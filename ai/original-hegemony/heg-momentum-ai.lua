-- Source: TODO/QSanguosha-For-Hegemony-xxyheaven/lua/ai/momentum-ai.lua (cf61c15).
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
local function momentumV2Card(name, id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    if id then card:addSubcard(id) end
    return card
end

if not sgs.original_hegemony_ai_loading then return end

sgs.ai_skill_movecards.heg_xunxun = function(self, upcards, downcards, min_num, max_num)
	local upcards_copy = table.copyFrom(upcards)
	local down = {}
	local id1 = self:askForAG(upcards_copy,false,"heg_xunxun")
	down[1] = id1
	table.removeOne(upcards_copy,id1)
	local id2 = self:askForAG(upcards_copy,false,"heg_xunxun")
	down[2] = id2
	table.removeOne(upcards_copy,id2)
	return upcards_copy,down
end

function sgs.ai_cardneed.heg_wangxi(to, card)
	return card:isKindOf("AOE") or card:isKindOf("Crossbow")
end

sgs.wangxi_keep_value = {
	Crossbow = 6,
	SavageAssault = 5.2,
	ArcheryAttack = 5.2
}

function sgs.ai_skill_invoke.heg_hengjiang(self, data)
	if not self:willShowForMasochism() then return false end
	local target = data:toPlayer()
	if not target then target = data:toDamage().from end
	if not target then return end
	if self:isFriend(target) then
		return false
	else
		return true
	end
end

sgs.ai_choicemade_filter.skillInvoke.heg_hengjiang = function(self, player, promptlist)
	if promptlist[3] == "yes" then
		local current = self.room:getCurrent()
		if current and current:getPhase() <= sgs.Player_Discard
			and not (current:hasShownSkill("heg_keji") and not current:hasFlag("KejiSlashInPlayPhase")) and current:getHandcardNum() > current:getMaxCards() - 2 then
			sgs.updateIntention(player, current, 50)
		end
	end
end

sgs.ai_skill_cardask["@heg_qianxi-discard"] = function(self, data, pattern, target, target2)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	self.qianxi_isred = cards[1]:isRed()
	if cards[1]:isBlack() and #cards > 1 then
		if cards[2]:isRed() and not cards[2]:isKindOf("Peach") then
			self.qianxi_isred = cards[2]:isRed()
			return cards[2]:toString()
		end
	end
	return cards[1]:toString()--必须弃1
end

sgs.ai_skill_playerchosen.qianxi_target = function(self, targets)
	local enemies = {}
	local slash = self:getCard("Slash") or sgs.cloneCard("slash")

	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) and not target:isKongcheng() then
			table.insert(enemies, target)
		end
	end
	self:sort(enemies, "defenseSlash")

	if #enemies == 1 then
		return enemies[1]
	else
		if not self.qianxi_isred then
			for _, enemy in ipairs(enemies) do
				if enemy:hasShownSkill("qingguo") and self:slashIsEffective(slash, enemy) then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if enemy:hasShownSkill("heg_kanpo") then return enemy end
			end
		else
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Peach", true, "h") > 0 or enemy:hasShownSkill("jijiu") then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) then return enemy end
			end
		end
		return enemies[1]
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)--ai默认函数
end

sgs.ai_playerchosen_intention.qianxi_target = 60

