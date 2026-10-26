-- Source: b6025acc ai/ck-ai.lua.
local package_skills={}
local known = AIValue.requireKnown
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return (self:legacySkillSeed(skill,class,action_request(self,request))) end
local function bind(self,skill,class,costs,request) return (self:bindSkillCard(skill,costs,action_request(self,request),nil,class)) end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function response_names(self,skill,class,names)
    local targets={}
    for _,name in ipairs(names)do targets[#targets+1]=(self.room:findPlayerByObjectName(name))end
    return response(self,skill,class,{},targets)
end
local function context(self,key) return known((self:getDecisionContext())[key],"ck.context."..key) end
local dummy = AIUsePlan.dummy
local function visible_role(self,player)
    local role=player:getRole()
    if role~=nil then return role end
    role=(self:getRoleEstimate(player))
    return (self:useKnowledgeEstimate({status="estimate",value=role,basis="viewer_role_estimate_private_role",player=(player:objectName())},"ckxueni.role"))
end
sgs.ai_ajustdamage_to.ckleiti = function(self,from,to,card,nature)
	if nature == sgs.DamageStruct_Thunder
	then return -99 end
end

sgs.ai_can_damagehp.ckleiti = function(self,from,card,to)
    if card then
        local nature = sgs.card_damage_nature[(card:getClassName())] or sgs.DamageStruct_Normal
        if nature == sgs.DamageStruct_Thunder
        then
            return true
        end
    end
end

local ckdianji_skill = {}
ckdianji_skill.name= "ckdianji"
table.insert(package_skills,ckdianji_skill)
ckdianji_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

    if not (self.player:canDiscard(self.player,"he")) then return end
	return seed(self,"ckdianji","#ckdianjicard",request)
end

ai_card_use["#ckdianjicard"] = function(self, card, use, request)
	local cards = AIList.new((self.player:getCards("he")))
	self:sortByKeepValueInPlace(cards)
    self:sortInPlace(self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if (self:objectiveLevel(enemy))>3 and not (self:cantbeHurt(enemy)) and (self:damageIsEffective(enemy,sgs.DamageStruct_Thunder,self.player)) and (self:canDamage(enemy,self.player,nil)) then
            use.card = bind(self,"ckdianji","#ckdianjicard",{(cards[1]:getKnownEffectiveId())},request)
            use.to:append(enemy)
            return
        end
    end
    if (self.player:getHp())<getBestHp(self.player) and (self.player:hasSkill("ckleiti")) then
        use.card = bind(self,"ckdianji","#ckdianjicard",{(cards[1]:getKnownEffectiveId())},request)
        use.to:append(self.player)
        return
    end
    local target = self:findBestDamageTarget(1,"T",0,nil)
    if target then
        use.card = bind(self,"ckdianji","#ckdianjicard",{(cards[1]:getKnownEffectiveId())},request)
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["ckdianjicard"] = 2.5
sgs.ai_card_intention["ckdianjicard"] = 80
sgs.dynamic_value.damage_card["ckdianjicard"] = true


local ckluolei_skill = {}
ckluolei_skill.name = "ckluolei"
table.insert(package_skills, ckluolei_skill)
ckluolei_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:getMark("@thunder")) <= 0 then return end
	if (self.room:getMode()) == "_mini_13" then return nil -- Fixed Card_Parse has no ck luolei prototype (no alias repair).
    end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and (self:isWeak(lord)) then return end
	for _, player in sgs.qlist((self.room:getOtherPlayers(self.player))) do
		if (self:isWeak(player)) then
			if (self:isFriend(player)) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist((self.room:getOtherPlayers(self.player))) do
		local hp = math.max((player:getHp()), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if (self:isFriend(player)) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		if (self:damageIsEffective(player,sgs.DamageStruct_Thunder,self.player)) then
			local lost_value = 0
			if (self:hasSkills(sgs.masochism_skill,player)) then lost_value = (player:getHp())/2 end
			local hp = math.max((player:getHp()), 1)
			if (self:isFriend(player)) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad and (self:isWeak()) and self:getHandcardNum() < 4 then return seed(self,"ckluolei","#ckluoleicard",request) end
end

ai_card_use["#ckluoleicard"]=function(self, card, use, request)
	use.card = (self:inheritLegacyCardIdentity(bind(self,"ckluolei","#ckluoleicard",{},request),card))
end

sgs.dynamic_value.damage_card["#ckluoleicard"] = true

local cksilie_skill = {}
cksilie_skill.name = "cksilie"
table.insert(package_skills,cksilie_skill)
cksilie_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:isKongcheng()) then return nil end
	return seed(self,"cksilie","#cksiliecard",request)
end

ai_card_use["#cksiliecard"] = function(self, card, use, request)
	local cards = AIList.new((self.player:getHandcards()))
	self:sortByUseValueInPlace(cards, true)
	self:sortInPlace(self.enemies, "defense")
	if (self:getOverflow())<=0 then return end
	self:setPriorityValue("cksiliecard",0.2,"ck.cksilie")
	local suit_table = { "spade","club","heart","diamond" }
	local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
	for _,enemy in ipairs(self.enemies)do
		if (enemy:getHandcardNum())>2 and (self:objectiveLevel(enemy))>3 and not (self:cantbeHurt(enemy)) and (self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player)) and (self:canDamage(enemy,self.player,nil)) then
			local max_suit_num,max_suit = 0,{}
			for i = 0,3,1 do
				local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
				for j = 0,4,1 do
					if enemy:getEquip(j) and (enemy:getEquip(j):getSuit())==i then
						local val = equip_val_table[j+1]
						if j==1 and (self:needToThrowArmor(enemy)) then val = -0.5
						else
							if (enemy:hasSkills(sgs.lose_equip_skill)) then val = val/8 end
							if (enemy:getEquip(j):getKnownEffectiveId())==self:getValuableCard(enemy) then val = val*1.1 end
							if (enemy:getEquip(j):getKnownEffectiveId())==self:getDangerousCard(enemy) then val = val*1.1 end
						end
						suit_num = suit_num+j
					end
				end
				if suit_num>max_suit_num then
					max_suit_num = suit_num
					max_suit = { i }
				elseif suit_num==max_suit_num then
					table.insert(max_suit,i)
				end
			end
			if max_suit_num==0 then
				max_suit = {}
				local suit_value = { 1,1,1.3,1.5 }
				for _,skill in ipairs(sgs.getPlayerSkillList(enemy))do
					if sgs[(skill:objectName()).."_suit_value"] then
						for i = 1,4,1 do
							local v = sgs[(skill:objectName()).."_suit_value"][suit_table[i]]
							if v then suit_value[i] = suit_value[i]+v end
						end
					end
				end
				local max_suit_val = 0
				for i = 0,3,1 do
					local suit_val = suit_value[i+1]
					if suit_val>max_suit_val then
						max_suit_val = suit_val
						max_suit = { i }
					elseif suit_val==max_suit_val then
						table.insert(max_suit,i)
					end
				end
			end
			for _,card in ipairs(cards)do
				if (self:getUseValue(card))<6 and table.contains(max_suit,(card:getSuit())) then
					use.card = bind(self,"cksilie","#cksiliecard",{(card:getKnownEffectiveId())},request)
					use.to:append(enemy)
					return
				end
			end
			if getCardsNum("Peach",enemy,self.player)<2 then
				for _,card in ipairs(cards)do
					if (self:getUseValue(card))<6 and not (self:isValuableCard(card)) then
						use.card = bind(self,"cksilie","#cksiliecard",{(card:getKnownEffectiveId())},request)
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["cksiliecard"] = 60

