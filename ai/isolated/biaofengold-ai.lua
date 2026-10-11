-- Fixed biaofengold-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("biaofengold policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("biaofengold policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==false and (method=="hasSkill"or method=="hasSkills"or method=="hasLordSkill")and AIValue.isPlayer(object)then
        local row=rawget(object,"_view")
        if row and row.skills_complete~=true then ai_unsupported("foreign skill absence is unknown",(...))end
    end
    return known(value,method)
end
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
local skill_cards={
 ["#FiveFanjian_Card"]="FiveFanjian",["#FiveHuangtianA_Card"]="FiveHuangtianA_Qun",["#FiveGuidaoA_Card"]="FiveGuidaoA",
 ["#FourJiaozhao_Card"]="FourJiaozhao",["#FourHuoji_Card"]="FourHuoji",["#FourFanjian_Card"]="FourFanjian",
 ["#FourTianxiang_Card"]="FourTianxiang",["#FourTaiping_Card"]="FourTaiping_Others",["#DiyXX_Card"]="DiyXX",
 ["#FiveLeiji_Card"]="FiveLeiji",["#FourNiepan_Card"]="FourNiepan",["#FourJianxiong_Card"]="FourJianxiong"}
local conversion_classes={slash="Slash",analeptic="Analeptic",dismantlement="Dismantlement"}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),"biaofengold disclosed material")end
local function material(card,name,skill)return{name=name,skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={q(card,"getEffectiveId")}}end
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
  return q(self,"evaluateTurnSkillCard",skill,class,costs,action_request(self,request))
 end
 local name,skill,id=wire:match("^([^:]+):([^%[]+)%[[^%]]+%]=(%d+)$")
 if not name then ai_unsupported("unsupported source card grammar",wire)end
 local spec=material(disclosed(self,tonumber(id)),name,skill)
 return q(self,"evaluateTurnConversion",skill,known(conversion_classes[name],name),spec,action_request(self,request))
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
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function residue(self,name)return q(known(self:getEvaluationCard(name),name),"getTargetModResidue")end
local function current_damage(self)
 local context=q(self,"getDecisionContext");local raw=known(context.damage,"CurrentDamageStruct")
 return raw
end
local function role(self,p)
 local value=call(p,"getRole");if value~=nil then return value end
 return q(self,"useKnowledgeEstimate",{status="estimate",value=q(self,"getRoleEstimate",p),basis="viewer_role_estimate_private_role",player=q(p,"objectName")},"FourJianxiong.role")
end
local function public_flag(self,player,name)
 local facts=self.world.strategy_facts.round41_skill_flags
 if type(facts)~="table" or facts.viewer~=q(self.player,"objectName") then
  return known(nil,"scoped skill flag "..name)
 end
 local row=facts.flags and facts.flags[name]
 local value=row and row[q(player,"objectName")]
 if type(value)~="table" or type(value.value)~="boolean" then return known(nil,"scoped skill flag "..name) end
 if value.status=="exact" and value.basis=="current_owner_flag" and player==self.player then return value.value end
 if value.status=="estimate" and value.basis=="skill_flag_last_public_observation" then
  return q(self,"useKnowledgeEstimate",{status="estimate",value=value.value,basis=value.basis,
   player=q(player,"objectName"),flag=name},"biaofengold.public_flag")
 end
 return known(nil,"scoped skill flag provenance "..name)
