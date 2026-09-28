-- V2: shared definitions, exact per-owner instance state, no acquired equip skills.
local extraSkills = sgs.SkillList()
local function addToSkills(skill)
    if not sgs.Sanguosha:getSkill(skill:objectName()) then extraSkills:append(skill) end
end
local function state(owner, ref, key)
    return owner:getSkillInstanceStateValue(ref.key.skillName, ref.key.instanceID, key)
end
local function put(owner, ref, key, value)
    owner:setSkillInstanceStateValue(ref.key.skillName, ref.key.instanceID, key, sgs.QVariant(value))
end
local function firstId(owner, name)
    for _, id in sgs.qlist(owner:getSkillInstanceIds(name)) do
        if owner:isSkillInstanceEffectAvailable(name, id) then return id end
    end
end
local function firstSource(players, name)
    for _, owner in sgs.qlist(players) do
        local id = owner:isAlive() and firstId(owner, name)
        if id then return name .. "#" .. id, owner end
    end
    return ""
end
local function own(self, player)
    if player and player:isAlive() and player:hasSkill(self:objectName()) then
        return self:objectName(), player
    end
    return ""
end
local function oneHand(self, request, card)
    return request:getSelectedCardIds():isEmpty()
        and request:getInitiator():handCards():contains(card:getEffectiveId())
end
local function oneCard(self, request)
    return request:getSelectedCardIds():length() == 1
end
local function play(request)
    return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
end
local function qiDisplay(room, player)
    local total = 0
    for _, id in sgs.qlist(player:getSkillInstanceIds("kangqin_daqi")) do
        total = total + player:getSkillInstanceStateValue("kangqin_daqi", id, "qi"):toInt()
    end
    room:setPlayerMark(player, "&qi", total)
end
local function daqiEffect(room, player, amount)
    local recover = sgs.RecoverStruct()
    recover.who, recover.recover = player, (player:getMaxHp() - player:getHp()) * amount
    if recover.recover > 0 then room:recover(player, recover) end
    local count = player:getMaxHp() - player:getHandcardNum()
    if count > 0 then player:drawCards(count * amount, "kangqin_daqi") end
    -- notifySkillInvoked emits ChoiceMade in this engine; Huoluan listens there.
    room:notifySkillInvoked(player, "kangqin_daqi_effect")
end

-- 合纵抗秦扩展包
-- 添加秦势力

-- 加载配置并添加秦势力
require("lua.config")
if not table.contains(config.kingdoms, "qin") then table.insert(config.kingdoms, "qin") end
config.kingdom_colors.qin = "#000000"  -- 黑色代表秦国

-- 创建武将包
local hezongkangqin_generals = sgs.Package("hezongkangqin_generals", sgs.Package_GeneralPack)

-- 创建卡牌包
local hezongkangqin_cards = sgs.Package("hezongkangqin_cards", sgs.Package_CardPack)

-- 翻译表
sgs.LoadTranslationTable{
    ["hezongkangqin_generals"] = "合纵抗秦·武将",
    ["hezongkangqin_cards"] = "合纵抗秦·卡牌",
    ["qin"] = "秦",
}

-- ==================== 白起 ====================

-- 白起武将
kangqin_baiqi = sgs.General(hezongkangqin_generals, "kangqin_baiqi", "qin", 4)

-- 武安：锁定技，你存活时，所有秦势力角色每回合可使用【杀】的上限+1，【杀】造成的伤害+1

