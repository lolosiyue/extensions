-- Source: TODO/QSanguosha-For-Hegemony-xxyheaven/lua/ai/basara-ai.lua (cf61c15).
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

-- Rule actions use the native V2 proxy; marker histories are owned by the server.
local function hegemonyRuleCard(name)
    local card = sgs.ActiveSkillCard()
    card:setSkillName(name)
    return card
end


sgs.ai_skill_choice.heg_nullification = function(self, choice, data)
	local effect = data:toCardEffect()
	if effect.card:isKindOf("AOE") or effect.card:isKindOf("GlobalEffect") then
		if self:isFriendWith(effect.to) then return "all"
		elseif self:isFriend(effect.to) then return "single"
		elseif self:isEnemy(effect.to) then return "all"
		end
	end
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. effect.card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
	if effect.card:isKindOf("HFightTogether") then
		local ed, no = 0,0
		for _, p in sgs.qlist(targets) do
			if p:objectName() ~= targets:at(0):objectName() and p:isChained() then
				ed = ed + 1
			end
			if p:objectName() ~= targets:at(0):objectName() and not p:isChained() then
				no = no + 1
			end
		end
		if targets:at(0):isChained() then
			if no > ed then return "single" end
		else
			if ed > no then return "single" end
		end
	end
	return "all"
end

