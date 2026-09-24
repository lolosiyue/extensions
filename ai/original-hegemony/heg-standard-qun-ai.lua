-- Source: TODO/QSanguosha-For-Hegemony-xxyheaven/lua/ai/standard-qun-ai.lua (cf61c15).
--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]
if not sgs.original_hegemony_ai_loading then return end

sgs.ai_view_as.jijiu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and card:isRed() and player:getPhase() == sgs.Player_NotActive
		and not player:hasFlag("Global_PreventPeach") and (player:getMark("##heg_qianxi+no_suit_red") == 0 or card:isEquipped()) then
		return ("peach:jijiu[%s:%s]=%d&jijiu"):format(suit, number, card_id)
	end
end

sgs.jijiu_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.jijiu = function(to, card)
	return card:isRed()
end

sgs.ai_suit_priority.jijiu= "club|spade|diamond|heart"

sgs.ai_skill_cardask["@wushuang-slash-1"] = function(self, data, pattern, target)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self:getCardsNum("Slash") < 2 and not (self.player:getHandcardNum() == 1 and self.player:hasSkills(sgs.need_kongcheng)) then return "." end
end

sgs.ai_skill_cardask["@multi-jink-start"] = function(self, data, pattern, target, target2, arg)
	local rest_num = tonumber(arg)
	if rest_num == 1 then return sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) == "." then return "." end
	if self.player:hasSkill("heg_kongcheng") then
		if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and target:hasWeapon("GudingBlade") then return "." end
	else
		if self:getCardsNum("Jink") < rest_num and self:hasLoseHandcardEffective() then return "." end
	end
end

sgs.ai_skill_cardask["@multi-jink"] = sgs.ai_skill_cardask["@multi-jink-start"]

sgs.ai_skill_invoke.wushuang = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	local use = self.player:getTag("WushuangData"):toCardUse()
	local current_trigger = self.player:getTag("WushuangTarget"):toPlayer()
	local index = use.to:indexOf(current_trigger)
	global_room:writeToConsole("无双当前触发："..index)
	local left_trigger = sgs.SPlayerList()
	if use.to:length() > index + 1 then
		for i = index, use.to:length() - 1, 1 do
			left_trigger:append(use.to:at(i))--会出现空值？
		end
	end

	if use.card then
		if use.card:isKindOf("Duel") then
			if use.from:objectName() == self.player:objectName() then
				for _, p in sgs.qlist(left_trigger) do
					if self:isFriend(p) then return false end
				end
				return true
			else
				for _, c in sgs.qlist(self.player:getHandcards()) do
					if isCard("Slash", c, self.player) then
						return true
					end
				end
				return false
			end
		end
		for _, p in sgs.qlist(left_trigger) do
			if self:isFriend(p) then return false end
		end
		return true
	end
	return false
end

sgs.ai_skill_playerchosen["wushuang_extra"] = function(self, targets, max_num, min_num)--可参考usecardduel
	--local use = self.player:getTag("WushuangUsedata"):toCardUse()
	global_room:writeToConsole("无双决斗额外选择")
	local result = {}
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num and not table.contains(result, target) then
			  table.insert(result, target)
		end
	end
	for _, target in ipairs(targetlist) do
		if not self:isFriendWith(target) and #result < max_num and not table.contains(result, target) then
			  table.insert(result, target)
		end
	end
	return result
end

sgs.ai_cardneed.wushuang = function(to, card, self)
	return isCard("Duel", card, to) or isCard("Slash", card, to) or card:isKindOf("HHalberd")
end

function SmartAI:getLijianCard()
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") and not acard:isKindOf("HJadeSeal") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") and not acard:isKindOf("HJadeSeal") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

