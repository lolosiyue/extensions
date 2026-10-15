-- ===== diyba b09 =====
do
-- diyba batch b09 (3D15J 张举&张纯; 庞淯; 邓方). 司马芝 skipped (1.5 hp).
local function diyba_trigger(name, events, effect, compulsory)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

diyba_15j_zhangjuzhangchun = sgs.General(extension, "diyba_15j_zhangjuzhangchun", "qun", 7)
diyba_xj_pangyu = sgs.General(extension, "diyba_xj_pangyu", "qun", 2)
diyba_xj_dengfang = sgs.General(extension, "diyba_xj_dengfang", "qun", 2)

------------------------------------------------------------------ 张举&张纯
-- Health cards are approximated with marks: diyba_jiding_v / diyba_mitian_v (勾玉 count),
-- diyba_jiding_f / diyba_mitian_f (flipped, 1 = flipped). A flip changes a card's value by -1 when
-- turned face down and +1 when turned back (min 0).
local function diyba_zz_flip(room, owner, which)
    local v, f = "diyba_" .. which .. "_v", "diyba_" .. which .. "_f"
    if owner:getMark(v) < 0 then return end
    if owner:getMark(f) == 0 then
        room:setPlayerMark(owner, f, 1)
        if owner:getMark(v) > 0 then
            local nv = owner:getMark(v) - 1
            room:setPlayerMark(owner, v, nv)
            if which == "mitian" and nv == 0 and owner:getMark("diyba_mitian_zero") == 0 then
                room:setPlayerMark(owner, "diyba_mitian_zero", 1)
                owner:drawCards(owner:getMaxHp(), "diyba_lulve")
                owner:turnOver()
            end
        end
    else
        room:setPlayerMark(owner, f, 0)
        room:setPlayerMark(owner, v, owner:getMark(v) + 1)
    end
    local a, b = owner:getMark("diyba_jiding_v"), owner:getMark("diyba_mitian_v")
    if a % 2 == b % 2 then
        local c = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
        c:setSkillName("diyba_juluan")
        room:useCard(sgs.CardUseStruct(c, owner, sgs.SPlayerList()), false)
        c:deleteLater()
    end
end

diyba_jitian = diyba_trigger("diyba_jitian", {sgs.GameStart}, function(self, event, room, p, data, owner)
    if owner:getMark("diyba_jitian_done") > 0 then return end
    room:setPlayerMark(owner, "diyba_jitian_done", 1)
    local a = (math.random(2) == 1) and 3 or 4
    local b = 7 - a
    room:setPlayerMark(owner, "diyba_jiding_v", a)
    room:setPlayerMark(owner, "diyba_mitian_v", b)
    room:setPlayerMark(owner, "diyba_jiding_f", 0)
    room:setPlayerMark(owner, "diyba_mitian_f", 0)
    room:setPlayerProperty(owner, "maxhp", sgs.QVariant(7))
    room:setPlayerProperty(owner, "hp", sgs.QVariant(7))
end, true)

diyba_juluan_record = diyba_record("#diyba_juluan_record", {sgs.EnterDying, sgs.Damage}, function(self, event, room, p, data)
    if event == sgs.EnterDying then
        room:setTag("diyba_juluan_dying", sgs.QVariant(true))
    end
end)
diyba_juluan = diyba_trigger("diyba_juluan", {sgs.RoundEnd, sgs.Damage}, function(self, event, room, p, data, owner)
    if event == sgs.RoundEnd then
        if room:getTag("diyba_juluan_dying"):toBool() then
            room:removeTag("diyba_juluan_dying")
            diyba_zz_flip(room, owner, "jiding")
        end
    else
        local damage = data:toDamage()
        if damage.from == owner and damage.card and damage.card:isKindOf("Slash") then
            diyba_zz_flip(room, owner, "mitian")
        end
    end
end, true)

