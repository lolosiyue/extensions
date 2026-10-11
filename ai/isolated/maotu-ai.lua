-- Fixed b6025acc Maotu effective source; no global Card/Player caches.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("maotu fact unknown",k)end;return v end
local function q(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if type(o[k])~="function"then ai_unsupported("maotu helper unavailable",k)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"end;return known(o[k](o,...),k)end
local function known_card(self,id)return known(self:getKnownCardById(id),"disclosed card "..tostring(id))end
local function fact(self,key)return known(known(self.world.strategy_facts.maotu,"maotu")[key],key)end
local function property(self,key)return known(known(self.world.strategy_facts.owner_skill_properties,"owner properties")[key],key)end
local function clone(self,skill,name,ids)
    return self:evaluateOwnerViewAsCard({source_key=skill,skill=skill,name=name,suit=sgs.Card_NoSuit,number=0,subcards=ids})
end
local function proposal(card,skill)return{name=q(card,"objectName"),skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards=q(card,"getSubcards")}end
local function response_cost(self,skill,ids)
    if skill=="mtweiqie" then
        -- The source returns a Slash proposal. Native MTWeiqie creates a
        -- DummyCard selection; do not silently replace the source policy card.
        return q(clone(self,skill,"slash",ids),"getLegacyStringKey")
    end
    return self:bindSkillCard(skill,ids)
end
local function response_use(self,skill,ids,names,request,policy)
    if skill=="mtxianzheng" then
        request=q(self,"getSkillAction")
        if q(request,"getActivationSkillName")~=skill then ai_unsupported("Maotu selected inquiry differs",skill)end
    end
    local card=self:bindSkillCard(skill,ids,request)
    if policy and (q(card,"objectName")~=q(policy,"objectName") or q(card,"getClassName")~=q(policy,"getClassName")
        or q(card,"getSuit")~=q(policy,"getSuit") or q(card,"getNumber")~=q(policy,"getNumber")
        or q(card,"getSkillName",false)~=skill)then ai_unsupported("Maotu native selected face differs",skill)end
    local spec=q(card,"toCardSpec")
    if policy then
        if not AIValue.isList(spec.subcards)or #spec.subcards~=#ids then ai_unsupported("Maotu selected costs differ",skill)end
        for i,id in ipairs(ids)do if spec.subcards[i]~=id then ai_unsupported("Maotu selected order differs",skill)end end
    end
    return {kind="use_card",card_spec=spec,targets=names}
end
local function owner_use(self)
    local row=fact(self,"mtrenyu_use")
    if row==false then return {from=nil,to=AIList.new({}),card=nil}end
    return {from=row.from and self.room:findPlayerByObjectName(row.from,true)or nil,card=row.card and CardView.new(row.card)or nil}
end
local function write(self,key,value)
    if key~="mtxianzheng_cid"and value then value=value:objectName()end
    self:setStrategyMemory("maotu."..key,value==nil and false or value)
end
local function read(self,key)
    local value,present=self:getStrategyMemory("maotu."..key);if not present or value==false then return nil end
    if key~="mtxianzheng_cid"then return known(self.room:findPlayerByObjectName(value,true),key)end
    return value
end

sgs.ai_skill_choice.mtwenqi = function(self,choices,data)
	local items = choices:split("+")
	if not q(self.player,"faceUp")
	then return items[2] end
	local to = data:toPlayer()
	local suits = {}
	for c,id in sgs.list(to:getPile("yhjyye"))do
		c = known_card(self,id)
		if not table.contains(suits,q(c,"getSuit"))
		then table.insert(suits,q(c,"getSuit")) end
	end
	suits = 4-#suits
	if to:objectName()==self.player:objectName()
	and suits>1 then return items[2] end
	if suits<2 then return items[1] end
end

sgs.ai_guhuo_card.mtzhihe = function(self,cname,class_name)
	local cs = AIList.new({})
	local suits = {}
	for c,id in sgs.list(self.player:getPile("yhjyye"))do
		c = known_card(self,id)
		if not table.contains(suits,q(c,"getSuit"))
		then table.insert(suits,q(c,"getSuit")) end
	end
	suits = 4-#suits
	if suits<1 then suits = 1 end
	for d,h in sgs.list(self:sortByKeepValue(self.player:getCards("h"),nil,"l"))do
		if cs:length()<1 or q(h,"getSuit")==known_card(self,cs:at(0)):getSuit()
		then cs:append(q(h,"getEffectiveId")) end
		if cs:length()>=suits
		then
			d = clone(self,"mtzhihe",cname,cs)
            return proposal(d,"mtzhihe")
		end
	end
end

sgs.ai_fill_skill.mtzhihe = function(self,inclusive,request)
    local cards = {}
	local suits = {}
	for c,id in sgs.list(self.player:getPile("yhjyye"))do
		c = known_card(self,id)
		if not table.contains(suits,q(c,"getSuit"))
		then table.insert(suits,q(c,"getSuit")) end
		if q(c,"isKindOf","BasicCard") or c:isNDTrick()
		then table.insert(cards,c) end
	end
	if #cards<1 then return end
	suits = 4-#suits
	local cs = AIList.new({})
	if suits<1 then suits = 1 end
	for d,h in sgs.list(self:sortByKeepValue(self.player:getCards("h"),nil,"l"))do
		if cs:length()<1 or q(h,"getSuit")==known_card(self,cs:at(0)):getSuit()
		then cs:append(q(h,"getEffectiveId")) end
		if cs:length()>=suits then break end
	end
	if cs:length()<suits then return end
	suits = {}
	for d,c in sgs.list(cards)do
		d = self:evaluateTurnConversion("mtzhihe",q(c,"getClassName"),{name=c:objectName(),skill="mtzhihe",suit=sgs.Card_NoSuit,number=0,subcards=cs},request)
		local dc = self:aiUseCard(d)
		if dc.card
		then
			if dc.to:length()<1 and q(d,"canRecast")
			then continue end
			return d
		end
	end
end

sgs.ai_skill_cardask["@mtjiye"] = function(self,data,pattern,prompt)
    local cs = self.player:getCards("he")
    cs = self:sortByUseValue(cs)
    local tocs = {}
	local yhjyye = self.player:getPile("yhjyye")
	for can,c in sgs.list(self:poisonCards("e"))do
    	if #tocs<#cs/2
		then
			for d,id in sgs.list(yhjyye)do
				d = known_card(self,id)
				if q(d,"getSuit")==q(c,"getSuit")
				then can = false break end
			end
			for d,id in sgs.list(tocs)do
				d = known_card(self,id)
				if q(d,"getSuit")==q(c,"getSuit")
				then can = false break end
			end
			if can
			then
				table.insert(tocs,q(c,"getEffectiveId"))
			end
		end
	end
	for can,c in sgs.list(cs)do
    	if #tocs<#cs/2
		and (q(c,"isKindOf","BasicCard") or c:isNDTrick())
		then
			for d,id in sgs.list(yhjyye)do
				d = known_card(self,id)
				if q(d,"getSuit")==q(c,"getSuit")
				or d:objectName()==c:objectName()
				then can = false break end
			end
			for d,id in sgs.list(tocs)do
				d = known_card(self,id)
				if q(d,"getSuit")==q(c,"getSuit")
				or d:objectName()==c:objectName()
				then can = false break end
			end
			if can
			then
				table.insert(tocs,q(c,"getEffectiveId"))
			end
		end
	end
	if #tocs>0
	then
		return response_cost(self,"mtjiye",tocs)
	end
	return "."
end

sgs.ai_skill_cardask["@mtlunhuan-discard"] = function(self,data,pattern,prompt)
	local record = property(self,"MTLunhuanSuits"):split("+")
    local selected = {}
	local to = data:toPlayer()
	for _,c in sgs.list(self:sortByKeepValue(self.player:getCards("he")))do
		if table.contains(record,q(c,"getSuitString"))
		then
			table.insert(selected,q(c,"getEffectiveId"))
			table.removeOne(record,q(c,"getSuitString"))
		end
	end
    if #selected>=q(to,"getHp")
	and #selected>=#record
	and #selected-q(to,"getHp")<2
	and self:isEnemy(to) then return response_cost(self,"mtlunhuan",selected) end
	return "."
end

sgs.ai_skill_playerchosen.mtlunhuan = function(self,players)
	local destlist = self:sort(players,"hp")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(target,"getHandcardNum")>=q(target,"getHp")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and q(target,"getHandcardNum")>=q(target,"getHp")
		then return target end
	end
end

sgs.ai_skill_cardask["@mtguqu-discard4"] = function(self,data,pattern,prompt)
	return sgs.ai_skill_cardask["@mtguqu-discard1"](self,data,pattern,prompt)
end

sgs.ai_skill_cardask["@mtguqu-discard3"] = function(self,data,pattern,prompt)
	return sgs.ai_skill_cardask["@mtguqu-discard1"](self,data,pattern,prompt)
end

sgs.ai_skill_cardask["@mtguqu-discard2"] = function(self,data,pattern,prompt)
	return sgs.ai_skill_cardask["@mtguqu-discard1"](self,data,pattern,prompt)
end

sgs.ai_skill_cardask["@mtguqu-discard1"] = function(self,data,pattern,prompt)
	local record = property(self,"MTGuquSuits"):split("+")
    local selected = {}
	local cs = {}
	for _,c in sgs.list(self:sortByKeepValue(self.player:getCards("he")))do
		if table.contains(record,q(c,"getSuitString"))
		then
			local can = true
			for _,d in sgs.list(cs)do
				if q(d,"getSuit")==q(c,"getSuit")
				then can = false break end
			end
			if can
			then
				table.insert(cs,c)
				table.insert(selected,q(c,"getEffectiveId"))
			end
		end
	end
    if #cs<3 and #record==#cs then return response_cost(self,"mtguqu",selected) end
	return "."
end

-- V2 proxy activations are keyed by skill name.

sgs.ai_fill_skill.mtguzhao = function(self,inclusive,request)
	return self:legacySkillSeed("mtguzhao","ActiveSkillCard",request)
end

sgs.ai_skill_use_func.mtguzhao = function(card,use,self)
	local mc = self:getMaxCard()
	if not (mc and q(mc,"getNumber")>9) then return end
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"canPindian",p)
		then
			if use.to:length()<1
			then
				use.card = self:bindSkillCard("mtguzhao",{},nil,nil,"ActiveSkillCard")
				use.to:append(p)
			else
				for _,to in sgs.list(use.to)do
					if q(p,"isAdjacentTo",to)
					then use.to:append(p) break end
				end
			end
			if use.to:length()>2
			then return end
		end
	end
