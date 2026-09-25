extension = sgs.Package("NyarzThird", sgs.Package_GeneralPack)
local packages = {}
table.insert(packages, extension)

nyarz_sunquan = sgs.General(extension, "nyarz_sunquan", "wu", 4, true, false, false)

nyarz_yuheng = sgs.CreateTriggerSkillV2 {
	name = "nyarz_yuheng",
	events = { sgs.CardUsed, sgs.CardResponded },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		if player:getMark("nyarz_yuheng-Clear") >= 2 then
			return false
		end

		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if (not card) or card:isKindOf("SkillCard") then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:getCurrent()
		local disCard = room:askForExchange(player, skill:objectName(), 3, 1, false, "@nyarz_yuheng-discard:" .. target:getGeneralName(), true)
		if (not disCard) or disCard:subcardsLength() <= 0 then
			return false
		end
		ctx.extra_data:setValue(disCard)
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		local disCard = ctx.extra_data:toCard()
		if (not disCard) or disCard:subcardsLength() <= 0 then
			return false
		end
		room:addPlayerMark(player, "nyarz_yuheng-Clear", 1)

		local skillLog = sgs.LogMessage()
		skillLog.type = "$DiscardCardWithSkill"
		skillLog.from = player
		skillLog.arg = skill:objectName()
		skillLog.card_str = disCard:toString()
		room:sendLog(skillLog)
		room:broadcastSkillInvoke(skill:objectName())

		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), skill:objectName(), "")
		local move = sgs.CardsMoveStruct(disCard:getSubcards(), nil, sgs.Player_DiscardPile, reason)
		room:moveCardsAtomic(move, true)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local disCard = ctx.extra_data:toCard()
		if not disCard then
			return false
		end
		local num = disCard:subcardsLength()
		local target = room:getCurrent()
		local choices = "draw+discard"
		local choice = room:askForChoice(player, skill:objectName(), choices, sgs.QVariant(num))
		if choice == "draw" then
			target:drawCards(num, skill:objectName())
		else
			room:askForDiscard(target, skill:objectName(), num, num, false, false)
		end
		return false
	end,
}

nyarz_tongye = sgs.CreateTriggerSkillV2 {
	name = "nyarz_tongye",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if room:getTag("FirstRound"):toBool() then
			return false
		end
		if not (player and player:isAlive()) then
			return false
		end

		local move = data:toMoveOneTime()
		if
			(move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand))
			or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand)
		then
		else
			return false
		end

		local num = player:getHandcardNum()
		local can_draw = false
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() == num then
				can_draw = true
				break
			end
		end
		if not can_draw then
			return false
		end

		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(trigger_list_skill, skill:objectName())
			table.insert(trigger_list_who, p:objectName())
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		local move = ctx.original_data:toMoveOneTime()
		if (move.reason.m_skillName == skill:objectName()) or (move.reason.m_skillName == "nyarz_yuheng") then
		else
			local invoker = ctx.invoker
			local time = os.time()
			if invoker:getTag("nyarz_tongye"):toInt() then
				if (time - invoker:getTag("nyarz_tongye"):toInt()) > 12 then
					room:broadcastSkillInvoke(skill:objectName())
				end
			else
				room:broadcastSkillInvoke(skill:objectName())
			end
			invoker:setTag("nyarz_tongye", sgs.QVariant(time))
		end
		player:drawCards(1, skill:objectName())
		return false
	end,
}

nyarz_sunquan:addSkill(nyarz_yuheng)
nyarz_sunquan:addSkill(nyarz_tongye)

nyarz_caocao = sgs.General(extension, "nyarz_caocao", "wei", 4, true, false, false)

