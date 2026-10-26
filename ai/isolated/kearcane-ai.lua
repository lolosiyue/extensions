-- Source: b6025acc ai/kearcane-ai.lua.


local dummy = AIUsePlan.dummy
local function reuse(self,card,request)
 if self:isReadonlyTurnConversion(card)then return card end
 if not card:isStrategySeed()then ai_unsupported("source seed identity unavailable","kearcane.seed")end
 local skill=card:getSourceSkillName()
 local selector="#"..card:objectName()
 return self:inheritLegacyCardIdentity(self:bindSkillCard(skill, {}, request, nil, selector), card)
end
local function response(self,skill,selector,names,request)
 if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
 local u=AIUsePlan.new();u.card=self:bindSkillCard(skill, {}, request, nil, selector);u.to=AIList.new({})
 for _,name in ipairs(names)do u.to:append(self.room:findPlayerByObjectName(name))end;return u:toAnswer()
end
local function role(self,p)
 local value=p:getRole();if value~=nil then return value end
 return self:useKnowledgeEstimate({value=self:getRoleEstimate(p),status="estimate",basis="kearcane.unrevealed_role_viewer_estimate",target=p:objectName()}, "kearcane.role")
end

--金克丝
sgs.ai_skill_playerchosen.kejinxmark = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_playerchosen_intention.kejinxmark = 50

ai_fill_skill.jinxchange=function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jinxchange", "#jinxchangeCard", request)
end

ai_card_use["#jinxchangeCard"] = function(self, card, use, request)
	local slash_num = self:getCardsNum("Slash")
	if slash_num > 1 and self.player:getStrategyMark("@jinxcannon")>0 then
		use.card = reuse(self,card,request)
	elseif slash_num == 1 and self.player:getStrategyMark("@jinxgun")>0 then
		use.card = reuse(self,card,request)
	end
end
sgs.ai_use_priority.jinxchangeCard = 9.5

sgs.ai_skill_playerchosen.kejintuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end
sgs.ai_playerchosen_intention.kejintuo = -50



ai_fill_skill.kefanmao=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("kefanmaoCard") then return end
	return self:legacySkillSeed("kefanmao", "#kefanmaoCard", request)
end

ai_card_use["#kefanmaoCard"] = function(self, card, use, request)
    if (self.player:getStrategyMark("@hexstone")>=2) and not self.player:getStrategyHasUsed("#kefanmaoCard") then
        self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and (self.player:objectName() ~= friend:objectName() ) then
				use.card = reuse(self,card,request)
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_value.kefanmaoCard = 8.5
sgs.ai_use_priority.kefanmaoCard = 9.5
sgs.ai_card_intention.kefanmaoCard = 80

ai_skill_invoke["flydoorswapback-ask"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_invoke.kebengneng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	return (self:doDisCard(target, "h")) or false
end

sgs.ai_ajustdamage_from.kebengneng = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:isRed()
    then
        return 1
    end
end


ai_skill_invoke.kechetan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not self:isFriend(target) and self:doDisCard(target, "h") then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.kechetan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, 50) end
	end
end


sgs.ai_ajustdamage_from.kejingwen = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and (from:getStrategyMark("@kebaotou") > 0)
    then
        return 1
    end
end

--vi

ai_fill_skill.keyuji=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("keyujiCard") then return end
	return self:legacySkillSeed("keyuji", "#keyujiCard", request)
end

ai_card_use["#keyujiCard"] = function(self, card, use, request)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 0 and (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) < (self.player:getHp()+self.player:getHp()+self.player:getHandcardNum()) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and not enemy:getStrategyFlag("yujichosen") and self.player:inMyAttackRange(enemy) then
			use.card = reuse(self,card,request)
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.keyujiCard = 8.5
sgs.ai_use_priority.keyujiCard = 9.5
sgs.ai_card_intention.keyujiCard = 80

ai_skill_invoke.kegonghuan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isFriend(target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.kegonghuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, -80) end
	end
end

ai_skill_choice["hitvi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	local duel=self:evaluateSkillCard("kevioletspace", "duel", {})
	local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return ai_choice_result(("juedou"), options)
	end
	
	return ai_choice_result(("slash"), options)
end

ai_skill_choice.kechupan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = data:toCardUse()
	if use.from then
		if self:isFriend(use.from) and self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player)
			and self:needToLoseHp(use.from, self.player, nil) then
			return ai_choice_result(("damage"), options)
		end
		if self:isEnemy(use.from) and self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player)
			and not self:needToLoseHp(use.from, self.player, nil) and not self:cantbeHurt(use.from) then
			return ai_choice_result(("damage"), options)
		end
	end
	return ai_choice_result(("cancel"), options)
end

ai_skill_invoke.kechupan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.from and self:isFriend(use.from) then
		return (false) or false
	end
	return (true) or false
end

sgs.ai_skill_playerchosen.kechupan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_skill_discard.kesilang = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
end

sgs.ai_skill_playerchosen.kesilang = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end
sgs.ai_playerchosen_intention.kesilang = -50


