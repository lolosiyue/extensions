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
 local use=AIUsePlan.new();use.isDummy=is_dummy~=false;use.extra_target=extra or 0;use.current_targets=current or {};return use
end
-- The viewer's own tags; nil is an absent tag (toBool false).
local function owner_fact(self,key)
 return self.player:getTag(key)
end
local function owner_damage(self)
 local row=owner_fact(self,"kenewgirlshibingDamage")
 -- An absent tag converts to the default DamageStruct.
 if row==nil then return{damage=1,nature=sgs.DamageStruct_Normal}end
 if type(row)~="table"or type(row.amount)~="number"then ai_unsupported("owner damage tag malformed","kenewgirlshibingDamage")end
 local d={damage=row.amount,nature=row.nature}
 for _,key in ipairs({"from","to"})do if type(row[key])=="string"and row[key]~=""then d[key]=q(self.room,"findPlayerByObjectName",row[key])end end
 if type(row.card)=="table"and next(row.card)~=nil then d.card=CardView.new(row.card)end;return d
end
local function role(self,p)
 local value=call(p,"getRole");if value~=nil then return value end
 return q(self,"useKnowledgeEstimate",{value=q(self,"getRoleEstimate",p),status="estimate",basis="kearwangushengxiang.unrevealed_role_viewer_estimate",target=q(p,"objectName")},"kearwangushengxiang.role")
end
--花木兰

