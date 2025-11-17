-- 使用qlist作條件時的卡片捨棄公用判斷
function Q_goodToThrow(who, card, havej)
	if havej and who:getCards("j"):length() > 0 then
		if card:isKindOf("DelayedTrick") and not card:isKindOf("YanxiaoCard") then
			return true
		end
	else
		if card:getClassName() == "SilverLion" and who:isWounded() then 
			return true
		end
		if card:getClassName() == "GaleShell" then
			return true
		end
		if card:getClassName() == "Tianjitu" and who:getHandcardNum() < 4 then
			return true
		end
	end
	
	return false
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|LuaZhenlie"
function sgs.ai_skill_invoke.LuaZhenlie(self,data)
	if sgs.ai_skill_invoke.zhenlie(self, data) then return true end
	local target = data:toCardUse().from
	if target and self:doDisCard(target, "he") then return true end
	return false
end

sgs.ai_ajustdamage_to.LuaZhenlie   = function(self, from, to, card, nature)
	if to:getMark("LuaZhenlie-Clear") > 0 then
		return -99
	end
end
sgs.ai_skill_choice.LuaZhenlie = function(self, choices, data)
    local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items, "losehp") then
		if self.player:getHp()+self:getAllPeachNum()-1 <= 0 then return "no" end
		if sgs.ai_skill_invoke.zhenlie(self, data) then return "losehp" end
		local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		slash:setSkillName("LuaZhenlie")
		if use.from and self:isEnemy(use.from) and not self:cantbeHurt(use.from) and self:damageIsEffective(use.from, slash, self.player) then
			return "losehp"
		end
		if self:needToLoseHp(self.player) then
			return "losehp"
		end
	end
	return "no"
end

sgs.ai_skill_choice.LuaRevenge = function(self, choices, data)
    local items = choices:split("+")
	local damage = data:toDamage()
	if damage.from and damage.from:objectName() == self.player:objectName() then
		return "itsmine"
	else
		return "giveyou"
	end
end

--神樂
sgs.ai_goddess_judgestring = {
	indulgence = "heart",
	diamond = "heart",
	supply_shortage = "club",
	gdancer = "red",
	yusha = "red",
	foxnature = "black",
	yuri_hagaku = "black",
	migonoinori = "spade",
	hononozouki = "heart",
	chikuwasama = "red",
	yueguang = "black",
}
function sgs.ai_cardneed.goddess_new(to, card, self)
	local hc = self.player:getCards("he")
	local have_spade = false
	local have_heart = false
	local have_club = false
	local have_red = false
	local have_black = false
	
	if hc:length() > 0 then
		for _ ,c in sgs.qlist(hc) do
			if c:isBlack() then have_black = true end
			if c:isRed() then have_red = true end
			if c:getSuit() == sgs.Card_Spade and c:getNumber() >= 2 and c:getNumber() <= 9 then have_spade = true end
			if c:getSuit() == sgs.Card_Heart then have_heart = true end
			if c:getSuit() == sgs.Card_Club then have_club = true end
		end
	end
	-- self.player:gainMark("&test")
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) then
			-- self.player:gainMark("&test2")
			if not p:containsTrick("YanxiaoCard") then
				-- self.player:gainMark("&test3")
				if p:containsTrick("indulgence") and not have_heart then
					return card:getSuit() == sgs.Card_Heart
				end
				if p:containsTrick("supply_shortage") and not have_club then
					return card:getSuit() == sgs.Card_Club
				end
				if p:containsTrick("lightning") and not (have_red and have_club) then
					return (card:getSuitString() ~= "spade" or (card:getSuitString() == "spade" and (card:getNumber() < 2 and card:getNumber() > 9)))
				end
			end
		end
		if self:isEnemy(p) then
			if p:containsTrick("lightning") and not p:containsTrick("YanxiaoCard") and not have_spade then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not p:hasSkills("hongyan|wuyan")
			end
		end
	end
end


sgs.ai_skill_cardask["@goddess-put"] = function(self,data,pattern)
	local player = self.player
	local target = self.room:getCurrent()
	local judge = data:toJudge()
	-- player:gainMark("&" .. judge.reason) 
    local needs = {}
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if not player:isNude() and judge.reason then
	-- player:gainMark("&test")
		for _,card in ipairs(cards) do
			if self:isFriend(target) then
				if judge.reason == "lightning" and (card:getSuitString() ~= "spade" or (card:getSuitString() == "spade" and (card:getNumber() < 2 and card:getNumber() > 9))) then return "$" .. card:getEffectiveId() end
				-- if judge.reason == "supply_shortage" and card:getSuitString() == "club" then return "$" .. card:getEffectiveId() end
				-- if judge.reason == "indulgence" and card:getSuitString() == "heart" then return "$" .. card:getEffectiveId() end
				if sgs.ai_goddess_judgestring[judge.reason] ~= nil and sgs.ai_goddess_judgestring[judge.reason] ~= "" then
					if card:getSuitString() == sgs.ai_goddess_judgestring[judge.reason] or card:getColorString() == sgs.ai_goddess_judgestring[judge.reason] then
						return "$" .. card:getEffectiveId() 
					end
				end
			elseif self:isEnemy(target) then
				if judge.reason == "lightning" and (card:getSuitString() == "spade" and (card:getNumber() > 1 and card:getNumber() < 10)) then return "$" .. card:getEffectiveId() end
				-- if judge.reason == "supply_shortage" and card:getSuitString() ~= "club" then return "$" .. card:getEffectiveId() end
				-- if judge.reason == "indulgence" and card:getSuitString() ~= "heart" then return "$" .. card:getEffectiveId() end
				if sgs.ai_goddess_judgestring[judge.reason] ~= nil and sgs.ai_goddess_judgestring[judge.reason] ~= "" then
					if card:getSuitString() ~= sgs.ai_goddess_judgestring[judge.reason] and card:getColorString() ~= sgs.ai_goddess_judgestring[judge.reason] then
						return "$" .. card:getEffectiveId()
					end
				end
			end
			if judge.reason == "miyadokyo" then 
				if player:hasFlag("majiBad") and card:isRed() then
					player:setFlags("-majiBad")
					return "$" .. card:getEffectiveId()
				end
				if player:hasFlag("majiGood") and card:isBlack() then
					player:setFlags("-majiGood")
					return "$" .. card:getEffectiveId()
				end
				if player:hasFlag("majiHeal") and player:getLostHp() > 1 and card:isBlack() then
					player:setFlags("-majiHeal")
					return "$" .. card:getEffectiveId()
				end
			end
		end
		local cards = self:addHandPile("he")
		local card_id = self:getRetrialCardId(cards,judge)
		if card_id~=-1 then return "$"..card_id end
	-- else
		for _,card in ipairs(cards) do
			if Q_goodToThrow(self.player, card, false) then
				table.insert(needs, card)
			end
		end
		if #needs > 0 then return "$" .. needs[1]:getEffectiveId() end
	end
    return "."
end

sgs.ai_skill_askforag["clearthemeridians"] = function(self, list)
	local cards = {}
	local ecards = {}
	for _, id in ipairs(list) do
		if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
			table.insert(ecards, sgs.Sanguosha:getCard(id))
		else
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByKeepValue(cards, true)
	self:sortByUseValue(ecards)
	if #ecards > 0 then
		return ecards[1]:getEffectiveId()
	else
		return cards[1]:getEffectiveId()
	end
end

local clearthemeridians_skill = {}
clearthemeridians_skill.name = "clearthemeridians"
table.insert(sgs.ai_skills, clearthemeridians_skill)
clearthemeridians_skill.getTurnUseCard = function(self)
	if self.player:getPile("pulsepile"):length() > 2 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf("EquipCard") then
			if c:isKindOf("SilverLion") and self.player:getArmor() and self.player:getArmor():isKindOf("SilverLion") and self.player:isWounded() then
				return sgs.Card_Parse("#clearthemeridians:" .. c:getId().. ":")
			elseif not c:isKindOf("SilverLion") then
				if not (self:isWeak(self.player) and self.player:getArmor() == nil and (c:isKindOf("RenwangShield") or c:isKindOf("EightDiagram") or c:isKindOf("Vine"))) then
					return sgs.Card_Parse("#clearthemeridians:" .. c:getId().. ":")
				end
			end
		end
	end
	return
end

sgs.ai_skill_use_func["#clearthemeridians"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.clearthemeridians = sgs.ai_use_priority.Slash + 1
sgs.ai_use_value["clearthemeridians"] = 4

sgs.ai_view_as.clearthemeridians = function(card, player, card_place)
	if player:getPile("pulsepile"):isEmpty() then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "pulsepile" then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then return ("analeptic:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id) end
		if pattern == "jink" then
			return ("jink:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id)
		elseif pattern == "slash" then
			return ("slash:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id)
		-- else
			-- return ("nullification:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_card_priority.clearthemeridians = function(self,card)
	if card:getSkillName()=="clearthemeridians"
	then
		return 1
	end
end

sgs.ai_skill_choice.clearthemeridians = function(self, choices) --照抄ol_render
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if self:isWeak() and self.player:isWounded() and table.contains(items, "peach") then return "peach" end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		if self:getCardsNum("Slash") > 1 and not slash:isAvailable(self.player) and table.contains(items, "analeptic") then
			for _, enemy in ipairs(self.enemies) do
				if ((enemy:getHp() < 3 and enemy:getHandcardNum() < 3) or (enemy:getHandcardNum() < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
					and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, slash) then
					return "analeptic"
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
				thunder_slash:deleteLater()
				local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
				fire_slash:deleteLater()
				if table.contains(items, "fire_slash") and not self:slashProhibit(fire_slash, enemy, self.player) 
				and self:slashIsEffective(fire_slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, fire_slash) then	--yun
					return "fire_slash"
				end
				if table.contains(items, "thunder_slash") and not self:slashProhibit(thunder_slash, enemy, self.player) 
				and self:slashIsEffective(thunder_slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies,thunder_slash) then	--yun
					return "thunder_slash"
				end
				if table.contains(items, "slash") and not self:slashProhibit(slash, enemy, self.player) 
				and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, slash) then	--yun
					return "slash"
				end
			end
		end
		if self.player:isWounded() and table.contains(items, "peach") then return "peach" end
	end
	if self.player:isWounded() and table.contains(items, "peach") then return "peach" end
	if table.contains(items, "analeptic") then return "analeptic" else return "cancel" end
end

sgs.ai_skill_use["@@clearthemeridians_fc"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local class_name = self.player:property("clearthemeridians_fc"):toString()
	local use_card = sgs.Sanguosha:cloneCard(class_name, sgs.Card_NoSuit, 0)
	use_card:deleteLater()
	use_card:setSkillName("clearthemeridians_fc")
	if (use_card:targetFixed()) then
		return use_card:toString()
	else
		if string.find(class_name, "slash")then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, use_card, false) and not self:slashProhibit(nil, enemy)
				and self:slashIsEffective(use_card, enemy) and self:isGoodTarget(enemy, self.enemies, use_card) then	--yun
					return use_card:toString() .. "->" .. enemy:objectName()
				end
			end
		end
	end
end


sgs.ai_skill_invoke.semeruki = function(self, data)
	-- return true
	local effect = data:toCardEffect()
	if self:isFriend(effect.to) and (effect.to:getArmor() and (effect.to:getArmor():isKindOf("GaleShell") or (effect.to:isWounded() and effect.to:getArmor():isKindOf("SilverLion")))) then
		return true
	end
	if self:isEnemy(effect.to) then return true end
	return false
end

sgs.ai_skill_cardchosen["semeruki"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if (card:isKindOf("SilverLion") and who:isWounded()) or card:isKindOf("GaleShell") then 
				return card 
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("e")) do
			if not who:isWounded() and card:isKindOf("SilverLion") then
				table.insert(goodchice, card)
			end
			if card:isKindOf("Weapon") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.skillInvoke.semeruki = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target and not (target:isWounded() and target:getArmor() and target:getArmor():isKindOf("SilverLion")) then sgs.updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_playerchosen.reedship = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if friend:getCards("he"):length() <= 1 and friend:getHp() == 1 then best_target = friend end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	return targets[1]
end
sgs.ai_skill_invoke.reedship = function(self, data)
	local use = data:toCardUse()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local hasblackcard = false
	for _,card in ipairs(cards) do
		if card:isBlack() then
			hasblackcard = true
			break
		end
	end
	if hasblackcard and self:isEnemy(use.from) then
		self:sort(self.enemies, "defenseSlash")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0)
		slash:deleteLater()
		for _,enemy in ipairs(self.enemies) do
			-- if self.player:canSlash(enemy) and not self:slashProhibit(sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0), enemy) then
			if not self:slashProhibit(slash, enemy) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@reedship"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")
	local target
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(slash, enemy) then
			target = enemy
			break
		end
	end
	if target then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if self:getCard("SilverLion") and self.player:isWounded() then 
				if card:isKindOf("SilverLion") then
					return ("slash:reedship[%s:%s]=%d->%s"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId(), target:objectName())
				end
			else
				if card:isBlack() and not (self.player:getHp() == 1 and card:isKindOf("Analeptic")) then
					return ("slash:reedship[%s:%s]=%d->%s"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId(), target:objectName())
				end
			end
		end
	else
		return "."
	end
	return "."
end

sgs.reedship_suit_value = {
	spade = 4,
	club = 3
}
sgs.ai_playerchosen_intention["reedship"] = function(self, from, to)
	sgs.updateIntention(from, to, -20)
end

local phantom_skill = {}
phantom_skill.name= "phantom"
table.insert(sgs.ai_skills,phantom_skill)
phantom_skill.getTurnUseCard=function(self)
	self:updatePlayers()
	local var = 0
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("@meiying") > 0 then 
			var = var + 1
		end
	end
	if var == 0 then return false end
	if (not self.player:hasUsed("#phantom")) then
		return sgs.Card_Parse("#phantom:.:")
	end
end

sgs.ai_skill_use_func["#phantom"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	if self.player:getMark("@waked") > 0 then
		for _, enemy in ipairs(self.enemies) do
			local cards = enemy:getHandcards()
			local hasdiamond = false
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的方塊牌，如果是閃或桃，那就逼他丟
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if card:hasFlag("visible") or card:hasFlag(flag) then
					if card:getSuit() == sgs.Card_Diamond and not (card:isKindOf("Jink") or card:isKindOf("Peach")) then
						hasdiamond = true
					end
					if hasdiamond then break end
				end
			end
			if self:objectiveLevel(enemy) > 3 and enemy:getMark("@meiying") > 0 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
				if enemy:getHp() < 3 and enemy:getCards("h"):length() <= 3 and not hasdiamond then -- 如果他的血少牌又少，加上可視牌無方塊，那是個好目標
					-- use.card = sgs.Card_Parse("#phantom:.:")
					-- if use.to then
						-- use.to:append(enemy)
					-- end
					-- return
					table.insert(good_targets, enemy)
				else
					table.insert(targets, enemy)
				end
				if enemy:getHp() == 1 and enemy:getEquips():length() > 1 and enemy:getMark("@meiying") > 0 and enemy:getCards("h"):length() <= 2 and not hasdiamond then
					best_target = enemy
					break
				end
				-- use.card = sgs.Card_Parse("#phantom:.:")
				-- if use.to then
					-- use.to:append(enemy)
				-- end
				-- return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			local cards = enemy:getHandcards()
			local hasdiamond = false
			local unknowcards = 0
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的方塊牌，如果是閃或桃，那就逼他丟
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if card:hasFlag("visible") or card:hasFlag(flag) then
					if card:getSuit() == sgs.Card_Diamond and not (card:isKindOf("Jink") or card:isKindOf("Peach")) then
						hasdiamond = true
					end
					if hasdiamond then break end
				else
					unknowcards = unknowcards + 1
				end
			end
			if enemy:getMark("@meiying") > 0 then
				if enemy:getHp() < 3 and not (hasdiamond or unknowcards > 1) then
					best_target = enemy
					break
				else
					table.insert(targets, enemy)
				end
			end
		end
	end
	use.card = sgs.Card_Parse("#phantom:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		else
			use.to:append(targets[1])
		end
		return
	end
end

sgs.ai_use_value["phantom"] = 3.5
sgs.ai_use_priority["phantom"] = sgs.ai_use_priority.Slash + 1
sgs.dynamic_value.damage_card["phantom"] = true

sgs.ai_card_intention["phantom"] = 60
sgs.ai_skill_cardask["@phantomask"] = function(self, data, pattern, target, target2)

	if not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,target) then
		return "."
	end
	if self:needToLoseHp(self.player,target) then
		return "."
	end
	local card_id
	for _,card in sgs.qlist(self.player:getCards("h"))do
		if card:getSuit() == sgs.Card_Diamond then
			card_id = card:getEffectiveId()
			break
		end
	end
	if not card_id then return "." else return "$"..card_id end
	return "."
end

local goodatwep_skill = {}
goodatwep_skill.name= "goodatwep"
table.insert(sgs.ai_skills, goodatwep_skill)
goodatwep_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#goodatwep:.:")
end

sgs.ai_skill_use_func["#goodatwep"] = function(card, use, self)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:inMyAttackRange(p) and p:getMark("GoodatwepMark") == 0 then
			if self.player:objectName() ~= p:objectName() and self:isFriend(p) and (p:getCards("j"):length() > 0 or (p:getArmor() and (p:getArmor():getClassName() == "GaleShell" or (p:isWounded() and p:getArmor():getClassName() == "SilverLion"))) or (p:getTreasure() and p:getHandcardNum() < 4 and p:getTreasure():isKindOf("Tianjitu")))then
				use.card = sgs.Card_Parse("#goodatwep:.:")
				if use.to then use.to:append(p) end
				return
			elseif not p:isNude() and not self:isFriend(p) then
				use.card = sgs.Card_Parse("#goodatwep:.:")
				self.room:setTag("goodatwep",sgs.QVariant(p:objectName()))
				if use.to then use.to:append(p) end
				return
			end
		end
	end
	-- return nil
end
sgs.ai_skill_cardchosen["goodatwep"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			-- if card:getClassName() == "Tianjitu" and who:getHandcardNum() < 4 then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_skill_choice.goodatwep = function(self, choices, data)
	local name = self.room:getTag("goodatwep"):toString()
	if name == "" then return "cancel" end
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == name then
			target = p
			break
		end
	end
	if self:isFriend(target) then return "cancel" end
	if not self:isWeak(self.player) then return "gogetit" end
	return "cancel"
end
sgs.ai_use_value["goodatwep"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["goodatwep"] = sgs.ai_use_priority.Slash + 1
-- sgs.dynamic_value.damage_card["goodatwep"] = true

sgs.ai_card_intention["goodatwep"] = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if to:getCards("j"):length() > 0 
		or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (to:isWounded() and to:getArmor():getClassName() == "SilverLion"))) 
		or (to:getTreasure() and to:getHandcardNum() < 5 and to:getTreasure():getClassName() == "Tianjitu") then
			sgs.updateIntention(from, to, 0)
		else 
			sgs.updateIntention(from, to, 15)
		end
	end
end

local helptheweak_skill = {}
helptheweak_skill.name= "helptheweak"
table.insert(sgs.ai_skills, helptheweak_skill)
helptheweak_skill.getTurnUseCard=function(self)
	local someonehurt = false
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() and friend:getHandcardNum() <= self.player:getHandcardNum() and self.player:getHp() >= friend:getHp() then
			someonehurt = true
			break
		end
	end
	if someonehurt and self.player:getHandcardNum() >= 2 then
		return sgs.Card_Parse("#helptheweak:.:")
	end
	return false
end

sgs.ai_skill_use_func["#helptheweak"] = function(card, use, self)
	local first_found, second_found = false, false
	local first_card, second_card
	local colors = nil
	local target
	self:sort(self.friends, "chaofeng")
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		if self:isWeak(self.player) and self.player:isLord() then
			target = self.player
		else
			for _, friend in ipairs(self.friends) do
				local exclude = true
				if friend:getHandcardNum() <= self.player:getHandcardNum() and self.player:getHp() >= friend:getHp() then
					if friend:isLord() and self:isWeak(friend) and self:getEnemyNumBySeat(self.player, friend) >= 1 then
						exclude = false
					elseif self.player:getHp() == 1 and self.player:getHandcardNum() >= 2 and self.player:objectName() == friend:objectName() then
						exclude = false
					elseif self:isWeak(friend) and friend:getHandcardNum() < 2 then
						exclude = false
					elseif friend:isWounded() and self.player:objectName() == friend:objectName() then
						exclude = false 				
					elseif self.player:getHandcardNum() >= 4 and friend:isWounded() then
						exclude = false 
					end
				end
				if self:needKongcheng(friend, true) and friend:getHp() > 1 then
					exclude = true
				end
				-- if not exclude and not hasManjuanEffect(friend) and self:objectiveLevel(friend) <= -2 then
				if not exclude and not hasManjuanEffect(friend) and friend:isWounded() then
					target = friend
				end
			end
		end
		if not target then return false end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player))
			if not fvalueCard and not self.player:hasFlag(fcard:getSuitString()) then
				first_card = fcard
				first_found = true
				if fcard:isRed() then colors = "red" end
				if fcard:isBlack() then colors = "black" end
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player))
					if colors == "red" then
						if first_card ~= scard and scard:isBlack() and not svalueCard then
							second_card = scard
							second_found = true
						end
					else
						if first_card ~= scard and scard:isRed() and not svalueCard then
							second_card = scard
							second_found = true
						end
					end
				end
				if second_found then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local to_use = {first_id, second_id}
		local card_str = string.format("#helptheweak:%s:", table.concat(to_use, "+"))
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["helptheweak"] = sgs.ai_use_value.Peach - 0.1
sgs.ai_use_priority["helptheweak"] = sgs.ai_use_priority.Peach - 0.1
sgs.ai_card_intention["helptheweak"] = -60
sgs.dynamic_value.benefit["helptheweak"] = true

local changesexual_skill={}
changesexual_skill.name="changesexual"
table.insert(sgs.ai_skills,changesexual_skill)
changesexual_skill.getTurnUseCard=function(self,inclusive)
	if self.player:isNude() or self.player:hasFlag("AI_dont_changesexual") then return false end
	self:sort(self.enemies, "defenseSlash")
	local girlpoint = 0
	local boypoint = 0
	local endgirlpoint = 0
	local endboypoint = 0
	local hasslash = false
	local needjink = true
	-- 觀察手牌狀態(用於回合結束前考慮是否變身與回合中是否要變身用殺)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local cl = self.player:getCards("he"):length()
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			endgirlpoint = endgirlpoint + 1
			hasslash = true
		end
		if card:isKindOf("Jink") then
			needjink = false
			endboypoint = endboypoint + 1
		end
		if card:isBlack() and not card:isKindOf("Slash") then
			endboypoint = endboypoint + 1
		end
		if card:isRed() and not card:isKindOf("Jink") then
			endgirlpoint = endgirlpoint + 1
			-- if cl <= 2 and self.player:isMale() then 
				-- self.player:setFlags("AI_dont_changesexual")
				-- local card_str = ("#changesexual:%d:")
				-- return sgs.Card_Parse(card_str)
			-- end
		end
	end
	-- 判斷敵人若有技能或裝備則考量用男性，若距離外且殘弱者則大幅考量用女性
	for _,enemy in ipairs(self.enemies) do
		local skills = enemy:getVisibleSkillList()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		-- if (not self:slashProhibit(slash, enemy, self.player)) and self:getCardsNum("Slash") > 0 and self:slashIsAvailable() then
		if (not self:slashProhibit(slash, enemy, self.player)) and self:slashIsAvailable() then
		-- and self.player:inMyAttackRange(enemy) and (enemy:hasSkills("tuntian+zaoxian") or enemy:hasSkills("bazhen|yizhong|linglong|enyuan|ganglie|gushou|huituo|wuhun|duanchang|huilei|niepan|fuli")) then
			if self.player:inMyAttackRange(enemy) and (self.player:canSlash(enemy, slash) or ((not hasslash) and endboypoint > 0)) and (skills:length() > 0 or (enemy:getArmor() and enemy:getArmor():getClassName() ~= "GaleShell")) then
				boypoint = boypoint + 2
				-- if skills:length() > 0 or (enemy:getArmor() and enemy:getArmor():getClassName() ~= "GaleShell") then
					-- boypoint = boypoint + 1
				-- end
			end
			if hasslash and not self.player:inMyAttackRange(enemy) then
				girlpoint = girlpoint + 1
				if self:isWeak(enemy) then
					girlpoint = girlpoint + 2
				end
			-- girlpoint = girlpoint + 2
			end
			-- local card_str = ("#changesexual:%d:")
			-- return sgs.Card_Parse(card_str)
		end
		-- if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:getCardsNum("Slash") > 0 and self:slashIsAvailable() and not self.player:inMyAttackRange(enemy) then
			-- girlpoint = girlpoint + 1
			-- if self:isWeak(enemy) then girlpoint = girlpoint + 2 end
		-- end
	end
	-- 牽羊一定用女人
	local current = self.room:getCurrent()
	for _,p in sgs.qlist(self.room:getOtherPlayers(current)) do
		local card = sgs.Sanguosha:cloneCard("snatch")
		if current:isCardLimited(card, sgs.Card_MethodUse, true) then break end
		if self.room:isProhibited(current, p, card) or current:distanceTo(p)>1 then continue end
		if self:isFriend(p) and (p:containsTrick("indulgence") or p:containsTrick("supply_shortage")) and not p:containsTrick("YanxiaoCard") then
		elseif self:isEnemy(p) and not p:isNude() then
		else continue end
		if self:getCardsNum("Snatch") == 0 then break end
		if self.player:isMale() then
			self.player:setFlags("AI_dont_changesexual")
			local card_str = ("#changesexual:%d:")
			return sgs.Card_Parse(card_str)
		else
			return false
		end
	end

	if girlpoint >= boypoint and self.player:isMale() and girlpoint > 0 and cl > 1 then
		self.player:setFlags("AI_dont_changesexual")
		local card_str = ("#changesexual:%d:")
		return sgs.Card_Parse(card_str)
	end
	if girlpoint < boypoint and self.player:isFemale() and boypoint > 0 and cl > 1 then
		self.player:setFlags("AI_dont_changesexual")
		local card_str = ("#changesexual:%d:")
		return sgs.Card_Parse(card_str)
	end
	if (endgirlpoint >= endboypoint or needjink) and self.player:isMale() and cl <= 2 then
		self.player:setFlags("AI_dont_changesexual")
		local card_str = ("#changesexual:%d:")
		return sgs.Card_Parse(card_str)
	end
	if endgirlpoint < endboypoint and self.player:isFemale() and cl <= 2 and not needjink then
		self.player:setFlags("AI_dont_changesexual")
		local card_str = ("#changesexual:%d:")
		return sgs.Card_Parse(card_str)
	end
	return false

