-- Assassins fixed b6025acc, full source policy with value-only dependencies.
local known = AIValue.requireKnown

local function reverse(t)local result={}for i=#t,1,-1 do result[#result+1]=t[i]end;return result end
local function response_answer(self,card,options)
    if not card then return {kind="pass"} end
    if AIValue.isCard(card) and card:isEvaluationOnly() then
        local materializer
        if self._response_selected_specs and self._response_selected_specs[card] then
            materializer=self.materializeResponseSelectedCard
        elseif self._original_selected_specs and self._original_selected_specs[card] then
            materializer=self.materializeOriginalSelectedCard
        end
        if type(materializer)~="function" then
            ai_unsupported("Mixin selected hypothesis has no source mapping","mixin.response")
        end
        card=known(materializer(self,card),"mixin.response")
        if not AIValue.isConversion(card) then
            ai_unsupported("Mixin selected hypothesis has no receipt","mixin.response")
        end
    end
    if AIValue.isConversion(card) then return {kind="answer",card_spec=card:toCardSpec()} end
    local id=card:getKnownEffectiveId()
    for _,allowed in ipairs(options and options.card_ids or{})do if id==allowed then return id end end
    return {kind="pass"}
end
sgs.ai_skill_invoke.moukui = function(self,data)
	local target = data:toPlayer()
	self:setStrategyMemory("moukui_target",target:objectName())
	if self:isFriend(target) then return self:needToThrowArmor(target) else return true end
end

sgs.ai_skill_choice.moukui = function(self,choices,data)
	local target = known(self.room:findPlayerByObjectName(known(self:getStrategyMemory("moukui_target"),"Moukui saved target")),"Moukui target")
	if self:doDisCard(target) then
		return "discard"
	end
	return "draw"
end

sgs.ai_skill_invoke.tianming = function(self,data)
	self:setStrategyMemory("tianming_discard",nil)
	if hasManjuanEffect(self.player) then return false end
	if self.player:isNude() then return true end
	if not self:canHit() and self.player:getCardCount(true)<3 then return false end
	if self:canHit() then return true end
	local unpreferedCards = {}
	local cards = self:addHandPile()

	cards = self:sortByKeepValue(cards)
	if self:isWeak() then
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then table.insert(unpreferedCards,card:getKnownId()) end
		end
	else
		if self:getCardsNum("Slash")>1 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Slash") then table.insert(unpreferedCards,card:getKnownId()) end
			end
			table.remove(unpreferedCards,1)
		end
	end

	local num = self:getCardsNum("Jink")-1
	if self.player:getArmor() then num = num+1 end
	if num>0 then
		for _,card in ipairs(cards)do
			if card:isKindOf("Jink") and num>0 then
				table.insert(unpreferedCards,card:getKnownId())
				num = num-1
			end
		end
	end

	for _,card in ipairs(cards)do
		if (card:isKindOf("Weapon") and self.player:getHandcardNum()<3) or card:isKindOf("OffensiveHorse")
			or self:getSameEquip(card,self.player) or card:isKindOf("AmazingGrace") or card:isKindOf("Lightning") then
			table.insert(unpreferedCards,card:getKnownId())
		end
	end

	if self.player:getWeapon() and self.player:getHandcardNum()<3 then
		table.insert(unpreferedCards,self.player:getWeapon():getId())
	end

	if self:needToThrowArmor() then
		table.insert(unpreferedCards,self.player:getArmor():getId())
	end

	if self.player:getOffensiveHorse() and self.player:getWeapon() then
		table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
	end

	local use_cards = {}
	for index = #unpreferedCards,1,-1 do
		if not self.player:isJilei(known(self:getKnownCardById(unpreferedCards[index]),"Tianming cost")) then table.insert(use_cards,unpreferedCards[index]) end
	end

	if #use_cards>=2 or #use_cards==#cards then
		self:setStrategyMemory("tianming_discard",use_cards)
		return true
	end
end

sgs.ai_skill_discard.tianming = function(self,discard_num,min_num,optional,include_equip)
	local discard = self:getStrategyMemory("tianming_discard")
	if discard and #discard>=2 then
		return { discard[1],discard[2] }
	else
		return self:askForDiscard("dummyreason",2,2,false,true)
	end
end

sgs.ai_fill_skill.mizhao = function(self,inclusive,request)
	if self.player:isKongcheng()
	or self:needBear() then return end
	return self:evaluateTurnSkillCard("mizhao", "MizhaoCard", {}, request)
