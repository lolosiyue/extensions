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
sk_shanxi = sgs.CreateProhibitSkill{
    name = "sk_shanxi",
	is_prohibited = function(self, from, to, card)
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
				if move.from and move.from:isAlive() and move.to_place == sgs.Player_DiscardPile then
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
	[":sk_fushe"] = "其他角色的出牌阶段开始时，若其在你的攻击范围内，你可以选择一种花色。若如此做，此阶段结束时，若其有此花色的牌进入弃牌堆，你对其造成1点伤害"..
	"，然后摸一张牌。",
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
	[":sk_zhaoxin"] = "当你受到伤害后，你可以展示所有手牌，然后摸X张牌（X为缺少的花色数）。",
	["$sk_zhaoxin1"] = "就让我大大方方地告诉你。",
	["$sk_zhaoxin2"] = "路人既知，又待如何？",
	["sk_zhihe"] = "制合",
	[":sk_zhihe"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示所有手牌，并将每种花色的牌弃置至1张，然后将手牌数翻倍。"..
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
			elseif player:getPhase() == sgs.Player_Play and player:hasFlag("yexi_redslash_ready") then
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
						room:setPlayerFlag(chosen, "yexi_blackslash_buff")
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
			elseif target:getPhase() == sgs.Player_Play and target:hasFlag("yexi_redslash_ready") then
				room:setPlayerFlag(target, "-yexi_redslash_ready")
				room:setPlayerFlag(target, "yexi_redslash_buff")
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
	    local n = math.max(1, player:getHp())
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
	[":sk_sijian"] = "当你失去所有手牌后，你可以弃置一名其他角色的X张牌（X为你的体力值，至少为1）。",
	["$sk_sijian"] = "臣愿以死谏言！",
	["@sijian-target"] = "你可选择一名其他角色，然后弃置其等同于你的体力值数（至少为1）的牌。",
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
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.EventAcquireSkill, sgs.EventLoseSkill},
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
		elseif event == sgs.CardUsed then
			local quancong = room:getCurrent()
			if not (quancong and quancong:isAlive() and quancong:hasSkill(skill:objectName())) then
				return false
			end
			local use = data:toCardUse()
			local card = use.card
			if not card or card:getTypeId() == sgs.Card_TypeSkill then return false end
			if quancong:getPhase() ~= sgs.Player_Play then return false end
			if card:getSuitString() == "" or not use.from
				or use.from:objectName() ~= quancong:objectName() then
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
		if event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			local card = use.card
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
		elseif event == sgs.CardUsed then
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
	[":sk_diezhang"] = "出牌阶段，当你使用牌时，若此牌的点数大于本回合你上一张使用的牌，你可以摸一张牌。",
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
		if request:getSelectedCardIds():length() > 0 then
			return to_select and not to_select:isEquipped()
		end
		return true
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
	[":sk_suiji"] = "其他角色出牌阶段结束时，你可以交给其至少一张手牌，然后其将超出其体力值数量的手牌交给你。",
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
	"你使用一张【杀】。",
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
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		local card = use.card
		local source = use.from
		if not (source and card and card:isNDTrick()) then return false end
		if source:getSeat() == player:getSeat() then return false end
		if player:isKongcheng() then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
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
		local use = ctx.original_data:toCardUse()
		local source = use.from
		local card = use.card
		if not (source and card) then return false end
		local cc = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
		if not cc then return false end
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
			if effect.from:getSeat() ~= xianglang:getSeat() then
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
	[":sk_cangshu"] = "当其他角色使用非延时锦囊牌时，你可以交给其一张基本牌，然后获得此牌并令其无效。",
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
	events = {sgs.EventPhaseEnd},
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
	[":sk_lirang"] = "一名角色的准备阶段结束时，其可以将一张与所有“礼”花色均不同的手牌置于你的武将牌上，称为“礼”，然后摸1张牌。你可以将两张“礼”当【桃】使用。",
	["$sk_lirang1"] = "谦者，德之柄也；让者，礼之主也。",
	["$sk_lirang2"] = "礼节铭心，让则不争。",
	["@lirang_to"] = "你可以将一张手牌作为“礼”置于%src的武将牌上，然后摸一张牌。",
	["sk_xianshi"] = "贤士",
	["@xianshi-discard"] = "请展示所有手牌并弃置一张牌，否则你对%src造成的伤害-1。",
	["#XianshiProtect"] = "%from 的“<font color=\"yellow\"><b>贤士</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	["#XianshiReduce"] = "%from 的“<font color=\"yellow\"><b>贤士</b></font>”效果被触发，受到的伤害从 %arg 点减少至 %arg2 点",
	[":sk_xianshi"] = "每当你即将受到伤害时，你可以令伤害来源选择一项：展示所有手牌并弃置其中一张；或令此伤害-1。",
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
	[":sk_daoshi"] = "一名角色的回合结束阶段开始时，若其装备区有牌，其可以摸一张牌，然后将其装备区的一张牌交给你。",
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
				local liyan = room:findPlayersBySkillName(skill:objectName()):first()
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
	[":sk_caijie"] = "其他角色的准备阶段，若其手牌数不小于你，你可以与其拼点，若你赢，你摸两张牌；若你没赢，视为其对你使用一张【杀】。",
	["$sk_caijie"] = "吾才捷遍悟，孰谁能及？",
	["sk_jilei"] = "鸡肋",
	[":sk_jilei"] = "当你受到伤害后，你可以令伤害来源展示所有手牌并弃置其中类别相同且数量最多（或之一）的所有牌。",
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
	技能描述：你的回合内，你可以通过弃置一张牌来令你的手牌数等于体力值，视为使用一张基本牌；你的回合外，你可以通过摸一张牌来令你的手牌数等于体力值，视为使用
	一张基本牌。
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
	[":sk_zhengyi"] = "你的回合内，你可以通过弃置一张牌来令你的手牌数等于体力值，视为使用一张基本牌；你的回合外，你可以通过摸一张牌来令你的手牌数等于体力值，"..
	"视为使用一张基本牌。",
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
	技能描述：出牌阶段开始时，你可以展示一张【杀】，令此【杀】获得以下效果之一（进入弃牌堆后失效）：
	1. 此【杀】不计入每回合使用次数限制；
	2. 此【杀】无距离限制，且可以额外指定一个目标；
	3. 此【杀】造成的伤害+1。
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
	[":sk_jiwu"] = "出牌阶段开始时，你可以展示一张【杀】，令此【杀】获得以下效果之一（进入弃牌堆后失效）："..
	"\n1. 此【杀】不计入每回合使用次数限制；"..
	"\n2. 此【杀】无距离限制，且可以额外指定一个目标；"..
	"\n3. 此【杀】的伤害值+1。",
	["$sk_jiwu1"] = "这无双的血脉，由我继承！",
	["$sk_jiwu2"] = "哼，你们能逃得出去吗？！",
	["$sk_jiwu3"] = "接招吧！",
	["llq_jiwu_residue"] = "此【杀】不计入每回合使用次数限制",
	["llq_jiwu_ex"] = "此【杀】无距离限制，且可以额外指定一个目标",
	["llq_jiwu_damage"] = "此【杀】的伤害值+1",
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
	技能描述：当你成为其他角色使用的【杀】或非延时锦囊的目标后，你可以失去1点体力，令此牌对你无效，然后可弃置一张牌，令该角色展示所有手牌并弃置其中与之花色相同
	的牌，若其没有因此弃置牌，其失去1点体力。
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
	技能描述：准备阶段，若你已受伤，你可以声明一种牌的类别，然后从牌堆随机亮出一张此类别的牌，将之交给一名角色。回合结束阶段，若你的体力值为全场最少（或之一），
	你亦可以如此做。
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
		if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then return false end
		if player:getPhase() == sgs.Player_Finish then
			if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then return false end
		end
		return true
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
	[":sk_zhenlie"] = "当你成为其他角色使用的【杀】或非延时锦囊的目标后，你可以失去1点体力，令此牌对你无效，然后可弃置一张牌，令该角色展示所有手牌并弃置其中与"..
	"之花色相同的牌，若其没有因此弃置牌，其失去1点体力。",
	["$sk_zhenlie"] = "看看我的觉悟吧！",
	["@zhenlie-discard"] = "你可以弃置一张牌，令%src选择一项：展示所有手牌并弃置其中与之花色相同的牌，或失去1点体力",
	["throwallsuitcards"] = "弃置全部与之花色相同的手牌",
	["lose1hp"] = "失去1点体力",
	["sk_miji"] = "秘计",
	[":sk_miji"] = "准备阶段，若你已受伤，你可以声明一种牌的类别，然后从牌堆随机亮出一张此类别的牌，将之交给一名角色。回合结束阶段，若你的体力值为全场最少（或"..
	"之一），你亦可以如此做。",
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
	技能描述：其他角色的准备阶段开始时，你可以弃置一张手牌，令其判定，若结果为：黑桃，其于本回合内所有武将技能无效；梅花，其弃置两张牌。
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
				local zhangbao = room:findPlayersBySkillName(skill:objectName()):first()
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
	技能描述：每回合限一次，当一名其他角色的黑色判定牌生效后，你可视为对其使用一张【杀】。
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
				if judge.who and judge.who:getSeat() ~= zhangbao:getSeat() and judge.card and judge.card:isBlack() then
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
	[":sk_zhoufu"] = "其他角色的准备阶段开始时，你可以弃置一张手牌，令其判定，若结果为：黑桃，其于本回合内所有武将技能无效；梅花，其弃置两张牌。",
	["$sk_zhoufu1"] = "孰死孰活，全听我令！",
	["$sk_zhoufu2"] = "咒缚缠身，尔待何如！",
	["@zhoufu"] = "你可以弃置一张手牌对%src发动【咒缚】",
	["sk_yingbing"] = "影兵",
	[":sk_yingbing"] = "每回合限一次，当一名其他角色的黑色判定牌生效后，你可视为对其使用一张【杀】。",
	["$sk_yingbing1"] = "幻影成兵，助我退敌！",
	["$sk_yingbing2"] = "四方神将，皆为我用！",
	["designer:sk_zhangbao"] = "极略三国",
    ["illustrator:sk_zhangbao"] = "极略三国",
    ["cv:sk_zhangbao"] = "极略三国",
}

return {extension}
