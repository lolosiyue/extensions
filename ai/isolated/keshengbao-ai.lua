-- Source: b6025acc ai/keshengbao-ai.lua.


local dummy = AIUsePlan.dummy
local function sole_slash(self,player)
 if player==self.player then return (player:getHandcards():at(0)):isKindOf("Slash")end
 local known=player:getKnownCards()
 if #known==1 then return known[1]:isKindOf("Slash")end
 return self:useKnowledgeEstimate({status="estimate",value=false,basis="keshengbao.liema_unobserved_single_hand_slash_inactive_prior",target=player:objectName()}, "keshengbao.liema.single_slash")
end
local function current_damage(self)
 -- Room tag CurrentDamageStruct: a question's decision context carries it while the tag
 -- holds one (absent reads as the donor's empty struct); event callbacks get no context.
 if self.request.kind=="event"then ai_unsupported("CurrentDamageStruct is not projected to event callbacks","keshengbao.current_damage")end
 local d=self:getDecisionContext().damage
 if d==nil then return{}end
 return{from=d.from,to=d.to,damage=d.amount,card=d.card,nature=d.nature}
end
--change

ai_skill_invoke.shengchangetupo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (false) or false
end

--圣孙权

ai_skill_invoke.keshengxionglve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_getBestHp_skill.keshengxionglve = function(owner)
	return owner:getMaxHp() - 1
end

ai_skill_invoke.keshengganen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			if self:isWeak(target) then
				return (not target:isKongcheng() and self:needKongcheng(target) and self:canDraw(target, self.player)) or false
			elseif self:canDraw(target, self.player) and (self:getOverflow() > 0 or self.player:isSkipped(sgs.Player_Play)) then
				return (true) or false
			else
				return (math.random() < 0.45 and self:canDraw(target, self.player)) or false
			end
		elseif self:isEnemy(target) then
			if target:isKongcheng() and self:needKongcheng(target) then
				return (true) or false
			end
		end
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.keshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if to then
			self:updateIntention(player, to, -70)
		end
	end
end


ai_skill_invoke.kejieshengxionglve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_getBestHp_skill.kejieshengxionglve = function(owner)
	return owner:getMaxHp() - 1
end

ai_skill_invoke.kejieshengganen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:isWeak(target) then
			return (self:canDraw(target, self.player)) or false
		elseif self:canDraw(target, self.player) and (self:getOverflow() > 0 or self.player:isSkipped(sgs.Player_Play)) then
			return (true) or false
		elseif self:hasSkills(sgs.cardneed_skill, self.player) then return (false) or false
		else
			return (math.random() < 0.8 and self:canDraw(target, self.player)) or false
		end
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if to then
			self:updateIntention(player, to, -70)
		end
	end
end


ai_skill_choice.kejieshengganen = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self:isWeak() or self.player:getHp() < getBestHp(self.player) then return ai_choice_result(("huixue"), options) end
	return ai_choice_result(("mopai"), options)
end

--圣孙策

sgs.ai_skill_cardask["shenghuju-slash"] = function(self, data, pattern, target)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to) then return "." end
	if self:cantDamageMore(effect.from, effect.to) then return "." end
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
			if c:isRed() and c:isKindOf("Slash") and not self:cantDamageMore(effect.from, effect.to) then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isKindOf("Slash") and not self:cantDamageMore(effect.from, effect.to) then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			return c:getKnownEffectiveId()
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
			if c:isRed() and c:isKindOf("Slash") and not self:cantDamageMore(use.from, use.to:first()) then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isRed() then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			if c:isKindOf("Slash") and not self:cantDamageMore(use.from, use.to:first()) then return c:getKnownEffectiveId() end
		end
		for _, c in sgs.list(self.player:getHandcards()) do
			return c:getKnownEffectiveId()
		end
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kejieshenghujutwo"
sgs.ai_cardneed.kejieshenghujutwo = sgs.ai_cardneed.slash

--圣甄姬

ai_skill_invoke.keshengliufeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|keshengliufeng"

sgs.ai_hasTuntianEffect_skill.keshengliufeng = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

ai_skill_choice.keshenghuixue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local choice=self:getStrategyMemory("keshengbao.huixue_choice");if choice then return ai_choice_result((choice), options) end
	return ai_choice_result(("huixue"), options)
end


