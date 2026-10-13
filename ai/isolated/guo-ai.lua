-- Fixed b6025acc guo effective callbacks. Earlier same-key definitions are superseded.
local function known(value,key)
    if value==nil then ai_unsupported("guo strategy fact is unknown",key)end
    return value
end
local function q(object,key,...)
    if not object or type(object[key])~="function"then ai_unsupported("guo helper unavailable",key)end
    if key=="getMark"and AIValue.isPlayer(object)then key="getStrategyMark"end
    if key=="hasFlag"and AIValue.isPlayer(object)then key="getStrategyFlag"end
    local value=object[key](object,...)
    if AIUnsupported and AIUnsupported.is(value)then error(value,0)end
    return known(value,key)
end
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
		if q(gc,"inMyAttackRange",p)
		and yinni(self,to)
		then
			if self:isEnemy(p) and not self:isFriend(gc)
			or not self:isFriend(p) and self:isEnemy(gc)
			then return true end
		end
	end
end

--筹伐
sgs.ai_fill_skill.jinchoufa = function(self,inclusive,request)
	return self:legacySkillSeed("jinchoufa","JinChoufaCard",request)
end

sgs.ai_skill_use_func.JinChoufaCard = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if q(p,"isKongcheng") then continue end
		if self:hasCrossbowEffect(p) then
			use.card = self:bindSkillCard("jinchoufa",{},nil,nil,"JinChoufaCard")
			use.to:append(p)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if q(p,"isKongcheng") or self:hasCrossbowEffect(p) then continue end
		use.card = self:bindSkillCard("jinchoufa",{},nil,nil,"JinChoufaCard")
		use.to:append(p)
		return
	end
end

sgs.ai_use_value.JinChoufaCard = 10

--昭然
sgs.ai_skill_invoke.jinzhaoran = true

sgs.ai_skill_playerchosen.jinzhaoran = function(self,targets)
	return self:findPlayerToDiscard("he",false,true,targets)[1]
end

--识人
sgs.ai_skill_invoke.jinshiren = function(self,data)
	local current = data:toPlayer()
	if self:isFriend(current) then
		return self:doDisCard(current,"h",true)
		or self:needToThrowLastHandcard(current)
		or self:getOverflow(current)>2
	elseif self:isEnemy(current) then
		return self:doDisCard(current,"h",true)
		or not self:needToThrowLastHandcard(current)
	end
	return true
end

sgs.ai_can_damagehp.jinshiren = function(self,from,card,to)
	return (self:isEnemy(self.room:getCurrent()) or #self.friends_noself<1)
	and yinni(self,to)
end

--宴戏
sgs.ai_fill_skill.jinyanxi = function(self,inclusive,request)
	if #self.enemies<=0 then return end
	return self:legacySkillSeed("jinyanxi","JinYanxiCard",request)
end

sgs.ai_skill_use_func.JinYanxiCard = function(card,use,self)
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
sgs.ai_fill_skill.jinsanchen = function(self,inclusive,request)
	return self:legacySkillSeed("jinsanchen","JinSanchenCard",request)
end

sgs.ai_skill_use_func.JinSanchenCard = function(card,use,self)
	self.friends = self:sort(self.friends,"handcard")
	self.friends = sgs.reverse(self.friends)
	for _,p in sgs.list(self.friends)do
		if not self:doDisCard(p,"h") and q(p,"getMark","jinsanchen_target-Clear")==0 then
			use.card = self:bindSkillCard("jinsanchen",{},nil,nil,"JinSanchenCard")
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.friends)do
		if q(p,"getMark","jinsanchen_target-Clear")>0 then continue end
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
sgs.ai_fill_skill.jinpozhu = function(self,inclusive,request)
	local cards = self:addHandPile()
	cards = self:sortByUseValue(cards,true,"l")
	if #cards<1 then return end
	if self:getUseValue(cards[1])>sgs.ai_use_value.Chuqibuyi then return end
	local suit = q(cards[1],"getSuitString")
	local number = q(cards[1],"getNumberString")
	local card_id = q(cards[1],"getEffectiveId")
    return self:evaluateTurnConversion("jinpozhu","Chuqibuyi",{name="chuqibuyi",skill="jinpozhu",suit=q(cards[1],"getSuit"),number=q(cards[1],"getNumber"),subcards={card_id}},request)
end

sgs.ai_skill_cardask["@jinshenpin-card"] = function(self,data)
	local judge = data:toJudge()
	local all_cards = self:addHandPile("he")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,c in sgs.list(all_cards)do
		if q(c,"getColor")~=q(judge.card,"getColor")
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

sgs.ai_skill_choice.jinzhongyun = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"discard")
	then
		for _,ep in sgs.list(self.enemies)do
			if self:isWeak(ep) or q(ep,"hasEquip")
			then return "discard" end
		end
	end
	if table.contains(items,"draw")
	then return "draw" end
end

sgs.ai_skill_playerchosen.jinzhongyun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and (self:isWeak(target) or q(target,"hasEquip"))
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
		and q(target,"isWounded")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and q(target,"isWounded")
		then return target end
	end
--	return destlist[1]
end

sgs.ai_can_damagehp.jingaoling = function(self,from,card,to)
    for _,p in sgs.list(self.friends)do
		if q(p,"isWounded") and not self:isFriend(self.room:getCurrent())
		or self:isWeak(p) then return yinni(self,to) end
	end
end

sgs.ai_skill_playerchosen.jinqimei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"isWounded")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and q(target,"isWounded")
		then return target end
	end
--	return destlist[1]
end

sgs.ai_skill_invoke.jinzhuiji = function(self,data)
    return self:isWeak() or q(self.player,"getHandcardNum")<5 and not self:isWeak()
end

sgs.ai_skill_choice.jinzhuiji = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"draw")
	and q(self.player,"getHandcardNum")<4 and not self:isWeak()
	then return "draw" end
	if table.contains(items,"recover")
	and self:isWeak()
	then return "recover" end
	return "recover"
end












