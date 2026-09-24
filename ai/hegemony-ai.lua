sgs.ai_skill_cardask["@xiaoguo"] = function(self,data)
	local currentplayer = self.room:getCurrent()

	local has_analeptic,has_slash,has_jink
	for _,acard in sgs.qlist(self.player:getHandcards())do
		if acard:isKindOf("Analeptic") then has_analeptic = acard
		elseif acard:isKindOf("Slash") then has_slash = acard
		elseif acard:isKindOf("Jink") then has_jink = acard
		end
	end

	local card

	if has_slash then card = has_slash
	elseif has_jink then card = has_jink
	elseif has_analeptic then
		if (getCardsNum("EquipCard",currentplayer,self.player)==0 and not self:isWeak()) or self:getCardsNum("Analeptic")>1 then
			card = has_analeptic
		end
	end

	if not card then return "." end
	if self:isFriend(currentplayer) then
		if self:needToThrowArmor(currentplayer) then
			if card:isKindOf("Slash") or (card:isKindOf("Jink") and self:getCardsNum("Jink")>1) then
				return "$"..card:getEffectiveId()
			else return "."
			end
		end
	elseif self:isEnemy(currentplayer) then
		if not self:damageIsEffective(currentplayer) then return "." end
		if self:needToLoseHp(currentplayer,self.player) then return "." end
		if self:needToThrowArmor() then return "." end
		if currentplayer:getHp()>2 and (currentplayer:getHandcardNum()>2 or currentplayer:getCards("e"):length()>1)then return "." end
		if currentplayer:getHp()>1 and (currentplayer:getHandcardNum()>3 or currentplayer:getCards("e"):length()>2)then return "." end
		if self:hasSkills(sgs.lose_equip_skill,currentplayer) and currentplayer:getCards("e"):length()>0 then return "." end
		return "$"..card:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@xiaoguo"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		local current = self.room:getCurrent()
		if not current then return end
		local intention = 10
		if self:hasSkills(sgs.lose_equip_skill,current) and current:getCards("e"):length()>0 then intention = 0 end
		if self:needToThrowArmor(current) then return end
		sgs.updateIntention(player,current,intention)
	end
end

sgs.ai_skill_cardask["@xiaoguo-discard"] = function(self,data)
	local yuejin = self.room:findPlayerBySkillName("xiaoguo")
	if self:needToThrowArmor() then
		return "$"..self.player:getArmor():getEffectiveId()
	end
	if not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,yuejin) then
		return "."
	end
	if self:needToLoseHp(self.player,yuejin) then
		return "."
	end
	local card_id
	if self:hasSkills(sgs.lose_equip_skill,self.player) then
		if self.player:getWeapon() then card_id = self.player:getWeapon():getId()
		elseif self.player:getOffensiveHorse() then card_id = self.player:getOffensiveHorse():getId()
		elseif self.player:getArmor() then card_id = self.player:getArmor():getId()
		elseif self.player:getDefensiveHorse() then card_id = self.player:getDefensiveHorse():getId()
		end
	end

	if not card_id then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("EquipCard") then
				card_id = card:getEffectiveId()
				break
			end
		end
	end

	if not card_id then
		if self.player:getWeapon() then card_id = self.player:getWeapon():getId()
		elseif self.player:getOffensiveHorse() then card_id = self.player:getOffensiveHorse():getId()
		elseif self:isWeak(self.player) and self.player:getArmor() then card_id = self.player:getArmor():getId()
		elseif self:isWeak(self.player) and self.player:getDefensiveHorse() then card_id = self.player:getDefensiveHorse():getId()
		end
	end

	if not card_id then return "." else return "$"..card_id end
end

sgs.ai_cardneed.xiaoguo = function(to,card)
	return getKnownCard(to,global_room:getCurrent(),"BasicCard",true)==0 and card:getTypeId()==sgs.Card_Basic
end

sgs.ai_skill_choice.shushen = function(self,choices)
	return self.shushenchoice
end