_nyarz_jianxiong_tianxiafuwo = sgs.CreateTrickCard {
	name = "_nyarz_jianxiong_tianxiafuwo",
	class_name = "Retribution",
	subclass = sgs.LuaTrickCard_TypeNormal,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	subtype = "nyarz_caocao_card",
	damage_card = true,
	can_recast = false,
	single_target = true,
	filter = function(self, targets, to_select, source)
		if #targets > sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, source, self) then
			return false
		end
		return to_select:objectName() ~= source:objectName()
	end,
	--[[feasible = function(self,targets,player)
		if player:isCardLimited(self,sgs.Card_MethodUse) then return false end
		return #targets > 0
	end,]]
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("cardUseStruct" .. self:toString()):toCardUse()
		for i, to in sgs.list(targets) do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = true
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list, "_ALL_TARGETS") or table.contains(use.no_offset_list, to:objectName())
			effect.no_respond = table.contains(use.no_respond_list, "_ALL_TARGETS") or table.contains(use.no_respond_list, to:objectName())
			effect.nullified = table.contains(use.nullified_list, "_ALL_TARGETS") or table.contains(use.nullified_list, to:objectName())

			room:cardEffect(effect)
		end
	end,
	on_effect = function(self, effect)
		local from, to, room = effect.from, effect.to, effect.to:getRoom()
		if from:isAlive() and to:isAlive() and (not to:isAllNude()) then
			local id = room:askForCardChosen(from, to, "hej", self:objectName())
			room:obtainCard(from, id, false)
		end
		room:damage(sgs.DamageStruct(self, from, to, 1, sgs.DamageStruct_Normal))
		if from:isAlive() and to:isAlive() then
			room:askForUseSlashTo(to, from, "@_nyarz_jianxiong_tianxiafuwo:" .. from:getGeneralName())
		end

		return false
	end,
}

_nyarz_jianxiong_tianxiafuwo:clone():setParent(extension)

nyarz_jianxiong = sgs.CreateTriggerSkillV2 {
	name = "nyarz_jianxiong",
	events = { sgs.Damaged, sgs.DamageInflicted },
	frequency = sgs.Skill_Compulsory,
	--waked_skills = "_nyarz_jianxiong_tianxiafuwo",
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.Damaged then
			return
		end
		local owner = ctx.owner
		if not (owner and player and owner:objectName() == player:objectName()) then
			return
		end
		if not (player:isAlive() and player:hasSkill(skill:objectName())) then
			return
		end
		local instance_ids = player:getSkillInstanceIds(skill:objectName())
		if instance_ids:length() > 0 and ctx.instanceID ~= instance_ids:at(0) then
			return
		end

		room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
		local names = player:property("SkillDescriptionRecord_nyarz_jianxiong"):toString():split("+")
		local name = nil

		local damage = ctx.original_data:toDamage()
		if damage.card and (not damage.card:isKindOf("SkillCard")) then
			--记录伤害牌
			name = damage.card:objectName()
			if damage.card:isKindOf("Slash") then
				name = "slash"
			end
		else
			name = "_nyarz_jianxiong_tianxiafuwo"
		end
		table.insert(names, name)
		room:setPlayerProperty(player, "SkillDescriptionRecord_nyarz_jianxiong", sgs.QVariant(table.concat(names, "+")))
		room:changeTranslation(player, "nyarz_jianxiong", 1)
		player:setSkillDescriptionSwap("nyarz_jianxiong", "%arg1", table.concat(names, "+,+"))

		local log = sgs.LogMessage()
		log.type = "$nyarz_jianxiong_record"
		log.from = player
		log.arg = name
		room:sendLog(log)
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageInflicted then
			return false
		end
		if not (player and player:hasSkill(skill:objectName()) and player:isAlive()) then
			return false
		end
		local damage = data:toDamage()
		local card = damage.card
		if (not card) or card:isKindOf("SkillCard") then
			return false
		end
		local names = player:property("SkillDescriptionRecord_nyarz_jianxiong"):toString():split("+")
		local name = card:objectName()
		if card:isKindOf("Slash") then
			name = "slash"
		end
		if table.contains(names, name) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event ~= sgs.DamageInflicted then
			return false
		end
		local damage = ctx.original_data:toDamage()
		local card = damage.card
		if (not card) or card:isKindOf("SkillCard") then
			return false
		end
		local names = player:property("SkillDescriptionRecord_nyarz_jianxiong"):toString():split("+")
		local name = card:objectName()
		if card:isKindOf("Slash") then
			name = "slash"
		end
		if table.contains(names, name) then
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
			room:sendLog(CreateDamageLog(damage, damage.damage, skill:objectName(), false))
			return true
		end
		return false
	end,
}

