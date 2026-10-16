-- Fixed b6025acc yjcm2022-ai.lua effective callbacks, including its yjcm2023
-- registrations. Pure strategy state is separate from native action receipts.
local known = AIValue.requireKnown

local function saved_estimates(self)
    local result={}
    for _,entry in ipairs(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or{})do
        local row={};for k,v in pairs(entry)do if type(v)~='table'then row[k]=v end end
        result[#result+1]=row
    end
    return result
end
local function replay_estimates(self,entries)
    for _,entry in ipairs(entries or{})do
        local row={};for k,v in pairs(entry)do row[k]=v end
        row.status,row.value,row.count='estimate',true,nil
        self:useKnowledgeEstimate(row,entry.context or'yjcm2022.cached_selection')
    end
end
local function save_player(self,key,player)
    self[key]=player
    self:setStrategyMemory('yjcm2022.'..key, player and player:objectName() or false)
end
local function saved_player(self,key)
    if self[key] then return self[key] end
    local name,present=self:getStrategyMemory('yjcm2022.'..key)
    replay_estimates(self,self:getStrategyMemory('yjcm2022.'..key..'.estimates'))
    if not present then ai_unsupported('prior source player selection is unavailable',key) end
    if name==false then return nil end
    return known(self.room:findPlayerByObjectName(name),key)
end
local function visible(self,id)
    return known(self:getChoiceCard(id) or self:getKnownCardById(id),'offered card '..tostring(id))
end
local function skill_card(self,skill,class,costs,request)
    return self:bindSkillCard(skill, costs, request, nil, class)
end
local dummy = AIUsePlan.dummy
local function evaluate(self,card,use)
    return self:evaluateCard(card, use or dummy())
end
local function sangu_available(self,card,target)
    if target==self.player then return card:isAvailable(target) end
    -- Public product predicates are evaluated; hidden use/recast limits,
    -- Slash history and foreign target-mod skills remain an explicit prior.
    local others=self.room:getOtherPlayers(target)
    local name=card:objectName()
    local eligible=false
    local function permitted(player)
        return not self:strategyProhibited(target, player, card)
    end
    if card:isKindOf('Slash') or name=='duel' then
        for _,p in ipairs(others)do if permitted(p)then eligible=true;break end end
    elseif name=='snatch' or name=='dismantlement' then
        for _,p in ipairs(others)do
            if p:getCardCount(true, not(self.room:getMode()=='02_1v1'
                and self.room:getDuelRule()~='Classical'))>0
                and (name~='snatch' or target:distanceTo(p)<=1)
                and permitted(p)then eligible=true;break end
        end
    elseif name=='fire_attack' then
        local all={};for _,p in ipairs(others)do all[#all+1]=p end;all[#all+1]=target
        for _,p in ipairs(all)do
            if p:getHandcardNum()>0 and permitted(p)then eligible=true;break end
        end
    elseif name=='ex_nihilo' then eligible=permitted(target)
    elseif card:isKindOf('AOE') then
        for _,p in ipairs(others)do if permitted(p)then eligible=true;break end end
    elseif card:isKindOf('GlobalEffect') then
        for _,p in ipairs(others)do if permitted(p)then eligible=true;break end end
        if not eligible then eligible=permitted(target)end
    elseif name=='iron_chain' then
        eligible=true -- Source permits recast even with no usable target.
    else
        eligible=true -- Unported custom NDTrick predicate; explicitly estimated.
    end
    return self:useKnowledgeEstimate({value=eligible,status='estimate',
        basis='sangu.foreign_availability_public_product_predicates_private_limits_history_targetmods_prior',
        target=target:objectName(),card_name=name},'sangu')
end
local function biejun_received(self,to)
    if to==self.player then
        -- The owner's own hand and marks are complete.
        for _,card in ipairs(to:getHandcards())do
            if to:getStrategyMark('biejunGetCard_'..card:getKnownEffectiveId()..'-Clear')>0 then return true end
        end
        return false
    end
    local cards=self:getKnownCards(to, self.player, 'h')
    for _,card in ipairs(cards)do
        if to:getStrategyMark('biejunGetCard_'..card:getKnownEffectiveId()..'-Clear')>0 then return true end
    end
    return self:useKnowledgeEstimate({value=false,status='estimate',
        basis='biejun.foreign_received_mark_no_known_positive',target=to:objectName()},'biejun')
end
local function restore_peiqi(self)
    if self.peiqiData then return end
    local row,present=self:getStrategyMemory('yjcm2022.peiqiData')
    if not present or type(row)~='table' then ai_unsupported('Fujue prior field selection is unknown','peiqiData') end
    replay_estimates(self,row.estimates)
    self.peiqiData={cid=row.cid}
    for _,key in ipairs({'from','to'})do
        if row[key] then self.peiqiData[key]=known(self.room:findPlayerByObjectName(row[key]),'peiqi '..key) end
    end
end

local function peiqi_policy(self)
	self.peiqiData = {}
	for _,ep in sgs.list(self.friends)do
		if self:doDisCard(ep,"ej",true) then
			self.peiqiData.from = ep
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs)
			for _,ej in sgs.list(ejs)do
				local i = ej:getKnownEffectiveId()
				if self:doDisCard(ep,i,true) then
					self.peiqiData.cid = i
					for _,fp in sgs.list(self.enemies)do
						self.peiqiData.to = fp
						if ej:getTypeId()==3 then
							local n = ej:getEquipSlot()
							local equipCard = ej
							local occupy = equipCard and equipCard:getEquipOccupyLocations()
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if self.player:canUse(ej, fp, true)
							then return true end
						end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"ej",true) then
			self.peiqiData.from = ep
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = ej:getKnownEffectiveId()
				if self:doDisCard(ep,i,true) then
					self.peiqiData.cid = i
					for _,fp in sgs.list(self.friends)do
						self.peiqiData.to = fp
						if ej:getTypeId()==3 then
							local n = ej:getEquipSlot()
							local equipCard = ej
							local occupy = equipCard and equipCard:getEquipOccupyLocations()
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if self.player:canUse(ej, fp, true)
							then return true end
						end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:doDisCard(ep,"ej",true) and not self:isFriend(ep) then
			self.peiqiData.from = ep
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = ej:getKnownEffectiveId()
				if self:doDisCard(ep,i,true) then
					self.peiqiData.cid = i
					for _,fp in sgs.list(self.friends)do
						self.peiqiData.to = fp
						if ej:getTypeId()==3 then
							local n = ej:getEquipSlot()
							local equipCard = ej
							local occupy = equipCard and equipCard:getEquipOccupyLocations()
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if not fp:containsTrick(ej:objectName())
							and self.player:canUse(ej, fp, true)
							then return true end
						end
					end
				end
			end
		end
	end
