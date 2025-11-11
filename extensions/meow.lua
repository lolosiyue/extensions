module("extensions.meow", package.seeall)
extension = sgs.Package("meow")
local skills = sgs.SkillList()
--逗喵
MeowCaiwenji = sgs.General(extension, "MeowCaiwenji", "qun", "3", false)
Meowdiaochan = sgs.General(extension, "Meowdiaochan", "qun", "3", false)
MeowCaifuren = sgs.General(extension, "MeowCaifuren", "qun", "3", false)
MeowZhangxingcai = sgs.General(extension, "MeowZhangxingcai", "shu", "3", false)
MeowZhurong = sgs.General(extension, "MeowZhurong", "shu", "4", false)
MeowHuangyueying = sgs.General(extension, "MeowHuangyueying", "shu", "3", false)
MeowDaqiao = sgs.General(extension, "MeowDaqiao", "wu", "3", false)
MeowXiaoqiao = sgs.General(extension, "MeowXiaoqiao", "wu", 3, false)
MeowSunshangxiang = sgs.General(extension, "MeowSunshangxiang", "wu", 3, false)
MeowZhenji = sgs.General(extension, "MeowZhenji", "wei", 3, false)
MeowZhangchunhua = sgs.General(extension, "MeowZhangchunhua", "wei", 3, false)
MeowWangyi = sgs.General(extension, "MeowWangyi", "wei", 4, false)
Meowlvlingqi = sgs.General(extension, "Meowlvlingqi", "qun", 4, false)
Meowdoumiao = sgs.CreateTriggerSkill {
	name = "Meowdoumiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and phase == sgs.Player_RoundStart then
			if player:isNude() then
				return false
			end
			if room:askForSkillInvoke(player, "Meowdoumiao", data) then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				--local use = room:askForUseCard(player, "@@Meowdoumiao", "@Meowdoumiao")
				if not player:isNude() then
					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
				end
				if player:hasSkill("Meowdoumiao") then
					room:detachSkillFromPlayer(player, "Meowdoumiao")
				end
				if not to:hasSkill("Meowdoumiao") then
					room:acquireSkill(to, "Meowdoumiao")
				end
				room:drawCards(to, 1, self:objectName())
				--room:broadcastSkillInvoke("Meowdoumiao")
			end
		elseif event == sgs.EventPhaseEnd and phase == sgs.Player_Finish then
			if not player:isNude() then
				room:askForDiscard(player, self:objectName(), 1, 1, false, true)
			end
		end
	end,
}
--喵蔡文姬

