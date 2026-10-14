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

-- ===== sheji done =====
do
-- 三国杀设计吧 3S2J（smart-ai）
sgs.ai_skill_playerchosen.sj2_shiershilian = function(self, targets)
    if self.player:getMark("&sj2_trials") == 12 then return nil end
    local enemies = {}
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and not self:doNotDiscard(p, "he") then table.insert(enemies, p) end
    end
    self:sort(enemies, "defense")
    return enemies[1]
end
sgs.ai_skill_invoke.sj2_shenyizhiqu = function(self)
    return self.player:getMark("&sj2_trials") > 0
end
sgs.ai_skill_invoke.sj2_cewai = function(self, data)
    local use = data:toCardUse()
    if self:isFriend(use.from) then return true end
    for _, p in sgs.qlist(use.to) do
        if self:slashIsEffective(use.card, p, use.from) and self:isFriend(p) then return false end
    end
    return use.from:getCardCount(true) >= 2
end
sgs.ai_skill_invoke.sj2_quanjue = function(self, data)
    local number = data:toCardUse().card:getNumber()
    local score = 0
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local sign = self:isEnemy(p) and 1 or (self:isFriend(p) and -1 or 0)
        for _, c in sgs.qlist(p:getCards("ej")) do
            if c:getNumber() < number then
                score = score + sign * (c:isKindOf("DelayedTrick") and -1 or 1)
            end
        end
        -- AI不读取隐藏手牌的点数，以预期数量估值。
        score = score + sign * p:getHandcardNum() * math.max(0, number - 1) / 13
    end
    return score >= 2
end
local sj2_zhan_skill = {name = "sj2_zhanwuchangfa"}
table.insert(sgs.ai_skills, sj2_zhan_skill)
sj2_zhan_skill.getTurnUseCard = function(self)
    if self.player:getMark("sj2_zhan_blocked") == 0 then
        return sgs.Card_Parse("#sj2_zhanwuchangfaCard:.:")
    end
end
sgs.ai_skill_use_func["#sj2_zhanwuchangfaCard"] = function(card, use, self)
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        -- 移动模式优先取敌人手牌；避免提出没有合法接收区域的装备移动。
        if (self.player:getMark("sj2_move_mode") > 0 and not enemy:isKongcheng())
            or (self.player:getMark("sj2_move_mode") == 0 and self.player:canDiscard(enemy, "hej")
                and not self:doNotDiscard(enemy, "he")) then
            use.card = card
            if use.to then use.to:append(enemy) end
            return
        end
    end
end
sgs.ai_skill_playerchosen.sj2_zhan_move = function(self, targets)
    for _, p in sgs.qlist(targets) do if p == self.player then return p end end
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_use_priority.sj2_zhanwuchangfaCard = 5

sgs.ai_skill_choice.sj2_zhanwuchangfa = function(self) return "move" end

