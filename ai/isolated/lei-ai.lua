-- Source: b6025acc ai/lei-ai.lua.
local dummy = AIUsePlan.dummy
local known = AIValue.requireKnown

-- The donor kept poxi_target on its SmartAI object; memory holds the player's name.
local function write(self,k,v)
 if k=="poxi_target"and v~=nil then v=v:objectName()end
 self:setStrategyMemory("lei."..k,v==nil and false or v)
end
local function read(self,k)
 local v,p=self:getStrategyMemory("lei."..k)
 if not p or v==false then return nil end
 if k=="poxi_target"then return known(self.room:findPlayerByObjectName(v,true),"poxi_target")end
 return v
end
local function paid(self,skill,class,costs,request)
    if type(self.evaluateTurnSkillCard)~="function"then ai_unsupported("readonly paid hypothesis unavailable",skill)end
    return self:evaluateTurnSkillCard(skill,class,costs,request)
end
local function response(self,skill,class,costs)
    local card=self:bindSkillCard(skill,costs,nil,nil,class)
    return {kind="use_card",card_spec=card:toCardSpec(),targets={}}
end
local function equip_location(card)
    for i,class in ipairs({"Weapon","Armor","DefensiveHorse","OffensiveHorse","Treasure"})do
        if card:isKindOf(class)then return i-1 end
    end
    ai_unsupported("equipment location unavailable","huairou")
end
local function disclosed_hand(self,player)
    -- Poxi shows the target's hand to the user; this viewer must know all of it.
    local cards=player:getKnownCards()
    if #cards~=player:getHandcardNum()then ai_unsupported("Poxi full hand not disclosed","poxi")end
    return cards
end
local function weidi_mark(self,player)
    if type(self.recordLeiweidiTarget)~="function"then ai_unsupported("legacy Leiweidi mark writer not projected","leiweidi_to-Clear")end
    self:recordLeiweidiTarget(player)
end
local function duorui_invoke(self,data,ol)
    local player=data:toPlayer();if self:isFriend(player)then return false end
    -- The engine General's skill list (not the player's current skills) is not projected.
    ai_unsupported("General skill lists are not projected","lei.general_skills")
end

--往烈
ai_skill_invoke.wanglie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	return (use.card:isKindOf("Duel") or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("Slash") or use.card:getStrategyFlag("drank")) or false
end

--罪论
ai_skill_invoke.zuilun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local n = 0
	if self.player:getStrategyMark("damage_point_round")>0 then n = n+1 end
	local minhandnum = true
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if p:getHandcardNum()<self.player:getHandcardNum() then
			minhandnum = false
			break
		end
	end
	if minhandnum then n = n+1 end
	if self.player:getStrategyMark("zuilun_discard-Clear")<=0 then n = n+1 end

	if n==0 then
		local to = self:findPlayerToLoseHp()
		if not to then return (false) or false end
		if to:getHp()>self.player:getHp() then return (false) or false end
		if (self.player:isLord() or self.player:getKnownRole()=="renegade") and self:isWeak() then return (false) or false end
		return (true) or false
	end
	if self:hasJieyingyEffect(self.player) then return (false) or false end
	return (true) or false
end

sgs.ai_skill_playerchosen.zuilun = function(self,targets)
	return self:findPlayerToLoseHp() or targets[1]
end

sgs.ai_playerchosen_intention.zuilun = function(self,from,to)
	if self:needToLoseHp(friend,self.player,false,true) then return end
	if hasZhaxiangEffect(to) then return end
	self:updateIntention(from,to,10)
end

sgs.ai_target_revises.fuyin = function(to,card,self)
    if self:getOverflow()>1 or to:getHandcardNum()>=self.player:getHandcardNum() then
		return
	end
    if card:isKindOf("Slash") then
		if to:getStrategyMark("fuyin-Clear")<1
		and self:getCardsNum("Duel")<1
		then return true end
	end
    if card:isKindOf("Duel") then
		if to:getStrategyMark("fuyin-Clear")<1
		and self:getCardsNum("Slash,Duel")<2
		then return true end
	end
end

