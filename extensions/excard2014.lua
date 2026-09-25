module("extensions.excard2014", package.seeall)
extension = sgs.Package("excard2014", sgs.Package_CardPack)

-- 卡牌启用开关：1-开启，0-关闭

----[国战]
--知己知彼
local TrickCard_zjzb = 1
--以逸待劳
local TrickCard_yydl = 1
--远交近攻
local TrickCard_yjjg = 1
--吴六剑
local EquipCard_wlj = 1
--三尖两刃刀
local EquipCard_sjlrd = 1
--飞龙夺凤
local EquipCard_fldf = 1
--太平要术
local EquipCard_typs = 0

-----[下限再突破]
--围魏救赵
local TrickCard_wwjz = 0
--调虎离山
local TrickCard_dhls = 1
--天降宝札
local TrickCard_tjbz = 1
----------------------===================================-------------
if EquipCard_sjlrd == 1 then
	EXCard_SJLRD_Skill = sgs.CreateTriggerSkillV2{
		name = "EXCard_SJLRD_Skill",
		events = { sgs.Damage },
		hide_skill = true,
		can_trigger = function(skill, event, room, player, data)
			if not (player and player:isAlive() and player:hasSkill(skill:objectName()) and player:hasWeapon("EXCard_SJLRD")) then
				return false
			end
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() == player:objectName()
				and not player:isKongcheng() and not damage.chain and not damage.transfer and damage.by_user then
				return skill:objectName()
			end
			return false
		end,
		on_cost = function(skill, event, room, player, ctx)
			return room:askForDiscard(player, skill:objectName(), 1, 1, true, false, "#EXCard_SJLRD_Skill_dis") ~= nil
		end,
		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
				if damage.to:distanceTo(p) == 1 then targets:append(p) end
			end
			if targets:isEmpty() then return false end
			local sb = room:askForPlayerChosen(player, targets, skill:objectName(), "#EXCard_SJLRD_chosen", true)
			if sb then
				room:setEmotion(player, "/excard2014/EXCard_SJLRD")
				room:damage(sgs.DamageStruct(skill:objectName(), player, sb))
			end
			return false
		end,
	}

	EXCard_SJLRD = sgs.CreateWeapon{
		name = "EXCard_SJLRD",
		class_name = "EXCard_SJLRD",
		suit = sgs.Card_Diamond,
		number = 12,
		range = 3,
		on_install = function(self, player)
			local room = player:getRoom()
			if player:getSkillInstanceIds("EXCard_SJLRD_Skill"):isEmpty() then
				room:attachSkillToPlayer(player, "EXCard_SJLRD_Skill")
			end
		end,
		on_uninstall = function(self, player)
		end,
	}

	local sjlrd = EXCard_SJLRD:clone()
	sjlrd:setParent(extension)

	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("EXCard_SJLRD_Skill") then skills:append(EXCard_SJLRD_Skill) end
	sgs.Sanguosha:addSkills(skills)
end