sgs.ai_skill_playerchosen.shushen = function(self,targets)
	if #self.friends_noself==0 then return nil end
	local target
	self:sort(self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if self:isWeak(friend) then
			target = friend break
		end
	end
	if target then
		self.shushenchoice = "recover"
	else
		target = self:findPlayerToDraw(false,2)
		self.shushenchoice = "draw"
	end
return target
end

sgs.ai_playerchosen_intention.shushen = -80

sgs.ai_skill_invoke.shenzhi = function(self,data)
	if self:getCardsNum("Peach")>0 then return false end
	if self.player:getHandcardNum()>=3 then return false end
	if self.player:getHandcardNum()>=self.player:getHp() and self.player:isWounded() then return true end
	if self.player:hasSkill("beifa") and self.player:getHandcardNum()==1 and self:needKongcheng() then return true end
	if self.player:hasSkill("sijian") and self.player:getHandcardNum()==1 then return true end
	return false
end

function sgs.ai_cardneed.shenzhi(to,card)
	return to:getHandcardNum()<to:getHp()
end

-- Canonical HStandard skills can also be acquired by identity-mode extensions.
-- Keep only skill/card policies here; the mode-wide Hegemony AI stays gated.
local function hegemonyV2Card(name, id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    if id then card:addSubcard(id) end
    return card
end

local function hegemonyWillShow(self, defence)
    if not sgs.GetConfig("EnableHegemony", false) then return true end
    if defence then return self:willShowForDefence() end
    return self:willShowForAttack()
end

function SmartAI:useCardAwaitExhausted(AwaitExhausted, use)
	if not AwaitExhausted:isAvailable(self.player) then return end
	use.card = AwaitExhausted
	return
end
sgs.ai_use_priority.AwaitExhausted = 2.8
sgs.ai_use_value.AwaitExhausted = 4.9
sgs.ai_keep_value.AwaitExhausted = 1
sgs.ai_card_intention.AwaitExhausted = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, -50)
	end
end
sgs.ai_nullification.AwaitExhausted = function(self, card, from, to, positive)
	if positive then
		if self:isEnemy(to) and (not sgs.GetConfig("EnableHegemony", false) or self:evaluateKingdom(to) ~= "unknown") then
			if self:getOverflow() > 0 or self:getCardsNum("Nullification") > 1 then return true end
			if self:hasSkills(sgs.lose_equip_skill, to) and to:getEquips():length() > 0 then return true end
			if to:getArmor() and self:needToThrowArmor(to) then return true end
		end
	else
		if self:isFriend(to) and (self:getOverflow() > 0 or self:getCardsNum("Nullification") > 1) then return true end
	end
	return
end

sgs.ai_fill_skill.heg_duoshi = function(self, inclusive)
	local DuoTime = 2
	if self.player:hasSkills("heg_fenming|heg_zhiheng|fenxun|heg_keji") then
		DuoTime = 1
	end
	if self.player:hasSkills("heg_hongyan|heg_yingzi_zhouyu|heg_yingzi_sunce") then
		DuoTime = 3
	end
	if self.player:hasSkills("heg_xiaoji|heg_haoshi") then
		DuoTime = 4
	end
	for _, player in ipairs(self.friends) do
		if (player:hasShownSkill("heg_xiaoji") or player:hasShownSkill("heg_haoshi")) then
			DuoTime = 4
			break
		end
	end

	if (self.player:usedTimes("DuoshiAE") >= DuoTime and self:getOverflow() <= 0) or self.player:usedTimes("DuoshiAE") >= 4 	then return end


	if sgs.turncount <= 1 and #self.friends_noself == 0 and not self:isWeak() and self:getOverflow() <= 0 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)


	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange  and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashes = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashes) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return end
			end
		end
	end

	local red_card
	if self.player:getHandcardNum() <= 2 then return end
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isRed() then
			local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.AwaitExhausted and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			local heg_sunshangxiang = false
			if self.player:hasSkills("heg_xiaoji") and self.player:getCards("e"):length() > 0 then
				heg_sunshangxiang = true
			end
			for _, player in ipairs(self.friends) do
				if player:hasShownSkill("heg_xiaoji") and player:getCards("e"):length() > 0 then
					heg_sunshangxiang = true
					break
				end
			end

			if not hegemonyWillShow(self, true) and not heg_sunshangxiang then
				shouldUse = false
			end

			if shouldUse and not card:isKindOf("Peach") then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = string.format("await_exhausted:heg_duoshi[%s:%d]=%d&heg_duoshi",red_card:getSuitString(), red_card:getNumber(), red_card:getEffectiveId())
		local await = sgs.Card_Parse(card_str)
		assert(await)
		return await
	end
