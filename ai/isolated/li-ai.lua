-- Fixed b6025acc li policy bodies. Private draw order is never inspected.
local function known(value,key)
    if value==nil then ai_unsupported("li strategy fact is unknown",key)end
    return value
end
local function q(object,key,...)
    if not object or type(object[key])~="function"then ai_unsupported("li helper unavailable",key)end
    if key=="getMark"and AIValue.isPlayer(object)then key="getStrategyMark"end
    if key=="hasFlag"and AIValue.isPlayer(object)then key="getStrategyFlag"end
    local value=object[key](object,...)
    if AIUnsupported and AIUnsupported.is(value)then error(value,0)end
    return known(value,key)
end
local function fact(self,key)
    local row=self.world.strategy_facts and self.world.strategy_facts.li
    if type(row)~="table"then ai_unsupported("li fact group unknown",key)end
    return known(row[key],key)
end
local function fact_player(self,key)
    local name=fact(self,key)
    if name==false then return nil end
    return known(self.room:findPlayerByObjectName(name,true),key)
end
local function property(self,key,expected)
    local fields=self.world.strategy_facts and self.world.strategy_facts.owner_skill_properties
    local value=type(fields)=="table"and fields[key]
    if type(value)~=(expected or "string")then ai_unsupported("owner property unknown",key)end
    return value
end
local function yinni(self,player)
    local value=player:inYinniState()
    if value~=nil then return value end
    if AIValue.sameLegacyIdentity(player,self.player)then ai_unsupported("owner Yinni state unknown","li")end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="foreign_yinni_inactive_prior",viewer=self.player:objectName(),observer=player:objectName()},"li.inYinniState")
end
local function material(card,name,skill)
    return {name=name,skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={q(card,"getEffectiveId")}}
end
local function clone(self,skill,name,ids)
    local c=self:evaluateOwnerViewAsCard({source_key=skill,name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=ids})
    if not c then error("attempt to index a nil value (local 'slash')",0)end
    return c
end
local function turn_skill(self,skill,class,ids,request,user)
    if type(self.evaluateTurnSkillCard)~="function"then ai_unsupported("readonly source SkillCard turn proposal unavailable",skill)end
    return self:evaluateTurnSkillCard(skill,class,ids,request,user)
