-- Thicket package, fixed b6025acc authority. No shared toTurnOver override.
sgs.ai_choicemade_filter.skillChoice=sgs.ai_choicemade_filter.skillChoice or {}
local function known(value,key)
    if value==nil then ai_unsupported("thicket fact is unknown",key) end
    return value
end

-- Legacy sort mutates the caller's Lua list; the common value API returns a
-- sorted copy. Retain shared friend/enemy array identity for later callbacks.
local function sort_in_place(self, players, key)
    local sorted=self:sort(players, key)
    for i=1,#sorted do players[i]=sorted[i] end
    return players
end
sgs.ai_skill_invoke.xingshang=true
sgs.ai_skill_playerchosen.fangzhu=function(self,targets)
    sort_in_place(self,self.friends_noself,"handcard")
    for _,friend in ipairs(self.friends_noself) do if not friend:faceUp() then return friend end end
    local count=self.player:getLostHp()
    for _,friend in ipairs(self.friends_noself) do if not self:toTurnOver(friend, count, "fangzhu") then return friend end end
    if count>=3 then
        local target=self:findPlayerToDraw(false,count)
        if target then return target end
        for _,enemy in ipairs(self.enemies) do
            if self:toTurnOver(enemy, count, "fangzhu") and known(hasManjuanEffect(enemy),"Manjuan") then return enemy end
        end
    else
        sort_in_place(self,self.enemies)
        for _,enemy in ipairs(self.enemies) do
            if self:toTurnOver(enemy, count, "fangzhu") and known(hasManjuanEffect(enemy),"Manjuan") then return enemy end
        end
        for _,enemy in ipairs(self.enemies) do
            if self:toTurnOver(enemy, count, "fangzhu") and enemy:hasSkills(sgs.priority_skill) then return enemy end
        end
        for _,enemy in ipairs(self.enemies) do if self:toTurnOver(enemy, count, "fangzhu") then return enemy end end
    end
end
sgs.ai_skill_playerchosen.songwei=function(self,targets)
    for _,target in ipairs(targets) do if self:isFriend(target) then return target end end
end
sgs.ai_playerchosen_intention.songwei=-50
sgs.ai_playerchosen_intention.fangzhu=function(self,from,to)
    if known(hasManjuanEffect(to),"Manjuan") then self:updateIntention(from,to,80) end
    local lost=from:getLostHp()
    local intention=80/math.max(lost,1)
    if not self:toTurnOver(to, lost) then intention=-intention end
    self:updateIntention(from,to,lost<3 and intention or math.min(intention,-30))
end
sgs.ai_need_damaged.fangzhu=function(self,attacker,player)
    local enemies=self:getEnemies(player)
    if #enemies<1 then return false end
    enemies=self:sort(enemies, "defense")
    local lost=player:getLostHp()
    for _,enemy in ipairs(enemies) do if lost<1 and self:toTurnOver(enemy, lost+1) then return true end end
    local friends=self:sort(self:getFriends(player, true), "defense")
    for _,friend in ipairs(friends) do if not self:toTurnOver(friend, lost+1) then return true end end
    return false
end
sgs.ai_fill_skill.duanliang=function(self,inclusive,request)
    local cards=self:sortByUseValue(self:addHandPile("he"), true)
    for _,card in ipairs(cards) do
        if card:isBlack() and (card:isKindOf("BasicCard") or card:isKindOf("EquipCard"))
            and self:getDynamicUsePriority(card)<known(sgs.ai_use_value.SupplyShortage,"SupplyShortage use value") then
            return self:evaluateTurnConversion("duanliang","SupplyShortage",{name="supply_shortage",skill="duanliang",
                suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}},request)
        end
    end
end
sgs.ai_cardneed.duanliang=function(to,card,self)
    return card:isBlack() and card:getTypeId()~=sgs.Card_TypeTrick
        and known(getKnownCard(to,self.player,"black",false),"known black cards")<2
end
sgs.duanliang_suit_value={spade=3.9,club=3.9}
sgs.ai_skill_invoke.zaiqi=function(self)
    return self.player:getLostHp()>=(self.player:hasSkills("rende|nosrende") and 3 or 2)
end
sgs.ai_skill_defense.zaiqi=function(self,player)
    if player:getHp()>1 then return player:getLostHp()*0.5 end
    return 0
end
sgs.ai_cardneed.lieren=function(to,card,self)
    return isCard("Slash",card,to) and known(getKnownCard(to,self.player,"Slash",true),"known Slash") == 0
end
sgs.ai_skill_invoke.lieren=function(self,data)
    local damage=data:toDamage()
    if not self:isEnemy(known(damage.to,"Lieren damage target")) then return false end
    if self.player:getHandcardNum()==1 then
        if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
        local card=known(self.player:getHandcards()[1],"Lieren only hand card")
        if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
    end
    if self:doDisCard(damage.to, "he", true, 2) then return true end
