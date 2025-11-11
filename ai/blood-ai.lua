sgs.ai_skill_invoke["blood_gudan"] = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()

	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end


sgs.ai_need_damaged.blood_gudan = function(self, attacker, player)
	if player:hasSkill("blood_gudan") and (player:getMark("gudan") == 0) and (self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < 1)
		and (player:getHp() == 1) and not (player:getCardCount(true) > 4) then
		return true
	end
	return false
end


local blood_hj_skill = {}
blood_hj_skill.name = "blood_hj"
table.insert(sgs.ai_skills, blood_hj_skill)
blood_hj_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#blood_hj") then return end
	return sgs.Card_Parse("#blood_hj:.:")
end

sgs.ai_skill_use_func["#blood_hj"] = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	local max_point = max_card:getNumber()

	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	local duel = sgs.Sanguosha:cloneCard("Duel")
	duel:deleteLater()
	self:useCardDuel(duel, dummy_use)
	self:sort(self.enemies, "defense")
	local target
	if dummy_use.card and dummy_use.to then
		for _, enemy in sgs.list(dummy_use.to) do
			if not enemy:isKongcheng() and not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if ((max_point > enemy_max_point) or (max_point > 9)) and self:getCardsNum("Slash") >= getCardsNum("Slash", enemy, self.player) then
					target = enemy
					break
				end
			end
		end
	end
	if target and dummy_use.card then
		use.card = sgs.Card_Parse("#blood_hj:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["#blood_hj"] = sgs.ai_use_priority.XiechanCard
sgs.ai_use_value["#blood_hj"] = sgs.ai_use_value.XiechanCard
sgs.ai_card_intention["#blood_hj"] = sgs.ai_card_intention.XiechanCard

function sgs.ai_skill_pindian.blood_hj(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_cardneed.blood_hj = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	end
end


sgs.ai_need_damaged.blood_hunzi = function(self, attacker, player)
	if player:hasSkill("blood_hunzi") and player:getMark("blood_hunzi") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < 1
		and (player:getHp() == 1) and not (player:getCardCount(true) > 3) then
		return true
	end
	return false
end


sgs.ai_suit_priority.luaangyang = function(self, card)
	return (card:isKindOf("Slash") or card:isKindOf("Duel")) and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end

sgs.ai_cardneed.luaangyang = function(to, card, self)
	return isCard("Duel", card, to) or (isCard("Slash", card, to) and card:isRed())
end


sgs.ai_skill_playerchosen.luaangyang = function(self, targets)
	return self:findPlayerToDraw(true, 1)
end

sgs.ai_playerchosen_intention.luaangyang = -60


--[[
sgs.ai_skill_choice.changeToWu = function(self,choices)
	return "yes"
end]]
sgs.ai_skill_choice["changeToWu"] = function(self, choices, data)
	local items = choices:split("+")

	return items[math.random(1, #items)]
end


sgs.ai_skill_use["@@luaxiongfeng"] = function(self, prompt)
	local x = self.player:getMark("luaxiongfeng")
	local n = x - 1
	self:updatePlayers()
	local selectset = {}
	if x == 1 and #self.friends == 1 then
		self.luaxiongfengchoice = "d1tx"
		return ("#luaxiongfeng:.:->%s"):format(self.player:objectName())
	end
	self.yinghun = nil
	local player = self:AssistTarget()
	if x == 1 then
		self:sort(self.friends, "chaofeng")
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
				and not hasManjuanEffect(friend) then
				self.yinghun = friend
				break
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.friends_noself) do
				if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if self:needToThrowArmor(friend) and not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			for _, enemy in ipairs(self.enemies) do
				if hasManjuanEffect(enemy) then
					self.luaxiongfengchoice = "d1tx"
					return ("#luaxiongfeng:.:->%s"):format(enemy:objectName())
				end
			end
		end
		if not self.yinghun and self.player and not hasManjuanEffect(self.player) and self.player:getCardCount(true) > 0 and not self:needKongcheng(self.player, true) then
			self.yinghun = self.player
		end

		if not self.yinghun and player and not hasManjuanEffect(player) and player:getCardCount(true) > 0 and not self:needKongcheng(player, true) then
			self.yinghun = player
		end

		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if friend:getCards("he"):length() > 0 and not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end

		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			self.yinghun = self:findPlayerToDraw(false, n)
		end
		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if self.yinghun then
			self.luaxiongfengchoice = "dxt1"
			return ("#luaxiongfeng:.:->%s"):format(self.yinghun:objectName())
		end
	end
	if x == 0 then
		self:sort(self.friends, "handcard")
		self:sort(self.enemies, "chaofeng")
		self.friends = sgs.reverse(self.friends)
		if not self.yinghun and not self:isWeak() then
			for _, enemy in ipairs(self.enemies) do
				if self:isWeak(enemy) and not enemy:isNude() then
					self.luaxiongfengchoice = "dxt1"
					return ("#luaxiongfeng:.:->%s"):format(enemy:objectName())
				end
			end
		end
		if not self.yinghun and self.player and not hasManjuanEffect(self.player) and self.player:getCardCount(true) > 0 and not self:needKongcheng(self.player, true) then
			self.yinghun = self.player
		end

		if not self.yinghun and player and not hasManjuanEffect(player) and player:getCardCount(true) > 0 and not self:needKongcheng(player, true) then
			self.yinghun = player
		end

		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			self.yinghun = self:findPlayerToDraw(false, n)
		end
		if not self.yinghun then
			for _, friend in ipairs(self.friends) do
				if not hasManjuanEffect(friend) then
					self.yinghun = friend
					break
				end
			end
		end
		if self.yinghun then
			self.luaxiongfengchoice = "d1tx"
			return ("#luaxiongfeng:.:->%s"):format(self.yinghun:objectName())
		end
	end
	if x > 1 then
		if not self:getCard("Peach") and self:isWeak() and x > 2 then return "." end
		if #self.friends >= x then
			self:sort(self.friends, "chaofeng")
			self.luaxiongfengchoice = "dxt1"
			for _, friend in ipairs(self.friends) do
				if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
					and not hasManjuanEffect(friend) and not table.contains(selectset, friend:objectName()) then
					table.insert(selectset, friend:objectName())
					if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
				end
			end
			if #selectset < x and self.player and not hasManjuanEffect(self.player) and not self:needKongcheng(self.player, true)
				and not table.contains(selectset, self.player:objectName()) then
				table.insert(selectset, self.player:objectName())
				if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
			end
			if #selectset < x then
				for _, friend in ipairs(self.friends_noself) do
					if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and not table.contains(selectset, friend:objectName()) then
						table.insert(selectset, friend:objectName())
						if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
					end
				end
			end
			if #selectset < x then
				for _, friend in ipairs(self.friends) do
					if self:needToThrowArmor(friend) and not hasManjuanEffect(friend) and not table.contains(selectset, friend:objectName()) then
						table.insert(selectset, friend:objectName())
						if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
					end
				end
			end
			if #selectset < x and player and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
				and not table.contains(selectset, player:objectName()) then
				table.insert(selectset, player:objectName())
				if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
			end

			local todraw = self:findPlayerToDraw(false, n)
			if #selectset < x and not table.contains(selectset, todraw:objectName()) then
				table.insert(selectset, todraw:objectName())
				if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
			end
			if #selectset < x then
				for _, friend in ipairs(self.friends) do
					if not hasManjuanEffect(friend) and not table.contains(selectset, friend:objectName()) then
						table.insert(selectset, friend:objectName())
						if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
					end
				end
			end
		end
		if #self.enemies >= x then
			self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if enemy:getCards("he"):length() >= n
					and self:doDisCard(enemy, "he", false, n) and not table.contains(selectset, enemy:objectName()) then
					self.luaxiongfengchoice = "d1tx"
					table.insert(selectset, enemy:objectName())
					if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
				end
			end
			self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not table.contains(selectset, enemy:objectName())
					and not hasTuntianEffect(enemy, true) then
					self.luaxiongfengchoice = "d1tx"
					table.insert(selectset, enemy:objectName())
					if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not table.contains(selectset, enemy:objectName())
					and not (hasTuntianEffect(enemy, true) and x < 3 and enemy:getCards("he"):length() < 2) then
					self.luaxiongfengchoice = "d1tx"
					table.insert(selectset, enemy:objectName())
					if #selectset == x then return ("#luaxiongfeng:.:->%s"):format(table.concat(selectset, "+")) end
				end
			end
		end
	end
	self.luaxiongfengchoice = "dxt1"
	return ("#luaxiongfeng:.:->%s"):format(self.player:objectName())
end



sgs.ai_skill_choice.luaxiongfeng = function(self, choices)
	return self.luaxiongfengchoice
end


sgs.ai_skill_invoke.luajuying = function(self, data)
	if sgs.turncount > 1 then
		return true
	end
end