function sgs.ai_cardneed.heg_qianxi(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic") or (card:isRed() and getKnownCard(to, self.player, "red", false) < 2)
end

sgs.ai_skill_invoke.heg_guixiu = true

sgs.ai_fill_skill.heg_cunsi = function(self)
	return momentumV2Card("heg_cunsi")
end

sgs.ai_skill_use_func.heg_cunsi = function(card, use, self)

	local all_shown = true
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:hasShownOneGeneral() then
			all_shown = false
			break
		end
	end

	local to
	for _, friend in ipairs(self.friends_noself) do
		if sgs.originalHegemonyPublicKingdom(friend) == self:originalHegemonyOwnKingdom() and ( self:isWeak(friend) or self.player:getLostHp() > 0 )then
			to = friend
			break
		end
	end
	if to then
		use.card = card
		if use.to then use.to:append(to) end
	end
	if use.card then return end

	if all_shown and #self.friends_noself == 0 and self.player:getLostHp() > 0 then
		use.card = card
		if use.to then use.to:append(self.player) end
	end
end

sgs.ai_use_priority.heg_cunsi = 11

sgs.ai_skill_choice.heg_yongjue = function(self)
	return "yes"
end

sgs.ai_skill_choice.heg_yingyang = function(self, choices, data)
	local pindian = data:toPindian()
	local reason = pindian.reason
	local from, to = pindian.from, pindian.to
	local f_num, t_num = pindian.from_number, pindian.to_number
	local amFrom = self.player:objectName() == from:objectName()

	local table_pindian_friends = { "tianyi", "heg_fenglve", "heg_fenglvezongheng" }
	if reason == "quhu" then
		local heg_xunyu = sgs.findPlayerByShownSkillName("heg_jieming")
		if not amFrom and heg_xunyu and self:isFriend(heg_xunyu) then
			if self:getJiemingDrawNum(heg_xunyu) >= 3 then return "jia3"
			elseif f_num > 8 then return "jian3"
			end
		end
		return "jia3"
	elseif table.contains(table_pindian_friends, reason) then
		return (not amFrom and self:isFriend(from)) and "jian3" or "jia3"
	else
		return "jia3"
	end
end

sgs.ai_skill_invoke.heg_hunshang = true

sgs.ai_fill_skill.heg_duanxie = function(self)

	if not self:willShowForAttack() then
		return
	end

	if self.player:hasUsed("HDuanxieCard") then return end
	return momentumV2Card("heg_duanxie")
end

sgs.ai_skill_use_func.heg_duanxie = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isChained() and not self:getDamagedEffects(enemy) and not self:needToLoseHp(enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
			target = enemy
			break
		end
	end
	if not target then return end
	if not self:isWeak() or self.player:isChained() then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_card_intention.heg_duanxie = 60

sgs.ai_use_priority.HDuanxieCard = 0.5

sgs.ai_skill_invoke.heg_fenming = function(self, data)
	local value, count = 0, 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:isChained() then
			count = count + 1
			if self:isFriend(player) then
				if self:needToThrowArmor(player) then
					value = value + 1
				elseif player:getHandcardNum() == 1 and self:needKongcheng(player) then
					value = value + 1
				elseif self.player:canDiscard(player, "he") then
					local dec = self:isWeak(player) and 1.2 or 0.8
					if player:objectName() == self.player:objectName() then dec = dec / 1.5 end
					if self:getOverflow(player) >= 0 then dec = dec / 1.5 end
					value = value - dec
				end
			elseif self:isEnemy(player) then
				if self.player:canDiscard(player, "he") then
					if self:doNotDiscard(player) then
						value = value - 0.8
					else
						local dec = self:isWeak(player) and 1.2 or 0.8
						if self:getValuableCard(player) or self:getDangerousCard(player) then dec = dec * 1.5 end
						value = value + dec
					end
				end
			else
				value = value + 0.5
			end
		end
	end
	return value / count >= 0.2
end

sgs.ai_skill_exchange.heg_fenming = function(self)
	local result = self:askForDiscard("dummy_reason", 1, 1, false, true)
	if type(result) == "number" then return { result } end
	return result
end

sgs.ai_skill_invoke.heg_hengzheng = function(self, data)
	local value = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isNude() and p:getJudgingArea():isEmpty() then continue end
		if self:isFriend(p) then
			local good = false
			if not p:getJudgingArea():isEmpty() then
				value = value + 1.5
				good = true
			end
			if self:needToThrowArmor(p) then
				value = value + 1.2
				good = true
			end
			if p:getEquips():length() > 0 and sgs.originalHegemonyHasShownSkills(p, sgs.lose_equip_skill) then
				value = value + 1
				good = true
			end
			if p:hasShownSkill("heg_tuntian") then
				value = value + 0.5
				good = true
			end
			if self:needKongcheng(p, false, true) and p:getHandcardNum() == 1 then
				value = value + 0.8
				good = true
			end
			if not good then
				value = value - 1
			end
		elseif self:isEnemy(p) then
			if p:isNude() then
				value = value - 1.5
			else
				if self:getDangerousCard(p) or self:getValuableCard(p) then
					value = value + 0.8
					if sgs.originalHegemonyHasShownSkills(p, sgs.lose_equip_skill) then
						value = value - 1
					end
				elseif p:getEquips():isEmpty() then
					if self:needKongcheng(p, false, true) and p:getHandcardNum() == 1 then
						value = value - 0.8
					end
					if getKnownCard(p, self.player, "Peach", true, "h") > 0 or getKnownCard(p, self.player, "Analeptic", true, "h") > 0 then
						value = value + 2 / p:getHandcardNum()
					end
				elseif p:isKongcheng() then
					if p:getEquips():length() == 1 and self:needToThrowArmor(p) then
						value = value - 1
					end
					if sgs.originalHegemonyHasShownSkills(p, sgs.lose_equip_skill) then
						value = value - 1
					end
				end
				if p:hasShownSkill("heg_tuntian") then
					value = value - 0.5
				end
				value = value + 1
			end
		else
			value = value + 1
		end
	end
	if value > 2 then
		return true
	end
	return false
end

sgs.ai_skill_invoke.heg_chuanxin = function(self, data)
	local damage = data:toDamage()
	if damage.to:hasShownSkill("heg_niepan") and not damage.to:inHeadSkills("heg_niepan") and damage.to:getMark("@nirvana") > 0 then
		return true
	end
	return not self:isFriend(damage.to)
		and not self:hasHeavySlashDamage(self.player, damage.card, damage.to)
		and not (damage.to:getHp() == 1 and not damage.to:getArmor())
end

sgs.ai_skill_choice.heg_chuanxin = function(self, choices)
    if choices:match("discard") then return "discard" end
    return choices:split("+")[1]
end

sgs.ai_skill_invoke.heg_wuxin = true

sgs.ai_fill_skill.heg_wendao = function(self)
	if not self.player:hasUsed("HWendaoCard") then
		local invoke = "no"
		local discardpile = self.room:getDiscardPile()
		local owner = nil
		for _, i in sgs.qlist(discardpile) do
			if sgs.Sanguosha:getCard(i):objectName() == "PeaceSpell" then
				invoke = "di"
				break
			end
		end
		if invoke == "no" then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:getArmor() and p:getArmor():objectName() == "PeaceSpell" then
					invoke = "eq"
					owner = p
					break
				end
			end
		end
		if invoke ~= "no" then
			if invoke == "eq" then
				assert(owner)
				if owner:hasArmorEffect("PeaceSpell") then
					if (owner:objectName() == self.player:objectName()) then
						if (not self.player:hasSkill("heg_hongfa")) or (self.player:getPile("heavenly_army"):isEmpty()) then
							if self.player:getHp() <= 1 then return nil end
						end
					else
						if (self.player:isFriendWith(owner)) then
							if not self:needToLoseHp(owner, self.player) then return nil end
							if owner:isChained() then return nil end
						else
							if self:needToLoseHp(owner, self.player) then return nil end
						end
					end
				end
			end
			local cards = sgs.QList2Table(self.player:getCards("he"))
			self:sortByKeepValue(cards)
			local cards_copy = {}
			for _, c in ipairs(cards) do
				table.insert(cards_copy, c)
			end
			for _, c in ipairs(cards_copy) do
				if c:objectName() == "PeaceSpell" then
					return momentumV2Card("heg_wendao", c:getEffectiveId())
				end
				if (not c:isRed()) or isCard("Peach", c, self.player) then table.removeOne(cards, c) end
			end
			if #cards == 0 then return nil end
			return momentumV2Card("heg_wendao", cards[1]:getEffectiveId())
		end
	end
	return nil
end

sgs.ai_skill_use_func.heg_wendao = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.heg_wendao = sgs.ai_use_priority.HZhihengCard or 2.8

sgs.ai_skill_invoke.heg_hongfa = true

local getHongfaCard = function(self,pile)
	for _, id in ipairs(pile) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("HPeaceSpell") then
			return id
		elseif card:isKindOf("HDragonPhoenix") then
			local lord = self.room:getLord("shu")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("HLuminousPearl") then
			local lord = self.room:getLord("wu")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("HSixDragons") then
			local lord = self.room:getLord("wei")
			if not lord or self:isFriend(lord) then
				return id
			end
		else
			return id
		end
	end
	if #pile > 0 then return pile[1] end
	return nil
end

local huangjinsymbol_skill = {}

huangjinsymbol_skill.name = "huangjinsymbol"

table.insert(sgs.ai_skills, huangjinsymbol_skill)

huangjinsymbol_skill.getTurnUseCard = function(self, inclusive)
	local zj = self.room:getLord("qun")
	if not zj or zj:getPile("heavenly_army"):isEmpty() or not self.player:willBeFriendWith(zj) then return end
	local ints = sgs.QList2Table(zj:getPile("heavenly_army"))

	local int = getHongfaCard(self,ints)
	if int then
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

-- HEG uses a distinct canonical skill ID while reusing the same public pile
-- selection policy as the identity-mode donor skill.
local heg_huangjinsymbol_skill = {}
heg_huangjinsymbol_skill.name = "heg_huangjinsymbol"
table.insert(sgs.ai_skills, heg_huangjinsymbol_skill)
heg_huangjinsymbol_skill.getTurnUseCard = function(self, inclusive)
	local lord = self.room:getLord("qun")
	if not self.player:hasShownOneGeneral() or not lord or lord:getPile("heavenly_army"):isEmpty()
		or not self.player:isFriendWith(lord) then return end
	local ids = sgs.QList2Table(lord:getPile("heavenly_army"))
	local id = getHongfaCard(self, ids)
	if not id then return end
	local material = sgs.Sanguosha:getCard(id)
	local wire = string.format("slash:heg_huangjinsymbol[%s:%s]=%d&", material:getSuitString(), material:getNumberString(), material:getEffectiveId())
	local slash = sgs.Card_Parse(wire)
	assert(slash)
	return slash
end

sgs.ai_cardsview.huangjinsymbol = function(self, class_name, player)
	if class_name ~= "Slash" then return end
	local zj = player:getLord()
	if not zj or zj:getPile("heavenly_army"):isEmpty() or not self.player:willBeFriendWith(zj) then return end
	local ints = zj:getPile("heavenly_army")
	local card_str = {}
	local HPeaceSpell, lord_equip
	for _, int in sgs.qlist(ints) do
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local id = card:getEffectiveId()
		if card:isKindOf("HPeaceSpell") then
			HPeaceSpell = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id)
		elseif card:isKindOf("HDragonPhoenix") or card:isKindOf("HLuminousPearl") or card:isKindOf("HSixDragons") then
			lord_equip = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id)
		else
			table.insert(card_str, string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id))
		end
	end
	if HPeaceSpell then table.insert(card_str, 1, HPeaceSpell) end
	if lord_equip then table.insert(card_str, lord_equip) end
	return card_str
