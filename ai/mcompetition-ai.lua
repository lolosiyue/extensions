
sgs.ai_skill_choice["shenyi"] = function(self,choices,data)
	local items = choices:split("+")
	local Phases = data:toString()
	local num = 0
	if Phases == "" then
		num = 1
	else
		Phases = data:toString():split("+")
		num = #Phases + 2
	end
	local current = self.room:getCurrent()
	if num == 1 then
		if self:isFriend(current)then
			if self:getOverflow(current) <= 0 and table.contains(items, "discard") then
				return "discard"
			end
			if table.contains(items, "draw") then
				return "draw"
			end
		elseif self:isEnemy(current)then
			if current:isKongcheng() and table.contains(items, "play") then
				return "play"
			end
			if self:getOverflow(current) > 0 and table.contains(items, "draw") then
				return "draw"
			end
		end
	elseif num == 2 then
		if self:isFriend(current)then
			if table.contains(items, "draw") then
				return "draw"
			end
			if table.contains(items, "play") then
				return "play"
			end
		elseif self:isEnemy(current)then
			if self:getOverflow(current) > 0 and table.contains(items, "discard") then
				return "discard"
			end
		end
	end
	return items[1]
end
sgs.ai_skill_invoke.shenyi = true
sgs.ai_cardneed.zhuanshan = sgs.ai_cardneed.bignumber
sgs.ai_skill_invoke.zhuanshan = function(self,data)
	if self.player:getHandcardNum()<=(self:isWeak() and 2 or 1) then return false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point+3,13) end
	if not (current:hasSkill("zhiji") and current:getMark("zhiji")==0 and current:getHandcardNum()==1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if enemy_max_card and current:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
		if max_point>enemy_max_point or max_point>10 then
			self.zhuanshan_card = max_card:getEffectiveId()
			return true
		end
	end
	if current:distanceTo(self.player)==1 and not self:isValuableCard(max_card) then
		self.zhuanshan_card = max_card:getEffectiveId()
		return true
	end
	return false
end

sgs.ai_use_revises.qishibusiyutushou = function(self,card,use)
	if card:isKindOf("Weapon") and self.player:property("qishibusiyutushouEquips"):toString() ~= ""
	then return false end
end

local wuqiongdewulian_skill = {}
wuqiongdewulian_skill.name = "wuqiongdewulian"
table.insert(sgs.ai_skills,wuqiongdewulian_skill)
wuqiongdewulian_skill.getTurnUseCard = function(self)
	local HandPile = self:addHandPile("he")
	self:sortByUseValue(HandPile,true)
	for _,c in sgs.list(HandPile)do
		if c:isKindOf("Slash") then return end
	end
	local c = sgs.Card_Parse("#wuqiongdewulian:.:slash")
	return c
end

sgs.ai_skill_use_func["#wuqiongdewulian"] = function(card,use,self)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("wuqiongdewulian")
	if slash:isAvailable(self.player) then
		self:aiUseCard(slash,use)
		if use.card and use.to
		then use.card = card end
	end	
end

function sgs.ai_cardsview_valuable.wuqiongdewulian(self,class_name,player)
	if self.player:hasFlag("wuqiongdewulian") then return false end
	local can_invoke = false
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:objectName()~=player:objectName() and not p:isAllNude() then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return false end
	local HandPile = self:addHandPile("he")
	self:sortByKeepValue(HandPile)
	for _,c in sgs.list(HandPile)do
		if c:isKindOf(class_name) then return end
	end
	if class_name=="Slash" then 
		return "#wuqiongdewulian:.:slash"
	end
	if class_name=="Jink" then 
		return "#wuqiongdewulian:.:jink"
	end
end

sgs.ai_skill_playerchosen.wuqiongdewulian = function(self,targets)
	return self:findPlayerToDiscard("hej",true,false,targets)[1]
end


sgs.ai_skill_use["@@Babylon"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")


	for _,enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then return "#Babylon:.:->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies) do
		local def=sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def < 8 then return "#Babylon:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_skill_askforag["Babylon"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(cards, true)
	if #cards > 0 then
		return cards[1]:getEffectiveId()
	end
end



sgs.ai_skill_playerchosen.zhisimoyan = function(self, targets)
	local target
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,enemy in ipairs(targets) do
		if self:isEnemy(enemy) and not enemy:isKongcheng() and self:isGoodTarget(enemy, self.enemies, nil) 
		and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy)  then
			target= enemy
			break
		end
	end
	if target then return target end
	return nil
end


sgs.ai_ajustdamage_from.zhisimoyan = function(self,from,to,card,nature)
	if from and card and from:getMark("zhisimoyan") > 0  then 
		local target = self.room:getTag("zhisimoyan_target"):toPlayer()
        local carda=sgs.Sanguosha:getCard(from:getMark("zhisimoyan"))
        if carda:getTypeId() == card:getTypeId() and target and target:objectName() == to:objectName() then 
		return 1 end
	end
end

sgs.ai_skill_choice["zhisimoyan"] = function(self, choices, data)
	local source = data:toPlayer()
	local items = choices:split("+")
	 if #items == 1 then
        return items[1]
	else
		if table.contains(items, "zhisimoyan_get") then return "zhisimoyan_get" end
		if table.contains(items, "zhisimoyan_damage") then
			if self:objectiveLevel(source) > 3 and not self:cantbeHurt(source)then 
				return "zhisimoyan_damage" 
				end
			end
    end
	return "cancel"
end




local zhiluan_skill = {}
zhiluan_skill.name = "zhiluan"
table.insert(sgs.ai_skills, zhiluan_skill)
zhiluan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#zhiluanCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#zhiluanCard:.:")
end
sgs.ai_skill_use_func["#zhiluanCard"] = function(card,use,self)
	local targets = {}
	local target
	self:sort(self.enemies, "defense") 
	self:sort(self.friends_noself, "defense") 
	for _, friend in ipairs(self.friends_noself) do
		if  not hasManjuanEffect(friend) then
			if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and friend:getPhase() == sgs.Player_NotActive and not friend:isKongcheng() then
				target = friend
				break
			end
			if friend:hasSkill("enyuan") and not friend:isKongcheng() then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			
				if hasManjuanEffect(enemy) and not enemy:isKongcheng() then
					target = enemy
					break
				end
				if not hasTuntianEffect(enemy, true) and not enemy:isKongcheng() then
					target = enemy
					break
				end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and not friend:isKongcheng() then
				target = friend
					break
			end
		end
	end
	if  target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_discard["zhiluan"] = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getId())
	end

	return to_discard
