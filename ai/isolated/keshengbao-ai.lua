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
local function dummy(value)local u=AIUsePlan.new();u.isDummy=value;return u end
local function sole_slash(self,player)
 if player==self.player then return q(q(player,"getHandcards"):at(0),"isKindOf","Slash")end
 local known=q(player,"getKnownCards")
 if #known==1 then return q(known[1],"isKindOf","Slash")end
 return q(self,"useKnowledgeEstimate",{status="estimate",value=false,basis="keshengbao.liema_unobserved_single_hand_slash_inactive_prior",target=q(player,"objectName")},"keshengbao.liema.single_slash")
end
local function current_damage(self)
 -- Room tag CurrentDamageStruct: a question's decision context carries it while the tag
 -- holds one (absent reads as the donor's empty struct); event callbacks get no context.
 if self.request.kind=="event"then ai_unsupported("CurrentDamageStruct is not projected to event callbacks","keshengbao.current_damage")end
 local d=self:getDecisionContext().damage
 if d==nil then return{}end
 return{from=d.from,to=d.to,damage=d.amount,card=d.card,nature=d.nature}
end
--change

sgs.ai_skill_invoke.shengchangetupo = function(self, data)
	--[[local num = math.random(0,1)
	if (num == 0) then
	    return true
	else
		return false
	end]]
	return false
end

--圣孙权

sgs.ai_skill_invoke.keshengxionglve = function(self, data)
	return true
end

sgs.ai_getBestHp_skill.keshengxionglve = function(owner)
	return q(owner,"getMaxHp") - 1
end

sgs.ai_skill_invoke.keshengganen = function(self, data)
	local target = call(data,"toPlayer")
	if target then
		if q(self,"isFriend",target) then
			if q(self,"isWeak",target) then
				return not q(target,"isKongcheng") and q(self,"needKongcheng",target) and q(self,"canDraw",target, self.player)
			elseif q(self,"canDraw",target, self.player) and (q(self,"getOverflow") > 0 or q(self.player,"isSkipped",sgs.Player_Play)) then
				return true
			else
				return math.random() < 0.45 and q(self,"canDraw",target, self.player)
			end
		elseif q(self,"isEnemy",target) then
			if q(target,"isKongcheng") and q(self,"needKongcheng",target) then
				return true
			end
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.keshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if to then
			call(self,"updateIntention",player, to, -70)
		end
	end
end


sgs.ai_skill_invoke.kejieshengxionglve = function(self, data)
	return true
end

sgs.ai_getBestHp_skill.kejieshengxionglve = function(owner)
	return q(owner,"getMaxHp") - 1
end

sgs.ai_skill_invoke.kejieshengganen = function(self, data)
	local target = call(data,"toPlayer")
	if q(self,"isFriend",target) then
		if q(self,"isWeak",target) then
			return q(self,"canDraw",target, self.player)
		elseif q(self,"canDraw",target, self.player) and (q(self,"getOverflow") > 0 or q(self.player,"isSkipped",sgs.Player_Play)) then
			return true
		elseif q(self,"hasSkills",sgs.cardneed_skill, self.player) then return false
		else
			return math.random() < 0.8 and q(self,"canDraw",target, self.player)
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengganen = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local to = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if to then
			call(self,"updateIntention",player, to, -70)
		end
	end
end


sgs.ai_skill_choice.kejieshengganen = function(self, choices, data)
	if q(self,"isWeak") or q(self.player,"getHp") < getBestHp(self.player) then return "huixue" end
	return "mopai"
end

--圣孙策

sgs.ai_skill_cardask["shenghuju-slash"] = function(self, data, pattern, target)
	local effect = q(data,"toCardEffect")
	if q(self,"isFriend",effect.to) then return "." end
	if q(self,"cantDamageMore",effect.from,effect.to) then return "." end
	if q(self.player,"getCardCount") - 2 >= q(self.player,"getHp")
		or q(self,"needKongcheng") and q(self.player,"getHandcardNum") > 0
		or q(self.player,"hasSkill","kuanggu") and q(self.player,"isWounded") and q(self.player,"distanceTo",effect.to) == 1
		or q(effect.to,"getHp") <= 2 and not hasBuquEffect(effect.to)
		or q(self,"getOverflow") > 0
	then
		return q(self,"getCardId","Slash")
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|keshenghuju"
sgs.ai_cardneed.keshenghuju = sgs.ai_cardneed.slash

sgs.ai_skill_cardask["jieshenghuju-slash"] = function(self, data, pattern, target)
	local effect = q(data,"toCardEffect")
	if q(self,"isFriend",effect.to) then return "." end
	if q(self.player,"getCardCount") - 2 >= q(self.player,"getHp")
		or q(self,"needKongcheng") and q(self.player,"getHandcardNum") > 0
		or q(self.player,"hasSkill","kuanggu") and q(self.player,"isWounded") and q(self.player,"distanceTo",effect.to) == 1
		or q(effect.to,"getHp") <= 2 and not hasBuquEffect(effect.to)
		or q(self,"getOverflow") > 0
	then
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isRed") and q(c,"isKindOf","Slash") and not q(self,"cantDamageMore",effect.from,effect.to) then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isRed") then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isKindOf","Slash") and not q(self,"cantDamageMore",effect.from,effect.to) then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			return q(c,"getEffectiveId")
		end
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kejieshenghuju"
sgs.ai_cardneed.kejieshenghuju = sgs.ai_cardneed.slash

