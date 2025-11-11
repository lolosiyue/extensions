sgs.ai_skill_playerchosen.tengxun = function(self, targets)
	local player_table = {}
	local players = sgs.SPlayerList()
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > self.player:getHandcardNum() and self.player:canDiscard(enemy, "h") and self:doDisCard(enemy, "h", false, 2) then
			players:append(enemy)
		end
	end
	local enemies = {}
	if players:isEmpty() then return nil end
	for _, player in sgs.qlist(players) do
		if self:isEnemy(player) then table.insert(enemies, player) end
	end

	self:sort(enemies, "defense")

	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and not enemy:isKongcheng() and  self:doDisCard(enemy, "h", false, 2) then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) and (self.player:canDiscard(enemy, cc:getId())) then
					table.insert(player_table, enemy)
				end
			end
		end
	end

	self:sort(enemies, "handcard")
	for _, enemy in ipairs(enemies) do
		if (self.player:canDiscard(enemy, "h")) and self:doDisCard(enemy, "h", false, 2) then
			table.insert(player_table, enemy)
		end
	end
	if #player_table == 0 then return nil else return player_table[1] end
end

sgs.ai_playerchosen_intention.tengxun = 40

wolfchicheng_skill = {}
wolfchicheng_skill.name = "wolfchicheng"
table.insert(sgs.ai_skills, wolfchicheng_skill)
wolfchicheng_skill.getTurnUseCard = function(self)
	if self.player:getMark("@chicheng") < 1 then return end
	if not self.player:isWounded() then return end
	if (#self.friends <= #self.enemies and sgs.turncount > 2 and self.player:getLostHp() > 0) or (sgs.turncount > 1 and self:isWeak()) or #self.friends > 2 then
		return sgs.Card_Parse("#wolfchichengCard:.:")
	end
end

sgs.ai_skill_use_func["#wolfchichengCard"] = function(card, use, self)
	use.card = card
	local min = math.min(3, #self.friends)
	for i = 1, min - 1 do
		if use.to then use.to:append(self.friends[i]) end
	end
end

sgs.ai_card_intention.wolfchichengCard = -80
sgs.ai_use_priority.wolfchichengCard = 9.31


sgs.ai_skill_invoke.xionglie = function(self, data)
	if self.player:getPile("incantation"):length() > 0 then
		local card = sgs.Sanguosha:getCard(self.player:getPile("incantation"):first())
		if not self.player:getJudgingArea():isEmpty() and not self.player:containsTrick("YanxiaoCard") and not self:hasWizard(self.enemies, true) then
			local trick = self.player:getJudgingArea():last()
			if trick:isKindOf("Indulgence") then
				if card:getSuit() == sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then return false end
			elseif trick:isKindOf("SupplyShortage") then
				if card:getSuit() == sgs.Card_Club then return false end
			end
		end
		local zhangbao = self.room:findPlayerBySkillName("yingbing")
		if zhangbao and self:isEnemy(zhangbao) and not zhangbao:hasSkill("manjuan")
			and (card:isRed() or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade)) then
			return false
		end
	end
	for _, p in ipairs(self.enemies) do
		if self.player:distanceTo(p) == 1 and not p:isKongcheng() then
			return true
		end
	end
	return false
end



sgs.ai_skill_playerchosen.xionglie = function(self, targets)
	local enemies = {}
	local slash = self:getCard("Slash") or sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not target:isKongcheng() then
			table.insert(enemies, target)
		end
	end
	local friends = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and not target:isKongcheng() and self:doDisCard(target, "h", false) then
			table.insert(friends, target)
		end
	end
	if #enemies == 1 then
		return enemies[1]
	else
		self:sort(enemies, "defense")
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkill("qingguo") and self:slashIsEffective(slash, enemy) then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkill("kanpo") then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies) then
				return
					enemy
			end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Peach", true, "h") > 0 or enemy:hasSkill("jijiu") then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) then
				return
					enemy
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkill("longhun") then return enemy end
		end
		return enemies[1]
	end
	if #enemies == 0 then
		return friends:first()
	end
	return targets:first()
end

sgs.hit_skill = sgs.hit_skill .. "|xionglie"

sgs.ai_playerchosen_intention.xionglie = function(self, from, to)
	local intention = 80
	if not self:doDisCard(to, "h", false) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_cardneed.xionglie = sgs.ai_cardneed.slash

