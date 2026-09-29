local extension = sgs.Package("mojiangprevious", sgs.Package_GeneralPack)
sgs.Sanguosha:setAudioType("mo_lvbu_old", "wushuang", "7")

sgs.LoadTranslationTable{
	["mojiangprevious"] = "极略魔武将-旧",
}


--V2 全局技能以隐藏技能名挂到所有武将；
--晚于本扩展加载的武将或换将后于结算时补挂 acquired 实例。
local sy_old_global_skill_names = {"#sy_old_sm_judge", "#sy_old_zongyu_lose", "#sy_old_maxcards", "#sy_old_clear"}
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local sy_old_ensuring_globals = false
local function sy_old_ensure_global_instances(room)
	if sy_old_ensuring_globals then return end
	if room:getTag("sy_old_globals_ensured"):toBool() then return end
	sy_old_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		sy_old_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("sy_old_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(sy_old_global_skill_names) do
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
		room:setTag("sy_old_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("sy_old_globals_ensured", sgs.QVariant(true))
	sy_old_ensuring_globals = false
end


sy_old_sm_judge = sgs.CreateTriggerSkillV2{
	name = "#sy_old_sm_judge",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge},
	global = true,
	priority = {10, 10},
	on_record = function(skill, event, room, player, ctx)
		sy_old_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		local judge = data:toJudge()
		local card = judge.card
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and (judge.reason == "sy_old_renji" or judge.reason == "sy_old_bolue") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local judge = ctx.original_data:toJudge()
		local card = judge.card
		if player:getSeat() == judge.who:getSeat() then player:obtainCard(card) end
		return false
	end
}


sy_old_zongyu_lose = sgs.CreateTriggerSkillV2{
	name = "#sy_old_zongyu_lose",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	global = true,
	on_record = function(skill, event, room, player, ctx)
		sy_old_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
	    local use = data:toCardUse()
		local card = use.card
		if card and table.contains(card:getSkillNames(), "sy_old_zongyu") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
	    room:loseHp(player, 1, true, player, "sy_old_zongyu")
		room:broadcastSkillInvoke("analeptic")
		return false
	end
}

--[[
	技能名：嗜杀
	相关武将：魔孙皓[旧]
	技能描述：锁定技，当你使用【杀】指定目标后，目标角色选择一项：①弃置两张牌，取消此【杀】对其的结算；②此【杀】不可被【闪】响应。
	引用：sy_old_shisha
]]--
sy_old_shisha = sgs.CreateTriggerSkillV2{
    name = "sy_old_shisha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if event == sgs.CardUsed then
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:notifySkillInvoked(player, "sy_old_shisha")
			room:broadcastSkillInvoke(skill:objectName())
		    for _, t in sgs.qlist(use.to) do
			    local shishaprompt = string.format("shishadiscard:%s", player:objectName())
			    if t:getEquips():length() + t:getHandcardNum() <= 1 then
					room:setPlayerFlag(t, "shisha_done")
				else
					if room:askForDiscard(t, skill:objectName(), 2, 2, true, true, shishaprompt) then
				        room:setPlayerFlag(t, "shisha_failed")
					else
						room:setPlayerFlag(t, "shisha_done")
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, t in sgs.qlist(use.to) do
				if (not t:hasFlag("shisha_failed")) and (not t:hasFlag("shisha_done")) then
			        local shishaprompt = string.format("shishadiscard:%s", player:objectName())
			        if t:getEquips():length() + t:getHandcardNum() <= 1 then
					    room:setPlayerFlag(t, "shisha_done")
				    else
					    if room:askForDiscard(t, skill:objectName(), 2, 2, true, true, shishaprompt) then
				            room:setPlayerFlag(t, "shisha_failed")
					    else
						    room:setPlayerFlag(t, "shisha_done")
						end
					end
				end
				if t:hasFlag("shisha_failed") then
					t:setFlags("-shisha_failed")
					local nullified_list = use.nullified_list
					table.insert(nullified_list, t:objectName())
					use.nullified_list = nullified_list
					ctx.original_data:setValue(use)
				elseif t:hasFlag("shisha_done") then
					t:setFlags("-shisha_done")
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
		return false
	end,
	priority = 20
}


sy_old_maxcards = sgs.CreateMaxCardsSkillV2{
	name = "#sy_old_maxcards",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if not target then return 0 end
		local n = 0
		if target:hasSkill("sy_old_shenwei") then n = n + 2 end
		if target:getMark("@ping") > 0 then n = n - target:getMark("@ping") end
		return n
	end
}


sy_old_clear = sgs.CreateTriggerSkillV2{
	name = "#sy_old_clear",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill},
	on_record = function(skill, event, room, player, ctx)
		sy_old_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			local current = room:getCurrent()
			if not current then return false end
			if current:getPhase() == sgs.Player_Finish and current:getMark("@ping") > 0 then
				return skill:objectName()
			end
			if current:getPhase() == sgs.Player_Start and not current:getPile("you"):isEmpty() then
				return skill:objectName()
			end
		elseif event == sgs.EventLoseSkill then
			local sk = data:toSkillChange().skillName
			if sk == "sy_old_taiping" or sk == "sy_old_tianyou" or sk == "sy_old_yaohuo" then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if room:getCurrent():getPhase() == sgs.Player_Finish then
				if room:getCurrent():getMark("@ping") > 0 then room:getCurrent():loseAllMarks("@ping") end
			end
			if room:getCurrent():getPhase() == sgs.Player_Start then
				local who = room:getCurrent()
				if not who:getPile("you"):isEmpty() then
					local you = who:getPile("you")
					local younum = you:length()
					local idx = -1
					if younum > 0 then
						idx = you:first()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, who:objectName(), "sy_old_tianyou","")
						local card = sgs.Sanguosha:getCard(idx)
						room:throwCard(card, reason, nil)
						younum = you:length()
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			local sk = ctx.original_data:toSkillChange().skillName
			if sk == "sy_old_taiping" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:loseAllMarks("@ping")
				end
			end
			if sk == "sy_old_tianyou" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not pe:getPile("you"):isEmpty() then
						local you = pe:getPile("you")
						local younum = you:length()
						local idx = -1
						if younum > 0 then
							idx = you:first()
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, pe:objectName(), "sy_old_tianyou","")
							local card = sgs.Sanguosha:getCard(idx)
							room:throwCard(card, reason, nil)
							younum = you:length()
						end
					end
				end
			end
			if sk == "sy_old_yaohuo" then
				local skills = player:getTag("Skills"):toString():split("+")
				room:handleAcquireDetachSkills(player, "-"..table.concat(skills, "|-"))
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("yaodao") then
						local yaodao_skills = p:getTag("sy_old_yaohuoSkills"):toString():split("+")
						room:handleAcquireDetachSkills(p, table.concat(yaodao_skills, "|"))
					end
				end
			end
		end
		return false
	end
}