-- 武安技能1：杀次数+1
kangqin_wuan_residue = sgs.CreateTargetModSkillV2{
    name = "#kangqin_wuan_residue", pattern = "Slash",
    holder_selector = sgs.CorrectSkill_AllHolders,
    correct_func = function(self, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_Residue or ctx:getPrimary():getKingdom() ~= "qin" then return false end
        -- The donor aura is one global bonus, not one bonus per Baiqi/instance.
        local holder = ctx:getHolder()
        local players = holder:getAliveSiblings()
        players:append(holder)
        local chosen, chosenId
        for _, p in sgs.qlist(players) do
            local id = firstId(p, self:objectName())
            if id and (not chosen or p:getSeat() < chosen:getSeat()) then chosen, chosenId = p, id end
        end
        return chosen and chosen:objectName() == holder:objectName()
            and ctx:getInstanceRef().key.instanceID == chosenId and 1 or false
    end,
}

-- 武安主技能：杀伤害+1
kangqin_wuan = sgs.CreateTriggerSkillV2{
    name = "kangqin_wuan", frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or player:getKingdom() ~= "qin" then return "" end
        local d = data:toDamage()
        if d.chain or d.transfer or not d.by_user or not d.card or not d.card:isKindOf("Slash") then return "" end
        return firstSource(room:getAlivePlayers(), self:objectName())
    end,
    on_effect = function(self, event, room, player, ctx)
        local d = ctx.original_data:toDamage()
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        d.damage = d.damage + self:getEffectiveAmount(ctx)
        ctx.original_data:setValue(d)
        return false
    end,
}

addToSkills(kangqin_wuan_residue)
kangqin_baiqi:addSkill(kangqin_wuan)
hezongkangqin_generals:insertRelatedSkills("kangqin_wuan", "#kangqin_wuan_residue")

-- 杀神：你可以将手牌中的任意一张牌当【杀】使用或打出。每回合你使用的第一张【杀】造成伤害后，摸一张牌
kangqin_shashenVS = sgs.CreateViewAsSkillV2{
    name = "kangqin_shashen", n = 1,
    can_activate = function(self, request)
        if play(request) then return sgs.Slash_IsAvailable(request:getInitiator()) end
        return request:getPattern() == "slash"
    end,
    can_select_card = oneHand, card_selection_feasible = oneCard,
    create_card = function(self, request)
        local ids = request:getSelectedCardIds()
        if ids:length() ~= 1 then return nil end
        local material = sgs.Sanguosha:getCard(ids:first())
        local card = sgs.Sanguosha:cloneCard("slash", material:getSuit(), material:getNumber())
        card:addSubcard(ids:first())
        card:setSkillName(self:objectName())
        return card
    end,
}

-- Compare the immutable use event, not a card id or a flag set at CardFinished.
local function isFirstSlashUse(room, player)
    local turn = room:historyScopes().turn_id
    if not turn or turn == "0" then return false end
    local current = room:currentHistoryEventId()
    local use = room:historyParent(current, "use_card", true)
    local response = room:historyParent(current, "respond_card", true)
    local filter = {turn_id = turn, limit = 64}
    while true do
        local page = room:queryHistoryFacts(filter)
        if page.error or not page.complete then error("kangqin_shashen: card history is incomplete") end
        for _, fact in ipairs(page.items) do
            local d = fact.data
            local isUse = fact.kind == "use_card" and d.from == player:objectName()
                or fact.kind == "respond_card" and d.is_use and d.player == player:objectName()
            if isUse and (not d.card or not d.card.classes or d.card.type == nil) then
                error("kangqin_shashen: card attribution is incomplete")
            end
            if isUse and d.card.type ~= sgs.Card_TypeSkill and table.contains(d.card.classes, "Slash") then
                -- Attribution here is the explicit card actor, not the legacy skill owner.
                return fact.kind == "use_card" and fact.event_id == use.id
                    or fact.kind == "respond_card" and fact.event_id == response.id
            end
        end
        if not page.has_more then return false end
        filter.watermark = filter.watermark or page.watermark
        filter.after = page.next_after
    end
end
kangqin_shashen = sgs.CreateTriggerSkillV2{
    name = "kangqin_shashen", frequency = sgs.Skill_NotFrequent,
    events = {sgs.Damage}, view_as_skill = kangqin_shashenVS,
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and damage.card and damage.card:isKindOf("Slash") and isFirstSlashUse(room, player) then
            return own(self, player)
        end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        ctx.invoker:drawCards(self:getEffectiveAmount(ctx), self:objectName())
        return false
    end,
}

kangqin_baiqi:addSkill(kangqin_shashen)

-- 伐楚：锁定技，当你对非秦势力角色造成伤害而导致其进入濒死状态后，你随机废除其一个装备区
kangqin_fachu = sgs.CreateTriggerSkillV2{
    name = "kangqin_fachu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EnterDying},
    can_trigger = function(self, event, room, player, data)
        local dying = data:toDying()
        if not dying.who or dying.who:getKingdom() == "qin" or not dying.damage then return "" end
        return own(self, dying.damage.from)
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local dying = data:toDying()
        
        -- 检查濒死角色是否是非秦势力
        if dying.who:getKingdom() == "qin" then
            return false
        end
        
        -- 检查是否有伤害来源（dying.damage 是 DamageStruct* 指针，不需要 toDamage()）
        if not dying.damage then
            return false
        end
        
        -- dying.damage 已经是 DamageStruct 了
        if not dying.damage.from then
            return false
        end
        
        -- 检查伤害来源是否拥有伐楚技能
        if not dying.damage.from:hasSkill(self:objectName()) then
            return false
        end
        
        -- 获取所有可以废除的装备区（0=武器, 1=防具, 2=防御马, 3=进攻马, 4=宝物）
        local slots = {}
        for i = 0, 4 do
            -- 检查该装备区是否存在且未被废除
            if dying.who:hasEquipArea(i) then
                table.insert(slots, i)
            end
        end
        
        -- 如果有可废除的装备区，随机选择一个废除
        if #slots > 0 then
            room:sendCompulsoryTriggerLog(dying.damage.from, "kangqin_fachu", true)
            
            local slot = slots[math.random(1, #slots)]
            
            -- 发送日志：废除装备区
            local log = sgs.LogMessage()
            log.type = "#kangqin_fachu"
            log.from = dying.damage.from
            log.to:append(dying.who)
            log.arg = "kangqin_fachu"
            
            -- 根据装备区类型设置 arg2
            if slot == 0 then
                log.arg2 = "weapon_area"
            elseif slot == 1 then
                log.arg2 = "armor_area"
            elseif slot == 2 then
                log.arg2 = "defensive_horse_area"
            elseif slot == 3 then
                log.arg2 = "offensive_horse_area"
            elseif slot == 4 then
                log.arg2 = "treasure_area"
            end
            
            room:sendLog(log)
            
            -- 废除装备区
            dying.who:throwEquipArea(slot)
        end
        
        return false
    end,
}

kangqin_baiqi:addSkill(kangqin_fachu)

-- 常胜：锁定技，你使用【杀】无距离限制
kangqin_changsheng = sgs.CreateTargetModSkillV2{
    name = "kangqin_changsheng", pattern = "Slash", base_amount = 1000,
    holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        return ctx:getModType() == sgs.TargetModSkill_DistanceLimit
    end,
}

kangqin_baiqi:addSkill(kangqin_changsheng)

-- 白起翻译
sgs.LoadTranslationTable{
    ["kangqin_baiqi"] = "白起",
    ["&kangqin_baiqi"] = "白起",
    ["#kangqin_baiqi"] = "武安君",
    ["~kangqin_baiqi"] = "人屠之名，终成枷锁...",
    ["designer:kangqin_baiqi"] = "合纵抗秦",
    
    ["kangqin_wuan"] = "武安",
    [":kangqin_wuan"] = "锁定技，你存活时，所有秦势力角色每回合可使用【杀】的上限+1，【杀】造成的伤害+1。",
    
    ["kangqin_shashen"] = "杀神",
    [":kangqin_shashen"] = "你可以将手牌中的任意一张牌当【杀】使用或打出。每回合你使用的第一张【杀】造成伤害后，摸一张牌。",
    
    ["kangqin_fachu"] = "伐楚",
    [":kangqin_fachu"] = "锁定技，当你对非秦势力角色造成伤害而导致其进入濒死状态后，你随机废除其一个装备区。",
    ["#kangqin_fachu"] = "%from 发动了【%arg】，随机废除了 %to 的 %arg2",   
    ["kangqin_changsheng"] = "常胜",
    [":kangqin_changsheng"] = "锁定技，你使用【杀】无距离限制。",
}

-- ==================== 赵姬 ====================

-- 赵姬武将
kangqin_zhaoji = sgs.General(hezongkangqin_generals, "kangqin_zhaoji", "qin", 3, false)


-- 善舞：锁定技，你使用【杀】指定目标后，你进行判定，若为黑色则该【杀】不能被抵消。当你成为【杀】的目标后，你进行判定，若为红色此杀无效。
kangqin_shanwu = sgs.CreateTriggerSkillV2{
    name = "kangqin_shanwu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecified, sgs.TargetConfirmed},
    
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if not use.card or not use.card:isKindOf("Slash") then return "" end
        if event == sgs.TargetSpecified and use.from == player then return own(self, player) end
        if event == sgs.TargetConfirmed and use.to:contains(player) and use.from ~= player then return own(self, player) end
        return ""
    end,
    
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        player = ctx.invoker
        local use = data:toCardUse()
        
        if not (use.card and use.card:isKindOf("Slash")) then
            return false
        end
        
        if event == sgs.TargetSpecified then
            -- 使用杀指定目标后
            if use.from:objectName() ~= player:objectName() then
                return false
            end
            
            -- 对每个目标进行判定
            local no_respond = use.no_respond_list
            local index = 1
            
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then break end
                
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                
                -- 进行判定
                local judge = sgs.JudgeStruct()
                judge.pattern = "."
                judge.play_animation = false
                judge.reason = self:objectName()
                judge.who = player
                room:judge(judge)
                
                -- 若为黑色，该杀不能被抵消（闪避次数设为0）
                if judge.card:isBlack() then
                    if not table.contains(no_respond, p:objectName()) then table.insert(no_respond, p:objectName()) end
                    
                    local log = sgs.LogMessage()
                    log.type = "#kangqin_shanwu_black"
                    log.from = player
                    log.to:append(p)
                    log.arg = self:objectName()
                    room:sendLog(log)
                end
                
                index = index + 1
            end
            
            -- 更新闪避次数表
            use.no_respond_list = no_respond
            data:setValue(use)
            
        elseif event == sgs.TargetConfirmed then
            -- 成为杀的目标后
            if not use.to:contains(player) or use.from:objectName() == player:objectName() then
                return false
            end
            
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            
            -- 进行判定
            local judge = sgs.JudgeStruct()
            judge.pattern = "."
            judge.play_animation = false
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            
            -- 若为红色，此杀无效
            if judge.card:isRed() then
                local log = sgs.LogMessage()
                log.type = "#kangqin_shanwu_red"
                log.from = player
                log.arg = self:objectName()
                room:sendLog(log)
                
                -- 将自己加入无效列表
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        
        return false
    end,
}

kangqin_zhaoji:addSkill(kangqin_shanwu)

-- 大期效果卡：封装回复体力和补牌的效果
-- Daqi resolves directly in V2 effect; no synthetic SkillCard or duplicate card lifecycle.

-- 大期：锁定技，你每使用或打出一张手牌、造成1点伤害、受到1点伤害，均会得到一个"期"标记。你的回合开始时，若你拥有的"期"标记大于等于10，则弃置所有"期"，体力回复至体力上限，并将手牌补至体力上限。
kangqin_daqi = sgs.CreateTriggerSkillV2{
    name = "kangqin_daqi", frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.Damage, sgs.Damaged, sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local c = data:toCardUse().card
            if not c or c:isKindOf("SkillCard") then return "" end
        elseif event == sgs.CardResponded then
            local c = data:toCardResponse().m_card
            if not c or c:isKindOf("SkillCard") then return "" end
        elseif event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_Start then return "" end
        return own(self, player)
    end,
    on_cost = function(self, event, room, player, ctx)
        return event ~= sgs.EventPhaseStart or state(ctx.owner, ctx:getSourceRef(), "qi"):toInt() >= 10
    end,
    on_pay = function(self, event, room, player, ctx)
        if event == sgs.EventPhaseStart then
            put(ctx.owner, ctx:getSourceRef(), "qi", 0)
            qiDisplay(room, ctx.owner)
        end
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        if event == sgs.EventPhaseStart then daqiEffect(room, ctx.invoker, self:getEffectiveAmount(ctx))
        else
            local n = (event == sgs.Damage or event == sgs.Damaged) and ctx.original_data:toDamage().damage or 1
            put(ctx.owner, ctx:getSourceRef(), "qi", state(ctx.owner, ctx:getSourceRef(), "qi"):toInt() + n)
            qiDisplay(room, ctx.owner)
        end
        return false
    end,
}

kangqin_zhaoji:addSkill(kangqin_daqi)

-- 献姬：限定技，出牌阶段，你可以弃置所有手牌、装备牌和【期】标记，失去1点体力上限，然后立即发动大期的回复体力和补牌效果。
-- Xianji uses the native V2 custom action and exact game quota.

-- The active entry is the skill itself.

kangqin_xianji = sgs.CreateViewAsSkillV2{
    name = "kangqin_xianji", n = 0, frequency = sgs.Skill_Limited,
    limit_mark = "@kangqin_xianji", limit_scope = sgs.Skill_Limit_Game, max_usage_limit = 1,
    target_mode = sgs.ViewAsSkillV2_NoTarget,
    can_activate = function(self, request) return play(request) end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    pay = function(self, room, ctx, request)
        local player = ctx.invoker
        room:removePlayerMark(ctx.owner, "@kangqin_xianji", 1)
        player:throwAllHandCardsAndEquips()
        for _, id in sgs.qlist(player:getSkillInstanceIds("kangqin_daqi")) do
            player:setSkillInstanceStateValue("kangqin_daqi", id, "qi", sgs.QVariant(0))
        end
        qiDisplay(room, player)
        room:loseMaxHp(player, 1)
        return true
    end,
    on_effect = function(self, ctx)
        if ctx.invoker:isAlive() then daqiEffect(ctx.invoker:getRoom(), ctx.invoker, self:getEffectiveAmount(ctx)) end
    end,
}

kangqin_zhaoji:addSkill(kangqin_xianji)

-- 祸乱：锁定技，你每次发动大期的回复体力和补牌效果后，你对所有其他角色造成1点伤害。
kangqin_huoluan = sgs.CreateTriggerSkillV2{
    name = "kangqin_huoluan", frequency = sgs.Skill_Compulsory, events = {sgs.ChoiceMade},
    can_trigger = function(self, event, room, player, data)
        if data:toString() == "notifyInvoked:kangqin_daqi_effect" then return own(self, player) end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        for _, p in sgs.qlist(room:getOtherPlayers(ctx.invoker)) do
            if p:isAlive() then room:damage(sgs.DamageStruct(self:objectName(), ctx.invoker, p, 1)) end
        end
        return false
    end,
}

kangqin_zhaoji:addSkill(kangqin_huoluan)

-- 赵姬翻译
sgs.LoadTranslationTable{
    ["kangqin_zhaoji"] = "赵姬",
    ["&kangqin_zhaoji"] = "赵姬",
    ["#kangqin_zhaoji"] = "秦国太后",
    ["~kangqin_zhaoji"] = "权倾一时，终成空...",
    ["designer:kangqin_zhaoji"] = "合纵抗秦",
    
    ["kangqin_shanwu"] = "善舞",
    [":kangqin_shanwu"] = "锁定技，你使用【杀】指定目标后，你进行判定，若为黑色则该【杀】不能被抵消。当你成为【杀】的目标后，你进行判定，若为红色此杀无效。",
    ["#kangqin_shanwu_black"] = "%from 的【%arg】判定为黑色，%to 对此【杀】不能使用【闪】",
    ["#kangqin_shanwu_red"] = "%from 的【%arg】判定为红色，此【杀】对其无效",
    
    ["kangqin_daqi"] = "大期",
    [":kangqin_daqi"] = "锁定技，你每使用或打出一张手牌、造成1点伤害、受到1点伤害，均会得到一个【期】标记。你的回合开始时，若你拥有的【期】标记大于等于10，则弃置所有【期】，体力回复至体力上限，并将手牌补至体力上限。",
    ["qi"] = "期",
    ["kangqin_daqi_effect"] = "大期效果",
    
    ["kangqin_xianji"] = "献姬",
    [":kangqin_xianji"] = "限定技，出牌阶段，你可以弃置所有手牌、装备牌和【期】标记，失去1点体力上限，然后立即发动大期的回复体力和补牌效果。",
    ["@kangqin_xianji"] = "献姬",
    ["$kangqin_xianji"] = "献姬：弃置所有手牌、装备牌和【期】标记，失去1点体力上限，然后发动大期效果",
    
    ["kangqin_huoluan"] = "祸乱",
    [":kangqin_huoluan"] = "锁定技，你每次发动大期的回复体力和补牌效果后，你对所有其他角色造成1点伤害。",
}

-- ==================== 商鞅 ====================

-- 商鞅武将
kangqin_shangyang = sgs.General(hezongkangqin_generals, "kangqin_shangyang", "qin", 4)

-- 变法：出牌阶段限一次，你可以将任意一张普通锦囊牌当【商鞅变法】使用
-- Bianfa is a direct ordinary-card ViewAsSkillV2 conversion.

kangqin_bianfa = sgs.CreateViewAsSkillV2{
    name = "kangqin_bianfa", n = 1,
    limit_scope = sgs.Skill_Limit_Turn, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request) return play(request) end,
    can_select_card = function(self, request, card) return oneHand(self, request, card) and card:isNDTrick() end,
    card_selection_feasible = oneCard,
    create_card = function(self, request)
        local ids = request:getSelectedCardIds()
        if ids:length() ~= 1 then return nil end
        local card = kangqin_shangyangbianfa:clone()
        card:addSubcard(ids:first())
        card:setSkillName(self:objectName())
        return card
    end,
}

kangqin_shangyang:addSkill(kangqin_bianfa)

-- 立木：锁定技，你使用的普通锦囊牌无法被【无懈可击】抵消
kangqin_limu = sgs.CreateTriggerSkillV2{
    name = "kangqin_limu", frequency = sgs.Skill_Compulsory, events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
        local c = data:toCardUse().card
        if c and c:isNDTrick() then return own(self, player) end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list
        if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
        use.no_respond_list = list
        ctx.original_data:setValue(use)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        return false
    end,
}

kangqin_shangyang:addSkill(kangqin_limu)

-- 垦草：锁定技，你存活时，秦势力角色每造成1点伤害，可获得一个"功"标记。若秦势力角色拥有大于等于3个"功"标记，则弃置所有"功"标记，增加1点体力上限，并回复1点体力
kangqin_kencao = sgs.CreateTriggerSkillV2{
    name = "kangqin_kencao", frequency = sgs.Skill_Compulsory, events = {sgs.Damage},
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or player:getKingdom() ~= "qin" then return "" end
        return firstSource(room:getAlivePlayers(), self:objectName())
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        player = ctx.invoker
        -- Gong belongs to its beneficiary; the unique aura must not multiply it.
        local damage = data:toDamage()
        
        -- 秦势力角色造成伤害，获得"功"标记
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        player:gainMark("&gong", damage.damage)
        
        -- 检查是否达到3个"功"标记
        if player:getMark("&gong") >= 3 then
            -- 弃置所有"功"标记
            room:setPlayerMark(player, "&gong", 0)
            
            -- 增加1点体力上限
            room:gainMaxHp(player, self:getEffectiveAmount(ctx), self:objectName())
            
            -- 回复1点体力
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = self:getEffectiveAmount(ctx)
            room:recover(player, recover)
            
            -- 发送日志
            local log = sgs.LogMessage()
            log.type = "#kangqin_kencao_effect"
            log.from = player
            log.arg = self:objectName()
            room:sendLog(log)
        end
        
        return false
    end,
}

kangqin_shangyang:addSkill(kangqin_kencao)

-- 商鞅翻译
sgs.LoadTranslationTable{
    ["kangqin_shangyang"] = "商鞅",
    ["&kangqin_shangyang"] = "商鞅",
    ["#kangqin_shangyang"] = "商君变法",
    ["~kangqin_shangyang"] = "法令既行，虽死无憾...",
    ["designer:kangqin_shangyang"] = "合纵抗秦",
    
    ["kangqin_bianfa"] = "变法",
    [":kangqin_bianfa"] = "出牌阶段限一次，你可以将任意一张普通锦囊牌当【商鞅变法】使用。",
    
    ["kangqin_limu"] = "立木",
    [":kangqin_limu"] = "锁定技，你使用的普通锦囊牌无法被【无懈可击】抵消。",
    
    ["kangqin_kencao"] = "垦草",
    [":kangqin_kencao"] = "锁定技，你存活时，秦势力角色每造成1点伤害，可获得一个【功】标记。若秦势力角色拥有大于等于3个【功】标记，则弃置所有【功】标记，增加1点体力上限，并回复1点体力。",
    ["&gong"] = "功",
    ["gong"] = "功",
    ["#kangqin_kencao_effect"] = "%from 的【%arg】触发，弃置所有【功】标记，增加1点体力上限并回复1点体力",
}

-- ==================== 芈月 ====================

-- 芈月武将
kangqin_miyue = sgs.General(hezongkangqin_generals, "kangqin_miyue", "qin", 3, false)

-- 掌政：锁定技，你的回合开始时，所有非秦势力角色依次选择：1.弃置一张手牌；2.失去1点体力
kangqin_zhangzheng = sgs.CreateTriggerSkillV2{
    name = "kangqin_zhangzheng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    
    can_trigger = function(self, event, room, player, data)
        if player and player:getPhase() == sgs.Player_Start then return own(self, player) end
        return ""
    end,
    
    on_effect = function(self, event, room, player, ctx)
        -- Each victim reacts during resolution; preserve donor choice/payment ordering.
        -- These are victim responses to the effect, not the skill owner's activation cost.
        local data = ctx.original_data
        player = ctx.invoker
        if player:getPhase() ~= sgs.Player_Start then
            return false
        end
        
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        
        -- 所有非秦势力角色依次选择
        local others = room:getOtherPlayers(player)
        for _, p in sgs.qlist(others) do
            if p:isAlive() and p:getKingdom() ~= "qin" then
                -- 选择：弃置一张手牌或失去1点体力
                local choices = {}
                if not p:isKongcheng() then
                    table.insert(choices, "discard")
                end
                table.insert(choices, "losehp")
                
                local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"), data)
                
                if choice == "discard" then
                    -- 弃置一张手牌
                    room:askForDiscard(p, self:objectName(), 1, 1, false, true)
                else
                    -- 失去1点体力
                    room:loseHp(p, 1)
                end
            end
        end
        
        return false
    end,
}

kangqin_miyue:addSkill(kangqin_zhangzheng)

-- 太后：锁定技，男性角色对你使用【杀】或普通锦囊牌时，需要额外弃置一张同种类型的牌，否则此牌无效
kangqin_taihou = sgs.CreateTriggerSkillV2{
    name = "kangqin_taihou", frequency = sgs.Skill_Compulsory, events = {sgs.TargetConfirming},
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick())
            and use.from and use.from:isMale() and use.to:contains(player) then return own(self, player) end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local pattern = use.card:isKindOf("Slash") and "Slash" or "TrickCard"
        local id = -1
        if not use.from:isKongcheng() then
            id = room:askForCardChosen(use.from, use.from, "h",
                string.format("@kangqin_taihou-discard:%s::%s", ctx.owner:objectName(), pattern), false, sgs.Card_MethodNone)
        end
        local c = id >= 0 and sgs.Sanguosha:getCard(id)
        local valid = c and ((use.card:isKindOf("Slash") and c:isKindOf("Slash")) or (use.card:isNDTrick() and c:isNDTrick()))
        ctx.extra_data = sgs.QVariant(valid and id or -1)
        return true
    end,
    on_pay = function(self, event, room, player, ctx)
        local use, id = ctx.original_data:toCardUse(), ctx.extra_data:toInt()
        if id >= 0 and room:getCardOwner(id) == use.from then room:throwCard(sgs.Sanguosha:getCard(id), use.from, use.from)
        else ctx.extra_data = sgs.QVariant(-1) end
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        if ctx.extra_data:toInt() < 0 then
            local use = ctx.original_data:toCardUse()
            local list = use.nullified_list
            if not table.contains(list, ctx.owner:objectName()) then table.insert(list, ctx.owner:objectName()) end
            use.nullified_list = list
            ctx.original_data:setValue(use)
        end
        return false
    end,
}

kangqin_miyue:addSkill(kangqin_taihou)

-- 诱灭：出牌阶段限一次，你可以将一张牌交给一名角色，若如此做，直到你的下个回合开始，该角色于其回合外无法使用或打出牌

-- 诱灭隐藏技能：给被诱灭的角色，在自己回合开始时移除标记，回合结束后加回标记
local function syncYoumieLimit(room, player, phase)
    local limited = player:getMark("kangqin_youmie_target") > 0
        and (phase or player:getPhase()) == sgs.Player_NotActive
    local applied = player:getTag("kangqin_youmie_limited"):toBool()
    if limited == applied then return end
    -- 原生限制按独立 reason 同步；已建立的效果不依赖源技能仍被持有。
    if limited then
        room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false, "kangqin_youmie")
    else
        room:removePlayerCardLimitationByReason(player, "kangqin_youmie")
    end
    player:setTag("kangqin_youmie_limited", sgs.QVariant(limited))
