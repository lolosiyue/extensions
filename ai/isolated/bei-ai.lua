-- Fixed b6025acc bei source bodies, including legacy-native ABI differences.
-- State stores only primitive IDs/names and disclosed value descriptors.
local function known(value,key)
    if value==nil then ai_unsupported("bei strategy fact is unknown",key)end
    return value
end
local function q(object,key,...)
    if not object or type(object[key])~="function"then ai_unsupported("bei helper unavailable",key)end
    if key=="getMark"and AIValue.isPlayer(object)then key="getStrategyMark"end
    if key=="hasFlag"and AIValue.isPlayer(object)then key="getStrategyFlag"end
    local value=object[key](object,...)
    if AIUnsupported and AIUnsupported.is(value)then error(value,0)end
    return known(value,key)
end
local function fact(self,key)
    local row=self.world.strategy_facts and self.world.strategy_facts.bei
    if type(row)~="table"then ai_unsupported("bei fact group unknown",key)end
    return known(row[key],key)
end
local function fact_player(self,key)
    local name=fact(self,key)
    if name==false then return nil end
    return known(self.room:findPlayerByObjectName(name,true),key)
end
local function property(self,key)
    local fields=self.world.strategy_facts and self.world.strategy_facts.owner_skill_properties
    local value=type(fields)=="table"and fields[key]
    if type(value)~="string"then ai_unsupported("owner property unknown",key)end
    return value
end
local function yinni(self,player)
    local value=player:inYinniState()
    if value~=nil then return value end
    if AIValue.sameLegacyIdentity(player,self.player)then ai_unsupported("owner Yinni state unknown","bei")end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="foreign_yinni_inactive_prior",viewer=self.player:objectName(),observer=player:objectName()},"bei.inYinniState")