end
local function source_visible_hand(self,p)
 local all=self.world.strategy_facts.source_visible_hand_ids
 local ids=known(all and all[q(p,"objectName")],"source visible hand order")
 local faces={};for _,card in ipairs(q(p,"getKnownCards"))do faces[q(card,"getEffectiveId")]=card end
 local cards={};for _,id in ipairs(ids)do cards[#cards+1]=known(faces[id],"source visible card face")end
 return cards
end
local function aoe_truth(self)
 local facts=self.world.strategy_facts
 local f=facts.new and facts.new.aoe_data_truthy
 if type(f)~="table"or f.known~=true or type(f.truthy)~="boolean"then ai_unsupported("legacy AOE truthiness unavailable","FourGuidao")end
 return f.truthy
end


function sgs.ai_cardneed.FiveYingzhan(to, card, self)
	if q(to,"getMark","FiveYingzhan") == 0 then
        return q(card,"isKindOf","FireSlash") or q(card,"isKindOf","FireAttack") or q(card,"isKindOf","Fan")
    end
end


local FiveFanjian_skill = {}
FiveFanjian_skill.name = "FiveFanjian"
table.insert(package_skills, FiveFanjian_skill)
FiveFanjian_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#FiveFanjian_Card") or q(self.player,"isKongcheng") then return end
	if q(self,"needBear") then return end
	local parsed_card = parse(self,request,"#FiveFanjian_Card:.:")
	return parsed_card
end

sgs.ai_skill_use_func["#FiveFanjian_Card"] = function(card,use,self,request)
    local use_card
    if not use_card then
		local hcards = q(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards, true)

		for _, hcard in ipairs(hcards) do
			if q(hcard,"getSuit") == sgs.Card_Heart and not q(hcard,"isKindOf","Peach") then
				use_card = hcard
				break
			end
		end
	end
    if not use_card then return end
	local count = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") then count = count + 1 end
	end
	if count >= 1 and #self.enemies > 1 then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (hasManjuanEffect(enemy) ) and not hasTuntianEffect(enemy, true) then
				target = enemy
				break
			end
		end
	end
	if not target then
		sort_players(self,self.friends_noself, "defense")
		self.friends_noself = sgs.reverse(self.friends_noself)
		if count < 1 then return end
		for _, friend in ipairs(self.friends_noself) do
			if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and not q(self,"isWeak",friend) then
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
		for _, acard in sgs.qlist(q(self.player,"getHandcards")) do
			if isCard("Peach", acard, self.player) and q(self.player,"getHandcardNum") > 1 and q(self.player,"isWounded")
				and not q(self,"needToLoseHp",self.player) then
					use.card = acard
					return
			end
		end
		use.card = final_parse(self,request,"#FiveFanjian_Card:"..q(use_card,"getId")..":")
		if use.to then
			call(self,"setStrategyPlayerFlag",target,"AI_FiveFanjianTarget",true)
			call(use.to,"append",target)
		end
	end
end

sgs.ai_use_priority["#FiveFanjian_Card"] = 1.5
sgs.ai_card_intention["#FiveFanjian_Card"] = 0
sgs.ai_playerchosen_intention.FiveFanjian = 10

sgs.ai_skill_playerchosen.FiveFanjian = function(self, targets)
	sort_players(self,self.enemies, "defense")
	local slash = call(self,"getEvaluationCard","slash")
	
	local from
	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"hasStrategyPlayerFlag",player,"AI_FiveFanjianTarget") then
			from = player
			call(self,"setStrategyPlayerFlag",from,"AI_FiveFanjianTarget",false)
			break
		end
	end
	if from then
		for _, to in ipairs(self.enemies) do
			if q(targets,"contains",to) and q(self,"slashIsEffective",slash, to, from) and q(self,"isGoodTarget",to, self.enemies, slash)	and not q(self,"needToLoseHp",to, from, slash,true) and not call(self,"findLeijiTarget",to, 50, from) then
				return to
			end
		end
	end
	for _, to in ipairs(self.enemies) do
		if q(targets,"contains",to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.FiveFanjian(minusecard, self, requestor, maxcard)
	local req
	if q(self.player,"objectName") == q(requestor,"objectName") then
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if public_flag(self,p,"FiveFanjianPindianTarget") then
				req = p
				break
			end
		end
	else
		req = requestor
	end
	local cards, maxcard = AIList.new(q(self.player,"getHandcards"))
	local max_value = 0
	sort_keep(self,cards)
	max_value = q(self,"getKeepValue",cards[#cards])
	local function compare_func1(a, b)
		return q(a,"getNumber") > q(b,"getNumber")
	end
	local function compare_func2(a, b)
		return q(a,"getNumber") < q(b,"getNumber")
	end
	if q(self,"isFriend",req) and q(self.player,"getHp") > q(req,"getHp") then
		table.sort(cards, compare_func2)
	else
		table.sort(cards, compare_func1)
	end
	for _, card in ipairs(cards) do
		if max_value > 7 or q(self,"getKeepValue",card) < 7 or q(card,"isKindOf","EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end




local FiveHuangtianA_Qun_skill = {}
FiveHuangtianA_Qun_skill.name = "FiveHuangtianA_Qun"
table.insert(package_skills, FiveHuangtianA_Qun_skill)
FiveHuangtianA_Qun_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasFlag","ForbidFiveHuangtianA") then return nil end
	if q(self.player,"getKingdom") ~= "qun" then return nil end

	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	local card
	sort_use(self,cards,true)
	for _,acard in ipairs(cards)  do
		if q(acard,"isRed") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = q(card,"getEffectiveId")
	local card_str = "#FiveHuangtianA_Card:"..card_id..":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#FiveHuangtianA_Card"] = function(card,use,self,request)
	if q(self,"needBear") or q(self,"getCardsNum","Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if q(friend,"hasLordSkill","FiveHuangtianA") then
			if not q(friend,"hasFlag","FiveHuangtianAInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		sort_players(self,targets, "defense")
		if use.to then
			call(use.to,"append",targets[1])
		end
	elseif q(self,"getCardsNum","Slash", "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"hasLordSkill","FiveHuangtianA") then
				if not q(enemy,"hasFlag","FiveHuangtianAInvoked") then
					if not hasManjuanEffect(enemy) then
						if q(enemy,"isKongcheng") and not q(enemy,"hasSkill","kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if q(self.player,"hasSkill","tianyi") and not q(self.player,"hasUsed","TianyiCard") then
				flag = true
			elseif q(self.player,"hasSkill","xianzhen") and not q(self.player,"hasUsed","XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = call(self,"getMaxCard",self.player) --最大点数的手牌
				if q(maxCard,"getNumber") > q(card,"getNumber") then --可以保证拼点成功
					sort_players(self,targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if q(self.player,"canSlash",enemy, nil, false, 0) then --可以发动天义或陷阵
								use.card = card
								call(self,"setStrategyPlayerFlag",enemy,"AI_HuangtianPindian",true)
								if use.to then
									call(use.to,"append",enemy)
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
	if tos[1]:isKongcheng() and ((q(from,"hasSkill","tianyi") and not q(from,"hasUsed","TianyiCard"))
								or (q(from,"hasSkill","xianzhen") and not q(from,"hasUsed","XianzhenCard"))) then
	else
		call(self,"updateIntention",from, tos[1], -80)
	end
end

sgs.ai_use_priority["#FiveHuangtianA_Card"] = 10
sgs.ai_use_value["#FiveHuangtianA_Card"] = 8.5


sgs.ai_skill_invoke.FiveGuidaoA = function(self, data)
	return true
end



local FiveGuidaoA_skill = {}
FiveGuidaoA_skill.name= "FiveGuidaoA"
table.insert(package_skills,FiveGuidaoA_skill)
FiveGuidaoA_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getPile","dao"):length() >= 3 then
		return parse(self,request,"#FiveGuidaoA_Card:.:")
	end
end

sgs.ai_skill_use_func["#FiveGuidaoA_Card"] = function(card,use,self,request)
    local to_use = {}
    local cards = {}
	if q(self.player,"getPile","dao"):length() > 0 then
        for _, id in sgs.qlist(q(self.player,"getPile","dao")) do
            table.insert(cards ,disclosed(self,id))
        end
    end
	sort_keep(self,cards)
	
    for _,c in ipairs(cards) do
        if #to_use < 3 then
			table.insert(to_use, q(c,"getEffectiveId"))
		end
    end
    if #to_use == 3  then
    
        call(self,"updatePlayers")
        sort_players(self,self.enemies,"hp")
        for _,enemy in ipairs(self.enemies) do
            if not q(enemy,"hasArmorEffect","SilverLion")  and
                q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and not (q(enemy,"isChained") and not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and q(self,"canDamage",enemy,self.player,nil) then
                use.card = final_parse(self,request,"#FiveGuidaoA_Card:" .. table.concat(to_use, "+").. ":")
                if use.to then
                    call(use.to,"append",enemy)
                end
                return
            end
        end
        
        for _,enemy in ipairs(self.enemies) do
            if not q(enemy,"hasSkill","hongyan")
             and not (q(enemy,"isChained") and not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) then
                use.card = final_parse(self,request,"#FiveGuidaoA_Card:" .. table.concat(to_use, "+").. ":")
                if use.to then
                    call(use.to,"append",enemy)
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
	return q(to,"getPhase") == sgs.Player_NotActive and q(to,"getPile","dao"):length() < 5
end

sgs.ai_skill_invoke.FiveGuidaoB = function(self, data)
    local target = call(self.room,"getCurrent") 
    if q(target,"objectName") == q(self.player,"objectName") then
        local zhangjiao = call(data,"toPlayer")
        if zhangjiao and q(self,"isFriend",zhangjiao) then
            return q(self,"doDisCard",zhangjiao, "h")
        else
            return q(self,"doDisCard",zhangjiao, "h")
        end
    else
        if (q(self,"isEnemy",target) and not q(target,"isChained")) or (q(self,"isFriend",target) and q(target,"isChained")) or (q(target,"getKingdom") == "qun" and not q(target,"isChained") and q(self.player,"hasLordSkill","FiveHuangtianB")) then
            return true
        end
    end
	return false
end



sgs.ai_skill_choice.FiveGuidaoB = function(self, choices)
local items = q(choices,"split","+")
local target = call(self.room,"getCurrent") 
	
	if target and q(self,"isFriend",target) and not q(self.player,"hasLordSkill","FiveHuangtianB") and q(target,"getKingdom") == "qun" then
		return "FiveGuidaoB_Reset"
	end	
	if target and q(self,"isEnemy",target)  then
		return "FiveGuidaoB_Chain"
	end
	return "FiveGuidaoB_Chain"
end




sgs.ai_skill_use["@FiveLeiji"]=function(self,prompt)
	local mode = q(self.room,"getMode")
	if call(mode,"find","_mini_17") or call(mode,"find","_mini_19") or call(mode,"find","_mini_20") or call(mode,"find","_mini_26") then 
		local players = q(self.room,"getAllPlayers");
		for _,aplayer in sgs.qlist(players) do
			if q(aplayer,"getState") ~= "robot" then
				return response(self,"#FiveLeiji_Card",{}, {aplayer})
			end
		end
	end

	call(self,"updatePlayers")
	sort_players(self,self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"hasArmorEffect","SilverLion")  and
			q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and not (q(enemy,"isChained") and not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and q(self,"canDamage",enemy,self.player,nil) then
			return response(self,"#FiveLeiji_Card",{}, {enemy})
		end
	end
	
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"hasSkill","hongyan")
		 and not (q(enemy,"isChained") and not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) then
			return response(self,"#FiveLeiji_Card",{}, {enemy})
		end
	end
	
	return "."
end

sgs.ai_card_intention["#FiveLeiji_Card"] = 80

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|FiveLeiji"

sgs.ai_hasTuntianEffect_skill.FiveLeiji = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_skill_playerchosen.FiveHuangtianB = function(self, targets)
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if q(self,"isFriend",target) and q(target,"isAlive") then
			return target
		end
	end
	if q(self.player,"getRole") == "renegade" then
		call(self,"updateIntention",self.player, call(self.room,"getLord"), 50)
	end
	return nil
end

sgs.ai_playerchosen_intention.FiveHuangtianB = -50


sgs.ai_skill_use["@FourJianxiong"] = function(self, prompt)
	local damage = current_damage(self)
	local dest = damage.to
	if not q(self,"isEnemy",dest) then return "." end
	local target
	
    if q(dest,"getHp") <= 1 then
        if role(self,dest) == "rebel" and q(self,"getOverflow") then
            for _,friend in ipairs(self.friends_noself) do
                if friend then
                    if not hasJueqingEffect(friend, dest, damage.nature) then
                        target = friend
                    end
                end
            end
        elseif role(self,dest) == "loyalist" then
            local lord = call(self.room,"getLord")
            if q(self,"isEnemy",lord) then
                target = lord
            end
        end
    end
    
    	
    if not target then
        if q(self,"hasSkills",sgs.masochism_skill, dest) then
            sort_players(self,self.enemies, "defense")
            for _,enemy in ipairs(self.enemies) do
                if enemy then
                    target = enemy
                end
            end
        end
    end
	
	local discard_cards =  {}
	
    for _, id in sgs.qlist(q(self.player,"getCards","h")) do
        if q(id,"getSuit") == sgs.Card_Spade then
            table.insert(discard_cards, id)
        end
    end
    if target and #discard_cards > 0 then return response(self,"#FourJianxiong_Card",{discard_cards[1]:getEffectiveId()}, {target})    end
	return "."
end


sgs.ai_skill_choice.FourJianxiong = function(self, choices, data)
	local damage = q(data,"toDamage")
	if not damage.card then return "FourJianxiong_choice2" end
	if q(damage.card,"isKindOf","Slash") and not q(self,"hasCrossbowEffect") and q(self.player,"getLostHp") > 1 and q(self,"getCardsNum","Slash") > 0 then return "FourJianxiong_choice2" end
	if q(self,"isWeak") and (q(self,"getCardsNum","Slash") > 0 or not q(damage.card,"isKindOf","Slash") or q(self.player,"getHandcardNum") <= q(self.player,"getHp")) then return "FourJianxiong_choice2" end
	local items = q(choices,"split","+")
	if table.contains(items, "FourJianxiong_choice1") then return "FourJianxiong_choice1" end
	return items[1]
end

ai_audited_aliases.register{id="ai_target_revises.FourJianxiong",registry="ai_target_revises",path={"FourJianxiong"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=1,defer_canonical=true}

sgs.ai_can_damagehp.FourJianxiong = function(self, from, card, to)
	if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
		and q(self,"canLoseHp",from, card, to)
	then
		return q(card,"isKindOf","Duel") or q(card,"isKindOf","AOE") or q(to,"getLostHp") > 2
	end
end


local FourJiaozhao_skill = {}
FourJiaozhao_skill.name = "FourJiaozhao"
table.insert(package_skills, FourJiaozhao_skill)
FourJiaozhao_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getMark","@jiaozhao") == 0 then return end

	local card
	if not card then
		local hcards = q(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards, true)

		for _, hcard in ipairs(hcards) do
			if q(hcard,"isKindOf","Peach") then
				card = hcard
			end
		end
	end
	if card then
		card = parse(self,request,"#FourJiaozhao_Card:" .. q(card,"getEffectiveId")..":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#FourJiaozhao_Card"] = function(card,use,self,request)
	local lord = call(self.room,"getLord")
	if lord then
		for _,skill in sgs.qlist(q(lord,"getVisibleSkillList")) do
			if q(skill,"isLordSkill") then
				use.card = card
				if use.to then
					call(use.to,"append",lord)
				end
			end
		end
	end
end



sgs.ai_skill_invoke.FourFenyong = function(self, data)
	if q(self.room,"getTurnCount") <= 1 and #self.enemies == 0 then return end

	local current = call(self.room,"getCurrent")
	if not current or q(current,"getPhase") >= sgs.Player_Finish then return true end
	if q(self,"isFriend",current) then
		return false
	end

	return true
end

function sgs.ai_slash_prohibit.FourFenyong(self, from, to)
	if hasJueqingEffect(from, to) or (q(from,"hasSkill","nosqianxi") and q(from,"distanceTo",to) == 1) then return false end
	if q(from,"hasFlag","NosJiefanUsed") then return false end
	return not q(to,"faceUp") and q(to,"hasSkill","FourFenyong")
end

sgs.ai_need_damaged.FourFenyong = function (self, attacker, player)
	if not q(player,"hasSkill","FourFenyong") then return false end
	if not q(player,"hasSkill","FourXuehen") then return false end
    local enemy = call(self.room,"getCurrent")
    if q(self,"isEnemy",enemy) then
		local def = q(self,"getDefenseSlash",enemy)
		local slash = call(self,"getEvaluationCard","slash")
		
		-- local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)
		local eff = q(self,"slashIsEffective",slash, enemy)

		if q(self.player,"canSlash",enemy, nil, false) and not q(self,"slashProhibit",nil, enemy) and eff and def < 6 then
			return true
		end
	end
	return false
end
sgs.ai_ajustdamage_to.FourFenyong = function(self, from, to, card, nature)
	if to and not q(to,"faceUp") then
		return -99
	end
end

sgs.ai_skill_invoke.FourXuehen = function(self, data)
	local current = call(self.room,"getCurrent")
    if q(self,"isEnemy",current) then
        local def = q(self,"getDefenseSlash",current)
        local slash = call(self,"getEvaluationCard","slash")
        local eff = q(self,"slashIsEffective",slash, current) and q(self,"isGoodTarget",current, self.enemies, slash)

        if q(self.player,"canSlash",current, nil, false) and not q(self,"slashProhibit",nil, current) and eff and def < 6 then
            return true
        end
    end
	return false
end

sgs.ai_view_as.FourWusheng = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or q(player,"getPile","wooden_ox"):contains(card_id)) then
        if q(card,"isRed") and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") and not (q(card,"isKindOf","WoodenOx") and q(player,"getPile","wooden_ox"):length() > 0) then
		return material(card,"slash","FourWusheng")
        elseif q(card,"isBlack") and not q(card,"hasFlag","using") then
        return material(card,"analeptic","FourWusheng")
        end
	end
    
end

local FourWusheng_skill = {}
FourWusheng_skill.name = "FourWusheng"
table.insert(package_skills, FourWusheng_skill)
FourWusheng_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local red_card
	local black_card
	sort_use(self,cards, true)
    
    
    

	local useAll = false
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getHp") == 1 and not q(enemy,"hasArmorEffect","eight_diagram") and q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if q(self,"getCardsNum","Slash") <= 0 or q(self.player,"hasSkill","paoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	sort_players(self,self.enemies, "defense")
	if q(self.player,"hasSkill","nuzhan") then
		for _, enemy in ipairs(self.enemies) do
			if  not q(enemy,"hasArmorEffect","eight_diagram") and q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange")
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if q(card,"isRed") and q(card,"isKindOf","EquipCard") and not (q(card,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	sort_players(self,self.enemies, "defense")
	if q(self.player,"hasSkill","nuzhan") and not q(self.player,"hasFlag","hasUsedSlash") and q(self,"getCardsNum","Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if  not q(enemy,"hasArmorEffect","eight_diagram") and q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") then
				nuzhan_trick_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if q(card,"isRed") and q(card,"isKindOf","TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _, card in ipairs(cards) do
		if q(card,"isRed") and not q(card,"isKindOf","Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (q(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive or residue(self,"slash") > 0)
			and not (q(card,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end

	if nuzhan_equip then
		for _, card in ipairs(cards) do
			if q(card,"isRed") and q(card,"isKindOf","EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _, card in ipairs(cards) do
			if q(card,"isRed") and q(card,"isKindOf","TrickCard")then
				red_card = card
				break
			end
		end
	end
    
    for _, card in ipairs(cards) do
		if q(card,"isBlack") and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (q(self,"getUseValue",card) < sgs.ai_use_value.Analeptic or inclusive or residue(self,"Analeptic") > 0) then
			black_card = card
			break
		end
	end
    if black_card and q(self,"getCardsNum","Slash") > 0 then
		local suit = q(black_card,"getSuitString")
		local number = q(black_card,"getNumberString")
		local card_id = q(black_card,"getEffectiveId")
		local card_str = ("analeptic:FourWusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)
		return slash
	end
    
    
    
    
	if red_card then
		local suit = q(red_card,"getSuitString")
		local number = q(red_card,"getNumberString")
		local card_id = q(red_card,"getEffectiveId")
		local card_str = ("slash:FourWusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)
		return slash
	end
    
    
    
    
end

function sgs.ai_cardneed.FourWusheng(to, card)
	return q(to,"getHandcardNum") < 3 and q(card,"isRed")
end


sgs.ai_skill_playerchosen.FourYijue = function(self, targets)
	targets = AIList.new(targets)
	for _,target in sgs.list(targets)do
		if q(self,"isFriend",target) then
			return q(self,"doDisCard",target, "ej")
		end
	end
	for _,target in sgs.list(targets)do
		if q(self,"isEnemy",target) then
			return q(self,"doDisCard",target, "hej")
		end
	end
	for _,target in sgs.list(targets)do
		return q(self,"doDisCard",target, "hej")
	end
    return targets[1]
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.FourYijue",registry="ai_choicemade_filter",path={"cardChosen","FourYijue"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}




local FourHuoji_skill={}
FourHuoji_skill.name="FourHuoji"
table.insert(package_skills,FourHuoji_skill)
FourHuoji_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"hasUsed","#FourHuoji_Card") then return nil end
	local cards = q(self.player,"getCards","h")
	cards=AIList.new(cards)

	
	local card

	sort_use(self,cards,true)

	for _,acard in ipairs(cards) do
		if q(acard,"isRed") and not q(acard,"isKindOf","Peach") and (q(self,"getDynamicUsePriority",acard) < sgs.ai_use_value.FireAttack or q(self,"getOverflow") > 0) then
			if q(acard,"isKindOf","Slash") and q(self,"getCardsNum","Slash") == 1 then
				local keep
				local dummy_use = q(self,"aiUseCard",acard, dummy())
				if dummy_use.card and dummy_use.to and q(dummy_use.to,"length") > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if q(p,"getHp") <= 1 then keep = true break end
					end
					if q(dummy_use.to,"length") > 1 then keep = true end
				end
				if keep then call(self,"setPriorityValue","Slash",q(self,"getPriorityValue","FireAttack")+0.1,"FourHuoji")
				else
					call(self,"setPriorityValue","Slash",2.6,"FourHuoji")
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
	
    return parse(self,request,"#FourHuoji_Card:"..q(card,"getEffectiveId") ..":")
end



sgs.ai_skill_use_func["#FourHuoji_Card"] = function(card,use,self,request)
	local fire_attack = q(self,"evaluateOwnerViewAsCard",{source_key="FourHuoji",skill="",name="fire_attack",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={}})
	local dummy_use = q(self,"aiUseCard",fire_attack, dummy())
    if dummy_use.card and q(dummy_use.to,"length") > 0 then
        use.card = card
        if use.to then call(use.to,"append",q(dummy_use.to,"first")) end
        return
    end
end



sgs.ai_cardneed.FourHuoji = function(to, card, self)
	return q(to,"getHandcardNum") >= 2 and q(card,"isRed")
end

sgs.ai_skill_invoke.FourNiepan = function(self, data)
	local dying = q(data,"toDying")
	local peaches = 1 - q(dying.who,"getHp")

	return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
end


sgs.ai_skill_use["@FourNiepan"]=function(self,prompt)
	call(self,"updatePlayers")
	sort_players(self,self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"hasArmorEffect","SilverLion")  and
			q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(enemy,"isChained") and not (q(enemy,"isChained") and not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) and q(self,"canDamage",enemy,self.player,nil) then
			return response(self,"#FourNiepan_Card",{}, {enemy})
		end
	end
	
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"isChained") and not ( not q(self,"isGoodChainTarget",enemy)) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) then
			return response(self,"#FourNiepan_Card",{}, {enemy})
		end
	end
	
	return "."
end

sgs.ai_canNiepan_skill.FourNiepan = function(player)
	return q(player,"getMark","@Four_nirvana")>0
end

local FourFanjian_skill = {}
FourFanjian_skill.name = "FourFanjian"
table.insert(package_skills, FourFanjian_skill)
FourFanjian_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"hasUsed","#FourFanjian_Card") then return nil end
	return parse(self,request,"#FourFanjian_Card:.:")
end

sgs.ai_skill_use_func["#FourFanjian_Card"]=function(card,use,self,request)

	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_use(self,cards, true)
	
	sort_players(self,self.enemies, "hp")
    
    

	if q(self,"getCardsNum","Slash") > 0 then
		local slash = call(self,"getCard","Slash")
		local dummy_use = { isDummy = true, to = AIList.new({}) }
		call(self,"useCardSlash",slash, dummy_use)
		if dummy_use.card and q(dummy_use.to,"length") > 0 then
			call(self,"setPriorityValue","#FourFanjian_Card",q(self,"getPriorityValue","Slash")+0.15,"FourFanjian")
			local target = q(dummy_use.to,"first")
			if q(self,"isEnemy",target) and getCardsNum("Jink",target,self.player)>0 and q(target,"getMark","yijue") == 0
				and not q(target,"isKongcheng") and (q(self,"getOverflow") > 0 or q(target,"getHandcardNum") > 2)
				and not (q(self.player,"hasSkill","liegong") and (q(target,"getHandcardNum") >= q(self.player,"getHp") or q(target,"getHandcardNum") <= q(self.player,"getAttackRange")))
				and not (q(self.player,"hasSkill","kofliegong") and q(target,"getHandcardNum") >= q(self.player,"getHp")) then
				if q(target,"hasSkill","qingguo") then
					for _, card in ipairs(cards) do
						if q(self,"getUseValue",card) < 6 and q(card,"isBlack") and not (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) then
							use.card = final_parse(self,request,"#FourFanjian_Card:" .. q(card,"getEffectiveId")..":")
							if use.to then call(use.to,"append",target) end
							return
						end
					end
				end
				for _, card in ipairs(cards) do
					if q(self,"getUseValue",card) < 6 and q(card,"getSuit") == sgs.Card_Diamond and not (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) then
						use.card = final_parse(self,request,"#FourFanjian_Card:" .. q(card,"getEffectiveId")..":")
						if use.to then call(use.to,"append",target) end
						return
					end
				end
			end
		end
	end

	if q(self,"getOverflow") <= 0 then return end
	call(self,"setPriorityValue","#FourFanjian_Card",0.2,"FourFanjian")
	    
    
	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[q(c,"getSuitString")] then
			suits[q(c,"getSuitString")] = true
			suits_num = suits_num + 1
		end
	end

	local wgt = call(self.room,"findPlayerBySkillName","buyi")
	if wgt and q(self,"isFriend",wgt) then wgt = nil end

	for _, enemy in ipairs(self.enemies) do
		
		if q(self,"canAttack",enemy) and not q(enemy,"hasSkills","qingnang|jijiu|tianxiang")
			and not (wgt and q(card,"getTypeId") ~= sgs.Card_Basic and (q(enemy,"isKongcheng") or q(enemy,"objectName") == q(wgt,"objectName"))) then
            for _, card in ipairs(cards) do
                if q(self,"getUseValue",card) < 6 and not q(self,"isValuableCard",card) and not (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) then
                    use.card = final_parse(self,request,"#FourFanjian_Card:".. q(card,"getEffectiveId") ..":")
                    if use.to then call(use.to,"append",enemy) end
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
	local tg = call(self.room,"getCurrent")
	local suits = {}
	local maxnum, maxsuit = 0
	for _, c in sgs.qlist(source_visible_hand(self,tg)) do
		local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(tg,"objectName"))
		if true then -- source_visible_hand already applied these exact flags
			if not suits[q(c,"getSuitString")] then suits[q(c,"getSuitString")] = 1 else suits[q(c,"getSuitString")] = suits[q(c,"getSuitString")] + 1 end
			if suits[q(c,"getSuitString")] > maxnum then
				maxnum = suits[q(c,"getSuitString")]
				maxsuit = q(c,"getSuit")
			end
		end
	end
	if q(self.player,"hasSkill","hongyan") and (maxsuit == sgs.Card_Spade or suit == sgs.Card_Spade) then
		return sgs.Card_Heart
	end
	if maxsuit then
		if q(self.player,"hasSkill","hongyan") and maxsuit == sgs.Card_Spade then return sgs.Card_Heart end
		return maxsuit
	else
		if q(self.player,"hasSkill","hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart end
		return suit
	end
end

sgs.dynamic_value.damage_card["#FourFanjian_Card"] = true





local FourQixi_skill = {}
FourQixi_skill.name = "FourQixi"
table.insert(package_skills, FourQixi_skill)
FourQixi_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"hasFlag","FourQixi_used") then return end
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)

	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local black_card

	sort_use(self,cards,true)

	local has_weapon = false

	for _,card in ipairs(cards)  do
		if q(card,"isKindOf","Weapon") and q(card,"isBlack") then has_weapon=true end
	end

	for _,card in ipairs(cards)  do
		if q(card,"isBlack") and ((q(self,"getUseValue",card) < sgs.ai_use_value.Dismantlement) or inclusive or q(self,"getOverflow") > 0) then
			local shouldUse = true

			if q(card,"isKindOf","Armor") then
				if not call(self.player,"getArmor") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not q(self,"needToThrowArmor") then shouldUse = false
				end
			end

			if q(card,"isKindOf","Weapon") then
				if not call(self.player,"getWeapon") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not has_weapon then shouldUse = false
				end
			end

			if q(card,"isKindOf","Slash") then
				local dummy_use = q(self,"aiUseCard",card, dummy())
				if q(self,"getCardsNum","Slash") == 1 then
					if dummy_use.card then shouldUse = false end
				end
			end

			if q(self,"getUseValue",card) > sgs.ai_use_value.Dismantlement and q(card,"isKindOf","TrickCard") then
				local dummy_use = q(self,"aiUseCard",card, dummy())
				call(self,"useTrickCard",card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end

		end
	end

	if black_card then
		local suit = q(black_card,"getSuitString")
		local number = q(black_card,"getNumberString")
		local card_id = q(black_card,"getEffectiveId")
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
	return q(card,"isBlack")
end

sgs.ai_skill_cardask["@FourJinfan_prompt"] = function(self, data, pattern, target)
	local move = q(data,"toMoveOneTime")
    local card_id = q(move.card_ids,"first")
    local cd = disclosed(self,card_id)
    local cards = AIList.new(q(self.player,"getCards","h"))
    sort_keep(self,cards)
    for _, card in ipairs(cards) do
        if q(self,"getKeepValue",card) < q(self,"getKeepValue",cd) and q(card,"isRed") then
            return "$" .. q(card,"getEffectiveId")
        end
    end
	return "."
end




local FourQixiA_skill = {}
FourQixiA_skill.name = "FourQixiA"
table.insert(package_skills, FourQixiA_skill)
FourQixiA_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getPile","horseA"):isEmpty() then
		return
	end
	for i = 0, q(self.player,"getPile","horseA"):length() - 1, 1 do
		local snatch = disclosed(self,q(self.player,"getPile","horseA"):at(i))
		local snatch_str = ("dismantlement:FourQixiA[%s:%s]=%d"):format(q(snatch,"getSuitString"), q(snatch,"getNumberString"), q(self.player,"getPile","horseA"):at(i))
		local jixisnatch = parse(self,request,snatch_str)

		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if  not q(self.room,"isProhibited",self.player, player, jixisnatch) and q(self,"hasTrickEffective",jixisnatch, player) then

				local suit = q(snatch,"getSuitString")
				local number = q(snatch,"getNumberString")
				local card_id = q(snatch,"getEffectiveId")
				local card_str = ("dismantlement:FourQixiA[%s:%s]=%d"):format(suit, number, card_id)
				local snatch = parse(self,request,card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end

sgs.ai_view_as.FourQixiA = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial and q(player,"getPileName",card_id) == "horseA" then
		return material(card,"dismantlement","FourQixiA")
	end
end


sgs.ai_skill_invoke.FourQixiA = function(self, data)
	return true
end

sgs.ai_skill_cardask["@FourQixiA_Exchange"] = function(self, data, pattern, target)
    local cards = AIList.new(q(self.player,"getCards","he"))
    sort_keep(self,cards)
    for _, card in ipairs(cards) do
        if q(card,"isBlack") then
            return "$" .. q(card,"getEffectiveId")
        end
    end
	return "."
end

sgs.ai_hasTuntianEffect_skill.FourQixiA = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive and q(to,"getPile","horseA"):length() < 4
end


sgs.lose_equip_skill = sgs.lose_equip_skill .. "|FourQixiB"



local FourQixiB_skill = {}
FourQixiB_skill.name = "FourQixiB"
table.insert(package_skills, FourQixiB_skill)
FourQixiB_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getPile","horseB"):isEmpty() then
		return
	end
	local can_use = false
	for i = 0, q(self.player,"getPile","horseB"):length() - 1, 1 do
		local snatch = disclosed(self,q(self.player,"getPile","horseB"):at(i))
		local snatch_str = ("dismantlement:FourQixiB[%s:%s]=%d"):format(q(snatch,"getSuitString"), q(snatch,"getNumberString"), q(self.player,"getPile","horseB"):at(i))
		local jixisnatch = parse(self,request,snatch_str)

		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if  not q(self.room,"isProhibited",self.player, player, jixisnatch) and q(self,"hasTrickEffective",jixisnatch, player) then

				local suit = q(snatch,"getSuitString")
				local number = q(snatch,"getNumberString")
				local card_id = q(snatch,"getEffectiveId")
				local card_str = ("dismantlement:FourQixiB[%s:%s]=%d"):format(suit, number, card_id)
				local snatch = parse(self,request,card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end

sgs.ai_view_as.FourQixiB = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial and q(player,"getPileName",card_id) == "horseB" then
		return material(card,"dismantlement","FourQixiB")
	end
end


sgs.ai_skill_invoke.FourQixiB = function(self, data)
	return true
end

sgs.ai_skill_cardask["@FourQixiB_Exchange"] = function(self, data, pattern, target)
    local cards = AIList.new(q(self.player,"getCards","he"))
    sort_keep(self,cards)
    for _, card in ipairs(cards) do
        if q(card,"isBlack") and not q(card,"isKindOf","EquipCard") then
            return "$" .. q(card,"getEffectiveId")
        end
    end
	return "."
end



local FourTianxiang_skill = {}
FourTianxiang_skill.name= "FourTianxiang"
table.insert(package_skills,FourTianxiang_skill)
FourTianxiang_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#FourTianxiang_Card") then
		return parse(self,request,"#FourTianxiang_Card:.:")
	end
end

sgs.ai_skill_use_func["#FourTianxiang_Card"] = function(card,use,self,request)


    local use_card, cards
    cards = q(self.player,"getHandcards")
    for _, card in sgs.qlist(cards) do
        if q(card,"getSuit") == sgs.Card_Heart  then
            use_card = card
            break
        end
    end
    
    
    
    sort_players(self,self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy) and q(self,"canDamage",enemy,self.player,nil) then
            if use_card  then
                use.card = final_parse(self,request,"#FourTianxiang_Card:" .. q(use_card,"getId")..":")
                if use.to then
                    call(use.to,"append",enemy)
                end
                break
            end
            
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"getHp") < getBestHp(friend) then
            if use_card  then
                use.card = final_parse(self,request,"#FourTianxiang_Card:" .. q(use_card,"getId")..":")
                if use.to then
                    call(use.to,"append",friend)
                end
                break
            end
            
        end
    end
		
end

sgs.ai_use_value["#FourTianxiang_Card"] = 2.5

function sgs.ai_cardneed.FourTianxiang(to, card, self)
	return (q(card,"getSuit") == sgs.Card_Heart or (q(to,"hasSkill","hongyan") and q(card,"getSuit") == sgs.Card_Spade))
		and (getKnownCard(to, self.player, "heart", false) + getKnownCard(to, self.player, "spade", false)) < 2
end

sgs.FourTianxiang_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}

sgs.ai_skill_choice.FourTianxiang = function(self, choices, data)
local items = q(choices,"split","+")
local target = call(data,"toPlayer")
	
	if target and q(self,"isFriend",target)  then
		return "FourTianxiang_Recover"
	end	
	if target and q(self,"isEnemy",target)  then
		return "FourTianxiang_Damage"
	end
	return "FourTianxiang_Damage"
end


sgs.ai_choicemade_filter.skillChoice["FourTianxiang"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if public_flag(self,p,"FourTianxiang") then
			if choice == "FourTianxiang_Recover" then
				call(self,"updateIntention",player, p, -80)
			else 
				call(self,"updateIntention",player, p, 80)
			end
		end
	end
end


sgs.wizard_skill = sgs.wizard_skill .. "|FourGuidao"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|FourGuidao"

sgs.ai_skill_cardask["@FourGuidao-card"]=function(self, data)
	local judge = q(data,"toJudge")
	local all_cards = q(self.player,"getCards","he")
	
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			call(all_cards,"prepend",disclosed(self,id))
		end
	end
	
	if q(all_cards,"isEmpty") then return "." end

	local needTokeep = q(judge.card,"getSuit") ~= sgs.Card_Spade and ((not q(self.player,"hasSkill","leiji") and not q(self.player,"hasSkill","olleiji")) or q(judge.card,"getSuit") ~= sgs.Card_Club)
						and aoe_truth(self) and q(self,"playerGetRound",judge.who) < q(self,"playerGetRound",self.player) and call(self,"findLeijiTarget",self.player, 50)
						and (q(self,"getCardsNum","Jink") > 0 or q(self,"hasEightDiagramEffect")) and q(self,"getFinalRetrial") == 1

	if not needTokeep then
		local who = judge.who
		if q(who,"getPhase") == sgs.Player_Judge and not q(who,"getJudgingArea"):isEmpty() and q(who,"containsTrick","lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if q(self.player,"hasSkill","nosleiji") then keptspade = 2 end
		if q(self.player,"hasSkill","PlusLeiji") then keptspade = 2 end
		if q(self.player,"hasSkill","leiji") then keptblack = 2 end
		if q(self.player,"hasSkill","olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if q(card,"isBlack") and not q(card,"hasFlag","using") then
			if q(card,"getSuit") == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not q(self.player,"hasSkill","olleiji") then return "." end
	if keptspade == 1 and not q(self.player,"hasSkill","leiji") then return "." end

	local card_id = q(self,"getRetrialCardId",cards, judge)
	if card_id == -1 then
		if q(self,"needRetrial",judge) and judge.reason ~= "beige" then
			if q(self,"needToThrowArmor") then return "$" .. call(self.player,"getArmor"):getEffectiveId() end
			sort_use(self,cards, true)
			if q(self,"getUseValue",judge.card) > q(self,"getUseValue",cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif q(self,"needRetrial",judge) or q(self,"getUseValue",judge.card) > q(self,"getUseValue",disclosed(self,card_id)) then
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

sgs.ai_skill_invoke.FourGuidao = function(self, data)
	return true
end
sgs.ai_skill_invoke.FourGuidaotake = function(self, data)
	return not (q(self.player,"hasSkill","FourDedao") and q(self.player,"getMark","FourDedao") == 0 and q(self.player,"getPile","symbol"):length() < 4 )
end




local FourTaiping_Others_skill = {}
FourTaiping_Others_skill.name = "FourTaiping_Others"
table.insert(package_skills, FourTaiping_Others_skill)
FourTaiping_Others_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasFlag","ForbidFourTaiping") then return nil end

	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	local card
	sort_use(self,cards,true)
	for _,acard in ipairs(cards)  do
		if q(acard,"getSuit") == sgs.Card_Heart then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = q(card,"getEffectiveId")
	local card_str = "#FourTaiping_Card:"..card_id..":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#FourTaiping_Card"] = function(card,use,self,request)
	if q(self,"needBear") then
		return
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if q(friend,"hasSkill","FourTaiping") then
			if not q(friend,"hasFlag","FourTaipingInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		sort_players(self,targets, "defense")
		if use.to then
			call(use.to,"append",targets[1])
		end
	elseif q(self,"getCardsNum","Slash", "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"hasSkill","FourTaiping") then
				if not q(enemy,"hasFlag","FourTaipingInvoked") then
					if not hasManjuanEffect(enemy) then
						if q(enemy,"isKongcheng") and not q(enemy,"hasSkill","kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if q(self.player,"hasSkill","tianyi") and not q(self.player,"hasUsed","TianyiCard") then
				flag = true
			elseif q(self.player,"hasSkill","xianzhen") and not q(self.player,"hasUsed","XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = call(self,"getMaxCard",self.player) --最大点数的手牌
				if q(maxCard,"getNumber") > q(card,"getNumber") then --可以保证拼点成功
					sort_players(self,targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if q(self.player,"canSlash",enemy, nil, false, 0) then --可以发动天义或陷阵
								use.card = card
								--call(self,"setStrategyPlayerFlag",enemy,"AI_HuangtianPindian",true)
								if use.to then
									call(use.to,"append",enemy)
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
	if tos[1]:isKongcheng() and ((q(from,"hasSkill","tianyi") and not q(from,"hasUsed","TianyiCard"))
								or (q(from,"hasSkill","xianzhen") and not q(from,"hasUsed","XianzhenCard"))) then
	else
		call(self,"updateIntention",from, tos[1], -80)
	end
end

sgs.ai_use_priority["#FourTaiping_Card"] = 10
sgs.ai_use_value["#FourTaiping_Card"] = 8.5




local DiyJisu_skill = {}
DiyJisu_skill.name = "DiyJisu"
table.insert(package_skills, DiyJisu_skill)
DiyJisu_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self,"getCardsNum","Slash") > 0 then
        for i = 0, q(self.player,"getPile","turn"):length() - 1, 1 do
            local snatch = disclosed(self,q(self.player,"getPile","turn"):at(i))
            local snatch_str = ("analeptic:DiyJisu[%s:%s]=%d"):format(q(snatch,"getSuitString"), q(snatch,"getNumberString"), q(self.player,"getPile","turn"):at(i))
            local suit = q(snatch,"getSuitString")
            local number = q(snatch,"getNumberString")
            local card_id = q(snatch,"getEffectiveId")
            local card_str = ("analeptic:DiyJisu[%s:%s]=%d"):format(suit, number, card_id)
            local snatch = parse(self,request,card_str)
            assert(snatch)
            return snatch
        end
    end
end

sgs.ai_view_as.DiyJisu = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial and q(player,"getPileName",card_id) == "turn" then
		return material(card,"analeptic","DiyJisu")
	end
end



local DiyXX_skill = {}
DiyXX_skill.name = "DiyXX"
table.insert(package_skills, DiyXX_skill)
DiyXX_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self,"needBear") and not q(self.player,"hasUsed","#DiyXX_Card") then
		return parse(self,request,"#DiyXX_Card:.:")
	end
end
sgs.ai_skill_use_func["#DiyXX_Card"] = function(card,use,self,request)
	sort_players(self,self.enemies, "chaofeng")
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getMark","DiyXX_Play") == 0 then
			if q(enemy,"isKongcheng") then continue end
			table.insert(enemys, enemy)
		end	
	end
	
	if #enemys > 0 then
		use.card = final_parse(self,request,"#DiyXX_Card:.:")
		if use.to then call(use.to,"append",enemys[1]) end
	end
end

sgs.ai_use_priority["DiyXX_Card"] = 8

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
