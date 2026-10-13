-- GU-audit2026 2026-07a smart-ai (loaded from mobile-ai.lua).
-- 星夏侯霸 gu_xingxiahouba / 夏侯恩 gu_xiahouen / 谋张任 gu_mouzhangren.

local function gu07a_parse_ids(pattern)
	local ids = {}
	for id in string.gmatch(pattern or "", "%d+") do ids[tonumber(id)] = true end
	return ids
end

local function gu07a_weakest_enemy(self, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then return nil end
	self:sort(pool, "hp")
	return pool[1]
end

-- 维谷 ---------------------------------------------------------------
local function gu07a_weigu_extra_score(self, use)
	local score = 0
	if not use or not use.card then return 0 end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		local skip = (use.from and p:objectName() == use.from:objectName())
		if not skip then
			for _, t in sgs.qlist(use.to) do
				if t:objectName() == p:objectName() then skip = true break end
			end
		end
		if not skip and self.player:inMyAttackRange(p) then
			if self:isEnemy(p) then score = score + 1 elseif self:isFriend(p) then score = score - 1 end
		end
	end
	if use.from and self:isEnemy(use.from) then score = -score end
	return score
end

sgs.ai_skill_invoke.gu_weigu = function(self, data)
	if self.player:getMark("&gu_juefa") > 0 then return true end
	local use = data and data.toCardUse and data:toCardUse()
	if self.player:getHp() <= 1 then return false end
	if use and use.from and use.from:objectName() == self.player:objectName() then
		return gu07a_weigu_extra_score(self, use) > 0 or self.player:getHp() >= 3
	end
	return self.player:getHp() >= 3
end

sgs.ai_skill_discard.gu_weigu = function(self, discard_num, min_num, optional, include_equip, pattern)
	local allowed = gu07a_parse_ids(pattern)
	local cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if allowed[c:getEffectiveId()] then table.insert(cards, c) end
	end
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	return { cards[1]:getEffectiveId() }
end

sgs.ai_skill_choice.gu_weigu = function(self, choices, data)
	local items = choices:split("+")
	local has = function(n) return table.contains(items, n) end
	if has("damage") then return "damage" end
	local use = data and data.toCardUse and data:toCardUse()
	if has("target") and gu07a_weigu_extra_score(self, use) > 0 then return "target" end
	if has("move") then return "move" end
	return items[1]
end

sgs.ai_skill_playerchosen.gu_weigu_damage = function(self, targets)
	return gu07a_weakest_enemy(self, targets) or targets:last()
end

-- 绝伐: only when an enemy is low enough to be finished by 维谷's 2 damage.
local gu_juefa_skill = { name = "gu_juefa" }
table.insert(sgs.ai_skills, gu_juefa_skill)
gu_juefa_skill.getTurnUseCard = function(self)
	if self.player:getMark("@gu_juefa") <= 0 or self.player:getHp() < 2 then return nil end
	for _, p in ipairs(self.enemies) do
		if p:getHp() <= 2 and not p:hasArmorEffect("silver_lion") then
			return sgs.Card_Parse("@Gu07aJuefaCard=.")
		end
	end
	return nil
end
sgs.ai_skill_use_func.Gu07aJuefaCard = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.Gu07aJuefaCard = 6

-- 恃武 ---------------------------------------------------------------
sgs.ai_skill_invoke.gu_shiwu = function(self, data)
	local target = data and data.toPlayer and data:toPlayer()
	if not target or not self:isEnemy(target) then return false end
	if self:getCardsNum("Slash") >= getCardsNum("Slash", target, self.player) then return true end
	return self.player:getHp() >= 3
end

-- 慑道 ---------------------------------------------------------------
sgs.ai_skill_invoke.gu_shedao = function(self, data)
	return true
end

sgs.ai_skill_choice.gu_shedao = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "slash") and self.player:hasSkill("gu_xunshi") then return "slash" end
	if table.contains(items, "red") then return "red" end
	return items[1]
end

sgs.ai_skill_discard.gu_shedao = function(self, discard_num, min_num, optional, include_equip, pattern)
	local cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:isBlack() then table.insert(cards, c) end
	end
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	return { cards[1]:getEffectiveId() }
end

-- 震弓 ---------------------------------------------------------------
local gu_zhengong_skill = { name = "gu_zhengong" }
table.insert(sgs.ai_skills, gu_zhengong_skill)
gu_zhengong_skill.getTurnUseCard = function(self)
	if self.player:getMark("@gu_zhengong") <= 0 or #self.enemies == 0 then return nil end
	local groups = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if not self.player:isJilei(c) then
			local key = c:isKindOf("Slash") and "slash" or c:objectName()
			groups[key] = groups[key] or {}
			table.insert(groups[key], c)
		end
	end
	local best
	for _, list in pairs(groups) do
		if not best or #list > #best then best = list end
	end
	if not best then return nil end
	local weakest = 99
	for _, p in ipairs(self.enemies) do weakest = math.min(weakest, p:getHp()) end
	if #best < 3 and #best < weakest then return nil end
	local ids = {}
	for _, c in ipairs(best) do table.insert(ids, tostring(c:getEffectiveId())) end
	return sgs.Card_Parse("@Gu07aZhengongCard=" .. table.concat(ids, "+"))
end
sgs.ai_skill_use_func.Gu07aZhengongCard = function(card, use, self)
	local n = card:subcardsLength()
	self:sort(self.enemies, "hp")
	for _, p in ipairs(self.enemies) do
		if use.to:length() >= n then break end
		use.to:append(p)
	end
	if use.to:length() > 0 then use.card = card end
end
sgs.ai_use_priority.Gu07aZhengongCard = 3

sgs.ai_skill_playerchosen.gu_zhengong = function(self, targets)
	return gu07a_weakest_enemy(self, targets) or targets:first()
end
