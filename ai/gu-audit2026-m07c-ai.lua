-- GU-audit2026 2026-07c smart-ai (loaded from mobile-ai.lua).
-- 界周妃 gu_jiezhoufei / 幻大乔 gu_huandaqiao / 疑伏寿 gu_yifushou.

local function gu07c_player(self, name)
	if not name or name == "" then return nil end
	return self.room:findPlayerByObjectName(name)
end

local function gu07c_contains(targets, player)
	if not targets or not player then return false end
	for _, p in sgs.qlist(targets) do
		if p:objectName() == player:objectName() then return true end
	end
	return false
end

-- 良姻
sgs.ai_skill_playerchosen.gu_liangyin = function(self, targets)
	local mode = self.player:getTag("GuLiangyinMode"):toString()
	local list = sgs.QList2Table(targets)
	if mode == "discard" then
		list = self:sort(list, "handcard", true)
		for _, p in ipairs(list) do
			if self:isEnemy(p) and p:getCardCount(true) > 0 then return p end
		end
		for _, p in ipairs(list) do
			if not self:isFriend(p) then return p end
		end
		for _, p in ipairs(list) do
			if p:getCardCount(true) > 2 then return p end
		end
		return list[1]
	end
	list = self:sort(list, "handcard")
	for _, p in ipairs(list) do
		if self:isFriend(p) then return p end
	end
	return list[1]
end

sgs.ai_skill_choice.gu_liangyin = function(self, choices, data)
	local items = choices:split("+")
	local healed = gu07c_player(self, self.player:getTag("GuLiangyinRecover"):toString())
	local victim = gu07c_player(self, self.player:getTag("GuLiangyinLose"):toString())
	local canRecover = table.contains(items, "recover") and healed
	local canLose = table.contains(items, "lose") and victim
	if canLose and self:isEnemy(victim) then return "lose" end
	if canRecover and self:isFriend(healed) and healed:isWounded() then return "recover" end
	if canRecover and not (self:isEnemy(healed) and healed:isWounded()) then return "recover" end
	if canLose and not self:isFriend(victim) then return "lose" end
	if canRecover then return "recover" end
	return items[1]
end

-- 箜声
sgs.ai_skill_invoke.gu_kongsheng = function(self, data)
	local current = data:toPlayer()
	if not current then return false end
	if current:objectName() == self.player:objectName() then
		return self.player:getCardCount(true) > 1
	end
	return self:isEnemy(current)
end

sgs.ai_skill_discard.gu_kongsheng = function(self, max_num, min_num)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return {} end
	for _, c in ipairs(cards) do
		if c:isKindOf("Jink") or c:isKindOf("Nullification") then return { c:getEffectiveId() } end
	end
	self:sortByKeepValue(cards)
	return { cards[1]:getEffectiveId() }
end

sgs.ai_skill_use["@@gu_kongsheng"] = function(self, prompt)
	local ids = self.player:getPile("#gu_kongsheng")
	for _, id in sgs.qlist(ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card and card:isAvailable(self.player) then
			local dummy = self:aiUseCard(card)
			if dummy.card and dummy.to then
				local tos = {}
				for _, p in sgs.qlist(dummy.to) do table.insert(tos, p:objectName()) end
				return card:toString() .. "->" .. (#tos > 0 and table.concat(tos, "+") or ".")
			end
		end
	end
	return "."
end

-- 帼色
sgs.ai_skill_invoke.gu_guose = function(self, data)
	local target = data:toPlayer()
	return target and self:isEnemy(target) and target:objectName() ~= self.player:objectName()
end

sgs.ai_skill_choice.gu_guose = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "swap") then
		if target and self:isFriend(target) then return "swap" end
		return "cancel"
	end
	if table.contains(items, "target") and target and self:isEnemy(target) then return "target" end
	return items[1]
end

sgs.ai_skill_discard.gu_guose = function(self, max_num, min_num)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	return { cards[1]:getEffectiveId() }
end

-- 流俪
sgs.ai_skill_invoke.gu_liuli = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	if not self:isFriend(target) then return false end
	local from = gu07c_player(self, self.player:getTag("GuLiuliFrom"):toString())
	if from and self:isFriend(from) and not target:getJudgingArea():isEmpty() then return true end
	if from and self:isFriend(from) then return false end
	return true
end

sgs.ai_skill_cardchosen.gu_liuli = function(self, who, flags, method)
	for _, c in sgs.qlist(who:getJudgingArea()) do
		if c:isRed() then return c:getEffectiveId() end
	end
	local equips = sgs.QList2Table(who:getEquips())
	self:sortByKeepValue(equips)
	for _, c in ipairs(equips) do
		if c:isRed() then return c:getEffectiveId() end
	end
	return nil
end

-- 密图
sgs.ai_skill_playerschosen.gu_mitu = function(self, targets, max_num, min_num)
	local rival = false
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then rival = true break end
	end
	if not rival then return {} end
	local chosen = {}
	local friends = {}
	for _, p in ipairs(self.friends) do
		if gu07c_contains(targets, p) then table.insert(friends, p) end
	end
	friends = self:sort(friends, "handcard")
	for _, p in ipairs(friends) do
		if #chosen >= max_num then break end
		table.insert(chosen, p)
	end
	return chosen
end

sgs.ai_skill_playerchosen.gu_mitu = function(self, targets)
	local from = gu07c_player(self, self.player:getTag("GuMituFrom"):toString())
	local list = sgs.QList2Table(targets)
	list = self:sort(list, "hp")
	local wantEnemy = not from or self:isFriend(from)
	for _, p in ipairs(list) do
		if wantEnemy and self:isEnemy(p) then return p end
		if not wantEnemy and self:isFriend(p) then return p end
	end
	return list[1]
end

-- A chosen character pindians with the highest of its own shown cards when it can.
local gu07c_askForPindian = SmartAI.askForPindian
function SmartAI:askForPindian(requestor, reason)
	if reason == "gu_mitu" and requestor and requestor:objectName() == self.player:objectName() then
		local best
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if c:hasFlag("gu_mitu_shown") and (not best or c:getNumber() > best:getNumber()) then best = c end
		end
		if best then return best end
	end
	return gu07c_askForPindian(self, requestor, reason)
end

-- 潜流
sgs.ai_skill_choice.gu_qianliu = function(self, choices)
	if choices:match("obtain") then return "obtain" end
	return "cancel"
end
