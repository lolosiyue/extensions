-- 国战卡牌扩展包
-- 包含国战模式专属的特殊卡牌

local extension = sgs.Package("guozhan", sgs.Package_CardPack)

sgs.LoadTranslationTable{
    ["guozhan"] = "国战卡牌(未完成)",
}

-- ========================================
-- 调虎离山
-- ========================================

sgs.LoadTranslationTable{
    ["TiaohuLishan"] = "调虎离山",
    [":TiaohuLishan"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：至多两名角色<br/><b>效果</b>：目标角色进入休整状态直至本回合结束。",
}

-- 调虎离山卡牌
TiaohuLishan = sgs.CreateTrickCard{
    name = "TiaohuLishan",
    subclass = sgs.LuaTrickCard_TypeNormal,  -- 普通锦囊（即时生效）
    
    -- 目标过滤：可以选择至多两名其他角色
    filter = function(self, targets, to_select)
        -- 最多选择2个目标
        if #targets >= 2 then
            return false
        end
        
        -- 不能选择已经休整的角色
        if to_select:isRest() then
            return false
        end
        
        return true
    end,
    
    -- 目标数量检查：至少1个，至多2个
    feasible = function(self, targets)
        return #targets >= 1 and #targets <= 2
    end,
    
    -- 卡牌效果
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local target = effect.to
        
        -- 让目标角色休整直至本回合结束
        -- 使用休整包的机制
        room:directRestPlayer(target, "TiaohuLishan", false)
        
        -- 不设置waitTurn，在当前回合结束时就会解除休整
    end,
    
    -- 可以被无懈可击响应
    can_recast = false,
}

-- 添加调虎离山的恢复机制（全局技能）
local TiaohuLishanRecover = sgs.CreateRuleSkillV2{
    name = "#TiaohuLishanRecover",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.EventPhaseEnd},  -- 改为回合结束阶段
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or player:getPhase() ~= sgs.Player_Finish then return "" end
        return self:objectName(), player
    end,
    on_effect = function(self, event, room, player, ctx)
        local room = player:getRoom()
        
        -- 在回合结束阶段（Finish阶段结束时）检查
        if player:getPhase() ~= sgs.Player_Finish or player:isDead() then 
            return false 
        end
        
        -- 检查所有休整中的玩家
        for _, p in sgs.qlist(room:getRestPlayers()) do
            if p:isRest() then
                local reason = p:getTag("RestReason"):toString()
                
                -- 如果是调虎离山造成的休整，立即解除
                if reason == "TiaohuLishan" then
                    local msg = sgs.LogMessage()
                    msg.type = "#RestOneTurnRecover"
                    msg.from = p
                    room:sendLog(msg)
                    
                    room:unrestPlayer(p, false)
                end
            end
        end
        
        return false
    end
}

-- 注册技能和卡牌
addToSkills(TiaohuLishanRecover)

-- 添加卡牌到牌堆
-- 红桃调虎离山 x2
for i = 1, 2 do
    local card = TiaohuLishan:clone()
    card:setSuit(sgs.Card_Heart)
    card:setNumber(3 + i - 1)  -- 红桃3、4
    card:setParent(extension)
end

-- 方片调虎离山 x2
for i = 1, 2 do
    local card = TiaohuLishan:clone()
    card:setSuit(sgs.Card_Diamond)
    card:setNumber(4 + i - 1)  -- 方片4、5
    card:setParent(extension)
end

-- ========================================
-- 知己知彼
-- ========================================

sgs.LoadTranslationTable{
    ["ZhijiZhibi"] = "知己知彼",
    [":ZhijiZhibi"] = "锦囊牌（可重铸）<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色或不选目标<br/><b>效果</b>：若选择目标，你观看目标角色的手牌；若不选目标，重铸此牌。",
}

