-- ===== diyba b18 =====
do
-- b18: diyba_re0_lihuowang (3DRE0 005)
local diyba_re0_lihuowang = sgs.General(extension, "diyba_re0_lihuowang", "qun", 4)

local function diyba_lhw_is_converted(card)
    return card and card:isVirtualCard() and card:subcardsLength() > 0 and not card:isKindOf("SkillCard")
end

local diyba_zhuizhenjia = sgs.CreateRuleSkillV2 {
    name = "diyba_zhuizhenjia", events = { sgs.CardFinished }, global = true,
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if not use.from or use.from:isDead() or not use.from:hasSkill(self:objectName()) then return false end
        if use.from:getMark("diyba_zhuizhenjia-Clear") > 0 or not diyba_lhw_is_converted(use.card) then return false end
        return self:objectName(), use.from
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local owner = use.from
        local tos = sgs.SPlayerList()
        for _, t in sgs.qlist(use.to) do
            if t:isAlive() and not t:isKongcheng() and t:objectName() ~= owner:objectName() then tos:append(t) end
        end
        if tos:isEmpty() or not owner:askForSkillInvoke(self:objectName(), ctx.original_data) then return false end
        room:addPlayerMark(owner, "diyba_zhuizhenjia-Clear")
        local to = room:askForPlayerChosen(owner, tos, self:objectName(), "@diyba_zhuizhenjia", false, true)
        if not to then return false end
        local id = room:askForCardChosen(owner, to, "h", self:objectName())
        room:showCard(to, id)
        local suit = sgs.Sanguosha:getCard(id):getSuit()
        room:obtainCard(owner, id, true)
        local differ = true
        for _, sid in sgs.qlist(use.card:getSubcards()) do
            if sgs.Sanguosha:getCard(sid):getSuit() == suit then differ = false end
        end
        if differ and to:isAlive() then
            local ids = sgs.IntList()
            for _, sid in sgs.qlist(use.card:getSubcards()) do
                if room:getCardPlace(sid) == sgs.Player_DiscardPile then ids:append(sid) end
            end
            if not ids:isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                dummy:addSubcards(ids)
                room:obtainCard(to, dummy, true)
                dummy:deleteLater()
            end
        end
        return false
    end,
}

local diyba_xiushixu = sgs.CreateRuleSkillV2 {
    name = "diyba_xiushixu", events = { sgs.CardFinished }, global = true,
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if not use.from or use.from:isDead() or not use.from:hasSkill(self:objectName()) then return false end
        if use.from:getMark("diyba_xiushixu-Clear") > 0 or not use.card:isVirtualCard() or use.card:isKindOf("SkillCard") then return false end
        if use.from:isNude() then return false end
        return self:objectName(), use.from
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local owner = use.from
        if not owner:askForSkillInvoke(self:objectName(), ctx.original_data) then return false end
        room:addPlayerMark(owner, "diyba_xiushixu-Clear")
        local ex = room:askForExchange(owner, self:objectName(), 2, 1, true, "@diyba_xiushixu", true)
        if not ex or ex:subcardsLength() == 0 then return false end
        local n = ex:subcardsLength()
        local before = {}
        for _, id in sgs.qlist(owner:handCards()) do before[id] = true end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, owner:objectName(), self:objectName(), "")
        room:moveCardTo(ex, owner, nil, sgs.Player_DiscardPile, reason)
        owner:drawCards(n, self:objectName())
        local same = false
        for _, id in sgs.qlist(owner:handCards()) do
            if not before[id] then
                room:showCard(owner, id)
                if sgs.Sanguosha:getCard(id):getTypeId() == use.card:getTypeId() then same = true end
            end
        end
        if same and owner:askForSkillInvoke(self:objectName(), sgs.QVariant("draw")) then
            owner:drawCards(1, self:objectName())
        end
        return false
    end,
}

-- 转换技: state 0 = (1) 火攻, state 1 = (2) 将一张牌当决斗
local diyba_dengchangjie = sgs.CreateViewAsSkillV2 {
    name = "diyba_dengchangjie",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c)
        if request:getInitiator():getMark("diyba_dengchangjie_state") % 2 == 0 then return false end
        return request:getSelectedCardIds():isEmpty() and not request:getInitiator():isJilei(c)
    end,
    card_selection_feasible = function(self, request)
        local n = request:getSelectedCardIds():length()
        if request:getInitiator():getMark("diyba_dengchangjie_state") % 2 == 0 then return n == 0 end
        return n == 1
    end,
    create_card = function(self, request)
        local odd = request:getInitiator():getMark("diyba_dengchangjie_state") % 2 == 1
        local c = sgs.Sanguosha:cloneCard(odd and "duel" or "fire_attack", sgs.Card_NoSuit, 0)
        if odd then c:addSubcards(request:getSelectedCardIds()) end
        c:setSkillName("diyba_dengchangjie")
        return c
    end,
}

