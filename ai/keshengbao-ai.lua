--change

sgs.ai_skill_invoke.shengchangetupo = function(self, data)
	--[[local num = math.random(0,1)
	if (num == 0) then
	    return true
	else
		return false
	end]]
	return false
end

--圣孙权

sgs.ai_skill_invoke.keshengxionglve = function(self, data)
	return true
end

sgs.ai_skill_invoke.keshengganen = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			if self:isWeak(target) then
				return not target:isKongcheng() and self:needKongcheng(target) and self:canDraw(target, self.player)
			elseif self:canDraw(target, self.player) and (self:getOverflow() > 0 or self.player:isSkipped(sgs.Player_Play)) then
				return true
			else
				return math.random() < 0.45 and self:canDraw(target, self.player)
			end
		elseif self:isEnemy(target) then
			if target:isKongcheng() and self:needKongcheng(target) then
				return true
			end
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.keshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if to then
			sgs.updateIntention(player, to, -70)
		end
	end
end


sgs.ai_skill_invoke.kejieshengxionglve = function(self, data)
	return true
end

sgs.ai_skill_invoke.kejieshengganen = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:isWeak(target) then
			return self:canDraw(target, self.player)
		elseif self:canDraw(target, self.player) and (self:getOverflow() > 0 or self.player:isSkipped(sgs.Player_Play)) then
			return true
		elseif self:hasSkills(sgs.cardneed_skill, self.player) then return false
		else
			return math.random() < 0.8 and self:canDraw(target, self.player)
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if to then
			sgs.updateIntention(player, to, -70)
		end
	end
end


sgs.ai_skill_choice.kejieshengganen = function(self, choices, data)
	if self:isWeak() or self.player:getHp() < getBestHp(self.player) then return "huixue" end
	return "mopai"
end

--圣孙策

sgs.ai_skill_cardask["shenghuju-slash"] = function(self, data, pattern, target)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to) then return "." end
	if self:cantDamageMore(effect.from,effect.to) then return "." end
	if self.player:getCardCount() - 2 >= self.player:getHp()
		or self:needKongcheng() and self.player:getHandcardNum() > 0
		or self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(effect.to) == 1
		or effect.to:getHp() <= 2 and not hasBuquEffect(effect.to)
		or self:getOverflow() > 0
	then
		return self:getCardId("Slash")
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|keshenghuju"
sgs.ai_cardneed.keshenghuju = sgs.ai_cardneed.slash

sgs.ai_skill_cardask["jieshenghuju-slash"] = function(self, data, pattern, target)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to) then return "." end
	if self.player:getCardCount() - 2 >= self.player:getHp()
		or self:needKongcheng() and self.player:getHandcardNum() > 0
		or self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(effect.to) == 1
		or effect.to:getHp() <= 2 and not hasBuquEffect(effect.to)
		or self:getOverflow() > 0
	then
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() and c:isKindOf("Slash") and not self:cantDamageMore(effect.from,effect.to) then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isKindOf("Slash") and not self:cantDamageMore(effect.from,effect.to) then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			return c:toString()
		end
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kejieshenghuju"
sgs.ai_cardneed.kejieshenghuju = sgs.ai_cardneed.slash