if EquipCard_wlj == 1 then
	-- 保留自訂 SkillCard：lua/ai/excard2014-ai.lua 以 Card_Parse("#EXCard_WLJ_SkillCARD:.:")
	-- 及 ai_skill_use_func["#EXCard_WLJ_SkillCARD"] 依賴此卡類名，V2 以 create_card 沿用。
	EXCard_WLJ_SkillCARD = sgs.CreateSkillCard{
		name = "EXCard_WLJ_SkillCARD",
		skill_name = "EXCard_WLJ",
		will_throw = false,
		filter = function(self, targets, to_select, player)
			return to_select and to_select:isAlive()
		end,
		feasible = function(self, targets, player)
			return #targets > 0
		end,
		on_use = function(self, room, source, targets)
			if not room then return end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p and p:getMark("@EXCard_WLJ") > 0 then
					p:loseAllMarks("@EXCard_WLJ")
				end
			end
			for _, p in ipairs(targets) do
				if p and p:isAlive() then
					p:gainMark("@EXCard_WLJ")
					room:setEmotion(p, "excard2014/EXCard_WLJ")
				end
			end
		end
	}
	EXCard_WLJ_Skill = sgs.CreateViewAsSkillV2{
		name = "EXCard_WLJ",
		n = 0,
		target_mode = sgs.ViewAsSkillV2_SelectTargets,
		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and player:hasWeapon("EXCard_WLJ")
		end,
		can_select_target = function(skill, request, selected, candidate)
			return candidate and candidate:isAlive()
		end,
		targets_feasible = function(skill, request, selected)
			return #selected > 0
		end,
		create_card = function(skill, request)
			return EXCard_WLJ_SkillCARD:clone()
		end,
	}
	EXCard_WLJ_SkillTM = sgs.CreateTargetModSkillV2{
		name = "EXCard_WLJ_SkillTM",
		pattern = "Slash",
		holder_selector = sgs.CorrectSkill_System,
		correct_func = function(skill, ctx)
			if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit then return nil end
			local from = ctx:getPrimary()
			if from and from:getMark("@EXCard_WLJ") > 0 then return 1 end
			return nil
		end,
	}
	EXCard_WLJ = sgs.CreateWeapon{
		name = "EXCard_WLJ",
		class_name = "EXCard_WLJ",
		suit = sgs.Card_Diamond,
		number = 6,
		range = 2,
		on_install = function(self, player)
			local room = player and player:getRoom()
			if not room then return end
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill and skill:inherits("ViewAsSkill") then room:attachSkillToPlayer(player, skill:objectName()) end
		end,
		on_uninstall = function(self, player)
			local room = player and player:getRoom()
			if not room then return end
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill and skill:inherits("ViewAsSkill") then room:detachSkillFromPlayer(player, skill:objectName(), true) end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p and p:getMark("@EXCard_WLJ") > 0 then
					p:loseAllMarks("@EXCard_WLJ")
				end
			end
		end,
	}

	local wlj = EXCard_WLJ:clone()
	wlj:setParent(extension)

	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("EXCard_WLJ") then skills:append(EXCard_WLJ_Skill) end
	if not sgs.Sanguosha:getSkill("EXCard_WLJ_SkillTM") then skills:append(EXCard_WLJ_SkillTM) end
	sgs.Sanguosha:addSkills(skills)
end