--良姻
sgs.ai_skill_playerchosen.liangyin = function(self,targets)
	local tos = sgs.QList2Table(targets)
	tos = self:sort(tos)
	for _,p in sgs.list(tos)do
		if p:getHandcardNum()>self.player:getHandcardNum() and self:isFriend(p) and self:canDraw(p) then
			return p
		elseif p:getHandcardNum()<self.player:getHandcardNum() and p:canDiscard(p, "he") then
			if self:isEnemy(p) and not self:needToThrowCard(p) and not (not self:hasLoseHandcardEffective(p) and not p:isKongcheng()) then return p end
			if self:isFriend(p) and self:needToThrowCard(p) then return p end
		end
	end
	if tos[1]:getHandcardNum()>self.player:getHandcardNum() then self:noChoice(targets,"draw") end
	if tos[1]:getHandcardNum()<self.player:getHandcardNum() then self:noChoice(targets,"letDis") end
	return nil
end

sgs.ai_playerchosen_intention.liangyin = function(self,from,to)
	if to:getHandcardNum()>from:getHandcardNum() and self:canDraw(to,from) then self:updateIntention(from,to,-10) end
	if to:getHandcardNum()<from:getHandcardNum() and not self:needToThrowCard(to) then self:updateIntention(from,to,10) end
end

--箜声
sgs.ai_skill_discard.kongsheng = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	if (self:needKongcheng() and not self.player:isKongcheng()) or self.player:containsTrick("indulgence") then
		for _,card in sgs.list(cards)do
			table.insert(to_discard,card:getKnownId())
		end
	end

	local useSlash = false
	local slash,ana,peach = 0,0,0
	for _,card in sgs.list(cards)do
		if (card:isKindOf("Jink") or card:isKindOf("DefensiveHorse")) and not table.contains(to_discard,card:getKnownId()) then
			table.insert(to_discard,card:getKnownId())
		elseif card:isKindOf("Slash") then
			if self:willUse(self.player,card,false,false,true) then
				useSlash = true
				slash = slash+1
			else
				if not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
			end
			if slash>1 and not self:hasCrossbowEffect() and not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
		elseif card:isKindOf("Analeptic") then
			if (not useSlash or ana>0) and not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
			ana = ana+1
		elseif card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") and not card:isKindOf("Nullification") then
			local dummyuse = dummy()
			self:useTrickCard(card,dummyuse)
			if not dummyuse.card then
				if not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
			end
		elseif card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
			if not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
		elseif card:isKindOf("Weapon") and self.player:getWeapon() and #to_discard==0 then
			if not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
		elseif card:isKindOf("Peach") then
			local dummy_use = dummy()
			self:useBasicCard(card,dummy_use)
			if dummy_use.card then
				peach = peach+1
			else
				if not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
			end
			if peach>1 and not table.contains(to_discard,card:getKnownId()) then table.insert(to_discard,card:getKnownId()) end
		end
	end
	if self:needToThrowArmor() then table.insert(to_discard,self.player:getArmor():getId()) end
	if self.player:getDefensiveHorse() then table.insert(to_discard,self.player:getDefensiveHorse():getId()) end
	return to_discard
end

sgs.ai_target_revises.qianjie = function(to,card,self,use)
    if card:isKindOf("IronChain")
	then return true end
end

--决堰
ai_fill_skill.jueyan = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jueyan","JueyanCard",request)
end

