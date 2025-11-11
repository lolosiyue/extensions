local luajuesii_skill = {}
luajuesii_skill.name = "luajuesii"
table.insert(sgs.ai_skills, luajuesii_skill)
luajuesii_skill.getTurnUseCard = function(self, inclusive)
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end
		
	if not self.player:isWounded() then return end

	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp() > 3 and self.player:getLostHp() <= losthp)
			or (self.player:getHp() - self.player:getHandcardNum() >= 2)) and target and not (isLord(self.player) and sgs.turncount <= 1) then
		return sgs.Card_Parse("#luajuesii:.:")
	end
	if self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1 then
		return sgs.Card_Parse("#luajuesii:.:")
	end

	--Suicide by NosKurou
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp() == 1 and self.player:getRole() ~= "lord" and self.player:getRole() ~= "renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role == "rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if self.player:getRole() == "rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if self.player:getRole() == "loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp() > nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getRole() == "rebel" and self.player:getHandcardNum() > 3 then to_death = false end
				if self.player:getRole() == "loyalist" and lord and lord:getCardCount(true) + 2 <= self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if to_death then
			self.player:setFlags("NosKurou_toDie")
			return sgs.Card_Parse("#luajuesii:.:")
		end
		self.player:setFlags("-NosKurou_toDie")
	end
end

sgs.ai_skill_use_func["#luajuesii"] = function(card, use, self)
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
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



sgs.ai_skill_choice.luajuesii = function(self, choices, data)
	if hasZhaxiangEffect(self.player) and self:getAllPeachNum() + self.player:getHp() > 0 then return "luajuesii2" end
	for _, friend in ipairs(self.friends) do
		if friend:hasSkills("tianxiang|ol_tianxiang") and (self.player:getHp() >= 3 or (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 and self.player:getHp() > 1)) then
			return "luajuesii2"
		end
	end
	if self.player:getMaxHp() >= self.player:getHp() + 2 then
		if self.player:getMaxHp() > 5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false) or self.player:hasSkills(sgs.need_maxhp_skill)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			local ls = sgs.fangquan_effect and self.room:findPlayerBySkillName("fangquan")
			if ls then
				sgs.fangquan_effect = false
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2, enemy_num - 1) or 1
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > least_hp) then
				return
				"luajuesii2"
			end
		end
		return "luajuesii1"
	else
		return "luajuesii2"
	end
end



sgs.ai_use_priority["luajuesii"] = 6.8



sgs.ai_skill_invoke["luatuxiex"] = function(self, data)
	local cardstr = sgs.ai_skill_use["@@luatuxiex"](self, "@luatuxiex")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			return true
		end
	end
	return false
end


sgs.ai_skill_use["@@luatuxiex"] = function(self, prompt)
	self:sort(self.enemies, "handcard_defense")
	local tuxi_mark = 1
	local targets = {}

	local add_player = function(player, isfriend)
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.playerRoles["rebel"] > 1 then return #targets end

		local f = false
		for _, c in ipairs(targets) do
			if c == player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets, player:objectName()) end

		if isfriend and isfriend == 1 then
			self.player:setFlags("tuxi_isfriend_" .. player:objectName())
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luatuxiex_card:.:->" .. s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount <= 1 and not lord:isKongcheng() then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic")) then
				if add_player(p) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark then return parseTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x == 1 and self:needKongcheng(p) then good_target = false end
		if x >= 2 and hasTuntianEffect(p, true) then good_target = false end
		if good_target and add_player(p) == tuxi_mark then return parseTuxiCard() end
	end


	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (hasTuntianEffect(other, true)) and add_player(other) == tuxi_mark then
			return parseTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (hasTuntianEffect(other, true)) and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parseTuxiCard()
end

sgs.ai_card_intention["luatuxiex"] = function(self, card, from, tos)
	local lord = getLord(self.player)
	local tuxi_lord = false
	if sgs.ai_role[from:objectName()] == "neutral" and sgs.ai_role[tos[1]:objectName()] == "neutral" and
		(not tos[2] or sgs.ai_role[tos[2]:objectName()] == "neutral") and lord and not lord:isKongcheng() and
		not (self:needKongcheng(lord) and lord:getHandcardNum() == 1) and
		self:hasLoseHandcardEffective(lord) and not (hasTuntianEffect(lord, true)) and from:aliveCount() >= 4 then
		sgs.updateIntention(from, lord, -80)
		return
	end
	if from:getState() == "online" then
		for _, to in ipairs(tos) do
			if self:needKongcheng(to)
				or (hasTuntianEffect(to, true)) then
			else
				sgs.updateIntention(from, to, 80)
			end
		end
	else
		for _, to in ipairs(tos) do
			if lord and to:objectName() == lord:objectName() then tuxi_lord = true end
			local intention = from:hasFlag("tuxi_isfriend_" .. to:objectName()) and -5 or 80
			sgs.updateIntention(from, to, intention)
		end
		if sgs.turncount == 1 and not tuxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount() > 2 then
			sgs.updateIntention(from, lord, -80)
		end
	end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luatuxiex"