end


-- Shared identity Fenxun uses the V2 proxy; its historical usage key stays FenxunCard.
local function fenxunV2Card(id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName("fenxun")
    card:addSubcard(id)
    return card
end

sgs.ai_fill_skill.fenxun = function(self)
	if #self.enemies==0 then return end
	if self:needBear() then return end
	if not self.player:isNude() then
		local card_id
		local slashcount = self:getCardsNum("Slash")
		local jinkcount = self:getCardsNum("Jink")
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)

		if self:needToThrowArmor() then
			return fenxunV2Card(self.player:getArmor():getId())
		elseif self.player:getHandcardNum()>0 then
			local lightning = self:getCard("Lightning")
			if lightning and not self:willUseLightning(lightning) then
				card_id = lightning:getEffectiveId()
			else
				for _,acard in ipairs(cards)do
					if (acard:isKindOf("AmazingGrace") or acard:isKindOf("EquipCard")) then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
			if not card_id and jinkcount>1 then
				for _,acard in ipairs(cards)do
					if acard:isKindOf("Jink") then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
			if not card_id and slashcount>1 then
				for _,acard in ipairs(cards)do
					if acard:isKindOf("Slash") then
						slashcount = slashcount-1
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
		end

		if not card_id and self.player:getWeapon() then
			card_id = self.player:getWeapon():getId()
		end

		if not card_id then
			for _,acard in ipairs(cards)do
				if (acard:isKindOf("AmazingGrace") or acard:isKindOf("EquipCard") or acard:isKindOf("BasicCard"))
					and not isCard("Peach",acard,self.player) and not isCard("Slash",acard,self.player) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end

		if slashcount>0 and card_id then
			return fenxunV2Card(card_id)
		end
	end
	return nil
end

sgs.ai_skill_use_func.fenxun = function(card,use,self)
	self:sort(self.enemies,"defense")
	local target
	for _,slash in ipairs(self:getCards("Slash"))do
		if not card:getSubcards():contains(slash:getEffectiveId()) then
			local target_num,hastarget = 0,nil
			for _,enemy in ipairs(self.enemies)do
				if not self:slashProhibit(slash,enemy) and self.player:canSlash(enemy,slash,false) and self:isGoodTarget(enemy,self.enemies,slash) then
					if self.player:distanceTo(enemy)>1 and not target then target = enemy
					elseif self.player:distanceTo(enemy)==1 then
						hastarget = true
					end
					if self.player:inMyAttackRange(enemy) then
						target_num = target_num+1
					end
				end
			end
			if hastarget and target_num>=2 then return end
		end
	end
	if target and self:getCardsNum("Slash")>0 then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_use_value.fenxun = 5.5
sgs.ai_use_priority.fenxun = 8
sgs.ai_card_intention.fenxun = 50

sgs.ai_fill_skill.xiongyi = function(self)
	if self.player:getMark("@arise") < 1 then return end
	if not sgs.GetConfig("EnableHegemony", false) and self:isWeak() then
		return hegemonyV2Card("xiongyi")
	end

	if self.player:hasShownSkill(sgs.Sanguosha:getSkill("heg_baoling")) then
		return hegemonyV2Card("xiongyi")
	end

	for _, friend in ipairs(self.friends) do
		if (not sgs.GetConfig("EnableHegemony", false) or self:objectiveLevel(friend) == 2 or self.player:isFriendWith(friend)) and self:isWeak(friend) then
			return hegemonyV2Card("xiongyi")
		end
	end
	if sgs.GetConfig("EnableHegemony", false) and sgs.originalHegemonyGameProcess() == "qun>>>" then
		return hegemonyV2Card("xiongyi")
	end
end

sgs.ai_skill_use_func.xiongyi = function(card, use, self)
	use.card = card
	-- Identity chooses beneficiaries; Hegemony determines its friends in the skill.
	if not sgs.GetConfig("EnableHegemony", false) and use.to then
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) then use.to:append(friend) end
		end
	end
end

sgs.ai_card_intention.xiongyi = -80
sgs.ai_use_priority.xiongyi = 9.31

sgs.ai_skill_invoke.heg_mingshi = true

