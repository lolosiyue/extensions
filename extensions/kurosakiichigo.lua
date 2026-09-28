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
	end,
}

krskitgtiansuo = sgs.CreateDistanceSkillV2 {
	name = "krskitgtiansuo",
	correct_func = function(skill, ctx)
		local holder = ctx:getHolder()
		if holder and holder:hasSkill(skill:objectName()) then
			return -1
		end
		return nil
	end,
}

krskitgxuhua = sgs.CreateTriggerSkillV2 {
	name = "krskitgxuhua",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	waked_skills = "krskitgjiamian+krskitgwuyue",
	limit_scope = sgs.Skill_Limit_Game,
	max_usage_limit = 1,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if player:getPhase() ~= sgs.Player_Start or player:getMark(skill:objectName()) >= 1 then
			return false
		end
		local usable = false
		for _, iid in sgs.list(player:getSkillInstanceIds(skill:objectName())) do
			local c = sgs.SkillContext()
			c.invoker = player
			c.owner = player
			c.instanceID = iid
			if skill:isUsable(c) then
				usable = true
				break
			end
		end
		if not usable then
			return false
		end
		local can_invoke = true
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHp() < player:getHp() then
				can_invoke = false
				break
			end
		end
		-- 外部授權覺醒旗標只做非破壞性檢查；消耗留到 on_effect 的 canWake()
		if not can_invoke
			and player:getTag(skill:objectName() .. "_SKILLCANWAKE"):toStringList():isEmpty() then
			return false
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local can_invoke = true
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHp() < player:getHp() then
				can_invoke = false
				break
			end
		end
		if not (can_invoke or player:canWake(skill:objectName())) then
			return false
		end
		local usageCtx = sgs.SkillContext()
		usageCtx.invoker = player
		usageCtx.owner = player
		usageCtx.instanceID = ctx.instanceID
		skill:addUsage(usageCtx)

		room:broadcastSkillInvoke(skill:objectName())
		room:doLightbox("$krskitgxuhua", 3000)
		room:getThread():delay(4500)

		local log = sgs.LogMessage()
		log.type = "#RuoyuWake"
		log.from = player
		log.arg = player:getHp()
		log.arg2 = skill:objectName()
		room:sendLog(log)

		room:setPlayerMark(player, skill:objectName(), 1)
		if player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player, nil, player:getLostHp()))
		end
		if room:changeMaxHpForAwakenSkill(player, 0, skill:objectName()) then
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
		return false
	end,
}

krskitgjiamianVS = sgs.CreateViewAsSkillV2 {
	name = "krskitgjiamian",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Slash_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			return pattern == "slash" or pattern == "jink"
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		if not card or not request:getSelectedCardIds():isEmpty() then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		end
		if request:getPattern() == "slash" then
			return card:isKindOf("Jink")
		end
		return card:isKindOf("Slash")
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then
			return nil
		end
		local original = sgs.Sanguosha:getCard(ids:first())
		if not original then
			return nil
		end
		local card
		if original:isKindOf("Slash") then
			card = sgs.Sanguosha:cloneCard("jink", original:getSuit(), original:getNumber())
		elseif original:isKindOf("Jink") then
			card = sgs.Sanguosha:cloneCard("slash", original:getSuit(), original:getNumber())
		else
			return nil
		end
		if not card then
			return nil
		end
		card:addSubcard(original)
		card:setSkillName(skill:objectName())
		return card
	end,
}
krskitgjiamian = sgs.CreateTriggerSkillV2 {
	name = "krskitgjiamian",
	view_as_skill = krskitgjiamianVS,
	events = { sgs.CardUsed, sgs.CardResponded },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if not player:isKongcheng() then
			return false
		end
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if not (card and card:getSkillName() == skill:objectName()) then
			return false
		end
		for _, sp in sgs.qlist(room:getAlivePlayers()) do
			if not sp:isKongcheng() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local splist = sgs.SPlayerList()
		for _, sp in sgs.qlist(room:getAlivePlayers()) do
			if not sp:isKongcheng() then
				splist:append(sp)
			end
		end
		if splist:isEmpty() or not room:askForSkillInvoke(player, skill:objectName()) then
			return false
		end
		local target = room:askForPlayerChosen(player, splist, skill:objectName())
		if not target then
			return false
		end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		local cdid = room:askForCardChosen(player, target, "h", skill:objectName())
		room:obtainCard(player, cdid, false)
		return false
	end,
}

krskitgwuyue = sgs.CreateTargetModSkillV2 {
	name = "krskitgwuyue",
	pattern = "Slash",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_ExtraTarget then
			return nil
		end
		local holder = ctx:getHolder()
		if holder and holder:hasSkill(skill:objectName()) and not holder:getWeapon() then
			return 2
		end
		return nil
	end,
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
	[":krskitgzhanyue"] = '<font color="blue"><b>锁定技，</b></font>你的【杀】视为火【杀】。',
	["krskitgtiansuo"] = "天锁",
	[":krskitgtiansuo"] = '<font color="blue"><b>锁定技，</b></font>你计算的与其他角色的距离时，始终-1。',
	["krskitgxuhua"] = "虚化",
	[":krskitgxuhua"] = '<font color="purple"><b>觉醒技，</b></font>回合开始阶段开始时，若你的体力全场最小(或之一)，你须永久失去【斩月】并回愎至體力上限，获得【假面】你可以将一张[杀]当[闪]，一张[闪]当[杀]使用或打出，且若你的手牌数小于1时,在完成转化后,你可以选择获得一名角色的一张手牌。【无月】若你的装备区没有武器牌时，你使用的[杀]可以额外选择至多两个目标。',
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
