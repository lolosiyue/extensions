-- ===== diyba b06 =====
do
-- diyba batch b06 (3D14J008, 3D15J001, 3D15J002; 3D14J009 skipped)
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
local function diyba_b06_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end
local function diyba_b06_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    c:addSubcards(ids)
    return c
end
local function diyba_b06_use_virtual(room, owner, name, skill)
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not c then return end
    c:setSkillName(skill)
    local targets = sgs.SPlayerList()
    if not c:targetFixed() then
        local list = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if c:targetFilter(sgs.PlayerList(), p, owner) then list:append(p) end
        end
        if list:isEmpty() then c:deleteLater() return end
        targets:append(room:askForPlayerChosen(owner, list, skill, "@" .. skill .. "-target"))
    end
    room:useCard(sgs.CardUseStruct(c, owner, targets), false)
    c:deleteLater()
end

diyba_14j_yuanxi = sgs.General(extension, "diyba_14j_yuanxi", "qun", 4)
diyba_15j_dingfei = sgs.General(extension, "diyba_15j_dingfei", "wei", 3)
diyba_15j_qinlang = sgs.General(extension, "diyba_15j_qinlang", "wei", 4)

-- 袁熙 纨纨 / 然然 / 凛凛
local function diyba_b06_recast_one(room, owner, skill)
    local c = room:askForCard(owner, "..", "@" .. skill, sgs.QVariant(), sgs.Card_MethodNone)
    if not c then return nil end
    local color, ctype = c:isRed(), c:getTypeId()
    room:recastCards(owner, c:getSubcards(), skill)
    return c
end
diyba_wanwan = diyba_b06_trigger("diyba_wanwan", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Draw or p:isNude() then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local c1 = room:askForCard(owner, "..", "@diyba_wanwan", data, sgs.Card_MethodNone)
    if not c1 then return end
    local red1 = c1:isRed()
    room:recastCards(owner, c1:getSubcards(), self:objectName())
    local c2 = room:askForCard(owner, "..", "@diyba_wanwan", data, sgs.Card_MethodNone)
    if c2 then
        local red2 = c2:isRed()
        local same = (red1 == red2) and (c1:isBlack() == c2:isBlack())
        room:recastCards(owner, c2:getSubcards(), self:objectName())
        if same and owner:isAlive() then
            local name = sgs.Sanguosha:cloneCard("await_exhausted", sgs.Card_NoSuit, 0) and "await_exhausted" or "heg_await_exhausted"
            diyba_b06_use_virtual(room, owner, name, self:objectName())
            if owner:isAlive() then owner:insertPhase(sgs.Player_Draw) end
        end
    end
    return true
end)
diyba_ranran_rec = diyba_b06_record("#diyba_ranran_rec", {sgs.CardUsed}, function(self, event, room, p, data)
    local use = data:toCardUse()
    if not use.card or use.card:getTypeId() == sgs.Card_TypeSkill then return end
    local t = use.from:getTag("diyba_ranran_types"):toString()
    if t == "" or t == "off" then return end
    use.from:setTag("diyba_ranran_types", sgs.QVariant(t .. "," .. tostring(use.card:getTypeId())))
end)
diyba_ranran = diyba_b06_trigger("diyba_ranran", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Play then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    owner:setTag("diyba_ranran_types", sgs.QVariant("x"))
    room:askForUseCard(owner, "..", "@diyba_ranran")
    room:askForUseCard(owner, "..", "@diyba_ranran")
    local t = owner:getTag("diyba_ranran_types"):toString():split(",")
    owner:setTag("diyba_ranran_types", sgs.QVariant("off"))
    if #t >= 3 and t[2] == t[3] and owner:isAlive() then
        diyba_b06_use_virtual(room, owner, "zhujinqiyuan", self:objectName())
        if owner:isAlive() then owner:insertPhase(sgs.Player_Play) end
    end
    return true
end)
diyba_linlin = diyba_b06_trigger("diyba_linlin", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Discard or p:isNude() then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local c1 = room:askForCard(owner, "..", "@diyba_linlin", data, sgs.Card_MethodDiscard)
    if not c1 then return end
    local suit = c1:getSuit()
    local c2 = room:askForCard(owner, "..", "@diyba_linlin", data, sgs.Card_MethodDiscard)
    if c2 and c2:getSuit() == suit and owner:isAlive() then
        diyba_b06_use_virtual(room, owner, "archery_attack", self:objectName())
        if owner:isAlive() then owner:insertPhase(sgs.Player_Discard) end
    end
    return true
end)
diyba_14j_yuanxi:addSkill(diyba_wanwan)
diyba_14j_yuanxi:addSkill(diyba_ranran)
diyba_14j_yuanxi:addSkill(diyba_ranran_rec)
diyba_14j_yuanxi:addSkill(diyba_linlin)

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
    for _, c in sgs.qlist(p:getHandcards()) do
        if ids:length() < 4 then ids:append(c:getEffectiveId()) end
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
        room:setPlayerCardLimitation(p, "use", "Card", true)
    end
