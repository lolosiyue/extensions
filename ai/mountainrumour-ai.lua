
function sgs.getCardNeedPlayerFromCertainPlayers(self, players, cards)
	cards = cards or sgs.QList2Table(self.player:getHandcards())
	local cardtogivespecial = {}
	local specialnum = 0
	local keptslash = 0
	local friends = {}

	local cmpByAction = function(a, b)
		return a:getRoom():getFront(a, b):objectName() == a:objectName()
	end
	local cmpByNumber = function(a, b)
		return a:getNumber() > b:getNumber()
	end

	for _, player in ipairs(players) do
		local exclude = self:needKongcheng(player) or self:willSkipPlayPhase(player)
		if self:hasSkills("keji|qiaobian|shensu", player) or player:getHp() - player:getHandcardNum() >= 3
			or (player:isLord() and self:isWeak(player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
			exclude = false
		end
		if self:objectiveLevel(player) <= -2 and not (player:hasSkill("manjuan") and self.room:getCurrent() ~= player) and not exclude then
			table.insert(friends, player)
		end
	end

	-- special move between nos_liubei and xunyu and huatuo
	for _, player in ipairs(friends) do
		if player:hasSkill("jieming") or player:hasSkill("jijiu") then
			specialnum = specialnum + 1
		end
	end
	if specialnum > 1 and #cardtogivespecial == 0 and self.player:hasSkill("nosrende") and self.player:getPhase() == sgs.Player_Play then
		local xunyu = self.room:findPlayerBySkillName("jieming")
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		local no_distance = self.slash_distance_limit
		local redcardnum = 0
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then
				if self.player:canSlash(xunyu, nil, not no_distance) and self:slashIsEffective(acard, xunyu) then
					keptslash = keptslash + 1
				end
				if keptslash > 0 then
					table.insert(cardtogivespecial, acard)
				end
			elseif isCard("Duel", acard, self.player) then
				table.insert(cardtogivespecial, acard)
			end
		end
		for _, hcard in ipairs(cardtogivespecial) do
			if hcard:isRed() then redcardnum = redcardnum + 1 end
		end
		if self.player:getHandcardNum() > #cardtogivespecial and redcardnum > 0 then
			for _, hcard in ipairs(cardtogivespecial) do
				if hcard:isRed() then return hcard, huatuo end
				return hcard, xunyu
			end
		end
	end

	-- keep one jink
	local cardtogive = {}
	local keptjink = 0
	for _, acard in ipairs(cards) do
		if isCard("Jink", acard, self.player) and keptjink < 1 then
			keptjink = keptjink + 1
		else
			table.insert(cardtogive, acard)
		end
	end

	-- weak friend
	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
	if self:isWeak(friend) and friend:getHandcardNum() < 3 then
		for _, hcard in ipairs(cards) do
			if isCard("Peach", hcard, friend)
				or (isCard("Jink", hcard, friend) and self:getEnemyNumBySeat(self.player, friend) > 0)
				or isCard("Analeptic", hcard, friend) then
					return hcard, friend
				end
			end
		end
	end

	if (self.player:hasSkill("nosrende") and self.player:isWounded() and self.player:getMark("nosrende") < 2) then
		if (self.player:getHandcardNum() < 2 and self.player:getMark("nosrende") == 0) then return end

		if ((self.player:getHandcardNum() == 2 and self.player:getMark("nosrende") == 0) or
			(self.player:getHandcardNum() == 1 and self.player:getMark("nosrende") == 1)) and self:getOverflow() <= 0 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasWeapon("guding_blade")
					and (enemy:canSlash(self.player)
					or self:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
					return
				end
				if enemy:canSlash(self.player) and enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then return end
			end
		end
	end

	if (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:isWounded() and self.player:getMark("rende") < 2) then
		if (self.player:getHandcardNum() < 2 and self.player:getMark("rende") == 0) then return end

		if ((self.player:getHandcardNum() == 2 and self.player:getMark("rende") == 0) or
			(self.player:getHandcardNum() == 1 and self.player:getMark("rende") == 1)) and self:getOverflow() <= 0 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasWeapon("guding_blade")
					and (enemy:canSlash(self.player)
					or self:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
					return
				end
				if enemy:canSlash(self.player) and enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then return end
			end
		end
	end

	-- armor,DefensiveHorse
	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 and friend:faceUp() then
			for _, hcard in ipairs(cards) do
				if (hcard:isKindOf("Armor") and not friend:getArmor() and not self:hasSkills("yizhong|bazhen", friend))
					or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
					return hcard, friend
				end
			end
		end
	end

	-- jijiu, jieyin
	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if self:hasSkills("jijiu|jieyin", friend) and friend:getHandcardNum() < 4 then
			for _, hcard in ipairs(cards) do
				if (hcard:isRed() and friend:hasSkill("jijiu")) or friend:hasSkill("jieyin") then
					return hcard, friend
				end
			end
		end
	end

	--Crossbow
	for _, friend in ipairs(friends) do
		if self:hasSkills("longdan|wusheng|keji", friend) and not self:hasSkills("paoxiao", friend) and friend:getHandcardNum() >= 2 then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Crossbow") then
					return hcard, friend
				end
			end
		end
	end
	for _, friend in ipairs(friends) do
		if getKnownCard(friend, "Crossbow") then
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and self:isGoodTarget(p, self.enemies, nil) and friend:distanceTo(p) <= 1 then
					for _, hcard in ipairs(cards) do
						if isCard("Slash", hcard, friend) then
							return hcard, friend
						end
					end
				end
			end
		end
	end

	table.sort(friends, cmpByAction)
	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and self:isGoodTarget(p, self.enemies, nil) and friend:distanceTo(p) <= friend:getAttackRange() then
					can_slash = true
					break
				end
			end

			if not can_slash then
				for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
					if self:isEnemy(p) and self:isGoodTarget(p, self.enemies, nil) and friend:distanceTo(p) > friend:getAttackRange() then
						for _, hcard in ipairs(cardtogive) do
							if hcard:isKindOf("Weapon")
								and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0) and not friend:getWeapon() then
								return hcard, friend
							end
							if hcard:isKindOf("OffensiveHorse")
								and friend:distanceTo(p) <= friend:getAttackRange() + 1 and not friend:getOffensiveHorse() then
								return hcard, friend
							end
						end
					end
				end
			end
		end
	end

	table.sort(cardtogive, cmpByNumber)
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and friend:faceUp() then
			for _, hcard in ipairs(cardtogive) do
				for _, askill in sgs.qlist(friend:getVisibleSkillList()) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback) == "function" and callback(friend, hcard, self) then
						return hcard, friend
					end
				end
			end
		end
	end

	-- slash
	if self.role == "lord" and self.player:hasLordSkill("jijiang") then
		for _, friend in ipairs(friends) do
			if friend:getKingdom() == "shu" and friend:getHandcardNum() < 3 then
				for _, hcard in ipairs(cardtogive) do
					if isCard("Slash", hcard, friend) then
						return hcard, friend
					end
				end
			end
		end
	end

	-- kongcheng
	self:sort(self.enemies, "defense")
	if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self.enemies[1]:hasSkill("kongcheng") then
		local do_continue = false
		for _,p in ipairs(players) do
			if p:objectName() == self.enemies[1]:objectName() then
				do_continue = true
				break
			end
		end
		if do_continue then
			for _, acard in ipairs(cardtogive) do
				if acard:isKindOf("Lightning") or acard:isKindOf("Collateral") or (acard:isKindOf("Slash") and self.player:getPhase() == sgs.Player_Play)
					or acard:isKindOf("OffensiveHorse") or acard:isKindOf("Weapon") then
					return acard, self.enemies[1]
				end
			end
		end
	end

	self:sort(friends, "defense")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(players) do
			if not self:needKongcheng(friend) and not friend:hasSkill("manjuan") and not self:willSkipPlayPhase(friend)
					and (self:hasSkills(sgs.priority_skill, friend) or (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) > 2) then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
					return hcard, friend
				end
			end
		end
	end

	self:sort(friends, "handcard")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(players) do
			if not self:needKongcheng(friend) and not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) then
				if friend:getHandcardNum() <= 3
					and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3
						or (self.player:hasSkill("nosrende") and self.player:isWounded() and self.player:getMark("nosrende") < 2)
						or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:isWounded() and self.player:getMark("rende") < 2)) then
					return hcard, friend
				end
			end
		end
	end

	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(players) do
			if not self:needKongcheng(friend) and not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3
					or (self.player:hasSkill("rende") and self.player:isWounded() and self.player:usedTimes("RendeCard") < 2)) then
					return hcard, friend
				end
			end
		end
	end

	if #cards > 0 and ((self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:getMark("rende") < 2)
						or (self.player:hasSkill("nosrende") and self.player:getMark("nosrende") < 2)) then
		local need_rende = (sgs.playerRoles["rebel"] == 0 and sgs.playerRoles["loyalist"]  > 0 and self.player:isWounded())
							or (sgs.playerRoles["rebel"] > 0 and sgs.playerRoles["renegade"] > 0
								and sgs.playerRoles["loyalist"]  == 0 and self:isWeak())
		if need_rende then
			self:sort(players, "defense")
			self:sortByUseValue(cards, true)
			return cards[1], players[1]
		end
	end