diyba_lulve = diyba_trigger("diyba_lulve", {sgs.CardUsed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:isKindOf("Slash") or not use.card:isKindOf("TrickCard") then return end
    if use.card:isKindOf("DelayedTrick") or use.to:length() ~= 1 then return end
    local slash = sgs.Sanguosha:cloneCard("slash", use.card:getSuit(), use.card:getNumber())
    if not use.card:isVirtualCard() then slash:addSubcard(use.card:getEffectiveId()) else slash:addSubcards(use.card:getSubcards()) end
    slash:setSkillName("diyba_lulve")
    use.card = slash
    data:setValue(use)
end, true)

diyba_15j_zhangjuzhangchun:addSkill(diyba_jitian)
diyba_15j_zhangjuzhangchun:addSkill(diyba_juluan)
diyba_15j_zhangjuzhangchun:addSkill(diyba_juluan_record)
diyba_15j_zhangjuzhangchun:addSkill(diyba_lulve)

------------------------------------------------------------------ 庞淯
local function diyba_fz_count(p)
    local n = 0
    if p:getRole() ~= "renegade" then n = n + 1 end
    local room = p:getRoom()
    local same, most = 0, 0
    local cnt = {}
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        cnt[q:getKingdom()] = (cnt[q:getKingdom()] or 0) + 1
    end
    same = cnt[p:getKingdom()] or 0
    for _, v in pairs(cnt) do if v > most then most = v end end
    if same < most then n = n + 1 end
    local nxt, lst = p:getNextAlive(), p:getNextAlive(room:alivePlayerCount() - 1)
    if nxt and lst and nxt:objectName() ~= lst:objectName() and nxt:objectName() ~= p:objectName()
        and nxt:getKingdom() == lst:getKingdom() and nxt:getKingdom() ~= p:getKingdom() then
        n = n + 1
    end
    return n
end
diyba_fenzhong = sgs.CreateAttackRangeSkillV2 {
    name = "diyba_fenzhong", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("diyba_fenzhong") then return diyba_fz_count(p) end
        return 0
    end,
}
diyba_fenzhong_max = sgs.CreateMaxCardsSkillV2 {
    name = "#diyba_fenzhong_max", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("diyba_fenzhong") then return diyba_fz_count(p) end
        return 0
    end,
}
diyba_minglie = sgs.CreateTriggerSkillV2 {
    name = "diyba_minglie",
    events = { sgs.Damaged },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:hasSkill(skill:objectName()) or player:isDead() or player:isKongcheng() then return false end
        return skill:objectName()
    end,
    on_cost = function(skill, event, room, player, ctx)
        local victims = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getOtherPlayers(player)) do
            if not q:isKongcheng() then victims:append(q) end
        end
        if victims:isEmpty() then return false end
        local to = room:askForPlayerChosen(player, victims, skill:objectName(), "@diyba_minglie", true, true)
        if not to then return false end
        player:setTag("diyba_minglie_to", sgs.QVariant(to:objectName()))
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local name = player:getTag("diyba_minglie_to"):toString()
        player:removeTag("diyba_minglie_to")
        local to = room:findPlayer(name)
        if not to or to:isDead() or player:isKongcheng() or to:isKongcheng() then return false end
        local max = math.min(player:getHandcardNum(), to:getHandcardNum())
        local mine = room:askForExchange(player, skill:objectName(), max, 1, false, "@diyba_minglie_give")
        if not mine then return false end
        local n = mine:subcardsLength()
        local theirs = room:askForExchange(to, skill:objectName(), n, n, false, "@diyba_minglie_back")
        if not theirs then return false end
        room:moveCardTo(mine, player, to, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), to:objectName(), skill:objectName(), ""), false)
        room:moveCardTo(theirs, to, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, to:objectName(), player:objectName(), skill:objectName(), ""), false)
        local tag = "diyba_minglie_" .. to:objectName() .. "-Clear"
        if player:getMark(tag) == 0 then
            room:setPlayerMark(player, tag, 1)
            to:drawCards(1, skill:objectName())
        end
        -- record swappers for the end-of-turn slash
        local cur = room:getCurrent()
        local list = room:getTag("diyba_minglie_swap"):toString()
        for _, who in ipairs({ player:objectName(), to:objectName() }) do
            if not string.find("," .. list .. ",", "," .. who .. ",", 1, true) then
                list = (list == "") and who or (list .. "," .. who)
            end
        end
        room:setTag("diyba_minglie_swap", sgs.QVariant(list))
        return false
    end,
}
diyba_minglie_slash = diyba_record("#diyba_minglie_slash", {sgs.EventPhaseEnd}, function(self, event, room, p, data)
    if p:getPhase() ~= sgs.Player_Finish then return end
    local list = room:getTag("diyba_minglie_swap"):toString()
    room:removeTag("diyba_minglie_swap")
    if list == "" then return end
    for _, who in ipairs(list:split(",")) do
        local q = room:findPlayer(who)
        if q and q:isAlive() and p:isAlive() and q:objectName() ~= p:objectName() then
            room:askForUseSlashTo(q, p, "@diyba_minglie_slash", false)
        end
    end
end)
diyba_xj_pangyu:addSkill(diyba_fenzhong)
diyba_xj_pangyu:addSkill(diyba_fenzhong_max)
diyba_xj_pangyu:addSkill(diyba_minglie)
diyba_xj_pangyu:addSkill(diyba_minglie_slash)

