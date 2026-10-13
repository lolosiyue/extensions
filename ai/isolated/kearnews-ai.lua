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
local function getYongdiTarget(self,targets)
 if type(self.getYongdiTarget)=="function"then return call(self,"getYongdiTarget",targets)end
 ai_unsupported("source getYongdiTarget general/lord-skill capability unavailable","kearnews.kexihuo.yongdi")
end
local function spec(name,skill,c)return{name=name,skill=skill,suit=q(c,"getSuit"),number=q(c,"getNumber"),subcards={q(c,"getEffectiveId")}}end
local function dummy(value,extra)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;return u end
local function analeptic_available(self,card)
 -- Analeptic::IsAvailable without a card is a native rule answer that is not projected.
 if not card then ai_unsupported("source static Analeptic availability is not projected","kearnews.analeptic_available")end
 local v=card._view and card._view.source_analeptic_available;if type(v)~="boolean"then ai_unsupported("source clone Analeptic availability unknown","kearnews.analeptic_available")end;return v
end
-- Own tags are projected; the keceyin/kenewmieyao room tags are not. A discard ask
-- carries no data, so its context damage is the CurrentDamageStruct room tag.
local function fact(self,key,standard)
 if standard and key=="current_damage"then
  local damage=self:getDecisionContext().damage
  if damage==nil then return{}end -- absent tag: the donor's default struct has no from/to
  for _,k in ipairs({"from","to"})do if damage[k.."_name"]==""then damage[k]=nil end end
  return damage
 end
 if standard or key~="newhujiaaDamage"then ai_unsupported("room tag is not projected","kearnews."..key)end
 local raw=self.player:getTag(key)
 if raw==nil then return{}end -- the donor's toDamage() default has no from/card
 local d={};for k,v in pairs(raw)do d[k]=v end
 for _,k in ipairs({"from","to"})do if type(d[k])=="string"then d[k]=d[k]~=""and q(self.room,"findPlayerByObjectName",d[k],true)or nil end end
 if type(d.card)=="table"then d.card=next(d.card)and CardView.new(d.card)or nil end
 return d
end
local function trigger(self,skill)
 local present=call(skill,"isTriggerSkill");if present==false then return nil end
 if present==true then return skill end
 ai_unsupported("public trigger-skill kind unknown","kearnews.trigger")
end
local function respond(self,skill,selector,costs,names,request)
 if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
 local u=AIUsePlan.new();u.card=q(self,"bindSkillCard",skill,costs,request,nil,selector)
 for _,name in ipairs(names)do u.to:append(q(self.room,"findPlayerByObjectName",name))end;return q(u,"toAnswer")
end
local function selected(self,card,names)
 local c=card
 if q(card,"isEvaluationOnly")then
  local skill=q(card,"getSkillName",false);c=q(self,"bindOriginalSelectedConversion",{name=q(card,"objectName"),skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards=q(card,"getSubcards")},q(card,"getClassName"),skill,card)
 end
 local u=AIUsePlan.new();u.card=c;for _,name in ipairs(names)do u.to:append(q(self.room,"findPlayerByObjectName",name))end;return q(u,"toAnswer")
end
--曹操

sgs.ai_skill_invoke.kejianxiong = function(self, data)
	return true
end

ai_skill_use["@@kejianxiong"]=function(self,prompt,request)
	local id = q(self.player,"getStrategyMark","kejianxiong-PlayClear") - 1
	if id < 0 then return "." end
	local card = q(self,"getPrintedCardById",id)
	if q(card,"targetFixed") then
		if q(card,"isKindOf","Peach") then
			if q(self,"isWeak") then
				return selected(self,card,{})
			end
			if q(self,"isWeak",self.friends_noself) then
				return "."
			end
			return selected(self,card,{})
		end
		if q(card,"isKindOf","EquipCard") then
			local equip_index = q(card,"getEquipSlot")
			if call(self.player,"getEquip",equip_index) == nil then
				return selected(self,card,{})
			end
		end
		if q(card,"isKindOf","AOE") then
			if q(self,"getAoeValue",card) > 0 then
				return selected(self,card,{})
			end
		end
		if q(card,"isKindOf","Analeptic") then
			return "."
		end
		if q(card,"isKindOf","ExNihilo") then
			return selected(self,card,{})
		end
	else
		local dummy_use = q(self,"aiUseCard",card, dummy())
		if dummy_use.card and not q(dummy_use.to,"isEmpty") then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, q(p,"objectName"))
			end
			if #targets > 0 then
				return selected(self,card,targets)
			end
		end
	end
	return "."
end

local function newhujiaa_target(self,prompt)
	local players = q(self.room,"getLieges","wei", self.player)
	if q(players,"length") == 0 then return "." end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target) and q(self,"isWeak",target)
		then return target end
	end
	local damage = fact(self,"newhujiaaDamage")
    for _,target in sgs.list(sgs.reverse(destlist))do
		if q(self,"isFriend",target) and not q(self,"isWeak",target)
		and q(self,"needToLoseHp",target, damage.from, damage.card)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target) and q(self,"isWeak")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target) and damage.damage > 1
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target) and q(self,"isWeak")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if q(self,"isWeak")
		then return target end
	end
	return "."
end

ai_skill_use["@@newhujiaa"]=function(self,prompt,request)
 local target=newhujiaa_target(self,prompt);if target=="."then return "."end
 return respond(self,"newhujiaa","#newhujiaaCard",{}, {q(target,"objectName")},request)
end
sgs.ai_can_damagehp.newhujiaa = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[q(card,"getClassName")] or sgs.DamageStruct_Normal
	return newhujiaa_target(self,d)~="."
end


--赵云
sgs.ai_fill_skill.kexianglong=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	for _, id in sgs.qlist(q(self.player,"getHandPile")) do
		table.insert(cards, q(self,"getKnownCardById",id))
	end
	call(self,"sortByUseValue",cards, true)

	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Analeptic") then
			return q(self,"evaluateTurnConversion","kexianglong","Peach",spec("peach","kexianglong",c),request)
		end
	end

	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Peach") then
			return analeptic_available(self) and
				q(self,"evaluateTurnConversion","kexianglong","Analeptic",spec("analeptic","kexianglong",c),request)
		end
	end

	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Jink") then
			return q(self,"evaluateTurnConversion","kexianglong","Slash",spec("slash","kexianglong",c),request)
		end
	end
end

sgs.ai_view_as.kexianglong = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand then
		if q(card,"isKindOf","Jink") then
			return spec("slash","kexianglong",card)
		elseif q(card,"isKindOf","Slash") then
			return spec("jink","kexianglong",card)
		elseif q(card,"isKindOf","Peach") then
			return spec("analeptic","kexianglong",card)
		elseif q(card,"isKindOf","Analeptic") then
			return spec("peach","kexianglong",card)
		end
	end
end
sgs.ai_card_priority.kexianglong = function(self,card)
	if table.contains(q(self,"cardSkillNamesKnowledge",card,"kearnews.kexianglong.priority"), "kexianglong")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|kexianglong"

sgs.kexianglong_keep_value = sgs.longdan_keep_value