end)
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
diyba_15j_dingfei:addSkill(diyba_tanlan)

-- 秦朗 征云 (first stage only)
diyba_zhengyun = sgs.CreateViewAsSkillV2 {
    name = "diyba_zhengyun",
    can_activate = function(self, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty()
            and (c:isKindOf("Slash") or c:isKindOf("Duel") or c:isKindOf("FireAttack")
                or c:isKindOf("ArcheryAttack") or c:isKindOf("SavageAssault"))
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("zhujinqiyuan", sgs.Card_SuitToBeDecided, -1)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("diyba_zhengyun"); return c
    end,
}
diyba_15j_qinlang:addSkill(diyba_zhengyun)

sgs.LoadTranslationTable {
    ["diyba_14j_yuanxi"] = "袁熙", ["#diyba_14j_yuanxi"] = "沉缶破瓮", ["designer:diyba_14j_yuanxi"] = "传说中的易大剧",
    ["diyba_wanwan"] = "纨纨",
    [":diyba_wanwan"] = "额定摸牌阶段，你可以改为重铸一张牌，然后重铸一张牌。若为相同颜色，你视为使用【以逸待劳】，然后执行一个额外的摸牌阶段。",
    ["@diyba_wanwan"] = "纨纨：请重铸一张牌",
    ["diyba_ranran"] = "然然",
    [":diyba_ranran"] = "额定出牌阶段，你可以改为使用一张牌，然后使用一张牌。若为相同类型，你视为使用【逐近弃远】，然后执行一个额外的出牌阶段。",
    ["@diyba_ranran"] = "然然：请使用一张牌",
    ["diyba_linlin"] = "凛凛",
    [":diyba_linlin"] = "额定弃牌阶段，你可以改为弃置一张牌，然后弃置一张牌。若为相同花色，你视为使用【万箭齐发】，然后执行一个额外的弃牌阶段。",
    ["@diyba_linlin"] = "凛凛：请弃置一张牌",
    ["diyba_15j_dingfei"] = "丁斐", ["#diyba_15j_dingfei"] = "贪不殉利", ["designer:diyba_15j_dingfei"] = "左小白",
    ["diyba_chutu"] = "畜突",
    [":diyba_chutu"] = "其他角色的出牌阶段开始时，你可以将至少一张牌置于牌堆顶，令其摸四张牌，弃置其四张手牌，然后其选择一项：你依次对其使用以此法弃置的【杀】或普通锦囊牌；你将以此法弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌。",
    ["@diyba_chutu"] = "畜突：请选择至少一张牌置于牌堆顶",
    ["diyba_chutu_use"] = "令其对你依次使用弃置的【杀】或普通锦囊牌",
    ["diyba_chutu_put"] = "将弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌",
    ["diyba_tanlan"] = "坦婪",
    [":diyba_tanlan"] = "结束阶段，你可以获得一名其他角色的一张手牌，然后其可以用至少X张手牌交换你的所有手牌（X为你的手牌数）。",
    ["@diyba_tanlan"] = "坦婪：选择一名其他角色，获得其一张手牌",
    ["@diyba_tanlan-exchange"] = "坦婪：你可以用至少X张手牌交换其所有手牌",
    ["diyba_15j_qinlang"] = "秦朗", ["#diyba_15j_qinlang"] = "纛立朔土", ["designer:diyba_15j_qinlang"] = "猪",
    ["diyba_zhengyun"] = "征云",
    [":diyba_zhengyun"] = "你可以将一张伤害类牌当【逐近弃远】使用；然后可以将以上牌获得的一张伤害类牌当【无中生有】使用；然后可以将以上牌获得的两张伤害类牌当【增兵减灶】使用；然后可以将以上牌获得的三张伤害类牌依次当你本回合使用的前三张普通锦囊牌使用。",
}
end