if EquipCard_fldf == 1 then
	EXCard_FLDF_Skill = sgs.CreateTriggerSkillV2{
		name = "EXCard_FLDF_Skill",
		events = { sgs.TargetConfirmed, sgs.BuryVictim },
		priority = -1,
		hide_skill = true,
		can_trigger = function(skill, event, room, player, data)
			if event == sgs.TargetConfirmed then
				if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:hasWeapon("EXCard_FLDF") then
					local use = data:toCardUse()
					if use.from and use.from:objectName() == player:objectName() and not use.to:isEmpty() and use.card:isKindOf("Slash") then
						return skill:objectName()
					end
				end
				return false
			elseif event == sgs.BuryVictim then
				if not (player and player:isDead()) then return false end
				local death = data:toDeath()
				if not (death.who and death.who:objectName() == player:objectName()) then return false end
				local damage = death.damage
				if damage and damage.from and damage.from:hasWeapon("EXCard_FLDF")
					and damage.from:hasSkill(skill:objectName()) and damage.card and damage.card:isKindOf("Slash") then
					return skill:objectName(), damage.from
				end
				return false
			end
			return false
		end,
		on_cost = function(skill, event, room, player, ctx)
			if event ~= sgs.BuryVictim then return true end
			local death = ctx.original_data:toDeath()
			local damage = death.damage
			local victim = death.who or ctx.invoker
			local generalsname = sgs.Sanguosha:getRandomGenerals(888)
			local bannames = {}
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				table.insert(bannames, p:getGeneralName())
				if p:getGeneral2() then table.insert(bannames, p:getGeneral2Name()) end
			end
			table.removeTable(generalsname, bannames)
			local newnames = {}
			for _, name in ipairs(generalsname) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general and general:getKingdom() == damage.from:getKingdom() then
					table.insert(newnames, name)
				end
			end
			local names1, names2, first
			if #newnames == 0 then
				names1 = sgs.Sanguosha:getRandomGenerals(1)[1]
				if victim:getGeneral2() then names2 = sgs.Sanguosha:getRandomGenerals(1)[1] end
			else
				first = newnames[1]
				if #newnames > 21 then
					names1 = table.concat(newnames, "+", 1, 21)
				else
					names1 = table.concat(newnames, "+")
				end
			end
			if not names1 then return false end
			room:setPlayerFlag(victim, skill:objectName())
			local invoke = room:askForSkillInvoke(player, "EXCard_FLDF_revive", ctx.original_data)
			room:setPlayerFlag(victim, "-"..skill:objectName())
			if not invoke then return false end
			ctx.extra_data:setValue(table.concat({names1, first or "", table.concat(newnames, "+")}, "|"))
			return true
		end,
		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.TargetConfirmed then
				local use = ctx.original_data:toCardUse()
				for _, to in sgs.qlist(use.to) do
					if not to:isKongcheng() and room:askForSkillInvoke(use.from, "EXCard_FLDF", ctx.original_data) then
						room:setEmotion(player, "/excard2014/EXCard_FLDF")
						room:askForDiscard(to, skill:objectName(), 1, 1, false, true, "#EXCard_FLDF_Skill_discard")
					end
				end
				return false
			end
			local death = ctx.original_data:toDeath()
			local damage = death.damage
			local victim = death.who or ctx.invoker
			local parts = ctx.extra_data:toString():split("|")
			local names1, first = parts[1], parts[2]
			if first == "" then first = nil end
			local newnames = {}
			if parts[3] and parts[3] ~= "" then newnames = parts[3]:split("+") end
			room:setEmotion(victim, "/excard2014/EXCard_FLDF")
			local choice1 = room:askForGeneral(victim, names1, first) or first
			local choice2
			if victim:getGeneral2() then
				table.removeTable(newnames, { choice1 })
				local second = newnames[1]
				local names2
				if #newnames > 21 then
					names2 = table.concat(newnames, "+", 1, 21)
				else
					names2 = table.concat(newnames, "+")
				end
				choice2 = room:askForGeneral(victim, names2, second) or second
			end

			room:changeHero(victim, choice1, true, not choice2, false, false)
			if choice2 then room:changeHero(victim, choice2, true, true, true, false) end
			room:revivePlayer(victim)
			if not sgs.GetConfig("EnableHegemony", false) then
				if damage.from:getRole() == "lord" then
					room:setPlayerProperty(victim, "role", sgs.QVariant("loyalist"))
				else
					room:setPlayerProperty(victim, "role", sgs.QVariant(damage.from:getRole()))
				end
			end
			room:setPlayerProperty(victim, "kingdom", sgs.QVariant(damage.from:getKingdom()))
			room:setPlayerProperty(victim, "faceup", sgs.QVariant(true))
			room:setPlayerProperty(victim, "chained", sgs.QVariant(false))
			room:resetAI(victim)
			room:updateStateItem()
			local log = sgs.LogMessage()
			log.type = "#EXCard_FLDF"
			log.from = damage.from
			log.to:append(victim)
			log.arg = "EXCard_FLDF"
			room:sendLog(log)
			room:setTag("EXCard_FLDF_effected", sgs.QVariant(victim:objectName()))
			return false
		end,
	}

	EXCard_FLDF = sgs.CreateWeapon{
		name = "EXCard_FLDF",
		class_name = "EXCard_FLDF",
		suit = sgs.Card_Spade,
		number = 2,
		range = 2,
		on_install = function(self, player)
			local room = player:getRoom()
			if player:getSkillInstanceIds("EXCard_FLDF_Skill"):isEmpty() then
				room:attachSkillToPlayer(player, "EXCard_FLDF_Skill")
			end
		end,
		on_uninstall = function(self, player)
		end,
	}

	local fldf = EXCard_FLDF:clone()
	fldf:setParent(extension)
	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("EXCard_FLDF_Skill") then skills:append(EXCard_FLDF_Skill) end
	sgs.Sanguosha:addSkills(skills)
