local extension = sgs.Package("xiuzheng", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["xiuzheng"] = "休整包",
    ["#RestOneTurnRecover"] = "%from 的休整效果结束，从休整状态中恢复",
    ["rest_caopi"] = "休整-曹丕", ["&rest_caopi"] = "曹丕",
    ["rest_fangzhu"] = "放逐",
    [":rest_fangzhu"] = "每当你受到伤害后，你可以令一名其他角色摸X张牌，然后令其休整至其回合结束。（X为你已损失的体力值）",
    ["rest_caoren"] = "休整-曹仁", ["&rest_caoren"] = "曹仁",
    ["rest_jushou"] = "据守",
    [":rest_jushou"] = "结束阶段开始时，你可以摸五张牌，然后休整一回合。",
}

local function restPlayerOneTurn(room, player, reason)
    local current = room:getCurrent()
    if current and player:objectName() == current:objectName() then
        player:setTag("waitTurn", sgs.QVariant(1))
    end
    room:directRestPlayer(player, reason, false)
end

-- 沿用 donor：所有非空 RestReason 都参与下一轮恢复，不增加技能白名单。
local rest_one_turn_recover = sgs.CreateRuleSkillV2{
    name = "#rest_one_turn_recover", frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if not player or player:getPhase() ~= sgs.Player_RoundStart or player:isDead() then return "" end
        return self:objectName(), player
    end,
    on_effect = function(self, event, room, player, ctx)
        for _, p in sgs.qlist(room:getRestPlayers()) do
            if p:isRest() and p:getTag("RestReason"):toString() ~= "" then
                local next_player = p:getNextAlive()
                if next_player and next_player:objectName() == player:objectName() then
                    local wait = p:getTag("waitTurn"):toInt()
                    if wait > 0 then p:setTag("waitTurn", sgs.QVariant(wait - 1))
                    else
                        local msg = sgs.LogMessage(); msg.type = "#RestOneTurnRecover"; msg.from = p; room:sendLog(msg)
                        room:unrestPlayer(p, false)
                    end
                end
            end
        end
    end,
}
addToSkills(rest_one_turn_recover)

local rest_caopi = sgs.General(extension, "$rest_caopi", "wei", 3)
rest_caopi:setImage("caopi"); rest_caopi:addSkill("mobilexingshang")
local rest_fangzhu = sgs.CreateTriggerSkillV2{
    name = "rest_fangzhu", events = {sgs.Damaged},
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() then return "" end
        return self:objectName(), player
    end,
    on_cost = function(self, event, room, player, ctx)
        local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fangzhu-invoke", player:getMark("JilveEvent") ~= 35, true)
        if not to then return false end
        ctx.targets:append(to)
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        local to = ctx.targets:first(); to:drawCards(player:getLostHp() * self:getEffectiveAmount(ctx), self:objectName())
        restPlayerOneTurn(room, to, self:objectName()); room:notifySkillInvoked(player, self:objectName())
    end,
}
rest_caopi:addSkill(rest_fangzhu)

local rest_caoren = sgs.General(extension, "rest_caoren", "wei", 4); rest_caoren:setImage("caoren")
local rest_jushou = sgs.CreateTriggerSkillV2{
    name = "rest_jushou", base_amount = 5, events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if not player or player:getPhase() ~= sgs.Player_Finish then return "" end
        return self:objectName(), player
    end,
    on_cost = function(self, event, room, player, ctx) return room:askForSkillInvoke(player, self:objectName()) end,
    on_effect = function(self, event, room, player, ctx) player:drawCards(self:getEffectiveAmount(ctx), self:objectName()); restPlayerOneTurn(room, player, self:objectName()) end,
}
rest_caoren:addSkill(rest_jushou)

return extension
