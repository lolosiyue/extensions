-- Source: b6025acc ai/jie_package-ai.lua.
local known = AIValue.requireKnown

local function color(card)
    if card:isRed() then return "red" end
    if card:isBlack() then return "black" end
    return "colorless" -- Both native color predicates were explicitly false.
end
local function request_view(self,r)
    if r and not r.getActivationSkillName then return AILegacyRequest.new(r,self.room) end
    return r
end
local function remember(self,k,v)self:setStrategyMemory("jie_package."..k,v)end
local function recall(self,k)local v=self:getStrategyMemory("jie_package."..k);return v end
local function find(self,name)
    return known(self.room:findPlayerByObjectName(name,true),"saved target "..tostring(name))
end
local function scoped(self,key)
    local context=self:getDecisionContext()
    if type(context.jie_package)~="table" then ai_unsupported("Jie scoped context unavailable",key) end
    return known(context.jie_package[key],key)
end
local function tagged_use(self,key)
    local row=scoped(self,key)
    if row==false then
        -- Native no longer writes these old tags. Preserve the donor's nil-card
        -- failure instead of substituting the newer activation's original_data.
        return {from=nil,card=nil,to=AIList.new({})}
    end
    local targets=AIList.new({})
    for _,name in ipairs(known(row.to,key..".to"))do targets:append(find(self,name))end
    return {from=row.from and row.from~=false and find(self,row.from) or nil,
        card=known(CardView.new(row.card),key..".card"),to=targets}
end
local function source_damage(card)
    if card==nil then error("fixed Jie missing tag dereferences nil CardUse card",0)end
    return card:isDamageCard()
end
local function patterns(self)return known(AICardCatalog.patternNames(),"pattern_names")end
local function pattern_card(self,name)
    -- PatternsCard also shuffles a getRandomCards list, but this caller only
    -- consumes the public card type; the isolated VM never draws gameplay RNG.
    return self:cloneEvaluationCard(name)
end
local function preview(self,name)
    return self:evaluateOwnerViewAsCard({source_key="jinbingxin",skill="jinbingxin",name=name,
        suit=sgs.Card_NoSuit,number=0,subcards={}})