sgs.ai_skill_choice["luaqingqi"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:isFriend(target) then
			local judges = target:getJudgingArea()
			if not judges:isEmpty() then
				for _, judge in sgs.qlist(judges) do
					if not judge:isKindOf("YanxiaoCard") then
						return "luaqingqi2"
					end
				end
			else
				if self.player:canSlash(target, slash) and not self:slashProhibit(slash, target)
					and self:slashIsEffective(slash, target) and self:needToLoseHp(target, self.player, slash) then
					return "luaqingqi1"
				end
			end
		else
			if self.player:canSlash(target, slash) and not self:slashProhibit(slash, target)
				and self:slashIsEffective(slash, target) and self:isGoodTarget(target, self.enemies, slash) then
				return "luaqingqi1"
			else
				return "luaqingqi2"
			end
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@luaqingqi"] = function(self, prompt)
	self:sort(self.enemies, "handcard_defense")
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then
			if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				return "#luaqingqi_card:.:->" .. enemy:objectName()
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		local judges = friend:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				if not judge:isKindOf("YanxiaoCard") then
					return "#luaqingqi_card:.:->" .. friend:objectName()
				end
			end
		end
	end
end




sgs.ai_skill_cardchosen["luaqingqi"] = function(self, who, flags)
	local equipments = sgs.QList2Table(who:getEquips())
	equipments = sgs.reverse(equipments)
	local handcards = sgs.QList2Table(who:getHandcards())
	if self:isFriend(who) then
		--SmartAI:askForCardChosen的判定區檢測
		if flags:match("j") and not who:containsTrick("YanxiaoCard") and not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getEffectiveId()
				elseif trick:isKindOf("Indulgence") then
					indulgence = trick:getEffectiveId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getEffectiveId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if who:getPile("wooden_ox"):length() > 0 then
			for _, e in ipairs(equipments) do
				if e:isKindOf("WoodenOx") then
					table.removeOne(equipments, e)
				end
			end
		end

		if who:hasArmorEffect("silver_lion") and who:isWounded() then
			return who:getArmor()
		end
		if who:getEquips():length() > 0 then
			if who:getHandcardNum() > 2 or (who:getHandcardNum() > 0 and who:getPile("wooden_ox"):length() > 0) then
				return handcards[1]
			else
				return equipments[1]
			end
		end
	end
	return nil
end





sgs.ai_skill_invoke.feijiangts = function(self, data)
	local target = data:toPlayer()
	if not target then
		return true
	end
	if self:isFriend(target) then
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and target:getHandcardNum() == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.feijiangts = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("feijiangtsTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and target:getHandcardNum() == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			sgs.updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and target:getHandcardNum() == 1 then intention = 0 end
			sgs.updateIntention(player, target, -intention)
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.feijiangts = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.double_slash_skill = sgs.double_slash_skill .."|xinwushuang"
xinwushuang_skill = { name = "xinwushuang" }
table.insert(sgs.ai_skills, xinwushuang_skill)
xinwushuang_skill.getTurnUseCard = function(self)
	self:updatePlayers()
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	if (self.player:isKongcheng()) then return end
	if (self.player:getMark("xinwushuang-SelfPlayClear") > 0 ) then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local use_cards = {}
	local x = 0
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(duel, enemy, self.player) and self:canAttack(enemy, self.player) and
			self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) then
			x = x + 1
		end
	end

	if self.player:getHandcardNum() > 1 then
		self:sortByUseValue(cards, true)
		for _, acard in ipairs(cards) do
			if not (acard:isKindOf("Peach")) and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Duel) and (x > #use_cards) then
				table.insert(use_cards, acard)
			end
		end
	end
	if #use_cards == 0 then return end
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
	for i = 1, #use_cards, 1 do
		duel:addSubcard(use_cards[i])
	end
	duel:setSkillName("xinwushuang")
	return duel
end
sgs.ai_use_priority.xinwushuang_skill = sgs.ai_use_priority.ExNihilo - 0.1



sgs.ai_skill_cardask["@xinwushuang-slash"] = function(self, data, pattern, target)
	local duel = data:toCardEffect().card
	if self.player:getPhase() == sgs.Player_Play then return self:getCardId("Slash") end

	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end

	--有大傷害全部殺都丟出去
	if self:hasHeavyDamage(target, duel, self.player) then return self:getCardId("Slash") end

	if self.player:hasFlag("AIGlobal_NeedToWake") and self.player:getHp() > 1 then return "." end
	if (target:hasSkill("wuyan") or self.player:hasSkill("wuyan")) and not target:hasSkill("jueqing") then return "." end
	if self.player:getMark("@fenyong") > 0 and self.player:hasSkill("fenyong") and not target:hasSkill("jueqing") then
		return
		"."
	end
	if self.player:hasSkill("wuhun") and self:isEnemy(target) and target:isLord() and #self.friends_noself > 0 then
		return
		"."
	end

	--排除司馬徽隱士技能，AI司馬徽被打
	if target and self.player:hasSkill("yinshi") and not target:hasSkill("jueqing") and self.player:getMark("@dragon") + self.player:getMark("@phoenix") == 0 and not self.player:getArmor() then
		return
		"."
	end
	--排除TW馬良白眉，TW馬良被打
	if target and self.player:hasSkill("twyj_baimei") and not target:hasSkill("jueqing") and self.player:isKongcheng() then
		return
		"."
	end


	if self:cantbeHurt(target) then return "." end

	if self:isFriend(target) and target:hasSkill("rende") and self.player:hasSkill("jieming") then return "." end
	if self:isEnemy(target) and not self:isWeak() and self:cantbeHurt(target) then return "." end

	if self:isFriend(target) then
		if self:needToLoseHp(self.player, target) then return "." end
		if self:needToLoseHp(target, self.player) then
			return self:getCardId("Slash")
		else
			if target:isLord() and not sgs.isLordInDanger() and not sgs.isGoodHp(self.player) then
				return self:getCardId(
					"Slash")
			end
			if self.player:isLord() and sgs.isLordInDanger() then return self:getCardId("Slash") end
			return "."
		end
	end
	local x = data:toCardEffect().card:getSubcards():length()
	if (not self:isFriend(target) and (self:getCardsNum("Slash") >= ((getCardsNum("Slash", target, self.player) + 1) * (x - self.player:getMark("AI_xinwushuang-Clear")))) and x < 3)
		or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and not self.player:hasSkill("buqu"))

		--薛綜復難技能有殺能出就出
		or (self.player:hasSkill("funan") and self.player:getMark("@funan") > 0)
	then
		return self:getCardId("Slash")
	else
		return "."
	end