sy_old_tianyouPro = sgs.CreateProhibitSkill{
    name = "#sy_old_tianyouPro",
	is_prohibited = function(self, from, to, card)
		local you = to:getPile("you")
		local X = you:length()
		if X > 0 then
			local youid = you:first()
			local youcard = sgs.Sanguosha:getCard(youid)
			return (to:objectName() ~= from:objectName()) and card:sameColorWith(youcard) 
					and (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic"))
					and card:getTypeId() ~= sgs.Card_TypeSkill and to:getPhase() == sgs.Player_NotActive
		else
			return false
		end
	end
}


local sy_old_hiddenskills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_old_sm_judge") then sy_old_hiddenskills:append(sy_old_sm_judge) end
if not sgs.Sanguosha:getSkill("sy_old_shisha") then sy_old_hiddenskills:append(sy_old_shisha) end
if not sgs.Sanguosha:getSkill("#sy_old_zongyu_lose") then sy_old_hiddenskills:append(sy_old_zongyu_lose) end
if not sgs.Sanguosha:getSkill("#sy_old_maxcards") then sy_old_hiddenskills:append(sy_old_maxcards) end
if not sgs.Sanguosha:getSkill("#sy_old_clear") then sy_old_hiddenskills:append(sy_old_clear) end
if not sgs.Sanguosha:getSkill("#sy_old_tianyouPro") then sy_old_hiddenskills:append(sy_old_tianyouPro) end
sgs.Sanguosha:addSkills(sy_old_hiddenskills)


sgs.LoadTranslationTable{
	["sy_old_shisha"] = "嗜杀",
	[":sy_old_shisha"] = "锁定技，其他角色响应你使用的【杀】时选择一项：①弃置两张牌并取消之；②此【杀】不可被【闪】响应。",
	["$sy_old_shisha"] = "净是些碍眼的家伙，都杀！都杀！",
	["shishadiscard"] = "%src的<font color = 'yellow'><b>【嗜杀】</b></font>被触发，你须弃置2张牌取消此【杀】对你的结算，否则此【杀】不可被【闪】响应。",
	["#WushuangTagTest"] = "%from 的Wushuang_的tag是 %arg",
	["#sy_old_tianyouPro"] = "天佑",
}


--魔吕布[旧]
mo_lvbu_old = sgs.General(extension, "mo_lvbu_old", "sgk_magic", 4, true)


--[[
	技能名：神威
	相关武将：魔吕布[旧]
	技能描述：锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限+2。
	引用：sy_old_shenwei
]]--
sy_old_shenwei = sgs.CreateTriggerSkillV2{
    name = "sy_old_shenwei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if player and player:isAlive() and player:hasSkill(skill:objectName()) and draw.reason == "draw_phase" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
		draw.num = draw.num + 2
		ctx.original_data:setValue(draw)
		return false
	end
}


--[[
	技能名：修罗
	相关武将：魔吕布[旧]
	技能描述：准备阶段，若你的判定区内有牌，则你可以弃置一张牌，然后弃置判定区内一张与该牌花色相同的牌。你可以重复此流程。
	引用：sy_old_xiuluo
]]--
local hasDelayedTrickXiuluo = function(target)
	for _, card in sgs.qlist(target:getJudgingArea()) do
		if not card:isKindOf("SkillCard") then return true end
	end
	return false
end

sy_old_xiuluo = sgs.CreateTriggerSkillV2{
	name = "sy_old_xiuluo" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if (player and player:isAlive() and player:hasSkill(skill:objectName()))
				and (player:getPhase() == sgs.Player_Start)
				and player:canDiscard(player, "h")
				and hasDelayedTrickXiuluo(player) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
			local suits = {}
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if not containsTable(suits, jcard:getSuitString()) then
					table.insert(suits, jcard:getSuitString())
				end
			end
			local card = room:askForCard(player, ".|" .. table.concat(suits, ",") .. "|.|hand", "@xiuluo", sgs.QVariant(), skill:objectName())
			if (not card) or (not hasDelayedTrickXiuluo(player)) then break end
			local avail_list = sgs.IntList()
			local other_list = sgs.IntList()
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if jcard:isKindOf("SkillCard") then
				elseif jcard:getSuit() == card:getSuit() then
					avail_list:append(jcard:getEffectiveId())
				else
					other_list:append(jcard:getEffectiveId())
				end
			end
			local all_list = sgs.IntList()
			for _, l in sgs.qlist(avail_list) do
				all_list:append(l)
			end
			for _, l in sgs.qlist(other_list) do
				all_list:append(l)
			end
			room:fillAG(all_list, nil, other_list)
			local id = room:askForAG(player, avail_list, false, skill:objectName())
			room:clearAG()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sy_old_xiuluo","")
			local card = sgs.Sanguosha:getCard(id)
			room:throwCard(card, reason, nil)
			room:broadcastSkillInvoke(skill:objectName())
		end
		return false
	end
}


mo_lvbu_old:addSkill("wushuang")
mo_lvbu_old:addSkill("mashu")
mo_lvbu_old:addSkill(sy_old_xiuluo)
mo_lvbu_old:addSkill(sy_old_shenwei)
mo_lvbu_old:addSkill("sy_shenji")


sgs.LoadTranslationTable{
	["mo_lvbu_old"] = "魔吕布[旧]",
	["&mo_lvbu_old"] = "魔吕布",
	["#mo_lvbu_old"] = "暴怒战神",
	["~mo_lvbu_old"] = "我在地狱等着你们！",
	["sy_old_shenwei"] = "神威",
	["#sy_old_shenwei"] = "神威",
	["$sy_old_shenwei"] = "唔唔唔唔唔唔——！！！",
	[":sy_old_shenwei"] = "锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限+2。",
	["$wushuang7"] = "这就让你去死！",
	["sy_old_xiuluo"] = "修罗",
	["$sy_old_xiuluo"] = "不可饶恕，不可饶恕！",
	[":sy_old_xiuluo"] = "准备阶段，你可以先弃置一张与你判定区里的一张花色相同的手牌，然后弃置判定区里的这张牌。你可以重复此流程。",
	["designer:mo_lvbu_old"] = "极略三国",
	["illustrator:mo_lvbu_old"] = "极略三国",
	["cv:mo_lvbu_old"] = "极略三国",
}


--魔董卓[旧]
mo_dongzhuo_old = sgs.General(extension, "mo_dongzhuo_old", "sgk_magic", 4, true)


--[[
	技能名：纵欲
	相关武将：魔董卓[旧]
	技能描述：出牌阶段限一次，你可以失去一点体力，视为你使用一张【酒】。
	引用：sy_old_zongyu
]]--
sy_old_zongyu = sgs.CreateViewAsSkillV2{
	name = "sy_old_zongyu",
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Analeptic_IsAvailable(player) and player:getHp() >= 2
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@sy_old_zongyu"
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(skill:objectName())
		return analeptic
	end
}


--[[
	技能名：凌虐
	相关武将：魔董卓[旧]
	技能描述：出牌阶段，每当你使用【杀】造成伤害后，你可以进行一次判定，若判定结果为黑色，你获得该判定牌且该【杀】不计入每回合使用限制。
	引用：sy_old_lingnue
]]--
sy_old_lingnue = sgs.CreateTriggerSkillV2{
	name = "sy_old_lingnue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damage, sgs.FinishJudge},
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.FinishJudge then
			if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
			local judge = ctx.original_data:toJudge()
			local card = judge.card
			if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and judge.reason == "sy_old_lingnue"  then
				if player:getSeat() == judge.who:getSeat() and judge:isGood() then player:obtainCard(card) end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damage then return false end
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) and player:getPhase() == sgs.Player_Play then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:notifySkillInvoked(player, "sy_old_lingnue")
		room:broadcastSkillInvoke("sy_old_lingnue")
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.pattern = ".|black"
		judge.reason = skill:objectName()
		judge.good = true
		room:judge(judge)
		if judge:isGood() then
			local use = ctx.original_data:toCardUse()
			if use.m_addHistory then room:addPlayerHistory(player, damage.card:getClassName(), -1) end
		end
		return false
	end
}


--[[
	技能名：暴政
	相关武将：魔董卓[旧]
	技能描述：锁定技，其他角色摸牌阶段结束时，若该角色手牌数大于你，则须选择一项：交给你一张方块牌或受到你造成的1点伤害。
	引用：sy_old_baozheng
]]--
sy_old_baozheng = sgs.CreateTriggerSkillV2{
	name = "sy_old_baozheng",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if s:objectName() ~= player:objectName() and s:isAlive() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, s:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		if invoker:getHandcardNum() > player:getHandcardNum() then
			local dz = sgs.QVariant()
			dz:setValue(player)
			local card = room:askForCard(invoker, ".|diamond", "@baozheng_old:" .. player:objectName(), dz, sgs.Card_MethodNone)
			room:doAnimate(1, player:objectName(), invoker:objectName())
			if card then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke("sy_old_baozheng")
				room:notifySkillInvoked(player, "sy_old_baozheng")
				player:obtainCard(card)
			else
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke("sy_old_baozheng")
				room:notifySkillInvoked(player, "sy_old_baozheng")
				room:damage(sgs.DamageStruct(skill:objectName(), player, invoker))
			end
		end
		return false
	end
}


--[[
	技能名：逆施
	相关武将：魔董卓[旧]
	技能描述：锁定技，摸牌阶段，你摸X张牌（X为你的当前体力值且至多为4）。
	引用：sy_old_shenwei
]]--
sy_old_nishi = sgs.CreateTriggerSkillV2{
	name = "sy_old_nishi",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
		draw.num = draw.num - 2 + math.min(4, player:getHp())
		ctx.original_data:setValue(draw)
		return false
	end
}


