-- ===== diyba b11 =====
do
-- diyba batch b11 (3D17J 001/003; 002 skipped)
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

diyba_17j_jiangxu = sgs.General(extension, "diyba_17j_jiangxu", "wei", 4)
diyba_17j_mazhong = sgs.General(extension, "diyba_17j_mazhong", "shu", 4)

-- 姜叙 峙围
local function diyba_zhiwei_x(p)
    local n = 0
    for _, q in sgs.qlist(p:getRoom():getAlivePlayers()) do
        if q:inMyAttackRange(p) or q:objectName() == p:objectName() then n = n + 1 end
    end
    return math.max(n, 1)
end
local diyba_zhiweiCard = sgs.CreateSkillCard {
    name = "diyba_zhiweiCard", will_throw = false,
    filter = function(self, targets, to, from)
        return #targets < diyba_zhiwei_x(from) and to:objectName() ~= from:objectName() and not to:isKongcheng()
    end,
    feasible = function(self, targets) return #targets >= 1 end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, "diyba_zhiwei-Clear")
        local parts = sgs.SPlayerList()
        parts:append(source)
        for _, t in ipairs(targets) do parts:append(t) end
        source:removeTag("diyba_zhiwei_result")
        pcall(function() room:askForYishi(source, parts, "diyba_zhiwei", 1) end)
        local result = source:getTag("diyba_zhiwei_result"):toString()
        source:removeTag("diyba_zhiwei_result")
        if result ~= "red" and result ~= "black" then return end
        for _, p in sgs.qlist(parts) do
            if p:isAlive() and not p:isKongcheng() then
                if result == "red" then
                    if room:askForDiscard(p, "diyba_zhiwei", 1, 1, true, false, "@diyba_zhiwei-discard") then
                        p:drawCards(1, "diyba_zhiwei")
                    end
                else
                    local used = room:askForUseCard(p, ".|.|.|hand", "@diyba_zhiwei-use")
                    if used then p:drawCards(1, "diyba_zhiwei") end
                end
            end
        end
    end,
}
diyba_zhiwei = sgs.CreateViewAsSkillV2 {
    name = "diyba_zhiwei",
    can_activate = function(self, request)
        local p = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and p:getMark("diyba_zhiwei-Clear") < diyba_zhiwei_x(p)
    end,
    can_select_card = function(self, request, c) return false end,
    card_selection_feasible = function(self, request) return true end,
    create_card = function(self, request)
        local c = diyba_zhiweiCard:clone()
        c:setSkillName("diyba_zhiwei")
        return c
    end,
}
diyba_zhiwei_record = sgs.CreateRuleSkillV2 {
    name = "#diyba_zhiwei_record", events = { sgs.YishiResultConfirmed }, global = true,
    can_trigger = function() return false end,
    on_record = function(self, event, room, player, ctx)
        local yishi = ctx.original_data:toYishi()
        if yishi and yishi.reason == "diyba_zhiwei" and yishi.initiator then
            yishi.initiator:setTag("diyba_zhiwei_result", sgs.QVariant(yishi.result or ""))
        end
    end,
}
-- 姜叙 恪义 (last hand card only as ex_nihilo/peach; duel on self in own play phase)
diyba_keyi = sgs.CreateViewAsSkillV2 {
    name = "diyba_keyi", frequency = sgs.Skill_Compulsory,
    can_activate = function(self, request)
        return request:getInitiator():getHandcardNum() == 1
    end,
    can_select_card = function(self, request, c)
        local p = request:getInitiator()
        return request:getSelectedCardIds():isEmpty() and p:getHandcardNum() == 1 and p:handCards():contains(c:getEffectiveId())
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local name = "peach"
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then name = "ex_nihilo" end
        local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("diyba_keyi")
        return c
    end,
}
diyba_17j_jiangxu:addSkill(diyba_zhiwei)
diyba_17j_jiangxu:addSkill(diyba_zhiwei_record)
diyba_17j_jiangxu:addSkill(diyba_keyi)

-- 马忠 威绥 (连招技: 伤害牌 + 非伤害牌)
local function diyba_is_damage_card(card)
    return card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("SavageAssault")
        or card:isKindOf("ArcheryAttack") or card:isKindOf("FireAttack")
end
local function diyba_nanman_ids(ids)
    local res = {}
    for _, id in sgs.qlist(ids) do
        if sgs.Sanguosha:getCard(id):isKindOf("SavageAssault") then table.insert(res, id) end
    end
    return res