-- 知己知彼卡牌
ZhijiZhibi = sgs.CreateTrickCard{
    name = "ZhijiZhibi",
    subclass = sgs.LuaTrickCard_TypeNormal,  -- 普通锦囊
    can_recast = true,    -- 可以重铸
    
    -- 目标过滤：可以选择一名有手牌的其他角色
    filter = function(self, targets, to_select, player)
        -- 最多选择1个目标
        if #targets >= 1 then
            return false
        end
        
        -- 不能选择自己
        if to_select:objectName() == player:objectName() then
            return false
        end
        
        -- 不能选择没有手牌的角色
        if to_select:isKongcheng() then
            return false
        end
        
        return true
    end,
    
    -- 目标数量检查：0个或1个都可以
    -- 0个目标 = 重铸，1个目标 = 使用
    feasible = function(self, targets)
        return #targets == 0 or #targets == 1
    end,
    
    -- 卡牌使用前的处理
    on_use = function(self, room, source, targets)
        -- 如果没有选择目标，执行重铸
        if #targets == 0 then
            UseCardRecast(source, self, "", 1)
            return
        end
        
        -- 有目标，执行正常的卡牌效果
        local use = room:getTag("cardUseStruct" .. self:toString()):toCardUse()
        for _, to in ipairs(targets) do
            local effect = sgs.CardEffectStruct()
            effect.from = source
            effect.card = self
            effect.multiple = #targets > 1
            effect.to = to
            effect.no_offset = table.contains(use.no_offset_list, "_ALL_TARGETS") or table.contains(use.no_offset_list, to:objectName())
            effect.no_respond = table.contains(use.no_respond_list, "_ALL_TARGETS") or table.contains(use.no_respond_list, to:objectName())
            effect.nullified = table.contains(use.nullified_list, "_ALL_TARGETS") or table.contains(use.nullified_list, to:objectName())
            room:cardEffect(effect)
        end
    end,
    
    -- 卡牌效果
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local source = effect.from  -- 使用者
        local target = effect.to    -- 目标角色
        
        -- 观看目标角色的手牌
        room:showAllCards(target, source)
        
        -- 为观看者设置 visible 标记
        -- 表示这些手牌对观看者来说是已知的
        local handcards = target:handCards()
        for _, card_id in sgs.qlist(handcards) do
            -- 设置卡牌对观看者可见的标记
            -- 格式：visible_观看者名字
            room:setCardFlag(card_id, "visible_" .. source:objectName())
        end
        
        -- 注意：这个标记只对当前手牌有效
        -- 目标后续摸的新牌不会有这个标记（符合游戏逻辑）
    end,
}

-- 添加知己知彼到牌堆
-- 黑桃知己知彼 x2
for i = 1, 2 do
    local card = ZhijiZhibi:clone()
    card:setSuit(sgs.Card_Spade)
    card:setNumber(12 + i - 1)  -- 黑桃12、13
    card:setParent(extension)
end

-- 梅花知己知彼 x2
for i = 1, 2 do
    local card = ZhijiZhibi:clone()
    card:setSuit(sgs.Card_Club)
    card:setNumber(12 + i - 1)  -- 梅花12、13
    card:setParent(extension)
end

-- ========================================
-- 六龙骖驾
-- ========================================

sgs.LoadTranslationTable{
    ["LiulongCanjia"] = "六龙骖驾",
    [":LiulongCanjia"] = "装备牌，坐骑。<br/><b>占据+1马栏和-1马栏。</b><br/>你计算与其他角色的距离-1，其他角色计算与你的距离+1。",
}

-- 六龙骖驾（同时占据+1马栏和-1马栏）
-- 使用CreateOffensiveHorse作为基础，然后通过occupy_slots占据两个马栏
LiulongCanjia = sgs.CreateOffensiveHorse{
    name = "LiulongCanjia",
    class_name = "LiulongCanjia",
    correct = -1,  -- -1马效果（你计算与其他角色的距离-1）
    occupy_slots = {2, 3},  -- 2=-1马栏, 3=+1马栏
}

-- 六龙骖驾的+1马效果技能（其他角色计算与你的距离+1）
local LiulongCanjiaDefensive = sgs.CreateDistanceSkillV2{
    name = "#LiulongCanjiaDefensive", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local to = ctx:getSecondary()
        -- 保留 donor 的实体六龙骖驾限制；无武将实例，不建立虚构来源。
        local horse = to and to:getOffensiveHorse()
        return horse and horse:objectName() == "LiulongCanjia" and 1 or false
    end,
}
-- 注册技能
addToSkills(LiulongCanjiaDefensive)

-- 添加六龙骖驾到牌堆
-- 红桃六龙骖驾 x1
local card = LiulongCanjia:clone()
card:setSuit(sgs.Card_Heart)
card:setNumber(5)  -- 红桃5
card:setParent(extension)

-- ========================================
-- 定澜夜明珠
-- ========================================