end






local luayuanlue_skill = {
	name = "luayuanlue",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#luayuanlue") then return end
		return sgs.Card_Parse("#luayuanlue:.:")
	end,
}
table.insert(sgs.ai_skills, luayuanlue_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#luayuanlue"] = function(card, use, self)
	self:updatePlayers()

	local acard = sgs.Card_Parse("#luayuanlue:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)

	local max = 0
	local min = 999
	local target

	self:sort(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		local x = 0
		if friend:getHandcardNum() > friend:getHp() then
			x = friend:getHandcardNum() - friend:getHp()
		end
		if (x > min) and x <= 2 and (getBestHp(friend) < friend:getHp()) then
			min = x
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			local x = 0
			if friend:getHandcardNum() < friend:getHp() then
				x = friend:getHp() - friend:getHandcardNum()
			end
			if (x > max) and x > 3 and not hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
				max = x
				target = friend
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if enemy:getHandcardNum() < enemy:getHp() then
				x = enemy:getHp() - enemy:getHandcardNum()
			end
			if (x < min) and (x < 2 or hasManjuanEffect(enemy)) and x > 0 and not hasZhaxiangEffect(enemy) then
				min = x
				target = enemy
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if enemy:getHandcardNum() > enemy:getHp() then
				x = enemy:getHandcardNum() - enemy:getHp()
			end
			if (x > max) and (x > 3) then
				max = x
				target = enemy
			end
		end
	end
	if target then
		use.card = acard
		if use.to then
			use.to:append(target) --填充卡牌使用结构体（to部分）
		end
		return
	end
end

sgs.ai_use_priority["luayuanlue"] = 3
sgs.ai_use_value["luayuanlue"] = 3

sgs.ai_cardneed.luajiezhi = sgs.ai_cardneed.slash
sgs.double_slash_skill = sgs.double_slash_skill .."|luajiezhi"

local luajiezhi_skill = {}
luajiezhi_skill.name = "luajiezhi"
table.insert(sgs.ai_skills, luajiezhi_skill)
luajiezhi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("luajiezhix") then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self.player:getMark("luajiezhiskill")):objectName(),
			c:getSuit(), c:getNumber())
		cardex:setSkillName("luajiezhi")
		cardex:deleteLater()
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not cardex:isKindOf("IronChain") then
			local name = sgs.Sanguosha:getCard(self.player:getMark("luajiezhiskill")):objectName()
			local new_card = sgs.Card_Parse((name .. ":luajiezhi[%s:%s]=%d"):format(c:getSuitString(),
				c:getNumberString(), c:getEffectiveId()))
			assert(new_card)
			return new_card
		end
	end
end


sgs.ai_cardneed.luafeiqi = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.luafeiqi = function(self, data)
	local target = data:toPlayer()
	if not target then
		return true
	end
	return self:doDisCard(target, "h")
end




sgs.ai_choicemade_filter.cardChosen.luafeiqi = sgs.ai_choicemade_filter.cardChosen.snatch




sgs.ai_skill_use["@@luazhuixi"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards, true)
	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
				assert(slash)
				local target
				self.player:setFlags("slashNoDistanceLimit")
				local dummy = self:aiUseCard(slash)
				self.player:setFlags("-slashNoDistanceLimit")
				if dummy.card and dummy.to then
					if not dummy.to:isEmpty() then
						for _, p in sgs.qlist(dummy.to) do
							if not self.player:inMyAttackRange(p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luazhuixi:" .. card:getEffectiveId() .. ":->" .. target:objectName()
				end
			end
		end
	end
end


sgs.ai_skill_discard.luaqingzhan = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	for _, acard in ipairs(cards) do
		if not (acard:isKindOf("Peach")) and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Slash) and #to_discard == 0 then
			table.insert(to_discard, acard:getEffectiveId())
			break
		end
	end
	if #to_discard == 0 then return end
	--table.insert(to_discard, cards[1]:getEffectiveId())

	return to_discard
end






sgs.ai_skill_use["@@luayonglue"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards, true)


	if self:needBear() then return "." end


	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and self.player:canDiscard(enemy, "he") then
			return "#luayonglue:.:->" .. enemy:objectName()
		end
	end
	for _, friend in ipairs(self.friends) do
		if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
			or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
			return "#luayonglue:.:->" .. friend:objectName()
		end
	end




	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
				assert(slash)
				local target
				self.player:setFlags("slashNoDistanceLimit")
				local dummy = self:aiUseCard(slash)
				self.player:setFlags("-slashNoDistanceLimit")
				if dummy.card and dummy.to then
					if not dummy.to:isEmpty() then
						for _, p in sgs.qlist(dummy.to) do
							if not self.player:inMyAttackRange(p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luayonglue:.:->" .. target:objectName()
				end
			end
		end
	end
end


sgs.ai_card_intention["#luayonglue"] = 80


sgs.ai_choicemade_filter.cardChosen.luayonglue = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_invoke.luamengxi = function(self, data)
	local target = data:toDamage().to
	if not self:isEnemy(target) then return false end
	if target:hasArmorEffect("silver_lion") then return false end
	if self:cantDamageMore(self.player, target) then return false end

	return true
end

sgs.ai_ajustdamage_from.luamengxi = function(self, from, to, card, nature)
	if from:getMark("&luasizhanjl") and not beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_playerchosen_intention.luazhonghun = -80

sgs.ai_skill_playerchosen.luazhonghun = function(self, targets)
	if self.player:getRole() == "loyalist" then
		return self.room:getLord()
	end

	self:sort(self.friends_noself, "hp")
	for _, p in ipairs(self.friends_noself) do
		if self:isWeak(p) then
			return p
		end
	end
end

sgs.ai_ajustdamage_to["&luazhonghun"] = function(self, from, to, card, nature)
	for _, p in sgs.list(self.room:getOtherPlayers(to)) do
		if to:getMark("&luazhonghun+to+#" .. p:objectName()) > 0
		then
			return self:ajustDamage(from, p, 0, card, nature)
		end
	end
end

sgs.ai_need_damaged["&luazhonghun"] = function(self, attacker, player)
	local victim
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if player:getMark("&luazhonghun+to+#" .. p:objectName()) > 0 then
			victim = p
			break
		end
	end
	if victim ~= nil then
		local role
		if isRolePredictable() and sgs.ai_role[player:objectName()] == "rebel" or self:compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
			role = "rebel"
		end
		local need_damage = false
		if (sgs.ai_role[player:objectName()] == "loyalist" or player:isLord()) and role == "rebel" then need_damage = true end
		if sgs.ai_role[player:objectName()] == "rebel" and role ~= "rebel" then need_damage = true end
		if sgs.ai_role[player:objectName()] == "renegade" then need_damage = true end
		if victim:isAlive() and need_damage then
			return victim:hasSkill("wuhun") and 2 or 1
		end
	end

	return false
end



sgs.ai_skill_invoke.luajuesheng = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and self:canDraw(target, self.player) then return true end

	return false
end

sgs.ai_choicemade_filter.skillInvoke.luajuesheng = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("luajueshengTarget") then
			target = p
			break
		end
	end
	if target then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, target, -40)
		end
	end
end



sgs.ai_skill_askforag["luaweiwo"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByKeepValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_use["@@luafuwei"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("h"))

	self:sortByUseValue(cards, true)

	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() <= self.player:getHandcardNum() then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. card:getEffectiveId() .. ":->" .. friend:objectName()
			end
		end
	end
	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))

	for _, player in ipairs(players) do
		if player:getHandcardNum() <= self.player:getHandcardNum() then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. card:getEffectiveId() .. ":->" .. player:objectName()
			end
		end
	end