end

sgs.ai_skill_use_func["#changesexual"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["changesexual"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["changesexual"] = sgs.ai_use_priority.ExNihilo - 0.1
sgs.dynamic_value.benefit["changesexual"] = true


local sexualadvantage_skill={}
sexualadvantage_skill.name="sexualadvantage"
table.insert(sgs.ai_skills, sexualadvantage_skill)
sexualadvantage_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	-- local uc = nil
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			local idc = sgs.Sanguosha:getCard(id)
			if idc:isBlack() and self.player:isMale() and self:slashIsAvailable() and not idc:isKindOf("Slash") then
				table.insert(cards, idc)
				-- return sgs.Card_Parse(("slash:sexualadvantage[%s:%s]=%d"):format(idc:getSuitString(), idc:getNumberString(), idc:getId()))
			end
		end
	end
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:isBlack() and self.player:isMale() and self:slashIsAvailable() and not card:isKindOf("Slash") then
			return sgs.Card_Parse(("slash:sexualadvantage[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end
sgs.ai_view_as.sexualadvantage = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	-- if player:isMale() and card:isBlack() and not card:isKindOf("Slash") then
	if player:isMale() and card:isKindOf("EquipCard") then
		return ("slash:sexualadvantage[%s:%s]=%d"):format(suit, number, card_id)
	elseif player:isFemale() and card:isRed() and not card:isKindOf("Jink") then
		return ("jink:sexualadvantage[%s:%s]=%d"):format(suit, number, card_id)
	end
end
function sgs.ai_cardneed.sexualadvantage(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return card:isRed() end
	return card:isRed()
end
-- sgs.ai_use_value["sexualadvantage"] = sgs.ai_use_value.Analeptic - 1
sgs.ai_use_value["sexualadvantage"] = sgs.ai_use_value.Slash + 1
-- sgs.ai_use_priority["sexualadvantage"] = sgs.ai_use_priority.Analeptic - 1
-- sgs.ai_use_priority["sexualadvantage"] = sgs.ai_use_priority.Slash - 1
-- sgs.dynamic_value.benefit["sexualadvantage"] = true


sgs.ai_skill_invoke.tomowodaji = function(self, data)
    local damage = data:toDamage()
	if not self:damageStruct(damage) then return false end
	local block_worth = 0
	-- if damage.damage > 0 and damage.to and self:isFriend(damage.to) and damage.to:objectName() ~= self.player:objectName() and (not damage.from or (damage.from and self:isEnemy(damage.from))) then
	if damage.damage > 0 and damage.to and self:isFriend(damage.to) and damage.to:objectName() ~= self.player:objectName() then
		if damage.to:getHp() <= damage.damage and (damage.to:isLord() or self:getCardsNum("Peach") > 0 or self.player:getHp() > 1) then
			block_worth = block_worth + 1
		end
		if self:getCardsNum("Slash") > 0 and damage.from and self:isEnemy(damage.from) and (self.player:getHp() > 3 or (self:isWeak(damage.from) and (self:getCardsNum("Peach") > 0 or self.player:getHp() > 1))) then
			block_worth = block_worth + 1
		end
		if self.player:getHp() >= 4 and damage.to:getHp() < 4 then
			block_worth = block_worth + 1
		end
	end
	if damage.to:objectName() == self.player:objectName() then
		if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card,damage.nature)>1 then
			return true
		end
		local slashcount = self:getCardsNum("Slash")
		if slashcount > 0 then
			local slash = self:getCard("Slash")
			assert(slash)
			if damage.from and damage.from:objectName() ~= self.player:objectName() then
				local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(damage.from)))
				if dummy_use.card and dummy_use.to:length() > 0 and dummy_use.to:contains(damage.from) then
					return true
				end
			end
		end
	end
	return block_worth > 0
end

sgs.ai_choicemade_filter.skillInvoke["tomowodaji"] = function(self, player, promptlist)
	local damage = self.room:getTag("tomowodaji"):toDamage()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, damage.to, -60)
	end
end

sgs.ai_ajustdamage_from.japenknifejile = function(self, from, to, card, nature)
    if from and card and card:isKindOf("Slash") and not beFriend(to, from)
    then
        return from:getMark("@defensive_distance_test")
    end
end

sgs.ai_skill_invoke.japenknifejile = function(self, data)
	local damage = data:toDamage()
	if self:cantDamageMore(damage.from, damage.to) then return false end
	if self:isWeak(self.player) then
		return false
	else
		return self:isEnemy(damage.to)
	end
end

sgs.japenknifejile_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.japenknifejile_keep_value = 
{
	Axe				= -2,
	Blade			= -1,
	Crossbow 		= -1,
	IceSword 		= -1,
	GudingBlade     = -1,
	YxSword    		= -1,
	YitianSword    	= -1,
	QinggangSword 	= -1,
	Spear 			= -1,
	Fan				= -2,
	KylinBow		= -2,
	Halberd			= -2,
	MoonSpear		= -2,
	SpMoonspear 	= -1,
}
sgs.japenknifejile_use_value = 
{
	Axe				= -10,
	Blade			= -10,
	Crossbow 		= -10,
	IceSword 		= -10,
	GudingBlade     = -10,
	YxSword    		= -10,
	YitianSword    	= -10,
	QinggangSword 	= -10,
	Spear 			= -10,
	Fan				= -10,
	KylinBow		= -10,
	Halberd			= -10,
	MoonSpear		= -10,
	SpMoonspear 	= -10,
}
sgs.ai_choicemade_filter.skillInvoke["japenknifejile"] = function(self, player, promptlist)
	local damage = self.room:getTag("japenknifejile"):toDamage()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, damage.to, 50)
	end
end