end

kangqin_youmie_hidden = sgs.CreateRuleSkillV2{
    name = "#kangqin_youmie_hidden", frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    -- Delayed records retain source owner/id without granting recipient skill instances.
    can_trigger = function(self, event, room, player, data)
        -- Record owns passive expiry/synchronization; it must not create an activation.
        return ""
    end,
    on_record = function(self, event, room, player, ctx)
        if not player then return end
        if event == sgs.EventPhaseChanging then
            syncYoumieLimit(room, player, ctx.original_data:toPhaseChange().to)
            return
        end
        if player:getPhase() ~= sgs.Player_Start then return end
        for _, p in sgs.qlist(room:getAllPlayers(true)) do
            local keep = {}
            for _, entry in ipairs(p:getTag("kangqin_youmie_sources"):toString():split("+")) do
                local owner = entry:match("^(.-):%d+$")
                if owner and owner ~= player:objectName() then table.insert(keep, entry) end
            end
            p:setTag("kangqin_youmie_sources", sgs.QVariant(table.concat(keep, "+")))
            room:setPlayerMark(p, "kangqin_youmie_target", #keep > 0 and 1 or 0)
            syncYoumieLimit(room, p)
        end
    end,
    on_effect = function(self, event, room, player, ctx) return false end,
}

addToSkills(kangqin_youmie_hidden)

-- Youmie is a native V2 custom action; its hand card is given in pay.

-- No SkillCard clone or legacy view_as callback is required.

kangqin_youmie = sgs.CreateViewAsSkillV2{
    name = "kangqin_youmie", n = 1,
    limit_scope = sgs.Skill_Limit_Turn, phase_name = "Play", max_usage_limit = 1,
    target_mode = sgs.ViewAsSkillV2_SelectTargets, target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
    will_throw_selected_cards = false,
    can_activate = function(self, request) return play(request) end,
    can_select_card = oneHand, card_selection_feasible = oneCard,
    can_select_target = function(self, request, selected, candidate)
        return #selected == 0 and candidate:objectName() ~= request:getInitiator():objectName()
    end,
    targets_feasible = function(self, request, selected) return #selected == 1 end,
    pay = function(self, room, ctx, request)
        local ids, targets = request:getSelectedCardIds(), ctx.targets
        if ids:length() ~= 1 or targets:length() ~= 1 or not targets:first():isAlive() then return false end
        local id = ids:first()
        if room:getCardOwner(id) ~= ctx.invoker or room:getCardPlace(id) ~= sgs.Player_PlaceHand then return false end
        room:obtainCard(targets:first(), sgs.Sanguosha:getCard(id), false)
        return true
    end,
    on_effect_target = function(self, ctx, target)
        local entries = target:getTag("kangqin_youmie_sources"):toString():split("+")
        local entry = ctx:getSourceRef().ownerObjectName .. ":" .. ctx:getSourceRef().key.instanceID
        if not table.contains(entries, entry) then table.insert(entries, entry) end
        target:setTag("kangqin_youmie_sources", sgs.QVariant(table.concat(entries, "+")))
        target:getRoom():setPlayerMark(target, "kangqin_youmie_target", 1)
        syncYoumieLimit(target:getRoom(), target)
    end,
}

kangqin_miyue:addSkill(kangqin_youmie)

-- No owner-gated CardLimitSkill: the rule expires the native pending limitation.

-- 隐退：锁定技，当你失去最后一张手牌时，你翻面。你的武将牌背面朝上时，若受到伤害，令此伤害-1，然后摸一张牌
kangqin_yintui = sgs.CreateTriggerSkillV2{
    name = "kangqin_yintui", frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.DamageInflicted},
    can_trigger = function(self, event, room, player, data)
        if not player then return "" end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand) and player:isKongcheng() and player:faceUp() then
                return own(self, player)
            end
        elseif not player:faceUp() then return own(self, player) end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(ctx.owner, self:objectName(), true)
        if event == sgs.CardsMoveOneTime then ctx.invoker:turnOver()
        else
            local d = ctx.original_data:toDamage()
            d.damage = d.damage - self:getEffectiveAmount(ctx)
            ctx.original_data:setValue(d)
            ctx.invoker:drawCards(self:getEffectiveAmount(ctx), self:objectName())
            return d.damage <= 0
        end
        return false
    end,
}