end
local function save_plan(self,plan)
    self.jinbingxinUse=plan
    local names={};for _,p in ipairs(known(plan.to,"jinbingxin targets"))do names[#names+1]=p:objectName()end
    local estimates={}
    for _,entry in ipairs(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {})do
        local row={};for k,v in pairs(entry)do if type(v)~="table"then row[k]=v end end;estimates[#estimates+1]=row
    end
    remember(self,"jinbingxinUse",{card=self:capturePriorTurnPlan(plan.card),targets=names,estimates=estimates})
end
local function prior_plan(self)
    if self.jinbingxinUse then return self.jinbingxinUse end
    local row=recall(self,"jinbingxinUse");if not row then return nil end
    for _,entry in ipairs(row.estimates or {})do
        local copy={};for k,v in pairs(entry)do copy[k]=v end;copy.status,copy.value="estimate",true
        self:useKnowledgeEstimate(copy,entry.context or "jie_package.jinbingxin.cached")
    end
    local targets=AIList.new({});for _,name in ipairs(known(row.targets,"jinbingxin saved targets"))do targets:append(find(self,name))end
    -- This allocation is a historical virtual-card observation, never a ticket.
    return {card=self:restorePriorTurnPlan(known(row.card,"jinbingxin saved card")),to=targets}
end



ai_skill_invoke.jinbolan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_fill_skill.jinbolan_skill = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:isWeak() or self.player:getHp()<2 then return end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if ep:hasSkill("jinbolan") and ep:getStrategyMark("jinbolan-PlayClear")<1
		and (not self:isEnemy(ep) or math.random()<0.3) then
			self.jinbolan_to=ep
            remember(self,"jinbolan_to",ep:objectName())
			return self:evaluateTurnSkillCard("jinbolan_skill","JinBolanSkillCard",{},request_view(self,request))
		end
	end
end

ai_card_use["JinBolanSkillCard"] = function(self, card, use, request)
	use.card = card
	use.to:append(self.jinbolan_to or find(self,known(recall(self,"jinbolan_to"),"jinbolan_to")))
end

sgs.ai_use_value.JinBolanSkillCard = 4.4
sgs.ai_use_priority.JinBolanSkillCard = 5.2

sgs.ai_skill_playerchosen.jincanmou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local use = tagged_use(self,"JincanmouData")
	if use.to:contains(use.from)
	and not source_damage(use.card) then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and self:canCanmou(target,use)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isEnemy(target)
			and self:isWeak(target)
			and self:canCanmou(target,use)
			then return target end
		end
	elseif source_damage(use.card) then
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and self:canCanmou(target,use)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isFriend(target)
			and not self:isWeak(target)
			and self:canCanmou(target,use)
			then return target end
		end
	elseif not self:isFriend(use.from) then
		for _,to in sgs.list(use.to)do
			if self:isFriend(to) then
				for _,target in sgs.list(destlist)do
					if self:isEnemy(target)
				and self:canCanmou(target,use)
					then return target end
				end
				for _,target in sgs.list(destlist)do
					if not self:isFriend(target)
					and not self:isWeak(target)
					and self:canCanmou(target,use)
					then return target end
				end
			end
		end
	elseif self:isFriend(use.from) then
		for _,to in sgs.list(use.to)do
			if self:isFriend(to) then
				for _,target in sgs.list(destlist)do
					if self:isFriend(target)
					and self:canCanmou(target,use)
					then return target end
				end
				for _,target in sgs.list(destlist)do
					if not self:isEnemy(target)
					and self:isWeak(target)
					and self:canCanmou(target,use)
					then return target end
				end
			elseif self:isEnemy(to) then
				for _,target in sgs.list(destlist)do
					if self:isEnemy(target)
					and self:canCanmou(target,use)
					then return target end
				end
				for _,target in sgs.list(destlist)do
					if not self:isFriend(target)
					and not self:isWeak(target)
					and self:canCanmou(target,use)
					then return target end
				end
			end
		end
	end
end

ai_skill_invoke.jincongjian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = tagged_use(self,"JincongjianData")
	self.jcj_can = nil; remember(self,"jcj_can",nil)
	if use.to:contains(use.from)
	and not source_damage(use.card)
	then return (self:canCanmou(self.player,use)) or false
	elseif source_damage(use.card)
	then
		self.jcj_can = not self:isWeak(); remember(self,"jcj_can",self.jcj_can)
		return (self.jcj_can
		and self:canCanmou(self.player,use)
		and self:canDamageHp(use.from,use.card)) or false
	end
	return false

end

sgs.ai_skill_cardask.jincongjian = function(self,data,pattern,prompt)
    local parsed = prompt:split(":")
    if self.jcj_can or recall(self,"jcj_can")
	then
    	self.jcj_can = nil; remember(self,"jcj_can",nil)
		return false
	end
end

ai_skill_invoke.jinxiongshu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self:getDecisionData():toPlayer()
	if target and not target:isKongcheng()
	then
		return (self:isEnemy(target)
		or (not self:isFriend(target)) and #self.enemies<2) or false
	end
	return false

end

sgs.ai_skill_discard.jinxiongshu = function(self,x,n)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,"j")
   	local target = self.room:getCurrent()
	if n>#cards/2 or self:isFriend(target)
	then return {} end
	local to_cards = {}
   	for _,h in sgs.list(cards)do
   		if #to_cards>=n then break end
     	table.insert(to_cards,h:getEffectiveId())
	end
	return to_cards
end

ai_skill_invoke.jinxiongshu_guess = function(self, options, request)
   	local data = request and self:getDecisionData(request) or nil
   	local target = self.room:getCurrent()
	local row=scoped(self,"JinXiongshuShowCard")
    if row==false then error("fixed jinxiongshu_guess missing show-card tag yields card -1",0)end
    local c=known(CardView.new(row),"JinXiongshuShowCard")
	if c:isAvailable(target)
	then
		for _,to in sgs.list(self.room:getAllPlayers())do
			if CanToCard(c,target,to)
			then
				if (c:isDamageCard() or c:isKindOf("SingleTargetTrick"))
				and self:isEnemy(target, to)
				then return (true) or false end
			end
		end
		if c:targetFixed()
		and not c:isDamageCard()
		then return (true) or false end
	end
   	return false

end

ai_fill_skill.jinbingxin = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	local can = #cards==self.player:getHp()
  	for _,c in sgs.list(cards)do
		if color(c)==color(cards[1])
		then continue end
		can = false
	end
	if can
	then
		for c,pn in sgs.list(patterns(self))do
			c = pattern_card(self,pn)
			if c and c:getTypeId()==1
			and self.player:getStrategyMark("jinbingxin_guhuo_remove_"..pn.."-Clear")<1
			then
				c = preview(self,pn)
				local d = self:aiUseCard(c)
				if c:isAvailable(self.player)
				and d.card and d.to
				then
					save_plan(self,d)
					self:setPriorityValue("JinBingxinCard",self:getSourcePriorityValue(c:getClassName())+5)
					return self:evaluateTurnSkillCard("jinbingxin","JinBingxinCard",{},request_view(self,request),pn)
				end
			end
		end
	end
end

ai_card_use["JinBingxinCard"] = function(self, card, use, request)
	local saved=prior_plan(self)
	if saved
	then
		use.card = card
		use.to = saved.to
	end
end

sgs.ai_use_value.JinBingxinCard = 3.4
sgs.ai_use_priority.JinBingxinCard = 4.8

sgs.ai_guhuo_card.jinbingxin = function(self,toname,class_name)
	return "@JinBingxinCard=.:"..toname
end

sgs.ai_skill_cardask["@@jinbingxin"] = function(self,data,pattern)
	local saved=prior_plan(self)
	if(saved)
	then
		local tos = {}
		for _,to in sgs.list(saved.to)do
			table.insert(tos,to:objectName())
		end
		return saved.card:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
    return "."
end


















