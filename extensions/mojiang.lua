local extension = sgs.Package("mojiang", sgs.Package_GeneralPack)

sgs.LoadTranslationTable {
	["mojiang"] = "极略魔武将",
}

do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "sgk_magic")
	config.kingdom_colors["sgk_magic"] = "#642222"
end

sgs.LoadTranslationTable {
	["sgk_magic"] = "魔",
}

sy_quanqing_USECARD = sgs.CreateTriggerSkillV2 {
	name = "sy_quanqing_USECARD",
	events = {},
}

function Nil2Int(nil_value)
	if nil_value == false or nil_value == nil or nil_value == "" or nil_value == 0 or nil_value == "0" then
		return 0
	else
		return nil_value
	end
end

--V2 全局技能以隱藏技能名掛到所有武將；
--晚於本擴展加載的武將或換將後於結算時補掛 acquired 實例。
local sy_global_skill_names = { "#sy_old_clear", "#sy_global_draw", "#sy_yinzi_clear" }
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local sy_ensuring_globals = false
local function sy_ensure_global_instances(room)
	if sy_ensuring_globals then return end
	if room:getTag("sy_globals_ensured"):toBool() then return end
	sy_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		sy_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("sy_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(sy_global_skill_names) do
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
		room:setTag("sy_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("sy_globals_ensured", sgs.QVariant(true))
	sy_ensuring_globals = false
end

sy_old_clear = sgs.CreateTriggerSkillV2 {
	name = "#sy_old_clear",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = { sgs.EventPhaseStart, sgs.EventLoseSkill },
	on_record = function(skill, event, room, player, ctx)
		sy_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			local who = room:getCurrent()
			if who and who:getPhase() == sgs.Player_Start and not who:getPile("you"):isEmpty() then
				return skill:objectName()
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "sy_tianyou" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not pe:getPile("you"):isEmpty() then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local who = room:getCurrent()
			if who and who:getPhase() == sgs.Player_Start then
				local you = who:getPile("you")
				if not you:isEmpty() then
					local idx = you:first()
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, who:objectName(), "sy_tianyou", "")
					local card = sgs.Sanguosha:getCard(idx)
					room:throwCard(card, reason, nil)
				end
			end
		elseif event == sgs.EventLoseSkill then
			if ctx.original_data:toSkillChange().skillName == "sy_tianyou" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					local you = pe:getPile("you")
					if not you:isEmpty() then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, pe:objectName(), "sy_tianyou", "")
						local card = sgs.Sanguosha:getCard(you:first())
						room:throwCard(card, reason, nil)
					end
				end
			end
		end
		return false
	end,
}

--防止成为目标（天佑）
sy_pro = sgs.CreateProhibitSkillV2 {
	name = "#sy_pro",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "secondary.pile:you" },
	is_prohibited = function(self, ctx)
		local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
		local you = to:getPile("you")
		local X = you:length()
		if X > 0 then
			local youid = you:first()
			local youcard = sgs.Sanguosha:getCard(youid)
			return (to:objectName() ~= from:objectName())
				and card:sameColorWith(youcard)
				and (not card:isKindOf("Peach"))
				and (not card:isKindOf("Analeptic"))
				and card:getTypeId() ~= sgs.Card_TypeSkill
				and to:getPhase() == sgs.Player_NotActive
		else
			return false
		end
	end,
}

--全局摸牌（舊 CreateDrawCardsSkill 實為 DrawNCards 觸發技包裝，此處以 V2 觸發技等價實現）
sy_global_draw = sgs.CreateTriggerSkillV2 {
	name = "#sy_global_draw",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = { sgs.DrawNCards },
	on_record = function(skill, event, room, player, ctx)
		sy_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then
			return false
		end
		local x = 0
		for _, _name in sgs.list(player:getMarkNames()) do
			if string.find(_name, "mcc_phasedraw_num_") then
				x = x - player:getMark(_name)
			end
		end
		if Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) > 0 then
			x = x + Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) - 2
		end
		draw.num = draw.num + x
		data:setValue(draw)
		return false
	end,
}

--全局出杀（全局規則不依附持有者實例，用 CorrectSkill_System 每次評估一次）
sy_global_targetMod = sgs.CreateTargetModSkillV2 {
	name = "#sy_global_targetMod",
	pattern = ".",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "mark:mcc_defaultslash_num", "mark:mcc_defaultslash_num_" },
	correct_func = function(self, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_Residue then
			return nil
		end
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		if not from or not card or not card:isKindOf("Slash") then
			return nil
		end
		local n = 0
		n = n - from:getMark("mcc_defaultslash_num_")
		if from:hasSkill("sy_duzun") or from:hasSkill("sy_longbian") then
			n = n + from:getMark("mcc_defaultslash_num")
		end
		return n
	end,
}

--淫恣的標記清理部分拆為全局隱藏技（原舊版藉全域 triggerable 在無持有者時仍生效）
sy_yinzi_clear = sgs.CreateTriggerSkillV2 {
	name = "#sy_yinzi_clear",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = { sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill },
	on_record = function(skill, event, room, player, ctx)
		sy_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				return skill:objectName()
			end
		elseif event == sgs.Death then
			return skill:objectName()
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "sy_yinzi" then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				pe:removeTag("yinzi_obtaincard")
				pe:removeTag("yinzi_hprecover")
			end
		elseif event == sgs.Death then
			local death = ctx.original_data:toDeath()
			death.who:removeTag("yinzi_obtaincard")
			death.who:removeTag("yinzi_hprecover")
			if death.who:hasSkill("sy_yinzi") then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:removeTag("yinzi_obtaincard")
					pe:removeTag("yinzi_hprecover")
				end
			end
		elseif event == sgs.EventLoseSkill then
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				pe:removeTag("yinzi_obtaincard")
				pe:removeTag("yinzi_hprecover")
			end
		end
		return false
	end,
}

local sy_hiddenskills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_old_clear") then
	sy_hiddenskills:append(sy_old_clear)
end
if not sgs.Sanguosha:getSkill("#sy_pro") then
	sy_hiddenskills:append(sy_pro)
end
if not sgs.Sanguosha:getSkill("sy_quanqing_USECARD") then
	sy_hiddenskills:append(sy_quanqing_USECARD)
end
if not sgs.Sanguosha:getSkill("#sy_global_draw") then
	sy_hiddenskills:append(sy_global_draw)
end
if not sgs.Sanguosha:getSkill("#sy_global_targetMod") then
	sy_hiddenskills:append(sy_global_targetMod)
end
if not sgs.Sanguosha:getSkill("#sy_yinzi_clear") then
	sy_hiddenskills:append(sy_yinzi_clear)
end
sgs.Sanguosha:addSkills(sy_hiddenskills)

-- V2 觸發技需要持有者實例：全局規則技掛到所有武將作為 bootstrap；
-- 加載順序更晚的武將/換將在結算時由 sy_ensure_global_instances 補掛。
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	for _, skill_name in ipairs(sy_global_skill_names) do
		gen:addSkill(skill_name)
	end
end

sgs.LoadTranslationTable {
	["sy_quanqing_USECARD"] = "权倾",
	["#sy_second_stage"] = '%from 暴怒了！即将进入<font color = "yellow"><b>三英</b></font>·<font color = "pink"><b>第二阶段</b></font>！',
}

--魔吕布
mo_lvbu = sgs.General(extension, "mo_lvbu", "sgk_magic", 4, true)

--[[
	技能名：神威
	相关武将：魔吕布
	技能描述：锁定技，你攻击范围内的其他角色手牌上限-X（X为你对其他角色造成过伤害的回合数+1）。
	引用：mo_shenwei
]]
--
mo_shenwei = sgs.CreateMaxCardsSkillV2 {
	name = "mo_shenwei",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not player then return false end
		local n = 0
		for _, pe in sgs.qlist(player:getAliveSiblings()) do
			if pe:hasSkill(skill:objectName()) and pe:inMyAttackRange(player) then
				n = n - (pe:getMark("@mo_shenwei") + 1)
			end
		end
		return n
	end,
}

--每回合首次對其他角色造成傷害時記一個 @mo_shenwei mark（計造成過傷害的回合數）
mo_shenwei_record = sgs.CreateTriggerSkillV2 {
	name = "#mo_shenwei",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
				and damage.to and damage.to:objectName() ~= player:objectName()
				and player:hasSkill("mo_shenwei") and not player:hasFlag("mo_shenwei_damaged") then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive and player:hasFlag("mo_shenwei_damaged") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damage then
			room:setPlayerFlag(player, "mo_shenwei_damaged")
			room:addPlayerMark(player, "@mo_shenwei")
		elseif event == sgs.EventPhaseChanging then
			room:setPlayerFlag(player, "-mo_shenwei_damaged")
		end
		return false
	end,
}

--[[
	技能名：修罗
	相关武将：魔吕布
	技能描述：当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。
	引用：sy_xiuluo
]]
--

--[[
	技能名：神戟
	相关武将：魔吕布
	技能描述：锁定技，你使用的【杀】目标上限数+2。
	引用：sy_shenji
]]
--

--[[
	技能名：无双
	相关武将：魔吕布
	技能描述：锁定技，你使用的点数为奇数的牌，或其他角色对你使用的点数为奇数的【决斗】对其他角色造成的伤害值为3。
	引用：mo_wushuang（魔將版；三英共用技 sy_wushuang 唔郁）
]]
--
mo_wushuang = sgs.CreateTriggerSkillV2 {
	name = "mo_wushuang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.TargetConfirming },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageCaused then return false end
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not (damage.card and math.fmod(damage.card:getNumber(), 2) ~= 0) then return false end
		if damage.from and damage.from:objectName() == player:objectName()
			and damage.to and damage.to:objectName() ~= player:objectName() then
			return skill:objectName()
		end
		if damage.card:isKindOf("Duel") and damage.to and damage.to:objectName() == player:objectName()
			and damage.card:getTag("mo_wushuang_target"):toBool() then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		--記錄其他角色對持有者使用嘅【決鬥】
		local use = ctx.original_data:toCardUse()
		if use.card and use.card:isKindOf("Duel") and use.from and use.from:objectName() ~= player:objectName()
			and use.to and use.to:contains(player) then
			use.card:setTag("mo_wushuang_target", sgs.QVariant(true))
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke("sy_wushuang")
		if damage.to then
			room:doAnimate(1, player:objectName(), damage.to:objectName())
		end
		damage.damage = 3
		ctx.original_data:setValue(damage)
		return false
	end,
}

--[[
	技能名：修罗
	相关武将：魔吕布
	技能描述：当你使用【杀】或普通锦囊牌指定目标后，或当你成为这些牌的唯一目标后，你可以摸一张牌，然后此牌效果改为【决斗】。
	引用：mo_xiuluo（魔將版雙向；三英共用技 sy_xiuluo 唔郁）
]]
--
mo_xiuluo = sgs.CreateTriggerSkillV2 {
	name = "mo_xiuluo",
	events = { sgs.TargetSpecified, sgs.TargetConfirming },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.from and use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick())) then return false end
		if event == sgs.TargetSpecified then
			if use.from:objectName() == player:objectName() and use.to:length() > 0 then
				return skill:objectName()
			end
		elseif event == sgs.TargetConfirming then
			if use.from:objectName() ~= player:objectName() and use.to:contains(player) and use.to:length() == 1 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		player:drawCards(1, skill:objectName())
		local ini_card = use.card
		if use.card:isKindOf("Duel") then
			room:broadcastSkillInvoke("sy_xiuluo")
		else
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
			if not use.card:isVirtualCard() then
				duel:addSubcard(use.card)
			elseif use.card:subcardsLength() > 0 then
				for _, id in sgs.qlist(use.card:getSubcards()) do
					duel:addSubcard(id)
				end
			end
			duel:setSkillName(skill:objectName())
			use.card = duel
			data:setValue(use)
			local msg = sgs.LogMessage()
			msg.from = player
			msg.to:append(use.from)
			msg.type = "#XiuluoDuel"
			msg.arg = skill:objectName()
			msg.card_str = ini_card:toString()
			room:sendLog(msg)
			room:broadcastSkillInvoke("sy_xiuluo")
		end
		return false
	end,
}

--[[
	技能名：神戟
	相关武将：魔吕布
	技能描述：锁定技，你使用的【杀】目标上限数+2。
	引用：mo_shenji（魔將版無子牌限制；三英共用技 sy_shenji 唔郁）
]]
--
mo_shenji = sgs.CreateTargetModSkillV2 {
	name = "mo_shenji",
	pattern = ".",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "skill:mo_shenji" },
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		local card = ctx:getCard()
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget
			and player and player:hasSkill(skill:objectName())
			and card and card:isKindOf("Slash") then
			return 2
		end
		return false
	end,
}

mo_shenjiAudio = sgs.CreateTriggerSkillV2 {
	name = "#mo_shenji",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreCardUsed, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from and use.from:hasSkill("mo_shenji") and use.to and use.to:length() >= 2 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.PreCardUsed then
			local use = ctx.original_data:toCardUse()
			room:sendCompulsoryTriggerLog(use.from, "mo_shenji")
			room:notifySkillInvoked(use.from, "mo_shenji")
		elseif event == sgs.CardUsed then
			room:broadcastSkillInvoke("sy_shenji")
		end
		return false
	end,
}

mo_lvbu:addSkill("mo_wushuang")
mo_lvbu:addSkill("mashu")
mo_lvbu:addSkill(mo_xiuluo)
mo_lvbu:addSkill(mo_shenwei)
mo_lvbu:addSkill(mo_shenwei_record)
mo_lvbu:addSkill(mo_shenji)
mo_lvbu:addSkill(mo_shenjiAudio)
extension:insertRelatedSkills("mo_shenwei", "#mo_shenwei")
extension:insertRelatedSkills("mo_shenji", "#mo_shenji")

sgs.LoadTranslationTable {
	["mo_lvbu"] = "魔吕布",
	["#mo_lvbu"] = "暴怒战神",
	["~mo_lvbu"] = "我在地狱等着你们！",
	["mo_shenwei"] = "神威",
	["#mo_shenwei"] = "神威",
	["@mo_shenwei"] = "神威",
	[":mo_shenwei"] = "锁定技，你攻击范围内的其他角色手牌上限-X（X为你对其他角色造成过伤害的回合数+1）。",
	["sy_shenwei"] = "神威",
	["#sy_shenwei"] = "神威",
	["$sy_shenwei"] = "唔唔唔唔唔唔——！！！",
	[":sy_shenwei"] = "锁定技，与你距离为1的其他角色的手牌上限-1。",
	["mo_wushuang"] = "无双",
	[":mo_wushuang"] = "锁定技，你使用的点数为奇数的牌，或其他角色对你使用的点数为奇数的【决斗】对其他角色造成的伤害值为3。",
	["sy_wushuang"] = "无双",
	["$sy_wushuang1"] = "你的人头，我要定了！",
	["$sy_wushuang2"] = "这就让你去死！",
	[":sy_wushuang"] = "锁定技，你使用点数为奇数的牌对其他角色造成的伤害为3点。",
	["mo_shenji"] = "神戟",
	["#mo_shenji"] = "神戟",
	[":mo_shenji"] = "锁定技，你使用的【杀】目标上限数+2。",
	["sy_shenji"] = "神戟",
	["$sy_shenji"] = "战神之力，开！",
	[":sy_shenji"] = "锁定技，你使用【杀】的目标上限+2。",
	["mo_xiuluo"] = "修罗",
	[":mo_xiuluo"] = "当你使用【杀】或普通锦囊牌指定目标后，或当你成为这些牌的唯一目标后，你可以摸一张牌，然后此牌效果改为【决斗】。",
	["sy_xiuluo"] = "修罗",
	["$sy_xiuluo"] = "不可饶恕，不可饶恕！",
	[":sy_xiuluo"] = "当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。",
	["#XiuluoDuel"] = '由于 %from 的“%arg”效果，%to 对 %from 使用的 %card 的效果被改为 <font color = "yellow"><b>决斗</b></font>',
	["designer:mo_lvbu"] = "极略三国",
	["illustrator:mo_lvbu"] = "极略三国",
	["cv:mo_lvbu"] = "极略三国",
}

--魔董卓
mo_dongzhuo = sgs.General(extension, "mo_dongzhuo", "sgk_magic", 4, true)

--[[
	技能名：纵欲
	相关武将：魔董卓
	技能描述：锁定技，当你于出牌阶段使用一张锦囊牌后，你视为使用一张不计入次数的【酒】。
	引用：sy_zongyu
]]
--

mo_dongzhuo:addSkill("sy_zongyu")

--[[
	技能名：凌虐
	相关武将：魔董卓
	技能描述：当你造成伤害值不小于2的伤害时，你可以摸两张牌并加1点体力上限。
	引用：sy_lingnue
]]
--

mo_dongzhuo:addSkill("sy_lingnue")

--[[
	技能名：暴政
	相关武将：魔董卓
	技能描述：锁定技，其他角色的摸牌阶段结束时，其选择一项：1.交给你一张锦囊牌；2.你视为对其使用一张无距离限制的【杀】。
	引用：sy_baozheng
]]
--

mo_dongzhuo:addSkill("sy_baozheng")

--[[
	技能名：逆施
	相关武将：魔董卓
	技能描述：锁定技，当你受到其他角色造成的伤害时，伤害来源选择一项：1.弃置装备区内的所有牌；2.你视为对其使用一张无距离限制的【杀】。
	引用：sy_nishi
]]
--

mo_dongzhuo:addSkill("sy_nishi")

--[[
	技能名：横行
	相关武将：魔董卓
	技能描述：锁定技，你于出牌阶段外造成伤害时，该伤害值+1。
	引用：sy_hengxing
]]
--

mo_dongzhuo:addSkill("sy_hengxing")