end

if EquipCard_typs == 1 then
	EXCard_TPYS_Skill = sgs.CreateTriggerSkillV2{
		name = "EXCard_TPYS_Skill",
		events = { sgs.DamageInflicted, sgs.CardsMoveOneTime },
		hide_skill = true,
		can_trigger = function(skill, event, room, player, data)
			if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
				return false
			end
			if event == sgs.DamageInflicted then
				local damage = data:toDamage()
				if player:hasArmorEffect("EXCard_TPYS") and damage.nature ~= sgs.DamageStruct_Normal then
					return skill:objectName()
				end
			elseif event == sgs.CardsMoveOneTime then
				if player:hasFlag("EXCard_TPYS_uninstall") then
					return skill:objectName()
				end
			end
			return false
		end,
		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.DamageInflicted then
				local damage = ctx.original_data:toDamage()
				local log = sgs.LogMessage()
				log.type = "#EXCard_TPYS"
				log.from = damage.to
				room:sendLog(log)
				room:setEmotion(damage.to, "/excard2014/EXCard_TPYS")
				return true
			elseif event == sgs.CardsMoveOneTime then
				room:setPlayerFlag(player, "-EXCard_TPYS_uninstall")
				local move = ctx.original_data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getEngineCard(id):getClassName() == "EXCard_TPYS" then
							player:drawCards(2)
							if player:getHp() > 1 then
								room:loseHp(player, 1, true, player, skill:objectName())
							end
							break
						end
					end
				end
			end
			return false
		end,
	}

	EXCard_TPYS_MaxCardSkill = sgs.CreateMaxCardsSkillV2{
		name = "EXCard_TPYS_MaxCardSkill",
		holder_selector = sgs.CorrectSkill_System,
		correct_func = function(skill, ctx)
			local player = ctx:getPrimary()
			if not player then return nil end
			local players = player:getAliveSiblings()
			players:append(player)
			local extra = 0
			for _, p1 in sgs.qlist(players) do
				if p1:hasArmorEffect("EXCard_TPYS") and player:getKingdom() == p1:getKingdom() then
					for _, p2 in sgs.qlist(players) do
						if p1:getKingdom() == p2:getKingdom() then extra = extra + 1 end
					end
				end
			end
			if extra > 0 and player:hasArmorEffect("EXCard_TPYS") then return extra end
			return nil
		end,
	}

	EXCard_TPYS = sgs.CreateArmor{
		name = "EXCard_TPYS",
		class_name = "EXCard_TPYS",
		suit = sgs.Card_Spade,
		number = 2,
		on_install = function(self, player)
			local room = player:getRoom()
			if player:getSkillInstanceIds("EXCard_TPYS_Skill"):isEmpty() then
				room:attachSkillToPlayer(player, "EXCard_TPYS_Skill")
			end
		end,
		on_uninstall = function(self, player)
			local room = player:getRoom()
			room:setPlayerFlag(player, "EXCard_TPYS_uninstall")
		end,
	}

	local tpys = EXCard_TPYS:clone()
	tpys:setParent(extension)
	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("EXCard_TPYS_Skill") then skills:append(EXCard_TPYS_Skill) end
	if not sgs.Sanguosha:getSkill("EXCard_TPYS_MaxCardSkill") then skills:append(EXCard_TPYS_MaxCardSkill) end
	sgs.Sanguosha:addSkills(skills)
end