ai_card_use.JueyanCard = function(self, card, use, request)
	write(self,"jueyan",nil)
	if self:needToThrowArmor() and self.player:hasEquipArea(1) then
		self:setPriorityValue("JueyanCard",10,"lei")
		write(self,"jueyan","1")
		use.card = self:bindSkillCard("jueyan",{},nil,nil,"JueyanCard")
		return
	end

	local cards = sgs.QList2Table(self.player:getCards("h"))
	local w,h,t = 0,0,0
	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash") then
			if self:willUse(self.player,c,false,true) then w = w+1 end
			if self:slashIsAvailable() and self:willUse(self.player,c,true) then h = h+1 end
		end
		if c:isKindOf("Snatch") or c:isKindOf("SupplyShortage") and self:willUse(self.player,c,true) then h = h+1 end
		if c:isNDTrick() and self:willUse(self.player,c) then t = t+1 end
	end
	if t>0 and self.player:hasEquipArea(4) and not self:keepWoodenOx() then
		self:setPriorityValue("JueyanCard",10,"lei")
		write(self,"jueyan","4")
		use.card = self:bindSkillCard("jueyan",{},nil,nil,"JueyanCard")
		return
	end
	if w>0 and self.player:hasEquipArea(0) then
		self:setPriorityValue("JueyanCard",sgs.ai_use_priority.Slash-0.1 ,"lei")
		write(self,"jueyan","0")
		use.card = self:bindSkillCard("jueyan",{},nil,nil,"JueyanCard")
		return
	end
	if h>0 and (self.player:hasEquipArea(2) or self.player:hasEquipArea(3)) then
		self:setPriorityValue("JueyanCard",sgs.ai_use_priority.Slash-0.1 ,"lei")
		write(self,"jueyan","23")
		use.card = self:bindSkillCard("jueyan",{},nil,nil,"JueyanCard")
		return
	end
	if self.player:hasEquipArea(1) and (not self.player:getArmor() or self:isWeak() or self.player:getHandcardNum()<3) then
		if self.player:isWounded() then self:setPriorityValue("JueyanCard",sgs.ai_use_priority.SilverLion-0.1,"lei") else self:setPriorityValue("JueyanCard",10,"lei") end
		write(self,"jueyan","1")
		use.card = self:bindSkillCard("jueyan",{},nil,nil,"JueyanCard")
		return
	end
end

sgs.ai_use_priority.JueyanCard = 10

ai_skill_choice.jueyan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if read(self,"jueyan") then
		return ai_choice_result((read(self,"jueyan")), options)
	else
		return ai_choice_result((items[1]), options)
	end

    return ai_choice_result(nil, options)
end

--怀柔
ai_fill_skill.huairou = function(self, options, request)
    local inclusive = options and options.inclusive
	--yun
	if self:needToThrowArmor() then return paid(self,"huairou","HuairouCard",{self.player:getArmor():getEffectiveId()},request) end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			local equip_index = equip_location(c)
			if self.player:isProhibited(self.player,c) or not self.player:hasEquipArea(equip_index) then
				return paid(self,"huairou","HuairouCard",{c:getKnownEffectiveId()},request)
			end

			if self:willUse(self.player,c) then
				if c:isKindOf("Weapon") and self.player:getWeapon() then
					return paid(self,"huairou","HuairouCard",{self.player:getWeapon():getEffectiveId()},request)
				elseif c:isKindOf("Armor") and self.player:getArmor() then
					return paid(self,"huairou","HuairouCard",{self.player:getArmor():getEffectiveId()},request)
				elseif c:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then
					return paid(self,"huairou","HuairouCard",{self.player:getDefensiveHorse():getEffectiveId()},request)
				elseif c:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
					return "@HuairouCard="..self.player:getOffensiveHorse()
				end
			else
				return paid(self,"huairou","HuairouCard",{c:getKnownEffectiveId()},request)
			end
		end
	end
	return
end

ai_card_use.HuairouCard = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority.HuairouCard = 10
sgs.ai_use_value.HuairouCard = 10

--镇骨
sgs.ai_skill_playerchosen.zhengu = function(self,targets)
	local n = self.player:getHandcardNum()
	local f,e = n,n

	local dis,drw = 0,0
	local fri,ene,eqf,eqe
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,who in sgs.list(self.friends_noself)do
		if who:getHandcardNum()<f and not self:needKongcheng(who,true) and not hasManjuanEffect(who) then f = who:getHandcardNum() fri = who end
		if who:getHandcardNum()==n and not eqf and not hasManjuanEffect(who) and n>1 then eqf = who end
	end

	drw = n-f
	if drw>0 and n>5 then
		drw = 5-f
	end

	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,who in sgs.list(self.enemies)do
		if who:getHandcardNum()>e and not (n==0 and self:needKongcheng(who,true)) then e = who:getHandcardNum() ene = who end
		if who:getHandcardNum()==n and n<2 then eqe = who end
	end
	dis = e-n
	if drw>0 and drw>=dis then return fri end
	if dis>0 and dis>=drw then return ene end
	if drw>0 and drw==dis then
		if n>1 and fri then return fri end
		if n<2 and ene then return ene end
	end
	if eqf then return eqf end
	if eqe then return eqe end
	return nil
