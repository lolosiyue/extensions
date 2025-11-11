local efusha_skill = {}
efusha_skill.name = "efusha"
table.insert(sgs.ai_skills, efusha_skill)
efusha_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	if self.player:hasUsed("#efusha") then return nil end
	return sgs.Card_Parse("#efusha:.:")
end

sgs.ai_skill_use_func["#efusha"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)

	self:sort(self.enemies, "hp")

	--if self:getOverflow() <= 0 then return end
	sgs.ai_use_priority["#efusha"] = 0.2


	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[c:getSuitString()] then
			suits[c:getSuitString()] = true
			suits_num = suits_num + 1
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy) and not enemy:hasSkills("qingnang|jijiu|tianxiang") then
			for _, card in ipairs(cards) do
				if self:getUseValue(card) < 6 and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
					use.card = sgs.Card_Parse("#efusha:" .. card:getEffectiveId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention["#efusha"] = 70




sgs.ai_skill_invoke.eweicheng = function(self, data)
	local target = data:toPlayer()
	
	return self:doDisCard(target,"he", false)
end

sgs.ai_choicemade_filter.cardChosen.eweicheng = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_choicemade_filter.skillInvoke.eweicheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .."|eqiehu"

sgs.ai_skill_cardask["@eqiehu1"] = function(self, data, pattern, target)
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	if current and self:isFriend(current) then
		for _, c in ipairs(usable_cards) do
			if c:isKindOf("BasicCard") then
				return c:toString()
			end
		end
	end
	return "."
end


sgs.ai_skill_cardask["@eqiehu2"] = function(self, data, pattern, target)
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	if current and self:isEnemy(current) and self:doDisCard(current, "he") then
		if self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
			for _, c in ipairs(usable_cards) do
				if c:isKindOf("SilverLion") then
					return c:toString()
				end
			end
		end
		if self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() > 0 then
			local equipments = sgs.QList2Table(self.player:getCards("e"))
			self:sortByKeepValue(equipments)
			for _, e in ipairs(equipments) do
				return e:toString()
			end
		end
		for _, c in ipairs(usable_cards) do
			if not c:isKindOf("BasicCard") then
				return c:toString()
			end
		end
	end
	return "."
end


sgs.ai_choicemade_filter.cardResponded["@eqiehu2"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end
sgs.ai_choicemade_filter.cardResponded["@eqiehu1"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, -80)
	end
end

function sgs.ai_cardneed.eqiehu(to, card)
	return to:getCards("h"):length() <= 2
end

sgs.ai_skill_invoke.ehuwu = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		return true
	end
	return self.room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile
end


sgs.ai_skill_choice.ehuwu = function(self, choices, data)
	local use = data:toCardUse()
	local obtain = getChoice(choices, "ehuwu1")
	local draw = getChoice(choices, "ehuwu2")
	if not use.card and self:isFriend(use.from) then return draw end
	if not self:isFriend(use.from) then return obtain end
	if use.card:isKindOf("Slash") and not self:hasCrossbowEffect(use.from) and getCardsNum("Slash", use.from, self.player) == 0 then
		return draw
	end
	if self:isWeak(use.from) and (getCardsNum("Slash", use.from, self.player) or not use.card:isKindOf("Slash") or use.from:getHandcardNum() <= use.from:getHp()) then
		return draw
	end
	if self:willSkipPlayPhase(self.player) or self:getOverflow() > 0 or self:getOverflow(use.from) == 0 then
		return
			obtain
	end
	local items = choices:split("+")
	if obtain then return obtain end
	return items[1]
end

sgs.ai_skill_invoke.echinei = function(self, data)
	return #self.friends_noself > 0
end


sgs.ai_skill_playerchosen.echinei = function(self, targets)
	return self:findPlayerToDraw(false, self.player:getLostHp() + 1)
end

sgs.ai_playerchosen_intention.echinei = -50


sgs.ai_skill_use["@@erangwai"] = function(self, prompt, method)
	local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
	use_card:setSkillName("erangwai")
	use_card:deleteLater()
	local card
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	for _, c in ipairs(hcards) do
		if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
			card = c
			break
		end
	end
	local current = self.room:getCurrent()

	if card and current and #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, use_card) and current:inMyAttackRange(enemy) then
				return "#erangwaiCard:" .. card:getEffectiveId() .. ":" .. "->" .. enemy:objectName()
			end
		end
	end
	return "."
end




local eyanshou_skill = {}
eyanshou_skill.name = "eyanshou"
table.insert(sgs.ai_skills, eyanshou_skill)
eyanshou_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#eyanshouCard") then return nil end
	return sgs.Card_Parse("#eyanshouCard:.:")
end

sgs.ai_skill_use_func["#eyanshouCard"] = function(card, use, self)
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasEquip() and self:doDisCard(enemy, "e") and self:willSkipPlayPhase(enemy) then
			use.card = sgs.Card_Parse("#eyanshouCard:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasEquip() and self:doDisCard(enemy, "e") then
			use.card = sgs.Card_Parse("#eyanshouCard:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend:hasEquip() and self:doDisCard(friend, "e") then
			use.card = sgs.Card_Parse("#eyanshouCard:.:")
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_cardneed.ejisi = sgs.ai_cardneed.bignumber
sgs.ai_cardsview_valuable.ejisi = function(self, class_name, player)
	local usereason = sgs.Sanguosha:getCurrentCardUseReason()
	if usereason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local current = self.room:getCurrent()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local had_card = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf("Nullification") then
			had_card = c
		end
	end

	local pattern = nil
	if class_name == "Nullification" and not player:hasFlag("ejisiUsed") and had_card == nil and current and player:canPindian(current, false) and not self:isFriend(current) then
		pattern = "nullification"
	end
	if pattern then
		local card_str = "#ejisiCard:.:"
		return card_str
	end
end

sgs.ai_skill_invoke.eqiangbian = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return false end
	return true
end

sgs.ai_skill_invoke.eaocai = function(self, data)
	return self.player:getHandcardNum() < 3 or self:isWeak()
end


sgs.ai_skill_invoke.ezhuanquan = function(self, data)
	local target = self.room:getCurrent()
	if self:isEnemy(target) then
		if self:doDisCard(target, "h") then
			return false
		end
	end
	if self:isFriend(target) then
		return self:doDisCard(target, "h")
	end
	return not self:isFriend(target)
end

sgs.ai_choicemade_filter.cardChosen.ezhuanquan = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_invoke.etushou = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.etushou = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	self:sort(targetlist, "hp")
	for _, player in ipairs(targetlist) do
		if self:isFriend(player) and self:canDraw(player, self.player) then
			target = player
			break
		end
	end
	if target then return target end
	for _, player in ipairs(targetlist) do
		if self:isFriend(player) then
			target = player
			break
		end
	end
	if target then return target end
	return targetlist[1]
end

sgs.ai_skill_choice.etushou = function(self, choices, data)
	local items = choices:split("+")

	if table.contains(items, "etushou2") and self:isWeak() then return "etushou2" end
	if table.contains(items, "etushou1") and self.player:getMaxHp() - self.player:getHandcardNum() > 2 then
		local maxHp = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getHp() > maxHp then
				maxHp = p:getHp()
			end
		end
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getHp() == maxHp and not self:isEnemy(p) then
				return "etushou1"
			end
		end
	end
	return "cancel"
end

sgs.ai_ajustdamage_to.etushou = function(self, from, to, card, nature)
	if to:hasFlag("etushou2") then
		return -99
	end
end

sgs.ai_ajustdamage_from.etushou = function(self, from, to, card, nature)
	if from:hasFlag("etushou") then
		return -99
	end
end

local etiaobo_skill = {
	name = "etiaobo",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#etiaoboCard") then return end
		if self.player:isNude() then return end
		local can_use = false
		self:sort(self.enemies, "chaofeng")
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if not self:slashIsEffective(slash, enemy) then continue end
			if enemy:isKongcheng() then continue end
			can_use = true
			break
		end
		if can_use then
			return sgs.Card_Parse("#etiaoboCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, etiaobo_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#etiaoboCard"] = function(card, use, self)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local slasher, target
	self:sort(self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if enemy_b:canSlash(enemy_a) and not self:slashProhibit(slash, enemy_a) and self:getDefenseSlash(enemy_a) <= 2
				and self:slashIsEffective(slash, enemy_a) and self:isGoodTarget(enemy_a, self.enemies, slash) and enemy_b:getHandcardNum() < enemy_a:getHandcardNum() and not enemy_a:isKongcheng() and not enemy_b:isKongcheng() and enemy_a:objectName() ~= self.player:objectName() then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy in ipairs(self.enemies) do
			for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(enemy))) do
				if p:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and p:getHandcardNum() < enemy:getHandcardNum() and enemy:objectName() ~= self.player:objectName() and not p:isKongcheng() and not enemy:isKongcheng() then
					slasher = p
					target = enemy
					break
				end
			end
		end
	end

	if slasher and target then
		local card_str = "#etiaoboCard:.:"
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(slasher)
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["#etiaoboCard"] = 0
sgs.ai_use_value["#etiaoboCard"] = 0
sgs.ai_card_intention["#etiaoboCard"] = 80
