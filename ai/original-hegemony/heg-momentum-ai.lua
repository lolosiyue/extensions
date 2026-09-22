-- V2 actions retain their skill ID through the common proxy.
local function momentumV2Card(name, id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    if id then card:addSubcard(id) end
    return card
end

-- Loaded only by the admitted Original Hegemony bundle in this Room VM.
if not sgs.original_hegemony_ai_loading then return end

--[[********************************************************************
	Copyright (c) 2013-2014 - QSanguosha-Rara

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

  QSanguosha-Rara
*********************************************************************]]
function sgs.ai_skill_invoke.heg_hengjiang(self, data)
	if not self:willShowForMasochism() then return false end
	local target = data:toPlayer()
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

sgs.ai_skill_invoke.heg_yongjue = true

sgs.ai_skill_choice.heg_yingyang = function(self, choices, data)
	local pindian = data:toPindian()
	local reason = pindian.reason
	local from, to = pindian.from, pindian.to
	local f_num, t_num = pindian.from_number, pindian.to_number
	local amFrom = self.player:objectName() == from:objectName()

	local table_pindian_friends = { "heg_tianyi", "heg_shuangren" }
	if reason == "heg_quhu" then
		if amFrom and self.player:hasSkill("heg_jieming") then
			if f_num > 8 then return "jia3"
			elseif self:getJiemingChaofeng(self.player) <= -6 then return "jian3"
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
sgs.ai_use_priority.heg_duanxie = 0

sgs.ai_skill_invoke.heg_fenming = function(self)
	local value, count = 0, 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:isChained() then
			count = count + 1
			if self:isFriend(player) then
				if self:needToThrowArmor(player) then
					value = value + 1
				elseif player:getHandcardNum() == 1 and self:needKongcheng(player) then
					value = value + 0.2
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
			end
		end
	end
	--self.room:writeToConsole(value / count)
	return value / count >= 0.2
end

sgs.ai_skill_invoke.heg_hengzheng = function(self, data)
	local value = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		value = value + self:getGuixinValue(player)
	end
	return value >= 1.3
end

sgs.ai_skill_invoke.heg_chuanxin = function(self, data)
	local damage = data:toDamage()

	if damage.to:hasShownSkill("heg_niepan") and not damage.to:inHeadSkills("heg_niepan") and  damage.to:getMark("@nirvana") > 0 then
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

sgs.ai_use_priority.heg_wendao = sgs.ai_use_priority.ZhihengCard or 2.8

sgs.ai_skill_invoke.heg_hongfa = true

local getHongfaCard = function(pile)
	for _, c in ipairs(pile) do
		if sgs.Sanguosha:getCard(c):objectName() == "PeaceSpell" then return c end
	end
	for _, c in ipairs(pile) do
		if sgs.Sanguosha:getCard(c):objectName() ~= "DragonPhoenix" then return c end
	end
	if #pile > 0 then return pile[1] end
	return nil
end

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

sgs.ai_cardsview.heg_hongfa_slash = function(self, class_name, player)
	if class_name ~= "Slash" then return end
	local zj = player:getLord()
	if (not zj or zj:getPile("heavenly_army"):isEmpty() or not zj:isFriendWith(player)) then return end
	local ints = zj:getPile("heavenly_army")
	local card_str = {}
	local PeaceSpell, DragonPhoenix
	for _, int in sgs.qlist(ints) do
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local id = card:getEffectiveId()
		if card:objectName() == "PeaceSpell" then
			PeaceSpell = string.format("slash:heg_hongfa_slash[%s:%s]=%d&", suit, number, id)
		elseif card:objectName() == "DragonPhoenix" then
			DragonPhoenix = string.format("slash:heg_hongfa_slash[%s:%s]=%d&", suit, number, id)
		else
			table.insert(card_str, string.format("slash:heg_hongfa_slash[%s:%s]=%d&", suit, number, id))
		end
	end
	if PeaceSpell then table.insert(card_str, 1, PeaceSpell) end
	if DragonPhoenix then table.insert(card_str, DragonPhoenix) end
	return card_str
end

-- Selection is now carried by SkillContext; no synthetic card use or Player Tag.
sgs.ai_skill_askforag.heg_hongfa = function(self, card_ids)
    return getHongfaCard(card_ids) or -1
end

sgs.ai_skill_choice.heg_hongfa_num = function(self, choices, data)
    local count = data:toPlayerNum()
    if count.m_reason == "heg_wuxin" or count.m_reason == "heg_hongfa" or count.m_reason == "PeaceSpell" then
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

sgs.ai_slash_prohibit.heg_PeaceSpell = function(self, from, enemy, card)
	if enemy:hasArmorEffect("PeaceSpell") and card:isKindOf("NatureSlash") and not IgnoreArmor(from, enemy) then return true end
	return
end
function sgs.ai_armor_value.PeaceSpell(player, self)
	if sgs.originalHegemonyHasShownSkills(player, "heg_hongfa+heg_wendao") then return 1000 end
	if getCardsNum("Peach", player, player) + getCardsNum("Analeptic", player, player) == 0 and player:getHp() == 1 then
		if player:hasArmorEffect("PeaceSpell") then return 99
		else return -99
		end
	end
	return 3.5
end

sgs.ai_use_priority.PeaceSpell = 0.75
