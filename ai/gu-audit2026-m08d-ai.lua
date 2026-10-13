-- GU-audit2026 2026-08d smart-ai (loaded from mobile-ai.lua).
-- 界严颜[手杀] gu_jieyanyan / 崔琰毛玠[手杀] gu_cuiyanmaojie / 界王基[手杀] gu_jiewangji.

local function gu08d_chargeMax(player)
	local n = 0
	local ok = pcall(function()
		for _, sk in sgs.qlist(player:getVisibleSkillList()) do
			local cn = sk:property("ChargeNum"):toString()
			if cn ~= "" then
				n = n + (tonumber(cn:split("/")[2]) or 0)
			end
		end
	end)
	if not ok then return 0 end
	return n
end

local function gu08d_contains(targets, player)
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

-- 拒战 (阳): drawing together with the user is always worth it.
sgs.ai_skill_invoke.gu_juzhan = function(self, data)
	return true
end

-- 拒战 (阴): take a card from an enemy target only.
sgs.ai_skill_playerchosen.gu_juzhan = function(self, targets)
	local pool = sgs.QList2Table(targets)
	self:sort(pool, "defense")
	for _, p in ipairs(pool) do
		if self:isEnemy(p) then return p end
	end
	return nil
end

-- 征辟: enemies first (take good cards, return weak ones), then friends with
-- delayed tricks in their judge area.
sgs.ai_skill_playerschosen.gu_zhengpi = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
	local pool = sgs.QList2Table(targets)
	self:sort(pool, "handcard")
	for i = #pool, 1, -1 do
		local p = pool[i]
		if selected:length() < max and self:isEnemy(p) and not p:isNude() then
			selected:append(p)
		end
	end
	for _, p in ipairs(pool) do
		if selected:length() < max and self:isFriend(p) and p:getJudgingArea():length() > 0
			and not gu08d_contains(selected, p) then
			selected:append(p)
		end
	end
	return selected
end

-- 征辟 (target side): help a friendly owner grow the skill, give enemies the minimum.
sgs.ai_skill_choice.gu_zhengpi = function(self, choices, data)
	local owner = data and data.toPlayer and data:toPlayer()
	local items = choices:split("+")
	if owner and self:isFriend(owner) then
		if table.contains(items, "3") then return "3" end
		return items[#items]
	end
	return items[1]
end

-- 奉迎: pick a friend whose attack range covers the most characters with hand cards.
local function gu08d_fengyingScore(self, target)
	local n = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() ~= target:objectName() and target:inMyAttackRange(p) and not p:isKongcheng() then
			n = n + 1
		end
	end
	return n
end

local function gu08d_isMaxHpTop(self, target)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMaxHp() > target:getMaxHp() then return false end
	end
	return true
end

local gu_fengying_skill = {name = "gu_fengying"}
table.insert(sgs.ai_skills, gu_fengying_skill)
gu_fengying_skill.getTurnUseCard = function(self)
	if self.player:getMark("@gu_fengying") < 1 then return nil end
	return sgs.Card_Parse("@Gu08dFengyingCard=.")
end

sgs.ai_skill_use_func.Gu08dFengyingCard = function(card, use, self)
	local best, bestScore = nil, 0
	for _, p in ipairs(self.friends) do
		local score = gu08d_fengyingScore(self, p) * 2
		if p:objectName() == self.player:objectName() and gu08d_isMaxHpTop(self, p) then
			score = score + 3
		elseif gu08d_isMaxHpTop(self, p) then
			score = score + 2
		end
		if score > bestScore then best, bestScore = p, score end
	end
	if best and bestScore >= 5 then
		use.card = card
		if use.to then use.to:append(best) end
	end
end
sgs.ai_use_priority.Gu08dFengyingCard = 1.5

-- 奇制: let another friend draw two.
local gu_qizhi_skill = {name = "gu_qizhi"}
table.insert(sgs.ai_skills, gu_qizhi_skill)
gu_qizhi_skill.getTurnUseCard = function(self)
	if self.player:getMark("&charge_num") < 1 then return nil end
	return sgs.Card_Parse("@Gu08dQizhiCard=.")
end

sgs.ai_skill_use_func.Gu08dQizhiCard = function(card, use, self)
	local mark = "gu_qizhi_" .. self.player:objectName() .. "-PlayClear"
	local pool = {}
	for _, p in ipairs(self.friends_noself) do
		if p:getMark(mark) < 1 then table.insert(pool, p) end
	end
	self:sort(pool, "handcard")
	-- Self-targeting would discard your own hand on every later basic/trick.
	local target = pool[1]
	if not target then return end
	use.card = card
	if use.to then use.to:append(target) end
end
sgs.ai_use_priority.Gu08dQizhiCard = 7

-- 进趋: give the charge to yourself first, else to a friend with room for it.
sgs.ai_skill_playerchosen.gu_jinqu = function(self, targets)
	if self.player:getMark("&charge_num") < gu08d_chargeMax(self.player) then return self.player end
	for _, p in ipairs(self.friends_noself) do
		if gu08d_contains(targets, p) and p:getMark("&charge_num") < gu08d_chargeMax(p) then return p end
	end
	return self.player
end