end

sgs.ai_cardsview.heg_huangjinsymbol = function(self, class_name, player)
	if class_name ~= "Slash" then return end
	local lord = player:getLord()
	if not player:hasShownOneGeneral() or not lord or lord:getPile("heavenly_army"):isEmpty()
		or not player:isFriendWith(lord) then return end
	local ids = sgs.QList2Table(lord:getPile("heavenly_army"))
	local cards = {}
	for _, id in ipairs(ids) do
		local card = sgs.Sanguosha:getCard(id)
		local wire = string.format("slash:heg_huangjinsymbol[%s:%s]=%d&", card:getSuitString(), card:getNumberString(), card:getEffectiveId())
		table.insert(cards, wire)
	end
	return cards
end

sgs.ai_skill_invoke.huangjinsymbol = true
sgs.ai_skill_invoke.heg_huangjinsymbol = true

sgs.ai_skill_askforag.heg_huangjinsymbol = function(self, card_ids)
	return getHongfaCard(self, card_ids) or -1
end

sgs.ai_skill_exchange["huangjinsymbol"] = function(self,pattern,max_num,min_num,expand_pile)
	global_room:writeToConsole("君角防止体力流失")
	local ints = sgs.QList2Table(self.player:getPile("heavenly_army"))
	local int = getHongfaCard(self,ints)
	if int then
		return {int}
	end
	return {}
