-- GU-audit2026 2026-08c smart-ai (loaded from mobile-ai.lua).
-- 势小乔 合韵/音洄, 势贺齐 闪袭/绮胄, 幻周瑜 督鍪/撼天.

local function gu08c_in(targets, player)
	if not targets or not player then return false end
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

local function gu08c_skill_names(player)
	local names = {}
	for _, sk in sgs.qlist(player:getVisibleSkillList()) do
		if not sk:isAttachedLordSkill() then table.insert(names, sk:objectName()) end
	end
	return names
end

local function gu08c_shares_skill(a, b)
	for _, name in ipairs(gu08c_skill_names(b)) do
		if a:hasSkill(name) then return true end
	end
	return false
end

-- A skill the AI is willing to give up for 合韵.
local function gu08c_spare_skill(self)
	local gained = self.player:getTag("gu_yinhui_skill"):toString()
	if gained ~= "" and self.player:hasSkill(gained) then return gained end
	for _, name in ipairs(gu08c_skill_names(self.player)) do
		if name ~= "gu_heyun" and name ~= "gu_yinhui" then return name end
	end
	return nil
end

-- 合韵
local gu_heyun_skill = { name = "gu_heyun" }
table.insert(sgs.ai_skills, gu_heyun_skill)
gu_heyun_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("Gu08cHeyunCard") >= 2 then return nil end
	if not gu08c_spare_skill(self) then return nil end
	return sgs.Card_Parse("@Gu08cHeyunCard=.")
end

sgs.ai_skill_use_func.Gu08cHeyunCard = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	for _, p in ipairs(self.friends_noself) do
		if gu08c_shares_skill(self.player, p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end
sgs.ai_use_priority.Gu08cHeyunCard = 6
sgs.ai_card_intention.Gu08cHeyunCard = -60

sgs.ai_skill_choice.gu_heyun = function(self, choices)
	local items = choices:split("+")
	local spare = gu08c_spare_skill(self)
	if spare and table.contains(items, spare) then return spare end
	for _, name in ipairs(items) do
		if name ~= "gu_heyun" and name ~= "gu_yinhui" then return name end
	end
	return items[#items]
end

-- 音洄
sgs.ai_skill_invoke.gu_yinhui = function(self)
	return true
end

sgs.ai_skill_playerchosen.gu_yinhui = function(self, targets)
	local best, most = nil, -1
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) then
			local n = #gu08c_skill_names(p)
			if n > most then best, most = p, n end
		end
	end
	return best or targets:first()
end

-- 闪袭
local gu_shanxi_skill = { name = "gu_shanxi" }
table.insert(sgs.ai_skills, gu_shanxi_skill)
gu_shanxi_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, c in ipairs(cards) do
		if c:hasFlag("cardTip:gu_yingji") then
			return sgs.Card_Parse(("duel:gu_shanxi[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
	end
	return nil
end

-- 绮胄: marking an enemy's hand card sends it to the discard pile at turn end.
sgs.ai_skill_playerchosen.gu_qizhou = function(self, targets)
	local pool = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(pool, p) end
	end
	if #pool == 0 then
		if self.player:getPhase() == sgs.Player_Play and gu08c_in(targets, self.player) then return self.player end
		return nil
	end
	self:sort(pool, "handcard")
	return pool[1]
end

-- 督鍪
sgs.ai_skill_invoke.gu_dumou = function(self)
	return true
end

local function gu08c_recast_enemy(self)
	local best, most = nil, 0
	for _, p in ipairs(self.enemies) do
		local n = p:getCardCount(true)
		if n > most then best, most = p, n end
	end
	return best
end

sgs.ai_skill_choice.gu_dumou = function(self, choices)
	if choices:match("recast") and gu08c_recast_enemy(self) then return "recast" end
	return "obtain"
end

sgs.ai_skill_playerchosen.gu_dumou_recast = function(self, targets)
	local enemy = gu08c_recast_enemy(self)
	if enemy and gu08c_in(targets, enemy) then return enemy end
	return targets:first()
end

sgs.ai_skill_playerchosen.gu_dumou_obtain = function(self, targets)
	self:sort(self.friends, "handcard")
	for _, p in ipairs(self.friends) do
		if gu08c_in(targets, p) then return p end
	end
	return targets:first()
end

-- 撼天
local gu_hantian_skill = { name = "gu_hantian" }
table.insert(sgs.ai_skills, gu_hantian_skill)
gu_hantian_skill.getTurnUseCard = function(self)
	if self.player:getMark("gu_hantian-PlayClear") > 0 then return nil end
	return sgs.Card_Parse("fire_attack:gu_hantian[no_suit:0]=.")
end

-- Target side: pick which of this turn's gained cards to show.
sgs.ai_skill_discard.gu_hantian = function(self, max_num, min_num, optional, equiped, pattern)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, c in ipairs(cards) do
		if sgs.Sanguosha:matchExpPattern(pattern, self.player, c) then return { c:getEffectiveId() } end
	end
	return {}
end