end

sgs.ai_use_value.mtguzhao = 5.4
sgs.ai_use_priority.mtguzhao = 3.8

sgs.ai_skill_invoke.mtjiawei = function(self,data)
	local str = data:toString():split(":")
	local to = self.room:findPlayerByObjectName(str[2])
	if to and self:isFriend(to)
	then
		return q(self.player,"getHandcardNum")>q(to,"getHandcardNum")
	end
end

sgs.ai_skill_playerchosen.mtjiawei = function(self,players)
	local destlist = self:sort(players,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"getHandcardNum")>q(self.player,"getHandcardNum")
		then return target end
	end
end

sgs.ai_skill_playerchosen.mtfengshang = function(self,players)
	local destlist = self:sort(players,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"getHandcardNum")<=q(self.player,"getHandcardNum")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and q(target,"getHandcardNum")<=q(self.player,"getHandcardNum")
		then return target end
	end
end

sgs.ai_skill_invoke.mtrenyu_jin = function(self,data)
	local use = owner_use(self)
    if self:isFriend(use.from)
	then return true
	elseif self:isWeak()
	and q(use.card,"isDamageCard")
	then return true end
end

sgs.ai_skill_invoke.mtrenyu = function(self,data)
	local to = data:toPlayer()
    if self:isFriend(to)
	then
		return self:doDisCard(to,"e") or self:isWeak(to)
	end