end

sgs.ai_slash_prohibit.heg_PeaceSpell = function(self, from, enemy, card)
	if from:hasShownSkill("heg_zhiman") then return false end
	if enemy:hasArmorEffect("PeaceSpell") and card:isKindOf("NatureSlash")
	and not IgnoreArmor(from, enemy) and not from:hasWeapon("IceSword") then return true end
end

function sgs.ai_armor_value.HPeaceSpell(player, self)
	if sgs.originalHegemonyHasShownSkills(player, "heg_hongfa+heg_wendao") then return 1000 end
--[[太平效果修改
	if getCardsNum("Peach", player, player) + getCardsNum("Analeptic", player, player) == 0 and player:getHp() == 1 then
		if player:hasArmorEffect("PeaceSpell") then return 99
		else return -99
		end
	end
]]
	--进攻缺牌需要摸2怎么写？条件：目标1血，能使用杀等。如果能知道上一个杀目标就好写了
	local v = 4.5
	for _, p in ipairs(self:getFriendsNoself(player)) do
		if player:isFriendWith(p) then
			v = v + 0.5
		end
	end
	if self:getOverflow(player) > 0 then
		v = v + 0.5
	end
	if player:getMark("GlobalBattleRoyalMode") > 0 and player:hasArmorEffect("PeaceSpell") and player:getHp() > 1 then--鏖战别失去体力
		v = v + 1.5
	end
	return v
