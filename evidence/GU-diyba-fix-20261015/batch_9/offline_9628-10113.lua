-- ===== diyba b12 =====
do
-- diyba batch b12 (3D17J 李恢, 蒋钦, 何姬, 魏讽)
local function b12_trigger(name, events, effect, compulsory)
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
local function b12_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end
local function b12_active(name, nmin, nmax, tfilter, tfeasible, effect, select_card, activate)
    local card = sgs.CreateSkillCard {
        name = name .. "Card", will_throw = false,
        filter = tfilter, feasible = tfeasible,
        on_use = effect,
    }
    return sgs.CreateViewAsSkillV2 {
        name = name,
        can_activate = function(self, request)
            return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
                and (not activate or activate(request:getInitiator()))
        end,
        can_select_card = function(self, request, c)
            local max = type(nmax) == "function" and nmax(request:getInitiator()) or nmax
            return request:getSelectedCardIds():length() < max
                and (not select_card or select_card(request, c))
        end,
        card_selection_feasible = function(self, request)
            local n = request:getSelectedCardIds():length()
            local max = type(nmax) == "function" and nmax(request:getInitiator()) or nmax
            return n >= nmin and n <= max
        end,
        create_card = function(self, request)
            local c = card:clone()
            c:addSubcards(request:getSelectedCardIds())
            c:setSkillName(name)
            return c
        end,
    }
end
local function b12_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    c:addSubcards(ids)
    return c
end
local function b12_hand_only(request, c)
    return not c:isEquipped()
end

diyba_17j_lihui = sgs.General(extension, "diyba_17j_lihui", "shu", 3)
diyba_17j_jiangqin = sgs.General(extension, "diyba_17j_jiangqin", "wu", 4)
diyba_17j_heji = sgs.General(extension, "diyba_17j_heji", "wu", 3)
diyba_17j_weifeng = sgs.General(extension, "diyba_17j_weifeng", "qun", 3)

------------------------------------------------------------------ 李恢
-- 推己: extra give/discard cards are not modelled; the card is used as normal.
diyba_tuiji = b12_trigger("diyba_tuiji", {sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local name = room:askForChoice(owner, self:objectName(), "yj_tuixinzhifu+yj_shushangkaihua", data)
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not c then return end
    c:setSkillName(self:objectName())
    local targets = sgs.SPlayerList()
    if name == "yj_tuixinzhifu" then
        local list = sgs.SPlayerList()
        for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
            if not o:isNude() then list:append(o) end
        end
        if list:isEmpty() then c:deleteLater() return end
        targets:append(room:askForPlayerChosen(owner, list, self:objectName(), "@diyba_tuiji", false, true))
    else
        targets:append(owner)
    end
    room:useCard(sgs.CardUseStruct(c, owner, targets), false)
    c:deleteLater()
    if owner:isAlive() and owner:getHandcardNum() <= owner:getMaxHp() and owner:isWounded() then
        room:recover(owner, sgs.RecoverStruct(owner, nil, 1))
    end
end)

diyba_fuding = b12_active("diyba_fuding", 0, 0,
    function(self, targets, to, from) return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        local name = "diyba_fuding"
        room:setPlayerMark(source, name .. "-Clear", 1)
        local n = source:getHandcardNum()
        if n > 1 then
            room:askForDiscard(source, name, n - 1, n - 1, false, false)
        elseif n < 1 then
            source:drawCards(1 - n, name)
        end
        -- 杀 is used on a chosen target; 闪 cannot be used actively, so it is approximated by 杀.
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(name)
        local list = sgs.SPlayerList()
        for _, o in sgs.qlist(room:getOtherPlayers(source)) do
            if source:canSlash(o, slash, false) then list:append(o) end
        end
        if not list:isEmpty() then
            local t = sgs.SPlayerList()
            t:append(room:askForPlayerChosen(source, list, name, "@diyba_fuding_slash", false, true))
            room:useCard(sgs.CardUseStruct(slash, source, t), false)
        end
        slash:deleteLater()
        if source:isDead() then return end
        local cand = sgs.SPlayerList()
        for _, o in sgs.qlist(room:getOtherPlayers(source)) do
            if o:getHandcardNum() > source:getHandcardNum() then cand:append(o) end
        end
        if cand:isEmpty() then return end
        local to = room:askForPlayerChosen(source, cand, name, "@diyba_fuding", false, true)
        local ids = source:handCards()
        if ids:isEmpty() then return end
        local all = true
        for _, id in sgs.qlist(ids) do
            local c = sgs.Sanguosha:getCard(id)
            if not (c:isKindOf("Slash") or c:isKindOf("Jink")) then all = false end
        end
        local d = b12_dummy(ids)
        room:showCard(source, ids)
        room:obtainCard(to, d, name, false)
        d:deleteLater()
        if all and source:isAlive() and source:askForSkillInvoke("diyba_fuding_get", sgs.QVariant()) then
            local others = sgs.SPlayerList()
            for _, o in sgs.qlist(room:getOtherPlayers(source)) do
                if o ~= to and not o:isNude() then others:append(o) end
            end
            if others:isEmpty() then return end
            local chosen = room:askForPlayersChosen(source, others, name, 0, 2, "@diyba_fuding_get", true, true)
            for _, o in sgs.qlist(chosen) do
                if o:isAlive() and not o:isNude() then
                    local id = room:askForCardChosen(source, o, "he", name)
                    room:obtainCard(source, sgs.Sanguosha:getCard(id), false)
                end
            end
        end
    end, nil, function(p) return p:getMark("diyba_fuding-Clear") == 0 end)

diyba_17j_lihui:addSkill(diyba_tuiji)
diyba_17j_lihui:addSkill(diyba_fuding)

------------------------------------------------------------------ 蒋钦
local function b12_q(p)
    local s = p:getTag("diyba_xushi_q"):toString()
    local r = {}
    if s ~= "" then for _, v in ipairs(s:split("+")) do table.insert(r, tonumber(v)) end end
    return r
end
local function b12_setq(p, r)
    local t = {}
    for _, v in ipairs(r) do table.insert(t, tostring(v)) end
    p:setTag("diyba_xushi_q", sgs.QVariant(table.concat(t, "+")))
end
diyba_xushi = b12_active("diyba_xushi", 1, function(p) return p:getAliveSiblings():length() + 1 end,
    function(self, targets, to, from) return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        room:setPlayerMark(source, "diyba_xushi-Clear", 1)
        local ids = self:getSubcards()
        local n = ids:length()
        local d = b12_dummy(ids)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "diyba_xushi", "")
        room:moveCardTo(d, source, nil, sgs.Player_DiscardPile, reason)
        d:deleteLater()
        source:drawCards(n, "diyba_xushi")
        local q = b12_q(source)
        table.insert(q, n)
        b12_setq(source, q)
    end, b12_hand_only, function(p) return p:getMark("diyba_xushi-Clear") == 0 end)
