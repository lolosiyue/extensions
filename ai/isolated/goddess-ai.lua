-- Fixed b6025acc goddess source policies. No hidden-card lookup or donor error repair.
local function result(v)if AIUnsupported.is(v)then error(v,0)end;return v end
local function known(v,k)result(v);if v==nil then ai_unsupported("goddess fact is unknown",k)end;return v end
local nullable={getWeapon=true,getCard=true,getCardId=true,findPlayerBySkillName=true,getCurrent=true,speak=true,setStrategyPlayerFlag=true,
    useCardshot=true,getSameEquip=true,getEvaluationCandidate=true,getCardCandidate=true,updateIntention=true}
local sorted={sort=true,sortByKeepValue=true,sortByUseValue=true}
local function q(o,k,...)
    if not o or type(o[k])~="function"then ai_unsupported("goddess source helper unavailable",k)end
    local method=k
    if k=="getMark"and AIValue.isPlayer(o)then method="getStrategyMark"end
    local v=result(o[method](o,...))
    if sorted[k]then local t=(...);known(v,k);for i,c in ipairs(v)do t[i]=c end;return t end
    if k=="hasSkill"or k=="hasSkills"or k=="hasLordSkill"then
        local p=AIValue.isPlayer(o)and o or select(2,...)or o.player
        local row=p and rawget(p,"_view")
        if v==false and row and row.skills_complete~=true then ai_unsupported("goddess foreign skill absence is unknown",(...))end
    end
    if nullable[k]then return v end
    -- An audited provider's nil is the donor's falsy result, not an unknown.
    if v==nil and SmartAIView.isKnownNilStrategyResult(o,method,o[method])then return nil end
    return known(v,k)
end
local function dummy(isDummy,extra)
    return {isDummy=isDummy==nil and true or isDummy,extra_target=extra or 0,to=AIList.new({}),current_targets={}}
end
local function role(self,p)return p==self.player and q(p,"getRole")or q(self,"getRoleEstimate",p)end
local function is_current(use,target)
    for _,p in ipairs(use.current_targets or{})do if p==target or p==q(target,"objectName")then return true end end
end
local function extra(self,card)
    local candidate=q(self,"getEvaluationCandidate",card)or q(self,"getCardCandidate",q(card,"getEffectiveId"))
    if not candidate and AIValue.isConversion(card)then candidate=card end
    return q(known(candidate,"extra-target candidate"),"getExtraTargetCount")
end
local function can_to(self,card,from,to,targets)
    if from~=self.player then ai_unsupported("goddess targetFilter is outside owner scope","CanToCard")end
    return q(self,"cardTargetFilter",card,targets or{},to)
end
local function jueqing(self,from,to)return q(self,"hasJueqingEffect",from,to)end
local function chain(self,to,from)return known(hasChainEffect(to,from),"chain effect")end
local function nullfilter(self,data,pattern,target)
    local f=sgs.ai_skill_cardask.nullfilter
    if type(f)~="function"then ai_unsupported("effective nullfilter unavailable","goddess")end
    return result(f(self,data,pattern,target))
end
local function current_damage(self)
    local raw=known(q(self,"getDecisionContext").damage,"CurrentDamageStruct")
    local copy={};for k,v in pairs(raw)do copy[k]=v end
    copy.damage=known(raw.amount~=nil and raw.amount or raw.damage,"CurrentDamageStruct.damage")
    return copy
end
local function tag_card(self,key,nullable_tag)ai_unsupported("goddess room tag is not projected",key)end
-- Fixed PoAskPo reads toCard() only as a truth value. A finite native producer
-- window attests presence; no unused card face or subcard identity is required.
local function tag_present(self,key)ai_unsupported("goddess room tag is not projected",key)end
-- Room tag UseHistory<index>; an absent tag reads as the donor's empty CardUseStruct.
local function history_use(self,index)
    local u=self:getUseHistory(index)
    if u==nil then return {}end
    return{from=u.from~=""and q(self.room,"findPlayerByObjectName",u.from,true)or nil,
        card=type(u.card)=="table"and u.card.name~=nil and CardView.new(u.card)or nil}
end
local function humanized(self)
    local policy=q(self,"getResponsePolicy")
    return known(policy.humanized,"AIHumanized")