--[[
	技能名：横行
	相关武将：魔董卓[旧]
	技能描述：当其他角色使用【杀】指定你为目标时，你可以弃置X张牌（X为你当前体力值），则该【杀】对你无效。
	引用：sy_old_hengxing
]]--
sy_old_hengxing = sgs.CreateTriggerSkillV2{
	name = "sy_old_hengxing",
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local k = sgs.QVariant()
		k:setValue(use.from)
		player:setTag("hengxing", k)
		local ok = use.card:isKindOf("Slash") and use.to:contains(player) and player:getEquips():length() + player:getHandcardNum() >= math.max(1, player:getHp())
		if ok then ok = player:askForSkillInvoke(skill:objectName(), ctx.original_data) end
		if not ok then
			player:removeTag("hengxing")
			return false
		end
		player:setFlags("-hengxingtarget")
		player:setFlags("hengxingtarget")
		room:notifySkillInvoked(player, "sy_old_hengxing")
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if player:isAlive() and player:hasFlag("hengxingtarget") then
			player:setFlags("-hengxingtarget")
			room:askForDiscard(player, skill:objectName(), math.max(1, player:getHp()), math.max(1, player:getHp()), false, true)
			room:broadcastSkillInvoke(skill:objectName())
			local nullified_list = use.nullified_list
			table.insert(nullified_list, player:objectName())
			use.nullified_list = nullified_list
			ctx.original_data:setValue(use)
		end
		player:removeTag("hengxing")
		return false
	end
}


mo_dongzhuo_old:addSkill(sy_old_zongyu)
mo_dongzhuo_old:addSkill(sy_old_lingnue)
mo_dongzhuo_old:addSkill(sy_old_baozheng)
mo_dongzhuo_old:addSkill(sy_old_nishi)
mo_dongzhuo_old:addSkill(sy_old_hengxing)


sgs.LoadTranslationTable{
	["mo_dongzhuo_old"] = "魔董卓[旧]",
	["&mo_dongzhuo_old"] = "魔董卓",
	["#mo_dongzhuo_old"] = "狱魔王",
	["~mo_dongzhuo_old"] = "那酒池肉林……都是我的……",
	["sy_old_zongyu"] = "纵欲",
	["$sy_old_zongyu"] = "呃……好酒！再来一壶！",
	[":sy_old_zongyu"] = "出牌阶段限一次，你可以失去1点体力，视为使用【酒】。",
	["sy_old_lingnue"] = "凌虐",
	["$sy_old_lingnue"] = "来人！活捉了他！斩首祭旗！",
	[":sy_old_lingnue"] = "出牌阶段，每当你使用【杀】造成伤害后，你可以判定，若结果为黑色，你获得该判定牌，然后令你此阶段内可使用【杀】的次数上限+1。",
	["sy_old_baozheng"] = "暴政",
	["$sy_old_baozheng"] = "顺我者昌，逆我者亡！",
	[":sy_old_baozheng"] = "锁定技，其他角色摸牌阶段结束时，若其手牌数大于你，除非其交给你一张方片牌，否则你对其造成1点伤害。",
	["@baozheng_old"] = "【暴政】效果触发，请交给%src一张方块牌，否则受到一点伤害。",
	["sy_old_nishi"] = "逆施",
	["$sy_old_nishi"] = "看我不活剐了你们！",
	[":sy_old_nishi"] = "锁定技，摸牌阶段，你摸X张牌（X为你的体力值且至多为4）。",
	["sy_old_hengxing"] = "横行",
	["$sy_old_hengxing"] = "都被我踏平吧！哈哈哈哈哈哈哈哈！",
	[":sy_old_hengxing"] = "当成为【杀】的目标后，你可以弃置X张牌（X为你的体力值），取消此【杀】对你的结算。",
	["designer:mo_dongzhuo_old"] = "极略三国",
	["illustrator:mo_dongzhuo_old"] = "极略三国",
	["cv:mo_dongzhuo_old"] = "极略三国",
}


--魔张角[旧]
mo_zhangjiao_old = sgs.General(extension, "mo_zhangjiao_old", "sgk_magic", 4, true)


--[[
	技能名：布教
	相关武将：魔张角[旧]
	技能描述：锁定技，其他角色出牌阶段开始时，其须交给你一张手牌，然后摸一张牌。
	引用：sy_old_bujiao
]]--
sy_old_bujiao = sgs.CreateTriggerSkillV2{
	name = "sy_old_bujiao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if s:objectName() ~= player:objectName() and s:isAlive() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, s:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		if invoker:getHandcardNum() > 0 then
			room:doAnimate(1, player:objectName(), invoker:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			room:notifySkillInvoked(player, "sy_old_bujiao")
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			local zj = sgs.QVariant()
			zj:setValue(player)
			local card = room:askForCard(invoker, ".!", "@bujiao:" .. player:objectName(), zj, sgs.Card_MethodNone)
			room:obtainCard(player, card, false)
			invoker:drawCards(1)
		end
		return false
	end
}


--[[
	技能名：太平
	相关武将：魔张角[旧]
	技能描述：每当你受到1点伤害后，你可以令一名其他角色获得一枚“平”标记。其他角色每有一枚“平”标记，手牌上限-1。一名角色的回合结束之后，你弃置其全部的“平”标记。
	引用：sy_old_taiping
]]--
sy_old_taiping = sgs.CreateTriggerSkillV2{
	name = "sy_old_taiping",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, "sy_old_taiping")
		for i = 1, damage.damage, 1 do
			local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName())
			dest:gainMark("@ping")
		end
		return false
	end
}


--[[
	技能名：妖惑
	相关武将：魔张角[旧]
	技能描述：出牌阶段限一次，你可以指定一名有手牌的其他角色并弃置等同于其手牌数的牌，然后选择一项：获得其所有手牌；或获得其当前的所有技能直到回合结束（限定
	技、觉醒技除外）。
	引用：sy_old_yaohuo
]]--
sy_old_yaohuoCard = sgs.CreateSkillCard{
	name = "sy_old_yaohuoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:getHandcardNum() > 0 and to_select:objectName() ~= player:objectName() 
			and player:getHandcardNum() + player:getEquips():length() >= to_select:getHandcardNum()
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = sgs.Sanguosha:currentRoom()
		local n = effect.to:getHandcardNum()
		room:askForDiscard(effect.from, "sy_old_yaohuo", n, n, false, true)
		local choices = {"yaohuo_card"}
		local count = 0
		local skill_list = effect.to:getVisibleSkillList()
		local sks = {}
		for _,sk in sgs.qlist(skill_list) do
			if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() then
				if sk:getFrequency() ~= sgs.Skill_Limited then
					if sk:getFrequency() ~= sgs.Skill_Wake then
						table.insert(sks, sk:objectName())
						count = 1
					end
				end
			end
		end
		if count > 0 then
			table.insert(choices, "yaohuo_skill")
		end
		local choice = room:askForChoice(effect.from, "sy_old_yaohuo", table.concat(choices, "+"))
		if choice == "yaohuo_card" then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, cd in sgs.qlist(effect.to:getHandcards()) do
				dummy:addSubcard(cd)
			end
			room:obtainCard(effect.from, dummy, false)
			dummy:deleteLater()
		elseif choice == "yaohuo_skill" then
			room:handleAcquireDetachSkills(effect.from, table.concat(sks, "|"))
			room:handleAcquireDetachSkills(effect.to, "-"..table.concat(sks, "|-"))
			effect.to:setTag("sy_old_yaohuoSkills", sgs.QVariant(table.concat(sks, "+")))
			room:setPlayerFlag(effect.to, "yaodao")
			local skills = effect.from:getTag("Skills"):toString():split("+")
			table.insert(skills, table.concat(sks, "+"))
			effect.from:setTag("Skills", sgs.QVariant(table.concat(skills, "+")))
		end
	end
}

sy_old_yaohuoVs = sgs.CreateViewAsSkillV2{
	name = "sy_old_yaohuo",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sy_old_yaohuoCard") or player:hasUsed("sy_old_yaohuo"))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = sy_old_yaohuoCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_yaohuoCard")
		end
		return true
	end,
}

sy_old_yaohuo = sgs.CreateTriggerSkillV2{
	name = "sy_old_yaohuo",
	view_as_skill = sy_old_yaohuoVs,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if data:toPhaseChange().to == sgs.Player_NotActive and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local skills = player:getTag("Skills"):toString():split("+")
		room:handleAcquireDetachSkills(player, "-"..table.concat(skills, "|-"))
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("yaodao") then
				local yaodao_skills = p:getTag("sy_old_yaohuoSkills"):toString():split("+")
				room:handleAcquireDetachSkills(p, table.concat(yaodao_skills, "|"))
			end
		end
		return false
	end
}


--[[
	技能名：三治
	相关武将：魔张角[旧]
	技能描述：出牌阶段限一次，你可以弃置任意种不同类别的手牌各一张，然后对等量的其他角色各造成1点伤害。
	引用：sy_old_yaohuo
]]--
sy_old_sanzhiCard = sgs.CreateSkillCard{
	name = "sy_old_sanzhiCard",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < self:subcardsLength()
	end,
	feasible = function(self, targets, player)
	    return #targets == self:subcardsLength() and #targets > 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:damage(sgs.DamageStruct("sy_old_sanzhi", effect.from, effect.to))
	end,
}