end

sgs.ai_skill_use_func.MizhaoCard = function(card,use,self,request)
	local trash = self:getCard("Disaster") or self:getCard("GodSalvation") or self:getCard("AmazingGrace") or self:getCard("Slash") or self:getCard("FireAttack")
	local count = 0
	local target
	for _,enemy in ipairs(self.enemies)do
		if not enemy:isKongcheng() then count = count+1 end
	end
	if self.player:getHandcardNum()==1 and trash and count>=1 and #self.enemies>1 then
		self:sortInPlace(self.enemies, "handcard")
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("manjuan") and enemy:isKongcheng())
			and not self:hasTuntianEffect(enemy, true)
			then target = enemy break end
		end
	end
	if not target then
		self:sortInPlace(self.friends_noself, "defense")
		self.friends_noself = reverse(self.friends_noself)
		if count<1 then return end
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") and not self:isWeak(friend)
			then target = friend break end
		end
		if not target then
			for _,friend in ipairs(self.friends_noself)do
				if not friend:hasSkill("manjuan")
				then target = friend break end
			end
		end
	end
	if target then
		for _,c in ipairs(self:addHandPile())do
			if isCard("Peach",c,self.player) and self.player:getHandcardNum()>1 and self.player:isWounded()
			and not self:needToLoseHp(self.player, nil, c)
			then use.card = c return end
		end
		use.card = card
		self:setStrategyPlayerFlag(target,"AI_MizhaoTarget",true)
		use.to:append(target)
	end
end

sgs.ai_use_priority.MizhaoCard = 1.5
sgs.ai_card_intention.MizhaoCard = 0
sgs.ai_playerchosen_intention.mizhao = 10