end
local function disclosed_top(self,count)
    local row=fact(self,"known_draw_top")
    if type(row)~="table"or row.known~=true or not AIValue.isList(row.ids)
        or (#row.ids<count and row.complete~=true)then
        ai_unsupported("JinXiongzhi requires undisclosed top order; no private draw-pile access","jinxiongzhi")
    end
    local ids={};for i=1,math.min(count,#row.ids)do ids[i]=row.ids[i]end
    return ids
end

--不臣
sgs.ai_skill_invoke.jinbuchen = function(self,data)
	local player = data:toPlayer()
	if self:needKongcheng(self.player,true) then return false end
	if self:doDisCard(player,"he") then return true end
end

sgs.ai_can_damagehp.jinbuchen = function(self,from,card,to)
	return self:doDisCard(self.room:getCurrent(),"he",true)
	and yinni(self,to)
end

--雄志
sgs.ai_fill_skill.jinxiongzhi = function(self,inclusive,request)
	return self:legacySkillSeed("jinxiongzhi","JinXiongzhiCard",request)
end

sgs.ai_skill_use_func.JinXiongzhiCard = function(card,use,self)
	local list = disclosed_top(self,q(self.player,"getMaxHp"))
	local use_num = 0
	for _,id in sgs.qlist(list)do
		local card = known(self:getKnownCardById(id),"disclosed card")
		if not q(self.player,"canUse",card) then break end
		if self:willUse(self.player,card)
		then use_num = use_num+1
		else break end
	end
	if use_num>=2 then
		use.card = self:bindSkillCard("jinxiongzhi",{},nil,nil,"JinXiongzhiCard")
	end
end

sgs.ai_use_priority.JinXiongzhiCard = 0

sgs.ai_skill_use["@@jinxiongzhi!"] = function(self,prompt,method)
	local id = q(self.player,"getMark","jinxiongzhi_id-PlayClear")
    local card = known(self:getKnownCardById(id),"disclosed card")
	local dummy = self:aiUseCard(card)
	if dummy.card and dummy.to then
		local tos = {}
		for _,p in sgs.qlist(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return {kind="use_card",card_id=id,targets=tos}
	end
	return "."
end

--权变
sgs.ai_skill_invoke.jinquanbian = function(self,data)
	return self:canDraw()
end

--二版权变
sgs.ai_skill_invoke.secondjinquanbian = function(self,data)
	return self:canDraw()
end

--慧识
sgs.ai_skill_invoke.jinhuishi = function(self,data)
	local num = data:toString():split(":")[2]
	num = tonumber(num)
	num = math.floor(num/2)
	return num>=2
end

--清冷
sgs.ai_skill_use["@@jinqingleng"] = function(self,prompt,method)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)

	local name = property(self,"jinqingleng_now_target")
	local to = self.room:findPlayerByObjectName(name)
	if not to or q(to,"isDead") then return "." end

	local slashs = {}
	for _,c in ipairs(cards)do
		local slash = clone(self,"jinqingleng","slash",{q(c,"getEffectiveId")})
		if q(self.player,"canSlash",to,slash,false) then
			self:setStrategyPlayerFlag(self.player,"slashNoDistanceLimit",true)
			local dummy_use = {isDummy=true,to=AIList.new({}),current_targets={}}
			for _,p in sgs.qlist(self.room:getAlivePlayers())do
				if p:objectName()~=name then
					table.insert(dummy_use.current_targets,p)
				end
			end
			self:useCardSlash(slash,dummy_use)
			self:setStrategyPlayerFlag(self.player,"slashNoDistanceLimit",false)
			if dummy_use.card and dummy_use.to and dummy_use.to:length()>0 then
				table.insert(slashs,c)
			end
		end
	end
	if #slashs==0 then return "." end

	for _,c in ipairs(slashs)do
		if q(c,"isKindOf","Peach") then continue end
		if q(c,"isKindOf","Jink") and self:getCardsNum("Jink")<2 then continue end
		if q(c,"isKindOf","Analeptic") and self:isWeak() then continue end
		if q(c,"isKindOf","ExNihilo") then continue end
		return "@JinQinglengCard="..q(c,"getEffectiveId")
	end
	return "."
end

sgs.ai_can_damagehp.jinxuanmu = function(self,from,card,to)
	return self:isEnemy(self.room:getCurrent())
	and yinni(self,to)
end

--巧言
sgs.ai_skill_discard.qiaoyan = function(self,discard_num,min_num,optional,include_equip)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	if not cards[1]then error("attempt to index a nil value (field integer index)",0)end
	return {q(cards[1],"getEffectiveId")}
end

--献珠
sgs.ai_skill_playerchosen.xianzhu = function(self,targets)
	local cards = {}
	for _,id in sgs.qlist(self.player:getPile("qyzhu"))do
		table.insert(cards,known(self:getKnownCardById(id),"owner pile card"))
	end
	local card,friend = self:getCardNeedPlayer(cards,true)
	if card and friend then return friend end

	self.friends_noself = self:sort(self.friends_noself)

	for _,p in ipairs(self.friends_noself)do
		if self:canDraw(p) and not self:willSkipPlayPhase(p)
		then return p end
	end
	for _,p in ipairs(self.friends_noself)do
		if not (q(p,"isKongcheng") and self:needKongcheng(p,true))
		and not self:willSkipPlayPhase(p)
		then return p end
	end
	for _,p in ipairs(self.friends_noself)do
		if self:canDraw(p)
		then return p end
	end
	for _,p in ipairs(self.friends_noself)do
		if not (q(p,"isKongcheng") and self:needKongcheng(p,true))
		then return p end
	end

	self.enemies = self:sort(self.enemies)
	for _,p in ipairs(self.enemies)do
		if not hasManjuanEffect(p) then continue end
		local slash = clone(self,"_xianzhu","slash",{})
		if q(p,"isLocked",slash) then continue end
		for _,enemy in ipairs(self.enemies)do
			if q(self.player,"inMyAttackRange",enemy)
			and q(p,"canSlash",enemy,slash,false)
			then return p end
		end
	end

	if #cards==1
	then
		if not q(cards[1],"isKindOf","Peach")
		and not q(cards[1],"isKindOf","Jink")
		and not q(cards[1],"isKindOf","Analeptic")
		and not q(cards[1],"isKindOf","ExNihilo")
		then
			for _,p in ipairs(self.enemies)do
				if self:canDraw(p) then continue end
				local slash = clone(self,"_xianzhu","slash",{})
				if q(p,"isLocked",slash) then continue end
				for _,enemy in ipairs(self.enemies)do
					if q(self.player,"inMyAttackRange",enemy)
					and q(p,"canSlash",enemy,slash,false)
					then return p end
				end
			end
		end
	end

	return self.player
end

sgs.ai_skill_playerchosen.xianzhu_target = function(self,targets)
	local from = fact_player(self,"xianzhu_slash_from")
	local enemies,zhongli,friends = {},{},{}
	local slash = clone(self,"_xianzhu","slash",{})
	for _,p in sgs.qlist(targets)do
		if self:slashIsEffective(slash,p,from)
		and not self:slashProhibit(slash,p,from)
		then
			if self:isEnemy(p)
			then table.insert(enemies,p)
			elseif self:isFriend(p)
			then table.insert(friends,p)
			else table.insert(zhongli,p) end
		end
	end
	if #enemies>0 then
		enemies = self:sort(enemies)
		for _,p in ipairs(enemies)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,enemies,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,enemies,slash))
			then return p end
		end
		for _,p in ipairs(enemies)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,enemies,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,enemies,slash))
			then return p end
		end
		for _,p in ipairs(enemies)do
			if self:slashIsEffective(slash,p,from)
			then return p end
		end
		return enemies[1]
	end

	if #zhongli>0
	then
		zhongli = self:sort(zhongli)
		zhongli = sgs.reverse(zhongli)
		for _,p in ipairs(zhongli)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,zhongli,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,zhongli,slash))
			then return p end
		end
		for _,p in ipairs(zhongli)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,zhongli,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,zhongli,slash))
			then return p end
		end
		return zhongli[1]
	end

	if #friends>0
	then
		friends = self:sort(friends)
		friends = sgs.reverse(friends)
		for _,p in ipairs(friends)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,friends,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,friends,slash))
			then return p end
		end
		for _,p in ipairs(friends)do
			if (self:isEnemy(from) and not self:isGoodTarget(p,friends,slash))
			or (self:isFriend(from) and self:isGoodTarget(p,friends,slash))
			then return p end
		end
		return friends[1]
	end
