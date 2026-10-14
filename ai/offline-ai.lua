-- Smart AI for GU 官正 SOURCE.md, 2026-10-13.
local function gu_ai_friend(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "hp")
    for _, p in ipairs(ps) do if self:isFriend(p) then return p end end
end
local function gu_ai_enemy(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "hp")
    for _, p in ipairs(ps) do if self:isEnemy(p) then return p end end
end
local function gu_ai_low(self, hand_only)
    local cards = sgs.QList2Table(self.player:getCards(hand_only and "h" or "he"))
    self:sortByKeepValue(cards); return cards[1]
end
local function gu_ai_cardask(self) local c = gu_ai_low(self); return c and "$" .. c:getEffectiveId() or "." end
sgs.ai_fill_skill.ofgu_qiangxi = function(self)
    if not self.player:isKongcheng() and self.player:getMark("ofgu_qiangxi_disabled-Clear") == 0 then return sgs.Card_Parse("#ofgu_qiangxiCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_qiangxiCard"] = function(card, use, self)
    local max = self:getMaxCard()
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and p:getMark("ofgu_qiangxi_" .. self.player:objectName() .. "-Clear") == 0
            and max and max:getNumber() >= 10 then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.ofgu_qiangxi = function(self, choices, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) and not p:isNude() and "discard" or "draw"
end
sgs.ai_skill_pindian.ofgu_qiangxi = function(minusecard, self, requestor, maxcard, mincard) return maxcard end
sgs.ai_skill_playerschosen.ofgu_qishen = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and p ~= self.player and p:getHp() > 1 and not self:hasSkills(sgs.masochism_skill, p) then table.insert(chosen, p) end
        if #chosen == 3 then break end
    end
    return chosen
end
sgs.ai_skill_invoke.ofgu_cirang = true
sgs.ai_skill_askforyiji.ofgu_cirang = function(self, ids, tos)
    local target = gu_ai_friend(self, tos or self.room:getOtherPlayers(self.player))
    if target and target ~= self.player then return target, ids[1] end
