-- GU-audit2026 2026-07b smart-ai (loaded from mobile-ai.lua).
-- 李昭仪 gu_lizhaoyi / 段煨 gu_duanwei / 势周瑜 gu_shizhouyu.

local function gu07b_has(choices, name)
	for _, c in ipairs(choices:split("+")) do
		if c == name then return true end
	end
	return false
end

-- ---------------- 李昭仪 ----------------

sgs.ai_skill_playerchosen.gu_mingjie = function(self, targets)
	-- The partner's death kills you: prefer the sturdiest friend (the lord first).
	local best, bestScore
	for _, p in sgs.qlist(targets) do
		local score = p:getHp() + p:getMaxHp() * 0.1
		if self:isFriend(p) then score = score + 100 end
		if p:isLord() and self:isFriend(p) then score = score + 5 end
		if not bestScore or score > bestScore then best, bestScore = p, score end
	end
	return best or targets:first()
end

sgs.ai_skill_invoke.gu_mingjie = function(self, data)
	local p = data and data.toPlayer and data:toPlayer()
	return p ~= nil and self:isFriend(p)
end

sgs.ai_skill_invoke.gu_xianfu = function(self, data)
	local use = data and data.toCardUse and data:toCardUse()
	if not use or not use.card then return false end
	if use.from and self:isFriend(use.from) then return false end
	local c = use.card
	if c:isDamageCard() then return true end
	return c:isKindOf("Snatch") or c:isKindOf("Dismantlement") or c:isKindOf("Indulgence")
		or c:isKindOf("SupplyShortage") or c:isKindOf("Collateral") or c:isKindOf("FireAttack")
end

-- ---------------- 段煨 ----------------

sgs.ai_skill_discard.gu_taohuai = function(self, discard_num, min_num, optional, include_equip)
	-- Discarding only flips the state; do it with a card that would be lost to the hand limit anyway.
	if self.player:getHandcardNum() <= self.player:getMaxCards() then return {} end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	return { cards[1]:getEffectiveId() }
end

-- ---------------- 势周瑜 ----------------

sgs.ai_skill_askforyiji.gu_chiyun = function(self, card_ids, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then return nil, -1 end
	self:sort(pool, "hp")
	local cards = {}
	for _, id in ipairs(card_ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
	self:sortByKeepValue(cards)
	if #cards == 0 then return nil, -1 end
	return pool[1], cards[1]:getEffectiveId()
end

sgs.ai_skill_choice.gu_chiyun = function(self, choices, data)
	local owner = data and data.toPlayer and data:toPlayer()
	if owner and self:isFriend(owner) and gu07b_has(choices, "chain") then return "chain" end
	if self.player:getHp() <= 2 and gu07b_has(choices, "chain") then return "chain" end
	if gu07b_has(choices, "show") then return "show" end
	return choices:split("+")[1]
end

sgs.ai_skill_invoke.gu_yanhui = function(self, data)
	local p = data and data.toPlayer and data:toPlayer()
	if not p or p:objectName() == self.player:objectName() then return false end
	return not self:isFriend(p)
end

sgs.ai_skill_choice.gu_yanhui = function(self, choices, data)
	if gu07b_has(choices, "damage") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getMark("gu_yanhui_lost-Clear") > 0 and self:isEnemy(p) then return "damage" end
		end
	end
	if gu07b_has(choices, "draw") then return "draw" end
	return "cancel"
end

sgs.ai_skill_playerchosen.gu_yanhui = function(self, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then
		for _, p in sgs.qlist(targets) do
			if not self:isFriend(p) then table.insert(pool, p) end
		end
	end
	if #pool == 0 then
		for _, p in sgs.qlist(targets) do table.insert(pool, p) end
	end
	self:sort(pool, "hp")
	return pool[1]
end

sgs.ai_skill_choice.gu_fentao = function(self, choices, data)
	-- Option 1 only raises the damage the iron chain passes on to the others.
	local friends, enemies = 0, 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isChained() then
			if self:isFriend(p) then friends = friends + 1 else enemies = enemies + 1 end
		end
	end
	if friends == 0 or enemies > friends then return "conduct" end
	return "discard"
end

sgs.ai_skill_invoke.gu_xiongzi = function(self)
	if self.player:getHp() <= 2 then return true end
	for _, p in ipairs(self.enemies) do
		if p:getHp() <= 2 then return true end
	end
	return false
end

sgs.ai_skill_choice.gu_xiongzi = function(self, choices)
	return "one"
end
