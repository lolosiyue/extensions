-- ===== diyba b10 =====
do
-- b10: diyba 朱异 (更狩). 阎行 skipped. 廖立/刘基 skipped (体力1.5).
local function diyba10_trigger(name, events, effect)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = sgs.Skill_NotFrequent,
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
local function diyba10_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

-- 朱异
diyba_xj_zhuyi = sgs.General(extension, "diyba_xj_zhuyi", "wu", 2)

diyba_gengshou = diyba10_trigger("diyba_gengshou", {sgs.Damage, sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if event == sgs.Damage then
        local damage = data:toDamage()
        if damage.from ~= owner or not damage.card or not damage.card:isKindOf("Slash")
            or damage.transfer or damage.chain then return end
        local list = { owner }
        for _, t in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:inMyAttackRange(t) then table.insert(list, t) end
        end
        for _, t in ipairs(list) do
            if owner:isDead() then return end
            if t:isAlive() then
                local choice = room:askForChoice(t, "diyba_gengshou", "draw+discard+cancel", ToData(owner))
                if choice == "draw" then
                    owner:drawCards(1, "diyba_gengshou")
                elseif choice == "discard" and not owner:isNude() then
                    room:askForDiscard(owner, "diyba_gengshou", 1, 1, false, true)
                end
            end
        end
    else
        if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
        -- 若你没有此阶段获得的手牌: none of the cards obtained this phase is still in hand
        local got = owner:getTag("diyba_gengshou_ids"):toString()
        if got ~= "" then
            for _, n in ipairs(got:split("+")) do
                local id = tonumber(n)
                if id and owner:handCards():contains(id) then return end
            end
        end
        if not owner:askForSkillInvoke("diyba_gengshou_slash", data) then return end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("diyba_gengshou")
        local targets = sgs.SPlayerList()
        for _, t in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:canSlash(t, slash, true) then targets:append(t) end
        end
        if not targets:isEmpty() then
            local to = room:askForPlayerChosen(owner, targets, "diyba_gengshou", "@diyba_gengshou-slash", true)
            if to then room:useCard(sgs.CardUseStruct(slash, owner, to), false) end
        end
        slash:deleteLater()
    end
end)
diyba_gengshou_record = diyba10_record("#diyba_gengshou_record", {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then player:removeTag("diyba_gengshou_ids") end
            return
        end
        local move = data:toMoveOneTime()
        if not move.to or move.to_place ~= sgs.Player_PlaceHand then return end
        local to = room:findPlayerByObjectName(move.to:objectName())
        if to and to:hasSkill("diyba_gengshou") and to:getPhase() == sgs.Player_Play then
            local ids = {}
            local old = to:getTag("diyba_gengshou_ids"):toString()
            if old ~= "" then table.insert(ids, old) end
            for _, id in sgs.qlist(move.card_ids) do table.insert(ids, tostring(id)) end
            to:setTag("diyba_gengshou_ids", sgs.QVariant(table.concat(ids, "+")))
        end
    end)
diyba_xj_zhuyi:addSkill(diyba_gengshou)
diyba_xj_zhuyi:addSkill(diyba_gengshou_record)

sgs.LoadTranslationTable {
    ["diyba_xj_zhuyi"] = "朱异",
    ["#diyba_xj_zhuyi"] = "大节巉天",
    ["designer:diyba_xj_zhuyi"] = "猪",
    ["diyba_gengshou"] = "更狩",
    [":diyba_gengshou"] = "你使用【杀】造成伤害后，你与你攻击范围内的角色依次可以令你摸或弃置一张牌。出牌阶段结束时，若你没有此阶段获得的手牌，你可以视为使用一张【杀】。",
    ["diyba_gengshou:draw"] = "令其摸一张牌",
    ["diyba_gengshou:discard"] = "令其弃置一张牌",
    ["diyba_gengshou:cancel"] = "取消",
    ["diyba_gengshou_slash"] = "更狩",
    ["@diyba_gengshou-slash"] = "更狩：选择视为使用【杀】的目标",
}
end