end

sgs.ai_skill_playerchosen.mtfuzhan = function(self,players)
	local destlist = self:sort(players,"hp")
	local mc = self:getMaxCard()
	if not (mc and q(mc,"getNumber")>9)
	then return end
	for _,to in sgs.list(destlist)do
		if self:isEnemy(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isFriend(to)
		then return to end
	end
end

sgs.ai_skill_cardask["@mtfeiren"] = function(self,data)
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local use = data:toCardUse()
   	for _,h in sgs.list(cards)do
   		if self:getUseValue(h)<self:getUseValue(use.card) and q(use.card,"isAvailable",self.player)
		or use.card:subcardsLength()>1 then return q(h,"getEffectiveId") end
	end
end

sgs.ai_view_as.mtfeiren = function(card,player,card_place,class_name)
	if q(card,"isKindOf","EquipCard")
	and card_place~=sgs.Player_PlaceSpecial
	then
    	return {name="slash",skill="mtfeiren",suit=sgs.Card_NoSuit,number=0,subcards={q(card,"getEffectiveId")}}
	end
end

sgs.ai_skill_use["@@mtrenyi2"] = function(self,prompt,method,pattern,request)
	local d = q(self.player,"getMark","mtrenyi_id-Clear")-1
	d = known_card(self,d)
    local c = clone(self,"_mtrenyi",d:objectName(),{})
    local dummy = self:aiUseCard(c)
   	if dummy.card and dummy.to
   	then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
		return response_use(self,"mtrenyi",{},tos,request)
    end
end

sgs.ai_skill_invoke.mtrenyi = function(self,data)
    return true
end

sgs.ai_skill_askforag.mtrenyi = function(self,card_ids)
	for c,id in sgs.list(card_ids)do
		c = known_card(self,id)
		c = self:getEvaluationCard(c:objectName())
		if c and self:aiUseCard(c).card
		then return id end
	end
end

sgs.ai_skill_use["@@mtrenyi1"] = function(self,prompt,method,pattern,request)
    local cs = self.player:getCards("he")
    cs = self:sortByUseValue(cs,true)
    local tocs = {}
	local n = q(self.player,"getMark","mtrenyiShowNum-Clear")
	for _,c in sgs.list(cs)do
    	if #tocs<n
		then
			table.insert(tocs,q(c,"getEffectiveId"))
		end
	end
	cs = {}
	for _,p in sgs.list(self.friends_noself)do
		if #cs<n
		then
			table.insert(cs,p:objectName())
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if #cs<n and not self:isEnemy(p) and #tocs<q(self.player,"getCardCount")/2
		and not table.contains(cs,p:objectName())
		then table.insert(cs,p:objectName()) end
	end
	if #cs==#tocs
	and #tocs==n
	then
		return response_use(self,"mtrenyi",tocs,cs,request)
	end
end

sgs.ai_skill_discard.mtdianpei = function(self,x,n)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to_cards = {}
   	for _,h in sgs.list(cards)do
   		if #to_cards<n
		then
         	table.insert(to_cards,q(h,"getEffectiveId"))
		end
	end
	local to = self.room:getCurrent()
	if #to_cards<#cards/2 and self:isEnemy(to)
	and q(to,"getHp")<3 then return to_cards end
	return {}
end

sgs.ai_skill_playerchosen.mtdianpei = function(self,players)
	local destlist = self:sort(players,"card")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(self.player,"getHandcardNum")<q(self.player,"getHp")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_choice.mtzhilie = function(self,choices,data)
	local items = choices:split("+")
	for d,c in sgs.list(items)do
		d = c:split("=")
		if c:startsWith("damage")
		and self:damageIsEffective(self.room:findPlayerByObjectName(d[3]),"N",self.player)
		then return c end
	end
	for d,c in sgs.list(items)do
		d = c:split("=")
		if c:startsWith("use")
		and self:hasTrickEffective(self:getEvaluationCard(d[3]),self.room:findPlayerByObjectName(d[2]),self.player)
		then return c end
	end
	return items[1]
end

sgs.ai_fill_skill.mtzhilie = function(self,inclusive,request)
	return self:legacySkillSeed("mtzhilie","ActiveSkillCard",request)
end

sgs.ai_skill_use_func.mtzhilie = function(card,use,self)
	for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>0
		and use.to
		then
			use.card = self:bindSkillCard("mtzhilie",{},nil,nil,"ActiveSkillCard")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.mtzhilie = 5.4
sgs.ai_use_priority.mtzhilie = 4.8

sgs.ai_skill_invoke.mtguanda = function(self,data)
    return true
end

sgs.ai_skill_invoke.mtweiqie = function(self,data)
    return true
end

sgs.ai_skill_cardask["@mtweiqie"] = function(self,data,pattern,prompt)
    local cs = {}
    local tocs = {}
	for _,c in sgs.list(fact(self,"mtweiqie_ids"))do
		table.insert(cs,CardView.new(known(fact(self,"mtweiqie_cards")[tostring(c)],"mtweiqie public face")))
	end
    cs = self:sortByUseValue(cs)
	local function Judge(a,b)
		if b==0 then return a
		else return Judge(b,a%b) end
	end
	for can,c in sgs.list(cs)do
		for _,d in sgs.list(tocs)do
			if Judge(q(c,"getNumber"),q(d,"getNumber"))~=1
			then can = false break end
		end
    	if can
		then
			table.insert(tocs,c)
		end
	end
	if #tocs>0
	then
		local ids={};for _,c in ipairs(tocs)do ids[#ids+1]=q(c,"getEffectiveId")end
        return response_cost(self,"mtweiqie",ids)
	end
	return "."
end

sgs.ai_skill_invoke.mtzhongyi = function(self,data)
	local str = data:toString():split(":")
	local to = self.room:findPlayerByObjectName(str[2])
	if to and str[1]=="draw"
	then
		return self:isFriend(to)
	end
	if to and str[1]=="current"
	then
		return not self:isFriend(to) or self:doDisCard(to,"e")
	end
end

sgs.ai_fill_skill.mtjieli = function(self,inclusive,request)
    local cards = self.player:getCards("h")
	local cs = {}
	for _,h in sgs.list(self:sortByUseValue(cards,nil,"l"))do
		if #cs<1
		or q(h,"getColor")==known_card(self,cs[1]):getColor()
		then table.insert(cs,q(h,"getEffectiveId")) end
	end
	if #cs<1 then return end
	-- The proxy declares the colour; every hand card of it becomes the Duel.
	return self:evaluateTurnSkillCard("mtjieli","ActiveSkillCard",{},request,known_card(self,cs[1]):isRed() and "red" or "black")
end

sgs.ai_skill_use_func.mtjieli = function(card,use,self)
	local ids = {}
	for _,h in sgs.list(self.player:getHandcards())do
		if card:getUserString()=="red" and q(h,"isRed")
		or card:getUserString()=="black" and q(h,"isBlack")
		then table.insert(ids,q(h,"getEffectiveId")) end
	end
	local d = self:aiUseCard(clone(self,"mtjieli","duel",ids))
	if d.card
	and use.to
	then
		use.card = card
		use.to = d.to
	end
end

sgs.ai_use_value.mtjieli = 5.4
sgs.ai_use_priority.mtjieli = 2.8

sgs.ai_skill_choice.mtliaoshi = function(self,choices,data)
	local items = choices:split("+")
	return "recover"
end

sgs.ai_skill_playerchosen.mtnianchou = function(self,players)
	local destlist = sgs.QList2Table(players)
	destlist = self:sort(destlist,"card")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self.player:distanceTo(target)>1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_cardchosen.mtxianzheng = function(self,who,flags,method)
	return read(self,"mtxianzheng_cid")
end

sgs.ai_skill_playerchosen.mtxianzheng_to = function(self,players)
    return read(self,"mtxianzheng_to")
end

sgs.ai_skill_playerchosen.mtxianzheng_from = function(self,players)
    return sgs.QList2Table(players)[1]
end

sgs.ai_skill_invoke.mtxianzheng = function(self,data)
	local to = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	write(self,"mtxianzheng_cid",nil)
	write(self,"mtxianzheng_to",nil)
	if to
	then
		local p,c = self:card_for_qiaobian(to)
		if p and c
		then
			write(self,"mtxianzheng_to",p)
			write(self,"mtxianzheng_cid",q(c,"getEffectiveId"))
			return true
		end
	end
end

sgs.ai_skill_use["@@mtxianzheng"] = function(self,prompt)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,"l")
    local ids={q(cards[1],"getEffectiveId")}
    local c = clone(self,"mtxianzheng","slash",ids)
    local dummy = self:aiUseCard(c)
   	if dummy.card
   	and dummy.to
   	then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return response_use(self,"mtxianzheng",ids,tos,nil,c)
    end
end

sgs.ai_skill_playerchosen.mttongyi = function(self,players)
    return read(self,"mttongyi_to")
end

sgs.ai_skill_choice.mtliaoshi = function(self,choices,data)
	local items = choices:split("+")
	write(self,"mttongyi_to",nil)
	if table.contains(items,"lose")
	and q(self.player,"hasSkill","mttongyi")
	and not self:isWeak()
	then
		for _,ep in sgs.list(self.enemies)do
			if q(ep,"getHp")<2
			and q(ep,"getMark","mttongyi_target-Keep")<1
			then
				write(self,"mttongyi_to",ep)
				return "lose"
			end
		end
	end
	if table.contains(items,"discard")
	and q(self.player,"hasSkill","mttongyi")
	and q(self.player,"getCardCount")>2
	then
		for _,ep in sgs.list(self.enemies)do
			if q(ep,"getCardCount")==2
			and q(ep,"getMark","mttongyi_target-Keep")<1
			then
				write(self,"mttongyi_to",ep)
				return "discard"
			end
		end
	end
	if table.contains(items,"recover")
	and q(self.player,"hasSkill","mttongyi")
	and q(self.player,"getCardCount")>2
	then
		for _,ep in sgs.list(self.friends_noself)do
			if self:isWeak(ep) and q(ep,"getLostHp")>0
			and q(ep,"getMark","mttongyi_target-Keep")<1
			then
				write(self,"mttongyi_to",ep)
				return "recover"
			end
		end
	end
	if table.contains(items,"recover")
	and self:isWeak()
	then
		return "recover"
	end
	return "draw"
end