end

sgs.ai_skill_choice["zhiluan"] = function(self, choices, data)
	local source = data:toPlayer()
	local items = choices:split("+")
	if source then
		if self:isFriend(source) then
			return "add"
		end
    end
	return "reset"
end

sgs.ai_skill_invoke.caoduo = function(self,data)
	local decision = data:toString():split(":")
	local target = self.room:findPlayerByObjectName(decision[4])
	if target and self:isEnemy(target) then
		return true
	end
	return false
end

local caoduo_skill = {}
caoduo_skill.name = "caoduo"
table.insert(sgs.ai_skills, caoduo_skill)

caoduo_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Club then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	if not self.player:hasUsed("#caoduoCard") then
		local card_str = "#caoduoCard:" .. table.concat(subcards, "+")..":"
		return sgs.Card_Parse(card_str)
	end
	local card_str = "Collateral:caoduo[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end
sgs.ai_skill_use_func["#caoduoCard"] = function(card, use, self)
	local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local cmp = function(a,b)
		local al = self:objectiveLevel(a)
		local bl = self:objectiveLevel(b)
		if al~=bl then return al>bl end
		al = getCardsNum("Slash",a,self.player)
		bl = getCardsNum("Slash",b,self.player)
		if al~=bl then return al<bl end
		return a:getHandcardNum()<b:getHandcardNum()
	end
	table.sort(fromList,cmp)
	function useToCard(to)
		return not(use.to:contains(to) or isCurrent(use,to)
		or self.player:isProhibited(to,card)) and not to:isKongcheng()
	end
	local toList = self:sort(self.room:getAlivePlayers(),"defense")
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	extraTarget = extraTarget*2
	for _,enemy in ipairs(fromList)do
		if useToCard(enemy) and self:objectiveLevel(enemy)>=0
		and not(self:loseEquipEffect(enemy) or hasTuntianEffect(enemy)) then
			local final_enemy
			for _,enemy2 in ipairs(toList)do
				if final_enemy then break end
				if enemy:canSlash(enemy2)
				and enemy:inMyAttackRange(enemy2)
				and self:objectiveLevel(enemy2)>2
				then final_enemy = enemy2 end
			end
			for _,enemy2 in ipairs(toList)do
				if final_enemy then break end
				local ol = self:objectiveLevel(enemy2)
				if enemy:inMyAttackRange(enemy2)
				and enemy:canSlash(enemy2) and ol<=3 and ol>=0
				then final_enemy = enemy2 end
			end
			for _,friend in ipairs(sgs.reverse(toList))do
				if final_enemy then break end
				if enemy:canSlash(friend)
				and enemy:inMyAttackRange(friend)
				and self:objectiveLevel(friend)<0
				and self:needToLoseHp(friend,enemy,dummyCard(),true)
				then final_enemy = friend end
			end
			for _,friend in ipairs(sgs.reverse(toList))do
				if final_enemy then break end
				if enemy:canSlash(friend)
				and enemy:inMyAttackRange(friend)
				and self:objectiveLevel(friend)<0
				and (getCardsNum("Jink",friend,self.player)>1 or getCardsNum("Slash",enemy,self.player)<1)
				then final_enemy = friend end
			end
			if final_enemy then
				use.card = card
				use.to:append(enemy)
				use.to:append(final_enemy)
				if use.to:length()>extraTarget
				then return end
			end
		end
	end
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and self:objectiveLevel(friend)<0
		and getCardsNum("Slash",friend,self.player)>0 then
			for _,enemy in ipairs(toList)do
				if friend:canSlash(enemy)
				and self:objectiveLevel(enemy)>2
				and friend:inMyAttackRange(enemy)
				and self:isGoodTarget(enemy,self.enemies,card) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
		end
	end
	self:sortEnemies(toList)
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and self:objectiveLevel(friend)<0
		and not(friend:hasWeapon("crossbow") and getCardsNum("Slash",friend,self.player)>1)
		and self:loseEquipEffect(friend) then
			for _,enemy in ipairs(toList)do
				if friend:canSlash(enemy) and self:objectiveLevel(enemy)>=0
				and friend:inMyAttackRange(enemy) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
			for _,enemy in ipairs(sgs.reverse(toList))do
				if friend:canSlash(enemy) and self:objectiveLevel(enemy)<0
				and friend:inMyAttackRange(enemy) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
		end
	end
