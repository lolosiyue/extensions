-- Source: b6025acc ai/guo-ai.lua.
local known = AIValue.requireKnown

-- The viewer's own player tag; an absent tag is no player.
local function fact_player(self,key)
    local name=self.player:getTag(key)
    if name==nil or name=="" then return nil end
    return known(self.room:findPlayerByObjectName(name,true),key)
end
local function yinni(self,player)
    local value=player:inYinniState()
    if value~=nil then return value end
    if AIValue.sameLegacyIdentity(player,self.player)then ai_unsupported("owner Yinni state unknown","guo")end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="foreign_yinni_inactive_prior",viewer=self.player:objectName(),observer=player:objectName()},"guo.inYinniState")
end
local function tuishi_from(self)return fact_player(self,"jintuishi_from")end
local function niluan(self,...)
    -- The donor calls whichever @mobileniluan callback this VM registered.
    local callback=sgs.ai_skill_cardask["@mobileniluan"]
    if callback==nil then error("attempt to call a nil value (field '@mobileniluan')",0)end
    return callback(self,...)
end

--推弑
sgs.ai_skill_playerchosen.jintuishi = function(self,targets)
	local from = tuishi_from(self)
	if self:isFriend(from) then return nil end
	targets = self:sort(targets)
	local slash = known(self:getEvaluationCard("slash"),"Slash")

	for _,p in sgs.list(targets)do
		if self:isEnemy(from,p) and self:slashIsEffective(slash,p,from) and self:needLeiji(p,from) then
			return p
		end
	end

	for _,p in sgs.list(targets)do
		if self:isFriend(from,p) and self:slashIsEffective(slash,p,from) then
			return p
		end
	end

	for _,p in sgs.list(targets)do
		if self:isFriend(from,p) then
			return p
		end
	end

	for _,p in sgs.list(targets)do
		if not self:isFriend(p) then
			return p
		end
	end

	if getCardsNum("Slash",from,self.player)<1 then
		targets = sgs.reverse(targets)
		return targets[1]
	end
end

sgs.ai_skill_cardask["@jintuishi_slash"] = function(self,data,pattern,target)
	return niluan(self,data,pattern,target)
end

sgs.ai_can_damagehp.jintuishi = function(self,from,card,to)
	local gc = self.room:getCurrent()
	for _,p in sgs.list(gc:getAliveSiblings())do
		if gc:inMyAttackRange(p)
		and yinni(self,to)
		then
			if self:isEnemy(p) and not self:isFriend(gc)
			or not self:isFriend(p) and self:isEnemy(gc)
			then return true end
		end
	end
end

--筹伐
ai_fill_skill.jinchoufa = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jinchoufa","JinChoufaCard",request)
end

ai_card_use.JinChoufaCard = function(self, card, use, request)
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if p:isKongcheng() then continue end
		if self:hasCrossbowEffect(p) then
			use.card = self:bindSkillCard("jinchoufa",{},nil,nil,"JinChoufaCard")
			use.to:append(p)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:isKongcheng() or self:hasCrossbowEffect(p) then continue end
		use.card = self:bindSkillCard("jinchoufa",{},nil,nil,"JinChoufaCard")
		use.to:append(p)
		return
	end
end

sgs.ai_use_value.JinChoufaCard = 10

--昭然
ai_skill_invoke.jinzhaoran = true

sgs.ai_skill_playerchosen.jinzhaoran = function(self,targets)
	return self:findPlayerToDiscard("he",false,true,targets)[1]
end

--识人
ai_skill_invoke.jinshiren = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = data:toPlayer()
	if self:isFriend(current) then
		return (self:doDisCard(current,"h",true)
		or self:needToThrowLastHandcard(current)
		or self:getOverflow(current)>2) or false
	elseif self:isEnemy(current) then
		return (self:doDisCard(current,"h",true)
		or not self:needToThrowLastHandcard(current)) or false
	end
	return (true) or false
end