sgs.ai_skill_invoke.skeleton = function(self, data)
	local effect = data:toCardUse()
	self:updatePlayers()
	local needpeach = false
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			needpeach = true
			break
		end
	end
	if self:isEnemy(effect.from) and not self.player:isKongcheng() then
		local count = 13 - effect.from:getCards("he"):length()
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards, true)
		for _, card in ipairs(cards) do
			if card:getNumber() >= count then
				if (self:isWeak(self.player) and effect.card:isKindOf("Slash") and card:isKindOf("Jink")) or ((self:isWeak(self.player) or needpeach) and self:getCardsNum("Peach") < 2 and card:isKindOf("Peach")) then
					return false
				else
					if effect.from:hasSkill("zhixi") then
						local ecards = effect.from:getHandcards()
						local hasspade = false
						for _, card in sgs.qlist(ecards) do -- 查找敵人已知手牌的黑桃牌
							local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), effect.from:objectName())
							if card:hasFlag("visible") or card:hasFlag(flag) then
								if card:getSuit() == sgs.Card_Spade then
									hasspade = true
								end
								if hasspade then break end
							end
						end
						if (hasspade and effect.from:faceUp()) or ((not hasspade) and not effect.from:faceUp()) then
							if self:isWeak(self.player) then 
								return true
							else
								return false
							end
						else
							return true
						end
					else
						if effect.from:faceUp() then
							return true
						else
							return false
						end
					end
				end
			end
		end
	end
	if self:isFriend(effect.from) and not effect.from:faceUp() and not self.player:isKongcheng() and not effect.from:hasSkill("zhixi") then
		local count = 13 - effect.from:getCards("he"):length()
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, card in ipairs(cards) do
			if card:getNumber() >= count then
				return true
			end
		end
	end
	if self:isFriend(effect.from) and not self.player:isKongcheng() and effect.from:hasSkill("zhixi") then
		local count = 13 - effect.from:getCards("he"):length()
		local caninvoke = false
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, card in ipairs(cards) do
			if card:getNumber() >= count then
				caninvoke = true
			end
			if caninvoke then break end
		end
		if not caninvoke then return false end
		local fcards = effect.from:getHandcards()
		local hasspade = false
		for _, card in sgs.qlist(fcards) do -- 查找已知手牌的黑桃牌
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), effect.from:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then
				if card:getSuit() == sgs.Card_Spade then
					hasspade = true
				end
				if hasspade then break end
			end
		end
		if (hasspade and effect.from:faceUp()) or ((not hasspade) and not effect.from:faceUp()) then
			return true
		else
			return false
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["skeleton"] = function(self, player, promptlist)
	local effect = self.room:getTag("skeleton"):toCardUse()
	-- if not effect.from:hasSkill("zhixi") then
		-- if promptlist[#promptlist] == "yes" and effect.from and effect.from:faceUp() then
			-- sgs.updateIntention(self.player, effect.from, 10)
		-- end
		-- if promptlist[#promptlist] == "yes" and effect.from and not effect.from:faceUp() then
			-- sgs.updateIntention(self.player, effect.from, 0)
		-- end
	-- else
		if promptlist[#promptlist] == "yes" and effect.from and effect.from:faceUp() then
			sgs.updateIntention(self.player, effect.from, -15)
		end
		if promptlist[#promptlist] == "yes" and effect.from and not effect.from:faceUp() then
			sgs.updateIntention(self.player, effect.from, 0)
		end
	-- end
end

sgs.ai_skill_cardask["@skeleton"] = function(self, data, pattern, target, target2)
	if target and self:isFriend(target) and not self:toTurnOver(target,0,"skeleton") then return "." end
	if target and not self:toTurnOver(target,0,"skeleton") and self.player:faceUp() then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
	end
	return "."
end

sgs.ai_target_revises.skeleton = function(to,card)
	if not to:faceUp() and (card:isKindOf("Slash") or card:isNDTrick())
	then return true end
end

sgs.ai_skill_invoke.strangeguy = function(self, data)
	local feedback = 0
	self:sort(self.enemies, "defenseSlash")
	if self.player:getCards("j"):length() > 0 then
		local maji = false
		for _,friend in ipairs(self.friends) do
			if friend:hasSkill("goddess_new") then
				maji = true
				break
			end
		end
		if not maji then
			feedback = feedback + 20
		end
		if self:hasWizard(self.friends) and not maji then
			feedback = feedback - 15
		end
		if self:hasWizard(self.enemies) and not maji then
			return true
		end
	end
	local weaponcount = 0
	local armorcount = 0
	local dhorsecount = 0
	local ohorsecount = 0
	local needweapon = false
	local cards = self.player:getHandcards()
	for _, c in sgs.qlist(cards) do
		if c:isKindOf("Armor") then
			armorcount = armorcount + 1
		end
		if c:isKindOf("Weapon") then
			weaponcount = weaponcount + 1
		end
		if c:isKindOf("DefensiveHorse") then
			dhorsecount = dhorsecount + 1
		end
		if c:isKindOf("OffensiveHorse") then
			ohorsecount = ohorsecount + 1
		end
	end
	if weaponcount > 0 or ohorsecount > 0 then
		if not self.player:getWeapon() or (self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")) then
			needweapon = true
			if self.player:getHp() > 2 then feedback = feedback - 1 end
		end
		if not self.player:getOffensiveHorse() then
			needweapon = true
			if self.player:getHp() > 2 then feedback = feedback - 1 end
		end
	end
	if armorcount > 0 then
		if self.player:getArmor() and self.player:getArmor():getClassName() == "GaleShell" then
			feedback = feedback - 3
		end
		if not (armorcount == 1 and self:getCardsNum("GaleShell") == 1) then
			if self.player:getArmor() == nil then
				feedback = feedback - 1
			end
			if self.player:isWounded() and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" then
				return false
			end
		end
	end
	if dhorsecount > 0 and not self.player:getDefensiveHorse() then
		feedback = feedback - 1
	end
	for _,enemy in ipairs(self.enemies) do
		if self:getCardsNum("Slash") > 0 and (not self:slashProhibit(slash, enemy, self.player)) and (needweapon or (self.player:inMyAttackRange(enemy) and self.player:canSlash(enemy, slash))) then
			feedback = feedback - 1
			if self:isWeak(enemy) then
				feedback = feedback - 1
				if enemy:isNude() then
					feedback = feedback - 5
				end
			end
		end
		if enemy:inMyAttackRange(self.player) then
			if self.player:getHandcardNum() <= self.player:getHp() then
				feedback = feedback + 1
				if self:isWeak(self.player) and self:getCardsNum("Peach") < 2 then
					feedback = feedback + 1
				end
			end
			if self.player:getHandcardNum() > self.player:getHp() and self:isWeak(self.player) then
				feedback = feedback + 1
				if self:getCardsNum("Peach") == 0 then
					feedback = feedback + 1
				end
				if self:getCardsNum("Peach") > 1 then
					feedback = feedback - 1
				end
			end
		end
	end
	return feedback > 0
end

local tobenature_skill = {}
tobenature_skill.name= "tobenature"
table.insert(sgs.ai_skills,tobenature_skill)
tobenature_skill.getTurnUseCard=function(self)
	local canuse = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > self.player:getHandcardNum() then
			canuse = true
			break
		end
		if enemy:getHandcardNum() < self.player:getHandcardNum() and (self.player:getHandcardNum() - enemy:getHandcardNum()) < 3 and enemy:hasSkill("kongcheng") then
			canuse = true
			break
		end
	end
	for _, friend in ipairs(self.friends) do
		if canuse then break end
		if friend:getHandcardNum() < self.player:getHandcardNum() and not ((friend:hasSkill("kongcheng") and friend:getHandcardNum() == 0) or friend:hasSkill("manjuan")) then
			canuse = true
			break
		end
		if friend:getHandcardNum() > self.player:getHandcardNum() and friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0
		  and friend:objectName() == self.player:getNextAlive():objectName() and friend:getHp() == (friend:getHandcardNum() - self.player:getHandcardNum() + 1) then
			canuse = true
			break
		end
	end
	if canuse and (not self.player:hasUsed("#tobenature")) then
		return sgs.Card_Parse("#tobenature:.:")
	end
end

sgs.ai_skill_use_func["#tobenature"] = function(card, use, self)
    self:updatePlayers()
	self:sort(self.enemies, "handcard")
	if self.player:getMark("Intheforest") == 0 then
		local goodtargets = {}
		local normal = {}
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHandcardNum() > self.player:getHandcardNum() then
				table.insert(normal, enemy)
				if enemy:getHp() <= (enemy:getHandcardNum() - self.player:getHandcardNum()) then
					table.insert(goodtargets, enemy)
				end
			end
			if enemy:getHandcardNum() < self.player:getHandcardNum() and enemy:getHandcardNum() == 0 and self.player:getHandcardNum() < 3 and enemy:hasSkill("kongcheng") then
				table.insert(goodtargets, enemy)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() < self.player:getHandcardNum() and not ((friend:hasSkill("kongcheng") and friend:getHandcardNum() == 0) or friend:hasSkill("manjuan")) then
				table.insert(normal, friend)
				if self:isWeak(friend) then
					table.insert(goodtargets, friend)
				end
			end
			if friend:getHandcardNum() > self.player:getHandcardNum() and friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0
			  and friend:objectName() == self.player:getNextAlive():objectName() and friend:getHp() == (friend:getHandcardNum() - self.player:getHandcardNum() + 1) then
				use.card = sgs.Card_Parse("#tobenature:.:")
				if use.to then use.to:append(friend) end
				return
			end
		end
		use.card = sgs.Card_Parse("#tobenature:.:")
		if use.to then
			if #goodtargets > 0 then
				use.to:append(goodtargets[1])
				return
			end
			if #normal > 0 then use.to:append(normal[1]) end
		end
		return
	else
		use.card = sgs.Card_Parse("#tobenature:.:")
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHandcardNum() > self.player:getHandcardNum() then
					use.to:append(enemy)
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if friend:getHandcardNum() < self.player:getHandcardNum() then
					use.to:append(friend)
				end
			end
			assert(use.to:length() > 0)
		end
	end
end
sgs.ai_card_intention.tobenature = function(self, card, from, tos)
	-- from:gainMark("@book")
	for _,to in ipairs(tos) do
		
		local intention = 60
		if to:getHandcardNum() < from:getHandcardNum() and not (to:hasSkill("kongcheng") and to:getHandcardNum() == 0) then
			intention = -80
		end
		sgs.updateIntention(from, to, intention)
	end
end
sgs.ai_use_value["tobenature"] = 4
sgs.ai_use_priority["tobenature"] = sgs.ai_use_priority.Peach - 0.1


sgs.ai_skill_cardask["@tobenatureAsk"] = function(self, data, pattern, target, target2)
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

sgs.ai_skill_invoke.zerodifference = function(self, data)
	return true
end
sgs.ai_skill_use["@@heapridge"] = function(self, prompt)
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local diamonds = {}
		local hearts = {}
		local spades = {}
		local clubs = {}
		local needpeach = false
		local wconter = self.player:getMark("AI_has_clubs") + self.player:getMark("AI_has_spades") + self.player:getMark("AI_has_diamonds") + self.player:getMark("AI_has_hearts")
		if self:isWeak(self.player) then needpeach = true end
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				needpeach = true
			end
		end
		for _, c in ipairs(cards) do
			if not c:isKindOf("ExNihilo") or (needpeach and not c:isKindOf("Peach")) then
				if c:getSuit() == sgs.Card_Club and #clubs < 4 then
					if wconter >= 3 or not (self.player:getMark("AI_has_clubs") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(clubs, c:getId())
					end
				elseif c:getSuit() == sgs.Card_Heart and #hearts < 4 then
					if wconter >= 3 or not (self.player:getMark("AI_has_hearts") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(hearts, c:getId())
					end
				elseif c:getSuit() == sgs.Card_Spade and #spades < 4 then
					if wconter >= 3 or not (self.player:getMark("AI_has_spades") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(spades, c:getId())
					end
				elseif c:getSuit() == sgs.Card_Diamond and #diamonds < 4 then
					if wconter >= 3 or not (self.player:getMark("AI_has_diamonds") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(diamonds, c:getId())
					end
				end
			end
		end
		if #diamonds >= 4 or #clubs >= 4 or #hearts >= 4 or #spades >= 4 then
			if #clubs >= 4 then
				self.player:addMark("AI_has_clubs")
				return "#heapridge:"..table.concat(clubs, "+")..":"
			end
			if #spades >= 4 then
				self.player:addMark("AI_has_spades")
				return "#heapridge:"..table.concat(spades, "+")..":"
			end
			if #diamonds >= 4 then
				self.player:addMark("AI_has_diamonds")
				return "#heapridge:"..table.concat(diamonds, "+")..":"
			end
			if #hearts >= 4 then
				self.player:addMark("AI_has_hearts")
				return "#heapridge:"..table.concat(hearts, "+")..":"
			end
		end
	return "."
end


sgs.ai_event_callback[sgs.AfterDrawNCards].lovesong = function(self, player, data)
	local draw = data:toDraw()
	if draw.reason ~= "InitialHandCards" then return false end
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if sb:hasSkill("lovesong") and sb:getMark("lovesong") > 0 then
			-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
			-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
			sgs.roleValue[sb:objectName()]["renegade"] = 0
			sgs.roleValue[sb:objectName()]["loyalist"] = 0
			local role, value = sb:getRole(), 1000
			if role == "rebel" then role = "loyalist" value = -1000 end
			--sgs.role_evaluation[sb:objectName()][role] = value
			sgs.roleValue[sb:objectName()][role] = 0
			sgs.ai_role[sb:objectName()] = sb:getRole()
			self:updatePlayers()
		end
	end
end

sgs.ai_ajustdamage_from.lovesong = function(self,from,to,slash,nature)
	if string.find(to:getGeneralName(), "ronomiyokaruta") or string.find(to:getGeneral2Name(), "ronomiyokaruta") then
		if to:getRole() ~= "renegade" and (from:getRole() == to:getRole() or (to:isLord() and from:getRole() == "loyalist") or (from:isLord() and to:getRole() == "loyalist")) then
			return -1
		end
	end
end


sgs.ai_skill_invoke.loyalm = function(self, data)
    local damage = data:toDamage()
	if damage.from:isNude() then
		return true
	end
	if self:isFriend(damage.from) and damage.from:objectName() ~= self.player:objectName() and (damage.from:getArmor() and (damage.from:getArmor():isKindOf("GaleShell") or (damage.from:isWounded() and damage.from:getArmor():isKindOf("SilverLion")))) then
		return true
	end
	if self:isEnemy(damage.from) then
		return true
	end
	return false
end
sgs.ai_skill_cardchosen["loyalm"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if (card:isKindOf("SilverLion") and who:isWounded()) or card:isKindOf("GaleShell") then 
				return card 
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:isKindOf("SilverLion") then
				table.insert(goodchice, card)
			end
			if card:isKindOf("Weapon") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_skill_playerchosen.loyalm = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if (friend:getCards("he"):length() <= 1 and friend:getHp() == 1) or (self:isWeak(friend) and friend:isLord()) then
			best_target = friend
			break
		end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	return targets[1]
end
sgs.ai_choicemade_filter.skillInvoke["loyalm"] = function(self, player, promptlist)
	local damage = self.room:getTag("loyalm"):toDamage()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, damage.to, 10)
	else
		sgs.updateIntention(self.player, damage.to, -10)
	end
end
sgs.ai_playerchosen_intention["loyalm"] = function(self, from, to)
	sgs.updateIntention(from, to, -30)
end

sgs.ai_can_damagehp.loyalm = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and from and (self:doDisCard(from, "he") or from:isNude())
end

sgs.ai_skill_invoke.deterrence = function(self, data)
	local current = self.room:getCurrent()
	return self:isEnemy(current)
	-- return true
end
sgs.ai_choicemade_filter.skillInvoke["deterrence"] = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		-- target:gainMark("@book") --經驗證可行
		if target then sgs.updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_invoke.wannawin = function(self, data)
	local target = data:toPlayer()
	if not target or self:isFriend(target) or (self:isEnemy(target) and target:getHandcardNum() == 1 and target:getEquips():length() == 0 and target:getCards("j"):length() > 0) then self.wannawin = nil return false end
	local invoke = self:doDisCard(target, "h")
	-- if invoke then
		-- local needpeach = false
		-- for _, friend in ipairs(self.friends) do
			-- if self:isWeak(friend) then
				-- needpeach = true
				-- break
			-- end
		-- end
		-- if needpeach then player:setFlags("AI_dont_pindinain_peach")
		-- local cards = sgs.QList2Table(self.player:getHandcards())
		-- self:sortByUseValue(cards, true)
		-- self.wannawin = cards[1]:getId()
		-- self.player:gainMark("@bear")
	-- end
	return invoke
end
local wannawin_skill = {}
wannawin_skill.name = "wannawin"
table.insert(sgs.ai_skills, wannawin_skill)
wannawin_skill.getTurnUseCard = function(self)
	if not self.player:isKongcheng() then return sgs.Card_Parse("#wannawin:.:") end
end
sgs.ai_skill_use_func["#wannawin"] = function(card, use, self)
	if self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "defense")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local needpeach = false
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) then
			needpeach = true
			break
		end
	end
	if needpeach then
		max_point = 0
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then 
				if c:getNumber() > max_point then
					max_point = c:getNumber()
					max_card = c
				end
			end
		end
	end
	if (self:needKongcheng() and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective() then
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "h", true) and enemy:getMark("Wannawinmark") == 0 and self.player:canPindian(enemy) then
				use.card = sgs.Card_Parse("#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("Wannawinmark") == 0 and self:doDisCard(enemy, "h", true) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				-- self.wannawin_card = max_card:getId()
				-- use.card = sgs.Card_Parse("@wannawinCard=.")
				use.card = sgs.Card_Parse("#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		if self.player:objectName() ~= friend:objectName() and not friend:isKongcheng() and friend:getMark("Wannawinmark") == 0 and self.player:canPindian(friend)
		and (friend:getCards("j"):length() > 0 or (friend:getArmor() and (friend:getArmor():getClassName() == "GaleShell" or (friend:isWounded() and friend:getArmor():getClassName() == "SilverLion")))) then
			use.card = sgs.Card_Parse("#wannawin:"..max_card:getId()..":")
			if use.to then use.to:append(friend) end
			return
		end
	end
	if self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getMark("Wannawinmark") == 0 and self:doDisCard(enemy, "h", true) and self.player:canPindian(enemy) then
				-- self.wannawin_card = cards[1]:getId()
				-- use.card = sgs.Card_Parse("@wannawinCard=.")
				-- use.card = sgs.Card_Parse("#wannawin:"..cards[1]:getId()..":")
				use.card = sgs.Card_Parse("#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return
end
sgs.ai_skill_cardchosen["wannawin"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" or card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_use_priority.wannawin = 3.4

sgs.ai_card_intention.wannawin = function(self, card, from, tos)
	local intention = 15
	local to = tos[1]
	if self:needKongcheng(to) and to:getHandcardNum() == 1 then
		intention = 0
	end
	if to:getCards("j"):length() > 0 or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (to:isWounded() and to:getArmor():getClassName() == "SilverLion"))) then
		intention = 0
	end
	sgs.updateIntention(from, tos[1], intention)
end

sgs.ai_cardneed.wannawin = sgs.ai_cardneed.bignumber
sgs.dynamic_value.control_card.wannawin = true

sgs.ai_card_priority.theace = function(self,card,v)
	if (card:getNumber() == 1 or card:getNumber() == 13)
	then return 10 end
end


-- function sgs.ai_skill_pindian.wannawin(minusecard, self, requestor)
	-- local cards = sgs.QList2Table(self.player:getHandcards())

	-- for _, card in ipairs(cards) do
		-- if card:getNumber() < 10 then return card end
	-- end
	-- self:sortByKeepValue(cards)
	-- return cards[1]
-- end

sgs.ai_skill_invoke.hotfight = function(self, data)
    -- local prompt = data:toString()
	local current = data:toPlayer()
	-- local effect = promptlist[1]
	-- local current = findPlayerByObjectName(self.room, prompt)
	-- if self:isEnemy(current) then
	    -- return true
	-- end
	if self.player:getMark("@hotfightmark") > 0 and ((self:isEnemy(current) and not (self.player:getMark("@hotfightmark") <= 2 and self:isWeak(self.player))) or self.player:objectName() == current:objectName()) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["hotfight"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, current, 40)
	else
		sgs.updateIntention(self.player, current, 0)
	end
end
local hotfight_skill={}
hotfight_skill.name="hotfight"
table.insert(sgs.ai_skills, hotfight_skill)
hotfight_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@hotfightmark") > 0 and self.player:hasSkill("hotfight") and not (self.player:getMark("@hotfightmark") <= 2 and self:isWeak(self.player)) then
		local card_str = ("fire_slash:hotfight[no_suit:0]=.")
		local card = sgs.Card_Parse(card_str)
		return card
	end
end
function sgs.ai_cardsview.hotfight(self, class_name, player)
	for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) then return end
    end
	if class_name == "Slash" then
		if player:getMark("@hotfightmark") > 0 then
			return ("fire_slash:hotfight[no_suit:0]=.")
		end
	end
	if class_name == "Jink" then
		if player:getMark("@hotfightmark") > 0 then
			return ("jink:hotfight[no_suit:0]=.")
		end
	end
end

sgs.ai_use_value["hotfight"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["hotfight"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_playerchosen_intention["iris"] = function(self, from, to)
	sgs.updateIntention(from, to, 40)
end

sgs.ai_choicemade_filter.skillInvoke["iris"] = function(self, player, promptlist)
	local current = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("AI_iris") > 0 then
			global_room:setPlayerMark(p, "AI_iris", 0)
			current = p
			break
		end
	end

	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, current, 40)
	else
		sgs.updateIntention(self.player, current, 0)
	end
end

sgs.ai_card_intention.dressing = function(self, card, from, tos)
	local intention = 20
	local to = tos[1]
	if (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (to:isWounded() and to:getArmor():getClassName() == "SilverLion"))) then
		intention = 0
	end
	sgs.updateIntention(from, tos[1], intention)
end
sgs.ai_playerchosen_intention["dressing"] = function(self, from, to)
	sgs.updateIntention(from, to, -5)
end

-- sgs.ai_skill_cardask["@@shenshou"] = function(self)
    -- if self.player:hasSkill("xiaya") then
	    -- return self:getSuitNum("red",true,self.player) > 1
	-- elseif self.player:hasSkill("huanyi") and self.player:getMark("@huanyi") > 0 then
		-- return self:getSuitNum("red",true,self.player) > 1 and self:getSuitNum("red",false,self.player) > 0
	-- elseif self.player:getMark("@supermode") > 0 and self.player:getMark("jingxin") > 0 and self.player:getMark("@point") > 0 then
		-- return self:getSuitNum("red",true,self.player) > 0
	-- else
		-- if (self:getCardsNum("Peach") > 0) or (self:getSuitNum("red",true,self.player) < 2) or (self:getCardsNum("Jink") == 0) then return "." end
		-- for _, card in sgs.qlist(self.player:getCards("he")) do
		    -- if self:getCardsNum("Jink") > 1 then
				-- if card:isRed() then
					-- return card:getEffectiveId()
				-- end
			-- else
			    -- if card:isRed() and not isCard("Jink", card, self.player) then
					-- return card:getEffectiveId()
				-- end
			-- end
		-- end
	-- end
-- end

sgs.ai_skill_cardask["@zhixi"] = function(self, data, pattern, target, target2)
	local damage = data:toDamage()
	if not self:damageStruct(damage) then
		return "."
	end
	if self:needToLoseHp(self.player,target, damage.card) then
		return "."
	end
	local card_id
	for _,card in sgs.qlist(self.player:getCards("he"))do
		if card:isBlack() then
			card_id = card:getEffectiveId()
			break
		end
	end
	if not card_id then return "." else return "$"..card_id end
	return "."
end


sgs.ai_skill_playerchosen.zhixi = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	local enemytars = {}
	local best_etarget = nil
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if not friend:faceUp() then
			if friend:getCards("he"):length() <= 1 and friend:getHp() == 1 then best_target = friend end
		end
	end
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		table.insert(targets, enemy)
		if (self:isWeak(enemy) and enemy:isKongcheng()) or enemy:getHandcardNum() > 4 then table.insert(enemytars, enemy) end
		if enemy:getHandcardNum() > 6 then best_etarget = enemy end
	end
	if best_target then return best_target end
	if best_etarget then return best_etarget end
	if #good_targets > 0 then return good_targets[1] end
	if #enemytars > 0 then return enemytars[1] end
	return targets[1]
end

sgs.ai_skill_choice.zhixi = function(self,choices,data)
	local target = data:toPlayer()
	if self:isEnemy(target) and self:doDisCard(target, "he") then return "discard" end
	return "draw"
end

sgs.ai_choicemade_filter.skillChoice["zhixi"] = function(self, player, promptlist)
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("AI_zhixi") > 0 then
			target = p
			break
		end
	end
	if not target then return end
	if promptlist[#promptlist] == "draw" then
		sgs.updateIntention(self.player, target, -30)
	else
		sgs.updateIntention(self.player, target, 30)
	end
end
sgs.ai_suit_priority.zhixi= "club|diamond|heart|spade"
function sgs.ai_cardneed.zhixi(to, card, self)
	return card:getSuit() == sgs.Card_Spade and not self:hasSuit("spade", true, to)
end
sgs.zhixi_suit_value = 
{
	spade = 4.9
}
sgs.ai_can_damagehp.zhixi = function(self,from,card,to)
	local has_black = false
	for _, card in sgs.qlist(to:getHandcards()) do
		if card:isBlack() then
			has_black = true
			break
		end
	end
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and has_black
end

sgs.ai_skill_invoke.yuejian = function(self)
	local current = self.room:getCurrent()
	if current and self.player:isAlive() then
		if self:isFriend(current) and not self:needBear(current) then return true end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["yuejian"] = function(self, player, promptlist)	--yun
	local current = self.room:getCurrent()
	if not current then return end
	if self:needBear(current) or sgs.ai_role[current:objectName()] == "neutral" or self:getOverflow(current) <= 0 then return end
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang then return end
	if promptlist[#promptlist] == "yes" then sgs.updateIntention(player, current, -10) end
	if promptlist[#promptlist] ~= "yes" then sgs.updateIntention(player, current, 10) end
end

local turned_skill = {}
turned_skill.name = "turned"
table.insert(sgs.ai_skills, turned_skill)
turned_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#turned:.:")
end

sgs.ai_skill_use_func["#turned"] = function(card, use, self)
	local targets = {}
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:getCardsNum("Peach") < getCardsNum("Peach", enemy)) 
		  and self.player:getHandcardNum() > 0 and enemy:getHandcardNum() > 0 and self:doDisCard(enemy, "h") then
			table.insert(targets, enemy)
		end
	end
        
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "handcard")
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if ((self:needKongcheng(friend) and not friend:hasSkill("kongcheng") and friend:getHandcardNum() < 3) or friend:hasSkill("tuntian")) 
			and friend:getHandcardNum() > 0 and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
		end
	end

	if self.player:getHandcardNum() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not isCard("Peach", cards[1], enemy) and not isCard("Nullification", cards[1], enemy) and not isCard("Analeptic", cards[1], enemy)
			  and enemy:getHandcardNum() > 0 and (self:doDisCard(enemy, "h") or hasManjuanEffect(enemy)) then
				table.insert(targets, enemy)
			end
		end
	end  

	if #targets == 0 then return end
	if use.to then
		targets[1]:setFlags("turned_target")
		use.to:append(targets[1])
	end
	use.card = card
end

sgs.ai_skill_invoke.bffeedingpoisoning = function(self, data) -- 不知為啥，判斷式裡存在數字條件時，效果不會出來，雖然技能依然有效。也有可能是我腦袋混亂，天知道。
	local damage = data:toDamage()
	local invoke = false
	local count = 0
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			count = damage.damage - damage.to:getHp() - getCardsNum("Peach", enemy)
			-- if getCardsNum("Peach", enemy) > 0 then
				-- invoke = true
			-- end
		end
		if count < 0 then count = -1 end
		-- self.player:gainMark("@book", count)
		if count >= 0 then invoke = true end
		if self:isFriend(damage.to) and (self.player:isWounded() or self:needToLoseHp(damage.to) or damage.to:hasSkills("yiji|quhu|huituo")) then return false end
		if self:isFriend(damage.to) and not self.player:isWounded() then return true end
		-- if damage.to:getRole() == "rebel" and damage.to:getHp() <= damage.damage then
			-- if self:isEnemy(damage.to) and invoke then return true else return false end
		-- end
		if damage.to:getRole() == "rebel" then
			if self:isEnemy(damage.to) and invoke then return false else return true end
		end
		if self:isEnemy(damage.to) and (self.player:isWounded() or self:needToLoseHp(damage.to) or damage.to:hasSkills("yiji|quhu|huituo")) then return true end
	return true
end

sgs.ai_choicemade_filter.skillInvoke["bffeedingpoisoning"] = function(self, player, promptlist)
	local damage = self.room:getTag("bffeedingpoisoning"):toDamage()
	if self.player:isWounded() then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(self.player, damage.to, 40)
		end
	end
	if damage.to:hasSkills("yiji|quhu|huituo") then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(self.player, damage.to, 15)
		else
			sgs.updateIntention(self.player, damage.to, -15)
		end
	end
end

sgs.ai_use_priority.turned = 0

sgs.ai_can_damagehp.newmember = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

sgs.ai_playerchosen_intention.newmember = function(self, from, to)
	local intention = 0
	if from:getMark("discard") > 0 then
		global_room:setPlayerMark(from, "discard", 0)
		intention = 15
		if (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (to:isWounded() and to:getArmor():getClassName() == "SilverLion"))) then
			intention = 0
		end
		if to:getCards("j"):length() > 0 and not to:containsTrick("YanxiaoCard") then
			intention = 0
		end
	end
	if from:getMark("draw") > 0 then
		global_room:setPlayerMark(from, "draw", 0)
		intention = -40
		if self:needKongcheng(to) then intention = 10 end
	end
	if from:getMark("getk") > 0 then
		global_room:setPlayerMark(from, "getk", 0)
		intention = 20
		if to:isChained() then intention = -10 end
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_choicemade_filter.skillInvoke["songforatsu"] = function(self, player, promptlist)
	local dying = self.room:getTag("songforatsu"):toDying()
	local who = dying.who
	-- dying = data:toDying()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, who, 40)
	else
		sgs.updateIntention(self.player, who, -15)
	end
end

sgs.ai_skill_invoke.introvert = function(self, data)
	-- local use = self.room:getTag("introvert"):toCardUse()
	local use = data:toCardUse()
	if self:isFriend(use.from) and (use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")) then
		return false
	end
	if self:isEnemy(use.from) and not use.card:isKindOf("Slash") then
		local gotslash = false
		local gotanaleptic = false
		local sn = 0
		-- Crossbow Blade Axe guding_blade
		local cards = use.from:getHandcards()
		for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的酒和殺
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), use.from:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then
				if card:isKindOf("Analeptic") then
					gotanaleptic = true
				end
				if card:isKindOf("Slash") then
					gotslash = true
					sn = sn + 1
				end
			end
		end
		local ssc = use.from:getHandcardNum()/3
		if self:isWeak() and use.card:isKindOf("Duel") and (self:getCardsNum("Slash") <= sn or self:getCardsNum("Slash") < ssc) then return true end
		if self:isWeak() and use.card:isKindOf("SavageAssault") and self:getCardsNum("Slash") == 0 then return true end
		if self:isWeak() and use.card:isKindOf("ArcheryAttack") and self:getCardsNum("Jink") == 0 then return true end
		-- use.from:gainMark("@book")
		if gotslash and gotanaleptic and use.from:canSlash(self.player) and (self:getCardsNum("Jink") < 1 or (use.from:getWeapon() and use.from:getWeapon():getClassName() == "Axe" and use.from:getCards("he"):length() > 3)) then
			return false
		else
			if (use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")) and (self.player:getArmor() and self.player:getArmor():getClassName() ~= "GaleShell") or self.player:getDefensiveHorse() or self.player:getOffensiveHorse() or self.player:getWeapon() or (self.player:getHandcardNum() == 1 and self:isWeak()) then
				return true
			end
			if use.card:isKindOf("Duel") and (self:getCardsNum("Slash") <= sn or self:getCardsNum("Slash") < ssc) then return true end
			if use.card:isKindOf("SavageAssault") and self:getCardsNum("Slash") == 0 then return true end
			if use.card:isKindOf("ArcheryAttack") and self:getCardsNum("Jink") == 0 then return true end
		end
	end
	if use.card:isKindOf("Slash") or use.card:isKindOf("DelayedTrick") then
		return true
	end
	return false

end

sgs.ai_skill_invoke.yuriganglie = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.from) then
		return true
	end
	return false
end
sgs.ai_skill_cardchosen["yuriganglie"] = function(self, who, flags)
	local goodchice = {}
	local normal = {}
	for _,card in sgs.qlist(who:getCards("e")) do
		if not who:isWounded() and card:isKindOf("SilverLion") then
			table.insert(goodchice, card)
		end
		if card:isKindOf("Weapon") or card:isKindOf("DefensiveHorse") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
			table.insert(goodchice, card)
		end
		table.insert(normal, card)
	end
	if #goodchice > 0 then return goodchice[1] end
	if #normal > 0 then return normal[1] end
	return nil
end

sgs.ai_need_damaged.fightingexper = function(self, attacker, player)
	-- if not player:hasSkill("fightingclimax") then
		-- if not attacker then return end
		-- if not attacker:hasSkill("fightingexper") and self:getDamagedEffects(attacker, player) then return player:hasSkill("fightingexper") and not self:isWeak() and self.player:getPile("fc"):length() < 5 end
	-- else
		-- if not attacker then return end
		-- if not attacker:hasSkill("fightingexper") and self:getDamagedEffects(attacker, player) then return player:hasSkill("fightingexper") and not self.player:isWounded() and self.player:getPile("fc"):length() < 5 end
	-- end
	return player:getPile("fc"):length() < 5 and player:hasSkill("fightingexper") and not self.player:isWounded()
end
sgs.ai_need_damaged.yuriganglie = function(self, attacker, player)
	if not attacker then return end
	if self:isEnemy(attacker) and attacker:getCards("e"):length() < 1
		and not (self:hasSkills(sgs.need_kongcheng .. "|buqu", attacker) and attacker:getHandcardNum() > 1) and self:isGoodTarget(attacker, self:getEnemies(attacker), nil) then
		return not self:isWeak()
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.yuriganglie = function(self, player, promptlist)
	local damage = self.room:getTag("yuriganglie"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(damage.to, damage.from, 40)
		else
			sgs.updateIntention(damage.to, damage.from, -40)
		end
	end
end

local fightingclimax_skill = {}
fightingclimax_skill.name= "fightingclimax"
table.insert(sgs.ai_skills,fightingclimax_skill)
fightingclimax_skill.getTurnUseCard=function(self)
	if self.player:getPile("fc"):length() >= 5 then
		local card_str = ("#fightingclimax:%d:")
		return sgs.Card_Parse(card_str)
	end
end
sgs.ai_skill_use_func["#fightingclimax"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["fightingclimax"] = 2.5
sgs.ai_use_priority["fightingclimax"] = sgs.ai_use_value.ExNihilo + 1
sgs.dynamic_value.damage_card["fightingclimax"] = true


-- sgs.ai_skill_choice.tiexue = function(self, choices, data)
	-- if willUse(self, "Slash") or willUse(self, "Duel") then
		-- return "tiexuebuff"
	-- end
	-- return "tiexuedraw"
-- end

local witty_skill = {}
witty_skill.name= "witty"
table.insert(sgs.ai_skills,witty_skill)
witty_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards) do
		if card:isKindOf("DelayedTrick") or card:isKindOf("AmazingGrace") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") or card:isKindOf("GodSalvation") then
			local card_str = ("#witty:"..card:getId()..":")
			return sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_skill_use_func["#witty"] = function(card, use, self)
    self:updatePlayers()
	use.card = card
	if use.to then
		for _, friend in ipairs(self.friends) do
			use.to:append(friend)
		end
		assert(use.to:length() > 0)
	end
end
sgs.ai_card_intention["witty"]= function(self, card, from, tos)
	local room = from:getRoom()
	for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, -30)
	end
end
sgs.ai_use_value["witty"] = 6
sgs.ai_use_priority["witty"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_playerchosen_intention["witty"] = function(self, from, to)
	sgs.updateIntention(from, to, 40)
end

sgs.ai_skill_playerchosen.witty = function(self, targets)
	self:updatePlayers()
	local best_etarget = nil
	local enemytars = {}
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		table.insert(enemytars, enemy)
		if (self:isWeak(enemy) and enemy:isNude()) then best_etarget = enemy end
	end
	if best_etarget then return best_etarget end
	return enemytars[1]
end

--[[

sgs.ai_skill_cardask["@againstdis-card"]=function(self, data)
	local judge = data:toJudge()
	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

function sgs.ai_cardneed.againstdis(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.againstdis_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}
]]--

-- sgs.ai_skill_invoke.witty = function(self,data)
	-- local target = data:toPlayer()
	-- if not self:isFriend(target) then return true end
	-- return false
-- end



sgs.ai_event_callback[sgs.AfterDrawNCards].yuriforever = function(self, player, data)
	local draw = data:toDraw()
	if draw.reason ~= "InitialHandCards" then return false end
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if sb:getMark("yuriforever") > 0 then
			-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
			-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
			sgs.roleValue[sb:objectName()]["renegade"] = 0
			sgs.roleValue[sb:objectName()]["loyalist"] = 0
			local role, value = sb:getRole(), 1000
			if role == "rebel" then role = "loyalist" value = -1000 end
			--sgs.role_evaluation[sb:objectName()][role] = value
			sgs.roleValue[sb:objectName()][role] = 0
			sgs.ai_role[sb:objectName()] = sb:getRole()
			self:updatePlayers()
		end
	end
end

sgs.ai_skill_invoke.LuaJTieji = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_skill_cardask["@luajtieji-discard"] = function(self, data, pattern)
	local suit = pattern:split("|")[2]
	local use = data:toCardUse()
	if self:needToThrowArmor() and self.player:getArmor():getSuitString() == suit then return "$" .. self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(use.card, self.player, use.from)
		or (not self:hasHeavyDamage(use.from, use.card, self.player)
			and (self:needToLoseHp(self.player, use.from, use.card)) and not self.player:getHp() <= 1) then return "." end
	if self:getCardsNum("Jink") == 0 or sgs.isJinkAvailable(use.from, self.player, use.card) then return "." end
	-- if self:getCardsNum("Jink") == 0 then return "." end --如果又出問題直接用這段，上面那個死一死

	local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
	local need_double_jink = use.from:hasSkill("wushuang")
							or (use.from:hasSkill("roulin") and self.player:isFemale())
							or (self.player:hasSkill("roulin") and use.from:isFemale())
							or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
	local jink = 0
	local need = need_double_jink and 2 or 1
	local hcards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		hcards:prepend(sgs.Sanguosha:getCard(id))
	end
	hcards = sgs.QList2Table(hcards)
	for _, card in ipairs(hcards) do
		if card:isKindOf("Jink") then jink = jink + 1 end
	end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:getSuitString() ~= suit then continue end
		if card:isKindOf("Analeptic") or card:isKindOf("Peach") then continue end
		if not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card)) then continue end
		if card:isKindOf("Jink") and jink - 1 < need then continue end
		if self.player:getArmor() and self:evaluateArmor() > 3 and card:getEffectiveId() == self.player:getArmor():getEffectiveId() then continue end
		if card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then continue end
		return "$" .. card:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.skillInvoke.LuaJTieji = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_use["@@thedolls"] = function(self, prompt)
    self:updatePlayers(true)
    local targets = {}
	-- self.player:gainMark("@book")
	-- for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		-- if (not p:isAllNude()) and p:getMark("@thedollsmark") > 0 then
			-- if self:isFriend(p) and (p:getCards("j"):length() > 0 or (p:getArmor() and (p:getArmor():getClassName() == "GaleShell" or (p:isWounded() and p:getArmor():getClassName() == "SilverLion"))))then
				-- table.insert(targets, p:objectName())
			-- elseif not (p:isNude() or (p:isKongcheng() and p:getCards("e"):length() == 1 and p:getArmor() and (p:getArmor():getClassName() == "GaleShell"))) and not self:isFriend(p) then
				-- table.insert(targets, p:objectName())
			-- end
		-- end
		-- if #targets >= 3 then break end
	-- end
	self:sort(self.friends, "chaofeng")
	self:sort(self.enemies, "defense")
    for _, f in ipairs(self.friends) do
		if (not f:isAllNude()) and f:getMark("@thedollsmark") > 0 then
			if self:isFriend(f) and (f:getCards("j"):length() > 0 or (f:getArmor() and (f:getArmor():getClassName() == "GaleShell" or (f:isWounded() and f:getArmor():getClassName() == "SilverLion"))))then
				table.insert(targets, f:objectName())
			end
		end
		if #targets >= 3 then break end
    end
	if #targets < 3 then
		for _, p in ipairs(self.enemies) do
			if (not p:isAllNude()) and p:getMark("@thedollsmark") > 0 then
				if p:getEquips():length() > 0 and not (p:getEquips():length() == 1 and p:getArmor() and (p:getArmor():getClassName() == "GaleShell")) then
					table.insert(targets, p:objectName())
				end
			end
			if #targets >= 3 then break end
		end
	end
	-- if #targets < 3 then
		-- for _, p in ipairs(self.enemies) do
			-- if (not p:isAllNude()) and p:getMark("@thedollsmark") > 0 then
				-- if not (p:isNude() or (p:isKongcheng() and p:getCards("e"):length() == 1 and p:getArmor() and (p:getArmor():getClassName() == "GaleShell"))) then
					-- table.insert(targets, p:objectName())
				-- end
			-- end
			-- if #targets >= 3 then break end
		-- end
	-- end
	if #targets == 0 then return nil end
    return "#thedolls:.:->"..table.concat(targets, "+")
end

sgs.ai_skill_cardchosen["thedolls"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			-- if card:getClassName() == "Tianjitu" and who:getHandcardNum() < 4 then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		-- if self:isWeak(self.player) then
		-- else
			for _,card in sgs.qlist(who:getCards("he")) do
				if self:isWeak(self.player) and not card:isKindOf("EquipCard") then
					table.insert(goodchice, card)
				end
				if not who:isWounded() and card:getClassName() == "SilverLion" then
					table.insert(goodchice, card)
				end
				if card:isKindOf("Weapon") or card:isKindOf("DefensiveHorse") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
					table.insert(goodchice, card)
				end
				table.insert(normal, card)
			end
		-- end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_card_intention["thedolls"] = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if to:getCards("j"):length() > 0 or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (to:isWounded() and to:getArmor():getClassName() == "SilverLion"))) then
			sgs.updateIntention(from, to, 0)
		else 
			sgs.updateIntention(from, to, 15)
		end
	end
end
sgs.ai_choicemade_filter.cardChosen.thedolls = sgs.ai_choicemade_filter.cardChosen.snatch
-- sgs.ai_skill_use_func["#tobenature"] = function(card, use, self)
    -- self:updatePlayers()
	-- self:sort(self.enemies, "handcard")
	-- if self.player:getMark("Intheforest") == 0 then
		-- local goodtargets = {}
		-- local normal = {}
		-- for _, enemy in ipairs(self.enemies) do
			-- if enemy:getHandcardNum() > self.player:getHandcardNum() then
				-- table.insert(normal, enemy)
				-- if enemy:getHp() <= (enemy:getHandcardNum() - self.player:getHandcardNum()) then
					-- table.insert(goodtargets, enemy)
				-- end
			-- end
			-- if enemy:getHandcardNum() < self.player:getHandcardNum() and enemy:getHandcardNum() == 0 and self.player:getHandcardNum() < 3 and enemy:hasSkill("kongcheng") then
				-- table.insert(goodtargets, enemy)
			-- end
		-- end
		-- for _, friend in ipairs(self.friends_noself) do
			-- if friend:getHandcardNum() < self.player:getHandcardNum() and not ((friend:hasSkill("kongcheng") and friend:getHandcardNum() == 0) or friend:hasSkill("manjuan")) then
				-- table.insert(normal, friend)
				-- if self:isWeak(friend) then
					-- table.insert(goodtargets, friend)
				-- end
			-- end
			-- if friend:getHandcardNum() > self.player:getHandcardNum() and friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0
			  -- and friend:objectName() == self.player:getNextAlive():objectName() and friend:getHp() == (friend:getHandcardNum() - self.player:getHandcardNum() + 1) then
				-- use.card = sgs.Card_Parse("#tobenature:.:")
				-- if use.to then use.to:append(friend) end
				-- return
			-- end
		-- end
		-- use.card = sgs.Card_Parse("#tobenature:.:")
		-- if use.to then
			-- if #goodtargets > 0 then
				-- use.to:append(goodtargets[1])
				-- return
			-- end
			-- if #normal > 0 then use.to:append(normal[1]) end
		-- end
		-- return
	-- else
		-- use.card = sgs.Card_Parse("#tobenature:.:")
		-- if use.to then
			-- for _, enemy in ipairs(self.enemies) do
				-- if enemy:getHandcardNum() > self.player:getHandcardNum() then
					-- use.to:append(enemy)
				-- end
			-- end
			-- for _, friend in ipairs(self.friends_noself) do
				-- if friend:getHandcardNum() < self.player:getHandcardNum() then
					-- use.to:append(friend)
				-- end
			-- end
			-- assert(use.to:length() > 0)
		-- end
	-- end
-- end
--關銀屏
sgs.ai_cardneed.yuri_xueji = function(to, card)
	return to:getHandcardNum() < 3 and card:isRed()
end

local function can_be_selected_as_target_olxueji(self, who)
	-- if not self:damageIsEffective(who, sgs.DamageStruct_Fire) then return false end
	-- if self:isEnemy(who) and not self:cantbeHurt(who) and self:canDamage(who, self.player, false, sgs.DamageStruct_Fire) then
	if self:isEnemy(who) and not who:isChained() then
		return true
	elseif self:isFriend(who) then
		-- if self:canDamage(who, self.player, false, sgs.DamageStruct_Fire) then return true end
		-- if self.player:getHp() > 1 and self.player:hasSkill("yuri_huxiao") and not self.player:hasSkill("jueqing") and #self.enemies > 1
		-- and who:objectName() == self.player:objectName() then 
			-- return true 
		-- end
		-- if who:hasSkills("yiji|nosyiji") and not self.player:hasSkill("jueqing") then
			-- local huatuo = self.room:findPlayerBySkillName("jijiu")
			-- if (huatuo and self:isFriend(huatuo) and huatuo:getHandcardNum() >= 3 and huatuo ~= self.player)
				-- or who:getHp() >= 3 then
				-- return true
			-- end
		-- end
		-- if who:hasSkill("hunzi") and who:getMark("hunzi") == 0 and who:objectName() == self.player:getNextAlive():objectName() and who:getHp() == 2 then
			-- return true
		-- end
		return who:isChained()
	end
	return false
end

local yuri_xueji_skill = {
	name = "yuri_xueji", 
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#yuri_xueji") then return end
		return sgs.Card_Parse("#yuri_xueji:.:")
	end,
}
table.insert(sgs.ai_skills, yuri_xueji_skill)
sgs.ai_skill_use_func["#yuri_xueji"] = function(card, use, self)
	-- for _, friend in ipairs(self.friends) do
		-- if friend:isChained() and self:isWeak(friend) and friend:getHp() < 2 and self:getCardsNum("Peach") < 2 and self:damageIsEffective(friend, sgs.DamageStruct_Fire) then return end
	-- end
	local cards = self.player:getCards("he")
	local slashs = {}
	for _,c in sgs.qlist(cards) do
		-- if c:isRed() and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1) then
		if c:isBlack() and not (card:isKindOf("IronChain") and self.player:getLostHp() < 2) then
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return end
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
		if can_be_selected_as_target_olxueji(self, enemy) then
			to_use = true
			break
		end
	end
	if not to_use then
		for _, friend in ipairs(self.friends) do
			if can_be_selected_as_target_olxueji(self, friend) then
				to_use = true
				break
			end
		end
	end
	if not to_use then return end
	
	self:sortByUseValue(slashs, true)
	local n = math.max(self.player:getLostHp()+1, 2)
	
	self:sort(self.enemies, "hp")
	
	use.card = sgs.Card_Parse("#yuri_xueji:"..slashs[1]:getId()..":")
	local tos = {}
	 for _, friend in ipairs(self.friends) do --把最後一段搬上來
		 if not table.contains(tos, friend) and can_be_selected_as_target_olxueji(self, friend) then
			if use.to and use.to:length() < n then use.to:append(friend) table.insert(tos, friend) end
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if can_be_selected_as_target_olxueji(self, enemy) and (enemy:hasArmorEffect("vine") or enemy:hasSkill("lianhuo")) then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if not table.contains(tos, enemy) and can_be_selected_as_target_olxueji(self, enemy) and not enemy:isChained() and not enemy:hasSkills("qianjie|marriedg") then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end
	
	-- for _, friend in ipairs(self.friends) do
		 -- if not table.contains(tos, friend) and can_be_selected_as_target_olxueji(self, friend) and not friend:isChained() then
			-- if use.to and use.to:length() < n then use.to:append(friend) table.insert(tos, friend) end
		-- end
	-- end
	
	for _, enemy in ipairs(self.enemies) do
	    if not table.contains(tos, enemy) and can_be_selected_as_target_olxueji(self, enemy) then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end
	-- return "#thedolls:.:->"..table.concat(targets, "+")
	-- for _, friend in ipairs(self.friends) do
		 -- if not table.contains(tos, friend) and can_be_selected_as_target_olxueji(self, friend) then
			-- if use.to and use.to:length() < n then use.to:append(friend) table.insert(tos, friend) end
		-- end
	-- end
end

sgs.ai_card_intention.yuri_xueji = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		local intention = 10
		if self:needToLoseHp(to) then continue end
		if to:isChained() then intention = -10 end
		if to:hasSkill("hunzi") and to:getMark("hunzi") == 0 then
			if to:objectName() == from:getNextAlive():objectName() and to:getHp() == 2 then
				intention = -10
			end
		end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_use_value.yuri_xuejiCard = 4
sgs.ai_use_priority.yuri_xueji = sgs.ai_use_priority.IronChain + 0.2

sgs.ai_view_as.yuri_wuji = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("fire_slash:yuri_wuji[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local yuri_wuji_skill = {}
yuri_wuji_skill.name = "yuri_wuji"
table.insert(sgs.ai_skills, yuri_wuji_skill)
yuri_wuji_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	local red_card
	self:sortByUseValue(cards, true)

	local useAll = false
	local kill = false
	
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() 
			and self:isGoodTarget(enemy, self.enemies, nil) then
				kill = true
				if enemy:getHp() <= 1 and self:isWeak(enemy) 
				and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
					useAll = true
					break
				end
		end
	end
	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then disCrossbow = true end
	
	if self:hasCrossbowEffect() and kill then
		for _, card in ipairs(cards) do
			if card:isRed() and (not isCard("Crossbow", card, self.player) or disCrossbow) and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				red_card = card
				break
			end
		end
	end
	
	if not red_card then
		if self.player:hasSkill("nuzhan") and kill then
			for _, card in ipairs(cards) do
				if card:isRed() and card:isKindOf("TrickCard") then
					red_card = card
					break
				end
			end
			
			if not red_card then
				local nuzhan = false
				for _, enemy in ipairs(self.enemies) do
					if not enemy:hasArmorEffect("eight_diagram") and not enemy:hasArmorEffect("silver_lion") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
					and getCardsNum("Jink", enemy) < 1 and self:isGoodTarget(enemy, self.enemies, nil) then
						nuzhan = true
						break
					end
				end
				if nuzhan then
					for _, card in ipairs(cards) do
						if card:isRed() and card:isKindOf("EquipCard") and (not card:isKindOf("Crossbow") or disCrossbow) and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
							red_card = card
							break
						end
					end
				end
			end
		end
		
		if not red_card then
			for _, card in ipairs(cards) do
				if card:isRed() and (not isCard("Peach", card, self.player) or useAll) and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0)
					and (not isCard("Crossbow", card, self.player) or disCrossbow)
					and (self:getUseValue(card) < sgs.ai_use_value.FireSlash or inclusive or self:getOverflow() > 0
						or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("fire_slash")) > 0) then
					red_card = card
					break
				end
			end
		end
	end
	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("fire_slash:yuri_wuji[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

sgs.ai_skill_playerchosen.ys_huairou = function(self, targets)
	self:sort(self.friends_noself, "defense")
	for _, target in ipairs(self.friends_noself) do
		if self:isFriend(target) and not (target:hasSkills("manjuan|zishu") or self:needKongcheng(target)) and target:hasSkills("enyuan|hongde") then 
			return target 
		end
	end
	for _, target in ipairs(self.friends_noself) do
		if self:isFriend(target) and not target:hasSkills("manjuan|zishu") then 
			return target 
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.ys_huairou = function(self, from, to)
	if to:hasSkills("manjuan|zishu") then sgs.updateIntention(from, to, 0) end
	sgs.updateIntention(from, to, -40)
end

local ys_jueyan_skill = {}
ys_jueyan_skill.name = "ys_jueyan"
table.insert(sgs.ai_skills, ys_jueyan_skill)
ys_jueyan_skill.getTurnUseCard = function(self)
	if self.player:getMark("@ys_jueyan") == 0 then return end
	return sgs.Card_Parse("#ys_jueyan:.:")
end

sgs.ai_skill_use_func["#ys_jueyan"] = function(card, use, self)
	if self.player:getMark("@ys_jueyan") <= 0 then return end

	local target
	-- self:sort(self.enemies, "handcard")
	-- for _, enemy in ipairs(self.enemies) do
		-- target = enemy
		-- break 
	-- end
	if not self:isWeak() then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) then 
				target = enemy
				break 
			end
		end
	end
	if not target and self:isWeak() then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) 
			and not (self:needToLoseHp(enemy, self.player, nil, true)) then 
				target = enemy
				break 
			end
		end
	end
	if not target then return end
	use.card = sgs.Card_Parse("#ys_jueyan:.:")
	if use.to then use.to:append(target) end
	return
end


sgs.ai_use_value["ys_jueyan"] = 5
sgs.ai_use_priority.ys_jueyan = sgs.ai_use_priority.ExNihilo - 0.1
sgs.ai_card_intention["ys_jueyan"] = 60

--雄起
-- local ys_xionchi_skill = {}
-- ys_xionchi_skill.name= "ys_xionchi"
-- table.insert(sgs.ai_skills,ys_xionchi_skill)
-- ys_xionchi_skill.getTurnUseCard=function(self)
	-- if self.player:getMark("@arise") == 0 or not self.player:isWounded() then return end
	-- return sgs.Card_Parse("#ys_xionchi:.:")
-- end

-- sgs.ai_skill_use_func["#ys_xionchi"] = function(card, use, self)
    -- self:updatePlayers()
	-- use.card = card
	-- if use.to then
		-- for _, friend in ipairs(self.friends) do
			-- use.to:append(friend)
		-- end
		-- assert(use.to:length() > 0)
	-- end
-- end
-- sgs.ai_card_intention["ys_xionchi"]= function(self, card, from, tos)
	-- for _,to in ipairs(tos) do
		-- sgs.updateIntention(from, to, -30)
	-- end
-- end
-- sgs.ai_use_value["ys_xionchi"] = sgs.ai_use_value.Peach + 1
-- sgs.ai_use_priority["ys_xionchi"] = sgs.ai_use_priority.Peach - 0.1

--雄亂
-- local ys_xiongluan_skill = {}
-- ys_xiongluan_skill.name= "ys_xiongluan"
-- table.insert(sgs.ai_skills,ys_xiongluan_skill)
-- ys_xiongluan_skill.getTurnUseCard=function(self)
	-- if self.player:getMark("@fuck_caocao") == 0 then return end
	-- local num = #self.enemies
	-- local maxp = math.ceil(num/2)
	-- local rp = 0
	-- if self:isWeak(player) then return sgs.Card_Parse("#ys_xiongluan:.:") end
	-- for _, enemy in ipairs(self.enemies) do
		-- if not enemy:hasArmorEffect("vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
			-- and not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy, self.player, nil, true)) then
			-- rp = rp + 1
		-- end
	-- end
	-- if maxp > 0 and rp >= maxp then return sgs.Card_Parse("#ys_xiongluan:.:") end
-- end

-- sgs.ai_skill_use_func["#ys_xiongluan"] = function(card, use, self)
    -- self:updatePlayers()
	-- use.card = card
	-- if use.to then
		-- for _, enemy in ipairs(self.enemies) do
			-- if not enemy:hasArmorEffect("vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player) 
				-- and not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy, self.player, nil, true)) then
				-- use.to:append(enemy)
			-- end
		-- end
		-- if use.to:length() == 0 then
			-- for _, enemy in ipairs(self.enemies) do
				-- use.to:append(enemy)
			-- end
		-- end
		-- assert(use.to:length() > 0)
	-- end
