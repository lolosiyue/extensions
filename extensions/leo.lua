module("extensions.leo", package.seeall)
extension = sgs.Package("leo")

--傅佥
leo_fuqian = sgs.General(extension, "leo_fuqian", "shu", "4", true)

luajuesii = sgs.CreateViewAsSkillV2 {
	name = "luajuesii",
	n = 0,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:isWounded()
	end,

	create_card = function(skill, request)
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		card:setSkillName(skill:objectName())
		return card
	end,

	cost = function(skill, room, ctx, request)
		local player = request:getInitiator()
		if not player then return false end
		local choice = room:askForChoice(player, skill:objectName(), "luajuesii1+luajuesii2")
		ctx.extra_data:setValue(choice)
		return true
	end,

	pay = function(skill, room, ctx, request)
		local player = request:getInitiator()
		if not player then return false end
		if ctx.extra_data:toString() == "luajuesii1" then
			room:loseMaxHp(player, 1)
		else
			room:loseHp(player, 1, true, player, skill:objectName())
		end
		return true
	end,
}


leo_fuqian:addSkill(luajuesii)

sgs.LoadTranslationTable {
	["leo_fuqian"] = "傅佥",
	["luajuesii"] = "决死",
	[":luajuesii"] = "出牌阶段，若你已经受伤，你可以失去1点体力或体力上限，视为对一名其他角色使用一张【决斗】。",
	["luajuesii1"] = "失去1点体力上限",
	["luajuesii2"] = "失去1点体力",

	--设计者(不写默认为官方)
	["designer:leo_fuqian"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_fuqian"] = "暂无",

	--称号
	["#leo_fuqian"] = "忠勇壮烈",

	--插画(默认为KayaK)
	["illustrator:leo_fuqian"] = "",
}





--张辽
leoshenzhangliao = sgs.General(extension, "leoshenzhangliao", "god", "4", true)

leo_global_skill_names = { "#leo_InTempMoving" }
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local leo_ensuring_globals = false
local function leo_ensure_global_instances(room)
	if leo_ensuring_globals then return end
	if room:getTag("leo_globals_ensured"):toBool() then return end
	leo_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		leo_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("leo_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(leo_global_skill_names) do
			if not skip_set[skill_name] and p:getSkillInstanceIds(skill_name):isEmpty() then
				room:attachSkillToPlayer(p, skill_name)
				if p:getSkillInstanceIds(skill_name):isEmpty() then
					skip_set[skill_name] = true
					skip_changed = true
				end
			end
		end
	end
	if skip_changed then
		local parts = {}
		for n, _ in pairs(skip_set) do table.insert(parts, n) end
		room:setTag("leo_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("leo_globals_ensured", sgs.QVariant(true))
	leo_ensuring_globals = false
end

leo_InTempMoving = sgs.CreateTriggerSkillV2 {
	name = "#leo_InTempMoving",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	global = true,
	on_record = function(skill, event, room, player, ctx)
		leo_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("leo_InTempMoving") then
				return skill:objectName(), p
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		return true
	end,
}


local s_skillList = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#leo_InTempMoving") then
	s_skillList:append(leo_InTempMoving)
end

--突袭ex视为技
luatuxiexVS = sgs.CreateViewAsSkillV2 {
	name = "luatuxiex",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@luatuxiex"
		end
		return false
	end,

	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected < 1
			and not candidate:isNude() and candidate:objectName() ~= player:objectName()
	end,

	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,

	on_effect_target = function(skill, ctx, target)
		local from = ctx.invoker or ctx.initiator
		if not from or not target then return end
		local room = from:getRoom()
		room:setPlayerFlag(target, "leo_InTempMoving")
		local x = math.max(from:getLostHp(), 1)
		local original_places = sgs.PlaceList()
		local card_ids = sgs.IntList()
		local dummy = sgs.Sanguosha:cloneCard("slash")
		for i = 1, x, 1 do
			card_ids:append(room:askForCardChosen(from, target, "h", "luatuxiex_card"))
			original_places:append(room:getCardPlace(card_ids:at(i - 1)))
			dummy:addSubcard(card_ids:at(i - 1))
			target:addToPile("#luatuxiex", card_ids:at(i - 1), false)
			if target:isKongcheng() then break end
		end
		if dummy:subcardsLength() > 0 then
			for i = 1, dummy:subcardsLength(), 1 do
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1), false)
			end
		end
		room:setPlayerFlag(target, "-leo_InTempMoving")
		from:obtainCard(dummy, false)
		dummy:deleteLater()
		room:broadcastSkillInvoke("tuxi")
	end,
}


luatuxiex = sgs.CreateTriggerSkillV2
	{ --突袭ex
		name = "luatuxiex",
		view_as_skill = luatuxiexVS,
		events = { sgs.EventPhaseStart, sgs.DrawNCards },

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Finish and room:getTag("luatuxiex"):toBool() then
					return skill:objectName()
				end
			elseif event == sgs.DrawNCards then
				if data:toDraw().reason == "draw_phase" then
					return skill:objectName()
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			if event == sgs.DrawNCards then
				return room:askForSkillInvoke(player, skill:objectName())
			end
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart then
				room:setTag("luatuxiex", sgs.QVariant(false))
				room:askForUseCard(player, "@@luatuxiex", "@luatuxiex")
			elseif event == sgs.DrawNCards then
				room:setTag("luatuxiex", sgs.QVariant(true))
				room:addPlayerMark(player, "&luatuxiex-Clear")
				local draw = ctx.original_data:toDraw()
				draw.num = draw.num - 1
				ctx.original_data:setValue(draw)
			end
			return false
		end
	}

luaqingqiVS = sgs.CreateViewAsSkillV2
	{ --轻骑视为技
		name = "luaqingqi",
		n = 0,
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

		can_activate = function(skill, request)
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				return request:getPattern() == "@@luaqingqi"
			end
			return false
		end,

		can_select_target = function(skill, request, selected, candidate)
			local player = request:getInitiator()
			if not player or not candidate or #selected >= 1 then return false end
			if not candidate:isAllNude() and candidate:objectName() ~= player:objectName() then
				return true
			end
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not card then return false end
			card:setSkillName(skill:objectName())
			card:deleteLater()
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(selected) do
				qtargets:append(p)
			end
			return card:targetFilter(qtargets, candidate, player) and
				not player:isProhibited(candidate, card, qtargets)
		end,

		targets_feasible = function(skill, request, selected)
			return #selected == 1
		end,

		on_effect_target = function(skill, ctx, target)
			local from = ctx.invoker or ctx.initiator
			if not from or not target then return end
			local room = from:getRoom()
			local choicelist = "cancel"
			if from:canSlash(target, nil, false) then
				choicelist = string.format("%s+%s", choicelist, "luaqingqi1")
			end
			if not target:isAllNude() then
				choicelist = string.format("%s+%s", choicelist, "luaqingqi2")
			end
			local dest = sgs.QVariant()
			dest:setValue(target)
			local choice = room:askForChoice(from, "luaqingqi", choicelist, dest)
			if choice == "luaqingqi1" then
				room:broadcastSkillInvoke("shensu", 2)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("luaqingqi_card")
				local use_card = sgs.CardUseStruct()
				use_card.from = from
				use_card.to:append(target)
				use_card.card = slash
				room:useCard(use_card, false)
				slash:deleteLater()
			elseif choice == "luaqingqi2" then
				local card_id = room:askForCardChosen(from, target, "hej", "luaqingqi")
				room:broadcastSkillInvoke("xianzhen", 2)
				from:obtainCard(sgs.Sanguosha:getCard(card_id))
			end
		end,
	}


luaqingqi = sgs.CreateTriggerSkillV2
	{ --轻骑
		name = "luaqingqi",
		view_as_skill = luaqingqiVS,
		events = { sgs.CardUsed, sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd },

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			if event == sgs.CardUsed then
				if data:toCardUse().card:isKindOf("BasicCard") and player:getPhase() == sgs.Player_Play then
					return skill:objectName()
				end
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Start then
					return skill:objectName()
				end
			elseif event == sgs.CardsMoveOneTime then
				if player:getPhase() == sgs.Player_Discard then
					return skill:objectName()
				end
			elseif event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Discard and room:getTag("luaqingqi"):toBool() then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.CardUsed then
				room:setTag("luaqingqi", sgs.QVariant(false))
				room:setPlayerMark(player, "&luaqingqi-Clear", 0)
			elseif event == sgs.EventPhaseStart then
				room:setTag("luaqingqi", sgs.QVariant(true))
				room:addPlayerMark(player, "&luaqingqi-Clear")
			elseif event == sgs.CardsMoveOneTime then
				local move = ctx.original_data:toMoveOneTime()
				if move.from and (move.from:objectName() == player:objectName())
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
					local n = move.card_ids:length()
					if n > 0 and room:getTag("luaqingqi"):toBool() then
						room:setTag("luaqingqi", sgs.QVariant(true))
					else
						room:setTag("luaqingqi", sgs.QVariant(false))
						room:setPlayerMark(player, "&luaqingqi-Clear", 0)
					end
				end
			elseif event == sgs.EventPhaseEnd then
				room:askForUseCard(player, "@@luaqingqi", "@luaqingqi")
			end
			return false
		end
	}

leoshenzhangliao:addSkill(luatuxiex)
leoshenzhangliao:addSkill(luaqingqi)

sgs.LoadTranslationTable {
	["leoshenzhangliao"] = "张辽",
	["luatuxiex"] = "突袭",
	["luatuxiex_card"] = "突袭",
	["luatuxiex_"] = "突袭",
	[":luatuxiex"] = "摸牌阶段，你可以少摸一张牌，则回合结束时你可以获得一名其他角色的X张手牌(X为你损失的体力值且至少为1)。",
	["@luatuxiex"] = "请指定一名其他角色发动技能【突袭】",
	["luaqingqi"] = "轻骑",
	["luaqingqi_card"] = "轻骑",
	["luaqingqi_"] = "轻骑",
	[":luaqingqi"] = "弃牌阶段，若你弃置了至少一张手牌，且你于出牌阶段没有使用过基本牌，你可以选择一项：1.视为对一名角色使用了一张【杀】，2.获得一名其他角色区域处的一张牌。",
	["@luaqingqi"] = "是否发动【轻骑】？",
	["luaqingqi1"] = "对该角色使用一张【杀】",
	["luaqingqi2"] = "获得该角色区域处的一张牌",

	--设计者(不写默认为官方)
	["designer:leoshenzhangliao"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leoshenzhangliao"] = "暂无",

	--称号
	["#leoshenzhangliao"] = "威震逍遥津",

	--插画(默认为KayaK)
	["illustrator:leoshenzhangliao"] = "暂无",
}





--吕布
splvbus = sgs.General(extension, "splvbus", "qun", "4", true)

xinwushuangTM = sgs.CreateTargetModSkillV2 {
	name = "#xinwushuangTM",
	pattern = "Duel",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_ExtraTarget then return false end
		local player = ctx:getPrimary()
		local card = ctx:getCard()
		if player and player:hasSkill("xinwushuang") and card
			and table.contains(card:getSkillNames(), "xinwushuang") then
			return card:subcardsLength() - 1
		end
		return false
	end,
}
xinwushuangVS = sgs.CreateViewAsSkillV2 { --新无双 by之语
	name = "xinwushuang",
	response_or_use = true,
	n = 998,                        --需要两张牌
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("xinwushuang-SelfPlayClear") == 0
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and not candidate:isEquipped() --非装备
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local acard = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0) --克隆一张无颜色无点数的决斗
		for i = 0, ids:length() - 1, 1 do
			acard:addSubcard(ids:at(i)) --X张牌成为子卡
		end
		acard:setSkillName("xinwushuang")
		return acard ----返回这个决斗
	end,
}

xinwushuang = sgs.CreateTriggerSkillV2
{ --争锋 触发技能 by 之语
	name = "xinwushuang",
	events = { sgs.TargetSpecified, sgs.CardEffected, sgs.CardResponded },
	view_as_skill = xinwushuangVS,
	priority = 1,
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.CardEffected then
			local effect = ctx.original_data:toCardEffect()
			if effect.card and effect.card:isKindOf("Duel") and effect.to and effect.to:isAlive() then
				local wushuang_tag = room:getTag("Wushuang_"..effect.card:toString()):toString():split("+")
				if table.contains(wushuang_tag, effect.to:objectName()) then
					room:setTag("xinwushuangData", ctx.original_data)
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Duel") and table.contains(use.card:getSkillNames(), "xinwushuang")
				and use.from and use.from:isAlive() and use.from:hasSkill(skill:objectName())
				and use.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_toCard and resp.m_toCard:isKindOf("Duel") and not player:hasFlag("xinwushuangSlash") then
				local effect = room:getTag("xinwushuangData"):toCardEffect()
				if resp.m_toCard == effect.card then
					local wushuang_tag = room:getTag("Wushuang_"..effect.card:toString()):toString():split("+")
					if table.contains(wushuang_tag, player:objectName()) then
						return skill:objectName(), effect.from
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.TargetSpecified then
			local use = ctx.original_data:toCardUse()
			room:setPlayerMark(use.from, "xinwushuang-SelfPlayClear", 1)

			local wushuang_tag = {}
			for _, p in sgs.qlist(use.to) do
				table.insert(wushuang_tag, p:objectName())
			end
			room:setTag("Wushuang_"..use.card:toString(), sgs.QVariant(table.concat(wushuang_tag, "+")))
		elseif event == sgs.CardResponded then
			local resp = ctx.original_data:toCardResponse()
			local effect = room:getTag("xinwushuangData"):toCardEffect()
			local responder = ctx.invoker
			room:setPlayerFlag(responder, "xinwushuangSlash")
			for i = 1, effect.card:getSubcards():length() - 1, 1 do
				if not room:askForCard(responder, "slash", "duel-slash:"..effect.from:objectName(),
					ctx.original_data, sgs.Card_MethodResponse, effect.from, false, "", false, effect.card) then
					resp.nullified = true
					ctx.original_data:setValue(resp)
					break
				end
			end
			room:setPlayerFlag(responder, "-xinwushuangSlash")
			room:addPlayerMark(responder, "AI_xinwushuang-Clear")
		end
		return false
	end,
}

feijiangts = sgs.CreateTriggerSkillV2 {
	name = "feijiangts",
	events = { sgs.EventPhaseStart, sgs.CardResponded, sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, cd in sgs.qlist(p:getCards("ej")) do
					if cd:isKindOf("Halberd") then
						return skill:objectName()
					end
				end
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and resp.m_card:isKindOf("Slash") and resp.m_who and (not resp.m_who:isKongcheng())
				and player:isLastHandCard(resp.m_card) then
				return skill:objectName()
			end
		else
			local use = data:toCardUse()
			if use.from and (use.from:objectName() == player:objectName()) and use.card
				and use.card:isKindOf("Slash") and player:isLastHandCard(use.card) then
				for _, p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local qinggang_sword = nil
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, cd in sgs.qlist(p:getCards("ej")) do
					if cd:isKindOf("Halberd") then
						qinggang_sword = cd
						break
					end
				end
			end
			if qinggang_sword ~= nil and player:askForSkillInvoke(skill:objectName()) then
				room:broadcastSkillInvoke("wuqian", math.random(1, 2))
				player:obtainCard(qinggang_sword)
			end
		elseif event == sgs.CardResponded then
			local resp = ctx.original_data:toCardResponse()
			local _data = sgs.QVariant()
			_data:setValue(resp.m_who)
			if player:askForSkillInvoke(skill:objectName(), _data) then
				local card_id = room:askForCardChosen(player, resp.m_who, "h", skill:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
			end
		else
			local use = ctx.original_data:toCardUse()
			for _, p in sgs.qlist(use.to) do
				if p:isKongcheng() then continue end
				local _data = sgs.QVariant()
				_data:setValue(p)
				p:setFlags("feijiangtsTarget")
				local invoke = player:askForSkillInvoke(skill:objectName(), _data)
				p:setFlags("-feijiangtsTarget")
				if invoke then
					local card_id = room:askForCardChosen(player, p, "h", skill:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
				end
			end
		end
		return false
	end
}


splvbus:addSkill(xinwushuangTM)
splvbus:addSkill(xinwushuang)
extension:insertRelatedSkills("xinwushuang", "#xinwushuangTM")
splvbus:addSkill(feijiangts)

sgs.LoadTranslationTable {
	["splvbus"] = "SP吕布",
	["xinwushuangvs"] = "争锋",
	["xinwushuang"] = "争锋",
	[":xinwushuang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意X张手牌当一张【决斗】使用，以此法使用【决斗】可以至多指定X名目标角色，且每名目标角色每次须连续打出X张【杀】。",
	["xinwushuangts"] = "争锋ts",
	["xinwushuangvs_card"] = "争锋",
	["@xinwushuang-slash"] = "%src 对你【决斗】，你须连续打出 %dest 张【杀】",

	[":xinwushuangvs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意X张手牌当一张【决斗】使用，以此法使用【决斗】可以至多指定X名目标角色，且每名目标角色每次须连续打出X张【杀】。",

	["feijiangts"] = "飞将",
	[":feijiangts"] = "若你使用或打出的【杀】是你最后一张手牌，你可以获得对方的一张牌。",


	--设计者(不写默认为官方)
	["designer:splvbus"] = "leowebber，之语，晴心~雨忆~", --lua制作：之语; 构思：leowebber

	--配音(不写默认为官方)
	["cv:splvbus"] = "暂无",

	--称号
	["#splvbus"] = "无双飞将",

	--插画(默认为KayaK)
	["illustrator:splvbus"] = "未知",
}





--王基
leo_wangji = sgs.General(extension, "leo_wangji", "wei", "4", true)

luayuanlue = sgs.CreateViewAsSkillV2
	{
		name = "luayuanlue",
		n = 0,
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("luayuanlue")
		end,

		can_select_target = function(skill, request, selected, candidate)
			if #selected > 0 or not candidate then return false end
			local handcardnum = candidate:getHandcardNum()
			local hp = candidate:getHp()
			return handcardnum > hp or handcardnum < hp
		end,

		targets_feasible = function(skill, request, selected)
			return #selected == 1
		end,

		on_effect_target = function(skill, ctx, target)
			local to = target
			local from = ctx.invoker or ctx.initiator
			if not to or not from then return end
			local room = from:getRoom()
			local handcardnum = to:getHandcardNum()
			local hp = to:getHp()
			local x = math.min(math.abs(handcardnum - hp), 4)
			if handcardnum > hp then
				room:broadcastSkillInvoke("qiaobian", 3)
				x = handcardnum - hp
				if x > 4 then x = 4 end
				room:askForDiscard(to, "luayuanlue", x, x, false, false)
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = to
				room:recover(to, recover)
			elseif handcardnum < hp then
				room:broadcastSkillInvoke("xianzhen", 1)
				x = hp - handcardnum
				if x > 4 then x = 4 end
				to:drawCards(x)
				room:loseHp(to, 1, true, from, "luayuanlue")
			end
		end
	}



leo_wangji:addSkill(luayuanlue)

sgs.LoadTranslationTable {
	["leo_wangji"] = "王基",
	["luayuanlue"] = "远略",
	[":luayuanlue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名手牌数大于体力值的角色，令其弃置X张手牌并回复1点体力，或指定一名手牌数小于体力值的角色，令其摸X张牌并失去1点体力（X为手牌数与体力值之差且至多为4）。",
	["luayuanlue_card"] = "远略",

	--设计者(不写默认为官方)
	["designer:leo_wangji"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_wangji"] = "暂无",

	--称号
	["#leo_wangji"] = "文武兼备",

	--插画(默认为KayaK)
	["illustrator:leo_wangji"] = "三国群英传",
}




--姜维
spjw = sgs.General(extension, "spjw", "shu", "4", true)


luajiezhiVS = sgs.CreateViewAsSkillV2 {
	name = "luajiezhi",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:hasFlag("luajiezhix")
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		return request:getSelectedCardIds():length() == 1 and player
			and sgs.Sanguosha:getCard(player:getMark("luajiezhiskill"))
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local ids = request:getSelectedCardIds()
		if ids:length() == 0 or not player then return nil end
		local card_id = player:getMark("luajiezhiskill")
		local card = sgs.Sanguosha:getCard(card_id)
		if not card then return nil end
		local acard = sgs.Sanguosha:getCard(ids:at(0))
		local new_card = sgs.Sanguosha:cloneCard(card:objectName(), acard:getSuit(), acard:getNumber())
		new_card:addSubcard(ids:at(0))
		new_card:setSkillName(skill:objectName())
		return new_card
	end,
}


luajiezhi = sgs.CreateTriggerSkillV2 {
	name = "luajiezhi",
	events = { sgs.CardUsed },
	view_as_skill = luajiezhiVS,
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Play or player:hasFlag("luajiezhiused") then
			return false
		end
		local card = data:toCardUse().card
		if not card or card:isKindOf("Nullification") then return false end
		if (card:isNDTrick() or card:isKindOf("BasicCard"))
			and card:getHandlingMethod() == sgs.Card_MethodUse then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local card = ctx.original_data:toCardUse().card
		if not card:isVirtualCard() then
			room:setPlayerFlag(player, "luajiezhix")
			local card_id = card:getEffectiveId()

			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "luajiezhiMark") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
			room:setPlayerMark(player, "&luajiezhiMark+" .. card:objectName() .. "+-Clear", 1)



			room:setPlayerMark(player, "luajiezhiskill", card_id)
		end
		if table.contains(card:getSkillNames(), "luajiezhi") then
			room:setPlayerFlag(player, "luajiezhiused")
			room:setPlayerFlag(player, "-luajiezhix")
			local use = ctx.original_data:toCardUse()
			use.m_addHistory = false
			ctx.original_data:setValue(use)
		end
		return false
	end
}
luajiezhiTargetMod = sgs.CreateTargetModSkillV2 {
	name = "#luajiezhi",
	pattern = "Slash",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_Residue then return false end
		local player = ctx:getPrimary()
		local card = ctx:getCard()
		if player and player:hasSkill("luajiezhi") and card
			and table.contains(card:getSkillNames(), "luajiezhi") then
			return sgs.CorrectSkillResult.unlimitedResidue()
		end
		return false
	end,
}




spjw:addSkill(luajiezhi)
spjw:addSkill(luajiezhiTargetMod)
extension:insertRelatedSkills("luajiezhi", "#luajiezhi")
spjw:addSkill("zhiji")
spjw:addRelateSkill("guanxing")

sgs.LoadTranslationTable {
	["spjw"] = "姜维",
	["luajiezhi"] = "竭智",
	[":luajiezhi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可将一张手牌当上一张你使用的基本牌或非延时锦囊使用，以此法使用的【杀】不受出牌阶段限制。",
	["luajiezhiMark"] = "竭智",
	["@jiezhiused"] = "竭智",
	["luazhiji1"] = "摸两张牌",
	["luazhiji2"] = "回复1点体力",

	--设计者(不写默认为官方)
	["designer:spjw"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spjw"] = "暂无",

	--称号
	["#spjw"] = "天水异才",

	--插画(默认为KayaK)
	["illustrator:spjw"] = "真三国无双",
}





--马超
leo_spmachao = sgs.General(extension, "leo_spmachao", "qun", "4", true)



luafeiqi = sgs.CreateTriggerSkillV2
	{
		name = "luafeiqi",
		events = { sgs.TargetSpecified, sgs.CardResponded, sgs.CardUsed },
		frequency = sgs.Skill_Frequent,

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			if event == sgs.TargetSpecified then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash")
					and use.from and use.from:objectName() == player:objectName() then
					for _, p in sgs.qlist(use.to) do
						if player:canDiscard(p, "h") then
							return skill:objectName()
						end
					end
				end
			elseif event == sgs.CardResponded then
				local card = data:toCardResponse().m_card
				if card and card:isKindOf("Jink") then
					return skill:objectName()
				end
			elseif event == sgs.CardUsed then
				local card = data:toCardUse().card
				if card and card:isKindOf("Jink") then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.TargetSpecified then
				local use = ctx.original_data:toCardUse()
				for _, p in sgs.qlist(use.to) do
					if player:canDiscard(p, "h") then
						local tohelp = sgs.QVariant()
						tohelp:setValue(p)
						if room:askForSkillInvoke(player, "luafeiqi", tohelp) then
							local card_id = room:askForCardChosen(player, p, "h", "luafeiqi")
							room:throwCard(card_id, p)
							room:broadcastSkillInvoke("longdan", 2)
						end
					end
				end
			elseif event == sgs.CardResponded or event == sgs.CardUsed then
				if room:askForSkillInvoke(player, "luafeiqi") then
					player:drawCards(1)
					room:broadcastSkillInvoke("longdan", 1)
				end
			end
			return false
		end
	}

luazhuixi_viewas = sgs.CreateViewAsSkillV2
	{
		name = "luazhuixi",
		n = 1,
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

		can_activate = function(skill, request)
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				return request:getPattern() == "@@luazhuixi"
			end
			return false
		end,

		can_select_card = function(skill, request, candidate)
			return candidate ~= nil
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() == 1
		end,

		can_select_target = function(skill, request, selected, candidate)
			local player = request:getInitiator()
			return player and candidate and #selected < 1
				and candidate:objectName() ~= player:objectName()
		end,

		targets_feasible = function(skill, request, selected)
			return #selected == 1
		end,

		on_effect_target = function(skill, ctx, target)
			local from = ctx.invoker or ctx.initiator
			if not from or not target then return end
			local room = from:getRoom()
			room:setFixedDistance(from, target, 1)
			local data = sgs.QVariant()
			data:setValue(target)
			from:setTag("luazhuixiTarget", data)
			room:addPlayerMark(target, "&luazhuixi+to+#" .. from:objectName() .. "-Clear")
		end
	}


luazhuixi = sgs.CreateTriggerSkillV2 {
	name = "luazhuixi",
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	view_as_skill = luazhuixi_viewas,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive and player:getTag("luazhuixiTarget"):toPlayer() then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local target = player:getTag("luazhuixiTarget"):toPlayer()
			if target then
				room:removeFixedDistance(player, target, 1)
			end
		elseif event == sgs.EventPhaseStart then
			room:askForUseCard(player, "@@luazhuixi", "@luazhuixi_card")
		end
		return false
	end,
}


leo_spmachao:addSkill(luafeiqi)
leo_spmachao:addSkill(luazhuixi)

sgs.LoadTranslationTable {
	["leo_spmachao"] = "SP马超",
	["luafeiqi"] = "飞骑",
	[":luafeiqi"] = "每当你指定【杀】的目标后，你可以弃置目标角色的一张手牌；每当你使用或打出一张【闪】时，你可以摸一张牌。",
	["@luazhuixi_card"] = "请指定一名角色发动【追袭】",
	["luazhuixi"] = "追袭",
	[":luazhuixi"] = "出牌阶段开始时，你可以弃置一张牌并指定一名其他角色，你与该角色的距离视为1，直至回合结束。",
	["luazhuixi_"] = "追袭",


	--设计者(不写默认为官方)
	["designer:leo_spmachao"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_spmachao"] = "暂无",

	--称号
	["#leo_spmachao"] = "一骑当千",

	--插画(默认为KayaK)
	["illustrator:leo_spmachao"] = "暂无",
}





--魏延
spwy = sgs.General(extension, "spwy", "shu", "4", true)

luayongluevs = sgs.CreateViewAsSkillV2 {
	name = "luayonglue",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@luayonglue"
		end
		return false
	end,
	can_select_target = function(skill, request, selected, candidate)
		if #selected > 0 or not candidate then return false end
		return not candidate:isKongcheng() or candidate:hasEquip()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then return end
		local room = source:getRoom()
		local card_id = room:askForCardChosen(source, target, "he", "luayonglue")
		local card = sgs.Sanguosha:getCard(card_id)
		room:throwCard(card, target)
		room:broadcastSkillInvoke("toudu", 1)
		room:setFixedDistance(source, target, 1)
		room:addPlayerMark(target, "&luayonglue+to+#" .. source:objectName() .. "+-Clear")
	end,
}

luayonglue = sgs.CreateTriggerSkillV2 {
	name = "luayonglue",
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	view_as_skill = luayongluevs,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local other = room:getOtherPlayers(player)
			for _, aplayer in sgs.qlist(other) do
				if player:canDiscard(aplayer, "he") then
					return skill:objectName()
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			if room:askForUseCard(player, "@@luayonglue", "@luayongluecard") then
				local draw = ctx.original_data:toDraw()
				draw.num = draw.num - 1
				ctx.original_data:setValue(draw)
			end
		elseif event == sgs.EventPhaseStart then
			local players = room:getAllPlayers()
			for _, p in sgs.qlist(players) do
				room:removeFixedDistance(player, p, 1)
			end
		end
		return false
	end,
}



luaqingzhanRecord = sgs.CreateTriggerSkillV2 {
	name = "#luaqingzhanRecord",
	events = { sgs.PreCardUsed, sgs.CardResponded },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local card = nil
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill(skill:objectName()) then
					return skill:objectName(), p
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		local card = nil
		if event == sgs.PreCardUsed then
			card = ctx.original_data:toCardUse().card
		else
			local response = ctx.original_data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse then
			if card:isKindOf("Slash") then
				local ids = sgs.IntList()
				if not card:isVirtualCard() then
					ids:append(card:getEffectiveId())
				else
					if card:subcardsLength() > 0 then
						ids = card:getSubcards()
						end
				end
				if not ids:isEmpty() then
					room:setCardFlag(card, "luaqingzhan")
					local pdata, cdata = sgs.QVariant(), sgs.QVariant()
					pdata:setValue(ctx.invoker)
					cdata:setValue(card)
					room:setTag("luaqingzhan_user", pdata)
					room:setTag("luaqingzhan_card", cdata)
				end
			end
		end
	end
}
luaqingzhan = sgs.CreateTriggerSkillV2 {
	name = "luaqingzhan",
	events = { sgs.BeforeCardsMove },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local move = data:toMoveOneTime()
		if move.card_ids:isEmpty() then return false end
		if not (move.from and move.from:isAlive()) then return false end
		local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile
			and basic == sgs.CardMoveReason_S_REASON_USE
			and room:getTag("luaqingzhan_card"):toCard() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local yongjue_user = room:getTag("luaqingzhan_user"):toPlayer()
		local yongjue_card = room:getTag("luaqingzhan_card"):toCard()
		room:removeTag("luaqingzhan_card")
		room:removeTag("luaqingzhan_user")
		if not (yongjue_card and yongjue_user and yongjue_card:hasFlag("luaqingzhan")
			and move.from:objectName() == yongjue_user:objectName()
			and not yongjue_user:hasSkill(skill:objectName())) then
			return false
		end
		local ids = sgs.IntList()
		if not yongjue_card:isVirtualCard() then
			ids:append(yongjue_card:getEffectiveId())
		else
			if yongjue_card:subcardsLength() > 0 then
				ids = yongjue_card:getSubcards()
			end
		end
		if ids:isEmpty() then return false end
		for _, id in sgs.qlist(ids) do
			if not move.card_ids:contains(id) then return false end
		end
		if room:askForDiscard(player, "luaqingzhan", 1, 1, true, true) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(ids) do
				slash:addSubcard(id)
			end
			player:obtainCard(slash)
			slash:deleteLater()
			move.card_ids = sgs.IntList()
			ctx.original_data:setValue(move)
		end
		return false
	end
}

spwy:addSkill(luayonglue)
spwy:addSkill(luaqingzhan)
spwy:addSkill(luaqingzhanRecord)
extension:insertRelatedSkills("luaqingzhan", "#luaqingzhanRecord")






sgs.LoadTranslationTable {
	["spwy"] = "魏延",
	["luayonglue"] = "勇略",
	[":luayonglue"] = "摸牌阶段，你可以摸少一张牌，并弃置一名其他角色的一张牌，则你与该角色的距离视为1，直至回合结束。",
	["@luayongluecard"] = "请指定一名角色发动技能【勇略】",
	["luaqingzhan"] = "请战",
	[":luaqingzhan"] = "其他角色使用的【杀】进入弃牌堆时，你可以用一张牌替换之。",


	--设计者(不写默认为官方)
	["designer:spwy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spwy"] = "暂无",

	--称号
	["#spwy"] = "奇袭关中",

	--插画
	["illustrator:spwy"] = "三国志大战",

}








--神典韦
sdw = sgs.General(extension, "sdw", "god", "5", true)



--忠魂触发技
luazhonghun = sgs.CreateTriggerSkillV2
	{
		name = "luazhonghun",
		events = { sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.DamageInflicted },
		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			if event == sgs.EventPhaseStart then
				if player:hasSkill("luazhonghun") and player:getPhase() == sgs.Player_RoundStart then
					return skill:objectName()
				end
			elseif event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive and player:hasSkill("luazhonghun") then
					return skill:objectName()
				end
			elseif event == sgs.DamageInflicted then
				if not player:hasSkill("luazhonghun") then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasSkill("luazhonghun")
							and player:getMark("&luazhonghun+to+#" .. p:objectName()) > 0 then
							return skill:objectName(), p
						end
					end
				end
			end
			return false
		end,
		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart then
				local players = room:getAllPlayers()
				for _, p in sgs.qlist(players) do
					if (p:getMark("&luazhonghun+to+#" .. player:objectName())) then
						room:setPlayerMark(p, "&luazhonghun+to+#" .. player:objectName(), 0)
					end
				end
			elseif event == sgs.EventPhaseChanging then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(),
					"luazhonghun-invoke", true, true)
				if not target then return false end
				--target:gainMark("@zhonghuned")
				room:addPlayerMark(target, "&luazhonghun+to+#" .. player:objectName())
			elseif event == sgs.DamageInflicted then
				local damage = ctx.original_data:toDamage()
				room:broadcastSkillInvoke("ganglie")
				local newdamage = damage
				newdamage.to = ctx.owner
				newdamage.transfer = true
				room:damage(newdamage)
				return true
			end
			return false
		end
	}

--死战距离技
luasizhanjl = sgs.CreateAttackRangeSkillV2 {
	name = "luasizhanjl",
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:hasSkill("luasizhanjl") then
			return player:getMark("&luasizhanjl")
		end
		return false
	end,
}
luasizhanjl_t = sgs.CreateTriggerSkillV2
	{
		name = "#luasizhanjl_t",
		events = { sgs.Damaged },

		can_trigger = function(skill, event, room, player, data)
			if player and event == sgs.Damaged then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			room:addPlayerMark(player, "&luasizhanjl", damage.damage)
			return false
		end
	}


--猛袭触发技
luamengxi = sgs.CreateTriggerSkillV2
	{
		name = "luamengxi",
		events = { sgs.Predamage },

		can_trigger = function(skill, event, room, player, data)
			if not player or player:getMark("&luasizhanjl") <= 0 then return false end
			local damage = data:toDamage()
			local reason = damage.card
			if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return room:askForSkillInvoke(player, "luamengxi", ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			room:broadcastSkillInvoke("qiangxi")
			--player:loseMark("@struggle")
			room:removePlayerMark(player, "&luasizhanjl")
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
			local log = sgs.LogMessage()
			log.type = "#skill_add_damage"
			log.from = damage.from
			log.to:append(damage.to)
			log.arg  = skill:objectName()
			log.arg2 = damage.damage
			player:getRoom():sendLog(log)
			return false
		end
	}

--决死
luajuesi = sgs.CreateFilterSkill {
	name = "luajuesi",
	view_filter = function(self, to_select)
		return (to_select:isBlack() and to_select:isNDTrick()) or (to_select:isKindOf("EquipCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local filtered = nil
		if (card:isBlack() and card:isNDTrick()) then
			local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
			filtered = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
			filtered:takeOver(duel)
		elseif (card:isKindOf("EquipCard")) then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:setSkillName(self:objectName())
			filtered = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
			filtered:takeOver(slash)
		end
		return filtered
	end
}


sdw:addSkill(luazhonghun)
sdw:addSkill(luasizhanjl)
sdw:addSkill(luasizhanjl_t)
extension:insertRelatedSkills("luasizhanjl", "#luasizhanjl_t")
sdw:addSkill(luamengxi)
sdw:addSkill(luajuesi)

sgs.LoadTranslationTable {
	["sdw"] = "典韦",
	["luazhonghun"] = "忠魂",
	["@luazhonghun"] = "忠魂",
	[":luazhonghun"] = "回合结束时，你可以指定一名其他角色，该角色受到伤害时均由你承受此伤害，直至下回合开始。",
	["@luazhonghun_card"] = "请指定一名角色发动技能忠魂",
	["luazhonghun-invoke"] = "你可以发动“忠魂”<b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["luasizhanjl"] = "死战",
	[":luasizhanjl"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到1点伤害后，你获得1枚死战标记，每有1枚死战标记，你的攻击范围+1。",
	["luamengxi"] = "猛袭",
	[":luamengxi"] = "你使用【杀】或【决斗】造成伤害时，你可以弃置1枚死战标记令此伤害+1。",
	["luajuesi"] = "决死",
	[":luajuesi"] = "<font color=\"blue\"><b>锁定技，</b></font>你的黑色非延时锦囊均视为【决斗】，你的装备牌均视为【杀】。",

	--设计者(不写默认为官方)
	["designer:sdw"] = "leowebber",

	--配音(不写默认为官方)
	["cv:sdw"] = "暂无",

	--称号
	["#sdw"] = "宛城的死士",

	--插画(默认为KayaK)
	["illustrator:sdw"] = "火凤燎原",
}





--诸葛亮
spwolong = sgs.General(extension, "spwolong", "shu", "3", true)

--帷幄
luaweiwo = sgs.CreateTriggerSkillV2
	{
		name = "luaweiwo",
		events = { sgs.EventPhaseChanging },
		frequency = sgs.Skill_Frequent,

		can_trigger = function(skill, event, room, player, data)
			if player and data:toPhaseChange().to == sgs.Player_NotActive then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName())
		end,

		on_effect = function(skill, event, room, player, ctx)
			player:drawCards(3)
			--将x张手牌依次置于牌堆顶
			local x = player:getHp()
			if (x > 3) then x = 3 end
			local card_ids = sgs.IntList()
			for _, cd in sgs.qlist(player:getHandcards()) do
				local id = cd:getEffectiveId()
				card_ids:append(id)
			end
			for var = 1, x, 1 do
				room:fillAG(card_ids, player)
				local cdid = room:askForAG(player, card_ids, false, skill:objectName())
				room:setPlayerFlag(player, "Global_GongxinOperator")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid), player, nil, sgs.Player_DrawPile,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "luaweiwo", ""),
					true)
				card_ids:removeOne(cdid)
				room:setPlayerFlag(player, "-Global_GongxinOperator")
				room:clearAG(player)
			end
			return false
		end
	}

--决胜
luajuesheng = sgs.CreateTriggerSkillV2
	{
		name = "luajuesheng",
		events = { sgs.Predamage },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			local damage = data:toDamage()
			local reason = damage.card
			if not reason or not reason:isKindOf("Slash") then return false end
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
			if #names == 0 then return false end
			return table.concat(names, "|"), table.concat(owners, "|")
		end,

		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			local owner = ctx.owner
			local tohelp = sgs.QVariant()
			tohelp:setValue(damage.from)
			room:setPlayerFlag(owner, "luajueshengTarget")
			if room:askForSkillInvoke(owner, "luajuesheng", tohelp) then
				room:broadcastSkillInvoke("mingce", math.random(1, 2))
				damage.from:drawCards(1, skill:objectName())
			end
			room:setPlayerFlag(owner, "-luajueshengTarget")
			return false
		end
	}

spwolong:addSkill(luaweiwo)
spwolong:addSkill(luajuesheng)

sgs.LoadTranslationTable {
	["spwolong"] = "SP诸葛亮",
	["luaweiwo"] = "帷幄",
	[":luaweiwo"] = "回合结束时，你可以摸3张牌，并将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",
	["luajuesheng"] = "决胜",
	[":luajuesheng"] = "一名角色使用【杀】造成伤害时，你可以令该角色摸一张牌。",


	--设计者(不写默认为官方)
	["designer:spwolong"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spwolong"] = "暂无",

	--称号
	["#spwolong"] = "卧龙",

	--插画(默认为KayaK)
	["illustrator:spwolong"] = "北",
}





--刘备
lgz = sgs.General(extension, "lgz", "shu", "3", true)

luajieyi = sgs.CreateViewAsSkillV2 {
	name = "luajieyi",
	n = 1,
	will_throw_selected_cards = false,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_WholeTargetGroup,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("luajieyi")
	end,

	can_select_card = function(skill, request, candidate)
		return candidate and request:getSelectedCardIds():isEmpty() and not candidate:isEquipped()
	end,

	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,

	can_select_target = function(skill, request, selected, candidate)
		return candidate and #selected < 2
	end,

	targets_feasible = function(skill, request, selected)
		return #selected >= 1 and #selected <= 2
	end,

	on_effect_target_group = function(skill, ctx, targets)
		local source = ctx.invoker or ctx.initiator
		if not source or not ctx.use_card or #targets == 0 then return end
		local room = source:getRoom()
		local scard = sgs.Sanguosha:getCard(ctx.use_card:getSubcards():first())
		if not scard then return end
		local jieyiflag = false
		--让指定角色选择一张手牌
		local cardid1 = room:askForCardChosen(targets[1], targets[1], "h", "luajieyivs")
		local card1 = sgs.Sanguosha:getCard(cardid1)
		local cardid2
		local card2
		if #targets == 1 then
			if (scard:isRed() and card1:isRed())
				or (scard:isBlack() and card1:isBlack()) then
				jieyiflag = true
			end
		elseif #targets > 1 then
			cardid2 = room:askForCardChosen(targets[2], targets[2], "h", "luajieyivs")
			card2 = sgs.Sanguosha:getCard(cardid2)
			if (scard:isRed() and card1:isRed() and card2:isRed())
				or (scard:isBlack() and card1:isBlack() and card2:isBlack()) then
				jieyiflag = true
			end
		end
		--依次展示手牌
		room:showCard(source, scard:getEffectiveId())
		room:showCard(targets[1], card1:getEffectiveId())
		if #targets > 1 then
			room:showCard(targets[2], card2:getEffectiveId())
		end
		--如果颜色相同
		if jieyiflag then
			local choice = room:askForChoice(source, "luajieyi", "luajieyi1+luajieyi2")
			if (choice == "luajieyi1") then --各摸一张牌
				source:drawCards(1)
				targets[1]:drawCards(1)
				if #targets > 1 then targets[2]:drawCards(1) end
			else --弃牌回复体力
				local recover = sgs.RecoverStruct()
				recover.recover = 1

				room:throwCard(scard, source)
				recover.who = source
				room:recover(source, recover)

				room:throwCard(card1, targets[1])
				recover.who = targets[1]
				room:recover(targets[1], recover)

				if #targets > 1 then
					room:throwCard(card2, targets[2])
					recover.who = targets[2]
					room:recover(targets[2], recover)
				end
			end
		end
	end,
}

luafuweivs = sgs.CreateViewAsSkillV2 {
	name = "luafuwei",
	n = 1,
	will_throw_selected_cards = false,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@luafuwei"
		end
		return false
	end,

	can_select_card = function(skill, request, candidate)
		return candidate and request:getSelectedCardIds():isEmpty() and not candidate:isEquipped()
	end,

	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,

	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		if #selected > 0 or not player or not candidate then return false end
		if candidate:getHandcardNum() > player:getHandcardNum() then return false end
		return candidate:objectName() ~= player:objectName()
	end,

	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,

	on_effect_target = function(skill, ctx, target)
		if target and ctx.use_card then
			target:obtainCard(ctx.use_card)
		end
	end,
}

luafuwei = sgs.CreateTriggerSkillV2 {
	name = "luafuwei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = luafuweivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Play then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(1)
		local invoke = false
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() <= player:getHandcardNum() then
				invoke = true
			end
		end
		if invoke then
			room:askForUseCard(player, "@@luafuwei", "@luafuweicard")
		end
		return false
	end,
}
luafuwei_h = sgs.CreateMaxCardsSkillV2 {
	name = "#luafuwei_h",
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("luafuwei") then
			return 2
		end
		return false
	end
}


lgz:addSkill(luajieyi)
lgz:addSkill(luafuwei)
lgz:addSkill(luafuwei_h)
extension:insertRelatedSkills("luafuwei", "#luafuwei_h")

sgs.LoadTranslationTable {
	["lgz"] = "刘备",
	["luajieyi"] = "结义",
	[":luajieyi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定至多两名其他角色与你各展示一张牌，若颜色相同，你与该角色各摸一张牌，或弃置所展示的牌然后各回复1点体力。",
	["@luajieyicard"] = "请指定一至两名角色发动技能【结义】",
	["luajieyi1"] = "各摸一张牌",
	["luajieyi2"] = "弃置此牌回复1点体力",
	["luafuwei"] = "扶危",
	[":luafuwei"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限始终+2，出牌阶段开始时，你摸一张牌，然后将一张手牌交给一名手牌数不大于你的角色。",
	["@luafuweicard"] = "请指定一名角色发动技能【扶危】",


	--设计者(不写默认为官方)
	["designer:lgz"] = "leowebber",

	--配音(不写默认为官方)
	["cv:lgz"] = "暂无",

	--称号
	["#lgz"] = "桃园义士",

	--插画(默认为KayaK)
	["illustrator:lgz"] = "三国游侠",
}





--关羽
wzgy = sgs.General(extension, "wzgy", "shu", "4", true)


--虎踞

local function luahuju_kingdoms(room)
	local kingdoms = {}
	local kingdom_number = 0
	local players = room:getAlivePlayers()
	for _, aplayer in sgs.qlist(players) do
		if not kingdoms[aplayer:getKingdom()] then
			kingdoms[aplayer:getKingdom()] = true
			kingdom_number = kingdom_number + 1
		end
	end
	if kingdom_number > 3 then kingdom_number = 3 end
	return kingdom_number
end

luahuju = sgs.CreateTriggerSkillV2 {
	name = "luahuju",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_NotActive then return false end
		if player:getHandcardNum() >= luahuju_kingdoms(room) then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local num = player:getHandcardNum()
		local lost = luahuju_kingdoms(room)
		if num >= lost then return false end
		if event == sgs.CardsMoveOneTime then
			room:sendCompulsoryTriggerLog(player, "luahuju", true)
			player:drawCards(lost - num)
			room:broadcastSkillInvoke("luahuju")
		elseif event == sgs.EventPhaseStart then
			room:sendCompulsoryTriggerLog(player, "luahuju", true)
			player:drawCards(lost - num)
		end
		return false
	end
}


wzgy:addSkill(luahuju)

sgs.LoadTranslationTable {
	["wzgy"] = "关羽",
	["luahuju"] = "虎踞",
	[":luahuju"] = "<font color=\"blue\"><b>锁定技，</b></font>回合外你的手牌数至少为X(X为场上现存的势力数且至多为3)。",


	--设计者(不写默认为官方)
	["designer:wzgy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:wzgy"] = "暂无",

	--称号
	["#wzgy"] = "威震华夏",

	--插画(默认为KayaK)
	["illustrator:wzgy"] = "",
}





--司马兄弟
simabro = sgs.General(extension, "simabro", "jin", "4", true)

--擅权

luashanquan = sgs.CreateViewAsSkillV2
	{
		name = "luashanquan",
		n = 0,
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("luashanquan")
		end,

		can_select_target = function(skill, request, selected, candidate)
			local player = request:getInitiator()
			if #selected > 0 or not player or not candidate or candidate:isKongcheng() then
				return false
			end
			return candidate:objectName() ~= player:objectName()
		end,

		targets_feasible = function(skill, request, selected)
			return #selected == 1
		end,

		on_effect_target = function(skill, ctx, target)
			local source = ctx.invoker or ctx.initiator
			if not source or not target then return end
			local room = source:getRoom()
			room:setPlayerFlag(target, "leo_InTempMoving");
			local original_places = sgs.PlaceList()
			local card_ids = sgs.IntList()
			local y = 0
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for i = 1, target:getMaxHp(), 1 do
				card_ids:append(room:askForCardChosen(source, target, "h", "luashanquan"))
				original_places:append(room:getCardPlace(card_ids:at(i - 1)))
				dummy:addSubcard(card_ids:at(i - 1))
				target:addToPile("#luashanquan", card_ids:at(i - 1), false)
				if target:isKongcheng() then break end
			end
			if dummy:subcardsLength() > 0 then
				for i = 1, dummy:subcardsLength(), 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1), false)
				end
			end
			room:setPlayerFlag(target, "-leo_InTempMoving")
			local x = dummy:subcardsLength()
			source:obtainCard(dummy, false)
			dummy:deleteLater()
			local to_goback
			local prompt = string.format("@luashanquanmove:%s", x)
			to_goback = room:askForExchange(source, "luashanquan", x, x, true, prompt)
			room:obtainCard(target, to_goback, false)
		end
	}


--继业
luajiye = sgs.CreateTriggerSkillV2 {
	name = "luajiye",
	frequency = sgs.Skill_Wake,
	waked_skills = "fankui,lianpo",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start or player:getMark("luajiye") >= 1
			or not player:hasSkill(skill:objectName()) then
			return false
		end
		local x = 999
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, p:getHp())
		end
		if player:getHp() <= x or player:canWake(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
			player:drawCards(2)
			room:handleAcquireDetachSkills(player, "fankui")
			room:handleAcquireDetachSkills(player, "lianpo")
			room:addPlayerMark(player, "luajiye")
		end
		return false
	end,
}


simabro:addSkill(luashanquan)
simabro:addSkill(luajiye)

sgs.LoadTranslationTable {
	["simabro"] = "司马兄弟",
	["luashanquan"] = "擅权",
	[":luashanquan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名其他角色的至多X张手牌(X为该角色的体力上限)，然后你交还等量的牌。",
	["@luashanquanmove"] = "擅权\
请返還%src张牌",
	["luajiye"] = "继业",
	[":luajiye"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为场上最少（或之一），你失去1点体力上限，摸两张牌，并获得“反馈”和“连破”。",

	--设计者(不写默认为官方)
	["designer:simabro"] = "leowebber",

	--配音(不写默认为官方)
	["cv:simabro"] = "暂无",

	--称号
	["#simabro"] = "开晋二帝",

	--插画(默认为KayaK)
	["illustrator:simabro"] = "三国无双",
}





--文鸯
leowenyang = sgs.General(extension, "leowenyang", "wei", "4", true)

--骁猛

luaxiaomeng = sgs.CreateTriggerSkillV2 {
	name = "luaxiaomeng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.CardEffected },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or player:objectName() ~= use.from:objectName()
				or not use.card:isKindOf("Slash") then
				return false
			end
			for _, p in sgs.qlist(use.to) do
				if player:distanceTo(p) <= 1 then
					return skill:objectName()
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and (player:distanceTo(effect.from) < 2) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.TargetConfirmed then
			local use = ctx.original_data:toCardUse()
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:distanceTo(p) <= 1 then
					local log = sgs.LogMessage()
					log.type = "#skill_cant_jink"
					log.from = player
					log.to:append(p)
					log.arg = skill:objectName()
					room:sendLog(log)
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		elseif event == sgs.CardEffected then
			local effect = ctx.original_data:toCardEffect()
			room:broadcastSkillInvoke("longdan", 1)
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.arg = skill:objectName()
			log.from = effect.to
			log.arg2 = effect.card:objectName()
			room:sendLog(log)
			return true
		end
	end
}


--突围
luatuwei = sgs.CreateTriggerSkillV2 {
	name = "luatuwei",
	frequency = sgs.Skill_Wake,
	waked_skills = "mashu",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start or player:getMark("luatuwei") >= 1
			or not player:hasSkill(skill:objectName()) then
			return false
		end
		local x = 999
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, p:getHp())
		end
		if player:getHp() <= x or player:canWake(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
			room:handleAcquireDetachSkills(player, "mashu")
			room:addPlayerMark(player, "luatuwei")
		end
		return false
	end,
}


leowenyang:addSkill(luaxiaomeng)
leowenyang:addSkill(luatuwei)

sgs.LoadTranslationTable {
	["leowenyang"] = "文鸯",
	["luaxiaomeng"] = "骁猛",
	[":luaxiaomeng"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离1以内的角色使用的【杀】不可被闪避，距离1以内的角色对你使用的【杀】无效。",
	["luatuwei"] = "突围",
	[":luatuwei"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为场上最少（或之一），你失去1点体力上限，并获得“马术”。",

	--设计者(不写默认为官方)
	["designer:leowenyang"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leowenyang"] = "暂无",

	--称号
	["#leowenyang"] = "单骑退雄兵",

	--插画(默认为KayaK)
	["illustrator:leowenyang"] = "三国战魂",
}


zhaoyungd = sgs.General(extension, "zhaoyungd", "shu", "4", true)

luakongying = sgs.CreateDistanceSkillV2
	{
		name = "luakongying",
		holder_selector = sgs.CorrectSkill_Secondary,
		correct_func = function(skill, ctx)
			local to = ctx:getSecondary()
			if to and to:isKongcheng() then
				return 1
			end
			return false
		end,
	}


luagudan = sgs.CreateViewAsSkillV2 {
	name = "luagudan",
	n = 999,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:isNude() then return false end
		local reason = request:getReason()
		local pattern = request:getPattern()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Slash_IsAvailable(player)
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return pattern == "slash" or pattern == "jink"
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate then return false end
		if request:getSelectedCardIds():isEmpty() then
			return candidate:isEquipped()
		else
			local first = request:getSelectedCards():first()
			if first and first:isEquipped() then
				return false
			end
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then
			local player = request:getInitiator()
			return player and player:getHandcardNum() > 0
		end
		return true
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local reason = request:getReason()
		local pattern = request:getPattern()
		local ids = request:getSelectedCardIds()
		local card = nil
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			or (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash")
			or (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and pattern == "slash") then
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "jink") then
			card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		end
		if not card then return nil end
		if ids:isEmpty() then
			if not player or player:getHandcardNum() == 0 then return nil end
			card:addSubcards(player:getHandcards())
			card:setSkillName("luagudan_ex")
		else
			card:addSubcards(ids)
			card:setSkillName("luagudan_dis")
		end
		return card
	end,
}



luagudanSlash = sgs.CreateTargetModSkillV2 {
	name = "#luagudanSlash",
	pattern = "Slash",
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		local card = ctx:getCard()
		if not player or not card or not player:hasSkill("luagudan") then return false end
		local modType = ctx:getModType()
		if modType == sgs.TargetModSkill_DistanceLimit then
			if table.contains(card:getSkillNames(), "luagudan_dis")
				or table.contains(card:getSkillNames(), "luagudan_ex") then
				return 1000
			end
		elseif modType == sgs.TargetModSkill_ExtraTarget then
			if table.contains(card:getSkillNames(), "luagudan_ex") then
				return card:subcardsLength() - 1
			end
		end
		return false
	end,
}





zhaoyungd:addSkill(luagudan)
zhaoyungd:addSkill(luagudanSlash)
extension:insertRelatedSkills("luagudan", "#luagudanSlash")
zhaoyungd:addSkill(luakongying)

sgs.LoadTranslationTable {
	["zhaoyungd"] = "赵云",
	["luakongying"] = "空营",
	[":luakongying"] = "<font color=\"blue\"><b>锁定技，</b></font>若你没有手牌，其他角色计算与你的距离时始终+1。",
	["$longdan4"] = "吾乃常山赵子龙也~",
	["luagudan"] = "孤胆",
	[":luagudan"] = "你可以将装备区的一张牌当【杀】或【闪】使用或打出，以此法使用的杀无距离限制。你可以将所有手牌当【杀】或【闪】使用或打出，以此法使用的【杀】无距离限制且可以指定至多X名目标角色(X为你弃置牌的张数)。",
	["luagudan_dis"] = "孤胆",
	["luagudan_ex"] = "孤胆",


	--设计者(不写默认为官方)
	["designer:zhaoyungd"] = "leowebber",

	--配音(不写默认为官方)
	["cv:zhaoyungd"] = "暂无",

	--称号
	["#zhaoyungd"] = "一身是胆",

	--插画(默认为KayaK)
	["illustrator:zhaoyungd"] = "暂无",
}


--周瑜
spzhouyu = sgs.General(extension, "spzhouyu", "god", "3", true)

--醇醪
luachunl = sgs.CreateTriggerSkillV2
	{
		name = "luachunl",
		events = { sgs.DamageInflicted },

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			local damage = data:toDamage()
			local from = damage.from
			if from and from:hasSkill(skill:objectName()) then
				return skill:objectName(), from
			elseif player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			local from = damage.from
			local owner = ctx.owner
			if owner and from and owner:objectName() == from:objectName() then
				if room:askForSkillInvoke(owner, "luachunl", ctx.original_data) then
					local recov = sgs.RecoverStruct()
					recov.who = owner
					room:recover(owner, recov)
					return true
				end
			else
				local to = damage.to
				if owner and room:askForSkillInvoke(owner, "luachunl", ctx.original_data) then
					room:loseHp(to, 1, true, to, skill:objectName())
					local x = to:getMaxHp() - to:getHp()
					if x > 2 then x = 2 end
					to:drawCards(x)
					return true
				end
			end
			return false
		end
	}


spzhouyu:addSkill("qinyin")
spzhouyu:addSkill(luachunl)
spzhouyu:addSkill("yingzi")

sgs.LoadTranslationTable {
	["spzhouyu"] = "周瑜",
	["luachunl"] = "醇醪",
	[":luachunl"] = " 当你对其他角色造成伤害时，你可以防止此伤害，然后你回复1点体力。 当你受到伤害时，你可以防止此次伤害，然后你失去1点体力并摸X张牌(X为你损失的体力值且至多为2)。",



	--设计者(不写默认为官方)
	["designer:spzhouyu"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spzhouyu"] = "暂无",

	--称号
	["#spzhouyu"] = "剑胆琴心",

	--插画(默认为KayaK)
	["illustrator:spzhouyu"] = "暂无",
}





--黄月英
sphyy = sgs.General(extension, "sphyy", "shu", "3", false)

--博学
leo_luaboxue = sgs.CreateTriggerSkillV2
	{
		name = "leo_luaboxue",
		events = { sgs.CardUsed, sgs.CardResponded },
		frequency = sgs.Skill_Frequent,

		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			local curcard = nil
			if event == sgs.CardUsed then
				curcard = data:toCardUse().card
			else
				curcard = data:toCardResponse().m_card
			end
			if curcard and not curcard:isKindOf("SkillCard") then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName())
		end,

		on_effect = function(skill, event, room, player, ctx)
			local curcard = nil
			if event == sgs.CardUsed then
				curcard = ctx.original_data:toCardUse().card
			else
				curcard = ctx.original_data:toCardResponse().m_card
			end
			local card = sgs.Sanguosha:getCard(room:drawCard())
			local cardid = card:getEffectiveId()
			--	player:drawCards(1)
			--展示此牌
			player:obtainCard(card)
			room:showCard(player, cardid);
			if (curcard:isKindOf("BasicCard") and not card:isKindOf("BasicCard")) or (curcard:isKindOf("TrickCard") and not card:isKindOf("TrickCard")) or (curcard:isKindOf("EquipCard") and not card:isKindOf("EquipCard")) then
				--将1张手牌依次置于牌堆顶
				local card_ids = sgs.IntList()
				for _, cd in sgs.qlist(player:getHandcards()) do
					if cd:getEffectiveId() ~= curcard:getEffectiveId() then
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
				end
				for _, cd in sgs.qlist(player:getEquips()) do
					if cd:getEffectiveId() ~= curcard:getEffectiveId() then
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
				end
				room:fillAG(card_ids, player)
				local cdid = room:askForAG(player, card_ids, false, skill:objectName())
				room:setPlayerFlag(player, "Global_GongxinOperator")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid), player, nil, sgs.Player_DrawPile,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "leo_luaboxue", ""), true)
				card_ids:removeOne(cdid)
				room:clearAG(player)
				room:setPlayerFlag(player, "-Global_GongxinOperator")
			end
			return false
		end
	}

--巧械
luaqiaoxie = sgs.CreateTriggerSkillV2
	{
		name = "luaqiaoxie",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Frequent,

		can_trigger = function(skill, event, room, player, data)
			if not player or player:getPhase() ~= sgs.Player_Start then return false end
			local hasej = false
			for _, ecard in sgs.qlist(player:getEquips()) do
				hasej = true
			end
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				hasej = true
			end
			if hasej then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName())
		end,

		on_effect = function(skill, event, room, player, ctx)
			local ejcard = room:askForCardChosen(player, player, "ej", "luaqiaoxie")
			room:obtainCard(player, ejcard)
			return false
		end
	}


sphyy:addSkill(leo_luaboxue)
sphyy:addSkill(luaqiaoxie)
sphyy:addSkill("qicai")

sgs.LoadTranslationTable {
	["sphyy"] = "黄月英",
	["leo_luaboxue"] = "博学",
	[":leo_luaboxue"] = "你使用或打出一张牌时，可以摸一张牌并展示之，若此牌与你使用或打出的牌类型不同，你需将一张牌置于牌堆顶。",
	["luaqiaoxie"] = "巧械",
	[":luaqiaoxie"] = "回合开始时，你可以将判定区或装备区的一张牌收归手牌。",


	--设计者(不写默认为官方)
	["designer:sphyy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:sphyy"] = "暂无",

	--称号
	["#sphyy"] = "归隐的杰女",

	--插画(默认为KayaK)
	["illustrator:sphyy"] = "真三国无双",
}



shenlvbuII = sgs.General(extension, "shenlvbuII", "god", "4", true)


--[[
luafeijiang = sgs.CreateDistanceSkill
{
	name = "luafeijiang",
	correct_func = function(self, from, to)
		if from:hasSkill("luafeijiang") then
			return -10
		end
	end,
}]]
luafeijiang = sgs.CreateDistanceSkillV2 {
	name = "luafeijiang",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		return false
	end,
	fixed_func = function(skill, ctx)
		local from = ctx:getPrimary()
		if from and from:hasSkill("luafeijiang") then
			return 1
		end
		return false
	end,
}




shenlvbuII:addSkill(xinwushuangTM)
shenlvbuII:addSkill(xinwushuang)

shenlvbuII:addSkill("shenwei")
shenlvbuII:addSkill(luafeijiang)


sgs.LoadTranslationTable {
	["shenlvbuII"] = "吕布",

	["luafeijiang"] = "飞将",
	[":luafeijiang"] = "<font color=\"blue\"><b>锁定技，</b></font>你与其他角色的距离视为1。",

	--设计者(不写默认为官方)
	["designer:shenlvbuII"] = "leowebber，之语，晴心~雨忆~", --lua制作：之语; 构思：leowebber

	--配音(不写默认为官方)
	["cv:shenlvbuII"] = "暂无",

	--称号
	["#shenlvbuII"] = "暴怒的战神",

	--插画(默认为KayaK)
	["illustrator:shenlvbuII"] = "未知",
}









czyex = sgs.General(extension, "czyex", "qun", "3", true)


luachongzhenex = sgs.CreateTriggerSkillV2 {
	name = "luachongzhenex",
	events = { sgs.CardOffset },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local effect = data:toCardEffect()
		if not effect.card or not effect.card:isKindOf("Slash") then return false end
		if player:hasSkill(skill:objectName()) then
			if effect.offset_card
				and room:getCardPlace(effect.offset_card:getEffectiveId()) == sgs.Player_DiscardPile then
				return skill:objectName()
			end
		elseif effect.to and effect.to:hasSkill(skill:objectName()) then
			if room:getCardPlace(effect.card:getEffectiveId()) == sgs.Player_PlaceTable then
				return skill:objectName(), effect.to
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		local owner = ctx.owner
		if owner and ctx.invoker and owner:objectName() == ctx.invoker:objectName() then
			if owner:askForSkillInvoke(skill:objectName(), ctx.original_data) then
				owner:obtainCard(effect.offset_card)
			end
		else
			if owner and owner:askForSkillInvoke(skill:objectName(), ctx.original_data) then
				owner:obtainCard(effect.card)
			end
		end
		return false
	end,
}


luashenweiex1 = sgs.CreateTriggerSkillV2 {
	name = "luashenweiex1",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if player and data:toDraw().reason == "draw_phase" and player:isWounded() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		draw.num = draw.num + 1
		room:sendCompulsoryTriggerLog(player, "luashenweiex1", true)
		ctx.original_data:setValue(draw)
		return false
	end
}
luashenweiex1_Keep = sgs.CreateMaxCardsSkillV2 {
	name = "#luashenweiex1_Keep",
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("luashenweiex1") and target:isWounded() then
			return 1
		end
		return false
	end
}

czyex:addSkill(luachongzhenex)
czyex:addSkill(luashenweiex1)
czyex:addSkill(luashenweiex1_Keep)
extension:insertRelatedSkills("luashenweiex1", "#luashenweiex1_Keep")
czyex:addSkill("longdan")

sgs.LoadTranslationTable {
	["czyex"] = "赵云",
	["luachongzhenex"] = "冲阵",
	[":luachongzhenex"] = "你使用【杀】被【闪】抵消时可以获得这张【闪】。你使用【闪】抵消【杀】时可以获得这张【杀】。",
	["luashenweiex1"] = "逆鳞",
	[":luashenweiex1"] = "<font color=\"blue\"><b>锁定技，</b></font>若你已受伤，摸牌阶段你额外摸一张牌，你的手牌上限+1。",

	--设计者(不写默认为官方)
	["designer:czyex"] = "leowebber",

	--配音(不写默认为官方)
	["cv:czyex"] = "暂无",

	--称号
	["#czyex"] = "白马先锋",

	--插画(默认为KayaK)
	["illustrator:czyex"] = "真三国无双",
}



wyzf = sgs.General(extension, "wyzf", "shu", "4", true)

--泼墨
wyzf_pomo = sgs.CreateTriggerSkillV2
	{
		name = "wyzf_pomo",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Frequent,

		can_trigger = function(skill, event, room, player, data)
			if player and (player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Finish) then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			if player:getPhase() == sgs.Player_Play then
				return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
			end
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			local players = room:getAllPlayers()
			if player:getPhase() == sgs.Player_Play then
				local id = room:drawCard()
				local card = sgs.Sanguosha:getCard(id)
				player:obtainCard(card)
				--展示此牌
				room:showCard(player, card:getEffectiveId());
				if card:isBlack() then
					--将1张手牌依次置于牌堆顶
					local carda = room:askForExchange(player, skill:objectName(), 1, 1, false, "wyzf_pomoGoBack",
						false)
					if carda then
						local move = sgs.CardsMoveStruct()
						move.card_ids = carda:getSubcards()
						move.to_place = sgs.Player_DrawPile
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
							"wyzf_pomo", "");
						move.reason = reason
						room:setPlayerFlag(player, "Global_GongxinOperator")
						room:moveCardsAtomic(move, false)
						room:setPlayerFlag(player, "-Global_GongxinOperator")
					end
					room:addPlayerMark(player, "&wyzf_pomo-Clear")
					for _, p in sgs.qlist(players) do
						room:setFixedDistance(player, p, 1)
					end
					room:broadcastSkillInvoke("wyzf_pomo", 2)
				else
					room:broadcastSkillInvoke("wyzf_pomo", 1)
				end
			elseif player:getPhase() == sgs.Player_Finish then
				room:broadcastSkillInvoke("wyzf_pomo", 3)
				for _, p in sgs.qlist(players) do
					room:removeFixedDistance(player, p, 1)
				end
			end
			return false
		end
	}


wyzf:addSkill(wyzf_pomo)

sgs.LoadTranslationTable {
	["wyzf"] = "张飞",
	["wyzf_pomo"] = "泼墨",
	[":wyzf_pomo"] = "出牌阶段开始时，你可以摸一张牌并展示之。若为黑色，你需将一张手牌置于牌堆顶，且本阶段内，你使用黑色牌无距离限制。",
	["wyzf_pomoGoBack"] = "你需将一张手牌置于牌堆顶",
	["$wyzf_pomo1"] = "风劲角弓鸣，将军猎渭城",
	["$wyzf_pomo2"] = "草枯鹰眼疾，雪尽马蹄轻",
	["$wyzf_pomo3"] = "回看射雕处，千里暮云平",


	--设计者(不写默认为官方)
	["designer:wyzf"] = "leowebber",

	--配音(不写默认为官方)
	["cv:wyzf"] = "暂无",

	--称号
	["#wyzf"] = "涿郡英豪",

	--插画(默认为KayaK)
	["illustrator:wyzf"] = "火凤三国",
}


leozhangxiu = sgs.General(extension, "leozhangxiu", "qun", "4", true)


luafanfu_viewas = sgs.CreateViewAsSkillV2
	{
		name = "luafanfu",
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		target_effect_mode = sgs.ViewAsSkillV2_EachTarget,

		can_activate = function(skill, request)
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				return request:getPattern() == "@@luafanfu"
			end
			return false
		end,

		can_select_card = function(skill, request, candidate)
			return candidate and request:getSelectedCardIds():isEmpty()
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() == 1
		end,

		can_select_target = function(skill, request, selected, candidate)
			local player = request:getInitiator()
			return player and candidate and #selected < 1
				and candidate:objectName() ~= player:objectName()
		end,

		targets_feasible = function(skill, request, selected)
			return #selected == 1
		end,

		on_effect_target = function(skill, ctx, target)
			local from = ctx.invoker
			local to = target
			local room = ctx.owner:getRoom()
			local kdfrom = from:getKingdom()
			local kdto = to:getKingdom()

			if kdfrom ~= kdto then
				from:drawCards(1, skill:objectName())
				to:drawCards(1, skill:objectName())
				room:setPlayerProperty(from, "kingdom", sgs.QVariant(kdto))
			else
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(skill:objectName())
				local use_card = sgs.CardUseStruct()
				use_card.from = from
				use_card.to:append(to)
				use_card.card = slash
				room:useCard(use_card, false)
				slash:deleteLater()
				local kd = sgs.Sanguosha:getKingdoms()
				table.removeOne(kd,from:getKingdom())
				if #kd<1 then return end
				kd = table.concat(kd,"+")
				kd = room:askForChoice(from,skill:objectName(),kd)
				local log = sgs.LogMessage()
				log.type = "#ChangeKingdom2"
				log.from = from
				log.arg = from:getKingdom()
				log.arg2 = kd
				room:sendLog(log)
				room:setPlayerProperty(from, "kingdom", sgs.QVariant(kd))
			end
		end
	}

luafanfu = sgs.CreateTriggerSkillV2
	{
		name = "luafanfu",
		view_as_skill = luafanfu_viewas,
		events = { sgs.EventPhaseStart },

		can_trigger = function(skill, event, room, player, data)
			if player and player:getPhase() == sgs.Player_Start then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			room:askForUseCard(player, "@@luafanfu", "@luafanfu_card")
			return false
		end
	}


luaqiangwang = sgs.CreateTriggerSkillV2 {
	name = "luaqiangwang",
	events = { sgs.TargetSpecified },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player and use.from and use.from:objectName() == player:objectName()
				and use.from:hasSkill(skill:objectName()) and use.card:isKindOf("Slash") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local can_invoke = false
		for _, p in sgs.qlist(use.to) do
			if (player:distanceTo(p) > 1) then
				if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then
					p:addQinggangTag(use.card)
					can_invoke = true
				end
			end
		end
		if can_invoke then
			room:setEmotion(use.from, "weapon/qinggang_sword")
			room:sendCompulsoryTriggerLog(use.from, "luaqiangwang", true)
			local log = sgs.LogMessage()
			log.type = "#IgnoreArmor"
			log.from = player
			log.card_str = use.card:toString()
			room:sendLog(log)
		end
		return false
	end,
}


leozhangxiu:addSkill(luafanfu)
leozhangxiu:addSkill(luaqiangwang)

sgs.LoadTranslationTable {
	["leozhangxiu"] = "张绣",
	["luafanfu"] = "反复",
	[":luafanfu"] = "回合开始时，你可以弃置一张牌并指定一名其他角色：若势力不同，你与其各摸一张牌，然后你需变为该角色的势力。若势力相同，视为你对其使用了一张【杀】，然后你需变为一个其他势力。",
	["@luafanfu_card"] = "请指定一名角色发动【反复】",
	["luaqiangwang"] = "枪王",
	[":luaqiangwang"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离大于1的角色使用【杀】时，无视其防具。",
	["luafanfu_"] = "反复",

	--设计者(不写默认为官方)
	["designer:leozhangxiu"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leozhangxiu"] = "暂无",

	--称号
	["#leozhangxiu"] = "宛城侯",

	--插画(默认为KayaK)
	["illustrator:leozhangxiu"] = "三国志12",
}


spjwh = sgs.General(extension, "spjwh", "qun", "3", true)

dushicardname = nil

--洞察
luadushi = sgs.CreateTriggerSkillV2 {
	name = "luadushi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.CardUsed },

	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseStart then
			if player:hasSkill("luadushi")
				and (player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Finish) then
				return "luadushi"
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local curp = room:getCurrent()
			if move.from and not move.from:hasSkill("luadushi")
				and player:getGeneralName() == move.from:getGeneralName()
				and curp and curp:hasSkill("luadushi")
				and move.to_place == 5 then
				return "luadushi", curp
			end
		elseif event == sgs.CardUsed then
			local card = data:toCardUse().card
			if player:hasSkill("luadushi") and card
				and (card:match("archery_attack") or card:match("savage_assault")) then
				return "luadushi"
			end
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local alplayers = room:getAlivePlayers()
				local duship = room:askForPlayerChosen(player, alplayers, "@luadushi1")
				if (duship ~= nil and not duship:isKongcheng()) then
					local cdid = room:askForCardChosen(player, duship, "h", skill:objectName(), true)
					local dest = sgs.QVariant()
					dest:setValue(cdid)
					room:setTag("luadushi", dest)
					room:showCard(duship, cdid)
					local dushic = sgs.Sanguosha:getCard(cdid)
					dushicardname = dushic:objectName()
					room:addPlayerMark(player, "&luadushi+" .. dushicardname .. "-PlayClear")
					room:broadcastSkillInvoke("weimu", 1)
				end
			elseif player:getPhase() == sgs.Player_Finish then
				dushicardname = nil
				room:removeTag("luadushi")
			end
		elseif event == sgs.CardsMoveOneTime then
			local curp = ctx.owner
			local mover = ctx.invoker
			local move = ctx.original_data:toMoveOneTime()
			local dushidiscard = nil
			for _, cdid in sgs.qlist(move.card_ids) do
				dushidiscard = sgs.Sanguosha:getCard(cdid)
				if (dushidiscard:match(dushicardname)) then
					if mover:isKongcheng() and not mover:hasEquip() then
						room:broadcastSkillInvoke("wansha", 1)
						room:loseHp(mover, 1, true, nil, skill:objectName())
					else
						choice = room:askForChoice(curp, "luadushi", "luadushi1+luadushi2")
						if (choice == "luadushi1") then
							local movecard_id = room:askForCardChosen(curp, mover, "he", "luadushi1")
							room:broadcastSkillInvoke("fankui", 1)
							curp:obtainCard(sgs.Sanguosha:getCard(movecard_id))
						else
							room:broadcastSkillInvoke("wansha", 1)
							room:loseHp(mover, 1, true, nil, skill:objectName())
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			room:broadcastSkillInvoke("luanwu", 1)
		end
		return false
	end,
}


--韬晦
luataohui = sgs.CreateTriggerSkillV2
	{
		name = "luataohui",
		events = { sgs.DamageInflicted },
		frequency = sgs.Skill_Compulsory,
		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Thunder or damage.nature == sgs.DamageStruct_Fire then
				return false
			end
			if damage.from and player:getHp() < damage.from:getHp() then
				return skill:objectName()
			end
			return false
		end,
		on_effect = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke("weimu", 2)
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
			return true
		end
	}
luataohui_c = sgs.CreateMaxCardsSkillV2 {
	name = "#luataohui_c",
	fixed_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("luataohui") then
			return target:getMaxHp()
		end
		return false
	end
}


spjwh:addSkill(luadushi)
spjwh:addSkill(luataohui)
spjwh:addSkill(luataohui_c)
extension:insertRelatedSkills("luataohui", "#luataohui_c")

sgs.LoadTranslationTable {
	["spjwh"] = "贾文和",
	["luadushi"] = "洞察",

	[":luadushi"] = "出牌阶段开始时，你可以观看一名角色的手牌并展示其中一张牌。则本阶段内，除你外的角色与此牌同名的牌进入弃牌堆时，你获得该角色的一张牌或令其失去1点体力。",
	["@luadushi1"] = "选择一名角色并展示该角色的一张手牌。",
	["@luadushi2"] = "选择展示一张手牌。",
	["luadushi1"] = "获得该角色的一张牌。",
	["luadushi2"] = "令该角色失去1点体力。",
	["luataohui"] = "韬晦",
	[":luataohui"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限始终等于体力上限，你防止体力值大于你的角色对你造成的无属性伤害。",



	--设计者(不写默认为官方)
	["designer:spjwh"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spjwh"] = "暂无",

	--称号
	["#spjwh"] = "算无遗策",

	--插画(默认为KayaK)
	["illustrator:spjwh"] = "三国志12",
}


guanyuzy = sgs.General(extension, "guanyuzy", "shu", "4", true)

local patterns = { "slash", "jink", "peach", "analeptic" }
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end
local slash_patterns = { "slash", "normal_slash", "thunder_slash", "fire_slash" }

-- The "#luazhiyong" card-string contract stays for AI submissions; the V2
-- view-as resolves them, so the SkillCard only exists as a parse prototype.
luazhiyongCard = sgs.CreateSkillCard {
	name = "luazhiyong",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
}

local function luazhiyongBuildCard(request, name)
	local ids = request:getSelectedCardIds()
	if ids:isEmpty() then return nil end
	local material = sgs.Sanguosha:getCard(ids:first())
	if not material then return nil end
	if name == "slash" then
		if material:isKindOf("Slash") then
			name = material:objectName()
		end
	elseif name == "normal_slash" then
		name = "slash"
	end
	local card = sgs.Sanguosha:cloneCard(name, material:getSuit(), material:getNumber())
	if not card then return nil end
	card:addSubcard(ids:first())
	card:setSkillName("luazhiyong")
	card:setCanRecast(false)
	return card
end

luazhiyongVS = sgs.CreateViewAsSkillV2 {
	name = "luazhiyong",
	n = 1,
	response_or_use = true,
	guhuo_type = "l",
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			newanal:deleteLater()
			if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then
				return player:usedTimes("Analeptic") <=
					sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
			end
			return sgs.Slash_IsAvailable(player) or player:isWounded()
		end
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		local pattern = request:getPattern()
		if pattern == "@luazhiyong" then
			return not player:isKongcheng()
		end
		if pattern == "peach" and player:hasFlag("Global_PreventPeach") then return false end
		return (pattern == "slash")
			or (pattern == "jink")
			or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
			or (string.find(pattern, "analeptic"))
	end,
	can_select_card = function(self, request, to_select)
		return to_select and to_select:getSuit() == sgs.Card_Heart
	end,
	allow_declaration = function(self, player, name)
		return table.contains(patterns, name)
	end,
	build_card = function(self, request, name)
		return luazhiyongBuildCard(request, name)
	end,
	cost = function(self, room, ctx, request)
		local yuji = ctx.invoker or ctx.initiator
		if not yuji then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return true end
		local to_guhuo = request:getUserString()
		if to_guhuo == "" then to_guhuo = request:getPattern() end
		local ask_name = nil
		local guhuo_list = {}
		if to_guhuo == "slash" then
			ask_name = "luazhiyong_slash"
			guhuo_list = (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"]
				and { "slash" } or slash_patterns
		elseif to_guhuo == "peach+analeptic" then
			ask_name = "guhuo_saveself"
			table.insert(guhuo_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "analeptic")
			end
		end
		if not ask_name then return true end
		to_guhuo = room:askForChoice(yuji, ask_name, table.concat(guhuo_list, "+"))
		local use_card = luazhiyongBuildCard(request, to_guhuo)
		if not use_card then return false end
		ctx.updated_card = use_card
		return true
	end,
}

luazhiyong = sgs.CreateTriggerSkillV2
	{
		name = "luazhiyong",
		events = { sgs.CardUsed, sgs.CardResponded },
		view_as_skill = luazhiyongVS,
		can_trigger = function(skill, event, room, player, data)
			if not player or not player:hasSkill("luazhiyong") then return false end --关羽触发此处
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			if event == sgs.CardUsed then
				local curcard = data:toCardUse().card
				if curcard and table.contains(curcard:getSkillNames(), "luazhiyong") then
					return skill:objectName()
				end
			elseif event == sgs.CardResponded then
				local card = data:toCardResponse().m_card
				if card and table.contains(card:getSkillNames(), "luazhiyong") then
					return skill:objectName()
				end
			end
			return false
		end,
		on_effect = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke("wusheng", 1)
			player:drawCards(1)
			return false
		end
	}

luayijuedestCard = sgs.CreateSkillCard {
	name = "luayijuedestCard",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, player) and
			not player:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, from)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local guanyu = room:findPlayerBySkillName("luayijue")
		if not guanyu:isAlive() or guanyu:isNude() then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@luayijue:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card = room:askForCard(guanyu, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse,
			guanyu);
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_luayijueFailed")
		room:setPlayerFlag(user, "Global_luayijueFailed_AI")
		return false
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local guanyu = room:findPlayerBySkillName("luayijue")
		if not guanyu or not guanyu:isAlive() or guanyu:isNude() then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end

		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@luayijue:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card = room:askForCard(guanyu, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse,
			guanyu);
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_luayijueFailed")
		room:setPlayerFlag(user, "Global_luayijueFailed_AI")
		return false
	end
}
local function luayijuedestName(request)
	local user_string = request:getUserString()
	if user_string ~= "" then return user_string:split("+")[1] end
	local pattern = request:getPattern()
	local player = request:getInitiator()
	if pattern == "peach+analeptic" and player and player:getMark("Global_PreventPeach") > 0 then
		pattern = "analeptic"
	end
	return pattern:split("+")[1]
end

luayijuedest = sgs.CreateViewAsSkillV2 {
	name = "luayijuedest&",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or player:getPhase() ~= sgs.Player_NotActive
			or player:hasFlag("Global_luayijueFailed") then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		local pattern = request:getPattern()
		if pattern == "slash" then
			return true
		elseif pattern == "peach" then
			return player:getMark("Global_PreventPeach") == 0
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
	can_select_target = function(self, request, selected, to_select)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local player = request:getInitiator()
		if not player or not to_select then return false end
		local card = sgs.Sanguosha:cloneCard(luayijuedestName(request))
		if not card then return false end
		card:deleteLater()
		if card:targetFixed() then return false end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(selected) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
			and not player:isProhibited(to_select, card, qtargets)
	end,
	targets_feasible = function(self, request, selected)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return #selected == 0
		end
		local player = request:getInitiator()
		if not player then return false end
		local card = sgs.Sanguosha:cloneCard(luayijuedestName(request))
		if not card then return false end
		card:deleteLater()
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(selected) do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets, player)
	end,
	cost = function(self, room, ctx, request)
		local user = ctx.invoker or ctx.initiator
		if not user then return false end
		local guanyu = room:findPlayerBySkillName("luayijue")
		if not guanyu or not guanyu:isAlive() or guanyu:isNude() then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end
		local name = luayijuedestName(request)
		local prompt = string.format("@@luayijue:%s", name)
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card = room:askForCard(guanyu, name, prompt, dt, sgs.Card_MethodResponse, guanyu)
		if not card then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end
		ctx.updated_card = card
		return true
	end,
}


luayijue = sgs.CreateTriggerSkillV2
	{
		name = "luayijue",
		events = { sgs.EventPhaseStart, sgs.CardAsked },
		frequency = sgs.Skill_Limited,
		can_trigger = function(skill, event, room, player, data)
			if not player then return false end
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName())
					and not (player:getMark("luayijue_used") > 0) then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if (p:getMark("@luayijue") > 0) then return false end
					end
					return skill:objectName()
				end
			elseif event == sgs.CardAsked then
				if player:getPhase() == sgs.Player_NotActive and (player:getMark("@luayijue") > 0) then
					local pattern = data:toStringList()[1]
					if pattern ~= "jink" and pattern ~= "slash" and not string.find(pattern, "peach") then
						return false
					end
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if (p:hasSkill(skill:objectName())) then
							return skill:objectName(), p
						end
					end
				end
			end
			return false
		end,
		on_cost = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart then
				return room:askForSkillInvoke(player, "luayijue_xianfu")
			elseif event == sgs.CardAsked then
				return ctx.invoker:askForSkillInvoke(skill:objectName(), ctx.original_data)
			end
			return true
		end,
		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart then
				local yijuetarget = room:askForPlayerChosen(player, room:getOtherPlayers(player), "luayijue")
				room:addPlayerMark(yijuetarget, "&luayijue+to+#" .. player:objectName())
				yijuetarget:gainMark("@luayijue")
				room:setPlayerMark(player, "luayijue_used", 1)
				room:broadcastSkillInvoke("danji", 1)
				room:attachSkillToPlayer(yijuetarget, "luayijuedest")
				return false
			elseif event == sgs.CardAsked then
				local pattern = ctx.original_data:toStringList()[1]
				local asktext = pattern
				if string.find(pattern, "peach") then
					asktext = "peach"
				end
				local guanyu = ctx.owner
				local dt = sgs.QVariant(0)
				dt:setValue(ctx.invoker)
				local supplycard = room:askForCard(guanyu, asktext, "luayijue" .. asktext, dt,
					sgs.Card_MethodResponse, guanyu)
				if (supplycard) then
					room:provide(supplycard)
					return true
				end
			end
			return false
		end,
	}



guanyuzy:addSkill(luazhiyong)
guanyuzy:addSkill(luayijue)

sgs.LoadTranslationTable {
	["guanyuzy"]             = "关羽",
	["luazhiyong"]           = "智勇",
	[":luazhiyong"]          = "你的红桃牌可以当任意一张基本牌使用或打出，若在回合外如此做，你摸一张牌。",
	["luazhiyongcard"]       = "智勇",
	["luazhiyongcancel"]     = "取消",
	["luazhiyong-new"]       = "智勇",
	["luazhiyong_select"]    = "智勇",
	["@@luazhiyong"]         = "你可以将一张基本牌 当 %src 使用或打出。",
	["~luazhiyong"]          = "选择一张牌→点击确定",
	["luayijue"]             = "义绝",
	["luayijue_xianfu"]      = "义绝",
	[":luayijue"]            = "<font color=\"red\"><b>限定技，</b></font>回合开始阶段，你可以指定一名其他角色：该角色回合外需要使用或打出一张基本牌时，你可以替其使用或打出，直至该角色阵亡或游戏结束。",
	["luayijueslash"]        = "是否发动义绝打出一张【杀】",
	["luayijuejink"]         = "是否发动义绝打出一张【闪】",
	["luayijuepeach"]        = "是否发动义绝打出一张【桃】",
	["@luayijue"]            = "义绝",
	["@@luayijue"]           = "是否发动义绝使用或打出一张 %src",
	["luayijuedest"]         = "义绝",

	--设计者(不写默认为官方)
	["designer:guanyuzy"]    = "leowebber",

	--配音(不写默认为官方)
	["cv:guanyuzy"]          = "暂无",

	--称号
	["#guanyuzy"]            = "忠义两全",

	--插画(默认为KayaK)
	["illustrator:guanyuzy"] = "暂无",
}

if not sgs.Sanguosha:getSkill("luayijuedest") then
	s_skillList:append(luayijuedest)
end


bazhenwolong=sgs.General(extension, "bazhenwolong", "shu", "3", true)
--帷幄
leo_luaweiwo = sgs.CreateTriggerSkillV2
{
	name = "leo_luaweiwo",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,

	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(3)
		--将x张手牌依次置于牌堆顶
		local x = player:getHp()
		if(x > 3) then x = 3 end
		local card_ids = sgs.IntList()
		for _,cd in sgs.qlist(player:getHandcards()) do
			local id = cd:getEffectiveId()
			card_ids:append(id)
		end
		for var = 1 , x, 1 do
			room:fillAG(card_ids, player)
			local cdid = room:askForAG(player, card_ids, false, skill:objectName())
			room:moveCardTo(sgs.Sanguosha:getCard(cdid), nil, sgs.Player_DrawPile, true)
			card_ids:removeOne(cdid)
			room:clearAG()
		end
		return false
	end
}

--八阵梅花
luabazhen_viewas = sgs.CreateViewAsSkillV2
{
	name = "luabazhen_viewas",
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_WholeTargetGroup,

	can_activate = function(skill, request)
		return false
	end,

	can_select_target = function(skill, request, selected, candidate)
		return candidate and #selected < 2
	end,

	targets_feasible = function(skill, request, selected)
		return #selected >= 1 and #selected <= 2
	end,

	on_effect_target_group = function(skill, ctx, targets)
		local room = ctx.owner:getRoom()
		local use_card = sgs.CardUseStruct()
		use_card.from = ctx.invoker
		for _, p in ipairs(targets) do
			use_card.to:append(p)
		end
		local card = sgs.Sanguosha:cloneCard("iron_chain",sgs.Card_NoSuit,0)
		card:setSkillName("luaspbazhen")
		use_card.card = card
		room:useCard(use_card,false)
		card:deleteLater()
	end
}

--八阵
luaspbazhen = sgs.CreateTriggerSkillV2 {
	name = "luaspbazhen",
	view_as_skill = luabazhen_viewas,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName()
			and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_NotActive
			and (move.from_places:contains(sgs.Player_PlaceHand)
				or move.from_places:contains(sgs.Player_PlaceEquip)) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local source = move.from
		do
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						local places = move.from_places
						if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
							room:broadcastSkillInvoke("fankui",1)
							--展示此牌
							room:showCard(player, card:getEffectiveId());
							local targetPlayers = room:getAlivePlayers()
							--如果失去的是基本牌或装备牌
							if(not card:isKindOf("TrickCard")) then 
								room:broadcastSkillInvoke("bazhen",2)
								local cardid = 0
								--红桃则先摸一张牌
								if(card:getSuit()==sgs.Card_Heart) then
									cardid = room:drawCard()
									local move = sgs.CardsMoveStruct()
									move.card_ids:append(cardid)
									move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,source:objectName(),"luaspbazhen","")
									move.to_place = sgs.Player_PlaceTable
									room:moveCardsAtomic(move,true)
									--player:drawCards(1) 
								end
			
								local targetp = nil
								
								--黑桃
								if(card:getSuit()==sgs.Card_Spade) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen1")
									if(targetp:isKongcheng() and not targetp:hasEquip()) or targetp==player then 
										return false
									else
										room:broadcastSkillInvoke("fankui",1)
										cardid = room:askForCardChosen(player, targetp, "he", "luaspbazhen");
										player:obtainCard(sgs.Sanguosha:getCard(cardid))
									end
								--梅花
								elseif(card:getSuit()==sgs.Card_Club) then
									room:askForUseCard(player, "@@luaspbazhen", "@luabazhen_club")
								--红桃
								elseif(card:getSuit()==sgs.Card_Heart) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen3")
									room:broadcastSkillInvoke("yiji",1)
									if(targetp==player) then 
										player:obtainCard(sgs.Sanguosha:getCard(cardid))
									else
										targetp:obtainCard(sgs.Sanguosha:getCard(cardid))
									end
								--方片
								elseif(card:getSuit()==sgs.Card_Diamond) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen4")
									if(targetp:isKongcheng()) then 
										return false
									else
										room:broadcastSkillInvoke("huoji",1)
										local use_card = sgs.CardUseStruct()
										use_card.from = player
										use_card.to:append(targetp)
										local fire_attack = sgs.Sanguosha:cloneCard("fire_attack",sgs.Card_NoSuit,0)
										fire_attack:setSkillName("luaspbazhen")
										use_card.card = fire_attack
										room:useCard(use_card,false)
										fire_attack:deleteLater()
									end
								end
							end
						end
					end
		end
		return false
	end,
}


bazhenwolong:addSkill("luaweiwo")
bazhenwolong:addSkill(luaspbazhen)

sgs.LoadTranslationTable{
	["bazhenwolong"]="八阵诸葛",
	["leo_luaweiwo"] = "帷幄",	
	[":leo_luaweiwo"] = "回合结束时可摸3张牌，并将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",
	["luaspbazhen"] = "八阵ex",	
	[":luaspbazhen"] = "回合外你失去一张牌时，可展示此牌，若为基本牌或装备牌，按此牌的花色执行一项：1、黑桃，获得任意一名角色的一张牌 2、梅花，将一至两名角色的武将牌横置或重置 3、红桃，摸一张牌交给任意一名角色 4、方片，视为使用了一张【火攻】。",
	["@luaspbazhen1"] = "发动技能八阵，选择一名角色，获得该角色的一张牌。",
	--["@luaspbazhen2"] = "发动技能八阵，选择一名角色，将该角色的武将牌横置或重置。",
	["@luaspbazhen3"] = "发动技能八阵，选择一名角色，将你摸的一张牌交给该角色。",
	["@luaspbazhen4"] = "发动技能八阵，选择一名角色，对该角色使用一张【火攻】。",
	["@luabazhen_club"] = "指定一到两名角色，将其武将牌横置或重置",
	["~luabazhen"] = "若为基本牌或装备牌，按此牌的花色执行一项：1、黑桃，获得任意一名角色的一张牌 2、梅花，将一至两名角色的武将牌横置或重置 3、红桃，摸一张牌交给任意一名角色 4、方片，视为使用了一张【火攻】。",
	["luabazhen_club"] = "八阵",
--设计者(不写默认为官方)
	["designer:bazhenwolong"] = "leowebber",
	
--配音(不写默认为官方)
	["cv:bazhenwolong"] = "暂无",
	
--称号
	["#bazhenwolong"] = "多智而近妖",
	
--插画(默认为KayaK)
	["illustrator:bazhenwolong"] = "暂无",
}

leo_spwolong=sgs.General(extension, "leo_spwolong", "shu", "3", true)

luatianming = sgs.CreateTriggerSkillV2{
	name = "luatianming",
	frequency = sgs.Skill_Wake,
	events = {sgs.AskForPeaches},
	waked_skills = "bazhen,kanpo,jizhi",
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName())
			and player:getMark("luatianming") < 1
			and (player:getMark("&luarangxingRX") >= 7 or player:canWake(skill:objectName())) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerMark(player, "luatianming", 1)
		room:broadcastSkillInvoke("qixing",2)

		while player:getHp()<1 do
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end

		--while player:getMaxHp()>1 do
		--	room:loseMaxHp(player)
		--end

		local count = player:getMark("&luarangxingRX")
		player:drawCards(count)
		room:addMaxCards(player, count, false)
		room:changeMaxHpForAwakenSkill(player, 0, skill:objectName())
		room:acquireSkill(player, "bazhen")
		room:acquireSkill(player, "kanpo")
		room:acquireSkill(player, "jizhi")
		room:detachSkillFromPlayer(player,"luarangxing")
		return false
	end,
}

luarangxing = sgs.CreateTriggerSkillV2
{
	name = "luarangxing",
	events = {sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_NotFrequent,

	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:getMark("tianming") == 0 then
			return skill:objectName()
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerMark(player, "&luarangxingRX")
		room:broadcastSkillInvoke("qixing",1)
		return false
	end
}

luajincui = sgs.CreateTriggerSkillV2
{
	name = "luajincui",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,

	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Play and player:getMaxHp() > 1 then
			return skill:objectName()
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		local jincuiTarget = room:askForPlayerChosen(player, room:getAllPlayers(), "luajincui")
		room:broadcastSkillInvoke("yiji",1)
		local choice = room:askForChoice(player, "luajincui", "luajincui1+luajincui2")
		jincuiTarget:drawCards(2)
		if(choice == "luajincui1") then
			room:loseHp(player, 1, true, player, skill:objectName())
		else
			room:loseMaxHp(player)
		end
		return false
	end
}

newluaweiwo = sgs.CreateTriggerSkillV2
{
	name = "newluaweiwo",
	events = {sgs.StartJudge, sgs.EventPhaseChanging},
	frequency = sgs.Skill_NotFrequent,

	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.StartJudge then
			if player:hasSkill(skill:objectName()) then
				local names = {}
				local owners = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill(skill:objectName()) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #names > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,

	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			return room:askForSkillInvoke(ctx.owner, "newluaweiwo", ctx.original_data)
		end
		return true
	end,

	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			local p = ctx.owner
			room:broadcastSkillInvoke("guanxing",2)
			p:drawCards(3)
			room:setTag("newluaweiwo", ctx.original_data)
			--将x张手牌依次置于牌堆顶
			local x = p:getHp()
			if(x > 3) then x = 3 end
			local card_ids = sgs.IntList()
			for _,cd in sgs.qlist(p:getHandcards()) do
				local id = cd:getEffectiveId()
				card_ids:append(id)
			end
			for var = 1 , x, 1 do
				room:addPlayerMark(p, "newluaweiwo")
				room:fillAG(card_ids, p)
				local cdid = room:askForAG(p, card_ids, false, skill:objectName())

				local moveA = sgs.CardsMoveStruct()
				local ln = sgs.IntList()
				ln:append(cdid)
				moveA.card_ids = ln
				moveA.to_place = sgs.Player_DrawPile
				room:moveCardsAtomic(moveA, false)

				card_ids:removeOne(cdid)
				room:clearAG(p)
			end
			room:setPlayerMark(p, "newluaweiwo", 0)
			room:removeTag("newluaweiwo")
		elseif event == sgs.EventPhaseChanging then
			room:broadcastSkillInvoke("guanxing",1)
			player:drawCards(3)
			--将x张手牌依次置于牌堆顶
			local x = player:getHp()
			if(x > 3) then x = 3 end
			local card_ids = sgs.IntList()
			for _,cd in sgs.qlist(player:getHandcards()) do
				local id = cd:getEffectiveId()
				card_ids:append(id)
			end
			for var = 1 , x, 1 do
				room:fillAG(card_ids, player)
				local cdid = room:askForAG(player, card_ids, false, skill:objectName())

				local moveA = sgs.CardsMoveStruct()
				local ln = sgs.IntList()
				ln:append(cdid)
				moveA.card_ids = ln
				moveA.to_place = sgs.Player_DrawPile
				room:moveCardsAtomic(moveA, false)

				card_ids:removeOne(cdid)
				room:clearAG(player)
			end
		end
		return false
	end
}

leo_spwolong:addSkill(newluaweiwo)
leo_spwolong:addSkill(luajincui)
leo_spwolong:addSkill(luarangxing)
leo_spwolong:addSkill(luatianming)

sgs.LoadTranslationTable{
	["leo_spwolong"]="诸葛亮",
	["newluaweiwo"] = "帷帐",	
	[":newluaweiwo"] = "你即将进行一次判定或你的回合结束时，可以摸3张牌，然后你须将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",	
	["luajincui"] = "尽瘁",
	[":luajincui"] = "锁定技，出牌阶段开始时若你的体力上限大于1，须减1点体力或体力上限令一名角色摸两张牌。",
	["luajincui1"] = "体力值",
	["luajincui2"] = "体力上限",
	["luarangxingRX"] = "星",
	["luarangxing"] = "禳星",
	[":luarangxing"] = "锁定技，每当体力值或体力上限变化时，你获得一枚“星”标记。",
	["luatianming"] = "天命",
	[":luatianming"] = "觉醒技，你濒死状态时若“星”不少于7枚，你将体力值回复至1，摸等同于“星”数量的牌并增加等量的手牌上限，然后失去“禳星”并获得“八阵”，“看破”，“集智”。",
	

--设计者(不写默认为官方)
	["designer:leo_spwolong"] = "leowebber",
	
--配音(不写默认为官方)
	["cv:leo_spwolong"] = "暂无",
	
--称号
	["#leo_spwolong"] = "秋风五丈原",
}

sgs.Sanguosha:addSkills(s_skillList)

return { extension }
