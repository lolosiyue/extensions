-- Fixed shengrongsiai-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("shengrongsiai policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("shengrongsiai policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...) return known(call(object,method,...),method) end
local function sorted(self,cards,method,...)
    local result=q(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return q(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local function bind(self,skill,class,costs,request) return q(self,"bindSkillCard",skill,costs,action_request(self,request),nil,class) end
-- Source Card_Parse in use_func allocates a fresh policy object, not authority.
-- Keep exact ordered costs; only the final selected proposal may bind.
local function fresh_policy(self,skill,class,costs,request)
    return q(self,"evaluateTurnSkillCard",skill,class,costs,action_request(self,request))
end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function sort_need(self,cards,...)return sorted(self,cards,"sortByCardNeed",...)end
local function dummy(is_dummy,extra,targets)
    local use=AIUsePlan.new();use.isDummy=is_dummy~=false;use.extra_target=extra or 0;use.current_targets=targets or {};return use
end
local function visible_card(self,id) return known(self:getChoiceCard(id)or self:getKnownCardById(id),"shengrongsiai.disclosed_card")end
local function set_target(self,key,p)self:setStrategyMemory("shengrongsiai."..key,p and q(p,"objectName")or false)end
local function get_target(self,key)local name,present=self:getStrategyMemory("shengrongsiai."..key);if present and name then return q(self.room,"findPlayerByObjectName",name,true)end end
-- The donor's visible set: hand cards carrying the public "visible" or
-- "visible_<viewer>_<target>" card flag, read from the known cards' flags.
local function source_visible_hand(self,player)
    local flag=string.format("visible_%s_%s",q(self.player,"objectName"),q(player,"objectName"))
    local cards=player==self.player and q(player,"getHandcards") or q(player,"getKnownCards")
    local out={};for _,card in ipairs(cards)do if q(card,"hasFlag","visible")or q(card,"hasFlag",flag)then out[#out+1]=card end end
    return out
end
-- The decision context carries the CurrentDamageStruct room tag as its damage. This
-- runs in an event callback, where a missing one is not known to be an absent tag.
local function current_damage(self)
    local damage=known(self:getDecisionContext().damage,"CurrentDamageStruct")
    for _,key in ipairs({"from","to"})do if damage[key.."_name"]==""then damage[key]=nil end end
    return damage
end
-- Callers take the target from the event being observed.
local function role_effect(self,source,target)
    local function observed_role(player)
        local role=call(player,"getRole")
        if role==nil then
            role=q(self,"getRoleEstimate",player)
            role=q(self,"useKnowledgeEstimate",{value=role,status="estimate",
                basis="quanxiang:viewer_inference_replaces_foreign_private_role",
                viewer=q(self.player,"objectName"),observer=q(player,"objectName")},"quanxiang.role")
        end
        if not ({lord=true,loyalist=true,rebel=true,renegade=true})[role] then
            ai_unsupported("Quanxiang role observation is unresolved","luaRquanxiang.role")
        end
        return role
    end
    -- The donor's local rebel rewrite is unused by the actual assignment.
    local source_role,target_role=observed_role(source),observed_role(target)
    call(self,"emitStrategyEffect",{kind="quanxiang_role",player=q(target,"objectName"),
        source_player=q(source,"objectName"),source_role=source_role,target_role=target_role})
    call(self,"updatePlayers")
end


sgs.ai_skill_use["@@luaRshiji"]=function(self,prompt)
	call(self,"updatePlayers")
	sort_players(self,self.enemies,"defense")
	
	if q(self,"needBear") then return "." end

	local selfSub = q(self.player,"getHp") - q(self.player,"getHandcardNum")
	local selfDef = q(self,"getDefense",self.player)

	for _,enemy in ipairs(self.enemies) do
		local def = q(self,"getDefenseSlash",enemy)
		local slash = q(self,"getEvaluationCard","slash")
        
		local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)
        if not q(self.player,"canSlash",enemy, slash, true) then
        elseif q(self,"slashProhibit",nil, enemy) then
        elseif def < 6 and eff then return response(self,"luaRshiji","#luaRshiji",{}, {enemy})

        elseif selfSub >= 2 then return "."
        elseif selfDef < 6 then return "." end
	end

	for _,enemy in ipairs(self.enemies) do
		local def=q(self,"getDefense",enemy)
		local slash = q(self,"getEvaluationCard","slash")
        
		local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)
		if not q(self.player,"canSlash",enemy, slash, true) then
		elseif q(self,"slashProhibit",nil, enemy) then
		elseif eff and def < 8 then return response(self,"luaRshiji","#luaRshiji",{}, {enemy})
		else return "." end
	end
	return "."
end


sgs.ai_event_callback[sgs.Death or "Death"]=sgs.ai_event_callback[sgs.Death or "Death"]or{}
sgs.ai_event_callback[sgs.Death or "Death"].luaRquanxiang=function(self,player,event)
    for _,source in ipairs(q(self.room,"getOtherPlayers",player))do
        local holder=q(source,"hasSkill","luaRquanxiang")
        -- A hidden hegemony general's skills are unknown, not absent.
        if not holder and q(source,"areSkillsComplete")~=true then ai_unsupported("Quanxiang holder skills are not public","luaRquanxiang") end
        if holder then
            local target=q(self.room,"findPlayerByObjectName",known(event.to,"death target"),true)
            role_effect(self,source,target)
        end
    end
end
sgs.ai_skill_invoke.luaRquanxiang = function(self, data)
	return true
end


sgs.ai_choicemade_filter.skillInvoke.luaRquanxiang=function(self,player,promptlist)
    if promptlist[#promptlist]=="yes"then
        local damage=current_damage(self)
        if damage.to then role_effect(self,player,damage.to)end
    end
end

sgs.ai_useto_revises.luaRduxian = function(self,card,use,p)
	if q(self.player,"getMark","luaRduxian-PlayClear") >= q(p,"getHp") and not q(self,"needToLoseHp",self.player, p) and q(self.player,"objectName") ~= q(p,"objectName")
	then
        if not q(card,"isKindOf","SkillCard") then
            return false
        end
	end
end

sgs.ai_damage_reason_suppress_intention["luaRduxian"] = true


sgs.ai_card_usage_penalty["luaRduxian"] = function(self, source, target)
    if q(source,"objectName") == q(target,"objectName") then 
        return false 
    end
    
    for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"getHp") < 1 or q(p,"hasFlag","Global_Dying") then return false end
    end

    local used_count = q(target,"getMark","luaRduxian-PlayClear") + 1 -- 預判下一張
    
    -- 如果用牌數超過了妒賢擁有者的體力，則觸發懲罰
    if used_count > q(source,"getHp") then
        return true
    end
    
    return false
end


sgs.ai_skill_playerchosen.luaRcaiyi = function(self,targets)
	sort_players(self,self.enemies,"handcard")
	sort_players(self,self.friends_noself,"defense")
	set_target(self,"luaRcaiyi_target",nil)
	if (q(self.player,"getHandcardNum")<3 and q(self,"getCardsNum","Peach")==0 and q(self,"getCardsNum","Jink")==0 and q(self,"getCardsNum","Analeptic")==0) or
		(q(self.player,"getHandcardNum")<=1 and q(self,"getCardsNum","Peach")==0 and q(self,"getCardsNum","Analeptic")==0) then
		local max_card_num = 0
		for _,enemy in ipairs(self.enemies)do
			max_card_num = math.max(max_card_num,q(enemy,"getHandcardNum"))
		end
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getHandcardNum")==max_card_num and q(enemy,"getHandcardNum")>0 then
				set_target(self,"luaRcaiyi_target",enemy)
				return enemy
			end
		end
	else
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true) then
				set_target(self,"luaRcaiyi_target",friend)
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_discard.luaRcaiyi = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_need(self,cards,true)
	local to_discard = {}
	local half_all_card_num = math.max(1,math.floor(q(self.player,"getHandcardNum")/2))
	for i = 1,half_all_card_num,1 do
		table.insert(to_discard,cards[i]:getEffectiveId())
	end
	return to_discard