sgs.ai_use_priority["cksiliecard"] = 0.2

ai_skill_use["@@ckbaihe"] = function(self, prompt, request)
    self:sortInPlace(self.friends, "defense")
    for _,friend in ipairs(self.friends)do
        if (self:doDisCard(friend,"e")) then
            return response(self,"ckbaihe","#ckbaihecard",{}, {friend})
        end
    end
    for _,friend in ipairs(self.friends)do
        if (friend:hasEquip()) and (self.player:canDiscard(friend,"e")) and (self:isWeak(friend)) then
            return response(self,"ckbaihe","#ckbaihecard",{}, {friend})
        end
    end
	return "."
end

sgs.ai_ajustdamage_from.ckdalian = function(self,from,to,card,nature)
	if from and (from:distanceTo(to))<=1 and not beFriend(to,from)
	then return 1 end
end

ai_skill_invoke.ckdalian = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target and (self:isFriend(target)) then return (false) or false end
	return (true) or false
end

sgs.ai_target_revises.ckhuansha = function(to,card)
	if (card:getTypeId())==sgs.Card_TypeSkill or (card:getKnownSkillName())~="" or (card:isVirtualCard()) or (card:isKindOf("SkillCard"))
	then return true end
end
sgs.ai_target_revises.ckshiliang = function(to,card)
	if (to:getMark("ckshiliang-Clear")) == 0
	then return true end
end

ai_skill_use["@@ckshiliang"] = function(self, prompt, request)
    local parsed = (prompt:split(":"))
    local use = context(self,"use")
    if parsed[1]=="@ckshiliangCard" then
        if use then
            local card = use.card
            local dummy_use = (self:aiUseCard(card,dummy(true, 0, use.to)))
			if dummy_use.card and dummy_use.to then
                for _,p in sgs.qlist(dummy_use.to)do
                    return response(self,"ckshiliang","#ckshiliangcard",{}, {p})
                end
            end
        end
    else
        if use.from and (self:isEnemy(use.from)) then
            for _, enemy in ipairs(self.enemies) do
                return response(self,"ckshiliang","#ckshiliangcard",{}, {enemy})
            end
        end
	end
	return "."
end