end

local function select_peiqi(self)
    local result=peiqi_policy(self)
    local row={cid=self.peiqiData.cid,estimates=saved_estimates(self)}
    for _,key in ipairs({'from','to'})do
        if self.peiqiData[key] then row[key]=self.peiqiData[key]:objectName() end
    end
    self:setStrategyMemory('yjcm2022.peiqiData', row)
    return result
end


sgs.ai_skill_invoke.liandui = function(self,data)
	local items = data:toString():split(":")
	if #items>1
	then
        local target = BeMan(self.room,items[2])
    	return target and not self:isEnemy(target)
	end
end

sgs.ai_skill_invoke.lianduiother = function(self,data)
	local items = data:toString():split(":")
	if #items>1
	then
        local target = BeMan(self.room,items[2])
    	return target and self:isFriend(target)
	end
end

sgs.ai_fill_skill["biejun-give"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
  	for _,p in sgs.list(self.room:findPlayersBySkillName("biejun"))do
		if #cards<2 or p==self.player then continue end
		save_player(self,"biejun_to",p)
		if self:isFriend(p) then
			if #cards>self.player:getMaxCards() and self:getPriorTurnUseCount()<1
			then return skill_card(self,"biejun-give","BiejunCard",{cards[1]:getEffectiveId()},request) end
		else
			local pcs = self:poisonCards(cards)
			if #pcs>0 then
				return skill_card(self,"biejun-give","BiejunCard",{pcs[1]:getEffectiveId()},request)
			end
			if self:isEnemy(p) and self:isWeak(p) and p:getHandcardNum()<3
			and #cards>self.player:getMaxCards() and self:getPriorTurnUseCount()>1
			then return skill_card(self,"biejun-give","BiejunCard",{cards[1]:getEffectiveId()},request) end
		end
	end
end

sgs.ai_skill_use_func["BiejunCard"] = function(card,use,self)
	self.biejun_to = saved_player(self,"biejun_to")
	if self.biejun_to then
		use.card = card
		use.to:append(self.biejun_to)
	end
end

sgs.ai_use_value.BiejunCard = 0.4
sgs.ai_use_priority.BiejunCard = 5.8

sgs.ai_skill_invoke.biejun = function(self,data)
	return not self.player:faceUp() or self:isWeak()
end

sgs.ai_can_damagehp.biejun = function(self,from,card,to)
	if biejun_received(self,to) then return end
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
	and self:isFriend(to)
	and not to:faceUp()
end

sgs.ai_skill_playerchosen.sangu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		save_player(self,"sangu_to",target)
		if self:isFriend(target)
		and target:getHandcardNum()>1
		then return target end
	end
    for _,target in sgs.list(destlist)do
		save_player(self,"sangu_to",target)
		if self:isEnemy(target)
		and target:getHandcardNum()>1
		then return target end
	end
    for _,target in sgs.list(destlist)do
		save_player(self,"sangu_to",target)
		if not self:isEnemy(target)
		and target:getHandcardNum()>1
		then return target end
	end
end

sgs.ai_skill_askforag.sangu = function(self,card_ids)
    self.sangu_to = saved_player(self,"sangu_to")
    local cards = {}
	for c,id in sgs.list(card_ids)do
		table.insert(cards,visible(self,id))
	end
    self:sortByKeepValue(cards,self:isFriend(self.sangu_to))
	for i,c in sgs.list(cards)do
		if self:isEnemy(self.sangu_to) and sangu_available(self,c,self.sangu_to)
		or self:isFriend(self.sangu_to) and not sangu_available(self,c,self.sangu_to)
		then continue end
		if self.player:getStrategyMark("SanguRecord_"..c:objectName().."-PlayClear")>0
		and i<#cards/3 then return c:getKnownEffectiveId() end
	end
	for i,c in sgs.list(cards)do
		if self.player:getStrategyMark("SanguRecord_"..c:objectName().."-PlayClear")>0
		and i<#cards/3 then return c:getKnownEffectiveId() end
	end
	for i,c in sgs.list(cards)do
		if self:isEnemy(self.sangu_to) and sangu_available(self,c,self.sangu_to)
		or self:isFriend(self.sangu_to) and not sangu_available(self,c,self.sangu_to)
		then continue end
		return c:getKnownEffectiveId()
	end
	return cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.bushilk = function(self,data)
	return self.player:getHandcardNum()>0
end

sgs.ai_skill_discard.koujing = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards)
	local touse = self:getTurnUse()
   	for c,h in sgs.list(cards)do
        c = self:evaluateSkillCard("koujing","slash",{h:getKnownEffectiveId()})
		if table.contains(touse,h)
		and self:getUseValue(c)<self:getUseValue(h)
		then continue end
		local d = evaluate(self,c)
		if d.card and d.to:length()>0
		and #to_cards<=d.to:at(0):getHp()
		then table.insert(to_cards,h:getKnownEffectiveId()) end
	end
	return to_cards