sgs.ai_skill_cardask["jieshenghujutwo-slash"] = function(self, data, pattern, target)
	local use = q(data,"toCardUse")
	if q(self,"isFriend",q(use.to,"first")) then return "." end
	if q(self.player,"getCardCount") - 2 >= q(self.player,"getHp")
		or q(self,"needKongcheng") and q(self.player,"getHandcardNum") > 0
		or q(self.player,"hasSkill","kuanggu") and q(self.player,"isWounded") and q(self.player,"distanceTo",q(use.to,"first")) == 1
		or q(use.to,"first"):getHp() <= 2 and not hasBuquEffect(q(use.to,"first"))
		or q(self,"getOverflow") > 0
	then
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isRed") and q(c,"isKindOf","Slash") and not q(self,"cantDamageMore",use.from,q(use.to,"first")) then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isRed") then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			if q(c,"isKindOf","Slash") and not q(self,"cantDamageMore",use.from,q(use.to,"first")) then return q(c,"getEffectiveId") end
		end
		for _, c in sgs.list(q(self.player,"getHandcards")) do
			return q(c,"getEffectiveId")
		end
	else
		return "."
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kejieshenghujutwo"
sgs.ai_cardneed.kejieshenghujutwo = sgs.ai_cardneed.slash

--圣甄姬

sgs.ai_skill_invoke.keshengliufeng = function(self, data)
	return true
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|keshengliufeng"

sgs.ai_hasTuntianEffect_skill.keshengliufeng = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_skill_choice.keshenghuixue = function(self, choices, data)
	local choice=call(self,"getStrategyMemory","keshengbao.huixue_choice");if choice then return choice end
	return "huixue"
end


sgs.ai_choicemade_filter.skillChoice["keshenghuixue"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(p,"getStrategyFlag","keshenghuixueTarget") then
			if choice == "huixue" then
				call(self,"updateIntention",player, p, -80)
			else
				call(self,"updateIntention",player, p, 80)
			end
		end
	end
end


sgs.ai_fill_skill.keshenghuixue=function(self,inclusive,request)
	if not q(self.player,"canDiscard",self.player, "h") then return end
	if q(self.player,"hasUsed","keshenghuixueCard") then return end
	return q(self,"legacySkillSeed","keshenghuixue","#keshenghuixueCard",request)
end

sgs.ai_skill_use_func["#keshenghuixueCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#keshenghuixueCard") then
		for _, p in ipairs(self.friends_noself) do
			if q(p,"getHp") < getBestHp(p) and q(p,"isMale") and q(p,"canDiscard",p, "h") then
				use.card=q(self,"bindSkillCard","keshenghuixue",{},request,nil,"#keshenghuixueCard")
				call(self,"setStrategyMemory","keshengbao.huixue_choice","huixue")
				if use.to then call(use.to,"append",p) end
				return
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy)
				and q(self.player,"getHp") > q(enemy,"getHp") and q(self.player,"getHp") > 1 and q(enemy,"canDiscard",enemy, "h")
			then
				call(self,"setStrategyMemory","keshengbao.huixue_choice","shanghai")
				use.card=q(self,"bindSkillCard","keshenghuixue",{},request,nil,"#keshenghuixueCard")
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keshenghuixueCard = 8.5
sgs.ai_use_priority.keshenghuixueCard = 9.5
--sgs.ai_card_intention.keshenghuixueCard = 80