-- 三国杀设计吧 3S5J 埃莉诺：只存低价值牌，保留防御与回复。
local function sj5_ban_ids(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not c:isKindOf("Jink") and not c:isKindOf("Analeptic")
            and self:getKeepValue(c) < 4 then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
local sj5_fengying_skill = {name = "sj5_fengying"}
table.insert(sgs.ai_skills, sj5_fengying_skill)
sj5_fengying_skill.getTurnUseCard = function(self)
    local ids = sj5_ban_ids(self)
    if #ids > 0 then return sgs.Card_Parse("#sj5_fengyingCard:" .. table.concat(ids, "+") .. ":") end
end
sgs.ai_skill_use_func["#sj5_fengyingCard"] = function(card, use, self) use.card = card end
sgs.ai_skill_use["@@sj5_fengying"] = function(self)
    local ids = sj5_ban_ids(self)
    return #ids > 0 and ("#sj5_fengyingCard:" .. table.concat(ids, "+") .. ":") or "."
end
sgs.ai_skill_invoke.sj5_wangting = function(self, data)
    local other = data:toPlayer()
    if not other then return false end
    local ban = self.player:getPile("sj5_ban"):length()
    if self:isFriend(other) then return ban > other:getHandcardNum() end
    return self:isEnemy(other) and other:getHandcardNum() > 0 and ban <= other:getHandcardNum() + 1
end
sgs.ai_skill_invoke.sj5_wangting_reset = true
sgs.ai_use_priority.sj5_fengyingCard = 0.1

sgs.ai_skill_invoke.sj7_xiangjian = function(self, data)
    local current = data:toPlayer()
    return current and (self:isEnemy(current) and current:faceUp() or self:isFriend(current) and not current:faceUp())
end
sgs.ai_skill_cardask["@sj7-xiangjian-discard"] = function(self, data, pattern)
    local current = data:toPlayer()
    if not current then return "." end
    local good = self:isEnemy(current) and current:faceUp() or self:isFriend(current) and not current:faceUp()
    if not good then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if sgs.Sanguosha:matchExpPattern(pattern, self.player, c) and not self.player:isJilei(c)
            and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_invoke.sj7_xiangjian_turn = function(self, data)
    local current = data:toPlayer()
    return current and (self:isEnemy(current) and current:faceUp() or self:isFriend(current) and not current:faceUp())
end
sgs.ai_skill_invoke.sj7_chaoai_fangzhu = function(self, data)
    local target = data:toPlayer()
    if not target then return false end
    local bad = self:toTurnOver(target, self.player:getLostHp(), "fangzhu")
    return self:isEnemy(target) and bad or self:isFriend(target) and not bad
end
end

-- ===== sheji b01 =====
do
sgs.ai_skill_invoke.sj2_jizhengzhe = function(self, data) return self.player:getHandcardNum() >= 2 end
sgs.ai_skill_playerchosen.sj2_jizhengzhe = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return nil
end
sgs.ai_skill_discard.sj2_jizhengzhe = function(self, discard_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return {cards[1]:getEffectiveId()}
end
sgs.ai_skill_playerchosen.sj2_tuotujun = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.sj2_faolaozhishe = function(self, data) return self.player:getHp() > 1 end
sgs.ai_skill_invoke.sj2_seyou = function(self, data) return self.player:getCardCount(true) >= 2 end
end

-- ===== sheji b02 =====
do
-- b02: no skills registered, no AI needed.
end

-- ===== sheji b03 =====
do
-- b03: no skills registered, no AI needed.
end

-- ===== sheji b04 =====
do
-- sj5 贝多芬
sgs.ai_skill_invoke.sj5_junbuzhisong = function(self, data)
    local damage = data and data:toDamage()
    if damage and damage.to and damage.from then
        return self:isFriend(damage.from) and self:isEnemy(damage.to)
    end
    return true
end
sgs.ai_skill_cardask["@sj5_junbuzhisong-recast"] = function(self, data, pattern)
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isKindOf("Jink") then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_playerchosen.sj5_junbuzhisong = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do
        if self:isFriend(p) then return p end
    end
    return list[1]
end
sgs.ai_skill_choice.sj5_yikuyile = function(self, choices, data)
    if string.find(choices, "discard") then
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isEnemy(p) and not p:isNude() then return "discard" end
        end
    end
    return "cancel"
end
sgs.ai_skill_playerchosen.sj5_yikuyile = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and not p:isNude() then return p end
    end
    return targets:first()
end
-- sj9 曹休
sgs.ai_skill_invoke.sj9_qingshi = function(self, data)
    local to = data and data:toPlayer()
    return to ~= nil and self:isEnemy(to)
end
sgs.ai_skill_askforag.sj9_qingshi = function(self, card_ids)
    return card_ids[1]
end
-- sj9 罗宪
sgs.ai_skill_invoke.sj9_lixian = true
end

-- ===== sheji b05 =====
do
sgs.ai_skill_invoke.sj9_tongzheng = function(self, data)
    local p = data:toPlayer()
    return p ~= nil and self:isFriend(p)
end
sgs.ai_skill_choice.sj9_tongzheng = function(self, choices, data)
    local p = data:toPlayer()
    if p and p:objectName() == self.player:objectName() then return "use" end
    return p and self:isFriend(p) and "give" or "use"
end
sgs.ai_skill_playerchosen.sj9_yaopan = function(self, targets)
    for _, q in sgs.qlist(targets) do if self:isFriend(q) and not q:isChained() then return q end end
    return nil
end
sgs.ai_skill_choice.sj9_yaopan = function(self, choices)
    for _, e in ipairs(self.enemies or {}) do
        if self.player:canSlash(e, nil, false) then return "slash" end
    end
    return "cancel"
end
sgs.ai_skill_playerchosen.sj9_yaopan_use = function(self, targets)
    for _, q in sgs.qlist(targets) do if self:isEnemy(q) then return q end end
    return targets:first()
end
end

-- ===== sheji b06 =====
do
sgs.ai_skill_invoke.sj9_qinke = function(self, data) return not self.player:isNude() end
sgs.ai_skill_cardask["@sj9_qinke"] = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards == 0 then return "." end
    self:sortByKeepValue(cards)
    return "$" .. cards[1]:getEffectiveId()
end
sgs.ai_skill_playerchosen.sj9_pengzheng = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "hp")
    for _, p in ipairs(list) do
        if self:isEnemy(p) and not p:isChained() then return p end
    end
    return nil
end
sgs.ai_skill_playerchosen.sj9_yiyi = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "handcard", true)
    for _, p in ipairs(list) do
        if self:isEnemy(p) and p:getHandcardNum() > 0 then return p end
    end
    for _, p in ipairs(list) do
        if p:objectName() == self.player:objectName() then return p end
    end
    return list[1]