kangqin_miyue:addSkill(kangqin_yintui)

-- 芈月翻译
sgs.LoadTranslationTable{
    ["kangqin_miyue"] = "芈月",
    ["&kangqin_miyue"] = "芈月",
    ["#kangqin_miyue"] = "宣太后",
    ["~kangqin_miyue"] = "权势滔天，终归尘土...",
    ["designer:kangqin_miyue"] = "合纵抗秦",
    
    ["kangqin_zhangzheng"] = "掌政",
    [":kangqin_zhangzheng"] = "锁定技，你的回合开始时，所有非秦势力角色依次选择：1.弃置一张手牌；2.失去1点体力。",
    ["discard"] = "弃置一张手牌",
    ["losehp"] = "失去1点体力",
    
    ["kangqin_taihou"] = "太后",
    [":kangqin_taihou"] = "锁定技，男性角色对你使用【杀】或普通锦囊牌时，需要额外弃置一张同种类型的牌，否则此牌无效。",
    ["@kangqin_taihou-discard"] = "太后：请弃置一张 %arg，否则此牌对 %src 无效",
    
    ["kangqin_youmie"] = "诱灭",
    [":kangqin_youmie"] = "出牌阶段限一次，你可以将一张牌交给一名角色，若如此做，直到你的下个回合开始，该角色于其回合外无法使用或打出牌。",
    
    ["kangqin_yintui"] = "隐退",
    [":kangqin_yintui"] = "锁定技，当你失去最后一张手牌时，你翻面。你的武将牌背面朝上时，若受到伤害，令此伤害-1，然后摸一张牌。",
}