end

sgs.ai_skill_choice.luaRcaiyi=function(self,choices,data)
    local items=q(choices,"split","+")
    local target=get_target(self,"luaRcaiyi_target")
    if not target then local items=q(choices,"split","+");return items[math.random(1,#items)]end
    local ids=AIList.new(known(q(self,"getDecisionContext").shengrongsiai_caiyi_ids,"caiyi disclosed input IDs"))
    local shown,unshown=0,0
    local totalabs,halfexact=0,true
    for _,id in ipairs(ids)do shown=shown+q(self,"cardNeed",visible_card(self,id))end
    local visible=source_visible_hand(self,target)
    local excluded={};for _,id in ipairs(ids)do excluded[id]=true end
    local observed=0
    for _,card in ipairs(visible)do
        if not excluded[q(card,"getEffectiveId")]then
            local value=q(self,"cardNeed",card)
            unshown=unshown+value;totalabs=totalabs+math.abs(value);halfexact=halfexact and value*2==math.floor(value*2);observed=observed+1
        end
    end
    local hidden=q(target,"getHandcardNum")-#ids-observed
    if hidden<0 then ai_unsupported("caiyi shown IDs are not current target hand","luaRcaiyi")end
    unshown=unshown+hidden*.5
    -- The donor adds 0.5 for each unseen card. Grouping those additions is
    -- decision-exact outside a conservative floating point roundoff interval.
    local tolerance=(q(target,"getHandcardNum")+#ids+2)*2.220446049250313e-16*(totalabs+hidden*.5+math.abs(shown))*2
    if hidden>0 and not(halfexact and totalabs+hidden*.5<2^50) and math.abs(shown-unshown)<=tolerance then
        ai_unsupported("caiyi hidden-order floating-point tie is unresolved","luaRcaiyi")
    end
    if shown>unshown then return "luaRcaiyi1"end
    if shown<=unshown then return "luaRcaiyi2"end
    return items[math.random(1,#items)]
end
function sgs.ai_skill_invoke.luaRhuogen(self, data)
	local target = call(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return not q(self,"isWeak")
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.luaRhuogen = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-80) end
	end
end

local luaRsihu_skill = {}
luaRsihu_skill.name = "luaRsihu"
table.insert(package_skills,luaRsihu_skill)
luaRsihu_skill.getTurnUseCard = function(self,inclusive,request)
	local card
	if q(self,"needToThrowArmor") then
		card = call(self.player,"getArmor")
	end
	if not card then
		local hcards = q(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards,true)

		for _,hcard in ipairs(hcards)do
			if q(hcard,"isKindOf","Slash") then
				if q(self,"getCardsNum","Slash")>1
				then
					card = hcard
					break
				else
					local dummy_use = q(self,"aiUseCard",hcard, dummy())
					if dummy_use and dummy_use.to and (q(dummy_use.to,"length")==0
					or q(dummy_use.to,"length")==1 and q(self,"ajustDamage",self.player,q(dummy_use.to,"first"),1,hcard)<2)
					then
						card = hcard
						break
					end
				end
			elseif q(hcard,"isKindOf","EquipCard")
			then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = q(self.player,"getCards","e")
		ecards = AIList.new(ecards)

		for _,ecard in ipairs(ecards)do
			if q(ecard,"isKindOf","Weapon") or q(ecard,"isKindOf","OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		return q(self,"evaluateTurnSkillCard","luaRsihu","#luaRsihuCard",{q(card,"getEffectiveId")},action_request(self,request))
	end
end

sgs.ai_skill_use_func["#luaRsihuCard"] = function(card,use,self,request)
	local target
	local friends = self.friends_noself
	local slash = q(self,"getEvaluationCard","slash")
	set_target(self,"luaRsihuTarget",nil)

	local canluaRsihuTo = function(player)
		local canGive = not q(self,"needKongcheng",player,true)
		return canGive or (not canGive and q(self,"getEnemyNumBySeat",self.player,player)==0)
	end

	sort_players(self,self.enemies,"defense")
	for _,friend in ipairs(friends)do
		if canluaRsihuTo(friend) then
			for _,enemy in ipairs(self.enemies)do
				if q(friend,"canSlash",enemy, nil, false) and not q(self,"slashProhibit",slash,enemy) and q(self,"getDefenseSlash",enemy)<=2
				and q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)
				and q(enemy,"objectName")~=q(self.player,"objectName") then
					target = friend
					set_target(self,"luaRsihuTarget",enemy)
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		sort_players(self,friends,"defense")
		for _,friend in ipairs(friends)do
			if canluaRsihuTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		call(use.to,"append",target)
	end
end

sgs.ai_skill_playerchosen.luaRsihu = function(self,targets)
	local remembered=get_target(self,"luaRsihuTarget")
	if remembered then return remembered end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

-- sgs.ai_playerchosen_intention.luaRsihu = 80

sgs.ai_use_value["luaRsihuCard"] = 5.9
sgs.ai_use_priority["luaRsihuCard"] = 4

sgs.ai_card_intention["luaRsihuCard"] = -70

ai_audited_aliases.register{id="ai_cardneed.luaRsihu",registry="ai_cardneed",path={"luaRsihu"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}

sgs.ai_skill_cardask["@luaRsihu"] = function(self, data, pattern)
    local target = call(data,"toPlayer")
    local slash = q(self,"getEvaluationCard","slash")
    local handcards = AIList.new(q(self.player,"getCards","he"))
	local use_card = {}
	sort_keep(self,handcards)
    if q(self,"needToLoseHp",self.player, target, slash, true) then return "."  end
	for _,c in ipairs(handcards) do
		if q(self,"matchesDiscardPattern",pattern,c)
		then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return "." end
   
    if q(self,"getCardsNum","Jink") == 0 then return use_card[1] end
    if q(self,"ajustDamage",target,self.player,1,slash)>1 then return use_card[1] end
    if q(self.player,"getHandcardNum")==1 and q(self,"needKongcheng")
    or not(q(self,"hasLoseHandcardEffective") or q(self.player,"isKongcheng")) then return use_card[1] end
    return "."
end

sgs.ai_skill_cardask["@luaRjianxiong"] = function(self,data,pattern,target)
    local target = call(data,"toPlayer")
	local card_list = q(self.player,"getHandcards")
	local cards = AIList.new(card_list)
	sort_keep(self,cards,false)
    for _,c in ipairs(cards) do
        if q(c,"hasFlag","luaRjianxiong") then
            if not q(c,"targetFixed") and not q(c,"isKindOf","EquipCard")  then
                local dummy_use = q(self,"aiUseCard",c, dummy(true, 0, q(self.room,"getOtherPlayers",target)))
                if dummy_use.card and dummy_use.to and q(dummy_use.to,"contains",target) then
                    return "$"..q(c,"getEffectiveId")
                end
            else
                if q(target,"objectName") == q(self.player,"objectName") then
                    local dummy_use = q(self,"aiUseCard",c, dummy())
                    if dummy_use.card then
                        return "$"..q(c,"getEffectiveId")
                    end
                end
            end
        end
    end
	return "."
end

ai_audited_aliases.register{id="ai_cardneed.luaRyaowu",registry="ai_cardneed",path={"luaRyaowu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_can_damagehp.luaRzhiyu = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to) and from and q(from,"getHandcardNum") - q(self.player,"getHandcardNum") >= 2
end

sgs.ai_skill_invoke.luaRqice = function(self, data)
    local use = q(data,"toCardUse")
    if q(self.player,"getPhase") == sgs.Player_Play and not q(self.player,"isKongcheng") then 
        local cards = AIList.new(q(self.player,"getCards","h"))
	    for _,c in sgs.list(cards)do
            if q(self,"willUse",self.player,c) then
                return false
            end
        end
    end
    if use.from and q(self,"isFriend",use.from) then
        if q(self.player,"isKongcheng") and q(self,"isWeak") then return false end
        if q(use.card,"isDamageCard") or q(use.card,"isKindOf","SingleTargetTrick") then
            for _,to in sgs.list(use.to)do
                if q(self,"isFriend",to)
                then return false end
            end
            if not q(self.player,"isKongcheng") then
                local cards = AIList.new(q(self.player,"getCards","h"))
                for _,c in sgs.list(cards)do
                    if q(self,"getUseValue",c) > q(self,"getUseValue",use.card) then
                        return false
                    end
                end
            end
            return true
        end
        local dummy_use = q(self,"aiUseCard",use.card, dummy())
        if dummy_use.card and dummy_use.to then
            for _, p in sgs.qlist(dummy_use.to) do
                if q(use.to,"contains",p) then
                    return true
                end
            end
        end
    end
	return false
end

local luaRziao_skill = {}
luaRziao_skill.name = "luaRziao"
table.insert(package_skills, luaRziao_skill)
luaRziao_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self,"needBear") then return end
	if #self.enemies < 1 or q(self.player,"isKongcheng") then return end
	if not q(self.player,"isKongcheng") then
		return seed(self,"luaRziao","#luaRziao",request)
	end
end

sgs.ai_skill_use_func["#luaRziao"] = function(card,use,self,request)
	sort_players(self,self.enemies, "handcard")
	local cards = AIList.new({})
	local peach = 0
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			call(cards,"append",c)
		end
	end
	local max_card = call(self,"getMaxCard",self.player, cards)
	if not max_card then return end
	local max_point = q(max_card,"getNumber")
	local card_str = "#luaRziao:.:"
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") and q(self.player,"canPindian",enemy) then
			local enemy_max_card = call(self,"getMaxCard",enemy)
			local allknown = 0
			if q(self,"getKnownNum",enemy) == q(enemy,"getHandcardNum") then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > q(enemy_max_card,"getNumber") and allknown > 0)
				or (enemy_max_card and max_point > q(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				call(self,"remember","zhijian_card",q(max_card,"getEffectiveId"))
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	if q(self.player,"getHandcardNum") >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isKongcheng") and q(self.player,"canPindian",enemy) then
				local cardsq = q(self.player,"getHandcards")
				cardsq = AIList.new(cardsq)
				sort_use(self,cardsq, true)

				local min_card = call(self,"getMinCard")
				local enemy_min_card = call(self,"getMinCard",enemy)
				if enemy_min_card and q(min_card,"getNumber") < q(enemy_min_card,"getNumber") then
					local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
					use.card = acard
					call(self,"remember","zhijian_card",q(max_card,"getEffectiveId"))
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end

	if q(self.player,"hasSkill","kongcheng") and q(self.player,"getHandcardNum") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isKongcheng") and not q(self,"doDisCard",enemy, "h") and q(self.player,"canPindian",enemy) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	local zhugeliang = call(self.room,"findPlayerBySkillName","kongcheng")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	if zhugeliang and q(self,"isFriend",zhugeliang) and q(zhugeliang,"getHandcardNum") == 1 and q(self.player,"canPindian",zhugeliang)
		and q(zhugeliang,"objectName") ~= q(self.player,"objectName") and q(self,"getEnemyNumBySeat",self.player, zhugeliang) >= 1 then
		if isCard("Jink", cards[1], self.player) and q(self,"getCardsNum","Jink") == 1 then return end
		local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
		use.card = acard
		if use.to then call(use.to,"append",zhugeliang) end
		return
	end

	if q(self,"getOverflow") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not q(self,"doDisCard",enemy, "h", true) and not q(enemy,"isKongcheng") and q(self.player,"canPindian",enemy) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				call(self,"remember","luaRziao_card",q(max_card,"getEffectiveId"))
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.luaRziao(minusecard, self, requestor)
	if q(requestor,"getHandcardNum") == 1 then
		local cards = AIList.new(q(self.player,"getHandcards"))
		sort_keep(self,cards)
		return cards[1]
	end
	local maxcard = call(self,"getMaxCard")
	return q(self,"isFriend",requestor) and call(self,"getMinCard") or (q(maxcard,"getNumber") < 6 and minusecard or maxcard)
end
sgs.ai_use_priority["luaRziao"]   = 5
sgs.ai_card_intention["luaRziao"] = 10
ai_audited_aliases.register{id="ai_cardneed.luaRziao",registry="ai_cardneed",path={"luaRziao"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.luaRshicai",registry="ai_cardneed",path={"luaRshicai"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}


sgs.ai_skill_playerchosen.luaRyaoyan = function(self,targets)
	targets = AIList.new(targets)
	for _,target in ipairs(targets)do
		if q(self,"isFriend",target) and q(target,"isAlive") then
			if q(target,"isWounded") then
				return target
			end
			local zhangjiao = call(self.room,"findPlayerBySkillName","guidao")
			if zhangjiao and q(self,"isFriend",zhangjiao) then
				return target
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.luaRyaoyan = -40

local luaRzhangshi_skill = {}
luaRzhangshi_skill.name = "luaRzhangshi"
table.insert(package_skills, luaRzhangshi_skill)
luaRzhangshi_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies < 1 or q(self.player,"hasUsed","#luaRzhangshicard") then return end
    if #q(self.room,"getLieges","qun",self.player) < 1 then return end
	return seed(self,"luaRzhangshi","#luaRzhangshicard",request)
end


sgs.ai_skill_use_func["#luaRzhangshicard"] = function(card,use,self,request)
	local target
	sort_players(self,self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            target = enemy
        end
    end
	if target then
		use.card = fresh_policy(self,"luaRzhangshi","#luaRzhangshicard",{},request)
		if use.to then call(use.to,"append",target) end
		return
	end
end
sgs.ai_use_value["luaRzhangshicard"]       = 8
sgs.ai_use_priority["luaRzhangshicard"]    = 8
sgs.ai_card_intention["luaRzhangshicard"]  = 50
sgs.ai_skill_choice["luaRzhangshi"] = function(self, choices, data)
	local items = q(choices,"split","+")
    if #q(self.room,"getLieges","qun",self.player) < 1 then return "slash" end
	return items[math.random(1,#items)]
end


for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
