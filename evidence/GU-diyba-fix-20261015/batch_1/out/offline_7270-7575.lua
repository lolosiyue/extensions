-- ===== diyba b01 =====
do
-- diyba batch b01 (3D10J 002/003/005/006)
local function diyba_trigger(name, events, effect, compulsory)
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
local function diyba_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

diyba_10j_zhangti = sgs.General(extension, "diyba_10j_zhangti", "wu", 3)
diyba_10j_zhugejing = sgs.General(extension, "diyba_10j_zhugejing", "wei", 4)

-- 张悌 逆势 / 覆江
diyba_nishi = diyba_trigger("diyba_nishi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    local minother
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if not minother or o:getHandcardNum() < minother then minother = o:getHandcardNum() end
    end
    if not minother then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName())
    if owner:getHandcardNum() < minother then
        local n = minother + 1 - owner:getHandcardNum()
        if n > 0 then owner:drawCards(n, self:objectName()) end
    end
    local cands = sgs.SPlayerList()
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if o:getHandcardNum() < owner:getHandcardNum() then cands:append(o) end
    end
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, self:objectName(), "@diyba_nishi", false, true)
    if not to then return end
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, owner:objectName(), to:objectName(), self:objectName(), "")
    moves:append(sgs.CardsMoveStruct(owner:handCards(), owner, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
    moves:append(sgs.CardsMoveStruct(to:handCards(), to, owner, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
    room:moveCardsAtomic(moves, false)
end, true)
diyba_fujiang = diyba_trigger("diyba_fujiang", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    local move = data:toMoveOneTime()
    if not move.from or move.from:objectName() ~= owner:objectName() or not move.to
        or move.to:objectName() == owner:objectName() or move.to_place ~= sgs.Player_PlaceHand then return end
    local to
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if o:objectName() == move.to:objectName() then to = o end
    end
    if not to or to:isDead() or not owner:askForSkillInvoke(self:objectName(), data) then return end
    if to:hasEquip() then
        local id = room:askForCardChosen(owner, to, "e", self:objectName())
        if id and id >= 0 then room:throwCard(id, to, owner) end
    else
        room:damage(sgs.DamageStruct(self:objectName(), owner, to, 1))
    end
end)
diyba_10j_zhangti:addSkill(diyba_nishi)
diyba_10j_zhangti:addSkill(diyba_fujiang)

-- 诸葛靓 三思 / 竭忠
local function diyba_sansi_switch(room, owner)
    room:setPlayerMark(owner, "diyba_sansi_state", (owner:getMark("diyba_sansi_state") + 1) % 3)
end
local diyba_sansiCard = sgs.CreateSkillCard {
    name = "diyba_sansiCard", will_throw = false,
    filter = function(self, targets, to, source) return #targets == 0 end,
    feasible = function(self, targets, source) return #targets == 1 end,
    on_use = function(self, room, source, targets)
        local ids = sgs.IntList()
        for _, id in sgs.qlist(self:getSubcards()) do ids:append(id) end
        diyba_sansi_switch(room, source)
        room:recastCards(source, ids, "diyba_sansi")
        if targets[1] and targets[1]:isAlive() then targets[1]:drawCards(3, "diyba_sansi") end
    end,
}
local function diyba_sansi_ok(state, cards, final)
    local n = #cards
    if state == 0 then return final and n == 2 or n < 2 end
    local seen = {}
    for _, c in ipairs(cards) do
        local k = state == 1 and c:getTypeId() or c:getSuit()
        if seen[k] then return false end
        seen[k] = true
    end
    local need = state == 1 and 3 or 4
    if final then return n == need end
    return n < need
end
diyba_sansi = sgs.CreateViewAsSkillV2 {
    name = "diyba_sansi",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c)
        local p = request:getInitiator()
        if p:isJilei(c) then return false end
        local cards = {}
        for _, id in sgs.qlist(request:getSelectedCardIds()) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
        table.insert(cards, c)
        return diyba_sansi_ok(p:getMark("diyba_sansi_state"), cards, false)
    end,
    card_selection_feasible = function(self, request)
        local cards = {}
        for _, id in sgs.qlist(request:getSelectedCardIds()) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
        return diyba_sansi_ok(request:getInitiator():getMark("diyba_sansi_state"), cards, true)
    end,
    create_card = function(self, request)
        local c = diyba_sansiCard:clone()
        c:addSubcards(request:getSelectedCardIds())
        c:setSkillName("diyba_sansi")
        return c
    end,
}
diyba_jiezhong = diyba_trigger("diyba_jiezhong", {sgs.EnterDying, sgs.RoundStart}, function(self, event, room, p, data, owner)
    if event == sgs.RoundStart then
        room:setPlayerMark(owner, "diyba_jiezhong_used", 0)
        return
    end
    if p == owner or owner:getMark("diyba_jiezhong_used") > 0 or not owner:askForSkillInvoke(self:objectName(), data) then return end
    room:setPlayerMark(owner, "diyba_jiezhong_used", 1)
    if p:getHp() < 1 then
        room:recover(p, sgs.RecoverStruct(self:objectName(), owner, 1 - p:getHp()))
    end
    diyba_sansi_switch(room, owner)
    local state = owner:getMark("diyba_sansi_state")
    if state == 0 then
        room:loseHp(owner, 1)
    elseif state == 2 then
        room:setPlayerMark(owner, "diyba_jiezhong_used", 0)
    end
end)
diyba_10j_zhugejing:addSkill(diyba_sansi)
diyba_10j_zhugejing:addSkill(diyba_jiezhong)

sgs.LoadTranslationTable {
    ["diyba_10j_zhangti"] = "张悌", ["#diyba_10j_zhangti"] = "枯浪哀潮", ["designer:diyba_10j_zhangti"] = "晨曦千载",
    ["diyba_nishi"] = "逆势",
    [":diyba_nishi"] = "锁定技，准备阶段，你须与手牌少于你的一名其他角色交换手牌。若你为手牌最少的角色，你须先将手牌摸至比手牌数最少的其他角色多一张牌。",
    ["@diyba_nishi"] = "逆势：选择一名手牌少于你的其他角色，与其交换手牌",
    ["diyba_fujiang"] = "覆江",
    [":diyba_fujiang"] = "其他角色获得你的牌时，若其装备区里：有牌，你可以弃置其中一张牌；没有牌，你可以对该角色造成1点伤害。",
    ["diyba_10j_zhugejing"] = "诸葛靓", ["#diyba_10j_zhugejing"] = "失恨咽漆", ["designer:diyba_10j_zhugejing"] = "绝代倾国倾城貌",
    ["diyba_sansi"] = "三思",
    [":diyba_sansi"] = "转换技，出牌阶段限一次，你可以重铸①两张牌②三种类别的牌③四种花色的牌，令一名角色摸三张牌。",
    ["diyba_jiezhong"] = "竭忠",
    [":diyba_jiezhong"] = "每轮限一次，其他角色进入濒死时，你可以令其将体力值回复至1点，然后你转换“三思”的状态；然后若“三思”状态：为①，你失去1点体力；为③，重置此技能。",
}
end