sgs.ai_choicemade_filter.skillChoice["keshenghuixue"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getStrategyFlag("keshenghuixueTarget") then
			if choice == "huixue" then
				self:updateIntention(player, p, -80)
			else
				self:updateIntention(player, p, 80)
			end
		end
	end
end


ai_fill_skill.keshenghuixue=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:canDiscard(self.player, "h") then return end
	if self.player:getStrategyHasUsed("keshenghuixueCard") then return end
	return self:legacySkillSeed("keshenghuixue", "#keshenghuixueCard", request)
end

ai_card_use["#keshenghuixueCard"] = function(self, card, use, request)
	if not self.player:getStrategyHasUsed("#keshenghuixueCard") then
		for _, p in ipairs(self.friends_noself) do
			if p:getHp() < getBestHp(p) and p:isMale() and p:canDiscard(p, "h") then
				use.card=self:bindSkillCard("keshenghuixue", {}, request, nil, "#keshenghuixueCard")
				self:setStrategyMemory("keshengbao.huixue_choice", "huixue")
				if use.to then use.to:append(p) end
				return
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
				and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and enemy:canDiscard(enemy, "h")
			then
				self:setStrategyMemory("keshengbao.huixue_choice", "shanghai")
				use.card=self:bindSkillCard("keshenghuixue", {}, request, nil, "#keshenghuixueCard")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keshenghuixueCard = 8.5
sgs.ai_use_priority.keshenghuixueCard = 9.5

ai_skill_invoke.kejieshengliufeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_hasTuntianEffect_skill.kejieshengliufeng = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

ai_skill_choice.kejieshenghuixue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local damage = getChoice(choices, "shenghuixue_damage")
	local recover = getChoice(choices, "shenghuixue_recover")
	if target and self:isEnemy(target) and damage then
		return ai_choice_result((damage), options)
	end
	return ai_choice_result((recover), options)
end

ai_fill_skill.kejieshenghuixue=function(self, options, request)
    local inclusive = options and options.inclusive

	if ((self.player:getStrategyMark("&useshengshanghai") > 0) and (self.player:getStrategyMark("&useshenghuixue") > 0)) then return end
	return self:legacySkillSeed("kejieshenghuixue", "#kejieshenghuixueCard", request)
end

ai_card_use["#kejieshenghuixueCard"] = function(self, card, use, request)
	if self.player:getStrategyMark("&useshengshanghai") == 0 then
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
				and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and enemy:canDiscard(enemy, "h")
			then
				use.card=self:bindSkillCard("kejieshenghuixue", {}, request, nil, "#kejieshenghuixueCard")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if self.player:getStrategyMark("&useshenghuixue") == 0 and self.player:canDiscard(self.player, "h") then
		for _, p in ipairs(self.friends_noself) do
			if p:getHp() < getBestHp(p) and p:isMale() and p:canDiscard(p, "h") then
				use.card=self:bindSkillCard("kejieshenghuixue", {}, request, nil, "#kejieshenghuixueCard")
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


ai_fill_skill.keshengzhuihun=function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return nil end
	if self.player:getStrategyHasUsed("#keshengzhuihunCard") then return nil end
	if self.player:getStrategyMark("keshengzhuihun") > 0 then return nil end
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
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			to_throw:append(acard:getKnownEffectiveId())
		end
		card_id = to_throw:first()
		if not card_id then
			return nil
		else
			return self:evaluateTurnSkillCard("keshengzhuihun", "#keshengzhuihunCard", {card_id}, request)
		end
	end
end

ai_card_use["#keshengzhuihunCard"] = function(self, card, use, request)
	use.card = card
end


sgs.ai_ajustdamage_from.keshengzhuihun = function(self, from, to, slash, nature)
	if slash and (slash:isKindOf("Slash") or slash:isKindOf("Duel")) and not to:isKongcheng() then
		return from:getStrategyMark("&keshengzhuihun")
	end
end


sgs.ai_use_value.keshengzhuihun = 8.5
sgs.ai_use_priority.keshengzhuihun = 9.5
sgs.ai_card_intention.keshengzhuihun = -80


ai_skill_invoke.keshengjiuzhu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:getCurrentDyingPlayer()
	if target and self:canNiepan(target) then return (false) or false end
	if self.player:getKnownRole() == "loyalist" and self:isWeak(self.room:getLord())
		and target and target:objectName() ~= self.player:objectName() and target:objectName() ~= self.room:getLord():objectName() then
		return (false) or false
	end
	return (self:isFriend(target)) or false
end


--界圣赵云


ai_fill_skill.kejieshengzhuihun=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#kejieshengzhuihunCard") then return end
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

	return self:legacySkillSeed("kejieshengzhuihun", "#kejieshengzhuihunCard", request)
	
end

ai_card_use["#kejieshengzhuihunCard"] = function(self, card, use, request)
	if not self.player:getStrategyHasUsed("#kejieshengzhuihunCard") then
		local handcards = sgs.QList2Table(self.player:getCards("he"))
		local discard_cards = {}
		self:sortByUseValue(handcards)
		local equip_check = true
		local basic_check = true
		local trick_check = true
		local should_equip = false
		local slashcount = self:getCardsNum("Slash")
		local dc=self:cloneEvaluationCard("slash") -- donor dummyCard: NoSuit/0, empty skill and costs
		local d = self:withOwnerRange("InfinityAttackRange", "kejieshengzhuihun", function()
			return self:aiUseCard(dc, dummy(true))
		end)
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
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif basic_check and c:isKindOf("BasicCard") and slashcount > 0 then
					basic_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif trick_check and c:isKindOf("TrickCard") then
					trick_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				end
				if #discard_cards == 3 then
					break
				end
			end
		end
		if #discard_cards > 0 then
			local card_str = string.format("#kejieshengzhuihunCard:%s:", table.concat(discard_cards, "+"))
			use.card=self:bindSkillCard("kejieshengzhuihun", discard_cards, request, nil, "#kejieshengzhuihunCard")
		end
		return
	end
end

function sgs.ai_cardneed.keshengzhuihun(to, card, self)
	if self.player:getStrategyHasUsed("#kejieshengzhuihunCard") then return false end
	return true
end

sgs.ai_use_value.kejieshengzhuihunCard = 8.5
sgs.ai_use_priority.kejieshengzhuihunCard = 9.5
sgs.ai_card_intention.kejieshengzhuihunCard = -80

sgs.ai_cardneed.kejieshengqinggang = sgs.ai_cardneed.slash

ai_skill_invoke.kejieshengqinggang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:doDisCard(target, "he")) or false
	end
	return (false) or false