if TrickCard_wwjz == 1 then
	-- 保留 legacy：全域「任一持牌者可響應他人【殺】」觸發技；V2 觸發需持有者技能實例，
	-- 卡牌包無合適的實例掛載點（非裝備技能、非武將技能），而 global=true 不自動建立實例。
	EXCard_WWJZ_Skill = sgs.CreateTriggerSkill{
		name = "EXCard_WWJZ_Skill",
		events = { sgs.TargetConfirmed, sgs.SlashMissed, sgs.SlashEffected, sgs.TurnBroken, sgs.StageChange },
		global = true,
		can_trigger = function(self, target)
			return target and target:isAlive()
		end,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.TargetConfirmed then
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") and use.from and not use.to:contains(player) and use.from:objectName() ~= player:objectName()
					and not use.to:contains(use.from) and use.card:getSkillName() ~= "EXCard_WWJZ" and not use.card:hasFlag("EXCard_WWJZ_success") then
					local has
					for _, c in sgs.qlist(player:getHandcards()) do
						if c:isKindOf("EXCard_WWJZ") then has = true end
					end
					if not has then return end
					room:setPlayerFlag(use.from, "EXCard_WWJZ_Wei")
					room:setTag("EXCard_WWJZ_data", data)
					local card = room:askForUseCard(player, "EXCard_WWJZ", string.format("#EXCard_WWJZ:%s", use.from:objectName()))
					room:setPlayerFlag(use.from, "-EXCard_WWJZ_Wei")
					room:removeTag("EXCard_WWJZ_data")
				end
			elseif event == sgs.SlashMissed then
				local slash = data:toSlashEffect()
				if table.contains(slash.slash:getSkillNames(), "EXCard_WWJZ") then
					local use = room:getTag("EXCard_WWJZ_data"):toCardUse()
					room:setCardFlag(use.card, "EXCard_WWJZ_success")
				end
			elseif event == sgs.SlashEffected then
				local slash = data:toSlashEffect()
				if slash.slash:hasFlag("EXCard_WWJZ_success") then
					local msg = sgs.LogMessage()
					msg.type = "$EXCard_WWJZ_effect"
					msg.from = slash.from
					msg.to:append(slash.to)
					msg.card_str = slash.slash:toString()
					room:sendLog(msg)
					return true
				end
			elseif event == sgs.TurnBroken or event == sgs.StageChange then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerFlag(p, "-EXCard_WWJZ_Wei")
				end
			end
		end
	}

	EXCard_WWJZ = sgs.CreateTrickCard{
		name = "EXCard_WWJZ",
		class_name = "EXCard_WWJZ",
		suit = 1,
		number = 1,
		target_fixed = false,
		can_recast = true,
		subtype = "single_target_trick",
		filter = function(self, targets, to_select, player)
			return sgs.Sanguosha:getCurrentCardUsePattern() == self:objectName() and to_select:hasFlag("EXCard_WWJZ_Wei") and to_select:objectName() ~= player:objectName()
		end,
		feasible = function(self, targets, player)
			return #targets == (sgs.Sanguosha:getCurrentCardUsePattern() == self:objectName() and 1 or 0)
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_nullified = function(self, target)
			local room = target:getRoom()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p, "-EXCard_WWJZ_Wei")
			end
		end,
		about_to_use = function(self, room, use)
			if use.to:isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, use.from:objectName())
				reason.m_skillName = self:objectName()
				room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason)
				use.from:broadcastSkillInvoke("@recast")

				local log = sgs.LogMessage()
				log.type = "#Card_Recast"
				log.from = use.from
				log.card_str = use.card:toString()
				room:sendLog(log)
				use.from:drawCards(1)
			else
				self:cardOnUse(room, use)
			end
		end,
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p, "-EXCard_WWJZ_Wei")
			end
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("_EXCard_WWJZ")
			room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to), false)
		end,
	}

	local wwjz = EXCard_WWJZ:clone(1, 2)
	wwjz:setParent(extension)
	local wwjz = EXCard_WWJZ:clone(3, 3)
	wwjz:setParent(extension)

	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("EXCard_WWJZ_Skill") then skills:append(EXCard_WWJZ_Skill) end
	sgs.Sanguosha:addSkills(skills)

end