nyarz_zhishiVS = sgs.CreateViewAsSkillV2 {
	name = "nyarz_zhishi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@nyarz_zhishi"
		end
		return false
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return nil
		end
		local pattern = player:property("nyarz_zhishi"):toString()
		if pattern == "" then
			return nil
		end
		local card = sgs.Sanguosha:cloneCard(pattern)
		if not card then
			return nil
		end
		card:setSkillName("_nyarz_zhishi_card")
		return card
	end,
}

nyarz_zhishi = sgs.CreateTriggerSkillV2 {
	name = "nyarz_zhishi",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	view_as_skill = nyarz_zhishiVS,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		if player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
		local names = player:property("SkillDescriptionRecord_nyarz_jianxiong"):toString():split("+")
		if #names == 0 then
			if player:isWounded() then
				room:recover(player, sgs.RecoverStruct(skill:objectName(), player, 1))
			end
			player:drawCards(1, skill:objectName())
		else
			local first = true
			while true do
				local choices = {}
				for _, name in ipairs(names) do
					table.insert(choices, name)
				end

				if first then
					first = false
				else
					table.insert(choices, "cancel")
				end
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), sgs.QVariant(), nil, "nyarz_zhishi_choice")
				if choice == "cancel" then
					break
				end

				local log = sgs.LogMessage()
				log.type = "$nyarz_zhishi_remove"
				log.from = player
				log.arg = choice
				room:sendLog(log)

				--删除记录
				table.removeOne(names, choice)
				room:setPlayerProperty(player, "SkillDescriptionRecord_nyarz_jianxiong", sgs.QVariant(table.concat(names, "+")))
				room:changeTranslation(player, "nyarz_jianxiong", 1)
				player:setSkillDescriptionSwap("nyarz_jianxiong", "%arg1", table.concat(names, "+,+"))

				--允许印属性杀
				if choice == "slash" then
					choice = room:askForChoice(player, "nyarz_zhishi_slash", "slash+fire_slash+thunder_slash")
				end

				room:setPlayerProperty(player, "nyarz_zhishi", sgs.QVariant(choice))
				if room:askForUseCard(player, "@@nyarz_zhishi", "@nyarz_zhishi-use:" .. choice, -1, sgs.Card_MethodUse, false) then
				else
					player:drawCards(2, skill:objectName())
				end
				names = player:property("SkillDescriptionRecord_nyarz_jianxiong"):toString():split("+")
				if #names <= 0 then
					break
				end
			end
		end
		return false
	end,
}

nyarz_caocao:addSkill(nyarz_jianxiong)
nyarz_caocao:addSkill(nyarz_zhishi)

nyarz_lvbu = sgs.General(extension, "nyarz_lvbu", "qun", 5, true, false, false)

nyarz_baguanVS = sgs.CreateViewAsSkillV2 {
	name = "nyarz_baguan",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@nyarz_baguan"
		end
		return false
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return nil
		end
		local pattern = player:property("nyarz_baguan"):toString()
		if pattern == "" then
			return nil
		end
		local card = sgs.Sanguosha:cloneCard(pattern)
		if not card then
			return nil
		end
		card:setSkillName("nyarz_baguan")
		return card
	end,
}

nyarz_baguan = sgs.CreateTriggerSkillV2 {
	name = "nyarz_baguan",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = nyarz_baguanVS,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		if use.card and (not use.card:isKindOf("SkillCard")) and use.to:contains(player) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), sgs.QVariant(), false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pattern = room:askForChoice(player, "nyarz_baguan_slash", "slash+fire_slash+thunder_slash")
		room:setPlayerProperty(player, "nyarz_baguan", sgs.QVariant(pattern))

		room:askForUseCard(player, "@@nyarz_baguan", "@nyarz_baguan-slash:" .. player:getAttackRange() .. ":" .. pattern, -1, sgs.Card_MethodUse, false)
		return false
	end,
}

