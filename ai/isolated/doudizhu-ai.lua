-- Fixed b6025acc doudizhu policies. Hypotheses never confer payment authority.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("doudizhu fact is unknown",k)end;return v end
local sorted={sort=true,sortByKeepValue=true}
local function q(o,k,...)
    if not o or type(o[k])~="function"then ai_unsupported("doudizhu source helper unavailable",k)end
    local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end
    if sorted[k]then local t=(...);known(v,k);for i,c in ipairs(v)do t[i]=c end;return t end
    if k=="hasSkill"or k=="hasSkills"then
        local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=="table"and rawget(p,"_view")
        if v==false and row and row.skills_complete~=true then ai_unsupported("doudizhu foreign skill absence unknown",(...))end
    end
    if k=="toPlayer"then return v end;return known(v,k)
end
local function callback(reg,key,...)
    local fn=sgs[reg]and sgs[reg][key]
    if type(fn)~="function"then ai_unsupported("doudizhu shared callback missing",reg.."."..key)end
    local a,b=fn(...);if AIUnsupported.is(a)then error(a,0)end;return a,b
end
local function response(self,skill,selector,costs,targets,request)
    local c=q(self,"bindSkillCard",skill,costs,request,nil,selector)
    return{kind="use_card",card_spec=q(c,"toCardSpec"),targets=targets}
end
local function converted(self,skill,name,class,c,request)
    return q(self,"evaluateTurnConversion",skill,class,{name=name,skill=skill,suit=q(c,"getSuit"),number=q(c,"getNumber"),subcards={q(c,"getEffectiveId")}},request or self.request)
end
local function acquired(self,id)return q(self,"getAcquiredCardEvaluation",q(self,"getChoiceCard",id))end
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
    return q(self,"getPriorTurnUseCards")
end
local function remember_faqi(self,d,offered)
    return q(self,"rememberFaqiUse",d.card,d.to,offered,d)
end
local function recall_faqi(self)
    return q(self,"materializeFaqiUse")
end


sgs.ai_skill_use["@@feiyang"] = function(self,prompt)
	local disaster,indulgence,supply_shortage = -1,-1,-1
	for _,card in sgs.list(q(self.player,"getJudgingArea"))do
		if q(card,"isKindOf","Disaster") then disaster = q(card,"getId") end
		if q(card,"isKindOf","Indulgence") then indulgence = q(card,"getId") end
		if q(card,"isKindOf","SupplyShortage") then supply_shortage = q(card,"getId") end
	end
	
	local handcards = {}
	for _,id in sgs.list(q(self.player,"handCards"))do
		if q(self.player,"canDiscard",self.player,id) then
			table.insert(handcards,q(self,"getKnownCardById",id))
		end
	end
	if #handcards<2 then return "." end
	q(self,"sortByKeepValue",handcards)
	
	local discard = {}
	
		table.insert(discard,q(handcards[1],"getId"))
		table.insert(discard,q(handcards[2],"getId"))
	if disaster>-1 and q(self,"hasSkills",sgs.wizard_skill,self.enemies) then
		table.insert(discard,disaster)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and q(self.player,"hasSkill","keji") and supply_shortage>-1 then
		table.insert(discard,supply_shortage)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and q(self,"getCardsNum","Peach")>1 and q(self,"isWeak") then
		table.insert(discard,indulgence)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if indulgence>-1 and q(self,"getOverflow",self.player)>1 and (not q(self,"isWeak") or not q(handcards[1],"isKindOf","Peach")) then
		table.insert(discard,indulgence)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if supply_shortage>-1 and (not q(self,"isWeak") or not q(handcards[1],"isKindOf","Peach")) then
		table.insert(discard,supply_shortage)
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	if not q(self,"isWeak") or not q(handcards[1],"isKindOf","Peach") then
		table.insert(discard,q(self.player,"getJudgingAreaID"):first())
		return response(self,"feiyang","FeiyangCard",discard,{},self.request)
	end
	
	return "."
end

sgs.ai_skill_invoke.doudizhu_reward = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_choice.doudizhu = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"recover")
	and q(self,"isWeak")
	then return "recover" end
	if table.contains(items,"draw")
	and q(self,"canDraw")
	then return "draw" end
	if table.contains(items,"recover")
	then return "recover" end
