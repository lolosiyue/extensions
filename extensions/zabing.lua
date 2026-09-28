--[[高达杀杂兵包
   编写者：某个什么都不会的杂兵指挥官
   鸣谢：高达杀制作组QQ群里的大佬们
   高达杀制作组QQ群：565837324
   PS：准备好氪金验欧非吧
]]

--[[设定
	支援机体力 = 耐久度
	第二回合起，出牌阶段，点击“支援”按钮，召唤你喜欢的支援机，以副将的形式出击。
	出牌阶段开始时、当你造成或受到1点伤害后，支援机耐久度-1，若为0则消失，X回合后才可再次召唤支援机出击。（X为其原耐久度）
	各类支援机的使用权从“扭蛋”获得，每次抽到便令该支援机的可使用次数+1/+3。
	一场游戏中，第一次召唤支援机需消耗1次该支援机的使用次数，之后再召唤支援机时不消耗次数，但只能召唤第一次的支援机。
]]

module("extensions.zabing", package.seeall)
extension = sgs.Package("zabing")

ZAKU = sgs.General(extension, "ZAKU", "", 5, true, true)
ZAKU:setGender(sgs.General_Neuter)

dangqiang = sgs.CreateTriggerSkillV2
{
	name = "dangqiang",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local marks = player:getMarkNames()
		for _,mark in pairs(marks) do
			if mark:startsWith("@zb_") and player:getMark(mark) > 0 then
				room:setPlayerMark(player, mark, 0)
				break
			end
		end
		room:setPlayerMark(player, "@zb_full5_re0", 1)
		local maxhp = player:getMaxHp()
		room:changeHero(player, "", false, false, true, false)
		room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
		room:setEmotion(player, "skill_nullify")
		return true
	end
}

ZAKU:addSkill(dangqiang)

GM = sgs.General(extension, "GM", "", 3, true, true)
GM:setGender(sgs.General_Neuter)

liangchan = sgs.CreateTargetModSkillV2{
	name = "liangchan",
	pattern = "Slash",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_ExtraTarget then return false end
		local holder = ctx:getHolder()
		return holder ~= nil and holder:hasSkill(skill:objectName())
	end
}

GM:addSkill(liangchan)

JEGAN = sgs.General(extension, "JEGAN", "", 3, true, true)
JEGAN:setGender(sgs.General_Neuter)

gaoda_lianxievs = sgs.CreateViewAsSkillV2{
	name = "gaoda_lianxie",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("gaoda_lianxie")
	end,
	can_select_card = function(skill, request, card)
		if not card or card:hasFlag("using") then return false end
		if request:getSelectedCardIds():length() >= 1 then return false end
		return sgs.Sanguosha:matchExpPattern("TrickCard", request:getInitiator(), card)
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local original = sgs.Sanguosha:getCard(ids:first())
		if not original or not original:isKindOf("TrickCard") then return nil end
		local acard = sgs.Sanguosha:cloneCard("tactical_combo", original:getSuit(), original:getNumber())
		if not acard then return nil end
		acard:addSubcard(original)
		acard:setSkillName(skill:objectName())
		return acard
	end
}

gaoda_lianxie = sgs.CreateTriggerSkillV2
{
	name = "gaoda_lianxie",
	events = {sgs.CardUsed},
	view_as_skill = gaoda_lianxievs,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		if use.card and table.contains(use.card:getSkillNames(), "gaoda_lianxie") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerHistory(player, skill:objectName())
		return false
	end
}

JEGAN:addSkill(gaoda_lianxie)

BUCUE = sgs.General(extension, "BUCUE", "", 4, true, true)
BUCUE:setGender(sgs.General_Neuter)

dizhan = sgs.CreateTriggerSkillV2{
	name = "dizhan",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Play and player:isKongcheng() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local card = sgs.Sanguosha:cloneCard("savage_assault")
		card:setSkillName(skill:objectName())
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = player
		room:useCard(use)
		return false
	end
}

BUCUE:addSkill(dizhan)

M1_ASTRAY = sgs.General(extension, "M1_ASTRAY", "", 4, true, true)
M1_ASTRAY:setGender(sgs.General_Neuter)