if TrickCard_zjzb == 1 then
	EXCard_ZJZB = sgs.CreateTrickCard{
		name = "EXCard_ZJZB",
		class_name = "EXCard_ZJZB",
		suit = 1,
		number = 1,
		target_fixed = false,
		can_recast = true,
		subtype = "single_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select, player)
			local total_num = 1
			if player then
				total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
			end
			return not to_select:isKongcheng() and to_select:objectName() ~= player:objectName() and #targets < total_num
		end,
		feasible = function(self, targets, player)
			local total_num = 1
			if player then
				total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
			end
			return #targets >= 0 and #targets <= total_num
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		about_to_use = function(self, room, use)
			if use.to:isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, use.from:objectName())
				reason.m_skillName = self:objectName()
				room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason)
				use.from:broadcastSkillInvoke("@recast")

				local log = sgs.LogMessage()
				log.type = "#Card_Recast"
				log.from = use.from
				log.card_str = use.card:toString()
				room:sendLog(log)
				use.from:drawCards(1)
			else
				self:cardOnUse(room, use)
			end
		end,
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			if room:askForChoice(effect.from, self:objectName(), "ZJZB_showhandcards+ZJZB_showrole") == "ZJZB_showhandcards" then
				room:showAllCards(effect.to, effect.from)
				local log = sgs.LogMessage()
				log.type = "#ZJZB_showhandcards"
				log.from = effect.from
				log.to:append(effect.to)
				room:sendLog(log)
			else
				room:askForChoice(effect.from,  self:objectName() .. "_show", "ZJZB_showrole_" .. effect.to:getRole() .. "+ZJZB_confirm")
				room:setPlayerMark(effect.to, string.format("EXCard_ZJZB_%s_%s", effect.from:objectName(), effect.to:objectName()), 1)
				local log = sgs.LogMessage()
				log.type = "#ZJZB_showrole"
				log.from = effect.from
				log.to:append(effect.to)
				room:sendLog(log)
			end
		end,
	}

	local zjzb = EXCard_ZJZB:clone(1, 3)
	zjzb:setParent(extension)
	local zjzb = EXCard_ZJZB:clone(1, 4)
	zjzb:setParent(extension)
end

if TrickCard_yjjg == 1 then
	EXCard_YJJG = sgs.CreateTrickCard{
		name = "EXCard_YJJG",
		class_name = "EXCard_YJJG",
		suit = 2,
		number = 9,
		target_fixed = false,
		can_recast = false,
		subtype = "single_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select, player)
			local total_num = 1
			if player then
				total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
			end
			return to_select:objectName() ~= player:objectName() and #targets < total_num
		end,
		feasible = function(self, targets, player)
			local total_num = 1
			if player then
				total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
			end
			return #targets <= total_num and #targets > 0
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_effect = function(self, effect)
			effect.to:drawCards(1)
			effect.from:drawCards(3)
		end,
	}

	local yjjg = EXCard_YJJG:clone()
	yjjg:setParent(extension)
end

if TrickCard_yydl == 1 then
	EXCard_YYDL = sgs.CreateTrickCard{
		name = "EXCard_YYDL",
		class_name = "EXCard_YYDL",
		suit = 2,
		number = 9,
		target_fixed = false,
		can_recast = false,
		subtype = "multiple_target_trick",
		subclass = sgs.LuaTrickCard_LuaTrickCard_TypeNormal,
		filter = function(self, targets, to_select, player)
			return true
		end,
		feasible = function(self, targets, player)
			return #targets > 0
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_use = function(self, room, source, targets)
			for _, t in ipairs(targets) do
				room:cardEffect(self, source, t)
			end
			for _, t in ipairs(targets) do
				if t:hasFlag("EXCard_YYDL_effected") and not t:isNude() then
					local num = math.min(t:getCardCount(), 2)
					room:askForDiscard(t, self:objectName(), num, num, false, true)
				end
			end
			if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
				room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
			end
		end,
		on_effect = function(self, effect)
			effect.to:drawCards(2)
			effect.to:setFlags("EXCard_YYDL_effected")
		end,
	}

	local yydl = EXCard_YYDL:clone(3, 4)
	yydl:setParent(extension)
	local yydl = EXCard_YYDL:clone(2, 11)
	yydl:setParent(extension)
