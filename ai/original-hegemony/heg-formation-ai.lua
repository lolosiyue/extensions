-- Source: TODO/QSanguosha-For-Hegemony-xxyheaven/lua/ai/formation-ai.lua (cf61c15).
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

local function formationProxy(name, id)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    if id then card:addSubcard(id) end
    return card
end

sgs.ai_skill_choice["heg_tuntian"] = function(self, choices)
	return "yes"
end

local getZiliangCard = function(self, target)
	if not (target:getPhase() == sgs.Player_NotActive and self:needKongcheng(target, true)) then
		local ids = sgs.QList2Table(self.player:getPile("field"))
		local cards = {}
		for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
		if target:getPhase() == sgs.Player_NotActive and self:isWeak(target) then
			for _, card in ipairs(cards) do
				if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
					return card:getEffectiveId()
				end
			end
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") then return card:getEffectiveId() end
			end
			self:sortByKeepValue(cards, true)
			return cards[1]:getEffectiveId()
		else--配合钟会找连弩？
			self:sortByUseValue(cards)
			return cards[1]:getEffectiveId()
		end
	else
		return nil
	end
end

sgs.ai_skill_use["@@heg_ziliang"] = function(self)
	local damage = self.player:getTag("ziliang_aidata"):toDamage()
	local target = damage and damage.to
	if not target then return "." end
	local id = getZiliangCard(self, target)
	if id then
		return formationProxy("heg_ziliang", id):toString()
	end
	return "."
end

local function huyuan_validate(self, equip_type, is_handcard)
	local targets = {}
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type == "po_bazhen" then
		for _, enemy in ipairs(self.enemies) do
			if self:hasKnownSkill("bazhen", enemy) and not enemy:getArmor() then table.insert(targets, enemy) end
		end
		equip_type = "Armor"
	end
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		local has_equip = false
		for _, equip in sgs.qlist(p:getEquips()) do
			if equip:isKindOf(equip_type) then
				has_equip = true
				break
			end
		end
		if not has_equip and not (equip_type == "Armor" and self:hasKnownSkill("bazhen", p) and self:isFriend(p)) then
			--[[
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if p:distanceTo(enemy) == 1 and self.player:canDiscard(enemy, "he") then
					enemy:setFlags("AI_HuyuanToChoose")
					return p
				end
			end
			]]
			return p
		end
	end
	return nil
end

