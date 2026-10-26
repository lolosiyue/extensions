-- Source: b6025acc ai/biaofengold-ai.lua.
local package_skills={}
local known = AIValue.requireKnown

local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local function bind(self,skill,class,costs,request) return self:bindSkillCard(skill, costs, action_request(self,request), nil, class) end
local skill_cards={
 ["#FiveFanjian_Card"]="FiveFanjian",["#FiveHuangtianA_Card"]="FiveHuangtianA_Qun",["#FiveGuidaoA_Card"]="FiveGuidaoA",
 ["#FourJiaozhao_Card"]="FourJiaozhao",["#FourHuoji_Card"]="FourHuoji",["#FourFanjian_Card"]="FourFanjian",
 ["#FourTianxiang_Card"]="FourTianxiang",["#FourTaiping_Card"]="FourTaiping_Others",["#DiyXX_Card"]="DiyXX",
 ["#FiveLeiji_Card"]="FiveLeiji",["#FourNiepan_Card"]="FourNiepan",["#FourJianxiong_Card"]="FourJianxiong"}
local conversion_classes={slash="Slash",analeptic="Analeptic",dismantlement="Dismantlement"}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),"biaofengold disclosed material")end
local function material(card,name,skill)return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}end
local function wire_parts(wire)
 local class,raw=wire:match("^(#[^:]+):([^:]*):$")
 if not class then return end
 local ids={};for value in raw:gmatch("%d+")do ids[#ids+1]=tonumber(value)end
 return class,ids
end
local function parse(self,request,wire)
 local class,costs=wire_parts(wire)
 if class then
  local skill=known(skill_cards[class],"source SkillCard class")
  if #costs==0 then return seed(self,skill,class,request)end
  return self:evaluateTurnSkillCard(skill, class, costs, action_request(self,request))
 end
 local name,skill,id=wire:match("^([^:]+):([^%[]+)%[[^%]]+%]=(%d+)$")
 if not name then ai_unsupported("unsupported source card grammar",wire)end
 local spec=material(disclosed(self,tonumber(id)),name,skill)
 return self:evaluateTurnConversion(skill, known(conversion_classes[name],name), spec, action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs=wire_parts(wire)
 if not class then ai_unsupported("unexpected source final card",wire)end
 return bind(self,known(skill_cards[class],class),class,costs,request)
end
local function response(self,class,costs,targets)
 local use=AIUsePlan.new();use.card=bind(self,known(skill_cards[class],class),class,costs,nil);use.to=AIList.new(targets)
 return use:toAnswer()
end
local dummy = AIUsePlan.dummy
local function residue(self,name)return (known(self:getEvaluationCard(name),name)):getTargetModResidue()end
local function current_damage(self)
 local context=self:getDecisionContext();local raw=known(context.damage,"CurrentDamageStruct")
 return raw
end
local function role(self,p)
 local value=p:getRole();if value~=nil then return value end
 return self:useKnowledgeEstimate({status="estimate",value=self:getRoleEstimate(p),basis="viewer_role_estimate_private_role",player=p:objectName()}, "FourJianxiong.role")
end
local function public_flag(self,player,name)
 -- Room::setPlayerFlag broadcasts, so every player's flags are projected.
 return player:hasFlag(name)
end
local function source_visible_hand(self,p)
 -- Another player's known cards are the hand cards this viewer may see, in hand
 -- order; the visible-flag subset of the viewer's own hand is not projected.
 if p:objectName()==self.player:objectName() then
  ai_unsupported("own visible-flag hand subset is not projected","source visible hand order")
 end
 return p:getKnownCards()
end
local function aoe_truth(self)
 -- sgs.ai_AOE_data is written only by the original-hegemony AI; elsewhere it stays nil.
 local h=AIHegemony.facts(self.world)
 if type(h)~="table" or type(h.enabled)~="boolean" then ai_unsupported("hegemony load domain unknown","FourGuidao") end
 if not(h.enabled and h.original_overrides_loaded==true) then return false end
 ai_unsupported("original hegemony AOE stack is not projected","FourGuidao")
end

function sgs.ai_cardneed.FiveYingzhan(to, card, self)
	if to:getMark("FiveYingzhan") == 0 then
        return card:isKindOf("FireSlash") or card:isKindOf("FireAttack") or card:isKindOf("Fan")
    end
end

local FiveFanjian_skill = {}
FiveFanjian_skill.name = "FiveFanjian"
table.insert(package_skills, FiveFanjian_skill)
FiveFanjian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#FiveFanjian_Card") or self.player:isKongcheng() then return end
	if self:needBear() then return end
	local parsed_card = parse(self,request,"#FiveFanjian_Card:.:")
	return parsed_card
end

ai_card_use["#FiveFanjian_Card"] = function(self, card, use, request)
    local use_card
    if not use_card then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Heart and not hcard:isKindOf("Peach") then
				use_card = hcard
				break
			end
		end
	end
    if not use_card then return end
	local count = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then count = count + 1 end
	end
	if count >= 1 and #self.enemies > 1 then
		self:sortInPlace(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (hasManjuanEffect(enemy) ) and not hasTuntianEffect(enemy, true) then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sortInPlace(self.friends_noself, "defense")
		self.friends_noself = sgs.reverse(self.friends_noself)
		if count < 1 then return end
		for _, friend in ipairs(self.friends_noself) do
			if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and not self:isWeak(friend) then
				target = friend
				break
			end
		end
		if not target then
			for _, friend in ipairs(self.friends_noself) do
				if not hasManjuanEffect(friend) then
					target = friend
					break
				end
			end
		end
	end
	if target then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
				and not self:needToLoseHp(self.player) then
					use.card = acard
					return
			end
		end
		use.card = final_parse(self,request,"#FiveFanjian_Card:"..use_card:getKnownId()..":")
		if use.to then
			self:setStrategyPlayerFlag(target, "AI_FiveFanjianTarget", true)
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["#FiveFanjian_Card"] = 1.5
sgs.ai_card_intention["#FiveFanjian_Card"] = 0
sgs.ai_playerchosen_intention.FiveFanjian = 10

sgs.ai_skill_playerchosen.FiveFanjian = function(self, targets)
	self:sortInPlace(self.enemies, "defense")
	local slash = self:getEvaluationCard("slash")
	
	local from
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:hasStrategyPlayerFlag(player, "AI_FiveFanjianTarget") then
			from = player
			self:setStrategyPlayerFlag(from, "AI_FiveFanjianTarget", false)
			break
		end
	end
	if from then
		for _, to in ipairs(self.enemies) do
			if targets:contains(to) and self:slashIsEffective(slash, to, from) and self:isGoodTarget(to, self.enemies, slash)	and not self:needToLoseHp(to, from, slash, true) and not self:findLeijiTarget(to, 50, from) then
				return to
			end
		end
	end
	for _, to in ipairs(self.enemies) do
		if targets:contains(to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.FiveFanjian(minusecard, self, requestor, maxcard)
	local req
	if self.player:objectName() == requestor:objectName() then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if public_flag(self,p,"FiveFanjianPindianTarget") then
				req = p
				break
			end
		end
	else
		req = requestor
	end
	local cards, maxcard = AIList.new(self.player:getHandcards())
	local max_value = 0
	self:sortByKeepValueInPlace(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a, b)
		return a:getNumber() > b:getNumber()
	end
	local function compare_func2(a, b)
		return a:getNumber() < b:getNumber()
	end
	if self:isFriend(req) and self.player:getHp() > req:getHp() then
		table.sort(cards, compare_func2)
	else
		table.sort(cards, compare_func1)
	end
	for _, card in ipairs(cards) do
		if max_value > 7 or self:getKeepValue(card) < 7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

local FiveHuangtianA_Qun_skill = {}
FiveHuangtianA_Qun_skill.name = "FiveHuangtianA_Qun"
table.insert(package_skills, FiveHuangtianA_Qun_skill)
FiveHuangtianA_Qun_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasFlag("ForbidFiveHuangtianA") then return nil end
	if self.player:getKnownKingdom() ~= "qun" then return nil end

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	local card
	self:sortByUseValueInPlace(cards, true)
	for _,acard in ipairs(cards)  do
		if acard:isRed() then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getKnownEffectiveId()
	local card_str = "#FiveHuangtianA_Card:"..card_id..":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

ai_card_use["#FiveHuangtianA_Card"] = function(self, card, use, request)
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("FiveHuangtianA") then
			if not friend:hasFlag("FiveHuangtianAInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sortInPlace(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("FiveHuangtianA") then
				if not enemy:hasFlag("FiveHuangtianAInvoked") then
					if not hasManjuanEffect(enemy) then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:getStrategyHasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:getStrategyHasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sortInPlace(targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
								use.card = card
								self:setStrategyPlayerFlag(enemy, "AI_HuangtianPindian", true)
								if use.to then
									use.to:append(enemy)
								end
								break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["#FiveHuangtianA_Card"] = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:getStrategyHasUsed("TianyiCard"))
								or (from:hasSkill("xianzhen") and not from:getStrategyHasUsed("XianzhenCard"))) then
	else
		self:updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority["#FiveHuangtianA_Card"] = 10
sgs.ai_use_value["#FiveHuangtianA_Card"] = 8.5

ai_skill_invoke.FiveGuidaoA = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

local FiveGuidaoA_skill = {}
FiveGuidaoA_skill.name= "FiveGuidaoA"
table.insert(package_skills,FiveGuidaoA_skill)
FiveGuidaoA_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getPile("dao"):length() >= 3 then
		return parse(self,request,"#FiveGuidaoA_Card:.:")
	end
end

ai_card_use["#FiveGuidaoA_Card"] = function(self, card, use, request)
    local to_use = {}
    local cards = {}
	if self.player:getPile("dao"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("dao")) do
            table.insert(cards ,disclosed(self,id))
        end
    end
	self:sortByKeepValueInPlace(cards)
	
    for _,c in ipairs(cards) do
        if #to_use < 3 then
			table.insert(to_use, c:getKnownEffectiveId())
		end
    end
    if #to_use == 3  then
    
        self:updatePlayers()
        self:sortInPlace(self.enemies, "hp")
        for _,enemy in ipairs(self.enemies) do
            if not enemy:hasArmorEffect("SilverLion")  and
                self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and self:canDamage(enemy, self.player, nil) then
                use.card = final_parse(self,request,"#FiveGuidaoA_Card:" .. table.concat(to_use, "+").. ":")
                if use.to then
                    use.to:append(enemy)
                end
                return
            end
        end
        
        for _,enemy in ipairs(self.enemies) do
            if not enemy:hasSkill("hongyan")
             and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) then
                use.card = final_parse(self,request,"#FiveGuidaoA_Card:" .. table.concat(to_use, "+").. ":")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
        end
	end
end

sgs.ai_use_value["#FiveGuidaoA_Card"] = 2.5
sgs.ai_card_intention["#FiveGuidaoA_Card"] = 80
sgs.dynamic_value.damage_card["#FiveGuidaoA_Card"] = true

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|FiveGuidaoA"

sgs.ai_hasTuntianEffect_skill.FiveGuidaoA = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive and to:getPile("dao"):length() < 5
end

ai_skill_invoke.FiveGuidaoB = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = self.room:getCurrent()
    if target:objectName() == self.player:objectName() then
        local zhangjiao = data:toPlayer()
        if zhangjiao and self:isFriend(zhangjiao) then
            return (self:doDisCard(zhangjiao, "h")) or false
        else
            return (self:doDisCard(zhangjiao, "h")) or false
        end
    else
        if (self:isEnemy(target) and not target:isChained()) or (self:isFriend(target) and target:isChained()) or (target:getKnownKingdom() == "qun" and not target:isChained() and self.player:hasLordSkill("FiveHuangtianB")) then
            return (true) or false
        end
    end
	return (false) or false
end

ai_skill_choice.FiveGuidaoB = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

local items = choices:split("+")
local target = self.room:getCurrent()
	
	if target and self:isFriend(target) and not self.player:hasLordSkill("FiveHuangtianB") and target:getKnownKingdom() == "qun" then
		return ai_choice_result(("FiveGuidaoB_Reset"), options)
	end	
	if target and self:isEnemy(target)  then
		return ai_choice_result(("FiveGuidaoB_Chain"), options)
	end
	return ai_choice_result(("FiveGuidaoB_Chain"), options)
end

ai_skill_use["@FiveLeiji"]=function(self, prompt, request)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers();
		for _,aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return response(self,"#FiveLeiji_Card",{}, {aplayer})
			end
		end
	end

	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("SilverLion")  and
			self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and self:canDamage(enemy, self.player, nil) then
			return response(self,"#FiveLeiji_Card",{}, {enemy})
		end
	end
	
	for _,enemy in ipairs(self.enemies) do
		if not enemy:hasSkill("hongyan")
		 and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) then
			return response(self,"#FiveLeiji_Card",{}, {enemy})
		end
	end
	
	return "."
end

sgs.ai_card_intention["#FiveLeiji_Card"] = 80

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|FiveLeiji"

sgs.ai_hasTuntianEffect_skill.FiveLeiji = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_skill_playerchosen.FiveHuangtianB = function(self, targets)
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	if self.player:getKnownRole() == "renegade" then
		self:updateIntention(self.player, self.room:getLord(), 50)
	end
	return nil
end

sgs.ai_playerchosen_intention.FiveHuangtianB = -50

ai_skill_use["@FourJianxiong"] = function(self, prompt, request)
	local damage = current_damage(self)
	local dest = damage.to
	if not self:isEnemy(dest) then return "." end
	local target
	
    if dest:getHp() <= 1 then
        if role(self,dest) == "rebel" and self:getOverflow() then
            for _,friend in ipairs(self.friends_noself) do
                if friend then
                    if not self:hasJueqingEffect(friend, dest, damage.nature) then
                        target = friend
                    end
                end
            end
        elseif role(self,dest) == "loyalist" then
            local lord = self.room:getLord()
            if self:isEnemy(lord) then
                target = lord
            end
        end
    end

    if not target then
        if self:hasSkills(sgs.masochism_skill, dest) then
            self:sortInPlace(self.enemies, "defense")
            for _,enemy in ipairs(self.enemies) do
                if enemy then
                    target = enemy
                end
            end
        end
    end
	
	local discard_cards =  {}
	
    for _, id in sgs.qlist(self.player:getCards("h")) do
        if id:getSuit() == sgs.Card_Spade then
            table.insert(discard_cards, id)
        end
    end
    if target and #discard_cards > 0 then return response(self,"#FourJianxiong_Card",{discard_cards[1]:getEffectiveId()}, {target})    end
	return "."
end

ai_skill_choice.FourJianxiong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local damage = data:toDamage()
	if not damage.card then return ai_choice_result(("FourJianxiong_choice2"), options) end
	if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self.player:getLostHp() > 1 and self:getCardsNum("Slash") > 0 then return ai_choice_result(("FourJianxiong_choice2"), options) end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then return ai_choice_result(("FourJianxiong_choice2"), options) end
	local items = choices:split("+")
	if table.contains(items, "FourJianxiong_choice1") then return ai_choice_result(("FourJianxiong_choice1"), options) end
	return ai_choice_result((items[1]), options)
end

ai_audited_aliases.register{id="ai_target_revises.FourJianxiong",registry="ai_target_revises",path={"FourJianxiong"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=1,defer_canonical=true}

sgs.ai_can_damagehp.FourJianxiong = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return card:isKindOf("Duel") or card:isKindOf("AOE") or to:getLostHp() > 2
	end
end

local FourJiaozhao_skill = {}
FourJiaozhao_skill.name = "FourJiaozhao"
table.insert(package_skills, FourJiaozhao_skill)
FourJiaozhao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getMark("@jiaozhao") == 0 then return end

	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("Peach") then
				card = hcard
			end
		end
	end
	if card then
		card = parse(self,request,"#FourJiaozhao_Card:" .. card:getKnownEffectiveId()..":")
		return card
	end

	return nil
end

ai_card_use["#FourJiaozhao_Card"] = function(self, card, use, request)
	local lord = self.room:getLord()
	if lord then
		for _,skill in sgs.qlist(lord:getVisibleSkillList()) do
			if skill:isLordSkill() then
				use.card = card
				if use.to then
					use.to:append(lord)
				end
			end
		end
	end
end

ai_skill_invoke.FourFenyong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.room:getTurnCount() <= 1 and #self.enemies == 0 then return false end

	local current = self.room:getCurrent()
	if not current or current:getPhase() >= sgs.Player_Finish then return (true) or false end
	if self:isFriend(current) then
		return (false) or false
	end

	return (true) or false
end

function sgs.ai_slash_prohibit.FourFenyong(self, from, to)
	if self:hasJueqingEffect(from, to) or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	return not to:faceUp() and to:hasSkill("FourFenyong")
end

sgs.ai_need_damaged.FourFenyong = function (self, attacker, player)
	if not player:hasSkill("FourFenyong") then return false end
	if not player:hasSkill("FourXuehen") then return false end
    local enemy = self.room:getCurrent()
    if self:isEnemy(enemy) then
		local def = self:getDefenseSlash(enemy)
		local slash = self:getEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy)

		if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and eff and def < 6 then
			return true
		end
	end
	return false
end
sgs.ai_ajustdamage_to.FourFenyong = function(self, from, to, card, nature)
	if to and not to:faceUp() then
		return -99
	end
end

ai_skill_invoke.FourXuehen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = self.room:getCurrent()
    if self:isEnemy(current) then
        local def = self:getDefenseSlash(current)
        local slash = self:getEvaluationCard("slash")
        local eff = self:slashIsEffective(slash, current) and self:isGoodTarget(current, self.enemies, slash)

        if self.player:canSlash(current, nil, false) and not self:slashProhibit(nil, current) and eff and def < 6 then
            return (true) or false
        end
    end
	return (false) or false
end

sgs.ai_view_as.FourWusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id)) then
        if card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return material(card,"slash","FourWusheng")
        elseif card:isBlack() and not card:hasFlag("using") then
        return material(card,"analeptic","FourWusheng")
        end
	end
    