end

sgs.ai_use_priority.HPeaceSpell = 0.75

sgs.ai_skill_askforag.heg_hongfa = function(self, card_ids)
    return getHongfaCard(self, card_ids) or -1
end

sgs.ai_skill_choice.hongfa_num = function(self, choices, data)
    local count = data:toPlayerNum()
    if count.m_reason == "heg_wuxin" or count.m_reason == "heg_hongfa" or count.m_reason == "HPeaceSpell" then
        local options = choices:split("+")
        return options[#options]
    end
    return "0"
end

sgs.ai_fill_skill.heg_guixiu = function(self)
    return momentumV2Card("heg_guixiu")
end

sgs.ai_skill_use_func.heg_guixiu = function(card, use, self) use.card = card end

sgs.ai_fill_skill.heg_fengshi = function(self) return momentumV2Card("heg_fengshi") end

sgs.ai_skill_use_func.heg_fengshi = function(card, use, self) use.card = card end

sgs.ai_skill_invoke.heg_fengshi = function(self, data) return self:isEnemy(data:toPlayer()) end

sgs.ai_fill_skill.heg_hongfa_slash = function(self, inclusive)
	local zj = self.room:getLord("qun")
	if (not zj or zj:getPile("heavenly_army"):isEmpty() or not zj:isFriendWith(self.player)) then return end
	local ints = sgs.QList2Table(zj:getPile("heavenly_army"))

	local int = getHongfaCard(ints)
	if int then
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = string.format("slash:heg_hongfa_slash[%s:%s]=%d&", suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end