end

sgs.ai_skill_invoke.koujing = function(self,data)
	local shown = self.player:getTag("KoujingShowCards") or {}
	if not AIValue.isList(shown) then ai_unsupported("owner id-list tag malformed","KoujingShowCards") end
	local ids = #shown
	if ids>0
	then
		return self.player:getHp()+self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<=ids
		or self.player:getHandcardNum()>=ids
	end
end


sgs.ai_skill_invoke.duanwan = function(self,data)
	return self.player:getHp()+self:getAllPeachNum()<1
end

sgs.ai_skill_cardask["diezhang0"] = function(self,data,pattern,to1,to2)
    if to2 and self:isEnemy(to2) and self.player:canSlash(to2, nil, false)
	then return true end
	return "."
end

sgs.ai_skill_invoke.diezhang = function(self,data)
	local to = data:toPlayer()
    if to and not self:isFriend(to) and self.player:canSlash(to, nil, false)
	then return true end
end

sgs.ai_skill_invoke.cibei = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.cibei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:doDisCard(p,"hej")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"hej")
		then return p end
	end
end

sgs.ai_fill_skill.shujian = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c1 in sgs.list(cards)do
		if self:wasPreviouslyPlannedCard(c1) then continue end
		return skill_card(self,"shujian","ShujianCard",{c1:getKnownId()},request)
	end
end