sgs.ai_fill_skill.kenewgirlshixie = function(self,inclusive,request)
	local alls = q(self.room,"getAllPlayers")
	local needrec = 0
	local needhelp = 0
	local needda = 0
	local needchai = 0
	for _,p in sgs.qlist(alls) do
		if q(self,"isFriend",p) and (q(p,"getStrategyMark","banshixie-Clear") == 0) then
			needhelp = 1
			if q(p,"isWounded") then
			    needrec = 1
			end
		end
		if q(self,"isEnemy",p) and (q(p,"getStrategyMark","banshixie-Clear") == 0) then
			needda = 1
			needchai = 1
		end
	end
	--打伤害
	if (needda == 1) and (q(self.player,"getStrategyMark","useshixiespade-Clear") == 0) then
		local card_id
		local cards = q(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (q(acard,"getSuit") == sgs.Card_Spade) then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0)
		if (card_id > 0) then
			return q(self,"evaluateTurnSkillCard","kenewgirlshixie","#kenewgirlshixieCard",{card_id},request)
		end
	end
	--加血
	if (needrec == 1) and (q(self.player,"getStrategyMark","useshixieheart-Clear") == 0) then
		local card_id
		local cards = q(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (q(acard,"getSuit") == sgs.Card_Heart) then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0)
		if (card_id > 0) then
			return q(self,"evaluateTurnSkillCard","kenewgirlshixie","#kenewgirlshixieCard",{card_id},request)
		end
	end
	--摸牌
	if (needhelp == 1) and (q(self.player,"getStrategyMark","useshixiediamond-Clear") == 0) then
		local card_id
		local cards = q(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (q(acard,"getSuit") == sgs.Card_Diamond) then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0)
		if (card_id > 0) then
			return q(self,"evaluateTurnSkillCard","kenewgirlshixie","#kenewgirlshixieCard",{card_id},request)
		end
	end
	--拆牌
	if (needchai == 1) and (q(self.player,"getStrategyMark","useshixieclub-Clear") == 0) then
		local card_id
		local cards = q(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (q(acard,"getSuit") == sgs.Card_Club) then
				call(to_throw,"append",q(acard,"getEffectiveId"))
			end
		end
		card_id = q(to_throw,"at",0)
		if (card_id > 0) then
			return q(self,"evaluateTurnSkillCard","kenewgirlshixie","#kenewgirlshixieCard",{card_id},request)
		end
	end
	return nil
end


sgs.ai_skill_use_func["#kenewgirlshixieCard"] = function(card,use,self,request)
	local idd =  q(card,"getEffectiveId")
	if q(self,"getKnownCardById",idd):isRed() then
		call(self,"sort",self.friends,"hp")
		for _,ep in sgs.list(self.friends)do
			if (q(ep,"getStrategyMark","banshixie-Clear") == 0) then
				use.card = card
				call(use.to,"append",ep)
				return
			end
		end
	else
		call(self,"sort",self.enemies,"hp")
		for _,ep in sgs.list(self.enemies)do
			if (q(ep,"getStrategyMark","banshixie-Clear") == 0) then
				use.card = card
				call(use.to,"append",ep)
				return
			end
		end
	end
end

sgs.ai_use_value.kenewgirlshixieCard = 8.5
sgs.ai_use_priority.kenewgirlshixieCard = 9.5
sgs.ai_card_intention.kenewgirlshixieCard = 80

--[[function sgs.ai_cardneed.kenewgirlshixieCard(to, card)
	return q(card,"isRed")
end]]

sgs.ai_skill_invoke.kenewgirlcongrong = function(self, data)
	local room = q(self.player,"getRoom")
	for _,p in sgs.qlist(q(room,"getAllPlayers")) do
		if q(p,"getStrategyFlag","ifwantkenewgirlcongrong") and q(self,"isFriend",p) then
	        return true
		end
	end
end

--娘张飞
sgs.ai_skill_choice.kenewgirlfuyi = function(self,choices, data)
	local use = q(data,"toCardUse")
	local items = q(choices,"split","+")
	if q(use.from,"objectName") == q(self.player,"objectName") then
		local dummy_use = q(self,"aiUseCard",use.card, dummy(true,2,use.to))
		if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"length") > q(use.to,"length") and table.contains(items, "add") then
			return "add"
		end
		call(self,"sort",self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"isWeak",friend) and q(self,"isWeak") then
				return "beishui"
			end
		end
		if q(use.card,"isDamageCard") then
			return "eff"
		end
		if q(use.card,"isKindOf","Peach") then 
			if q(self.player,"getLostHp") > 1 then
				return "eff"
			elseif table.contains(items, "add")  then
				for _, friend in ipairs(self.friends_noself) do
					if q(friend,"getHp")<getBestHp(friend) then
						return "add"
					end
				end
			end
		end
	else
		if q(self,"isFriend",use.from) then
			if q(use.card,"isKindOf","Peach") then 
				if q(self.player,"getLostHp") > 1 then
					return "eff"
				elseif table.contains(items, "add")  then
					for _, friend in ipairs(self.friends_noself) do
						if q(friend,"getHp")<getBestHp(friend) then
							return "add"
						end
					end
				end
			end
		end
		if q(self,"isFriend",use.from) and q(self,"isWeak",use.from) and q(self,"isWeak") then
			for _, friend in ipairs(self.friends_noself) do
				if q(self,"isWeak",friend) then
					return "beishui"
				end
			end
		end
	end
	return "cancel"
end

sgs.ai_skill_playerschosen.kenewgirlfuyi = function(self, targets, max, min)
	local use = q(self,"getDecisionData"):toCardUse()
    local selected = AIList.new({})
    local can_choose = sgs.QList2Table(targets)
    call(self,"sort",can_choose, "defense")
	if q(self.player,"getStrategyFlag","beishuifuyi") then
		for _,target in ipairs(can_choose) do
			if q(self,"isFriend",target) and q(target,"getHp") < getBestHp(target) and not q(use.to,"contains",target) then
				call(selected,"append",target)
			end
			if q(selected,"length") >= max then break end
		end
	else
		local dummy_use = q(self,"aiUseCard",use.card, dummy(true,2,use.to))
		if dummy_use.card and dummy_use and dummy_use.to then
			for _, p in sgs.qlist(dummy_use.to) do
				if not q(use.to,"contains",p) then
					call(selected,"append",p)
					if q(selected,"length") >= max then break end
				end
			end
		end
	end
    return selected
end

sgs.ai_skill_invoke.kenewgirlzhenyi = function(self, data)
	local target = call(self.room,"findPlayerByObjectName",q(data,"toString"):split(":")[2])
	if target and q(self,"isFriend",target) then
		return true
	end