end
sgs.ai_skill_cardask["@ofgu_liaoliao"] = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:getNumber() <= 6 and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_fill_skill.ofgu_duanliang = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isBlack() and not c:isKindOf("TrickCard") and not self.player:isJilei(c) and self:getUseValue(c) < 6 then
            return sgs.Card_Parse("supply_shortage:ofgu_duanliang[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_skill_invoke.ofgu_zier = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p)
end
sgs.ai_skill_choice.ofgu_zier = function(self, choices)
    local cs = choices:split("+")
    if table.contains(cs, "play") then return "play" end
    if table.contains(cs, tostring(sgs.Player_Discard)) then return tostring(sgs.Player_Discard) end
    return cs[1]
end
sgs.ai_skill_invoke.ofgu_lieren = function(self, data)
    local use = data:toCardUse(); local to = use.to:first(); local c = self:getMaxCard()
    return to and self:isEnemy(to) and c and c:getNumber() >= 10
end
sgs.ai_skill_pindian.ofgu_lieren = sgs.ai_skill_pindian.ofgu_qiangxi
sgs.ai_skill_invoke.ofgu_juxiang = function(self, data) return self:isEnemy(data:toDamage().to) end
sgs.ai_skill_use["@ofgu_hengren"] = function(self)
    for _, c in ipairs(self:getCards("Slash")) do
        local use = self:aiUseCard(c)
        if use.card and use.to and not use.to:isEmpty() then
            local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
            return c:toString() .. "->" .. table.concat(names, "+")
        end
    end
    return "."
end
sgs.ai_skill_invoke.ofgu_danjue = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do if self:isFriend(p) then return true end end
    return false
end
sgs.ai_skill_cardask["@ofgu_danjue"] = function(self, data)
    local p = data:toPlayer(); if p and self:isFriend(p) then return gu_ai_cardask(self) end
    return "."
end
sgs.ai_fill_skill.ofgu_yishi = function(self)
    if self.player:getMark("@ofgu_yishi") > 0 and #self.enemies > #self.friends_noself then return sgs.Card_Parse("#ofgu_yishiCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_yishiCard"] = function(card, use) use.card = card end
sgs.ai_skill_playerchosen.ofgu_fangzhu = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:faceUp() or self:isFriend(p) and not p:faceUp() then return p end
    end
end
sgs.ai_skill_cardask["@ofgu_nianjun-self"] = function(self)
    if #self.friends_noself == 0 then return "." end
    local c = gu_ai_low(self, true); return c and "$" .. c:getEffectiveId() or "."
end
sgs.ai_skill_playerschosen.ofgu_nianjun = function(self, targets)
    local chosen = {}; for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(chosen, p) end end
    return chosen
end
sgs.ai_skill_playerchosen.ofgu_meihun = gu_ai_enemy
sgs.ai_skill_choice.ofgu_meihun = function(self, choices, data)
    local p = data:toPlayer(); local counts = {spade=0, heart=0, club=0, diamond=0}
    if p then for _, c in sgs.qlist(p:getCards("he")) do
        if c:isEquipped() or c:hasFlag("visible") or c:hasFlag("visible_" .. self.player:objectName() .. "_" .. p:objectName()) then
            if counts[c:getSuitString()] then counts[c:getSuitString()] = counts[c:getSuitString()] + 1 end
        end
    end end
    local choice, n = "heart", -1
    for _, suit in ipairs({"heart", "diamond", "spade", "club"}) do if counts[suit] > n then choice, n = suit, counts[suit] end end
    return choice
end
sgs.ai_skill_cardask["@ofgu_meihun-give"] = function(self, data, pattern)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if sgs.Sanguosha:matchExpPattern(pattern, self.player, c) then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_fill_skill.ofgu_huoxin = function(self)
    if #self.enemies < 2 then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for i, a in ipairs(cards) do for j = i+1, #cards do
        local b = cards[j]
        if a:getSuit() == b:getSuit() and self:getKeepValue(a) + self:getKeepValue(b) < 11 then
            return sgs.Card_Parse("#ofgu_huoxinCard:" .. a:getEffectiveId() .. "+" .. b:getEffectiveId() .. ":")
        end
    end end
end
sgs.ai_skill_use_func["#ofgu_huoxinCard"] = function(card, use, self)
    if #self.enemies >= 2 then use.card = card; use.to:append(self.enemies[1]); use.to:append(self.enemies[2]) end
end
sgs.ai_skill_invoke.ofgu_jiang = true
sgs.ai_skill_playerchosen.ofgu_zhiba = gu_ai_enemy
sgs.ai_skill_pindian.ofgu_zhiba = sgs.ai_skill_pindian.ofgu_qiangxi
sgs.ai_skill_choice.ofgu_duanchang = function(self, choices, data)
    local p = data:toPlayer(); return p and p:getCardCount(true) >= 5 and "cards" or "skills"
end
sgs.ai_skill_cardask["@ofgu_beige"] = function(self, data)
    local d = data:toDamage()
    if self:isFriend(d.to) or d.from and self:isEnemy(d.from) then return gu_ai_cardask(self) end
    return "."
end
sgs.ai_skill_use["@@ofgu_quzhong"] = function(self)
    for _, id in sgs.qlist(self.player:getTag("ofgu_quzhong_availableForAI"):toIntList()) do
        local c = sgs.Card_Parse("slash:ofgu_quzhong[to_be_decided:0]=" .. id)
        local use = self:aiUseCard(c)
        if use.card and use.to and not use.to:isEmpty() then
            local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
            return c:toString() .. "->" .. table.concat(names, "+")
        end
    end
    return "."
end
sgs.ai_skill_choice.ofgu_yuanlin = function(self, choices) return self.player:isWounded() and "recover" or "draw" end
sgs.ai_skill_invoke.ofgu_qiongshan = function(self, data)
    local j = data:toJudge(); return self:isFriend(j.who) and j:isBad() or self:isEnemy(j.who) and j:isGood()
end
sgs.ai_skill_suit.ofgu_qiongshan = function(self)
    local j = self.room:getTag("ofgu_qiongshan_judge"):toJudge()
    return j and self:isEnemy(j.who) and sgs.Card_Spade or sgs.Card_Heart
end
sgs.ai_skill_choice.ofgu_qiongshan = function(self, choices) return "5" end
sgs.ai_skill_invoke.ofgu_saxue = function(self) return self.player:getHp() > 2 and #self.enemies >= 2 end
sgs.ai_skill_playerschosen.ofgu_saxue = function(self, targets)
    local chosen = {}; for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(chosen, p); if #chosen == 2 then return chosen end end end
    return chosen
end
sgs.ai_skill_playerchosen.ofgu_saxue = gu_ai_enemy
sgs.ai_skill_choice.ofgu_saxue = function(self, choices, data)
    local p = data:toPlayer(); return p and self:isFriend(p) and "0" or "2"
end
sgs.ai_skill_invoke.ofgu_xianfeng = function(self, data) return self:isEnemy(data:toDamage().from) end
sgs.ai_skill_choice.ofgu_benghuai = function(self) return self.player:getMaxHp() > 3 and "maxhp" or "hp" end
sgs.ai_skill_playerchosen.ofgu_diyu = gu_ai_friend
sgs.ai_skill_choice.ofgu_diyu = function(self, choices)
    for _, name in ipairs({"ofgu_yiju", "ofgu_bihun", "ofgu_benghuai", "ofgu_tongji"}) do if choices:contains(name) then return name end end
end
sgs.ai_skill_playerchosen.ofgu_fuyi = gu_ai_enemy
sgs.ai_skill_invoke.ofgu_jiuji = function(self) return #self.enemies > 0 and #self.friends > 0 end
sgs.ai_skill_playerschosen.ofgu_jiuji = function(self, targets)
    local a, b = gu_ai_friend(self, targets), gu_ai_enemy(self, targets)
    return a and b and {a,b} or {}
end
sgs.ai_skill_invoke.ofgu_jingshi = true
sgs.ai_skill_askforag.ofgu_zhuhun = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByKeepValue(cards); return cards[1]:getEffectiveId()
end
sgs.ai_skill_askforag.ofgu_jingshi = function(self, ids) return ids[1] end
sgs.ai_skill_discard.ofgu_jingshi = function(self)
    if #self.friends_noself == 0 then return {} end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if #cards >= 2 then return {cards[1]:getEffectiveId(), cards[2]:getEffectiveId()} end
    return {}
end
for _, name in ipairs({"ofgu_qiangxi", "ofgu_huoxin", "ofgu_yishi"}) do
    sgs.ai_use_value[name .. "Card"] = 5.5; sgs.ai_use_priority[name .. "Card"] = 4.2
end

-- 謀攻篇線下.
sgs.ai_skill_invoke.ofgu_yicong = true
sgs.ai_skill_choice.ofgu_yicong = function(self) return self:isWeak() and "to" or "from" end
sgs.ai_skill_invoke.ofgu_qiaomeng = true
sgs.ai_skill_choice.ofgu_qiaomeng = function(self, choices, data)
    if choices:contains("draw") then
        local d = data:toDamage()
        return d.to and self:isEnemy(d.to) and not d.to:isAllNude() and "draw" or "hu"
    end
    return self:getCardsNum("Jink") == 0 and "jink" or "slash"
end
sgs.ai_fill_skill.ofgu_quhu = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if not self.player:isJilei(c) and self:getKeepValue(c) < 5 then return sgs.Card_Parse("#ofgu_quhuCard:" .. c:getEffectiveId() .. ":") end end
end
sgs.ai_skill_use_func["#ofgu_quhuCard"] = function(card, use, self)
    local targets = {}
    for _, p in ipairs(self.enemies) do if not p:isNude() then table.insert(targets, p) end end
    if #targets >= 2 then use.card = card; use.to:append(targets[1]); use.to:append(targets[2]) end
end
sgs.ai_skill_discard.ofgu_quhu = function(self, max, min)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}; for _, c in ipairs(cards) do
        if not self.player:isJilei(c) then table.insert(ids, c:getEffectiveId()); if #ids >= math.max(1,min) then break end end
    end
    return ids
