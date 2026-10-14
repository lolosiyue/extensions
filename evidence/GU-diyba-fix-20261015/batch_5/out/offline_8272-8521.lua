-- ===== diyba b06 =====
do
-- diyba batch b06 (3D15J001)
local function diyba_b06_trigger(name, events, effect, compulsory)
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
local function diyba_b06_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    c:addSubcards(ids)
    return c
end
diyba_15j_dingfei = sgs.General(extension, "diyba_15j_dingfei", "wei", 3)

-- 丁斐 畜突 / 坦婪
diyba_chutu = diyba_b06_trigger("diyba_chutu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Play or owner:isNude() or p:isDead() then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local put = room:askForExchange(owner, self:objectName(), owner:getCardCount(true), 1, "@diyba_chutu", "", ".", true)
    if not put or put:subcardsLength() == 0 then return end
    room:moveCardsAtomic(sgs.CardsMoveStruct(put:getSubcards(), owner, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), self:objectName(), "")), false)
    p:drawCards(4, self:objectName())
    local ids = sgs.IntList()
    local n = math.min(4, p:getHandcardNum())
    if n > 0 then
        local dis = room:askForExchange(p, self:objectName(), n, n, "@diyba_chutu-discard", "", ".|.|.|hand", false)
        if dis then ids = dis:getSubcards() end
    end
    local pile = sgs.IntList()
    if not ids:isEmpty() then
        local d = diyba_b06_dummy(ids)
        room:throwCard(d, self:objectName(), p)
        d:deleteLater()
        for _, id in sgs.qlist(ids) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then pile:append(id) end
        end
    end
    if pile:isEmpty() then return end
    local choice = room:askForChoice(p, self:objectName(), "diyba_chutu_use+diyba_chutu_put", data)
    if choice == "diyba_chutu_use" then
        for _, id in sgs.qlist(pile) do
            local c = sgs.Sanguosha:getCard(id)
            if owner:isAlive() and p:isAlive() and room:getCardPlace(id) == sgs.Player_DiscardPile
                and (c:isKindOf("Slash") or c:isKindOf("TrickCard") and c:isNDTrick()) then
                room:useCard(sgs.CardUseStruct(c, owner, p), false)
            end
        end
    else
        local avail = sgs.IntList()
        for _, id in sgs.qlist(pile) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then avail:append(id) end
        end
        if not avail:isEmpty() then
            room:fillAG(avail, owner)
            local picked = {}
            while not avail:isEmpty() do
                local id = room:askForAG(owner, avail, true, self:objectName())
                if id < 0 then break end
                avail:removeOne(id)
                room:takeAG(nil, id, false)
                table.insert(picked, id)
            end
            room:clearAG(owner)
            for _, id in ipairs(picked) do
                room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile, false)
            end
        end
        room:setPlayerMark(p, "diyba_chutu_limit-Clear", 1)
    end
end)
diyba_chutu_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#diyba_chutu_prohibit",
    holder_selector = sgs.CorrectSkill_System,
    gate = { "secondary.mark:diyba_chutu_limit-Clear" },
    is_prohibited = function(self, ctx)
        local from, to = ctx:getFrom(), ctx:getTo()
        return from:getMark("diyba_chutu_limit-Clear") > 0 and from ~= to
    end,
}
diyba_tanlan = diyba_b06_trigger("diyba_tanlan", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Finish then return end
    local list = sgs.SPlayerList()
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if not o:isKongcheng() then list:append(o) end
    end
    if list:isEmpty() or not owner:askForSkillInvoke(self:objectName(), data) then return end
    local to = room:askForPlayerChosen(owner, list, self:objectName(), "@diyba_tanlan")
    local id = room:askForCardChosen(owner, to, "h", self:objectName())
    room:obtainCard(owner, id, false)
    local x = owner:getHandcardNum()
    if to:isDead() or owner:isDead() or to:getHandcardNum() < x or x == 0 then return end
    local give = room:askForExchange(to, self:objectName(), to:getHandcardNum(), x, "@diyba_tanlan-exchange", "", ".|.|.|hand", true)
    if not give or give:subcardsLength() < x then return end
    local mine = sgs.IntList()
    for _, c in sgs.qlist(owner:getHandcards()) do mine:append(c:getEffectiveId()) end
    local theirs = give:getSubcards()
    local d1, d2 = diyba_b06_dummy(theirs), diyba_b06_dummy(mine)
    room:obtainCard(owner, d1, false)
    room:obtainCard(to, d2, false)
    d1:deleteLater() d2:deleteLater()
end)
diyba_15j_dingfei:addSkill(diyba_chutu)
diyba_15j_dingfei:addSkill(diyba_chutu_prohibit)
diyba_15j_dingfei:addSkill(diyba_tanlan)

sgs.LoadTranslationTable {
    ["diyba_15j_dingfei"] = "丁斐", ["#diyba_15j_dingfei"] = "贪不殉利", ["designer:diyba_15j_dingfei"] = "左小白",
    ["diyba_chutu"] = "畜突",
    [":diyba_chutu"] = "其他角色的出牌阶段开始时，你可以将至少一张牌置于牌堆顶，令其摸四张牌，弃置其四张手牌，然后其选择一项：你依次对其使用以此法弃置的【杀】或普通锦囊牌；你将以此法弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌。",
    ["@diyba_chutu-discard"] = "畜突：请弃置四张手牌",
    ["@diyba_chutu"] = "畜突：请选择至少一张牌置于牌堆顶",
    ["diyba_chutu_use"] = "你依次对其使用以此法弃置的【杀】或普通锦囊牌",
    ["diyba_chutu_put"] = "你将以此法弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌",
    ["diyba_tanlan"] = "坦婪",
    [":diyba_tanlan"] = "结束阶段，你可以获得一名其他角色的一张手牌，然后其可以用至少X张手牌交换你的所有手牌（X为你的手牌数）。",
    ["@diyba_tanlan"] = "坦婪：选择一名其他角色，获得其一张手牌",
    ["@diyba_tanlan-exchange"] = "坦婪：你可以用至少X张手牌交换其所有手牌",
}
end

