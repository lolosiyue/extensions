extension = sgs.Package("du", sgs.Package_GeneralPack)

duGanning = sgs.General(extension, "duGanning", "wu", 4)

local function jinfanPileIds(room, player, move)
	local card_ids = sgs.IntList()
	if move.to_place == sgs.Player_DiscardPile then
		local i = 0
		if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			for _, card_id in sgs.qlist(move.card_ids) do
				if
					(move.to_place == sgs.Player_DiscardPile)
					and room:getCardOwner(card_id)
					and (room:getCardOwner(card_id):objectName() == player:objectName())
					and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip)
				then
					card_ids:append(card_id)
					i = i + 1
				end
			end
		end
	end
	return card_ids
end

jinfan = sgs.CreateTriggerSkillV2 {
	name = "jinfan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.BeforeCardsMove },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local move = data:toMoveOneTime()
		if not jinfanPileIds(room, player, move):isEmpty() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local card_ids = jinfanPileIds(room, player, move)
		for _, id in sgs.qlist(card_ids) do
			if move.card_ids:contains(id) then
				move.from_places:removeAt(listIndexOf(move.card_ids, id))
				move.card_ids:removeOne(id)
				ctx.original_data:setValue(move)
				if not player:isAlive() then
					break
				end
			end
		end
		player:addToPile("du_jin", card_ids, true)
		--	room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
		return false
	end,
}

jinfanTake = sgs.CreateViewAsSkillV2 {
	name = "jinfanTake&",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_target = function(skill, request, selected, candidate)
		return candidate ~= nil and candidate:hasSkill("jinfan") and candidate:getPile("du_jin"):length() > 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected > 0
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then
			return
		end
		local room = source:getRoom()
		if not room then
			return
		end
		local jin = target:getPile("du_jin")
		if not jin:isEmpty() then
			room:fillAG(jin, source)
			local id = room:askForAG(source, jin, false, "jinfan")
			room:clearAG(source)
			local choice = room:askForChoice(target, "jinfan", "jinfanTake_allow=" .. source:objectName() .. "+jinfanTake_disallow=" .. source:objectName())
			if choice:startsWith("jinfanTake_allow") then
				local card = sgs.Sanguosha:getCard(id)
				source:obtainCard(card)
				room:showCard(source, id)
				room:broadcastSkillInvoke("jinfan")
			end
		end
	end,
}

jinfanStart = sgs.CreateTriggerSkillV2 {
	name = "#jinfanStart",
	frequency = sgs.Skill_Frequent,
	events = { sgs.GameStart, sgs.EventAcquireSkill },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toSkillChange().skillName == "jinfan") then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local lieges = room:getLieges("wu", player)
		if player:getKingdom() == "wu" then
			room:attachSkillToPlayer(player, "jinfanTake")
		end
		for _, p in sgs.qlist(lieges) do
			if not p:hasSkill("jinfanTake") then
				room:attachSkillToPlayer(p, "jinfanTake")
			end
		end
		return false
	end,
}
jinfanEnd = sgs.CreateTriggerSkillV2 {
	name = "#jinfanEnd",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death, sgs.EventLoseSkill },
	can_trigger = function(skill, event, room, player, data)
		if player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventLoseSkill then
			local name = ctx.original_data:toSkillChange().skillName
			if name == "jinfan" then
				local lieges = room:getLieges("wu", player)
				for _, p in sgs.qlist(lieges) do
					room:detachSkillFromPlayer(p, "jinfanTake")
				end
			end
		elseif event == sgs.Death then
			local death = ctx.original_data:toDeath()
			local victim = death.who
			if victim:objectName() == player:objectName() then
				local lieges = room:getLieges("wu", player)
				for _, p in sgs.qlist(lieges) do
					if p:hasSkill("jinfanTake") then
						room:detachSkillFromPlayer(p, "jinfanTake")
					end
				end
			end
		end
		return false
	end,
}

