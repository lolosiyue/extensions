-- Source: b6025acc ai/kearwangushengxiang-ai.lua.


local dummy = AIUsePlan.dummy
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
 for _,key in ipairs({"from","to"})do if type(row[key])=="string"and row[key]~=""then d[key]=self.room:findPlayerByObjectName(row[key])end end
 if type(row.card)=="table"and next(row.card)~=nil then d.card=CardView.new(row.card)end;return d
end
local function role(self,p)
 local value=p:getRole();if value~=nil then return value end
 return self:useKnowledgeEstimate({value=self:getRoleEstimate(p),status="estimate",basis="kearwangushengxiang.unrevealed_role_viewer_estimate",target=p:objectName()}, "kearwangushengxiang.role")
end
--花木兰

ai_fill_skill.kenewgirlshixie = function(self, options, request)
    local inclusive = options and options.inclusive

	local alls = self.room:getAllPlayers()
	local needrec = 0
	local needhelp = 0
	local needda = 0
	local needchai = 0
	for _,p in sgs.qlist(alls) do
		if self:isFriend(p) and (p:getStrategyMark("banshixie-Clear") == 0) then
			needhelp = 1
			if p:isWounded() then
			    needrec = 1
			end
		end
		if self:isEnemy(p) and (p:getStrategyMark("banshixie-Clear") == 0) then
			needda = 1
			needchai = 1
		end
	end
	--打伤害
	if (needda == 1) and (self.player:getStrategyMark("useshixiespade-Clear") == 0) then
		local card_id
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (acard:getSuit() == sgs.Card_Spade) then
				to_throw:append(acard:getKnownEffectiveId())
			end
		end
		card_id = to_throw:at(0)
		if (card_id > 0) then
			return self:evaluateTurnSkillCard("kenewgirlshixie", "#kenewgirlshixieCard", {card_id}, request)
		end
	end
	--加血
	if (needrec == 1) and (self.player:getStrategyMark("useshixieheart-Clear") == 0) then
		local card_id
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (acard:getSuit() == sgs.Card_Heart) then
				to_throw:append(acard:getKnownEffectiveId())
			end
		end
		card_id = to_throw:at(0)
		if (card_id > 0) then
			return self:evaluateTurnSkillCard("kenewgirlshixie", "#kenewgirlshixieCard", {card_id}, request)
		end
	end
	--摸牌
	if (needhelp == 1) and (self.player:getStrategyMark("useshixiediamond-Clear") == 0) then
		local card_id
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (acard:getSuit() == sgs.Card_Diamond) then
				to_throw:append(acard:getKnownEffectiveId())
			end
		end
		card_id = to_throw:at(0)
		if (card_id > 0) then
			return self:evaluateTurnSkillCard("kenewgirlshixie", "#kenewgirlshixieCard", {card_id}, request)
		end
	end
	--拆牌
	if (needchai == 1) and (self.player:getStrategyMark("useshixieclub-Clear") == 0) then
		local card_id
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local to_throw = AIList.new({})
		for _, acard in ipairs(cards) do
			if (acard:getSuit() == sgs.Card_Club) then
				to_throw:append(acard:getKnownEffectiveId())
			end
		end
		card_id = to_throw:at(0)
		if (card_id > 0) then
			return self:evaluateTurnSkillCard("kenewgirlshixie", "#kenewgirlshixieCard", {card_id}, request)
		end
	end
	return nil
end


ai_card_use["#kenewgirlshixieCard"] = function(self, card, use, request)
	local idd =  card:getKnownEffectiveId()
	if self:getKnownCardById(idd):isRed() then
		self:sort(self.friends, "hp")
		for _,ep in sgs.list(self.friends)do
			if (ep:getStrategyMark("banshixie-Clear") == 0) then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	else
		self:sort(self.enemies, "hp")
		for _,ep in sgs.list(self.enemies)do
			if (ep:getStrategyMark("banshixie-Clear") == 0) then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	end
end

sgs.ai_use_value.kenewgirlshixieCard = 8.5
sgs.ai_use_priority.kenewgirlshixieCard = 9.5
sgs.ai_card_intention.kenewgirlshixieCard = 80


ai_skill_invoke.kenewgirlcongrong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local room = self.player:getRoom()
	for _,p in sgs.qlist(room:getAllPlayers()) do
		if p:getStrategyFlag("ifwantkenewgirlcongrong") and self:isFriend(p) then
	        return (true) or false
		end
	end
	return false

end