sgs.ai_skill_invoke.kejieshengliufeng = function(self, data)
	return true
end

sgs.ai_hasTuntianEffect_skill.kejieshengliufeng = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_skill_choice.kejieshenghuixue = function(self, choices, data)
	local target = call(data,"toPlayer")
	local damage = getChoice(choices, "shenghuixue_damage")
	local recover = getChoice(choices, "shenghuixue_recover")
	if target and q(self,"isEnemy",target) and damage then
		return damage
	end
	return recover
end

sgs.ai_fill_skill.kejieshenghuixue=function(self,inclusive,request)
	if ((q(self.player,"getStrategyMark","&useshengshanghai") > 0) and (q(self.player,"getStrategyMark","&useshenghuixue") > 0)) then return end
	return q(self,"legacySkillSeed","kejieshenghuixue","#kejieshenghuixueCard",request)
end

sgs.ai_skill_use_func["#kejieshenghuixueCard"] = function(card,use,self,request)
	if q(self.player,"getStrategyMark","&useshengshanghai") == 0 then
		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy)
				and q(self.player,"getHp") > q(enemy,"getHp") and q(self.player,"getHp") > 1 and q(enemy,"canDiscard",enemy, "h")
			then
				use.card=q(self,"bindSkillCard","kejieshenghuixue",{},request,nil,"#kejieshenghuixueCard")
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	if q(self.player,"getStrategyMark","&useshenghuixue") == 0 and q(self.player,"canDiscard",self.player, "h") then
		for _, p in ipairs(self.friends_noself) do
			if q(p,"getHp") < getBestHp(p) and q(p,"isMale") and q(p,"canDiscard",p, "h") then
				use.card=q(self,"bindSkillCard","kejieshenghuixue",{},request,nil,"#kejieshenghuixueCard")
				if use.to then call(use.to,"append",p) end
				return
			end
		end
	end
end

sgs.ai_use_value.kejieshenghuixueCard = 8.5
sgs.ai_use_priority.kejieshenghuixueCard = 9.5
sgs.ai_card_intention.kejieshenghuixueCard = 80


--圣赵云


