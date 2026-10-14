-- ===== diyba b10 =====
do
-- b10: diyba 朱异 (更狩), 阎行 (叛约). 廖立/刘基 skipped (体力1.5).
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
        if owner:getMark("diyba_gengshou_got") > 0 then return end
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
            if player:getPhase() == sgs.Player_Play then room:setPlayerMark(player, "diyba_gengshou_got", 0) end
            return
        end
        local move = data:toMoveOneTime()
        if not move.to or move.to_place ~= sgs.Player_PlaceHand then return end
        local to = room:findPlayerByObjectName(move.to:objectName())
        if to and to:hasSkill("diyba_gengshou") and to:getPhase() == sgs.Player_Play then
            room:setPlayerMark(to, "diyba_gengshou_got", 1)
        end
    end)
diyba_xj_zhuyi:addSkill(diyba_gengshou)
diyba_xj_zhuyi:addSkill(diyba_gengshou_record)

-- 阎行
diyba_xj_yanxing = sgs.General(extension, "diyba_xj_yanxing", "qun", 2)

-- records the final target list of the converted card
diyba_panyue_record = diyba10_record("#diyba_panyue_record", {sgs.CardUsed}, function(self, event, room, player, data)
    local use = data:toCardUse()
    if not use.card or use.card:getSkillName() ~= "diyba_panyue" or not use.from then return end
    local names = {}
    for _, t in sgs.qlist(use.to) do table.insert(names, t:objectName()) end
    use.from:setTag("diyba_panyue_targets", sgs.QVariant(table.concat(names, "+")))
end)

local diyba_panyue_card = sgs.CreateSkillCard {
    name = "diyba_panyueCard", will_throw = false, target_fixed = true,
    on_use = function(self, room, source, targets)
        local slash = sgs.Sanguosha:getCard(self:getSubcards():first())
        local id = slash:getEffectiveId()
        local trick = sgs.Sanguosha:cloneCard("fight_together", sgs.Card_NoSuit, 0)
        if not trick then trick = sgs.Sanguosha:cloneCard("heg_fight_together", sgs.Card_NoSuit, 0) end
        if not trick then return end
        trick:addSubcard(id)
        trick:setSkillName("diyba_panyue")
        if not trick:isAvailable(source) then trick:deleteLater() return end
        source:removeTag("diyba_panyue_targets")
        local drew = source:isChained() -- chained targets draw a card, others become chained
        room:useCard(sgs.CardUseStruct(trick, source, source), false)
        trick:deleteLater()
        if source:isDead() then return end
        local names = source:getTag("diyba_panyue_targets"):toString()
        source:removeTag("diyba_panyue_targets")
        local others = sgs.SPlayerList()
        if names ~= "" then
            for _, n in ipairs(names:split("+")) do
                local t = room:findPlayerByObjectName(n)
                if t and t:isAlive() and t:objectName() ~= source:objectName() then others:append(t) end
            end
        end
        if others:isEmpty() then return end
        local other = others:first()
        if others:length() > 1 then
            other = room:askForPlayerChosen(source, others, "diyba_panyue", "@diyba_panyue-choose", false)
        end
        if not other then return end
        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then return end
        local card = sgs.Sanguosha:getCard(id)
        card:setSkillName("diyba_panyue")
        if drew then
            -- the other target uses this Slash (against a target of their choice)
            local tos = sgs.SPlayerList()
            for _, t in sgs.qlist(room:getOtherPlayers(other)) do
                if other:canSlash(t, card, false) then tos:append(t) end
            end
            if not tos:isEmpty() then
                local to = room:askForPlayerChosen(other, tos, "diyba_panyue", "@diyba_panyue-slash", false)
                if to then room:useCard(sgs.CardUseStruct(card, other, to), false) end
            end
        else
            if source:canSlash(other, card, false) then
                room:useCard(sgs.CardUseStruct(card, source, other), false)
            end
        end
    end,
}
diyba_panyue = sgs.CreateViewAsSkillV2 {
    name = "diyba_panyue",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and c:isKindOf("Slash")
    end,
    card_selection_feasible = function(self, request)
        return request:getSelectedCardIds():length() == 1
    end,
    create_card = function(self, request)
        local c = diyba_panyue_card:clone()
        c:addSubcards(request:getSelectedCardIds())
        c:setSkillName("diyba_panyue")
        return c
    end,
}
diyba_xj_yanxing:addSkill(diyba_panyue)
diyba_xj_yanxing:addSkill(diyba_panyue_record)

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
    ["diyba_xj_yanxing"] = "阎行",
    ["#diyba_xj_yanxing"] = "贰心顾瞻",
    ["designer:diyba_xj_yanxing"] = "静谦",
    ["diyba_panyue"] = "叛约",
    [":diyba_panyue"] = "出牌阶段限一次，你可以将一张【杀】当【勠力同心】使用（目标须包含你）。若你因此摸牌，你令另一名目标角色使用此【杀】，否则你对另一名目标角色使用此【杀】。",
    ["@diyba_panyue-choose"] = "叛约：选择另一名目标角色",
    ["@diyba_panyue-slash"] = "叛约：使用此【杀】的目标",
}
end

