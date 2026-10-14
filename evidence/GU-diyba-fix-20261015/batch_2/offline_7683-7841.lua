-- ===== diyba b03 =====
do
-- diyba b03: 3D12J (孙和, 周处). Pasted inside `do ... end` of offline.lua; `extension` is the package.
local diyba_round = 0
local diyba_granted = {}

local diyba_round_record = sgs.CreateRuleSkillV2 {
    name = "#diyba_12j_round", events = { sgs.RoundStart }, global = true,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        diyba_round = diyba_round + 1
        for name, _ in pairs(diyba_granted) do
            local p = room:findPlayer(name, true)
            if p and p:hasSkill("diyba_mingye") and p:getGeneralName() ~= "diyba_12j_sunhe"
                and p:getGeneral2Name() ~= "diyba_12j_sunhe" then
                room:detachSkillFromPlayer(p, "diyba_mingye", false, true)
            end
        end
        diyba_granted = {}
    end,
}
extension:addSkills(diyba_round_record)

local function diyba_is_sunhe(p)
    return p:getGeneralName() == "diyba_12j_sunhe" or p:getGeneral2Name() == "diyba_12j_sunhe"
end

local diyba_mingye = sgs.CreateTriggerSkillV2 {
    name = "diyba_mingye",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardUsed },
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return false end
        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() or not use.card then return false end
        if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
        local own_turn = room:getCurrent() and room:getCurrent():objectName() == player:objectName()
        local key = "diyba_mingye_" .. (own_turn and "in" or "out")
        if player:getMark(key) == diyba_round then return false end
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, ctx) return true end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local own_turn = room:getCurrent() and room:getCurrent():objectName() == player:objectName()
        room:setPlayerMark(player, "diyba_mingye_" .. (own_turn and "in" or "out"), diyba_round)
        room:broadcastSkillInvoke(self:objectName())
        local card = use.card
        -- cancel the card and do not count it toward use limits
        if card:isVirtualCard() or not card:isVirtualCard() then
            room:addPlayerHistory(player, card:getClassName(), -1)
        end
        player:drawCards(2, self:objectName())
        if diyba_is_sunhe(player) then
            local hearts = room:askForCard(player, ".|heart", "@diyba-mingye-discard", ctx.original_data,
                sgs.Card_MethodDiscard)
            if hearts and player:isWounded() then
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
        else
            local sunhe
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if diyba_is_sunhe(p) then sunhe = p break end
            end
            if sunhe and room:askForSkillInvoke(player, "diyba_mingye_give", sgs.QVariant("@diyba-mingye-give")) then
                room:obtainCard(sunhe, card, true)
            end
        end
        return true -- cancel the used card
    end,
}

local diyba_dangshu = sgs.CreateTriggerSkillV2 {
    name = "diyba_dangshu",
    events = { sgs.HpChanged },
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return false end
        if player:getMark("diyba_dangshu_round") == diyba_round then return false end
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, ctx)
        local others = room:getOtherPlayers(player)
        if others:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, others, self:objectName(), "@diyba-dangshu", true, true)
        if not target then return false end
        ctx.targets:append(target)
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        local target = ctx.targets:first()
        room:setPlayerMark(player, "diyba_dangshu_round", diyba_round)
        if target and target:isAlive() and not target:hasSkill("diyba_mingye") then
            room:acquireSkill(target, "diyba_mingye")
            diyba_granted[target:objectName()] = true
        end
        return false
    end,
}

local diyba_xiaheng = sgs.CreateTriggerSkillV2 {
    name = "diyba_xiaheng",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.EventPhaseStart },
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Play then
            return self:objectName()
        end
        return false
    end,
    on_cost = function(self, event, room, player, ctx) return true end,
    on_effect = function(self, event, room, player, ctx)
        room:broadcastSkillInvoke(self:objectName())
        local a = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@diyba-xiaheng-discard", false, true)
        for i = 1, 2 do
            if a:isNude() then break end
            local id = room:askForCardChosen(player, a, "he", self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(id, a, player)
        end
        if not player:isAlive() then return false end
        local b = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@diyba-xiaheng-damage", false, true)
        room:damage(sgs.DamageStruct(self:objectName(), player, b, 1))
        if not player:isAlive() then return false end
        local pn = player:objectName()
        if a:objectName() ~= pn and b:objectName() ~= pn then
            room:loseMaxHp(player, 1)
        elseif a:objectName() == b:objectName() then
            room:loseHp(player, 1)
        end
        -- "删除【】中的内容" has no defined target in the source text; not implemented.
        return false
    end,
}

local diyba_12j_sunhe = sgs.General(extension, "diyba_12j_sunhe", "wu", 3)
diyba_12j_sunhe:addSkill(diyba_mingye)
diyba_12j_sunhe:addSkill(diyba_dangshu)
local diyba_12j_zhouchu = sgs.General(extension, "diyba_12j_zhouchu", "wu", 5)
diyba_12j_zhouchu:addSkill(diyba_xiaheng)

sgs.LoadTranslationTable {
    ["diyba_12j_sunhe"] = "孙和", ["&diyba_12j_sunhe"] = "孙和", ["#diyba_12j_sunhe"] = "季子绝途",
    ["designer:diyba_12j_sunhe"] = "再見末日基因",
    ["diyba_mingye"] = "命也",
    [":diyba_mingye"] = "锁定技，回合内外每轮各限一次，你使用基本牌或普通锦囊牌时，你取消此牌，且令之不计限制次数，然后摸两张牌。若如此做，若你为孙和，则你可弃置一张红桃牌，回复1点体力；否则你可令孙和获得被取消的牌。",
    ["@diyba-mingye-discard"] = "命也：你可弃置一张红桃牌，回复1点体力",
    ["diyba_mingye_give"] = "命也：令孙和获得被取消的牌",
    ["diyba_dangshu"] = "党乎",
    [":diyba_dangshu"] = "每轮限一次，你的体力值改变后，你可令一名其他角色于本轮中拥有“命也”。",
    ["@diyba-dangshu"] = "党乎：你可令一名其他角色于本轮中拥有“命也”",
    ["diyba_12j_zhouchu"] = "周处", ["&diyba_12j_zhouchu"] = "周处", ["#diyba_12j_zhouchu"] = "云蛟何惧",
    ["designer:diyba_12j_zhouchu"] = "志文",
    ["diyba_xiaheng"] = "侠横",
    [":diyba_xiaheng"] = "锁定技，出牌阶段开始时，你弃置一名角色两张牌（不足则全弃），再对一名角色造成1点伤害。若两名角色，均不为你，你减1点体力上限；为同一名角色，你失去1点体力；然后若以此法选择包括你在内三名不同的角色，你删除【】中的内容。",
    ["@diyba-xiaheng-discard"] = "侠横：选择一名角色，弃置其两张牌",
    ["@diyba-xiaheng-damage"] = "侠横：选择一名角色，对其造成1点伤害",
}
end