--娘张飞
ai_skill_choice.kenewgirlfuyi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = data:toCardUse()
	local items = choices:split("+")
	if use.from:objectName() == self.player:objectName() then
		local dummy_use = self:aiUseCard(use.card, dummy(true,2,use.to))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:length() > use.to:length() and table.contains(items, "add") then
			return ai_choice_result(("add"), options)
		end
		self:sort(self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) and self:isWeak() then
				return ai_choice_result(("beishui"), options)
			end
		end
		if use.card:isDamageCard() then
			return ai_choice_result(("eff"), options)
		end
		if use.card:isKindOf("Peach") then
			if self.player:getLostHp() > 1 then
				return ai_choice_result(("eff"), options)
			elseif table.contains(items, "add")  then
				for _, friend in ipairs(self.friends_noself) do
					if friend:getHp()<getBestHp(friend) then
						return ai_choice_result(("add"), options)
					end
				end
			end
		end
	else
		if self:isFriend(use.from) then
			if use.card:isKindOf("Peach") then
				if self.player:getLostHp() > 1 then
					return ai_choice_result(("eff"), options)
				elseif table.contains(items, "add")  then
					for _, friend in ipairs(self.friends_noself) do
						if friend:getHp()<getBestHp(friend) then
							return ai_choice_result(("add"), options)
						end
					end
				end
			end
		end
		if self:isFriend(use.from) and self:isWeak(use.from) and self:isWeak() then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) then
					return ai_choice_result(("beishui"), options)
				end
			end
		end
	end
	return ai_choice_result(("cancel"), options)
end

sgs.ai_skill_playerschosen.kenewgirlfuyi = function(self, targets, max, min)
	local use = self:getDecisionData():toCardUse()
    local selected = AIList.new({})
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	if self.player:getStrategyFlag("beishuifuyi") then
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) and target:getHp() < getBestHp(target) and not use.to:contains(target) then
				selected:append(target)
			end
			if selected:length() >= max then break end
		end
	else
		local dummy_use = self:aiUseCard(use.card, dummy(true,2,use.to))
		if dummy_use.card and dummy_use and dummy_use.to then
			for _, p in sgs.qlist(dummy_use.to) do
				if not use.to:contains(p) then
					selected:append(p)
					if selected:length() >= max then break end
				end
			end
		end
	end
    return selected
end

ai_skill_invoke.kenewgirlzhenyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target and self:isFriend(target) then
		return (true) or false
	end
	return false

end
sgs.ai_choicemade_filter.skillInvoke["kenewgirlzhenyi"] = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if p:getStrategyFlag("kenewgirlzhenyiTarget") then target = p break end
		end
		if target then
            self:updateIntention(player, target, -80)
		end
	end
end


--娘姜维

sgs.ai_skill_playerschosen.kenewgirljizhi = function(self, targets, max, min)
    local selected = AIList.new({})
    local n = max
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	if (n > 0) then
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) then
				selected:append(target)
				n = n - 1
			end
			if n <= 0 then break end
		end
	end
    return selected
end
ai_skill_invoke["kenewgirljizhi"] = true

sgs.ai_canNiepan_skill.kenewgirljizhi = function(player)
	return player:getStrategyMark("@kenewgirljizhi") > 0
end

ai_fill_skill.kenewgirljingmu = function(self, options, request)
    local inclusive = options and options.inclusive

	
	return self:legacySkillSeed("kenewgirljingmu", "#kenewgirljingmuCard", request)
end