-- ==================== 传国玉玺 ====================

-- 传国玉玺翻译表
sgs.LoadTranslationTable{
    ["kangqin_chuanguoyuxi"] = "传国玉玺",
    [":kangqin_chuanguoyuxi"] = "装备牌，宝物。<br/><b>占据宝物栏。</b><br/>出牌阶段开始时，你可以选择并使用以下一张牌：【南蛮入侵】、【万箭齐发】、【桃园结义】、【五谷丰登】。",
    ["@kangqin_chuanguoyuxi-choose"] = "传国玉玺：你可以选择并使用一张锦囊牌",
    ["kangqin_chuanguoyuxi_savage_assault"] = "南蛮入侵",
    ["kangqin_chuanguoyuxi_archery_attack"] = "万箭齐发",
    ["kangqin_chuanguoyuxi_god_salvation"] = "桃园结义",
    ["kangqin_chuanguoyuxi_amazing_grace"] = "五谷丰登",
}

-- 传国玉玺技能：出牌阶段开始时选择使用一张锦囊
kangqin_chuanguoyuxi_trigger = sgs.CreateEquipSkillV2{
    name = "#kangqin_chuanguoyuxi_trigger", equipment = "kangqin_chuanguoyuxi", equipment_type = "treasure",
    frequency = sgs.Skill_NotFrequent, events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase() == sgs.Player_Play and player:hasTreasure("kangqin_chuanguoyuxi") then
            return self:objectName(), player
        end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        if not ctx.invoker:askForSkillInvoke("kangqin_chuanguoyuxi", ctx.original_data) then return false end
        ctx.choice = room:askForChoice(ctx.invoker, "kangqin_chuanguoyuxi",
            "kangqin_chuanguoyuxi_savage_assault+kangqin_chuanguoyuxi_archery_attack+kangqin_chuanguoyuxi_god_salvation+kangqin_chuanguoyuxi_amazing_grace+cancel", ctx.original_data)
        return ctx.choice ~= "cancel"
    end,
    on_effect = function(self, event, room, player, ctx)
        local names = {kangqin_chuanguoyuxi_savage_assault = "savage_assault", kangqin_chuanguoyuxi_archery_attack = "archery_attack",
            kangqin_chuanguoyuxi_god_salvation = "god_salvation", kangqin_chuanguoyuxi_amazing_grace = "amazing_grace"}
        local name = names[ctx.choice]
        if not name then return false end
        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        card:setSkillName("kangqin_chuanguoyuxi")
        room:useCard(sgs.CardUseStruct(card, ctx.invoker, sgs.SPlayerList()), true)
        card:deleteLater()
        return false
    end,
}

