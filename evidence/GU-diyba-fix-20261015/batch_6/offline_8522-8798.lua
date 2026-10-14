-- ===== diyba b07 =====
do
-- diyba batch b07 (3D15J 003 xumiao, 006 yangxi; 004 huoyi / 005 guoyouzhi skipped)
local function diyba7_trigger(name, events, effect, compulsory)
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
                    cancelled = effect(self, event, room, player, ctx.original_data, p, event) or cancelled
                end
            end
            return cancelled
        end,
    }
end

-- use a virtual card (name/suit/number) against targets chosen by the user
local function diyba7_use(room, user, name, suit, number, skillname)
    local c = sgs.Sanguosha:cloneCard(name, suit or sgs.Card_NoSuit, number or 0)
    c:setSkillName(skillname)
    if not c:isAvailable(user) then c:deleteLater() return false end
    local cands = sgs.SPlayerList()
    local pl = sgs.PlayerList()
    for _, to in sgs.qlist(room:getAlivePlayers()) do
        if c:targetFilter(pl, to, user) and not user:isProhibited(to, c) then cands:append(to) end
    end
    local use = sgs.CardUseStruct()
    use.card = c
    use.from = user
    if c:targetFixed() then
        if c:isKindOf("Peach") and not user:isWounded() then c:deleteLater() return false end
    else
        if cands:isEmpty() then c:deleteLater() return false end
        local n = 1
        if c:isKindOf("Collateral") then c:deleteLater() return false end
        local to = room:askForPlayerChosen(user, cands, skillname, "@diyba7_target:" .. name)
        if not to then c:deleteLater() return false end
        use.to:append(to)
    end
    room:useCard(use)
    return true
end

diyba_15j_xumiao = sgs.General(extension, "diyba_15j_xumiao", "wei", 3)
diyba_15j_yangxi = sgs.General(extension, "diyba_15j_yangxi", "shu", 3)

-- 徐邈 绘骨: remember instant cards that entered the discard pile this turn
local function diyba_huigu_ids(room)
    local s = room:getTag("diyba_huigu_ids"):toString()
    return s == "" and {} or s:split("+")
end
diyba_huigu_rec = sgs.CreateRuleSkillV2 {
    name = "#diyba_huigu_rec", events = { sgs.CardsMoveOneTime, sgs.TurnStart }, global = true,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        if event == sgs.TurnStart then
            room:setTag("diyba_huigu_ids", sgs.QVariant(""))
            return
        end
        local move = ctx.original_data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile then return end
        local ids = diyba_huigu_ids(room)
        for _, id in sgs.qlist(move.card_ids) do
            local c = sgs.Sanguosha:getCard(id)
            if c:isKindOf("BasicCard") or (c:isKindOf("TrickCard") and not c:isKindOf("DelayedTrick")) then
                table.insert(ids, tostring(id))
            end
        end
        room:setTag("diyba_huigu_ids", sgs.QVariant(table.concat(ids, "+")))
    end,
}
local diyba_huiguCard = sgs.CreateSkillCard {
    name = "diyba_huiguCard", target_fixed = true, will_throw = false,
    on_use = function(self, room, source, targets)
        local list = sgs.IntList()
        for _, s in ipairs(diyba_huigu_ids(room)) do
            local id = tonumber(s)
            if room:getCardPlace(id) == sgs.Player_DiscardPile then list:append(id) end
        end
        if list:isEmpty() then return end
        room:addPlayerMark(source, "diyba_huigu-Clear")
        local id = room:askForAG(source, list, true, "diyba_huigu")
        if not id or id < 0 then return end
        local c = sgs.Sanguosha:getCard(id)
        diyba7_use(room, source, c:objectName(), c:getSuit(), c:getNumber(), "diyba_huigu")
    end,
}
diyba_huigu = sgs.CreateViewAsSkillV2 {
    name = "diyba_huigu",
    can_activate = function(self, request)
        local p = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and p:getMark("diyba_huigu-Clear") == 0 and p:getMark("drank") > 0
    end,
    can_select_card = function() return false end,
    card_selection_feasible = function(self, request) return true end,
    create_card = function(self, request)
        local c = diyba_huiguCard:clone()
        c:setSkillName("diyba_huigu")
        return c
    end,
}