zhongli = sgs.CreateTriggerSkillV2{
	name = "zhongli",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Finish
			and player:getMark("damage_point_round") == 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(1, skill:objectName())
		return false
	end
}

M1_ASTRAY:addSkill(zhongli)

FLAG = sgs.General(extension, "FLAG", "", 3, true, true)
FLAG:setGender(sgs.General_Neuter)

kongxi = sgs.CreateTriggerSkillV2{
	name = "kongxi",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		local use = ctx.original_data:toCardUse()
		local log = sgs.LogMessage()
		log.type = "#IgnoreArmor"
		log.from = player
		log.card_str = use.card:toString()
		room:sendLog(log)
		for _,p in sgs.qlist(use.to) do
			if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
				p:addQinggangTag(use.card)
			end
		end
		return false
	end
}

FLAG:addSkill(kongxi)

TIEREN = sgs.General(extension, "TIEREN", "", 4, true, true)
TIEREN:setGender(sgs.General_Neuter)

diyu = sgs.CreateTriggerSkillV2{
	name = "diyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpLost, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		player:drawCards(1, skill:objectName())
		return false
	end
}

TIEREN:addSkill(diyu)

GENOACE = sgs.General(extension, "GENOACE", "", 4, true, true)
GENOACE:setGender(sgs.General_Neuter)

huanji = sgs.CreateTriggerSkillV2{
	name = "huanji",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(skill:objectName())
			local ok = not damage.from:isProhibited(damage.from, slash)
			slash:deleteLater()
			if ok then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForCard(player, ".|red", "@@huanji", ctx.original_data,
			sgs.Card_MethodDiscard, nil, false, skill:objectName(), false) ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.from then return false end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(skill:objectName())
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = player
		use.to:append(damage.from)
		room:useCard(use)
		return false
	end
}

GENOACE:addSkill(huanji)

GAFRAN = sgs.General(extension, "GAFRAN", "", 5, true, true)
GAFRAN:setGender(sgs.General_Neuter)

fuxi = sgs.CreateViewAsSkillV2{
	name = "fuxi",
	n = 2,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, card)
		return card and request:getSelectedCardIds():length() < 2
			and not card:isEquipped()
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect = function(skill, ctx)
		local source = ctx.invoker or ctx.initiator
		if not source then return end
		local room = source:getRoom()
		local log = sgs.LogMessage()
		log.type = "#fuxi"
		log.from = source
		log.arg = skill:objectName()
		room:sendLog(log)
		local marks = source:getMarkNames()
		for _,mark in pairs(marks) do
			if mark:startsWith("@zb_") and source:getMark(mark) > 0 then
				room:setPlayerMark(source, mark, 0)
				break
			end
		end
		room:setPlayerMark(source, "@zb_full5_re0", 1)
		local maxhp = source:getMaxHp()
		room:changeHero(source, "", false, false, true, false)
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(maxhp))
	end,
	on_effect_target = function(skill, ctx, target)
		if not target then return end
		target:getRoom():addPlayerMark(target, "fuxi")
	end
}

fuxieffect = sgs.CreateTriggerSkillV2
{
	name = "#fuxieffect",
	events = {sgs.TurnStart},
	global = true,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:getMark("fuxi") > 0) then return false end
		local owner = room:findPlayerBySkillName(skill:objectName())
		if not owner then return false end
		local ids = owner:getValidSkillInstanceIds(skill:objectName())
		if ids:length() == 0 then return false end
		return skill:objectName() .. "#" .. ids:at(0), owner
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:getMark("fuxi") > 0) then return false end
		room:removePlayerMark(target, "fuxi")
		local log = sgs.LogMessage()
		log.type = "#fuxie"
		log.from = target
		log.arg = "fuxi"
		room:sendLog(log)
		room:loseHp(target, 1, true, nil, "fuxi")
		return false
	end
}

GAFRAN:addSkill(fuxi)
GAFRAN:addSkill(fuxieffect)

--请在gaoda.lua的“杂兵”处进行翻译