ai_skill_invoke.ckxueni = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target  then 
        if (self:isEnemy(target)) then
			return (true) or false
		end
        if (self:isFriend(target)) and visible_role(self,target) == "rebel" then
			for _, friend in ipairs(self.friends) do
				if getKnownCard(friend, self.player, "Peach", true, "h") > 0 then return (false) or false end
				if (friend:getHandcardNum()) > 3 then return (false) or false end
			end
            return (true) or false
		end
    end
    return (false) or false
end

ai_skill_invoke.ckyongchang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local effect = context(self,"effect")
    local dest = effect.to
    if dest and (self:isEnemy(dest)) then return (false) or false end
	if effect.card and (effect.card:hasFlag("NosJiefanUsed")) then return (false) or false  end

	if not effect.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)
		or (effect.card:isKindOf("NatureSlash")) and (self.player:isChained()) and (self:isGoodChainTarget(dest,effect.card,effect.from))
		or (self:needToLoseHp(dest,effect.from,effect.card)) and (self:ajustDamage(effect.from,dest,1,effect.card))==1 then return (false) or false end
	if (self:needToLoseHp(dest,effect.from,effect.card,true,true)) then return (false) or false end
	if (self:getCardsNum("Jink")) == 0 then return (true) or false end
	
	return (true) or false
end

sgs.ai_choicemade_filter.skillInvoke.ckyongchang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player,target,-50) end
	end
end

local cklongxi_skill = {}
cklongxi_skill.name= "cklongxi"
table.insert(package_skills,cklongxi_skill)
cklongxi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return seed(self,"cklongxi","#cklongxicard",request)
end

ai_card_use["#cklongxicard"] = function(self, card, use, request)
	local cards = AIList.new((self.player:getCards("he")))
	self:sortByKeepValueInPlace(cards)
    self:sortInPlace(self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if (self:objectiveLevel(enemy))>3 and not (self:cantbeHurt(enemy)) and (self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player)) and not (self:cantDamageMore(self.player,enemy)) and ((enemy:getHp()) <= 3 or (self:isWeak())) and (self:canDamage(enemy,self.player,nil)) then
            use.card = bind(self,"cklongxi","#cklongxicard",{},request)
            use.to:append(enemy)
            return
        end
    end
    local target = self:findBestDamageTarget(3,"N",0,nil)
    if target then
        use.card = bind(self,"cklongxi","#cklongxicard",{},request)
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["cklongxicard"] = 2.5
sgs.ai_card_intention["cklongxicard"] = 80
sgs.dynamic_value.damage_card["cklongxicard"] = true

ai_audited_aliases.register{id="ai_cardneed.ckqishan",registry="ai_cardneed",path={"ckqishan"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_canliegong_skill.ckqishan = function(self, from, to)
	return true
end

local ckweishan_skill = {}
ckweishan_skill.name= "ckweishan"
table.insert(package_skills,ckweishan_skill)
ckweishan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return seed(self,"ckweishan","#ckweishancard",request)
end

ai_card_use["#ckweishancard"] = function(self, card, use, request)
	local cards = AIList.new((self.player:getCards("he")))
	self:sortByKeepValueInPlace(cards)
    self:sortInPlace(self.enemies)
    local use_cards = {}
    local types = {}
    
	for _,c in ipairs(cards) do
		if not table.contains(types, (c:getTypeId()))  then
            table.insert(types, (c:getTypeId()))
            table.insert(use_cards, (c:getKnownEffectiveId()))
		end
	end
    if #use_cards < 3 then return end

	local enemies = (self:findPlayerToDamage(3,self.player,"N"))
	enemies = table.filter(enemies, function(p) return not (self:cantDamageMore(self.player,p)) end)
	for _,enemy in ipairs(enemies) do
		use.card = bind(self,"ckweishan","#ckweishancard",use_cards,request)
        use.to:append(enemy)
        return
	end
    local target = self:findBestDamageTarget(3,"N",0,nil)
    if target then
        use.card = bind(self,"ckweishan","#ckweishancard",use_cards,request)
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["ckweishancard"] = 2.5
sgs.ai_card_intention["ckweishancard"] = 80
sgs.dynamic_value.damage_card["ckweishancard"] = true

ai_skill_use["@@ckjinjie"] = function(self, prompt, request)
    local targets = {}
    table.insert(targets, (self.player:objectName()))
    self:sortInPlace(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if #targets < 3 then
            table.insert(targets, (friend:objectName()))
            break
        end
    end
    self:sortInPlace(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 and not (self.player:inMyAttackRange(enemy)) then
            table.insert(targets, (enemy:objectName()))
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 then
            table.insert(targets, (enemy:objectName()))
        end
    end
    if #targets > 0 then
        return response_names(self,"ckjinjie","#ckjinjieCard",targets)
    end
    return "."
end
for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["ckhuansha"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","ckhuansha") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["ckhuansha"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "ckhuansha" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "ckhuansha", {
        {phase="need_hp_before_damage", order=1, rule="ckhuansha"},
    })
end)()
end