sy_old_sanzhi = sgs.CreateViewAsSkillV2{
	name = "sy_old_sanzhi",
	n = 3,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sy_old_sanzhiCard") or player:hasUsed("sy_old_sanzhi"))
	end,
	can_select_card = function(skill, request, card)
		if not card or card:isEquipped() then return false end
		if request:getSelectedCardIds():length() >= 3 then return false end
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			if sgs.Sanguosha:getCard(id):getTypeId() == card:getTypeId() then return false end
		end
		return true
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local card = sy_old_sanzhiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_sanzhiCard")
		end
		return true
	end,
}


mo_zhangjiao_old:addSkill(sy_old_bujiao)
mo_zhangjiao_old:addSkill(sy_old_taiping)
mo_zhangjiao_old:addSkill(sy_old_yaohuo)
mo_zhangjiao_old:addSkill(sy_old_sanzhi)


sgs.LoadTranslationTable{	
	["mo_zhangjiao_old"] = "魔张角[旧]",
	["&mo_zhangjiao_old"] = "魔张角",
	["#mo_zhangjiao_old"] = "大贤良师",
	["~mo_zhangjiao_old"] = "逆道者，必遭天谴而亡！",
	["sy_old_bujiao"] = "布教",
	["$sy_old_bujiao"] = "众星熠熠，不若一日之明。",
	[":sy_old_bujiao"] = "锁定技，其他角色的出牌阶段开始时，你令其交给你一张手牌，然后摸一张牌。",
	["@bujiao"] = "请交给%src一张手牌，然后摸一张牌。",
	["sy_old_taiping"] = "太平",
	["$sy_old_taiping"] = "行大舜之道，救苍生万民。",
	[":sy_old_taiping"] = "当你受到1点伤害后，你可以令一名其他角色获得1枚“平”标记。其他角色手牌上限-X（“平”标记数）。一名角色的回合结束之后，弃置其拥有的全部"..
	"“平”标记。",
	["@ping"] = "平",
	["sy_old_yaohuo"] = "妖惑",
	["sy_old_yaohuoCard"] = "妖惑",
	["$sy_old_yaohuo"] = "存恶害义，善必诛之！",
	[":sy_old_yaohuo"] = "出牌阶段限一次，你可以指定一名有手牌的其他角色并弃置等同于其手牌数的牌，然后选择一项：\
	1. 获得其所有手牌；\
	2. 获得其所有技能且其失去所有技能（限定技、觉醒技除外）直到回合结束。",
	["yaohuo_card"] = "获得其所有手牌",
	["yaohuo_skill"] = "获得其所有技能且其失去所有技能（限定技、觉醒技除外）",
	["sy_old_sanzhi"] = "三治",
	["sy_old_sanzhiCard"] = "三治",
	["$sy_old_sanzhi"] = "三气集，万物治！",
	[":sy_old_sanzhi"] = "出牌阶段限一次，你可以弃置至少一张不同类别的手牌，然后对等量的其他角色各造成1点伤害。",
	["designer:mo_zhangjiao_old"] = "极略三国",
	["illustrator:mo_zhangjiao_old"] = "极略三国",
	["cv:mo_zhangjiao_old"] = "极略三国",
}


--魔张让[旧]
mo_zhangrang_old = sgs.General(extension, "mo_zhangrang_old", "sgk_magic", 4, true, true)


--[[
	技能名：谗陷
	相关武将：魔张让[旧]
	技能描述：出牌阶段限一次，你可以展示一张手牌并将之交给一名角色，该角色选择一项：交给你一张点数大于此牌的手牌，然后弃置一张牌；或对除你以外的一名角色造成
	1点伤害。
	引用：sy_old_chanxian
]]--
sy_old_chanxianCard = sgs.CreateSkillCard{
    name = "sy_old_chanxianCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
        if #targets == 0 then
		    return to_select:objectName() ~= player:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), "sy_old_chanxian", "")
		room:obtainCard(target, self, reason, true)
		local star_card, x
		for _, icard in sgs.qlist(self:getSubcards()) do
		    star_card = sgs.Sanguosha:getCard(icard)
			x = star_card:getNumber()
		end
		room:setPlayerMark(target, "AI_chanxian", x)
		local prompt = string.format("@sy_old_chanxian:%s:%s", source:objectName(), star_card:getNumberString())
		local c
		local n = sgs.QVariant()
		n:setValue(x)
		if x >= 1 and x <= 11 then
			c = room:askForCard(target, ".|.|" .. tostring(x+1) .. "~" .. "13|hand", prompt, n, sgs.Card_MethodNone)
		elseif x == 12 then
		    c = room:askForCard(target, ".|.|13|hand", prompt, n, sgs.Card_MethodNone)
		elseif x == 13 then
		    local t = room:askForPlayerChosen(target, room:getOtherPlayers(source), "sy_old_chanxian")
			if t then
			    room:damage(sgs.DamageStruct("sy_old_chanxian", target, t))
			end
			return false
		end
		if not c then
		    local t = room:askForPlayerChosen(target, room:getOtherPlayers(source), "sy_old_chanxian")
			if t then
			    room:damage(sgs.DamageStruct("sy_old_chanxian", target, t))
			end
		else
		    source:obtainCard(c, true)
			if not target:isNude() then
			    room:askForDiscard(target, "sy_old_chanxian", 1, 1, false, true)
			end
		end
	end
}

sy_old_chanxian = sgs.CreateViewAsSkillV2{
    name = "sy_old_chanxian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return (not player:isKongcheng()) and (not (player:hasUsed("#sy_old_chanxianCard") or player:hasUsed("sy_old_chanxian")))
	end,
	can_select_card = function(skill, request, card)
		return card and not card:isEquipped() and request:getSelectedCardIds():isEmpty()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sy_old_chanxianCard:clone()
		card:addSubcard(ids:first())
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_chanxianCard")
		end
		return true
	end,
}


--[[
	技能名：乱政
	相关武将：魔张让[旧]
	技能描述：锁定技，若场上存活角色数不小于3，则其他角色使用的【杀】、【顺手牵羊】、【过河拆桥】、【决斗】指定你为目标时，须额外指定一名角色（不得为此牌的使
	用者）为目标，否则此牌对你无效。
	引用：sy_old_luanzheng
]]--
sy_old_luanzheng = sgs.CreateTriggerSkillV2{
    name = "sy_old_luanzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if room:getAlivePlayers():length() <= 2 then return false end
		local use = data:toCardUse()
		if use.to:contains(player) and use.from:objectName() ~= player:objectName()
			and (use.card:isKindOf("Duel") or use.card:isKindOf("Dismantlement")
				or use.card:isKindOf("Snatch") or use.card:isKindOf("Slash")) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local targets = room:getOtherPlayers(player)
		targets:removeOne(use.from)
		room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
		room:notifySkillInvoked(player, "sy_old_luanzheng")
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		if use.card:isKindOf("Duel") or use.card:isKindOf("Slash") then
			for _, p in sgs.qlist(targets) do
				if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
					targets:removeOne(p)
					if targets:isEmpty() then break end
				end
				if p:hasSkill("kongcheng") and p:isKongcheng() then
					targets:removeOne(p)
					if targets:isEmpty() then break end
				end
			end
		elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
			for _, p in sgs.qlist(targets) do
				if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
					targets:removeOne(p)
					if targets:isEmpty() then break end
				end
				if p:isAllNude() then
					targets:removeOne(p)
					if targets:isEmpty() then break end
				end
			end
		end
		if targets:isEmpty() then
			room:setPlayerFlag(player, "sy_old_luanzheng_failed")
			return false
		end
		local choices = {"sy_old_luanzhengextratarget", "sy_old_luanzhengfail"}
		local choice = room:askForChoice(use.from, "sy_old_luanzheng", table.concat(choices, "+"))
		if choice == "sy_old_luanzhengextratarget" then
			local T = room:askForPlayerChosen(use.from, targets, "sy_old_luanzheng", nil, false, true)
			if T then
				use.to:append(T)
				room:sortByActionOrder(use.to)
				ctx.original_data:setValue(use)
				room:getThread():trigger(sgs.TargetConfirming, room, T, ctx.original_data)
				return false
			else
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				ctx.original_data:setValue(use)
			end
		else
			local nullified_list = use.nullified_list
			table.insert(nullified_list, player:objectName())
			use.nullified_list = nullified_list
			ctx.original_data:setValue(use)
		end
		return false
	end
}