-- 注册技能
addToSkills(kangqin_chuanguoyuxi_trigger)

-- 传国玉玺（占据宝物栏）
kangqin_chuanguoyuxi = sgs.CreateTreasure{
    name = "kangqin_chuanguoyuxi", class_name = "kangqin_chuanguoyuxi", occupy_slots = {4},
}

-- 添加传国玉玺到牌堆
-- 方片1传国玉玺 x1
for i = 1, 1 do
    local card = kangqin_chuanguoyuxi:clone()
    card:setSuit(sgs.Card_Diamond)
    card:setNumber(1)  -- 方片A
    card:setParent(hezongkangqin_cards)
end

-- 设置传国玉玺装备技能标记
-- Native EquipSkillV2 validates the actual treasure source.

-- ==================== 真龙长剑 ====================

-- 真龙长剑翻译表
sgs.LoadTranslationTable{
    ["kangqin_zhenlongchangjian"] = "真龙长剑",
    [":kangqin_zhenlongchangjian"] = "装备牌，武器，攻击范围2。<br/><b>武器技能</b>：每回合，你使用的第一张非延时性锦囊无法被【无懈可击】抵消。",
}

-- 真龙长剑技能：第一张非延时性锦囊无法被无懈可击抵消
kangqin_zhenlongchangjian_trigger = sgs.CreateEquipSkillV2{
    name = "#kangqin_zhenlongchangjian_trigger", equipment = "kangqin_zhenlongchangjian", equipment_type = "weapon",
    frequency = sgs.Skill_Compulsory, events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if player and player:isAlive() and player:hasWeapon("kangqin_zhenlongchangjian")
            and use.card and use.card:isNDTrick() and player:getMark("kangqin_zhenlongchangjian_used-Clear") == 0 then
            return self:objectName(), player
        end
        return ""
    end,
    on_pay = function(self, event, room, player, ctx)
        -- Equipment is not a player skill instance; the donor quota is per wielder/turn.
        room:addPlayerMark(ctx.invoker, "kangqin_zhenlongchangjian_used-Clear")
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list
        if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
        use.no_respond_list = list
        ctx.original_data:setValue(use)
        room:sendCompulsoryTriggerLog(ctx.invoker, "kangqin_zhenlongchangjian", true)
        room:setEmotion(ctx.invoker, "weapon/kangqin_zhenlongchangjian")
        return false
    end,
}

