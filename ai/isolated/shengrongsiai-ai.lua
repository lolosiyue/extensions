-- Source: b6025acc ai/shengrongsiai-ai.lua.
local package_skills={}
local known = AIValue.requireKnown
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return (self:legacySkillSeed(skill,class,action_request(self,request))) end
local function bind(self,skill,class,costs,request) return (self:bindSkillCard(skill,costs,action_request(self,request),nil,class)) end
-- Source Card_Parse in use_func allocates a fresh policy object, not authority.
-- Keep exact ordered costs; only the final selected proposal may bind.
local function fresh_policy(self,skill,class,costs,request)
    return (self:evaluateTurnSkillCard(skill,class,costs,action_request(self,request)))
end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local dummy = AIUsePlan.dummy
local function visible_card(self,id) return known(self:getChoiceCard(id)or self:getKnownCardById(id),"shengrongsiai.disclosed_card")end
local function set_target(self,key,p)self:setStrategyMemory("shengrongsiai."..key,p and (p:objectName())or false)end
local function get_target(self,key)local name,present=self:getStrategyMemory("shengrongsiai."..key);if present and name then return (self.room:findPlayerByObjectName(name,true))end end
-- The donor's visible set: hand cards carrying the public "visible" or
-- "visible_<viewer>_<target>" card flag, read from the known cards' flags.
local function source_visible_hand(self,player)
    local flag=string.format("visible_%s_%s",(self.player:objectName()),(player:objectName()))
    local cards=player==self.player and (player:getHandcards()) or (player:getKnownCards())
    local out={};for _,card in ipairs(cards)do if (card:hasFlag("visible"))or (card:hasFlag(flag))then out[#out+1]=card end end
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
        local role=player:getRole()
        if role==nil then
            role=(self:getRoleEstimate(player))
            role=(self:useKnowledgeEstimate({value=role,status="estimate",
                basis="quanxiang:viewer_inference_replaces_foreign_private_role",
                viewer=(self.player:objectName()),observer=(player:objectName())},"quanxiang.role"))
        end
        if not ({lord=true,loyalist=true,rebel=true,renegade=true})[role] then
            ai_unsupported("Quanxiang role observation is unresolved","luaRquanxiang.role")
        end
        return role
    end
    -- The donor's local rebel rewrite is unused by the actual assignment.
    local source_role,target_role=observed_role(source),observed_role(target)
    self:emitStrategyEffect({kind="quanxiang_role",player=(target:objectName()),
        source_player=(source:objectName()),source_role=source_role,target_role=target_role})
    self:updatePlayers()
end


ai_skill_use["@@luaRshiji"]=function(self, prompt, request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	
	if (self:needBear()) then return "." end

	local selfSub = (self.player:getHp()) - (self.player:getHandcardNum())
	local selfDef = (self:getDefense(self.player))

	for _,enemy in ipairs(self.enemies) do
		local def = (self:getDefenseSlash(enemy))
		local slash = (self:getEvaluationCard("slash"))
        
		local eff = (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies,slash))
        if not (self.player:canSlash(enemy,slash,true)) then
        elseif (self:slashProhibit(nil,enemy)) then
        elseif def < 6 and eff then return response(self,"luaRshiji","#luaRshiji",{}, {enemy})

        elseif selfSub >= 2 then return "."
        elseif selfDef < 6 then return "." end
	end

	for _,enemy in ipairs(self.enemies) do
		local def=(self:getDefense(enemy))
		local slash = (self:getEvaluationCard("slash"))
        
		local eff = (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies,slash))
		if not (self.player:canSlash(enemy,slash,true)) then
		elseif (self:slashProhibit(nil,enemy)) then
		elseif eff and def < 8 then return response(self,"luaRshiji","#luaRshiji",{}, {enemy})
		else return "." end
	end
	return "."
end


sgs.ai_event_callback[sgs.Death or "Death"]=sgs.ai_event_callback[sgs.Death or "Death"]or{}
sgs.ai_event_callback[sgs.Death or "Death"].luaRquanxiang=function(self,player,event)
    for _,source in ipairs((self.room:getOtherPlayers(player)))do
        local holder=(source:hasSkill("luaRquanxiang"))
        -- A hidden hegemony general's skills are unknown, not absent.
        if not holder and (source:areSkillsComplete())~=true then ai_unsupported("Quanxiang holder skills are not public","luaRquanxiang") end
        if holder then
            local target=(self.room:findPlayerByObjectName(known(event.to,"death target"),true))
            role_effect(self,source,target)
        end
    end