end

sgs.ai_use_priority["caoduoCard"] = sgs.ai_use_priority.Slash + 1
sgs.ai_card_intention["caoduoCard"] = sgs.ai_card_intention.Collateral


sgs.ai_skill_use["@@caoduo"] = function(self, prompt)
	local ids = self.player:getTag("LuaZongxuan"):toString():split("+")
	for _,id in ipairs(ids)do
		local card = sgs.Sanguosha:getCard(id)
		local use = self:aiUseCard(card)
		if use.card and card:hasFlag("caoduo") then
			if use.to and use.to:length() > 0 then
				local tos = {}
				for _,p in sgs.qlist(use.to) do
					table.insert(tos, p:objectName())
				end
				return card:toString().."->"..table.concat(tos,"+")
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.shengkong = true





local tianlai_skill = {}
tianlai_skill.name = "tianlai"
table.insert(sgs.ai_skills,tianlai_skill)
tianlai_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)

	return sgs.Card_Parse("#tianlaiCard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#tianlaiCard"] = function(card,use,self)
	local arr1,arr2 = self:getWoundedFriend(false,false)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) and not arr1[1]:isKongcheng() and not self.player:hasUsed("#tianlai"..arr1[1]:objectName()) and self:canDraw(arr1[1], self.player) then target = arr1[1] end
	if target then
		use.card = card
		use.to:append(target)
		return
	end
	if self:getOverflow()>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not friend:hasSkills("hunzi|longhun") and not friend:isKongcheng() and not self.player:hasUsed("#tianlai"..friend:objectName()) and self:canDraw(friend, self.player) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority["tianlaiCard"] = 4.2