mo_zhangrang_old:addSkill(sy_old_chanxian)
mo_zhangrang_old:addSkill(sy_old_luanzheng)
mo_zhangrang_old:addSkill("sy_canlue")


sgs.LoadTranslationTable{	
	["mo_zhangrang_old"] = "魔张让[旧]",
	["&mo_zhangrang_old"] = "魔张让",
	["~mo_zhangrang_old"] = "小的怕是活不成了……陛下……保重……",
	["#mo_zhangrang_old"] = "祸乱之源",
	["sy_old_chanxian"] = "谗陷",
	["sy_old_chanxianCard"] = "谗陷",
	["@sy_old_chanxian"] = "请交给%src一张点数大于%dest的手牌。",
	["sy_old_chanxianeCard"] = "谗陷",
	["$sy_old_chanxian1"] = "懂不懂宫里的规矩？",
	["$sy_old_chanxian2"] = "活得不耐烦了吧？",
	[":sy_old_chanxian"] = "出牌阶段限一次，你可以展示一张手牌并将之交给一名其他角色，令其选择一项：\
	1. 交给你一张点数大于此牌的手牌，然后弃置一张牌；\
	2. 对除你以外的一名角色造成1点伤害。",
	["sy_old_luanzheng"] = "乱政",
	["#sy_old_luanzheng"] = "乱政",
	["$sy_old_luanzheng1"] = "陛下，都、都是他们干的！",
	["$sy_old_luanzheng2"] = "大、大、大事不好！有人造反了！",
	[":sy_old_luanzheng"] = "锁定技，若场上存活角色数不小于3，其他角色使用的【杀】、【顺手牵羊】、【过河拆桥】、【决斗】指定你为目标时，除非额外指定一名角色（"..
	"不得为使用者）为目标，否则取消此牌对你的结算。",
	["sy_old_luanzhengextratarget"] = "你为这张牌额外指定一名目标，该牌对其继续生效",
	["sy_old_luanzhengfail"] = "你不为这张牌额外指定目标，取消该牌对其的结算",
	["designer:mo_zhangrang_old"] = "极略三国",
	["illustrator:mo_zhangrang_old"] = "极略三国",
	["cv:mo_zhangrang_old"] = "极略三国",
}


--魔魏延[旧]
mo_weiyan_old = sgs.General(extension, "mo_weiyan_old", "sgk_magic", 4, true, true)


--[[
	技能名：恃傲
	相关武将：魔魏延[旧]
	技能描述：准备阶段/结束阶段开始时，你可以视为对手牌数小于/大于你的一名其他角色使用一张【杀】。
	引用：sy_old_shiao
]]--
sy_old_shiao = sgs.CreateTriggerSkillV2{
	name = "sy_old_shiao",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("sy_old_shiao")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() < player:getHandcardNum() then
					if not sgs.Sanguosha:isProhibited(player, p, slash) then
						players:append(p)
					end
				end
			end
			if not players:isEmpty() then
				room:setPlayerMark(player, "shiao_AIA", 1)
				local target = room:askForPlayerChosen(player, players, skill:objectName(), "@shiao-less", true, true)
				room:setPlayerMark(player, "shiao_AIA", 0)
				if target then
					local to = sgs.SPlayerList()
					to:append(target)
					room:notifySkillInvoked(player, "sy_old_shiao")
					room:broadcastSkillInvoke(skill:objectName(), 1)
					local use = sgs.CardUseStruct()
					use.from = player
					use.to = to
					use.card = slash
					room:useCard(use, false)
				end
			end
			slash:deleteLater()
		elseif player:getPhase() == sgs.Player_Finish then
			local players = sgs.SPlayerList()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("sy_old_shiao")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > player:getHandcardNum() then
					if not sgs.Sanguosha:isProhibited(player, p, slash) then
						players:append(p)
					end
				end
			end
			if not players:isEmpty() then
				room:setPlayerMark(player, "shiao_AIB", 1)
				local target = room:askForPlayerChosen(player, players, skill:objectName(), "@shiao-more", true, true)
				room:setPlayerMark(player, "shiao_AIB", 0)
				if target then
					local to = sgs.SPlayerList()
					to:append(target)
					room:notifySkillInvoked(player, "sy_old_shiao")
					room:broadcastSkillInvoke(skill:objectName(), 2)
					local use = sgs.CardUseStruct()
					use.from = player
					use.to = to
					use.card = slash
					room:useCard(use, false)
				end
			end
			slash:deleteLater()
		end
		return false
	end
}


--[[
	技能名：狂袭
	相关武将：魔魏延[旧]
	技能描述：出牌阶段，当你使用非延时类锦囊牌指定其他角色为目标后，你可以终止此牌的结算，改为视为对这些目标依次使用一张【杀】（不计入出牌阶段的使用限制）。
	引用：sy_old_kuangxi
]]--
sy_old_kuangxi = sgs.CreateTriggerSkillV2{
	name = "sy_old_kuangxi",
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		local use = data:toCardUse()
		if use.card:isNDTrick() and (use.to:length() > 1 or (not use.to:contains(player) and use.to:length() == 1)) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("sy_old_kuangxi")
		slash:deleteLater()
		room:broadcastSkillInvoke(skill:objectName(), math.random(1,2))
		room:notifySkillInvoked(player, "sy_old_kuangxi")
		for _,p in sgs.qlist(use.to) do
			if player:canSlash(p, nil, false) and player:objectName() ~= p:objectName() then
				local to = sgs.SPlayerList()
				to:append(p)
				local use2 = sgs.CardUseStruct()
				use2.from = player
				use2.to = to
				use2.card = slash
				use2.m_addHistory = false
				slash:onUse(room, use2)
			end
		end
		return true
	end
}


mo_weiyan_old:addSkill(sy_old_shiao)
mo_weiyan_old:addSkill("sy_fangu")
mo_weiyan_old:addSkill(sy_old_kuangxi)


sgs.LoadTranslationTable{	
	["mo_weiyan_old"] = "魔魏延[旧]",
	["&mo_weiyan_old"] = "魔魏延",
	["#mo_weiyan_old"] = "嗜血狂狼",
	["~mo_weiyan_old"] = "这……就是老子追求的东西吗？",
	["sy_old_shiao"] = "恃傲",
	["@shiao-less"] = "你可以发动“恃傲”视为对一名手牌数小于你的角色使用一张【杀】<br/> <b>操作提示</b>: 选择一名手牌数小于你的角色→点击确定<br/>",
	["@shiao-more"] = "你可以发动“恃傲”视为对一名手牌数大于你的角色使用一张【杀】<br/> <b>操作提示</b>: 选择一名手牌数大于你的角色→点击确定<br/>",
	["shiao-slash"] = "恃傲",
	["$sy_old_shiao1"] = "靠手里的家伙来说话吧。",
	["$sy_old_shiao2"] = "少废话！真有本事就来打！",
	[":sy_old_shiao"] = "准备阶段/结束阶段开始时，你可以视为对手牌数小于/大于你的一名其他角色使用一张【杀】。",
	["shiao_target1"] = "恃傲",
	["shiao_target2"] = "恃傲",
	["sy_old_fangu"] = "反骨",
	["fangu"] = "反骨",
	["$sy_old_fangu"] = "一群胆小之辈，成天坏我大事！",
	[":sy_old_fangu"] = "锁定技，当你受到的伤害结算完毕后，你令当前回合结束，然后你进行一个额外的回合。",
	["sy_old_kuangxi"] = "狂袭",
	["kuangxi-slash"] = "狂袭",
	["$sy_old_kuangxi1"] = "敢挑战老子，你就后悔去吧！",
	["$sy_old_kuangxi2"] = "凭你们是阻止不了老子的！",
	[":sy_old_kuangxi"] = "出牌阶段，当你使用非延时锦囊牌指定目标后，若目标不包含你，你可终止此牌的结算，改为视为对这些目标依次使用一张【杀】（不计入出牌阶段的"..
	"使用次数限制）。",
	["designer:mo_weiyan_old"] = "极略三国",
	["illustrator:mo_weiyan_old"] = "极略三国",
	["cv:mo_weiyan_old"] = "极略三国",
}


--魔孙皓[旧]
mo_sunhao_old = sgs.General(extension, "mo_sunhao_old", "sgk_magic", 4, true, true)