end
diyba_weisui = diyba_trigger("diyba_weisui", { sgs.CardFinished, sgs.EventPhaseStart }, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart then
        p:removeTag("diyba_weisui_prev")
        return
    end
    local use = data:toCardUse()
    if use.from:objectName() ~= p:objectName() or not use.card or use.card:isKindOf("SkillCard") then return end
    local prev = p:getTag("diyba_weisui_prev"):toBool()
    local dmg = diyba_is_damage_card(use.card)
    p:setTag("diyba_weisui_prev", sgs.QVariant(dmg))
    if p:objectName() ~= owner:objectName() or not prev or dmg or owner:isDead() then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    if not owner:isKongcheng() then room:showAllCards(owner) end
    local choice = room:askForChoice(owner, self:objectName(), "diyba_weisui1+diyba_weisui2+diyba_weisui3", data)
    if choice == "diyba_weisui1" then
        local x = #diyba_nanman_ids(owner:handCards())
        for _ = 1, x do
            local fields = sgs.IntList()
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                for _, c in sgs.qlist(q:getCards("ej")) do fields:append(c:getEffectiveId()) end
            end
            if fields:isEmpty() or not owner:askForSkillInvoke("diyba_weisui_move", data) then break end
            local from
            local targets = sgs.SPlayerList()
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                if not q:getCards("ej"):isEmpty() then targets:append(q) end
            end
            from = room:askForPlayerChosen(owner, targets, self:objectName(), "@diyba_weisui-from", true)
            if not from then break end
            local id = room:askForCardChosen(owner, from, "ej", self:objectName())
            local card = sgs.Sanguosha:getCard(id)
            local tos = sgs.SPlayerList()
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                if q:objectName() ~= from:objectName() then
                    if card:isKindOf("EquipCard") then
                        local eq = card:getRealCard():toEquipCard()
                        if q:hasEquipArea(eq:location()) and not q:getEquip(eq:location()) then tos:append(q) end
                    elseif not q:containsTrick(card:objectName()) then
                        tos:append(q)
                    end
                end
            end
            if tos:isEmpty() then break end
            local to = room:askForPlayerChosen(owner, tos, self:objectName(), "@diyba_weisui-to", true)
            if not to then break end
            local place = card:isKindOf("EquipCard") and sgs.Player_PlaceEquip or sgs.Player_PlaceDelayedTrick
            room:moveCardTo(card, from, to, place,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, owner:objectName(), self:objectName(), ""))
        end
    elseif choice == "diyba_weisui2" then
        local list = diyba_nanman_ids(room:getDiscardPile())
        if #list == 0 then return end
        local picked = sgs.IntList()
        for _, id in ipairs(list) do
            if picked:length() < #list and owner:askForSkillInvoke("diyba_weisui_put", data) then
                picked:append(id)
            else
                break
            end
        end
        if picked:isEmpty() then return end
        local ok = pcall(function() room:moveCardsToEndOfDrawpile(owner, picked, self:objectName()) end)
        if not ok then
            for _, id in sgs.qlist(picked) do
                room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), self:objectName(), ""))
            end
        end
        local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@diyba_weisui-recover", true)
        if to then
            room:recover(to, sgs.CardRecoveryStruct(owner, nil, picked:length()))
        end
    else
        local ids = sgs.IntList()
        for _, id in sgs.qlist(room:getDrawPile()) do ids:append(id) end
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            for _, c in sgs.qlist(q:getCards("ej")) do ids:append(c:getEffectiveId()) end
            if q:objectName() ~= owner:objectName() then
                for _, c in sgs.qlist(q:getHandcards()) do ids:append(c:getEffectiveId()) end
            end
        end
        local x = #diyba_nanman_ids(ids)
        if x > 0 then owner:drawCards(x, self:objectName()) end
        if not owner:isNude() then
            local c = room:askForCard(owner, "..!", "@diyba_weisui-top", data, sgs.Card_MethodNone)
            if c then
                room:moveCardTo(c, nil, sgs.Player_DrawPile,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), self:objectName(), ""))
            end
        end
    end
end)
diyba_17j_mazhong:addSkill(diyba_weisui)

sgs.LoadTranslationTable {
    ["diyba_17j_jiangxu"] = "姜叙",
    ["#diyba_17j_jiangxu"] = "辉絮覆云",
    ["designer:diyba_17j_jiangxu"] = "左小白",
    ["diyba_zhiwei"] = "峙围",
    [":diyba_zhiwei"] = "出牌阶段共限X次，你可以令至多X名角色议事，若结果为：红色/黑色，议事角色可以：弃置议事牌/使用任意张议事牌，然后摸一张牌；你参与议事时可以展示至多X张同色手牌（X为攻击范围内包含你的角色数）。",
    ["@diyba_zhiwei-discard"] = "峙围：你可以弃置一张牌，然后摸一张牌",
    ["@diyba_zhiwei-use"] = "峙围：你可以使用一张手牌，然后摸一张牌",
    ["diyba_keyi"] = "恪义",
    [":diyba_keyi"] = "锁定技，你的最后一张手牌仅能当【无中生有】或【桃】对任意角色使用；若目标为你，前句对应牌名于你的出牌阶段内改为【决斗】。",

    ["diyba_17j_mazhong"] = "马忠",
    ["#diyba_17j_mazhong"] = "祠悯庭丧",
    ["designer:diyba_17j_mazhong"] = "海豚湾梦语",
    ["diyba_weisui"] = "威绥",
    [":diyba_weisui"] = "连招技（伤害牌+非伤害牌），你可以展示手牌并选择一项（X为对应区域内【南蛮入侵】张数之和）：1.你的手牌区~依次执行至多X次：移动场上一张牌；2.弃牌堆~将其中至多X张【南蛮入侵】置于牌堆底，令一名角色回复等量体力；3.其他游戏内区域~摸X张牌，然后将一张牌置于牌堆顶。",
    ["diyba_weisui1"] = "手牌区：移动场上的牌",
    ["diyba_weisui2"] = "弃牌堆：南蛮入侵置于牌堆底并回复体力",
    ["diyba_weisui3"] = "其他区域：摸牌并置牌于牌堆顶",
    ["@diyba_weisui-from"] = "威绥：选择移动牌的来源角色",
    ["@diyba_weisui-to"] = "威绥：选择移动牌的目标角色",
    ["@diyba_weisui-recover"] = "威绥：选择回复体力的角色",
    ["@diyba_weisui-top"] = "威绥：将一张牌置于牌堆顶",
}
end

