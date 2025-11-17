--星曹操
sgs.ai_skill_choice["LuaJianxiong"] = function(self, choices, data)
	local obtain = getChoice(choices, "LuaJianxiongobtain")
	local draw = getChoice(choices, "LuaJianxiongdraw")
	local damage = data:toDamage()
	if not damage.card then return draw end
	if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 0 then return draw end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then
		return
			draw
	end
	if damage.card and damage.card:isKindOf("AOE") and obtain then
		return obtain
	end
	if self.player:getLostHp() > 1 then
		return draw
	end
	if obtain then
		return obtain
	end
	return "cancel"
end

sgs.ai_target_revises.LuaJianxiong = function(to, card, self)
	if card:isDamageCard()
		and not self:isFriend(to)
		and card:subcardsLength() > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", sgs.Sanguosha:getCard(id), to)
			then
				return true
			end
		end
	end
end

sgs.ai_can_damagehp.LuaJianxiong = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return (card and (card:isKindOf("Duel") or card:isKindOf("AOE"))) or to:getLostHp() > 2
	end
end

local LuaNengchen_skill = {}
LuaNengchen_skill.name = "LuaNengchen"
table.insert(sgs.ai_skills, LuaNengchen_skill)
LuaNengchen_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("jx") then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex = sgs.Sanguosha:cloneCard(
			sgs.Sanguosha:getCard(self.player:getMark("luanengchenskill")):objectName(), c:getSuit(), c:getNumber())
		cardex:deleteLater()
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not cardex:isKindOf("IronChain") then
			local name = sgs.Sanguosha:getCard(self.player:getMark("luanengchenskill")):objectName()
			local new_card = sgs.Card_Parse((name .. ":LuaNengchen[%s:%s]=%d"):format(c:getSuitString(),
				c:getNumberString(), c:getEffectiveId()))
			assert(new_card)
			return new_card
		end
	end
end

--星郭嘉
sgs.ai_skill_invoke.LuaXinyiji = function(self, data)
	return true
end


sgs.ai_skill_use["@@LuaXinyiji"] = function(self, prompt)
	self:updatePlayers()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local suit = {}
	for _, card_id in sgs.qlist(self.player:getPile("ji")) do
		local card = sgs.Sanguosha:getCard(card_id)
		if not table.contains(suit, card:getSuitString()) then
			table.insert(suit, card:getSuitString())
		end
	end
	for _, c in ipairs(cards) do
		if not table.contains(suit, c:getSuitString()) then
			return ("#LuaXinyiji:%d:"):format(c:getEffectiveId())
		end
	end

	return "."
end