end

--才望
sgs.ai_skill_invoke.jincaiwang = function(self,data)
	local name = data:toString():split(":")[2]
	local to = self.room:findPlayerByObjectName(name)
	if not to then return false end
	return self:isEnemy(to) and self:doDisCard(to,"he")
end

sgs.ai_fill_skill.secondjincaiwang = function(self,inclusive,request)
	local cards = self.player:getCards("j")
	cards = self:sortByKeepValue(cards,nil,"l")
  	for d,c in sgs.list(cards)do
		if #cards<2
		then
			local slash = self:evaluateTurnConversion("secondjincaiwang","Slash",material(c,"slash","secondjincaiwang"),request)
			if self:readonlyTurnAvailability(slash)
			then return slash end
		end
	end
end

sgs.ai_guhuo_card.secondjincaiwang = function(self,toname,class_name)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if #cards==1
	and class_name=="Jink"
	then
		return material(cards[1],"jink","secondjincaiwang")
	end
	cards = self.player:getCards("e")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if #cards==1
	and class_name=="Nullification"
	then
		return material(cards[1],"nullification","secondjincaiwang")
	end
	cards = self.player:getCards("j")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if #cards==1
	and class_name=="Slash"
	then
		return material(cards[1],"slash","secondjincaiwang")
	end
end

--车悬
sgs.ai_skill_invoke.chexuan = function(self,data)
	return true
end

sgs.ai_fill_skill.chexuan = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if q(h,"isBlack")
		then
            return turn_skill(self,"chexuan","ChexuanCard",{q(h,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["ChexuanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ChexuanCard = 4.4
sgs.ai_use_priority.ChexuanCard = 0.4


--草诏
sgs.ai_fill_skill.caozhao = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
    local names = property(self,"CaozhaoNames","table")
	for _,name in sgs.list(known(self.world.strategy_facts.pattern_names,"patterns() order"))do
        if table.contains(names,name) then continue end
		local card = self:getEvaluationCard(name)
		if not card or q(card,"isKindOf","DelayedTrick") then continue end
		card = clone(self,"caozhao",name,{q(cards[1],"getEffectiveId")})
		if self:getUseValue(card)>5
		and math.random()>0.6
		then
			return turn_skill(self,"caozhao","CaozhaoCard",{q(cards[1],"getEffectiveId")},request,name)
		end
	end
end

sgs.ai_skill_use_func["CaozhaoCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.CaozhaoCard = 4.4
sgs.ai_use_priority.CaozhaoCard = 0.4

sgs.ai_skill_playerchosen.caozhao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_playerchosen.caozhao_give = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_choice.caozhao = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local cn = items[1]:split("=")[2]
	local c = self:getEvaluationCard(cn)
	if self:isFriend(target) or self:isWeak()
	then return items[1] end
	if self:isEnemy(target) and not self:isWeak()
	and self:getUseValue(c)>3
	then return items[2] end
end

--息兵
sgs.ai_skill_invoke.olxibing = function(self,data)
	local dama = data:toDamage()
	if dama.from
	then
		if self:isFriend(dama.from)
		then
			if q(self.player,"getHandcardNum")-q(dama.from,"getHandcardNum")>2
			or q(dama.from,"getHandcardNum")-q(self.player,"getHandcardNum")>2
			then return true end
		else
			return true
		end
	end
end

sgs.ai_skill_choice.olxibing = function(self,choices,data)
	local items = choices:split("+")
	local dama = data:toDamage()
	if table.contains(items,"discard_self")
	then
		if q(self.player,"getHandcardNum")-q(dama.from,"getHandcardNum")<2
		then return "discard_self" end
	end
    for _,item in sgs.list(items)do
		if item~="discard_self"
		then return item end
	end
end