diyba_xushi_lost = b12_record("#diyba_xushi_lost", {sgs.CardsMoveOneTime}, function(self, event, room, p, data)
    local move = data:toMoveOneTime()
    if move.from and move.from_places:contains(sgs.Player_PlaceHand) or (move.from and move.from_places:contains(sgs.Player_PlaceEquip)) then
        room:addPlayerMark(move.from, "diyba_xushi_lost-Clear")
    end
end)
diyba_xushi_slash = b12_trigger("#diyba_xushi_slash", {sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    local change = data:toPhaseChange()
    if change.to ~= sgs.Player_NotActive then return end
    local q, rest, fire = b12_q(owner), {}, 0
    for _, v in ipairs(q) do
        if v <= 1 then fire = fire + 1 else table.insert(rest, v - 1) end
    end
    b12_setq(owner, rest)
    for _ = 1, fire do
        if owner:isDead() then return end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("diyba_xushi")
        local base = sgs.SPlayerList()
        for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:canSlash(o, slash, false) then base:append(o) end
        end
        if not base:isEmpty() then
            local t = sgs.SPlayerList()
            t:append(room:askForPlayerChosen(owner, base, "diyba_xushi", "@diyba_xushi", false, true))
            for _, o in sgs.qlist(room:getAlivePlayers()) do
                if o ~= owner and o:getMark("diyba_xushi_lost-Clear") > 0 and not t:contains(o) then
                    if owner:canSlash(o, slash, false) and owner:askForSkillInvoke("diyba_xushi_extra", ToData(o)) then t:append(o) end
                end
            end
            room:useCard(sgs.CardUseStruct(slash, owner, t), false)
        end
        slash:deleteLater()
    end
end)

diyba_shangyi_record = b12_record("#diyba_shangyi_record", {sgs.Damage}, function(self, event, room, p, data)
    local damage = data:toDamage()
    if damage.from then room:setTag("diyba_shangyi_last", sgs.QVariant(damage.from:objectName())) end
end)
diyba_shangyi = b12_trigger("diyba_shangyi", {sgs.RoundStart, sgs.DamageCaused, sgs.DamageInflicted}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if event == sgs.RoundStart then
        room:setPlayerMark(owner, name .. "_1", 0)
        room:setPlayerMark(owner, name .. "_2", 0)
        return
    end
    local damage = data:toDamage()
    local lastname = room:getTag("diyba_shangyi_last"):toString()
    if lastname == "" then return end
    local last = room:findPlayerByObjectName(lastname)
    if not last or last:isDead() then return end
    if event == sgs.DamageCaused then
        if damage.from ~= owner or owner:getMark(name .. "_1") > 0 then return end
        if owner:askForSkillInvoke(name, data) then
            room:setPlayerMark(owner, name .. "_1", 1)
            last:drawCards(2, name)
        end
    else
        if damage.to ~= owner or owner:getMark(name .. "_2") > 0 then return end
        if last:askForSkillInvoke(name, ToData(owner)) then
            room:setPlayerMark(owner, name .. "_2", 1)
            owner:drawCards(2, name)
        end
    end
end)

diyba_17j_jiangqin:addSkill(diyba_xushi)
diyba_17j_jiangqin:addSkill(diyba_xushi_lost)
diyba_17j_jiangqin:addSkill(diyba_xushi_slash)
diyba_17j_jiangqin:addSkill(diyba_shangyi_record)
diyba_17j_jiangqin:addSkill(diyba_shangyi)

------------------------------------------------------------------ 何姬
-- 恤遗: offered when a hand-less character enters dying or starts its play phase.
diyba_xuyi = b12_trigger("diyba_xuyi", {sgs.EnterDying, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    local who = p
    if event == sgs.EnterDying then who = data:toDying().who end
    if not who or who:isDead() or not who:isKongcheng() then return end
    if event == sgs.EventPhaseStart and who:getPhase() ~= sgs.Player_Play then return end
    if who:getMark("diyba_xuyi_ban") > 0 then return end
    if not who:askForSkillInvoke(name, ToData(owner)) then return end
    if who ~= owner and not owner:askForSkillInvoke("diyba_xuyi_accept", ToData(who)) then return end
    local dying = who:getHp() <= 0
    who:drawCards(1, name)
    if dying or who == owner then
        if who ~= owner then owner:drawCards(1, name) end
    end
    local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
    peach:setSkillName(name)
    if who:isAlive() and who:isWounded() or dying then
        local t = sgs.SPlayerList()
        t:append(who)
        room:useCard(sgs.CardUseStruct(peach, who, t), false)
    end
    peach:deleteLater()
    if not dying then
        room:setPlayerMark(who, "diyba_xuyi_ban", 1)
        if who ~= owner and owner:isAlive() then
            local n = owner:getMaxHp() - owner:getHandcardNum()
            if n > 0 then owner:drawCards(n, name) end
        end
    end
end)

diyba_xuyi2 = sgs.CreateViewAsSkillV2 {
    name = "diyba_xuyi2",
    can_activate = function(self, request)
        local p = request:getInitiator()
        if not p or request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
        local n = p:getHandcardNum()
        if n == 0 then return false end
        local used = p:getTag("diyba_xuyi2_used"):toString()
        for _, v in ipairs(used == "" and {} or used:split("+")) do
            if tonumber(v) == n then return false end
        end
        return true
    end,
    can_select_card = function(self, request, c) return not c:isEquipped() end,
    card_selection_feasible = function(self, request)
        local p = request:getInitiator()
        return request:getSelectedCardIds():length() == p:getHandcardNum()
    end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds())
        c:setSkillName("diyba_xuyi2")
        return c
    end,
}
diyba_xuyi2.response_pattern = "nullification"
diyba_xuyi2_use = b12_trigger("#diyba_xuyi2_use", {sgs.CardUsed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:getSkillName() ~= "diyba_xuyi2" then return end
    local n = use.card:subcardsLength()
    local used = owner:getTag("diyba_xuyi2_used"):toString()
    owner:setTag("diyba_xuyi2_used", sgs.QVariant(used == "" and tostring(n) or (used .. "+" .. n)))
    room:addPlayerMark(owner, "diyba_xuyi2_max")
    local list = sgs.SPlayerList()
    for _, o in sgs.qlist(room:getAlivePlayers()) do
        if o:getMaxCards() >= owner:getMaxCards() then list:append(o) end
    end
    if list:isEmpty() then return end
    if not owner:askForSkillInvoke("diyba_xuyi2_draw", data) then return end
    local to = room:askForPlayerChosen(owner, list, "diyba_xuyi2", "@diyba_xuyi2", true, true)
    if to then to:drawCards(2, "diyba_xuyi2") end
end)
diyba_xuyi2_max = sgs.CreateMaxCardsSkillV2 {
    name = "#diyba_xuyi2_max",
    correct_func = function(skill, ctx)
        local holder = ctx:getHolder()
        if holder and holder:hasSkill("diyba_xuyi2") then
            return holder:getMark("diyba_xuyi2_max")
        end
        return 0
    end,
}

diyba_17j_heji:addSkill(diyba_xuyi)
diyba_17j_heji:addSkill(diyba_xuyi2)
diyba_17j_heji:addSkill(diyba_xuyi2_use)
diyba_17j_heji:addSkill(diyba_xuyi2_max)

------------------------------------------------------------------ 魏讽
diyba_yingtan = b12_trigger("diyba_yingtan", {sgs.RoundStart, sgs.EventPhaseEnd, sgs.CardUsed}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if event == sgs.RoundStart then
        room:setPlayerMark(owner, name .. "_on", 0)
        room:setPlayerMark(owner, name .. "_got", 0)
        if owner:askForSkillInvoke(name, data) then room:setPlayerMark(owner, name .. "_on", 1) end
    elseif event == sgs.EventPhaseEnd then
        if p:getPhase() ~= sgs.Player_Discard or owner:getMark(name .. "_on") == 0 then return end
        local pile = room:getDiscardPile()
        local found
        for _, id in sgs.qlist(pile) do
            if sgs.Sanguosha:getCard(id):isKindOf("Slash") then found = id break end
        end
        if found and p:isAlive() and p:askForSkillInvoke(name .. "_get", sgs.QVariant()) then
            room:obtainCard(p, sgs.Sanguosha:getCard(found), true)
            room:setPlayerMark(owner, name .. "_got", 1)
        end
    else
        local use = data:toCardUse()
        if use.from ~= owner or owner:getMark(name .. "_got") == 0 or not use.card then return end
        if use.card:isKindOf("SkillCard") or use.card:isKindOf("DelayedTrick") or use.card:isKindOf("EquipCard") then return end
        if use.to:length() ~= 1 then return end
        local to = use.to:first()
        if to:getHandcardNum() < 2 or not owner:askForSkillInvoke(name .. "_show", ToData(to)) then return end
        local ids = to:handCards()
        local pick = {}
        local list = {}
        for _, id in sgs.qlist(ids) do table.insert(list, id) end
        for _ = 1, 2 do
            local i = math.random(#list)
            table.insert(pick, list[i])
            table.remove(list, i)
        end
        local hasSlash = false
        for _, id in ipairs(pick) do
            room:showCard(to, id)
            if sgs.Sanguosha:getCard(id):isKindOf("Slash") then hasSlash = true end
        end
        if not hasSlash then
            use.no_respond_list:append("_ALL_TARGETS")
            data:setValue(use)
        end
    end
end)

diyba_yefan = b12_active("diyba_yefan", 0, 0,
    function(self, targets, to, from)
        return #targets == 0 and to ~= from and to:getHandcardNum() > from:getHandcardNum() and not to:isNude()
    end,
    function(self, targets) return #targets == 1 end,
    function(self, room, source, targets)
        local name = "diyba_yefan"
        local to = targets[1]
        room:setTag("diyba_yefan_death", sgs.QVariant(false))
        room:setPlayerFlag(source, "diyba_yefan_using")
        local target = to
        while target and target:isAlive() and source:isAlive() and not target:isNude() do
            local id = room:askForCardChosen(source, target, "he", name)
            room:obtainCard(source, sgs.Sanguosha:getCard(id), false)
            room:showCard(source, id)
            local used = false
            if source:isAlive() then
                room:askForUseCard(source, "BasicCard,TrickCard|.|.|hand", "@diyba_yefan")
                used = room:getCardOwner(id) ~= source
            end
            if not used then break end
            -- repeat with a target that still has more hand cards than the user
            target = nil
            for _, o in sgs.qlist(room:getOtherPlayers(source)) do
                if o:getHandcardNum() > source:getHandcardNum() and not o:isNude() then
                    target = room:askForPlayerChosen(source, room:getOtherPlayers(source), name, "@diyba_yefan_next", true, true)
                    if target and (target:getHandcardNum() <= source:getHandcardNum() or target:isNude()) then target = nil end
                    break
                end
            end
        end
        room:setPlayerFlag(source, "-diyba_yefan_using")
        if not room:getTag("diyba_yefan_death"):toBool() and source:isAlive() then
            room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
        end
    end, nil, nil)
diyba_yefan_record = b12_record("#diyba_yefan_record", {sgs.Death}, function(self, event, room, p, data)
    room:setTag("diyba_yefan_death", sgs.QVariant(true))
end)
diyba_yefan_mod = sgs.CreateTargetModSkillV2 {
    name = "#diyba_yefan_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from = ctx.getFrom and ctx:getFrom() or nil
        if from and from:hasFlag("diyba_yefan_using") then
            if ctx:getModType() == sgs.TargetModSkill_Residue or ctx:getModType() == sgs.TargetModSkill_DistanceLimit then return 999 end
        end
        return 0
    end,
}

diyba_17j_weifeng:addSkill(diyba_yingtan)
diyba_17j_weifeng:addSkill(diyba_yefan)
diyba_17j_weifeng:addSkill(diyba_yefan_record)
diyba_17j_weifeng:addSkill(diyba_yefan_mod)

sgs.LoadTranslationTable {
    ["diyba_17j_lihui"] = "李恢", ["#diyba_17j_lihui"] = "执灯照南", ["designer:diyba_17j_lihui"] = "别玩一起跑",
    ["diyba_tuiji"] = "推己",
    [":diyba_tuiji"] = "出牌阶段结束时，你可以视为使用【推心置腹】/【树上开花】且你可以额外交出/弃置任意张牌；该牌结算后，若你的手牌数不大于体力上限，你回复1点体力。",
    ["diyba_fuding"] = "复定",
    [":diyba_fuding"] = "每回合限一次，你可以将手牌数调整至1以视为使用【杀】或【闪】，然后令一名手牌数多于你的角色获得并展示你的所有手牌；若均为【杀】或【闪】，你可以获得至多两名除其之外的角色各一张牌。",

    ["diyba_17j_jiangqin"] = "蒋钦", ["#diyba_17j_jiangqin"] = "飞流扰霞", ["designer:diyba_17j_jiangqin"] = "yyuan",
    ["diyba_xushi"] = "蓄矢",
    [":diyba_xushi"] = "出牌阶段限一次，你可以重铸至多角色数张手牌，于之后等量个回合结束时视为使用【杀】，且可额外指定任意名于该回合内失去过牌的角色为目标。",
    ["diyba_shangyi"] = "尚义",
    [":diyba_shangyi"] = "每轮每项限一次，当你造成伤害时，你可以先令上一名造成伤害的角色摸两张牌；当你受到伤害时，上一名造成伤害的角色可以先令你摸两张牌。",

    ["diyba_17j_heji"] = "何姬", ["#diyba_17j_heji"] = "亭盖荧宫", ["designer:diyba_17j_heji"] = "柠檬",
    ["diyba_xuyi"] = "恤遗",
    [":diyba_xuyi"] = "没有手牌的角色可以令你选择是否：与其各摸一张牌以令其视为使用【桃】；若其未处于濒死状态，其不能再发动“恤遗”，你改为将手牌摸至上限。",
    ["diyba_xuyi2"] = "序仪",
    [":diyba_xuyi2"] = "每手牌数限一次，你可以将所有手牌当【无懈可击】使用并令手牌上限+1，然后你可以令一名手牌上限不小于你的角色摸两张牌。",

    ["diyba_17j_weifeng"] = "魏讽", ["#diyba_17j_weifeng"] = "委鬼言风", ["designer:diyba_17j_weifeng"] = "别玩一起跑",
    ["diyba_yingtan"] = "荧谈",
    [":diyba_yingtan"] = "轮次开始时，你可以令所有角色：于此轮内弃牌阶段弃牌后，均可获得其中一张【杀】。若如此做，你于此轮内使用目标唯一的即时牌时，可以展示对方至少两张手牌，若其中没有【杀】，该牌不可被抵消。",
    ["diyba_yefan"] = "掖反",
    [":diyba_yefan"] = "出牌阶段，你可以获得并展示一名手牌多于你的角色的一张牌，然后你可以使用一张即时牌（无次数限制）；若你使用了此次获得的牌，你重复此流程。流程结束后，若没有角色于其间死亡，你结束此阶段。",
}
end