sgs.LoadTranslationTable {
	["mo_dongzhuo"] = "魔董卓",
	["#mo_dongzhuo"] = "狱魔王",
	["~mo_dongzhuo"] = "那酒池肉林……都是我的……",
	["sy_zongyu"] = "纵欲",
	["$sy_zongyu"] = "呃……好酒！再来一壶！",
	[":sy_zongyu"] = "锁定技，当你于出牌阶段使用一张锦囊牌后，你视为使用一张不计入次数的【酒】。",
	["sy_lingnue"] = "凌虐",
	["$sy_lingnue"] = "来人！活捉了他！斩首祭旗！",
	[":sy_lingnue"] = "当你造成伤害值不小于2的伤害时，你可以摸两张牌并加1点体力上限。",
	["sy_baozheng"] = "暴政",
	["$sy_baozheng"] = "顺我者昌，逆我者亡！",
	[":sy_baozheng"] = "锁定技，其他角色的摸牌阶段结束时，其选择一项：1.交给你一张锦囊牌；2.你视为对其使用一张无距离限制的【杀】。",
	["@baozheng"] = "【暴政】效果触发，请交给%src一张锦囊牌，否则视为%src对你使用一张无距离限制的【杀】。",
	["sy_nishi"] = "逆施",
	["$sy_nishi"] = "看我不活剐了你们！",
	[":sy_nishi"] = "锁定技，当你受到其他角色造成的伤害时，伤害来源选择一项：1.弃置装备区内的所有牌；2.你视为对其使用一张无距离限制的【杀】。",
	["clearEquipArea"] = "弃置装备区内的所有牌",
	["sy_nishi:ViewAsUseSlash"] = "视为%src对你使用一张无距离限制的【杀】",
	["sy_hengxing"] = "横行",
	["$sy_hengxing"] = "都被我踏平吧！哈哈哈哈哈哈哈哈！",
	[":sy_hengxing"] = "锁定技，你于出牌阶段外造成伤害时，该伤害值+1。",
	["designer:mo_dongzhuo"] = "极略三国",
	["illustrator:mo_dongzhuo"] = "极略三国",
	["cv:mo_dongzhuo"] = "极略三国",
}

--魔张角
mo_zhangjiao = sgs.General(extension, "mo_zhangjiao", "sgk_magic", 4, true)

--[[
	技能名：布教
	相关武将：魔张角
	技能描述：其他角色的准备阶段，你可令其摸1张牌并获得1个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。
	引用：sy_bujiao
]]
--

--[[
	技能名：太平
	相关武将：魔张角
	技能描述：准备阶段，你可以弃置所有其他角色的“太平”标记并摸等量的牌，然后若你的手牌数大于其他角色的手牌数之和，你可以对其他角色各造成1点伤害。
	引用：sy_taiping
]]
--

--[[
	技能名：妖惑
	相关武将：魔张角
	技能描述：出牌阶段限一次，你选择一名其他角色，然后选择一项：①弃置等同于其手牌数的牌，获得其所有手牌；②弃置等同于其技能数的牌，然后偷取其所有技能，直至其下个回合开始或死亡。
	引用：sy_yaohuo
]]
--

--[[
	技能名：三治
	相关武将：魔张角
	技能描述：每当你使用3种不同类型的牌后，你可令所有其他角色获得1个“太平”标记。
	引用：sy_sanzhi
]]
--

--[[
	技能名：太平（魔將版）
	相关武将：魔张角
	技能描述：准备阶段，你可以弃置所有角色的“太平”标记并摸与标记数等量的牌；然后若你的手牌数大于其他角色的手牌数之和，你可以对所有其他角色各造成1点伤害。
	引用：mo_taiping（原文為「所有角色」；共用技 sy_taiping 只棄其他角色，唔郁）
]]
--
mo_taiping = sgs.CreateTriggerSkillV2{
	name = "mo_taiping",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		local tp_mark = 0
		for _, pe in sgs.qlist(room:getAllPlayers()) do
			tp_mark = tp_mark + pe:getMark("&sy_taiping")
		end
		if tp_mark > 0 then return skill:objectName() end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp_mark = 0
		local tp_hand = 0
		for _, pe in sgs.qlist(room:getAllPlayers()) do
			tp_mark = tp_mark + pe:getMark("&sy_taiping")
		end
		for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
			tp_hand = tp_hand + pe:getHandcardNum()
		end
		if tp_mark <= 0 then return false end
		for _, pe in sgs.qlist(room:getAllPlayers()) do
			pe:loseAllMarks("&sy_taiping")
		end
		player:drawCards(tp_mark, skill:objectName())
		if player:getHandcardNum() > tp_hand then
			local taiping = room:askForChoice(player, skill:objectName(), "taiping_damage+cancel")
			if taiping == "taiping_damage" then
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					room:doAnimate(1, player:objectName(), pe:objectName())
				end
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					room:damage(sgs.DamageStruct(skill:objectName(), player, pe))
				end
			end
		end
		return false
	end
}

mo_zhangjiao:addSkill("sy_bujiao")
mo_zhangjiao:addSkill("mo_taiping")
mo_zhangjiao:addSkill("sy_yaohuo")
mo_zhangjiao:addSkill("sy_sanzhi")

sgs.LoadTranslationTable {
	["mo_zhangjiao"] = "魔张角",
	["#mo_zhangjiao"] = "大贤良师",
	["~mo_zhangjiao"] = "逆道者，必遭天谴而亡！",
	["sy_bujiao"] = "布教",
	["$sy_bujiao"] = "众星熠熠，不若一日之明。",
	[":sy_bujiao"] = "其他角色的准备阶段，你可以令其摸一张牌并获得一个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。",
	["mo_taiping"] = "太平",
	["$mo_taiping"] = "行大舜之道，救苍生万民。",
	[":mo_taiping"] = "准备阶段，你可以弃置所有角色的“太平”标记并摸与标记数等量的牌；然后若你的手牌数大于其他角色的手牌数之和，你可以对所有其他角色各造成1点伤害。",
	["sy_yaohuo"] = "妖惑",
	["sy_yaohuoCard"] = "妖惑",
	["$sy_yaohuo"] = "存恶害义，善必诛之！",
	[":sy_yaohuo"] = "出牌阶段限一次，你可以选择一名其他角色并执行一项：1.弃置与其技能数等量的牌，然后获得其所有技能，其技能失效，直到其回合开始或死亡；"
		.. "2.弃置与其手牌数等量的牌，然后获得其所有手牌。",
	["yaohuo_card"] = "弃置与其手牌数等量的牌，然后获得其所有手牌",
	["yaohuo_skill"] = "弃置与其技能数等量的牌，然后获得其所有技能（其技能失效直到其回合开始或死亡）",
	["sy_sanzhi"] = "三治",
	["$sy_sanzhi"] = "三气集，万物治！",
	[":sy_sanzhi"] = "当你使用牌时，若未记录此类别，则记录之，然后若已记录三种类别，你清除记录，然后可以令所有其他角色各获得1个“太平”标记。",
	["designer:mo_zhangjiao"] = "极略三国",
	["illustrator:mo_zhangjiao"] = "极略三国",
	["cv:mo_zhangjiao"] = "极略三国",
}

--魔张让
mo_zhangrang = sgs.General(extension, "mo_zhangrang", "sgk_magic", 4, true)

--[[
	技能名：谗陷
	相关武将：魔张让
	技能描述：出牌阶段限一次，你可以移动一名角色的一张牌至另一名角色的对应区域，然后失去牌的角色视为对获得牌的角色使用一张【决斗】；此牌结算后，你获得受到此牌伤害的角色的一张牌。
	引用：sy_chanxian
]]
--

--[[
	技能名：残掠
	相关武将：魔张让
	技能描述：当你获得其他角色的一张牌后，你可以对其造成1点伤害；当其他角色获得你的一张牌后，你可以令其弃置一张牌。
	引用：sy_canlue
]]
--

--[[
	技能名：乱政
	相关武将：魔张让
	技能描述：每回合限一次，当一名角色使用基本牌或普通锦囊牌指定唯一目标时，你可以令另一名角色也成为此牌的目标。
	引用：sy_luanzheng
]]
--

mo_zhangrang:addSkill("sy_chanxian")
mo_zhangrang:addSkill("sy_luanzheng")
mo_zhangrang:addSkill("sy_canlue")

sgs.LoadTranslationTable {
	["mo_zhangrang"] = "魔张让",
	["~mo_zhangrang"] = "小的怕是活不成了，陛下，保重……",
	["#mo_zhangrang"] = "祸乱之源",
	["sy_chanxian"] = "谗陷",
	["sy_chanxianCard"] = "谗陷",
	["@chanxian_to"] = "请选择获得此%src[%dest%arg]的角色",
	["sy_chanxianeCard"] = "谗陷",
	["$sy_chanxian1"] = "懂不懂宫里的规矩？",
	["$sy_chanxian2"] = "活得不耐烦了吧？",
	[":sy_chanxian"] = "出牌阶段限一次，你可以移动一名角色的一张牌至另一名角色的对应区域，然后失去牌的角色视为对获得牌的角色使用一张【决斗】；此牌结算后，你获得受到此牌伤害的角色的一张牌。",
	["sy_canlue"] = "残掠",
	["$sy_canlue"] = "没钱？没钱，就拿命来抵吧！",
	[":sy_canlue"] = "当你获得其他角色的一张牌后，你可以对其造成1点伤害；当其他角色获得你的一张牌后，你可以令其弃置一张牌。",
	["sy_luanzheng"] = "乱政",
	["#LuanzhengExTarget"] = "%from 令 %to 成为 %card 的额外目标",
	["$sy_luanzheng1"] = "陛下，都、都是他们干的！",
	["$sy_luanzheng2"] = "大、大、大事不好！有人造反了！",
	[":sy_luanzheng"] = "每回合限一次，当一名角色使用基本牌或普通锦囊牌指定唯一目标时，你可以令另一名角色也成为此牌的目标。",
	["@luanzheng-extra"] = "你可以发动【乱政】为此%src[%dest%arg]选择一名其他角色作为额外目标",
	["designer:mo_zhangrang"] = "极略三国",
	["illustrator:mo_zhangrang"] = "极略三国",
	["cv:mo_zhangrang"] = "极略三国",
}

--魔魏延
mo_weiyan = sgs.General(extension, "mo_weiyan", "sgk_magic", 4, true)

--[[
	技能名：恃傲
	相关武将：魔魏延
	技能描述：准备阶段或结束阶段，你可以视为使用一张无距离限制的【杀】。
	引用：sy_shiao
]]
--

--[[
	技能名：反骨
	相关武将：魔魏延
	技能描述：锁定技，当你受到的伤害结算后，你结束当前回合，然后执行一个额外的回合。
	引用：sy_fangu
]]
--

--[[
	技能名：狂袭
	相关武将：魔魏延
	技能描述：当你使用的锦囊牌结算后，你可以视为对此牌的目标角色使用一张无距离与次数限制的【杀】；然后若此牌未造成伤害，你失去1点体力。
	引用：sy_kuangxi
]]
--

mo_weiyan:addSkill("sy_shiao")
mo_weiyan:addSkill("sy_fangu")
mo_weiyan:addSkill("sy_kuangxi")

sgs.LoadTranslationTable {
	["mo_weiyan"] = "魔魏延",
	["#mo_weiyan"] = "嗜血狂狼",
	["~mo_weiyan"] = "这……就是老子追求的东西吗？",
	["sy_shiao"] = "恃傲",
	["@shiao-tar"] = "你可以发动“恃傲”视为对一名其他角色使用一张【杀】<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["shiao-slash"] = "恃傲",
	["$sy_shiao1"] = "靠手里的家伙来说话吧。",
	["$sy_shiao2"] = "少废话！真有本事就来打！",
	[":sy_shiao"] = "准备阶段或结束阶段，你可以视为使用一张无距离限制的【杀】。",
	["sy_fangu"] = "反骨",
	["$sy_fangu"] = "一群胆小之辈，成天坏我大事！",
	["#fanguExTurn"] = "%from 的“%arg”被触发，由于 %from 受到了伤害，当前回合将结束，并且 %from 将在此回合结束后立即进行一个额外的回合",
	[":sy_fangu"] = "锁定技，当你受到的伤害结算后，你结束当前回合，然后执行一个额外的回合。",
	["sy_kuangxi"] = "狂袭",
	["$sy_kuangxi1"] = "敢挑战老子，你就后悔去吧！",
	["$sy_kuangxi2"] = "凭你们，是阻止不了老子的！",
	[":sy_kuangxi"] = "当你使用的锦囊牌结算后，你可以视为对此牌的目标角色使用一张无距离与次数限制的【杀】；然后若此牌未造成伤害，你失去1点体力。",
	["designer:mo_weiyan"] = "极略三国",
	["illustrator:mo_weiyan"] = "极略三国",
	["cv:mo_weiyan"] = "极略三国",
}

--魔孙皓
mo_sunhao = sgs.General(extension, "mo_sunhao", "sgk_magic", 4, true)

--[[
	技能名：明政
	相关武将：魔孙皓
	技能描述：锁定技，所有角色摸牌阶段额外摸一张牌；若为你，则额外摸两张。当你受到伤害后，你摸X张牌并失去“明政”（X为已进行的回合数，至少为1），然后你获得技能“嗜杀”。
	引用：sy_mingzheng
]]
--

--[[
	技能名：荒淫
	相关武将：魔孙皓
	技能描述：锁定技，当你弃置其他角色的牌后，你随机获得这些牌的其中一张。
	引用：sy_huangyin
]]
--

--[[
	技能名：醉酒
	相关武将：魔孙皓
	技能描述：出牌阶段，若你的手牌数不小于X，你可以随机弃置X张手牌，然后随机视为使用一张不计入次数的【酒】或【杀】（X为你本回合已发动“醉酒”的次数）。
	引用：sy_zuijiu
]]
--

--[[
	技能名：归命
	相关武将：魔孙皓
	技能描述：限定技，当你进入濒死状态时，你可以回复体力至X点（或体力上限），然后你随机弃置所有其他角色的各X张牌（X为存活角色数，不足则全弃）。
	引用：sy_guiming
]]
--

mo_sunhao:addSkill("sy_mingzheng")
mo_sunhao:addRelateSkill("sy_shisha")
mo_sunhao:addSkill("sy_huangyin")
mo_sunhao:addSkill("sy_zuijiu")
mo_sunhao:addSkill("sy_guiming")

sgs.LoadTranslationTable {
	["mo_sunhao"] = "魔孙皓",
	["#mo_sunhao"] = "末世暴君",
	["~mo_sunhao"] = "乱臣贼子，不得好死！",
	["sy_mingzheng"] = "明政",
	[":sy_mingzheng"] = "锁定技，所有角色摸牌阶段额外摸一张牌；若为你，则额外摸两张。当你受到伤害后，你摸X张牌并失去“明政”（X为已进行的回合数，至少为1），然后你获得技能“嗜杀”。",
	["$sy_mingzheng"] = "开仓放粮，赈济百姓！",
	["sy_shisha"] = "嗜杀",
	[":sy_shisha"] = "锁定技，当你使用【杀】指定目标后，你随机弃置目标角色的一至三张牌。",
	["$sy_shisha"] = "净是些碍眼的家伙，都杀！都杀！",
	["sy_zuijiu"] = "醉酒",
	["$sy_zuijiu"] = "酒……酒呢！拿酒来！",
	["sy_zuijiunormalslash"] = "醉酒",
	["sy_zuijiuNormalSlashCard"] = "醉酒",
	["@sy_zuijiuNormalSlash"] = "你可以视为对一名其他角色使用不计入次数限制的【杀】",
	["~sy_zuijiuNormalSlash"] = "选择目标角色，点击“确定”",
	[":sy_zuijiu"] = "出牌阶段，若你的手牌数不小于X，你可以随机弃置X张手牌，然后随机视为使用一张不计入次数的【酒】或【杀】（X为你本回合已发动“醉酒”的次数）。",
	["sy_huangyin"] = "荒淫",
	["$sy_huangyin"] = "美人儿来来来，让朕瞧瞧！",
	[":sy_huangyin"] = "锁定技，当你弃置其他角色的牌后，你随机获得这些牌的其中一张。",
	["sy_guiming"] = "归命",
	["@guiming"] = "归命",
	["$sy_guiming"] = "你们！难道忘了朝廷之恩吗！",
	[":sy_guiming"] = "限定技，当你进入濒死状态时，你可以回复体力至X点（或体力上限），然后你随机弃置所有其他角色的各X张牌（X为存活角色数，不足则全弃）。",
	["designer:mo_sunhao"] = "极略三国",
	["illustrator:mo_sunhao"] = "极略三国",
	["cv:mo_sunhao"] = "极略三国",
}

--魔蔡夫人
mo_caifuren = sgs.General(extension, "mo_caifuren", "sgk_magic", 4, false)

--[[
	技能名：诋毁
	相关武将：魔蔡夫人
	技能描述：出牌阶段限一次，你可以选择两名体力值不相等的角色，然后令其中体力值较大的角色对另一名角色造成1点伤害；若伤害来源不是你，你回复1点体力。
	引用：sy_dihui
]]
--

--[[
	技能名：乱嗣
	相关武将：魔蔡夫人
	技能描述：出牌阶段限一次，你可以令两名角色拼点，然后你弃置以此法拼点没赢的角色两张牌；若你未以此法拼点赢，你摸两张牌。
	引用：sy_luansi
]]
--

--[[
	技能名：祸心
	相关武将：魔蔡夫人
	技能描述：锁定技，当你受到伤害时，伤害来源选择一项：1.防止此伤害并失去1点体力；2.令你获得其区域内的各一张牌。
	引用：sy_huoxin
]]
--

mo_caifuren:addSkill("sy_dihui")
mo_caifuren:addSkill("sy_luansi")
mo_caifuren:addSkill("sy_huoxin")

sgs.LoadTranslationTable {
	["mo_caifuren"] = "魔蔡夫人",
	["#mo_caifuren"] = "蛇蝎美人",
	["~mo_caifuren"] = "做鬼也不会放过你的！",
	["sy_dihui"] = "诋毁",
	["$sy_dihui1"] = "夫君，此人留不得！",
	["$sy_dihui2"] = "养虎为患，须尽早除之！",
	["$sy_luansi1"] = "教你见识一下我的手段！",
	["$sy_luansi2"] = "求饶？呵呵……晚了！",
	[":sy_dihui"] = "出牌阶段限一次，你可以选择两名体力值不相等的角色，然后令其中体力值较大的角色对另一名角色造成1点伤害；若伤害来源不是你，你回复1点体力。",
	["dihuiothers-choose"] = "请选择因“诋毁”受到伤害的另一名其他角色。",
	["sy_luansi"] = "乱嗣",
	[":sy_luansi"] = "出牌阶段限一次，你可以令两名角色拼点，然后你弃置以此法拼点没赢的角色两张牌；若你未以此法拼点赢，你摸两张牌。",
	["sy_huoxin"] = "祸心",
	["$sy_huoxin"] = "别敬酒不吃吃罚酒！",
	[":sy_huoxin"] = "锁定技，当你受到伤害时，伤害来源选择一项：1.防止此伤害并失去1点体力；2.令你获得其区域内的各一张牌。",
	["obtain_onebyone"] = "该角色获得你每个区域各一张牌",
	["lose_hp"] = "防止此伤害，然后失去一点体力",
	["designer:mo_caifuren"] = "极略三国",
	["illustrator:mo_caifuren"] = "极略三国",
	["cv:mo_caifuren"] = "极略三国",
}

--魔司马懿
mo_simayi = sgs.General(extension, "mo_simayi", "sgk_magic", 4, true)