end
local function owner_property(self,key)
    -- The viewer's own property, read like the donor's toString() (absent reads "").
    local v=self.player:getPropertyValue(key)
    if v==nil then return "" end;return v
end
local function persistent_effect_card(self)
    local context=q(self,"getDecisionContext")
    return known(context.effect and context.effect.card,"sgs.cardEffect.card")
end
local function update_intentions(self,from,tos,level)for _,to in ipairs(tos)do q(self,"updateIntention",from,to,level)end end
local function turn_conversion(self,request,wire,costs)
    local name,skill=wire:match('^(%w+):(%w+)%[')
    -- Raw NoSuit/0 storage inherits the sole material through Card::getSuit/getNumber.
    local printed=({SavageAssault="savage_assault",ArcheryAttack="archery_attack"})[name]
    if not printed then ai_unsupported("goddess conversion source class not audited",name)end
    local material=q(self,"getKnownCardById",costs[1])
    return q(self,"evaluateTurnConversion",skill,name,{name=printed,skill=skill,suit=q(material,"getSuit"),number=q(material,"getNumber"),subcards=costs},request or self.request)
end
local function youhua_source(self,material_id,reference,request)
    local row=q(self,"getGodYouhuaSourceObservation",material_id)
    if row.reference_id~=reference then ai_unsupported("GodYouhua reference changed during source evaluation","GodYouhua")end
    if row.exists==false then error("donor GodYouhua Card_Parse assertion failed",0)end
    return q(self,"evaluateTurnConversion","GodYouhua",known(row.card.class_name,"GodYouhua parsed class"),
        {name=known(row.card.name,"GodYouhua parsed name"),skill=known(row.card.skill_name,"GodYouhua parsed skill"),
         suit=known(row.card.suit,"GodYouhua parsed suit"),number=known(row.card.number,"GodYouhua parsed number"),subcards={material_id}},request or self.request)
