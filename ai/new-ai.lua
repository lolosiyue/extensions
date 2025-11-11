sgs.ai_skill_choice.luajuemou = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp() - 1 then return "luajuemouHp" end
	return "luajuemouCd"
end

sgs.ai_can_damagehp.luajuemou = function(self, from, card, to)
	return not (to:isWounded() or to:getMark("luajuemou") > 0)
		and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0 and self:canLoseHp(from,card,to)
end

sgs.ai_skill_playerchosen.lualilian = function(self, targets)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	local target = nil
	local n = 0
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "lualilian") then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") and hasManjuanEffect(enemy) then
						target = enemy
						break
					end
				end
			end
		else
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, n, "lualilian") and hasManjuanEffect(enemy) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") and self:hasSkills(sgs.priority_skill, enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.lualilian = function(self, from, to)
	local intention = 80
	if not self:toTurnOver(to, 0, "lualilian") then intention = -intention end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_need_damaged.lualilian = function(self, attacker, player)
	if not player:hasSkill("lualilian") then return false end
	local enemies = self:getEnemies(player)
	if #enemies < 1 then return false end
	self:sort(enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if player:getLostHp() < 1 and self:toTurnOver(enemy, 0, "lualilian") then
			return true
		end
	end
	local friends = self:getFriends(player, true)
	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if not self:toTurnOver(friend, 0, "lualilian") then return true end
	end
	return false
end

sgs.ai_skill_choice.lualilian = function(self, choice)
	local targets = self.room:getOtherPlayers(self.player)
	if targets:length() == 0 then return false end
	if sgs.ai_skill_playerchosen.lualilian(self, targets) ~= nil then
		return "luayihengturn"
	end
	return "luayihengmopai"
end


local lualveji_skill = {}
lualveji_skill.name = "lualveji_vs"
table.insert(sgs.ai_skills, lualveji_skill)
lualveji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#lualveji") then return end
	if #self.enemies == 0 then return end

	if self.player:hasSkill("luawu_trs") and (self.player:getMark("@luawu_mark") > 0) then
		local good, bad = 0, 0
		local lord = self.room:getLord()
		if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isWeak(player) then
				if self:isFriend(player) then
					bad = bad + 1
				else
					good = good + 1
				end
			end
		end
		if good == 0 then return end

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			local hp = math.max(player:getHp(), 1)
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end
			if self:isFriend(player) then
				good = good + math.max(getCardsNum("Peach", player), 1)
			else
				bad = bad + math.max(getCardsNum("Peach", player), 1)
			end

			local lost_value = 0
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end

		if good > bad then
			self.player:setFlags("should_luawu")
		end
	end



	if (self.player:getHp() > 3 and self.player:getHandcardNum() > self.player:getHp())
		or (self.player:getHp() - self.player:getHandcardNum() >= 2)
		or (self.player:getHp() > 1 and self.player:getRole() == "loyalist")
	then
		return sgs.Card_Parse("#lualveji:.:")
	end

	local function can_kurou_with_cb(self)
		if self.player:getHp() > 1 then return true end
		local has_save = false
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		if huatuo and self:isFriend(huatuo) then
			for _, equip in sgs.qlist(huatuo:getEquips()) do
				if equip:isRed() then
					has_save = true
					break
				end
			end
			if not has_save then has_save = (huatuo:getHandcardNum() > 3) end
		end
		if has_save then return true end
		local handang = self.room:findPlayerBySkillName("nosjiefan")
		if handang and self:isFriend(handang) and getCardsNum("Slash", handang, self.player) >= 1 then return true end
		return false
	end

	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if (self.player:hasWeapon("crossbow") or self:getCardsNum("Crossbow") > 0) or self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:slashIsEffective(slash, enemy)
				and self:isGoodTarget(enemy, self.enemies) and not self:slashProhibit(slash, enemy) and can_kurou_with_cb(self) then
				return sgs.Card_Parse("#lualveji:.:")
			end
		end
	end

	if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") + self:getCardsNum("Peach") > 1 then
		return sgs.Card_Parse("#lualveji:.:")
	end
end

sgs.ai_skill_use_func["#lualveji"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["lualveji"] = 6.7


sgs.ai_skill_askforag["lualveji"] = function(self, card_ids)
	if #card_ids == 1 then return card_ids[1] end
	local cards = {}
	local x = 0
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
		if (sgs.Sanguosha:getCard(card_id)):isBlack() then
			x = x + 1
		end
	end
	if x >= 2 then
		self.player:setFlags("AI_doInvoke_luawu")
	end
	if #card_ids > 0 then return self:askForAG(card_ids, false, "dummyreason") end
	return card_ids[1]
end

sgs.ai_skill_choice.lualveji = function(self, choice)
	if self.player:hasFlag("should_luawu") then
		if self.player:hasFlag("lualveji_vsblack") and self.player:hasFlag("AI_doInvoke_luawu") then
			return "lualvejiFZ"
		end
	end
	return "lualvejiQZ"
end




luawu_trs_skill = {}
luawu_trs_skill.name = "luawu_trs"
table.insert(sgs.ai_skills, luawu_trs_skill)
luawu_trs_skill.getTurnUseCard = function(self)
	if self.player:getMark("@luawu_mark") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return sgs.Card_Parse("#luawu:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end
		if self:isFriend(player) then
			good = good + math.max(getCardsNum("Peach", player), 1)
		else
			bad = bad + math.max(getCardsNum("Peach", player), 1)
		end

		local lost_value = 0
		local hp = math.max(player:getHp(), 1)
		if self:isFriend(player) then
			bad = bad + (lost_value + 1) / hp
		else
			good = good + (lost_value + 1) / hp
		end
	end

	if (good > bad) and ((self.player:hasFlag("should_luawu") and self.player:hasFlag("AI_doInvoke_luawu")) or (not self.player:hasSkill("lualveji_vs"))) then
		return sgs.Card_Parse("#luawu:.:")
	end
end

sgs.ai_skill_use_func["#luawu"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card["#luawu"] = true


sgs.ai_use_priority["luawu"] = 6.8


sgs.ai_skill_playerchosen.luafan = function(self, targets)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers()
		for _, aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return aplayer
			end
		end
	end

	self:updatePlayers()
	return self:findLeijiTarget(self.player, 100, nil, -1)
end

sgs.ai_playerchosen_intention.luafan = sgs.ai_playerchosen_intention.leiji

function SmartAI:SlashCanIgnoreJink(from, to, slash)
	from = from or self.room:getCurrent()
	to = to or self.player
	slash = slash or sgs.Sanguosha:cloneCard("slash")
	return not sgs.isJinkAvailable(from, to, slash) or from:hasSkill("wanglie")
end

function sgs.ai_slash_prohibit.luafan(self, from, to, card)
	local has_black_card = false
	for _, c in ipairs(sgs.QList2Table(to:getCards("he"))) do
		if c:getSuit() == sgs.Card_Spade then
			has_black_card = true
		end
	end

	if self:isFriend(to, from) and has_black_card then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end
	if from:hasSkill("tieji") then return false end
	local hcard = to:getHandcardNum()
	if from:hasSkill("liegong") and (hcard >= from:getHp() or hcard <= from:getAttackRange()) then return false end
	if from:hasSkill("kofliegong") and hcard >= from:getHp() then return false end
	if self:SlashCanIgnoreJink(from, to) then return false end

	if not self:getCardId("Jink", to) then
		if self:hasEightDiagramEffect(to) then
			if IgnoreArmor(from, to) then
				return false
			else
				return true
			end
		else
			return false
		end
	else
		return true
	end

	if from:getRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if sgs.ai_role[player:objectName()]== "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((from:getHp() >= 4 and (getCardsNum("Peach", from, self.player) > 0 or from:hasSkills("nosganglie|vsnosganglie"))) or from:hasSkill("hongyan")) then
			return false
		end
	end
	if getKnownCard(to, from, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) then return true end
	if to:getTreasure() and to:getPile("wooden_ox"):length() > 1 then return true end
end

sgs.ai_cardneed.luafan = sgs.ai_cardneed.leiji

sgs.ai_use_revises.luafan = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:getSuit() == sgs.Card_Spade and card:getNumber() <= 9 and card:getNumber() >= 2 and self:hasSkills(sgs.wizard_skill, self.player)
	then
		same = self:getSameEquip(card)
		if same and same:getSuit() == sgs.Card_Spade and same:getNumber() <= 9 and same:getNumber() >= 2
		then
			return false
		end
	end
end

sgs.ai_need_damaged.luaxumou = function(self, attacker, player)
	if not player:hasSkill("chanyuan") and player:hasSkill("luaxumou") and player:getMark("luaxumou") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 2 or player:getHp() == 2 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end

function sgs.ai_slash_prohibit.luaxumou(self, from, to, card)
	if sgs.turncount <= 1 and to:isLord() and to:getHp() >= 2 and not self:isFriend(to, from) then return true end
end

sgs.ai_view_as.luaqiyi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == card:getSuit() and #two_cards < 2 then
			--[[if not isCard("Jink", card, player) and not isCard("Peach", card, player)
			and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play)
			and not isCard("Jink", c, player) and not isCard("Peach", c, player)
			and not (isCard("ExNihilo", c, player) and player:getPhase() == sgs.Player_Play) then ]]
			table.insert(two_cards, c:getEffectiveId())
			--end
		end
	end


	if #two_cards == 2 and not card:isKindOf("Jink") then
		return ("jink:luaqiyi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2])
	end
end



sgs.ai_skill_cardask["@luaguidao"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and
		((not self.player:hasSkill("leiji") and not self.player:hasSkill("olleiji")) or judge.card:getSuit() ~= sgs.Card_Club)
		and sgs.ai_AOE_data and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and
		self:findLeijiTarget(self.player, 50)
		and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("nosleiji") then keptspade = 2 end
		if self.player:hasSkill("luafan") then keptspade = 2 end
		if self.player:hasSkill("leiji") then keptblack = 2 end
		if self.player:hasSkill("olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not self.player:hasSkill("olleiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("luafan") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end
function sgs.ai_cardneed.luaguidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart and self:hasSuit("heart", true, to)
			end
		end
	end
	if self:getFinalRetrial(to) == 1 then
		if to:hasSkill("nosleiji") then
			return card:getSuit() == sgs.Card_Spade
		end
		if to:hasSkill("leiji") then
			return card:isBlack()
		end
		if to:hasSkill("olleiji") then
			return card:isBlack()
		end
		if to:hasSkill("luafan") then
			return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9
		end
	end
end

sgs.ai_useto_revises.luaguidao = function(self, card, use, p)
	if card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
	then
		if self:isFriend(p) and p:getCardCount() > 2
		then
			use.card = card
			return
		end
		return false
	end
end
sgs.wizard_harm_skill =  sgs.wizard_harm_skill .. "|luaguidao"
sgs.wizard_skill =  sgs.wizard_skill .. "|luaguidao"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|luaguidao"


sgs.ai_skill_invoke.luajiejiang = function(self, data)
	if #self.enemies == 0 then
		return false
	end
	local targets = self.room:getOtherPlayers(self.player)
	local cardstr = sgs.ai_skill_use["@@luajiejiang"](self, "@luajiejiang")
	if (sgs.ai_skill_playerchosen.luajiejiang(self, targets) ~= nil) or (cardstr:match("->")) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.luajiejiang = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	local target = nil
	local n = 0

	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:toTurnOver(enemy, n, "luajiejiang") and hasManjuanEffect(enemy) then
			target = enemy
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:toTurnOver(enemy, n, "luajiejiang") and self:hasSkills(sgs.priority_skill, enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:toTurnOver(enemy, n, "luajiejiang") then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:faceUp() then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "luajiejiang") then
				target = friend
				break
			end
		end
	end

	return nil
end

sgs.ai_skill_use["@@luajiejiang"] = function(self, prompt)
	self:sort(self.enemies, "handcard_defense")
	local tuxi_mark = 2
	local targets = {}

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhijiangwei = self.room:findPlayerBySkillName("beifa")

	local add_player = function(player, isfriend)
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.playerRoles["rebel"] > 1 then
			return #
				targets
		end

		local f = false
		for _, c in ipairs(targets) do
			if c == player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets, player:objectName()) end

		if isfriend and isfriend == 1 then
			self.player:setFlags("luajiejiang_isfriend_" .. player:objectName())
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luajiejiang:.:->" .. s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount <= 1 and not lord:isNude() then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for _, friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			local judges = friend:getJudgingArea()
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					if add_player(friend, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and jiangwei:getHandcardNum() == 1
		and self:getEnemyNumBySeat(self.player, jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei, 1) == tuxi_mark then return parseTuxiCard() end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0)
		and dengai:hasSkill("zaoxian") and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
		else
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), zhugeliang:objectName())
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, luxun) > 0 then
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun, 1) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	if zhijiangwei and self:isFriend(zhijiangwei) and zhijiangwei:getHandcardNum() == 1 and
		self:getEnemyNumBySeat(self.player, zhijiangwei) <= (zhijiangwei:getHp() >= 3 and 1 or 0) then
		local isGood
		for _, enemy in ipairs(self.enemies) do
			local def = self:getDefenseSlash(enemy)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			local eff = self:slashIsEffective(slash, enemy, zhijiangwei) and
				self:isGoodTarget(enemy, self.enemies, slash)
			if zhijiangwei:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, zhijiangwei) and eff and def < 4 then
				isGood = true
			end
		end
		if isGood and add_player(zhijiangwei, 1) == tuxi_mark then return parseTuxiCard() end
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


	if luxun and add_player(luxun, (self:isFriend(luxun) and 1 or nil)) == tuxi_mark then
		return parseTuxiCard()
	end

	if dengai and self:isFriend(dengai) and dengai:hasSkill("zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
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

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luajiejiang"

sgs.ai_skill_cardchosen["luajiejiang2_main"] = function(self, who, flags)
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



local luamouce_skill = {}
luamouce_skill.name = "luamouce"
table.insert(sgs.ai_skills, luamouce_skill)
luamouce_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#luamouce") then
		return sgs.Card_Parse("#luamouce:.:")
	end
end

sgs.ai_skill_use_func["#luamouce"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() and self.player:canDiscard(enemy, "hej") and self:doDisCard(enemy, "hej") and not hasZhaxiangEffect(enemy) then
			target = enemy
			break
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luamouce"] = 7
sgs.ai_use_value["luamouce"] = 7
sgs.ai_card_intention["luamouce"] = 80



sgs.ai_skill_invoke.luaJC = function(self, data)
	if self.player:isLord() then return false end
	if self:getCardsNum("Peach") > 0 then
		return false
	end
	for _, friend in ipairs(self.friends_noself) do
		if getCardsNum("Peach", friend) > 0 then
			return false
		end
	end
	return true
end




sgs.ai_skill_playerchosen["ask_1"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target     = self:findPlayerToDraw(false, 2)
	if target then
		return target
	end
	return targetlist[1]
end

sgs.ai_skill_playerchosen["ask_2"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local lord       = self.room:getLord()
	if lord and self:isEnemy(lord) then
		return lord
	end
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	if #self.enemies > 0 then
		return self.enemies[1]
	end
	return targetlist[1]
end
function sgs.ai_cardneed.luaqinglong(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Blade") or (isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0)
	end
end


function sgs.ai_armor_value.luaqinglong(player, self, card)
	if card and card:isKindOf("Blade") then return 4 end
end

sgs.ai_use_revises.luaqinglong = function(self, card, use)
	if card and card:isKindOf("Weapon")
	then
		local same = self:getSameEquip(card)
		if same and same:isKindOf("Blade")
		then
			return false
		end
	end
end


sgs.ai_skill_invoke["@luaqibing"] = function(self, data)
	local use = data:toCardUse()
	local card = use.card
	if card:isKindOf("EquipCard") then
		return false
	end
	return true
end

sgs.ai_skill_invoke["luaqibing"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end


	return true
end

sgs.ai_ajustdamage_from.luaqibing = function(self, from, to, card, nature)
	if from:getPile("luaqibingcards"):length() > 0 and not beFriend(to, from) and card and card:isKindOf("Slash")
	then
		return 1
	end
end
sgs.ai_cardneed.luaqibing = sgs.ai_cardneed.slash

sgs.ai_skill_invoke["luazhenshe"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local enemy_max_card = self:getMaxCard(target)
	local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
	if (max_point > enemy_max_point) or target:isKongcheng() then
		return true
	end
	if self.player:getLostHp() + 1 >= 2 or not self.player:faceUp() then
		return true
	end
	return false
end

sgs.ai_cardneed.luazhenshe = sgs.ai_cardneed.bignumber

sgs.ai_need_damaged.luajilue = sgs.ai_need_damaged.fangzhu

sgs.ai_can_damagehp.luajilue = sgs.ai_can_damagehp.jieming

sgs.ai_skill_choice.luajilue = function(self, choice)
	local data = self.room:getTag("CurrentDamageStruct")
	local targets = self.room:getOtherPlayers(self.player)
	if (sgs.ai_skill_playerchosen.fangzhu(self, targets) ~= nil) then
		return "c3"
	end
	if (sgs.ai_skill_playerchosen.jieming(self, targets) ~= nil) then
		return "c2"
	end

	if (sgs.ai_skill_invoke.fankui(self, sgs.QVariant(data:toDamage().from))) then
		return "c1"
	end
	return "c4"
end



luahuntian_skill = {}
luahuntian_skill.name = "luahuntian"
table.insert(sgs.ai_skills, luahuntian_skill)
luahuntian_skill.getTurnUseCard      = function(self, inclusive)
	if self.player:hasUsed("#luahuntian") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#luahuntian:.:")
end

sgs.ai_skill_use_func["#luahuntian"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Spade and #needed < 5 then
			table.insert(needed, acard:getEffectiveId())
			if #needed == 5 then
				break
			end
		end
	end
	if targets and needed and #needed == 5 then
		use.card = sgs.Card_Parse("#luahuntian:" .. table.concat(needed, "+") .. ":")
		use.to = targets
		return
	end
end

sgs.ai_use_value["luahuntian"]       = 10
sgs.ai_use_priority["luahuntian"]    = 9
sgs.ai_card_intention["luahuntian"]  = 60


sgs.ai_skill_invoke["luajiaodi"] = function(self, data)
	return true
end

luafentian_skill = {}
luafentian_skill.name = "luafentian"
table.insert(sgs.ai_skills, luafentian_skill)
luafentian_skill.getTurnUseCard      = function(self, inclusive)
	if self.player:hasUsed("#luafentian") then return end
	if #self.enemies < 1 then return end
	if self.player:getMark("@fentian_mark") == 0 then return end
	return sgs.Card_Parse("#luafentian:.:")
end

sgs.ai_skill_use_func["#luafentian"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Spade and #needed < 1 then
			table.insert(needed, acard:getEffectiveId())
			if #needed == 1 then
				break
			end
		end
	end
	if targets and needed and #needed == 1 then
		use.card = sgs.Card_Parse("#luafentian:" .. table.concat(needed, "+") .. ":")
		use.to = targets
		return
	end
end

sgs.ai_use_value["luafentian"]       = 10
sgs.ai_use_priority["luafentian"]    = 9
sgs.ai_card_intention["luafentian"]  = 60


sgs.ai_skill_playerchosen["@luageipai2"] = function(self, targets)
	return self.player
end


local luajice_skill = {}
luajice_skill.name = "luajice"
table.insert(sgs.ai_skills, luajice_skill)
luajice_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#luajice") and not self.player:getPile("Plianji"):isEmpty() then
		return sgs.Card_Parse("#luajice:.:")
	end
end

sgs.ai_skill_use_func["#luajice"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true) then
			target = enemy
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self:doDisCard(enemy, "h", true)  then
				target = enemy
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luajice"] = 7
sgs.ai_use_value["luajice"] = 7
sgs.ai_card_intention["luajice"] = 80

sgs.ai_skill_invoke["lualianji"] = function(self, data)
	return true
end