------------------------------------------------------------------ 邓方
diyba_guoyi_card = sgs.CreateSkillCard {
    name = "diyba_guoyiCard", will_throw = false,
    filter = function(self, targets, to, from) return #targets == 0 end,
    feasible = function(self, targets) return #targets == 1 end,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        to:drawCards(1, "diyba_guoyi")
        local choice = room:askForChoice(to, "diyba_guoyi", "diyba_guoyi_give+diyba_guoyi_discard")
        if choice == "diyba_guoyi_give" then
            if to:getCardCount(true) < 2 then return end
            local ex = room:askForExchange(to, "diyba_guoyi", 2, 2, true, "@diyba_guoyi_give")
            if not ex then return end
            local red, black = false, false
            for _, id in sgs.qlist(ex:getSubcards()) do
                local c = sgs.Sanguosha:getCard(id)
                if c:isRed() then red = true elseif c:isBlack() then black = true end
                room:showCard(to, id)
            end
            room:obtainCard(source, ex, false)
            if red and not black then
                room:setPlayerCardLimitation(source, "use", ".|black", true)
            elseif black and not red then
                room:setPlayerCardLimitation(source, "use", ".|red", true)
            end
        else
            source:setTag("diyba_guoyi_target", sgs.QVariant(to:objectName()))
        end
    end,
}
diyba_guoyi = sgs.CreateViewAsSkillV2 {
    name = "diyba_guoyi",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c) return false end,
    card_selection_feasible = function(self, request) return true end,
    create_card = function(self, request)
        local c = diyba_guoyi_card:clone()
        c:setSkillName("diyba_guoyi")
        return c
    end,
}
diyba_guoyi_use = diyba_record("#diyba_guoyi_use", {sgs.CardFinished, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_NotActive then p:removeTag("diyba_guoyi_target") end
        return
    end
    local use = data:toCardUse()
    if use.from ~= p or not p:hasSkill("diyba_guoyi") or use.card:isKindOf("SkillCard") then return end
    local name = p:getTag("diyba_guoyi_target"):toString()
    if name == "" then return end
    local to = room:findPlayer(name)
    if not to or to:isDead() or to:isNude() then return end
    if p:askForSkillInvoke("diyba_guoyi", data) then
        local id = room:askForCardChosen(p, to, "he", "diyba_guoyi", false, sgs.Card_MethodDiscard)
        room:throwCard(id, to, p)
    end
end)
diyba_xj_dengfang:addSkill(diyba_guoyi)
diyba_xj_dengfang:addSkill(diyba_guoyi_use)

sgs.LoadTranslationTable {
    ["diyba_15j_zhangjuzhangchun"] = "张举&张纯", ["#diyba_15j_zhangjuzhangchun"] = "鹿走幽蓟", ["designer:diyba_15j_zhangjuzhangchun"] = "一网",
    ["diyba_jitian"] = "觊天",
    [":diyba_jitian"] = "锁定技，游戏开始时，你用两张3/4体力牌组成你的体力值。最靠近你武将牌的体力牌称为“觊鼎”，剩余的称为“弥天”。",
    ["diyba_juluan"] = "举乱",
    [":diyba_juluan"] = "锁定技，有角色进入过濒死状态的轮次结束时，你翻面“觊鼎”；你使用【杀】造成伤害后，你翻面“弥天”。你的体力牌翻面后，若所有体力牌勾玉数的奇偶性相同，你于当前结算后视为使用【南蛮入侵】。",
    ["diyba_lulve"] = "虏略",
    [":diyba_lulve"] = "锁定技，你的单目标锦囊牌视为【杀】；当一张“弥天”上的体力值首次变为0后，其不再计入体力上限而仅计入“举乱”，然后你摸等同于体力上限张牌并翻面。",
    ["diyba_xj_pangyu"] = "庞淯", ["#diyba_xj_pangyu"] = "秉节蹈刃", ["designer:diyba_xj_pangyu"] = "对勾",
    ["diyba_fenzhong"] = "奋忠",
    [":diyba_fenzhong"] = "锁定技，每满足以下一项，你的攻击范围与手牌上限均+1：1. 你不是野心家；2. 你是小势力角色；3. 你是被围攻角色。",
    ["diyba_minglie"] = "铭烈",
    [":diyba_minglie"] = "当你受到伤害后，你可与其他角色交换至少一张手牌，然后若为本回合首次对其发动则其摸一张牌。以此法交换过牌的角色可于此回合结束时对当前回合角色使用一张【杀】。",
    ["@diyba_minglie"] = "铭烈：你可以选择一名其他角色，与其交换至少一张手牌",
    ["@diyba_minglie_give"] = "铭烈：选择交给其的手牌",
    ["@diyba_minglie_back"] = "铭烈：选择交还的等量手牌",
    ["@diyba_minglie_slash"] = "铭烈：你可以对当前回合角色使用一张【杀】",
    ["diyba_xj_dengfang"] = "邓方", ["#diyba_xj_dengfang"] = "御土如磐", ["designer:diyba_xj_dengfang"] = "yyuaN",
    ["diyba_guoyi"] = "果毅",
    [":diyba_guoyi"] = "出牌阶段限一次，你可以令一名角色摸一张牌并选择一项：1.展示并交给你两张牌，你本回合只能使用这些颜色的牌；2.你本回合使用牌后，可以弃置其一张牌。",
    ["diyba_guoyi_give"] = "展示并交给其两张牌，其本回合只能使用这些颜色的牌",
    ["diyba_guoyi_discard"] = "其本回合使用牌后，可以弃置你一张牌",
    ["@diyba_guoyi_give"] = "果毅：展示并交给其两张牌",
}
end

