-- Fixed donor b6025acc: yjcm2014-ai.lua. Policy uses pure views; only
-- current native action receipts authorize costs/targets. No legacy fallback.
local function known(value,key)
    if AIUnsupported.is(value)then error(value,0)end
    if value==nil then ai_unsupported('yjcm2014 fact is unknown',key)end
    return value
end
local function q(object,method,...)
    if AIValue.isPlayer(object)then
        if method=='getMark'then method='getStrategyMark'
        elseif method=='hasFlag'then method='getStrategyFlag'end
    end
    if not object or type(object[method])~='function'then ai_unsupported('yjcm2014 method is unavailable',method)end
    return known(object[method](object,...),method)
end
local function dummy(is_dummy,extra,current)
    local use=AIUsePlan.new();use.isDummy=is_dummy~=false;use.extra_target=extra or 0;use.current_targets=current or{};return use
end
local function fact(self,name)
    return known(self.world.strategy_facts and self.world.strategy_facts.standard and self.world.strategy_facts.standard[name],name)
end
local function visible(self,id)
    id=tonumber(id)
    return known(self:getChoiceCard(id)or self:getKnownCardById(id),'disclosed card '..tostring(id))
end
local function skill_card(self,skill,class,costs,request)
    local authority=q(self,'bindSkillCard',skill,costs,request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=visible(self,costs[1]);suit,number=q(c,'getSuit'),q(c,'getNumber')
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs)do local c=visible(self,id);red,black=red and q(c,'isRed'),black and q(c,'isBlack')end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]='spade',[sgs.Card_Club]='club',[sgs.Card_Heart]='heart',[sgs.Card_Diamond]='diamond',[sgs.Card_NoSuitBlack]='no_suit_black',[sgs.Card_NoSuitRed]='no_suit_red',[sgs.Card_NoSuit]='no_suit'}
    local ns=({[1]='A',[11]='J',[12]='Q',[13]='K'})[number]or tostring(number)
    local key='@'..class..'['..known(suits[suit],'skill policy suit')..':'..ns..']='..(#costs>0 and table.concat(costs,'+')or'.')
    return q(self,'legacyPolicyCard',authority,{name='',class_name=class,type_id=0,kind_of={class,'SkillCard','Card'},
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
    local result=q(self,'recommendCardChosen',player,flags,reason,method)
    if result.zone=='none'then return -1 end -- donor getCardRandomly empty sentinel is truthy.
    return known(result.id,'public chosen card')
end
local function random_judge(self,player)
    local ids={};local disabled=self.disabled_ids or self:getStrategyMemory('discard_disabled_ids')or{}
    for _,card in ipairs(q(player,'getJudgingArea'))do
        local id=q(card,'getEffectiveId');if not table.contains(disabled,id)then ids[#ids+1]=id end
    end
    if #ids<1 then return -1 end
    local index=math.random(1,#ids);local id=ids[index]
    local card=visible(self,id)
    if q(card,'isKindOf','SilverLion')and q(player,'isWounded')and q(self,'isEnemy',player)and q(player,'hasArmorEffect','SilverLion')then
        if index~=#ids then id=ids[index+1]elseif index>1 then id=ids[index-1]end
    end
    return id
end
local function save_yonglve(self,id)
    self:setStrategyMemory('yjcm2014.yonglve_cardchosen',id)
    self:useKnowledgeEstimate({value=id,status='estimate',basis='viewer_local_yonglve_cardchosen_without_cross_viewer_global_writes'},'yonglve')
end
local function zenhui_use(self)
    local row=fact(self,'zenhui_use')
    local use={card=known(CardView.new(row.card),'Zenhui active card'),to=AIList.new({})}
    use.from=known(self.room:findPlayerByObjectName(row.from),'Zenhui source')
    for _,name in ipairs(row.to)do use.to:append(known(self.room:findPlayerByObjectName(name),'Zenhui target'))end
    return use
end
local function borrowed_ai(self,player)
    return known(fact(self,'player_has_ai')[q(player,'objectName')],'player AI presence')
end

sgs.ai_fill_skill.dingpin = function(self,inclusive,request)
	self:setPriorityValue("DingpinCard",0,"dingpin")
	--if not q(self.player,"canDiscard",self.player,"h") or q(self.player,"getMark","dingpin")==0xE then return false end
	if not q(self.player,"canDiscard",self.player,"h") then return false end
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers"))do
		if not q(p,"hasFlag","dingpin") and q(p,"isWounded") then
			if not q(self,"toTurnOver",self.player) then self:setPriorityValue("DingpinCard",8.9,"dingpin") end
			return self:legacySkillSeed("dingpin","DingpinCard",request)
		end
	end
end
sgs.ai_skill_use_func.DingpinCard = function(card,use,self,request)
	local cards = {}
	local cardType = {}
	for _,card in sgs.qlist(q(self.player,"getHandcards"))do
		--if (q(self.player,"getMark","dingpin") & (1 << q(card,"getTypeId")))==0 then
		if q(self.player,"canDiscard",self.player,q(card,"getEffectiveId")) and q(self.player,"getMark","dingpin_"..q(card,"getType").."-Clear")==0 then
			table.insert(cards,card)
			if not table.contains(cardType,q(card,"getTypeId")) then table.insert(cardType,q(card,"getTypeId")) end
		end
	end

	if #cards==0 then return end
	self:sortByUseValue(cards,true)
	if q(self,"isValuableCard",cards[1]) then return end

	if #cardType>1 or not q(self,"toTurnOver",self.player) then
		self:sort(self.friends)
		for _,friend in ipairs(self.friends)do
			if not q(friend,"hasFlag","dingpin") and q(friend,"isWounded") then
				use.card = skill_card(self,"dingpin","DingpinCard",{q(cards[1],"getEffectiveId")},request)
				use.to:append(friend)
				return
			end
		end
	end

end

sgs.ai_use_priority.DingpinCard = 0
sgs.ai_card_intention.DingpinCard = -10

sgs.ai_skill_invoke.faen = function(self,data)
	local player = q(data,"toPlayer")
	if q(self,"needKongcheng",player,true) then return not q(self,"isFriend",player) end
	return q(self,"isFriend",player)
end

sgs.ai_choicemade_filter.skillInvoke.faen = function(self,player,promptlist)
	local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
	if not target then return end
	local yes = promptlist[#promptlist]=="yes"
	if q(self,"needKongcheng",target,true) then
		self:updateIntention(player,target,yes and 10 or -10)
	else
		self:updateIntention(player,target,yes and -10 or 10)
	end
end

sgs.ai_skill_invoke.sidi = true

sgs.ai_skill_use["@@sidi"] = function(self)
	local current = self.room:getCurrent()
	if q(self,"isEnemy",current) then
		if (getCardsNum("Slash",current,self.player)>0 or q(self.player,"getPile","sidi"):length()>1)
		and not q(self,"hasCrossbowEffect",current) then
			for _,p in sgs.qlist(q(self.room,"getOtherPlayers",current))do
				if q(self,"isFriend",p) and q(current,"distanceTo",p)<=q(current,"getAttackRange")
				and q(self,"slashIsEffective",self:getEvaluationCard("slash"),p)
				and (q(self,"isWeak",p) or q(self.player,"getPile","sidi"):length()>1) then
					return response_skill(self,"sidi","SidiCard",{q(self.player,"getPile","sidi"):first()})
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["@ol_sidi-discard"] = function(self,data,pattern)
	local target = self.room:getCurrent()
    local cards = q(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if q(self,"isEnemy",target) and #cards>1
		and q(self,"matchGuanxingPattern",pattern,self.player,h)
    	then return q(h,"getEffectiveId") end
	end
    return "."
end

sgs.ai_skill_use["@@shenduan"] = function(self)
	for _,id in ipairs(fact(self,"shenduan_for_ai"):split("+"))do
		local card = visible(self,id)
		local card_str = ("supply_shortage:shenduan[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),id)
		local ss = self:bindTurnConversion("shenduan","SupplyShortage",{name="supply_shortage",skill="shenduan",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={tonumber(id)}})
		if q(self.player,"isCardLimited",ss,sgs.Card_MethodUse) then continue end
		local dummy_use = dummy()
		self:useCardSupplyShortage(ss,dummy_use)
		if dummy_use.card and not q(dummy_use.to,"isEmpty") then
			local selected=dummy(false);selected.card=dummy_use.card;selected.to:append(q(dummy_use.to,"first"));return q(selected,"toAnswer")
		end
	end
	return "."
end

sgs.ai_skill_invoke.yonglve = function(self)
	local current = self.room:getCurrent()
	local slash = self:evaluateSkillCard("_yonglve","slash",{})
	if q(self,"isFriend",current)
	and choose_card(self,current,"j","dummyReason",sgs.Card_MethodDiscard) then
		if not q(self,"slashIsEffective",slash,current,self.player) then return true end
		if not q(self,"isWeak",current) or getKnownCard(current,self.player,"Jink")>0 then return true end
	elseif q(self,"isEnemy",current) then
		if choose_card(self,current,"j","dummyReason",sgs.Card_MethodDiscard) then return true end
		for _,card in sgs.qlist(q(current,"getJudgingArea"))do
			if q(card,"isKindOf","SupplyShortage")
			and (q(current,"getHandcardNum")>4 or q(current,"containsTrick","indulgence")) then
				save_yonglve(self,q(card,"getEffectiveId"))
				return true
			elseif q(card,"isKindOf","Indulgence")
			and q(current,"getHandcardNum")+q(self,"ImitateResult_DrawNCards",current)<=q(self,"getOverflow",current,true) then
				save_yonglve(self,q(card,"getEffectiveId"))
				return true
			end
		end
		if q(self,"isWeak",current) and q(current,"getHp")==1
		and getCardsNum("Jink",current,self.player)<1
		and q(self,"slashIsEffective",slash,current,self.player) then
			save_yonglve(self,random_judge(self,current))
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.qiangzhi = function(self)
	return not q(self,"needKongcheng",self.player,true)
end

sgs.ai_skill_playerchosen.qiangzhi = function(self,targetlist)
	local slash = self:getCard("Slash")
	if slash then
		local dummy_use = dummy()
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and not q(dummy_use.to,"isEmpty") then
			local target = q(dummy_use.to,"first")
			if q(targetlist,"contains",target) and q(target,"getHandcardNum")-getKnownNum(target,self.player)<=2 and q(target,"getHandcardNum")<=2 then
				return target
			end
		end
	end

	local cardType = { trick = 0,basic = 0,equip = 0 }
	local turnUse = q(self,"getTurnUse")
	for _,card in ipairs(turnUse)do
		if q(card,"getType")~="skill_card" then cardType[q(card,"getType")] = cardType[q(card,"getType")]+1 end
	end

	local target = {}
	local max_trick,max_basic,max_equip = 0,0,0
	for _,player in sgs.qlist(targetlist)do
		local known = getKnownCard(player,self.player,"TrickCard")
		if cardType.trick>0 and known/q(player,"getHandcardNum")>max_trick then
			max_trick = known
			target.trick = player
		end

		known = getKnownCard(player,self.player,"BasicCard")
		if cardType.basic>0 and known/q(player,"getHandcardNum")>max_basic then
			max_basic = known
			target.basic = player
		end

		known = getKnownCard(player,self.player,"EquipCard")
		if cardType.equip>0 and known/q(player,"getHandcardNum")>max_equip then
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
		if q(targetlist,"contains",enemy) then return enemy end
	end

	local players = sgs.QList2Table(q(self.room,"getOtherPlayers",self.player))
	self:sort(players)
	for _,p in ipairs(players)do
		if not q(self,"isFriend",p) and q(targetlist,"contains",p) then return p end
	end

	self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if q(targetlist,"contains",friend) then return friend end
	end

	return fasle
end

sgs.ai_skill_invoke.xiantu = function(self)
	local current = self.room:getCurrent()
	if q(self,"isFriend",current) then
		if q(current,"isLord") and q(self,"isLordInDanger") then return true end
		if q(self.player,"getRole")=="renegade" and not q(self,"needToThrowArmor") then return false end
		if self:getRoleEstimate(current)=="renegade" and not q(self,"needToThrowArmor") then return false end
		for _,enemy in ipairs(self.enemies)do
			if q(self,"isWeak",enemy) and q(enemy,"getHp")==1 and not q(self,"slashProhibit",nil,enemy,current)
				and (not sgs.isJinkAvailable(current,enemy) or getCardsNum("Jink",enemy,self.player)<1)
				and (getCardsNum("Slash",current,self.player)>=1 or q(self,"getCardsNum","Slash")>0) then
				return true
			end
		end
		if not q(self.player,"isWounded") and q(self,"isWeak",current) then return true end
	end
end

sgs.ai_skill_discard.xiantu = function(self,discard_num,min_num,optional,include_equip)
	local to_exchange = {}
	local current = self.room:getCurrent()
	if q(self.player,"isWounded") and q(self.player,"hasArmorEffect","SilverLion") then table.insert(to_exchange,self.player:getArmor():getEffectiveId()) end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	self:sortByUseValue(cards)
	if getCardsNum("Slash",current,self.player)<1 then
		for _,card in ipairs(cards)do
			if not isCard("Peach",card,self.player) and isCard("Slash",card,current) then
				table.insert(to_exchange,q(card,"getEffectiveId"))
			end
		end
	end

	if #to_exchange==2 then return to_exchange end

	for _,card in ipairs(cards)do
		if q(self.player,"hasEquip",card) and q(self.player,"hasSkills",sgs.lose_equip_skill) then
			table.insert(to_exchange,q(card,"getEffectiveId"))
			if #to_exchange==2 then return to_exchange end
			break
		end
	end
	for _,card in ipairs(cards)do
		table.insert(to_exchange,q(card,"getEffectiveId"))
		if #to_exchange==2 then return to_exchange end
	end
end

sgs.ai_skill_playerchosen.zhongyong = function(self,targetlist)
	self:sort(self.friends)
	if q(self,"getCardsNum","Slash")>0 then
		for _,friend in ipairs(self.friends)do
			if not q(targetlist,"contains",friend) or friend==self.player then continue end
			if getCardsNum("Jink",friend,self.player)<1
			then return friend end
			end
		if q(self,"getCardsNum","Jink")<1 and q(targetlist,"contains",self.player) then return self.player end
	end
	local lord = self.room:getLord()
	if q(self,"isFriend",lord) and q(self,"isLordInDanger") and q(targetlist,"contains",lord) and getCardsNum("Jink",lord,self.player)<2 then return lord end
	if q(self.player,"getRole")=="renegade" and q(targetlist,"contains",self.player) then return self.player end
	return self:findPlayerToDraw(true,1) or self.friends[1]
end

sgs.ai_skill_playerchosen.newzhongyong = function(self,targetlist)
	return sgs.ai_skill_playerchosen.zhongyong(self,targetlist)
end

sgs.ai_fill_skill.shenxing = function(self,inclusive,request)
	self:setPriorityValue("ShenxingCard",3,"shenxing")
	if q(self.player,"getCardCount",true)<2 then return false end
	if q(self,"getOverflow")<=0 then return false end
	if q(self,"isWeak") and q(self,"getOverflow")<=1 then return false end
	return self:legacySkillSeed("shenxing","ShenxingCard",request)
end
sgs.ai_skill_use_func.ShenxingCard = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	self:sortByKeepValue(cards)

	local red_num,black_num = 0,0
	if q(self.player,"getHp")<3 then
		local zcards = q(self.player,"getCards","he")
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = fact(self,"jilve_wansha")
		for _,zcard in sgs.qlist(zcards)do
			if q(self.player,"isCardLimited",zcard,sgs.Card_MethodDiscard) then continue end
			if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
				local shouldUse = true
				if isCard("Slash",zcard,self.player) and not use_slash then
					local dummy_use = dummy()
					self:useBasicCard(zcard,dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.qlist(dummy_use.to)do
								if q(p,"getHp")<=1 then
									shouldUse = false
									if q(self.player,"distanceTo",p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if q(dummy_use.to,"length")>1 then shouldUse = false end
						end
						if not q(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if q(zcard,"getTypeId")==sgs.Card_TypeTrick then
					local dummy_use = dummy()
					self:useTrickCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if q(zcard,"getTypeId")==sgs.Card_TypeEquip and not q(self.player,"hasEquip",zcard) then
					local dummy_use = dummy()
					self:useEquipCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and q(zcard,"getEffectiveId")==q(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","Armor") and not q(self,"needToThrowArmor") then shouldUse = false end
				if q(self.player,"hasTreasure","wooden_ox") then shouldUse = false end
				if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","DefensiveHorse") and not q(self,"needToThrowArmor") then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if q(self.player,"getHp")==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then
					if (table.contains(unpreferedCards,q(zcard,"getId"))) then continue end
					table.insert(unpreferedCards,q(zcard,"getId"))
					if q(self.room,"getCardPlace",q(zcard,"getId"))==sgs.Player_PlaceHand then
						if q(zcard,"isRed") then red_num = red_num+1
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

	local red = q(self,"getSuitNum","red")
	local black = q(self,"getSuitNum","black")
	if red-red_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if q(c,"isRed") and (not isCard("Peach",c,self.player) or not q(self,"findFriendsByType",sgs.Friend_Weak) and #cards>1) then
				if q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,q(c,"getId")) then continue end
				table.insert(unpreferedCards,q(c,"getId"))
			end
		end
	elseif black-black_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if q(c,"isBlack") and (not isCard("Peach",c,self.player) or not q(self,"findFriendsByType",sgs.Friend_Weak) and #cards>1) then
				if q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,q(c,"getId")) then continue end
				table.insert(unpreferedCards,q(c,"getId"))
			end
		end
	end

	if #unpreferedCards<2 then
		for _,c in ipairs(cards)do
			if not q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then
				if table.contains(unpreferedCards,q(c,"getId")) then continue end
				table.insert(unpreferedCards,q(c,"getId"))
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

sgs.ai_skill_use["@@bingyi"] = function(self)

	local cards = q(self.player,"getHandcards")
	if q(cards,"length")==0 then return "." end

	if q(cards,"first"):isBlack() then
		for _,c in sgs.qlist(cards)do
			if q(c,"isRed") then return "." end
		end
	elseif q(cards,"first"):isRed() then
		for _,c in sgs.qlist(cards)do
			if q(c,"isBlack") then return "." end
		end
	end

	self:sort(self.friends)
	local targets = {}
	for _,friend in ipairs(self.friends)do
		if not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true) then
			table.insert(targets,q(friend,"objectName"))
		end
		if #targets==q(self.player,"getHandcardNum") then break end
	end

	if #targets<q(self.player,"getHandcardNum") then
		for _,enemy in ipairs(self.enemies)do
			if q(self,"needKongcheng",enemy,true) then
				table.insert(targets,q(enemy,"objectName"))
			end
		end
	end

	if #targets>0 then
		return response_skill(self,"bingyi","BingyiCard",{},targets)
	end
end

sgs.ai_card_intention.BingyiCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if q(self,"needKongcheng",to,true) then self:updateIntention(from,to,10)
		elseif hasManjuanEffect(to) then continue
		else self:updateIntention(from,to,-10) end
	end
end

sgs.ai_skill_playerchosen.zenhui = function(self,targetlist)
	self:setStrategyMemory("yjcm2014.zenhui_collateral",nil)
	local use = zenhui_use(self)
	local target = use.to:first()
	if not target then return end
	local actual=use.card;use.card=q(self,"evaluateZenhuiCard");if q(use.card,"getClassName")~=q(actual,"getClassName")then ai_unsupported("Zenhui hypothetical changed active card","zenhui")end
	local dummy_use = dummy(true,99,{target})
	self:useCardByClassName(use.card,dummy_use)
	if dummy_use.card and q(use.card,"getClassName")==q(dummy_use.card,"getClassName") and not q(dummy_use.to,"isEmpty") then
		if q(use.card,"isKindOf","Collateral") then
			assert(q(dummy_use.to,"length")==2)
			local player = q(dummy_use.to,"first")
			if q(targetlist,"contains",player) and (q(self,"isFriend",player) or q(self,"hasTrickEffective",use.card,target,player)) then
				self:setStrategyMemory("yjcm2014.zenhui_collateral",q(dummy_use.to,"at",1):objectName())
				return player
			end
			return false
		elseif q(use.card,"isKindOf","Slash") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and (q(self,"isFriend",player) or not q(self,"slashProhibit",use.card,target,player)) then
					return player
				end
			end
		elseif q(use.card,"isKindOf","FireAttack") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and not q(self,"isFriend",player,target) and not q(self,"isFriend",player) and q(self,"hasTrickEffective",use.card,target,player) then
					return player
				end
			end
			dummy_use.to = sgs.QList2Table(dummy_use.to)
			self:sort(dummy_use.to,"handcard")
			dummy_use.to = sgs.reverse(dummy_use.to)
			local suits = {}
			for _,c in sgs.qlist(q(self.player,"getHandcards"))do
				if q(c,"getSuit")<=3 and not table.contains(suits,q(c,"getSuitString")) then table.insert(suits,q(c,"getSuitString")) end
			end
			if #suits<=2 or q(self,"getSuitNum","heart",false,target)>0 and q(self,"getSuitNum","heart")==0 then
				for _,player in ipairs(dummy_use.to)do
					if q(self,"isFriend",player) and q(targetlist,"contains",player) then return player end
				end
			end
		elseif q(use.card,"isKindOf","Duel") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and (q(self,"isFriend",player) or q(self,"hasTrickEffective",use.card,target,player)) then
					return player
				end
			end
		elseif q(use.card,"isKindOf","Drowning") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and (q(self,"isFriend",player) or q(self,"hasTrickEffective",use.card,target,player)) then
					return player
				end
			end
		elseif q(use.card,"isKindOf","Dismantlement") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and q(self,"isFriend",player) then
					return player
				end
			end
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) then
					if not q(self,"isFriend",player,target) then
						return player
					elseif not q(self,"needToThrowArmor",target)
						and (q(target,"getJudgingArea"):isEmpty()
							or (not q(target,"containsTrick","indulgence")
								and not q(target,"containsTrick","supply_shortage")
								and not (q(target,"containsTrick","lightning") and self:getFinalRetrial(target,"lightning")==1))) then
						return player
					end
				end
			end
		elseif q(use.card,"isKindOf","Snatch") then
			for _,player in sgs.qlist(dummy_use.to)do
				if q(targetlist,"contains",player) and q(self,"isFriend",player) then
					return player
				end
			end
			local friend = self:findPlayerToDraw(false)
			if friend and q(targetlist,"contains",friend) and q(self,"hasTrickEffective",use.card,target,friend) then
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
	return q(targetlist,"at",math.random(0,q(targetlist,"length")-1))
end

sgs.ai_skill_cardask["@zenhui-give"] = function(self,data)
	local use = q(data,"toCardUse")
	local target = q(use.to,"first")
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	self:sortByKeepValue(cards)
	local id = q(cards[1],"getEffectiveId")

	if q(use.card,"isKindOf","Snatch") then
		if q(self,"isFriend",use.from) then
			if choose_card(self,self.player,"ej","dummyReason") or not borrowed_ai(self,use.from) then
				return "."
			else
				self:sortByUseValue(cards)
				return q(cards[1],"getEffectiveId")
			end
		elseif not q(self,"hasTrickEffective",use.card,self.player,use.from) then
			return "."
		end
		return id
	elseif q(use.card,"isKindOf","Slash") then
		if q(self,"slashProhibit",use.card,self.player,use.from)
		or q(self,"ajustDamage",use.from,self.player,1,use.card)<2 and q(self,"needToLoseHp",self.player,use.from,use.card)
		then
			return "."
		elseif q(self,"isFriend",target) then
			if not q(self,"slashIsEffective",use.card,target,self.player) then
				return id
			end
		elseif not q(self,"isValuableCard",cards[1]) or q(self,"isWeak") or q(self,"getCardsNum","Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card) then
			return id
		end
		return "."
	elseif q(use.card,"isKindOf","Dismantlement") then
		if not q(self,"hasTrickEffective",use.card,self.player,use.from) then
			return "."
		elseif q(self,"isFriend",use.from) and choose_card(self,self.player,"ej","dummyReason") then
			return "."
		end
		return id
	elseif q(use.card,"isKindOf","Duel") then
		if q(self,"needToLoseHp",self.player,use.from,use.card) then
			return "."
		elseif not q(self,"hasTrickEffective",use.card,self.player,use.from) then
			return "."
		elseif q(self,"isFriend",use.from) then
			if q(self,"needToLoseHp",use.from,self.player,use.card)
			and q(self,"getCardsNum","Slash")-(q(cards[1],"isKindOf","Slash") and 1 or 0)>0
			then return "." end
		else
			if q(self,"getCardsNum","Slash")-(q(cards[1],"isKindOf","Slash") and 1 or 0)>getCardsNum("Slash",use.from,self.player) then
				return "."
			end
		end
		return id
	elseif q(use.card,"isKindOf","FireAttack") then
		if q(self,"needToLoseHp",self.player,use.from,use.card) then
			return "."
		end
		return id
	elseif q(use.card,"isKindOf","Collateral") then
		local victim = self.room:findPlayerByObjectName(fact(self,"collateral_victim"))
		if sgs.ai_skill_cardask["collateral-slash"](self,nil,nil,victim,use.from)~="."
			and q(self,"isFriend",use.from) or not q(self,"isValuableCard",cards[1]) then
			return "."
		end
		return id
	elseif q(use.card,"isKindOf","Drowning") then
		if q(self,"needToLoseHp",self.player,use.from,use.card) or q(self,"needToThrowArmor") then
			return "."
		elseif q(self,"isValuableCard",cards[1]) and q(self,"isEnemy",use.from) then
			return "."
		end
		return id
	else
	end

	return "."
end

sgs.ai_skill_cardask["@jiaojin"] = function(self,data)
	local damage = q(data,"toDamage")
	if q(self,"damageStruct",damage)
	and not q(self,"needToLoseHp",damage.to,damage.from,damage.card)
	then
		local cards = sgs.QList2Table(q(self.player,"getCards","he"))
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if q(c,"getTypeId")==sgs.Card_TypeEquip then return q(c,"getEffectiveId") end
		end
	end
	return "."
end

sgs.ai_skill_choice.qieting = function(self,choices)
	local target = self.room:getCurrent()
	local id = choose_card(self,target,"e","dummyReason")
	if id then
		for i = 0,4 do
			if target:getEquip(i) and target:getEquip(i):getEffectiveId()==id and string.find(choices,i) then
				return i
			end
		end
	end
	return "draw"
end


sgs.ai_fill_skill.xianzhou = function(self,inclusive,request)
	if q(self.player,"getEquips"):isEmpty() then return end
	return skill_card(self,"xianzhou","XianzhouCard",{},request)
end

sgs.ai_skill_use_func.XianzhouCard = function(card,use,self,request)
	if q(self,"isWeak") then
		for _,friend in ipairs(self.friends_noself)do
			if q(friend,"hasSkills",sgs.need_equip_skill) then
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
		for _,target in sgs.qlist(q(self.room,"getOtherPlayers",self.player))do
			local canUse = true
			for _,friend in ipairs(self.friends)do
				if q(target,"inMyAttackRange",friend) and q(self,"damageIsEffective",friend,nil,target)
				and not q(self,"needToLoseHp",friend,target)
				then canUse = false break end
			end
			if canUse then
				use.card = card
				use.to:append(target)
				return
			end
		end
	end
	if not q(self.player,"isWounded") then
		local killer
		self:sort(self.friends_noself)
		for _,target in sgs.qlist(q(self.room,"getOtherPlayers",self.player))do
			local canUse = false
			for _,friend in ipairs(self.friends_noself)do
				if q(friend,"inMyAttackRange",target) and q(self,"damageIsEffective",target,nil,friend)
					and not q(self,"needToLoseHp",target,friend) and q(self,"isWeak",target) then
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
	if q(self.player,"getEquips"):length()>2 or q(self.player,"getEquips"):length()>#self.enemies and q(self.room,"getTurnCount")>2 then
		local function cmp_AttackRange(a,b)
			local ar_a = q(a,"getAttackRange")
			local ar_b = q(b,"getAttackRange")
			if ar_a==ar_b then
				return q(self,"getDefense",a)>q(self,"getDefense",b)
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
	if not q(from,"isWounded") then self:updateIntentions(from,tos,-10) end
end

sgs.ai_skill_use["@xianzhou"] = function(self,prompt)
	local prompt = q(prompt,"split",":")
	local num = prompt[#prompt]
	local current = self.room:getCurrent()
	if q(self,"isWeak",current) and q(self,"isFriend",current) then return "." end
	local targets = {}
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if q(self.player,"inMyAttackRange",enemy) and q(self,"damageIsEffective",enemy,nil,self.player)
		and not q(self,"needToLoseHp",enemy,self.player)
		then
			table.insert(targets,q(enemy,"objectName"))
			if #targets==tonumber(num) then break end
		end
	end
	if #targets<tonumber(num) then
		self:sort(self.friends_noself)
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,friend in ipairs(self.friends_noself)do
			if q(self.player,"inMyAttackRange",friend) and q(self,"damageIsEffective",friend,nil,self.player)
 			and not q(self,"needToLoseHp",friend,self.player)
			then
				table.insert(targets,q(friend,"objectName"))
				if #targets==tonumber(num) then break end
			end
		end
	end
	if #targets<tonumber(num) then
		for _,target in sgs.qlist(q(self.room,"getAlivePlayers"))do
			if not q(self,"isFriend",target) and q(self,"isWeak",target) then
				table.insert(targets,q(target,"objectName"))
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
		if q(self,"damageIsEffective",to,nil,from) and not q(self,"needToLoseHp",to,from) then
			self:updateIntention(from,to,10)
		end
	end
end

sgs.ai_skill_invoke.jianying = function(self)
	return not q(self,"needKongcheng",self.player,true)
end

sgs.ai_skill_playerchosen.youdi = function(self,targets)
	self.youdi_obtain_to_friend = false
	local throw_armor = q(self,"needToThrowArmor")
	if throw_armor and #self.friends_noself>0 and q(self.player,"getCardCount",true)>1 then
		for _,friend in ipairs(self.friends_noself)do
			if q(friend,"canDiscard",self.player,self.player:getArmor():getEffectiveId())
				and (q(self,"needToThrowArmor",friend) or (q(self,"needKongcheng",friend) and q(friend,"getHandcardNum")==1)
					or q(friend,"getHandcardNum")<=q(self,"getLeastHandcardNum",friend)) then
				return friend
			end
		end
	end

	local valuable,dangerous = self:getValuableCard(self.player),self:getDangerousCard(self.player)
	local slash_ratio = 0
	if not q(self.player,"isKongcheng") then
		local slash_count = 0
		for _,c in sgs.qlist(q(self.player,"getHandcards"))do
			if q(c,"isKindOf","Slash") then slash_count = slash_count+1 end
		end
		slash_ratio = slash_count/q(self.player,"getHandcardNum")
	end
	if not valuable and not dangerous and slash_ratio>0.45 then return nil end

	self:sort(self.enemies,"defense")
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if q(self,"doDisCard",enemy,"he") then
			if (valuable and q(enemy,"canDiscard",self.player,valuable)) or (dangerous and q(enemy,"canDiscard",self.player,dangerous)) then
				if (self:getValuableCard(enemy) or self:getDangerousCard(enemy)) and q(self,"getDefense",enemy)>8 then return enemy end
			elseif not q(enemy,"isNude") then return enemy
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