sgs.ai_skill_choice["GameRule:TriggerOrder"] = function(self, choices, data)
	local headGeneral = sgs.originalHegemonyGeneral(self.player, true)
	local deputyGeneral = sgs.originalHegemonyGeneral(self.player, false)
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")

	local firstShow = ("heg_luanji|heg_qianhuan"):split("|")
	local bothShow = ("heg_luanji+shuangxiong|heg_luanji+heg_huoshui|heg_huoji+heg_jizhi|heg_luoshen+mobilefangzhu|guanxing+heg_jizhi"):split("|")
	local followShow = ("heg_qianhuan|heg_duoshi|rende|heg_cunsi|jieyin|xiongyi|heg_shouyue|heg_hongfa"):split("|")

	local notshown, shown, allshown, f, e, eAtt = 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self:originalHegemonyOwnKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
		if (p:hasShownGeneral() and p:hasShownGeneral2()) then
			allshown = allshown + 1
		end
	end

	local showRate = math.random() + shown/20

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end

	if (firstShowReward or self:willShowForAttack()) and not self:willSkipPlayPhase() then
		for _, skill in ipairs(bothShow) do
			if self.player:hasSkills(skill) then
				if canShowHead and showRate > 0.7 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.7 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
	end

	if firstShowReward and not self:willSkipPlayPhase() then
		for _, skill in ipairs(firstShow) do
			if self.player:hasSkill(skill) and not self.player:hasShownOneGeneral() then
				if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.8 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.8 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
		if not self.player:hasShownOneGeneral() then
			if canShowHead and showRate > 0.9 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.9 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:inHeadSkills("heg_baoling") then
		if (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") ~= 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0) then
			canShowHead = false
		end
	end
	if self.player:inHeadSkills("heg_baoling") then
		if (self.player:hasSkill("heg_mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") == 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			end
		end
	end

	if self.player:hasSkill("heg_guixiu") and not self.player:hasShownSkill("heg_guixiu") then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase() ) then
			if self.player:inHeadSkills("heg_guixiu") and canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and (headGeneral and headGeneral:isMale()) then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and (headGeneral and headGeneral:isFemale()) and (deputyGeneral and deputyGeneral:isMale()) then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() and self:willShowForDefence() then
			if canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate >0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _, skill in ipairs(followShow) do
		if ((shown > 0 and e < notshown) or self.player:hasShownOneGeneral()) and self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end
	for _, skill in ipairs(followShow) do
		if not self.player:hasShownOneGeneral() then
			for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if p:hasShownSkill(skill) and p:getKingdom() == self:originalHegemonyOwnKingdom() then
					if canShowHead and canShowDeputy and showRate > 0.2 then
						local cho = { "GameRule_AskForGeneralShowHead", "GameRule_AskForGeneralShowDeputy"}
						return cho[math.random(1, #cho)]
					elseif canShowHead and showRate > 0.2 then
						return "GameRule_AskForGeneralShowHead"
					elseif canShowDeputy and showRate > 0.2 then
						return "GameRule_AskForGeneralShowDeputy"
					end
				end
			end
		end
	end

	local skillTrigger = false
	local skillnames = choices:split("+")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowHead")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowDeputy")
	table.removeOne(skillnames, "cancel")
	if #skillnames ~= 0 then
		skillTrigger = true
	end

	if skillTrigger then
		if string.find(choices, "heg_jieming") then return "heg_jieming" end
		if string.find(choices, "nosfankui") and string.find(choices, "heg_ganglie") then return "nosfankui" end
		if string.find(choices, "heg_wangxi") and string.find(choices, "heg_ganglie") then return "heg_ganglie" end
		if string.find(choices, "heg_luoshen") and string.find(choices, "guanxing") then return "guanxing" end
		if string.find(choices, "heg_wangxi") and string.find(choices, "mobilefangzhu") then return "mobilefangzhu" end

		local except = {}
		for _, skillname in ipairs(skillnames) do
			local invoke = self:askForSkillInvoke(skillname, data)
			if invoke == true then
				return skillname
			elseif invoke == false then
				table.insert(except, skillname)
			end
		end
		if string.find(choices, "cancel") and not canShowHead and not canShowDeputy and not self.player:hasShownOneGeneral() then
			return "cancel"
		end
		table.removeTable(skillnames, except)

		if #skillnames > 0 then return skillnames[math.random(1, #skillnames)] end
	end

	return "cancel"
end

sgs.ai_skill_choice["GameRule:TurnStart"] = function(self, choices, data)--旧的亮将已失效
	--[[
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")
	local choice = sgs.ai_skill_choice["GameRule:TriggerOrder"](self, choices, data)]]
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")

	local firstShow = ("heg_luanji|heg_qianhuan"):split("|")
	local bothShow = ("heg_luanji+shuangxiong|heg_luanji+heg_huoshui|heg_huoji+heg_jizhi|heg_luoshen+mobilefangzhu|guanxing+heg_jizhi"):split("|")
	local followShow = ("heg_qianhuan|heg_duoshi|rende|heg_cunsi|jieyin|xiongyi|heg_shouyue|heg_hongfa"):split("|")

	local notshown, shown, allshown, f, e, eAtt = 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self:originalHegemonyOwnKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
		if p:hasShownAllGenerals() then
			allshown = allshown + 1
		end
	end

	local showRate = math.random() + shown/20

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end

	if (firstShowReward or self:willShowForAttack()) and not self:willSkipPlayPhase() then
		for _, skill in ipairs(bothShow) do
			if self.player:hasSkills(skill) then
				if canShowHead and showRate > 0.7 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.7 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
	end

	if firstShowReward and not self:willSkipPlayPhase() then
		for _, skill in ipairs(firstShow) do
			if self.player:hasSkill(skill) and not self.player:hasShownOneGeneral() then
				if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.8 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.8 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
		if not self.player:hasShownOneGeneral() then
			if canShowHead and showRate > 0.9 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.9 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:inHeadSkills("heg_baoling") then
		if (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") ~= 0)
		or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0)
		or (self.player:hasSkill("heg_yaowu") and not self.player:hasShownGeneral2()) then
			canShowHead = nil
		end
	end
	if self.player:inHeadSkills("heg_baoling") then
		if (self.player:hasSkill("heg_mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") == 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			end
		end
	end

	if self.player:hasSkill("heg_guixiu") and not self.player:hasShownSkill("heg_guixiu") then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase() ) then
			if self.player:inHeadSkills("heg_guixiu") and canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and self.player:getGeneral():isMale() then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and self.player:getGeneral():isFemale() and self.player:getGeneral2():isMale() then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() and self:willShowForDefence() then
			if canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate >0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _, skill in ipairs(followShow) do
		if ((shown > 0 and e < notshown) or self.player:hasShownOneGeneral()) and self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end
	for _, skill in ipairs(followShow) do
		if not self.player:hasShownOneGeneral() then
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownSkill(skill) and p:getKingdom() == self:originalHegemonyOwnKingdom() then
					if canShowHead and canShowDeputy and showRate > 0.2 then
						local cho = { "GameRule_AskForGeneralShowHead", "GameRule_AskForGeneralShowDeputy"}
						return cho[math.random(1, #cho)]
					elseif canShowHead and showRate > 0.2 then
						return "GameRule_AskForGeneralShowHead"
					elseif canShowDeputy and showRate > 0.2 then
						return "GameRule_AskForGeneralShowDeputy"
					end
				end
			end
		end
	end

	--if choice == "cancel" then
		local showRate2 = math.random()

		if canShowHead and showRate2 > 0.8 then
			if sgs.originalHegemonyDuanchang(self.player) then return "GameRule_AskForGeneralShowHead" end
			for _, p in ipairs(self.enemies) do
				if sgs.originalHegemonyHasShownSkills(p, "heg_mingshi|heg_huoshui") then return "GameRule_AskForGeneralShowHead" end
			end
		elseif canShowDeputy and showRate2 > 0.8 then
			if sgs.originalHegemonyDuanchang(self.player) then return "GameRule_AskForGeneralShowDeputy" end
			for _, p in ipairs(self.enemies) do
				if sgs.originalHegemonyHasShownSkills(p, "heg_mingshi|heg_huoshui") then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
		if not self.player:hasShownOneGeneral() then
			--local gameProcess = sgs.originalHegemonyGameProcess():split(">>") self:originalHegemonyOwnKingdom() == gameProcess[1]
			if string.find(sgs.originalHegemonyGameProcess(), self:originalHegemonyOwnKingdom() .. ">>") and (self.player:getLord() or sgs.originalHegemonyShownCount(self:originalHegemonyOwnKingdom()) < self.player:aliveCount() / 2) then
				if canShowHead and showRate2 > 0.6 then return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate2 > 0.6 then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
	--end
	--return choice
	return  "cancel"
end

sgs.ai_skill_choice["armorskill"] = function(self, choice, data)
	local choices = choice:split("+")
	for _, name in ipairs(choices) do
		local skill_names = name:split(":")
		if #skill_names == 2 then
			if self:askForSkillInvoke(skill_names[2], data) then return name end
		end
	end
	return "cancel"
end

sgs.ai_skill_invoke.GameRule_AskForArraySummon = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_invoke.SiegeSummon = true

sgs.ai_skill_invoke["SiegeSummon!"] = false

sgs.ai_skill_invoke.FormationSummon = true

sgs.ai_skill_invoke["FormationSummon!"] = false

sgs.ai_skill_choice.GameRule_AskForGeneralShow = function(self, choices, data)
    local available = choices:split("+")
    local translated = choices:gsub("showhead", "head"):gsub("showdeputy", "deputy")
    local selected = sgs.ai_skill_choice.HegemonyReveal(self, translated, data)
    selected = ({head="showhead", deputy="showdeputy"})[selected]
    return selected and table.contains(available, selected) and selected or available[1]
end

sgs.ai_skill_choice["changetolord"] = function(self, choices, data)
	global_room:writeToConsole(self.player:objectName().. ":变身君主选择" .. choices)
	return "yes"
end

function sgs.viewNextPlayerDeputy()
	if sgs.GetConfig("ViewNextPlayerDeputyGeneral", true) then
		for _, player in sgs.qlist(global_room:getPlayers()) do
			local np = player:getNextAlive()
			np:setMark(("KnownBoth_%s_%s"):format(player:objectName(), np:objectName()), 1)
			local names = {}
			if player:getTag("KnownBoth_" .. np:objectName()):toString() ~= "" then
				names = player:getTag("KnownBoth_" .. np:objectName()):toString():split("+")
			else
				if np:hasShownGeneral1() then
					table.insert(names, sgs.originalHegemonyGeneral(np, true):objectName())
				else
					table.insert(names, "anjiang")
				end
				if np:hasShownGeneral2() then
					table.insert(names, sgs.originalHegemonyGeneral(np, false):objectName())
				else
					table.insert(names, "anjiang")
				end
			end
			names[2] = sgs.originalHegemonyGeneral(np, false):objectName()
-- Native disclosure owns private KnownBoth knowledge; observers never mutate it.
			global_room:writeToConsole(player:objectName().."查看下家的副将:"..table.concat(names, "+"))
		end
	end
end

local aozhan_skill = {}

aozhan_skill.name = "heg_aozhan"

table.insert(sgs.ai_skills, aozhan_skill)

aozhan_skill.getTurnUseCard = function(self)
	if self.player:getMark("GlobalBattleRoyalMode") == 0 then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local Peach
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Peach") then
			Peach = card
			break
		end
	end
	if not Peach then return nil end
	local suit = Peach:getSuitString()
	local number = Peach:getNumberString()
	local card_id = Peach:getEffectiveId()
	local card_str = ("slash:heg_aozhan[%s:%s]=%d&"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.heg_aozhan = function(card, player, card_place, class_name)
	if player:getMark("GlobalBattleRoyalMode") == 0 then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Peach") then
			if class_name == "Slash" then
				return ("slash:heg_aozhan[%s:%s]=%d&"):format(suit, number, card_id)
			elseif class_name == "Jink" then
				return ("jink:heg_aozhan[%s:%s]=%d&"):format(suit, number, card_id)
			end
		end
	end
end

sgs.aozhan_keep_value = {
	Peach = 7,
	Analeptic = 6--鏖战酒需要比闪高吗？
}

local companion_skill = {}

companion_skill.name = "heg_companion"

table.insert(sgs.ai_skills, companion_skill)

companion_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@companion") < 1 then return end
	return hegemonyRuleCard("heg_companion")
end

sgs.ai_skill_use_func.HCompanionCard= function(card, use, self)
	--global_room:writeToConsole("珠联璧合判断开始")
	local card_str = hegemonyRuleCard("heg_companion"):toString()
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak and sgs.cloneCard("peach"):isAvailable(self.player) then
		--global_room:writeToConsole("桃回复")
		use.card = sgs.Card_Parse(card_str)
		return
	end
--暂不考虑摸牌
--[[如何获取当前或上一张杀的目标？可参考野心家标记补牌
	情况1：能出杀，预测杀目标血量为1且无闪或手牌小于等于2
	情况2：敌方目标血量为1且自身或团队状态良好，有桃
]]--
end

sgs.ai_skill_choice["heg_companion"] = function(self, choices)
	return "peach"
end

function sgs.ai_cardsview.heg_companion(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@companion") > 0 and not player:hasFlag("Global_PreventPeach") then
			--global_room:writeToConsole("珠联璧合标记救人")
			return "peach:heg_companion[no_suit:0]=."
		end
	end
end

sgs.ai_card_intention.HCompanionCard = -140

sgs.ai_use_priority.HCompanionCard= 0.1

sgs.ai_skill_choice.heg_halfmaxhp = function(self, choices)
	local can_tongdu = false
	local heg_liuba = sgs.findPlayerByShownSkillName("heg_tongdu")
	if heg_liuba and self.player:isFriendWith(heg_liuba) then
		can_tongdu = true
	end
	if (self.player:getHandcardNum() - self.player:getMaxCards()) > 1 + (can_tongdu and 3 or 0) then
		return "yes"
	end
	return "no"
end

local halfmaxhp_skill = {}

halfmaxhp_skill.name = "heg_halfmaxhp"

table.insert(sgs.ai_skills, halfmaxhp_skill)

halfmaxhp_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@halfmaxhp") < 1 then return end
	return hegemonyRuleCard("heg_halfmaxhp")
end

sgs.ai_skill_use_func.HHalfMaxHpCard= function(card, use, self)
	--global_room:writeToConsole("阴阳鱼摸牌判断开始")
	if self.player:isKongcheng() and self:isWeak() and not self:needKongcheng() and self.player:getMark("@firstshow") < 1 then
		use.card = card
		return
	end
	if self.player:hasSkill("dingke") and self.player:getMark("@halfmaxhp") > 1 then--技能定科
		use.card = card
		return
	end
	--暂不考虑找进攻牌
end

sgs.ai_use_priority.HHalfMaxHpCard = 0

local firstshow_skill = {}

firstshow_skill.name = "heg_firstshow"

table.insert(sgs.ai_skills, firstshow_skill)

firstshow_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@firstshow") < 1 then return end
	return hegemonyRuleCard("heg_firstshow")
end

sgs.ai_skill_use_func.HFirstShowCard= function(card, use, self)
	sgs.ai_use_priority.HFirstShowCard = 0.1--挟天子之前
	--global_room:writeToConsole("先驱判断开始")
	local target
	local not_shown = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not p:hasShownAllGenerals() then
			table.insert(not_shown, p)
		end
	end
	if #not_shown > 0 then
		for _, p in ipairs(not_shown) do
			if not self:isFriend(p) and not self:isEnemy(p) then
				target = p
				break
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if not p:hasShownOneGeneral() and self:isEnemy(p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if self:isFriend(p) and not p:hasShownGeneral1() then
					target = p
					break
				end
			end
		end
		if not target then
			target = not_shown[1]
		end
	end

	if (self.player:getHandcardNum() < 2 and self:slashIsAvailable())
	or (math.min(self.player:getMaxCards(), 4) - self.player:getHandcardNum() > 2) then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.HFirstShowCard = 2.4--杀之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end

	local freindisweak = false
	for _, friend in ipairs(self.friends) do
		if friend:getHp() == 1 and self:isWeak(friend) then
			freindisweak = true
			break
		end
	end
	if self.player:getHandcardNum() <= 2 and self:getCardsNum("Peach") == 0 and freindisweak then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.HFirstShowCard = 0.9--桃之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_choice["heg_firstshow_see"] = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "head_general") then
		return "head_general"
	end
	return choices[#choices]
end

sgs.ai_choicemade_filter.skillChoice.firstshow_see = function(self, from, promptlist)
	local choice = promptlist[#promptlist]
	for _, to in sgs.qlist(self.room:getOtherPlayers(from)) do
		if to:hasFlag("XianquTarget") then
			to:setMark(("KnownBoth_%s_%s"):format(from:objectName(), to:objectName()), 1)
			local names = {}
			if from:getTag("KnownBoth_" .. to:objectName()):toString() ~= "" then
				names = from:getTag("KnownBoth_" .. to:objectName()):toString():split("+")
			else
				if to:hasShownGeneral1() then
					table.insert(names, sgs.originalHegemonyGeneral(to, true):objectName())
				else
					table.insert(names, "anjiang")
				end
				if to:hasShownGeneral2() then
					table.insert(names, sgs.originalHegemonyGeneral(to, false):objectName())
				else
					table.insert(names, "anjiang")
				end
			end
			if choice == "head_general" then
				names[1] = sgs.originalHegemonyGeneral(to, true):objectName()
			else
				names[2] = sgs.originalHegemonyGeneral(to, false):objectName()
			end
-- Native disclosure owns private KnownBoth knowledge; observers never mutate it.
			global_room:writeToConsole(from:objectName().."先驱查看暗将:"..table.concat(names, "+"))
			break
		end
	end
end

local careerman_skill = {}

careerman_skill.name = "heg_careerman"

table.insert(sgs.ai_skills, careerman_skill)

careerman_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@careerist") < 1 then return end
	--global_room:writeToConsole("野心家标记生成")
	return hegemonyRuleCard("heg_careerman")
end

sgs.ai_skill_use_func.HCareermanCard= function(card, use, self)
	sgs.ai_use_priority.HCareermanCard = 0.1--挟天子之前
	self.careerman_case = 2--记录选择情况
	--global_room:writeToConsole("野心家标记判断开始")
	local card_str = hegemonyRuleCard("heg_careerman"):toString()
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak and sgs.cloneCard("peach"):isAvailable(self.player) then
		--global_room:writeToConsole("野心家标记回复")
		self.careerman_case = 3
		use.card = sgs.Card_Parse(card_str)
		return
	end
	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable()
	or (math.min(self.player:getMaxCards(), 4) - self.player:getHandcardNum() > 3) then
		local should_draw = false
		local dummy_slash = { isDummy = true, to = sgs.SPlayerList() }
		local slash = sgs.cloneCard("slash")
		self:useCardSlash(slash, dummy_slash)
		if use.card and use.to then
			for _, p in sgs.qlist(use.to) do
				if p:getHp() == 1 and self:isWeak(p) and sgs.getDefenseSlash(p, self) < 2 then
					should_draw = true
					break
				end
			end
		end
		if should_draw then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				local dummy_use = { isDummy = true }
				if c:isKindOf("BasicCard") then
					self:useBasicCard(c, dummy_use)
				elseif c:isKindOf("EquipCard") then
					self:useEquipCard(c, dummy_use)
				elseif c:isKindOf("TrickCard") then
					self:useTrickCard(c, dummy_use)
				end
				if dummy_use.card then
					return--先用光牌
				end
			end
			sgs.ai_use_priority.HCareermanCard = 2.4--杀之后
			--global_room:writeToConsole("野心家标记补牌")
			self.careerman_case = 4
			use.card = card
			return
		end
	end
	--暂时不考虑摸2牌
end

sgs.ai_skill_choice["heg_careerman"] = function(self, choices)
	if self.careerman_case == 3 then
		return "peach"
	end
	if self.careerman_case == 4 then
		return "heg_firstshow"
	end
	return "draw2cards"--默认情况case2
end

sgs.ai_skill_playerchosen["heg_careerman"] = function(self, targets)
	local not_shown = sgs.QList2Table(targets)
	local target
	for _, p in ipairs(not_shown) do
		if not self:isFriend(p) and not self:isEnemy(p) then
			target = p
			break
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if not p:hasShownOneGeneral() and self:isEnemy(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if self:isFriend(p) and not p:hasShownGeneral1() then
				target = p
				break
			end
		end
	end
	if not target then
		target = not_shown[1]
	end
	return target
end

function sgs.ai_cardsview.heg_careerman(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@careerist") > 0 and not player:hasFlag("Global_PreventPeach") then
			--global_room:writeToConsole("野心家标记救人")
			return "peach:heg_careerman[no_suit:0]=."
		end
	end
end

sgs.ai_card_intention.HCareermanCard = -140

sgs.ai_skill_choice["GameRule:CareeristShow"]= function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "yes") then
		return "yes"
	end
	return "no"
end

sgs.ai_skill_choice["GameRule:CareeristSummon"]= function(self, choices)
	return "yes"
end

sgs.ai_skill_choice["GameRule:CareeristAdd"]= function(self, choices)
	return math.random(1, 3) > 1 and "no" or "yes"
end

-- Explicit reveal actions stay on the native HegemonyReveal request.

sgs.ai_skill_choice.HegemonyReveal = function(self, choices, data)
    local available, translated = choices:split("+"), {}
    if table.contains(available, "head") then translated[#translated + 1] = "GameRule_AskForGeneralShowHead" end
    if table.contains(available, "deputy") then translated[#translated + 1] = "GameRule_AskForGeneralShowDeputy" end
    if table.contains(available, "cancel") then translated[#translated + 1] = "cancel" end
    local decision = sgs.ai_skill_choice["GameRule:TurnStart"](self, table.concat(translated, "+"), data)
    local selected = ({GameRule_AskForGeneralShowHead="head", GameRule_AskForGeneralShowDeputy="deputy"})[decision] or "cancel"
    return table.contains(available, selected) and selected or available[1]
end

sgs.ai_skill_choice["GuanxingShowGeneral"] = function(self, choices, data)
	-- V2 already chose the exact source in the trigger menu. Only the optional
	-- second reveal remains; never return a legacy choice absent from the request.
	local available = choices:split("+")
	if #available == 2 and table.contains(available, "cancel") and table.contains(available, "show_both_generals") then
		return self.room:alivePlayerCount() >= 5 and "cancel" or "show_both_generals"
	end
	if self.room:alivePlayerCount() >= 5 then
		local cho = { "show_head_general", "show_deputy_general"}
		return cho[math.random(1, #cho)]
	end
	return "show_both_generals"
end

sgs.ai_fill_skill.heg_firstshow = firstshow_skill.getTurnUseCard
sgs.ai_skill_use_func.heg_firstshow = sgs.ai_skill_use_func.HFirstShowCard
sgs.ai_use_priority.heg_firstshow = sgs.ai_use_priority.HFirstShowCard
sgs.ai_use_value.heg_firstshow = sgs.ai_use_value.HFirstShowCard
sgs.ai_card_intention.heg_firstshow = sgs.ai_card_intention.HFirstShowCard

sgs.ai_fill_skill.heg_halfmaxhp = halfmaxhp_skill.getTurnUseCard
sgs.ai_skill_use_func.heg_halfmaxhp = sgs.ai_skill_use_func.HHalfMaxHpCard
sgs.ai_use_priority.heg_halfmaxhp = sgs.ai_use_priority.HHalfMaxHpCard
sgs.ai_use_value.heg_halfmaxhp = sgs.ai_use_value.HHalfMaxHpCard
sgs.ai_card_intention.heg_halfmaxhp = sgs.ai_card_intention.HHalfMaxHpCard

sgs.ai_fill_skill.heg_companion = companion_skill.getTurnUseCard
sgs.ai_skill_use_func.heg_companion = sgs.ai_skill_use_func.HCompanionCard
sgs.ai_use_priority.heg_companion = sgs.ai_use_priority.HCompanionCard
sgs.ai_use_value.heg_companion = sgs.ai_use_value.HCompanionCard
sgs.ai_card_intention.heg_companion = sgs.ai_card_intention.HCompanionCard

sgs.ai_fill_skill.heg_careerman = careerman_skill.getTurnUseCard
sgs.ai_skill_use_func.heg_careerman = sgs.ai_skill_use_func.HCareermanCard
sgs.ai_use_priority.heg_careerman = sgs.ai_use_priority.HCareermanCard
sgs.ai_use_value.heg_careerman = sgs.ai_use_value.HCareermanCard
sgs.ai_card_intention.heg_careerman = sgs.ai_card_intention.HCareermanCard