duYinlingVS = sgs.CreateViewAsSkillV2 {
	name = "duYinling",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@duYinling"
		end
		return false
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player ~= nil and candidate ~= nil and #selected < 1
			and candidate:objectName() ~= player:objectName()
			and not candidate:isKongcheng()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then
			return
		end
		local room = source:getRoom()
		if not room then
			return
		end
		local id1 = room:askForCardChosen(source, target, "h", "duYinlingCard")
		room:obtainCard(source, id1, false)
		room:setPlayerFlag(source, "duYinlingStarted")
		room:addPlayerMark(source, "&duYinling-Clear")
		room:broadcastSkillInvoke("duYinling")
	end,
}
duYinling = sgs.CreateTriggerSkillV2 {
	name = "duYinling",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = duYinlingVS,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if player:getPhase() == sgs.Player_Draw then
			local other_players = room:getOtherPlayers(player)
			for _, target in sgs.qlist(other_players) do
				if not target:isKongcheng() then
					return skill:objectName()
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("duYinlingStarted") and player:canDiscard(player, "he") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Draw then
			local used = room:askForUseCard(player, "@@duYinling", "@duYinlingCard")
			return used ~= nil
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("duYinlingStarted") and player:canDiscard(player, "he") then
				room:askForDiscard(player, "duYinling", 1, 1, false, true)
			end
		end
		return false
	end,
}

du_jieying = sgs.CreateTriggerSkillV2 {
	name = "du_jieying",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	waked_skills = "qixi",
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Start and player:getMark(skill:objectName()) < 1 and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPile("du_jin") >= 3 or player:canWake(skill:objectName()) then
			local hp = player:getHp()
			room:broadcastSkillInvoke(skill:objectName())
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 1
			theRecover.who = player
			room:recover(player, theRecover)
			room:addPlayerMark(player, skill:objectName())
			if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
				room:handleAcquireDetachSkills(player, "qixi")
			end
		end
		return false
	end,
}

test = sgs.General(extension, "test", "qun", 5, true, true, true)

duLejin = sgs.General(extension, "duLejin", "wei", 4)

duXiaoguo = sgs.CreateTriggerSkillV2 {
	name = "duXiaoguo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		local damage = data:toDamage()
		local victim = damage.to
		if victim and victim:isAlive() and victim:objectName() ~= player:objectName()
			and not victim:isKongcheng() and player:canPindian(victim) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		return player:pindian(damage.to, skill:objectName(), nil)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		damage.damage = damage.damage + 1
		local log = sgs.LogMessage()
		log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = skill:objectName()
		log.arg2 = damage.damage
		room:sendLog(log)
		ctx.original_data:setValue(damage)
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end,
}

duLejin:addSkill(duXiaoguo)

duDiaochan = sgs.General(extension, "duDiaochan", "qun", 3, false)
du_zhouxuan = sgs.CreateViewAsSkillV2 {
	name = "du_zhouxuan",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_WholeTargetGroup,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@yaochong") > 0
	end,
	can_select_card = function(skill, request, card)
		return card ~= nil and request:getSelectedCardIds():isEmpty() and not card:isEquipped()
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player ~= nil and candidate ~= nil and #selected < 2
			and (candidate:isMale() or candidate:objectName() == player:objectName())
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 2
	end,
	on_effect_target_group = function(skill, ctx, targets)
		local source = ctx.invoker or ctx.initiator
		if not source or #targets < 2 then
			return
		end
		local room = source:getRoom()
		if not room then
			return
		end
		local a = targets[1]
		local b = targets[2]
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "du_zhouxuan", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "du_zhouxuan", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove, false)
		source:loseMark("@yaochong")
	end,
}
yaochongStart = sgs.CreateTriggerSkillV2 {
	name = "#yaochongStart",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Start and player:getMark("@yaochong") == 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:gainMark("@yaochong", 1)
		return false
	end,
}
yaochong = sgs.CreateTriggerSkillV2 {
	name = "yaochong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then
			return false
		end
		local move = data:toMoveOneTime()
		if
			move.to
			and (move.to:objectName() == player:objectName())
			and move.from
			and move.from:isAlive()
			and (move.from:objectName() ~= move.to:objectName())
			and (move.card_ids:length() >= 2)
			and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
			and move.from:isMale()
		then
			return skill:objectName()
		end
		if
			move.to
			and move.from
			and (move.from:objectName() == player:objectName())
			and move.to:isAlive()
			and (move.from:objectName() ~= move.to:objectName())
			and (move.card_ids:length() >= 2)
			and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
			and move.to:isMale()
		then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		if
			move.to
			and (move.to:objectName() == player:objectName())
			and move.from
			and move.from:isAlive()
			and (move.from:objectName() ~= move.to:objectName())
			and (move.card_ids:length() >= 2)
			and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
		then
			local _movefrom
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if move.from:objectName() == p:objectName() then
					_movefrom = p
					break
				end
			end
			if _movefrom:isMale() then
				player:gainMark("@yaochong", 1)
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		if
			move.to
			and move.from
			and (move.from:objectName() == player:objectName())
			and move.to
			and move.to:isAlive()
			and (move.from:objectName() ~= move.to:objectName())
			and (move.card_ids:length() >= 2)
			and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
		then
			local _moveto
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if move.to:objectName() == p:objectName() then
					_moveto = p
					break
				end
			end
			if _moveto:isMale() then
				player:loseMark("@yaochong", 1)
			end
		end
		return false
	end,
}

