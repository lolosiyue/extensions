-- Source: b6025acc ai/doudizhu-ai.lua.
local known = AIValue.requireKnown
local sorted={sort=true,sortByKeepValue=true}

local function callback(reg,key,...)
    local fn=(reg == "ai_skill_use" and ai_skill_use or (reg == "ai_card_use" and ai_card_use or (reg == "ai_skill_invoke" and ai_skill_invoke or (reg == "ai_fill_skill" and ai_fill_skill or (reg == "ai_skill_choice" and ai_skill_choice or sgs[reg])))))and (reg == "ai_skill_use" and ai_skill_use or (reg == "ai_card_use" and ai_card_use or (reg == "ai_skill_invoke" and ai_skill_invoke or (reg == "ai_fill_skill" and ai_fill_skill or (reg == "ai_skill_choice" and ai_skill_choice or sgs[reg])))))[key]
    if type(fn)~="function"then ai_unsupported("doudizhu shared callback missing",reg.."."..key)end
    local a,b=fn(...);if AIUnsupported.is(a)then error(a,0)end;return a,b
end
local function response(self,skill,selector,costs,targets,request)
    local c=self:bindSkillCard(skill, costs, request, nil, selector)
    return{kind="use_card",card_spec=c:toCardSpec(),targets=targets}
end
local function converted(self,skill,name,class,c,request)
    return self:evaluateTurnConversion(skill, class, {name=name,skill=skill,suit=c:getSuit(),number=c:getNumber(),subcards={c:getKnownEffectiveId()}}, request or self.request)
end
local function acquired(self,id)return self:getAcquiredCardEvaluation(self:getChoiceCard(id))end
local function pattern_names(self)
    local rows=AICardCatalog.patternNames()
    if type(rows)~="table"then ai_unsupported("ordered public patterns are unavailable","jiejiu")end
    return rows
end
-- The viewer's own tag, read like the donor's toInt() (absent reads 0).
local function owner_tag(self,key)
    return tonumber(self.player:getTag(key)) or 0
end
local function prior_cards(self)
    return self:getPriorTurnUseCards()
end
local function remember_faqi(self,d,offered)
    return self:rememberFaqiUse(d.card, d.to, offered, d)
end
local function recall_faqi(self)
    return self:materializeFaqiUse()
end


ai_skill_use["@@feiyang"] = function(self, prompt, native_request)
	local disaster,indulgence,supply_shortage = -1,-1,-1
	for _,card in sgs.list(self.player:getJudgingArea())do
		if card:isKindOf("Disaster") then disaster = card:getKnownId() end
		if card:isKindOf("Indulgence") then indulgence = card:getKnownId() end
		if card:isKindOf("SupplyShortage") then supply_shortage = card:getKnownId() end
	end
	
	local handcards = {}
	for _,id in sgs.list(self.player:handCards())do
		if self.player:canDiscard(self.player, id) then
			table.insert(handcards,self:getKnownCardById(id))
		end
	end
	if #handcards<2 then return "." end
	self:sortByKeepValueInPlace(handcards)
	
	local discard = {}
	
		table.insert(discard,handcards[1]:getKnownId())
		table.insert(discard,handcards[2]:getKnownId())
	if disaster>-1 and self:hasSkills(sgs.wizard_skill, self.enemies) then
		table.insert(discard,disaster)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and self.player:hasSkill("keji") and supply_shortage>-1 then
		table.insert(discard,supply_shortage)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and self:getCardsNum("Peach")>1 and self:isWeak() then
		table.insert(discard,indulgence)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and self:getOverflow(self.player)>1 and (not self:isWeak() or not handcards[1]:isKindOf("Peach")) then
		table.insert(discard,indulgence)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if supply_shortage>-1 and (not self:isWeak() or not handcards[1]:isKindOf("Peach")) then
		table.insert(discard,supply_shortage)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if not self:isWeak() or not handcards[1]:isKindOf("Peach") then
		table.insert(discard,self.player:getJudgingAreaID():first())
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	return "."
end

ai_skill_invoke.doudizhu_reward = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_skill_choice.doudizhu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"recover")
	and self:isWeak()
	then return ai_choice_result(("recover"), options) end
	if table.contains(items,"draw")
	and self:canDraw()
	then return ai_choice_result(("draw"), options) end
	if table.contains(items,"recover")
	then return ai_choice_result(("recover"), options) end

    return ai_choice_result(nil, options)
end

ai_skill_invoke.ddzcibei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:isFriend(target) or not self:isWeak(target)) or false
	end
	return false

end

ai_skill_invoke.longgong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.from then
		return (self:isFriend(damage.from) or self:isWeak()) or false
	end
	return (true) or false
end

ai_fill_skill.sitian = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValueInPlace(cards, nil, "j")
	for _,c1 in sgs.list(cards)do
		if self:getOverflow()<0 or #self.enemies<1 then break end
		local ids2 = {}
		table.insert(ids2,c1:getKnownId())
		for _,c2 in sgs.list(cards)do
			if c1:getSuit()~=c2:getSuit() then
				table.insert(ids2,c2:getKnownId())
				return self:evaluateTurnSkillCard("sitian", "SitianCard", ids2, request or self.request)
			end
		end
	end
end