sgs.ai_card_intention["tianlaiCard"] = -100

sgs.dynamic_value.benefit["tianlaiCard"] = true

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|tianlai"


sgs.ai_choicemade_filter.cardResponded["@shengkong-use"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = self.room:findPlayerByObjectName(promptlist[4])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end
sgs.ai_skill_playerchosen.shengkong = function(self, targets)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) and self:canDraw(p, self.player) and hasTuntianEffect(p) then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	return targets:first()
end

function sgs.ai_cardsview_valuable.shengkong(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Peach" or sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	if player:hasFlag("Global_shengkongFailed") then return end
	if player:isKongcheng() then return end
	local ids = self.player:handCards()	
	ids = sgs.QList2Table(ids)
	return "#shengkongCard:"..table.concat(ids,"+")..":"..name
end

sgs.ai_skill_cardask["@shengkong-use"] = function(self, data, pattern)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,h in sgs.list(cards)do
            if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
            then return h:getEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getEffectiveId() end
        end
        return self:getCardId(pattern)
    end
    return "."
end

addAiSkills("lingbian").getTurnUseCard = function(self)
	local ids = self.player:handCards()
   	self:sort(self.friends_noself,"card",true)
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card	and (card:isKindOf("BasicCard") or card:isNDTrick())
		and self:getCardsNum(card:getClassName())<1 then
            card:addSubcards(ids)
            card:setSkillName("lingbian")
			if card:isAvailable(self.player) then
				local dummy = self:aiUseCard(card)
				if dummy.card then
					self.lingbian_dummy = dummy
					if card:canRecast() and dummy.to:length()<1 then continue end
					ids = sgs.QList2Table(ids)
					return sgs.Card_Parse("#lingbianCard:"..table.concat(ids,"+")..":"..name)
				end
			end
		end
	end
   	self:sort(self.enemies,"hp")
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card and (card:isKindOf("BasicCard") or card:isNDTrick())
		and card:isDamageCard() and #self.enemies>0 and self:isWeak(self.enemies[1])
		and self:getCardsNum(card:getClassName())<1 then
            card:addSubcard(ids)
            card:setSkillName("lingbian")
			if card:isAvailable(self.player) then
				local dummy = self:aiUseCard(card)
				if dummy.card then
					self.lingbian_dummy = dummy
					ids = sgs.QList2Table(ids)
					return sgs.Card_Parse("#lingbianCard:"..table.concat(ids,"+")..":"..name)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#lingbianCard"] = function(card,use,self)
	use.card = card
	use.to = self.lingbian_dummy.to
end

sgs.ai_skill_invoke.xingyou = function(self, data)
	local damage = data:toDamage()
	if damage.to then
		if self:needToLoseHp(damage.to, damage.from, damage.card) then
			return false
		end
		return true
	end
end

sgs.ai_skill_playerchosen.zuiyou = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:doDisCard(p, "he") then return p end
	end
	return nil
end

sgs.ai_skill_playerchosen.duotian = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:doDisCard(p, "ej", true) then return p end
	end
	return nil
end

sgs.ai_cardsview_valuable.pomou = function(self, class_name, player)
	if class_name ~= "Nullification" then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) then return end
    end
    return string.format("#pomou:.:nullification")
end
sgs.ai_skill_playerchosen.pomou = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if p and self:isEnemy(p) then
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
			for _,c in sgs.qlist(p:getCards("h"))do
				if self.player:canSeeHandcard(p) or c:hasFlag("visible") or c:hasFlag(flag) then
					if not c:isKindOf("BasicCard") then
						return p
					end
				end
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:doDisCard(p, "h") then return p end
	end
	return nil