sgs.LoadTranslationTable{
    ["DinglanYemingzhu"] = "定澜夜明珠",
    [":DinglanYemingzhu"] = "装备牌，宝物。<br/>当你装备此装备时，你视为拥有技能【制衡】；若你已经拥有【制衡】，则升级为【界制衡】。",
}

-- 定澜夜明珠宝物牌
local DinglanYemingzhu = sgs.CreateTreasure{
    name = "DinglanYemingzhu", class_name = "DinglanYemingzhu",
    on_install = function(self, player)
        local room = player:getRoom()
        if player:hasSkill("tenyearzhiheng") then return end
        local key = "DinglanYemingzhu_" .. self:getEffectiveId()
        local upgraded = player:hasSkill("zhiheng")
        if upgraded then
            -- 保留原技能实例与状态，仅暂时失效；卸装不会重新创建或误删另一实例。
            local ids = player:getSkillInstanceIds("zhiheng")
            if ids:isEmpty() then return end
            local choices = {}
            for _, id in sgs.qlist(ids) do table.insert(choices, tostring(id)) end
            local id = ids:first()
            if #choices > 1 then id = tonumber(room:askForChoice(player, "DinglanYemingzhu", table.concat(choices, "+"))) end
            if not id or id <= 0 or not ids:contains(id) then return end
            player:setTag(key .. "_original", sgs.QVariant(id))
            room:addSkillInvalidity(player, "zhiheng", player:objectName(), key, id)
        end
        local name = upgraded and "tenyearzhiheng" or "zhiheng"
        local granted = room:acquireSkill(player, name, false, true, false)
        if granted <= 0 then
            local original = player:getTag(key .. "_original"):toInt()
            if original > 0 then room:removeSkillInvalidity(player, "zhiheng", player:objectName(), key, original) end
            player:removeTag(key .. "_original")
            return
        end
        player:setTag(key .. "_granted", sgs.QVariant(granted))
        player:setTag(key .. "_name", sgs.QVariant(name))
        local msg = sgs.LogMessage(); msg.from = player
        msg.type = upgraded and "#DinglanYemingzhu_Upgrade" or "#DinglanYemingzhu_Acquire"
        msg.arg = "zhiheng"; if upgraded then msg.arg2 = "tenyearzhiheng" end
        room:sendLog(msg)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        local key = "DinglanYemingzhu_" .. self:getEffectiveId()
        local original = player:getTag(key .. "_original"):toInt()
        local granted = player:getTag(key .. "_granted"):toInt()
        local name = player:getTag(key .. "_name"):toString()
        -- 名称加精确 ID 是引擎既有 detach 语法，仅移除此装备实际授予的实例。
        if granted > 0 then room:detachSkillFromPlayer(player, name .. "#" .. granted, true, true, false) end
        if original > 0 then room:removeSkillInvalidity(player, "zhiheng", player:objectName(), key, original) end
        if granted > 0 then
            local msg = sgs.LogMessage(); msg.from = player
            msg.type = original > 0 and "#DinglanYemingzhu_Downgrade" or "#DinglanYemingzhu_Lose"
            msg.arg = original > 0 and "tenyearzhiheng" or "zhiheng"
            if original > 0 then msg.arg2 = "zhiheng" end
            room:sendLog(msg)
        end
        player:removeTag(key .. "_original"); player:removeTag(key .. "_granted"); player:removeTag(key .. "_name")
    end,
}
-- 添加定澜夜明珠到牌堆
-- 方片定澜夜明珠 x1
local card = DinglanYemingzhu:clone()
card:setSuit(sgs.Card_Diamond)
card:setNumber(6)  -- 方片6
card:setParent(extension)

-- 定澜夜明珠日志翻译
sgs.LoadTranslationTable{
    ["#DinglanYemingzhu_Acquire"] = "%from 因装备【定澜夜明珠】获得了技能【%arg】",
    ["#DinglanYemingzhu_Upgrade"] = "%from 因装备【定澜夜明珠】将技能【%arg】升级为【%arg2】",
    ["#DinglanYemingzhu_Downgrade"] = "%from 因卸下【定澜夜明珠】将技能【%arg】恢复为【%arg2】",
    ["#DinglanYemingzhu_Lose"] = "%from 因卸下【定澜夜明珠】失去了技能【%arg】",
}


return extension