sgs.ai_skill_cardask["jieshenghujutwo-slash"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	if self:isFriend(use.to:first()) then return "." end
	if self.player:getCardCount() - 2 >= self.player:getHp()
		or self:needKongcheng() and self.player:getHandcardNum() > 0
		or self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(use.to:first()) == 1
		or use.to:first():getHp() <= 2 and not hasBuquEffect(use.to:first())
		or self:getOverflow() > 0
	then
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() and c:isKindOf("Slash") and not self:cantDamageMore(use.from,use.to:first()) then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isKindOf("Slash") and not self:cantDamageMore(use.from,use.to:first()) then return c:toString() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			return c:toString()
		end
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kejieshenghujutwo"
sgs.ai_cardneed.kejieshenghujutwo = sgs.ai_cardneed.slash

--圣甄姬

sgs.ai_skill_invoke.keshengliufeng = function(self, data)
	return true
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|keshengliufeng"

sgs.ai_skill_choice.keshenghuixue = function(self, choices, data)
	if self.keshenghuixueChoice then return self.keshenghuixueChoice end
	return "huixue"
end


sgs.ai_choicemade_filter.skillChoice["keshenghuixue"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("keshenghuixueTarget") then
			if choice == "huixue" then
				sgs.updateIntention(player, p, -80)
			else
				sgs.updateIntention(player, p, 80)
			end
		end
	end
end


local keshenghuixue_skill = {}
keshenghuixue_skill.name = "keshenghuixue"
table.insert(sgs.ai_skills, keshenghuixue_skill)
keshenghuixue_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player, "h") then return end
	if self.player:hasUsed("keshenghuixueCard") then return end
	return sgs.Card_Parse("#keshenghuixueCard:.:")
end

sgs.ai_skill_use_func["#keshenghuixueCard"] = function(card, use, self)
	if not self.player:hasUsed("#keshenghuixueCard") then
		for _, p in ipairs(self.friends_noself) do
			if p:getHp() < getBestHp(p) and p:isMale() and p:canDiscard(p, "h") then
				use.card = sgs.Card_Parse("#keshenghuixueCard:.:")
				self.keshenghuixueChoice = "huixue"
				if use.to then use.to:append(p) end
				return
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
				and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and enemy:canDiscard(enemy, "h")
			then
				self.keshenghuixueChoice = "shanghai"
				use.card = sgs.Card_Parse("#keshenghuixueCard:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keshenghuixueCard = 8.5
sgs.ai_use_priority.keshenghuixueCard = 9.5
--sgs.ai_card_intention.keshenghuixueCard = 80

sgs.ai_skill_invoke.kejieshengliufeng = function(self, data)
	return true
end

sgs.ai_skill_choice.kejieshenghuixue = function(self, choices, data)
	local target = data:toPlayer()
	local damage = getChoice(choices, "shenghuixue_damage")
	local recover = getChoice(choices, "shenghuixue_recover")
	if target and self:isEnemy(target) and damage then
		return damage
	end
	return recover
end

local kejieshenghuixue_skill = {}
kejieshenghuixue_skill.name = "kejieshenghuixue"
table.insert(sgs.ai_skills, kejieshenghuixue_skill)
kejieshenghuixue_skill.getTurnUseCard = function(self)
	if ((self.player:getMark("&useshengshanghai") > 0) and (self.player:getMark("&useshenghuixue") > 0)) then return end
	return sgs.Card_Parse("#kejieshenghuixueCard:.:")
end

sgs.ai_skill_use_func["#kejieshenghuixueCard"] = function(card, use, self)
	if self.player:getMark("&useshengshanghai") == 0 then
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
				and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and enemy:canDiscard(enemy, "h")
			then
				use.card = sgs.Card_Parse("#kejieshenghuixueCard:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if self.player:getMark("&useshenghuixue") == 0 and self.player:canDiscard(self.player, "h") then
		for _, p in ipairs(self.friends_noself) do
			if p:getHp() < getBestHp(p) and p:isMale() and p:canDiscard(p, "h") then
				use.card = sgs.Card_Parse("#kejieshenghuixueCard:.:")
				if use.to then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_use_value.kejieshenghuixueCard = 8.5
sgs.ai_use_priority.kejieshenghuixueCard = 9.5
sgs.ai_card_intention.kejieshenghuixueCard = 80


--圣赵云


local keshengzhuihun_skill = {}
keshengzhuihun_skill.name = "keshengzhuihun"
table.insert(sgs.ai_skills, keshengzhuihun_skill)
keshengzhuihun_skill.getTurnUseCard = function(self)
	if self:needBear() then return nil end
	if self.player:hasUsed("#keshengzhuihunCard") then return nil end
	if self.player:getMark("keshengzhuihun") > 0 then return nil end
	if not self.player:canDiscard(self.player, "h") then return nil end
	if not self:slashIsAvailable(self.player) then return nil end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	self:sort(self.enemies, "hp")
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies, card) and not enemy:isKongcheng() then
					if getCardsNum("Jink", enemy) < 1 or (self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") then
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and self:isGoodTarget(enemy, self.enemies, card) and not enemy:isKongcheng()
					and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy, self.player, 2) and self:ajustDamage(self.player, enemy, 1, card) > 0 then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 then
		local card_id
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			to_throw:append(acard:getEffectiveId())
		end
		card_id = to_throw:first()
		if not card_id then
			return nil
		else
			return sgs.Card_Parse("#keshengzhuihunCard:" .. card_id .. ":")
		end
	end
end

sgs.ai_skill_use_func["#keshengzhuihunCard"] = function(card, use, self)
	use.card = card
end


sgs.ai_ajustdamage_from.keshengzhuihun = function(self, from, to, slash, nature)
	if slash and (slash:isKindOf("Slash") or slash:isKindOf("Duel")) and not to:isKongcheng() then
		return from:getMark("&keshengzhuihun")
	end
end


sgs.ai_use_value.keshengzhuihun = 8.5
sgs.ai_use_priority.keshengzhuihun = 9.5
sgs.ai_card_intention.keshengzhuihun = -80


sgs.ai_skill_invoke.keshengjiuzhu = function(self, data)
	local target = self.room:getCurrentDyingPlayer()
	if target and canNiepan(target) then return false end
	if self.player:getRole() == "loyalist" and self:isWeak(self.room:getLord())
		and target and target:objectName() ~= self.player:objectName() and target:objectName() ~= self.room:getLord():objectName() then
		return false
	end
	return self:isFriend(target)
end


--界圣赵云


local kejieshengzhuihun_skill = {}
kejieshengzhuihun_skill.name = "kejieshengzhuihun"
table.insert(sgs.ai_skills, kejieshengzhuihun_skill)
kejieshengzhuihun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#kejieshengzhuihunCard") then return end
	local has_Crossbow = false
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isKindOf("Crossbow") then
			has_Crossbow = true
		end
	end
	if has_Crossbow or self:hasCrossbowEffect() then
		for _, slash in ipairs(self:getCards("Slash")) do
			local dummy_use = self:aiUseCard(slash)
			if not dummy_use.to:isEmpty() then return end
		end
	end

	return sgs.Card_Parse("#kejieshengzhuihunCard:.:")
	
end

sgs.ai_skill_use_func["#kejieshengzhuihunCard"] = function(card, use, self)
	if not self.player:hasUsed("#kejieshengzhuihunCard") then
		local handcards = sgs.QList2Table(self.player:getCards("he"))
		local discard_cards = {}
		self:sortByUseValue(handcards)
		local equip_check = true
		local basic_check = true
		local trick_check = true
		local should_equip = false
		local slashcount = self:getCardsNum("Slash")
		local dc = dummyCard("slash")
		self.player:setFlags("InfinityAttackRange")
		local d = self:aiUseCard(dc,dummy(true))
		self.player:setFlags("-InfinityAttackRange")
		if d.card then
			for _,p in sgs.qlist(d.to) do
				if not self.player:inMyAttackRange(p) then
					should_equip = true
					break
				end
			end
		end
		for _, c in ipairs(handcards) do
			if not c:isKindOf("Peach")
				and not c:isKindOf("Duel")
				and not c:isKindOf("Indulgence")
				and not c:isKindOf("SupplyShortage")
				and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
				and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
			then
				if equip_check and c:isKindOf("EquipCard") and should_equip and slashcount > 0 then
					equip_check = false
					table.insert(discard_cards, c:getEffectiveId())
				elseif basic_check and c:isKindOf("BasicCard") and slashcount > 0 then
					basic_check = false
					table.insert(discard_cards, c:getEffectiveId())
				elseif trick_check and c:isKindOf("TrickCard") then
					trick_check = false
					table.insert(discard_cards, c:getEffectiveId())
				end
				if #discard_cards == 3 then
					break
				end
			end
		end
		if #discard_cards > 0 then
			local card_str = string.format("#kejieshengzhuihunCard:%s:", table.concat(discard_cards, "+"))
			use.card = sgs.Card_Parse(card_str)
		end
		return
	end
end

function sgs.ai_cardneed.keshengzhuihun(to, card, self)
	if self.player:hasUsed("#kejieshengzhuihunCard") then return false end
	return true
end

sgs.ai_use_value.kejieshengzhuihunCard = 8.5
sgs.ai_use_priority.kejieshengzhuihunCard = 9.5
sgs.ai_card_intention.kejieshengzhuihunCard = -80

sgs.ai_cardneed.kejieshengqinggang = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.kejieshengqinggang = function(self, data)
	local target = data:toPlayer()
	if target then
		return self:doDisCard(target, "he")
	end
	return false
end

sgs.ai_skill_invoke.kejieshengjiuzhu = function(self, data)
	--local target = self.room:getCurrentDyingPlayer()
	local target = data:toPlayer()
	if target and canNiepan(target) then return false end
	if (self.player:getRole() == "loyalist" or self.player:getRole() == "renegade")   and self:isWeak(self.room:getLord())
		and target and target:objectName() ~= self.player:objectName() and target:objectName() ~= self.room:getLord():objectName() then
		return false
	end
	return self:isFriend(target)
end

--圣郭嘉
sgs.ai_skill_invoke.keshengqizuo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getMark("&keshengqizuo") == 0 then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.keshengqizuo = 50

sgs.ai_can_damagehp.keshengqizuo = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end

sgs.ai_skill_invoke.keshengxiangzhi = function(self, data)
	return true
end

--[[sgs.ai_skill_askforyiji.keshengxiangzhi = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end]]
sgs.ai_skill_askforyiji.keshengxiangzhi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then table.insert(available_friends, friend) end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
			keep = true
		else
			table.insert(toGive, card)
		end
		table.insert(allcards, card)
	end

	local cards = #toGive > 0 and toGive or allcards
	self:sortByKeepValue(cards, true)
	local id = cards[1]:getId()

	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and table.contains(available_friends, friend) then return friend, card:getId() end

	if #available_friends > 0 then
		self:sort(available_friends, "handcard")
		for _, afriend in ipairs(available_friends) do
			if not self:needKongcheng(afriend, true) then
				return afriend, id
			end
		end
		self:sort(available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end

--界圣郭嘉

sgs.ai_skill_invoke.kejieshengqizuo = function(self, data)
	return true
end
sgs.ai_skill_playerchosen.kejieshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getMark("&kejieshengqizuo") == 0 then
			return p
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kejieshengqizuo_get = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieshengqizuo = 50

sgs.ai_can_damagehp.kejieshengqizuo = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end

sgs.ai_skill_invoke.kejieshengxiangzhi = function(self, data)
	return true
end

--[[sgs.ai_skill_askforyiji.kejieshengxiangzhi = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end]]
sgs.ai_skill_askforyiji.kejieshengxiangzhi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and not self:isLihunTarget(friend) then
			table.insert(available_friends,
				friend)
		end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
			keep = true
		else
			table.insert(toGive, card)
		end
		table.insert(allcards, card)
	end

	local cards = #toGive > 0 and toGive or allcards
	self:sortByKeepValue(cards, true)
	local id = cards[1]:getId()

	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and table.contains(available_friends, friend) then return friend, card:getId() end

	if #available_friends > 0 then
		self:sort(available_friends, "handcard")
		for _, afriend in ipairs(available_friends) do
			if not self:needKongcheng(afriend, true) then
				return afriend, id
			end
		end
		self:sort(available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end


--程普

sgs.ai_skill_invoke.keshengtonggui = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keshengtonggui = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.keshengtonggui = 50

sgs.ai_skill_invoke.keshengfuchou = function(self, data)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		return true
	else
		return false
	end
end

sgs.ai_choicemade_filter.skillInvoke.keshengfuchou = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current and promptlist[3] == "yes" then
		sgs.updateIntention(player, current, 20)
	end
end

sgs.ai_can_damagehp.keshengfuchou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:getOverflow(from) > 0 and from:getCardCount() > 0
	end
end

sgs.ai_skill_invoke.kejieshengtonggui = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kejieshengtonggui = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieshengtonggui = 50



sgs.ai_skill_invoke.kejieshengfuchou = function(self, data)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		return true
	else
		return false
	end
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengfuchou = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current and promptlist[3] == "yes" then
		sgs.updateIntention(player, current, 20)
	end
end

sgs.ai_can_damagehp.kejieshengfuchou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:getOverflow(from) > 0 and from:getCardCount() > 0
	end
end


--公孙瓒

sgs.ai_skill_invoke.keshengyuma = function(self, data)
	return true
end
function sgs.ai_cardneed.keshengyuma(to, card)
	return card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")
end

sgs.ai_skill_invoke.kejieshengyuma = function(self, data)
	return true
end

function sgs.ai_cardneed.kejieshengyuma(to, card)
	return card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")
end

sgs.ai_skill_invoke.kejieshengliema = function(self, data)
	local mode = self.room:getMode()
	if mode:find("_mini_41") or mode:find("_mini_46") then return true end
	local damage = data:toDamage()
	local target = damage.from
	if target then
		if self:isEnemy(target) and self:doDisCard(target, "he") then
			return true
		elseif self:isFriend(target) and self:doDisCard(target, "he") then
			return true
		end
	end
	return false
end
function sgs.ai_slash_prohibit.kejieshengliema(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if from:getHandcardNum() == 1 and from:getEquips():length() == 0 and from:getHandcards():at(0):isKindOf("Slash") and from:getHp() >= 2 then return false end
	return (from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2) and
		(from:getOffensiveHorse() or from:getDefensiveHorse())
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengliema = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(damage.to, damage.from, 40)
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to, damage.from, -40)
		end
	end
end