ai_card_use["SitianCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.SitianCard = 3.4
sgs.ai_use_priority.SitianCard = 1.2

ai_fill_skill.jiuxian = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		if c:isNDTrick() and not c:isSingleTargetCard() then
			local dc = converted(self,"jiuxian","analeptic","Analeptic",c,request)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.jiuxian(self,class_name,player)
    local cards = sgs.QList2Table(player:getCards("h"))
    self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
        if c:isNDTrick() and not c:isSingleTargetCard() then
            return "analeptic:jiuxian[no_suit:0]="..c:getKnownEffectiveId()
	   	end
	end
end

ai_skill_invoke.shixian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

sgs.ai_skill_askforag.faqi = function(self,card_ids)
    -- A plan from an earlier Faqi must not answer this one's @@faqi.
    self:setStrategyMemory("doudizhu.faqiUse",nil)
    for _,id in sgs.list(card_ids)do
		local offered=self:getChoiceCard(id)
        local dc=self:evaluateOwnerViewAsCard({name=offered:objectName(),skill="faqi",suit=sgs.Card_SuitToBeDecided,number=0,subcards={}})
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if dc:canRecast() and d.to:isEmpty()
				then continue end
				remember_faqi(self,d,id)
				return id
			end
		end
	end
end

ai_skill_use["@@faqi"] = function(self, prompt, request)
    return recall_faqi(self)
end

ai_skill_invoke.zhanjian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (not self:isFriend(target) and self:canDraw()) or false
	end
	return false

end

sgs.ai_skill_playerchosen.ddzbenxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end

ai_fill_skill.lisao = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("lisao", "LisaoCard", request or self.request)
end

ai_card_use["LisaoCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if use.to:length()<2 then
			use.card = card
			use.to:append(ep)
		end
	end
end

sgs.ai_use_value.LisaoCard = 3.4
sgs.ai_use_priority.LisaoCard = 9.2

ai_skill_invoke.juanlv = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (callback("ai_skill_invoke","double_sword",self,options,request)) or false
end

ai_fill_skill.qixin = function(self, options, request)
    local inclusive = options and options.inclusive

	for i,c in sgs.list(prior_cards(self))do
		if c:isKindOf("QixinCard") then return end
	end
	for i,c in sgs.list(prior_cards(self))do
		if i>1 and c:getTypeId()>0 then
			local d = self:aiUseCard(c)
			for _,p in sgs.list(d.to)do
				if p~=self.player and p:getGender()==self.player:getGender() then
					return self:legacySkillSeed("qixin", "QixinCard", request or self.request)
				end
			end
			break
		end
	end
	if #prior_cards(self)<2 then
		local c = owner_tag(self,"qixinCaojieHp")
		local l = owner_tag(self,"qixinLiuxieHp")
		if c>l and self.player:isMale() or l>c and self.player:isFemale() then
			return self:legacySkillSeed("qixin", "QixinCard", request or self.request)
		end
	end
end

ai_card_use["QixinCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.QixinCard = 3.4
sgs.ai_use_priority.QixinCard = 9.2



ai_skill_invoke.zhinang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_skill_invoke.huyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self.player:getVisibleSkillList():length()>3) or false
end

sgs.ai_skill_playerchosen.fengzhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.yuyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

ai_fill_skill.jiejiu = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		if c:isKindOf("Analeptic") then
			for _,pn in sgs.list(pattern_names(self))do
				local face=self:getEvaluationCard(pn)
                local dc=face
                if face:getTypeId()==1 then dc=converted(self,"jiejiu",pn,face:getClassName(),c,request)end
				if dc:getTypeId()==1 and dc:isAvailable(self.player) then
					if self:aiUseCard(dc).card then
						return dc
					end
				end
			end
		end
	end
end

ai_skill_invoke.dingxi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local to = data:toPlayer()
	return (self:isEnemy(to)) or false
end

sgs.ai_skill_askforag.dingxi = function(self,card_ids)
    for _,id in sgs.list(card_ids)do
		local dc = acquired(self,id)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				return id
			end
		end
	end
end

ai_skill_invoke.huiwan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw() and #self.enemies>0) or false
end

sgs.ai_skill_askforag.huiwan = function(self,card_ids)
    local cs = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cs,acquired(self,id))
	end
	self:sortByKeepValueInPlace(cs, true)
	for _,dc in sgs.list(cs)do
		if dc:isAvailable(self.player) and self:getCardsNum(dc:getClassName())<1 then
			local d = self:aiUseCard(dc)
			if d.card then
				return dc:getKnownId()
			end
		end
	end
	return -1
end

sgs.ai_skill_playerchosen.huanli = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, true)
    for i,target in sgs.list(destlist)do
		if self:isEnemy(target) and i<#destlist/2
		then return target end
	end
    for _,target in sgs.list(sgs.reverse(destlist))do
		return target
	end
end

ai_skill_invoke.huanli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local to = data:toPlayer()
	return (not self:isEnemy(to) and to:getMaxHp()>3) or false
end

sgs.ai_skill_askforyiji.ddzfulu = function(self,card_ids,tos)
    local cs = {}
    for _,id in ipairs(card_ids)do cs[#cs+1]=self:getKnownCardById(id)end
	cs = self:sortByKeepValueInPlace(cs)
	for _,p in sgs.list(tos)do
		if p:isAlive() and self:doDisCard(p, "h", true, 2) then
			return p,cs[1]:getKnownId()
		end
	end
	local t,id = callback("ai_skill_askforyiji","nosyiji",self,card_ids,tos)
	if t and t:isAlive() then
		return t,id
	end
end

sgs.ai_skill_discard.ddzfulu = function(self,inclusive,request)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValueInPlace(handcards)
	return {handcards[1]:getKnownId()}
end

ai_skill_invoke.pimi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		return (self:doDisCard(use.from, "e") or not use.card:isDamageCard()) or false
	end
	return (self:doDisCard(use.from, "he") and not use.card:isDamageCard()) or false
end





