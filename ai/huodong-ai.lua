-- GU 活动模式 (huodong.md) AI; package huodong.

-- ==================== d01
do
-- Reused optional skill; locked Yawang needs no AI hook.
sgs.ai_skill_invoke.zd_xunzhi = function(self, data)
    return self.player:getHp() > 2 and self.player:getHandcardNum() > self.player:getMaxCards()
end
end

-- ==================== d02
do
sgs.ai_skill_invoke.hd_biancai = true
sgs.ai_skill_askforag.hd_biancai = function(self, ids)
    local best, value = ids[1] or -1, -100
    for _, id in ipairs(ids) do
        local card = sgs.Sanguosha:getCard(id)
        if card and self:getUseValue(card) > value then best, value = id, self:getUseValue(card) end
    end
    return best
end
sgs.ai_fill_skill.hd_cuiren = function(self)
    if not self.player or self.player:hasUsed("#hd_cuirenCard") or #self.enemies == 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") and not self.player:isJilei(card) and self:getKeepValue(card) < 5 then
            return sgs.Card_Parse("#hd_cuirenCard:" .. card:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hd_cuirenCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hd_cuirenCard = 7
sgs.ai_skill_cardask["@hd_shenfeng"] = function(self, data)
    if not self.player or not data then return "." end
    local use = data:toCardUse()
    local enemy = false
    if use.to then for _, p in sgs.qlist(use.to) do if self:isEnemy(p) then enemy = true end end end
    if not enemy then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") and not self.player:isJilei(card) and self:getKeepValue(card) < 5 then
            return "$" .. card:getEffectiveId()
        end
    end
    return "."
end
sgs.ai_skill_choice.hd_shenfeng = function() return "damage" end
end

-- ==================== d03
do
-- Complete supplied generals already exist as ddz_rendengai / ddz_youzhugeliang.
end

-- ==================== d04
do
sgs.ai_fill_skill.hd_shuangbi = function(self)
    return sgs.Card_Parse("#hd_shuangbiCard:.:")
end
sgs.ai_skill_use_func["#hd_shuangbiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hd_shuangbiCard = 8
sgs.ai_skill_choice.hd_shuangbi = function(self, choices)
    if choices:find("hd_shuangbi:jie", 1, true) then return "hd_shuangbi:jie" end
    return choices:split("+")[1]
end
sgs.ai_skill_playerchosen.hd_shuangbi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_discard.hd_shuangbi = function() return {} end
sgs.ai_skill_invoke.hd_baoshi = true
sgs.ai_skill_choice.hd_baoshi = function() return "hd_baoshi:obtain" end
sgs.ai_fill_skill.hd_xinggong = function(self)
    local room = self.room
    if not room then return end
    for _, id in sgs.qlist(room:getTag("hd_xinggong_ids"):toIntList()) do
        if room:getCardPlace(id) == sgs.Player_DiscardPile then return sgs.Card_Parse("#hd_xinggongCard:.:") end
    end
end
sgs.ai_skill_use_func["#hd_xinggongCard"] = function(card, use, self)
    self.hd_xinggong_taken = 0
    use.card = card
end
sgs.ai_use_priority.hd_xinggongCard = 7
sgs.ai_skill_askforag.hd_xinggong = function(self, ids)
    local count = self.hd_xinggong_taken or 0
    if count >= math.max(0, self.player:getHp()) then return -1 end
    local best, value = -1, -100
    for _, id in ipairs(ids) do
        local card = sgs.Sanguosha:getCard(id)
        if card and self:getUseValue(card) > value then best = id; value = self:getUseValue(card) end
    end
    if best >= 0 then self.hd_xinggong_taken = count + 1 end
    return best
end
sgs.ai_fill_skill.hd_haojiu = function(self)
    local name = self.player:getChangeSkillState("hd_haojiu") <= 1 and "analeptic" or "ex_nihilo"
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:getNumber() == 9 and self:getUseValue(c) < (name == "ex_nihilo" and 9 or 5) then
            return sgs.Card_Parse(name .. ":hd_haojiu[" .. c:getSuitString() .. ":9]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_view_as.hd_haojiu = function(card, player, place, class_name)
    if not card or not player or card:getNumber() ~= 9 then return end
    if place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip then return end
    local yang = player:getChangeSkillState("hd_haojiu") <= 1
    if (yang and class_name == "Analeptic") or (not yang and class_name == "ExNihilo") then
        return (yang and "analeptic" or "ex_nihilo") .. ":hd_haojiu[" .. card:getSuitString() .. ":9]=" .. card:getEffectiveId()
    end
end
end

-- ==================== d05
do
sgs.ai_skill_invoke.hd_bingling = function(self, data)
    local target = data:toPlayer()
    return target and self:isEnemy(target) and self.player:getHp() > 1
end
sgs.ai_fill_skill.hd_beijin = function(self)
    if self.player:getHp() <= 1 or self.player:getHandcardNum() > 4 or self.player:hasUsed("#hd_beijinCard") then return end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if self.player:getMark("hd_beijin_id_" .. c:getEffectiveId()) > 0 then return end
    end
    return sgs.Card_Parse("#hd_beijinCard:.:")
end
sgs.ai_skill_use_func["#hd_beijinCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hd_beijinCard = 1
sgs.ai_skill_invoke.hd_tongliao = true
sgs.ai_skill_invoke.hd_wudao = true
end

-- ==================== d06
do
-- d06: no AI hooks; 朱铁雄 / 变装 requires unsupported skin mechanics.
end

-- ==================== d07
do
sgs.ai_fill_skill.hd_kenyu = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    local need = self.player:getLostHp()
    for _, c in ipairs(cards) do
        if #ids < 5 and not self.player:isJilei(c, true) and self.player:canDiscard(self.player, c:getEffectiveId())
            and (#ids < need or (self.player:getPile("hd_yumidui"):length() < 5 and self:getKeepValue(c) < 3)) then
            table.insert(ids, c:getEffectiveId())
        end
    end
    if #ids > 0 then return sgs.Card_Parse("#hd_kenyuCard:" .. table.concat(ids, "+") .. ":") end
end
sgs.ai_skill_use_func["#hd_kenyuCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hd_kenyuCard = 5
sgs.ai_skill_invoke.hd_touwei = function(self, data)
    local p = data:toPlayer()
    return p and self:isFriend(p)
end
sgs.ai_skill_askforag.hd_touwei = function(self, ids) return ids[1] or -1 end
sgs.ai_skill_invoke.hd_zhamao = function(self, data)
    local damage = data:toDamage()
    return damage.from and self:isEnemy(damage.from) and self.player:getPile("hd_yumidui"):length() > 0
end
end

-- ==================== d08
do
sgs.ai_skill_invoke.hd_kuku = function(self, data)
    local name = data:toString()
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:objectName() == name then return self:isEnemy(p) and p:getHandcardNum() > self.player:getHandcardNum() end
    end
    return false
end
sgs.ai_skill_invoke.hd_quanjia = function(self, data)
    local d = data:toDamage()
    return d.from and self:isEnemy(d.from)
end
sgs.ai_skill_askforag.hd_quanjia = function(self, ids) return ids[1] or -1 end
sgs.ai_skill_invoke.hd_xuyuan = true
sgs.ai_skill_choice.hd_xuyuan = function(self, choices)
    local opts = choices:split("+")
    for _, name in ipairs(opts) do
        local slots = {weapon = 0, armor = 1, defensive_horse = 2, offensive_horse = 3, treasure = 4}
        if slots[name] and self.player:hasEquipArea(slots[name]) and not self.player:getEquip(slots[name]) then return name end
    end
    return opts[1]
end
sgs.ai_skill_invoke.hd_xiaomian = function(self, data)
    local use = data:toCardUse()
    if not use.card then return false end
    local n = 0
    for _, c in sgs.qlist(self.player:getEquips()) do if c:getSuit() == use.card:getSuit() then n = n + 1 end end
    return n >= 2
end
sgs.ai_skill_cardchosen.hd_xiaomian = function(self, who, flags)
    local cards = sgs.QList2Table(who:getEquips())
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
end

-- ==================== d09
do
sgs.ai_skill_invoke.hd_zuandai = function(self)
    return self.player:getHandcardNum() == 0
end
sgs.ai_skill_invoke.hd_maimeng = true
sgs.ai_skill_choice.hd_maimeng = function() return "draw" end
sgs.ai_skill_playerchosen.hd_maimeng = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "handcard")
    for _, p in ipairs(players) do if self:isEnemy(p) then return p end end
    return players[1]
end
sgs.ai_skill_exchange.hd_maimeng = function(self, pattern, max_num, min_num)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(max_num, #cards) do ids[#ids + 1] = cards[i]:getEffectiveId() end
    return ids
end
sgs.ai_skill_invoke.hd_weiqu = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from)
end
sgs.ai_skill_choice.hd_weiqu = function(self)
    if self.player:getEquips():isEmpty() then return "equip" end
    if self.player:getMark("hd_weiqu_equip-Clear") > 0 then return "hand" end
    return "equip"
end
end

-- ==================== d10
do
sgs.ai_fill_skill.hd_huibian = function(self)
    if self.player:getMark("hd_huibian_disabled-Clear") == 0 then
        return sgs.Card_Parse("#hd_huibianCard:.:")
    end
end
sgs.ai_skill_use_func["#hd_huibianCard"] = function(card, use, self)
    local candidates = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if not p:isKongcheng() and self:isEnemy(p) then table.insert(candidates, p) end
    end
    if #candidates < 2 then return end
    use.card = card
    if use.to then use.to:append(candidates[1]); use.to:append(candidates[2]) end
end
sgs.ai_skill_choice.hd_huibian = function() return "hd_huibian:same" end
sgs.ai_use_priority.hd_huibianCard = 5
sgs.ai_fill_skill.hd_shentui = function(self) return sgs.Card_Parse("#hd_shentuiCard:.:") end
sgs.ai_skill_use_func["#hd_shentuiCard"] = function(card, use, self)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    for _, p in ipairs(self.enemies or {}) do
        if self.player:distanceTo(p) <= self.player:getAttackRange() + 1
            and not self.room:isProhibited(self.player, p, slash)
            and self:slashIsEffective(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            use.card = card
            if use.to then use.to:append(p) end
            break
        end
    end
    slash:deleteLater()
end
sgs.ai_use_priority.hd_shentuiCard = 6
end

-- ==================== d11
do
sgs.ai_skill_invoke.hd_fanzhuan = function(self, data)
    if not self.player then return false end
    local hp, target = self.player:getHp(), self.player:getLostHp()
    return target > 0 and (target >= hp or (target >= 2 and hp - target >= 3))
end
-- Exchange is mandatory; favor high points to reach the extra-turn threshold.
sgs.ai_skill_discard.hd_haoshi = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    table.sort(cards, function(a, b)
        local av = a:getNumber() - self:getKeepValue(a)
        local bv = b:getNumber() - self:getKeepValue(b)
        return av > bv
    end)
    local ids = {}
    for i = 1, math.min(discard_num, #cards) do ids[#ids + 1] = cards[i]:getEffectiveId() end
    return ids
end
end

-- ==================== d12
do
-- Native JinlanCard; Maozhu is locked and needs no AI decisions.
sgs.ai_fill_skill.jinlan = function(self)
    if not self.player or not self.room or self.player:hasUsed("JinlanCard") then return end
    local maximum = 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        local n = 0
        for _, skill in sgs.qlist(p:getVisibleSkillList()) do
            if not skill:isAttachedLordSkill() then n = n + 1 end
        end
        maximum = math.max(maximum, n)
    end
    if maximum > self.player:getHandcardNum() then
        return sgs.Card_Parse("@JinlanCard=.")
    end
end
sgs.ai_skill_use_func["JinlanCard"] = function(card, use, self)
    if card and self.player and self.player:isAlive() then use.card = card end
end
sgs.ai_use_priority.JinlanCard = 8
end

-- ==================== d13
do
sgs.ai_skill_invoke.hd_dingxi = function(self, data)
    local target = data:toPlayer()
    return target and self:isEnemy(target)
end
sgs.ai_skill_askforag.hd_dingxi = function(self, card_ids)
    local best, value = card_ids[1], -100
    for _, id in ipairs(card_ids) do
        local c = sgs.Sanguosha:getCard(id)
        local v = self:getUseValue(c)
        if v > value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_playerchosen.hd_fengzhu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_playerchosen.hd_yuyu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
-- 能臣 is passive; 戒酒 retains the engine skill name and existing AI hooks.
end

-- ==================== d14
do
sgs.ai_skill_choice.hd_huaquan = function(self, choices, data)
    local use = data:toCardUse()
    if use.card and use.card:isDamageCard() then
        for _, p in sgs.qlist(use.to) do
            if self:isEnemy(p) then return "hd_zhongquan" end
        end
    end
    return "hd_qingquan"
end
sgs.ai_skill_choice.hd_huaquan_guess = function(self, choices, data)
    local use = data:toCardUse()
    return use.card and use.card:isDamageCard() and "hd_zhongquan" or "hd_qingquan"
end
-- 披靡 uses the engine's existing pimi AI; all other effects are compulsory.
end