sgs.ai_fill_skill.keshengzhuihun=function(self,inclusive,request)
	if q(self,"needBear") then return nil end
	if q(self.player,"hasUsed","#keshengzhuihunCard") then return nil end
	if q(self.player,"getStrategyMark","keshengzhuihun") > 0 then return nil end
	if not q(self.player,"canDiscard",self.player, "h") then return nil end
	if not q(self,"slashIsAvailable",self.player) then return nil end
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	call(self,"sort",self.enemies, "hp")
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","Slash") then
			for _, enemy in ipairs(self.enemies) do
				if q(self.player,"canSlash",enemy, card) and q(self,"slashIsEffective",card, enemy) and q(self,"objectiveLevel",enemy) > 3 and q(self,"isGoodTarget",enemy, self.enemies, card) and not q(enemy,"isKongcheng") then
					if getCardsNum("Jink", enemy) < 1 or (q(self.player,"hasWeapon","axe") and q(self.player,"getCards","he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if q(card,"isKindOf","Duel") then
			for _, enemy in ipairs(self.enemies) do
				if q(self,"getCardsNum","Slash") >= getCardsNum("Slash", enemy) and q(self,"isGoodTarget",enemy, self.enemies, card) and not q(enemy,"isKongcheng")
					and q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy, self.player, 2) and q(self,"ajustDamage",self.player, enemy, 1, card) > 0 then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 then
		local card_id
		local cards = q(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			call(to_throw,"append",q(acard,"getEffectiveId"))
		end
		card_id = q(to_throw,"first")
		if not card_id then
			return nil
		else
			return q(self,"evaluateTurnSkillCard","keshengzhuihun","#keshengzhuihunCard",{card_id},request)
		end
	end
end

sgs.ai_skill_use_func["#keshengzhuihunCard"] = function(card,use,self,request)
	use.card = card
end


sgs.ai_ajustdamage_from.keshengzhuihun = function(self, from, to, slash, nature)
	if slash and (q(slash,"isKindOf","Slash") or q(slash,"isKindOf","Duel")) and not q(to,"isKongcheng") then
		return q(from,"getStrategyMark","&keshengzhuihun")
	end
end


sgs.ai_use_value.keshengzhuihun = 8.5
sgs.ai_use_priority.keshengzhuihun = 9.5
sgs.ai_card_intention.keshengzhuihun = -80


sgs.ai_skill_invoke.keshengjiuzhu = function(self, data)
	local target = call(self.room,"getCurrentDyingPlayer")
	if target and q(self,"canNiepan",target) then return false end
	if q(self.player,"getRole") == "loyalist" and q(self,"isWeak",call(self.room,"getLord"))
		and target and q(target,"objectName") ~= q(self.player,"objectName") and q(target,"objectName") ~= call(self.room,"getLord"):objectName() then
		return false
	end
	return q(self,"isFriend",target)
end


--界圣赵云


sgs.ai_fill_skill.kejieshengzhuihun=function(self,inclusive,request)
	if q(self.player,"hasUsed","#kejieshengzhuihunCard") then return end
	local has_Crossbow = false
	for _, c in ipairs(sgs.QList2Table(q(self.player,"getCards","h"))) do
		if q(c,"isKindOf","Crossbow") then
			has_Crossbow = true
		end
	end
	if has_Crossbow or q(self,"hasCrossbowEffect") then
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			local dummy_use = q(self,"aiUseCard",slash)
			if not q(dummy_use.to,"isEmpty") then return end
		end
	end

	return q(self,"legacySkillSeed","kejieshengzhuihun","#kejieshengzhuihunCard",request)
	
end

sgs.ai_skill_use_func["#kejieshengzhuihunCard"] = function(card,use,self,request)
	if not q(self.player,"hasUsed","#kejieshengzhuihunCard") then
		local handcards = sgs.QList2Table(q(self.player,"getCards","he"))
		local discard_cards = {}
		call(self,"sortByUseValue",handcards)
		local equip_check = true
		local basic_check = true
		local trick_check = true
		local should_equip = false
		local slashcount = q(self,"getCardsNum","Slash")
		local dc=q(self,"cloneEvaluationCard","slash") -- donor dummyCard: NoSuit/0, empty skill and costs
		local d = q(self,"withOwnerRange","InfinityAttackRange","kejieshengzhuihun",function()
			return q(self,"aiUseCard",dc,dummy(true))
		end)
		if d.card then
			for _,p in sgs.qlist(d.to) do
				if not q(self.player,"inMyAttackRange",p) then
					should_equip = true
					break
				end
			end
		end
		for _, c in ipairs(handcards) do
			if not q(c,"isKindOf","Peach")
				and not q(c,"isKindOf","Duel")
				and not q(c,"isKindOf","Indulgence")
				and not q(c,"isKindOf","SupplyShortage")
				and not (q(self,"getCardsNum","Jink") == 1 and q(c,"isKindOf","Jink"))
				and not (q(self,"getCardsNum","Analeptic") == 1 and q(c,"isKindOf","Analeptic"))
			then
				if equip_check and q(c,"isKindOf","EquipCard") and should_equip and slashcount > 0 then
					equip_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				elseif basic_check and q(c,"isKindOf","BasicCard") and slashcount > 0 then
					basic_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				elseif trick_check and q(c,"isKindOf","TrickCard") then
					trick_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				end
				if #discard_cards == 3 then
					break
				end
			end
		end
		if #discard_cards > 0 then
			local card_str = string.format("#kejieshengzhuihunCard:%s:", table.concat(discard_cards, "+"))
			use.card=q(self,"bindSkillCard","kejieshengzhuihun",discard_cards,request,nil,"#kejieshengzhuihunCard")
		end
		return
	end
end

function sgs.ai_cardneed.keshengzhuihun(to, card, self)
	if q(self.player,"hasUsed","#kejieshengzhuihunCard") then return false end
	return true
end

sgs.ai_use_value.kejieshengzhuihunCard = 8.5
sgs.ai_use_priority.kejieshengzhuihunCard = 9.5
sgs.ai_card_intention.kejieshengzhuihunCard = -80

sgs.ai_cardneed.kejieshengqinggang = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.kejieshengqinggang = function(self, data)
	local target = call(data,"toPlayer")
	if target then
		return q(self,"doDisCard",target, "he")
	end
	return false
end

sgs.ai_skill_invoke.kejieshengjiuzhu = function(self, data)
	--local target = call(self.room,"getCurrentDyingPlayer")
	local target = call(data,"toPlayer")
	if target and q(self,"canNiepan",target) then return false end
	if (q(self.player,"getRole") == "loyalist" or q(self.player,"getRole") == "renegade")   and q(self,"isWeak",call(self.room,"getLord"))
		and target and q(target,"objectName") ~= q(self.player,"objectName") and q(target,"objectName") ~= call(self.room,"getLord"):objectName() then
		return false
	end
	return q(self,"isFriend",target)
end

--圣郭嘉
sgs.ai_skill_invoke.keshengqizuo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(p,"getStrategyMark","&keshengqizuo") == 0 then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.keshengqizuo = 50

sgs.ai_can_damagehp.keshengqizuo = function(self, from, card, to)
	return q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
		and q(self,"canLoseHp",from, card, to)
end

sgs.ai_skill_invoke.keshengxiangzhi = function(self, data)
	return true
end

--[[sgs.ai_skill_askforyiji.keshengxiangzhi = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end]]
sgs.ai_skill_askforyiji.keshengxiangzhi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then table.insert(available_friends, friend) end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = q(self,"getKnownCardById",id)
		if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
			keep = true
		else
			table.insert(toGive, card)
		end
		table.insert(allcards, card)
	end

	local cards = #toGive > 0 and toGive or allcards
	call(self,"sortByKeepValue",cards, true)
	local id = cards[1]:getId()

	local card, friend = call(self,"getCardNeedPlayer",cards)
	if card and friend and table.contains(available_friends, friend) then return friend, q(card,"getId") end

	if #available_friends > 0 then
		call(self,"sort",available_friends, "handcard")
		for _, afriend in ipairs(available_friends) do
			if not q(self,"needKongcheng",afriend, true) then
				return afriend, id
			end
		end
		call(self,"sort",available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end

--界圣郭嘉

sgs.ai_skill_invoke.kejieshengqizuo = function(self, data)
	return true
end
sgs.ai_skill_playerchosen.kejieshengqizuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(p,"getStrategyMark","&kejieshengqizuo") == 0 then
			return p
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kejieshengqizuo_get = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieshengqizuo = 50

sgs.ai_can_damagehp.kejieshengqizuo = function(self, from, card, to)
	return q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
		and q(self,"canLoseHp",from, card, to)
end

sgs.ai_skill_invoke.kejieshengxiangzhi = function(self, data)
	return true
end

--[[sgs.ai_skill_askforyiji.kejieshengxiangzhi = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end]]
sgs.ai_skill_askforyiji.kejieshengxiangzhi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and not q(self,"isLihunTarget",friend) then
			table.insert(available_friends,
				friend)
		end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = q(self,"getKnownCardById",id)
		if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
			keep = true
		else
			table.insert(toGive, card)
		end
		table.insert(allcards, card)
	end

	local cards = #toGive > 0 and toGive or allcards
	call(self,"sortByKeepValue",cards, true)
	local id = cards[1]:getId()

	local card, friend = call(self,"getCardNeedPlayer",cards)
	if card and friend and table.contains(available_friends, friend) then return friend, q(card,"getId") end

	if #available_friends > 0 then
		call(self,"sort",available_friends, "handcard")
		for _, afriend in ipairs(available_friends) do
			if not q(self,"needKongcheng",afriend, true) then
				return afriend, id
			end
		end
		call(self,"sort",available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end


--程普

sgs.ai_skill_invoke.keshengtonggui = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keshengtonggui = function(self, targets)
	targets = sgs.QList2Table(targets)
	call(self,"sort",targets, "handcard")
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.keshengtonggui = 50

sgs.ai_skill_invoke.keshengfuchou = function(self, data)
	local current = call(self.room,"getCurrent")
	if current and q(self,"isEnemy",current) then
		return true
	else
		return false
	end
end

sgs.ai_choicemade_filter.skillInvoke.keshengfuchou = function(self, player, promptlist)
	local current = call(self.room,"getCurrent")
	if current and promptlist[3] == "yes" then
		call(self,"updateIntention",player, current, 20)
	end
end

sgs.ai_can_damagehp.keshengfuchou = function(self, from, card, to)
	if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
		and q(self,"canLoseHp",from, card, to)
	then
		return q(self,"isEnemy",from) and q(self,"getOverflow",from) > 0 and q(from,"getCardCount") > 0
	end
end

sgs.ai_skill_invoke.kejieshengtonggui = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kejieshengtonggui = function(self, targets)
	targets = sgs.QList2Table(targets)
	call(self,"sort",targets, "handcard")
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieshengtonggui = 50



sgs.ai_skill_invoke.kejieshengfuchou = function(self, data)
	local current = call(self.room,"getCurrent")
	if current and q(self,"isEnemy",current) then
		return true
	else
		return false
	end
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengfuchou = function(self, player, promptlist)
	local current = call(self.room,"getCurrent")
	if current and promptlist[3] == "yes" then
		call(self,"updateIntention",player, current, 20)
	end
end

sgs.ai_can_damagehp.kejieshengfuchou = function(self, from, card, to)
	if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
		and q(self,"canLoseHp",from, card, to)
	then
		return q(self,"isEnemy",from) and q(self,"getOverflow",from) > 0 and q(from,"getCardCount") > 0
	end
end


--公孙瓒

sgs.ai_skill_invoke.keshengyuma = function(self, data)
	return true
end
function sgs.ai_cardneed.keshengyuma(to, card)
	return q(card,"isKindOf","OffensiveHorse") or q(card,"isKindOf","DefensiveHorse")
end

sgs.ai_skill_invoke.kejieshengyuma = function(self, data)
	return true
end

function sgs.ai_cardneed.kejieshengyuma(to, card)
	return q(card,"isKindOf","OffensiveHorse") or q(card,"isKindOf","DefensiveHorse")
end

sgs.ai_skill_invoke.kejieshengliema = function(self, data)
	local mode = q(self.room,"getMode")
	if q(mode,"find","_mini_41") or q(mode,"find","_mini_46") then return true end
	local damage = q(data,"toDamage")
	local target = damage.from
	if target then
		if q(self,"isEnemy",target) and q(self,"doDisCard",target, "he") then
			return true
		elseif q(self,"isFriend",target) and q(self,"doDisCard",target, "he") then
			return true
		end
	end
	return false
end
function sgs.ai_slash_prohibit.kejieshengliema(self, from, to)
	if q(self,"isFriend",from, to) then return false end
	if q(from,"hasSkill","jueqing") or (q(from,"hasSkill","nosqianxi") and q(from,"distanceTo",to) == 1) then return false end
	if q(from,"getStrategyFlag","NosJiefanUsed") then return false end
	if q(from,"getHandcardNum") == 1 and q(from,"getEquips"):length() == 0 and sole_slash(self,from) and q(from,"getHp") >= 2 then return false end
	return (q(from,"getHp") + q(from,"getEquips"):length() < 4 or q(from,"getHp") < 2) and
		(call(from,"getOffensiveHorse") or call(from,"getDefensiveHorse"))
end

sgs.ai_choicemade_filter.skillInvoke.kejieshengliema = function(self, player, promptlist)
	local damage = current_damage(self)
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",damage.to, damage.from, 40)
		elseif q(self,"canAttack",damage.from) then
			call(self,"updateIntention",damage.to, damage.from, -40)
		end
	end
end