end

ai_skill_invoke.kejieshengjiuzhu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:canNiepan(target) then return (false) or false end
	if (self.player:getKnownRole() == "loyalist" or self.player:getKnownRole() == "renegade")   and self:isWeak(self.room:getLord())
		and target and target:objectName() ~= self.player:objectName() and target:objectName() ~= self.room:getLord():objectName() then
		return (false) or false
	end
	return (self:isFriend(target)) or false
end

--圣郭嘉
ai_skill_invoke.keshengqizuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.keshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getStrategyMark("&keshengqizuo") == 0 then
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

ai_skill_invoke.keshengxiangzhi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_askforyiji.keshengxiangzhi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then table.insert(available_friends, friend) end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = self:getKnownCardById(id)
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
	if card and friend and table.contains(available_friends, friend) then return friend, card:getKnownId() end

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

ai_skill_invoke.kejieshengqizuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
sgs.ai_skill_playerchosen.kejieshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getStrategyMark("&kejieshengqizuo") == 0 then
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

ai_skill_invoke.kejieshengxiangzhi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

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
		local card = self:getKnownCardById(id)
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
	if card and friend and table.contains(available_friends, friend) then return friend, card:getKnownId() end

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

ai_skill_invoke.keshengtonggui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
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

ai_skill_invoke.keshengfuchou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		return (true) or false
	else
		return (false) or false
	end
	return false

end

sgs.ai_choicemade_filter.skillInvoke.keshengfuchou = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current and promptlist[3] == "yes" then
		self:updateIntention(player, current, 20)
	end
end

sgs.ai_can_damagehp.keshengfuchou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:getOverflow(from) > 0 and from:getCardCount() > 0
	end
end

ai_skill_invoke.kejieshengtonggui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
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



ai_skill_invoke.kejieshengfuchou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		return (true) or false
	else
		return (false) or false
	end
	return false

end

sgs.ai_choicemade_filter.skillInvoke.kejieshengfuchou = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current and promptlist[3] == "yes" then
		self:updateIntention(player, current, 20)
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

ai_skill_invoke.keshengyuma = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
function sgs.ai_cardneed.keshengyuma(to, card)
	return card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")
end

ai_skill_invoke.kejieshengyuma = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

function sgs.ai_cardneed.kejieshengyuma(to, card)
	return card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")
end

ai_skill_invoke.kejieshengliema = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local mode = self.room:getMode()
	if mode:find("_mini_41") or mode:find("_mini_46") then return (true) or false end
	local damage = data:toDamage()
	local target = damage.from
	if target then
		if self:isEnemy(target) and self:doDisCard(target, "he") then
			return (true) or false
		elseif self:isFriend(target) and self:doDisCard(target, "he") then
			return (true) or false
		end
	end
	return (false) or false
end
function sgs.ai_slash_prohibit.kejieshengliema(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:getStrategyFlag("NosJiefanUsed") then return false end
	if from:getHandcardNum() == 1 and from:getEquips():length() == 0 and sole_slash(self,from) and from:getHp() >= 2 then return false end
	return (from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2) and
		(from:getOffensiveHorse() or from:getDefensiveHorse())
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengliema = function(self, player, promptlist)
	local damage = current_damage(self)
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(damage.to, damage.from, 40)
		elseif self:canAttack(damage.from) then
			self:updateIntention(damage.to, damage.from, -40)
		end
	end
end