sgs.ai_skill_invoke.lirang = function(self, data)
	if not hegemonyWillShow(self) then
		return false
	end
	return #self.friends_noself > 0
end

sgs.ai_skill_askforyiji.lirang = function(self, card_ids)
	self:updatePlayers()
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local id = card_ids[1]

	local card, friend = self:getCardNeedPlayer(cards, self.friends_noself)
	if card and friend then return friend, card:getId() end
	if #self.friends_noself > 0 then
		self:sort(self.friends_noself, "handcard")
		for _, afriend in ipairs(self.friends_noself) do
			if not self:needKongcheng(afriend, true) then
				return afriend, id
			end
		end
		self:sort(self.friends_noself, "defense")
		return self.friends_noself[1], id
	end
	return nil, -1
end

sgs.ai_skill_playerchosen.shuangren = function(self, targets)
	if self.player:isKongcheng() then return nil end
	if not hegemonyWillShow(self) then return nil end
	if self.player:getMark("ViewAsSkill_shuangxiongEffect") > 0 and self.player:hasSkill("shuangxiong") then return nil end

	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card and not dummy_use.to:isEmpty() then
		for _, enemy in sgs.qlist(dummy_use.to) do
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if targets:contains(enemy) and max_point > enemy_max_point then
				self.shuangren_card = max_card:getEffectiveId()
				return enemy
			end
		end
		for _, enemy in sgs.qlist(dummy_use.to) do
			if targets:contains(enemy) and max_point >= 10 then
				self.shuangren_card = max_card:getEffectiveId()
				return enemy
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.shuangren(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_skill_playerchosen["shuangren_slash"] = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_playerchosen_intention.shuangren = 20
sgs.ai_cardneed.shuangren = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.heg_suishi = function(self, data)
	local event = data:toInt()
	if event == sgs.Death then return false end
	return true
end

sgs.ai_skill_playerchosen.sijian = function(self, targets)
	-- The shared helper returns a ranked list; the callback requires one legal player.
    for _, target in ipairs(self:findPlayerToDiscard("he", false, true, targets, "sijian")) do
        if targets:contains(target) then return target end
    end
    return nil
end

sgs.ai_cardneed.sijian = function(to, card, self)
    return to:isKongcheng() and not self:needKongcheng(to)
end

sgs.ai_playerchosen_intention.sijian = function(self, from, to)
	local intention = 80
	if (to:hasShownSkill("kongcheng") and to:getHandcardNum() == 1) or self:needToThrowArmor(to) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_invoke.kuangfu = function(self,data)
	local damage = data:toDamage()
	if self:hasSkills(sgs.lose_equip_skill,damage.to) then
		return self:isFriend(damage.to) and not self:isWeak(damage.to)
	end
	local benefit = (damage.to:getCards("e"):length()==1 and damage.to:getArmor() and self:needToThrowArmor(damage.to))
	if self:isFriend(damage.to) then return benefit end
	return not benefit
end

sgs.ai_skill_choice.kuangfu_equip = function(self,choices,data)
	local who = data:toPlayer()
	if self:isFriend(who) then
		if choices:match("1") and self:needToThrowArmor(who) then return "1" end
		if choices:match("1") and self:evaluateArmor(who:getArmor(),who)<-5 then return "1" end
		if self:hasSkills(sgs.lose_equip_skill,who) and self:isWeak(who) then
			if choices:match("0") then return "0" end
			if choices:match("3") then return "3" end
		end
	else
		local dangerous = self:getDangerousCard(who)
		if dangerous then
			local card = sgs.Sanguosha:getCard(dangerous)
			if card:isKindOf("Weapon") and choices:match("0") then return "0"
			elseif card:isKindOf("Armor") and choices:match("1") then return "1"
			elseif card:isKindOf("DefensiveHorse") and choices:match("2") then return "2"
			elseif card:isKindOf("OffensiveHorse") and choices:match("3") then return "3"
			end
		end
		if choices:match("1") and who:hasArmorEffect("EightDiagram") and not self:needToThrowArmor(who) then return "1" end
		if self:hasSkills("jijiu|beige|mingce|weimu|heg_qingcheng",who) and self:doDisCard(who,"e") then
			if choices:match("2") then return "2" end
			if choices:match("1") and who:getArmor() and not self:needToThrowArmor(who) then return "1" end
			if choices:match("3") and (not who:hasSkill("jijiu") or who:getOffensiveHorse():isRed()) then return "3" end
			if choices:match("0") and (not who:hasSkill("jijiu") or who:getWeapon():isRed()) then return "0" end
		end
		local valuable = self:getValuableCard(who)
		if valuable then
			local card = sgs.Sanguosha:getCard(valuable)
			if card:isKindOf("Weapon") and choices:match("0") then return "0"
			elseif card:isKindOf("Armor") and choices:match("1") then return "1"
			elseif card:isKindOf("DefensiveHorse") and choices:match("2") then return "2"
			elseif card:isKindOf("OffensiveHorse") and choices:match("3") then return "3"
			end
		end
		if self:doDisCard(who,"e") then
			if choices:match("3") then return "3" end
			if choices:match("1") then return "1" end
			if choices:match("2") then return "2" end
			if choices:match("0") then return "0" end
		end
	end
end

sgs.ai_skill_choice.kuangfu = function(self,choices)
	return "move"
end

sgs.ai_fill_skill.heg_qingcheng = function(self, inclusive)
	local equipcard
	if self:needToThrowArmor() then
		equipcard = self.player:getArmor()
	else
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("EquipCard") then
				equipcard = card
				break
			end
		end
		if not equipcard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not card:isKindOf("DefensiveHorse") then
					equipcard = card
				end
			end
		end
	end

	if equipcard then
		local card_id = equipcard:getEffectiveId()
		local qc_card = hegemonyV2Card("heg_qingcheng", card_id)

		assert(qc_card)

		return qc_card
	end
end

sgs.ai_skill_use_func.heg_qingcheng = function(card, use, self)
    local slash = sgs.cloneCard("slash")
    local dummy_use = {isDummy = true, to = sgs.SPlayerList()}
    self:useBasicCard(slash, dummy_use)
    if not dummy_use.card then return end
    for _, target in sgs.qlist(dummy_use.to) do
        if self:isEnemy(target) and target:hasShownAllGenerals() then
            for _, name in ipairs(sgs.masochism_skill:split("|")) do
                if target:hasShownSkill(name) then
                    local head = target:inHeadSkills(name)
                    local general = head and target:getGeneral() or target:getGeneral2()
                    if general and not (head and target:isLord()) and not general:objectName():match("sujiang") then
                        use.card = card
                        if use.to then use.to:append(target) end
                        if not use.isDummy then self.heg_qingcheng_general = general:objectName() end
                        return
                    end
                end
            end
        end
    end
end

sgs.ai_general_choice.heg_qingcheng = function(self, generals)
    local preferred = self.heg_qingcheng_general
    self.heg_qingcheng_general = nil
    if preferred and table.contains(generals, preferred) then return preferred end
    return generals[1]
end

sgs.ai_use_value.heg_qingcheng = 6
sgs.ai_use_priority.heg_qingcheng = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention.heg_qingcheng = 100

sgs.ai_fill_skill.heg_huoshui = function(self)
	if not hegemonyWillShow(self) or self.player:hasShownSkill(sgs.Sanguosha:getSkill("heg_huoshui")) then return nil end
	local card = hegemonyV2Card("heg_huoshui")
	assert(card)
	return card
end
function sgs.ai_skill_use_func.heg_huoshui(card, use, self)
	use.card = card
end

sgs.ai_use_priority.heg_huoshui = 10

sgs.ai_skill_invoke.cv_caopi = function(self,data)
	if math.random(0,2)==0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_zhugeliang = function(self,data)
	if math.random(0,2)>0 then return false end
	if math.random(0,4)==0 then sgs.ai_skill_choice.cv_zhugeliang = "tw_zhugeliang" return true
	else sgs.ai_skill_choice.cv_zhugeliang = "heg_zhugeliang" return true end
end

sgs.ai_skill_invoke.cv_nos_huangyueying = function(self,data)
	if math.random(0,2)>0 then return false end
	if math.random(0,4)==0 then sgs.ai_skill_choice.cv_nos_huangyueying = "tw_huangyueying" return true
	else sgs.ai_skill_choice.cv_nos_huangyueying = "heg_huangyueying" return true end
end
