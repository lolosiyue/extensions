extension = sgs.Package("du", sgs.Package_GeneralPack)

duGanning = sgs.General(extension, "duGanning", "wu", 4)

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
jinfan = sgs.CreateTriggerSkill {
	name = "jinfan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local card_ids = sgs.IntList()
		if (move.to_place == sgs.Player_DiscardPile) then
			local i = 0
			if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
					sgs.CardMoveReason_S_REASON_DISCARD) then
				for _, card_id in sgs.qlist(move.card_ids) do
					if (move.to_place == sgs.Player_DiscardPile) and room:getCardOwner(card_id) and
						(room:getCardOwner(card_id):objectName() == player:objectName()) and
						(move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) ==
							sgs.Player_PlaceEquip) then
						card_ids:append(card_id)
						i = i + 1
					end
				end
			end
		end
		if not card_ids:isEmpty() and room:askForSkillInvoke(player, self:objectName()) then
			for _, id in sgs.qlist(card_ids) do
				if move.card_ids:contains(id) then
					move.from_places:removeAt(listIndexOf(move.card_ids, id))
					move.card_ids:removeOne(id)
					data:setValue(move)
					if not player:isAlive() then
						break
					end
				end
			end
			player:addToPile("du_jin", card_ids, true)
			--	room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
		end
		return false
	end
}

jfTakeCard = sgs.CreateSkillCard {
	name = "jfTakeCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:hasSkill("jinfan") and to_select:getPile("du_jin"):length() > 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local jin = target:getPile("du_jin")
		if not jin:isEmpty() then
			room:fillAG(jin, source)
			local id = room:askForAG(source, jin, false, "jinfan")
			room:clearAG(source)
			local choice = room:askForChoice(target, "jinfan", "jinfanTake_allow=" .. source:objectName() ..
				"+jinfanTake_disallow=" .. source:objectName())
			if choice:startsWith("jinfanTake_allow") then
				local card = sgs.Sanguosha:getCard(id)
				source:obtainCard(card)
				room:showCard(source, id)
				room:broadcastSkillInvoke("jinfan")
			end
		end
	end
}

