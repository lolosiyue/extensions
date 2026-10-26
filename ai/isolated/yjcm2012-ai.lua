-- Source: b6025acc ai/yjcm2012-ai.lua.
local known = AIValue.requireKnown
local function has_skill(self,player,names,multiple)
    local value=AIValue.callKnown(player,multiple and "hasSkills" or "hasSkill",names)
    local view=type(player)=="table" and rawget(player,"_view")
    if value==true or value~=nil and (not view or view.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then
        ai_unsupported("YJCM2012 owner skill roster is incomplete",names)
    end
    return self:useKnowledgeEstimate({status="estimate",value=false,player=player:objectName(),
        basis="yjcm2012.undisclosed_skill_uses_visible_roster"},names)
end
local function own_tag(self,key,kind,default)
    local value=self.player:getTag(key)
    if value==nil then return default end
    if type(value)~=kind then ai_unsupported("YJCM2012 owner tag has an unexpected type",key) end
    return value
end
local function visible_card(self,id)
    return known(self:getChoiceCard(id) or self:getKnownCardById(id),"disclosed card "..tostring(id))
end
local dummy = AIUsePlan.dummy
local function legacy(self,skill,class,costs,request,user_string)
    return (self:bindSkillCard(skill,costs,request,user_string,class))
end
local function role(self,player)
    return player==self.player and (player:getKnownRole()) or (self:getRoleEstimate(player))
end
local function lihuo_spec(card)
    return {name="fire_slash",skill="lihuo",suit=(card:getSuit()),number=(card:getNumber()),subcards={(card:getKnownEffectiveId())}}
end
ai_skill_invoke.qianxi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if (self.player:getStrategyFlag("AI_doNotInvoke_qianxi")) then
		self:setStrategyPlayerFlag(self.player,"AI_doNotInvoke_qianxi",false)
		return false
	end
	if (self.player:getPile("incantation")):length()>0 then
		local card = visible_card(self,(self.player:getPile("incantation")):first())
		if not (self.player:getJudgingArea()):isEmpty() and not (self.player:containsTrick("YanxiaoCard")) and not self:hasWizard(self.enemies,true) then
			local trick = (self.player:getJudgingArea()):last()
			if (trick:isKindOf("Indulgence")) then
				if (card:getSuit())==sgs.Card_Heart or (has_skill(self,self.player,"hongyan") and (card:getSuit())==sgs.Card_Spade) then return (false) or false end
			elseif (trick:isKindOf("SupplyShortage")) then
				if (card:getSuit())==sgs.Card_Club then return (false) or false end
			end
		end
		local zhangbao = self.room:findPlayerBySkillName("yingbing")
		if zhangbao and self:isEnemy(zhangbao) and not has_skill(self,zhangbao,"manjuan")
			and (card:isRed() or (has_skill(self,self.player,"hongyan") and (card:getSuit())==sgs.Card_Spade)) then return (false) or false end
	end
	for _,p in ipairs(self.enemies)do
		if (self.player:distanceTo(p))==1 and not (p:isKongcheng()) then
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.qianxi = function(self,targets)
	local enemies = {}
	local slash = self:getCard("Slash") or (self:getEvaluationCard("slash"))
	local isRed = (own_tag(self,"qianxi","string","")=="red")

	for _,target in sgs.qlist(targets)do
		if self:isEnemy(target) and not (target:isKongcheng()) then
			table.insert(enemies,target)
		end
	end

	if #enemies==1 then
		return enemies[1]
	else
		self:sortInPlace(enemies, "defense")
		if not isRed then
			for _,enemy in ipairs(enemies)do
				if has_skill(self,enemy,"qingguo") and self:slashIsEffective(slash,enemy) then return enemy end
			end
			for _,enemy in ipairs(enemies)do
				if has_skill(self,enemy,"kanpo") then return enemy end
			end
		else
			for _,enemy in ipairs(enemies)do
				if getKnownCard(enemy,self.player,"Jink",false,"h")>0 and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then return enemy end
			end
			for _,enemy in ipairs(enemies)do
				if getKnownCard(enemy,self.player,"Peach",true,"h")>0 or has_skill(self,enemy,"jijiu") then return enemy end
			end
			for _,enemy in ipairs(enemies)do
				if getKnownCard(enemy,self.player,"Jink",false,"h")>0 and self:slashIsEffective(slash,enemy) then return enemy end
			end
		end
		for _,enemy in ipairs(enemies)do
			if has_skill(self,enemy,"longhun") then return enemy end
		end
		return enemies[1]
	end
	return targets:first()
end

sgs.ai_playerchosen_intention.qianxi = 80

function sgs.ai_cardneed.dangxian(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end

ai_skill_invoke.noszishou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self:needBear() then return (true) or false end
	if (self.player:isSkipped(sgs.Player_Play)) then return (true) or false end

	local chance_value = 1
	local peach_num = self:getCardsNum("Peach")
	local can_save_card_num = self:getOverflow(self.player,true)-(self.player:getHandcardNum())

	if (self.player:getHp())<=2 and (self.player:getHp())<getBestHp(self.player) then chance_value = chance_value+1 end
	if has_skill(self,self.player,"nosrende|rende",true) and self:findFriendsByType(sgs.Friend_Draw) then chance_value = chance_value-1 end
	if has_skill(self,self.player,"qingnang") then
		for _,friend in ipairs(self.friends)do
			if (friend:isWounded()) then chance_value = chance_value-1 break end
		end
	end
	if has_skill(self,self.player,"jieyin") then
		for _,friend in ipairs(self.friends)do
			if (friend:isWounded()) and (friend:isMale()) then chance_value = chance_value-1 break end
		end
	end

	return (self:ImitateResult_DrawNCards(self.player,(self.player:getVisibleSkillList(true)))-can_save_card_num+peach_num<=chance_value) or false
end

ai_skill_invoke.fuli = true

function sgs.ai_cardsview.fuhun(self,class_name,player)
	return cardsView_spear(self,player,"fuhun")
end

ai_fill_skill.fuhun = function(self, options, request)
    local inclusive = options and options.inclusive

	return turnUse_spear(self,"fuhun",request)
end

function ai_skill_invoke.zhenlie(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if not use.from or (use.from:isDead()) then return (false) or false end
	if (self.player:getKnownRole())=="rebel" and role(self,use.from)=="rebel" and not has_skill(self,use.from,"jueqing")
	and (self.player:getHp())<2 and self:getAllPeachNum()<1 then return (false) or false end

	if self:isEnemy(use.from)
	or (self:isFriend(use.from) and (self.player:getKnownRole())=="loyalist" and not has_skill(self,use.from,"jueqing") and (use.from:isLord()) and (self.player:getHp())<2) then
		if (use.card:isKindOf("Slash")) then
			if not self:slashIsEffective(use.card,self.player,use.from) then return (false) or false end
			if self:ajustDamage(use.from,self.player,1,use.card)>1 then return (true) or false end
			local jink_num = self:getExpectedJinkNum(use)
			local hasHeart = false
			local jn = 0
			for _,card in ipairs(self:getCards("Jink"))do
				if (card:getSuit())==sgs.Card_Heart then
					hasHeart = true
				end
				jn = jn+1
			end
			if jn<1 or jink_num<1 or jn<jink_num
			or (self.player:getStrategyFlag("dahe")) and not hasHeart then
				if (use.card:isKindOf("NatureSlash")) and (self.player:isChained()) and not self:isGoodChainTarget(self.player,use.card,use.from) then return (true) or false end
				if has_skill(self,use.from,"nosqianxi") and (use.from:distanceTo(self.player))==1 then return (true) or false end
				if self:isFriend(use.from) and (self.player:getKnownRole())=="loyalist" and not has_skill(self,use.from,"jueqing") and (use.from:isLord()) and (self.player:getHp())<2 then return (true) or false end
				if (not (self:hasSkills(sgs.masochism_skill) or (has_skill(self,self.player,"tianxiang") and getKnownCard(self.player,self.player,"heart")>0)) or has_skill(self,use.from,"jueqing"))
				and self:doDisCard(use.from,"he") then
					return (true) or false
				end
			end
		elseif (use.card:isKindOf("AOE")) then
			local from = use.from
			if (use.card:isKindOf("SavageAssault")) then
				local menghuo = self.room:findPlayerBySkillName("huoshou")
				if menghuo then from = menghuo end
			end

			local friend_null = 0
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
				if self:isFriend(p) then friend_null = friend_null+getCardsNum("Nullification",p,self.player) end
				if self:isEnemy(p) then friend_null = friend_null-getCardsNum("Nullification",p,self.player) end
			end
			friend_null = friend_null+self:getCardsNum("Nullification")
			local sj_num = self:getCardsNum((use.card:isKindOf("SavageAssault")) and "Slash" or "Jink")

			if not self:hasTrickEffective(use.card,self.player,from) then return (false) or false end
			if not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,from) then return (false) or false end
			if has_skill(self,use.from,"drwushuang") and (self.player:getCardCount())==1 and self:hasLoseHandcardEffective() then return (true) or false end
			if sj_num==0 and friend_null<=0 then
				if self:isEnemy(from) and has_skill(self,from,"jueqing") then return (self:doDisCard(from,"he")) or false end
				if self:isFriend(from) and (self.player:getKnownRole())=="loyalist" and (from:isLord()) and (self.player:getHp())==1 and not has_skill(self,from,"jueqing") then return (true) or false end
				if (not (self:hasSkills(sgs.masochism_skill) or has_skill(self,self.player,"tianxiang") and getKnownCard(self.player,self.player,"heart")>0) or has_skill(self,use.from,"jueqing"))
					and self:doDisCard(use.from,"he") then
					return (true) or false
				end
			end
		elseif self:isEnemy(use.from) then
			if not self:hasTrickEffective(use.card,self.player) then return (false) or false end
			if (use.card:isKindOf("FireAttack")) and (use.from:getHandcardNum())>0 then
				if not self:damageIsEffective(self.player,sgs.DamageStruct_Fire,use.from) then return (false) or false end
                if ((self.player:hasArmorEffect("Vine")) or (self.player:getStrategyMark("&kuangfeng"))>0) and (use.from:getHandcardNum())>3
				and not(has_skill(self,use.from,"hongyan") and getKnownCard(self.player,self.player,"spade")>0)
				then return (self:doDisCard(use.from,"he")) or false
				elseif (self.player:isChained()) and not self:isGoodChainTarget(self.player,nil,use.from)
				then return (self:doDisCard(use.from,"he")) or false end
			elseif ((use.card:isKindOf("Snatch")) or (use.card:isKindOf("Dismantlement")))
			and self:getCardsNum("Peach")==(self.player:getHandcardNum()) and not (self.player:isKongcheng())
			then return (self:doDisCard(use.from,"he")) or false
			elseif (use.card:isKindOf("Duel")) then
				if self:getCardsNum("Slash")<1
				or self:getCardsNum("Slash")<getCardsNum("Slash",use.from,self.player) then
					if not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,use.from) then return (false) or false end
					return (self:doDisCard(use.from,"he")) or false
				end
			elseif (use.card:isKindOf("TrickCard")) and not (use.card:isKindOf("AmazingGrace")) then
				return (self:doDisCard(use.from,"he") and self:needToLoseHp(self.player,nil,use.card)) or false
			end
		end
	end
	return false

end

ai_skill_choice.miji_draw = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	return ai_choice_result((""..(self.player:getLostHp())), options)
end

ai_skill_invoke.miji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.friends_noself==0 then return (false) or false end
	for _,friend in ipairs(self.friends_noself)do
		if not has_skill(self,friend,"manjuan") and not self:isLihunTarget(friend) then return (true) or false end
	end
	return (false) or false
end

sgs.ai_skill_askforyiji.miji = function(self,card_ids)
	local available_friends = {}
	for _,friend in ipairs(self.friends_noself)do
		if not has_skill(self,friend,"manjuan") and not self:isLihunTarget(friend) then table.insert(available_friends,friend) end
	end

	local toGive,allcards = {},{}
	local keep
	for _,id in ipairs(card_ids)do
		local card = visible_card(self,id)
		if not keep and (isCard("Jink",card,self.player) or isCard("Analeptic",card,self.player)) then
			keep = true
		else
			table.insert(toGive,card)
		end
		table.insert(allcards,card)
	end

	local cards = #toGive>0 and toGive or allcards
	self:sortByKeepValueInPlace(cards, true)
	local id = cards[1]:getId()

	local card,friend = self:getCardNeedPlayer(cards)
	if card and friend and table.contains(available_friends,friend) then return friend,(card:getKnownId()) end

	if #available_friends>0 then
		self:sortInPlace(available_friends, "handcard")
		for _,afriend in ipairs(available_friends)do
			if not self:needKongcheng(afriend,true) then
				return afriend,id
			end
		end
		self:sortInPlace(available_friends, "defense")
		return available_friends[1],id
	end
	return nil,-1
end

ai_skill_invoke.secondmiji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	for _,friend in ipairs(self.friends)do
		if self:canDraw(friend) then return (true) or false end
	end
	return (false) or false
end

sgs.ai_skill_askforyiji.secondmiji = function(self,card_ids,tos)
	local optional = own_tag(self,"SecondMijiOptional","boolean",false)
	
	if optional then
		return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	end
	
	return sgs.ai_skill_askforyiji.miji(self,card_ids,tos)
end

function sgs.ai_cardneed.jiangchi(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)<2
end

ai_skill_choice.jiangchi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local target = 0
	local goodtarget = 0
	local slashnum = 0
	local needburst = 0

	for _,slash in ipairs(self:getCards("Slash"))do
		for _,enemy in ipairs(self.enemies)do
			if self:slashIsEffective(slash,enemy) then
				slashnum = slashnum+1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		for _,slash in ipairs(self:getCards("Slash"))do
			if not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then
				goodtarget = goodtarget+1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if (self.player:canSlash(enemy)) then
			target = target+1
			break
		end
	end

	if slashnum>1 or (slashnum>0 and goodtarget>0) then needburst = 1 end
	self:sortInPlace(self.enemies, "defenseSlash")
	local can_save_card_num = (self.player:getMaxCards())-(self.player:getHandcardNum())
	if target==0 or can_save_card_num>1 or (self.player:isSkipped(sgs.Player_Play)) then return ai_choice_result(("jiang"), options) end
	if self:needBear() then return ai_choice_result(("jiang"), options) end

	for _,enemy in ipairs(self.enemies)do
		local def = (self:getDefense(enemy))
		local slash = (self:getEvaluationCard("slash"))
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if self:slashProhibit(slash,enemy) then
		elseif eff and def<8 and needburst>0 then return ai_choice_result(("chi"), options)
		end
	end

	return ai_choice_result(("cancel"), options)
end

ai_fill_skill.gongqi = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	if #self.enemies==0 then return end
	local cards = (self.player:getCards("he"))
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then
		return legacy(self,"gongqi","GongqiCard",{self.player:getArmor():getEffectiveId()},request)
	end

	for _,c in ipairs(cards)do
		if (c:isKindOf("Weapon")) then return legacy(self,"gongqi","GongqiCard",{(c:getKnownEffectiveId())},request) end
	end

	local handcards = (self.player:getHandcards())
	handcards = sgs.QList2Table(handcards)
	local has_weapon,has_armor,has_def,has_off = false,false,false,false
	local weapon,armor
	for _,c in ipairs(handcards)do
		if (c:isKindOf("Weapon")) then
			has_weapon = true
			if not weapon or self:evaluateWeapon(weapon)<self:evaluateWeapon(c) then weapon = c end
		end
		if (c:isKindOf("Armor")) then
			has_armor = true
			if not armor or self:evaluateArmor(armor)<self:evaluateArmor(c) then armor = c end
		end
		if (c:isKindOf("DefensiveHorse")) then has_def = true end
		if (c:isKindOf("OffensiveHorse")) then has_off = true end
	end
	if has_off and self.player:getOffensiveHorse() then return legacy(self,"gongqi","GongqiCard",{self.player:getOffensiveHorse():getEffectiveId()},request) end
	if has_def and self.player:getDefensiveHorse() then return legacy(self,"gongqi","GongqiCard",{self.player:getDefensiveHorse():getEffectiveId()},request) end
	if has_weapon and self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<=self:evaluateWeapon(weapon) then
		return legacy(self,"gongqi","GongqiCard",{self.player:getWeapon():getEffectiveId()},request)
	end
	if has_armor and self.player:getArmor() and self:evaluateArmor(self.player:getArmor())<=self:evaluateArmor(armor) then
		return legacy(self,"gongqi","GongqiCard",{self.player:getArmor():getEffectiveId()},request)
	end

	if self:getOverflow()>0 and self:getCardsNum("Slash")>=1 then
		self:sortByKeepValueInPlace(handcards)
		self:sortInPlace(self.enemies, "defense")
		for _,c in ipairs(handcards)do
			if (c:isKindOf("Snatch")) or (c:isKindOf("Dismantlement")) then
				local use = dummy()
				self:useCardSnatch(c,use)
				if use.card then return end
			elseif isCard("Peach",c,self.player)
				or isCard("ExNihilo",c,self.player)
				or (isCard("Analeptic",c,self.player) and (self.player:getHp())<=2)
				or (isCard("Jink",c,self.player) and self:getCardsNum("Jink")<2)
				or (isCard("Nullification",c,self.player) and self:getCardsNum("Nullification")<2)
				or (isCard("Slash",c,self.player) and self:getCardsNum("Slash")==1) then
			elseif not (c:isKindOf("EquipCard")) and #self.enemies>0 and (self.player:inMyAttackRange(self.enemies[1])) then
			else
				return legacy(self,"gongqi","GongqiCard",{(c:getKnownEffectiveId())},request)
			end
		end
	end
end

ai_card_use.GongqiCard = function(self, card, use, request)
	local id = (card:getSubcards()):first()
	local subcard = visible_card(self,id)
	if (subcard:isKindOf("SilverLion")) and self.room:getCardPlace(id)==sgs.Player_PlaceHand and (self:isWounded()) then
		use.card = subcard
		return
	end
	use.card = card
end

sgs.ai_skill_playerchosen.gongqi = function(self,targets)
	local player = self:findPlayerToDiscard()[1]
	return player
end

sgs.ai_use_value.GongqiCard = 2
sgs.ai_use_priority.GongqiCard = 8

ai_fill_skill.jiefan = function(self, options, request)
    local inclusive = options and options.inclusive

	return (self:legacySkillSeed("jiefan","JiefanCard",request))
end

ai_card_use.JiefanCard = function(self, card, use, request)
	local target
	local use_value = 0
	local max_value = -10000
	local p_count = 0
	for _,friend in ipairs(self.friends)do
		use_value = 0
		local count = 0
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if (p:inMyAttackRange(friend)) then
				count = count+1
				if self:isFriend(p) then
					if not has_skill(self,friend,"manjuan") then use_value = use_value+1 end
				else
					if p:getWeapon() then
						use_value = use_value+1.2
					else
						if not has_skill(self,friend,"manjuan") then use_value = use_value+(p:getHandcardNum())/5 end
					end
				end
			end
		end
		if friend:objectName()==self.player:objectName() then p_count = count end
		use_value = use_value-(friend:getHandcardNum())/2
		if use_value>max_value then
			max_value = use_value
			target = friend
		end
	end

	if target and max_value>=(self.player:aliveCount())/2 then
		use.card = legacy(self,"jiefan","JiefanCard",{},request)
		use.to:append(target)
		return
	end

	if self:isWeak() and p_count>0 then
		use.card = legacy(self,"jiefan","JiefanCard",{},request)
		use.to:append(self.player)
		return
	end
end

sgs.ai_skill_cardask["@jiefan-discard"] = function(self,data)
	local player = data:toPlayer()
	if not player or not (player:isAlive()) or has_skill(self,player,"manjuan") or self:isFriend(player) then return "." end
	for _,card in sgs.qlist((self.player:getCards("he")))do
		if (card:isKindOf("Weapon")) and not (self.player:hasEquip(card)) then
			return (card:getKnownEffectiveId())
		end
	end

	if not self.player:getWeapon() then return "." end
	local count = 0
	-- This VM's sgs.weapon_range registry stands in for the donor's; SWIG truncates the fix to int.
	local range_fix = ( sgs.weapon_range[(self.player:getWeapon():getClassName())] or 1 )-(self.player:getAttackRange(false))
	range_fix = range_fix<0 and math.ceil(range_fix) or math.floor(range_fix)

	for _,p in sgs.qlist(self.room:getAllPlayers())do
		if self:isEnemy(p) and known(self.player:distanceTo(p,range_fix),"Jiefan target distance")>(self.player:getAttackRange()) then count = count+1 end
	end

	if count<=2 then return self.player:getWeapon():getEffectiveId() end
	return "."
end

sgs.ai_card_intention.JiefanCard = -80

function sgs.ai_cardneed.jiefan(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end

ai_fill_skill.anxu = function(self, options, request)
    local inclusive = options and options.inclusive

	return (self:legacySkillSeed("anxu","AnxuCard",request))
end

ai_card_use.AnxuCard = function(self, card, use, request)
	if #self.enemies==0 then return end
	local intention = 50
	local friends = {}
	for _,friend in ipairs(self.friends_noself)do
		if has_skill(self,friend,"manjuan") then
			if self:needKongcheng(friend,true) then table.insert(friends,friend) end
		elseif not self:needKongcheng(friend,true) then
			table.insert(friends,friend)
		end
	end
	self:sortInPlace(friends, "handcard")

	local least_friend,most_friend
	if #friends>0 then
		least_friend = friends[1]
		most_friend = friends[#friends]
	end

	local need_kongcheng_friend
	for _,friend in ipairs(friends)do
		if (friend:getHandcardNum())==1 and (has_skill(self,friend,"kongcheng") or (has_skill(self,friend,"zhiji") and (friend:getStrategyMark("zhiji"))==0 and (friend:getHp())>=3)) then
			need_kongcheng_friend = friend
			break
		end
	end

	local enemies = {}
	for _,enemy in ipairs(self.enemies)do
		if not (self:hasTuntianEffect(enemy,true)) and not ((enemy:isKongcheng()) or ((enemy:getHandcardNum())<=1 and self:needKongcheng(enemy))) then
			table.insert(enemies,enemy)
		end
	end

	self:sortInPlace(enemies, "handcard")
	enemies = sgs.reverse(enemies)
	local most_enemy
	if #enemies>0 then most_enemy = enemies[1] end

	local prior_enemy,kongcheng_enemy,manjuan_enemy
	for _,enemy in ipairs(enemies)do
		if (enemy:getHandcardNum())>=2 and self:hasSkills(sgs.cardneed_skill,enemy) then
			if not prior_enemy then prior_enemy = enemy end
		end
		if has_skill(self,enemy,"kongcheng") and (enemy:isKongcheng()) then
			if not kongcheng_enemy then kongcheng_enemy = enemy end
		end
		if has_skill(self,enemy,"manjuan") then
			if not manjuan_enemy then manjuan_enemy = enemy end
		end
		if prior_enemy and kongcheng_enemy and manjuan_enemy then break end
	end

	-- Enemy -> Friend
	if least_friend then
		local tg_enemy
		if not tg_enemy and prior_enemy and (prior_enemy:getHandcardNum())>(least_friend:getHandcardNum()) then tg_enemy = prior_enemy end
		if not tg_enemy and most_enemy  and (most_enemy:getHandcardNum())>(least_friend:getHandcardNum()) then tg_enemy = most_enemy end
		if tg_enemy  then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(tg_enemy)
			use.to:append(least_friend)
			if not use.isDummy then
				self:updateIntention(self.player,tg_enemy,intention)
				self:updateIntention(self.player,least_friend,-intention)
			end
			return
		end

		if most_enemy and (most_enemy:getHandcardNum())>(least_friend:getHandcardNum()) then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(most_enemy)
			use.to:append(least_friend)
			if not use.isDummy then
				self:updateIntention(self.player,most_enemy,intention)
				self:updateIntention(self.player,least_friend,-intention)
			end
			return
		end
	end

	self:sortInPlace(enemies, "defense")
	if least_friend then
		for _,enemy in ipairs(enemies)do
			local hand1 = (enemy:getHandcardNum())
			local hand2 = (least_friend:getHandcardNum())

			if (hand1>hand2) then
				use.card = legacy(self,"anxu","AnxuCard",{},request)
				use.to:append(enemy)
				use.to:append(least_friend)
				return
			end
		end
	end



	self:sortInPlace(enemies, "handcard", true)
	-- Friend -> Friend
	if #friends>=2 then
		if need_kongcheng_friend and (least_friend:isKongcheng()) then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(need_kongcheng_friend)
			use.to:append(least_friend)
			if not use.isDummy then
				self:updateIntention(self.player,need_kongcheng_friend,-intention)
				self:updateIntention(self.player,least_friend,-intention)
			end
			return
		elseif (most_friend:getHandcardNum())>=4 and (most_friend:getHandcardNum())>(least_friend:getHandcardNum()) then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(most_friend)
			use.to:append(least_friend)
			if not use.isDummy then self:updateIntention(self.player,least_friend,-intention) end
			return
		end
	end

	-- Enemy -> Enemy
	if kongcheng_enemy and not has_skill(self,kongcheng_enemy,"manjuan") then
		local tg_enemy = prior_enemy or most_enemy
		if tg_enemy and not (tg_enemy:isKongcheng()) then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(tg_enemy)
			use.to:append(kongcheng_enemy)
			if not use.isDummy then
				self:updateIntention(self.player,tg_enemy,intention)
				self:updateIntention(self.player,kongcheng_enemy,intention)
			end
			return
		elseif most_friend and (most_friend:getHandcardNum())>=4 then -- Friend -> Enemy for KongCheng
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(most_friend)
			use.to:append(kongcheng_enemy)
			if not use.isDummy then self:updateIntention(self.player,kongcheng_enemy,intention) end
			return
		end
	elseif manjuan_enemy then
		local tg_enemy = prior_enemy or most_enemy
		if tg_enemy and (tg_enemy:getHandcardNum())>(manjuan_enemy:getHandcardNum()) then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(tg_enemy)
			use.to:append(manjuan_enemy)
			if not use.isDummy then self:updateIntention(self.player,tg_enemy,intention) end
			return
		end
	elseif most_enemy then
		local tg_enemy,second_enemy
		if prior_enemy then
			for _,enemy in ipairs(enemies)do
				if (enemy:getHandcardNum())<(prior_enemy:getHandcardNum()) then
					second_enemy = enemy
					tg_enemy = prior_enemy
					break
				end
			end
		end
		if not second_enemy then
			tg_enemy = most_enemy
			for _,enemy in ipairs(enemies)do
				if (enemy:getHandcardNum())<(most_enemy:getHandcardNum()) then
					second_enemy = enemy
					break
				end
			end
		end
		if tg_enemy and second_enemy then
			use.card = legacy(self,"anxu","AnxuCard",{},request)
			use.to:append(tg_enemy)
			use.to:append(second_enemy)
			if not use.isDummy then
				self:updateIntention(self.player,tg_enemy,intention)
				self:updateIntention(self.player,second_enemy,intention)
			end
			return
		end
	end
end

sgs.ai_card_intention.AnxuCard = 0
sgs.ai_use_priority.AnxuCard = 9.6


sgs.ai_skill_playerchosen.zhuiyi = function(self,targets)
	local first,second
	targets = sgs.QList2Table(targets)
	self:sortInPlace(targets, "defense")
	for _,friend in ipairs(targets)do
		if self:isFriend(friend) and (friend:isAlive()) and not (has_skill(self,friend,"manjuan") and (friend:getPhase())==sgs.Player_NotActive and (friend:getLostHp())==0) then
			if isLord(friend) and self:isWeak(friend) then return friend end
			if not (has_skill(self,friend,"zhiji") and (friend:getStrategyMark("zhiji"))==0 and not self:isWeak(friend) and (friend:getPhase())==sgs.Player_NotActive) then
				if role(self,friend)=="renegade" then second = friend
				elseif role(self,friend)~="renegade" and not first then first = friend
				end
			end
		end
	end
	return first or second
end


function sgs.ai_cardneed.lihuo(to,card,self)
	local slash = (card:isKindOf("Slash")) and not ((card:isKindOf("FireSlash")) or (card:isKindOf("ThunderSlash")))
	return ((card:isKindOf("FireSlash")) and getKnownCard(to,self.player,"FireSlash",false)==0) or (slash and getKnownCard(to,self.player,"Slash",false)==0)
end

ai_skill_invoke.lihuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if (self.player:hasWeapon("fan")) then return (false) or false end
	if not ai_skill_invoke.fan(self, options, request) then return (false) or false end
	local use = data:toCardUse()
	for _,player in sgs.qlist(use.to)do
		if self:isEnemy(player) and self:isGoodTarget(player,self.enemies,(self:getEvaluationCard("fire_slash"))) then
			if (player:isChained()) then return (self:isGoodChainTarget(player,"F")) or false end
			if (player:hasArmorEffect("Vine")) then return (true) or false end
		end
	end
	return (false) or false
end

sgs.ai_view_as.lihuo = function(card,player,card_place)
	local suit = (card:getSuitString())
	local number = (card:getNumberString())
	local card_id = (card:getKnownEffectiveId())
    known(card_place,"Lihuo card place")
	if card_place~=sgs.Player_PlaceSpecial and card:objectName()=="slash" then
		return lihuo_spec(card)
	end
end

ai_fill_skill.lihuo = function(self, options, request)
    local inclusive = options and options.inclusive

	local slash_card

	for _,card in ipairs(self:addHandPile())do
		if (card:isKindOf("Slash")) and not (card:isKindOf("NatureSlash")) then
			slash_card = card
			break
		end
	end

	if not slash_card then return nil end
	local dummy_use = dummy()
	self:useCardFireSlash(slash_card,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		local use = {from=self.player,to=dummy_use.to,card=slash_card}
		if not ai_skill_invoke.lihuo(self,self:inquiryInput("skill_invoke","lihuo",{use=use})) then return nil end
	else return nil end
	-- ListS2I drops the literal "%d<id>" token in the donor string.
    -- Keep that zero-cost policy object for subsequent source valuation. It is
    -- read-only: selecting it cannot mint or submit a paid Lihuo action.
    return (self:evaluateSkillCard("lihuo","fire_slash",{}))

end


ai_skill_use["@@chunlao"] = function(self,prompt,request)
	if prompt~="@chunlao" and prompt~="@tenyearchunlao" and prompt~="@secondtenyearchunlao" then return "." end
	local slashcards={}
	local chunlao = (self.player:getPile("wine"))
	local cards = (self.player:getCards("h"))
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards)  do
		if (card:isKindOf("Slash")) then
			table.insert(slashcards,(card:getKnownId()))
		end
	end
	if #slashcards>0 and chunlao:isEmpty() then
		if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
        local card=legacy(self,"chunlao","ChunlaoCard",slashcards,request)
        local use=AIUsePlan.new();use.card=card
        return known(use:toAnswer(),"Chunlao store authority answer")
	end
	return "."
end

function sgs.ai_cardsview_valuable.chunlao(self,class_name,player)
	local dying = player:getRoom():getCurrentDyingPlayer()
	if dying then
		-- Player::isLocked on a fresh Analeptic for the dying player is not projected.
		ai_unsupported("dying player's analeptic lock is not projected","chunlao")
	end
end

sgs.ai_card_intention.ChunlaoWineCard = sgs.ai_card_intention.Peach

function sgs.ai_cardneed.chunlao(to,card)
	return (to:getPile("wine")):isEmpty() and (card:isKindOf("Slash"))
end

sgs.chunlao_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Slash = 5.5,
}

ai_skill_invoke.zhiyu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local first
	local color = 1
	for _,card in sgs.qlist((self.player:getCards("h")))do
		if not first then first = card end
		if (first:getColorString())~=(card:getColorString()) then
			color = 2
			break
		end
	end
	local damage = data:toDamage()
	if color==1 and damage.from then
		if self:isFriend(damage.from) then
			return ((damage.from:isKongcheng())) or false
		end
	end
	if hasManjuanEffect(self.player)
	then return (false) or false end
	return (true) or false
end

ai_fill_skill.qice = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.toUse>2 then return end
	local ids = (self.player:handCards())
	local canCs = {}
	for _,pn in ipairs(known(AICardCatalog.patternNames(),"patterns() order"))do
		local metadata=known(AICardCatalog.get(pn),"Qice pattern "..pn)
        if known(metadata.nd_trick,"Qice clone class") then
            local dc=(self:evaluateSkillCard("qice",pn,ids))
			if (dc:isAvailable(self.player))
			then table.insert(canCs,dc) end
		end
	end
	ids = sgs.QList2Table(ids)
	self:sortByUseValueInPlace(canCs)
	self:setPriorityValue("QiceCard",4-#ids,"qice")
	if #ids<3 then
		for _,c in ipairs(canCs)do
			if (c:isKindOf("AOE")) then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if (c:targetFixed()) and not (c:isDamageCard())
			and self:getCardsNum("Jink,Peach")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
	end
	if #ids==3 then
		for _,c in ipairs(canCs)do
			if (c:isKindOf("AOE")) then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if (c:isKindOf("GlobalEffect"))
			and (self.player:isWounded()) then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if (c:targetFixed()) and not (c:isDamageCard())
			and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
	end
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	for _,c in ipairs(canCs)do
		if (c:isKindOf("AOE"))
		and caocao and (caocao:getHp())>1
		and self:getAoeValue(c)>-5 and self:isFriend(caocao) and not self:willSkipPlayPhase(caocao)
		and not has_skill(self,self.player,"jueqing") and self:aoeIsEffective(c,caocao,self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				self.qice_to = d.to
				return legacy(self,"qice","QiceCard",ids,request,c:objectName())
			end
		end
	end
	if #ids<=3
	and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
		for _,c in ipairs(canCs)do
			if (c:isKindOf("GlobalEffect"))
			and (self.player:isWounded()) then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if (c:targetFixed()) and not (c:isDamageCard()) then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return legacy(self,"qice","QiceCard",ids,request,c:objectName())
				end
			end
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and (c:isDamageCard())
		and self:getUseValue(c)>#ids*2.1 then
			self.qice_to = d.to
			return legacy(self,"qice","QiceCard",ids,request,c:objectName())
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and self:getUseValue(c)>#ids*2.6 then
			self.qice_to = d.to
			return legacy(self,"qice","QiceCard",ids,request,c:objectName())
		end
	end
end

ai_card_use.QiceCard = function(self, card, use, request)
	for _,c in sgs.qlist((self.player:getHandcards()))do
		if (self.player:getHandcardNum())>1
		and (self.player:isWounded())
		and isCard("Peach",c,self.player)
		and not self:needToLoseHp(self.player)
		and (c:isAvailable(self.player))
		then return end
		end
	use.card = card
	use.to = self.qice_to
end

sgs.ai_use_priority.QiceCard = 3.5

ai_skill_invoke["zishou"] = ai_skill_invoke["noszishou"]
ai_skill_invoke["olzishou"] = ai_skill_invoke["noszishou"]

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["need_hp_active_best.draw_or_awaken"]
    local policy = function(self, from, to, card, context)
        local bh, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to,"hasSkills","longluo|miji|yinghun") and damage_call(self,"findFriendsByType",sgs.Friend_Draw,to)
        		or damage_call(to,"hasSkills","nosrende|rende") and not damage_call(self,"willSkipPlayPhase",to) and damage_call(self,"findFriendsByType",sgs.Friend_Draw,to)
        		or damage_call(to,"hasSkill","jspdanqi") and damage_call(self,"getOverflow")==0
        		then bh = math.min(bh,damage_call(to,"getMaxHp")-1) end
        return bh
    end
    sgs.ai_need_damaged["need_hp_active_best.draw_or_awaken"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_active_best" and context.rule == "draw_or_awaken" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "need_hp_active_best.draw_or_awaken", {
        {phase="need_hp_active_best", order=1, rule="draw_or_awaken"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["good_survival.miji"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "hasSkills", "nosmiji|miji") then return nil, true end
        return value
    end
    sgs.ai_target_damage["good_survival.miji"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_survival" and context.rule == "miji" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "good_survival.miji", {
        {phase="good_survival", order=3, rule="miji"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["qianxi"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local strategy_mark = state.strategy_mark
        if call(to, "hasFlag", "QianxiTarget") then
            if strategy_mark(self, to, "@qianxi_red") > 0 then
                if call(to, "hasSkill", "qingguo") or call(to, "hasSkill", "longhun") and call(to, "isWounded") then defense = defense - 1 else defense = 0 end
            elseif strategy_mark(self, to, "@qianxi_black") > 0 and call(to, "hasSkill", "qingguo") then defense = defense - 1 end
        end
        return defense
    end
    sgs.ai_defense_slash["qianxi"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_4" and context.rule == "slash_defense.qianxi" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "qianxi", {
        {phase="special_4", order=10, rule="slash_defense.qianxi"},
    })
end)()
end