local diyba_dengchangjie_effect = sgs.CreateRuleSkillV2 {
    name = "#diyba_dengchangjie_effect",
    events = { sgs.PreCardUsed, sgs.CardUsed, sgs.Damage, sgs.Damaged },
    global = true,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.from and use.card:getSkillName() == "diyba_dengchangjie" and use.from:hasSkill("diyba_dengchangjie") then
                room:addPlayerMark(use.from, "diyba_dengchangjie_state")
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            local from = use.from
            if from and from:getMark("diyba_dengchangjie_extra") > 0 and not use.card:isKindOf("SkillCard")
                and use.card:getSkillName() ~= "diyba_dengchangjie" then
                room:setPlayerMark(from, "diyba_dengchangjie_extra", 0)
                local cand = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not use.to:contains(p) and not room:isProhibited(from, p, use.card)
                        and use.card:targetFilter(sgs.PlayerList(), p, from) and use.to:length() > 0 then
                        cand:append(p)
                    end
                end
                if not cand:isEmpty() then
                    local t = room:askForPlayerChosen(from, cand, "diyba_dengchangjie", "@diyba_dengchangjie-extra", true, true)
                    if t then use.to:append(t); room:sortByActionOrder(use.to); data:setValue(use) end
                end
            end
        else
            local damage = data:toDamage()
            if not damage.card or damage.card:getSkillName() ~= "diyba_dengchangjie" then return end
            if event == sgs.Damage and damage.from and damage.from:hasSkill("diyba_dengchangjie") then
                -- approximation: reset the usage counts of this general's three skills
                room:addPlayerHistory(damage.from, "diyba_dengchangjie", -1)
                room:setPlayerMark(damage.from, "diyba_zhuizhenjia-Clear", 0)
                room:setPlayerMark(damage.from, "diyba_xiushixu-Clear", 0)
            elseif event == sgs.Damaged and damage.to and damage.to:hasSkill("diyba_dengchangjie") then
                room:setPlayerMark(damage.to, "diyba_dengchangjie_extra", 1)
            end
        end
    end,
}

diyba_re0_lihuowang:addSkill(diyba_zhuizhenjia)
diyba_re0_lihuowang:addSkill(diyba_xiushixu)
diyba_re0_lihuowang:addSkill(diyba_dengchangjie)
diyba_re0_lihuowang:addSkill(diyba_dengchangjie_effect)

sgs.LoadTranslationTable {
    ["diyba_re0_lihuowang"] = "李火旺",
    ["#diyba_re0_lihuowang"] = "虚实坐忘",
    ["designer:diyba_re0_lihuowang"] = "yyuaN",
    ["diyba_zhuizhenjia"] = "坠真假",
    [":diyba_zhuizhenjia"] = "每回合限一次，转化牌结算后，你可以展示并获得其中一名目标角色的一张手牌，若此牌与该转化牌对应实体牌花色均不同，其获得该转化牌。",
    ["@diyba_zhuizhenjia"] = "坠真假：选择一名目标角色",
    ["diyba_xiushixu"] = "修实虚",
    [":diyba_xiushixu"] = "每回合限一次，虚拟牌结算后，你可以重铸至多两张牌然后展示以此法获得的牌，若这些牌中有与该虚拟牌的类别相同的牌，你可以摸一张牌。",
    ["@diyba_xiushixu"] = "修实虚：重铸至多两张牌",
    ["diyba_dengchangjie"] = "登长阶",
    [":diyba_dengchangjie"] = "转换技，出牌阶段限一次，你可以①视为使用【火攻】；②将一张牌当【决斗】使用。你因此造成伤害后，你重置你一个技能的使用次数；你因此受到伤害后，你本回合使用的下一张牌可以额外指定一个目标。",
    ["@diyba_dengchangjie-extra"] = "登长阶：你可以额外指定一个目标",
}
end