end

sgs.ai_skill_cardchosen.pomou = function(self,who,flags)
	local flag = string.format("%s_%s_%s","visible",self.player:objectName(),who:objectName())
	for _,c in sgs.qlist(who:getCards("h"))do
		if self.player:canSeeHandcard(who) or c:hasFlag("visible") or c:hasFlag(flag) then
			if not c:isKindOf("BasicCard") then
				return c
			end
		end
	end
	return -1
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|jilian"

local dongxi_skill = {}
dongxi_skill.name = "dongxi"
table.insert(sgs.ai_skills,dongxi_skill)
dongxi_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)

	return sgs.Card_Parse("#dongxi:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#dongxi"] = function(card,use,self)
	for _,enemy in ipairs(self.enemies)do
		if enemy:getMark("dongxi") == 0 and enemy:getHandcardNum() >= 3 and not enemy:isKongcheng() and self:canDraw(enemy, self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
	if self:getOverflow() > 0 then
		for _,friend in ipairs(self.friends_noself)do
			if friend:getMark("dongxi") == 0  and self:canDraw(friend, self.player) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if self:canDraw(friend, self.player) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority["dongxi"] = 4.2


sgs.ai_skill_cardask["@huanxing"]=function(self,data, pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if math.random() < 0.6 then
		for _,h in sgs.list(cards)do
			if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
			then return h:getEffectiveId() end
			if h:isKindOf(pattern)
			then return h:getEffectiveId() end
		end
	end
	return "."
end


sgs.ai_skill_invoke.huanxing = function(self, data)
	local used = self.player:getTag("huanxing"):toBool()
	if used then
		local current = self.room:getCurrent()
		if current and self:isFriend(current) then
			return true
		end
	end
	return false
end

local zzy_weimian_skill = {}
zzy_weimian_skill.name = "zzy_weimian"
table.insert(sgs.ai_skills,zzy_weimian_skill)
zzy_weimian_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)

	return sgs.Card_Parse("#zzy_weimianCard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#zzy_weimianCard"] = function(card,use,self)
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend, self.player) and friend:getHandcardNum() >= 3 then
			use.card = card
			use.to:append(friend)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend, self.player) then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end
sgs.ai_use_priority.zzy_weimianCard = 4.2
sgs.ai_card_intention.zzy_weimianCard = -100

sgs.double_slash_skill = sgs.double_slash_skill .. "|luahuojianzhuixi"
local luahuojianzhuixi_skill={}
luahuojianzhuixi_skill.name="luahuojianzhuixi"
table.insert(sgs.ai_skills,luahuojianzhuixi_skill)
luahuojianzhuixi_skill.getTurnUseCard=function(self)
	
	local card = sgs.Card_Parse("#luahuojianzhuixiCard:.:")
	return card
end