end

sgs.ai_playerchosen_intention.zhengu = function(self,from,to)
	if to:getHandcardNum()<from:getHandcardNum() and self:canDraw(to,from) then self:updateIntention(from,to,-10) end
	if to:getHandcardNum()>from:getHandcardNum() and not self:needToThrowCard(to,"h") then self:updateIntention(from,to,10) end
end

--征荣
ai_skill_invoke.zhengrong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:getOverflow(target)>2 then return (true) or false end
		if self:needToThrowCard(target) then return (true) or false end
		if self:needKongcheng(target) and target:getHandcardNum()==1 then return (true) or false end
		return (false) or false
	end
	if self:isEnemy(target) then
		if not self:doDisCard(target,"he",true) then return (false) or false end
		return (true) or false
	end
	return (true) or false
end

--鸿举
ai_skill_use["@@hongju"] = function(self, prompt, request)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(),#cards)
	for _,card_id in sgs.qlist(pile)do
		table.insert(piles,known(self:getKnownCardById(card_id),"rong card"))
	end

	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	cards = self:sortByCardNeed(cards)
	piles = self:sortByCardNeed(piles)
	for i = 1 ,max_num,1 do
		if self:cardNeed(piles[#piles])>self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard,piles[#piles])
			table.insert(exchange_to_pile,cards[1])
			table.removeOne(piles,piles[#piles])
			table.removeOne(cards,cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard==0 then return "." end
	local exchange = {}

	for _,c in sgs.list(exchange_to_handcard)do
		table.insert(exchange,c:getKnownId())
	end

	for _,c in sgs.list(exchange_to_pile)do
		table.insert(exchange,c:getKnownId())
	end

	return response(self,"hongju","HongjuCard",exchange)
end

--清侧
ai_fill_skill.qingce = function(self, options, request)
    local inclusive = options and options.inclusive

	local piles = self.player:getPile("rong")
	return paid(self,"qingce","QingceCard",{piles:first()},request)
end

ai_card_use.QingceCard = function(self, card, use, request)
	local to = self:findPlayerToDiscard("ej",true,false,players)[1]
	if not to then return end
	use.card = card
	use.to:append(to)
end

sgs.ai_use_priority.QingceCard = 4.2

--OL征荣
sgs.ai_skill_playerchosen.olzhengrong = function(self,targets)
	local to = self:findPlayerToDiscard("he",true,false,targets)[1]
	if to then return to end
	for _,to in sgs.qlist(targets)do
		if not self:isFriend(to) and self:doDisCard(to,"he",true) then return to end
	end
	return nil
end

--OL鸿举
ai_skill_use["@@olhongju"] = function(self, prompt, request)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(),#cards)
	for _,card_id in sgs.qlist(pile)do
		table.insert(piles,known(self:getKnownCardById(card_id),"rong card"))
	end

	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	cards = self:sortByCardNeed(cards)
	piles = self:sortByCardNeed(piles)
	for i = 1 ,max_num,1 do
		if self:cardNeed(piles[#piles])>self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard,piles[#piles])
			table.insert(exchange_to_pile,cards[1])
			table.removeOne(piles,piles[#piles])
			table.removeOne(cards,cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard==0 then return "." end
	local exchange = {}

	for _,c in sgs.list(exchange_to_handcard)do
		table.insert(exchange,c:getKnownId())
	end

	for _,c in sgs.list(exchange_to_pile)do
		table.insert(exchange,c:getKnownId())
	end

	return response(self,"olhongju","OLHongjuCard",exchange)
end

--OL清侧
ai_fill_skill.olqingce = function(self, options, request)
    local inclusive = options and options.inclusive

	local hands = sgs.QList2Table(self.player:getCards("h"))
	hands = self:sortByKeepValue(hands)
	if hands[1]:isKindOf("ExNihilo") then return end
	if self:isWeak() and hands[1]:isKindOf("Peach") then return end
	if self:isWeak() and hands[1]:isKindOf("Jink") and self:getCardsNum("Jink")<2 then return end
	local piles = {}
	for _,id in sgs.qlist(self.player:getPile("rong"))do
		table.insert(piles,known(self:getKnownCardById(id),"offered card"))
	end
	piles = self:sortByUseValue(piles,true)
	local c = {}
	table.insert(c,hands[1]:getKnownId())
	table.insert(c,piles[1]:getKnownId())
	return paid(self,"olqingce","OLQingceCard",c,request)
end

ai_card_use.OLQingceCard = function(self, card, use, request)
	local to = self:findPlayerToDiscard("ej",true,false,players)[1]
	if not to then return end
	use.card = card
	use.to:append(to)
end

sgs.ai_use_priority.OLQingceCard = sgs.ai_use_priority.Dismantlement-0.1

--手杀征荣
sgs.ai_skill_playerchosen.mobilezhengrong = function(self,targets)
	local to = self:findPlayerToDiscard("he",false,false,targets)[1]
	if to then return to end
	for _,to in sgs.qlist(targets)do
		if not self:isFriend(to) and self:doDisCard(to) then return to end
	end
	for _,to in sgs.qlist(targets)do
		if not self:isFriend(to) then return to end
	end
	return targets:at(math.random(0,targets:length()-1))
end

--手杀鸿举
ai_skill_use["@@mobilehongju"] = function(self, prompt, request)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(),#cards)
	for _,card_id in sgs.qlist(pile)do
		table.insert(piles,known(self:getKnownCardById(card_id),"rong card"))
	end

	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	cards = self:sortByCardNeed(cards)
	piles = self:sortByCardNeed(piles)
	for i = 1 ,max_num,1 do
		if self:cardNeed(piles[#piles])>self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard,piles[#piles])
			table.insert(exchange_to_pile,cards[1])
			table.removeOne(piles,piles[#piles])
			table.removeOne(cards,cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard==0 then return "." end
	local exchange = {}

	for _,c in sgs.list(exchange_to_handcard)do
		table.insert(exchange,c:getKnownId())
	end

	for _,c in sgs.list(exchange_to_pile)do
		table.insert(exchange,c:getKnownId())
	end

	return response(self,"mobilehongju","MobileHongjuCard",exchange)
end

--伪帝
sgs.ai_skill_askforyiji.leiweidi = function(self,card_ids,targets)
	local friends = {}
	for _,p in sgs.list(targets)do
		if hasManjuanEffect(p) or self:isLihunTarget(p)
		or p:getKnownKingdom()~="qun" or not self:isFriend(p) then continue end
		table.insert(friends,p)
	end
	if #friends<1 then
		for _,p in sgs.list(targets)do
			if hasManjuanEffect(p) or self:isLihunTarget(p)
			or p:getKnownKingdom()~="qun" or self:isEnemy(p) then continue end
			table.insert(friends,p)
		end
	end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,targets)
	if id and to and targets:contains(to) then
		weidi_mark(self,to)
		return to,id
	end
	local keep,toGive,allcards = nil,{},{}
	for _,id in sgs.list(card_ids)do
		local card = known(self:getKnownCardById(id),"offered card")
		if not keep and isCard("Jink,Analeptic",card,self.player)
		then keep = true
		else
			table.insert(toGive,card)
		end
		table.insert(allcards,card)
	end
	local card,friend = self:getCardNeedPlayer(allcards)
	if card and friend and targets:contains(friend) then
		weidi_mark(self,friend)
		return friend,card:getKnownId()
	end
	allcards = #toGive>0 and toGive or allcards
	allcards = self:sortByKeepValue(allcards,true)
	if #friends>0 then
		local id = allcards[1]:getKnownId()
		friends = self:sort(friends,"handcard")
		for _,ap in sgs.list(friends)do
			if self:needKongcheng(ap,true)
			then continue end
			weidi_mark(self,ap)
			return ap,id
		end
		friends = self:sort(friends,"defense")
		weidi_mark(self,friends[1])
		return friends[1],id
	end
	return nil,-1
end

--从谏
sgs.ai_skill_askforyiji.congjian = function(self,card_ids,tos)
	local equips,ces,cs = {},{},{}
	for _,id in sgs.list(card_ids)do
		local equip = known(self:getKnownCardById(id),"offered card")
		table.insert(cs,equip)
		if not equip:isKindOf("EquipCard")
		or equip:objectName()=="wooden_ox" and self.player:getPile("wooden_ox"):length()>0
		then continue end
		table.insert(ces,equip)
		table.insert(equips,id)
	end
	local c,to = self:getCardNeedPlayer(ces,nil,tos)
	if c and to and not AIValue.sameLegacyIdentity(to,self.player) then return to,c:getKnownEffectiveId() end
	local c,to = self:getCardNeedPlayer(cs,nil,tos)
	if c and to and not AIValue.sameLegacyIdentity(to,self.player) then return to,c:getKnownEffectiveId() end
	if #equips>0 then
		local to,id = sgs.ai_skill_askforyiji.nosyiji(self,equips,tos)
		if to and id>0 and not AIValue.sameLegacyIdentity(to,self.player) then return to,id end
	end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id>0 and not AIValue.sameLegacyIdentity(to,self.player) then return to,id end
	return nil,-1
end

--雄乱
ai_fill_skill.xiongluan = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("xiongluan","XiongluanCard",request)
end

ai_card_use.XiongluanCard = function(self, card, use, request)
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(AIList.new(slashes))do
			if slash:getKnownEffectiveId()==e:getKnownId()
			or table.contains(slash:getSkillNames(), e:objectName())
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes<1 then return end
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHp()<2 or #self.enemies<2
		then continue end
		local n = 0
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy)
			and not(self:hasEightDiagramEffect(enemy)) then
				n = n+1
				if n>=enemy:getHp() then
					use.card = self:bindSkillCard("xiongluan",{},nil,nil,"XiongluanCard")
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.XiongluanCard = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value.XiongluanCard = 3


--夺锐
ai_skill_invoke.duorui = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (duorui_invoke(self,data,false)) or false
end

ai_skill_choice.duorui_area = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if self:needToThrowArmor() and self.player:hasEquipArea(1) and table.contains(items,"1") then
		return ai_choice_result(("1"), options)
	elseif self.player:hasEquipArea(4) and not self.player:getTreasure() and table.contains(items,"4") then
		return ai_choice_result(("4"), options)
	elseif self.player:hasEquipArea(1) and not self.player:getArmor() and table.contains(items,"1") then
		return ai_choice_result(("1"), options)
	elseif self.player:hasEquipArea(0) and not self.player:getWeapon() and table.contains(items,"0") then
		return ai_choice_result(("0"), options)
	elseif self.player:hasEquipArea(3) and not self.player:getOffensiveHorse() and table.contains(items,"3") then
		return ai_choice_result(("3"), options)
	elseif self.player:hasEquipArea(2) and not self.player:getDefensiveHorse() and table.contains(items,"2") then
		return ai_choice_result(("2"), options)
	elseif self.player:hasEquipArea(4) and not self:keepWoodenOx() and table.contains(items,"4") then
		return ai_choice_result(("4"), options)
	elseif self.player:hasEquipArea(1) and table.contains(items,"1") then
		return ai_choice_result(("1"), options)
	elseif self.player:hasEquipArea(0) and table.contains(items,"0") then
		return ai_choice_result(("0"), options)
	elseif self.player:hasEquipArea(3) and table.contains(items,"3") then
		return ai_choice_result(("3"), options)
	elseif self.player:hasEquipArea(2) and table.contains(items,"2") then
		return ai_choice_result(("2"), options)
	else
		return ai_choice_result((items[1]), options)
	end

    return ai_choice_result(nil, options)
end

ai_skill_choice.duorui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toDamage().to
	local skills = choices:split("+")


	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return ai_choice_result((sk), options)
		end
	end

	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return ai_choice_result((sk), options)
		end
	end

	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return ai_choice_result((not_bad_skills[math.random(1,#not_bad_skills)]), options)
	end

	return ai_choice_result((skills[math.random(1,#skills)]), options)
end

--止啼
ai_skill_choice.zhiti = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if not self.player:hasEquipArea(1) then
		return ai_choice_result(("1"), options)
	elseif not self.player:hasEquipArea(0) then
		return ai_choice_result(("0"), options)
	elseif not self.player:hasEquipArea(2) then
		return ai_choice_result(("2"), options)
	elseif not self.player:hasEquipArea(3) then
		return ai_choice_result(("3"), options)
	elseif not self.player:hasEquipArea(4) then
		return ai_choice_result(("4"), options)
	else
		return ai_choice_result((items[1]), options)
	end

    return ai_choice_result(nil, options)
end

--魄袭
ai_fill_skill.poxi = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("poxi","PoxiCard",request)
end

ai_card_use.PoxiCard = function(self, card, use, request)
	if #self.enemies<=0 then return end
	local target = nil
	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:doDisCard(p,"h")
		then target = p	break end
	end
	if not target then return end
	write(self,"poxi_target",nil)
	if target:getHandcardNum()>0 then
		use.card = self:bindSkillCard("poxi",{},nil,nil,"PoxiCard")
		write(self,"poxi_target",target)
		use.to:append(target)
	end
end

ai_skill_use["@@poxi"] = function(self, prompt, request)
	if read(self,"poxi_target") then
		local target_handcards = disclosed_hand(self,read(self,"poxi_target"))
		target_handcards = self:sortByUseValue(target_handcards,inverse)
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0

		for _,c in sgs.list(target_handcards)do
			if spade_check and c:getSuit()==sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards,c:getKnownEffectiveId())
			elseif heart_check and c:getSuit()==sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards,c:getKnownEffectiveId())
			elseif club_check and c:getSuit()==sgs.Card_Club then
				club_check = false
				table.insert(discard_cards,c:getKnownEffectiveId())
			elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards,c:getKnownEffectiveId())
			end
			target_discard_count = #discard_cards
		end

		for _,c in sgs.list(handcards)do
			if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink")==1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic")==1 and c:isKindOf("Analeptic"))
			then
				if spade_check and c:getSuit()==sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards,c:getKnownEffectiveId())
				elseif heart_check and c:getSuit()==sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards,c:getKnownEffectiveId())
				elseif club_check and c:getSuit()==sgs.Card_Club then
					club_check = false
					table.insert(discard_cards,c:getKnownEffectiveId())
				elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards,c:getKnownEffectiveId())
				end
			end
		end

		if target_discard_count==4 and not self.player:isWounded() then return "." end
		if 4-target_discard_count==1 and self.player:getHandcardNum()>self.player:getMaxCards() then return "." end

		if #discard_cards==4 then
			return response(self,"poxi","PoxiDisCard",discard_cards)
		end
	end
	return "."
end

sgs.ai_use_priority.PoxiCard = 3
sgs.ai_use_value.PoxiCard = 3
sgs.ai_card_intention.PoxiCard = 50

--劫营
sgs.ai_skill_playerchosen.jieyingg = function(self,targets)
	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)

	for _,enemy in sgs.list(self.enemies)do
		if enemy:containsTrick("indulgence") then
			return enemy
		end
	end
	local second
	for _,enemy in sgs.list(self.enemies)do
		if enemy:faceUp() and not enemy:hasSkills("tenyearliegong|tieji") and not self:needKongcheng(enemy)
		and not (enemy:hasSkills("rende|nosrende|olrende|tenyearrende|nosmingjian|mingjian|mizhao") and self:findFriendsByType(sgs.Friend_Draw,enemy)) then
			if not enemy:inMyAttackRange(self.player) or enemy:getHandcardNum()>3 or self:hasSkills(sgs.notActive_cardneed_skill, enemy) then return enemy end
			if not second then second = enemy end
		end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,friend in sgs.list(self.friends_noself)do
		if self:needKongcheng(friend) or friend:hasSkills("tenyearliegong|tieji|rende|nosrende|olrende|tenyearrende|nosmingjian|mingjian|mizhao") then
			return friend
		end
	end
	if second then return second end
	return nil
end


--OL夺锐
ai_skill_invoke.olduorui = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (duorui_invoke(self,data,true)) or false
end

ai_skill_choice.olduorui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toDamage().to
	local skills = choices:split("+")

	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return ai_choice_result((sk), options)
		end
	end

	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return ai_choice_result((sk), options)
		end
	end

	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return ai_choice_result((not_bad_skills[math.random(1,#not_bad_skills)]), options)
	end

	return ai_choice_result((skills[math.random(1,#skills)]), options)
end

--OL止啼
local function getEquipAreaNum(player)
	local num = 0
	if player:hasEquipArea(0) then num = num+1 end
	if player:hasEquipArea(1) then num = num+1 end
	if player:hasEquipArea(2) then num = num+1 end
	if player:hasEquipArea(3) then num = num+1 end
	if player:hasEquipArea(4) then num = num+1 end
	return num
end

local function hasOnlyEquipArea(player,area)
	if not area then return false end
	if not player:hasEquipArea(area) then return false end
	for i = 0,4 do
		if i==area then continue end
		if player:hasEquipArea(i) then return false end
	end
	return true
end

local function getOnlyEquipArea(player)
	local num = -1
	for i = 0,4 do
		if hasOnlyEquipArea(player,i) then return i end
	end
	return num
end

sgs.ai_skill_playerchosen.olzhiti = function(self,targets)
	local players = {}
	for _,p in sgs.list(targets)do
		if self:isFriend(p) and hasOnlyEquipArea(p,1) and p:getEquip(1) and self:needToThrowArmor(p) then return p end
		if self:isEnemy(p) and getOnlyEquipArea(p)>-1 and p:getEquip(getOnlyEquipArea(p)) and self:doDisCard(p,"e") then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and p:hasEquipArea() and p:getEquips():isEmpty() and getOnlyEquipArea(p)>-1 then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and p:hasEquipArea() and p:getEquips():isEmpty() and p:hasSkills(sgs.lose_equip_skill) then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and p:hasEquipArea() and p:getEquips():isEmpty() then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and getEquipAreaNum(p)<=2*p:getEquips():length() and self:doDisCard(p,"e") then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and getEquipAreaNum(p)<=2*p:getEquips():length() then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players,"defense")
		return players[1]
	end

	return nil
end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["duorui"]
    local damage_known = AIValue.requireKnownFor("ajustDamage", "damage projection is unknown: ")
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        local duorui_ready
        if from:objectName() == self.player:objectName() then
                    local names = damage_known(self.player:getPropertyValue("duorui_skills") or {}, "owner duorui acquisition state")
                    if not AIValue.isList(names) then ai_unsupported("invalid owner duorui acquisition state", "canLoseHp") end
                    duorui_ready = #names < 1
                else
                    duorui_ready = damage_call(self, "useKnowledgeEstimate", {
                        value=true, status="estimate", viewer=self.player:objectName(), target=from:objectName(),
                        basis="foreign_duorui_readiness_assumed_from_public_skill_private_acquisitions_excluded"
                    }, "canLoseHp.duorui")
                end
        if duorui_ready and damage_call(from, "hasSkill", "duorui") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["duorui"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_hostile" and context.rule == "duorui" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "duorui", {
        {phase="can_lose_hostile", order=6, rule="duorui"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["duorui"]
    local policy = function(self, to, context)
        local value, strategy_call = context.value, context.query
        local from, is_slash, lock, same_player, strategy_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4], context.extra[5]
        do
                -- Source reads the property length BEFORE checking the skill.
                local ready
                if same_player(from, self.player) then
                    local names = self.player:getPropertyValue("duorui_skills") or {}
                    if type(names) ~= "table" then ai_unsupported("owner duorui skill state is malformed", "duorui_skills") end
                    ready = #names < 1
                else
                    ready = self:useKnowledgeEstimate({value = true, status = "estimate", viewer = self.player:objectName(), target = from:objectName(),
                        basis = "foreign_duorui_readiness_assumed_from_public_skill_private_acquisitions_excluded"}, "justDamage.duorui")
                end
                if ready and strategy_call(from,"hasSkill","duorui") then return true, true end
            end
        return value
    end
    sgs.ai_target_damage["duorui"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "just_damage_after_relation" and context.rule == "duorui" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "duorui", {
        {phase="just_damage_after_relation", order=2, rule="duorui"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["olduorui"]
    local policy = function(self, to, context)
        local value, strategy_call = context.value, context.query
        local from, is_slash, lock, same_player, strategy_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4], context.extra[5]
        if strategy_call(from, "hasSkill", "olduorui") then return true, true end
        return value
    end
    sgs.ai_target_damage["olduorui"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "just_damage_after_relation" and context.rule == "olduorui" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "olduorui", {
        {phase="just_damage_after_relation", order=3, rule="olduorui"},
    })
end)()
end