end

local FourWusheng_skill = {}
FourWusheng_skill.name = "FourWusheng"
table.insert(package_skills, FourWusheng_skill)
FourWusheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local red_card
	local black_card
	self:sortByUseValueInPlace(cards, true)

	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self:sortInPlace(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self:sortInPlace(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") and not self.player:hasFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				nuzhan_trick_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or residue(self,"slash") > 0)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end

	if nuzhan_equip then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard")then
				red_card = card
				break
			end
		end
	end
    
    for _, card in ipairs(cards) do
		if card:isBlack() and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Analeptic or inclusive or residue(self,"Analeptic") > 0) then
			black_card = card
			break
		end
	end
    if black_card and self:getCardsNum("Slash") > 0 then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getKnownEffectiveId()
		local card_str = ("analeptic:FourWusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)
		return slash
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getKnownEffectiveId()
		local card_str = ("slash:FourWusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)
		return slash
	end

end

function sgs.ai_cardneed.FourWusheng(to, card)
	return to:getHandcardNum() < 3 and card:isRed()
end

sgs.ai_skill_playerchosen.FourYijue = function(self, targets)
	targets = AIList.new(targets)
	for _,target in sgs.list(targets)do
		if self:isFriend(target) then
			return self:doDisCard(target, "ej")
		end
	end
	for _,target in sgs.list(targets)do
		if self:isEnemy(target) then
			return self:doDisCard(target, "hej")
		end
	end
	for _,target in sgs.list(targets)do
		return self:doDisCard(target, "hej")
	end
    return targets[1]
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.FourYijue",registry="ai_choicemade_filter",path={"cardChosen","FourYijue"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}

local FourHuoji_skill={}
FourHuoji_skill.name="FourHuoji"
table.insert(package_skills,FourHuoji_skill)
FourHuoji_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#FourHuoji_Card") then return nil end
	local cards = self.player:getCards("h")
	cards=AIList.new(cards)

	local card

	self:sortByUseValueInPlace(cards, true)

	for _,acard in ipairs(cards) do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = self:aiUseCard(acard, dummy())
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then self:setPriorityValue("Slash", self:getPriorityValue("FireAttack")+0.1, "FourHuoji")
				else
					self:setPriorityValue("Slash", 2.6, "FourHuoji")
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	
    return parse(self,request,"#FourHuoji_Card:"..card:getKnownEffectiveId() ..":")
end

ai_card_use["#FourHuoji_Card"] = function(self, card, use, request)
	local fire_attack = self:evaluateOwnerViewAsCard({source_key="FourHuoji",skill="",name="fire_attack",suit=card:getSuit(),number=card:getNumber(),subcards={}})
	local dummy_use = self:aiUseCard(fire_attack, dummy())
    if dummy_use.card and dummy_use.to:length() > 0 then
        use.card = card
        if use.to then use.to:append(dummy_use.to:first()) end
        return
    end
end

sgs.ai_cardneed.FourHuoji = function(to, card, self)
	return to:getHandcardNum() >= 2 and card:isRed()
end

ai_skill_invoke.FourNiepan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()

	return (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches) or false
end

ai_skill_use["@FourNiepan"]=function(self, prompt, request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("SilverLion")  and
			self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:isChained() and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and self:canDamage(enemy, self.player, nil) then
			return response(self,"#FourNiepan_Card",{}, {enemy})
		end
	end
	
	for _,enemy in ipairs(self.enemies) do
		if enemy:isChained() and not ( not self:isGoodChainTarget(enemy)) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			return response(self,"#FourNiepan_Card",{}, {enemy})
		end
	end
	
	return "."
end

sgs.ai_canNiepan_skill.FourNiepan = function(player)
	return player:getMark("@Four_nirvana")>0
end

local FourFanjian_skill = {}
FourFanjian_skill.name = "FourFanjian"
table.insert(package_skills, FourFanjian_skill)
FourFanjian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return nil end
	if self.player:getStrategyHasUsed("#FourFanjian_Card") then return nil end
	return parse(self,request,"#FourFanjian_Card:.:")
end

ai_card_use["#FourFanjian_Card"]=function(self, card, use, request)

	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	
	self:sortInPlace(self.enemies, "hp")

	if self:getCardsNum("Slash") > 0 then
		local slash = self:getCard("Slash")
		local dummy_use = { isDummy = true, to = AIList.new({}) }
		self:useCardSlash(slash, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			self:setPriorityValue("#FourFanjian_Card", self:getPriorityValue("Slash")+0.15, "FourFanjian")
			local target = dummy_use.to:first()
			if self:isEnemy(target) and getCardsNum("Jink",target,self.player)>0 and target:getMark("yijue") == 0
				and not target:isKongcheng() and (self:getOverflow() > 0 or target:getHandcardNum() > 2)
				and not (self.player:hasSkill("liegong") and (target:getHandcardNum() >= self.player:getHp() or target:getHandcardNum() <= self.player:getAttackRange()))
				and not (self.player:hasSkill("kofliegong") and target:getHandcardNum() >= self.player:getHp()) then
				if target:hasSkill("qingguo") then
					for _, card in ipairs(cards) do
						if self:getUseValue(card) < 6 and card:isBlack() and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
							use.card = final_parse(self,request,"#FourFanjian_Card:" .. card:getKnownEffectiveId()..":")
							if use.to then use.to:append(target) end
							return
						end
					end
				end
				for _, card in ipairs(cards) do
					if self:getUseValue(card) < 6 and card:getSuit() == sgs.Card_Diamond and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
						use.card = final_parse(self,request,"#FourFanjian_Card:" .. card:getKnownEffectiveId()..":")
						if use.to then use.to:append(target) end
						return
					end
				end
			end
		end
	end

	if self:getOverflow() <= 0 then return end
	self:setPriorityValue("#FourFanjian_Card", 0.2, "FourFanjian")

	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[c:getSuitString()] then
			suits[c:getSuitString()] = true
			suits_num = suits_num + 1
		end
	end

	local wgt = self.room:findPlayerBySkillName("buyi")
	if wgt and self:isFriend(wgt) then wgt = nil end

	for _, enemy in ipairs(self.enemies) do
		
		if self:canAttack(enemy) and not enemy:hasSkills("qingnang|jijiu|tianxiang")
			and not (wgt and card:getTypeId() ~= sgs.Card_Basic and (enemy:isKongcheng() or enemy:objectName() == wgt:objectName())) then
            for _, card in ipairs(cards) do
                if self:getUseValue(card) < 6 and not self:isValuableCard(card) and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
                    use.card = final_parse(self,request,"#FourFanjian_Card:".. card:getKnownEffectiveId() ..":")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
		end
	end
end

sgs.ai_card_intention["#FourFanjian_Card"] = 70

function sgs.ai_skill_suit.FourFanjian(self)
	local map = {0, 0, 1, 2, 2, 3, 3, 3}
	local suit = map[math.random(1, 8)]
	local tg = self.room:getCurrent()
	local suits = {}
	local maxnum, maxsuit = 0
	for _, c in sgs.qlist(source_visible_hand(self,tg)) do
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), tg:objectName())
		if true then -- source_visible_hand already applied these exact flags
			if not suits[c:getSuitString()] then suits[c:getSuitString()] = 1 else suits[c:getSuitString()] = suits[c:getSuitString()] + 1 end
			if suits[c:getSuitString()] > maxnum then
				maxnum = suits[c:getSuitString()]
				maxsuit = c:getSuit()
			end
		end
	end
	if self.player:hasSkill("hongyan") and (maxsuit == sgs.Card_Spade or suit == sgs.Card_Spade) then
		return sgs.Card_Heart
	end
	if maxsuit then
		if self.player:hasSkill("hongyan") and maxsuit == sgs.Card_Spade then return sgs.Card_Heart end
		return maxsuit
	else
		if self.player:hasSkill("hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart end
		return suit
	end
end

sgs.dynamic_value.damage_card["#FourFanjian_Card"] = true

local FourQixi_skill = {}
FourQixi_skill.name = "FourQixi"
table.insert(package_skills, FourQixi_skill)
FourQixi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:hasFlag("FourQixi_used") then return end
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local black_card

	self:sortByUseValueInPlace(cards, true)

	local has_weapon = false

	for _,card in ipairs(cards)  do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon=true end
	end

	for _,card in ipairs(cards)  do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end

			if card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if self:getCardsNum("Slash") == 1 then
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = self:aiUseCard(card, dummy())
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end

		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getKnownEffectiveId()
		local card_str = ("dismantlement:FourQixi[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = parse(self,request,card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.FourQixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.FourQixi(to, card)
	return card:isBlack()
end

sgs.ai_skill_cardask["@FourJinfan_prompt"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
    local card_id = move.card_ids:first()
    local cd = disclosed(self,card_id)
    local cards = AIList.new(self.player:getCards("h"))
    self:sortByKeepValueInPlace(cards)
    for _, card in ipairs(cards) do
        if self:getKeepValue(card) < self:getKeepValue(cd) and card:isRed() then
            return "$" .. card:getKnownEffectiveId()
        end
    end
	return "."
end

local FourQixiA_skill = {}
FourQixiA_skill.name = "FourQixiA"
table.insert(package_skills, FourQixiA_skill)
FourQixiA_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getPile("horseA"):isEmpty() then
		return
	end
	for i = 0, self.player:getPile("horseA"):length() - 1, 1 do
		local snatch = disclosed(self,self.player:getPile("horseA"):at(i))
		local snatch_str = ("dismantlement:FourQixiA[%s:%s]=%d"):format(snatch:getSuitString(), snatch:getNumberString(), self.player:getPile("horseA"):at(i))
		local jixisnatch = parse(self,request,snatch_str)

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if  not self.room:isProhibited(self.player, player, jixisnatch) and self:hasTrickEffective(jixisnatch, player) then

				local suit = snatch:getSuitString()
				local number = snatch:getNumberString()
				local card_id = snatch:getKnownEffectiveId()
				local card_str = ("dismantlement:FourQixiA[%s:%s]=%d"):format(suit, number, card_id)
				local snatch = parse(self,request,card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end

sgs.ai_view_as.FourQixiA = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "horseA" then
		return material(card,"dismantlement","FourQixiA")
	end
end

ai_skill_invoke.FourQixiA = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_cardask["@FourQixiA_Exchange"] = function(self, data, pattern, target)
    local cards = AIList.new(self.player:getCards("he"))
    self:sortByKeepValueInPlace(cards)
    for _, card in ipairs(cards) do
        if card:isBlack() then
            return "$" .. card:getKnownEffectiveId()
        end
    end
	return "."
end

sgs.ai_hasTuntianEffect_skill.FourQixiA = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive and to:getPile("horseA"):length() < 4
end

sgs.lose_equip_skill = sgs.lose_equip_skill .. "|FourQixiB"

local FourQixiB_skill = {}
FourQixiB_skill.name = "FourQixiB"
table.insert(package_skills, FourQixiB_skill)
FourQixiB_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getPile("horseB"):isEmpty() then
		return
	end
	local can_use = false
	for i = 0, self.player:getPile("horseB"):length() - 1, 1 do
		local snatch = disclosed(self,self.player:getPile("horseB"):at(i))
		local snatch_str = ("dismantlement:FourQixiB[%s:%s]=%d"):format(snatch:getSuitString(), snatch:getNumberString(), self.player:getPile("horseB"):at(i))
		local jixisnatch = parse(self,request,snatch_str)

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if  not self.room:isProhibited(self.player, player, jixisnatch) and self:hasTrickEffective(jixisnatch, player) then

				local suit = snatch:getSuitString()
				local number = snatch:getNumberString()
				local card_id = snatch:getKnownEffectiveId()
				local card_str = ("dismantlement:FourQixiB[%s:%s]=%d"):format(suit, number, card_id)
				local snatch = parse(self,request,card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end

sgs.ai_view_as.FourQixiB = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "horseB" then
		return material(card,"dismantlement","FourQixiB")
	end
end

ai_skill_invoke.FourQixiB = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_cardask["@FourQixiB_Exchange"] = function(self, data, pattern, target)
    local cards = AIList.new(self.player:getCards("he"))
    self:sortByKeepValueInPlace(cards)
    for _, card in ipairs(cards) do
        if card:isBlack() and not card:isKindOf("EquipCard") then
            return "$" .. card:getKnownEffectiveId()
        end
    end
	return "."
end

local FourTianxiang_skill = {}
FourTianxiang_skill.name= "FourTianxiang"
table.insert(package_skills,FourTianxiang_skill)
FourTianxiang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#FourTianxiang_Card") then
		return parse(self,request,"#FourTianxiang_Card:.:")
	end
end

ai_card_use["#FourTianxiang_Card"] = function(self, card, use, request)

    local use_card, cards
    cards = self.player:getHandcards()
    for _, card in sgs.qlist(cards) do
        if card:getSuit() == sgs.Card_Heart  then
            use_card = card
            break
        end
    end

    self:sortInPlace(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy, self.player, nil) then
            if use_card  then
                use.card = final_parse(self,request,"#FourTianxiang_Card:" .. use_card:getKnownId()..":")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
            
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp() < getBestHp(friend) then
            if use_card  then
                use.card = final_parse(self,request,"#FourTianxiang_Card:" .. use_card:getKnownId()..":")
                if use.to then
                    use.to:append(friend)
                end
                break
            end
            
        end
    end
		
end

sgs.ai_use_value["#FourTianxiang_Card"] = 2.5

function sgs.ai_cardneed.FourTianxiang(to, card, self)
	return (card:getSuit() == sgs.Card_Heart or (to:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade))
		and (getKnownCard(to, self.player, "heart", false) + getKnownCard(to, self.player, "spade", false)) < 2
end

sgs.FourTianxiang_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}

ai_skill_choice.FourTianxiang = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

local items = choices:split("+")
local target = data:toPlayer()
	
	if target and self:isFriend(target)  then
		return ai_choice_result(("FourTianxiang_Recover"), options)
	end	
	if target and self:isEnemy(target)  then
		return ai_choice_result(("FourTianxiang_Damage"), options)
	end
	return ai_choice_result(("FourTianxiang_Damage"), options)
end

sgs.ai_choicemade_filter.skillChoice["FourTianxiang"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if public_flag(self,p,"FourTianxiang") then
			if choice == "FourTianxiang_Recover" then
				self:updateIntention(player, p, -80)
			else 
				self:updateIntention(player, p, 80)
			end
		end
	end
end

sgs.wizard_skill = sgs.wizard_skill .. "|FourGuidao"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|FourGuidao"

sgs.ai_skill_cardask["@FourGuidao-card"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(disclosed(self,id))
		end
	end
	
	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and ((not self.player:hasSkill("leiji") and not self.player:hasSkill("olleiji")) or judge.card:getSuit() ~= sgs.Card_Club)
						and aoe_truth(self) and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and self:findLeijiTarget(self.player, 50)
						and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("nosleiji") then keptspade = 2 end
		if self.player:hasSkill("PlusLeiji") then keptspade = 2 end
		if self.player:hasSkill("leiji") then keptblack = 2 end
		if self.player:hasSkill("olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not self.player:hasSkill("olleiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValueInPlace(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(disclosed(self,card_id)) then
		local card = disclosed(self,card_id)
		return "$" .. card_id
	end

	return "."
end

sgs.FourGuidao_suit_value = {
	spade = 3.9,
	club = 2.7
}

sgs.FourGuidao_keep_value = {
	Peach = 10,
	Jink = 9
}

ai_skill_invoke.FourGuidao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
ai_skill_invoke.FourGuidaotake = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (not (self.player:hasSkill("FourDedao") and self.player:getMark("FourDedao") == 0 and self.player:getPile("symbol"):length() < 4 )) or false
end

local FourTaiping_Others_skill = {}
FourTaiping_Others_skill.name = "FourTaiping_Others"
table.insert(package_skills, FourTaiping_Others_skill)
FourTaiping_Others_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasFlag("ForbidFourTaiping") then return nil end

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	local card
	self:sortByUseValueInPlace(cards, true)
	for _,acard in ipairs(cards)  do
		if acard:getSuit() == sgs.Card_Heart then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getKnownEffectiveId()
	local card_str = "#FourTaiping_Card:"..card_id..":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

ai_card_use["#FourTaiping_Card"] = function(self, card, use, request)
	if self:needBear() then
		return
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasSkill("FourTaiping") then
			if not friend:hasFlag("FourTaipingInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sortInPlace(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasSkill("FourTaiping") then
				if not enemy:hasFlag("FourTaipingInvoked") then
					if not hasManjuanEffect(enemy) then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:getStrategyHasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:getStrategyHasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sortInPlace(targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
								use.card = card
								if use.to then
									use.to:append(enemy)
								end
								break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["#FourTaiping_Card"] = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:getStrategyHasUsed("TianyiCard"))
								or (from:hasSkill("xianzhen") and not from:getStrategyHasUsed("XianzhenCard"))) then
	else
		self:updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority["#FourTaiping_Card"] = 10
sgs.ai_use_value["#FourTaiping_Card"] = 8.5

local DiyJisu_skill = {}
DiyJisu_skill.name = "DiyJisu"
table.insert(package_skills, DiyJisu_skill)
DiyJisu_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

    if self:getCardsNum("Slash") > 0 then
        for i = 0, self.player:getPile("turn"):length() - 1, 1 do
            local snatch = disclosed(self,self.player:getPile("turn"):at(i))
            local snatch_str = ("analeptic:DiyJisu[%s:%s]=%d"):format(snatch:getSuitString(), snatch:getNumberString(), self.player:getPile("turn"):at(i))
            local suit = snatch:getSuitString()
            local number = snatch:getNumberString()
            local card_id = snatch:getKnownEffectiveId()
            local card_str = ("analeptic:DiyJisu[%s:%s]=%d"):format(suit, number, card_id)
            local snatch = parse(self,request,card_str)
            assert(snatch)
            return snatch
        end
    end
end

sgs.ai_view_as.DiyJisu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "turn" then
		return material(card,"analeptic","DiyJisu")
	end
end

local DiyXX_skill = {}
DiyXX_skill.name = "DiyXX"
table.insert(package_skills, DiyXX_skill)
DiyXX_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self:needBear() and not self.player:getStrategyHasUsed("#DiyXX_Card") then
		return parse(self,request,"#DiyXX_Card:.:")
	end
end
ai_card_use["#DiyXX_Card"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "chaofeng")
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("DiyXX_Play") == 0 then
			if enemy:isKongcheng() then continue end
			table.insert(enemys, enemy)
		end	
	end
	
	if #enemys > 0 then
		use.card = final_parse(self,request,"#DiyXX_Card:.:")
		if use.to then use.to:append(enemys[1]) end
	end
end

sgs.ai_use_priority["DiyXX_Card"] = 8

for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["FiveYingzhan"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if from and damage_call(from,"getMark","FiveYingzhan") == 0 and damage_call(self,"isFriend",from, to) and not damage_call(from,"hasFlag","FiveYingzhan_Damage")
        		and card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Fire then
        		return true, true
        	end
        return value
    end
    sgs.ai_need_damaged["FiveYingzhan"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_after_legacy" and context.rule == "FiveYingzhan" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "FiveYingzhan", {
        {phase="need_hp_after_legacy", order=12, rule="FiveYingzhan"},
    })
end)()
end