end
sgs.ai_choicemade_filter.skillInvoke["kenewgirlzhenyi"] = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target
		for _,p in sgs.qlist(q(self.room,"getOtherPlayers",player))do
			if q(p,"getStrategyFlag","kenewgirlzhenyiTarget") then target = p break end
		end
		if target then
		 	call(self,"updateIntention",player, target, -80)
		end
	end
end


--娘姜维

sgs.ai_skill_playerschosen.kenewgirljizhi = function(self, targets, max, min)
    local selected = AIList.new({})
    local n = max
    local can_choose = sgs.QList2Table(targets)
    call(self,"sort",can_choose, "defense")
	if (n > 0) then
		for _,target in ipairs(can_choose) do
			if q(self,"isFriend",target) then
				call(selected,"append",target)
				n = n - 1
			end
			if n <= 0 then break end
		end
	end
    return selected
end
sgs.ai_skill_invoke["kenewgirljizhi"] = true

sgs.ai_canNiepan_skill.kenewgirljizhi = function(player)
	return q(player,"getStrategyMark","@kenewgirljizhi") > 0
end

sgs.ai_fill_skill.kenewgirljingmu = function(self,inclusive,request)
	
	return q(self,"legacySkillSeed","kenewgirljingmu","#kenewgirljingmuCard",request)
end


