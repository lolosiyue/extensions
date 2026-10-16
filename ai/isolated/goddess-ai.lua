-- Fixed b6025acc goddess source policies. No hidden-card lookup or donor error repair.
local function result(v)if AIUnsupported.is(v)then error(v,0)end;return v end
local function known(v,k)result(v);if v==nil then ai_unsupported("goddess fact is unknown",k)end;return v end
local nullable={getWeapon=true,getCard=true,getCardId=true,findPlayerBySkillName=true,getCurrent=true,speak=true,setStrategyPlayerFlag=true,
    useCardshot=true,getSameEquip=true,getEvaluationCandidate=true,getCardCandidate=true,updateIntention=true}
local sorted={sort=true,sortByKeepValue=true,sortByUseValue=true}

local function dummy(isDummy,extra)
    return {isDummy=isDummy==nil and true or isDummy,extra_target=extra or 0,to=AIList.new({}),current_targets={}}
end
local function role(self,p)return p==self.player and p:getKnownRole()or self:getRoleEstimate(p)end
local function is_current(use,target)
    for _,p in ipairs(use.current_targets or{})do if p==target or p==target:objectName()then return true end end
end
local function extra(self,card)
    local candidate=self:getEvaluationCandidate(card)or self:getCardCandidate(card:getKnownEffectiveId())
    if not candidate and AIValue.isConversion(card)then candidate=card end
    return (known(candidate,"extra-target candidate")):getExtraTargetCount()
end
local function can_to(self,card,from,to,targets)
    if from~=self.player then ai_unsupported("goddess targetFilter is outside owner scope","CanToCard")end
    return self:cardTargetFilter(card, targets or{}, to)
end
local function jueqing(self,from,to)return self:hasJueqingEffect(from, to)end
local function chain(self,to,from)return known(hasChainEffect(to,from),"chain effect")end
local function nullfilter(self,data,pattern,target)
    local f=sgs.ai_skill_cardask.nullfilter
    if type(f)~="function"then ai_unsupported("effective nullfilter unavailable","goddess")end
    return result(f(self,data,pattern,target))
end
local function current_damage(self)
    local raw=known(self:getDecisionContext().damage,"CurrentDamageStruct")
    local copy={};for k,v in pairs(raw)do copy[k]=v end
    copy.damage=known(raw.amount~=nil and raw.amount or raw.damage,"CurrentDamageStruct.damage")
    return copy
end
local function tag_card(self,key,nullable_tag)ai_unsupported("goddess room tag is not projected",key)end
-- Fixed PoAskPo reads toCard() only as a truth value. A finite native producer
-- window attests presence; no unused card face or subcard identity is required.
local function tag_present(self,key)ai_unsupported("goddess room tag is not projected",key)end
-- Room tag UseHistory<index>; an absent tag reads as the donor's empty CardUseStruct.
local function history_use(self,index)
    local u=self:getUseHistory(index)
    if u==nil then return {}end
    return{from=u.from~=""and self.room:findPlayerByObjectName(u.from, true)or nil,
        card=type(u.card)=="table"and u.card.name~=nil and CardView.new(u.card)or nil}
end
local function humanized(self)
    local policy=self:getResponsePolicy()
    return known(policy.humanized,"AIHumanized")
end
local function owner_property(self,key)
    -- The viewer's own property, read like the donor's toString() (absent reads "").
    local v=self.player:getPropertyValue(key)
    if v==nil then return "" end;return v
end
local function persistent_effect_card(self)
    local context=self:getDecisionContext()
    return known(context.effect and context.effect.card,"sgs.cardEffect.card")
end
local function update_intentions(self,from,tos,level)for _,to in ipairs(tos)do self:updateIntention(from, to, level)end end
local function turn_conversion(self,request,wire,costs)
    local name,skill=wire:match('^(%w+):(%w+)%[')
    -- Raw NoSuit/0 storage inherits the sole material through Card::getSuit/getNumber.
    local printed=({SavageAssault="savage_assault",ArcheryAttack="archery_attack"})[name]
    if not printed then ai_unsupported("goddess conversion source class not audited",name)end
    local material=self:getKnownCardById(costs[1])
    return self:evaluateTurnConversion(skill, name, {name=printed,skill=skill,suit=material:getSuit(),number=material:getNumber(),subcards=costs}, request or self.request)