end




sgs.ai_card_intention["#luafuweicard"] = -20

local luajieyi_skill = {}
luajieyi_skill.name = "luajieyi"
table.insert(sgs.ai_skills, luajieyi_skill)
luajieyi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luajieyicard") then return end
	local hurtF = 0

	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() then hurtF = hurtF + 1 end
	end

	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < getBestHp(p) and not p:isKongcheng() then hurtF = hurtF + 1 end
	end

	if hurtF > 0 then return sgs.Card_Parse("#luajieyicard:.:") end
	return
end

sgs.ai_skill_use_func["#luajieyicard"] = function(card, use, self)
	local targets = sgs.SPlayerList()

	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < getBestHp(p) and not p:isKongcheng() and targets:length() < 2 and not targets:contains(p) then
			targets:append(p)
		end
	end

	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and targets:length() < 2 and not targets:contains(p) then targets:append(p) end
	end

	if targets:length() == 0 then return end

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = nil
	for _, c in ipairs(handcards) do
		use_card = c
	end

	if (targets:length() > 0) and not (use_card == nil) then
		use.card = sgs.Card_Parse("#luajieyicard:" .. use_card:getEffectiveId() .. ":")
		if use.to then use.to = targets end
		return
	end
end





local luashanquan_skill = {}
luashanquan_skill.name = "luashanquan"
table.insert(sgs.ai_skills, luashanquan_skill)
luashanquan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#luashanquan") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#luashanquan:.:")
end
sgs.ai_skill_use_func["#luashanquan"] = function(card, use, self)
	local targets = {}
	local target
	self:sort(self.enemies, "defense")
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then
			if hasTuntianEffect(friend) and not friend:isKongcheng() then
				target = friend
				break
			end
			if friend:hasSkill("enyuan") and not friend:isKongcheng() then
				target = friend
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) and not enemy:isKongcheng() then
			target = enemy
			break
		end
		if not hasTuntianEffect(enemy) and not enemy:isKongcheng() then
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