sgs.ai_skill_use_func["#luahuojianzhuixiCard"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local c = sgs.Sanguosha:cloneCard("slash")
	c:deleteLater()
	local target
	for _, enemy in ipairs(self.enemies) do
		if  self:isWeak(enemy) and self:slashIsEffective(c, enemy) then
			target = enemy
			break
		end
	end

	
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
sgs.ai_use_priority["luahuojianzhuixiCard"] = sgs.ai_use_priority.Slash - 0.1



sgs.double_slash_skill = sgs.double_slash_skill .. "|luabaozhahuohua"
sgs.ai_cardneed.luabaozhahuohua = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.luabaozhahuohua = function(self, data)
	local damage = data:toDamage()
	local nextTarget = damage.to:getNextAlive()
	local beforeTarget = damage.to:getNextAlive()
	while beforeTarget:getNextAlive() ~= damage.to do
		beforeTarget = beforeTarget:getNextAlive()
	end

	local single = (beforeTarget == nextTarget)
	if single then
		if self:doDisCard(beforeTarget, "he") then 
			return true
		end
	else
		if self:doDisCard(beforeTarget, "he") and self:doDisCard(nextTarget, "he") then 
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.xuezou = function(self, data)
	for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
		for _, c in ipairs(sgs.QList2Table(p:getCards("ej"))) do
			if self:doDisCard(p, c:getEffectiveId()) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_suit["xuezou"] = function(self)
	local suits = {}
	local maxnum, maxsuit = 0, nil
	for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
		for _, c in ipairs(sgs.QList2Table(p:getCards("ej"))) do
			if self:doDisCard(p, c:getEffectiveId()) then
				if not suits[c:getSuitString()] then suits[c:getSuitString()] = 1 else suits[c:getSuitString()] = suits[c:getSuitString()] + 1 end
				if suits[c:getSuitString()] > maxnum then
					maxnum = suits[c:getSuitString()]
					maxsuit = c:getSuit()
				end
			end
		end
	end
	if maxsuit then
		return maxsuit
	end
	return math.random(0, 3)
end

sgs.ai_skill_use["@@zhanmeiqiyue"] = function(self, prompt)
	for _,friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) and friend:isFemale() then 
			return "#zhanmeiqiyuecard:.:->"..friend:objectName()
		end
	end
	for _,friend in ipairs(self.friends) do
		if self:canDraw(friend, self.player) and friend:isFemale() then 
			return "#zhanmeiqiyuecard:.:->"..friend:objectName()
		end
	end
	return "."
end
sgs.ai_card_intention["zhanmeiqiyuecard"] = -50



sgs.ai_view_as.feitianshuangzhan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and ((card:isRed() and not player:hasFlag("feitianshuangzhan_RedUsed")) or (card:isBlack() and not player:hasFlag("feitianshuangzhan_BlackUsed"))) and not card:hasFlag("using") then
		return ("slash:feitianshuangzhan[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local feitianshuangzhan_skill = {}
feitianshuangzhan_skill.name = "feitianshuangzhan"
table.insert(sgs.ai_skills,feitianshuangzhan_skill)
feitianshuangzhan_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local use_cards = {}
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if ((card:isRed() and not self.player:hasFlag("feitianshuangzhan_RedUsed")) or (card:isBlack() and not self.player:hasFlag("feitianshuangzhan_BlackUsed"))) and not card:isKindOf("Slash") 	and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(use_cards,card) end
	end

	for _,card in ipairs(use_cards)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("feitianshuangzhan")
		if slash:isAvailable(self.player)
		then
			sgs.ai_use_priority.Slash = 10
			return slash 
		end
	end
end
sgs.ai_event_callback[sgs.CardFinished].feitianshuangzhan = function(self,player,data)
	local use = data:toCardUse()
	if use.card and use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), "feitianshuangzhan") then
		sgs.ai_use_priority.Slash = 2.6
	end
end

sgs.ai_card_priority.feitianshuangzhan = function(self,card)
	if table.contains(card:getSkillNames(), "feitianshuangzhan")
	then
		if self.useValue
		then return 10 end
		return 0.08
	end
end




sgs.ai_skill_invoke.jinyanmofa = function(self, data)
	local use = data:toCardUse()
	local suit = use.card:getSuit()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		for _, judge in sgs.qlist(p:getJudgingArea()) do
			if (judge:getSuit() == suit) and (self.player:canDiscard(p, judge:getEffectiveId())) then
				if self:isFriend(p) then
					self.jinyanmofa = p
					return true
				end
			end
		end
		for _, equips_id in sgs.qlist(p:getEquips()) do
			if sgs.Sanguosha:getEngineCard(equips_id:getEffectiveId()):getSuit() == suit and self.player:canDiscard(p, equips_id:getEffectiveId()) then
				if self:doDisCard(p, equips_id:getEffectiveId()) then
					self.jinyanmofa = p
					return true
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.jinyanmofa = function(self, targets)
	if self.jinyanmofa then return self.jinyanmofa end
	for _,p in sgs.qlist(targets) do
		if self:doDisCard(p, "ej", true) then return p end
	end
	return nil
end