MeowBeige = sgs.CreateTriggerSkill {
	name = "MeowBeige",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card == nil or not damage.card:isKindOf("Slash") or damage.to:isDead() then
			return false
		end
		for _, caiwenji in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if not caiwenji or caiwenji:isDead() or not caiwenji:hasSkill(self:objectName()) then continue end
			if caiwenji:canDiscard(caiwenji, "he") then
				local card = room:askForCard(caiwenji, "..", "@MeowBeige", data, self:objectName())
				if card then
					room:broadcastSkillInvoke("MeowBeige", math.random(1, 2))
					-- local id = room:askForCardChosen(caiwenji, caiwenji, "he", "MeowBeige")
					-- local card = sgs.Sanguosha:getCard(id)
					-- local suit = card:getSuit()
					--room:askForDiscard(caiwenji, self:objectName(), 1, 1, false, true)
					local suit = card:getSuit()
					if suit == sgs.Card_Spade then
						if damage.from and damage.from:isAlive() then
							damage.from:turnOver()
						end
					elseif suit == sgs.Card_Heart then
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = 1
						theRecover.who = caiwenji
						room:recover(damage.to, theRecover)
					elseif suit == sgs.Card_Club then
						if not damage.from:isNude() and damage.from:isAlive() then
							room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
						end
					elseif suit == sgs.Card_Diamond then
						room:drawCards(damage.to, 2, self:objectName())
					end
					if not caiwenji:hasSkill("Meowdoumiao") then
						local choices = "Spade+Heart+Club+Diamond"
						local choice = room:askForChoice(caiwenji, "MeowBeige", choices, data)
						if choice == "Spade" then
							if damage.from and damage.from:isAlive() then
								damage.from:turnOver()
							end
						elseif choice == "Heart" then
							local theRecover = sgs.RecoverStruct()
							theRecover.recover = 1
							theRecover.who = caiwenji
							room:recover(damage.to, theRecover)
						elseif choice == "Club" then
							if not damage.from:isNude() and damage.from:isAlive() then
								room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
							end
						elseif choice == "Diamond" then
							room:drawCards(damage.to, 2, self:objectName())
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
MeowCaiwenji:addSkill(MeowBeige)
MeowDuanchang = sgs.CreateTriggerSkill {
	name = "MeowDuanchang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death, sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
			room:broadcastSkillInvoke("MeowDuanchang", math.random(1, 2))
			if death.damage and death.damage.from then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local skills = death.damage.from:getVisibleSkillList()
				local detachList = {}
				for _, skill in sgs.qlist(skills) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
						table.insert(detachList, "-" .. skill:objectName())
					end
				end
				room:handleAcquireDetachSkills(death.damage.from, table.concat(detachList, "|"))
				if death.damage.from:isAlive() then
					death.damage.from:gainMark("@duanchang")
				end
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if player:hasSkill("Meowdoumiao") or dying.who:objectName() ~= player:objectName() then
				return false
			else
				room:broadcastSkillInvoke("MeowDuanchang", math.random(1, 2))
				if dying.damage and dying.damage.from then
					room:askForDiscard(dying.damage.from, self:objectName(), 2, 2, false, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
}
MeowCaiwenji:addSkill(MeowDuanchang)
--喵貂蝉, 部分代码来自FC佬的谋貂蝉

MeowlijianCard = sgs.CreateSkillCard {
	name = "MeowlijianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local n = player:getHandcardNum() + player:getEquips():length()
		if not player:hasSkill(Meowdoumiao) then
			n = n + 1
		end
		return to_select:objectName() ~= sgs.Self:objectName() and #targets <= n
	end,
	feasible = function(self, targets, player)
		local n = player:getHandcardNum() + player:getEquips():length()
		if not player:hasSkill(Meowdoumiao) then
			n = n + 1
		end
		return #targets <= n and #targets >= 2
	end,
	on_use = function(self, room, source, targets)
		local n = #targets
		if not source:hasSkill(Meowdoumiao) then
			n = n - 1
		end
		if not source:isNude() then
			n = math.min(n, source:getHandcardNum() + source:getEquips():length())
		end
		room:askForDiscard(source, self:objectName(), n, n, false, true)
		local lj, st, f, t = 1, 1, nil, nil
		for _, p in pairs(targets) do
			room:setPlayerMark(p, "MeowlijianTargets", lj)
			if p:getMark("MeowlijianTargets") == 1 then
				t = p
			elseif p:getMark("MeowlijianTargets") == #targets then
				f = p
				break
			end
			lj = lj + 1
		end
		while lj > 0 do
			local from, to = nil, nil
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getMark("MeowlijianTargets") == st then
					from = p
				elseif p:getMark("MeowlijianTargets") == st + 1 then
					to = p
				end
				if from ~= nil and to ~= nil then break end
			end
			if from ~= nil and to ~= nil then
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				duel:setSkillName("Meowlijian")
				if not from:isCardLimited(duel, sgs.Card_MethodUse) and not from:isProhibited(to, duel) then
					room:useCard(sgs.CardUseStruct(duel, from, to))
				else
					duel:deleteLater()
				end
			end
			st = st + 1
			lj = lj - 1
		end
		if f:isAlive() and t:isAlive() then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("Meowlijian")
			if not f:isCardLimited(duel, sgs.Card_MethodUse) and not f:isProhibited(t, duel) then
				room:useCard(sgs.CardUseStruct(duel, f, t))
			else
				duel:deleteLater()
			end
		end
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:setPlayerMark(p, "MeowlijianTargets", 0)
		end
	end,
}
Meowlijian = sgs.CreateViewAsSkill {
	name = "Meowlijian",
	n = 0,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		--[[if #cards > 0 then
			local MLJCard = MeowlijianCard:clone()
			for _, card in pairs(cards) do
				MLJCard:addSubcard(card)
			end
			MLJCard:setSkillName(self:objectName())
			return MLJCard
		end]]
		return MeowlijianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and not player:hasUsed("#MeowlijianCard")
	end,
}
Meowdiaochan:addSkill(Meowlijian)
Meowbiyue = sgs.CreateTriggerSkill {
	name = "Meowbiyue",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.EventPhaseChanging, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() and not player:hasFlag("Meowbiyue_damagedTargets") then
				room:setPlayerFlag(player, "Meowbiyue_damagedTargets")
				local x = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("Meowbiyue_damagedTargets") then
						x = x + 1
					end
				end
				local current = room:getCurrent()
				if current and current:hasSkill(self:objectName()) then
					room:setPlayerMark(current, "&" .. self:objectName() .. "-Clear", x)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
				local n = 1
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("Meowbiyue_damagedTargets") then
						room:setPlayerFlag(p, "-Meowbiyue_damagedTargets")
						n = n + 1
					end
				end
				if not player:hasSkill(Meowdoumiao) then
					n = n + 1
				end
				if n > 5 then n = 5 end
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, n, self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("Meowbiyue_damagedTargets") then
					room:setPlayerFlag(p, "-Meowbiyue_damagedTargets")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}


Meowdiaochan:addSkill(Meowbiyue)
--喵蔡夫人

MeowQieting = sgs.CreateTriggerSkill {
	name = "MeowQieting",
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive and not player:isNude() then
				--local splayer = room:findPlayerBySkillName(self:objectName())
				--if not splayer or splayer:objectName() == player:objectName() then return end
				for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if splayer:objectName() ~= player:objectName() and splayer:askForSkillInvoke(self:objectName()) then
						room:broadcastSkillInvoke("MeowQieting", math.random(1, 2))
						local dest = sgs.QVariant()
						dest:setValue(player)
						if not player:hasSkill(Meowdoumiao) then
							local choices = {}
							local can_get = false
							local disabled_ids = sgs.IntList()
							if player:hasEquip() then
								for i = 0, 4, 1 do
									if player:getEquip(i) then
										if splayer:getEquip(i) then
											disabled_ids:append(player:getEquip(i):getEffectiveId())
										else
											can_get = true
										end
									end
								end
								if can_get then
									table.insert(choices, "get=" .. player:objectName())
								end
							end
							table.insert(choices, "draw")

							local choice = room:askForChoice(splayer, self:objectName(), table.concat(choices, "+"), dest)
							if choice:startsWith("get") then
								local card_id = room:askForCardChosen(splayer, player, "e", self:objectName(), false,
									sgs.Card_MethodNone, disabled_ids)
								room:moveCardTo(sgs.Sanguosha:getCard(card_id), splayer, sgs.Player_PlaceEquip)
							else
								splayer:drawCards(1)
							end
						else
							local choices = {}
							local disabled_ids = sgs.IntList()
							if not player:isKongcheng() then
								table.insert(choices, "getHCrad=" .. player:objectName())
							end
							table.insert(choices, "draw")
							local choice = room:askForChoice(splayer, self:objectName(), table.concat(choices, "+"), dest)
							if choice:startsWith("getHCrad") then
								local x = math.min(player:getHandcardNum(), 2)
								local card_id = sgs.IntList()
								while x > 0 do
									local id = room:askForCardChosen(splayer, player, "h", self:objectName())
									card_id:append(id)
									x = x - 1
								end
								room:fillAG(card_id, splayer)
								local id = room:askForAG(splayer, card_id, false, self:objectName())
								room:clearAG(splayer)
								room:obtainCard(splayer, id, false)
							else
								splayer:drawCards(1)
							end
						end
					end
				end
			end
		end
		return false
	end
}
MeowCaifuren:addSkill(MeowQieting)
--
MeowxianzhouCard = sgs.CreateSkillCard {
	name = "MeowxianzhouCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if player:hasFlag("Meowxianzhou_target") then
			return #targets < player:getMark("Meowxianzhou_count") and player:inMyAttackRange(to_select)
		end
		if #targets ~= 0 then return false end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		if sgs.Self:hasFlag("Meowxianzhou_target") then
			return #targets <= sgs.Self:getMark("Meowxianzhou_count")
		end
		return #targets == 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:hasFlag("Meowxianzhou_target") then
			room:damage(sgs.DamageStruct("Meowxianzhou", effect.from, effect.to))
		else
			room:removePlayerMark(effect.from, "@handover")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(),
				effect.to:objectName(), "Meowxianzhou", "")
			room:moveCardTo(self, effect.to, sgs.Player_PlaceHand, reason, false)
			local choices = {}
			if effect.from:isWounded() then
				table.insert(choices, "recover")
			end
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if effect.to:inMyAttackRange(p) then
					n = n + 1
				end
			end
			if n >= 1 then
				table.insert(choices, "damage")
			end
			if #choices > 0 then
				local choice = room:askForChoice(effect.to, "Meowxianzhou", table.concat(choices, "+"))
				if choice == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = effect.to
					recover.recover = math.min(effect.from:getMaxHp() - effect.from:getHp(), self:subcardsLength())
					room:recover(effect.from, recover)
				elseif choice == "damage" then
					room:setPlayerFlag(effect.to, "Meowxianzhou_target")
					room:setPlayerMark(effect.to, "Meowxianzhou_count", self:subcardsLength())
					if room:askForUseCard(effect.to, "@@Meowxianzhou", "@Meowxianzhou") then
					else
						local recover = sgs.RecoverStruct()
						recover.who = effect.to
						recover.recover = math.min(effect.from:getMaxHp() - effect.from:getHp(), self:subcardsLength())
						room:recover(effect.from, recover)
					end
					room:setPlayerFlag(effect.to, "-Meowxianzhou_target")
					room:setPlayerMark(effect.to, "Meowxianzhou_count", 0)
				end
			end
		end
	end
}
MeowxianzhouVS = sgs.CreateViewAsSkill {
	name = "Meowxianzhou",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local MXZCard = MeowxianzhouCard:clone()
		for _, card in pairs(cards) do
			MXZCard:addSubcard(card)
		end
		--MXZCard:setSkillName(self:objectName())
		return MXZCard
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and player:getMark("@handover") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@Meowxianzhou"
	end
}
Meowxianzhou = sgs.CreateTriggerSkill {
	name = "Meowxianzhou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@handover",
	events = { sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill },
	view_as_skill = MeowxianzhouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setPlayerMark(player, "@handover", 1)
		elseif event == sgs.EventLoseSkill and not player:hasSkill(Meowdoumiao) then
			room:setPlayerMark(player, "MeowxianzhouMark", 1)
		elseif event == sgs.EventAcquireSkill and player:hasSkill(Meowdoumiao) and player:getMark("MeowxianzhouMark") > 0 then
			room:setPlayerMark(player, "@handover", 1)
			room:setPlayerMark(player, "MeowxianzhouMark", 0)
		end
	end
}
MeowCaifuren:addSkill(Meowxianzhou)
--喵张星彩

MeowShenxian = sgs.CreateTriggerSkill {
	name = "MeowShenxian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if player:hasFlag("MeowShenxianUsed") then return false end
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		if move.from and (move.from:objectName() ~= player:objectName())
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			local can_draw = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or (not player:hasSkill(Meowdoumiao) and sgs.Sanguosha:getCard(id):isKindOf("TrickCard")) then
					can_draw = can_draw + 1
				end
			end
			if can_draw > 0 then
				room:broadcastSkillInvoke("MeowShenxian", math.random(1, 2))
				if move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
					local n = 0
					for n = 1, can_draw, 1 do
						if player:askForSkillInvoke(self:objectName()) then
							player:drawCards(1)
							room:setPlayerFlag(player, "MeowShenxianUsed")
							break
						else
							break
						end
					end
				elseif player:askForSkillInvoke(self:objectName()) then
					player:drawCards(1)
					room:setPlayerFlag(player, "MeowShenxianUsed")
				end
			end
		end
		return false
	end,
}
MeowShenxianM = sgs.CreateTriggerSkill {
	name = "#MeowShenxianM",
	events = { sgs.TurnStart },
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			room:setPlayerFlag(p, "-MeowShenxianUsed")
		end
		return false
	end
}
MeowZhangxingcai:addSkill(MeowShenxian)
MeowZhangxingcai:addSkill(MeowShenxianM)
MeowQiangwuMod = sgs.CreateTargetModSkill {
	name = "MeowQiangwuMod",
	pattern = "Slash",
	residue_func = function(self, from, card, to)
		local n = 0
		if from:hasSkill("MeowQiangwu") and to and to:hasSkill("Meowdoumiao") then
			n = n + 1000
		end
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("MeowQiangwu") and to and not to:hasSkill("Meowdoumiao") then
			return 1000
		end
	end,
}
if not sgs.Sanguosha:getSkill("MeowQiangwuMod") then skills:append(MeowQiangwuMod) end

MeowQiangwu = sgs.CreateTriggerSkill {
	name = "MeowQiangwu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from == player and damage.card:isKindOf("Slash") and player:hasSkill(Meowdoumiao) then
			room:broadcastSkillInvoke("MeowQiangwu", math.random(1, 2))
			room:drawCards(player, 1)
		end
	end,
}
MeowZhangxingcai:addSkill(MeowQiangwu)
--喵祝融

MeowJuxiang = sgs.CreateTriggerSkill {
	name = "MeowJuxiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime, sgs.BeforeCardsMove, sgs.CardUsed, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.from and use.from:isAlive()
					and use.from:hasSkill(self:objectName()) then
					local sp, no_respond_list = sgs.SPlayerList(), use.no_respond_list
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:hasSkill(Meowdoumiao) then
							table.insert(no_respond_list, p:objectName())
							sp:append(p)
						end
					end
					if sp:isEmpty() then
						return false
					end
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
				if use.card:isVirtualCard()
					and (use.card:subcardsLength() == 0) then
					return false
				end
				if use.card:isKindOf("SavageAssault") then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		elseif event == sgs.BeforeCardsMove then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local move = data:toMoveOneTime()
				if (move.card_ids:length() >= 1)
					and move.from_places:contains(sgs.Player_PlaceTable)
					and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
					local card = sgs.Sanguosha:getCard(move.card_ids:first())
					if card:hasFlag("real_SA")
						and (player:objectName() ~= move.from:objectName()) then
						for _, id in sgs.qlist(move.card_ids) do
							player:obtainCard(sgs.Sanguosha:getCard(id))
							room:broadcastSkillInvoke("MeowJuxiang", 1)
						end
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() ~= player:objectName())
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				and player and player:isAlive() and player:hasSkill(self:objectName()) then
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("SavageAssault") then
						player:obtainCard(sgs.Sanguosha:getCard(id))
						room:broadcastSkillInvoke("MeowJuxiang", 2)
					end
				end
			end
		elseif event == sgs.Damage then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				if damage.from == player and damage.card:isKindOf("SavageAssault")
					and not damage.to:hasSkill(Meowdoumiao) then
					room:drawCards(player, 1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
MeowJXAvoid = sgs.CreateTriggerSkill {
	name = "#MeowJXAvoid",
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		else
			return false
		end
	end
}
MeowZhurong:addSkill(MeowJuxiang)
MeowZhurong:addSkill(MeowJXAvoid)

MeowLierenCard = sgs.CreateSkillCard {
	name = "MeowLierenCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if player:hasFlag("MeowLierenMarkfrom") then
			return to_select:hasFlag("MeowLierenMarkto")
		end
		if to_select:isKongcheng() then
			return false
		elseif to_select:objectName() == sgs.Self:objectName() then
			return false
		end
		return true
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local success = source:pindian(target, "MeowLieren", nil)
		if success then
			if not target:isNude() then
				local id = room:askForCardChosen(source, target, "he", "MeowLieren")
				room:obtainCard(source, id, false)
			end
		end
		local list = room:getAlivePlayers()
		for _, p in sgs.qlist(list) do
			if p:hasFlag("MeowLierenMarkto") then
				room:setPlayerFlag(p, "-MeowLierenMarkto")
			end
		end
		if source:hasFlag("MeowLierenMarkfrom") then
			room:setPlayerFlag(source, "-MeowLierenMarkfrom")
		end
	end,
}
MeowLierenVS = sgs.CreateViewAsSkill {
	name = "MeowLieren",
	n = 0,

	view_as = function(self, cards)
		if #cards == 0 then
			local vs_card = MeowLierenCard:clone()

			return vs_card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@MeowLieren"
	end
}
MeowLieren = sgs.CreateTriggerSkill {
	name = "MeowLieren",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.TargetSpecified, sgs.Pindian, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.GameStart },
	view_as_skill = MeowLierenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and event == sgs.EventPhaseStart then
			if not player:isKongcheng() and player:getMark("MeowLierenMark") > 0 then
				if room:askForSkillInvoke(player, "MeowLieren", data) then
					room:broadcastSkillInvoke("MeowLieren", math.random(1, 2))
					local use = room:askForUseCard(player, "@@MeowLieren", "@MeowLieren")
				end
			end
			room:setPlayerMark(player, "MeowLierenMark", 0)
		elseif player:isAlive()
			and event == sgs.TargetSpecified
			and not player:isKongcheng() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				for _, p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						room:setPlayerFlag(p, "MeowLierenMarkto")
					end
				end
				if room:askForSkillInvoke(player, "MeowLieren", data) then
					room:setPlayerFlag(player, "MeowLierenMarkfrom")
					local use = room:askForUseCard(player, "@@MeowLieren", "@MeowLieren")
				end
			end
		elseif player:isAlive() and event == sgs.Pindian
			and player:hasSkill(self:objectName()) then
			local pindian = data:toPindian()
			if pindian.reason == "MeowLieren" then
				player:obtainCard(pindian.to_card)
			end
		elseif event == sgs.EventLoseSkill
			and not player:hasSkill(Meowdoumiao)
			and player:getMark("MeowLierenDM")
			and player:getMark("MeowLierenDM") > 0 then
			room:setPlayerMark(player, "MeowLierenMark", 1)
			room:setPlayerMark(player, "MeowLierenDM", 0)
		elseif event == sgs.EventAcquireSkill
			and player:hasSkill(Meowdoumiao)
			and player:getMark("MeowLierenDM")
			and player:getMark("MeowLierenDM") == 0 then
			room:setPlayerMark(player, "MeowLierenDM", 1)
		elseif event == sgs.GameStart
			and player:hasSkill(self:objectName()) then
			room:setPlayerMark(player, "MeowLierenDM", 1)
		end
	end,
}
MeowZhurong:addSkill(MeowLieren)

MeowJizhi = sgs.CreateTriggerSkill {
	name = "MeowJizhi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed, sgs.TurnStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("MeowJizhiMark") then
					room:setPlayerFlag(p, "-MeowJizhiMark")
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") then
				if player:hasSkill(self:objectName())
					and use.from == player
					and use.from:isAlive() then
					if room:askForSkillInvoke(player, self:objectName()) then
						room:broadcastSkillInvoke("MeowJizhi", 1)
						player:drawCards(1, self:objectName())
					end
				end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isDead()
						or not p:hasSkill(self:objectName()) then
						continue
					end
					if p:hasSkill(self:objectName()) and not p:hasSkill(Meowdoumiao)
						and not p:hasFlag("MeowJizhiMark") then
						if room:askForSkillInvoke(p, self:objectName()) then
							p:drawCards(1, self:objectName())
							room:setPlayerFlag(p, "MeowJizhiMark")
							room:broadcastSkillInvoke("MeowJizhi", 2)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
MeowHuangyueying:addSkill(MeowJizhi)
MeowQicai = sgs.CreateTriggerSkill {
	name = "MeowQicai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				--room:acquireSkill(player, "qicai")
			elseif not player:hasSkill(Meowdoumiao) then
				room:setPlayerMark(player, "MeowQicaiMark", 1)
			end
		elseif event == sgs.EventLoseSkill
			and not player:hasSkill(Meowdoumiao) then
			room:setPlayerMark(player, "MeowQicaiMark", 1)
		elseif event == sgs.EventAcquireSkill
			and player:hasSkill(Meowdoumiao)
			and player:getMark("MeowQicaiMark")
			and player:getMark("MeowQicaiMark") > 0 then
			room:setPlayerMark(player, "MeowQicaiMark", 0)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill(self:objectName()) then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
							room:obtainCard(p, id, false)
							room:broadcastSkillInvoke("MeowQicai", math.random(1, 2))
							break
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
MeowQicaiLimit= sgs.CreateCardLimitSkill {
	name = "#MeowQicaiLimit",
	limit_list = function(self, player)
		return "discard"
	end,
	limit_pattern = function(self, player)
		if player then
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasSkill("MeowQicai") and p:getArmor() then
					return p:getArmor():toString()
				end
			end
		end
		return ""
	end
}
MeowHuangyueying:addSkill(MeowQicai)
MeowHuangyueying:addSkill(MeowQicaiLimit)
extension:insertRelatedSkills("MeowQicai", "#MeowQicaiLimit")

MeowGuoseCard = sgs.CreateSkillCard {
	name = "MeowGuoseCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			for _, j in sgs.qlist(to_select:getJudgingArea()) do
				if j:isKindOf("Indulgence") then
					return true
				end
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		for _, idg in sgs.qlist(effect.to:getJudgingArea()) do
			if idg:isKindOf("Indulgence") then
				room:throwCard(idg, effect.to, effect.from)
				if effect.to:hasSkill(Meowdoumiao) then
					room:drawCards(effect.from, 2, "MeowGuose")
					if not effect.from:isNude() then
						room:askForDiscard(effect.from, self:objectName(), 1, 1, false, true)
					end
				else
					room:drawCards(effect.from, 1, "MeowGuose")
				end
				if effect.from:getMark("MeowGuoseUsed") and effect.from:getMark("MeowGuoseUsed") > 1 then
					room:setPlayerMark(effect.from, "MeowGuoseUsed", effect.from:getMark("MeowGuoseUsed") + 1)
				else
					room:setPlayerMark(effect.from, "MeowGuoseUsed", 1)
				end
				room:broadcastSkillInvoke("MeowGuose", math.random(1, 2))
			end
		end
	end,
}
MeowGuoseCard2 = sgs.CreateSkillCard {
	name = "MeowGuoseCard2",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local indulgence = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
		indulgence:setSkillName("MeowGuose")
		indulgence:addSubcard(card)
		if not effect.to:isProhibited(effect.to, indulgence) then
			room:useCard(sgs.CardUseStruct(indulgence, effect.from, effect.to))
			room:addMaxCards(effect.to, -1, true)
		else
			indulgence:deleteLater()
		end
		if effect.to:hasSkill(Meowdoumiao) then
			room:drawCards(effect.from, 2, "MeowGuose")
			if not effect.from:isNude() then
				room:askForDiscard(effect.from, self:objectName(), 1, 1, false, true)
			end
		else
			room:drawCards(effect.from, 1, "MeowGuose")
		end
		if effect.from:getMark("MeowGuoseUsed") and effect.from:getMark("MeowGuoseUsed") > 0 then
			room:setPlayerMark(effect.from, "MeowGuoseUsed", effect.from:getMark("MeowGuoseUsed") + 1)
		else
			room:setPlayerMark(effect.from, "MeowGuoseUsed", 1)
		end
		room:broadcastSkillInvoke("MeowGuose", math.random(1, 2))
	end,
}
MeowGuoseVS = sgs.CreateViewAsSkill {
	name = "MeowGuose",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond
	end,
	view_as = function(self, cards)
		if #cards == 0 then --弃乐
			return MeowGuoseCard:clone()
		elseif #cards == 1 then --贴乐
			local card = MeowGuoseCard2:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("MeowGuoseUsed") < 4
	end,
}
MeowGuose = sgs.CreateTriggerSkill {
	name = "MeowGuose",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	view_as_skill = MeowGuoseVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			player:getRoom():setPlayerMark(player, "MeowGuoseUsed", 0)
		end
	end,
}
MeowDaqiao:addSkill(MeowGuose)

MeowLiuliCard = sgs.CreateSkillCard {
	name = "MeowLiuliCard",
	filter = function(self, targets, to_select, player)
		local n = 0
		if not player:hasSkill(Meowdoumiao) then
			n = n + 1
		end
		if #targets > n then return false end
		if to_select:hasFlag("MeowLiuliSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("MeowLiuliSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("MeowLiuli"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (sgs.Self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("MeowLiuliTarget")
	end
}
MeowLiuliVS = sgs.CreateOneCardViewAsSkill {
	name = "MeowLiuli",
	response_pattern = "@@MeowLiuli",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = MeowLiuliCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
MeowLiuli = sgs.CreateTriggerSkill {
	name = "MeowLiuli",
	events = { sgs.TargetConfirming },
	view_as_skill = MeowLiuliVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card
			and use.card:isKindOf("Slash")
			and use.to:contains(player)
			and player:canDiscard(player, "he")
			and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@liuli:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "MeowLiuliSlashSource")
				room:setPlayerProperty(player, "MeowLiuli", sgs.QVariant(use.card:toString()))
				room:setTag("MeowLiuli", data)
				if room:askForUseCard(player, "@@MeowLiuli", prompt, -1, sgs.Card_MethodDiscard) then
					room:broadcastSkillInvoke("MeowLiuli", math.random(1, 2))
					room:setPlayerProperty(player, "MeowLiuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-MeowLiuliSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("MeowLiuliTarget") then
							p:setFlags("-MeowLiuliTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
						end
					end
				else
					room:setPlayerProperty(player, "MeowLiuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-MeowLiuliSlashSource")
				end
				room:removeTag("MeowLiuli")
			end
		end
		return false
	end
}
MeowDaqiao:addSkill(MeowLiuli)

MeowTianxiangCard = sgs.CreateSkillCard {
	name = "MeowTianxiangCard",
	will_throw = false,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:obtainCard(effect.to, self, true)
		effect.to:addMark("MeowTianxiangTarget")
		local damage = effect.from:getTag("MeowTianxiangDamage"):toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			effect.from:removeQinggangTag(damage.card)
		end
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage)
		room:broadcastSkillInvoke("MeowTianxiang", math.random(1, 2))
		if effect.to:hasSkill(Meowdoumiao) then
			local theDamage = sgs.DamageStruct()
			theDamage.from = effect.from
			theDamage.to = effect.to
			theDamage.damage = 1
			theDamage.nature = sgs.DamageStruct_Normal
			room:damage(theDamage)
		else
			if not effect.to:isNude() then
				local id = room:askForCardChosen(effect.from, effect.to, "he", "MeowTianxiang")
				room:throwCard(id, effect.to, effect.from)
			end
		end
	end
}
MeowTianxiangVS = sgs.CreateViewAsSkill {
	name = "MeowTianxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected ~= 0 then return false end
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Heart)
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local tianxiangCard = MeowTianxiangCard:clone()
		tianxiangCard:addSubcard(cards[1])
		return tianxiangCard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@MeowTianxiang"
	end
}
MeowTianxiang = sgs.CreateTriggerSkill {
	name = "MeowTianxiang",
	events = { sgs.DamageInflicted },
	view_as_skill = MeowTianxiangVS,
	on_trigger = function(self, event, player, data)
		if player:canDiscard(player, "h") then
			player:setTag("MeowTianxiangDamage", data)
			return player:getRoom():askForUseCard(player, "@@MeowTianxiang", "@tianxiang-card", -1,
				sgs.Card_MethodDiscard)
		end
		return false
	end
}
MeowXiaoqiao:addSkill(MeowTianxiang)
MeowHongyan = sgs.CreateTriggerSkill {
	name = "MeowHongyan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.FinishRetrial },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.FinishRetrial then
			local judge = data:toJudge()
			if not judge.who:hasSkill(Meowdoumiao)
				and judge.card:getSuit() == sgs.Card_Heart then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill(self:objectName()) then
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = 1
						theRecover.who = p
						room:recover(p, theRecover)
						room:drawCards(p, 1, self:objectName())
						room:broadcastSkillInvoke("MeowHongyan", math.random(1, 2))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
MeowHongyanVS = sgs.CreateFilterSkill {
	name = "#MeowHongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}
MeowXiaoqiao:addSkill(MeowHongyan)
MeowXiaoqiao:addSkill(MeowHongyanVS)
MeowJieyiCard = sgs.CreateSkillCard {
	name = "MeowJieyiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		if card:isEquipped() then
			if not to_select:hasEquip()
				or (card:isKindOf("Weapon") and not to_select:getWeapon())
				or (card:isKindOf("Armor") and not to_select:getArmor())
				or (card:isKindOf("Horse") and not to_select:getHorse())
				or (card:isKindOf("Treasure") and not to_select:getTreasure()) then
				return true
			else
				return false
			end
		end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if room:getCardPlace(self:getSubcards():first()) == sgs.Player_PlaceEquip then
			room:moveCardTo(self, effect.to, sgs.Player_PlaceEquip, false)
		else
			room:obtainCard(effect.to, self, false)
		end
		local theRecover = sgs.RecoverStruct()
		theRecover.recover = 1
		theRecover.who = effect.from
		room:recover(effect.from, theRecover)
		room:drawCards(effect.from, 1, self:objectName())
		room:broadcastSkillInvoke("MeowJieyi", math.random(1, 2))
		if not effect.from:hasSkill("Meowdoumiao") then
			local choices = "yes+no"
			local dest = sgs.QVariant()
			dest:setValue(effect.to)
			local choice = room:askForChoice(effect.from, "MeowJieyi", choices, dest)
			if choice == "yes" then
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				theRecover.who = effect.from
				room:recover(effect.to, theRecover)
				room:drawCards(effect.to, 1, self:objectName())
			end
		end
	end
}
MeowJieyi = sgs.CreateViewAsSkill {
	name = "MeowJieyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = MeowJieyiCard:clone()
			card:addSubcard(cards[1])
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player, pattern)
		return not player:isNude() and not player:hasUsed("#MeowJieyiCard")
	end
}
MeowSunshangxiang:addSkill(MeowJieyi)
MeowXiaoji = sgs.CreateTriggerSkill {
	name = "MeowXiaoji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName()
			and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:drawCards(2)
						room:broadcastSkillInvoke("MeowXiaoji", math.random(1, 2))
						if not player:hasSkill("Meowdoumiao") then
							local XJ = sgs.SPlayerList()
							for _, p in sgs.qlist(room:getAllPlayers()) do
								if p:getEquips():length() > 0
									or p:getJudgingArea():length() > 0 then
									XJ:append(p)
								end
							end
							if XJ:isEmpty() then
								return false
							else
								room:askForSkillInvoke(player, self:objectName() .. "_dis")
								local victim = room:askForPlayerChosen(player, XJ, self:objectName(), "MeowXiaoji_throw", true)
								if victim then
									local card = room:askForCardChosen(player, victim, "ej", self:objectName())
									room:throwCard(card, victim, player)
								end
							end
						end
					else
						break
					end
				end
			end
		end
		return false
	end
}
MeowSunshangxiang:addSkill(MeowXiaoji)
MeowLuoshen = sgs.CreateTriggerSkill {
	name = "MeowLuoshen",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start or (player:getPhase() == sgs.Player_Finish and not player:hasSkill(Meowdoumiao)) then
				while player:askForSkillInvoke(self:objectName()) do
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				player:obtainCard(card)
				room:broadcastSkillInvoke("MeowLuoshen", math.random(1, 2))
				return true
			end
		end
		return false
	end
}
MeowZhenji:addSkill(MeowLuoshen)
MeowQingguo = sgs.CreateViewAsSkill {
	name = "MeowQingguo",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and (to_select:isKindOf("Jink")) and not sgs.Self:hasSkill(Meowdoumiao) then
				return true
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
			or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:isBlack()
			elseif string.find(pattern, "peach") and not sgs.Self:hasSkill(Meowdoumiao) then
				return to_select:isKindOf("Jink") and not sgs.Self:hasSkill(Meowdoumiao)
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			if card:isKindOf("Jink") and not sgs.Self:hasSkill(Meowdoumiao) then
				local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
				peach:setSkillName(self:objectName())
				peach:addSubcard(id)
				return peach
			elseif card:isBlack() then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:setSkillName(self:objectName());
				jink:addSubcard(id);
				return jink
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:isWounded() and not player:hasSkill(Meowdoumiao)
	end,
	enabled_at_response = function(self, player, pattern)
		return (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")) and not player:hasSkill(Meowdoumiao)) or
			(pattern == "jink")
	end
}
MeowZhenji:addSkill(MeowQingguo)

MeowJueqing = sgs.CreateTriggerSkill {
	name = "MeowJueqing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Predamage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if not player:hasSkill(Meowdoumiao) then
			if room:askForSkillInvoke(player, "MeowJueqing", data) then
				room:loseHp(damage.from, damage.damage)
				damage.damage = damage.damage * 2
			end
		end
		room:broadcastSkillInvoke("MeowJueqing", math.random(1, 2))
		room:loseHp(damage.to, damage.damage)
		return true
	end,
}
MeowZhangchunhua:addSkill(MeowJueqing)
Meowshangshi = sgs.CreateTriggerSkill {
	name = "Meowshangshi",
	events = { sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged, sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			if player:getHandcardNum() >= math.max(player:getLostHp(), 1) then return false end
			local move = data:toMoveOneTime()
			local source = move.from
			local target = move.to
			if player:getHandcardNum() < math.max(player:getLostHp(), 1) then
				player:drawCards(math.max(player:getLostHp(), 1) - player:getHandcardNum())
				room:broadcastSkillInvoke("Meowshangshi", 1)
			end
		elseif event == sgs.MaxHpChanged
			or event == sgs.HpChanged then
			if player:getHandcardNum() >= math.max(player:getLostHp(), 1) then return false end
			local count = player:getHandcardNum()
			if player:getHandcardNum() < math.max(player:getLostHp(), 1) then
				player:drawCards(math.max(player:getLostHp(), 1) - player:getHandcardNum())
				room:broadcastSkillInvoke("Meowshangshi", 1)
			end
		elseif event == sgs.EventLoseSkill then
			if not player:hasSkill(Meowdoumiao)
				and player:hasSkill(self:objectName())
				and player:getMark("MeowshangshiMark")
				and player:getMark("MeowshangshiMark") == 0 then
				local mhp = sgs.QVariant()
				mhp:setValue(player:getMaxHp() + 1)
				room:setPlayerProperty(player, "maxhp", mhp)
				room:setPlayerMark(player, "MeowshangshiMark", 1)
				room:broadcastSkillInvoke("Meowshangshi", 2)
			end
		elseif event == sgs.EventAcquireSkill then
			if player:hasSkill(Meowdoumiao)
				and player:hasSkill(self:objectName())
				and player:getMark("MeowshangshiMark")
				and player:getMark("MeowshangshiMark") == 1 then
				room:loseMaxHp(player, 1)
				room:setPlayerMark(player, "MeowshangshiMark", 0)
				room:broadcastSkillInvoke("Meowshangshi", 2)
			end
		end
		return false
	end
}
MeowZhangchunhua:addSkill(Meowshangshi)

MeowZhenlie = sgs.CreateTriggerSkill {
	name = "MeowZhenlie",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						player:setFlags("-MeowZhenlieTarget")
						player:setFlags("MeowZhenlieTarget")
						room:loseHp(player)
						if player:isAlive() and player:hasFlag("MeowZhenlieTarget") then
							player:setFlags("-MeowZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							if not player:hasSkill(Meowdoumiao) then
								if not use.from:isNude() and use.from:isAlive() then
									local id = room:askForCardChosen(player, use.from, "he", self:objectName())
									room:obtainCard(player, id, false)
								end
							else
								if player:canDiscard(use.from, "he") then
									local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false,
										sgs.Card_MethodDiscard)
									room:throwCard(id, use.from, player)
								end
							end
							room:broadcastSkillInvoke("MeowZhenlie", math.random(1, 2))
						end
					end
				end
			end
		end
		return false
	end
}
MeowWangyi:addSkill(MeowZhenlie)
MeowMijiCard = sgs.CreateSkillCard {
	name = "MeowMijiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:obtainCard(effect.to, self, false)
		room:setPlayerMark(effect.from, "MeowMiji_count", 0)
	end
}
MeowMijiVS = sgs.CreateViewAsSkill {
	name = "MeowMiji",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and #selected < sgs.Self:getMark("MeowMiji_count")
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getMark("MeowMiji_count") then
			local card = MeowMijiCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@MeowMiji"
	end,
}
MeowMiji = sgs.CreateTriggerSkill {
	name = "MeowMiji",
	events = { sgs.EventPhaseStart },
	view_as_skill = MeowMijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) then
			if player:hasSkill(Meowdoumiao) then
				if not player:isWounded() then
					return false
				end
			else
				local PwList = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isWounded() then
						PwList:append(p)
					end
				end
				if PwList:isEmpty() then
					return false
				end
			end
			if player:askForSkillInvoke(self:objectName()) then
				local n = 0
				if not player:hasSkill(Meowdoumiao) then
					local p = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "MeowMijiA")
					n = p:getLostHp()
				else
					n = math.min(player:getLostHp(), 5)
				end
				player:drawCards(n, self:objectName())
				room:broadcastSkillInvoke("MeowMiji", math.random(1, 2))
				room:setPlayerMark(player, "MeowMiji_count", n)
				if not player:isKongcheng() and player:getHandcardNum() > n then
					local use = room:askForUseCard(player, "@@MeowMiji", "@MeowMiji")
				end
				room:setPlayerMark(player, "MeowMiji_count", 0)
			end
		end
		return false
	end
}
MeowWangyi:addSkill(MeowMiji)

MeowGuowuDouble = sgs.CreateTriggerSkill{
name = "#MeowGuowuDouble",
events = sgs.CardFinished,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if player:getMark("MeowGuowu"..use.card:toString())<1 then return false end
	player:removeMark("MeowGuowu"..use.card:toString())
	use.card:use(room,use.from,use.to)
	return false
end
}
MeowGuowu = sgs.CreateTriggerSkill {
	name = "MeowGuowu",
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Play) then
				if not player:isKongcheng() and player:askForSkillInvoke(self:objectName()) then
					room:showAllCards(player)
					local types = {}
					for _, card in sgs.qlist(player:getHandcards()) do
						if not table.contains(types, card:getTypeId()) then
							table.insert(types, card:getTypeId())
						end
					end
					local log = sgs.LogMessage()
					log.type  = "#GuoWuType"
					log.from  = player
					log.arg   = tonumber(#types)
					room:sendLog(log)
					room:addPlayerMark(player, "&MeowGuowu-PlayClear", #types)
					if #types >= 1 then
						local ids = sgs.IntList()
						for _,id in sgs.list(room:getDiscardPile())do
							if sgs.Sanguosha:getCard(id):isKindOf("TrickCard")
							then ids:append(id) end
						end
						if not ids:isEmpty() then
							local id = ids:at(math.random(1, ids:length()));
							room:obtainCard(player, id)
						end
					end
					if #types >= 2 then
						room:addPlayerMark(player, "MeowGuowu-PlayClear")
					end
					if #types >= 3 then
						room:addPlayerMark(player, "MeowGuowu_three-PlayClear")
					end
				end
			end
		elseif event == sgs.CardUsed then
			if player:getMark("MeowGuowu_three-PlayClear") == 0 then return false end
			local use = data:toCardUse()
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return false end
			room:setPlayerMark(player, "MeowGuowu_three-PlayClear", 0)
			player:addMark("MeowGuowu"..use.card:toString())
		end
		return false
	end
}

MeowGuowuTargetMod = sgs.CreateTargetModSkill {
	name = "#MeowGuowuTargetMod",
	pattern = "^SkillCard",
	residue_func = function(self, player)
		if player:hasSkill("MeowGuowu") and player:getMark("MeowGuowu-PlayClear") > 0 then
			return 999
		end
	end,
}

MeowZhuangrong = sgs.CreateTriggerSkill{
    name = "MeowZhuangrong",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Wake,
    waked_skills = "wushuang,MeowShenwei",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("MeowZhuangrong") == 0 then
					if (p:canWake(self:objectName()) or p:getHandcardNum() == 1 or p:getHp() == 1) then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:setPlayerMark(p, "MeowZhuangrong", 1)
						room:doSuperLightbox(p, "MeowZhuangrong")
						room:broadcastSkillInvoke(self:objectName())
						room:loseMaxHp(p, 1)
						local n = p:getMaxHp()
						if n > 0 then
							local rec = sgs.RecoverStruct(p, nil, n)
							room:recover(p, rec)
						end
						local x = p:getMaxHp()-p:getHandcardNum()
						if x > 0 then
							p:drawCards(x)
						end
						room:acquireSkill(p, "wushuang")
						room:acquireSkill(p, "MeowShenwei")
					end
				end
			end
		end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MeowShenweiDraw = sgs.CreateDrawCardsSkill{
	name = "#MeowShenweiDraw" ,
	frequency = sgs.Skill_Compulsory ,
	draw_num_func = function(self, player, n, room)
		room:sendCompulsoryTriggerLog(player, "MeowShenwei")
		room:broadcastSkillInvoke("MeowShenwei")
		if player:hasSkill("Meowdoumiao") then
			return n + 2
		end
		return n + 3
	end
}
MeowShenwei = sgs.CreateMaxCardsSkill{
	name = "MeowShenwei" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			if target:hasSkill("Meowdoumiao") then
				return 2
			end
			return 1
		else
			return 0
		end
	end
}
Meowlvlingqi:addSkill(MeowGuowuDouble)
Meowlvlingqi:addSkill(MeowGuowu)
Meowlvlingqi:addSkill(MeowGuowuTargetMod)
extension:insertRelatedSkills("MeowGuowu", "#MeowGuowuDouble")
extension:insertRelatedSkills("MeowGuowu", "#MeowGuowuTargetMod")
sgs.Sanguosha:setAudioType("Meowlvlingqi","wushuang","5,6")
Meowlvlingqi:addSkill(MeowZhuangrong)
if not sgs.Sanguosha:getSkill("MeowShenwei") then skills:append(MeowShenwei) end
if not sgs.Sanguosha:getSkill("#MeowShenweiDraw") then skills:append(MeowShenweiDraw) end
extension:insertRelatedSkills("MeowShenwei", "#MeowShenweiDraw")

MeowCaiwenji:addSkill(Meowdoumiao)
Meowdiaochan:addSkill(Meowdoumiao)
MeowCaifuren:addSkill(Meowdoumiao)
MeowZhangxingcai:addSkill(Meowdoumiao)
MeowZhurong:addSkill(Meowdoumiao)
MeowHuangyueying:addSkill(Meowdoumiao)
MeowDaqiao:addSkill(Meowdoumiao)
MeowXiaoqiao:addSkill(Meowdoumiao)
MeowSunshangxiang:addSkill(Meowdoumiao)
MeowZhenji:addSkill(Meowdoumiao)
MeowZhangchunhua:addSkill(Meowdoumiao)
MeowWangyi:addSkill(Meowdoumiao)
Meowlvlingqi:addSkill(Meowdoumiao)
sgs.Sanguosha:addSkills(skills)	
sgs.LoadTranslationTable {
	["meow"] = "喵娘乱舞",
	["MeowCaiwenji"] = "喵蔡文姬",
	["&MeowCaiwenji"] = "喵蔡文姬",
	["#MeowCaiwenji"] = "异乡的孤女",
	["Meowdoumiao"] = "逗猫",
	["meowdoumiao"] = "逗猫",
	[":Meowdoumiao"] = "回合开始时，你可以弃置一张牌并选择一名其他角色，转移“逗猫”，并使其摸一张牌，回合结束时，若你拥有“逗猫”，则需弃置一张牌。",
	["@Meowdoumiao"] = "选择“逗猫”的目标",
	["$Meowdoumiao"] = "喵~",
	["MeowBeige"] = "悲歌",
	["meowbeige"] = "悲歌",
	["$MeowBeige1"] = "接受吧，一切都是最好的安排",
	["$MeowBeige2"] = "我来为你点首歌吧。",
	[":MeowBeige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，若弃置的牌为：红桃，令其回复1点体力；方片，令其摸两张牌；黑桃，伤害来源翻面；梅花，伤害来源弃置2张牌。若你没有“逗猫”，则额外选择一个效果。",
	["MeowDuanchang"] = "断肠",
	["meowduanchang"] = "断肠",
	["$MeowDuanchang1"] = "请欣赏我最后的演奏。",
	["$MeowDuanchang2"] = "这首曲子，真是闻者伤心，听者断肠。",
	[":MeowDuanchang"] = "锁定技，当你死亡时，杀死你的角色失去所有武将技能。你没有“逗猫”时，令你进入濒死的角色需弃置两张牌。",
	["MeowBeige:Spade"] = "伤害来源翻面",
	["MeowBeige:Heart"] = "令其回复1点体力",
	["MeowBeige:Club"] = "伤害来源弃置2张牌",
	["MeowBeige:Diamond"] = "令其摸两张牌",
	["Meowdiaochan"] = "喵貂蝉",
	["&Meowdiaochan"] = "喵貂蝉",
	["#Meowdiaochan"] = "绝世的舞姬",
	["Meowlijian"] = "离间",
	["meowlijian"] = "离间",
	[":Meowlijian"] = "<font color='green'><b>出牌阶段限一次</b></font>，你可以选择至少两名角色并弃置X张牌（X为你选择的角色数，若你没有“逗猫”则改为角色数-1），他们依次对逆时针最近座次的你选择的另一名角色视为使用一张【决斗】。",
	["$Meowlijian1"] = "谁愿与我共舞？",
	["$Meowlijian2"] = "舞会开场啦。",
	["Meowbiyue"] = "闭月",
	["meowbiyue"] = "闭月",
	["$Meowbiyue1"] = "妾身先休息了喵~",
	["$Meowbiyue2"] = "妾身告退~",
	[":Meowbiyue"] = "锁定技，结束阶段，你摸X张牌（X为本回合受到伤害的角色数+1，若你没有“逗猫”则改为+2，至多为5）。",
	["MeowCaifuren"] = "喵蔡夫人",
	["&MeowCaifuren"] = "喵蔡夫人",
	["#MeowCaifuren"] = "襄江的蒲苇",
	["MeowQieting"] = "窃听",
	["meowqieting"] = "窃听",
	[":MeowQieting"] = "其他角色的回合结束时，若其没有“逗猫”，则你可以选择一项：1.将其装备区里的一张牌置入你的装备区；2.摸一张牌。若其拥有“逗猫”，则你可以选择一项：1.观看其两张手牌并获得其中一张牌；2.摸一张牌。",
	["$MeowQieting1"] = "卑鄙的外乡人，竟敢背后说我坏话。",
	["$MeowQieting2"] = "让我来听听看，你说了点啥。",
	["MeowQieting:get"] = "将 %src 装备区里的一张牌置入你的装备区",
	["MeowQieting:getHCrad"] = "观看 %src 两张手牌并获得其中一张牌",
	["Meowxianzhou"] = "献州",
	["meowxianzhou"] = "献州",
	["$Meowxianzhou1"] = "不打了不打了，都给你还不行吗？",
	["$Meowxianzhou2"] = "都被你榨干了。",
	[":Meowxianzhou"] = "限定技，出牌阶段，你可以将任意张牌交给一名其他角色，然后该角色选择一项：1.令你回复X点体力；2.对其攻击范围内的至多X名角色各造成1点伤害(X为你以此法交给该角色的牌的数量)。当你获得“逗猫”时，“献州”视为未发动过。",
	["Meowxianzhou:recover"] = "令你回复体力",
	["Meowxianzhou:damage"] = "对其攻击范围内的角色造成伤害",
	["@Meowxianzhou"] = "选择伤害对象",
	["MeowZhangxingcai"] = "喵张星彩",
	["&MeowZhangxingcai"] = "喵张星彩",
	["#MeowZhangxingcai"] = "敬哀皇后",
	["MeowShenxian"] = "甚贤",
	["meowshenxian"] = "甚贤",
	["$MeowShenxian1"] = "多谢老板，老板恭喜发财。",
	["$MeowShenxian2"] = "收你点小费，不过分吧。",
	[":MeowShenxian"] = "当其他角色因弃置而失去的基本牌后（若你没有“逗猫”则改为失去非装备牌），你可以摸一张牌。（每回合限一次）",
	["MeowQiangwu"] = "枪舞",
	["meowqiangwu"] = "枪舞",
	["$MeowQiangwu1"] = "欺负猫猫，看打！",
	["$MeowQiangwu2"] = "哼！揍你哟",
	[":MeowQiangwu"] = "你对没有“逗猫”的角色使用【杀】无距离限制，对有“逗猫”的角色使用【杀】无次数限制。若你拥有“逗猫”时，你的【杀】造成伤害后，摸一张牌。",
	["MeowZhurong"] = "喵祝融",
	["&MeowZhurong"] = "喵祝融",
	["#MeowZhurong"] = "野性的女王",
	["MeowJuxiang"] = "巨象",
	["meowjuxiang"] = "巨象",
	["$MeowJuxiang1"] = "小象冲鸭，踩扁他们。",
	["$MeowJuxiang2"] = "呀呼，大象来咯。",
	[":MeowJuxiang"] = "锁定技，【南蛮入侵】对你无效；当其他角色使用或弃置的【南蛮入侵】进入弃牌堆时，你获得之。拥有“逗猫”的角色无法响应你的【南蛮入侵】，你的【南蛮入侵】对没有“逗猫”的角色造成伤害时，你摸一张牌。",
	["MeowLieren"] = "烈刃",
	["meowlieren"] = "烈刃",
	["$MeowLieren1"] = "我的刀法可不比你差。",
	["$MeowLieren2"] = "你的刀，太慢了",
	[":MeowLieren"] = "当你使用【杀】指定一个目标后，你可以与其拼点，你获得其拼点的牌，若你赢，你获得其一张牌。出牌阶段开始时，若你本回合失去了“逗猫”，你可以指定一名其他角色，并发动“烈刃”。",
	["@MeowLieren"] = "选择拼点的对象",
	["MeowHuangyueying"] = "喵黄月英",
	["&MeowHuangyueying"] = "喵黄月英",
	["#MeowHuangyueying"] = "归隐的杰女",
	["MeowJizhi"] = "集智",
	["meowjizhi"] = "集智",
	[":MeowJizhi"] = "当你使用一张锦囊牌时，你可以摸一张牌。若你没有“逗猫”，其他角色使用锦囊时，你摸一张牌。（每回合限一次）",
	["$MeowJizhi1"] = "灵感不绝，计出如神。",
	["$MeowJizhi2"] = "集众人之智，则无不胜也",
	["MeowQicai"] = "奇才",
	["meowqicai"] = "奇才",
	["$MeowQicai1"] = "机关巧计，皆我所长。",
	["$MeowQicai2"] = "知人者智，自知者明。",
	[":MeowQicai"] = "锁定技，你使用锦囊牌无距离限制；其他角色不能弃置你装备区里的防具。当其他角色获得“逗猫”时，你从牌堆中获得一张锦囊牌。",
	["MeowDaqiao"] = "喵大乔",
	["&MeowDaqiao"] = "喵大乔",
	["#MeowDaqiao"] = "矜持之花",
	["MeowGuose"] = "国色",
	["meowguose"] = "国色",
	["meowguose2"] = "国色",
	["$MeowGuose1"] = "没休息好，可不能剧烈运动哦",
	["$MeowGuose2"] = "色不迷人，人自迷。",
	[":MeowGuose"] = "<font color='green'><b>出牌阶段限四次</b></font>，你可以将一张方块牌当【乐不思蜀】使用，或弃置场上的一张【乐不思蜀】；然后你摸一张牌，若目标角色身上有“逗猫”，则改为你摸两张牌并弃一张牌。",
	["MeowLiuli"] = "流离",
	["meowliuli"] = "流离",
	["$MeowLiuli1"] = "欺负女孩子算什么本事？",
	["$MeowLiuli2"] = "你先上，我为你加油助威。",
	[":MeowLiuli"] = "你被【杀】时，可以弃一张牌转移给你攻击范围内的一名其他角色；若你没有“逗猫”，则改为攻击范围内的至多两名其他角色。",
	["MeowXiaoqiao"] = "喵小乔",
	["&MeowXiaoqiao"] = "喵小乔",
	["#MeowXiaoqiao"] = "矫情之花",
	["MeowTianxiang"] = "天香",
	["meowtianxiang"] = "天香",
	["$MeowTianxiang1"] = "被我迷住了吗？",
	["$MeowTianxiang2"] = "风沙太大，来帮我挡一挡。",
	[":MeowTianxiang"] = "你受到伤害时，可以交给一名角色一张红桃手牌，然后令其代替你承受此伤害，若其拥有“逗猫”，你对其造成1点伤害；若其没有“逗猫”，你弃置其一张牌。",
	["MeowHongyan"] = "红颜",
	["meowhongyan"] = "红颜",
	["#MeowHongyan"] = "红颜",
	["$MeowHongyan1"] = "爱笑的女孩运气不会太差。",
	["$MeowHongyan2"] = "人见人爱，花见花开。",
	[":MeowHongyan"] = "锁定技，你的黑桃牌视为红桃牌。没有“逗猫”的角色判定牌生效后：如果此判定牌为红桃，你回1点体力并摸一张牌。",
	["MeowSunshangxiang"] = "喵孙尚香",
	["&MeowSunshangxiang"] = "喵孙尚香",
	["#MeowSunshangxiang"] = "弓腰姬",
	["MeowJieyi"] = "结谊",
	["meowjieyi"] = "结谊",
	["$MeowJieyi1"] = "交个朋友吧。",
	["$MeowJieyi2"] = "收下吧，这是一点心意。",
	[":MeowJieyi"] = "出牌阶段限一次，选择一名其他角色，给予一张手牌或将一张装备牌置入其装备区，然后自己回复1点体力，并摸一张牌；若没有“逗猫”，可令其也回复1点体力，并摸一张牌。",
	["MeowXiaoji"] = "枭姬",
	["meowxiaoji"] = "枭姬",
	["MeowXiaoji_dis"] = "枭姬",
	["$MeowXiaoji1"] = "凭你还想拦住本小姐？",
	["$MeowXiaoji2"] = "你是想尝尝我弓箭的厉害。",
	[":MeowXiaoji"] = "当你失去装备区里的一张牌后，你可以摸两张牌；若你没有“逗猫”，你可以弃置场上一张牌。",
	["MeowJieyi:yes"] = "令其回复1点体力，并摸一张牌",
	["MeowJieyi:no"] = "取消",
	["MeowXiaoji_throw"] = "请选择要弃置的牌",
	["MeowZhenji"] = "喵甄姬",
	["&MeowZhenji"] = "喵甄姬",
	["#MeowZhenji"] = "薄幸的美人",
	["MeowLuoshen"] = "洛神",
	["meowluoshen"] = "洛神",
	["$MeowLuoshen1"] = "皎若太阳升朝霞。",
	["$MeowLuoshen2"] = "含辞未吐，气若幽兰。",
	[":MeowLuoshen"] = "准备阶段，你可以进行判定，若结果为黑色，你获得此牌，然后你可以重复此流程；红色，获得此牌，然后结束此流程。若你没有“逗猫”，回合结束时可以再次发动【洛神】",
	["MeowQingguo"] = "倾国",
	["meowqingguo"] = "倾国",
	["$MeowQingguo1"] = "一顾倾人城，再顾倾人城。",
	["$MeowQingguo2"] = "北方有佳人，绝世而独立。",
	[":MeowQingguo"] = "你可以将一张黑色牌当【闪】使用或打出；若没有“逗猫”，你可以将一张【闪】当【桃】使用。",
	["MeowZhangchunhua"] = "喵张春华",
	["&MeowZhangchunhua"] = "喵张春华",
	["#MeowZhangchunhua"] = "冷血皇后",
	["MeowJueqing"] = "绝情",
	["meowjueqing"] = "绝情",
	["$MeowJueqing1"] = "有情人葬花，无情人葬情。",
	["$MeowJueqing2"] = "我的绝情都是拜你所赐。",
	[":MeowJueqing"] = "当你即将造成伤害时，若你没有“逗猫”，你可以失去等量体力，令此伤害翻倍。你即将造成的伤害视为失去体力。",
	["Meowshangshi"] = "伤逝",
	["meowshangshi"] = "伤逝",
	["$Meowshangshi1"] = "心已成伤，终随梦逝。",
	["$Meowshangshi2"] = "爱人者自爱，伤人者自伤。",
	[":Meowshangshi"] = "当你的手牌数小于X时，你将手牌摸至X张（X为你已损失的体力值且至少为1）；当你失去“逗猫”时，体力值上限+1；当你获得“逗猫”时，体力值上限-1。",
	["MeowWangyi"] = "喵王异",
	["&MeowWangyi"] = "喵王异",
	["#MeowWangyi"] = "决意的巾帼",
	["MeowZhenlie"] = "贞烈",
	["meowzhenlie"] = "贞烈",
	["$MeowZhenlie1"] = "不许毛手毛脚！",
	["$MeowZhenlie2"] = "一边去，这里不需要你！",
	[":MeowZhenlie"] = "当你成为【杀】或普通锦囊的目标后，你可以失去1点体力使此牌对你无效，然后你弃置使用者一张牌；若你没有“逗猫”，则改为获得使用者一张牌。",
	["MeowMiji"] = "秘计",
	["meowmiji"] = "秘计",
	["MeowMijiA"] = "选择场上一名角色，摸等同于其已损失体力值数的牌",
	["$MeowMiji1"] = "我有了个新想法。",
	["$MeowMiji2"] = "兵书上刚学的计策，正好实践一下。",
	[":MeowMiji"] = "结束阶段，你可以摸X张牌（X为你已损失的体力值），然后你可以将等量的手牌交给一名其他角色；若你没有“逗猫”则X改为场上一名你选择的角色的已损失体力值且至多为5",
	["@MeowMiji"] = "将将等量的手牌交给一名其他角色(可取消)",

	["Meowlvlingqi"] = "喵吕玲绮",
	["&Meowlvlingqi"] = "喵吕玲绮",
	["#Meowlvlingqi"] = "无双虓姬",
	["MeowGuowu"] = "帼武",
	[":MeowGuowu"] = "出牌阶段开始时，你可以展示全部手牌，根据你展示的类型数，你获得对应效果：①至少一类，从弃牌堆获得一张普通锦囊牌；\
	②至少两类，此阶段使用牌无次数限制；\
	③至少三类，此阶段首张【杀】或首张普通锦囊牌可以额外执行一次效果。",
	["MeowZhuangrong"] = "妆戎",
	[":MeowZhuangrong"] = "觉醒技，每个回合结束时，若你的体力值或手牌数为1，你减1点体力上限并回满体力，将手牌摸至体力上限，然后获得“神威”和“无双”。",
	["MeowShenwei"] = "神威",
	[":MeowShenwei"] = "锁定技，摸牌阶段，你额外摸两张牌，你的手牌上限+2；若你没有“逗猫”则修改为额外摸三张牌，手牌上限+1。",

}
return { extension }