-- end

-- sgs.ai_use_value["ys_xiongluan"] = sgs.ai_use_value.Slash + 1
-- sgs.ai_use_priority["ys_xiongluan"] = sgs.ai_use_priority.Slash + 0.1

-- sgs.ai_skill_use["@@ys_congjian"]=function(self,prompt)
    -- self:updatePlayers()
	-- if self.player:isNude() then return "." end
    -- if #self.friends > 0 then
	    -- self:sort(self.friends, "defense")
		-- local best_tar
		-- local targets = {}
	    -- for _,friend in ipairs(self.friends) do
			-- if friend:getMark("ys_congjian") > 0 then
				-- table.insert(targets, friend)
				-- if self:isWeak(friend) then
					-- best_tar = friend
					-- break
				-- end
			-- end
	    -- end
		-- local cardlist = {}
		-- if (best_tar and best_tar:objectName() == self.player:objectName()) or (#targets == 1 and targets[1]:objectName() == self.player:objectName()) then
			-- local cards = self.player:getCards("he")
			-- cards = sgs.QList2Table(cards)
			-- self:sortByKeepValue(cards, false)
			-- for _,card in ipairs(cards) do
				-- if not card:isKindOf("Peach") then
					-- table.insert(cardlist, card)
				-- end
				-- if card:isKindOf("EquipCard") then
					-- return ("#ys_congjian:%d:->%s"):format(card:getEffectiveId(), self.player:objectName())
				-- end
			-- end
			-- if #cardlist > 0 then 
				-- return ("#ys_congjian:%d:->%s"):format(cardlist[1]:getEffectiveId(), self.player:objectName())
			-- end
		-- elseif (best_tar or #targets > 0) then
			-- local cards = self.player:getCards("he")
			-- cards = sgs.QList2Table(cards)
			-- self:sortByKeepValue(cards, true)
			-- for _,card in ipairs(cards) do
				-- table.insert(cardlist, card)
				-- if best_tar then 
					-- if self:getCardsNum("Peach") > 0 and ((card:isKindOf("Armor") and not card:isKindOf("GaleShell")) or card:isKindOf("DefensiveHorse")) then
						-- return ("#ys_congjian:%d:->%s"):format(card:getEffectiveId(), best_tar:objectName())
					-- end
				-- else
					-- if card:isKindOf("EquipCard") then
						-- return ("#ys_congjian:%d:->%s"):format(card:getEffectiveId(), targets[1]:objectName())
					-- end
				-- end
			-- end
			-- if #cardlist > 0 then 
				-- if best_tar then return ("#ys_congjian:%d:->%s"):format(cardlist[1]:getEffectiveId(), best_tar:objectName()) end
				-- return ("#ys_congjian:%d:->%s"):format(cardlist[1]:getEffectiveId(), targets[1]:objectName())
			-- end
		-- else
		    -- return "."
		-- end
    -- end
    -- return "."
-- end
-- sgs.ai_card_intention["ys_congjian"] = sgs.ai_card_intention.RendeCard

sgs.ai_skill_invoke.likebooks = true

sgs.ai_skill_discard["likebooks"] = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	self:sortByKeepValue(cards)
	-- if self:needKongcheng() and not self.player:isKongcheng() then
		-- for _, card in ipairs(cards) do
			-- table.insert(to_discard, card:getId())
		-- end
		-- return to_discard
	-- end
	local jink = 0
	local ana = 0
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") or card:isKindOf("Disaster") or card:isKindOf("AmazingGrace") then
			table.insert(to_discard, card:getId())
		elseif card:isKindOf("Jink") then
			if jink > 0 then table.insert(to_discard, card:getId()) end
			jink = jink + 1
		elseif card:isKindOf("Analeptic") then
			if ana > 0 then table.insert(to_discard, card:getId()) end
			ana = ana + 1
		elseif card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") and not card:isKindOf("Nullification") then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummyuse)
			if dummyuse.to:isEmpty() then
				table.insert(to_discard, card:getId())
			end
		else
			if not self:hasSkills(sgs.lose_equip_skill) then
				if card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
					table.insert(to_discard, card:getId())
				elseif card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then
					table.insert(to_discard, card:getId())
				elseif card:isKindOf("Armor") and self:evaluateArmor(card) <= self:evaluateArmor() then
					table.insert(to_discard, card:getId())
				elseif card:isKindOf("Weapon") and self:evaluateWeapon(card) <= self:evaluateWeapon(self.player:getWeapon()) then
					table.insert(to_discard, card:getId())
				end
			end
		end
	end
	if #to_discard < 1 then return self:askForDiscard("dummyreason", 1, 1, false, false) end
	return to_discard[1]
end

sgs.ai_skill_choice.likebooks = function(self, choices, data)
	if self.player:hasArmorEffect("vine") and self.player:isChained() and not self:isGoodChainPartner() then
		return "reset"
	end
	if self:isWeak() and self.player:isWounded() then return "recover" end
	if self.player:hasSkills("manjuan|zishu") then
		if self.player:isWounded() then return "recover" end
		if self.player:isChained() then return "reset" end
	end
	return "recover"
end

sgs.ai_skill_invoke.happinesstoeveryone = function(self, data)
	local target = self.room:getCurrent()
	local count = target:getHandcardNum() - target:getMaxHp()
	if target and self:isFriend(target) and (target:isChained() or not target:faceUp()) then return true end
	if target and self:isFriend(target) and ((count < -1 and not self:needKongcheng(target, true)) or self:isWeak(target)) and target then
		return true
	end
	
	return false
end

sgs.ai_choicemade_filter.skillInvoke.happinesstoeveryone = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if not current then return end
	if promptlist[#promptlist] == "yes" then sgs.updateIntention(player, current, -20) end
end

sgs.ai_ajustdamage_to.bloody   = function(self, from, to, card, nature)
	if to:getMark("@struggle") > 1  then
		return -99
	end
end


sgs.ai_skill_invoke.blooddry = function(self,data)
	local use = data:toCardUse()
	-- if not self:isFriend(target) then return true end
	-- return false
	for _ ,to in sgs.qlist(use.to) do
		if self:isEnemy(to) then return true end
	end
	return false
end

local suckblood_skill={}
suckblood_skill.name="suckblood"
table.insert(sgs.ai_skills, suckblood_skill)
-- suckblood_skill.getTurnUseCard = function(self, inclusive)
	-- local getpeach = false
	-- for _,friend in ipairs(self.friends) do
		-- if getCardsNum("Peach", friend) > 0 and not self:isWeak(friend) then getpeach = true break end
	-- end
	-- if self.player:getHp() > 1 and self.player:hasSkill("suckblood") and (not self:isWeak(self.player) or getpeach) then
		-- local card_str = ("slash:suckblood[no_suit:0]=.")
		-- local card = sgs.Card_Parse(card_str)
		-- return card
	-- end
-- end
suckblood_skill.getTurnUseCard = function(self, inclusive)
	local n = 0
	local getpeach = false
    for _,enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) and self.player:getHp() < enemy:getHandcardNum() and (self.player:distanceTo(enemy) <= 1 or self:isWeak(enemy)) then
			n = n + 1
		end
	end
	for _,friend in ipairs(self.friends) do
		if getCardsNum("Peach", friend) > 0 then getpeach = true break end
	end
	if n > 0 and (getpeach or not self:isWeak(self.player)) then
		local card_str = ("slash:suckblood[no_suit:0]=.")
		local card = sgs.Card_Parse(card_str)
		return card
	end
end
function sgs.ai_cardsview.suckblood(self, class_name, player)
	if class_name == "Slash" then
		if player:getHp() > 0 then
			return ("slash:suckblood[no_suit:0]=.")
		end
	end
end
sgs.ai_skill_invoke.suckblood = function(self,data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["suckblood"] = function(self, player, promptlist)
	local damage = self.room:getTag("suckblood"):toDamage()
	if promptlist[#promptlist] == "yes" then
		sgs.updateIntention(self.player, damage.to, 30)
	end
end
sgs.ai_use_value["suckblood"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["suckblood"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_skill_invoke.yuri_jianchu = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) and self:doDisCard(target, "he") then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.yuri_jianchu = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_playerchosen["yuri_liangyin"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in ipairs(targets) do
		if (p:getHandcardNum() < self.player:getHandcardNum() or p:getHp() < self.player:getHp()) and self:isFriend(p) and self.player:getMark("yl_draw") > 0 then --room:setPlayerMark(player, "yl_draw", 1)
			return p
		elseif (p:getHandcardNum() > self.player:getHandcardNum() or p:getHp() > self.player:getHp()) and (not p:isNude()) and self.player:getMark("yl_draw") == 0 then
			if self:isEnemy(p) and not self:needToThrowCard(p) then return p end
			if self:isFriend(p) and self:needToThrowCard(p) then return p end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.yuri_liangyin = function(self, from, to)
	if (to:getHandcardNum() < from:getHandcardNum() or to:getHp() < from:getHp()) and self.player:getMark("yl_draw") > 0 then sgs.updateIntention(from, to, -10) end
	if ((to:getHandcardNum() > from:getHandcardNum()) or (to:getHp() > from:getHp())) and (self.player:getMark("yl_draw") == 0) and not self:needToThrowCard(to) then sgs.updateIntention(from, to, 10) end
end

sgs.ai_skill_use["@yuri_kongsheng"] = function(self, prompt, method)	--yun
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	-- local to_discard = qlist
	self:sortByKeepValue(cards)
	if (self:needKongcheng() and not self.player:isKongcheng()) or self.player:containsTrick("indulgence") then
		for _, card in ipairs(cards) do
			table.insert(to_discard, card:getId())
		end
	end
	local useSlash = false
	local slash, ana, peach = 0, 0, 0
	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			table.insert(to_discard, card:getId())
		elseif card:isKindOf("Slash") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				useSlash = true
				slash = slash + 1
			else
				table.insert(to_discard, card:getId())
			end
			if slash > 1 and not self:hasCrossbowEffect() and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		elseif card:isKindOf("Analeptic") then
			if not useSlash or ana > 0 then table.insert(to_discard, card:getId()) end
			ana = ana + 1
		elseif card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") and not card:isKindOf("Nullification") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.to:isEmpty() then
				table.insert(to_discard, card:getId())
			end
		elseif card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
			table.insert(to_discard, card:getId())
		elseif card:isKindOf("Peach") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				peach = peach + 1
			else
				table.insert(to_discard, card:getId())
			end
			if peach > 1 and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		end
	end
	if self:needToThrowArmor() then table.insert(to_discard, self.player:getArmor():getId()) end
	if self.player:getDefensiveHorse() then table.insert(to_discard, self.player:getDefensiveHorse():getId()) end
	if #to_discard == 0 then return "." end
	if #to_discard > 1 then
		local to_use = {to_discard[1], to_discard[2]}
		return string.format("#yuri_kongsheng:%s:", table.concat(to_use, "+"))
	else
		return string.format("#yuri_kongsheng:%s:", to_discard[1])
	end
end
sgs.ai_skill_playerchosen.yuri_kongsheng = function(self, targets)
	self:updatePlayers()
	local guys={}
	for _,target  in sgs.qlist(targets) do
		if self:isFriend(target) then
		 table.insert(guys, target)
		end
	end
	if #guys == 0 then return nil end
	self:sort(guys, "chaofeng")
	local tars={}
	local badtars={}
	for _, t in ipairs(guys) do
		if t:hasSkills("keji|conghui") then
			table.insert(badtars, t)
		else
			table.insert(tars, t)
		end
		if not t:hasSkills("keji|conghui") and (t:getHp() == 1 or self:getOverflow(t) > 2) then best_etarget = t end
	end
	if best_etarget then return best_etarget end
	if tars[1] then return tars[1] end
	if badtars[1] then return badtars[1] end
	return nil
end

sgs.ai_skill_invoke.protectdestroy = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end
sgs.ai_choicemade_filter.skillInvoke.protectdestroy = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, 50) end
	end
end

--界結姻
local married_skill={}
married_skill.name = "married"
table.insert(sgs.ai_skills, married_skill)
married_skill.getTurnUseCard=function(self)
	if self.player:isNude() or self.player:hasUsed("#married") then return nil end
	-- self.player:gainMark("@book")
	return sgs.Card_Parse("#married:.:")
end
-- sgs.ai_skill_use_func["#phantom"] = function(card, use, self)
sgs.ai_skill_use_func["#married"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	local use_card = nil
	self:sortByCardNeed(handcards, true)
	self:sortByCardNeed(equipments, true)
	self:sort(self.friends_noself, "hp")
	local target = nil
	
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			use_card = c
		end
	end
	
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() ~= self.player:getHp() or (friend:getHp() == self.player:getHp() and self.player:isWounded()) then
			target = friend
			break	--yun
		end
	end
	
	if self.player:getEquips():length() > 0 then
		for _,e in ipairs(equipments) do
			if not e:isKindOf("WoodenOx") then
				local equip_index = e:getRealCard():toEquipCard():location()
				for _, friend in ipairs(self.friends_noself) do
					if (friend:getHp() ~= self.player:getHp() or (friend:getHp() == self.player:getHp() and self.player:isWounded())) and friend:getEquip(equip_index) == nil then
						use_card = e
						target = friend
						break	--yun
					end
				end
			end
		end
	end
	if target == nil or use_card == nil then return end
	use.card = sgs.Card_Parse("#married:"..use_card:getId()..":")
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["married"] = 2.8

sgs.ai_card_intention["married"] = function(self, card, from, tos)
	-- if not from:hasFlag("jieyin_isenemy_"..tos[1]:objectName()) then
		sgs.updateIntention(from, tos[1], -80)
	-- end
end



local meleemaster_skill={}
meleemaster_skill.name="meleemaster"
table.insert(sgs.ai_skills,meleemaster_skill)

meleemaster_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local trickcard

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("TrickCard") then
			trickcard = card
			break
		end
	end

	if not trickcard then return nil end
	local suit = trickcard:getSuitString()
	local number = trickcard:getNumberString()
	local card_id = trickcard:getEffectiveId()
	local card_str = ("slash:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.meleemaster = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("TrickCard") and pattern == "jink" then
			return ("jink:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("TrickCard") and pattern == "slash" then
			return ("slash:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.meleemaster_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 3.8,
	FireSlash = 4.5,
	Slash = 3.8,
	ThunderSlash = 4.5,
	ExNihilo = 4.7,
	Nullification	= 5,
	Snatch 			= 5,
	Dismantlement 	= 5,
	Duel			= 5,
	ArcheryAttack 	= 4,
	FireAttack 		= 4,
	SavageAssault 	= 3.9,
	IronChain 		= 4,
	GodSalvation 	= 4,
	
	Indulgence 		= 5,
	SupplyShortage 	= 5,
	Lightning 		= 3.9
}

sgs.ai_can_damagehp.tacitunderstanding = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end


local weareidle_skill = {}
weareidle_skill.name = "weareidle"
table.insert(sgs.ai_skills, weareidle_skill)
weareidle_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#weareidle") then
		return sgs.Card_Parse("#weareidle:.:")
	end
	return false
end
sgs.ai_skill_use_func["#weareidle"] = function(card, use, self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("Dismantlement", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("Dismantlement", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit() and not svalueCard then
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end

	local targetA
	local targetB
	-- local targets = {}
	
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:objectName() ~= p:objectName() and self:isFriend(p) and (p:getCards("j"):length() > 0 or (p:getArmor() and (p:getArmor():getClassName() == "GaleShell" or (p:isWounded() and p:getArmor():getClassName() == "SilverLion"))))then
			if not targetA then
				targetA = p 
			elseif not targetB then
				targetB = p
			else
				break
			end
			-- if #targets >= 2 then
				-- break
			-- else
				-- table.insert(targets, p:objectName())
			-- end
		elseif not p:isNude() and not self:isFriend(p) then
			if not targetA then
				targetA = p 
			elseif not targetB then
				targetB = p
			else
				break
			end
			-- if #targets >= 2 then
				-- break
			-- else
				-- table.insert(targets, p:objectName())
			-- end
		end
	end

	if first_found and second_found and (targetA or targetB) then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local to_use = {first_id, second_id}
		local card_str = string.format("#weareidle:%s:", table.concat(to_use, "+"))
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(targetA)
			if targetB then use.to:append(targetB) end
			
		end
	end
end
sgs.ai_skill_cardchosen["weareidle"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.weareidle = sgs.ai_choicemade_filter.cardChosen.dismantlement
sgs.ai_use_value["weareidle"] = sgs.ai_use_value.Dismantlement
sgs.ai_use_priority["weareidle"] = sgs.ai_use_priority.Snatch
sgs.ai_card_intention["weareidle"] = sgs.ai_card_intention.Snatch

sgs.ai_skill_invoke.solidarity = function(self, data)
	return true
end

sgs.ai_skill_discard.listentonature = function(self, discard_num, min_num, optional, include_equip)
	local card_id = self.player:getMark("ltn_mark")
    local card = sgs.Sanguosha:getCard(card_id)     
	local cards = {}
	-- local cards = sgs.QList2Table(self.player:getCards("he"))
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isRed() and not (c:isKindOf("Peach") or (self.player:getHp() == 1 and c:isKindOf("Analeptic"))) then
			table.insert(cards, c)
		end
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
	else
		return {}
	end
	
	local cd = cards[1]
	local id = cd:getEffectiveId()
	-- if cd:isKindOf("Analeptic") or cd:isKindOf("Peach") then return {} end
	
	for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
		local callback = sgs.ai_cardneed[skill:objectName()]
		if type(callback) == "function" and callback(self.player, cd, self) then
			return {}
		end
		if type(callback) == "function" and callback(self.player, card, self) then
			return id
		end
	end
	
	if self:isValuableCard(cd, self.player) then return {} end
	if self:isValuableCard(card, self.player) then return id end

	return {}
end

sgs.ai_skill_invoke.migonoinori = function(self, data)
	return true
end

sgs.ai_skill_invoke.imwatching = function(self, data)
	-- local current = self.room:getCurrent()
	local current = data:toPlayer()
	-- current:gainMark("@book")
	if current:getHp() > 1 and self:isEnemy(current) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		local hasblackcard = false
		for _,card in ipairs(cards) do
			if card:isBlack() then
				hasblackcard = true
				break
			end
		end
		-- if not hasblackcard then return false end
		return hasblackcard
	elseif current:getHp() <= 1 then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@imwatching"] = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local choice
	for _,card in ipairs(cards)  do
		if not choice and card:isBlack() and not (self:isWeak(self.player) and self.player:isLord() and card:isKindOf("Analeptic")) then
			choice = card
		end
		if self.player:isWounded() and self.player:getArmor():getClassName() == "SilverLion" and card:isKindOf("SilverLion") then
			choice = card
			break
		end
	end
	return choice:getEffectiveId()
end

sgs.ai_choicemade_filter.skillInvoke.imwatching = function(self, player, promptlist)
	-- local current = self.room:getCurrent()
	-- local current = self.player:getTag("imwatching"):toPlayer()
	-- local current = data:toPlayer()
	-- current:gainMark("@book")
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		-- if p:hasFlag("Imw_target") then
		if p:getHp() > 1 and p:hasFlag("Imw_target") then
			p:setFlags("-Imw_target")
			if promptlist[#promptlist] == "yes" then
				sgs.updateIntention(self.player, p, 20)
			else
				sgs.updateIntention(self.player, p, 0)
			end
		end
	end
	-- if not current or current:getMark("imwatching_damage") < 1 then return end
	-- current:gainMark("@book")
	-- if promptlist[#promptlist] == "yes" then sgs.updateIntention(self.player, current, 15) end -- 單體回復這個會生效，雖然群回也有效
end

-- sgs.ai_skill_discard.listentonature = function(self, discard_num, min_num, optional, include_equip)
	-- local card_id = self.player:getMark("ltn_mark")
    -- local card = sgs.Sanguosha:getCard(card_id)     
	-- local cards = sgs.QList2Table(self.player:getCards("he"))
	-- self:sortByKeepValue(cards)
	
	-- local cd = cards[1]
	-- local id = cd:getEffectiveId()
	-- if cd:isKindOf("Analeptic") or cd:isKindOf("Peach") then return {} end
	
	-- for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
		-- local callback = sgs.ai_cardneed[skill:objectName()]
		-- if type(callback) == "function" and callback(self.player, cd, self) then
			-- return {}
		-- end
		-- if type(callback) == "function" and callback(self.player, card, self) then
			-- return id
		-- end
	-- end
	
	-- if self:isValuableCard(cd, self.player) then return {} end
	-- if self:isValuableCard(card, self.player) then return id end

	-- return {}
-- end

sgs.ai_skill_cardask["@bougairensha"] = function(self, data)
	local use = data:toCardUse()
	local from = use.from
	if self:isFriend(from) then return "." end
	local needprotect = false
	for _, p in sgs.qlist(use.to) do
		if (self:isFriend(p) or p:objectName() == self.player:objectName()) and self:isEnemy(from) then
			needprotect = true
		end
		if self:isEnemy(from) and self:isEnemy(p) then
			needprotect = true
		end
	end
	if not needprotect then return "." end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local choice
	for _,card in ipairs(cards)  do
		if not choice and card:isBlack() and not (self:isWeak(self.player) and self.player:isLord() and card:isKindOf("Analeptic")) then
			choice = card
		end
		if self.player:isWounded() and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" and card:isKindOf("SilverLion") then
			choice = card
			break
		end
	end
	if choice then
		return choice:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@bougairensha"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local use = self.room:getTag("bougairensha"):toCardUse()
		if not use.from then return end
		sgs.updateIntention(player, use.from, 80)
	end
end

-- sgs.ai_skill_cardask["@bougairensha_es"] = function(self) --舊壓制需要對方棄牌使用的
	-- local cuc = sgs.QList2Table(self.player:getCards("he"))
	-- local card_id = self.player:getMark("bes_mark")
    -- local usedc = sgs.Sanguosha:getCard(card_id)  
	-- local needuse = 0
	-- self:sortByUseValue(cuc,true)
	-- for _,c in ipairs(cuc)  do
		-- if c:isKindOf("TrickCard") or c:isKindOf("EquipCard") then
			-- needuse = needuse + 1
		-- end
	-- end
	-- if needuse < 2 and self.player:getHandcardNum() <= self.player:getHp() then return "." end
	-- for _,card in ipairs(cuc)  do
		-- if card:getSuit() == usedc:getSuit() and not (card:isKindOf("Peach") or (self:isWeak(self.player) and card:isKindOf("Analeptic"))) then
			-- return card:getEffectiveId()
		-- end
	-- end
	-- return "."
-- end

-- sgs.bougairensha_suit_value = {
	-- club = 4.2,
-- }
sgs.ai_cardneed.bougairensha = function(to, card, self)
	return card:isBlack()
end

sgs.ai_skill_invoke.sizukana = function(self, data)
	-- local current = self.room:getCurrent()
	local firends = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			firends:append(p)
		end
	end
	if firends:length() > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen["sizukana"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local good_tar = {}
	local normal_tar
	if self.player:getMark("@sizukana_mark") < 1 then return self.player end
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			if (self:isWeak(p) or p:getHp() == 1) and p:isLord() and p:getMark("@sizukana_mark") < 1 then return p end
			if self:isWeak(p) and p:getMark("@sizukana_mark") < 1 then table.insert(good_tar, p) end
			if p:getMark("@sizukana_mark") < 1 then normal_tar = p end
			-- if p:objectName() == self.player:objectName() then tomyself = p end
		end
	end
	if #good_tar > 0 then
		return good_tar[1]
	elseif normal_tar then
		return normal_tar
	end
	return self.player
end
-- sgs.ai_skill_playerchosen["sizukana"] = function(self, targets) --老版本使用
	-- local targets = sgs.QList2Table(targets)
	-- self:sort(targets, "hp")
	-- local good_tar
	-- local normal_tar
	-- for _,p in ipairs(targets) do
		-- if self:isFriend(p) then
			-- if (self:isWeak(p) or p:getHp() == 1) and p:isLord() then return p end
			-- if (self:isWeak(p) or p:getHp() == 1) and not p:hasSkill("buuzetsu") then good_tar = p end
			-- normal_tar = p
		-- end
	-- end
	-- if good_tar then
		-- return good_tar
	-- else
		-- return normal_tar
	-- end
	-- return nil
-- end
sgs.ai_playerchosen_intention.sizukana = function(self, from, to)
	sgs.updateIntention(from, to, -20)
end

local hononozouki_skill = {}
hononozouki_skill.name= "hononozouki"
table.insert(sgs.ai_skills, hononozouki_skill)
hononozouki_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#hononozouki:.:")
end

sgs.ai_skill_use_func["#hononozouki"] = function(card, use, self)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("hononozouki_used") == 0 then
			if self.player:objectName() ~= p:objectName() and self:isFriend(p) then
				use.card = sgs.Card_Parse("#hononozouki:.:")
				if use.to then use.to:append(p) end
				return
			end
		end
	end
	-- return nil
end

sgs.ai_card_intention["hononozouki"] = -20

sgs.ai_skill_invoke.hononochikara = function(self,data)
	local use = data:toCardUse() -- 經測試use.from抓對角色
	local aoeatk = false
	local letgo = 0
	if use.card:isKindOf("ExNihilo") then return false end
	if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then aoeatk = true end
	for _, p in sgs.qlist(use.to) do
		if not aoeatk and self:isFriend(p) then return false end
		if self:isEnemy(p) and not (p:hasSkill("shixin") or p:hasSkill("moekogoro") or self:hasEightDiagramEffect(p)) then
			letgo = letgo + 1
			if self:isWeak(p) and getCardsNum("Jink", p, self.player) == 0 then
				letgo = letgo + 1
			end
		end
		if self:isFriend(p) and not (p:hasSkill("shixin") or p:hasSkill("moekogoro") or self:hasEightDiagramEffect(p)) and getCardsNum("Jink", p, self.player) == 0 then
			letgo = letgo - 1
			if p:hasArmorEffect("Vine") then letgo = letgo - 2 end
			if self:isWeak(p) and getCardsNum("Peach", p, self.player) + getCardsNum("Analeptic", p, self.player) == 0 then
				letgo = letgo - 1
			end
		end
	end
	if letgo > 0 then
		return true
	else
		return false
	end
	
end


sgs.ai_can_damagehp.moekogoro = function(self,from,card,to)
	if card and sgs.card_damage_nature[card:getClassName()] == sgs.DamageStruct_Fire then
		return true
	end
end
sgs.ai_ajustdamage_to.moekogoro = function(self,from,to,card,nature)
	if nature=="F"
	then return -99 end
end

sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|wisdom_s"
sgs.ai_skill_cardask["@wisdom-card"]=function(self, data)
	local judge = data:toJudge()
	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

function sgs.ai_cardneed.wisdom_s(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.wisdom_s_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

sgs.ai_target_revises.yochi = function(to,card)
	if card:isKindOf("Slash") and to:canDiscard(to, "he")
	then return true end
end

local yomi_skill = {}
yomi_skill.name = "yomi"
table.insert(sgs.ai_skills, yomi_skill)
yomi_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	local active = false
	for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and not p:hasFlag("yomi_AI") then
			active = true
			break
        end
    end
	if active then
		return sgs.Card_Parse("#yomi:.:")
	end
end
sgs.ai_skill_use_func["#yomi"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and not p:hasFlag("yomi_AI") then
            use.card = sgs.Card_Parse("#yomi:.:")
            if use.to then use.to:append(p) end
            return
        end
    end
end

sgs.ai_use_priority["yomi"] = sgs.ai_use_priority.Dismantlement + 1.2

local kanchiskill = {}
kanchiskill.name = "kanchi"
table.insert(sgs.ai_skills, kanchiskill)
kanchiskill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#kanchi") then return false end
	return sgs.Card_Parse("#kanchi:.:")
end
sgs.ai_skill_use_func["#kanchi"] = function(card, use, self)
	self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			if self:isWeak(p) and self.player:canSlash(p, slash) and self:getCardsNum("Slash") > 0 then
				use.card = sgs.Card_Parse("#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
			if getCardsNum("Nullification", p, self.player) > 0 or p:hasSkill("kanpo") then
				use.card = sgs.Card_Parse("#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
			if getCardsNum("Peach", p, self.player) + getCardsNum("Analeptic", p, self.player) > 0 then
				use.card = sgs.Card_Parse("#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
        end
    end
	 for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then
			use.card = sgs.Card_Parse("#kanchi:.:")
			if use.to then
				use.to:append(p)
			end
		end
	end
	return
end

sgs.ai_use_value["kanchi"] = 3.5
sgs.ai_use_priority["kanchi"] = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_card_intention["kanchi"] = 30

sgs.ai_skill_invoke.yuri_guixin = function(self, data)
	return true
end
sgs.ai_skill_choice["yuri_guixin"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:needKongcheng(target, true) then
		return "yg_dis"
	else
		return "yg_obtain"
	end
end
sgs.ai_need_damaged.yuri_guixin = sgs.ai_need_damaged.guixin

sgs.ai_skill_cardchosen["yuri_guixin"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:isKindOf("Weapon") or card:isKindOf("DefensiveHorse") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_choicemade_filter.skillChoice.yuri_guixin = function(self, player, promptlist)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("yuri_guixinUsing") then
			to = p
			p:setFlags("-yuri_guixinUsing")
			break
		end
	end
	local choice = promptlist[#promptlist]
	if choice == "yg_obtain" and not self:needKongcheng(to, true) then
		-- to:gainMark("@book") --經測試有效
		sgs.updateIntention(player, to, 80)
	elseif choice == "yg_dis" then
		sgs.updateIntention(player, to, -60)
	end
end

local barakurosaku_skill = {}
barakurosaku_skill.name = "barakurosaku"
table.insert(sgs.ai_skills, barakurosaku_skill)
barakurosaku_skill.getTurnUseCard = function(self)
	if self.player:isNude() or self.player:usedTimes("#barakurosaku") >= 3 + self.player:getMark("okanemochi_maxh") then return end
	if self.player:getMark("@ChangeSkill3") > 0 and self.player:getHp() < 2 and self:damageIsEffective(self.player, nil, self.player) and (self:getCardsNum("Peach") < 1 or self:getCardsNum("Analeptic") < 1) then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)	
	if cards[1]:isKindOf("Peach") then return end
	return sgs.Card_Parse("#barakurosaku:" .. cards[1]:getId().. ":")
end
sgs.ai_skill_use_func["#barakurosaku"] = function(card, use, self)
	-- if self.player:getHp() > 2 or (self.player:getHp() - self.player:getHandcardNum() >= 2) or not self:damageIsEffective(self.player, nil, self.player) then
	local target
	if self.player:getMark("@ChangeSkill3") > 0 then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
	if self.player:getMark("@ChangeSkill1") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHp() > 2 and ((friend:hasSkill("weareidle") or self:needToLoseHp(friend, self.player)) or not self:damageIsEffective(friend, nil, self.player)) then
				target = friend
				break
			end
		end
		if not target then
			self:sort(self.enemies, "hp")
			for _, enemy in ipairs(self.enemies) do
				if self:isWeak(enemy) and enemy:getHp() < 2 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and not (self:needToLoseHp(enemy, self.player, nil, true)) then 
					target = enemy
					break 
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) 
				and not (self:needToLoseHp(enemy, self.player, nil, true)) then 
					target = enemy
					break 
				end
			end
		end
		
		-- if not target then
			-- for _, friend in ipairs(self.friends) do
				-- if self:damageIsEffective(friend, nil, self.player) and (self:getDamagedEffects(friend, self.player) or self:needToLoseHp(friend, self.player, nil, true) or friend:hasSkill("weareidle")) then 
					-- target = friend
					-- break
				-- end
			-- end
		-- end
		
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHp() < 3 and not self:cantbeHurt(enemy) then 
					target = enemy
					break 
				end
			end
		end
		
		if not target then return end
		use.card = card
		if use.to then use.to:append(target) end
		return
	elseif self.player:getMark("@ChangeSkill2") > 0 then
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() and (friend:getCards("he"):length() < 2 or friend:hasSkills("kongcheng|lianying|noslianying|tuntian") or (friend:hasSkill("xiaoji") and friend:getCards("e"):length() > 0)) then
				target = friend
				break
			end
		end
		-- if target:objectName() == self.player:objectName() and self.player:getCards("he"):length() <= 3 and self:getCardsNum("Peach") > 1 then target = nil end
		if not target then
			for _, friend in ipairs(self.friends) do
				if friend:isWounded() or friend:hasSkill("tuntian") or (friend:hasSkill("kongcheng") and friend:getHandcardNum() > 0) or (friend:hasSkill("xiaoji") and friend:getCards("e"):length() > 0)
				and not (friend:objectName() == self.player:objectName() and self.player:getCards("he"):length() <= 3 and self:getCardsNum("Peach") > 1) then
					target = friend
					break
				end
			end
		end
		
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isWounded() and not (enemy:hasSkills("kongcheng|lianying|noslianying|tuntian") or (enemy:hasSkill("xiaoji") and enemy:getCards("e"):length() > 0)) then 
					target = enemy
					break 
				end
			end
		end
		
		if not target then return end
		use.card = card
		if use.to then use.to:append(target) end
		return
		
	end
end

sgs.ai_use_priority.barakurosaku = sgs.ai_use_priority.Slash + 1

sgs.ai_card_intention.barakurosaku = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if from:getMark("@ChangeSkill1") > 0 and to:getHp() > 2 and (self:needToLoseHp(to, from, nil, true) or to:hasSkill("weareidle")) then
			sgs.updateIntention(from, to, -30)
		elseif from:getMark("@ChangeSkill2") > 0 then
			if to:isWounded() then
				sgs.updateIntention(from, to, -40)
			elseif not (to:hasSkills("kongcheng|lianying|noslianying|tuntian") or (to:hasSkill("xiaoji") and to:getCards("e"):length() > 0)) then
				sgs.updateIntention(from, to, 20)
			end
		end
	end
end


sgs.ai_skill_invoke.kanshi = function(self, data)
	local useto = data:toPlayer()
	if self:isFriend(useto) then
		if self:needKongcheng(useto, false) then return false end
		return true
	else
		if self:isEnemy(useto) and self:needKongcheng(useto, false) and useto:getHandcardNum() == 0 then return true end
		return false
	end
	return false
end

-- sgs.ai_choicemade_filter.skillInvoke["kanshi"] = function(self, player, promptlist)
	-- local tar = data:toPlayer()
	-- if promptlist[#promptlist] == "yes" then
		-- sgs.updateIntention(self.player, damage.to, -60)
	-- end
-- end
sgs.ai_choicemade_filter.skillInvoke.kanshi = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		-- target:gainMark("@book")
		if target and not self:needKongcheng(target, false) then sgs.updateIntention(player, target, -40) end
	end
end

sgs.ai_skill_invoke.kanshi_dis = function(self, data)
	local useto = data:toPlayer()
	if self:isFriend(useto) then
		if self:needKongcheng(useto, false) and useto:getHandcardNum() == 1 then return true end
		if useto:getCards("j"):length() > 0 or (useto:getArmor() and (useto:getArmor():getClassName() == "GaleShell" or (useto:isWounded() and useto:getArmor():getClassName() == "SilverLion"))) then return true end
		return false
	else
		if self:isEnemy(useto) and self:needKongcheng(useto, false) and useto:getCards("he"):length() == 1 and useto:getHandcardNum() == 1 then return false end
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["kanshi"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
		for _,card in sgs.qlist(who:getCards("h")) do
			if self:needKongcheng(who, false) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.kanshi = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_playerchosen.genjutsu = function(self, targets)
	local card = sgs.Sanguosha:getCard(self.player:getPile("gensou"):first())
	local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
	slash:addSubcard(card)
	slash:setSkillName("genjutsuslash")
	slash:deleteLater()
	targets = sgs.QList2Table(targets)
	local dummy_use = self:aiUseCard(slash, dummy())
	if dummy_use.card and dummy_use and dummy_use.to then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	return nil
end
sgs.ai_use_revises.genjutsu = function(self,card,use)
	if card:isKindOf("Slash") and card:getSkillName() == "genjutsuslash" then
		card:setFlags("Qinggang")
	end
end

sgs.ai_playerchosen_intention["tsuyoiishiki"] = function(self, from, to)
	sgs.updateIntention(from, to, -30)
end

-- sgs.ai_skill_invoke.tsuyoiishiki = function(self, data)
	-- return true
-- end

sgs.ai_skill_playerchosen.tsuyoiishiki = function(self, targets)
	self:updatePlayers()
	local best_target = nil
	local friendtars = {}
	self:sort(self.friends, "defense")
	for _, f in ipairs(self.friends) do
		table.insert(friendtars, f)
		if (self:isWeak(f) and f:isNude()) and not f:hasSkills(sgs.need_kongcheng) then best_target = f end
	end
	if best_target then return best_target end
	return friendtars[1]
end

sgs.ai_view_as.countertrick = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and not (card:isKindOf("BasicCard") or card:isKindOf("Nullification")) and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("nullification:countertrick[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_card_priority.countertrick = function(self,card)
	if card:getSkillName()=="countertrick"
	then
		return 1
	end
end

local unlock_skill = {}
unlock_skill.name= "unlock"
table.insert(sgs.ai_skills,unlock_skill)
unlock_skill.getTurnUseCard=function(self)
	self:updatePlayers()
	local var = 0
	if self.player:getMark("@kiyoi_coin") < 3 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHandcardNum() > 2 then 
				var = var + 1
			end
			if enemy:getHandcardNum() > 4 then
				var = var + 1
			end
		end
		if var < 2 then return false end
	end
	-- self.player:gainMark("@book", var)
	if (not self.player:hasUsed("#unlock")) then
		return sgs.Card_Parse("#unlock:.:")
	end
end

sgs.ai_skill_use_func["#unlock"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["unlock"] = 3.5
sgs.ai_use_priority["unlock"] = sgs.ai_use_priority.Slash + 1

local peeking_skill = {}
peeking_skill.name= "peeking"
table.insert(sgs.ai_skills,peeking_skill)
peeking_skill.getTurnUseCard=function(self)
	self:updatePlayers()
	local tars = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			if not (self:isFriend(p) and p:getHandcardNum() > 3) then
				tars = tars + 1
			end
		end
	end
	-- if self:isWeak(self.player) then var = var + 2 end
	if tars == 0 then return false end
	if (not self.player:hasUsed("#peeking")) then
		return sgs.Card_Parse("#peeking:.:")
	end
end

sgs.ai_skill_use_func["#peeking"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	local basic_count = 0
	local trick_count = 0
	local equip_count = 0

	for _, enemy in ipairs(self.enemies) do
		local cards = enemy:getHandcards()
		if enemy:getHandcardNum() > 6 then best_target = enemy break end
		if not enemy:isKongcheng() then
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if card:hasFlag("visible") or card:hasFlag(flag) then
					if card:isKindOf("BasicCard") then
						basic_count = basic_count+1
					end
					if card:isKindOf("TrickCard") then
						trick_count = trick_count+1
					end
					if card:isKindOf("EquipCard") then
						equip_count = equip_count+1
					end
				end
			end
			enemy:removeMark("basic_count_pm" ,enemy:getMark("basic_count_pm")) --就算只有一個敵人也會運行兩次，只好這麼寫
			enemy:removeMark("trick_count_pm" ,enemy:getMark("trick_count_pm"))
			enemy:removeMark("equip_count_pm" ,enemy:getMark("equip_count_pm"))
			if basic_count > 0 and enemy:getMark("basic_count_pm") == 0 then enemy:addMark("basic_count_pm", basic_count) end
			if trick_count > 0 and enemy:getMark("trick_count_pm") == 0 then enemy:addMark("trick_count_pm", trick_count) end
			if equip_count > 0 and enemy:getMark("equip_count_pm") == 0 then enemy:addMark("equip_count_pm", equip_count) end
			-- self.player:gainMark("@bear")
			if basic_count > 3 or trick_count > 3 or equip_count > 3 then best_target = enemy break end --直接讓他失去技能
			if basic_count > 2 or trick_count > 1 or equip_count > 0 or enemy:getHandcardNum() > 3 then table.insert(good_targets, enemy) end
			
			table.insert(targets, enemy)
			basic_count = 0
			trick_count = 0
			equip_count = 0
		end
	end
	if not best_target and #good_targets == 0 and #targets == 0 then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() then
				if friend:getHandcardNum() < 4 then
					table.insert(targets, friend)
				end
			end
		end
	end
	use.card = sgs.Card_Parse("#peeking:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		elseif #targets > 0 then
			use.to:append(targets[1])
		end
	end
	return
end

sgs.ai_use_value["peeking"] = 4
sgs.ai_use_priority["peeking"] = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_skill_choice.peeking = function(self, choices, data)
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("peeking_AI") > 0 then
			target = p
			break
		end
	end
	if self:isFriend(target) then return "BasicCard" end
	if self:isEnemy(target) then
		if target:getMark("basic_count_pm") > 3 then return "BasicCard" end
		if target:getMark("trick_count_pm") > 3 then return "TrickCard" end
		if target:getMark("equip_count_pm") > 3 then return "EquipCard" end
		
		if target:getMark("basic_count_pm") > 2 then return "BasicCard" end
		if target:getMark("trick_count_pm") > 0 then return "TrickCard" end
		if target:getMark("equip_count_pm") > 0 then return "EquipCard" end
		
		-- if target:getHandcardNum() > 6 then return "BasicCard" end
		return "BasicCard"
	end
	return false
end

sgs.ai_skill_cardchosen["peeking"] = function(self, who, flags)
	if not self:isEnemy(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			return card
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("e")) do
			if not who:isWounded() and card:isKindOf("SilverLion") then
				table.insert(goodchice, card)
			end
			if card:isKindOf("Weapon") or card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_choicemade_filter.skillChoice.peeking = function(self, player, promptlist)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("peekingUsing") then
			to = p
			p:setFlags("-peekingUsing")
			break
		end
	end
	local choice = promptlist[#promptlist]
	if choice == "BasicCard" then
		local int = 0
		if to:getMark("basic_count_pm") > 2 then int = int + 30 end
		if to:getHandcardNum() > 5 then int = int + 30 end
		sgs.updateIntention(player, to, int)
	else
		sgs.updateIntention(player, to, 60)
	end
end


sgs.ai_skill_invoke.songforatsu = function(self, data)
	local dying = data:toDying()
	local who = dying.who
	if self:isFriend(who) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.songforatsu = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		sgs.updateIntention(player, target, -50)
	end
end

sgs.ai_skill_invoke.lovetoevo = function(self, data)
	if sgs.turncount <= 1 and self.role ~= "rebel" and sgs.playerRoles.rebel == 0 then return false end	--yun
	if self:getCardsNum("Peach") > 0 then return false end
	return true
end

local buuzetsu_skill = {}
buuzetsu_skill.name = "buuzetsu"
table.insert(sgs.ai_skills, buuzetsu_skill)
buuzetsu_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if self:slashIsAvailable() then
			if card:isRed() then
				return sgs.Card_Parse(("fire_slash:buuzetsu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
			else
				return sgs.Card_Parse(("thunder_slash:buuzetsu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
			end
		end
	end
end
sgs.ai_view_as.buuzetsu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		if card:isRed() then
			return ("fire_slash:buuzetsu[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("thunder_slash:buuzetsu[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_ajustdamage_to.buuzetsu = function(self,from,to,card,nature)
	if (card and card:isKindOf("TrickCard")) or not from then
		return -99
	end
	if to:getMark("@SuperLimitBreak") > 0 and to:isKongcheng() then
		return -1
	end
end


local zurunoonkaeshi_skill = {}
zurunoonkaeshi_skill.name = "zurunoonkaeshi"
table.insert(sgs.ai_skills, zurunoonkaeshi_skill)
zurunoonkaeshi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#zurunoonkaeshi") then return end
	local no_need = true
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			no_need = false
			break
		end
	end
	if self.player:hasSkills(sgs.bad_skills) then return sgs.Card_Parse("#zurunoonkaeshi:.:") end
	if self.player:isNude() or no_need then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)	
	if cards[1]:isKindOf("Peach") then return end
	return sgs.Card_Parse("#zurunoonkaeshi:" .. cards[1]:getId().. ":")
end
sgs.ai_skill_use_func["#zurunoonkaeshi"] = function(card, use, self)
	self:sort(self.friends, "hp")
	local tar
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			tar = friend
			break
		end
	end
	if tar then
	if card then
		use.card = card
	else
		use.card = sgs.Card_Parse("#zurunoonkaeshi:.:")
	end
	if use.to and tar then use.to:append(tar) end
	end
	return
end

sgs.ai_skill_choice.zurunoonkaeshi = function(self, choices, data)
	choices = choices:split("+")
	for _, name in ipairs(choices) do
		if string.find(sgs.bad_skills, name) then
			return name
		end
	end
	return false
end

sgs.ai_use_priority.zurunoonkaeshi = sgs.ai_use_priority.Peach - 1
sgs.ai_card_intention["zurunoonkaeshi"] = -60

sgs.ai_skill_invoke.haigu = function(self, data)
	return true
end

sgs.ai_skill_use["@@haigu"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.friends, "defense")
	local selectset = {}
	for _,f in ipairs(self.friends) do
		table.insert(selectset, f:objectName())
		if #selectset > 4 then break end
	end
	if #selectset > 0 then
		return "#haigu:.:->"..table.concat(selectset, "+")
	else
		return "."
	end
    return "."
end

sgs.ai_card_intention["haigu"] = -40

sgs.ai_skill_playerchosen["haigu"] = function(self, targets)
	-- local targets = sgs.QList2Table(targets)
	local tar
	local count = 0
	for _,target in sgs.qlist(targets) do
		count = 0
		if self.player:getPile("haigu_pile"):length() > 3 then break end
		if self:isFriend(target) then
			if target:getCards("j"):length() > 0 then
				for _,jc in sgs.qlist(target:getCards("j")) do
					if not jc:isKindOf("YanxiaoCard") then
						count = count + 1
					end
				end
			end
			if target:isWounded() and target:getArmor() and target:getArmor():getClassName() == "SilverLion" then count = count + 2 end
			
			if self.player:getPile("haigu_pile"):length() <= count then tar = target end
		end
	end
	if not tar then
		local findmax = 0
		local curtar
		-- self.player:gainMark("@book")
		for _,target in sgs.qlist(targets) do
			if not self:isFriend(target) then
				if target:getCards("he"):length() > findmax then
					findmax = target:getCards("he"):length()
					curtar = target
				end
			end
		end
		tar = curtar
	end
	if tar then
		return tar
	else
		return nil
	end
end

sgs.ai_skill_cardchosen["haigu"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card 
			-- end
			-- if card:getClassName() == "GaleShell" or (card:isKindOf("DelayedTrick") and not card:isKindOf("YanxiaoCard")) then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.haigu = sgs.ai_choicemade_filter.cardChosen.dismantlement

-- sgs.ai_skill_invoke.yuri_hagaku = function(self, data)
	-- return true
-- end

sgs.ai_skill_invoke.kirisou = function(self, data)
	local current = data:toPlayer()
	if self:isEnemy(current) or (self:isFriend(current) and ((current:getArmor() and (current:getArmor():getClassName() == "GaleShell" or (current:isWounded() and current:getArmor():getClassName() == "SilverLion"))) or (current:getTreasure() and current:getHandcardNum() < 4 and current:getTreasure():isKindOf("Tianjitu")))) then
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["kirisou"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				return card 
			end
			if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				return card
			end
			if card:getClassName() == "Tianjitu" and who:getHandcardNum() < 4 then
				return card
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not who:isWounded() and card:getClassName() == "SilverLion" then
				table.insert(goodchice, card)
			end
			if card:getClassName() == "EightDiagram" or card:getClassName() == "Vine" or card:getClassName() == "RenwangShield" or card:getClassName() == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_skill_choice.kirisou = function(self, choices, data)
	local target = data:toPlayer()
	if self:isEnemy(target)  then
		local use = self.room:getTag("kirisou"):toCardUse()
		local dummy_use = self:aiUseCard(use.card, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			if math.random() < 0.5 or self.player:getHandcardNum() < 2 then
				return "kirisou_ea"
			end
			return "kirisou_e2"
		end
	end
	return "kirisou_e1"
end

local gopugu_skill = {}
gopugu_skill.name = "gopugu"
table.insert(sgs.ai_skills,gopugu_skill)
gopugu_skill.getTurnUseCard = function(self)
    if not self.player:isNude() then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local ecards = sgs.QList2Table(self.player:getCards("e"))
		self:sortByUseValue(cards,true)
		for _,card in ipairs(ecards) do
			local card_str = ("#gopugu:"..card:getId()..":")
			if self.player:isWounded() and card:getClassName() == "SilverLion" then return sgs.Card_Parse(card_str) end
			if self.player:getHandcardNum() < 4 and card:getClassName() == "Tianjitu" then return sgs.Card_Parse(card_str) end
		end
		for _,card in ipairs(cards) do
			-- self.player:gainMark("&test")
			local card_str = ("#gopugu:"..card:getId()..":")
			if card:isKindOf("TrickCard") then
				local dummy_use = self:aiUseCard(card, dummy())
    			if dummy_use.card and dummy_use and dummy_use.to then
					continue
				end
				return sgs.Card_Parse(card_str)
			end
			if card:isKindOf("Weapon") and self.player:getWeapon() then return sgs.Card_Parse(card_str) end
			if card:isKindOf("Armor") and self.player:getArmor() then return sgs.Card_Parse(card_str) end
			if card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then return sgs.Card_Parse(card_str) end
			if card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then return sgs.Card_Parse(card_str) end
			if card:isKindOf("Treasure") and self.player:getTreasure() then return sgs.Card_Parse(card_str) end
		end
	end
end

sgs.ai_skill_use_func["#gopugu"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["gopugu"] = 4
sgs.ai_use_priority["gopugu"] = 8

--對應界線突破後的三好
sgs.ai_skill_discard.kirisou_umaretuski = function(self)
	-- self.player:gainMark("&test")
	local to_cards = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	-- self.player:gainMark("&test")
	local effect = self.player:getTag("SlashMissed"):toSlashEffect()
	local to = effect.to
	if #cards < 3 or self:isFriend(to) then return true end
	return false
end

sgs.ai_view_as.yuri_hagaku = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() and (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) then
		return ("nullification:yuri_hagaku[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.yuri_hagaku = function(to, card, self)
	return card:isBlack()
end

sgs.ai_skill_invoke.yuri_hagaku = function(self, data)
	return true
end

local new_againstdis_skill={}
new_againstdis_skill.name="new_againstdis"
table.insert(sgs.ai_skills,new_againstdis_skill)
new_againstdis_skill.getTurnUseCard=function(self,inclusive)
	local DiscardPile = self.room:getDiscardPile()
	if (not self.player:hasUsed("#new_againstdis")) and DiscardPile:length() > 1 then
		local card_str = ("#new_againstdis:%d:")
		return sgs.Card_Parse(card_str)
	end
	return false
end

sgs.ai_skill_use_func["#new_againstdis"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["new_againstdis"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["new_againstdis"] = sgs.ai_use_priority.ExNihilo - 1

sgs.ai_target_revises.helmet = function(to,card,self)
	if card:isKindOf("Slash") and not (card:isKindOf("ThunderSlash") or card:isKindOf("FireSlash"))
	then return true end
end

sgs.ai_skill_use["@@hunnshin"] = function(self, prompt)
    self:updatePlayers(true)
	--選手牌丟棄
	local card_to_use = {}
	local needpeach = false
	local needachol = false
	-- self.player:gainMark("&test")
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if self:isWeak(self.player) then
		needpeach = true
		needachol = true
	end
	if not needpeach then
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				needpeach = true
			end
		end
	end
	-- if needpeach or needachol then
		for _, c in ipairs(cards) do
			if (needpeach and not c:isKindOf("Peach")) or (needachol and not c:isKindOf("Analeptic")) or (not needpeach and not needachol) then
				-- self.player:gainMark("&test")
				table.insert(card_to_use, c:getId())
			end
			if #card_to_use >= 2 then break end
		end
	-- end
	-- self.player:gainMark("&test")
	--手牌選完選人
    local targets = {}
	self:sort(self.friends, "chaofeng")
	local fs = {}
	for _,f in ipairs(self.friends) do
		if f:getPile("MWCreate"):isEmpty() then
			table.insert(fs, f:objectName())
		end
    end
    for _,f in ipairs(self.friends) do
		if f:getPile("MWCreate"):isEmpty() and (f:hasSkills(sgs.need_equip_skill .. "|clearthemeridians|hunnshin|witty")) then
			table.insert(targets, f:objectName())
			table.removeOne(fs, f:objectName())
		end
		if #targets >= #card_to_use then break end
    end
	-- self.player:gainMark("&test")
	if #targets < #card_to_use and #fs > 0 then
		local formax = #fs
		for n = 1, formax do
			table.insert(targets, fs[n])
			if #targets >= #card_to_use then break end
		end
	end
	-- self.player:gainMark("&test")
	if #targets == 0 then return nil end
    -- return "#hunnshin:.:->"..table.concat(targets, "+") --看這個式子(不用棄牌版)，可以研究出底下的式子
	return "#hunnshin:"..table.concat(card_to_use, "+")..":->"..table.concat(targets, "+")
end

sgs.ai_card_intention.hunnshin = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		local intention = -25
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_choice.tennsainohojyou = function(self, choices, data)
	-- local name = self.room:getTag("tennsainohojyou"):toString()
	-- if name == "" then return "cancel" end
	-- local target = nil
	-- for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		-- if p:objectName() == name then
			-- target = p
			-- break
		-- end
	-- end
	-- if self:isFriend(target) then return "cancel" end
	-- if not self:isWeak(self.player) then return "gogetit" end
	-- self.player:gainMark("&test")
	local jcn = self.player:getCards("j"):length()
	local ecn = self.player:getCards("e"):length()
	local hcn = self.player:getCards("h"):length()
	
	local n = jcn
	-- if jcn > 0 then return n = n+1 end
	if ecn > 0 then
		-- self.player:gainMark("&test")
		if self.player:getArmor() and self.player:getArmor():getClassName() == "GaleShell" then n=n+1 end
		if self.player:isWounded() and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" then n=n+1 end
		if self.player:getTreasure() and self.player:getTreasure():getClassName() == "Tianjitu" and self.player:getHandcardNum() < 4 then n=n+1 end
	end
	if hcn > 0 then
		local needpeach = false
		local needachol = false
		if self:isWeak(self.player) then
			needpeach = true
			needachol = true
		end
		if not needpeach then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) then
					needpeach = true
				end
			end
		end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _ ,c in ipairs(cards) do
			if (needpeach and not c:isKindOf("Peach")) or (needachol and not c:isKindOf("Analeptic")) or (not needpeach and not needachol and not c:isKindOf("nullification")) then n=n+1 end
		end
	end
	n = math.min(3, n)
	-- self.player:gainMark("&test" ,n)
	if n > 0 then return n end
	return "cancel"
end
sgs.ai_skill_cardchosen["tennsainohojyou"] = function(self, who, flags)
	-- if self:isFriend(who) then
	--經過測試，用底下那個sgs.QList2Table(cards) 循環換用 ipairs的，用於此處也有一樣的效果，但為了拋棄J，寫不同的方式較省
		for _,card in sgs.qlist(who:getCards("ej")) do
			-- if card:getClassName() == "SilverLion" and who:isWounded() and who:getCards("j"):length() == 0 then 
				-- return card
			-- end
			-- if card:getClassName() == "GaleShell" and who:getCards("j"):length() == 0 then
				-- return card
			-- end
			-- if card:isKindOf("DelayedTrick") then
				-- return card
			-- end
			-- if card:getClassName() == "Tianjitu" and who:getHandcardNum() < 4 then
				-- return card
			-- end
			if Q_goodToThrow(who, card, true) then return card end
		end
		local cards = self.player:getCards("he")
		local tothrow
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local needpeach = false
		local needachol = false
		if self:isWeak(self.player) then
			needpeach = true
			needachol = true
		end
		if not needpeach then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) then
					needpeach = true
				end
			end
		end
		for _,c in ipairs(cards) do
			if (needpeach and not c:isKindOf("Peach")) or (needachol and not c:isKindOf("Analeptic")) or (not needpeach and not needachol and not c:isKindOf("nullification")) then
				tothrow = c
				break
			end
		end
		if tothrow then return tothrow end
	-- end
	return nil
end
-- sgs.ai_choicemade_filter.cardChosen.tennsainohojyou = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_skill_invoke.jiyuunokuni = function(self,data)
	local target = data:toPlayer()
	local n = 0
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local lcard = self.player:getHandcards():first()
	if self:isFriend(target) then
		if self:isWeak(self.player) and not self:isWeak(target) then
			if self:needKongcheng(self.player) and self.player:getHandcardNum() == 1 and not (self:isWeak(self.player) and lcard:isKindOf("Analeptic")) then
				return true
			end
			for _,c in ipairs(cards) do
				if c:isKindOf("Peach") or c:isKindOf("Analeptic") then n=n+1 end
			end
			if n == 1 and self.player:getHandcardNum() < 2 then
				return false
			end
		end
	else
		if self:needKongcheng(self.player) and self.player:getHandcardNum() == 1 and not (lcard:isKindOf("Peach") or (self:isWeak(self.player) and lcard:isKindOf("Analeptic"))) then
			return true
		end
		for _,c in ipairs(cards) do
			if c:isKindOf("Peach") or (self:isWeak(self.player) and c:isKindOf("Analeptic")) then n=n+1 end
			if (not self:isWeak(self.player)) and c:isKindOf("TrickCard") and not c:isKindOf("Lightning") then n=n+1 end
			if (not self:isWeak(self.player)) and (c:isKindOf("Weapon") or c:isKindOf("Armor")) then n=n+1 end
		end
		if n == self.player:getHandcardNum() then
			return false
		end
	end
	return true
end

sgs.ai_skill_invoke.yuryounowaku = function(self,data)
	local target = data:toPlayer()
	local cards = self.player:getCards("jhe")
	cards = sgs.QList2Table(cards)
	-- target:gainMark("&test") -- player
	-- self.player:gainMark("@cupcake") --source
	if self:isFriend(target) then
		if target:getTreasure() and target:getTreasure():getClassName() == "WoodenOx" and target:getPile("wooden_ox"):length() > 0 then return false end
		for _,card in sgs.qlist(target:getCards("je")) do
			if Q_goodToThrow(target, card, true) then return true end
		end
		if (self:isWeak(target) and self:getCardsNum("Peach") > 0 and getCardsNum("Peach", target) < self:getCardsNum("Peach")) or target:isKongcheng() then return true end
		if (getCardsNum("Peach", target) > 0 and target:isWounded()) or target:getCards("e"):length() > 2 or target:getHandcardNum() > self.player:getHandcardNum()+1
		or self.player:isKongcheng() then return false end
		for _,c in ipairs(cards) do
			if c:isAvailable(target) then return true end
		end
	else
		if (target:isWounded() and self:getCardsNum("Peach") > 0) or target:isKongcheng() then return false end
		if target:getTreasure() and target:getTreasure():getClassName() == "WoodenOx" and target:getPile("wooden_ox"):length() > 1 then return true end
		for _,card in sgs.qlist(target:getCards("je")) do
			if Q_goodToThrow(target, card, true) then return false end
		end
		if (getCardsNum("Peach", target) > 0 and target:isWounded()) or target:getCards("e"):length() > 1 or target:getHandcardNum() > self.player:getHandcardNum()+1
		or self.player:isKongcheng() then return true end
		for _,c in ipairs(cards) do
			if c:isAvailable(target) then return false end
		end
	end
	return false
end

--觀百
sgs.ai_skill_discard.yurimi = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
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
sgs.ai_skill_use["@@yurimi"] = function(self, prompt)
	local pile = self.player:getPile("yurimipile")
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if pile:isEmpty() or (#cards == 0) then
		return "."
	end
	local max_num = pile:length()
	local n = 0
	for _, card_id in sgs.qlist(pile) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local exchange_to_pile = {}
	self:sortByCardNeed(cards, false)

	for _,card in ipairs(cards) do
		if Q_goodToThrow(self.player, card, false) then
			-- self.player:gainMark("@cupcake")
			table.insert(exchange_to_pile, card)
			n = n+1
			if n >= max_num then break end
		end
	end

	if n < max_num then
		for _,card in ipairs(cards) do
			table.insert(exchange_to_pile, card)
			n = n+1
			if n >= max_num then break end
		end
	end

	if #exchange_to_pile == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end
		-- self.player:gainMark("&test")
	return "#yurimi:"..table.concat(exchange, "+")..":"
end
sgs.ai_skill_invoke.yurimi = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) and not (self:needKongcheng(target) and target:isKongcheng()) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.yurimi = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, -30) end
	end
end

--百橫
sgs.ai_skill_playerchosen.yuri_hengjiang = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self:sort(self.enemies, "defense")
	self:sort(self.friends_noself, "defense")
	for _, e in ipairs(self.enemies) do
		if e:getMark("@yuri_hengjiang") == 0 then
			table.insert(targets, e)
			if (not self:needKongcheng(e)) or (self:needKongcheng(e) and getCardsNum("Peach", e, self.player) > 0 and e:getHp() == 1) then
				if self:isWeak(e) then table.insert(good_targets, e) end
				if e:getHp() == 1 then best_target = e end
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("@yuri_hengjiang") < 2 then
			if self:needKongcheng(friend) and getCardsNum("Peach", friend, self.player) < 1 then table.insert(good_targets, friend) end
		end
	end
	--全部人都發標記為重
	for _, e in ipairs(self.enemies) do
		if e:getMark("@yuri_hengjiang") > 0 then
			table.insert(targets, e)
		end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	if #targets > 0 then return targets[1] end
	return nil
end
sgs.ai_playerchosen_intention["yuri_hengjiang"] = function(self, from, to)
	if not self:needKongcheng(to) then
		sgs.updateIntention(from, to, 40)
	end
end



--碎閃
local kurashinfurashu_skill = {}
kurashinfurashu_skill.name= "kurashinfurashu"
table.insert(sgs.ai_skills,kurashinfurashu_skill)
kurashinfurashu_skill.getTurnUseCard=function(self)
	-- self:updatePlayers()
	local var = 0
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then 
			var = var + 1
		end
	end
	if var == 0 then return false end
	if (not self.player:hasUsed("#kurashinfurashu")) then
		return sgs.Card_Parse("#kurashinfurashu:.:")
	end
end

sgs.ai_skill_use_func["#kurashinfurashu"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			if self:isWeak(enemy) and enemy:getHandcardNum() == 1 and not self:needKongcheng(enemy) then
				best_target = enemy
				break
			end
			if self:isWeak(enemy) and (getCardsNum("Peach", enemy, self.player) > 0 or getCardsNum("Analeptic", enemy, self.player) > 0) then
				table.insert(good_targets, enemy)
			else
				table.insert(targets, enemy)
			end
		end
	end
	use.card = sgs.Card_Parse("#kurashinfurashu:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		elseif #targets > 0 then
			use.to:append(targets[1])
		end
		return
	end
end

sgs.ai_use_value["kurashinfurashu"] = 3.5
sgs.ai_use_priority["kurashinfurashu"] = sgs.ai_use_value.Slash - 0.1
sgs.dynamic_value.damage_card["kurashinfurashu"] = true
sgs.ai_card_intention["kurashinfurashu"] = 50

sgs.ai_skill_playerchosen.kurashinfurashu = function(self, targets)
	self:updatePlayers()
	local ispeach = false
	if self.player:getMark("kurashu_ai_p") == 1 then ispeach = true end
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self:sort(self.friends, "hp")
	if ispeach then
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() then
				table.insert(targets, friend)
				if self:isWeak(friend) and friend:objectName() ~= self.player:objectName() then table.insert(good_targets, friend) end
				if (friend:getCards("he"):length() <= 1 and friend:getHp() == 1) or (self:isWeak(friend) and friend:isLord()) then best_target = friend end
			end
		end
		if best_target then return best_target end
		if #good_targets > 0 then return good_targets[1] end
		if #targets > 0 then return targets[1] end
	end
	return self.player
end
sgs.ai_playerchosen_intention["kurashinfurashu"] = function(self, from, to)
	sgs.updateIntention(from, to, -40)
end

--弧光

sgs.ai_skill_invoke.arkora = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.arkora = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, 50) end
	end
end


sgs.ai_skill_cardask["@arkoraask"] = function(self,data,pattern,target)
	local n = self:ajustDamage(target,nil,1,nil)
	if n==1 and self:needToLoseHp(self.player,target,nil)
	then return "." end
	function getarkoraJink()
		if sgs.AIHumanized then
			self.room:getThread():delay(math.random(global_delay*0.3,global_delay*1.3))
		end
		local js = self:getCard("Jink",true)
		for _,c in sgs.list(js)do
			if self.player:hasFlag("dahe") and c:getSuit()~=sgs.Card_Heart then continue end
			return c:toString()
		end
		if sgs.AIHumanized and math.random()<0.5 and #self.friends_noself>0
		and self:getCardsNum("Peach,Analeptic")<1 and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")
			self.room:getThread():delay(math.random(global_delay*0.5,global_delay*1.5))
		end
		return "."
	end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player,50,target) then return getarkoraJink() end
		if self.player:getLostHp()==0 and self.player:isMale() and target:hasSkill("jieyin") then return "." end
		if not hasJueqingEffect(target,self.player) then
			if (target:hasSkill("nosrende") or target:hasSkill("rende") and not target:hasUsed("RendeCard")) and self.player:hasSkill("jieming")
			or target:hasSkill("pojun") and not self.player:faceUp()
			then return "." end
		end
	else
		if n>1 or n>=self.player:getHp() then return getarkoraJink() end
		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp()>0 then
			for _,c in sgs.list(self:getCards("Jink"))do
				if self.player:isLastHandCard(c,true)
				then return "." end
			end
		end
		if self.player:getHandcardNum()==1 and self:needKongcheng()
		or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return getarkoraJink() end
		if self.player:getHp()>1 and getKnownCard(target,self.player,"Slash")>0
		and getKnownCard(target,self.player,"Analeptic")>0 and self:getCardsNum("Jink")<2
		and (target:getPhase()<=sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player))
		then return "." end
	end
	return getarkoraJink()
end

--好戰
local warlike_skill={}
warlike_skill.name="warlike"
table.insert(sgs.ai_skills,warlike_skill)
warlike_skill.getTurnUseCard=function(self)
	if self.player:hasSkill("bloodfight") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)

	local card
	for _,c in ipairs(cards) do
		if c:isKindOf("TrickCard") then
			card = c
			break
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:warlike[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end



sgs.ai_target_revises.optimistic = function(to,card)
	if card:isKindOf("IronChain")
	then return true end
	if to:getEquips():length() + to:getHandcardNum() > to:getHp() and to:getHp() == 1 then
		if not (card:isKindOf("SkillCard") or card:isKindOf("Peach") or card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or card:isKindOf("IronChain") or card:isKindOf("Zhujinqiyuan")) then
			return true
		end
	end
end

sgs.ai_ajustdamage_to.optimistic   = function(self, from, to, card, nature)
	if to:getEquips():length() + to:getHandcardNum() > to:getHp() and to:getHp() == 1 then
		return -99
	end
end

--經撰：這類不必指定對象的牌，在getTurnUseCard中先把使用的牌挑出來，ai_skill_use_func那邊直接用卡即可，若有要指定對象可參考本AI的【界結姻】
local keishoukaki_skill = {}
keishoukaki_skill.name = "keishoukaki"
table.insert(sgs.ai_skills, keishoukaki_skill)
keishoukaki_skill.getTurnUseCard = function(self)
	-- if self.player:getMark("taiheikei_hiddenmark") < 10 and not self.player:isKongcheng() then
		-- return sgs.Card_Parse("#keishoukaki:.:")
	-- else
		-- return
	-- end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	-- self:sortByKeepValue(cards)
	self:sortByCardNeed(cards, true)
	local chosen = {}
	local getPeach = 0
	local num = 0
	local num_max = 10 - self.player:getMark("taiheikei_hiddenmark")
	if num_max == 0 or (self:getOverflow() == 0 and self.player:hasUsed("#keishoukaki")) then return end
	for _, c in ipairs(cards) do
		if (c:isKindOf("Peach") and self:getCardsNum("Peach") > getPeach+2) then
			getPeach = getPeach+1
			num = num+1
			table.insert(chosen, c:getId())
		end
		if not c:isKindOf("Peach") and not (c:isKindOf("Analeptic") and self:isWeak(self.player)) then
			num = num+1
			table.insert(chosen, c:getId())
		end
		if num >= self:getOverflow() or num == num_max then
			break
		end
	end
	if #chosen > 0 then
		local parse = sgs.Card_Parse("#keishoukaki:"..table.concat(chosen,"+")..":")
		assert(parse)
		return parse
		-- return sgs.Card_Parse("#keishoukaki:"..table.concat(chosen,"+")..":")
	end
	return
end

sgs.ai_skill_use_func["#keishoukaki"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.keishoukaki = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value["keishoukaki"] = 4

--經撰：五行區

sgs.ai_skill_choice["keishoukaki"] = function(self, choices, data)
	if self.player:hasFlag("KeishoukakiZokusei") then
		--選擇屬性區
		self.player:setFlags("-KeishoukakiZokusei")
		local weak_friend, weak_enemy = 0, 0
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isWeak(player) then
				if self:isEnemy(player) then
					weak_enemy = weak_enemy + 1
					if player:isLord() then weak_enemy = weak_enemy + 1 end
				elseif self:isFriend(player) then
					weak_friend = weak_friend + 1
					if player:isLord() then weak_friend = weak_friend + 1 end
				end
			end
		end
		local n = 0
		local e_dn = 0
		local f_dn = 0
		local ehasvine = false
		local frecnum = 0
		local erecnum = 0
		local e_cardneed = 0
		local f_cardneed = 0
		local e_manyhc = 0
		local f_manyhc = 0
		local e_haveCross = false
		local need_kana = false
		local f_haveCross = false
		local e_can_use = 0
		local f_can_use = 0
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasWeapon("crossbow") or enemy:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
				if enemy:getHandcardNum() > 2 then
					e_haveCross = true 
				end
				if enemy:getHandcardNum() > 4 then
					need_kana = true 
				end
			end
			if enemy:getHandcardNum() > 5 then e_manyhc = e_manyhc + 1 end
			if enemy:hasArmorEffect("vine") then e_dn=e_dn+1 ehasvine = true end
			if enemy:hasSkills(sgs.recover_hp_skill) or enemy:hasSkills("helptheweak|goldentear|weareidle|married|barakurosaku|zurunoonkaeshi") then erecnum = erecnum+1 end
			if enemy:getHandcardNum() < 2 or (enemy:getHandcardNum() < 3 and (enemy:hasSkills(sgs.cardneed_skill) or
			enemy:hasSkills("genshunoYURI|weareidle|yurimi|yochi|wisdom_s|bougairensha|imwatching|eatforlike|yuri_hagaku|fakebody|heapridge|japenknifejile|zhixi|frankly|clever|optimistic|countertrick|helptheweak"))) then e_cardneed = e_cardneed+1 end
			for _, c in sgs.qlist(enemy:getHandcards()) do
				if c:hasFlag("visible") and c:isDamageCard() and c:isKindOf("TrickCard") then e_dn=e_dn+1 end
				if c:hasFlag("visible") and (c:isKindOf("TrickCard") or c:isKindOf("EquipCard")) then n = n+1 end
				if c:hasFlag("visible") and (c:isKindOf("Peach") or c:isKindOf("Analeptic")) then erecnum = erecnum+1 end
			end
			if e_can_use < n then e_can_use = n end
		end
		n = 0
		for _,friend in ipairs(self.friends) do
			if friend:getHandcardNum() > 2 and (friend:hasWeapon("crossbow") or friend:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")) then f_haveCross = true end
			if friend:getHandcardNum() > 5 then f_manyhc = f_manyhc + 1 end
			if friend:hasSkills(sgs.recover_hp_skill) or friend:hasSkills("helptheweak|goldentear|weareidle|married|barakurosaku|zurunoonkaeshi") then frecnum = frecnum+1 end
			if friend:getHandcardNum() < 2 or (friend:getHandcardNum() < 3 and (friend:hasSkills(sgs.cardneed_skill) or
			friend:hasSkills("genshunoYURI|weareidle|yurimi|yochi|wisdom_s|bougairensha|imwatching|eatforlike|yuri_hagaku|fakebody|heapridge|japenknifejile|zhixi|frankly|clever|optimistic|countertrick|helptheweak"))) then f_cardneed = f_cardneed+1 end
			for _, c in sgs.qlist(friend:getHandcards()) do
				if c:hasFlag("visible") and c:isDamageCard() and c:isKindOf("TrickCard") then f_dn=f_dn+1 end
				if c:hasFlag("visible") and (c:isKindOf("TrickCard") or c:isKindOf("EquipCard")) then n=n+1 end
				if c:hasFlag("visible") and (c:isKindOf("Peach") or c:isKindOf("Analeptic")) then frecnum = frecnum+1 end
			end
			if f_can_use < n then f_can_use = n end
		end
		if choices:match("mizu") then
			-- self.player:gainMark("&test2")
			if weak_friend > 0 and weak_friend >= weak_enemy and frecnum >= erecnum then return "mizu" end
		end
		if choices:match("kana") then
			-- self.player:gainMark("&test1")
			if not f_haveCross and e_haveCross then return "kana" end
			if f_manyhc < e_manyhc or (f_can_use < e_can_use and e_can_use > 1) then return "kana" end
			if need_kana then return "kana" end
		end
		if choices:match("moku") then
			-- self.player:gainMark("&test3")
			if f_cardneed >= e_cardneed then return "moku" end
		end
		if choices:match("daiji") then
			-- self.player:gainMark("&test4")
		-- card:isDamageCard()
			if ((e_dn > 1 and weak_friend > 0) or e_dn > 2) and f_dn <= e_dn then return "daiji" end
		end
		if choices:match("hono") then
			-- self.player:gainMark("&test5")
			if ehasvine then return "hono" end
			if #(self:getChainedFriends()) < #(self:getChainedEnemies()) and
				#(self:getChainedFriends()) + #(self:getChainedEnemies()) > 1 then return "hono" end
		end
		-- self.player:gainMark("&test")
		local choices_table = choices:split("+")
		return choices_table[math.random(1, #choices_table)]
	else
		--判定是否取消效果區
		if self.player:getPile("taiheikei"):isEmpty() then return "cancel" end
		if self.player:getMark("&kana") > 0 then
			local target = data:toPlayer()
			-- target:gainMark("&inten1")
			if self:isFriend(target) and self:getOverflow(target) > 2 then 
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if self.player:getMark("&moku") > 0 then
			local target = data:toPlayer()
			-- target:gainMark("&inten2")
			if self:isFriend(target) and target:getHandcardNum() < 2 then 
				return "active_effect"
			else
				return "cancel"
			end
		end
		if self.player:getMark("&mizu") > 0 then
			local target = data:toPlayer()
			-- target:gainMark("&inten3")
			if self:isFriend(target) and target:getHandcardNum() < 2 and target:getLostHp() > 1 then
				return "active_effect"
			elseif self:isEnemy(target) and target:getHandcardNum() > 1 and target:getLostHp() > 1 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if self.player:getMark("&hono") > 0 then
			local damage = data:toDamage()
			-- target:gainMark("&inten4")
			if self:isEnemy(damage.to) then
				return "active_effect"
			elseif self:isFriend(damage.to) and self:isEnemy(damage.from) and damage.from:getHandcardNum() > 1 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if self.player:getMark("&daiji") > 0 then
			local damage = data:toDamage()
			-- target:gainMark("&inten5")
			if self:isFriend(damage.to) and damage.to:getHandcardNum() < 3 then
				return "active_effect"
			elseif self:isEnemy(damage.to) and damage.to:getHandcardNum() > 2 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
	end
end

sgs.ai_choicemade_filter.skillChoice.keishoukaki = function(self, player, promptlist)
	local to
	local type_str
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("kana_AI") then
			to = p
			p:setFlags("-kana_AI")
			type_str = "kana"
			break
		elseif p:hasFlag("moku_AI") then
			to = p
			p:setFlags("-moku_AI")
			type_str = "moku"
			break 
		elseif p:hasFlag("mizu_AI") then
			to = p
			p:setFlags("-mizu_AI")
			type_str = "mizu"
			break
		elseif p:hasFlag("hono_AI") then
			to = p
			p:setFlags("-hono_AI")
			type_str = "hono"
			break
		elseif p:hasFlag("daiji_AI") then
			to = p
			p:setFlags("-daiji_AI")
			type_str = "daiji"
			break
		end
	end
	if not type_str then return false end
	local choice = promptlist[#promptlist]
	if type_str == "kana" then
		if choice == "cancel_effect" then
			sgs.updateIntention(player, to, -40)
		end
	end
	if type_str == "moku" or type_str == "mizu" or type_str == "daiji" then
		if choice == "active_effect" then
			sgs.updateIntention(player, to, -40)
		end
		if choice == "cancel_effect" then
			sgs.updateIntention(player, to, 40)
		end
	end
	if type_str == "hono" then
		if choice == "active_effect" then
			sgs.updateIntention(player, to, 40)
		end
		if choice == "cancel_effect" then
			sgs.updateIntention(player, to, -40)
		end
	end
end
--金：沒有棄牌選項
--木
sgs.ai_skill_cardask["@moku_draw_ask"] = function(self,data,pattern)
	local target = data:toPlayer()
	if target:isKongcheng() then return "." end
    local needs = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if not (card:isKindOf("Peach") or card:isKindOf("Nullification") or (self:isWeak(target) and card:isKindOf("Analeptic")) or (target:getHandcardNum() == 1 and card:isKindOf("Jink"))) then
			table.insert(needs, card)
		end
	end
	if #needs > 0 then return "$" .. needs[1]:getEffectiveId() end
    return "."
end
--水
sgs.ai_skill_cardask["@mizu_recover_ask"] = function(self,data,pattern)
	local target = data:toPlayer()
	if (not target:isWounded()) or target:getLostHp() < 2 or target:isKongcheng() then return "." end
    local needs = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isRed() then
			if not (card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("Dongzhuxianji")) then
				table.insert(needs, card)
			end
		end
	end
	if #needs > 0 then return "$" .. needs[1]:getEffectiveId() end
    return "."
end
--火
sgs.ai_skill_cardask["@hono_damage_ask"] = function(self,data,pattern)
	local damage = data:toDamage()
	local from = damage.from
	local to = damage.to
	if from:isKongcheng() or self:isFriend(to) then return "." end
    local needs = {}
	local cards = from:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then
			table.insert(needs, card)
		end
	end
	if #needs > 0 then return "$" .. needs[1]:getEffectiveId() end
    return "."
end
--土
sgs.ai_skill_cardask["@daiji_damage_ask"] = function(self,data,pattern)
	local damage = data:toDamage()
	local to = damage.to
	if to:isKongcheng() then return "." end
    local needs = {}
	local cards = to:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		-- if card:getSuit() == sgs.Card_Club then
		if card:isBlack() then
			table.insert(needs, card)
		end
	end
	-- to:gainMark("&test")
	if #needs > 0 then return "$" .. needs[1]:getEffectiveId() end
    return "."
end

--邀棋(但技能寫在落子裡)
sgs.ai_skill_choice.taigyokunoyousei = function(self, choices, data)
	local current = data:toPlayer()
	-- self.player:gainMark("&test") --被問問題的人
	-- current:gainMark("&test") --程式碼裡設定的
	local e_wounded = 0
	local f_wounded = 0
	--因為此判斷之後，對象也會改變標記。這裡的標記判斷看起來會相反，是因為對應的是改變後的標記，而非現在的標記。
	if (current:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_black") == 1) or (current:getMark("&gomaoku_black") == 1 and self.player:getMark("&gomaoku_red") == 1) then
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() then f_wounded = f_wounded+1 end
		end
		for _, enemy in ipairs(self.enemies) do
			if enemy:isWounded() then e_wounded = e_wounded+1 end
		end
		for _ ,c in sgs.qlist(current:getHandcards()) do
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), current:objectName())
			if c:hasFlag("visible") or c:hasFlag(flag) then
				if self:isFriend(current) then
					if ((c:isKindOf("AOE") and #self.friends < #self.enemies) or (c:isKindOf("AmazingGrace") and #self.friends >= #self.enemies) or (c:isKindOf("GodSalvation") and f_wounded >= e_wounded)) and
					c:isAvailable(current) then
						return "change_goma"
					end
				elseif self:isEnemy(current) then
					if ((c:isKindOf("AOE") and #self.friends >= #self.enemies) or (c:isKindOf("AmazingGrace") and #self.friends < #self.enemies) or (c:isKindOf("GodSalvation") and f_wounded <= e_wounded)) and
					c:isAvailable(current) then
						return "change_goma"
					end
					if (c:isKindOf("Indulgence") and self:getOverflow() > 1) or ((c:isKindOf("SupplyShortage") or c:isKindOf("Snatch")) and current:distanceTo(self.player) == 1) or
					(c:isKindOf("Slash") and current:inMyAttackRange(self.player) and self:slashIsAvailable(current)) or ((c:isKindOf("Drowning") or c:isKindOf("Dismantlement")) and self.player:getCards("e"):length() > 0) or
					(c:isKindOf("FireAttack") and not self.player:isKongcheng() and self:isWeak(self.player)) then
						return "change_goma"
					end
				end

			end
		end
	end
	return "draw"
end

--落子
local gomaoku_skill = {}
gomaoku_skill.name = "gomaoku"
table.insert(sgs.ai_skills, gomaoku_skill)
gomaoku_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#gomaoku") or self.player:getHandcardNum() < 2 then return end
	local enemy_same = 0
	local may_need_change = false
	local dont_change = true
	local f_same = 0
	local e_wounded = 0
	local f_wounded = 0
	if self.player:isWounded() then f_wounded = 1 end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() then e_wounded = e_wounded+1 end
		if (enemy:getMark("&gomaoku_black") == 1 and self.player:getMark("&gomaoku_black") == 1) or (enemy:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_red") == 1) then
			enemy_same = enemy_same+1
		end
		if (enemy:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_black") == 1) or (enemy:getMark("&gomaoku_black") == 1 and self.player:getMark("&gomaoku_red") == 1) then
			if (self.player:inMyAttackRange(enemy) and self:getCardId("Slash") and self:slashIsAvailable(self.player)) or (self:getCardId("Snatch") and self.player:distanceTo(enemy) == 1) or 
			(self:getCardId("Dismantlement") and (enemy:getArmor() or enemy:getWeapon() or enemy:getDefensiveHorse() or enemy:getOffensiveHorse())) then
				may_need_change = true
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:isWounded() then f_wounded = f_wounded+1 end
		if (friend:getMark("&gomaoku_black") == 1 and self.player:getMark("&gomaoku_black") == 1) or (friend:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_red") == 1) then
			f_same = f_same+1
		end
		-- if (friend:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_black") == 1) or (friend:getMark("&gomaoku_red") == 1 and self.player:getMark("&gomaoku_black") == 1) then
			-- f_dif = f_dif+1
		-- end
	end
	local n = 0
	for _ ,c in sgs.qlist(self.player:getHandcards()) do
        if ((c:isKindOf("AOE") and #self.friends_noself < #self.enemies) or (c:isKindOf("AmazingGrace") and #self.friends >= #self.enemies) or (c:isKindOf("GodSalvation") and f_wounded >= e_wounded)) and
		c:isAvailable(self.player) then
			n=n+1
		end
    end
    for _, id in sgs.qlist(self.player:getHandPile()) do
        local c = sgs.Sanguosha:getCard(id)
        if ((c:isKindOf("AOE") and #self.friends_noself < #self.enemies) or (c:isKindOf("AmazingGrace") and #self.friends >= #self.enemies) or (c:isKindOf("GodSalvation") and f_wounded >= e_wounded)) and
		c:isAvailable(self.player) then
			n=n+1
		end
    end
	if self.player:getHandcardNum() > 2 and n >= 2 and enemy_same >= f_same then return end
	if (enemy_same < f_same and self.player:getHandcardNum() > 2) or (self.player:getHandcardNum() > 1 and may_need_change) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		if self.player:getPhase() == sgs.Player_NotActive then
			self:sortByKeepValue(cards)
		else
			self:sortByUseValue(cards)
		end
		local use_card
		for _,card in ipairs(cards) do
			if (card:isBlack() and self.player:getMark("&gomaoku_red") == 1) or (card:isRed() and self.player:getMark("&gomaoku_black") == 1) then
				use_card = card
				break
			end
		end
		if not use_card or use_card:isKindOf("Peach") then return end
		-- return sgs.Card_Parse("#gomaoku:" .. cards[1]:getId().. ":")
		return sgs.Card_Parse("#gomaoku:" .. use_card:getId().. ":")
	end
	return
end
sgs.ai_skill_use_func["#gomaoku"] = function(card, use, self)
	if card then
		use.card = card
	end
	return
end
sgs.ai_use_priority.gomaoku = sgs.ai_use_priority.ExNihilo + 1

--雙飛
local flyaway_skill = {} --借用火包園紹AI
flyaway_skill.name = "flyaway"
table.insert(sgs.ai_skills, flyaway_skill)
flyaway_skill.getTurnUseCard = function(self)
	-- local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("Dongzhuxianji", fcard, self.player) or isCard("AmazingGrace", fcard, self.player) or isCard("GodSalvation", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("Dongzhuxianji", scard, self.player) or isCard("AmazingGrace", fcard, self.player) or isCard("GodSalvation", fcard, self.player))
					if first_card ~= scard and scard:getColor() == first_card:getColor() and not svalueCard then
						local card_str
						if first_card:isBlack() then
							card_str = ("amazing_grace:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						elseif first_card:isRed() then
							card_str = ("god_salvation:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						end
						local aoe_card = sgs.Card_Parse(card_str)

						assert(aoe_card)

						local dummy_use = { isDummy = true }
						self:useTrickCard(aoe_card, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str
		if first_card:isBlack() then
			card_str = ("amazing_grace:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		elseif first_card:isRed() then
			card_str = ("god_salvation:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		end
		local aoe_card = sgs.Card_Parse(card_str)
		assert(aoe_card)
		return aoe_card
	end
end
sgs.ai_use_priority["flyaway"] = sgs.ai_use_priority.AmazingGrace


local frankly_skill = {}
frankly_skill.name= "frankly"
table.insert(sgs.ai_skills,frankly_skill)
frankly_skill.getTurnUseCard=function(self)
	self:updatePlayers()
	local tars = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			if not (self:isFriend(p) and p:getHandcardNum() > 3) then
				tars = tars + 1
			end
		end
	end
	-- if self:isWeak(self.player) then var = var + 2 end
	if tars == 0 then return false end
	if (not self.player:hasUsed("#franklyCard")) then
		return sgs.Card_Parse("#franklyCard:.:")
	end
end

sgs.ai_skill_use_func["#franklyCard"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local targets = {}
	local best_target = nil

	for _, enemy in ipairs(self.enemies) do
		local cards = enemy:getHandcards()
		if not self:doDisCard(enemy, "hej") then continue end
		if enemy:getHandcardNum() > 6 then best_target = enemy break end
		table.insert(targets, enemy)
	end
	if not best_target and #targets == 0 then
		for _, friend in ipairs(self.friends_noself) do
			if self:doDisCard(friend, "hej") then
				table.insert(targets, friend)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if self:canDraw(friend, self.player) then
				table.insert(targets, friend)
			end
		end
	end
	if best_target then
		use.card = sgs.Card_Parse("#franklyCard:.:")
		if use.to then
			use.to:append(best_target)
		end
	elseif #targets > 0 then
		use.card = sgs.Card_Parse("#franklyCard:.:")
		if use.to then
			use.to:append(targets[1])
		end
	end
	return
end

sgs.ai_use_value["franklyCard"] = 4
sgs.ai_use_priority["franklyCard"] = sgs.ai_use_priority.Dismantlement + 1


sgs.ai_skill_choice["frankly"] = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return "discard"
	end
	if target and self:isFriend(target) then
		if self:doDisCard(target, "hej") then return "discard" end
		return "draw"
	end

	return "discard"
end

sgs.ai_skill_suit.frankly = function(self)
	local sus = {}
	for s,h in sgs.list(self.player:getHandcards())do
		s = h:getSuit()
		if sus[s] then sus[s] = sus[s]+1
		else sus[s] = 1 end
	end
	local function func(a,b)
		return a>b
	end
	table.sort(sus,func)
	for i,v in pairs(sus)do
		return i
	end
end

local function need_flexible(self,who)
	local use = self.player:getTag("flexible"):toCardUse()
	local card,from = use.card,use.from
	if self:isEnemy(who) then
		if card:isKindOf("GodSalvation") and who:isWounded() and who:getHp()<getBestHp(who) and self:hasTrickEffective(card,who,from) then
			return true
		end
		if card:isKindOf("ExNihilo") then return true end
		if card:isKindOf("Peach") then return true end
		return false
	elseif self:isFriend(who) then
		if who:hasSkill("noswuyan") and from:objectName()~=who:objectName() then return true end
		if card:isKindOf("GodSalvation") and not who:isWounded() then
			if hasManjuanEffect(who) then return false end
			if self:needKongcheng(who,true) then return false end
			return true
		end
		if card:isKindOf("GodSalvation") and who:isWounded() and self:hasTrickEffective(card,who,from) then
			if who:getHp()>getBestHp(who) and not self:needKongcheng(who,true) then return true end
			return false
		end
		if card:isKindOf("IronChain") and (self:needKongcheng(who,true) or (who:isChained() and self:hasTrickEffective(card,who,from))) then
			return false
		end
		if card:isKindOf("AmazingGrace") then return not self:hasTrickEffective(card,who,from) end
		if card:isKindOf("ExNihilo") then return false end
		if card:isKindOf("Peach") then return false end
		return true
	end
end
sgs.ai_skill_use["@@flexible"] = function(self, prompt) 
    self:updatePlayers(true)
    local targets = {}
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("flexible") then
		local use = self.room:getTag("flexible"):toCardUse()
		if self.player:getMark("friendlyTime") > 0 then
			local target_table = {}
			local use = self.player:getTag("flexible"):toCardUse()
			for _,player in sgs.list(self.room:getAllPlayers())do
				if use.to:contains(player) and need_flexible(self,player) then
					table.insert(target_table,player:objectName())
					if #target_table==self.player:getMark("@defensive_distance_test") then break end
				end
			end
			if #target_table==0 then return "." end
			return "#flexible:.:->"..table.concat(target_table, "+")
		else
			local dummy_use = self:aiUseCard(use.card, dummy(true, self.player:getMark("@defensive_distance_test"), use.to))
			if dummy_use and dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,p in sgs.list(dummy_use.to)do
					table.insert(tos,p:objectName())
				end
				return "#flexible:.:->"..table.concat(tos,"+")
			end
		end
	else
		if self.player:getMark("fake_flexible") == 0 then return nil end
		for _, p in ipairs(self.enemies) do
			table.insert(targets, p:objectName())
			if #targets >= self.player:getMark("fake_flexible") then break end
		end
		if #targets == 0 then return nil end
		return "#flexible:.:->"..table.concat(targets, "+")
	end
end

--鬥陣
sgs.ai_skill_playerchosen.hb_konoyaiba_uketemiyo = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		-- if (self.player:inMyAttackRange(enemy) or self.player:distanceTo(enemy) <= self.player:getHp()) and self.player:getHp() < enemy:getHp() then
		if (self.player:inMyAttackRange(enemy) or (self.player:distanceTo(enemy) <= self.player:getHp() and not self.player:getWeapon())) and self.player:getHp() <= enemy:getHp() then
			if self:isWeak(enemy) then
				table.insert(good_targets, enemy)
			else
				table.insert(targets, enemy)
			end
		end
	end
	if #good_targets > 0 then return good_targets[1] end
	if #targets > 0 then return targets[1] end
	return nil
end
sgs.ai_playerchosen_intention["hb_konoyaiba_uketemiyo"] = function(self, from, to)
	sgs.updateIntention(from, to, 60)
end

--王肉

sgs.ai_skill_invoke.nikuhei_k = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.nikuhei_k = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, -50) end
	end
end

--棄置牌AI範例
--room->askForExchange(playerA, "olanxu", 1, 1, false, QString("@olanxu:%1:%2").arg(source->objectName()).arg(playerB->objectName()))
-- sgs.ai_skill_discard["olanxu"] = function(self, discard_num, min_num, optional, include_equip)
    -- local others = self.room:getOtherPlayers(self.player)
    -- local target = nil
    -- for _,p in sgs.qlist(others) do
        -- if p:hasFlag("olanxu_target") then
            -- target = nil
            -- break
        -- end
    -- end
    -- assert(target)
    -- local handcards = self.player:getHandcards()
    -- handcards = sgs.QList2Table(handcards)
    -- if self:isFriend(target) and not hasManjuanEffect(target) then
        -- self:sortByUseValue(handcards)
        -- return { handcards[1]:getEffectiveId() }
    -- end
    -- return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
-- end

-- 給牌AI範例，使用的是room:askForYiji(player, hands, "pinghe", false, false, false, 1)的程式碼(非本AI範例，但同格式)
-- sgs.ai_skill_askforyiji.olmiji = function(self, card_ids)
    
    -- local available_friends = {}
    -- for _, friend in ipairs(self.friends) do
        -- if not friend:hasSkill("manjuan") and not self:isLihunTarget(friend) then table.insert(available_friends, friend) end
    -- end

    -- local toGive, allcards = {}, {}
    -- local keep
    -- for _, id in ipairs(card_ids) do
        -- local card = sgs.Sanguosha:getCard(id)
        -- if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
            -- keep = true
        -- else
            -- table.insert(toGive, card)
        -- end
        -- table.insert(allcards, card)
    -- end

    
    
    -- local cards = #toGive > 0 and toGive or allcards
    -- self:sortByKeepValue(cards, true)
    -- local id = cards[1]:getId()

    -- local card, friend = self:getCardNeedPlayer(cards, true)
    -- if card and friend and table.contains(available_friends, friend) then 
        -- if friend:objectName() == self.player:objectName() then 
            -- return nil, -1
        -- else
            -- return friend, card:getId() 
        -- end
    -- end

    
    -- if #available_friends > 0 then
        -- self:sort(available_friends, "handcard")
        -- for _, afriend in ipairs(available_friends) do
            -- if not self:needKongcheng(afriend, true) then
                -- if afriend:objectName() == self.player:objectName() then 
                    -- return nil, -1
                -- else
                    -- return afriend, id
                -- end
            -- end
        -- end
        -- self:sort(available_friends, "defense")
        -- if available_friends[1]:objectName() == self.player:objectName() then 
            -- return nil, -1
        -- else
            -- return available_friends[1], id
        -- end
    -- end
    -- return nil, -1
-- end



sgs.ai_skill_invoke.yuriKansen = function(self,data)
	local use = data:toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy())
	if use.from and self:isFriend(use.from) and use.card:isKindOf("EquipCard") then return false end
	if dummy_use.card and dummy_use and dummy_use.to then
		return true
	end
	return false
end

sgs.ai_can_damagehp.yuriKansen = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) then
		return self:isEnemy(from) and from:getMark("&yuriKansen") == 0
	end
end

sgs.ai_guhuo_card.ov_jichou = function(self,toname,class_name)
	if self.player:getMark("ov_jichou_"..toname)<1
	and self.player:getMark("ov_jichou-Clear")<1 then
        local c = dummyCard(toname)
		if c and c:isNDTrick() and self:getCardsNum(class_name)<1
	    then return "#ov_jichoucard:.:"..toname end
	end
end

sgs.ai_fill_skill.genshunoYURI = function(self)
    return sgs.Card_Parse("#genshunoYURICard:.:")
end

sgs.ai_skill_use_func["#genshunoYURICard"] = function(card,use,self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for c,h in sgs.list(cards)do
		for _,p in sgs.list(RandomList(patterns()))do
			local dc = dummyCard(p)
			if dc and (dc:isNDTrick() or dc:isKindOf("BasicCard")) and self:getCardsNum(dc:getClassName())<1 then
				dc:setSkillName("genshunoYURI")
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						use.card = sgs.Card_Parse("#genshunoYURICard:".. h:getEffectiveId() ..":"..p)
						use.to = d.to
						sgs.ai_use_priority.genshunoYURICard = sgs.ai_use_priority[dc:getClassName()]
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value.genshunoYURICard = 3.4
sgs.ai_use_priority.genshunoYURICard = 3.2

sgs.ai_guhuo_card.genshunoYURI = function(self,toname,class_name)
	local current = self.room:getCurrent()
	if ((sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
	and current and self.player:getMark("genshunoYURI-".. current:getPhase().."Clear") == 0) or sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	then
		local card = dummyCard(toname)
		if card and (card:isNDTrick() or card:isKindOf("BasicCard")) and self:getCardsNum(class_name)<1  then
			local cards = self:addHandPile("he")
			cards = self:sortByKeepValue(cards,nil,true)
			-- card:setSkillName("genshunoYURI")
			-- card:addSubcard(cards[1])
			-- return card:toString()
			return "#genshunoYURICard:"..cards[1]:getEffectiveId()..":"..toname
		end
	end
end

sgs.ai_skill_invoke.machiko = function(self, data)
	local damage = data:toDamage()
    if self:damageIsEffective(damage.to,damage.card,damage.from) and not self:needToLoseHp(damage.to, damage.from, damage.card) then return true end
	return false
end


local clever_skill = {}
clever_skill.name = "clever"
table.insert(sgs.ai_skills, clever_skill)
clever_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("clevercards"):length() > 0 then
		local cardid = self.player:getPile("clevercards"):first()
		local cardname = sgs.Sanguosha:getCard(cardid):objectName()
		local cards = self:addHandPile("he")
		cards = self:sortByUseValue(cards,true)
		local use_card
		for _,card in ipairs(cards)  do
			if (self:getUseValue(card)<self:getUseValue(sgs.Sanguosha:getCard(cardid))) and self:getCardsNum(cardname)<1 then
				use_card = card
				break
			end
		end
		if use_card then
			local suit = use_card:getSuitString()
			local number = use_card:getNumberString()
			local card_id = use_card:getEffectiveId()
			local card_str = (cardname..":clever[%s:%s]=%d"):format(suit,number,card_id)
			local new_card = sgs.Card_Parse(card_str)
			assert(new_card)
			return new_card
		end
	else
	return sgs.Card_Parse("#clever:.:")
	end
end


sgs.ai_skill_use_func["#clever"] = function(card, use, self)
	for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
		if (c:isKindOf("EquipCard") or c:isKindOf("Analeptic") or c:isKindOf("IronChain") or c:isKindOf("ExNihilo") or c:isKindOf("AmazingGrace") or c:isKindOf("Dongzhuxianji")) then continue end
		if table.contains(self.toUse,c) or c:isKindOf("Peach") then
			use.card = sgs.Card_Parse("#clever:" .. c:getEffectiveId() .. ":")
			return
		end
	end
end
sgs.ai_use_priority.clever = 10


sgs.ai_view_as.clever = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getPile("clevercards"):isEmpty() then return nil end
	if player:getMark("@cleverkon") > 0 then return nil end
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local cardid = player:getPile("clevercards"):first()
		local cardname = sgs.Sanguosha:getCard(cardid):objectName()
		if cardname then
			return (cardname..":sfofl_huxiao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.ai_skill_cardask["@magicat"] = function(self,data)
	local currentplayer = self.room:getCurrent()
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards, true)
	for i,c in sgs.list(cards)do
		if self:doDisCard(currentplayer, "he") or (self:isFriend(currentplayer) and self:canDraw(currentplayer, self.player)) then
			return "$"..c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_choice["magicat"] = function(self, choices, data)
	local items = choices:split("+")
	local currentplayer = data:toPlayer()
	if (self:isFriend(currentplayer) and self:canDraw(currentplayer, self.player)) then
		return "draw"
	end
	return "discard"
end
sgs.ai_choicemade_filter.skillChoice["magicat"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local currentplayer = self.room:getCurrent()
	if currentplayer then
		if choice == "discard" then
			sgs.updateIntention(player, currentplayer, 80)
		else
			sgs.updateIntention(player, currentplayer, -80)
		end
	end
end


sgs.ai_skill_invoke.magicat = function(self,data)
	local currentplayer = self.room:getCurrent()
	if self:isEnemy(currentplayer) then
		if self:doDisCard(currentplayer, "he", true) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.magicat = function(self,player,promptlist)
	local current = self.room:getCurrent()
	if current then
		local intention = 60
		if promptlist[3]=="yes" then
			if self:hasSkills(sgs.lose_equip_skill,current) and current:getCards("e"):length()>0 then intention = 0 end
			if self:needToThrowArmor(current) then return end
			if not self:hasLoseHandcardEffective(current)
			or (self:needToLoseHp(current))
			then intention = 0 end
			sgs.updateIntention(player,current,intention)
		end
	end
end

local Subetewonomikonmu_skill = {}
Subetewonomikonmu_skill.name = "Subetewonomikonmu"
table.insert(sgs.ai_skills,Subetewonomikonmu_skill)
Subetewonomikonmu_skill.getTurnUseCard = function(self)
	if self.player:getMark("@wrath") < 7 then return nil end
	return sgs.Card_Parse("#SubetewonomikonmuCard:.:")
end

function SmartAI:canSaveSelf(player)
	if hasBuquEffect(player) then return true end
	if getCardsNum("Analeptic",player,self.player)>0 then return true end
	if player:hasSkills("jiushi|mobilejiushi") and player:faceUp() then return true end
	if player:hasSkills("jiuchi|mobilejiuchi|oljiuchi") then
		for _,c in sgs.list(player:getHandcards())do
			if c:getSuit()==sgs.Card_Spade then return true end
		end
	end
	return false
end

local function getSubetewonomikonmuUseValueOfHECards(self,to)
	local value = 0
	-- value of handcards
	local value_h = 0
	local hcard = to:getHandcardNum()
	if to:hasSkill("lianying") then
		hcard = hcard-0.9
	elseif to:hasSkills("shangshi|nosshangshi") then
		hcard = hcard-0.9*to:getLostHp()
	else
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		if jwfy and self:isFriend(jwfy,to) and (not self:isWeak(jwfy) or jwfy:getHp()>1) then hcard = hcard-0.9 end
	end
	value_h = (hcard>4) and 16/hcard or hcard
	if to:hasSkills("tuntian+zaoxian") then value = value*0.95 end
	if (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getHp()>2 and to:getMark("zhiji")==0)) and not to:isKongcheng() then value_h = value_h*0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then value_h = value_h*0.95 end
	value = value+value_h

	-- value of equips
	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("SilverLion") and to:isWounded() then equip_num = equip_num-1.1 end
	value_e = equip_num*1.1
	if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e*0.7 end
	if to:hasSkill("nosxuanfeng") then value_e = value_e*0.85 end
	if to:hasSkills("bazhen|yizhong") and to:getArmor() then value_e = value_e-1 end
	value = value+value_e

	return value
end

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _,player in sgs.list(self.room:getAllPlayers())do
                local nm_mark = player:getMark("&nightmare")
		if player:objectName()==self.player:objectName() then nm_mark = nm_mark+1 end
		if nm_mark>0 and nm_mark>most or (nm_mark==most and self:isEnemy(player)) then
			most = nm_mark
			target = player
		end
	end
	if target and self:isEnemy(target) then return true end
	return false
end

sgs.ai_skill_use_func.SubetewonomikonmuCard = function(card,use,self)
	if (self.role=="loyalist" or self.role=="renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not self.player:isLord() then return end
	local benefit = 0
	for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:isFriend(player) then benefit = benefit-getSubetewonomikonmuUseValueOfHECards(self,player) end
		if self:isFriend(player) then benefit = benefit+getSubetewonomikonmuUseValueOfHECards(self,player) end
	end
	local friend_save_num = self:getSaveNum(true)
	local enemy_save_num = self:getSaveNum(false)
	local others = 0
	for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:damageIsEffective(player,sgs.DamageStruct_Normal) then
			others = others+1
			local value_d = 3.5/math.max(player:getHp(),1)
			if player:getHp()<=1 then
				if player:hasSkill("wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d*0.1 end
				end
				if self:canSaveSelf(player) then
					value_d = value_d*0.9
				elseif self:isFriend(player) and friend_save_num>0 then
					friend_save_num = friend_save_num-1
					value_d = value_d*0.9
				elseif self:isEnemy(player) and enemy_save_num>0 then
					enemy_save_num = enemy_save_num-1
					value_d = value_d*0.9
				end
			end
			if player:hasSkill("fankui") then value_d = value_d*0.8 end
			if player:hasSkill("guixin") then
				if not player:faceUp() then
					value_d = value_d*0.4
				else
					value_d = value_d*0.8*(1.05-self.room:alivePlayerCount()/15)
				end
			end
			if self:needToLoseHp(player,self.player) or getBestHp(player)==player:getHp()-1 then value_d = value_d*0.8 end
			if self:isFriend(player) then benefit = benefit-value_d end
			if self:isEnemy(player) then benefit = benefit+value_d end
		end
	end
	if not self.player:faceUp() or self.player:hasSkills("jushou|nosjushou|neojushou|kuiwei") then
		benefit = benefit+1
	else
		local help_friend = false
		for _,friend in sgs.list(self.friends_noself)do
			if self:hasSkills("fangzhu|jilve",friend) then
				help_friend = true
				benefit = benefit+1
				break
			end
		end
		if not help_friend then benefit = benefit-0.5 end
	end
	if self.player:getKingdom()=="qun" then
		for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
			if player:hasLordSkill("baonue") and self:isFriend(player) then
				benefit = benefit+0.2*self.room:alivePlayerCount()
				break
			end
		end
	end
	benefit = benefit+(others-7)*0.05
	if benefit>0 then
		use.card = card
	end
end

sgs.ai_use_value.SubetewonomikonmuCard = 8
sgs.ai_use_priority.SubetewonomikonmuCard = 5.3

sgs.dynamic_value.damage_card.SubetewonomikonmuCard = true
sgs.dynamic_value.control_card.SubetewonomikonmuCard = true

sgs.ai_fill_skill.acting = function(self)
    return sgs.Card_Parse("#actingcard:.:")
end

sgs.ai_skill_use_func["#actingcard"] = function(card,use,self)
	
	use.card = card
	if use.to then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if math.random() < 0.5 then
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if math.random() < 0.3 then
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.actingcard = 3.4
sgs.ai_use_priority.actingcard = 10


sgs.ai_fill_skill.liketoplay = function(self)
    return sgs.Card_Parse("#liketoplaycard:.:")
end

sgs.ai_skill_use_func["#liketoplaycard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.liketoplaycard = 3.4
sgs.ai_use_priority.liketoplaycard = 6


sgs.ai_card_priority.proficient = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end


sgs.ai_fill_skill.endingchoice = function(self)
    return sgs.Card_Parse("#endingchoiceCard:.:")
end

sgs.ai_skill_use_func["#endingchoiceCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.endingchoiceCard = 3.4
sgs.ai_use_priority.endingchoiceCard = 6

sgs.ai_skill_choice["sweetsis"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

sgs.ai_view_as.angel = function(card,player,card_place)
	if card_place~=sgs.Player_PlaceSpecial and card:getSuit() == sgs.Card_Heart then
		return ("peach:angel[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getEffectiveId())
	end
end

sgs.angel_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.angel = function(to,card)
	return card:isRed()
end

local angel = {}
angel.name = "angel"
table.insert(sgs.ai_skills,angel)
angel.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,c in ipairs(cards)do
		if c:getSuit() == sgs.Card_Heart then
			return sgs.Card_Parse("peach:angel[no_suit:0]="..c:getEffectiveId())
		end
	end
end
local hidethepath = {}
hidethepath.name = "hidethepath"
table.insert(sgs.ai_skills,hidethepath)
hidethepath.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,c in ipairs(cards)do
		if c:getSuit() == sgs.Card_Diamond then
			return sgs.Card_Parse("snatch:hidethepath[no_suit:0]="..c:getEffectiveId())
		end
	end
end

sgs.ai_fill_skill.dressing = function(self)
	if not self.player:canDiscard(self.player, "h") then return nil end
    return sgs.Card_Parse("#dressing:.:")
end

sgs.ai_skill_use_func["#dressing"] = function(card,use,self)
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	sgs.ai_skill_invoke.peiqi(self)
    for _,target in sgs.list(self.room:getAlivePlayers())do
		if target==self.peiqiData.from and target:getJudgingArea():length() <= 0 then 
			use.card = sgs.Card_Parse("#dressing:" .. hcards[1]:getId() .. ":")
			use.to:append(target) 
			return 
		end
	end
end

sgs.ai_skill_cardchosen.dressing = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.dressing = function(self,players)
    for _,target in sgs.list(players)do
		if target==self.peiqiData.to
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_use_value.dressing = 3.4
sgs.ai_use_priority.dressing = 2