-- 注册技能
addToSkills(kangqin_zhenlongchangjian_trigger)

-- 真龙长剑（攻击范围2）
kangqin_zhenlongchangjian = sgs.CreateWeapon{
    name = "kangqin_zhenlongchangjian", class_name = "kangqin_zhenlongchangjian", range = 2,
}

-- 添加真龙长剑到牌堆
-- 黑桃5真龙长剑 x1
for i = 1, 1 do
    local card = kangqin_zhenlongchangjian:clone()
    card:setSuit(sgs.Card_Spade)
    card:setNumber(5)
    card:setParent(hezongkangqin_cards)
end

-- 设置真龙长剑装备技能标记
-- Native EquipSkillV2 validates the actual weapon source.

-- ==================== 商鞅变法 ====================

-- 商鞅变法翻译表
sgs.LoadTranslationTable{
    ["kangqin_shangyangbianfa"] = "商鞅变法",
    [":kangqin_shangyangbianfa"] = "锦囊牌。<br/>出牌阶段，对一名其他角色使用。对目标造成随机1~2点伤害。若目标因此进入濒死状态，你进行判定，若结果为黑色，则其本次濒死状态无法向其他角色求【桃】。",
    ["#kangqin_shangyangbianfa_damage"] = "【商鞅变法】对 %to 造成了 %arg 点伤害",
    ["#kangqin_shangyangbianfa_nope ach"] = "%from 的【商鞅变法】判定为黑色，%to 本次濒死无法向其他角色求【桃】",
}