end

if TrickCard_dhls == 1 then
	EXCard_DHLS = sgs.CreateTrickCard{
		name = "EXCard_DHLS",
		class_name = "EXCard_DHLS",
		suit = 3,
		number = 7,
		target_fixed = false,
		can_recast = true,
		subtype = "multiple_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select, player)
			return to_select:objectName() ~= player:objectName() and #targets < 2
		end,
		feasible = function(self, targets, player)
			return #targets == 2 or #targets == 0
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		about_to_use = function(self, room, use)
			if use.to:isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, use.from:objectName())
				reason.m_skillName = self:objectName()
				room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason)
				use.from:broadcastSkillInvoke("@recast")

				local log = sgs.LogMessage()
				log.type = "#Card_Recast"
				log.from = use.from
				log.card_str = use.card:toString()
				room:sendLog(log)
				use.from:drawCards(1)
			else
				self:cardOnUse(room, use)
			end
		end,
		on_use = function(self, room, source, targets)
			targets[1]:setFlags("EXCard_DHLS_target")
			targets[2]:setFlags("EXCard_DHLS_target")
			for _, t in ipairs(targets) do
				room:cardEffect(self, source, t)
			end
			if targets[1]:hasFlag("EXCard_DHLS_do") and targets[2]:hasFlag("EXCard_DHLS_do") and targets[1]:isAlive() and targets[2]:isAlive() then
				room:swapSeat(targets[1], targets[2])
				local log = sgs.LogMessage()
				log.type = "#EXCard_DHLS"
				log.from = targets[1]
				log.to:append(targets[2])
				room:sendLog(log)
			end
			targets[1]:setFlags("-EXCard_DHLS_do")
			targets[2]:setFlags("-EXCard_DHLS_do")
			targets[1]:setFlags("-EXCard_DHLS_target")
			targets[2]:setFlags("-EXCard_DHLS_target")
			if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
				room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
			end
		end,
		on_effect = function(self, effect)
			effect.to:setFlags("EXCard_DHLS_do")
		end,
	}

	local dhls = EXCard_DHLS:clone()
	dhls:setParent(extension)
end

if TrickCard_tjbz == 1 then
	EXCard_TJBZ = sgs.CreateTrickCard{
		name = "EXCard_TJBZ",
		class_name = "EXCard_TJBZ",
		suit = 2,
		number = 6,
		target_fixed = true,
		can_recast = false,
		subtype = "global_effect",
		subclass = sgs.LuaTrickCard_TypeGlobalEffect,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_effect = function(self, effect)
			if effect.to:getHandcardNum() < 6 then
				effect.to:drawCards(6 - effect.to:getHandcardNum())
			end
		end,
	}

	local tjbl = EXCard_TJBZ:clone()
	tjbl:setParent(extension)
end

--------------------------------------------------