sgs.ai_fill_skill.keliezhen=function(self,inclusive,request)
	if q(self.player,"hasUsed","keliezhenCard") then return end
	return q(self,"evaluateTurnSkillCard","keliezhen","#keliezhenCard",{},request)
end

sgs.ai_skill_use_func["#keliezhenCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#keliezhenCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if q(enys,"isEmpty") then
				call(enys,"append",enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (q(enemy,"getHp") + q(enemy,"getHp") + q(enemy,"getHandcardNum")) >= (q(p,"getHp") + q(p,"getHp") + q(p,"getHandcardNum")) then
						yes = 0
					end
				end
				if (yes == 1) then
					call(enys,"removeOne",q(enys,"at",0))
					call(enys,"append",enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if q(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keliezhenCard = 8.5
sgs.ai_use_priority.keliezhenCard = 9.5
sgs.ai_card_intention.keliezhenCard = 80

sgs.ai_skill_playerschosen.keliezhen = function(self, targets, max, min)
	local enemy = AIList.new({})
	for _, p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) then
			call(enemy,"append",p)
		end
	end
	return enemy
end

sgs.ai_skill_playerchosen.kelongxiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(self,"isWeak",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["kelongxiang"] = -80


sgs.ai_fill_skill.kechenniang=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	local card
	call(self,"sortByUseValue",cards,true)
	for _,acard in ipairs(cards)  do
		if q(acard,"isKindOf","Jink") or q(acard,"isKindOf","EquipCard")  then
			card = acard
			break
		end
	end
	if not card then return nil end
	local analeptic = q(self,"evaluateTurnConversion","kechenniang","Analeptic",spec("analeptic","kechenniang",card),request)
	assert(analeptic)
	if analeptic_available(self,analeptic)
	then return analeptic end
end

sgs.ai_view_as.kechenniang = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if q(card,"isKindOf","Jink") or q(card,"isKindOf","EquipCard") then
		return spec("analeptic","kechenniang",card)
	end
end

function sgs.ai_cardneed.kechenniang(to,card,self)
	return q(card,"isKindOf","Jink") or q(card,"isKindOf","EquipCard")
end
sgs.ai_ajustdamage_from.kechenniang = function(self, from, to, card, nature)
	return q(from,"getStrategyMark","&kechenniang-Clear")
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|kenewpaoxiao"

sgs.ai_use_revises.kenewpaoxiao = sgs.ai_use_revises.paoxiao

sgs.ai_cardneed.kenewpaoxiao = sgs.ai_cardneed.paoxiao
sgs.kenewpaoxiao_keep_value = sgs.paoxiao_keep_value


--孙尚香
ai_skill_use["@@kerongchang"]=function(self,prompt,request)
    call(self,"sort",self.enemies,"defense")
	local slash=q(self,"evaluateSkillCard","kerongchang","slash",{})
	local dummy = q(self,"aiUseCard",slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,q(p,"objectName"))
		end
		return selected(self,slash,tos)
	end
	return "."
end
sgs.ai_skill_playerchosen["kerongchang"] = function(self, targets)
	if q(self,"findPlayerToDiscard","eh", true, false, targets) ~= {} then
		return q(self,"findPlayerToDiscard","eh", true, false, targets)[1]
	end
	return nil
end

sgs.ai_cardneed.kerongchang = sgs.ai_cardneed.equip
sgs.ai_use_revises.kerongchang = function(self,card,use)
	if q(card,"isKindOf","EquipCard") and q(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end
sgs.ai_skill_playerchosen.kexiaoji = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(self,"isWeak",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(p,"getHp") < getBestHp(p) then
			return p
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kexiaojiobtain = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", true) and q(p,"getEquips"):length() > 0 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"doDisCard",p, "he", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention["kexiaoji"] = -80
sgs.ai_playerchosen_intention.kexiaojiobtain = function(self, from, to)
	if q(self,"doDisCard",to, "he", true) and q(self,"isFriend",to) then
		call(self,"updateIntention",from, to, -50)
	else
		call(self,"updateIntention",from, to, 50)
	end
end
sgs.ai_skill_choice.kexiaoji = function(self, choices, data)
	local target = call(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(target,"getHp") < getBestHp(target) then return "huixue" end
	return "shouhui"
end

--曹婴

sgs.ai_skill_discard.ketwopaomu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local damage = fact(self,"current_damage",true)
	if damage.from and damage.to then
		if ((q(self,"isFriend",damage.from) and q(self,"needToLoseHp",damage.from, self.player, nil)) or (not q(self,"cantbeHurt",damage.from) and q(self,"damageIsEffective",damage.from, sgs.DamageStruct_Fire) and q(self,"canDamage",damage.from,self.player,nil))) and ((q(self,"isFriend",damage.to) and q(self,"needToLoseHp",damage.to, self.player, nil)) or (not q(self,"cantbeHurt",damage.to) and q(self,"damageIsEffective",damage.to, sgs.DamageStruct_Fire) and q(self,"canDamage",damage.to,self.player,nil))) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end
	return to_discard
end


sgs.ai_fill_skill.kequshang=function(self,inclusive,request)
	if q(self.player,"hasUsed","kequshangCard") then return end
	return q(self,"evaluateTurnSkillCard","kequshang","#kequshangCard",{},request)
end

sgs.ai_skill_use_func["#kequshangCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#kequshangCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if q(enys,"isEmpty") then
				call(enys,"append",enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (q(enemy,"getHp") + q(enemy,"getHp") + q(enemy,"getHandcardNum")) >= (q(p,"getHp") + q(p,"getHp") + q(p,"getHandcardNum")) then
						yes = 0
					end
				end
				if (yes == 1) then
					call(enys,"removeOne",q(enys,"at",0))
					call(enys,"append",enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if q(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.kequshangCard = 8.5
sgs.ai_use_priority.kequshangCard = 9.5
sgs.ai_card_intention.kequshangCard = 80

sgs.ai_skill_invoke.kenewfengming = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target and q(self,"isFriend",target) then return false end
	return true
end


--徐庶

sgs.ai_skill_playerchosen.kexiajue = sgs.ai_skill_playerchosen.zero_card_as_slash


sgs.ai_fill_skill.kexiajuetwo=function(self,inclusive,request)
	if q(self.player,"hasUsed","kexiajuetwoCard") then return end
	return q(self,"evaluateTurnSkillCard","kexiajuetwo","#kexiajuetwoCard",{},request)
end

sgs.ai_skill_use_func["#kexiajuetwoCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	local slash=q(self,"evaluateSkillCard","_kedianzhen","slash",{})
 call(self,"setStrategyCardFlag",slash,"Qinggang",true)
	local dummy_use = q(self,"aiUseCard",slash, dummy())
	if not q(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			use.card = card
			if use.to then call(use.to,"append",p) end
			return
		end
	end
end

sgs.ai_use_value.kexiajuetwoCard = 8.5
sgs.ai_use_priority.kexiajuetwoCard = 9.5
sgs.ai_card_intention.kexiajuetwoCard = 80

sgs.ai_skill_playerchosen.kedianzhen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return q(self,"findPlayerToDiscard","he", false, false, targets, false)[1]
end

--大乔
sgs.ai_skill_invoke["keliuliqp"] = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(self,"doDisCard",use.from, "he") then return true end
	return false
end
sgs.ai_fill_skill.keguose=function(self,inclusive,request)
	if ((q(self.player,"getStrategyMark","useliulilbss-Clear") > 0) and (q(self.player,"getStrategyMark","useliuliqzpdq-Clear") > 0)) then return end
	if (q(self.player,"getStrategyMark","useliulilbss-Clear") == 0) then
		local cards = q(self.player,"getCards","he")
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			local c = q(self,"getKnownCardById",id)
			call(cards,"prepend",c)
		end
		cards = sgs.QList2Table(cards)

		call(self,"sortByUseValue",cards, true)
		local card = nil
		local has_weapon, has_armor = false, false

		for _, acard in ipairs(cards) do
			if q(acard,"isKindOf","Weapon") and not (q(acard,"getSuit") == sgs.Card_Diamond) then has_weapon = true end
		end

		for _, acard in ipairs(cards) do
			if q(acard,"isKindOf","Armor") and not (q(acard,"getSuit") == sgs.Card_Diamond) then has_armor = true end
		end

		for _, acard in ipairs(cards) do
			if (q(acard,"getSuit") == sgs.Card_Diamond) and ((q(self,"getUseValue",acard) < sgs.ai_use_value.Indulgence)) then
				local shouldUse = true

				if q(acard,"isKindOf","Armor") then
					if not call(self.player,"getArmor") then
						shouldUse = false
					elseif q(self.player,"hasEquip",acard) and not has_armor and q(self,"evaluateArmor") > 0 then
						shouldUse = false
					end
				end

				if q(acard,"isKindOf","Weapon") then
					if not call(self.player,"getWeapon") then
						shouldUse = false
					elseif q(self.player,"hasEquip",acard) and not has_weapon then
						shouldUse = false
					end
				end

				if shouldUse then
					card = acard
					break
				end
			end
		end

		if not card then return nil end
		return q(self,"evaluateTurnSkillCard","keguose","#keguoseCard",{q(card,"getEffectiveId")},request)
	end
	if (q(self.player,"getStrategyMark","useliuliqzpdq-Clear") == 0) then
		return q(self,"evaluateTurnSkillCard","keguose","#keguoseCard",{},request)
	end
end


sgs.ai_skill_use_func["#keguoseCard"] = function(card,use,self,request)

	if (q(self.player,"getStrategyMark","useliulilbss-Clear") == 0) and card then
		local id = q(card,"getEffectiveId")
		local indulgence=q(self,"evaluateSkillCard","keguose","indulgence",{id})
		if not q(self.player,"isLocked",indulgence) then
			call(self,"setPriorityValue","keguoseCard",q(self,"getPriorityValue","Indulgence"))

			local dummy_use = q(self,"aiUseCard",indulgence, dummy())
			if dummy_use.card and q(dummy_use.to,"length") > 0 then
				use.card = card
				if use.to then call(use.to,"append",q(dummy_use.to,"first")) end
				return
			end
		end
	elseif (q(self.player,"getStrategyMark","useliuliqzpdq-Clear") == 0) then
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"isFriend",friend) then
				if (q(friend,"getJudgingArea"):length() > 0) then
					use.card = card
					if use.to then call(use.to,"append",friend) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.keguoseCard = 5.5
sgs.ai_use_value.keguoseCard = 5
sgs.ai_card_intention.keguoseCard = -60

function sgs.ai_cardneed.keguose(to, card)
	return q(card,"getSuit") == sgs.Card_Diamond
end

sgs.keguose_suit_value = {
	diamond = 3.9
}


sgs.ai_skill_playerschosen.kekaojun = function(self, targets, max, min)
	local friend = AIList.new({})
	for _, p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(self,"canDraw",p, self.player) and q(friend,"length") < max then
			call(friend,"append",p)
		end
	end
	return friend
end



--刘谌

sgs.ai_skill_choice.kenewwenxiang = function(self, choices, data)
	local items = q(choices,"split","+")
    if #items == 1 then return items[1] end
	return items[math.random(1, #items)]
end

sgs.ai_fill_skill.kenewwenxiang=function(self,inclusive,request)
	if q(self.player,"hasUsed","kenewwenxiangCard") then return end
	local card_id
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		if q(acard,"isRed") then
			call(to_throw,"append",q(acard,"getEffectiveId"))
		end
	end
	card_id = q(to_throw,"at",0)
	if not card_id then
		return nil
	else
		return q(self,"evaluateTurnSkillCard","kenewwenxiang","#kenewwenxiangCard",{card_id},request)
	end
end


sgs.ai_skill_use_func["#kenewwenxiangCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies, "hp")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 0 and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) and q(enemy,"getStrategyMark","usedkenewwenxiang-PlayClear") == 0 then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_use_value.kenewwenxiangCard = 8.5
sgs.ai_use_priority.kenewwenxiangCard = 9.5
sgs.ai_card_intention.kenewwenxiangCard = 80

function sgs.ai_cardneed.kenewwenxiang(to, card)
	return q(card,"isRed")
end




--曹睿

sgs.ai_skill_playerchosen.kehuituo = sgs.ai_skill_playerchosen.huituo
sgs.ai_playerchosen_intention.kehuituo = sgs.ai_playerchosen_intention.huituo

ai_skill_use["@@kemingjianusevs"]=function(self,prompt,request)
	local id = q(self.player,"getStrategyMark","kemingjianusevs-PlayClear") - 1
	if id < 0 then return "." end
	local card = q(self,"getPrintedCardById",id)
	if q(card,"targetFixed") then
		if q(card,"isKindOf","Peach") then
			if q(self,"isWeak") then
				return selected(self,card,{})
			end
			if q(self,"isWeak",self.friends_noself) then
				return "."
			end
			return selected(self,card,{})
		end
		if q(card,"isKindOf","EquipCard") then
			local equip_index = q(card,"getEquipSlot")
			if call(self.player,"getEquip",equip_index) == nil then
				return selected(self,card,{})
			end
		end
		if q(card,"isKindOf","AOE") then
			if q(self,"getAoeValue",card) > 0 then
				return selected(self,card,{})
			end
		end
		if q(card,"isKindOf","Analeptic") then
			return "."
		end
		if q(card,"isKindOf","ExNihilo") then
			return selected(self,card,{})
		end
	else
		local dummy_use = q(self,"aiUseCard",card, dummy())
		if dummy_use.card and not q(dummy_use.to,"isEmpty") then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, q(p,"objectName"))
			end
			if #targets > 0 then
				return selected(self,card,targets)
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.kexingshuai = function(self, data)
	return true
end

sgs.ai_skill_choice.xingshuai_choice = function(self, choices, data)
	if q(self.player,"getStrategyFlag","helpcaorui") then
		return "huifu"
	else
		return "no"
	end
end

sgs.ai_fill_skill.kemingjian=function(self,inclusive,request)
	return q(self,"evaluateTurnSkillCard","kemingjian","#kemingjianCard",{},request)
end

sgs.ai_skill_use_func["#kemingjianCard"] = function(card,use,self,request)
	local give_all_cards = {}
	for _, c in ipairs(sgs.QList2Table(q(self.player,"getCards","h"))) do
		if q(c,"isAvailable",self.player) and ((q(self.player,"getStrategyMark","mingjianjbp-Clear") == 0 and q(c,"isKindOf","BasicCard"))
		or (q(self.player,"getStrategyMark","mingjianzbp-Clear") == 0 and q(c,"isKindOf","EquipCard"))
		or (q(self.player,"getStrategyMark","mingjianjnp-Clear") == 0 and q(c,"isKindOf","TrickCard"))) then
			table.insert(give_all_cards, q(c,"getEffectiveId"))
			break
		end
	end
	if #give_all_cards == 0 then return end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if not q(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) and q(self,"getKnownCardById",give_all_cards[1]):isAvailable(friend) then
			table.insert(targets, friend)
		end
	end
	if #targets > 0 and #give_all_cards > 0 then
		local card_str = string.format("#kemingjianCard:" .. give_all_cards[1] .. ":")
		local acard=q(self,"bindSkillCard","kemingjian",{give_all_cards[1]},request,nil,"#kemingjianCard")
		use.card = acard
		if use.to then
			call(use.to,"append",targets[1])
		end
		return
	end
end

sgs.ai_use_value.kemingjianCard = 8.5
sgs.ai_use_priority.kemingjianCard = 8.8

sgs.ai_card_intention.kemingjianCard = function(self,card,from,tos)
	local to = tos[1]
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif q(to,"hasSkill","kongcheng") and q(to,"isKongcheng") then
		intention = 30
	end
	call(self,"updateIntention",from,to,intention)
end


--王基
sgs.ai_skill_playerchosen.kenewqizhi = function(self, targets)
	call(self,"updatePlayers")
	local targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if q(self,"isEnemy",target) and hasManjuanEffect(target) and not q(target,"isNude") then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if q(self,"isFriend",target) and not hasManjuanEffect(target) and q(self,"needToThrowCard",target, "he", false, false, true) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if q(self,"isEnemy",target) and (call(self,"getDangerousCard",target) or q(self,"keepWoodenOx",target)) then return target end
		if q(self,"isEnemy",target) and call(self,"getValuableCard",target) and q(self,"doDisCard",target, "e")
			and not q(target,"hasSkills",sgs.notActive_cardneed_skill) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if q(target,"objectName") == q(self.player,"objectName") then
			local cards = sgs.QList2Table(q(self.player,"getCards","he"))
			for _, c in ipairs(cards) do
				if not q(self,"keepCard",c, self.player) then return target end
			end
		end
	end
	return nil
end

sgs.ai_skill_invoke.kenewqizhi = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target then
		if q(self,"isFriend",target) then
			return true
		end
	end
	return false
end

sgs.ai_fill_skill.keyanzhu=function(self,inclusive,request)
	if q(self.player,"hasUsed","keyanzhuCard") then return end
	return q(self,"evaluateTurnSkillCard","keyanzhu","#keyanzhuCard",{},request)
end

sgs.ai_skill_use_func["#keyanzhuCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#keyanzhuCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		local x = math.max(q(self.player,"getLostHp"), 1)
		for _, enemy in ipairs(self.enemies) do
			if q(self,"doDisCard",enemy, "he", true) or (q(self.player,"getStrategyMark","changekexingxue") == 0 and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil)) then
				call(enys,"append",enemy)
				if q(enys,"length") >= x then
					break
				end
			end
		end

		if (q(enys,"length") > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to then
					call(use.to,"append",p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.keyanzhuCard = 8.5
sgs.ai_use_priority.keyanzhuCard = 9.5
sgs.ai_card_intention.keyanzhuCard = 80

sgs.ai_skill_cardchosen.keyanzhutishi = function(self,who,flags)
	if (q(self,"isEnemy",who) and q(self,"damageIsEffective",who, sgs.DamageStruct_Normal, self.player) and not q(self,"cantbeHurt",who) and q(self,"canDamage",who,self.player,nil) and q(self.player,"getStrategyMark","changekexingxue") == 0) or (q(self,"isFriend",who) and q(self,"needToLoseHp",who, self.player)) then
		return -1
	end

	return sgs.ai_skill_cardchosen.fankui(self,who,flags)
end

sgs.ai_fill_skill.kezhaofu=function(self,inclusive,request)
	if q(self.player,"hasUsed","kezhaofuCard") then return end
	return q(self,"evaluateTurnSkillCard","kezhaofu","#kezhaofuCard",{},request)
end

sgs.ai_skill_use_func["#kezhaofuCard"] = function(card,use,self,request)
	if (q(self.player,"getStrategyMark","@kezhaofu") > 0) and (q(self,"getCardsNum","Slash") > 0) and not q(self.player,"hasUsed","#kezhaofuCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local slash=q(self,"getEvaluationCard","slash")
		for _, enemy in ipairs(self.enemies) do
			if q(self,"getDefenseSlash",enemy) <= 2
			and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
			end
		end
	end
end

sgs.ai_skill_playerschosen.kexingxue = function(self, targets, max, min)
	local friend = AIList.new({})
	for _, p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(self,"canDraw",p, self.player) then
			call(friend,"append",p)
			if q(friend,"length") >= max then
                break
            end
		end
	end
	return friend
end


--钟会

sgs.ai_skill_invoke.kezhenggong = function(self, data)
	return true
end

sgs.ai_fill_skill.kesuni=function(self,inclusive,request)
	if q(self.player,"hasUsed","kesuniCard") then return end
	return q(self,"evaluateTurnSkillCard","kesuni","#kesuniCard",{},request)
end

sgs.ai_skill_use_func["#kesuniCard"] = function(card,use,self,request)
	if (q(self.player,"getStrategyMark","&kegong") > 0) and not q(self.player,"hasUsed","#kesuniCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if q(enys,"isEmpty") then
				call(enys,"append",enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (q(enemy,"getHp") + q(enemy,"getHp") + q(enemy,"getHandcardNum")) >= (q(p,"getHp") + q(p,"getHp") + q(p,"getHandcardNum")) then
						yes = 0
					end
				end
				if (yes == 1) then
					call(enys,"removeOne",q(enys,"at",0))
					call(enys,"append",enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if q(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.kesuniCard = 8.5
sgs.ai_use_priority.kesuniCard = 9.5
sgs.ai_card_intention.kesuniCard = 80


--曹冲
sgs.ai_fill_skill.kenewchengxiang=function(self,inclusive,request)
	if q(self.player,"hasUsed","kenewchengxiangCard") then return end
	return q(self,"evaluateTurnSkillCard","kenewchengxiang","#kenewchengxiangCard",{},request)
end

sgs.ai_skill_use_func["#kenewchengxiangCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#kenewchengxiangCard") then
		local room = self.room
		local all = q(room,"getOtherPlayers",self.player)
		local enys = AIList.new({})
		for _, p in sgs.qlist(all) do
			if q(self,"isEnemy",p) then
				if (not q(p,"isKongcheng")) and ((q(p,"getHp") >= q(self.player,"getHp")) or (q(p,"getHandcardNum") >= q(self.player,"getHandcardNum"))) then
					call(enys,"append",p)
				end
			end
		end
		if (q(enys,"length") > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to then
					call(use.to,"append",p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.kenewchengxiangCard = 8.5
sgs.ai_use_priority.kenewchengxiangCard = 9.5
sgs.ai_card_intention.kenewchengxiangCard = 80

sgs.ai_skill_invoke.keceyin = function(self, data)
	local damage = fact(self,"keceyin")
	if damage.to and q(self,"isFriend",damage.to) then
		if not q(self,"needToLoseHp",damage.to, damage.from, damage.card) then
			return true
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.keceyin = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end


sgs.ai_skill_discard.keceyin = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

--孙鲁育

sgs.ai_skill_invoke.keraoxi = function(self, data)
	local target = call(data,"toPlayer")
	if q(self,"isEnemy",target) and q(self,"getOverflow",target) > 0 then
		return true
	end
	return false
end

sgs.ai_skill_discard.keceyin = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	if (q(self.player,"getCardCount") > 1) and (q(self.player,"getStrategyMark","useraoxi_lun") < 2)  then
		table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	end
	return to_discard
end


sgs.ai_skill_choice.keraoxi = function(self, choices, data)
	local target = call(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(target,"getHandcardNum") <= 1 then
		return "skipmp"
	else
		return "skipcp"
	end
end
sgs.ai_choicemade_filter.skillChoice["keraoxi"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = call(self.room,"getCurrent")
	if choice == "skipmp" and q(self,"getOverflow",current) > 0 then
		call(self,"updateIntention",player, current, 60)
	end
end


sgs.ai_fill_skill.kemumu=function(self,inclusive,request)
	if q(self.player,"hasUsed","kemumuCard") then return end
	return q(self,"evaluateTurnSkillCard","kemumu","#kemumuCard",{},request)
end

sgs.ai_skill_use_func["#kemumuCard"] = function(card,use,self,request)

	call(self,"sort",self.friends, "defense")
	self.friends = sgs.reverse(self.friends)
	for _, fri in ipairs(self.friends) do
		if q(self,"doDisCard",fri, "hej") then
			use.card = card
			if use.to then call(use.to,"append",fri) end
			return
		end
	end
	call(self,"sort",self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 0 and q(self,"doDisCard",enemy, "hej") then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
end


sgs.ai_use_value.kemumuCard = 8.5
sgs.ai_use_priority.kemumuCard = 9.5
sgs.ai_choicemade_filter.cardChosen.kemumu = sgs.ai_choicemade_filter.cardChosen.snatch


--张星彩
sgs.ai_fill_skill.keqiangwu=function(self,inclusive,request)
	if q(self.player,"hasUsed","keqiangwuCard") then return end
	return q(self,"evaluateTurnSkillCard","keqiangwu","#keqiangwuCard",{},request)
end

sgs.ai_skill_use_func["#keqiangwuCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#keqiangwuCard") then
		use.card = card
		return
	end
end

sgs.ai_use_value.keqiangwuCard = 8.5
sgs.ai_use_priority.keqiangwuCard = 9.5
sgs.ai_card_intention.keqiangwuCard = 80

sgs.ai_skill_invoke.kexianjie = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.kexianjie = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|kexianjie"
sgs.ai_cardneed.kexianjie = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.keqiangwu = function(self, targets)
	targets = sgs.QList2Table(targets)
	if q(self.player,"getStrategyFlag","keqiangwu_throw") then
		for _, p in ipairs(targets) do
			if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
				return p
			end
		end
	else
		for _, p in ipairs(targets) do
			if q(self,"isEnemy",p) and q(self,"objectiveLevel",p)>3 and not q(self,"cantbeHurt",p) and q(self,"damageIsEffective",p) then
				return p
			end
		end
	end

	return nil
end
sgs.ai_playerchosen_intention.keqiangwu = 70
sgs.ai_card_priority.keqiangwu = function(self,card,v)
	if q(self.player,"getStrategyMark","keqiangwu-PlayClear") > 0 then
		local qiangwu = q(self,"getKnownCardById",q(self.player,"getStrategyMark","keqiangwu-PlayClear"))
		if qiangwu and (q(qiangwu,"getSuit") ==q(card,"getSuit")
		or q(qiangwu,"getNumber")==q(card,"getNumber"))
		then return 10 end
	end
end


--曹仁
sgs.ai_view_as.keyanzheng = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand then
		if q(card,"isBlack") or q(card,"isRed") then
			return spec("nullification","keyanzheng",card)
		end
	end
end

sgs.ai_cardneed.keyanzheng = function(to, card, self)
	return q(card,"isBlack") or q(card,"isRed")
end

sgs.ai_fill_skill.keyugong=function(self,inclusive,request)
	if q(self.player,"hasUsed","#keyugongCard") then return end
	local card_id
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	if (q(self.player,"getChangeSkillState","keyugong") == 2) then
		local yes = 0
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if q(acard,"isDamageCard") then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0)
		if not card_id then
			return nil
		else
			return q(self,"evaluateTurnSkillCard","keyugong","#keyugongCard",{card_id},request)
		end
	elseif (q(self.player,"getChangeSkillState","keyugong") == 1) then
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if not q(acard,"isDamageCard") then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0) --(q(to_throw,"length")-1)
		if not card_id then
			return nil
		else
			return q(self,"evaluateTurnSkillCard","keyugong","#keyugongCard",{card_id},request)
		end
	end
end

sgs.ai_skill_use_func["#keyugongCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#keyugongCard") then
		use.card = card
		return
	end
end

function sgs.ai_cardneed.keyugongCard(to, card, self)
	if q(self.player,"hasUsed","#keyugongCard") then return false end
	return true
end

sgs.ai_use_value.keyugongCard = 8.5
sgs.ai_use_priority.keyugongCard = 9.5
sgs.ai_card_intention.keyugongCard = 80

--邓艾
sgs.ai_use_revises.kepihuang = function(self,card,use)
	if q(card,"isKindOf","EquipCard") and q(self,"evaluateArmor",card)>-5 and q(self.player,"getStrategyMark","&keppihuangbozhong") > 0 and q(self.player,"hasSkill","kezhuxian")
	then use.card = card return true end
end
sgs.ai_skill_choice.kepihuang = function(self, choices, data)
	if (q(self.player,"getStrategyMark","&ketian") <= 2) or (not q(self.player,"hasSkill","kezhuxian")) then
		return "bozhong"
	else
		return "fengshou"
	end
end

sgs.ai_skill_choice.kezaoxian = function(self, choices, data)
	if (q(self,"isWeak") and q(self.player,"isWounded")) then
		return "recover"
	else
		return "draw"
	end
end

sgs.ai_skill_playerchosen.kezhuxian = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", true) then
			return p
		end
	end
	return nil
end

--姜维

sgs.ai_fill_skill.ketiaoxin=function(self,inclusive,request)
	if q(self.player,"hasUsed","ketiaoxinCard") then return end
	return q(self,"evaluateTurnSkillCard","ketiaoxin","#ketiaoxinCard",{},request)
end

sgs.ai_skill_use_func["#ketiaoxinCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#ketiaoxinCard") then
		call(self,"sort",self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = AIList.new({})
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isNude") then
				if q(enys,"isEmpty") then
					call(enys,"append",enemy)
				else
					local yes = 1
					for _, p in sgs.qlist(enys) do
						if (q(enemy,"getHp") + q(enemy,"getHp") + q(enemy,"getHandcardNum")) >= (q(p,"getHp") + q(p,"getHp") + q(p,"getHandcardNum")) then
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
		for _, enemy in sgs.qlist(enys) do
			if q(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.ketiaoxinCard = 8.5
sgs.ai_use_priority.ketiaoxinCard = 9.5
sgs.ai_card_intention.ketiaoxinCard = 80

sgs.ai_skill_choice.kezhiji = function(self, choices, data)
	if (q(self,"isWeak") and q(self.player,"isWounded")) then
		return "recover"
	else
		return "draw"
	end
end

sgs.ai_skill_choice.kejwkuitian = function(self, choices, data)
	return "fromass"
end
sgs.ai_skill_playerchosen["kejwkuitian"] = function(self, targets)
	call(self,"sort",self.enemies, "handcard", true)
	for _, p in ipairs(self.enemies) do
		if not q(p,"isKongcheng") then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention["kejwkuitian"] = 50

sgs.ai_card_priority.kemingding = function(self,card,v)
	if (q(self.player,"getStrategyMark","&kemingding-Clear") + 1 == q(card,"nameLength")) then return 10 end
end

sgs.ai_skill_invoke.kenewgonghuan = function(self, data)
	local use = q(data,"toCardUse")
	local target = q(use.to,"first")
	if target and q(self,"isFriend",target) then
		if not q(self,"isFriend",use.from) then
			return not q(self,"isWeak")
		end
	end
	return false
end


sgs.ai_skill_choice.kenewgonghuan = function(self, choices, data)
	local target = call(data,"toPlayer")
	if getBestHp(target) > q(target,"getHp") then
		return "recover"
	else
		return "mopai"
	end
end

sgs.ai_fill_skill.kenewsangzhi=function(self,inclusive,request)
	--if q(self.player,"hasUsed","kenewsangzhiCard") then return end
	return q(self,"evaluateTurnSkillCard","kenewsangzhi","#kenewsangzhiCard",{},request)
end

sgs.ai_skill_use_func["#kenewsangzhiCard"] = function(card,use,self,request)
	--if not q(self.player,"hasUsed","#kenewsangzhiCard") then
	local room = q(self.player,"getRoom")
	local hpones = AIList.new({})
	local spones = AIList.new({})
	local ones = q(room,"getOtherPlayers",self.player)
	for _, one in sgs.qlist(ones) do
		if (math.min(q(one,"getHp"), q(self.player,"getMaxHp")) > q(self.player,"getHp")) and (q(one,"getStrategyMark","beselectsangzhi") == 0) then
			if q(hpones,"isEmpty") then
				call(hpones,"append",one)
			else
				local yes = 1
				for _, p in sgs.qlist(hpones) do
					if (math.min(q(p,"getHp"), q(self.player,"getMaxHp")) >= math.min(q(one,"getHp"), q(self.player,"getMaxHp"))) then
						yes = 0
						break
					end
				end
				if (yes == 1) then
					call(hpones,"removeOne",q(hpones,"at",0))
					call(hpones,"append",one)
				end
			end
		end
		if (q(one,"getHandcardNum") > q(self.player,"getHandcardNum")) and (q(one,"getStrategyMark","beselectsangzhi") == 0) then
			if q(spones,"isEmpty") then
				call(spones,"append",one)
			else
				local yes = 1
				for _, p in sgs.qlist(spones) do
					if (q(p,"getHandcardNum") >= q(one,"getHandcardNum")) then
						yes = 0
						break
					end
				end
				if (yes == 1) then
					call(spones,"removeOne",q(spones,"at",0))
					call(spones,"append",one)
				end
			end
		end
	end
	if not q(hpones,"isEmpty") then
		use.card = card
		if use.to then call(use.to,"append",q(hpones,"at",0)) end
		return
	end
	if not q(spones,"isEmpty") then
		use.card = card
		if use.to then call(use.to,"append",q(spones,"at",0)) end
		return
	end
	--end
end

sgs.ai_use_value.kenewsangzhiCard = 8.5
sgs.ai_use_priority.kenewsangzhiCard = 9.5
sgs.ai_card_intention.kenewsangzhiCard = 80

sgs.ai_fill_skill.kenewzahuo=function(self,inclusive,request)
	if q(self.player,"hasUsed","kenewzahuoCard") or (q(self.player,"getStrategyMark","@kecaoxie") < 3) then return end
	return q(self,"evaluateTurnSkillCard","kenewzahuo","#kenewzahuoCard",{},request)
end

sgs.ai_skill_use_func["#kenewzahuoCard"] = function(card,use,self,request)
	if (q(self.player,"getStrategyMark","@kecaoxie") >= 3) and not q(self.player,"hasUsed","#kenewzahuoCard") then
		use.card = card
		return
	end
end

sgs.ai_use_value.kenewzahuoCard = 8.5
sgs.ai_use_priority.kenewzahuoCard = 9.5
sgs.ai_card_intention.kenewzahuoCard = 80


sgs.ai_skill_choice.goodsclass = function(self, choices, data)
	local room = q(self.player,"getRoom")
	local yes = 0
	for _, p in sgs.qlist(q(room,"getOtherPlayers",self.player)) do
		if q(self,"isEnemy",p) and q(self.player,"inMyAttackRange",p)
			and (q(self,"getCardsNum","Slash") > 0) then
			yes = 1
		end
	end
	if (q(self,"isWeak") and q(self.player,"isWounded") and (q(self.player,"getStrategyMark","@kecaoxie") >= 5))
		or ((q(self.player,"getStrategyMark","@kecaoxie") >= 3) and (q(self,"slashIsAvailable",self.player)) and (q(self,"getCardsNum","Slash") == 0)) then
		return "basiccard"
	elseif (yes == 0) and (q(self.player,"getStrategyMark","@kecaoxie") >= 4) then
		return "equip"
	elseif (q(self.player,"getStrategyMark","@kecaoxie") >= 4) and (not q(self,"slashIsAvailable",self.player)) and (q(self,"getCardsNum","Slash") > 0)
		or (q(self.player,"getStrategyMark","@kecaoxie") >= 3) and (q(self.player,"getHandcardNum") > q(self.player,"getMaxCards") + 2) then
		return "effect"
	end
end

sgs.ai_skill_choice.liubeijibenpai = function(self, choices, data)
	local room = q(self.player,"getRoom")
	if q(self,"isWeak") and q(self.player,"isWounded") and (q(self.player,"getStrategyMark","@kecaoxie") >= 5) then
		return "peach"
	elseif (q(self.player,"getStrategyMark","@kecaoxie") >= 3) and (q(self,"slashIsAvailable",self.player)) and (q(self,"getCardsNum","Slash") == 0) then
		return "slash"
	end
end

sgs.ai_skill_choice.liubeizhuangbei = function(self, choices, data)
	return "weapon"
end

sgs.ai_skill_choice.liubeitexiao = function(self, choices, data)
	local room = q(self.player,"getRoom")
	if (q(self.player,"getStrategyMark","@kecaoxie") >= 4) and (not q(self,"slashIsAvailable",self.player)) and (q(self,"getCardsNum","Slash") > 0) then
		return "addslash"
	elseif (q(self.player,"getStrategyMark","@kecaoxie") >= 3) and (q(self.player,"getHandcardNum") > q(self.player,"getMaxCards") + 2) then
		return "maxhand"
	end
end

--孙权

sgs.ai_skill_choice.kezhiheng = function(self, choices, data)
	if (q(self,"getEnemyNumBySeat",call(self.room,"getCurrent"),self.player,self.player,true) == 0) or (q(self,"getEnemyNumBySeat",call(self.room,"getCurrent"),self.player,self.player,true)>q(self.room,"getAlivePlayers"):length()/2) then
		return "xiaomo"
	end
	return "damo"
end

--卧龙诸葛亮

sgs.ai_skill_discard.kenewhuoji = function(self, discard_num, min_num, optional, include_equip, pattern)
	local to_discard = {}
	for _, c in sgs.qlist(q(self.player,"getCards","h")) do
		if q(self,"matchesDiscardPattern",pattern,c)
			then
			table.insert(to_discard, q(c,"getEffectiveId"))
			return to_discard
		end
	end
	return to_discard
end


sgs.ai_fill_skill.kenewhuoji=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)

	local card

	call(self,"sortByUseValue",cards, true)

	for _, acard in ipairs(cards) do
		if q(acard,"isRed") and not q(acard,"isKindOf","Peach") and (q(self,"getDynamicUsePriority",acard) < sgs.ai_use_value.FireAttack or q(self,"getOverflow") > 0) then
			if q(acard,"isKindOf","Slash") and q(self,"getCardsNum","Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true, to = AIList.new({}) }
				call(self,"useBasicCard",acard, dummy_use)
				if dummy_use.card and dummy_use.to and q(dummy_use.to,"length") > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if q(p,"getHp") <= 1 then
							keep = true
							break
						end
					end
					if q(dummy_use.to,"length") > 1 then keep = true end
				end
				if keep then
					call(self,"setPriorityValue","Slash",q(self,"getPriorityValue","FireAttack")+0.1)
				else
					call(self,"setPriorityValue","Slash",2.6)
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
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	local card_str = spec("fire_attack","kenewhuoji",card)
	local skillcard=q(self,"evaluateTurnConversion","kenewhuoji","FireAttack",spec("fire_attack","kenewhuoji",card),request)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.kenewhuoji = function(to, card, self)
	return q(to,"getHandcardNum") >= 2 and q(card,"isRed")
end

sgs.ai_view_as.kenewkanpo = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if q(card,"isBlack") then
		return spec("nullification","kenewkanpo",card)
	end
end

sgs.ai_cardneed.kenewkanpo = function(to, card, self)
	return q(card,"isBlack")
end
sgs.ai_skill_playerschosen.kenewkanpo = function(self, targets, max, min)
	local friend = AIList.new({})
	for _, p in sgs.qlist(targets) do
		if q(self,"isFriend",p) then
			call(friend,"append",p)
		end
	end
	return friend
end


sgs.ai_skill_invoke.kenewbazhen = sgs.ai_skill_invoke.eight_diagram

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|kewulie"
sgs.ai_ajustdamage_from.kewulie = function(self,from,to,slash,nature)
	if q(from,"getStrategyMark","&kewulie") > 0 and q(to,"isKongcheng") and q(from,"objectName") ~= q(to,"objectName")
	then return 1 end
end

sgs.ai_skill_playerschosen.kewulie = function(self, targets, max, min)
	targets = sgs.QList2Table(targets)
	local tos = {}
	call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if q(self,"doDisCard",p,"hej") and #tos < max then
			table.insert(tos, p)
		end
	end
	return tos
end

sgs.ai_getBestHp_skill.kewulie = function(owner)
	return q(owner,"getMaxHp") - 2
end

sgs.ai_fill_skill.kexihuo=function(self,inclusive,request)
	if q(self.player,"hasUsed","kexihuoCard") or (q(self.player,"getStrategyMark","@kexihuo") < 1) then return end
	if not getYongdiTarget(self,q(self.room,"getOtherPlayers",self.player)) then return end
	return q(self,"evaluateTurnSkillCard","kexihuo","#kexihuoCard",{},request)
end

sgs.ai_skill_use_func["#kexihuoCard"] = function(card,use,self,request)
	local target = getYongdiTarget(self,q(self.room,"getOtherPlayers",self.player))
	if target then
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
end








--十常侍

--赵忠
sgs.ai_skill_invoke.kenewshiren = function(self, data)
	local current = call(self.room,"getCurrent")
	if current and q(self,"isEnemy",current) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.kenewshiren = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local current = call(self.room,"getCurrent")
		if current then call(self,"updateIntention",player,current,50) end
	end
end

--孙璋
sgs.ai_fill_skill.kenewqieshui=function(self,inclusive,request)
	if q(self.player,"hasUsed","kenewqieshuiCard") then return end
	return q(self,"evaluateTurnSkillCard","kenewqieshui","#kenewqieshuiCard",{},request)
end

sgs.ai_skill_use_func["#kenewqieshuiCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#kenewqieshuiCard") then
		local room = self.room
		local all = q(room,"getOtherPlayers",self.player)
		local enys = AIList.new({})
		for _, p in sgs.qlist(all) do
			if q(self,"isEnemy",p) then
				call(enys,"append",p)
			end
		end
		if (q(enys,"length") > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to and (q(use.to,"length") < q(self.player,"getStrategyMark","sunzhanglunci")) then
					call(use.to,"append",p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.kenewqieshuiCard = 8.5
sgs.ai_use_priority.kenewqieshuiCard = 9.5
sgs.ai_card_intention.kenewqieshuiCard = 80

sgs.ai_skill_askforyiji.kenewqieshui = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end


sgs.ai_skill_choice.kenewrongyuan = function(self, choices, data)
	local num = math.random(0, 1)
	if num == 0 then
		return "dis"
	else
		return "mopai"
	end
end

sgs.ai_skill_playerschosen.kenewrongyuan = function(self, targets, max, min)
	if q(self.player,"getStrategyFlag","kenewrongyuan_draw") then
		local friend = AIList.new({})
		for _, p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and q(self,"canDraw",p, self.player) and q(friend,"length") < max then
				call(friend,"append",p)
			end
		end
		return friend
	end
	local enemy = AIList.new({})
	for _, p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") and q(enemy,"length") < max then
			call(enemy,"append",p)
		end
	end
	return enemy
end


--夏恽
sgs.ai_skill_invoke.kenewbiting = function(self, data)
	local current = call(self.room,"getCurrent")
	if current and q(self,"isEnemy",current) and q(current,"isLord") then
		return true
	end
	if current and q(self,"isEnemy",current) then
        for _,sk in ipairs(sgs.getPlayerSkillList(current))do
			local dp = q(sk,"getDescription")
			if string.find(dp,"摸牌阶段") and string.find(dp,"额外") then
				local t = trigger(self,sk)
				if t and q(t,"hasEvent",sgs.DrawNCards)
				then return true end
			end
		end
    end
	if current and q(self,"isFriend",current) then
		for _,sk in ipairs(sgs.getPlayerSkillList(current))do
			local dp = q(sk,"getDescription")
			if string.find(dp,"摸牌阶段") and string.find(dp,"额外") then
				local t = trigger(self,sk)
				if t and q(t,"hasEvent",sgs.DrawNCards)
				then return false end
			end
		end
		return #self.enemies>0
	end
    return false
end

sgs.ai_skill_discard.kenewbiting = function(self)
	local to_discard = {}
	local current = call(self.room,"getCurrent")
	if current and q(self,"isFriend",current) then
		for _, c in sgs.qlist(q(self.player,"getCards","he")) do
			table.insert(to_discard, q(c,"getEffectiveId"))
		end
	else
		local cards = q(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		table.insert(to_discard, cards[1]:getEffectiveId())
	end
	return to_discard
end

--栗嵩
sgs.ai_skill_invoke.kenewmieyao = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target then
		if q(self,"isEnemy",target) then
			local use = fact(self,"kenewmieyao")
			for _, p in sgs.qlist(use.to) do
				if q(self,"isFriend",p) then
					return false
				end
			end
			return true
		end
	end
	return false
end

sgs.ai_ajustdamage_from.kenewjueling = function(self,from,to,card,nature)
	if (q(to,"isKongcheng") or (q(to,"getEquips"):length() == 0) or (q(to,"getJudgingArea"):length() > 0))
		and (q(from,"getStrategyMark","juelingadd-Clear") == 0)
	then return 1 end
end


--郭胜
sgs.ai_skill_playerchosen.kenewyuanli = function(self, targets)
	targets = sgs.QList2Table(targets)
	local slash=q(self,"evaluateSkillCard","kenewyuanli","fire_slash",{})
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			if q(self.player,"canSlash",p, slash, false) and not q(self,"slashProhibit",slash, p) and q(self,"getDefenseSlash",p) <= 6
				and q(self,"slashIsEffective",slash, p) and q(self,"isGoodTarget",p, self.enemies, slash)
				and q(p,"objectName") ~= q(self.player,"objectName") then
				return p
			end
		end
	end
	return nil
end

--高望

sgs.ai_skill_invoke.kenewsiji = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target then
		if q(self,"isEnemy",target) then
			if not q(self.player,"getStrategyFlag","kenewsiji_damage") then
				return true
			end
		elseif q(self,"isFriend",target) and not q(self,"needToLoseHp",target) then
			if q(self.player,"getStrategyFlag","kenewsiji_damage") then
				return true
			end
		end
	end
	return false
end

--张让

sgs.ai_fill_skill.kenewwangmiu=function(self,inclusive,request)
	if q(self.player,"hasUsed","kenewwangmiuCard") then return end
	local card_id
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		if q(acard,"isKindOf","BasicCard") or q(acard,"isNDTrick") then
			call(to_throw,"append",q(acard,"getEffectiveId"))
		end
	end
	card_id = q(to_throw,"at",0)
	if not card_id then
		return nil
	else
		return q(self,"evaluateTurnSkillCard","kenewwangmiu","#kenewwangmiuCard",{card_id},request)
	end
end


sgs.ai_skill_use_func["#kenewwangmiuCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#kenewwangmiuCard") then
		call(self,"sort",self.friends)
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"isFriend",friend) then
				use.card = card
				if use.to then call(use.to,"append",friend) end
				return
			end
		end
	end
end

sgs.ai_use_value.kenewwangmiuCard = 8.5
sgs.ai_use_priority.kenewwangmiuCard = 9.5
sgs.ai_card_intention.kenewwangmiuCard = 80

sgs.ai_skill_playerschosen.kenewwangmiu = function(self, targets, max, min)
	local tos = {}
	if q(self.player,"getStrategyMark","kenewwangmiu") > 0 then
		local card = q(self,"getKnownCardById",q(self.player,"getStrategyMark","kenewwangmiu"))
		if card then
			local dummy_use = q(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if dummy_use.to then
					for _, p in sgs.qlist(dummy_use.to) do
						if #tos < max then
							table.insert(tos,p) end
						end
					end
				end
			end
		end
    return tos
end



function sgs.ai_cardneed.kenewwangmiuCard(to, card)
	return q(card,"isKindOf","BasicCard") or q(card,"isNDTrick")
end

--夏侯紫萼
sgs.double_slash_skill = sgs.double_slash_skill .. "|kenewqingran"
sgs.ai_cardneed.kenewqingran = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.kenewlvefeng = function(self, data)
	local target = call(data,"toPlayer")
	return not q(self,"isFriend",target)
end
sgs.ai_can_damagehp.kenewlvefeng = function(self,from,card,to)
	if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
	then
		return q(self,"isEnemy",from) and q(self,"isWeak",from) and q(from,"getHandcardNum")>0
	end
end


--王异

sgs.ai_skill_invoke.kenewzhenlietwo = function(self, data)
	if q(self,"isWeak") then return false end
	local use = q(data,"toCardUse")
	for _, szm in sgs.qlist(use.to) do
		if q(self,"isFriend",szm) then
			return false
		end
	end
	return true
end

sgs.ai_skill_invoke.kenewzhenlie = sgs.ai_skill_invoke.zhenlie

sgs.ai_skill_invoke.kenewmiji = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kenewmiji = function(self, targets)
	if (q(self.player,"getHandcardNum") > 3) then
		targets = sgs.QList2Table(targets)
		local theweak = AIList.new({})
		local theweaktwo = AIList.new({})
		for _, p in ipairs(targets) do
			if q(self,"isFriend",p) then
				call(theweak,"append",p)
			end
		end
		for _, qq in sgs.qlist(theweak) do
			if q(theweaktwo,"isEmpty") then
				call(theweaktwo,"append",qq)
			else
				local inin = 1
				for _, pp in sgs.qlist(theweaktwo) do
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
	end
	return nil
end

sgs.ai_skill_discard.kenewmiji = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	--[[local cards = q(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)]]
	if (q(self.player,"getHandcardNum") <= 3) then
		return q(self,"askForDiscard","dummyreason", 999, 999, true, true)
	else
		local dd = q(self.player,"getHandcardNum")
		while (dd > 3)
		do
			dd = dd - 1
			local cards = q(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			call(self,"sortByKeepValue",cards)
			table.insert(to_discard, cards[1]:getEffectiveId())
		end
		return to_discard
	end
end

sgs.ai_getBestHp_skill.kenewmiji = function(owner)
	return q(owner,"getMaxHp") - 1
end