sgs.ai_skill_use_func["#kenewgirljingmuCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies,"hp")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))

	if q(self.player,"getHp")<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = owner_fact(self,"JilveWansha")
		for _,zcard in sgs.list(q(self.player,"getCards","he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = q(self,"aiUseCard",zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if q(p,"getHp")<=1 then
									shouldUse = false
									if q(self.player,"distanceTo",p)>1 then keep_weapon = call(self.player,"getWeapon") end
									break
								end
							end
							if q(dummy_use.to,"length")>1 then shouldUse = false end
						end
						if not q(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if q(zcard,"getTypeId")==sgs.Card_TypeTrick then
					if q(self,"aiUseCard",zcard).card then shouldUse = false end
				end
				if q(zcard,"getTypeId")==sgs.Card_TypeEquip and not q(self.player,"hasEquip",zcard) then
					if q(self,"aiUseCard",zcard).card then shouldUse = false end
					if keep_weapon and q(zcard,"getEffectiveId")==q(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","Armor") and not q(self,"needToThrowArmor") then shouldUse = false end
				if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","DefensiveHorse") and not q(self,"needToThrowArmor") then shouldUse = false end
				if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if q(self.player,"getHp")<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,q(zcard,"getId")) end
			end
		end
	end

	if #unpreferedCards<1 then
		local use_slash_num = 0
		call(self,"sortByKeepValue",cards)
		for _,card in ipairs(cards)do
			if q(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num<=q(card,"getTargetModResidue",self.player)
				then
					if q(self,"aiUseCard",card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,q(card,"getId")) end
			end
		end

		local num = q(self,"getCardsNum","Jink")-1
		if call(self.player,"getArmor") then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if q(card,"isKindOf","Jink") and num>0 then
					table.insert(unpreferedCards,q(card,"getId"))
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if q(card,"isKindOf","Weapon") and q(self.player,"getHandcardNum")<3
			or call(self,"getSameEquip",card,self.player)
			or q(card,"isKindOf","OffensiveHorse")
			or q(card,"isKindOf","AmazingGrace")
			then table.insert(unpreferedCards,q(card,"getId"))
			elseif q(card,"getTypeId")==sgs.Card_TypeTrick then
				if not q(self,"aiUseCard",card).card then table.insert(unpreferedCards,q(card,"getId")) end
			end
		end
	end


	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not q(self.player,"isJilei",q(self,"getKnownCardById",unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		local slash = q(self,"evaluateSkillCard","kenewgirljingmu","slash",{})
		local dummy_use = q(self,"aiUseCard",slash, dummy())
		if dummy_use.card then
			for _, p in sgs.qlist(dummy_use.to) do
				if q(self,"doDisCard",p, "he") then
					use.card=q(self,"bindSkillCard","kenewgirljingmu",use_cards,request,nil,"#kenewgirljingmuCard")
					call(use.to,"append",p)
					return
				end
			end
		end
	end
	
end

sgs.ai_use_value.kenewgirljingmuCard = 8.5
sgs.ai_use_priority.kenewgirljingmuCard = 9.5
sgs.ai_card_intention.kenewgirljingmuCard = 80

sgs.ai_skill_playerchosen.kenewgirlduoshuai = function(self, targets)
	local target = q(self,"findPlayerToDamage",2, self.player, "N", targets, 0)[1]
	return target
end

sgs.ai_skill_choice.kenewgirlduoshuai = function(self,choices, data)
	return "two"
end

sgs.ai_skill_invoke["kenewgirlshibing"] = true

sgs.ai_skill_invoke.kenewgirlshibingdiscardask      = function(self, data)
	local target = call(data,"toPlayer")
	if target and q(self,"doDisCard",target, "he") then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.cardChosen.kenewgirlshibing = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_playerchosen.kenewgirlshibing = function(self, targets)
	local dmg = owner_damage(self)
	for _,enemy in ipairs(self.enemies)do
		if (q(enemy,"getHp")<=dmg.damage and q(enemy,"isAlive")) then
			if q(self,"canAttack",enemy,dmg.from or q(self.room,"getCurrent"),dmg.nature)
				and not (dmg.card and q(dmg.card,"getTypeId")==sgs.Card_TypeTrick and q(enemy,"hasSkill","wuyan")) then
				return enemy
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if q(friend,"isChained") and dmg.nature~=sgs.DamageStruct_Normal
		and not q(self,"isGoodChainTarget",friend,dmg.card or dmg.nature,dmg.from,dmg.damage)
		then
		elseif q(friend,"getHp")>=2 and dmg.damage<2
		and q(self,"needToLoseHp",friend)
		then return friend
		elseif dmg.card and q(dmg.card,"getTypeId")==sgs.Card_TypeTrick
		and q(friend,"hasSkill","wuyan") and q(friend,"getLostHp")>1
		then return friend
	end

	for _,enemy in ipairs(self.enemies)do
		if (q(enemy,"getHandcardNum")<=2)
			and q(self,"canAttack",enemy,(dmg.from or q(self.room,"getCurrent")),dmg.nature)
			and not (dmg.card and q(dmg.card,"getTypeId")==sgs.Card_TypeTrick and q(enemy,"hasSkill","wuyan")) then
			return enemy end
		end
	end

	for i = #self.enemies,1,-1 do
		local enemy = self.enemies[i]
		if not q(enemy,"isWounded") and not q(self,"hasSkills",sgs.masochism_skill,enemy) and q(enemy,"isAlive")
			and q(self,"canAttack",enemy,dmg.from or q(self.room,"getCurrent"),dmg.nature)
			and (not (dmg.card and q(dmg.card,"getTypeId")==sgs.Card_TypeTrick and q(enemy,"hasSkill","wuyan") and q(enemy,"getLostHp")>0) or q(self,"isWeak")) then
			return enemy
		end
	end
end

sgs.ai_playerchosen_intention.kenewgirlshibing = function(self, from, to)
	if q(self,"needToLoseHp",to) then return end
	local intention = 10
	call(self,"updateIntention",from, to, intention)
end


sgs.ai_skill_choice["kenewgirlshibing"] = function(self, choices, data)
	local damage = q(data,"toDamage")
	if q(self,"isFriend",damage.to) then
		if not q(self,"needToLoseHp",damage.to, damage.from, damage.card) then return "dis" end
	end
	if q(self,"isFriend",damage.from) then
		if not q(self,"cantDamageMore",damage.to, damage.from) then
			return "add"
		end
	end
	return "cancel"
end

sgs.ai_skill_playerschosen.kenewgirltanyan = function(self, targets, max, min)
    local selected = AIList.new({})
    local can_choose = sgs.QList2Table(targets)
    call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if q(self,"isEnemy",target) then
			call(selected,"append",target)
		end
		if q(selected,"length") >= max then break end
	end
    return selected
end

sgs.ai_skill_invoke.kenewgirlganglv = true

ai_skill_use["@@kenewgirlganglv"]=function(self,prompt,request)
 for _,original in ipairs(q(self.player,"getNotifiedPileCards","kenewgirlganglv"))do
  local card,candidate=q(self,"getAcquiredCardEvaluation",original)
  if not card or not candidate then ai_unsupported("ganglv disclosed current-card evaluation unavailable","kenewgirlganglv")end
  local old=self._evaluation_scope;self._evaluation_scope={card=card,candidate=candidate}
  local ok,plan=pcall(self.aiUseCard,self,card);self._evaluation_scope=old
  if not ok then error(plan,0)end
  if AIUnsupported.is(plan)then error(plan,0)end
  if plan.card and plan.to then
   if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
   plan.card=q(self,"bindSkillCard","kenewgirlganglv",{q(original,"getEffectiveId")},request)
   return q(plan,"toAnswer")
  end
 end
 return "."
end

sgs.ai_fill_skill.kenewgirlbuguan = function(self,inclusive,request)
	if q(self.player,"hasUsed","#kenewgirlbuguanCard") then return end
	return q(self,"legacySkillSeed","kenewgirlbuguan","#kenewgirlbuguanCard",request)
end

sgs.ai_skill_use_func["#kenewgirlbuguanCard"] = function(card,use,self,request)
	local buguanslash = q(self,"evaluateSkillCard","kenewgirlbuguan","slash",{})
	local ppp = AIList.new({})
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self.player,"canSlash",p, buguanslash, false) then	
			call(ppp,"append",p)
		end
	end
	local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, ppp)
	if target then
		use.card = q(self,"bindSkillCard","kenewgirlbuguan",{},request,nil,"#kenewgirlbuguanCard")
		return
	end
end
sgs.ai_use_value["kenewgirlbuguanCard"] = 5
sgs.ai_use_priority["kenewgirlbuguanCard"]  = sgs.ai_use_priority.Slash - 0.1

sgs.ai_skill_playerchosen.kenewgirlbuguan = function(self, targets)
	targets = sgs.QList2Table(targets)
	if q(self.player,"getStrategyFlag","kenewgirlbuguan_draw") then
		return self.player
	end
	if q(self.player,"getStrategyFlag","kenewgirlbuguan_recover") then
		for _, p in ipairs(targets) do
			if q(self,"isFriend",p) and q(p,"getHp") < getBestHp(p) then
				return p
			end
		end
	end
	if q(self.player,"getStrategyFlag","kenewgirlbuguan_judge") then
		for _, p in ipairs(targets) do
			if q(self,"isFriend",p) and q(p,"getJudgingArea"):length() > 0 then
				return p
			end
		end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_skill_choice["kenewgirlbuguan"] = function(self, choices, data)
	local items = q(choices,"split","+")
	local buguanslash = q(self,"evaluateSkillCard","kenewgirlbuguan","slash",{})
	if q(self,"getOverflow") > 0 and table.contains(items, "discard") then
		return "discard"
	end
	if table.contains(items, "throw") then
		local ppp = AIList.new({})
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
				if q(self.player,"canSlash",p, buguanslash, false) then	
					call(ppp,"append",p)
				end
			end
		local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, ppp)
		if target and q(self,"isEnemy",target) and q(target,"hasEquipArea") then
			if  getCardsNum("Jink", target, self.player) < 1 or q(self,"canLiegong",target, self.player) then
				return "throw"
			end
		end
	end
	if q(self.player,"getHp") + q(self,"getAllPeachNum") > 0  and table.contains(items, "losehp") then
		return "losehp"
	end
	if table.contains(items, "hlose") then
		local damage = q(data,"toDamage")
		if damage.to then
			if q(self,"isFriend",damage.to) and q(self,"hasZhaxiangEffect",damage.to) or (q(self,"isEnemy",damage.to) and not q(self,"hasZhaxiangEffect",damage.to)) then
				return "hlose"
			end
		end
	end
	if table.contains(items, "hdraw") then
		return "hdraw"
	end
	if table.contains(items, "hdis") then
		local damage = q(data,"toDamage")
		if damage.to then
			if q(self,"doDisCard",damage.to, "he", false, 2) then
				return "hdis"
			end
		end
	end
	if table.contains(items, "hrec") then
		for _, p in ipairs(sgs.QList2Table(q(self.room,"getAlivePlayers"))) do
			if q(self,"isFriend",p) and q(p,"getHp") < getBestHp(p) then
				return "hrec"
			end
		end
	end
	if table.contains(items, "hpanding") then
		for _, p in ipairs(sgs.QList2Table(q(self.room,"getAlivePlayers"))) do
			if q(self,"isFriend",p) and q(p,"getJudgingArea"):length() > 0 then
				return "hpanding"
			end
		end
	end
	if table.contains(items, "hthrow") then
		return "hthrow"
	end

	return "cancel"
end



sgs.ai_fill_skill.kenewgirljuzhong = function(self,inclusive,request)
	if q(self.player,"hasUsed","#kenewgirljuzhongCard") then return end
	return q(self,"legacySkillSeed","kenewgirljuzhong","#kenewgirljuzhongCard",request)
end

sgs.ai_skill_use_func["#kenewgirljuzhongCard"] = function(card,use,self,request)
	local target = nil
	local max = 0
	local min = 999
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHandcardNum") > max then
			max = q(p,"getHandcardNum")
        end
		if q(p,"getHandcardNum") < min then
			min = q(p,"getHandcardNum")
        end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getHandcardNum") == max and q(self,"doDisCard",enemy, "he") and q(self.player,"getStrategyMark","usejuzhongqi-PlayClear") < 2 then
			target = enemy
		end
	end
	for _, friend in ipairs(self.friends) do
		if q(friend,"getHandcardNum") == min and q(self,"canDraw",friend, self.player) and q(self.player,"getStrategyMark","usejuzhongmo-PlayClear") < 2 then
			target = friend
		end
	end
	if target then
		use.card = q(self,"bindSkillCard","kenewgirljuzhong",{},request,nil,"#kenewgirljuzhongCard")
		if use.to then call(use.to,"append",target) end
		return
	end
end
sgs.ai_use_value["kenewgirljuzhongCard"] = 5
sgs.ai_use_priority["kenewgirljuzhongCard"]  = 5

sgs.ai_skill_choice["kenewgirljuzhong"] = function(self, choices, data)
	local target = call(data,"toPlayer")
	local items = q(choices,"split","+")
	if table.contains(items, "maxqi") and target and q(self,"doDisCard",target, "he") then
		return "maxqi"
	end
	return "minmo"
end

sgs.ai_skill_choice["kenewgirlshiqian"] = function(self, choices, data)
	local player = call(data,"toPlayer")
	local skills = q(choices,"split","+")
	
	for _,sk in sgs.list(skills)do
		if q(self,"isValueSkill",sk,player,true) then
			return sk
		end
	end
	
	for _,sk in sgs.list(skills)do
		if q(self,"isValueSkill",sk,player) then
			return sk
		end
	end
	
	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if not string.find(sgs.bad_skills,sk) then table.insert(not_bad_skills,sk) end
	end
	if #not_bad_skills>0 then
		return not_bad_skills[math.random(1,#not_bad_skills)]
	end
	
	return skills[math.random(1,#skills)]
	
end
sgs.ai_skill_invoke.kenewgirlshiqian = true

sgs.ai_can_damagehp.kenewgirlshiqian = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_fill_skill.kenewgirlchenji = function(self,inclusive,request)
	if q(self.player,"hasUsed","#kenewgirlchenjiCard") then return end
	return q(self,"legacySkillSeed","kenewgirlchenji","#kenewgirlchenjiCard",request)
end

sgs.ai_skill_use_func["#kenewgirlchenjiCard"] = function(card,use,self,request)
	local target = nil
	for _, friend in ipairs(self.friends) do
		if q(self,"canDraw",friend, self.player) and q(self,"needToLoseHp",friend, self.player) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if q(self,"canDraw",friend, self.player) then
				target = friend
				break
			end
		end
	end
	if target then
		use.card = q(self,"bindSkillCard","kenewgirlchenji",{},request,nil,"#kenewgirlchenjiCard")
		if use.to then call(use.to,"append",target) end
		return
	end
end
sgs.ai_use_value["kenewgirlchenjiCard"] = 5
sgs.ai_use_priority["kenewgirlchenjiCard"]  = 5


sgs.ai_cardneed.kenewgirlchandou = sgs.ai_cardneed.slash

sgs.ai_skill_choice["kenewgirlchandou"] = function(self, choices, data)
	local effect = q(data,"toCardEffect")
	local juedou = q(self,"evaluateSkillCard","kenewgirlchandou","duel",{})
	if q(self.player,"objectName") ==  q(effect.to,"objectName") then
		if effect.from and q(self,"isEnemy",effect.from) and q(self,"isWeak",effect.from) then
			local dummy_use = q(self,"aiUseCard",juedou, dummy(true, 0, q(self.room,"getOtherPlayers",effect.from)))
			if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",effect.from) then
				return "juedou"
			end
		end
		return "dis"
	elseif q(self.player,"objectName") ==  q(effect.from,"objectName") then
		if q(self,"getOverflow") > 0 or q(self,"hasHeavyDamage",self.player, effect.card, effect.to) then
			return "beishui"
		end
		local dummy_use = q(self,"aiUseCard",juedou, dummy(true, 0, q(self.room,"getOtherPlayers",effect.to)))
		if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",effect.to) then
			return "juedou"
		end
	end
	return "dis"
end

sgs.ai_cardneed.kenewgirljiang = sgs.ai_cardneed.jiang
sgs.ai_card_priority.kenewgirljiang = sgs.ai_card_priority.jiang

sgs.ai_fill_skill.kenewgirlscshixie = function(self,inclusive,request)
	if #self.enemies < 1 or q(self.player,"getStrategyMark","@kenewgirlscshixie") < 1 then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if q(player,"getHp") >= 2 then
			too_weak = false
		end
	end
	if too_weak then return end
	local lord = call(self.room,"getLord")
	if q(self.player,"getRole") == "lord" or q(self.player,"getRole") == "loyalist" or q(self.player,"getRole") == "rebel" then
		return q(self,"legacySkillSeed","kenewgirlscshixie","#kenewgirlscshixieCard",request)
	end
	if q(self.player,"getRole") == "renegade" then
		if #self.friends + 1 >= #self.enemies and (q(self.player,"getHp") >= 3 or q(lord,"getHp") >= 3) then return end
		if #self.friends >= #self.enemies and (q(self.player,"getHp") >= 2 or q(lord,"getHp") >= 2) then return end
		return q(self,"legacySkillSeed","kenewgirlscshixie","#kenewgirlscshixieCard",request)
	end
end


sgs.ai_skill_use_func["#kenewgirlscshixieCard"] = function(card,use,self,request)
	local target
	call(self,"sort",self.enemies, "defense")
	local lord = call(self.room,"getLord")
	if q(self.player,"getRole") == "rebel" then
		target = lord
	end
	if q(self.player,"getRole") == "loyalist" or q(self.player,"getRole") == "lord" then
		for _, enemy in ipairs(self.enemies) do
			if enemy then
				target = enemy
			end
		end
	end
	if q(self.player,"getRole") == "renegade" then
		if #self.friends == #self.enemies then
			for _, enemy in ipairs(self.enemies) do
				if role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
		if #self.friends + 1 == #self.enemies then
			for _, enemy in ipairs(self.enemies) do
				if enemy then
					target = enemy
				end
			end
		end
		if q(lord,"getHp") <= 2 then
			for _, enemy in ipairs(self.enemies) do
				if role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
	end
	if target then
		use.card = q(self,"bindSkillCard","kenewgirlscshixie",{},request,nil,"#kenewgirlscshixieCard")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["kenewgirlscshixieCard"]       = 8
sgs.ai_use_priority["kenewgirlscshixieCard"]    = 8
sgs.ai_card_intention["kenewgirlscshixieCard"]  = 108