end
ai_skill_invoke.luaRquanxiang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end


sgs.ai_choicemade_filter.skillInvoke.luaRquanxiang=function(self,player,promptlist)
    if promptlist[#promptlist]=="yes"then
        local damage=current_damage(self)
        if damage.to then role_effect(self,player,damage.to)end
    end
end

sgs.ai_useto_revises.luaRduxian = function(self,card,use,p)
	if (self.player:getMark("luaRduxian-PlayClear")) >= (p:getHp()) and not (self:needToLoseHp(self.player,p)) and (self.player:objectName()) ~= (p:objectName())
	then
        if not (card:isKindOf("SkillCard")) then
            return false
        end
	end
end

sgs.ai_damage_reason_suppress_intention["luaRduxian"] = true


sgs.ai_card_usage_penalty["luaRduxian"] = function(self, source, target)
    if (source:objectName()) == (target:objectName()) then
        return false 
    end
    
    for _, p in sgs.qlist((self.room:getAlivePlayers())) do
        if (p:getHp()) < 1 or (p:hasFlag("Global_Dying")) then return false end
    end

    local used_count = (target:getMark("luaRduxian-PlayClear")) + 1 -- 預判下一張
    
    -- 如果用牌數超過了妒賢擁有者的體力，則觸發懲罰
    if used_count > (source:getHp()) then
        return true
    end
    
    return false
end


sgs.ai_skill_playerchosen.luaRcaiyi = function(self,targets)
	self:sortInPlace(self.enemies, "handcard")
	self:sortInPlace(self.friends_noself, "defense")
	set_target(self,"luaRcaiyi_target",nil)
	if ((self.player:getHandcardNum())<3 and (self:getCardsNum("Peach"))==0 and (self:getCardsNum("Jink"))==0 and (self:getCardsNum("Analeptic"))==0) or
		((self.player:getHandcardNum())<=1 and (self:getCardsNum("Peach"))==0 and (self:getCardsNum("Analeptic"))==0) then
		local max_card_num = 0
		for _,enemy in ipairs(self.enemies)do
			max_card_num = math.max(max_card_num,(enemy:getHandcardNum()))
		end
		for _,enemy in ipairs(self.enemies)do
			if (enemy:getHandcardNum())==max_card_num and (enemy:getHandcardNum())>0 then
				set_target(self,"luaRcaiyi_target",enemy)
				return enemy
			end
		end
	else
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) and not (self:needKongcheng(friend,true)) then
				set_target(self,"luaRcaiyi_target",friend)
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_discard.luaRcaiyi = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new((self.player:getCards("h")))
	self:sortByCardNeedInPlace(cards, true)
	local to_discard = {}
	local half_all_card_num = math.max(1,math.floor((self.player:getHandcardNum())/2))
	for i = 1,half_all_card_num,1 do
		table.insert(to_discard,cards[i]:getEffectiveId())
	end
	return to_discard
end