nyarz_baguan_buff = sgs.CreateTargetModSkillV2 {
	name = "#nyarz_baguan_buff",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_ExtraTarget then
			return nil
		end
		local card = ctx:getCard()
		local from = ctx:getPrimary()
		if card and from and card:getSkillName() == "nyarz_baguan" then
			return from:getAttackRange()
		end
		return nil
	end,
}

nyarz_yangwu = sgs.CreateTriggerSkillV2 {
	name = "nyarz_yangwu",
	events = { sgs.TargetConfirmed },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		if (not use.card)
			or ((not use.card:isKindOf("Slash")) and (not use.card:isKindOf("Duel")))
			or (not use.from)
			or (use.from:objectName() ~= player:objectName()) then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		for _, to in sgs.qlist(use.to) do
			local temp = sgs.QVariant()
			temp:setValue(to)
			if room:askForSkillInvoke(player, skill:objectName(), temp, true) then
				ctx.targets:append(to)
			end
		end
		return not ctx.targets:isEmpty()
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, to)
		for i = 1, 2, 1 do
			local id = -1
			local name = nil

			local log = sgs.LogMessage()
			log.type = "$nyarz_yangwu_discard"
			log.from = player
			log.arg = skill:objectName()

			if not to:isNude() then
				id = room:askForCardChosen(player, to, "he", skill:objectName(), false, sgs.Card_MethodDiscard, sgs.IntList(), true)
				if id >= 0 then
					log.arg2 = to:getGeneralName()
					name = to:objectName()
				end
			end
			if id < 0 then
				id = room:getDrawPile():at(0)
				log.arg2 = "drawPileTop"
			end

			log.card_str = tostring(id)
			room:sendLog(log)

			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, name, skill:objectName(), "")
			local move = sgs.CardsMoveStruct(id, nil, sgs.Player_DiscardPile, reason)
			room:moveCardsAtomic(move, true)

			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("EquipCard") then
				room:obtainCard(player, card, true)
			end
		end
		return false
	end,
}

nyarz_yangwu_limit = sgs.CreateCardLimitSkill {
	name = "#nyarz_yangwu_limit",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player)
		if player:hasSkill("nyarz_yangwu") then
			return "Nullification|.|.|."
		end
		return ""
	end,
}

nyarz_lvbu:addSkill(nyarz_baguan)
nyarz_lvbu:addSkill(nyarz_baguan_buff)
nyarz_lvbu:addSkill(nyarz_yangwu)
nyarz_lvbu:addSkill(nyarz_yangwu_limit)
extension:insertRelatedSkills("nyarz_baguan", "#nyarz_baguan_buff")
extension:insertRelatedSkills("nyarz_yangwu", "#nyarz_yangwu_limit")