duGuanyu = sgs.General(extension, "duGuanyu", "shu", 4)

duWuhun = sgs.CreateTriggerSkillV2 {

	name = "duWuhun",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Wake,
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Start and player:getMark(skill:objectName()) < 1 and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:canWake(skill:objectName()) then
			player:addMark("Blade", 1)
			player:addMark("ChiTu", 1)
		end
		local weapon = player:getWeapon()
		if weapon then
			if weapon:isKindOf("Blade") and player:getMark("Blade") == 0 and player:getMark("BladeUsed") == 0 then
				player:addMark("Blade", 1)
			end
		end
		local horse = player:getOffensiveHorse()
		if horse then
			local horseName = horse:objectName()
			if horseName == "chitu" and player:getMark("ChiTu") == 0 then
				player:addMark("ChiTu", 1)
			end
		end


		if player:getMark("Blade") == 1 and player:getMark("BladeUsed") == 0 then
			room:setPlayerMark(player, "Blade", 0)
			room:addPlayerMark(player, "BladeUsed")
			room:handleAcquireDetachSkills(player, "huxiao")
			room:addPlayerMark(player, "&huxiao")
		end
		if player:getMark("ChiTu") == 1 and player:getMark("ChiTuUsed") == 0 then
			room:setPlayerMark(player, "ChiTu", 0)
			room:addPlayerMark(player, "ChiTuUsed")
			room:addPlayerMark(player, "&chitu")
			room:handleAcquireDetachSkills(player, "mashu")
		end
		if player:getMark("BladeUsed") == 1 and player:getMark("ChiTuUsed") == 1 then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:changeMaxHpForAwakenSkill(player, -1, skill:objectName())
			room:addPlayerMark(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
		end
		return false
	end,
}
duoDaoAndMa = sgs.CreateTriggerSkillV2 {
	name = "#duoDaoAndMa",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Start and (player:getMark("BladeUsed") == 0 or player:getMark("ChiTuUsed") == 0) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local others = room:getOtherPlayers(player)
		local ids = sgs.IntList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			for _, card in sgs.qlist(p:getCards("ej")) do
				if card:isKindOf("Blade") or card:objectName() == "chitu" then
					ids:append(card:getId())
				end
			end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Blade") then
				ids:append(id)
				break
			end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):objectName() == "chitu" then
				ids:append(id)
				break
			end
		end
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Blade") then
				ids:append(id)
				break
			end
		end
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):objectName() == "chitu" then
				ids:append(id)
				break
			end
		end
		room:fillAG(ids)
		if not ids:isEmpty() then
			-- local id = room:askForAG(player, ids, false, skill:objectName())
			local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(ids) do
				to_handcard_x:addSubcard(id)
			end
			player:obtainCard(to_handcard_x)
			to_handcard_x:deleteLater()
		end
		room:clearAG()
		return false
	end,
}

duCaocao = sgs.General(extension, "duCaocao$", "wei", 4)

jieyou = sgs.CreateViewAsSkillV2 {

	name = "jieyou",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_NoTarget,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		if player == nil then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			newanal:deleteLater()
			if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then
				return false
			end
			return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern() or "", "analeptic") ~= nil
		end
		return false
	end,

	can_select_card = function(skill, request, card)
		return card ~= nil
			and request:getSelectedCardIds():isEmpty()
			and card:getSuit() == sgs.Card_Spade
			and card:getNumber() > 1
			and card:getNumber() < 10
	end,

	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 1 then
			local card = sgs.Sanguosha:getCard(ids:first())
			local jiu = sgs.Sanguosha:cloneCard("Analeptic", card:getSuit(), card:getNumber())
			jiu:addSubcard(card:getId())
			jiu:setSkillName(skill:objectName())
			return jiu
		end
	end,
}