end
local function youhua_source(self,material_id,reference,request)
    local row=self:getGodYouhuaSourceObservation(material_id)
    if row.reference_id~=reference then ai_unsupported("GodYouhua reference changed during source evaluation","GodYouhua")end
    if row.exists==false then error("donor GodYouhua Card_Parse assertion failed",0)end
    return self:evaluateTurnConversion("GodYouhua", known(row.card.class_name,"GodYouhua parsed class"), {name=known(row.card.name,"GodYouhua parsed name"),skill=known(row.card.skill_name,"GodYouhua parsed skill"),
         suit=known(row.card.suit,"GodYouhua parsed suit"),number=known(row.card.number,"GodYouhua parsed number"),subcards={material_id}}, request or self.request)
end
sgs.ai_fill_skill.GodQuxiang = function(self, inclusive, request)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local subcards = {}
	self:sortByUseValueInPlace(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if card:isBlack() then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if self:getKeepValue(cardsq[1])  > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getKnownId())
	local card_str = "SavageAssault:GodQuxiang[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = turn_conversion(self,request,card_str,subcards)
	assert(AsCard)
	return AsCard
end


sgs.ai_skill_choice["GodShenfu"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

sgs.ai_fill_skill.GodShijun = function(self, inclusive, request)
	if not self.player:canDiscard(self.player, "he") then return end
	return self:legacySkillSeed("GodShijun", "#GodShijunCard", request or self.request)
end

sgs.ai_skill_use_func["#GodShijunCard"] = function(card, use, self, request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortInPlace(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValueInPlace(cards, true)
	if slashcount > 0  then
		for _, card in ipairs(cards) do
				if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
					assert(slash)
					local dummy_use = self:withOwnerRange("InfinityAttackRange", "GodShijun", function()
						return self:aiUseCard(slash, dummy(true))
					end)
					if dummy_use.card and dummy_use.to:length() > 0 then
						local target
						for _, enemy in ipairs(self.enemies) do
							if not self.player:inMyAttackRange(enemy) then
								target = enemy
							else
								return
							end
						end
						if target then
						use.card = self:bindSkillCard("GodShijun", {card:getKnownId()}, request or self.request, nil, "#GodShijunCard")
								if use.to then use.to:append(target) end
								return
						end
					end
				end
			end
	end
end

sgs.ai_card_intention["GodShijunCard"] = 70


sgs.ai_use_value["GodShijunCard"] = 9.2
sgs.ai_use_priority["GodShijunCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_fill_skill.GodYouhua = function(self, inclusive, request)
	if self.player:isNude() then return nil end
	if self.player:getStrategyMark("LastId") == 0 or self.player:hasFlag("YouhuaUsed") then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	local card = cards[1]
	local Id = self.player:getStrategyMark("LastId")
		
	if card and self.player:getStrategyMark("LastId") > 0 then
        local reference=self:getGodYouhuaSourceObservation()
        if reference.reference_id~=Id then ai_unsupported("GodYouhua current LastId observation differs","GodYouhua")end
        -- Source calls isKindOf on the actual clone, not on the physical reference.
        if reference.clone_exists==false then error("donor GodYouhua cloneCard returned nil before isKindOf",0)end
        for _,kind in ipairs(reference.clone.kind_of)do if kind=="IronChain"then return nil end end
        -- Preserve reached source getter/mark order before its Card_Parse call.
        local suit=card:getSuitString()
        local number=card:getNumberString()
        local material_id=card:getKnownEffectiveId()
        if self.player:getStrategyMark("LastId")<=0 then error("donor GodYouhua source wire became nil",0)end
        return youhua_source(self,material_id,Id,request)
	end
end	




sgs.ai_fill_skill.GodGongshen = function(self, inclusive, request)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local subcards = {}
	self:sortByUseValueInPlace(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if self:getKeepValue(cardsq[1])  > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getKnownId())
	local card_str = "ArcheryAttack:GodGongshen[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = turn_conversion(self,request,card_str,subcards)
	assert(AsCard)
	return AsCard
end



sgs.ai_skill_playerchosen["GodJiuse"] = function(self, targets)
	local damage = current_damage(self)
	targets = sgs.QList2Table(targets)
			if self:isEnemy(damage.to) then
					self:sortInPlace(targets, "defense")
					for _, anotherenemy in ipairs(targets) do
						if  self:ajustDamage(damage.from, damage.to, damage.damage, damage.card) > 0 then
							if self:isWeak(damage.to) then
								if self:isEnemy(anotherenemy) and self:ajustDamage(anotherenemy, damage.to, damage.damage, damage.card) > 0 then
									return anotherenemy
								end
							else
								if self:isFriend(anotherenemy) and self:ajustDamage(anotherenemy, damage.to, damage.damage, damage.card) > 0  then
									return anotherenemy
								end
						end
					end
				end
			end

	return nil
end

sgs.ai_ajustdamage_from.GodJiuse = function(self, from, to, card, nature)
	if (card and card:isKindOf("Slash")) and from:getPhase() == sgs.Player_Play	then
		for _,p in sgs.qlist(self.room:getOtherPlayers(from)) do
			if p:isMale() and p:inMyAttackRange(to) then
				return 1
			end
		end
	end
end
-- GodJiuse identity-gated alias remains shared-owned.


sgs.ai_skill_invoke.GodManwu = function(self, data)
	local card = tag_card(self,"GodManwu")
	if self:isWeak() and (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then return true end
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") and card:isKindOf("Slash") then return true end
	if not self:isWeak() and (card:isKindOf("Snatch") or card:isKindOf("ExNihilo") or card:isKindOf("Dismantlement")) then return true end
	return false
end


sgs.ai_skill_choice["LuaDanji"] = function(self, choices, data)
	local items = choices:split("+")
	if self.player:isWeak() then
		return "distwocards"
	end
	return items[math.random(1,#items)]
end

function sgs.ai_skill_invoke.LuaXJianshou(self, data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (known(self.world.turn_count,"turncount") <= 1 and role(self,sbdiaochan) == "neutral")) then return false end
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	return self:isWeak()
end

sgs.ai_target_revises.LuaTiebi = function(to,card)
	if card:isKindOf("Dismantlement") and not to:faceUp()
	then return true end
end

sgs.bad_skills = sgs.bad_skills .. "|GodXiaoshi"


-- GodSaodang identity-gated alias remains shared-owned.

sgs.ai_target_revises.GodYuxiang = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end


function SmartAIView:useCardshot(card,use)
	local extraTarget = extra(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	local function slashNoTarget(target)
		if is_current(use,target)
		or use.to:contains(target) then return end
		if use.card and use.card~=card then
			extraTarget = extra(self,use.card)
			if use.extra_target then extraTarget = extraTarget+use.extra_target end
		end
		if use.to:length()>extraTarget then return true end
		if can_to(self,use.card or card,self.player,target)
		and self:ajustDamage(self.player, target, 1, use.card or card)~=0 then
			if (card:isKindOf("thunder_shot") or card:isKindOf("fire_shot"))
			and chain(self,target,self.player) then
				if self:isGoodChainTarget(target, card) then
					use.card = card
					use.to:append(target)
				end
			else
				use.card = card
				use.to:append(target)
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if role(self,friend)==role(self,self.player)
		and self:isPriorFriendOfSlash(friend, use.card or card)
		and slashNoTarget(friend) then return end
	end
	
	local forbidden = {}
	self:sortInPlace(self.enemies, "defenseSlash")
	for _,enemy in ipairs(self.enemies)do
		if self:isGoodTarget(enemy, self.enemies, use.card or card) then
			if self:objectiveLevel(enemy)<=3
			then table.insert(forbidden,enemy)
			elseif slashNoTarget(enemy)
			then return end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if role(self,friend)==role(self,self.player)
		and (use.card or card):getSkillName()~="lihuo"
		and not(friend:isLord() and #self.enemies<1)
		and self:needToLoseHp(friend, self.player, use.card or card, true)
		and self:ajustDamage(self.player, friend, 1, use.card or card)==1
		and slashNoTarget(friend) then return end
	end
	for _,target in ipairs(forbidden)do
		if slashNoTarget(target) then return end
	end
end
sgs.ai_use_priority.shot = 4.55
sgs.ai_use_value.shot = 9
sgs.ai_keep_value.shot = 1.0
sgs.ai_card_intention.shot = 40
function SmartAIView:useCardthunder_shot(...)
	self:useCardshot(...)
end
sgs.card_damage_nature.thunder_shot = "T"

sgs.ai_card_intention.thunder_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.thunder_shot = 4.6
sgs.ai_keep_value.thunder_shot = 3.63
sgs.ai_use_priority.thunder_shot = 2.5

function SmartAIView:useCardfire_shot(...)
	self:useCardshot(...)
end
sgs.card_damage_nature.fire_shot = "F"

sgs.ai_card_intention.fire_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.fire_shot = 4.6
sgs.ai_keep_value.fire_shot = 3.63
sgs.ai_use_priority.fire_shot = 2.5



sgs.ai_skill_cardask["shot-jink"] = function(self,data,pattern,target)
	local slash = self:getEvaluationCard("slash")
	local effect = data:toCardEffect()
	if (type(data)=="table" or type(data)=="userdata") and effect and effect.card then slash = effect.card end
	local source = target or (effect and effect.from)
	if not source or nullfilter(self,data,pattern,source)=="."
	or (slash:isKindOf("fire_shot") or slash:isKindOf("thunder_shot")) and self.player:isChained() and self:isGoodChainTarget(self.player, slash, source)then return "." end
	local n = self:ajustDamage(source, self.player, 1, (effect and effect.card) or slash)
	if self:needToLoseHp(self.player, source, slash) and n==1
	then return "." end
	local function getJink()
		if #self.friends_noself>0 and self:getCardsNum("Peach,Analeptic")<1
		and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")

		end
		return "."
	end
	if self:isFriend(source) then
		if self.player:getLostHp()==0 and self.player:isMale() and source:hasSkill("jieyin") then return "." end
		if not jueqing(self,source,self.player) then
			if (source:hasSkill("nosrende") or source:hasSkill("rende") and not source:getStrategyHasUsed("RendeCard")) and self.player:hasSkill("jieming")
			or source:hasSkill("pojun") and not self.player:faceUp()
			then return "." end
		end
	else
		if n>1 or n>=self.player:getHp() then return getJink() end
		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp()>0 then
			for _,c in sgs.list(self:getCards("Jink"))do
				if self.player:isLastHandCard(c, true)
				then return "." end
			end
		end
		if self.player:getHandcardNum()==1 and self:needKongcheng()
		or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return getJink() end
		if self.player:getHp()>1 and getKnownCard(source,self.player,"Slash")>0
		and getKnownCard(source,self.player,"Analeptic")>0 and self:getCardsNum("Jink")<=1
		and (source:getPhase()<=sgs.Player_Play or self:slashIsAvailable(source) and source:canSlash(self.player))
		then return "." end
	end
	return getJink()
end


sgs.ai_skill_cardask["Kai-Jink"] = function(self,data,pattern,target)
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then
			use = history_use(self,data:toStringList()[4])
		end
	end
	local function getKai()
		if humanized(self) then

		end
		for _,c in sgs.list(self:getCard("Kai", true))do
			if self.player:hasFlag("dahe") and c:getSuit()~=sgs.Card_Heart then continue end
			return c
		end
		if humanized(self) and math.random()<0.5 and #self.friends_noself>0 and self:getCardsNum("Peach,Analeptic")<1
		and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")

		end
		return "."
	end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return getKai()  end
		if not use.from or nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, use.card, use.from)
		or self:needToLoseHp(self.player, use.from, use.card) and self:ajustDamage(use.from, self.player, 1, use.card)==1 then return "." end
	end
	if self:needToLoseHp(self.player, use.from, use.card, true) then return "."  end
	if self:getCardsNum("Jink") == 0 then return getKai() end
	if self:ajustDamage(use.from, self.player, 1, use.card)>1 then return getKai() end
end

sgs.ai_use_value.Kai = 9
sgs.ai_keep_value.Kai = 5.3

sgs.ai_skill_cardask["PoAskPo"] = function(self,data,pattern,target)
    -- Exact native non-CardUse question conversion has a null source. The
    -- original getTag/toCard read is total, pure, and its result is unused on
    -- this branch; do not turn that read into a private presence capability.
    local context=self:getDecisionContext()
    local empty=type(context.goddess)=="table"and context.goddess.po_ask_empty_use
    if empty~=nil and empty~=false then
        local r=self.request
        if type(empty)~="table"or empty.known~=true
            or (empty.source~="Kai.CardAsked"and empty.source~="Weikai.CardResponded")
            or not r or r.kind~="respond_card"or r.pattern~="Weikai"
            or r.prompt~="PoAskPo"or r.handling_method~=sgs.Card_MethodUse then
            ai_unsupported("Goddess default CardUse proof is malformed or outside current question","PoAskPo")
        end
        return "."
    end
	local use = data:toCardUse()
	local Weikai = tag_present(self,"Weikai")
	if use.from and self:isEnemy(use.from) then
		if Weikai then
			return "."
		else
			for _,c in sgs.list(self:getCard("Weikai", true))do
				return c
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAsk"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	if use.from and self:isEnemy(use.from) then
		for _,c in sgs.list(self:getCard("Weikai", true))do
			return c
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAskAgain"] = function(self,data,pattern,target)
	for _,c in sgs.list(self:getCard(pattern, true))do
		return c
	end
	return true
end
sgs.ai_keep_value.Weikai = 5.2

function SmartAIView:useCardSu(card,use)
	self:sortInPlace(self.friends, "hp")
	local extraTarget = 1 + extra(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends)do
		if is_current(use,ep) then continue end
		if self.player:canUse(card, ep) then
	    	use.card = card
	    	use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Su = 2.4
sgs.ai_keep_value.Su = 2.2
sgs.ai_use_value.Su = 4.7
sgs.ai_card_intention.Su = -33

function SmartAIView:useCardgongcheng(card,use)
	local slash = self:getCard("Slash")
	if slash and #self:getCards("Slash") > 1 then
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
			use.card = card
		end
	end
end
sgs.ai_use_priority.gongcheng = 2.7
sgs.ai_keep_value.gongcheng = 2.2
sgs.ai_use_value.gongcheng = 4.7

function SmartAIView:useCardxianzhencard(card,use)
	local dismantlement = self:getEvaluationCard("dismantlement")
	
	local dummy_use = self:aiUseCard(dismantlement, dummy(true,99))
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() and dummy_use.to:length() >= self.room:alivePlayerCount()/2 then
		use.card = card
	end
end
sgs.ai_use_value.xianzhencard = 5.6
sgs.ai_use_priority.xianzhencard = 9.4
sgs.ai_keep_value.xianzhencard = 3.44
-- xianzhencard identity-gated alias remains shared-owned.










-- The donor sets a real flag on its own player, live until that player's next flag
-- clear. The isolated VM cannot set it, so its own writes go to viewer memory stamped
-- with the flag lifecycle epoch; a flag set by a gameplay-VM decision is read directly.
local function manbing_flag(self,target,write)
    local name=target:objectName()
    if self.room:findPlayerByObjectName(name,true)~=target then
        ai_unsupported("Manbing target is outside the current roster","manbingTo_")
    end
    local epochs=known(AIWorldLifecycle.epochs(self.world,"flag"),"manbingTo_")
    local epoch=known(epochs[self.player:objectName()],"manbingTo_")
    local key="goddess.manbingTo_"..name
    if write then self:remember(key, epoch);return true end
    return self.player:hasFlag("manbingTo_"..name) or self:recall(key)==epoch
end

function SmartAIView:useCardmanbing(manbing,use)
	self.aiUsing = manbing:getSubcards()
	local extraTarget = extra(self,manbing)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if use.xiechan then extraTarget = 100 end
	self:sortInPlace(self.enemies)
	local enemySlash = 0
	for _,enemy in sgs.list(self.enemies)do
		if is_current(use,enemy) then continue end
		if manbing_flag(self,enemy)
		and can_to(self,manbing,self.player,enemy)
		and self:ajustDamage(self.player, enemy, 1, manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if n2>0 then continue end
			enemySlash = enemySlash+n2
			if self.player:getPhase()<=sgs.Player_Play and math.random()<0.5
			then manbing_flag(self,enemy,true) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
	local bcv = {}
	for _,p in ipairs(self.enemies)do
		local v1 = getCardsNum("Slash",p,self.player)+p:getHp()
		if not self:isWeak(p) and p:hasSkill("jianxiong") and not jueqing(self,self.player,p) then v1 = v1+10 end
		if self:needToLoseHp(p, nil, manbing) then v1 = v1+15 end
		if self:hasSkills(sgs.masochism_skill, p) then v1 = v1+5 end
		if not self:isWeak(p) and p:hasSkill("jiang") then v1 = v1+5 end
		if p:hasLordSkill("jijiang") then v1 = v1+self:JijiangSlash(p)*2 end
		bcv[p:objectName()] = v1
	end
	local function compare_func(a,b)
		return bcv[a:objectName()]<bcv[b:objectName()]
	end
	table.sort(self.enemies,compare_func)
	for _,enemy in sgs.list(self.enemies)do
		if is_current(use,enemy) then continue end
		if not use.to:contains(enemy) and can_to(self,manbing,self.player,enemy)
		and self:objectiveLevel(enemy)>3 and self:isGoodTarget(enemy, self.enemies)
		and self:ajustDamage(self.player, enemy, 1, manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if self:needToLoseHp(self.player, nil, manbing, true) or n2<1
			or self:hasSkill("jianxiong") or owner_property(self,"shuangxiong_colors_turn") ~= ""
			then else continue end
			enemySlash = enemySlash+n2
			if self.player:getPhase()<=sgs.Player_Play and math.random()<0.5
			then manbing_flag(self,enemy,true) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_card_intention.manbing = function(self,card,from,tos)
	update_intentions(self,from,tos,66)
end

sgs.ai_use_value.manbing = 3.7
sgs.ai_use_priority.manbing = 2.9
sgs.ai_keep_value.manbing = 3.42

sgs.dynamic_value.damage_card.manbing = true

sgs.ai_skill_cardask["manbing-slash1"] = function(self,data,pattern,target)
	local effect = data:toCardEffect()
	if self.player:hasSkill("wuhun") and self:isEnemy(effect.from) and effect.from:isLord() and #self.friends_noself>0
	or self:getCardsNum("Slash")<2
	or self:isEnemy(effect.from) and not self:isWeak() and self:needToLoseHp(self.player, effect.from, effect.card)
	or self:ajustDamage(effect.from, self.player, 1, effect.card)==0
	or nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if self:getCardsNum("Slash")>=2 then return true end
	return "."
end
sgs.ai_skill_cardask["manbing-slash2"] = function(self,data,pattern,target)
	local effect = data:toCardEffect()
	if self.player:hasSkill("wuhun") and self:isEnemy(effect.from) and effect.from:isLord() and #self.friends_noself>0
	or self:getCardsNum("Slash")<1
	or self:isEnemy(effect.from) and not self:isWeak() and self:needToLoseHp(self.player, effect.from)
	or self:ajustDamage(effect.from, self.player, 1, effect.card)==0
	or nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if self:getCardsNum("Slash")>=1 then return true end
	return "."
end


function SmartAIView:useCardquanxiang(card,use)
	self:sortInPlace(self.enemies, "skill", false)
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if ep:getStrategyMark("@RemoveGeneral") == 0
		and ep:getVisibleSkillList():length()>0
		and ep:getHandcardNum() < self.player:getHandcardNum()
	   	and can_to(self,card,self.player,ep,use.to) then
	    	use.card = card
	    	use.to:append(ep)
		end
	end
end
sgs.ai_use_priority.quanxiang = 5.4
sgs.ai_keep_value.quanxiang = 4
sgs.ai_use_value.quanxiang = 3.7

sgs.ai_nullification.quanxiang = function(self,trick,from,to,positive)
    return self:isFriend(to) and (to:getHandcardNum()>3 or to==self.player)
	and positive
end

sgs.ai_card_intention.quanxiang = 80

sgs.ai_skill_cardask["@quanxiangmessage"] = function(self,data,pattern,target)
	if target and self:isEnemy(target) then
		local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValueInPlace(cards)
        for _,h in sgs.list(cards)do
            if self:matchesDiscardPattern(pattern, h)
            then return h:getKnownEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getKnownEffectiveId() end
        end
        return self:getCardId(pattern)
	end
end


function SmartAIView:useCardshuigong(shuigong,use)
	local lack = {basic=false,trick=false,equip=false}
	local canDis = {}
	for _,h in sgs.list(self.player:getHandcards())do
		if h:getKnownEffectiveId()~=shuigong:getKnownEffectiveId()
		and self.player:canDiscard(self.player, h:getKnownEffectiveId())
		then
			table.insert(canDis,h)
			lack[h:getTypeId()] = true
		end
	end
	local suitnum = 0
	for suit,islack in pairs(lack)do
		if islack then suitnum = suitnum+1  end
	end
	self:sortInPlace(self.enemies, "defense")
	local function can_attack(enemy)
		if self:cantbeHurt(enemy, self.player) then return end
		return self:objectiveLevel(enemy)>2
		and self:isGoodTarget(enemy, self.enemies, shuigong)
		and (jueqing(self,self.player,enemy) or not(enemy:hasSkill("jianxiong") and not self:isWeak(enemy)
		or self:needToLoseHp(enemy, self.player, shuigong)))
	end
	local enemies,targets = {},{}
	for _,enemy in sgs.list(self.enemies)do
		if can_attack(enemy) then table.insert(enemies,enemy) end
	end
	for kc,enemy in sgs.list(enemies)do
		kc = getKnownCards(enemy,self.player)
		if #kc>enemy:getHandcardNum()/2
		then
			local can = 0
			for _,h in sgs.list(kc)do
				if lack[h:getSuitString()]
				then can = can+1 end
			end
			if can>=#kc then table.insert(targets,enemy) end
		end
	end
	
	if (suitnum==2 and lack.diamond or suitnum<=1) and #targets<1
	and self:getOverflow()<=(self.player:hasSkills("jizhi|nosjizhi") and -2 or 0)
	then return end
	for _,enemy in sgs.list(enemies)do
		if table.contains(targets,enemy)
		then else table.insert(targets,enemy) end
	end
	local extraTarget = extra(self,shuigong)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,p in sgs.list(targets)do
		if is_current(use,p) then continue end
		if can_to(self,shuigong,self.player,p)
		and self:ajustDamage(self.player, p, 1, shuigong)~=0
		then
			use.card = shuigong
			local gs = self:getCard("GodSalvation")
			if gs and gs:getKnownEffectiveId()~=shuigong:getKnownEffectiveId()
			and p:getLostHp()<1 and self:willUseGodSalvation(gs)
			and self:hasTrickEffective(gs, p, self.player)
			then use.card = gs return end
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
end


sgs.ai_use_value.shuigong = 4.8
sgs.ai_keep_value.shuigong = 3.3
sgs.ai_use_priority.shuigong = sgs.ai_use_priority.Dismantlement+0.1
sgs.dynamic_value.damage_card.shuigong = true
sgs.ai_card_intention.shuigong = 80

sgs.ai_skill_cardask["@shuigongmessage_BasicCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValueInPlace(cards, true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("BasicCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target, self.player, persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil, false) or self:ajustDamage(self.player, target, 1, persistent_effect_card(self))>1
				then return c:getKnownId() end
			else
				return c:getKnownId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_TrickCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValueInPlace(cards, true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("TrickCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target, self.player, persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil, false) or self:ajustDamage(self.player, target, 1, persistent_effect_card(self))>1
				then return c:getKnownId() end
			else
				return c:getKnownId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_EquipCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValueInPlace(cards, true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target, self.player, persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil, false) or self:ajustDamage(self.player, target, 1, persistent_effect_card(self))>1
				then return c:getKnownId() end
			else
				return c:getKnownId()
			end
		end
	end
	return "."
end