--[[
	技能名：明政
	相关武将：魔孙皓[旧]
	技能描述：锁定技，任一角色摸牌阶段摸牌时，额外摸1张牌。当你受到一次伤害时，失去该技能，并获得技能【嗜杀】。
	引用：sy_old_mingzheng
]]--
sy_old_mingzheng = sgs.CreateTriggerSkillV2{
    name = "sy_old_mingzheng",
	events = {sgs.DrawNCards, sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local sunhao = room:findPlayerBySkillName(skill:objectName())
		if not sunhao then return false end
		if event == sgs.DrawNCards then
			local flag = 1
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("sy_old_mingzheng") > 0 then
					flag = 0
				end
			end
			if flag == 0 then return false end
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then
				return skill:objectName(), sunhao:objectName()
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == sunhao:objectName() then
				return skill:objectName(), sunhao:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			room:broadcastSkillInvoke("sy_old_mingzheng")
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:notifySkillInvoked(player, skill:objectName())
			draw.num = draw.num + 1
			ctx.original_data:setValue(draw)
		elseif event == sgs.Damaged then
			room:addPlayerMark(player, "sy_old_mingzheng", 999)
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:notifySkillInvoked(player, skill:objectName())
			room:broadcastSkillInvoke("sy_old_mingzheng")
			if not player:hasSkill("sy_old_mingzheng") then return false end
			if not player:hasSkill("sy_old_shisha") then room:acquireSkill(player, "sy_old_shisha") end
			if player:hasSkill("sy_old_mingzheng") then room:detachSkillFromPlayer(player, "sy_old_mingzheng") end
		end
		return false
	end
}


--[[
	技能名：荒淫
	相关武将：魔孙皓[旧]
	技能描述：每当你从牌堆获得牌前，可放弃之，改为任意名其他角色处获得共计等量的牌。
	引用：sy_old_huangyin
]]--
sy_old_huangyin = sgs.CreateTriggerSkillV2{
    name = "sy_old_huangyin",
	frequency = sgs.NotFrequent,
	events = {sgs.BeforeCardsMove},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if not move.from_places:contains(sgs.Player_DrawPile) or move.from then return false end
		if move.to_place == sgs.Player_PlaceHand and move.to:objectName() == player:objectName()
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
				or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
			local X = move.card_ids:length()
			if X <= 0 then return false end
			local hascards = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if not pe:isNude() then hascards:append(pe) end
			end
			if hascards:isEmpty() then return false end
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local X = move.card_ids:length()
		room:setPlayerMark(player, "huangyin-AI", X) --AI
		local count = ctx.original_data:toInt()
		count = 0
		room:returnToTopDrawPile(move.card_ids)
		ctx.original_data:setValue(count)
		for i = 1, X do
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("huangyin") < p:getHandcardNum() + p:getEquips():length() then targets:append(p) end
			end
			if targets:isEmpty() then break end
			local t = room:askForPlayerChosen(player, targets, skill:objectName())
			room:addPlayerMark(t, "huangyin", 1)
		end
		room:setPlayerMark(player, "huangyin-AI", 0)
		for _, to in sgs.qlist(room:getOtherPlayers(player)) do
			if to:getMark("huangyin") > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				local y = to:getMark("huangyin")
				for i = 1, y, 1 do
					local id = room:askForCardChosen(player, to, "he", skill:objectName(), false, sgs.Card_MethodNone, dummy:getSubcards(), false)
					if id < 0 then break end
					dummy:addSubcard(id)
				end
				room:setPlayerMark(to, "huangyin", 0)
				if dummy:subcardsLength() > 0 then room:obtainCard(player, dummy, false) end
			end
		end
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end
}


--[[
	技能名：醉酒
	相关武将：魔孙皓[旧]
	技能描述：出牌阶段限一次，你可以展示所有手牌，若黑色牌不少于红色牌，则视为你使用一张【酒】。
	引用：sy_old_zuijiu
]]--
sy_old_zuijiuvs = sgs.CreateViewAsSkillV2{
	name = "sy_old_zuijiu",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return sgs.Analeptic_IsAvailable(player) and (not player:hasFlag("Global_Dying")) and (not player:isKongcheng()) and (not player:hasFlag("cannot_usezuijiu"))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(skill:objectName())
		return analeptic
	end,
}

sy_old_zuijiu = sgs.CreateTriggerSkillV2{
    name = "sy_old_zuijiu",
	events = {sgs.PreCardUsed, sgs.CardUsed, sgs.EventPhaseChanging},
	view_as_skill = sy_old_zuijiuvs,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card and table.contains(card:getSkillNames(), "sy_old_zuijiu") then
				return skill:objectName()
			end
		elseif event == sgs.CardUsed then
			return skill:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasFlag("cannot_usezuijiu") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.PreCardUsed then
			local red_count = 0
			local black_count = 0
			for _, c in sgs.qlist(player:getHandcards()) do
				if c:isRed() then
					red_count = red_count + 1
				elseif c:isBlack() then
					black_count = black_count + 1
				end
			end
			room:showAllCards(player)
			if black_count < red_count then
				room:setPlayerFlag(player, "cannot_usezuijiu")
			else
				room:broadcastSkillInvoke("analeptic")
			end
			player:setMark("zuijiu_red", red_count)
			player:setMark("zuijiu_black", black_count)
		elseif event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			local red_count = player:getMark("zuijiu_red")
			local black_count = player:getMark("zuijiu_black")
			if use.from and use.from:hasFlag("cannot_usezuijiu") then
				room:setPlayerFlag(player, "-cannot_usezuijiu")
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = tostring(red_count)
				msg.arg2 = tostring(black_count)
				msg.type = "#zuijiuFail"
				room:sendLog(msg)
				return true
			end
			player:setMark("zuijiu_red", 0)
			player:setMark("zuijiu_black", 0)
		elseif event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:hasFlag("cannot_usezuijiu") then
					room:setPlayerFlag(player, "-cannot_usezuijiu")
				end
			end
		end
		return false
	end
}


--[[
	技能名：归命
	相关武将：魔孙皓[旧]
	技能描述：限定技，当你进入濒死状态时，你可以令体力值最少的一名其他角色将体力值补至体力上限，然后你回复体力至4点。
	引用：sy_old_guiming
]]--
sy_old_guiming = sgs.CreateTriggerSkillV2{
    name = "sy_old_guiming",
	frequency = sgs.Skill_Limited,
	limit_mark = "@guiming",
	events = {sgs.Dying},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName()) and not player:isDead()) then return false end
		local dying = data:toDying()
		if player:getHp() > 0 then return false end
		if player:getMark("@guiming") == 0 then return false end
		if dying.who:objectName() ~= player:objectName() then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local _min = 9999
		local players = sgs.SPlayerList()
		for _, _player in sgs.qlist(room:getOtherPlayers(player)) do
			if _player:isWounded() then players:append(_player) end
		end
		if not players:isEmpty() then
			for _, p in sgs.qlist(players) do
				_min = math.min(p:getHp(), _min)
			end
			local foes = sgs.SPlayerList()
			for _, _player in sgs.qlist(players) do
				if _player:getHp() == _min and _player:isWounded() then
					foes:append(_player)
				end
			end
			if foes:isEmpty() then
				local guiming_self = sgs.RecoverStruct()
				guiming_self.recover = 4 - player:getHp()
				guiming_self.who = player
				room:recover(player, guiming_self, true)
				player:loseMark("@guiming")
				return false
			else
				local foe
				if foes:length() == 1 then
					foe = foes:first()
				else
					foe = room:askForPlayerChosen(player, foes, skill:objectName())
				end
				if foe:isWounded() then
					local guiming_to = sgs.RecoverStruct()
					guiming_to.recover = foe:getLostHp()
					guiming_to.who = player
					room:recover(foe, guiming_to, true)
				end
				local guiming_self = sgs.RecoverStruct()
				guiming_self.recover = 4 - player:getHp()
				guiming_self.who = player
				room:recover(player, guiming_self, true)
				player:loseMark("@guiming")
				return false
			end
		else
			local guiming_self = sgs.RecoverStruct()
			guiming_self.recover = 4 - player:getHp()
			guiming_self.who = player
			room:recover(player, guiming_self, true)
			player:loseMark("@guiming")
			return false
		end
	end
}



mo_sunhao_old:addSkill(sy_old_mingzheng)
mo_sunhao_old:addRelateSkill("sy_old_shisha")
mo_sunhao_old:addSkill(sy_old_huangyin)
mo_sunhao_old:addSkill(sy_old_zuijiu)
mo_sunhao_old:addSkill(sy_old_guiming)


