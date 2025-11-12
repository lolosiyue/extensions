module("extensions.kurosakiichigo", package.seeall)
extension = sgs.Package("lingbao")

kurosakiichigo = sgs.General(extension, "kurosakiichigo", "qun", 4)
kurosakiichigoex = sgs.General(extension, "kurosakiichigoex", "qun", 4, true, true, true)


krskitgzhanyue = sgs.CreateFilterSkill {
	name = "krskitgzhanyue",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Slash") and not to_select:isKindOf("FireSlash")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("fire_slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}


krskitgtiansuo = sgs.CreateDistanceSkill {
	name = "krskitgtiansuo",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then return -1 end
		return 0
	end
}

krskitgxuhua = sgs.CreateTriggerSkill {
	name = "krskitgxuhua",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	waked_skills = "krskitgjiamian+krskitgwuyue",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		room:broadcastSkillInvoke(self:objectName())
		room:doLightbox("$krskitgxuhua", 3000)
		room:getThread():delay(4500)

		local log = sgs.LogMessage()
		log.type = "#RuoyuWake"
		log.from = player
		log.arg = player:getHp()
		log.arg2 = self:objectName()
		room:sendLog(log)

		room:setPlayerMark(player, "krskitgxuhua", 1)
		if player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player, nil, player:getLostHp()))
		end
		if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
			if player:getGeneralName() == "kurosakiichigo" then
				room:changeHero(player, "kurosakiichigoex", true, false, false, true)
				room:handleAcquireDetachSkills(player, "-krskitgzhanyue")
				room:handleAcquireDetachSkills(player, "krskitgjiamian")
				room:handleAcquireDetachSkills(player, "krskitgwuyue")
			elseif player:getGeneral2Name() == "kurosakiichigo" then
				room:changeHero(player, "kurosakiichigoex", true, false, true, true)
				room:handleAcquireDetachSkills(player, "-krskitgzhanyue")
				room:handleAcquireDetachSkills(player, "krskitgjiamian")
				room:handleAcquireDetachSkills(player, "krskitgwuyue")
			else
				room:handleAcquireDetachSkills(player, "-krskitgzhanyue")
				room:handleAcquireDetachSkills(player, "krskitgjiamian")
				room:handleAcquireDetachSkills(player, "krskitgwuyue")
			end
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHp() < player:getHp() then return false end
		end
		return true
	end,
}


krskitgjiamianVS = sgs.CreateViewAsSkill {
	name = "krskitgjiamian",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end
}
krskitgjiamian = sgs.CreateTriggerSkill {
	name = "krskitgjiamian",
	view_as_skill = krskitgjiamianVS,
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:isKongcheng() then return false end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() ~= "krskitgjiamian" then return false end
			local splist = sgs.SPlayerList()
			for _, sp in sgs.qlist(room:getAlivePlayers()) do
				if not sp:isKongcheng() then
					splist:append(sp)
				end
			end
			if splist:isEmpty() or not room:askForSkillInvoke(player, self:objectName()) then return false end
			local target = room:askForPlayerChosen(player, splist, self:objectName())
			local cdid = room:askForCardChosen(player, target, "h", self:objectName())
			room:obtainCard(player, cdid, false)
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_card:getSkillName() ~= "krskitgjiamian" then return false end
			local splist = sgs.SPlayerList()
			for _, sp in sgs.qlist(room:getAlivePlayers()) do
				if not sp:isKongcheng() then
					splist:append(sp)
				end
			end
			if splist:isEmpty() or not room:askForSkillInvoke(player, self:objectName()) then return false end
			local target = room:askForPlayerChosen(player, splist, self:objectName())
			local cdid = room:askForCardChosen(player, target, "h", self:objectName())
			room:obtainCard(player, cdid, false)
		end
	end
}

krskitgwuyue = sgs.CreateTargetModSkill {
	name = "krskitgwuyue",
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) and from:getWeapon() == nil then
			return 2
		else
			return 0
		end
	end
}

kurosakiichigo:addSkill(krskitgzhanyue)
kurosakiichigo:addSkill(krskitgtiansuo)
kurosakiichigo:addSkill(krskitgxuhua)
kurosakiichigoex:addSkill(krskitgwuyue)
kurosakiichigoex:addSkill(krskitgtiansuo)
kurosakiichigoex:addSkill(krskitgjiamian)


sgs.LoadTranslationTable {
	["lingbao"] = "灵包",

	["#kurosakiichigo"] = "死神代理",
	["kurosakiichigo"] = "黑崎一护",
	["kurosakiichigoex"] = "黑崎一护",
	["krskitgzhanyue"] = "斩月",
	[":krskitgzhanyue"] = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】视为火【杀】。",
	["krskitgtiansuo"] = "天锁",
	[":krskitgtiansuo"] = "<font color=\"blue\"><b>锁定技，</b></font>你计算的与其他角色的距离时，始终-1。",
	["krskitgxuhua"] = "虚化",
	[":krskitgxuhua"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若你的体力全场最小(或之一)，你须永久失去【斩月】并回愎至體力上限，获得【假面】你可以将一张[杀]当[闪]，一张[闪]当[杀]使用或打出，且若你的手牌数小于1时,在完成转化后,你可以选择获得一名角色的一张手牌。【无月】若你的装备区没有武器牌时，你使用的[杀]可以额外选择至多两个目标。",
	["$krskitgxuhua"] = "忘记那恐惧，看着前面；\
前进吧，呼喊吧，斩月！",
	["krskitgjiamian"] = "假面",
	["krskitgjiamianvs"] = "假面",
	[":krskitgjiamian"] = "你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出；若你以此法使用或打出一张手牌时，若你沒有手牌，你可以获得一名角色的一张手牌。 ",

	["krskitgwuyue"] = "无月",
	[":krskitgwuyue"] = "若你的装备区没有武器牌时，你使用的【杀】可以额外选择至多两个目标。",
	["designer:kurosakiichigo"] = "洛神赋 | CodeBy:FF",
	["cv:kurosakiichigo"] = "洛神赋 | 合成",
	["illustrator:kurosakiichigo"] = "洛神赋",
}
return { extension }