-- 徐邈 清贤: items 1 drank, 2 use a card, 3 undrank, 4 draw; neighbours cyclic.
local function diyba_qingxian_item(self, room, owner, item)
    if item == 1 then
        if owner:getMark("drank") == 0 then room:setPlayerMark(owner, "drank", 1) end
    elseif item == 2 then
        room:askForUseCard(owner, ".", "@diyba_qingxian_use")
    elseif item == 3 then
        if owner:getMark("drank") > 0 then room:setPlayerMark(owner, "drank", 0) end
    else
        owner:drawCards(1, "diyba_qingxian")
    end
end
local function diyba_qingxian_after(self, room, owner, done, data)
    if owner:isDead() or owner:hasFlag("diyba_qingxian_doing") then return end
    local a, b = done % 4 + 1, (done + 2) % 4 + 1
    local names = { "diyba_qx1", "diyba_qx2", "diyba_qx3", "diyba_qx4" }
    local choices = names[a] .. "+" .. names[b] .. "+cancel"
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local ch = room:askForChoice(owner, self:objectName(), choices)
    if ch == "cancel" then return end
    local item = tonumber(string.sub(ch, -1))
    owner:setFlags("diyba_qingxian_doing")
    diyba_qingxian_item(self, room, owner, item)
    owner:setFlags("-diyba_qingxian_doing")
end
diyba_qingxian = diyba7_trigger("diyba_qingxian", { sgs.CardFinished, sgs.CardsMoveOneTime, sgs.MarkChanged },
    function(self, event, room, p, data, owner, ev)
        if owner:hasFlag("diyba_qingxian_doing") then return end
        if ev == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from == owner and use.card and use.card:getSkillName() ~= "diyba_qingxian" and not use.card:isKindOf("SkillCard") then
                diyba_qingxian_after(self, room, owner, 2, data)
            end
        elseif ev == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == owner:objectName() and move.to_place == sgs.Player_PlaceHand
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
                and move.reason.m_skillName ~= "diyba_qingxian" then
                diyba_qingxian_after(self, room, owner, 4, data)
            end
        else
            local mark = data:toMark()
            if p == owner and mark.name == "drank" then
                if mark.gain > 0 then diyba_qingxian_after(self, room, owner, 1, data)
                elseif mark.gain < 0 then diyba_qingxian_after(self, room, owner, 3, data) end
            end
        end
    end)
diyba_15j_xumiao:addSkill(diyba_huigu)
diyba_15j_xumiao:addSkill(diyba_huigu_rec)
diyba_15j_xumiao:addSkill(diyba_qingxian)

-- 杨戏 妙锦: every two physical instant cards used -> suit of one + number of the other
local function diyba_miaojin_names(suit, number)
    local set, names = {}, {}
    for id = 0, sgs.Sanguosha:getCardCount() - 1 do
        local c = sgs.Sanguosha:getEngineCard(id)
        if c:getSuit() == suit and c:getNumber() == number
            and (c:isKindOf("BasicCard") or (c:isKindOf("TrickCard") and not c:isKindOf("DelayedTrick")))
            and not set[c:objectName()] then
            set[c:objectName()] = true
            table.insert(names, c:objectName())
        end
    end
    return names
end
diyba_miaojin = diyba7_trigger("diyba_miaojin", { sgs.CardFinished }, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:isVirtualCard() or use.card:isKindOf("SkillCard")
        or use.card:getSkillName() == "diyba_miaojin" then return end
    if not (use.card:isKindOf("BasicCard") or (use.card:isKindOf("TrickCard") and not use.card:isKindOf("DelayedTrick"))) then return end
    local s = owner:getTag("diyba_miaojin_rec"):toString()
    local rec = s == "" and {} or s:split("+")
    table.insert(rec, use.card:getSuit() .. "_" .. use.card:getNumber() .. "_" .. use.card:getType())
    if #rec < 2 then
        owner:setTag("diyba_miaojin_rec", sgs.QVariant(table.concat(rec, "+")))
        return
    end
    owner:setTag("diyba_miaojin_rec", sgs.QVariant(""))
    if owner:isDead() or not owner:askForSkillInvoke(self:objectName(), data) then return end
    local a, b = rec[1]:split("_"), rec[2]:split("_")
    -- choose which card gives the suit; the other gives the number
    local pick = room:askForChoice(owner, self:objectName(), "diyba_mj_first+diyba_mj_second")
    local suit, number, srctype
    if pick == "diyba_mj_first" then
        suit, number, srctype = tonumber(a[1]), tonumber(b[2]), a[3]
    else
        suit, number, srctype = tonumber(b[1]), tonumber(a[2]), b[3]
    end
    local names = diyba_miaojin_names(suit, number)
    if #names == 0 then return end
    local name = room:askForChoice(owner, self:objectName(), table.concat(names, "+"))
    local ctype = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    local newtype = ctype:getType()
    ctype:deleteLater()
    if diyba7_use(room, owner, name, suit, number, "diyba_miaojin") then
        local mark = owner:getTag("diyba_chiheng_type"):toString()
        if mark ~= "" and mark ~= newtype and owner:getMark("diyba_chiheng_pen") > 0 then
            room:setPlayerMark(owner, "diyba_chiheng_pen", 0)
            owner:setTag("diyba_chiheng_type", sgs.QVariant(""))
            room:loseHp(owner, 1)
        end
    end
end)

