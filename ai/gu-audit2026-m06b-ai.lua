-- 2026-06 batch: 谋关羽 / 孙綝 / 势程普.
-- Loaded only when this file is on the SmartAI scan path (lua/ai). The engine
-- tree has no lua/ai directory; this copy lives with the extension AI files.

local function gu_contains(targets, player)
	if not targets or not player then return false end
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

sgs.ai_skill_invoke.gu_weishi = function(self, data)
	local use = data and data.toCardUse and data:toCardUse()
	if use and use.card and not use.card:isDamageCard() and use.from and self:isFriend(use.from) then
		return false
	end
	return true
end

sgs.ai_skill_invoke.gu_duzuo = function(self)
	return true
end

sgs.ai_skill_playerchosen.gu_duzuo = function(self, targets)
	self:sort(self.friends, "handcard")
	for _, p in ipairs(self.friends) do
		if gu_contains(targets, p) then return p end
	end
	return targets:first()
end

sgs.ai_skill_playerchosen.gu_lulian = function(self, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then
		for _, p in sgs.qlist(targets) do table.insert(pool, p) end
	end
	self:sort(pool, "hp")
	return pool[1]
end

sgs.ai_skill_invoke.gu_bihan = function(self, data)
	local victim = data and data.toPlayer and data:toPlayer()
	return victim and self:isFriend(victim)
end

sgs.ai_skill_choice.gu_bihan = function(self, choices, data)
	local victim = data and data.toPlayer and data:toPlayer()
	if not victim or victim:objectName() == self.player:objectName() then return "self" end
	local function excess(p)
		return math.max(0, p:getHandcardNum() - math.max(0, p:getHp()))
	end
	if self:isFriend(victim) then
		return excess(self.player) <= excess(victim) and "self" or "victim"
	end
	return excess(victim) > 0 and "victim" or "self"
end

sgs.ai_skill_cardask["@gu_nigu-give"] = function(self, data, pattern, target)
	if not target or self:isFriend(target) then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

local gu_juao_skill = {name = "gu_juao"}
table.insert(sgs.ai_skills, gu_juao_skill)
gu_juao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("GuJuaoCard") then return nil end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return nil end
	local hit = false
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then hit = true break end
	end
	if not hit then return nil end
	self:sortByKeepValue(cards)
	return sgs.Card_Parse("@GuJuaoCard=" .. cards[1]:getEffectiveId() .. ":slash")
end

sgs.ai_skill_use_func.GuJuaoCard = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end
sgs.ai_use_priority.GuJuaoCard = 2.5

local gu_nigu_skill = {name = "gu_nigu"}
table.insert(sgs.ai_skills, gu_nigu_skill)
gu_nigu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("GuNiguCard") then return nil end
	local hit = false
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then hit = true break end
	end
	if not hit then return nil end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return nil end
	self:sortByKeepValue(cards)
	return sgs.Card_Parse("@GuNiguCard=" .. cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func.GuNiguCard = function(card, use)
	use.card = card
end
sgs.ai_use_priority.GuNiguCard = 4