function SmartAI:findLijianTarget(card_name, use)
	local duel = sgs.cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		local maxSlash = 0
		local friend_maxSlash
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:trickIsEffective(duel, first, friend) then
				if (getCardsNum("Slash", friend, self.player) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend, self.player)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if sgs.originalHegemonyHasShownSkills(first, "nosfankui|heg_ganglie") then
				if (first:getHp() <= 1 and first:isKongcheng()) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash, self.player) >= getCardsNum("Slash", first, self.player)) then safe = true end
			if safe then return friend_maxSlash end
		end
		return nil
	end

	if not self.player:hasUsed(card_name) then
		self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, heg_xunyu

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() then
				if enemy:hasShownSkill("heg_kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasShownSkill("heg_jieming") then heg_xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:trickIsEffective(duel, enemy, anotherenemy) then
								table.insert(males, enemy)
							end
							if #males == 1 and self:trickIsEffective(duel, males[1], anotherenemy) then
								if not sgs.originalHegemonyHasShownSkills(anotherenemy, "heg_jizhi|heg_jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and males[1]:getHp() == 1 then--新增配合吕布张绣
			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
			local heg_lvbu = sgs.findPlayerByShownSkillName("wushuang")
			local heg_zhangxiu = sgs.findPlayerByShownSkillName("heg_congjian")
			if heg_lvbu and heg_lvbu:getHp() > 1 and heg_lvbu:getHandcardNum() > 1 then
				afriend  =heg_lvbu
			end
			if heg_zhangxiu and heg_zhangxiu:getHp() > 1 and heg_zhangxiu:getHandcardNum() > 1 then
				afriend = heg_zhangxiu
			end
			if afriend and afriend:objectName() ~= males[1]:objectName() and afriend:objectName() ~= self.player:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif heg_xunyu and not heg_xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1], self.player) < 1 then
					table.insert(males, heg_xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, heg_xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:trickIsEffective(duel, first, zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

local lijian_skill = {}

lijian_skill.name = "lijian"

table.insert(sgs.ai_skills, lijian_skill)

lijian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LijianCard") or self.player:isNude() then
		return
	end
	local card_id = self:getLijianCard()
	if card_id then return sgs.Card_Parse("@LijianCard=" .. card_id .. "&lijian") end
end

sgs.ai_skill_use_func.LijianCard = function(card, use, self)
	local first, second = self:findLijianTarget("LijianCard", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value.LijianCard = 8.5

sgs.ai_use_priority.LijianCard = 4

sgs.dynamic_value.damage_card.LijianCard = true

sgs.ai_skill_invoke.biyue = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	return not self:needKongcheng(self.player, true)
end

local luanji_skill = {}

luanji_skill.name = "heg_luanji"

table.insert(sgs.ai_skills, luanji_skill)

luanji_skill.getTurnUseCard = function(self)
	local willShow = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") then
			willShow = true
			break
		end
	end
	--配合许攸
	local heg_xuyou = sgs.findPlayerByShownSkillName("heg_chenglve")
	if heg_xuyou and self.player:isFriendWith(heg_xuyou) then
		willShow = true
	end

	if not self.player:hasShownSkill("heg_luanji") and not willShow then return nil end

	local archery = sgs.cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	local usedsuits = self.player:property("heg_luanji_suits_phase"):toString():gsub("_char", ""):split("+")

	if self.player:getHandcardNum() + self.player:getHandPile():length() >= 2 then
		local cards = self.player:getHandcards()
		for _, id in sgs.qlist(self.player:getHandPile()) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local useAll = false
		local hasSamesuit = false
		local heartKeepnum, diamondKeepnum, spadeKeepnum, clubKeepnum = 0,0,0,0

		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end

		for _, c in ipairs(cards) do
			if useAll then
				if isCard("ArcheryAttack", c, self.player) or isCard("HBefriendAttacking", c, self.player) then
					if c:getSuit() == sgs.Card_Heart then
						heartKeepnum = heartKeepnum +1
					elseif c:getSuit() == sgs.Card_Diamond then
						diamondKeepnum = diamondKeepnum + 1
					elseif c:getSuit() == sgs.Card_Spade then
						spadeKeepnum = spadeKeepnum + 1
					elseif c:getSuit() == sgs.Card_Club then
						clubKeepnum = clubKeepnum + 1
					end
				end
			else
				if isCard("Peach", c, self.player) or isCard("ExNihilo", c, self.player)
				or isCard("HBefriendAttacking", c, self.player) or isCard("HAllianceFeast", c, self.player)
				or isCard("ArcheryAttack", c, self.player) or isCard("HJadeSeal", c, self.player) then
					if c:getSuit() == sgs.Card_Heart then
						heartKeepnum = heartKeepnum +1
					elseif c:getSuit() == sgs.Card_Diamond then
						diamondKeepnum = diamondKeepnum + 1
					elseif c:getSuit() == sgs.Card_Spade then
						spadeKeepnum = spadeKeepnum + 1
					elseif c:getSuit() == sgs.Card_Club then
						clubKeepnum = clubKeepnum + 1
					end
				end
			end
		end
		--去除保留牌的花色，优先使用同色
		if self:getSuitNum("heart", false, self.player) > 1 + heartKeepnum or
		self:getSuitNum("diamond", false, self.player) > 1 + diamondKeepnum or
		self:getSuitNum("spade", false, self.player) > 1 + spadeKeepnum or
		self:getSuitNum("club", false, self.player) > 1 + clubKeepnum then
		   hasSamesuit = true
	   end

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player)
								or isCard("HBefriendAttacking", fcard, self.player) or isCard("HAllianceFeast", fcard, self.player)
								or isCard("ArcheryAttack", fcard, self.player) or isCard("HJadeSeal", fcard, self.player))
			if useAll then
				fvalueCard = isCard("ArcheryAttack", fcard, self.player) or isCard("HBefriendAttacking", fcard, self.player)
			end
			if not fvalueCard and not table.contains(usedsuits, sgs.Sanguosha:getCard(fcard:getId()):getSuitString()) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player) or isCard("HJadeSeal", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and (scard:getSuit() == first_card:getSuit() or not hasSamesuit)--新万箭齐发
						and not svalueCard and not table.contains(usedsuits, sgs.Sanguosha:getCard(scard:getId()):getSuitString()) then

						local card_str = ("archery_attack:heg_luanji[%s:%s]=%d+%d&heg_luanji"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
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
		if table.contains(usedsuits, sgs.Sanguosha:getCard(first_id):getSuitString())--前边也有检测
		or table.contains(usedsuits, sgs.Sanguosha:getCard(second_id):getSuitString()) then
			return nil
		end
		local card_str = ("archery_attack:heg_luanji[%s:%s]=%d+%d&heg_luanji"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

sgs.ai_skill_choice["luanji_draw"] = function(self, choices, data)
	return "yes"
end

local luanwu_skill = {}

luanwu_skill.name = "luanwu"

table.insert(sgs.ai_skills, luanwu_skill)

luanwu_skill.getTurnUseCard = function(self)
	if self.player:getMark("@chaos") <= 0 then return end
	local good, bad = 0, 0
	if self.player:hasShownSkill("heg_baoling") then good = good + 0.8 end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1.5
			elseif player:hasShownOneGeneral() then  good = good + 0.8
			else good = good + 0.4
			end
		end
	end
	local alive = self.room:alivePlayerCount()
	if good < alive/4 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:isRemoved() then
			continue
		end
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player, self.player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		local has_slash = (getCardsNum("Slash", player, self.player) > 0)
		local can_slash = false
		if not can_slash then
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if player:distanceTo(p) <= player:getAttackRange() then can_slash = true break end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then good = good + math.max(getCardsNum("Peach", player, self.player), 1)
			else bad = bad + math.max(getCardsNum("Peach", player, self.player), 1)
			end
		end

		if getCardsNum("Jink", player, self.player) == 0 then
			local lost_value = 0
			if sgs.originalHegemonyHasShownSkills(player, sgs.masochism_skill) then lost_value = player:getHp() / 2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return sgs.Card_Parse("@LuanwuCard=.&luanwu") end
end

sgs.ai_skill_use_func.LuanwuCard = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card.LuanwuCard = true

sgs.ai_skill_cardask["@luanwu-slash"] = function(self)
	local players = {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasFlag("SlashAssignee") then table.insert(players, player) end
	end
	local slashes = self:getCards("Slash")

	if #slashes == 0 then return "." end
	self:sort(players, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local targets = {}
		local EXT = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash)
		for _, friend in ipairs(players) do
			if not self.player:canSlash(friend, slash) then continue end
			if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, slash, friend)
				and not self:slashProhibit(slash, friend) and self:slashIsEffective(slash, friend)
				and self:isPriorFriendOfSlash(friend, slash, self.player)
				and not table.contains(targets, friend:objectName()) then
				table.insert(targets, friend:objectName())
			end
		end

		for _, enemy in ipairs(players) do
			if not self.player:canSlash(enemy, slash) then continue end
			if self:isEnemy(enemy) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy)
				and sgs.isGoodTarget(enemy, players, self) and not table.contains(targets, enemy:objectName()) then
				table.insert(targets, enemy:objectName())
			end
		end

		for _, friend in ipairs(players) do
			if not self.player:canSlash(friend, slash) then continue end
			if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, slash, friend)
				and not self:slashProhibit(slash, friend) and self:slashIsEffective(slash, friend)
				and (self:needDamagedEffects(friend, self.player, true) or self:needToLoseHp(friend, self.player, true))
				and not table.contains(targets, friend:objectName()) then
				table.insert(targets, friend:objectName())
			end
		end

		if self:isWeak() then
			for _, enemy in ipairs(players) do
				if not self.player:canSlash(enemy, slash) then continue end
				if not table.contains(targets, enemy:objectName()) and self:isEnemy(enemy) then
					table.insert(targets, enemy:objectName())
				end
			end
		end

		if self:isWeak() then
			for _, friend in ipairs(players) do
				if not self.player:canSlash(friend, slash) then continue end
				if not table.contains(targets, friend:objectName()) and self:isFriend(friend) and (not self:isFriend(friend) or getKnownCard(friend, self.player, "Jink", true) > 0) then
					table.insert(targets, friend:objectName())
				end
			end
		end

		if #targets > 0 then
			return slash:toString() .. "->" .. table.concat(targets, "+", 1, EXT)
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_weimu = function(self, data)
	local use = data:toCardUse()
	if not use.card then return false end
	if use.card:isKindOf("HThreatenEmperor") then return false end
	if self.player:isChained() then
		if use.card:isKindOf("HFightTogether") then return false end
		if use.card:isKindOf("IronChain") then return false end
	end
	if use.card:isKindOf("HImperialOrder") then
		if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
			local reward = true
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:hasShownOneGeneral() then
					reward = false
					break
				end
			end
			if reward then return true end
		else
			return false
		end
	end
	if self:isWeak() then return true end
	if not self:willShowForDefence() then return false end
	return true
end

sgs.ai_skill_invoke.wansha = function(self, data)
	return not self:isFriend(data:toDying().who)
end

sgs.ai_skill_cardask["@guidao-card"]=function(self, data)
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1
	and not self.player:hasShownGeneral1() and self.player:inHeadSkills("guidao") and not self:isWeak() then--君主
		return "."
	end
	if not (self:willShowForAttack() or self:willShowForDefence() ) then return "." end
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		all_cards:prepend(sgs.Sanguosha:getCard(id))
	end
	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade
						and sgs.ai_AOE_data and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and self:findLeijiTarget(self.player, 50)
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
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 then return "." end
	if keptspade == 1 and not self.player:hasSkill("nosleiji") then return "." end

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

function sgs.ai_cardneed.guidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:containsTrick("lightning") and self:getFinalRetrial(to, "lightning") == 1  then
			return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self.player:hasSkill("hongyan")
		end
		if self:isFriend(player) and self:willSkipDrawPhase(player) and self:getFinalRetrial(to, "supply_shortage") == 1 then
			return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
		end
	end
	if to:hasShownSkill("nosleiji") and self:getFinalRetrial(to, "nosleiji")then
		return card:isBlack()
	end
end

function SmartAI:findLeijiTarget(player, leiji_value, slasher)
	if not player:hasShownSkill("nosleiji") then return end
	if slasher then
		if not self:slashIsEffective(sgs.cloneCard("slash"), player, slasher, slasher:hasWeapon("QinggangSword")) then return nil end
		if self:canLiegong(player, slasher) and self:isEnemy(player, slasher) then
			return nil
		end
		if not self:hasSuit("spade", true, player) and player:getHandcardNum() < 3 then return nil end
		local hasJink
		if getKnownCard(player, self.player, "Jink", true) > 0 then hasJink = true end
		if not hasJink and player:getHandcardNum() >= 3 and getCardsNum("Jink", player, self.player) >= 1 and sgs.card_lack[player:objectName()]["Jink"] ~= 1 then hasJink = true end
		if not hasJink and not self:isWeak(player) and self:hasEightDiagramEffect(player) and not slasher:hasWeapon("QinggangSword") then hasJink = true end
		if not hasJink then return end
	end
	local getCmpValue = function(enemy)
		local value = 0
		local damage = {}
		damage.to = enemy
		damage.from = player
		damage.nature = sgs.DamageStruct_Thunder
		damage.damage = 2
		if not self:damageIsEffective_(damage) then return 99 end
		if enemy:hasShownSkill("hongyan") then return 99 end
		if self:cantbeHurt(enemy, player, 2) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget_(damage)) then return 100 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value + 50 end
		if enemy:hasArmorEffect("SilverLion") then value = value + 20 end
		if sgs.originalHegemonyHasShownSkills(enemy, sgs.exclusive_skill) then value = value + 10 end
		if sgs.originalHegemonyHasShownSkills(enemy, sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget_(damage) and #(self:getChainedEnemies(player)) > 1 then value = value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + sgs.getDefenseSlash(enemy, self) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < leiji_value then return enemy end
	end
	return nil
end

function SmartAI:needLeiji(to, from)
	return self:findLeijiTarget(to, 50, from)
end


sgs.guidao_suit_value = {
	spade = 3.9,
	club = 2.7
}

sgs.ai_suit_priority.guidao= "diamond|heart|club|spade"

sgs.ai_skill_discard.beige = function(self)
	local damage = self.player:getTag("beige_data"):toDamage()
	if damage.from and self:isFriend(damage.from) and not damage.from:faceUp() and damage.to:getPile("incantation"):length() > 0 then		--和张宝的配合
		local id = damage.to:getPile("incantation"):first()
		if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
			return self:askForDiscard("dummy_reason", 1, 1, false, true)
		end
	end
	if damage.to and not self:isFriend(damage.to) or damage.from and self:isFriend(damage.from) then return {} end
	if not self:willShowForMasochism() then return {} end
	return self:askForDiscard("dummy_reason", 1, 1, false, true)
end

function sgs.ai_cardneed.beige(to, card)
	return to:getCardCount(true) <= 2
end

function sgs.ai_slash_prohibit.heg_duanchang(self, from, to)
	if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
	if (sgs.originalHegemonyGeneral(from, true):getKingdom() == "careerist" or from:isLord())
	and to:getHp() == 1 and #(self:getEnemies(from)) > 1 then--多个敌人时的野心家或君主
		return true
	end
	if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
	return false
end

sgs.ai_skill_choice.heg_duanchang = function(self, choices, data)
	local who = data:toPlayer()
	local needToDuanchangSkills = ""
	if self:isFriend(who) then
		if #sgs.originalHegemonySlotSkills(who, true) >= #sgs.originalHegemonySlotSkills(who, false) then
			return "deputy_general"
		end
	else
		if #sgs.originalHegemonySlotSkills(who, true) >= #sgs.originalHegemonySlotSkills(who, false) then
			return "head_general"
		end
	end

	local skills = (sgs.priority_skill .. "|" .. sgs.masochism_skill .. "|" .. sgs.recover_skill .. "|"
					.. sgs.wizard_skill .. "|" .. sgs.cardneed_skill):split("|")
	for _, skill in ipairs(skills) do
		if who:hasShownSkill(skill) then
			if self.player:isFriendWith(who) then--现在可以用sgs.general_value来判断武将强度
				return who:inHeadSkills(skill) and "deputy_general" or "head_general"
			else
				return who:inHeadSkills(skill) and "head_general" or "deputy_general"
			end
		end
	end

	return "head_general"
end

-- Shared HStandard V2 policies are registered by hegemony-ai.lua in every mode.

-- Preserve native V2 source identity for the existing Qun actions.
local function qunV2Card(name, id)

    local card = sgs.ActiveSkillCard()

    card:setSkillName(name)

    if id then card:addSubcard(id) end

    return card

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

		local qc_card = qunV2Card("heg_qingcheng", card_id)



		assert(qc_card)



		return qc_card

	end

end

sgs.ai_skill_use_func.heg_qingcheng = function(card, use, self)

	local room = self.room

	local heg_zhoutai = room:findPlayerBySkillName("heg_buqu")

	if heg_zhoutai and heg_zhoutai:getPile("heg_buqu"):length() > 1 and (heg_zhoutai:hasShownGeneral() and heg_zhoutai:hasShownGeneral2()) then

		use.card = card

		if use.to then

			if not use.isDummy then sgs.heg_qingcheng = "heg_zhoutai" end

			use.to:append(heg_zhoutai)

		end

		return

	end



	local dummy_use = {isDummy = true, to = sgs.SPlayerList()}

	local slash = sgs.cloneCard("Slash")

	self:useBasicCard(slash, dummy_use)

	if (dummy_use.card and dummy_use.to:length() > 0) then

		for _, p in sgs.qlist(dummy_use.to) do

			if not (p:hasShownGeneral() and p:hasShownGeneral2()) then continue end

			if self.player:isFriendWith(p) or (self:originalHegemonyOwnKingdom() == p:getKingdom()) then continue end

			local skill_table = sgs.masochism_skill:split("|")

			for _, skill_name in ipairs(skill_table) do

				if (p:hasShownSkill(skill_name)) then

					use.card = card

					if use.to then

						if not use.isDummy then sgs.heg_qingcheng = (p:inHeadSkills(skill_name) and p:getGeneral():objectName() or p:getGeneral2():objectName()) end

						use.to:append(p)

					end

					return

				end

			end

		end

	end



	return

end

sgs.ai_skill_choice.heg_qingcheng = function(self, choices)

	return sgs.heg_qingcheng

end

sgs.ai_use_value.heg_qingcheng = 6

sgs.ai_use_priority.heg_qingcheng = sgs.ai_use_priority.Slash + 0.1

sgs.ai_card_intention.heg_qingcheng = 100

sgs.ai_fill_skill.heg_huoshui = function(self)

	if not self:willShowForAttack() or self.player:hasShownSkill(sgs.Sanguosha:getSkill("heg_huoshui")) then return nil end

	local card = qunV2Card("heg_huoshui")

	assert(card)

	return card

end

function sgs.ai_skill_use_func.heg_huoshui(card, use, self)

	use.card = card

end

sgs.ai_use_priority.heg_huoshui = 10
