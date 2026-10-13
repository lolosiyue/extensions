-- GU-audit2026 2026-08b smart-ai (loaded from mobile-ai.lua).
-- 谋祝融（OL） gu_olmouzhurong / 曹金玉（OL） gu_olcaojinyu / 界步练师（OL） gu_oljiebulianshi.

local function gu08b_contains(targets, player)
	if not targets or not player then return false end
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

-- ---------------- 谋祝融 刃掣 ----------------
local gu_renche_skill = {name = "gu_renche"}
table.insert(sgs.ai_skills, gu_renche_skill)
gu_renche_skill.getTurnUseCard = function(self)
	local x = math.max(1, self.player:getMark("&gu_renche_x-Clear"))
	if self.player:getMark("gu_renche_used-PlayClear") >= x then return nil end
	local victims = 0
	for _, p in ipairs(self.enemies) do
		if not p:isNude() then victims = victims + 1 end
	end
	if victims == 0 or x > math.max(2, victims) then return nil end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards < x then return nil end
	self:sortByKeepValue(cards)
	local ids = {}
	for i = 1, x do
		if cards[i]:isKindOf("Peach") then return nil end
		table.insert(ids, cards[i]:getEffectiveId())
	end
	return sgs.Card_Parse("@Gu08bRencheCard=" .. table.concat(ids, "+"))
end

sgs.ai_skill_use_func.Gu08bRencheCard = function(card, use, self)
	local x = card:subcardsLength()
	local picks = {}
	for _, p in ipairs(self.enemies) do
		if not p:isNude() then table.insert(picks, p) end
	end
	if #picks == 0 then return end
	self:sort(picks, "handcard")
	use.card = card
	if use.to then
		for i = #picks, 1, -1 do
			if use.to:length() >= x then break end
			use.to:append(picks[i])
		end
	end
end
sgs.ai_use_priority.Gu08bRencheCard = 3
sgs.ai_card_intention.Gu08bRencheCard = 40

-- ---------------- 谋祝融 牙镰 ----------------
sgs.ai_skill_playerschosen.gu_yalian = function(self, targets, max_num, min_num)
	local chosen = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(chosen, p) end
	end
	return chosen
end

-- ---------------- 曹金玉 春晖 ----------------
sgs.ai_skill_playerchosen.gu_chunhui = function(self, targets)
	local best
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and (not best or p:getHandcardNum() > best:getHandcardNum()) then best = p end
	end
	if best then return best end
	for _, p in sgs.qlist(targets) do
		if not self:isFriend(p) then return p end
	end
	self:sort(self.friends_noself, "handcard")
	for i = #self.friends_noself, 1, -1 do
		if gu08b_contains(targets, self.friends_noself[i]) then return self.friends_noself[i] end
	end
	return targets:first()
end

-- ---------------- 曹金玉 秋暮 ----------------
sgs.ai_skill_invoke.gu_qiumu = function(self, data)
	local who = data and data.toPlayer and data:toPlayer()
	if not who or who:objectName() == self.player:objectName() then return false end
	if self:isFriend(who) then return false end
	return true
end

-- ---------------- 界步练师 安恤 ----------------
local gu_anxu_skill = {name = "gu_anxu"}
table.insert(sgs.ai_skills, gu_anxu_skill)
gu_anxu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("Gu08bAnxuCard") then return nil end
	return sgs.Card_Parse("@Gu08bAnxuCard=.")
end

sgs.ai_skill_use_func.Gu08bAnxuCard = function(card, use, self)
	local picks = {}
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if not p:isNude() then table.insert(enemies, p) end
	end
	if #enemies == 0 then return end
	self:sort(enemies, "handcard")
	for i = #enemies, 1, -1 do
		if #picks >= 2 then break end
		table.insert(picks, enemies[i])
	end
	if #picks < 2 then
		local friends = {}
		for _, p in ipairs(self.friends_noself) do
			if not p:isNude() then table.insert(friends, p) end
		end
		self:sort(friends, "handcard")
		for _, p in ipairs(friends) do
			if #picks >= 2 then break end
			table.insert(picks, p)
		end
	end
	if #picks < 2 then return end
	use.card = card
	if use.to then
		use.to:append(picks[1])
		use.to:append(picks[2])
	end
end
sgs.ai_use_priority.Gu08bAnxuCard = 6

sgs.ai_skill_askforag.gu_anxu = function(self, card_ids)
	local best, bestValue
	for _, id in ipairs(card_ids) do
		local c = sgs.Sanguosha:getCard(id)
		local value = self:getKeepValue(c)
		if c:getSuit() ~= sgs.Card_Spade then value = value - 10 end
		if not best or value < bestValue then best, bestValue = id, value end
	end
	return best
end

-- ---------------- 界步练师 追忆 ----------------
sgs.ai_skill_playerchosen.gu_zhuiyi = function(self, targets)
	local friends = {}
	for _, p in ipairs(self.friends_noself) do
		if gu08b_contains(targets, p) then table.insert(friends, p) end
	end
	if #friends == 0 then return nil end
	self:sort(friends, "hp")
	local first = friends[1]
	if not first:isWounded() and first:getHandcardNum() > 2 and self.player:getHp() > 1 then return nil end
	return first
end

sgs.ai_skill_invoke.gu_zhuiyi = function(self, data)
	local target = data and data.toPlayer and data:toPlayer()
	return target and self:isFriend(target)
end
