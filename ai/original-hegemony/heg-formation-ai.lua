-- Identity skills keep the same IDs; reuse existing identity AI policies where
-- their decisions still match, adapting only the V2 response wire format.
if not sgs.GetConfig("EnableHegemony", false) then
    local function proxy(name, id)
        local card = sgs.ActiveSkillCard()
        card:setSkillName(name)
        if id then card:addSubcard(id) end
        return card
    end
    sgs.ai_skill_invoke.heg_tianfu = function(self, data)
        local owner = data:toPlayer()
        return owner and self:isFriend(owner)
    end
    sgs.ai_skill_invoke.heg_qianhuan = function(self, data)
        local owner = data:toPlayer()
        return owner and self:isFriend(owner) and owner:getPile("sorcery"):length() < 4
    end
    sgs.ai_skill_invoke.heg_niaoxiang = function(self, data)
        if sgs.ai_skill_invoke.niaoxiang then return sgs.ai_skill_invoke.niaoxiang(self, data) end
        local target = data:toPlayer()
        return target and self:isEnemy(target)
    end
    sgs.ai_skill_invoke.heg_yicheng = function(self, data)
        if sgs.ai_skill_invoke.yicheng then return sgs.ai_skill_invoke.yicheng(self, data) end
        local target = data:toPlayer()
        return target and self:isFriend(target)
    end
    sgs.ai_skill_invoke.heg_shengxi = true
    sgs.ai_skill_invoke.heg_shoucheng = function(self, data)
        if sgs.ai_skill_invoke.shoucheng then return sgs.ai_skill_invoke.shoucheng(self, data) end
        local move = data:toMoveOneTime()
        local target = move.from and self.room:findPlayerByObjectName(move.from:objectName())
        return target and self:isFriend(target) and not hasManjuanEffect(target)
            and not self:needKongcheng(target, true)
    end
    sgs.ai_skill_choice.heg_shoucheng = function(self, choices)
        -- This decision belongs to the recipient, after the owner's invocation.
        return (hasManjuanEffect(self.player) or self:needKongcheng(self.player, true)) and "reject" or "accept"
    end
    sgs.ai_skill_use["@@heg_ziliang"] = function(self)
        local damage = self.player:getTag("ziliang_aidata"):toDamage()
        if not damage.to or not self:isFriend(damage.to) or hasManjuanEffect(damage.to)
            or self:needKongcheng(damage.to, true) then return "." end
        local cards = {}
        for _, id in sgs.qlist(self.player:getPile("field")) do
            table.insert(cards, sgs.Sanguosha:getCard(id))
        end
        self:sortByKeepValue(cards)
        return cards[1] and proxy("heg_ziliang", cards[1]:getEffectiveId()):toString() or "."
    end
    sgs.ai_skill_use["@@heg_heyi"] = function(self)
        local others = sgs.QList2Table(self.room:getOtherPlayers(self.player))
        local selected, names = {[self.player:objectName()] = true}, {self.player:objectName()}
        local function include(player)
            if not self:isFriend(player) then return false end
            local name = player:objectName()
            if not selected[name] then selected[name] = true; table.insert(names, name) end
            return true
        end
        for i = 1, #others do if not include(others[i]) then break end end
        for i = #others, 1, -1 do if not include(others[i]) then break end end
        return #names > 1 and (proxy("heg_heyi"):toString() .. "->" .. table.concat(names, "+")) or "."
    end
    sgs.ai_skill_use["@@heg_qianhuan"] = function(self)
        local use = self.player:getTag("qianhuan_data"):toCardUse()
        if not use.card or use.to:isEmpty() or self.player:getPile("sorcery"):isEmpty() then return "." end
        local invoke = sgs.ai_skill_invoke.qianhuan
        local cancel
        if invoke then
            cancel = invoke(self, self.player:getTag("qianhuan_data"))
        else
            local target = use.to:first()
            cancel = self:isFriend(target) and not (use.from and use.from:objectName() == target:objectName())
                and not use.card:isKindOf("Peach") and not use.card:isKindOf("Analeptic")
                and not use.card:isKindOf("ExNihilo")
        end
        if cancel then
            return proxy("heg_qianhuan", self.player:getPile("sorcery"):first()):toString()
        end
        return "."
    end
    sgs.ai_fill_skill.heg_shangyi = function(self) return proxy("heg_shangyi") end
    sgs.ai_skill_use_func.heg_shangyi = function(card, use, self)
        if sgs.ai_skill_use_func.ShangyiCard then
            sgs.ai_skill_use_func.ShangyiCard(card, use, self)
            return
        end
        self:sort(self.enemies, "handcard")
        for i = #self.enemies, 1, -1 do
            if not self.enemies[i]:isKongcheng() then
                use.card = card
                if use.to then use.to:append(self.enemies[i]) end
                return
            end
        end
    end
    sgs.ai_skill_choice.heg_shangyi = function(self, choices)
        return string.find(choices, "handcards", 1, true) and "handcards" or "role"
    end
    sgs.ai_use_value.heg_shangyi = 4
    sgs.ai_use_priority.heg_shangyi = 9
    sgs.ai_card_intention.heg_shangyi = 50
    return
