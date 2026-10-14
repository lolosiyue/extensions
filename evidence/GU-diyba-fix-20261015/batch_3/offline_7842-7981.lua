-- ===== diyba b04 =====
do
-- diyba batch b04
local diyba_kebineng = sgs.General(extension, "diyba_xj_kebineng", "qun", 4)
local diyba_zhangkai = sgs.General(extension, "diyba_xj_zhangkai", "qun", 4)

local function diyba_owner_trigger(name, events, effect)
    return sgs.CreateTriggerSkillV2 {
        name = name, events = events,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_cost = function(self, event, room, player, ctx)
            local owner = ctx.owner or player
            return room:askForSkillInvoke(owner, self:objectName(), ctx.original_data)
        end,
        on_effect = function(self, event, room, player, ctx)
            effect(self, event, room, ctx.owner or player, player, ctx.original_data)
            return false
        end,
    }
end

-- 柯比能
diyba_xiaoxing = sgs.CreateAttackRangeSkillV2 {
    name = "diyba_xiaoxing", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("diyba_xiaoxing") then return 3 end
        return 0
    end,
}
diyba_xiaoxing_keep = sgs.CreateMaxCardsSkillV2 {
    name = "#diyba_xiaoxing_keep", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("diyba_xiaoxing") then return 3 end
        return 0
    end,
}
diyba_langzhi = sgs.CreateTriggerSkillV2 {
    name = "diyba_langzhi", events = { sgs.EventPhaseStart },
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        return false
    end,
    on_cost = function(self, event, room, player, ctx)
        return room:askForSkillInvoke(player, self:objectName(), ctx.original_data)
    end,
    on_effect = function(self, event, room, player, ctx)
        local name = self:objectName()
        local holder, shown = {}, sgs.IntList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:inMyAttackRange(p) and not p:isNude() then
                local id = room:askForCardChosen(p, p, "he", name)
                if id and id >= 0 then
                    room:showCard(p, id)
                    holder[id] = p
                    shown:append(id)
                end
            end
        end
        if shown:isEmpty() then return false end
        local chosen, avail = {}, sgs.IntList()
        for _, id in sgs.qlist(shown) do avail:append(id) end
        while not avail:isEmpty() do
            local id = room:askForAG(player, avail, #chosen > 0, name)
            if not id or id < 0 then break end
            table.insert(chosen, id)
            avail:removeOne(id)
        end
        if #chosen == 0 then return false end
        local choice = room:askForChoice(player, name, "replace+obtain", ctx.original_data)
        if choice == "replace" and player:getCardCount(true) >= #chosen then
            local ex = room:askForExchange(player, name, #chosen, #chosen, true, "@diyba_langzhi")
            if ex and ex:subcardsLength() == #chosen then
                local mine = ex:getSubcards()
                for i, id in ipairs(chosen) do
                    local to = holder[id]
                    if to and to:isAlive() then room:obtainCard(to, mine:at(i - 1), false) end
                    room:obtainCard(player, id, false)
                end
                return false
            end
        end
        for _, id in ipairs(chosen) do room:obtainCard(player, id, false) end
        room:detachSkillFromPlayer(player, name)
        return false
    end,
}
diyba_kebineng:addSkill(diyba_xiaoxing)
diyba_kebineng:addSkill(diyba_xiaoxing_keep)
diyba_kebineng:addSkill(diyba_langzhi)

-- 张闿 (劫行 not implemented)
diyba_bailei = diyba_owner_trigger("diyba_bailei", { sgs.RoundStart }, function(self, event, room, owner, player, data)
    local name = self:objectName()
    local ones, maxs, maxhp = {}, {}, -1
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:getHp() == 1 then table.insert(ones, p) end
        if p:getHp() > maxhp then maxhp = p:getHp(); maxs = { p }
        elseif p:getHp() == maxhp then table.insert(maxs, p) end
    end
    local choices = {}
    if #ones == 1 then table.insert(choices, "kill") end
    if #maxs == 1 then table.insert(choices, "damage") end
    if #choices == 0 then return end
    local c = room:askForChoice(owner, name, table.concat(choices, "+"))
    if c == "kill" then
        room:killPlayer(ones[1])
    else
        room:damage(sgs.DamageStruct(name, owner, maxs[1], 2))
    end
end)
diyba_zhangkai:addSkill(diyba_bailei)

sgs.LoadTranslationTable {
    ["diyba_xj_kebineng"] = "轲比能",
    ["#diyba_xj_kebineng"] = "雄兼漠南",
    ["diyba_xiaoxing"] = "枭行",
    [":diyba_xiaoxing"] = "锁定技，你的攻击范围和手牌上限+3；你进入濒死状态时，若轮次数大于一，且伤害来源装备了武器牌，其可废除其武器栏，令你失去“枭行”。",
    ["diyba_langzhi"] = "狼志",
    [":diyba_langzhi"] = "结束阶段，你可令你攻击范围内的所有角色各展示一张牌，你选择其中任意张牌并选择一项：1.用等量牌替换这些牌；2.获得这些牌，失去“狼志”。",
    ["diyba_langzhi:replace"] = "用等量牌替换这些牌",
    ["diyba_langzhi:obtain"] = "获得这些牌，失去“狼志”",
    ["@diyba_langzhi"] = "狼志：选择等量牌替换",
    ["diyba_xj_zhangkai"] = "张闿",
    ["#diyba_xj_zhangkai"] = "诡随贪豺",
    ["diyba_bailei"] = "拜泪",
    [":diyba_bailei"] = "轮次开始时，你可杀死体力值唯一为1的角色，或对体力唯一最多的角色造成2点伤害。",
    ["diyba_bailei:kill"] = "杀死体力值唯一为1的角色",
    ["diyba_bailei:damage"] = "对体力唯一最多的角色造成2点伤害",
}
end