ai_card_use["#kenewgirljingmuCard"] = function(self, card, use, request)
	self:sort(self.enemies, "hp")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp()<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = owner_fact(self,"JilveWansha")
		for _,zcard in sgs.list(self.player:getCards("he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getKnownEffectiveId()==keep_weapon:getKnownEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getKnownId()) end
			end
		end
	end

	if #unpreferedCards<1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=card:getTargetModResidue(self.player)
				then
					if self:aiUseCard(card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,card:getKnownId()) end
			end
		end

		local num = self:getCardsNum("Jink")-1
		if self.player:getArmor() then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Jink") and num>0 then
					table.insert(unpreferedCards,card:getKnownId())
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card, self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getKnownId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getKnownId()) end
			end
		end
	end


	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(self:getKnownCardById(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		local slash = self:evaluateSkillCard("kenewgirljingmu", "slash", {})
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card then
			for _, p in sgs.qlist(dummy_use.to) do
				if self:doDisCard(p, "he") then
					use.card=self:bindSkillCard("kenewgirljingmu", use_cards, request, nil, "#kenewgirljingmuCard")
					use.to:append(p)
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
	local target = self:findPlayerToDamage(2, self.player, "N", targets, 0)[1]
	return target
end

ai_skill_choice.kenewgirlduoshuai = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("two"), options)
end

ai_skill_invoke["kenewgirlshibing"] = true

ai_skill_invoke.kenewgirlshibingdiscardask      = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:doDisCard(target, "he") then
		return (true) or false
	end
	return (false) or false
end
sgs.ai_choicemade_filter.cardChosen.kenewgirlshibing = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_playerchosen.kenewgirlshibing = function(self, targets)
	local dmg = owner_damage(self)
	for _,enemy in ipairs(self.enemies)do
		if (enemy:getHp()<=dmg.damage and enemy:isAlive()) then
			if self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
				and not (dmg.card and dmg.card:getTypeId()==sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
				return enemy
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:isChained() and dmg.nature~=sgs.DamageStruct_Normal
		and not self:isGoodChainTarget(friend, dmg.card or dmg.nature, dmg.from, dmg.damage)
		then
		elseif friend:getHp()>=2 and dmg.damage<2
		and self:needToLoseHp(friend)
		then return friend
		elseif dmg.card and dmg.card:getTypeId()==sgs.Card_TypeTrick
		and friend:hasSkill("wuyan") and friend:getLostHp()>1
		then return friend
	end

	for _,enemy in ipairs(self.enemies)do
		if (enemy:getHandcardNum()<=2)
			and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
			and not (dmg.card and dmg.card:getTypeId()==sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
			return enemy end
		end
	end

	for i = #self.enemies,1,-1 do
		local enemy = self.enemies[i]
		if not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive()
			and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
			and (not (dmg.card and dmg.card:getTypeId()==sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp()>0) or self:isWeak()) then
			return enemy
		end
	end
end

sgs.ai_playerchosen_intention.kenewgirlshibing = function(self, from, to)
	if self:needToLoseHp(to) then return end
	local intention = 10
	self:updateIntention(from, to, intention)
end


ai_skill_choice["kenewgirlshibing"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		if not self:needToLoseHp(damage.to, damage.from, damage.card) then return ai_choice_result(("dis"), options) end
	end
	if self:isFriend(damage.from) then
		if not self:cantDamageMore(damage.to, damage.from) then
			return ai_choice_result(("add"), options)
		end
	end
	return ai_choice_result(("cancel"), options)
end

sgs.ai_skill_playerschosen.kenewgirltanyan = function(self, targets, max, min)
    local selected = AIList.new({})
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isEnemy(target) then
			selected:append(target)
		end
		if selected:length() >= max then break end
	end
    return selected
end

ai_skill_invoke.kenewgirlganglv = true

ai_skill_use["@@kenewgirlganglv"]=function(self,prompt,request)
 for _,original in ipairs(self.player:getNotifiedPileCards("kenewgirlganglv"))do
  local card,candidate=self:getAcquiredCardEvaluation(original)
  if not card or not candidate then ai_unsupported("ganglv disclosed current-card evaluation unavailable","kenewgirlganglv")end
  local old=self._evaluation_scope;self._evaluation_scope={card=card,candidate=candidate}
  local ok,plan=pcall(self.aiUseCard,self,card);self._evaluation_scope=old
  if not ok then error(plan,0)end
  if AIUnsupported.is(plan)then error(plan,0)end
  if plan.card and plan.to then
   if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
   plan.card=self:bindSkillCard("kenewgirlganglv", {original:getKnownEffectiveId()}, request)
   return plan:toAnswer()
  end
 end
 return "."
end

ai_fill_skill.kenewgirlbuguan = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#kenewgirlbuguanCard") then return end
	return self:legacySkillSeed("kenewgirlbuguan", "#kenewgirlbuguanCard", request)
end

ai_card_use["#kenewgirlbuguanCard"] = function(self, card, use, request)
	local buguanslash = self:evaluateSkillCard("kenewgirlbuguan", "slash", {})
	local ppp = AIList.new({})
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, buguanslash, false) then
			ppp:append(p)
		end
	end
	local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, ppp)
	if target then
		use.card = self:bindSkillCard("kenewgirlbuguan", {}, request, nil, "#kenewgirlbuguanCard")
		return
	end
end
sgs.ai_use_value["kenewgirlbuguanCard"] = 5
sgs.ai_use_priority["kenewgirlbuguanCard"]  = sgs.ai_use_priority.Slash - 0.1

sgs.ai_skill_playerchosen.kenewgirlbuguan = function(self, targets)
	targets = sgs.QList2Table(targets)
	if self.player:getStrategyFlag("kenewgirlbuguan_draw") then
		return self.player
	end
	if self.player:getStrategyFlag("kenewgirlbuguan_recover") then
		for _, p in ipairs(targets) do
			if self:isFriend(p) and p:getHp() < getBestHp(p) then
				return p
			end
		end
	end
	if self.player:getStrategyFlag("kenewgirlbuguan_judge") then
		for _, p in ipairs(targets) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then
				return p
			end
		end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


ai_skill_choice["kenewgirlbuguan"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local buguanslash = self:evaluateSkillCard("kenewgirlbuguan", "slash", {})
	if self:getOverflow() > 0 and table.contains(items, "discard") then
		return ai_choice_result(("discard"), options)
	end
	if table.contains(items, "throw") then
		local ppp = AIList.new({})
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.player:canSlash(p, buguanslash, false) then
					ppp:append(p)
				end
			end
		local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, ppp)
		if target and self:isEnemy(target) and target:hasEquipArea() then
			if  getCardsNum("Jink", target, self.player) < 1 or self:canLiegong(target, self.player) then
				return ai_choice_result(("throw"), options)
			end
		end
	end
	if self.player:getHp() + self:getAllPeachNum() > 0  and table.contains(items, "losehp") then
		return ai_choice_result(("losehp"), options)
	end
	if table.contains(items, "hlose") then
		local damage = data:toDamage()
		if damage.to then
			if self:isFriend(damage.to) and self:hasZhaxiangEffect(damage.to) or (self:isEnemy(damage.to) and not self:hasZhaxiangEffect(damage.to)) then
				return ai_choice_result(("hlose"), options)
			end
		end
	end
	if table.contains(items, "hdraw") then
		return ai_choice_result(("hdraw"), options)
	end
	if table.contains(items, "hdis") then
		local damage = data:toDamage()
		if damage.to then
			if self:doDisCard(damage.to, "he", false, 2) then
				return ai_choice_result(("hdis"), options)
			end
		end
	end
	if table.contains(items, "hrec") then
		for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
			if self:isFriend(p) and p:getHp() < getBestHp(p) then
				return ai_choice_result(("hrec"), options)
			end
		end
	end
	if table.contains(items, "hpanding") then
		for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then
				return ai_choice_result(("hpanding"), options)
			end
		end
	end
	if table.contains(items, "hthrow") then
		return ai_choice_result(("hthrow"), options)
	end

	return ai_choice_result(("cancel"), options)
end



ai_fill_skill.kenewgirljuzhong = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#kenewgirljuzhongCard") then return end
	return self:legacySkillSeed("kenewgirljuzhong", "#kenewgirljuzhongCard", request)
end

ai_card_use["#kenewgirljuzhongCard"] = function(self, card, use, request)
	local target = nil
	local max = 0
	local min = 999
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHandcardNum() > max then
			max = p:getHandcardNum()
        end
		if p:getHandcardNum() < min then
			min = p:getHandcardNum()
        end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() == max and self:doDisCard(enemy, "he") and self.player:getStrategyMark("usejuzhongqi-PlayClear") < 2 then
			target = enemy
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend:getHandcardNum() == min and self:canDraw(friend, self.player) and self.player:getStrategyMark("usejuzhongmo-PlayClear") < 2 then
			target = friend
		end
	end
	if target then
		use.card = self:bindSkillCard("kenewgirljuzhong", {}, request, nil, "#kenewgirljuzhongCard")
		if use.to then use.to:append(target) end
		return
	end
end
sgs.ai_use_value["kenewgirljuzhongCard"] = 5
sgs.ai_use_priority["kenewgirljuzhongCard"]  = 5

ai_skill_choice["kenewgirljuzhong"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "maxqi") and target and self:doDisCard(target, "he") then
		return ai_choice_result(("maxqi"), options)
	end
	return ai_choice_result(("minmo"), options)
end

ai_skill_choice["kenewgirlshiqian"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toPlayer()
	local skills = choices:split("+")
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk, player, true) then
			return ai_choice_result((sk), options)
		end
	end
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk, player) then
			return ai_choice_result((sk), options)
		end
	end
	
	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if not string.find(sgs.bad_skills,sk) then table.insert(not_bad_skills,sk) end
	end
	if #not_bad_skills>0 then
		return ai_choice_result((not_bad_skills[math.random(1,#not_bad_skills)]), options)
	end
	
	return ai_choice_result((skills[math.random(1,#skills)]), options)
	
end
ai_skill_invoke.kenewgirlshiqian = true

sgs.ai_can_damagehp.kenewgirlshiqian = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end


ai_fill_skill.kenewgirlchenji = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#kenewgirlchenjiCard") then return end
	return self:legacySkillSeed("kenewgirlchenji", "#kenewgirlchenjiCard", request)
end

ai_card_use["#kenewgirlchenjiCard"] = function(self, card, use, request)
	local target = nil
	for _, friend in ipairs(self.friends) do
		if self:canDraw(friend, self.player) and self:needToLoseHp(friend, self.player) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if self:canDraw(friend, self.player) then
				target = friend
				break
			end
		end
	end
	if target then
		use.card = self:bindSkillCard("kenewgirlchenji", {}, request, nil, "#kenewgirlchenjiCard")
		if use.to then use.to:append(target) end
		return
	end
end
sgs.ai_use_value["kenewgirlchenjiCard"] = 5
sgs.ai_use_priority["kenewgirlchenjiCard"]  = 5


sgs.ai_cardneed.kenewgirlchandou = sgs.ai_cardneed.slash

ai_skill_choice["kenewgirlchandou"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local effect = data:toCardEffect()
	local juedou = self:evaluateSkillCard("kenewgirlchandou", "duel", {})
	if self.player:objectName() ==  effect.to:objectName() then
		if effect.from and self:isEnemy(effect.from) and self:isWeak(effect.from) then
			local dummy_use = self:aiUseCard(juedou, dummy(true, 0, self.room:getOtherPlayers(effect.from)))
			if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(effect.from) then
				return ai_choice_result(("juedou"), options)
			end
		end
		return ai_choice_result(("dis"), options)
	elseif self.player:objectName() ==  effect.from:objectName() then
		if self:getOverflow() > 0 or self:hasHeavyDamage(self.player, effect.card, effect.to) then
			return ai_choice_result(("beishui"), options)
		end
		local dummy_use = self:aiUseCard(juedou, dummy(true, 0, self.room:getOtherPlayers(effect.to)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(effect.to) then
			return ai_choice_result(("juedou"), options)
		end
	end
	return ai_choice_result(("dis"), options)
end

sgs.ai_cardneed.kenewgirljiang = sgs.ai_cardneed.jiang
sgs.ai_card_priority.kenewgirljiang = sgs.ai_card_priority.jiang

ai_fill_skill.kenewgirlscshixie = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies < 1 or self.player:getStrategyMark("@kenewgirlscshixie") < 1 then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if player:getHp() >= 2 then
			too_weak = false
		end
	end
	if too_weak then return end
	local lord = self.room:getLord()
	if self.player:getKnownRole() == "lord" or self.player:getKnownRole() == "loyalist" or self.player:getKnownRole() == "rebel" then
		return self:legacySkillSeed("kenewgirlscshixie", "#kenewgirlscshixieCard", request)
	end
	if self.player:getKnownRole() == "renegade" then
		if #self.friends + 1 >= #self.enemies and (self.player:getHp() >= 3 or lord:getHp() >= 3) then return end
		if #self.friends >= #self.enemies and (self.player:getHp() >= 2 or lord:getHp() >= 2) then return end
		return self:legacySkillSeed("kenewgirlscshixie", "#kenewgirlscshixieCard", request)
	end
end


ai_card_use["#kenewgirlscshixieCard"] = function(self, card, use, request)
	local target
	self:sort(self.enemies, "defense")
	local lord = self.room:getLord()
	if self.player:getKnownRole() == "rebel" then
		target = lord
	end
	if self.player:getKnownRole() == "loyalist" or self.player:getKnownRole() == "lord" then
		for _, enemy in ipairs(self.enemies) do
			if enemy then
				target = enemy
			end
		end
	end
	if self.player:getKnownRole() == "renegade" then
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
		if lord:getHp() <= 2 then
			for _, enemy in ipairs(self.enemies) do
				if role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
	end
	if target then
		use.card = self:bindSkillCard("kenewgirlscshixie", {}, request, nil, "#kenewgirlscshixieCard")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["kenewgirlscshixieCard"]       = 8
sgs.ai_use_priority["kenewgirlscshixieCard"]    = 8
sgs.ai_card_intention["kenewgirlscshixieCard"]  = 108