sgs.ai_skill_cardask["jieffan"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local c
	local target = data:toDying().who
	local damage = data:toDying().damage
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			c = card
			break
		end
	end
	if c and target then
		if self:isEnemy(target) then
			return "$" .. c:getEffectiveId()
		end
		if self:isFriend(target) and target:getRole() == "rebel" then
			if damage and damage.from and self:isFriend(damage.from) then return "." end
			for _, friend in ipairs(self.friends) do
				if getKnownCard(friend, self.player, "Peach", true, "h") > 0 then return "." end
				if friend:getHandcardNum() > 3 then return "." end
			end
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["jieffan"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local dying = self.room:getCurrentDyingPlayer()
		if not dying then return end
		sgs.updateIntention(player, dying, 80)
	end
end

sgs.ai_cardneed.jieffan = function(to,card, self)
	if not self:willSkipPlayPhase(to) then
		return (card:isKindOf("TrickCard") and getKnownCard(to, "TrickCard", true) == 0)
	end
end
sgs.jieffan_keep_value = sgs.jizhi_keep_value



local tieti_skill = {}
tieti_skill.name = "tieti"
table.insert(sgs.ai_skills, tieti_skill)
tieti_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#tietiCard") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#tietiCard:.:")
end

sgs.ai_skill_use_func["#tietiCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isBlack() and #to_discard < 2 then
			table.insert(to_discard, card:getEffectiveId())
		end
	end
	if #to_discard == 2 then
		self:sort(self.enemies)
		local target
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy)  and self:damageIsEffective(enemy) then
				if self.player:distanceTo(enemy) == 1 then
					target = enemy
					break
				end
			end
		end
		if target then
			local card_str = string.format("#tietiCard:%s:", table.concat(to_discard, "+"))
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_use_value["#tietiCard"] = 2.5
sgs.ai_card_intention["#tietiCard"] = 80
sgs.dynamic_value.damage_card["#tietiCard"] = true


sgs.ai_skill_invoke.duanqiao = function(self, data)
	local target = data:toDamage().from
	if target then
		if self:doDisCard(target, "he", false) then
			return true
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.duanqiao = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and promptlist[3]=="yes" and not self:doDisCard(damage.from,"he") then
		sgs.updateIntention(player,damage.from,10)
	end
end

sgs.ai_cardneed.chenmu = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from.suzhan = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and to:getEquips():isEmpty()
	then
		return 1
	end
end
sgs.ai_cardneed.suzhan = sgs.ai_cardneed.slash

sgs.ai_use_revises.shuiyan = function(self, card, use)
	if card:isKindOf("EquipCard")
	then
		same = self:getSameEquip(card)
		if same and same:getSuit() == card:getSuit()
		then
			return false
		end
	end
end


local shuiyan_skill = {}
shuiyan_skill.name = "shuiyan"
table.insert(sgs.ai_skills, shuiyan_skill)
shuiyan_skill.getTurnUseCard = function(self)
	if self.player:getCards("he"):length() < 3 then return end
	if not self.player:hasUsed("#shuiyanCard") then
		return sgs.Card_Parse("#shuiyanCard:.:")
	end
end

sgs.ai_skill_use_func["#shuiyanCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if #to_discard < 3 then
			if #to_discard > 0 then
				local same = false
				for i = 1, #to_discard, 1 do
					if card:getSuit() == sgs.Sanguosha:getCard(to_discard[i]):getSuit() then
						same = true
						break
					end
				end
				if not same then
					table.insert(to_discard, card:getEffectiveId())
				end
			else
				table.insert(to_discard, card:getEffectiveId())
			end
		end
	end
	if #to_discard == 3 then
		self:sort(self.enemies)

		local players = self.room:getOtherPlayers(self.player)
		if players:isEmpty() then return nil end
		local value_e = 0
		local value_f = 0
		for _, player in sgs.qlist(players) do
			local value = 0
			for _, equip in sgs.qlist(player:getEquips()) do
				if equip:isKindOf("Weapon") then
					value = value + self:evaluateWeapon(equip)
				elseif equip:isKindOf("Armor") then
					value = value + self:evaluateArmor(equip)
					if self:needToThrowArmor() then value = value - 5 end
				elseif equip:isKindOf("OffensiveHorse") then
					value = value + 2.5
				elseif equip:isKindOf("DefensiveHorse") then
					value = value + 5
				end
			end
			if hasZhaxiangEffect(player) then
				value = value + 3
			end
			if self:isEnemy(player) then
				value_e = value_e + value
			elseif self:isFriend(player) then
				value_f = value_f + value
			end
		end
		if value_e > value_f then
			local card_str = string.format("#shuiyanCard:%s:", table.concat(to_discard, "+"))
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			return
		end
	end
end

-- sgs.ai_card_intention.shuiyan = function(self, card, from, tos)
-- 	for _, to in sgs.qlist(self.room:getOtherPlayers(self.player)) do
-- 		if self:needToThrowArmor(to) then
-- 		else
-- 			local intention = 40
-- 			if hasZhaxiangEffect(to) then
-- 				intention = -intention
-- 			end
-- 			sgs.updateIntention(from, to, intention)
-- 		end
-- 	end
-- end

sgs.ai_use_value.shuiyan = 5
sgs.ai_use_priority.shuiyan = 7



sgs.ai_skill_choice.shuiyan = function(self, choices, data)
	local target = data:toPlayer()
	if self:needToLoseHp(self.player, target) or hasZhaxiangEffect(self.player) and self:canDraw() and not self:willSkipPlayPhase() and (self.player:getHp()>0 or hasBuquEffect(self.player) or self:getSaveNum(true)>0) then
		return "be_lost"
	end
	if self:isWeak() and not self:needDeath() then return "throw_equips" end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do
		if equip:isKindOf("Weapon") then
			value = value + self:evaluateWeapon(equip)
		elseif equip:isKindOf("Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5 end
		elseif equip:isKindOf("OffensiveHorse") then
			value = value + 2.5
		elseif equip:isKindOf("DefensiveHorse") then
			value = value + 5
		end
	end
	if value < 8 then return "throw_equips" else return "be_lost" end
end



lalong_skill = {}
lalong_skill.name = "lalong"
table.insert(sgs.ai_skills, lalong_skill)
lalong_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lalongCard") then return end

	local card
	if self:needToThrowArmor() and self.player:getArmor():getSuit() == sgs.Card_Spade then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Spade then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _, ecard in ipairs(ecards) do
			if (ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse")) and ecard:getSuit() == sgs.Card_Spade then
				card = ecard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("#lalongCard:" .. card:getEffectiveId() .. ":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lalongCard"] = function(card, use, self)
	local target
	local friends = self.friends_noself
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	self.lalongTarget = nil

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player, true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
	end

	self:sort(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) and self:canDraw(friend,self.player) then
			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
					and enemy:objectName() ~= self.player:objectName() then
					target = friend
					self.lalongTarget = enemy
					break
				end
			end
		end
		if target then break end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_card_intention.lalongCard = -40

sgs.ai_skill_playerchosen.lalong = function(self, targets)
	if self.lalongTarget then return self.lalongTarget end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.double_slash_skill = sgs.double_slash_skill .."|lalong"

sgs.ai_skill_playerchosen.renzha = function(self, targets)
	if self:isWeak() and (self.player:getJudgingArea():length() == 0) then return nil end
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			if (self.player:getJudgingArea():length() > 0)
				or (self:isWeak(target))
				or (self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() > 0)
				or (self.player:hasSkills(sgs.need_kongcheng) and self.player:getHandcardNum() == 1) then
				return target
			end
		end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.renzha = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_playerchosen_intention.renzha = function(self,from,to)
	if hasManjuanEffect(to) then return end
	local intention = -60
	if self:needKongcheng(to,true) then intention = 10 end
	sgs.updateIntention(from,to,intention)
end

sgs.ai_skill_invoke.shengui = function(self, data)
	local target = data:toPlayer()
	if target then
		if not self:isFriend(target) then
			if self:hasHeavyDamage(self.player, nil, target) and self:canLiegong(target, self.player) then
				if self.player:canDiscard(target, "h") and getCardsNum("Jink", target, self.player) > 1 then
					return false
				end
			end
			return true
		end
	end
	return false
end
sgs.ai_cardneed.shengui = sgs.ai_cardneed.slash

sgs.ai_choicemade_filter.skillInvoke.shengui = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end

sgs.hit_skill = sgs.hit_skill .. "|shengui"

sgs.ai_skill_use["@@sheji"] = function(self, prompt)
	local handcardnum = self.player:getHandcardNum()
	local trash = self:getCard("Disaster") or self:getCard("GodSalvation") or self:getCard("AmazingGrace") or
		self:getCard("Slash") or self:getCard("FireAttack") or self:getCard("Jink") or self:getCard("shuugakulyukou") or
		self:getCard("strike_the_death") or self:getCard("together_go_die") or self:getCard("rotenburo") or
		self:getCard("bunkasai")
	local best_target, target
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_discard = {}
	for _, card in ipairs(cards) do
		table.insert(to_discard, card:getEffectiveId())
	end
	self:sort(self.enemies, "defenseSlash")
	if handcardnum <= 2 and trash and #self.enemies >= 1 then
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash")
			if self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) and self.player:inMyAttackRange(enemy)
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies) then
				if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
					best_target = enemy
					break
				end
				if sgs.getDefense(enemy) < 6 then
					best_target = enemy
					break
				end
			end
			slash:deleteLater()
		end
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash")
			if self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) and self.player:inMyAttackRange(enemy)
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				target = enemy
			end
			slash:deleteLater()
		end
	end
	for _, acard in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
			and not self:needToLoseHp(self.player) then
			return "."
		end
	end
	if best_target then
		return "#shejiCard:" .. table.concat(to_discard, "+") .. ":->" .. best_target:objectName()
	end
	if target then
		return "#shejiCard:" .. table.concat(to_discard, "+") .. ":->" .. target:objectName()
	end
end