sgs.ai_skill_use_func["ShujianCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ShujianCard = 3.4
sgs.ai_use_priority.ShujianCard = 6.2

sgs.ai_skill_use["@@shujian"] = function(self,prompt)
    local c = self:evaluateSkillCard("_shujian","dismantlement",{})
    local d = evaluate(self,c)
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
            table.insert(tos,p:objectName())
       	end
       	local authority = self:bindSkillCard("shujian",{},nil)
        local use=AIUsePlan.new();use.card=authority
        for _,p in ipairs(d.to)do use.to:append(p)end
        return use:toAnswer()
    end
end

sgs.ai_skill_choice["shujian"] = function(self,choices,data)
	local items = choices:split("+")
	local p = data:toPlayer()
	if self:isFriend(p) and p:getStrategyMark("shujianNum-PlayClear")<2 then
		return items[1]
	end
	if evaluate(self,self:getEvaluationCard("dismantlement")).card then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_playerschosen.zhitu = function(self,players,x,n)
    -- Fixed source zhituData is never written: default CardUse.card is nil,
    -- aiUseCard(nil) returns nil, then source d.card raises a runtime error.
    error("fixed donor Zhitu dereferences nil aiUseCard result (unwritten zhituData)",0)
end

sgs.ai_fill_skill.fujue = function(self,inclusive,request)
	if select_peiqi(self) then
		return skill_card(self,"fujue","FujueCard",{},request)
	end
end

sgs.ai_skill_use_func["FujueCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.FujueCard = 3.4
sgs.ai_use_priority.FujueCard = 6.2

sgs.ai_skill_playerchosen.fujue_from = function(self,players)
    restore_peiqi(self)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,p in sgs.list(destlist)do
		if self.peiqiData.from==p
		then return p end
	end
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"ej")
		then return p end
	end
end

sgs.ai_skill_playerchosen.fujue_to = function(self,players)
    restore_peiqi(self)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,p in sgs.list(destlist)do
		if self.peiqiData.to==p
		then return p end
	end
end

sgs.ai_skill_cardchosen.fujue = function(self,who,flags)
    restore_peiqi(self)
	if self.peiqiData.cid then return self.peiqiData.cid end
end

sgs.ai_fill_skill.beiyu = function(self,inclusive,request)
	if self.player:getMaxHp()>self.player:getHandcardNum() then
		return skill_card(self,"beiyu","BeiyuCard",{},request)
	end
end

sgs.ai_skill_use_func["BeiyuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.BeiyuCard = 3.4
sgs.ai_use_priority.BeiyuCard = 6.2

sgs.ai_skill_invoke.duchi = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.tyqimei = function(self,inclusive,request)
    return skill_card(self,"tyqimei","ThQimeiCard",{},request)
end

sgs.ai_skill_use_func["ThQimeiCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ThQimeiCard = 3.4
sgs.ai_use_priority.ThQimeiCard = 6.2

sgs.ai_skill_use["@@thqimei"] = function(self,prompt)
    -- thqimeiForAI has no fixed-source writer. Preserve the empty source loop;
    -- the modern V2 cards state is a different input and is not substituted.
    return nil
end

sgs.ai_skill_playerchosen.thzhuiji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_fill_skill.gongqiao = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c1 in sgs.list(cards)do
		if self:wasPreviouslyPlannedCard(c1) or #cards<3 then continue end
		return skill_card(self,"gongqiao","GongqiaoCard",{c1:getKnownId()},request)
	end
end

sgs.ai_skill_use_func["GongqiaoCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.GongqiaoCard = 3.4
sgs.ai_use_priority.GongqiaoCard = 6.2

sgs.ai_skill_choice.gongqiao = function(self,choices)
	local items = choices:split("+")
    for _,t in sgs.list(items)do
		local n = tonumber(t:split("ea")[2])
		if self.player:getEquip(n)
		then continue end
		return t
	end
end


function SmartAIView:useCardWangmeizhike(card,use)
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) and getKnownCard(p,self.player,"club",false,"h")>0
	   	and self:cardTargetFilter(card,use.to,p)
		then use.card = card end
	end
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if not self:isWeak(p) and getKnownCard(p,self.player,"club",false,"h")>1
	   	and self:cardTargetFilter(card,use.to,p)
		then use.card = card end
	end
end
sgs.ai_use_priority.Wangmeizhike = 1.4
sgs.ai_keep_value.Wangmeizhike = 4
sgs.ai_use_value.Wangmeizhike = 3.7
sgs.ai_nullification.Wangmeizhike = function(self,trick,from,to,positive)
	if self:getCardsNum("Nullification")>1 then
        return self:isEnemy(to)
        and to:isWounded()
    	and positive
	else
        return self:isEnemy(to)
    	and self:isWeak(to)
        and to:isWounded()
    	and positive
	end
end


-- The donor object keeps these selections across prompts. Persist their pure
-- names and the estimates which informed them, never player/card capabilities.
for _,entry in ipairs({{sgs.ai_fill_skill,'biejun-give','biejun_to'},
    {sgs.ai_skill_playerchosen,'sangu','sangu_to'}})do
    local registry,key,state=entry[1],entry[2],entry[3]
    local callback=registry[key]
    registry[key]=function(self,...)
        local result=callback(self,...)
        self:setStrategyMemory('yjcm2022.'..state..'.estimates', saved_estimates(self))
        return result
    end
end