-- 杨戏 弛衡
diyba_chiheng_rec = sgs.CreateRuleSkillV2 {
    name = "#diyba_chiheng_rec", events = { sgs.Damage, sgs.CardUsed, sgs.RoundStart }, global = true,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.RoundStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(p, "diyba_chiheng_used", 0) end
        elseif event == sgs.Damage then
            local d = data:toDamage()
            if d.from then room:setPlayerMark(d.from, "diyba_dmg-Clear", 1) end
        else
            local use = data:toCardUse()
            if use.from and use.card and use.card:isKindOf("Slash") then
                room:setPlayerMark(use.from, "diyba_slash-Clear", 1)
            end
        end
    end,
}
diyba_chiheng = diyba7_trigger("diyba_chiheng", { sgs.EventPhaseEnd }, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Finish and p:getPhase() ~= sgs.Player_NotActive then return end
    if p:getPhase() ~= sgs.Player_Finish then return end
    if owner:getMark("diyba_chiheng_used") > 0 or owner:isDead() or p:isNude() then return end
    if p:getMark("diyba_dmg-Clear") > 0 or p:getMark("diyba_slash-Clear") == 0 then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    room:setPlayerMark(owner, "diyba_chiheng_used", 1)
    local id = room:askForCardChosen(owner, p, "he", self:objectName())
    room:obtainCard(owner, id, false)
    room:showCard(owner, id)
    owner:setTag("diyba_chiheng_type", sgs.QVariant(sgs.Sanguosha:getCard(id):getType()))
    room:setPlayerMark(owner, "diyba_chiheng_pen", 1)
end)
diyba_15j_yangxi:addSkill(diyba_miaojin)
diyba_15j_yangxi:addSkill(diyba_chiheng)
diyba_15j_yangxi:addSkill(diyba_chiheng_rec)

sgs.LoadTranslationTable {
    ["diyba_15j_xumiao"] = "徐邈",
    ["#diyba_15j_xumiao"] = "丹景青山",
    ["designer:diyba_15j_xumiao"] = "舆人",
    ["diyba_huigu"] = "绘骨",
    [":diyba_huigu"] = "每回合限一次，当你处于【酒】状态时，你可以视为使用本回合进入弃牌堆的一张即时牌。",
    ["diyba_qingxian"] = "清贤",
    [":diyba_qingxian"] = "当你不因“清贤”执行下述任一项后，你可以执行其一邻项（首尾项相连）：1、进入【酒】状态；2、使用一张牌；3、脱离【酒】状态；4、摸一张牌。",
    ["diyba_qx1"] = "进入【酒】状态", ["diyba_qx2"] = "使用一张牌",
    ["diyba_qx3"] = "脱离【酒】状态", ["diyba_qx4"] = "摸一张牌",
    ["@diyba_qingxian_use"] = "清贤：你可以使用一张牌",
    ["@diyba7_target"] = "请选择使用目标",
    ["diyba_15j_yangxi"] = "杨戏",
    ["#diyba_15j_yangxi"] = "翊赞季兴",
    ["designer:diyba_15j_yangxi"] = "樵苏",
    ["diyba_miaojin"] = "妙锦",
    [":diyba_miaojin"] = "你每使用两张实体即时牌后，你可将其中一张牌的点数与另一张牌的花色组合，视为使用一张存在此花色点数组合的即时牌。",
    ["diyba_mj_first"] = "取第一张的花色与第二张的点数",
    ["diyba_mj_second"] = "取第二张的花色与第一张的点数",
    ["diyba_chiheng"] = "弛衡",
    [":diyba_chiheng"] = "每轮限一次，一名其他角色的回合结束时，若其本回合未造成过伤害且使用过【杀】，你可获得其一张牌并展示之；若如此做，你下次发动“妙锦”使用与此牌类别不同的牌时，失去1点体力。",
}
end

