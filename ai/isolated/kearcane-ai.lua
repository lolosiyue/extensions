-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local values=table.pack(object[method](object,...))
    if AIUnsupported.is(values[1]) then error(values[1],0) end
    return table.unpack(values,1,values.n)
end
local function q(object,method,...)
    local values=table.pack(call(object,method,...))
    if values[1]==nil then ai_unsupported("package input is unknown",method) end
    return table.unpack(values,1,values.n)
end
local function dummy(is_dummy,extra,current)
 local u=AIUsePlan.new();u.isDummy=is_dummy~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u
end
local function reuse(self,card,request)
 if q(self,"isReadonlyTurnConversion",card)then return card end
 if not q(card,"isStrategySeed")then ai_unsupported("source seed identity unavailable","kearcane.seed")end
 local skill=q(card,"getSourceSkillName")
 local selector="#"..q(card,"objectName")
 return q(self,"inheritLegacyCardIdentity",q(self,"bindSkillCard",skill,{},request,nil,selector),card)
end
local function response(self,skill,selector,names,request)
 if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
 local u=AIUsePlan.new();u.card=q(self,"bindSkillCard",skill,{},request,nil,selector);u.to=AIList.new({})
 for _,name in ipairs(names)do call(u.to,"append",q(self.room,"findPlayerByObjectName",name))end;return q(u,"toAnswer")
end
local function role(self,p)
 local value=call(p,"getRole");if value~=nil then return value end
 return q(self,"useKnowledgeEstimate",{value=q(self,"getRoleEstimate",p),status="estimate",basis="kearcane.unrevealed_role_viewer_estimate",target=q(p,"objectName")},"kearcane.role")
end

