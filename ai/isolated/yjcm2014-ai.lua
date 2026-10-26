-- Source: b6025acc ai/yjcm2014-ai.lua.
local known = AIValue.requireKnown

local dummy = AIUsePlan.dummy
local function visible(self,id)
    id=tonumber(id)
    return known(self:getChoiceCard(id)or self:getKnownCardById(id),'disclosed card '..tostring(id))
end
local function skill_card(self,skill,class,costs,request)
    local authority=self:bindSkillCard(skill, costs, request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=visible(self,costs[1]);suit,number=c:getSuit(),c:getNumber()
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs)do local c=visible(self,id);red,black=red and c:isRed(),black and c:isBlack()end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]='spade',[sgs.Card_Club]='club',[sgs.Card_Heart]='heart',[sgs.Card_Diamond]='diamond',[sgs.Card_NoSuitBlack]='no_suit_black',[sgs.Card_NoSuitRed]='no_suit_red',[sgs.Card_NoSuit]='no_suit'}
    local ns=({[1]='A',[11]='J',[12]='Q',[13]='K'})[number]or tostring(number)
    local key='@'..class..'['..known(suits[suit],'skill policy suit')..':'..ns..']='..(#costs>0 and table.concat(costs,'+')or'.')
    return self:legacyPolicyCard(authority, {name='',class_name=class,type_id=0,kind_of={class,'SkillCard','Card'},
        legacy_string_key=key,legacy_sort_key=key,subcards=costs,suit=suit,number=number,effective_id=costs[1],
        skill_name=skill,skill_names={skill},will_throw=class~='SidiCard',handling_method=class=='SidiCard'and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        damage_card=false,can_recast=false,
        red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack})
end
local function response_skill(self,skill,class,costs,targets)
    local use=dummy(false);use.card=skill_card(self,skill,class,costs)
    for _,name in ipairs(targets or{})do use.to:append(known(self.room:findPlayerByObjectName(name),'response target'))end
    return use:toAnswer()
end
local function choose_card(self,player,flags,reason,method)
    local result=self:recommendCardChosen(player, flags, reason, method)
    if result.zone=='none'then return -1 end -- donor getCardRandomly empty sentinel is truthy.
    return known(result.id,'public chosen card')
end
local function random_judge(self,player)
    local ids={};local disabled=self.disabled_ids or self:getStrategyMemory('discard_disabled_ids')or{}
    for _,card in ipairs(player:getJudgingArea())do
        local id=card:getKnownEffectiveId();if not table.contains(disabled,id)then ids[#ids+1]=id end
    end
    if #ids<1 then return -1 end
    local index=math.random(1,#ids);local id=ids[index]
    local card=visible(self,id)
    if card:isKindOf('SilverLion')and player:isWounded()and self:isEnemy(player)and player:hasArmorEffect('SilverLion')then
        if index~=#ids then id=ids[index+1]elseif index>1 then id=ids[index-1]end
    end
    return id
end
local function save_yonglve(self,id)
    self:setStrategyMemory('yjcm2014.yonglve_cardchosen',id)
    self:useKnowledgeEstimate({value=id,status='estimate',basis='viewer_local_yonglve_cardchosen_without_cross_viewer_global_writes'},'yonglve')
end
local function zenhui_use(self)
    local row=known(self.player:getTag('zenhui'),'zenhui_use')
    local use={card=known(CardView.new(row.card),'Zenhui active card'),to=AIList.new({})}
    use.from=known(self.room:findPlayerByObjectName(row.from),'Zenhui source')
    for _,name in ipairs(row.to)do use.to:append(known(self.room:findPlayerByObjectName(name),'Zenhui target'))end
    return use
end
-- getAI() from the public board: a player who is online, or whose actual
-- controller is online, has none; any other control state is private.
local function borrowed_ai(self,player)
    if player:getState()=='online' then return false end
    local controller=self.room:findPlayerByObjectName(player:getController(),true)
    if controller and controller:getState()=='online' then return false end
    return known(nil,'player AI presence')
end

ai_fill_skill.dingpin = function(self, options, request)
    local inclusive = options and options.inclusive

	self:setPriorityValue("DingpinCard",0,"dingpin")
	if not self.player:canDiscard(self.player, "h") then return false end
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if not p:getStrategyFlag("dingpin") and p:isWounded() then
			if not self:toTurnOver(self.player) then self:setPriorityValue("DingpinCard",8.9,"dingpin") end
			return self:legacySkillSeed("dingpin","DingpinCard",request)
		end
	end
end
ai_card_use.DingpinCard = function(self, card, use, request)
	local cards = {}
	local cardType = {}
	for _,card in sgs.qlist(self.player:getHandcards())do
		if self.player:canDiscard(self.player, card:getKnownEffectiveId()) and self.player:getStrategyMark("dingpin_"..card:getType().."-Clear")==0 then
			table.insert(cards,card)
			if not table.contains(cardType,card:getTypeId()) then table.insert(cardType,card:getTypeId()) end
		end
	end

	if #cards==0 then return end
	self:sortByUseValue(cards,true)
	if self:isValuableCard(cards[1]) then return end

	if #cardType>1 or not self:toTurnOver(self.player) then
		self:sort(self.friends)
		for _,friend in ipairs(self.friends)do
			if not friend:getStrategyFlag("dingpin") and friend:isWounded() then
				use.card = skill_card(self,"dingpin","DingpinCard",{cards[1]:getKnownEffectiveId()},request)
				use.to:append(friend)
				return
			end
		end
	end

end

sgs.ai_use_priority.DingpinCard = 0
sgs.ai_card_intention.DingpinCard = -10

ai_skill_invoke.faen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local player = data:toPlayer()
	if self:needKongcheng(player, true) then return (not self:isFriend(player)) or false end
	return (self:isFriend(player)) or false
end

sgs.ai_choicemade_filter.skillInvoke.faen = function(self,player,promptlist)
	local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
	if not target then return end
	local yes = promptlist[#promptlist]=="yes"
	if self:needKongcheng(target, true) then
		self:updateIntention(player,target,yes and 10 or -10)
	else
		self:updateIntention(player,target,yes and -10 or 10)
	end
end

ai_skill_invoke.sidi = true

ai_skill_use["@@sidi"] = function(self, prompt, request)
	local current = self.room:getCurrent()
	if self:isEnemy(current) then
		if (getCardsNum("Slash",current,self.player)>0 or self.player:getPile("sidi"):length()>1)
		and not self:hasCrossbowEffect(current) then
			for _,p in sgs.qlist(self.room:getOtherPlayers(current))do
				if self:isFriend(p) and current:distanceTo(p)<=current:getAttackRange()
				and self:slashIsEffective(self:getEvaluationCard("slash"), p)
				and (self:isWeak(p) or self.player:getPile("sidi"):length()>1) then
					return response_skill(self,"sidi","SidiCard",{self.player:getPile("sidi"):first()})
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["@ol_sidi-discard"] = function(self,data,pattern)
	local target = self.room:getCurrent()
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if self:isEnemy(target) and #cards>1
		and self:matchGuanxingPattern(pattern, self.player, h)
        then return h:getKnownEffectiveId() end
	end
    return "."
end

ai_skill_use["@@shenduan"] = function(self, prompt, request)
	for _,id in ipairs((self.player:getPropertyValue("shenduanForAI") or ""):split("+"))do
		local card = visible(self,id)
		local card_str = ("supply_shortage:shenduan[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),id)
		local ss = self:bindTurnConversion("shenduan","SupplyShortage",{name="supply_shortage",skill="shenduan",suit=card:getSuit(),number=card:getNumber(),subcards={tonumber(id)}})
		if self.player:isCardLimited(ss, sgs.Card_MethodUse) then continue end
		local dummy_use = dummy()
		self:useCardSupplyShortage(ss,dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local selected=dummy(false);selected.card=dummy_use.card;selected.to:append(dummy_use.to:first());return selected:toAnswer()
		end
	end
	return "."
end

ai_skill_invoke.yonglve = function(self, options, request)
	local current = self.room:getCurrent()
	local slash = self:evaluateSkillCard("_yonglve","slash",{})
	if self:isFriend(current)
	and choose_card(self,current,"j","dummyReason",sgs.Card_MethodDiscard) then
		if not self:slashIsEffective(slash, current, self.player) then return (true) or false end
		if not self:isWeak(current) or getKnownCard(current,self.player,"Jink")>0 then return (true) or false end
	elseif self:isEnemy(current) then
		if choose_card(self,current,"j","dummyReason",sgs.Card_MethodDiscard) then return (true) or false end
		for _,card in sgs.qlist(current:getJudgingArea())do
			if card:isKindOf("SupplyShortage")
			and (current:getHandcardNum()>4 or current:containsTrick("indulgence")) then
				save_yonglve(self,card:getKnownEffectiveId())
				return (true) or false
			elseif card:isKindOf("Indulgence")
			and current:getHandcardNum()+self:ImitateResult_DrawNCards(current)<=self:getOverflow(current, true) then
				save_yonglve(self,card:getKnownEffectiveId())
				return (true) or false
			end
		end
		if self:isWeak(current) and current:getHp()==1
		and getCardsNum("Jink",current,self.player)<1
		and self:slashIsEffective(slash, current, self.player) then
			save_yonglve(self,random_judge(self,current))
			return (true) or false
		end
	end
	return (false) or false
end

ai_skill_invoke.qiangzhi = function(self, options, request)
	return (not self:needKongcheng(self.player, true)) or false
end

sgs.ai_skill_playerchosen.qiangzhi = function(self,targetlist)
	local slash = self:getCard("Slash")
	if slash then
		local dummy_use = dummy()
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local target = dummy_use.to:first()
			if targetlist:contains(target) and target:getHandcardNum()-getKnownNum(target,self.player)<=2 and target:getHandcardNum()<=2 then
				return target
			end
		end
	end

	local cardType = { trick = 0,basic = 0,equip = 0 }
	local turnUse = self:getTurnUse()
	for _,card in ipairs(turnUse)do
		if card:getType()~="skill_card" then cardType[card:getType()] = cardType[card:getType()]+1 end
	end

	local target = {}
	local max_trick,max_basic,max_equip = 0,0,0
	for _,player in sgs.qlist(targetlist)do
		local known = getKnownCard(player,self.player,"TrickCard")
		if cardType.trick>0 and known/player:getHandcardNum()>max_trick then
			max_trick = known
			target.trick = player
		end

		known = getKnownCard(player,self.player,"BasicCard")
		if cardType.basic>0 and known/player:getHandcardNum()>max_basic then
			max_basic = known
			target.basic = player
		end

		known = getKnownCard(player,self.player,"EquipCard")
		if cardType.equip>0 and known/player:getHandcardNum()>max_equip then
			max_equip = known
			target.equip = player
		end
	end

	local max_value = math.max(cardType.trick*max_trick,cardType.basic*max_basic,cardType.equip*max_equip)
	if max_value>0 then
		for cardype,value in pairs(cardType)do
			if max_value==value then return target[cardype] end
		end
	end

	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if targetlist:contains(enemy) then return enemy end
	end

	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(players)
	for _,p in ipairs(players)do
		if not self:isFriend(p) and targetlist:contains(p) then return p end
	end

	self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if targetlist:contains(friend) then return friend end
	end

	return fasle
end

ai_skill_invoke.xiantu = function(self, options, request)
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		if current:isLord() and self:isLordInDanger() then return (true) or false end
		if self.player:getKnownRole()=="renegade" and not self:needToThrowArmor() then return (false) or false end
		if self:getRoleEstimate(current)=="renegade" and not self:needToThrowArmor() then return (false) or false end
		for _,enemy in ipairs(self.enemies)do
			if self:isWeak(enemy) and enemy:getHp()==1 and not self:slashProhibit(nil, enemy, current)
				and (not sgs.isJinkAvailable(current,enemy) or getCardsNum("Jink",enemy,self.player)<1)
				and (getCardsNum("Slash",current,self.player)>=1 or self:getCardsNum("Slash")>0) then
				return (true) or false
			end
		end
		if not self.player:isWounded() and self:isWeak(current) then return (true) or false end
	end
	return false

end

sgs.ai_skill_discard.xiantu = function(self,discard_num,min_num,optional,include_equip)
	local to_exchange = {}
	local current = self.room:getCurrent()
	if self.player:isWounded() and self.player:hasArmorEffect("SilverLion") then table.insert(to_exchange,self.player:getArmor():getEffectiveId()) end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards)
	if getCardsNum("Slash",current,self.player)<1 then
		for _,card in ipairs(cards)do
			if not isCard("Peach",card,self.player) and isCard("Slash",card,current) then
				table.insert(to_exchange,card:getKnownEffectiveId())
			end
		end
	end

	if #to_exchange==2 then return to_exchange end

	for _,card in ipairs(cards)do
		if self.player:hasEquip(card) and self.player:hasSkills(sgs.lose_equip_skill) then
			table.insert(to_exchange,card:getKnownEffectiveId())
			if #to_exchange==2 then return to_exchange end
			break
		end
	end
	for _,card in ipairs(cards)do
		table.insert(to_exchange,card:getKnownEffectiveId())
		if #to_exchange==2 then return to_exchange end
	end
end

sgs.ai_skill_playerchosen.zhongyong = function(self,targetlist)
	self:sort(self.friends)
	if self:getCardsNum("Slash")>0 then
		for _,friend in ipairs(self.friends)do
			if not targetlist:contains(friend) or friend==self.player then continue end
			if getCardsNum("Jink",friend,self.player)<1
			then return friend end
			end
		if self:getCardsNum("Jink")<1 and targetlist:contains(self.player) then return self.player end
	end
	local lord = self.room:getLord()
	if self:isFriend(lord) and self:isLordInDanger() and targetlist:contains(lord) and getCardsNum("Jink",lord,self.player)<2 then return lord end
	if self.player:getKnownRole()=="renegade" and targetlist:contains(self.player) then return self.player end
	return self:findPlayerToDraw(true,1) or self.friends[1]
end

sgs.ai_skill_playerchosen.newzhongyong = function(self,targetlist)
	return sgs.ai_skill_playerchosen.zhongyong(self,targetlist)
end

ai_fill_skill.shenxing = function(self, options, request)
    local inclusive = options and options.inclusive

	self:setPriorityValue("ShenxingCard",3,"shenxing")
	if self.player:getCardCount(true)<2 then return false end
	if self:getOverflow()<=0 then return false end
	if self:isWeak() and self:getOverflow()<=1 then return false end
	return self:legacySkillSeed("shenxing","ShenxingCard",request)
end
ai_card_use.ShenxingCard = function(self, card, use, request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	local red_num,black_num = 0,0
	if self.player:getHp()<3 then
		local zcards = self.player:getCards("he")
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local wansha = self.player:getTag("JilveWansha")
		local keep_slash = wansha~=nil and wansha~=false and wansha~=""
		for _,zcard in sgs.qlist(zcards)do
			if self.player:isCardLimited(zcard, sgs.Card_MethodDiscard) then continue end
			if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
				local shouldUse = true
				if isCard("Slash",zcard,self.player) and not use_slash then
					local dummy_use = dummy()
					self:useBasicCard(zcard,dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.qlist(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					local dummy_use = dummy()
					self:useTrickCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = dummy()
					self:useEquipCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getKnownEffectiveId()==keep_weapon:getKnownEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasTreasure("wooden_ox") then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then
					if (table.contains(unpreferedCards,zcard:getKnownId())) then continue end
					table.insert(unpreferedCards,zcard:getKnownId())
					if self.room:getCardPlace(zcard:getKnownId())==sgs.Player_PlaceHand then
						if zcard:isRed() then red_num = red_num+1
						else black_num = black_num+1 end
					end
				end
				if #unpreferedCards==2 then
					use.card = skill_card(self,"shenxing","ShenxingCard",unpreferedCards,request)
					return
				end
			end
		end
	end

	local red = self:getSuitNum("red")
	local black = self:getSuitNum("black")
	if red-red_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if c:isRed() and (not isCard("Peach",c,self.player) or not self:findFriendsByType(sgs.Friend_Weak) and #cards>1) then
				if self.player:isCardLimited(c, sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,c:getKnownId()) then continue end
				table.insert(unpreferedCards,c:getKnownId())
			end
		end
	elseif black-black_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if c:isBlack() and (not isCard("Peach",c,self.player) or not self:findFriendsByType(sgs.Friend_Weak) and #cards>1) then
				if self.player:isCardLimited(c, sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,c:getKnownId()) then continue end
				table.insert(unpreferedCards,c:getKnownId())
			end
		end
	end

	if #unpreferedCards<2 then
		for _,c in ipairs(cards)do
			if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) then
				if table.contains(unpreferedCards,c:getKnownId()) then continue end
				table.insert(unpreferedCards,c:getKnownId())
			end
			if #unpreferedCards==2 then break end
		end
	end

	if #unpreferedCards==2 then
		use.card = skill_card(self,"shenxing","ShenxingCard",unpreferedCards,request)
		self:setPriorityValue("ShenxingCard",0,"shenxing")
		return
	end

end

sgs.ai_use_priority.ShenxingCard = 3

ai_skill_use["@@bingyi"] = function(self, prompt, request)

	local cards = self.player:getHandcards()
	if cards:length()==0 then return "." end

	if cards:first():isBlack() then
		for _,c in sgs.qlist(cards)do
			if c:isRed() then return "." end
		end
	elseif cards:first():isRed() then
		for _,c in sgs.qlist(cards)do
			if c:isBlack() then return "." end
		end
	end

	self:sort(self.friends)
	local targets = {}
	for _,friend in ipairs(self.friends)do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
			table.insert(targets,friend:objectName())
		end
		if #targets==self.player:getHandcardNum() then break end
	end

	if #targets<self.player:getHandcardNum() then
		for _,enemy in ipairs(self.enemies)do
			if self:needKongcheng(enemy, true) then
				table.insert(targets,enemy:objectName())
			end
		end
	end

	if #targets>0 then
		return response_skill(self,"bingyi","BingyiCard",{},targets)
	end
end

sgs.ai_card_intention.BingyiCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if self:needKongcheng(to, true) then self:updateIntention(from,to,10)
		elseif hasManjuanEffect(to) then continue
		else self:updateIntention(from,to,-10) end
	end
end

sgs.ai_skill_playerchosen.zenhui = function(self,targetlist)
	self:setStrategyMemory("yjcm2014.zenhui_collateral",nil)
	local use = zenhui_use(self)
	local target = use.to:first()
	if not target then return end
	local actual=use.card;use.card=self:evaluateZenhuiCard();if use.card:getClassName()~=actual:getClassName()then ai_unsupported("Zenhui hypothetical changed active card","zenhui")end
	local dummy_use = dummy(true,99,{target})
	self:useCardByClassName(use.card,dummy_use)
	if dummy_use.card and use.card:getClassName()==dummy_use.card:getClassName() and not dummy_use.to:isEmpty() then
		if use.card:isKindOf("Collateral") then
			assert(dummy_use.to:length()==2)
			local player = dummy_use.to:first()
			if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
				self:setStrategyMemory("yjcm2014.zenhui_collateral",dummy_use.to:at(1):objectName())
				return player
			end
			return false
		elseif use.card:isKindOf("Slash") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or not self:slashProhibit(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("FireAttack") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and not self:isFriend(player, target) and not self:isFriend(player) and self:hasTrickEffective(use.card, target, player) then
					return player
				end
			end
			dummy_use.to = sgs.QList2Table(dummy_use.to)
			self:sort(dummy_use.to,"handcard")
			dummy_use.to = sgs.reverse(dummy_use.to)
			local suits = {}
			for _,c in sgs.qlist(self.player:getHandcards())do
				if c:getSuit()<=3 and not table.contains(suits,c:getSuitString()) then table.insert(suits,c:getSuitString()) end
			end
			if #suits<=2 or self:getSuitNum("heart", false, target)>0 and self:getSuitNum("heart")==0 then
				for _,player in ipairs(dummy_use.to)do
					if self:isFriend(player) and targetlist:contains(player) then return player end
				end
			end
		elseif use.card:isKindOf("Duel") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Drowning") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Dismantlement") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) then
					if not self:isFriend(player, target) then
						return player
					elseif not self:needToThrowArmor(target)
						and (target:getJudgingArea():isEmpty()
							or (not target:containsTrick("indulgence")
								and not target:containsTrick("supply_shortage")
								and not (target:containsTrick("lightning") and self:getFinalRetrial(target,"lightning")==1))) then
						return player
					end
				end
			end
		elseif use.card:isKindOf("Snatch") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			local friend = self:findPlayerToDraw(false)
			if friend and targetlist:contains(friend) and self:hasTrickEffective(use.card, target, friend) then
				return friend
			end
		else
		end
	end
	return false
end

sgs.ai_skill_playerchosen.zenhui_collateral = function(self,targetlist)
	local saved=self:getStrategyMemory("yjcm2014.zenhui_collateral")
	if saved then return known(self.room:findPlayerByObjectName(saved),"cached Zenhui collateral victim") end
	return targetlist:at(math.random(0,targetlist:length()-1))
end

sgs.ai_skill_cardask["@zenhui-give"] = function(self,data)
	local use = data:toCardUse()
	local target = use.to:first()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local id = cards[1]:getKnownEffectiveId()

	if use.card:isKindOf("Snatch") then
		if self:isFriend(use.from) then
			if choose_card(self,self.player,"ej","dummyReason") or not borrowed_ai(self,use.from) then
				return "."
			else
				self:sortByUseValue(cards)
				return cards[1]:getKnownEffectiveId()
			end
		elseif not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Slash") then
		if self:slashProhibit(use.card, self.player, use.from)
		or self:ajustDamage(use.from, self.player, 1, use.card)<2 and self:needToLoseHp(self.player, use.from, use.card)
		then
			return "."
		elseif self:isFriend(target) then
			if not self:slashIsEffective(use.card, target, self.player) then
				return id
			end
		elseif not self:isValuableCard(cards[1]) or self:isWeak() or self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card) then
			return id
		end
		return "."
	elseif use.card:isKindOf("Dismantlement") then
		if not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		elseif self:isFriend(use.from) and choose_card(self,self.player,"ej","dummyReason") then
			return "."
		end
		return id
	elseif use.card:isKindOf("Duel") then
		if self:needToLoseHp(self.player, use.from, use.card) then
			return "."
		elseif not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		elseif self:isFriend(use.from) then
			if self:needToLoseHp(use.from, self.player, use.card)
			and self:getCardsNum("Slash")-(cards[1]:isKindOf("Slash") and 1 or 0)>0
			then return "." end
		else
			if self:getCardsNum("Slash")-(cards[1]:isKindOf("Slash") and 1 or 0)>getCardsNum("Slash",use.from,self.player) then
				return "."
			end
		end
		return id
	elseif use.card:isKindOf("FireAttack") then
		if self:needToLoseHp(self.player, use.from, use.card) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Collateral") then
		local victim = self.room:findPlayerByObjectName(self.player:getTag("collateralVictim") or "")
		if sgs.ai_skill_cardask["collateral-slash"](self,nil,nil,victim,use.from)~="."
			and self:isFriend(use.from) or not self:isValuableCard(cards[1]) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Drowning") then
		if self:needToLoseHp(self.player, use.from, use.card) or self:needToThrowArmor() then
			return "."
		elseif self:isValuableCard(cards[1]) and self:isEnemy(use.from) then
			return "."
		end
		return id
	else
	end

	return "."
end

sgs.ai_skill_cardask["@jiaojin"] = function(self,data)
	local damage = data:toDamage()
	if self:damageStruct(damage)
	and not self:needToLoseHp(damage.to, damage.from, damage.card)
	then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if c:getTypeId()==sgs.Card_TypeEquip then return c:getKnownEffectiveId() end
		end
	end
	return "."
end

ai_skill_choice.qieting = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local target = self.room:getCurrent()
	local id = choose_card(self,target,"e","dummyReason")
	if id then
		for i = 0,4 do
			if target:getEquip(i) and target:getEquip(i):getEffectiveId()==id and string.find(choices,i) then
				return ai_choice_result((i), options)
			end
		end
	end
	return ai_choice_result(("draw"), options)
end


ai_fill_skill.xianzhou = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getEquips():isEmpty() then return end
	return skill_card(self,"xianzhou","XianzhouCard",{},request)
end

ai_card_use.XianzhouCard = function(self, card, use, request)
	if self:isWeak() then
		for _,friend in ipairs(self.friends_noself)do
			if friend:hasSkills(sgs.need_equip_skill) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
		self:sort(self.friends)
		for _,target in sgs.qlist(self.room:getOtherPlayers(self.player))do
			local canUse = true
			for _,friend in ipairs(self.friends)do
				if target:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, target)
				and not self:needToLoseHp(friend, target)
				then canUse = false break end
			end
			if canUse then
				use.card = card
				use.to:append(target)
				return
			end
		end
	end
	if not self.player:isWounded() then
		local killer
		self:sort(self.friends_noself)
		for _,target in sgs.qlist(self.room:getOtherPlayers(self.player))do
			local canUse = false
			for _,friend in ipairs(self.friends_noself)do
				if friend:inMyAttackRange(target) and self:damageIsEffective(target, nil, friend)
					and not self:needToLoseHp(target, friend) and self:isWeak(target) then
					canUse = true
					killer = friend
					break
				end
			end
			if canUse then
				use.card = card
				use.to:append(killer)
				return
			end
		end
	end

	if #self.friends_noself==0 then return end
	if self.player:getEquips():length()>2 or self.player:getEquips():length()>#self.enemies and self.room:getTurnCount()>2 then
		local function cmp_AttackRange(a,b)
			local ar_a = a:getAttackRange()
			local ar_b = b:getAttackRange()
			if ar_a==ar_b then
				return self:getDefense(a)>self:getDefense(b)
			else
				return ar_a>ar_b
			end
		end
		table.sort(self.friends_noself,cmp_AttackRange)
		use.card = card
		use.to:append(self.friends_noself[1])
	end
end

sgs.ai_use_priority.XianzhouCard = 4.9
sgs.ai_card_intention.XianzhouCard = function(self,card,from,tos)
	if not from:isWounded() then self:updateIntentions(from,tos,-10) end
end

ai_skill_use["@xianzhou"] = function(self, prompt, request)
	local prompt = prompt:split(":")
	local num = prompt[#prompt]
	local current = self.room:getCurrent()
	if self:isWeak(current) and self:isFriend(current) then return "." end
	local targets = {}
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if self.player:inMyAttackRange(enemy) and self:damageIsEffective(enemy, nil, self.player)
		and not self:needToLoseHp(enemy, self.player)
		then
			table.insert(targets,enemy:objectName())
			if #targets==tonumber(num) then break end
		end
	end
	if #targets<tonumber(num) then
		self:sort(self.friends_noself)
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,friend in ipairs(self.friends_noself)do
			if self.player:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, self.player)
            and not self:needToLoseHp(friend, self.player)
			then
				table.insert(targets,friend:objectName())
				if #targets==tonumber(num) then break end
			end
		end
	end
	if #targets<tonumber(num) then
		for _,target in sgs.qlist(self.room:getAlivePlayers())do
			if not self:isFriend(target) and self:isWeak(target) then
				table.insert(targets,target:objectName())
			end
		end
	end

	if #targets>0 and #targets==tonumber(num) then
		return response_skill(self,"xianzhou-damage","XianzhouDamageCard",{},targets)
	end
	return "."
end

sgs.ai_card_intention.XianzhouDamageCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if self:damageIsEffective(to, nil, from) and not self:needToLoseHp(to, from) then
			self:updateIntention(from,to,10)
		end
	end
end

ai_skill_invoke.jianying = function(self, options, request)
	return (not self:needKongcheng(self.player, true)) or false
end

sgs.ai_skill_playerchosen.youdi = function(self,targets)
	self.youdi_obtain_to_friend = false
	local throw_armor = self:needToThrowArmor()
	if throw_armor and #self.friends_noself>0 and self.player:getCardCount(true)>1 then
		for _,friend in ipairs(self.friends_noself)do
			if friend:canDiscard(self.player, self.player:getArmor():getEffectiveId())
				and (self:needToThrowArmor(friend) or (self:needKongcheng(friend) and friend:getHandcardNum()==1)
					or friend:getHandcardNum()<=self:getLeastHandcardNum(friend)) then
				return friend
			end
		end
	end

	local valuable,dangerous = self:getValuableCard(self.player),self:getDangerousCard(self.player)
	local slash_ratio = 0
	if not self.player:isKongcheng() then
		local slash_count = 0
		for _,c in sgs.qlist(self.player:getHandcards())do
			if c:isKindOf("Slash") then slash_count = slash_count+1 end
		end
		slash_ratio = slash_count/self.player:getHandcardNum()
	end
	if not valuable and not dangerous and slash_ratio>0.45 then return nil end

	self:sort(self.enemies,"defense")
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy, "he") then
			if (valuable and enemy:canDiscard(self.player, valuable)) or (dangerous and enemy:canDiscard(self.player, dangerous)) then
				if (self:getValuableCard(enemy) or self:getDangerousCard(enemy)) and self:getDefense(enemy)>8 then return enemy end
			elseif not enemy:isNude() then return enemy
			end
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.youdi_obtain = sgs.ai_choicemade_filter.cardChosen.snatch
sgs.ai_skill_cardchosen.yonglve=function(self,who,flags,method)
    local id,present=self:getStrategyMemory("yjcm2014.yonglve_cardchosen")
    if not present or id==nil then return end
    self:setStrategyMemory("yjcm2014.yonglve_cardchosen",nil)
    self:useKnowledgeEstimate({value=id,status="estimate",basis="viewer_local_yonglve_cardchosen_without_cross_viewer_global_writes"},"yonglve")
    return id
end
