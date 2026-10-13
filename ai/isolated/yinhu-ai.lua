-- Yinhu: fixed b6025acc source. Cross-inquiry state contains only primitives.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("yinhu fact unknown",k)end;return v end
local function q(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"end;if k=="hasFlag"and AIValue.isPlayer(o)then k="getStrategyFlag"end;if type(o[k])~="function"then ai_unsupported("yinhu helper unavailable",k)end;return known(o[k](o,...),k)end
local function known_card(self,id)return known(self:getKnownCardById(id),"disclosed card "..tostring(id))end
-- The viewer's own property, read like the donor's toString() (absent reads "").
local function property(self,k)local v=self.player:getPropertyValue(k);if v==nil then return""end;return v end
local function write(self,key,v)
 if key=="yhbianzhan_c"then v=v and v:getEffectiveId()
 elseif key=="yhyuren_to"then if v then local names={};for _,p in sgs.list(v)do names[#names+1]=p:objectName()end;v=names end
 elseif key~="ispc"then v=v and v:objectName()end
 self:setStrategyMemory("yinhu."..key,v==nil and false or v)
end
local function read(self,key)
 local v,ok=self:getStrategyMemory("yinhu."..key);if not ok or v==false then return nil end
 if key=="yhbianzhan_c"then return known_card(self,v)
 elseif key=="yhyuren_to"then local ps={};for _,name in ipairs(v)do ps[#ps+1]=known(self.room:findPlayerByObjectName(name,true),key)end;return AIList.new(ps)
 elseif key~="ispc"then return known(self.room:findPlayerByObjectName(v,true),key)end
 return v
end
local function clone(self,skill,name,ids)return self:evaluateOwnerViewAsCard({source_key=skill,skill=skill,name=name,suit=sgs.Card_NoSuit,number=0,subcards=ids})end
local function turn_clone(self,skill,name,ids,request)
 local base=self:getEvaluationCard(name);if not base then return nil end
 return self:evaluateTurnConversion(skill,base:getClassName(),{name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=ids},request)
end
local function converted_use(self,skill,c,tos)
 local spec={name=c:objectName(),skill=skill,suit=c:getSuit(),number=c:getNumber(),subcards=c:getSubcards()}
 if skill=="yhduwei" or skill=="yhshanhai" then
  local request=q(self,"getSkillAction")
  if q(request,"getActivationSkillName")~=skill then ai_unsupported("Yinhu selected inquiry differs",skill)end
  local paid=q(self,"bindSkillCard",skill,spec.subcards,request)
  if q(paid,"objectName")~=spec.name or q(paid,"getClassName")~=q(c,"getClassName")
   or q(paid,"getSuit")~=spec.suit or q(paid,"getNumber")~=spec.number
   or q(paid,"getSkillName",false)~=skill then ai_unsupported("Yinhu native selected face differs",skill)end
  local exact=q(paid,"toCardSpec")
  if not AIValue.isList(exact.subcards)or #exact.subcards~=#spec.subcards then ai_unsupported("Yinhu selected costs differ",skill)end
  for i,id in ipairs(spec.subcards)do if exact.subcards[i]~=id then ai_unsupported("Yinhu selected order differs",skill)end end
  return {kind="use_card",card_spec=exact,targets=tos}
 end
 local policy=self:getConversionPolicy(c:getClassName());local selected
 for _,row in ipairs(policy.skills)do if row.skill_name==skill then
  if selected then ai_unsupported("ambiguous response source",skill)end;selected=row
 end end
 if not selected then ai_unsupported("response source scope missing",skill)end
 local paid=self:resolveResponseConversion(spec,selected)
 return {kind="use_card",card_spec=known(paid,"selected response"):toCardSpec(),targets=tos}
end
local function visible_draw_cards(self)
 -- The donor walks the draw pile, whose contents are not projected.
 ai_unsupported("draw-pile contents are not projected","yhbuque")
end
local function foreign_plan(self,player,card)
 ai_unsupported("source calls another player's private SmartAI planning; no viewer-equivalent planner","yhmeiying")
end
local function podi_mark(self,p)
 self:addStrategyPlayerMark(p,"yhpodi_to-PlayClear",1)
end
local function select_peiqi(self)
 local f=sgs.ai_skill_invoke.peiqi;if type(f)~="function"then ai_unsupported("source peiqi dependency not loaded","yhshoulu")end
 return f(self,{isNull=function()return true end,toPlayer=function()return nil end})
end
local function peiqi_data(self)
 local row,ok=self:getStrategyMemory("yjcm2022.peiqiData")
 if not ok or type(row)~="table"then ai_unsupported("source peiqi selection missing","yhshoulu")end
 return {cid=row.cid,from=known(self.room:findPlayerByObjectName(row.from,true),"peiqi from"),to=known(self.room:findPlayerByObjectName(row.to,true),"peiqi to")}
end

sgs.ai_fill_skill.yhshecuo = function(self,inclusive,request)
	return self:legacySkillSeed("yhshecuo","YHShecuoCard",request)
end

sgs.ai_skill_use_func["YHShecuoCard"] = function(card,use,self)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")>=q(self.player,"getHp")
		then
			use.card = self:bindSkillCard("yhshecuo",{},nil,nil,"YHShecuoCard")
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHandcardNum")>=q(self.player,"getHandcardNum")
		then
			use.card = self:bindSkillCard("yhshecuo",{},nil,nil,"YHShecuoCard")
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHandcardNum")>0
		then
			use.card = self:bindSkillCard("yhshecuo",{},nil,nil,"YHShecuoCard")
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.YHShecuoCard = 2.4
sgs.ai_use_priority.YHShecuoCard = 1.8

sgs.ai_skill_playerchosen.yhyingfu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	write(self,"yf_to",nil)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:isWeak(target)
		then
			write(self,"yf_to",target)
			return target
		end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and not self:isWeak(target)
		then
			write(self,"yf_to",target)
			return target
		end
	end
	write(self,"yf_to",destlist[1])
    return destlist[1]
end

sgs.ai_skill_cardask.yhyingfu = function(self,data,pattern,prompt)
    local parsed = prompt:split(":")
    if read(self,"yf_to")
	and not self:isFriend(read(self,"yf_to"))
	then
    	if parsed[1]=="slash-jink"
		then
	    	parsed = data:toCardEffect()
			if self:canLoseHp(parsed.from,parsed.slash)
			then return false end
		else
	    	parsed = data:toCardEffect()
			local card = parsed.card
			if card and q(card,"isDamageCard")
			and self:canLoseHp(parsed.from,parsed.card)
			then return false end
		end
	end
end

sgs.ai_nullification.yhyingfu = function(self,trick,from,to,positive)
    if q(to,"hasSkill","yhyingfu")
	and self:isFriend(to)
	and read(self,"yf_to")
	and not self:isFriend(read(self,"yf_to"))
	and q(trick,"isDamageCard")
   	and self:canLoseHp(from,trick,to)
	then return false end
end

sgs.ai_skill_playerchosen.yhnabi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and not self:isWeak(target)
		then return target end
	end
	return self:isWeak() and destlist[1]
end

sgs.ai_skill_defense.yhnabi = function(self, player)
	for _,p in sgs.qlist(player:getAliveSiblings())do
		if q(p,"getMark","&yhyffu+#"..player:objectName())>0
		then return q(p,"getHp") end
	end
	return 0
end

sgs.ai_fill_skill.yhyijie = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	for _,c in sgs.list(cards)do
		if q(c,"getSuit")==2
		then return self:evaluateTurnSkillCard("yhyijie","YHYijieCard",{q(c,"getEffectiveId")},request) end
	end
end

sgs.ai_skill_use_func["YHYijieCard"] = function(card,use,self)
	for _,ep in sgs.list(self.friends)do
		if self:isWeak(ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends)do
		if q(ep,"isWounded")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.YHYijieCard = 6.4
sgs.ai_use_priority.YHYijieCard = 4.8

sgs.ai_skill_askforyiji.yhxinghan = function(self,card_ids)
	local cards = {}
	for d,id in sgs.list(card_ids)do
		table.insert(cards,known_card(self,id))
	end
	cards = self:sortByKeepValue(cards)
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if not self:isFriend(p) then continue end
		return p,q(cards[1],"getEffectiveId")
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if self:isEnemy(p) then continue end
		return p,q(cards[1],"getEffectiveId")
	end
end

sgs.ai_fill_skill.yhxinghan = function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards)
  	for d,c in sgs.list(cards)do
	   	local fs = turn_clone(self,"yhxinghan","slash",{q(c,"getEffectiveId")},request)
		if q(fs,"isAvailable",self.player)
		and q(self.player,"getMark","yhxinghan-PlayClear")==1
		and q(c,"getTypeId")~=1
	   	then return fs end
	end
end

sgs.ai_fill_skill.yhbianzhan = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	write(self,"yhbianzhan_c",nil)
  	for _,c in sgs.list(cards)do
		if q(c,"getNumber")>9
		or #cards>q(self.player,"getMaxCards")
		then
			write(self,"yhbianzhan_c",c)
			return self:legacySkillSeed("yhbianzhan","YHBianzhanCard",request)
		end
	end
end

sgs.ai_skill_use_func["YHBianzhanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHandcardNum")>q(self.player,"getHandcardNum")
		then
			use.card = self:bindSkillCard("yhbianzhan",{},nil,nil,"YHBianzhanCard")
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.YHBianzhanCard = 9.4
sgs.ai_use_priority.YHBianzhanCard = 4.4

sgs.ai_skill_discard.yhjifeng = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    handcards = self:sortByKeepValue(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>1 then break end
		table.insert(cards,q(h,"getEffectiveId"))
	end
	if read(self,"yhbianzhan_c")
	and read(self,"yhbianzhan_c"):getSuit()==3
	and read(self,"yhbianzhan_c"):getNumber()>9
	then return cards end
end

sgs.ai_skill_playerchosen.yhjifeng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(target,"getHandcardNum")>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and q(target,"getHandcardNum")>0
		then return target end
	end
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_fill_skill.yhhuntian = function(self,inclusive,request)
	return self:legacySkillSeed("yhhuntian","YHHuntianCard",request)
end

sgs.ai_skill_use_func["YHHuntianCard"] = function(card,use,self)
	use.card = self:bindSkillCard("yhhuntian",{},nil,nil,"YHHuntianCard")
end

sgs.ai_use_value.YHHuntianCard = 2.4
sgs.ai_use_priority.YHHuntianCard = 1.8

sgs.ai_skill_invoke.yhhuntian = function(self,data)
    return true
end


sgs.ai_skill_playerchosen.yhceri = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_invoke.yhsancai = function(self,data)
    return true
end

sgs.ai_skill_askforyiji.yhsancai = function(self,card_ids)
	local cards = {}
	for d,id in sgs.list(card_ids)do
		table.insert(cards,known_card(self,id))
	end
	cards = self:sortByKeepValue(cards)
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if q(p,"hasFlag","yhsancai_give")
		or not self:isFriend(p)
		then continue end
		return p,q(cards[1],"getEffectiveId")
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if q(p,"hasFlag","yhsancai_give")
		or self:isEnemy(p)
		then continue end
		return p,q(cards[1],"getEffectiveId")
	end
end

sgs.ai_skill_discard.yhjuyi = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    handcards = self:sortByKeepValue(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>0 then break end
		table.insert(cards,q(h,"getEffectiveId"))
	end
   	local target = self.room:getCurrent()
	if not self:isEnemy(target)
	then return {} end
	return #handcards>3 and cards or {}
end

sgs.ai_skill_invoke.yhhanjie = function(self,data)
	local target = self.player
	local use = data:toCardUse()
	return not self:isFriend(use.from)
	and q(use.card,"getNumber")>8
end

sgs.ai_fill_skill.yhjuxian = function(self,inclusive,request)
	if #self.friends_noself>0
	then
		return self:legacySkillSeed("yhjuxian","YHJuxianCard",request)
	end
end

sgs.ai_skill_use_func["YHJuxianCard"] = function(card,use,self)
	use.card = self:bindSkillCard("yhjuxian",{},nil,nil,"YHJuxianCard")
end

sgs.ai_use_value.YHJuxianCard = 3.4
sgs.ai_use_priority.YHJuxianCard = 1.8

sgs.ai_skill_playerchosen.yhjuxian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
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

sgs.ai_skill_playerchosen.yhdujian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_fill_skill.yhbuque_put = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
    for _,p in sgs.list(self.room:findPlayersBySkillName("yhbuque"))do
		if not self:isEnemy(p) and q(p,"getMark","yhbuque_put-PlayClear")<1 and #cards>q(self.player,"getMaxCards")
		then return self:evaluateTurnSkillCard("yhbuque_put","YHBuquePutCard",{q(cards[1],"getEffectiveId")},request) end
	end
	cards = self:poisonCards("e")
    for _,p in sgs.list(self.room:findPlayersBySkillName("yhbuque"))do
		if q(p,"getMark","yhbuque_put-PlayClear")<1 and #cards>0
		then return self:evaluateTurnSkillCard("yhbuque_put","YHBuquePutCard",{q(cards[1],"getEffectiveId")},request) end
	end
end

sgs.ai_skill_use_func["YHBuquePutCard"] = function(card,use,self)
	use.card = card
    for _,p in sgs.list(self.room:findPlayersBySkillName("yhbuque"))do
		if not self:isEnemy(p) and q(p,"getMark","yhbuque_put-PlayClear")<1 and use.to
		then use.to:append(p) return end
	end
    for _,p in sgs.list(self.room:findPlayersBySkillName("yhbuque"))do
		if q(p,"getMark","yhbuque_put-PlayClear")<1 and use.to
		then use.to:append(p) return end
	end
end

sgs.ai_use_value.YHBuquePutCard = 9.4
sgs.ai_use_priority.YHBuquePutCard = -0.4

sgs.ai_fill_skill.yhbuque = function(self)
    local cs=visible_draw_cards(self)
    return #cs>0 and cs
end
sgs.ai_guhuo_card.yhbuque = function(self,toname,class_name)
    for _,c in ipairs(visible_draw_cards(self))do
        if q(c,"isKindOf",class_name)then return c end
    end
end

sgs.ai_skill_invoke.yhchenzhen = function(self,data)
    return q(self.player,"getPhase")<=sgs.Player_Play
	and not self:willSkipPlayPhase()
	and q(self.player,"getMaxHp")>1
	and #self.enemies>0
end

sgs.ai_skill_choice.yhchenzhen = function(self,choices)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_skill_choice.yhchenzhen_num = function(self,choices)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_skill_playerchosen.yhsigong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_fill_skill.yhxijian_give = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	write(self,"ispc",nil)
	local yhxijian = self.room:findPlayerBySkillName("yhxijian")
	if yhxijian and not self:isEnemy(yhxijian) and #cards>q(self.player,"getMaxCards")
	then return self:evaluateTurnSkillCard("yhxijian_give","YHXijianGiveCard",{q(cards[1],"getEffectiveId")},request) end
	cards = self:poisonCards()
	if #cards>0
	then
		write(self,"ispc",true)
		return self:evaluateTurnSkillCard("yhxijian_give","YHXijianGiveCard",{q(cards[1],"getEffectiveId")},request)
	end
end

sgs.ai_skill_use_func["YHXijianGiveCard"] = function(card,use,self)
	if read(self,"ispc")
	then
		for _,ep in sgs.list(self.enemies)do
			if q(ep,"hasSkill","yhxijian")
			and q(ep,"getMark","yhxijian_give-PlayClear")<1
			then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	else
		for _,ep in sgs.list(self.friends_noself)do
			if q(ep,"hasSkill","yhxijian")
			and q(ep,"getMark","yhxijian_give-PlayClear")<1
			then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	end
end

sgs.ai_use_value.YHXijianGiveCard = 9.4
sgs.ai_use_priority.YHXijianGiveCard = -0.4

sgs.ai_skill_playerchosen.yhxijian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_invoke.yhboben = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
end

sgs.ai_skill_discard.yhboben = function(self,x,n)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    handcards = self:sortByKeepValue(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>=n then break end
		table.insert(cards,q(h,"getEffectiveId"))
	end
   	local target = self.room:getCurrent()
	if self:isEnemy(target)
	then return cards end
	return {}
end

sgs.ai_skill_playerchosen.yhjuantu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_fill_skill.yhquanwang = function(self,inclusive,request)
	if q(self.player,"getHandcardNum")>0
	and #self.friends_noself>0
	and self:isWeak()
	then
		return self:legacySkillSeed("yhquanwang","YHQuanwangCard",request)
	end
end

sgs.ai_skill_use_func["YHQuanwangCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,ep in sgs.list(self.friends_noself)do
		use.card = self:bindSkillCard("yhquanwang",{},nil,nil,"YHQuanwangCard")
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.YHQuanwangCard = 3.4
sgs.ai_use_priority.YHQuanwangCard = -1.8

sgs.ai_skill_choice.yhchenwen = function(self,choices)
	local items = choices:split("+")
	local n = q(self.player,"getLostHp")
	n = n>2 and math.random(2,3) or n
	if n>0 and items[1]:startsWith("yhchenwen")
	then return items[n] end
	if table.contains(items,"yhpodi3")
	then return "yhpodi3" end
	if table.contains(items,"yhpodi2")
	then return "yhpodi2" end
	if table.contains(items,"yhshouzhuang")
	then return "yhshouzhuang" end
	if table.contains(items,"yhpodi4")
	then return "yhpodi4" end
	return items[#items]
end

sgs.ai_skill_discard.yhchenwen = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>#cards-q(self.player,"getMaxCards")
		or #to_cards>=3 then break end
		table.insert(to_cards,q(hcard,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_invoke.yhshouzhuang = function(self,data)
	local invoke = data:toPlayer()
	if invoke
	then
		return self:doDisCard(invoke,"he")
		or not self:isFriend(invoke)
	end
	invoke = data:toString()
	if invoke and invoke~=""
	then
		invoke = invoke:split(":")[2]
		invoke = self.room:findPlayerByObjectName(invoke)
		return invoke and (self:doDisCard(invoke,"he") or not self:isFriend(invoke))
	end
end

sgs.ai_skill_choice.yhshouzhuang = function(self,choices,data)
	local items = choices:split("+")
	local to = data:toPlayer()
	local n = items[1]:split("=")[3]
	n = n-0
	if self:isFriend(to)
	then
		if n<=to:getEquips():length()
		then return items[1]
		else return items[2] end
	else
		if n>to:getEquips():length()
		then return items[1]
		else return items[2] end
	end
end

sgs.ai_fill_skill.yhpodi = function(self,inclusive,request)
	return self:legacySkillSeed("yhpodi","YHPodiCard",request)
end

sgs.ai_skill_use_func["YHPodiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHandcardNum")>1
		and q(self.player,"isWounded")
		and q(ep,"getMark","yhpodi_to-PlayClear")<1
		then
			use.card = self:bindSkillCard("yhpodi",{},nil,nil,"YHPodiCard")
			use.to:append(ep)
			podi_mark(self,ep)
			return
		end
	end
end

sgs.ai_use_value.YHPodiCard = 4.4
sgs.ai_use_priority.YHPodiCard = 6.8

sgs.ai_skill_choice.yhpodi = function(self,choices)
	local items = choices:split("+")
	if #items>4 then return items[math.random(2,4)] end
	if #items>3 then return items[math.random(2,3)] end
	if #items>2 then return items[2] end
	return items[#items-1]
end

sgs.ai_fill_skill.yhduwei = function(self,inclusive,request)
  	local name = property(self,"yhduwei_damage_card")
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for _,c in sgs.list(cards)do
	   	if name=="" then break end
		local fs = turn_clone(self,"yhduwei",name,{q(c,"getEffectiveId")},request)
		if self:getCardsNum(q(fs,"getClassName"))<2
	   	then return fs end
	end
end

sgs.ai_skill_use["@@yhduwei"] = function(self,prompt)
  	local name = property(self,"yhduwei_damage_card")
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for dc,c in sgs.list(cards)do
	   	if name=="" then break end
		dc = clone(self,"yhduwei",name,{q(c,"getEffectiveId")})
        if dc==nil then break end
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to
		and q(dc,"isAvailable",self.player)
		then
			if q(dc,"canRecast")
			and dummy.to:length()<1
			then return end
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return converted_use(self,"yhduwei",dc,tos)
		end
    end
end

sgs.ai_skill_invoke.yhsiku = function(self,data)
	local invoke = data:toString()
	if invoke~=""
	then
		invoke = invoke:split(":")[2]
		invoke = self.room:findPlayerByObjectName(invoke)
		return self:isEnemy(invoke) and (not self:isWeak(invoke) or #self.enemies<2 or q(self.player,"isDead"))
	end
end

sgs.ai_skill_invoke.yhqingsi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target) and not self:isWeak()
	end
end

sgs.ai_skill_playerchosen.yhchuzhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0
	then return end
	local n = tonumber(self.player:getTag("YHQingsiNum")) or 0
    for _,target in sgs.list(destlist)do
		if known(self:isFriend(target),"yhchuzhu.isFriend")
		and q(target,"getLostHp")>=n
		then return target end
	end
end

sgs.ai_skill_cardask["@yhhuairen-put"] = function(self,data,pattern)
	return true
end

sgs.ai_fill_skill.yhyuren = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local tocs = {}
  	for d,c in sgs.list(cards)do
		if q(c,"isKindOf","Slash") then table.insert(tocs,c) end
	end
	if #tocs<1 then return end
	for dc,pn in sgs.list(known(AICardCatalog.patternNames(),"patterns"))do
		dc = self:getEvaluationCard(pn)
		if dc and q(dc,"isKindOf","BasicCard")
		and q(dc,"isAvailable",self.player)
		and self:getCardsNum(q(dc,"getClassName"))<1
		then
			dc = clone(self,"yhyuren",pn,{q(tocs[1],"getEffectiveId")})
            local d = self:aiUseCard(dc)
			if d.card and d.to
			then
				write(self,"yhyuren_to",d.to)
				if q(dc,"canRecast") and d.to:length()<1 then continue end
				self:setPriorityValue("YHYurenCard",known(sgs.ai_use_priority[q(dc,"getClassName")],"source priority")-0.3,"yhyuren")
				return self:evaluateTurnSkillCard("yhyuren","YHYurenCard",{q(tocs[1],"getEffectiveId")},request,pn)
			end
		end
	end
end

sgs.ai_skill_use_func["YHYurenCard"] = function(card,use,self)
	if read(self,"yhyuren_to")
	then
		use.card = card
		use.to = read(self,"yhyuren_to")
	end
end

sgs.ai_use_value.YHYurenCard = 5.4
sgs.ai_use_priority.YHYurenCard = 2.8

sgs.ai_guhuo_card.yhyuren = function(self,toname,class_name)
	local cards = self:addHandPile()
	cards = self:sortByKeepValue(cards,nil,true)
  	for d,c in sgs.list(cards)do
		d = self:getEvaluationCard(toname)
		if q(c,"isKindOf","Slash")
		and d and q(d,"isKindOf","BasicCard")
		and self:getCardsNum(q(d,"getClassName"))<2
		and known(self.request.reason,"current use reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		then return {skill="yhyuren",legacy_class="YHYurenCard",subcards={q(c,"getEffectiveId")},user_string=toname} end
	end
end

sgs.ai_skill_playerchosen.yhrangwei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"isWounded")
		and q(self.player,"isWounded")
		then return target end
	end
end

sgs.ai_skill_playerchosen.yhxiaoyun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
end

sgs.ai_fill_skill.yhmeiying = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	self.enemies = self:sort(self.enemies,"hp")
  	for _,c in sgs.list(cards)do
		if q(c,"isAvailable",self.player) then continue end
		for _,fp in sgs.list(self.friends_noself)do
			if q(c,"isAvailable",fp)
			then
				local d = foreign_plan(self,fp,c)
				if d.card and d.to
				then
					write(self,"yhmeiying_to",fp)
					return self:evaluateTurnSkillCard("yhmeiying","YHMeiyingCard",{q(c,"getEffectiveId")},request)
				end
			end
		end
		for _,ep in sgs.list(self.enemies)do
			if q(c,"isAvailable",ep) then continue end
			write(self,"yhmeiying_to",ep)
			return self:evaluateTurnSkillCard("yhmeiying","YHMeiyingCard",{q(c,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["YHMeiyingCard"] = function(card,use,self)
	if read(self,"yhmeiying_to")
	then
		use.card = card
		use.to:append(read(self,"yhmeiying_to"))
	end
end

sgs.ai_use_value.YHMeiyingCard = 5.4
sgs.ai_use_priority.YHMeiyingCard = 2.8

sgs.ai_skill_use["@@yhmeiying"] = function(self,prompt)
  	local c = q(self.player,"getMark","yhmeiying_id-PlayClear")
	c = known_card(self,c)
	local dummy = self:aiUseCard(c)
	if dummy.card and dummy.to
	then
		if q(c,"canRecast")
		and dummy.to:length()<1
		then return end
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return {kind="use_card",card_id=q(c,"getEffectiveId"),targets=tos}
    end
end

sgs.ai_skill_choice.yhkudu = function(self,choices)
	local items = choices:split("+")
	write(self,"yhkudu_to",nil)
	if table.contains(items,"self=judge")
	and self:doDisCard(self.player,"j")
	then return "self=judge" end
	if table.contains(items,"self=discard")
	and q(self.player,"getHandcardNum")>=q(self.player,"getMaxCards")
	then return "self=discard" end
	if table.contains(items,"self=discard")
	then return "self=discard" end
	if table.contains(items,"self=judge")
	then return "self=judge" end
	if table.contains(items,"self=draw")
	and q(self.player,"getHandcardNum")>3
	then return "self=draw" end
	if table.contains(items,"self=play")
	and q(self.player,"getHandcardNum")<3
	then return "self=play" end
	if table.contains(items,"self=draw")
	then return "self=draw" end
	if table.contains(items,"self=play")
	then return "self=play" end

	if table.contains(items,"other=play")
	then
		self.enemies = self:sort(self.enemies,"handcard",true)
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			if q(ep,"getHandcardNum")>2
			then
				return "other=play"
			end
		end
	end
	if table.contains(items,"other=draw")
	then
		self.enemies = self:sort(self.enemies,"handcard")
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			if q(ep,"getHandcardNum")<3
			then
				return "other=draw"
			end
		end
	end
	if table.contains(items,"other=discard")
	then
		self.friends_noself = self:sort(self.friends_noself,"handcard",true)
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			if q(ep,"getHandcardNum")>3
			then
				return "other=discard"
			end
		end
	end
	if table.contains(items,"other=judge")
	then
		self.friends_noself = self:sort(self.friends_noself,"handcard")
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			if self:doDisCard(ep,"j")
			then
				return "other=judge"
			end
		end
	end

	if table.contains(items,"other=play")
	then
		self.enemies = self:sort(self.enemies,"handcard",true)
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			return "other=play"
		end
	end
	if table.contains(items,"other=draw")
	then
		self.enemies = self:sort(self.enemies,"handcard")
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			return "other=draw"
		end
	end
	if table.contains(items,"other=discard")
	then
		self.friends_noself = self:sort(self.friends_noself,"handcard",true)
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			return "other=discard"
		end
	end
	if table.contains(items,"other=judge")
	then
		self.friends_noself = self:sort(self.friends_noself,"handcard")
		for i,ep in sgs.list(self.enemies)do
			write(self,"yhkudu_to",ep)
			return "other=judge"
		end
	end


end

sgs.ai_skill_invoke.yhkudu = function(self,data)
    local choices = "other=play+other=draw+other=discard+other=judge"
	return sgs.ai_skill_choice.yhkudu(self,choices)
end

sgs.ai_skill_playerchosen.yhkudu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if AIValue.sameLegacyIdentity(target,read(self,"yhkudu_to"))
		then return target end
	end
end

sgs.ai_skill_invoke.yhkunmo = function(self,data)
    return true
end

sgs.ai_skill_use["@@yhkunmo"] = function(self,prompt)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true,true)
  	for d,c in sgs.list(cards)do
		if q(c,"isAvailable",self.player)
		then
			local dummy = self:aiUseCard(c)
			if dummy.card and dummy.to
			then
				if q(c,"canRecast")
				and dummy.to:length()<1
				then return end
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				local paid=self:bindSkillCard("yhkunmo",{q(c,"getEffectiveId")},nil,nil,"YHKunmoCard")
                return {kind="use_card",card_spec=paid:toCardSpec(),targets=tos}
			end
		end
    end
end

sgs.ai_skill_playerchosen.yhtanyou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"maxhp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"isWounded")
		then return target end
	end
end

local function bozhi_plan(self,prompt)
  	local c = property(self,"YHBozhiRecordTrick")
	c = clone(self,"yhbozhi",c,{})
	-- Source immediately calls nil:setSkillName when the exact clone is absent.
	if c==nil then error("attempt to index a nil value",0)end
	local dummy = self:aiUseCard(c)
	if dummy.card and dummy.to
	and q(c,"isAvailable",self.player)
	then
		if q(c,"canRecast")
		and dummy.to:length()<1
		then return end
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return c,tos
    end
end

sgs.ai_skill_invoke.yhbozhi = function(self,data)
    local c,tos=bozhi_plan(self,"yhbozhi0")
    if c then return c:getLegacyStringKey().."->"..table.concat(tos,"+")end
end

sgs.ai_skill_use["@@yhbozhi"]=function(self,prompt)
 local c,tos=bozhi_plan(self,prompt);if c then return converted_use(self,"yhbozhi",c,tos)end
end

sgs.ai_skill_invoke.yhjixiang = function(self,data)
	for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(fp)
		then return true end
	end
end

sgs.ai_skill_askforyiji.yhjixiang = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and to:objectName()~=self.player:objectName()
	then return to,id end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,fp in sgs.list(self.friends_noself)do
		return fp,card_ids[1]
	end
	to = self.room:getOtherPlayers(self.player)
	to = self:sort(to,"handcard")
	for _,fp in sgs.list(to)do
		if not self:isEnemy(fp)
		then
			return fp,card_ids[1]
		end
	end
	for _,fp in sgs.list(to)do
		return fp,card_ids[1]
	end
end

sgs.ai_skill_playerchosen.yhguidu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not (self:isFriend(target) or self:isWeak(target))
		then return target end
	end
end

sgs.ai_skill_use["@@yhshanhai"] = function(self,prompt)
  	local ids = property(self,"YHShanhaiGetIds"):split("+")
	for c,id in sgs.list(self.player:handCards())do
		if not table.contains(ids,""..id)
		then continue end
		c = clone(self,"yhshanhai","slash",{id})
		local dummy = self:aiUseCard(c)
		if dummy.card and dummy.to
		and q(c,"isAvailable",self.player)
		then
			if q(c,"canRecast")
			and dummy.to:length()<1
			then return end
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return converted_use(self,"yhshanhai",c,tos)
		end
	end
end

sgs.ai_skill_choice.yhyanglian = function(self,choices)
	local items = choices:split("+")
	return items[math.random(1,#items-1)]
end

sgs.ai_skill_choice.yhxiandao = function(self,choices)
	local items = choices:split("+")
	if q(self.player,"getHandcardNum")<4
	then return items[2] end
	return items[#items]
end

sgs.ai_skill_playerchosen.yhqizu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:isWeak(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and not self:isWeak()
		then return target end
	end
end

sgs.ai_skill_playerchosen.yhshoulu_from = function(self,players)
    if select_peiqi(self)
	then
		for _,target in sgs.list(players)do
			if target:objectName()==peiqi_data(self).from:objectName()
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.yhshoulu_to = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==peiqi_data(self).to:objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.yhshoulu = function(self,who,flags,method)
	for i,c in sgs.list(who:getCards(flags))do
		i = q(c,"getEffectiveId")
		if i==peiqi_data(self).cid
		then return i end
	end
end

sgs.ai_skill_invoke.yhyange = function(self,data)
    return true
end

sgs.ai_skill_choice.yhqupai = function(self,choices)
	local items = choices:split("+")
	if math.random()>0.3
	then return "2" end
	if math.random()>0.6
	then return "1" end
	return "cancel"
end