sgs.ai_need_damaged.LuaXinyiji = function(self, attacker, player)
	if not player:hasSkill("LuaXinyiji") then return end

	local friends = {}
	for _, ap in sgs.list(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	self:sort(friends, "hp")

	if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

	return player:getHp() > 2 and sgs.turncount > 2 and not self:isWeak(player) and player:getHandcardNum() >= 2
end

sgs.ai_can_damagehp.LuaXinyiji = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|LuaXinyiji"

sgs.ai_skill_use["@@LuaJuece"] = function(self, prompt)
	local damage = self.player:getTag("LuaJueceDamage"):toDamage()
	self:updatePlayers()
	local cards = {}
	if self.player:getPile("ji"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("ji")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	for _, c in ipairs(cards) do
		if damage.to and self:isFriend(damage.to) and self:doDisCard(damage.from,"he") and self:canDraw(damage.to, self.player) then
			if c:getSuit() == sgs.Card_Club then
				return ("#LuaJuece:%d:"):format(c:getEffectiveId())
			end
		end
		if damage.from and self:isEnemy(damage.from) then
			if self:objectiveLevel(damage.from) > 3 and not self:cantbeHurt(damage.from) and self:damageIsEffective(damage.from) then
				if c:getSuit() == sgs.Card_Heart then
					return ("#LuaJuece:%d:"):format(c:getEffectiveId())
				end
			end
			if self:toTurnOver(damage.from, damage.from:getLostHp() + 1, "LuaJuece") then
				if c:getSuit() == sgs.Card_Diamond then
					return ("#LuaJuece:%d:"):format(c:getEffectiveId())
				end
			end
			if self:isEnemy(damage.from) then
				if self:doDisCard(damage.from,"he", true)  then
					if c:getSuit() == sgs.Card_Spade then
						return ("#LuaJuece:%d:"):format(c:getEffectiveId())
					end
				end
			end
		end
		if damage.to and self:isFriend(damage.to) and self:needToLoseHp(damage.to, self.player) then
			if c:getSuit() == sgs.Card_Heart then
				return ("#LuaJuece:%d:"):format(c:getEffectiveId())
			end
		end
	end

	return "."
end

--星司马懿
sgs.ai_skill_cardask["@LuaGuizha-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end

function sgs.ai_cardneed.LuaGuizha(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.LuaGuizha_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|LuaGuizha"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .."|LuaGuizha"

sgs.ai_skill_invoke.LuaQuanbian = function(self, data)
	local target = data:toPlayer()
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if sgs.ai_need_damaged.LuaQuanbian(self, target) then return true end

	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		return self.player:objectName() == damage.to:objectName() and self:doDisCard(target,"he", true) or self:doDisCard(target,"e", true)
	end
	if self:isEnemy(target) then
		return self.player:objectName() == damage.to:objectName() and self:doDisCard(target,"he", true) or self:doDisCard(target,"e", true)
	end
	return true
end
sgs.ai_skill_cardchosen.LuaQuanbian = function(self, who, flags)
	local suit = sgs.ai_need_damaged.LuaQuanbian(self, who)
	if not suit then return nil end

	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards == 1 and handcards[1]:hasFlag("visible") then table.insert(cards, handcards[1]) end

	for i = 1, #cards, 1 do
		if (cards[i]:getSuit() == suit and suit ~= sgs.Card_Spade) or
			(cards[i]:getSuit() == suit and suit == sgs.Card_Spade and cards[i]:getNumber() >= 2 and cards[i]:getNumber() <= 9) then
			return cards[i]
		end
	end
	return nil
end

sgs.ai_can_damagehp.LuaQuanbian = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount() > 0
	end
end

sgs.ai_need_damaged.LuaQuanbian = function(self, attacker)
	if not self.player:hasSkill("LuaGuizha") then return false end
	local need_retrial = function(player)
		local alive_num = self.room:alivePlayerCount()
		return alive_num + player:getSeat() % alive_num > self.room:getCurrent():getSeat()
			and player:getSeat() < alive_num + self.player:getSeat() % alive_num
	end
	local retrial_card = { ["spade"] = nil, ["heart"] = nil, ["club"] = nil }
	local attacker_card = { ["spade"] = nil, ["heart"] = nil, ["club"] = nil }

	local handcards = sgs.QList2Table(self.player:getHandcards())
	for i = 1, #handcards, 1 do
		if handcards[i]:getSuit() == sgs.Card_Spade and handcards[i]:getNumber() >= 2 and handcards[i]:getNumber() <= 9 then
			retrial_card.spade = true
		end
		if handcards[i]:getSuit() == sgs.Card_Heart then
			retrial_card.heart = true
		end
		if handcards[i]:getSuit() == sgs.Card_Club then
			retrial_card.club = true
		end
	end

	local cards = sgs.QList2Table(attacker:getEquips())
	local handcards = sgs.QList2Table(attacker:getHandcards())
	if #handcards == 1 and handcards[1]:hasFlag("visible") then table.insert(cards, handcards[1]) end

	for i = 1, #cards, 1 do
		if cards[i]:getSuit() == sgs.Card_Spade and cards[i]:getNumber() >= 2 and cards[i]:getNumber() <= 9 then
			attacker_card.spade = sgs.Card_Spade
		end
		if cards[i]:getSuit() == sgs.Card_Heart then
			attacker_card.heart = sgs.Card_Heart
		end
		if cards[i]:getSuit() == sgs.Card_Club then
			attacker_card.club = sgs.Card_Club
		end
	end

	local players = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(players) do
		if player:containsTrick("lightning") and self:getFinalRetrial(player) == 1 and need_retrial(player) then
			if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
		end

		if self:isFriend(player) and not player:containsTrick("YanxiaoCard") and not player:hasSkill("qiaobian") then
			if player:containsTrick("indulgence") and self:getFinalRetrial(player) == 1 and need_retrial(player) and player:getHandcardNum() >= player:getHp() then
				if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
			end

			if player:containsTrick("supply_shortage") and self:getFinalRetrial(player) == 1 and need_retrial(player) and self:hasSkills("yongshi", player) then
				if not retrial_card.club and attacker_card.club then return attacker_card.club end
			end
		end
	end
	return false
end


--星诸葛亮
sgs.ai_view_as.LuaDongcha = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getSuit() == sgs.Card_Spade then
		return ("nullification:LuaDongcha[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.LuaDongcha = function(to, card, self)
	if card:getSuit() == sgs.Card_Spade then
		return card
	end
end

sgs.LuaDongcha_suit_value = {
	spade = 3.9
}

sgs.ai_skill_invoke.LuaNixing = function(self, data)
	return true
end

sgs.ai_use_revises.LuaDongcha = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:getSuit() == sgs.Card_Spade
	then
		same = self:getSameEquip(card)
		if same and same:getSuit() == sgs.Card_Spade
		then
			return false
		end
	end
end


--星赵云
local LuaLongzhen_skill = {}
LuaLongzhen_skill.name = "LuaLongzhen"
table.insert(sgs.ai_skills, LuaLongzhen_skill)
LuaLongzhen_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:LuaLongzhen[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.LuaLongzhen = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip then
		if card:isKindOf("Jink") then
			return ("slash:LuaLongzhen[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:LuaLongzhen[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_use_priority.LuaLongzhen = 9

sgs.LuaLongzhen_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.8,
	FireSlash = 5.7,
	Slash = 5.9,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_skill_invoke["#LuaChongzhen"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and target:getHandcardNum() == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.LuaLongzhen = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("LuaChongzhenTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[3] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and target:getHandcardNum() == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			sgs.updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and target:getHandcardNum() == 1 then intention = 0 end
			sgs.updateIntention(player, target, -intention)
		end
	end
end

sgs.ai_slash_prohibit.LuaLongzhen = function(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasSkill("tieji") or self:canLiegong(to, from) then
		return false
	end
	if to:hasSkill("LuaLongzhen") and to:getHandcardNum() >= 3 and from:getHandcardNum() > 1 then return true end
	return false
end









--星周瑜
sgs.ai_skill_invoke.LuaYingcai = function(self, data)
	return true
end

local LuaFanjian_skill = {}
LuaFanjian_skill.name = "LuaFanjian"
table.insert(sgs.ai_skills, LuaFanjian_skill)
LuaFanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	if self.player:hasUsed("#LuaFanjianCard") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card_str = "#LuaFanjianCard:" .. cards[1]:getId() .. ":"
	assert(card_str ~= nil)
	return sgs.Card_Parse(card_str)
end


sgs.ai_skill_use_func["#LuaFanjianCard"] = function(card, use, self)
	local room = self.player:getRoom()
	card:setSkillName("LuaFanjian")
	self:sort(self.enemies, "defense")
	local target
	local n = 0
	local y = 0
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy) then
			if n <= enemy:getEquips():length() then
				n = enemy:getEquips():length()
				target = enemy
			end
			if (self.player:getHandcardNum() - 1) < (enemy:getHandcardNum() + 1) then
				if y < enemy:getHandcardNum() then
					y = enemy:getHandcardNum()
					target = enemy
					break
				end
			end
		end
	end
	if target then
		if use.to then
			use.to:append(target)
		end
		use.card = card
		return
	end
end

sgs.ai_card_intention["#LuaFanjianCard"] = sgs.ai_card_intention.FanjianCard
sgs.dynamic_value.damage_card["#LuaFanjianCard"] = true


function sgs.ai_skill_suit.LuaFanjian(self)
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	if self.player:hasSkill("hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart else return suit end
end

--星吕布
sgs.ai_view_as.LuaGuishen = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:LuaGuishen[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local LuaGuishen_skill = {}
LuaGuishen_skill.name = "LuaGuishen"
table.insert(sgs.ai_skills, LuaGuishen_skill)
LuaGuishen_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("Slash") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not isCard("Analeptic", card, self.player) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:LuaGuishen[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.LuaGuishen(to, card)
	return to:getHandcardNum() < 3
end

sgs.hit_skill = sgs.hit_skill .."|LuaGuishen"

sgs.ai_skill_invoke["#LuaXDuojian"] = function(self, data)
	return true
end

sgs.ai_skill_invoke.LuaShenyong = function(self, data)
	local effect = data:toCardEffect()
	if effect.to and self:isEnemy(effect.to) and self:doDisCard(effect.to, "he") and self:isTiaoxinTarget(effect.to) then
		return true
	end
end

sgs.ai_skill_invoke.LuaJuejing = function(self, data)
	return true
end


sgs.ai_card_priority.LuaLongzhen_o = function(self, card)
	if card:getSkillName() == "LuaLongzhen_o"
	then
		return 2
	end
end

sgs.ai_skill_invoke.LuaLongzhen_o = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and target:getHandcardNum() == 1)
	end
	return true
end


sgs.ai_choicemade_filter.cardChosen.LuaLongzhen_o = sgs.ai_choicemade_filter.cardChosen.snatch




local LuaLongzhen_o_skill = {}
LuaLongzhen_o_skill.name = "LuaLongzhen_o"
table.insert(sgs.ai_skills, LuaLongzhen_o_skill)
LuaLongzhen_o_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:LuaLongzhen_o[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.LuaLongzhen_o = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isKindOf("Jink") then
			return ("slash:LuaLongzhen_o[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:LuaLongzhen_o[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.LuaLongzhen_o_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}


sgs.ai_skill_invoke.LuaLongwei = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.LuaLongwei = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

sgs.ai_getBestHp_skill.LuaBaonu = function(owner)
	if owner:hasSkills("LuaHuaji+LuaBaonu") and owner:getMark("LuaBaonu") == 0 then
		return owner:getMaxHp() - 1
	end
end

sgs.hit_skill = sgs.hit_skill .. "|os_chitu"

sgs.ai_cardneed.os_chitu = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.LuaHuaji = function(self, data)
	local current = self.room:getCurrent()
	local juece_effect = (current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and self:isEnemy(current) and current:hasSkill("juece"))
	local manjuan_effect = hasManjuanEffect(self.player)
	if self.player:isKongcheng() then
		if manjuan_effect or juece_effect then return false end
	elseif self.player:getHandcardNum() == 1 then
		if manjuan_effect and juece_effect then return false end
	end
	return true
end

sgs.ai_skill_discard.LuaHuaji = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())

	return to_discard
end

sgs.ai_can_damagehp.LuaHuaji = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 1
		and self:canLoseHp(from, card, to)
end

sgs.ai_getBestHp_skill.xingLuashenji = function(owner)
	if owner:hasSkills("LuaHuaji+xingLuashenji") and owner:getMark("xingLuashenji") == 0 then
		return owner:getMaxHp() - 1
	end
end