sgs.LoadTranslationTable {
	["NyarzThird"] = "群阴荟萃·第三幕",

	--孙权
	["nyarz_sunquan"] = "群阴·孙权",
	["&nyarz_sunquan"] = "孙权",
	["#nyarz_sunquan"] = "会凌绝顶",
	["designer:nyarz_sunquan"] = "Nyarz",

	["nyarz_yuheng"] = "驭衡",
	[":nyarz_yuheng"] = "每回合限两次，在你使用或打出牌后，你可以弃置一至三张手牌，然后令当前回合角色摸或弃置等量手牌。",
	["@nyarz_yuheng-discard"] = "你可以发动“驭衡”弃置弃置一至三张手牌，然后令 %src 摸或弃置等量手牌",
	["nyarz_tongye"] = "统业",
	[":nyarz_tongye"] = "锁定技，一名角色的手牌数变化后，若有其他角色手牌数与其相同，你摸一张牌。",

	["$nyarz_yuheng1"] = "腰悬三江，肩担六山，衡方圆于乱世!",
	["$nyarz_yuheng2"] = "坐断东南，挥斥字内，彼以何论英雄?",
	["$nyarz_tongye1"] = "凡日月所照，江河所至，皆为大吴疆土!",
	["$nyarz_tongye2"] = "江东之水成潮必,没江淮，摧幽冀，湮雍凉!",
	["~nyarz_sunquan"] = "家事国事天下事，事事罢了……",

	--曹操·第二版

	["nyarz_caocao"] = "群阴·曹操·第二版",
	["&nyarz_caocao"] = "曹操",
	["#nyarz_caocao"] = "雄吞天下",
	["designer:nyarz_caocao"] = "Nyarz",

	["nyarz_jianxiong"] = "奸雄",
	[":nyarz_jianxiong"] = "锁定技，当你受到游戏牌造成的伤害时，你记录此牌名，若已记录则改为防止此伤害。当你受到非游戏牌造成的伤害时，记录【天下负我】。",
	[":nyarz_jianxiong1"] = '锁定技，当你受到游戏牌造成的伤害时，你记录此牌名，若已记录则改为防止此伤害。当你受到非游戏牌造成的伤害时，记录【天下负我】。\
    <font color="red"><b>已记录：%arg1</b></font>',
	["$nyarz_jianxiong_record"] = "%from 发动“奸雄”记录了 %arg",
	["_nyarz_jianxiong_tianxiafuwo"] = "天下负我",
	[":_nyarz_jianxiong_tianxiafuwo"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名其他角色使用<br/><b>效果</b>：你获得目标区域内的一张牌并对其造成1点伤害，然后该角色可以对你使用一张【杀】。",
	["nyarz_caocao_card"] = "曹操专属",
	["@_nyarz_jianxiong_tianxiafuwo"] = "你可以对 %src 使用一张【杀】",
	["nyarz_zhishi"] = "治世",
	[":nyarz_zhishi"] = "锁定技，出牌阶段开始时或结束阶段，你移去一个“奸雄”记录的牌名并选择一项：①视为使用此牌；②摸两张牌。你可以重复此流程直至没有被记录的牌名。若没有记录的牌名，你回复一点体力并摸一张牌。",
	["nyarz_zhishi_card"] = "治世",
	["nyarz_zhishi_choice"] = "请选择一个要移除的牌名",
	["@nyarz_zhishi-use"] = "你可以视为使用【%src】或摸两张牌",
	["$nyarz_zhishi_remove"] = "%from 发动“治世”移除了“奸雄”的记录 %arg",
	["nyarz_zhishi_slash"] = "治世",

	["$nyarz_jianxiong1"] = "计定九州乱，雄吞天下兵！",
	["$nyarz_jianxiong2"] = "为谋天下一统，何惜眼前小损！",
	["$nyarz_zhishi1"] = "宦祸专权，吾当以严法儆之！",
	["$nyarz_zhishi2"] = "严行正法，奸佞不敢前。",
	["~nyarz_caocao"] = "关东有义士，兴兵讨群凶…",

	--吕布

	["nyarz_lvbu"] = "群阴·吕布",
	["&nyarz_lvbu"] = "吕布",
	["#nyarz_lvbu"] = "戟荡胡云",
	["designer:nyarz_lvbu"] = "Nyarz",

	["nyarz_baguan"] = "霸关",
	["nyarz_baguan_slash"] = "霸关",
	[":nyarz_baguan"] = "你使用目标包含自己的牌结算后，你可以视为使用一张可以额外指定X名目标的【杀】。（X为你的攻击范围）",
	["@nyarz_baguan-slash"] = "你可以视为使用一张可以额外指定 %src 名目标的【%dest】",
	["nyarz_yangwu"] = "扬武",
	[":nyarz_yangwu"] = "锁定技，你不能使用【无懈可击】。你使用【杀】或【决斗】指定目标后，可以依次弃置目标或牌堆顶共计两张牌，你获得其中的【杀】、【决斗】和装备牌。",
	["$nyarz_yangwu_discard"] = "%from 发动 %arg 弃置了 %arg2 的 %card",

	["$nyarz_baguan1"] = "赤眸披煞月，红锋冠血缨！",
	["$nyarz_baguan2"] = "虓虎啸黄沙，斩尽天下士！",
	["$nyarz_yangwu1"] = "尔等魍魉，休想逃出我的掌心哈哈哈哈！",
	["$nyarz_yangwu2"] = "沐血宴、舞画戟，匹夫安知沙场之乐！",
	["~nyarz_lvbu"] = "胡马漫九原，不见飞将在。",
}
return packages
