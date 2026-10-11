-- Fixed ck-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("ck policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("ck policy helper unavailable",method) end
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
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function response_names(self,skill,class,names)
    local targets={}
    for _,name in ipairs(names)do targets[#targets+1]=q(self.room,"findPlayerByObjectName",name)end
    return response(self,skill,class,{},targets)
end
local function context(self,key) return known(q(self,"getDecisionContext")[key],"ck.context."..key) end
local function dummy(is_dummy,extra,targets)
    local use=AIUsePlan.new();use.isDummy=is_dummy~=false;use.extra_target=extra or 0;use.current_targets=targets or {};return use
end
local function visible_role(self,player)
    local role=call(player,"getRole")
    if role~=nil then return role end
    role=q(self,"getRoleEstimate",player)
    return q(self,"useKnowledgeEstimate",{status="estimate",value=role,basis="viewer_role_estimate_private_role",player=q(player,"objectName")},"ckxueni.role")
end
sgs.ai_ajustdamage_to.ckleiti = function(self,from,to,card,nature)
	if nature == sgs.DamageStruct_Thunder
	then return -99 end
end

sgs.ai_can_damagehp.ckleiti = function(self,from,card,to)
    if card then
        local nature = sgs.card_damage_nature[q(card,"getClassName")] or sgs.DamageStruct_Normal
        if nature == sgs.DamageStruct_Thunder
        then
            return true
        end
    end
end

local ckdianji_skill = {}
ckdianji_skill.name= "ckdianji"
table.insert(package_skills,ckdianji_skill)
ckdianji_skill.getTurnUseCard=function(self,inclusive,request)
    if not q(self.player,"canDiscard",self.player, "he") then return end
	return seed(self,"ckdianji","#ckdianjicard",request)
end

sgs.ai_skill_use_func["#ckdianjicard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
    sort_players(self,self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder, self.player) and q(self,"canDamage",enemy,self.player,nil) then
            use.card = bind(self,"ckdianji","#ckdianjicard",{q(cards[1],"getEffectiveId")},request)
            call(use.to,"append",enemy)
            return
        end
    end
    if q(self.player,"getHp")<getBestHp(self.player) and q(self.player,"hasSkill","ckleiti") then
        use.card = bind(self,"ckdianji","#ckdianjicard",{q(cards[1],"getEffectiveId")},request)
        call(use.to,"append",self.player)
        return
    end
    local target = call(self,"findBestDamageTarget",1, "T", 0, nil)
    if target then
        use.card = bind(self,"ckdianji","#ckdianjicard",{q(cards[1],"getEffectiveId")},request)
        call(use.to,"append",target)
        return
    end
end

sgs.ai_use_value["ckdianjicard"] = 2.5
sgs.ai_card_intention["ckdianjicard"] = 80
sgs.dynamic_value.damage_card["ckdianjicard"] = true


local ckluolei_skill = {}
ckluolei_skill.name = "ckluolei"
table.insert(package_skills, ckluolei_skill)
ckluolei_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"getMark","@thunder") <= 0 then return end
	if q(self.room,"getMode") == "_mini_13" then return nil -- Fixed Card_Parse has no ck luolei prototype (no alias repair).
    end
	local good, bad = 0, 0
	local lord = call(self.room,"getLord")
	if lord and self.role ~= "rebel" and q(self,"isWeak",lord) then return end
	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"isWeak",player) then
			if q(self,"isFriend",player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		local hp = math.max(q(player,"getHp"), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if q(self,"isFriend",player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		if q(self,"damageIsEffective",player, sgs.DamageStruct_Thunder, self.player) then
			local lost_value = 0
			if q(self,"hasSkills",sgs.masochism_skill, player) then lost_value = q(player,"getHp")/2 end
			local hp = math.max(q(player,"getHp"), 1)
			if q(self,"isFriend",player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad and q(self,"isWeak") and self:getHandcardNum() < 4 then return seed(self,"ckluolei","#ckluoleicard",request) end
end

sgs.ai_skill_use_func["#ckluoleicard"]=function(card,use,self,request)
	use.card = q(self,"inheritLegacyCardIdentity",bind(self,"ckluolei","#ckluoleicard",{},request),card)
end

sgs.dynamic_value.damage_card["#ckluoleicard"] = true

local cksilie_skill = {}
cksilie_skill.name = "cksilie"
table.insert(package_skills,cksilie_skill)
cksilie_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"isKongcheng") then return nil end
	return seed(self,"cksilie","#cksiliecard",request)
end

sgs.ai_skill_use_func["#cksiliecard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_use(self,cards,true)
	sort_players(self,self.enemies,"defense")
	if q(self,"getOverflow")<=0 then return end
	q(self,"setPriorityValue","cksiliecard",0.2,"ck.cksilie")
	local suit_table = { "spade","club","heart","diamond" }
	local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHandcardNum")>2 and q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and q(self,"canDamage",enemy,self.player,nil) then
			local max_suit_num,max_suit = 0,{}
			for i = 0,3,1 do
				local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
				for j = 0,4,1 do
					if call(enemy,"getEquip",j) and q(call(enemy,"getEquip",j),"getSuit")==i then
						local val = equip_val_table[j+1]
						if j==1 and q(self,"needToThrowArmor",enemy) then val = -0.5
						else
							if q(enemy,"hasSkills",sgs.lose_equip_skill) then val = val/8 end
							if q(call(enemy,"getEquip",j),"getEffectiveId")==call(self,"getValuableCard",enemy) then val = val*1.1 end
							if q(call(enemy,"getEquip",j),"getEffectiveId")==call(self,"getDangerousCard",enemy) then val = val*1.1 end
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
					if sgs[q(skill,"objectName").."_suit_value"] then
						for i = 1,4,1 do
							local v = sgs[q(skill,"objectName").."_suit_value"][suit_table[i]]
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
				if q(self,"getUseValue",card)<6 and table.contains(max_suit,q(card,"getSuit")) then
					use.card = bind(self,"cksilie","#cksiliecard",{q(card,"getEffectiveId")},request)
					call(use.to,"append",enemy)
					return
				end
			end
			if getCardsNum("Peach",enemy,self.player)<2 then
				for _,card in ipairs(cards)do
					if q(self,"getUseValue",card)<6 and not q(self,"isValuableCard",card) then
						use.card = bind(self,"cksilie","#cksiliecard",{q(card,"getEffectiveId")},request)
						call(use.to,"append",enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["cksiliecard"] = 60

sgs.ai_use_priority["cksiliecard"] = 0.2

sgs.ai_skill_use["@@ckbaihe"] = function(self,prompt)
    sort_players(self,self.friends,"defense")
    for _,friend in ipairs(self.friends)do
        if q(self,"doDisCard",friend, "e") then
            return response(self,"ckbaihe","#ckbaihecard",{}, {friend})
        end
    end
    for _,friend in ipairs(self.friends)do
        if q(friend,"hasEquip") and q(self.player,"canDiscard",friend, "e") and q(self,"isWeak",friend) then
            return response(self,"ckbaihe","#ckbaihecard",{}, {friend})
        end
    end
	return "."
end

sgs.ai_ajustdamage_from.ckdalian = function(self,from,to,card,nature)
	if from and q(from,"distanceTo",to)<=1 and not beFriend(to,from)
	then return 1 end
end

sgs.ai_skill_invoke.ckdalian = function(self, data)
    local target = call(data,"toPlayer")
    if target and q(self,"isFriend",target) then return false end
	return true
end

sgs.ai_target_revises.ckhuansha = function(to,card)
	if q(card,"getTypeId")==sgs.Card_TypeSkill or q(card,"getSkillName")~="" or q(card,"isVirtualCard") or q(card,"isKindOf","SkillCard")
	then return true end
end
sgs.ai_target_revises.ckshiliang = function(to,card)
	if q(to,"getMark","ckshiliang-Clear") == 0
	then return true end
end

sgs.ai_skill_use["@@ckshiliang"] = function(self,prompt)
    local parsed = q(prompt,"split",":")
    local use = context(self,"use")
    if parsed[1]=="@ckshiliangCard" then
        if use then
            local card = use.card
            local dummy_use = q(self,"aiUseCard",card, dummy(true, 0, use.to))
			if dummy_use.card and dummy_use.to then
                for _,p in sgs.qlist(dummy_use.to)do
                    return response(self,"ckshiliang","#ckshiliangcard",{}, {p})
                end
            end
        end
    else
        if use.from and q(self,"isEnemy",use.from) then
            for _, enemy in ipairs(self.enemies) do
                return response(self,"ckshiliang","#ckshiliangcard",{}, {enemy})
            end
        end
	end
	return "."
end

sgs.ai_skill_invoke.ckxueni = function(self, data)
    local target = call(data,"toPlayer")
    if target  then 
        if q(self,"isEnemy",target) then
			return true
		end
        if q(self,"isFriend",target) and visible_role(self,target) == "rebel" then
			for _, friend in ipairs(self.friends) do
				if getKnownCard(friend, self.player, "Peach", true, "h") > 0 then return false end
				if q(friend,"getHandcardNum") > 3 then return false end
			end
            return true
		end
    end
    return false
end

sgs.ai_skill_invoke.ckyongchang = function(self, data)
	local effect = context(self,"effect")
    local dest = effect.to
    if dest and q(self,"isEnemy",dest) then return false end
	if effect.card and q(effect.card,"hasFlag","NosJiefanUsed") then return false  end

	if not effect.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)
		or q(effect.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",dest,effect.card,effect.from)
		or q(self,"needToLoseHp",dest,effect.from,effect.card) and q(self,"ajustDamage",effect.from,dest,1,effect.card)==1 then return false end
	if q(self,"needToLoseHp",dest, effect.from,effect.card, true, true) then return false end
	if q(self,"getCardsNum","Jink") == 0 then return true end
	
	return true
end

sgs.ai_choicemade_filter.skillInvoke.ckyongchang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

local cklongxi_skill = {}
cklongxi_skill.name= "cklongxi"
table.insert(package_skills,cklongxi_skill)
cklongxi_skill.getTurnUseCard=function(self,inclusive,request)
	return seed(self,"cklongxi","#cklongxicard",request)
end

sgs.ai_skill_use_func["#cklongxicard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
    sort_players(self,self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and not q(self,"cantDamageMore",self.player, enemy) and (q(enemy,"getHp") <= 3 or q(self,"isWeak")) and q(self,"canDamage",enemy,self.player,nil) then
            use.card = bind(self,"cklongxi","#cklongxicard",{},request)
            call(use.to,"append",enemy)
            return
        end
    end
    local target = call(self,"findBestDamageTarget",3, "N", 0, nil)
    if target then
        use.card = bind(self,"cklongxi","#cklongxicard",{},request)
        call(use.to,"append",target)
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
ckweishan_skill.getTurnUseCard=function(self,inclusive,request)
	return seed(self,"ckweishan","#ckweishancard",request)
end

sgs.ai_skill_use_func["#ckweishancard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
    sort_players(self,self.enemies)
    local use_cards = {}
    local types = {}
    
	for _,c in ipairs(cards) do
		if not table.contains(types, q(c,"getTypeId"))  then
            table.insert(types, q(c,"getTypeId"))
            table.insert(use_cards, q(c,"getEffectiveId"))
		end
	end
    if #use_cards < 3 then return end

	local enemies = q(self,"findPlayerToDamage",3, self.player, "N")
	enemies = table.filter(enemies, function(p) return not q(self,"cantDamageMore",self.player, p) end)
	for _,enemy in ipairs(enemies) do
		use.card = bind(self,"ckweishan","#ckweishancard",use_cards,request)
        call(use.to,"append",enemy)
        return
	end
    local target = call(self,"findBestDamageTarget",3, "N", 0, nil)
    if target then
        use.card = bind(self,"ckweishan","#ckweishancard",use_cards,request)
        call(use.to,"append",target)
        return
    end
end

sgs.ai_use_value["ckweishancard"] = 2.5
sgs.ai_card_intention["ckweishancard"] = 80
sgs.dynamic_value.damage_card["ckweishancard"] = true

sgs.ai_skill_use["@@ckjinjie"] = function(self,prompt)
    local targets = {}
    table.insert(targets, q(self.player,"objectName"))
    sort_players(self,self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if #targets < 3 then
            table.insert(targets, q(friend,"objectName"))
            break
        end
    end
    sort_players(self,self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 and not q(self.player,"inMyAttackRange",enemy) then
            table.insert(targets, q(enemy,"objectName"))
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 then
            table.insert(targets, q(enemy,"objectName"))
        end
    end
    if #targets > 0 then
        return response_names(self,"ckjinjie","#ckjinjieCard",targets)
    end
    return "."
end
for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