sgs.ai_can_damagehp.jinshiren = function(self,from,card,to)
	return (self:isEnemy(self.room:getCurrent()) or #self.friends_noself<1)
	and yinni(self,to)
end

--宴戏
ai_fill_skill.jinyanxi = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	return self:legacySkillSeed("jinyanxi","JinYanxiCard",request)
end

ai_card_use.JinYanxiCard = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,p in sgs.list(self.enemies)do
		if self:doDisCard(p,"h",true) then
			use.card = self:bindSkillCard("jinyanxi",{},nil,nil,"JinYanxiCard")
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.JinYanxiCard = 10
sgs.ai_card_intention.JinYanxiCard = 50

--三陈
ai_fill_skill.jinsanchen = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jinsanchen","JinSanchenCard",request)
end

ai_card_use.JinSanchenCard = function(self, card, use, request)
	self.friends = self:sort(self.friends,"handcard")
	self.friends = sgs.reverse(self.friends)
	for _,p in sgs.list(self.friends)do
		if not self:doDisCard(p,"h") and p:getStrategyMark("jinsanchen_target-Clear")==0 then
			use.card = self:bindSkillCard("jinsanchen",{},nil,nil,"JinSanchenCard")
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getStrategyMark("jinsanchen_target-Clear")>0 then continue end
		use.card = self:bindSkillCard("jinsanchen",{},nil,nil,"JinSanchenCard")
		use.to:append(p)
		return
	end
end

sgs.ai_use_value.JinSanchenCard = 10
sgs.ai_card_intention.JinSanchenCard = -50

sgs.ai_skill_discard.jinsanchen = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummyreason",discard_num,min_num,false,include_equip)
end

--破竹
ai_fill_skill.jinpozhu = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile()
	cards = self:sortByUseValue(cards,true,"l")
	if #cards<1 then return end
	if self:getUseValue(cards[1])>sgs.ai_use_value.Chuqibuyi then return end
	local suit = cards[1]:getSuitString()
	local number = cards[1]:getNumberString()
	local card_id = cards[1]:getKnownEffectiveId()
    return self:evaluateTurnConversion("jinpozhu","Chuqibuyi",{name="chuqibuyi",skill="jinpozhu",suit=cards[1]:getSuit(),number=cards[1]:getNumber(),subcards={card_id}},request)
end

sgs.ai_skill_cardask["@jinshenpin-card"] = function(self,data)
	local judge = data:toJudge()
	local all_cards = self:addHandPile("he")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,c in sgs.list(all_cards)do
		if c:getColor()~=judge.card:getColor()
		then table.insert(cards,c) end
	end
	if #cards<1 then return "." end
    cards = self:sortByUseValue(cards)
	if self:needRetrial(judge)
	then
    	local id = self:getRetrialCardId(cards,judge)
    	if id~=-1 then return id end
	end
    return "."
end

ai_skill_choice.jinzhongyun = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"discard")
	then
		for _,ep in sgs.list(self.enemies)do
			if self:isWeak(ep) or ep:hasEquip()
			then return ai_choice_result(("discard"), options) end
		end
	end
	if table.contains(items,"draw")
	then return ai_choice_result(("draw"), options) end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.jinzhongyun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and (self:isWeak(target) or target:hasEquip())
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_playerchosen.jingaoling = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:isWounded()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and target:isWounded()
		then return target end
	end
end

sgs.ai_can_damagehp.jingaoling = function(self,from,card,to)
    for _,p in sgs.list(self.friends)do
		if p:isWounded() and not self:isFriend(self.room:getCurrent())
		or self:isWeak(p) then return yinni(self,to) end
	end
end

sgs.ai_skill_playerchosen.jinqimei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:isWounded()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and target:isWounded()
		then return target end
	end
end

ai_skill_invoke.jinzhuiji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:isWeak() or self.player:getHandcardNum()<5 and not self:isWeak()) or false
end

ai_skill_choice.jinzhuiji = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"draw")
	and self.player:getHandcardNum()<4 and not self:isWeak()
	then return ai_choice_result(("draw"), options) end
	if table.contains(items,"recover")
	and self:isWeak()
	then return ai_choice_result(("recover"), options) end
	return ai_choice_result(("recover"), options)
end