sgs.ai_skill_invoke.busizhixue = function(self, data)
	local damage = data:toDamage()
	--对自己无脑用
	if (damage.to:objectName() == self.player:objectName()) then
		return true
	elseif self:isFriend(damage.to) and (not self:isWeak() or (damage.to:isLord() and self:isWeak(damage.to))) then
		return not self:needToLoseHp(damage.to, damage.from, damage.card)
	end
end

sgs.ai_choicemade_filter.skillInvoke.busizhixue = function(self,player,promptlist)
	local damage = self.room:getTag("busizhixue"):toDamage()
	if damage.to and promptlist[3]=="yes" then
		sgs.updateIntention(player,damage.to,-80)
	end
end


sgs.ai_skill_invoke.boyi = function(self, data)
	local use = data:toCardUse()
	if self:doDisCard(self.player, "he") then return true end
	if use.from == self.player then
		if self:canLiegong(use.to:first(), self.player) then return false end
		for _, p in sgs.qlist(use.to) do
			if getCardsNum("Jink",p,self.player)<1 then
			else
				return true
			end
		end
		
	else
		local effect = sgs.CardEffectStruct()
		effect.card = use.card
		effect.from = use.from
		effect.to = self.player
		local _data = sgs.QVariant()
		_data:setValue(effect)
		return not self:canLiegong(self.player, use.from) and sgs.ai_skill_cardask["slash-jink"](self,_data,"jink",use.from) ~= "."
	end
	return false
end
sgs.ai_skill_discard["boyi"] = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getId())
	end

	return to_discard
end


local lingyin_skill = {}
lingyin_skill.name = "lingyin"
table.insert(sgs.ai_skills,lingyin_skill)
lingyin_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#lingyincard:.:")
end

sgs.ai_skill_use_func["#lingyincard"] = function(card,use,self)
	local arr1,arr2 = self:getWoundedFriend(false,false)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) and self:canDraw(arr1[1], self.player) then target = arr1[1] end
	if target then
		use.card = card
		use.to:append(target)
		return
	end
	if self:getOverflow()>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not friend:hasSkills("hunzi|longhun") and self:canDraw(friend, self.player) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority["lingyincard"] = 4.2
sgs.ai_card_intention["lingyincard"] = -100

sgs.dynamic_value.benefit["lingyincard"] = true

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lingyin"

sgs.ai_cardneed.langmanpaotai = sgs.ai_cardneed.slash
sgs.ai_skill_playerchosen.langmanpaotai = function(self, targets)
	local use = self.room:getTag("langmanpaotai"):toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:hasHeavyDamage(use.from,use.card, p) then return nil end
	end
	local should = false
	for _,p in sgs.qlist(use.to) do
		if (self:isFriend(p) and not self:needToLoseHp(p,use.from,use.card)) or (self:isEnemy(p) and self:needToLoseHp(p,use.from,use.card)) then should = true end
	end
	if should then
		for _,p in sgs.qlist(targets) do
			if self:doDisCard(p, "eh", true) then return p end
		end
	end
	if self:getOverflow() > 0 then return nil end
	for _,p in sgs.qlist(targets) do
		if self:doDisCard(p, "eh", true) then return p end
	end
	return nil
end

local DuriNoko_skill = {}
DuriNoko_skill.name = "DuriNoko"
table.insert(sgs.ai_skills, DuriNoko_skill)
DuriNoko_skill.getTurnUseCard = function(self, inclusive)
	local card_str = "#DuriNokocard:.:"
	local skillcard = sgs.Card_Parse(card_str)

	return skillcard
end
sgs.ai_skill_use_func["#DuriNokocard"]=function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local use_cards = cards[1]
	local targets = sgs.SPlayerList()
	for _,enemy in sgs.list(self.enemies)do
		if self.player:distanceTo(enemy) <= 1 and self:doDisCard(enemy, "he") then
			targets:append(enemy)
			if targets:length() >= self.player:getLostHp() and self.player:getLostHp() > 0 then
				break
			end
		end
	end
	if use_cards and targets:length() > 0 then
		local card_str = string.format("#DuriNokocard:%s:", use_cards:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to = targets
		end
		return
	end
end