sgs.ai_skill_playerchosen.mizhao = function(self,targets)
	local from
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if player:getStrategyFlag("AI_MizhaoTarget") then
			from = player
			self:setStrategyPlayerFlag(from,"AI_MizhaoTarget",false)
			break
		end
	end
	self:sortInPlace(self.enemies, "defense")
	if from then
		local slash = known(self:getEvaluationCard("slash"),"Mizhao evaluation Slash")
		for _,to in ipairs(self.enemies)do
			if targets:contains(to) and self:slashIsEffective(slash, to, from) and not self:needToLoseHp(to, from, slash)
				and not self:needToLoseHp(to, from, slash) and not self:findLeijiTarget(to,50,from) then
				return to
			end
		end
	end
	for _,to in ipairs(self.enemies)do
		if targets:contains(to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.mizhao(minusecard,self,requestor,maxcard)
	local req
	if self.player:objectName()==requestor:objectName() then
        local context=self.request and self.request.options and self.request.options.context
        local name=context and context.mizhao_pindian_target
        if type(name)~="string" then ai_unsupported("public Mizhao pindian target is missing","mizhao") end
        req=known(self.room:findPlayerByObjectName(name),"Mizhao target")

	else
		req = requestor
	end
	local cards,maxcard = self.player:getHandcards(),nil
	local max_value = 0
	cards = self:sortByKeepValue(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a,b)
		return a:getNumber()>b:getNumber()
	end
	local function compare_func2(a,b)
		return a:getNumber()<b:getNumber()
	end
	if self:isFriend(req) and self.player:getHp()>req:getHp() then
		table.sort(cards,compare_func2)
	else
		table.sort(cards,compare_func1)
	end
	for _,card in ipairs(cards)do
		if max_value>7 or self:getKeepValue(card)<7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_skill_cardask["@jieyuan-increase"] = function(self,data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("SilverLion") then return "." end
	local cards = self.player:getHandcards()
	if self.player:getStrategyMark("jieyuan_renegade-Keep")>0 then
		cards = self.player:getCards("he")
	end
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if self.player:getStrategyMark("jieyuan_renegade-Keep")>0 then return "$"..card:getKnownEffectiveId() end
		if card:isBlack() then return "$"..card:getKnownEffectiveId() end
	end
	return "."
end

sgs.ai_skill_cardask["@jieyuan-decrease"] = function(self,data)
	local damage = data:toDamage()
	local cards = self.player:getHandcards()
	if self.player:getStrategyMark("jieyuan_renegade-Keep")>0 then
		cards = self.player:getCards("he")
	end
	cards = self:sortByKeepValue(cards)
	if damage.card and damage.card:isKindOf("Slash") then
		if self:ajustDamage(damage.from, self.player, 1, damage.card)>1
		then
			for _,card in ipairs(cards)do
				if self.player:getStrategyMark("jieyuan_renegade-Keep")>0 then return "$"..card:getKnownEffectiveId() end
				if card:isRed() then return "$"..card:getKnownEffectiveId() end
			end
		end
	end
	if self:needToLoseHp(self.player, damage.from, damage.card) and damage.damage<=1 then return "." end
	if self:needToLoseHp(self.player, damage.from, damage.card) and damage.damage<=1 then return "." end
	for _,card in ipairs(cards)do
		if self.player:getStrategyMark("jieyuan_renegade-Keep")>0 then return "$"..card:getKnownEffectiveId() end
		if card:isRed() then return "$"..card:getKnownEffectiveId() end
	end
	return "."
end

function sgs.ai_cardneed.jieyuan(to,card)
	if to:getStrategyMark("jieyuan_renegade-Keep")>0 then
		return to:getHandcardNum()<4 and (to:getHp()>=3 and true)
	end
	return to:getHandcardNum()<4 and (to:getHp()>=3 and true or card:isRed())
end

sgs.ai_skill_invoke.fenxin = function(self,data)
	local target = data:toPlayer()
	local target_role = known(self:getRoleEstimate(target),"Fenxin role estimate")
	local self_role = self.player:getKnownRole()
	if target_role=="renegade" or target_role=="neutral" then return false end
	local process = self:getGameProcess()
	return target_role=="rebel" and self.player:getKnownRole()~="rebel" and process:match("rebel")
	or target_role=="loyalist" and self.player:getKnownRole()~="loyalist" and process:match("loyal")
end

sgs.ai_fill_skill.mixin = function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self:needBear() then return end
	if #self.friends_noself<1 then return end
	return self:legacySkillSeed("mixin","MixinCard",request)
end

sgs.ai_skill_use_func.MixinCard = function(card,use,self,request)
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	if #self.enemies<1 then return end
	local slash
	cards = self:sortByKeepValue(cards)
	for _,acard in ipairs(cards)do
		if acard:isKindOf("Slash") then
			slash = acard
			break
		end
	end

	if slash then
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
				use.card = self:evaluateTurnSkillCard("mixin", "MixinCard", {slash:getKnownEffectiveId()}, request)
				use.to:append(friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if not friend:hasSkill("manjuan") then
				use.card = self:evaluateTurnSkillCard("mixin", "MixinCard", {slash:getKnownEffectiveId()}, request)
				use.to:append(friend)
				return
			end
		end
	else
		local compare_more_slash = function(a,b)
			return getCardsNum("Slash",a)>getCardsNum("Slash",b)
		end
		table.sort(self.friends_noself,compare_more_slash)
		for _,friend in ipairs(self.friends_noself)do
			if not friend:hasSkill("manjuan") and getCardsNum("Slash",friend)>=1 then
				use.card = self:evaluateTurnSkillCard("mixin", "MixinCard", {cards[1]:getEffectiveId()}, request)
				use.to:append(friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
				use.card = self:evaluateTurnSkillCard("mixin", "MixinCard", {cards[1]:getEffectiveId()}, request)
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_skill_playerchosen.mixin = sgs.ai_skill_playerchosen.zero_card_as_slash

local function mixin_response(self,target)
	if target then
		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(target) and self:slashIsEffective(slash, target) then
				if self:needLeiji(target,self.player) then return slash end
				if self:needToLoseHp(target, self.player, slash, true)
				then return slash end
			end
			if not self:isFriend(target) and self:slashIsEffective(slash, target)
			and not self:needToLoseHp(target, self.player, slash)
			and not self:needLeiji(target,self.player)
			then return slash end
		end
		for _,slash in ipairs(self:getCards("Slash"))do
			if not self:isFriend(target) then
				if not self:needLeiji(target,self.player) then return slash end
				if not self:slashIsEffective(slash, target) then return slash end
			end
		end
	end
	return nil
end

ai_skill_cardask["#mixin"]=function(self,options,request)
    local target=self:getDecisionContext().target
    if not target and options and options.players and options.players[1] then target=self.room:findPlayerByObjectName(options.players[1]) end
    return response_answer(self,mixin_response(self,target),options)
end

sgs.ai_use_priority.MixinCard = 0
sgs.ai_card_intention.MixinCard = -20

sgs.ai_skill_invoke.cangni = function(self,data)
	local target = self.room:getCurrent()
	if self.player:getStrategyFlag("cangnilose") then return self:isEnemy(target) end
	if self.player:getStrategyFlag("cangniget") then return self:isFriend(target) end
	local hand = self.player:getHandcardNum()
	local hp = self.player:getHp()
	return (hand+2)<=hp or self.player:isWounded();
end

sgs.ai_skill_choice.cangni = function(self,choices)
	local hand = self.player:getHandcardNum()
	local hp = self.player:getHp()
	if (hand+2)<=hp then
		return "draw"
	else
		return "recover"
	end
end

sgs.ai_fill_skill.duyi = function(self,inclusive,request)
	return self:evaluateTurnSkillCard("duyi", "DuyiCard", {}, request)
end

sgs.ai_skill_use_func.DuyiCard = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_playerchosen.duyi = function(self,targets)
    local target=self:getStrategyMemory("duyi_target")
    if target then
        self:setStrategyMemory("duyi_target",nil)
        local context=self.request and self.request.options and self.request.options.context
        local row=context and context.duyi_card
        if type(row)~="table" then ai_unsupported("current publicly revealed Duyi card is missing","duyi") end
        local black=known(CardView.new(row):isBlack(),"Duyi color")
        black=self:useKnowledgeEstimate({value=black,status="estimate",viewer=self.player:objectName(),target=target,
            basis="current publicly revealed Duyi color replaces previously cached secret top-card identity; intervening deck changes can differ"},"duyi.revealed_color")
        if black then return known(self.room:findPlayerByObjectName(target),"Duyi saved target") end
    end
    if self:needBear() then return self.player end
    local to=self:findPlayerToDraw(self:getOverflow()<0)
    return to or self.player
end
sgs.ai_playerchosen_intention.duyi = function(self,from,to)
    local target=self:getStrategyMemory("duyi_target")
    if target then
        local context=self.request and self.request.options and self.request.options.context
        local row=context and context.duyi_card
        if type(row)~="table" then ai_unsupported("public Duyi intention card is missing","duyi") end
        local red=known(CardView.new(row):isRed(),"Duyi color")
        red=self:useKnowledgeEstimate({value=red,status="estimate",viewer=self.player:objectName(),target=target,
            basis="current public Duyi face instead of secret cached top-card identity"},"duyi.intention_color")
        if red then self:updateIntention(from,to,-80) end
    end
    self:updateIntention(from,to,-10)
end

sgs.ai_skill_invoke.duanzhi = function(self,data)
	local use = data:toCardUse()
	if use.from and self:isEnemy(use.from) and use.card:getSubtype()=="attack_card" and self.player:getHp()==1 and not self:getCard("Peach")
		and not self:getCard("Analeptic") and not isLord(self.player) and self:getAllPeachNum()==0 then
		self:setStrategyPlayerFlag(self.player,"AI_doNotSave",true)
		return true
	end
	return use.from and self:isEnemy(use.from) and self:doDisCard(use.from, "he", nil, 2) and self.player:getHp()>2
end

sgs.ai_skill_choice.duanzhi = function(self,choices)
	return "discard"
end

local function fengyin_cost(self)
	if self:needBear() then return nil end
	local cards = self.player:getHandcards()
	local card
	cards = AIList.new(cards)

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Slash") then
			card = acard
			break
		end
	end

	if not card then
		return nil
	end

	local card_id = card:getKnownEffectiveId()

	local target = self.room:getCurrent()
	if self:isFriend(target) and self:willSkipPlayPhase(target) and target:getHandcardNum()+2>target:getHp() and target:getHp()>=self.player:getHp() then
		return card_id
	end
	if self:isEnemy(target) and not target:hasSkill("yongsi") and not self:willSkipPlayPhase(target) and target:getHandcardNum()>=target:getHp()
		and target:getHp()>=self.player:getHp() then
		return card_id
	end
	return nil
end

ai_skill_use["@@fengyin"]=function(self,prompt,request)
    local id=fengyin_cost(self)
    if id==nil then return {kind="pass"} end
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local receipt=known(self:bindSkillCard("fengyin",{id},request),"Fengyin receipt")
    local use=AIUsePlan.new();use.card=receipt
    return known(use:toAnswer(),"Fengyin exact response")
end

sgs.ai_skill_invoke.cv_caocao = function(self,data)
	if math.random(0,6)==0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_lingju = function(self,data)
	if math.random(0,2)==0 then return true end
	return false
end