sgs.ai_skill_discard["luashanquan"] = function(self, discard_num, optional, include_equip)
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

sgs.ai_target_revises.luaxiaomeng = function(to, card, self)
	if card:isKindOf("Slash")
	then
		return self.player:distanceTo(to) < 2
	end
end

--fail
--[[
local luagudan_skill={}
luagudan_skill.name="luagudan"
table.insert(sgs.ai_skills,luagudan_skill)
luagudan_skill.getTurnUseCard=function(self)

	local cards = self.player:getCards("e")
	cards = sgs.QList2Table(cards)
	
	local card
	self:sortByUseValue(cards, true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end

	for _, c in ipairs(cards) do
		if isCard("Slash", c, self.player) then
			return
		end
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
	for _, c in ipairs(cards) do
			if  c:isKindOf("EquipCard") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end


	for _, c in ipairs(cards) do
		if  (not isCard("Crossbow", c, self.player) and not disCrossbow)
			and (self:getUseValue(c) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0)
			and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			card = c
			break
		end
	end

	if nuzhan_equip then
		for _, c in ipairs(cards) do
			if  c:isKindOf("EquipCard") then
				card = c
				break
			end
		end
	end


	if card then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = ("slash:luagudan_dis[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end


	
	
	local has_weak_enemy = false
	for _,enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	
	if (self.player:isKongcheng()) then return end
	if not has_weak_enemy then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Slash") > 0
		or (self:getCardsNum("Analeptic") > 0 and self:isWeak())
		or (self:getCardsNum("Jink") > 0 and self:isWeak())
		or self:getCardsNum("SupplyShortage") > 0 or self:getCardsNum("Indulgence") > 0
		or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("SavageAssault") > 0
		then
			return
		end
	end
	
	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				if willUse(self, c:getClassName()) or c:isAvailable(self.player) then return end
			end
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:addSubcards(self.player:getHandcards())
	slash:setSkillName("luagudan_ex")
	return slash

end

]]

sgs.ai_view_as.luagudan = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip and card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using") then
		if class_name == "Jink" then
			return ("jink:luagudan[%s:%s]=%d"):format(suit, number, card_id)
		elseif class_name == "Slash" then
			return ("slash:luagudan_dis[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

function sgs.ai_cardsview_valuable.luagudan(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			local c = PatternsCard(class_name)
			c:setSkillName("luagudan_ex")
			c:addSubcards(player:getHandcards())
			return c:toString()
		end
	elseif class_name == "Jink" then
		local jinks = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Jink") then
				table.insert(jinks, c)
			end
		end
		if #jinks == 0 then
			local c = PatternsCard(class_name)
			c:setSkillName("luagudan_ex")
			c:addSubcards(player:getHandcards())
			return c:toString()
		end
	end
end


SelfUseCard = function(self, card)
	local dummy = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	if card:isKindOf("BasicCard")
	then
		self:useBasicCard(card, dummy)
	elseif card:isKindOf("TrickCard")
	then
		self:useTrickCard(card, dummy)
	elseif card:isKindOf("EquipCard")
	then
		self:useEquipCard(card, dummy)
	end
	if dummy.card
	then
		return dummy
	end
	self:useCardByClassName(card, dummy)
	return dummy
end

sgs.ai_use_revises.luagudan = function(self, card, use)
	if card:isKindOf("EquipCard")
	then
		local same = self:getSameEquip(card)
		if same then
			return false
		end
	end
end

local luagudan_skill = {}
luagudan_skill.name = "luagudan"
table.insert(sgs.ai_skills, luagudan_skill)
luagudan_skill.getTurnUseCard = function(self, inclusive)
	local cards = self:addHandPile("e")
	local equip_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") then
			equip_card = nil
		end
	end
	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		local card_str = ("slash:luagudan_dis[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end

	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				local dummy = self:aiUseCard(c)
				if dummy.card then
					return
				end
			end
		end
	end

	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:addSubcards(self.player:getHandcards())
	slash:setSkillName("luagudan_ex")
	local dummy = self:aiUseCard(slash)
	if dummy.card and dummy.to then
		return slash
	end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .."|luagudan"

function sgs.ai_cardneed.luagudan(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_skill_invoke.luachunl = function(self, data)
	local damage = data:toDamage()
	if damage.to and damage.to:hasSkill("luachunl") then
		if self:needToLoseHp(damage.to, damage.from, damage.card) then
			return false
		end
		return true
	elseif damage.from and damage.from:hasSkill("luachunl") then
		if self:isFriend(damage.to) then
			if self:needToLoseHp(damage.to, damage.from, damage.card) then
				return false
			end
			return true
		else
			if self:hasHeavyDamage(self.player, damage.card, damage.to) then return false end
			if self:isWeak(damage.to) then return false end
			if self:needToLoseHp(damage.to, damage.from, damage.card) then return true end
			if self:getDangerousCard(damage.to) then return true end
			return false
		end
	end
end


sgs.ai_skill_askforag["leo_luaboxue"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByKeepValue(to_obtain)
	self.room:setPlayerMark(self.player, "AI_leo_luaboxue1", 0)
	self.room:setPlayerMark(self.player, "AI_leo_luaboxue2", 0)
	self.room:setPlayerMark(self.player, "AI_leo_luaboxue3", 0)
	self.room:setPlayerMark(self.player, "AI_leo_luaboxue" .. tostring(to_obtain[1]:getTypeId()), 1)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_card_priority.leo_luaboxue = function(self, card, v)
	if self.player:getMark("AI_leo_luaboxue" .. tostring(card:getTypeId())) == 1
	then
		return 10
	end
end





sgs.ai_skill_use["@@luafanfu"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))

	self:sortByUseValue(cards)

	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))

	for _, player in ipairs(players) do
		if player:getKingdom() == self.player:getKingdom() then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			if self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player)
				and self:isGoodTarget(player, self.enemies, slash) then
				for _, card in ipairs(cards) do
					if not card:isKindOf("Peach") then
						return "#luafanfu:" .. card:getEffectiveId() .. ":->" .. player:objectName()
					end
				end
			end
		end
	end
	for _, player in ipairs(players) do
		if player:getKingdom() ~= self.player:getKingdom() then
			if self:isFriend(player) and self:canDraw(player, self.player) then
				for _, card in ipairs(cards) do
					if not card:isKindOf("Peach") then
						return "#luafanfu:" .. card:getEffectiveId() .. ":->" .. player:objectName()
					end
				end
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			if #self.friends_noself == 0 and self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player) then
				for _, card in ipairs(cards) do
					return "#luafanfu:" .. card:getEffectiveId() .. ":->" .. player:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_choice.luafanfu = function(self, choices, data)
	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local items = choices:split("+")
	for _, player in ipairs(players) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player)
			and self:isGoodTarget(player, self.enemies, slash) and table.contains(items, player:getKingdom()) then
			return player:getKingdom()
		end
	end
	return items[1]
end

sgs.ai_ajustdamage_to.luataohui = function(self, from, to, card, nature)
	if from and from:getHp() > to:getHp() and nature == sgs.DamageStruct_Normal
	then
		return -99
	end
end




sgs.ai_skill_playerchosen["@luadushi1"] = function(self, targets)
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and not lord:isKongcheng() then
		return lord
	end

	self:sort(self.enemies, "handcard")

	for _, p in ipairs(self.enemies) do
		if self:isWeak(p) and not p:isKongcheng() then
			return p
		end
	end
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			return p
		end
	end
end

sgs.ai_playerchosen_intention["@luadushi1"] = function(self, from, to)
	sgs.updateIntention(from, to, 50)
end

sgs.ai_skill_choice.luadushi = function(self, choices)
	local items = choices:split("+")
	local target = self.room:getTag("luadushi"):toPlayer()
	if target and (self:getDangerousCard(target) or self:isFriend(target)) and table.contains(items, "luadushi1") then
		return "luadushi1"
	end

	return "luadushi2"
end




sgs.ai_skill_invoke["luayijue_xianfu"] = function(self, data)
	if self.player:getRole() == "loyalist" then
		return true
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getRole() == p:getRole() then
			return true
		end
	end
	return false
end



sgs.ai_skill_playerchosen.luayijue = function(self, targets)
	if self.player:getRole() == "loyalist" or self.player:getRole() == "renegade" then
		return self.room:getLord()
	end

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getRole() == p:getRole() then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.luayijue = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end



sgs.ai_skill_invoke["luayijue"] = function(self, data)
	local pattern = data:toStringList()[1]
	local tied
	if pattern == "jink" then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getMark("luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if self:hasEightDiagramEffect(tied) then return true end
		return self:getCardsNum("Jink") == 0
	elseif pattern == "slash" then
		local asked = data:toStringList()
		local prompt = asked[2]
		if self:askForCard("slash", prompt, 1) == "." then return false end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getMark("luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if tied and tied:getPhase() ~= sgs.Player_NotActive
			and self:isFriend(tied) and self:getOverflow(tied) > 2 and not self:hasCrossbowEffect(tied) then
			return true
		end

		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if isCard("Slash", card, self.player) then
				return false
			end
		end
		return tied and self:isFriend(tied)
	end
end

sgs.ai_skill_cardask["luayijuejink"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Jink") or "."
end


sgs.ai_skill_cardask["luayijueslash"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Slash") or "."
end



sgs.ai_skill_cardask["luayijuepeach"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Peach") or "."
end

sgs.ai_cardneed.luazhiyong = function(to, card, self)
	return card and card:getSuit() == sgs.Card_Heart
end

sgs.luazhiyong_suit_value = {
	heart = 6,
}

sgs.ai_card_priority.luazhiyong = function(self,card)
	if card:getSkillName()=="luazhiyong"
	then
		if self.player:getPhase() ==sgs.Player_NotActive
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_revises.luazhiyong = function(self,card,use)
	if card:isKindOf("EquipCard")
	and card:getSuit() == sgs.Card_Heart
	then
		local same = self:getSameEquip(card)
		if same and same:getSuit() == sgs.Card_Heart
		then return false end
	end
end

local luazhiyong_skill = {}
luazhiyong_skill.name = "luazhiyong"
table.insert(sgs.ai_skills, luazhiyong_skill)
luazhiyong_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(handcards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(handcards, true)
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	self:sortByUseValue(equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local use_cards = {}



	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:getSuit() == sgs.Card_Heart then
				basic_cards_count = basic_cards_count + 1
				table.insert(basic_cards, c:getEffectiveId())
			end
		end
	end

	if self:getOverflow() <= 0 then return end


	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end


	if self.player:isWounded() then
		return sgs.Card_Parse("#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies) and self.player:inMyAttackRange(enemy) then
			local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
			thunder_slash:deleteLater()
			local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
			fire_slash:deleteLater()
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			if not self:slashProhibit(fire_slash, enemy, self.player) and self:slashIsEffective(fire_slash, enemy, self.player) then
				return sgs.Card_Parse("#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not self:slashProhibit(thunder_slash, enemy, self.player) and self:slashIsEffective(thunder_slash, enemy, self.player) then
				return sgs.Card_Parse("#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				return sgs.Card_Parse("#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
		end
	end
end

sgs.ai_skill_use_func["#luazhiyong"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local xin_zhayi_jibencard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	xin_zhayi_jibencard:setSkillName("luazhiyong")
	self:useBasicCard(xin_zhayi_jibencard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["luazhiyong"] = 3
sgs.ai_use_value["luazhiyong"] = 3

sgs.ai_view_as["luazhiyong"] = function(card, player, card_place, class_name)
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	if not player then return end
	local cards = player:getCards("h")
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local handcards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(handcards, sgs.Sanguosha:getCard(id))
		end
	end
	local basic_cards = {}
	local use_cards = {}


	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:getSuit() == sgs.Card_Heart then
				table.insert(basic_cards, c:getEffectiveId())
			end
		end
	end


	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end
	return (name .. ":luazhiyong[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
end

function sgs.ai_cardsview_valuable.luayijuedest(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Peach" and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	if player:hasFlag("Global_luayijueFailed") then return end
	if player:hasFlag("Global_luayijueFailed_AI") then return end
	local guanyu = self.room:findPlayerBySkillName("luayijue")
	if guanyu then return "#luayijuedestCard:.:"..name end
end

sgs.ai_skill_cardask["@@luayijue"] = function(self, data, pattern)
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



sgs.ai_skill_askforag["luaweiwo1"] = function(self,card_ids)
	local cards = Ids2Cards(card_ids)
	self:sortByUseValue(cards,true)
	return cards[1]:getId()
end
sgs.ai_skill_playerchosen["@luaspbazhen1"] = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _,target in ipairs(targets) do
        if self:doDisCard(target, "he", true) then
            return target
        end
    end
    return targets[1]
end

sgs.ai_skill_use["@@luaspbazhen"] = function(self, prompt, method)
	local use_card = sgs.Sanguosha:cloneCard("IronChain", sgs.Card_NoSuit, -1)
	use_card:setSkillName("luaspbazhen")
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end



sgs.ai_skill_playerchosen["@luaspbazhen3"] = function(self, targets)
    return self.player
end


sgs.ai_skill_playerchosen["@luaspbazhen4"] = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local fire_attack = sgs.Sanguosha:cloneCard("fire_attack",sgs.Card_NoSuit,0)
    fire_attack:setSkillName("luaspbazhen")
    fire_attack:deleteLater()
    local dummy_use = self:aiUseCard(fire_attack, dummy())
    if dummy_use.card and not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets, p) then
                return p
            end
        end
    end
	return targets[1]
end

sgs.ai_skill_askforag["newluaweiwo"] = function(self, card_ids)
	local judge = self.room:getTag("newluaweiwo"):toJudge()
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	
	if judge then
		local x = math.min(self.player:getHp(), 3) - self.player:getMark("newluaweiwo")
		if x > 0 then
			self:sortByKeepValue(to_obtain, true)
			return to_obtain[1]:getEffectiveId()
		else
			local card_id = self:getRetrialCardId(to_obtain, judge)
			if card_id ~= -1 then
				return "$" .. card_id
			end
		end
	end
	self:sortByKeepValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end
sgs.ai_skill_playerchosen["luajincui"] = function(self, targets)
	return self.player
end
sgs.ai_playerchosen_intention.luajincui = -50


sgs.ai_skill_choice.luajincui = function(self,choices,data)
	for _,friend in ipairs(self.friends)do
		if friend:hasSkill("tianxiang") and (self.player:getHp()>=3 or (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 and self.player:getHp()>1)) then
			return "luajincui1"
		end
	end
	if self.player:getMaxHp()>=self.player:getHp()+2 then
		if self.player:getMaxHp()>5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _,p in ipairs(self.enemies)do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num+1 end
			end
			local ls = sgs.fangquan_effect and self.room:findPlayerBySkillName("fangquan")
			if ls then
				sgs.fangquan_effect = false
				enemy_num = self:getEnemyNumBySeat(ls,self.player,self.player)
			end
			local least_hp = isLord(self.player) and math.max(2,enemy_num-1) or 1
			if (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")+self.player:getHp()>least_hp) then return "luajincui1" end
		end
		return "luajincui2"
	else
		return "luajincui1"
	end
end