sgs.LoadTranslationTable{	
	["mo_sunhao_old"] = "魔孙皓[旧]",
	["&mo_sunhao_old"] = "魔孙皓",
	["#mo_sunhao_old"] = "末世暴君",
	["~mo_sunhao_old"] = "乱臣贼子，不得好死！",
	["sy_old_mingzheng"] = "明政",
	[":sy_old_mingzheng"] = "锁定技，任一角色摸牌阶段摸牌时，额外摸1张牌。当你受到一次伤害时，失去该技能，并获得技能【嗜杀】。",
	["$sy_old_mingzheng"] = "开仓放粮，赈济百姓！",
	["shishadiscard"] = "%src的<font color = 'yellow'><b>【嗜杀】</b></font>触发，你须弃置2张牌取消此【杀】对你的结算，否则此【杀】不可被【闪】响应。",
	["sy_old_zuijiu"] = "醉酒",
	["#zuijiuFail"] = "%from的红色手牌数为%arg，大于其黑色手牌数%arg2，“<font color = 'yellow'><b>醉酒</b></font>”发动失败，%from无法视为使用一张【<font color"..
	" = 'yellow'><b>酒</b></font>】。",
	["$sy_old_zuijiu"] = "酒……酒呢！拿酒来！",
	[":sy_old_zuijiu"] = "出牌阶段限一次，你可以展示所有手牌，若黑色牌不少于红色牌，则视为你使用一张【酒】。",
	["sy_old_huangyin"] = "荒淫",
	["@huangyin"] = "荒淫",
	["$sy_old_huangyin"] = "美人儿来来来，让朕瞧瞧！",
	[":sy_old_huangyin"] = "每当你从牌堆获得牌前，你可将本次获得牌的方式改为从任意名其他角色处获得共计等量的牌。",
	["sy_old_guiming"] = "归命",
	["@guiming"] = "归命",
	["$sy_old_guiming"] = "你们！难道忘了朝廷之恩吗！",
	[":sy_old_guiming"] = "限定技，当你进入濒死状态时，你可以令体力值最少的一名其他角色将体力值补至体力上限，然后你回复体力至4点。",
	["designer:mo_sunhao_old"] = "极略三国",
	["illustrator:mo_sunhao_old"] = "极略三国",
	["cv:mo_sunhao_old"] = "极略三国",
}


--魔蔡夫人[旧]
mo_caifuren_old = sgs.General(extension, "mo_caifuren_old", "sgk_magic", 4, false, true)


--[[
	技能名：诋毁
	相关武将：魔蔡夫人[旧]
	技能描述：出牌阶段限一次，你可令场上（除你外）体力值最多（或之一）的一名角色对另一名其他角色造成1点伤害。
	引用：sy_old_dihui
]]--
sy_old_dihuiCard = sgs.CreateSkillCard{
    name = "sy_old_dihuiCard",
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			local players = player:getAliveSiblings()
			local _max = -1000
			for _, t in sgs.qlist(players) do
			    _max = math.max(_max, t:getHp())
			end
			return to_select:getHp() == _max and to_select:objectName() ~= player:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		local players = room:getOtherPlayers(source)
		players:removeOne(target)
		local t = room:askForPlayerChosen(source, players, "sy_old_dihui")
	    if t then
			room:doAnimate(1, target:objectName(), t:objectName())
			room:damage(sgs.DamageStruct("sy_old_dihui", target, t))
		end
	end
}

sy_old_dihui = sgs.CreateViewAsSkillV2{
    name = "sy_old_dihui",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local n = player:getAliveSiblings():length()
		return n >= 2 and (not (player:hasUsed("#sy_old_dihuiCard") or player:hasUsed("sy_old_dihui")))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = sy_old_dihuiCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_dihuiCard")
		end
		return true
	end,
}


--[[
	技能名：乱嗣
	相关武将：魔蔡夫人[旧]
	技能描述：出牌阶段限一次，你可以令两名有手牌的其他角色拼点，你弃置没赢的一方两张牌。
	引用：sy_old_luansi
]]--
sy_old_luansiCard = sgs.CreateSkillCard{
    name = "sy_old_luansiCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
	    if to_select:objectName() == player:objectName() or to_select:isKongcheng() then return false end
		if #targets == 0 then
		    return true
		elseif #targets == 1 then
		    return not to_select:isKongcheng()
		elseif #targets == 2 then
		    return false
		end
	end,
	feasible = function(self, targets, player)
		return #targets == 2 and (not targets[1]:isKongcheng()) and (not targets[2]:isKongcheng()) and targets[1]:objectName() ~= player:objectName() and targets[2]:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local success = targets[1]:pindian(targets[2], "sy_old_luansi", nil)
		if success then
		    if not targets[2]:isNude() then
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			    for i = 1, math.max(1, targets[2]:getCards("he"):length()) do
					if targets[2]:isNude() then break end
					local c = room:askForCardChosen(source, targets[2], "he", "sy_old_luansi", true, sgs.Card_MethodDiscard, jink:getSubcards())
			        jink:addSubcard(c)
				end
				room:throwCard(jink, targets[2], source)
				jink:deleteLater()
			end
		else
		    if not targets[1]:isNude() then
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			    for i = 1, math.max(1, targets[1]:getCards("he"):length()) do
				    if targets[1]:isNude() then break end
					local c = room:askForCardChosen(source, targets[1], "he", "sy_old_luansi", true, sgs.Card_MethodDiscard, jink:getSubcards())
			        jink:addSubcard(c)
				end
				room:throwCard(jink, targets[1], source)
				jink:deleteLater()
			end
		end
	end
}

sy_old_luansi = sgs.CreateViewAsSkillV2{
    name = "sy_old_luansi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sy_old_luansiCard") or player:hasUsed("sy_old_luansi"))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = sy_old_luansiCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_luansiCard")
		end
		return true
	end,
}