sgs.LoadTranslationTable{
	["excard2014"] = "下限再突破",

	["EXCard_SJLRD"] = "三尖两刃刀",
	[":EXCard_SJLRD"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：每当你使用【杀】对目标角色造成伤害后，可弃置一张手牌，并对该角色距离1的另一名角色造成1点伤害。",
	["#EXCard_SJLRD_chosen"] = "【三尖两刃刀】你可以选择一角色，对其造成1点伤害。",
	["#EXCard_SJLRD_Skill_dis"] = "【三尖两刃刀】你可以弃置一张手牌。",

	["EXCard_WLJ"] = "吴六剑",
	[":EXCard_WLJ"] = "装备牌·武器\
	攻击范围：2\
	攻击效果：出牌阶段N次，选择任意数量的角色，使用【杀】与其他角色计算距离时-1。",
	["@EXCard_WLJ"] = "吴六剑",

	["EXCard_FLDF"] = "飞龙夺凤",
	[":EXCard_FLDF"] = "装备牌·武器\
	攻击范围：2\
	攻击效果：当你使用【杀】指定一名角色为目标后，你可令该角色弃置一张牌。\
	你使用【杀】杀死一名角色后，你可令该角色的使用者选择是否从未使用的武将牌中选择一张与你势力相同的武将牌重新加入游戏。",
	["#EXCard_FLDF"] = "%from 发动了 %arg ， %to 闪亮登场！",
	["#EXCard_FLDF_Skill_discard"] = " 因<font color = 'gold'><b>【飞龙夺凤】</b></font>的效果，你需要弃置一张手牌。",
	["EXCard_FLDF_revive"] = "飞龙夺凤",
	["EXCard_FLDF_Skill"] = "飞龙夺凤",

	["EXCard_TPYS"] = "太平要术",
	[":EXCard_TPYS"] = "装备牌·防具\
	防具效果：防止你受到的所有属伤害。全场每有一名与你势力相同的角色存活，你手牌上限+1；当你失去装备牌区的【太平要术】时，你摸两张牌，然后若你的体力值大于1，你失去1点体力。",
	["#EXCard_TPYS"] = "%from 的防具【<font color= 'gold'><b>太平要术</b></font>】效果被触发，属性伤害无效。",

	["EXCard_WWJZ"] = "围魏救赵",
	[":EXCard_WWJZ"] = "锦囊牌\
	出牌时机：每当一名角色使用【杀】指定目标后\
	使用目标：使用【杀】的角色\
	作用效果：视为你对目标使用一张【杀】，若目标打出【闪】，则目标使用的【杀】无效。\
	重铸：出牌阶段，你可将此牌置入弃牌堆，然后摸一张牌",
	["#EXCard_WWJZ"] = "你可以对 <font color = 'red'>%src</font> 使用<font color = 'gold'>【围魏救赵】</font>",
	["$EXCard_WWJZ_effect"] = "因<font color = 'gold'><b>【围魏救赵】</b></font>的效果，%from 对 %to 使用的 %card 无效",

	["EXCard_ZJZB"] = "知己知彼",
	[":EXCard_ZJZB"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一名其他角色\
	作用效果：观看目标角色的身份牌或手牌。\
	重铸：出牌阶段，你可将此牌置入弃牌堆，然后摸一张牌",
	["ZJZB_showhandcards"] = "观看他手牌",
	["ZJZB_showrole"] = "观看他身份牌",
	["ZJZB_showrole_rebel"] = "他的身份是反贼",
	["ZJZB_showrole_lord"] = "他的身份是主公",
	["ZJZB_showrole_loyalist"] = "他的身份是忠臣",
	["ZJZB_showrole_renegade"] = "他的身份是内奸",
	["ZJZB_confirm"] = "没了",
	["#ZJZB_showhandcards"] = "%from 选择观看 %to 的<font color = 'gold'><b>【手牌】</b></font>",
	["#ZJZB_showrole"] = "%from 选择观看 %to 的<font color = 'gold'><b>【身份牌】</b></font>",

	["EXCard_YJJG"] = "远交近攻",
	[":EXCard_YJJG"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一名其他角色\
	作用效果：目标角色摸一张牌，然后你摸三张牌。",

	["EXCard_YYDL"] = "以逸待劳",
	[":EXCard_YYDL"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：任意角色\
	作用效果：目标角色摸两张牌，然后弃置两张牌。",

	["EXCard_DHLS"] = "调虎离山",
	[":EXCard_DHLS"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：两名其他角色\
	作用效果：两名目标角色交换座位。\
	重铸：出牌阶段，你可将此牌置入弃牌堆，然后摸一张牌",
	["#EXCard_DHLS"] = "%from 与 %to 交换了座位",
	
	["EXCard_TJBZ"] = "天降宝札",
	[":EXCard_TJBZ"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：所有角色\
	作用效果：手牌数不足6张的角色，将手牌补至6张。",
}