end

sgs.ai_skill_invoke.ddzcibei = function(self,data)
	local target = q(data,"toPlayer")
	if target then
		return q(self,"isFriend",target) or not q(self,"isWeak",target)
	end
end

sgs.ai_skill_invoke.longgong = function(self,data)
	local damage = q(data,"toDamage")
	if damage.from then
		return q(self,"isFriend",damage.from) or q(self,"isWeak")
	end
	return true
end

sgs.ai_fill_skill.sitian = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    q(self,"sortByKeepValue",cards,nil,"j") -- 按保留值排序
	for _,c1 in sgs.list(cards)do
		if q(self,"getOverflow")<0 or #self.enemies<1 then break end
		local ids2 = {}
		table.insert(ids2,q(c1,"getId"))
		for _,c2 in sgs.list(cards)do
			if q(c1,"getSuit")~=q(c2,"getSuit") then
				table.insert(ids2,q(c2,"getId"))
				return q(self,"evaluateTurnSkillCard","sitian","SitianCard",ids2,request or self.request)
			end
		end
	end
end

sgs.ai_skill_use_func["SitianCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.SitianCard = 3.4
sgs.ai_use_priority.SitianCard = 1.2

sgs.ai_fill_skill.jiuxian = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    q(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if q(c,"isNDTrick") and not q(c,"isSingleTargetCard") then
			local dc = converted(self,"jiuxian","analeptic","Analeptic",c,request)
			if q(dc,"isAvailable",self.player) then
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.jiuxian(self,class_name,player)
   	local cards = sgs.QList2Table(q(player,"getCards","h"))
    q(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
       	if q(c,"isNDTrick") and not q(c,"isSingleTargetCard") then
            return "analeptic:jiuxian[no_suit:0]="..q(c,"getEffectiveId")
	   	end
	end
end

sgs.ai_skill_invoke.shixian = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_askforag.faqi = function(self,card_ids)
    -- A plan from an earlier Faqi must not answer this one's @@faqi.
    self:setStrategyMemory("doudizhu.faqiUse",nil)
    for _,id in sgs.list(card_ids)do
		local offered=q(self,"getChoiceCard",id)
        local dc=q(self,"evaluateOwnerViewAsCard",{name=q(offered,"objectName"),skill="faqi",suit=sgs.Card_SuitToBeDecided,number=0,subcards={}})
		if q(dc,"isAvailable",self.player) then
			local d = q(self,"aiUseCard",dc)
			if d.card then
				if q(dc,"canRecast") and d.to:isEmpty()
				then continue end
				remember_faqi(self,d,id)
				return id
			end
		end
	end
end

sgs.ai_skill_use["@@faqi"] = function(self,prompt)
    return recall_faqi(self)
end

sgs.ai_skill_invoke.zhanjian = function(self,data)
	local target = q(data,"toPlayer")
	if target then
		return not q(self,"isFriend",target) and q(self,"canDraw")
	end
end

sgs.ai_skill_playerchosen.ddzbenxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	q(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if q(self,"isEnemy",p) and q(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if q(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_fill_skill.lisao = function(self,inclusive,request)
	return q(self,"legacySkillSeed","lisao","LisaoCard",request or self.request)
end

sgs.ai_skill_use_func["LisaoCard"] = function(card,use,self)
	q(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if use.to:length()<2 then
			use.card = card
			use.to:append(ep)
		end
	end
end

sgs.ai_use_value.LisaoCard = 3.4
sgs.ai_use_priority.LisaoCard = 9.2

sgs.ai_skill_invoke.juanlv = function(self,data)
	return callback("ai_skill_invoke","double_sword",self,data)
end

sgs.ai_fill_skill.qixin = function(self,inclusive,request)
	for i,c in sgs.list(prior_cards(self))do
		if q(c,"isKindOf","QixinCard") then return end
	end
	for i,c in sgs.list(prior_cards(self))do
		if i>1 and q(c,"getTypeId")>0 then
			local d = q(self,"aiUseCard",c)
			for _,p in sgs.list(d.to)do
				if p~=self.player and q(p,"getGender")==q(self.player,"getGender") then
					return q(self,"legacySkillSeed","qixin","QixinCard",request or self.request)
				end
			end
			break
		end
	end
	if #prior_cards(self)<2 then
		local c = owner_tag(self,"qixinCaojieHp")
		local l = owner_tag(self,"qixinLiuxieHp")
		if c>l and q(self.player,"isMale") or l>c and q(self.player,"isFemale") then
			return q(self,"legacySkillSeed","qixin","QixinCard",request or self.request)
		end
	end
end

sgs.ai_skill_use_func["QixinCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.QixinCard = 3.4
sgs.ai_use_priority.QixinCard = 9.2



sgs.ai_skill_invoke.zhinang = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_invoke.huyi = function(self,data)
	return q(self.player,"getVisibleSkillList"):length()>3
end

sgs.ai_skill_playerchosen.fengzhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	q(self,"sort",destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.yuyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	q(self,"sort",destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_fill_skill.jiejiu = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    q(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","Analeptic") then
			for _,pn in sgs.list(pattern_names(self))do
				local face=q(self,"getEvaluationCard",pn)
                local dc=face
                if q(face,"getTypeId")==1 then dc=converted(self,"jiejiu",pn,q(face,"getClassName"),c,request)end
				if q(dc,"getTypeId")==1 and q(dc,"isAvailable",self.player) then
					if q(self,"aiUseCard",dc).card then
						return dc
					end
				end
			end
		end
	end
end

sgs.ai_skill_invoke.dingxi = function(self,data)
	local to = q(data,"toPlayer")
	return q(self,"isEnemy",to)
end

sgs.ai_skill_askforag.dingxi = function(self,card_ids)
    for _,id in sgs.list(card_ids)do
		local dc = acquired(self,id)
		if q(dc,"isAvailable",self.player) then
			local d = q(self,"aiUseCard",dc)
			if d.card then
				return id
			end
		end
	end
end

sgs.ai_skill_invoke.huiwan = function(self,data)
	return q(self,"canDraw") and #self.enemies>0
end

sgs.ai_skill_askforag.huiwan = function(self,card_ids)
    local cs = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cs,acquired(self,id))
	end
	q(self,"sortByKeepValue",cs,true)
	for _,dc in sgs.list(cs)do
		if q(dc,"isAvailable",self.player) and q(self,"getCardsNum",q(dc,"getClassName"))<1 then
			local d = q(self,"aiUseCard",dc)
			if d.card then
				return q(dc,"getId")
			end
		end
	end
	return -1
end

sgs.ai_skill_playerchosen.huanli = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	q(self,"sort",destlist,true)
    for i,target in sgs.list(destlist)do
		if q(self,"isEnemy",target) and i<#destlist/2
		then return target end
	end
    for _,target in sgs.list(sgs.reverse(destlist))do
		return target
	end
end

sgs.ai_skill_invoke.huanli = function(self,data)
	local to = q(data,"toPlayer")
	return not q(self,"isEnemy",to) and q(to,"getMaxHp")>3
end

sgs.ai_skill_askforyiji.ddzfulu = function(self,card_ids,tos)
    local cs = {}
    for _,id in ipairs(card_ids)do cs[#cs+1]=q(self,"getKnownCardById",id)end
	cs = q(self,"sortByKeepValue",cs)
	for _,p in sgs.list(tos)do
		if q(p,"isAlive") and q(self,"doDisCard",p,"h",true,2) then
			return p,q(cs[1],"getId")
		end
	end
	local t,id = callback("ai_skill_askforyiji","nosyiji",self,card_ids,tos)
	if t and q(t,"isAlive") then
		return t,id
	end
end

sgs.ai_skill_discard.ddzfulu = function(self,inclusive,request)
    local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
    q(self,"sortByKeepValue",handcards) -- 按保留值排序
	return {q(handcards[1],"getId")}
end

sgs.ai_skill_invoke.pimi = function(self,data)
	local use = q(data,"toCardUse")
	if q(self,"isFriend",use.from) then
		return q(self,"doDisCard",use.from,"e") or not q(use.card,"isDamageCard")
	end
	return q(self,"doDisCard",use.from,"he") and not q(use.card,"isDamageCard")
end