jiuwei = sgs.CreateTriggerSkillV2 {

	name = "jiuwei",
	events = { sgs.CardOffset },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local effect = data:toCardEffect()
		local killer = effect.from
		if killer and killer:objectName() == player:objectName() and effect.card and effect.card:isKindOf("Slash") and (effect.card:hasFlag("drank")) then
			local target = effect.to
			if not target:isNude() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		local target = effect.to
		room:broadcastSkillInvoke(skill:objectName())
		room:setPlayerFlag(target, "jiuwei_target")
		local choice = room:askForChoice(player, skill:objectName(), "jwTake=" .. target:objectName() .. "+jwDrop=" .. target:objectName())
		if choice:startsWith("jwTake") then
			local card_id = room:askForCardChosen(player, target, "he", skill:objectName())
			room:obtainCard(player, card_id)
		else
			if player:canDiscard(target, "he") then
				local card_id1 = room:askForCardChosen(player, target, "he", skill:objectName())
				room:throwCard(card_id1, target, player)
				if player:canDiscard(target, "he") then
					local card_id2 = room:askForCardChosen(player, target, "he", skill:objectName())
					room:throwCard(card_id2, target, player)
				end
			end
		end
		room:setPlayerFlag(target, "-jiuwei_target")
		return false
	end,
}
du_tongque = sgs.CreateTriggerSkillV2 {

	name = "du_tongque$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForPeachesDone },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isFemale() and player:getHp() <= 0 and player:getMark("du_tongque") == 0) then
			return false
		end
		local dying = data:toDying()
		if not dying.damage then
			return false
		end
		local killer = dying.damage.from
		local victim = dying.damage.to
		if not killer then
			return false
		end
		local kingdom = killer:getKingdom()
		if not (kingdom == "wei" and victim:isFemale()) then
			return false
		end
		local trigger_list_skill = {}
		local trigger_list_who = {}
		local list = room:getOtherPlayers(player)
		for _, lord in sgs.qlist(list) do
			if lord:hasLordSkill(skill:objectName()) and not lord:isKongcheng() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, lord:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local lord = player
		local dying = ctx.original_data:toDying()
		local victim = dying.damage.to
		local prompt = string.format("#caocao_tongque:%s", victim:objectName())
		local card = room:askForCard(lord, ".!", prompt, ctx.original_data, sgs.AskForPeachesDone)
		if card then
			victim:obtainCard(card)
			room:broadcastSkillInvoke(skill:objectName())
			local hp = victim:getHp()
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 1 - hp
			theRecover.who = victim
			room:recover(victim, theRecover)
			room:loseMaxHp(victim)
			room:drawCards(victim, 3, skill:objectName())
			room:setPlayerProperty(victim, "kingdom", sgs.QVariant("wei"))
			room:setPlayerProperty(victim, "role", sgs.QVariant("renegade"))
			local msg = sgs.LogMessage()
			msg.type = "#du_tongque1"
			msg.from = lord
			msg.to:append(victim)
			room:sendLog(msg)
			victim:gainMark("du_tongque")
		end
		return false
	end,
}

duDongzhuo = sgs.General(extension, "duDongzhuo$", "qun", 4)

du_xixing = sgs.CreateTriggerSkillV2 {

	name = "du_xixing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local damage = data:toDamage()
		if damage.from == nil then
			return false
		end
		if damage.from:isNude() then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local dest = sgs.QVariant()
		dest:setValue(damage.from)
		return room:askForSkillInvoke(player, "du_xixing", dest)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		player:obtainCard(damage.from:wholeHandCards(), false)
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end,
}

du_jiyu = sgs.CreateTriggerSkillV2 {

	name = "du_jiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Start and player:getHandcardNum() > player:getMaxHp() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:loseMaxHp(player)
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end,
}