end

-- Hegemony policies are loaded only by the admitted bundle in this Room VM.
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

-- Selection replies and playable actions share the existing V2 proxy format.
local function formationProxy(name, id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    if id then card:addSubcard(id) end
    return card
end

local getZiliangCard = function(self, damage)
	if not (damage.to:getPhase() == sgs.Player_NotActive and self:needKongcheng(damage.to, true)) then
		local ids = sgs.QList2Table(self.player:getPile("field"))
		local cards = {}
		for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") or card:isKindOf("Analeptic") then return card:getEffectiveId() end
		end
		for _, card in ipairs(cards) do
			if card:isKindOf("Jink") then return card:getEffectiveId() end
		end
		self:sortByKeepValue(cards, true)
		return cards[1]:getEffectiveId()
	else
		return nil
	end
end

sgs.ai_skill_use["@@heg_ziliang"] = function(self)
	local damage = self.player:getTag("ziliang_aidata"):toDamage()
	local id = getZiliangCard(self, damage)
	if id then
		return formationProxy("heg_ziliang", id):toString()
	end
	return "."
end

local function heg_huyuan_validate(self, equip_type, is_handcard)
	local targets = {}
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type == "SilverLion" then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasShownSkill("heg_bazhen") and not enemy:getArmor() then table.insert(targets, enemy) end
		end
	end
	for _, friend in ipairs(targets) do
		local has_equip = false
		for _, equip in sgs.qlist(friend:getEquips()) do
			if equip:isKindOf(equip_type == "SilverLion" and "Armor" or equip_type) then
				has_equip = true
				break
			end
		end
		if not has_equip and not ((equip_type == "Armor" or equip_type == "SilverLion") and friend:hasShownSkill("heg_bazhen")) then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if friend:distanceTo(enemy) == 1 and self.player:canDiscard(enemy, "he") then
					enemy:setFlags("AI_HuyuanToChoose")
					return friend
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@heg_huyuan"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("SilverLion") then
		local player = heg_huyuan_validate(self, "SilverLion", false)
		if player then return formationProxy("heg_huyuan", self.player:getArmor():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getOffensiveHorse() then
		local player = heg_huyuan_validate(self, "OffensiveHorse", false)
		if player then return formationProxy("heg_huyuan", self.player:getOffensiveHorse():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getWeapon() then
		local player = heg_huyuan_validate(self, "Weapon", false)
		if player then return formationProxy("heg_huyuan", self.player:getWeapon():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3 then
		local player = heg_huyuan_validate(self, "Armor", false)
		if player then return formationProxy("heg_huyuan", self.player:getArmor():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") then
			local player = heg_huyuan_validate(self, "DefensiveHorse", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") then
			local player = heg_huyuan_validate(self, "OffensiveHorse", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			local player = heg_huyuan_validate(self, "Weapon", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") then
			local player = heg_huyuan_validate(self, "SilverLion", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
		if card:isKindOf("Armor") and heg_huyuan_validate(self, "Armor", true) then
			local player = heg_huyuan_validate(self, "Armor", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
end

sgs.ai_skill_playerchosen.heg_huyuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("AI_HuyuanToChoose") then
			p:setFlags("-AI_HuyuanToChoose")
			return p
		end
	end
	return targets[1]
end

sgs.ai_card_intention.heg_huyuan = function(self, card, from, to)
	if to[1]:hasShownSkill("heg_bazhen") then
		if sgs.Sanguosha:getCard(card:getEffectiveId()):isKindOf("SilverLion") then
			sgs.updateIntention(from, to[1], 10)
			return
		end
	end
	sgs.updateIntention(from, to[1], -50)
end

sgs.ai_cardneed.heg_huyuan = sgs.ai_cardneed.equip

sgs.heg_huyuan_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 4.8
}


sgs.ai_skill_invoke.heg_shoucheng = function(self, data)
	local move = data:toMoveOneTime()
	if move and move.from then
		local from = findPlayerByObjectName(move.from:objectName())
		if from and self:isFriend(from) and not self:needKongcheng(move.from, true) then
			return true
		end
	end
	return false
end

local heg_shangyi_skill = {}
heg_shangyi_skill.name = "heg_shangyi"
table.insert(sgs.ai_skills, heg_shangyi_skill)
heg_shangyi_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if not self:willShowForAttack() then return end
	local heg_shangyi_card = formationProxy("heg_shangyi")
	assert(heg_shangyi_card)
	return heg_shangyi_card
end

sgs.ai_skill_use_func.heg_shangyi = function(card, use, self)
	self:sort(self.enemies, "handcard")

	for index = #self.enemies, 1, -1 do
		if not self.enemies[index]:isKongcheng() and self:objectiveLevel(self.enemies[index]) > 0 then
			use.card = card
			if use.to then
				use.to:append(self.enemies[index])
			end
			return
		end
	end
end

sgs.ai_skill_choice.heg_shangyi = function(self, choices)
	return "handcards"
end

sgs.ai_use_value.heg_shangyi = 4
sgs.ai_use_priority.heg_shangyi = 9
sgs.ai_card_intention.heg_shangyi = 50

sgs.ai_skill_invoke.heg_yicheng = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	return true
end

sgs.ai_skill_discard.heg_yicheng = function(self, discard_num, min_num, optional, include_equip)
	if self.player:hasSkill("heg_hongyan") then
		return self:askForDiscard("dummyreason", 1, 1, false, true)
	end

	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self:getCardsNum("Slash") > 1 then
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then table.insert(unpreferedCards, card:getId()) end
		end
		table.remove(unpreferedCards, 1)
	end

	local num = self:getCardsNum("Jink") - 1
	if self.player:getArmor() then num = num + 1 end
	if num > 0 then
		for _, card in ipairs(cards) do
			if card:isKindOf("Jink") and num > 0 then
				table.insert(unpreferedCards, card:getId())
				num = num - 1
			end
		end
	end
	for _, card in ipairs(cards) do
		if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
			or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") or card:isKindOf("Lightning") then
			table.insert(unpreferedCards, card:getId())
		end
	end

	if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
		table.insert(unpreferedCards, self.player:getWeapon():getId())
	end

	if self:needToThrowArmor() then
		table.insert(unpreferedCards, self.player:getArmor():getId())
	end

	if self.player:getOffensiveHorse() and self.player:getWeapon() then
		table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
	end

	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then return { unpreferedCards[index] } end
	end

	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

sgs.ai_skill_invoke.heg_qianhuan = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence() or self:willShowForMasochism() ) then
		return false
	end
	return true
end

local invoke_qianhuan = function(self, use)
	if (use.from and self:isFriend(use.from)) then return false end
	if use.to:isEmpty() then return false end
	if use.card:isKindOf("Peach") then return false end
	if use.card:isKindOf("Lightning") then return end
	local to = use.to:first()
	if use.card:isKindOf("Slash") and not self:slashIsEffective(use.card, to, use.from) then return end
	if use.card:isKindOf("TrickCard") and not self:hasTrickEffective(use.card, to, use.from) then return end
	if self.player:getPile("sorcery"):length() == 1 then
		if use.card:isKindOf("Slash") or use.card:isKindOf("Duel") or use.card:isKindOf("FireAttack") or use.card:isKindOf("BurningCamps")
			or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("Drowning") or use.card:isKindOf("SavageAssault") then
			return true
		end
		if use.card:isKindOf("KnownBoth") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Indulgence") or use.card:isKindOf("SupplyShortage") then
			--@todo
			return false
		end
		self.room:writeToConsole("invoke_qianhuan ? " .. use.card:getClassName())
		return false
	end
	if to and to:objectName() == self.player:objectName() then
		return not (use.from and (use.from:objectName() == to:objectName()
									or (use.card:isKindOf("Slash") and self:isPriorFriendOfSlash(self.player, use.card, use.from))))
	else
		return not (use.from and use.from:objectName() == to:objectName())
	end
end
sgs.ai_skill_use["@@heg_qianhuan"] = function(self)
	local use = self.player:getTag("qianhuan_data"):toCardUse()
	local invoke = invoke_qianhuan(self, use)
	if invoke then
		return formationProxy("heg_qianhuan", self.player:getPile("sorcery"):first()):toString()
	end
	return "."
end

sgs.ai_skill_invoke.heg_jizhao = sgs.ai_skill_invoke.heg_niepan

sgs.ai_skill_invoke.heg_zhangwu = true

sgs.weapon_range.DragonPhoenix = 2
sgs.ai_use_priority.DragonPhoenix = 2.400
function sgs.ai_weapon_value.DragonPhoenix(self, enemy, player)
	local lordliubei = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasShownSkill("heg_zhangwu") then
			lordliubei = p
			break
		end
	end
	if lordliubei and player:getWeapon() and not player:hasShownSkill("heg_xiaoji") then
		return -10
	end
	if enemy and enemy:getHp() <= 1 and (sgs.card_lack[enemy:objectName()]["Jink"] == 1 or getCardsNum("Jink", enemy, self.player) == 0) then
		return 4.1
	end
end

function sgs.ai_slash_weaponfilter.DragonPhoenix(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.DragonPhoenix, player:getAttackRange()) then return end
	return getCardsNum("Peach", to, self.player) + getCardsNum("Jink", to, self.player) < 1
		and (sgs.card_lack[to:objectName()]["Jink"] == 1 or getCardsNum("Jink", to, self.player) == 0)
end

sgs.ai_skill_invoke.heg_DragonPhoenix = function(self, data)
	if data:toString() == "revive" then return true end
	local death = data:toDeath()
	if death.who then return true
	else
		local to = data:toPlayer()
		return self:doNotDiscard(to) == self:isFriend(to)
	end
end

sgs.ai_skill_choice.heg_DragonPhoenix = function(self, choices, data)
	local kingdom = data:toString()
	choices_t = string.split(choices, "+")
	if (kingdom == "wei") then
		if (string.find(choices, "heg_guojia")) then
			return "heg_guojia"
		elseif (string.find(choices, "heg_xunyu")) then
			return "heg_xunyu"
		elseif (string.find(choices, "heg_lidian")) then
			return "heg_lidian"
		elseif (string.find(choices, "heg_zhanghe")) then
			return "heg_zhanghe"
		elseif (string.find(choices, "heg_caopi")) then
			return "heg_caopi"
		elseif (string.find(choices, "heg_zhangliao")) then
			return "heg_zhangliao"
		end

		table.removeOne(choices_t, "heg_caohong")
		table.removeOne(choices_t, "heg_zangba")
		table.removeOne(choices_t, "heg_xuchu")
		table.removeOne(choices_t, "heg_dianwei")
		table.removeOne(choices_t, "heg_caoren")

	elseif (kingdom == "shu") then
		if (string.find(choices, "heg_mifuren")) then
			return "heg_mifuren"
		elseif (string.find(choices, "heg_pangtong")) then
			return "heg_pangtong"
		elseif (string.find(choices, "heg_lord_liubei")) then
			return "heg_lord_liubei"
		elseif (string.find(choices, "heg_liushan")) then
			return "heg_liushan"
		elseif (string.find(choices, "heg_jiangwanfeiyi")) then
			return "heg_jiangwanfeiyi"
		end

		table.removeOne(choices_t, "heg_liubei")
		table.removeOne(choices_t, "heg_guanyu")
		table.removeOne(choices_t, "heg_zhangfei")
		table.removeOne(choices_t, "heg_weiyan")
		table.removeOne(choices_t, "heg_zhurong")
		table.removeOne(choices_t, "heg_madai")

	elseif (kingdom == "wu") then
		if (string.find(choices, "heg_zhoutai")) then
			return "heg_zhoutai"
		elseif (string.find(choices, "heg_lusu")) then
			return "heg_lusu"
		elseif (string.find(choices, "heg_taishici")) then
			return "heg_taishici"
		elseif (string.find(choices, "heg_sunjian")) then
			return "heg_sunjian"
		end

		table.removeOne(choices_t, "heg_sunce")
		table.removeOne(choices_t, "heg_chenwudongxi")
		table.removeOne(choices_t, "heg_luxun")
		table.removeOne(choices_t, "heg_huanggai")

	elseif (kingdom == "qun") then
		if (string.find(choices, "heg_yuji")) then
			return "heg_yuji"
		elseif (string.find(choices, "heg_caiwenji")) then
			return "heg_caiwenji"
		elseif (string.find(choices, "heg_mateng")) then
			return "heg_mateng"
		elseif (string.find(choices, "heg_kongrong")) then
			return "heg_kongrong"
		elseif (string.find(choices, "heg_lord_zhangjiao")) then
			return "heg_lord_zhangjiao"
		end

		table.removeOne(choices_t, "heg_dongzhuo")
		table.removeOne(choices_t, "heg_tianfeng")
		table.removeOne(choices_t, "heg_zhangjiao")

	end
	if #choices_t == 0 then choices_t = string.split(choices, "+") end
	return choices_t[math.random(1, #choices_t)]
end

sgs.ai_skill_discard.heg_DragonPhoenix = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = sgs.QList2Table(self.player:getCards("he"))

	if #to_discard == 1 then
		return {to_discard[1]:getEffectiveId()}
	end

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2 end

			if card:isKindOf("Weapon") then
				if self.player:getHandcardNum() < discard_num + 2 and not self:needKongcheng() then return 0
				else return 2 end
			elseif card:isKindOf("OffensiveHorse") then
				if self.player:getHandcardNum() < discard_num + 2 and not self:needKongcheng() then return 0
				else return 1 end
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then
				if self.player:hasSkill("heg_bazhen") then return 0
				else return 4 end
			else return 0 --@to-do: add the corrsponding value of Treasure
			end
		else
			if self.player:getMark("@heg_qianxi_red") > 0 and card:isRed() and not card:isKindOf("Peach") then return 0 end
			if self.player:getMark("@heg_qianxi_black") > 0 and card:isBlack() then return 0 end
			if self:isWeak() then return 5 else return 0 end
		end
	end

	local compare_func = function(card1, card2)
		local card1_aux = aux_func(card1)
		local card2_aux = aux_func(card2)
		if card1_aux ~= card2_aux then return card1_aux < card2_aux end
		return self:getKeepValue(card1) < self:getKeepValue(card2)
	end

	table.sort(to_discard, compare_func)

	for _, card in ipairs(to_discard) do
		if not self.player:isJilei(card) then return {card:getEffectiveId()} end
	end
end

sgs.ai_skill_invoke.heg_shengxi = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	if self:getOverflow() >= 0 then
		local heg_erzhang = sgs.findPlayerByShownSkillName("heg_guzheng")
		if heg_erzhang and self:isEnemy(heg_erzhang) then return false end
	end
	return true
end



-- The common V2 gate owns availability and per-instance usage checks.
sgs.ai_fill_skill.heg_shangyi = heg_shangyi_skill.getTurnUseCard
for _, name in ipairs({"heg_heyi", "heg_tianfu", "heg_niaoxiang"}) do
    local skill_name = name
    local function summon(self)
        if self:willShowForAttack() or self:willShowForDefence() then
            return formationProxy(skill_name)
        end
    end
    table.insert(sgs.ai_skills, {name = skill_name, getTurnUseCard = summon})
    sgs.ai_fill_skill[skill_name] = summon
    sgs.ai_skill_use_func[skill_name] = function(card, use) use.card = card end
end