sgs.ai_ajustdamage_to["@besilanged"] = function(self, from, to, card, nature)
	if not to:hasSkill("kesilang") then
		return to:getStrategyMark("@besilanged")
	end
end


ai_skill_use["@@ketinghu"] = function(self,prompt,request)
	local x = self.player:getMaxHp() - 1
	local targets = {}
	for _,p in ipairs(self.friends) do
		if #targets >= x then
			break
		end
		if p:getStrategyMark("&beketinghu+to+#"..self.player:objectName()) == 0 then table.insert(targets, p:objectName()) end
	end
	if #targets > 0 then
		return response(self,"ketinghu","#ketinghuCard",targets,request)
	end
end

sgs.ai_card_intention.ketinghuCard = -80

ai_skill_choice.vander_choice = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if self.player:getStrategyMark("&usetinghu") > self.player:getHp()+self:getAllPeachNum() then
		return ai_choice_result(("losemaxhp"), options)
	end
	return ai_choice_result((items[math.random(1,#items)]), options)
end
 

ai_skill_invoke.keblood = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.from and use.from:objectName() == self.player:objectName() then
		if self:isFriend(use.to:first()) then
			return (false) or false
		end
	end
	if use.from and use.from:objectName() ~= self.player:objectName() then
		if self:isFriend(use.from) then
			return (false) or false
		end
	end
	return (true) or false
end
ai_skill_invoke.kebloodangry = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.from and use.from:objectName() == self.player:objectName() then
		if self:isFriend(use.to:first()) then
			return (false) or false
		end
	end
	if use.from and use.from:objectName() ~= self.player:objectName() then
		if self:isFriend(use.from) then
			return (false) or false
		end
	end
	return (true) or false
end

local killaround_targets
ai_skill_invoke.killaround = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return ((self.player:getHandcardNum() < 4 or self.player:getLostHp() > 1) and killaround_targets(self, "") ~= ".") or false
end
killaround_targets = function(self,prompt)
	local slash=self:evaluateSkillCard("killaround", "slash", {})
	local dummy_use = self:aiUseCard(slash, dummy(true, self.player:getLostHp() - 1))
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return tos
    end
	return "."
end

ai_skill_use["@@killaround"]=function(self,prompt,request)
 local names=killaround_targets(self,prompt);if names=="."then return "."end
 return response(self,"killaround","#killaroundCard",names,request)
end

sgs.ai_use_revises.killaround = function(self,card,use)
	if card:isKindOf("Slash") and table.contains(self:cardSkillNamesKnowledge(card, "killaround.skill_names"), "killaround") then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end

ai_fill_skill.keduantou_extra=function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("keduantou_extra", "#keduantouCard", request)
end

ai_fill_skill.keduantou=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByUseValue(cards)
	local first_found, second_found = false, false
	local first_card, second_card
	for _, fcard in ipairs(cards) do
		first_card = fcard
		first_found = true
		for _, scard in ipairs(cards) do
			if not AIValue.sameLegacyIdentity(first_card,scard) then
				second_card = scard
				second_found = true
				table.insert(to_discard, fcard:getKnownEffectiveId())
				table.insert(to_discard, scard:getKnownEffectiveId())
				break
			end
		end
		if second_card then break end
	end
	local card_str = string.format("#keduantouCard:%s:", table.concat(to_discard, "+"))
	return self:evaluateTurnSkillCard("keduantou", "#keduantouCard", to_discard, request)
end

ai_card_use["#keduantouCard"] = function(self, card, use, request)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and enemy:getStrategyMark("@shixue") >= 5 and enemy:getHp() + self:getAllPeachNum(enemy) <= 2 and self.player:distanceTo(enemy) <= 1 then
			use.card = reuse(self,card,request)
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and enemy:getHp() + self:getAllPeachNum(enemy) <= 1 and self.player:distanceTo(enemy) <= 1 then
			use.card = reuse(self,card,request)
			if use.to then use.to:append(enemy) end
			return
		end
	end
	if self.player:hasSkill("keduantou_extra") then
		for _,enemy in sgs.list(self.enemies) do
			if self:damageIsEffective(enemy, nil, self.player) and self.player:distanceTo(enemy) <= 1 then
				use.card = reuse(self,card,request)
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keduantouCard = 8.5
sgs.ai_use_priority.keduantouCard = 9.5
sgs.ai_card_intention.keduantouCard = 80

ai_fill_skill.kebeilian=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("kebeilianCard") then return end
	return self:legacySkillSeed("kebeilian", "#kebeilianCard", request)
end

ai_card_use["#kebeilianCard"] = function(self, card, use, request)
	self:sort(self.friends)
	for _, friend in ipairs(self.friends_noself) do
		if self:isFriend(friend) and friend:getStrategyMark("@shixue") > 0 then
			use.card = reuse(self,card,request)
			if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_card_intention.kebeilianCard = -80

--garen
ai_skill_invoke.kezhengyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) and self:isWeak(target) and target:getHp() + self:getAllPeachNum(target) - target:getLostHp() < 1 and not self:cantDamageMore(self.player, target) and self:damageIsEffective(target, sgs.DamageStruct_Thunder, self.player) then
			return (true) or false
		end
	end
	return (false) or false
end

ai_fill_skill.kehaojin=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("kehaojinCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getKnownEffectiveId())
	end
	card_id = to_throw:at(0)--(q(to_throw,"length")-1)
	if not card_id then
		return nil
	else
		return self:evaluateTurnSkillCard("kehaojin", "#kehaojinCard", {card_id}, request)
	end
end

ai_card_use["#kehaojinCard"] = function(self, card, use, request)
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		if slash then
			assert(slash)
			local dummy_use = self:aiUseCard(slash, dummy())
			if dummy_use.card and dummy_use.to then
				if not dummy_use.to:isEmpty() then
					use.card = reuse(self,card,request)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.kehaojinCard = 8.5
sgs.ai_use_priority.kehaojinCard = 3
sgs.ai_card_intention.kehaojinCard = -80

--lux

ai_fill_skill.keguangfu=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("keguangfuCard") then return end
	return self:legacySkillSeed("keguangfu", "#keguangfuCard", request)
end

ai_card_use["#keguangfuCard"] = function(self, card, use, request)
    if not self.player:getStrategyHasUsed("#keguangfuCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		if self.player:hasSkill("kelux_r") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canPindian(enemy, true) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(enemy) then
					use.card = reuse(self,card,request)
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		local max_card = self:getMaxCard()
		local max_point = max_card:getNumber()
		for _,enemy in ipairs(self.enemies) do
			if self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if enemy_max_card and enemy:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
				if max_point>enemy_max_point or max_point>10 then
					use.card = reuse(self,card,request)
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keguangfuCard = 8.5
sgs.ai_use_priority.keguangfuCard = 9.5
sgs.ai_card_intention.keguangfuCard = 80

sgs.ai_skill_playerchosen.kequguang = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_card_intention.kequguang = -80

ai_fill_skill.playmovesoldier=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("playmovesoldierCard") then return end
	return self:legacySkillSeed("playmovesoldier", "#playmovesoldierCard", request)
end

ai_card_use["#playmovesoldierCard"] = function(self, card, use, request)
    if not self.player:getStrategyHasUsed("#playmovesoldierCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if (enemy:getStrategyMark("@sandsoldier") == 0) then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
			    use.card = reuse(self,card,request)
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.playmovesoldierCard = 8.5
sgs.ai_use_priority.playmovesoldierCard = 9.5
sgs.ai_card_intention.playmovesoldierCard = 80


ai_skill_invoke.azirslash = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if (p:getStrategyMark("@sandsoldier") > 0) then
			local dummy_use = self:aiUseCard(use.card, dummy(true, 99, self.room:getOtherPlayers(p)))
			if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(p) then
				return (true) or false
			end
		end
	end
	return (false) or false
end

ai_skill_invoke.playmovesoldier = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.playmovesoldier = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	if self:isWeak() then
		local min = 999
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getHp() < min and not (p:getKnownGeneralName() == "kesolardisk" or p:getGeneral2Name() == "kesolardisk") then
				min = p:getHp()
			end
		end
		if self.player:getHp() <= min then
			return self.player
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return self.player
end


sgs.ai_event_callback[sgs.CardFinished].azirshenjiCard = function(self, player, data)
 local use=data:toCardUse()
 if use.card and use.card:objectName()=="azirshenjiCard" then
  local room=player:getRoom()
  -- The witness is the public board: each head general must be disclosed, and
  -- the solar disk's role revealed.
  for _,sb in sgs.qlist(room:getOtherPlayers(player))do
   local name=sb:getGeneralName()
   if sb:objectName()~=self.player:objectName() and (type(name)~="string" or name=="" or name=="anjiang")then
    ai_unsupported("Source-ordered public head witness unavailable","kearcane.azirshenji.head")
   end
   if name=="kesolardisk" then
    local role=sb:hasShownRole() and sb:getKnownRole()
    if not ({lord=true,loyalist=true,rebel=true,renegade=true})[role]then
     ai_unsupported("Solar disk role has not been publicly revealed","kearcane.azirshenji.role")
    end
    self:emitStrategyEffect({kind="azirshenji_role",player=sb:objectName(),role=role})
   end
  end
 end
end

ai_fill_skill.azirshenji=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("@azirshenji") == 0 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((role(self,p) == self.player:getKnownRole())
		 or (role(self,p) == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getKnownGeneralName())
		end
	end
	if #deathplayer==0 then return end
	return self:legacySkillSeed("azirshenji", "#azirshenjiCard", request)
end

ai_card_use["#azirshenjiCard"] = function(self, card, use, request)
	use.card = reuse(self,card,request)
end

sgs.ai_use_value["#azirshenjiCard"] = 8
sgs.ai_use_priority["#azirshenjiCard"] = 9.5



ai_skill_choice["shenji-ask"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	table.removeOne(items, "cancel")
	return ai_choice_result((items[math.random(1,#items)]), options)
end