--[[
	技能名：祸心
	相关武将：魔蔡夫人[旧]
	技能描述：锁定技，每当你受到一次伤害后，伤害来源须令你获得其装备区中的一张装备牌，否则失去1点体力。
	引用：sy_old_huoxin
]]--
sy_old_huoxin = sgs.CreateTriggerSkillV2{
    name = "sy_old_huoxin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.to:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:notifySkillInvoked(player, "sy_old_huoxin")
		room:doAnimate(1, player:objectName(), damage.from:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if not damage.from:hasEquip() then
			room:loseHp(damage.from, 1, true, player, skill:objectName())
			return false
		else
			local choices = {"obtain_equip", "lose_hp"}
			local choice = room:askForChoice(damage.from, skill:objectName(), table.concat(choices, "+"))
			if choice == "obtain_equip" then
				local equip = room:askForCardChosen(player, damage.from, "e", skill:objectName())
				if equip then room:obtainCard(player, equip) end
			else
				room:loseHp(damage.from, 1, true, player, skill:objectName())
			end
		end
		return false
	end,
	priority = -3
}


mo_caifuren_old:addSkill(sy_old_dihui)
mo_caifuren_old:addSkill(sy_old_luansi)
mo_caifuren_old:addSkill(sy_old_huoxin)


sgs.LoadTranslationTable{	
	["mo_caifuren_old"] = "魔蔡夫人[旧]",
	["&mo_caifuren_old"] = "魔蔡夫人",
	["#mo_caifuren_old"] = "蛇蝎美人",
	["~mo_caifuren_old"] = "做鬼也不会放过你的！",
	["sy_old_dihui"] = "诋毁",
	["$sy_old_dihui1"] = "夫君，此人留不得！",
	["$sy_old_dihui2"] = "养虎为患，须尽早除之！",
	["$sy_old_luansi1"] = "教你见识一下我的手段！",
	["$sy_old_luansi2"] = "求饶？呵呵……晚了！",
	[":sy_old_dihui"] = "出牌阶段限一次，你可令场上（除你外）体力值最多（或之一）的一名角色对另一名其他角色造成1点伤害。",
	["dihuiothers-choose"] = "请选择因“诋毁”受到伤害的另一名其他角色。",
	["sy_old_luansi"] = "乱嗣",
	[":sy_old_luansi"] = "出牌阶段限一次，你可以令两名有手牌的其他角色拼点，你弃置没赢的一方两张牌。<font color = \"red\"><b>（你选择的第一名角色为此拼点的发起人）</b></font>",
	["sy_old_huoxin"] = "祸心",
	["$sy_old_huoxin"] = "别敬酒不吃吃罚酒！",
	[":sy_old_huoxin"] = "锁定技，每当你受到一次伤害后，伤害来源须令你获得其装备区中的一张装备牌，否则失去1点体力。",
	["obtain_equip"] = "该角色获得你一张装备区的牌",
	["lose_hp"] = "失去一点体力",
	["designer:mo_caifuren_old"] = "极略三国",
	["illustrator:mo_caifuren_old"] = "极略三国",
	["cv:mo_caifuren_old"] = "极略三国",
}


--魔司马懿[旧]
mo_simayi_old = sgs.General(extension, "mo_simayi_old", "sgk_magic", 4, true)


--[[
	技能名：博略
	相关武将：魔司马懿[旧]
	技能描述：出牌阶段限一次，你可以判定并获得判定牌，并根据判定结果获得以下技能直到本回合结束：红桃-奇才；方块-权衡；黑桃-强袭；梅花-乱击。
	引用：sy_old_bolue
]]--
sy_old_bolueCard = sgs.CreateSkillCard{
    name = "sy_old_bolueCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local judge = sgs.JudgeStruct()
	    judge.who = source
	    judge.pattern = "."
		judge.reason = "sy_old_bolue"
		judge.play_animation = false
	    room:judge(judge)
	    local card = judge.card
	    local suit = card:getSuit()
		if suit == sgs.Card_Heart then
			room:broadcastSkillInvoke("sy_old_bolue", 1)
			if not source:hasSkill("sr_qicai") then
				room:acquireOneTurnSkills(source, "sy_old_bolue", "sr_qicai")
			end
	    elseif suit == sgs.Card_Diamond then
			room:broadcastSkillInvoke("sy_old_bolue", 2)
	        if not source:hasSkill("sr_quanheng") then
				room:acquireOneTurnSkills(source, "sy_old_bolue", "sr_quanheng")
			end
	    elseif suit == sgs.Card_Spade then
			room:broadcastSkillInvoke("sy_old_bolue", 3)
	        if not source:hasSkill("qiangxi") then
				room:acquireOneTurnSkills(source, "sy_old_bolue", "qiangxi")
			end
	    elseif suit == sgs.Card_Club then
			room:broadcastSkillInvoke("sy_old_bolue", 4)
	        if not source:hasSkill("luanji") then
				room:acquireOneTurnSkills(source, "sy_old_bolue", "luanji")
			end
		end
    end
}

sy_old_bolue = sgs.CreateViewAsSkillV2{
    name = "sy_old_bolue",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not (player:hasUsed("#sy_old_bolueCard") or player:hasUsed("sy_old_bolue"))
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@sy_old_bolue"
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = sy_old_bolueCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#sy_old_bolueCard")
		end
		return true
	end,
}


--[[
	技能名：忍忌
	相关武将：魔司马懿[旧]
	技能描述：每当你受到一次伤害后，你可以判定并获得判定牌，并根据判定结果视为你对来源发动以下技能：红色-反馈；黑桃-刚烈；梅花-放逐。
	引用：sy_old_renji
]]--
sy_old_renji = sgs.CreateTriggerSkillV2{
    name = "sy_old_renji",
	events = {sgs.Damaged},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.from then room:doAnimate(1, player:objectName(), damage.from:objectName()) end
		room:notifySkillInvoked(player, "sy_old_renji")
		room:broadcastSkillInvoke(skill:objectName(), math.random(1, 3))
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = skill:objectName()
		judge.play_animation = false
		room:judge(judge)
		local card = judge.card
		local suit = card:getSuit()
		if not damage.from then return false end
		if suit == sgs.Card_Heart or suit == sgs.Card_Diamond then    --红色-反馈（神算）
			if damage.from and not damage.from:isNude() then
				if not damage.from:isNude() then
					room:notifySkillInvoked(player, "fankui")
					room:doAnimate(1, player:objectName(), damage.from:objectName())
					local card_id = room:askForCardChosen(player, damage.from, "he", "fankui")
					room:obtainCard(player, card_id, false)
				else
					return false
				end
			end
		elseif suit == sgs.Card_Spade then    --黑桃-刚烈（誓仇）
			room:notifySkillInvoked(player, "nosganglie")
			if (not damage.from) or damage.from:isDead() then return false end
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			local gangliejudge = sgs.JudgeStruct()
			gangliejudge.pattern = ".|heart"
			gangliejudge.good = false
			gangliejudge.reason = "nosganglie"
			gangliejudge.who = player
			room:judge(gangliejudge)
			if gangliejudge:isGood() then
				if damage.from:getHandcardNum() < 2 or not room:askForDiscard(damage.from, "nosganglie", 2, 2, true) then
					room:damage(sgs.DamageStruct("nosganglie", player, damage.from))
				end
			end
		elseif suit == sgs.Card_Club then    --梅花-放逐
			room:notifySkillInvoked(player, "fangzhu")
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			damage.from:drawCards(player:getLostHp())
			damage.from:turnOver()
		end
		return false
	end,
	priority = -2
}


--[[
	技能名：天佑
	相关武将：魔司马懿[旧]
	技能描述：回合结束阶段开始时，你可以将摸牌堆顶的牌置于你的武将牌上，称为“佑”。直到你的下个回合开始时，将之置入弃牌堆。若你的武将牌上有牌，你不能成为其他
	角色使用的与之颜色相同的牌的目标。
	引用：sy_old_tianyou
]]--
sy_old_tianyou = sgs.CreateTriggerSkillV2{
    name = "sy_old_tianyou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Finish and player:getPile("you"):isEmpty() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:notifySkillInvoked(player, "sy_old_tianyou")
		room:broadcastSkillInvoke(skill:objectName())
		local ids = room:getNCards(1, true)
		local id = ids:first()
		local card = sgs.Sanguosha:getCard(id)
		player:addToPile("you", card)
		local tianyou_msg = sgs.LogMessage()
		tianyou_msg.from = player
		if card:isRed() then
			tianyou_msg.type = "#tianyoured"
		else
			tianyou_msg.type = "#tianyoublack"
		end
		tianyou_msg.arg = skill:objectName()
		room:sendLog(tianyou_msg)
		return false
	end,
	priority = 1
}


mo_simayi_old:addSkill(sy_old_bolue)
mo_simayi_old:addSkill(sy_old_renji)
mo_simayi_old:addSkill("sy_biantian")
mo_simayi_old:addSkill(sy_old_tianyou)


sgs.LoadTranslationTable{		
	["mo_simayi_old"] = "魔司马懿[旧]",
	["&mo_simayi_old"] = "魔司马懿",
	["~mo_simayi_old"] = "呃哦……呃啊……",
	["#mo_simayi_old"] = "三分归晋",
	["sy_old_bolue"] = "博略",
	["$sy_old_bolue1"] = "老夫，想到一些有趣之事。",
	["$sy_old_bolue2"] = "无用之物，老夫毫无兴趣。",
	["$sy_old_bolue3"] = "杀人伎俩，偶尔一用无妨。",
	["$sy_old_bolue4"] = "此种事态，老夫早有准备。",
	[":sy_old_bolue"] = "出牌阶段限一次，你可以判定并获得生效后的判定牌，并根据结果于此回合内获得对应技能：红桃-奇才；方块-权衡；黑桃-强袭；梅花-乱击。",
	["sy_old_renji"] = "忍忌",
	["$sy_old_renji1"] = "老夫也不得不认真起来了。",
	["$sy_old_renji2"] = "你们，是要置老夫于死地吗？",
	["$sy_old_renji3"] = "休要聒噪，吵得老夫头疼！",
	[":sy_old_renji"] = "当你受到伤害后，你可以判定并获得生效后的判定牌，并根据判定结果视为你对来源发动对应技能：红色-反馈；黑桃-刚烈；梅花-放逐。",
	["sy_old_tianyou"] = "天佑",
	["$sy_old_tianyou"] = "好好看着吧！",
	["you"] = "佑",
	["#tianyoured"] = "%from 的下个回合开始之前，%from 不能成为其他角色使用的 <font color=\"yellow\"><b>红色牌</b></font> 的目标。",
	["#tianyoublack"] = "%from 的下个回合开始之前，%from 不能成为其他角色使用的 <font color=\"yellow\"><b>黑色牌</b></font> 的目标。",
	[":sy_old_tianyou"] = "回合结束阶段，你可以将摸牌堆顶的牌置于你的武将牌上，称为“佑”。准备阶段，你将“佑”置入弃牌堆。若你有“佑”，你不能成为其他角色使用的与"..
	"“佑”颜色相同的牌的目标。",
	["designer:mo_simayi_old"] = "极略三国",
	["illustrator:mo_simayi_old"] = "极略三国",
	["cv:mo_simayi_old"] = "极略三国",
}
return {extension}