end
sgs.ai_skill_pindian.lieren=function(minusecard,self,requestor)
    local cards=self:sortByKeepValue(self.player:getHandcards())
    if requestor:objectName()==self.player:objectName() then return (known(cards[1],"Lieren hand card")):getKnownId() end
    return (known(self:getMaxCard(self.player),"Lieren maximum card")):getKnownId()
end
sgs.ai_cardneed.haoshi=function(to,card,self) return not self:willSkipDrawPhase(to) end
sgs.ai_card_intention.HaoshiCard=-80
sgs.ai_view_as.jiuchi=function(card,player,place)
    known(place,"Jiuchi place")
    if place==sgs.Player_PlaceHand and card:getSuit()==sgs.Card_Spade then
        return {name="analeptic",skill="jiuchi",suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}
    end
end
sgs.ai_cardneed.jiuchi=function(to,card,self)
    return card:getSuit()==sgs.Card_Spade and
        known(getKnownCard(to,self.player,"club",false),"known clubs")+known(getKnownCard(to,self.player,"spade",false),"known spades")==0
end
sgs.ai_cardneed.roulin=function(to,card,self)
    for _,enemy in ipairs(self.enemies) do
        if card:isKindOf("Slash") and to:canSlash(enemy, nil, true) and self:slashIsEffective(card, enemy)
            and not(enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isGoodTarget(enemy, self.enemies, card)
            and not self:slashProhibit(card, enemy) and enemy:isFemale() then
            return known(getKnownCard(to,self.player,"Slash",true),"known Slash")==0
        end
    end
end
sgs.ai_skill_playerchosen.baonue=function(self,targets)
    for _,target in ipairs(targets) do
        if self:isFriend(target) and target:isAlive() then
            if target:isWounded() then return target end
            local wizard=self.room:findPlayerBySkillName("guidao")
            if wizard and self:isFriend(wizard) then return target end
        end
    end
end
sgs.ai_playerchosen_intention.baonue=-40
sgs.jiuchi_suit_value={spade=5}
sgs.ai_suit_priority.jiuchi="diamond|heart|club|spade"
sgs.ai_skill_choice.wumou=function(self)
    if self.player:getStrategyMark("&wrath")>6 then return "discard" end
    return self.player:getHp()+self:getCardsNum("Peach")>3 and "losehp" or "discard"
end
sgs.ai_use_revises.wumou=function(self,card,use)
    if card:isNDTrick() and self.player:getStrategyMark("&wrath")<7 then
        if not(card:isKindOf("AOE") or card:isKindOf("IronChain") or card:isKindOf("Drowning"))
            and not(card:isKindOf("Duel") and self.player:getStrategyMark("&wrath")>0) then return false end
    end
end

local function reverse(values)
    local result={}
    for i=#values,1,-1 do result[#result+1]=values[i] end
    return result
end
local function choose_yinghun(self,targets)
	if self.player:getStrategyFlag("AI_doNotInvoke_yinghun") then
		self:setStrategyPlayerFlag(self.player,"AI_doNotInvoke_yinghun",false)
		return
	end
	self.yinghunchoice = "d1tx"
	local x = self.player:getLostHp()
	if x==1 and #self.friends==1 then
		for _,enemy in ipairs(self.enemies)do
			if enemy:hasSkill("manjuan") then
				return enemy
			end
		end
		return nil
	end
	local n = x-1

	self.yinghun = nil
	local player = self:AssistTarget()

	if x==1 then
		sort_in_place(self,self.friends_noself,"handcard")
		self.friends_noself = reverse(self.friends_noself)
		for _,friend in ipairs(self.friends_noself)do
			if self:hasSkills(sgs.lose_equip_skill, friend) and #friend:getEquips()>0
			  and not friend:hasSkill("manjuan") then
				self.yinghun = friend
				break
			end
		end
		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if self:needToThrowArmor(friend) and not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			for _,enemy in ipairs(self.enemies)do
				if enemy:hasSkill("manjuan") then
					return enemy
				end
			end
		end

		if not self.yinghun and player and not player:hasSkill("manjuan") and player:getCardCount(true)>0 and not self:needKongcheng(player, true) then
			self.yinghun = player
		end

		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if friend:getCardCount(true)>0 and not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end

		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
	elseif #self.friends>1 then
		sort_in_place(self,self.friends_noself,"chaofeng")
		for _,friend in ipairs(self.friends_noself)do
			if self:hasSkills(sgs.lose_equip_skill, friend) and #friend:getEquips()>0
			  and not friend:hasSkill("manjuan") then
				self.yinghun = friend
				break
			end
		end
		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if self:needToThrowArmor(friend) and not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
		if not self.yinghun and #self.enemies>0 then
			local wf
			if self.player:isLord() then
				if self:isWeak() and (self.player:getHp()<2 and self:getCardsNum("Peach")<1) then
					wf = true
				end
			end
			if not wf then
				for _,friend in ipairs(self.friends_noself)do
					if self:isWeak(friend) then
						wf = true
						break
					end
				end
			end

			if not wf then
				sort_in_place(self,self.enemies,"chaofeng")
				for _,enemy in ipairs(self.enemies)do
					if enemy:getCardCount(true)==n
					and self:doDisCard(enemy, "nil", true, n) then
						self.yinghunchoice = "d1tx"
						return enemy
					end
				end
				for _,enemy in ipairs(self.enemies)do
					if enemy:getCardCount(true)>=n
					and self:doDisCard(enemy, "nil", true, n)
					and self:hasSkills(sgs.cardneed_skill, enemy) then
						self.yinghunchoice = "d1tx"
						return enemy
					end
				end
			end
		end

		if not self.yinghun and player and not player:hasSkill("manjuan") and not self:needKongcheng(player, true) then
			self.yinghun = player
		end

		if not self.yinghun then
			self.yinghun = self:findPlayerToDraw(false,n)
		end
		if not self.yinghun then
			for _,friend in ipairs(self.friends_noself)do
				if not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
		if self.yinghun then self.yinghunchoice = "dxt1" end
	end
	if not self.yinghun and x>1 and #self.enemies>0 then
		sort_in_place(self,self.enemies,"handcard")
		for _,enemy in ipairs(self.enemies)do
			if enemy:getCardCount(true)>=n
			and self:doDisCard(enemy, "nil", true, n) then
				self.yinghunchoice = "d1tx"
				return enemy
			end
		end
		self.enemies = reverse(self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if not enemy:isNude()
			and not (self:hasSkills(sgs.lose_equip_skill, enemy) and #enemy:getEquips()>0)
			and not self:needToThrowArmor(enemy)
			and not hasTuntianEffect(enemy, true) then
				self.yinghunchoice = "d1tx"
				return enemy
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not enemy:isNude()
				and not (self:hasSkills(sgs.lose_equip_skill, enemy) and #enemy:getEquips()>0)
				and not self:needToThrowArmor(enemy)
				and not (hasTuntianEffect(enemy, true) and x<3 and enemy:getCardCount(true)<2) then
				self.yinghunchoice = "d1tx"
				return enemy
			end
		end
	end

	return self.yinghun
end

sgs.ai_skill_playerchosen.yinghun=function(self,targets)
    self.yinghunchoice=self:getStrategyMemory("thicket_yinghun_choice")
    local result=choose_yinghun(self,targets)
    self:setStrategyMemory("thicket_yinghun_choice",self.yinghunchoice)
    return result
end
sgs.ai_skill_choice.yinghun=function(self)
    return self:getStrategyMemory("thicket_yinghun_choice")
end
sgs.ai_playerchosen_intention.yinghun = function(self,from,to)
	if from:getLostHp()>1 then return end
	local intention = -80
	if to:hasSkill("manjuan") then intention = -intention end
	self:updateIntention(from,to,intention)
end

sgs.ai_choicemade_filter.skillChoice.yinghun = function(self,player,promptlist)
	local to
	for _,p in ipairs(self.room:getOtherPlayers(player))do
		if p:getStrategyFlag("YinghunTarget") then
			to = p
			break
		end
	end
	local choice = promptlist[#promptlist]
	local intention = (choice=="dxt1") and -80 or 80
	self:updateIntention(player,to,intention)
end

local function getLowerBoundOfHandcard(self)
	local least = math.huge
	local players = self.room:getOtherPlayers(self.player)
	for _,player in ipairs(players)do
		least = math.min(player:getHandcardNum(),least)
	end

	return least
end

local function getBeggar(self)
	local least = getLowerBoundOfHandcard(self)

	sort_in_place(self,self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()==least then
			return friend
		end
	end

	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if player:getHandcardNum()==least then
			return player
		end
	end
end

sgs.ai_skill_invoke.haoshi = function(self,data)
	local extra = 0
	if self.player:hasSkill("yongsi") then
		local kingdoms = {}
		for _,p in ipairs(self.room:getAlivePlayers())do
			kingdoms[p:getKnownKingdom()] = true
		end
		extra=extra+#kingdoms
	end
	local sk = {["yingzi"]=1,["noszishou"]=self.player:getLostHp(),["ayshuijian"]=1+self.player:getEquips():length(),
	["shenwei"]=2,["juejing"]=self.player:getLostHp()}
	for s,n in ipairs(sk)do
		if self.player:hasSkill(s) then
			extra = extra+n
		end
	end
	if self.player:getHandcardNum()+extra<=1 then
		return true
	end

	local beggar = getBeggar(self)
	return self:isFriend(beggar) and not beggar:hasSkill("manjuan")
end

function DimengIsWorth(self,friend,enemy,mycards,myequips)
	local e_hand1,e_hand2 = enemy:getHandcardNum(),enemy:getHandcardNum()-self:getLeastHandcardNum(enemy)
	local f_hand1,f_hand2 = friend:getHandcardNum(),friend:getHandcardNum()-self:getLeastHandcardNum(friend)
	local e_peach,f_peach = getCardsNum("Peach",enemy),getCardsNum("Peach",friend)
	if e_hand1<f_hand1 then
		return false
	elseif e_hand2<=f_hand2 and e_peach<=f_peach then
		return false
	elseif e_peach<f_peach and e_peach<1 then
		return false
	elseif e_hand1==f_hand1 and e_hand1>0 then
		return hasTuntianEffect(friend, true)
	end
	local cardNum = #mycards
	local delt = e_hand1-f_hand1 --assert: delt>0
	if delt>cardNum then
		return false
	end
	local equipNum = #myequips
	if equipNum>0 then
		if self.player:hasSkills("xuanfeng|xiaoji|nosxuanfeng") then
			return true
		end
	end
	--now e_hand1>f_hand1 and delt<=cardNum
	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt/2)
	for i=1,delt,1 do
		local card = mycards[i]
		local keepValue = self:getKeepValue(card)
		if keepValue>4 then
			soKeep = soKeep+1
		end
		local useValue = self:getUseValue(card)
		if useValue>=6 then
			soUse = soUse+1
		end
	end
	if soKeep>marker then
		return false
	end
	if soUse>marker then
		return false
	end
	return true
end

--缔盟的弃牌策略--
local dimeng_discard = function(self,discard_num,mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getKnownEffectiveId())
		if place==sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:getUseValue(card)>=6 then return 3 --使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end

	local compare_func = function(a,b)
		if aux_func(a)~=aux_func(b) then
			return aux_func(a)<aux_func(b)
		end
		return self:getKeepValue(a)<self:getKeepValue(b)
	end

	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if not self.player:isJilei(card) then table.insert(to_discard,card:getKnownId()) end
		if #to_discard>=discard_num then break end
	end
	if #to_discard~=discard_num then return {} end
	return to_discard
end


local function dummy()
    local use=AIUsePlan.new();use.isDummy=true;return use
end
local function thicket_card(self,skill,class,costs,request)
    local receipt=self:bindSkillCard(skill, costs, request)
    local suit,number=sgs.Card_NoSuit,0
    local red,black=true,true
    for _,id in ipairs(costs) do
        local material=self:getKnownCardById(id)
        if not material then ai_unsupported("skill cost face is not visible",skill) end
        if #costs==1 then suit,number=material:getSuit(),material:getNumber() end
        red,black=red and material:isRed(),black and material:isBlack()
    end
    if #costs>1 then suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",
        [sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuit]="no_suit"}
    local ns=({[1]="A",[11]="J",[12]="Q",[13]="K"})[number]or tostring(number)
    return self:legacyPolicyCard(receipt, {name=class:lower(),class_name=class,type_id=0,kind_of={class,"SkillCard","Card"},
        legacy_string_key="@"..class.."["..known(suits[suit],"skill suit")..":"..ns.."]="..(#costs>0 and table.concat(costs,"+")or"."),
        subcards=costs,suit=suit,number=number,effective_id=costs[1]or -1,will_throw=class~="HaoshiCard",
        handling_method=class=="HaoshiCard"and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        damage_card=false,can_recast=false,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack})
end
sgs.ai_fill_skill.dimeng=function(self,inclusive,request)
    if self:needBear() then return end
    return self:legacySkillSeed("dimeng", "DimengCard", request)
end
sgs.ai_skill_use_func.DimengCard = function(card,use,self,request)
	local mycards = {}
	local myequips = {}
	local keepaslash
	for _,c in ipairs(self.player:getHandcards())do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash",c,self.player) then
				local dummy_use = dummy()
				self:useBasicCard(c,dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length()>1 or dummy_use.to:first():getHp()<=1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards,c) end
		end
	end
	for _,c in ipairs(self.player:getEquips())do
		if not self.player:isJilei(c) then
			table.insert(mycards,c)
			table.insert(myequips,c)
		end
	end
	if #mycards==0 then return end
	mycards = self:sortByKeepValue(mycards) --桃的keepValue是5，useValue是6；顺手牵羊的keepValue是1.9，useValue是9

	sort_in_place(self,self.enemies,"handcard")
	local friends = {}
	for _,player in ipairs(self.friends_noself)do
		if not player:hasSkill("manjuan") then
			table.insert(friends,player)
		end
	end
	if #friends==0 then return end

	friends = self:sort(friends,"defense")
	local function cmp_HandcardNum(a,b)
		local x = a:getHandcardNum()-self:getLeastHandcardNum(a)
		local y = b:getHandcardNum()-self:getLeastHandcardNum(b)
		return x<y
	end
	table.sort(friends,cmp_HandcardNum)

	sort_in_place(self,self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:hasSkill("manjuan") then
			local e_hand = enemy:getHandcardNum()
			for _,friend in ipairs(friends)do
				local f_peach,f_hand = getCardsNum("Peach",friend),friend:getHandcardNum()
				if (e_hand>f_hand-1) and (e_hand-f_hand)<=#mycards and (f_hand>0 or e_hand>0) and f_peach<=2 then
					if e_hand==f_hand then
						use.card = self:inheritLegacyCardIdentity(thicket_card(self,"dimeng","DimengCard",{},request),card)
					else
						local discard_num = e_hand-f_hand
						local discards = dimeng_discard(self,discard_num,mycards)
						if #discards>0 then use.card = thicket_card(self,"dimeng","DimengCard",discards,request) end
					end
					if use.card and use.to then
						use.to:append(enemy)
						use.to:append(friend)
					end
					return
				end
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		local e_hand = enemy:getHandcardNum()
		for _,friend in ipairs(friends)do
			local f_hand = friend:getHandcardNum()
			if DimengIsWorth(self,friend,enemy,mycards,myequips) and (e_hand>0 or f_hand>0) then
				if e_hand==f_hand then
					use.card = self:inheritLegacyCardIdentity(thicket_card(self,"dimeng","DimengCard",{},request),card)
				else
					local discard_num = math.abs(e_hand-f_hand)
					local discards = dimeng_discard(self,discard_num,mycards)
					if #discards>0 then use.card = thicket_card(self,"dimeng","DimengCard",discards,request) end
				end
				use.to:append(enemy)
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_card_intention.DimengCard = function(self,card,from,to)
	local compare_func = function(a,b)
		return a:getHandcardNum()<b:getHandcardNum()
	end
	table.sort(to,compare_func)
	if to[1]:getHandcardNum()<to[2]:getHandcardNum() then
		self:updateIntention(from,to[1],-80)
	end
end

sgs.ai_use_value.DimengCard = 3.5
sgs.ai_use_priority.DimengCard = 2.8

sgs.dynamic_value.control_card.DimengCard = true
sgs.ai_fill_skill.luanwu = function(self,inclusive,request)
	if self.room:getMode()=="_mini_13" then return thicket_card(self,"luanwu","LuanwuCard",{},request) end
	local good,bad = 0,0
	local lord = self.room:getLord()
	if lord and self.role~="rebel" and self:isWeak(lord) then return end
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad+1
			else good = good+1
			end
		end
	end
	if good==0 then return end

	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		local hp = math.max(player:getHp(),1)
		if getCardsNum("Analeptic",player)>0 then
			if self:isFriend(player) then good = good+1.0/hp
			else bad = bad+1.0/hp
			end
		end

		local has_slash = (getCardsNum("Slash",player)>0)
		local can_slash = false
		if not can_slash then
			for _,p in ipairs(self.room:getOtherPlayers(player))do
				if player:distanceTo(p)<=player:getAttackRange() then can_slash = true break end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then good = good+math.max(getCardsNum("Peach",player),1)
			else bad = bad+math.max(getCardsNum("Peach",player),1)
			end
		end

		if getCardsNum("Jink",player)==0 then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp()/2 end
			local hp = math.max(player:getHp(),1)
			if self:isFriend(player) then bad = bad+(lost_value+1)/hp
			else good = good+(lost_value+1)/hp
			end
		end
	end

	if good>bad then return thicket_card(self,"luanwu","LuanwuCard",{},request) end
end

sgs.ai_skill_use_func.LuanwuCard=function(card,use,self)
	use.card = card
end

sgs.dynamic_value.damage_card.LuanwuCard = true
sgs.ai_fill_skill.jiuchi=function(self,inclusive,request)
	local cards = self:addHandPile()
	local card
	cards = self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if acard:getSuit()==sgs.Card_Spade then
			card = acard
			break
		end
	end
	if not card then return nil end
	local analeptic = self:evaluateTurnConversion("jiuchi","Analeptic",{name="analeptic",skill="jiuchi",suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}},request)
	assert(analeptic)
	if self:readonlyTurnAvailability(analeptic)
	then return analeptic end
end
function getGuixinValue(self,player)
	if player:isAllNude() then return 0 end
	local choice = self:recommendCardChosen(player, "hej", "dummy")
	if choice.zone~="h" and choice.zone~="e" and choice.zone~="j" and choice.zone~="none" then ai_unsupported("Guixin hypothetical choice domain is incomplete","guixin") end
	local card_id = choice.id
	if self:isEnemy(player) then
		for _,card in ipairs(player:getJudgingArea())do
			if card:getKnownEffectiveId()==card_id then
				if card:isKindOf("YanxiaoCard") then return 0
				elseif card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 0.8
					elseif self:hasWizard(self.friends, true) then return 0.4
					else return 0.5*(#self.friends)/(#self.friends+#self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0,3 do
			local card = player:getEquip(i)
			if card and card:getKnownEffectiveId()==card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0 end
				local value = 0
				if self:getDangerousCard(player)==card_id then value = 1.5
				elseif self:getValuableCard(player)==card_id then value = 1.1
				elseif i==1 then value = 1
				elseif i==2 then value = 0.8
				elseif i==0 then value = 0.7
				elseif i==3 then value = 0.5
				end
				if player:hasSkills(sgs.lose_equip_skill) or not self:doDisCard(player, "e") then value = value-0.2 end
				return value
			end
		end
		if self:needKongcheng(player) and player:getHandcardNum()==1 then return 0 end
		if not self:hasLoseHandcardEffective() then return 0.1
		else
			local index = player:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.7 or 0.6
			local value = 0.2+index/(player:getHandcardNum()+1)
			if not self:doDisCard(player, "h") then value = value-0.1 end
			return value
		end
	elseif self:isFriend(player) then
		for _,card in ipairs(player:getJudgingArea())do
			if card:getKnownEffectiveId()==card_id then
				if card:isKindOf("YanxiaoCard") then return 0
				elseif card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 1
					elseif self:hasWizard(self.friends, true) then return 0.8
					else return 0.4*(#self.enemies)/(#self.friends+#self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0,3 do
			local card = player:getEquip(i)
			if card and card:getKnownEffectiveId()==card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0.9 end
				local value = 0
				if i==1 then value = 0.1
				elseif i==2 then value = 0.2
				elseif i==0 then value = 0.25
				elseif i==3 then value = 0.25
				end
				if player:hasSkills(sgs.lose_equip_skill) then value = value+0.1 end
				if hasTuntianEffect(player, true) then value = value+0.1 end
				return value
			end
		end
		if self:needKongcheng(player, true) and player:getHandcardNum()==1 then return 0.5
		elseif self:needKongcheng(player) and player:getHandcardNum()==1 then return 0.3 end
		if not self:hasLoseHandcardEffective() then return 0.2
		else
			local index = player:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.5 or 0.4
			local value = 0.2-index/(player:getHandcardNum()+1)
			if hasTuntianEffect(player, true) then value = value+0.1 end
			return value
		end
	end
	return 0.3
end

sgs.ai_skill_invoke.guixin = function(self,data)
	local damage = data:toDamage()
	local diaochans = self.room:findPlayersBySkillName("lihun")
	local lihun_eff = false
	for _,diaochan in ipairs(diaochans)do
		if self:isEnemy(diaochan) then
			lihun_eff = true
			break
		end
	end
	local manjuan_eff = hasManjuanEffect(self.player)
	if lihun_eff and not manjuan_eff then return false end
	if not self.player:faceUp() then return true
	else
		if manjuan_eff then return false end
		local value = 0
		for _,player in ipairs(self.room:getOtherPlayers(self.player))do
			value = value+getGuixinValue(self,player)
		end
		local left_num = known(damage.damage,"Guixin damage amount")-self.player:getStrategyMark("guixinTimes")
		return value>=1.3 or left_num>0
	end
end

sgs.ai_skill_defense.guixin = function(self, player)
	return player:aliveCount()-1
end
sgs.ai_need_damaged.guixin = function(self,attacker,player)
	if self.room:alivePlayerCount()<=3 or player:hasSkill("manjuan") then return false end
	local diaochan = self.room:findPlayerBySkillName("lihun")
	local drawcards = 0
	for _,aplayer in ipairs(self.room:getOtherPlayers(player))do
		if (aplayer:getCardCount(true)+#aplayer:getJudgingArea())>0 then drawcards = drawcards+1 end
	end
	return not self:isLihunTarget(player, drawcards)
end

sgs.ai_skill_invoke.newguixin = function(self,data)
	local damage = data:toDamage()
	local diaochans = self.room:findPlayersBySkillName("lihun")
	local lihun_eff = false
	for _,diaochan in ipairs(diaochans)do
		if self:isEnemy(diaochan) then
			lihun_eff = true
			break
		end
	end
	local manjuan_eff = hasManjuanEffect(self.player)
	if lihun_eff and not manjuan_eff then return false end
	if not self.player:faceUp() then return true
	else
		if manjuan_eff then return false end
		local value = 0
		for _,player in ipairs(self.room:getOtherPlayers(self.player))do
			value = value+getGuixinValue(self,player)
		end
		local left_num = known(damage.damage,"Guixin damage amount")-self.player:getStrategyMark("newguixinTimes")
		return value>=1.3 or left_num>0
	end
end

sgs.ai_need_damaged.newguixin = function(self,attacker,player)
	return sgs.ai_need_damaged.guixin(self,attacker,player)
end


sgs.ai_fill_skill.wuqian=function(self,inclusive,request)
    if self.player:getStrategyMark("&wrath")<2 then return end
    return thicket_card(self,"wuqian","WuqianCard",{},request)
end
sgs.ai_fill_skill.shenfen=function(self,inclusive,request)
    return thicket_card(self,"shenfen","ShenfenCard",{},request)
end
sgs.ai_skill_use_func.WuqianCard = function(wuqiancard,use,self)
	if self:getCardsNum("Slash")>0 and not self.player:hasSkill("wushuang") then
		for _,card in ipairs(self.player:getHandcards())do
			if isCard("Duel",card,self.player) then
				local dummy_use = dummy()
				dummy_use.isWuqian = true
				local duel = self:getEvaluationCard("duel")
				self:useCardDuel(duel,dummy_use)
				if dummy_use.card and dummy_use.to:length()>0 and (self:isWeak(dummy_use.to:first()) and dummy_use.to:first():getHp()==1 or dummy_use.to:length()>1) then
					use.card = wuqiancard
					use.to:append(dummy_use.to:first())
					return
				end
			end
		end
	end
end

sgs.ai_use_value.WuqianCard = 5
sgs.ai_use_priority.WuqianCard = 10
sgs.ai_card_intention.WuqianCard = 80

function SmartAIView:canSaveSelf(player)
    if known(hasBuquEffect(player),"Buqu") then return true end
    if known(getCardsNum("Analeptic",player,self.player),"known Analeptic")>0 then return true end
    if player:hasSkills("jiushi|mobilejiushi") and player:faceUp() then return true end
    if player:hasSkills("jiuchi|mobilejiuchi|oljiuchi") then
        local cards=player:getKnownCards()
        if player:objectName()==self.player:objectName() then cards=player:getHandcards() end
        for _,card in ipairs(cards) do if card:getSuit()==sgs.Card_Spade then return true end end
        local hidden=math.max(0,player:getHandcardNum()-#cards)
        if hidden>0 then
            return self:useKnowledgeEstimate({value=1-0.75^hidden>=0.5,status="estimate",
                basis="Jiuchi self rescue: visible nonspades plus symmetric hidden-suit prior p=.25; threshold .5",
                viewer=self.player:objectName(),observer=self.player:objectName(),target=player:objectName()},"canSaveSelf.jiuchi")
        end
    end
    return false
end
local function getShenfenUseValueOfHECards(self,to)
	local value = 0
	-- value of handcards
	local value_h = 0
	local hcard = to:getHandcardNum()
	if to:hasSkill("lianying") then
		hcard = hcard-0.9
	elseif to:hasSkills("shangshi|nosshangshi") then
		hcard = hcard-0.9*to:getLostHp()
	else
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		if jwfy and self:isFriend(jwfy, to) and (not self:isWeak(jwfy) or jwfy:getHp()>1) then hcard = hcard-0.9 end
	end
	value_h = (hcard>4) and 16/hcard or hcard
	if hasTuntianEffect(to, true) then value = value*0.95 end
	if (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getHp()>2 and to:getStrategyMark("zhiji")==0)) and not to:isKongcheng() then value_h = value_h*0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then value_h = value_h*0.95 end
	value = value+value_h

	-- value of equips
	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("SilverLion") and to:isWounded() then equip_num = equip_num-1.1 end
	value_e = equip_num*1.1
	if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e*0.7 end
	if to:hasSkill("nosxuanfeng") then value_e = value_e*0.85 end
	if to:hasSkills("bazhen|yizhong") and to:getArmor() then value_e = value_e-1 end
	value = value+value_e

	return value
end

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _,player in ipairs(self.room:getAllPlayers())do
                local nm_mark = player:getStrategyMark("&nightmare")
		if player:objectName()==self.player:objectName() then nm_mark = nm_mark+1 end
		if nm_mark>0 and nm_mark>most or (nm_mark==most and self:isEnemy(player)) then
			most = nm_mark
			target = player
		end
	end
	if target and self:isEnemy(target) then return true end
	return false
end

sgs.ai_skill_use_func.ShenfenCard = function(card,use,self)
	if (self.role=="loyalist" or self.role=="renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not self.player:isLord() then return end
	local benefit = 0
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if self:isFriend(player) then benefit = benefit-getShenfenUseValueOfHECards(self,player) end
		if self:isFriend(player) then benefit = benefit+getShenfenUseValueOfHECards(self,player) end
	end
	local friend_save_num = self:getSaveNum(true)
	local enemy_save_num = self:getSaveNum(false)
	local others = 0
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			others = others+1
			local value_d = 3.5/math.max(player:getHp(),1)
			if player:getHp()<=1 then
				if player:hasSkill("wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d*0.1 end
				end
				if self:canSaveSelf(player) then
					value_d = value_d*0.9
				elseif self:isFriend(player) and friend_save_num>0 then
					friend_save_num = friend_save_num-1
					value_d = value_d*0.9
				elseif self:isEnemy(player) and enemy_save_num>0 then
					enemy_save_num = enemy_save_num-1
					value_d = value_d*0.9
				end
			end
			if player:hasSkill("fankui") then value_d = value_d*0.8 end
			if player:hasSkill("guixin") then
				if not player:faceUp() then
					value_d = value_d*0.4
				else
					value_d = value_d*0.8*(1.05-self.room:alivePlayerCount()/15)
				end
			end
			if self:needToLoseHp(player, self.player) or getBestHp(player)==player:getHp()-1 then value_d = value_d*0.8 end
			if self:isFriend(player) then benefit = benefit-value_d end
			if self:isEnemy(player) then benefit = benefit+value_d end
		end
	end
	if not self.player:faceUp() or self.player:hasSkills("jushou|nosjushou|neojushou|kuiwei") then
		benefit = benefit+1
	else
		local help_friend = false
		for _,friend in ipairs(self.friends_noself)do
			if self:hasSkills("fangzhu|jilve", friend) then
				help_friend = true
				benefit = benefit+1
				break
			end
		end
		if not help_friend then benefit = benefit-0.5 end
	end
	if self.player:getKnownKingdom()=="qun" then
		for _,player in ipairs(self.room:getOtherPlayers(self.player))do
			if player:hasLordSkill("baonue") and self:isFriend(player) then
				benefit = benefit+0.2*self.room:alivePlayerCount()
				break
			end
		end
	end
	benefit = benefit+(others-7)*0.05
	if benefit>0 then
		use.card = card
	end
end

sgs.ai_use_value.ShenfenCard = 8
sgs.ai_use_priority.ShenfenCard = 5.3

sgs.dynamic_value.damage_card.ShenfenCard = true
sgs.dynamic_value.control_card.ShenfenCard = true

sgs.ai_skill_choice.benghuai = function(self,choices,data)
	for _,friend in ipairs(self.friends)do
		if friend:hasSkill("tianxiang") and (self.player:getHp()>=3 or (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 and self.player:getHp()>1)) then
			return "hp"
		end
	end
	if self.player:getMaxHp()>=self.player:getHp()+2 then
		if self.player:getMaxHp()>5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _,p in ipairs(self.enemies)do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num+1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and self.room:findPlayerBySkillName("fangquan")
			if ls then
				self:setStrategyMemory("fangquan_effect",false)
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2,enemy_num-1) or 1
			if (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")+self.player:getHp()>least_hp) then return "hp" end
		end
		return "maxhp"
	else
		return "hp"
	end
end

ai_skill_use["@@haoshi!"]=function(self,prompt,request)
    local beggar=known(getBeggar(self),"Haoshi receiver")
    local cards=self:sortByUseValue(self.player:getHandcards(), true)
    local ids={}
    for i=1,math.floor(#cards/2) do ids[#ids+1]=cards[i]:getKnownEffectiveId() end
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local card=self:bindSkillCard("haoshi", ids, request)
    local use=AIUsePlan.new();use.card=card;use.to=AIList.new{beggar}
    return known(use:toAnswer(),"Haoshi exact authority answer")
end

-- Effective tenyear_st_standard-ai.lua:2231, gated by immutable native
-- raw-reference/source proof. Canonical callback identity is captured now.
if ai_audited_aliases then
    ai_audited_aliases.register{ id="ai_cardneed.tenyearduanliang",registry="ai_cardneed",path={"tenyearduanliang"},
        canonical_registry="ai_cardneed",canonical_path={"duanliang"},self_index=3 }
end