jinfanTake = sgs.CreateViewAsSkill {
	name = "jinfanTake&",
	n = 0,
	view_as = function(self, card)
		local card = jfTakeCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jfTakeCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

jinfanStart = sgs.CreateTriggerSkill {
	name = "#jinfanStart",
	frequency = sgs.Skill_Frequent,
	events = { sgs.GameStart, sgs.EventAcquireSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.GameStart) or (event == sgs.EventAcquireSkill and data:toString() == "jinfan") then
			local lieges = room:getLieges("wu", player)
			if player:getKingdom() == "wu" then
				room:attachSkillToPlayer(player, "jinfanTake")
			end
			for _, p in sgs.qlist(lieges) do
				if not p:hasSkill("jinfanTake") then
					room:attachSkillToPlayer(p, "jinfanTake")
				end
			end
		end
	end
}
jinfanEnd = sgs.CreateTriggerSkill {
	name = "#jinfanEnd",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill then
			local name = data:toString()
			if name == "jinfan" then
				local lieges = room:getLieges("wu", player)
				for _, p in sgs.qlist(lieges) do
					room:detachSkillFromPlayer(p, "jinfanTake")
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
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
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

duYinlingCard = sgs.CreateSkillCard {
	name = "duYinlingCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() then
			return #targets < 1
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,

	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		local id1 = room:askForCardChosen(source, target, "h", self:objectName())
		--[[move1.card_ids:append(id1)
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		room:moveCards(moves, false)]]
		room:obtainCard(source, id1, false)
		room:setPlayerFlag(source, "duYinlingStarted")
		room:addPlayerMark(source, "&duYinling-Clear")
		room:broadcastSkillInvoke("duYinling")
	end
}
duYinlingVS = sgs.CreateViewAsSkill {
	name = "duYinling",
	n = 0,
	view_as = function(self, cards)
		return duYinlingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@duYinling"
	end
}
duYinling = sgs.CreateTriggerSkill {
	name = "duYinling",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = duYinlingVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, target in sgs.qlist(other_players) do
				if not target:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				if room:askForUseCard(player, "@@duYinling", "@duYinlingCard") then
					return false
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if player:hasFlag("duYinlingStarted") then
				if player:canDiscard(player, "he") then
					room:askForDiscard(player, "duYinling", 1, 1, false, true)
				end
			end
		end

		return false
	end
}

du_jieying = sgs.CreateTriggerSkill {
	name = "du_jieying",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hp = player:getHp()
		room:broadcastSkillInvoke(self:objectName())
		local theRecover = sgs.RecoverStruct()
		theRecover.recover = 1
		theRecover.who = player
		room:recover(player, theRecover)
		room:addPlayerMark(player, self:objectName())
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			room:handleAcquireDetachSkills(player, "qixi")
		end
	end,
	waked_skills = "qixi",
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		local jin = player:getPile("du_jin")
		if jin:length() >= 3 then
			return true
		end
		return false
	end

}

test = sgs.General(extension, "test", 'qun', 5, true, true, true)

duLejin = sgs.General(extension, "duLejin", "wei", 4)

duXiaoguo = sgs.CreateTriggerSkill {
	name = "duXiaoguo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local victim = damage.to

		if victim and victim:isAlive() then
			if victim:objectName() ~= player:objectName() then
				if not victim:isKongcheng() and player:canPindian(victim) then
					-- if not damage.transfer then
					-- victim:gainMark("victim")
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local success = player:pindian(victim, self:objectName(), nil)
						if success then
							damage.damage = damage.damage + 1
							local log = sgs.LogMessage()
							log.type = "#skill_add_damage"
							log.from = damage.from
							log.to:append(damage.to)
							log.arg = self:objectName()
							log.arg2 = damage.damage
							room:sendLog(log)
							data:setValue(damage)
							room:broadcastSkillInvoke(self:objectName())
						end
					end
					-- end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end

}

duLejin:addSkill(duXiaoguo)

duDiaochan = sgs.General(extension, "duDiaochan", "qun", 3, false)
du_zhouxuanCard = sgs.CreateSkillCard {
	name = "du_zhouxuanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:isMale() or to_select:objectName() == sgs.Self:objectName() then
			return #targets < 2
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		--[[local playerA = targets[1]
		local playerB = targets[2]
		local countA = playerA:getHandcardNum()
		local countB = playerB:getHandcardNum()
		local moveA = sgs.CardsMoveStruct()
		moveA.card_ids = playerA:handCards()
		moveA.to = playerB
		moveA.to_place = sgs.Player_PlaceHand
		local moveB = sgs.CardsMoveStruct()
		moveB.card_ids = playerB:handCards()
		moveB.to = playerA
		moveB.to_place = sgs.Player_PlaceHand
		room:moveCards(moveA, false)
		room:moveCards(moveB, false)]]
		local a = targets[1]
		local b = targets[2]
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(
			sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "du_zhouxuan", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(
			sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "du_zhouxuan", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove, false);
		source:loseMark("@yaochong")
	end

}
du_zhouxuan = sgs.CreateViewAsSkill {
	name = "du_zhouxuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = du_zhouxuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yaochong") > 0
	end

}
yaochongStart = sgs.CreateTriggerSkill {
	name = "#yaochongStart",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start and player:getMark("@yaochong") == 0 then
			player:gainMark("@yaochong", 1)
		end
	end
}
yaochong = sgs.CreateTriggerSkill {
	name = "yaochong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive() and
				(move.from:objectName() ~= move.to:objectName()) and (move.card_ids:length() >= 2) and
				(move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				local _movefrom
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if move.from:objectName() == p:objectName() then
						_movefrom = p
						break
					end
				end
				if _movefrom:isMale() then
					player:gainMark("@yaochong", 1)
					room:broadcastSkillInvoke(self:objectName())
				end
			end
			if move.to and move.from and (move.from:objectName() == player:objectName()) and move.to and
				move.to:isAlive() and (move.from:objectName() ~= move.to:objectName()) and (move.card_ids:length() >= 2) and
				(move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
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
		end
		return false
	end
}

duGuanyu = sgs.General(extension, "duGuanyu", "shu", 4)

duWuhun = sgs.CreateTriggerSkill {

	name = "duWuhun",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

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
			room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
			room:addPlayerMark(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
		end
	end,

	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			player:addMark("Blade", 1)
			player:addMark("ChiTu", 1)
			return true
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

		if player:getMark("ChiTu") == 1 and player:getMark("ChiTuUsed") == 0 then
			return true
		end
		if player:getMark("Blade") == 1 and player:getMark("BladeUsed") == 0 then
			return true
		end

		return false
	end

}
duoDaoAndMa = sgs.CreateTriggerSkill {
	name = "#duoDaoAndMa",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start and
			(player:getMark("BladeUsed") == 0 or player:getMark("ChiTuUsed") == 0) then
			local room = player:getRoom()
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
				-- local id = room:askForAG(player, ids, false, self:objectName())
				local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(ids) do
					to_handcard_x:addSubcard(id)
				end
				player:obtainCard(to_handcard_x)
				to_handcard_x:deleteLater()
			end
			room:clearAG()
		end
		return false
	end
}

duCaocao = sgs.General(extension, "duCaocao$", "wei", 4)

jieyou = sgs.CreateViewAsSkill {

	name = "jieyou",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and to_select:getNumber() > 1 and to_select:getNumber() < 10
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local jiu = sgs.Sanguosha:cloneCard("Analeptic", card:getSuit(), card:getNumber())
			jiu:addSubcard(card:getId())
			jiu:setSkillName(self:objectName())
			return jiu
		end
	end,

	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		newanal:deleteLater()
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then
			return false
		end
		return player:usedTimes("Analeptic") <=
			sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
	end,

	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}

jiuwei = sgs.CreateTriggerSkill {

	name = "jiuwei",
	events = { sgs.CardOffset },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local killer = effect.from
		if killer:objectName() == player:objectName() and effect.card
			and effect.card:isKindOf("Slash") and (effect.card:hasFlag("drank")) then
			local target = effect.to
			if not target:isNude() then
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerFlag(target, "jiuwei_target")
					local choice = room:askForChoice(player, self:objectName(), "jwTake=" .. target:objectName() ..
						"+jwDrop=" .. target:objectName())
					if choice:startsWith("jwTake") then
						local card_id = room:askForCardChosen(player, target, "he", self:objectName())
						room:obtainCard(player, card_id)
					else
						if player:canDiscard(target, "he") then
							local card_id1 = room:askForCardChosen(player, target, "he", self:objectName())
							room:throwCard(card_id1, target, player)
							if player:canDiscard(target, "he") then
								local card_id2 = room:askForCardChosen(player, target, "he", self:objectName())
								room:throwCard(card_id2, target, player)
							end
						end
					end
					room:setPlayerFlag(target, "-jiuwei_target")
				end
			end
		end
	end
}
du_tongque = sgs.CreateTriggerSkill {

	name = "du_tongque$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForPeachesDone },
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()

		if dying.damage then
			local killer = dying.damage.from
			local victim = dying.damage.to
			local kingdom = killer:getKingdom()

			if kingdom == "wei" and victim:isFemale() then
				local room = player:getRoom()
				local list = room:getOtherPlayers(player)
				for _, lord in sgs.qlist(list) do
					if lord:hasLordSkill(self:objectName()) and not lord:isKongcheng() then
						if room:askForSkillInvoke(lord, self:objectName(), data) then
							local prompt = string.format("#caocao_tongque:%s", victim:objectName())
							local card = room:askForCard(lord, ".!", prompt, data, sgs.AskForPeachesDone)
							if card then
								victim:obtainCard(card)
								room:broadcastSkillInvoke(self:objectName())
								local hp = victim:getHp()
								local theRecover = sgs.RecoverStruct()
								theRecover.recover = 1 - hp
								theRecover.who = victim
								room:recover(victim, theRecover)
								room:loseMaxHp(victim)
								room:drawCards(victim, 3, self:objectName())
								room:setPlayerProperty(victim, "kingdom", sgs.QVariant("wei"))
								room:setPlayerProperty(victim, "role", sgs.QVariant("renegade"))
								local msg = sgs.LogMessage()
								msg.type = "#du_tongque1"
								msg.from = lord
								msg.to:append(victim)
								room:sendLog(msg)
								victim:gainMark("du_tongque")
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target:isFemale() and target:getHp() <= 0 and target:getMark("du_tongque") == 0 then
			return true
		end
	end
}

duDongzhuo = sgs.General(extension, "duDongzhuo$", "qun", 4)

xixing = sgs.CreateTriggerSkill {

	name = "xixing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from == nil then
			return
		end
		if damage.from:isNude() then
			return
		end
		local dest = sgs.QVariant()
		dest:setValue(damage.from)
		if room:askForSkillInvoke(player, "xixing", dest) then
			player:obtainCard(damage.from:wholeHandCards(), false)
			room:broadcastSkillInvoke(self:objectName())
		end
	end
}

du_jiyu = sgs.CreateTriggerSkill {

	name = "du_jiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getHandcardNum() > player:getMaxHp() then
				room:loseMaxHp(player)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end
}

duBaonue = sgs.CreateTriggerSkill {
	name = "duBaonue$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage, sgs.DamageDone },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageDone and damage.from then
			damage.from:setTag("InvokeBaonue", sgs.QVariant(damage.from:getKingdom() == "qun"))
		elseif event == sgs.Damage and player:getTag("InvokeBaonue"):toBool() and player:isAlive() then
			local dongzhuos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					dongzhuos:append(p)
				end
			end
			while (not dongzhuos:isEmpty()) do
				local dongzhuo = room:askForPlayerChosen(player, dongzhuos, self:objectName(), "@baonue-to", true)
				if dongzhuo then
					dongzhuos:removeOne(dongzhuo)
					local log = sgs.LogMessage()
					log.type = "#InvokeOthersSkill"
					log.from = player
					log.to:append(dongzhuo)
					log.arg = self:objectName()
					room:sendLog(log)
					room:notifySkillInvoked(dongzhuo, self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					room:broadcastSkillInvoke(self:objectName())
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
		end
		return false
	end
}

duSunjian = sgs.General(extension, "duSunjian", "wu", 4)


tongpaodestCard = sgs.CreateSkillCard {
	name = "tongpaodestCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring==""
		then aocaistring = "slash"
		end
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring==""
			then aocaistring = "slash"
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
		if aocaistring==""
			then aocaistring = "slash"
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
			card = room:askForCard(p, aocaistring, prompt, dt, sgs.Card_MethodResponse, p);
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
		if aocaistring==""
			then aocaistring = "slash"
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
			card = room:askForCard(p, aocaistring, prompt, dt, sgs.Card_MethodResponse,p);
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
	end
}
tongpaodest = sgs.CreateZeroCardViewAsSkill {
	name = "tongpaodest&",
	enabled_at_play = function(self, player)
		if player:hasFlag("Global_tongpaoFailed") then return false end
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("Global_tongpaoFailed") then return end
		if player:hasFlag("Global_tongpaoUsing") then return end
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
	end
}


tongpao = sgs.CreateTriggerSkill {
	name = "tongpao",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getAlivePlayers()
		for _, p in sgs.qlist(players) do
			if p:getKingdom() == "wu" then
				room:attachSkillToPlayer(p, "tongpaodest")
			end
		end
		return false
	end
}

tongpaoSlash = sgs.CreateTriggerSkill {
	name = "#tongpaoSlash",
	events = { sgs.CardAsked },
	can_trigger = function(self, target)
		return target ~= nil and target:getKingdom() == "wu"
	end,
	on_trigger = function(self, event, player, data)
		local pattern = data:toStringList()[1]
		if pattern ~= "slash" then
			return false
		end
		if string.startsWith(data:toStringList()[2], "@tongpao") or string.startsWith(data:toStringList()[2], "@@tongpao") then
			return false
		end
		if not player:askForSkillInvoke("tongpao_slash", data) then
			return false
		end
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = player
		room:sendLog(log)
		local dest = sgs.QVariant()
		dest:setValue(player)
		local lieges = room:getLieges("wu", player)
		for _, p in sgs.qlist(lieges) do
			local slash = room:askForCard(p, "slash", "@tongpao-slash:" .. player:objectName(), dest,
				sgs.Card_MethodResponse, nil, false, "", true)
			if slash then
				room:setPlayerFlag(player, "-tongpao_target")
				room:broadcastSkillInvoke("tongpao")
				room:provide(slash)
				return true
			end
		end
		return false
	end
}
tongpaoJink = sgs.CreateTriggerSkill {
	name = "#tongpaoJink",
	events = { sgs.CardAsked },
	can_trigger = function(self, target)
		return target ~= nil and target:getKingdom() == "wu" and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then
			return false
		end
		if string.startsWith(data:toStringList()[2], "@tongpao") or string.startsWith(data:toStringList()[2], "@@tongpao") then
			return false
		end
		if not player:askForSkillInvoke("tongpao_jink", data) then
			return false
		end

		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.type = "#tongpao"
		log.from = player
		room:sendLog(log)
		local lieges = room:getLieges("wu", player)
		local dest = sgs.QVariant()
		dest:setValue(player)
		for _, p in sgs.qlist(lieges) do
			local jink = room:askForCard(p, "jink", "@tongpao-jink:" .. player:objectName(), dest,
				sgs.Card_MethodResponse, nil, false, "", true)
			if jink then
				room:broadcastSkillInvoke("tongpao")
				room:provide(jink)
				return true
			end
		end
		return false
	end
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
duDongzhuo:addSkill(xixing)
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
duGanning:addRelateSkill("qixi")

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
	[":du_jieying"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的“锦”大于或等于三张，你回复1点体力，然后失去1点体力上限，并获得“奇袭”。",
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
	["@@tongpao"]           = "是否发动同袍使用或打出一张 %src",
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
	[":du_tongque"] = "<font color=\"orange\"><b>主公技，</b></font>当魏势力角色导致女性角色濒死并求桃失败后，你可以将一张手牌交给其，令其复活。该角色摸三张牌，恢复1点体力，失去1点体力上限，将势力改为魏，并改变身份为“内奸”。",
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

	["xixing"] = "庸纳",
	[":xixing"] = "每当你受到伤害后，你可以获得伤害来源的全部手牌。",
	["$xixing1"] = "敲骨吸髓，不亦乐乎。",
	["$xixing2"] = "强取豪夺，乃真豪杰。",

	["du_jiyu"] = "积郁",
	[":du_jiyu"] = "回合开始阶段，若你的手牌数量大于手牌上限，你失去一点体力上限。",
	["$du_jiyu1"] = "我还要更多，更多！",
	["$du_jiyu2"] = "酒池肉林，其乐无穷，哈哈哈",

	["duBaonue"] = "暴虐",
	[":duBaonue"] = "<font color=\"orange\"><b>主公技，</b></font>当其他群势力角色造成伤害后，其可以进行判定，若结果为♠，你增加1点体力上限。",
	["#baonueMessage"] = "%from 增加 %arg 点体力上限",
	["$duBaonue1"] = "哈哈哈哈，不愧是我的好部下。",
	["$duBaonue2"] = "杀得好，大大有赏！",


	["~tmp"] = "一二三",
	["$duWusheng"] = "四五六",
	["$jiushen_tril"] = "酒神现世",
	["$jiushen2_tril"] = "酒神现世",
	["$juli_tril"] = "汇天地之灵气",
	["$gudan_tril"] = "孤胆英雄",
	["$xixing_tril"] = "孤胆英雄",
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
	["illustratr:tmp"] = "222"

}

return { extension }