sgs.ai_skill_use["@@heg_huyuan"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("SilverLion") then
		local player = huyuan_validate(self, "SilverLion", false)
		if player then return formationProxy("heg_huyuan", self.player:getArmor():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getOffensiveHorse() then
		local player = huyuan_validate(self, "OffensiveHorse", false)
		if player then return formationProxy("heg_huyuan", self.player:getOffensiveHorse():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getWeapon() then
		local player = huyuan_validate(self, "Weapon", false)
		if player then return formationProxy("heg_huyuan", self.player:getWeapon():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3 then
		local player = huyuan_validate(self, "Armor", false)
		if player then return formationProxy("heg_huyuan", self.player:getArmor():getEffectiveId()):toString() .. "->" .. player:objectName() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") then
			local player = huyuan_validate(self, "DefensiveHorse", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") then
			local player = huyuan_validate(self, "OffensiveHorse", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			local player = huyuan_validate(self, "Weapon", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") then
			local player = huyuan_validate(self, "SilverLion", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
		if card:isKindOf("Armor") and huyuan_validate(self, "Armor", true) then
			local player = huyuan_validate(self, "Armor", true)
			if player then return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. player:objectName() end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not friend:isRemoved() and friend:getHandcardNum() < 3 then
			for _, card in ipairs(cards) do
				if not self.player:isCardLimited(card, sgs.Card_MethodNone) then
					return formationProxy("heg_huyuan", card:getEffectiveId()):toString() .. "->" .. friend:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.heg_huyuan = function(self, targets)
--[[
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("AI_HuyuanToChoose") then
			p:setFlags("-AI_HuyuanToChoose")
			return p
		end
	end
]]
	return self:findPlayerToDiscard("ej", false, sgs.Card_MethodDiscard, targets)
end

sgs.ai_card_intention.HHuyuanCard = function(self, card, from, to)
	if self:hasKnownSkill("bazhen", to[1]) then
		if sgs.Sanguosha:getCard(card:getEffectiveId()):isKindOf("Armor") then
			sgs.updateIntention(from, to[1], 10)
			return
		end
	end
	sgs.updateIntention(from, to[1], -50)
end

sgs.ai_cardneed.heg_huyuan = sgs.ai_cardneed.equip

sgs.huyuan_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 4.8
}

sgs.ai_skill_invoke.heg_shoucheng = function(self, data)
	local move = data:toMoveOneTime()
	local target = move and move.from and self.room:findPlayerByObjectName(move.from:objectName())
	return target and self:isFriend(target) and not hasManjuanEffect(target)
		and not self:needKongcheng(target, true)
end

sgs.ai_skill_invoke.heg_shengxi = function(self, data)
	if not self:willShowForDefence() and (self:needKongcheng() and self.player:getHp() < 3 ) then
		return false
	end
--[[
		if self:getOverflow() >= 0 then
		local erzhang = sgs.findPlayerByShownSkillName("guzheng")
		if erzhang and self:isEnemy(erzhang) then return false end
	end
]]--现在是结束阶段发动
	return true
end

local shangyi_skill = {}

shangyi_skill.name = "heg_shangyi"

table.insert(sgs.ai_skills, shangyi_skill)

shangyi_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if not self:willShowForAttack() then return end
	local heg_shangyi_card = formationProxy("heg_shangyi")
	assert(heg_shangyi_card)
	return heg_shangyi_card
end

sgs.ai_fill_skill.heg_shangyi = shangyi_skill.getTurnUseCard

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
	return self.heg_shangyi
end

sgs.ai_choicemade_filter.skillChoice.heg_shangyi = function(self, from, promptlist)
	local choice = promptlist[#promptlist]
	if choice ~= "handcards" then
		for _, to in sgs.qlist(self.room:getOtherPlayers(from)) do
			if to:hasFlag("shangyiTarget") then
				to:setMark(("KnownBoth_%s_%s"):format(from:objectName(), to:objectName()), 1)
-- Native disclosure owns private KnownBoth knowledge; observers never mutate it.
				break
			end
		end
	end
end

sgs.ai_use_value.heg_shangyi = 4

sgs.ai_use_priority.heg_shangyi = 9

sgs.ai_card_intention.heg_shangyi = 50

sgs.ai_skill_invoke.heg_yicheng = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then
		return false
	end
	return true
end

sgs.ai_skill_discard.heg_yicheng = function(self, discard_num, min_num, optional, include_equip)
	if self.player:hasSkill("hongyan") then
		return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
	end

	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self:needToThrowArmor() then
		table.insert(unpreferedCards, self.player:getArmor():getId())
	end

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

	if self.player:getOffensiveHorse() and self.player:getWeapon() then
		table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
	end

	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then return { unpreferedCards[index] } end
	end

	return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
end

sgs.ai_skill_choice.heg_yicheng = function(self, choices, data)
	local owner = data and data:toPlayer()
	if owner and self:isFriend(owner) then return "yes" end
	return "no"
end

sgs.ai_skill_invoke.heg_qianhuan = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence() or self:willShowForMasochism() ) then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@heg_qianhuan-put"] = function(self, data, pattern, target, target2)

	local function qianhuan_CanPut(card)
		local sorcery_ids = self.player:getPile("sorcery")
		local suits = {"heart", "diamond", "spade", "club"}
		for _,id in sgs.qlist(sorcery_ids) do
			table.removeOne(suits, sgs.Sanguosha:getCard(id):getSuitString())
		end
		for _,suit in ipairs(suits) do
			if card:getSuitString() == suit then
				return true
			end
		end
		return false
	end

	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasTreasure("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then
		local WoodenOx = sgs.Sanguosha:getCard(self.player:getTreasure():getEffectiveId())
		if self:getKeepValue(WoodenOx) > sgs.ai_keep_value.Peach then
			table.removeOne(cards, WoodenOx)
		end
	end
	for _,card in ipairs(cards) do
		if qianhuan_CanPut(card) and (not isCard("Peach", card, self.player)) then
			return card:toString()
		end
	end
	return "."
end

local invoke_qianhuan = function(self, use)
	if (use.from and self:isFriend(use.from)) then return false end
	if use.to:isEmpty() then return false end
	if use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic") then return false end
	if use.card:isKindOf("Lightning") or use.card:isKindOf("HKnownBoth") then return end
	local to = use.to:first()
	if use.card:isKindOf("Slash") and not self:slashIsEffective(use.card, to, use.from) then return end
	if use.card:isKindOf("TrickCard") and not self:trickIsEffective(use.card, to, use.from) then return end
	if self.player:getPile("sorcery"):length() == 1 then
		if use.card:isKindOf("Slash") or use.card:isKindOf("Duel")  or use.card:isKindOf("HBurningCamps")
			or use.card:isKindOf("ArcheryAttack")  or use.card:isKindOf("SavageAssault")
			or (use.card:isKindOf("FireAttack") and to:getHp() == 1)
			or (use.card:isKindOf("HDrowning") and to:getEquips():length() > 1) then
			return true
		end
		if (use.card:isKindOf("Indulgence") and self:getOverflow(to) > 1)
		or (use.card:isKindOf("SupplyShortage") and to:getHandcardNum() < 2) then--乐、兵
			return true
		end
		if (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) then--拆顺暂时不处理
			return false
		end
		--self.room:writeToConsole("invoke_qianhuan ? " .. use.card:getClassName())
		return false
	end
	if to and to:objectName() == self.player:objectName() then
		return not (use.from and (use.from:objectName() == to:objectName()
									or (use.card:isKindOf("Slash") and self:isPriorFriendOfSlash(self.player, use.card, use.from))))
	else
		return not (use.from and use.from:objectName() == to:objectName())
	end
end

sgs.ai_skill_use["@@heg_qianhuan"] = function(self, prompt)
	local pile = self.player:getPile("sorcery")
	if pile:isEmpty() then return "." end
	local use = self.player:getTag("qianhuan_data"):toCardUse()
	local cancel = use.card and not use.to:isEmpty() and invoke_qianhuan(self, use)
	if not cancel then
		-- BeforeCardsMoveBatch carries a move list rather than CardUseStruct;
		-- the stable prompt carries the friendly recipient and delayed trick.
		local fields = prompt:split(":")
		local target = fields[3] and self.room:findPlayerByObjectName(fields[3])
		cancel = target and self:isFriend(target)
	end
	if cancel then
		return formationProxy("heg_qianhuan", pile:first()):toString()
	end
	return "."
end

function sgs.ai_cardneed.heg_zhendu(to, card, self)
	return to:isKongcheng() and not self:needKongcheng(to)
end

sgs.ai_skill_invoke.heg_qiluan = true

sgs.ai_skill_invoke.heg_jizhao = sgs.ai_skill_invoke.heg_niepan

sgs.ai_skill_invoke.heg_zhangwu = true

sgs.weapon_range.HDragonPhoenix = 2

sgs.ai_use_priority.HDragonPhoenix = 2.400

function sgs.ai_weapon_value.HDragonPhoenix(self, enemy, player)
	local heg_lord_liubei = sgs.findPlayerByShownSkillName("heg_zhangwu")
	if heg_lord_liubei and player:getWeapon() and not sgs.originalHegemonyHasShownSkills(player, sgs.lose_equip_skill) then
		return -10
	end
	if enemy and enemy:getHp() <= 2 and enemy:getHandcardNum() <= 2 then--效果修改
		--(sgs.card_lack[enemy:objectName()]["Jink"] == 1 or getCardsNum("Jink", enemy, self.player) == 0)
		return 4.5
	end
	if sgs.originalHegemonyHasShownSkills(player, "heg_paoxiao|heg_paoxiao_xh|heg_suzhi|heg_xiongnve|heg_kuangcai") or (player:hasShownSkill("heg_baolie") and player:getHp() < 3) then
		return 3.5
	end
	return 2.5
end

function sgs.ai_slash_weaponfilter.HDragonPhoenix(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.HDragonPhoenix, player:getAttackRange()) then return end
--[[
	return getCardsNum("Peach", to, self.player) + getCardsNum("Jink", to, self.player) < 1
		and (sgs.card_lack[to:objectName()]["Jink"] == 1 or getCardsNum("Jink", to, self.player) == 0)
]]
	return to:getHandcardNum() <= 2 or sgs.card_lack[to:objectName()]["Jink"] == 1 or getCardsNum("Jink", to, self.player) < 1
end

sgs.ai_skill_invoke.heg_DragonPhoenix = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_discard.heg_DragonPhoenix = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = sgs.QList2Table(self.player:getCards("he"))

	if #to_discard == 1 then
		return {to_discard[1]:getEffectiveId()}
	end

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			local few_hnum = self.player:getHandcardNum() < discard_num + 2 and not self:needKongcheng()
			if card:isKindOf("Weapon") then
				return few_hnum and 0 or 2
			elseif card:isKindOf("OffensiveHorse") then
				return few_hnum and 0 or 1
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then
				if self.player:getHp() == 1 and card:isKindOf("HBreastplate") then
					return 99
				end
				return self:needToThrowArmor() and -2 or 4
			elseif card:isKindOf("Treasure") then
				if card:isKindOf("WoodenOx") then
					if self.player:getPile("wooden_ox"):isEmpty() then
						return few_hnum and 0 or 2
					else
						return 6
					end
				end
				return few_hnum and 1 or 4
			else return 0
			end
		else
			if self.player:getMark("##heg_qianxi+no_suit_red") > 0 and card:isRed() and not card:isKindOf("Peach") then return 0 end
			if self.player:getMark("##heg_qianxi+no_suit_black") > 0 and card:isBlack() then return 0 end
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

	if #to_discard == 2 then
		if self.player:getHp() <= 1 and to_discard[1]:isKindOf("Jink") and not self.player:isJilei(to_discard[2])
		and (to_discard[2]:isKindOf("Peach") or to_discard[2]:isKindOf("Analeptic")) then
			return to_discard[2]:getEffectiveId()
		end
	end

	for _, card in ipairs(to_discard) do
		if not self.player:isJilei(card) then return {card:getEffectiveId()} end
	end
end

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