--金克丝
sgs.ai_skill_playerchosen.kejinxmark = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if q(theweaktwo,"isEmpty") then
			call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (q(pp,"getHp") < q(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				call(theweaktwo,"append",qq)
			end
		end
	end
	if q(theweaktwo,"length") > 0 then
	    return q(theweaktwo,"at",0)
	end
	return nil
end

sgs.ai_playerchosen_intention.kejinxmark = 50

sgs.ai_fill_skill.jinxchange=function(self,inclusive,request)
	return q(self,"legacySkillSeed","jinxchange","#jinxchangeCard",request)
end

sgs.ai_skill_use_func["#jinxchangeCard"] = function(card,use,self,request)
	local slash_num = q(self,"getCardsNum","Slash")
	if slash_num > 1 and q(self.player,"getStrategyMark","@jinxcannon")>0 then
		use.card = reuse(self,card,request)
	elseif slash_num == 1 and q(self.player,"getStrategyMark","@jinxgun")>0 then
		use.card = reuse(self,card,request)
	end
end
sgs.ai_use_priority.jinxchangeCard = 9.5

sgs.ai_skill_playerchosen.kejintuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then
			call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if q(theweaktwo,"isEmpty") then
			call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (q(pp,"getHp") < q(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				call(theweaktwo,"append",qq)
			end
		end
	end
	if q(theweaktwo,"length") > 0 then
	    return q(theweaktwo,"at",0)
	end
	return nil
end
sgs.ai_playerchosen_intention.kejintuo = -50



sgs.ai_fill_skill.kefanmao=function(self,inclusive,request)
	if q(self.player,"hasUsed","kefanmaoCard") then return end
	return q(self,"legacySkillSeed","kefanmao","#kefanmaoCard",request)
end

sgs.ai_skill_use_func["#kefanmaoCard"] = function(card,use,self,request)
    if (q(self.player,"getStrategyMark","@hexstone")>=2) and not q(self.player,"hasUsed","#kefanmaoCard") then
        call(self,"sort",self.friends)
		for _, friend in ipairs(self.friends) do
			if q(self,"isFriend",friend) and (q(self.player,"objectName") ~= q(friend,"objectName") ) then
				use.card = reuse(self,card,request)
				if use.to then call(use.to,"append",friend) end
				return
			end
		end
	end
end

sgs.ai_use_value.kefanmaoCard = 8.5
sgs.ai_use_priority.kefanmaoCard = 9.5
sgs.ai_card_intention.kefanmaoCard = 80

sgs.ai_skill_invoke["flydoorswapback-ask"] = function(self, data)
	return true
end

sgs.ai_skill_invoke.kebengneng = function(self, data)
	local target = call(data,"toPlayer")
	return q(self,"doDisCard",target, "h")
end

sgs.ai_ajustdamage_from.kebengneng = function(self, from, to, card, nature)
    if card and q(card,"isKindOf","Slash") and q(card,"isRed")
    then
        return 1
    end
end


sgs.ai_skill_invoke.kechetan = function(self, data)
	local target = call(data,"toPlayer")
	if not q(self,"isFriend",target) and q(self,"doDisCard",target, "h") then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kechetan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,50) end
	end
end


sgs.ai_ajustdamage_from.kejingwen = function(self, from, to, card, nature)
    if card and q(card,"isKindOf","Slash") and (q(from,"getStrategyMark","@kebaotou") > 0)
    then
        return 1
    end
end

--vi

sgs.ai_fill_skill.keyuji=function(self,inclusive,request)
	if q(self.player,"hasUsed","keyujiCard") then return end
	return q(self,"legacySkillSeed","keyuji","#keyujiCard",request)
end

sgs.ai_skill_use_func["#keyujiCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 0 and (q(enemy,"getHp")+q(enemy,"getHp")+q(enemy,"getHandcardNum")) < (q(self.player,"getHp")+q(self.player,"getHp")+q(self.player,"getHandcardNum")) and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, nil, self.player) and not q(enemy,"getStrategyFlag","yujichosen") and q(self.player,"inMyAttackRange",enemy) then
			use.card = reuse(self,card,request)
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_use_value.keyujiCard = 8.5
sgs.ai_use_priority.keyujiCard = 9.5
sgs.ai_card_intention.keyujiCard = 80

sgs.ai_skill_invoke.kegonghuan = function(self, data)
	local target = call(data,"toPlayer")
	if q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kegonghuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-80) end
	end
end

sgs.ai_skill_choice["hitvi"] = function(self, choices, data)
	local items = q(choices,"split","+")
	local target = call(data,"toPlayer")
	local duel=q(self,"evaluateSkillCard","kevioletspace","duel",{})
	local dummy_use = q(self,"aiUseCard",duel, dummy(true, 0, q(self.room,"getOtherPlayers",target)))
	if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",target) then
		return "juedou"
	end
	
	return "slash"
end

sgs.ai_skill_choice.kechupan = function(self, choices, data)
	local use = q(data,"toCardUse")
	if use.from then
		if q(self,"isFriend",use.from) and q(self,"damageIsEffective",use.from, sgs.DamageStruct_Normal, self.player)
			and q(self,"needToLoseHp",use.from,self.player,nil) then
			return "damage"
		end
		if q(self,"isEnemy",use.from) and q(self,"damageIsEffective",use.from, sgs.DamageStruct_Normal, self.player)
			and not q(self,"needToLoseHp",use.from,self.player,nil) and not q(self,"cantbeHurt",use.from) then
			return "damage"
		end
	end
	return "cancel"
end

sgs.ai_skill_invoke.kechupan = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(self,"isFriend",use.from) then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.kechupan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if q(theweaktwo,"isEmpty") then
			call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (q(pp,"getHp") < q(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				call(theweaktwo,"append",qq)
			end
		end
	end
	if q(theweaktwo,"length") > 0 then
	    return q(theweaktwo,"at",0)
	end
	return nil
end

sgs.ai_skill_discard.kesilang = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	--if q(self.player,"getStrategyFlag","wantusepaomu") then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	--else
	   -- return q(self,"askForDiscard","dummyreason", 999, 999, true, true)
	--end
end

sgs.ai_skill_playerchosen.kesilang = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then
			call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if q(theweaktwo,"isEmpty") then
			call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (q(pp,"getHp") < q(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				call(theweaktwo,"append",qq)
			end
		end
	end
	if q(theweaktwo,"length") > 0 then
	    return q(theweaktwo,"at",0)
	end
	return nil
end
sgs.ai_playerchosen_intention.kesilang = -50


sgs.ai_ajustdamage_to["@besilanged"] = function(self, from, to, card, nature)
	if not q(to,"hasSkill","kesilang") then
		return q(to,"getStrategyMark","@besilanged")
	end
end


ai_skill_use["@@ketinghu"] = function(self,prompt,request)
	local x = q(self.player,"getMaxHp") - 1
	local targets = {}
	for _,p in ipairs(self.friends) do
		if #targets >= x then
			break
		end
		if q(p,"getStrategyMark","&beketinghu+to+#"..q(self.player,"objectName")) == 0 then table.insert(targets, q(p,"objectName")) end
	end
	if #targets > 0 then
		return response(self,"ketinghu","#ketinghuCard",targets,request)
	end
end

sgs.ai_card_intention.ketinghuCard = -80

sgs.ai_skill_choice.vander_choice = function(self, choices, data)
	local items = q(choices,"split","+")
	if q(self.player,"getStrategyMark","&usetinghu") > q(self.player,"getHp")+q(self,"getAllPeachNum") then
		return "losemaxhp"
	end
	return items[math.random(1,#items)]
end
 

sgs.ai_skill_invoke.keblood = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(use.from,"objectName") == q(self.player,"objectName") then
		if q(self,"isFriend",q(use.to,"first")) then
			return false
		end
	end
	if use.from and q(use.from,"objectName") ~= q(self.player,"objectName") then
		if q(self,"isFriend",use.from) then
			return false
		end
	end
	return true
end
sgs.ai_skill_invoke.kebloodangry = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(use.from,"objectName") == q(self.player,"objectName") then
		if q(self,"isFriend",q(use.to,"first")) then
			return false
		end
	end
	if use.from and q(use.from,"objectName") ~= q(self.player,"objectName") then
		if q(self,"isFriend",use.from) then
			return false
		end
	end
	return true
end

local killaround_targets
sgs.ai_skill_invoke.killaround = function(self, data)
	return (q(self.player,"getHandcardNum") < 4 or q(self.player,"getLostHp") > 1) and killaround_targets(self, "") ~= "."
end
killaround_targets = function(self,prompt)
	local slash=q(self,"evaluateSkillCard","killaround","slash",{})
	local dummy_use = q(self,"aiUseCard",slash, dummy(true, q(self.player,"getLostHp") - 1))
	if dummy_use.to and q(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, q(to,"objectName"))
        end
        return tos
    end
	return "."
end

ai_skill_use["@@killaround"]=function(self,prompt,request)
 local names=killaround_targets(self,prompt);if names=="."then return "."end
 return response(self,"killaround","#killaroundCard",names,request)
end

sgs.ai_use_revises.killaround = function(self,card,use)
	if q(card,"isKindOf","Slash") and table.contains(q(self,"cardSkillNamesKnowledge",card,"killaround.skill_names"), "killaround") then
		call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_fill_skill.keduantou_extra=function(self,inclusive,request)
	return q(self,"legacySkillSeed","keduantou_extra","#keduantouCard",request)
end

sgs.ai_fill_skill.keduantou=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	local to_discard = {}
	call(self,"sortByUseValue",cards)
	local first_found, second_found = false, false
	local first_card, second_card
	for _, fcard in ipairs(cards) do
		first_card = fcard
		first_found = true
		for _, scard in ipairs(cards) do
			if not AIValue.sameLegacyIdentity(first_card,scard) then
				second_card = scard
				second_found = true
				table.insert(to_discard, q(fcard,"getEffectiveId"))
				table.insert(to_discard, q(scard,"getEffectiveId"))
				break
			end
		end
		if second_card then break end
	end
	local card_str = string.format("#keduantouCard:%s:", table.concat(to_discard, "+"))
	return q(self,"evaluateTurnSkillCard","keduantou","#keduantouCard",to_discard,request)
end

sgs.ai_skill_use_func["#keduantouCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, nil, self.player) and q(enemy,"getStrategyMark","@shixue") >= 5 and q(enemy,"getHp") + q(self,"getAllPeachNum",enemy) <= 2 and q(self.player,"distanceTo",enemy) <= 1 then
			use.card = reuse(self,card,request)
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
	for _,enemy in sgs.list(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, nil, self.player) and q(enemy,"getHp") + q(self,"getAllPeachNum",enemy) <= 1 and q(self.player,"distanceTo",enemy) <= 1 then
			use.card = reuse(self,card,request)
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
	if q(self.player,"hasSkill","keduantou_extra") then
		for _,enemy in sgs.list(self.enemies) do
			if q(self,"damageIsEffective",enemy, nil, self.player) and q(self.player,"distanceTo",enemy) <= 1 then
				use.card = reuse(self,card,request)
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keduantouCard = 8.5
sgs.ai_use_priority.keduantouCard = 9.5
sgs.ai_card_intention.keduantouCard = 80

sgs.ai_fill_skill.kebeilian=function(self,inclusive,request)
	if q(self.player,"hasUsed","kebeilianCard") then return end
	return q(self,"legacySkillSeed","kebeilian","#kebeilianCard",request)
end

sgs.ai_skill_use_func["#kebeilianCard"] = function(card,use,self,request)
	call(self,"sort",self.friends)
	for _, friend in ipairs(self.friends_noself) do
		if q(self,"isFriend",friend) and q(friend,"getStrategyMark","@shixue") > 0 then
			use.card = reuse(self,card,request)
			if use.to then call(use.to,"append",friend) end
			return
		end
	end
end
sgs.ai_card_intention.kebeilianCard = -80

--garen
sgs.ai_skill_invoke.kezhengyi = function(self, data)
	local target = call(data,"toPlayer")
	if target then
		if q(self,"isEnemy",target) and q(self,"isWeak",target) and q(target,"getHp") + q(self,"getAllPeachNum",target) - q(target,"getLostHp") < 1 and not q(self,"cantDamageMore",self.player, target) and q(self,"damageIsEffective",target, sgs.DamageStruct_Thunder, self.player) then
			return true
		end
	end
	return false
end

sgs.ai_fill_skill.kehaojin=function(self,inclusive,request)
	if q(self.player,"hasUsed","kehaojinCard") then return end
	--if (q(self.player,"getStrategyMark","kechengzhengbing-Clear") >= 3) or (q(self.player,"getKingdom") ~= "qun") or (q(self.player,"isKongcheng")) then return end
	local card_id
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		call(to_throw,"append",q(acard,"getEffectiveId"))
	end
	card_id = q(to_throw,"at",0)--(q(to_throw,"length")-1)
	if not card_id then
		return nil
	else
		return q(self,"evaluateTurnSkillCard","kehaojin","#kehaojinCard",{card_id},request)
	end
end

sgs.ai_skill_use_func["#kehaojinCard"] = function(card,use,self,request)
	local slashcount = q(self,"getCardsNum","Slash")
	if slashcount > 0 then
		local slash = call(self,"getCard","Slash")
		if slash then
			assert(slash)
			local dummy_use = q(self,"aiUseCard",slash, dummy())
			if dummy_use.card and dummy_use.to then
				if not q(dummy_use.to,"isEmpty") then
					use.card = reuse(self,card,request)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.kehaojinCard = 8.5
sgs.ai_use_priority.kehaojinCard = 3
sgs.ai_card_intention.kehaojinCard = -80

--lux

sgs.ai_fill_skill.keguangfu=function(self,inclusive,request)
	if q(self.player,"hasUsed","keguangfuCard") then return end
	return q(self,"legacySkillSeed","keguangfu","#keguangfuCard",request)
end

sgs.ai_skill_use_func["#keguangfuCard"] = function(card,use,self,request)
    if not q(self.player,"hasUsed","#keguangfuCard") then
        call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		if q(self.player,"hasSkill","kelux_r") then
			for _, enemy in ipairs(self.enemies) do
				if q(self.player,"canPindian",enemy,true) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire, self.player) and not q(self,"cantbeHurt",enemy) then
					use.card = reuse(self,card,request)
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
		local max_card = call(self,"getMaxCard")
		local max_point = q(max_card,"getNumber")
		for _,enemy in ipairs(self.enemies) do
			if q(self.player,"canPindian",enemy) then
				local enemy_max_card = call(self,"getMaxCard",enemy)
				local enemy_max_point = enemy_max_card and q(enemy_max_card,"getNumber") or 100
				if enemy_max_card and q(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
				if max_point>enemy_max_point or max_point>10 then
					use.card = reuse(self,card,request)
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keguangfuCard = 8.5
sgs.ai_use_priority.keguangfuCard = 9.5
sgs.ai_card_intention.keguangfuCard = 80

sgs.ai_skill_playerchosen.kequguang = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then
			call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if q(theweaktwo,"isEmpty") then
			call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (q(pp,"getHp") < q(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				call(theweaktwo,"append",qq)
			end
		end
	end
	if q(theweaktwo,"length") > 0 then
	    return q(theweaktwo,"at",0)
	end
	return nil
end

sgs.ai_card_intention.kequguang = -80

sgs.ai_fill_skill.playmovesoldier=function(self,inclusive,request)
	if q(self.player,"hasUsed","playmovesoldierCard") then return end
	return q(self,"legacySkillSeed","playmovesoldier","#playmovesoldierCard",request)
end

sgs.ai_skill_use_func["#playmovesoldierCard"] = function(card,use,self,request)
    if not q(self.player,"hasUsed","#playmovesoldierCard") then
        call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if (q(enemy,"getStrategyMark","@sandsoldier") == 0) then
				if q(enys,"isEmpty") then
					call(enys,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (q(enemy,"getHp")+q(enemy,"getHp")+q(enemy,"getHandcardNum")) >= (q(p,"getHp")+q(p,"getHp")+q(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						call(enys,"removeOne",q(enys,"at",0))
						call(enys,"append",enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if q(self,"objectiveLevel",enemy) > 0 then
			    use.card = reuse(self,card,request)
			    if use.to then call(use.to,"append",enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.playmovesoldierCard = 8.5
sgs.ai_use_priority.playmovesoldierCard = 9.5
sgs.ai_card_intention.playmovesoldierCard = 80


sgs.ai_skill_invoke.azirslash = function(self, data)
	local use = q(data,"toCardUse")
	for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do        
		if (q(p,"getStrategyMark","@sandsoldier") > 0) then
			local dummy_use = q(self,"aiUseCard",use.card, dummy(true, 99, q(self.room,"getOtherPlayers",p)))
			if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",p) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.playmovesoldier = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.playmovesoldier = function(self, targets)
	targets = sgs.QList2Table(targets)
	call(self,"sort",targets, "defense")
	if q(self,"isWeak") then
		local min = 999
		for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(p,"getHp") < min and not (q(p,"getGeneralName") == "kesolardisk" or q(p,"getGeneral2Name") == "kesolardisk") then
				min = q(p,"getHp")
			end
		end
		if q(self.player,"getHp") <= min then
			return self.player
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return self.player
end


sgs.ai_event_callback[sgs.CardFinished].azirshenjiCard = function(self, player, data)
 local use=q(data,"toCardUse")
 if use.card and q(use.card,"objectName")=="azirshenjiCard" then
  local room=q(player,"getRoom")
  -- The witness is the public board: each head general must be disclosed, and
  -- the solar disk's role revealed.
  for _,sb in sgs.qlist(q(room,"getOtherPlayers",player))do
   local name=sb:getGeneralName()
   if q(sb,"objectName")~=q(self.player,"objectName") and (type(name)~="string" or name=="" or name=="anjiang")then
    ai_unsupported("Source-ordered public head witness unavailable","kearcane.azirshenji.head")
   end
   if name=="kesolardisk" then
    local role=q(sb,"hasShownRole") and q(sb,"getRole")
    if not ({lord=true,loyalist=true,rebel=true,renegade=true})[role]then
     ai_unsupported("Solar disk role has not been publicly revealed","kearcane.azirshenji.role")
    end
    self:emitStrategyEffect({kind="azirshenji_role",player=q(sb,"objectName"),role=role})
   end
  end
 end
end

sgs.ai_fill_skill.azirshenji=function(self,inclusive,request)
	if q(self.player,"getStrategyMark","@azirshenji") == 0 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(q(self.room,"getPlayers")) do
		if q(p,"isDead") and ((role(self,p) == q(self.player,"getRole"))
		 or (role(self,p) == "loyalist" and q(self.player,"isLord"))) then
			table.insert(deathplayer,q(p,"getGeneralName"))
		end
	end
	if #deathplayer==0 then return end
	return q(self,"legacySkillSeed","azirshenji","#azirshenjiCard",request)
end

sgs.ai_skill_use_func["#azirshenjiCard"] = function(card,use,self,request)
	use.card = reuse(self,card,request)
end

sgs.ai_use_value["#azirshenjiCard"] = 8
sgs.ai_use_priority["#azirshenjiCard"] = 9.5



sgs.ai_skill_choice["shenji-ask"] = function(self, choices, data)
	local items = q(choices,"split","+")
	table.removeOne(items, "cancel")
	return items[math.random(1,#items)]
end