end

function sgs.findPlayerToDrawFromCertainPlayers(players, drawnum, self)
	drawnum = drawnum or 1
	local friends = {}
	for _, player in ipairs(players) do
		if self:isFriend(player) and not (player:hasSkill("manjuan") and player:getPhase() == sgs.Player_NotActive)
			and not (player:hasSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	return nil
end



sgs.findTuxiTargetsFromCertainPlayers = function(self, players, target_num)
	self:sort(self.enemies, "handcard")
	local targets = {}

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")

	local add_player = function(player, isfriend)
		local included = false
		for _,p in ipairs(players) do
			if p:objectName() == player:objectName() then
				included = true
				break
			end
		end
		if not included then return #targets end
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.playerRoles["rebel"] > 1 then return #targets end
		if #targets == 0 then
			table.insert(targets, player)
		else
			local to_join = true
			for _,p in ipairs(targets) do
				if player:objectName() ~= p:objectName() then
					to_join = false
					break
				end
			end
			if to_join then
				table.insert(targets, player)
			end
		end
		if isfriend and isfriend == 1 then
			self.player:setFlags("AI_TuxiToFriend_" .. player:objectName())
		end
		return #targets
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount <= 1 and not lord:isKongcheng() then
		add_player(lord)
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and jiangwei:getHandcardNum()== 1
		and self:getEnemyNumBySeat(self.player, jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei, 1) == target_num then return targets end
	end
	if dengai and dengai:hasSkill("zaoxian") and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0)
		and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai, 1) == target_num then
		return targets
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang, 1) == target_num then return targets end
		else
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), zhugeliang:objectName())
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang, 1) == target_num then return targets end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, luxun) > 0 then
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun, 1) == target_num then return targets end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic")) then
				if add_player(p) == target_num then return targets end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == target_num then return targets end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x == 1 and self:hasSkills(sgs.need_kongcheng, p) then good_target = false end
		if x >= 2 and hasTuntianEffect(p, true) then good_target = false end
		if good_target and add_player(p) == target_num then return targets end
	end

	if luxun and add_player(luxun, (self:isFriend(luxun) and 1 or nil)) == target_num then
		return targets
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and add_player(dengai, 1) == target_num then
		return targets
	end

	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and hasTuntianEffect(other, true) and add_player(other) == target_num then
			return targets
		end
	end
	--[[
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not hasTuntianEffect(other, true) and add_player(other) > 0 and math.random(0, 5) <= 1 then
			return targets
		end
	end]]
	--targets = {players[1]} 

	return targets