duBaonue = sgs.CreateTriggerSkillV2 {
	name = "duBaonue$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage, sgs.DamageDone },
	global = true,
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.DamageDone then
			local damage = ctx.original_data:toDamage()
			if damage.from then
				damage.from:setTag("InvokeBaonue", sgs.QVariant(damage.from:getKingdom() == "qun"))
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damage or not (player and player:getTag("InvokeBaonue"):toBool() and player:isAlive()) then
			return false
		end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasLordSkill(skill:objectName()) then
				return skill:objectName(), p
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local dealer = ctx.invoker
		if not dealer then
			return false
		end
		local dongzhuos = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(dealer)) do
			if p:hasLordSkill(skill:objectName()) then
				dongzhuos:append(p)
			end
		end
		while not dongzhuos:isEmpty() do
			local dongzhuo = room:askForPlayerChosen(dealer, dongzhuos, skill:objectName(), "@baonue-to", true)
			if dongzhuo then
				dongzhuos:removeOne(dongzhuo)
				local log = sgs.LogMessage()
				log.type = "#InvokeOthersSkill"
				log.from = dealer
				log.to:append(dongzhuo)
				log.arg = skill:objectName()
				room:sendLog(log)
				room:notifySkillInvoked(dongzhuo, skill:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = true
				judge.reason = skill:objectName()
				judge.who = dealer
				room:judge(judge)
				room:broadcastSkillInvoke(skill:objectName())
				if judge:isGood() then
					room:setPlayerProperty(dongzhuo, "maxhp", sgs.QVariant(dongzhuo:getMaxHp() + 1))
					local msg = sgs.LogMessage()
					msg.type = "#baonueMessage"
					msg.from = dongzhuo
					msg.arg = 1
					room:sendLog(msg)
				end
			else
				break
			end
		end
		return false
	end,
}

duSunjian = sgs.General(extension, "duSunjian", "wu", 4)

tongpaodestCard = sgs.CreateSkillCard {
	name = "tongpaodestCard",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		local aocaistring = self:getUserString()
		if aocaistring == "" then
			aocaistring = "slash"
		end
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		local aocaistring = self:getUserString()
		if aocaistring == "" then
			aocaistring = "slash"
		end
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, from)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		if aocaistring == "" then
			aocaistring = "slash"
		end
		local prompt = string.format("@@tongpao:%s", aocaistring)
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card
		local lieges = room:getLieges("wu", user)
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = user
		room:sendLog(log)
		for _, p in sgs.qlist(lieges) do
			room:setPlayerFlag(p, "Global_tongpaoUsing")
			card = room:askForCard(p, aocaistring, prompt, dt, sgs.Card_MethodResponse, p)
			room:setPlayerFlag(p, "-Global_tongpaoUsing")
			if card then
				break
			end
		end
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_tongpaoFailed")
		return nil
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		if aocaistring == "" then
			aocaistring = "slash"
		end
		local prompt = string.format("@@tongpao:%s", aocaistring)
		local dt = sgs.QVariant()
		dt:setValue(user)
		local lieges = room:getLieges("wu", user)
		local card
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = user
		room:sendLog(log)
		for _, p in sgs.qlist(lieges) do
			room:setPlayerFlag(p, "Global_tongpaoUsing")
			card = room:askForCard(p, aocaistring, prompt, dt, sgs.Card_MethodResponse, p)
			room:setPlayerFlag(p, "-Global_tongpaoUsing")
			if card then
				break
			end
		end
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_tongpaoFailed")
		return nil
	end,
}
tongpaodest = sgs.CreateZeroCardViewAsSkill {
	name = "tongpaodest&",
	enabled_at_play = function(self, player)
		if player:hasFlag("Global_tongpaoFailed") then
			return false
		end
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("Global_tongpaoFailed") then
			return
		end
		if player:hasFlag("Global_tongpaoUsing") then
			return
		end
		if pattern == "slash" or pattern == "jink" then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = tongpaodestCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		acard:setUserString(pattern)
		return acard
	end,
}