--[[
	技能名：博略
	相关武将：魔司马懿
	技能描述：锁定技，回合开始时，你随机获得魏、蜀、吴势力的各一个技能，直到你的下一个回合开始。
	引用：sy_bolue
]]
--

--[[
	技能名：忍忌
	相关武将：魔司马懿
	技能描述：当你受到伤害后，你可以摸一张牌，且你发动“博略”时额外获得一个与伤害来源势力相同的技能。
	引用：sy_renji
]]
--

--[[
	技能名：变天
	相关武将：魔司马懿
	技能描述：锁定技，其他角色的判定阶段开始时，你令其额外进行一次【闪电】的判定。
	引用：sy_biantian
]]
--

--[[
	技能名：天佑
	相关武将：魔司马懿
	技能描述：锁定技，结束阶段，若没有角色因【闪电】受到伤害，你回复1点体力；否则你摸X张牌（X为场上角色因【闪电】受伤的次数）。
	引用：sy_tianyou
]]
--

mo_simayi:addSkill("sy_bolue")
mo_simayi:addSkill("sy_renji")
mo_simayi:addSkill("sy_biantian")
mo_simayi:addSkill("sy_tianyou")

sgs.LoadTranslationTable {
	["mo_simayi"] = "魔司马懿",
	["~mo_simayi"] = "呃哦……呃啊……",
	["#mo_simayi"] = "三分归晋",
	["sy_bolue"] = "博略",
	["$sy_bolue1"] = "老夫，想到一些有趣之事。",
	["$sy_bolue2"] = "无用之物，老夫毫无兴趣。",
	["$sy_bolue3"] = "杀人伎俩，偶尔一用无妨。",
	["$sy_bolue4"] = "此种事态，老夫早有准备。",
	[":sy_bolue"] = "锁定技，回合开始时，你随机获得魏、蜀、吴势力的各一个技能，直到你的下一个回合开始。",
	["sy_renji"] = "忍忌",
	["$sy_renji1"] = "老夫也不得不认真起来了。",
	["$sy_renji2"] = "你们，是要置老夫于死地吗？",
	["$sy_renji3"] = "休要聒噪，吵得老夫头疼！",
	[":sy_renji"] = "当你受到伤害后，你可以摸一张牌，且你发动“博略”时额外获得一个与伤害来源势力相同的技能。",
	["#RenjiRecNew"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["#RenjiRec"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["sy_biantian"] = "变天",
	["$sy_biantian"] = "雷起！喝！",
	[":sy_biantian"] = "锁定技，其他角色的判定阶段开始时，你令其额外进行一次【闪电】的判定。",
	["sy_tianyou"] = "天佑",
	["$sy_tianyou"] = "好好看着吧！",
	["#TianyouDraw"] = '%from 的“%arg”被触发，本局游戏中【<font color="gold"><b>闪电</b></font>】已一共造成了 %arg2 次伤害，将摸 %arg2 张牌',
	[":sy_tianyou"] = "锁定技，结束阶段，若没有角色因【闪电】受到伤害，你回复1点体力；否则你摸X张牌（X为场上角色因【闪电】受伤的次数）。",
	["designer:mo_simayi"] = "极略三国",
	["illustrator:mo_simayi"] = "极略三国",
	["cv:mo_simayi"] = "极略三国",
}

--魔袁绍
mo_yuanshao = sgs.General(extension, "mo_yuanshao", "sgk_magic", 4, true)

--[[
	技能名：魔箭
	相关武将：魔袁绍
	技能描述：锁定技，准备阶段，你视为使用一张【万箭齐发】；若此牌被【闪】响应，结束阶段，你视为使用一张【万箭齐发】。
	引用：sy_mojian
]]
--

--[[
	技能名：主宰
	相关武将：魔袁绍
	技能描述：锁定技，你使用锦囊牌造成伤害时，此伤害+1；当你受到锦囊牌造成的伤害时，此伤害-1。
	引用：sy_zhuzai
]]
--

--[[
	技能名：夺冀
	相关武将：魔袁绍
	技能描述：锁定技，当你杀死其他角色时，你获得其所有手牌和技能。
	引用：sy_duoji
]]
--

mo_yuanshao:addSkill("sy_mojian")
mo_yuanshao:addSkill("sy_zhuzai")
mo_yuanshao:addSkill("sy_duoji")

sgs.LoadTranslationTable {
	["mo_yuanshao"] = "魔袁绍",
	["#mo_yuanshao"] = "魔君",
	["~mo_yuanshao"] = "我不甘心！我不甘心啊！！！",
	["sy_mojian"] = "魔箭",
	["$sy_mojian1"] = "血肉之躯，怎可挡我万箭穿心！",
	["$sy_mojian2"] = "全都去死，去死吧！",
	["mojian_jink"] = "魔箭被闪响应",
	[":sy_mojian"] = "锁定技，准备阶段，你视为使用一张【万箭齐发】；若此牌被【闪】响应，结束阶段，你视为使用一张【万箭齐发】。",
	["sy_zhuzai"] = "主宰",
	["$sy_zhuzai1"] = "天命在我，尔等凡人还不跪拜！",
	["$sy_zhuzai2"] = "四世三公，名动天下！",
	[":sy_zhuzai"] = "锁定技，你使用锦囊牌造成伤害时，此伤害+1；当你受到锦囊牌造成的伤害时，此伤害-1。",
	["sy_duoji"] = "夺冀",
	["$sy_duoji1"] = "冀州已得，这天下迟早是我的！",
	["$sy_duoji2"] = "属于我的东西，不如趁早双手奉上！",
	[":sy_duoji"] = "锁定技，当你杀死其他角色时，你获得其所有手牌和技能。",
	["designer:mo_yuanshao"] = "极略三国",
	["illustrator:mo_yuanshao"] = "极略三国",
	["cv:mo_yuanshao"] = "极略三国",
}

--魔曹操
mo_caocao = sgs.General(extension, "mo_caocao", "sgk_magic", 4, true)

--[[
	技能名：魏武
	相关武将：魔曹操
	技能描述：当你受到伤害后，你可以摸两张牌，然后若造成此伤害的实体牌为【杀】或普通锦囊牌，你可以获得此牌和弃牌堆中所有与此牌牌名相同的牌。
	引用：sy_weiwu
]]
--
sy_weiwu = sgs.CreateTriggerSkillV2 {
	name = "sy_weiwu",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.damage > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(2, skill:objectName())
		if damage.card and (damage.card:isKindOf("Slash") or damage.card:isNDTrick()) then
			local ids = sgs.IntList()
			if damage.card:isVirtualCard() then
				ids = damage.card:getSubcards()
			else
				ids:append(damage.card:getEffectiveId())
			end
			if ids:isEmpty() then
				return false
			end
			for _, id in sgs.qlist(ids) do
				if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
					return false
				end
			end
			player:obtainCard(damage.card)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			if not room:getDiscardPile():isEmpty() then
				for _, id in sgs.qlist(room:getDiscardPile()) do
					if sgs.Sanguosha:getCard(id):objectName() == damage.card:objectName() then
						dummy:addSubcard(id)
					end
				end
			end
			if dummy:subcardsLength() > 0 then
				player:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		return false
	end,
}

mo_caocao:addSkill(sy_weiwu)

--[[
	技能名：独尊
	相关武将：魔曹操
	技能描述：锁定技，每名角色限两次，其他角色的回合开始时，其令以下大于0的一项数值-1，然后令你该项的数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。
	引用：sy_duzun
]]
--
local function updateMCCvalue(mcc, mcc_skill)
	local room = sgs.Sanguosha:currentRoom()
	local s, d, m = Nil2Int(mcc:getTag("mcc_defaultslash_num"):toInt()), Nil2Int(mcc:getTag("mcc_phasedraw_num"):toInt()), mcc:getMaxHp()
	if s == 0 then
		s = s + 1
	end
	if d == 0 then
		d = d + 2
	end
	s = s - mcc:getMark("mcc_defaultslash_num_")
	d = d - mcc:getMark("mcc_phasedraw_num_")
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg1", math.max(0, s))
	mcc:setTag("mcc_defaultslash_num", sgs.QVariant(math.max(0, s)))
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg2", math.max(0, d))
	mcc:setTag("mcc_phasedraw_num", sgs.QVariant(math.max(0, d)))
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg3", m)
	room:changeTranslation(mcc, mcc_skill)
end

sy_duzun = sgs.CreateTriggerSkillV2 {
	name = "sy_duzun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.MaxHpChanged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:getPhase() == sgs.Player_Start
				and player:getTag(skill:objectName()):toInt() < 2 then
				local names, owners = {}, {}
				for _, cc in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if cc:objectName() ~= player:objectName() then
						table.insert(names, skill:objectName())
						table.insert(owners, cc:objectName())
					end
				end
				if #names > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == skill:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.MaxHpChanged then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			-- player 為技能持有者（舊版 cc），ctx.invoker 為回合角色（舊版 player）
			local target = ctx.invoker
			if target and target:objectName() ~= player:objectName()
				and target:getTag(skill:objectName()):toInt() < 2
				and target:isAlive() and target:getPhase() == sgs.Player_Start then
				local cc = player
				local items = { "mcc_defaultslash_num", "mcc_phasedraw_num", "mcc_maxhp" }
				local x = Nil2Int(target:getTag(skill:objectName()):toInt())
				local y = target:getMark("mcc_phasedraw_num_")
				target:setTag(skill:objectName(), sgs.QVariant(x + 1))
				room:sendCompulsoryTriggerLog(cc, skill:objectName(), true, true)
				if target:getMark("mcc_defaultslash_num_") >= 1 then
					table.removeOne(items, "mcc_defaultslash_num")
				end
				if y >= 2 then
					table.removeOne(items, "mcc_phasedraw_num")
				end
				local to_lose = room:askForChoice(target, skill:objectName(), table.concat(items, "+"), data)
				local msg = sgs.LogMessage()
				msg.from = target
				msg.type = "#duzunLose"
				msg.arg = to_lose
				room:sendLog(msg)
				if to_lose == "mcc_defaultslash_num" then
					room:addPlayerMark(target, to_lose .. "_")
					local s = 0
					if Nil2Int(cc:getTag(to_lose):toInt()) == 0 then
						s = s + 1
					else
						s = s + Nil2Int(cc:getTag(to_lose):toInt())
					end --杀次数基础值：1
					s = s - cc:getMark("mcc_defaultslash_num_")
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
					cc:setTag(to_lose, sgs.QVariant(s + 1))
					room:setPlayerMark(cc, to_lose, s)
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
				elseif to_lose == "mcc_phasedraw_num" then
					room:addPlayerMark(target, to_lose .. "_")
					local k = 0
					if Nil2Int(cc:getTag(to_lose):toInt()) == 0 then
						k = k + 2
					else
						k = k + Nil2Int(cc:getTag(to_lose):toInt())
					end --摸牌阶段摸牌基础值：2
					k = k - cc:getMark("mcc_phasedraw_num_")
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
					cc:setTag(to_lose, sgs.QVariant(k + 1))
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
				elseif to_lose == "mcc_maxhp" then
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
					room:loseMaxHp(target, 1)
					room:gainMaxHp(cc, 1)
					updateMCCvalue(cc, skill:objectName())
					if cc:hasSkill("sy_longbian") then
						updateMCCvalue(cc, "sy_longbian")
					end
				end
				room:changeTranslation(cc, "sy_duzun")
				if cc:hasSkill("sy_longbian") then
					room:changeTranslation(cc, "sy_longbian")
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == skill:objectName() then
				if player:getSeat() == ctx.invoker:getSeat() then
					for _, pe in sgs.qlist(room:getAllPlayers(true)) do
						room:setPlayerMark(pe, "mcc_defaultslash_num_", 0)
						pe:removeTag("mcc_phasedraw_num")
						room:setPlayerMark(pe, "mcc_phasedraw_num_", 0)
						pe:removeTag("mcc_defaultslash_num")
					end
				end
			end
		elseif event == sgs.MaxHpChanged then
			local change = data:toMaxHp()
			if change.who and change.who:objectName() == player:objectName() then
				updateMCCvalue(player, skill:objectName())
				room:changeTranslation(player, "sy_duzun")
				if player:hasSkill("sy_longbian") then
					updateMCCvalue(player, "sy_longbian")
				end
			end
		end
		return false
	end,
}

mo_caocao:addSkill(sy_duzun)

--[[
	技能名：龙变
	相关武将：魔曹操
	技能描述：回合开始时，你可以将你大于0的两项交换数值，然后令其余一项数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。
	引用：sy_longbian
]]
--
sy_longbian = sgs.CreateTriggerSkillV2 {
	name = "sy_longbian",
	events = { sgs.EventPhaseStart, sgs.MaxHpChanged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				return skill:objectName()
			end
		elseif event == sgs.MaxHpChanged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:broadcastSkillInvoke(skill:objectName())
				--注意：摸牌数、杀的次数记录的都是基础值，在转换成对应的增益时，需要减去基础值（如：记录的摸牌数为3，则增益值为3-2=1；记录的【杀】次数为3，则可额外出【杀】次数为3-1=2）
				local items = { "mcc_defaultslash_num", "mcc_phasedraw_num", "mcc_maxhp" }
				local x = 0 --【杀】可用次数
				local y = 0 --摸牌阶段摸牌数
				if (not player:getTag("mcc_phasedraw_count"):toInt()) or player:getTag("mcc_phasedraw_count"):toInt() == 0 then
					if Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) == 0 then
						y = y + 2
					else
						y = y + player:getTag("mcc_phasedraw_num"):toInt()
					end
				else
					if player:getTag("mcc_phasedraw_count"):toInt() then
						y = y + player:getTag("mcc_phasedraw_count"):toInt()
					end
				end
				local z = player:getMaxHp() --体力上限
				if Nil2Int(player:getTag("mcc_defaultslash_num"):toInt()) == 0 then
					x = x + 1
				else
					x = x + player:getTag("mcc_defaultslash_num"):toInt()
				end
				room:setPlayerMark(player, "mcc_defaultslash_num", x - 1)
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#longbianData"
				msg.arg = tostring(x)
				msg.arg2 = tostring(y)
				msg.arg3 = tostring(z)
				room:sendLog(msg)
				local new_slashnum, new_drawnum = 0, 0
				local to_add = room:askForChoice(player, skill:objectName(), table.concat(items, "+"), data)
				if to_add == "mcc_maxhp" then --交换【杀】使用次数和摸牌数，体力上限+1
					new_slashnum = y
					new_drawnum = x
					room:gainMaxHp(player, 1)
				elseif to_add == "mcc_defaultslash_num" then --交换体力上限和摸牌数，【杀】使用次数（x）+1
					new_slashnum = x + 1
					new_drawnum = z
					local dif1 = math.abs(y - z)
					if y > z then
						room:gainMaxHp(player, dif1)
					elseif y < z then
						room:loseMaxHp(player, dif1)
					end
				elseif to_add == "mcc_phasedraw_num" then --交换体力上限和【杀】使用次数，摸牌数（y）+1
					new_drawnum = y + 1
					new_slashnum = z
					local dif2 = math.abs(x - z)
					if x > z then
						room:gainMaxHp(player, dif2)
					elseif x < z then
						room:loseMaxHp(player, dif2)
					end
				end
				player:setTag("mcc_defaultslash_num", sgs.QVariant(new_slashnum))
				player:setTag("mcc_phasedraw_num", sgs.QVariant(new_drawnum))
				room:setPlayerMark(player, "mcc_defaultslash_num", new_slashnum - 1)
				if player:hasSkill("sy_duzun") then
					updateMCCvalue(player, "sy_duzun")
					room:changeTranslation(player, "sy_duzun")
				end
				updateMCCvalue(player, skill:objectName())
				room:changeTranslation(player, skill:objectName())
				local msg2 = sgs.LogMessage()
				msg2.from = player
				msg2.type = "#longbianUpdate"
				msg2.arg = to_add
				msg2.arg2 = tostring(new_slashnum)
				msg2.arg3 = tostring(new_drawnum)
				msg2.arg4 = tostring(player:getMaxHp())
				room:sendLog(msg2)
			end
		elseif event == sgs.MaxHpChanged then
			updateMCCvalue(player, "sy_duzun")
			room:changeTranslation(player, "sy_duzun")
			updateMCCvalue(player, skill:objectName())
			room:changeTranslation(player, skill:objectName())
		end
		return false
	end,
}

mo_caocao:addSkill(sy_longbian)

sgs.LoadTranslationTable {
	["mo_caocao"] = "魔曹操",
	["#mo_caocao"] = "黯世权龙",
	["~mo_caocao"] = "孤不嫌世，世却不容孤！",
	["sy_weiwu"] = "魏武",
	["$sy_weiwu1"] = "国家无有孤，不知几人称帝，几人称王！",
	["$sy_weiwu2"] = "燕雀安知鸿鹄之志！",
	[":sy_weiwu"] = "当你受到伤害后，你可以摸两张牌，然后若造成此伤害的实体牌为【杀】或普通锦囊牌，你可以获得此牌和弃牌堆中所有与此牌牌名相同的牌。",
	["sy_duzun"] = "独尊",
	["$sy_duzun1"] = "天下人的命，不及孤之霸业！",
	["$sy_duzun2"] = "世人皆蝼蚁，无奸不成雄！",
	[":sy_duzun"] = "锁定技，每名角色限两次，其他角色的回合开始时，其令以下大于0的一项数值-1，然后令你该项的数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。",
	[":sy_duzun1"] = '锁定技，每名角色限两次，其他角色的回合开始时，其令以下大于0的一项数值-1，然后令你该项的数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。\
	<font color="#00BFFF">当前基础值：每回合可用【%arg1】次【杀】，摸牌阶段摸【%arg2】张牌，体力上限【%arg3】点</font>',
	["mcc_defaultslash_num"] = "每回合【杀】使用次数",
	["mcc_phasedraw_num"] = "摸牌阶段摸牌数",
	["mcc_maxhp"] = "体力上限",
	["#duzunLose"] = "%from 选择了令自己的 %arg 的数值-1",
	["sy_longbian"] = "龙变",
	["#longbianData"] = "%from 当前各项目的基础数值：每回合可使用 %arg 次【杀】，摸牌阶段摸 %arg2 张牌，体力上限 %arg3 点",
	["$sy_longbian1"] = "飞腾于宇宙之间，潜伏于波涛之内。",
	["$sy_longbian2"] = "兴云吐雾，隐介藏形，犹人得志，纵横四海。",
	[":sy_longbian"] = '回合开始时，你可以将你大于0的两项数值交换，然后令其余一项数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。\
	<font color="#9932CC">操作方法：弹窗中选择的那一项是你接下来基础数值+1的，没选的那两项将互换。</font>',
	[":sy_longbian1"] = '回合开始时，你可以将你大于0的两项数值交换，然后令其余一项数值+1：使用【杀】的次数上限；摸牌阶段摸牌数；体力上限。\
	<font color="#00BFFF">当前基础值：每回合可用【%arg1】次【杀】，摸牌阶段摸【%arg2】张牌，体力上限【%arg3】点</font>\
	<font color="#9932CC">操作方法：弹窗中选择的那一项是你接下来基础数值+1的，没选的那两项将互换。</font>',
	["#longbianUpdate"] = "%from 选择令自己 %arg 的数值+1，交换了其余两项，目前基础数值属性：每回合可使用 %arg2 次【杀】，摸牌阶段摸 %arg3 张牌，体力上限 %arg4 点",
	["designer:mo_caocao"] = "极略三国",
	["illustrator:mo_caocao"] = "极略三国",
	["cv:mo_caocao"] = "极略三国",
}

--魔邹氏
mo_zoushi = sgs.General(extension, "mo_zoushi", "sgk_magic", 4, false)

--[[
	技能名：祸世
	相关武将：魔邹氏
	技能描述：锁定技，当其他角色使用基本牌或普通锦囊牌指定目标时，你随机令一名不是此牌目标的角色成为此牌的目标。
	引用：sy_huoshi
]]
--
sy_huoshi = sgs.CreateTriggerSkillV2 {
	name = "sy_huoshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming, sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		local zoushi = room:findPlayerBySkillName(skill:objectName())
		if not zoushi then
			return false
		end
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.from and use.card and use.from:objectName() ~= zoushi:objectName()
				and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
				and use.to:length() > 0
				and zoushi:getMark("huoshi_extarget" .. use.card:toString()) == 0 then
				return skill:objectName(), zoushi
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and zoushi:getMark("huoshi_extarget" .. use.card:toString()) > 0 then
				return skill:objectName(), zoushi
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local zoushi = player
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.from and use.card and use.from:objectName() ~= zoushi:objectName() and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and use.to:length() > 0 then
				local others = sgs.SPlayerList()
				for _, t in sgs.qlist(room:getAlivePlayers()) do
					if not use.to:contains(t) and (not sgs.Sanguosha:isProhibited(use.from, t, use.card)) then
						others:append(t)
					end
				end
				if others:isEmpty() then
					return false
				end
				if zoushi:getMark("huoshi_extarget" .. use.card:toString()) > 0 then
					return false
				end
				zoushi:addMark("huoshi_extarget" .. use.card:toString())
				others = sgs.QList2Table(others)
				local exone = others[math.random(1, #others)]
				room:broadcastSkillInvoke(skill:objectName())
				room:doAnimate(1, use.from:objectName(), exone:objectName())
				local msg = sgs.LogMessage()
				msg.from = zoushi
				msg.arg = skill:objectName()
				msg.type = "#HuoshiExTarget"
				msg.to:append(exone)
				msg.card_str = use.card:toString()
				room:sendLog(msg)
				use.to:append(exone)
				room:sortByActionOrder(use.to)
				data:setValue(use)
				room:setPlayerFlag(use.from, "ZenhuiUser_" .. use.card:toString())
				room:getThread():trigger(sgs.TargetConfirming, room, exone, data)
				return false
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and zoushi:getMark("huoshi_extarget" .. use.card:toString()) > 0 then
				zoushi:setMark("huoshi_extarget" .. use.card:toString(), 0)
			end
		end
		return false
	end,
}

mo_zoushi:addSkill(sy_huoshi)

--[[
	技能名：淫恣
	相关武将：魔邹氏
	技能描述：锁定技，每回合每名角色限一次，当一名其他角色于其回合外获得牌后，你回复1点体力；每回合每名角色限一次，当一名其他角色于其回合外回复体力后，你摸两张牌。
	引用：sy_yinzi
]]
--
sy_yinzi = sgs.CreateTriggerSkillV2 {
	name = "sy_yinzi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		local zoushi = room:findPlayerBySkillName(skill:objectName())
		if not zoushi then
			return false
		end
		if event == sgs.HpRecover then
			if player:getSeat() ~= zoushi:getSeat() and player:getPhase() == sgs.Player_NotActive
				and not player:getTag("yinzi_hprecover"):toBool() then
				return skill:objectName(), zoushi
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to_place == sgs.Player_PlaceHand
				and move.to:objectName() == player:objectName()
				and player:isAlive() and player:getPhase() == sgs.Player_NotActive
				and not player:getTag("yinzi_obtaincard"):toBool()
				and player:getSeat() ~= zoushi:getSeat() and zoushi:isWounded() then
				return skill:objectName(), zoushi
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- player 為技能持有者（zoushi）；ctx.invoker 為原事件目標
		local zoushi = player
		if event == sgs.HpRecover then
			local target = ctx.invoker
			target:setTag("yinzi_hprecover", sgs.QVariant(true))
			room:broadcastSkillInvoke(skill:objectName())
			local msg1 = sgs.LogMessage()
			msg1.from = zoushi
			msg1.arg = skill:objectName()
			msg1.to:append(target)
			msg1.type = "#yinziRecover"
			msg1.arg2 = tostring(2)
			room:sendLog(msg1)
			zoushi:drawCards(2, skill:objectName())
		elseif event == sgs.CardsMoveOneTime then
			local _to = ctx.invoker
			_to:setTag("yinzi_obtaincard", sgs.QVariant(true))
			room:broadcastSkillInvoke(skill:objectName())
			local msg2 = sgs.LogMessage()
			msg2.from = zoushi
			msg2.arg = skill:objectName()
			msg2.to:append(_to)
			msg2.type = "#yinziObtain"
			msg2.arg2 = tostring(1)
			room:sendLog(msg2)
			room:recover(zoushi, sgs.RecoverStruct(zoushi, nil, 1))
		end
		return false
	end,
}

mo_zoushi:addSkill(sy_yinzi)

--[[
	技能名：魔舞
	相关武将：魔邹氏
	技能描述：当其他角色对你/你对其他角色使用基本牌或普通锦囊牌后，你可以令此牌的使用者与所有目标角色各摸一张牌，然后你令此牌额外结算一次。
	引用：sy_mowu
]]
--
sy_mowu = sgs.CreateTriggerSkillV2 {
	name = "sy_mowu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if room:findPlayersBySkillName(skill:objectName()):isEmpty() then
			return false
		end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or not use.card or use.to:isEmpty() then
				return false
			end
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then
				return false
			end
			if use.card:getTag("mowu_twice"):toBool() then
				return false
			end
			local names, owners = {}, {}
			for _, zoushi in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				local qualifies = false
				if use.from:objectName() ~= zoushi:objectName() and use.to:contains(zoushi) then
					qualifies = true
				elseif use.from:objectName() == zoushi:objectName() then
					for _, t in sgs.qlist(use.to) do
						if t:objectName() ~= zoushi:objectName() then
							qualifies = true
							break
						end
					end
				end
				if qualifies then
					table.insert(names, skill:objectName())
					table.insert(owners, zoushi:objectName())
				end
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getTag("mowu_twice"):toBool() then
				local names, owners = {}, {}
				for _, zoushi in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(names, skill:objectName())
					table.insert(owners, zoushi:objectName())
				end
				if #names > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- player 為技能持有者（zoushi）
		local data = ctx.original_data
		local zoushi = player
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or not use.card then
				return false
			end
			if use.to:isEmpty() then
				return false
			end
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then
				return false
			end
			if use.from:objectName() ~= zoushi:objectName() and use.to:contains(zoushi) and not use.card:getTag("mowu_twice"):toBool() then
				use.card:setTag("mowu_twice", sgs.QVariant(true))
			else
				if use.from:objectName() == zoushi:objectName() then
					local contains_others = false
					for _, t in sgs.qlist(use.to) do
						if t:objectName() ~= zoushi:objectName() then
							contains_others = true
							break
						end
					end
					if contains_others and not use.card:getTag("mowu_twice"):toBool() then
						use.card:setTag("mowu_twice", sgs.QVariant(true))
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getTag("mowu_twice"):toBool() then
				for _, t in sgs.qlist(use.to) do
					if t:isDead() then
						use.to:removeOne(t)
					end
				end
				if not use.to:isEmpty() and zoushi:askForSkillInvoke(skill:objectName(), data) then
					use.card:setTag("mowu_twice", sgs.QVariant(false))
					use.card:removeTag("mowu_twice")
					room:broadcastSkillInvoke(skill:objectName())
					local draws = sgs.SPlayerList()
					if not draws:contains(use.from) then
						draws:append(use.from)
					end
					for _, t in sgs.qlist(use.to) do
						if not draws:contains(t) then
							draws:append(t)
						end
					end
					for _, pe in sgs.qlist(draws) do
						room:doAnimate(1, zoushi:objectName(), pe:objectName())
					end
					for _, pe in sgs.qlist(draws) do
						pe:drawCards(1, skill:objectName())
					end
					local msg = sgs.LogMessage()
					msg.from = zoushi
					msg.type = "#mowuTwice"
					msg.card_str = use.card:toString()
					msg.to = use.to
					room:sendLog(msg)
					use.card:use(room, use.from, use.to)
					return false
				end
				use.card:setTag("mowu_twice", sgs.QVariant(false))
				use.card:removeTag("mowu_twice")
			end
		end
		return false
	end,
}

mo_zoushi:addSkill(sy_mowu)

sgs.LoadTranslationTable {
	["mo_zoushi"] = "魔邹氏",
	["#mo_zoushi"] = "妖媚之殃",
	["~mo_zoushi"] = "嗯……真不懂得怜香惜爱……",
	["sy_huoshi"] = "祸世",
	["$sy_huoshi1"] = "男人管不住自己的眼睛，与我何干？",
	["$sy_huoshi2"] = "祸水又如何？难道，你不是心甘情愿吗？",
	[":sy_huoshi"] = "锁定技，当其他角色使用基本牌或普通锦囊牌指定目标时，你随机令一名不是此牌目标的角色成为此牌的目标。",
	["#HuoshiExTarget"] = "%from 的“%arg”被触发，令 %to 也成为了 %card 的目标",
	["sy_yinzi"] = "淫恣",
	["$sy_yinzi1"] = "将军与妾身，甚是投缘呐~",
	["$sy_yinzi2"] = "春宵苦短，将军还等什么？",
	[":sy_yinzi"] = "锁定技，每回合每名角色限一次，当一名其他角色于其回合外获得牌后，你回复1点体力；每回合每名角色限一次，当一名其他角色于其回合外回复体力后，你摸两张牌。",
	["#yinziRecover"] = "%from 的“%arg”被触发，由于 %to 在其回合外回复了体力，%from 将摸 %arg2 张牌",
	["#yinziObtain"] = "%from 的“%arg”被触发，由于 %to 在其回合外获得了牌，%from 将回复 %arg2 点体力",
	["sy_mowu"] = "魔舞",
	["$sy_mowu1"] = "这一舞的代价，将军愿付出什么呢？",
	["$sy_mowu2"] = "沉溺于此，走向你的末路吧！",
	[":sy_mowu"] = "当其他角色对你/你对其他角色使用基本牌或普通锦囊牌后，你可以令此牌的使用者与所有目标角色各摸一张牌，然后你令此牌额外结算一次。",
	["#mowuTwice"] = "%from 令此 %card 对 %to 再额外结算一次",
	["designer:mo_zoushi"] = "极略三国",
	["illustrator:mo_zoushi"] = "极略三国",
	["cv:mo_zoushi"] = "极略三国",
}

--魔孙鲁班
mo_sunluban = sgs.General(extension, "mo_sunluban", "sgk_magic", 4, false)

--[[
	技能名：权倾
	相关武将：魔孙鲁班
	技能描述：出牌阶段每名角色限一次，你可以展示一张本阶段内未以此法展示过的手牌并选择一名其他角色，除非其弃置一张点数大于此牌的牌，否则你令其视为使用目标由你选择
	的任意基本牌或非延时锦囊牌，然后你回复1点体力。
	引用：sy_quanqing
]]
--
function getFixedTargets(user, card)
	local tos = sgs.SPlayerList()
	local room = sgs.Sanguosha:currentRoom()
	if card:isKindOf("ExNihilo") or card:isKindOf("Dongzhuxianji") or card:isKindOf("Peach") or card:isKindOf("Analeptic") then
		tos:append(user)
	elseif card:isKindOf("AmazingGrace") or card:isKindOf("GoldSalvation") then
		tos = room:getAlivePlayers()
	elseif card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssult") then
		tos = room:getOtherPlayers(user)
	end
	return tos
end

sy_quanqingCard = sgs.CreateSkillCard {
	name = "sy_quanqingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getMark("sy_quanqingTarget-PlayClear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local cid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cid)
		room:addPlayerMark(effect.from, "sy_quanqing" .. cid .. "-PlayClear")
		room:addPlayerMark(effect.to, "sy_quanqingTarget-PlayClear")
		room:showCard(effect.from, cid)
		local num = card:getNumber()
		local prompt = string.format("@sy_quanqing:%s:%s", effect.from:objectName(), card:getNumberString())
		local to_throw = nil
		local n = sgs.QVariant()
		n:setValue(num)
		if num <= 12 then
			to_throw = room:askForCard(effect.to, ".|.|" .. tostring(num + 1) .. "~" .. "13|.", prompt, n, sgs.Card_MethodNone)
		end
		if to_throw ~= nil then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.to:objectName(), "sy_quanqing", "")
			room:throwCard(to_throw, reason, nil)
		else
			local bnd_warehouse, bnd_cards = {}, sgs.IntList()
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
				local cd = sgs.Sanguosha:getEngineCard(id)
				if
					(cd:isKindOf("BasicCard") or cd:isNDTrick())
					and not table.contains(bnd_warehouse, cd:objectName())
					and (not cd:isKindOf("Jink"))
					and (not cd:isKindOf("Suijiyingbian"))
					and (not cd:isKindOf("Nullification"))
				then
					table.insert(bnd_warehouse, cd:objectName())
					bnd_cards:append(id)
				end
			end
			room:fillAG(bnd_cards, effect.from)
			local _q = sgs.QVariant()
			_q:setValue(effect.to)
			effect.from:setTag("sy_quanqing_target", _q)
			local use_id = room:askForAG(effect.from, bnd_cards, false, "sy_quanqing", "@quanqing_viewas:" .. effect.to:objectName())
			room:clearAG(effect.from)
			local name = sgs.Sanguosha:getEngineCard(use_id):objectName()
			local qq_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
			qq_card:setSkillName("sy_quanqing_USECARD")
			if qq_card:targetFixed() then
				room:useCard(sgs.CardUseStruct(qq_card, effect.to, getFixedTargets(effect.to, qq_card)))
			else
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not effect.to:isProhibited(p, qq_card) then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(effect.from, targets, "sy_quanqing", "sy_quanqing-playerchosen:" .. name)
					room:setPlayerFlag(effect.to, "sy_quanqingFrom")
					room:setPlayerFlag(target, "sy_quanqingTo")
					room:useCard(sgs.CardUseStruct(qq_card, effect.to, target))
					if effect.to:isAlive() then
						room:setPlayerFlag(effect.to, "-sy_quanqingFrom")
					end
					if target:isAlive() then
						room:setPlayerFlag(target, "-sy_quanqingTo")
					end
				end
			end
			qq_card:deleteLater()
			effect.from:removeTag("sy_quanqing_target")
			if effect.from:isWounded() then
				room:recover(effect.from, sgs.RecoverStruct(effect.from), true)
			end
		end
	end,
}

sy_quanqing = sgs.CreateViewAsSkillV2 {
	name = "sy_quanqing",
	n = 1,
	will_throw_selected_cards = false,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return false
		end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		return not player:isKongcheng()
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or candidate:isEquipped() then
			return false
		end
		local player = request:getInitiator()
		if not player then
			return false
		end
		local id = candidate:getEffectiveId()
		return player:getMark("sy_quanqing" .. id .. "-PlayClear") == 0
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then
			return nil
		end
		local showtime = sy_quanqingCard:clone()
		showtime:addSubcard(ids:first())
		showtime:setSkillName(skill:objectName())
		return showtime
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_quanqingCard")
		end
		return true
	end,
}

mo_sunluban:addSkill(sy_quanqing)

--[[
	技能名：扰梦
	相关武将：魔孙鲁班
	技能描述：锁定技，其他角色的判定阶段开始时，若其判定区内没有牌，你令其进行【乐不思蜀】判定。
	引用：sy_raomeng
]]
--
sy_raomeng = sgs.CreateTriggerSkillV2 {
	name = "sy_raomeng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Judge and player:getJudgingArea():isEmpty() then
			local names, owners = {}, {}
			for _, mslb in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if mslb:objectName() ~= player:objectName() then
					table.insert(names, skill:objectName())
					table.insert(owners, mslb:objectName())
				end
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- player 為技能持有者（mslb）；ctx.invoker 為判定階段角色
		local mslb = player
		local target = ctx.invoker
		if mslb:objectName() == target:objectName() then
			return false
		end
		room:sendCompulsoryTriggerLog(mslb, skill:objectName(), true, true)
		room:doAnimate(1, mslb:objectName(), target:objectName())
		local indulgence = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)
		local effect = sgs.CardEffectStruct()
		effect.from = nil
		effect.to = target
		effect.card = indulgence
		indulgence:onEffect(effect)
		return false
	end,
}

mo_sunluban:addSkill(sy_raomeng)

--[[
	技能名：永劫
	相关武将：魔孙鲁班
	技能描述：回合结束阶段，你可以选择至少一名对你造成过伤害的其他角色，除非其弃置X张牌（X为其对你造成过伤害的次数），否则你令其减1点体力上限。
	引用：sy_yongjie
]]
--
sy_yongjie = sgs.CreateTriggerSkillV2 {
	name = "sy_yongjie",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("sy_yongjie_DamageTimes") > 0 then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local data = ctx.original_data
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("sy_yongjie_DamageTimes") > 0 then
					targets:append(p)
				end
			end
			for _, nl in sgs.qlist(targets) do
				room:setPlayerMark(nl, "&yongjie_tome_damagetimes", nl:getMark("sy_yongjie_DamageTimes"))
			end
			if not player:askForSkillInvoke(skill:objectName(), data) then
				for _, nl in sgs.qlist(targets) do
					room:setPlayerMark(nl, "&yongjie_tome_damagetimes", 0)
				end
				return false
			end
			local nulis = room:askForPlayersChosen(player, targets, skill:objectName(), 1, targets:length(), "@sy_yongjie-playerschosen")
			for _, nl in sgs.qlist(targets) do
				room:setPlayerMark(nl, "&yongjie_tome_damagetimes", 0)
			end
			if nulis:isEmpty() then
				return false
			end
			local names = {}
			for _, nl in sgs.qlist(nulis) do
				table.insert(names, nl:objectName())
			end
			player:setTag("sy_yongjie_choosed", sgs.QVariant(table.concat(names, "+")))
			return true
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
				room:addPlayerMark(damage.from, "sy_yongjie_DamageTimes")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local names = player:getTag("sy_yongjie_choosed"):toString():split("+")
				player:removeTag("sy_yongjie_choosed")
				local nulis = sgs.SPlayerList()
				for _, name in ipairs(names) do
					local p = room:findPlayerByObjectName(name, true)
					if p then
						nulis:append(p)
					end
				end
				if nulis:isEmpty() then
					return false
				end
				room:broadcastSkillInvoke(skill:objectName())
				for _, nl in sgs.qlist(nulis) do
					room:doAnimate(1, player:objectName(), nl:objectName())
				end
				for _, nl in sgs.qlist(nulis) do
					local n = nl:getMark("sy_yongjie_DamageTimes")
					if nl:getCards("he"):length() < n then
						room:loseMaxHp(nl, 1, skill:objectName())
					else
						local prompt = string.format("@sy_yongjie_discard:%s:%s", player:objectName(), n)
						local dis = room:askForDiscard(nl, skill:objectName(), n, n, true, true, prompt)
						if not dis then
							room:loseMaxHp(nl, 1, skill:objectName())
						end
					end
				end
			end
		end
		return false
	end,
}

mo_sunluban:addSkill(sy_yongjie)

sgs.LoadTranslationTable {
	["mo_sunluban"] = "魔孙鲁班",
	["#mo_sunluban"] = "梦魇",
	["~mo_sunluban"] = "我可是公主！你竟敢？！……",
	["sy_quanqing"] = "权倾",
	["$sy_quanqing1"] = "本公主说你忤逆了，就是忤逆了。",
	["$sy_quanqing2"] = "你可知，与本宫作对的下场？",
	[":sy_quanqing"] = "出牌阶段每名角色限一次，你可以展示一张本阶段内未以此法展示过的手牌并选择一名其他角色，除非其弃置一张点数大于此牌的牌，否则"
		.. "你令其视为使用目标由你选择的任意基本牌或非延时锦囊牌，然后你回复1点体力。",
	["@quanqing_viewas"] = "请选择一张牌，令%src视为使用之",
	["@sy_quanqing"] = "请弃置一张点数大于%dest的牌，否则%src将令你视为使用一张基本牌或非延时锦囊牌，且目标由%src选择。",
	["sy_quanqing-playerchosen"] = "【权倾】你令其视为使用一张【<font color='yellow'><b>%src</b></font>】，请选择此牌的目标",
	["sy_raomeng"] = "扰梦",
	["$sy_raomeng1"] = "睡着了，就再也不要醒过来了。",
	["$sy_raomeng2"] = "梦里多好，别再给本宫添乱了。",
	[":sy_raomeng"] = "锁定技，其他角色的判定阶段开始时，若其判定区内没有牌，你令其进行【乐不思蜀】判定。",
	["sy_yongjie"] = "永劫",
	["yongjie_tome_damagetimes"] = "[永劫]伤害次数",
	["$sy_yongjie1"] = "事到如今，求死，可没有那么简单。",
	["$sy_yongjie2"] = "站错了边，等待你的，可是万劫不复。",
	[":sy_yongjie"] = "回合结束阶段，你可以选择至少一名对你造成过伤害的其他角色，除非其弃置X张牌（X为其对你造成过伤害的次数），否则你令其减1点体力上限。",
	["@sy_yongjie_discard"] = "你对%src总共造成了%dest次伤害，你须弃置%dest张牌（包括装备），否则%src令你减1点体力上限。",
	["@sy_yongjie-playerschosen"] = "【永劫】请选择至少一名对你造成过伤害的其他角色",
	["designer:mo_sunluban"] = "极略三国",
	["illustrator:mo_sunluban"] = "极略三国",
	["cv:mo_sunluban"] = "极略三国",
}

--魔孟获
mo_menghuo = sgs.General(extension, "mo_menghuo", "sgk_magic", 4, true)

--[[
	技能名：酋首
	相关武将：魔孟获
	技能描述：锁定技，当你使用普通锦囊牌指定其他角色为目标后，或当你成为其他角色使用这些牌的目标后，你令其选择一项：1.打出一张【杀】；2.你对其造成1点伤害。
	引用：sy_qiushou
]]
--
sy_qiushou = sgs.CreateTriggerSkillV2 {
	name = "sy_qiushou",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from and use.from:isAlive() and use.card and use.card:isNDTrick() then
			if use.from:objectName() == player:objectName() then
				for _, t in sgs.qlist(use.to) do
					if t:objectName() ~= player:objectName() then
						return skill:objectName()
					end
				end
			elseif use.to:contains(player) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if use.from and use.from:isAlive() and use.card and use.card:isNDTrick() then
			if use.from:objectName() == player:objectName() then
				local contains_others = false
				for _, t in sgs.qlist(use.to) do
					if t:objectName() ~= player:objectName() then
						contains_others = true
						break
					end
				end
				if contains_others then
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					for _, t in sgs.qlist(use.to) do
						if t:objectName() ~= player:objectName() then
							local slash = room:askForCard(t, "slash", "@qiushou-slash:" .. player:objectName(), data, sgs.Card_MethodResponse, player)
							if not slash then
								room:damage(sgs.DamageStruct(skill:objectName(), player, t, 1))
							end
						end
					end
				end
			elseif use.from:objectName() ~= player:objectName() then
				if use.to:contains(player) then
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					local slash = room:askForCard(use.from, "slash", "@qiushou-slash:" .. player:objectName(), data, sgs.Card_MethodResponse, player)
					if not slash then
						room:damage(sgs.DamageStruct(skill:objectName(), player, use.from, 1))
					end
				end
			end
		end
		return false
	end,
}

mo_menghuo:addSkill(sy_qiushou)

--[[
	技能名：魔兽
	相关武将：魔孟获
	技能描述：锁定技，回合开始时，你随机获得一个未拥有的效果并移除其余效果，然后摸X张牌（X为你获得此效果的次数）：
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；
	虎-令其他角色的非锁定技和装备牌失效直到其下回合结束；
	熊-你防止其他角色施加的属性伤害以外的所有负面效果。
	引用：sy_moshou, sy_moshouBuff_elephant, sy_moshouBuff_tiger, sy_moshouBuff_bear
]]
--
function activateAllSkills(vic)
	local room = vic:getRoom()
	local Qingchenglist = vic:getTag("Qingcheng"):toString():split("+")
	if #Qingchenglist > 0 then
		for _, name in ipairs(Qingchenglist) do
			room:setPlayerMark(vic, "Qingcheng" .. name, 0)
		end
		vic:removeTag("Qingcheng")
		for _, t in sgs.qlist(room:getAllPlayers()) do
			room:filterCards(t, t:getCards("he"), true)
		end
	end
	room:setPlayerMark(vic, "moshou_tiger_invalid", 0)
	room:setPlayerMark(vic, "Armor_Nullified", 0)
	room:setPlayerMark(vic, "Equips_Nullified_to_Yourself", 0)
end

local function doMoshouTiger(vic)
	local room = vic:getRoom()
	room:addPlayerMark(vic, "moshou_tiger_invalid")
	local skill_list = {}
	for _, sk in sgs.qlist(vic:getSkillList(true, true)) do
		if not table.contains(skill_list, sk:objectName()) then
			if sk:getFrequency() ~= sgs.Skill_Compulsory and sk:getFrequency() ~= sgs.Skill_Wake then
				table.insert(skill_list, sk:objectName())
			end
			if sgs.Sanguosha:getViewAsEquipSkill(sk:objectName()) then
				table.insert(skill_list, sk:objectName())
			end
		end
	end
	if not vic:getEquips():isEmpty() then
		for _, eq in sgs.qlist(vic:getEquips()) do
			if vic:hasEquipSkill(eq:objectName()) then
				table.insert(skill_list, eq:objectName())
			end
		end
	end
	room:addPlayerMark(vic, "Armor_Nullified")
	room:addPlayerMark(vic, "Equips_Nullified_to_Yourself")
	if #skill_list > 0 then
		vic:setTag("Qingcheng", sgs.QVariant(table.concat(skill_list, "+")))
		for _, skill_qc in ipairs(skill_list) do
			room:addPlayerMark(vic, "Qingcheng" .. skill_qc)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(p, p:getCards("he"), true)
			end
		end
	end
end

sy_moshou = sgs.CreateTriggerSkillV2 {
	name = "sy_moshou",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TurnStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local beasts = { "sy_moshou_elephant", "sy_moshou_tiger", "sy_moshou_bear" }
		local current_beast = -1
		if player:getTag("sy_moshou_beast"):toString():startsWith("sy_moshou_") then
			current_beast = player:getTag("sy_moshou_beast"):toString()
		end
		if current_beast ~= -1 then
			table.removeOne(beasts, current_beast)
			room:setPlayerMark(player, "&" .. current_beast .. "_Current", 0)
			if current_beast == "sy_moshou_tiger" then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					activateAllSkills(p)
					room:setPlayerMark(p, "moshou_tiger_invalid", 0)
				end
			end
		end
		local beast = beasts[math.random(1, #beasts)]
		player:setTag("sy_moshou_beast", sgs.QVariant(beast))
		room:addPlayerMark(player, beast)
		if beast == "sy_moshou_elephant" then
			room:broadcastSkillInvoke(skill:objectName(), 1)
		elseif beast == "sy_moshou_tiger" then
			room:broadcastSkillInvoke(skill:objectName(), 2)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				doMoshouTiger(p)
			end
		elseif beast == "sy_moshou_bear" then
			room:broadcastSkillInvoke(skill:objectName(), 3)
		end
		local msg = sgs.LogMessage()
		msg.from = player
		msg.arg = skill:objectName()
		msg.type = "#MoshouBeastBuff"
		msg.arg2 = beast
		room:sendLog(msg)
		player:setSkillDescriptionSwap("sy_moshou", "%beast", beast)
		room:changeTranslation(player, "sy_moshou")
		room:setPlayerMark(player, "&" .. beast .. "_Current", player:getMark(beast))
		player:drawCards(player:getMark(beast), skill:objectName())
		return false
	end,
}

sy_moshouBuff_elephant = sgs.CreateTriggerSkillV2 {
	name = "#sy_moshouBuff_elephant",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_elephant" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_elephant" then
			if damage.damage > 0 and damage.to:objectName() ~= player:objectName() and damage.to:isAlive() then
				room:broadcastSkillInvoke("sy_moshou", 1)
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#MoshouElephantBuff"
				msg.to:append(damage.to)
				msg.arg = "sy_moshou"
				room:sendLog(msg)
				throwRandomCards(true, player, damage.to, 1, "he", "sy_moshou")
				damage.to:turnOver()
			end
		end
		return false
	end,
}

sy_moshouBuff_tiger = sgs.CreateTriggerSkillV2 {
	name = "#sy_moshouBuff_tiger",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Finish and player:getMark("moshou_tiger_invalid") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Finish and player:getMark("moshou_tiger_invalid") > 0 then
			room:setPlayerMark(player, "moshou_tiger_invalid", 0)
			activateAllSkills(player)
		end
		return false
	end,
}

sy_moshouBuff_bear = sgs.CreateTriggerSkillV2 {
	name = "#sy_moshouBuff_bear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted, sgs.PreHpLost, sgs.MaxHpChange, sgs.BeforeCardsMove, sgs.MarkChange, sgs.ChainStateChange, sgs.TurnOver, sgs.EventLoseSkill },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal
				and damage.from and damage.from:objectName() ~= player:objectName()
				and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			if lose.from and lose.from:objectName() ~= player:objectName()
				and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			if change.change < 0
				and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			if
				move.from
				and move.from:objectName() == player:objectName()
				and move.to_place == sgs.Player_DiscardPile
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and x > 0
				and ((move.reason.m_playerId and move.reason.m_playerId ~= player:objectName()) or player:getPhase() == sgs.Player_NotActive)
				and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear"
			then
				return skill:objectName()
			end
		elseif event == sgs.MarkChange then
			if player:getTag("hunlie_global_resist_invalid"):toBool() then
				return skill:objectName()
			end
			local mark = data:toMark()
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) then
				if not player:getTag("hunlie_global_resist_invalid"):toBool()
					and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					return skill:objectName()
				end
			end
		elseif event == sgs.ChainStateChange then
			if not player:isChained() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		elseif event == sgs.TurnOver then
			if player:faceUp() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		elseif event == sgs.EventLoseSkill then
			if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal
				and damage.from and damage.from:objectName() ~= player:objectName() then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventDamage"
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			if lose.from and lose.from:objectName() ~= player:objectName() then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventLoseHp"
					msg.arg2 = tostring(lose.lose)
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			if change.change < 0 then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventLoseMaxhp"
					msg.arg2 = tostring(math.abs(change.change))
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			if
				move.from
				and move.from:objectName() == player:objectName()
				and move.to_place == sgs.Player_DiscardPile
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and x > 0
			then
				if (move.reason.m_playerId and move.reason.m_playerId ~= player:objectName()) or player:getPhase() == sgs.Player_NotActive then
					if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
						local msg = sgs.LogMessage()
						msg.from = player
						msg.arg = "sy_moshou"
						msg.type = "#MoshouBearPreventDiscard"
						room:sendLog(msg)
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				end
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			if player:getTag("hunlie_global_resist_invalid"):toBool() then
				return true
			end
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) then
				if not player:getTag("hunlie_global_resist_invalid"):toBool() then
					if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
						local msg = sgs.LogMessage()
						msg.from = player
						msg.arg = "sy_moshou"
						msg.type = "#MoshouBearPreventInvalidity"
						room:sendLog(msg)
						return true
					end
				end
			end
		elseif event == sgs.ChainStateChange then
			if not player:isChained() then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventChain"
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.TurnOver then
			if player:faceUp() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = "sy_moshou"
				msg.type = "#MoshouBearPreventTurnOver"
				room:sendLog(msg)
				return true
			end
		elseif event == sgs.EventLoseSkill then
			if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = "sy_moshou"
				msg.type = "#MoshouBearPreventLoseSkill"
				msg.arg2 = data:toSkillChange().skillName
				room:sendLog(msg)
				player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
				room:addPlayerMark(player, data:toSkillChange().skillName .. "_temp_skill")
				room:handleAcquireDetachSkills(player, data:toString())
				room:setPlayerMark(player, data:toString() .. "_temp_skill", 0)
			end
		end
		return false
	end,
}

mo_menghuo:addSkill(sy_moshou)
mo_menghuo:addSkill(sy_moshouBuff_elephant)
mo_menghuo:addSkill(sy_moshouBuff_tiger)
mo_menghuo:addSkill(sy_moshouBuff_bear)
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_elephant")
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_tiger")
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_bear")

sgs.LoadTranslationTable {
	["mo_menghuo"] = "魔孟获",
	["#mo_menghuo"] = "南中魔兽",
	["~mo_menghuo"] = "他是何人！",
	["sy_qiushou"] = "酋首",
	["$sy_qiushou1"] = "南中之首，岂可向蜀汉称臣！",
	["$sy_qiushou2"] = "一介书生，敢染指我的地界！",
	[":sy_qiushou"] = "锁定技，当你使用普通锦囊牌指定其他角色为目标后，或当你成为其他角色使用这些牌的目标后，你令其选择一项：1.打出一张【杀】；2.你对其造成1点伤害。",
	["@qiushou-slash"] = "%src的【酋首】被触发，请打出一张【杀】，否则%src对你造成1点伤害",
	["sy_moshou"] = "魔兽",
	["$sy_moshou1"] = "巨象之力，踏平敌阵！",
	["$sy_moshou2"] = "猛虎之威，百兽颤栗！",
	["$sy_moshou3"] = "战熊之躯，刀枪不入！",
	["sy_moshou_elephant"] = "象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面。",
	["sy_moshou_tiger"] = "虎-令其他角色的非锁定技和装备牌失效直到其下回合结束。",
	["sy_moshou_bear"] = "熊-你防止其他角色施加的属性伤害以外的所有负面效果。",
	["sy_moshou_elephant_Current"] = "魔兽-象",
	["sy_moshou_tiger_Current"] = "魔兽-虎",
	["sy_moshou_bear_Current"] = "魔兽-熊",
	[":sy_moshou"] = "锁定技，回合开始时，你随机获得一个未拥有的效果并移除其余效果，然后摸X张牌（X为你获得此效果的次数）：\
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；\
	虎-令其他角色的非锁定技和装备牌失效直到其下回合结束；\
	熊-你防止其他角色施加的属性伤害以外的所有负面效果。",
	[":sy_moshou1"] = '锁定技，回合开始时，你随机获得一个未拥有的效果并移除其余效果，然后摸X张牌（X为你获得此效果的次数）：\
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；\
	虎-令其他角色的非锁定技和装备牌失效直到其下回合结束；\
	熊-你防止其他角色施加的属性伤害以外的所有负面效果。\
	当前“魔兽”生效效果：<font color="#FF4500">%beast</font>',
	["#MoshouBeastBuff"] = "%from 的“%arg”被触发，本轮的“%arg”生效的效果是：%arg2",
	["#MoshouElephantBuff"] = "%from 的“%arg”被触发，%to 受到伤害后将被随机弃置一张牌并翻面",
	["#MoshouBearPreventDamage"] = "%from 的“%arg”被触发，防止了 %arg2 点伤害",
	["#MoshouBearPreventLoseHp"] = "%from 的“%arg”被触发，防止失去了 %arg2 点体力",
	["#MoshouBearPreventLoseMaxhp"] = "%from 的“%arg”被触发，防止失去了 %arg2 点体力上限",
	["#MoshouBearPreventDiscard"] = "%from 的“%arg”被触发，弃置牌的效果被无效",
	["#MoshouBearPreventTurnOver"] = "%from 的“%arg”被触发，翻面的效果被无效",
	["#MoshouBearPreventLoseSkill"] = "%from 的“%arg”被触发，失去技能“%arg2”的效果被无效",
	["#MoshouBearPreventInvalidity"] = "%from 的“%arg”被触发，其技能无效的效果被无效",
	["#MoshouBearPreventChain"] = "%from 的“%arg”被触发，其被横置的骁果被无效",
	["designer:mo_menghuo"] = "极略三国",
	["illustrator:mo_menghuo"] = "极略三国",
	["cv:mo_menghuo"] = "极略三国",
}

--魔张春华
mo_zhangchunhua = sgs.General(extension, "mo_zhangchunhua", "sgk_magic", 4, false)

--[[
	技能名：凋零
	相关武将：魔张春华
	技能描述：每回合限一次，当一名其他角色不因弃牌阶段弃置牌时，你可以令其改为失去等量体力。
	引用：sy_diaoling
]]
--
sy_diaoling = sgs.CreateTriggerSkillV2 {
	name = "sy_diaoling",
	events = { sgs.BeforeCardsMove },
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if move.from and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			local _from
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.from:objectName() then
					_from = p
					break
				end
			end
			local x = move.card_ids:length()
			if _from and player:getMark(skill:objectName() .. "-Clear") == 0 and _from:getPhase() ~= sgs.Player_Discard and player:objectName() ~= _from:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local _from
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() == move.from:objectName() then
				_from = p
				break
			end
		end
		if not _from then
			return false
		end
		local x = move.card_ids:length()
		local prompt = string.format("diaoling_discard:%s:%s", _from:objectName(), tostring(x))
		local _q1, _q2 = sgs.QVariant(), sgs.QVariant()
		_q1:setValue(_from)
		_q2:setValue(move)
		player:setTag("sy_diaoling_target", _q1)
		player:setTag("sy_diaoling_move", _q2)
		local invoked = player:askForSkillInvoke(skill:objectName(), sgs.QVariant(prompt))
		player:removeTag("sy_diaoling_target")
		player:removeTag("sy_diaoling_move")
		return invoked
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local _from
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() == move.from:objectName() then
				_from = p
				break
			end
		end
		if not _from then
			return false
		end
		local x = move.card_ids:length()
		room:addPlayerMark(player, skill:objectName() .. "-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		move.card_ids = sgs.IntList()
		data:setValue(move)
		room:loseHp(_from, x, true, player, skill:objectName())
		return false
	end,
}

mo_zhangchunhua:addSkill(sy_diaoling)

--[[
	技能名：扼绝
	相关武将：魔张春华
	技能描述：出牌阶段限一次，或当你受到伤害后，你可以摸两张牌并弃置其中一张牌，然后你令所有其他角色弃置点数小于此牌的所有相同类别的牌，若如此做，你从弃牌堆中随机获得每名角色以此法弃置的各一张牌。
	引用：sy_ejue
]]
--
sy_ejueCard = sgs.CreateSkillCard {
	name = "sy_ejueCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern():startsWith("@@sy_ejue") then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sy_ejue", "")
			room:throwCard(self, reason, nil)
			for _, p in sgs.qlist(room:getPlayers()) do
				for _, c in sgs.qlist(p:getCards("hej")) do
					if c:hasFlag("sy_ejue_draw") then
						room:setCardFlag(c, "-sy_ejue_draw")
					end
				end
			end
			local acard = sgs.Sanguosha:getCard(self:getSubcards():first())
			local ctype, number = acard:getTypeId(), acard:getNumber()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				room:doAnimate(1, source:objectName(), p:objectName())
			end
			local dummy1 = sgs.Sanguosha:cloneCard("slash")
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				local dummy2 = sgs.Sanguosha:cloneCard("jink")
				dummy2:deleteLater()
				for _, c in sgs.qlist(p:getCards("he")) do
					if c:getTypeId() == ctype and c:getNumber() < number then
						dummy2:addSubcard(c)
					end
				end
				if dummy2:subcardsLength() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, p:objectName(), nil, "sy_ejue", nil)
					room:throwCard(dummy2, reason, p, source)
					local to_gain = {}
					for _, id in sgs.qlist(dummy2:getSubcards()) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							table.insert(to_gain, id)
						end
					end
					if #to_gain > 0 then
						dummy1:addSubcard(to_gain[math.random(1, #to_gain)])
					end
				end
			end
			if dummy1:subcardsLength() > 0 then
				source:obtainCard(dummy1)
			end
			dummy1:deleteLater()
		else
			room:broadcastSkillInvoke("sy_ejue")
			source:drawCards(2, "sy_ejue")
			local can_ejue = false
			for _, c in sgs.qlist(source:getCards("h")) do
				if c:hasFlag("sy_ejue_draw") then
					can_ejue = true
					break
				end
			end
			if can_ejue then
				room:askForUseCard(source, "@@sy_ejue!", "@sy_ejue")
				for _, p in sgs.qlist(room:getPlayers()) do
					for _, c in sgs.qlist(p:getCards("hej")) do
						if c:hasFlag("sy_ejue_draw") then
							room:setCardFlag(c, "-sy_ejue_draw")
						end
					end
				end
			end
		end
	end,
}

sy_ejueVS = sgs.CreateViewAsSkillV2 {
	name = "sy_ejue",
	n = 1,
	will_throw_selected_cards = false,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return false
		end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:hasUsed("#sy_ejueCard")
		end
		local pattern = request:getPattern() or ""
		return pattern:startsWith("@@sy_ejue")
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate then
			return false
		end
		local pattern = request:getPattern() or ""
		if pattern:startsWith("@@sy_ejue") then
			if not request:getSelectedCardIds():isEmpty() then
				return false
			end
			local player = request:getInitiator()
			return player and (not player:isJilei(candidate)) and candidate:hasFlag("sy_ejue_draw")
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern:startsWith("@@sy_ejue") then
			return request:getSelectedCardIds():length() == 1
		end
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern() or ""
		local c = sy_ejueCard:clone()
		if pattern:startsWith("@@sy_ejue") then
			local ids = request:getSelectedCardIds()
			if ids:isEmpty() then
				return nil
			end
			for _, id in sgs.qlist(ids) do
				c:addSubcard(id)
			end
		end
		c:setSkillName(skill:objectName())
		return c
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_ejueCard")
		end
		return true
	end,
}

sy_ejue = sgs.CreateTriggerSkillV2 {
	name = "sy_ejue",
	view_as_skill = sy_ejueVS,
	events = { sgs.AfterDrawNCards, sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason == skill:objectName() and draw.who and draw.who:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason == skill:objectName() and draw.who and draw.who:objectName() == player:objectName() then
				if draw.card_ids:length() > 0 then
					for _, id in sgs.qlist(draw.card_ids) do
						if room:getCardPlace(id) == sgs.Player_PlaceHand then
							room:setCardFlag(sgs.Sanguosha:getCard(id), "sy_ejue_draw")
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			room:broadcastSkillInvoke(skill:objectName())
			player:drawCards(2, skill:objectName())
			local can_ejue = false
			for _, c in sgs.qlist(player:getCards("h")) do
				if c:hasFlag("sy_ejue_draw") then
					can_ejue = true
					break
				end
			end
			if can_ejue then
				room:askForUseCard(player, "@@sy_ejue!", "@sy_ejue")
				for _, p in sgs.qlist(room:getPlayers()) do
					for _, c in sgs.qlist(p:getCards("hej")) do
						if c:hasFlag("sy_ejue_draw") then
							room:setCardFlag(c, "-sy_ejue_draw")
						end
					end
				end
			end
		end
		return false
	end,
}

mo_zhangchunhua:addSkill(sy_ejue)

--[[
	技能名：翦灭
	相关武将：魔张春华
	技能描述：锁定技，你对手牌数小于你的角色使用的【杀】视为火【杀】且不计入次数。这些角色于你的回合内跳过濒死结算。
	引用：sy_jianmie
]]
--
sy_jianmie = sgs.CreateTriggerSkillV2 {
	name = "sy_jianmie",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ChangeSlash, sgs.EnterDying },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.ChangeSlash then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() then
				for _, t in sgs.qlist(use.to) do
					if t:getHandcardNum() < player:getHandcardNum() then
						return skill:objectName()
					end
				end
			end
		elseif event == sgs.EnterDying then
			-- player 為瀕死角色；持有者為回合角色（chunhua）
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:hasFlag("CurrentPlayer") and current:hasSkill(skill:objectName())
				and dying.who and dying.who:getSeat() ~= current:getSeat()
				and current:getHandcardNum() > dying.who:getHandcardNum() then
				return skill:objectName(), current
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.ChangeSlash then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() then
				local will_change = false
				for _, t in sgs.qlist(use.to) do
					if t:getHandcardNum() < player:getHandcardNum() then
						will_change = true
						break
					end
				end
				if will_change then
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					if not use.card:isKindOf("FireSlash") then
						local jianmie_fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
						jianmie_fire:addSubcard(use.card:getEffectiveId())
						jianmie_fire:setSkillName("_sy_jianmie")
						jianmie_fire:deleteLater()
						use.changeCard(use, jianmie_fire)
					end
					if use.m_addHistory then
						room:addPlayerHistory(player, use.card:getClassName(), -1)
						use.m_addHistory = false
					end
					data:setValue(use)
				end
			end
		elseif event == sgs.EnterDying then
			-- player 為技能持有者（current）；ctx.invoker 為瀕死角色
			local dying = data:toDying()
			local current = player
			if dying.who and dying.who:getSeat() ~= current:getSeat() and current:getHandcardNum() > dying.who:getHandcardNum() then
				local msg = sgs.LogMessage()
				msg.from = current
				msg.type = "#JianmieDie"
				msg.to:append(dying.who)
				msg.arg = skill:objectName()
				room:sendLog(msg)
				room:broadcastSkillInvoke(skill:objectName())
				if dying.damage then
					room:killPlayer(dying.who, dying.damage)
				else
					room:killPlayer(dying.who)
				end
			end
		end
		return false
	end,
}

mo_zhangchunhua:addSkill(sy_jianmie)

sgs.LoadTranslationTable {
	["mo_zhangchunhua"] = "魔张春华",
	["#mo_zhangchunhua"] = "万魂归寂",
	["~mo_zhangchunhua"] = "血色尽染，终归绝情……",
	["sy_diaoling"] = "凋零",
	["$sy_diaoling1"] = "芳华散尽，万物同朽。",
	["$sy_diaoling2"] = "命若游丝，何苦挣扎？",
	[":sy_diaoling"] = "每回合限一次，当一名其他角色不因弃牌阶段弃置牌时，你可以令其改为失去等量体力。",
	["sy_diaoling:diaoling_discard"] = "%src即将弃置%dest张牌，是否对%src发动“凋零”？（若如此做，%src本次将不再弃置%dest张牌，而是改为失去%dest点体力）",
	["sy_ejue"] = "扼绝",
	["$sy_ejue1"] = "生机已了，黄泉路近！",
	["$sy_ejue2"] = "三魂七魄，尽入我彀！",
	[":sy_ejue"] = "出牌阶段限一次，或当你受到伤害后，你可以摸两张牌并弃置其中一张牌，然后你令所有其他角色弃置点数小于此牌的所有相同类别的牌，若如此做，你从弃牌堆中"
		.. "随机获得每名角色以此法弃置的各一张牌。",
	["@sy_ejue"] = "请选择一张牌并弃置，若如此做，所有其他角色将弃置点数小于此牌的所有相同类别的牌",
	["sy_jianmie"] = "翦灭",
	["$sy_jianmie1"] = "幽冥业火，焚尽痴妄！",
	["$sy_jianmie2"] = "九州烬冷，万象归无！",
	[":sy_jianmie"] = "锁定技，你对手牌数小于你的角色使用的【杀】视为火【杀】且不计入次数。这些角色于你的回合内跳过濒死结算。",
	["#JianmieDie"] = "%from 的“%arg”被触发，由于 %to 的手牌数少于 %from 的手牌数，%to 将直接死亡",
	["designer:mo_zhangchunhua"] = "极略三国",
	["illustrator:mo_zhangchunhua"] = "极略三国",
	["cv:mo_zhangchunhua"] = "极略三国",
}

fcmk_jlsg_modiaochan = sgs.General(extension, "fcmk_jlsg_modiaochan", "sgk_magic", 3, false)

fcmk_jlsg_meihuoCard = sgs.CreateSkillCard {
	name = "fcmk_jlsg_meihuoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:isMale()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:obtainCard(effect.to, self, false)
		local targets, others = sgs.SPlayerList(), room:getOtherPlayers(effect.to)
		if effect.from:getState() == "online" then
			targets = room:askForPlayersChosen(effect.from, others, "fcmk_jlsg_meihuo", 1, others:length(), "fcmk_jlsg_meihuo-playerschosen")
		else
			local target = room:askForPlayerChosen(effect.from, others, "fcmk_jlsg_meihuo")
			targets:append(target)
			others:removeOne(target)
			while not others:isEmpty() do
				local target = room:askForPlayerChosen(effect.from, others, "fcmk_jlsg_meihuo", "", true, true)
				if not target then
					break
				end
				targets:append(target)
				others:removeOne(target)
			end
		end
		if not effect.to:hasFlag("fcmk_jlsg_meihuoATKfrom") then
			room:setPlayerFlag(effect.to, "fcmk_jlsg_meihuoATKfrom")
		end
		for _, p in sgs.qlist(targets) do
			if not p:hasFlag("fcmk_jlsg_meihuoATKto") then
				room:setPlayerFlag(p, "fcmk_jlsg_meihuoATKto")
			end
		end
		room:showAllCards(effect.to)
		while not effect.to:isKongcheng() do
			local asn = {}
			for _, cd in sgs.qlist(effect.to:getHandcards()) do
				if cd:isKindOf("Slash") or (cd:isNDTrick() and not cd:isKindOf("Nullification")) then
					table.insert(asn, cd)
				end
			end
			if #asn == 0 then
				break
			end
			local atk_card = asn[math.random(1, #asn)]
			room:useCard(sgs.CardUseStruct(atk_card, effect.to, targets))
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("fcmk_jlsg_meihuoATKfrom") then
				room:setPlayerFlag(p, "-fcmk_jlsg_meihuoATKfrom")
			end
			if p:hasFlag("fcmk_jlsg_meihuoATKto") then
				room:setPlayerFlag(p, "-fcmk_jlsg_meihuoATKto")
			end
		end
	end,
}
fcmk_jlsg_meihuoVS = sgs.CreateViewAsSkillV2 {
	name = "fcmk_jlsg_meihuo",
	n = 999,
	will_throw_selected_cards = false,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return false
		end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		return not player:hasUsed("#fcmk_jlsg_meihuoCard") and not player:isKongcheng()
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or candidate:isEquipped() then
			return false
		end
		return request:getSelectedCardIds():length() < 999
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then
			return nil
		end
		local mh_card = fcmk_jlsg_meihuoCard:clone()
		for _, id in sgs.qlist(ids) do
			mh_card:addSubcard(id)
		end
		mh_card:setSkillName(skill:objectName())
		return mh_card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#fcmk_jlsg_meihuoCard")
		end
		return true
	end,
}
fcmk_jlsg_meihuo = sgs.CreateTriggerSkillV2 { --手动筛除多余目标（专为AOE和全体增益锦囊准备）
	name = "fcmk_jlsg_meihuo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreCardUsed },
	view_as_skill = fcmk_jlsg_meihuoVS,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasFlag("fcmk_jlsg_meihuoATKfrom") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if
			use.from
			and use.from:objectName() == player:objectName()
			and use.card
			and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and not use.card:isKindOf("Nullification")))
		then
			local useto = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if p:hasFlag("fcmk_jlsg_meihuoATKto") then
					useto:append(p)
				end
			end
			use.to = useto
			data:setValue(use)
		end
		return false
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_meihuo)

fcmk_jlsg_yaoyan = sgs.CreateTriggerSkillV2 {
	name = "fcmk_jlsg_yaoyan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if
			use.from
			and use.from:objectName() ~= player:objectName()
			and use.to:contains(player)
			and use.card
			and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
		then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if
			use.from
			and use.from:objectName() ~= player:objectName()
			and use.to:contains(player)
			and use.card
			and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
		then
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			use.to:append(use.from)
			data:setValue(use)
		end
		return false
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_yaoyan)

fcmk_jlsg_miluan = sgs.CreateTriggerSkillV2 {
	name = "fcmk_jlsg_miluan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() then
			room:broadcastSkillInvoke(skill:objectName())
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isKongcheng() then
					continue
				end
				dummy:addSubcards(p:getHandcards())
				room:obtainCard(player, dummy, false)
				dummy:clearSubcards()
			end
			dummy:deleteLater()
			local n = math.floor(player:getHandcardNum() / 2)
			--local dummi = sgs.Sanguosha:cloneCard("jink")
			while n > 0 do
				local give_ids = {}
				for _, id in sgs.qlist(player:handCards()) do
					table.insert(give_ids, id)
				end
				--local g = math.random(1, n) --实测太夸张了，很容易一边倒，上限必须控
				--[[local gg = g
				while g > 0 do]]
				local give_id = give_ids[math.random(1, #give_ids)]
				--[[dummi:addSubcard(give_id)
					table.removeOne(give_ids, give_id)
					g = g - 1
				end]]
				local people = {}
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					table.insert(people, p)
				end
				local person = people[math.random(1, #people)]
				--[[room:obtainCard(person, dummi, false)
				dummi:clearSubcards()
				n = n - gg]]
				local give_card = sgs.Sanguosha:getCard(give_id)
				room:obtainCard(person, give_card, false)
				n = n - 1
			end
			--dummi:deleteLater()
		end
		return false
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_miluan)
sgs.LoadTranslationTable {
	--魔貂蝉
	["fcmk_jlsg_modiaochan"] = "魔貂蝉[极略三国]",
	["&fcmk_jlsg_modiaochan"] = "魔貂蝉",
	["#fcmk_jlsg_modiaochan"] = "狐妖的诱惑",
	["designer:fcmk_jlsg_modiaochan"] = "[极略三国-三英挑战兑换]",
	["cv:fcmk_jlsg_modiaochan"] = "极略三国",
	["illustrator:fcmk_jlsg_modiaochan"] = "极略三国",
	--魅惑
	["fcmk_jlsg_meihuo"] = "魅惑",
	[":fcmk_jlsg_meihuo"] = "出牌阶段限一次，你可以将任意张手牌交给一名其他男性角色并选择至少一名除其以外的角色，然后其展示手牌，依次对这些角色随机使用其手牌中的"
		.. "【杀】或普通锦囊牌。",
	["fcmk_jlsg_meihuo-playerschosen"] = "[魅惑]请选择至少一名除该角色外的角色，令该角色“攻击”你选择的这些角色",
	--["fcmk_jlsg_mhbe"] = "被魅了",
	["$fcmk_jlsg_meihuo1"] = "只有赢家，才能与妾身...共度良宵哦~",
	["$fcmk_jlsg_meihuo2"] = "将军，妾身可是受委屈了~",
	--妖颜
	["fcmk_jlsg_yaoyan"] = "妖颜",
	[":fcmk_jlsg_yaoyan"] = "<font color='red'><s>变身技，</s></font>锁定技，当其他角色使用基本牌或普通锦囊牌指定你为目标时，你令其也成为此牌的目标。",
	["$fcmk_jlsg_yaoyan1"] = "狐妖之魄，蚀骨销魂。",
	["$fcmk_jlsg_yaoyan2"] = "看着我的眼睛，可不要眨眼哦~",
	--迷乱
	["fcmk_jlsg_miluan"] = "迷乱",
	[":fcmk_jlsg_miluan"] = "<font color='red'><s>变身技，</s></font>当你受到伤害后，你可以获得所有其他角色的所有手牌，然后你将随机X张手牌随机分配给其他角色（X为你手牌数的一半，向下取整）"
		.. "<font color='red'><b>(注:为避免给牌“一边倒”,每次给一张)</b></font>。",
	["$fcmk_jlsg_miluan1"] = "是虚情假意，还是逢场作戏呢？",
	["$fcmk_jlsg_miluan2"] = "哼~男人的嘴，妾身可不会轻易相信~",
	--☠️阵亡
	["~fcmk_jlsg_modiaochan"] = "修罗夜叉，共坠轮回！......",
}

--魔李儒
mo_liru = sgs.General(extension, "mo_liru", "sgk_magic", 3, true)

--[[
	技能名：魔策
	相关武将：魔李儒
	技能描述：出牌阶段，你可以将随机一名角色的一张黑桃牌当【过河拆桥】使用，然后若该角色不是你，你摸一张牌。
	引用：mo_moce
]]
--
mo_moceCard = sgs.CreateSkillCard {
	name = "mo_moceCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isAllNude()
	end,
	feasible = function(self, targets, player)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local owners = {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, c in sgs.qlist(p:getCards("he")) do
				if c:getSuit() == sgs.Card_Spade then
					table.insert(owners, p)
					break
				end
			end
		end
		if #owners == 0 then
			return
		end
		local owner = owners[math.random(1, #owners)]
		local spades = {}
		for _, c in sgs.qlist(owner:getCards("he")) do
			if c:getSuit() == sgs.Card_Spade then
				table.insert(spades, c:getEffectiveId())
			end
		end
		local cid = spades[math.random(1, #spades)]
		local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_SuitToBeDecided, -1)
		dismantlement:addSubcard(cid)
		dismantlement:setSkillName("mo_moce")
		room:useCard(sgs.CardUseStruct(dismantlement, source, targets[1]))
		if owner:objectName() ~= source:objectName() and source:isAlive() then
			source:drawCards(1, "mo_moce")
		end
	end,
}

mo_moceVS = sgs.CreateViewAsSkillV2 {
	name = "mo_moce",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then
			return false
		end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, c in sgs.qlist(p:getCards("he")) do
				if c:getSuit() == sgs.Card_Spade then
					return true
				end
			end
		end
		return false
	end,
	create_card = function(skill, request)
		local mc_card = mo_moceCard:clone()
		mc_card:setSkillName(skill:objectName())
		return mc_card
	end,
}

mo_moce = sgs.CreateTriggerSkillV2 {
	name = "mo_moce",
	view_as_skill = mo_moceVS,
	events = {},
}

mo_liru:addSkill(mo_moce)

--[[
	技能名：焚劫
	相关武将：魔李儒
	技能描述：锁定技，你的回合开始时，若为：第一个回合，你令所有其他角色各加1点体力上限并摸两张牌；第二个回合，你令所有其他角色弃置所有红色牌；其他的回合，你对所有其他角色各造成2点火焰伤害。
	引用：mo_fenjie
]]
--
mo_fenjie = sgs.CreateTriggerSkillV2 {
	name = "mo_fenjie",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_RoundStart then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		room:addPlayerMark(player, "mo_fenjie_turns")
		local turn = player:getMark("mo_fenjie_turns")
		if turn == 1 then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:gainMaxHp(p, 1)
				p:drawCards(2, skill:objectName())
			end
		elseif turn == 2 then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				for _, c in sgs.qlist(p:getCards("he")) do
					if c:isRed() then
						dummy:addSubcard(c:getEffectiveId())
					end
				end
				if dummy:subcardsLength() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, p:objectName(), skill:objectName(), "")
					room:throwCard(dummy, reason, nil)
				end
				dummy:deleteLater()
			end
		else
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:damage(sgs.DamageStruct(skill:objectName(), player, p, 2, sgs.DamageStruct_Fire))
			end
		end
		return false
	end,
}

mo_liru:addSkill(mo_fenjie)

--[[
	技能名：烬灭
	相关武将：魔李儒
	技能描述：每回合每名角色限一次，当一名其他角色失去所有手牌后，若其已受伤，你可以对其造成X点火焰伤害（X为其体力值）。
	引用：mo_jinmie
]]
--
mo_jinmie = sgs.CreateTriggerSkillV2 {
	name = "mo_jinmie",
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local move = data:toMoveOneTime()
		if move.from and move.from:isAlive() and move.from:objectName() ~= player:objectName()
			and move.from_places:contains(sgs.Player_PlaceHand) and move.from:isKongcheng()
			and move.from:isWounded() and move.from:getMark("mo_jinmie-Clear") == 0
		then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local _data = sgs.QVariant()
		_data:setValue(move.from)
		return room:askForSkillInvoke(player, skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local target = move.from
		if target and target:isAlive() and target:isWounded() and target:getHp() > 0 then
			room:setPlayerMark(target, "mo_jinmie-Clear", 1)
			room:broadcastSkillInvoke(skill:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			room:damage(sgs.DamageStruct(skill:objectName(), player, target, target:getHp(), sgs.DamageStruct_Fire))
		end
		return false
	end,
}

mo_liru:addSkill(mo_jinmie)

sgs.LoadTranslationTable {
	["mo_liru"] = "魔李儒",
	["#mo_liru"] = "焚城毒士",
	["~mo_liru"] = "焚尽洛阳的火，终于也烧到了我自己……",
	["mo_moce"] = "魔策",
	["mo_moceCard"] = "魔策",
	[":mo_moce"] = "出牌阶段，你可以将随机一名角色的一张黑桃牌当【过河拆桥】使用，然后若该角色不是你，你摸一张牌。",
	["mo_fenjie"] = "焚劫",
	[":mo_fenjie"] = "锁定技，你的回合开始时，若为：第一个回合，你令所有其他角色各加1点体力上限并摸两张牌；第二个回合，你令所有其他角色弃置所有红色牌；其他的回合，你对所有其他角色各造成2点火焰伤害。",
	["mo_jinmie"] = "烬灭",
	[":mo_jinmie"] = "每回合每名角色限一次，当一名其他角色失去所有手牌后，若其已受伤，你可以对其造成X点火焰伤害（X为其体力值）。",
	["designer:mo_liru"] = "极略三国",
	["illustrator:mo_liru"] = "极略三国",
	["cv:mo_liru"] = "极略三国",
}

--魔袁术
mo_yuanshu = sgs.General(extension, "mo_yuanshu", "sgk_magic", 3, true)

--[[
	技能名：妄尊
	相关武将：魔袁术
	技能描述：锁定技，准备阶段，若你没有“玺”，你将所有其他角色的各一张牌置于武将牌上，称为“玺”；若你有“玺”，你获得一张“玺”并回复1点体力。你的摸牌数、攻击范围、使用【杀】的次数+X，你的手牌上限-X（X为玺的数量）。
	引用：mo_wangzun
	备注：收玺与取玺均随机；摸牌数修正并入本技，攻击范围／出杀次数／手牌上限三项由关联隐藏技提供。
]]--
mo_wangzun = sgs.CreateTriggerSkillV2 {
	name = "mo_wangzun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then return skill:objectName() end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" and not player:getPile("mo_wangzun_xi"):isEmpty() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			if player:getPile("mo_wangzun_xi"):isEmpty() then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local cards = p:getCards("he")
					if not cards:isEmpty() then
						local cid = cards:at(math.random(0, cards:length() - 1)):getEffectiveId()
						player:addToPile("mo_wangzun_xi", cid, true)
					end
				end
			else
				local pile = player:getPile("mo_wangzun_xi")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcard(pile:at(math.random(0, pile:length() - 1)))
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(), skill:objectName(), "")
				room:obtainCard(player, dummy, reason, true)
				dummy:deleteLater()
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then
				draw.num = draw.num + player:getPile("mo_wangzun_xi"):length()
				data:setValue(draw)
			end
		end
		return false
	end,
}

mo_wangzun_range = sgs.CreateAttackRangeSkillV2 {
	name = "#mo_wangzun_range",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:hasSkill("mo_wangzun") then
			return player:getPile("mo_wangzun_xi"):length()
		end
		return 0
	end,
}

mo_wangzun_slash = sgs.CreateTargetModSkillV2 {
	name = "#mo_wangzun_slash",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "pile:mo_wangzun_xi" },
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if ctx:getModType() == sgs.TargetModSkill_Residue
			and player and player:hasSkill("mo_wangzun") then
			return player:getPile("mo_wangzun_xi"):length()
		end
		return false
	end,
}

mo_wangzun_maxcards = sgs.CreateMaxCardsSkillV2 {
	name = "#mo_wangzun_maxcards",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:hasSkill("mo_wangzun") then
			return 0 - player:getPile("mo_wangzun_xi"):length()
		end
		return 0
	end,
}

--[[
	技能名：僭天
	相关武将：魔袁术
	技能描述：当你使用【杀】或伤害锦囊牌指定目标后，你可以令此牌伤害+1且不能被响应；若如此做，你下次受到的伤害+1。
	引用：mo_jiantian
	备注：每张牌仅询问一次（以卡牌标记判重）；“下次受到的伤害+1”按发动次数叠加。
]]--
mo_jiantian = sgs.CreateTriggerSkillV2 {
	name = "mo_jiantian",
	events = { sgs.TargetSpecified, sgs.DamageCaused, sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card
				and (use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isDamageCard()))
				and player:getMark("mo_jiantian" .. use.card:toString()) == 0 then
				return skill:objectName()
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
				and damage.card and damage.card:hasFlag("mo_jiantian_up") then
				return skill:objectName()
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName()
				and damage.damage > 0 and player:getMark("mo_jiantian_updamage") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.TargetSpecified then
			local use = ctx.original_data:toCardUse()
			room:setPlayerMark(player, "mo_jiantian" .. use.card:toString(), 1)
			return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		room:broadcastSkillInvoke(skill:objectName())
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			room:setCardFlag(use.card, "mo_jiantian_up")
			local no_respond_list = use.no_respond_list
			if not table.contains(no_respond_list, "_ALL_TARGETS") then
				table.insert(no_respond_list, "_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
			room:addPlayerMark(player, "mo_jiantian_updamage")
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("mo_jiantian_up") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local x = player:getMark("mo_jiantian_updamage")
			if x > 0 then
				room:setPlayerMark(player, "mo_jiantian_updamage", 0)
				damage.damage = damage.damage + x
				data:setValue(damage)
			end
		end
		return false
	end,
}

--[[
	技能名：冢骨
	相关武将：魔袁术
	技能描述：每回合限一次，当你受到负面效果后，你可以对所有其他角色施加此效果。
	引用：mo_zhonggu
	备注：负面效果含受到伤害、失去体力、减体力上限、被迫弃牌、翻至背面、横置、技能无效/失效类标记；
	施加的弃牌数目按本次移动牌数计。
]]--
mo_zhonggu = sgs.CreateTriggerSkillV2 {
	name = "mo_zhonggu",
	events = { sgs.Damaged, sgs.HpLost, sgs.MaxHpChanged, sgs.BeforeCardsMove, sgs.MarkChange, sgs.ChainStateChange, sgs.TurnOver },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getMark("mo_zhonggu-Clear") == 0) then return false end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then return skill:objectName() end
		elseif event == sgs.HpLost then
			local lose = data:toHpLost()
			if lose.lose > 0 then return skill:objectName() end
		elseif event == sgs.MaxHpChanged then
			if data:toMaxHp().change < 0 then return skill:objectName() end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
				and ((move.reason.m_playerId and move.reason.m_playerId ~= player:objectName()) or player:getPhase() == sgs.Player_NotActive) then
				return skill:objectName()
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) then
				return skill:objectName()
			end
		elseif event == sgs.ChainStateChange then
			if player:isChained() then return skill:objectName() end
		elseif event == sgs.TurnOver then
			if not player:faceUp() then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		room:addPlayerMark(player, "mo_zhonggu-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:doAnimate(1, player:objectName(), p:objectName())
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:damage(sgs.DamageStruct(skill:objectName(), player, p, damage.damage, damage.nature))
			end
		elseif event == sgs.HpLost then
			local lose = data:toHpLost()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:loseHp(p, lose.lose, true, player, skill:objectName())
			end
		elseif event == sgs.MaxHpChanged then
			local dif = 0 - data:toMaxHp().change
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:loseMaxHp(p, dif)
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:askForDiscard(p, skill:objectName(), move.card_ids:length(), move.card_ids:length(), false, true)
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:addPlayerMark(p, mark.name, mark.gain)
			end
		elseif event == sgs.ChainStateChange then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isChained() then room:setPlayerChained(p) end
			end
		elseif event == sgs.TurnOver then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:faceUp() then p:turnOver() end
			end
		end
		return false
	end,
}

mo_yuanshu:addSkill(mo_wangzun)
mo_yuanshu:addSkill(mo_jiantian)
mo_yuanshu:addSkill(mo_zhonggu)
mo_yuanshu:addSkill(mo_wangzun_range)
mo_yuanshu:addSkill(mo_wangzun_slash)
mo_yuanshu:addSkill(mo_wangzun_maxcards)
extension:insertRelatedSkills("mo_wangzun", "#mo_wangzun_range")
extension:insertRelatedSkills("mo_wangzun", "#mo_wangzun_slash")
extension:insertRelatedSkills("mo_wangzun", "#mo_wangzun_maxcards")

sgs.LoadTranslationTable {
	["mo_yuanshu"] = "魔袁术",
	["#mo_yuanshu"] = "冢中枯骨",
	["~mo_yuanshu"] = "蜜水……朕要蜜水……",
	["mo_wangzun"] = "妄尊",
	["mo_wangzun_xi"] = "玺",
	[":mo_wangzun"] = "锁定技，准备阶段，若你没有“玺”，你将所有其他角色的各一张牌置于武将牌上，称为“玺”；若你有“玺”，你获得一张“玺”并回复1点体力。你的摸牌数、攻击范围、使用【杀】的次数+X，你的手牌上限-X（X为玺的数量）。",
	["mo_jiantian"] = "僭天",
	[":mo_jiantian"] = "当你使用【杀】或伤害锦囊牌指定目标后，你可以令此牌伤害+1且不能被响应；若如此做，你下次受到的伤害+1。",
	["mo_zhonggu"] = "冢骨",
	[":mo_zhonggu"] = "每回合限一次，当你受到负面效果后，你可以对所有其他角色施加此效果。",
	["designer:mo_yuanshu"] = "极略三国",
	["illustrator:mo_yuanshu"] = "极略三国",
	["cv:mo_yuanshu"] = "极略三国",
}

--魔何太后
mo_hetaohou = sgs.General(extension, "mo_hetaohou", "sgk_magic", 3, false)

--[[
	技能名：噬心
	相关武将：魔何太后
	技能描述：锁定技，当其他角色于濒死状态外失去黑桃手牌后，你令其失去1点体力。
	引用：mo_shixin
]]--
mo_shixin = sgs.CreateTriggerSkillV2 {
	name = "mo_shixin",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		local hetaihou = room:findPlayerBySkillName(skill:objectName())
		if not (hetaihou and hetaihou:isAlive()) then return false end
		local move = data:toMoveOneTime()
		if not (move.from and move.from:isAlive() and move.from:objectName() ~= hetaihou:objectName()) then return false end
		local dying = room:getCurrentDyingPlayer()
		if (dying and dying:objectName() == move.from:objectName()) or move.from:getHp() < 1 then return false end
		for i = 0, math.min(move.card_ids:length(), move.from_places:length()) - 1 do
			if move.from_places:at(i) == sgs.Player_PlaceHand
				and sgs.Sanguosha:getCard(move.card_ids:at(i)):getSuit() == sgs.Card_Spade then
				return skill:objectName(), hetaihou
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if move.from and move.from:isAlive() then
			room:doAnimate(1, player:objectName(), move.from:objectName())
			room:loseHp(move.from, 1, true, player, skill:objectName())
		end
		return false
	end,
}

--[[
	技能名：血宴
	相关武将：魔何太后
	技能描述：锁定技，当其他角色于其出牌阶段使用牌后，你令其摸一张牌，若此牌为：红色，你摸一张牌；本阶段以此法获得的牌，你令其失去1点体力。
	引用：mo_xueyan
	备注：以此法获得的牌以角色标签 mo_xueyan_ids 按 id 记录，出牌阶段结束时清除。
]]--
mo_xueyan = sgs.CreateTriggerSkillV2 {
	name = "mo_xueyan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished, sgs.AfterDrawNCards, sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		local hetaihou = room:findPlayerBySkillName(skill:objectName())
		if event == sgs.CardFinished then
			if not hetaihou then return false end
			local use = data:toCardUse()
			if use.from and use.from:isAlive() and use.from:objectName() ~= hetaihou:objectName()
				and use.from:getPhase() == sgs.Player_Play then
				return skill:objectName(), hetaihou
			end
		elseif event == sgs.AfterDrawNCards then
			if not hetaihou then return false end
			local draw = data:toDraw()
			if draw.reason == skill:objectName() and draw.who then
				return skill:objectName(), hetaihou
			end
		elseif event == sgs.EventPhaseChanging then
			if player and player:getTag("mo_xueyan_ids"):toString() ~= "" then
				return skill:objectName(), hetaihou or player
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local who = use.from
			if not (who and who:isAlive()) then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			local tag = who:getTag("mo_xueyan_ids"):toString()
			local gained = {}
			if tag ~= "" then
				for _, s in ipairs(tag:split("+")) do
					local n = tonumber(s)
					if n then gained[n] = true end
				end
			end
			local reused = false
			if use.card then
				if use.card:subcardsLength() == 0 then
					reused = gained[use.card:getEffectiveId()] == true
				else
					for _, id in sgs.qlist(use.card:getSubcards()) do
						if gained[id] then reused = true break end
					end
				end
			end
			who:drawCards(1, skill:objectName())
			if use.card and use.card:isRed() then
				player:drawCards(1, skill:objectName())
			end
			if reused and who:isAlive() then
				room:doAnimate(1, player:objectName(), who:objectName())
				room:loseHp(who, 1, true, player, skill:objectName())
			end
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.who then
				local parts = {}
				local tag = draw.who:getTag("mo_xueyan_ids"):toString()
				if tag ~= "" then parts = tag:split("+") end
				for _, id in sgs.qlist(draw.card_ids) do
					table.insert(parts, tostring(id))
				end
				draw.who:setTag("mo_xueyan_ids", sgs.QVariant(table.concat(parts, "+")))
			end
		elseif event == sgs.EventPhaseChanging then
			local who = ctx.invoker or player
			if who then who:removeTag("mo_xueyan_ids") end
		end
		return false
	end,
}

--[[
	技能名：绝嗣
	相关武将：魔何太后
	技能描述：锁定技，其他角色弃牌阶段开始时，你获得其所有手牌，若其中有红桃牌，你回复1点体力；然后你随机交给其X张牌（X为其体力值，至多为你以此法获得的牌数）。
	引用：mo_juesi
]]--
mo_juesi = sgs.CreateTriggerSkillV2 {
	name = "mo_juesi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		local hetaihou = room:findPlayerBySkillName(skill:objectName())
		if not (hetaihou and hetaihou:isAlive()) then return false end
		if player and player:isAlive() and player:objectName() ~= hetaihou:objectName()
			and player:getPhase() == sgs.Player_Discard and not player:isKongcheng() then
			return skill:objectName(), hetaihou
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:isAlive()) then return false end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		local ids = target:handCards()
		local n = ids:length()
		local has_heart = false
		for _, id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then has_heart = true break end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(ids)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), skill:objectName(), "")
		room:obtainCard(player, dummy, reason, false)
		dummy:deleteLater()
		if has_heart and player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
		end
		local x = math.min(target:getHp(), n)
		if x > 0 and target:isAlive() and not player:isKongcheng() then
			local hc = {}
			for _, id in sgs.qlist(player:handCards()) do table.insert(hc, id) end
			local give = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for i = 1, math.min(x, #hc) do
				local idx = math.random(1, #hc)
				give:addSubcard(hc[idx])
				table.remove(hc, idx)
			end
			local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), skill:objectName(), "")
			room:obtainCard(target, give, reason2, false)
			give:deleteLater()
		end
		return false
	end,
}

mo_hetaohou:addSkill(mo_shixin)
mo_hetaohou:addSkill(mo_xueyan)
mo_hetaohou:addSkill(mo_juesi)

sgs.LoadTranslationTable {
	["mo_hetaohou"] = "魔何太后",
	["#mo_hetaohou"] = "鸩宴妖后",
	["~mo_hetaohou"] = "宫闱深冷，鸩酒自酌……",
	["mo_shixin"] = "噬心",
	[":mo_shixin"] = "锁定技，当其他角色于濒死状态外失去黑桃手牌后，你令其失去1点体力。",
	["mo_xueyan"] = "血宴",
	[":mo_xueyan"] = "锁定技，当其他角色于其出牌阶段使用牌后，你令其摸一张牌，若此牌为：红色，你摸一张牌；本阶段以此法获得的牌，你令其失去1点体力。",
	["mo_juesi"] = "绝嗣",
	[":mo_juesi"] = "锁定技，其他角色弃牌阶段开始时，你获得其所有手牌，若其中有红桃牌，你回复1点体力；然后你随机交给其X张牌（X为其体力值，至多为你以此法获得的牌数）。",
	["designer:mo_hetaohou"] = "极略三国",
	["illustrator:mo_hetaohou"] = "极略三国",
	["cv:mo_hetaohou"] = "极略三国",
}

--魔刘禅
mo_liushan = sgs.General(extension, "mo_liushan", "sgk_magic", 3, true)

--[[
	技能名：夺权
	相关武将：魔刘禅
	技能描述：锁定技，其他角色的回合开始时和回合结束时，你随机获得其一张手牌。若本回合你获得过该角色的红桃牌，本回合结束后你执行一个额外回合。
	引用：mo_duoquan
	备注：红桃牌标记置于牌原持有者，回合结束发动时清除。
]]--
mo_duoquan = sgs.CreateTriggerSkillV2 {
	name = "mo_duoquan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		local liushan = room:findPlayerBySkillName(skill:objectName())
		if not (liushan and liushan:isAlive()) then return false end
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:objectName() ~= liushan:objectName()
				and (player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_NotActive) then
				return skill:objectName(), liushan
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local current = room:getCurrent()
			if move.from and move.to and current
				and move.from:objectName() == current:objectName()
				and move.from:objectName() ~= liushan:objectName()
				and move.to:objectName() == liushan:objectName()
				and move.to_place == sgs.Player_PlaceHand then
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
						return skill:objectName(), liushan
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			local who = ctx.invoker
			if not (who and who:isAlive()) then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			if who:getPhase() == sgs.Player_RoundStart then
				room:setPlayerFlag(who, "-mo_duoquan_heart")
			end
			local got_heart = false
			local hc = who:getCards("h")
			if not hc:isEmpty() then
				local card = hc:at(math.random(0, hc:length() - 1))
				if card:getSuit() == sgs.Card_Heart then got_heart = true end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, who:objectName(), player:objectName(), skill:objectName(), "")
				room:obtainCard(player, card, reason, false)
			end
			if who:getPhase() == sgs.Player_NotActive and (who:hasFlag("mo_duoquan_heart") or got_heart) then
				room:setPlayerFlag(who, "-mo_duoquan_heart")
				if not room:getTag("ExtraTurn"):toBool() then
					player:gainAnExtraTurn()
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from then room:setPlayerFlag(move.from, "mo_duoquan_heart") end
		end
		return false
	end,
}

--[[
	技能名：婪乐
	相关武将：魔刘禅
	技能描述：锁定技，当其他角色使用牌时，你随机获得其一张手牌，然后若其使用的牌花色为红桃，其随机获得你一张手牌。
	引用：mo_lanle
]]--
mo_lanle = sgs.CreateTriggerSkillV2 {
	name = "mo_lanle",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		local liushan = room:findPlayerBySkillName(skill:objectName())
		if not (liushan and liushan:isAlive()) then return false end
		local use = data:toCardUse()
		if use.from and use.from:isAlive() and use.from:objectName() ~= liushan:objectName()
			and not use.from:isKongcheng() then
			return skill:objectName(), liushan
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local who = use.from
		if not (who and who:isAlive()) then return false end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local hc = who:getCards("h")
		if not hc:isEmpty() then
			local cid = hc:at(math.random(0, hc:length() - 1)):getEffectiveId()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, who:objectName(), player:objectName(), skill:objectName(), "")
			room:obtainCard(player, sgs.Sanguosha:getCard(cid), reason, false)
		end
		if use.card and use.card:getSuit() == sgs.Card_Heart and who:isAlive() and not player:isKongcheng() then
			local mine = player:getCards("h")
			local cid = mine:at(math.random(0, mine:length() - 1)):getEffectiveId()
			local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), who:objectName(), skill:objectName(), "")
			room:obtainCard(who, sgs.Sanguosha:getCard(cid), reason2, false)
		end
		return false
	end,
}

--妄断：自摸牌堆随机取 n 张指定类别牌作为临时牌；牌堆不足则尽取（入弃堆销毁以弃置处理）
local function mo_wangduan_gain(room, kindof, n)
	if room:getDrawPile():isEmpty() then room:swapPile() end
	local pool = {}
	for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf(kindof) then table.insert(pool, id) end
	end
	local ids = {}
	for i = 1, n do
		if #pool == 0 then break end
		local idx = math.random(1, #pool)
		table.insert(ids, pool[idx])
		table.remove(pool, idx)
	end
	return ids
end

mo_wangduanCard = sgs.CreateSkillCard {
	name = "mo_wangduanCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local choice = room:askForChoice(source, "mo_wangduan", "basic+trick+equip")
		local kindof = "BasicCard"
		if choice == "trick" then kindof = "TrickCard" elseif choice == "equip" then kindof = "EquipCard" end
		local others_discarded = 0
		local discards = {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, c in sgs.qlist(p:getCards("h")) do
				if not c:isKindOf(kindof) then dummy:addSubcard(c:getEffectiveId()) end
			end
			local n = dummy:subcardsLength()
			discards[p:objectName()] = n
			if n > 0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), p:objectName(), "mo_wangduan", "")
				room:throwCard(dummy, reason, p, source)
				if p:objectName() ~= source:objectName() then others_discarded = others_discarded + 1 end
			end
			dummy:deleteLater()
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local n = discards[p:objectName()] or 0
			if p:objectName() == source:objectName() then n = n + others_discarded end
			if n > 0 and p:isAlive() then
				local ids = mo_wangduan_gain(room, kindof, n)
				if #ids > 0 then
					local gain = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in ipairs(ids) do
						gain:addSubcard(id)
						if p:objectName() == source:objectName() then
							room:setCardFlag(sgs.Sanguosha:getCard(id), "mo_wangduan_temp")
						end
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), p:objectName(), "mo_wangduan", "")
					room:obtainCard(p, gain, reason, true)
					gain:deleteLater()
				end
			end
		end
	end,
}

mo_wangduanVS = sgs.CreateViewAsSkillV2 {
	name = "mo_wangduan",
	limit_scope = sgs.Skill_Limit_Phase,
	phase_name = "Play",
	max_usage_limit = 1,
	history_key = "#mo_wangduanCard",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = mo_wangduanCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

mo_wangduan = sgs.CreateTriggerSkillV2 {
	name = "mo_wangduan",
	view_as_skill = mo_wangduanVS,
	events = {},
}

mo_wangduan_maxcards = sgs.CreateMaxCardsSkillV2 {
	name = "#mo_wangduan_maxcards",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not (player and player:hasSkill("mo_wangduan")) then return 0 end
		local n = 0
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:hasFlag("mo_wangduan_temp") then n = n + 1 end
		end
		return n
	end,
}

mo_wangduan_tm = sgs.CreateTargetModSkillV2 {
	name = "#mo_wangduan_tm",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "card_flag:mo_wangduan_temp" },
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			local card = ctx:getCard()
			if card and card:hasFlag("mo_wangduan_temp") then return 9999 end
		end
		return false
	end,
}

mo_liushan:addSkill(mo_duoquan)
mo_liushan:addSkill(mo_lanle)
mo_liushan:addSkill(mo_wangduan)
mo_liushan:addSkill(mo_wangduan_maxcards)
mo_liushan:addSkill(mo_wangduan_tm)
extension:insertRelatedSkills("mo_wangduan", "#mo_wangduan_maxcards")
extension:insertRelatedSkills("mo_wangduan", "#mo_wangduan_tm")

sgs.LoadTranslationTable {
	["mo_liushan"] = "魔刘禅",
	["#mo_liushan"] = "妄乐庸君",
	["~mo_liushan"] = "此间乐，不思蜀……也不思汝等……",
	["mo_duoquan"] = "夺权",
	[":mo_duoquan"] = "锁定技，其他角色的回合开始时和回合结束时，你随机获得其一张手牌。若本回合你获得过该角色的红桃牌，本回合结束后你执行一个额外回合。",
	["mo_lanle"] = "婪乐",
	[":mo_lanle"] = "锁定技，当其他角色使用牌时，你随机获得其一张手牌，然后若其使用的牌花色为红桃，其随机获得你一张手牌。",
	["mo_wangduan"] = "妄断",
	["mo_wangduanCard"] = "妄断",
	[":mo_wangduan"] = "出牌阶段限一次，你可以选择一种牌的类别，令所有角色弃置所有非此类别的手牌并获得等量的此类别的临时牌，每有一名其他角色以此法弃置牌，你多获得一张临时牌。你以此法获得的临时牌不计入手牌上限且无次数限制。",
	["mo_wangduan:basic"] = "基本牌",
	["mo_wangduan:trick"] = "锦囊牌",
	["mo_wangduan:equip"] = "装备牌",
	["designer:mo_liushan"] = "极略三国",
	["illustrator:mo_liushan"] = "极略三国",
	["cv:mo_liushan"] = "极略三国",
}

--魔董白
mo_dongbai = sgs.General(extension, "mo_dongbai", "sgk_magic", 3, false)

--[[
	技能名：华宠
	相关武将：魔董白
	技能描述：每回合各限一次，你可以将摸牌改为随机获得其他角色的牌；你可以将受到伤害改为随机偷取其他角色的体力。
	引用：mo_huachong
	备注：兩個效果各以 mo_huachong_draw-Clear / mo_huachong_damage-Clear 記每回合一次；
	摸牌改為：將該次摸牌數歸零，改為重複 X 次隨機偷取一名有牌嘅其他角色一張牌（X=原摸牌數）；
	受傷改為：防止該傷害，隨機一名其他角色失去等量體力，然後你回復等量體力。
]]--
mo_huachong = sgs.CreateTriggerSkillV2 {
	name = "mo_huachong",
	events = { sgs.DrawNCards, sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.num <= 0 or player:getMark("mo_huachong_draw-Clear") > 0 then return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isAlive() and not p:getCards("he"):isEmpty() then
					return skill:objectName()
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and damage.damage > 0
				and player:getMark("mo_huachong_damage-Clear") == 0
				and not room:getOtherPlayers(player):isEmpty() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			return room:askForSkillInvoke(player, skill:objectName(), sgs.QVariant("draw"))
		end
		local damage = ctx.original_data:toDamage()
		return room:askForSkillInvoke(player, skill:objectName(), sgs.QVariant(damage.damage))
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		room:broadcastSkillInvoke(skill:objectName())
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			local n = draw.num
			draw.num = 0
			data:setValue(draw)
			room:setPlayerMark(player, "mo_huachong_draw-Clear", 1)
			for i = 1, n do
				local pool = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isAlive() and not p:getCards("he"):isEmpty() then pool:append(p) end
				end
				if pool:isEmpty() then break end
				local t = pool:at(math.random(0, pool:length() - 1))
				local cs = t:getCards("he")
				local card = cs:at(math.random(0, cs:length() - 1))
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, t:objectName(), player:objectName(), skill:objectName(), "")
				room:obtainCard(player, card, reason, false)
			end
			return false
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			room:setPlayerMark(player, "mo_huachong_damage-Clear", 1)
			local others = {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isAlive() then table.insert(others, p) end
			end
			if #others > 0 then
				local t = others[math.random(1, #others)]
				room:doAnimate(1, player:objectName(), t:objectName())
				room:loseHp(t, damage.damage)
				if player:isAlive() then
					local re = sgs.RecoverStruct()
					re.who = player
					re.recover = damage.damage
					room:recover(player, re)
				end
			end
			return true
		end
		return false
	end,
}

--[[
	技能名：幼魔
	相关武将：魔董白
	技能描述：锁定技，回合开始时，你令你体力、体力上限、摸牌数、使用【杀】的次数上限中最小的一项属性+2，然后随机获得两个已拥有的魔势力技能。
	引用：mo_youmo
	备注：摸牌數=2+「mo_youmo_draw」標記、出殺次數上限=1+「mo_youmo_slash」標記（只計幼魔自身累積加成）；
	並列最小時按體力→體力上限→摸牌數→殺次數順序取先；
	「已擁有嘅魔勢力技能」以本局武將池（getLimitedGeneralNames）中 sgk_magic 武將嘅可見技能、扣除你已持有嘅技能計算。
]]--
mo_youmo = sgs.CreateTriggerSkillV2 {
	name = "mo_youmo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TurnStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local stats = {
			{ "hp", player:getHp() },
			{ "maxhp", player:getMaxHp() },
			{ "draw", 2 + player:getMark("mo_youmo_draw") },
			{ "slash", 1 + player:getMark("mo_youmo_slash") },
		}
		local pick = stats[1]
		for _, s in ipairs(stats) do
			if s[2] < pick[2] then pick = s end
		end
		if pick[1] == "hp" then
			local re = sgs.RecoverStruct()
			re.who = player
			re.recover = 2
			room:recover(player, re)
		elseif pick[1] == "maxhp" then
			room:gainMaxHp(player, 2)
		elseif pick[1] == "draw" then
			room:addPlayerMark(player, "mo_youmo_draw", 2)
		elseif pick[1] == "slash" then
			room:addPlayerMark(player, "mo_youmo_slash", 2)
		end
		local pool = {}
		for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
			local g = sgs.Sanguosha:getGeneral(name)
			if g and g:getKingdom() == "sgk_magic" then
				for _, sk in sgs.qlist(g:getVisibleSkillList()) do
					local sn = sk:objectName()
					if not player:hasSkill(sn) and not table.contains(pool, sn) then
						table.insert(pool, sn)
					end
				end
			end
		end
		for i = 1, 2 do
			if #pool == 0 then break end
			local sn = pool[math.random(1, #pool)]
			table.removeOne(pool, sn)
			room:acquireSkill(player, sn)
		end
		return false
	end,
}

mo_youmo_draw_mod = sgs.CreateTriggerSkillV2 {
	name = "#mo_youmo_draw",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("mo_youmo")) then return false end
		local draw = data:toDraw()
		if draw.reason == "draw_phase" and player:getMark("mo_youmo_draw") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local draw = data:toDraw()
		draw.num = draw.num + player:getMark("mo_youmo_draw")
		data:setValue(draw)
		return false
	end,
}

mo_youmo_slash_tm = sgs.CreateTargetModSkillV2 {
	name = "#mo_youmo_slash",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "mark:mo_youmo_slash" },
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			local player = ctx:getPrimary()
			if player and player:hasSkill("mo_youmo") then
				return player:getMark("mo_youmo_slash")
			end
		end
		return false
	end,
}

mo_dongbai:addSkill(mo_huachong)
mo_dongbai:addSkill(mo_youmo)
mo_dongbai:addSkill(mo_youmo_draw_mod)
mo_dongbai:addSkill(mo_youmo_slash_tm)
extension:insertRelatedSkills("mo_youmo", "#mo_youmo_draw")
extension:insertRelatedSkills("mo_youmo", "#mo_youmo_slash")

sgs.LoadTranslationTable {
	["mo_dongbai"] = "魔董白",
	["#mo_dongbai"] = "掌上魔珠",
	["~mo_dongbai"] = "爷爷……珠儿好痛……",
	["mo_huachong"] = "华宠",
	[":mo_huachong"] = "每回合各限一次，你可以将摸牌改为随机获得其他角色的牌；你可以将受到伤害改为随机偷取其他角色的体力。",
	["mo_youmo"] = "幼魔",
	["#mo_youmo_draw"] = "幼魔",
	["#mo_youmo_slash"] = "幼魔",
	["@mo_youmo_draw"] = "幼魔摸牌",
	["@mo_youmo_slash"] = "幼魔出杀",
	[":mo_youmo"] = "锁定技，回合开始时，你令你体力、体力上限、摸牌数、使用【杀】的次数上限中最小的一项属性+2，然后随机获得两个已拥有的魔势力技能。",
	["designer:mo_dongbai"] = "极略三国",
	["illustrator:mo_dongbai"] = "极略三国",
	["cv:mo_dongbai"] = "极略三国",
}

--本擴展自建武將喺上方 gen 迴圈執行時尚未創建，
--呢度補掛隱藏全局技能名（General::addSkill 會去重，先前武將唔受影響）。
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	for _, skill_name in ipairs(sy_global_skill_names) do
		gen:addSkill(skill_name)
	end
end

return { extension }
