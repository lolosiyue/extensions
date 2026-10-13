-- GU-audit2026 2026-08a smart-ai (loaded from mobile-ai.lua).
-- 威马腾 / 王越 / 傅干 / 木鹿大王（十周年新版）.

local function gu08a_contains(targets, player)
	if not targets or not player then return false end
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

local function gu08a_weakest_enemy(self, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then return nil end
	self:sort(pool, "hp")
	return pool[1]
end

-- 威马腾: keep 骑 on enemies, take them off friends.

local function gu08a_qi_from(self, targets)
	for _, p in sgs.qlist(targets) do
		if p:objectName() ~= self.player:objectName() and self:isFriend(p) then return p end
	end
	if gu08a_contains(targets, self.player) then return self.player end
	for _, p in sgs.qlist(targets) do
		if not self:isEnemy(p) then return p end
	end
	return targets:first()
end

local function gu08a_qi_to(self, targets)
	local from = self.gu08a_qi_from_player
	if from and from:objectName() ~= self.player:objectName() and self:isFriend(from)
		and gu08a_contains(targets, self.player) then
		return self.player
	end
	return gu08a_weakest_enemy(self, targets) or (gu08a_contains(targets, self.player) and self.player) or targets:first()
end

for _, name in ipairs({"gu_huirui", "gu_xiaoben"}) do
	sgs.ai_skill_playerchosen[name .. "_from"] = function(self, targets)
		local p = gu08a_qi_from(self, targets)
		self.gu08a_qi_from_player = p
		return p
	end
	sgs.ai_skill_playerchosen[name .. "_to"] = function(self, targets)
		local p = gu08a_qi_to(self, targets)
		self.gu08a_qi_from_player = nil
		return p
	end
end

sgs.ai_skill_choice.gu_huirui = function(self, choices)
	local items = choices:split("+")
	local has = function(c)
		for _, x in ipairs(items) do if x == c then return true end end
		return false
	end
	if has("move") and #self.enemies > 0 then
		local friendQi = self.player:getMark("&gu_heqi_qi") > 0
		for _, p in ipairs(self.friends_noself) do
			if p:getMark("&gu_heqi_qi") > 0 then friendQi = true end
		end
		if friendQi then return "move" end
	end
	if has("slash") then
		for _, p in ipairs(self.enemies) do
			if self.player:canSlash(p) and not self:slashProhibit(nil, p) then return "slash" end
		end
	end
	return "gain"
end

sgs.ai_skill_playerchosen.gu_huirui = function(self, targets)
	return gu08a_weakest_enemy(self, targets) or targets:first()
end

-- 王越

sgs.ai_skill_invoke.gu_shifeng = function(self, data)
	local use = data and data.toCardUse and data:toCardUse()
	if not use or not use.from then return false end
	if self:isFriend(use.from) then return false end
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then return true end
	end
	return self:getCardsNum("Slash") >= 1
end

sgs.ai_skill_invoke.gu_jiandao_swap = function(self)
	return true
end

sgs.ai_skill_cardchosen.gu_jiandao = function(self, who, flags, method)
	if who:objectName() ~= self.player:objectName() then return nil end
	local cards = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not c:isDamageCard() then table.insert(cards, c) end
	end
	if #cards == 0 then return nil end
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

sgs.ai_skill_cardask["@gu_jiandao-basic"] = function(self, data, pattern, target)
	if self:getCardsNum("Jink") < 1 then return "." end
	local basics = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("BasicCard") and not c:isKindOf("Jink") and not c:isKindOf("Peach") then
			table.insert(basics, c)
		end
	end
	if #basics == 0 then return "." end
	self:sortByKeepValue(basics)
	return "$" .. basics[1]:getEffectiveId()
end

-- 傅干

local gu_qiaojian_skill = {name = "gu_qiaojian"}
table.insert(sgs.ai_skills, gu_qiaojian_skill)
gu_qiaojian_skill.getTurnUseCard = function(self)
	if self.player:getCardCount(true) < 2 then return nil end
	return sgs.Card_Parse("@Gu08aQiaojianCard=.")
end

sgs.ai_skill_use_func.Gu08aQiaojianCard = function(card, use, self)
	local mark = function(p) return self.player:getMark("gu_qiaojian_" .. p:objectName() .. "-PlayClear") end
	self:sort(self.friends_noself, "handcard")
	for _, p in ipairs(self.friends_noself) do
		if mark(p) == 0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sort(self.enemies, "handcard")
	for _, p in ipairs(self.enemies) do
		if mark(p) == 0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end
sgs.ai_use_priority.Gu08aQiaojianCard = 3

sgs.ai_skill_discard.gu_qiaojian = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	local pick = cards[1]
	for i = 1, math.min(3, #cards) do
		if cards[i]:getNumber() > pick:getNumber() then pick = cards[i] end
	end
	return {pick:getEffectiveId()}
end

sgs.ai_skill_discard.gu_qiaojian_target = function(self)
	return {}
end

sgs.ai_skill_choice.gu_qiaojian = function(self, choices, data)
	local target = data and data.toPlayer and data:toPlayer()
	if target and self:isFriend(target) then return "extra" end
	return "ban"
end

sgs.ai_skill_cardchosen.gu_xicha = function(self, who, flags, method)
	local cards = sgs.QList2Table(who:getHandcards())
	if #cards == 0 then return nil end
	local disabled = self.disabled_ids
	local best, bestValue
	for _, c in ipairs(cards) do
		if not (disabled and disabled:contains(c:getEffectiveId())) then
			local v = self:getUseValue(c)
			if not best or v > bestValue then best, bestValue = c, v end
		end
	end
	return best and best:getEffectiveId() or nil
end

-- 木鹿大王

local function gu08a_zhoufa_material(self)
	local cards = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:getTypeId() ~= sgs.Card_TypeBasic and not c:isKindOf("Nullification") and not c:isDamageCard() then
			table.insert(cards, c)
		end
	end
	if #cards == 0 then return nil end
	self:sortByUseValue(cards, true)
	return cards[1]
end

local gu_zhoufa_skill = {name = "gu_zhoufa"}
table.insert(sgs.ai_skills, gu_zhoufa_skill)
gu_zhoufa_skill.getTurnUseCard = function(self)
	local card = gu08a_zhoufa_material(self)
	if not card or #self.enemies == 0 then return nil end
	local name = "duel"
	if sgs.Slash_IsAvailable(self.player) then
		for _, p in ipairs(self.enemies) do
			if self.player:canSlash(p) then name = "slash" break end
		end
	end
	return sgs.Card_Parse(("%s:gu_zhoufa[%s:%s]=%d"):format(name, card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
end
sgs.ai_use_priority.gu_zhoufa = 2.6

sgs.ai_view_as.gu_zhoufa = function(card, player, card_place, class_name)
	if class_name ~= "Slash" then return nil end
	if card:getTypeId() == sgs.Card_TypeBasic or card_place == sgs.Player_PlaceSpecial then return nil end
	if card:isKindOf("Nullification") or card:isKindOf("Peach") then return nil end
	return ("slash:gu_zhoufa[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
end

sgs.ai_skill_choice.gu_shouqun = function(self, choices)
	local init = self.player:getMark("gu_shouqun_init")
	if init > 0 and self.player:getMaxHp() < init and self.player:getHp() <= 2 then return "pick" end
	return "all"
end