end
sgs.ai_skill_use_func["#sj9_yiyiCard"] = function(card, use, self)
    use.card = card
end
sgs.ai_use_priority.sj9_yiyiCard = 3
end

-- ===== sheji b07 =====
do
-- sj7_fuguang / sj7_yongyi are compulsory; the AG pick uses default AI.
sgs.ai_skill_askforag.sj7_yongyi = function(self, card_ids)
    return card_ids[1]
end
-- 清弹: choose a name whose flip count reaches "only that 弦 face up"; otherwise cancel.
local function sj7_ai_flips(p, name)
    local order = {"slash", "jink", "peach", "analeptic"}
    local diff, idx = {}, 0
    for i, n in ipairs(order) do
        local up = p:getMark("&sj7_sixian_" .. n) > 0
        if n == name then idx = i end
        if up ~= (n == name) then table.insert(diff, n) end
    end
    return diff, idx
end
sgs.ai_skill_choice.sj7_qingtan = function(self, choices)
    local cs = choices:split("+")
    for _, n in ipairs(cs) do
        if n ~= "cancel" then
            local diff, idx = sj7_ai_flips(self.player, n)
            if idx > 0 and #diff == idx then return n end
        end
    end
    return table.contains(cs, "cancel") and "cancel" or cs[1]
end
sgs.ai_skill_choice.sj7_qingtan_flip = function(self, choices)
    local cs = choices:split("+")
    local target = self.player:getTag("sj7_qingtan_target"):toString()
    local diff = sj7_ai_flips(self.player, target)
    for _, n in ipairs(diff) do
        if table.contains(cs, n) then return n end
    end
    return cs[1]
end
sgs.ai_skill_use["@@sj7_qingtan"] = function(self)
    local name = self.player:getTag("sj7_qingtan_card"):toString()
    if name == "" then return "." end
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    c:setSkillName("sj7_qingtan")
    local use = self:aiUseCard(c)
    if use and use.card then
        local names = {}
        if use.to then for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end end
        if #names > 0 then return c:toString() .. "->" .. table.concat(names, "+") end
        return c:toString()
    end
    return "."
end
sgs.ai_skill_use_func["sj7_qingtanCard"] = function(card, use, self)
    local order = {"slash", "peach", "analeptic"}
    for _, n in ipairs(order) do
        local diff, idx = sj7_ai_flips(self.player, n)
        if #diff == idx and self.player:getMark("sj7_sixian_set") > 0
            and self.player:getMark("sj7_qingtan_" .. n .. "-Clear") == 0 then
            use.card = card
            return
        end
    end
end
sgs.ai_use_priority.sj7_qingtanCard = 3
end

-- ===== sheji b08 =====
do
sgs.ai_skill_invoke.sj7_pianxiang = function(self, data)
    for _, n in ipairs({"bazhen", "longdan", "paoxiao"}) do
        if self.player:hasSkill(n) then return true end
    end
    return false
end
sgs.ai_skill_choice.sj7_pianxiang = function(self, choices, data)
    local list = string.split(choices, "+")
    for _, n in ipairs({"bazhen", "longdan", "paoxiao"}) do
        if table.contains(list, n) then return n end
    end
    return "cancel"
end
sgs.ai_skill_choice.sj7_pianxiang_use = function(self, choices, data)
    local list = string.split(choices, "+")
    for _, n in ipairs({"ex_nihilo", "peach", "slash"}) do
        if table.contains(list, n) then return n end
    end
    return list[1]
end
sgs.ai_skill_playerchosen.sj7_pianxiang_use = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_skill_invoke.sj11_chaomian_slash = function(self, data)
    local to = data:toPlayer()
    return to ~= nil and self:isEnemy(to)
end
sgs.ai_skill_invoke.sj11_xiti = true
sgs.ai_skill_invoke.sj11_xiti_draw = function(self, data)
    local to = data:toPlayer()
    return to ~= nil and self:isFriend(to)
end
sgs.ai_skill_invoke.sj11_xiti_discard = function(self, data)
    local to = data:toPlayer()
    return to ~= nil and self:isEnemy(to)
end
end

-- ===== sheji b09 =====
do
-- b09: no AI (no generals ported).
end
