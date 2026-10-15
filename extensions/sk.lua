-- 50P keeps this live scan in native code: same getAllPlayers() roster and exact flag.
-- No flag result is cached. Other modes retain the Lua scan.
local perf50_native_flag_scan = sgs.GetConfig("50PNativeFlagScan", true)
if os and os.getenv and os.getenv("QSAN_50P_NATIVE_FLAG_SCAN") == "0" then
    perf50_native_flag_scan = false
end
local function perf50RoomHasFlag(room, flag)
    if perf50_native_flag_scan and room:getMode() == "50p" and room.findPlayerWithFlag then
        return room:findPlayerWithFlag(flag) ~= nil
    end
    for _, p in sgs.qlist(room:getAllPlayers()) do
        if p:hasFlag(flag) then return true end
    end
    return false
end
-- End 50P flag scan helper.

--module("extensions.sk", package.seeall)
extension = sgs.Package("sk")

sgs.LoadTranslationTable{
	["sk"] = "极略三国SK包",
}

sk_chaohuangSlash = sgs.CreateTriggerSkillV2{
    name = "sk_chaohuangSlash",
	events = {},
}

caijie_slash = sgs.CreateTriggerSkillV2{
	name = "caijie_slash",
	events = {},
	frequency = sgs.Skill_Compulsory,
}

--V2 全局技能以隱藏技能名掛到所有武將；
--晚於本擴展加載的武將或換將後於結算時補掛 acquired 實例。
local sk_global_skill_names = {"#clear_cardbuff", "#card_damagebuff"}
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local sk_ensuring_globals = false
local function sk_ensure_global_instances(room)
	if sk_ensuring_globals then return end
	if room:getTag("sk_globals_ensured"):toBool() then return end
	sk_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		sk_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("sk_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(sk_global_skill_names) do
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
		room:setTag("sk_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("sk_globals_ensured", sgs.QVariant(true))
	sk_ensuring_globals = false
end

clear_cardbuff = sgs.CreateTriggerSkillV2{
	name = "#clear_cardbuff",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.CardFinished},
	on_record = function(skill, event, room, player, ctx)
		sk_ensure_global_instances(room)
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			local flags = {"llq_jiwu_residue", "llq_jiwu_ex", "llq_jiwu_damage"}
			if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_USE then
				for _, id in sgs.qlist(move.card_ids) do
					for _, flag in ipairs(flags) do
						if sgs.Sanguosha:getCard(id):hasFlag(flag) then room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..flag) end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			local flags = {"llq_jiwu_residue", "llq_jiwu_ex", "llq_jiwu_damage"}
			if use.card then
				for _, flag in ipairs(flags) do
					if use.card:hasFlag(flag) then room:setCardFlag(use.card, "-"..flag) end
				end
			end
		end
	end
}

card_damagebuff = sgs.CreateTriggerSkillV2{
	name = "#card_damagebuff",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("llq_jiwu_damage") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("llq_jiwu_damage") then
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
		end
		return false
	end
}

card_tarmod = sgs.CreateTargetModSkillV2{
	name = "card_tarmod",
	pattern = "Slash",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_System,
	gate = { "card_flag:llq_jiwu_ex", "card_flag:llq_jiwu_residue" },
	correct_func = function(skill, ctx)
		local card = ctx:getCard()
		if not card then return false end
		local mod = ctx:getModType()
		if mod == sgs.TargetModSkill_DistanceLimit then
			if card:hasFlag("llq_jiwu_ex") then return 9999 end
		elseif mod == sgs.TargetModSkill_Residue then
			if card:hasFlag("llq_jiwu_residue") then return 1 end
		elseif mod == sgs.TargetModSkill_ExtraTarget then
			if card:hasFlag("llq_jiwu_ex") then return 1 end
		end
		return false
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sk_chaohuangSlash") then skills:append(sk_chaohuangSlash) end
if not sgs.Sanguosha:getSkill("caijie_slash") then skills:append(caijie_slash) end
if not sgs.Sanguosha:getSkill("#clear_cardbuff") then skills:append(clear_cardbuff) end
if not sgs.Sanguosha:getSkill("#card_damagebuff") then skills:append(card_damagebuff) end
if not sgs.Sanguosha:getSkill("card_tarmod") then skills:append(card_tarmod) end
sgs.Sanguosha:addSkills(skills)
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	for _, skill_name in ipairs(sk_global_skill_names) do
		gen:addSkill(skill_name)
	end
end

--张宁
sk_zhangning = sgs.General(extension, "sk_zhangning", "qun", 3, false)


--雷祭：当其他角色使用【闪】时，你可将牌堆或弃牌堆里的一张【闪电】置入一名角色的判定区。
sk_leiji = sgs.CreateTriggerSkillV2{
    name = "sk_leiji",
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		local card = use.card
		local source = use.from
		if not (source and card and card:isKindOf("Jink")) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, zhangning in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if source:objectName() ~= zhangning:objectName() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, zhangning:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local lightning_id = -1
		for _, c in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(c):isKindOf("Lightning") then
				lightning_id = c
				break
			end
		end
		if lightning_id == -1 then
			for _, c in sgs.qlist(room:getDiscardPile()) do
				if sgs.Sanguosha:getCard(c):isKindOf("Lightning") then
					lightning_id = c
					break
				end
			end
		end
		if lightning_id == -1 then return false end
		local lightning = sgs.Sanguosha:getCard(lightning_id)
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isProhibited(p, lightning) and (not p:containsTrick("lightning")) then players:append(p) end
		end
		lightning:setSkillName(skill:objectName())
		if players:isEmpty() then return false end
		if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then return false end
		local t = room:askForPlayerChosen(player, players, skill:objectName(), nil, false, true)
		ctx.extra_data:setValue(lightning_id)
		ctx.targets:append(t)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		local lightning_id = ctx.extra_data:toInt()
		local lightning = sgs.Sanguosha:getCard(lightning_id)
		room:broadcastSkillInvoke(skill:objectName())
		local move = sgs.CardsMoveStruct()
		move.card_ids:append(lightning_id)
		move.to = target
		move.to_place = sgs.Player_PlaceDelayedTrick
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill:objectName(), nil)
		room:moveCardsAtomic(move, true)
		local movemsg = sgs.LogMessage()
		movemsg.from = player
		movemsg.type = "#PutLightning"
		movemsg.to:append(target)
		movemsg.card_str = lightning:toString()
		room:sendLog(movemsg)
		return false
	end,
}


sk_zhangning:addSkill(sk_leiji)


--闪戏：锁定技，你不能成为【闪电】的目标，【闪电】的判定牌生效后，你获得之。
sk_shanxi = sgs.CreateProhibitSkillV2{
    name = "sk_shanxi",
	holder_selector = sgs.CorrectSkill_Secondary,
	is_prohibited = function(self, ctx)
	    local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
	    return to:hasSkill("sk_shanxi") and card:isKindOf("Lightning")
	end
}


sk_shanxiget = sgs.CreateTriggerSkillV2{
    name = "#sk_shanxi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local judge = data:toJudge()
		if not judge.card or judge.reason ~= "lightning" then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, zhangning in sgs.qlist(room:findPlayersBySkillName("sk_shanxi")) do
			table.insert(trigger_list_skill, skill:objectName())
			table.insert(trigger_list_who, zhangning:objectName())
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local judge = ctx.original_data:toJudge()
		local card = judge.card
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and judge.reason == "lightning" then
			room:sendCompulsoryTriggerLog(player, "sk_shanxi")
			room:notifySkillInvoked(player, "sk_shanxi")
			room:broadcastSkillInvoke("sk_shanxi", math.random(1, 2))
			player:obtainCard(card)
		end
		return false
	end,
}


extension:insertRelatedSkills("sk_shanxi", "#sk_shanxi")
sk_zhangning:addSkill(sk_shanxi)
sk_zhangning:addSkill(sk_shanxiget)


sgs.LoadTranslationTable{
    ["sk_zhangning"] = "SK张宁",
	["&sk_zhangning"] = "张宁",
	["#sk_zhangning"] = "诡电魅娘",
	["~sk_zhangning"] = "苍天劫数将至，或已无处可逃。",
	["sk_leiji"] = "雷祭",
	["$sk_leiji1"] = "接下来，我们要电谁呢？",
	["$sk_leiji2"] = "雷火轰鸣，请不要乱逃哦。",
	[":sk_leiji"] = "当其他角色使用【闪】时，你可将牌堆或弃牌堆里的一张【闪电】置入一名角色的判定区。",
	["#PutLightning"] = "%from 把 %card 放进了 %to 的判定区",
	["sk_shanxi"] = "闪戏",
	["$sk_shanxi1"] = "天雷可是会勾动地火的哟。",
	["$sk_shanxi2"] = "小伙子，你可不要玩火哦。",
	[":sk_shanxi"] = "<font color = \"blue\"><b>锁定技，</b></font>你不能成为【闪电】的目标，【闪电】的判定牌生效后，你获得之。",
}


--司马师
sk_simashi = sgs.General(extension, "sk_simashi", "wei", 4, true)


--权略：出牌阶段开始时，你可以展示所有手牌并选择其中一种花色的手牌，然后摸与之等量的牌。若如此做，此阶段结束时，你须展示手牌并弃置所有此花色的手牌。
sk_quanlue = sgs.CreateTriggerSkillV2{
    name = "sk_quanlue",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		if event == sgs.EventPhaseStart then
			if player:getHandcardNum() > 0 then return skill:objectName() end
		elseif event == sgs.EventPhaseEnd then
			if player:hasFlag("quanlue_done") then return skill:objectName() end
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
		if event == sgs.EventPhaseStart then
			local mycards = sgs.IntList()
			for _, c in sgs.qlist(player:getHandcards()) do
			    mycards:append(c:getEffectiveId())
			end
			room:fillAG(mycards)
		    local id = room:askForAG(player, mycards, false, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
		    local card = sgs.Sanguosha:getCard(id)
		    local pattern = card:getSuitString()
			room:setTag("quanlue_pattern", sgs.QVariant(pattern))
		    local n = 0
		    for _, c in sgs.qlist(player:getHandcards()) do
		        if c:getSuitString() == pattern then n = n + 1 end
		    end
		    player:drawCards(n)
		    room:clearAG()
			room:setPlayerFlag(player, "quanlue_done")
			room:addPlayerMark(player, "&sk_quanlue+:+"..pattern.."_char-Clear")
		elseif event == sgs.EventPhaseEnd then
		    room:setPlayerFlag(player, "-quanlue_done")
			local quanlue_suit = room:getTag("quanlue_pattern"):toString()
			local mycards = sgs.IntList()
			for _, c in sgs.qlist(player:getHandcards()) do
			    mycards:append(c:getEffectiveId())
			end
			if not player:isKongcheng() then
			    room:fillAG(mycards)
			    room:getThread():delay(500)
			    room:clearAG()
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, g in sgs.qlist(player:getHandcards()) do
			    if g:getSuitString() == quanlue_suit then dummy:addSubcard(g) end
			end
			if dummy:subcardsLength() > 0 then
			    room:throwCard(dummy, player)
			end
			room:removeTag("quanlue_pattern")
			dummy:deleteLater()
		end
		return false
	end,
}


sk_simashi:addSkill(sk_quanlue)


sgs.LoadTranslationTable{
    ["sk_simashi"] = "SK司马师",
    ["&sk_simashi"] = "司马师",
	["#sk_simashi"] = "晋之基石",
	["~sk_simashi"] = "我竟……丧此……区区小疾……",
	["sk_quanlue"] = "权略",
	["$sk_quanlue1"] = "你？是在跟我提权术吗？",
	["$sk_quanlue2"] = "权谋定天下，极略终三国。",
	[":sk_quanlue"] = "出牌阶段开始时，你可以展示所有手牌并选择其中一种花色的手牌，然后摸与之等量的牌。若如此做，此阶段结束时，你须展示手牌并弃置所有此花色的手"..
	"牌。",
}


--张任
sk_zhangren = sgs.General(extension, "sk_zhangren", "qun", 4, true)


--伏射
sk_fushe = sgs.CreateTriggerSkillV2{
    name = "sk_fushe",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, zhangren in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if player:objectName() ~= zhangren:objectName() then
				local ok = false
				if event == sgs.EventPhaseStart then
					ok = player:getPhase() == sgs.Player_Play and zhangren:inMyAttackRange(player)
				elseif event == sgs.CardsMoveOneTime then
					ok = player:getPhase() == sgs.Player_Play and player:hasFlag("fushe_target")
				elseif event == sgs.EventPhaseEnd then
					ok = player:hasFlag("fushe_target") and player:getPhase() == sgs.Player_Play
				end
				if ok then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, zhangren:objectName())
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			return player:askForSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then return false end
		if event == sgs.EventPhaseStart then
			if target:getPhase() == sgs.Player_Play and target:objectName() ~= player:objectName() and player:inMyAttackRange(target) then
				local suits = {"spade", "heart", "club", "diamond"}
				local suit = room:askForChoice(player, skill:objectName(), table.concat(suits, "+"))
				player:setTag("fushe_suit", sgs.QVariant(suit))
				local fushe_msg = sgs.LogMessage()
				fushe_msg.from = player
				fushe_msg.type = "#fushe"
				fushe_msg.arg = skill:objectName()
				fushe_msg.arg2 = suit
				room:sendLog(fushe_msg)
				room:setPlayerFlag(target, "fushe_target")
				room:addPlayerMark(target, "&sk_fushe+to+:+".. suit .."_char" .."+#"..player:objectName().."-PlayClear")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if target:getPhase() == sgs.Player_Play and target:objectName() ~= player:objectName() and target:hasFlag("fushe_target") then
				if move.from and move.from:isAlive() and move.from:objectName() == target:objectName() and move.to_place == sgs.Player_DiscardPile then
					local suit = player:getTag("fushe_suit"):toString()
					for _, c in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(c):getSuitString() == suit then
							room:setPlayerFlag(player, "fushe_damage")
							break
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if target:hasFlag("fushe_target") and target:getPhase() == sgs.Player_Play then
				room:setPlayerFlag(target, "-fushe_target")
				if player:hasFlag("fushe_damage") then
					room:removeTag("fushe_suit")
					room:doAnimate(1, player:objectName(), target:objectName())
					room:setPlayerFlag(player, "-fushe_damage")
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:damage(sgs.DamageStruct(skill:objectName(), player, target))
					player:drawCards(1)
				end
				room:removeTag("fushe_suit")
			end
		end
		return false
	end,
}


sk_zhangren:addSkill(sk_fushe)


sgs.LoadTranslationTable{
    ["sk_zhangren"] = "SK张任",
    ["&sk_zhangren"] = "张任",
	["#sk_zhangren"] = "索命神射",
	["~sk_zhangren"] = "忠臣……不事……二主……",
	["sk_fushe"] = "伏射",
	[":sk_fushe"] = "其他角色的出牌阶段开始时，若其在你的攻击范围内，你可以选择一种花色；然后此阶段结束时，若其有该花色的牌于此阶段进入弃牌堆，你对其造成"..
	"1点伤害并摸一张牌。",
	["$sk_fushe1"] = "射掉那个骑白马的，重重有赏。",
	["$sk_fushe2"] = "这一箭，就是要你死！",
	["#fushe"] = "%from 发动 %arg 选择了 %arg2",
}


--糜竺
sk_mizhu = sgs.General(extension, "sk_mizhu", "shu", 3, true)


--资国
sk_ziguoCard = sgs.CreateSkillCard{
    name = "sk_ziguoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
        if #targets == 0 then
		    return to_select:isWounded()
		end
		return false
	end,
	feasible = function(self, targets, player)
	    return #targets == 1 and targets[1]:isWounded()
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		targets[1]:drawCards(2)
		room:setPlayerFlag(source, "ziguo_done")
	end
}

sk_ziguoVS = sgs.CreateViewAsSkillV2{
    name = "sk_ziguo",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_ziguoCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_ziguoCard:clone()
	end,
}

sk_ziguo = sgs.CreateTriggerSkillV2{
    name = "sk_ziguo",
	view_as_skill = sk_ziguoVS,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish
			and player:hasFlag("ziguo_done") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Finish then
		    if player:hasFlag("ziguo_done") then
			    room:setPlayerFlag(player, "-ziguo_done")
			end
		end
		return false
	end,
}

sk_ziguoMaxCards = sgs.CreateMaxCardsSkillV2{
    name = "#sk_ziguo",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
	    if target and target:hasFlag("ziguo_done") then
		    return -2
		end
		return false
	end
}


extension:insertRelatedSkills("sk_ziguo", "#sk_ziguo")


--商道
sk_shangdao = sgs.CreateTriggerSkillV2{
    name = "sk_shangdao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, mizhu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if player:objectName() ~= mizhu:objectName() and player:getHandcardNum() > mizhu:getHandcardNum() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, mizhu:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:getPhase() == sgs.Player_Start and target:objectName() ~= player:objectName()
			and target:getHandcardNum() > player:getHandcardNum()) then return false end
	    if room:getDrawPile():isEmpty() then room:swapPile() end
	    room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local ids = sgs.IntList()
		local drawpile = sgs.QList2Table(room:getDrawPile())
		local id = drawpile[1]
		ids:append(id)
		room:fillAG(ids)
		room:getThread():delay(750)
		room:clearAG()
		room:obtainCard(player, id, true)
		return false
	end,
}


sk_mizhu:addSkill(sk_ziguo)
sk_mizhu:addSkill(sk_ziguoMaxCards)
sk_mizhu:addSkill(sk_shangdao)


sgs.LoadTranslationTable{
    ["sk_mizhu"] = "SK糜竺",
    ["&sk_mizhu"] = "糜竺",
	["#sk_mizhu"] = "富甲一方",
	["~sk_mizhu"] = "我有何面目去见关将军？",
	["sk_ziguo"] = "资国",
	["$sk_ziguo1"] = "国将不国，何以为家？",
	["$sk_ziguo2"] = "举家之财力，资国之大计。",
	[":sk_ziguo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名已受伤的角色摸两张牌，若如此做，本回合你的手牌上限-2。",
	["sk_shangdao"] = "商道",
	["$sk_shangdao1"] = "别介意，在商言商。",
	["$sk_shangdao2"] = "走过路过，不要错过！",
	[":sk_shangdao"] = "<font color=\"blue\"><b>锁定技。</b></font>一名角色的准备阶段开始时，若其手牌数大于你，你展示牌堆顶的牌并获得之。",
}


--张鲁
sk_zhanglu = sgs.General(extension, "sk_zhanglu", "qun", 3, true)


--米道
sk_midaoCard = sgs.CreateSkillCard{
    name = "sk_midaoCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    local midao_targets = sgs.SPlayerList()
		for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    if t:getHandcardNum() > source:getHandcardNum() then midao_targets:append(t) end
		end
		if not midao_targets:isEmpty() then
		    for _, p in sgs.qlist(midao_targets) do
			    local card = room:askForCardChosen(p, p, "he", "sk_midao")
				room:obtainCard(source, card, false)
			end
		end
		local _max = -1000
		for _, m in sgs.qlist(room:getOtherPlayers(source)) do
		    _max = math.max(m:getHandcardNum(), _max)
		end
		if source:getHandcardNum() <= _max then return false end
		room:loseHp(source, 1, true, source, "sk_midao")
	end
}

sk_midao = sgs.CreateViewAsSkillV2{
    name = "sk_midao",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    local s = 0
	    for _, t in sgs.qlist(player:getAliveSiblings()) do
		    if t:getHandcardNum() > player:getHandcardNum() then s = s + 1 end
		end
		return s > 0 and not (player:hasUsed("#sk_midaoCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_midaoCard:clone()
	end,
}


--义舍
sk_yisheCard = sgs.CreateSkillCard{
    name = "sk_yisheCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
        if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and to_select:getHandcardNum() <= player:getHandcardNum()
		end
		return false
	end,
	feasible = function(self, targets, player)
	    return #targets == 1 and targets[1]:getHandcardNum() <= player:getHandcardNum()
	end,
	on_use = function(self, room, source, targets)
	    local exchangeMove = sgs.CardsMoveList()
	    local move1 = sgs.CardsMoveStruct(source:handCards(), targets[1], sgs.Player_PlaceHand, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), targets[1]:objectName(), "sk_yishe", ""))
	    local move2 = sgs.CardsMoveStruct(targets[1]:handCards(), source, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), targets[1]:objectName(), "sk_yishe", ""))
	    exchangeMove:append(move2)
	    exchangeMove:append(move1)
	    room:moveCardsAtomic(exchangeMove, false)
	end
}

sk_yishe = sgs.CreateViewAsSkillV2{
    name = "sk_yishe",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_yisheCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_yisheCard:clone()
	end,
}


--普渡
sk_puduCard = sgs.CreateSkillCard{
    name = "sk_puduCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    local pudu_move = sgs.CardsMoveList()
		for _, _player in sgs.qlist(room:getOtherPlayers(source)) do
		    if not _player:isKongcheng() then
			    local movex = sgs.CardsMoveStruct(_player:handCards(), source, sgs.Player_PlaceHand, 
		            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, _player:objectName(), source:objectName(), "sk_pudu", ""))
				pudu_move:append(movex)
			end
		end
		room:moveCardsAtomic(pudu_move, false)
		while true do
		    local pudu_end = 0
			for _, t in sgs.qlist(room:getOtherPlayers(source)) do
				room:setPlayerFlag(t, "sk_pudu_target")
			    local card = room:askForCardChosen(source, source, "he", "sk_pudu")
				room:setPlayerFlag(t, "-sk_pudu_target")
				room:obtainCard(t, card, false)
				local _max = -9999
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				    _max = math.max(p:getHandcardNum(), _max)
				end
				if source:getHandcardNum() <= _max then
				    pudu_end = 1
					break
				end
			end
			if pudu_end == 1 then break end
		end
		source:loseMark("@pudu")
	end
}

sk_puduVS = sgs.CreateViewAsSkillV2{
    name = "sk_pudu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return player:getMark("@pudu") > 0 and not (player:hasUsed("#sk_puduCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_puduCard:clone()
	end,
}

sk_pudu = sgs.CreateTriggerSkillV2{
    name = "sk_pudu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@pudu",
	view_as_skill = sk_puduVS,
	events = {},
}


sk_zhanglu:addSkill(sk_midao)
sk_zhanglu:addSkill(sk_yishe)
sk_zhanglu:addSkill(sk_pudu)


sgs.LoadTranslationTable{
    ["sk_zhanglu"] = "SK张鲁",
    ["&sk_zhanglu"] = "张鲁",
	["#sk_zhanglu"] = "五斗天官",
	["~sk_zhanglu"] = "天之粟物，属之奇孤……",
	["sk_midao"] = "米道",
	["$sk_midao1"] = "知人者智，自知者明。",
	["$sk_midao2"] = "自修其身，以真先寿。",
	[":sk_midao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令手牌数大于你的其他角色依次交给你一张牌，然后若你的手牌数为全场最多，你失去1点体力。",
	["sk_yishe"] = "义舍",
	["$sk_yishe1"] = "上善若水，利万物而不争。",
	["$sk_yishe2"] = "圣人恒无心，以百姓心为心。",
	[":sk_yishe"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名手牌数不大于你的其他角色交换手牌。",
	["sk_pudu"] = "普渡",
	["@pudu"] = "普渡",
	["$sk_pudu"] = "天地不仁，以万物为刍狗。",
	[":sk_pudu"] = "<font color=\"red\"><b>限定技。</b></font>出牌阶段，你可以获得所有其他角色的手牌，然后依次交给其他角色一张牌，直到你的手牌数不为全场最多。",
}


--董卓
sk_dongzhuo = sgs.General(extension, "sk_dongzhuo", "qun", 6, true)


--暴征
sk_baozheng = sgs.CreateTriggerSkillV2{
    name = "sk_baozheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Finish then
		    room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			room:notifySkillInvoked(player, skill:objectName())
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			    if player:isDead() then break end
				if not p:isNude() then
					room:doAnimate(1, player:objectName(), p:objectName())
				    if p:getCards("he"):length() == 1 then
					    local card = p:getCards("he"):at(0)
						room:obtainCard(player, card, false)
					else
					    local choice = room:askForChoice(p, skill:objectName(), "giveonecard+discardtwocards")
						if choice == "giveonecard" then
						    local c = room:askForCardChosen(p, p, "he", skill:objectName())
							room:obtainCard(player, c, false)
						else
						    room:askForDiscard(p, skill:objectName(), 2, 2, false, true)
							room:damage(sgs.DamageStruct(skill:objectName(), p, player))
						end
					end
				end
			end
		end
		return false
	end,
}


--凌怒
sk_lingnu = sgs.CreateTriggerSkillV2{
    name = "sk_lingnu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseEnd, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then return skill:objectName() end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName()
				and player:getPhase() ~= sgs.Player_NotActive then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and player:getMark("lingnu_damage") >= 2 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Start then
			    player:setMark("lingnu_damage", 0)
			end
		elseif event == sgs.Damaged then
		    local damage = ctx.original_data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
			    if player:getPhase() == sgs.Player_NotActive then return false end
				local lingnu_count = player:getMark("lingnu_damage")
				room:setPlayerMark(player, "lingnu_damage", lingnu_count + damage.damage)
			end
		elseif event == sgs.EventPhaseEnd then
		    if player:getPhase() == sgs.Player_Finish then
			    local lingnu_count = player:getMark("lingnu_damage")
				if lingnu_count >= 2 then
				    player:setMark("lingnu_damage", 0)
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:notifySkillInvoked(player, skill:objectName())
					room:loseMaxHp(player)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					    if player:isDead() then break end
					    if not p:isNude() then
							room:doAnimate(1, player:objectName(), p:objectName())
						    local card = room:askForCardChosen(player, p, "he", skill:objectName())
							room:obtainCard(player, card, false)
						end
					end
				end
			end
		end
		return false
	end,
}


sk_dongzhuo:addSkill(sk_baozheng)
sk_dongzhuo:addSkill(sk_lingnu)


sgs.LoadTranslationTable{
    ["sk_dongzhuo"] = "SK董卓",
    ["&sk_dongzhuo"] = "董卓",
	["#sk_dongzhuo"] = "阎魔王",
	["~sk_dongzhuo"] = "吾儿，奉先，何在……",
	["sk_baozheng"] = "暴征",
	["$sk_baozheng1"] = "此刻，正是尔等为我尽忠之时！",
	["$sk_baozheng2"] = "嗯？谁敢不听话？",
	[":sk_baozheng"] = "<font color=\"blue\"><b>锁定技。</b></font>回合结束阶段开始时，你令其他角色依次选择一项：交给你一张牌；或弃置两张牌，然后对你造成1点伤害。",
	["giveonecard"] = "交给该角色一张牌",
	["discardtwocards"] = "弃置两张牌，对其造成1点伤害",
	["sk_lingnu"] = "凌怒",
	["$sk_lingnu1"] = "凡册上有名者，都应处死！",
	["$sk_lingnu2"] = "不听话的，都等着下油锅吧！",
	[":sk_lingnu"] = "<font color=\"blue\"><b>锁定技。</b></font>回合结束时，若你于此回合受到2点或更多的伤害，你减1点体力上限，然后从其他角色处依次获得一张牌。",
}


--司马昭
sk_simazhao = sgs.General(extension, "sk_simazhao", "wei", 3, true)


--昭心
sk_zhaoxin = sgs.CreateTriggerSkillV2{
    name = "sk_zhaoxin",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not damage.to or damage.to:objectName() ~= player:objectName() then return false end
		local suits = {"spade", "heart", "club", "diamond"}
		for _, c in sgs.qlist(player:getHandcards()) do
		    if table.contains(suits, c:getSuitString()) then
			    table.removeOne(suits, c:getSuitString())
			end
		end
		if #suits == 0 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.to or damage.to:objectName() ~= player:objectName() then return false end
		local suits = {"spade", "heart", "club", "diamond"}
		for _, c in sgs.qlist(player:getHandcards()) do
		    if table.contains(suits, c:getSuitString()) then
			    table.removeOne(suits, c:getSuitString())
			end
		end
		if #suits == 0 then return false end
	    if player:isKongcheng() then
		    player:drawCards(#suits)
		else
		    room:showAllCards(player)
			player:drawCards(#suits)
		end
		room:broadcastSkillInvoke(skill:objectName())
		return false
	end,
}


--制合
sk_zhiheCard = sgs.CreateSkillCard{
    name = "sk_zhiheCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local spade_hand, heart_hand, club_hand, diamond_hand = sgs.IntList(), sgs.IntList(), sgs.IntList(), sgs.IntList()
		for _, c in sgs.qlist(source:getHandcards()) do
		    if c:getSuitString() == "spade" then
			    spade_hand:append(c:getEffectiveId())
			elseif c:getSuitString() == "heart" then
			    heart_hand:append(c:getEffectiveId())
			elseif c:getSuitString() == "club" then
			    club_hand:append(c:getEffectiveId())
			elseif c:getSuitString() == "diamond" then
			    diamond_hand:append(c:getEffectiveId())
			end
		end
		room:showAllCards(source)
		local zhihe_throw = sgs.IntList()
		if spade_hand:length() > 1 then
		    room:fillAG(spade_hand, source)
			local spade_id = room:askForAG(source, spade_hand, false, "sk_zhihe")
			room:clearAG()
			spade_hand:removeOne(spade_id)
			for _, card in sgs.qlist(spade_hand) do
			    zhihe_throw:append(card)
			end
		end
		if heart_hand:length() > 1 then
		    room:fillAG(heart_hand, source)
			local heart_id = room:askForAG(source, heart_hand, false, "sk_zhihe")
			room:clearAG()
			heart_hand:removeOne(heart_id)
			for _, card in sgs.qlist(heart_hand) do
			    zhihe_throw:append(card)
			end
		end
		if club_hand:length() > 1 then
		    room:fillAG(club_hand, source)
			local club_id = room:askForAG(source, club_hand, false, "sk_zhihe")
			room:clearAG()
			club_hand:removeOne(club_id)
			for _, card in sgs.qlist(club_hand) do
			    zhihe_throw:append(card)
			end
		end
		if diamond_hand:length() > 1 then
		    room:fillAG(diamond_hand, source)
			local diamond_id = room:askForAG(source, diamond_hand, false, "sk_zhihe")
			room:clearAG()
			diamond_hand:removeOne(diamond_id)
			for _, card in sgs.qlist(diamond_hand) do
			    zhihe_throw:append(card)
			end
		end
		if not zhihe_throw:isEmpty() then
		    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		    dummy:addSubcards(getCardList(zhihe_throw))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sk_zhihe","")
			room:throwCard(dummy, reason, nil)
			dummy:deleteLater()
		end
		source:drawCards(source:getHandcardNum())
	end
}

sk_zhihe = sgs.CreateViewAsSkillV2{
    name = "sk_zhihe",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_zhiheCard") or player:hasUsed(skill:objectName())) and (not player:isKongcheng())
	end,
	create_card = function(skill, request)
	    return sk_zhiheCard:clone()
	end,
}


sk_simazhao:addSkill(sk_zhaoxin)
sk_simazhao:addSkill(sk_zhihe)


sgs.LoadTranslationTable{
    ["sk_simazhao"] = "SK司马昭",
    ["&sk_simazhao"] = "司马昭",
	["#sk_simazhao"] = "狼子野心",
	["~sk_simazhao"] = "我的，宏图霸业……",
	["sk_zhaoxin"] = "昭心",
	[":sk_zhaoxin"] = "当你受到伤害后，你可以展示所有手牌，然后摸X张牌（X为你缺少的花色数）。",
	["$sk_zhaoxin1"] = "就让我大大方方地告诉你。",
	["$sk_zhaoxin2"] = "路人既知，又待如何？",
	["sk_zhihe"] = "制合",
	[":sk_zhihe"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示所有手牌，将其中每种花色的牌均弃置至一张，若如此做，你摸与手牌数等量的牌。"..
	"<font color=\"red\"><b>（操作方法：在弹出的选牌框中，选中你要保留的那张牌，则其余牌会被自动弃置掉）</b></font>",
	["$sk_zhihe1"] = "八荒六合，皆为我用！",
	["$sk_zhihe2"] = "都给我睁大双眼看好了！",
}


--孙皓
sk_sunhao = sgs.General(extension, "sk_sunhao", "wu", 4, true)


--暴戾
sk_baoliCard = sgs.CreateSkillCard{
    name = "sk_baoliCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and (to_select:getEquips():isEmpty() or (not to_select:getJudgingArea():isEmpty()))
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    room:damage(sgs.DamageStruct("sk_baoli", source, targets[1]))
	end
}

sk_baoli = sgs.CreateViewAsSkillV2{
    name = "sk_baoli",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_baoliCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_baoliCard:clone()
	end,
}


sk_sunhao:addSkill(sk_baoli)


sgs.LoadTranslationTable{
    ["sk_sunhao"] = "SK孙皓",
    ["&sk_sunhao"] = "孙皓",
	["#sk_sunhao"] = "归命侯",
	["~sk_sunhao"] = "你们，好大的胆子！",
	["sk_baoli"] = "暴戾",
	[":sk_baoli"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以对一名装备区没有牌或判定区有牌的其他角色造成1点伤害。",
	["$sk_baoli1"] = "还等什么？拖出去斩了！",
	["$sk_baoli2"] = "看见了吗？这就是违抗我的下场！",
}


--许攸
sk_xuyou = sgs.General(extension, "sk_xuyou", "wei", 3, true)


--夜袭
sk_yexi = sgs.CreateTriggerSkillV2{
    name = "sk_yexi",
	events = {sgs.EventPhaseStart, sgs.TargetConfirming, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		if event == sgs.EventPhaseStart then
			if player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, player:objectName())
			elseif player:getPhase() == sgs.Player_Play and (player:hasFlag("yexi_redslash_ready") or player:hasFlag("yexi_blackslash_ready")) then
				for _, xuyou in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if player:objectName() ~= xuyou:objectName() then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, xuyou:objectName())
						break
					end
				end
			end
		elseif event == sgs.TargetConfirming then
		    local use = data:toCardUse()
			local current = room:getCurrent()
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() and use.from
				and current and current:objectName() == use.from:objectName() and current:hasFlag("yexi_blackslash_buff") then
				for _, xuyou in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, xuyou:objectName())
					break
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and (player:hasFlag("yexi_blackslash_buff") or player:hasFlag("yexi_redslash_buff")) then
				for _, xuyou in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if player:objectName() ~= xuyou:objectName() then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, xuyou:objectName())
						break
					end
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart and ctx.invoker and ctx.invoker:objectName() == player:objectName()
			and player:getPhase() == sgs.Player_Finish then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then return false end
		if event == sgs.EventPhaseStart then
			if target:objectName() == player:objectName() and player:getPhase() == sgs.Player_Finish then
				if player:isKongcheng() then return false end
				room:askForDiscard(player, skill:objectName(), 1, 1, false, false)
				room:broadcastSkillInvoke(skill:objectName())
				local chosen = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName())
				if chosen then
					local choice = room:askForChoice(chosen, skill:objectName(), "yexi_blackslash+yexi_redslash")
					if choice == "yexi_blackslash" then
						room:setPlayerFlag(chosen, "yexi_blackslash_ready")
						local yexi_black = sgs.LogMessage()
						yexi_black.from = chosen
						yexi_black.arg = "yexi_blackslash"
						yexi_black.type = "#sk_yexiBlack"
						room:sendLog(yexi_black)
						room:addPlayerMark(chosen, "&sk_yexi+black+to+#"..player:objectName().."-SelfPlayClear")
					else
						room:setPlayerFlag(chosen, "yexi_redslash_ready")
						local yexi_red = sgs.LogMessage()
						yexi_red.from = chosen
						yexi_red.arg = "yexi_redslash"
						yexi_red.type = "#sk_yexiRed"
						room:sendLog(yexi_red)
						room:addPlayerMark(chosen, "&sk_yexi+red+to+#"..player:objectName().."-SelfPlayClear")
					end
				end
			elseif target:getPhase() == sgs.Player_Play then
				if target:hasFlag("yexi_redslash_ready") then
					room:setPlayerFlag(target, "-yexi_redslash_ready")
					room:setPlayerFlag(target, "yexi_redslash_buff")
				end
				if target:hasFlag("yexi_blackslash_ready") then
					room:setPlayerFlag(target, "-yexi_blackslash_ready")
					room:setPlayerFlag(target, "yexi_blackslash_buff")
				end
			end
		elseif event == sgs.TargetConfirming then
		    local use = ctx.original_data:toCardUse()
			local current = room:getCurrent()
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() and use.from
				and current and current:objectName() == use.from:objectName() and current:hasFlag("yexi_blackslash_buff") then
			    for _, p in sgs.qlist(use.to) do
                    p:addQinggangTag(use.card)
                end
				local log = sgs.LogMessage()
				log.type = "#IgnoreArmor"
				log.from = current
				log.card_str = use.card:toString()
				room:sendLog(log)
			end
		elseif event == sgs.EventPhaseEnd then
			if target:objectName() ~= player:objectName() and target:getPhase() == sgs.Player_Play then
				if target:hasFlag("yexi_blackslash_buff") then
					room:setPlayerFlag(target, "-yexi_blackslash_buff")
					local yexi_end = sgs.LogMessage()
					yexi_end.from = target
					yexi_end.arg = "sk_yexi"
					yexi_end.type = "#sk_yexiEnd"
					room:sendLog(yexi_end)
				end
				if target:hasFlag("yexi_redslash_buff") then
					room:setPlayerFlag(target, "-yexi_redslash_buff")
					local yexi_end = sgs.LogMessage()
					yexi_end.from = target
					yexi_end.arg = "sk_yexi"
					yexi_end.type = "#sk_yexiEnd"
					room:sendLog(yexi_end)
				end
			end
		end
		return false
	end,
}

sk_yexiRedslashBuff = sgs.CreateTargetModSkillV2{
    name = "#sk_yexi",
	pattern = "Slash",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player, card = ctx:getPrimary(), ctx:getCard()
	    if player and card and ctx:getModType() == sgs.TargetModSkill_DistanceLimit
			and card:isRed() and player:hasFlag("yexi_redslash_buff") then
		    return 9999
		end
		return false
	end
}


extension:insertRelatedSkills("sk_yexi", "#sk_yexi")


--狂言
sk_kuangyan = sgs.CreateTriggerSkillV2{
    name = "sk_kuangyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() then
		    if (damage.nature == sgs.DamageStruct_Normal and damage.damage <= 1) or damage.damage >= 2 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() then
		    if damage.nature == sgs.DamageStruct_Normal and damage.damage <= 1 then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), 1)
				return true
			end
			if damage.damage >= 2 then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
				damage.damage = damage.damage + 1
				ctx.original_data:setValue(damage)
				room:broadcastSkillInvoke(skill:objectName(), 2)
			end
		end
		return false
	end,
}


sk_xuyou:addSkill(sk_yexi)
sk_xuyou:addSkill(sk_yexiRedslashBuff)
sk_xuyou:addSkill(sk_kuangyan)


sgs.LoadTranslationTable{
    ["sk_xuyou"] = "SK许攸",
    ["&sk_xuyou"] = "许攸",
	["#sk_xuyou"] = "诡计智将",
	["~sk_xuyou"] = "汝等果然不可救药！",
	["sk_yexi"] = "夜袭",
	[":sk_yexi"] = "回合结束阶段，你可以弃置一张手牌，然后指定一名其他角色选择：1.使用黑色杀时无视防具。2.使用红色杀时无视距离。该角色将在他的下个出牌阶段获得"..
	"上述效果中的一个。",
	["$sk_yexi"] = "出其不意，方可一招制敌！",
	["yexi_blackslash"] = "使用黑色杀时无视防具",
	["yexi_redslash"] = "使用红色杀时无视距离",
	["#sk_yexiBlack"] = "%from 选择的夜袭效果 “%arg” 将在其下个回合的出牌阶段开始时生效。",
	["#sk_yexiRed"] = "%from 选择的夜袭效果 “%arg” 将在其下个回合的出牌阶段开始时生效。",
	["#sk_yexiEnd"] = "%from 的【%arg】失效。",
	["sk_kuangyan"] = "狂言",
	[":sk_kuangyan"] = "<font color = \"blue\"><b>锁定技。</b></font>你受到1点无属性伤害时，该伤害对你无效。你受到两点或两点以上伤害时，该伤害+1。",
	["$sk_kuangyan1"] = "汝等皆匹夫耳，何足道哉！",
	["$sk_kuangyan2"] = "什么？竟敢如此对我？",
}


--张绣
sk_zhangxiu = sgs.General(extension, "sk_zhangxiu", "qun", 4, true)


--花枪
sk_huaqiangCard = sgs.CreateSkillCard{
    name = "sk_huaqiangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:objectName() ~= player:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    room:damage(sgs.DamageStruct("sk_huaqiang", source, targets[1]))
	end
}

sk_huaqiang = sgs.CreateViewAsSkillV2{
    name = "sk_huaqiang",
	n = 4,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_huaqiangCard") or player:hasUsed(skill:objectName()))
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not (player and to_select) then return false end
		local need = math.max(1, player:getHp())
	    if request:getSelectedCardIds():length() >= math.min(4, need) then return false end
		if to_select:isEquipped() then return false end
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			if sgs.Sanguosha:getCard(id):getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
	    return request:getSelectedCardIds():length() >= math.max(1, player:getHp())
	end,
	create_card = function(skill, request)
		local huaqiang_card = sk_huaqiangCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
		    huaqiang_card:addSubcard(id)
		end
		return huaqiang_card
	end,
}


--朝凰
sk_chaohuangCard = sgs.CreateSkillCard{
    name = "sk_chaohuangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    if to_select:getSeat() == player:getSeat() then return false end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		return player:inMyAttackRange(to_select) and (not sgs.Sanguosha:isProhibited(player, to_select, slash)) and (not player:isJilei(slash, true))
	end,
	feasible = function(self, targets, player)
	    return #targets > 0
	end,
	on_use = function(self, room, source, targets)
	    room:loseHp(source, 1, true, source, "sk_chaohuang")
	    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("sk_chaohuangSlash")
		for _, target in ipairs(targets) do
		    local card_use = sgs.CardUseStruct()
			card_use.from = source
			card_use.card = slash
			card_use.to:append(target)
			room:useCard(card_use, false)
		end
		slash:deleteLater()
	end
}

sk_chaohuang = sgs.CreateViewAsSkillV2{
    name = "sk_chaohuang",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_chaohuangCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_chaohuangCard:clone()
	end,
}


sk_zhangxiu:addSkill(sk_huaqiang)
sk_zhangxiu:addSkill(sk_chaohuang)


sgs.LoadTranslationTable{
    ["sk_zhangxiu"] = "SK张绣",
    ["&sk_zhangxiu"] = "张绣",
	["#sk_zhangxiu"] = "北地枪王",
	["~sk_zhangxiu"] = "有此一战，也算得偿夙愿。",
	["sk_huaqiang"] = "花枪",
	[":sk_huaqiang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置X种不同花色的手牌，然后对一名其他角色造成1点伤害（X为你的体力值且至多为4，至少为"..
	"1）。",
	["$sk_huaqiang1"] = "喝！",
	["$sk_huaqiang2"] = "接招吧！",
	["sk_chaohuang"] = "朝凰",
	["sk_chaohuangSlash"] = "朝凰",
	[":sk_chaohuang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去1点体力，然后视为对你攻击范围内任意名其他角色依次使用一张【杀】（不计入出牌阶段"..
	"的使用限制）。",
	["$sk_chaohuang"] = "看招！百鸟朝凰！",
}


--田丰
sk_tianfeng = sgs.General(extension, "sk_tianfeng", "qun", 3)


--死谏
sk_sijian = sgs.CreateTriggerSkillV2{
    name = "sk_sijian",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName()
			and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
	    local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
		    if not p:isNude() then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then return false end
		local target = room:askForPlayerChosen(player, targets, skill:objectName())
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		if not target then return false end
	    local n = player:getHp()
		room:setPlayerFlag(target, "sk_sijian_InTempMoving")
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		local card_ids = sgs.IntList()
		local original_places = sgs.IntList()
		for i = 0, n - 1, 1 do
		    if not player:canDiscard(target, "he") then break end
			local c = room:askForCardChosen(player, target, "he", skill:objectName())
			card_ids:append(c)
			original_places:append(room:getCardPlace(card_ids:at(i)))
			dummy:addSubcard(card_ids:at(i))
			target:addToPile("#sijian_pile", card_ids:at(i), false)
		end
		for i = 0, dummy:subcardsLength() - 1, 1 do
		    room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), target, original_places:at(i), false)
		end
		room:setPlayerFlag(target, "-sk_sijian_InTempMoving")
		if dummy:subcardsLength() > 0 then
		    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
			room:throwCard(dummy, reason, nil)
			room:broadcastSkillInvoke(skill:objectName())
			dummy:deleteLater()
		end
		return false
	end,
}

sk_sijian_FakeMove = sgs.CreateTriggerSkillV2{
    name = "#sk_sijian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	priority = 10,
	can_trigger = function(skill, event, room, player, data)
		for _, p in sgs.qlist(room:getAllPlayers()) do
		    if p:hasFlag("sk_sijian_InTempMoving") then
				local trigger_list_skill, trigger_list_who = {}, {}
				for _, tianfeng in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, tianfeng:objectName())
					break
				end
				if #trigger_list_skill > 0 then
					return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		return perf50RoomHasFlag(room, "sk_sijian_InTempMoving")
	end,
}


extension:insertRelatedSkills("sk_sijian", "#sk_sijian")


--刚直
sk_gangzhi = sgs.CreateTriggerSkillV2{
    name = "sk_gangzhi",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
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
		if not damage.to or damage.to:objectName() ~= player:objectName() then return false end
		if player:isKongcheng() then
			room:broadcastSkillInvoke(skill:objectName(), 2)
			player:drawCards(player:getMaxHp())
			player:turnOver()
		else
			room:broadcastSkillInvoke(skill:objectName(), 1)
			player:throwAllHandCards()
			return true
		end
		return false
	end,
}


sk_tianfeng:addSkill(sk_sijian)
sk_tianfeng:addSkill(sk_sijian_FakeMove)
sk_tianfeng:addSkill(sk_gangzhi)


sgs.LoadTranslationTable{
    ["sk_tianfeng"] = "SK田丰",
    ["&sk_tianfeng"] = "田丰",
	["~sk_tianfeng"] = "今军败，吾其死矣……",
	["#sk_tianfeng"] = "刚而犯上",
	["sk_sijian"] = "死谏",
	[":sk_sijian"] = "当你失去手牌后，若你没有手牌，你可以弃置一名其他角色的X张牌（X为你的体力值，不足则全弃）。",
	["$sk_sijian"] = "臣愿以死谏言！",
	["@sijian-target"] = "你可选择一名其他角色，然后弃置其等同于你的体力值数的牌（不足则全弃）。",
	["sk_gangzhi"] = "刚直",
	[":sk_gangzhi"] = "当你受到伤害时，若你有手牌，你可以弃置所有手牌，然后防止此伤害；若你没有手牌，你可以将武将牌翻面，然后将手牌数补至体力上限。",
	["$sk_gangzhi1"] = "大丈夫当前斗死，不可苟活！",
	["$sk_gangzhi2"] = "惜哉惜哉，臣有言，而不得语……",
}


--全琮
sk_quancong = sgs.General(extension, "sk_quancong", "wu", 4, true)


--邀名
sk_yaoming = sgs.CreateTriggerSkillV2{
    name = "sk_yaoming",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local quancong = room:getCurrent()
			if not (quancong and quancong:isAlive() and quancong:hasSkill(skill:objectName())) then
				return false
			end
			local card, from
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
				from = use.from
			else
				local resp = data:toCardResponse()
				card = resp.m_card
				from = resp.m_who
			end
			if not card or card:getTypeId() == sgs.Card_TypeSkill then return false end
			if quancong:getPhase() ~= sgs.Player_Play then return false end
			if card:getSuitString() == "" or not from
				or from:objectName() ~= quancong:objectName() then
				return false
			end
			local suits = quancong:getTag("yaoming_suits"):toString():split("+")
			if #suits == 0 then return false end
			local remaining = #suits
			for i = 1, #suits do
				if card:getSuitString() == suits[i] then
					remaining = remaining - 1
					break
				end
			end
			if (remaining == 3 and not quancong:hasFlag("yaoming1_done"))
				or (remaining == 2 and not quancong:hasFlag("yaoming2_done"))
				or (remaining == 1 and not quancong:hasFlag("yaoming3_done"))
				or (remaining == 0 and not quancong:hasFlag("yaoming4_done")) then
				return skill:objectName(), quancong
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName == skill:objectName()
				and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == skill:objectName()
				and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = ctx.original_data:toCardUse().card
			else
				card = ctx.original_data:toCardResponse().m_card
			end
			local suits = player:getTag("yaoming_suits"):toString():split("+")
			if #suits == 0 then return false end
			for i = 1, #suits do
				if card:getSuitString() == suits[i] then
					table.remove(suits, i)
					break
				end
			end
			if #suits == 3 and not player:hasFlag("yaoming1_done") then
				room:setPlayerMark(player, "yaoming", 1)
				room:setPlayerFlag(player, "yaoming1_done")
				player:setTag("yaoming_suits", sgs.QVariant(table.concat(suits, "+")))
				ctx.extra_data:setValue("yaoming1")
				return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("yaoming_draw"))
			end
			if #suits == 2 and not player:hasFlag("yaoming2_done") then
				room:setPlayerMark(player, "yaoming", 2)
				room:setPlayerFlag(player, "yaoming2_done")
				player:setTag("yaoming_suits", sgs.QVariant(table.concat(suits, "+")))
				local targets = sgs.SPlayerList()
				for _, _player in sgs.qlist(room:getOtherPlayers(player)) do
					if not _player:isNude() then targets:append(_player) end
				end
				ctx.extra_data:setValue("yaoming2")
				if targets:isEmpty() then return true end
				return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("yaoming_discard"))
			end
			if #suits == 1 and not player:hasFlag("yaoming3_done") then
				room:setPlayerMark(player, "yaoming", 3)
				room:setPlayerFlag(player, "yaoming3_done")
				player:setTag("yaoming_suits", sgs.QVariant(table.concat(suits, "+")))
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasEquip() or p:getJudgingArea():length() > 0 then
						players:append(p)
					end
				end
				ctx.extra_data:setValue("yaoming3")
				if players:isEmpty() then return true end
				return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("yaoming_move"))
			end
			if #suits == 0 and not player:hasFlag("yaoming4_done") then
				room:setPlayerMark(player, "yaoming", 4)
				room:setPlayerFlag(player, "yaoming4_done")
				ctx.extra_data:setValue("yaoming4")
				return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("yaoming_damage"))
			end
			return false
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart or event == sgs.EventAcquireSkill then
			player:setMark("yaoming_suit", 0)
			room:setPlayerFlag(player, "-yaoming1_done")
			room:setPlayerFlag(player, "-yaoming2_done")
			room:setPlayerFlag(player, "-yaoming3_done")
			room:setPlayerFlag(player, "-yaoming4_done")
			local suits = {"spade", "heart", "club", "diamond"}
			player:setTag("yaoming_suits", sgs.QVariant(table.concat(suits, "+")))
		elseif event == sgs.EventPhaseChanging or event == sgs.EventLoseSkill then
			player:setMark("yaoming_suit", 0)
			room:setPlayerFlag(player, "-yaoming1_done")
			room:setPlayerFlag(player, "-yaoming2_done")
			room:setPlayerFlag(player, "-yaoming3_done")
			room:setPlayerFlag(player, "-yaoming4_done")
			room:removeTag("yaoming_suits")
			room:setPlayerMark(player, "yaoming", 0)
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local stage = ctx.extra_data:toString()
			if stage == "yaoming1" then
				room:broadcastSkillInvoke(skill:objectName(), 1)
				player:drawCards(1)
			elseif stage == "yaoming2" then
				local targets = sgs.SPlayerList()
				for _, _player in sgs.qlist(room:getOtherPlayers(player)) do
					if not _player:isNude() then targets:append(_player) end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, skill:objectName())
				local c = room:askForCardChosen(player, target, "he", skill:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sk_yaoming", "")
				room:throwCard(sgs.Sanguosha:getCard(c), reason, target, player)
				room:broadcastSkillInvoke(skill:objectName(), 2)
			elseif stage == "yaoming3" then
				local targets = room:getAlivePlayers()
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(targets) do
					if p:hasEquip() or p:getJudgingArea():length() > 0 then
						players:append(p)
					end
				end
				if players:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, players, "yaoming_first")
				local q = sgs.QVariant()
				q:setValue(target)
				room:setTag("yaomingTarget", q)
				local card_id = room:askForCardChosen(player, target, "ej", skill:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local playermoves = sgs.SPlayerList()
				if place == sgs.Player_PlaceEquip then
					local equip = card:getRealCard():toEquipCard()
					local index = equip:location()
					for _, p in sgs.qlist(targets) do
						if p:getEquip(index) == nil then
							playermoves:append(p)
						end
					end
				elseif place == sgs.Player_PlaceDelayedTrick then
					for _, p in sgs.qlist(targets) do
						if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							playermoves:append(p)
						end
					end
				end
				if not playermoves:isEmpty() then
					local playermove = room:askForPlayerChosen(player, playermoves, "yaoming_second")
					room:removeTag("yaomingTarget")
					if playermove then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,
							player:objectName(), skill:objectName(), "")
						room:moveCardTo(card, target, playermove, place, reason)
						room:broadcastSkillInvoke(skill:objectName(), 3)
					end
				end
			elseif stage == "yaoming4" then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName())
				room:damage(sgs.DamageStruct(skill:objectName(), player, to))
				room:broadcastSkillInvoke(skill:objectName(), 4)
			end
		end
		return false
	end,
}


sk_quancong:addSkill(sk_yaoming)


sgs.LoadTranslationTable{
    ["sk_quancong"] = "SK全琮",
	["&sk_quancong"] = "全琮",
	["#sk_quancong"] = "慕势耀族",
	["~sk_quancong"] = "主公恩情浩荡，我儿必可守荆州……",
	["sk_yaoming"] = "邀名",
	[":sk_yaoming"] = "出牌阶段，当你使用或打出一张牌时，若此牌的花色是你此阶段使用或打出的：第一种，你可以摸一张牌；第二种，你可以弃置一名其他角色的一张牌；第"..
	"三种，你可以将场上一张牌移至另一位置；第四种，你可以对一名其他角色造成1点伤害。",
	["yaoming_first"] = "请选择【邀名】要移动的牌的目标",
	["yaoming_second"] = "请选择【邀名】此牌移动至的目标",
	["yaoming_damage"] = "请选择【邀名】造成伤害的目标",
	["$sk_yaoming1"] = "国家大计，盖弱敌，而副国望也。",
	["$sk_yaoming2"] = "群臣有不谏者，臣以为不忠。",
	["$sk_yaoming3"] = "所市非急，当振倒悬之患。",
	["$sk_yaoming4"] = "以圣朝之威，何向而不克？",
	["sk_yaoming:yaoming_draw"] = "是否发动“邀名”，摸1张牌？",
	["sk_yaoming:yaoming_discard"] = "是否发动“邀名”，弃置一名其他角色的一张牌？",
	["sk_yaoming:yaoming_move"] = "是否发动“邀名”，将场上的一张牌移动至另一位置？",
	["sk_yaoming:yaoming_damage"] = "是否发动“邀名”，对一名其他角色造成1点伤害？",
	["designer:sk_quancong"] = "极略三国",
    ["illustrator:sk_quancong"] = "极略三国",
    ["cv:sk_quancong"] = "极略三国",
}


--马腾
sk_mateng = sgs.General(extension, "sk_mateng", "qun", 4, true)


--雄异
sk_xiongyi = sgs.CreateTriggerSkillV2{
    name = "sk_xiongyi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Start
			and (player:getHp() == 1 or player:isKongcheng()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		if player:getHp() == 1 then
			local re = sgs.RecoverStruct()
			re.who = player
			room:recover(player, re, true)
		end
		if player:isKongcheng() then player:drawCards(2) end
		return false
	end,
}


sk_mateng:addSkill("mashu")
sk_mateng:addSkill(sk_xiongyi)


sgs.LoadTranslationTable{
    ["sk_mateng"] = "SK马腾",
	["&sk_mateng"] = "马腾",
	["#sk_mateng"] = "驰骋西陲",
	["~sk_mateng"] = "我要，永守西凉……",
	["sk_xiongyi"] = "雄异",
	[":sk_xiongyi"] = "回合开始阶段，若你的体力值为1，你可以回复1点体力；若你没有手牌，你可以摸两张牌。",
	["$sk_xiongyi1"] = "此时不战，更待何时？",
	["$sk_xiongyi2"] = "弟兄们，我们的机会来了！",
	["designer:sk_mateng"] = "极略三国",
    ["illustrator:sk_mateng"] = "极略三国",
    ["cv:sk_mateng"] = "极略三国",
}


--张布
sk_zhangbu = sgs.General(extension, "sk_zhangbu", "wu", 3, true)


--朝臣
sk_chaochenCard = sgs.CreateSkillCard{
    name = "sk_chaochenCard",
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
		room:obtainCard(target, self, false)
		target:setMark("chaochen_hand", 1)
		room:addPlayerMark(target, "&sk_chaochen+to+#"..source:objectName().."-SelfStartClear")
		room:addPlayerMark(target, "sk_chaochen"..source:objectName().."-SelfStartClear")
	end
}

sk_chaochenVS = sgs.CreateViewAsSkillV2{
    name = "sk_chaochen",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return (not player:isKongcheng()) and (not player:hasUsed("#sk_chaochenCard"))
			and (not player:hasUsed(skill:objectName()))
	end,
	can_select_card = function(skill, request, to_select)
		return to_select and not to_select:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local card = sk_chaochenCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}

sk_chaochen = sgs.CreateTriggerSkillV2{
    name = "sk_chaochen",
	view_as_skill = sk_chaochenVS,
	events = {sgs.EventPhaseStart, sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start or player:getMark("chaochen_hand") == 0 then
				return false
			end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, zhangbu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, zhangbu:objectName())
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.who:objectName() == player:objectName()
				and player:hasSkill(skill:objectName()) then
				return skill:objectName(), player:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local p = ctx.invoker
			if not p then return false end
			p:setMark("chaochen_hand", 0)
			if p:getHandcardNum() > p:getHp()
				and p:getMark("sk_chaochen"..player:objectName().."-SelfStartClear") > 0 then
				room:doAnimate(1, player:objectName(), p:objectName())
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:notifySkillInvoked(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
				room:damage(sgs.DamageStruct(skill:objectName(), player, p))
			end
		elseif event == sgs.Death then
			for _, t in sgs.qlist(room:getPlayers()) do
				if t:getMark("chaochen_hand") > 0 then t:setMark("chaochen_hand", 0) end
			end
		end
		return false
	end,
}


--全政
sk_quanzheng = sgs.CreateTriggerSkillV2{
    name = "sk_quanzheng",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.card and use.from and (use.card:isKindOf("Slash") or use.card:isNDTrick())
			and use.to:contains(player)) then
			return false
		end
		if use.from:objectName() ~= player:objectName()
			and (use.from:getHandcardNum() > player:getHandcardNum()
				or use.from:getEquips():length() > player:getEquips():length()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(1)
		return false
	end,
}


sk_zhangbu:addSkill(sk_chaochen)
sk_zhangbu:addSkill(sk_quanzheng)


sgs.LoadTranslationTable{
    ["sk_zhangbu"] = "SK张布",
	["&sk_zhangbu"] = "张布",
	["#sk_zhangbu"] = "养痈遗患",
	["~sk_zhangbu"] = "饶命啊，陛下……",
	["sk_chaochen"] = "朝臣",
	[":sk_chaochen"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将至少一张手牌交给一名其他角色，若如此做，该角色的回合开始阶段开始时，若其手"..
	"牌数大于其体力值，你对其造成1点伤害。",
	["$sk_chaochen"] = "陛下勿忧，臣有一计。",
	["sk_quanzheng"] = "全政",
	[":sk_quanzheng"] = "当你成为其他角色使用的【杀】或非延时锦囊牌的目标后，若其手牌或装备区的牌数大于你对应的区域，你可以摸一张牌。",
	["$sk_quanzheng"] = "你们这些蝼蚁，敢在我面前横？",
	["designer:sk_zhangbu"] = "极略三国",
    ["illustrator:sk_zhangbu"] = "极略三国",
    ["cv:sk_zhangbu"] = "极略三国",
}


--贺齐
sk_heqi = sgs.General(extension, "sk_heqi", "wu", 4, true)


--迭嶂
sk_diezhang = sgs.CreateTriggerSkillV2{
    name = "sk_diezhang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:getPhase() ~= sgs.Player_Play or not use.card
				or use.card:getTypeId() == sgs.Card_TypeSkill then
				return false
			end
			return skill:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_NotActive or change.to == sgs.Player_NotActive then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card:getNumber() > player:getTag("diezhang_point"):toInt() then
				if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then
					return false
				end
				room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			end
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "sk_diezhang") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
			room:addPlayerMark(player, "&sk_diezhang+:+"..use.card:getNumberString().."-Clear")
			player:setTag("diezhang_point", sgs.QVariant(math.min(13, use.card:getNumber())))
		elseif event == sgs.EventPhaseChanging then
			player:setTag("diezhang_point", sgs.QVariant(999))
		end
		return false
	end,
}


sk_heqi:addSkill(sk_diezhang)


sgs.LoadTranslationTable{
    ["sk_heqi"] = "SK贺齐",
	["&sk_heqi"] = "贺齐",
	["#sk_heqi"] = "绥静邦域",
	["~sk_heqi"] = "我的坚甲利兵……",
	["sk_diezhang"] = "迭嶂",
	[":sk_diezhang"] = "出牌阶段，当你使用牌时，若此牌的点数大于你此阶段使用的上一张牌，你可以摸一张牌。",
	["$sk_diezhang1"] = "开山凿路，以破敌军！",
	["$sk_diezhang2"] = "一山还有一山高！",
	["designer:sk_heqi"] = "极略三国",
    ["illustrator:sk_heqi"] = "极略三国",
    ["cv:sk_heqi"] = "极略三国",
}


--陈到
sk_chendao = sgs.General(extension, "sk_chendao", "shu")


--忠勇
sk_zhongyong = sgs.CreateTriggerSkillV2{
	name = "sk_zhongyong",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.DrawNCards, sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Play or change.from == sgs.Player_Play)
				and player:hasFlag("sk_zhongyong") then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				return skill:objectName()
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" and player:hasFlag("sk_zhongyong") then
				return skill:objectName()
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName()) and player:getPhase() == sgs.Player_Discard and
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				and player:hasFlag("sk_zhongyong") and not player:hasFlag("zhongyong_InTempMoving") then
				local i = 0
				for _, card_id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						local place = move.from_places:at(i)
						if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
							return skill:objectName()
						end
					end
					i = i + 1
				end
			end
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
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_Play then
				if player:hasFlag("sk_zhongyong") then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						room:setFixedDistance(player, p, 1)
					end
				end
			end
			if change.from == sgs.Player_Play then
				if player:hasFlag("sk_zhongyong") then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						room:removeFixedDistance(player, p, 1)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			room:loseHp(player, 1, true, player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName(), 1)
			room:setPlayerFlag(player, "sk_zhongyong")
			room:addPlayerMark(player, "&sk_zhongyong-Clear")
		elseif event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			draw.num = draw.num + player:getLostHp()
			ctx.original_data:setValue(draw)
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			local i = 0
			local zhongyong_card = sgs.IntList()
			for _,card_id in sgs.qlist(move.card_ids) do
				if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
					local place = move.from_places:at(i)
					if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
						zhongyong_card:append(card_id)
					end
				end
				i = i + 1
			end
			if not zhongyong_card:isEmpty() then
				local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),skill:objectName(),"#sk_zhongyong",true,true)
				if target and target:isAlive() then
					room:setPlayerFlag(player, "zhongyong_InTempMoving")
					local move3 = sgs.CardsMoveStruct()
					move3.card_ids = zhongyong_card
					move3.to_place = sgs.Player_PlaceHand
					move3.to = target
					room:broadcastSkillInvoke(skill:objectName(), 2)
					room:moveCardsAtomic(move3, true)
					room:setPlayerFlag(player, "-zhongyong_InTempMoving")
					room:setPlayerFlag(player, "-sk_zhongyong")
				end
			end
		end
		return false
	end
}


sk_chendao:addSkill(sk_zhongyong)


sgs.LoadTranslationTable{
	["sk_chendao"] = "SK陈到",
	["&sk_chendao"] = "陈到",
	["~sk_chendao"] = "你们，别想再靠近，半步……",
	["#sk_chendao"] = "白毦之烈",
	["sk_zhongyong"] = "忠勇",
	[":sk_zhongyong"] = "回合开始阶段开始时，你可以失去1点体力，然后于此回合的摸牌阶段摸牌时，可额外摸x张牌（x为你已损失的体力值）；于此回合的出牌阶段，当你计"..
	"算与其他角色的距离时，始终为1；于此回合的弃牌阶段弃牌后，可指定一名其他角色获得你弃置的牌。",
	["$sk_zhongyong1"] = "有我在，无人能伤主公分毫！",
	["$sk_zhongyong2"] = "主公的安危，由我来守护！",
	["#sk_zhongyong"] = "你可选择一名其他角色为【忠勇】的目标来获得这些弃牌",
	["designer:sk_chendao"] = "极略三国",
    ["illustrator:sk_chendao"] = "极略三国",
    ["cv:sk_chendao"] = "极略三国",
}


--郭女王
sk_guonvwang = sgs.General(extension, "sk_guonvwang", "wei", 3, false)


--恭慎
sk_gongshenCard = sgs.CreateSkillCard{
    name = "sk_gongshenCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    source:drawCards(1)
		local n = 9999
		for _, _player in sgs.qlist(room:getAlivePlayers()) do
		    n = math.min(n, _player:getHandcardNum())
		end
		if source:getHandcardNum() <= n then
		    if source:isWounded() then
			    local re = sgs.RecoverStruct()
			    re.who = source
		        room:recover(source, re, true)
			end
		end
	end
}

sk_gongshen = sgs.CreateViewAsSkillV2{
    name = "sk_gongshen",
	n = 3,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getHandcardNum() + player:getEquips():length() >= 3
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not (player and to_select) then return false end
		return not player:isJilei(to_select)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 3
	end,
	create_card = function(skill, request)
		local card = sk_gongshenCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(skill:objectName())
		return card
	end,
}


--俭约
sk_jianyue = sgs.CreateTriggerSkillV2{
    name = "sk_jianyue",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Finish then return false end
		if room:getDiscardPile():isEmpty() then return false end  --没有弃牌堆你俭约个锤子
		local x = 9999
		for _, _player in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, _player:getHandcardNum())
		end
		if player:getHandcardNum() > x then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, guonvwang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(trigger_list_skill, skill:objectName())
			table.insert(trigger_list_who, guonvwang:objectName())
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		local x = 9999
		for _, _player in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, _player:getHandcardNum())
		end
		if p:getHandcardNum() > x then return false end
		return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("jianyuebupai:" .. p:objectName()))
	end,
	on_effect = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), p:objectName())
		local cards = room:getDiscardPile()
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		local a = 0
		while true do
			local n = cards:length()
			if n == 0 then break end
			local j = math.random(0, n-1)
			local id = cards:at(j)
			cards:removeOne(id)
			dummy:addSubcard(id)
			a = a + 1
			local _min = 9999
			for _, _player in sgs.qlist(room:getAlivePlayers()) do
				if _player:objectName() ~= p:objectName() then
					_min = math.min(_min, _player:getHandcardNum())
				else
					_min = math.min(_min, _player:getHandcardNum() + a)
				end
			end
			if cards:length() == 0 then break end
			if p:getHandcardNum() + a > _min then break end
		end
		p:obtainCard(dummy)
		dummy:deleteLater()
		return false
	end,
}


sk_guonvwang:addSkill(sk_gongshen)
sk_guonvwang:addSkill(sk_jianyue)


sgs.LoadTranslationTable{
	["sk_guonvwang"] = "SK郭女王",
	["&sk_guonvwang"] = "郭女王",
	["~sk_guonvwang"] = "谁是红尘父母造，众生假情利为因。",
	["#sk_guonvwang"] = "文德皇后",
	["sk_gongshen"] = "恭慎",
	[":sk_gongshen"] = "出牌阶段，你可以弃置三张牌，然后摸一张牌。若此时你的手牌数为全场最少（或之一），你回复1点体力。",
	["$sk_gongshen1"] = "陛下，谨慎难道是坏事吗？",
	["$sk_gongshen2"] = "臣妾出身微寒，唯勤慎肃恭以待上。",
	["sk_jianyue"] = "俭约",
	["sk_jianyue:jianyuebupai"] = "是否发动“俭约”令%src从弃牌堆中随机获得牌直至其手牌数不为最少（或之一）？",
	[":sk_jianyue"] = "一名角色的回合结束阶段开始时，若该角色的手牌数为最少（或之一），你可令其从弃牌堆随机获得牌直到其手牌数不为最少（或之一）。",
	["$sk_jianyue1"] = "此乃社稷之福，国家之幸也。",
	["$sk_jianyue2"] = "从俭去奢，必有裨益。",
	["designer:sk_guonvwang"] = "极略三国",
    ["illustrator:sk_guonvwang"] = "极略三国",
    ["cv:sk_guonvwang"] = "极略三国",
}


--程昱
sk_chengyu = sgs.General(extension, "sk_chengyu", "wei", 3, true)


--捧日
sk_pengriCard = sgs.CreateSkillCard{
    name = "sk_pengriCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    source:drawCards(2)
		for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    if t:canSlash(source, nil, true) then
				room:doAnimate(1, source:objectName(), t:objectName())
				room:askForUseSlashTo(t, source, "@pengri-slash:" .. source:objectName())
			end
		end
	end
}

sk_pengri = sgs.CreateViewAsSkillV2{
    name = "sk_pengri",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_pengriCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_pengriCard:clone()
	end,
}


--胆谋
sk_danmou = sgs.CreateTriggerSkillV2{
    name = "sk_danmou",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName()
			and not (damage.from:isKongcheng() and player:isKongcheng()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.from or damage.from:objectName() == player:objectName() then return false end
		room:doAnimate(1, player:objectName(), damage.from:objectName())
		local danmouExchange = sgs.CardsMoveList()
        local move1 = sgs.CardsMoveStruct(player:handCards(), damage.from, sgs.Player_PlaceHand,
		    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), damage.from:objectName(), "sk_danmou", ""))
        local move2 = sgs.CardsMoveStruct(damage.from:handCards(), player, sgs.Player_PlaceHand,
		    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), damage.from:objectName(), "sk_danmou", ""))
        danmouExchange:append(move2)
        danmouExchange:append(move1)
		room:broadcastSkillInvoke(skill:objectName())
        room:moveCardsAtomic(danmouExchange, false)
		return false
	end,
}


sk_chengyu:addSkill(sk_pengri)
sk_chengyu:addSkill(sk_danmou)


sgs.LoadTranslationTable{
	["sk_chengyu"] = "SK程昱",
	["&sk_chengyu"] = "程昱",
	["~sk_chengyu"] = "知足不辱，吾当急流勇退。",
	["#sk_chengyu"] = "筹妙绝伦",
	["sk_pengri"] = "捧日",
	["@pengri-slash"] = "%src的【捧日】效果，你可以对%src使用一张【杀】。",
	["$sk_pengri1"] = "捧泰山之日，立吾主之名。",
	["$sk_pengri2"] = "以将军之神武，霸王之业可图也！",
	[":sk_pengri"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以摸两张牌，然后攻击范围内含有你的其他角色可依次对你使用一张【杀】。",
	["sk_danmou"] = "胆谋",
	[":sk_danmou"] = "当你受到伤害后，你可以与伤害来源交换手牌。",
	["$sk_danmou1"] = "背水为阵，伏兵施队！",
	["$sk_danmou2"] = "兵只七百，尔，可敢来攻？",
	["designer:sk_chengyu"] = "极略三国",
    ["illustrator:sk_chengyu"] = "极略三国",
    ["cv:sk_chengyu"] = "极略三国",
}


--孙乾
sk_sunqian = sgs.General(extension, "sk_sunqian", "shu", 3, true)


--随骥
sk_suijiCard = sgs.CreateSkillCard{
    name = "sk_suijiCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
	    if room:getCurrent() then
		    local target = room:getCurrent()
			room:obtainCard(target, self, false)
			if target:getHandcardNum() > target:getHp() and source:isAlive() then
			    local n = target:getHandcardNum() - target:getHp()
				local prom = string.format("@suiji_tosunqian:%s:%s", source:objectName(), tostring(n))
				local cards = room:askForExchange(target, "sk_suiji", n, n, false, prom)
				room:obtainCard(source, cards, false)
			end
		end
	end
}

sk_suijiVS = sgs.CreateViewAsSkillV2{
    name = "sk_suiji",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		return request:getPattern() == "@@sk_suiji"
	end,
	can_select_card = function(skill, request, to_select)
		return to_select and not to_select:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local card = sk_suijiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName("sk_suiji")
		return card
	end,
}

sk_suiji = sgs.CreateTriggerSkillV2{
    name = "sk_suiji",
	events = {sgs.EventPhaseStart},
	view_as_skill = sk_suijiVS,
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Discard or player:isDead() then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, sunqian in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if sunqian:objectName() ~= player:objectName() and not sunqian:isKongcheng() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, sunqian:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		return room:askForUseCard(player, "@@sk_suiji", "@suiji-give:" .. p:objectName(), -1, sgs.Card_MethodNone)
	end,
	on_effect = function(skill, event, room, player, ctx)
		return false
	end,
}


--凤仪
sk_fengyi = sgs.CreateTriggerSkillV2{
    name = "sk_fengyi",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and use.to:length() == 1 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(1)
		return false
	end,
}


sk_sunqian:addSkill(sk_suiji)
sk_sunqian:addSkill(sk_fengyi)


sgs.LoadTranslationTable{
	["sk_sunqian"] = "SK孙乾",
	["&sk_sunqian"] = "孙乾",
	["~sk_sunqian"] = "既遇伯乐，此生无憾……",
	["#sk_sunqian"] = "雍容秉忠",
	["sk_suiji"] = "随骥",
	["$sk_suiji1"] = "愿随明主，征战四方。",
	["$sk_suiji2"] = "蝇随骥尾，得以绝群。",
	[":sk_suiji"] = "其他角色的弃牌阶段开始时，你可以交给其至少一张手牌，然后其将超出其体力值数量的手牌交给你。",
	["@suiji-give"] = "你可以交给%src至少一张手牌（即使%src的手牌数不大于其体力值，你也可如此做）",
	["@suiji_tosunqian"] = "请将%dest张手牌交给%src。",
	["~sk_suiji"] = "选择至少一张手牌→点击“确定”",
	["sk_fengyi"] = "凤仪",
	[":sk_fengyi"] = "当你成为非延时锦囊牌的唯一目标后，你可以摸一张牌。",
	["$sk_fengyi1"] = "无妨，这些都伤不到我。",
	["$sk_fengyi2"] = "哈哈，此皆浮云耳。",
	["designer:sk_sunqian"] = "极略三国",
    ["illustrator:sk_sunqian"] = "极略三国",
    ["cv:sk_sunqian"] = "极略三国",
}


--董允
sk_dongyun = sgs.General(extension, "sk_dongyun", "shu", 3, true)


--裨补
sk_bibu = sgs.CreateTriggerSkillV2{
    name = "sk_bibu",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, dongyun in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if player:objectName() ~= dongyun:objectName() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, dongyun:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		if player:getHandcardNum() > math.max(1, player:getHp()) then
			ctx.extra_data:setValue("give")
			return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("bibu_give:" .. p:objectName()))
		else
			ctx.extra_data:setValue("draw")
			return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("bibu_draw"))
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		if ctx.extra_data:toString() == "give" then
			local c = room:askForExchange(player, skill:objectName(), 1, 1, false, "@bibu:" .. p:objectName())
			room:broadcastSkillInvoke(skill:objectName(), 1)
			if c then
				room:doAnimate(1, player:objectName(), p:objectName())
				room:obtainCard(p, c, false)
			end
		else
			player:drawCards(1, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName(), 2)
		end
		return false
	end,
}


--匡正
function throwNRamdomCardsFromPile(target, n, pile)
    local room = target:getRoom()
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
	if pile:length() >= n then
	    for i = 1, n do
		    local k = pile:at(math.random(1,pile:length())-1)
		    local c = sgs.Sanguosha:getCard(k)
			dummy:addSubcard(c)
			pile:removeOne(k)
		end
		room:throwCard(dummy, target)
	end
	dummy:deleteLater()
end


function canKuangzheng(target)
    if target:isChained() then return true end
	if target:isAlive() and not target:faceUp() then return true end
	if target:getPile("."):length() > 0 then return true end
	if target:getMark("@duanchang") > 0 then return true end
	return false
end

function initializationKuangzheng(target)
    local room = target:getRoom()
	if target:isChained() then
	    room:setPlayerProperty(target, "chained", sgs.QVariant(false))
		room:broadcastProperty(target, "chained")
	end
	if target:isAlive() and not target:faceUp() then
	    target:turnOver()
	end
	if target:getMark("@duanchang") > 0 then
	    local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local initial_skills = {}
		for _, _general in ipairs(generals) do
		    if target:getGeneral() and target:getGeneralName() ~= _general then table.removeOne(generals, _general) end
			if target:getGeneral2() and target:getGeneral2Name() ~= _general then table.removeOne(generals, _general) end
		end
		for _, g in ipairs(generals) do
		    local t = sgs.Sanguosha:getGeneral(g)
			for _, skill in sgs.qlist(t:getVisibleSkillList()) do
			    table.insert(initial_skills, skill)
			end
		end
		if #initial_skills > 0 then room:handleAcquireDetachSkills(target, table.concat(initial_skills, "|")) end
	end
	target:clearPrivatePiles()
end

sk_kuangzheng = sgs.CreateTriggerSkillV2{
    name = "sk_kuangzheng",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if canKuangzheng(t) then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if canKuangzheng(t) then targets:append(t) end
		end
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		initializationKuangzheng(target)
		return false
	end,
}


sk_dongyun:addSkill(sk_bibu)
sk_dongyun:addSkill(sk_kuangzheng)


sgs.LoadTranslationTable{
    ["sk_dongyun"] = "SK董允",
	["&sk_dongyun"] = "董允",
	["~sk_dongyun"] = "墨守成规，终为其害啊！",
	["#sk_dongyun"] = "秉正匡主",
	["sk_bibu"] = "裨补",
	["$sk_bibu1"] = "此乃丞相厚托。",
	["$sk_bibu2"] = "臣，定不辱使命！",
	[":sk_bibu"] = "其他角色的回合结束时，若你的手牌数大于体力值，你可以将一张手牌交给该角色；若你的手牌数不大于体力值，你可以摸一张牌",
	["sk_bibu:bibu_give"] = "你是否发动【裨补】交给%src一张手牌？",
	["@bibu"] = "请交给%src一张手牌。",
	["sk_bibu:bibu_draw"] = "你是否发动【裨补】摸一张牌？",
	["sk_kuangzheng"] = "匡正",
	[":sk_kuangzheng"] = "你的回合结束时，你可以将一名角色的武将牌恢复至游戏开始时的状态。",
	["$sk_kuangzheng"] = "尽匡救之礼，正诸君之行。",
	["designer:sk_dongyun"] = "极略三国",
    ["illustrator:sk_dongyun"] = "极略三国",
    ["cv:sk_dongyun"] = "极略三国",
}


sk_whiteboard = sgs.General(extension, "sk_whiteboard", "sy_god", "99", true, true, true)


shejian_slash = sgs.CreateTriggerSkillV2{
    name = "shejian_slash",
	events = {},
}


sk_whiteboard:addSkill(shejian_slash)


sgs.LoadTranslationTable{
    ["shejian_slash"] = "舌剑",
}


--祢衡
sk_miheng = sgs.General(extension, "sk_miheng", "qun", 3, true)


--舌剑
sk_shejianCard = sgs.CreateSkillCard{
    name = "sk_shejianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and (not to_select:hasFlag("shejian_used")) and (not to_select:isNude())
		end
		return false
	end,
	feasible = function(self, targets, player)
	    return #targets == 1 and (not targets[1]:hasFlag("shejian_used"))
	end,
	on_use = function(self, room, source, targets)
	    local room = source:getRoom()
		local target = targets[1]
	    local id = room:askForCardChosen(source, target, "he", "sk_shejian")
		room:setPlayerFlag(target, "shejian_used")
		room:throwCard(id, target, source)
		if target:canSlash(source, false) then
		    local choice = room:askForChoice(target, "sk_shejian", "useslashtomiheng+cancel")
			if choice ~= "cancel" then
			    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("shejian_slash")
				local card_use = sgs.CardUseStruct()
			    card_use.from = target
			    card_use.card = slash
			    card_use.to:append(source)
			    room:useCard(card_use, false)
			    slash:deleteLater()
			end
		end
	end
}

sk_shejianVS = sgs.CreateViewAsSkillV2{
    name = "sk_shejian",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getArmor() == nil
	end,
	create_card = function(skill, request)
	    return sk_shejianCard:clone()
	end,
}

sk_shejian = sgs.CreateTriggerSkillV2{
    name = "sk_shejian",
	view_as_skill = sk_shejianVS,
	events = {sgs.Death, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.who:objectName() == player:objectName() then
				return skill:objectName(), player:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, t in sgs.qlist(room:getPlayers()) do
			if t:hasFlag("shejian_used") then t:setFlags("-shejian_used") end
		end
		return false
	end,
}


--狂傲
sk_kuangao = sgs.CreateTriggerSkillV2{
    name = "sk_kuangao",
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.from and use.from:objectName() ~= player:objectName() and use.card
			and use.card:isKindOf("Slash") and use.to:contains(player)) then
			return false
		end
		local slasher = use.from
		if player:isNude() and slasher:getHandcardNum() >= math.min(5, slasher:getMaxHp()) then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local t = sgs.QVariant()
		t:setValue(use.from)
		return player:askForSkillInvoke(skill:objectName(), t)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local slasher = use.from
		if not slasher then return false end
		local t = sgs.QVariant()
		t:setValue(slasher)
		if player:isNude() and slasher:getHandcardNum() < math.min(5, slasher:getMaxHp()) then
			room:doAnimate(1, player:objectName(), slasher:objectName())
			room:broadcastSkillInvoke(skill:objectName(), 2)
			slasher:drawCards(math.min(5, slasher:getMaxHp()-slasher:getHandcardNum()), skill:objectName())
		else
			room:setPlayerFlag(slasher, "kuangao_target")
			local choice = room:askForChoice(player, skill:objectName(), "kuangao_draw+kuangao_discard", t)
			room:setPlayerFlag(slasher, "-kuangao_target")
			if choice == "kuangao_draw" then
				room:broadcastSkillInvoke(skill:objectName(), 2)
				room:doAnimate(1, player:objectName(), slasher:objectName())
				slasher:drawCards(math.min(5, slasher:getMaxHp()-slasher:getHandcardNum()), skill:objectName())
			else
				room:broadcastSkillInvoke(skill:objectName(), 1)
				room:doAnimate(1, player:objectName(), slasher:objectName())
				local dummy1 = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				dummy1:addSubcards(player:getCards("he"))
				local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
				room:throwCard(dummy1, reason1, nil)
				dummy1:deleteLater()
				local dummy2 = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				dummy2:addSubcards(slasher:getCards("he"))
				local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, slasher:objectName(), skill:objectName(), "")
				room:throwCard(dummy2, reason2, nil)
				dummy2:deleteLater()
			end
		end
		return false
	end,
}


sk_miheng:addSkill(sk_shejian)
sk_miheng:addSkill(sk_kuangao)


sgs.LoadTranslationTable{
    ["sk_miheng"] = "SK祢衡",
	["&sk_miheng"] = "祢衡",
	["~sk_miheng"] = "活于行尸走肉间，不如一死！",
	["#sk_miheng"] = "不可一世",
	["sk_shejian"] = "舌剑",
	["$sk_shejian"] = "酒囊饭袋，也敢自称英雄？",
	[":sk_shejian"] = "<font color=\"green\"><b>出牌阶段对每名其他角色限一次，</b></font>若你未装备防具，你可以弃置一名其他角色的一张牌，然后该角色可以视为对"..
	"你使用一张无距离限制的【杀】。",
	["useslashtomiheng"] = "视为对其使用一张【杀】",
	["kuangao_discard"] = "弃置所有牌（至少一张），然后目标角色弃置所有牌",
	["kuangao_draw"] = "令该【杀】的使用者将手牌补至体力上限（至多5张）",
	["sk_kuangao"] = "狂傲",
	[":sk_kuangao"] = "当一张对你使用的【杀】结算后，你可以选择一项：弃置所有牌（至少一张），然后该【杀】的使用者弃置所有牌；或令该【杀】的使用者将手牌补至其"..
	"体力上限的张数（至多5张）。",
	["$sk_kuangao1"] = "什么东西，狗屁不通！",
	["$sk_kuangao2"] = "我看，就你还算是个明白人儿！",
	["designer:sk_miheng"] = "极略三国",
    ["illustrator:sk_miheng"] = "极略三国",
    ["cv:sk_miheng"] = "极略三国",
}


--华雄
sk_huaxiong = sgs.General(extension, "sk_huaxiong", "qun", 5)


--奋威
sk_fenwei = sgs.CreateTriggerSkillV2{
	name = "sk_fenwei",
	events = {sgs.DamageCaused},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and damage.card
			and damage.card:isKindOf("Slash") and not damage.transfer
			and damage.to and damage.to:objectName() ~= player:objectName()
			and not damage.to:isKongcheng() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not (damage.to and damage.from and damage.from:objectName() == player:objectName()) then
			return false
		end
		room:doAnimate(1, player:objectName(), damage.to:objectName())
		local id = room:askForCardChosen(player, damage.to, "h", skill:objectName())
		local card = sgs.Sanguosha:getCard(id)
		room:showCard(damage.to, card:getEffectiveId())
		room:broadcastSkillInvoke(skill:objectName())
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
		    player:obtainCard(card)
		elseif not card:isKindOf("BasicCard") then
		    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
			room:throwCard(card, reason, nil)
			local msg = sgs.LogMessage()
			msg.type = "#fenweiDamage"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = tostring(damage.damage)
			msg.arg2 = tostring(damage.damage+1)
			msg.card_str = damage.card:toString()
			room:sendLog(msg)
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
		end
		return false
	end,
}


--恃勇
sk_shiyong = sgs.CreateTriggerSkillV2{
	name = "sk_shiyong",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.chain or damage.transfer then return false end
		if damage.card and damage.card:isKindOf("Slash")
				and (damage.card:isRed() or damage.card:hasFlag("drank")) and not player:hasSkill("shiyong") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		room:loseMaxHp(player)
		return false
	end,
}


sk_huaxiong:addSkill(sk_fenwei)
sk_huaxiong:addSkill(sk_shiyong)


sgs.LoadTranslationTable{
    ["sk_huaxiong"] = "SK华雄",
	["&sk_huaxiong"] = "华雄",
	["~sk_huaxiong"] = "死在你手里，也是命吧……",
	["#sk_huaxiong"] = "魔将",
	["sk_fenwei"] = "奋威",
	["#fenweiDamage"] = "由于 %from 的“<font color=\"yellow\"><b>奋威</b></font>”效果，%from 对 %to 使用的 %card 造成的伤害从 %arg 点增加至 %arg2 点。",
	["$sk_fenwei"] = "还有谁敢接我一刀？",
	[":sk_fenwei"] = "当你使用【杀】对目标角色造成伤害时，你可以展示该角色的一张手牌，若为【桃】或【酒】，则你获得之；若不为基本牌，则你弃掉该牌并令该伤害+1。",
	["sk_shiyong"] = "恃勇",
	[":sk_shiyong"] = "<font color=\"blue\"><b>锁定技，</b></font>你每受到一次红色【杀】或【酒】【杀】造成的伤害后，你减1点体力上限。",
	["$sk_shiyong"] = "混账！休想活命！",
	["designer:sk_huaxiong"] = "极略三国",
    ["illustrator:sk_huaxiong"] = "极略三国",
    ["cv:sk_huaxiong"] = "极略三国",
}


--向朗
sk_xianglang = sgs.General(extension, "sk_xianglang", "shu", 3, true, true)


--[[
	技能名：藏书
	相关武将：SK向朗
	技能描述：当其他角色使用非延时锦囊牌时，你可以交给其一张基本牌，然后获得此牌并令其无效。
	引用：sk_cangshu
]]--
sk_cangshu = sgs.CreateTriggerSkillV2{
	name = "sk_cangshu",
	events = {sgs.TargetConfirmed, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetConfirmed then
			if not (player:isAlive() and player:hasSkill(skill:objectName())) then return false end
			if player:getMark("cangshu_currentturn") > 0 then return false end
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			if not (source and card and card:isNDTrick()) then return false end
			if source:getSeat() == player:getSeat() then return false end
			if player:isKongcheng() then return false end
			return skill:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, xianglang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if xianglang:getMark("cangshu_currentturn") > 0 then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, xianglang:objectName())
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then return true end
		local use = ctx.original_data:toCardUse()
		local source = use.from
		if not source then return false end
		local prompt = string.format("@cangshu-give:%s:%s", source:objectName(), use.card:objectName())
		local cc = room:askForCard(player, "BasicCard", prompt, ctx.original_data, sgs.Card_MethodNone, source)
		if not cc then return false end
		ctx.extra_data:setValue(cc:getEffectiveId())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "cangshu_currentturn", 0)
			return false
		end
		local use = ctx.original_data:toCardUse()
		local source = use.from
		local card = use.card
		if not (source and card) then return false end
		local cc = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
		if not cc then return false end
		room:addPlayerMark(player, "cangshu_currentturn")
		local log = sgs.LogMessage()
		log.type = "#InvokeSkill"
		log.from = player
		log.arg = skill:objectName()
		room:sendLog(log)
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		source:obtainCard(cc)
		player:obtainCard(card)
		local nullified_list = use.nullified_list
		for _, t in sgs.qlist(use.to) do
			table.insert(nullified_list, t:objectName())
		end
		use.nullified_list = nullified_list
		ctx.original_data:setValue(use)
		local msg = sgs.LogMessage()
		msg.from = player
		msg.arg = skill:objectName()
		msg.card_str = card:toString()
		msg.type = "#cangshuNull"
		room:sendLog(msg)
		return false
	end,
}

sk_cangshunul = sgs.CreateTriggerSkillV2{
	name = "#sk_cangshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.NullificationEffect},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local effect = data:toCardEffect()
		if not (effect.card and effect.from) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, xianglang in sgs.qlist(room:findPlayersBySkillName("sk_cangshu")) do
			if effect.from:getSeat() ~= xianglang:getSeat() and xianglang:getMark("cangshu_currentturn") <= 0 then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, xianglang:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		if not (effect.card and effect.from) then return false end
		local prompt = string.format("@cangshu-give:%s:%s", effect.from:objectName(), effect.card:objectName())
		local cc = room:askForCard(player, "BasicCard", prompt, ctx.original_data, sgs.Card_MethodNone, effect.from)
		if not cc then return false end
		ctx.extra_data:setValue(cc:getEffectiveId())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		if not (effect.card and effect.from) then return false end
		local cc = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
		if not cc then return false end
		local log = sgs.LogMessage()
		log.type = "#InvokeSkill"
		log.from = player
		log.arg = "sk_cangshu"
		room:sendLog(log)
		room:broadcastSkillInvoke("sk_cangshu")
		room:notifySkillInvoked(player, "sk_cangshu")
		room:addPlayerMark(player, "cangshu_currentturn")
		effect.from:obtainCard(cc)
		player:obtainCard(effect.card)
		local msg = sgs.LogMessage()
		msg.from = player
		msg.arg = "sk_cangshu"
		msg.card_str = effect.card:toString()
		msg.type = "#cangshuNull"
		room:sendLog(msg)
		return true
	end,
}


extension:insertRelatedSkills("sk_cangshu", "#sk_cangshu")


--[[
	技能名：勘误
	相关武将：SK向朗
	技能描述：当你于回合外需要使用或打出一张基本牌时，你可以弃置一张锦囊牌，视为使用或打出之。
	引用：sk_cangshu
]]--
sk_kanwuCard = sgs.CreateSkillCard{
	name = "sk_kanwu",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and player:getWeapon() and player:getWeapon():getId() == self:getSubcards():first() then
			local card = player:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - player:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and player:getOffensiveHorse() and player:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and player:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = player:getTag("sk_kanwu"):toCard()
		return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and player:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("sk_kanwu"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, player)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = player:getTag("sk_kanwu"):toCard()
		return card and card:targetsFeasible(plist, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, kanwu_basic = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local sk_kanwu_list = {}
			table.insert(sk_kanwu_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_kanwu_list, "normal_slash")
				table.insert(sk_kanwu_list, "thunder_slash")
				table.insert(sk_kanwu_list, "fire_slash")
			end
			kanwu_basic = room:askForChoice(player, "sk_kanwu_slash", table.concat(sk_kanwu_list, "+"))
		end
		local card = sgs.Sanguosha:cloneCard(kanwu_basic, sgs.Card_NoSuit, 0)
		local user_str
		if kanwu_basic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif kanwu_basic == "normal_slash" then
			user_str = "slash"
		else
			user_str = kanwu_basic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		use_card:setSkillName("sk_kanwu")
		use_card:deleteLater()
		if player:getPhase() == sgs.Player_NotActive then
			if self:subcardsLength() > 0 then
				local ji = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				ji:addSubcards(self:getSubcards())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sk_kanwu","")
				room:throwCard(ji, reason, nil)
				ji:deleteLater()
			end
		end
		return use_card
	end,
	on_validate_in_response = function(self, user)  --不能通过此技能打出【杀】，response只能给桃
		local room = user:getRoom()
		local kanwu_basic = -1
		if self:getUserString() == "slash" then
			local sk_kanwu_list = {}
			table.insert(sk_kanwu_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_kanwu_list, "normal_slash")
				table.insert(sk_kanwu_list, "thunder_slash")
				table.insert(sk_kanwu_list, "fire_slash")
			end
			kanwu_basic = room:askForChoice(user, "sk_kanwu_slash", table.concat(sk_kanwu_list, "+"))
		else
			kanwu_basic = self:getUserString()
		end
		local card = sgs.Sanguosha:cloneCard(kanwu_basic, sgs.Card_NoSuit, 0)
		local user_str
		if kanwu_basic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif kanwu_basic == "normal_slash" then
			user_str = "slash"
		else
			user_str = kanwu_basic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		use_card:setSkillName("sk_kanwu")
		use_card:deleteLater()
		if user:getPhase() == sgs.Player_NotActive then
			if self:subcardsLength() > 0 then
				local ji = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				ji:addSubcards(self:getSubcards())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, user:objectName(), "sk_kanwu","")
				room:throwCard(ji, reason, nil)
				ji:deleteLater()
			end
		end
		return use_card
	end
}


sk_kanwu = sgs.CreateViewAsSkillV2{
	name = "sk_kanwu",
	n = 1,
	guhuo_type = "l",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local pattern = request:getPattern()
		if pattern == "slash" or pattern == "jink" then
			return reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		elseif pattern == "peach" then
			return player:getMark("Global_PreventPeach") == 0
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		return to_select and to_select:isKindOf("TrickCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local acard = sk_kanwuCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			acard:addSubcard(id)
		end
		acard:setSkillName(skill:objectName())
		local pattern = request:getPattern()
		if pattern == "peach+analeptic" and player and player:getMark("Global_PreventPeach") > 0 then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
		return acard
	end,
}
sk_xianglang:addSkill(sk_cangshu)
sk_xianglang:addSkill(sk_cangshunul)
sk_xianglang:addSkill(sk_kanwu)


sgs.LoadTranslationTable{
	["sk_xianglang"] = "SK向朗",
	["&sk_xianglang"] = "向朗",
	["~sk_xianglang"] = "我死后，记得给我烧点书啊……",
	["#sk_xianglang"] = "瓜田李下",
	["sk_cangshu"] = "藏书",
	["#cangshuNull"] = "由于 %from 的“%arg”效果，此 %card 无效",
	[":sk_cangshu"] = "每回合限一次，当其他角色使用非延时锦囊牌时，你可以交给其一张基本牌，然后获得此牌并令其无效。",
	["$sk_cangshu"] = "唉，给你一本书，别再打扰我了。",
	["@cangshu-give"] = "你可以交给%src一张基本牌，然后获得%dest，则%dest无效。",
	["sk_kanwu"] = "勘误",
	[":sk_kanwu"] = "当你于回合外需要使用或打出一张基本牌时，你可以弃置一张锦囊牌，视为使用或打出之。",
	["$sk_kanwu"] = "别吵别吵！我执笔再改改。",
	["@kanwu-ask"] = "你可以弃置一张锦囊牌，视为使用/打出了一张【%src】。",
}


--祖茂
sk_zumao = sgs.General(extension, "sk_zumao", "wu", 4)


--引兵
sk_yinbing = sgs.CreateTriggerSkillV2{
	name = "sk_yinbing",
	events = {sgs.TargetConfirming, sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		local source = use.from
		local card = use.card
		if not (source and source:objectName() ~= player:objectName() and card and card:isKindOf("Slash")) then
			return false
		end
		if event == sgs.TargetConfirming then
			for _, t in sgs.qlist(use.to) do
				if player:inMyAttackRange(t) and (not t:getEquips():isEmpty())
					and t:objectName() ~= player:objectName() then
					return skill:objectName()
				end
			end
		elseif event == sgs.TargetConfirmed then
			if use.to:contains(player) and not player:isNude() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.TargetConfirmed then
			return player:askForSkillInvoke("sk_yinbing_draw", ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local card = use.card
			for _, t in sgs.qlist(use.to) do
				if player:inMyAttackRange(t) and (not t:getEquips():isEmpty()) and t:objectName() ~= player:objectName() then
					local dest = sgs.QVariant()
					dest:setValue(t)
					if player:askForSkillInvoke(skill:objectName(), t) then
						room:doAnimate(1, player:objectName(), t:objectName())
						room:setPlayerFlag(t, "yinbing_removetarget")
						local card = room:askForCardChosen(player, t, "e", skill:objectName())
						room:obtainCard(player, card, true)
						room:broadcastSkillInvoke(skill:objectName(), 1)
					end
				end
			end
			for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				if t:hasFlag("yinbing_removetarget") then
					room:setPlayerFlag(t, "-yinbing_removetarget")
					local msg = sgs.LogMessage()
					msg.from = player
					msg.to:append(t)
					msg.arg = skill:objectName()
					msg.type = "#yinbingTrans"
					msg.card_str = card:toString()
					room:sendLog(msg)
					use.to:removeOne(t)
					use.to:append(player)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					room:getThread():trigger(sgs.TargetConfirming, room, player, data)
					return false
				end
			end
		elseif event == sgs.TargetConfirmed then
			room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
			room:broadcastSkillInvoke(skill:objectName(), 2)
			player:drawCards(player:getLostHp(), skill:objectName())
		end
		return false
	end,
}


sk_zumao:addSkill(sk_yinbing)


sgs.LoadTranslationTable{
	["sk_zumao"] = "SK祖茂",
	["&sk_zumao"] = "祖茂",
	["~sk_zumao"] = "望主公平安无事，末将拜别！",
	["#sk_zumao"] = "血路先驱",
	["sk_yinbing"] = "引兵",
	["sk_yinbing_draw"] = "引兵",
	["#yinbingTrans"] = "由于%from的%arg效果，此%card的目标从%to转移至%from。",
	[":sk_yinbing"] = "你攻击范围内的一名其他角色成为【杀】的目标时，你可以获得其装备区的一张牌，然后将该【杀】的目标转移给你（你不得是此【杀】的使用者）；"..
	"当你成为【杀】的目标时，你可以弃置一张牌，然后摸X张牌（X为你已损失的体力值）。",
	["$sk_yinbing1"] = "追兵众多，我来断后！",
	["$sk_yinbing2"] = "来啊！先从我尸体上踏过去！",
	["designer:sk_zumao"] = "极略三国",
    ["illustrator:sk_zumao"] = "极略三国",
    ["cv:sk_zumao"] = "极略三国",
}


--陆抗
sk_lukang = sgs.General(extension, "sk_lukang", "wu", 4)


--衡势
sk_hengshi = sgs.CreateTriggerSkillV2{
	name = "sk_hengshi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Discard and not player:isKongcheng() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(player:getHandcardNum())
		return false
	end,
}


sk_lukang:addSkill(sk_hengshi)


--至交
sk_zhijiao = sgs.CreateTriggerSkillV2{
	name = "sk_zhijiao",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zhijiao",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getMark("@zhijiao") > 0) then return false end
		if event == sgs.CardsMoveOneTime then
			local current = room:getCurrent()
			if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end
			if current:objectName() ~= player:objectName() then return false end
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile)
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish then return false end
			local DiscardPile = room:getDiscardPile()
			local tag = room:getTag("zhijiao_discard"):toString():split("+")
			if #tag == 0 then return false end
			for _, is in ipairs(tag) do
				if is ~= "" and DiscardPile:contains(tonumber(is)) then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local oldtag = room:getTag("zhijiao_discard"):toString():split("+")
			local totag = {}
			for _, is in ipairs(oldtag) do
				table.insert(totag, tonumber(is))
			end
			for _, card_id in sgs.qlist(move.card_ids) do
				table.insert(totag, card_id)
			end
			room:setTag("zhijiao_discard", sgs.QVariant(table.concat(totag,"+")))
		elseif event == sgs.EventPhaseStart then
			local DiscardPile = room:getDiscardPile()
			local tag = room:getTag("zhijiao_discard"):toString():split("+")
			if #tag == 0 then return false end
			room:setPlayerMark(player, "zhijiao_count", #tag)
			local toGainList = sgs.IntList()
			for _, is in ipairs(tag) do
				if is ~= "" and DiscardPile:contains(tonumber(is)) then
					toGainList:append(tonumber(is))
				end
			end
			if toGainList:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(),"@zhijiao-give", true, true)
			room:setPlayerMark(player, "zhijiao_count", 0)
			if target then
				player:loseMark("@zhijiao")
				room:broadcastSkillInvoke(skill:objectName())
				local zhijiao = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(toGainList) do
					zhijiao:addSubcard(id)
				end
				room:obtainCard(target, zhijiao)
				zhijiao:deleteLater()
			end
			room:removeTag("zhijiao_discard")
		end
		return false
	end,
}


sk_lukang:addSkill(sk_zhijiao)


sgs.LoadTranslationTable{
	["sk_lukang"] = "SK陆抗",
	["&sk_lukang"] = "陆抗",
	["~sk_lukang"] = "江东，已无回天之力了……",
	["#sk_lukang"] = "巨川舟楫",
	["sk_hengshi"] = "衡势",
	[":sk_hengshi"] = "弃牌阶段开始时，你可以摸等同于手牌数的牌。",
	["$sk_hengshi1"] = "以今日之大势，当行此计。",
	["$sk_hengshi2"] = "国之大计，审视为先。",
	["sk_zhijiao"] = "至交",
	["@zhijiao"] = "至交",
	["@zhijiao-give"] = "你可以将本回合内弃置的牌交给一名其他角色。",
	[":sk_zhijiao"] = "<font color=\"red\"><b>限定技，</b></font>回合结束阶段开始时，你可以令一名其他角色获得本回合内你因弃置而进入弃牌堆的牌。",
	["$sk_zhijiao1"] = "自古英雄，惜英雄。",
	["$sk_zhijiao2"] = "来而不往，非礼也。",
	["designer:sk_lukang"] = "极略三国",
    ["illustrator:sk_lukang"] = "极略三国",
    ["cv:sk_lukang"] = "极略三国",
}


--孔融
sk_kongrong = sgs.General(extension, "sk_kongrong", "qun", 3, true)


--礼让
sk_lirangVS = sgs.CreateViewAsSkillV2{
	name = "sk_lirang",
	n = 2,
	expand_pile = "gift",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if player:getMark("Global_PreventPeach") > 0 then return false end
			return player:getLostHp() > 0 and player:getPile("gift"):length() >= 2
		end
		local pattern = request:getPattern()
		if string.find(pattern, "peach") then
			if player:getMark("Global_PreventPeach") > 0 then return false end
			return player:getPile("gift"):length() > 1
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not (player and to_select) then return false end
		if request:getSelectedCardIds():length() < 2 then
			return player:getPile("gift"):contains(to_select:getEffectiveId())
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			peach:addSubcard(id)
		end
		peach:setSkillName(skill:objectName())
		return peach
	end,
}

sk_lirang = sgs.CreateTriggerSkillV2{
	name = "sk_lirang",
	view_as_skill = sk_lirangVS,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start or player:isKongcheng() then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, kr in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			local suits = {"spade", "heart", "club", "diamond"}
			local gf = kr:getPile("gift")
			if not gf:isEmpty() then
				for _, id in sgs.qlist(gf) do
					if table.contains(suits, sgs.Sanguosha:getCard(id):getSuitString()) then
						table.removeOne(suits, sgs.Sanguosha:getCard(id):getSuitString())
					end
					if #suits == 0 then break end
				end
			end
			if #suits > 0 then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, kr:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		-- player is the skill owner (kongrong); ctx.invoker is the Start-phase player giving the card
		local invoker = ctx.invoker
		if not invoker or invoker:isKongcheng() then return false end
		local suits = {"spade", "heart", "club", "diamond"}
		local gf = player:getPile("gift")
		if not gf:isEmpty() then
			for _, id in sgs.qlist(gf) do
				if table.contains(suits, sgs.Sanguosha:getCard(id):getSuitString()) then
					table.removeOne(suits, sgs.Sanguosha:getCard(id):getSuitString())
				end
				if #suits == 0 then break end
			end
		end
		if #suits == 0 then return false end
		local _data = sgs.QVariant()
		_data:setValue(player)
		room:setPlayerFlag(player, "lirang_Target")
		local c = room:askForCard(invoker, ".|".. table.concat(suits, ",").."|.|hand", "@lirang_to:" .. player:objectName(), _data, sgs.Card_MethodNone)
		room:setPlayerFlag(player, "-lirang_Target")
		if not c then return false end
		ctx.extra_data:setValue(c:getEffectiveId())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		local c = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
		if not c then return false end
		room:broadcastSkillInvoke(skill:objectName(), 1)
		room:doAnimate(1, invoker:objectName(), player:objectName())
		player:addToPile("gift", c, true)
		invoker:drawCards(1)
		return false
	end,
}


sk_kongrong:addSkill(sk_lirang)


--贤士
sk_xianshi = sgs.CreateTriggerSkillV2{
	name = "sk_xianshi",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.damage > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local dmg = sgs.QVariant()
		dmg:setValue(damage.from)
		return player:askForSkillInvoke(skill:objectName(), dmg)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		if not damage.from then return false end
		room:doAnimate(1, player:objectName(), damage.from:objectName())
		if damage.from:isKongcheng() then
			room:broadcastSkillInvoke(skill:objectName(), 2)
			if damage.damage <= 1 then
				local msg = sgs.LogMessage()
				msg.type = "#XianshiProtect"
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				msg.from = player
				room:sendLog(msg)
				return true
			else
				local msg = sgs.LogMessage()
				msg.type = "#XianshiReduce"
				msg.arg = damage.damage
				msg.arg2 = damage.damage - 1
				msg.from = player
				room:sendLog(msg)
				damage.damage = damage.damage - 1
				data:setValue(damage)
			end
		else
			local _dmg = sgs.QVariant()
			_dmg:setValue(damage)
			local card = room:askForCard(damage.from, ".|.|.|hand", "@xianshi-discard:" .. player:objectName(), _dmg, sgs.Card_MethodNone)
			if card then
				room:broadcastSkillInvoke(skill:objectName(), 1)
				room:showAllCards(damage.from)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, damage.from:objectName(), skill:objectName(), "")
				room:throwCard(card, reason, nil)
			else
				room:broadcastSkillInvoke(skill:objectName(), 2)
				if damage.damage <= 1 then
					local msg = sgs.LogMessage()
					msg.type = "#XianshiProtect"
					msg.arg = damage.damage
					if damage.nature == sgs.DamageStruct_Fire then
						msg.arg2 = "fire_nature"
					elseif damage.nature == sgs.DamageStruct_Thunder then
						msg.arg2 = "thunder_nature"
					elseif damage.nature == sgs.DamageStruct_Normal then
						msg.arg2 = "normal_nature"
					end
					msg.from = player
					room:sendLog(msg)
					return true
				else
					local msg = sgs.LogMessage()
					msg.type = "#XianshiReduce"
					msg.arg = damage.damage
					msg.arg2 = damage.damage - 1
					msg.from = player
					room:sendLog(msg)
					damage.damage = damage.damage - 1
					data:setValue(damage)
				end
			end
		end
		return false
	end,
}


sk_kongrong:addSkill(sk_xianshi)


sgs.LoadTranslationTable{
	["sk_kongrong"] = "SK孔融",
	["&sk_kongrong"] = "孔融",
	["~sk_kongrong"] = "生存多所虑，长寝万事毕……",
	["#sk_kongrong"] = "凛然重义",
	["sk_lirang"] = "礼让",
	["gift"] = "礼",
	[":sk_lirang"] = "一名角色的准备阶段，其可以将一张手牌置于你的武将牌上（每种花色至多一张），称为“礼”，然后摸一张牌。你可以将两张“礼”当一张【桃】使用。",
	["$sk_lirang1"] = "谦者，德之柄也；让者，礼之主也。",
	["$sk_lirang2"] = "礼节铭心，让则不争。",
	["@lirang_to"] = "你可以将一张手牌作为“礼”置于%src的武将牌上，然后摸一张牌。",
	["sk_xianshi"] = "贤士",
	["@xianshi-discard"] = "请展示所有手牌并弃置一张牌，否则你对%src造成的伤害-1。",
	["#XianshiProtect"] = "%from 的“<font color=\"yellow\"><b>贤士</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	["#XianshiReduce"] = "%from 的“<font color=\"yellow\"><b>贤士</b></font>”效果被触发，受到的伤害从 %arg 点减少至 %arg2 点",
	[":sk_xianshi"] = "当你受到伤害时，你可以令伤害来源选择一项：1.展示所有手牌并弃置其中一张牌；2.此伤害-1。",
	["$sk_xianshi1"] = "汝不行仁义，天下之士共讥之！",
	["$sk_xianshi2"] = "人虽喻自觉，其何伤于日月乎？",
	["designer:sk_kongrong"] = "极略三国",
    ["illustrator:sk_kongrong"] = "极略三国",
    ["cv:sk_kongrong"] = "极略三国",
}


--周仓
sk_zhoucang = sgs.General(extension, "sk_zhoucang", "shu", 4, true)


--刀侍
sk_daoshi = sgs.CreateTriggerSkillV2{
	name = "sk_daoshi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Finish or player:getEquips():isEmpty() then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, zhoucang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(trigger_list_skill, skill:objectName())
			table.insert(trigger_list_who, zhoucang:objectName())
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		-- player is the skill owner (zhoucang); ctx.invoker is the Finish-phase player who decides
		local invoker = ctx.invoker
		if not invoker or invoker:getEquips():isEmpty() then return false end
		local _data = sgs.QVariant()
		_data:setValue(player)
		return invoker:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		room:broadcastSkillInvoke(skill:objectName())
		invoker:drawCards(1)
		if invoker:objectName() ~= player:objectName() then
			local eq = room:askForCardChosen(invoker, invoker, "e", skill:objectName())
			room:doAnimate(1, invoker:objectName(), player:objectName())
			local equip = sgs.Sanguosha:getCard(eq)
			player:obtainCard(equip)
		end
		return false
	end,
}


sk_zhoucang:addSkill(sk_daoshi)


sgs.LoadTranslationTable{
	["sk_zhoucang"] = "SK周仓",
	["&sk_zhoucang"] = "周仓",
	["~sk_zhoucang"] = "末将，这就随将军去……",
	["#sk_zhoucang"] = "披肝沥胆",
	["sk_daoshi"] = "刀侍",
	[":sk_daoshi"] = "一名角色的回合结束阶段，若其装备区有牌，其可以摸一张牌，然后将其装备区里的一张牌交给你。",
	["$sk_daoshi1"] = "末将，必誓死追随将军！",
	["$sk_daoshi2"] = "这刀，岂是末将配用的！",
	["designer:sk_zhoucang"] = "极略三国",
    ["illustrator:sk_zhoucang"] = "极略三国",
    ["cv:sk_zhoucang"] = "极略三国",
}


--潘凤
sk_panfeng = sgs.General(extension, "sk_panfeng", "qun", 4, true)


--狂斧
sk_kuangfu = sgs.CreateTriggerSkillV2{
	name = "sk_kuangfu",
	events = {sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)
			and damage.to and not damage.to:getEquips():isEmpty() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.to then return false end
		local _data = sgs.QVariant()
		_data:setValue(damage.to)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.to then return false end
		local eq = room:askForCardChosen(player, damage.to, "e", skill:objectName())
		room:doAnimate(1, player:objectName(), damage.to:objectName())
		local equip = sgs.Sanguosha:getCard(eq)
		player:obtainCard(equip)
		return false
	end,
}


sk_panfeng:addSkill(sk_kuangfu)


sgs.LoadTranslationTable{
	["sk_panfeng"] = "SK潘凤",
	["&sk_panfeng"] = "潘凤",
	["~sk_panfeng"] = "我的斧子呢？",
	["#sk_panfeng"] = "无双上将",
	["sk_kuangfu"] = "狂斧",
	[":sk_kuangfu"] = "当你使用【杀】对目标角色造成伤害后，你可以获得其装备区里的一张牌。",
	["$sk_kuangfu"] = "吾乃上将潘凤！",
	["designer:sk_panfeng"] = "极略三国",
    ["illustrator:sk_panfeng"] = "极略三国",
    ["cv:sk_panfeng"] = "极略三国",
}


--颜良
sk_yanliang = sgs.General(extension, "sk_yanliang", "qun", 4, true)


--虎步
sk_hubu = sgs.CreateTriggerSkillV2{
	name = "sk_hubu",
	events = {sgs.Damage, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not (damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)) then
			return false
		end
		if event == sgs.Damage then
			if damage.from and damage.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tos = sgs.SPlayerList()
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName(skill:objectName())
		duel:toTrick():setCancelable(false)
		for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
			if not sgs.Sanguosha:isProhibited(player, pe, duel) then tos:append(pe) end
		end
		if not tos:isEmpty() then
			local to = room:askForPlayerChosen(player, tos, skill:objectName(), "@hubu-target", true, true)
			if to then
				room:broadcastSkillInvoke(skill:objectName())
				local judge = sgs.JudgeStruct()
				judge.who = to
				judge.reason = skill:objectName()
				judge.pattern = ".|spade"
				judge.good = false
				judge.negative = true
				room:judge(judge)
				if judge:isGood() then room:useCard(sgs.CardUseStruct(duel, player, to), false) end
			end
		end
		duel:deleteLater()
		return false
	end,
}


sk_yanliang:addSkill(sk_hubu)


sgs.LoadTranslationTable{
	["sk_yanliang"] = "SK颜良",
	["&sk_yanliang"] = "颜良",
	["~sk_yanliang"] = "武运已尽啊……",
	["#sk_yanliang"] = "猛虎出栏",
	["sk_hubu"] = "虎步",
	[":sk_hubu"] = "当你使用【杀】造成伤害或受到【杀】造成的伤害后，你可令一名其他角色进行判定：若结果不为黑桃，你视为对其使用一张不能被【无懈可击】响应的【决"..
	"斗】。",
	["@hubu-target"] = "你可以发动“虎步”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["$sk_hubu"] = "来啊！你我，以武定胜负！",
	["designer:sk_yanliang"] = "极略三国",
    ["illustrator:sk_yanliang"] = "极略三国",
    ["cv:sk_yanliang"] = "极略三国",
}


--孙鲁育
sk_sunluyu = sgs.General(extension, "sk_sunluyu", "wu", 3, false)


--[[
	技能名：惠敛
	相关武将：SK孙鲁育
	技能描述：出牌阶段限一次，你可以令一名其他角色进行一次判定并获得生效后的判定牌。若结果为红桃，该角色回复1点体力。
	引用：sk_huilian
]]--
sk_huilianCard = sgs.CreateSkillCard{
	name = "sk_huilian",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
         if #targets == 0 then
		    return to_select:getSeat() ~= player:getSeat()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local judge = sgs.JudgeStruct()
		judge.who = targets[1]
		judge.reason = self:objectName()
		judge.play_animation = false
		judge.pattern = ".|heart"
		room:judge(judge)
		local card = judge.card
		targets[1]:obtainCard(card)
		if judge:isGood() then
			if targets[1]:isWounded() then
				local rec = sgs.RecoverStruct()
				rec.who = source
				room:recover(targets[1], rec, true)
			end
		end
	end
}

sk_huilian = sgs.CreateViewAsSkillV2{
	name = "sk_huilian",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_huilian") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_huilianCard:clone()
	end,
}


sk_sunluyu:addSkill(sk_huilian)


--[[
	技能名：温良
	相关武将：SK孙鲁育
	技能描述：一名角色的红色判定牌生效后，你可以摸一张牌。
	引用：sk_wenliang
]]--
sk_wenliang = sgs.CreateTriggerSkillV2{
	name = "sk_wenliang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local judge = data:toJudge()
		local card = judge.card
		if not card or room:getCardPlace(card:getEffectiveId()) ~= sgs.Player_PlaceJudge or not judge.card:isRed() then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, sunluyu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(trigger_list_skill, skill:objectName())
			table.insert(trigger_list_who, sunluyu:objectName())
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:notifySkillInvoked(player, "sk_wenliang")
		room:broadcastSkillInvoke("sk_wenliang", math.random(1, 2))
		player:drawCards(1)
		return false
	end,
}


sk_sunluyu:addSkill(sk_wenliang)


sgs.LoadTranslationTable{
	["sk_sunluyu"] = "SK孙鲁育",
	["&sk_sunluyu"] = "孙鲁育",
	["~sk_sunluyu"] = "大虎，你为何要如此陷害于我？",
	["#sk_sunluyu"] = "舍身饲虎",
	["sk_huilian"] = "惠敛",
	[":sk_huilian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色进行一次判定并获得生效后的判定牌。若结果为红桃，该角色回复1点体"..
	"力。",
	["$sk_huilian"] = "到我怀里来。",
	["sk_wenliang"] = "温良",
	[":sk_wenliang"] = "一名角色的红色判定牌生效后，你可以摸一张牌。",
	["$sk_wenliang1"] = "别担心，此事还有转还余地。",
	["$sk_wenliang2"] = "总有办法的。",
	["designer:sk_sunluyu"] = "极略三国",
    ["illustrator:sk_sunluyu"] = "极略三国",
    ["cv:sk_sunluyu"] = "极略三国",
}


--王平
sk_wangping = sgs.General(extension, "sk_wangping", "shu", 4, true)


--[[
	技能名：义谏
	相关武将：SK王平
	技能描述：你可以跳过你的出牌阶段并令一名其他角色摸一张牌，然后若该角色的手牌数不小于你的手牌数，你回复1点体力。
	引用：sk_yijian
]]--
sk_yijian = sgs.CreateTriggerSkillV2{
	name = "sk_yijian",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play and not player:isSkipped(change.to) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@yijian-target", true, true)
		if to then
			ctx.targets:append(to)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, to)
		room:broadcastSkillInvoke(skill:objectName())
		to:drawCards(1)
		if to:getHandcardNum() >= player:getHandcardNum() then
			if player:isWounded() then
				local rec = sgs.RecoverStruct()
				rec.who = player
				room:recover(player, rec, true)
			end
		end
		player:skip(sgs.Player_Play)
		return false
	end,
}


sk_wangping:addSkill(sk_yijian)


--[[
	技能名：飞军
	相关武将：SK王平
	技能描述：锁定技，出牌阶段开始时，若你的手牌数不小于你的体力值，本阶段你的攻击范围+X且可以额外使用一张【杀】（X为你的体力值）；若你的手牌数小于你的体力值，
	你不能使用【杀】直到回合结束。
	引用：sk_feijun
]]--
sk_feijun = sgs.CreateTriggerSkillV2{
	name = "sk_feijun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then return skill:objectName() end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getHandcardNum() >= player:getHp() then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:notifySkillInvoked(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), 1)
				room:setPlayerMark(player, "feijun_exrange", player:getHp())
			else
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:notifySkillInvoked(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), 2)
				room:setPlayerCardLimitation(player, "use", "Slash", true)
			end
		elseif event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "feijun_exrange", 0)
		end
		return false
	end,
}

sk_feijunexrange = sgs.CreateAttackRangeSkillV2{
	name = "#sk_feijunexrange",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:hasSkill("sk_feijun") and player:getMark("feijun_exrange") > 0 then
			return player:getMark("feijun_exrange")
		end
		return false
	end
}

sk_feijunexslash = sgs.CreateTargetModSkillV2{
    name = "#sk_feijunexslash",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
	    if player and ctx:getModType() == sgs.TargetModSkill_Residue
			and player:hasSkill("sk_feijun") and player:getMark("feijun_exrange") > 0 then
		    return 1
		end
		return false
	end
}


extension:insertRelatedSkills("sk_feijun", "#sk_feijunexrange")
extension:insertRelatedSkills("sk_feijun", "#sk_feijunexslash")
sk_wangping:addSkill(sk_feijun)
sk_wangping:addSkill(sk_feijunexrange)
sk_wangping:addSkill(sk_feijunexslash)


sgs.LoadTranslationTable{
	["sk_wangping"] = "SK王平",
	["&sk_wangping"] = "王平",
	["~sk_wangping"] = "蜀之精锐，怎能葬身于此！",
	["#sk_wangping"] = "无当飞将",
	["sk_yijian"] = "义谏",
	[":sk_yijian"] = "你可以跳过你的出牌阶段并令一名其他角色摸一张牌，然后若该角色的手牌数不小于你的手牌数，你回复1点体力。",
	["@yijian-target"] = "你可以发动“义谏”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["$sk_yijian"] = "主帅，这有违丞相之令。",
	["sk_feijun"] = "飞军",
	[":sk_feijun"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段开始时，若你的手牌数不小于你的体力值，本阶段你的攻击范围+X且可以额外使用一张【杀】"..
	"（X为你的体力值）；若你的手牌数小于你的体力值，你不能使用【杀】直到回合结束。",
	["$sk_feijun1"] = "跟上！翻过此山，直取敌营！",
	["$sk_feijun2"] = "不可轻敌，视机而战！",
	["designer:sk_wangping"] = "极略三国",
    ["illustrator:sk_wangping"] = "极略三国",
    ["cv:sk_wangping"] = "极略三国",
}


--李严
sk_liyan = sgs.General(extension, "sk_liyan", "shu", 4, true)


--[[
	技能名：延粮
	相关武将：SK李严
	技能描述：一名角色的准备阶段，你可以弃置一张红色牌，令其本回合的摸牌阶段于出牌阶段后进行；或弃置一张黑色牌，令其本回合的摸牌阶段于弃牌阶段后进行。
	引用：sk_yyanliang
]]--
sk_yyanliang = sgs.CreateTriggerSkillV2{
	name = "sk_yyanliang",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return false end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, liyan in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if liyan and liyan:isAlive() and not liyan:isNude() then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, liyan:objectName())
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		elseif event == sgs.EventPhaseChanging then
			if not (player:hasFlag("afterplay") or player:hasFlag("afterdiscard")) then return false end
			local change = data:toPhaseChange()
			local to = change.to
			if to == sgs.Player_Draw
				or (player:hasFlag("afterplay") and to == sgs.Player_Discard and not player:hasFlag("SupplyShortaged"))
				or (player:hasFlag("afterdiscard") and to == sgs.Player_Finish and not player:hasFlag("SupplyShortaged")) then
				local liyan = room:findPlayersBySkillName(skill:objectName()):at(0)
				if liyan then return skill:objectName(), liyan:objectName() end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local invoker = ctx.invoker
			local _data = sgs.QVariant()
			_data:setValue(invoker)
			local card = room:askForCard(player, ".|.|.|.", "@yanliang_card:"..invoker:objectName(), _data, sgs.Card_MethodNone)
			if card then
				ctx.extra_data:setValue(card:getEffectiveId())
				return true
			end
			return false
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local target = ctx.invoker
			local card = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
			room:throwCard(card, reason, nil)
			room:doAnimate(1, player:objectName(), target:objectName())
			if card:isRed() then
				room:broadcastSkillInvoke(skill:objectName(), 1)
				room:setPlayerFlag(target, "afterplay")
			elseif card:isBlack() then
				room:broadcastSkillInvoke(skill:objectName(), 2)
				room:setPlayerFlag(target, "afterdiscard")
			end
		else
			local target = ctx.invoker
			local change = ctx.original_data:toPhaseChange()
			local to = change.to
			if to == sgs.Player_Draw then
				if not target:isSkipped(to) then
					target:skip(to)
				else
					room:setPlayerFlag(target, "SupplyShortaged")
				end
			elseif (target:hasFlag("afterplay") and to == sgs.Player_Discard and not target:hasFlag("SupplyShortaged")) then
				room:setPlayerFlag(target, "-afterplay")
				change.to = sgs.Player_Draw
				ctx.original_data:setValue(change)
				target:insertPhase(sgs.Player_Draw)
			elseif (target:hasFlag("afterdiscard") and to == sgs.Player_Finish and not target:hasFlag("SupplyShortaged")) then
				room:setPlayerFlag(target, "-afterdiscard")
				change.to = sgs.Player_Draw
				ctx.original_data:setValue(change)
				target:insertPhase(sgs.Player_Draw)
			end
		end
		return false
	end,
}


sk_liyan:addSkill(sk_yyanliang)


sgs.LoadTranslationTable{
	["sk_liyan"] = "SK李严",
	["&sk_liyan"] = "李严",
	["~sk_liyan"] = "此生怕是复官无望啊……",
	["#sk_liyan"] = "性自矜高",
	["sk_yyanliang"] = "延粮",
	[":sk_yyanliang"] = "一名角色的准备阶段，你可以弃置一张红色牌，令其本回合的摸牌阶段于出牌阶段后进行；或弃置一张黑色牌，令其本回合的摸牌阶段于弃牌阶段后进行。",
	["@yanliang_card"] = "你可以弃置一张红色牌，令%src的摸牌阶段于出牌阶段之后进行；或弃置一张黑色牌，令%src的摸牌阶段于弃牌阶段之后进行",
	["$sk_yyanliang1"] = "军粮充足，为何急于撤兵？",
	["$sk_yyanliang2"] = "军粮延误，皆因近日绵雨。",
	["designer:sk_liyan"] = "极略三国",
    ["illustrator:sk_liyan"] = "极略三国",
    ["cv:sk_liyan"] = "极略三国",
}


--杨修
sk_yangxiu = sgs.General(extension, "sk_yangxiu", "wei", 3, true)


--[[
	技能名：才捷
	相关武将：SK杨修
	技能描述：其他角色的准备阶段，若其手牌数不小于你，你可以与其拼点，若你赢，你摸两张牌；若你没赢，视为其对你使用一张【杀】。
	引用：sk_caijie
]]--
sk_caijie = sgs.CreateTriggerSkillV2{
	name = "sk_caijie",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and (not player:isKongcheng()) and player:getPhase() == sgs.Player_Start) then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, yangxiu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if player:getSeat() ~= yangxiu:getSeat() and player:getHandcardNum() >= yangxiu:getHandcardNum() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, yangxiu:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local _data = sgs.QVariant()
		_data:setValue(ctx.invoker)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(target, skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		local yangxiuwin = player:pindian(target, skill:objectName(), nil)
		if yangxiuwin then
			player:drawCards(2, skill:objectName())
		else
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("caijie_slash")
			local use = sgs.CardUseStruct()
			use.from = target
			use.to:append(player)
			use.card = slash
			room:useCard(use, false)
			slash:deleteLater()
		end
		return false
	end,
}


sk_yangxiu:addSkill(sk_caijie)


--[[
	技能名：鸡肋
	相关武将：SK杨修
	技能描述：当你受到伤害后，你可以令伤害来源展示所有手牌并弃置其中类别相同且数量最多（或之一）的所有牌。
	引用：sk_jilei
]]--
function doSKjilei(yangxiu, from, reason)
	local room = sgs.Sanguosha:currentRoom()
	room:showAllCards(from)
	local basic_num = 0
	local trick_num = 0
	local equip_num = 0
	for _, c in sgs.qlist(from:getHandcards()) do
		if c:isKindOf("BasicCard") then
			basic_num = basic_num + 1
		elseif c:isKindOf("TrickCard") then
			trick_num = trick_num + 1
		elseif c:isKindOf("EquipCard") then
			equip_num = equip_num + 1
		end
	end
	local num = {basic_num, trick_num, equip_num}
	local _max = -2
	for i = 1, #num do
		_max = math.max(_max, num[i])
	end
	local ids = sgs.IntList()
	if basic_num >= _max then
		for _, card in sgs.qlist(from:getHandcards()) do
			if card:isKindOf("BasicCard") then ids:append(card:getEffectiveId()) end
		end
	end
	if trick_num >= _max then
		for _, card in sgs.qlist(from:getHandcards()) do
			if card:isKindOf("TrickCard") then ids:append(card:getEffectiveId()) end
		end
	end
	if equip_num >= _max then
		for _, card in sgs.qlist(from:getHandcards()) do
			if card:isKindOf("EquipCard") then ids:append(card:getEffectiveId()) end
		end
	end
	room:fillAG(ids, yangxiu)
	local id = room:askForAG(yangxiu, ids, false, reason)
	local acard = sgs.Sanguosha:getCard(id)
	local jilei_type = -1
	if acard:isKindOf("BasicCard") then
		jilei_type = "BasicCard"
	elseif acard:isKindOf("TrickCard") then
		jilei_type = "TrickCard"
	elseif acard:isKindOf("EquipCard") then
		jilei_type = "EquipCard"
	end
	room:clearAG()
	local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
	for _, cid in sgs.qlist(ids) do
		if sgs.Sanguosha:getCard(cid):isKindOf(jilei_type) then jink:addSubcard(cid) end
	end
	jink:deleteLater()
	if jink:subcardsLength() > 0 then
		local r = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, yangxiu:objectName(), reason, "")
		room:throwCard(jink, r, nil)
	end
end

sk_jilei = sgs.CreateTriggerSkillV2{
	name = "sk_jilei",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not damage.from or damage.from:isKongcheng() then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local _data = sgs.QVariant()
		_data:setValue(damage.from)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		room:doAnimate(1, player:objectName(), damage.from:objectName())
		doSKjilei(player, damage.from, skill:objectName())
		return false
	end,
}


sk_yangxiu:addSkill(sk_jilei)


sgs.LoadTranslationTable{
	["sk_yangxiu"] = "SK杨修",
	["&sk_yangxiu"] = "杨修",
	["~sk_yangxiu"] = "我固自以死之晚也……",
	["#sk_yangxiu"] = "恃才放旷",
	["sk_caijie"] = "才捷",
	["caijie_slash"] = "才捷",
	[":sk_caijie"] = "其他角色的准备阶段，若其手牌数不小于你，你可以与其拼点。若你赢，你摸两张牌；若你没赢，该角色视为对你使用一张无距离限制的【杀】。",
	["$sk_caijie"] = "吾才捷遍悟，孰谁能及？",
	["sk_jilei"] = "鸡肋",
	[":sk_jilei"] = "当你受到伤害后，你可以令伤害来源展示所有手牌并弃置其中数量最多的一种类别的手牌。",
	["$sk_jilei"] = "食之无味，弃之可惜。",
	["designer:sk_yangxiu"] = "极略三国",
    ["illustrator:sk_yangxiu"] = "极略三国",
    ["cv:sk_yangxiu"] = "极略三国",
}


--于禁
sk_yujin = sgs.General(extension, "sk_yujin", "wei", 4, true)


--[[
	技能名：整毅
	相关武将：SK于禁
	技能描述：当你于回合内/外需要使用一张基本牌时，若X为0且你装备区有牌或X为1/X为-1（X为你的手牌数减体力值），你可以弃置一张牌/摸一张牌，然后你视为使用之。
	引用：sk_zhengyi
]]--
local can_zhengyi = function(player)
	if player:getPhase() == sgs.Player_NotActive then
		if player:getHp() - player:getHandcardNum() == 1 then return true end
	else
		if player:getHandcardNum() - player:getHp() == 1 then return true end
		if player:getHandcardNum() == player:getHp() and (not player:getEquips():isEmpty()) then return true end
	end
	return false
end

sk_zhengyiCard = sgs.CreateSkillCard{
	name = "sk_zhengyi",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and player:getWeapon() and player:getWeapon():getId() == self:getSubcards():first() then
			local card = player:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - player:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and player:getOffensiveHorse() and player:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and player:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = player:getTag("sk_zhengyi"):toCard()
		return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and player:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("sk_zhengyi"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, player)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = player:getTag("sk_zhengyi"):toCard()
		return card and card:targetsFeasible(plist, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, zhengyi_basic = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local sk_zhengyi_list = {}
			table.insert(sk_zhengyi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_zhengyi_list, "normal_slash")
				table.insert(sk_zhengyi_list, "thunder_slash")
				table.insert(sk_zhengyi_list, "fire_slash")
			end
			zhengyi_basic = room:askForChoice(player, "sk_zhengyi_slash", table.concat(sk_zhengyi_list, "+"))
		end
		local card = sgs.Sanguosha:cloneCard(zhengyi_basic, sgs.Card_NoSuit, 0)
		local user_str
		if zhengyi_basic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif zhengyi_basic == "normal_slash" then
			user_str = "slash"
		else
			user_str = zhengyi_basic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		use_card:setSkillName("sk_zhengyi")
		use_card:deleteLater()
		if player:getPhase() ~= sgs.Player_NotActive then
			local acard = -1
			if player:getHandcardNum() - player:getHp() == 1 then
				acard = room:askForExchange(player, "sk_zhengyi", 1, 1, false, "@zhengyi-hand:"..use_card:objectName(), false)
			else
				if player:getHandcardNum() == player:getHp() and player:getEquips():length() > 0 then
					acard = room:askForExchange(player, "sk_zhengyi", 1, 1, true, "@zhengyi-equip:"..use_card:objectName(), false, ".|.|.|equipped|.")
				end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sk_zhengyi","")
			room:throwCard(acard, reason, nil)
		end
		return use_card
	end,
	on_validate_in_response = function(self, user)  --不能通过此技能打出【杀】，response只能给桃
		local room = user:getRoom()
		local zhengyi_basic = -1
		if self:getUserString() == "slash" then
			local sk_zhengyi_list = {}
			table.insert(sk_zhengyi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_zhengyi_list, "normal_slash")
				table.insert(sk_zhengyi_list, "thunder_slash")
				table.insert(sk_zhengyi_list, "fire_slash")
			end
			zhengyi_basic = room:askForChoice(user, "sk_zhengyi_slash", table.concat(sk_zhengyi_list, "+"))
		else
			zhengyi_basic = self:getUserString()
		end
		local card = sgs.Sanguosha:cloneCard(zhengyi_basic, sgs.Card_NoSuit, 0)
		local user_str
		if zhengyi_basic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif zhengyi_basic == "normal_slash" then
			user_str = "slash"
		else
			user_str = zhengyi_basic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		use_card:setSkillName("sk_zhengyi")
		use_card:deleteLater()
		if user:getPhase() ~= sgs.Player_NotActive then
			local acard = -1
			if user:getHandcardNum() - user:getHp() == 1 then
				acard = room:askForExchange(user, "sk_zhengyi", 1, 1, false, "@zhengyi-hand:"..use_card:objectName(), false)
			else
				if user:getHandcardNum() == user:getHp() and user:getEquips():length() > 0 then
					acard = room:askForExchange(user, "sk_zhengyi", 1, 1, true, "@zhengyi-equip:"..use_card:objectName(), false, ".|.|.|equipped|.")
				end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, user:objectName(), "sk_zhengyi","")
			room:throwCard(acard, reason, nil)
		end
		return use_card
	end
}

sk_zhengyiVS = sgs.CreateViewAsSkillV2{
	name = "sk_zhengyi",
	n = 0,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if can_zhengyi(player) then
				local basic = {"slash", "peach"}
				if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
					table.insert(basic, "thunder_slash")
					table.insert(basic, "fire_slash")
					table.insert(basic, "analeptic")
				end
				for _, patt in ipairs(basic) do
					local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
					if poi and poi:isAvailable(player) and not(patt == "peach" and not player:isWounded()) then
						return true
					end
				end
			end
			return false
		end
		local pattern = request:getPattern()
		if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		return pattern ~= "nullification" and can_zhengyi(player)
			and reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local reason = request:getReason()
		if player:getPhase() == sgs.Player_NotActive then
			local skillcard = sk_zhengyiCard:clone()
			skillcard:setSkillName(skill:objectName())
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				skillcard:setUserString(request:getPattern())
				return skillcard
			end
			local c = player:getTag("sk_zhengyi"):toCard()
			if c then
				skillcard:setUserString(c:objectName())
				return skillcard
			else
				return nil
			end
		else
			local skillcard = sk_zhengyiCard:clone()
			skillcard:setSkillName(skill:objectName())
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				skillcard:setUserString(request:getPattern())
				return skillcard
			end
			local c = player:getTag("sk_zhengyi"):toCard()
			if c then
				skillcard:setUserString(c:objectName())
				return skillcard
			else
				return nil
			end
		end
	end,
}

sk_zhengyi = sgs.CreateTriggerSkillV2{
	name = "sk_zhengyi",
	view_as_skill = sk_zhengyiVS,
	guhuo_type = "l",
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card and table.contains(card:getSkillNames(), "sk_zhengyi") and player:getHp() - player:getHandcardNum() == 1 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(1, skill:objectName())
		return false
	end,
}
sk_yujin:addSkill(sk_zhengyi)


sgs.LoadTranslationTable{
	["sk_yujin"] = "SK于禁",
	["&sk_yujin"] = "于禁",
	["~sk_yujin"] = "同归于尽吧！",
	["#sk_yujin"] = "弗克其终",
	["sk_zhengyi"] = "整毅",
	[":sk_zhengyi"] = "当你于回合内/外需要使用一张基本牌时，若X为0且你装备区有牌或X为1/X为-1（X为你的手牌数减体力值），你可以弃置一张牌/摸一张牌，"..
	"然后你视为使用之。",
	["@zhengyi-hand"] = "请弃置一张手牌，视为你使用了一张【%src】。",
	["@zhengyi-equip"] = "请弃置一张装备区内的牌，视为你使用了一张【%src】。",
	["$sk_zhengyi1"] = "厉兵秣马，枕戈待敌。",
	["$sk_zhengyi2"] = "兵刃相接，汝当片甲不留！",
	["designer:sk_yujin"] = "极略三国",
    ["illustrator:sk_yujin"] = "极略三国",
    ["cv:sk_yujin"] = "极略三国",
}


--吕玲绮
sk_lvlingqi = sgs.General(extension, "sk_lvlingqi", "qun", 4, false)


--[[
	技能名：戟舞
	相关武将：SK吕玲绮
	技能描述：出牌阶段开始时，你可以展示一张【杀】，然后令此牌获得以下一个效果直到此牌进入弃牌堆：
	1.不计入次数；2.无距离限制且目标上限+1；3.伤害+1。
	引用：sk_jiwu
]]--
function getMyCardsNum(my, name)
	local x = 0
	for _, c in sgs.qlist(my:getHandcards()) do
		if c:isKindOf(name) then
			x = x + 1
		end
	end
	return x
end

sk_jiwuCard = sgs.CreateSkillCard{
	name = "sk_jiwu",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		local source = use.from
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local flags = {"llq_jiwu_residue", "llq_jiwu_ex", "llq_jiwu_damage"}
		for _, flag in ipairs(flags) do
			if card:hasFlag(flag) then table.removeOne(flags, flag) end
		end
		local tobuff = room:askForChoice(source, "sk_jiwu", table.concat(flags, "+"))
		room:setCardTip(id,"sk_jiwu")
		local msg = sgs.LogMessage()
		msg.from = source
		msg.type = "#JiwuSelect"
		msg.arg = tobuff
		if tobuff == "llq_jiwu_residue" then
			local skmsg = sgs.LogMessage()
			skmsg.type = "#InvokeSkill"
			skmsg.from = source
			skmsg.arg = "sk_jiwu"
			room:sendLog(skmsg)
			room:notifySkillInvoked(source, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:showCard(source, id)
			room:sendLog(msg)
			room:setCardFlag(card, tobuff)
		elseif tobuff == "llq_jiwu_ex" then
			local skmsg = sgs.LogMessage()
			skmsg.type = "#InvokeSkill"
			skmsg.from = source
			skmsg.arg = "sk_jiwu"
			room:sendLog(skmsg)
			room:notifySkillInvoked(source, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:showCard(source, id)
			room:sendLog(msg)
			room:setCardFlag(card, tobuff)
		elseif tobuff == "llq_jiwu_damage" then
			local skmsg = sgs.LogMessage()
			skmsg.type = "#InvokeSkill"
			skmsg.from = source
			skmsg.arg = "sk_jiwu"
			room:sendLog(skmsg)
			room:notifySkillInvoked(source, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:showCard(source, id)
			room:sendLog(msg)
			room:setCardFlag(card, tobuff)
		end
	end
}

sk_jiwuVS = sgs.CreateViewAsSkillV2{
	name = "sk_jiwu",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		return request:getPattern() == "@@sk_jiwu"
	end,
	can_select_card = function(skill, request, to_select)
		if to_select and to_select:isKindOf("Slash") then
			return not (to_select:hasFlag("llq_jiwu_residue") and to_select:hasFlag("llq_jiwu_ex") and to_select:hasFlag("llq_jiwu_damage"))
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local jiwu = sk_jiwuCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			jiwu:addSubcard(id)
		end
		jiwu:setSkillName(skill:objectName())
		return jiwu
	end,
}

sk_jiwu = sgs.CreateTriggerSkillV2{
	name = "sk_jiwu",
	events = {sgs.EventPhaseStart},
	view_as_skill = sk_jiwuVS,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Play then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@sk_jiwu", "@jiwu_slashshow") ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		return false
	end,
}


sk_lvlingqi:addSkill(sk_jiwu)


sgs.LoadTranslationTable{
	["sk_lvlingqi"] = "SK吕玲绮",
	["&sk_lvlingqi"] = "吕玲绮",
	["~sk_lvlingqi"] = "父亲，我来得还是太迟……",
	["#sk_lvlingqi"] = "无双女杰",
	["sk_jiwu"] = "戟舞",
	[":sk_jiwu"] = "出牌阶段开始时，你可以展示一张【杀】，然后令此牌获得以下一个效果直到此牌进入弃牌堆："..
	"\n1.不计入次数；"..
	"\n2.无距离限制且目标上限+1；"..
	"\n3.伤害+1。",
	["$sk_jiwu1"] = "这无双的血脉，由我继承！",
	["$sk_jiwu2"] = "哼，你们能逃得出去吗？！",
	["$sk_jiwu3"] = "接招吧！",
	["llq_jiwu_residue"] = "此【杀】不计入次数",
	["llq_jiwu_ex"] = "此【杀】无距离限制且目标上限+1",
	["llq_jiwu_damage"] = "此【杀】伤害+1",
	["#JiwuSelect"] = "%from 选择了“%arg”",
	["@jiwu_slashshow"] = "你可以发动“戟舞”",
	["~sk_jiwu"] = "选择一张【戟舞】效果未满的【杀】→点击“确定”",
	["designer:sk_lvlingqi"] = "极略三国",
    ["illustrator:sk_lvlingqi"] = "极略三国",
    ["cv:sk_lvlingqi"] = "极略三国",
}


--王异
sk_wangyi = sgs.General(extension, "sk_wangyi", "wei", 3, false)


--[[
	技能名：贞烈
	相关武将：SK王异
	技能描述：当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以失去1点体力，令此牌对你无效；然后你可以弃置一张牌，令使用者选择一项：1.展示所有手牌，并弃置其中与弃置牌花色相同的牌；2.失去1点体力。
	引用：sk_zhenlie
]]--
sk_zhenlie = sgs.CreateTriggerSkillV2{
	name = "sk_zhenlie",
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.from and use.from:getSeat() ~= player:getSeat() and use.to:contains(player)
			and use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:broadcastSkillInvoke(skill:objectName())
		room:loseHp(player, 1, true, player, skill:objectName())
		local nullified_list = use.nullified_list
		table.insert(nullified_list, player:objectName())
		use.nullified_list = nullified_list
		ctx.original_data:setValue(use)
		local _data = sgs.QVariant()
		_data:setValue(use.from)
		local card = room:askForCard(player, ".|red,black", "@zhenlie-discard:" .. use.from:objectName(), _data, sgs.Card_MethodNone)
		if not card then return false end
		room:doAnimate(1, player:objectName(), use.from:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
		room:throwCard(card, reason, nil)
		if use.from:isKongcheng() then
			room:loseHp(use.from, 1, true, player, skill:objectName())
		else
			local suit = card:getSuit()
			local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			for _, acard in sgs.qlist(use.from:getHandcards()) do
				if acard:getSuit() == suit then dummy:addSubcard(acard) end
			end
			dummy:deleteLater()
			if dummy:getSubcards():isEmpty() then
				room:loseHp(use.from, 1, true, player, skill:objectName())
			else
				local choice = room:askForChoice(use.from, skill:objectName(), "throwallsuitcards+lose1hp")
				if choice == "throwallsuitcards" then
					room:showAllCards(use.from)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), skill:objectName(), "")
					room:throwCard(dummy, reason, nil)
				else
					room:loseHp(use.from, 1, true, player, skill:objectName())
				end
			end
		end
		return false
	end,
}


sk_wangyi:addSkill(sk_zhenlie)


--[[
	技能名：秘计
	相关武将：SK王异
	技能描述：准备阶段，若你已受伤，你可以选择一种类别，然后随机展示牌堆中的一张该类别的牌，令一名角色获得之。结束阶段，若你的体力值为场上最少，你也可以如此做。
	引用：sk_miji
]]--
function getOneTypeIds(type_str)
	local onetypeids = sgs.IntList()
	local room = sgs.Sanguosha:currentRoom()
	for _, id in sgs.qlist(room:getDrawPile()) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf(type_str) then onetypeids:append(id) end
	end
	return onetypeids
end

function canmiji()
	local basic = getOneTypeIds("BasicCard")
	local equip = getOneTypeIds("EquipCard")
	local trick = getOneTypeIds("TrickCard")
	return basic:length() > 0 or equip:length() > 0 or trick:length() > 0
end

sk_miji = sgs.CreateTriggerSkillV2{
	name = "sk_miji",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if not canmiji() then return false end
		if player:getPhase() == sgs.Player_Start then
			if player:isWounded() then return skill:objectName() end
		elseif player:getPhase() == sgs.Player_Finish then
			local _min = 2000
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				_min = math.min(_min, pe:getHp())
			end
			if player:getHp() <= _min then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local miji = {"BasicCard", "TrickCard", "EquipCard"}
		for _, _type in ipairs(miji) do
			if getOneTypeIds(_type):isEmpty() then table.removeOne(miji, _type) end
		end
		local choice = room:askForChoice(player, skill:objectName(), table.concat(miji, "+"))
		local miji_ids = sgs.QList2Table(getOneTypeIds(choice))
		local _id = miji_ids[math.random(1, #miji_ids)]
		local move = sgs.CardsMoveStruct()
		move.card_ids:append(_id)
		move.to = player
	    move.to_place = sgs.Player_PlaceTable
	    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), skill:objectName(), nil)
	    room:moveCardsAtomic(move, true)
		local to = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@miji-target", false, false)
		room:doAnimate(1, player:objectName(), to:objectName())
		local card = sgs.Sanguosha:getCard(_id)
		to:obtainCard(card)
		return false
	end,
}


sk_wangyi:addSkill(sk_miji)


sgs.LoadTranslationTable{
	["sk_wangyi"] = "SK王异",
	["&sk_wangyi"] = "王异",
	["~sk_wangyi"] = "我，绝不屈服！",
	["#sk_wangyi"] = "决意巾帼",
	["sk_zhenlie"] = "贞烈",
	[":sk_zhenlie"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以失去1点体力，令此牌对你无效；然后你可以弃置一张牌，令使用者选择一项："..
	"1.展示所有手牌，并弃置其中与弃置牌花色相同的牌；2.失去1点体力。",
	["$sk_zhenlie"] = "看看我的觉悟吧！",
	["@zhenlie-discard"] = "你可以弃置一张牌，令%src选择一项：展示所有手牌并弃置其中与之花色相同的牌，或失去1点体力",
	["throwallsuitcards"] = "弃置全部与之花色相同的手牌",
	["lose1hp"] = "失去1点体力",
	["sk_miji"] = "秘计",
	[":sk_miji"] = "准备阶段，若你已受伤，你可以选择一种类别，然后随机展示牌堆中的一张该类别的牌，令一名角色获得之。结束阶段，若你的体力值为场上最少，"..
	"你也可以如此做。",
	["@miji-target"] = "请将这张牌交给一名角色。<br/> <b>操作提示</b>: 选择包括自己在内的一名角色→点击确定<br/>",
	["$sk_miji"] = "我将尽我所能。",
	["designer:sk_wangyi"] = "极略三国",
    ["illustrator:sk_wangyi"] = "极略三国",
    ["cv:sk_wangyi"] = "极略三国",
}


--张宝
sk_zhangbao = sgs.General(extension, "sk_zhangbao", "qun", 3, true)


--[[
	技能名：咒缚
	相关武将：SK张宝
	技能描述：其他角色的回合开始时，你可以弃置一张手牌，令该角色判定。若判定结果为黑桃，此回合内，该角色所有技能失效；若为梅花，其弃置两张牌。
	引用：sk_zhoufu
]]--
function forbidAllSkill(player, reason)
	local room = player:getRoom()
	room:addPlayerMark(player, reason.."ForbidSkill")
	for _, skill in sgs.qlist(player:getVisibleSkillList()) do
		room:addPlayerMark(player, "Qingcheng"..skill:objectName())
	end
end

function openAllSkill(player, reason)
	local room = player:getRoom()
	room:setPlayerMark(player, reason.."ForbidSkill", 0)
	for _, skill in sgs.qlist(player:getVisibleSkillList()) do
		room:setPlayerMark(player, "Qingcheng"..skill:objectName(), 0)
	end
end


sk_zhoufu = sgs.CreateTriggerSkillV2{
	name = "sk_zhoufu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if player:getPhase() == sgs.Player_Start then
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, zhangbao in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if zhangbao:canDiscard(zhangbao, "h") and player:getSeat() ~= zhangbao:getSeat() then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, zhangbao:objectName())
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:getMark(skill:objectName().."ForbidSkill") > 0 then
				local zhangbao = room:findPlayersBySkillName(skill:objectName()):at(0)
				if zhangbao then return skill:objectName(), zhangbao:objectName() end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if target:getPhase() == sgs.Player_Start then
			local card = room:askForCard(player, ".|.|.|hand", "@zhoufu:" .. target:objectName(), ctx.original_data, skill:objectName())
			if card then
				ctx.extra_data:setValue(card:getEffectiveId())
				return true
			end
			return false
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if target:getPhase() == sgs.Player_Start then
			local card = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
			room:throwCard(card, reason, nil)
			room:broadcastSkillInvoke(skill:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			local judge = sgs.JudgeStruct()
			judge.who = target
			judge.reason = skill:objectName()
			judge.pattern = ".|black"
			judge.good = true
			judge.negative = true
			room:judge(judge)
			if judge:isGood() then
				if judge.card:getSuit() == sgs.Card_Spade then
					forbidAllSkill(target, skill:objectName())
					room:addPlayerMark(target, "&sk_zhoufu+to+#"..player:objectName().."-Clear")
				elseif judge.card:getSuit() == sgs.Card_Club then
					room:askForDiscard(target, skill:objectName(), 2, 2, false, true)
				end
			end
		elseif target:getPhase() == sgs.Player_Finish then
			if target:getMark(skill:objectName().."ForbidSkill") > 0 then openAllSkill(target, skill:objectName()) end
		end
		return false
	end,
}


sk_zhangbao:addSkill(sk_zhoufu)


--[[
	技能名：影兵
	相关武将：SK张宝
	技能描述：每回合限一次，当一名角色的黑色判定牌生效后，你可以视为对其使用一张无距离限制的【杀】。
	引用：sk_yingbing
]]--
sk_yingbing = sgs.CreateTriggerSkillV2{
	name = "sk_yingbing",
	events = {sgs.FinishJudge, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			for _, zhangbao in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if judge.who and judge.card and judge.card:isBlack() then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(skill:objectName())
					if not sgs.Sanguosha:isProhibited(zhangbao, player, slash) and zhangbao:getMark("yingbing_currentturn") <= 0 then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, zhangbao:objectName())
					end
					slash:deleteLater()
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, zhangbao in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if zhangbao:getMark("yingbing_currentturn") > 0 then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, zhangbao:objectName())
					end
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			local _data = sgs.QVariant()
			_data:setValue(judge.who)
			return player:askForSkillInvoke(skill:objectName(), _data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(skill:objectName())
			room:addPlayerMark(player, "yingbing_currentturn")
			local use = sgs.CardUseStruct()
			use.from = ctx.invoker
			use.to:append(judge.who)
			use.card = slash
			room:useCard(use, false)
			slash:deleteLater()
		elseif event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "yingbing_currentturn", 0)
		end
		return false
	end,
}


sk_zhangbao:addSkill(sk_yingbing)


sgs.LoadTranslationTable{
	["sk_zhangbao"] = "SK张宝",
	["&sk_zhangbao"] = "张宝",
	["~sk_zhangbao"] = "黄天！黄天",
	["#sk_zhangbao"] = "地公将军",
	["sk_zhoufu"] = "咒缚",
	[":sk_zhoufu"] = "其他角色的回合开始时，你可以弃置一张手牌，令该角色判定。若判定结果为：黑桃，此回合内，该角色所有技能失效；梅花，其弃置两张牌。",
	["$sk_zhoufu1"] = "孰死孰活，全听我令！",
	["$sk_zhoufu2"] = "咒缚缠身，尔待何如！",
	["@zhoufu"] = "你可以弃置一张手牌对%src发动【咒缚】",
	["sk_yingbing"] = "影兵",
	[":sk_yingbing"] = "每回合限一次，当一名角色的黑色判定牌生效后，你可以视为对其使用一张无距离限制的【杀】。",
	["$sk_yingbing1"] = "幻影成兵，助我退敌！",
	["$sk_yingbing2"] = "四方神将，皆为我用！",
	["designer:sk_zhangbao"] = "极略三国",
    ["illustrator:sk_zhangbao"] = "极略三国",
    ["cv:sk_zhangbao"] = "极略三国",
}


--邓芝
sk_dengzhi = sgs.General(extension, "sk_dengzhi", "shu", 3, true)


--和盟
sk_hemengCard = sgs.CreateSkillCard{
    name = "sk_hemengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
	    return #targets == 1
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		local id = room:askForCardChosen(target, source, "h", "sk_hemeng", true)
		room:obtainCard(target, id, false)
		if source:isAlive() and not target:isKongcheng() then
		    local id2 = room:askForCardChosen(source, target, "h", "sk_hemeng", true)
			room:obtainCard(source, id2, false)
		end
	end
}

sk_hemengVS = sgs.CreateViewAsSkillV2{
    name = "sk_hemeng",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if player:isKongcheng() then return false end
		return player:usedTimes("#sk_hemengCard") < player:getMark("sk_hemeng_max-PlayClear")
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0 and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		return sk_hemengCard:clone()
	end,
}

sk_hemeng = sgs.CreateTriggerSkillV2{
    name = "sk_hemeng",
	view_as_skill = sk_hemengVS,
	events = {sgs.EventPhaseStart},
	on_record = function(skill, event, room, player, ctx)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Play then
			room:setPlayerMark(player, "sk_hemeng_max-PlayClear", player:getLostHp() + 1)
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
}


--素检
sk_sujian = sgs.CreateTriggerSkillV2{
    name = "sk_sujian",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if not (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand
			and move.from and move.from:objectName() ~= player:objectName()) then return false end
		for _, place in sgs.qlist(move.from_places) do
			if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip
				or place == sgs.Player_PlaceJudge or place == sgs.Player_PlaceDelayedTrick then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = room:getOtherPlayers(player)
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sujian-target", true, true)
		if target then
			ctx.targets:append(target)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, to)
		if player:isNude() then return false end
		room:broadcastSkillInvoke(skill:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, to:objectName(), player:objectName(), skill:objectName(), nil)
		local id = room:askForCardChosen(to, player, "he", skill:objectName())
		room:throwCard(id, reason, player, to)
		if player:isAlive() and to:isAlive() and not to:isNude() then
			local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), to:objectName(), skill:objectName(), nil)
			local id2 = room:askForCardChosen(player, to, "he", skill:objectName())
			room:throwCard(id2, reason2, to, player)
		end
		return false
	end,
}


sk_dengzhi:addSkill(sk_hemeng)
sk_dengzhi:addSkill(sk_sujian)


sgs.LoadTranslationTable{
	["sk_dengzhi"] = "SK邓芝",
	["&sk_dengzhi"] = "邓芝",
	["sk_hemeng"] = "和盟",
	[":sk_hemeng"] = "出牌阶段限X+1次（X为此阶段开始时你已损失的体力值），若你有手牌，你可以令一名其他角色观看你的手牌并获得其中一张，然后你观看其手牌并获得其一张牌。",
	["~sk_hemengCard"] = "选择一名其他角色→点击“确定”",
	["sk_sujian"] = "素检",
	[":sk_sujian"] = "当你从其他角色的区域里获得牌后，你可以令一名其他角色弃置你的一张牌，然后你弃置其一张牌。",
	["@sujian-target"] = "素检：你可以令一名其他角色弃置你的一张牌，然后你弃置其一张牌",
	["designer:sk_dengzhi"] = "极略三国",
    ["illustrator:sk_dengzhi"] = "极略三国",
    ["cv:sk_dengzhi"] = "极略三国",
}


--陈式
sk_chenshi = sgs.General(extension, "sk_chenshi", "shu", 4, true)


--擎北
sk_qingbei = sgs.CreateTriggerSkillV2{
    name = "sk_qingbei",
	events = {sgs.RoundStart, sgs.CardUsed},
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.RoundStart and player and player:hasSkill(skill:objectName()) then
			player:setTag("sk_qingbei_suit_old", player:getTag("sk_qingbei_suit"))
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.RoundStart then
			if player and player:isAlive() and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.CardUsed then
			if not player then return false end
			local use = data:toCardUse()
			if not (use.card and use.m_isHandcard and use.from) then return false end
			local suit = use.card:getSuitString()
			if suit == "" or suit == "no_suit" then return false end
			local names, owners = {}, {}
			for _, chenshi in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if chenshi:isAlive() and (chenshi:getTag("sk_qingbei_suit"):toString() == suit
					or chenshi:getTag("sk_qingbei_suit_old"):toString() == suit) then
					table.insert(names, skill:objectName())
					table.insert(owners, chenshi:objectName())
				end
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.RoundStart then
			return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("choose_suit"))
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.RoundStart then
			local suit = room:askForChoice(player, skill:objectName(), "spade+heart+club+diamond")
			player:setTag("sk_qingbei_suit", sgs.QVariant(suit))
			local log = sgs.LogMessage()
			log.type = "#sk_qingbei_choose"
			log.from = player
			log.arg = skill:objectName()
			log.arg2 = suit .. "_char"
			room:sendLog(log)
			room:broadcastSkillInvoke(skill:objectName())
		elseif event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			local user = use.from
			local suit = use.card:getSuitString()
			local flag = "sk_qingbei_used_" .. suit .. "-Clear"
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			if user:getMark(flag) > 0 then
				player:drawCards(1, skill:objectName())
			else
				room:addPlayerMark(user, flag)
				player:drawCards(2, skill:objectName())
			end
		end
		return false
	end,
}


sk_chenshi:addSkill(sk_qingbei)


sgs.LoadTranslationTable{
	["sk_chenshi"] = "SK陈式",
	["&sk_chenshi"] = "陈式",
	["sk_qingbei"] = "擎北",
	[":sk_qingbei"] = "每轮开始时，你可以选择一种花色，然后直到下一轮结束，当一名角色使用此花色的手牌时，若为本回合首次使用，你摸两张牌；否则你摸一张牌。",
	["sk_qingbei:choose_suit"] = "擎北：你可以选择一种花色",
	["#sk_qingbei_choose"] = "%from 发动了“%arg”，选择了 %arg2",
	["designer:sk_chenshi"] = "极略三国",
    ["illustrator:sk_chenshi"] = "极略三国",
    ["cv:sk_chenshi"] = "极略三国",
}


--马良
sk_maliang = sgs.General(extension, "sk_maliang", "shu", 3, true)


--雅虑
sk_yalv = sgs.CreateTriggerSkillV2{
    name = "sk_yalv",
	events = {sgs.Damaged, sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.Damaged then
			return skill:objectName()
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local ids = room:getNCards(2, false)
		if ids:length() > 0 then
			room:askForGuanxing(player, ids, sgs.Room_GuanxingBothSides)
		end
		if player:isAlive() and player:askForSkillInvoke(skill:objectName(), sgs.QVariant("draw")) then
			player:drawCards(1, skill:objectName())
		end
		return false
	end,
}


--协穆
sk_xiemu = sgs.CreateTriggerSkillV2{
    name = "sk_xiemu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local names, owners = {}, {}
		if player:getPhase() == sgs.Player_Start then
			for _, maliang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if maliang:isAlive() and maliang:objectName() ~= player:objectName() and not maliang:isKongcheng() then
					table.insert(names, skill:objectName())
					table.insert(owners, maliang:objectName())
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			for _, maliang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if maliang:isAlive() and player:getMark("sk_xiemu_draw+#" .. maliang:objectName() .. "-Clear") > 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, maliang:objectName())
				end
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:isAlive()) then return false end
		if target:getPhase() == sgs.Player_Start then
			local card = room:askForCard(player, ".|.|.|hand", "@xiemu-put:" .. target:objectName(), ctx.original_data, sgs.Card_MethodNone)
			if card then
				ctx.extra_data:setValue(card:getEffectiveId())
				return true
			end
		elseif target:getPhase() == sgs.Player_Finish then
			return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("xiemu_draw:" .. target:objectName()))
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:isAlive()) then return false end
		if target:getPhase() == sgs.Player_Start then
			local card = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
			if card then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill:objectName(), "")
				room:moveCardTo(card, player, nil, sgs.Player_DrawPile, reason)
				room:broadcastSkillInvoke(skill:objectName())
				room:addPlayerMark(target, "sk_xiemu_draw+#" .. player:objectName() .. "-Clear")
			end
		elseif target:getPhase() == sgs.Player_Finish then
			room:broadcastSkillInvoke(skill:objectName())
			target:drawCards(1, skill:objectName())
		end
		return false
	end,
}


sk_maliang:addSkill(sk_yalv)
sk_maliang:addSkill(sk_xiemu)


sgs.LoadTranslationTable{
	["sk_maliang"] = "SK马良",
	["&sk_maliang"] = "马良",
	["#sk_maliang"] = "白眉智士",
	["sk_yalv"] = "雅虑",
	[":sk_yalv"] = "当你受到伤害后，或出牌阶段开始时，你可以观看牌堆顶的两张牌，将这些牌以任意顺序置于牌堆顶或底，然后你可以摸一张牌。",
	["sk_yalv:draw"] = "雅虑：你可以摸一张牌",
	["sk_xiemu"] = "协穆",
	[":sk_xiemu"] = "其他角色的准备阶段，你可以将一张手牌置于牌堆顶，然后该回合的结束阶段时，你可以令其摸一张牌。",
	["@xiemu-put"] = "协穆：你可以将一张手牌置于牌堆顶（%src 的回合结束阶段，你可以令其摸一张牌）",
	["sk_xiemu:xiemu_draw"] = "协穆：你可以令 %src 摸一张牌",
	["designer:sk_maliang"] = "极略三国",
    ["illustrator:sk_maliang"] = "极略三国",
    ["cv:sk_maliang"] = "极略三国",
}


--费祎
sk_feiyi = sgs.General(extension, "sk_feiyi", "shu", 3, true)


--衍息
sk_yanxi = sgs.CreateTriggerSkillV2{
    name = "sk_yanxi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish)
			and player:getEquips():isEmpty() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(1, skill:objectName())
		return false
	end,
}


--止戈
sk_zhige = sgs.CreateTriggerSkillV2{
    name = "sk_zhige",
	events = {sgs.CardAsked},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())
			and not player:getEquips():isEmpty()) then return false end
		local pattern = data:toStringList()
		if pattern[1] == "slash" or pattern[1] == "jink" then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pattern = ctx.original_data:toStringList()
		if pattern[1] ~= "slash" and pattern[1] ~= "jink" then return false end
		room:broadcastSkillInvoke(skill:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), skill:objectName(), "")
		for _, c in sgs.qlist(player:getEquips()) do
			room:throwCard(c, reason, player, player)
		end
		local card = sgs.Sanguosha:cloneCard(pattern[1], sgs.Card_NoSuit, 0)
		card:setSkillName(skill:objectName())
		room:provide(card)
		return true
	end,
}


sk_feiyi:addSkill(sk_yanxi)
sk_feiyi:addSkill(sk_zhige)


sgs.LoadTranslationTable{
	["sk_feiyi"] = "SK费祎",
	["&sk_feiyi"] = "费祎",
	["#sk_feiyi"] = "洞世权相",
	["sk_yanxi"] = "衍息",
	[":sk_yanxi"] = "准备阶段或结束阶段，若你装备区内没有牌，你可以摸一张牌。",
	["sk_zhige"] = "止戈",
	[":sk_zhige"] = "当你需要使用一张【杀】或【闪】时，你可以弃置装备区内的所有牌，然后视为使用之。",
	["designer:sk_feiyi"] = "极略三国",
    ["illustrator:sk_feiyi"] = "极略三国",
    ["cv:sk_feiyi"] = "极略三国",
}


--甘夫人
sk_ganfuren = sgs.General(extension, "sk_ganfuren", "shu", 3, false)


--淑慎
sk_shushen = sgs.CreateTriggerSkillV2{
    name = "sk_shushen",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local rec = data:toRecover()
		if rec.recover > 0 then return skill:objectName() end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local rec = ctx.original_data:toRecover()
		room:broadcastSkillInvoke(skill:objectName())
		for i = 1, rec.recover do
			if not player:isAlive() then break end
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@shushen-target", true, true)
			if not (to and to:isAlive()) then break end
			if to:isWounded() then
				local choice = room:askForChoice(to, skill:objectName(), "shushen_draw+shushen_recover")
				if choice == "shushen_recover" then
					local re = sgs.RecoverStruct()
					re.who = player
					room:recover(to, re, true)
				else
					to:drawCards(2, skill:objectName())
				end
			else
				to:drawCards(2, skill:objectName())
			end
		end
		return false
	end,
}


--神智
sk_shenzhi = sgs.CreateTriggerSkillV2{
    name = "sk_shenzhi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:isWounded() and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local n = player:getHandcardNum()
		player:throwAllHandCards(skill:objectName())
		if n >= math.max(1, player:getHp()) and player:isWounded() then
			local rec = sgs.RecoverStruct()
			rec.who = player
			room:recover(player, rec, true)
		end
		return false
	end,
}


sk_ganfuren:addSkill(sk_shushen)
sk_ganfuren:addSkill(sk_shenzhi)


sgs.LoadTranslationTable{
	["sk_ganfuren"] = "SK甘夫人",
	["&sk_ganfuren"] = "甘夫人",
	["#sk_ganfuren"] = "昭烈皇后",
	["sk_shushen"] = "淑慎",
	[":sk_shushen"] = "当你回复1点体力后，你可以令一名其他角色选择一项：1.摸两张牌；2.回复1点体力。",
	["@shushen-target"] = "淑慎：你可以令一名其他角色选择摸两张牌或回复1点体力",
	["shushen_draw"] = "摸两张牌",
	["shushen_recover"] = "回复1点体力",
	["sk_shenzhi"] = "神智",
	[":sk_shenzhi"] = "准备阶段，若你已受伤，你可以弃置所有手牌，然后若你以此法弃置的牌数不小于体力值，你回复1点体力。",
	["designer:sk_ganfuren"] = "极略三国",
    ["illustrator:sk_ganfuren"] = "极略三国",
    ["cv:sk_ganfuren"] = "极略三国",
}


--糜夫人
sk_mifuren = sgs.General(extension, "sk_mifuren", "shu", 3, false)


--闺秀
sk_guixiu = sgs.CreateTriggerSkillV2{
	name = "sk_guixiu",
	events = {sgs.EventPhaseStart, sgs.Damage},
	frequency = sgs.Skill_Frequent,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.Damage then return end
		if not (player and player:hasSkill(skill:objectName())) then return end
		local current = room:getCurrent()
		if not (current and current:objectName() == player:objectName()) then return end
		local damage = ctx.original_data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() then
			room:addPlayerMark(player, "sk_guixiu_damaged-Clear")
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart then return false end
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() == sgs.Player_Discard
			and player:getMark("sk_guixiu_damaged-Clear") == 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:skip(sgs.Player_Discard)
		player:drawCards(1, skill:objectName())
		return false
	end,
}


--存嗣
sk_cunsi = sgs.CreateTriggerSkillV2{
	name = "sk_cunsi",
	events = {sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() then
			return skill:objectName(), player:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = room:getOtherPlayers(player)
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_cunsi-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, to)
		if not to then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), to:objectName())
		for _, c in sgs.qlist(player:getCards("he")) do
			to:addToPile("sk_si", c:getEffectiveId(), false)
		end
		if not to:hasSkill("sk_yongjue") then room:acquireSkill(to, "sk_yongjue") end
		return false
	end,
}


--勇决
sk_yongjue = sgs.CreateTriggerSkillV2{
	name = "sk_yongjue",
	events = {sgs.ConfirmDamage, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
				and damage.card and damage.card:isKindOf("Slash") then
				return skill:objectName()
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.who:getSeat() ~= player:getSeat()
				and death.damage and death.damage.from
				and death.damage.from:getSeat() == player:getSeat()
				and not player:getPile("sk_si"):isEmpty() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if event == sgs.ConfirmDamage then
			local damage = ctx.original_data:toDamage()
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
		elseif event == sgs.Death then
			local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(player:getPile("sk_si")) do
				dummy:addSubcard(id)
			end
			if dummy:subcardsLength() > 0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
				room:obtainCard(player, dummy, reason, false)
			end
			dummy:deleteLater()
		end
		return false
	end,
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sk_yongjue") then skills:append(sk_yongjue) end
sgs.Sanguosha:addSkills(skills)

sk_mifuren:addSkill(sk_guixiu)
sk_mifuren:addSkill(sk_cunsi)
sk_mifuren:addRelateSkill("sk_yongjue")


sgs.LoadTranslationTable{
	["sk_mifuren"] = "SK糜夫人",
	["&sk_mifuren"] = "糜夫人",
	["sk_guixiu"] = "闺秀",
	[":sk_guixiu"] = "若你未于本回合内造成伤害，你可以跳过弃牌阶段并摸一张牌。",
	["sk_cunsi"] = "存嗣",
	[":sk_cunsi"] = "你死亡时，你可以将所有牌置于一名其他角色的武将牌上，称为“嗣”，然后其获得“勇决”。",
	["@sk_cunsi-choose"] = "存嗣：你可以将所有牌置于一名其他角色的武将牌上，然后其获得“勇决”",
	["sk_yongjue"] = "勇决",
	[":sk_yongjue"] = "锁定技，你使用【杀】造成的伤害+1。当你杀死一名角色后，你获得“嗣”。",
	["sk_si"] = "嗣",
	["designer:sk_mifuren"] = "极略三国",
    ["illustrator:sk_mifuren"] = "极略三国",
    ["cv:sk_mifuren"] = "极略三国",
}


--关兴
sk_guanxing = sgs.General(extension, "sk_guanxing", "shu", 4, true)


--勇继
sk_yongji = sgs.CreateTriggerSkillV2{
	name = "sk_yongji",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName()
			and damage.card and damage.card:isKindOf("Slash")
			and player:getPhase() == sgs.Player_Play then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local x = math.min(player:getLostHp(), 3)
		if x > 0 then player:drawCards(x, skill:objectName()) end
		if damage.card then room:addPlayerHistory(player, damage.card:getClassName(), -1) end
		return false
	end,
}


--武志
sk_wuzhi = sgs.CreateTriggerSkillV2{
	name = "sk_wuzhi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() == sgs.Player_Finish and player:canSlashWithoutCrossbow() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		room:loseHp(player, 1, true, player, skill:objectName())
		if player:isAlive() then
			if room:getDrawPile():isEmpty() then room:swapPile() end
			local slash_ids = sgs.QList2Table(getOneTypeIds("Slash"))
			if #slash_ids > 0 then
				room:obtainCard(player, slash_ids[math.random(1, #slash_ids)], false)
			end
		end
		return false
	end,
}


sk_guanxing:addSkill(sk_yongji)
sk_guanxing:addSkill(sk_wuzhi)


sgs.LoadTranslationTable{
	["sk_guanxing"] = "SK关兴",
	["&sk_guanxing"] = "关兴",
	["sk_yongji"] = "勇继",
	[":sk_yongji"] = "锁定技，出牌阶段，当你使用【杀】造成伤害后，你摸X张牌且此牌不计入使用次数（X为你已损失的体力值，至多为3）。",
	["sk_wuzhi"] = "武志",
	[":sk_wuzhi"] = "锁定技，结束阶段，若你本回合使用【杀】的次数小于次数上限，你失去1点体力并从牌堆中随机获得一张【杀】。",
	["designer:sk_guanxing"] = "极略三国",
    ["illustrator:sk_guanxing"] = "极略三国",
    ["cv:sk_guanxing"] = "极略三国",
}


--刘谌
sk_liuchen = sgs.General(extension, "sk_liuchen", "shu", 4, true)


--[[
	技能名：战绝
	相关武将：SK刘谌
	技能描述：当你失去一个区域内的所有牌后，你可以对一名其他角色造成1点伤害。
	引用：sk_zhanjue
]]--
sk_zhanjue = sgs.CreateTriggerSkillV2{
	name = "sk_zhanjue",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if not (move.from and move.from:objectName() == player:objectName()) then return false end
		for _, place in sgs.qlist(move.from_places) do
			if place == sgs.Player_PlaceHand and player:isKongcheng() then
				return skill:objectName()
			elseif place == sgs.Player_PlaceEquip and player:getEquips():isEmpty() then
				return skill:objectName()
			elseif (place == sgs.Player_PlaceDelayedTrick or place == sgs.Player_PlaceJudge)
				and player:getJudgingArea():isEmpty() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local hand_lost, equip_lost, judge_lost = false, false, false
		for _, place in sgs.qlist(move.from_places) do
			if place == sgs.Player_PlaceHand then
				hand_lost = true
			elseif place == sgs.Player_PlaceEquip then
				equip_lost = true
			elseif place == sgs.Player_PlaceDelayedTrick or place == sgs.Player_PlaceJudge then
				judge_lost = true
			end
		end
		local n = 0
		if hand_lost and player:isKongcheng() then n = n + 1 end
		if equip_lost and player:getEquips():isEmpty() then n = n + 1 end
		if judge_lost and player:getJudgingArea():isEmpty() then n = n + 1 end
		for i = 1, n do
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sk_zhanjue-target", true, true)
			if not target then break end
			room:broadcastSkillInvoke(skill:objectName())
			room:damage(sgs.DamageStruct(skill:objectName(), player, target))
		end
		return false
	end,
}

sk_liuchen:addSkill(sk_zhanjue)


sgs.LoadTranslationTable{
	["sk_liuchen"] = "SK刘谌",
	["&sk_liuchen"] = "刘谌",
	["sk_zhanjue"] = "战绝",
	[":sk_zhanjue"] = "当你失去一个区域（手牌区、装备区、判定区）内的所有牌后，你可以对一名其他角色造成1点伤害。",
	["@sk_zhanjue-target"] = "战绝：你可以对一名其他角色造成1点伤害",
	["designer:sk_liuchen"] = "极略三国",
    ["illustrator:sk_liuchen"] = "极略三国",
    ["cv:sk_liuchen"] = "极略三国",
}


--吴懿
sk_wuyi = sgs.General(extension, "sk_wuyi", "shu", 4, true)


--[[
	技能名：制敌
	相关武将：SK吴懿
	技能描述：锁定技，准备阶段，你随机获得以下任一未获得的效果：1.使用【杀】造成伤害后，摸一张牌；2.使用【杀】无视防具且不能被【闪】响应；3.使用【杀】无距离限制且次数上限+X；4.【杀】的目标上限+X（X为“制敌”发动次数）。
	引用：sk_zhidi
]]--
sk_zhidi = sgs.CreateTriggerSkillV2{
	name = "sk_zhidi",
	events = {sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("sk_zhidi_num") < 4 then
				return skill:objectName()
			end
		elseif event == sgs.TargetConfirmed then
			if player:getMark("sk_zhidi_ef2") == 0 then return false end
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName()
				and use.card and use.card:isKindOf("Slash") then
				return skill:objectName()
			end
		elseif event == sgs.Damage then
			if player:getMark("sk_zhidi_ef1") == 0 then return false end
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
				and damage.card and damage.card:isKindOf("Slash") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if event == sgs.EventPhaseStart then
			local pool = {}
			for i = 1, 4 do
				if player:getMark("sk_zhidi_ef" .. i) == 0 then table.insert(pool, i) end
			end
			if #pool == 0 then return false end
			local n = pool[math.random(1, #pool)]
			room:setPlayerMark(player, "sk_zhidi_ef" .. n, 1)
			room:addPlayerMark(player, "sk_zhidi_num")
			local log = sgs.LogMessage()
			log.type = "#sk_zhidiGain"
			log.from = player
			log.arg = "sk_zhidi_ef" .. n
			log.arg2 = tostring(player:getMark("sk_zhidi_num"))
			room:sendLog(log)
		elseif event == sgs.TargetConfirmed then
			local data = ctx.original_data
			local use = data:toCardUse()
			local no_respond_list = use.no_respond_list
			if not table.contains(no_respond_list, "_ALL_TARGETS") then
				table.insert(no_respond_list, "_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
			for _, t in sgs.qlist(use.to) do
				t:addQinggangTag(use.card)
			end
		elseif event == sgs.Damage then
			player:drawCards(1, skill:objectName())
		end
		return false
	end,
}

sk_zhiditm = sgs.CreateTargetModSkillV2{
	name = "#sk_zhiditm",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not (player and player:hasSkill("sk_zhidi")) then return false end
		local mod = ctx:getModType()
		if mod == sgs.TargetModSkill_DistanceLimit then
			if player:getMark("sk_zhidi_ef3") > 0 then return 9999 end
		elseif mod == sgs.TargetModSkill_Residue then
			if player:getMark("sk_zhidi_ef3") > 0 then return player:getMark("sk_zhidi_num") end
		elseif mod == sgs.TargetModSkill_ExtraTarget then
			if player:getMark("sk_zhidi_ef4") > 0 then return player:getMark("sk_zhidi_num") end
		end
		return false
	end,
}

extension:insertRelatedSkills("sk_zhidi", "#sk_zhiditm")
sk_wuyi:addSkill(sk_zhidi)
sk_wuyi:addSkill(sk_zhiditm)


sgs.LoadTranslationTable{
	["sk_wuyi"] = "SK吴懿",
	["&sk_wuyi"] = "吴懿",
	["sk_zhidi"] = "制敌",
	[":sk_zhidi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段，你随机获得以下任一未获得的效果：1.使用【杀】造成伤害后，摸一张牌；2.使用【杀】无视防具且不能被【闪】响应；3.使用【杀】无距离限制且次数上限+X；4.【杀】的目标上限+X（X为“制敌”发动次数）。",
	["#sk_zhidiGain"] = "%from 的“制敌”发动次数为 %arg2，获得效果“%arg”",
	["sk_zhidi_ef1"] = "①使用【杀】造成伤害后，摸一张牌",
	["sk_zhidi_ef2"] = "②使用【杀】不能被响应",
	["sk_zhidi_ef3"] = "③使用【杀】无距离限制且次数上限+X",
	["sk_zhidi_ef4"] = "④【杀】的目标上限+X",
	["designer:sk_wuyi"] = "极略三国",
    ["illustrator:sk_wuyi"] = "极略三国",
    ["cv:sk_wuyi"] = "极略三国",
}


--诸葛果
sk_zhugeguo = sgs.General(extension, "sk_zhugeguo", "shu", 3, false)


--[[
	技能名：羽化
	相关武将：SK诸葛果
	技能描述：当你使用锦囊牌造成伤害时，或受到锦囊牌造成的伤害时，你可以摸一张牌并防止此伤害；若如此做，若你手牌上限大于0，你手牌上限-1。
	引用：sk_yuhua
]]--
sk_yuhua = sgs.CreateTriggerSkillV2{
	name = "sk_yuhua",
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not (damage.card and damage.card:isKindOf("TrickCard")) then return false end
		if event == sgs.DamageCaused then
			if damage.from and damage.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.DamageInflicted then
			if damage.to and damage.to:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(1, skill:objectName())
		if player:getMaxCards() > 0 then
			room:addPlayerMark(player, "sk_yuhua_max")
		end
		return true
	end,
}

sk_yuhuaMax = sgs.CreateMaxCardsSkillV2{
	name = "#sk_yuhua",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("sk_yuhua") then
			return -target:getMark("sk_yuhua_max")
		end
		return false
	end,
}


--[[
	技能名：登仙
	相关武将：SK诸葛果
	技能描述：觉醒技，准备阶段，若你的手牌上限为0，你将弃牌阶段改为一个额外的摸牌阶段或出牌阶段。
	引用：sk_dengxian
]]--
sk_dengxian = sgs.CreateTriggerSkillV2{
	name = "sk_dengxian",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark(skill:objectName()) == 0
				and player:getMaxCards() <= 0 then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			if player:getMark(skill:objectName()) > 0
				and data:toPhaseChange().to == sgs.Player_Discard then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			room:broadcastSkillInvoke(skill:objectName())
			room:addPlayerMark(player, skill:objectName())
			local msg = sgs.LogMessage()
			msg.type = "#sk_dengxianWake"
			msg.from = player
			msg.arg = skill:objectName()
			room:sendLog(msg)
		elseif event == sgs.EventPhaseChanging then
			local choice = room:askForChoice(player, skill:objectName(), "dengxian_draw+dengxian_play", ctx.original_data)
			local data = ctx.original_data
			local change = data:toPhaseChange()
			if choice == "dengxian_play" then
				change.to = sgs.Player_Play
			else
				change.to = sgs.Player_Draw
			end
			data:setValue(change)
		end
		return false
	end,
}


extension:insertRelatedSkills("sk_yuhua", "#sk_yuhua")
sk_zhugeguo:addSkill(sk_yuhua)
sk_zhugeguo:addSkill(sk_yuhuaMax)
sk_zhugeguo:addSkill(sk_dengxian)


sgs.LoadTranslationTable{
	["sk_zhugeguo"] = "SK诸葛果",
	["&sk_zhugeguo"] = "诸葛果",
	["sk_yuhua"] = "羽化",
	[":sk_yuhua"] = "当你使用锦囊牌造成伤害时，或受到锦囊牌造成的伤害时，你可以摸一张牌并防止此伤害；若如此做，若你的手牌上限大于0，你的手牌上限-1。",
	["sk_dengxian"] = "登仙",
	[":sk_dengxian"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段，若你的手牌上限为0，你将弃牌阶段改为一个额外的摸牌阶段或出牌阶段。",
	["#sk_dengxianWake"] = "%from 的“%arg”觉醒，其弃牌阶段将改为一个额外的摸牌阶段或出牌阶段",
	["dengxian_draw"] = "摸牌阶段",
	["dengxian_play"] = "出牌阶段",
	["designer:sk_zhugeguo"] = "极略三国",
    ["illustrator:sk_zhugeguo"] = "极略三国",
    ["cv:sk_zhugeguo"] = "极略三国",
}


--夏侯氏
sk_xiahoushi = sgs.General(extension, "sk_xiahoushi", "shu", 3, false)


--[[
	技能名：拾樵
	相关武将：SK夏侯氏
	技能描述：一名角色的回合结束时，你可以随机获得弃牌堆中的X张牌（X为该角色本回合使用【杀】的次数）。
	引用：sk_shiqiao
]]--
sk_shiqiao = sgs.CreateTriggerSkillV2{
	name = "sk_shiqiao",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:getPhase() == sgs.Player_Finish) then return false end
		if player:usedTimes("Slash") <= 0 then return false end
		if room:getDiscardPile():isEmpty() then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("shiqiaodraw:" .. p:objectName()))
	end,
	on_effect = function(skill, event, room, player, ctx)
		local p = ctx.invoker
		if not p then return false end
		local x = math.min(p:usedTimes("Slash"), room:getDiscardPile():length())
		if x <= 0 then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), p:objectName())
		local cards = sgs.QList2Table(room:getDiscardPile())
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		for i = 1, x do
			local j = math.random(1, #cards)
			dummy:addSubcard(cards[j])
			table.remove(cards, j)
		end
		player:obtainCard(dummy)
		dummy:deleteLater()
		return false
	end,
}


--[[
	技能名：莺歌
	相关武将：SK夏侯氏
	技能描述：一名角色的出牌阶段开始时，你可以弃置一张牌，然后其从牌堆或弃牌堆中随机获得三张【杀】，其本回合使用点数不小于弃置牌的【杀】无次数与距离限制，且这些牌对你伤害-1。
	引用：sk_yingge
]]--
sk_yingge = sgs.CreateTriggerSkillV2{
	name = "sk_yingge",
	events = {sgs.EventPhaseStart, sgs.ConfirmDamage},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then return false end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:isAlive() and not p:isNude() then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, p:objectName())
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if not (damage.from and damage.to and damage.card) then return false end
			if player:objectName() ~= damage.from:objectName() then return false end
			local point = damage.from:getMark("sk_yingge_point-Clear")
			if point <= 0 or not damage.card:isKindOf("Slash")
				or damage.card:getNumber() < point then return false end
			if damage.to:hasSkill(skill:objectName())
				and damage.from:getMark("sk_yingge_to+#" .. damage.to:objectName() .. "-Clear") > 0 then
				return skill:objectName(), damage.to:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.ConfirmDamage then return true end
		local target = ctx.invoker
		if not target then return false end
		local card = room:askForCard(player, ".|.|.|.", "@sk_yingge-discard:" .. target:objectName(), ctx.original_data, sgs.Card_MethodDiscard)
		if card then
			ctx.extra_data:setValue(card:getNumber())
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.ConfirmDamage then
			room:broadcastSkillInvoke(skill:objectName())
			local damage = ctx.original_data:toDamage()
			damage.damage = math.max(0, damage.damage - 1)
			ctx.original_data:setValue(damage)
			return false
		end
		local target = ctx.invoker
		if not target then return false end
		local point = ctx.extra_data:toInt()
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local slash_ids = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Slash") then table.insert(slash_ids, id) end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Slash") then table.insert(slash_ids, id) end
		end
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		for i = 1, 3 do
			if #slash_ids == 0 then break end
			local j = math.random(1, #slash_ids)
			dummy:addSubcard(slash_ids[j])
			table.remove(slash_ids, j)
		end
		if dummy:subcardsLength() > 0 then
			target:obtainCard(dummy)
		end
		dummy:deleteLater()
		room:setPlayerMark(target, "sk_yingge_point-Clear", point)
		room:setPlayerMark(target, "sk_yingge_to+#" .. player:objectName() .. "-Clear", 1)
		return false
	end,
}

sk_yinggeTM = sgs.CreateTargetModSkillV2{
	name = "#sk_yingge",
	pattern = "Slash",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local from, card = ctx:getPrimary(), ctx:getCard()
		if not (from and card) then return false end
		local point = from:getMark("sk_yingge_point-Clear")
		if point <= 0 or card:getNumber() < point then return false end
		local mod = ctx:getModType()
		if mod == sgs.TargetModSkill_DistanceLimit or mod == sgs.TargetModSkill_Residue then
			return 9999
		end
		return false
	end,
}

local sk_yingge_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sk_yingge") then sk_yingge_skills:append(sk_yinggeTM) end
sgs.Sanguosha:addSkills(sk_yingge_skills)


sk_xiahoushi:addSkill(sk_shiqiao)
sk_xiahoushi:addSkill(sk_yingge)


sgs.LoadTranslationTable{
	["sk_xiahoushi"] = "SK夏侯氏",
	["&sk_xiahoushi"] = "夏侯氏",
	["sk_shiqiao"] = "拾樵",
	[":sk_shiqiao"] = "一名角色的回合结束时，你可以随机获得弃牌堆中的X张牌（X为该角色本回合使用【杀】的次数）。",
	["sk_shiqiao:shiqiaodraw"] = "是否发动“拾樵”从弃牌堆中随机获得 %src 本回合使用【杀】次数的牌？",
	["sk_yingge"] = "莺歌",
	[":sk_yingge"] = "一名角色的出牌阶段开始时，你可以弃置一张牌，然后其从牌堆或弃牌堆中随机获得三张【杀】，其本回合使用点数不小于弃置牌的【杀】无次数与距离限制，且这些牌对你伤害-1。",
	["@sk_yingge-discard"] = "莺歌：你可以弃置一张牌，令 %src 随机获得三张【杀】且其本回合使用点数不小于此牌点数的【杀】无次数与距离限制（这些【杀】对你伤害-1）",
	["designer:sk_xiahoushi"] = "极略三国",
    ["illustrator:sk_xiahoushi"] = "极略三国",
    ["cv:sk_xiahoushi"] = "极略三国",
}


--吴苋
sk_wuxian = sgs.General(extension, "sk_wuxian", "shu", 3, false)


--[[
	技能名：贺春
	相关武将：SK吴苋
	技能描述：出牌阶段限一次，你可以令所有其他角色展示并交给你一张牌，若此牌为红色且其已受伤/为黑色，你可以令其回复/失去1点体力。
	引用：sk_hechun
]]--
sk_hechunCard = sgs.CreateSkillCard{
	name = "sk_hechunCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:isNude() then
				local card_id = room:askForCardChosen(p, p, "he", "sk_hechun")
				local card = sgs.Sanguosha:getCard(card_id)
				room:obtainCard(source, card_id, true)
				if card:isRed() and p:isWounded() then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if source:askForSkillInvoke("sk_hechun_recover", _data) then
						local rec = sgs.RecoverStruct()
						rec.who = source
						room:recover(p, rec, true)
					end
				elseif card:isBlack() then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if source:askForSkillInvoke("sk_hechun_lose", _data) then
						room:loseHp(p, 1, true, source, "sk_hechun")
					end
				end
			end
		end
	end
}

sk_hechun = sgs.CreateViewAsSkillV2{
	name = "sk_hechun",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_hechunCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_hechunCard:clone()
	end,
}


--[[
	技能名：怠宴
	相关武将：SK吴苋
	技能描述：回合结束时，你可以令一名角色失去X点体力（X为你对其发动此技能的次数-1），然后进行一个额外的回合。
	引用：sk_daiyan
]]--
sk_daiyan = sgs.CreateTriggerSkillV2{
	name = "sk_daiyan",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Finish then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_daiyan-choose", true, true)
		if target then
			ctx.targets:append(target)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		local mark = "&sk_daiyan+#" .. player:objectName()
		local x = target:getMark(mark)
		room:addPlayerMark(target, mark)
		if x > 0 then
			room:loseHp(target, x, true, player, skill:objectName())
		end
		if target:isAlive() then
			target:gainAnExtraTurn()
		end
		return false
	end,
}


sk_wuxian:addSkill(sk_hechun)
sk_wuxian:addSkill(sk_daiyan)


sgs.LoadTranslationTable{
	["sk_wuxian"] = "SK吴苋",
	["&sk_wuxian"] = "吴苋",
	["sk_hechun"] = "贺春",
	["sk_hechunCard"] = "贺春",
	[":sk_hechun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令所有其他角色展示并交给你一张牌，若此牌为红色且其已受伤/为黑色，你可以令其回复/失去1点体力。",
	["sk_hechun_recover"] = "贺春",
	["sk_hechun_lose"] = "贺春",
	["sk_daiyan"] = "怠宴",
	[":sk_daiyan"] = "回合结束时，你可以令一名角色失去X点体力（X为你对其发动此技能的次数-1），然后进行一个额外的回合。",
	["@sk_daiyan-choose"] = "怠宴：你可以令一名角色失去X点体力（X为你对其发动此技能的次数-1），其进行一个额外的回合",
	["designer:sk_wuxian"] = "极略三国",
    ["illustrator:sk_wuxian"] = "极略三国",
    ["cv:sk_wuxian"] = "极略三国",
}


--花鬘
sk_huaman = sgs.General(extension, "sk_huaman", "qun", 3, false)


--[[
	技能名：蛮裔
	相关武将：SK花鬘
	技能描述：当你使用【杀】或普通锦囊牌指定目标后，或当你成为这些牌的目标后，你可以将此牌效果改为【南蛮入侵】，此牌结算后，你摸一张牌。
	引用：sk_manyi
]]--
sk_manyi = sgs.CreateTriggerSkillV2{
	name = "sk_manyi",
	events = {sgs.TargetConfirmed, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed then
			if not (use.card and use.from) then return false end
			if not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
			if use.card:getTag("sk_manyi_done"):toBool() or use.card:getTag("sk_manyi_conv"):toBool() then return false end
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:isAlive() and (p:objectName() == use.from:objectName() or p:objectName() == player:objectName()) then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, p:objectName())
				end
			end
			if #trigger_list_skill > 0 then
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		elseif event == sgs.CardFinished then
			if use.card then
				if use.card:getTag("sk_manyi_done"):toBool() then
					use.card:removeTag("sk_manyi_done")
				end
				if use.card:getTag("sk_manyi_draw"):toString() ~= "" then
					local huaman = room:findPlayerByObjectName(use.card:getTag("sk_manyi_draw"):toString())
					if huaman and huaman:isAlive() then
						return skill:objectName(), huaman:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.CardFinished then return true end
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if use.card and use.card:getTag("sk_manyi_draw"):toString() ~= "" then
				use.card:removeTag("sk_manyi_draw")
			end
			player:drawCards(1, skill:objectName())
			return false
		end
		local data = ctx.original_data
		local use = data:toCardUse()
		local card = use.card
		if not (card and use.from) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		use.card:setTag("sk_manyi_done", sgs.QVariant(true))
		local nullified_list = use.nullified_list
		for _, t in sgs.qlist(use.to) do
			table.insert(nullified_list, t:objectName())
		end
		use.nullified_list = nullified_list
		data:setValue(use)
		local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())
		savage_assault:setSkillName(skill:objectName())
		savage_assault:setTag("sk_manyi_conv", sgs.QVariant(true))
		savage_assault:setTag("sk_manyi_draw", sgs.QVariant(player:objectName()))
		if card:isVirtualCard() then
			for _, id in sgs.qlist(card:getSubcards()) do
				savage_assault:addSubcard(id)
			end
		else
			savage_assault:addSubcard(card)
		end
		local use2 = sgs.CardUseStruct()
		use2.card = savage_assault
		use2.from = use.from
		for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
			if not use.from:isProhibited(p, savage_assault) then
				use2.to:append(p)
			end
		end
		room:useCard(use2)
		savage_assault:deleteLater()
		return false
	end,
}


--[[
	技能名：薮影
	相关武将：SK花鬘
	技能描述：每回合每名角色各限一次，当一名角色打出一张【杀】/【闪】时，你可以对一名角色造成1点伤害/令一名角色回复1点体力。
	引用：sk_souying
]]--
sk_souying = sgs.CreateTriggerSkillV2{
	name = "sk_souying",
	events = {sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local resp = data:toCardResponse()
		if not (resp.m_card and resp.m_who and resp.m_isUse == false) then return false end
		if not (resp.m_card:isKindOf("Slash") or resp.m_card:isKindOf("Jink")) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local resp = ctx.original_data:toCardResponse()
		local is_slash = resp.m_card:isKindOf("Slash")
		local mark = is_slash and "sk_souying_dmg#" or "sk_souying_heal#"
		local targets = sgs.SPlayerList()
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if player:getMark(mark .. t:objectName() .. "-Clear") == 0
				and (is_slash or t:isWounded()) then
				targets:append(t)
			end
		end
		if targets:isEmpty() then return false end
		local virtual = is_slash and "sk_souying_dmg" or "sk_souying_heal"
		local prompt = is_slash and "@sk_souying-damage" or "@sk_souying-recover"
		local to = room:askForPlayerChosen(player, targets, virtual, prompt, true, true)
		if to then
			ctx.targets:append(to)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		local resp = ctx.original_data:toCardResponse()
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		if resp.m_card:isKindOf("Slash") then
			room:addPlayerMark(player, "sk_souying_dmg#" .. target:objectName() .. "-Clear")
			room:damage(sgs.DamageStruct(skill:objectName(), player, target))
		else
			room:addPlayerMark(player, "sk_souying_heal#" .. target:objectName() .. "-Clear")
			local rec = sgs.RecoverStruct()
			rec.who = player
			room:recover(target, rec, true)
		end
		return false
	end,
}


sk_huaman:addSkill(sk_manyi)
sk_huaman:addSkill(sk_souying)


sgs.LoadTranslationTable{
	["sk_huaman"] = "SK花鬘",
	["&sk_huaman"] = "花鬘",
	["sk_manyi"] = "蛮裔",
	[":sk_manyi"] = "当你使用【杀】或普通锦囊牌指定目标后，或当你成为这些牌的目标后，你可以将此牌效果改为【南蛮入侵】，此牌结算后，你摸一张牌。",
	["sk_souying"] = "薮影",
	["sk_souying_dmg"] = "薮影",
	["sk_souying_heal"] = "薮影",
	[":sk_souying"] = "每回合每名角色各限一次，当一名角色打出一张【杀】/【闪】时，你可以对一名角色造成1点伤害/令一名角色回复1点体力。",
	["@sk_souying-damage"] = "薮影：你可以对一名角色造成1点伤害",
	["@sk_souying-recover"] = "薮影：你可以令一名角色回复1点体力",
	["designer:sk_huaman"] = "极略三国",
    ["illustrator:sk_huaman"] = "极略三国",
    ["cv:sk_huaman"] = "极略三国",
}


--关索
sk_guansuo = sgs.General(extension, "sk_guansuo", "shu", 4, true)


--[[
	技能名：征南
	相关武将：SK关索
	技能描述：出牌阶段限一次，你可以令一名角色视为使用一张【南蛮入侵】，此牌造成伤害后，你与其各摸一张牌。
	引用：sk_zhengnan
]]--
sk_zhengnanCard = sgs.CreateSkillCard{
	name = "sk_zhengnanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
		savage_assault:setSkillName("sk_zhengnan")
		savage_assault:setTag("sk_zhengnan_src", sgs.QVariant(source:objectName()))
		local use = sgs.CardUseStruct()
		use.card = savage_assault
		use.from = target
		for _, p in sgs.qlist(room:getOtherPlayers(target)) do
			if not target:isProhibited(p, savage_assault) then
				use.to:append(p)
			end
		end
		if not use.to:isEmpty() then
			room:useCard(use)
		end
		savage_assault:deleteLater()
	end
}

sk_zhengnanVS = sgs.CreateViewAsSkillV2{
	name = "sk_zhengnan",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_zhengnanCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_zhengnanCard:clone()
	end,
}

sk_zhengnan = sgs.CreateTriggerSkillV2{
	name = "sk_zhengnan",
	events = {sgs.Damage},
	view_as_skill = sk_zhengnanVS,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local damage = data:toDamage()
		if not (damage.card and damage.from) then return false end
		local src_name = damage.card:getTag("sk_zhengnan_src"):toString()
		if src_name == "" then return false end
		local guansuo = room:findPlayerByObjectName(src_name)
		if guansuo and guansuo:isAlive() and guansuo:hasSkill(skill:objectName()) then
			return skill:objectName(), src_name
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local damage = ctx.original_data:toDamage()
		player:drawCards(1, skill:objectName())
		if damage.from and damage.from:isAlive() then
			damage.from:drawCards(1, skill:objectName())
		end
		return false
	end,
}


--[[
	技能名：同心
	相关武将：SK关索、SK鲍三娘
	技能描述：限定技，当你处于濒死状态时，你可以回复体力值至2点；然若“关索”或“鲍三娘”不在场上，你可以将武将牌（或主将）替换为其中之一。
	引用：sk_tongxin
]]--
sk_tongxin = sgs.CreateTriggerSkillV2{
	name = "sk_tongxin",
	frequency = sgs.Skill_Limited,
	limit_mark = "@sk_tongxin",
	events = {sgs.Dying},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getMark("@sk_tongxin") > 0) then return false end
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:loseMark("@sk_tongxin")
		room:broadcastSkillInvoke(skill:objectName())
		if player:getHp() < 2 then
			room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp()), true)
		end
		local onfield = {}
		for _, p in sgs.qlist(room:getAllPlayers()) do
			local g1, g2 = p:getGeneralName(), p:getGeneral2Name()
			if g1 and string.find(g1, "guansuo") then onfield["sk_guansuo"] = true end
			if g1 and string.find(g1, "baosanniang") then onfield["sk_baosanniang"] = true end
			if g2 and string.find(g2, "guansuo") then onfield["sk_guansuo"] = true end
			if g2 and string.find(g2, "baosanniang") then onfield["sk_baosanniang"] = true end
		end
		local candidates = {}
		for _, gname in ipairs({"sk_guansuo", "sk_baosanniang"}) do
			if not onfield[gname] then table.insert(candidates, gname) end
		end
		if #candidates > 0 and player:isAlive() then
			local general = room:askForGeneral(player, table.concat(candidates, "+"))
			if general and general ~= "" then
				room:changeHero(player, general, false, false, false, true)
			end
		end
		return false
	end,
}


sk_guansuo:addSkill(sk_zhengnan)
sk_guansuo:addSkill(sk_tongxin)


sgs.LoadTranslationTable{
	["sk_guansuo"] = "SK关索",
	["&sk_guansuo"] = "关索",
	["sk_zhengnan"] = "征南",
	["sk_zhengnanCard"] = "征南",
	[":sk_zhengnan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名角色视为使用一张【南蛮入侵】，此牌造成伤害后，你与其各摸一张牌。",
	["sk_tongxin"] = "同心",
	["@sk_tongxin"] = "同心",
	[":sk_tongxin"] = "<font color=\"red\"><b>限定技，</b></font>当你处于濒死状态时，你可以回复体力值至2点；然后若“关索”或“鲍三娘”不在场上，你可以将武将牌（或主将）替换为其中之一。",
	["designer:sk_guansuo"] = "极略三国",
    ["illustrator:sk_guansuo"] = "极略三国",
    ["cv:sk_guansuo"] = "极略三国",
}


--鲍三娘
sk_baosanniang = sgs.General(extension, "sk_baosanniang", "shu", 3, false)


--[[
	技能名：剑舞
	相关武将：SK鲍三娘
	技能描述：锁定技，当你使用基本牌后，若你使用的下一张牌是【杀】，此牌无距离与次数限制且目标上限+1。
	引用：sk_jianwu
]]--
sk_jianwu = sgs.CreateTriggerSkillV2{
	name = "sk_jianwu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.card and use.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and resp.m_who and resp.m_isUse == false
				and resp.m_who:objectName() == player:objectName()
				and resp.m_card:isBasicCard() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local armed = false
		if event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if use.card and use.card:isBasicCard() then armed = true end
		elseif event == sgs.CardResponded then
			armed = true
		end
		if armed then
			if not player:hasFlag("sk_jianwu_armed") then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:setPlayerFlag(player, "sk_jianwu_armed")
			end
		else
			if player:hasFlag("sk_jianwu_armed") then
				room:setPlayerFlag(player, "-sk_jianwu_armed")
			end
		end
		return false
	end,
}

sk_jianwuTM = sgs.CreateTargetModSkillV2{
	name = "#sk_jianwu",
	pattern = "Slash",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not (player and player:hasSkill("sk_jianwu") and player:hasFlag("sk_jianwu_armed")) then return false end
		local mod = ctx:getModType()
		if mod == sgs.TargetModSkill_DistanceLimit or mod == sgs.TargetModSkill_Residue then
			return 9999
		elseif mod == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

extension:insertRelatedSkills("sk_jianwu", "#sk_jianwu")


--[[
	技能名：镇南
	相关武将：SK鲍三娘
	技能描述：每回合限一次，当一名角色使用【杀】或普通锦囊牌指定至少两个目标后，你可以对一名目标角色造成1点伤害。
	引用：sk_zhennan
]]--
sk_zhennan = sgs.CreateTriggerSkillV2{
	name = "sk_zhennan",
	events = {sgs.TargetConfirming},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local use = data:toCardUse()
		if not (use.card and use.from) then return false end
		if not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
		if use.to:length() < 2 then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() and p:getMark("sk_zhennan_used-Clear") == 0 then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local targets = sgs.SPlayerList()
		for _, t in sgs.qlist(use.to) do
			targets:append(t)
		end
		local to = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_zhennan-choose", true, true)
		if to then
			ctx.targets:append(to)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:addPlayerMark(player, "sk_zhennan_used-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		room:damage(sgs.DamageStruct(skill:objectName(), player, target))
		return false
	end,
}


sk_baosanniang:addSkill(sk_jianwu)
sk_baosanniang:addSkill(sk_jianwuTM)
sk_baosanniang:addSkill(sk_zhennan)
sk_baosanniang:addSkill(sk_tongxin)


sgs.LoadTranslationTable{
	["sk_baosanniang"] = "SK鲍三娘",
	["&sk_baosanniang"] = "鲍三娘",
	["sk_jianwu"] = "剑舞",
	[":sk_jianwu"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用基本牌后，若你使用的下一张牌是【杀】，此牌无距离与次数限制且目标上限+1。",
	["sk_zhennan"] = "镇南",
	[":sk_zhennan"] = "每回合限一次，当一名角色使用【杀】或普通锦囊牌指定至少两个目标后，你可以对一名目标角色造成1点伤害。",
	["@sk_zhennan-choose"] = "镇南：你可以对一名目标角色造成1点伤害",
	["designer:sk_baosanniang"] = "极略三国",
    ["illustrator:sk_baosanniang"] = "极略三国",
    ["cv:sk_baosanniang"] = "极略三国",
}


--谯周
sk_qiaozhou = sgs.General(extension, "sk_qiaozhou", "shu", 3, true)


--[[
	技能名：识命
	相关武将：SK谯周
	技能描述：每回合限一次，当一名其他角色获得牌后，若这些牌均为黑色，你可以选择一项：1.获得这些牌；2.将这些牌置于牌堆顶；然后你令其对自己造成X点伤害（X为这些牌的数量）。
	引用：sk_shiming
]]--
sk_shiming = sgs.CreateTriggerSkillV2{
	name = "sk_shiming",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local move = data:toMoveOneTime()
		local to = move.to
		if not (to and to:isAlive() and move.to_place == sgs.Player_PlaceHand
			and move.card_ids:length() > 0) then return false end
		for _, id in sgs.qlist(move.card_ids) do
			if not sgs.Sanguosha:getCard(id):isBlack() then return false end
		end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() and p:objectName() ~= to:objectName()
				and p:getMark("sk_shiming_used-Clear") == 0 then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerMark(player, "sk_shiming_used-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		local move = ctx.original_data:toMoveOneTime()
		local to = move.to
		if not (to and to:isAlive()) then return false end
		local ids = {}
		for _, id in sgs.qlist(move.card_ids) do
			table.insert(ids, id)
		end
		if #ids == 0 then return false end
		local choice = room:askForChoice(player, skill:objectName(), "sk_shiming_obtain+sk_shiming_puttop", ctx.original_data)
		if choice == "sk_shiming_obtain" then
			for _, id in ipairs(ids) do
				room:obtainCard(player, id, false)
			end
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill:objectName(), "")
			for _, id in ipairs(ids) do
				room:moveCardTo(sgs.Sanguosha:getCard(id), to, nil, sgs.Player_DrawPile, reason)
			end
		end
		if to:isAlive() then
			room:damage(sgs.DamageStruct(skill:objectName(), to, to, #ids))
		end
		return false
	end,
}


--[[
	技能名：星卜
	相关武将：SK谯周
	技能描述：准备阶段，你可以展示牌堆顶的三张牌，然后你可以令一名角色获得这些牌并根据其中红色牌数获得效果直到其下一个回合结束：3，摸牌数、手牌上限、攻击范围+3，使用【杀】无次数限制且造成伤害+1；2，摸牌数、手牌上限、攻击范围+2且使用【杀】无次数限制；1，摸牌数、手牌上限、攻击范围和出【杀】次数+1。
	引用：sk_xingbu
]]--
sk_xingbu = sgs.CreateTriggerSkillV2{
	name = "sk_xingbu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local ids = room:getNCards(3, true)
		if ids:isEmpty() then return false end
		local red = 0
		for _, id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):isRed() then red = red + 1 end
		end
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_xingbu-give", true, true)
		if not target then
			for i = ids:length() - 1, 0, -1 do
				room:moveCardTo(sgs.Sanguosha:getCard(ids:at(i)), nil, sgs.Player_DrawPile, false)
			end
			return false
		end
		room:doAnimate(1, player:objectName(), target:objectName())
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, id in sgs.qlist(ids) do
			dummy:addSubcard(id)
		end
		target:obtainCard(dummy)
		dummy:deleteLater()
		if red > 0 then
			room:setPlayerMark(target, "&sk_xingbu_lv", red)
			room:setPlayerMark(target, "sk_xingbu_turns", 0)
			room:addPlayerMark(target, "sk_xingbu_given-Clear")
		end
		return false
	end,
}

sk_xingbu_aux = sgs.CreateTriggerSkillV2{
	name = "#sk_xingbu_aux",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.DrawNCards, sgs.ConfirmDamage},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local lv = player:getMark("&sk_xingbu_lv")
		if lv <= 0 then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("sk_xingbu_given-Clear") == 0 then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and player:getMark("sk_xingbu_turns") > 0 then
				return skill:objectName()
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then return skill:objectName() end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("&sk_xingbu_lv") >= 3
				and damage.card and damage.card:isKindOf("Slash") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local lv = player:getMark("&sk_xingbu_lv")
		if event == sgs.EventPhaseStart then
			room:addPlayerMark(player, "sk_xingbu_turns")
		elseif event == sgs.EventPhaseEnd then
			room:setPlayerMark(player, "&sk_xingbu_lv", 0)
			room:setPlayerMark(player, "sk_xingbu_turns", 0)
		elseif event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			draw.num = draw.num + lv
			ctx.original_data:setValue(draw)
		elseif event == sgs.ConfirmDamage then
			local damage = ctx.original_data:toDamage()
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
		end
		return false
	end,
}

sk_xingbuTM = sgs.CreateTargetModSkillV2{
	name = "#sk_xingbu_tm",
	pattern = "Slash",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not player then return false end
		local lv = player:getMark("&sk_xingbu_lv")
		if lv <= 0 then return false end
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			if lv >= 2 then return 9999 end
			return 1
		end
		return false
	end,
}

sk_xingbuRange = sgs.CreateAttackRangeSkillV2{
	name = "#sk_xingbu_range",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:getMark("&sk_xingbu_lv") > 0 then
			return player:getMark("&sk_xingbu_lv")
		end
		return false
	end,
}

sk_xingbuMax = sgs.CreateMaxCardsSkillV2{
	name = "#sk_xingbu_max",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if player and player:getMark("&sk_xingbu_lv") > 0 then
			return player:getMark("&sk_xingbu_lv")
		end
		return false
	end,
}

local sk_xingbu_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sk_xingbu_aux") then sk_xingbu_skills:append(sk_xingbu_aux) end
if not sgs.Sanguosha:getSkill("#sk_xingbu_tm") then sk_xingbu_skills:append(sk_xingbuTM) end
if not sgs.Sanguosha:getSkill("#sk_xingbu_range") then sk_xingbu_skills:append(sk_xingbuRange) end
if not sgs.Sanguosha:getSkill("#sk_xingbu_max") then sk_xingbu_skills:append(sk_xingbuMax) end
sgs.Sanguosha:addSkills(sk_xingbu_skills)
table.insert(sk_global_skill_names, "#sk_xingbu_aux")


sk_qiaozhou:addSkill(sk_shiming)
sk_qiaozhou:addSkill(sk_xingbu)


sgs.LoadTranslationTable{
	["sk_qiaozhou"] = "SK谯周",
	["&sk_qiaozhou"] = "谯周",
	["sk_shiming"] = "识命",
	[":sk_shiming"] = "每回合限一次，当一名其他角色获得牌后，若这些牌均为黑色，你可以选择一项：1.获得这些牌；2.将这些牌置于牌堆顶；然后你令其对自己造成X点伤害（X为这些牌的数量）。",
	["sk_shiming_obtain"] = "获得这些牌",
	["sk_shiming_puttop"] = "将这些牌置于牌堆顶",
	["sk_xingbu"] = "星卜",
	[":sk_xingbu"] = "准备阶段，你可以展示牌堆顶的三张牌，然后你可以令一名角色获得这些牌并根据其中红色牌数获得效果直到其下一个回合结束：3张，其摸牌数、手牌上限、攻击范围+3且使用【杀】无次数限制、造成伤害+1；2张，其摸牌数、手牌上限、攻击范围+2且使用【杀】无次数限制；1张，其摸牌数、手牌上限、攻击范围和出【杀】次数+1。",
	["@sk_xingbu-give"] = "星卜：你可以令一名角色获得展示的三张牌",
	["&sk_xingbu_lv"] = "星卜",
	["designer:sk_qiaozhou"] = "极略三国",
    ["illustrator:sk_qiaozhou"] = "极略三国",
    ["cv:sk_qiaozhou"] = "极略三国",
}


--孙策
sk_sunce = sgs.General(extension, "sk_sunce", "wu", 4, true)


--[[
	技能名：昂扬
	相关武将：SK孙策
	技能描述：当你使用红色【杀】或【决斗】指定目标后，或当你成为其他角色使用红色【杀】或【决斗】的目标后，
	你可以摸一张牌；若目标角色/使用者判定区内有牌，则你额外摸一张牌。
	引用：sk_angyang
]]--
sk_angyang = sgs.CreateTriggerSkillV2{
	name = "sk_angyang",
	events = {sgs.TargetSpecified, sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.card and use.card:isRed() and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel"))) then
			return false
		end
		if event == sgs.TargetSpecified then
			if use.from and use.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.TargetConfirmed then
			if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local n = 1
		if event == sgs.TargetSpecified then
			for _, t in sgs.qlist(use.to) do
				if not t:getJudgingArea():isEmpty() then n = n + 1 break end
			end
		else
			if use.from and not use.from:getJudgingArea():isEmpty() then n = n + 1 end
		end
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(n, skill:objectName())
		return false
	end,
}


--[[
	技能名：威风
	相关武将：SK孙策
	技能描述：准备阶段，若你手牌数小于体力值，你可以与一名其他角色拼点。若你赢，你摸两张牌；若你没赢，该角色摸两张牌。
	引用：sk_weifeng
]]--
sk_weifeng = sgs.CreateTriggerSkillV2{
	name = "sk_weifeng",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		if player:isKongcheng() or player:getHandcardNum() >= player:getHp() then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		local to = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_weifeng-target", true, true)
		if to then
			ctx.targets:append(to)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, to)
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		room:doAnimate(1, player:objectName(), to:objectName())
		if player:pindian(to, skill:objectName(), nil) then
			player:drawCards(2, skill:objectName())
		else
			to:drawCards(2, skill:objectName())
		end
		return false
	end,
}


sk_sunce:addSkill(sk_angyang)
sk_sunce:addSkill(sk_weifeng)


sgs.LoadTranslationTable{
	["sk_sunce"] = "SK孙策",
	["&sk_sunce"] = "孙策",
	["sk_angyang"] = "昂扬",
	[":sk_angyang"] = "当你使用红色【杀】或【决斗】指定目标后，或当你成为其他角色使用红色【杀】或【决斗】的目标后，你可以摸一张牌；若目标角色/使用者判定区内有牌，则你额外摸一张牌。",
	["sk_weifeng"] = "威风",
	[":sk_weifeng"] = "准备阶段，若你手牌数小于体力值，你可以与一名其他角色拼点。若你赢，你摸两张牌；若你没赢，该角色摸两张牌。",
	["@sk_weifeng-target"] = "威风：你可以与一名其他角色拼点",
	["designer:sk_sunce"] = "极略三国",
    ["illustrator:sk_sunce"] = "极略三国",
    ["cv:sk_sunce"] = "极略三国",
}


--步骘
sk_buzhi = sgs.General(extension, "sk_buzhi", "wu", 3, true)


--[[
	技能名：折节
	相关武将：SK步骘
	技能描述：其他角色的结束阶段，你可以弃置一张手牌，然后令该角色弃置一张牌；若其以此法弃置了装备牌，
	你可以令另一名角色获得此牌。
	引用：sk_zhejie
]]--
sk_zhejie = sgs.CreateTriggerSkillV2{
	name = "sk_zhejie",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Finish then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() and p:objectName() ~= player:objectName() and not p:isKongcheng() then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then return false end
		local card = room:askForCard(player, ".|.|.|hand", "@sk_zhejie-discard:" .. target:objectName(), ctx.original_data, sgs.Card_MethodDiscard)
		return card ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		if target:isNude() then return false end
		local id = room:askForCardChosen(player, target, "he", skill:objectName())
		local card = sgs.Sanguosha:getCard(id)
		local is_equip = card:isKindOf("EquipCard")
		room:throwCard(id, target, target)
		if is_equip then
			local receivers = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(target)) do
				receivers:append(p)
			end
			local receiver = room:askForPlayerChosen(player, receivers, skill:objectName(), "@sk_zhejie-give", true, true)
			if receiver then
				room:obtainCard(receiver, card, true)
			end
		end
		return false
	end,
}


--[[
	技能名：风雅
	相关武将：SK步骘
	技能描述：当你受到伤害时，你可以摸一张牌，然后伤害来源可以摸一张牌并令此伤害-1。
	引用：sk_fengya
]]--
sk_fengya = sgs.CreateTriggerSkillV2{
	name = "sk_fengya",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
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
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		player:drawCards(1, skill:objectName())
		if damage.from and damage.from:isAlive() then
			local _d = sgs.QVariant()
			_d:setValue(damage.to)
			if damage.from:askForSkillInvoke("sk_fengya_reduce", _d) then
				room:notifySkillInvoked(damage.from, "sk_fengya_reduce")
				damage.from:drawCards(1, skill:objectName())
				damage.damage = math.max(0, damage.damage - 1)
				ctx.original_data:setValue(damage)
			end
		end
		return false
	end,
}


sk_buzhi:addSkill(sk_zhejie)
sk_buzhi:addSkill(sk_fengya)


sgs.LoadTranslationTable{
	["sk_buzhi"] = "SK步骘",
	["&sk_buzhi"] = "步骘",
	["sk_zhejie"] = "折节",
	[":sk_zhejie"] = "其他角色的结束阶段，你可以弃置一张手牌，然后令该角色弃置一张牌；若其以此法弃置了装备牌，你可以令另一名角色获得此牌。",
	["@sk_zhejie-discard"] = "折节：你可以弃置一张手牌，令 %src 弃置一张牌",
	["@sk_zhejie-give"] = "折节：你可以令另一名角色获得此装备牌",
	["sk_fengya"] = "风雅",
	[":sk_fengya"] = "当你受到伤害时，你可以摸一张牌，然后伤害来源可以摸一张牌并令此伤害-1。",
	["sk_fengya_reduce"] = "风雅",
	["designer:sk_buzhi"] = "极略三国",
    ["illustrator:sk_buzhi"] = "极略三国",
    ["cv:sk_buzhi"] = "极略三国",
}


--董袭
sk_dongxi = sgs.General(extension, "sk_dongxi", "wu", 4, true)


--[[
	技能名：断缆
	相关武将：SK董袭
	技能描述：出牌阶段限一次，你可以弃置至多三名其他角色区域内的至多共计三张牌，
	然后你弃置一张点数大于这些牌点数和的牌或失去1点体力。
	引用：sk_duanlan, sk_duanlanCard
]]--
sk_duanlanCard = sgs.CreateSkillCard{
	name = "sk_duanlanCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local sum = 0
		for i = 1, 3 do
			local victims = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if not (p:isNude() and p:getJudgingArea():isEmpty()) then victims:append(p) end
			end
			if victims:isEmpty() then break end
			local optional = (i > 1)
			local prompt = (i == 1) and "@sk_duanlan-target" or "@sk_duanlan-more"
			local victim = room:askForPlayerChosen(source, victims, "sk_duanlan", prompt, optional, true)
			if not victim then break end
			local id = room:askForCardChosen(source, victim, "hej", "sk_duanlan")
			sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			room:throwCard(id, victim, source)
		end
		if sum <= 0 then return end
		if sum < 13 then
			local pattern = ".|.|" .. tostring(sum + 1) .. "~13|.|."
			local pay = room:askForCard(source, pattern, "@sk_duanlan-pay:" .. tostring(sum), sgs.QVariant(), sgs.Card_MethodDiscard)
			if pay then return end
		end
		room:loseHp(source, 1, true, source, "sk_duanlan")
	end
}

sk_duanlan = sgs.CreateViewAsSkillV2{
	name = "sk_duanlan",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_duanlanCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_duanlanCard:clone()
	end,
}


sk_dongxi:addSkill(sk_duanlan)


sgs.LoadTranslationTable{
	["sk_dongxi"] = "SK董袭",
	["&sk_dongxi"] = "董袭",
	["sk_duanlan"] = "断缆",
	[":sk_duanlan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置至多三名其他角色区域内的至多共计三张牌，然后你弃置一张点数大于这些牌点数和的牌或失去1点体力。",
	["@sk_duanlan-target"] = "断缆：请选择一名区域内有牌的其他角色，弃置其一张牌",
	["@sk_duanlan-more"] = "断缆：你可以继续弃置一名其他角色区域内的一张牌（至多三张）",
	["@sk_duanlan-pay"] = "断缆：请弃置一张点数大于 %src 的牌，否则失去1点体力",
	["designer:sk_dongxi"] = "极略三国",
    ["illustrator:sk_dongxi"] = "极略三国",
    ["cv:sk_dongxi"] = "极略三国",
}


--朱然
sk_zhuran = sgs.General(extension, "sk_zhuran", "wu", 4, true)


--[[
	技能名：胆守
	相关武将：SK朱然
	技能描述：锁定技，当你成为其他角色使用【杀】的目标后，若你与其均有手牌，你与其拼点。
	若你赢，你摸一张牌，并弃置使用者一张牌；若你没赢，你不能响应此牌。
	引用：sk_danshou
]]--
sk_danshou = sgs.CreateTriggerSkillV2{
	name = "sk_danshou",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from
			and use.from:objectName() ~= player:objectName()
			and use.to:contains(player)
			and not (player:isKongcheng() or use.from:isKongcheng()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		local from = use.from
		if not (from and from:isAlive() and not (player:isKongcheng() or from:isKongcheng())) then return false end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if player:pindian(from, skill:objectName(), nil) then
			player:drawCards(1, skill:objectName())
			if from:getCards("hej"):length() > 0 then
				local id = room:askForCardChosen(player, from, "hej", skill:objectName())
				room:throwCard(id, from, player)
			end
		else
			local no_respond_list = use.no_respond_list
			if not table.contains(no_respond_list, player:objectName()) then
				table.insert(no_respond_list, player:objectName())
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		return false
	end,
}


--[[
	技能名：勇烈
	相关武将：SK朱然
	技能描述：当你或你攻击范围内的一名其他角色受到【杀】造成的伤害后，你可以失去1点体力并对伤害来源造成1点伤害。
	引用：sk_yonglie
]]--
sk_yonglie = sgs.CreateTriggerSkillV2{
	name = "sk_yonglie",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if not (damage.card and damage.card:isKindOf("Slash") and damage.to) then return false end
		if damage.to:objectName() == player:objectName() or player:inMyAttackRange(damage.to) then
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
		room:notifySkillInvoked(player, skill:objectName())
		room:loseHp(player, 1, true, player, skill:objectName())
		if player:isAlive() and damage.from and damage.from:isAlive() then
			room:damage(sgs.DamageStruct(skill:objectName(), player, damage.from))
		end
		return false
	end,
}


sk_zhuran:addSkill(sk_danshou)
sk_zhuran:addSkill(sk_yonglie)


sgs.LoadTranslationTable{
	["sk_zhuran"] = "SK朱然",
	["&sk_zhuran"] = "朱然",
	["sk_danshou"] = "胆守",
	[":sk_danshou"] = "<font color=\"blue\"><b>锁定技，</b></font>当你成为其他角色使用【杀】的目标后，若你与其均有手牌，你与其拼点。若你赢，你摸一张牌，并弃置使用者一张牌；若你没赢，你不能响应此牌。",
	["sk_yonglie"] = "勇烈",
	[":sk_yonglie"] = "当你或你攻击范围内的一名其他角色受到【杀】造成的伤害后，你可以失去1点体力并对伤害来源造成1点伤害。",
	["designer:sk_zhuran"] = "极略三国",
    ["illustrator:sk_zhuran"] = "极略三国",
    ["cv:sk_zhuran"] = "极略三国",
}


--丁奉
sk_dingfeng = sgs.General(extension, "sk_dingfeng", "wu", 4, true)


--[[
	技能名：搏战
	相关武将：SK丁奉
	技能描述：当你使用的【杀】结算后，或指定你为目标的【杀】结算后，若此牌未造成伤害，
	此牌的目标角色可以对使用者使用一张【杀】。
	引用：sk_bozhan
]]--
sk_bozhan = sgs.CreateTriggerSkillV2{
	name = "sk_bozhan",
	events = {sgs.CardFinished, sgs.DamageCaused},
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.DamageCaused then
			local damage = ctx.original_data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				damage.card:setTag("sk_bozhan_damaged", sgs.QVariant(true))
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.CardFinished then return false end
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.card and use.card:isKindOf("Slash") and use.from) then return false end
		if use.card:getTag("sk_bozhan_damaged"):toBool() then return false end
		if use.from:objectName() == player:objectName() or use.to:contains(player) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if not (use.from and use.from:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		for _, t in sgs.qlist(use.to) do
			if t:isAlive() and t:objectName() ~= use.from:objectName() and t:canSlash(use.from, nil, true) then
				room:doAnimate(1, t:objectName(), use.from:objectName())
				room:askForUseSlashTo(t, use.from, "@sk_bozhan-slash:" .. use.from:objectName())
			end
		end
		return false
	end,
}


--[[
	技能名：轻袭
	相关武将：SK丁奉
	技能描述：锁定技，当你使用【杀】指定唯一目标后，若你装备区的牌数小于该角色，其不能响应此牌。
	引用：sk_qingxi
]]--
sk_qingxi = sgs.CreateTriggerSkillV2{
	name = "sk_qingxi",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from
			and use.from:objectName() == player:objectName()
			and use.to:length() == 1 then
			for _, t in sgs.qlist(use.to) do
				if t and t:isAlive() and player:getEquips():length() < t:getEquips():length() then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local no_respond_list = use.no_respond_list
		for _, t in sgs.qlist(use.to) do
			if not table.contains(no_respond_list, t:objectName()) then
				table.insert(no_respond_list, t:objectName())
			end
		end
		use.no_respond_list = no_respond_list
		data:setValue(use)
		return false
	end,
}


sk_dingfeng:addSkill(sk_bozhan)
sk_dingfeng:addSkill(sk_qingxi)


sgs.LoadTranslationTable{
	["sk_dingfeng"] = "SK丁奉",
	["&sk_dingfeng"] = "丁奉",
	["sk_bozhan"] = "搏战",
	[":sk_bozhan"] = "当你使用的【杀】结算后，或指定你为目标的【杀】结算后，若此牌未造成伤害，此牌的目标角色可以对使用者使用一张【杀】。",
	["@sk_bozhan-slash"] = "搏战：你可以对 %src 使用一张【杀】",
	["sk_qingxi"] = "轻袭",
	[":sk_qingxi"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】指定唯一目标后，若你装备区的牌数小于该角色，其不能响应此牌。",
	["designer:sk_dingfeng"] = "极略三国",
    ["illustrator:sk_dingfeng"] = "极略三国",
    ["cv:sk_dingfeng"] = "极略三国",
}


--蒋钦
sk_jiangqin = sgs.General(extension, "sk_jiangqin", "wu", 4, true)


--[[
	技能名：尚义
	相关武将：SK蒋钦
	技能描述：出牌阶段限一次，你可以令一名其他角色观看你的手牌，然后你选择一项：
	1.观看其身份牌；2.观看其手牌，然后你可以弃置其中一张黑色牌。
	引用：sk_shangyi, sk_shangyiCard
]]--
sk_shangyiCard = sgs.CreateSkillCard{
	name = "sk_shangyiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not source:isKongcheng() then
			room:doGongxin(target, source, sgs.IntList(), "sk_shangyi")
		end
		local choice = room:askForChoice(source, "sk_shangyi", "shangyi_role+shangyi_hand")
		if choice == "shangyi_role" then
			local log = sgs.LogMessage()
			log.type = "#sk_shangyi_role"
			log.from = target
			log.arg = sgs.Sanguosha:translate(target:getRole())
			room:sendLog(log, source)
		elseif not target:isKongcheng() then
			local blacks = sgs.IntList()
			for _, c in sgs.qlist(target:getHandcards()) do
				if c:isBlack() then blacks:append(c:getEffectiveId()) end
			end
			local id = room:doGongxin(source, target, blacks, "sk_shangyi")
			if id >= 0 then
				room:throwCard(id, target, source)
			end
		end
	end,
}

sk_shangyi = sgs.CreateViewAsSkillV2{
	name = "sk_shangyi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_shangyiCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_shangyiCard:clone()
	end,
}


--[[
	技能名：忘私
	相关武将：SK蒋钦
	技能描述：当你受到伤害时，你可以观看伤害来源的手牌，然后弃置其中一张红色牌。
	引用：sk_wangsi
]]--
sk_wangsi = sgs.CreateTriggerSkillV2{
	name = "sk_wangsi",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName()
			and damage.from and not damage.from:isKongcheng() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local from = damage.from
		if not (from and from:isAlive() and not from:isKongcheng()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local reds = sgs.IntList()
		for _, c in sgs.qlist(from:getHandcards()) do
			if c:isRed() then reds:append(c:getEffectiveId()) end
		end
		local id = room:doGongxin(player, from, reds, skill:objectName())
		if id >= 0 then
			room:throwCard(id, from, player)
		end
		return false
	end,
}


sk_jiangqin:addSkill(sk_shangyi)
sk_jiangqin:addSkill(sk_wangsi)


sgs.LoadTranslationTable{
	["sk_jiangqin"] = "SK蒋钦",
	["&sk_jiangqin"] = "蒋钦",
	["sk_shangyi"] = "尚义",
	[":sk_shangyi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色观看你的手牌，然后你选择一项：1.观看其身份牌；2.观看其手牌，然后你可以弃置其中一张黑色牌。",
	["~sk_shangyiCard"] = "选择一名其他角色→点击“确定”",
	["shangyi_role"] = "观看其身份牌",
	["shangyi_hand"] = "观看其手牌并弃置其中一张黑色牌",
	["#sk_shangyi_role"] = "%from 的身份为 %arg",
	["sk_wangsi"] = "忘私",
	[":sk_wangsi"] = "当你受到伤害时，你可以观看伤害来源的手牌，然后弃置其中一张红色牌。",
	["designer:sk_jiangqin"] = "极略三国",
    ["illustrator:sk_jiangqin"] = "极略三国",
    ["cv:sk_jiangqin"] = "极略三国",
}


--周泰
sk_zhoutai = sgs.General(extension, "sk_zhoutai", "wu", 4, true)


--[[
	技能名：不屈
	相关武将：SK周泰
	技能描述：锁定技，当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上，称为“创”，若此“创”与其他的“创”点数均不相同，你将体力回复至1点，否则你将此“创”置入弃牌堆。若你有“创”，则你的手牌上限为“创”数。
	引用：sk_buqu, #sk_buqu
]]--
sk_buqu = sgs.CreateTriggerSkillV2{
	name = "sk_buqu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() and player:getHp() < 1 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		if not (dying.who and dying.who:objectName() == player:objectName()) or player:getHp() > 0 then
			return false
		end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local id = room:drawCard()
		local card = sgs.Sanguosha:getCard(id)
		local msg = sgs.LogMessage()
		msg.type = "#sk_buquShow"
		msg.from = player
		msg.card_str = card:toString()
		room:sendLog(msg)
		local duplicate = false
		for _, cid in sgs.qlist(player:getPile("sk_chuang")) do
			if sgs.Sanguosha:getCard(cid):getNumber() == card:getNumber() then
				duplicate = true
				break
			end
		end
		player:addToPile("sk_chuang", id, true)
		if duplicate then
			local move = sgs.CardsMoveStruct()
			move.card_ids:append(id)
			move.to = nil
			move.to_place = sgs.Player_DiscardPile
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), skill:objectName(), "")
			room:moveCardsAtomic(move, true)
		elseif player:getHp() < 1 then
			local rec = sgs.RecoverStruct()
			rec.recover = 1 - player:getHp()
			rec.who = player
			room:recover(player, rec)
		end
		return false
	end,
}

sk_buquMax = sgs.CreateMaxCardsSkillV2{
	name = "#sk_buqu",
	holder_selector = sgs.CorrectSkill_Primary,
	fixed_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("sk_buqu") then
			local n = target:getPile("sk_chuang"):length()
			if n > 0 then return n end
		end
		return false
	end,
}

extension:insertRelatedSkills("sk_buqu", "#sk_buqu")


--[[
	技能名：奋激
	相关武将：SK周泰
	技能描述：当一名角色成为【杀】的目标后，你可以失去1点体力，令其摸两张牌。
	引用：sk_fenji
]]--
sk_fenji = sgs.CreateTriggerSkillV2{
	name = "sk_fenji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local use = data:toCardUse()
		if not (use.card and use.card:isKindOf("Slash") and use.to:contains(player)) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not target then return false end
		local _data = sgs.QVariant()
		_data:setValue(target)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		room:broadcastSkillInvoke(skill:objectName())
		if target then
			room:doAnimate(1, player:objectName(), target:objectName())
		end
		room:loseHp(player, 1, true, player, skill:objectName())
		if target and target:isAlive() then
			target:drawCards(2, skill:objectName())
		end
		return false
	end,
}


sk_zhoutai:addSkill(sk_buqu)
sk_zhoutai:addSkill(sk_buquMax)
sk_zhoutai:addSkill(sk_fenji)


sgs.LoadTranslationTable{
	["sk_zhoutai"] = "SK周泰",
	["&sk_zhoutai"] = "周泰",
	["#sk_zhoutai"] = "历战之躯",
	["sk_buqu"] = "不屈",
	[":sk_buqu"] = "<font color=\"blue\"><b>锁定技。</b></font>当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上，称为“创”，若此“创”与其他的“创”点数均不相同，你将体力回复至1点，否则你将此“创”置入弃牌堆。若你有“创”，则你的手牌上限为“创”数。",
	["#sk_buquShow"] = " %from 展示了 %card",
	["sk_chuang"] = "创",
	["sk_fenji"] = "奋激",
	[":sk_fenji"] = "当一名角色成为【杀】的目标后，你可以失去1点体力，令其摸两张牌。",
	["designer:sk_zhoutai"] = "极略三国",
	["illustrator:sk_zhoutai"] = "极略三国",
	["cv:sk_zhoutai"] = "极略三国",
}


--陆绩
sk_luji = sgs.General(extension, "sk_luji", "wu", 3, true)


--[[
	技能名：怀橘
	相关武将：SK陆绩
	技能描述：你的任意阶段结束时，若你的手牌数为3，你可以摸一张牌或者弃置两张牌。
	引用：sk_huaiju
]]--
sk_huaiju = sgs.CreateTriggerSkillV2{
	name = "sk_huaiju",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getHandcardNum() == 3 then return skill:objectName() end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getHandcardNum() ~= 3 then return false end
		room:broadcastSkillInvoke(skill:objectName())
		local choice = room:askForChoice(player, skill:objectName(), "huaiju_draw+huaiju_discard", ctx.original_data)
		if choice == "huaiju_draw" then
			player:drawCards(1, skill:objectName())
		else
			room:askForDiscard(player, skill:objectName(), 2, 2, false, true)
		end
		return false
	end,
}


--[[
	技能名：浑天
	相关武将：SK陆绩
	技能描述：当你的牌因弃置而进入弃牌堆时，你可以将其中任意数量的牌置于牌堆顶，然后从牌堆随机获得一张与这些牌类别均不同的牌。
	引用：sk_huntian
]]--
sk_huntian = sgs.CreateTriggerSkillV2{
	name = "sk_huntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if not (move.from and move.from:objectName() == player:objectName()
			and move.to_place == sgs.Player_DiscardPile
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			return false
		end
		local i = 0
		for _, card_id in sgs.qlist(move.card_ids) do
			local place = move.from_places:at(i)
			if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
				return skill:objectName()
			end
			i = i + 1
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local ids = sgs.IntList()
		local i = 0
		for _, card_id in sgs.qlist(move.card_ids) do
			local place = move.from_places:at(i)
			if (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip)
				and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				ids:append(card_id)
			end
			i = i + 1
		end
		if ids:isEmpty() then return false end
		room:broadcastSkillInvoke(skill:objectName())
		local chosen = {}
		local first = true
		while not ids:isEmpty() do
			room:fillAG(ids, player)
			local id = room:askForAG(player, ids, true, first and "sk_huntian" or "sk_huntian_more")
			room:clearAG()
			first = false
			if id < 0 then break end
			table.insert(chosen, id)
			ids:removeOne(id)
			room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile, false)
		end
		if #chosen == 0 then return false end
		local types = {}
		for _, id in ipairs(chosen) do
			types[sgs.Sanguosha:getCard(id):getTypeId()] = true
		end
		local candidates = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if not types[sgs.Sanguosha:getCard(id):getTypeId()] then
				table.insert(candidates, id)
			end
		end
		if #candidates > 0 then
			room:obtainCard(player, candidates[math.random(1, #candidates)], false)
		end
		return false
	end,
}


sk_luji:addSkill(sk_huaiju)
sk_luji:addSkill(sk_huntian)


sgs.LoadTranslationTable{
	["sk_luji"] = "SK陆绩",
	["&sk_luji"] = "陆绩",
	["#sk_luji"] = "瑚琏之器",
	["sk_huaiju"] = "怀橘",
	[":sk_huaiju"] = "你的任意阶段结束时，若你的手牌数为3，你可以摸一张牌或者弃置两张牌。",
	["huaiju_draw"] = "摸一张牌",
	["huaiju_discard"] = "弃置两张牌",
	["sk_huntian"] = "浑天",
	[":sk_huntian"] = "当你的牌因弃置而进入弃牌堆时，你可以将其中任意数量的牌置于牌堆顶，然后从牌堆随机获得一张与这些牌类别均不同的牌。",
	["sk_huntian_more"] = "浑天：你可以继续将其中弃置的牌置于牌堆顶",
	["designer:sk_luji"] = "极略三国",
	["illustrator:sk_luji"] = "极略三国",
	["cv:sk_luji"] = "极略三国",
}


--诸葛瑾
sk_zhugejin = sgs.General(extension, "sk_zhugejin", "wu", 3, true)


--[[
	技能名：缓兵
	相关武将：SK诸葛瑾
	技能描述：锁定技，当你成为【杀】的目标时，你令此【杀】无效，然后将之置于你的武将牌上，称为“缓”。回合开始阶段，若你有“缓”，你选择其中一张并判定：若为红色，你摸一张牌，然后将该“缓”置入弃牌堆；若为黑色，你失去1点体力，然后获得该“缓”。你重复此流程直到你没有“缓”。
	引用：sk_huanbing
]]--
sk_huanbing = sgs.CreateTriggerSkillV2{
	name = "sk_huanbing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and not player:getPile("sk_huan"):isEmpty() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.TargetConfirmed then
			local data = ctx.original_data
			local use = data:toCardUse()
			if not (use.card and use.to:contains(player)) then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			use.to:removeOne(player)
			data:setValue(use)
			if use.card:isVirtualCard() then
				for _, id in sgs.qlist(use.card:getSubcards()) do
					player:addToPile("sk_huan", id, true)
				end
			else
				player:addToPile("sk_huan", use.card:getEffectiveId(), true)
			end
		elseif event == sgs.EventPhaseStart then
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			while player:isAlive() and not player:getPile("sk_huan"):isEmpty() do
				local pile = player:getPile("sk_huan")
				room:fillAG(pile, player)
				local id = room:askForAG(player, pile, false, skill:objectName())
				room:clearAG()
				if id < 0 then id = pile:first() end
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.reason = skill:objectName()
				judge.pattern = ".|red"
				judge.play_animation = false
				room:judge(judge)
				if judge:isGood() then
					player:drawCards(1, skill:objectName())
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(id)
					move.to = nil
					move.to_place = sgs.Player_DiscardPile
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), skill:objectName(), "")
					room:moveCardsAtomic(move, true)
				else
					room:loseHp(player, 1, true, player, skill:objectName())
					if player:isAlive() then
						player:obtainCard(sgs.Sanguosha:getCard(id))
					end
				end
			end
		end
		return false
	end,
}


--[[
	技能名：弘援
	相关武将：SK诸葛瑾
	技能描述：出牌阶段限一次，你可以弃置至多X张牌并选择一名角色，然后该角色获得场上等量的牌（X为你已损失的体力值）。
	引用：sk_hongyuan, sk_hongyuanCard
]]--
sk_hongyuanCard = sgs.CreateSkillCard{
	name = "sk_hongyuanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	feasible = function(self, targets, player)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local n = self:subcardsLength()
		for i = 1, n do
			local fields = sgs.IntList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				for _, c in sgs.qlist(p:getCards("ej")) do
					fields:append(c:getEffectiveId())
				end
			end
			if fields:isEmpty() then break end
			room:fillAG(fields, target)
			local id = room:askForAG(target, fields, false, "sk_hongyuan")
			room:clearAG()
			if id < 0 then break end
			room:obtainCard(target, id, true)
		end
	end,
}

sk_hongyuan = sgs.CreateViewAsSkillV2{
	name = "sk_hongyuan",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getLostHp() > 0 and not player:isNude()
			and not (player:hasUsed("#sk_hongyuanCard") or player:hasUsed(skill:objectName()))
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not player then return false end
		return request:getSelectedCardIds():length() < player:getLostHp()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local card = sk_hongyuanCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}


sk_zhugejin:addSkill(sk_huanbing)
sk_zhugejin:addSkill(sk_hongyuan)


sgs.LoadTranslationTable{
	["sk_zhugejin"] = "SK诸葛瑾",
	["&sk_zhugejin"] = "诸葛瑾",
	["#sk_zhugejin"] = "联盟的维系者",
	["sk_huanbing"] = "缓兵",
	[":sk_huanbing"] = "<font color=\"blue\"><b>锁定技。</b></font>当你成为【杀】的目标时，你令此【杀】无效，然后将之置于你的武将牌上，称为“缓”。回合开始阶段，若你有“缓”，你选择其中一张并判定：若为红色，你摸一张牌，然后将该“缓”置入弃牌堆；若为黑色，你失去1点体力，然后获得该“缓”。你重复此流程直到你没有“缓”。",
	["sk_huan"] = "缓",
	["sk_hongyuan"] = "弘援",
	[":sk_hongyuan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置至多X张牌并选择一名角色，然后该角色获得场上等量的牌（X为你已损失的体力值）。",
	["~sk_hongyuanCard"] = "选择至多X张牌→选择一名角色→点击“确定”",
	["designer:sk_zhugejin"] = "极略三国",
	["illustrator:sk_zhugejin"] = "极略三国",
	["cv:sk_zhugejin"] = "极略三国",
}


--徐氏
sk_xushi = sgs.General(extension, "sk_xushi", "wu", 3, false)


--[[
	技能名：问卦
	相关武将：SK徐氏
	技能描述：其他角色的准备阶段，其可以交给你一张牌，然后你可以将一张牌置于牌堆底，你与其各摸一张牌。准备阶段，你可以将一张牌置于牌堆底，然后摸两张牌。
	引用：sk_wengua
]]--
sk_wengua = sgs.CreateTriggerSkillV2{
	name = "sk_wengua",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start then return false end
		local names, owners = {}, {}
		for _, xushi in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if xushi:isAlive() and (xushi:objectName() == player:objectName() or not player:isKongcheng()) then
				table.insert(names, skill:objectName())
				table.insert(owners, xushi:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		if invoker:objectName() == player:objectName() then
			local c = room:askForExchange(player, skill:objectName(), 1, 1, true, "@sk_wengua-self", true, ".")
			if not c then return false end
			ctx.extra_data:setValue("self:" .. c:getSubcards():first())
		else
			local c = room:askForExchange(invoker, skill:objectName(), 1, 1, false, "@sk_wengua-give:" .. player:objectName(), true)
			if not c then return false end
			ctx.extra_data:setValue("other:" .. c:getSubcards():first())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		local info = ctx.extra_data:toString()
		room:broadcastSkillInvoke(skill:objectName())
		if string.sub(info, 1, 5) == "self:" then
			local id = tonumber(string.sub(info, 6))
			room:moveCardsInToDrawpile(player, id, skill:objectName(), room:getDrawPile():length())
			player:drawCards(2, skill:objectName())
		else
			local id = tonumber(string.sub(info, 7))
			room:doAnimate(1, invoker:objectName(), player:objectName())
			room:obtainCard(player, id, false)
			if player:isNude() then return false end
			local c = room:askForExchange(player, skill:objectName(), 1, 1, true, "@sk_wengua-put", true, ".")
			if not c then return false end
			room:moveCardsInToDrawpile(player, c:getSubcards():first(), skill:objectName(), room:getDrawPile():length())
			player:drawCards(1, skill:objectName())
			if invoker:isAlive() then invoker:drawCards(1, skill:objectName()) end
		end
		return false
	end,
}


--[[
	技能名：伏诛
	相关武将：SK徐氏
	技能描述：限定技，出牌阶段，你可以选择一名其他角色，然后展示牌堆底的一张牌，若此牌为黑色，你将此牌当无次数与距离限制的【杀】对其使用；你重复此流程。
	引用：sk_fuzhu, sk_fuzhuCard
]]--
sk_fuzhuCard = sgs.CreateSkillCard{
	name = "sk_fuzhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		source:loseMark("@fuzhu")
		while source:isAlive() and target and target:isAlive() do
			if room:getDrawPile():isEmpty() then room:swapPile() end
			local pile = sgs.QList2Table(room:getDrawPile())
			if #pile == 0 then break end
			local bottom_id = pile[#pile]
			local ids = sgs.IntList()
			ids:append(bottom_id)
			room:fillAG(ids)
			room:getThread():delay(750)
			room:clearAG()
			local card = sgs.Sanguosha:getCard(bottom_id)
			if not card or not card:isBlack() then break end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:addSubcard(bottom_id)
			slash:setSkillName("sk_fuzhu")
			local card_use = sgs.CardUseStruct()
			card_use.from = source
			card_use.card = slash
			card_use.to:append(target)
			card_use.m_addHistory = false
			room:useCard(card_use, false)
			slash:deleteLater()
		end
	end,
}

sk_fuzhuVS = sgs.CreateViewAsSkillV2{
	name = "sk_fuzhu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@fuzhu") > 0 and not (player:hasUsed("#sk_fuzhuCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_fuzhuCard:clone()
	end,
}

sk_fuzhu = sgs.CreateTriggerSkillV2{
	name = "sk_fuzhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fuzhu",
	view_as_skill = sk_fuzhuVS,
	events = {},
}


sk_xushi:addSkill(sk_wengua)
sk_xushi:addSkill(sk_fuzhu)


sgs.LoadTranslationTable{
	["sk_xushi"] = "SK徐氏",
	["&sk_xushi"] = "徐氏",
	["#sk_xushi"] = "节义双全",
	["sk_wengua"] = "问卦",
	[":sk_wengua"] = "其他角色的准备阶段，其可以交给你一张牌，然后你可以将一张牌置于牌堆底，你与其各摸一张牌。准备阶段，你可以将一张牌置于牌堆底，然后摸两张牌。",
	["@sk_wengua-give"] = "问卦：你可以交给%src一张牌，然后其可以将一张牌置于牌堆底，你与其各摸一张牌",
	["@sk_wengua-self"] = "问卦：你可以将一张牌置于牌堆底，然后摸两张牌",
	["@sk_wengua-put"] = "问卦：你可以将一张牌置于牌堆底，然后你与其各摸一张牌",
	["sk_fuzhu"] = "伏诛",
	["@fuzhu"] = "伏诛",
	[":sk_fuzhu"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以选择一名其他角色，然后展示牌堆底的一张牌，若此牌为黑色，你将此牌当无次数与距离限制的【杀】对其使用；你重复此流程。",
	["~sk_fuzhuCard"] = "选择一名其他角色→点击“确定”",
	["designer:sk_xushi"] = "极略三国",
	["illustrator:sk_xushi"] = "极略三国",
	["cv:sk_xushi"] = "极略三国",
}


--周妃
sk_zhoufei = sgs.General(extension, "sk_zhoufei", "wu", 3, false)


--[[
	技能名：姻缘
	相关武将：SK周妃
	技能描述：结束阶段，你可以令一名角色随机获得牌堆中的一张红桃牌；若你首次以此法选择该角色，你也如此做。
	引用：sk_yinyuan
]]--
sk_yinyuan = sgs.CreateTriggerSkillV2{
	name = "sk_yinyuan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Finish then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_yinyuan-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local hearts = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
				table.insert(hearts, id)
			end
		end
		if #hearts > 0 then
			room:obtainCard(target, hearts[math.random(1, #hearts)], false)
		end
		if target:getMark("sk_yinyuan_chosen") > 0 then return false end
		room:setPlayerMark(target, "sk_yinyuan_chosen", 1)
		if room:getDrawPile():isEmpty() then room:swapPile() end
		hearts = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
				table.insert(hearts, id)
			end
		end
		if #hearts > 0 then
			room:obtainCard(player, hearts[math.random(1, #hearts)], false)
		end
		return false
	end,
}


--[[
	技能名：箜篌
	相关武将：SK周妃
	技能描述：当其他角色于其出牌阶段使用使用第一/二张牌时，若此牌是普通锦囊牌/基本牌，你可以弃置一张牌，然后令此牌无效。
	引用：sk_konghou
]]--
sk_konghou = sgs.CreateTriggerSkillV2{
	name = "sk_konghou",
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local names, owners = {}, {}
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if not (use.card and use.from and use.from:isAlive() and use.from:getPhase() == sgs.Player_Play) then return false end
			if use.card:isKindOf("SkillCard") then return false end
			for _, zhoufei in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if zhoufei:isAlive() and use.from:objectName() ~= zhoufei:objectName() then
					table.insert(names, skill:objectName())
					table.insert(owners, zhoufei:objectName())
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play or player:getMark("sk_konghou_cnt-Clear") == 0 then return false end
			for _, zhoufei in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if zhoufei:isAlive() then
					table.insert(names, skill:objectName())
					table.insert(owners, zhoufei:objectName())
				end
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local invoker = ctx.invoker
			if invoker then room:setPlayerMark(invoker, "sk_konghou_cnt-Clear", 0) end
			return false
		end
		local use = ctx.original_data:toCardUse()
		if not (use.card and use.from) then return false end
		local user = use.from
		room:addPlayerMark(user, "sk_konghou_cnt-Clear")
		local n = user:getMark("sk_konghou_cnt-Clear")
		local card = use.card
		local qualifies = (n == 1 and card:isNDTrick()) or (n == 2 and card:isKindOf("BasicCard"))
		if not (qualifies and player:isAlive() and user:isAlive() and not player:isNude()) then return false end
		local prompt = string.format("@sk_konghou-discard:%s:%s", user:objectName(), card:objectName())
		local cc = room:askForCard(player, ".", prompt, ctx.original_data, sgs.Card_MethodDiscard)
		if not cc then return false end
		local log = sgs.LogMessage()
		log.type = "#InvokeSkill"
		log.from = player
		log.arg = skill:objectName()
		room:sendLog(log)
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local nullified_list = use.nullified_list
		for _, t in sgs.qlist(use.to) do
			table.insert(nullified_list, t:objectName())
		end
		use.nullified_list = nullified_list
		ctx.original_data:setValue(use)
		return false
	end,
}


sk_zhoufei:addSkill(sk_yinyuan)
sk_zhoufei:addSkill(sk_konghou)


sgs.LoadTranslationTable{
	["sk_zhoufei"] = "SK周妃",
	["&sk_zhoufei"] = "周妃",
	["#sk_zhoufei"] = "软玉温香",
	["sk_yinyuan"] = "姻缘",
	[":sk_yinyuan"] = "结束阶段，你可以令一名角色随机获得牌堆中的一张红桃牌；若你首次以此法选择该角色，你也如此做。",
	["@sk_yinyuan-choose"] = "姻缘：你可以令一名角色随机获得牌堆中的一张红桃牌",
	["sk_konghou"] = "箜篌",
	[":sk_konghou"] = "当其他角色于其出牌阶段使用使用第一/二张牌时，若此牌是普通锦囊牌/基本牌，你可以弃置一张牌，然后令此牌无效。",
	["@sk_konghou-discard"] = "箜篌：你可以弃置一张牌，令 %src 使用的 %dest 无效",
	["designer:sk_zhoufei"] = "极略三国",
	["illustrator:sk_zhoufei"] = "极略三国",
	["cv:sk_zhoufei"] = "极略三国",
}


--潘淑
sk_panshu = sgs.General(extension, "sk_panshu", "wu", 3, false)


--[[
	技能名：锦织
	相关武将：SK潘淑
	技能描述：每轮限四次，你可以将所有手牌当一张本轮未以此法使用过的基本牌或普通锦囊牌使用，然后摸X张牌（X为你本轮发动“锦织”的次数）。
	引用：sk_jinzhi
]]--
local function sk_jinzhi_nameok(player, name)
	if not name or name == "" then return false end
	local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
	if not card then return false end
	local ok = card:isKindOf("BasicCard") or card:isNDTrick()
	card:deleteLater()
	if not ok then return false end
	return player:getMark("sk_jinzhi:" .. name .. "_lun") == 0
end

local function sk_jinzhi_hasname(player)
	if player:getMark("sk_jinzhi_lun") >= 4 then return false end
	for _, cn in ipairs(sgs.Sanguosha:getCardNames("BasicCard+TrickCard+^DelayedTrick")) do
		if player:getMark("sk_jinzhi:" .. cn .. "_lun") == 0 then
			local c = sgs.Sanguosha:cloneCard(cn)
			local ok = c and c:isAvailable(player)
			if c then c:deleteLater() end
			if ok then return true end
		end
	end
	return false
end

local function sk_jinzhi_buildcard(player, name)
	local use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
	if not use_card then return nil end
	for _, id in sgs.qlist(player:handCards()) do
		use_card:addSubcard(id)
	end
	use_card:setSkillName("sk_jinzhi")
	use_card:deleteLater()
	return use_card
end

local function sk_jinzhi_pickname(room, player, name)
	if not name or name == "" then return nil end
	if name == "slash" then
		return room:askForChoice(player, "sk_jinzhi_slash", table.concat(sgs.Sanguosha:getSlashNames(), "+"))
	end
	return name
end

sk_jinzhiCard = sgs.CreateSkillCard{
	name = "sk_jinzhi",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = nil
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local user_str = self:getUserString()
			if user_str ~= "" then
				card = sgs.Sanguosha:cloneCard(user_str:split("+")[1])
			end
		else
			card = player:getTag("sk_jinzhi"):toCard()
		end
		return card and card:targetFilter(plist, to_select, player) and not player:isProhibited(to_select, card, plist)
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = nil
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local user_str = self:getUserString()
			if user_str ~= "" then
				card = sgs.Sanguosha:cloneCard(user_str:split("+")[1])
			end
		else
			card = sgs.Self:getTag("sk_jinzhi"):toCard()
		end
		return card and card:targetFixed()
	end,
	feasible = function(self, targets, player)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = nil
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local user_str = self:getUserString()
			if user_str ~= "" then
				card = sgs.Sanguosha:cloneCard(user_str:split("+")[1])
			end
		else
			card = player:getTag("sk_jinzhi"):toCard()
		end
		return card and card:targetsFeasible(plist, player) and card:isAvailable(player)
			and (card:isKindOf("BasicCard") or card:isNDTrick())
			and player:getMark("sk_jinzhi:" .. card:objectName() .. "_lun") == 0
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local name = self:getUserString()
		if name == "" then
			local dc = player:getTag("sk_jinzhi"):toCard()
			if dc then name = dc:objectName() end
		end
		name = sk_jinzhi_pickname(room, player, name)
		if not (name and sk_jinzhi_nameok(player, name)) then return nil end
		return sk_jinzhi_buildcard(player, name)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local name = self:getUserString()
		if name and name:find("+") then
			local valids = {}
			for _, cn in ipairs(name:split("+")) do
				if sk_jinzhi_nameok(user, cn) then table.insert(valids, cn) end
			end
			if #valids == 0 then return nil end
			name = room:askForChoice(user, "sk_jinzhi", table.concat(valids, "+"))
		end
		name = sk_jinzhi_pickname(room, user, name)
		if not (name and sk_jinzhi_nameok(user, name)) then return nil end
		return sk_jinzhi_buildcard(user, name)
	end,
}

sk_jinzhiVS = sgs.CreateViewAsSkillV2{
	name = "sk_jinzhi",
	n = 0,
	guhuo_type = "l",
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() or player:isKongcheng() then return false end
		if player:getMark("sk_jinzhi_lun") >= 4 then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sk_jinzhi_hasname(player)
		end
		local pattern = request:getPattern()
		if not pattern or pattern == "" then return false end
		local name = pattern:split("+")[1]
		if pattern == "peach+analeptic" and player:getMark("Global_PreventPeach") > 0 then
			name = "analeptic"
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return sk_jinzhi_nameok(player, name)
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return (name == "peach" or name == "analeptic" or name == "nullification")
				and sk_jinzhi_nameok(player, name)
		end
		return false
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local acard = sk_jinzhiCard:clone()
		acard:setSkillName(skill:objectName())
		local reason = request:getReason()
		local name
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			name = request:getPattern()
		else
			local dc = player:getTag("sk_jinzhi"):toCard()
			if dc then name = dc:objectName() end
			if not name or name == "" then name = request:getUserString() end
		end
		if not name or name == "" then return nil end
		acard:setUserString(name)
		return acard
	end,
}
sk_jinzhiVS.response_pattern = "nullification"

sk_jinzhi = sgs.CreateTriggerSkillV2{
	name = "sk_jinzhi",
	view_as_skill = sk_jinzhiVS,
	guhuo_type = "l",
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not (use.card and use.from and use.from:objectName() == player:objectName()) then return false end
		if not table.contains(use.card:getSkillNames(), skill:objectName()) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if not use.card then return false end
		room:addPlayerMark(player, "sk_jinzhi_lun")
		room:addPlayerMark(player, "sk_jinzhi:" .. use.card:objectName() .. "_lun")
		room:broadcastSkillInvoke(skill:objectName())
		player:drawCards(player:getMark("sk_jinzhi_lun"), skill:objectName())
		return false
	end,
}


--[[
	技能名：鱼忧
	相关武将：SK潘淑
	技能描述：锁定技，当你一次性获得不少于两张牌后，你保留其中一张并弃置其余牌，然后你可以令一名其他男性角色选择一项：1.弃置等量的牌；2.失去1点体力。
	引用：sk_yuyou
]]--
sk_yuyou = sgs.CreateTriggerSkillV2{
	name = "sk_yuyou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local move = data:toMoveOneTime()
		if not (move.to and move.to:objectName() == player:objectName()
			and move.to_place == sgs.Player_PlaceHand and move.card_ids:length() >= 2) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local held = sgs.IntList()
		for _, id in sgs.qlist(move.card_ids) do
			if room:getCardPlace(id) == sgs.Player_PlaceHand
				and room:getCardOwner(id) and room:getCardOwner(id):objectName() == player:objectName() then
				held:append(id)
			end
		end
		if held:isEmpty() then return false end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local keep_id = held:first()
		if held:length() > 1 then
			room:fillAG(held, player)
			keep_id = room:askForAG(player, held, false, "@sk_yuyou-keep")
			room:clearAG()
			if keep_id < 0 then keep_id = held:first() end
		end
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
		for _, id in sgs.qlist(held) do
			if id ~= keep_id then dummy:addSubcard(id) end
		end
		local n = dummy:subcardsLength()
		if n > 0 then
			room:throwCard(dummy, player)
		end
		dummy:deleteLater()
		if n == 0 then return false end
		local males = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isMale() then males:append(p) end
		end
		if males:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, males, skill:objectName(), "@sk_yuyou-choose", true, true)
		if not target then return false end
		local choice = room:askForChoice(target, skill:objectName(), "yuyou_discard+yuyou_losehp", sgs.QVariant(n))
		if choice == "yuyou_discard" then
			room:askForDiscard(target, skill:objectName(), n, n, false, true)
		else
			room:loseHp(target, 1, true, player, skill:objectName())
		end
		return false
	end,
}


sk_panshu:addSkill(sk_jinzhi)
sk_panshu:addSkill(sk_yuyou)


sgs.LoadTranslationTable{
	["sk_panshu"] = "SK潘淑",
	["&sk_panshu"] = "潘淑",
	["#sk_panshu"] = "神女",
	["sk_jinzhi"] = "锦织",
	[":sk_jinzhi"] = "每轮限四次，你可以将所有手牌当一张本轮未以此法使用过的基本牌或普通锦囊牌使用，然后摸X张牌（X为你本轮发动“锦织”的次数）。",
	["sk_jinzhi_slash"] = "锦织",
	["sk_yuyou"] = "鱼忧",
	[":sk_yuyou"] = "<font color=\"blue\"><b>锁定技。</b></font>当你一次性获得不少于两张牌后，你保留其中一张并弃置其余牌，然后你可以令一名其他男性角色选择一项：1.弃置等量的牌；2.失去1点体力。",
	["@sk_yuyou-keep"] = "鱼忧：请选择要保留的一张牌",
	["@sk_yuyou-choose"] = "鱼忧：你可以令一名其他男性角色选择一项",
	["yuyou_discard"] = "弃置等量的牌",
	["yuyou_losehp"] = "失去1点体力",
	["designer:sk_panshu"] = "极略三国",
	["illustrator:sk_panshu"] = "极略三国",
	["cv:sk_panshu"] = "极略三国",
}


--孙休
sk_sunxiu = sgs.General(extension, "sk_sunxiu", "wu", 3, true)


--[[
	技能名：宴诛
	相关武将：SK孙休
	技能描述：出牌阶段限三次，你可以令一名角色获得一个“宴诛”标记，然后若其有一/二/三个“宴诛”标记，其摸X张牌/弃置X张牌/你对其造成X点伤害（X为与其“宴诛”标记数相同的角色数）。
	引用：sk_yanzhu, sk_yanzhuCard
]]--
sk_yanzhuCard = sgs.CreateSkillCard{
	name = "sk_yanzhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	feasible = function(self, targets, player)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:addPlayerMark(target, "@sk_yanzhu")
		local n = target:getMark("@sk_yanzhu")
		local x = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@sk_yanzhu") == n then x = x + 1 end
		end
		if n == 1 then
			target:drawCards(x, "sk_yanzhu")
		elseif n == 2 then
			room:askForDiscard(target, "sk_yanzhu", x, x, false, true)
		elseif n == 3 then
			room:damage(sgs.DamageStruct("sk_yanzhu", source, target, x))
		end
	end,
}

sk_yanzhuVS = sgs.CreateViewAsSkillV2{
	name = "sk_yanzhu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:usedTimes("#sk_yanzhuCard") < 3
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		return sk_yanzhuCard:clone()
	end,
}

sk_yanzhu = sgs.CreateTriggerSkillV2{
	name = "sk_yanzhu",
	view_as_skill = sk_yanzhuVS,
	events = {},
}


--[[
	技能名：兴学
	相关武将：SK孙休
	技能描述：结束阶段，你可以令一名角色摸与其“宴诛”标记等量的牌，且其将超过体力上限的手牌交给你；然后你移去其所有“宴诛”标记。
	引用：sk_xingxue
]]--
sk_xingxue = sgs.CreateTriggerSkillV2{
	name = "sk_xingxue",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Finish then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_xingxue-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		local n = target:getMark("@sk_yanzhu")
		if n > 0 then target:drawCards(n, skill:objectName()) end
		if target:isAlive() and player:isAlive() and target:objectName() ~= player:objectName() then
			local over = target:getHandcardNum() - target:getMaxHp()
			if over > 0 then
				local c = room:askForExchange(target, skill:objectName(), over, over, false, "@sk_xingxue-give:" .. player:objectName(), true)
				if c then
					room:obtainCard(player, c, false)
					c:deleteLater()
				end
			end
		end
		if target:getMark("@sk_yanzhu") > 0 then
			room:setPlayerMark(target, "@sk_yanzhu", 0)
		end
		return false
	end,
}


sk_sunxiu:addSkill(sk_yanzhu)
sk_sunxiu:addSkill(sk_xingxue)


sgs.LoadTranslationTable{
	["sk_sunxiu"] = "SK孙休",
	["&sk_sunxiu"] = "孙休",
	["#sk_sunxiu"] = "君临即位",
	["sk_yanzhu"] = "宴诛",
	["sk_yanzhuCard"] = "宴诛",
	["@sk_yanzhu"] = "宴诛",
	[":sk_yanzhu"] = "出牌阶段限三次，你可以令一名角色获得一个“宴诛”标记，然后若其有一/二/三个“宴诛”标记，其摸X张牌/弃置X张牌/你对其造成X点伤害（X为与其“宴诛”标记数相同的角色数）。",
	["~sk_yanzhuCard"] = "选择一名角色→点击“确定”",
	["sk_xingxue"] = "兴学",
	[":sk_xingxue"] = "结束阶段，你可以令一名角色摸与其“宴诛”标记等量的牌，且其将超过体力上限的手牌交给你；然后你移去其所有“宴诛”标记。",
	["@sk_xingxue-choose"] = "兴学：你可以令一名角色摸与其“宴诛”标记等量的牌",
	["@sk_xingxue-give"] = "兴学：你须将超过体力上限的手牌交给 %src",
	["designer:sk_sunxiu"] = "极略三国",
	["illustrator:sk_sunxiu"] = "极略三国",
	["cv:sk_sunxiu"] = "极略三国",
}


--孙登
sk_sundeng = sgs.General(extension, "sk_sundeng", "wu", 3, true)


--[[
	技能名：匡弼
	相关武将：SK孙登
	技能描述：每回合限一次，当一名角色使用基本牌或普通锦囊牌指定目标时，你可以取消之；然后你可以选择任意名角色，令这些角色成为此牌的目标（无距离限制）。
	引用：sk_kuangbi
]]--
sk_kuangbi = sgs.CreateTriggerSkillV2{
	name = "sk_kuangbi",
	events = {sgs.TargetSpecified},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getMark("sk_kuangbi_used-Clear") > 0 then return false end
		local use = data:toCardUse()
		if not (use.card and use.from and use.to and use.to:length() > 0) then return false end
		if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		room:addPlayerMark(player, "sk_kuangbi_used-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		local harmful = use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
			or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")
			or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")
			or use.card:isKindOf("FireAttack") or use.card:isKindOf("IronChain")
			or use.card:isKindOf("Collateral") or use.card:isKindOf("Lightning")
			or use.card:isKindOf("Drowning") or use.card:isKindOf("BurningCamps")
			or use.card:isKindOf("LureTiger") or use.card:isKindOf("FightTogether")
			or use.card:isKindOf("ImperialOrder") or use.card:isKindOf("ThreatenEmperor"))
		room:setPlayerMark(player, "sk_kuangbi_harm-Clear", harmful and 1 or 0)
		local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0,
			room:getAlivePlayers():length(), "@sk_kuangbi-choose:" .. use.card:objectName(), true, true)
		local useto = sgs.SPlayerList()
		if targets then
			for _, t in sgs.qlist(targets) do
				useto:append(t)
			end
		end
		use.to = useto
		room:sortByActionOrder(use.to)
		data:setValue(use)
		return false
	end,
}


sk_sundeng:addSkill(sk_kuangbi)


sgs.LoadTranslationTable{
	["sk_sundeng"] = "SK孙登",
	["&sk_sundeng"] = "孙登",
	["#sk_sundeng"] = "宣太子",
	["sk_kuangbi"] = "匡弼",
	[":sk_kuangbi"] = "每回合限一次，当一名角色使用基本牌或普通锦囊牌指定目标时，你可以取消之；然后你可以选择任意名角色，令这些角色成为此牌的目标（无距离限制）。",
	["@sk_kuangbi-choose"] = "匡弼：你可以选择任意名角色成为 %src 的新目标（不选择则取消此牌）",
	["designer:sk_sundeng"] = "极略三国",
	["illustrator:sk_sundeng"] = "极略三国",
	["cv:sk_sundeng"] = "极略三国",
}


--朱治
sk_zhuzhi = sgs.General(extension, "sk_zhuzhi", "wu", 4, true)


--[[
	技能名：安国
	相关武将：SK朱治
	技能描述：摸牌阶段，你可以少摸一张牌，然后令一名角色随机使用一张装备牌；然后若此牌为：武器牌，你摸X张牌（X为此牌的攻击范围）；防具牌，其回复1点体力；坐骑牌，重复此流程。
	引用：sk_anguo
]]--
sk_anguo = sgs.CreateTriggerSkillV2{
	name = "sk_anguo",
	events = {sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local draw = data:toDraw()
		if not (draw and draw.reason == "draw_phase" and draw.num > 0) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_anguo-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		local draw = ctx.original_data:toDraw()
		draw.num = math.max(0, draw.num - 1)
		ctx.original_data:setValue(draw)
		while target:isAlive() do
			local equips = {}
			for _, id in sgs.qlist(room:getDrawPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("EquipCard") and target:hasEquipArea(c:getRealCard():toEquipCard():location()) then
					table.insert(equips, id)
				end
			end
			if #equips == 0 then break end
			local eid = equips[math.random(1, #equips)]
			local card = sgs.Sanguosha:getCard(eid)
			local range = 0
			if card:isKindOf("Weapon") then
				range = card:getRealCard():toWeapon():getRange()
			end
			room:useCard(sgs.CardUseStruct(card, target, target))
			if range > 0 then
				player:drawCards(range, skill:objectName())
				break
			elseif card:isKindOf("Armor") then
				if target:isAlive() and target:isWounded() then
					local rec = sgs.RecoverStruct()
					rec.who = player
					room:recover(target, rec, true)
				end
				break
			elseif not (card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")) then
				break
			end
		end
		return false
	end,
}


sk_zhuzhi:addSkill(sk_anguo)


sgs.LoadTranslationTable{
	["sk_zhuzhi"] = "SK朱治",
	["&sk_zhuzhi"] = "朱治",
	["#sk_zhuzhi"] = "毗陵侯",
	["sk_anguo"] = "安国",
	[":sk_anguo"] = "摸牌阶段，你可以少摸一张牌，然后令一名角色随机使用一张装备牌；然后若此牌为：武器牌，你摸X张牌（X为此牌的攻击范围）；防具牌，其回复1点体力；坐骑牌，重复此流程。",
	["@sk_anguo-choose"] = "安国：你可以少摸一张牌，令一名角色随机使用一张装备牌",
	["designer:sk_zhuzhi"] = "极略三国",
	["illustrator:sk_zhuzhi"] = "极略三国",
	["cv:sk_zhuzhi"] = "极略三国",
}


--孙亮
sk_sunliang = sgs.General(extension, "sk_sunliang", "wu", 3, true)


--[[
	技能名：溃诛
	相关武将：SK孙亮
	技能描述：锁定技，结束阶段，若所有其他角色本回合弃置的牌数和大于你本回合弃置的牌数，你对一名角色造成2点伤害；否则你失去1点体力并摸与角色数等量的牌。
	引用：sk_kuizhu
]]--
sk_kuizhu = sgs.CreateTriggerSkillV2{
    name = "sk_kuizhu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.to_place == sgs.Player_DiscardPile
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if p:isAlive() then
						return skill:objectName(), p:objectName()
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish then
				return skill:objectName(), player:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.from and move.card_ids:length() > 0 then
				room:addPlayerMark(move.from, "sk_kuizhu_dc-Clear", move.card_ids:length())
			end
			return false
		end
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local self_n = player:getMark("sk_kuizhu_dc-Clear")
		local other_n = 0
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			other_n = other_n + p:getMark("sk_kuizhu_dc-Clear")
		end
		if other_n > self_n then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_kuizhu-choose")
			if target then
				room:damage(sgs.DamageStruct(skill:objectName(), player, target, 2))
			end
		else
			room:loseHp(player, 1, true, player, skill:objectName())
			if player:isAlive() then
				player:drawCards(room:getAlivePlayers():length(), skill:objectName())
			end
		end
		return false
	end,
}


--[[
	技能名：掣政
	相关武将：SK孙亮
	技能描述：非额外的出牌阶段结束时，你可以选择至多X名角色（X为你的体力值），然后你选择一项：1.这些角色各弃置一张牌，然后依次进行一个额外的出牌阶段；2.这些角色各摸一张牌，然后依次进行一个额外的弃牌阶段。
	引用：sk_chezheng
]]--
sk_chezheng = sgs.CreateTriggerSkillV2{
    name = "sk_chezheng",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:hasFlag("sk_chezheng_extra") then return false end
		local current = room:getCurrent()
		if not (current and current:objectName() == player:objectName()) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0,
			math.max(0, player:getHp()), "@sk_chezheng-choose", true, true)
		if not targets or targets:isEmpty() then return false end
		local choice = room:askForChoice(player, skill:objectName(), "sk_chezheng_play+sk_chezheng_discard")
		if choice == "sk_chezheng_play" then
			for _, t in sgs.qlist(targets) do
				if t and t:isAlive() then
					room:askForDiscard(t, skill:objectName(), 1, 1, false, true)
				end
			end
			for _, t in sgs.qlist(targets) do
				if t and t:isAlive() then
					room:setPlayerFlag(t, "sk_chezheng_extra")
					PhaseExtra(t, sgs.Player_Play, true)
					if t:hasFlag("sk_chezheng_extra") then room:setPlayerFlag(t, "-sk_chezheng_extra") end
				end
			end
		else
			for _, t in sgs.qlist(targets) do
				if t and t:isAlive() then
					t:drawCards(1, skill:objectName())
				end
			end
			for _, t in sgs.qlist(targets) do
				if t and t:isAlive() then
					room:setPlayerFlag(t, "sk_chezheng_extra")
					PhaseExtra(t, sgs.Player_Discard, true)
					if t:hasFlag("sk_chezheng_extra") then room:setPlayerFlag(t, "-sk_chezheng_extra") end
				end
			end
		end
		return false
	end,
}


sk_sunliang:addSkill(sk_kuizhu)
sk_sunliang:addSkill(sk_chezheng)


sgs.LoadTranslationTable{
    ["sk_sunliang"] = "SK孙亮",
    ["&sk_sunliang"] = "孙亮",
    ["#sk_sunliang"] = "会稽王",
	["sk_kuizhu"] = "溃诛",
	[":sk_kuizhu"] = "<font color = \"blue\"><b>锁定技。</b></font>结束阶段，若所有其他角色本回合弃置的牌数和大于你本回合弃置的牌数，你对一名角色造成2点伤害；否则你失去1点体力并摸与角色数等量的牌。",
	["@sk_kuizhu-choose"] = "溃诛：请选择一名角色，对其造成2点伤害",
	["sk_chezheng"] = "掣政",
	[":sk_chezheng"] = "非额外的出牌阶段结束时，你可以选择至多X名角色（X为你的体力值），然后你选择一项：1.这些角色各弃置一张牌，然后依次进行一个额外的出牌阶段；2.这些角色各摸一张牌，然后依次进行一个额外的弃牌阶段。",
	["@sk_chezheng-choose"] = "掣政：你可以选择至多X名角色（X为你的体力值）",
	["sk_chezheng_play"] = "这些角色各弃置一张牌，然后依次进行一个额外的出牌阶段",
	["sk_chezheng_discard"] = "这些角色各摸一张牌，然后依次进行一个额外的弃牌阶段",
	["designer:sk_sunliang"] = "极略三国",
	["illustrator:sk_sunliang"] = "极略三国",
	["cv:sk_sunliang"] = "极略三国",
}


--葛玄
sk_gexuan = sgs.General(extension, "sk_gexuan", "qun", 3, true)


--[[
	技能名：炼化
	相关武将：SK葛玄
	技能描述：一名角色的出牌阶段开始时，你可以观看其手牌并弃置其中至少一张牌，然后其获得X张随机临时牌（X为该角色的弃牌数+1）。
	引用：sk_lianhua
]]--
sk_lianhua = sgs.CreateTriggerSkillV2{
    name = "sk_lianhua",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:isKongcheng() then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local gexuan = player
		local target = ctx.invoker
		if not (gexuan and target and gexuan:isAlive() and target:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		local n = 0
		while target:isAlive() and not target:isKongcheng() do
			local hands = target:handCards()
			if hands:isEmpty() then break end
			local id = room:doGongxin(gexuan, target, hands, skill:objectName())
			if id < 0 then
				if n > 0 then break end
				id = hands:at(math.random(0, hands:length() - 1))
			end
			if room:getCardOwner(id) ~= target or room:getCardPlace(id) ~= sgs.Player_PlaceHand then break end
			room:throwCard(id, target, gexuan)
			n = n + 1
		end
		if n <= 0 or not target:isAlive() then return false end
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local pool = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			table.insert(pool, id)
		end
		local gain = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local got = 0
		for i = 1, n + 1 do
			if #pool == 0 then break end
			local idx = math.random(1, #pool)
			local id = pool[idx]
			table.remove(pool, idx)
			gain:addSubcard(id)
			room:setCardFlag(sgs.Sanguosha:getCard(id), "sk_gexuan_temp")
			got = got + 1
		end
		if got > 0 then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, gexuan:objectName(), target:objectName(), skill:objectName(), "")
			room:obtainCard(target, gain, reason, true)
		end
		gain:deleteLater()
		return false
	end,
}


--[[
	技能名：札符
	相关武将：SK葛玄
	技能描述：锁定技，当临时牌进入弃牌堆后，你摸一张牌。
	引用：sk_zhafu
]]--
sk_zhafu = sgs.CreateTriggerSkillV2{
    name = "sk_zhafu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local has_temp = false
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):hasFlag("sk_gexuan_temp")
					and room:getCardPlace(id) == sgs.Player_DiscardPile then
					has_temp = true
					break
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card then return false end
			local cids = sgs.IntList()
			for _, id in sgs.qlist(use.card:getSubcards()) do
				cids:append(id)
			end
			if cids:isEmpty() and use.card:getEffectiveId() >= 0 then
				cids:append(use.card:getEffectiveId())
			end
			for _, id in sgs.qlist(cids) do
				if sgs.Sanguosha:getCard(id):hasFlag("sk_gexuan_temp")
					and room:getCardPlace(id) == sgs.Player_DiscardPile then
					has_temp = true
					break
				end
			end
		end
		if not has_temp then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:isAlive() then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local gexuan = player
		if not (gexuan and gexuan:isAlive()) then return false end
		local ids = sgs.IntList()
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:hasFlag("sk_gexuan_temp") and room:getCardPlace(id) == sgs.Player_DiscardPile then
					room:setCardFlag(card, "-sk_gexuan_temp")
					ids:append(id)
				end
			end
		else
			local use = ctx.original_data:toCardUse()
			local cids = sgs.IntList()
			for _, id in sgs.qlist(use.card:getSubcards()) do
				cids:append(id)
			end
			if cids:isEmpty() and use.card:getEffectiveId() >= 0 then
				cids:append(use.card:getEffectiveId())
			end
			for _, id in sgs.qlist(cids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:hasFlag("sk_gexuan_temp") and room:getCardPlace(id) == sgs.Player_DiscardPile then
					room:setCardFlag(card, "-sk_gexuan_temp")
					ids:append(id)
				end
			end
		end
		if ids:isEmpty() then return false end
		room:sendCompulsoryTriggerLog(gexuan, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local n = ids:length()
		local msg = sgs.LogMessage()
		msg.type = "$BreakCard"
		msg.from = gexuan
		msg.card_str = table.concat(sgs.QList2Table(ids, "+"))
		room:sendLog(msg)
		local toids = sgs.IntList()
		for _, id in sgs.qlist(ids) do
			toids:append(id)
		end
		for _, id in sgs.qlist(room:getTag("BreakCard"):toIntList()) do
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				toids:append(id)
			end
		end
		local tagv = sgs.QVariant()
		tagv:setValue(toids)
		room:setTag("BreakCard", tagv)
		local breakmove = sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, gexuan:objectName(), "BreakCard", ""))
		room:moveCardsAtomic(breakmove, true)
		gexuan:drawCards(n, skill:objectName())
		return false
	end,
}


sk_gexuan:addSkill(sk_lianhua)
sk_gexuan:addSkill(sk_zhafu)


sgs.LoadTranslationTable{
    ["sk_gexuan"] = "SK葛玄",
    ["&sk_gexuan"] = "葛玄",
    ["#sk_gexuan"] = "冲应真人",
	["sk_lianhua"] = "炼化",
	[":sk_lianhua"] = "一名角色的出牌阶段开始时，你可以观看其手牌并弃置其中至少一张牌，然后其获得X张随机临时牌（X为该角色的弃牌数+1）。",
	["sk_zhafu"] = "札符",
	[":sk_zhafu"] = "当临时牌进入弃牌堆后，你摸一张牌。",
	["designer:sk_gexuan"] = "极略三国",
	["illustrator:sk_gexuan"] = "极略三国",
	["cv:sk_gexuan"] = "极略三国",
}


--管辂
sk_guanlu = sgs.General(extension, "sk_guanlu", "wei", 3, true)


--[[
	技能名：纵情
	相关武将：SK管辂
	技能描述：摸牌阶段开始时，你可以判定。此阶段结束时，你展示本阶段获得的牌，然后弃置其中与判定牌颜色不同的一张牌，若此牌为红色/黑色，你视为使用一张【桃】/【酒】。
	引用：sk_zongqing
]]--
sk_zongqing = sgs.CreateTriggerSkillV2{
	name = "sk_zongqing",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Draw then return false end
		if event == sgs.EventPhaseStart then
			return skill:objectName()
		elseif event == sgs.CardsMoveOneTime then
			if player:hasFlag("sk_zongqing_judged") then
				local move = data:toMoveOneTime()
				if move.to and move.to:objectName() == player:objectName()
					and move.to_place == sgs.Player_PlaceHand then
					return skill:objectName()
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:hasFlag("sk_zongqing_judged") then return skill:objectName() end
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
		if event == sgs.EventPhaseStart then
			room:broadcastSkillInvoke(skill:objectName())
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.reason = skill:objectName()
			room:judge(judge)
			if judge.card then
				room:setPlayerFlag(player, "sk_zongqing_judged")
				local colorv = sgs.QVariant()
				colorv:setValue(judge.card:isRed() and "red" or "black")
				room:setTag("sk_zongqing_color_" .. player:objectName(), colorv)
				local idsv = sgs.QVariant()
				idsv:setValue(sgs.IntList())
				room:setTag("sk_zongqing_ids_" .. player:objectName(), idsv)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			local ids = room:getTag("sk_zongqing_ids_" .. player:objectName()):toIntList()
			for _, id in sgs.qlist(move.card_ids) do
				ids:append(id)
			end
			local idsv = sgs.QVariant()
			idsv:setValue(ids)
			room:setTag("sk_zongqing_ids_" .. player:objectName(), idsv)
		elseif event == sgs.EventPhaseEnd then
			room:setPlayerFlag(player, "-sk_zongqing_judged")
			local color = room:getTag("sk_zongqing_color_" .. player:objectName()):toString()
			local ids = room:getTag("sk_zongqing_ids_" .. player:objectName()):toIntList()
			room:removeTag("sk_zongqing_color_" .. player:objectName())
			room:removeTag("sk_zongqing_ids_" .. player:objectName())
			local gained = sgs.IntList()
			for _, id in sgs.qlist(ids) do
				if room:getCardPlace(id) == sgs.Player_PlaceHand
					and room:getCardOwner(id) and room:getCardOwner(id):objectName() == player:objectName() then
					gained:append(id)
				end
			end
			if gained:isEmpty() then return false end
			room:fillAG(gained)
			room:getThread():delay(500)
			local choices = sgs.IntList()
			for _, id in sgs.qlist(gained) do
				local c = sgs.Sanguosha:getCard(id)
				if (color == "red" and c:isBlack()) or (color == "black" and c:isRed()) then
					choices:append(id)
				end
			end
			if not choices:isEmpty() then
				local id = room:askForAG(player, choices, false, skill:objectName())
				room:clearAG()
				local card = sgs.Sanguosha:getCard(id)
				room:throwCard(card, player)
				local use_card = sgs.Sanguosha:cloneCard(card:isRed() and "peach" or "analeptic", sgs.Card_NoSuit, 0)
				use_card:setSkillName(skill:objectName())
				local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(player)
				use.card = use_card
				room:useCard(use, false)
				use_card:deleteLater()
			else
				room:clearAG()
			end
		end
		return false
	end,
}


--[[
	技能名：卜卦
	相关武将：SK管辂
	技能描述：当一名角色判定前，你可以展示牌堆顶的一张牌，然后你可以选择一项：1.将一张手牌置于牌堆顶；2.令其将一张手牌置于牌堆顶。当一名角色的红色/黑色判定牌生效后，你可以令其摸/弃置一张牌。
	引用：sk_bugua
]]--
sk_bugua = sgs.CreateTriggerSkillV2{
	name = "sk_bugua",
	events = {sgs.StartJudge, sgs.FinishJudge},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local judge = data:toJudge()
		if not (judge.who and judge.who:isAlive()) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, guanlu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if guanlu:isAlive() then
				if event == sgs.StartJudge then
					if not room:getDrawPile():isEmpty() then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, guanlu:objectName())
					end
				elseif event == sgs.FinishJudge then
					if judge.card then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, guanlu:objectName())
					end
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local judge = ctx.original_data:toJudge()
		if event == sgs.StartJudge then
			return player:askForSkillInvoke(skill:objectName(), sgs.QVariant("bugua_start:" .. judge.who:objectName()))
		elseif event == sgs.FinishJudge then
			local color = judge.card:isRed() and "red" or "black"
			return player:askForSkillInvoke(skill:objectName(),
				sgs.QVariant("bugua_finish:" .. judge.who:objectName() .. ":" .. color))
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local judge = ctx.original_data:toJudge()
		if event == sgs.StartJudge then
			if room:getDrawPile():isEmpty() then return false end
			room:broadcastSkillInvoke(skill:objectName())
			local ids = sgs.IntList()
			ids:append(sgs.QList2Table(room:getDrawPile())[1])
			room:fillAG(ids)
			room:getThread():delay(500)
			room:clearAG()
			local choices = {}
			if not player:isKongcheng() then table.insert(choices, "bugua_self") end
			if judge.who and not judge.who:isKongcheng() then table.insert(choices, "bugua_who") end
			if #choices == 0 then return false end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"))
			if choice == "cancel" then return false end
			local giver = (choice == "bugua_self") and player or judge.who
			local c = room:askForExchange(giver, skill:objectName(), 1, 1, false,
				"@bugua-put:" .. judge.who:objectName(), true, ".|.|.|hand")
			if c then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
					giver:objectName(), skill:objectName(), "")
				room:moveCardTo(sgs.Sanguosha:getCard(c:getSubcards():first()), giver,
					nil, sgs.Player_DrawPile, reason)
			end
		elseif event == sgs.FinishJudge then
			room:broadcastSkillInvoke(skill:objectName())
			if judge.card:isRed() then
				judge.who:drawCards(1, skill:objectName())
			elseif judge.who:isAlive() then
				room:askForDiscard(judge.who, skill:objectName(), 1, 1, false, true)
			end
		end
		return false
	end,
}


sk_guanlu:addSkill(sk_zongqing)
sk_guanlu:addSkill(sk_bugua)


sgs.LoadTranslationTable{
	["sk_guanlu"] = "SK管辂",
	["&sk_guanlu"] = "管辂",
	["sk_zongqing"] = "纵情",
	[":sk_zongqing"] = "摸牌阶段开始时，你可以判定。此阶段结束时，你展示本阶段获得的牌，然后弃置其中与判定牌颜色不同的一张牌，若此牌为红色/黑色，你视为使用一张【桃】/【酒】。",
	["sk_bugua"] = "卜卦",
	[":sk_bugua"] = "当一名角色判定前，你可以展示牌堆顶的一张牌，然后你可以选择一项：1.将一张手牌置于牌堆顶；2.令其将一张手牌置于牌堆顶。当一名角色的红色/黑色判定牌生效后，你可以令其摸/弃置一张牌。",
	["bugua_self"] = "将一张手牌置于牌堆顶",
	["bugua_who"] = "令其将一张手牌置于牌堆顶",
	["@bugua-put"] = "卜卦：请将一张手牌置于牌堆顶（%src 的判定）",
	["designer:sk_guanlu"] = "极略三国",
	["illustrator:sk_guanlu"] = "极略三国",
	["cv:sk_guanlu"] = "极略三国",
}


--臧霸
sk_zangba = sgs.General(extension, "sk_zangba", "wei", 4, true)


--横江
sk_hengjiang = sgs.CreateTriggerSkillV2{
    name = "sk_hengjiang",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Discard then return false end
		if event ~= sgs.EventPhaseStart and not player:hasFlag("sk_hengjiang_used") then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local choice = room:askForChoice(player, skill:objectName(), "hengjiang_plus+hengjiang_minus+cancel", ctx.original_data)
			if choice == "cancel" then return false end
			ctx.extra_data:setValue(choice)
			return true
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			room:broadcastSkillInvoke(skill:objectName())
			room:setPlayerFlag(player, "sk_hengjiang_used")
			if ctx.extra_data:toString() == "hengjiang_minus" then
				room:addPlayerMark(player, "sk_hengjiang_minus-Clear")
			else
				room:addPlayerMark(player, "sk_hengjiang_plus-Clear")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
				and move.to_place == sgs.Player_DiscardPile
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local n = 0
				local i = 0
				for _, card_id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						local place = move.from_places:at(i)
						if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
							n = n + 1
						end
					end
					i = i + 1
				end
				if n > 0 then room:addPlayerMark(player, "sk_hengjiang_dc-Clear", n) end
			end
		elseif event == sgs.EventPhaseEnd then
			room:setPlayerFlag(player, "-sk_hengjiang_used")
			local x = player:getMark("sk_hengjiang_dc-Clear")
			room:setPlayerMark(player, "sk_hengjiang_dc-Clear", 0)
			if x <= 0 then return false end
			local discarded = 0
			while discarded < x do
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasEquip() or p:getJudgingArea():length() > 0 then
						targets:append(p)
					end
				end
				if targets:isEmpty() then break end
				local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@hengjiang-discard", true, true)
				if not target then break end
				local card_id = room:askForCardChosen(player, target, "ej", skill:objectName())
				if card_id == -1 then break end
				room:throwCard(card_id, target, player)
				discarded = discarded + 1
			end
		end
		return false
	end,
}

sk_hengjiangMaxCards = sgs.CreateMaxCardsSkillV2{
    name = "#sk_hengjiang",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:getMark("sk_hengjiang_plus-Clear") > 0 then return 1 end
		if target and target:getMark("sk_hengjiang_minus-Clear") > 0 then return -1 end
		return false
	end
}

extension:insertRelatedSkills("sk_hengjiang", "#sk_hengjiang")


sk_zangba:addSkill(sk_hengjiang)
sk_zangba:addSkill(sk_hengjiangMaxCards)


sgs.LoadTranslationTable{
	["sk_zangba"] = "SK臧霸",
	["&sk_zangba"] = "臧霸",
	["sk_hengjiang"] = "横江",
	["hengjiang_plus"] = "手牌上限+1",
	["hengjiang_minus"] = "手牌上限-1",
	["@hengjiang-discard"] = "横江：你可以弃置场上一张牌",
	[":sk_hengjiang"] = "弃牌阶段开始时，你可以令本回合手牌上限+1或-1，然后此阶段结束时，你可以弃置场上的至多X张牌（X为你此阶段弃置的牌数）。",
	["designer:sk_zangba"] = "极略三国",
    ["illustrator:sk_zangba"] = "极略三国",
    ["cv:sk_zangba"] = "极略三国",
}


--卞夫人
sk_bianfuren = sgs.General(extension, "sk_bianfuren", "wei", 3, false)


--化戈
sk_huageCard = sgs.CreateSkillCard{
    name = "sk_huageCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isAlive() and not p:isKongcheng() then
				local c = room:askForExchange(p, "sk_huage", 999, 1, false, "@huage-discard:" .. source:objectName())
				if c then
					local slash_num = 0
					for _, id in sgs.qlist(c:getSubcards()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							slash_num = slash_num + 1
						end
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, p:objectName(), "sk_huage", "")
					room:throwCard(c, reason, p)
					if slash_num > 0 and p:isAlive() then
						p:drawCards(slash_num, "sk_huage")
					end
				end
			end
		end
	end
}

sk_huage = sgs.CreateViewAsSkillV2{
    name = "sk_huage",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
	    return not (player:hasUsed("#sk_huageCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
	    return sk_huageCard:clone()
	end,
}


--母仪
sk_muyi = sgs.CreateTriggerSkillV2{
    name = "sk_muyi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		if player:getPhase() == sgs.Player_Start and not player:isKongcheng() then
			for _, bf in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if bf:isAlive() and bf:objectName() ~= player:objectName() then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, bf:objectName())
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			for _, bf in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if bf:isAlive() and bf:getMark("sk_muyi_back#" .. player:objectName() .. "-Clear") > 0 then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, bf:objectName())
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		-- player is the skill owner (bianfuren); ctx.invoker is the phase player
		local invoker = ctx.invoker
		if not invoker then return false end
		if invoker:getPhase() == sgs.Player_Start then
			if invoker:isKongcheng() then return false end
			local c = room:askForExchange(invoker, skill:objectName(), 2, 1, true, "@muyi-give:" .. player:objectName())
			if not c then return false end
			local ids = {}
			for _, id in sgs.qlist(c:getSubcards()) do
				table.insert(ids, tostring(id))
			end
			ctx.extra_data:setValue(table.concat(ids, "+"))
			return true
		elseif invoker:getPhase() == sgs.Player_Finish then
			return player:getMark("sk_muyi_back#" .. invoker:objectName() .. "-Clear") > 0
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		if not invoker then return false end
		if invoker:getPhase() == sgs.Player_Start then
			local idstr = ctx.extra_data:toString()
			if idstr == "" then return false end
			room:broadcastSkillInvoke(skill:objectName())
			room:doAnimate(1, invoker:objectName(), player:objectName())
			local n = 0
			for _, s in ipairs(idstr:split("+")) do
				local id = tonumber(s)
				if id then
					room:obtainCard(player, id, false)
					n = n + 1
				end
			end
			if n > 0 then
				room:addPlayerMark(player, "sk_muyi_back#" .. invoker:objectName() .. "-Clear", n)
			end
		elseif invoker:getPhase() == sgs.Player_Finish then
			local n = math.min(player:getMark("sk_muyi_back#" .. invoker:objectName() .. "-Clear"), player:getHandcardNum())
			if n <= 0 then return false end
			room:broadcastSkillInvoke(skill:objectName())
			room:doAnimate(1, player:objectName(), invoker:objectName())
			if invoker:isAlive() then
				local c = room:askForExchange(player, skill:objectName(), n, n, false, "@muyi-back:" .. invoker:objectName())
				if c then room:obtainCard(invoker, c, false) end
			end
		end
		return false
	end,
}


sk_bianfuren:addSkill(sk_huage)
sk_bianfuren:addSkill(sk_muyi)


sgs.LoadTranslationTable{
	["sk_bianfuren"] = "SK卞夫人",
	["&sk_bianfuren"] = "卞夫人",
	["sk_huage"] = "化戈",
	[":sk_huage"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令所有角色各弃置至少一张牌，然后其摸X张牌（X为其以此法弃置的【杀】的数量）。",
	["@huage-discard"] = "化戈：请弃置至少一张牌（每弃置一张【杀】，你摸一张牌）",
	["sk_muyi"] = "母仪",
	[":sk_muyi"] = "其他角色的准备阶段，其可以交给你一至两张牌，然后此回合结束时，你交给其等量的牌。",
	["@muyi-give"] = "母仪：你可以交给 %src 一至两张牌",
	["@muyi-back"] = "母仪：请交给 %src 等量的牌",
	["designer:sk_bianfuren"] = "极略三国",
    ["illustrator:sk_bianfuren"] = "极略三国",
    ["cv:sk_bianfuren"] = "极略三国",
}


--戏志才
sk_xizhicai = sgs.General(extension, "sk_xizhicai", "wei", 3, true)


--天策
local function sk_tiance_judge(room, player, target, data)
	room:doAnimate(1, player:objectName(), target:objectName())
	local judge = sgs.JudgeStruct()
	judge.who = target
	judge.reason = "sk_tiance"
	judge.pattern = "."
	judge.good = true
	judge.play_animation = false
	room:judge(judge)
	local jcard = judge.card
	if not jcard or not target:isAlive() then return jcard end
	local suit = jcard:getSuit()
	local function collect(ids)
		local list = {}
		for _, id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):getSuit() == suit then table.insert(list, id) end
		end
		return list
	end
	local pools = {}
	pools.tiance_drawpile = collect(room:getDrawPile())
	pools.tiance_discardpile = collect(room:getDiscardPile())
	pools.tiance_others = {}
	for _, p in sgs.qlist(room:getOtherPlayers(target)) do
		for _, c in sgs.qlist(p:getCards("he")) do
			if c:getSuit() == suit then table.insert(pools.tiance_others, c:getEffectiveId()) end
		end
	end
	local choices = {}
	for _, name in ipairs({"tiance_drawpile", "tiance_discardpile", "tiance_others"}) do
		if #pools[name] > 0 then table.insert(choices, name) end
	end
	if #choices == 0 then return jcard end
	table.insert(choices, "cancel")
	local choice = room:askForChoice(target, "sk_tiance", table.concat(choices, "+"), data)
	if choice == "cancel" then return jcard end
	local pool = pools[choice]
	for i = 1, math.min(2, #pool) do
		local id = table.remove(pool, math.random(1, #pool))
		if target:isAlive() then room:obtainCard(target, id, false) end
	end
	return jcard
end

sk_tiance = sgs.CreateTriggerSkillV2{
	name = "sk_tiance",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_tiance-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		sk_tiance_judge(room, player, target, ctx.original_data)
		return false
	end,
}


--竭心
sk_jiexin = sgs.CreateTriggerSkillV2{
	name = "sk_jiexin",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_tiance", "@sk_jiexin-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		local damage = ctx.original_data:toDamage()
		local jcard = sk_tiance_judge(room, player, target, ctx.original_data)
		if not (jcard and damage.card and player:isAlive()) then return false end
		local same_color = (jcard:isRed() and damage.card:isRed()) or (jcard:isBlack() and damage.card:isBlack())
		if not same_color then return false end
		local again = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_tiance", "@sk_jiexin-again", true, true)
		if again then
			room:broadcastSkillInvoke(skill:objectName())
			sk_tiance_judge(room, player, again, ctx.original_data)
		end
		return false
	end,
}


sk_xizhicai:addSkill(sk_tiance)
sk_xizhicai:addSkill(sk_jiexin)


sgs.LoadTranslationTable{
	["sk_xizhicai"] = "SK戏志才",
	["&sk_xizhicai"] = "戏志才",
	["sk_tiance"] = "天策",
	[":sk_tiance"] = "准备阶段，你可以令一名角色判定，然后其可从牌堆、弃牌堆或其他角色处随机获得两张与判定结果花色相同的牌。",
	["@sk_tiance-choose"] = "天策：你可以令一名角色判定",
	["tiance_drawpile"] = "从牌堆随机获得两张同花色牌",
	["tiance_discardpile"] = "从弃牌堆随机获得两张同花色牌",
	["tiance_others"] = "从其他角色处随机获得两张同花色牌",
	["sk_jiexin"] = "竭心",
	[":sk_jiexin"] = "当你受到伤害后，你可以发动“天策”；若判定结果与造成伤害的牌颜色相同，你可以额外发动一次“天策”。",
	["@sk_jiexin-choose"] = "竭心：你可以发动“天策”，令一名角色判定",
	["@sk_jiexin-again"] = "竭心：判定结果与伤害牌颜色相同，你可以额外发动一次“天策”",
	["designer:sk_xizhicai"] = "极略三国",
    ["illustrator:sk_xizhicai"] = "极略三国",
    ["cv:sk_xizhicai"] = "极略三国",
}


--曹睿
sk_caorui = sgs.General(extension, "sk_caorui", "wei", 3, true)


--恢拓
local sk_huituo_options = {"huituo_recover", "huituo_draw", "huituo_equip", "huituo_acquire"}
local function sk_huituo_choices(player, target)
	local list = {}
	for _, opt in ipairs(sk_huituo_options) do
		if player:getMark("sk_" .. opt) == 0 and not (opt == "huituo_acquire" and target and target:hasSkill("sk_huituo")) then
			table.insert(list, opt)
		end
	end
	return list
end

sk_huituo = sgs.CreateTriggerSkillV2{
	name = "sk_huituo",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		if #sk_huituo_choices(player) == 0 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_huituo-choose", true, true)
		if not target then return false end
		local choices = sk_huituo_choices(player, target)
		if #choices == 0 then return false end
		table.insert(choices, "cancel")
		local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), ctx.original_data)
		if choice == "cancel" then return false end
		ctx.extra_data:setValue(choice)
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		local choice = ctx.extra_data:toString()
		if choice == "" then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		room:addPlayerMark(player, "sk_" .. choice)
		local function unique_max(getter)
			for _, p in sgs.qlist(room:getOtherPlayers(target)) do
				if getter(p) >= getter(target) then return false end
			end
			return true
		end
		if choice == "huituo_recover" then
			while target:isAlive() and target:isWounded() and not unique_max(function(p) return p:getHp() end) do
				local rec = sgs.RecoverStruct()
				rec.who = player
				room:recover(target, rec, true)
			end
		elseif choice == "huituo_draw" then
			local n = 0
			while target:isAlive() and n < 50 and not unique_max(function(p) return p:getHandcardNum() end) do
				target:drawCards(1, skill:objectName())
				n = n + 1
			end
		elseif choice == "huituo_equip" then
			local n = 0
			while target:isAlive() and n < 10 do
				local equips = {}
				for _, pile in ipairs({room:getDrawPile(), room:getDiscardPile()}) do
					for _, id in sgs.qlist(pile) do
						local c = sgs.Sanguosha:getCard(id)
						if c:isKindOf("EquipCard") then
							local loc = c:getRealCard():toEquipCard():location()
							if target:hasEquipArea(loc) and target:getEquip(loc) == nil then
								table.insert(equips, id)
							end
						end
					end
				end
				if #equips == 0 then break end
				local card = sgs.Sanguosha:getCard(equips[math.random(1, #equips)])
				room:useCard(sgs.CardUseStruct(card, target, target))
				n = n + 1
			end
		elseif choice == "huituo_acquire" then
			if not target:hasSkill(skill:objectName()) then room:acquireSkill(target, skill:objectName()) end
		end
		return false
	end,
}


--兴衰
sk_xingshuai = sgs.CreateTriggerSkillV2{
	name = "sk_xingshuai",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sk_xingshuai-choose", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		local choice = room:askForChoice(target, skill:objectName(), "xingshuai_turnover+xingshuai_extraturn", ctx.original_data)
		if choice == "xingshuai_turnover" then
			target:turnOver()
		else
			player:gainAnExtraTurn()
		end
		return false
	end,
}


sk_caorui:addSkill(sk_huituo)
sk_caorui:addSkill(sk_xingshuai)


sgs.LoadTranslationTable{
	["sk_caorui"] = "SK曹睿",
	["&sk_caorui"] = "曹睿",
	["sk_huituo"] = "恢拓",
	[":sk_huituo"] = "准备阶段，你可以选择一名角色并令其执行一项未选择过的选项：1.令其回复体力至唯一最多；2.令其摸牌至唯一最多；3.令其随机使用牌堆或弃牌堆中的装备牌，直到其装备区没有空位；4.令该角色获得“恢拓”。",
	["@sk_huituo-choose"] = "恢拓：你可以选择一名角色，令其执行一项未选择过的选项",
	["huituo_recover"] = "令其回复体力至唯一最多",
	["huituo_draw"] = "令其摸牌至唯一最多",
	["huituo_equip"] = "令其随机使用牌堆或弃牌堆中的装备牌，直到其装备区没有空位",
	["huituo_acquire"] = "令该角色获得“恢拓”",
	["sk_xingshuai"] = "兴衰",
	[":sk_xingshuai"] = "当你受到其他角色造成的伤害后，你可以令一名其他角色选择一项：1.将武将牌翻面；2.令你于此回合结束后进行一个额外的回合。",
	["@sk_xingshuai-choose"] = "兴衰：你可以令一名其他角色选择翻面或令你进行一个额外的回合",
	["xingshuai_turnover"] = "将武将牌翻面",
	["xingshuai_extraturn"] = "令其于此回合结束后进行一个额外的回合",
	["designer:sk_caorui"] = "极略三国",
    ["illustrator:sk_caorui"] = "极略三国",
    ["cv:sk_caorui"] = "极略三国",
}


--曹休
sk_caoxiu = sgs.General(extension, "sk_caoxiu", "wei", 4, true)


--讨袭
sk_taoxiCard = sgs.CreateSkillCard{
	name = "sk_taoxiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local records = {}
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:isAlive() and not p:isKongcheng() then
				local id = room:askForCardChosen(source, p, "h", "sk_taoxi")
				if id ~= -1 then
					room:obtainCard(source, id, false)
					table.insert(records, id .. ":" .. p:objectName())
				end
			end
		end
		if #records > 0 then
			room:setPlayerFlag(source, "sk_taoxi_used")
			room:setTag("sk_taoxi_" .. source:objectName(), sgs.QVariant(table.concat(records, "+")))
		end
	end
}

sk_taoxi = sgs.CreateViewAsSkillV2{
	name = "sk_taoxi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#sk_taoxiCard") or player:hasUsed(skill:objectName()))
	end,
	create_card = function(skill, request)
		return sk_taoxiCard:clone()
	end,
}

sk_taoxiReturn = sgs.CreateTriggerSkillV2{
	name = "#sk_taoxi",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:getPhase() == sgs.Player_Play and player:hasFlag("sk_taoxi_used")) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerFlag(player, "-sk_taoxi_used")
		local tagname = "sk_taoxi_" .. player:objectName()
		local record = room:getTag(tagname):toString()
		room:removeTag(tagname)
		if record == "" then return false end
		local back = {}
		for _, s in ipairs(record:split("+")) do
			local parts = s:split(":")
			local id, owner_name = tonumber(parts[1]), parts[2]
			if id and owner_name and room:getCardPlace(id) == sgs.Player_PlaceHand then
				local holder = room:getCardOwner(id)
				if holder and holder:objectName() == player:objectName() then
					back[owner_name] = back[owner_name] or {}
					table.insert(back[owner_name], id)
				end
			end
		end
		for _, owner in sgs.qlist(room:getOtherPlayers(player)) do
			local ids = back[owner:objectName()]
			if ids and owner:isAlive() then
				local move = sgs.CardsMoveStruct()
				for _, id in ipairs(ids) do move.card_ids:append(id) end
				move.to = owner
				move.to_place = sgs.Player_PlaceHand
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), owner:objectName(), "sk_taoxi", "")
				room:moveCardsAtomic(move, false)
			end
		end
		return false
	end,
}

extension:insertRelatedSkills("sk_taoxi", "#sk_taoxi")


sk_caoxiu:addSkill(sk_taoxi)
sk_caoxiu:addSkill(sk_taoxiReturn)


sgs.LoadTranslationTable{
	["sk_caoxiu"] = "SK曹休",
	["&sk_caoxiu"] = "曹休",
	["sk_taoxi"] = "讨袭",
	["sk_taoxiCard"] = "讨袭",
	[":sk_taoxi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得所有其他角色的手牌各一张；然后此阶段结束时，你将手牌中剩余的牌还给对应角色。",
	["designer:sk_caoxiu"] = "极略三国",
    ["illustrator:sk_caoxiu"] = "极略三国",
    ["cv:sk_caoxiu"] = "极略三国",
}


--关羽
sk_guanyu = sgs.General(extension, "sk_guanyu", "shu", 4, true)


--[[
	技能名：单骑
	相关武将：SK关羽
	技能描述：觉醒技，准备阶段，若你的手牌数大于体力值，你减1点体力上限，回复1点体力，获得技能“拖刀”。
	引用：sk_danqi
]]--
sk_danqi = sgs.CreateTriggerSkillV2{
	name = "sk_danqi",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		if player:getMark("sk_danqi") ~= 0 then return false end
		if player:getHandcardNum() <= player:getHp() then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:addPlayerMark(player, "sk_danqi")
		local msg = sgs.LogMessage()
		msg.type = "#sk_danqiWake"
		msg.from = player
		msg.arg = skill:objectName()
		room:sendLog(msg)
		room:loseMaxHp(player, 1)
		local rec = sgs.RecoverStruct()
		rec.who = player
		room:recover(player, rec)
		room:acquireSkill(player, "sk_tuodao")
		return false
	end,
}


--[[
	技能名：拖刀
	相关武将：SK关羽
	技能描述：当你使用【闪】抵消一名角色对你使用的【杀】时，若其在你攻击范围内，你可以对其使用一张【杀】，此牌无视防具且不能被响应。
	引用：sk_tuodao
]]--
sk_tuodao = sgs.CreateTriggerSkillV2{
	name = "sk_tuodao",
	events = {sgs.SlashMissed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local effect = data:toSlashEffect()
		if not (effect.to and effect.to:objectName() == player:objectName()) then return false end
		if not effect.jink then return false end
		if not (effect.from and effect.from:isAlive()) then return false end
		if not player:inMyAttackRange(effect.from) then return false end
		if not player:canSlash(effect.from, nil, false) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toSlashEffect()
		if not (effect.from and effect.from:isAlive()) then return false end
		room:setPlayerFlag(player, "sk_tuodao_asking")
		room:askForUseSlashTo(player, effect.from, "@sk_tuodao:" .. effect.from:objectName(), false)
		room:setPlayerFlag(player, "-sk_tuodao_asking")
		return false
	end,
}

sk_tuodaoMod = sgs.CreateTriggerSkillV2{
	name = "#sk_tuodao",
	events = {sgs.PreCardUsed, sgs.TargetConfirmed, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("sk_tuodao")) then return false end
		local use = data:toCardUse()
		if not (use.from and use.from:objectName() == player:objectName()) then return false end
		if event == sgs.PreCardUsed then
			if player:hasFlag("sk_tuodao_asking") and use.card and use.card:isKindOf("Slash") then
				return skill:objectName()
			end
		elseif event == sgs.TargetConfirmed then
			if use.card and use.card:hasFlag("sk_tuodao_slash") then
				return skill:objectName()
			end
		elseif event == sgs.CardFinished then
			if use.card and use.card:hasFlag("sk_tuodao_slash") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if event == sgs.PreCardUsed then
			room:setCardFlag(use.card, "sk_tuodao_slash")
		elseif event == sgs.TargetConfirmed then
			local no_respond_list = use.no_respond_list
			if not table.contains(no_respond_list, "_ALL_TARGETS") then
				table.insert(no_respond_list, "_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
			for _, t in sgs.qlist(use.to) do
				room:addPlayerMark(t, "Armor_Nullified")
			end
		elseif event == sgs.CardFinished then
			room:setCardFlag(use.card, "-sk_tuodao_slash")
			for _, t in sgs.qlist(use.to) do
				room:removePlayerMark(t, "Armor_Nullified")
			end
		end
		return false
	end,
}

extension:insertRelatedSkills("sk_tuodao", "#sk_tuodao")

local sk_tuodao_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sk_tuodao") then sk_tuodao_skills:append(sk_tuodao) end
if not sgs.Sanguosha:getSkill("#sk_tuodao") then sk_tuodao_skills:append(sk_tuodaoMod) end
sgs.Sanguosha:addSkills(sk_tuodao_skills)


sk_guanyu:addSkill("wusheng")
sk_guanyu:addSkill(sk_danqi)


sgs.LoadTranslationTable{
	["sk_guanyu"] = "SK关羽",
	["&sk_guanyu"] = "关羽",
	["sk_danqi"] = "单骑",
	[":sk_danqi"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段，若你的手牌数大于体力值，你减1点体力上限，回复1点体力，获得技能“拖刀”。",
	["#sk_danqiWake"] = "%from 的“%arg”觉醒，减1点体力上限并回复1点体力，获得技能“拖刀”",
	["sk_tuodao"] = "拖刀",
	[":sk_tuodao"] = "当你使用【闪】抵消一名角色对你使用的【杀】时，若其在你攻击范围内，你可以对其使用一张【杀】，此牌无视防具且不能被响应。",
	["@sk_tuodao"] = "拖刀：你可以对 %src 使用一张【杀】（无视防具且不能被响应）",
	["#sk_tuodao"] = "拖刀",
	["designer:sk_guanyu"] = "极略三国",
    ["illustrator:sk_guanyu"] = "极略三国",
    ["cv:sk_guanyu"] = "极略三国",
}


--辛宪英
sk_xinxianying = sgs.General(extension, "sk_xinxianying", "wei", 3, false)


local function sk_caijian_put(room, player, target)
	if not (target and target:isAlive()) then return end
	if target:isNude() then return end
	local id = room:askForCardChosen(player, target, "he", "sk_caijian")
	local card = sgs.Sanguosha:getCard(id)
	local flip = card:isBlack()
	if flip then
		for _, pid in sgs.qlist(player:getPile("sk_jian")) do
			if sgs.Sanguosha:getCard(pid):getSuit() == card:getSuit() then
				flip = false
				break
			end
		end
	end
	player:addToPile("sk_jian", id, true)
	if flip and target:isAlive() then
		target:turnOver()
	end
end


--[[
	技能名：才鉴
	相关武将：SK辛宪英
	技能描述：出牌阶段限一次，或当你受到伤害后，你可以将一名角色的一张牌置于武将牌上，称为“鉴”。若此牌为黑色且与其他牌花色不同，该角色翻面。
	引用：sk_caijian
]]--
sk_caijianCard = sgs.CreateSkillCard{
	name = "sk_caijianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		sk_caijian_put(room, source, targets[1])
	end,
}

sk_caijianVS = sgs.CreateViewAsSkillV2{
	name = "sk_caijian",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#sk_caijianCard")
	end,
	create_card = function(skill, request)
		return sk_caijianCard:clone()
	end,
}

sk_caijian = sgs.CreateTriggerSkillV2{
	name = "sk_caijian",
	view_as_skill = sk_caijianVS,
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isNude() then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isNude() then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		local to = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_caijian-choose", true, true)
		if to then
			ctx.targets:append(to)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		sk_caijian_put(room, player, target)
		return false
	end,
}


--[[
	技能名：智识
	相关武将：SK辛宪英
	技能描述：出牌阶段，你可以将三张花色不同的“鉴”置入弃牌堆，然后摸三张牌并随机获得一个未上场魏势力角色的所有技能。
	引用：sk_zhishi
]]--
sk_zhishiCard = sgs.CreateSkillCard{
	name = "sk_zhishiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(self:getSubcards())
		room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, source:objectName(), "sk_zhishi", ""), nil)
		dummy:deleteLater()
		source:drawCards(3, "sk_zhishi")
		local all = sgs.Sanguosha:getLimitedGeneralNames()
		for _, p in sgs.qlist(room:getPlayers()) do
			if p:getGeneral() and table.contains(all, p:getGeneralName()) then
				table.removeOne(all, p:getGeneralName())
			end
			if p:getGeneral2() and table.contains(all, p:getGeneral2Name()) then
				table.removeOne(all, p:getGeneral2Name())
			end
		end
		local candidates = {}
		for _, name in ipairs(all) do
			local gen = sgs.Sanguosha:getGeneral(name)
			if gen and gen:getKingdom() == "wei" then
				local skills = {}
				for _, sk in sgs.qlist(gen:getSkillList()) do
					local sname = sk:objectName()
					if not sk:isLordSkill() and string.sub(sname, 1, 1) ~= "#" and not source:hasSkill(sname) then
						table.insert(skills, sname)
					end
				end
				if #skills > 0 then
					table.insert(candidates, {name = name, skills = skills})
				end
			end
		end
		if #candidates > 0 then
			local chosen = candidates[math.random(1, #candidates)]
			local log = sgs.LogMessage()
			log.type = "#sk_zhishiAcquire"
			log.from = source
			log.arg = chosen.name
			room:sendLog(log)
			for _, sname in ipairs(chosen.skills) do
				room:acquireSkill(source, sname)
			end
		end
	end,
}

sk_zhishi = sgs.CreateViewAsSkillV2{
	name = "sk_zhishi",
	n = 3,
	expand_pile = "sk_jian",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local suits = {}
		for _, id in sgs.qlist(player:getPile("sk_jian")) do
			suits[sgs.Sanguosha:getCard(id):getSuit()] = true
		end
		local count = 0
		for _ in pairs(suits) do count = count + 1 end
		return count >= 3
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not (player and to_select) then return false end
		if not player:getPile("sk_jian"):contains(to_select:getEffectiveId()) then return false end
		if request:getSelectedCardIds():length() >= 3 then return false end
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			if sgs.Sanguosha:getCard(id):getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 3
	end,
	create_card = function(skill, request)
		local card = sk_zhishiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(skill:objectName())
		return card
	end,
}


sk_xinxianying:addSkill(sk_caijian)
sk_xinxianying:addSkill(sk_zhishi)


sgs.LoadTranslationTable{
	["sk_xinxianying"] = "SK辛宪英",
	["&sk_xinxianying"] = "辛宪英",
	["sk_jian"] = "鉴",
	["sk_caijian"] = "才鉴",
	["sk_caijianCard"] = "才鉴",
	[":sk_caijian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>或当你受到伤害后，你可以将一名角色的一张牌置于武将牌上，称为“鉴”。若此牌为黑色且与其他牌花色不同，该角色翻面。",
	["@sk_caijian-choose"] = "才鉴：你可以将一名角色的一张牌置于你的武将牌上，称为“鉴”",
	["sk_zhishi"] = "智识",
	["sk_zhishiCard"] = "智识",
	[":sk_zhishi"] = "出牌阶段，你可以将三张花色不同的“鉴”置入弃牌堆，然后摸三张牌并随机获得一个未上场魏势力角色的所有技能。",
	["#sk_zhishiAcquire"] = "%from 发动“智识”，随机获得了 %arg 的所有技能",
	["designer:sk_xinxianying"] = "极略三国",
    ["illustrator:sk_xinxianying"] = "极略三国",
    ["cv:sk_xinxianying"] = "极略三国",
}


--王朗
sk_wanglang = sgs.General(extension, "sk_wanglang", "wei", 3, true)


local function sk_raoshe_gain(room, player, n)
	room:addPlayerMark(player, "@sk_raoshe", n)
	if player:getMark("@sk_raoshe") >= 7 then
		room:killPlayer(player)
	end
end


--[[
	技能名：劝降
	相关武将：SK王朗
	技能描述：出牌阶段，你可以与一名其他角色拼点。若你赢，其失去所有体力且此阶段“劝降”失效，若其未因此死亡，其回复等量体力，然后你获得1枚“饶舌”标记；若你没赢，你获得2枚“饶舌”标记。若你拥有7枚“饶舌”标记，你死亡。
	引用：sk_quanxiang
]]--
sk_quanxiangCard = sgs.CreateSkillCard{
	name = "sk_quanxiangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if source:pindian(target, "sk_quanxiang", nil) then
			room:setPlayerFlag(source, "sk_quanxiang_invalid")
			local hp = target:getHp()
			if hp > 0 then room:loseHp(target, hp, true, source, "sk_quanxiang") end
			if target:isAlive() then
				room:recover(target, sgs.RecoverStruct(source, nil, hp))
				sk_raoshe_gain(room, source, 1)
			end
		else
			sk_raoshe_gain(room, source, 2)
		end
	end,
}

sk_quanxiang = sgs.CreateViewAsSkillV2{
	name = "sk_quanxiang",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasFlag("sk_quanxiang_invalid") and not player:isKongcheng()
	end,
	create_card = function(skill, request)
		return sk_quanxiangCard:clone()
	end,
}


--[[
	技能名：鼓舌
	相关武将：SK王朗
	技能描述：锁定技，你的拼点牌点数+X（X为“饶舌”标记数）；你参与的拼点结算后，若你赢/没赢，你获得对方/你的拼点牌。
	引用：sk_gushe
]]--
sk_gushe = sgs.CreateTriggerSkillV2{
	name = "sk_gushe",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PindianVerifying, sgs.Pindian},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local pindian = data:toPindian()
		if not (pindian.from and pindian.to) then return false end
		local me = player:objectName()
		if pindian.from:objectName() ~= me and pindian.to:objectName() ~= me then return false end
		if event == sgs.PindianVerifying and player:getMark("@sk_raoshe") <= 0 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		local data = ctx.original_data
		local pindian = data:toPindian()
		local me = player:objectName()
		if event == sgs.PindianVerifying then
			local x = player:getMark("@sk_raoshe")
			if pindian.from:objectName() == me then
				pindian.from_number = pindian.from_number + x
			end
			if pindian.to:objectName() == me then
				pindian.to_number = pindian.to_number + x
			end
			data:setValue(pindian)
		elseif event == sgs.Pindian then
			local is_from = pindian.from:objectName() == me
			local win
			if is_from then
				win = pindian.success
			else
				win = pindian.to_number > pindian.from_number
			end
			local card
			if win then
				card = is_from and pindian.to_card or pindian.from_card
			else
				card = is_from and pindian.from_card or pindian.to_card
			end
			if card and room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable then
				room:obtainCard(player, card, true)
			end
		end
		return false
	end,
}


--[[
	技能名：激词
	相关武将：SK王朗
	技能描述：当你受到其他角色对你造成的伤害时，你可以令其摸一张牌，然后与其拼点。若你赢，防止此伤害；若你没赢，此伤害改为1，你获得1枚“饶舌”标记。若你拥有7枚“饶舌”标记，你死亡。
	引用：sk_jici
]]--
sk_jici = sgs.CreateTriggerSkillV2{
	name = "sk_jici",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:isKongcheng() then return false end
		local damage = data:toDamage()
		if not (damage.from and damage.from:isAlive()) then return false end
		if damage.from:objectName() == player:objectName() then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local data = ctx.original_data
		local damage = data:toDamage()
		if not (damage.from and damage.from:isAlive()) then return false end
		damage.from:drawCards(1, "sk_jici")
		if player:isKongcheng() or damage.from:isKongcheng() then return false end
		if player:pindian(damage.from, "sk_jici", nil) then
			local log = sgs.LogMessage()
			log.type = "#sk_jiciPrevent"
			log.from = player
			log.arg = tostring(damage.damage)
			room:sendLog(log)
			return true
		else
			damage.damage = 1
			data:setValue(damage)
			sk_raoshe_gain(room, player, 1)
		end
		return false
	end,
}


sk_wanglang:addSkill(sk_quanxiang)
sk_wanglang:addSkill(sk_gushe)
sk_wanglang:addSkill(sk_jici)


sgs.LoadTranslationTable{
	["sk_wanglang"] = "SK王朗",
	["&sk_wanglang"] = "王朗",
	["@sk_raoshe"] = "饶舌",
	["sk_quanxiang"] = "劝降",
	["sk_quanxiangCard"] = "劝降",
	[":sk_quanxiang"] = "出牌阶段，你可以与一名其他角色拼点。若你赢，其失去所有体力且此阶段“劝降”失效，若其未因此死亡，其回复等量体力，然后你获得1枚“饶舌”标记；若你没赢，你获得2枚“饶舌”标记。若你拥有7枚“饶舌”标记，你死亡。",
	["sk_gushe"] = "鼓舌",
	[":sk_gushe"] = "<font color=\"blue\"><b>锁定技，</b></font>你的拼点牌点数+X（X为“饶舌”标记数）；你参与的拼点结算后，若你赢/没赢，你获得对方/你的拼点牌。",
	["sk_jici"] = "激词",
	[":sk_jici"] = "当你受到其他角色对你造成的伤害时，你可以令其摸一张牌，然后与其拼点。若你赢，防止此伤害；若你没赢，此伤害改为1，你获得1枚“饶舌”标记。若你拥有7枚“饶舌”标记，你死亡。",
	["#sk_jiciPrevent"] = "%from 的“激词”拼点赢，防止了 %arg 点伤害",
	["designer:sk_wanglang"] = "极略三国",
    ["illustrator:sk_wanglang"] = "极略三国",
    ["cv:sk_wanglang"] = "极略三国",
}


--sp姜维
sk_spjiangwei = sgs.General(extension, "sk_spjiangwei", "shu", 5, true)


--[[
	技能名：困奋
	相关武将：SKsp姜维
	技能描述：锁定技，当你受到伤害后、或失去体力后、或减体力上限后，你摸三张牌；然后若为本回合首次发动“困奋”，你回复1点体力。
	引用：sk_kunfen
]]--
sk_kunfen = sgs.CreateTriggerSkillV2{
	name = "sk_kunfen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.HpLost, sgs.MaxHpChanged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not (damage.to and damage.to:objectName() == player:objectName()) then return false end
		elseif event == sgs.HpLost then
			if data:toHpLost().lose <= 0 then return false end
		elseif event == sgs.MaxHpChanged then
			local change = data:toMaxHp()
			if change.who and change.who:objectName() ~= player:objectName() then return false end
			if change.change >= 0 then return false end
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		player:drawCards(3, skill:objectName())
		if player:getMark("sk_kunfen-Clear") == 0 then
			room:addPlayerMark(player, "sk_kunfen-Clear")
			if player:isAlive() and player:isWounded() then
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		end
		return false
	end,
}


--[[
	技能名：才遇
	相关武将：SKsp姜维
	技能描述：准备阶段，你可以减1点体力上限，然后随机获得任一普通诸葛亮或sp神诸葛亮的一个技能。
	引用：sk_caiyu
	备注：技能池取自以下武将（存在者才计入）：zhugeliang、wolong、sr_zhugeliang、sgkgodspzhuge。
]]--
local sk_caiyu_generals = {"zhugeliang", "wolong", "sr_zhugeliang", "sgkgodspzhuge"}

sk_caiyu = sgs.CreateTriggerSkillV2{
	name = "sk_caiyu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:loseMaxHp(player)
		if player:isDead() then return false end
		local candidates = {}
		for _, gname in ipairs(sk_caiyu_generals) do
			local gen = sgs.Sanguosha:getGeneral(gname)
			if gen then
				for _, sk in sgs.qlist(gen:getSkillList()) do
					local sname = sk:objectName()
					if not sk:isLordSkill() and string.sub(sname, 1, 1) ~= "#" and not player:hasSkill(sname) then
						table.insert(candidates, sname)
					end
				end
			end
		end
		if #candidates > 0 then
			local sname = candidates[math.random(1, #candidates)]
			local log = sgs.LogMessage()
			log.type = "#sk_caiyuAcquire"
			log.from = player
			log.arg = sname
			room:sendLog(log)
			room:acquireSkill(player, sname)
		end
		return false
	end,
}


sk_spjiangwei:addSkill(sk_kunfen)
sk_spjiangwei:addSkill(sk_caiyu)


sgs.LoadTranslationTable{
	["sk_spjiangwei"] = "SKsp姜维",
	["&sk_spjiangwei"] = "sp姜维",
	["sk_kunfen"] = "困奋",
	[":sk_kunfen"] = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害后、或失去体力后、或减体力上限后，你摸三张牌；然后若为本回合首次发动“困奋”，你回复1点体力。",
	["sk_caiyu"] = "才遇",
	[":sk_caiyu"] = "准备阶段，你可以减1点体力上限，然后随机获得任一普通诸葛亮或sp神诸葛亮的一个技能。",
	["#sk_caiyuAcquire"] = "%from 的“才遇”随机获得了技能 %arg",
	["designer:sk_spjiangwei"] = "极略三国",
    ["illustrator:sk_spjiangwei"] = "极略三国",
    ["cv:sk_spjiangwei"] = "极略三国",
}


--公孙瓒
sk_gongsunzan = sgs.General(extension, "sk_gongsunzan", "qun", 4, true)


--[[
	技能名：义从
	相关武将：SK公孙瓒
	技能描述：锁定技，若你体力值大于2，你计算到其他角色的距离-1；若你的体力值不大于2，其他角色计算到你的距离+1。
	引用：sk_yicong
]]--
sk_yicong = sgs.CreateTriggerSkillV2{
	name = "sk_yicong",
	frequency = sgs.Skill_Compulsory,
	events = {},
}

sk_yicongDist = sgs.CreateDistanceSkillV2{
	name = "#sk_yicong",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local from, to = ctx:getPrimary(), ctx:getSecondary()
		local correct = 0
		if from and from:hasSkill("sk_yicong") and from:getHp() > 2 then correct = correct - 1 end
		if to and to:hasSkill("sk_yicong") and to:getHp() <= 2 then correct = correct + 1 end
		if correct == 0 then return false end
		return correct
	end,
}


--[[
	技能名：募马
	相关武将：SK公孙瓒
	技能描述：锁定技，你的回合外，当其他角色装备区内的坐骑牌置入弃牌堆后，若你的装备区内没有坐骑牌，你可以获得之。
	引用：sk_muma
]]--
sk_muma = sgs.CreateTriggerSkillV2{
	name = "sk_muma",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		if player:getOffensiveHorse() or player:getDefensiveHorse() then return false end
		local move = data:toMoveOneTime()
		if not (move.from and move.from:objectName() ~= player:objectName()) then return false end
		if move.to_place ~= sgs.Player_DiscardPile then return false end
		local i = 0
		for _, card_id in sgs.qlist(move.card_ids) do
			if move.from_places:at(i) == sgs.Player_PlaceEquip and sgs.Sanguosha:getCard(card_id):isKindOf("Horse")
				and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				return skill:objectName()
			end
			i = i + 1
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local horses = sgs.IntList()
		local i = 0
		for _, card_id in sgs.qlist(move.card_ids) do
			if move.from_places:at(i) == sgs.Player_PlaceEquip and sgs.Sanguosha:getCard(card_id):isKindOf("Horse")
				and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				horses:append(card_id)
			end
			i = i + 1
		end
		if horses:isEmpty() then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(horses)
		room:obtainCard(player, dummy, true)
		dummy:deleteLater()
		return false
	end,
}


sk_gongsunzan:addSkill(sk_yicong)
sk_gongsunzan:addSkill(sk_yicongDist)
sk_gongsunzan:addSkill(sk_muma)
extension:insertRelatedSkills("sk_yicong", "#sk_yicong")


sgs.LoadTranslationTable{
	["sk_gongsunzan"] = "SK公孙瓒",
	["&sk_gongsunzan"] = "公孙瓒",
	["sk_yicong"] = "义从",
	[":sk_yicong"] = "<font color=\"blue\"><b>锁定技，</b></font>若你体力值大于2，你计算到其他角色的距离-1；若你的体力值不大于2，其他角色计算到你的距离+1。",
	["sk_muma"] = "募马",
	[":sk_muma"] = "<font color=\"blue\"><b>锁定技，</b></font>你的回合外，当其他角色装备区内的坐骑牌置入弃牌堆后，若你的装备区内没有坐骑牌，你可以获得之。",
	["designer:sk_gongsunzan"] = "极略三国",
    ["illustrator:sk_gongsunzan"] = "极略三国",
    ["cv:sk_gongsunzan"] = "极略三国",
}


--左慈
sk_zuoci = sgs.General(extension, "sk_zuoci", "qun", 3, true)


--[[
	技能名：千幻
	相关武将：SK左慈
	技能描述：锁定技，游戏开始时，你随机展示三张未上场的武将牌，然后获得这些武将牌上的共计两个技能。回合开始时，你随机展示三张未上场的武将牌，你可以失去以此法获得的任意个技能，然后将技能补至两个。锁定技，游戏开始时，若本局为双将，你移除另一个武将，然后本局你获得技能的上限改为四个。
	引用：sk_qianhuan
]]--
local function sk_qianhuan_acquired(player)
	local str = player:getTag("sk_qianhuan_skills"):toString()
	if not str or str == "" then return {} end
	return str:split("+")
end

local function sk_qianhuan_record(player, list)
	player:setTag("sk_qianhuan_skills", sgs.QVariant(table.concat(list, "+")))
end

local function sk_qianhuan_limit(player)
	if player:getMark("sk_qianhuan_four") > 0 then return 4 end
	return 2
end

local function sk_qianhuan_skillOk(player, sk)
	local sname = sk:objectName()
	return not sk:isLordSkill() and string.sub(sname, 1, 1) ~= "#" and sname ~= "sk_qianhuan" and not player:hasSkill(sname)
end

local function sk_qianhuan_show(room, player)
	local all = sgs.Sanguosha:getLimitedGeneralNames()
	for _, p in sgs.qlist(room:getPlayers()) do
		if p:getGeneral() and table.contains(all, p:getGeneralName()) then
			table.removeOne(all, p:getGeneralName())
		end
		if p:getGeneral2() and table.contains(all, p:getGeneral2Name()) then
			table.removeOne(all, p:getGeneral2Name())
		end
	end
	local candidates = {}
	for _, name in ipairs(all) do
		local gen = sgs.Sanguosha:getGeneral(name)
		if gen then
			for _, sk in sgs.qlist(gen:getVisibleSkillList()) do
				if sk_qianhuan_skillOk(player, sk) then
					table.insert(candidates, name)
					break
				end
			end
		end
	end
	local shown, skills = {}, {}
	for i = 1, 3 do
		if #candidates == 0 then break end
		local idx = math.random(1, #candidates)
		table.insert(shown, candidates[idx])
		table.remove(candidates, idx)
	end
	for _, name in ipairs(shown) do
		local log = sgs.LogMessage()
		log.type = "#sk_qianhuanShow"
		log.from = player
		log.arg = name
		room:sendLog(log)
		local gen = sgs.Sanguosha:getGeneral(name)
		for _, sk in sgs.qlist(gen:getVisibleSkillList()) do
			if sk_qianhuan_skillOk(player, sk) and not table.contains(skills, sk:objectName()) then
				table.insert(skills, sk:objectName())
			end
		end
	end
	return skills
end

local function sk_qianhuan_lose(room, player)
	local acquired = sk_qianhuan_acquired(player)
	while #acquired > 0 and player:isAlive() do
		local choice = room:askForChoice(player, "sk_qianhuan", table.concat(acquired, "+") .. "+cancel")
		if choice == "cancel" then break end
		table.removeOne(acquired, choice)
		sk_qianhuan_record(player, acquired)
		local log = sgs.LogMessage()
		log.type = "#sk_qianhuanLose"
		log.from = player
		log.arg = choice
		room:sendLog(log)
		room:handleAcquireDetachSkills(player, "-" .. choice)
	end
end

local function sk_qianhuan_fill(room, player, skills)
	local acquired = sk_qianhuan_acquired(player)
	local limit = sk_qianhuan_limit(player)
	while #acquired < limit and player:isAlive() do
		local choices = {}
		for _, sname in ipairs(skills) do
			if not player:hasSkill(sname) and not table.contains(acquired, sname) then
				table.insert(choices, sname)
			end
		end
		if #choices == 0 then break end
		local choice = room:askForChoice(player, "sk_qianhuan", table.concat(choices, "+"))
		table.insert(acquired, choice)
		sk_qianhuan_record(player, acquired)
		local log = sgs.LogMessage()
		log.type = "#sk_qianhuanAcquire"
		log.from = player
		log.arg = choice
		room:sendLog(log)
		room:acquireSkill(player, choice)
	end
end

sk_qianhuan = sgs.CreateTriggerSkillV2{
	name = "sk_qianhuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_RoundStart then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		if event == sgs.GameStart then
			if player:getGeneral2() then
				room:setPlayerMark(player, "sk_qianhuan_four", 1)
				if player:getGeneral2Name() == "sk_zuoci" then
					room:changeHero(player, "sujiang", false, false, false, true)
				else
					room:changeHero(player, "sujiang", false, false, true, true)
				end
			end
			local skills = sk_qianhuan_show(room, player)
			sk_qianhuan_fill(room, player, skills)
		else
			local skills = sk_qianhuan_show(room, player)
			sk_qianhuan_lose(room, player)
			sk_qianhuan_fill(room, player, skills)
		end
		return false
	end,
}


sk_zuoci:addSkill(sk_qianhuan)


sgs.LoadTranslationTable{
	["sk_zuoci"] = "SK左慈",
	["&sk_zuoci"] = "左慈",
	["#sk_zuoci"] = "迷之仙人",
	["sk_qianhuan"] = "千幻",
	[":sk_qianhuan"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你随机展示三张未上场的武将牌，然后获得这些武将牌上的共计两个技能。回合开始时，你随机展示三张未上场的武将牌，你可以失去以此法获得的任意个技能，然后将技能补至两个。<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，若本局为双将，你移除另一个武将，然后本局你获得技能的上限改为四个。",
	["sk_qianhuan:cancel"] = "不再失去技能",
	["#sk_qianhuanShow"] = "%from 的“千幻”展示了武将牌 %arg",
	["#sk_qianhuanAcquire"] = "%from 的“千幻”获得了技能 %arg",
	["#sk_qianhuanLose"] = "%from 的“千幻”失去了技能 %arg",
	["designer:sk_zuoci"] = "极略三国",
    ["illustrator:sk_zuoci"] = "极略三国",
    ["cv:sk_zuoci"] = "极略三国",
}


--吉平
sk_jiping = sgs.General(extension, "sk_jiping", "qun", 3, true)


--[[
	技能名：毒治
	相关武将：SK吉平
	技能描述：当你回复1点体力后，或使用红色【杀】造成伤害后，你可以令一名其他角色失去1点体力，然后其可以对你使用一张无距离限制的【杀】。
	引用：sk_duzhi
]]--
local function sk_duzhi_effect(room, player, skillname)
	local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skillname, "@sk_duzhi-target", true, true)
	if not (target and target:isAlive()) then return end
	room:broadcastSkillInvoke(skillname)
	room:doAnimate(1, player:objectName(), target:objectName())
	room:loseHp(target, 1)
	if target:isAlive() and player:isAlive() and target:canSlash(player, nil, false) then
		room:askForUseSlashTo(target, player, "@sk_duzhi-slash:" .. player:objectName(), false)
	end
end

sk_duzhi = sgs.CreateTriggerSkillV2{
	name = "sk_duzhi",
	events = {sgs.HpRecover, sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.HpRecover then
			if data:toRecover().recover <= 0 then return false end
		else
			local damage = data:toDamage()
			if not (damage.card and damage.card:isKindOf("Slash") and damage.card:isRed()
				and (not damage.chain) and (not damage.transfer)) then return false end
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.Damage then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damage then
			sk_duzhi_effect(room, player, skill:objectName())
		else
			local rec = ctx.original_data:toRecover()
			for i = 1, rec.recover do
				if not player:isAlive() then break end
				if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then break end
				sk_duzhi_effect(room, player, skill:objectName())
			end
		end
		return false
	end,
}


--[[
	技能名：烈医
	相关武将：SK吉平
	技能描述：锁定技，你的【桃】均视为【杀】；你的【闪】均视为【酒】。
	引用：sk_lieyi
]]--
sk_lieyi = sgs.CreateFilterSkill{
	name = "sk_lieyi",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Peach") or to_select:isKindOf("Jink")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local name = "slash"
		if card:isKindOf("Jink") then name = "analeptic" end
		local new_card = sgs.Sanguosha:cloneCard(name, card:getSuit(), card:getNumber())
		new_card:setSkillName(self:objectName())
		local wrapped = sgs.Sanguosha:getWrappedCard(card:getId())
		wrapped:takeOver(new_card)
		return wrapped
	end
}


sk_jiping:addSkill(sk_duzhi)
sk_jiping:addSkill(sk_lieyi)


sgs.LoadTranslationTable{
	["sk_jiping"] = "SK吉平",
	["&sk_jiping"] = "吉平",
	["#sk_jiping"] = "太医令",
	["sk_duzhi"] = "毒治",
	[":sk_duzhi"] = "当你回复1点体力后，或使用红色【杀】造成伤害后，你可以令一名其他角色失去1点体力，然后其可以对你使用一张无距离限制的【杀】。",
	["@sk_duzhi-target"] = "毒治：你可以令一名其他角色失去1点体力，然后其可以对你使用一张【杀】",
	["@sk_duzhi-slash"] = "毒治：你可以对 %src 使用一张【杀】（无距离限制）",
	["sk_lieyi"] = "烈医",
	[":sk_lieyi"] = "<font color=\"blue\"><b>锁定技，</b></font>你的【桃】均视为【杀】；你的【闪】均视为【酒】。",
	["designer:sk_jiping"] = "极略三国",
    ["illustrator:sk_jiping"] = "极略三国",
    ["cv:sk_jiping"] = "极略三国",
}


--何进
sk_hejin = sgs.General(extension, "sk_hejin", "qun", 4, true)


--[[
	技能名：专擅
	相关武将：SK何进
	技能描述：准备阶段或结束阶段，你可以令一名角色摸一张牌，然后你将该角色的一张牌置于牌堆顶。
	引用：sk_zhuanshan
]]--
sk_zhuanshan = sgs.CreateTriggerSkillV2{
	name = "sk_zhuanshan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_zhuanshan-target", true, true)
		if target then
			ctx.extra_data:setValue(target:objectName())
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = nil
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() == ctx.extra_data:toString() then target = p end
		end
		if not (target and target:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		target:drawCards(1, skill:objectName())
		if player:isAlive() and target:isAlive() and not target:isNude() then
			local id = room:askForCardChosen(player, target, "he", skill:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill:objectName(), "")
			room:moveCardTo(sgs.Sanguosha:getCard(id), target, nil, sgs.Player_DrawPile, reason)
		end
		return false
	end,
}


sk_hejin:addSkill(sk_zhuanshan)


sgs.LoadTranslationTable{
	["sk_hejin"] = "SK何进",
	["&sk_hejin"] = "何进",
	["#sk_hejin"] = "鸩杀的大将军",
	["sk_zhuanshan"] = "专擅",
	[":sk_zhuanshan"] = "准备阶段或结束阶段，你可以令一名角色摸一张牌，然后你将该角色的一张牌置于牌堆顶。",
	["@sk_zhuanshan-target"] = "专擅：你可以令一名角色摸一张牌，然后将其一张牌置于牌堆顶",
	["designer:sk_hejin"] = "极略三国",
    ["illustrator:sk_hejin"] = "极略三国",
    ["cv:sk_hejin"] = "极略三国",
}


--蒯越
sk_kuaiyue = sgs.General(extension, "sk_kuaiyue", "qun", 3, true)


local function sk_kuaiyue_lost(move)
	for _, place in sgs.qlist(move.from_places) do
		if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then return true end
	end
	return false
end

local function sk_kuaiyue_match(move, current)
	local suits = {}
	for i = 0, move.card_ids:length() - 1, 1 do
		local place = move.from_places:at(i)
		if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
			suits[sgs.Sanguosha:getCard(move.card_ids:at(i)):getSuit()] = true
		end
	end
	local x = 0
	for _, c in sgs.qlist(current:getHandcards()) do
		if suits[c:getSuit()] then x = x + 1 end
	end
	return x
end

--[[
	技能名：异度
	相关武将：SK蒯越
	技能描述：每回合限一次，你的回合外，当你失去牌时，你可以摸X张牌（X为当前回合角色手牌中与这些牌花色相同的牌数）。
	引用：sk_yidu
]]--
sk_yidu = sgs.CreateTriggerSkillV2{
	name = "sk_yidu",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if not move.from then return false end
		local current = room:getCurrent()
		if not (current and current:isAlive()) then return false end
		if current:objectName() == move.from:objectName() then return false end
		if not sk_kuaiyue_lost(move) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, kuaiyue in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if kuaiyue:isAlive() and kuaiyue:objectName() == move.from:objectName()
				and kuaiyue:getMark("sk_yidu-Clear") == 0 then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, kuaiyue:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerMark(player, "sk_yidu-Clear")
		local current = room:getCurrent()
		if not (current and current:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local x = sk_kuaiyue_match(ctx.original_data:toMoveOneTime(), current)
		if x > 0 then
			player:drawCards(x, skill:objectName())
		end
		return false
	end,
}


--[[
	技能名：诛暴
	相关武将：SK蒯越
	技能描述：每回合每名其他角色限一次，你的回合内，当其他角色失去牌时，你可以摸X张牌（X为当前回合角色手牌中与这些牌花色相同的手牌数）。
	引用：sk_zhubao
]]--
sk_zhubao = sgs.CreateTriggerSkillV2{
	name = "sk_zhubao",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if not move.from then return false end
		local current = room:getCurrent()
		if not (current and current:isAlive() and current:hasSkill(skill:objectName())) then return false end
		if current:objectName() == move.from:objectName() then return false end
		if current:getMark("sk_zhubao#" .. move.from:objectName() .. "-Clear") > 0 then return false end
		if not sk_kuaiyue_lost(move) then return false end
		return skill:objectName(), current:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		room:addPlayerMark(player, "sk_zhubao#" .. move.from:objectName() .. "-Clear")
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local x = sk_kuaiyue_match(move, player)
		if x > 0 then
			player:drawCards(x, skill:objectName())
		end
		return false
	end,
}


sk_kuaiyue:addSkill(sk_yidu)
sk_kuaiyue:addSkill(sk_zhubao)


sgs.LoadTranslationTable{
	["sk_kuaiyue"] = "SK蒯越",
	["&sk_kuaiyue"] = "蒯越",
	["sk_yidu"] = "异度",
	[":sk_yidu"] = "每回合限一次，你的回合外，当你失去牌时，你可以摸X张牌（X为当前回合角色手牌中与这些牌花色相同的牌数）。",
	["sk_zhubao"] = "诛暴",
	[":sk_zhubao"] = "每回合每名其他角色限一次，你的回合内，当其他角色失去牌时，你可以摸X张牌（X为当前回合角色手牌中与这些牌花色相同的手牌数）。",
	["designer:sk_kuaiyue"] = "极略三国",
    ["illustrator:sk_kuaiyue"] = "极略三国",
    ["cv:sk_kuaiyue"] = "极略三国",
}


--卢植
sk_luzhi = sgs.General(extension, "sk_luzhi", "qun", 3, true)


--[[
	技能名：经纶
	相关武将：SK卢植
	技能描述：每回合限一次，当你响应其他角色使用的牌，或其他角色响应你使用的牌时，你可以获得该角色使用或打出的牌。
	引用：sk_jinglun
]]--
sk_jinglun = sgs.CreateTriggerSkillV2{
	name = "sk_jinglun",
	events = {sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		local resp = data:toCardResponse()
		if not (resp.m_card and resp.m_who and resp.m_toCard) then return false end
		local touser = room:getCardUser(resp.m_toCard)
		if not touser then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, luzhi in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if luzhi:isAlive() and luzhi:getMark("sk_jinglun-Clear") == 0 then
				local hit = false
				if resp.m_who:objectName() == luzhi:objectName() then
					hit = touser:objectName() ~= luzhi:objectName()
				else
					hit = touser:objectName() == luzhi:objectName()
				end
				if hit then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, luzhi:objectName())
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerMark(player, "sk_jinglun-Clear")
		local resp = ctx.original_data:toCardResponse()
		local gain = nil
		if resp.m_who and resp.m_who:objectName() == player:objectName() then
			gain = resp.m_toCard
		else
			gain = resp.m_card
		end
		if not gain then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		if gain:isVirtualCard() then
			for _, id in sgs.qlist(gain:getSubcards()) do
				local owner = room:getCardOwner(id)
				if not owner or owner:objectName() ~= player:objectName()
					or room:getCardPlace(id) ~= sgs.Player_PlaceHand then
					room:obtainCard(player, id, true)
				end
			end
		else
			room:obtainCard(player, gain, true)
		end
		return false
	end,
}


--[[
	技能名：儒宗
	相关武将：SK卢植
	技能描述：你可以将【闪】当【无懈可击】使用；或将【无懈可击】当【闪】使用或打出。
	引用：sk_ruzong
]]--
sk_ruzong = sgs.CreateViewAsSkillV2{
	name = "sk_ruzong",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		pattern = pattern:split("+")[1]
		return pattern == "jink" or pattern == "nullification"
	end,
	can_select_card = function(skill, request, to_select)
		local pattern = request:getPattern() or ""
		pattern = pattern:split("+")[1]
		if pattern == "jink" then
			return to_select:isKindOf("Nullification")
		elseif pattern == "nullification" then
			return to_select:isKindOf("Jink")
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		if not card then return nil end
		local pattern = request:getPattern() or ""
		pattern = pattern:split("+")[1]
		local name = nil
		if pattern == "jink" and card:isKindOf("Nullification") then
			name = "jink"
		elseif pattern == "nullification" and card:isKindOf("Jink") then
			name = "nullification"
		end
		if not name then return nil end
		local new_card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, 0)
		new_card:setSkillName(skill:objectName())
		new_card:addSubcard(ids:first())
		return new_card
	end,
}
sk_ruzong.response_pattern = "nullification"


sk_luzhi:addSkill(sk_jinglun)
sk_luzhi:addSkill(sk_ruzong)


sgs.LoadTranslationTable{
	["sk_luzhi"] = "SK卢植",
	["&sk_luzhi"] = "卢植",
	["sk_jinglun"] = "经纶",
	[":sk_jinglun"] = "每回合限一次，当你响应其他角色使用的牌，或其他角色响应你使用的牌时，你可以获得该角色使用或打出的牌。",
	["sk_ruzong"] = "儒宗",
	[":sk_ruzong"] = "你可以将【闪】当【无懈可击】使用；或将【无懈可击】当【闪】使用或打出。",
	["designer:sk_luzhi"] = "极略三国",
    ["illustrator:sk_luzhi"] = "极略三国",
    ["cv:sk_luzhi"] = "极略三国",
}


--于吉
sk_yuji = sgs.General(extension, "sk_yuji", "qun", 3, true)


--[[
	技能名：蛊惑
	相关武将：SK于吉
	技能描述：其他角色的回合开始时，你可以与其拼点。若你赢，其视为使用一张牌名和目标由你指定的非装备牌（延时锦囊牌除外）；若你没赢，该角色对你造成1点伤害。
	引用：sk_guhuo
]]--
sk_guhuo = sgs.CreateTriggerSkillV2{
	name = "sk_guhuo",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart
			and not player:isKongcheng()) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, yuji in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if yuji:isAlive() and not yuji:isKongcheng()
				and yuji:objectName() ~= player:objectName() then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, yuji:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local _data = sgs.QVariant()
		_data:setValue(ctx.invoker)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if not (target and target:isAlive() and player:isAlive()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		if not player:pindian(target, skill:objectName(), nil) then
			room:damage(sgs.DamageStruct(skill:objectName(), target, player))
			return false
		end
		local names = {}
		for _, cn in ipairs(sgs.Sanguosha:getCardNames("BasicCard+TrickCard+^DelayedTrick")) do
			table.insert(names, cn)
		end
		if #names == 0 then return false end
		local name = room:askForChoice(player, "sk_guhuo", table.concat(names, "+"))
		if name == "slash" then
			name = room:askForChoice(player, "sk_guhuo_slash", table.concat(sgs.Sanguosha:getSlashNames(), "+"))
		end
		local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
		if not card then return false end
		card:setSkillName(skill:objectName())
		local use = sgs.CardUseStruct()
		use.from = target
		use.card = card
		if not card:targetFixed() then
			local picked = {}
			local plist = sgs.PlayerList()
			while not card:targetsFeasible(plist, target) do
				local candidates = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not picked[p:objectName()] and card:targetFilter(plist, p, target)
						and not target:isProhibited(p, card, plist) then
						candidates:append(p)
					end
				end
				if candidates:isEmpty() then card:deleteLater() return false end
				local t = room:askForPlayerChosen(player, candidates, skill:objectName(), "@sk_guhuo-target:" .. card:objectName(), true, true)
				if not t then card:deleteLater() return false end
				picked[t:objectName()] = true
				plist:append(t)
			end
			for _, p in sgs.qlist(plist) do
				use.to:append(p)
			end
		end
		room:useCard(use, true)
		card:deleteLater()
		return false
	end,
}


--[[
	技能名：符箓
	相关武将：SK于吉
	技能描述：当你受到伤害后，你可以令最近三名对你造成伤害的角色各随机弃置一张牌，最近三名令你回复体力的角色各摸一张牌。
	引用：sk_fulu
]]--
local function sk_fulu_push(room, tag, name)
	if not name or name == "" then return end
	local names = {}
	local record = room:getTag(tag):toString()
	if record ~= "" then
		for _, n in ipairs(record:split("+")) do
			if n ~= "" and n ~= name then table.insert(names, n) end
		end
	end
	table.insert(names, 1, name)
	while #names > 16 do table.remove(names) end
	room:setTag(tag, sgs.QVariant(table.concat(names, "+")))
end

sk_fuluRec = sgs.CreateTriggerSkillV2{
	name = "#sk_fulu",
	frequency = sgs.Skill_Compulsory,
	priority = 10,
	events = {sgs.Damaged, sgs.HpRecover},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("sk_fulu")) then return false end
		if event == sgs.Damaged then
			if data:toDamage().from then return skill:objectName() end
		else
			if data:toRecover().who then return skill:objectName() end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			local from = ctx.original_data:toDamage().from
			if from then sk_fulu_push(room, "sk_fulu_dmg@" .. player:objectName(), from:objectName()) end
		else
			local who = ctx.original_data:toRecover().who
			if who then sk_fulu_push(room, "sk_fulu_rec@" .. player:objectName(), who:objectName()) end
		end
		return false
	end,
}

sk_fulu = sgs.CreateTriggerSkillV2{
	name = "sk_fulu",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:notifySkillInvoked(player, skill:objectName())
		local damage = ctx.original_data:toDamage()
		if damage.from then
			sk_fulu_push(room, "sk_fulu_dmg@" .. player:objectName(), damage.from:objectName())
		end
		local record = room:getTag("sk_fulu_dmg@" .. player:objectName()):toString()
		local cnt = 0
		for _, n in ipairs(record ~= "" and record:split("+") or {}) do
			if cnt >= 3 then break end
			local p = room:findPlayerByObjectName(n)
			if p and p:isAlive() and not p:isNude() then
				cnt = cnt + 1
				room:doAnimate(1, player:objectName(), n)
				local ids = {}
				for _, id in sgs.qlist(p:getCards("he")) do table.insert(ids, id) end
				if #ids > 0 then
					room:throwCard(ids[math.random(1, #ids)], p)
				end
			end
		end
		record = room:getTag("sk_fulu_rec@" .. player:objectName()):toString()
		cnt = 0
		for _, n in ipairs(record ~= "" and record:split("+") or {}) do
			if cnt >= 3 then break end
			local p = room:findPlayerByObjectName(n)
			if p and p:isAlive() then
				cnt = cnt + 1
				room:doAnimate(1, player:objectName(), n)
				p:drawCards(1, skill:objectName())
			end
		end
		return false
	end,
}


sk_yuji:addSkill(sk_guhuo)
sk_yuji:addSkill(sk_fulu)
sk_yuji:addSkill(sk_fuluRec)
extension:insertRelatedSkills("sk_fulu", "#sk_fulu")


sgs.LoadTranslationTable{
	["sk_yuji"] = "SK于吉",
	["&sk_yuji"] = "于吉",
	["sk_guhuo"] = "蛊惑",
	[":sk_guhuo"] = "其他角色的回合开始时，你可以与其拼点。若你赢，其视为使用一张牌名和目标由你指定的非装备牌（延时锦囊牌除外）；若你没赢，该角色对你造成1点伤害。",
	["sk_guhuo_slash"] = "蛊惑",
	["@sk_guhuo-target"] = "蛊惑：请选择“%src”的目标",
	["sk_fulu"] = "符箓",
	[":sk_fulu"] = "当你受到伤害后，你可以令最近三名对你造成伤害的角色各随机弃置一张牌，最近三名令你回复体力的角色各摸一张牌。",
	["designer:sk_yuji"] = "极略三国",
    ["illustrator:sk_yuji"] = "极略三国",
    ["cv:sk_yuji"] = "极略三国",
}


--极略31 SP马超（jilue.md L2213-L2215）
sk_spmachao = sgs.General(extension, "sk_spmachao", "qun", 4, true)
sk_zhuiji = sgs.CreateTriggerSkillV2{
 name = "sk_zhuiji", frequency = sgs.Skill_Compulsory, events = {sgs.Damage},
 can_trigger = function(skill, event, room, player, data)
  local d = data:toDamage()
  if player and player:hasSkill(skill:objectName()) and d.from == player and d.to and d.to ~= player then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  room:addPlayerMark(player, "sk_zhuiji_" .. ctx.original_data:toDamage().to:objectName())
  return false
 end,
}
sk_zhuijiDist = sgs.CreateDistanceSkillV2{
 name = "#sk_zhuiji", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local from, to = ctx:getPrimary(), ctx:getSecondary()
  if from and to and from:hasSkill("sk_zhuiji") then return -from:getMark("sk_zhuiji_" .. to:objectName()) end
  return false
 end,
}
sk_xionglie = sgs.CreateTriggerSkillV2{
 name = "sk_xionglie", events = {sgs.TargetSpecified, sgs.ConfirmDamage, sgs.CardFinished},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.ConfirmDamage then
   local d = data:toDamage()
   if d.card and d.card:hasFlag("sk_xionglie_damage") then return skill:objectName() end
  else
   local use = data:toCardUse()
   if use.from == player and use.card and use.card:isKindOf("Slash") then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return event ~= sgs.TargetSpecified or player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local data = ctx.original_data
  if event == sgs.ConfirmDamage then
   local d = data:toDamage(); d.damage = d.damage + 1; data:setValue(d)
  else
   local use = data:toCardUse()
   if event == sgs.CardFinished then room:setCardFlag(use.card, "-sk_xionglie_damage") return false end
   local all = true
   for _, p in sgs.qlist(room:getOtherPlayers(player)) do if player:distanceTo(p) ~= 1 then all = false break end end
   local choice = all and "both" or room:askForChoice(player, skill:objectName(), "no_response+damage", data)
   if choice ~= "damage" then
    local list = use.no_respond_list
    if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
    use.no_respond_list = list; data:setValue(use)
   end
   if choice ~= "no_response" then room:setCardFlag(use.card, "sk_xionglie_damage") end
  end
  return false
 end,
}
sk_spmachao:addSkill(sk_zhuiji)
sk_spmachao:addSkill(sk_zhuijiDist)
sk_spmachao:addSkill(sk_xionglie)
extension:insertRelatedSkills("sk_zhuiji", "#sk_zhuiji")
sgs.LoadTranslationTable{
 ["sk_spmachao"] = "SKSP马超", ["&sk_spmachao"] = "SP马超", ["#sk_spmachao"] = "SP马超",
 ["sk_zhuiji"] = "追击", [":sk_zhuiji"] = "锁定技，当你对其他角色造成伤害后，你计算到该角色的距离-1。",
 ["sk_xionglie"] = "雄烈", [":sk_xionglie"] = "当你使用【杀】指定目标后，你可以选择一项：1.此牌不能被响应；2.此牌伤害+1。若你与所有其他角色的距离均为1，你改为依次执行两项。",
 ["no_response"] = "此牌不能被响应", ["damage"] = "此牌伤害+1",
}

--极略31 董白（jilue.md L2219-L2223）
sk_dongbai = sgs.General(extension, "sk_dongbai", "qun", 3, false)
sk_shemi = sgs.CreateTriggerSkillV2{
 name = "sk_shemi", frequency = sgs.Skill_Compulsory,
 events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.DrawNCards},
 on_record = function(skill, event, room, player, ctx)
  if not player or not player:hasSkill(skill:objectName()) then return end
  if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
   room:setPlayerMark(player, "sk_shemi_current", 0)
  elseif event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_Discard then
   local move = ctx.original_data:toMoveOneTime()
   if move.from and move.from:objectName() == player:objectName()
    and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
    room:addPlayerMark(player, "sk_shemi_current", move.card_ids:length())
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then return skill:objectName() end
  if event == sgs.DrawNCards and player:getMark("sk_shemi_bonus") > 0 then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.DrawNCards then
   local draw = ctx.original_data:toDraw(); draw.num = draw.num + 1; ctx.original_data:setValue(draw)
   return false
  end
  local extra = room:askForExchange(player, skill:objectName(), 999, 1, true, "@sk_shemi", true)
  if extra then room:throwCard(extra, player, player) end
  local n = player:getMark("sk_shemi_current")
  room:setPlayerMark(player, "sk_shemi_bonus", n > player:getMark("sk_shemi_previous") and 1 or 0)
  room:setPlayerMark(player, "sk_shemi_previous", n)
  if not player:isWounded() then
   room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
  end
  return false
 end,
}
sk_jiaohui = sgs.CreateTriggerSkillV2{
 name = "sk_jiaohui", events = {sgs.DamageInflicted},
 can_trigger = function(skill, event, room, player, data)
  if player and player:isAlive() and player:hasSkill(skill:objectName()) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local choices = "draw"
  if player:canDiscard(player, "he") then choices = choices .. "+discard" end
  if room:askForChoice(player, skill:objectName(), choices, ctx.original_data) == "draw" then
   player:drawCards(1, skill:objectName())
  else room:askForDiscard(player, skill:objectName(), 1, 1, false, true) end
  if player:getHandcardNum() == player:getHp() then
   local d = ctx.original_data:toDamage(); d.damage = d.damage - 1
   ctx.original_data:setValue(d)
   return d.damage <= 0
  end
  return false
 end,
}
sk_dongbai:addSkill(sk_shemi)
sk_dongbai:addSkill(sk_jiaohui)
sgs.LoadTranslationTable{
 ["sk_dongbai"] = "SK董白", ["&sk_dongbai"] = "董白", ["#sk_dongbai"] = "董白",
 ["sk_shemi"] = "奢靡", [":sk_shemi"] = "锁定技，弃牌阶段，你可以多弃置任意张牌，然后若你此阶段弃置的牌数大于你上一个弃牌阶段的弃牌数，你摸牌阶段额外摸一张牌；若你未受伤，你加1点体力上限。",
 ["sk_jiaohui"] = "狡慧", [":sk_jiaohui"] = "当你受到伤害时，你可以摸一张牌或弃置一张牌；然后若你的手牌数等于体力值，此伤害-1。",
 ["@sk_shemi"] = "奢靡", ["draw"] = "摸一张牌", ["discard"] = "弃置一张牌",
}

--极略32 张梁（jilue.md L2229）
sk_zhangliang = sgs.General(extension, "sk_zhangliang", "qun", 3, true)
local function sk_jijun_options(player, ids)
 local distinct, counts, available = true, {}, {}
 for _, id in sgs.qlist(player:getPile("sk_bing")) do
  local suit = sgs.Sanguosha:getCard(id):getSuit()
  available[suit] = (available[suit] or 0) + 1
 end
 local swap = true
 for _, id in sgs.qlist(ids) do
  local suit = sgs.Sanguosha:getCard(id):getSuit()
  counts[suit] = (counts[suit] or 0) + 1
  if counts[suit] > 1 then distinct = false end
  if counts[suit] > (available[suit] or 0) then swap = false end
 end
 return ids:length() <= 4 and distinct, swap
end
sk_jijunCard = sgs.CreateSkillCard{
 name = "sk_jijunCard", target_fixed = true, will_throw = false, handling_method = sgs.Card_MethodNone,
 on_use = function(self, room, source, targets)
  local ids = self:getSubcards()
  local put, swap = sk_jijun_options(source, ids)
  local choices = {}
  if put then table.insert(choices, "put") end
  if swap then table.insert(choices, "swap") end
  if ids:isEmpty() then table.insert(choices, "get") end
  local choice = room:askForChoice(source, "sk_jijun", table.concat(choices, "+"))
  if choice == "put" then
   if not ids:isEmpty() then source:addToPile("sk_bing", ids, true) end
  elseif choice == "get" then
   local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
   dummy:addSubcards(source:getPile("sk_bing"))
   if not dummy:getSubcards():isEmpty() then room:obtainCard(source, dummy, true) end
   dummy:deleteLater()
  else
   local used = {}
   for _, id in sgs.qlist(ids) do
    local pool = sgs.IntList()
    for _, old in sgs.qlist(source:getPile("sk_bing")) do
     if not used[old] and sgs.Sanguosha:getCard(old):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then pool:append(old) end
    end
    room:fillAG(pool, source)
    local old = room:askForAG(source, pool, false, "sk_jijun")
    room:clearAG(source)
    used[id] = true
    source:addToPile("sk_bing", id, true)
    room:obtainCard(source, old, true)
   end
  end
  if not source:isAlive() then return end
  local names = sgs.Sanguosha:getCardNames("BasicCard")
  local name = room:askForChoice(source, "sk_jijun_basic", table.concat(names, "+"))
  if name == "slash" then name = room:askForChoice(source, "sk_jijun_basic", table.concat(sgs.Sanguosha:getSlashNames(), "+")) end
  local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
  if not card then return end
  card:setSkillName("sk_jijun")
  local use = sgs.CardUseStruct(); use.from = source; use.card = card
  if not card:targetFixed() then
   local plist = sgs.PlayerList()
   while true do
    local pool = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
     if not plist:contains(p) and card:targetFilter(plist, p, source) and not source:isProhibited(p, card, plist) then pool:append(p) end
    end
    if pool:isEmpty() then break end
    local t = room:askForPlayerChosen(source, pool, "sk_jijun", "@sk_jijun-target:" .. name, card:targetsFeasible(plist, source), true)
    if not t then break end
    plist:append(t)
   end
   if not card:targetsFeasible(plist, source) then card:deleteLater() return end
   for _, p in sgs.qlist(plist) do use.to:append(p) end
  end
  room:useCard(use, false)
  card:deleteLater()
 end,
}
sk_jijun = sgs.CreateViewAsSkillV2{
 name = "sk_jijun", n = 999,
 can_activate = function(skill, request)
  local p = request:getInitiator()
  return p and p:isAlive() and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
   and not p:hasUsed("#sk_jijunCard")
 end,
 can_select_card = function(skill, request, card)
  if card:isEquipped() then return false end
  local ids = sgs.IntList()
  for _, id in sgs.qlist(request:getSelectedCardIds()) do ids:append(id) end
  ids:append(card:getEffectiveId())
  local put, swap = sk_jijun_options(request:getInitiator(), ids)
  return put or swap
 end,
 card_selection_feasible = function(skill, request)
  local put, swap = sk_jijun_options(request:getInitiator(), request:getSelectedCardIds())
  return put or swap
 end,
 create_card = function(skill, request)
  local card = sk_jijunCard:clone(); card:addSubcards(request:getSelectedCardIds()); return card
 end,
}
sk_jijunMod = sgs.CreateTargetModSkillV2{
 name = "#sk_jijun", pattern = "BasicCard", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local card = ctx:getCard()
  if card and card:getSkillName() == "sk_jijun" and
   (ctx:getModType() == sgs.TargetModSkill_DistanceLimit or ctx:getModType() == sgs.TargetModSkill_Residue) then return 9999 end
  return false
 end,
}
local sk_fangtong_grants = {"sk_zhangliang_leiji", "sk_zhangliang_zhoufu", "sk_zhangliang_shendao", "sk_zhangliang_biantian"}
local function sk_fangtong_update(room, player)
 if player:hasFlag("sk_fangtong_updating") then return end
 room:setPlayerFlag(player, "sk_fangtong_updating")
 local sum = 0
 for _, id in sgs.qlist(player:getPile("sk_bing")) do sum = sum + sgs.Sanguosha:getCard(id):getNumber() end
 local wanted = {sum >= 9, sum >= 18, sum == 27, sum == 36}
 local n = 0
 for i, name in ipairs(sk_fangtong_grants) do
  local active = player:hasSkill("sk_fangtong") and wanted[i]
  if active then
   n = n + 1
   if not player:hasSkill(name) then room:acquireSkill(player, name); room:setPlayerMark(player, name .. "_granted", 1) end
  elseif player:getMark(name .. "_granted") > 0 then
   room:detachSkillFromPlayer(player, name); room:setPlayerMark(player, name .. "_granted", 0)
  end
 end
 room:setPlayerMark(player, "sk_fangtong_count", n)
 room:setPlayerFlag(player, "-sk_fangtong_updating")
end
sk_fangtong = sgs.CreateTriggerSkillV2{
 name = "sk_fangtong", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.CardsMoveOneTime, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  for _, p in sgs.qlist(room:getAllPlayers()) do
   if p:hasSkill(skill:objectName()) or p:getMark("sk_fangtong_count") > 0 then sk_fangtong_update(room, p) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseStart and player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish
   and player:getHandcardNum() < player:getMark("sk_fangtong_count") then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  player:drawCards(player:getMark("sk_fangtong_count") - player:getHandcardNum(), skill:objectName()); return false
 end,
}
sk_zhangliang_leiji = sgs.CreateTriggerSkillV2{
 name = "sk_zhangliang_leiji", events = {sgs.CardUsed, sgs.CardResponded},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  local card = event == sgs.CardUsed and data:toCardUse().card or data:toCardResponse().m_card
  if card and card:isKindOf("Jink") then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sk_zhangliang_leiji", true, true)
  if not target then return false end
  ctx.extra_data:setValue(target); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.extra_data:toPlayer()
  local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = skill:objectName(); judge.pattern = ".|spade"; judge.good = true
  room:judge(judge)
  if judge:isGood() then room:damage(sgs.DamageStruct(skill:objectName(), player, target, 2, sgs.DamageStruct_Thunder)) end
  return false
 end,
}
sk_zhangliang_zhoufu = sgs.CreateTriggerSkillV2{
 name = "sk_zhangliang_zhoufu", global = true, events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event ~= sgs.EventPhaseChanging or not player or ctx.original_data:toPhaseChange().to ~= sgs.Player_NotActive then return end
  local names = player:getTag("sk_zhangliang_zhoufu_disabled"):toString()
  if names ~= "" then
   for _, name in ipairs(names:split("+")) do room:removePlayerMark(player, "Qingcheng" .. name) end
   player:removeTag("sk_zhangliang_zhoufu_disabled")
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or player:getPhase() ~= sgs.Player_RoundStart then return false end
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p ~= player and p:canDiscard(p, "h") then table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return room:askForCard(player, ".|.|.|hand", "@sk_zhangliang_zhoufu:" .. ctx.invoker:objectName(), ctx.original_data, skill:objectName()) ~= nil
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = skill:objectName(); judge.pattern = ".|black"; judge.good = true
  room:judge(judge)
  if judge.card:getSuit() == sgs.Card_Spade then
   local names = target:getTag("sk_zhangliang_zhoufu_disabled"):toString()
   local list = names ~= "" and names:split("+") or {}
   for _, s in sgs.qlist(target:getVisibleSkillList()) do
    room:addPlayerMark(target, "Qingcheng" .. s:objectName()); table.insert(list, s:objectName())
   end
   target:setTag("sk_zhangliang_zhoufu_disabled", sgs.QVariant(table.concat(list, "+")))
  elseif judge.card:getSuit() == sgs.Card_Club then room:askForDiscard(target, skill:objectName(), 2, 2, false, true) end
  return false
 end,
}
sk_zhangliang_shendao = sgs.CreateTriggerSkillV2{
 name = "sk_zhangliang_shendao", events = {sgs.AskForRetrial},
 can_trigger = function(skill, event, room, player, data)
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   table.insert(skills, skill:objectName()); table.insert(owners, p:objectName())
  end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local ids = sgs.IntList()
  for _, id in sgs.qlist(player:handCards()) do ids:append(id) end
  for _, p in sgs.qlist(room:getAlivePlayers()) do
   for _, c in sgs.qlist(p:getCards("ej")) do ids:append(c:getEffectiveId()) end
  end
  if ids:isEmpty() then return false end
  room:fillAG(ids, player)
  local id = room:askForAG(player, ids, true, skill:objectName()); room:clearAG(player)
  if id < 0 then return false end
  local judge = ctx.original_data:toJudge()
  room:retrial(sgs.Sanguosha:getCard(id), player, judge, skill:objectName(), true)
  return false
 end,
}
sk_zhangliang_biantian = sgs.CreateTriggerSkillV2{
 name = "sk_zhangliang_biantian", frequency = sgs.Skill_Compulsory, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or player:getPhase() ~= sgs.Player_Judge then return false end
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p ~= player then table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = "lightning"; judge.pattern = ".|spade|2~9"; judge.good = false; judge.negative = true
  room:judge(judge)
  if judge:isBad() then room:damage(sgs.DamageStruct("lightning", nil, target, 3, sgs.DamageStruct_Thunder)) end
  return false
 end,
}
local sk_zhangliang_skills = sgs.SkillList()
for _, skill in ipairs({sk_zhangliang_leiji, sk_zhangliang_zhoufu, sk_zhangliang_shendao, sk_zhangliang_biantian}) do
 if not sgs.Sanguosha:getSkill(skill:objectName()) then sk_zhangliang_skills:append(skill) end
end
sgs.Sanguosha:addSkills(sk_zhangliang_skills)
sk_zhangliang:addSkill(sk_jijun)
sk_zhangliang:addSkill(sk_jijunMod)
sk_zhangliang:addSkill(sk_fangtong)
extension:insertRelatedSkills("sk_jijun", "#sk_jijun")
sgs.LoadTranslationTable{
 ["sk_zhangliang"] = "SK张梁", ["&sk_zhangliang"] = "张梁", ["#sk_zhangliang"] = "张梁",
 ["sk_bing"] = "兵", ["sk_jijun"] = "集军",
 [":sk_jijun"] = "出牌阶段限一次，你可以选择一项：1.将至多四张花色不同的手牌置为“兵”；2.用相同花色的手牌替换任意张“兵”；3.获得所有“兵”；然后你视为使用一张无距离与次数限制的任意基本牌。",
 ["sk_fangtong"] = "方统", [":sk_fangtong"] = "锁定技，你根据“兵”的点数和获得对应技能：不小于9，“雷击”；不小于18，“咒缚”；27，“神道”；36，“变天”。结束阶段，你将手牌数补至X张（X为你以此法获得的技能数）。",
 ["sk_zhangliang_leiji"] = "雷击", [":sk_zhangliang_leiji"] = "当你使用或打出【闪】时，你可以令一名其他角色判定。若为黑桃，你对其造成2点雷电伤害。",
 ["sk_zhangliang_zhoufu"] = "咒缚", [":sk_zhangliang_zhoufu"] = "其他角色的回合开始时，你可以弃置一张手牌并令其判定。若为黑桃，本回合内其所有技能失效；若为梅花，其弃置两张牌。",
 ["sk_zhangliang_shendao"] = "神道", [":sk_zhangliang_shendao"] = "当一名角色的判定牌生效前，你可以用一张手牌或场上的一张牌代替之，然后你获得原判定牌。",
 ["sk_zhangliang_biantian"] = "变天", [":sk_zhangliang_biantian"] = "锁定技，其他角色的判定阶段开始时，你令其进行一次【闪电】判定。",
 ["sk_jijun_basic"] = "集军", ["@sk_jijun-target"] = "集军", ["@sk_zhangliang_leiji"] = "雷击", ["@sk_zhangliang_zhoufu"] = "咒缚",
 ["put"] = "将至多四张花色不同的手牌置为“兵”", ["swap"] = "用相同花色的手牌替换任意张“兵”", ["get"] = "获得所有“兵”",
}

-- 极略32：曹节（jilue.md L2241-L2245）
sk_caojie = sgs.General(extension, "sk_caojie", "qun", 3, false)
sk_huaibi = sgs.CreateTriggerSkillV2{
 name = "sk_huaibi", frequency = sgs.Skill_Compulsory,
 events = {sgs.GameStart, sgs.EventPhaseStart, sgs.CardEffected},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.CardEffected then
   local card = data:toCardEffect().card
   local pile = player:getPile("sk_xi")
   local from = data:toCardEffect().from
   if not pile:isEmpty() and card and from and from:objectName() ~= player:objectName()
    and (card:isKindOf("Slash") or (card:isKindOf("TrickCard") and not card:isKindOf("DelayedTrick")))
    and card:getSuit() == sgs.Sanguosha:getCard(pile:first()):getSuit() then return skill:objectName() end
  elseif player:getPile("sk_xi"):isEmpty() and (event == sgs.GameStart or player:getPhase() == sgs.Player_Finish) then
   return skill:objectName()
  end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.CardEffected then return true end
  player:drawCards(2, skill:objectName())
  if not player:isKongcheng() then
   local card = room:askForExchange(player, skill:objectName(), 1, 1, false, "@sk_huaibi", false)
   if card then player:addToPile("sk_xi", card:getSubcards(), true); card:deleteLater() end
  end
  return false
 end,
}
sk_zhixiCard = sgs.CreateSkillCard{
 name = "sk_zhixiCard", will_throw = false,
 filter = function(self, targets, target, source) return #targets == 0 and target ~= source end,
 feasible = function(self, targets) return #targets == 1 end,
 on_use = function(self, room, source, targets)
  local target = targets[1]
  local mark = "sk_zhixi_" .. target:objectName()
  local loss = source:getMark(mark) > 0 and 1 or 3
  room:addPlayerMark(source, mark)
  room:obtainCard(target, source:getPile("sk_xi"):first(), true)
  room:loseHp(target, loss)
 end,
}
sk_zhixi = sgs.CreateViewAsSkillV2{
 name = "sk_zhixi", n = 0,
 can_activate = function(skill, request)
  local p = request:getInitiator()
  return p and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
   and not p:getPile("sk_xi"):isEmpty() and not p:hasUsed("#sk_zhixiCard")
 end,
 can_select_target = function(skill, request, selected, candidate)
  return #selected == 0 and candidate ~= request:getInitiator()
 end,
 targets_feasible = function(skill, request, selected) return #selected == 1 end,
 create_card = function(skill, request) return sk_zhixiCard:clone() end,
}
sk_caojie:addSkill(sk_huaibi)
sk_caojie:addSkill(sk_zhixi)
sgs.LoadTranslationTable{
 ["sk_caojie"] = "SK曹节", ["&sk_caojie"] = "曹节", ["#sk_caojie"] = "曹节",
 ["sk_huaibi"] = "怀璧", [":sk_huaibi"] = "锁定技，游戏开始时或结束阶段，若你没有“玺”，你摸两张牌并将一张手牌置于武将牌上，称为“玺”。若你有“玺”，其他角色使用的与之花色相同的【杀】和非延时锦囊牌对你无效。",
 ["sk_zhixi"] = "掷玺", [":sk_zhixi"] = "出牌阶段限一次，你可以将“玺”交给一名其他角色，然后其失去3点体力；若你以此法选择过该角色，其改为失去1点体力。",
 ["sk_xi"] = "玺", ["@sk_huaibi"] = "怀璧",
}

-- 极略32：沮授（jilue.md L2249-L2251）
sk_jushou = sgs.General(extension, "sk_jushou", "qun", 3)
sk_jianying = sgs.CreateTriggerSkillV2{
 name = "sk_jianying", events = {sgs.CardUsed},
 on_record = function(skill, event, room, player, ctx)
  if not player or not player:hasSkill(skill:objectName()) then return end
  local card = ctx.original_data:toCardUse().card
  if not card then return end
  local same = player:getTag("sk_jianying_has_previous"):toBool()
   and (card:getSuit() == player:getTag("sk_jianying_suit"):toInt() or card:getNumber() == player:getTag("sk_jianying_number"):toInt())
  card:setTag("sk_jianying_match", sgs.QVariant(same))
  player:setTag("sk_jianying_has_previous", sgs.QVariant(true))
  player:setTag("sk_jianying_suit", sgs.QVariant(card:getSuit()))
  player:setTag("sk_jianying_number", sgs.QVariant(card:getNumber()))
 end,
 can_trigger = function(skill, event, room, player, data)
  local card = data:toCardUse().card
  if player and player:hasSkill(skill:objectName()) and card and card:getTag("sk_jianying_match"):toBool() then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx) player:drawCards(1, skill:objectName()); return false end,
}
sk_shibeiVS = sgs.CreateViewAsSkillV2{
 name = "sk_shibei", n = 1,
 can_activate = function(skill, request)
  return request:getPattern() == "@@sk_shibei" and request:getInitiator():getTag("sk_shibei_card"):toString() ~= ""
 end,
 can_select_card = function(skill, request, card) return true end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local id = request:getSelectedCardIds():first()
  local material = sgs.Sanguosha:getCard(id)
  local card = sgs.Sanguosha:cloneCard(request:getInitiator():getTag("sk_shibei_card"):toString(), material:getSuit(), material:getNumber())
  if card then card:addSubcard(id); card:setSkillName(skill:objectName()) end
  return card
 end,
}
sk_shibei = sgs.CreateTriggerSkillV2{
 name = "sk_shibei", view_as_skill = sk_shibeiVS, global = true,
 events = {sgs.Damaged, sgs.PreCardUsed, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(p, "sk_shibei_used", 0); room:setPlayerMark(p, "sk_shibei_next", 0) end
  elseif event == sgs.PreCardUsed then
   local card = ctx.original_data:toCardUse().card
   if card and card:getSkillName() == skill:objectName() then room:setPlayerMark(player, "sk_shibei_next", 1) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.Damaged and player and player:hasSkill(skill:objectName())
   and (player:getMark("sk_shibei_next") > 0 or player:getMark("sk_shibei_used") == 0) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  if player:getMark("sk_shibei_next") > 0 then return true end
  return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  if player:getMark("sk_shibei_next") > 0 then
   room:setPlayerMark(player, "sk_shibei_next", 0); room:loseHp(player, 1); return false
  end
  room:setPlayerMark(player, "sk_shibei_used", 1)
  local damage = ctx.original_data:toDamage()
  local recover = sgs.RecoverStruct(); recover.who = player; recover.recover = 1; room:recover(player, recover)
  if damage.card and player:isAlive() then
   local old = player:getTag("sk_shibei_card")
   player:setTag("sk_shibei_card", sgs.QVariant(damage.card:objectName()))
   room:askForUseCard(player, "@@sk_shibei", "@sk_shibei")
   player:setTag("sk_shibei_card", old)
  end
  return false
 end,
}
sk_jushou:addSkill(sk_jianying)
sk_jushou:addSkill(sk_shibei)
sgs.LoadTranslationTable{
 ["sk_jushou"] = "SK沮授", ["&sk_jushou"] = "沮授", ["#sk_jushou"] = "沮授",
 ["sk_jianying"] = "渐营", [":sk_jianying"] = "当你使用牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。",
 ["sk_shibei"] = "矢北", [":sk_shibei"] = "每回合限一次，当你受到伤害后，你可以回复1点体力，然后你可以将一张牌当作造成伤害的牌使用；若如此做，本回合内，你下一次受到伤害后，你失去1点体力。",
 ["@sk_shibei"] = "矢北",
}

-- 极略36：严颜（jilue.md L2304-L2305）
sk_yanyan = sgs.General(extension, "sk_yanyan", "shu", 4)
sk_juzhan = sgs.CreateTriggerSkillV2{
 name = "sk_juzhan", global = true, events = {sgs.EventPhaseStart, sgs.Damage},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.Damage then
   local damage = ctx.original_data:toDamage()
   if damage.card and damage.card:getSkillName() == skill:objectName() then
    damage.card:setTag("sk_juzhan_damaged", sgs.QVariant(true))
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or player:getPhase() ~= sgs.Player_Play then return false end
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p ~= player then table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  local x = math.min(5, player:getLostHp())
  if x > 0 then player:drawCards(x, skill:objectName()) end
  if not player:isAlive() or not target:isAlive() then return false end
  local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
  card:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.from = target; use.card = card; use.to:append(player)
  room:useCard(use, false)
  if card:getTag("sk_juzhan_damaged"):toBool() and target:isAlive() then
   local choice = room:askForChoice(target, skill:objectName(), "discard+end", sgs.QVariant(x))
   if choice == "discard" then
    if x > 0 then room:askForDiscard(target, skill:objectName(), x, x, false, true) end
   else target:endPlayPhase() end
  end
  card:deleteLater()
  return false
 end,
}
sk_yanyan:addSkill(sk_juzhan)
sgs.LoadTranslationTable{
 ["sk_yanyan"] = "SK严颜", ["&sk_yanyan"] = "严颜", ["#sk_yanyan"] = "严颜",
 ["sk_juzhan"] = "拒战", [":sk_juzhan"] = "其他角色的出牌阶段开始时，你可以摸X张牌，然后令该角色视为对你使用一张无距离限制的【杀】；此牌结算后，若此牌造成伤害，该角色选择一项：1.弃置X张牌；2.结束此阶段（X为你已损失的体力值，至多为5）。",
}

-- 极略36：诸葛瞻（jilue.md L2313-L2321）
sk_zhugezhan = sgs.General(extension, "sk_zhugezhan", "shu", 4)
sk_zuilun = sgs.CreateTriggerSkillV2{
 name = "sk_zuilun", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.HpRecover, sgs.Damage},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers()) do
    for _, mark in ipairs({"discard", "recover", "damage"}) do room:setPlayerMark(p, "sk_zuilun_" .. mark, 0) end
   end
  elseif event == sgs.CardsMoveOneTime then
   local move = ctx.original_data:toMoveOneTime()
   if move.from and not move.card_ids:isEmpty() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
    local p = room:findPlayerByObjectName(move.from:objectName()); if p then room:setPlayerMark(p, "sk_zuilun_discard", 1) end
   end
  elseif player and event == sgs.HpRecover then room:setPlayerMark(player, "sk_zuilun_recover", 1)
  elseif event == sgs.Damage then
   local d = ctx.original_data:toDamage(); if d.from then room:setPlayerMark(d.from, "sk_zuilun_damage", 1) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseStart and player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local done = {}
  for _, mark in ipairs({"discard", "recover", "damage"}) do done[mark] = player:getMark("sk_zuilun_" .. mark) > 0 end
  for _, mark in ipairs({"discard", "recover", "damage"}) do
   if not player:isAlive() then break end
   local target = player
   if done[mark] then
    target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sk_zuilun_" .. mark, "@sk_zuilun_" .. mark, false, true)
   end
   if target then
    if mark == "discard" then target:drawCards(4, skill:objectName())
    elseif mark == "recover" then room:loseHp(target, 1)
    else room:loseMaxHp(target, 1) end
   end
  end
  return false
 end,
}
local function sk_yaozhi_choose(room, player, event, data)
 local pool, seen = {}, {}
 local phrase = event == sgs.Damaged and "受到伤害后" or player:getPhase() == sgs.Player_Start and "准备阶段" or player:getPhase() == sgs.Player_Finish and "结束阶段" or "出牌阶段"
 for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
  local general = sgs.Sanguosha:getGeneral(name)
  for _, candidate in sgs.qlist(general:getVisibleSkillList()) do
   local n = candidate:objectName()
   local trigger = sgs.Sanguosha:getTriggerSkill(n)
   local active = event == nil and sgs.Sanguosha:getViewAsSkill(n)
   if not seen[n] and n ~= "sk_yaozhi" and n ~= "sk_fuzhi" and n ~= "sk_xingyun"
    and sgs.Sanguosha:translate(":" .. n):find(phrase, 1, true)
    and (active or trigger and event and trigger:hasEvent(event)) then
    seen[n] = true; table.insert(pool, n)
   end
  end
 end
 local choices = {}
 for i = 1, math.min(3, #pool) do table.insert(choices, table.remove(pool, math.random(#pool))) end
 if #choices == 0 then return end
 local chosen = room:askForChoice(player, "sk_yaozhi", table.concat(choices, "+"), data or sgs.QVariant())
 local previous = player:getTag("sk_yaozhi_chosen"):toString()
 local history = previous ~= "" and previous:split("+") or {}
 if not table.contains(history, chosen) then table.insert(history, chosen) end
 player:setTag("sk_yaozhi_chosen", sgs.QVariant(table.concat(history, "+")))
 if event == nil then
  room:askForUseCardWithBorrowedSkill(player, chosen, "sk_yaozhi", "@sk_yaozhi")
 else
  local owned = player:hasSkill(chosen)
  if not owned then room:acquireSkill(player, chosen) end
  sgs.Sanguosha:getTriggerSkill(chosen):trigger(event, room, player, data, player)
  if not owned then room:detachSkillFromPlayer(player, chosen, false, true) end
 end
end
sk_yaozhiCard = sgs.CreateSkillCard{
 name = "sk_yaozhiCard", target_fixed = true,
 on_use = function(self, room, source, targets) sk_yaozhi_choose(room, source, nil, nil) end,
}
sk_yaozhiVS = sgs.CreateViewAsSkillV2{
 name = "sk_yaozhi", n = 0,
 can_activate = function(skill, request)
  return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and not request:getInitiator():hasUsed("#sk_yaozhiCard")
 end,
 create_card = function() return sk_yaozhiCard:clone() end,
}
sk_yaozhi = sgs.CreateTriggerSkillV2{
 name = "sk_yaozhi", view_as_skill = sk_yaozhiVS, events = {sgs.EventPhaseStart, sgs.Damaged},
 can_trigger = function(skill, event, room, player, data)
  if player and player:hasSkill(skill:objectName()) and (event == sgs.Damaged or player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx) sk_yaozhi_choose(room, player, event, ctx.original_data); return false end,
}
sk_xingyun = sgs.CreateTriggerSkillV2{
 name = "sk_xingyun", frequency = sgs.Skill_Compulsory, events = {sgs.EventPhaseChanging},
 can_trigger = function(skill, event, room, player, data)
  if player and player:hasSkill(skill:objectName()) and data:toPhaseChange().to == sgs.Player_NotActive then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  room:loseMaxHp(player, 1)
  local choices = player:getTag("sk_yaozhi_chosen"):toString()
  if player:isAlive() and choices ~= "" then room:acquireSkill(player, room:askForChoice(player, skill:objectName(), choices)) end
  return false
 end,
}
sk_fuzhi = sgs.CreateTriggerSkillV2{
 name = "sk_fuzhi", frequency = sgs.Skill_Wake, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if player and player:hasSkill(skill:objectName()) and player:getMark(skill:objectName()) == 0 and player:getPhase() == sgs.Player_Start and player:getHp() == 1 then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  room:addPlayerMark(player, skill:objectName())
  room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
  local recover = sgs.RecoverStruct(); recover.who = player; room:recover(player, recover)
  local names = {}; for _, s in sgs.qlist(player:getSkillList(false, false)) do table.insert(names, s:objectName()) end
  for _, n in ipairs(names) do room:detachSkillFromPlayer(player, n) end
  room:acquireSkill(player, "sk_yaozhi"); room:acquireSkill(player, "sk_xingyun")
  return false
 end,
}
sk_zhugezhan:addSkill(sk_zuilun)
sk_zhugezhan:addSkill(sk_fuzhi)
local sk_zhugezhan_skills = sgs.SkillList()
for _, skill in ipairs({sk_yaozhi, sk_xingyun}) do if not sgs.Sanguosha:getSkill(skill:objectName()) then sk_zhugezhan_skills:append(skill) end end
sgs.Sanguosha:addSkills(sk_zhugezhan_skills)
sgs.LoadTranslationTable{
 ["sk_zhugezhan"] = "SK诸葛瞻", ["&sk_zhugezhan"] = "诸葛瞻", ["#sk_zhugezhan"] = "诸葛瞻",
 ["sk_zuilun"] = "罪论", [":sk_zuilun"] = "锁定技，结束阶段，若你本回合内未弃置牌/回复体力/造成伤害，你摸四张牌/失去1点体力/减1点体力上限；否则你令一名其他角色执行对应操作。",
 ["sk_fuzhi"] = "父志", [":sk_fuzhi"] = "觉醒技，准备阶段，若你体力值为1，你加1点体力上限并回复1点体力，然后你失去所有技能，获得“妖智”、“星陨”。",
 ["sk_yaozhi"] = "妖智", [":sk_yaozhi"] = "准备阶段、出牌阶段限一次、结束阶段或当你受到伤害后，你可以随机抽取三个此时机的技能并选择其中一个发动。",
 ["sk_xingyun"] = "星陨", [":sk_xingyun"] = "锁定技，回合结束后，你减1点体力上限，然后获得一个“妖智”选择过的技能。",
 ["@sk_yaozhi"] = "妖智", ["@sk_zuilun_discard"] = "罪论", ["@sk_zuilun_recover"] = "罪论", ["@sk_zuilun_damage"] = "罪论",
}

-- 极略37：潘璋（jilue.md L2342-L2343）
sk_panzhang = sgs.General(extension, "sk_panzhang", "wu", 4)
sk_jiejun = sgs.CreateTriggerSkillV2{
 name = "sk_jiejun", global = true, events = {sgs.CardFinished, sgs.Damage},
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.Damage then
   local damage = data:toDamage()
   if damage.from and damage.from:hasSkill(skill:objectName()) and damage.card and damage.card:hasFlag("sk_jiejun")
    and damage.to and damage.to:objectName() == damage.card:getTag("sk_jiejun_target"):toString() then return skill:objectName(), damage.from:objectName() end
  else
   local use = data:toCardUse()
   if not use.from or not use.card or not use.card:isRed() then return false end
   local skills, owners = {}, {}
   for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
    if p ~= use.from and p:getPhase() == sgs.Player_NotActive then table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
   end
   if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.Damage then
   local target = ctx.original_data:toDamage().to
   local cards = target:getCards("hej")
   if not cards:isEmpty() then
    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    for _, c in sgs.qlist(cards) do dummy:addSubcard(c) end
    room:obtainCard(player, dummy, false); dummy:deleteLater()
   end
  else
   local target = ctx.original_data:toCardUse().from
   if target and target:isAlive() then room:askForUseSlashTo(player, target, "@sk_jiejun:" .. target:objectName(), false, false, false, nil, nil, "sk_jiejun") end
  end
  return false
 end,
}
sk_jiejun_target = sgs.CreateTriggerSkillV2{
 name = "#sk_jiejun_target", global = true, events = {sgs.PreCardUsed},
 on_record = function(skill, event, room, player, ctx)
  local use = ctx.original_data:toCardUse()
  if use.card and use.card:hasFlag("sk_jiejun") and not use.to:isEmpty() then use.card:setTag("sk_jiejun_target", sgs.QVariant(use.to:first():objectName())) end
 end,
 can_trigger = function() return false end,
}
sk_panzhang:addSkill(sk_jiejun)
sk_panzhang:addSkill(sk_jiejun_target)
extension:insertRelatedSkills("sk_jiejun", "#sk_jiejun_target")
sgs.LoadTranslationTable{
 ["sk_panzhang"] = "SK潘璋", ["&sk_panzhang"] = "潘璋", ["#sk_panzhang"] = "潘璋",
 ["sk_jiejun"] = "截军", [":sk_jiejun"] = "你的回合外，当一名其他角色使用的红色牌结算后，你可以对其使用一张无距离限制的【杀】；若此牌对其造成伤害，你获得其所有牌。",
 ["@sk_jiejun"] = "截军",
}

-- 极略37：孙茹（jilue.md L2351-L2355）
sk_sunru = sgs.General(extension, "sk_sunru", "wu", 3, false)
sk_xiecuiCard = sgs.CreateSkillCard{
 name = "sk_xiecuiCard", target_fixed = true, will_throw = false,
 on_use = function(self, room, source, targets)
  room:throwCard(self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName(), "sk_xiecui", ""), source)
  room:setPlayerMark(source, "sk_xiecui_paid", 1)
 end,
}
sk_xiecuiVS = sgs.CreateViewAsSkillV2{
 name = "sk_xiecui", n = 2,
 can_activate = function(skill, request) return request:getPattern() == "@@sk_xiecui" end,
 can_select_card = function(skill, request, card)
  if request:getInitiator():isJilei(card) then return false end
  for _, id in sgs.qlist(request:getSelectedCardIds()) do if sgs.Sanguosha:getCard(id):getSuit() == card:getSuit() then return false end end
  return true
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 2 end,
 create_card = function(skill, request) local card = sk_xiecuiCard:clone(); card:addSubcards(request:getSelectedCardIds()); return card end,
}
sk_xiecui = sgs.CreateTriggerSkillV2{
 name = "sk_xiecui", view_as_skill = sk_xiecuiVS, global = true,
 events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused, sgs.Damage, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(p, "sk_xiecui_uses", 0); room:setPlayerMark(p, "sk_xiecui_damage", 0) end
  elseif event == sgs.CardUsed then
   room:addPlayerMark(player, "sk_xiecui_uses")
  elseif event == sgs.CardResponded and ctx.original_data:toCardResponse().m_isUse then
   room:addPlayerMark(player, "sk_xiecui_uses")
  elseif event == sgs.Damage then
   local damage = ctx.original_data:toDamage()
   if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive then room:addPlayerMark(damage.from, "sk_xiecui_damage") end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.DamageCaused then return false end
  local damage = data:toDamage()
  if not damage.from or damage.from:getPhase() == sgs.Player_NotActive or damage.from:getMark("sk_xiecui_damage") ~= 0 then return false end
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:getCards("he"):length() >= 2 then table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  room:setPlayerMark(player, "sk_xiecui_paid", 0)
  room:askForUseCard(player, "@@sk_xiecui", "@sk_xiecui")
  return player:getMark("sk_xiecui_paid") > 0
 end,
 on_effect = function(skill, event, room, player, ctx)
  local damage = ctx.original_data:toDamage()
  local choice = room:askForChoice(player, skill:objectName(), "increase+decrease", ctx.original_data)
  local x = damage.from:getMark("sk_xiecui_uses")
  damage.damage = damage.damage + (choice == "increase" and 1 or -1)
  ctx.original_data:setValue(damage)
  if damage.from:isAlive() and x > 0 then
   if choice == "increase" then damage.from:drawCards(x, skill:objectName())
   else room:askForDiscard(damage.from, skill:objectName(), x, x, false, true) end
  end
  return damage.damage <= 0
 end,
}
sk_youxu = sgs.CreateTriggerSkillV2{
 name = "sk_youxu", global = true, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or player:getPhase() ~= sgs.Player_Play or player:getCards("hej"):length() < player:getLostHp() then return false end
  local skills, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do table.insert(skills, skill:objectName()); table.insert(owners, p:objectName()) end
  if #skills > 0 then return table.concat(skills, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  local ids, disabled = {}, sgs.IntList()
  for i = 1, target:getLostHp() do
   local id = room:askForCardChosen(player, target, "hej", skill:objectName(), false, sgs.Card_MethodNone, disabled)
   if id < 0 then return false end
   disabled:append(id); table.insert(ids, tostring(id))
  end
  local name = room:askForChoice(player, skill:objectName(), "amazing_grace+peach", sgs.QVariant(target))
  local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
  for _, id in ipairs(ids) do card:addSubcard(tonumber(id)) end
  card:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.from = target; use.card = card
  if name == "peach" then use.to:append(target) end
  room:useCard(use, false); card:deleteLater()
  return false
 end,
}
sk_sunru:addSkill(sk_xiecui)
sk_sunru:addSkill(sk_youxu)
sgs.LoadTranslationTable{
 ["sk_sunru"] = "SK孙茹", ["&sk_sunru"] = "孙茹", ["#sk_sunru"] = "孙茹",
 ["sk_xiecui"] = "撷翠", [":sk_xiecui"] = "当一名角色于其回合内首次造成伤害时，你可以弃置两张花色不同的牌，令此伤害+1/-1，然后该角色摸/弃置X张牌（X为该角色此回合使用的牌数）。",
 ["sk_youxu"] = "忧恤", [":sk_youxu"] = "一名角色的出牌阶段开始时，你可以选择其X张牌（X为其已损失的体力值），然后令该角色将这些牌当作一张【五谷丰登】或【桃】使用。",
 ["@sk_xiecui"] = "撷翠", ["@sk_youxu"] = "忧恤",
}

-- 极略37：岑昏（jilue.md L2359-L2360）
sk_cenhun = sgs.General(extension, "sk_cenhun", "wu", 3)
local function sk_jishe_card(player, name)
 local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
 if not card then return nil end
 if not (card:objectName() == "fire_attack" or card:isNDTrick() and not card:isDamageCard()) then card:deleteLater(); return nil end
 card:setSkillName("sk_jishe")
 if not card:isAvailable(player) then card:deleteLater(); return nil end
 return card
end
sk_jisheVS = sgs.CreateViewAsSkillV2{
 name = "sk_jishe", n = 0, guhuo_type = "r",
 can_activate = function(skill, request)
  if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
  for _, name in ipairs(sgs.Sanguosha:getCardNames("TrickCard")) do
   local card = sk_jishe_card(request:getInitiator(), name)
   if card then card:deleteLater(); return true end
  end
  return false
 end,
 create_card = function(skill, request)
  local name = request:getUserString()
  if not name or name == "" then
   local card = request:getInitiator():getTag("sk_jishe"):toCard()
   if card then name = card:objectName() end
  end
  if not name or name == "" then return nil end
  return sk_jishe_card(request:getInitiator(), name)
 end,
}
sk_jishe = sgs.CreateTriggerSkillV2{
 name = "sk_jishe", view_as_skill = sk_jisheVS, events = {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if not player then return end
  if event == sgs.EventPhaseChanging then room:setPlayerMark(player, "sk_jishe_count", 0)
  elseif event == sgs.CardUsed then
   local card = ctx.original_data:toCardUse().card
   if card and card:getSkillName() == "sk_jishe" then room:addPlayerMark(player, "sk_jishe_count") end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardFinished or not player or not player:hasSkill(skill:objectName()) then return false end
  local card = data:toCardUse().card
  if card and card:getSkillName() == skill:objectName() and player:getMark("sk_jishe_count") > player:getMaxHp() then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx) room:loseMaxHp(player, 1); return false end,
}
sk_lianhuo = sgs.CreateTriggerSkillV2{
 name = "sk_lianhuo", frequency = sgs.Skill_Compulsory, events = {sgs.TargetConfirmed, sgs.DamageInflicted},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.TargetConfirmed then
   local use = data:toCardUse()
   if use.card and use.from and not use.card:isKindOf("EquipCard") and use.to:contains(player) then return skill:objectName() end
  else
   if player:isChained() and data:toDamage().nature == sgs.DamageStruct_Fire then return skill:objectName() end
  end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.TargetConfirmed then room:setPlayerProperty(player, "chained", sgs.QVariant(true))
  else local damage = ctx.original_data:toDamage(); damage.damage = damage.damage + 2; ctx.original_data:setValue(damage) end
  return false
 end,
}
sk_cenhun:addSkill(sk_jishe)
sk_cenhun:addSkill(sk_lianhuo)
sgs.LoadTranslationTable{
 ["sk_cenhun"] = "SK岑昏", ["&sk_cenhun"] = "岑昏", ["#sk_cenhun"] = "岑昏",
 ["sk_jishe"] = "极奢", [":sk_jishe"] = "出牌阶段，你可以视为使用一张【火攻】或一张非伤害类普通锦囊牌；此牌结算后，若你本阶段以此法使用牌数大于体力上限，你减1点体力上限。",
 ["sk_lianhuo"] = "链祸", [":sk_lianhuo"] = "锁定技，当你成为一名角色使用非装备牌的目标后，你横置武将牌。当你受到火焰伤害时，若你处于“连环状态”，此伤害+2。",
}

-- 极略39：刘焉（jilue.md L2387）
sk_liuyan = sgs.General(extension, "sk_liuyan", "qun", 3)
sk_zhulu = sgs.CreateTriggerSkillV2{
 name = "sk_zhulu", events = {sgs.Damage},
 can_trigger = function(skill, event, room, player, data)
  local damage = data:toDamage()
  if player and player:hasSkill(skill:objectName()) and damage.from == player and damage.to and damage.to ~= player then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.original_data:toDamage().to
  local recipients = room:getOtherPlayers(target)
  room:sortByActionOrder(recipients)
  for _, p in sgs.qlist(recipients) do
   if target:getCards("hej"):isEmpty() then break end
   if p:isAlive() then
    local id = room:askForCardChosen(p, target, "hej", skill:objectName())
    room:obtainCard(p, id, false)
   end
  end
  return false
 end,
}
sk_limuCard = sgs.CreateSkillCard{
 name = "sk_limuCard", target_fixed = true, will_throw = false,
 on_use = function(self, room, source, targets)
  local material = sgs.Sanguosha:getCard(self:getSubcards():first())
  local card = sgs.Sanguosha:cloneCard("indulgence", material:getSuit(), material:getNumber())
  card:addSubcards(self:getSubcards()); card:setSkillName("sk_limu")
  local x = material:getNumber()
  local use = sgs.CardUseStruct(); use.from = source; use.card = card; use.to:append(source)
  room:useCard(use)
  card:deleteLater()
  if source:isAlive() then
   local recover = sgs.RecoverStruct(); recover.who = source; room:recover(source, recover)
   source:drawCards(x, "sk_limu")
  end
 end,
}
sk_limu = sgs.CreateViewAsSkillV2{
 name = "sk_limu", n = 1,
 can_activate = function(skill, request)
  if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
  local p = request:getInitiator()
  local card = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)
  local available = not p:hasUsed("#sk_limuCard") and not p:containsTrick("indulgence") and card:isAvailable(p) and not p:isProhibited(p, card)
  card:deleteLater(); return available
 end,
 can_select_card = function(skill, request, card)
  return card:getSuit() == sgs.Card_Diamond and request:getSelectedCardIds():isEmpty()
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request) local card = sk_limuCard:clone(); card:addSubcards(request:getSelectedCardIds()); return card end,
}
sk_limuMod = sgs.CreateTargetModSkillV2{
 name = "#sk_limu", pattern = ".", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and p:hasSkill("sk_limu") and not p:getJudgingArea():isEmpty() and ctx:getModType() == sgs.TargetModSkill_Residue then return 9999 end
  return false
 end,
}
sk_liuyan:addSkill(sk_zhulu)
sk_liuyan:addSkill(sk_limu)
sk_liuyan:addSkill(sk_limuMod)
extension:insertRelatedSkills("sk_limu", "#sk_limu")
sgs.LoadTranslationTable{
 ["sk_liuyan"] = "SK刘焉", ["&sk_liuyan"] = "刘焉", ["#sk_liuyan"] = "刘焉",
 ["sk_zhulu"] = "逐鹿", [":sk_zhulu"] = "当你对一名其他角色造成伤害后，你可以令除该角色以外的角色依次获得其一张牌。",
 ["sk_limu"] = "立牧", [":sk_limu"] = "出牌阶段限一次，你可以将一张方块牌当【乐不思蜀】对自己使用，然后你回复1点体力并摸X张牌（X为此牌点数）。若你的判定区内有牌，你使用牌无次数限制。",
}

-- 极略39：公孙渊（jilue.md L2389）
sk_gongsunyuan = sgs.General(extension, "sk_gongsunyuan", "qun", 4)
sk_huaiyiCard = sgs.CreateSkillCard{
 name = "sk_huaiyiCard",
 filter = function(self, targets, target, source) return #targets == 0 and target ~= source and not target:getCards("hej"):isEmpty() end,
 feasible = function(self, targets) return #targets == 1 end,
 on_use = function(self, room, source, targets)
  local id = room:askForCardChosen(source, targets[1], "hej", "sk_huaiyi")
  source:addToPile("sk_yi", id)
 end,
}
sk_huaiyiVS = sgs.CreateViewAsSkillV2{
 name = "sk_huaiyi", n = 0,
 can_activate = function(skill, request)
  return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and not request:getInitiator():hasUsed("#sk_huaiyiCard")
 end,
 can_select_target = function(skill, request, selected, candidate)
  return #selected == 0 and candidate ~= request:getInitiator() and not candidate:getCards("hej"):isEmpty()
 end,
 targets_feasible = function(skill, request, selected) return #selected == 1 end,
 create_card = function() return sk_huaiyiCard:clone() end,
}
sk_huaiyi = sgs.CreateTriggerSkillV2{
 name = "sk_huaiyi", view_as_skill = sk_huaiyiVS, events = {sgs.DrawNCards, sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:hasSkill(skill:objectName()) then return false end
  local x = player:getPile("sk_yi"):length()
  if event == sgs.DrawNCards and x > 0 or event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getHp() < x then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.DrawNCards then
   local draw = ctx.original_data:toDraw()
   draw.num = draw.num + player:getPile("sk_yi"):length()
   ctx.original_data:setValue(draw)
  else
   local targets = room:getOtherPlayers(player)
   room:sortByActionOrder(targets)
   for _, target in sgs.qlist(targets) do
    if target:isAlive() then
     local damage = sgs.DamageStruct(); damage.from = player; damage.to = target; damage.damage = 1; damage.reason = skill:objectName()
     room:damage(damage)
    end
   end
   if player:isAlive() and not player:getPile("sk_yi"):isEmpty() then
    local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    card:addSubcards(player:getPile("sk_yi")); room:obtainCard(player, card, true); card:deleteLater()
   end
  end
  return false
 end,
}
sk_gongsunyuan:addSkill(sk_huaiyi)
sgs.LoadTranslationTable{
 ["sk_gongsunyuan"] = "SK公孙渊", ["&sk_gongsunyuan"] = "公孙渊", ["#sk_gongsunyuan"] = "公孙渊",
 ["sk_huaiyi"] = "怀异", [":sk_huaiyi"] = "出牌阶段限一次，你可以将一名其他角色的一张牌置于武将牌上，称为“异”。你的摸牌阶段的摸牌数+X；结束阶段，若你的体力值小于X，你对其他角色各造成1点伤害，然后获得所有“异”（X为“异”的数量）。",
 ["sk_yi"] = "异",
}

-- 极略39：南华老仙（jilue.md L2397、L2399）
sk_nanhualaoxian = sgs.General(extension, "sk_nanhualaoxian", "qun", 3)
-- Signed offsets preserve the original's unrestricted numerical changes.
local function sk_tiandao_number(player, key)
 return 1 + player:getTag("sk_tiandao_" .. key):toInt()
end
sk_tiandao = sgs.CreateTriggerSkillV2{
 name = "sk_tiandao", frequency = sgs.Skill_Compulsory, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Start then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local draw = sk_tiandao_number(player, "draw")
  if draw > 0 then player:drawCards(draw, skill:objectName()) end
  if not player:isAlive() then return false end
  local present, pool, seen = {}, {}, {}
  for _, p in sgs.qlist(room:getAllPlayers()) do
   present[p:getGeneralName()] = true
   present[p:getGeneral2Name()] = true
  end
  for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
   local general = sgs.Sanguosha:getGeneral(name)
   if general and general:getKingdom() == "qun" and not present[name] then
    for _, candidate in sgs.qlist(general:getVisibleSkillList()) do
     local n = candidate:objectName()
     if not seen[n] then seen[n] = true; table.insert(pool, n) end
    end
   end
  end
  for i = 1, sk_tiandao_number(player, "skills") do
   if #pool == 0 or not player:isAlive() then break end
   room:acquireSkill(player, table.remove(pool, math.random(#pool)))
  end
  if not player:isAlive() or room:getOtherPlayers(player):isEmpty() then return false end
  local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName())
  for i = 1, sk_tiandao_number(player, "discard") do
   local cards = target:getCards("he")
   if cards:isEmpty() or not target:isAlive() then break end
   room:throwCard(cards:at(math.random(cards:length()) - 1), target, player)
  end
  local amount = sk_tiandao_number(player, "damage")
  if target:isAlive() and amount > 0 then
   local damage = sgs.DamageStruct(); damage.from = player; damage.to = target; damage.damage = amount
   damage.nature = sgs.DamageStruct_Thunder; damage.reason = skill:objectName(); room:damage(damage)
  end
  return false
 end,
}
sk_xianshou = sgs.CreateTriggerSkillV2{
 name = "sk_xianshou", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_RoundStart then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName())
  if not target:hasSkill("sk_tiandao") then room:acquireSkill(target, "sk_tiandao")
  else
   local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = skill:objectName()
   judge.pattern = ".|spade"; judge.good = true; room:judge(judge)
   local keys = {"draw", "skills", "discard", "damage"}
   local key = "sk_tiandao_" .. keys[math.random(#keys)]
   target:setTag(key, sgs.QVariant(target:getTag(key):toInt() + (judge:isGood() and -1 or 1)))
  end
  return false
 end,
}
sk_chengfeng = sgs.CreateTriggerSkillV2{
 name = "sk_chengfeng", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.DamageInflicted, sgs.EventPhaseChanging},
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.DamageInflicted then
   if player and player:hasSkill(skill:objectName()) then return skill:objectName() end
  elseif data:toPhaseChange().to == sgs.Player_NotActive then
   local names, owners = {}, {}
   for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
    if p:getMark("sk_chengfeng") >= 2 then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
   end
   if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging then
   local owner = ctx.invoker or player
   room:removePlayerMark(owner, "sk_chengfeng", 2); owner:gainAnExtraTurn()
  else
   local judge = sgs.JudgeStruct(); judge.who = player; judge.reason = skill:objectName()
   judge.pattern = ".|spade"; judge.good = true; room:judge(judge)
   if judge:isGood() then room:addPlayerMark(player, "sk_chengfeng")
   else
    local damage = ctx.original_data:toDamage(); damage.damage = damage.damage - 1; ctx.original_data:setValue(damage)
    return damage.damage <= 0
   end
  end
  return false
 end,
}
sk_nanhualaoxian:addSkill(sk_xianshou)
sk_nanhualaoxian:addSkill(sk_chengfeng)
local sk_nanhua_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sk_tiandao") then sk_nanhua_skills:append(sk_tiandao) end
sgs.Sanguosha:addSkills(sk_nanhua_skills)
extension:insertRelatedSkills("sk_xianshou", "sk_tiandao")
sgs.LoadTranslationTable{
 ["sk_nanhualaoxian"] = "SK南华老仙", ["&sk_nanhualaoxian"] = "南华老仙", ["#sk_nanhualaoxian"] = "南华老仙",
 ["sk_xianshou"] = "仙授", [":sk_xianshou"] = "回合开始时，你可以令一名角色执行一项：1若其没有技能“天道”，其获得之.；2.若其有，其进行一次判定。若结果为/不为黑桃，你令其“天道”中随机一个数字-1/+1。",
 ["sk_chengfeng"] = "乘风", [":sk_chengfeng"] = "锁定技，当你受到伤害时，你判定，若不为黑桃，此伤害值-1；否则你获得一枚“乘风”标记。每回合结束时，若你拥有至少两枚此标记，你弃置两枚标记，并执行一个额外的回合。",
 ["sk_tiandao"] = "天道", [":sk_tiandao"] = "锁定技，准备阶段，你摸一张牌，随机获得任意个未上场的群势力角色的共计一个技能，然后你令一名其他角色随机弃置一张牌，且你对其造成1点雷电伤害。",
}

-- 极略42：文鸯（jilue.md L2417-L2419）
sk_wenyang = sgs.General(extension, "sk_wenyang", "wei", 7)
sk_jueyong = sgs.CreateTriggerSkillV2{
 name = "sk_jueyong", frequency = sgs.Skill_Limited, limit_mark = "@sk_jueyong", events = {sgs.Damage},
 can_trigger = function(skill, event, room, player, data)
  local d = data:toDamage()
  if player and player:hasSkill(skill:objectName()) and player:getMark("@sk_jueyong") > 0 and d.from == player and d.card and d.card:isKindOf("Slash") and player:getHandcardNum() > player:getMaxHp() then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  room:removePlayerMark(player, "@sk_jueyong")
  room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getHandcardNum()))
  local r = sgs.RecoverStruct(); r.who = player; r.recover = player:getLostHp(); room:recover(player, r)
  return false
 end,
}
sk_choujueCard = sgs.CreateSkillCard{
 name = "sk_choujueCard", will_throw = false,
 filter = function(self, targets, target, source)
  local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:setSkillName("sk_choujue")
  local list = sgs.PlayerList(); for _, p in ipairs(targets) do list:append(p) end
  local ok = c:targetFilter(list, target, source) and not source:isProhibited(target, c); c:deleteLater(); return ok
 end,
 feasible = function(self, targets, source) return #targets > 0 end,
 on_use = function(self, room, source, targets)
  room:loseMaxHp(source, 1); source:drawCards(1, "sk_choujue")
  if not source:isAlive() then return end
  local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:setSkillName("sk_choujue")
  local use = sgs.CardUseStruct(); use.card = c; use.from = source
  for _, p in ipairs(targets) do if p:isAlive() then use.to:append(p) end end
  room:useCard(use, false); c:deleteLater()
 end,
}
sk_choujueVS = sgs.CreateViewAsSkillV2{
 name = "sk_choujue", n = 0,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and not request:getInitiator():hasUsed("#sk_choujueCard") end,
 create_card = function() return sk_choujueCard:clone() end,
}
sk_choujue = sgs.CreateTriggerSkillV2{
 name = "sk_choujue", view_as_skill = sk_choujueVS, events = {sgs.Damage, sgs.CardUsed, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if not player or not player:hasSkill(skill:objectName()) then return end
  if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then player:setTag("sk_choujue_history", sgs.QVariant("")) end
  if event == sgs.CardUsed then
   local c = ctx.original_data:toCardUse().card
   if c and c:isKindOf("SkillCard") then
    local keys = player:getTag("sk_choujue_history"):toString()
    player:setTag("sk_choujue_history", sgs.QVariant(keys .. "+" .. c:getClassName()))
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.Damage or not player or not player:hasSkill(skill:objectName()) then return false end
  local d = data:toDamage()
  if d.from == player and d.card and d.card:getSkillName() == skill:objectName() then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  for _, s in sgs.qlist(player:getVisibleSkillList()) do
   if s:getDescription(player):find("出牌阶段限一次", 1, true) then
    local name = s:objectName()
    for _, key in ipairs(player:getTag("sk_choujue_history"):toString():split("+")) do
     if key ~= "" and key:lower():find(name:lower(), 1, true) then room:addPlayerHistory(player, key, -player:usedTimes(key)) end
    end
    for _, mark in ipairs(player:getMarkNames()) do
     if mark:find(name, 1, true) and not mark:find("@", 1, true) then room:setPlayerMark(player, mark, 0) end
    end
   end
  end
  return false
 end,
}
sk_choujueMod = sgs.CreateTargetModSkillV2{
 name = "#sk_choujue", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  if ctx:getCard() and ctx:getCard():getSkillName() == "sk_choujue" and (ctx:getModType() == sgs.TargetModSkill_DistanceLimit or ctx:getModType() == sgs.TargetModSkill_Residue) then return 9999 end
  return false
 end,
}
sk_wenyang:addSkill(sk_jueyong)
sk_wenyang:addSkill(sk_choujue)
sk_wenyang:addSkill(sk_choujueMod)
extension:insertRelatedSkills("sk_choujue", "#sk_choujue")
sgs.LoadTranslationTable{
 ["sk_wenyang"] = "SK文鸯", ["&sk_wenyang"] = "文鸯", ["#sk_wenyang"] = "文鸯",
 ["sk_jueyong"] = "绝勇", ["@sk_jueyong"] = "绝勇", [":sk_jueyong"] = "限定技，当你使用【杀】造成伤害时，若你的手牌数大于体力上限，你可以将体力上限改为X（X为你的手牌数），然后你将体力回复至上限。",
 ["sk_choujue"] = "仇决", [":sk_choujue"] = "出牌阶段限一次，你可以减1点体力上限并摸一张牌，然后你视为使用一张无次数与距离限制的【杀】；当你以此法造成伤害时，你令你所有“出牌阶段限一次”的技能视为此阶段未发动过。",
}

-- 极略42：郭皇后（jilue.md L2425-L2429）
sk_guohuanghou = sgs.General(extension, "sk_guohuanghou", "wei", 3, false)
local function sk_jiaozhao_clone(name, ids)
 local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
 if not c then return nil end
 if not (c:isKindOf("BasicCard") or c:isNDTrick()) then c:deleteLater(); return nil end
 c:addSubcards(ids); c:setSkillName("sk_jiaozhao"); return c
end
sk_jiaozhaoCard = sgs.CreateSkillCard{
 name = "sk_jiaozhaoCard", will_throw = false, handling_method = sgs.Card_MethodNone,
 filter = function(self, targets, target, source)
  local c = sk_jiaozhao_clone(self:getUserString(), self:getSubcards())
  if not c then return false end
  local ok = target ~= source and not source:isProhibited(target, c)
  c:deleteLater(); return ok
 end,
 feasible = function(self, targets, source) return #targets > 0 end,
 on_validate = function(self, use)
  local p = use.from
  if p:getMark("sk_jiaozhao_danxin") == 0 then p:getRoom():setPlayerMark(p, "sk_jiaozhao_used", 1) end
  return sk_jiaozhao_clone(self:getUserString(), self:getSubcards())
 end,
}
sk_jiaozhao = sgs.CreateViewAsSkillV2{
 name = "sk_jiaozhao", n = 1, guhuo_type = "l",
 can_activate = function(skill, request)
  local p = request:getInitiator()
  return not p:isKongcheng() and (request:getPattern() == "@@sk_jiaozhao" or request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and p:getMark("sk_jiaozhao_used") == 0)
 end,
 can_select_card = function(skill, request, card) return not card:isEquipped() and request:getSelectedCardIds():isEmpty() end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local name = request:getUserString()
  if not name or name == "" then local c = request:getInitiator():getTag("sk_jiaozhao"):toCard(); if c then name = c:objectName() end end
  if not name or name == "" then return nil end
  local c = sk_jiaozhao_clone(name, request:getSelectedCardIds()); if not c then return nil end; c:deleteLater()
  local result = sk_jiaozhaoCard:clone(); result:addSubcards(request:getSelectedCardIds()); result:setUserString(name); return result
 end,
}
sk_jiaozhaoMod = sgs.CreateTargetModSkillV2{
 name = "#sk_jiaozhao", pattern = ".", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local c = ctx:getCard()
  if c and c:getSkillName() == "sk_jiaozhao" then return 9999 end
  return false
 end,
}
sk_jiaozhaoProhibit = sgs.CreateProhibitSkillV2{
 name = "#sk_jiaozhao_self", holder_selector = sgs.CorrectSkill_System,
 is_prohibited = function(skill, ctx)
  return ctx:getCard() and ctx:getCard():getSkillName() == "sk_jiaozhao" and ctx:getPrimary() == ctx:getSecondary()
 end,
}
sk_danxin = sgs.CreateTriggerSkillV2{
 name = "sk_danxin", events = {sgs.Damaged, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_Play then room:setPlayerMark(player, "sk_jiaozhao_used", 0) end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.Damaged and player and player:hasSkill(skill:objectName()) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  player:drawCards(2, skill:objectName())
  room:setPlayerMark(player, "sk_jiaozhao_danxin", 1)
  room:askForUseCard(player, "@@sk_jiaozhao", "@sk_danxin-jiaozhao")
  room:setPlayerMark(player, "sk_jiaozhao_danxin", 0)
  return false
 end,
}
sk_guohuanghou:addSkill(sk_jiaozhao)
sk_guohuanghou:addSkill(sk_danxin)
sk_guohuanghou:addSkill(sk_jiaozhaoMod)
sk_guohuanghou:addSkill(sk_jiaozhaoProhibit)
extension:insertRelatedSkills("sk_jiaozhao", "#sk_jiaozhao")
extension:insertRelatedSkills("sk_jiaozhao", "#sk_jiaozhao_self")
sgs.LoadTranslationTable{
 ["sk_guohuanghou"] = "SK郭皇后", ["&sk_guohuanghou"] = "郭皇后", ["#sk_guohuanghou"] = "郭皇后",
 ["sk_jiaozhao"] = "矫诏", [":sk_jiaozhao"] = "出牌阶段限一次，你可以将一张手牌当作任意基本牌或普通锦囊牌使用，你不能成为此牌的目标，且你使用此牌时可以指定任意名其他角色为目标（此牌无次数与距离限制）。",
 ["sk_danxin"] = "殚心", [":sk_danxin"] = "当你受到伤害后，你可以摸两张牌，然后你可以发动“矫诏”。", ["@sk_danxin-jiaozhao"] = "殚心：你可以发动“矫诏”",
}

-- 极略42：钟繇（jilue.md L2431-L2435）
sk_zhongyao = sgs.General(extension, "sk_zhongyao", "wei", 3)
local function sk_huomo_names(request)
 if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Sanguosha:getCardNames("BasicCard") end
 return (request:getPattern() or ""):split("+")
end
local function sk_huomo_card(player, name, ids, play)
 local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
 if not c then return nil end
 if not c:isKindOf("BasicCard") or player:getMark("sk_huomo_" .. c:objectName()) > 0 then c:deleteLater(); return nil end
 c:addSubcards(ids); c:setSkillName("sk_huomo")
 if play and not c:isAvailable(player) then c:deleteLater(); return nil end
 return c
end
sk_huomoVS = sgs.CreateViewAsSkillV2{
 name = "sk_huomo", n = 1, guhuo_type = "b", response_or_use = true,
 can_activate = function(skill, request)
  local p = request:getInitiator(); local black = false
  for _, c in sgs.qlist(p:getCards("he")) do if c:isBlack() then black = true; break end end
  if not black then return false end
  for _, name in ipairs(sk_huomo_names(request)) do
   local c = sk_huomo_card(p, name, sgs.IntList(), request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY)
   if c then c:deleteLater(); return true end
  end
  return false
 end,
 can_select_card = function(skill, request, card) return card:isBlack() and request:getSelectedCardIds():isEmpty() end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local p = request:getInitiator(); local name = request:getUserString()
  local play = request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
  if not name or name == "" then
   if play then local c = p:getTag("sk_huomo"):toCard(); if c then name = c:objectName() end
   else
    local choices = {}
    for _, n in ipairs(sk_huomo_names(request)) do
     local c = sk_huomo_card(p, n, request:getSelectedCardIds(), false)
     if c then table.insert(choices, n); c:deleteLater() end
    end
    if #choices == 0 then return nil end
    name = #choices == 1 and choices[1] or p:getRoom():askForChoice(p, "sk_huomo", table.concat(choices, "+"))
   end
  end
  if not name or name == "" then return nil end
  return sk_huomo_card(p, name, request:getSelectedCardIds(), play)
 end,
}
sk_huomo = sgs.CreateTriggerSkillV2{
 name = "sk_huomo", view_as_skill = sk_huomoVS, global = true,
 events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging then
   if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
    for _, p in sgs.qlist(room:getAllPlayers()) do
     for _, name in ipairs(p:getMarkNames()) do if name:find("sk_huomo_", 1, true) == 1 then room:setPlayerMark(p, name, 0) end end
    end
   end
  elseif player then
   local c
   if event == sgs.CardUsed then c = ctx.original_data:toCardUse().card else c = ctx.original_data:toCardResponse().m_card end
   if c and c:getSkillName() == "sk_huomo" then room:setPlayerMark(player, "sk_huomo_" .. c:objectName(), 1) end
  end
 end,
 can_trigger = function() return false end,
}
sk_dingguan = sgs.CreateTriggerSkillV2{
 name = "sk_dingguan", global = true, events = {sgs.TargetSpecified, sgs.Damaged, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart then room:removeTag("sk_dingguan_damaged")
  elseif event == sgs.Damaged then room:setTag("sk_dingguan_damaged", sgs.QVariant(true)) end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.TargetSpecified or not player or player:getPhase() ~= sgs.Player_Play or room:getTag("sk_dingguan_damaged"):toBool() then return false end
  local use = data:toCardUse()
  if not use.card or not use.card:isBlack() or use.to:isEmpty() then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  for _, p in sgs.qlist(ctx.original_data:toCardUse().to) do
   if p:isAlive() and room:askForChoice(owner, "sk_dingguan", "draw+cancel", sgs.QVariant(p)) == "draw" then p:drawCards(1, skill:objectName()) end
  end
  return false
 end,
}
sk_zhongyao:addSkill(sk_huomo)
sk_zhongyao:addSkill(sk_dingguan)
sgs.LoadTranslationTable{
 ["sk_zhongyao"] = "SK钟繇", ["&sk_zhongyao"] = "钟繇", ["#sk_zhongyao"] = "钟繇",
 ["sk_huomo"] = "活墨", [":sk_huomo"] = "每回合每种牌名限一次，你可以将一张黑色牌当作任意基本牌使用或打出。",
 ["sk_dingguan"] = "定关", [":sk_dingguan"] = "当一名角色在其出牌阶段使用黑色牌指定目标后，若本阶段内没有角色受到伤害，你可以令此牌的任意个目标角色各摸一张牌。",
}

-- 极略43：赵襄（jilue.md L2439-L2440）
sk_zhaoxiang = sgs.General(extension, "sk_zhaoxiang", "shu", 4, false)
sk_fanghunVS = sgs.CreateViewAsSkillV2{
 name = "sk_fanghun", n = 1, response_or_use = true,
 can_activate = function(skill, request)
  local p = request:getInitiator(); local play = request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
  if play then return sgs.Slash_IsAvailable(p) end
  return request:getPattern() == "slash" or request:getPattern() == "jink"
 end,
 can_select_card = function(skill, request, card)
  if not request:getSelectedCardIds():isEmpty() then return false end
  if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or request:getPattern() == "slash" then return card:isKindOf("Jink") end
  return card:isKindOf("Slash")
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local material = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
  local c = sgs.Sanguosha:cloneCard(material:isKindOf("Slash") and "jink" or "slash", material:getSuit(), material:getNumber())
  c:addSubcards(request:getSelectedCardIds()); c:setSkillName("sk_fanghun"); return c
 end,
}
sk_fanghun = sgs.CreateTriggerSkillV2{
 name = "sk_fanghun", view_as_skill = sk_fanghunVS, events = {sgs.CardFinished, sgs.PostCardResponded},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local c = event == sgs.CardFinished and data:toCardUse().card or data:toCardResponse().m_card
  if c and c:getSkillName() == skill:objectName() then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  if event == sgs.CardFinished then targets = ctx.original_data:toCardUse().to
  else local p = ctx.original_data:toCardResponse().m_who; if p then targets:append(p) end end
  for _, p in sgs.qlist(targets) do
   if p ~= player and p:isAlive() and not p:isKongcheng() and player:askForSkillInvoke(skill:objectName(), sgs.QVariant(p)) then
    room:obtainCard(player, room:askForCardChosen(player, p, "h", skill:objectName()), false)
   end
  end
  return false
 end,
}
sk_fuhan = sgs.CreateTriggerSkillV2{
 name = "sk_fuhan", global = true, events = {sgs.CardFinished, sgs.PostCardResponded, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(p, "sk_fuhan_used", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseChanging or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getMark("sk_fuhan_used") > 0 then return false end
  if event == sgs.PostCardResponded and not data:toCardResponse().m_isUse then return false end
  local c = event == sgs.CardFinished and data:toCardUse().card or data:toCardResponse().m_card
  if c and c:isVirtualCard() and not c:isKindOf("SkillCard") then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  room:setPlayerMark(player, "sk_fuhan_used", 1)
  local present, pool = {}, {}
  for _, p in sgs.qlist(room:getAllPlayers(true)) do present[p:getGeneralName()] = true; present[p:getGeneral2Name()] = true end
  for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
   local g = sgs.Sanguosha:getGeneral(name)
   if g and g:getKingdom() == "shu" and not present[name] and not g:getVisibleSkillList():isEmpty() then table.insert(pool, g) end
  end
  if #pool > 0 then
   local skills = sgs.QList2Table(pool[math.random(#pool)]:getVisibleSkillList())
   room:acquireSkill(player, skills[math.random(#skills)]:objectName())
  end
  return false
 end,
}
sk_zhaoxiang:addSkill(sk_fanghun)
sk_zhaoxiang:addSkill(sk_fuhan)
sgs.LoadTranslationTable{
 ["sk_zhaoxiang"] = "SK赵襄", ["&sk_zhaoxiang"] = "赵襄", ["#sk_zhaoxiang"] = "赵襄",
 ["sk_fanghun"] = "芳魂", [":sk_fanghun"] = "你可以将一张【杀】/【闪】当作【闪】/【杀】使用或打出；然后你可以获得对方的一张手牌。",
 ["sk_fuhan"] = "扶汉", [":sk_fuhan"] = "每回合限一次，你使用的转化牌结算后，你可以随机获得一个未上场的蜀势力角色的随机一个技能。",
}

-- 极略43：张嶷（jilue.md L2444-L2446）
sk_zhangni = sgs.General(extension, "sk_zhangni", "shu", 4)
sk_wurongCard = sgs.CreateSkillCard{
 name = "sk_wurongCard",
 filter = function(self, targets, target, source) return #targets == 0 and target ~= source and not target:isKongcheng() end,
 on_use = function(self, room, source, targets)
  local target = targets[1]
  repeat
   if not source:isAlive() or not target:isAlive() or target:isKongcheng() then return end
   local id = room:askForCardChosen(source, target, "h", "sk_wurong")
   local shown = sgs.Sanguosha:getCard(id); room:showCard(target, id)
   local cost = room:askForCard(source, ".|.|.|hand", "@sk_wurong-discard", sgs.QVariant(target), "sk_wurong")
   if not cost then return end
   if cost:getTypeId() ~= shown:getTypeId() then
    local names = {}
    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
     if skill:getFrequency() ~= sgs.Skill_Compulsory and skill:getFrequency() ~= sgs.Skill_Wake then table.insert(names, skill:objectName()) end
    end
    if #names > 0 then
     local name = room:askForChoice(source, "sk_wurong", table.concat(names, "+"), sgs.QVariant(target))
     room:addPlayerMark(target, "Qingcheng" .. name)
     local old = target:getTag("sk_wurong_disabled"):toString()
     target:setTag("sk_wurong_disabled", sgs.QVariant(old == "" and name or old .. "+" .. name))
    end
    local d = sgs.DamageStruct(); d.from = source; d.to = target; d.damage = 1; d.reason = "sk_wurong"; room:damage(d)
    return
   end
   if room:getCardOwner(id) == target and room:getCardPlace(id) == sgs.Player_PlaceHand then room:obtainCard(source, id, true) end
  until not source:isAlive() or not target:isAlive() or target:isKongcheng() or not source:askForSkillInvoke("sk_wurong", sgs.QVariant(target))
 end,
}
sk_wurongVS = sgs.CreateViewAsSkillV2{
 name = "sk_wurong", n = 0,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and not request:getInitiator():hasUsed("#sk_wurongCard") end,
 create_card = function() return sk_wurongCard:clone() end,
}
sk_wurong = sgs.CreateTriggerSkillV2{
 name = "sk_wurong", view_as_skill = sk_wurongVS, global = true, events = {sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if ctx.original_data:toPhaseChange().to ~= sgs.Player_NotActive then return end
  for _, p in sgs.qlist(room:getAllPlayers(true)) do
   local names = p:getTag("sk_wurong_disabled"):toString()
   if names ~= "" then
    for _, name in ipairs(names:split("+")) do room:removePlayerMark(p, "Qingcheng" .. name) end
    p:removeTag("sk_wurong_disabled")
   end
  end
 end,
 can_trigger = function() return false end,
}
sk_zhangni:addSkill(sk_wurong)
sgs.LoadTranslationTable{
 ["sk_zhangni"] = "SK张嶷", ["&sk_zhangni"] = "张嶷", ["#sk_zhangni"] = "张嶷",
 ["sk_wurong"] = "怃戎", [":sk_wurong"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你可以弃置一张手牌，若这两张牌：类别不同，你令该角色本回合内一个非锁定技失效，然后你对其造成1点伤害；类别相同，你获得其展示的牌，然后你可以对该角色重复此流程。",
 ["@sk_wurong-discard"] = "怃戎：你可以弃置一张手牌",
}

-- 极略45：陈群（jilue.md L2462-L2463）
sk_chenqun = sgs.General(extension, "sk_chenqun", "wei", 3)
sk_dingpinCard = sgs.CreateSkillCard{
 name = "sk_dingpinCard",
 filter = function(self, targets, target, source)
  return #targets == 0 and target ~= source and target:getMark("sk_dingpin_" .. source:objectName()) == 0
 end,
 on_use = function(self, room, source, targets)
  local target = targets[1]
  room:setPlayerMark(target, "sk_dingpin_" .. source:objectName(), 1)
  local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = "sk_dingpin"; judge.pattern = "."; room:judge(judge)
  if judge.card:isBlack() then
   local choice = room:askForChoice(source, "sk_dingpin", "draw+discard+cancel", sgs.QVariant(target))
   if choice == "draw" then target:drawCards(3, "sk_dingpin")
   elseif choice == "discard" then room:askForDiscard(target, "sk_dingpin", 3, 3, false, true) end
  elseif judge.card:getSuit() == sgs.Card_Diamond then source:drawCards(1, "sk_dingpin")
  elseif judge.card:getSuit() == sgs.Card_Heart then source:turnOver() end
 end,
}
sk_dingpinVS = sgs.CreateViewAsSkillV2{
 name = "sk_dingpin", n = 1,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
 can_select_card = function(skill, request, card)
  return request:getSelectedCardIds():isEmpty() and not card:isEquipped() and not request:getInitiator():isJilei(card)
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request) local c = sk_dingpinCard:clone(); c:addSubcards(request:getSelectedCardIds()); return c end,
}
sk_dingpin = sgs.CreateTriggerSkillV2{
 name = "sk_dingpin", view_as_skill = sk_dingpinVS, global = true, events = {sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if ctx.original_data:toPhaseChange().from == sgs.Player_Play then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_dingpin_" .. player:objectName(), 0) end
  end
 end,
 can_trigger = function() return false end,
}
sk_faen = sgs.CreateTriggerSkillV2{
 name = "sk_faen", global = true, events = {sgs.TurnedOver},
 can_trigger = function(skill, event, room, player, data)
  if not player then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), sgs.QVariant(player)) end,
 on_effect = function(skill, event, room, player, ctx) player:drawCards(3, skill:objectName()); return false end,
}
sk_chenqun:addSkill(sk_dingpin)
sk_chenqun:addSkill(sk_faen)
sgs.LoadTranslationTable{
 ["sk_chenqun"] = "SK陈群", ["&sk_chenqun"] = "陈群", ["#sk_chenqun"] = "陈群",
 ["sk_dingpin"] = "定品", [":sk_dingpin"] = "出牌阶段，你可以弃置一张手牌并令一名本阶段未以此法选择过的其他角色进行判定。若为黑色，你可以令其摸或弃置三张牌；若为方块，你摸一张牌；若为红桃，你翻面。",
 ["sk_faen"] = "法恩", [":sk_faen"] = "当一名角色翻面后，你可以令其摸三张牌。",
}

-- 极略45：曹纯（jilue.md L2467-L2469）
sk_caochun = sgs.General(extension, "sk_caochun", "wei", 4)
sk_shanjia = sgs.CreateTriggerSkillV2{
 name = "sk_shanjia", frequency = sgs.Skill_Compulsory, global = true, events = {sgs.CardEffect},
 on_record = function(skill, event, room, player, ctx)
  local effect = ctx.original_data:toCardEffect()
  local source, card = effect.from, effect.card
  if not source or not source:hasSkill(skill:objectName()) or not card then return end
  local extra = card:isKindOf("Slash") and not source:getOffensiveHorse()
  if card:isNDTrick() and not source:getDefensiveHorse() and not card:isKindOf("Nullification") and not card:isKindOf("Collateral") and not card:isKindOf("IronChain") then extra = true end
  if extra then effect.extra_effect = effect.extra_effect + 1; ctx.original_data:setValue(effect) end
 end,
 can_trigger = function() return false end,
}
sk_shanjiaDist = sgs.CreateDistanceSkillV2{
 name = "#sk_shanjia", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local from, to = ctx:getPrimary(), ctx:getSecondary()
  local n = 0
  if from and from:hasSkill("sk_shanjia") and not from:getOffensiveHorse() then n = n - 2 end
  if to and to:hasSkill("sk_shanjia") and not to:getDefensiveHorse() then n = n + 2 end
  if n == 0 then return false end
  return n
 end,
}
sk_caochun:addSkill(sk_shanjia)
sk_caochun:addSkill(sk_shanjiaDist)
extension:insertRelatedSkills("sk_shanjia", "#sk_shanjia")
sgs.LoadTranslationTable{
 ["sk_caochun"] = "SK曹纯", ["&sk_caochun"] = "曹纯", ["#sk_caochun"] = "曹纯",
 ["sk_shanjia"] = "缮甲", [":sk_shanjia"] = "锁定技，若你的装备区内没有攻击坐骑牌，你计算到其他角色的距离-2且你使用的【杀】额外结算一次；若你的装备区内没有防御坐骑牌，其他角色计算到你的距离+2且你使用的普通锦囊牌额外结算一次（【无懈可击】、【借刀杀人】、【铁索连环】除外）。",
}

-- 极略46：凌操（jilue.md L2489）
sk_lingcao = sgs.General(extension, "sk_lingcao", "wu", 4)
sk_dujin = sgs.CreateTriggerSkillV2{
 name = "sk_dujin", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.CardUsed, sgs.ConfirmDamage, sgs.PostCardResponded, sgs.CardFinished, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  local data = ctx.original_data
  if event == sgs.EventPhaseChanging then
   local change = data:toPhaseChange()
   if change.from == sgs.Player_Play or change.to == sgs.Player_Play then room:setPlayerMark(player, "sk_dujin_slashes", 0) end
  elseif event == sgs.CardUsed then
   local use = data:toCardUse()
   if use.from and use.from:getPhase() == sgs.Player_Play and use.card and use.card:isKindOf("Slash") then
    room:addPlayerMark(use.from, "sk_dujin_slashes")
    if use.from:hasSkill(skill:objectName()) then
     if use.from:getMark("sk_dujin_slashes") == 1 then
      room:setCardFlag(use.card, "sk_dujin_first")
      local list = use.no_respond_list
      if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
      use.no_respond_list = list; data:setValue(use)
     else room:setCardFlag(use.card, "sk_dujin_later") end
    end
   end
  elseif event == sgs.ConfirmDamage then
   local damage = data:toDamage()
   if damage.card and damage.card:hasFlag("sk_dujin_first") then damage.damage = damage.damage + 1; data:setValue(damage) end
  elseif event == sgs.CardFinished then
   local card = data:toCardUse().card
   if card then
    room:setCardFlag(card, "-sk_dujin_first")
    room:setCardFlag(card, "-sk_dujin_later")
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.PostCardResponded or not player or not player:isAlive() then return false end
  local response = data:toCardResponse()
  if not response.m_card or not response.m_toCard or not response.m_toCard:hasFlag("sk_dujin_later") then return false end
  local source = room:getCardUser(response.m_toCard)
  if source and source:isAlive() and source ~= player then return skill:objectName(), source:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local damage = sgs.DamageStruct()
  damage.from = player; damage.to = ctx.invoker; damage.damage = 1; damage.reason = skill:objectName()
  room:damage(damage)
  return false
 end,
}
sk_dujinMod = sgs.CreateTargetModSkillV2{
 name = "#sk_dujin", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and p:hasSkill("sk_dujin") and ctx:getModType() == sgs.TargetModSkill_Residue then return 9999 end
  return false
 end,
}
sk_lingcao:addSkill(sk_dujin)
sk_lingcao:addSkill(sk_dujinMod)
extension:insertRelatedSkills("sk_dujin", "#sk_dujin")
sgs.LoadTranslationTable{
 ["sk_lingcao"] = "SK凌操", ["&sk_lingcao"] = "凌操", ["#sk_lingcao"] = "凌操",
 ["sk_dujin"] = "独进", [":sk_dujin"] = "锁定技，你使用【杀】无次数限制。当你于出牌阶段使用【杀】时，若为第一张【杀】，则此牌不能被响应且伤害值+1；否则，此牌被其他角色响应后，该角色对你造成1点伤害。",
}

-- 极略46：赵嫣（jilue.md L2489）
sk_zhaoyan = sgs.General(extension, "sk_zhaoyan", "wu", 3, false)
sk_sanjueCard = sgs.CreateSkillCard{
 name = "sk_sanjueCard", will_throw = false, handling_method = sgs.Card_MethodNone,
 filter = function(self, targets, target, source) return #targets == 0 end,
 feasible = function(self, targets, source) return #targets == 1 end,
 on_use = function(self, room, source, targets)
  local library = source:getTag("sk_sanjue_library"):toString()
  if library == "" or not targets[1]:isAlive() then return end
  local chosen = room:askForChoice(source, "sk_sanjue", library, sgs.QVariant(targets[1]))
  room:acquireSkill(targets[1], chosen)
 end,
}
sk_sanjueVS = sgs.CreateViewAsSkillV2{
 name = "sk_sanjue", n = 0,
 can_activate = function(skill, request)
  return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():getTag("sk_sanjue_library"):toString() ~= ""
 end,
 create_card = function() return sk_sanjueCard:clone() end,
}
sk_sanjue = sgs.CreateTriggerSkillV2{
 name = "sk_sanjue", frequency = sgs.Skill_Compulsory, global = true, view_as_skill = sk_sanjueVS,
 events = {sgs.CardUsed, sgs.CardResponded},
 on_record = function(skill, event, room, player, ctx)
  if not player then return end
  local card
  if event == sgs.CardUsed then card = ctx.original_data:toCardUse().card
  else
   local response = ctx.original_data:toCardResponse()
   if response.m_isUse then card = response.m_card end
  end
  if card then room:addPlayerMark(player, "sk_sanjue_name_" .. card:objectName()) end
 end,
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local card
  if event == sgs.CardUsed then card = data:toCardUse().card
  else local response = data:toCardResponse(); if response.m_isUse then card = response.m_card end end
  if card then
   local n = player:getMark("sk_sanjue_name_" .. card:objectName())
   if n == 1 or n == 3 then return skill:objectName() end
  end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  player:drawCards(1, skill:objectName())
  local present, pool = {}, {}
  for _, p in sgs.qlist(room:getAllPlayers(true)) do
   present[p:getGeneralName()] = true; present[p:getGeneral2Name()] = true
  end
  for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
   local general = sgs.Sanguosha:getGeneral(name)
   if general and general:getKingdom() == "wu" and not present[name] and not general:getVisibleSkillList():isEmpty() then table.insert(pool, general) end
  end
  if #pool > 0 then
   local skills = sgs.QList2Table(pool[math.random(#pool)]:getVisibleSkillList())
   local chosen = skills[math.random(#skills)]:objectName()
   local library = player:getTag("sk_sanjue_library"):toString()
   local names = library == "" and {} or library:split("+")
   if not table.contains(names, chosen) then table.insert(names, chosen) end
   player:setTag("sk_sanjue_library", sgs.QVariant(table.concat(names, "+")))
  end
  return false
 end,
}
sk_zhaoyan:addSkill(sk_sanjue)
sgs.LoadTranslationTable{
 ["sk_zhaoyan"] = "SK赵嫣", ["&sk_zhaoyan"] = "赵嫣", ["#sk_zhaoyan"] = "锦绘山河",
 ["sk_sanjue"] = "三绝", [":sk_sanjue"] = "锁定技，当你首次或第三次使用一种牌名的牌时，你摸一张牌并随机将一个未上场的吴势力角色的一个技能加入技能库。出牌阶段，你可以令一名角色获得一个你选择的技能库中的技能。",
}

-- 极略47：何太后（jilue.md L2493-L2494）
sk_hetaihou = sgs.General(extension, "sk_hetaihou", "qun", 3, false)
sk_zhendu = sgs.CreateTriggerSkillV2{
 name = "sk_zhendu", global = true,
 events = {sgs.EventPhaseStart, sgs.ConfirmDamage, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_zhendu_turn", 0) end
  elseif event == sgs.ConfirmDamage then
   local d = ctx.original_data:toDamage()
   if d.from and d.from ~= d.to then
    d.damage = d.damage + d.from:getMark("sk_zhendu_turn"); ctx.original_data:setValue(d)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or player:getPhase() ~= sgs.Player_Play then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return room:askForSkillInvoke(player, skill:objectName(), sgs.QVariant(ctx.invoker))
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  room:addPlayerMark(target, "sk_zhendu_turn")
  if target ~= player then room:loseHp(target, 1) end
  return false
 end,
}
sk_qiluan = sgs.CreateTriggerSkillV2{
 name = "sk_qiluan", global = true, events = {sgs.HpChanged, sgs.EventPhaseChanging, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.HpChanged then room:setTag("sk_qiluan_changes", sgs.QVariant(room:getTag("sk_qiluan_changes"):toInt() + 1))
  elseif event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   room:setTag("sk_qiluan_changes", sgs.QVariant(0))
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or player:getPhase() ~= sgs.Player_Finish then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local source = ctx.invoker
  local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
  slash:setSkillName(skill:objectName())
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(source)) do
   if source:canSlash(p, slash, false) then targets:append(p) end
  end
  slash:deleteLater()
  if targets:isEmpty() then return false end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_qiluan", true, true)
  if not target then return false end
  player:setTag("sk_qiluan_target", sgs.QVariant(target))
  return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = player:getTag("sk_qiluan_target"):toPlayer(); player:removeTag("sk_qiluan_target")
  local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.from = ctx.invoker; use.card = slash; use.to:append(target)
  room:useCard(use, false)
  if player:isAlive() then player:drawCards(room:getTag("sk_qiluan_changes"):toInt(), skill:objectName()) end
  return false
 end,
}
sk_hetaihou:addSkill(sk_zhendu)
sk_hetaihou:addSkill(sk_qiluan)
sgs.LoadTranslationTable{
 ["sk_hetaihou"] = "SK何太后", ["&sk_hetaihou"] = "何太后", ["#sk_hetaihou"] = "何太后",
 ["sk_zhendu"] = "鸩毒", [":sk_zhendu"] = "一名角色的出牌阶段开始时，你可以令其本回合对其他角色造成的伤害+1；然后若该角色不是你，你令其失去1点体力。",
 ["sk_qiluan"] = "戚乱", [":sk_qiluan"] = "一名角色的结束阶段，你可以令其视为对你选择的另一名角色使用一张无视距离的【杀】，此牌结算后，你摸X张牌（X为本回合所有角色体力值变化的次数）。",
 ["@sk_qiluan"] = "戚乱：选择【杀】的目标",
}

-- 极略47：卑弥呼（jilue.md L2496-L2498）
sk_beimihu = sgs.General(extension, "sk_beimihu", "qun", 3, false)
sk_canshi = sgs.CreateTriggerSkillV2{
 name = "sk_canshi", global = true,
 events = {sgs.HpRecover, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.Damage},
 can_trigger = function(skill, event, room, player, data)
  local target = player
  if event == sgs.MaxHpChanged and data:toMaxHp().change <= 0 then return false end
  if event == sgs.HpRecover and data:toRecover().recover <= 0 then return false end
  local damage
  if event == sgs.Damage then damage = data:toDamage(); target = damage.from end
  if not target or not target:isAlive() then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if target ~= p and (not damage or damage.to == p) then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  if event == sgs.Damage then target = ctx.original_data:toDamage().from end
  return room:askForSkillInvoke(player, skill:objectName(), sgs.QVariant(target))
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.invoker
  if event == sgs.Damage then target = ctx.original_data:toDamage().from end
  room:addPlayerMark(target, "&sk_canshi")
  player:drawCards(2, skill:objectName())
  return false
 end,
}
sk_canshiMax = sgs.CreateMaxCardsSkillV2{
 name = "#sk_canshi", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p then return -p:getMark("&sk_canshi") end
  return false
 end,
}
sk_xianji = sgs.CreateTriggerSkillV2{
 name = "sk_xianji", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_Start then return false end
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do
   if p:getMark("sk_xianji_forbidden") == 0 and p:getMark("&sk_canshi") > p:getMaxHp() then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do
   if p:getMark("sk_xianji_forbidden") == 0 and p:getMark("&sk_canshi") > p:getMaxHp() then targets:append(p) end
  end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_xianji", true, true)
  if not target then return false end
  player:setTag("sk_xianji_target", sgs.QVariant(target)); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = player:getTag("sk_xianji_target"):toPlayer(); player:removeTag("sk_xianji_target")
  room:setPlayerMark(target, "&sk_canshi", 0)
  local own, other = {}, {}
  for _, s in sgs.qlist(player:getSkillList(false, false)) do table.insert(own, s:objectName()) end
  for _, s in sgs.qlist(target:getSkillList(false, false)) do table.insert(other, s:objectName()) end
  local x = #other
  if x > 0 then
   room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + x))
   local recover = sgs.RecoverStruct(); recover.who = player; recover.recover = x; room:recover(player, recover)
  end
  room:setPlayerMark(player, "sk_xianji_forbidden", 1)
  -- Detach both snapshots before acquiring, including skills common to both players.
  local detachOwn, detachOther = {}, {}
  for _, name in ipairs(own) do table.insert(detachOwn, "-" .. name) end
  for _, name in ipairs(other) do table.insert(detachOther, "-" .. name) end
  if #detachOwn > 0 then room:handleAcquireDetachSkills(player, table.concat(detachOwn, "|")) end
  if #detachOther > 0 then room:handleAcquireDetachSkills(target, table.concat(detachOther, "|")) end
  if #other > 0 then room:handleAcquireDetachSkills(player, table.concat(other, "|")) end
  if #own > 0 then room:handleAcquireDetachSkills(target, table.concat(own, "|")) end
  return false
 end,
}
sk_beimihu:addSkill(sk_canshi)
sk_beimihu:addSkill(sk_canshiMax)
sk_beimihu:addSkill(sk_xianji)
extension:insertRelatedSkills("sk_canshi", "#sk_canshi")
sgs.LoadTranslationTable{
 ["sk_beimihu"] = "SK卑弥呼", ["&sk_beimihu"] = "卑弥呼", ["#sk_beimihu"] = "卑弥呼",
 ["sk_canshi"] = "蚕食", [":sk_canshi"] = "当一名其他角色回复体力、加体力上限、获得技能或对你造成伤害后，你可以令其获得一个“蚕食”标记，然后你摸两张牌。有此标记的角色手牌上限-X（X为其“蚕食”标记数）。",
 ["sk_xianji"] = "献祭", [":sk_xianji"] = "准备阶段，你可以令一名“蚕食”标记数大于体力上限的其他角色移去其所有“蚕食”标记，然后你加X点体力上限并回复等量体力（X为其技能数）；若如此做，你与其交换所有技能且本局游戏内，你不能成为“献祭”的目标。",
 ["@sk_xianji"] = "献祭：选择交换技能的角色",
}

-- 极略47：邢道荣（jilue.md L2508-L2510）
sk_xingdaorong = sgs.General(extension, "sk_xingdaorong", "qun", 5)
sk_xuxie = sgs.CreateTriggerSkillV2{
 name = "sk_xuxie", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.TargetSpecified, sgs.TargetConfirmed, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_xuxie_draw", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseChanging or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local use = data:toCardUse()
  if not use.card or not use.from then return false end
  if event == sgs.TargetSpecified and use.from == player and not player:isWounded() then return skill:objectName() end
  if event == sgs.TargetConfirmed and use.from ~= player and use.to:contains(player) and player:isWounded() then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local use = ctx.original_data:toCardUse()
  local list = use.no_respond_list
  if event == sgs.TargetSpecified then
   for _, p in sgs.qlist(room:getOtherPlayers(player)) do
    if not table.contains(list, p:objectName()) then table.insert(list, p:objectName()) end
   end
  elseif not table.contains(list, player:objectName()) then table.insert(list, player:objectName()) end
  use.no_respond_list = list; ctx.original_data:setValue(use)
  room:sendCompulsoryTriggerLog(player, skill:objectName())
  if player:getMark("sk_xuxie_draw") == 0 and room:askForSkillInvoke(player, "sk_xuxie_draw", ctx.original_data) then
   room:setPlayerMark(player, "sk_xuxie_draw", 1)
   player:drawCards(use.to:length(), skill:objectName())
  end
  return false
 end,
}
sk_xingdaorong:addSkill(sk_xuxie)
sgs.LoadTranslationTable{
 ["sk_xingdaorong"] = "SK邢道荣", ["&sk_xingdaorong"] = "邢道荣", ["#sk_xingdaorong"] = "邢道荣",
 ["sk_xuxie"] = "虚猲", [":sk_xuxie"] = "锁定技，若你未受伤，其他角色不能响应你使用的牌。若你已受伤，你不能响应其他角色对你使用的牌。每回合限一次，当你触发此技能后，你可以摸X张牌（X为此牌的目标数）。",
 ["sk_xuxie_draw"] = "虚猲：摸牌",
}

-- 极略49：沙摩柯（jilue.md L2522-L2523）
sk_shamoke = sgs.General(extension, "sk_shamoke", "shu", 4)
sk_jili = sgs.CreateTriggerSkillV2{
 name = "sk_jili", global = true,
 events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished, sgs.PostCardResponded, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_jili_uses", 0) end
  elseif event == sgs.CardUsed then
   room:addPlayerMark(player, "sk_jili_uses")
  elseif event == sgs.CardResponded and ctx.original_data:toCardResponse().m_isUse then
   room:addPlayerMark(player, "sk_jili_uses")
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardFinished and event ~= sgs.PostCardResponded then return false end
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  -- Use-responses finish through CardFinished; pure responses finish here.
  if event == sgs.PostCardResponded and data:toCardResponse().m_isUse then return false end
  local c = event == sgs.CardFinished and data:toCardUse().card or data:toCardResponse().m_card
  if c and not c:isKindOf("TrickCard") then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do
   if player:inMyAttackRange(p) then targets:append(p) end
  end
  local n = 0
  for _, p in sgs.qlist(targets) do
   local cards = sgs.QList2Table(p:getCards("he"))
   if p:isAlive() and #cards > 0 then
    room:throwCard(cards[math.random(#cards)], p, player); n = n + 1
   end
  end
  if player:isAlive() and player:getMark("sk_jili_uses") <= player:getAttackRange() and n > 0 then player:drawCards(n, skill:objectName()) end
  return false
 end,
}
sk_shamoke:addSkill(sk_jili)
sgs.LoadTranslationTable{
 ["sk_shamoke"] = "SK沙摩柯", ["&sk_shamoke"] = "沙摩柯", ["#sk_shamoke"] = "沙摩柯",
 ["sk_jili"] = "蒺藜", [":sk_jili"] = "当你使用或打出的一张非锦囊牌结算后，你可以令攻击范围内所有其他角色各随机弃置一张牌；然后若你本回合使用的牌数不大于你的攻击范围，则你摸与弃牌数等量的牌。",
}

-- 极略49：马云騄（jilue.md L2525、L2527）
sk_mayunlu = sgs.General(extension, "sk_mayunlu", "shu", 4, false)
sk_fengyin = sgs.CreateTriggerSkillV2{
 name = "sk_fengyin", global = true, events = {sgs.DamageCaused, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    room:setPlayerMark(p, "sk_fengyin_slash", 0); room:setPlayerMark(p, "sk_fengyin_duel", 0)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.DamageCaused then return false end
  local d = data:toDamage()
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or d.from ~= player or d.to == player or not d.card then return false end
  local name = d.card:isKindOf("Slash") and "slash" or d.card:isKindOf("Duel") and "duel"
  if name and player:getMark("sk_fengyin_" .. name) == 0 then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local d = ctx.original_data:toDamage()
  local name = d.card:isKindOf("Slash") and "slash" or "duel"
  room:setPlayerMark(player, "sk_fengyin_" .. name, 1)
  local red = player:hasSkill("sk_rongzhuang") and player:getWeapon() and player:getArmor()
  local x, y = 0, 0
  for _, c in sgs.qlist(player:getHandcards()) do
   if (red and c:isRed()) or (not red and c:getSuit() == sgs.Card_Diamond) then x = x + 1 end
  end
  for _, c in sgs.qlist(d.to:getHandcards()) do
   if (red and c:isRed()) or (not red and c:getSuit() == sgs.Card_Diamond) then y = y + 1 end
  end
  if x > 0 then player:drawCards(x, skill:objectName()) end
  d.damage = d.damage + y; ctx.original_data:setValue(d)
  return false
 end,
}
sk_rongzhuang = sgs.CreateTriggerSkillV2{
 name = "sk_rongzhuang", frequency = sgs.Skill_Compulsory, events = {sgs.TargetSpecified},
 can_trigger = function(skill, event, room, player, data)
  local use = data:toCardUse()
  if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getArmor() and use.from == player and use.card and use.card:isKindOf("Slash") then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local use = ctx.original_data:toCardUse(); local list = use.no_respond_list
  if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
  use.no_respond_list = list; ctx.original_data:setValue(use)
  room:sendCompulsoryTriggerLog(player, skill:objectName())
  return false
 end,
}
sk_rongzhuangMod = sgs.CreateTargetModSkillV2{
 name = "#sk_rongzhuang", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and p:hasSkill("sk_rongzhuang") and p:getWeapon() and ctx:getModType() == sgs.TargetModSkill_Residue then return 9999 end
  return false
 end,
}
sk_changqu = sgs.CreateDistanceSkillV2{
 name = "sk_changqu", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and p:hasSkill(skill:objectName()) then return -1 end
  return false
 end,
}
sk_mayunlu:addSkill(sk_fengyin)
sk_mayunlu:addSkill(sk_rongzhuang)
sk_mayunlu:addSkill(sk_rongzhuangMod)
sk_mayunlu:addSkill(sk_changqu)
extension:insertRelatedSkills("sk_rongzhuang", "#sk_rongzhuang")
sgs.LoadTranslationTable{
 ["sk_mayunlu"] = "SK马云騄", ["&sk_mayunlu"] = "马云騄", ["#sk_mayunlu"] = "马云騄",
 ["sk_fengyin"] = "凤吟", [":sk_fengyin"] = "每回合各限一次，当你使用【杀】或【决斗】对其他角色造成伤害时，你可以摸X张牌并令此伤害+Y（X为你手牌中的方块牌数，Y为该角色手牌中的方块牌数）。",
 ["sk_rongzhuang"] = "戎妆", [":sk_rongzhuang"] = "锁定技，若你的装备区有：武器牌，你使用【杀】无次数限制；防具牌，你使用的【杀】不能被响应。若以上均有，则“凤吟”中的“方块牌”修改为“红色牌”。",
 ["sk_changqu"] = "长驱", [":sk_changqu"] = "锁定技，你计算与其他角色的距离-1。",
}

-- 极略49：黄皓（jilue.md L2527-L2529）
sk_huanghao = sgs.General(extension, "sk_huanghao", "shu", 3)
sk_qinqing = sgs.CreateTriggerSkillV2{
 name = "sk_qinqing", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_qinqing", true, true)
  if not target then return false end
  player:setTag("sk_qinqing_target", sgs.QVariant(target)); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = player:getTag("sk_qinqing_target"):toPlayer(); player:removeTag("sk_qinqing_target")
  local givers = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getAlivePlayers()) do
   if p:inMyAttackRange(target) then givers:append(p) end
  end
  for _, p in sgs.qlist(givers) do
   if target:isAlive() and p:isAlive() and not p:isNude() then
    local c = room:askForExchange(p, skill:objectName(), 1, 1, true, "@sk_qinqing-give:" .. target:objectName(), false)
    if c then room:obtainCard(target, c, false); c:deleteLater() end
   end
  end
  if target:isAlive() and target:getHandcardNum() <= player:getHandcardNum() and room:askForSkillInvoke(player, "sk_qinqing_recover", sgs.QVariant(target)) then
   local recover = sgs.RecoverStruct(); recover.who = player; room:recover(target, recover)
  end
  return false
 end,
}
sk_huisheng = sgs.CreateTriggerSkillV2{
 name = "sk_huisheng", events = {sgs.DamageInflicted},
 can_trigger = function(skill, event, room, player, data)
  local d = data:toDamage()
  if player and player:isAlive() and player:hasSkill(skill:objectName()) and not player:isKongcheng() and d.from and d.from ~= player then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local c = room:askForExchange(player, skill:objectName(), 3, 1, false, "@sk_huisheng-show", true)
  if not c then return false end
  player:setTag("sk_huisheng_cards", sgs.QVariant(c:getSubcards())); c:deleteLater(); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local ids = player:getTag("sk_huisheng_cards"):toIntList(); player:removeTag("sk_huisheng_cards")
  local source = ctx.original_data:toDamage().from
  for _, id in sgs.qlist(ids) do room:showCard(player, id) end
  local choice = room:askForChoice(source, skill:objectName(), "obtain+discard", sgs.QVariant(player))
  if choice == "obtain" then
   room:fillAG(ids, source)
   local id = room:askForAG(source, ids, false, skill:objectName()); room:clearAG(source)
   room:obtainCard(source, id, false)
   return true
  end
  room:askForDiscard(source, skill:objectName(), ids:length(), ids:length(), false, true)
  return false
 end,
}
sk_huanghao:addSkill(sk_qinqing)
sk_huanghao:addSkill(sk_huisheng)
sgs.LoadTranslationTable{
 ["sk_huanghao"] = "SK黄皓", ["&sk_huanghao"] = "黄皓", ["#sk_huanghao"] = "黄皓",
 ["sk_qinqing"] = "寝情", [":sk_qinqing"] = "结束阶段，你可以选择一名角色，并令所有攻击范围内有其的角色各交给其一张牌；然后若其手牌数不大于你，你可以令其回复1点体力。",
 ["sk_huisheng"] = "贿生", [":sk_huisheng"] = "当你受到其他角色造成的伤害时，你可以展示一至三张手牌并令其选择一项：1.获得其中一张牌并防止此伤害；2.弃置等量的牌。",
 ["@sk_qinqing"] = "寝情：选择一名角色", ["@sk_qinqing-give"] = "寝情：交给 %src 一张牌",
 ["sk_qinqing_recover"] = "寝情：回复体力", ["@sk_huisheng-show"] = "贿生：展示一至三张手牌",
}

-- 极略50：兀突骨（jilue.md L2540；极略版 6/6）
sk_wutugu = sgs.General(extension, "sk_wutugu", "qun", 6)
sk_hanyong = sgs.CreateTriggerSkillV2{
 name = "sk_hanyong", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.GameReady, sgs.GameStart, sgs.CardsMoveOneTime, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  -- Use the engine's virtual equipment property, so native Axe/Vine rules
  -- (including range, equipment nullification and Qinggang) remain authoritative.
  for _, p in sgs.qlist(room:getAllPlayers(true)) do
   local equips = p:property("View_As_Equips_List"):toString():split("+")
   local owned = p:getTag("sk_hanyong_equips"):toString():split("+")
   for _, name in ipairs(owned) do table.removeOne(equips, name) end
   local added = {}
   if p:hasSkill(skill:objectName()) then
    for _, name in ipairs({"axe", "vine"}) do
     local empty = name == "axe" and not p:getWeapon() or name == "vine" and not p:getArmor()
     if empty and not table.contains(equips, name) then table.insert(equips, name); table.insert(added, name) end
    end
   end
   if table.contains(equips, "axe") and not p:hasSkill("axe") then
    room:attachSkillToPlayer(p, "axe"); p:setTag("sk_hanyong_axe_attached", sgs.QVariant(true))
   elseif not table.contains(equips, "axe") and p:getTag("sk_hanyong_axe_attached"):toBool() then
    p:removeTag("sk_hanyong_axe_attached")
    if not p:getWeapon() or p:getWeapon():objectName() ~= "axe" then room:detachSkillFromPlayer(p, "axe", true) end
   end
   p:setTag("sk_hanyong_equips", sgs.QVariant(table.concat(added, "+")))
   local value = table.concat(equips, "+")
   if value ~= p:property("View_As_Equips_List"):toString() then room:setPlayerProperty(p, "View_As_Equips_List", sgs.QVariant(value)) end
  end
 end,
}
sk_wutugu:addSkill(sk_hanyong)
sgs.LoadTranslationTable{
 ["sk_wutugu"] = "SK兀突骨", ["&sk_wutugu"] = "兀突骨", ["#sk_wutugu"] = "兀突骨",
 ["sk_hanyong"] = "悍勇", [":sk_hanyong"] = "锁定技，若你装备区内没有武器牌/防具牌，你视为装备着【贯石斧】/【藤甲】。",
}

-- 极略50：王元姬（jilue.md L2552、L2554；群 3/3）
sk_wangyuanji = sgs.General(extension, "sk_wangyuanji", "qun", 3, false)
sk_qianchong = sgs.CreateTriggerSkillV2{
 name = "sk_qianchong", global = true,
 events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_RoundStart then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    room:setPlayerMark(p, "sk_qianchong_black", 0); room:setPlayerMark(p, "sk_qianchong_red", 0)
   end
  elseif player and (event == sgs.PreCardUsed or event == sgs.CardResponded) then
   local card, hand
   if event == sgs.PreCardUsed then
    local use = ctx.original_data:toCardUse(); card = use.card; hand = use.m_isHandcard
   else
    local response = ctx.original_data:toCardResponse()
    if not response.m_isUse then return end
    card = response.m_card; hand = response.m_isHandcard
   end
   if hand and card then
    if card:isBlack() then room:addPlayerMark(player, "sk_qianchong_black")
    elseif card:isRed() then room:addPlayerMark(player, "sk_qianchong_red") end
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseChanging or not player or data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and (p:getMark("sk_qianchong_black") == 1 or p:getMark("sk_qianchong_red") == 1) then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local own_extra = room:isCurrentExtraTurn() and room:getCurrent() == owner
  local eligible = {owner:getMark("sk_qianchong_black") == 1, owner:getMark("sk_qianchong_red") == 1}
  local done = 0
  for i, color in ipairs({"black", "red"}) do
   if owner:isAlive() and eligible[i] then
    local target = room:askForPlayerChosen(owner, room:getAlivePlayers(), skill:objectName(), "@sk_qianchong-" .. color, true, true)
    if target then
     local choice = room:askForChoice(owner, skill:objectName(), color == "black" and "losehp+discard" or "recover+draw", sgs.QVariant(target))
     done = done + 1
     if choice == "losehp" then room:loseHp(target, 2)
     elseif choice == "recover" then local r = sgs.RecoverStruct(); r.who = owner; r.recover = 2; room:recover(target, r)
     elseif choice == "discard" then room:askForDiscard(target, skill:objectName(), math.max(0, target:getMaxHp()), math.max(0, target:getMaxHp()), false, true)
     elseif target:getMaxHp() > 0 then target:drawCards(target:getMaxHp(), skill:objectName()) end
    end
   end
  end
  if done == 2 and owner:isAlive() and not own_extra then room:scheduleExtraTurn(owner, skill:objectName()) end
  return false
 end,
}
sk_shangjian = sgs.CreateTriggerSkillV2{
 name = "sk_shangjian", frequency = sgs.Skill_Compulsory,
 events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_Discard then return false end
  if event == sgs.EventPhaseStart or player:getMark("sk_shangjian_given") > 0 then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseEnd then
   local n = player:getMark("sk_shangjian_given"); room:setPlayerMark(player, "sk_shangjian_given", 0)
   player:drawCards(n, skill:objectName()); return false
  end
  room:setPlayerMark(player, "sk_shangjian_given", 0)
  local n = math.min(player:getHandcardNum(), math.max(0, player:getHandcardNum() - player:getMaxCards()))
  if n <= 0 or room:getOtherPlayers(player):isEmpty() then return false end
  room:sendCompulsoryTriggerLog(player, skill:objectName())
  local cards = room:askForExchange(player, skill:objectName(), n, n, false, "@sk_shangjian", false)
  if not cards then return false end
  local ids = cards:getSubcards(); cards:deleteLater()
  local recipients = room:getOtherPlayers(player)
  while player:isAlive() and not ids:isEmpty() and not recipients:isEmpty() do
   local before = ids:length()
   room:askForYiji(player, ids, skill:objectName(), false, false, false, -1, recipients)
   local left = sgs.IntList()
   for _, id in sgs.qlist(ids) do
    if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then left:append(id) end
   end
   local given = before - left:length()
   if given == 0 then
    -- Mandatory distribution: resolve cancellation without losing the cards.
    local target = room:askForPlayerChosen(player, recipients, skill:objectName())
    room:obtainCard(target, left:first(), false); left:removeOne(left:first()); given = 1
   end
   room:addPlayerMark(player, "sk_shangjian_given", given)
   ids = left; recipients = room:getOtherPlayers(player)
  end
  return false
 end,
}
sk_wangyuanji:addSkill(sk_qianchong)
sk_wangyuanji:addSkill(sk_shangjian)
sgs.LoadTranslationTable{
 ["sk_wangyuanji"] = "SK王元姬", ["&sk_wangyuanji"] = "王元姬", ["#sk_wangyuanji"] = "王元姬",
 ["sk_qianchong"] = "谦冲", [":sk_qianchong"] = "一名角色的回合结束时，若你于此回合内仅使用了一张黑色/红色手牌，你可以令一名角色失去/回复2点体力或弃置/摸X张牌（X为其体力上限）。若你本回合这些了两项且本回合不为你的额外回合，你于本回合结束后进行一个额外的回合。",
 ["sk_shangjian"] = "尚俭", [":sk_shangjian"] = "锁定技，弃牌阶段开始时，你将超过手牌上限的手牌任意分配给其他角色，然后你于此阶段结束时摸等量的牌。",
 ["@sk_qianchong-black"] = "谦冲", ["@sk_qianchong-red"] = "谦冲", ["@sk_shangjian"] = "尚俭",
}

-- 极略52 SP庞统：jilue.md L2583-L2587
sk_sp_pangtong = sgs.General(extension, "sk_sp_pangtong", "shu", 3, true)
local function sk_guolun_event(event, data)
 if event == sgs.CardsMoveOneTime then
  local m = data:toMoveOneTime()
  local reason = bit32.band(m.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
  if reason == sgs.CardMoveReason_S_REASON_DRAW and m.to and m.to_place == sgs.Player_PlaceHand then return m.to, "draw", m.card_ids:length() end
  if reason == sgs.CardMoveReason_S_REASON_DISCARD and m.from and m.to_place == sgs.Player_DiscardPile then return m.from, "discard", m.card_ids:length() end
 elseif event == sgs.Damage then local d = data:toDamage(); return d.from, "damage", d.damage
 elseif event == sgs.HpRecover then local r = data:toRecover(); return r.who, "recover", r.recover end
end
sk_guolun = sgs.CreateTriggerSkillV2{
 name = "sk_guolun", global = true,
 events = {sgs.CardsMoveOneTime, sgs.Damage, sgs.HpRecover, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    room:setPlayerMark(p, "sk_guolun_opposite", 0); room:setPlayerMark(p, "sk_guolun_same", 0)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseChanging then return false end
  local actor, action, n = sk_guolun_event(event, data)
  -- Recovery belongs to the character recovering, not the recovery provider.
  if event == sgs.HpRecover then actor = player end
  if not actor or not n or n <= 0 then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   local level = p:getMark("sk_songsang") + 1
   local basic = action == "draw" or action == "discard"
   local opposite = p:getMark("sk_guolun_opposite") == 0 and (actor:objectName() == p:objectName() or level >= 3) and (basic or level == 4)
   local same = level >= 2 and p:getMark("sk_guolun_same") == 0 and (actor:objectName() == p:objectName() or level == 3) and (basic or level == 4)
   if p:isAlive() and (opposite or same) then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local actor, action, n = sk_guolun_event(event, ctx.original_data)
  if event == sgs.HpRecover then actor = player end
  if not actor then return false end
  local level = owner:getMark("sk_songsang") + 1
  local basic = action == "draw" or action == "discard"
  local eligibility = {
   (actor:objectName() == owner:objectName() or level >= 3) and (basic or level == 4),
   level >= 2 and (actor:objectName() == owner:objectName() or level == 3) and (basic or level == 4),
  }
  local inverse = {draw = "discard", discard = "draw", damage = "recover", recover = "damage"}
  for i, mode in ipairs({"opposite", "same"}) do
   local mark = "sk_guolun_" .. mode
   if owner:isAlive() and eligibility[i] and owner:getMark(mark) == 0 then
    local effect = i == 1 and inverse[action] or action
    local targets = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do if p:objectName() ~= owner:objectName() then targets:append(p) end end
    local target = room:askForPlayerChosen(owner, targets, skill:objectName(), "@sk_guolun-" .. effect, true, true)
    if target then
     room:setPlayerMark(owner, mark, 1)
     if effect == "draw" then target:drawCards(n, skill:objectName())
     elseif effect == "discard" then room:askForDiscard(target, skill:objectName(), n, n, false, true)
     elseif effect == "recover" then local r = sgs.RecoverStruct(); r.who = owner; r.recover = n; room:recover(target, r)
     else local d = sgs.DamageStruct(); d.from = owner; d.to = target; d.damage = n; d.reason = skill:objectName(); room:damage(d) end
    end
   end
  end
  return false
 end,
}
sk_songsang = sgs.CreateTriggerSkillV2{
 name = "sk_songsang", frequency = sgs.Skill_Compulsory, global = true, events = {sgs.Death},
 can_trigger = function(skill, event, room, player, data)
  local dead = data:toDeath().who; local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and p ~= dead then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  room:sendCompulsoryTriggerLog(owner, skill:objectName())
  if owner:getMark("sk_songsang") < 3 then room:addPlayerMark(owner, "sk_songsang") end
  owner:drawCards(room:getAlivePlayers():length(), skill:objectName()); return false
 end,
}
sk_sp_pangtong:addSkill(sk_guolun)
sk_sp_pangtong:addSkill(sk_songsang)
sgs.LoadTranslationTable{
 ["sk_sp_pangtong"] = "SKSP庞统", ["&sk_sp_pangtong"] = "SP庞统", ["#sk_sp_pangtong"] = "SP庞统",
 ["sk_guolun"] = "过论", [":sk_guolun"] = "每回合限一次，当你摸牌或弃牌后，你可以令一名其他角色执行相反的效果。",
 [":sk_guolun1"] = "每回合限一次，当你摸牌或弃牌后，你可以令一名其他角色执行相反的效果。每回合限一次，当你摸牌或弃牌后，你可以令一名其他角色执行相同的效果。",
 [":sk_guolun2"] = "每回合限一次，当一名角色摸牌或弃牌后，你可以令一名其他角色执行相反的效果。每回合限一次，当一名角色摸牌或弃牌后，你可以令一名其他角色执行相同的效果。",
 [":sk_guolun3"] = "每回合限一次，当一名角色摸牌或弃牌后、造成伤害或回复体力后，你可以令一名其他角色执行相反的效果。每回合限一次，当你摸牌或弃牌后、造成伤害或回复体力后，你可以令一名其他角色执行相同的效果。",
 ["sk_songsang"] = "送丧", [":sk_songsang"] = "锁定技，当其他角色死亡时，你升级“过论”（至多三次）并摸X张牌（X为存活角色数）。",
 ["@sk_guolun-draw"] = "过论", ["@sk_guolun-discard"] = "过论", ["@sk_guolun-damage"] = "过论", ["@sk_guolun-recover"] = "过论",
}

-- 极略52 吕岱：jilue.md L2599-L2603
sk_lvdai = sgs.General(extension, "sk_lvdai", "wu", 4, true)
sk_qinguoVS = sgs.CreateViewAsSkillV2{
 name = "sk_qinguo", n = 0,
 can_activate = function(skill, request) return request:getPattern() == "@@sk_qinguo" end,
 create_card = function(skill, request)
  local card = sgs.Sanguosha:cloneCard(request:getInitiator():getTag("sk_qinguo_card"):toString(), sgs.Card_NoSuit, 0)
  if card then card:setSkillName("sk_qinguo") end
  return card
 end,
}
sk_qinguoMod = sgs.CreateTargetModSkillV2{
 name = "#sk_qinguo", pattern = "BasicCard", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  if ctx:getModType() == sgs.TargetModSkill_Residue and ctx:getCard() and ctx:getCard():getSkillName() == "sk_qinguo" then return 9999 end
  return false
 end,
}
local function sk_qinguo_equips(room, move)
 local ids = sgs.IntList()
 if move.from and move.to_place == sgs.Player_DiscardPile then
  for i, id in sgs.qlist(move.card_ids) do
   if move.from_places:at(i) == sgs.Player_PlaceEquip and room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
  end
 end
 return ids
end
sk_qinguo = sgs.CreateTriggerSkillV2{
 name = "sk_qinguo", global = true, view_as_skill = sk_qinguoVS,
 events = {sgs.PreCardUsed, sgs.CardFinished, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_qinguo_obtain", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.EventPhaseChanging then return false end
  if event == sgs.CardsMoveOneTime then
   if sk_qinguo_equips(room, data:toMoveOneTime()):isEmpty() then return false end
   local names, owners = {}, {}
   for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
    if p:isAlive() and p:getMark("sk_qinguo_obtain") == 0 then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
   end
   if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  elseif player and player:isAlive() and player:hasSkill(skill:objectName()) then
   local use = data:toCardUse()
   if use.card and use.card:isKindOf("EquipCard") and (event == sgs.CardFinished or player:getPhase() == sgs.Player_Play) then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  if event ~= sgs.CardsMoveOneTime then return true end
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if event == sgs.PreCardUsed then
   local use = ctx.original_data:toCardUse()
   local target = room:askForPlayerChosen(owner, room:getAlivePlayers(), skill:objectName(), "@sk_qinguo-equip", true, true)
   if target then use.to = sgs.SPlayerList(); use.to:append(target); ctx.original_data:setValue(use) end
  elseif event == sgs.CardsMoveOneTime then
   local ids = sk_qinguo_equips(room, ctx.original_data:toMoveOneTime())
   if not ids:isEmpty() then
    room:setPlayerMark(owner, "sk_qinguo_obtain", 1)
    local dummy = sgs.DummyCard(ids); room:obtainCard(owner, dummy, true); dummy:deleteLater()
   end
  else
   local choices, seen = {}, {}
   local id = 0
   while true do
    local prototype = sgs.Sanguosha:getEngineCard(id)
    if not prototype then break end
    local name = prototype:objectName()
    if prototype:isKindOf("BasicCard") and not seen[name] then
     seen[name] = true
     local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); card:setSkillName("sk_qinguo")
     if card:isAvailable(owner) then table.insert(choices, name) end
     card:deleteLater()
    end
    id = id + 1
   end
   if #choices > 0 then
    table.insert(choices, "cancel")
    local name = room:askForChoice(owner, skill:objectName(), table.concat(choices, "+"))
    if name ~= "cancel" then
     owner:setTag("sk_qinguo_card", sgs.QVariant(name))
     room:askForUseCard(owner, "@@sk_qinguo", "@sk_qinguo-basic", -1, sgs.Card_MethodUse, false)
     owner:removeTag("sk_qinguo_card")
    end
   end
  end
  return false
 end,
}
sk_lvdai:addSkill(sk_qinguo)
sk_lvdai:addSkill(sk_qinguoMod)
extension:insertRelatedSkills("sk_qinguo", "#sk_qinguo")
sgs.LoadTranslationTable{
 ["sk_lvdai"] = "SK吕岱", ["&sk_lvdai"] = "吕岱", ["#sk_lvdai"] = "吕岱",
 ["sk_qinguo"] = "勤国", [":sk_qinguo"] = "出牌阶段，你可以对任意角色使用装备牌。当你使用装备牌后，你可以视为使用一张无次数限制的任意基本牌。每回合限一次，当一名角色的装备区内的牌进入弃牌堆时，你可以获得之。",
 ["@sk_qinguo-equip"] = "勤国", ["@sk_qinguo-basic"] = "勤国",
}

-- 极略52 周夷：jilue.md L2609-L2611
sk_zhouyi = sgs.General(extension, "sk_zhouyi", "wu", 4, false)
sk_zhukou = sgs.CreateTriggerSkillV2{
 name = "sk_zhukou", global = true,
 events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.PreCardUsed, sgs.CardResponded},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_Play then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    for i = 1, 3 do room:setPlayerMark(p, "sk_zhukou_type" .. i, 0) end
   end
  elseif (event == sgs.PreCardUsed or event == sgs.CardResponded) and player then
   local current = room:getCurrent()
   if not current or current:getPhase() ~= sgs.Player_Play then return end
   local card
   if event == sgs.PreCardUsed then card = ctx.original_data:toCardUse().card
   else local r = ctx.original_data:toCardResponse(); if r.m_isUse then card = r.m_card end end
   if card and card:getTypeId() >= 1 and card:getTypeId() <= 3 then room:setPlayerMark(player, "sk_zhukou_type" .. card:getTypeId(), 1) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseEnd or not player or player:getPhase() ~= sgs.Player_Play then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   local n = 0; for i = 1, 3 do n = n + p:getMark("sk_zhukou_type" .. i) end
   if p:isAlive() and n > 0 then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local n = 0; for i = 1, 3 do n = n + owner:getMark("sk_zhukou_type" .. i) end
  local target = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), skill:objectName(), "@sk_zhukou", true, true)
  if not target then return false end
  local times = 1
  while times < n do
   if room:askForChoice(owner, skill:objectName(), "repeat+done", sgs.QVariant(target)) ~= "repeat" then break end
   times = times + 1
  end
  for i = 1, times do
   if target:isAlive() then
    local d = sgs.DamageStruct(); d.from = owner; d.to = target; d.damage = 1; d.reason = skill:objectName(); room:damage(d)
   end
  end
  return false
 end,
}
sk_duannianVS = sgs.CreateViewAsSkillV2{
 name = "sk_duannian", n = 1,
 can_activate = function(skill, request) return request:getPattern() == "@@sk_duannian" end,
 can_select_card = function(skill, request, card)
  return not card:isEquipped() and request:getSelectedCardIds():isEmpty()
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local original = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
  local card = sgs.Sanguosha:cloneCard(original:objectName(), original:getSuit(), original:getNumber())
  card:addSubcards(request:getSelectedCardIds()); card:setSkillName("sk_duannian"); return card
 end,
}
sk_duannianMod = sgs.CreateTargetModSkillV2{
 name = "#sk_duannian", pattern = ".", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  if ctx:getCard() and ctx:getCard():getSkillName() == "sk_duannian" and ctx:getModType() == sgs.TargetModSkill_Residue then return 9999 end
  return false
 end,
}
sk_duannian = sgs.CreateTriggerSkillV2{
 name = "sk_duannian", global = true, view_as_skill = sk_duannianVS, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or player:getPhase() ~= sgs.Player_Play then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local before = owner:getHandcardNum(); owner:throwAllHandCards(skill:objectName())
  local n = before - owner:getHandcardNum()
  if owner:isAlive() and n > 0 then owner:drawCards(n, skill:objectName()) end
  if not owner:isAlive() then return false end
  local choice = room:askForChoice(owner, skill:objectName(), "use+recover")
  if choice == "recover" then local r = sgs.RecoverStruct(); r.who = owner; room:recover(owner, r)
  else
   room:askForUseCard(owner, "@@sk_duannian", "@sk_duannian-use", -1, sgs.Card_MethodUse, false)
  end
  return false
 end,
}
sk_zhouyi:addSkill(sk_zhukou)
sk_zhouyi:addSkill(sk_duannian)
sk_zhouyi:addSkill(sk_duannianMod)
extension:insertRelatedSkills("sk_duannian", "#sk_duannian")
sgs.LoadTranslationTable{
 ["sk_zhouyi"] = "SK周夷", ["&sk_zhouyi"] = "周夷", ["#sk_zhouyi"] = "周夷",
 ["sk_zhukou"] = "逐寇", [":sk_zhukou"] = "一名角色的出牌阶段结束时，你可以选择一名其他角色至多X次（X为你此阶段使用过的牌的类别数），然后你对这些角色依次造成1点伤害。",
 ["sk_duannian"] = "断念", [":sk_duannian"] = "一名角色的出牌阶段开始时，你可以弃置所有手牌并摸等量的牌，然后你选择一项：1.使用一张手牌（无次数限制）；2.回复1点体力。",
 ["@sk_zhukou"] = "逐寇", ["@sk_duannian-use"] = "断念", ["repeat"] = "选择", ["done"] = "结束",
}

-- 极略53：张昌蒲（jilue.md L2617-L2618）
sk_zhangchangpu = sgs.General(extension, "sk_zhangchangpu", "wei", 3, false)
local function sk_yanjiao_valid(player, ids)
 local n = ids:length()
 if n < 1 or n > 5 or player:getMark("sk_yanjiao_" .. n) > 0 then return false end
 local cards = {}
 for _, id in sgs.qlist(ids) do
  if not player:handCards():contains(id) then return false end
  table.insert(cards, sgs.Sanguosha:getCard(id))
 end
 table.sort(cards, function(a, b) return a:getNumber() < b:getNumber() end)
 if n == 1 then
  for _, c in sgs.qlist(player:getHandcards()) do if c:getNumber() > cards[1]:getNumber() then return false end end
 elseif n == 2 then return cards[1]:getNumber() == cards[2]:getNumber()
 elseif n == 3 then
  for _, c in ipairs(cards) do if c:getSuit() ~= cards[1]:getSuit() then return false end end
 else
  for i = 2, n do
   if cards[i]:getNumber() ~= cards[i-1]:getNumber() + 1 then return false end
   if n == 5 and cards[i]:getSuit() ~= cards[1]:getSuit() then return false end
  end
 end
 return true
end
sk_yanjiaoCard = sgs.CreateSkillCard{
 name = "sk_yanjiaoCard", will_throw = false, handling_method = sgs.Card_MethodNone,
 filter = function(self, targets, target, source) return #targets == 0 and target ~= source end,
 on_use = function(self, room, source, targets)
  if not sk_yanjiao_valid(source, self:getSubcards()) then return end
  local n = self:subcardsLength(); local target = targets[1]
  room:setPlayerMark(source, "sk_yanjiao_" .. n, 1)
  room:obtainCard(target, self, false)
  source:drawCards(n, "sk_yanjiao")
  if source:getMark("&sk_xingshen") > 0 and source:askForSkillInvoke("sk_yanjiao", sgs.QVariant(target)) then
   local d = sgs.DamageStruct(); d.from = source; d.to = target; d.damage = n; d.reason = "sk_yanjiao"; room:damage(d)
  end
 end,
}
sk_yanjiaoVS = sgs.CreateViewAsSkillV2{
 name = "sk_yanjiao", n = 5,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
 can_select_card = function(skill, request, card) return not card:isEquipped() and request:getSelectedCardIds():length() < 5 end,
 card_selection_feasible = function(skill, request) return sk_yanjiao_valid(request:getInitiator(), request:getSelectedCardIds()) end,
 create_card = function(skill, request) local c = sk_yanjiaoCard:clone(); c:addSubcards(request:getSelectedCardIds()); return c end,
}
sk_yanjiao = sgs.CreateTriggerSkillV2{
 name = "sk_yanjiao", global = true, view_as_skill = sk_yanjiaoVS, events = {sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  local change = ctx.original_data:toPhaseChange()
  if change.from == sgs.Player_Play or change.to == sgs.Player_Play then
   for i = 1, 5 do room:setPlayerMark(player, "sk_yanjiao_" .. i, 0) end
  end
 end,
 can_trigger = function() return false end,
}
sk_xingshen = sgs.CreateTriggerSkillV2{
 name = "sk_xingshen", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.Damaged, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging then
   local change = ctx.original_data:toPhaseChange()
   if change.to == sgs.Player_RoundStart and player:getMark("&sk_xingshen") > 0 then room:setPlayerMark(player, "sk_xingshen_expire", 1) end
   if change.to == sgs.Player_NotActive and player:getMark("sk_xingshen_expire") > 0 then
    room:setPlayerMark(player, "&sk_xingshen", 0); room:setPlayerMark(player, "sk_xingshen_expire", 0)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.Damaged and player and player:isAlive() and player:hasSkill(skill:objectName()) then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  for i = 1, ctx.original_data:toDamage().damage do
   player:drawCards(2, skill:objectName())
   if player:getMark("&sk_xingshen") == 0 then
    local r = sgs.RecoverStruct(); r.who = player; room:recover(player, r)
    room:setPlayerMark(player, "&sk_xingshen", 1)
   end
  end
  return false
 end,
}
sk_zhangchangpu:addSkill(sk_yanjiao)
sk_zhangchangpu:addSkill(sk_xingshen)
sgs.LoadTranslationTable{
 ["sk_zhangchangpu"] = "SK张昌蒲", ["&sk_zhangchangpu"] = "张昌蒲", ["#sk_zhangchangpu"] = "张昌蒲",
 ["sk_yanjiao"] = "严教", [":sk_yanjiao"] = "出牌阶段每项各限一次，你可以将满足以下一项条件的对应张手牌交给一名其他角色，然后你摸等量的牌：1.一张点数最大的手牌；2.两张点数相同的手牌；3.三张花色相同的手牌；4.四张点数连续的手牌；5.五张点数连续且花色相同的手牌。若如此做，然后若你有“省身”标记，你可以对该角色造成等量的伤害。",
 ["sk_xingshen"] = "省身", ["&sk_xingshen"] = "省身", [":sk_xingshen"] = "锁定技，当你受到1点伤害后，你摸两张牌，然后若你没有“省身”标记，你回复1点体力并获得该标记直到你的下一个回合结束。",
}

-- 极略53：郭淮（jilue.md L2624-L2626）
sk_guohuai = sgs.General(extension, "sk_guohuai", "wei", 4)
local function sk_jingce_options(player)
 local n = player:getMark("sk_jingce_cards")
 local options = {}
 if n == 2 + player:getMark("&sk_jingce_draw") then table.insert(options, "draw") end
 local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
 local limit = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash)
 slash:deleteLater()
 if n == limit then table.insert(options, "slash") end
 if n == player:getMaxHp() then table.insert(options, "maxhp") end
 return options
end
sk_jingce = sgs.CreateTriggerSkillV2{
 name = "sk_jingce", global = true,
 events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished, sgs.EventPhaseChanging, sgs.DrawNCards},
 on_record = function(skill, event, room, player, ctx)
  if not player then return end
  if event == sgs.EventPhaseChanging then
   local change = ctx.original_data:toPhaseChange()
   if change.to == sgs.Player_Play or change.from == sgs.Player_Play then
    room:setPlayerMark(player, "sk_jingce_cards", 0); room:setPlayerMark(player, "sk_jingce_used", 0)
   end
  elseif player:getPhase() == sgs.Player_Play and (event == sgs.PreCardUsed or event == sgs.CardResponded) then
   local card
   if event == sgs.PreCardUsed then card = ctx.original_data:toCardUse().card
   else local response = ctx.original_data:toCardResponse(); if response.m_isUse then card = response.m_card end end
   if card and not card:isKindOf("SkillCard") then room:addPlayerMark(player, "sk_jingce_cards") end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.DrawNCards and player:getMark("&sk_jingce_draw") > 0 then return skill:objectName() end
  if event == sgs.CardFinished and player:getPhase() == sgs.Player_Play and player:getMark("sk_jingce_used") == 0
   and not data:toCardUse().card:isKindOf("SkillCard") and #sk_jingce_options(player) > 0 then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return event == sgs.DrawNCards or player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.DrawNCards then
   local draw = ctx.original_data:toDraw()
   draw.num = draw.num + player:getMark("&sk_jingce_draw")
   ctx.original_data:setValue(draw)
   return false
  end
  local options = sk_jingce_options(player)
  if #options == 0 then return false end
  room:setPlayerMark(player, "sk_jingce_used", 1)
  local choice = room:askForChoice(player, skill:objectName(), table.concat(options, "+"))
  if choice == "maxhp" then room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
  else room:addPlayerMark(player, "&sk_jingce_" .. choice) end
  player:drawCards(2, skill:objectName())
  return false
 end,
}
sk_jingceMod = sgs.CreateTargetModSkillV2{
 name = "#sk_jingce", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and ctx:getModType() == sgs.TargetModSkill_Residue then return p:getMark("&sk_jingce_slash") end
  return false
 end,
}
sk_guohuai:addSkill(sk_jingce)
sk_guohuai:addSkill(sk_jingceMod)
extension:insertRelatedSkills("sk_jingce", "#sk_jingce")
sgs.LoadTranslationTable{
 ["sk_guohuai"] = "SK郭淮", ["&sk_guohuai"] = "郭淮", ["#sk_guohuai"] = "郭淮",
 ["sk_jingce"] = "精策", [":sk_jingce"] = "出牌阶段限一次，当你使用的牌结算后，若你本阶段使用的牌数等于你的摸牌数、使用【杀】的次数上限或体力上限，你可以令此项数值+1，然后摸两张牌。",
 ["&sk_jingce_draw"] = "精策·摸牌", ["&sk_jingce_slash"] = "精策·杀",
 ["maxhp"] = "体力上限",
}

-- 极略53：诸葛诞（jilue.md L2630）
sk_zhugedan = sgs.General(extension, "sk_zhugedan", "wei", 5)
sk_gongao = sgs.CreateTriggerSkillV2{
 name = "sk_gongao", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.Dying, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, owner in sgs.qlist(room:getAllPlayers(true)) do
    for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(owner, "sk_gongao_" .. p:objectName(), 0) end
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.Dying then return false end
  local dying = data:toDying().who
  if not dying then return false end
  local names, owners = {}, {}
  for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if owner:isAlive() and owner ~= dying and owner:getMark("sk_gongao_" .. dying:objectName()) == 0 then
    table.insert(names, skill:objectName()); table.insert(owners, owner:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local dying = ctx.original_data:toDying().who
  room:setPlayerMark(owner, "sk_gongao_" .. dying:objectName(), 1)
  room:setPlayerProperty(owner, "maxhp", sgs.QVariant(owner:getMaxHp() + 1))
  local r = sgs.RecoverStruct(); r.who = owner; room:recover(owner, r)
  return false
 end,
}
sk_juyi = sgs.CreateTriggerSkillV2{
 name = "sk_juyi", events = {sgs.EventPhaseStart, sgs.DrawNCards},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then return skill:objectName() end
  if event == sgs.DrawNCards and player:getMark("&sk_juyi") > 0 then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return event == sgs.DrawNCards or player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.DrawNCards then
   local draw = ctx.original_data:toDraw()
   draw.num = draw.num + player:getMark("&sk_juyi")
   ctx.original_data:setValue(draw)
  else room:loseMaxHp(player, 1); room:addPlayerMark(player, "&sk_juyi") end
  return false
 end,
}
sk_juyiMax = sgs.CreateMaxCardsSkillV2{
 name = "#sk_juyi_max", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx) local p = ctx:getPrimary(); if p then return p:getMark("&sk_juyi") end; return false end,
}
sk_juyiRange = sgs.CreateAttackRangeSkillV2{
 name = "#sk_juyi_range", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx) local p = ctx:getPrimary(); if p then return p:getMark("&sk_juyi") end; return false end,
}
sk_juyiMod = sgs.CreateTargetModSkillV2{
 name = "#sk_juyi_slash", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and ctx:getModType() == sgs.TargetModSkill_Residue then return p:getMark("&sk_juyi") end
  return false
 end,
}
sk_weizhong = sgs.CreateTriggerSkillV2{
 name = "sk_weizhong", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.Dying, sgs.MaxHpChanged},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.Dying then
   local dying = ctx.original_data:toDying().who
   if dying and room:getTag("sk_weizhong_first"):toString() == "" then room:setTag("sk_weizhong_first", sgs.QVariant(dying:objectName())) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.MaxHpChanged then return skill:objectName() end
  local dying = data:toDying().who
  if dying == player and room:getTag("sk_weizhong_first"):toString() == player:objectName() then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.MaxHpChanged then player:drawCards(2, skill:objectName())
  else local r = sgs.RecoverStruct(); r.who = player; r.recover = player:getMaxHp() - player:getHp(); room:recover(player, r) end
  return false
 end,
}
sk_zhugedan:addSkill(sk_gongao)
sk_zhugedan:addSkill(sk_juyi)
sk_zhugedan:addSkill(sk_juyiMax)
sk_zhugedan:addSkill(sk_juyiRange)
sk_zhugedan:addSkill(sk_juyiMod)
sk_zhugedan:addSkill(sk_weizhong)
extension:insertRelatedSkills("sk_juyi", "#sk_juyi_max")
extension:insertRelatedSkills("sk_juyi", "#sk_juyi_range")
extension:insertRelatedSkills("sk_juyi", "#sk_juyi_slash")
sgs.LoadTranslationTable{
 ["sk_zhugedan"] = "SK诸葛诞", ["&sk_zhugedan"] = "诸葛诞", ["#sk_zhugedan"] = "诸葛诞",
 ["sk_gongao"] = "功獒", [":sk_gongao"] = "锁定技，每回合每名角色限一次，当一名其他角色进入濒死状态时，你加1点体力上限并回复1点体力。",
 ["sk_juyi"] = "举义", ["&sk_juyi"] = "举义", [":sk_juyi"] = "准备阶段，你可以减1点体力上限，然后你的摸牌数、手牌上限、攻击范围和使用【杀】的次数上限+1。",
 ["sk_weizhong"] = "威重", [":sk_weizhong"] = "锁定技，当你的体力上限变化后，你摸两张牌。当你进入濒死状态时，若你为第一个进入濒死状态的角色，你回复体力至上限。",
}

-- 极略53 曹金玉：jilue.md L2644-L2648
sk_caojinyu = sgs.General(extension, "sk_caojinyu", "wei", 3, false)
sk_yuqi = sgs.CreateTriggerSkillV2{
 name = "sk_yuqi", events = {sgs.EventPhaseStart, sgs.Damaged},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.Damaged then return skill:objectName() end
  if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
   for _, p in sgs.qlist(room:getOtherPlayers(player)) do if p:isMale() then return skill:objectName() end end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getAlivePlayers()) do
   if event == sgs.Damaged or p ~= player and p:isMale() then targets:append(p) end
  end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_yuqi", true, true)
  if not target then return false end
  ctx.targets:append(target); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.targets:first()
  if event == sgs.EventPhaseStart then room:loseHp(player, 1) end
  if target:isAlive() then room:loseHp(target, 1) end
  return false
 end,
}
sk_shanshen = sgs.CreateTriggerSkillV2{
 name = "sk_shanshen", global = true, events = {sgs.HpLost, sgs.EventPhaseStart, sgs.CardsMoveOneTime},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_Discard then
   local ids = sgs.IntList()
   for _, c in sgs.qlist(player:getHandcards()) do if c:hasFlag("sk_shanshen_temp") then ids:append(c:getEffectiveId()) end end
   room:ignoreCards(player, ids)
  elseif event == sgs.CardsMoveOneTime then
   local move = ctx.original_data:toMoveOneTime()
   if move.to_place ~= sgs.Player_DiscardPile then return end
   local ids = sgs.IntList()
   for _, id in sgs.qlist(move.card_ids) do
    local card = sgs.Sanguosha:getCard(id)
    if card:hasFlag("sk_shanshen_temp") and room:getCardPlace(id) == sgs.Player_DiscardPile then
     room:setCardFlag(card, "-sk_shanshen_temp"); ids:append(id)
    end
   end
   if not ids:isEmpty() then
    local broken = room:getTag("BreakCard"):toIntList()
    for _, id in sgs.qlist(ids) do broken:append(id) end
    local tag = sgs.QVariant(); tag:setValue(broken); room:setTag("BreakCard", tag)
    room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
     sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "BreakCard", "")), true)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.HpLost or data:toHpLost().lose <= 0 then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if room:getDrawPile():isEmpty() then room:swapPile() end
  local pool = {}
  for _, id in sgs.qlist(room:getDrawPile()) do if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then table.insert(pool, id) end end
  local ids = sgs.IntList()
  for i = 1, math.min(2, #pool) do
   local index = math.random(#pool); local id = table.remove(pool, index)
   room:setCardFlag(sgs.Sanguosha:getCard(id), "sk_shanshen_temp"); ids:append(id)
  end
  if not ids:isEmpty() then
   local card = sgs.DummyCard(ids); room:obtainCard(owner, card, false); room:ignoreCards(owner, ids); card:deleteLater()
  end
  return false
 end,
}
sk_caojinyu:addSkill(sk_yuqi)
sk_caojinyu:addSkill(sk_shanshen)
sgs.LoadTranslationTable{
 ["sk_caojinyu"] = "SK曹金玉", ["&sk_caojinyu"] = "曹金玉", ["#sk_caojinyu"] = "曹金玉",
 ["sk_yuqi"] = "隅泣", ["@sk_yuqi"] = "隅泣", [":sk_yuqi"] = "准备阶段或结束阶段，你可以与另一名男性角色各失去1点体力。当你受到伤害后，你可以令一名角色失去1点体力。",
 ["sk_shanshen"] = "善身", [":sk_shanshen"] = "当一名角色失去体力后，你获得两张不计入手牌上限的临时基本牌。",
}

-- 极略54 秦宓：jilue.md L2654-L2656
sk_qinmi = sgs.General(extension, "sk_qinmi", "shu", 3, true)
local function sk_tianbian_choose(room, player, pattern)
 local ids = room:getNCards(3, false)
 local enabled, disabled = sgs.IntList(), sgs.IntList()
 for _, id in sgs.qlist(ids) do
  local c = sgs.Sanguosha:getCard(id)
  if not pattern or c:isKindOf("BasicCard") and sgs.Sanguosha:matchExpPattern(pattern, player, c) then enabled:append(id)
  else disabled:append(id) end
 end
 room:fillAG(ids, player, disabled)
 local id = -1
 if not enabled:isEmpty() then id = room:askForAG(player, enabled, true, "sk_tianbian") end
 room:clearAG(player)
 if id >= 0 then ids:removeOne(id) end
 room:returnToTopDrawPile(ids)
 return id >= 0 and sgs.Sanguosha:getCard(id) or nil
end
sk_tianbianVS = sgs.CreateViewAsSkillV2{
 name = "sk_tianbian", n = 0, response_or_use = true,
 can_activate = function(skill, request)
  local p = request:getInitiator()
  if p:getPhase() ~= sgs.Player_NotActive or request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
  for _, name in ipairs((request:getPattern() or ""):split("+")) do
   local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
   if c then local basic = c:isKindOf("BasicCard"); c:deleteLater(); if basic then return true end end
  end
  return false
 end,
 create_card = function(skill, request)
  for _, name in ipairs(request:getPattern():split("+")) do
   local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
   if c then
    if c:isKindOf("BasicCard") then c:setSkillName(skill:objectName()); return c end
    c:deleteLater()
   end
  end
  return nil
 end,
 cost = function(skill, room, ctx, request)
  local c = sk_tianbian_choose(room, ctx.invoker, request:getPattern())
  if not c then return false end
  ctx.updated_card = c; return true
 end,
}
sk_tianbian = sgs.CreateTriggerSkillV2{
 name = "sk_tianbian", view_as_skill = sk_tianbianVS,
 events = {sgs.AskforPindianCard, sgs.CardAsked},
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.CardAsked then
   if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_NotActive then return false end
   local pattern = data:toStringList()[1]
   if pattern == "slash" or pattern == "jink" or pattern == "peach" or pattern == "analeptic" then return skill:objectName() end
   return false
  end
  local pd = data:toPindian(); local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and (pd.from == p and not pd.from_card or pd.to == p and not pd.to_card) then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local pattern = event == sgs.CardAsked and ctx.original_data:toStringList()[1] or nil
  local card = sk_tianbian_choose(room, owner, pattern)
  if not card then return false end
  if event == sgs.CardAsked then room:provide(card); return true end
  local pd = ctx.original_data:toPindian()
  if pd.from == owner then pd.from_card = card else pd.to_card = card end
  ctx.original_data:setValue(pd); return false
 end,
}
sk_jianzhengMod = sgs.CreateTargetModSkillV2{
 name = "#sk_jianzheng_distance", pattern = ".", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and ctx:getPrimary() and ctx:getPrimary():hasFlag("sk_jianzheng_reselect") then return 9999 end
  return false
 end,
}
sk_jianzheng = sgs.CreateTriggerSkillV2{
 name = "sk_jianzheng", global = true, events = {sgs.TargetSpecifying, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_jianzheng_disabled", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.TargetSpecifying then return false end
  local use = data:toCardUse()
  if not use.from or not use.card or not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and p ~= use.from and p:getMark("sk_jianzheng_disabled") == 0
    and not p:isKongcheng() and not use.from:isKongcheng() then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; local use = ctx.original_data:toCardUse()
  local card
  if owner:isKongcheng() then
   card = sk_tianbian_choose(room, owner, nil)
   if not card then return false end
  end
  if owner:pindian(use.from, skill:objectName(), card) then
   if not owner:askForSkillInvoke("sk_jianzheng_reselect", ctx.original_data) then return false end
   local selected = sgs.SPlayerList()
   room:setPlayerFlag(use.from, "sk_jianzheng_reselect")
   while true do
    local candidates = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
     if not selected:contains(p) and not use.from:isProhibited(p, use.card, selected)
      and (use.card:targetFixed() and selected:isEmpty() or not use.card:targetFixed() and use.card:targetFilter(selected, p, use.from)) then candidates:append(p) end
    end
    if candidates:isEmpty() then break end
    local target = room:askForPlayerChosen(owner, candidates, skill:objectName(), "@sk_jianzheng", true, true)
    if not target then break end
    selected:append(target)
   end
   room:setPlayerFlag(use.from, "-sk_jianzheng_reselect")
   use.to = selected; room:sortByActionOrder(use.to)
  else
   room:setPlayerMark(owner, "sk_jianzheng_disabled", 1)
   if not use.to:contains(owner) then use.to:append(owner); room:sortByActionOrder(use.to) end
  end
  ctx.original_data:setValue(use); return false
 end,
}
sk_qinmi:addSkill(sk_jianzheng)
sk_qinmi:addSkill(sk_jianzhengMod)
sk_qinmi:addSkill(sk_tianbian)
extension:insertRelatedSkills("sk_jianzheng", "#sk_jianzheng_distance")
sgs.LoadTranslationTable{
 ["sk_qinmi"] = "SK秦宓", ["&sk_qinmi"] = "秦宓", ["#sk_qinmi"] = "秦宓",
 ["sk_jianzheng"] = "谏征", ["sk_jianzheng_reselect"] = "谏征", ["@sk_jianzheng"] = "谏征",
 [":sk_jianzheng"] = "当一名其他角色使用基本牌或普通锦囊牌指定目标时，你可以与其拼点。若你赢，你可以为此牌重新选择目标（无距离限制）；若你没赢，你成为此牌的额外目标且“谏征”本回合内失效。",
 ["sk_tianbian"] = "天辩", [":sk_tianbian"] = "当你需要拼点/于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的三张牌，然后你可以将其中一张牌作为拼点牌/使用或打出其中一张牌。",
}

-- 极略54 吕凯：jilue.md L2664-L2666
sk_lvkai = sgs.General(extension, "sk_lvkai", "shu", 3, true)
sk_tunanMod = sgs.CreateTargetModSkillV2{
 name = "#sk_tunan", pattern = ".", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local c = ctx:getCard()
  if c and c:getSkillName() == "sk_tunan" and (ctx:getModType() == sgs.TargetModSkill_Residue or ctx:getModType() == sgs.TargetModSkill_DistanceLimit) then return 9999 end
  return false
 end,
}
sk_tunan = sgs.CreateTriggerSkillV2{
 name = "sk_tunan", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Play then return false end
  local target = player:getNextAlive()
  if not target or target == player then return false end
  local available = false
  for _, name in ipairs({"slash", "snatch"}) do
   local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); card:setSkillName(skill:objectName())
   if not player:isProhibited(target, card) and card:targetFilter(sgs.SPlayerList(), target, player) then available = true end
   card:deleteLater()
  end
  if not available then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), sgs.QVariant(player))
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; local target = player:getNextAlive()
  if not player:isAlive() or not target or target == player then return false end
  local choices = {}
  for _, name in ipairs({"slash", "snatch"}) do
   local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); card:setSkillName(skill:objectName())
   if not player:isProhibited(target, card) and card:targetFilter(sgs.SPlayerList(), target, player) then table.insert(choices, name) end
   card:deleteLater()
  end
  if #choices == 0 then return false end
  local name = room:askForChoice(owner, skill:objectName(), table.concat(choices, "+"), sgs.QVariant(player))
  local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); card:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.card = card; use.from = player; use.to:append(target)
  room:useCard(use, false); card:deleteLater(); return false
 end,
}
sk_bijing = sgs.CreateTriggerSkillV2{
 name = "sk_bijing", events = {sgs.TargetConfirmed},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local use = data:toCardUse()
  if use.from and use.from ~= player and use.to:contains(player) and use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local use = ctx.original_data:toCardUse(); local colors = {}
  local function record(card)
   table.insert(colors, card:isRed() and "red" or card:isBlack() and "black" or "none")
  end
  for i = 1, 2 do
   if not player:isAlive() or not use.from:isAlive() or not player:canDiscard(use.from, "he") then break end
   local id = room:askForCardChosen(player, use.from, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
   if id < 0 then break end
   record(sgs.Sanguosha:getCard(id)); room:throwCard(id, use.from, player)
  end
  if player:isAlive() and player:canDiscard(player, "he") then
   local id = room:askForCardChosen(player, player, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
   if id >= 0 then record(sgs.Sanguosha:getCard(id)); room:throwCard(id, player, player) end
  end
  local same = #colors > 0
  for i = 2, #colors do if colors[i] ~= colors[1] then same = false end end
  if same then
   if not table.contains(use.nullified_list, player:objectName()) then table.insert(use.nullified_list, player:objectName()) end
   ctx.original_data:setValue(use)
  end
  return false
 end,
}
sk_lvkai:addSkill(sk_tunan)
sk_lvkai:addSkill(sk_tunanMod)
sk_lvkai:addSkill(sk_bijing)
extension:insertRelatedSkills("sk_tunan", "#sk_tunan")
sgs.LoadTranslationTable{
 ["sk_lvkai"] = "SK吕凯", ["&sk_lvkai"] = "吕凯", ["#sk_lvkai"] = "吕凯",
 ["sk_tunan"] = "图南", [":sk_tunan"] = "一名角色的出牌阶段开始时，你可以令其视为对其下家使用一张无次数与距离限制的【杀】或【顺手牵羊】。",
 ["sk_bijing"] = "闭境", ["@sk_bijing"] = "闭境", [":sk_bijing"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以弃置其两张牌，然后你弃置一张牌；若这些牌颜色均相同，此牌对你无效。",
}

-- 极略54 杨婉：jilue.md L2672
sk_yangwan = sgs.General(extension, "sk_yangwan", "shu", 3, false)
sk_youyan = sgs.CreateTriggerSkillV2{
 name = "sk_youyan", global = true, events = {sgs.CardFinished, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().from == sgs.Player_Play then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_youyan_" .. player:objectName(), 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardFinished or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_Play then return false end
  local use = data:toCardUse()
  if use.from ~= player or not use.card or not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
  for _, p in sgs.qlist(room:getAlivePlayers()) do
   if p:getMark("sk_youyan_" .. player:objectName()) == 0 then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getAlivePlayers()) do
   if p:getMark("sk_youyan_" .. player:objectName()) == 0 then targets:append(p) end
  end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_youyan", true, true)
  if not target then return false end
  player:setTag("sk_youyan_target", sgs.QVariant(target)); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = player:getTag("sk_youyan_target"):toPlayer(); player:removeTag("sk_youyan_target")
  if not target or not target:isAlive() then return false end
  room:setPlayerMark(target, "sk_youyan_" .. player:objectName(), 1)
  local original = ctx.original_data:toCardUse().card
  local card = sgs.Sanguosha:cloneCard(original:objectName(), sgs.Card_NoSuit, 0); card:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.from = target; use.card = card
  if not card:targetFixed() then use.to:append(player) end
  room:useCard(use, false); card:deleteLater()
  if player:isAlive() then
   local recover = sgs.RecoverStruct(); recover.who = player; recover.recover = 1; room:recover(player, recover)
   player:drawCards(3, skill:objectName())
  end
  return false
 end,
}
sk_zhuihuan = sgs.CreateTriggerSkillV2{
 name = "sk_zhuihuan", global = true, events = {sgs.Damaged, sgs.TurnStart, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if not player then return end
  if event == sgs.Damaged then
   local damage = ctx.original_data:toDamage()
   if damage.from and damage.from ~= player then room:setPlayerMark(damage.from, "sk_zhuihuan_" .. player:objectName(), 1) end
  elseif event == sgs.TurnStart then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    room:setPlayerMark(p, "sk_zhuihuan_pending_" .. player:objectName(), p:getMark("sk_zhuihuan_" .. player:objectName()))
    room:setPlayerMark(p, "sk_zhuihuan_" .. player:objectName(), 0)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_Start then return false end
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do
   if p:getMark("sk_zhuihuan_pending_" .. player:objectName()) > 0 then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do
   if p:getMark("sk_zhuihuan_pending_" .. player:objectName()) > 0 then targets:append(p) end
  end
  for _, p in sgs.qlist(targets) do
   if p:isAlive() then local damage = sgs.DamageStruct(); damage.from = player; damage.to = p; damage.damage = 2; damage.reason = skill:objectName(); room:damage(damage) end
  end
  return false
 end,
}
sk_yangwan:addSkill(sk_youyan)
sk_yangwan:addSkill(sk_zhuihuan)
sgs.LoadTranslationTable{
 ["sk_yangwan"] = "SK杨婉", ["&sk_yangwan"] = "杨婉", ["#sk_yangwan"] = "杨婉",
 ["sk_youyan"] = "诱言", ["@sk_youyan"] = "诱言", [":sk_youyan"] = "出牌阶段每名角色限一次，当你使用基本牌或普通锦囊牌后，你可以令一名角色视为使用此牌（若需选择目标则指定你为目标），此牌结算后，你回复1点体力并摸三张牌。",
 ["sk_zhuihuan"] = "追还", [":sk_zhuihuan"] = "准备阶段，你可以对你上个回合开始后对你造成过伤害的其他角色各造成2点伤害。",
}

-- 极略57 羊徽瑜：jilue.md L2727
sk_yanghuiyu = sgs.General(extension, "sk_yanghuiyu", "qun", 3, false)
local function sk_ciwei_targets(use)
 local names = {}
 for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
 table.sort(names); return table.concat(names, "+")
end
sk_ciweiRecord = sgs.CreateTriggerSkillV2{
 name = "#sk_ciwei_record", global = true,
 events = {sgs.PreCardUsed, sgs.TargetSpecifying, sgs.TargetConfirming, sgs.TargetSpecified, sgs.TargetConfirmed, sgs.CardFinished, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging then
   if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
    for _, p in sgs.qlist(room:getAllPlayers(true)) do
     room:setPlayerMark(p, "sk_ciwei_changed", 0); room:setPlayerMark(p, "sk_ciwei_unchanged", 0)
    end
   end
   return
  end
  local use = ctx.original_data:toCardUse()
  if not use.card or not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return end
  if event == sgs.CardFinished then
   use.card:removeTag("sk_ciwei_targets"); use.card:removeTag("sk_ciwei_changed"); return
  end
  local targets = sk_ciwei_targets(use)
  if event == sgs.PreCardUsed then
   use.card:setTag("sk_ciwei_targets", sgs.QVariant(targets)); use.card:setTag("sk_ciwei_changed", sgs.QVariant(false))
  elseif use.card:getTag("sk_ciwei_targets"):toString() ~= targets then
   use.card:setTag("sk_ciwei_changed", sgs.QVariant(true))
   use.card:setTag("sk_ciwei_targets", sgs.QVariant(targets))
  end
 end,
}
sk_ciwei = sgs.CreateTriggerSkillV2{
 name = "sk_ciwei", priority = -10, events = {sgs.TargetSpecified},
 can_trigger = function(skill, event, room, player, data)
  local use = data:toCardUse()
  if not use.from or not use.card or not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
  local changed = use.card:getTag("sk_ciwei_changed"):toBool() or use.card:getTag("sk_ciwei_targets"):toString() ~= sk_ciwei_targets(use)
  local mark = changed and "sk_ciwei_changed" or "sk_ciwei_unchanged"
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and p:getMark(mark) == 0 and (not changed or p ~= use.from) then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; local use = ctx.original_data:toCardUse()
  local changed = use.card:getTag("sk_ciwei_changed"):toBool() or use.card:getTag("sk_ciwei_targets"):toString() ~= sk_ciwei_targets(use)
  local mark = changed and "sk_ciwei_changed" or "sk_ciwei_unchanged"
  if owner:getMark(mark) > 0 or changed and owner == use.from then return false end
  room:setPlayerMark(owner, mark, 1)
  if changed then
   local list = use.nullified_list
   if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
   use.nullified_list = list; ctx.original_data:setValue(use)
   room:loseHp(use.from, 1)
  else
   local list = use.no_respond_list
   if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
   use.no_respond_list = list; ctx.original_data:setValue(use)
   room:obtainCard(use.from, use.card, true)
   if use.from:isAlive() then local recover = sgs.RecoverStruct(); recover.who = owner; recover.recover = 1; room:recover(use.from, recover) end
  end
  return false
 end,
}
sk_caiyuan = sgs.CreateTriggerSkillV2{
 name = "sk_caiyuan", events = {sgs.TargetConfirming},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local use = data:toCardUse()
  if use.card and not use.card:isBlack() and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
   and use.to:length() == 1 and use.to:contains(player) and not room:getOtherPlayers(player):isEmpty() then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  player:drawCards(2, skill:objectName())
  if not player:isAlive() then return false end
  local targets = room:getOtherPlayers(player)
  if targets:isEmpty() then return false end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_caiyuan", false, true)
  local use = ctx.original_data:toCardUse(); use.to:removeOne(player); use.to:append(target)
  use.card:setTag("sk_ciwei_changed", sgs.QVariant(true))
  room:sortByActionOrder(use.to); ctx.original_data:setValue(use); return false
 end,
}
sk_yanghuiyu:addSkill(sk_ciweiRecord)
sk_yanghuiyu:addSkill(sk_ciwei)
sk_yanghuiyu:addSkill(sk_caiyuan)
extension:insertRelatedSkills("sk_ciwei", "#sk_ciwei_record")
sgs.LoadTranslationTable{
 ["sk_yanghuiyu"] = "SK羊徽瑜", ["&sk_yanghuiyu"] = "羊徽瑜", ["#sk_yanghuiyu"] = "羊徽瑜",
 ["sk_ciwei"] = "慈威", [":sk_ciwei"] = "每回合各限一次，当其他角色/一名角色使用基本牌或普通锦囊牌指定目标后，若此牌目标发生过/未发生变化，你可以令此牌无效/不能被响应，然后令使用者失去1点体力/获得此牌且回复1点体力。",
 ["sk_caiyuan"] = "才媛", ["@sk_caiyuan"] = "才媛", [":sk_caiyuan"] = "当你成为基本牌或普通锦囊牌的唯一目标时，若此牌不为黑色，你可以摸两张牌，将此牌目标转移给另一名角色。",
}

-- 极略57 蹋顿：jilue.md L2735-L2737
sk_tadun = sgs.General(extension, "sk_tadun", "qun", 6, true)
sk_luanzhan = sgs.CreateTriggerSkillV2{
 name = "sk_luanzhan", global = true, events = {sgs.CardFinished, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_luanzhan_used", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardFinished then return false end
  local use = data:toCardUse()
  if not use.from or not use.card or not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and p:getMark("sk_luanzhan_used") == 0 then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), ctx.original_data)
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if owner:getMark("sk_luanzhan_used") > 0 then return false end
  room:setPlayerMark(owner, "sk_luanzhan_used", 1)
  local original = ctx.original_data:toCardUse()
  local card = sgs.Sanguosha:cloneCard(original.card:objectName(), sgs.Card_NoSuit, 0); card:setSkillName(skill:objectName())
  local use = sgs.CardUseStruct(); use.card = card; use.from = owner; use.to:append(owner)
  if original.from ~= owner and original.from:isAlive() then use.to:append(original.from) end
  room:sortByActionOrder(use.to); room:useCard(use, false); card:deleteLater()
  if owner:isAlive() then owner:drawCards(2, skill:objectName()) end
  return false
 end,
}
sk_tadun:addSkill(sk_luanzhan)
sgs.LoadTranslationTable{
 ["sk_tadun"] = "SK蹋顿", ["&sk_tadun"] = "蹋顿", ["#sk_tadun"] = "蹋顿",
 ["sk_luanzhan"] = "乱战", [":sk_luanzhan"] = "每回合限一次，当一名角色使用【杀】或普通锦囊牌结算后，你可以视为对你和该角色使用此牌，然后你摸两张牌。",
}

-- 极略57 sp太史慈：jilue.md L2743-L2745
sk_sptaishici = sgs.General(extension, "sk_sptaishici", "wu", 4, true)
sk_jixu = sgs.CreateTriggerSkillV2{
 name = "sk_jixu", global = true, events = {sgs.DamageCaused, sgs.DamageInflicted, sgs.Damage, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_jixu_used", 0) end
  elseif event == sgs.Damage then
   local d = ctx.original_data:toDamage()
   if d.card and d.card:getSkillName() == "sk_jixu" then
    local names = d.card:getTag("sk_jixu_hit"):toString()
    d.card:setTag("sk_jixu_hit", sgs.QVariant(names == "" and d.to:objectName() or names .. "+" .. d.to:objectName()))
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.DamageCaused and event ~= sgs.DamageInflicted then return false end
  local d = data:toDamage()
  if not d.from or d.from == d.to then return false end
  local owner = event == sgs.DamageCaused and d.from or d.to
  if player == owner and owner:isAlive() and owner:hasSkill(skill:objectName()) and owner:getMark("sk_jixu_used") < 2 then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  room:addPlayerMark(player, "sk_jixu_used"); player:drawCards(2, skill:objectName())
  if not player:isAlive() then return false end
  local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:setSkillName(skill:objectName())
  local candidates = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(player)) do if not player:isProhibited(p, slash) then candidates:append(p) end end
  local use = sgs.CardUseStruct(); use.from = player; use.card = slash
  for i = 1, 2 do
   if candidates:isEmpty() then break end
   local target = room:askForPlayerChosen(player, candidates, "sk_jixu_slash", "@sk_jixu_slash", true, true)
   if not target then break end
   use.to:append(target); candidates:removeOne(target)
  end
  if not use.to:isEmpty() then room:sortByActionOrder(use.to); room:useCard(use, false) end
  local hits = slash:getTag("sk_jixu_hit"):toString(); local targets = sgs.SPlayerList()
  if hits ~= "" then
   for _, name in ipairs(hits:split("+")) do local p = room:findPlayerByObjectName(name); if p and p:isAlive() and not targets:contains(p) then targets:append(p) end end
  end
  slash:deleteLater()
  if player:isAlive() and not targets:isEmpty() then
   local target = room:askForPlayerChosen(player, targets, "sk_jixu_transfer", "@sk_jixu_transfer", true, true)
   if target then local d = ctx.original_data:toDamage(); d.to = target; d.transfer = true; room:damage(d); return true end
  end
  return false
 end,
}
sk_sptaishici:addSkill(sk_jixu)
sgs.LoadTranslationTable{
 ["sk_sptaishici"] = "SKSP太史慈", ["&sk_sptaishici"] = "SP太史慈", ["#sk_sptaishici"] = "太史慈",
 ["sk_jixu"] = "击虚", ["sk_jixu_slash"] = "击虚", ["sk_jixu_transfer"] = "击虚", ["@sk_jixu_slash"] = "击虚", ["@sk_jixu_transfer"] = "击虚",
 [":sk_jixu"] = "每回合限两次，当你对其他角色造成伤害时，或当其他角色对你造成伤害时，你可以摸两张牌并可视为对至多两名其他角色使用一张无次数与距离限制的【杀】。此【杀】结算后，你可将此伤害转移给因此牌受到伤害的角色。",
}

-- 极略59 郝昭：jilue.md L2759
sk_haozhao = sgs.General(extension, "sk_haozhao", "wei", 4, true)
sk_zhengu = sgs.CreateTriggerSkillV2{
 name = "sk_zhengu", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if player and player:isAlive() and player:hasSkill(skill:objectName()) and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@sk_zhengu", true, true)
  if not target then return false end
  ctx.target = target; return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.target; local x = player:getHandcardNum(); local delta = player:isWounded() and 2 or 1
  local choice = room:askForChoice(player, skill:objectName(), "increase+decrease", sgs.QVariant(target))
  local n = math.max(0, x + (choice == "increase" and delta or -delta))
  local diff = n - target:getHandcardNum()
  if diff > 0 then target:drawCards(diff, skill:objectName())
  elseif diff < 0 then room:askForDiscard(target, skill:objectName(), -diff, -diff, false, false) end
  return false
 end,
}
sk_haozhao:addSkill(sk_zhengu)
sgs.LoadTranslationTable{
 ["sk_haozhao"] = "SK郝昭", ["&sk_haozhao"] = "郝昭", ["#sk_haozhao"] = "郝昭",
 ["sk_zhengu"] = "镇骨", ["@sk_zhengu"] = "镇骨",
 [":sk_zhengu"] = "准备阶段或结束阶段，你可以令一名角色将手牌数调整至X+1或X-1（X为你的手牌数）。若你已受伤，则改为X+2或X-2。",
}

-- 极略59 杜预：jilue.md L2761-L2763
sk_duyu = sgs.General(extension, "sk_duyu", "wei", 4, true)
sk_sanchen = sgs.CreateTriggerSkillV2{
 name = "sk_sanchen", global = true, events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Start then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return (ctx.invoker or player):askForSkillInvoke(skill:objectName(), sgs.QVariant(player)) end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; player:drawCards(3, skill:objectName())
  if not player:isAlive() then return false end
  local n = math.min(3, player:getCards("he"):length())
  if n == 0 then return false end
  local cards = room:askForExchange(player, skill:objectName(), n, n, true, "@sk_sanchen", false)
  if not cards then return false end
  local counts, ids = {}, {}
  for _, id in sgs.qlist(cards:getSubcards()) do
   local kind = sgs.Sanguosha:getCard(id):getTypeId(); counts[kind] = (counts[kind] or 0) + 1; table.insert(ids, id)
  end
  room:throwCard(cards, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), "sk_sanchen", ""), player)
  cards:deleteLater()
  local maximum, kinds = 0, 0
  for _, count in pairs(counts) do maximum = math.max(maximum, count); kinds = kinds + 1 end
  local gain = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
  for _, id in ipairs(ids) do
   if counts[sgs.Sanguosha:getCard(id):getTypeId()] == maximum and room:getCardPlace(id) == sgs.Player_DiscardPile then gain:addSubcard(id) end
  end
  if owner:isAlive() and gain:subcardsLength() > 0 then room:obtainCard(owner, gain, true) end
  gain:deleteLater()
  if owner:isAlive() and player:isAlive() and kinds == #ids and owner:askForSkillInvoke("sk_sanchen_draw", sgs.QVariant(player)) then player:drawCards(3, skill:objectName()) end
  return false
 end,
}
local function sk_pozhu_tricks(player)
 local n = 0
 for _, c in sgs.qlist(player:getHandcards()) do if c:isKindOf("TrickCard") then n = n + 1 end end
 return n
end
sk_pozhuCard = sgs.CreateSkillCard{
 name = "sk_pozhuCard",
 filter = function(self, targets, target, source) return #targets == 0 and target ~= source and source:inMyAttackRange(target) end,
 on_use = function(self, room, source, targets)
  local target = targets[1]
  if sk_pozhu_tricks(target) <= sk_pozhu_tricks(source) then
   local x = target:getMark("sk_pozhu_damage_" .. source:objectName())
   if x > 0 then local d = sgs.DamageStruct(); d.from = source; d.to = target; d.damage = x; d.reason = "sk_pozhu"; room:damage(d) end
  elseif not target:isKongcheng() then
   room:showAllCards(target, source)
   if source:isAlive() and target:isAlive() and not target:isKongcheng() then
    local id = room:askForCardChosen(source, target, "h", "sk_pozhu", false, sgs.Card_MethodNone)
    room:obtainCard(source, id, false)
   end
  end
 end,
}
sk_pozhuVS = sgs.CreateViewAsSkillV2{
 name = "sk_pozhu", n = 1,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():usedTimes("#sk_pozhuCard") < 3 end,
 can_select_card = function(skill, request, card) return request:getSelectedCardIds():isEmpty() and card:isKindOf("TrickCard") and not request:getInitiator():isJilei(card) end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request) local c = sk_pozhuCard:clone(); c:addSubcards(request:getSelectedCardIds()); return c end,
}
sk_pozhu = sgs.CreateTriggerSkillV2{
 name = "sk_pozhu", view_as_skill = sk_pozhuVS, global = true, events = {sgs.Damage, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.Damage then
   local d = ctx.original_data:toDamage()
   if d.from and d.from:getPhase() == sgs.Player_Play then room:addPlayerMark(d.to, "sk_pozhu_damage_" .. d.from:objectName()) end
  else
   local change = ctx.original_data:toPhaseChange()
   if change.from == sgs.Player_Play or change.to == sgs.Player_Play then
    for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_pozhu_damage_" .. player:objectName(), 0) end
   end
  end
 end,
 can_trigger = function() return false end,
}
sk_duyu:addSkill(sk_sanchen)
sk_duyu:addSkill(sk_pozhu)
sgs.LoadTranslationTable{
 ["sk_duyu"] = "SK杜预", ["&sk_duyu"] = "杜预", ["#sk_duyu"] = "杜预",
 ["sk_sanchen"] = "三陈", ["sk_sanchen_draw"] = "三陈", ["@sk_sanchen"] = "三陈",
 [":sk_sanchen"] = "一名角色的准备阶段，你可以令其摸三张牌并弃置三张牌，然后你获得弃置牌中类别相同且数量最多的牌。若弃置牌类别均不同，你可以令其摸三张牌。",
 ["sk_pozhu"] = "破竹",
 [":sk_pozhu"] = "出牌阶段限三次，你可以弃置一张锦囊牌并选择一名攻击范围内的其他角色，若其手牌中锦囊牌数量不大于你，你对其造成X点伤害（X为本阶段你对其造成伤害的次数）；否则你观看其手牌并获得其中一张牌。",
}

-- 极略59 司马朗：jilue.md L2763
sk_simalang = sgs.General(extension, "sk_simalang", "wei", 3, true)
local function sk_junbing_gain(room, source, target)
 room:addPlayerMark(target, "&sk_junbing")
 target:drawCards(1, "sk_junbing")
 local kingdom = target:getKingdom()
 if target:isAlive() and kingdom ~= "shu" and kingdom ~= "wu" and kingdom ~= "qun" then target:drawCards(2, "sk_junbing") end
end
sk_junbingCard = sgs.CreateSkillCard{
 name = "sk_junbingCard",
 filter = function(self, targets, target, source) return #targets == 0 end,
 on_use = function(self, room, source, targets) sk_junbing_gain(room, source, targets[1]) end,
}
sk_junbingVS = sgs.CreateViewAsSkillV2{
 name = "sk_junbing", n = 1,
 can_activate = function(skill, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and not request:getInitiator():hasUsed("#sk_junbingCard") end,
 can_select_card = function(skill, request, card) return request:getSelectedCardIds():isEmpty() and card:isKindOf("Slash") and not request:getInitiator():isJilei(card) end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request) local c = sk_junbingCard:clone(); c:addSubcards(request:getSelectedCardIds()); return c end,
}
sk_junbing = sgs.CreateTriggerSkillV2{
 name = "sk_junbing", view_as_skill = sk_junbingVS, events = {sgs.Damaged},
 can_trigger = function(skill, event, room, player, data)
  if player and player:isAlive() and player:hasSkill(skill:objectName()) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return room:askForCard(player, "Slash", "@sk_junbing", ctx.original_data, sgs.Card_MethodDiscard) ~= nil
 end,
 on_effect = function(skill, event, room, player, ctx)
  if player:isAlive() then local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName()); sk_junbing_gain(room, player, target) end
  return false
 end,
}
sk_junbingRange = sgs.CreateAttackRangeSkillV2{
 name = "#sk_junbing_range", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx) local p = ctx:getPrimary(); if p then return p:getMark("&sk_junbing") end; return false end,
}
sk_junbingMod = sgs.CreateTargetModSkillV2{
 name = "#sk_junbing_slash", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local p = ctx:getPrimary()
  if p and ctx:getModType() == sgs.TargetModSkill_Residue then return p:getMark("&sk_junbing") end
  return false
 end,
}
sk_quji = sgs.CreateTriggerSkillV2{
 name = "sk_quji", global = true, events = {sgs.Damaged, sgs.DrawNCards, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.DrawNCards then
   local draw = ctx.original_data:toDraw()
   local n = player:getMark("&sk_quji_draw")
   if n > 0 and draw.reason == "draw_phase" then draw.num = draw.num + n; ctx.original_data:setValue(draw) end
  elseif event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_quji_used", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.Damaged or not player or not player:isAlive() or not data:toDamage().from then return false end
  if data:toDamage().from == player then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() and p:getMark("sk_quji_used") == 0 then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if owner:getMark("sk_quji_used") > 0 then return false end
  if room:askForCard(owner, "Jink", "@sk_quji:" .. player:objectName(), ctx.original_data, sgs.Card_MethodDiscard) then
   room:setPlayerMark(owner, "sk_quji_used", 1); return true
  end
  return false
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local r = sgs.RecoverStruct(); r.who = owner; room:recover(player, r)
  local kingdom = player:getKingdom()
  if player:isAlive() and kingdom ~= "shu" and kingdom ~= "wu" and kingdom ~= "qun" then
   local values = {hp = player:getHp(), maxhp = player:getMaxHp(), draw = 2 + player:getMark("&sk_quji_draw")}
   local minimum = math.min(values.hp, values.maxhp, values.draw)
   local choices = {}; for _, name in ipairs({"hp", "maxhp", "draw"}) do if values[name] == minimum then table.insert(choices, name) end end
   local choice = room:askForChoice(owner, skill:objectName(), table.concat(choices, "+"), sgs.QVariant(player))
   if choice == "hp" then room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp() + 1))
   elseif choice == "maxhp" then room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
   else room:addPlayerMark(player, "&sk_quji_draw") end
  end
  return false
 end,
}
sk_simalang:addSkill(sk_junbing)
sk_simalang:addSkill(sk_quji)
sk_simalang:addSkill(sk_junbingRange)
sk_simalang:addSkill(sk_junbingMod)
extension:insertRelatedSkills("sk_junbing", "#sk_junbing_range")
extension:insertRelatedSkills("sk_junbing", "#sk_junbing_slash")
sgs.LoadTranslationTable{
 ["sk_simalang"] = "SK司马朗", ["&sk_simalang"] = "司马朗", ["#sk_simalang"] = "司马朗",
 ["sk_junbing"] = "郡兵", ["@sk_junbing"] = "郡兵",
 [":sk_junbing"] = "出牌阶段限一次，或当你受到伤害时，你可以弃置一张【杀】并选择一名角色，令其摸一张牌且出【杀】次数与攻击范围+1；若该角色势力不为蜀、吴或群，你令其额外摸两张牌。",
 ["sk_quji"] = "去疾", ["@sk_quji"] = "去疾",
 [":sk_quji"] = "每回合限一次，当一名角色受到另一名角色造成的伤害后，你可以弃置一张【闪】并令其回复1点体力；若其势力不为蜀、吴或群，你令其体力值、体力上限与摸牌数中最小的一项属性+1。",
}

-- 极略59 曹华：jilue.md L2763
sk_caohua = sgs.General(extension, "sk_caohua", "wei", 3, false)
sk_caiyi = sgs.CreateTriggerSkillV2{
 name = "sk_caiyi", global = true, events = {sgs.CardUsed, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_caiyi_disabled", 0) end
  elseif event == sgs.CardsMoveOneTime then
   local move = ctx.original_data:toMoveOneTime()
   if move.to and move.to_place == sgs.Player_PlaceHand and move.reason.m_skillName == "sk_caiyi" then
    local target = room:findPlayerByObjectName(move.to:objectName())
    if target and target:getMark("sk_caiyi_collect") > 0 then
     for _, id in sgs.qlist(move.card_ids) do
      local suit = sgs.Sanguosha:getCard(id):getSuit()
      if suit >= sgs.Card_Spade and suit <= sgs.Card_Diamond then room:setPlayerMark(target, "sk_caiyi_suit_" .. suit, 1) end
     end
    end
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.CardUsed and player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getMark("sk_caiyi_disabled") == 0 then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName(), ctx.original_data) end,
 on_effect = function(skill, event, room, player, ctx)
  for suit = sgs.Card_Spade, sgs.Card_Diamond do room:setPlayerMark(player, "sk_caiyi_suit_" .. suit, 0) end
  local cards = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
  for _, c in sgs.qlist(player:getHandcards()) do
   cards:addSubcard(c)
   local suit = c:getSuit()
   if suit >= sgs.Card_Spade and suit <= sgs.Card_Diamond then room:setPlayerMark(player, "sk_caiyi_suit_" .. suit, 1) end
  end
  if cards:subcardsLength() > 0 then room:throwCard(cards, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), "sk_caiyi", ""), player) end
  cards:deleteLater()
  if not player:isAlive() then return false end
  room:setPlayerMark(player, "sk_caiyi_collect", 1)
  player:drawCards(4, skill:objectName())
  room:setPlayerMark(player, "sk_caiyi_collect", 0)
  local complete = true
  for suit = sgs.Card_Spade, sgs.Card_Diamond do if player:getMark("sk_caiyi_suit_" .. suit) == 0 then complete = false end end
  if complete and player:isAlive() then
   local targets = room:getOtherPlayers(player)
   if not targets:isEmpty() then
    local target = room:askForPlayerChosen(player, targets, skill:objectName())
    room:setPlayerProperty(target, "chained", sgs.QVariant(true))
    if target:isAlive() then target:turnOver() end
    if target:isAlive() then
     local pool = sgs.QList2Table(target:getCards("he"))
     local discard = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
     for i = 1, math.min(2, #pool) do local index = math.random(#pool); discard:addSubcard(pool[index]); table.remove(pool, index) end
     if discard:subcardsLength() > 0 then room:throwCard(discard, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, target:objectName(), "sk_caiyi", ""), target) end
     discard:deleteLater()
    end
    if target:isAlive() then room:loseHp(target, 1) end
   end
   room:setPlayerMark(player, "sk_caiyi_disabled", 1)
  end
  return false
 end,
}
sk_guili = sgs.CreateTriggerSkillV2{
 name = "sk_guili", frequency = sgs.Skill_Compulsory, global = true,
 events = {sgs.Damage, sgs.EventPhaseStart, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_RoundStart then room:setPlayerMark(player, "sk_guili_damage", 0)
  elseif event == sgs.Damage then
   local damage = ctx.original_data:toDamage()
   if damage.from and damage.from == room:getCurrent() then room:setPlayerMark(damage.from, "sk_guili_damage", 1) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseChanging or not player or data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
  if room:isCurrentExtraTurn() then
   if player:isAlive() and player:hasSkill(skill:objectName()) and room:getCurrentExtraTurnReason() == skill:objectName() and player:getMark("sk_guili_damage") == 0 then return skill:objectName() end
   return false
  end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if p:isAlive() then table.insert(names, skill:objectName()); table.insert(owners, p:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if room:isCurrentExtraTurn() then owner:turnOver()
  else room:scheduleExtraTurn(owner, skill:objectName()) end
  return false
 end,
}
sk_caohua:addSkill(sk_caiyi)
sk_caohua:addSkill(sk_guili)
sgs.LoadTranslationTable{
 ["sk_caohua"] = "SK曹华", ["&sk_caohua"] = "曹华", ["#sk_caohua"] = "曹华",
 ["sk_caiyi"] = "彩翼",
 [":sk_caiyi"] = "当你使用牌时，你可以弃置所有手牌，然后摸四张牌。若你因此失去与获得的牌之中包括了四种花色的牌，你令一名其他角色依次执行：横置、翻面、随机弃置两张牌、失去1点体力；然后此技能本回合失效。",
 ["sk_guili"] = "归离",
 [":sk_guili"] = "锁定技，非额外回合结束后，你执行一个额外回合，此回合结束时，若你未于此回合内造成伤害，你翻面。",
}

-- 极略61 严畯：jilue.md L2771
sk_yanjun = sgs.General(extension, "sk_yanjun", "wu", 3)
sk_guanchao = sgs.CreateTriggerSkillV2{
 name = "sk_guanchao", global = true, events = {sgs.CardFinished, sgs.CardsMoveOneTime},
 on_record = function(skill, event, room, player, ctx)
  if event ~= sgs.CardsMoveOneTime then return end
  local move = ctx.original_data:toMoveOneTime()
  if move.to_place ~= sgs.Player_DiscardPile then return end
  local ids = sgs.IntList()
  for _, id in sgs.qlist(move.card_ids) do
   local card = sgs.Sanguosha:getCard(id)
   if card:hasFlag("sk_guanchao_temp") and room:getCardPlace(id) == sgs.Player_DiscardPile then
    room:setCardFlag(card, "-sk_guanchao_temp"); ids:append(id)
   end
  end
  if not ids:isEmpty() then
   local broken = room:getTag("BreakCard"):toIntList()
   for _, id in sgs.qlist(ids) do broken:append(id) end
   local tag = sgs.QVariant(); tag:setValue(broken); room:setTag("BreakCard", tag)
   room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "BreakCard", "")), true)
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardFinished then return false end
  local c = data:toCardUse().card
  if not c then return false end
  local names, owners = {}, {}
  for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   local n, old = c:getNumber(), p:getMark("&sk_guanchao")
   if p:isAlive() and (p:getMark("sk_guanchao_down") == 0 and n > old or p:getMark("sk_guanchao_down") > 0 and n < old) then
    table.insert(names, skill:objectName()); table.insert(owners, p:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; local c = ctx.original_data:toCardUse().card
  local n = c:getNumber(); room:setPlayerMark(owner, "&sk_guanchao", n)
  if n == 13 then room:setPlayerMark(owner, "sk_guanchao_down", 1)
  elseif n == 1 then room:setPlayerMark(owner, "sk_guanchao_down", 0) end
  if room:getDrawPile():isEmpty() then room:swapPile() end
  local pool = {}
  for _, id in sgs.qlist(room:getDrawPile()) do
   if sgs.Sanguosha:getCard(id):objectName() == c:objectName() then table.insert(pool, id) end
  end
  local ids = sgs.IntList()
  for i = 1, math.min((n == 1 or n == 13) and 2 or 1, #pool) do
   local id = table.remove(pool, math.random(#pool)); ids:append(id)
   room:setCardFlag(sgs.Sanguosha:getCard(id), "sk_guanchao_temp")
  end
  if not ids:isEmpty() then
   local dummy = sgs.DummyCard(ids); room:obtainCard(owner, dummy, false); dummy:deleteLater()
  end
  return false
 end,
}
sk_xunxian = sgs.CreateTriggerSkillV2{
 name = "sk_xunxian", global = true, events = {sgs.TargetConfirming, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_xunxian_used", 0) end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.TargetConfirming or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getMark("sk_xunxian_used") > 0 then return false end
  local use = data:toCardUse(); local c = use.card
  if c and c:getNumber() > 0 and (c:isKindOf("Slash") or c:isNDTrick()) and use.to:contains(player) then
   for _, p in sgs.qlist(room:getAlivePlayers()) do if not use.to:contains(p) then return skill:objectName() end end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local use = ctx.original_data:toCardUse(); local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getAlivePlayers()) do if not use.to:contains(p) then targets:append(p) end end
  local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@sk_xunxian", true, true)
  if not target then return false end
  ctx.targets:append(target); room:setPlayerMark(player, "sk_xunxian_used", 1); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.targets:first(); local use = ctx.original_data:toCardUse(); local n = use.card:getNumber()
  local pattern = ".|.|"
  if n == 1 then pattern = pattern .. "2~13" elseif n == 13 then pattern = pattern .. "1~12"
  else pattern = pattern .. "1~" .. (n - 1) .. "," .. (n + 1) .. "~13" end
  local card = room:askForCard(target, pattern, "@sk_xunxian-give:" .. player:objectName(), ctx.original_data, sgs.Card_MethodNone)
  if card then room:obtainCard(player, card, false)
  else
   use.to = sgs.SPlayerList(); use.to:append(target); ctx.original_data:setValue(use)
   room:getThread():trigger(sgs.TargetConfirming, room, target, ctx.original_data)
  end
  return false
 end,
}
sk_yanjun:addSkill(sk_guanchao)
sk_yanjun:addSkill(sk_xunxian)
sgs.LoadTranslationTable{
 ["sk_yanjun"] = "SK严畯", ["&sk_yanjun"] = "严畯", ["#sk_yanjun"] = "严畯",
 ["sk_guanchao"] = "观潮",
 [":sk_guanchao"] = "当一名角色使用的牌结算后，若此牌点数大于记录点数，你记录此牌点数，然后你获得一张同名临时牌，若记录点数为A或K，你额外获得一张。当你记录点数后，若为K/A，你将此技能中的“大于”/“小于”换为另一个，并从点数K/A重新记录。",
 ["sk_xunxian"] = "逊贤", ["@sk_xunxian"] = "逊贤", ["@sk_xunxian-give"] = "逊贤",
 [":sk_xunxian"] = "每回合限一次，当你成为有点数的【杀】或普通锦囊牌的目标时，你可以令一名不是此牌目标的角色选择一项：1.交给你一张点数小于或大于此牌的牌；2.其成为此牌的唯一目标。",
}

-- 极略61 留赞：jilue.md L2771
sk_liuzan = sgs.General(extension, "sk_liuzan", "wu", 4)
sk_fenyin = sgs.CreateTriggerSkillV2{
 name = "sk_fenyin", global = true, events = {sgs.CardUsed, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    room:setPlayerMark(p, "sk_fenyin_previous", 0)
    for suit = sgs.Card_Spade, sgs.Card_NoSuit do room:setPlayerMark(p, "sk_fenyin_seen_" .. suit, 0) end
   end
  elseif event == sgs.CardUsed and player then
   local use = ctx.original_data:toCardUse(); local c = use.card
   if not c then return end
   room:setCardFlag(c, "-sk_fenyin_first"); room:setCardFlag(c, "-sk_fenyin_same"); room:setCardFlag(c, "-sk_fenyin_different")
   local suit = c:getSuit(); local previous = player:getMark("sk_fenyin_previous")
   if use.m_isHandcard then
    if player:getMark("sk_fenyin_seen_" .. suit) == 0 then room:setCardFlag(c, "sk_fenyin_first") end
    room:setPlayerMark(player, "sk_fenyin_seen_" .. suit, 1)
    if previous > 0 then room:setCardFlag(c, previous == suit + 1 and "sk_fenyin_same" or "sk_fenyin_different") end
   end
   room:setPlayerMark(player, "sk_fenyin_previous", suit + 1)
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.CardUsed or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  local c = data:toCardUse().card
  if c and (c:hasFlag("sk_fenyin_first") or c:hasFlag("sk_fenyin_same") or c:hasFlag("sk_fenyin_different")) then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local c = ctx.original_data:toCardUse().card
  local first, same, different = c:hasFlag("sk_fenyin_first"), c:hasFlag("sk_fenyin_same"), c:hasFlag("sk_fenyin_different")
  if first then
   local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sk_fenyin", true, true)
   if target then local damage = sgs.DamageStruct(); damage.from = player; damage.to = target; damage.damage = 1; damage.reason = skill:objectName(); room:damage(damage) end
  end
  if player:isAlive() then
   if same then room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
   elseif different then player:drawCards(1, skill:objectName()) end
  end
  return false
 end,
}
sk_liuzan:addSkill(sk_fenyin)
sgs.LoadTranslationTable{
 ["sk_liuzan"] = "SK留赞", ["&sk_liuzan"] = "留赞", ["#sk_liuzan"] = "留赞",
 ["sk_fenyin"] = "奋音", ["@sk_fenyin"] = "奋音",
 [":sk_fenyin"] = "当你每回合首次使用一种花色的手牌后，你可以对一名其他角色造成1点伤害。当你使用一张手牌后，若此牌与你本回合使用的上一张牌花色：相同，你弃置一张牌；不同，你摸一张牌。",
}

-- 极略62 胡金定：jilue.md L2775
sk_hujinding = sgs.General(extension, "sk_hujinding", "shu", 3, false)
local function sk_qingyuan_target(room, owner)
 for _, p in sgs.qlist(room:getAllPlayers(true)) do
  if p:getMark("&sk_qingyuan") > 0 and p:getMark("sk_qingyuan_owner_" .. owner:objectName()) > 0 then return p end
 end
end
local function sk_qingyuan_remove(room, owner, target, punish)
 local count = target:getMark("sk_qingyuan_count")
 room:setPlayerMark(target, "&sk_qingyuan", 0)
 room:setPlayerMark(target, "sk_qingyuan_count", 0)
 room:setPlayerMark(target, "sk_qingyuan_owner_" .. owner:objectName(), 0)
 if punish and target:isAlive() then
  local n = math.min(count, owner:getMaxHp()); if n > 0 then room:loseHp(target, n) end
 end
end
sk_qingyuan = sgs.CreateTriggerSkillV2{
 name = "sk_qingyuan", global = true,
 events = {sgs.RoundStart, sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.QuitDying},
 can_trigger = function(skill, event, room, player, data)
  local names, owners = {}, {}
  for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   local target = sk_qingyuan_target(room, owner); local eligible = false
   if event == sgs.RoundStart then
    for _, p in sgs.qlist(room:getOtherPlayers(owner)) do if p:getMark("&sk_qingyuan") == 0 then eligible = true end end
   elseif target and event == sgs.CardsMoveOneTime then
    local move = data:toMoveOneTime()
    eligible = move.to and move.to:objectName() == target:objectName() and not move.card_ids:isEmpty() and move.reason.m_skillName ~= skill:objectName()
   elseif target and event == sgs.EventPhaseChanging then
    eligible = player == target and data:toPhaseChange().to == sgs.Player_NotActive
   elseif target and event == sgs.QuitDying then eligible = player == owner end
   if owner:isAlive() and eligible then table.insert(names, skill:objectName()); table.insert(owners, owner:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  if event ~= sgs.RoundStart then return true end
  local owner = ctx.invoker or player; local targets = sgs.SPlayerList()
  for _, p in sgs.qlist(room:getOtherPlayers(owner)) do if p:getMark("&sk_qingyuan") == 0 then targets:append(p) end end
  local target = room:askForPlayerChosen(owner, targets, skill:objectName(), "@sk_qingyuan", true, true)
  if not target then return false end
  ctx.targets:append(target); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  if event == sgs.RoundStart then
   local target = ctx.targets:first()
   for _, p in sgs.qlist(room:getAllPlayers(true)) do
    if p:getMark("&sk_qingyuan") > 0 then
     for _, old in sgs.qlist(room:getAllPlayers(true)) do
      if p:getMark("sk_qingyuan_owner_" .. old:objectName()) > 0 then sk_qingyuan_remove(room, old, p, false) end
     end
    end
   end
   room:setPlayerMark(target, "&sk_qingyuan", 1)
   room:setPlayerMark(target, "sk_qingyuan_owner_" .. owner:objectName(), 1)
   room:setPlayerMark(target, "sk_qingyuan_count", 0)
  else
   local target = sk_qingyuan_target(room, owner)
   if not target then return false end
   if event == sgs.CardsMoveOneTime then
    owner:drawCards(1, skill:objectName())
    if owner:isAlive() and target:isAlive() and sk_qingyuan_target(room, owner) == target and owner:getHandcardNum() <= target:getHandcardNum() and not target:isNude() then
     local id = room:askForCardChosen(owner, target, "he", skill:objectName())
     room:addPlayerMark(target, "sk_qingyuan_count")
     room:obtainCard(owner, id, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, owner:objectName(), target:objectName(), skill:objectName(), ""), false)
    end
   else sk_qingyuan_remove(room, owner, target, true) end
  end
  return false
 end,
}
sk_zhongshenVS = sgs.CreateViewAsSkillV2{
 name = "sk_zhongshen", n = 1, response_or_use = true,
 can_activate = function(skill, request)
  local p = request:getInitiator()
  if p:hasFlag("Global_PreventPeach") then return false end
  if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return p:isWounded() end
  return string.find(request:getPattern(), "peach", 1, true) ~= nil
 end,
 can_select_card = function(skill, request, card)
  return request:getSelectedCardIds():isEmpty() and card:isRed()
 end,
 card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 1 end,
 create_card = function(skill, request)
  local material = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
  local c = sgs.Sanguosha:cloneCard("peach", material:getSuit(), material:getNumber())
  c:addSubcards(request:getSelectedCardIds()); c:setSkillName("sk_zhongshen"); return c
 end,
}
sk_zhongshen = sgs.CreateTriggerSkillV2{
 name = "sk_zhongshen", view_as_skill = sk_zhongshenVS, events = {sgs.CardFinished},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_NotActive then return false end
  local c = data:toCardUse().card
  if c and c:getSkillName() == skill:objectName() and not room:getOtherPlayers(player):isEmpty() then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sk_zhongshen", true, true)
  if not target then return false end
  ctx.targets:append(target); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local c = ctx.original_data:toCardUse().card
  room:obtainCard(ctx.targets:first(), c, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), ctx.targets:first():objectName(), skill:objectName(), ""), true)
  return false
 end,
}
sk_hujinding:addSkill(sk_qingyuan)
sk_hujinding:addSkill(sk_zhongshen)
sgs.LoadTranslationTable{
 ["sk_hujinding"] = "SK胡金定", ["&sk_hujinding"] = "胡金定", ["#sk_hujinding"] = "胡金定",
 ["sk_qingyuan"] = "轻缘", ["@sk_qingyuan"] = "轻缘",
 [":sk_qingyuan"] = "每轮开始时，你可以选择一名未拥有“轻缘”标记的其他角色，令其获得此标记（若场上已存在此标记，则改为移动之）。当拥有此标记的角色（不以此法）获得牌后，你摸一张牌，然后若你的手牌不多于该角色，你获得其一张牌。该角色的回合结束时，或当你脱离濒死状态时，其失去此标记并失去X点体力（X为其获得此标记后你以此法获得其牌的次数，且至多为你的体力上限）。",
 ["sk_zhongshen"] = "重身", ["@sk_zhongshen"] = "重身",
 [":sk_zhongshen"] = "你可以将红色牌当【桃】使用，当你于回合外以此法使用牌后，你可以将此牌交给一名其他角色。",
}

-- 极略62 马岱：jilue.md L2777
sk_madai = sgs.General(extension, "sk_madai", "shu", 4, true)
local function sk_qianxi_refresh(room)
 for _, target in sgs.qlist(room:getAllPlayers(true)) do
  local red, black = false, false
  for _, owner in sgs.qlist(room:getAlivePlayers()) do
   if owner:getMark("sk_qianxi_active") > 0 and owner:distanceTo(target) == 1 then
    red = red or owner:getMark("sk_qianxi_color") == 1
    black = black or owner:getMark("sk_qianxi_color") == 2
   end
  end
  for _, entry in ipairs({{"red", red}, {"black", black}}) do
   local mark = "sk_qianxi_limit_" .. entry[1]
   if entry[2] and target:getMark(mark) == 0 then
    room:setPlayerCardLimitation(target, "use", ".|" .. entry[1] .. "|.|hand", false, "sk_qianxi")
    room:setPlayerMark(target, mark, 1)
   elseif not entry[2] and target:getMark(mark) > 0 then
    room:removePlayerCardLimitation(target, "use", ".|" .. entry[1] .. "|.|hand$0", "sk_qianxi")
    room:setPlayerMark(target, mark, 0)
   end
  end
 end
end
sk_qianxiCard = sgs.CreateSkillCard{
 name = "sk_qianxiCard", target_fixed = true,
 on_use = function(self, room, source, targets)
  room:setPlayerMark(source, "sk_qianxi_phase_used", 1)
  source:drawCards(2, "sk_qianxi")
  if not source:isAlive() or source:isKongcheng() then return end
  local c = room:askForCard(source, ".|.|.|hand", "@sk_qianxi", sgs.QVariant(), sgs.Card_MethodNone)
  if not c then c = source:getHandcards():first() end
  room:showCard(source, c:getEffectiveId())
  source:setTag("sk_qianxi_name", sgs.QVariant(c:objectName()))
  room:setPlayerMark(source, "sk_qianxi_color", c:isRed() and 1 or (c:isBlack() and 2 or 0))
  room:setPlayerMark(source, "sk_qianxi_active", 1)
  room:setPlayerMark(source, "sk_qianxi_same", source:getMark("sk_qianxi_used_" .. c:objectName() .. "-Clear") > 0 and 1 or 0)
  sk_qianxi_refresh(room)
 end,
}
sk_qianxiVS = sgs.CreateViewAsSkillV2{
 name = "sk_qianxi", n = 0,
 can_activate = function(skill, request)
  return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():getMark("sk_qianxi_phase_used") == 0
 end,
 create_card = function() return sk_qianxiCard:clone() end,
}
sk_qianxi = sgs.CreateTriggerSkillV2{
 name = "sk_qianxi", view_as_skill = sk_qianxiVS, global = true,
 events = {sgs.CardUsed, sgs.CardResponded, sgs.ConfirmDamage, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.HpChanged, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart, sgs.MarkChanged, sgs.EventSkillValidityRestored, sgs.EventSkillInvalidated, sgs.GeneralTransformed},
 on_record = function(skill, event, room, player, ctx)
  local data = ctx.original_data
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_Play then room:setPlayerMark(player, "sk_qianxi_phase_used", 0) end
  if player then
   if event == sgs.CardUsed or event == sgs.CardResponded then
    local card
    if event == sgs.CardUsed then card = data:toCardUse().card
    else local response = data:toCardResponse(); if response.m_isUse then card = response.m_card end end
    if card then
     room:addPlayerMark(player, "sk_qianxi_used_" .. card:objectName() .. "-Clear")
     if player:getMark("sk_qianxi_active") > 0 and card:objectName() == player:getTag("sk_qianxi_name"):toString() then room:setPlayerMark(player, "sk_qianxi_same", 1) end
    end
   elseif event == sgs.EventPhaseChanging and player:getMark("sk_qianxi_active") > 0 then
    local change = data:toPhaseChange()
    if change.to == sgs.Player_Discard and player:getMark("sk_qianxi_same") == 0 then player:skip(sgs.Player_Discard) end
    if change.to == sgs.Player_NotActive then
     room:setPlayerMark(player, "sk_qianxi_active", 0); player:removeTag("sk_qianxi_name")
    end
   end
  end
  sk_qianxi_refresh(room)
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.ConfirmDamage then return false end
  local d = data:toDamage(); local owner = d.from
  if owner and owner:getMark("sk_qianxi_active") > 0 and d.card and d.card:objectName() == owner:getTag("sk_qianxi_name"):toString() and owner:distanceTo(d.to) == 1 then return skill:objectName(), owner:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  local d = ctx.original_data:toDamage(); d.damage = d.damage + 1; ctx.original_data:setValue(d); return false
 end,
}
sk_qianxiMod = sgs.CreateTargetModSkillV2{
 name = "#sk_qianxi", pattern = ".", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local p, c = ctx:getPrimary(), ctx:getCard()
  if p and c and p:getMark("sk_qianxi_active") > 0 and c:objectName() == p:getTag("sk_qianxi_name"):toString() and ctx:getModType() == sgs.TargetModSkill_Residue then return 9999 end
  return false
 end,
}
sk_madai:addSkill(sk_qianxi)
sk_madai:addSkill(sk_qianxiMod)
sk_madai:addSkill("sk_changqu")
extension:insertRelatedSkills("sk_qianxi", "#sk_qianxi")
sgs.LoadTranslationTable{
 ["sk_madai"] = "SK马岱", ["&sk_madai"] = "马岱", ["#sk_madai"] = "马岱",
 ["sk_qianxi"] = "潜袭", ["@sk_qianxi"] = "潜袭",
 [":sk_qianxi"] = "出牌阶段限一次，你可以摸两张牌并展示一张手牌，然后本回合内你获得以下效果：与你距离为1的角色不能使用与此牌颜色相同的手牌。你使用与此牌牌名相同的牌无次数限制且对距离为1的角色造成的伤害+1。若你本回合未使用与此牌牌名相同的牌，你跳过本回合弃牌阶段。",
}

-- 极略63 士燮：jilue.md L2781
sk_shixie = sgs.General(extension, "sk_shixie", "qun", 3, true)
local function sk_lixia_remember(player)
 for _, skill in sgs.qlist(player:getVisibleSkillList()) do player:setTag("sk_lixia_seen_" .. skill:objectName(), sgs.QVariant(true)) end
end
local function sk_lixia_choices(player, recipient, giving)
 local result = {}
 for _, skill in sgs.qlist(player:getVisibleSkillList()) do
  local name = skill:objectName()
  if (giving and name ~= "sk_lixia") or (not giving and not recipient:getTag("sk_lixia_seen_" .. name):toBool()) then table.insert(result, name) end
 end
 return result
end
sk_biluan = sgs.CreateTriggerSkillV2{
 name = "sk_biluan", events = {sgs.EventPhaseStart, sgs.Damaged, sgs.TurnStart},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.TurnStart and player then
   room:setPlayerMark(player, "sk_biluan_active", 0); room:setPlayerMark(player, "sk_biluan_draw", 0)
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() then return false end
  if event == sgs.Damaged and player:getMark("sk_biluan_draw") > 0 then return skill:objectName() end
  if event == sgs.EventPhaseStart and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isNude() then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  if event == sgs.Damaged then return true end
  return room:askForCard(player, "..", "@sk_biluan", ctx.original_data, sgs.Card_MethodDiscard) ~= nil
 end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.Damaged then
   room:setPlayerMark(player, "sk_biluan_draw", 0); player:drawCards(room:alivePlayerCount(), skill:objectName())
  else room:setPlayerMark(player, "sk_biluan_active", 1); room:setPlayerMark(player, "sk_biluan_draw", 1) end
  return false
 end,
}
sk_biluanDist = sgs.CreateDistanceSkillV2{
 name = "#sk_biluan", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local target = ctx:getSecondary()
  if target and target:getMark("sk_biluan_active") > 0 then return target:aliveCount() end
  return false
 end,
}
sk_lixia = sgs.CreateTriggerSkillV2{
 name = "sk_lixia", global = true, events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventPhaseStart},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.GameStart then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do sk_lixia_remember(p) end
  elseif event == sgs.EventAcquireSkill and player then
   player:setTag("sk_lixia_seen_" .. ctx.original_data:toSkillChange().skillName, sgs.QVariant(true))
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.EventPhaseStart or not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Finish then return false end
  local names, owners = {}, {}
  for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if owner:isAlive() and owner ~= player and not player:inMyAttackRange(owner) and #sk_lixia_choices(owner, player, true) > 0 and #sk_lixia_choices(player, owner, false) > 0 then
    table.insert(names, skill:objectName()); table.insert(owners, owner:objectName())
   end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  return room:askForSkillInvoke(owner, skill:objectName(), sgs.QVariant(player))
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  sk_lixia_remember(owner)
  local gifts = sk_lixia_choices(owner, player, true)
  if #gifts == 0 then return false end
  local gift = room:askForChoice(owner, skill:objectName(), table.concat(gifts, "+"), sgs.QVariant(player))
  room:detachSkillFromPlayer(owner, gift); room:acquireSkill(player, gift)
  local returns = sk_lixia_choices(player, owner, false)
  if #returns == 0 then return false end
  local received = room:askForChoice(player, skill:objectName(), table.concat(returns, "+"), sgs.QVariant(owner))
  room:detachSkillFromPlayer(player, received); room:acquireSkill(owner, received)
  return false
 end,
}
sk_shixie:addSkill(sk_biluan)
sk_shixie:addSkill(sk_biluanDist)
sk_shixie:addSkill(sk_lixia)
extension:insertRelatedSkills("sk_biluan", "#sk_biluan")
sgs.LoadTranslationTable{
 ["sk_shixie"] = "SK士燮", ["&sk_shixie"] = "士燮", ["#sk_shixie"] = "士燮",
 ["sk_biluan"] = "避乱", ["@sk_biluan"] = "避乱",
 [":sk_biluan"] = "结束阶段你可以弃置一张牌，若如此做，直到你的下一个回合开始，其他角色与你的距离+X，且当你下次受到伤害后，你摸X张牌（X为存活角色数）。",
 ["sk_lixia"] = "礼下",
 [":sk_lixia"] = "其他角色的结束阶段，若你不在其攻击范围内且该角色拥有你未获得过的技能，你可以将一个其他技能交给该角色，然后令其交给你一个你未获得过的技能。",
}

-- 极略63 张琪瑛：jilue.md L2781
sk_zhangqiying = sgs.General(extension, "sk_zhangqiying", "qun", 3, false)
local function sk_falu_library(player)
 local text = player:getTag("sk_falu_library"):toString()
 return text == "" and {} or text:split("+")
end
local function sk_falu_reserve(room, player, count)
 local present, pool, known = {}, {}, {}
 for _, p in sgs.qlist(room:getAllPlayers(true)) do present[p:getGeneralName()] = true; present[p:getGeneral2Name()] = true end
 local library = sk_falu_library(player)
 for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
  local general = sgs.Sanguosha:getGeneral(name)
  if general and general:getKingdom() == "qun" and not present[name] then
   for _, skill in sgs.qlist(general:getVisibleSkillList()) do
    local skill_name = skill:objectName()
    if not known[skill_name] then known[skill_name] = true; table.insert(pool, skill_name) end
   end
  end
 end
 for i = 1, count do
  if #pool == 0 or not player:isAlive() then break end
  local chosen = room:askForChoice(player, "sk_falu_reserve", table.concat(pool, "+"))
  table.insert(library, chosen)
 end
 player:setTag("sk_falu_library", sgs.QVariant(table.concat(library, "+")))
end
local function sk_falu_give(room, owner, target, count, skill_name)
 for i = 1, count do
  local library = sk_falu_library(owner)
  if #library == 0 or not target:isAlive() then break end
  local chosen = room:askForChoice(owner, skill_name, table.concat(library, "+"), sgs.QVariant(target))
  room:acquireSkill(target, chosen)
 end
end
sk_falu = sgs.CreateTriggerSkillV2{
 name = "sk_falu", frequency = sgs.Skill_Compulsory, events = {sgs.GameStart, sgs.CardsMoveOneTime},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
  if event == sgs.GameStart then return skill:objectName() end
  local move = data:toMoveOneTime()
  if not move.from or move.from:objectName() ~= player:objectName() or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) then return false end
  local count = 0
  for _, place in sgs.qlist(move.from_places) do if place == sgs.Player_PlaceHand then count = count + 1 end end
  if count == 1 then return skill:objectName() end
  return false
 end,
 on_cost = function() return true end,
 on_effect = function(skill, event, room, player, ctx)
  if event == sgs.GameStart then sk_falu_reserve(room, player, 3); return false end
  local move = ctx.original_data:toMoveOneTime(); local card
  for i = 0, move.card_ids:length() - 1 do
   if move.from_places:at(i) == sgs.Player_PlaceHand then card = sgs.Sanguosha:getCard(move.card_ids:at(i)); break end
  end
  if not card then return false end
  room:addPlayerMark(player, "sk_falu_count")
  if card:isRed() then room:addPlayerMark(player, "sk_falu_red") elseif card:isBlack() then room:addPlayerMark(player, "sk_falu_black") end
  if player:getMark("sk_falu_count") < 3 then return false end
  local red, black = player:getMark("sk_falu_red"), player:getMark("sk_falu_black")
  room:setPlayerMark(player, "sk_falu_count", 0); room:setPlayerMark(player, "sk_falu_red", 0); room:setPlayerMark(player, "sk_falu_black", 0)
  player:drawCards(2, skill:objectName())
  if not player:isAlive() then return false end
  if black == 3 then
   local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_falu_damage")
   local d = sgs.DamageStruct(); d.from = player; d.to = target; d.damage = 2; d.nature = sgs.DamageStruct_Thunder; d.reason = skill:objectName(); room:damage(d)
  elseif red == 3 then
   if #sk_falu_library(player) > 0 then
    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_falu_give")
    sk_falu_give(room, player, target, 1, "sk_falu_give")
   end
  else sk_falu_reserve(room, player, 2) end
  return false
 end,
}
sk_zhenyi = sgs.CreateTriggerSkillV2{
 name = "sk_zhenyi", global = true, events = {sgs.DamageInflicted, sgs.TurnStart, sgs.EventPhaseChanging},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseChanging and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
   for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, "sk_zhenyi_used", 0); room:setPlayerMark(p, "sk_dianhua_used", 0) end
  elseif event == sgs.TurnStart and player then
   local text = player:getTag("sk_zhenyi_restore"):toString()
   player:removeTag("sk_zhenyi_restore")
   if text ~= "" then for _, name in ipairs(text:split("+")) do room:acquireSkill(player, name) end end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event ~= sgs.DamageInflicted or not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getMark("sk_zhenyi_used") > 0 or player:isKongcheng() then return false end
  local d = data:toDamage()
  if d.from and d.from ~= player then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  room:setPlayerMark(player, "sk_zhenyi_used", 1)
  local card = room:askForCard(player, ".|.|.|hand", "@sk_zhenyi", ctx.original_data, sgs.Card_MethodDiscard)
  if not card then room:setPlayerMark(player, "sk_zhenyi_used", 0); return false end
  ctx.extra_data = sgs.QVariant(card:getSuit() == sgs.Card_Spade)
  return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local source = ctx.original_data:toDamage().from
  if ctx.extra_data:toBool() and source and source:isAlive() and not source:getVisibleSkillList():isEmpty() and room:askForSkillInvoke(player, "sk_zhenyi_remove", sgs.QVariant(source)) then
   local skills = sgs.QList2Table(source:getVisibleSkillList()); local chosen = skills[math.random(#skills)]:objectName()
   local id = room:detachSkillFromPlayer(source, chosen)
   if id > 0 then
    local text = source:getTag("sk_zhenyi_restore"):toString()
    source:setTag("sk_zhenyi_restore", sgs.QVariant(text == "" and chosen or text .. "+" .. chosen))
   end
  end
  return true
 end,
}
-- 引擎没有取得前事件；用取得通知立即撤回该 exact instance，再替换。
sk_dianhua = sgs.CreateTriggerSkillV2{
 name = "sk_dianhua", global = true, events = {sgs.EventAcquireSkill},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() then return false end
  local names, owners = {}, {}
  for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
   if owner:isAlive() and owner:getMark("sk_dianhua_used") == 0 and not owner:isKongcheng() and #sk_falu_library(owner) > 0 then table.insert(names, skill:objectName()); table.insert(owners, owner:objectName()) end
  end
  if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player
  local change = ctx.original_data:toSkillChange()
  if owner:getMark("sk_dianhua_used") > 0 or #sk_falu_library(owner) == 0 or not player:hasSkillInstance(change.skillName, change.instanceID) then return false end
  room:setPlayerMark(owner, "sk_dianhua_used", 1)
  local card = room:askForCard(owner, ".|heart|.|hand", "@sk_dianhua:" .. player:objectName(), ctx.original_data, sgs.Card_MethodDiscard)
  if not card then room:setPlayerMark(owner, "sk_dianhua_used", 0); return false end
  return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local owner = ctx.invoker or player; local change = ctx.original_data:toSkillChange()
  if room:detachSkillFromPlayer(player, change.skillName .. "#" .. change.instanceID) == 0 then return false end
  local options = {}
  for i = 1, 3 do table.insert(options, tostring(i)) end
  if #options > 0 then
   local count = tonumber(room:askForChoice(owner, "sk_dianhua_count", table.concat(options, "+"), sgs.QVariant(player)))
   sk_falu_give(room, owner, player, count, skill:objectName())
  end
  return false
 end,
}
sk_zhangqiying:addSkill(sk_falu)
sk_zhangqiying:addSkill(sk_zhenyi)
sk_zhangqiying:addSkill(sk_dianhua)
sgs.LoadTranslationTable{
 ["sk_zhangqiying"] = "SK张琪瑛", ["&sk_zhangqiying"] = "张琪瑛", ["#sk_zhangqiying"] = "张琪瑛",
 ["sk_falu"] = "法箓", ["sk_falu_reserve"] = "法箓", ["sk_falu_damage"] = "法箓", ["sk_falu_give"] = "法箓",
 [":sk_falu"] = "锁定技，游戏开始时，你获得三个已拥有且未上场的群势力储备技能。当你仅失去一张手牌后，记录此牌的颜色，然后若记录数为3，你移除所有记录，摸两张牌，再根据移除的颜色执行效果：均为黑色，对一名角色造成2点雷电伤害；均为红色，令一名角色获得你储备技能中的一个技能；否则你获得两个已拥有且未上场的群势力储备技能。",
 ["sk_zhenyi"] = "真仪", ["@sk_zhenyi"] = "真仪", ["sk_zhenyi_remove"] = "真仪",
 [":sk_zhenyi"] = "每回合限一次，当你受到其他角色造成的伤害时，你可以弃置一张手牌防止之；然后若你以此法弃置黑桃牌，你可以令其随机失去一个技能，该角色于其下个回合开始时获得之。",
 ["sk_dianhua"] = "点化", ["@sk_dianhua"] = "点化", ["sk_dianhua_count"] = "点化",
 [":sk_dianhua"] = "每回合限一次，当一名角色获得技能前，你可以弃置一张红桃手牌，将此效果改为从你的储备技能中获得一至三个技能。",
}

-- 极略67 周鲂：jilue.md L2796-L2799（技能原文 L2798）
sk_zhoufang = sgs.General(extension, "sk_zhoufang", "wu", 3)
local function sk_duanfa_is_temp(card)
 for _, flag in sgs.qlist(card:getFlags()) do
  if flag:match("_temp$") then return true end
 end
 return false
end
local function sk_duanfa_resolve(room, player)
 player:drawCards(2, "sk_duanfa")
 if not player:isAlive() then return end
 local ids = sgs.IntList()
 for _, card in sgs.qlist(player:getHandcards()) do
  if card:isBlack() and not sk_duanfa_is_temp(card) then ids:append(card:getEffectiveId()) end
 end
 local count = ids:length()
 if count == 0 then return end
 local dummy = sgs.DummyCard(ids)
 room:throwCard(dummy, player, player); dummy:deleteLater()
 if not player:isAlive() then return end
 player:drawCards(count, "sk_duanfa")
 if not player:isAlive() then return end
 -- 用牌堆实体承载临时牌，不受牌堆中现有顺手牵羊数量限制。
 local materials = room:getNCards(count, false)
 local temporary = room:getTag("sk_duanfa_temporary"):toIntList()
 for _, id in sgs.qlist(materials) do temporary:append(id) end
 local tag = sgs.QVariant(); tag:setValue(temporary); room:setTag("sk_duanfa_temporary", tag)
 if not materials:isEmpty() then
  local gain = sgs.DummyCard(materials); room:obtainCard(player, gain, false); gain:deleteLater()
 end
end
sk_duanfaCard = sgs.CreateSkillCard{
 name = "sk_duanfaCard", target_fixed = true,
 on_use = function(self, room, source, targets)
  room:setPlayerMark(source, "sk_duanfa_phase_used", 1)
  sk_duanfa_resolve(room, source)
 end,
}
sk_duanfaVS = sgs.CreateViewAsSkillV2{
 name = "sk_duanfa", n = 0,
 can_activate = function(skill, request)
  return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():getMark("sk_duanfa_phase_used") == 0
 end,
 create_card = function() return sk_duanfaCard:clone() end,
}
sk_duanfa = sgs.CreateTriggerSkillV2{
 name = "sk_duanfa", view_as_skill = sk_duanfaVS, global = true,
 events = {sgs.GameStart, sgs.EventPhaseStart, sgs.CardsMoveOneTime},
 on_record = function(skill, event, room, player, ctx)
  if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_Play then
   room:setPlayerMark(player, "sk_duanfa_phase_used", 0)
  elseif event == sgs.CardsMoveOneTime then
   local move = ctx.original_data:toMoveOneTime()
   local temporary = room:getTag("sk_duanfa_temporary"):toIntList()
   local ids = sgs.IntList()
   for _, id in sgs.qlist(move.card_ids) do
    if temporary:contains(id) then
     if move.to_place == sgs.Player_DiscardPile and room:getCardPlace(id) == sgs.Player_DiscardPile then
      temporary:removeOne(id); ids:append(id)
      room:setCardFlag(sgs.Sanguosha:getCard(id), "-sk_duanfa_temp")
     else
      -- 移入手牌时引擎会重设改名牌，须在移牌通知恢复临时牌面。
      local card = sgs.Sanguosha:getCard(id)
      local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
      local wrapped = sgs.Sanguosha:getWrappedCard(id)
      wrapped:takeOver(snatch)
      room:broadcastUpdateCard(room:getAllPlayers(true), id, wrapped)
      room:setCardFlag(wrapped, "sk_duanfa_temp")
     end
    end
   end
   local temp_tag = sgs.QVariant(); temp_tag:setValue(temporary); room:setTag("sk_duanfa_temporary", temp_tag)
   if not ids:isEmpty() then
    local broken = room:getTag("BreakCard"):toIntList()
    for _, id in sgs.qlist(ids) do broken:append(id) end
    local tag = sgs.QVariant(); tag:setValue(broken); room:setTag("BreakCard", tag)
    room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
     sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "BreakCard", "")), true)
   end
  end
 end,
 can_trigger = function(skill, event, room, player, data)
  if event == sgs.GameStart and player and player:isAlive() and player:hasSkill(skill:objectName()) then return skill:objectName() end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  return room:askForSkillInvoke(player, skill:objectName())
 end,
 on_effect = function(skill, event, room, player, ctx)
  sk_duanfa_resolve(room, player); return false
 end,
}
sk_duanfaMod = sgs.CreateTargetModSkillV2{
 name = "#sk_duanfa", pattern = "Snatch", holder_selector = sgs.CorrectSkill_System,
 correct_func = function(skill, ctx)
  local card = ctx:getCard()
  if card and card:hasFlag("sk_duanfa_temp") and ctx:getModType() == sgs.TargetModSkill_DistanceLimit then return 9999 end
  return false
 end,
}
sk_youdi = sgs.CreateTriggerSkillV2{
 name = "sk_youdi", events = {sgs.EventPhaseStart},
 can_trigger = function(skill, event, room, player, data)
  if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) or player:getPhase() ~= sgs.Player_Finish or player:isKongcheng() then return false end
  for _, other in sgs.qlist(room:getOtherPlayers(player)) do
   if other:canDiscard(player, "h") then return skill:objectName() end
  end
  return false
 end,
 on_cost = function(skill, event, room, player, ctx)
  local candidates = sgs.SPlayerList()
  for _, other in sgs.qlist(room:getOtherPlayers(player)) do if other:canDiscard(player, "h") then candidates:append(other) end end
  local target = room:askForPlayerChosen(player, candidates, skill:objectName(), "@sk_youdi", true, true)
  if not target then return false end
  ctx.extra_data = sgs.QVariant(target); return true
 end,
 on_effect = function(skill, event, room, player, ctx)
  local target = ctx.extra_data:toPlayer()
  if not target or not target:isAlive() or not target:canDiscard(player, "h") then return false end
  local id = room:askForCardChosen(target, player, "h", skill:objectName(), false, sgs.Card_MethodDiscard)
  local card = sgs.Sanguosha:getCard(id)
  local black, slash = card:isBlack(), card:isKindOf("Slash")
  room:throwCard(id, player, target)
  if not player:isAlive() then return false end
  if not black then player:drawCards(1, skill:objectName()) end
  if not slash and player:isAlive() and target:isAlive() and not target:isNude() then
   local gained = room:askForCardChosen(player, target, "he", skill:objectName())
   room:obtainCard(player, gained, false)
  end
  return false
 end,
}
sk_zhoufang:addSkill(sk_duanfa)
sk_zhoufang:addSkill(sk_duanfaMod)
sk_zhoufang:addSkill(sk_youdi)
extension:insertRelatedSkills("sk_duanfa", "#sk_duanfa")
sgs.LoadTranslationTable{
 ["sk_zhoufang"] = "SK周鲂", ["&sk_zhoufang"] = "周鲂", ["#sk_zhoufang"] = "周鲂",
 ["sk_duanfa"] = "断发",
 [":sk_duanfa"] = "游戏开始时，或出牌阶段限一次，你可以摸两张牌，然后弃置所有黑色非临时手牌并摸等量的牌，若如此做，你获得X张无距离限制的临时【顺手牵羊】（X为你本次发动此技能弃置的黑色牌数）。",
 ["sk_youdi"] = "诱敌", ["@sk_youdi"] = "诱敌",
 [":sk_youdi"] = "结束阶段，你可以令一名其他角色弃置你的一张手牌：若此牌：不为黑色，你摸一张牌；不是【杀】，你获得其一张牌。",
}

return {extension}