end
sgs.ai_skill_playerchosen.ofgu_jieming = gu_ai_friend
sgs.ai_skill_discard.ofgu_jieming = function(self, max, min)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}; for _, c in ipairs(cards) do
        if not self.player:isJilei(c) then table.insert(ids, c:getEffectiveId()); if #ids >= min then return ids end end
    end
    return {}
end
sgs.ai_fill_skill.ofgu_leiji = function(self)
    if self.player:getMark("@ofgu_daobing") >= 2 then return sgs.Card_Parse("#ofgu_leijiCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_leijiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if self:damageIsEffective(p, "T", self.player) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_invoke.ofgu_guidao = function(self, data)
    local d = data:toDamage()
    return not self:needToLoseHp(self.player, d.from, d.card) and (d.damage > 1 or self:isWeak())
end
sgs.ai_fill_skill.ofgu_ganglie = function(self) return sgs.Card_Parse("#ofgu_ganglieCard:.:") end
sgs.ai_skill_use_func["#ofgu_ganglieCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if p:getMark("ofgu_ganglie_hurt_" .. self.player:objectName()) > 0 and p:getMark("ofgu_ganglie_used_" .. self.player:objectName()) == 0
            and self:damageIsEffective(p, "N", self.player) then use.card = card; use.to:append(p) end
    end
end
sgs.ai_skill_askforag.ofgu_qingjian = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByKeepValue(cards, true); return cards[1]:getEffectiveId()
end
sgs.ai_skill_playerchosen.ofgu_qingjian = gu_ai_friend
sgs.ai_skill_discard.ofgu_qianxun = function(self, max, min, optional, equiped)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards, true)
    local ids = {}; for _, c in ipairs(cards) do
        if not c:isEquipped() then table.insert(ids, c:getEffectiveId()); if #ids == max then break end end
    end
    return ids
end
sgs.ai_skill_choice.ofgu_qianxun = function(self, choices)
    for _, name in ipairs(choices:split("+")) do
        if name ~= "cancel" then
            local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
            if c then
                local use = c:isNDTrick() and self:aiUseCard(c) or nil
                c:deleteLater()
                if use and use.card then return name end
            end
        end
    end
    return "cancel"
end
sgs.ai_skill_use["@@ofgu_qianxun"] = function(self)
    local name = self.player:getTag("ofgu_qianxun_use"):toString()
    local c = sgs.Card_Parse(name .. ":ofgu_qianxun[no_suit:0]=.")
    if not c then return "." end
    local use = self:aiUseCard(c)
    if not use.card then return "." end
    local names = {}; if use.to then for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end end
    return c:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
end
sgs.ai_skill_invoke.ofgu_lianying = true
sgs.ai_skill_playerchosen.ofgu_lianying = gu_ai_friend
sgs.ai_skill_askforag.ofgu_lianying = function(self, ids) return ids[1] end
sgs.ai_skill_cardask["@ofgu_gongqi"] = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if self:getKeepValue(c) < 5 and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_fill_skill.ofgu_jiefan = function(self)
    if self.player:getMark("ofgu_jiefan_disabled") == 0 then return sgs.Card_Parse("#ofgu_jiefanCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_jiefanCard"] = function(card, use, self)
    self:sort(self.friends, "handcard")
    for _, p in ipairs(self.friends) do
        local n = 0; for _, q in sgs.qlist(self.room:getOtherPlayers(p)) do if q:inMyAttackRange(p) then n = n+1 end end
        if n > 0 then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.ofgu_jiefan = function(self) return "draw" end
sgs.ai_skill_invoke.ofgu_jiefan_backwater = false
sgs.ai_fill_skill.ofgu_xianzhen = function(self) return sgs.Card_Parse("#ofgu_xianzhenCard:.:") end
sgs.ai_skill_use_func["#ofgu_xianzhenCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do if p:getHp() < self.player:getHp() and self:getCardsNum("Slash") > 0 then use.card = card; use.to:append(p); return end end
end
sgs.ai_skill_invoke.ofgu_xianzhen = function(self, data)
    local p = data:toPlayer(); local c = self:getMaxCard()
    return p and self:isEnemy(p) and c and c:getNumber() >= 10
end
sgs.ai_skill_pindian.ofgu_xianzhen = sgs.ai_skill_pindian.ofgu_qiangxi
for _, name in ipairs({"ofgu_quhu", "ofgu_leiji", "ofgu_ganglie", "ofgu_jiefan", "ofgu_xianzhen"}) do
    sgs.ai_use_value[name .. "Card"] = 5.5; sgs.ai_use_priority[name .. "Card"] = 4.2
end
sgs.ai_use_priority.ofgu_xianzhenCard = 7

-- SOURCE-C: existing Ying, no native-AI additions.
sgs.ai_fill_skill.ofgu_qianling = function(self)
    if #self.enemies > 0 then return sgs.Card_Parse("#ofgu_qianlingCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_qianlingCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if self.player:getHandcardNum() < p:getHandcardNum() then
            use.card = card; use.to:append(p); return
        end
    end
end
sgs.ai_skill_playerchosen.ofgu_qianling = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:getHandcardNum() > self.player:getHandcardNum() then return p end
    end
    return nil
end
sgs.ai_fill_skill.ofgu_queying = function(self)
    if self.player:getHandcardNum() < self.player:getMaxHp() then return sgs.Card_Parse("#ofgu_queyingCard:.:slash") end
end
sgs.ai_skill_use_func["#ofgu_queyingCard"] = function(card, use, self)
    local slash = sgs.Sanguosha:cloneCard("slash"); slash:setSkillName("ofgu_queying")
    local dummy = {isDummy = true, to = sgs.SPlayerList()}
    self:useBasicCard(slash, dummy)
    if dummy.card and not dummy.to:isEmpty() then
        use.card = card
        for _, p in sgs.qlist(dummy.to) do use.to:append(p) end
    end
    slash:deleteLater()
end
sgs.ai_cardsview_valuable.ofgu_queying = function(self, class_name, player)
    if player:getHandcardNum() >= player:getMaxHp() then return end
    if class_name == "Jink" then return "#ofgu_queyingCard:.:jink" end
    if class_name == "Slash" then return "#ofgu_queyingCard:.:slash" end
end
-- Hidden Luo Guanzhong: support the sourced discard/equip portion only.
sgs.ai_fill_skill.ofgu_ranhan = function(self)
    for _, p in ipairs(self.enemies) do
        if not p:getCards("ej"):isEmpty() then return sgs.Card_Parse("#ofgu_ranhanCard:.:") end
    end
end
sgs.ai_skill_use_func["#ofgu_ranhanCard"] = function(card, use) use.card = card end
sgs.ai_skill_askforag.ofgu_ranhan = function(self, ids, refusable)
    for _, id in ipairs(ids) do
        local p = self.room:getCardOwner(id)
        if p and self:isEnemy(p) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip then return id end
    end
    return refusable and -1 or ids[1]
end
sgs.ai_skill_invoke.ofgu_huhaibi = false

sgs.ai_skill_cardask["@ofgu_kuanglei"] = function(self) return gu_ai_cardask(self) end

sgs.ai_fill_skill.ofgu_lianhuan = function(self)
    if self.player:getMark("ofgu_lianhuan_used-PlayClear") >= self.room:getTag("SwapPile"):toInt() + 1 then return end
    local c = gu_ai_low(self)
    if c then return sgs.Card_Parse("iron_chain:ofgu_lianhuan[to_be_decided:0]=" .. c:getEffectiveId()) end
end
sgs.ai_skill_invoke.ofgu_niepan = true
sgs.ai_skill_playerchosen.ofgu_niepan = function(self, targets) return gu_ai_enemy(self, targets) or targets:first() end

sgs.ai_fill_skill.ofgu_xingshang = function(self)
    if self.player:getMark("&ofgu_song") >= 2 then return sgs.Card_Parse("#ofgu_xingshangCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_xingshangCard"] = function(card, use, self)
    self:sort(self.friends, "hp")
    for _, p in ipairs(self.friends) do
        if not p:faceUp() or p:isWounded() or p:getHandcardNum() < 3 then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.ofgu_xingshang = function(self, choices, data)
    local to = data:toPlayer()
    if choices:find("3") and to and to:isWounded() and to:faceUp() then return "3" end
    return "2"
end
sgs.ai_skill_playerchosen.ofgu_zhuisi = function(self, targets)
    local best, score
    for _, p in sgs.qlist(targets) do
        local n = 0
        for _, general in ipairs({p:getGeneral(), p:getGeneral2()}) do
            for _, skill in sgs.qlist(general:getSkillList()) do if not skill:isLordSkill() then n = n + 1 end end
        end
        if not score or n > score then best, score = p, n end
    end
    return best
end
sgs.ai_fill_skill.ofgu_moufangzhu = function(self)
    if self.player:getMark("&ofgu_song") >= 2 then return sgs.Card_Parse("#ofgu_moufangzhuCard:.:") end
end
sgs.ai_skill_use_func["#ofgu_moufangzhuCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do if p:getHandcardNum() > 1 then use.card = card; use.to:append(p); return end end
end
sgs.ai_skill_choice.ofgu_moufangzhu = function(self, choices)
    if choices:find("invalid") then return "invalid" end
    return "basic"
end

-- Correspondence has no additional gameplay effect; keep the native defaults.
sgs.ai_skill_invoke.ofgu_huamao_reassign = false

-- GU 王者之战 (wangzhan.md).
sgs.ai_skill_invoke.ofwz_guanxing = true
sgs.ai_skill_invoke.ofwz_luoshen = true
sgs.ai_skill_invoke.ofwz_shouye = function(self, data)
    local use = data:toCardUse()
    return use.from ~= self.player and not (self:isFriend(use.from) and (use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo")))
end
sgs.ai_skill_playerschosen.ofwz_liezhi = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if #chosen < 2 and (self:isEnemy(p) and not p:isNude() or self:isFriend(p) and not p:getJudgingArea():isEmpty()) then
            table.insert(chosen, p)
        end
    end
    return chosen
end
sgs.ai_fill_skill.ofwz_qiangxi = function(self)
    if self.player:getMark("ofwz_qiangxi_weapon-PlayClear") == 0 then
        for _, c in sgs.qlist(self.player:getCards("he")) do
            if c:isKindOf("Weapon") and not self.player:isJilei(c) then return sgs.Card_Parse("#ofwz_qiangxiCard:" .. c:getEffectiveId() .. ":") end
        end
    end
    if self.player:getMark("ofwz_qiangxi_hp-PlayClear") == 0 and self.player:getHp() > 2 then return sgs.Card_Parse("#ofwz_qiangxiCard:.:") end
end
sgs.ai_skill_use_func["#ofwz_qiangxiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:getMark("ofwz_qiangxi_" .. self.player:objectName() .. "-PlayClear") == 0
            and self.player:inMyAttackRange(p, card:getSubcards()) and self:damageIsEffective(p) then
            use.card = card; use.to:append(p); return
        end
    end
end
sgs.ai_use_priority.ofwz_qiangxiCard = 2.5
sgs.ai_fill_skill.ofwz_duanliang = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isBlack() and (c:isKindOf("BasicCard") or c:isKindOf("EquipCard")) and not self.player:isJilei(c) and self:getUseValue(c) < 6 then
            return sgs.Card_Parse("supply_shortage:ofwz_duanliang[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_fill_skill.ofwz_zhongyi = function(self)
    if self.player:getHandcardNum() <= self.player:getHp() then return end
    local cards = sgs.QList2Table(self.player:getCards("h")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") then return sgs.Card_Parse("#ofwz_zhongyiCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#ofwz_zhongyiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.ofwz_zhongyiCard = 0.5
sgs.ai_skill_invoke.ofwz_zhongyi = function(self, data) return self:isEnemy(data:toDamage().to) end
sgs.ai_skill_playerchosen.ofwz_choujin = function(self, targets) return gu_ai_enemy(self, targets) or targets:first() end
sgs.ai_skill_playerchosen.ofwz_choujin21 = sgs.ai_skill_playerchosen.ofwz_choujin
-- 忠谏 has no use limit; the AI stops after two gifts so its turn ends.
local function wz_ai_ally(a, b)
    local mode = a:getGameMode()
    return (mode:startsWith("06_") or mode:startsWith("04_") or mode == "08_defense") and a:getRole():sub(1, 1) == b:getRole():sub(1, 1)
end
sgs.ai_fill_skill.ofwz_zhongjian = function(self)
    if #self.friends_noself == 0 or self.player:isNude() or self.player:usedTimes("#ofwz_zhongjianCard") >= 2 then return end
    local c = gu_ai_low(self)
    if c then return sgs.Card_Parse("#ofwz_zhongjianCard:" .. c:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#ofwz_zhongjianCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if wz_ai_ally(self.player, p) and not p:hasSkill("manjuan") then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.ofwz_zhongjianCard = 1
sgs.ai_skill_choice.ofwz_zhanshen21 = function(self, choices)
    for _, c in ipairs({"damage", "target", "draw"}) do if choices:find(c) then return c end end
end

-- ===== diyba b01 =====
do
-- diyba b01: default AI behaviour is sufficient; invoke hooks below.
sgs.ai_skill_invoke.diyba_lianer = true
sgs.ai_skill_invoke.diyba_anzhi = true
sgs.ai_skill_invoke.diyba_fujiang = function(self, data) return true end
end

-- ===== diyba b02 =====
do
-- diyba b02 ai
sgs.ai_skill_use["@@diyba_dangu"] = function(self, prompt)
    return "."
end
sgs.ai_skill_invoke.diyba_dangu = true
end

-- ===== diyba b03 =====
do
-- diyba b03 AI hooks
sgs.ai_skill_invoke.diyba_mingye_give = true
sgs.ai_skill_cardask["@diyba-mingye-discard"] = function(self, data, pattern)
    if self.player:isWounded() then
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if c:getSuit() == sgs.Card_Heart then return c:toString() end
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.diyba_dangshu = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then return p end
    end
    return nil
end
sgs.ai_skill_playerchosen.diyba_xiaheng = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then return p end
    end
    return targets:first()
end
end

-- ===== diyba b04 =====
do
-- diyba b04 AI hooks
sgs.ai_skill_invoke.diyba_langzhi = true
sgs.ai_skill_invoke.diyba_bailei = function(self, data)
    return true
end
sgs.ai_skill_choice.diyba_langzhi = "obtain"
sgs.ai_skill_choice.diyba_bailei = function(self, choices, data)
    if string.find(choices, "kill") then
        for _, p in ipairs(self.enemies or {}) do
            if p:getHp() == 1 then return "kill" end
        end
    end
    if string.find(choices, "damage") then return "damage" end
    return "kill"
end
end

-- ===== diyba b05 =====
do
-- diyba b05 ai
sgs.ai_skill_invoke.diyba_yeshen = function(self, data)
    local cur = self.room:getCurrent()
    return cur and self:isFriend(cur) or false
end
sgs.ai_skill_playerchosen.diyba_jungui = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then return p end
    end
    return nil
end
sgs.ai_skill_invoke.diyba_jungui = true
end

-- ===== diyba b06 =====
do
-- diyba b06
sgs.ai_skill_invoke.diyba_wanwan = true
sgs.ai_skill_invoke.diyba_ranran = true
sgs.ai_skill_invoke.diyba_linlin = function(self, data) return false end
sgs.ai_skill_invoke.diyba_chutu = function(self, data) return false end
sgs.ai_skill_invoke.diyba_tanlan = true
sgs.ai_skill_choice.diyba_chutu = "diyba_chutu_use"
end

-- ===== diyba b07 =====
do
-- diyba b07: default AI behaviour is sufficient; invoke hooks below.
sgs.ai_skill_invoke.diyba_qingxian = true
sgs.ai_skill_invoke.diyba_miaojin = true
sgs.ai_skill_invoke.diyba_chiheng = function(self, data) return true end
end

-- ===== diyba b08 =====
do
-- b08 AI hooks for diyba_raolue
sgs.ai_skill_choice.diyba_raolue = function(self, choices, data)
    local source = data:toPlayer()
    if source and self:isFriend(source) and self.player:getHandcardNum() < source:getHandcardNum() then return "swap" end
    if source and not self:isFriend(source) and self.player:getHandcardNum() > source:getHandcardNum() then return "noswap" end
    return "noswap"
end
sgs.ai_skill_invoke.diyba_raolue_draw = true
sgs.ai_skill_invoke.diyba_raolue = function(self, data)
    local to = data:toPlayer()
    return to and self:isEnemy(to) and self.player:getHp() > 1
end
end

-- ===== diyba b09 =====
do
-- diyba b09: default AI is sufficient for locked skills; invoke hooks below.
sgs.ai_skill_invoke.diyba_minglie = true
sgs.ai_skill_invoke.diyba_guoyi = true
sgs.ai_skill_choice.diyba_guoyi = "diyba_guoyi_give"
end

-- ===== diyba b10 =====
do
-- b10 AI hooks
sgs.ai_skill_choice.diyba_gengshou = function(self, choices, data)
    local owner = data:toPlayer()
    if not owner then return "cancel" end
    if self:isFriend(owner) then return "draw" end
    if self:isEnemy(owner) and not owner:isNude() then return "discard" end
    return "cancel"
end
sgs.ai_skill_invoke.diyba_gengshou_slash = true
sgs.ai_skill_playerchosen.diyba_gengshou = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return nil
end
sgs.ai_skill_playerchosen.diyba_panyue = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
end

-- ===== diyba b11 =====
do
-- diyba b11: default AI behaviour is sufficient; invoke hooks below.
sgs.ai_skill_invoke.diyba_weisui = true
sgs.ai_skill_invoke.diyba_weisui_move = false
sgs.ai_skill_invoke.diyba_weisui_put = true
sgs.ai_skill_choice.diyba_weisui = "diyba_weisui3"
end

-- ===== diyba b12 =====
do
-- diyba batch b12 AI hooks (minimal)
sgs.ai_skill_invoke.diyba_tuiji = true
sgs.ai_skill_invoke.diyba_yingtan = true
sgs.ai_skill_invoke.diyba_yingtan_get = true
sgs.ai_skill_invoke.diyba_yingtan_show = true
sgs.ai_skill_invoke.diyba_fuding_get = true
sgs.ai_skill_invoke.diyba_xushi_extra = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi_accept = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi2_draw = true
sgs.ai_skill_invoke.diyba_shangyi = function(self, data)
    local damage = data:toDamage()
    if damage and damage.to then return not self:isEnemy(damage.to) or damage.to == self.player end
    return true
end
sgs.ai_skill_choice.diyba_tuiji = "yj_tuixinzhifu"
end

-- ===== diyba b17 =====
do
-- b17 AI hooks
sgs.ai_skill_invoke["diyba_canggu"] = function(self, data)
    local damage = data:toDamage()
    return damage and damage.from and self:isEnemy(damage.from) or false
end
sgs.ai_skill_invoke["diyba_xuanwen"] = true
sgs.ai_skill_choice["diyba_canggu"] = "diyba_canggu_recover"
end

-- ===== diyba b18 =====
do
-- b18: minimal AI hooks
sgs.ai_skill_invoke.diyba_zhuizhenjia = true
sgs.ai_skill_invoke.diyba_xiushixu = true
end

-- ===== diyba b20 =====
do
-- b20 AI hooks
sgs.ai_skill_invoke.diyba_huahai = function(self, data)
    local card
    local ok, d = pcall(function() return data:toDamage() end)
    if ok and d and d.card then
        return d.from ~= nil and self:isFriend(d.from) and d.to ~= nil and self:isEnemy(d.to)
    end
    local ok2, r = pcall(function() return data:toRecover() end)
    if ok2 and r and r.who then return self:isFriend(r.who) end
    return false
end
sgs.ai_skill_invoke.diyba_ougezhu = function(self, data)
    return self.player:getHp() <= 2
end
end

-- ===== diyba b21 =====
do
-- b21 diyba_12j_qianzhao AI
sgs.ai_skill_invoke.diyba_zhirong = function(self, data) return true end
sgs.ai_skill_choice.diyba_yuanzhen = function(self, choices, data)
    local src = data:toPlayer()
    if src and self:isFriend(src) then return "draw" end
    return self.player:getCardCount(true) > 2 and "discard" or "draw"
end
sgs.ai_skill_playerchosen.diyba_zhirong = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:hasEquip() then return p end
    end
    return targets:first()
end
end