-- 商鞅变法卡牌
kangqin_shangyangbianfa = sgs.CreateTrickCard{
    name = "kangqin_shangyangbianfa",
    class_name = "kangqin_shangyangbianfa",
    target_fixed = false,
    
    filter = function(self, targets, to_select, source)
        -- Source is supplied by the native card query on both server and client.
        return #targets == 0 and source and to_select:objectName() ~= source:objectName()
    end,
    
    on_effect = function(self, effect)
        local source, target = effect.from, effect.to
        local room = target:getRoom()
        -- 造成随机1~2点伤害
        local damage_value = math.random(1, 2)
        
        local log = sgs.LogMessage()
        log.type = "#kangqin_shangyangbianfa_damage"
        log.from = source
        log.to:append(target)
        log.arg = tostring(damage_value)
        room:sendLog(log)
        
        -- 记录使用者和目标，用于后续判定
        
        -- 造成伤害
        local damage = sgs.DamageStruct()
        damage.from = source
        damage.to = target
        damage.damage = damage_value
        damage.card = self
        room:damage(damage)
    end,
}

-- 商鞅变法技能：监听濒死和求桃列表
kangqin_shangyangbianfa_skill = sgs.CreateRuleSkillV2{
    name = "#kangqin_shangyangbianfa_skill", frequency = sgs.Skill_Compulsory,
    events = {sgs.EnterDying, sgs.AskForPeaches, sgs.QuitDying},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.card and dying.damage.card:isKindOf("kangqin_shangyangbianfa")
                and dying.damage.from then return self:objectName(), dying.damage.from end
        elseif event == sgs.AskForPeaches then
            local dying = data:toDying().who
            if player and dying and player ~= dying and dying:getTag("kangqin_shangyangbianfa_nopeach"):toBool() then
                return self:objectName(), player
            end
        end
        return ""
    end,
    on_record = function(self, event, room, player, ctx)
        if event == sgs.EnterDying or event == sgs.QuitDying then
            local dying = ctx.original_data:toDying().who
            if dying then dying:removeTag("kangqin_shangyangbianfa_nopeach") end
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        if event == sgs.EnterDying then
            local dying = ctx.original_data:toDying()
            local judge = sgs.JudgeStruct()
            judge.pattern, judge.play_animation, judge.reason, judge.who = ".", false, "kangqin_shangyangbianfa", ctx.owner
            room:judge(judge)
            if judge.card:isBlack() then
                dying.who:setTag("kangqin_shangyangbianfa_nopeach", sgs.QVariant(true))
                local log = sgs.LogMessage()
                log.type, log.from = "#kangqin_shangyangbianfa_nope ach", ctx.owner
                log.to:append(dying.who)
                room:sendLog(log)
            end
        else
            -- This native event runs once per saver before GameRule's Peach prompt.
            -- Cancel other savers only; the dying player keeps their self-save window.
            return true
        end
        return false
    end,
}

-- 注册技能
addToSkills(kangqin_shangyangbianfa_skill)

-- 添加商鞅变法到牌堆
-- 黑桃7商鞅变法 x1, 梅花8商鞅变法 x1
local suits = {sgs.Card_Spade, sgs.Card_Club}
local numbers = {7, 8}
for i = 1, 2 do
    local card = kangqin_shangyangbianfa:clone()
    card:setSuit(suits[i])
    card:setNumber(numbers[i])
    card:setParent(hezongkangqin_cards)
end

sgs.Sanguosha:addSkills(extraSkills)

-- 返回两个扩展包
return {hezongkangqin_generals, hezongkangqin_cards}