end
sgs.ai_fill_skill.GodQuxiang = function(self, inclusive, request)
	if q(self.player,"getHandcardNum") < 1 then return end
	local can = false
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	local subcards = {}
	q(self,"sortByUseValue",cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if q(card,"isBlack") then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if q(self,"getKeepValue",cardsq[1])  > 18 then return end
	if q(self,"getUseValue",cardsq[1]) > 12 then return end
	table.insert(subcards, q(cardsq[1],"getId"))
	local card_str = "SavageAssault:GodQuxiang[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = turn_conversion(self,request,card_str,subcards)
	assert(AsCard)
	return AsCard
end


sgs.ai_skill_choice["GodShenfu"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

sgs.ai_fill_skill.GodShijun = function(self, inclusive, request)
	if not q(self.player,"canDiscard",self.player,"he") then return end
	return q(self,"legacySkillSeed","GodShijun","#GodShijunCard",request or self.request)
end

sgs.ai_skill_use_func["#GodShijunCard"] = function(card, use, self, request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sort",self.enemies, "handcard")
	local slashcount = q(self,"getCardsNum","Slash")
	q(self,"sortByUseValue",cards,true)
	if slashcount > 0  then
		for _, card in ipairs(cards) do
				if (not q(card,"isKindOf","Peach") and not q(card,"isKindOf","ExNihilo") and not q(card,"isKindOf","Jink")) or q(self,"getOverflow") > 0 then
				local slash = q(self,"getCard","Slash")
					assert(slash)
					local dummy_use = q(self,"withOwnerRange","InfinityAttackRange","GodShijun",function()
						return q(self,"aiUseCard",slash,dummy(true))
					end)
					if dummy_use.card and dummy_use.to:length() > 0 then
						local target
						for _, enemy in ipairs(self.enemies) do
							if not q(self.player,"inMyAttackRange",enemy) then
								target = enemy
							else
								return
							end
						end
						if target then
						use.card = q(self,"bindSkillCard","GodShijun",{q(card,"getId")},request or self.request,nil,"#GodShijunCard")
								if use.to then use.to:append(target) end
								return
						end
					end
				end
			end
	end
end

sgs.ai_card_intention["GodShijunCard"] = 70


sgs.ai_use_value["GodShijunCard"] = 9.2
sgs.ai_use_priority["GodShijunCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_fill_skill.GodYouhua = function(self, inclusive, request)
	if q(self.player,"isNude") then return nil end
	if q(self.player,"getMark","LastId") == 0 or q(self.player,"hasFlag","YouhuaUsed") then return nil end 
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	local card = cards[1]
	local Id = q(self.player,"getMark","LastId")
		
	if card and q(self.player,"getMark","LastId") > 0 then
        local reference=q(self,"getGodYouhuaSourceObservation")
        if reference.reference_id~=Id then ai_unsupported("GodYouhua current LastId observation differs","GodYouhua")end
        -- Source calls isKindOf on the actual clone, not on the physical reference.
        if reference.clone_exists==false then error("donor GodYouhua cloneCard returned nil before isKindOf",0)end
        for _,kind in ipairs(reference.clone.kind_of)do if kind=="IronChain"then return nil end end
        -- Preserve reached source getter/mark order before its Card_Parse call.
        local suit=q(card,"getSuitString")
        local number=q(card,"getNumberString")
        local material_id=q(card,"getEffectiveId")
        if q(self.player,"getMark","LastId")<=0 then error("donor GodYouhua source wire became nil",0)end
        return youhua_source(self,material_id,Id,request)
	end
end	




sgs.ai_fill_skill.GodGongshen = function(self, inclusive, request)
	if q(self.player,"getHandcardNum") < 1 then return end
	local can = false
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	local subcards = {}
	q(self,"sortByUseValue",cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if q(card,"isKindOf","EquipCard") then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if q(self,"getKeepValue",cardsq[1])  > 18 then return end
	if q(self,"getUseValue",cardsq[1]) > 12 then return end
	table.insert(subcards, q(cardsq[1],"getId"))
	local card_str = "ArcheryAttack:GodGongshen[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = turn_conversion(self,request,card_str,subcards)
	assert(AsCard)
	return AsCard
end



sgs.ai_skill_playerchosen["GodJiuse"] = function(self, targets)
	local damage = current_damage(self)
	targets = sgs.QList2Table(targets)
			if q(self,"isEnemy",damage.to) then	
					q(self,"sort",targets, "defense")
					for _, anotherenemy in ipairs(targets) do
						if  q(self,"ajustDamage",damage.from,damage.to,damage.damage,damage.card) > 0 then
							if q(self,"isWeak",damage.to) then
								if q(self,"isEnemy",anotherenemy) and q(self,"ajustDamage",anotherenemy,damage.to,damage.damage,damage.card) > 0 then
									return anotherenemy
								end
							else
								if q(self,"isFriend",anotherenemy) and q(self,"ajustDamage",anotherenemy,damage.to,damage.damage,damage.card) > 0  then
									return anotherenemy
								end
						end
					end
				end
			end

	return nil
end

sgs.ai_ajustdamage_from.GodJiuse = function(self, from, to, card, nature)
	if (card and q(card,"isKindOf","Slash")) and q(from,"getPhase") == sgs.Player_Play	then
		for _,p in sgs.qlist(q(self.room,"getOtherPlayers",from)) do
			if q(p,"isMale") and q(p,"inMyAttackRange",to) then
				return 1
			end
		end
	end
end
-- GodJiuse identity-gated alias remains shared-owned.


sgs.ai_skill_invoke.GodManwu = function(self, data)
	local card = tag_card(self,"GodManwu")
	if q(self,"isWeak") and (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) then return true end
	if q(self.player,"getWeapon") and q(self.player,"getWeapon"):isKindOf("Crossbow") and q(card,"isKindOf","Slash") then return true end
	if not q(self,"isWeak") and (q(card,"isKindOf","Snatch") or q(card,"isKindOf","ExNihilo") or q(card,"isKindOf","Dismantlement")) then return true end
	return false
end


sgs.ai_skill_choice["LuaDanji"] = function(self, choices, data)
	local items = choices:split("+")
	if q(self.player,"isWeak") then
		return "distwocards"
	end
	return items[math.random(1,#items)]
end

function sgs.ai_skill_invoke.LuaXJianshou(self, data)
	local sbdiaochan = q(self.room,"findPlayerBySkillName","lihun")
	if sbdiaochan and q(sbdiaochan,"faceUp") and not q(self,"willSkipPlayPhase",sbdiaochan)
		and (q(self,"isEnemy",sbdiaochan) or (known(self.world.turn_count,"turncount") <= 1 and role(self,sbdiaochan) == "neutral")) then return false end
	if not q(self.player,"faceUp") then return true end
	for _, friend in ipairs(self.friends) do
		if q(self,"hasSkills","fangzhu|jilve", friend) then return true end
		if q(friend,"hasSkill","junxing") and q(friend,"faceUp") and not q(self,"willSkipPlayPhase",friend)
			and not (q(friend,"isKongcheng") and q(self,"willSkipDrawPhase",friend)) then
			return true
		end
	end
	return q(self,"isWeak")
end

sgs.ai_target_revises.LuaTiebi = function(to,card)
	if q(card,"isKindOf","Dismantlement") and not q(to,"faceUp")
	then return true end
end

sgs.bad_skills = sgs.bad_skills .. "|GodXiaoshi"


-- GodSaodang identity-gated alias remains shared-owned.

sgs.ai_target_revises.GodYuxiang = function(to,card)
	if q(card,"isKindOf","SavageAssault")
	then return true end
end


function SmartAIView:useCardshot(card,use)
	local extraTarget = extra(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	local function slashNoTarget(target)
		if is_current(use,target)
		or use.to:contains(target) then return end
		if use.card and use.card~=card then
			extraTarget = extra(self,use.card)
			if use.extra_target then extraTarget = extraTarget+use.extra_target end
		end
		if use.to:length()>extraTarget then return true end
		if can_to(self,use.card or card,self.player,target)
		and q(self,"ajustDamage",self.player,target,1,use.card or card)~=0 then
			if (q(card,"isKindOf","thunder_shot") or q(card,"isKindOf","fire_shot"))
			and chain(self,target,self.player) then
				if q(self,"isGoodChainTarget",target,card) then
					use.card = card
					use.to:append(target)
				end
			else
				use.card = card
				use.to:append(target)
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if role(self,friend)==role(self,self.player)
		and q(self,"isPriorFriendOfSlash",friend,use.card or card)
		and slashNoTarget(friend) then return end
	end
	
	local forbidden = {}
	q(self,"sort",self.enemies,"defenseSlash")
	for _,enemy in ipairs(self.enemies)do
		if q(self,"isGoodTarget",enemy,self.enemies,use.card or card) then
			if q(self,"objectiveLevel",enemy)<=3
			then table.insert(forbidden,enemy)
			elseif slashNoTarget(enemy)
			then return end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if role(self,friend)==role(self,self.player)
		and (use.card or card):getSkillName()~="lihuo"
		and not(q(friend,"isLord") and #self.enemies<1)
		and q(self,"needToLoseHp",friend,self.player,use.card or card,true)
		and q(self,"ajustDamage",self.player,friend,1,use.card or card)==1
		and slashNoTarget(friend) then return end
	end
	for _,target in ipairs(forbidden)do
		if slashNoTarget(target) then return end
	end
end
sgs.ai_use_priority.shot = 4.55
sgs.ai_use_value.shot = 9
sgs.ai_keep_value.shot = 1.0
sgs.ai_card_intention.shot = 40
function SmartAIView:useCardthunder_shot(...)
	q(self,"useCardshot",...)
end
sgs.card_damage_nature.thunder_shot = "T"

sgs.ai_card_intention.thunder_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.thunder_shot = 4.6
sgs.ai_keep_value.thunder_shot = 3.63
sgs.ai_use_priority.thunder_shot = 2.5

function SmartAIView:useCardfire_shot(...)
	q(self,"useCardshot",...)
end
sgs.card_damage_nature.fire_shot = "F"

sgs.ai_card_intention.fire_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.fire_shot = 4.6
sgs.ai_keep_value.fire_shot = 3.63
sgs.ai_use_priority.fire_shot = 2.5



sgs.ai_skill_cardask["shot-jink"] = function(self,data,pattern,target)
	local slash = q(self,"getEvaluationCard","slash")
	local effect = q(data,"toCardEffect")
	if (type(data)=="table" or type(data)=="userdata") and effect and effect.card then slash = effect.card end
	local source = target or (effect and effect.from)
	if not source or nullfilter(self,data,pattern,source)=="."
	or (q(slash,"isKindOf","fire_shot") or q(slash,"isKindOf","thunder_shot")) and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player,slash,source)then return "." end
	local n = q(self,"ajustDamage",source,self.player,1,(effect and effect.card) or slash)
	if q(self,"needToLoseHp",self.player,source,slash) and n==1
	then return "." end
	local function getJink()
		if #self.friends_noself>0 and q(self,"getCardsNum","Peach,Analeptic")<1
		and q(self.player,"getHp")<=math.abs(n) then
			q(self,"speak","noJink")

		end
		return "."
	end
	if q(self,"isFriend",source) then
		if q(self.player,"getLostHp")==0 and q(self.player,"isMale") and q(source,"hasSkill","jieyin") then return "." end
		if not jueqing(self,source,self.player) then
			if (q(source,"hasSkill","nosrende") or q(source,"hasSkill","rende") and not q(source,"hasUsed","RendeCard")) and q(self.player,"hasSkill","jieming")
			or q(source,"hasSkill","pojun") and not q(self.player,"faceUp")
			then return "." end
		end
	else
		if n>1 or n>=q(self.player,"getHp") then return getJink() end
		local current = q(self.room,"getCurrent")
		if current and current:hasSkill("juece") and q(self.player,"getHp")>0 then
			for _,c in sgs.list(q(self,"getCards","Jink"))do
				if q(self.player,"isLastHandCard",c,true)
				then return "." end
			end
		end
		if q(self.player,"getHandcardNum")==1 and q(self,"needKongcheng")
		or not(q(self,"hasLoseHandcardEffective") or q(self.player,"isKongcheng")) then return getJink() end
		if q(self.player,"getHp")>1 and getKnownCard(source,self.player,"Slash")>0
		and getKnownCard(source,self.player,"Analeptic")>0 and q(self,"getCardsNum","Jink")<=1
		and (q(source,"getPhase")<=sgs.Player_Play or q(self,"slashIsAvailable",source) and q(source,"canSlash",self.player))
		then return "." end
	end
	return getJink()
end


sgs.ai_skill_cardask["Kai-Jink"] = function(self,data,pattern,target)
	local isUse = q(data,"toStringList")[3] == "use"
	local use 
	if isUse then
		if q(data,"toStringList")[4] then 
			use = history_use(self,q(data,"toStringList")[4])
		end
	end
	local function getKai()
		if humanized(self) then

		end
		for _,c in sgs.list(q(self,"getCard","Kai",true))do
			if q(self.player,"hasFlag","dahe") and q(c,"getSuit")~=sgs.Card_Heart then continue end
			return c
		end
		if humanized(self) and math.random()<0.5 and #self.friends_noself>0 and q(self,"getCardsNum","Peach,Analeptic")<1
		and q(self.player,"getHp")<=math.abs(n) then
			q(self,"speak","noJink")

		end
		return "."
	end
	if isUse then
		if use.card and q(use.card,"hasFlag","NosJiefanUsed") then return getKai()  end
		if not use.from or nullfilter(self,data,pattern,use.from)
		or q(use.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player,use.card,use.from)
		or q(self,"needToLoseHp",self.player,use.from,use.card) and q(self,"ajustDamage",use.from,self.player,1,use.card)==1 then return "." end
	end
	if q(self,"needToLoseHp",self.player, use.from, use.card, true) then return "."  end
	if q(self,"getCardsNum","Jink") == 0 then return getKai() end
	if q(self,"ajustDamage",use.from,self.player,1,use.card)>1 then return getKai() end
end

sgs.ai_use_value.Kai = 9
sgs.ai_keep_value.Kai = 5.3

sgs.ai_skill_cardask["PoAskPo"] = function(self,data,pattern,target)
    -- Exact native non-CardUse question conversion has a null source. The
    -- original getTag/toCard read is total, pure, and its result is unused on
    -- this branch; do not turn that read into a private presence capability.
    local context=q(self,"getDecisionContext")
    local empty=type(context.goddess)=="table"and context.goddess.po_ask_empty_use
    if empty~=nil and empty~=false then
        local r=self.request
        if type(empty)~="table"or empty.known~=true
            or (empty.source~="Kai.CardAsked"and empty.source~="Weikai.CardResponded")
            or not r or r.kind~="respond_card"or r.pattern~="Weikai"
            or r.prompt~="PoAskPo"or r.handling_method~=sgs.Card_MethodUse then
            ai_unsupported("Goddess default CardUse proof is malformed or outside current question","PoAskPo")
        end
        return "."
    end
	local use = q(data,"toCardUse")
	local Weikai = tag_present(self,"Weikai")
	if use.from and q(self,"isEnemy",use.from) then
		if Weikai then
			return "."
		else
			for _,c in sgs.list(q(self,"getCard","Weikai",true))do
				return c
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAsk"] = function(self,data,pattern,target)
	local use = q(data,"toCardUse")
	if use.from and q(self,"isEnemy",use.from) then
		for _,c in sgs.list(q(self,"getCard","Weikai",true))do
			return c
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAskAgain"] = function(self,data,pattern,target)
	for _,c in sgs.list(q(self,"getCard",pattern,true))do
		return c
	end
	return true
end
sgs.ai_keep_value.Weikai = 5.2

function SmartAIView:useCardSu(card,use)
	q(self,"sort",self.friends,"hp")
	local extraTarget = 1 + extra(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends)do
		if is_current(use,ep) then continue end
		if q(self.player,"canUse",card,ep) then
	    	use.card = card
	    	use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Su = 2.4
sgs.ai_keep_value.Su = 2.2
sgs.ai_use_value.Su = 4.7
sgs.ai_card_intention.Su = -33

function SmartAIView:useCardgongcheng(card,use)
	local slash = q(self,"getCard","Slash")
	if slash and #q(self,"getCards","Slash") > 1 then
		local dummy_use = q(self,"aiUseCard",slash, dummy())
		if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
			use.card = card
		end
	end
end
sgs.ai_use_priority.gongcheng = 2.7
sgs.ai_keep_value.gongcheng = 2.2
sgs.ai_use_value.gongcheng = 4.7

function SmartAIView:useCardxianzhencard(card,use)
	local dismantlement = q(self,"getEvaluationCard","dismantlement")
	
	local dummy_use = q(self,"aiUseCard",dismantlement, dummy(true,99))
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() and dummy_use.to:length() >= q(self.room,"alivePlayerCount")/2 then
		use.card = card
	end
end
sgs.ai_use_value.xianzhencard = 5.6
sgs.ai_use_priority.xianzhencard = 9.4
sgs.ai_keep_value.xianzhencard = 3.44
-- xianzhencard identity-gated alias remains shared-owned.










-- The donor sets a real flag on its own player, live until that player's next flag
-- clear. The isolated VM cannot set it, so its own writes go to viewer memory stamped
-- with the flag lifecycle epoch; a flag set by a gameplay-VM decision is read directly.
local function manbing_flag(self,target,write)
    local name=q(target,"objectName")
    if self.room:findPlayerByObjectName(name,true)~=target then
        ai_unsupported("Manbing target is outside the current roster","manbingTo_")
    end
    local epochs=known(AIWorldLifecycle.epochs(self.world,"flag"),"manbingTo_")
    local epoch=known(epochs[q(self.player,"objectName")],"manbingTo_")
    local key="goddess.manbingTo_"..name
    if write then q(self,"remember",key,epoch);return true end
    return q(self.player,"hasFlag","manbingTo_"..name) or self:recall(key)==epoch
end

function SmartAIView:useCardmanbing(manbing,use)
	self.aiUsing = q(manbing,"getSubcards")
	local extraTarget = extra(self,manbing)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if use.xiechan then extraTarget = 100 end
	q(self,"sort",self.enemies)
	local enemySlash = 0
	for _,enemy in sgs.list(self.enemies)do
		if is_current(use,enemy) then continue end
		if manbing_flag(self,enemy)
		and can_to(self,manbing,self.player,enemy)
		and q(self,"ajustDamage",self.player,enemy,1,manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if n2>0 then continue end
			enemySlash = enemySlash+n2
			if q(self.player,"getPhase")<=sgs.Player_Play and math.random()<0.5
			then manbing_flag(self,enemy,true) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
	local bcv = {}
	for _,p in ipairs(self.enemies)do
		local v1 = getCardsNum("Slash",p,self.player)+q(p,"getHp")
		if not q(self,"isWeak",p) and q(p,"hasSkill","jianxiong") and not jueqing(self,self.player,p) then v1 = v1+10 end
		if q(self,"needToLoseHp",p,nil,manbing) then v1 = v1+15 end
		if q(self,"hasSkills",sgs.masochism_skill,p) then v1 = v1+5 end
		if not q(self,"isWeak",p) and q(p,"hasSkill","jiang") then v1 = v1+5 end
		if q(p,"hasLordSkill","jijiang") then v1 = v1+q(self,"JijiangSlash",p)*2 end
		bcv[q(p,"objectName")] = v1
	end
	local function compare_func(a,b)
		return bcv[q(a,"objectName")]<bcv[q(b,"objectName")]
	end
	table.sort(self.enemies,compare_func)
	for _,enemy in sgs.list(self.enemies)do
		if is_current(use,enemy) then continue end
		if not use.to:contains(enemy) and can_to(self,manbing,self.player,enemy)
		and q(self,"objectiveLevel",enemy)>3 and q(self,"isGoodTarget",enemy,self.enemies)
		and q(self,"ajustDamage",self.player,enemy,1,manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if q(self,"needToLoseHp",self.player,nil,manbing,true) or n2<1 
			or q(self,"hasSkill","jianxiong") or owner_property(self,"shuangxiong_colors_turn") ~= ""
			then else continue end
			enemySlash = enemySlash+n2
			if q(self.player,"getPhase")<=sgs.Player_Play and math.random()<0.5
			then manbing_flag(self,enemy,true) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_card_intention.manbing = function(self,card,from,tos)
	update_intentions(self,from,tos,66)
end

sgs.ai_use_value.manbing = 3.7
sgs.ai_use_priority.manbing = 2.9
sgs.ai_keep_value.manbing = 3.42

sgs.dynamic_value.damage_card.manbing = true

sgs.ai_skill_cardask["manbing-slash1"] = function(self,data,pattern,target)
	local effect = q(data,"toCardEffect")
	if q(self.player,"hasSkill","wuhun") and q(self,"isEnemy",effect.from) and q(effect.from,"isLord") and #self.friends_noself>0
	or q(self,"getCardsNum","Slash")<2
	or q(self,"isEnemy",effect.from) and not q(self,"isWeak") and q(self,"needToLoseHp",self.player,effect.from, effect.card)
	or q(self,"ajustDamage",effect.from,self.player,1,effect.card)==0
	or nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if q(self,"getCardsNum","Slash")>=2 then return true end
	return "."
end
sgs.ai_skill_cardask["manbing-slash2"] = function(self,data,pattern,target)
	local effect = q(data,"toCardEffect")
	if q(self.player,"hasSkill","wuhun") and q(self,"isEnemy",effect.from) and q(effect.from,"isLord") and #self.friends_noself>0
	or q(self,"getCardsNum","Slash")<1
	or q(self,"isEnemy",effect.from) and not q(self,"isWeak") and q(self,"needToLoseHp",self.player,effect.from)
	or q(self,"ajustDamage",effect.from,self.player,1,effect.card)==0
	or nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if q(self,"getCardsNum","Slash")>=1 then return true end
	return "."
end


function SmartAIView:useCardquanxiang(card,use)
	q(self,"sort",self.enemies,"skill",false)
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if q(ep,"getMark","@RemoveGeneral") == 0
		and q(ep,"getVisibleSkillList"):length()>0
		and q(ep,"getHandcardNum") < q(self.player,"getHandcardNum")
	   	and can_to(self,card,self.player,ep,use.to) then
	    	use.card = card
	    	use.to:append(ep)
		end
	end
end
sgs.ai_use_priority.quanxiang = 5.4
sgs.ai_keep_value.quanxiang = 4
sgs.ai_use_value.quanxiang = 3.7

sgs.ai_nullification.quanxiang = function(self,trick,from,to,positive)
    return q(self,"isFriend",to) and (q(to,"getHandcardNum")>3 or to==self.player)
	and positive
end

sgs.ai_card_intention.quanxiang = 80

sgs.ai_skill_cardask["@quanxiangmessage"] = function(self,data,pattern,target)
	if target and q(self,"isEnemy",target) then
		local cards = q(self.player,"getCards","he")
        cards = sgs.QList2Table(cards)
        q(self,"sortByKeepValue",cards)
        for _,h in sgs.list(cards)do
            if q(self,"matchesDiscardPattern",pattern,h)
            then return q(h,"getEffectiveId") end
            if q(h,"isKindOf",pattern)
            then return q(h,"getEffectiveId") end
        end
        return q(self,"getCardId",pattern)
	end
end


function SmartAIView:useCardshuigong(shuigong,use)
	local lack = {basic=false,trick=false,equip=false}
	local canDis = {}
	for _,h in sgs.list(q(self.player,"getHandcards"))do
		if q(h,"getEffectiveId")~=q(shuigong,"getEffectiveId")
		and q(self.player,"canDiscard",self.player,q(h,"getEffectiveId"))
		then
			table.insert(canDis,h)
			lack[q(h,"getTypeId")] = true
		end
	end
	local suitnum = 0
	for suit,islack in pairs(lack)do
		if islack then suitnum = suitnum+1  end
	end
	q(self,"sort",self.enemies,"defense")
	local function can_attack(enemy)
		if q(self,"cantbeHurt",enemy,self.player) then return end
		return q(self,"objectiveLevel",enemy)>2
		and q(self,"isGoodTarget",enemy,self.enemies,shuigong)
		and (jueqing(self,self.player,enemy) or not(q(enemy,"hasSkill","jianxiong") and not q(self,"isWeak",enemy)
		or q(self,"needToLoseHp",enemy,self.player,shuigong)))
	end
	local enemies,targets = {},{}
	for _,enemy in sgs.list(self.enemies)do
		if can_attack(enemy) then table.insert(enemies,enemy) end
	end
	for kc,enemy in sgs.list(enemies)do
		kc = getKnownCards(enemy,self.player)
		if #kc>q(enemy,"getHandcardNum")/2
		then
			local can = 0
			for _,h in sgs.list(kc)do
				if lack[q(h,"getSuitString")]
				then can = can+1 end
			end
			if can>=#kc then table.insert(targets,enemy) end
		end
	end
	
	if (suitnum==2 and lack.diamond or suitnum<=1) and #targets<1
	and q(self,"getOverflow")<=(q(self.player,"hasSkills","jizhi|nosjizhi") and -2 or 0)
	then return end
	for _,enemy in sgs.list(enemies)do
		if table.contains(targets,enemy)
		then else table.insert(targets,enemy) end
	end
	local extraTarget = extra(self,shuigong)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,p in sgs.list(targets)do
		if is_current(use,p) then continue end
		if can_to(self,shuigong,self.player,p)
		and q(self,"ajustDamage",self.player,p,1,shuigong)~=0
		then
			use.card = shuigong
			local gs = q(self,"getCard","GodSalvation")
			if gs and q(gs,"getEffectiveId")~=q(shuigong,"getEffectiveId")
			and q(p,"getLostHp")<1 and q(self,"willUseGodSalvation",gs)
			and q(self,"hasTrickEffective",gs,p,self.player)
			then use.card = gs return end
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
end


sgs.ai_use_value.shuigong = 4.8
sgs.ai_keep_value.shuigong = 3.3
sgs.ai_use_priority.shuigong = sgs.ai_use_priority.Dismantlement+0.1
sgs.dynamic_value.damage_card.shuigong = true
sgs.ai_card_intention.shuigong = 80

sgs.ai_skill_cardask["@shuigongmessage_BasicCard"] = function(self,data,pattern,target)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByUseValue",cards,true)
	for i,c in sgs.list(cards)do
		if q(c,"isKindOf","BasicCard") then
			if q(self,"isFriend",target) then
				if q(self,"needToLoseHp",target,self.player,persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not q(self,"isWeak",nil,false) or q(self,"ajustDamage",self.player,target,1,persistent_effect_card(self))>1
				then return q(c,"getId") end
			else
				return q(c,"getId")
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_TrickCard"] = function(self,data,pattern,target)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByUseValue",cards,true)
	for i,c in sgs.list(cards)do
		if q(c,"isKindOf","TrickCard") then
			if q(self,"isFriend",target) then
				if q(self,"needToLoseHp",target,self.player,persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not q(self,"isWeak",nil,false) or q(self,"ajustDamage",self.player,target,1,persistent_effect_card(self))>1
				then return q(c,"getId") end
			else
				return q(c,"getId")
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_EquipCard"] = function(self,data,pattern,target)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByUseValue",cards,true)
	for i,c in sgs.list(cards)do
		if q(c,"isKindOf","EquipCard") then
			if q(self,"isFriend",target) then
				if q(self,"needToLoseHp",target,self.player,persistent_effect_card(self))
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not q(self,"isWeak",nil,false) or q(self,"ajustDamage",self.player,target,1,persistent_effect_card(self))>1
				then return q(c,"getId") end
			else
				return q(c,"getId")
			end
		end
	end
	return "."
end