module("extensions.Christmas", package.seeall)
extension = sgs.Package("Christmas")

sgs.LoadTranslationTable {
	["Christmas"] = "圣诞快乐",
}

RLiwaVS = sgs.CreateViewAsSkillV2 {
	name = "RLiwa",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	will_throw_selected_cards = false,
	limit_scope = sgs.Skill_Limit_Phase,
	max_usage_limit = 1,
	phase_name = "Play",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not (source and target and ctx.use_card) then return end
		local room = source:getRoom()
		if not room then return end
		target:addToPile("liwas", ctx.use_card, true)
		room:setPlayerMark(target, "RLiwa" .. source:objectName() .. ctx.use_card:getSubcards():at(0), 1)
	end,
}

RLiwa = sgs.CreateTriggerSkillV2 {
	name = "RLiwa",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardFinished },
	view_as_skill = RLiwaVS,

	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return false end
			if player:getPile("liwas"):length() == 0 then return false end
			local owner = room:findPlayerBySkillName("RLiwa")
			if not owner then return false end
			local ids = owner:getValidSkillInstanceIds("RLiwa")
			if ids:length() == 0 then return false end
			return "RLiwa#" .. ids:at(0), owner
		elseif event == sgs.CardFinished then
			if player:getPhase() ~= sgs.Player_Play then return false end
			local use = data:toCardUse()
			if not (use and use.card) then return false end
			local card_type = tostring(use.card:getTypeId())
			local RLiwa_types = player:getTag("RLiwa"):toString():split(",")
			if not table.contains(RLiwa_types, card_type) then return false end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, source in sgs.qlist(room:findPlayersBySkillName("RLiwa")) do
				if source:getMark("RLiwa" .. card_type .. "-Clear") > 0 then
					local ids = source:getValidSkillInstanceIds("RLiwa")
					if ids:length() > 0 then
						table.insert(trigger_list_skill, "RLiwa#" .. ids:at(0))
						table.insert(trigger_list_who, source:objectName())
					end
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		end
		return false
	end,

	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then return true end
		if event == sgs.CardFinished then
			return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local pile_owner = ctx.invoker
			if not pile_owner or pile_owner:getPile("liwas"):length() == 0 then return false end
			local RLiwa_types = {}
			for _, card in sgs.qlist(pile_owner:getPile("liwas")) do
				table.insert(RLiwa_types, sgs.Sanguosha:getCard(card):getTypeId())
				for _, source in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if pile_owner:getMark("RLiwa" .. source:objectName() .. card) > 0 then
						room:setPlayerMark(pile_owner, "RLiwa" .. source:objectName() .. card, 0)
						room:setPlayerMark(source, "RLiwa" .. sgs.Sanguosha:getCard(card):getTypeId() .. "-Clear", 1)
					end
				end
			end
			pile_owner:setTag("RLiwa", sgs.QVariant(table.concat(RLiwa_types, ",")))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, pile_owner:objectName())
			local move = sgs.CardsMoveStruct(pile_owner:getPile("liwas"), pile_owner, sgs.Player_PlaceHand, reason)
			room:moveCardsAtomic(move, true)
		elseif event == sgs.CardFinished then
			player:drawCards(1)
		end
		return false
	end,
}

ReindeerGirl = sgs.General(extension, "ReindeerGirl", "god", 4, false)
ReindeerGirl:addSkill(RLiwa)

sgs.LoadTranslationTable {
	["ReindeerGirl"] = "驯鹿娘",
	["&ReindeerGirl"] = "驯鹿娘",
	["#ReindeerGirl"] = "飞奔的礼物",
	["RLiwa"] = "礼袜",
	[":RLiwa"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可将一张牌置于其他角色武将牌旁，称为“袜子”。该角色准备阶段开始时获得此“袜子”。\
当一名角色其于出牌阶段使用与其此回合获得的“袜子”类别相同的牌后，你可摸一张牌。',
	["liwas"] = "袜子",
	["designer:ReindeerGirl"] = "Amira",
	["illustrator:ReindeerGirl"] = "ピスケ",
}