ai_skill_choice.luaRcaiyi=function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items=(choices:split("+"))
    local target=get_target(self,"luaRcaiyi_target")
    if not target then local items=(choices:split("+"));return ai_choice_result((items[math.random(1,#items)]), options)end
    local ids=AIList.new(known((self:getDecisionContext()).shengrongsiai_caiyi_ids,"caiyi disclosed input IDs"))
    local shown,unshown=0,0
    local totalabs,halfexact=0,true
    for _,id in ipairs(ids)do shown=shown+(self:cardNeed(visible_card(self,id)))end
    local visible=source_visible_hand(self,target)
    local excluded={};for _,id in ipairs(ids)do excluded[id]=true end
    local observed=0
    for _,card in ipairs(visible)do
        if not excluded[(card:getKnownEffectiveId())]then
            local value=(self:cardNeed(card))
            unshown=unshown+value;totalabs=totalabs+math.abs(value);halfexact=halfexact and value*2==math.floor(value*2);observed=observed+1
        end
    end
    local hidden=(target:getHandcardNum())-#ids-observed
    if hidden<0 then ai_unsupported("caiyi shown IDs are not current target hand","luaRcaiyi")end
    unshown=unshown+hidden*.5
    -- The donor adds 0.5 for each unseen card. Grouping those additions is
    -- decision-exact outside a conservative floating point roundoff interval.
    local tolerance=((target:getHandcardNum())+#ids+2)*2.220446049250313e-16*(totalabs+hidden*.5+math.abs(shown))*2
    if hidden>0 and not(halfexact and totalabs+hidden*.5<2^50) and math.abs(shown-unshown)<=tolerance then
        ai_unsupported("caiyi hidden-order floating-point tie is unresolved","luaRcaiyi")
    end
    if shown>unshown then return ai_choice_result(("luaRcaiyi1"), options)end
    if shown<=unshown then return ai_choice_result(("luaRcaiyi2"), options)end
    return ai_choice_result((items[math.random(1,#items)]), options)
end
function ai_skill_invoke.luaRhuogen(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and (self:isFriend(target)) then
		return (not (self:isWeak())) or false
	end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.luaRhuogen = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = (self.room:findPlayerByObjectName(promptlist[#promptlist-1]))
		if target then self:updateIntention(player,target,-80) end
	end
end

local luaRsihu_skill = {}
luaRsihu_skill.name = "luaRsihu"
table.insert(package_skills,luaRsihu_skill)
luaRsihu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local card
	if (self:needToThrowArmor()) then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = (self.player:getCards("h"))
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _,hcard in ipairs(hcards)do
			if (hcard:isKindOf("Slash")) then
				if (self:getCardsNum("Slash"))>1
				then
					card = hcard
					break
				else
					local dummy_use = (self:aiUseCard(hcard,dummy()))
					if dummy_use and dummy_use.to and ((dummy_use.to:length())==0
					or (dummy_use.to:length())==1 and (self:ajustDamage(self.player,(dummy_use.to:first()),1,hcard))<2)
					then
						card = hcard
						break
					end
				end
			elseif (hcard:isKindOf("EquipCard"))
			then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = (self.player:getCards("e"))
		ecards = AIList.new(ecards)

		for _,ecard in ipairs(ecards)do
			if (ecard:isKindOf("Weapon")) or (ecard:isKindOf("OffensiveHorse")) then
				card = ecard
				break
			end
		end
	end
	if card then
		return (self:evaluateTurnSkillCard("luaRsihu","#luaRsihuCard",{(card:getKnownEffectiveId())},action_request(self,request)))
	end
end

ai_card_use["#luaRsihuCard"] = function(self, card, use, request)
	local target
	local friends = self.friends_noself
	local slash = (self:getEvaluationCard("slash"))
	set_target(self,"luaRsihuTarget",nil)

	local canluaRsihuTo = function(player)
		local canGive = not (self:needKongcheng(player,true))
		return canGive or (not canGive and (self:getEnemyNumBySeat(self.player,player))==0)
	end

	self:sortInPlace(self.enemies, "defense")
	for _,friend in ipairs(friends)do
		if canluaRsihuTo(friend) then
			for _,enemy in ipairs(self.enemies)do
				if (friend:canSlash(enemy,nil,false)) and not (self:slashProhibit(slash,enemy)) and (self:getDefenseSlash(enemy))<=2
				and (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies,slash))
				and (enemy:objectName())~=(self.player:objectName()) then
					target = friend
					set_target(self,"luaRsihuTarget",enemy)
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sortInPlace(friends, "defense")
		for _,friend in ipairs(friends)do
			if canluaRsihuTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_skill_playerchosen.luaRsihu = function(self,targets)
	local remembered=get_target(self,"luaRsihuTarget")
	if remembered then return remembered end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end


sgs.ai_use_value["luaRsihuCard"] = 5.9
sgs.ai_use_priority["luaRsihuCard"] = 4

sgs.ai_card_intention["luaRsihuCard"] = -70

ai_audited_aliases.register{id="ai_cardneed.luaRsihu",registry="ai_cardneed",path={"luaRsihu"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}

sgs.ai_skill_cardask["@luaRsihu"] = function(self, data, pattern)
    local target = data:toPlayer()
    local slash = (self:getEvaluationCard("slash"))
    local handcards = AIList.new((self.player:getCards("he")))
	local use_card = {}
	self:sortByKeepValueInPlace(handcards)
    if (self:needToLoseHp(self.player,target,slash,true)) then return "."  end
	for _,c in ipairs(handcards) do
		if (self:matchesDiscardPattern(pattern,c))
		then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return "." end
   
    if (self:getCardsNum("Jink")) == 0 then return use_card[1] end
    if (self:ajustDamage(target,self.player,1,slash))>1 then return use_card[1] end
    if (self.player:getHandcardNum())==1 and (self:needKongcheng())
    or not((self:hasLoseHandcardEffective()) or (self.player:isKongcheng())) then return use_card[1] end
    return "."
end

sgs.ai_skill_cardask["@luaRjianxiong"] = function(self,data,pattern,target)
    local target = data:toPlayer()
	local card_list = (self.player:getHandcards())
	local cards = AIList.new(card_list)
	self:sortByKeepValueInPlace(cards, false)
    for _,c in ipairs(cards) do
        if (c:hasFlag("luaRjianxiong")) then
            if not (c:targetFixed()) and not (c:isKindOf("EquipCard"))  then
                local dummy_use = (self:aiUseCard(c,dummy(true, 0, (self.room:getOtherPlayers(target)))))
                if dummy_use.card and dummy_use.to and (dummy_use.to:contains(target)) then
                    return "$"..(c:getKnownEffectiveId())
                end
            else
                if (target:objectName()) == (self.player:objectName()) then
                    local dummy_use = (self:aiUseCard(c,dummy()))
                    if dummy_use.card then
                        return "$"..(c:getKnownEffectiveId())
                    end
                end
            end
        end
    end
	return "."
end

ai_audited_aliases.register{id="ai_cardneed.luaRyaowu",registry="ai_cardneed",path={"luaRyaowu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_can_damagehp.luaRzhiyu = function(self,from,card,to)
	return (to:getHp())+(self:getAllPeachNum())-(self:ajustDamage(from,to,1,card))>0
	and (self:canLoseHp(from,card,to)) and from and (from:getHandcardNum()) - (self.player:getHandcardNum()) >= 2
end

ai_skill_invoke.luaRqice = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = (data:toCardUse())
    if (self.player:getPhase()) == sgs.Player_Play and not (self.player:isKongcheng()) then
        local cards = AIList.new((self.player:getCards("h")))
	    for _,c in sgs.list(cards)do
            if (self:willUse(self.player,c)) then
                return (false) or false
            end
        end
    end
    if use.from and (self:isFriend(use.from)) then
        if (self.player:isKongcheng()) and (self:isWeak()) then return (false) or false end
        if (use.card:isDamageCard()) or (use.card:isKindOf("SingleTargetTrick")) then
            for _,to in sgs.list(use.to)do
                if (self:isFriend(to))
                then return (false) or false end
            end
            if not (self.player:isKongcheng()) then
                local cards = AIList.new((self.player:getCards("h")))
                for _,c in sgs.list(cards)do
                    if (self:getUseValue(c)) > (self:getUseValue(use.card)) then
                        return (false) or false
                    end
                end
            end
            return (true) or false
        end
        local dummy_use = (self:aiUseCard(use.card,dummy()))
        if dummy_use.card and dummy_use.to then
            for _, p in sgs.qlist(dummy_use.to) do
                if (use.to:contains(p)) then
                    return (true) or false
                end
            end
        end
    end
	return (false) or false
end

local luaRziao_skill = {}
luaRziao_skill.name = "luaRziao"
table.insert(package_skills, luaRziao_skill)
luaRziao_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if (self:needBear()) then return end
	if #self.enemies < 1 or (self.player:isKongcheng()) then return end
	if not (self.player:isKongcheng()) then
		return seed(self,"luaRziao","#luaRziao",request)
	end
end

ai_card_use["#luaRziao"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "handcard")
	local cards = AIList.new({})
	local peach = 0
	for _, c in sgs.qlist((self.player:getHandcards())) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player,cards)
	if not max_card then return end
	local max_point = (max_card:getNumber())
	local card_str = "#luaRziao:.:"
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:isKongcheng()) and (self.player:canPindian(enemy)) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if (self:getKnownNum(enemy)) == (enemy:getHandcardNum()) then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > (enemy_max_card:getNumber()) and allknown > 0)
				or (enemy_max_card and max_point > (enemy_max_card:getNumber()) and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				self:remember("zhijian_card",(max_card:getKnownEffectiveId()))
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if (self.player:getHandcardNum()) >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:isKongcheng()) and (self.player:canPindian(enemy)) then
				local cardsq = (self.player:getHandcards())
				cardsq = AIList.new(cardsq)
				self:sortByUseValueInPlace(cardsq, true)

				local min_card = self:getMinCard()
				local enemy_min_card = self:getMinCard(enemy)
				if enemy_min_card and (min_card:getNumber()) < (enemy_min_card:getNumber()) then
					local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
					use.card = acard
					self:remember("zhijian_card",(max_card:getKnownEffectiveId()))
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	if (self.player:hasSkill("kongcheng")) and (self.player:getHandcardNum()) == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:isKongcheng()) and not (self:doDisCard(enemy,"h")) and (self.player:canPindian(enemy)) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	if zhugeliang and (self:isFriend(zhugeliang)) and (zhugeliang:getHandcardNum()) == 1 and (self.player:canPindian(zhugeliang))
		and (zhugeliang:objectName()) ~= (self.player:objectName()) and (self:getEnemyNumBySeat(self.player,zhugeliang)) >= 1 then
		if isCard("Jink", cards[1], self.player) and (self:getCardsNum("Jink")) == 1 then return end
		local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
		use.card = acard
		if use.to then use.to:append(zhugeliang) end
		return
	end

	if (self:getOverflow()) > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not (self:doDisCard(enemy,"h",true)) and not (enemy:isKongcheng()) and (self.player:canPindian(enemy)) then
				local acard = fresh_policy(self,"luaRziao","#luaRziao",{},request)
				use.card = acard
				self:remember("luaRziao_card",(max_card:getKnownEffectiveId()))
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.luaRziao(minusecard, self, requestor)
	if (requestor:getHandcardNum()) == 1 then
		local cards = AIList.new((self.player:getHandcards()))
		self:sortByKeepValueInPlace(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return (self:isFriend(requestor)) and self:getMinCard() or ((maxcard:getNumber()) < 6 and minusecard or maxcard)
end
sgs.ai_use_priority["luaRziao"]   = 5
sgs.ai_card_intention["luaRziao"] = 10
ai_audited_aliases.register{id="ai_cardneed.luaRziao",registry="ai_cardneed",path={"luaRziao"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.luaRshicai",registry="ai_cardneed",path={"luaRshicai"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}


sgs.ai_skill_playerchosen.luaRyaoyan = function(self,targets)
	targets = AIList.new(targets)
	for _,target in ipairs(targets)do
		if (self:isFriend(target)) and (target:isAlive()) then
			if (target:isWounded()) then
				return target
			end
			local zhangjiao = self.room:findPlayerBySkillName("guidao")
			if zhangjiao and (self:isFriend(zhangjiao)) then
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
luaRzhangshi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies < 1 or (self.player:getStrategyHasUsed("#luaRzhangshicard")) then return end
    if #(self.room:getLieges("qun",self.player)) < 1 then return end
	return seed(self,"luaRzhangshi","#luaRzhangshicard",request)
end


ai_card_use["#luaRzhangshicard"] = function(self, card, use, request)
	local target
	self:sortInPlace(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            target = enemy
        end
    end
	if target then
		use.card = fresh_policy(self,"luaRzhangshi","#luaRzhangshicard",{},request)
		if use.to then use.to:append(target) end
		return
	end
end
sgs.ai_use_value["luaRzhangshicard"]       = 8
sgs.ai_use_priority["luaRzhangshicard"]    = 8
sgs.ai_card_intention["luaRzhangshicard"]  = 50
ai_skill_choice["luaRzhangshi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = (choices:split("+"))
    if #(self.room:getLieges("qun",self.player)) < 1 then return ai_choice_result(("slash"), options) end
	return ai_choice_result((items[math.random(1,#items)]), options)
end


for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "hasSkill", "luaRkuangyan") and nature == "N" and dmg == 1 then
            dmg = 0
        end
        return dmg, nature
    end
    local function policy_2(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "hasSkill", "luaRkuangyan") and dmg > 1 then
            dmg = dmg + 1
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_to["luaRkuangyan"]
    sgs.ai_ajustdamage_to["luaRkuangyan"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_to" and context.rule == "luaRkuangyan_normal" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            if context.phase == "after_to" and context.rule == "luaRkuangyan_more" then
                local damage, next_nature, terminal = policy_2(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "luaRkuangyan", {
        {phase="after_to", rule="luaRkuangyan_normal", order=6500},
        {phase="after_to", rule="luaRkuangyan_more", order=6600},
    })
end)()