end
local function save_targets(self,key,targets)
    local names={};for _,p in ipairs(targets)do names[#names+1]=p:objectName()end
    self:setStrategyMemory(key,names)
end
local function load_targets(self,key)
    local row,present=self:getStrategyMemory(key)
    if not present then return nil end
    local result=AIList.new({});for _,name in ipairs(row)do result:append(known(self.room:findPlayerByObjectName(name,true),key))end
    return result
end
local function save_use(self,key,use)
    local row={to={}}
    if use.from then row.from=use.from:objectName()end
    for _,p in ipairs(use.to)do row.to[#row.to+1]=p:objectName()end
    if use.card then
        if type(use.card._view)~="table"then ai_unsupported("use card lacks pure descriptor",key)end
        row.card=use.card._view
    end
    self:setStrategyMemory(key,row)
end
local function load_use(self,key,optional)
    local row,present=self:getStrategyMemory(key)
    if not present or row==false then return nil end
    local use={to=AIList.new({})}
    for _,name in ipairs(row.to)do use.to:append(known(self.room:findPlayerByObjectName(name,true),key))end
    if row.from then use.from=known(self.room:findPlayerByObjectName(row.from,true),key)end
    if row.card then use.card=CardView.new(row.card)end
    return use
end
local function chuming_clone(self,name,ids)
    local costs={};for _,id in ipairs(ids)do costs[#costs+1]=tonumber(id)end
    local card=self:evaluateOwnerViewAsCard({source_key="chuming",name=name,skill="_chuming",suit=sgs.Card_NoSuit,number=0,subcards=costs})
    if not card then error("attempt to index a nil value (local 'dc')",0)end
    return card
end
local function tousui_proposal(self,ids,request)
    -- Native support must supply the source SkillCard hypothesis without paying
    -- during fill; the selected proposal is bound only at final materialization.
    if type(self.evaluateTurnSkillCard)~="function"then ai_unsupported("readonly TousuiCard turn proposal unavailable","tousui")end
    return self:evaluateTurnSkillCard("tousui","TousuiCard",ids,request)
end

--宝箧
sgs.ai_skill_invoke.jinbaoqie = function(self,data)
	return not self.player:getTreasure()
end

sgs.ai_can_damagehp.jinbaoqie = function(self,from,card,to)
	return yinni(self,to)
end

--宜室
sgs.ai_skill_use["@@jinyishi"] = function(self,data)
	local card_ids = fact(self,"jinyishi_card_ids")
	card_ids = sgs.QList2Table(card_ids)
	local who = fact_player(self,"jinyishi_from")

	if self:isLihunTarget(self.player,#card_ids-1) then return "." end
	local invoke = (self:isFriend(who) and not (q(who,"hasSkill","kongcheng") and q(who,"isKongcheng")))
					or (#card_ids>=3 and not q(self.player,"hasSkill","manjuan"))
					or (#card_ids==2 and not q(self,"hasSkills",sgs.cardneed_skill,who) and not q(self.player,"hasSkill","manjuan"))
					or (self:isEnemy(who) and q(who,"hasSkill","kongcheng") and q(who,"isKongcheng"))
	if not invoke then return "." end

	local wulaotai = self.room:findPlayerBySkillName("buyi")
	local Need_buyi = wulaotai and q(who,"getHp")==1 and self:isFriend(who,wulaotai)

	local cards,except_Equip,except_Key = {},{},{}
	for _,card_id in sgs.list(card_ids)do
		local card = known(self:getKnownCardById(card_id),"jinyishi card")
		if q(self.player,"hasSkills","zhijian|mobilezhijianzhan") and not q(card,"isKindOf","EquipCard") then
			table.insert(except_Equip,card)
		end
		if not q(card,"isKindOf","Peach") and not q(card,"isKindOf","Jink") and not q(card,"isKindOf","Analeptic") and
			not q(card,"isKindOf","Nullification") and not (q(card,"isKindOf","EquipCard") and q(self.player,"hasSkills","zhijian|mobilezhijianzhan")) then
			table.insert(except_Key,card)
		end
		table.insert(cards,card)
	end

	if self:isFriend(who) then

		if Need_buyi then
			local buyicard1,buyicard2
			cards = self:sortByKeepValue(cards)
			for _,card in sgs.list(cards)do
				if q(card,"isKindOf","TrickCard") and not buyicard1 then
					buyicard1 = q(card,"getEffectiveId")
				end
				if not q(card,"isKindOf","BasicCard") and not buyicard2 then
					buyicard2 = q(card,"getEffectiveId")
				end
				if buyicard1 then break end
			end
			if buyicard1 then
				return "@JinYishiCard="..buyicard1
			elseif buyicard2 then
				return "@JinYishiCard="..buyicard2
			end
		end

		local peach_num,peach,jink,analeptic,slash = 0,nil,nil,nil,nil
		for _,card in sgs.list(cards)do
			if q(card,"isKindOf","Peach") then peach = q(card,"getEffectiveId") peach_num = peach_num+1 end
			if q(card,"isKindOf","Jink") then jink = q(card,"getEffectiveId") end
			if q(card,"isKindOf","Analeptic") then analeptic = q(card,"getEffectiveId") end
			if q(card,"isKindOf","Slash") then slash = q(card,"getEffectiveId") end
		end
		if peach then
			if peach_num>1
				or (self:getCardsNum("Peach")>=q(self.player,"getMaxCards"))
				or (q(who,"getHp")<getBestHp(who) and q(who,"getHp")<q(self.player,"getHp")) then
					return "@JinYishiCard="..peach
			end
		end
		if self:isWeak(who) and (jink or analeptic) then
			if jink then
				return "@JinYishiCard="..jink
			elseif analeptic then
				return "@JinYishiCard="..analeptic
			end
		end

		for _,card in sgs.list(cards)do
			if not q(card,"isKindOf","EquipCard") then
				for _,askill in sgs.qlist(who:getVisibleSkillList(true))do
					local callback = self:getHooks("ai_cardneed")[askill:objectName()]
					if type(callback)=="function" and callback(who,card,self) then
						return "@JinYishiCard="..q(card,"getEffectiveId")
					end
				end
			end
		end

		if jink or analeptic or slash then
			if jink then
				return "@JinYishiCard="..jink
			elseif analeptic then
				return "@JinYishiCard="..analeptic
			elseif slash then
				return "@JinYishiCard="..slash
			end
		end

		for _,card in sgs.list(cards)do
			if not q(card,"isKindOf","EquipCard") and not q(card,"isKindOf","Peach") then
				return "@JinYishiCard="..q(card,"getEffectiveId")
			end
		end

	else

		if Need_buyi then
			for _,card in sgs.list(cards)do
				if q(card,"isKindOf","Slash") then
					return "@JinYishiCard="..q(card,"getEffectiveId")
				end
			end
		end

		for _,card in sgs.list(cards)do
			if q(card,"isKindOf","EquipCard") and q(self.player,"hasSkills","zhijian|mobilezhijianzhan") then
				local Cant_Zhijian = true
				for _,friend in sgs.list(self.friends)do
					if not self:getSameEquip(card,friend) then
						Cant_Zhijian = false
					end
				end
				if Cant_Zhijian then
					return "@JinYishiCard="..q(card,"getEffectiveId")
				end
			end
		end

		local new_cards = (#except_Key>0 and except_Key) or (#except_Equip>0 and except_Equip) or cards

		new_cards = self:sortByKeepValue(new_cards)
		local valueless,slash
		for _,card in sgs.list (new_cards)do
			if q(card,"isKindOf","Lightning") and not q(self,"hasSkills",sgs.wizard_harm_skill,who) then
				return "@JinYishiCard="..q(card,"getEffectiveId")
			end

			if q(card,"isKindOf","Slash") then slash = q(card,"getEffectiveId") end

			if not valueless and not q(card,"isKindOf","Peach") then
				for _,askill in sgs.qlist(who:getVisibleSkillList(true))do
					local callback = self:getHooks("ai_cardneed")[askill:objectName()]
					if (type(callback)=="function" and not callback(who,card,self)) or not callback then
						valueless = q(card,"getEffectiveId")
						break
					end
				end
			end
		end

		if slash or valueless then
			if slash then
				return "@JinYishiCard="..slash
			elseif valueless then
				return "@JinYishiCard="..valueless
			end
		end

		return "@JinYishiCard="..q(new_cards[1],"getEffectiveId")
	end
end

--识度
sgs.ai_fill_skill.jinshidu = function(self,inclusive,request)
	return self:legacySkillSeed("jinshidu","JinShiduCard",request)
end

sgs.ai_skill_use_func.JinShiduCard = function(card,use,self)
	local max_card = self:getMaxCard()
	if max_card then
		local number = q(max_card,"getNumber")
		if q(self.player,"hasSkill","tianbian") and q(max_card,"getSuit")==sgs.Card_Heart then number = 13 end
		if number>=7 then
			self.enemies = self:sort(self.enemies,"handcard")
			self.enemies = sgs.reverse(self.enemies)
			for _,p in sgs.list(self.enemies)do
				if math.floor((q(p,"getHandcardNum")+q(self.player,"getHandcardNum"))/2)<q(self.player,"getHandcardNum") then continue end
				if self:doDisCard(p,"h",true) and q(self.player,"canPindian",p)
				then
					use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
					self:remember("jinshidu_card",q(max_card,"getEffectiveId"))
					use.to:append(p)
					return
				end
			end

			self.friends_noself = self:sort(self.friends_noself,"handcard")
			for _,p in sgs.list(self.friends_noself)do
				if math.floor((q(p,"getHandcardNum")+q(self.player,"getHandcardNum"))/2)<q(p,"getHandcardNum")
				or q(p,"hasSkill","kongcheng") and q(p,"getHandcardNum")==1 then continue end
				if self:doDisCard(p,"h",true) and q(self.player,"canPindian",p)
				then
					self:setPriorityValue("JinShiduCard",5,"bei")
					use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
					self:remember("jinshidu_card",q(max_card,"getEffectiveId"))
					use.to:append(p)
					return
				end
			end
			for _,p in sgs.list(self.friends_noself)do
				if not q(self.player,"canPindian",p) then continue end
				if math.floor((q(p,"getHandcardNum")+q(self.player,"getHandcardNum"))/2)<q(p,"getHandcardNum") then continue end
				--if self:needKongcheng(p,true) then continue end
				if q(p,"hasSkill","kongcheng") and q(p,"getHandcardNum")==1 then continue end
				self:setPriorityValue("JinShiduCard",5,"bei")
				use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
				self:remember("jinshidu_card",q(max_card,"getEffectiveId"))
				use.to:append(p)
				return
			end
		end
	end

	local min_card = self:getMinCard()
	if min_card then
		local number = q(min_card,"getNumber")
		if number<7 then
			self.friends_noself = self:sort(self.friends_noself,"handcard")
			for _,p in sgs.list(self.friends_noself)do
				if not q(self.player,"canPindian",p) then continue end
				if not self:needToThrowLastHandcard(p) then continue end
				self:setPriorityValue("JinShiduCard",5,"bei")
				use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
				self:remember("jinshidu_card",q(min_card,"getEffectiveId"))
				use.to:append(p)
				return
			end
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _,p in sgs.list(self.friends_noself)do
				if not q(self.player,"canPindian",p) then continue end
				if self:doDisCard(p,"h",true) and (not self:isWeak(p) or self:getEnemyNumBySeat(self.player,p,p)==0)
				then
					self:setPriorityValue("JinShiduCard",5,"bei")
					use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
					self:remember("jinshidu_card",q(min_card,"getEffectiveId"))
					use.to:append(p)
					return
				end
			end
			if self:getOverflow(self.player,true)>0
			then
				self.enemies = self:sort(self.enemies,"handcard")
				for _,p in sgs.list(self.enemies)do
					if self:doDisCard(p,"h") and q(self.player,"canPindian",p)
					then
						self:setPriorityValue("JinShiduCard",0,"bei")
						use.card = self:bindSkillCard("jinshidu",{},nil,nil,"JinShiduCard")
						self:remember("jinshidu_card",q(min_card,"getEffectiveId"))
						use.to:append(p)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.JinShiduCard = 10.1

function sgs.ai_skill_pindian.jinshidu(minusecard,self,requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( q(maxcard,"getNumber")<6 and  minusecard or maxcard )
end

sgs.ai_skill_discard.jinshidu = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
    cards = self:sortByUseValue(cards,true)
	local dis = {}
	for _,c in sgs.list(cards)do
		if #dis>=min_num then break end
		table.insert(dis,q(c,"getEffectiveId"))
	end
	return dis
end

--韬隐
sgs.ai_skill_invoke.jintaoyin = function(self,data)
	local current = data:toPlayer()
	return self:isEnemy(current)
end

sgs.ai_can_damagehp.jintaoyin = function(self,from,card,to)
	return self:isEnemy(self.room:getCurrent())
	and yinni(self,to)
end

--夷灭
sgs.ai_skill_invoke.jinyimie = function(self,data)
	local str = data:toString():split(":")
	local to = self.room:findPlayerByObjectName(str[2])
	if not to or q(to,"isDead") or not self:isEnemy(to) or tonumber(str[4])<1 then return false end
	if self:cantDamageMore(self.player,to) then return false end
	return true
end

--睿略
sgs.ai_fill_skill.jinruilve_give = function(self,inclusive,request)
	if self:getOverflow(self.player,true)<=0 then return end
	return self:legacySkillSeed("jinruilve_give","JinRuilveGiveCard",request)
end

sgs.ai_skill_use_func.JinRuilveGiveCard = function(card,use,self)
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("h"))do
		if q(c,"isKindOf","Slash") or (q(c,"isDamageCard") and q(c,"isKindOf","TrickCard")) then
			table.insert(cards,c)
		end
	end
	if #cards==0 then return end
	cards = self:sortByUseValue(cards,true)
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,p in sgs.list(self.friends_noself)do
		if not self:canDraw(p) or not q(p,"hasLordSkill","jinruilve") or q(p,"getMark","jinruilve-PlayClear")>0 then continue end
		use.card = self:bindSkillCard("jinruilve_give",{q(cards[1],"getEffectiveId")},nil,nil,"JinRuilveGiveCard")
		use.to:append(p)
		return
	end
end

sgs.ai_use_priority.JinRuilveGiveCard = 0

--慧容
sgs.ai_skill_playerchosen.jinhuirong = function(self,targets)
	local targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	for _,p in sgs.list(targets)do
		if self:canDraw(p) and self:isWeak(p)
		and self:isFriend(p)
		and q(p,"getHandcardNum")<q(p,"getHp")
		then return p end
	end
	local new_targets = {}
	for _,p in sgs.list(targets)do
		if self:isFriend(p) or self:isEnemy(p) then
			table.insert(new_targets,p)
		end
	end
	if #new_targets>0
	then
		local numsort = function(a,b)
			local c1,c2 = q(a,"getHandcardNum")-q(a,"getHp"),q(b,"getHandcardNum")-q(b,"getHp")
			if q(a,"getHp")>q(a,"getHandcardNum") then
				c1 = math.min(q(a,"getHp"),5)-q(a,"getHandcardNum")
			end
			if q(b,"getHp")>q(b,"getHandcardNum") then
				c2 = math.min(q(b,"getHp"),5)-q(b,"getHandcardNum")
			end
			c1 = math.abs(c1)
			c2 = math.abs(c2)
			return c1>c2
		end
		targets = self:sort(targets)
		table.sort(targets,numsort)
		if self:isFriend(targets[1]) and q(targets[1],"getHandcardNum")<=q(targets[1],"getHp") then return targets[1] end
		if self:isEnemy(targets[1]) and q(targets[1],"getHandcardNum")>=q(targets[1],"getHp") then return targets[1] end
	end
	if q(self.player,"getHp")>=q(self.player,"getHandcardNum")
	then return self.player end
	for _,p in sgs.list(targets)do
		if self:isFriend(p) or self:isEnemy(p) then continue end
		return p
	end
	return self.player
end

sgs.ai_can_damagehp.jinhuirong = function(self,from,card,to)
	for _,p in sgs.list(self.friends)do
		if q(p,"getHandcardNum")<q(p,"getHp")
		and yinni(self,to)
		then return true end
	end
	for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>q(p,"getHp")
		and yinni(self,to)
		then return true end
	end
end

--慈威
sgs.ai_skill_cardask["@jinciwei-discard"] = function(self,data)
	local player = fact_player(self,"jinciwei_player")
	if self:isEnemy(player) then
		local to_discard = self:askForDiscard("dummyreason",1,1,false,true)
		if #to_discard>0 then return "$"..to_discard[1] end
	end
	return "."
end

sgs.ai_skill_invoke.jinzhuosheng = function(self,data)
	return true
end

sgs.ai_skill_choice.jinzhuosheng = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	save_use(self,"bei.js_use",use)
	if table.contains(items,"add")
	then
		if q(use.card,"isDamageCard")
		or #self.friends_noself>0 and use.to:contains(self.player)
		then return "add" end
	end
	if table.contains(items,"remove")
	and q(use.card,"isDamageCard")
	then
		for _,to in sgs.list(use.to)do
			if self:isFriend(to)
			then return "remove" end
		end
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.jinzhuosheng = function(self,players)
    local saved_use=load_use(self,"bei.js_use")
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	if q(saved_use.card,"isDamageCard")
	then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and saved_use.to:contains(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and not saved_use.to:contains(target)
			and self:canCanmou(target,saved_use)
			then return target end
		end
	else
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and self:canCanmou(target,saved_use)
			then return target end
		end
	end
	return destlist[1]
end

sgs.ai_fill_skill.tousui = function(self,inclusive,request)
    local cards = self.player:getCards("he")
	local dc = known(self:evaluateSkillCard("tousui","slash",{}),"tousui Slash")
	if q(dc,"isAvailable",self.player) then
		local d = self:aiUseCard(dc)
		if d.card then
			save_targets(self,"bei.tousuiUse",d.to)
			cards = self:sortByKeepValue(cards) -- 按保留值排序
			local ids = {}
			for i,c in sgs.list(cards)do
				if self:wasPreviouslyPlannedCard(c) and not q(c,"isKindOf","Slash")
				or #ids>#cards/2 then continue end
				table.insert(ids,q(c,"getId"))
				if #ids>getCardsNum("Jink",d.to:at(0),self.player)
				then return tousui_proposal(self,ids,request) end
			end
		end
	end
end

sgs.ai_skill_use_func["TousuiCard"] = function(card,use,self)
	use.card = card
	use.to = load_targets(self,"bei.tousuiUse")
end

sgs.ai_use_value.TousuiCard = 2.4
sgs.ai_use_priority.TousuiCard = 6.2

function sgs.ai_cardsview.tousui(self,class_name,player)
    local cards = player:getCards("he")
	cards = self:sortByKeepValue(cards) -- 按保留值排序
	if #cards>0 then
		return {skill="tousui",legacy_class="TousuiCard",subcards={q(cards[1],"getId")}}
	end
end

sgs.ai_skill_choice.chuming = function(self,choices)
	local items = choices:split("+")
	self:setStrategyMemory("bei.chumingUse",false)
	local subcards = property(self,"chumingSubcard"):split("+");
	for _,pc in sgs.list(items)do
		local dc = chuming_clone(self,pc,subcards)
		local d = self:aiUseCard(dc)
		if d.card then
			save_use(self,"bei.chumingUse",d)
			return pc
		end
	end
end

sgs.ai_skill_use["@@chuming!"] = function(self,prompt)
    local d = load_use(self,"bei.chumingUse",true)
   	if d and d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	local paid=self:bindChumingSelectedPlan(d.card)
            return {kind="use_card",card_spec=paid:toCardSpec(),targets=tos}
    end
end