end


function _aiPlayerChat(self, answers)
	local answer = answers[math.random(1, #answers)]
	self.player:speak(answer)
end

function aiPlayerChat(self, skillname)
	local a = skillname
	local b = {}
	if a == "fendao_1" then
		b = {"邓艾：我们一起去偷窥姜小薇洗澡吧咕嘿嘿。钟会滚粗。"}
	elseif a == "fendao_2" then
		b = {"钟会：警察叔叔就是这个人！→邓艾：纳尼？"}
	elseif a == "shitu" then
		b = {"我在二郎神身边打过工。", "猎物休走！（舔舌头）", "我的优点是方向感好。"}
	elseif a == "tuogu" then
		b = {"哥几个罩住啊！", "我爸给你们发工资为了啥啊都想想！"}
	elseif a == "bawang" then
		b = {"还没完呢！", "再来再来！", "爽不爽？:-D", "站住别跑！直接撂倒！"}
	elseif a == "zhaoxu" then
		b = {"想娶我家香香，要先接受老身的试♂♀炼", "奶一口。奶水足足的。"}
	elseif a == "caokong" then
		b = {"我需要目标"}
	elseif a == "huanying" then
		b = {"你是信啊还是信啊还是信啊？", "让我们来做一道选择题。"}
	elseif a == "mengzhu" then
		b = {"乡亲们都出来吧！皇军不抢粮食！", "那谁谁！把你的胖次交出来！"}
		
	--default
		
	else
		b 
			= {"看我的腻害！", "接受我的制裁吧！", "代表月亮消灭你！", "别看我只是一只羊~", "嘎啦嘎啦呜喵喵~", "咪啪~"}
	end
	_aiPlayerChat(self, b)
end
	








--邓艾钟会
--sgs.ai_chaofeng.luadengaizhonghui_fendao = -1

sgs.ai_skill_invoke.luatoudumr = function(self, data)
	return self.player:getHandcardNum() - 2 > self.player:getMaxCards()
end

sgs.ai_skill_choice.luatoudumr = function(self, choice)
	if self.player:getHp() > 1 and (self:getCardsNum("Peach") > 0 or self.player:hasSkill("jieyin") or self.player:hasSkill("qingnang") or hasZhaxiangEffect(self.player)) then return "toudu_dm" end
	return "toudu_dl"
end



sgs.ai_skill_use["@@luaxianhai"] = function(self, prompt, method)
	local others = self.room:getAlivePlayers()
	
	if self.player:isKongcheng() then return "." end
	
	local from_card = self.room:getTag(self.player:objectName().."xianhai_fromcard"):toCard()
	
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:getMark("xianhai_from") > 0 then
			source = player
			break
		end
	end
	self:sort(self.enemies, "defense")
	
	if source and (self:isFriend(source))  then return "." end

	local doXianhai = function(who)
	
		if from_card:isKindOf("Slash") or from_card:isKindOf("AcheryAttack") then
	
			if not self:isFriend(who) and who:hasSkill("leiji")
				and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
				and (getKnownCard(who, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
				return "."
			end
		
		end

		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and self.player:inMyAttackRange(who) then
				if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "#luaxianhaicard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
				elseif self:isEnemy(who) and self:hasTrickEffective(from_card, who, source) and (from_card:isKindOf("FireAttack") or (from_card:isKindOf("Snatch") or from_card:isKindOf("Dismantlement") or from_card:isKindOf("Duel"))) then
					return "#luaxianhaicard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
                else
					return "#luaxianhaicard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
				end
			end
		end
		
		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doXianhai(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doXianhai(player)
			if ret ~= "." then return ret end
		end
	end

	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)

	for _, friend in ipairs(self.friends_noself) do
		if from_card:isKindOf("Slash") and not self:slashIsEffective(from_card, friend) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doXianhai(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, from_card) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doXianhai(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	if (self:isWeak()  or self:hasHeavyDamage(source, from_card, self.player)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
		and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doXianhai(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if (self:isWeak() or self:hasHeavyDamage(source, from_card, self.player)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doXianhai(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end


sgs.ai_card_intention.luaxianhaicard = function(self, card, from, to)
	if not self:isWeak(from) then sgs.updateIntention(from, to[1], 50) end
end

function sgs.ai_slash_prohibit.liuxianhai(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:canSlash(friend, card) and self:slashIsEffective(card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.luaxianhai(to, card)
	return to:getCards("h"):length() <= 2 and isCard("Jink", card, to)
end

sgs.bad_skills = sgs.bad_skills .. "|luazhenggongmr"

sgs.ai_use_revises.luazhenggongmr = function(self, card, use)
	if self.player:getMark("fendao_used") == 0 and (card:isKindOf("Slash") or (card:isNDTrick() and not card:isKindOf("AOE"))) and self:getCardsNum(card:getName()) < 2  then
		return false
	end
end

sgs.ai_can_damagehp.luazhenggongmr = function(self, from, card, to)
	if to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return to:getLostHp() < 3 and to:getMark("fendao_used") == 0 
	end
end

sgs.ai_skill_cardask["@luazhenggongmr"] = function(self,data,pattern)
	local player = self.player
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
    	if sgs.Sanguosha:matchExpPattern(pattern,player,c)
		then return c:getEffectiveId() end
	end
    return "."
end

luafendao_skill = {}
luafendao_skill.name = "luafendao"
table.insert(sgs.ai_skills, luafendao_skill)
luafendao_skill.getTurnUseCard = function(self)
	if self.player:getMark("@fendao") <= 0 then return nil end
	if self.player:getMaxHp() < 5 then return nil end
	local card_str = ("#luafendaocard:.:")
	local card = sgs.Card_Parse(card_str)
	return card
end

sgs.ai_skill_use_func["#luafendaocard"] = function(card, use, self)
	if math.random(0,self.player:getLostHp())+sgs.turncount-1<=1 then return false end
	use.card = card
	return
end

sgs.ai_skill_choice.luafendaocard = function(self, choice)
	local rand = math.random(1, 3)
	if rand == 1 then
		aiPlayerChat(self, "fendao_1")
		return "luatoudumr"
	end
	aiPlayerChat(self, "fendao_2")
	return "luaxianhai"
end
	
sgs.ai_card_intention.luafendaocard = 99
sgs.ai_use_priority.luafendaocard = 9.9
	
	
--张颌
sgs.ai_chaofeng.luazhanghe_zhuiji = 1
	
luashitu_skill = {}
luashitu_skill.name = "luashitu"
table.insert(sgs.ai_skills, luashitu_skill)
luashitu_skill.getTurnUseCard = function(self)
	local will_use = false
	if self.player:hasUsed("#luashitucard") or self.player:isKongcheng() then
		return false
	elseif self.player:getMark("luazhuiji") == 0 then
		will_use = true
	else
		local others = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(others) do
			if self:isEnemy(self.player, p) and self:isGoodTarget(p, self.enemies, nil) then
				if self.player:canSlash(p) then
					will_use = false
					break
				elseif self.player:getAttackRange() + 1 == self.player:distanceTo(p) then
					if self:isGoodTarget(p, self.enemies, nil) and p:getDefensiveHorse() and self:getCardsNum("Slash") > 0 then
						will_use = true
					end
				end
			end
		end
	end
	if will_use then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if self.player:getMark("luazhuiji") == 0 or (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) then
				local card_str = ("#luashitucard:"..card:getEffectiveId()..":")
				local card = sgs.Card_Parse(card_str)
				return card
			end
		end
	end
	return nil
end

sgs.ai_skill_use_func["#luashitucard"] = function(card, use, self)
	use.card = card
	return
end

function sgs.ai_cardneed.luazhuiji(to, card)
	return card:isNDTrick() or card:isKindOf("Slash")
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|luazhuiji"

sgs.ai_use_priority.luashitucard = 8	
	
	
--姜维
sgs.ai_chaofeng.luajiangwei_qilin = 0

function sgs.ai_cardneed.luaqilin(to, card)
	return card:isKindOf("TrickCard")
end	
	
sgs.ai_skill_invoke.luadunjia = function(self, data)
	if self.player:getMark("luadunjia") > 0 then return true end
	return sgs.ai_skill_invoke.jushou(self, data)
end
	
sgs.ai_skill_choice.luadunjia = function(self, choice)
	aiPlayerChat(self)
	if self.player:getHp() == 1 then return "dunjiarecover" end
	if self.player:getHp() > self.player:getHandcardNum() then return "dunjiadraw" end
	return "dunjiarecover"
end
	
--刘禅
sgs.ai_chaofeng.lualiushan_fuyou = -4

sgs.ai_skill_invoke.luatuogu = function(self, data)	
	local damage = data:toDamage().damage
	if self.player:getHp() - damage <= 0 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then
		aiPlayerChat(self, "tuogu")
		return true
	end
end

sgs.ai_skill_choice.luatuogu = function(self, data)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("luatuogu_who") == 1 then
			target = p
			break
		end
	end
	if target and self:isEnemy(self.player, target) then return "tuogunonhelper" end
	
	local from
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("luatuogu_from") == 1 then
			from = p
			break
		end
	end
	
	
	self:sort(self.friends, "defense")
	local helper = self.friends[#self.friends]
	
	for _,p in ipairs(self.friends) do
		if self:needToLoseHp(p, from, nil) then
			helper = p
			break
		end
	end
	
	if helper and helper:objectName() == self.player:objectName() then
		return "tuoguhelper"
	end
	return "tuogunonhelper"
end


--孙策
sgs.ai_chaofeng.luasunce_bawang = 2

sgs.ai_skill_invoke.luabawang = function(self, data)
	local target
	local damage = data:toDamage()
	if damage then
		target = damage.to
	end
	local pindian = data:toPindian()
	if pindian then
		target = pindian.from
		if pindian.from:objectName() == self.player:objectName() then
			target = pindian.to
		end
	end
	if target and self:isEnemy(self.player, target) then
		if not self:needToLoseHp(target, self.player, nil) then
			aiPlayerChat(self, "bawang")
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.luabawang = function(self, discard_num, min_num, optional, include_equip)
	return nosganglie_discard(self, discard_num, min_num, optional, include_equip, "luabawang")
end

function sgs.ai_cardneed.luabawang(to, card)
	return card:isKindOf("Slash") or card:isKindOf("Duel")
end

sgs.ai_skill_cardask["@luajiebing"] = function(self, data)
	local asker
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("luajiebing") == 1 then
			asker = p
			break
		end
	end
	
	if asker and self:isEnemy(self.player, asker) then return "." end

	self:sort(self.friends, "defense")
	local helper = self.friends[#self.friends]
	for _,friend in ipairs(self.friends) do
		if self:needToThrowArmor(friend) or (self:hasSkills(sgs.lose_equip_skill, friend)
			or (hasTuntianEffect(friend, true) and friend:getPhase() == sgs.Player_NotActive)) then
			helper = friend
			break
		end
	end
	if self.player:objectName() == helper:objectName() then
		if self:needToThrowArmor(self.player) then
			local to_discard = self:askForDiscard("jiebing", 1, 1, false, true)
			if #to_discard > 0 then
				return to_discard[1]
			end
		end
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		return cards[#cards]:getEffectiveId()
	end
	return "."
end
	



--吴国太
sgs.ai_chaofeng.luawuguotai_tongtang = 5



sgs.ai_skill_askforag.luatongtang = function(self, card_ids)
	local cards = {}
	for _,i in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(i)
		table.insert(cards, card)
	end
	local players = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getKingdom() == "wu" then
			table.insert(players, p)
		end
	end
	local acard, friend = sgs.getCardNeedPlayerFromCertainPlayers(self, players, cards)
	if not acard then acard = cards[1] end
	if not friend then friend = self.player end
	local tag = sgs.QVariant()
	tag:setValue(friend)
	self.room:setTag("ai_sel_luatongtang", tag)
	return acard:getEffectiveId()
end

sgs.ai_skill_playerchosen.luatongtang = function(self, targets)
	local choice = self.room:getTag("ai_sel_luatongtang"):toPlayer()
	if not choice then choice = self.player end
	for _,p in sgs.qlist(targets) do
		if p:objectName() == choice:objectName() then
			return choice
		end
	end
	return targets[1]
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|luazhaoxu"

luazhaoxu_skill = {}
luazhaoxu_skill.name = "luazhaoxu"
table.insert(sgs.ai_skills, luazhaoxu_skill)
luazhaoxu_skill.getTurnUseCard = function(self)	
	local card_num = self.player:getHandcardNum()
	if card_num <= 1 then return nil end
	if self.player:hasUsed("#luazhaoxucard") then return nil end
	
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	
	self:sort(self.friends_noself, "defense")
	self:sort(self.enemies, "defense")
	
	local targets = {}
	
	local counts = card_num - 1
	
	for _,p in ipairs(self.friends_noself) do
		if p:isMale() and self:isWeak(p) then
			table.insert(targets, p)
			counts = counts - 1
		elseif p:isMale() and p:isWounded() and (self.player:getLostHp() > #targets or self.player:getMaxCards() < counts) then
			table.insert(targets, p)
			counts = counts - 1
		end
		if counts == 0 then break end
	end
	
	if #targets > 0 then
		
		local card_ids = {}
		
		for i=1,#targets+1 do
			table.insert(card_ids, cards[i]:getEffectiveId())
		end
		
		local target_names = {}
		
		for i=1,#targets do
			table.insert(target_names, targets[i]:objectName())
		end
		
		local card_str = ("#luazhaoxucard:"..table.concat(card_ids, "+")..":")--->"..table.concat(target_names, "+"))
		local card = sgs.Card_Parse(card_str)
		return card
	end
	return nil
end

sgs.ai_skill_use_func["#luazhaoxucard"] = function(card, use, self)
	use.card = card
	if use.to then
		self:sort(self.friends_noself, "defense")
	
		local counts = card:subcardsLength()
	
		for _,p in ipairs(self.friends_noself) do
			if p:isMale() and p:isWounded() then
				use.to:append(p)
				counts = counts - 1
			end
			if counts == 0 then break end
		end
	end
	return
end


sgs.ai_skill_choice.luazhaoxucard = function(self, data)
	aiPlayerChat(self, "zhaoxu")
	return "zhaoxurecoverhp"
end

sgs.ai_use_priority.luazhaoxucard = 3


--蔡文姬


sgs.ai_chaofeng.luacaiwenji_shushen = 0

sgs.ai_skill_use["@@luashushenmr"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	local equips = {}
	for _,c in sgs.qlist(cards) do
		if c:isKindOf("EquipCard") then
			table.insert(equips, c)
		end
	end
	if #equips == 0 then return "." end
	if not sgs.ai_skill_invoke.nosjushou(self, sgs.QVariant()) then return "." end
	local card_ids = {}
	for _,c in ipairs(equips) do
		if not self.player:getArmor() or self.player:getArmor():objectName() ~= c:objectName() or (c:objectName() == "silver_lion" and self.player:getLostHp() > 0)
			and (not self.player:getDefensiveHorse() or self.player:getDefensiveHorse():objectName() ~= c:objectName()) then
			table.insert(card_ids, c:getEffectiveId())
		end
	end
	if #card_ids ~= 0 then
		aiPlayerChat(self, "shushen")
		return "#luashushenmrcard:"..table.concat(card_ids, "+")..":"
	end
	return "."
end

function sgs.ai_cardneed.luashushenmr(to, card)
	return card:isKindOf("EquipCard")
end



local luahujiamr_skill = {}
luahujiamr_skill.name = "luahujiamr"
table.insert(sgs.ai_skills, luahujiamr_skill)
luahujiamr_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
	local blackslashes = {}
	local redslashes = {}
    for _,card in ipairs(cards) do 
		if card:isKindOf("Slash") and card:isBlack() then
			table.insert(blackslashes, card)
		elseif card:isKindOf("Slash") and card:isRed() then
			table.insert(redslashes, card)
		end
    end
    if #blackslashes < 2 and #redslashes < 2 then
		return nil 
	end
	local selected = {}
	local trick = ""
	if #blackslashes >= 2 then
		selected = blackslashes
	else
		selected = redslashes
	end
	self:sortByUseValue(selected, true)
    local card_str = ("savage_assault:luahujiamr[to_be_decided:0]=%d+%d"):format(selected[1]:getId(), selected[2]:getId())
    local new_card = sgs.Card_Parse(card_str)
    assert(new_card)
    return new_card
end


--左慈

sgs.ai_chaofeng.luazuoci_caokong = 0

sgs.ai_skill_cardask["@luahuanying"] = function(self, data)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if c:getSuitString() == "club" then
			return c:getEffectiveId()
		end
	end
	if #cards > 0 then
		return cards[1]:getEffectiveId()
	else
		return nil
	end
end

sgs.ai_skill_invoke.luahuanying = function(self, data)
	aiPlayerChat(self, "huanying")
	return true
end

sgs.ai_skill_askforag.luahuanying = function(self, card_ids)
	for _,i in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(i):getSuitString() == "club" then
			if math.random(1, 4) > 1 then
				return i
			end
		else
			if math.random(1, 4) == 1 then
				return i
			end
		end
	end
	return card_ids[1]
end

sgs.ai_skill_choice.luahuanying = function(self, choice)
	local from = self.room:getTag("huanying_target"):toPlayer()
	local damage = self.room:getTag("huanying_data"):toDamage()
	if from then
		if self:isFriend(from) then
			return "no_question"
		elseif damage and damage.damage > 1 then
			return "question"
		elseif self.player:getHp() > 2 or from:getHp() <= 1 then
			return "question"
		else
			if math.random(1, 2) == 1 then
				return "question"
			end
		end
	end
	return "no_question"
end

sgs.ai_skill_invoke.luacaokong = function(self, data)
	if data:toString() == "caokong_a" or data:toString() == "caokong_b" then
		local players = self.room:getOtherPlayers(self.player)
		players = sgs.QList2Table(players)
		local to_selects = sgs.findTuxiTargetsFromCertainPlayers(self, players, 3)
		if to_selects == {} then return false end
		local current_targets = self.room:getTag("caokong_tos"):toCardUse()
		for _,p in ipairs(to_selects) do
			if not current_targets or not current_targets.to
				or not current_targets.to:contains(p) then
				return true
			end
		end
		return false
	else
		local card = self.room:getTag("caokong_carduse"):toCard()
		if not card:isKindOf("AOE") and not card:isKindOf("GlobalEffect") then 
			return true
		else
			if card:isKindOf("AOE") and self:getAoeValue(card) then
				return true
			end
		end
		local use = self:aiUseCard(card, dummy())
		if use.card then 
			return true
		end
		return false
	end
	
end
sgs.ai_skill_playerchosen.luacaokong = function(self, targets)
	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)
	local to_selects = sgs.findTuxiTargetsFromCertainPlayers(self, players, 3)
	local current_targets = self.room:getTag("caokong_tos"):toCardUse()
	for _,p in ipairs(to_selects) do
		if targets:contains(p)  then
			if not current_targets or not current_targets.to
			or not current_targets.to:contains(p) then
				return p
			end
		end
	end
	return targets:first()
end
sgs.ai_skill_use["@@luacaokong"] = function(self, prompt)
	local card = self.room:getTag("caokong_carduse"):toCard()
	local use = self:aiUseCard(card, dummy())
	if not use.card then 
		aiPlayerChat(self, "caokong")
		return "." 
	end	
	local targets = {}
	if use.card and use.to and not use.to:isEmpty() then
		for _,p in sgs.qlist(use.to) do
			table.insert(targets, p:objectName())
		end
	end
	local parse = string.format(card:objectName()..":luacaokong[%s:%s]=%d", card:getSuit(), card:getNumber(), card:getEffectiveId())
	if #targets > 0 then
		parse = parse.."->"..table.concat(targets, "+")
	end
	return parse
end

sgs.ai_can_damagehp.luacaokong = function(self, from, card, to)
	if from and self:isEnemy(from) and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return to:getMark("luacaokong") == 0 and to:hasSkills("luahuanying") and to:getPile("huanyingpile"):length() > 0
	end
end




	

--神袁绍
sgs.ai_chaofeng.luashenyuanshao_mengzhu = 6

sgs.ai_skill_invoke.luamengzhu = function(self, data)
	local f_data = sgs.QVariant()
	local damage = sgs.DamageStruct()
	damage.to = self.player
	damage.damage = 1
	f_data:setValue(damage)
	if sgs.ai_skill_invoke.guixin(self, data) then
		aiPlayerChat(self, "mengzhu")
		return true
	end
	return false
end

--shisheng-select
for i=1,10 do
	addAiSkills("shisheng"..i).getTurnUseCard = function(self)
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			poi:deleteLater()
			if poi:isAvailable(self.player) then
				table.insert(choices, name)
			end
		end

		if next(choices) and self.player:getMark("AI_do_not_invoke_shisheng".. i .. "-Clear") == 0 and self.player:getMark("AI_do_not_invoke_shisheng-Clear") == 0 then
			local markcost = 0
			if i <= 2 then
				markcost = 0
			elseif i <= 6 then
				markcost = 1
			elseif i <= 9 then
				markcost = 2
			else
				markcost = 3
			end
			if self.player:getMark("@wins") < markcost then return end
			local cost = 0
			if i <= 2 then
				cost = 1
			elseif i <= 5 then
				cost = 2
			elseif i == 6 then
				cost = 3
			elseif i <= 9 then
				cost = 1
			else
				cost = 0
			end
			local use_cards = {}
			for _,c in sgs.list(cards)do
				if #use_cards >= cost then break end
				if c:getNumber() == 5 and i == 1 then
					table.insert(use_cards, c:getEffectiveId())
				elseif c:getNumber() == 10 and i == 2 then
					table.insert(use_cards, c:getEffectiveId())
				elseif i == 3 then
					for _,c2 in sgs.list(cards)do
						if c:getNumber() == c2:getNumber() and c:getSuit() == c2:getSuit() and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
							table.insert(use_cards, c:getEffectiveId())
							table.insert(use_cards, c2:getEffectiveId())
							break
						end
					end
				elseif i == 4 then
					for _,c2 in sgs.list(cards)do
						if c:getNumber() == c2:getNumber() and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
							table.insert(use_cards, c:getEffectiveId())
							table.insert(use_cards, c2:getEffectiveId())
							break
						end
					end
				elseif i == 5 then
					for _,c2 in sgs.list(cards)do
						if c:getSuit() == c2:getSuit() and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
							table.insert(use_cards, c:getEffectiveId())
							table.insert(use_cards, c2:getEffectiveId())
							break
						end
					end
				elseif i == 6 then
					table.insert(use_cards, c:getEffectiveId())
				elseif c:isKindOf("TrickCard") and i == 7 then
					table.insert(use_cards, c:getEffectiveId())
				elseif c:isKindOf("EquipCard") and i == 8 then
					table.insert(use_cards, c:getEffectiveId())
				elseif c:isKindOf("BasicCard") and i == 9 then
					table.insert(use_cards, c:getEffectiveId())
				end
			end
			if #use_cards == 0 then return end
			if #use_cards == cost then 
				return sgs.Card_Parse("#shisheng_sc".. i ..":".. table.concat(use_cards, "+") ..":")
			end
		end
	end
end

for i=1,10 do
	sgs.ai_skill_use_func["#shisheng_sc"..i] = function(card,use,self)
		use.card = card
		self.room:setPlayerMark(self.player, "shisheng", i)
	end
end

sgs.ai_skill_use["@@shisheng"] = function(self, prompt, method)
	local pattern = self.player:property("shisheng_sel"):toString()
	if pattern ~= "" then
		local x = self.player:getMark("shisheng")
		self.room:setPlayerMark(self.player, "shisheng", 0)
		if x > 0 then
			local markcost = 0
			if x <= 2 then
				markcost = 0
			elseif x <= 6 then
				markcost = 1
			elseif x <= 9 then
				markcost = 2
			else
				markcost = 3
			end
			if self.player:getMark("@wins") >= markcost then 
				local use_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
				use_card:setSkillName("shisheng")
				local cost = 0
				if x <= 2 then
					cost = 1
				elseif x <= 5 then
					cost = 2
				elseif x == 6 then
					cost = 3
				elseif x <= 9 then
					cost = 1
				else
					cost = 0
				end
				local cards = sgs.QList2Table(self.player:getCards("he"))
				self:sortByKeepValue(cards)
				local use_cards = {}
				for _,c in sgs.list(cards)do
					if #use_cards >= cost then break end
					if c:getNumber() == 5 and x == 1 then
						table.insert(use_cards, c:getEffectiveId())
					elseif c:getNumber() == 10 and x == 2 then
						table.insert(use_cards, c:getEffectiveId())
					elseif x == 3 then
						for _,c2 in sgs.list(cards)do
							if c:getNumber() == c2:getNumber() and c:getSuit() == c2:getSuit() and c~=c2 and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
								table.insert(use_cards, c:getEffectiveId())
								table.insert(use_cards, c2:getEffectiveId())
								break
							end
						end
					elseif x == 4 then
						for _,c2 in sgs.list(cards)do
							if c:getNumber() == c2:getNumber() and c~=c2 and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
								table.insert(use_cards, c:getEffectiveId())
								table.insert(use_cards, c2:getEffectiveId())
								break
							end
						end
					elseif x == 5 then
						for _,c2 in sgs.list(cards)do
							if c:getSuit() == c2:getSuit() and c~=c2 and not table.contains(use_cards, c:getEffectiveId()) and not table.contains(use_cards, c2:getEffectiveId()) then
								table.insert(use_cards, c:getEffectiveId())
								table.insert(use_cards, c2:getEffectiveId())
								break
							end
						end
					elseif x == 6 then
						table.insert(use_cards, c:getEffectiveId())
					elseif c:isKindOf("TrickCard") and x == 7 then
						table.insert(use_cards, c:getEffectiveId())
					elseif c:isKindOf("EquipCard") and x == 8 then
						table.insert(use_cards, c:getEffectiveId())
					elseif c:isKindOf("BasicCard") and x == 9 then
						table.insert(use_cards, c:getEffectiveId())
					end
				end
				if #use_cards == cost then
					for _,c in sgs.list(use_cards)do
						use_card:addSubcard(c)
					end
					local dummyuse = self:aiUseCard(use_card, dummy())
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							table.insert(targets, p:objectName())
						end
						if #targets > 0 then
							return use_card:toString() .. "->" .. table.concat(targets, "+")
						end
					end
				end
			end
			self.room:addPlayerMark(self.player, "AI_do_not_invoke_shisheng".. x .. "-Clear")
		end
	else
		return "#shisheng_card:.:"
	end
	return "."
end

for i=1,10 do
	sgs.ai_skill_choice["shisheng_sc_re"..i] = function(self, choices, data)
		local shisheng_vs_card = {}
		local items = choices:split("+")
		for _, card_name in ipairs(items) do
			if card_name ~= "esc" then
				local use_card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, -1)
				use_card:deleteLater()
				table.insert(shisheng_vs_card, use_card)
			end
		end
		self:sortByUsePriority(shisheng_vs_card)
		for _, c in ipairs(shisheng_vs_card) do
			if table.contains(items, c:objectName()) then
				local dummyuse = self:aiUseCard(c)
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						self.room:setTag("ai_shisheng_sc_re"..i .."_card_name", sgs.QVariant(c:objectName()))
						return c:objectName()
					end
				end
			end
		end
		self.room:writeToConsole("AI_do_not_invoke_shisheng".. i .. "-Clear")
		self.room:addPlayerMark(self.player, "AI_do_not_invoke_shisheng".. i .. "-Clear")
		return "esc"
	end
end
sgs.ai_skill_choice["shisheng_card"] = function(self, choices, data)
	local shisheng_vs_card = {}
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "esc" then
			local use_card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, -1)
			use_card:deleteLater()
			table.insert(shisheng_vs_card, use_card)
		end
	end
	self:sortByUsePriority(shisheng_vs_card)
	for _, c in ipairs(shisheng_vs_card) do
		if table.contains(items, c:objectName()) then
			local dummyuse = self:aiUseCard(c)
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					self.room:setTag("ai_shisheng_card_name", sgs.QVariant(c:objectName()))
					return c:objectName()
				end
			end
		end
	end
	self.room:addPlayerMark(self.player, "AI_do_not_invoke_shisheng-Clear")
	return "esc"
end








			

