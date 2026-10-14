-- ===== diyba b02 =====
do
-- diyba b02: 刘宏 (3D10J 007)
local diyba_liuhong = sgs.General(extension, "diyba_10j_liuhong", "qun", 4)

local diyba_shixing_granted = "diyba_shixing_granted"

local function diyba_shixing_refresh(room)
    local trick_used = room:getTag("diyba_shixing_trick"):toBool()
    local female = false
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:isFemale() then female = true break end
    end
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:hasSkill("diyba_shixing") then
            local want = {}
            if female then table.insert(want, "xiangle") end
            if not trick_used then table.insert(want, "jiushi") end
            if #want == 0 then table.insert(want, "zhiheng") end
            local old = p:getTag(diyba_shixing_granted):toString()
            local oldset = {}
            if old ~= "" then
                for s in string.gmatch(old, "[^,]+") do oldset[s] = true end
            end
            local newset = {}
            for _, s in ipairs(want) do newset[s] = true end
            local ops = {}
            for s in pairs(oldset) do
                if not newset[s] then table.insert(ops, "-" .. s) end
            end
            for s in pairs(newset) do
                if not oldset[s] and not p:hasSkill(s) then table.insert(ops, s) end
            end
            if #ops > 0 then
                room:handleAcquireDetachSkills(p, table.concat(ops, "|"))
            end
            local kept = {}
            for s in pairs(newset) do
                if oldset[s] or not p:hasSkill(s) or true then table.insert(kept, s) end
            end
            p:setTag(diyba_shixing_granted, sgs.QVariant(table.concat(kept, ",")))
        end
    end
end

local diyba_shixing = sgs.CreateRuleSkillV2 {
    name = "diyba_shixing",
    events = { sgs.CardUsed, sgs.EventPhaseStart, sgs.Death },
    global = true,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("TrickCard") then
                room:setTag("diyba_shixing_trick", sgs.QVariant(true))
            end
        elseif event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_RoundStart then
            room:setTag("diyba_shixing_trick", sgs.QVariant(false))
        end
        diyba_shixing_refresh(room)
    end,
}

local diyba_dangu = sgs.CreateTriggerSkillV2 {
    name = "diyba_dangu",
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(skill:objectName())
            and player:getPhase() == sgs.Player_Finish then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local x = 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getKingdom() == "qun" then x = x + 1 end
        end
        if x == 0 then return false end
        local others = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0, x, "@diyba_dangu", true, true)
        if not others or others:length() == 0 then return false end
        for _, t in sgs.qlist(others) do ctx.targets:append(t) end
        return true
    end,
    on_effect_target = function(skill, event, room, player, ctx, target)
        if not target:isChained() then room:setPlayerChained(target) end
        return false
    end,
}

diyba_liuhong:addSkill(diyba_shixing)
diyba_liuhong:addSkill(diyba_dangu)

sgs.LoadTranslationTable {
    ["diyba_10j_liuhong"] = "刘宏",
    ["#diyba_10j_liuhong"] = "乱既损何",
    ["designer:diyba_10j_liuhong"] = "拉普拉斯",
    ["diyba_shixing"] = "失兴",
    [":diyba_shixing"] = "锁定技，若有存活的女性角色，你视为拥有“享乐”；若当前回合没有锦囊牌被使用，你视为拥有“酒诗”；若你没有上述技能，你视为拥有“制衡”。",
    ["diyba_dangu"] = "党锢",
    [":diyba_dangu"] = "回合结束时，你可以横置至多X名角色（X为群势力角色数）；其他角色的弃牌阶段，若其处于“连环状态”，其装备区里的牌视为手牌。",
    ["@diyba_dangu"] = "党锢：你可以横置至多X名角色（X为群势力角色数）",
}
end