tongpao = sgs.CreateTriggerSkillV2 {
	name = "tongpao",
	events = { sgs.GameStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local players = room:getAlivePlayers()
		for _, p in sgs.qlist(players) do
			if p:getKingdom() == "wu" then
				room:attachSkillToPlayer(p, "tongpaodest")
			end
		end
		return false
	end,
}

tongpaoSlash = sgs.CreateTriggerSkillV2 {
	name = "#tongpaoSlash",
	events = { sgs.CardAsked },
	can_trigger = function(skill, event, room, player, data)
		if not (player ~= nil and player:getKingdom() == "wu") then
			return false
		end
		local pattern = data:toStringList()[1]
		if pattern ~= "slash" then
			return false
		end
		if string.startsWith(data:toStringList()[2], "@tongpao") or string.startsWith(data:toStringList()[2], "@@tongpao") then
			return false
		end
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			return skill:objectName(), p
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then
			return false
		end
		return target:askForSkillInvoke("tongpao_slash", ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then
			return false
		end
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = target
		room:sendLog(log)
		local dest = sgs.QVariant()
		dest:setValue(target)
		local lieges = room:getLieges("wu", target)
		for _, p in sgs.qlist(lieges) do
			local slash = room:askForCard(p, "slash", "@tongpao-slash:" .. target:objectName(), dest, sgs.Card_MethodResponse, nil, false, "", true)
			if slash then
				room:setPlayerFlag(target, "-tongpao_target")
				room:broadcastSkillInvoke("tongpao")
				room:provide(slash)
				return true
			end
		end
		return false
	end,
}
tongpaoJink = sgs.CreateTriggerSkillV2 {
	name = "#tongpaoJink",
	events = { sgs.CardAsked },
	can_trigger = function(skill, event, room, player, data)
		if not (player ~= nil and player:getKingdom() == "wu" and player:isAlive()) then
			return false
		end
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then
			return false
		end
		if string.startsWith(data:toStringList()[2], "@tongpao") or string.startsWith(data:toStringList()[2], "@@tongpao") then
			return false
		end
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			return skill:objectName(), p
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then
			return false
		end
		return target:askForSkillInvoke("tongpao_jink", ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then
			return false
		end
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = target
		room:sendLog(log)
		local lieges = room:getLieges("wu", target)
		local dest = sgs.QVariant()
		dest:setValue(target)
		for _, p in sgs.qlist(lieges) do
			local jink = room:askForCard(p, "jink", "@tongpao-jink:" .. target:objectName(), dest, sgs.Card_MethodResponse, nil, false, "", true)
			if jink then
				room:broadcastSkillInvoke("tongpao")
				room:provide(jink)
				return true
			end
		end
		return false
	end,
}

duGuanyu:addSkill("wusheng")
duGuanyu:addSkill(duoDaoAndMa)
duGuanyu:addSkill(duWuhun)
duGuanyu:addRelateSkill("huxiao")
duGuanyu:addRelateSkill("mashu")
extension:insertRelatedSkills("duWuhun", "#duoDaoAndMa")
duCaocao:addSkill(jieyou)
duCaocao:addSkill(jiuwei)
duCaocao:addSkill(du_tongque)
duDongzhuo:addSkill(du_xixing)
duDongzhuo:addSkill(du_jiyu)
duDongzhuo:addSkill(duBaonue)
duDiaochan:addSkill(du_zhouxuan)
duDiaochan:addSkill(yaochongStart)
duDiaochan:addSkill(yaochong)
extension:insertRelatedSkills("yaochong", "#yaochongStart")
duSunjian:addSkill(tongpao)
duSunjian:addSkill(tongpaoJink)
duSunjian:addSkill(tongpaoSlash)
extension:insertRelatedSkills("tongpao", "#tongpaoJink")
extension:insertRelatedSkills("tongpao", "#tongpaoSlash")
duSunjian:addSkill("yinghun")
duGanning:addSkill(jinfan)
duGanning:addSkill(duYinling)
duGanning:addSkill(jinfanStart)
duGanning:addSkill(jinfanEnd)
extension:insertRelatedSkills("jinfan", "#jinfanStart")
extension:insertRelatedSkills("jinfan", "#jinfanEnd")
duGanning:addSkill(du_jieying)

test:addSkill(jinfanTake)
addToSkills(tongpaodest)

sgs.LoadTranslationTable {

	["du"] = "独包",
	["duGuanyu"] = "关羽",
	["~duGuanyu"] = "汉室未兴，死而有憾~",
	["duCaocao"] = "曹操",
	["~duCaocao"] = "霸业未成，未成啊...",
	["duDongzhuo"] = "董卓",
	["~duDongzhuo"] = "竖子，竟敢反我！",
	["duDiaochan"] = "貂蝉",
	["~duDiaochan"] = "红颜多薄命，几人能白头！",
	["duSunjian"] = "孙坚",
	["~duSunjian"] = "上天的眷顾，真的只是幻觉吗？",
	["duLejin"] = "乐进",
	["~duLejin"] = "不能再为主公杀敌了...",
	["duGanning"] = "甘宁",
	["~duGanning"] = "银铃将息，锦帆何去...",

	["#zunhui"] = "%from 触发【%arg2】， %to 使用的杀【%arg】对其无效",

	["du_jieying"] = "劫营",
	[":du_jieying"] = '<font color="purple"><b>觉醒技，</b></font>准备阶段开始时，若你的“锦”大于或等于三张，你回复1点体力，然后失去1点体力上限，并获得“奇袭”。',
	["$du_jieying1"] = "奋威齐进，呼声动天！",
	["$du_jieying2"] = "奇兵奋勇，以威天下！",

	["duYinling"] = "银铃",
	["duyinling"] = "银铃",
	["duYinlingCard"] = "银铃",
	[":duYinling"] = "摸牌阶段开始时，你可以获得一名其他角色的一张手牌。若如此做，弃牌阶段结束后，你需要弃置一张牌。",
	["@duYinlingCard"] = "是否发动技能【银铃】",
	["~duYinling"] = "请选择一名角色,然后点击确定",
	["$duYinling1"] = "再回去练上几年吧！",
	["$duYinling2"] = "疆场杀敌，勇者先胜三分。",

	["jfTakeCard"] = "锦帆",
	["jinfanTake"] = "锦帆",
	[":jinfanTake"] = "出牌阶段限一次，你可以选择一张“锦”，甘宁可以将之交给你。",
	["jinfan"] = "锦帆",
	["jftake"] = "锦帆",
	[":jinfan"] = "当你的牌因弃置进入弃牌堆时，你可以将其置于武将牌上，称为“锦”。吴势力角色的出牌阶段限一次，其可选择一张“锦”，你可以将之交给其。",
	["du_jin"] = "锦",
	["jinfanTake_allow"] = "你可以将之交给 %src",
	["jinfanTake_disallow"] = "拒绝将之交给 %src",
	["$jinfan1"] = "这里是我们的地盘！",
	["$jinfan2"] = "锦帆游侠的名号，岂是白叫的？",

	["duXiaoguo"] = "骁果",
	[":duXiaoguo"] = "当你对一名其他角色造成伤害时，你可以与其拼点，若你赢，则伤害+1。",
	["$duXiaoguo1"] = "当敌制决，靡有遗失。",
	["$duXiaoguo2"] = "奋强突固，无坚不可陷。",

	["tongpao"] = "同袍",
	[":tongpao"] = "当吴势力角色需要使用或打出【杀】或【闪】时，其他吴势力角色可以代为使用或打出【杀】或【闪】",
	["tongpaodest"] = "同袍",
	[":tongpaodest"] = "当你需要使用或打出【杀】或【闪】时，其他吴势力角色可以代为使用或打出【杀】或【闪】。",
	["tongpao_jink"] = "【同胞】，请吴势力角色代你出【闪】",
	["tongpao_slash"] = "【同胞】，请吴势力角色代你出【杀】",
	["@tongpao-jink"] = "【同胞】技能被触发，请吴势力角色代 %src 出【闪】",
	["@tongpao-slash"] = "【同胞】技能被触发，请吴势力角色代 %src 出【杀】",
	["#tongpao"] = "%from 请吴国势力代为打出【杀】或【闪】",
	["@@tongpao"] = "是否发动同袍使用或打出一张 %src",
	["$tongpao1"] = "义兵再起，暴乱必除。",
	["$tongpao2"] = "举贤荐能，以保江东。",

	["du_zhouxuan"] = "周旋",
	[":du_zhouxuan"] = "出牌阶段，若你拥有“宠”标记，你可以弃一张手牌，与一名男性角色交换其余手牌，或交换两名男性角色的手牌。若如此做，你失去一枚“宠”标记。",
	["$du_zhouxuan1"] = "都是他的错！",
	["$du_zhouxuan2"] = "妾身，向来仰慕勇武强者。",

	["du_zhouxuanCard"] = "周旋",
	["yaochong"] = "邀宠",
	[":yaochong"] = "每当从男性角色获得两张或以上手牌，你获得一枚“宠”标记；每当男性角色获得你的两张或以上手牌，你失去一枚“宠”标记。回合开始时，若你没有“宠”标记，你获得一枚“宠”标记。",
	["@yaochong"] = "邀宠",
	["$yaochong1"] = "得君垂怜，妾身足矣。",
	["$yaochong2"] = "将军~你的眼睛在往哪儿看呐。",

	["duWuhun"] = "武魂",
	[":duWuhun"] = "回合开始时，你获得场上、牌堆或弃牌堆里的一张【青龙偃月刀】或【赤兔马】。觉醒技，回合开始时，若你已经装备【青龙偃月刀】则获得“虎啸”，若已装备【赤兔马】则获得“马术”。获得上述两技能后，你回复一点体力，然后失去一点体力上限，并“武魂”改为失效。。",
	["$duWuhun1"] = "忠心赤胆，青龙啸天！",
	["$duWuhun2"] = "撒满腔热血，扫天下汉贼！",

	["jieyou"] = "解忧",
	[":jieyou"] = "你可以将一张♠2~9手牌当【酒】使用。",
	["$jieyou1"] = "山不厌高，海不厌深。",
	["$jieyou2"] = "周公吐哺，天下归心。",

	["du_tongque"] = "铜雀",
	[":du_tongque"] = '<font color="orange"><b>主公技，</b></font>当魏势力角色导致女性角色濒死并求桃失败后，你可以将一张手牌交给其，令其复活。该角色摸三张牌，恢复1点体力，失去1点体力上限，将势力改为魏，并改变身份为“内奸”。',
	["#du_tongque1"] = "%to 被收入 %from 的铜雀台，势力变为魏，身为变为内奸",
	["#tongque2"] = "%from 被收入 %to 的铜雀台",
	["#caocao_tongque"] = "请选择一张手牌给 %src",
	["$du_tongque"] = "扫清六合，席卷八荒！",

	["jiuwei"] = "酒威",
	[":jiuwei"] = "你使用的受【酒】影响的【杀】被目标角色的【闪】抵消后，你可以获得其一张牌或弃置其两张牌。",
	["jwTake"] = "获得 %src 一张牌",
	["jwDrop"] = "弃置 %src 两张牌",
	["$jiuwei1"] = "孤，好梦中杀人！",
	["$jiuwei2"] = "宁教我负天下人，休教天下人负我！",

	["du_xixing"] = "庸纳",
	[":du_xixing"] = "每当你受到伤害后，你可以获得伤害来源的全部手牌。",
	["$du_xixing1"] = "敲骨吸髓，不亦乐乎。",
	["$du_xixing2"] = "强取豪夺，乃真豪杰。",

	["du_jiyu"] = "积郁",
	[":du_jiyu"] = "回合开始阶段，若你的手牌数量大于手牌上限，你失去一点体力上限。",
	["$du_jiyu1"] = "我还要更多，更多！",
	["$du_jiyu2"] = "酒池肉林，其乐无穷，哈哈哈",

	["duBaonue"] = "暴虐",
	[":duBaonue"] = '<font color="orange"><b>主公技，</b></font>当其他群势力角色造成伤害后，其可以进行判定，若结果为♠，你增加1点体力上限。',
	["#baonueMessage"] = "%from 增加 %arg 点体力上限",
	["$duBaonue1"] = "哈哈哈哈，不愧是我的好部下。",
	["$duBaonue2"] = "杀得好，大大有赏！",

	["~tmp"] = "一二三",
	["$duWusheng"] = "四五六",
	["$jiushen_tril"] = "酒神现世",
	["$jiushen2_tril"] = "酒神现世",
	["$juli_tril"] = "汇天地之灵气",
	["$gudan_tril"] = "孤胆英雄",
	["$du_xixing_tril"] = "孤胆英雄",
	["$jiyu_tril"] = "孤胆英雄",
	["$jiuwei_tril"] = "孤胆英雄",
	["$duHujia_tril"] = "孤胆英雄",
	["$jiuse_tril"] = "孤胆英雄",
	["$duWuhun_tril"] = "孤胆英雄",
	["$jieyou_tril"] = "孤胆英雄",
	["$ZhuishaSkill_tril"] = "孤胆英雄",
	["$ziyan_tril"] = "孤胆英雄",
	["$tongque_tril"] = "孤胆英雄",
	["$jiusha_tril"] = "一二三四",
	["$zhouxuan_tril"] = "一二三四",

	["#tmp"] = "仅供测试",
	["designer:tmp"] = "222",
	["cv:tmp"] = "官方",
	["illustratr:tmp"] = "222",
}

return { extension }
