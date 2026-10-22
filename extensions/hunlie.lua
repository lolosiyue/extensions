local extension = sgs.Package("hunlie", sgs.Package_GeneralPack)

sgs.Sanguosha:setAudioType("sgkgodlvbu", "wushuang", "7")
sgs.Sanguosha:setAudioType("sgkgodsima", "zhiheng", "3")
sgs.Sanguosha:setAudioType("sgkgodsima", "guanxing", "5")
sgs.Sanguosha:setAudioType("sgkgodsima", "nosfankui", "3")
sgs.Sanguosha:setAudioType("sgkgodsima", "wansha", "5")
sgs.Sanguosha:setAudioType("sgkgodsunquan", "zhiheng", "4,5")


sgs.LoadTranslationTable{
	["hunlie"] = "极略魂烈",
}

--V2 全局技能以隐藏技能名挂到所有武将；晚于本扩展加载的武将或换将后于结算时补挂 acquired 實例
local hunlie_global_skill_names = {
	"#hunlie_drawCards",
	"#sgkgoddawu_fog", "#sgkgodluoyan_mark", "#sgkgodzhenhun_clear",
	"#tongtian_wansha_clear", "#sgkgodliangyuan_check", "#sgkgodliangyuan_exgive",
	"#sgkgodluncexia", "#sgkgodluncezhong", "#sgkgodlunceshang", "#sgkgodmeixinClear",
	"#sgkgodweizhen_mark", "#jlsglianti_mark", "#sgkgodlihun_clear",
}
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local hunlie_ensuring_globals = false
local function hunlie_ensure_global_instances(room)
	if hunlie_ensuring_globals then return end
	if room:getTag("hunlie_globals_ensured"):toBool() then return end
	hunlie_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		hunlie_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("hunlie_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(hunlie_global_skill_names) do
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
		room:setTag("hunlie_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("hunlie_globals_ensured", sgs.QVariant(true))
	hunlie_ensuring_globals = false
end

--全局配置类技能
cuifeng_slash = sgs.CreateTriggerSkillV2{
	name = "cuifeng_slash",
	frequency = sgs.Skill_Compulsory,
	events = {},
}

qianqi_slash = sgs.CreateTriggerSkillV2{
	name = "qianqi_slash",
	frequency = sgs.Skill_Compulsory,
	events = {},
}


hunlie_tarmod = sgs.CreateTargetModSkillV2{
	name = "hunlie_tarmod",
	pattern = ".",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "card_skill:qianqi_slash", "card_skill:sgkgodliegong", "mark:hunlie_global_slashtime", "skill:sgkgodshayi" },
	correct_func = function(skill, ctx)
		local mod = ctx:getModType()
		if mod ~= sgs.TargetModSkill_Residue and mod ~= sgs.TargetModSkill_DistanceLimit then return false end
		local from, card = ctx:getPrimary(), ctx:getCard()
		if not (from and card) then return false end
		local n = 0
		if mod == sgs.TargetModSkill_Residue then
			if from:hasSkill("sgkgodshayi") and card:isKindOf("Slash") then n = n + 9999 end
			if from:hasSkill("sgkgodliegong") and card:isKindOf("FireSlash") and table.contains(card:getSkillNames(), "sgkgodliegong") then n = n + 9999 end
			if card:isKindOf("Slash") and from:getMark("hunlie_global_slashtime") > 0 then n = n + from:getMark("hunlie_global_slashtime") end
			if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "qianqi_slash") then n = n + 9999 end
			if from:hasSkill("sgkgodfeiying") and card:isKindOf("Slash") and card:isBlack() and not from:isWounded() then n = n + 9999 end
			if from:getMark("sgkgodlihun_buff") > 0 then n = n + 9999 end
		elseif mod == sgs.TargetModSkill_DistanceLimit then
			if from:hasSkill("sgkgodshayi") and card:isKindOf("Slash") then n = n + 9999 end
			if from:hasSkill("sgkgodliegong") and card:isKindOf("FireSlash") and table.contains(card:getSkillNames(), "sgkgodliegong") then n = n + 9999 end
			if from:hasSkill("sgkgodqianqi") and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "qianqi_slash") then n = n + 9999 end
			if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "cuifeng_slash") then n = n + 9999 end
			if from:hasSkill("sgkgodfeiying") and card:isKindOf("Slash") and card:isBlack() and not from:isWounded() then n = n + 9999 end
			if from:getMark("sgkgodlihun_buff") > 0 then n = n + 9999 end
		end
		if n ~= 0 then return n end
		return false
	end
}


hunlie_maxcards = sgs.CreateMaxCardsSkillV2{
	name = "#hunlie_maxcards",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "pile:xing", "skill:sgkgodjuejing", "skill:sgkgodtianzi" },
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if not target then return false end
		local n = 0
		if target:hasSkill("sgkgodqixing") then n = n + target:getPile("xing"):length() end
		if target:hasSkill("sgkgodtianzi") then n = n + target:getAliveSiblings():length() end
		if n ~= 0 then return n end
		return false
	end,
	fixed_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:hasSkill("sgkgodjuejing") then return target:getMaxHp() end
		return false
	end
}


hunlie_drawCards = sgs.CreateTriggerSkillV2{
	name = "#hunlie_drawCards",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_record = function(skill, event, room, player, ctx)
		hunlie_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local draw = data:toDraw()
		local x = 0
		if player:getMark("hunlie_global_draw") > 0 then x = x + player:getMark("hunlie_global_draw") end
		draw.num = draw.num + x
		data:setValue(draw)
		return false
	end
}


function throwRandomCards(random_bool, thrower, victim, n, flag, skill)  --随机弃置一定数量的牌，魔孙皓专用
	local room = sgs.Sanguosha:currentRoom()
	local x = victim:getCards(flag):length()
	local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	if random_bool == true then
		local include_equip = false
		if string.find(flag, "e") then include_equip = true end
		local to_ids = victim:forceToDiscard(math.min(n, x), include_equip, true)
		dummy:addSubcards(to_ids)
	else
		for i = 1, math.min(n, x) do
			local id = room:askForCardChosen(thrower, victim, flag, skill, false, sgs.Card_MethodNone, dummy:getSubcards(), false)
			if id < 0 then break end
			dummy:addSubcard(id)
		end
	end
	if dummy:subcardsLength() > 0 then
		if thrower:objectName() == victim:objectName() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, thrower:objectName(), skill, "")
			room:throwCard(dummy, reason, nil)
			dummy:deleteLater()
			card_ids = sgs.IntList()
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, thrower:objectName(), nil, skill, nil)
			room:throwCard(dummy, reason, victim, thrower)
		end
	end
	dummy:deleteLater()
end


-- 语音只随龙魂持有者的隐藏关联实例触发，不向其他武将补挂。
sgkgodlonghunC = sgs.CreateTriggerSkillV2{
	name = "#sgkgodlonghunC",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		local ids = player and player:getValidSkillInstanceIds(skill:objectName())
		if ids and not ids:isEmpty() then
			return skill:objectName().."#"..tostring(ids:first()), player
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and (table.contains(card:getSkillNames(), "sgkgodlonghun") or table.contains(card:getSkillNames(), "sgkgodlonghunC") or table.contains(card:getSkillNames(), "sgkgodlonghunBuff")) then
			if card:isKindOf("Nullification") then
				room:broadcastSkillInvoke("sgkgodlonghun", 1)
			elseif card:isKindOf("Jink") then
				room:broadcastSkillInvoke("sgkgodlonghun", 2)
			elseif card:isKindOf("Peach") then
				room:broadcastSkillInvoke("sgkgodlonghun", 3)
			elseif card:isKindOf("FireSlash") then
				room:broadcastSkillInvoke("sgkgodlonghun", 4)
			end
		end
		return false
	end
}

-- 已用出的双牌效果须完成 CardFinished 结算，不能随主技能失去而中断。
sgkgodlonghunBuff = sgs.CreateRuleSkillV2{
	name = "#sgkgodlonghunBuff",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardFinished, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player then return skill:objectName(), player end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:subcardsLength() == 2 and (table.contains(use.card:getSkillNames(), "sgkgodlonghun") or table.contains(use.card:getSkillNames(), "sgkgodlonghunBuff")) then
				if use.card:isKindOf("Nullification") then
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list, "_ALL_TARGETS")
					use.no_respond_list = no_respond_list
					data:setValue(use)
					if use.whocard then
						local ids = sgs.IntList()
						if use.whocard:isVirtualCard() then
							ids = use.whocard:getSubcards()
						else
							ids:append(use.whocard:getEffectiveId())
						end
						if ids:isEmpty() then return false end
						for _, id in sgs.qlist(ids) do
							if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return false end
						end
						if use.from then room:obtainCard(use.from, use.whocard, "sgkgodlonghun") end
					end
				elseif use.card:isKindOf("Peach") then
					for _, t in sgs.qlist(use.to) do
						room:gainMaxHp(t, 1)
					end
				elseif use.card:isKindOf("Jink") then
					if use.who and use.whocard and use.whocard:isKindOf("Slash") then throwRandomCards(true, use.who, use.who, 2, "he", "sgkgodlonghun") end
				elseif use.card:isKindOf("FireSlash") then
					use.card:setTag("sgkgodlonghun_fireslash", sgs.QVariant(true))
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getTag("sgkgodlonghun_fireslash"):toBool() then
				use.card:removeTag("sgkgodlonghun_fireslash")
				use.card:use(room, use.from, use.to)
				use.card:use(room, use.from, use.to)
				return false
			end
		elseif event == sgs.CardResponded then
			local res = data:toCardResponse()
			if res.m_card and res.m_card:isKindOf("Nullification") and res.m_card:subcardsLength() == 2 and (table.contains(res.m_card:getSkillNames(), "sgkgodlonghun") or table.contains(res.m_card:getSkillNames(), "sgkgodlonghunBuff")) then
				local tocard = res.m_toCard
				if tocard then
					local ids = sgs.IntList()
					if tocard:isVirtualCard() then
						ids = tocard:getSubcards()
					else
						ids:append(tocard:getEffectiveId())
					end
					if ids:isEmpty() then return false end
					for _, id in sgs.qlist(ids) do
						if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return false end
					end
					if res.m_who then room:obtainCard(res.m_who, tocard, "sgkgodlonghun") end
				end
			end
		end
		return false
	end	
}


--[[
	技能名：仁政
	相关武将：神曹丕
	技能描述：出牌阶段限一次，你可以交给一名其他角色任意张手牌或任意个技能，然后若该角色为首次成为此技能的目标，你可以与其各加1点体力上限并回复1点体力。
	引用：sgkgodrenzheng
]]--
sgkgodrenzhengCard = sgs.CreateSkillCard{
	name = "sgkgodrenzhengCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
	    return to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
	    return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local givewhat = {"give_handcard", "give_skill"}
		if source:isKongcheng() then table.removeOne(givewhat, "give_handcard") end
		local _t = sgs.QVariant()
		_t:setValue(targets[1])
		local choice = room:askForChoice(source, "sgkgodrenzheng", table.concat(givewhat, "+"), _t)
		if choice == "give_handcard" then
			local to_card = room:askForExchange(source, "sgkgodrenzheng", source:getHandcardNum(), 1, true, "@sgkgodrenzheng:"..targets[1]:objectName())
			room:giveCard(source, targets[1], to_card, "sgkgodrenzheng", false)
			if targets[1]:getMark("sgkgodrenzheng_first") == 0 then
				room:addPlayerMark(targets[1], "sgkgodrenzheng_first")
				local welfare = room:askForChoice(source, "sgkgodrenzheng_buff", "yes+no", _t, nil, "renzheng_tip")
				if welfare == "yes" then
					room:gainMaxHp(source, 1)
					local rec = sgs.RecoverStruct()
					rec.recover = 1
					rec.who = source
					room:recover(source, rec, true)
					room:gainMaxHp(targets[1], 1)
					local rec = sgs.RecoverStruct()
					rec.recover = 1
					rec.who = source
					room:recover(targets[1], rec, true)
				end
			end
		elseif choice == "give_skill" then
			local choose_skill, to_skill = {}, {}
			for _, sk in sgs.qlist(source:getVisibleSkillList()) do
				table.insert(choose_skill, sk:objectName())
			end
			for i = 1, #choose_skill do
				if i > 1 then table.insert(choose_skill, "cancel") end
				local to_give = room:askForChoice(source, "renzheng_giveskill", table.concat(choose_skill, "+"), _t)
				if to_give ~= "cancel" then
					table.insert(to_skill, to_give)
					table.removeOne(choose_skill, to_give)
					if #choose_skill == 0 then break end
				else
					break
				end
			end
			room:handleAcquireDetachSkills(source, "-"..table.concat(to_skill, "|-"))
			room:handleAcquireDetachSkills(targets[1], table.concat(to_skill, "|"))
			if targets[1]:getMark("sgkgodrenzheng_first") == 0 then
				room:addPlayerMark(targets[1], "sgkgodrenzheng_first")
				local welfare = room:askForChoice(source, "sgkgodrenzheng_buff", "yes+no", _t, nil, "renzheng_tip")
				if welfare == "yes" then
					room:gainMaxHp(source, 1)
					local rec = sgs.RecoverStruct()
					rec.recover = 1
					rec.who = source
					room:recover(source, rec, true)
					room:gainMaxHp(targets[1], 1)
					local rec = sgs.RecoverStruct()
					rec.recover = 1
					rec.who = source
					room:recover(targets[1], rec, true)
				end
			end
		end
	end
}

sgkgodrenzheng = sgs.CreateViewAsSkillV2{
	name = "sgkgodrenzheng",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodrenzheng")
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local card = sgkgodrenzhengCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("sgkgodrenzheng", instance_id)
			card:setSourceSkill("sgkgodrenzheng", instance_id)
		end
		return card
	end,
}


--[[
	技能名：极权
	相关武将：神曹丕
	技能描述：出牌阶段限一次，你可以令任意名其他角色各选择一项：1.交给你X张牌（X为你对其发动此技能的次数）；2.交给你一个技能；然后若你的体力上限
	小于这些角色体力上限之和，你加1点体力上限并回复1点体力。
	引用：sgkgodjiquan
]]--
sgkgodjiquanCard = sgs.CreateSkillCard{
	name = "sgkgodjiquanCard",
	filter = function(self, targets, to_select, player)
	    return to_select:objectName() ~= player:objectName() and (to_select:getHandcardNum() + to_select:getEquips():length() >= to_select:getMark("sgkgodjiquan_times") + 1 
		or to_select:getVisibleSkillList():length() > 0)
	end,
	feasible = function(self, targets, player)
	    return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local _maxhp = 0
		for i = 1, #targets, 1 do
			room:addPlayerMark(targets[i], "sgkgodjiquan_times", 1)
			_maxhp = _maxhp + targets[i]:getMaxHp()
		end
		local cp = sgs.QVariant()
		cp:setValue(source)
		for i = 1, #targets, 1 do
			local n = targets[i]:getMark("sgkgodjiquan_times")
			local choices = {"givecards_to_caopi="..source:objectName().."="..tostring(n), "giveskill_to_caopi="..source:objectName()}
			if targets[i]:getCards("he"):length() < n then table.remove(choices, 1) end
			local togive = room:askForChoice(targets[i], "sgkgodjiquan", table.concat(choices, "+"), cp)
			if togive:startsWith("givecards_to_caopi") then
				local prompt = string.format("@sgkgodjiquan:%s:%s", source:objectName(), tostring(n))
				local cards = room:askForExchange(targets[i], "sgkgodjiquan", n, n, true, prompt)
				room:giveCard(targets[1], source, cards, "sgkgodjiquan", false)
			else
				local to_skill = {}
				for _, sk in sgs.qlist(targets[i]:getVisibleSkillList()) do
					table.insert(to_skill, sk:objectName())
				end
				local to_give = room:askForChoice(targets[i], "jiquan_giveskill", table.concat(to_skill, "+"), cp)
				room:handleAcquireDetachSkills(targets[1], "-"..to_give)
				room:handleAcquireDetachSkills(source, to_give)
			end
		end
		if source:getMaxHp() < _maxhp then
			room:gainMaxHp(source, 1)
			local rec = sgs.RecoverStruct()
			rec.recover = 1
			rec.who = source
			room:recover(source, rec, true)
		end
	end
}

sgkgodjiquan = sgs.CreateViewAsSkillV2{
	name = "sgkgodjiquan",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodjiquan")
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and candidate:objectName() ~= player:objectName()
			and (candidate:getHandcardNum() + candidate:getEquips():length() >= candidate:getMark("sgkgodjiquan_times") + 1
				or candidate:getVisibleSkillList():length() > 0)
	end,
	targets_feasible = function(skill, request, selected)
		return #selected > 0
	end,
	create_card = function(skill, request)
		local card = sgkgodjiquanCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("sgkgodjiquan", instance_id)
			card:setSourceSkill("sgkgodjiquan", instance_id)
		end
		return card
	end,
}


local sgkgodhidden = sgs.SkillList()
if not sgs.Sanguosha:getSkill("cuifeng_slash") then sgkgodhidden:append(cuifeng_slash) end
if not sgs.Sanguosha:getSkill("qianqi_slash") then sgkgodhidden:append(qianqi_slash) end
if not sgs.Sanguosha:getSkill("hunlie_tarmod") then sgkgodhidden:append(hunlie_tarmod) end
if not sgs.Sanguosha:getSkill("#hunlie_maxcards") then sgkgodhidden:append(hunlie_maxcards) end
if not sgs.Sanguosha:getSkill("#hunlie_drawCards") then sgkgodhidden:append(hunlie_drawCards) end
if not sgs.Sanguosha:getSkill("#sgkgodlonghunC") then sgkgodhidden:append(sgkgodlonghunC) end
if not sgs.Sanguosha:getSkill("#sgkgodlonghunBuff") then sgkgodhidden:append(sgkgodlonghunBuff) end
if not sgs.Sanguosha:getSkill("sgkgodrenzheng") then sgkgodhidden:append(sgkgodrenzheng) end
if not sgs.Sanguosha:getSkill("sgkgodjiquan") then sgkgodhidden:append(sgkgodjiquan) end
sgs.Sanguosha:addSkills(sgkgodhidden)


sgs.LoadTranslationTable{
	["cuifeng_slash"] = "摧锋",
	["sgkgodlonghunBuff"] = "龙魂",
	["sgkgodlonghunC"] = "龙魂",
	["#sgkgodlonghunBuff"] = "龙魂",
	["#sgkgodlonghunC"] = "龙魂",
	["sgkgodrenzheng"] = "仁政",
	[":sgkgodrenzheng"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌或任意个技能，然后若该角色为首次成为此技能的目标，你可以与其各加1点体力上限并回复1点体力。",
	["$sgkgodrenzheng"] = "仁政为民，恩泽天下。",
	["give_handcard"] = "交出至少一张牌",
	["give_skill"] = "交出至少一个武将技能",
	["@sgkgodrenzheng"] = "请将至少一张牌交给%src",
	["sgkgodrenzheng_buff"] = "仁政",
	["renzheng_tip"] = "是否与其各加1点体力上限并各回复1点体力？",
	["renzheng_giveskill"] = "选择“仁政”交出的技能",
	["sgkgodjiquan"] = "极权",
	[":sgkgodjiquan"] = "出牌阶段限一次，你可以令任意名其他角色各选择一项：1.交给你X张牌（X为你对其发动此技能的次数）；2.交给你一个技能；然后若你的体力上限小于这些角色"..
	"体力上限之和，你加1点体力上限并回复1点体力。",
	["$sgkgodjiquan"] = "兴师征伐，一统山河！",
	["sgkgodjiquan:givecards_to_caopi"] = "将%arg张牌交给%src",
	["sgkgodjiquan:giveskill_to_caopi"] = "将你的一个技能交给%src",
	["@sgkgodjiquan"] = "请将%dest张牌交给%src",
	["jiquan_giveskill"] = "选择“极权”交出的技能",
	["qianqi_slash"] = "千骑",
}


--神月英
sgkgodyueying = sgs.General(extension, "sgkgodyueying", "sy_god", "3", false)


--[[
	技能名：知命
	相关武将：神月英
	技能描述：出牌阶段限一次，你可以选择至多X名其他角色（X为你的体力值），并执行以下任意个选项（你不能选择上一个出牌阶段以此法选择过的选项）：1.失去1点体力；2.翻面；3.弃置任意张牌；然后这些角色也如此做。
	引用：sgkgodzhiming
]]--
sgkgodzhimingCard = sgs.CreateSkillCard{
	name = "sgkgodzhimingCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < player:getHp()
	end,
	feasible = function(self, targets, player)
		return #targets > 0 and #targets <= player:getHp()
	end,
	on_use = function(self, room, source, targets)
		local prev = source:getMark("sgkgodzhiming_prev")
		local opts, cur = {}, 0
		local _data = sgs.QVariant()
		_data:setValue(source)
		if prev % 2 == 0 and room:askForChoice(source, "sgkgodzhiming", "yes+no", _data, nil, "@sgkgodzhiming_losehp") == "yes" then
			cur = cur + 1
			table.insert(opts, "losehp")
		end
		if math.floor(prev / 2) % 2 == 0 and room:askForChoice(source, "sgkgodzhiming", "yes+no", _data, nil, "@sgkgodzhiming_turnover") == "yes" then
			cur = cur + 2
			table.insert(opts, "turnover")
		end
		if math.floor(prev / 4) % 2 == 0 and room:askForChoice(source, "sgkgodzhiming", "yes+no", _data, nil, "@sgkgodzhiming_discard") == "yes" then
			cur = cur + 4
			table.insert(opts, "discard")
		end
		room:setPlayerMark(source, "sgkgodzhiming_cur", cur)
		if #opts == 0 then return end
		room:notifySkillInvoked(source, "sgkgodzhiming")
		room:broadcastSkillInvoke("sgkgodzhiming")
		local do_opt = function(p, op)
			if op == "losehp" then
				room:loseHp(p, 1, true, source, "sgkgodzhiming")
			elseif op == "turnover" then
				p:turnOver()
			elseif op == "discard" and p:getCards("he"):length() > 0 then
				room:askForDiscard(p, "sgkgodzhiming", p:getCards("he"):length(), 0, false, true, "@sgkgodzhiming-discard")
			end
		end
		for _, op in ipairs(opts) do do_opt(source, op) end
		for _, t in ipairs(targets) do
			if t:isAlive() then
				for _, op in ipairs(opts) do do_opt(t, op) end
			end
		end
	end
}

sgkgodzhiming = sgs.CreateViewAsSkillV2{
	name = "sgkgodzhiming",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodzhiming")
			and player:getMark("sgkgodzhiming_prev") < 7
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and candidate:objectName() ~= player:objectName()
			and #selected < player:getHp()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected > 0
	end,
	create_card = function(skill, request)
		local card = sgkgodzhimingCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("sgkgodzhiming", instance_id)
			card:setSourceSkill("sgkgodzhiming", instance_id)
		end
		return card
	end,
}

-- 每個出牌階段開始時記錄上一階段已選過的選項（對應“不能選擇上一個出牌階段以此法選擇過的選項”）
sgkgodzhimingC = sgs.CreateTriggerSkillV2{
	name = "#sgkgodzhimingC",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() == sgs.Player_Play and player:hasSkill("sgkgodzhiming") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		room:setPlayerMark(player, "sgkgodzhiming_prev", player:getMark("sgkgodzhiming_cur"))
		room:setPlayerMark(player, "sgkgodzhiming_cur", 0)
		return false
	end
}


--[[
	技能名：夙隐
	相关武将：神月英
	技能描述：当失去所有手牌后，你可以令一名其他角色翻面。
	引用：sgkgodsuyin
]]--
sgkgodsuyin = sgs.CreateTriggerSkillV2{
	name = "sgkgodsuyin",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName()
			and move.from_places:contains(sgs.Player_PlaceHand)
			and move.is_last_handcard then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@suyin-turnover")
		if not s then return false end
		room:doAnimate(1, player:objectName(), s:objectName())
		room:broadcastSkillInvoke(self:objectName())
		s:turnOver()
	end
}


sgkgodyueying:addSkill(sgkgodzhiming)
sgkgodyueying:addSkill(sgkgodsuyin)


local sgkgodzhiming_hidden = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sgkgodzhimingC") then sgkgodzhiming_hidden:append(sgkgodzhimingC) end
sgs.Sanguosha:addSkills(sgkgodzhiming_hidden)


sgs.LoadTranslationTable{
	["sgkgodyueying"] = "神月英",
	["&sgkgodyueying"] = "神月英",
	["#sgkgodyueying"] = "夕风霞影",
	["sgkgodzhiming"] = "知命",
	[":sgkgodzhiming"] = "出牌阶段限一次，你可以选择至多X名其他角色（X为你的体力值），并执行以下任意个选项（你不能选择上一个出牌阶段以此法选择过的选项）：1.失去1点体力；2.翻面；3.弃置任意张牌；然后这些角色也如此做。",
	["@sgkgodzhiming_losehp"] = "知命：是否执行「失去1点体力」？",
	["@sgkgodzhiming_turnover"] = "知命：是否执行「翻面」？",
	["@sgkgodzhiming_discard"] = "知命：是否执行「弃置任意张牌」？",
	["@sgkgodzhiming-discard"] = "知命：请弃置任意张牌",
	["sgkgodsuyin"] = "夙隐",
	["@suyin-turnover"] = "你可以发动“夙隐”令一名其他角色将武将牌翻面<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":sgkgodsuyin"] = "当你失去所有手牌后，你可以令一名其他角色翻面。",
	["$sgkgodzhiming"] = "风起日落，天行有常。",
	["$sgkgodsuyin"] = "欲别去归隐，无负奢望。",
	["~sgkgodyueying"]= "只盼明日，能共沐晨光……",
	["designer:sgkgodyueying"] = "极略三国",
	["illustrator:sgkgodyueying"] = "极略三国",
	["cv:sgkgodyueying"] = "极略三国",
}


--神张角
sgkgodzhangjiao = sgs.General(extension, "sgkgodzhangjiao", "sy_god", "3")


--[[
	技能名：电界
	相关武将：神张角
	技能描述：你可以跳过摸牌阶段或出牌阶段，然后判定，若结果为：梅花，你可令任意名角色横置；黑桃，你可对一名角色造成2点雷电伤害。
	引用：sgkgoddianjie
]]--
sgkgoddianjie = sgs.CreateTriggerSkillV2{
	name = "sgkgoddianjie",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Draw and change.to ~= sgs.Player_Play then return false end
		if player:isSkipped(change.to) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		if change.to == sgs.Player_Draw then
			room:broadcastSkillInvoke(self:objectName(), 1)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
		end
		player:skip(change.to)
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.pattern = ".|black"
		judge.reason = self:objectName()
		judge.good = true
		judge.negative = false
		room:judge(judge)
		if judge:isGood() then
			if judge.card:getSuit() == sgs.Card_Spade then
				local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@dianjie-thunder", true)
				if not s then return false end
				room:doAnimate(1, player:objectName(), s:objectName())
				room:damage(sgs.DamageStruct("sgkgoddianjie", player, s, 2, sgs.DamageStruct_Thunder))
			elseif judge.card:getSuit() == sgs.Card_Club then
				local unchained = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not pe:isChained() then unchained:append(pe) end
				end
				if unchained:isEmpty() then return false end
				local targets = room:askForPlayersChosen(player, unchained, self:objectName(), 0, 999, "@dianjie-chain")
				if not targets then return false end
				for _, p in sgs.qlist(targets) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				for _, t in sgs.qlist(targets) do
					room:setPlayerChained(t)
				end
			end
		end
	end
}


--[[
	技能名：神道
	相关武将：神张角
	技能描述：一名角色的判定牌生效前，你可以用一张手牌或场上的牌替换之。
	引用：sgkgodshendao
]]--
sgkgodshendao=sgs.CreateTriggerSkillV2{
	name = "sgkgodshendao",
	events = {sgs.AskForRetrial},
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then return skill:objectName() end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local judge = data:toJudge()
		local q = sgs.QVariant()
		q:setValue(judge)
		player:setTag("shendao_judge", q)
		local non_nude_count = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getCards("ej"):length() > 0 then
				non_nude_count = non_nude_count + 1
			end
		end
		if non_nude_count == 0 and player:isKongcheng() then return false end
		return player:askForSkillInvoke(skill:objectName(), data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local judge = data:toJudge()
		local non_nude_count = 0
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getCards("ej"):length() > 0 then  --场上有牌的角色
				non_nude_count = non_nude_count + 1
				targets:append(p)
			end
		end
		local card
		if player:isKongcheng() and non_nude_count ~= 0 then  --特例1：自己没有手牌，但是场上还有牌
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			card = sgs.Sanguosha:getCard(room:askForCardChosen(player, target, "ej", self:objectName()))
		else
			if (not player:isKongcheng()) and non_nude_count == 0 then  --特例2：自己有手牌，但是场上没有牌
				local prompt = "@shendao-card:"..judge.who:objectName()..":"..self:objectName()..
				":"..judge.reason..":"..judge.card:getEffectiveId()
				card = room:askForCard(player,  "." , prompt, data, sgs.Card_MethodResponse, judge.who, true)
			else
				if (not player:isKongcheng()) and non_nude_count ~= 0 then  --一般情况下，自己有手牌，并且场上也有牌
					local choice = room:askForChoice(player, self:objectName(), "shendao_selfhandcard+shendao_wholearea", data)
					if choice == "shendao_selfhandcard" then
						local prompt = "@shendao-card:"..judge.who:objectName()..":"..self:objectName()..
						":"..judge.reason..":"..judge.card:getEffectiveId()
						card = room:askForCard(player,  "." , prompt, data, sgs.Card_MethodResponse, judge.who, true)
					else
						local target = room:askForPlayerChosen(player, targets, self:objectName())
						card = sgs.Sanguosha:getCard(room:askForCardChosen(player, target, "ej", self:objectName()))
					end
				end
			end
		end
		if card then
			room:broadcastSkillInvoke(self:objectName())
			room:retrial(card, player, judge, self:objectName(), true)
		end
	end
}


--[[
	技能名：雷魂
	相关武将：神张角
	技能描述：锁定技，当你即将受到雷电伤害时，防止之，改为回复等量的体力。
	引用：sgkgodleihun
]]--
sgkgodleihun = sgs.CreateTriggerSkillV2{
	name = "sgkgodleihun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		if player:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(damage.damage, player:getLostHp())
			room:recover(player, recover)
		end
		return true
	end
}


sgkgodzhangjiao:addSkill(sgkgoddianjie)
sgkgodzhangjiao:addSkill(sgkgodshendao)
sgkgodzhangjiao:addSkill(sgkgodleihun)


sgs.LoadTranslationTable{
	["sgkgodzhangjiao"] = "神张角",
	["&sgkgodzhangjiao"] = "神张角",
	["#sgkgodzhangjiao"] = "雷霆万钧",
	["sgkgoddianjie"] = "电界",
	[":sgkgoddianjie"] = "你可以跳过摸牌阶段或出牌阶段，然后判定，若结果为：梅花，你可令任意名角色横置；黑桃，你可对一名角色造成2点雷电伤害。",
	["@dianjie-thunder"] = "你可以对一名角色造成2点雷电伤害",
	["@dianjie-chain"] = "你可以横置任意名角色的武将牌",
	["~sgkgoddianjie"] = "选择任意名未被横置的角色→点击“确定”",
	["sgkgodshendao"] = "神道",
	[":sgkgodshendao"] = "一名角色的判定牌生效前，你可以用一张手牌或场上的牌替换之。",
	["shendao_selfhandcard"] = "用一张自己的手牌改判",
	["shendao_wholearea"] = "用一张场上的牌改判",
	["@shendao-card"] = "请发动“%dest”来修改 %src 的“%arg”判定",
	["sgkgodleihun"] = "雷魂",
	[":sgkgodleihun"] = "锁定技，当你即将受到雷电伤害时，防止之，改为回复等量的体力。",
	["$sgkgoddianjie1"] = "电破苍穹，雷震九州！",
	["$sgkgoddianjie2"] = "风雷如律令，法咒显圣灵！",
	["$sgkgodshendao"] = "人世之伎俩，于鬼神无用！",
	["$sgkgodleihun"] = "肉体凡胎，也敢扰我清静？！",
	["~sgkgodzhangjiao"] = "吾之信仰，也将化为微尘……",
	["designer:sgkgodzhangjiao"] = "极略三国",
	["illustrator:sgkgodzhangjiao"] = "极略三国",
	["cv:sgkgodzhangjiao"] = "极略三国",
}


--神吕蒙
sgkgodlvmeng = sgs.General(extension, "sgkgodlvmeng", "sy_god", 3)


--[[
	技能名：涉猎
	相关武将：神吕蒙
	技能描述：锁定技，当你使用的牌结算完毕后，你从牌堆随机获得与此牌类别不同且类别各不相同的两张牌，每回合每种类别限一次。
	引用：sgkgodshelie
]]--
sgkgodshelie = sgs.CreateTriggerSkillV2{
    name = "sgkgodshelie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local names, owners = {}, {}
				for _, slm in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(names, skill:objectName())
					table.insert(owners, slm:objectName())
				end
				if #names > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if room:getDrawPile():isEmpty() then return false end
			if use.from and use.from:hasSkill(skill:objectName()) and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill then
				local shelie_types = use.from:getTag("shelie_types"):toString():split("+")
				if not table.contains(shelie_types, use.card:getType()) then
					return skill:objectName(), use.from
				end
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			player:removeTag("shelie_types")
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local shelie_types = use.from:getTag("shelie_types"):toString():split("+")
			local all_types = {}
			if use.card:isKindOf("BasicCard") then all_types = {"TrickCard", "EquipCard"}
			elseif use.card:isKindOf("TrickCard") then all_types = {"BasicCard", "EquipCard"}
			elseif use.card:isKindOf("EquipCard") then all_types = {"BasicCard", "TrickCard"} end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			local ids1, ids2 = sgs.IntList(), sgs.IntList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(all_types[1]) and not ids1:contains(id) then ids1:append(id) end
				if sgs.Sanguosha:getCard(id):isKindOf(all_types[2]) and not ids2:contains(id) then ids2:append(id) end
			end
			if not ids1:isEmpty() then
				ids1 = sgs.QList2Table(ids1)
				dummy:addSubcard(ids1[math.random(1, #ids1)])
			end
			if not ids2:isEmpty() then
				ids2 = sgs.QList2Table(ids2)
				dummy:addSubcard(ids2[math.random(1, #ids2)])
			end
			if dummy:subcardsLength() > 0 then
				table.insert(shelie_types, use.card:getType())
				room:addPlayerMark(use.from, "&sgkgodshelie+".. use.card:getType() .."-Clear")
				use.from:setTag("shelie_types", sgs.QVariant(table.concat(shelie_types, "+")))
				room:sendCompulsoryTriggerLog(use.from, self:objectName(), true, true)
				room:obtainCard(use.from, dummy, "sgkgodshelie", false)
			end
			dummy:deleteLater()
		end
		return false
	end
}


--[[
	技能名：攻心
	相关武将：神吕蒙
	技能描述：出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以先获得其中一张牌，再弃置另一张花色不同的牌，若如此做，该角色于本回合内不能使用或
	打出剩余两种花色的手牌。
	引用：sgkgodgongxin, sgkgodgongxinLimitCard
]]--
sgkgodgongxinCard = sgs.CreateSkillCard{
    name = "sgkgodgongxinCard",
	filter = function(self, targets, to_select, player)
	    return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		if effect.from:canGet(effect.to, "h") then
			local patterns = {"spade", "heart", "club", "diamond"}
		    local id1 = room:askForCardChosen(effect.from, effect.to, "h", "sgkgodgongxin", true, sgs.Card_MethodGet)
			if not effect.from:canGet(effect.to, id1) then return end
			local card1 = sgs.Sanguosha:getCard(id1)
			room:obtainCard(effect.from, card1, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName(), effect.to:objectName(), "sgkgodgongxin", ""), true)
			table.removeOne(patterns, card1:getSuitString())
			local same_suit = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				if card:getSuit() == card1:getSuit() then
					same_suit:append(card:getEffectiveId())
				end
			end
			if not effect.to:isKongcheng() then
				local id2 = room:askForCardChosen(effect.from, effect.to, "h", "sgkgodgongxin", true, sgs.Card_MethodNone, same_suit)
				local card2 = sgs.Sanguosha:getCard(id2)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, effect.from:objectName(), nil, "sgkgodgongxin", nil)
				if card2 then
					room:throwCard(card2, reason, effect.to, effect.from)
					table.removeOne(patterns, card2:getSuitString())
				end
				if #patterns == 2 then
					room:setPlayerCardLimitation(effect.to, "use,response", ".|"..table.concat(patterns, ",").."|.|hand", true)
					local msg = sgs.LogMessage()
					msg.from = effect.from
					msg.type = "#gongxinLimit"
					msg.arg = patterns[1]
					msg.arg2 = patterns[2]
					msg.to:append(effect.to)
					room:sendLog(msg)
					room:addPlayerMark(effect.to, "&sgkgodgongxin+to+:+#"..effect.from:objectName().."+"..patterns[1].."_char+"..patterns[2].."_char".."-Clear")
				end
			end
		end
	end
}

sgkgodgongxin = sgs.CreateViewAsSkillV2{
    name = "sgkgodgongxin",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodgongxin")
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
			and not candidate:isKongcheng()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local card = sgkgodgongxinCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("sgkgodgongxin", instance_id)
			card:setSourceSkill("sgkgodgongxin", instance_id)
		end
		return card
	end,
}


sgkgodlvmeng:addSkill(sgkgodshelie)
sgkgodlvmeng:addSkill(sgkgodgongxin)


sgs.LoadTranslationTable{
	["sgkgodlvmeng"] = "神吕蒙",
	["#sgkgodlvmeng"] = "圣光国士",
	["&sgkgodlvmeng"] = "神吕蒙",
	["~sgkgodlvmeng"] = "死去方知万事空……",
	["sgkgodshelie"] = "涉猎",
	[":sgkgodshelie"] = "锁定技，当你使用的牌结算完毕后，你从牌堆随机获得与此牌类别不同且类别各不相同的两张牌，每回合每种类别限一次。",
	["$sgkgodshelie"] = "涉猎阅旧闻，暂使心魂澄。",
	["sgkgodgongxin"] = "攻心",
	[":sgkgodgongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以先获得其中一张牌，再弃置另一张花色不同的牌，若如此做，该角色于本回合内不能使用或"..
	"打出剩余两种花色的手牌。",
	["$sgkgodgongxin"] = "攻城为下，攻心为上。",
	["#gongxinLimit"] = "%from 令 %to 本回合不能使用或打出 %arg 和 %arg2 花色的手牌",
	["designer:sgkgodlvmeng"] = "极略三国",
	["illustrator:sgkgodlvmeng"] = "极略三国",
	["cv:sgkgodlvmeng"] = "极略三国",
}


--神赵云
sgkgodzhaoyun = sgs.General(extension, "sgkgodzhaoyun", "sy_god", 4)


--[[
	技能名：绝境
	相关武将：神赵云
	技能描述：锁定技，你的体力不能大于1点（游戏开始/当你获得此技能时，若你的体力值大于1点，你失去多余的体力）。你的手牌上限为你的体力上限。当你进入或脱离濒死状态时，你摸两张牌。
	引用：sgkgodjuejing
]]--
sgkgodjuejing = sgs.CreateTriggerSkillV2{
    name = "sgkgodjuejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.PreHpRecover, sgs.EnterDying, sgs.QuitDying},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName ~= skill:objectName() then return false end
		elseif event == sgs.PreHpRecover then
			if data:toRecover().recover <= 0 then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			if player:getHp() >= 1 then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				room:loseHp(player, player:getHp() - 1, true, player, self:objectName())
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName == self:objectName() and player:getHp() >= 1 then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				room:loseHp(player, player:getHp() - 1, true, player, self:objectName())
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.recover > 0 then
				if player:getHp() >= 1 then
					return true
				else
					if player:getHp() + rec.recover >= 1 then
						rec.recover = 1 - player:getHp()
						data:setValue(rec)
					end
				end
			end
		else
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			player:drawCards(2, self:objectName())
		end
		return false
	end
}


--[[
	技能名：龙魂
	相关武将：神赵云
	技能描述：你可以将1-2张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当【火杀】；黑桃当【无懈可击】；梅花当【闪】。若以此法使用的牌为两张，则：
	【桃】-令目标角色加1点体力上限；
	【火杀】-以此法使用的【火杀】额外结算两次；
	【闪】-若响应了【杀】，则此【杀】的使用者随机弃置两张牌；
	【无懈可击】-不可被响应，且你获得被响应的牌。
	引用：sgkgodlonghun
]]--
sgkgodlonghun = sgs.CreateViewAsSkillV2{
    name = "sgkgodlonghun",
	response_or_use = true,
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:isWounded() or sgs.Slash_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if pattern == "nullification" then
				local count = 0
				for _, c in sgs.qlist(player:getHandcards()) do
					if c:getSuit() == sgs.Card_Spade then count = count + 1 end
				end
				for _, c in sgs.qlist(player:getEquips()) do
					if c:getSuit() == sgs.Card_Spade then count = count + 1 end
				end
				return count >= 1
			end
			return pattern == "slash" or pattern == "jink"
				or (string.find(pattern, "peach") ~= nil and player:getMark("Global_PreventPeach") == 0)
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		if not to_select or to_select:hasFlag("using") then return false end
		local ids = request:getSelectedCardIds()
		if ids:length() > 1 then return false end
		local player = request:getInitiator()
		if not player then return false end
		if ids:length() > 0 then
			local first = sgs.Sanguosha:getCard(ids:first())
			return first ~= nil and to_select:getSuit() == first:getSuit()
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if player:isWounded() or (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash_IsAvailable(player) and (to_select:getSuit() == sgs.Card_Diamond) then
				if player:getWeapon() and (to_select:getEffectiveId() == player:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return player:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local n = request:getSelectedCardIds():length()
		return n == 1 or n == 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local n = ids:length()
		if n ~= 1 and n ~= 2 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		if not card then return nil end
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName("sgkgodlonghun")
			for _, id in sgs.qlist(ids) do
				new_card:addSubcard(id)
			end
		end
		return new_card
	end,
}
-- ServerPlayer::hasNullification 只問舊 response_pattern 探針
sgkgodlonghun.response_pattern = "nullification"


sgkgodzhaoyun:addSkill(sgkgodjuejing)
sgkgodzhaoyun:addSkill(sgkgodlonghun)
sgkgodzhaoyun:addSkill(sgkgodlonghunC)
sgkgodzhaoyun:addSkill(sgkgodlonghunBuff)
extension:insertRelatedSkills("sgkgodlonghun", "#sgkgodlonghunC")
extension:insertRelatedSkills("sgkgodlonghun", "#sgkgodlonghunBuff")


sgs.LoadTranslationTable{
    ["sgkgodzhaoyun"] = "神赵云",
	["#sgkgodzhaoyun"] = "神威如龙",
	["&sgkgodzhaoyun"] = "神赵云",
	["~sgkgodzhaoyun"] = "血染鳞甲，龙坠九天……",
	["sgkgodjuejing"] = "绝境",
	[":sgkgodjuejing"] = "锁定技，你的体力不能大于1点（游戏开始/当你获得此技能时，若你的体力值大于1点，你失去多余的体力）。你的手牌上限为你的体力上限。当你进入"..
	"或脱离濒死状态时，你摸两张牌。",
	["$sgkgodjuejing"] = "龙战于野，其血玄黄。",
	["sgkgodlonghun"] = "龙魂",
	[":sgkgodlonghun"] = "你可以将1-2张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当【火杀】；黑桃当【无懈可击】；梅花当【闪】。若以此法使用的牌为两张：\
	使用【桃】-令目标角色加1点体力上限；\
	使用【火杀】-以此法使用的【火杀】额外结算两次；\
	使用【闪】-若响应了【杀】，则此【杀】的使用者随机弃置两张牌；\
	使用【无懈可击】-不可被响应，且你获得被响应的牌。",
	["$sgkgodlonghun1"] = "金甲映日，驱邪祛秽。",  --无懈可击
	["$sgkgodlonghun2"] = "腾龙行云，首尾不见。",  --闪
	["$sgkgodlonghun3"] = "潜龙于渊，涉灵愈伤。",  --桃
	["$sgkgodlonghun4"] = "千里一怒，红莲灿世。",  --火杀
	["designer:sgkgodzhaoyun"] = "极略三国",
	["illustrator:sgkgodzhaoyun"] = "极略三国",
	["cv:sgkgodzhaoyun"] = "极略三国",
}


--神张辽
sgkgodzhangliao=sgs.General(extension,"sgkgodzhangliao","sy_god","4")


--[[
	技能名：逆战
	相关武将：神张辽
	技能描述：锁定技，一名角色的准备阶段，若其：已受伤，获得1个“逆战”标记；未受伤，移去1个“逆战”标记。
	引用：sgkgodnizhan
]]--
sgkgodnizhan = sgs.CreateTriggerSkillV2{
	name = "sgkgodnizhan",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Start then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local target = ctx.invoker
		if target:isWounded() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			target:gainMark("&nizhan")
		else
			if target:getMark("&nizhan") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), target:objectName())
				target:loseMark("&nizhan")
			end
		end
		return false
	end
}

sgkgodnizhanClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodnizhan",
	events = {sgs.Death, sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Death then
			if player:hasSkill("sgkgodnizhan") then return skill:objectName() end
		elseif event == sgs.EventLoseSkill then
			-- 主技能實例在 EventLoseSkill 分發前已移除，清理由此 related helper 負責
			if data:toSkillChange().skillName == "sgkgodnizhan" then return skill:objectName() end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		if event == sgs.Death and not ctx.original_data:toDeath().who:hasSkill("sgkgodnizhan") then
			return false
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("&nizhan")>0 then p:loseAllMarks("&nizhan") end
		end
		return false
	end
}


extension:insertRelatedSkills("sgkgodnizhan","#sgkgodnizhan")
extension:insertRelatedSkills("sgkgodweizhen","#sgkgodweizhenClear")


--[[
	技能名：摧锋
	相关武将：神张辽
	技能描述：出牌阶段限一次，你可以移动场上的1枚“逆战”标记，然后失去标记的角色视为对获得标记的角色使用一张无次数与距离限制的【杀】。
	引用：sgkgodcuifeng
]]--
sgkgodcuifengCard = sgs.CreateSkillCard{
	name = "sgkgodcuifengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return to_select:getMark("&nizhan") > 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local players = room:getAlivePlayers()
		players:removeOne(target)
		local t = room:askForPlayerChosen(source, players, "sgkgodcuifeng")
	    if t then
			room:doAnimate(1, target:objectName(), t:objectName())
			target:loseMark("&nizhan")
			t:gainMark("&nizhan")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("cuifeng_slash")
			if not sgs.Sanguosha:isProhibited(target, t, slash) then
				local use = sgs.CardUseStruct()
				use.from = target
				use.to:append(t)
				use.card = slash
				room:useCard(use, false)
			end
			slash:deleteLater()
		end
	end
}

sgkgodcuifeng = sgs.CreateViewAsSkillV2{
	name = "sgkgodcuifeng",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodcuifeng")
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected == 0 and candidate:getMark("&nizhan") > 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodcuifengCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodcuifeng", instance_id)
		card:setSourceSkill("sgkgodcuifeng", instance_id)
		return card
	end
}


--[[
	技能名：威震
	相关武将：神张辽
	技能描述：锁定技，摸牌阶段，你额外摸X张牌（X为有“逆战”标记的角色数）。若一名角色的“逆战”标记数不小于：2，其摸牌阶段少摸一张牌；3，你对其造成的伤害+1；4，其非锁定技失效。
	引用：sgkgodweizhen
]]--
function forbidNonCompulsorySkills(vic, trigger_name)
	local room = vic:getRoom()
	local skill_list = {}
	for _, sk in sgs.qlist(vic:getVisibleSkillList()) do
		if not table.contains(skill_list, sk:objectName()) then 
			if sk:getFrequency() ~= sgs.Skill_Compulsory and sk:getFrequency() ~= sgs.Skill_Wake then
				table.insert(skill_list, sk:objectName())
			end
		end
	end
	if #skill_list > 0 then
		vic:setTag("Qingcheng", sgs.QVariant(table.concat(skill_list, "+")))
		for _, skill_qc in ipairs(skill_list) do
			room:addPlayerMark(vic, "Qingcheng"..skill_qc)
			room:addPlayerMark(vic, trigger_name..skill_qc)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(p, p:getCards("he"), true)
			end
		end
	end
end

function activateAllSkills(vic, trigger_name)
	local room = vic:getRoom()
	local Qingchenglist = vic:getTag("Qingcheng"):toString():split("+")
	if #Qingchenglist > 0 then
		for _, name in ipairs(Qingchenglist) do
			room:setPlayerMark(vic, "Qingcheng"..name, 0)
			room:setPlayerMark(vic, trigger_name..name, 0)
		end
		vic:removeTag("Qingcheng")
		for _, t in sgs.qlist(room:getAllPlayers()) do
			room:filterCards(t, t:getCards("he"), true)
		end
	end
end

sgkgodweizhen = sgs.CreateTriggerSkillV2{
	name = "sgkgodweizhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.DamageCaused, sgs.EventAcquireSkill},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DrawNCards then
			-- 張遼本人摸牌階段的 +N（其餘受標記者的 -1 由全局 helper 處理）
			return skill:objectName()
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName ~= skill:objectName() then return false end
			return skill:objectName()
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if not (damage.from and damage.from:hasSkill(skill:objectName()) and damage.to:getMark("&nizhan") >= 3) then return false end
			return skill:objectName(), damage.from:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DrawNCards then
			local x = 0
			local draw = data:toDraw()
			if player:getMark("&nizhan") >= 2 then x = x - 1 end
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				if pe:getMark("&nizhan") >= 1 then x = x + 1 end
			end
			if x ~= 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
			if draw.reason == "draw_phase" then
				draw.num = draw.num + x
				data:setValue(draw)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from == player and damage.to:getMark("&nizhan") >= 3 then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				room:doAnimate(1, damage.from:objectName(), damage.to:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.EventAcquireSkill then
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				if pe:getMark("&nizhan") >= 4 and pe:getMark(self:objectName()) == 0 then
					--room:doAnimate(1, zhangliao:objectName(), pe:objectName())
					room:addPlayerMark(pe, self:objectName())
					forbidNonCompulsorySkills(pe, self:objectName())
				end
			end
		end
		return false
	end
}

--威震的標記懲罰作用在受標記角色身上；張遼死亡後仍須結算，故以全局隱藏技能承載
sgkgodweizhenMark = sgs.CreateTriggerSkillV2{
	name = "#sgkgodweizhen_mark",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.MarkChanged},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DrawNCards then
			if player:hasSkill("sgkgodweizhen") then return false end
			if player:getMark("&nizhan") >= 2 then return skill:objectName() end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&nizhan" and mark.who and mark.who:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then
				draw.num = draw.num - 1
				data:setValue(draw)
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&nizhan" then
				if player:getMark("&nizhan") >= 4 and player:getMark("sgkgodweizhen") == 0 then
					room:broadcastSkillInvoke("sgkgodweizhen")
					room:addPlayerMark(player, "sgkgodweizhen")
					forbidNonCompulsorySkills(player, "sgkgodweizhen")
				end
				if player:getMark("&nizhan") < 4 then
					if player:getMark("sgkgodweizhen") > 0 then
						room:setPlayerMark(player, "sgkgodweizhen", 0)
						activateAllSkills(player, "sgkgodweizhen")
					end
				end
			end
		end
		return false
	end
}

sgkgodweizhenClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodweizhenClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		-- 主技能實例在 EventLoseSkill 分發前已移除，清理由此 related helper 負責
		if data:toSkillChange().skillName == "sgkgodweizhen" then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		for _, pe in sgs.qlist(room:getAlivePlayers()) do
			if pe:getMark("sgkgodweizhen") > 0 then
				room:setPlayerMark(pe, "sgkgodweizhen", 0)
				activateAllSkills(pe, "sgkgodweizhen")
			end
		end
		return false
	end
}


sgkgodzhangliao:addSkill(sgkgodnizhan)
sgkgodzhangliao:addSkill(sgkgodcuifeng)
sgkgodzhangliao:addSkill(sgkgodweizhen)


sgs.LoadTranslationTable{
	["sgkgodzhangliao"] = "神张辽",
	["&sgkgodzhangliao"] = "神张辽",
	["#sgkgodzhangliao"] = "威名裂胆",
	["sgkgodnizhan"] = "逆战",
	[":sgkgodnizhan"] = "锁定技，一名角色的准备阶段，若其：已受伤，获得1个“逆战”标记；未受伤，移去1个“逆战”标记。",
	["nizhan"] = "逆战",
	["$sgkgodnizhan"] = "已是成败二分之时！",
	["sgkgodcuifeng"] = "摧锋",
	[":sgkgodcuifeng"] = "出牌阶段限一次，你可以移动场上的1枚“逆战”标记，然后失去标记的角色视为对获得标记的角色使用一张无次数与距离限制的【杀】。",
	["$sgkgodcuifeng"] = "全军化为一体，总攻！",
	["sgkgodweizhen"] = "威震",
	[":sgkgodweizhen"] = "锁定技，摸牌阶段，你额外摸X张牌（X为有“逆战”标记的角色数）。若一名角色的“逆战”标记数不小于：2，其摸牌阶段少摸一张牌；3，你对其造成的伤"..
	"害+1；4，其非锁定技失效。",
	["$sgkgodweizhen"] = "让你见识我军的真正实力！",
	["~sgkgodzhangliao"] = "不求留名青史，但求无愧于心……",
	["designer:sgkgodzhangliao"] = "极略三国",
	["illustrator:sgkgodzhangliao"] = "极略三国",
	["cv:sgkgodzhangliao"] = "极略三国",
}


--神陆逊
sgkgodluxun=sgs.General(extension,"sgkgodluxun","sy_god",3)


--[[
	技能名：劫焰
	相关武将：神陆逊
	技能描述：当一名角色使用红色【杀】或红色普通锦囊牌指定唯一目标后，你可以弃置一张手牌并令此牌无效，然后对目标角色造成1点火焰伤害。
	引用：sgkgodjieyan
]]--
sgkgodjieyan = sgs.CreateTriggerSkillV2{
	name = "sgkgodjieyan",
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.card and use.card:isRed()) then return false end
		if use.to:length() ~= 1 then return false end
		if not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if not s:isKongcheng() then
				table.insert(names, skill:objectName())
				table.insert(owners, s:objectName())
			end
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if not player:askForSkillInvoke(skill:objectName(), data) then return false end
		local prompt = string.format("@sgkgodjieyan:%s:%s", use.card:objectName(), use.to:at(0):objectName())
		local c = room:askForCard(player, ".|.|.|hand|.", prompt, data, sgs.Card_MethodDiscard)
		if not c then return false end
		return true
	end,
	on_effect = function(self, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:broadcastSkillInvoke(self:objectName())
		local to = use.to:at(0)
		local log = sgs.LogMessage()
		log.type = "#jieyan"
		log.from = player
		log.to:append(use.from)
		log.arg = use.card:objectName()
		room:sendLog(log)
		room:doAnimate(1, player:objectName(), to:objectName())
		local nullified_list = use.nullified_list
		table.insert(nullified_list, to:objectName())
		use.nullified_list = nullified_list
		ctx.original_data:setValue(use)
		room:damage(sgs.DamageStruct(self:objectName(), player, to, 1, sgs.DamageStruct_Fire))
		return false
	end
}


--[[
	技能名：焚营
	相关武将：神陆逊
	技能描述：当一名角色受到火焰伤害后，你可以摸一张牌，然后你可以弃置X张牌（X为你本回合发动“焚营”的次数），并对其或与其距离最近的一名角色造成等量火焰伤害。
	引用：sgkgodfenying
]]--
sgkgodfenying = sgs.CreateTriggerSkillV2{
	name = "sgkgodfenying",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if not (damage.to and damage.to:isAlive()) then return false end
		if damage.nature ~= sgs.DamageStruct_Fire then return false end
		if damage.damage <= 0 then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local n = damage.damage
		room:notifySkillInvoked(player, self:objectName())
		player:drawCards(1, self:objectName())
		room:addPlayerMark(player, "&sgkgodfenying-Clear")
		local distance = 1000
		for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
			if p:distanceTo(damage.to) < distance then
				distance = p:distanceTo(damage.to)
			end
		end
		local all = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
			if p:distanceTo(damage.to) == distance then
				all:append(p)
			end
		end
		all:append(damage.to)
		if all:isEmpty() then return false end
		if player:getCards("he"):length() < player:getMark("&sgkgodfenying-Clear") then return false end
		local x = player:getMark("&sgkgodfenying-Clear")
		local prompt = string.format("@sgkgodfenying_discard:%s:%s", n, damage.to:objectName())
		local card = room:askForDiscard(player, self:objectName(), x, x, true, true, prompt)
		if card then
			local t = room:askForPlayerChosen(player, all, self:objectName())
			room:doAnimate(1, player:objectName(), t:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), player, t, n, sgs.DamageStruct_Fire))
		end
		return false
	end
}


sgkgodluxun:addSkill(sgkgodjieyan)
sgkgodluxun:addSkill(sgkgodfenying)


sgs.LoadTranslationTable{
	["sgkgodluxun"] = "神陆逊",
	["&sgkgodluxun"] = "神陆逊",
	["#sgkgodluxun"] = "焚炎灭阵",
	["sgkgodjieyan"] = "劫焰",
	["#jieyan"] = "<font color=\"gold\"><b>【劫焰】</b></font>效果触发，%from 对 %to 使用的 %arg 无效。",
	[":sgkgodjieyan"] = "当一名角色使用红色【杀】或红色普通锦囊牌指定唯一目标后，你可以弃置一张手牌并令此牌无效，然后对目标角色造成1点火焰伤害。",
	["@sgkgodjieyan"] = "你可以弃置一张手牌，令此%src无效，并对%dest造成1点火焰伤害。",
	["sgkgodfenying"] = "焚营",
	[":sgkgodfenying"] = "当一名角色受到火焰伤害后，你可以摸一张牌，然后你可以弃置X张牌（X为你本回合发动“焚营”的次数），并对其或与其距离最近的一名角色造成等量火焰伤害。",
	["@sgkgodfenying"] = "你可以摸一张牌，然后弃置X张牌（X为你本回合发动“焚营”的次数）对其或与其距离最近的一名角色造成等量火焰伤害",
	["$sgkgodjieyan"] = "炙浊之气，已溢满万剑。",
	["$sgkgodfenying"] = "随着大火，往生去吧！",
	["~sgkgodluxun"] = "火，终究是……无情之物……",
	["designer:sgkgodluxun"] = "极略三国",
	["illustrator:sgkgodluxun"] = "极略三国",
	["cv:sgkgodluxun"] = "极略三国",
}


--神郭嘉
sgkgodguojia=sgs.General(extension,"sgkgodguojia","sy_god", 3, true)


--[[
	技能名：天启
	相关武将：神郭嘉
	技能描述：出牌阶段基本牌与普通锦囊牌各限一次，若你不处于濒死状态，当你需要使用或打出一张基本牌或普通锦囊牌时，你可以用牌堆顶的一张牌当作此牌使用或打出
	；若牌堆顶的牌与此牌类别不同，你使用此牌时失去1点体力。
	引用：sgkgodtianqi
]]--
function tianduguojia(guojia, c)
	local room = sgs.Sanguosha:currentRoom()
	local drawcard = sgs.QList2Table(room:getDrawPile())
	local id = drawcard[1]
	local card = sgs.Sanguosha:getCard(id)
	if card:isKindOf("BasicCard") and c:isKindOf("BasicCard") then return false end
	if card:isKindOf("TrickCard") and c:isKindOf("TrickCard") then return false end
	if card:isKindOf("EquipCard") and c:isKindOf("EquipCard") then return false end
	return true
end

sgkgodtianqiCard = sgs.CreateSkillCard{
	name = "sgkgodtianqi",
    will_throw = false,
	filter = function(self, targets, to_select, player)
		local players = sgs.PlayerList()
		for i = 1 , #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetFilter(players, to_select, player) and not player:isProhibited(to_select, card, players)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local _card = player:getTag("sgkgodtianqi"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:deleteLater()
		return card and card:targetFilter(players, to_select, player) and not player:isProhibited(to_select, card, players)
	end,
	feasible = function(self, targets, player)
		local players = sgs.PlayerList()
		for i = 1 , #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetsFeasible(players, player)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local _card = player:getTag("sgkgodtianqi"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:deleteLater()
		return card and card:targetsFeasible(players, player)
	end ,
	on_validate = function(self, card_use)
		local guojia = card_use.from
		local room = guojia:getRoom()
		if not guojia:isAlive() then return nil end
		local user_str = self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local tianqi_list = {}
			table.insert(tianqi_list, "slash")
			local sts = sgs.GetConfig("BanPackages", ""):split(",")
			if not table.contains(sts, "maneuvering") then
				table.insert(tianqi_list, "thunder_slash")
				table.insert(tianqi_list, "fire_slash")
			end
			user_str = room:askForChoice(guojia, "tianqi_slash", table.concat(tianqi_list, "+"))
			guojia:setTag("TianqiSlash", sgs.QVariant(user_str))
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local check_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
			local banned = (check_card:isKindOf("BasicCard") and guojia:hasFlag("tianqi_used_basic"))
				or (check_card:isKindOf("TrickCard") and guojia:hasFlag("tianqi_used_trick"))
			check_card:deleteLater()
			if banned then return nil end
		end
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local poi = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		local drawcard = sgs.QList2Table(room:getDrawPile())
		local id = drawcard[1]
		local card = sgs.Sanguosha:getCard(id)
		local ids = sgs.IntList()
		ids:append(id)
		room:fillAG(ids)
		local news = sgs.LogMessage()
		news.type = "#tianqiclaim"
		news.from = guojia
		news.arg = poi:objectName()
		room:sendLog(news)
		local log = sgs.LogMessage()
		log.type = "#tianqishow"
		log.from = guojia
		log.card_str = card:toString()
		room:sendLog(log)
		room:getThread():delay(500)
		room:clearAG()
		if tianduguojia(guojia, poi) then room:loseHp(guojia, 1, true, guojia, self:objectName()) end
		if guojia:isAlive() then
			local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
			use_card:setSkillName("sgkgodtianqi")
			use_card:addSubcard(card)
			use_card:deleteLater()
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(guojia, to, use_card)
				if skill then
					card_use.to:removeOne(to)
				end
			end
			return use_card
		else
			return nil
		end
	end ,
	on_validate_in_response = function(self, guojia)
		local room = guojia:getRoom()
		if not guojia:isAlive() then return nil end
		local to_tianqi = ""
		if self:getUserString() == "slash" then
			local tianqi_list = {}
			table.insert(tianqi_list, "slash")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(tianqi_list, "normal_slash")
				table.insert(tianqi_list, "thunder_slash")
				table.insert(tianqi_list, "fire_slash")
			end
			to_tianqi = room:askForChoice(guojia, "tianqi_slash", table.concat(tianqi_list, "+"))
			guojia:setTag("TianqiSlash", sgs.QVariant(to_tianqi))
		else
			to_tianqi = self:getUserString()
		end
		if room:getDrawPile():isEmpty() then room:swapPile() end
		local user_str = ""
		if to_tianqi == "slash" then
			user_str = "slash"
		elseif to_tianqi == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_tianqi
		end
		local poi = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
		local drawcard = sgs.QList2Table(room:getDrawPile())
		local id = drawcard[1]
		local card = sgs.Sanguosha:getCard(id)
		local ids = sgs.IntList()
		ids:append(id)
		room:fillAG(ids)
		local news = sgs.LogMessage()
		news.type = "#tianqiclaim"
		news.from = guojia
		news.arg = poi:objectName()
		room:sendLog(news)
		local log = sgs.LogMessage()
		log.type = "#tianqishow"
		log.from = guojia
		log.card_str = card:toString()
		room:sendLog(log)
		room:getThread():delay(500)
		room:clearAG()
		if tianduguojia(guojia, poi) then room:loseHp(guojia, 1, true, guojia, self:objectName()) end
		if guojia:isAlive() then
			local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
			use_card:setSkillName("sgkgodtianqi")
			use_card:addSubcard(card)
			use_card:deleteLater()
			return use_card
		else
			return nil
		end
	end
}

sgkgodtianqiVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodtianqi",
	n = 0,
	response_or_use = true,
	guhuo_type = "lr",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:hasFlag("Global_Dying") then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not (player:hasFlag("tianqi_used_basic") and player:hasFlag("tianqi_used_trick"))
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then return false end
			if pattern == "peach" then
				return not player:hasFlag("Global_PreventPeach")
			end
			if string.find(pattern, "[%u%d]") then return false end
			return true
		end
		return false
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player or player:hasFlag("Global_Dying") then return nil end
		local pattern
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local user_str = request:getUserString()
			if user_str and user_str ~= "" then
				pattern = user_str
			else
				local c = player:getTag("sgkgodtianqi"):toCard()
				if c then
					pattern = c:objectName()
				else
					return nil
				end
			end
		else
			local user_str = request:getUserString()
			if user_str and user_str ~= "" then
				pattern = user_str
			elseif player:getTag("TianqiSlash"):toString() ~= "" then
				pattern = player:getTag("TianqiSlash"):toString()
			else
				pattern = request:getPattern()
			end
		end
		if pattern and pattern ~= "" then
			local tq = sgkgodtianqiCard:clone()
			tq:setUserString(pattern)
			return tq
		end
		return nil
	end,
}

sgkgodtianqi = sgs.CreateTriggerSkillV2{
	name = "sgkgodtianqi",
	events= {sgs.PreCardUsed, sgs.EventPhaseChanging},
	view_as_skill = sgkgodtianqiVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if not (use.card and table.contains(use.card:getSkillNames(), "sgkgodtianqi")) then return false end
			if player:getPhase() ~= sgs.Player_Play then return false end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive or not (player:hasFlag("tianqi_used_basic") or player:hasFlag("tianqi_used_trick")) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if event == sgs.PreCardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card:isKindOf("BasicCard") and not player:hasFlag("tianqi_used_basic") then
				room:setPlayerFlag(player, "tianqi_used_basic")
			elseif use.card:isKindOf("TrickCard") and not player:hasFlag("tianqi_used_trick") then
				room:setPlayerFlag(player, "tianqi_used_trick")
			end
		else
			room:setPlayerFlag(player, "-tianqi_used_basic")
			room:setPlayerFlag(player, "-tianqi_used_trick")
		end
		return false
	end
}
sgkgodtianqi:setGuhuoDialog("lr")


--[[
	技能名：天机
	相关武将：神郭嘉
	技能描述：一名角色的出牌阶段开始时，你可以观看牌堆顶的三张牌并可以获得其中一张牌，然后你将其余牌以任意顺序放回牌堆顶。
	引用：sgkgodtianji
]]--
sgkgodtianji=sgs.CreateTriggerSkillV2{
	name = "sgkgodtianji",
	priority = -2,
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if room:getDrawPile():isEmpty() then room:swapPile() end
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local s = player
		room:broadcastSkillInvoke(self:objectName())
		local ids = room:getNCards(3, false)
		room:fillAG(ids, s)
		room:getThread():delay(450)
		local id = room:askForAG(s, ids, true, self:objectName())
		room:clearAG(s)
		if id ~= -1 then
			ids:removeOne(id)
			room:obtainCard(s, id, "sgkgodtianji", false)
		end
		if ids:length() > 0 then
			room:askForGuanxing(s, ids, sgs.Room_GuanxingUpOnly)
		end
		return false
	end
}


sgkgodguojia:addSkill(sgkgodtianqi)
sgkgodguojia:addSkill(sgkgodtianji)


sgs.LoadTranslationTable{
	["sgkgodguojia"] = "神郭嘉",
	["&sgkgodguojia"] = "神郭嘉",
	["#sgkgodguojia"] = "天人合一",
	["#tianqishow"] = "%from 亮出了牌堆顶的 %card",
	["sgkgodtianqi"] = "天启",
	[":sgkgodtianqi"] = "出牌阶段基本牌与普通锦囊牌各限一次，若你不处于濒死状态，当你需要使用或打出一张基本牌或普通锦囊牌时，你可以用牌堆顶的一张牌当作此牌使"..
	"用或打出；若牌堆顶的牌与此牌类别不同，你使用此牌时失去1点体力。",
	["#tianqishow"] = "%from 亮出了牌堆顶的 %card",
	["tianqi_slash"] = "天启",
	["#tianqiclaim"] = "%from 声明了【%arg】",
	["sgkgodtianji"] = "天机",
	[":sgkgodtianji"] = "一名角色的出牌阶段开始时，你可以观看牌堆顶的三张牌并可以获得其中一张牌，然后你将其余牌以任意顺序放回牌堆顶。",
	["$sgkgodtianqi1"] = "荡破天光，领得天启！",
	["$sgkgodtianqi2"] = "谋事在人，成事在天。",
	["$sgkgodtianji"] = "天机可知，却不可说。",
	["~sgkgodguojia"] = "窥天意，竭心力，皆为吾主！",
	["designer:sgkgodguojia"] = "极略三国",
	["illustrator:sgkgodguojia"] = "极略三国",
	["cv:sgkgodguojia"] = "极略三国",
}


--神吕布
sgkgodlvbu = sgs.General(extension, "sgkgodlvbu", "sy_god", 5)



--[[
	技能名：狂暴
	相关武将：神吕布
	技能描述：锁定技，游戏开始时，你获得2枚“狂暴”标记。当你造成或受到伤害后，你获得1枚“狂暴”标记。当你受到伤害后，你摸两张牌。
	引用：sgkgodkuangbao
]]--
sgkgodkuangbao = sgs.CreateTriggerSkillV2{
    name = "sgkgodkuangbao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Damaged, sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if event == sgs.GameStart then
		    room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			player:gainMark("&fierce", 2)
		else
		    room:broadcastSkillInvoke(self:objectName())
			local X = 0
			if player:hasSkill("sgkgodwuqian") and player:getMark("&fierce") >= 4 and event == sgs.Damage then
			    X = 2
			else
			    X = 1
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			player:gainMark("&fierce", X)
			if event == sgs.Damaged then
				player:drawCards(2, self:objectName())
			end
		end
		return false
	end
}


--[[
	技能名：无谋
	相关武将：神吕布
	技能描述：锁定技，当你使用普通锦囊牌时，你弃置1枚“狂暴”标记或受到1点伤害；且此牌不能被【无懈可击】响应。
	引用：sgkgodwumou
]]--
sgkgodwumou = sgs.CreateTriggerSkillV2{
	name = "sgkgodwumou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if use.card:isNDTrick() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local num = player:getMark("&fierce")
			if num >= 1 and room:askForChoice(player, self:objectName(), "loseonemark+getdamaged") == "loseonemark" then
				player:loseMark("&fierce")
			else
				room:damage(sgs.DamageStruct(self:objectName(), player, player))
			end
			local no_offset_list = use.no_offset_list
			for _, t in sgs.qlist(room:getAlivePlayers()) do
				table.insert(no_offset_list, t:objectName())
			end
			use.no_offset_list = no_offset_list
			data:setValue(use)
		end
		return false
	end
}


--[[
	技能名：无前
	相关武将：神吕布
	技能描述：锁定技，若你有不少于4枚“狂暴”标记，你获得“无双”和“神戟”；且当你造成伤害后，额外获得1枚该标记。
	引用：sgkgodwuqian
]]--
sgkgodwuqian = sgs.CreateTriggerSkillV2{
	name = "sgkgodwuqian",
	events = {sgs.MarkChanged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local mark = data:toMark()
		if mark.name == "&fierce" then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local mark = data:toMark()
		if mark.name == "&fierce" then
			if mark.gain > 0 then
				if player:getMark("&fierce") >= 4 then
					local lacked = {}
					if not player:hasSkill("sy_shenji") then table.insert(lacked, "sy_shenji") end
					if not player:hasSkill("wushuang") then table.insert(lacked, "wushuang") end
					if #lacked > 0 then
						player:setTag("wuqian_buff", sgs.QVariant(table.concat(lacked, "|")))
						room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
						room:handleAcquireDetachSkills(player, table.concat(lacked, "|"))
					end
				end
			elseif mark.gain < 0 then
				if player:getMark("&fierce") < 4 then
					local has = player:getTag("wuqian_buff"):toString():split("|")
					if #has > 0 then
						player:removeTag("wuqian_buff")
						room:handleAcquireDetachSkills(player, "-"..table.concat(has, "|-"))
					end
				end
			end
		end
		return false
	end
}


--[[
	技能名：神愤
	相关武将：神吕布
	技能描述：出牌阶段限一次，你可以弃置6枚“狂暴”标记，然后对所有其他角色各造成1点伤害，然后这些角色弃置所有牌，你翻面。
	引用：sgkgodshenfen
]]--
sgkgodshenfenCard = sgs.CreateSkillCard{
	name = "sgkgodshenfenCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		source:loseMark("&fierce", 6)
		room:doSuperLightbox("sgkgodlvbu", "sgkgodshenfen")
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:doAnimate(1, source:objectName(), player:objectName())
		end
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("sgkgodshenfen", source, player))
		end
		for _, player in sgs.qlist(players) do
			player:throwAllHandCardsAndEquips()
		end
		source:turnOver()
	end
}

sgkgodshenfen = sgs.CreateViewAsSkillV2{
	name = "sgkgodshenfen",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("&fierce") >= 6 and not player:hasUsed("sgkgodshenfen")
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodshenfenCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodshenfen", instance_id)
		card:setSourceSkill("sgkgodshenfen", instance_id)
		return card
	end
}


sgkgodlvbu:addSkill(sgkgodkuangbao)
sgkgodlvbu:addSkill(sgkgodwumou)
sgkgodlvbu:addSkill(sgkgodwuqian)
sgkgodlvbu:addSkill(sgkgodshenfen)


sgs.LoadTranslationTable{
    ["sgkgodlvbu"] = "神吕布",
	["&sgkgodlvbu"] = "神吕布",
	["#sgkgodlvbu"] = "修罗之道",
	["~sgkgodlvbu"] = "我不会消失！不会——",
	["fierce"] = "狂暴",
	["sgkgodkuangbao"] = "狂暴",
	[":sgkgodkuangbao"] = "锁定技，游戏开始时，你获得2枚“狂暴”标记。当你造成或受到伤害后，你获得1枚“狂暴”标记。当你受到伤害后，你摸两张牌。",
	["$sgkgodkuangbao"] = "找死！",
	["sgkgodwumou"] = "无谋",
	[":sgkgodwumou"] = "锁定技，当你使用普通锦囊牌时，你弃置1枚“狂暴”标记或受到1点伤害；且此牌不能被【无懈可击】响应。",
	["loseonemark"] = "弃置1枚“狂暴”标记",
	["getdamaged"] = "受到1点伤害",
	["$sgkgodwumou"] = "老子可不管这些！",
	["sgkgodwuqian"] = "无前",
	[":sgkgodwuqian"] = "锁定技，若你有不少于4枚“狂暴”标记，你获得“无双”和“神戟”；且当你造成伤害后，额外获得1枚该标记。",
	["$sgkgodwuqian"] = "看你还能挣扎多久？",
	["sgkgodshenfen"] = "神愤",
	[":sgkgodshenfen"] = "出牌阶段限一次，你可以弃置6枚“狂暴”标记，然后对所有其他角色各造成1点伤害，然后这些角色弃置所有牌，你翻面。",
	["$sgkgodshenfen"] = "神挡杀神！佛挡杀佛！",
	["designer:sgkgodlvbu"] = "极略三国",
    ["illustrator:sgkgodlvbu"] = "极略三国",
    ["cv:sgkgodlvbu"] = "极略三国",
}


--神关羽
sgkgodguanyu = sgs.General(extension, "sgkgodguanyu", "sy_god", 5)


--[[
	技能名：武神
	相关武将：神关羽
	技能描述：锁定技，你的【杀】和【桃】只能当作【决斗】使用。你对其他魔势力或神势力角色造成伤害时，此伤害+1。
	引用：sgkgodwushen
]]--
--DEFER:sgkgodwushen:CreateFilterSkill 無 V2 API
sgkgodwushen = sgs.CreateFilterSkill{
    name = "sgkgodwushen",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Slash") or to_select:isKindOf("Peach")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
		duel:setSkillName(self:objectName())
		local wushen = sgs.Sanguosha:getWrappedCard(card:getId())
		wushen:takeOver(duel)
		return wushen
	end
}

sgkgodwushenDamage = sgs.CreateTriggerSkillV2{
	name = "#sgkgodwushenDamage",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() ~= player:objectName()
			and (damage.to:getKingdom() == "sy_god" or damage.to:getKingdom() == "sgk_magic") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		room:sendCompulsoryTriggerLog(player, "sgkgodwushen")
		damage.damage = damage.damage + 1
		data:setValue(damage)
		return false
	end
}


--[[
	技能名：索魂
	相关武将：神关羽
	技能描述：锁定技，当你对其他角色造成伤害后，或当你受到其他角色造成的1点伤害后，其获得1个“索魂”标记。当你进入濒死状态时，你将体力上限减半并回复体力至上限
	（向上取整），然后有“索魂”标记的角色弃置其所有“索魂”标记，并受到你造成的等量伤害。
	引用：sgkgodsuohun
]]--
sgkgodsuohun = sgs.CreateTriggerSkillV2{
    name = "sgkgodsuohun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.Damaged, sgs.Dying},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:objectName() ~= player:objectName() then return skill:objectName() end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() and damage.to and damage.to:objectName() == player:objectName() then return skill:objectName() end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who and dying.who:objectName() == player:objectName() then return skill:objectName() end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damage then
		    local damage = data:toDamage()
			if damage.from and damage.to:objectName() ~= player:objectName() then
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				damage.to:gainMark("&sk_soul", 1)
			end
		elseif event == sgs.Damaged then
		    local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() and damage.to:objectName() == player:objectName() then
			    room:doAnimate(1, player:objectName(), damage.from:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				damage.from:gainMark("&sk_soul", damage.damage)
			end
		elseif event == sgs.Dying then
		    local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
			    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				local n = math.ceil(player:getMaxHp()/2)
				room:loseMaxHp(player, n)
				if player:isDead() then return false end
				local re = sgs.RecoverStruct()
			    re.who = player
				re.recover = player:getMaxHp() - player:getHp()
		        room:recover(player, re, true)
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				    room:doAnimate(1, player:objectName(), t:objectName())
				end
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				    room:setPlayerMark(t, "suohun_temp", t:getMark("&sk_soul"))
					t:loseAllMarks("&sk_soul")
				end
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				    local n = t:getMark("suohun_temp")
				    if n > 0 then
						room:setPlayerMark(t, "suohun_temp", 0)
						room:damage(sgs.DamageStruct(self:objectName(), player, t, n))
					end
				end
			end
		end
		return false
	end
}

sgkgodsuohunClear = sgs.CreateTriggerSkillV2{
    name = "#sgkgodsuohun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if player:hasSkill("sgkgodsuohun") then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local death = ctx.original_data:toDeath()
		if death.who:objectName() == player:objectName() then
		    for _, t in sgs.qlist(room:getAllPlayers()) do
			    if t:getMark("&sk_soul") > 0 then t:loseAllMarks("&sk_soul") end
			end
		end
		return false
	end
}



sgkgodguanyu:addSkill(sgkgodwushen)
extension:insertRelatedSkills("sgkgodwushen", "#sgkgodwushenDamage")
sgkgodguanyu:addSkill(sgkgodsuohun)
extension:insertRelatedSkills("sgkgodsuohun", "#sgkgodsuohun")


sgs.LoadTranslationTable{
    ["sgkgodguanyu"] = "神关羽",
	["&sgkgodguanyu"] = "神关羽",
	["#sgkgodguanyu"] = "鬼神再临",
	["~sgkgodguanyu"] = "吾一世英名，竟葬于小人之手！",
	["sk_soul"] = "索魂",
	["sgkgodwushen"] = "武神",
	[":sgkgodwushen"] = "锁定技，你的【杀】和【桃】只能当作【决斗】使用。你对其他魔势力或神势力角色造成伤害时，此伤害+1。",
	["$sgkgodwushen"] = "武神现世，天下莫敌！",
	["sgkgodsuohun"] = "索魂",
	[":sgkgodsuohun"] = "锁定技，当你对其他角色造成伤害后，或当你受到其他角色造成的1点伤害后，其获得1个“索魂”标记。当你进入濒死状态时，你将体力上限减半并回复体力至"..
	"上限（向上取整），然后有“索魂”标记的角色弃置其所有“索魂”标记，并受到你造成的等量伤害。",
	["$sgkgodsuohun"] = "还不速速领死！",
	["designer:sgkgodguanyu"] = "极略三国",
    ["illustrator:sgkgodguanyu"] = "极略三国",
    ["cv:sgkgodguanyu"] = "极略三国",
}


--神司马懿
sgkgodsima = sgs.General(extension, "sgkgodsima", "sy_god", "3", true)


--[[
	技能名：极略
	相关武将：神司马懿
	技能描述：锁定技，当你使用一张牌后，你摸一张牌。
	引用：sgkgodjilue
]]--
sgkgodjilue = sgs.CreateTriggerSkillV2{
	name = "sgkgodjilue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
		player:drawCards(1, self:objectName())
		return false
	end
}


--[[
	技能名：通天
	相关武将：神司马懿
	技能描述：限定技，出牌阶段，你可以摸四张牌，然后弃置至多四张花色不同的牌，你根据这些牌的花色获得对应技能：黑桃，“反馈”；梅花，“完杀”；方块，“制衡”；红桃，“观星”。
	引用：sgkgodtongtian
]]--
sgkgodtongtianCard = sgs.CreateSkillCard{
	name = "sgkgodtongtianCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern():startsWith("@@sgkgodtongtian") then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sgkgodtongtian","")
			room:throwCard(self, reason, nil)
			for _, id in sgs.qlist(self:getSubcards()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == sgs.Card_Spade then
					if (not source:hasSkill("fankui")) and (not source:hasSkill("nosfankui")) then room:acquireSkill(source, "nosfankui") end
				elseif c:getSuit() == sgs.Card_Heart then
					if not source:hasSkill("guanxing") then room:acquireSkill(source, "guanxing") end
				elseif c:getSuit() == sgs.Card_Club then
					if not source:hasSkill("wansha") and (not source:hasSkill("olwansha")) then room:acquireSkill(source, "wansha") end
				elseif c:getSuit() == sgs.Card_Diamond then
					if (not source:hasSkill("zhiheng")) and (not source:hasSkill("tenyearzhiheng")) then room:acquireSkill(source, "zhiheng") end
				end
			end
		else
			if source:isNude() then return false end
			room:broadcastSkillInvoke("sgkgodtongtian")
			room:doSuperLightbox("sgkgodsima", "sgkgodtongtian")
			source:loseMark("@tian")
			source:drawCards(4, "sgkgodtongtian")
			room:askForUseCard(source, "@@sgkgodtongtian", "@sgkgodtongtian")
		end
	end
}

sgkgodtongtianViewAsSkill = sgs.CreateViewAsSkillV2{
	name = "sgkgodtongtian",
	n = 4,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getMark("@tian") >= 1 and not player:hasUsed("sgkgodtongtian")
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.startsWith(pattern, "@@sgkgodtongtian")
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		local pattern = request:getPattern() or ""
		if not string.startsWith(pattern, "@@sgkgodtongtian") then return false end
		local selected = request:getSelectedCardIds()
		if #selected >= 4 then return false end
		for _, id in sgs.qlist(selected) do
			local c = sgs.Sanguosha:getCard(id)
			if c and c:getSuit() == to_select:getSuit() then return false end
		end
		return not request:getInitiator():isJilei(to_select)
	end,
	card_selection_feasible = function(skill, request)
		local pattern = request:getPattern() or ""
		local n = #request:getSelectedCardIds()
		if string.startsWith(pattern, "@@sgkgodtongtian") then
			return n >= 1 and n <= 4
		end
		return n == 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local ttCard = sgkgodtongtianCard:clone()
		for _, id in sgs.qlist(ids) do
			ttCard:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			ttCard:setSkillInstanceId(instance_id)
			ttCard:setActivationSkill("sgkgodtongtian", instance_id)
			ttCard:setSourceSkill("sgkgodtongtian", instance_id)
		end
		return ttCard
	end
}

sgkgodtongtian = sgs.CreateTriggerSkillV2{
	name = "sgkgodtongtian",
	frequency = sgs.Skill_Limited,
	limit_mark = "@tian",
	events = {},
	view_as_skill = sgkgodtongtianViewAsSkill,
}


sgkgodsima:addSkill(sgkgodjilue)
sgkgodsima:addSkill(sgkgodtongtian)
sgkgodsima:addRelateSkill("nosfankui")
sgkgodsima:addRelateSkill("zhiheng")
sgkgodsima:addRelateSkill("guanxing")
sgkgodsima:addRelateSkill("wansha")


sgs.LoadTranslationTable{
	["sgkgodsima"] = "神司马懿",
	["&sgkgodsima"] = "神司马懿",
	["~sgkgodsima"] = "生门已闭，唯有赴死……",
	["#sgkgodsima"]= "晋国之祖",
	["sgkgodjilue"] = "极略",
	["$sgkgodjilue1"] = "轻举妄为，徒招横祸。",
	["$sgkgodjilue2"] = "因果有律，世间无常。",
	["$sgkgodjilue3"] = "万物无一，强弱有变。",
	[":sgkgodjilue"] = "锁定技，当你使用一张牌后，你摸一张牌。",
	["@sgkgodtongtian"] = "【通天】请弃置至多四张花色不同的牌",
	["sgkgodtongtian"] = "通天",
	["$sgkgodtongtian"] = "反乱不除，必生枝节。",
	["@tian"] = "通天",
	[":sgkgodtongtian"] = "限定技，出牌阶段，你可以摸四张牌，然后弃置至多四张花色不同的牌，你根据这些牌的花色获得对应技能：黑桃，“反馈”；梅花，“完杀”；方块，“制衡”；"..
	"红桃，“观星”。",
	["$nosfankui3"] = "逆势而为，不自量力。",
	["$guanxing5"] = "吾之身前，万籁俱静。",
	["$zhiheng3"] = "吾之身后，了无生机。",
	["$wansha5"] = "狂战似魔，深谋如鬼。",
	["designer:sgkgodsima"] = "极略三国",
	["illustrator:sgkgodsima"] = "极略三国",
	["cv:sgkgodsima"] = "极略三国",
}


--神曹操
sgkgodcaocao = sgs.General(extension, "sgkgodcaocao", "sy_god", 3)


--[[
	技能名：归心
	相关武将：神曹操
	技能描述：当你受到1点伤害后，你可以随机获得所有其他角色区域内的各一张牌，然后若你于此次结算中获得的牌数小于4，你重复此流程；若如此做，你翻面。
	引用：sgkgodguixin
]]--
sgkgodguixin = sgs.CreateTriggerSkillV2{
    name = "sgkgodguixin",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() then return false end
		local damage = data:toDamage()
		if not damage or damage.damage < 1 then return false end
		return skill:objectName().."*"..damage.damage
	end,
	on_cost = function(skill, event, room, player, ctx)
		player:addMark("guixin_times")
		if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then
			player:setMark("guixin_times", 0)
			return false
		end
		player:setFlags("guixin_using")
		return true
	end,
	on_effect = function(self, event, room, player, ctx)
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("sgkgodcaocao", self:objectName())
		local gained = 0
		repeat
			local round_got = 0
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			    local ids = {}
			    if p:isAlive() then
				    for _, c in sgs.qlist(p:getCards("hej")) do
					    if player:canGet(p, c:getEffectiveId()) then table.insert(ids, c:getEffectiveId()) end
				    end
			    end
			    if #ids > 0 then
				    local card_id = ids[math.random(#ids)]
				    room:doAnimate(1, player:objectName(), p:objectName())
				    room:obtainCard(player, sgs.Sanguosha:getCard(card_id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), p:objectName(), "sgkgodguixin", ""), false)
				    gained = gained + 1
				    round_got = round_got + 1
				end
			end
			if round_got == 0 then break end
		until gained >= 4
		player:turnOver()
		player:setFlags("-guixin_using")
		player:setMark("guixin_times", 0)
		return false
	end
}


--[[
	技能名：飞影
	相关武将：神曹操
	技能描述：锁定技，若你未受伤，你使用黑色【杀】无距离与次数限制；若你已受伤，你手牌中的红色装备牌均视为【桃】。
	引用：sgkgodfeiying
]]--
sgkgodfeiying = sgs.CreateFilterSkill{
    name = "sgkgodfeiying",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local owner = room:getCardOwner(to_select:getEffectiveId())
		if not (owner and owner:hasSkill(self:objectName()) and owner:isWounded()) then return false end
		return to_select:isKindOf("EquipCard") and to_select:isRed()
			and room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		local wrapped = sgs.Sanguosha:getWrappedCard(card:getId())
		wrapped:takeOver(peach)
		return wrapped
	end
}

sgkgodfeiyingSlash = sgs.CreateProhibitSkillV2{
    name = "#sgkgodfeiying",
	holder_selector = sgs.CorrectSkill_Secondary,
	is_prohibited = function(self, ctx)
	    local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
	    if to:hasSkill("sgkgodfeiying") and (not to:faceUp()) then
		    return card:isKindOf("Slash")
		end
	end
}


extension:insertRelatedSkills("sgkgodfeiying", "#sgkgodfeiying")

sgkgodcaocao:addSkill(sgkgodguixin)
sgkgodcaocao:addSkill(sgkgodfeiying)


sgs.LoadTranslationTable{
	["sgkgodcaocao"] = "神曹操",
	["#sgkgodcaocao"] = "超世英杰",
	["&sgkgodcaocao"] = "神曹操",
	["~sgkgodcaocao"] = "就让大地，成为我的棺木吧……",
	["sgkgodguixin"] = "归心",
	["$sgkgodguixin"] = "周公吐哺，天下归心！",
	[":sgkgodguixin"] = "当你受到1点伤害后，你可以随机获得所有其他角色区域内的各一张牌，然后若你于此次结算中获得的牌数小于4，你重复此流程；若如此做，你翻面。",
	["sgkgodfeiying"] = "飞影",
	[":sgkgodfeiying"] = "锁定技，若你未受伤，你使用黑色【杀】无距离与次数限制；若你已受伤，你手牌中的红色装备牌均视为【桃】。",
	["designer:sgkgodcaocao"] = "极略三国",
	["illustrator:sgkgodcaocao"] = "极略三国",
	["cv:sgkgodcaocao"] = "极略三国",
}


--神诸葛
sgkgodzhuge = sgs.General(extension, "sgkgodzhuge", "sy_god", 3)


--[[
	技能名：七星
	相关武将：神诸葛
	技能描述：你的起始手牌数+7。分发起始手牌后，你将其中至少7张牌扣置于武将牌旁，称为“星”；摸牌阶段结束时，你可以用至少一张手牌替换等量的“星”。你每有一张“星”，手牌上限+1
	引用：sgkgodqixing
]]--
sgkgodqixingCard = sgs.CreateSkillCard{
	name = "sgkgodqixingCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local pile = source:getPile("xing")
		local subCards = self:getSubcards()
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("xing")
		for _,id in sgs.qlist(subCards) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not subCards:contains(id) then
				to_handcard:append(id)
			elseif not pile:contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "sgkgodqixing")
		source:addToPile("xing", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), "sgkgodqixing", "")
		room:obtainCard(source, to_handcard_x, reason, false)
	end,
}

sgkgodqixingVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodqixing",
	n = 998,
	response_or_use = true,
	expand_pile = "xing",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return string.startsWith(pattern, "@@sgkgodqixing")
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not player then return false end
		if #request:getSelectedCardIds() < player:getPile("xing"):length() then
			return not to_select:isEquipped()
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		return player and #request:getSelectedCardIds() == player:getPile("xing"):length()
	end,
	create_card = function(skill, request)
		local c = sgkgodqixingCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			c:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			c:setSkillInstanceId(instance_id)
			c:setActivationSkill("sgkgodqixing", instance_id)
			c:setSourceSkill("sgkgodqixing", instance_id)
		end
		return c
	end,
}

sgkgodqixing = sgs.CreateTriggerSkillV2{
	name = "sgkgodqixing",
	events = {sgs.EventPhaseEnd},
	view_as_skill = sgkgodqixingVS,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:getPile("xing"):length() > 0
			and player:getPhase() == sgs.Player_Draw then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		room:askForUseCard(player, "@@sgkgodqixing", "@qixing-exchange", -1, sgs.Card_MethodNone)
		return false
	end,
}

sgkgodqixingStart = sgs.CreateTriggerSkillV2{
	name = "#sgkgodqixingStart",
	events = {sgs.DrawNCards,sgs.AfterDrawNCards},
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "InitialHandCards" then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			room:sendCompulsoryTriggerLog(player, "sgkgodqixing", true, true)
			draw.num = draw.num + 7
			data:setValue(draw)
		elseif event == sgs.AfterDrawNCards then
			local exchange_card = room:askForExchange(player, "sgkgodqixing", 999, 7)
			player:addToPile("xing", exchange_card:getSubcards(), false)
			exchange_card:deleteLater()
		end
		return false
	end,
}

sgkgodqixingAsk = sgs.CreateTriggerSkillV2{
	name = "#sgkgodqixingAsk",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPile("xing"):length() <= 0 then return false end
		if player:getPhase() == sgs.Player_Start and player:hasSkill("sgkgodkuangfeng") then
			return skill:objectName()
		end
		if player:getPhase() == sgs.Player_Finish and player:hasSkill("sgkgoddawu") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Start then
			if player:getPile("xing"):length() > 0 and player:hasSkill("sgkgodkuangfeng") then
				room:askForUseCard(player, "@@sgkgodkuangfeng", "@kuangfeng-card", -1, sgs.Card_MethodNone)
			end
		end
		if player:getPhase() == sgs.Player_Finish then
			if player:getPile("xing"):length() > 0 and player:hasSkill("sgkgoddawu") then
				room:askForUseCard(player, "@@sgkgoddawu", "@dawu-card", -1, sgs.Card_MethodNone)
			end
		end
		return false
	end,
}

sgkgodqixingClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodqixingClear",
	events = {sgs.EventPhaseStart, sgs.Death, sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart or event == sgs.Death then
			if event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then return false end
			end
			if not player:getTag("sgkgodqixing_user"):toBool() then return false end
			if not ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or event == sgs.Death) then return false end
			return skill:objectName()
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "sgkgodqixing" then return skill:objectName() end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart or event == sgs.Death then
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				p:loseAllMarks("&dawu")
			end
			player:removeTag("sgkgodqixing_user")
		elseif event == sgs.EventLoseSkill and data:toSkillChange().skillName == "sgkgodqixing" then
			player:clearOnePrivatePile("xing")
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				p:loseAllMarks("&dawu")
				p:loseAllMarks("&kuangfeng")
			end
		end
		return false
	end,
}


--[[
	技能名：狂风
	相关武将：神诸葛
	技能描述：准备阶段，你可以将一张“星”置入弃牌堆并选择一名其他角色，该角色获得一个“狂风”标记。当有此标记的角色受到伤害时，若此伤害：无属性，你摸X张牌；火焰伤害，
	此伤害+X；雷电伤害，你将牌堆顶的一张牌置入“星”（X为其“狂风”标记数）。
	引用：sgkgodkuangfeng
]]--
sgkgodkuangfengCard = sgs.CreateSkillCard{
	name = "sgkgodkuangfengCard",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "sgkgodkuangfeng", "")
		effect.to:getRoom():throwCard(self, reason, nil)
		effect.from:setTag("sgkgodqixing_user", sgs.QVariant(true))
		effect.to:gainMark("&kuangfeng")
	end,
}

sgkgodkuangfengVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodkuangfeng",
	n = 1,
	response_or_use = true,
	expand_pile = "xing",
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return string.startsWith(pattern, "@@sgkgodkuangfeng")
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not player then return false end
		return player:getPile("xing"):contains(to_select:getId())
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected == 0 and request:getInitiator() and candidate:objectName() ~= request:getInitiator():objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local kf = sgkgodkuangfengCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			kf:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			kf:setSkillInstanceId(instance_id)
			kf:setActivationSkill("sgkgodkuangfeng", instance_id)
			kf:setSourceSkill("sgkgodkuangfeng", instance_id)
		end
		return kf
	end,
}

sgkgodkuangfeng = sgs.CreateTriggerSkillV2{
	name = "sgkgodkuangfeng",
	events = {sgs.DamageForseen},
	view_as_skill = sgkgodkuangfengVS,
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getMark("&kuangfeng") <= 0 then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local shenzhuge = player
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire then
		    room:broadcastSkillInvoke(self:objectName(), 2)
			room:doAnimate(1, shenzhuge:objectName(), damage.to:objectName())
			room:sendCompulsoryTriggerLog(shenzhuge, self:objectName())
			room:notifySkillInvoked(shenzhuge, self:objectName())
			damage.damage = damage.damage + damage.to:getMark("&kuangfeng")
			data:setValue(damage)
		elseif damage.nature == sgs.DamageStruct_Thunder then
		    room:broadcastSkillInvoke(self:objectName(), 2)
			room:doAnimate(1, shenzhuge:objectName(), damage.to:objectName())
			room:sendCompulsoryTriggerLog(shenzhuge, self:objectName())
			room:notifySkillInvoked(shenzhuge, self:objectName())
			if room:getDrawPile():length() < 1 then room:swapPile() end
			local id = room:getNCards(1, true)
			local c = id:first()
			local card = sgs.Sanguosha:getCard(c)
			shenzhuge:addToPile("xing", card, false)
		elseif damage.nature == sgs.DamageStruct_Normal then
		    room:broadcastSkillInvoke(self:objectName(), 2)
			room:doAnimate(1, shenzhuge:objectName(), damage.to:objectName())
			room:sendCompulsoryTriggerLog(shenzhuge, self:objectName())
			room:notifySkillInvoked(shenzhuge, self:objectName())
			shenzhuge:drawCards(damage.to:getMark("&kuangfeng"), self:objectName())
		end
		return false
	end,
}


--[[
	技能名：大雾
	相关武将：神诸葛
	技能描述：结束阶段，你可将任意张“星”置入弃牌堆，并令等量角色各获得一个“大雾”标记直到你的下一个回合开始。当有此标记的角色受到伤害时，若此伤害不是雷电伤害，
	防止之且该角色摸一张牌。
	引用：sgkgoddawu
]]--
sgkgoddawuCard = sgs.CreateSkillCard{
	name = "sgkgoddawuCard",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "sgkgoddawu", "")
		room:throwCard(self, reason, nil)
		source:setTag("sgkgodqixing_user", sgs.QVariant(true))
		for _,p in ipairs(targets) do
			p:gainMark("&dawu")
		end
	end,
}

sgkgoddawuVS = sgs.CreateViewAsSkillV2{
	name = "sgkgoddawu",
	n = 999,
	response_or_use = true,
	expand_pile = "xing",
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return string.startsWith(pattern, "@@sgkgoddawu")
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not player then return false end
		return player:getPile("xing"):contains(to_select:getId())
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() > 0
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected < #request:getSelectedCardIds()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == #request:getSelectedCardIds()
	end,
	create_card = function(skill, request)
		local dw = sgkgoddawuCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dw:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			dw:setSkillInstanceId(instance_id)
			dw:setActivationSkill("sgkgoddawu", instance_id)
			dw:setSourceSkill("sgkgoddawu", instance_id)
		end
		return dw
	end,
}

sgkgoddawu = sgs.CreateTriggerSkillV2{
	name = "sgkgoddawu",
	events = {},
	view_as_skill = sgkgoddawuVS,
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		return false
	end,
}

--大霧標記留在受標記角色身上；神諸葛亮死亡後標記仍須生效，故以全局隱藏技能承載
sgkgoddawuFog = sgs.CreateTriggerSkillV2{
	name = "#sgkgoddawu_fog",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getMark("&dawu") <= 0 then return false end
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Thunder then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then
			local log = sgs.LogMessage()
			log.from = damage.to
			log.type = "#FogProtect"
			log.arg = tostring(damage.damage)
			if damage.nature == sgs.DamageStruct_Fire then
			    log.arg2 = "fire_nature"
			elseif damage.nature == sgs.DamageStruct_Normal then
			    log.arg2 = "normal_nature"
			end
			room:sendLog(log)
			damage.to:drawCards(1, "sgkgoddawu")
			return true
		end
		return false
	end,
}


sgkgodzhuge:addSkill(sgkgodqixing)
extension:insertRelatedSkills("sgkgodqixing", "#sgkgodqixingStart")
extension:insertRelatedSkills("sgkgodqixing", "#sgkgodqixingAsk")
extension:insertRelatedSkills("sgkgodqixing", "#sgkgodqixingClear")
sgkgodzhuge:addSkill(sgkgodkuangfeng)
sgkgodzhuge:addSkill(sgkgoddawu)


sgs.LoadTranslationTable{
    ["sgkgodzhuge"] = "神诸葛亮",
    ["~sgkgodzhuge"] = "大业未竟，奈何天命将至……",
    ["#sgkgodzhuge"] = "赤壁妖术师",
    ["sgkgodqixing"] = "七星",
    ["#sgkgodqixingStart"] = "七星",
    ["#sgkgodqixingClear"] = "七星",
    ["#sgkgodqixingAsk"] = "七星",
    ["$sgkgodqixing"] = "伏望天慈，佑我蜀汉！",
	["~sgkgodqixing"] = "选择你要作为“星”移出游戏的卡牌→点击“确定”",
    [":sgkgodqixing"] = "分发起始手牌时，你额外获得七张牌，然后你将至少七张手牌置于武将牌上，称为“星”。摸牌阶段结束时，你可以用手牌替换等量的“星”；你的手牌上限+X（X为你的“星”的数量）。",
	["xing"] = "星",
	["sgkgodkuangfeng"] = "狂风",
	[":sgkgodkuangfeng"] = "准备阶段，你可以将一张“星”置入弃牌堆并选择一名其他角色，该角色获得一个“狂风”标记。当有此标记的角色受到伤害时，若此伤害：无属性，你摸X张牌；"..
	"火焰伤害，此伤害+X；雷电伤害，你将牌堆顶的一张牌置入“星”（X为其“狂风”标记数）。",
	["~sgkgodkuangfeng"] = "选择一张“星”→选择一名其他角色→点击“确定”",
	["$sgkgodkuangfeng1"] = "欲破曹公，宜用火攻。",
	["$sgkgodkuangfeng2"] = "万事俱备，只欠东风。",
	["sgkgoddawu"] = "大雾",
	[":sgkgoddawu"] = "结束阶段，你可将任意张“星”置入弃牌堆，并令等量角色各获得一个“大雾”标记直到你的下一个回合开始。当有此标记的角色受到伤害时，若此伤害不是雷电伤害，防止之且该角色摸一张牌。",
	["~sgkgoddawu"] = "选择至少一张“星”→选择等量的角色→点击“确定”",
	["$sgkgoddawu"] = "一幕深雾锁长江，难分渺茫。",
    ["designer:sgkgodzhuge"] = "极略三国",
    ["illustrator:sgkgodzhuge"] = "极略三国",
    ["cv:sgkgodzhuge"] = "极略三国",
}


--神周瑜
sgkgodzhouyu = sgs.General(extension, "sgkgodzhouyu", "sy_god", 4)


--[[
	技能名：琴音
	相关武将：神周瑜
	技能描述：弃牌阶段开始时，你可以改为摸/弃置两张牌，然后令所有角色各失去/回复1点体力。然后若你已发动“业炎”，你可以令所有角色额外执行一次此操作。
	引用：sgkgodqinyin
]]--
sgkgodqinyin = sgs.CreateTriggerSkillV2{
    name = "sgkgodqinyin",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Discard then return false end
		if player:isSkipped(sgs.Player_Discard) then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		player:skip(sgs.Player_Discard)
		if player:getCards("he"):length() < 2 then
		    player:drawCards(2, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1)
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1, player:objectName(), pe:objectName())
			end
			for _, t in sgs.qlist(room:getAlivePlayers()) do
			    room:loseHp(t, 1, true, player, self:objectName())
			end
			if player:getTag("sgkgodyeyan_used"):toBool() == true then
				if player:askForSkillInvoke(self:objectName(), data) then
					for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
						room:doAnimate(1, player:objectName(), pe:objectName())
					end
					for _, t in sgs.qlist(room:getAlivePlayers()) do
						room:loseHp(t, 1, true, player, self:objectName())
					end
				end
			end
		else
		    local choice = room:askForChoice(player, self:objectName(), "qinyin_alllose+qinyin_allrecover")
			if choice == "qinyin_alllose" then
			    player:drawCards(2, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				for _, t in sgs.qlist(room:getAlivePlayers()) do
				    room:doAnimate(1, player:objectName(), t:objectName())
				end
				for _, t in sgs.qlist(room:getAlivePlayers()) do
				    room:loseHp(t, 1, true, player, self:objectName())
				end
				if player:getTag("sgkgodyeyan_used"):toBool() == true then
					if player:askForSkillInvoke(self:objectName(), data) then
						for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
							room:doAnimate(1, player:objectName(), pe:objectName())
						end
						for _, t in sgs.qlist(room:getAlivePlayers()) do
							room:loseHp(t, 1, true, player, self:objectName())
						end
					end
				end
			else
			    room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				room:broadcastSkillInvoke(self:objectName(), 2)
				for _, t in sgs.qlist(room:getAlivePlayers()) do
				    room:doAnimate(1, player:objectName(), t:objectName())
				end
				for _, t in sgs.qlist(room:getAlivePlayers()) do
				    local re = sgs.RecoverStruct()
			        re.who = player
		            room:recover(t, re, true)
				end
				if player:getTag("sgkgodyeyan_used"):toBool() == true then
					if player:askForSkillInvoke(self:objectName(), data) then
						for _, t in sgs.qlist(room:getAlivePlayers()) do
							room:doAnimate(1, player:objectName(), t:objectName())
						end
						for _, t in sgs.qlist(room:getAlivePlayers()) do
							local re = sgs.RecoverStruct()
							re.who = player
							room:recover(t, re, true)
						end
					end
				end
			end
		end
		return false
	end
}


--[[
	技能名：业炎
	相关武将：神周瑜
	技能描述：限定技，你可以弃置至多四张手牌，然后对至多X+1名角色各造成Y+1点火焰伤害；（X/Y为你以此法弃置的黑色/红色牌数）。当你以此法造成不少于5点伤害时，你失去3点体力。
	引用：sgkgodyeyan
]]--
sgkgodyeyanCard = sgs.CreateSkillCard{
    name = "sgkgodyeyanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local x = 0
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isBlack() then x = x + 1 end
		end
		return #targets < x + 1
	end,
	feasible = function(self, targets, player)
	    local x = 0
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isBlack() then x = x + 1 end
		end
		return #targets > 0 and #targets <= x + 1
	end,
	on_use = function(self, room, source, targets)
		local y = 0
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isRed() then y = y + 1 end
		end
		room:doSuperLightbox("sgkgodzhouyu", "sgkgodyeyan")
		source:setTag("sgkgodyeyan_dmg", sgs.QVariant(0))
		source:setFlags("sgkgodyeyan_pending")
		for i = 1, #targets do
		    room:damage(sgs.DamageStruct("sgkgodyeyan", source, targets[i], y + 1, sgs.DamageStruct_Fire))
		end
		source:setFlags("-sgkgodyeyan_pending")
		local total = source:getTag("sgkgodyeyan_dmg"):toInt()
		source:removeTag("sgkgodyeyan_dmg")
		if total >= 5 then room:loseHp(source, 3, true, source, self:objectName()) end
		source:loseMark("@sk_fire")
		source:setTag("sgkgodyeyan_used", sgs.QVariant(true))
	end
}

sgkgodyeyanVS = sgs.CreateViewAsSkillV2{
    name = "sgkgodyeyan",
	n = 4,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@sk_fire") >= 1 and not player:isKongcheng()
	end,
	can_select_card = function(skill, request, to_select)
		if to_select:isEquipped() then return false end
		return #request:getSelectedCardIds() < 4
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() >= 1
	end,
	can_select_target = function(skill, request, selected, candidate)
		local x = 0
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			if sgs.Sanguosha:getCard(id):isBlack() then x = x + 1 end
		end
		return #selected < x + 1
	end,
	targets_feasible = function(skill, request, selected)
		local x = 0
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			if sgs.Sanguosha:getCard(id):isBlack() then x = x + 1 end
		end
		return #selected > 0 and #selected <= x + 1
	end,
	create_card = function(skill, request)
		local yeyan = sgkgodyeyanCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			yeyan:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			yeyan:setSkillInstanceId(instance_id)
			yeyan:setActivationSkill("sgkgodyeyan", instance_id)
			yeyan:setSourceSkill("sgkgodyeyan", instance_id)
		end
		return yeyan
	end,
}

sgkgodyeyan = sgs.CreateTriggerSkillV2{
    name = "sgkgodyeyan",
	view_as_skill = sgkgodyeyanVS,
	frequency = sgs.Skill_Limited,
	limit_mark = "@sk_fire",
	events = {sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasFlag("sgkgodyeyan_pending")) then return false end
		if data:toDamage().reason ~= "sgkgodyeyan" then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local total = player:getTag("sgkgodyeyan_dmg"):toInt() + damage.damage
		player:setTag("sgkgodyeyan_dmg", sgs.QVariant(total))
		return false
	end,
}


sgkgodzhouyu:addSkill(sgkgodqinyin)
sgkgodzhouyu:addSkill(sgkgodyeyan)


sgs.LoadTranslationTable{
    ["sgkgodzhouyu"] = "神周瑜",
	["&sgkgodzhouyu"] = "神周瑜",
	["#sgkgodzhouyu"] = "赤壁的火神",
	["~sgkgodzhouyu"] = "残焰黯然，弦歌不复……",
	["@sk_fire"] = "业炎",
	["sgkgodqinyin"] = "琴音",
	[":sgkgodqinyin"] = "弃牌阶段开始时，你可以改为摸/弃置两张牌，然后令所有角色各失去/回复1点体力；然后若你已发动“业炎”，你可以令所有角色额外执行一次此操作。",
	["$sgkgodqinyin1"] = "琴音齐疾，碎心裂胆。",
	["$sgkgodqinyin2"] = "琴音齐徐，如沐甘霖。",
	["qinyin_alllose"] = "令所有角色各失去1点体力",
	["qinyin_allrecover"] = "令所有角色各回复1点体力",
	["sgkgodyeyan"] = "业炎",
	["sgkgodyeyanCard"] = "业炎",
	[":sgkgodyeyan"] = "限定技，你可以弃置至多四张手牌，然后对至多X+1名角色各造成Y+1点火焰伤害（X/Y为你以此法弃置的黑色/红色牌数）。当你以此法造成不少于5点伤害时，你失去3点体力。",
	["$sgkgodyeyan1"] = "红莲业火，焚尽人间！",
	["$sgkgodyeyan2"] = "浮生罪业，皆归灰烬！",
	["$sgkgodyeyan3"] = "血色火海，葬敌万千！",
	["designer:sgkgodzhouyu"] = "极略三国",
    ["illustrator:sgkgodzhouyu"] = "极略三国",
    ["cv:sgkgodzhouyu"] = "极略三国",
}


--神刘备
sgkgodliubei = sgs.General(extension, "sgkgodliubei", "sy_god", "4")


--[[
	技能名：君望
	相关武将：神刘备
	技能描述：锁定技，其他角色的出牌阶段开始或结束时，若其手牌数不小于你，你令其交给你一张手牌。
	引用：sgkgodjunwang
]]--
sgkgodjunwang = sgs.CreateTriggerSkillV2{
    name = "sgkgodjunwang",
	frequency = sgs.Skill_Compulsory,
	priority = -2,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Play or player:getHandcardNum() <= 0 then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if player:objectName() ~= s:objectName() and player:getHandcardNum() >= s:getHandcardNum() then
				table.insert(names, skill:objectName())
				table.insert(owners, s:objectName())
			end
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local liubei = player
		local target = ctx.invoker
		local data = ctx.original_data
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		room:sendCompulsoryTriggerLog(liubei, self:objectName())
		room:notifySkillInvoked(liubei, self:objectName())
		room:doAnimate(1, liubei:objectName(), target:objectName())
		local c = room:askForCard(target, ".!", "@junwang:" .. liubei:objectName(), data, sgs.Card_MethodNone)
		room:obtainCard(liubei, c, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), liubei:objectName(), "sgkgodjunwang", ""), false)
		return false
	end
}


--[[
	技能名：激诏
	相关武将：神刘备
	技能描述：出牌阶段开始时，你可以将任意张手牌分配给任意名其他角色，然后这些角色各获得一个“激诏”标记。有此标记的角色造成伤害时，你可以移去其一个“激诏”标记，
	令此伤害+1。回合开始时，你可以移去场上所有“激诏”标记，然后这些角色失去等量体力。
	引用：sgkgodjizhao
]]--
sgkgodjizhaoCard = sgs.CreateSkillCard{
    name = "sgkgodjizhaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName()
	end,
	about_to_use = function(self, room, use)
		local source = use.from
		local msg = sgs.LogMessage()
		msg.type = "#ChoosePlayerWithSkill"
		msg.from = source
		msg.arg = "sgkgodjizhao"
		for _, p in sgs.qlist(use.to) do
			msg.to:append(p)
		end
		room:sendLog(msg)
		room:broadcastSkillInvoke("sgkgodjizhao", 1)
		room:notifySkillInvoked(source, "sgkgodjizhao")
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			targets:append(p)
		end
		for _, id in sgs.qlist(self:getSubcards()) do
			if targets:isEmpty() then break end
			local target = targets:first()
			if targets:length() > 1 then
				target = room:askForPlayerChosen(source, targets, "sgkgodjizhao", "@jizhao-give", false, true)
			end
			if target then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "sgkgodjizhao", "")
				room:obtainCard(target, sgs.Sanguosha:getCard(id), reason, false)
			end
		end
		for _, p in sgs.qlist(use.to) do
			p:gainMark("&zhao", 1)
		end
	end
}

sgkgodjizhaoVS = sgs.CreateViewAsSkillV2{
    name = "sgkgodjizhao",
	n = 9999,
	response_or_use = true,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return string.startsWith(pattern, "@@sgkgodjizhao")
    end,
	can_select_card = function(skill, request, to_select)
        return not to_select:isEquipped()
    end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() >= 1
	end,
	can_select_target = function(skill, request, selected, candidate)
		return request:getInitiator() and candidate:objectName() ~= request:getInitiator():objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected >= 1
	end,
	create_card = function(skill, request)
	    local jizhao_card = sgkgodjizhaoCard:clone()
	    for _, id in sgs.qlist(request:getSelectedCardIds()) do
		    jizhao_card:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			jizhao_card:setSkillInstanceId(instance_id)
			jizhao_card:setActivationSkill("sgkgodjizhao", instance_id)
			jizhao_card:setSourceSkill("sgkgodjizhao", instance_id)
		end
	    return jizhao_card
	end
}

sgkgodjizhao = sgs.CreateTriggerSkillV2{
    name = "sgkgodjizhao",
	events = {sgs.EventPhaseStart, sgs.DamageCaused},
	view_as_skill = sgkgodjizhaoVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if not player:hasSkill(skill:objectName()) then return false end
			if player:getPhase() == sgs.Player_Play then
				if not player:isKongcheng() then return skill:objectName() end
			elseif player:getPhase() == sgs.Player_RoundStart then
				for _, s in sgs.qlist(room:getAllPlayers()) do
					if s:getMark("&zhao") > 0 then return skill:objectName() end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("&zhao") > 0 then
				local names, owners = {}, {}
				for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(names, skill:objectName())
					table.insert(owners, s:objectName())
				end
				if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				room:askForUseCard(player, "@@sgkgodjizhao", "@jizhao-givecard", -1, sgs.Card_MethodNone)
			elseif player:getPhase() == sgs.Player_RoundStart then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:notifySkillInvoked(player, self:objectName())
					for _, s in sgs.qlist(room:getAllPlayers()) do
						local n = s:getMark("&zhao")
						if n > 0 then
							s:loseAllMarks("&zhao")
							room:loseHp(s, n, true, player, self:objectName())
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:askForSkillInvoke("sgkgodjizhao_damage", data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:notifySkillInvoked(player, self:objectName())
				ctx.invoker:loseMark("&zhao", 1)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
}


sgkgodliubei:addSkill(sgkgodjunwang)
sgkgodliubei:addSkill(sgkgodjizhao)


sgs.LoadTranslationTable{
	["sgkgodliubei"] = "神刘备",
	["&sgkgodliubei"] = "神刘备",
	["~sgkgodliubei"] = "朕今日……注定命丧此地……",
	["#sgkgodliubei"] = "烈龙之怒",
	["sgkgodjunwang" ]= "君望",
	["$sgkgodjunwang1"] = "此诚危急存亡之时，当需一搏！",
	["$sgkgodjunwang2"] = "吾以汉室之名，借英雄一臂之力！",
	[":sgkgodjunwang"] = "锁定技，其他角色的出牌阶段开始或结束时，若其手牌数不小于你，你令其交给你一张手牌。",
	["@junwang"] = "【君望】效果触发，请交给%src一张手牌。",
	["sgkgodjizhao"] = "激诏",
	["#sgkgodjizhao"] = "激诏",
	["$sgkgodjizhao1"] = "破联盟，屠吴狗！",
	["$sgkgodjizhao2"] = "不取东吴，誓不为人！",
	[":sgkgodjizhao"] = "出牌阶段开始时，你可以将任意张手牌分配给任意名其他角色，然后这些角色各获得一个“激诏”标记。有此标记的角色造成伤害时，"..
	"你可以移去其一个“激诏”标记，令此伤害+1。回合开始时，你可以移去场上所有“激诏”标记，然后这些角色失去等量体力。",
	["@jizhao-givecard"] = "激诏：你可以将任意张手牌分配给任意名其他角色",
	["@jizhao-give"] = "激诏：请选择获得此牌的角色",
	["zhao"] = "激诏",
	["sgkgodjizhao_damage"] = "激诏",
	["#jizhao"] = "%to 本回合内未造成过伤害，将触发 %from 的“%arg”效果。",
	["designer:sgkgodliubei"] = "极略三国",
	["illustrator:sgkgodliubei"] = "极略三国",
	["cv:sgkgodliubei"] = "极略三国",
}


--神贾诩
sgkgodjiaxu=sgs.General(extension,"sgkgodjiaxu","sy_god", 3)


--[[
	技能名：湮灭
	相关武将：神贾诩
	技能描述：出牌阶段，你可以弃置一张黑桃牌并选择一名有牌的其他角色，你令其先弃置所有牌并摸等量的牌再展示，然后你可以弃置其中全部非基本牌，对其造成X点伤
	害（X为以此法弃置的牌数）。
	引用：sgkgodyanmie
]]--
sgkgodyanmieCard = sgs.CreateSkillCard{
    name = "sgkgodyanmieCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    return (not to_select:hasSkill(self:objectName())) and (not to_select:isNude())
	end,
	feasible = function(self, targets, player)
	    return #targets == 1 and targets[1]:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		local n = target:getCards("he"):length()
		room:setPlayerMark(target, "toyanmie", n)
		local N = target:getMark("toyanmie")
		target:throwAllHandCardsAndEquips("sgkgodyanmie")
		target:drawCards(N)
		room:showAllCards(target)
		room:setPlayerMark(target, "toyanmie", 0)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local a = 0
	    for _, c in sgs.qlist(target:getHandcards()) do
	        if not c:isKindOf("BasicCard") then
		        a = a + 1
			    dummy:addSubcard(c)
		    end
	    end
		local choices = {"dis-yanmie", "zhaquan"}
		if a <= 0 then
			 return false
		else
	        local choice = room:askForChoice(source, "sgkgodyanmie", table.concat(choices, "+"))
	        if choice == "dis-yanmie" then
		        room:doAnimate(1, source:objectName(), target:objectName())
				room:throwCard(dummy, target, source)
		        room:damage(sgs.DamageStruct("sgkgodyanmie", source, target, a))
		    else
		        return false
	        end
	    end
	end
}

sgkgodyanmie = sgs.CreateViewAsSkillV2{
    name = "sgkgodyanmie",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		if not request:getInitiator() then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, to_select)
	    return to_select:getSuit() == sgs.Card_Spade
	end,
	can_select_target = function(skill, request, selected, candidate)
		if #selected ~= 0 then return false end
		return (not candidate:hasSkill(skill:objectName())) and (not candidate:isNude())
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1 and selected[1]:objectName() ~= request:getInitiator():objectName()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
	    local yanmiecard = sgkgodyanmieCard:clone()
		yanmiecard:addSubcard(ids:first())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			yanmiecard:setSkillInstanceId(instance_id)
			yanmiecard:setActivationSkill("sgkgodyanmie", instance_id)
			yanmiecard:setSourceSkill("sgkgodyanmie", instance_id)
		end
		return yanmiecard
	end
}


--[[
	技能名：顺世
	相关武将：神贾诩
	技能描述：当你成为其他角色使用的基本牌或普通锦囊牌的唯一目标时，你可以令至多3名不为此牌目标的角色也成为此牌的目标，然后你摸X张牌（X为以此法增加的目标数）。
	引用：sgkgodshunshi
]]--
sgkgodshunshi = sgs.CreateTriggerSkillV2{
    name = "sgkgodshunshi",
	view_as_skill = sgkgodshunshiVS,
	events = {sgs.TargetConfirming},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from and use.from:objectName() ~= player:objectName() and use.to:length() == 1 and use.to:contains(player)
			and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if use.from and use.from:objectName() ~= player:objectName() and use.to:length() == 1 and use.to:contains(player) then
			if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
				local shunshi = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not use.to:contains(pe) and not sgs.Sanguosha:isProhibited(use.from, pe, use.card) then shunshi:append(pe) end
				end
				if shunshi:isEmpty() then return false end
				local q = sgs.QVariant()
				q:setValue(use)
				player:setTag("shunshi_data", q)
				local others = room:askForPlayersChosen(player, shunshi, self:objectName(), 0, 3, "@shunshi_select:"..use.card:objectName(), true, true)
				if others:length() > 0 then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(others:length(), self:objectName())
					for _, p in sgs.qlist(others) do
						use.to:append(p)
						room:sortByActionOrder(use.to)
					end
					room:setCardFlag(use.card, "sgkgodshunshi")
					data:setValue(use)
				end
			end
		end
	end
}


sgkgodjiaxu:addSkill(sgkgodyanmie)
sgkgodjiaxu:addSkill(sgkgodshunshi)


sgs.LoadTranslationTable{
	["sgkgodjiaxu"] = "神贾诩",
	["~sgkgodjiaxu"] = "我死了，诸位就能幸免吗？哈哈哈哈哈哈……",
	["#sgkgodjiaxu"] = "冷眼下瞰",
	["sgkgodyanmie"] = "湮灭",
	["luasgkgodyanmie"] = "湮灭",
	[":sgkgodyanmie"] = "出牌阶段，你可以弃置一张黑桃牌并选择一名有牌的其他角色，你令其先弃置所有牌，再摸等量的牌并展示之，然后你可以弃置这些牌中的所有非基本牌，"..
	"对其造成等量伤害。",
	["dis-yanmie"] = "弃置全部非基本牌并造成等量伤害",
	["zhaquan"] = "取消",
	["sgkgodshunshi"] = "顺世",
	[":sgkgodshunshi"] = "当你成为其他角色使用的基本牌或普通锦囊牌的唯一目标时，你可以令至多3名不为此牌目标的角色也成为此牌的目标，然后你摸X张牌（X为以此法增加的目标数）。",
	["@shunshi_select"] = "你可以发动“顺世”，选择至多3名角色也成为此【%src】的目标。",
	["$sgkgodyanmie1"] = "能救你的人已经不在了！",
	["$sgkgodyanmie2"] = "留你一命，用余生后悔去吧！",
	["$sgkgodshunshi1"] = "死人，是不会说话的。",
	["$sgkgodshunshi2"] = "此天意，非人力所能左右。",
	["designer:sgkgodjiaxu"] = "极略三国",
	["illustrator:sgkgodjiaxu"] = "极略三国",
	["cv:sgkgodjiaxu"] = "极略三国",
}


--神孙权
sgkgodsunquan = sgs.General(extension, "sgkgodsunquan", "sy_god", "5")


--[[
	技能名：虎踞
	相关武将：神孙权
	技能描述：锁定技，任一角色的准备阶段，你摸4张牌，若此时是你的回合，你减1点体力上限，失去“虎踞”，获得“制衡”、“雄略”和“虎缚”。
	引用：sgkgodhuju
]]--
sgkgodhuju = sgs.CreateTriggerSkillV2{
    name = "sgkgodhuju",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Start then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local sunquan = player
		local invoker = ctx.invoker
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
		room:sendCompulsoryTriggerLog(sunquan, self:objectName())
		room:notifySkillInvoked(sunquan, self:objectName())
		sunquan:drawCards(4, self:objectName())
		if invoker:getSeat() == sunquan:getSeat() then
			room:doSuperLightbox("sgkgodsunquan", self:objectName())
			room:loseMaxHp(sunquan)
			local sunquan_skills = {}
			if not sunquan:hasSkill("zhiheng") and (not sunquan:hasSkill("tenyearzhiheng")) then table.insert(sunquan_skills, "zhiheng") end
			if not sunquan:hasSkill("sgkgodhufu") then table.insert(sunquan_skills, "sgkgodhufu") end
			if not sunquan:hasSkill("sr_xionglve") then table.insert(sunquan_skills, "sr_xionglve") end
			table.insert(sunquan_skills, "-sgkgodhuju")
			room:handleAcquireDetachSkills(sunquan, table.concat(sunquan_skills, "|"))
		end
		return false
	end
}


--[[
	技能名：虎缚
	相关武将：神孙权
	技能描述：出牌阶段限一次，你可以令一名其他角色弃置X张牌（X为其装备区的牌数）。
	引用：sgkgodhufu
]]--
sgkgodhufuCard = sgs.CreateSkillCard{
    name = "sgkgodhufuCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
        return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and (to_select:getEquips():length() > 0)
    end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		local room = source:getRoom()
		local X = target:getEquips():length()
		room:askForDiscard(target, "sgkgodhufu", X, X, false, true)
	end
}

sgkgodhufu = sgs.CreateViewAsSkillV2{
    name = "sgkgodhufu",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodhufu")
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected == 0 and candidate:objectName() ~= request:getInitiator():objectName()
			and candidate:getEquips():length() > 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodhufuCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodhufu", instance_id)
		card:setSourceSkill("sgkgodhufu", instance_id)
		return card
	end
}
	
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sgkgodhufu") then skills:append(sgkgodhufu) end
sgs.Sanguosha:addSkills(skills)
sgkgodsunquan:addSkill(sgkgodhuju)
sgkgodsunquan:addRelateSkill("sgkgodhufu")
sgkgodsunquan:addRelateSkill("zhiheng")
sgkgodsunquan:addRelateSkill("sr_xionglve")


sgs.LoadTranslationTable{
	["sgkgodsunquan"] = "神孙权",
	["&sgkgodsunquan"] = "神孙权",
	["#sgkgodsunquan"] = "峰林之上",
	["~sgkgodsunquan"] = "效季良不得，陷为天下……轻薄子……",
	["sgkgodhuju"] = "虎踞",
	["$sgkgodhuju1"] = "踞虎盘龙，步步为营！",
	["$sgkgodhuju2"] = "虎踞江东，利在鼎足！",
	["$sgkgodhuju3"] = "虎跃天堑，剑指中原！",
	["Tolose"] = "失去1点体力",
	["Hujuwake"] = "减1点体力上限",
	[":sgkgodhuju"] = "锁定技，任一角色的准备阶段，你摸4张牌，若此时是你的回合，你减1点体力上限，失去“虎踞”，获得“制衡”、“雄略”和“虎缚”。",
	["$zhiheng4"] = "大人虎变，其文炳也。",
	["$zhiheng5"] = "虎视眈眈，其欲逐逐。",
	["sgkgodhufu"] = "虎缚",
	["$sgkgodhufu1"] = "虎兕出柙，恩怨必报！",
	["$sgkgodhufu2"] = "委肉虎蹊，祸必不振！",
	[":sgkgodhufu"] = "出牌阶段限一次，你可以令一名其他角色弃置X张牌（X为其装备区的牌数）。",
	["designer:sgkgodsunquan"] = "极略三国",
	["illustrator:sgkgodsunquan"] = "极略三国",
	["cv:sgkgodsunquan"] = "极略三国",
}


--神貂蝉
sgkgoddiaochan = sgs.General(extension, "sgkgoddiaochan", "sy_god", 3, false)


--[[
	技能名：天姿
	相关武将：神貂蝉
	技能描述：锁定技，你的摸牌阶段摸牌数和手牌上限+X（X为存活的其他角色数）
	引用：sgkgodtianzi
]]--
sgkgodtianzi = sgs.CreateTriggerSkillV2{
    name = "sgkgodtianzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local draw = data:toDraw()
		room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
		draw.num = draw.num + player:getAliveSiblings():length()
		data:setValue(draw)
		return false
	end
}


--[[
	技能名：魅心
	相关武将：神貂蝉
	技能描述：出牌阶段，你可以弃置X张牌并选择一名没有“魅心”标记的其他男性角色（X为拥有“魅心”标记的角色数+1），令其获得1个“魅心”标记直至其下回合开始。对于
	拥有“魅心”标记的角色，当你或任意女性角色使用：基本牌后，你令其随机弃置一张牌；锦囊牌后，你随机获得其一张牌；装备牌后，你对其造成1点伤害。
	引用：sgkgodmeixin
]]--
sgkgodmeixinCard = sgs.CreateSkillCard{
    name = "sgkgodmeixinCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and to_select:isMale() and to_select:isAlive() and to_select:getMark("&sgkgodmeixin") == 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		targets[1]:gainMark("&sgkgodmeixin")
	end
}

sgkgodmeixinVS = sgs.CreateViewAsSkillV2{
    name = "sgkgodmeixin",
	n = 999,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local male = 0
		for _, pe in sgs.list(player:getAliveSiblings()) do
			if pe:isMale() then male = male + 1 end
		end
		return not player:isNude() and male > 0
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		local num = 1
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:getMark("&sgkgodmeixin") > 0 then num = num + 1 end
		end
		return #request:getSelectedCardIds() < num and not player:isJilei(to_select)
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		local num = 1
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:getMark("&sgkgodmeixin") > 0 then num = num + 1 end
		end
		return #request:getSelectedCardIds() == num
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		if #selected ~= 0 then return false end
		return candidate:objectName() ~= player:objectName() and candidate:isMale()
			and candidate:isAlive() and candidate:getMark("&sgkgodmeixin") == 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local c = sgkgodmeixinCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			c:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			c:setSkillInstanceId(instance_id)
			c:setActivationSkill("sgkgodmeixin", instance_id)
			c:setSourceSkill("sgkgodmeixin", instance_id)
		end
		return c
	end,
}

sgkgodmeixin = sgs.CreateTriggerSkillV2{
    name = "sgkgodmeixin",
	view_as_skill = sgkgodmeixinVS,
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.from then return false end
			local mx_targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				if pe:getMark("&"..skill:objectName()) > 0 and pe:isAlive() then mx_targets:append(pe) end
			end
			if mx_targets:isEmpty() then return false end
		end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local diaochan = player
			if use.from and (use.from:isFemale() or use.from:objectName() == diaochan:objectName()) then
				local mx_targets = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if pe:getMark("&"..self:objectName()) > 0 and pe:isAlive() then mx_targets:append(pe) end
				end
				if mx_targets:isEmpty() then return false end
				if use.card:isKindOf("BasicCard") then
					room:sendCompulsoryTriggerLog(diaochan, self:objectName(), true, true)
					for _, m in sgs.qlist(mx_targets) do
						room:doAnimate(1, diaochan:objectName(), m:objectName())
					end
					for _, m in sgs.qlist(mx_targets) do
						local cards = sgs.QList2Table(m:getCards("he"))
						if #cards > 0 then
							local rcard = cards[math.random(1, #cards)]
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, diaochan:objectName(), nil, self:objectName(), nil)
							room:throwCard(rcard, reason, m, diaochan)
						end
					end
				elseif use.card:isKindOf("TrickCard") then
					room:sendCompulsoryTriggerLog(diaochan, self:objectName(), true, true)
					for _, m in sgs.qlist(mx_targets) do
						room:doAnimate(1, diaochan:objectName(), m:objectName())
					end
					for _, m in sgs.qlist(mx_targets) do
						local cards = {}
						for _, c in sgs.qlist(m:getCards("he")) do
							if diaochan:canGet(m, c:getEffectiveId()) then table.insert(cards, c) end
						end
						if #cards > 0 then
							local rcard = cards[math.random(1, #cards)]
							room:obtainCard(diaochan, rcard, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, diaochan:objectName(), m:objectName(), "sgkgodmeixin", ""), true)
						end
					end
				elseif use.card:isKindOf("EquipCard") then
					room:sendCompulsoryTriggerLog(diaochan, self:objectName(), true, true)
					for _, m in sgs.qlist(mx_targets) do
						room:doAnimate(1, diaochan:objectName(), m:objectName())
					end
					for _, m in sgs.qlist(mx_targets) do
						room:damage(sgs.DamageStruct(self:objectName(), diaochan, m))
					end
				end
			end
		end
		return false
	end
}

--魅心標記留在被標記角色身上；最後的持有者死亡或受標記者回合開始時仍須結算，故以全局隱藏技能承載
sgkgodmeixinClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodmeixinClear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("&sgkgodmeixin") > 0 then
				return skill:objectName()
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "sgkgodmeixin" then return skill:objectName() end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.who:objectName() == player:objectName() and death.who:hasSkill("sgkgodmeixin") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			player:loseAllMarks("&sgkgodmeixin")
		elseif event == sgs.EventLoseSkill or event == sgs.Death then
			if room:findPlayersBySkillName("sgkgodmeixin"):isEmpty() then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:loseAllMarks("&sgkgodmeixin")
				end
			end
		end
		return false
	end
}


sgkgoddiaochan:addSkill(sgkgodtianzi)
sgkgoddiaochan:addSkill(sgkgodmeixin)


sgs.LoadTranslationTable{
	["sgkgoddiaochan"] = "神貂蝉",
	["&sgkgoddiaochan"] = "神貂蝉",
	["#sgkgoddiaochan"] = "乱世的舞魅",
	["~sgkgoddiaochan"] = "自古美人如名将，不许人间见白头……",
	["sgkgodtianzi"] = "天姿",
	[":sgkgodtianzi"] = "锁定技，你的摸牌阶段摸牌数和手牌上限+X（X为存活的其他角色数）。",
	["$sgkgodtianzi"] = "香囊暗解，罗带轻分，薄幸谁常往？",
	["sgkgodmeixin"] = "魅心",
	[":sgkgodmeixin"] = "出牌阶段，你可以弃置X张牌并选择一名没有“魅心”标记的其他男性角色（X为拥有“魅心”标记的角色数+1），令其获得1个“魅心”标记直至其下回合开始。对于"..
	"拥有“魅心”标记的角色，当你或任意女性角色使用：基本牌后，你令其随机弃置一张牌；锦囊牌后，你随机获得其一张牌；装备牌后，你对其造成1点伤害。",
	["$sgkgodmeixin1"] = "妾心妾意，惟愿常相伴。",
	["$sgkgodmeixin2"] = "夫为乐，为乐当及时。",
	["$sgkgodmeixin3"] = "滔滔日夜东注，多少醉生梦死。",
	["$sgkgodmeixin4"] = "银壶金樽复美酒，与君同销万古愁。",
	["designer:sgkgoddiaochan"]= "极略三国",
	["illustrator:sgkgoddiaochan"] = "极略三国",
	["cv:sgkgoddiaochan"] = "极略三国",
}


--神张飞
sgkgodzhangfei = sgs.General(extension, "sgkgodzhangfei", "sy_god", 4)


--[[
	技能名：杀意
	相关武将：神张飞
	技能描述：锁定技，出牌阶段开始时，你摸一张牌并标记所有黑色手牌，你于本阶段可将这些牌当【杀】使用，结算完毕后摸一张牌。你使用【杀】无距离和次数限制。
	引用：sgkgodshayi
]]--
sgkgodshayi = sgs.CreateViewAsSkillV2{
    name = "sgkgodshayi",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
	    return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isNude()
	end,
	can_select_card = function(skill, request, to_select)
	   return to_select:hasTip("sgkgodshayi")
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
	    local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card)
		slash:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			slash:setSkillInstanceId(instance_id)
			slash:setActivationSkill("sgkgodshayi", instance_id)
			slash:setSourceSkill("sgkgodshayi", instance_id)
		end
		return slash
	end,
}


sgkgodshayiDo = sgs.CreateTriggerSkillV2{
    name = "#sgkgodshayiDo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then return false end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from ~= sgs.Player_Play then return false end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local zhangfei = room:getCurrent()
			if not zhangfei or zhangfei:objectName() ~= player:objectName() then return false end
			if not zhangfei:hasSkill("sgkgodshayi") then return false end
			if not (use.card and use.card:isKindOf("Slash") and use.card:getSkillName() ~= "sgkgodshayi"
				and use.from and use.from:objectName() == zhangfei:objectName()) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
		    room:sendCompulsoryTriggerLog(player, "sgkgodshayi")
			room:broadcastSkillInvoke("sgkgodshayi", 1)
			player:drawCards(1, "sgkgodshayi")
			for _, card in sgs.qlist(player:getHandcards()) do
			    if card:isBlack() then
					card:setTag("sgkgodshayi", sgs.QVariant(true))
					room:setCardTip(card:getEffectiveId(), "sgkgodshayi") 
				end
			end
		elseif event == sgs.EventPhaseChanging then
			for _, card in sgs.qlist(player:getHandcards()) do
			    if card:hasTip("sgkgodshayi") or card:getTag("sgkgodshayi"):toBool() then
					card:removeTag("sgkgodshayi")
					room:setCardTip(card:getEffectiveId(), "-sgkgodshayi")
				end
			end
		elseif event == sgs.CardUsed then
			room:broadcastSkillInvoke("sgkgodshayi", math.random(2, 4))
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and ((table.contains(use.card:getSkillNames(), "sgkgodshayi")) or (use.card:getTag("sgkgodshayi"):toBool() and use.card:isKindOf("Slash") and use.card:isBlack())) then
				player:drawCards(1, "sgkgodshayi")
				use.card:removeTag("sgkgodshayi")
			end
		end
		return false
	end
}


function forbidAllSkills(vic)
	local room = vic:getRoom()
	for _, sk in sgs.qlist(vic:getVisibleSkillList()) do
		room:addPlayerMark(vic, "Qingcheng"..sk:objectName())
	end
end

function activateAllSkills(vic)
	local room = vic:getRoom()
	for _, sk in sgs.qlist(vic:getVisibleSkillList()) do
		room:setPlayerMark(vic, "Qingcheng"..sk:objectName(), 0)
	end
end


--[[
	技能名：震魂
	相关武将：神张飞
	技能描述：出牌阶段限一次，你可以令所有其他角色的非锁定技于此阶段内无效，且不处于濒死状态的这些角色不能使用【桃】。
	引用：sgkgodzhenhun
]]--
sgkgodzhenhunCard = sgs.CreateSkillCard{
    name = "sgkgodzhenhunCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    for _, p in sgs.qlist(room:getOtherPlayers(source)) do
		    room:doAnimate(1, source:objectName(), p:objectName())
		end
		room:addPlayerMark(source, "zhenhun_src")
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:addPlayerMark(p, "zhenhun_buff")
		    room:addPlayerMark(p, "@skill_invalidity")
			room:filterCards(p, p:getCards("he"), true)
			local jsonValue={9}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
	end
}

sgkgodzhenhunVS = sgs.CreateViewAsSkillV2{
    name = "sgkgodzhenhun",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodzhenhun")
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodzhenhunCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodzhenhun", instance_id)
		card:setSourceSkill("sgkgodzhenhun", instance_id)
		return card
	end
}

sgkgodzhenhun = sgs.CreateTriggerSkillV2{
    name = "sgkgodzhenhun",
	view_as_skill = sgkgodzhenhunVS,
	events = {sgs.EnterDying},
	can_trigger = function(skill, event, room, player, data)
		local current = room:getCurrent()
		if not (current and current:isAlive() and current:hasFlag("CurrentPlayer") and current:hasSkill(skill:objectName())) then return false end
		if current:getMark("zhenhun_src") == 0 then return false end
		return skill:objectName(), current:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EnterDying then
			local dying = data:toDying()
			local current = player
			if current and current:hasFlag("CurrentPlayer") and current:hasSkill(self) then
				for _,p in sgs.qlist(room:getOtherPlayers(dying.who)) do
					if p ~= current then
						p:addMark("zhenhun_nopeach")
						local jsonValue={9}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					end
				end
				local log = sgs.LogMessage()
				log.from = current
				log.arg = self:objectName()
				log.type = "#WanshaTwo"
				log.to:append(dying.who)
				if current == dying.who then
					log.type = "#WanshaOne"
				end
				room:sendLog(log)
				room:notifySkillInvoked(current, self:objectName())
			end
		end
		return false
	end,
}

--鎮魂的全場標記清理與張飛是否存活無關，故以全局隱藏技能承載
sgkgodzhenhunClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodzhenhun_clear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.QuitDying},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from ~= sgs.Player_Play then return false end
			return skill:objectName()
		elseif event == sgs.QuitDying then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			for _, p in sgs.qlist(room:getPlayers()) do
				room:setPlayerMark(p, "zhenhun_buff", 0)
				room:setPlayerMark(p, "zhenhun_src", 0)
				room:setPlayerMark(p, "@skill_invalidity", 0)
				room:filterCards(p, p:getCards("he"), true)
			end
		elseif event == sgs.QuitDying then
			local dying = data:toDying()
			for _,p in sgs.qlist(room:getOtherPlayers(dying.who)) do
				local n = p:getMark("zhenhun_nopeach")
				if n >= 1 then p:setMark("zhenhun_nopeach", 0) end
			end
		end
		return false
	end,
}

--DEFER:sgkgodzhenhunBuff:CreateCardLimitSkill 無 V2 API
sgkgodzhenhunBuff = sgs.CreateCardLimitSkill{
	name = "#sgkgodzhenhunBuff",
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player)
		if player:hasFlag("Global_Dying") then return "" end
		if player:getMark("zhenhun_buff") > 0 then return "Peach" end
		return ""
	end
}


sgkgodzhangfei:addSkill(sgkgodshayi)
extension:insertRelatedSkills("sgkgodshayi", "#sgkgodshayiDo")
sgkgodzhangfei:addSkill(sgkgodzhenhun)
sgkgodzhangfei:addSkill(sgkgodzhenhunBuff)
extension:insertRelatedSkills("sgkgodzhenhun", "#sgkgodzhenhunBuff")


sgs.LoadTranslationTable{
["sgkgodzhangfei"] = "神张飞",
["&sgkgodzhangfei"] = "神张飞",
["~sgkgodzhangfei"] = "汝等杂碎！还吾头来……",
["#sgkgodzhangfei"] = "横扫千军",
["sgkgodshayi"] = "杀意",
["sgkgodshayiDo"] = "杀意",
["#sgkgodshayiDo"] = "杀意",
["$sgkgodshayi1"] = "长矛所向，万夫不当！",
["$sgkgodshayi2"] = "呆若木鸡，是等死吗？",
["$sgkgodshayi3"] = "喝啊啊啊啊——",
["$sgkgodshayi4"] = "看爷爷我大杀四方！",
[":sgkgodshayi"] = "锁定技，出牌阶段开始时，你摸一张牌并标记所有黑色手牌，你于本阶段可将这些牌当【杀】使用，结算完毕后摸一张牌。你使用【杀】无距离和次数限制。",
["sgkgodzhenhun"] = "震魂",
["$sgkgodzhenhun"] = "都跪下，叫老子一声爹！",
[":sgkgodzhenhun"] = "出牌阶段限一次，你可以令所有其他角色的非锁定技于此阶段内无效，且不处于濒死状态的这些角色不能使用【桃】。",
["designer:sgkgodzhangfei"] = "极略三国",
["illustrator:sgkgodzhangfei"] = "极略三国",
["cv:sgkgodzhangfei"] = "极略三国",
}


--神司马徽
sgkgodsimahui = sgs.General(extension, "sgkgodsimahui", "sy_god", 3)


--[[
	技能名：隐世
	相关武将：神司马徽
	技能描述：锁定技，当你受到伤害时，你摸X张牌（X为伤害值），然后若此伤害不为雷电伤害，你防止之。
	备注：初代的神司马徽免疫一切伤害，只有体力流失、扣体力上限、吃菜、神关羽/十周年神张飞的强制死亡才能打动他。
	引用：sgkgodyinshi
]]--
sgkgodyinshi = sgs.CreateTriggerSkillV2{
    name = "sgkgodyinshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.to:objectName() == player:objectName() then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
	    room:sendCompulsoryTriggerLog(player, self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		player:drawCards(damage.damage)
		if damage.nature ~= sgs.DamageStruct_Thunder then return true end
		return false
	end
}


--[[
	技能名：知天
	相关武将：神司马徽
	技能描述：锁定技，回合开始时，你随机观看三张未加入游戏的武将牌并选择其中一张上的一个技能，然后你将所有手牌交给一名角色（若为你则跳过），令其获得此技能并
	失去1点体力。
	备注：初代的神司马徽抽到什么技能全随机，没得选，纯粹开盲盒，而且给别人牌和技能也是自己流失体力。现在你可以空城状态下给别人一个恃勇然后让他流失1点体力。
	备注：我玩初代的神司马徽曾经出现过我送给别人一个通天，下回合给我自己来了个极略版的武神（锁定技，你的桃和杀均视为决斗）。
	引用：sgkgodzhitian
]]--
local json = require ("json")
function isNormalGameMode (mode_name)
	return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end
function acquireGenerals(zuoci, n)
	local room = zuoci:getRoom()
	local Huashens = {}
	for i=1, n, 1 do
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local banned = {"zuoci", "guzhielai", "dengshizai", "jiangboyue", "bgm_xiahoudun"}
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if not table.contains(banned, p:getGeneralName()) then
				table.insert(banned, p:getGeneralName())
			end
			if p:getGeneral2() and not table.contains(banned, p:getGeneral2Name()) then
				table.insert(banned, p:getGeneral2Name())
			end
		end
		if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_")or room:getMode() == "custom_scenario") then
			table.removeTable(generals, sgs.GetConfig("Banlist/Roles", ""):split(","))
		elseif (room:getMode() == "04_1v3") then
			table.removeTable(generals, sgs.GetConfig("Banlist/HulaoPass", ""):split(","))
		elseif (room:getMode() == "06_XMode") then
			table.removeTable(generals, sgs.GetConfig("Banlist/XMode", ""):split(","))
			for _,p in sgs.qlist(room:getAlivePlayers())do
				table.removeTable(generals, (p:getTag("XModeBackup"):toStringList()) or {})
			end
		elseif (room:getMode() == "02_1v1") then
			table.removeTable(generals, sgs.GetConfig("Banlist/1v1", ""):split(","))
			for _,p in sgs.qlist(room:getAlivePlayers())do
				table.removeTable(generals, (p:getTag("1v1Arrange"):toStringList()) or {})
			end
		end
		for i=1, #generals, 1 do
			if table.contains(banned, generals[i]) then
				table.remove(generals, i)
			end
		end
		for i=1, #generals, 1 do
			local ageneral = sgs.Sanguosha:getGeneral(generals[i])
			if ageneral ~= nil then 
				local N = ageneral:getVisibleSkillList():length()
				local x = 0
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					for _, sk in sgs.qlist(ageneral:getVisibleSkillList()) do
						if pe:hasSkill(sk:objectName()) then x = x + 1 end
					end
				end
				if x == N then table.remove(generals, i) end
			end
		end
		if #generals > 0 then
			table.insert(Huashens, generals[math.random(1, #generals)])
		end
	end
	zuoci:setTag("absense_generals_record", sgs.QVariant(table.concat(Huashens, "+")))
end

local function getZhitianSkill(zuoci)
	local room = zuoci:getRoom()
	Hs_String = zuoci:getTag("absense_generals_record"):toString()
	local zhitian_skills = {}
	if Hs_String and Hs_String ~= "" then
		local Huashens = Hs_String:split("+")		
		for _, general_name in ipairs(Huashens) do
			local msg = sgs.LogMessage()
			msg.type = "#ShowAbsenseGenerals"
			msg.from = zuoci
			msg.arg = general_name
			room:sendLog(msg)		
			local general = sgs.Sanguosha:getGeneral(general_name)		
			for _, sk in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(zhitian_skills, sk:objectName())
			end
		end
	end
	if #zhitian_skills > 0 then
		for _, pe in sgs.qlist(room:getAlivePlayers()) do
			for _, gsk in sgs.qlist(pe:getVisibleSkillList()) do
				if table.contains(zhitian_skills, gsk:objectName()) then table.removeOne(zhitian_skills, gsk:objectName()) end
			end
		end
	end
	if #zhitian_skills > 0 then
		return zhitian_skills
	else
		return {}
	end
end

sgkgodzhitian = sgs.CreateTriggerSkillV2{
    name = "sgkgodzhitian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() == sgs.Player_RoundStart then return skill:objectName() end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
	    acquireGenerals(player, 3)
		local skill_list = getZhitianSkill(player)
		local skill = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"), data)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@zhitian-target:"..skill)
		if target then
			room:doAnimate(1, player:objectName(), target:objectName())
		    room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			if target:objectName() ~= player:objectName() and not player:isKongcheng() then
				room:obtainCard(target, player:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), "sgkgodzhitian", ""), false)
			end
			room:acquireSkill(target, skill)
			room:loseHp(target, 1, true, player, self:objectName())
		end
		return false
	end
}


sgkgodsimahui:addSkill(sgkgodyinshi)
sgkgodsimahui:addSkill(sgkgodzhitian)


sgs.LoadTranslationTable{
	["sgkgodsimahui"] = "神司马徽",
	["#sgkgodsimahui"] = "水镜先生",
	["&sgkgodsimahui"] = "神司马徽",
	["~sgkgodsimahui"] = "万物顺应成天，老夫自当归去……",
	["sgkgodyinshi"] = "隐世",
	["$sgkgodyinshi"] = "逃遁避世，虽逢无道，心无所闷。",
	[":sgkgodyinshi"] = "锁定技，当你受到伤害时，你摸X张牌（X为伤害值），然后若此伤害不为雷电伤害，你防止之。",
	["sgkgodzhitian"] = "知天",
	["$sgkgodzhitian"] = "见龙在田，利见大人。",
	[":sgkgodzhitian"] = "锁定技，回合开始时，你随机观看三张未加入游戏的武将牌并选择其中一张上的一个技能，然后你将所有手牌交给一名角色（若为你则跳过），令其"..
	"获得该技能并失去1点体力。",
	["#ShowAbsenseGenerals"] = "%from展示了一张武将牌“%arg”",
	["@zhitian-target"] = "“知天”效果触发，你须将所有手牌交给一名角色并令其获得“%src”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["designer:sgkgodsimahui"] =" 极略三国",
	["illustrator:sgkgodsimahui"] = "极略三国",
	["cv:sgkgodsimahui"] = "极略三国",
}


--神甘宁
sgkgodganning = sgs.General(extension, "sgkgodganning", "sy_god", 4)


--[[
	技能名：掠阵
	相关武将：神甘宁
	技能描述：当你使用【杀】指定目标后，你可以将牌堆顶的3张牌置入弃牌堆，其中每有1张非基本牌，你弃置目标角色1张牌。
	备注：这个是初代神甘宁，后面经历过两次改版，而且SP神甘宁都出了，但这个版本的我真不想改。
	引用：sgkgodluezhen
]]--
sgkgodluezhen = sgs.CreateTriggerSkillV2{
    name = "sgkgodluezhen",
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not use.from then return false end
		if player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
		if use.to:contains(player) then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if not use.from then return false end
		if player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
		if use.to:contains(player) then return false end
		if room:getDrawPile():length()< 3 then room:swapPile() end
		local cards = room:getDrawPile()
		for _, t in sgs.qlist(use.to) do
		    if t:isNude() then return false end
		    if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
		    local a = 0
			local b = 0
			local luezhen = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			while b < 3 do
			    local cardsid = cards:at(0)
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(cardsid)
				move.to = player
			    move.to_place = sgs.Player_PlaceTable
			    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			    room:moveCardsAtomic(move, true)
				local c = sgs.Sanguosha:getCard(cardsid)
				if not c:isKindOf("BasicCard") then a = a + 1 end
				luezhen:addSubcard(cardsid)
				b = b + 1
				if cards:length() == 0 then room:swapPile() end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
			room:throwCard(luezhen, reason, nil)
			luezhen:deleteLater()
			if a > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			    for i = 1, math.max(a, t:getCards("he"):length()) do
				    if t:isNude() then break end
					local id = room:askForCardChosen(player, t, "he", self:objectName(), true, sgs.Card_MethodDiscard, dummy:getSubcards())
			        dummy:addSubcard(id)
				end
				if dummy:subcardsLength() > 0 then
				    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), "")
					room:throwCard(dummy, reason, nil)
				end
				dummy:deleteLater()
			end
		end
	end
}


--[[
	技能名：游龙
	相关武将：神甘宁
	技能描述：出牌阶段，若弃牌堆的牌数多于摸牌堆，你可以将黑色手牌当【顺手牵羊】使用。
	引用：sgkgodyoulong
]]--
sgkgodyoulong = sgs.CreateViewAsSkillV2{
    name = "sgkgodyoulong",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
	    return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("youlong") > 0 and not player:isKongcheng()
	end,
	can_select_card = function(skill, request, to_select)
	    local value = request:getInitiator():getMark("youlong")
		if value == 1 then
		    return to_select:isBlack() and (not to_select:isEquipped())
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
	    local youlong_snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
		youlong_snatch:addSubcard(card)
		youlong_snatch:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			youlong_snatch:setSkillInstanceId(instance_id)
			youlong_snatch:setActivationSkill("sgkgodyoulong", instance_id)
			youlong_snatch:setSourceSkill("sgkgodyoulong", instance_id)
		end
		return youlong_snatch
	end,
}

sgkgodyoulongMoveCheck = sgs.CreateTriggerSkillV2{
    name = "#sgkgodyoulong-MoveCheck",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if move.to_place ~= sgs.Player_DiscardPile then return false end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName("sgkgodyoulong")) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local ganning = room:findPlayerBySkillName("sgkgodyoulong")
		if not ganning then return false end
	    local a = room:getDiscardPile():length()
		local b = room:getDrawPile():length()
		if a > b then
		    room:setPlayerMark(ganning, "youlong", 1)
		else
		    room:setPlayerMark(ganning, "youlong", 0)
		end
		return false
	end,
}


extension:insertRelatedSkills("sgkgodyoulong", "#sgkgodyoulong-MoveCheck")
sgkgodganning:addSkill(sgkgodluezhen)
sgkgodganning:addSkill(sgkgodyoulong)


sgs.LoadTranslationTable{
	["sgkgodganning"] = "神甘宁",
	["#sgkgodganning"] = "疾驱斩浪",
	["&sgkgodganning"] = "神甘宁",
	["~sgkgodganning"] = "哼！江东好汉，誓死不降！",
	["sgkgodluezhen"] = "掠阵",
	["$sgkgodluezhen1"] = "天不怕，临阵杀人！",
	["$sgkgodluezhen2"] = "地不慌，攻池破城！",
	[":sgkgodluezhen"] = "当你使用【杀】指定目标后，你可以将牌堆顶的3张牌置入弃牌堆，其中每有1张非基本牌，你弃置目标角色1张牌。",
	["sgkgodyoulong"] = "游龙",
	["#sgkgodyoulong-MoveCheck"] = "游龙",
	["$sgkgodyoulong1"] = "青甲刀，拿人头！",
	["$sgkgodyoulong2"] = "游龙手，夺绣花！",
	[":sgkgodyoulong"] = "出牌阶段，若弃牌堆的牌数多于摸牌堆，你可以将黑色手牌当【顺手牵羊】使用。",
	["designer:sgkgodganning"] = "极略三国",
	["illustrator:sgkgodganning"] = "极略三国",
	["cv:sgkgodganning"] = "极略三国",
}


--神典韦
sgkgoddianwei = sgs.General(extension, "sgkgoddianwei", "sy_god", 5)


--[[
	技能名：掷戟
	相关武将：神典韦
	技能描述：出牌阶段限一次，你可以弃置至少一张武器牌，然后对至多等量的其他角色各造成等量的伤害。准备阶段，若你已受伤，或当你受到伤害后，你可从场上、牌堆、
	弃牌堆中获得一张武器牌，然后弃置一张非装备牌。
	引用：sgkgodzhiji
]]--
sgkgodzhijiCard = sgs.CreateSkillCard{
    name = "sgkgodzhijiCard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select, player)
		return to_select:getSeat() ~= player:getSeat() and #targets < self:subcardsLength()
	end,
	feasible = function(self, targets, player)
	    return #targets > 0 and #targets <= self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sgkgodzhiji", "")
		room:throwCard(self, reason, nil)
		room:broadcastSkillInvoke("sgkgodzhiji", math.random(1, 3))
		for i = 1, #targets, 1 do
			room:damage(sgs.DamageStruct("sgkgodzhiji", source, targets[i], self:getSubcards():length()))
		end
	end
}

sgkgodzhijiVS = sgs.CreateViewAsSkillV2{
    name = "sgkgodzhiji",
	n = 999,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
	    return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodzhiji") and player:canDiscard(player, "he")
	end,
	can_select_card = function(skill, request, to_select)
	    return (not request:getInitiator():isJilei(to_select)) and to_select:isKindOf("Weapon")
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() > 0
	end,
	can_select_target = function(skill, request, selected, candidate)
		return candidate:getSeat() ~= request:getInitiator():getSeat()
			and #selected < #request:getSelectedCardIds()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected > 0 and #selected <= #request:getSelectedCardIds()
	end,
	create_card = function(skill, request)
		local zhiji_card = sgkgodzhijiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
		    zhiji_card:addSubcard(id)
		end
		zhiji_card:setSkillName("sgkgodzhiji")
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			zhiji_card:setSkillInstanceId(instance_id)
			zhiji_card:setActivationSkill("sgkgodzhiji", instance_id)
			zhiji_card:setSourceSkill("sgkgodzhiji", instance_id)
		end
		return zhiji_card
	end,
}

sgkgodzhiji = sgs.CreateTriggerSkillV2{
    name = "sgkgodzhiji",
	view_as_skill = sgkgodzhijiVS,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged or (player:getPhase() == sgs.Player_Start and player:isWounded()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged or (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:isWounded()) then
			local to_get = {}
			local hasweapon = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if pe:getWeapon() ~= nil and player:canGet(pe, pe:getWeapon():getEffectiveId()) then hasweapon:append(pe) end
			end
			if not hasweapon:isEmpty() then table.insert(to_get, "zhiji_fromOther") end
			local Weapon_items = sgs.IntList()
			for _, c in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(c):isKindOf("Weapon") then
					local weapon = sgs.Sanguosha:getCard(c)
					Weapon_items:append(weapon:getEffectiveId())
				end
			end
			for _, c in sgs.qlist(room:getDiscardPile()) do
				if sgs.Sanguosha:getCard(c):isKindOf("Weapon") then
					local weapon = sgs.Sanguosha:getCard(c)
					Weapon_items:append(weapon:getEffectiveId())
				end
			end
			if not Weapon_items:isEmpty() then table.insert(to_get, "zhiji_fromPile") end
			if #to_get == 0 then return false end
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 4)
				local choice = room:askForChoice(player, self:objectName(), table.concat(to_get, "+"), data)
				if choice == "zhiji_fromOther" then
					local t = room:askForPlayerChosen(player, hasweapon, self:objectName())
					if t then
						room:doAnimate(1, player:objectName(), t:objectName())
						room:obtainCard(player, t:getWeapon(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), t:objectName(), "sgkgodzhiji", ""), true)
					end
				else
					local N = Weapon_items:length() - 1
					local ran_weapon = Weapon_items:at(math.random(0, N))
					room:obtainCard(player, ran_weapon, "sgkgodzhiji", false)
				end
				Weapon_items = sgs.IntList()
				local has_not_equip = false
				for _, _card in sgs.qlist(player:getCards("he")) do
					if not _card:isKindOf("EquipCard") then
						has_not_equip = true
						break
					end
				end
				if has_not_equip then room:askForDiscard(player, self:objectName(), 1, 1, false, true, nil, "^EquipCard") end
			end
		end
		return false
	end
}


sgkgoddianwei:addSkill(sgkgodzhiji)


sgs.LoadTranslationTable{
	["sgkgoddianwei"] = "神典韦",
	["#sgkgoddianwei"] = "丘峦崩摧",
	["&sgkgoddianwei"] = "神典韦",
	["~sgkgoddianwei"] = "主公安然，末将，死而……无憾……",
	["sgkgodzhiji"] = "掷戟",
	["$sgkgodzhiji1"] = "恶来之力，助我神威！",
	["$sgkgodzhiji2"] = "铁戟出，地狱开！",
	["$sgkgodzhiji3"] = "这一戟，定让你魂飞魄散！",
	["$sgkgodzhiji4"] = "这天下，没有我拿不动的兵器！",
	[":sgkgodzhiji"] = "出牌阶段限一次，你可以弃置至少一张武器牌，然后对至多等量的其他角色各造成等量的伤害。准备阶段，若你已受伤，或当你受到伤害后，你可从场上、"..
	"牌堆、弃牌堆中获得一张武器牌，然后弃置一张非装备牌。",
	["zhiji_fromOther"] = "从场上获得一张武器牌",
	["zhiji_fromPile"] = "从牌堆或弃牌堆中获得一张武器牌",
	["designer:sgkgoddianwei"] = "极略三国",
	["illustrator:sgkgoddianwei"] = "极略三国",
	["cv:sgkgoddianwei"] = "极略三国",
}


--神夏侯惇
sgkgodxiahoudun = sgs.General(extension, "sgkgodxiahoudun", "sy_god", 5)


--[[
	技能名：啖睛
	相关武将：神夏侯惇
	技能描述：当你受到伤害/失去体力/减体力上限/弃置牌后，你可以令一名其他角色也执行此效果。
	引用：sgkgoddanjing
]]--
function Nature2String(nature)
	if nature == sgs.DamageStruct_Normal then return "normal" end
	if nature == sgs.DamageStruct_Fire then return "fire" end
	if nature == sgs.DamageStruct_Thunder then return "thunder" end
	if nature == sgs.DamageStruct_Ice then return "ice" end
	if nature == sgs.DamageStruct_Poison then return "poison" end
end

sgkgoddanjing = sgs.CreateTriggerSkillV2{
	name = "sgkgoddanjing",
	events = {sgs.Damaged, sgs.HpLost, sgs.CardsMoveOneTime, sgs.MaxHpChanged},
	priority = {1, 1, 1, 10},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.from and move.from:objectName() == player:objectName()
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				return false
			end
		elseif event == sgs.MaxHpChanged then
			if data:toMaxHp().change >= 0 then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local q = sgs.QVariant()
			q:setValue(damage)
			player:setTag("danjing_damage", q)
			if damage.damage > 0 then
				local current_nature = damage.nature
				local prompt = "@danjing_dmg:"..tostring(damage.damage)..":"..Nature2String(current_nature)
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sgkgoddanjing_damage", prompt, true, true)
				if target then
					room:doAnimate(1, player:objectName(), target:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), player, target, damage.damage, current_nature))
				end
			end
		elseif event == sgs.HpLost then
			local lose = data:toHpLost().lose
			local prompt = "@danjing_lose:"..tostring(lose)
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sgkgoddanjing_lose", prompt, true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(target, lose, true, player, self:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			local prompt = "@danjing_discard:"..tostring(x)
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sgkgoddanjing_discard", prompt, true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:askForDiscard(target, self:objectName(), x, x, false, true)
			end
		elseif event == sgs.MaxHpChanged then
			local change = data:toMaxHp()
			local dif = 0 - change.change
			local prompt = "@danjing_maxhp:"..tostring(dif)
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sgkgoddanjing_maxhp", prompt, true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseMaxHp(target, dif)
			end
		end
		return false
	end
}


--[[
	技能名：忠魂
	相关武将：神夏侯惇
	技能描述：限定技，游戏开始时，或出牌阶段，你可以选择一名其他角色，令其加1点体力上限并回复1点体力；当该角色受到伤害时，若伤害来源不为你，将此伤害转移
	给你；当你死亡时，其获得你的所有技能。
	引用：sgkgodzhonghun
]]--
sgkgodzhonghunCard = sgs.CreateSkillCard{
	name = "sgkgodzhonghunCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and to_select:getMark("&sgkgodzhonghun") == 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local zhonghun_data = sgs.QVariant()
		zhonghun_data:setValue(target)
		source:setTag("zhonghunTarget", zhonghun_data)
		room:addPlayerMark(source, "sgkgodzhonghun")
		room:addPlayerMark(target, "&sgkgodzhonghun")
		room:gainMaxHp(target, 1)
		local rec = sgs.RecoverStruct()
		rec.recover = 1
		rec.who = source
		room:recover(target, rec, true)
	end
}

sgkgodzhonghunVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodzhonghun",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:hasUsed("sgkgodzhonghun") and player:getMark("sgkgodzhonghun") == 0
		end
		return request:getPattern() == "@@sgkgodzhonghun" and player:getMark("sgkgodzhonghun") == 0
	end,
	can_select_target = function(skill, request, selected, candidate)
		if #selected ~= 0 then return false end
		return candidate:objectName() ~= request:getInitiator():objectName()
			and candidate:getMark("&sgkgodzhonghun") == 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodzhonghunCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodzhonghun", instance_id)
		card:setSourceSkill("sgkgodzhonghun", instance_id)
		return card
	end,
}


sgkgodzhonghun = sgs.CreateTriggerSkillV2{
    name = "sgkgodzhonghun",
	view_as_skill = sgkgodzhonghunVS,
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart, sgs.DamageInflicted, sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getMark("&"..skill:objectName()) <= 0 or damage.damage <= 0 or not damage.from then return false end
			local names, owners = {}, {}
			for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if damage.from:getSeat() ~= s:getSeat() then
					table.insert(names, skill:objectName())
					table.insert(owners, s:objectName())
				end
			end
			if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
			return false
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			if not room:askForUseCard(player, "@@sgkgodzhonghun", "@sgkgodzhonghun") then room:setPlayerMark(player, self:objectName(), 0) end
		elseif event == sgs.DamageInflicted then
			local xiahou = player
			local damage = data:toDamage()
			damage.to = xiahou
			damage.transfer = true
			data:setValue(damage)
		elseif event == sgs.Death then
			local death = data:toDeath()
			local zhonghun_tar = player:getTag("zhonghunTarget"):toPlayer()
			if zhonghun_tar and zhonghun_tar:isAlive() then
				local my_skills = {}
				local skill_list = player:getVisibleSkillList()
				for _, skill in sgs.qlist(skill_list) do
					table.insert(my_skills, skill:objectName())
				end
				if #my_skills == 0 then return false end
				room:doAnimate(1, player:objectName(), zhonghun_tar:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:handleAcquireDetachSkills(zhonghun_tar, table.concat(my_skills, "|"))
			end
		end
		return false
	end,
}


sgkgodxiahoudun:addSkill(sgkgoddanjing)
sgkgodxiahoudun:addSkill(sgkgodzhonghun)


sgs.LoadTranslationTable{
    ["sgkgodxiahoudun"] = "神夏侯惇",
	["&sgkgodxiahoudun"] = "神夏侯惇",
	["#sgkgodxiahoudun"] = "不灭忠候",
	["~sgkgodxiahoudun"] = "我要……亲自向丞相、谢罪……",
	["sgkgoddanjing"] = "啖睛",
	["sgkgoddanjing_damage"] = "啖睛",
	["sgkgoddanjing_discard"] = "啖睛",
	["sgkgoddanjing_lose"] = "啖睛",
	["sgkgoddanjing_maxhp"] = "啖睛",
	["normal"] = "无属性",
	["fire"] = "火焰",
	["thunder"] = "雷电",
	["ice"] = "冰冻",
	["poison"] = "毒性",
	[":sgkgoddanjing"] = "当你受到伤害/失去体力/减体力上限/弃置牌后，你可以令一名其他角色也执行此效果。",
	["@danjing_dmg"] = "你可以发动“啖睛”对一名其他角色造成%src点%dest伤害",
	["@danjing_lose"] = "你可以发动“啖睛”令一名其他角色失去%src点体力",
	["@danjing_maxhp"] = "你可以发动“啖睛”令一名其他角色失去%src点体力上限",
	["@danjing_discard"] = "你可以发动“啖睛”令一名其他角色弃置%src张牌",
	["$sgkgoddanjing1"] = "我看见你了！",
	["$sgkgoddanjing2"] = "想走？把人头留下！",
	["$sgkgoddanjing3"] = "父精母血，不可弃之！",
	["sgkgodzhonghun"] = "忠魂",
	[":sgkgodzhonghun"] = "限定技，游戏开始时，或出牌阶段，你可以选择一名其他角色，令其加1点体力上限并回复1点体力；当该角色受到伤害时，"..
	"若伤害来源不为你，将此伤害转移给你；当你死亡时，其获得你的所有技能。",
	["$sgkgodzhonghun1"] = "都等什么？继续冲！",
	["$sgkgodzhonghun2"] = "还没分出胜负！",
	["@sgkgodzhonghun"] = "你可以选择一名其他角色对其发动“忠魂”，则本局游戏你将替其承担一切有来源且不为你造成的伤害，你死后其获得你的所有武将技能。",
	["designer:sgkgodxiahoudun"] =" 极略三国",
	["illustrator:sgkgodxiahoudun"] = "极略三国",
	["cv:sgkgodxiahoudun"] = "极略三国",
}


--神孙尚香
sgkgodsunshangxiang = sgs.General(extension, "sgkgodsunshangxiang", "sy_god", 3, false)


--[[
	技能名：贤助
	相关武将：神孙尚香
	技能描述：当一名角色回复体力后，或失去装备区里的牌后，你可以令其摸两张牌。
	引用：sgkgodxianzhu
]]--
sgkgodxianzhu = sgs.CreateTriggerSkillV2{
	name = "sgkgodxianzhu",
	events = {sgs.CardsMoveOneTime, sgs.HpRecover},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.from and move.from:objectName() == player:objectName()
				and move.from_places:contains(sgs.Player_PlaceEquip)) then return false end
		end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local _data = sgs.QVariant()
		_data:setValue(ctx.invoker)
		return player:askForSkillInvoke(skill:objectName(), _data)
	end,
	on_effect = function(self, event, room, player, ctx)
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		room:doAnimate(1, player:objectName(), ctx.invoker:objectName())
		ctx.invoker:drawCards(2, self:objectName())
		return false
	end,
}


sgkgodsunshangxiang:addSkill(sgkgodxianzhu)


--[[
	技能名：良缘
	相关武将：神孙尚香
	技能描述：限定技，出牌阶段，你可以选择一名其他男性角色，则于本局游戏中，你的自然回合结束时，该角色进行一个额外的回合。
	引用：sgkgodliangyuan
]]--
sgkgodliangyuanCard = sgs.CreateSkillCard{
	name = "sgkgodliangyuanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    if #targets == 0 then
		    return to_select:objectName() ~= player:objectName() and to_select:isMale() and to_select:isAlive()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@liangyuan")
		local target = targets[1]
		room:addPlayerMark(target, "liangyuan_exturn_to")
		room:addPlayerMark(source, "liangyuan_exturn_from")
		room:addPlayerMark(target, "&sgkgodliangyuan+to+#"..source:objectName())
	end
}

sgkgodliangyuanVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodliangyuan",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and (not player:hasUsed("sgkgodliangyuan")) and player:getMark("@liangyuan") > 0
	end,
	can_select_target = function(skill, request, selected, candidate)
		if #selected ~= 0 then return false end
	    return candidate:objectName() ~= request:getInitiator():objectName()
			and candidate:isMale() and candidate:isAlive()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodliangyuanCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodliangyuan", instance_id)
		card:setSourceSkill("sgkgodliangyuan", instance_id)
		return card
	end,
}

sgkgodliangyuan = sgs.CreateTriggerSkillV2{
	name = "sgkgodliangyuan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@liangyuan",
	view_as_skill = sgkgodliangyuanVS,
	events = {},
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		return false
	end
}

sgkgodliangyuan_check = sgs.CreateTriggerSkillV2{
	name = "#sgkgodliangyuan_check",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getMark("liangyuan_exturn_from") > 0
			and not room:getTag("ExtraTurn"):toBool() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local liangyuan_male
		for _, pe in sgs.qlist(room:getAlivePlayers()) do
			if pe:getMark("liangyuan_exturn_to") > 0 then
				liangyuan_male = pe
				break
			end
		end
		if liangyuan_male then
			local playerdata = sgs.QVariant()
			playerdata:setValue(liangyuan_male)
			room:setTag("sgkgodliangyuan_exturn_Target", playerdata)
		end
		return false
	end,
}

sgkgodliangyuan_exgive = sgs.CreateTriggerSkillV2{
	name = "#sgkgodliangyuan_exgive",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_NotActive then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if room:getTag("sgkgodliangyuan_exturn_Target") then
			local target = room:getTag("sgkgodliangyuan_exturn_Target"):toPlayer()
			room:removeTag("sgkgodliangyuan_exturn_Target")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
}


sgkgodsunshangxiang:addSkill(sgkgodliangyuan)


sgs.LoadTranslationTable{
    ["sgkgodsunshangxiang"] = "神孙尚香",
	["&sgkgodsunshangxiang"] = "神孙尚香",
	["#sgkgodsunshangxiang"] = "蕙兰巾帼",
	["~sgkgodsunshangxiang"] = "夫君，你可会记得我的好……",
	["sgkgodxianzhu"] = "贤助",
	[":sgkgodxianzhu"] = "当一名角色回复体力后，或失去装备区里的牌后，你可以令其摸两张牌。",
	["$sgkgodxianzhu1"] = "春风复多情，吹我罗裳开。",
	["$sgkgodxianzhu2"] = "春林花多媚，春鸟意多哀。",
	["sgkgodliangyuan"] = "良缘",
	["@liangyuan"] = "良缘",
	[":sgkgodliangyuan"] = "限定技，出牌阶段，你可以选择一名其他男性角色，则于本局游戏中，你的自然回合结束时，该角色进行一个额外的回合。",
	["$sgkgodliangyuan"] = "我心如松柏，君情复何似？",
	["designer:sgkgodsunshangxiang"] =" 极略三国",
	["illustrator:sgkgodsunshangxiang"] = "极略三国",
	["cv:sgkgodsunshangxiang"] = "极略三国",
}


--神马超
sgkgodmachao = sgs.General(extension, "sgkgodmachao", "sy_god", 4, true)


--[[
	技能名：千骑
	相关武将：神马超
	技能描述：游戏开始时，你随机装备进攻马和防御马。当一名角色从装备区失去坐骑牌后，你获得2个“千骑”标记。出牌阶段，你可以移去1个“千骑”标记，视为使用一张【杀】
	（无距离和次数限制）。
	引用：sgkgodqianqi
]]--
sgkgodqianqiCard = sgs.CreateSkillCard{
	name = "sgkgodqianqiCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self,targets,to_select,player)
		local card =  sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player) and 
			not player:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = false,
	feasible = function(self, targets, player)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:setSkillName("qianqi_slash")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local machao = card_use.from
		local room = machao:getRoom()		
		local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		use_card:setSkillName("qianqi_slash")			
		use_card:deleteLater()
		local tos = card_use.to
		for _, to in sgs.qlist(tos) do
			local skill = room:isProhibited(machao, to, use_card)
			if skill then
				local log = sgs.LogMessage()
				log.type = "#SkillAvoid"
				log.from = to
				log.arg = skill:objectName()
				log.arg2 = use_card:objectName()
				room:sendLog(log)
				card_use.to:removeOne(to)
			end
		end
		return use_card
	end
}

sgkgodqianqiVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodqianqi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("&sgkgodqianqi") > 0
	end,
	create_card = function(skill, request)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("qianqi_slash")
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			slash:setSkillInstanceId(instance_id)
			slash:setActivationSkill("sgkgodqianqi", instance_id)
			slash:setSourceSkill("sgkgodqianqi", instance_id)
		end
		return slash
	end,
}

sgkgodqianqi = sgs.CreateTriggerSkillV2{
	name = "sgkgodqianqi",
	view_as_skill = sgkgodqianqiVS,
	events = {sgs.GameStart, sgs.CardUsed, sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if not (use.card and use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), "qianqi_slash")) then
				return false
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.from_places:contains(sgs.Player_PlaceEquip) and player:isAlive()) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			local offensive, defensive = {}, {}
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("OffensiveHorse") then table.insert(offensive, card) end
				if card:isKindOf("DefensiveHorse") then table.insert(defensive, card) end
			end
			if #offensive > 0 or #defensive > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				local of_horse, de_horse = -1, -1
				if #offensive > 0 then of_horse = offensive[math.random(1, #offensive)] end
				if #defensive > 0 then de_horse = defensive[math.random(1, #defensive)] end
				if of_horse ~= -1 then
					if player:isAlive() and (not player:isCardLimited(of_horse, sgs.Card_MethodUse)) then
						room:useCard(sgs.CardUseStruct(of_horse, player, player))
					end
				end
				if de_horse ~= -1 then
					if player:isAlive() and (not player:isCardLimited(de_horse, sgs.Card_MethodUse)) then
						room:useCard(sgs.CardUseStruct(de_horse, player, player))
					end
				end
			end
		elseif event == sgs.CardUsed then
			room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			player:loseMark("&sgkgodqianqi")
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse") then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					player:gainMark("&sgkgodqianqi", 2)
				end
			end
			return false
		end
		return false
	end
}


sgkgodmachao:addSkill(sgkgodqianqi)


--[[
	技能名：绝尘
	相关武将：神马超
	技能描述：当你使用【杀】对其他角色即将造成伤害时，你可以防止此伤害，改为令其失去X点体力（X为伤害值）或减1点体力上限。
	引用：sgkgodjuechen
]]--
sgkgodjuechen = sgs.CreateTriggerSkillV2{
	name = "sgkgodjuechen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.to and damage.to:getSeat() ~= player:getSeat() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local _t = sgs.QVariant()
		_t:setValue(damage.to)
		return player:askForSkillInvoke(skill:objectName(), _t)
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		local _t = sgs.QVariant()
		_t:setValue(damage.to)
		local x = damage.damage
		local lists = {"jc_losehp="..tostring(x), "jc_losemaxhp"}
		local jc = room:askForChoice(player, self:objectName(), table.concat(lists, "+"), _t)
		if jc:startsWith("jc_losehp") then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:loseHp(damage.to, x, true, player, self:objectName())
			return true
		else
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:loseMaxHp(damage.to)
			return true
		end
	end
}


sgkgodmachao:addSkill(sgkgodjuechen)


sgs.LoadTranslationTable{
    ["sgkgodmachao"] = "神马超",
	["&sgkgodmachao"] = "神马超",
	["#sgkgodmachao"] = "神威天将军",
	["~sgkgodmachao"] = "（马鸣）",
	["sgkgodqianqi"] = "千骑",
	[":sgkgodqianqi"] = "游戏开始时，你随机装备进攻马和防御马。当一名角色从装备区失去坐骑牌后，你获得2个“千骑”标记。出牌阶段，你可以移去1个“千骑”"..
	"标记，视为使用一张【杀】（无距离和次数限制）。",
	["$sgkgodqianqi1"] = "千军万马，随我破阵杀敌！",
	["$sgkgodqianqi2"] = "得此良驹，我军无人可挡！",
	["$sgkgodqianqi3"] = "这就是，一骑当千的力量！",
	["$sgkgodqianqi4"] = "你被包围了，还不束手就擒！",
	["sgkgodjuechen"] = "绝尘",
	[":sgkgodjuechen"] = "当你使用【杀】对其他角色即将造成伤害时，你可以防止此伤害，改为令其失去X点体力（X为伤害值）或减1点体力上限。",
	["sgkgodjuechen:jc_losehp"] = "改为失去%src点体力",
	["jc_losemaxhp"] = "改为减1点体力上限",
	["$sgkgodjuechen1"] = "奔轶绝尘，袭敌无影！",
	["$sgkgodjuechen2"] = "哈哈哈哈哈！太慢了！",
	["designer:sgkgodmachao"] =" 极略三国",
	["illustrator:sgkgodmachao"] = "极略三国",
	["cv:sgkgodmachao"] = "极略三国",
}


--神甄姬
sgkgodzhenji = sgs.General(extension, "sgkgodzhenji", "sy_god", 3, false)


--[[
	技能名：神赋
	相关武将：神甄姬
	技能描述：当你失去手牌后，若你的手牌数小于四，你记录此次失去牌的花色并将手牌数摸至四张（同时失去多张牌视为无花色，至多记录四次花色）；然后若记录了
	四次不同的花色，你可以对一名其他角色造成1点雷电伤害。
	引用：sgkgodshenfu
]]--
sgkgodshenfu = sgs.CreateTriggerSkillV2{
	name = "sgkgodshenfu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if not move.from or move.from:objectName() ~= player:objectName() then return false end
		if not move.from_places:contains(sgs.Player_PlaceHand) then return false end
		if player:getHandcardNum() >= 4 then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local suit_str
		if move.card_ids:length() == 1 then
			local card = sgs.Sanguosha:getCard(move.card_ids:first())
			if card:getSuit() ~= sgs.Card_NoSuit then
				suit_str = card:getSuitString()
			else
				suit_str = "nosuit"
			end
		elseif move.card_ids:length() > 1 then
			suit_str = "nosuit"
		end
		if suit_str then
			local shenfurec = {}
			for _, s in ipairs(player:getTag("sgkgodshenfu_suitslost"):toString():split("+")) do
				if s ~= "" then table.insert(shenfurec, s) end
			end
			table.insert(shenfurec, suit_str)
			while #shenfurec > 4 do table.remove(shenfurec, 1) end
			local suits = {}
			for _, _s in ipairs(shenfurec) do
				table.insert(suits, _s.."_char")
			end
			for _, name in sgs.list(player:getMarkNames()) do
				if name:startsWith("&sgkgodshenfu+:+") then room:setPlayerMark(player, name, 0) end
			end
			player:setTag("sgkgodshenfu_suitslost", sgs.QVariant(table.concat(shenfurec, "+")))
			room:setPlayerMark(player, "&sgkgodshenfu+:+"..table.concat(suits, "+"), 1)
		end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(4 - player:getHandcardNum(), self:objectName())
		end
		local shenfurec = {}
		for _, s in ipairs(player:getTag("sgkgodshenfu_suitslost"):toString():split("+")) do
			if s ~= "" then table.insert(shenfurec, s) end
		end
		local can_damage = (#shenfurec == 4)
		if can_damage then
			local seen = {}
			for _, s in ipairs(shenfurec) do
				if seen[s] then
					can_damage = false
					break
				end
				seen[s] = true
			end
		end
		if can_damage then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@shenfu-thunder", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
			end
		end
		return false
	end
}


sgkgodzhenji:addSkill(sgkgodshenfu)


sgs.LoadTranslationTable{
    ["sgkgodzhenji"] = "神甄姬",
	["&sgkgodzhenji"] = "神甄姬",
	["#sgkgodzhenji"] = "洛水之神",
	["~sgkgodzhenji"] = "今夕……何夕……",
	["sgkgodshenfu"] = "神赋",
	[":sgkgodshenfu"] = "当你失去手牌后，若你的手牌数小于四，你记录此次失去牌的花色并将手牌数摸至四张（同时失去多张牌视为无花色，至多记录四次花色）；"..
	"然后若记录了四次不同的花色，你可以对一名其他角色造成1点雷电伤害。",
	["nosuit_char"] = "🚫",
	["$sgkgodshenfu1"] = "动无常则，若危若安。",
	["$sgkgodshenfu2"] = "进止难期，若往若还。",
	["$sgkgodshenfu3"] = "转眄流精，光润玉颜。",
	["@shenfu-thunder"] = "你已通过触发“神赋”累积失去了4种不同花色的牌，可以对一名角色造成1点雷电伤害。",
	["designer:sgkgodzhenji"] =" 极略三国",
	["illustrator:sgkgodzhenji"] = "极略三国",
	["cv:sgkgodzhenji"] = "极略三国",
}


--神许褚
sgkgodxuchu = sgs.General(extension, "sgkgodxuchu", "sy_god", 5, true)


--[[
	技能名：虎痴
	相关武将：神许褚
	技能描述：出牌阶段，你可以视为使用【决斗】（不能被【无懈可击】响应），以此法受到伤害的角色摸3张牌。若有角色因此进入濒死状态或此【决斗】没有造成伤害，你
	于此阶段内不能再发动此技能。
	引用：sgkgodhuchi
]]--
sgkgodhuchiVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodhuchi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("sgkgodhuchi_duel_forbidden-Clear") == 0
	end,
	create_card = function(skill, request)
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("sgkgodhuchi")
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			duel:setSkillInstanceId(instance_id)
			duel:setActivationSkill("sgkgodhuchi", instance_id)
			duel:setSourceSkill("sgkgodhuchi", instance_id)
		end
		return duel
	end,
}

sgkgodhuchi = sgs.CreateTriggerSkillV2{
	name = "sgkgodhuchi",
	view_as_skill = sgkgodhuchiVS,
	events = {sgs.PreCardUsed, sgs.TrickCardCanceling, sgs.DamageDone, sgs.Damage, sgs.Damaged, sgs.Dying, sgs.CardFinished, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if not (use.from and use.card and use.card:getSkillName() == skill:objectName()
				and use.from:hasSkill(skill:objectName())) then return false end
			return skill:objectName()
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if not (effect.card and effect.card:isKindOf("Duel") and table.contains(effect.card:getSkillNames(), "sgkgodhuchi")) then return false end
		elseif event == sgs.DamageDone then
			local damage = data:toDamage()
			if not (damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == skill:objectName() and damage.damage > 0) then return false end
		elseif event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			if not (damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == skill:objectName() and damage.damage > 0) then return false end
			if not (player:isAlive() and player:getMark("huchi_damage_globalcheck") > 0) then return false end
			return skill:objectName()
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if not (dying.damage and dying.damage.card and dying.damage.card:getSkillName() == skill:objectName()) then return false end
			return skill:objectName()
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not (use.from and use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == skill:objectName()
				and use.from:hasSkill(skill:objectName()) and use.from:getMark("huchi_damage_globalcheck") > 0) then return false end
			return skill:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			return skill:objectName()
		end
		local names, owners = {}, {}
		for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, s:objectName())
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			room:addPlayerMark(use.from, "huchi_damage_globalcheck", 1)
		elseif event == sgs.TrickCardCanceling then
			return true
		elseif event == sgs.DamageDone then
			local damage = data:toDamage()
			damage.to:drawCards(3, self:objectName())
		elseif event == sgs.Damage or event == sgs.Damaged then
			room:setPlayerMark(player, "huchi_damage_globalcheck", 0)
		elseif event == sgs.Dying then
			room:addPlayerMark(player, "sgkgodhuchi_duel_forbidden-Clear")
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			room:addPlayerMark(use.from, "sgkgodhuchi_duel_forbidden-Clear")
		elseif event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "huchi_damage_globalcheck", 0)
		end
		return false
	end
}


sgkgodxuchu:addSkill(sgkgodhuchi)


--[[
	技能名：卸甲
	相关武将：神许褚
	技能描述：锁定技，若你的装备区里没有防具牌，你使用【杀】和【决斗】对其他角色造成的伤害+X（X为你从装备区里失去防具牌的次数+1）。
	引用：sgkgodxiejia
]]--
sgkgodxiejia = sgs.CreateTriggerSkillV2{
	name = "sgkgodxiejia",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if player:getArmor() == nil and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				if damage.to and damage.to:getSeat() ~= player:getSeat() then return skill:objectName() end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to and damage.to:getSeat() ~= player:getSeat() then
				local x = player:getMark("&"..self:objectName())
				if x == 0 then
					room:doAnimate(1, player:objectName(), damage.to:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:sendCompulsoryTriggerLog(player, self:objectName())
					damage.damage = damage.damage + 1
					data:setValue(damage)
				elseif x > 0 then
					room:doAnimate(1, player:objectName(), damage.to:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					local msg = sgs.LogMessage()
					msg.type = "#XiejiaLoseArmor"
					msg.from = player
					msg.arg = tostring(x)
					msg.arg2 = tostring(x+1)
					msg.to:append(damage.to)
					msg.card_str = damage.card:toString()
					room:sendLog(msg)
					damage.damage = damage.damage + (x + 1)
					data:setValue(damage)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local i = 0
			for _, id in sgs.qlist(move.card_ids) do
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:addPlayerMark(player, "&"..self:objectName(), 1)
					end
				end
				i = i + 1
			end
		end
		return false
	end
}


sgkgodxuchu:addSkill(sgkgodxiejia)


sgs.LoadTranslationTable{
    ["sgkgodxuchu"] = "神许褚",
	["&sgkgodxuchu"] = "神许褚",
	["#sgkgodxuchu"] = "雷铸虎躯",
	["~sgkgodxuchu"] = "居然……是我先倒下……",
	["sgkgodhuchi"] = "虎痴",
	[":sgkgodhuchi"] = "出牌阶段，你可以视为使用【决斗】（不能被【无懈可击】响应），以此法受到伤害的角色摸3张牌。若有角色因此进入濒死状态或此【决斗】没有"..
	"造成伤害，你于此阶段内不能再发动此技能。",
	["$sgkgodhuchi1"] = "哈哈哈哈哈哈！痛快！痛快！",
	["$sgkgodhuchi2"] = "不是你死，便是我亡！",
	["sgkgodxiejia"] = "卸甲",
	[":sgkgodxiejia"] = "锁定技，若你的装备区里没有防具牌，你使用【杀】和【决斗】对其他角色造成的伤害+X（X为你从装备区里失去防具牌的次数+1）。",
	["#XiejiaLoseArmor"] = "%from 已从装备区里失去过 %arg 次防具牌，此 %card 对 %to 的伤害额外增加 %arg2 点",
	["$sgkgodxiejia1"] = "拔山扛鼎，力敌千军！",
	["$sgkgodxiejia2"] = "卸下重甲，方能战个痛快！",
	["designer:sgkgodxuchu"] =" 极略三国",
	["illustrator:sgkgodxuchu"] = "极略三国",
	["cv:sgkgodxuchu"] = "极略三国",
}


--神大乔
sgkgoddaqiao = sgs.General(extension, "sgkgoddaqiao", "sy_god", 3, false)


--[[
	技能名：望月
	相关武将：神大乔
	技能描述：每回合每项限一次，当一名角色弃牌/失去体力/减体力上限后，你可以令另一名角色摸牌/回复等量体力/加等量体力上限。
	引用：sgkgodwangyue
]]--
sgkgodwangyue = sgs.CreateTriggerSkillV2{
	name = "sgkgodwangyue",
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.HpLost, sgs.MaxHpChanged},
	priority = {10, 1, 1, 10},
	can_trigger = function(skill, event, room, player, data)
		local names, owners = {}, {}
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(names, skill:objectName())
				table.insert(owners, s:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.from and move.to_place == sgs.Player_DiscardPile
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then return false end
			for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if s:getMark(skill:objectName().."_letdraw") == 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, s:objectName())
				end
			end
		elseif event == sgs.HpLost then
			for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if s:getMark(skill:objectName().."_letrecoverhp") == 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, s:objectName())
				end
			end
		elseif event == sgs.MaxHpChanged then
			if data:toMaxHp().change >= 0 then return false end
			for _, s in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if s:getMark(skill:objectName().."_letaddmaxhp") == 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, s:objectName())
				end
			end
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local daqiao = player
		local invoker = ctx.invoker
		if event == sgs.EventPhaseChanging then
			room:setPlayerMark(daqiao, self:objectName().."_letdraw", 0)  --刷新大乔的每个选项记录
			room:setPlayerMark(daqiao, self:objectName().."_letrecoverhp", 0)
			room:setPlayerMark(daqiao, self:objectName().."_letaddmaxhp", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			daqiao:setTag("wangyue_value", sgs.QVariant(x))
			local _w = sgs.QVariant()
			_w:setValue(move)
			daqiao:setTag("wangyue_draw_AI", _w)
			local target = room:askForPlayerChosen(daqiao, room:getOtherPlayers(invoker), self:objectName(), "@wangyue_draw:"..tostring(x), true, true)
			daqiao:removeTag("wangyue_draw_AI")
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, daqiao:objectName(), target:objectName())
				target:drawCards(x, self:objectName())
				room:addPlayerMark(daqiao, self:objectName().."_letdraw")
			end
		elseif event == sgs.HpLost then
			local lose = data:toHpLost()
			local x = lose.lose
			local _w = sgs.QVariant()
			_w:setValue(lose)
			daqiao:setTag("wangyue_rec_AI", _w)
			local target = room:askForPlayerChosen(daqiao, room:getOtherPlayers(invoker), self:objectName(), "@wangyue_rec:"..tostring(x), true, true)
			daqiao:removeTag("wangyue_rec_AI")
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, daqiao:objectName(), target:objectName())
				if target:isWounded() then
					local rec = sgs.RecoverStruct()
					rec.recover = math.min(x, target:getLostHp())
					rec.who = daqiao
					room:recover(target, rec, true)
				end
				room:addPlayerMark(daqiao, self:objectName().."_letrecoverhp")
			end
		elseif event == sgs.MaxHpChanged then
			local change = data:toMaxHp()
			local dif = 0 - change.change
			local _w = sgs.QVariant()
			_w:setValue(change)
			daqiao:setTag("wangyue_maxhp_AI", _w)
			local target = room:askForPlayerChosen(daqiao, room:getOtherPlayers(invoker), self:objectName(), "@wangyue_maxhp:"..tostring(dif), true, true)
			daqiao:removeTag("wangyue_maxhp_AI")
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, daqiao:objectName(), target:objectName())
				room:gainMaxHp(target, dif)
				room:addPlayerMark(daqiao, self:objectName().."_letaddmaxhp")
			end
		end
		return false
	end
}


sgkgoddaqiao:addSkill(sgkgodwangyue)


--[[
	技能名：落雁
	相关武将：神大乔
	技能描述：结束阶段，你可以选择一名角色；然后该角色于其出牌阶段使用第一/二/三张牌后，其随机弃置一张牌/失去1点体力/减1点体力上限，直到你下一次发动“落雁”。
	引用：sgkgodluoyan
]]--
sgkgodluoyan = sgs.CreateTriggerSkillV2{
	name = "sgkgodluoyan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish or not player:hasSkill(skill:objectName()) then return false end
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				targets:append(pe)
			end
			if targets:isEmpty() then return false end
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event ~= sgs.EventPhaseStart then return true end
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local invoker = ctx.invoker
		if event == sgs.EventPhaseStart then
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				targets:append(pe)
			end
			local has_luoyan = -1
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				if pe:getMark("&"..self:objectName()) > 0 then
					has_luoyan = pe
					break
				end
			end
			local tar = room:askForPlayerChosen(invoker, targets, self:objectName())
			if tar then
				room:doAnimate(1, invoker:objectName(), tar:objectName())
				room:broadcastSkillInvoke(self:objectName())
				if has_luoyan ~= -1 then
					room:setPlayerMark(has_luoyan, "&"..self:objectName(), 0)
					room:setPlayerMark(has_luoyan, "luoyan_cardcount", 0)
				end
				room:addPlayerMark(tar, "&"..self:objectName(), 1)
			end
		end
		return false
	end
}

--落雁標記留在受標記角色身上；大喬死亡後標記仍須結算，故以全局隱藏技能承載
sgkgodluoyanMark = sgs.CreateTriggerSkillV2{
	name = "#sgkgodluoyan_mark",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local current = room:getCurrent()
			if not (current and use.from and use.from:getSeat() == current:getSeat()
				and player:getSeat() == current:getSeat() and player:getPhase() == sgs.Player_Play) then return false end
			if not (player:getMark("&sgkgodluoyan") > 0 and player:getMark("luoyan_cardcount") < 3
				and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill) then return false end
			return skill:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("luoyan_cardcount") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			room:addPlayerMark(player, "luoyan_cardcount")
			if player:getMark("luoyan_cardcount") == 1 then
				if not player:isNude() then
					local cards = sgs.QList2Table(player:getCards("he"))
					local rc = cards[math.random(1, #cards)]
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sgkgodluoyan","")
					room:throwCard(rc, reason, nil)
				end
			elseif player:getMark("luoyan_cardcount") == 2 then
				room:loseHp(player, 1, true, player, "sgkgodluoyan")
			elseif player:getMark("luoyan_cardcount") == 3 then
				room:loseMaxHp(player)
			end
		elseif event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "luoyan_cardcount", 0)
		end
		return false
	end
}


sgkgoddaqiao:addSkill(sgkgodluoyan)


sgs.LoadTranslationTable{
    ["sgkgoddaqiao"] = "神大乔",
	["&sgkgoddaqiao"] = "神大乔",
	["#sgkgoddaqiao"] = "韶华易逝",
	["~sgkgoddaqiao"] = "伯符，我终于能再度与你相遇……",
	["sgkgodwangyue"] = "望月",
	["sgkgodwangyue_draw"] = "望月",
	["sgkgodwangyue_rec"] = "望月",
	["sgkgodwangyue_maxhp"] = "望月",
	[":sgkgodwangyue"] = "每回合每项限一次，当一名角色弃牌/失去体力/减体力上限后，你可以令另一名角色摸牌/回复等量体力/加等量体力上限。",
	["@wangyue_draw"] = "你可以发动“望月”令一名角色摸%src张牌",
	["@wangyue_rec"] = "你可以发动“望月”令一名角色回复%src点体力",
	["@wangyue_maxhp"] = "你可以发动“望月令一名角色增加%src点体力上限”",
	["$sgkgodwangyue1"] = "清风吹寒裘，寒月照易人。",
	["$sgkgodwangyue2"] = "斜月照帘帷，念君何时归？",
	["sgkgodluoyan"] = "落雁",
	[":sgkgodluoyan"] = "结束阶段，你可以选择一名角色；然后该角色于其出牌阶段使用第一/二/三张牌后，其随机弃置一张牌/失去1点体力/减1点体力上限，直到你下一次发动“落雁”。",
	["$sgkgodluoyan1"] = "秋风落黄叶，飘零独易居。",
	["$sgkgodluoyan2"] = "水影寒沾衣，独雁何处归？",
	["designer:sgkgoddaqiao"] =" 极略三国",
	["illustrator:sgkgoddaqiao"] = "极略三国",
	["cv:sgkgoddaqiao"] = "极略三国",
}


--神黄忠
sgkgodhuangzhong = sgs.General(extension, "sgkgodhuangzhong", "sy_god", 4, true)


--[[
	技能名：烈弓
	相关武将：神黄忠
	技能描述：每回合限一次（若你已受伤，则改为每回合限两次），你可以将任意张花色不同的手牌当作一张火【杀】使用，此牌无次数与距离限制且不能被响应；且若转化此
	牌的牌数：不小于二，你摸三张牌；不小于三，此牌伤害+1；为四，此牌造成伤害后，目标角色随机失去一个技能。
	引用：sgkgodliegong
]]--
sgkgodliegongvs = sgs.CreateViewAsSkillV2{
	name = "sgkgodliegong",
	n = 4,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if not player:isKongcheng() then
			local x = 1
			if player:isWounded() then x = 2 end
			return player:getMark("lg_fire_time") < x
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		local ids = request:getSelectedCardIds()
		if #ids >= 4 then return false end
		for _, id in sgs.qlist(ids) do
			local card = sgs.Sanguosha:getCard(id)
			if to_select:isEquipped() or card:getSuit() == to_select:getSuit() then return false end
		end
		local fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		fire:addSubcard(to_select:getEffectiveId())
		fire:deleteLater()
		return not player:isJilei(fire)
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() >= 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids == 0 then return nil end
		local lg_fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		for _, id in sgs.qlist(ids) do
			lg_fire:addSubcard(id)
		end
		lg_fire:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			lg_fire:setSkillInstanceId(instance_id)
			lg_fire:setActivationSkill("sgkgodliegong", instance_id)
			lg_fire:setSourceSkill("sgkgodliegong", instance_id)
		end
		return lg_fire
	end,
}

sgkgodliegong = sgs.CreateTriggerSkillV2{
	name = "sgkgodliegong",
	view_as_skill = sgkgodliegongvs,
	events = {sgs.EventPhaseChanging, sgs.TargetConfirmed, sgs.CardFinished, sgs.DamageCaused, sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive or player:getMark("lg_fire_time") <= 0 then return false end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("FireSlash")) then return false end
			if use.card:getSkillName() ~= skill:objectName() or use.card:subcardsLength() < 1 then return false end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("FireSlash")) then return false end
			if use.card:getSkillName() ~= skill:objectName() then return false end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if not (damage.card and (not damage.chain) and (not damage.transfer)
				and damage.card:getSkillName() == skill:objectName() and damage.card:subcardsLength() >= 3) then return false end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if not (damage.card and damage.card:getSkillName() == skill:objectName() and damage.damage > 0
				and damage.card:subcardsLength() >= 4 and damage.to and damage.to:isAlive()
				and damage.to:getSeat() ~= player:getSeat() and (not damage.transfer)) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			room:setPlayerMark(player, "lg_fire_time", 0)
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local n = use.card:subcardsLength()
			if n >= 1 then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#FireLiegong1"
				msg.card_str = use.card:toString()
				msg.arg = self:objectName()
				room:sendLog(msg)
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, t in sgs.qlist(use.to) do
					jink_table[index] = 0
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("FireSlash")) then return false end
			if use.card:getSkillName() ~= self:objectName() then return false end
			room:addPlayerMark(player, "lg_fire_time", 1)
			local n = use.card:subcardsLength()
			if n >= 2 then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#FireLiegong2"
				msg.card_str = use.card:toString()
				msg.arg = self:objectName()
				room:sendLog(msg)
				player:drawCards(3, self:objectName())
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and (not damage.chain) and (not damage.transfer) and damage.card:getSkillName() == self:objectName() then
				local n = damage.card:subcardsLength()
				if n >= 3 then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.type = "#FireLiegong3"
					msg.card_str = damage.card:toString()
					msg.arg = tostring(damage.damage)
					msg.arg2 = tostring(damage.damage + 1)
					room:sendLog(msg)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local to_lose = {}
			if not damage.to:getVisibleSkillList():isEmpty() then
				for _, _skill in sgs.qlist(damage.to:getVisibleSkillList()) do
					table.insert(to_lose, "-".._skill:objectName())
				end
			end
			if #to_lose > 0 then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#FireLiegong4"
				msg.card_str = damage.card:toString()
				msg.arg = self:objectName()
				msg.to:append(damage.to)
				room:sendLog(msg)
				room:handleAcquireDetachSkills(damage.to, to_lose[math.random(1, #to_lose)])
			end
		end
		return false
	end
}


sgkgodhuangzhong:addSkill(sgkgodliegong)


sgs.LoadTranslationTable{
    ["sgkgodhuangzhong"] = "神黄忠",
	["&sgkgodhuangzhong"] = "神黄忠",
	["#sgkgodhuangzhong"] = "气概天参",
	["~sgkgodhuangzhong"] = "终究敌不过这沧桑岁月……",
	["sgkgodliegong"] = "烈弓",
	[":sgkgodliegong"] = "每回合限一次（若你已受伤，则改为每回合限两次），你可以将任意张花色不同的手牌当作一张火【杀】使用，此牌无次数与距离限制且不能被响"..
	"应；且若转化此牌的牌数：不小于二，你摸三张牌；不小于三，此牌伤害+1；为四，此牌造成伤害后，目标角色随机失去一个技能。",
	["#FireLiegong1"] = "由于“%arg”的技能效果，%from 使用的 %card 不能被【<font color = 'yellow'><b>闪</b></font>】响应",
	["#FireLiegong2"] = "由于“%arg”的技能效果，%from 使用的 %card 在结算完毕后，%from摸 <font color = 'yellow'><b>3</b></font> 张牌",
	["#FireLiegong3"] = "由于“<font color = 'yellow'><b>烈弓</b></font>”的技能效果，%from 使用的 %card 造成的伤害从 %arg 点增加至 %arg2 点",
	["#FireLiegong4"] = "由于“%arg”的技能效果，%to 受到 %from 使用的 %card 造成的伤害后将随机失去1个武将技能",
	["$sgkgodliegong1"] = "烈弓神威，箭矢毙敌！",
	["$sgkgodliegong2"] = "鋷甲锵躯，肝胆俱裂！",
	["designer:sgkgodhuangzhong"] =" 极略三国",
	["illustrator:sgkgodhuangzhong"] = "极略三国",
	["cv:sgkgodhuangzhong"] = "极略三国",
}


--神小乔
sgkgodxiaoqiao = sgs.General(extension, "sgkgodxiaoqiao", "sy_god", 3, false)


--[[
	技能名：星舞
	相关武将：神小乔
	技能描述：游戏开始时，你可以令所有角色各获得一个“星舞”标记，然后你可以令所有角色各获得至多X个“星舞”标记（X为你的体力值）。一名角色的回合开始时，你可以弃
	置一张红桃手牌并选择一项：1.令该角色获得一个“星舞”标记；2.若其有“星舞”标记，移动其一个此标记。然后你可以令其失去以此法获得的所有技能，并重新获得等量的技
	能。当一名角色获得/失去“星舞”标记后，你令其回复/失去1点体力，随机获得/失去一个性别与其不同/相同的武将的技能。
	引用：sgkgodxingwu
]]--
local function getGenderSkills(gender, is_same, n)
	local gender_sk = {}  --初始化存放技能的table容器
	local room = sgs.Sanguosha:currentRoom()  --读取本局游戏的房间
	local all = sgs.Sanguosha:getLimitedGeneralNames()  --读取本游戏所有武将名称
	for _, pe in sgs.qlist(room:getPlayers()) do
		if pe:getGeneral() then
			if table.contains(all, pe:getGeneralName()) then table.removeOne(all, pe:getGeneralName()) end  --场上已有的武将（主将）全部排除
		end
		if pe:getGeneral2() then  --若为双将模式（奇怪，极略三国怎么也整若制？啊是我自己写的啊，那没事了，带娱没搞也不屑搞这出）
			if table.contains(all, pe:getGeneral2Name()) then table.removeOne(all, pe:getGeneral2Name()) end  --场上已有的武将（副将）全部排除
		end
	end
	local to_choose_names = {}  --初始化存放符合条件的武将名称的table容器
	if is_same == true then  --如果判定条件是“与XXX性别相同”，则载入所有同性武将的名称
		for _, _name in ipairs(all) do
			if gender == sgs.General_Sexless or gender == sgs.General_Neuter then  --十常侍被阉之前也是男的
				if sgs.Sanguosha:getGeneral(_name):getGender() == sgs.General_Male then
					table.insert(to_choose_names, _name)
				end
			else
				if sgs.Sanguosha:getGeneral(_name):getGender() == gender then
					table.insert(to_choose_names, _name)
				end
			end
		end
	elseif is_same == false then  --如果判定条件是“与XXX性别不同”，则载入所有异性武将的名称
		for _, _name in ipairs(all) do
			if gender == sgs.General_Sexless or gender == sgs.General_Neuter then
				if sgs.Sanguosha:getGeneral(_name):getGender() == sgs.General_Female then
					table.insert(to_choose_names, _name)
				end
			else
				if sgs.Sanguosha:getGeneral(_name):getGender() ~= gender then
					table.insert(to_choose_names, _name)
				end
			end
		end
	end
	if #to_choose_names > 0 then
		for _, name in ipairs(to_choose_names) do
			local general = sgs.Sanguosha:getGeneral(name)
			for _, _skill in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(gender_sk, _skill:objectName())
			end
		end
	end
	if type(n) == "number" then
		local output = {}
		for i = 1, n, 1 do
			local rskill = gender_sk[math.random(1, #gender_sk)]
			table.removeOne(gender_sk, rskill)
			table.insert(output, rskill)
			if #gender_sk == 0 then break end
		end
		return output
	elseif type(n) == "string" then
		if n == "all" then return gender_sk end
	end
end

local function getTargetGenderSkills(target)
	local target_skills = {}
	local all = sgs.Sanguosha:getLimitedGeneralNames()
	local same_skills = {}
	for _, name in ipairs(all) do
		local gen = sgs.Sanguosha:getGeneral(name)
		if target:getGender() == sgs.General_Neuter or target:getGender() == sgs.General_Sexless then
			if gen:getGender() == sgs.General_Male or target:getGender() == gen:getGender() then
				for _, _sk in sgs.qlist(gen:getSkillList()) do
					table.insert(same_skills, _sk:objectName())
				end
			end
		else
			if gen:getGender() == target:getGender() then
				for _, _sk in sgs.qlist(gen:getSkillList()) do
					table.insert(same_skills, _sk:objectName())
				end
			end
		end
	end
	for _, sk in sgs.qlist(target:getVisibleSkillList()) do
		if table.contains(same_skills, sk:objectName()) then table.insert(target_skills, sk:objectName()) end
	end
	same_skills = {}
	all = nil
	return target_skills
end

sgkgodxingwu = sgs.CreateTriggerSkillV2{
	name = "sgkgodxingwu",
	events = {sgs.GameStart, sgs.MarkChanged, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.GameStart then
			return skill:objectName()
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name ~= "&"..skill:objectName() then return false end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return false end
		end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, p:objectName())
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				for _, t in sgs.qlist(room:getAlivePlayers()) do
					room:doAnimate(1, player:objectName(), t:objectName())
					t:gainMark("&"..self:objectName())
				end
				for a = 1, player:getHp() do
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName(), 2)
						for _, t in sgs.qlist(room:getAlivePlayers()) do
							t:gainMark("&"..self:objectName())
						end
					else
						break
					end
				end
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&"..self:objectName() then
				if mark.gain > 0 then
					if mark.who:isWounded() then
						local recover = sgs.RecoverStruct()
						recover.recover = 1
						room:recover(mark.who, recover)
					end
					local skills = getGenderSkills(mark.who:getGender(), false, 1)
					if #skills > 0 then
						room:handleAcquireDetachSkills(mark.who, skills[1])
						local xingwu_rec = mark.who:getTag("xingwu_rec"):toString():split("+")
						table.insert(xingwu_rec, skills[1])
						mark.who:setTag("xingwu_rec", sgs.QVariant(table.concat(xingwu_rec, "+")))
					end
				elseif mark.gain < 0 then
					room:loseHp(mark.who, 1, true, nil, self:objectName())
					local to_lose = getTargetGenderSkills(mark.who)
					if #to_lose > 0 then room:handleAcquireDetachSkills(mark.who, "-"..to_lose[math.random(1, #to_lose)]) end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local target = ctx.invoker
			if target and target:getPhase() == sgs.Player_RoundStart then
				local q = sgs.QVariant()
				q:setValue(target)
				local xiaoqiao = player
				local card = room:askForCard(xiaoqiao, ".|heart", "@xingwu_heart:"..target:objectName(), q, sgs.Card_MethodNone)
				if card then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, xiaoqiao:objectName(), self:objectName(), "")
					room:throwCard(card, reason, nil)
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:doAnimate(1, xiaoqiao:objectName(), target:objectName())
					local items = {"addxingwumark"}
					if target:getMark("&"..self:objectName()) > 0 then table.insert(items, "transferxingwumark") end
					local choice = room:askForChoice(xiaoqiao, self:objectName(), table.concat(items, "+"), q)
					if choice == "addxingwumark" then
						target:gainMark("&"..self:objectName())
					else
						local toget = room:askForPlayerChosen(xiaoqiao, room:getOtherPlayers(target), self:objectName())
						target:loseMark("&"..self:objectName())
						toget:gainMark("&"..self:objectName())
					end
					local xingwu_skills = target:getTag("xingwu_rec"):toString():split("+")
					if #xingwu_skills > 0 and target:isAlive() then
						local prompt = string.format("xingwu_exchange_skills:%s:", target:objectName())
						if xiaoqiao:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
							local new_skills = getGenderSkills(target:getGender(), false, #xingwu_skills)
							room:handleAcquireDetachSkills(target, "-"..table.concat(xingwu_skills, "|-").."|"..table.concat(new_skills, "|"))
							target:setTag("xingwu_rec", sgs.QVariant(table.concat(new_skills, "+")))
						end
					end
				end
			end
		end
		return false
	end
}


sgkgodxiaoqiao:addSkill(sgkgodxingwu)


--[[
	技能名：沉鱼
	相关武将：神小乔
	技能描述：锁定技，结束阶段或当你受到伤害后，你获得其他角色手牌中的所有红桃牌。
	引用：sgkgodchenyu
]]--
sgkgodchenyu = sgs.CreateTriggerSkillV2{
	name = "sgkgodchenyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_Finish then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) or event == sgs.Damaged then
			local hearts = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				local _heart = 0
				if not pe:isKongcheng() then
					for _, c in sgs.qlist(pe:getHandcards()) do
						if c:getSuit() == sgs.Card_Heart and player:canGet(pe, c:getEffectiveId()) then
							_heart = _heart + 1
							break
						end
					end
				end
				if _heart > 0 then hearts:append(pe) end
			end
			if hearts:isEmpty() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			for _, h in sgs.qlist(hearts) do
				room:doAnimate(1, player:objectName(), h:objectName())
			end
			for _, h in sgs.qlist(hearts) do
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				if not h:isKongcheng() then
					for _, c in sgs.qlist(h:getHandcards()) do
						if c:getSuit() == sgs.Card_Heart and player:canGet(h, c:getEffectiveId()) then jink:addSubcard(c) end
					end
				end
				if jink:subcardsLength() > 0 then room:obtainCard(player, jink, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), h:objectName(), "sgkgodchenyu", ""), false) end
				jink:deleteLater()
			end
		end
		return false
	end
}


sgkgodxiaoqiao:addSkill(sgkgodchenyu)


sgs.LoadTranslationTable{
    ["sgkgodxiaoqiao"] = "神小乔",
	["&sgkgodxiaoqiao"] = "神小乔",
	["#sgkgodxiaoqiao"] = "星河共舞",
	["~sgkgodxiaoqiao"] = "追随公瑾，此生~无悔~",
	["sgkgodxingwu"] = "星舞",
	[":sgkgodxingwu"] = "游戏开始时，你可以令所有角色各获得一个“星舞”标记，然后你可以令所有角色各获得至多X个“星舞”标记（X为你的体力值）。一名角色的回合开始时，你可"..
	"以弃置一张红桃手牌并选择一项：1.令该角色获得一个“星舞”标记；2.若其有“星舞”标记，移动其一个此标记。然后你可以令其失去以此法获得的所有技能，并重新获得等量的技能。"..
	"当一名角色获得/失去“星舞”标记后，你令其回复/失去1点体力，随机获得/失去一个性别与其不同/相同的武将的技能。",
	["@xingwu_heart"] = "你可以弃置一张红桃牌对%src发动【星舞】，令其获得“星舞”标记或转移“星舞”标记",
	["addxingwumark"] = "令其获得1个“星舞”标记",
	["transferxingwumark"] = "将其1个“星舞”标记移至其他角色处",
	["sgkgodxingwu:xingwu_exchange_skills"] = "是否令%src失去所有因“星舞”获得的技能，重新获得等量的异性技能？",
	["$sgkgodxingwu1"] = "剑影蹁跹，共舞星河。",
	["$sgkgodxingwu2"] = "舞步轻盈，星光闪耀！",
	["sgkgodchenyu"] = "沉鱼",
	[":sgkgodchenyu"] = "锁定技，结束阶段或当你受到伤害后，你获得其他角色手牌中的所有红桃牌。",
	["$sgkgodchenyu1"] = "回眸一笑，千娇媚~",
	["$sgkgodchenyu2"] = "东吴多佳人，貌美颜如玉。",
	["designer:sgkgodxiaoqiao"] =" 极略三国",
	["illustrator:sgkgodxiaoqiao"] = "极略三国",
	["cv:sgkgodxiaoqiao"] = "极略三国",
}


--神曹仁
sgkgodcaoren = sgs.General(extension, "sgkgodcaoren", "sy_god", 8, true)


--[[
	技能名：八门
	相关武将：神曹仁
	技能描述：锁定技，出牌阶段开始时，你弃置所有手牌并从牌堆中获得八张牌名各不相同的牌；然后若你以此法获得的牌数少于八张，你可以对一名其他角色造成X点雷电伤
	害（X为你少摸的牌数）。
	引用：sgkgodbamen
]]--
sgkgodbamen = sgs.CreateTriggerSkillV2{
	name = "sgkgodbamen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Play then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Play then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			if player:getHandcardNum() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				for _, c in sgs.qlist(player:getHandcards()) do
					dummy:addSubcard(c)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(),"")
				room:throwCard(dummy, reason, nil)
				dummy:deleteLater()
			end
			local bamen_names = {}
			local bamen = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			if not room:getDrawPile():isEmpty() then
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if not table.contains(bamen_names, card:objectName()) then
						table.insert(bamen_names, card:objectName())
						bamen:addSubcard(card)
					end
					if #bamen_names == 8 then break end
				end
			end
			room:obtainCard(player, bamen, "sgkgodbamen")
			bamen:deleteLater()
			if #bamen_names < 8 then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@bamen-tar:"..tostring(8-#bamen_names), true, true)
				if target then
					room:doAnimate(1, player:objectName(), target:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 8-#bamen_names, sgs.DamageStruct_Thunder))
					bamen_names = {}
				end
			end
		end
		return false
	end
}


sgkgodcaoren:addSkill(sgkgodbamen)


--[[
	技能名：孤城
	相关武将：神曹仁
	技能描述：锁定技，当其他角色使用基本牌或普通锦囊牌指定你为目标后，若你本局内未使用过此牌名的牌，此牌对你无效。
	引用：sgkgodgucheng
]]--
sgkgodgucheng = sgs.CreateTriggerSkillV2{
	name = "sgkgodgucheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.from and use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())) then return false end
		if event == sgs.CardUsed then
			if use.from:objectName() ~= player:objectName() then return false end
		elseif event == sgs.TargetConfirmed then
			if use.from:objectName() == player:objectName() or not use.to:contains(player) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card then
				if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
					local gc = player:property("SkillDescriptionRecord_sgkgodgucheng"):toString():split("+")
					if not table.contains(gc, use.card:objectName()) then
						table.insert(gc, use.card:objectName())
						room:setPlayerProperty(player, "SkillDescriptionRecord_sgkgodgucheng", sgs.QVariant(table.concat(gc, "+")))
					end
					if #gc > 0 then
						local tks = {}
						for _, pn in sgs.list(gc) do
							table.insert(tks, pn)
							table.insert(tks, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodgucheng", "%arg1", table.concat(tks, "+"))
						room:changeTranslation(player, "sgkgodgucheng")
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() ~= player:objectName() and use.card and use.to:contains(player) then
				if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
					local gc = player:property("SkillDescriptionRecord_sgkgodgucheng"):toString():split("+")
					if not table.contains(gc, use.card:objectName()) then
						local msg = sgs.LogMessage()
						msg.from = player
						msg.to:append(use.from)
						msg.arg = self:objectName()
						msg.card_str = use.card:toString()
						msg.arg2 = use.card:objectName()
						msg.type = "#GuchengNull"
						room:sendLog(msg)
						room:broadcastSkillInvoke(self:objectName())
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
		return false
	end
}


sgkgodcaoren:addSkill(sgkgodgucheng)


sgs.LoadTranslationTable{
    ["sgkgodcaoren"] = "神曹仁",
	["&sgkgodcaoren"] = "神曹仁",
	["#sgkgodcaoren"] = "樊城天堑",
	["~sgkgodcaoren"] = "中计兵败，吾愧对孟德！",
	["sgkgodbamen"] = "八门",
	[":sgkgodbamen"] = "锁定技，出牌阶段开始时，你弃置所有手牌并从牌堆中获得八张牌名各不相同的牌；然后若你以此法获得的牌数少于八张，你可以对一名其他角色造成X点雷电伤害（X为你少摸的牌数）。",
	["@bamen-tar"] = "【八门】你因牌堆缺少%src种牌名少摸了%src张牌，你可以对一名其他角色造成%src点雷电伤害",
	["$sgkgodbamen1"] = "整装列队，结八门金锁之阵！",
	["$sgkgodbamen2"] = "哼！汝可识吾阵势？",
	["sgkgodgucheng"] = "孤城",
	[":sgkgodgucheng"] = "锁定技，当其他角色使用基本牌或普通锦囊牌指定你为目标后，若你本局内未使用过此牌名的牌，此牌对你无效。",
	[":sgkgodgucheng1"] = "锁定技，当其他角色使用基本牌或普通锦囊牌指定你为目标后，若你本局内未使用过此牌名的牌，此牌对你无效。\
	<font color=\"#9400D3\">“孤城”记录的已使用过的牌名：%arg1</font>",
	["$sgkgodgucheng1"] = "孤城临险，需坚壁清野！",
	["$sgkgodgucheng2"] = "众将一心，严防死守！",
	["#GuchengNull"] = "%from 的“%arg”被触发，由于 %from 没有使用过名称为 %arg2 的牌，%card 对 %from 无效",
	["designer:sgkgodcaoren"] =" 极略三国",
	["illustrator:sgkgodcaoren"] = "极略三国",
	["cv:sgkgodcaoren"] = "极略三国",
}


--神曹丕
sgkgodcaopi = sgs.General(extension, "sgkgodcaopi", "sy_god", 3, true)


--[[
	技能名：储元
	相关武将：神曹丕
	技能描述：当一名角色使用的【杀】/【闪】结算后，你可以摸两张牌并将一张黑色/红色牌置于武将牌上，称为“储”。你每有两张颜色不同的“储”，你的摸牌数
	与手牌上限便+1。
	引用：sgkgodchuyuan, sgkgodchuyuanMax
]]--
sgkgodchuyuan = sgs.CreateTriggerSkillV2{
	name = "sgkgodchuyuan",
	events = {sgs.CardFinished, sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card or use.card:isKindOf("SkillCard") then return false end
			if not (use.card:isKindOf("Slash") or use.card:isKindOf("Jink")) then return false end
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:getMark("sgkgoddengji") == 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #names == 0 then return false end
			return table.concat(names, "|"), table.concat(owners, "|")
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Draw or player:getMark("sgkgoddengji") ~= 0 then return false end
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" or player:getPile("sgkgodchu"):isEmpty() then return false end
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then return false end
			local caopi = player
			if use.card:isKindOf("Slash") then
				if caopi:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					caopi:drawCards(2, self:objectName())
					local blackone = room:askForCard(caopi, ".|black|.|.", "@sgkgodchuyuan-black", data, sgs.Card_MethodNone)
					if blackone then caopi:addToPile("sgkgodchu", blackone, true) end
				end
			elseif use.card:isKindOf("Jink") then
				if caopi:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					caopi:drawCards(2, self:objectName())
					local redone = room:askForCard(caopi, ".|red|.|.", "@sgkgodchuyuan-red", data, sgs.Card_MethodNone)
					if redone then caopi:addToPile("sgkgodchu", redone, true) end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and player:getMark("sgkgoddengji") == 0 then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				if player:getPile("sgkgodchu"):isEmpty() then return false end
				local redc, blackc, dummy = 0, 0
				for _, id in sgs.qlist(player:getPile("sgkgodchu")) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isBlack() then
						blackc = blackc + 1
					elseif card:isRed() then
						redc = redc + 1
					end
				end
				draw.num = draw.num + math.min(blackc, redc)
				data:setValue(draw)
			end
		end
		return false
	end
}

sgkgodchuyuanMax = sgs.CreateMaxCardsSkillV2{
	name = "#sgkgodchuyuanMax",
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if target and target:hasSkill("sgkgodchuyuan") and not target:getPile("sgkgodchu"):isEmpty() and target:getMark("sgkgoddengji") == 0 then
			local redc, blackc, dummy = 0, 0
			for _, id in sgs.qlist(target:getPile("sgkgodchu")) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isBlack() then
					blackc = blackc + 1
				elseif card:isRed() then
					redc = redc + 1
				end
			end
			local n = math.min(blackc, redc)
			if n ~= 0 then return n end
		end
		return false
	end
}


sgkgodcaopi:addSkill(sgkgodchuyuan)
extension:insertRelatedSkills("sgkgodchuyuan", "#sgkgodchuyuanMax")


--[[
	技能名：登极
	相关武将：神曹丕
	技能描述：觉醒技，准备阶段，若你拥有至少五张“储”且数量为奇数，你令“储元”失效并获得所有“储”；若你以此法获得的黑色/红色牌较多，你获得技能“极权”/“仁政”，
	你每以此法获得两张颜色不同的牌，你随机获得一个已拥有的君主的技能。
	引用：sgkgoddengji, sgkgoddengjiFake
]]--
--随机选取N个不同元素
function randomGetN(table, count)
	local new = {}
	for i = 1, math.min(count, #table) do
		local ri = math.random(i, #table)
		local tmp = table[i]
		table[i] = table[ri]
		table[ri] = tmp
	end
	for i = 1, count do
		table.insert(new, table[i])
	end
	return new
end

local function getDengjiLordSkills(skill_num)
	local skills = {}
	local to_names = {}
	local room = sgs.Sanguosha:currentRoom()
	local lords = {
	--[魏国]--
	"caocao", "caopi", "caorui", "caofang", "caomao",
	--[蜀国]--
	"liubei", "liushan", "liuchen", "menghuo",
	--[吴国]--
	"sunjian", "sunce", "sunquan", "sunliang", "sunxiu", "sunhao",
	--[群雄]--
	"zhangjiao", "dongzhuo", "yuanshao", "lvbu", "yuanshu", "liubiao", "liuyao", "liuyan", "liuzhang", "gongsunzan",
	--[晋朝]--
	"simayi", "simashi", "simazhao", "simayan"
	}
	local all = sgs.Sanguosha:getLimitedGeneralNames()
	for _, _name in ipairs(all) do
		for _, _lord in ipairs(lords) do
			if string.find(_name, _lord) then table.insert(to_names, _name) end
		end
	end
	for _, _l in ipairs(to_names) do
		local al = sgs.Sanguosha:getGeneral(_l)
		for _, sk in sgs.qlist(al:getVisibleSkillList()) do
			table.insert(skills, sk:objectName())
		end
	end
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		for _, _sk in sgs.qlist(t:getVisibleSkillList()) do
			if table.contains(skills, _sk:objectName()) then table.removeOne(skills, _sk:objectName()) end
		end
	end
	if table.contains(skills, "sgkgodchuyuan") then table.removeOne(skills, "sgkgodchuyuan") end
	if #skills > 0 then
		local output_table = randomGetN(skills, skill_num)
		return output_table
	else
		return {}
	end
end

sgkgoddengji = sgs.CreateTriggerSkillV2{
	name = "sgkgoddengji",
	frequency = sgs.Skill_Wake,
	waked_skills = "sgkgodrenzheng,sgkgodjiquan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(skill:objectName()) >= 1 then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if (player:getPile("sgkgodchu"):length() % 2 == 1 and player:getPile("sgkgodchu"):length() >= 5) or player:canWake(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local msg = sgs.LogMessage()
			msg.from = player
			msg.type = "#sgkgoddengjiWake"
			msg.arg = "sgkgodchu"
			msg.arg2 = tostring(player:getPile("sgkgodchu"):length())
			msg.arg3 = self:objectName()
			room:sendLog(msg)
			room:addPlayerMark(player, self:objectName())
			room:addPlayerMark(player, "Qingchengsgkgodchuyuan")
			room:doSuperLightbox("sgkgodcaopi", "sgkgoddengji")
			local redc, blackc, dummy = 0, 0, sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			for _, id in sgs.qlist(player:getPile("sgkgodchu")) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isBlack() then
					blackc = blackc + 1
				elseif card:isRed() then
					redc = redc + 1
				end
				dummy:addSubcard(id)
			end
			if dummy:subcardsLength() > 0 then
				room:obtainCard(player, dummy, "sgkgoddengji")
				local _toget = math.min(blackc, redc)
				local lord_skills = getDengjiLordSkills(_toget)
				if redc > blackc then
					table.insert(lord_skills, "sgkgodrenzheng")
				elseif redc < blackc then
					table.insert(lord_skills, "sgkgodjiquan")
				end
				room:handleAcquireDetachSkills(player, table.concat(lord_skills, "|"))
			end
			dummy:deleteLater()
		end
		return false
	end
}


sgkgodcaopi:addSkill(sgkgoddengji)


sgs.LoadTranslationTable{
    ["sgkgodcaopi"] = "神曹丕",
	["&sgkgodcaopi"] = "神曹丕",
	["#sgkgodcaopi"] = "代汉而立",
	["~sgkgodcaopi"] = "朕的盛世……咳、咳……",
	["sgkgodchuyuan"] = "储元",
	["sgkgodchu"] = "储",
	[":sgkgodchuyuan"] = "当一名角色使用的【杀】/【闪】结算后，你可以摸两张牌并将一张黑色/红色牌置于武将牌上，称为“储”。你每有两张颜色不同的“储”，你的"..
	"摸牌数与手牌上限便+1。",
	["$sgkgodchuyuan1"] = "储君之位，势在必得！",
	["$sgkgodchuyuan2"] = "礼嗣之争，是我之胜！",
	["@sgkgodchuyuan-black"] = "你可以选择一张黑色牌，然后将之作为“储”置于你的武将牌上。",
	["@sgkgodchuyuan-red"] = "你可以选择一张红色牌，然后将之作为“储”置于你的武将牌上。",
	["sgkgoddengji"] = "登极",
	[":sgkgoddengji"] = "觉醒技，准备阶段，若你拥有至少五张“储”且数量为奇数，你令“储元”失效并获得所有“储”；若你以此法获得的黑色/红色牌较多，你获得技能“极"..
	"权”/“仁政”，你每以此法获得两张颜色不同的牌，你随机获得一个已拥有的君主的技能。",
	["$sgkgoddengji1"] = "魏武霸业，由孤继承！", 
	["$sgkgoddengji2"] = "大魏皇帝，四海称臣！",
	["#sgkgoddengjiWake"] = "%from 的“%arg”数量为 %arg2 ，触发“%arg3”觉醒",
	["designer:sgkgodcaopi"] =" 极略三国",
	["illustrator:sgkgodcaopi"] = "极略三国",
	["cv:sgkgodcaopi"] = "极略三国",
}


--神庞统
sgkgodpangtong = sgs.General(extension, "sgkgodpangtong", "sy_god", 3, true)


--[[
	技能名：栖凤
	相关武将：神庞统
	技能描述：锁定技，当你进入濒死状态时，你减1点体力上限，回复体力至1点，摸0张牌，然后你对一名其他角色造成0点火焰伤害。
	当一名角色完成上策/中策/下策后，本技能中的造成伤害值/回复体力值/摸牌数+1。
	引用：sgkgodqifeng
]]--
sgkgodqifeng = sgs.CreateTriggerSkillV2{
	name = "sgkgodqifeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	can_trigger = function(skill, event, room, player, data)
		local dying = data:toDying()
		if not (dying.who and dying.who:objectName() == player:objectName()) then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local dying = data:toDying()
		if dying.who:hasSkill(self:objectName()) and dying.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			local qifeng_draw = player:getTag("qifeng_draw"):toInt()
			local qifeng_rec = player:getTag("qifeng_rec"):toInt()
			local qifeng_fire = player:getTag("qifeng_fire"):toInt()
			room:loseMaxHp(player)
			room:doSuperLightbox("sgkgodpangtong", "sgkgodqifeng")
			local rec = sgs.RecoverStruct()
			rec.who = player
			rec.recover = 1 + qifeng_rec - player:getHp()
			room:recover(player, rec)
			if qifeng_draw > 0 then player:drawCards(qifeng_draw, self:objectName()) end
			if qifeng_fire > 0 then
				local victim = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@qifeng_firedamage:"..tostring(qifeng_fire))
				room:doAnimate(1, player:objectName(), victim:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, victim, qifeng_fire, sgs.DamageStruct_Fire))
			end
		end
		return false
	end
}


sgkgodpangtong:addSkill(sgkgodqifeng)


--[[
	技能名：论策
	相关武将：神庞统
	技能描述：每轮开始时，你可以令一名角色获得一个场上没有的计策。然后当一名角色完成计策后，你加1点体力上限并回复1点体力。
	引用：sgkgodlunce, sgkgodluncexia, sgkgodluncezhong, sgkgodlunceshang
]]--
local function getLunceCondition(level)
	local s1, s2, s3 = {"lunce_shang_suit", "lunce_shang_type"}, {"lunce_shang_acquireskill", "lunce_shang_loseskill"}, {"lunce_shang_causedying", "lunce_shang_dying"}
	local z1, z2, z3 = {"lunce_zhong_2spade", "lunce_zhong_2heart"}, {"lunce_zhong_slash2dmg", "lunce_zhong_trick2dmg"}, {"lunce_zhong_2nature", "lunce_zhong_2rec"}
	local x1, x2, x3 = {"lunce_xia_blackcard", "lunce_xia_redcard"}, {"lunce_xia_slash", "lunce_xia_trick"}, {"lunce_xia_damage", "lunce_xia_recover"}
	local condition = {}
	if level == "sgkgodshangce" then
		table.insert(condition, s1[math.random(1, 2)])
		table.insert(condition, s2[math.random(1, 2)])
		table.insert(condition, s3[math.random(1, 2)])
	elseif level == "sgkgodzhongce" then
		table.insert(condition, z1[math.random(1, 2)])
		table.insert(condition, z2[math.random(1, 2)])
		table.insert(condition, z3[math.random(1, 2)])
	elseif level == "sgkgodxiace" then
		table.insert(condition, x1[math.random(1, 2)])
		table.insert(condition, x2[math.random(1, 2)])
		table.insert(condition, x3[math.random(1, 2)])
	end
	return condition
end

local function getLunceEffect(level)  --备注：上中下三策的执行效果的第三条总是负面效果，第二条有50%概率为负面效果
	local s = {"lunce_shang_gainsamekingdomskill", "lunce_shang_1maxhp1recover", "lunce_shang_loserandomskill", "lunce_shang_throwallcards"}
	local z = {"lunce_zhong_drawphase", "lunce_zhong_slashtime", "lunce_zhong_turnover", "lunce_zhong_losemaxhp"}
	local x = {"lunce_xia_draw2", "lunce_xia_recover1", "lunce_xia_throw2", "lunce_xia_firedamage"}
	local l_effect = {}
	if level == "sgkgodshangce" then
		for _, _effect in ipairs(s) do
			table.insert(l_effect, _effect)
		end
		table.remove(l_effect, math.random(1, 4))
	elseif level == "sgkgodzhongce" then
		for _, _effect in ipairs(z) do
			table.insert(l_effect, _effect)
		end
		table.remove(l_effect, math.random(1, 4))
	elseif level == "sgkgodxiace" then
		for _, _effect in ipairs(x) do
			table.insert(l_effect, _effect)
		end
		table.remove(l_effect, math.random(1, 4))
	end
	return l_effect
end

local function lunceVoice(strategy)
	if strategy == "sgkgodshangce" then
		return 3
	elseif strategy == "sgkgodzhongce" then
		return 2
	elseif strategy == "sgkgodxiace" then
		return 1
	end
end

local function updateLunce(player)
	local room = sgs.Sanguosha:currentRoom()
	local worst, mid, best = {}, {}, {}
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getMark("&sgkgodxiace") > 0 then
			worst = pe:getTag("sgkgodxiace"):toString():split("+")
			break
		end
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getMark("&sgkgodzhongce") > 0 then
			mid = pe:getTag("sgkgodzhongce"):toString():split("+")
			break
		end
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getMark("&sgkgodshangce") > 0 then
			best = pe:getTag("sgkgodshangce"):toString():split("+")
			break
		end
	end
	if #worst > 0 then
		local worst_table = {"when_one", worst[1], "when_comma", "then_one", worst[2], "then_end"}
		player:setSkillDescriptionSwap("sgkgodlunce", "%worst", table.concat(worst_table, "+"))
	else
		player:setSkillDescriptionSwap("sgkgodlunce", "%worst", "")
	end
	if #mid > 0 then
		local mid_table = {"when_one", mid[1], "when_comma", "then_one", mid[2], "then_end"}
		player:setSkillDescriptionSwap("sgkgodlunce", "%mid", table.concat(mid_table, "+"))
	else
		player:setSkillDescriptionSwap("sgkgodlunce", "%mid", "")
	end
	if #best > 0 then
		local best_table = {"when_one", best[1], "when_comma", "then_one", best[2], "then_end"}
		player:setSkillDescriptionSwap("sgkgodlunce", "%best", table.concat(best_table, "+"))
	else
		player:setSkillDescriptionSwap("sgkgodlunce", "%best", "")
	end
	room:changeTranslation(player, "sgkgodlunce")
end

local function updateQifeng(pangtong)
	local room = sgs.Sanguosha:currentRoom()
	local qifeng_draw = pangtong:getTag("qifeng_draw"):toInt()  --完成下策，“栖凤”复活后摸牌数+1
	local qifeng_rec = pangtong:getTag("qifeng_rec"):toInt()  --完成中策，“栖凤”复活后回复体力量+1
	local qifeng_fire = pangtong:getTag("qifeng_fire"):toInt()  --完成上策，“栖凤”复活后造成火焰伤害+1
	pangtong:setSkillDescriptionSwap("sgkgodqifeng", "%arg1", qifeng_draw)
	pangtong:setSkillDescriptionSwap("sgkgodqifeng", "%arg2", 1+qifeng_rec)
	pangtong:setSkillDescriptionSwap("sgkgodqifeng", "%arg3", qifeng_fire)
	room:changeTranslation(pangtong, "sgkgodqifeng")
end

function getOneKingdomSkills(kingdom, n)
	local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
	local room = sgs.Sanguosha:currentRoom()
	local selected = {}
	local skills = {}
	local output_table = {}
	for _, _name in ipairs(all_generals) do
		local general = sgs.Sanguosha:getGeneral(_name)
		if general:getKingdom() == kingdom then table.insert(selected, _name) end
	end
	for i = 1, #selected, 1 do
		local general = sgs.Sanguosha:getGeneral(selected[i])
		if general ~= nil then
			for _, _skill in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(skills, _skill:objectName())
			end
		end
	end
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		for _, _skill in sgs.qlist(t:getVisibleSkillList()) do
			if table.contains(skills, _skill:objectName()) then table.removeOne(skills, _skill:objectName()) end
		end
	end
	if #skills > 0 then
		local k = 0
		while k < n do
			local s = math.random(1, #skills)
			table.insert(output_table, skills[s])
			table.removeOne(skills, skills[s])
			k = k + 1
			if #skills == 0 then break end
		end
		if #output_table > 0 then
			return output_table
		else
			return {}
		end
	else
		return {}
	end
end

local function doLunceEffect(target, effect)
	local room = sgs.Sanguosha:currentRoom()
	if effect == "lunce_xia_draw2" then
		room:setPlayerMark(target, "&sgkgodxiace", 0)
		target:drawCards(2, "sgkgodlunce")
	elseif effect == "lunce_xia_recover1" then
		room:setPlayerMark(target, "&sgkgodxiace", 0)
		if target:isWounded() then
			local rec = sgs.RecoverStruct()
			rec.who = target
			rec.recover = 1
			room:recover(target, rec)
		end
	elseif effect == "lunce_xia_throw2" then
		room:setPlayerMark(target, "&sgkgodxiace", 0)
		local ids = target:forceToDiscard(2, true, true)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		dummy:deleteLater()
		dummy:addSubcards(ids)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, target:objectName(), "sgkgodlunce", "")
		room:throwCard(dummy, reason, nil)
		dummy:deleteLater()
	elseif effect == "lunce_xia_firedamage" then
		room:setPlayerMark(target, "&sgkgodxiace", 0)
		room:damage(sgs.DamageStruct("sgkgodlunce", nil, target, 1, sgs.DamageStruct_Fire))
	elseif effect == "lunce_zhong_drawphase" then
		room:setPlayerMark(target, "&sgkgodzhongce", 0)
		room:addPlayerMark(target, "hunlie_global_draw")
	elseif effect == "lunce_zhong_slashtime" then
		room:setPlayerMark(target, "&sgkgodzhongce", 0)
		room:addPlayerMark(target, "hunlie_global_slashtime")
	elseif effect == "lunce_zhong_turnover" then
		room:setPlayerMark(target, "&sgkgodzhongce", 0)
		target:turnOver()
	elseif effect == "lunce_zhong_losemaxhp" then
		room:setPlayerMark(target, "&sgkgodzhongce", 0)
		room:loseMaxHp(target)
	elseif effect == "lunce_shang_gainsamekingdomskill" then
		room:setPlayerMark(target, "&sgkgodshangce", 0)
		local skill = getOneKingdomSkills(target:getKingdom(), 1)
		room:handleAcquireDetachSkills(target, skill[1])
	elseif effect == "lunce_shang_1maxhp1recover" then
		room:setPlayerMark(target, "&sgkgodshangce", 0)
		room:gainMaxHp(target)
		if target:isWounded() then
			local rec = sgs.RecoverStruct()
			rec.who = target
			rec.recover = 1
			room:recover(target, rec)
		end
	elseif effect == "lunce_shang_loserandomskill" then
		room:setPlayerMark(target, "&sgkgodshangce", 0)
		local skills = {}
		for _, skill in sgs.qlist(target:getVisibleSkillList()) do
			table.insert(skills, skill:objectName())
		end
		room:handleAcquireDetachSkills(target, "-"..skills[math.random(1, #skills)])
	elseif effect == "lunce_shang_throwallcards" then
		room:setPlayerMark(target, "&sgkgodshangce", 0)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		dummy:deleteLater()
		dummy:addSubcards(target:getCards("hej"))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, target:objectName(), "sgkgodlunce", "")
		room:throwCard(dummy, reason, nil)
		dummy:deleteLater()
	end
end

local function finishStrategy(player, strategy)
	local room = sgs.Sanguosha:currentRoom()
	local str = player:getTag(strategy):toString():split("+")
	room:broadcastSkillInvoke("sgkgodlunce", lunceVoice(strategy))
	local msg1 = sgs.LogMessage()
	msg1.type = "#lunceFinish"
	msg1.from = player
	msg1.arg = strategy
	msg1.arg2 = str[1]
	msg1.arg3 = str[2]
	room:sendLog(msg1)
	doLunceEffect(player, str[2])
	if not room:findPlayerBySkillName("sgkgodlunce") then return false end
	local pt = room:findPlayerBySkillName("sgkgodlunce")
	local msg2 = sgs.LogMessage()
	msg2.type = "#lunceFinishPangtong"
	msg2.from = pt
	msg2.to:append(player)
	msg2.arg = "sgkgodlunce"
	msg2.arg2 = strategy
	msg2.arg3 = "sgkgodqifeng"
	room:sendLog(msg2)
	room:gainMaxHp(pt)
	if pt:isWounded() then
		local rec = sgs.RecoverStruct()
		rec.who = pt
		rec.recover = 1
		room:recover(pt, rec)
	end
	player:removeTag(strategy)
	if strategy == "sgkgodxiace" then
		local qifeng_draw = pt:getTag("qifeng_draw"):toInt()
		qifeng_draw = qifeng_draw + 1
		pt:setTag("qifeng_draw", sgs.QVariant(qifeng_draw))
	elseif strategy == "sgkgodzhongce" then
		local qifeng_rec = pt:getTag("qifeng_rec"):toInt()
		qifeng_rec = qifeng_rec + 1
		pt:setTag("qifeng_rec", sgs.QVariant(qifeng_rec))
	elseif strategy == "sgkgodshangce" then
		local qifeng_fire = pt:getTag("qifeng_fire"):toInt()
		qifeng_fire = qifeng_fire + 1
		pt:setTag("qifeng_fire", sgs.QVariant(qifeng_fire))
	end
	updateLunce(pt)
	updateQifeng(pt)
end

sgkgodlunce = sgs.CreateTriggerSkillV2{
	name = "sgkgodlunce",
	events = {sgs.RoundStart},
	can_trigger = function(skill, event, room, player, data)
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local x, z, s = 0, 0, 0
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if t:getMark("&sgkgodxiace") > 0 then x = x + 1 end
			if t:getMark("&sgkgodzhongce") > 0 then z = z + 1 end
			if t:getMark("&sgkgodshangce") > 0 then s = s + 1 end
		end
		if x * z * s > 0 then return false end
		local t = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@lunce-target", true, true)
		if t then
			local st = {}
			if x == 0 then table.insert(st, "sgkgodxiace") end
			if z == 0 then table.insert(st, "sgkgodzhongce") end
			if s == 0 then table.insert(st, "sgkgodshangce") end
			local t_data = sgs.QVariant()
			t_data:setValue(t)
			local strategy = room:askForChoice(player, self:objectName(), table.concat(st, "+"), t_data)
			player:removeTag("st_AI")
			player:setTag("st_AI", sgs.QVariant(strategy))
			local _con = getLunceCondition(strategy)
			local _eff = getLunceEffect(strategy)
			local _condition = room:askForChoice(player, "lunce_condition", table.concat(_con, "+"), t_data)
			player:removeTag("lunce_condition_AI")
			player:setTag("lunce_condition_AI", sgs.QVariant(_condition))
			local _effect = room:askForChoice(player, "lunce_effect", table.concat(_eff, "+"), t_data)
			room:doAnimate(1, player:objectName(), t:objectName())
			room:addPlayerMark(t, "&"..strategy)
			room:broadcastSkillInvoke(self:objectName(), lunceVoice(strategy))
			t:setTag(strategy, sgs.QVariant("".._condition.."+".._effect))  --设置“论策”的tag格式：第一项记载计策的条件，第二项记载计策的效果
			updateLunce(player)
		end
		return false
	end
}


sgkgodpangtong:addSkill(sgkgodlunce)


--论策·下策:使用黑色牌，使用红色牌，使用【杀】，使用锦囊牌，造成伤害，回复体力
sgkgodluncexia = sgs.CreateTriggerSkillV2{
	name = "#sgkgodluncexia",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.Damage, sgs.HpRecover},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not (use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill
				and use.from:getMark("&sgkgodxiace") > 0 and player:objectName() == use.from:objectName()) then return false end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if not (damage.from and damage.from:objectName() == player:objectName()
				and damage.from:getMark("&sgkgodxiace") > 0 and damage.damage > 0) then return false end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if not (player:getMark("&sgkgodxiace") > 0 and rec.recover > 0) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, owner, ctx)
		local data = ctx.original_data
		local player = ctx.invoker
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.from:getMark("&sgkgodxiace") > 0 and player:objectName() == use.from:objectName() then
				local xiace = player:getTag("sgkgodxiace"):toString():split("+")
				if (use.card:isBlack() and xiace[1] == "lunce_xia_blackcard") or (use.card:isRed() and xiace[1] == "lunce_xia_redcard")
					or (use.card:isKindOf("Slash") and xiace[1] == "lunce_xia_slash") or (use.card:isKindOf("TrickCard") and xiace[1] == "lunce_xia_trick") then
					finishStrategy(player, "sgkgodxiace")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.from:getMark("&sgkgodxiace") > 0 and damage.damage > 0 then
				local xiace = player:getTag("sgkgodxiace"):toString():split("+")
				if xiace[1] == "lunce_xia_damage" then finishStrategy(player, "sgkgodxiace") end
			end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if player:getMark("&sgkgodxiace") > 0 and rec.recover > 0 then
				local xiace = player:getTag("sgkgodxiace"):toString():split("+")
				if xiace[1] == "lunce_xia_recover" then finishStrategy(player, "sgkgodxiace") end
			end
		end
		return false
	end
}

--论策·中策:使用两张黑桃牌，使用两张红桃牌，因【杀】累计造成2点伤害，因锦囊牌累计造成2点伤害，累计造成2点属性伤害，累计回复2点体力
sgkgodluncezhong = sgs.CreateTriggerSkillV2{
	name = "#sgkgodluncezhong",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.Damage, sgs.HpRecover},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not (use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill
				and use.from:getMark("&sgkgodzhongce") > 0 and player:objectName() == use.from:objectName()) then return false end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if not (damage.from and damage.from:objectName() == player:objectName()
				and damage.from:getMark("&sgkgodzhongce") > 0 and damage.damage > 0) then return false end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if not (player:getMark("&sgkgodzhongce") > 0 and rec.recover > 0) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, owner, ctx)
		local data = ctx.original_data
		local player = ctx.invoker
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.from:getMark("&sgkgodzhongce") > 0 and player:objectName() == use.from:objectName() then
				local zhongce = player:getTag("sgkgodzhongce"):toString():split("+")
				if (zhongce[1] == "lunce_zhong_2heart" and use.card:getSuit() == sgs.Card_Heart) or (zhongce[1] == "lunce_zhong_2spade" and use.card:getSuit() == sgs.Card_Spade) then
					room:addPlayerMark(player, "zhongce_times")
					if player:getMark("zhongce_times") >= 2 then
						room:setPlayerMark(player, "zhongce_times", 0)
						finishStrategy(player, "sgkgodzhongce")
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.from:getMark("&sgkgodzhongce") > 0 and damage.damage > 0 then
				local zhongce = player:getTag("sgkgodzhongce"):toString():split("+")
				if zhongce[1] == "lunce_zhong_2nature" and damage.nature ~= sgs.DamageStruct_Normal then
					room:addPlayerMark(player, "zhongce_times", damage.damage)
					if player:getMark("zhongce_times") >= 2 then
						room:setPlayerMark(player, "zhongce_times", 0)
						finishStrategy(player, "sgkgodzhongce")
					end
				end
				if damage.card then
					if (zhongce[1] == "lunce_zhong_slash2dmg" and damage.card:isKindOf("Slash")) or (zhongce[1] == "lunce_zhong_trick2dmg" and damage.card:isKindOf("TrickCard")) then
						room:addPlayerMark(player, "zhongce_times", damage.damage)
						if player:getMark("zhongce_times") >= 2 then
							room:setPlayerMark(player, "zhongce_times", 0)
							finishStrategy(player, "sgkgodzhongce")
						end
					end
				end
			end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if player:getMark("&sgkgodzhongce") > 0 and rec.recover > 0 then
				local zhongce = player:getTag("sgkgodzhongce"):toString():split("+")
				if zhongce[1] == "lunce_zhong_2rec" then
					room:addPlayerMark(player, "zhongce_times", rec.recover)
					if player:getMark("zhongce_times") >= 2 then
						room:setPlayerMark(player, "zhongce_times", 0)
						finishStrategy(player, "sgkgodzhongce")
					end
				end
			end
		end
		return false
	end
}

--论策·上策:使用不同花色的牌各一张，使用不同类型的牌各一张，获得技能，失去技能，令一名角色进入濒死状态，进入濒死状态
sgkgodlunceshang = sgs.CreateTriggerSkillV2{
	name = "#sgkgodlunceshang",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EnterDying},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not (use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill
				and use.from:getMark("&sgkgodshangce") > 0 and player:objectName() == use.from:objectName()) then return false end
		elseif event == sgs.EventAcquireSkill or event == sgs.EventLoseSkill then
			if player:getMark("&sgkgodshangce") <= 0 then return false end
		elseif event == sgs.EnterDying then
			local dying = data:toDying()
			local ok = false
			if dying.damage and dying.damage.from and dying.damage.from:getMark("&sgkgodshangce") > 0
				and dying.damage.from:objectName() == player:objectName() then ok = true end
			if dying.who and dying.who:objectName() == player:objectName() and dying.who:getMark("&sgkgodshangce") > 0 then ok = true end
			if not ok then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, owner, ctx)
		local data = ctx.original_data
		local player = ctx.invoker
		if not player then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.from:getMark("&sgkgodshangce") > 0 and player:objectName() == use.from:objectName() then
				local shangce = player:getTag("sgkgodshangce"):toString():split("+")
				if shangce[1] == "lunce_shang_suit" then
					local suits = player:getTag("lunce_shang_suit"):toString():split("+")
					if (not string.find(use.card:getSuitString(), "nosuit")) and not table.contains(suits, use.card:getSuitString()) then
						table.insert(suits, use.card:getSuitString())
						if #suits == 4 then
							suits = nil
							player:removeTag("lunce_shang_suit")
							finishStrategy(player, "sgkgodshangce")
						else
							player:setTag("lunce_shang_suit", sgs.QVariant(table.concat(suits, "+"))) 
						end
					end
				elseif shangce[1] == "lunce_shang_type" then
					local types = player:getTag("lunce_shang_type"):toString():split("+")
					if not table.contains(types, getTypeString(use.card)) then
						table.insert(types, getTypeString(use.card))
						if #types == 3 then
							types = nil
							player:removeTag("lunce_shang_type")
							finishStrategy(player, "sgkgodshangce")
						else
							player:setTag("lunce_shang_type", sgs.QVariant(table.concat(types, "+"))) 
						end
					end
				end
			end
		elseif event == sgs.EventAcquireSkill then
			if player:getMark("&sgkgodshangce") > 0 then
				local shangce = player:getTag("sgkgodshangce"):toString():split("+")
				if shangce[1] == "lunce_shang_acquireskill" then
					room:setPlayerMark(player, "&sgkgodshangce", 0)
					finishStrategy(player, "sgkgodshangce")
				end
			end
		elseif event == sgs.EventLoseSkill then
			if player:getMark("&sgkgodshangce") > 0 then
				local shangce = player:getTag("sgkgodshangce"):toString():split("+")
				if shangce[1] == "lunce_shang_loseskill" then
					room:setPlayerMark(player, "&sgkgodshangce", 0)
					finishStrategy(player, "sgkgodshangce")
				end
			end
		elseif event == sgs.EnterDying then
			local dying = data:toDying()
			if dying.damage and dying.damage.from and dying.damage.from:getMark("&sgkgodshangce") > 0 and dying.damage.from:objectName() == player:objectName() then
				local shangce = player:getTag("sgkgodshangce"):toString():split("+")
				if shangce[1] == "lunce_shang_causedying" then
					room:setPlayerMark(player, "&sgkgodshangce", 0)
					finishStrategy(player, "sgkgodshangce")
				end
			end
			if dying.who:objectName() == player:objectName() and dying.who:getMark("&sgkgodshangce") > 0 then
				local shangce = player:getTag("sgkgodshangce"):toString():split("+")
				if shangce[1] == "lunce_shang_dying" then
					room:setPlayerMark(player, "&sgkgodshangce", 0)
					finishStrategy(player, "sgkgodshangce")
				end
			end
		end
		return false
	end
}



sgs.LoadTranslationTable{
    ["sgkgodpangtong"] = "神庞统",
	["&sgkgodpangtong"] = "神庞统",
	["#sgkgodpangtong"] = "凤唳九天",
	["~sgkgodpangtong"] = "看来，我命中注定要落凤于此……",
	["sgkgodqifeng"] = "栖凤",
	[":sgkgodqifeng"] = "锁定技，当你进入濒死状态时，你减1点体力上限，回复体力至1点，摸0张牌，然后你对一名其他角色造成0点火焰伤害。\
	<font color=\"#00ff40\">当任意角色完成下策后，“栖凤”摸牌数+1。</font>\
	<font color=\"#ff00a5\">当任意角色完成中策后，“栖凤”体力回复量+1。</font>\
	<font color=\"#ffa500\">当任意角色完成上策后，“栖凤”造成的火焰伤害+1。</font>",
	[":sgkgodqifeng1"] = "锁定技，当你进入濒死状态时，你减1点体力上限，回复体力至%arg2点，摸%arg1张牌，然后你对一名其他角色造成%arg3点火焰伤害。\
	<font color=\"#00ff40\">当任意角色完成下策后，“栖凤”摸牌数+1。</font>\
	<font color=\"#ff00a5\">当任意角色完成中策后，“栖凤”体力回复量+1。</font>\
	<font color=\"#ffa500\">当任意角色完成上策后，“栖凤”造成的火焰伤害+1。</font>",
	["$sgkgodqifeng1"] = "凤凰折翼，涅槃再生！",
	["$sgkgodqifeng2"] = "九天之志，展翅翱翔！",
	["@qifeng_firedamage"] = "请选择一名其他角色，对其造成%src点火焰伤害",
	["sgkgodlunce"] = "论策",
	["@lunce-target"] = "你可以发动“论策”令一名角色获得一项计策",
	[":sgkgodlunce"] = "每轮开始时，你可以令一名角色获得一个场上没有的计策（每种计策至多同时存在一个）。然后当一名角色完成计策后，你加1点体力上限并回复1点体力。",
	[":sgkgodlunce1"] = "每轮开始时，你可以令一名角色获得一个场上没有的计策（每种计策至多同时存在一个）。然后当一名角色完成计策后，你加1点体力上限并回复1点体力。\
	<font color=\"#ffa500\">上策：%best</font>\
	<font color=\"#ff00a5\">中策：%mid</font>\
	<font color=\"#00ff40\">下策：%worst</font>",
	["#lunceFinish"] = "%from 完成了“%arg”的条件“%arg2”，将执行该计策的效果“%arg3”",
	["#lunceFinishPangtong"] = "%from 的“%arg”被触发，由于 %to 完成了“%arg2”，%from 将获得1点体力上限的奖励并修改“%arg3”的效果",
	["$sgkgodlunce1"] = "退还白帝，连引荆州，徐还图之，此下计也。",  --下策
	["$sgkgodlunce2"] = "荆州有急，欲还救之，进取其兵，此中计也。",  --中策
	["$sgkgodlunce3"] = "阴选精兵，昼夜兼道，径袭成都，此上计也！",  --上策
	["sgkgodxiace"] = "下策",
	["sgkgodzhongce"] = "中策",
	["sgkgodshangce"] = "上策",
	["lunce_condition"] = "选择“论策”的计策条件",
	["lunce_effect"] = "选择“论策”的计策效果",
	--下策条件
	["lunce_xia_blackcard"] = "使用黑色牌",
	["lunce_xia_redcard"] = "使用红色牌",
	["lunce_xia_slash"] = "使用【杀】",
	["lunce_xia_trick"] = "使用锦囊牌",
	["lunce_xia_damage"] = "造成伤害",
	["lunce_xia_recover"] = "回复体力",
	--下策效果
	["lunce_xia_draw2"] = "摸两张牌",
	["lunce_xia_recover1"] = "回复1点体力",
	["lunce_xia_throw2"] = "随机弃置两张牌",
	["lunce_xia_firedamage"] = "受到1点无来源的火焰伤害",
	--中策条件
	["lunce_zhong_2spade"] = "使用两张黑桃牌",
	["lunce_zhong_2heart"] = "使用两张红桃牌",
	["lunce_zhong_slash2dmg"] = "因【杀】累计造成2点伤害",
	["lunce_zhong_trick2dmg"] = "因锦囊牌累计造成2点伤害",
	["lunce_zhong_2nature"] = "累计造成2点属性伤害",
	["lunce_zhong_2rec"] = "累计回复2点体力",
	--中策效果
	["lunce_zhong_drawphase"] = "摸牌阶段摸牌数+1",
	["lunce_zhong_slashtime"] = "出牌阶段使用【杀】次数+1",
	["lunce_zhong_turnover"] = "翻面",
	["lunce_zhong_losemaxhp"] = "减1点体力上限",
	--上策条件
	["lunce_shang_suit"] = "使用不同花色的牌各一张",
	["lunce_shang_type"] = "使用不同类型的牌各一张",
	["lunce_shang_acquireskill"] = "获得技能",
	["lunce_shang_loseskill"] = "失去技能",
	["lunce_shang_causedying"] = "令一名角色进入濒死状态",
	["lunce_shang_dying"] = "进入濒死状态",
	--上策效果
	["lunce_shang_gainsamekingdomskill"] = "随机获得一个同势力技能",
	["lunce_shang_1maxhp1recover"] = "加1点体力上限并回复1点体力",
	["lunce_shang_loserandomskill"] = "随机失去一个技能",
	["lunce_shang_throwallcards"] = "弃置所有牌",
	["when_one"] = "当执行计策的角色",
	["when_comma"] = "时，",
	["then_one"] = "该角色",
	["then_end"] = "。",
	["designer:sgkgodpangtong"] =" 极略三国",
	["illustrator:sgkgodpangtong"] = "极略三国",
	["cv:sgkgodpangtong"] = "极略三国",
}


--神蔡文姬
sgkgodcaiwenji = sgs.General(extension, "sgkgodcaiwenji", "sy_god", 3, false)


--[[
	技能名：寒霜
	相关武将：神蔡文姬
	技能描述：当任意角色受到伤害时，你可以令其摸/弃置X张牌并令此伤害+X/-X（X为“寒霜”本轮对其发动的次数）。
	引用：sgkgodhanshuang
]]--
sgkgodhanshuang = sgs.CreateTriggerSkillV2{
	name = "sgkgodhanshuang",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, p:objectName())
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		local cwj = player
		local _q = sgs.QVariant()
		_q:setValue(damage.to)
		local _d = sgs.QVariant()
		_d:setValue(damage)
		cwj:setTag("hanshuang_AI_data", _d)
		local x = damage.to:getMark("&sgkgodhanshuang_times_lun") + 1
		local hanshuang = {"hanshuang_draw_exdmg="..damage.to:objectName().."="..tostring(x), "hanshuang_discard_reduce="..damage.to:objectName().."="..tostring(x)}
		if damage.to:getCards("he"):length() < x then table.remove(hanshuang, 2) end
		table.insert(hanshuang, "cancel")
		local choice = room:askForChoice(cwj, self:objectName(), table.concat(hanshuang, "+"), _q)
		cwj:removeTag("hanshuang_AI_data")
		if choice ~= "cancel" then
			room:doAnimate(1, cwj:objectName(), damage.to:objectName())
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:addPlayerMark(damage.to, "&sgkgodhanshuang_times_lun")
			local log = sgs.LogMessage()
			log.type = "#InvokeSkill"
			log.from = cwj
			log.arg = self:objectName()
			room:sendLog(log)
			cwj:peiyin(self)
			room:notifySkillInvoked(cwj, self:objectName())
			local y = damage.to:getMark("&sgkgodhanshuang_times_lun")
			if choice:startsWith("hanshuang_draw_exdmg") then
				damage.to:drawCards(y, self:objectName())
				damage.damage = damage.damage + y
				data:setValue(damage)
			else
				room:askForDiscard(damage.to, self:objectName(), y, y, false, true)
				if damage.damage <= y then
					return true
				else
					damage.damage = damage.damage - y
					data:setValue(damage)
				end
			end
		end
		return false
	end
}


sgkgodcaiwenji:addSkill(sgkgodhanshuang)


--[[
	技能名：离乱
	相关武将：神蔡文姬
	技能描述：每回合限一次，当任意角色弃置牌/摸牌时，你可以改为令其以外的所有角色各随机弃置一张牌/摸一张牌。
	引用：sgkgodliluan
]]--
sgkgodliluan = sgs.CreateTriggerSkillV2{
	name = "sgkgodliluan",
	events = {sgs.BeforeCardsMove},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		local x = move.card_ids:length()
		if room:getTag("FirstRound"):toBool() then return false end
		if player:getMark(skill:objectName().."-Clear") > 0 then return false end
		local discard_move = move.from and move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand)
			or move.from_places:contains(sgs.Player_PlaceEquip)) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick) and
			bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and x > 0
		local draw_move = move.to_place == sgs.Player_PlaceHand and move.to and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
			or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW)
		if not (discard_move or draw_move) then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local x = move.card_ids:length()
		if room:getTag("FirstRound"):toBool() then return false end
		if not player:hasSkill(self:objectName()) then return false end
		if player:getMark(self:objectName().."-Clear") > 0 then return false end
		--有人弃置牌时，改为令所有其他角色随机弃置一张牌
		if move.from and move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand)
		or move.from_places:contains(sgs.Player_PlaceEquip)) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick) and 
		bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and x > 0 then
			local _from = -1
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.from:objectName() then
					_from = p
					break
				end
			end
			if _from ~= -1 then
				local _q = sgs.QVariant()
				_q:setValue(_from)
				local _m = sgs.QVariant()
				_m:setValue(move)
				player:setTag("liluan_AI_movedata", _m)
				if player:askForSkillInvoke(self:objectName(), _q) then
					player:removeTag("liluan_AI_movedata")
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:addPlayerMark(player, self:objectName().."-Clear")
					move.card_ids = sgs.IntList()
					data:setValue(move)
					for _, t in sgs.qlist(room:getOtherPlayers(_from)) do
						room:doAnimate(1, player:objectName(), t:objectName())
					end
					for _, t in sgs.qlist(room:getOtherPlayers(_from)) do
						throwRandomCards(true, player, t, 1, "he", self:objectName())
					end
				end
			end
		end
		--有人摸牌时，改为令所有其他角色摸一张牌
		if move.to_place == sgs.Player_PlaceHand and move.to and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW 
		or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
			local _to = -1
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.to:objectName() then
					_to = p
					break
				end
			end
			if _to ~= -1 then
				local _q = sgs.QVariant()
				_q:setValue(_to)
				local _m = sgs.QVariant()
				_m:setValue(move)
				player:setTag("liluan_AI_movedata", _m)
				if player:askForSkillInvoke(self:objectName(), _q) then
					player:removeTag("liluan_AI_movedata")
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:addPlayerMark(player, self:objectName().."-Clear")
					move.card_ids = sgs.IntList()
					data:setValue(move)
					for _, t in sgs.qlist(room:getOtherPlayers(_to)) do
						room:doAnimate(1, player:objectName(), t:objectName())
					end
					for _, t in sgs.qlist(room:getOtherPlayers(_to)) do
						t:drawCards(1, self:objectName())
					end
				end
			end
		end
		player:removeTag("liluan_AI_movedata")
		return false
	end
}


sgkgodcaiwenji:addSkill(sgkgodliluan)


sgs.LoadTranslationTable{
    ["sgkgodcaiwenji"] = "神蔡文姬",
	["&sgkgodcaiwenji"] = "神蔡文姬",
	["#sgkgodcaiwenji"] = "霜弦哀世",
	["~sgkgodcaiwenji"] = "十八拍兮曲已终，身赴黄泉忧愁同……",
	["sgkgodhanshuang"] = "寒霜",
	[":sgkgodhanshuang"] = "当一名角色受到伤害时，你可以令其执行一项：1.摸X张牌且此伤害+X；2.若其牌数不小于X，其弃置X张牌且此伤害-X（X为你本轮对其发动此技能的次数）。",
	["sgkgodhanshuang_times_lun"] = "寒霜",
	["sgkgodhanshuang_times"] = "寒霜",
	["sgkgodhanshuang:hanshuang_draw_exdmg"] = "令%src摸%arg张牌，并令此伤害+%arg",
	["sgkgodhanshuang:hanshuang_discard_reduce"] = "令%src弃置%arg张牌，并令此伤害-%arg",
	["$sgkgodhanshuang1"] = "冰霜凛凛身苦寒，万物凋零繁花残。",
	["$sgkgodhanshuang2"] = "风霜凛凛春夏寒，叹息欲绝泪阑干。",
	["sgkgodliluan"] = "离乱",
	[":sgkgodliluan"] = "每回合限一次，当一名角色即将摸牌/弃牌时，你可以改为令除其以外的所有角色各摸/随机弃置一张牌。",
	["$sgkgodliluan1"] = "天不仁兮降乱离，地不仁兮逢此时。",
	["$sgkgodliluan2"] = "干戈日寻道路危，民卒流亡共哀悲。",
	["designer:sgkgodcaiwenji"] =" 极略三国",
	["illustrator:sgkgodcaiwenji"] = "极略三国",
	["cv:sgkgodcaiwenji"] = "极略三国",
}

--old

--SK神吕蒙
nos_sgkgodlvmeng = sgs.General(extension, "nos_sgkgodlvmeng", "sy_god", 3)


--涉猎
nos_sgkgodshelie = sgs.CreateTriggerSkillV2{
    name = "nos_sgkgodshelie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		if room:getDrawPile():isEmpty() then room:swapPile() end --没牌可摸那就尴尬了
		local basic_cards, trick_cards, equip_cards = sgs.IntList(), sgs.IntList(), sgs.IntList()
		for _, c in sgs.qlist(room:getDrawPile()) do
		    local card = sgs.Sanguosha:getCard(c)
			if card:isKindOf("BasicCard") then
			    basic_cards:append(card:getEffectiveId())
			elseif card:isKindOf("TrickCard") then
			    trick_cards:append(card:getEffectiveId())
			elseif card:isKindOf("EquipCard") then
			    equip_cards:append(card:getEffectiveId())
			end
		end
		local shelie_types = {"BasicCard","TrickCard","EquipCard"}
		if basic_cards:isEmpty() then table.removeOne(shelie_types, "BasicCard") end
		if trick_cards:isEmpty() then table.removeOne(shelie_types, "TrickCard") end
		if equip_cards:isEmpty() then table.removeOne(shelie_types, "EquipCard") end
		local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		for i = 1, 4 do
		    local id
			local choice = room:askForChoice(player, self:objectName(), table.concat(shelie_types, "+"))
			if choice == "BasicCard" then
			    id = basic_cards:at(math.random(0, basic_cards:length()-1))
				basic_cards:removeOne(id)
				dummy:addSubcard(id)
			elseif choice == "TrickCard" then
			    id = trick_cards:at(math.random(0, trick_cards:length()-1))
				trick_cards:removeOne(id)
				dummy:addSubcard(id)
			elseif choice == "EquipCard" then
			    id = equip_cards:at(math.random(0, equip_cards:length()-1))
				equip_cards:removeOne(id)
				dummy:addSubcard(id)
			end
			if #shelie_types == 0 then break end
		end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		room:obtainCard(player, dummy, "nos_sgkgodshelie", false)
		dummy:deleteLater()
		basic_cards, trick_cards, equip_cards = sgs.IntList(), sgs.IntList(), sgs.IntList()
		return true
	end
}


--攻心
nos_sgkgodgongxinCard = sgs.CreateSkillCard{
    name = "nos_sgkgodgongxinCard",
	filter = function(self, targets, to_select, player)
	    return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
		    local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart then
					ids:append(card:getEffectiveId())
				end
			end
			if ids:isEmpty() then
			    room:fillAG(effect.to:handCards(), effect.from)
				room:getThread():delay(1000)
				room:clearAG()
			else
			    room:fillAG(ids)
			    local card_id = room:doGongxin(effect.from, effect.to, ids)
				room:getThread():delay(1000)
				room:clearAG()
			    if ids:length() == 1 then
			        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, effect.from:objectName(), nil, "nos_sgkgodgongxin", nil)
				    room:throwCard(sgs.Sanguosha:getCard(card_id), reason, effect.to, effect.from)
				    room:damage(sgs.DamageStruct("nos_sgkgodgongxin", effect.from, effect.to))
			    else
			        if ids:length() > 1 then
				        local card = sgs.Sanguosha:getCard(card_id)
					    if effect.from:canGet(effect.to, card_id) then
						    room:obtainCard(effect.from, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName(), effect.to:objectName(), "nos_sgkgodgongxin", ""), true)
						end
					end
				end
			end
		end
	end
}

nos_sgkgodgongxin = sgs.CreateViewAsSkillV2{
    name = "nos_sgkgodgongxin",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("nos_sgkgodgongxin")
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
			and not candidate:isKongcheng()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local card = nos_sgkgodgongxinCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("nos_sgkgodgongxin", instance_id)
			card:setSourceSkill("nos_sgkgodgongxin", instance_id)
		end
		return card
	end,
}


nos_sgkgodlvmeng:addSkill(nos_sgkgodshelie)
nos_sgkgodlvmeng:addSkill(nos_sgkgodgongxin)


sgs.LoadTranslationTable{
	["nos_sgkgodlvmeng"] = "SK神吕蒙[旧]",
	["#nos_sgkgodlvmeng"] = "圣光国士",
	["&nos_sgkgodlvmeng"] = "神吕蒙",
	["~nos_sgkgodlvmeng"] = "死去方知万事空……",
	["designer:nos_sgkgodlvmeng"] = "魂烈",
	["illustrator:nos_sgkgodlvmeng"] = "魂烈",
	["cv:nos_sgkgodlvmeng"] = "魂烈",
	["nos_sgkgodshelie"] = "涉猎",
	[":nos_sgkgodshelie"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你放弃摸牌，改为选择四次牌的类别，然后从牌堆随机获得相应类别的牌。",
	["$nos_sgkgodshelie"] = "涉猎阅旧闻，暂使心魂澄。",
	["nos_sgkgodgongxin"] = "攻心",
	[":nos_sgkgodgongxin"] = "<font color = \"green\"><b>出牌阶段限一次。</b></font>你可以观看一名其他角色的手牌并展示其中所有的红桃牌，然后若展示的牌数：为1，你弃置之并对其"..
	"造成1点伤害；大于1，你获得其中一张。",
	["$nos_sgkgodgongxin"] = "攻城为下，攻心为上。",
}


--SK神赵云
nos_sgkgodzhaoyun = sgs.General(extension, "nos_sgkgodzhaoyun", "sy_god", 2)


--绝境
nos_sgkgodjuejing = sgs.CreateTriggerSkillV2{
    name = "nos_sgkgodjuejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, p:objectName())
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_effect = function(self, event, room, player, ctx)
		local zhaoyun = player
		room:sendCompulsoryTriggerLog(zhaoyun, self:objectName())
		room:notifySkillInvoked(zhaoyun, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		if zhaoyun:getHp() >= 2 then
			room:loseHp(zhaoyun, 1, true, zhaoyun, self:objectName())
			zhaoyun:drawCards(2)
		else
			zhaoyun:drawCards(1)
		end
		return false
	end,
}


--龙魂
nos_sgkgodlonghun = sgs.CreateViewAsSkillV2{
    name = "nos_sgkgodlonghun",
	response_or_use = true,
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:isWounded() or sgs.Slash_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if pattern == "nullification" then
				local n = math.max(1, player:getHp())
				local count = 0
				for _, c in sgs.qlist(player:getHandcards()) do
					if c:getSuit() == sgs.Card_Spade then count = count + 1 end
					if count >= n then return true end
				end
				for _, c in sgs.qlist(player:getEquips()) do
					if c:getSuit() == sgs.Card_Spade then count = count + 1 end
					if count >= n then return true end
				end
				return false
			end
			return pattern == "slash" or pattern == "jink"
				or (string.find(pattern, "peach") ~= nil and player:getMark("Global_PreventPeach") == 0)
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		local player = request:getInitiator()
		if not player then return false end
		local n = math.max(1, player:getHp())
		if not card or card:hasFlag("using") then return false end
		if request:getSelectedCardIds():length() >= n then return false end
		if request:getSelectedCardIds():length() > 0 then
			local first = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
			if first and card:getSuit() ~= first:getSuit() then return false end
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if player:isWounded() and card:getSuit() == sgs.Card_Heart then
				return true
			elseif card:getSuit() == sgs.Card_Diamond then
				local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
				slash:addSubcard(card:getEffectiveId())
				slash:deleteLater()
				return slash:isAvailable(player)
			else
				return false
			end
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if pattern == "jink" then
				return card:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return card:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return card:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return card:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local n = math.max(1, player:getHp())
		return request:getSelectedCardIds():length() == n
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local n = math.max(1, player:getHp())
		local ids = request:getSelectedCardIds()
		if ids:length() ~= n then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		if not card then return nil end
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(skill:objectName())
			for _, id in sgs.qlist(ids) do
				new_card:addSubcard(id)
			end
		end
		return new_card
	end,
}
-- ServerPlayer::hasNullification 只問舊 response_pattern 探針
nos_sgkgodlonghun.response_pattern = "nullification"


nos_sgkgodzhaoyun:addSkill(nos_sgkgodjuejing)
nos_sgkgodzhaoyun:addSkill(nos_sgkgodlonghun)


sgs.LoadTranslationTable{
    ["nos_sgkgodzhaoyun"] = "SK神赵云[旧]",
	["#nos_sgkgodzhaoyun"] = "神威如龙",
	["&nos_sgkgodzhaoyun"] = "神赵云",
	["~nos_sgkgodzhaoyun"] = "血染鳞甲，龙坠九天……",
	["designer:nos_sgkgodzhaoyun"] = "魂烈",
    ["illustrator:nos_sgkgodzhaoyun"] = "魂烈",
    ["cv:nos_sgkgodzhaoyun"] = "魂烈",
	["nos_sgkgodjuejing"] = "绝境",
	[":nos_sgkgodjuejing"] = "<font color=\"blue\"><b>锁定技。</b></font>一名角色的回合结束时，若你的体力值：为1，你摸一张牌；大于1，你失去1点体力，然后摸两张牌。",
	["$nos_sgkgodjuejing"] = "龙战于野，其血玄黄。",
	["nos_sgkgodlonghun"] = "龙魂",
	[":nos_sgkgodlonghun"] = "你可以将X张花色相同的牌按下列规则使用或打出（X为你的体力值且至少为1）：红桃当【桃】，方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】。",
	["$nos_sgkgodlonghun1"] = "金甲映日，驱邪祛秽。",
	["$nos_sgkgodlonghun2"] = "腾龙行云，首尾不见。",
	["$nos_sgkgodlonghun3"] = "潜龙于渊，涉灵愈伤。",
	["$nos_sgkgodlonghun4"] = "千里一怒，红莲灿世。",
}
--SK神张辽
nos_sgkgodzhangliao=sgs.General(extension,"nos_sgkgodzhangliao","sy_god","4")


--逆战
nos_sgkgodnizhan=sgs.CreateTriggerSkillV2{
name="nos_sgkgodnizhan",
events={sgs.DamageInflicted},
frequency=sgs.Skill_NotFrequent,
can_trigger=function(skill,event,room,player,data)
	local damage=data:toDamage()
	if not damage.to or not damage.to:isAlive() then return false end
	if not damage.card then return false end
	if not damage.card:isKindOf("Slash") and not damage.card:isKindOf("Duel") then return false end
	local names, owners = {}, {}
	for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
		table.insert(names, skill:objectName())
		table.insert(owners, p:objectName())
	end
	if #names == 0 then return false end
	return table.concat(names, "|"), table.concat(owners, "|")
end,
on_effect=function(self,event,room,player,ctx)
	local data = ctx.original_data
	local damage=data:toDamage()
	if not damage.to:isAlive() then return false end
	if not damage.card then return false end
	if not damage.card:isKindOf("Slash") and not damage.card:isKindOf("Duel") then return false end
	local s = player
	if not s:askForSkillInvoke(self:objectName(),data) then return false end
	if damage.from:objectName()==s:objectName() or damage.to:objectName()==s:objectName() then
		if damage.from:objectName()==s:objectName() then
			damage.to:gainMark("@xi")
			room:broadcastSkillInvoke(self:objectName())
		elseif damage.to:objectName()==s:objectName() then
			damage.from:gainMark("@xi")
			room:broadcastSkillInvoke(self:objectName())
		elseif damage.from:objectName() == s:objectName() and damage.to:objectName() == s:objectName() then
			return false
		end
	else
		local players=sgs.SPlayerList()
		players:append(damage.from)
		players:append(damage.to)
		local target=room:askForPlayerChosen(s,players,self:objectName())
		target:gainMark("@xi")
		room:broadcastSkillInvoke(self:objectName())
	end
	return false
end
}

nos_sgkgodnizhanClear=sgs.CreateTriggerSkillV2{
name="#nos_sgkgodnizhan",
events=sgs.Death,
frequency=sgs.Skill_Compulsory,
can_trigger=function(skill,event,room,player,data)
	return skill:objectName()
end,
on_effect=function(self,event,room,player,ctx)
	local data = ctx.original_data
    local death=data:toDeath()
	if death.who:hasSkill("nos_sgkgodnizhan") then
	    for _,p in sgs.qlist(room:getAllPlayers()) do
		    if p:getMark("@xi")>0 then p:loseAllMarks("@xi") end
		end
	end
	return false
end
}


extension:insertRelatedSkills("nos_sgkgodnizhan","#nos_sgkgodnizhan")


--摧锋
nos_sgkgodcuifeng=sgs.CreateTriggerSkillV2{
name="nos_sgkgodcuifeng",
events=sgs.EventPhaseStart,
frequency=sgs.Skill_Compulsory,
can_trigger=function(skill,event,room,player,data)
	if player:getPhase()~=sgs.Player_Finish then return false end
	return skill:objectName()
end,
on_effect=function(self,event,room,player,ctx)
	if player:getPhase()~=sgs.Player_Finish then return false end
	local x=0
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		x=x+p:getMark("@xi")
	end
	if x<4 then return false end
	room:sendCompulsoryTriggerLog(player, self:objectName())
	room:notifySkillInvoked(player,self:objectName())
	room:broadcastSkillInvoke(self:objectName())
	room:doSuperLightbox("nos_sgkgodzhangliao", "nos_sgkgodcuifeng")
	for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		if not player:isAlive() then break end
		if p:getMark("@xi")>0 then
			local hand=p:getHandcardNum()
			local mark=p:getMark("@xi")
			p:loseAllMarks("@xi")
			if hand<mark then
				local whole=sgs.Sanguosha:cloneCard("slash",sgs.Card_SuitToBeDecided,-1)
				for _,c in sgs.qlist(p:getHandcards()) do
					if player:canGet(p,c:getEffectiveId()) then whole:addSubcard(c) end
				end
				if whole:subcardsLength()>0 then
					room:obtainCard(player,whole,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,player:objectName(),p:objectName(),"nos_sgkgodcuifeng",""),false)
				end
				whole:deleteLater()
				room:damage(sgs.DamageStruct("nos_sgkgodcuifeng",player,p))
			else
				local cards={}
				for _,c in sgs.qlist(p:getCards("h")) do
					if player:canGet(p,c:getEffectiveId()) then table.insert(cards,c) end
				end
				local dummy=sgs.Sanguosha:cloneCard("slash",sgs.Card_SuitToBeDecided,-1)
				local count=0
				for i=1,mark,1 do
					if #cards==0 then break end
					local c=table.remove(cards,math.random(1,#cards))
					dummy:addSubcard(c)
					count=count+1
				end
				if count>0 then
					room:obtainCard(player,dummy,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,player:objectName(),p:objectName(),"nos_sgkgodcuifeng",""),false)
				end
			end
		end
	end
	return false
end
}


--威震
nos_sgkgodweizhen=sgs.CreateTriggerSkillV2{
name="nos_sgkgodweizhen",
events=sgs.EventPhaseStart,
can_trigger=function(skill,event,room,player,data)
	if player:getPhase()~=sgs.Player_Start then return false end
	return skill:objectName()
end,
on_effect=function(self,event,room,player,ctx)
	local data = ctx.original_data
	if player:getPhase()~=sgs.Player_Start then return false end
	local flag=false
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:getMark("@xi")>0 then
			flag=true
			break
		end
	end
	if flag==false then return false end
	if not player:askForSkillInvoke(self:objectName(),data) then return false end
	room:broadcastSkillInvoke(self:objectName())
	local x=0
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:getMark("@xi")>0 then
			x=x+p:getMark("@xi")
			p:loseAllMarks("@xi")
		end
	end
	player:drawCards(x)
	return false
end
}


nos_sgkgodzhangliao:addSkill(nos_sgkgodnizhan)
nos_sgkgodzhangliao:addSkill(nos_sgkgodcuifeng)
nos_sgkgodzhangliao:addSkill(nos_sgkgodweizhen)


sgs.LoadTranslationTable{
["nos_sgkgodzhangliao"]="SK神张辽[旧]",
["&nos_sgkgodzhangliao"]="神张辽",
["#nos_sgkgodzhangliao"]="威名裂胆",
["nos_sgkgodnizhan"]="逆战",
[":nos_sgkgodnizhan"]="每当一名角色受到【杀】或【决斗】造成的伤害时，你可以令该角色或伤害来源（不得为你）获得一枚“袭”标记。",
["@xi"]="袭",
["nos_sgkgodcuifeng"]="摧锋",
[":nos_sgkgodcuifeng"]="<font color=\"blue\"><b>锁定技。</b></font>结束阶段开始时，若所有角色的“袭”标记总数不小于4，你须从有“袭”标记的角色处各获得等同于其“袭”标记数的手牌（若不足则获得其全部手牌并对其造成1点伤害），然后弃置所有角色全部的“袭”标记。",
["nos_sgkgodweizhen"]="威震",
[":nos_sgkgodweizhen"]="准备阶段开始时，你可以弃置所有角色全部的“袭”标记，然后摸等量的牌。",
["$nos_sgkgodnizhan"]="已是成败二分之时！",
["$nos_sgkgodcuifeng"]="全军化为一体，总攻！",
["$nos_sgkgodweizhen"]="让你见识我军的真正实力！",
["~nos_sgkgodzhangliao"]="不求留名青史，但求无愧于心……",
["designer:nos_sgkgodzhangliao"]="魂烈",
["illustrator:nos_sgkgodzhangliao"]="魂烈",
["cv:nos_sgkgodzhangliao"]="魂烈",
}



--SK神司马
nos_sgkgodsima = sgs.General(extension, "nos_sgkgodsima", "sy_god", "3", true)


--极略
nos_sgkgodjilueCard = sgs.CreateSkillCard{
	name = "nos_sgkgodjilueCard",
	target_fixed=true,
	will_throw=true,
	on_use = function(self,room,source,targets)
		room:drawCards(source, 1)
		local pattern = "|.|.|.|."
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("EquipCard") and not source:isLocked(cd)  then
				if cd:isAvailable(source) then
					pattern = "EquipCard,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Analeptic") and not source:isLocked(cd)  then
				local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
				if card:isAvailable(source) then
					pattern = "Analeptic,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Slash") and not source:isLocked(cd)  then
				local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
				if card:isAvailable(source) then
				    for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					    if (not sgs.Sanguosha:isProhibited(source, p, cd)) and source:canSlash(p, card, true) then
					        pattern = "Slash,"..pattern
					        break
						end
					end
				end
				break
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Peach") and not source:isLocked(cd)  then
				if cd:isAvailable(source) then
					pattern = "Peach,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("TrickCard") and not source:isLocked(cd) then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not sgs.Sanguosha:isProhibited(source, p, cd) then 
						pattern = "TrickCard+^Nullification,"..pattern
						break
					end
				end
				break
			end
		end
		if pattern ~= "|.|.|.|." then
		    local card = room:askForUseCard(source, pattern, "@nos_sgkgodjilue", -1)
			if not card then
				room:askForDiscard(source, "nos_sgkgodjilue", 1, 1, false, true)
				room:setPlayerFlag(source, "jiluefailed")
			end
		else
			room:askForDiscard(source, "nos_sgkgodjilue", 1, 1, false, true)
			room:setPlayerFlag(source, "jiluefailed")
		end
	end
}

nos_sgkgodjilue = sgs.CreateViewAsSkillV2{
	name = "nos_sgkgodjilue",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasFlag("jiluefailed")
	end,
	create_card = function(skill, request)
		local card = nos_sgkgodjilueCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("nos_sgkgodjilue", instance_id)
			card:setSourceSkill("nos_sgkgodjilue", instance_id)
		end
		return card
	end,
}


--通天
nos_sgkgodtongtianCard = sgs.CreateSkillCard{
	name = "nos_sgkgodtongtianCard",
	target_fixed = true,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@tian")
		room:doSuperLightbox("nos_sgkgodsima", "nos_sgkgodtongtian")
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getSuit() == sgs.Card_Spade then
			    if (not source:hasSkill("fankui")) and (not source:hasSkill("nosfankui")) then room:acquireSkill(source, "tongtian_fankui") end
			elseif c:getSuit() == sgs.Card_Heart then
			    if not source:hasSkill("guanxing") then room:acquireSkill(source, "tongtian_guanxing") end
			elseif c:getSuit() == sgs.Card_Club then
			    if not source:hasSkill("wansha") then room:acquireSkill(source, "tongtian_wansha") end
			elseif c:getSuit() == sgs.Card_Diamond then
			    if (not source:hasSkill("zhiheng")) and (not source:hasSkill("hujuzhiheng")) then room:acquireSkill(source, "tongtian_zhiheng") end
			end
		end
	end
}

nos_sgkgodtongtianViewAsSkill = sgs.CreateViewAsSkillV2{
	name = "nos_sgkgodtongtian",
	n = 4,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@tian") >= 1
	end,
	can_select_card = function(skill, request, to_select)
		local ids = request:getSelectedCardIds()
		if #ids >= 4 then return false end
		for _, id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() >= 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids == 0 then return nil end
		local ttCard = nos_sgkgodtongtianCard:clone()
		for _, id in sgs.qlist(ids) do
			ttCard:addSubcard(id)
		end
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			ttCard:setSkillInstanceId(instance_id)
			ttCard:setActivationSkill("nos_sgkgodtongtian", instance_id)
			ttCard:setSourceSkill("nos_sgkgodtongtian", instance_id)
		end
		return ttCard
	end,
}

nos_sgkgodtongtian = sgs.CreateTriggerSkillV2{
	name = "nos_sgkgodtongtian",
	frequency = sgs.Skill_Limited,
	limit_mark = "@tian",
	events = {},
	view_as_skill = nos_sgkgodtongtianViewAsSkill,
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		return false
	end
}


--反馈（通天）
tongtian_fankui = sgs.CreateTriggerSkillV2{
    name = "tongtian_fankui",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		local source = damage.from
		if not source or not player:canGet(source, "he") then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local source = data:toDamage().from
		if not source or not player:canGet(source, "he") then return false end
		if not player:askForSkillInvoke(skill:objectName(), data) then return false end
		ctx.targets:append(source)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke("tongtian_fankui")
		if not player:canGet(target, "he") then return false end
		local card_id = room:askForCardChosen(player, target, "he", "tongtian_fankui", false, sgs.Card_MethodGet)
		if not player:canGet(target, card_id) then return false end
		room:obtainCard(player, sgs.Sanguosha:getCard(card_id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), target:objectName(), "tongtian_fankui", ""), false)
		return false
	end
}


--制衡（通天）
tongtian_zhihengCard = sgs.CreateSkillCard{
	name = "tongtian_zhihengCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}

tongtian_zhiheng = sgs.CreateViewAsSkillV2{
	name = "tongtian_zhiheng",
	n = 1000,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("tongtian_zhiheng")
	end,
	can_select_card = function(skill, request, to_select)
		return true
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() > 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids == 0 then return nil end
		local zhiheng_card = tongtian_zhihengCard:clone()
		for _, id in sgs.qlist(ids) do
			zhiheng_card:addSubcard(id)
		end
		zhiheng_card:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			zhiheng_card:setSkillInstanceId(instance_id)
			zhiheng_card:setActivationSkill("tongtian_zhiheng", instance_id)
			zhiheng_card:setSourceSkill("tongtian_zhiheng", instance_id)
		end
		return zhiheng_card
	end,
}


--观星（通天）
tongtian_guanxing = sgs.CreateTriggerSkillV2{
	name = "tongtian_guanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Start then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 5 then
					count = 5
				end
				room:broadcastSkillInvoke(self:objectName())
				local cards = room:getNCards(count)
				room:askForGuanxing(player,cards)
			end
		end
		return false
	end
}


--完杀（通天）
tongtian_wansha = sgs.CreateTriggerSkillV2{
    name = "tongtian_wansha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	can_trigger = function(skill, event, room, player, data)
		local sima = room:getCurrent()
		if not (sima and sima:isAlive() and sima:hasSkill(skill:objectName()) and sima:getPhase() ~= sgs.Player_NotActive) then return false end
		return skill:objectName(), sima:objectName()
	end,
	on_effect = function(self, event, room, owner, ctx)
		local data = ctx.original_data
		local player = ctx.invoker
		if not player then return false end
		if event == sgs.AskForPeaches then
		    local dying = data:toDying()
			local sima = owner
			if sima and sima:isAlive() and sima:hasSkill(self:objectName()) and sima:getPhase() ~= sgs.Player_NotActive then
			    if sima:objectName() == player:objectName() then
			        room:broadcastSkillInvoke(self:objectName())
				    room:notifySkillInvoked(sima, self:objectName())
				    local log = sgs.LogMessage()
				    log.from = sima
				    log.arg = self:objectName()
				    if dying.who:objectName() ~= sima:objectName() then
				        log.type = "#WanshaTwo"
					    log.to:append(dying.who)
				    else
				        log.type = "#WanshaOne"
				    end
				    room:sendLog(log)
				end
				if dying.who:objectName() ~= player:objectName() and sima:objectName() ~= player:objectName() then
				    room:setPlayerMark(player, "Global_PreventPeach", 1)
				end
			end
		end
		return false
	end
}

--完殺標記的清理在司馬懿死亡或回合真正結束後仍須執行，故以全局隱藏技能承載
tongtian_wanshaClear = sgs.CreateTriggerSkillV2{
	name = "#tongtian_wansha_clear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			return skill:objectName()
		elseif event == sgs.Death then
			local death = data:toDeath()
			if not death.who or death.who:objectName() ~= player:objectName() or death.who:getPhase() == sgs.Player_NotActive then return false end
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		for _, p in sgs.qlist(room:getAllPlayers()) do
	        if p:getMark("Global_PreventPeach") > 0 then
		        room:setPlayerMark(p, "Global_PreventPeach", 0)
			end
		end
		return false
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("tongtian_fankui") then skills:append(tongtian_fankui) end
if not sgs.Sanguosha:getSkill("tongtian_zhiheng") then skills:append(tongtian_zhiheng) end
if not sgs.Sanguosha:getSkill("tongtian_guanxing") then skills:append(tongtian_guanxing) end
if not sgs.Sanguosha:getSkill("tongtian_wansha") then skills:append(tongtian_wansha) end
sgs.Sanguosha:addSkills(skills)
nos_sgkgodsima:addSkill(nos_sgkgodjilue)
nos_sgkgodsima:addSkill(nos_sgkgodtongtian)
nos_sgkgodsima:addRelateSkill("tongtian_fankui")
nos_sgkgodsima:addRelateSkill("tongtian_zhiheng")
nos_sgkgodsima:addRelateSkill("tongtian_guanxing")
nos_sgkgodsima:addRelateSkill("tongtian_wansha")


sgs.LoadTranslationTable{
	["nos_sgkgodsima"] = "SK神司马[旧]",
	["&nos_sgkgodsima"] = "神司马懿",
	["~nos_sgkgodsima"] = "生门已闭，唯有赴死……",
	["#nos_sgkgodsima"]= "晋国之祖",
	["nos_sgkgodjilue"] = "极略",
	["$nos_sgkgodjilue1"] = "轻举妄为，徒招横祸。",
	["$nos_sgkgodjilue2"] = "因果有律，世间无常。",
	["$nos_sgkgodjilue3"] = "万物无一，强弱有变。",
	[":nos_sgkgodjilue"] = "出牌阶段，你可以摸一张牌，然后选择一项：1.使用一张牌；2.弃置一张牌。若你以此法弃置牌，此技能于此阶段内无效。",
	["@nos_sgkgodjilue"] = "请使用一张牌，否则你须弃置一张牌，且本回合内【极略】失效。",
	["nos_sgkgodtongtian"] = "通天",
	["$nos_sgkgodtongtian"] = "反乱不除，必生枝节。",
	["@tian"] = "通天",
	[":nos_sgkgodtongtian"] = "<font color=\"red\"><b>限定技。</b></font>出牌阶段，你可以弃置至少一张花色各不相同的牌，然后若你以此法弃置的牌包含：黑桃，获得“反馈”；红桃，获得“观星”；梅花，获得“完杀”；方片，获得“制衡”。",
	["tongtian_fankui"] = "反馈",
	[":tongtian_fankui"] = "每当你受到伤害后，你可以获得来源的一张牌。",
	["$tongtian_fankui"] = "逆势而为，不自量力。",
	["tongtian_guanxing"] = "观星",
	[":tongtian_guanxing"] = "准备阶段，你可以观看牌堆顶的X张牌（X为存活角色数且至多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。",
	["$tongtian_guanxing"] = "吾之身前，万籁俱静。",
	["tongtian_zhiheng"] = "制衡",
	[":tongtian_zhiheng"] = "<font color=\"green\"><b>出牌阶段限一次。</b></font>你可以弃置至少一张牌，然后摸等量的牌。",
	["$tongtian_zhiheng"] = "吾之身后，了无生机。",
	["tongtian_wansha"] = "完杀",
	[":tongtian_wansha"] = "<font color=\"blue\"><b>锁定技。</b></font>在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。",
	["$tongtian_wansha"] = "狂战似魔，深谋如鬼。",
	["designer:nos_sgkgodsima"] = "魂烈",
	["illustrator:nos_sgkgodsima"] = "魂烈",
	["cv:nos_sgkgodsima"] = "魂烈",
}


--SK神夏侯惇
nos_sgkgodxiahoudun = sgs.General(extension, "nos_sgkgodxiahoudun", "sy_god", 5)


--啖睛
nos_sgkgoddanjingCard = sgs.CreateSkillCard{
    name = "nos_sgkgoddanjingCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    room:loseHp(source, 1, true, source, "nos_sgkgoddanjing")
		local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "nos_sgkgoddanjing")
		room:setPlayerMark(target, "danjing_AI", 2)--AI
		local choice = room:askForChoice(source, "nos_sgkgoddanjing", "drawthree+throwthree")
		if choice == "drawthree" then
		    target:drawCards(3)
		else
		    room:askForDiscard(target, "nos_sgkgoddanjing", 3, 3, false, true)
		end
		room:setPlayerMark(target, "danjing_AI", 0)--AI
	end
}

nos_sgkgoddanjing = sgs.CreateViewAsSkillV2{
    name = "nos_sgkgoddanjing",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("nos_sgkgoddanjing")
	end,
	create_card = function(skill, request)
		local card = nos_sgkgoddanjingCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("nos_sgkgoddanjing", instance_id)
			card:setSourceSkill("nos_sgkgoddanjing", instance_id)
		end
		return card
	end,
}


--忠魂
nos_sgkgodzhonghun = sgs.CreateTriggerSkillV2{
    name = "nos_sgkgodzhonghun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		local death = data:toDeath()
		if not death.who or death.who:objectName() ~= player:objectName() then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local my_skills = {}
		local skill_list = player:getVisibleSkillList()
		for _, skill in sgs.qlist(skill_list) do
		    table.insert(my_skills, skill:objectName())
		end
		if #my_skills == 0 then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
		    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:handleAcquireDetachSkills(target, table.concat(my_skills, "|"))
		end
		return false
	end,
}


nos_sgkgodxiahoudun:addSkill(nos_sgkgoddanjing)
nos_sgkgodxiahoudun:addSkill(nos_sgkgodzhonghun)


sgs.LoadTranslationTable{
    ["nos_sgkgodxiahoudun"] = "SK神夏侯惇",
	["&nos_sgkgodxiahoudun"] = "神夏侯惇",
	["#nos_sgkgodxiahoudun"] = "不灭忠候",
	["~nos_sgkgodxiahoudun"] = "我要……亲自向、丞相、谢罪……",
	["nos_sgkgoddanjing"] = "啖睛",
	[":nos_sgkgoddanjing"] = "<font color=\"green\"><b>出牌阶段限一次。</b></font>你可以失去1点体力，然后令一名其他角色摸3张牌或弃置3张牌。",
	["drawthree"] = "令该角色摸3张牌",
	["throwthree"] = "令该角色弃置3张牌",
	["$nos_sgkgoddanjing1"] = "我看见你了！",
	["$nos_sgkgoddanjing2"] = "想走？把人头留下！",
	["$nos_sgkgoddanjing3"] = "父精母血，不可弃之！",
	["nos_sgkgodzhonghun"] = "忠魂",
	[":nos_sgkgodzhonghun"] = "当你死亡时，你可令一名其他角色获得你当前的所有技能。",
	["$nos_sgkgodzhonghun1"] = "都等什么？继续冲！",
	["$nos_sgkgodzhonghun2"] = "还没分出胜负！",
}

--神黄盖
jlsg_shenhuanggai = sgs.General(extension, "jlsg_shenhuanggai", "sy_god", 6, true)

jlsglianti = sgs.CreateTriggerSkillV2{
	name = "jlsglianti",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.ChainStateChange, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.GameStart then
			if player:isChained() then return false end
			return skill:objectName()
		elseif event == sgs.ChainStateChange then
			if not player:isChained() then return false end
			return skill:objectName()
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if not (damage.to and damage.to:objectName() == player:objectName() and damage.nature ~= sgs.DamageStruct_Normal) then return false end
			local names, owners = {}, {}
			if player:hasSkill(skill:objectName()) then
				table.insert(names, skill:objectName())
				table.insert(owners, player:objectName())
			end
			local jlsgshg = room:getCurrent()
			if jlsgshg and jlsgshg:isAlive() and jlsgshg:hasSkill(skill:objectName())
				and jlsgshg:objectName() ~= player:objectName() and not player:hasFlag(skill:objectName()) then
				table.insert(names, skill:objectName())
				table.insert(owners, jlsgshg:objectName())
			end
			if #names == 0 then return false end
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) and not player:isChained() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:speak("弓我还没得，不可能铁索，一体力我都没得~")
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setPlayerChained(player)
			end
		elseif event == sgs.ChainStateChange then
			if player:hasSkill(self:objectName()) and player:isChained() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:speak("弓我还没得，不可能铁索，一体力我都没得~")
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local jlsgshg = room:getCurrent()
			local victim = ctx.invoker or player
			if jlsgshg and jlsgshg:objectName() == player:objectName() and jlsgshg:hasSkill(self:objectName()) then
				if damage.to and damage.to:isAlive() and damage.to:objectName() == victim:objectName() and victim:objectName() ~= jlsgshg:objectName()
				and damage.nature ~= sgs.DamageStruct_Normal and not victim:hasFlag(self:objectName()) then
					room:setPlayerFlag(victim, self:objectName())
					room:sendCompulsoryTriggerLog(jlsgshg, self:objectName())
					jlsgshg:speak("好多的牌，摸 好多的牌哦，全局是闪哎~")
					room:broadcastSkillInvoke(self:objectName(), 2)
					--[[if damage.from:isAlive() then
						room:damage(sgs.DamageStruct(self:objectName(), damage.from, victim, damage.damage, damage.nature))
					else]]
						room:damage(sgs.DamageStruct(self:objectName(), nil, victim, damage.damage, damage.nature))
					--end
				end
			end
			if damage.to and damage.to:isAlive() and damage.to:objectName() == player:objectName() and player:hasSkill(self:objectName())
			and damage.nature ~= sgs.DamageStruct_Normal then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local spk = math.random(0,2)
				if spk == 0 then player:speak("苦肉一次，弓无闪有，弓啊在哪")
				elseif spk == 1 then player:speak("苦肉无数，苦了没奶")
				elseif spk == 2 then player:speak("还拿桃哦，你自己打~")
				end
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:addPlayerMark(player, "&jlsglianti")
				if player:getMark("jlsglianti_hurt_lun") == 0 then
					room:setPlayerMark(player, "jlsglianti_hurt_lun", 1)
					room:loseMaxHp(player, 1)
				end
			end
		end
		return false
	end,
}

--連體標記與旗標結算作用在受標記角色身上；神黃蓋死亡後仍須結算，故以全局隱藏技能承載
jlsgliantiMark = sgs.CreateTriggerSkillV2{
	name = "#jlsglianti_mark",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			return skill:objectName()
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" and player:getMark("&jlsglianti") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("jlsglianti") then
					room:setPlayerFlag(p, "-jlsglianti")
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then
				local n = player:getMark("&jlsglianti")
				draw.num = draw.num + n
				data:setValue(draw)
			end
		end
		return false
	end,
}
jlsgliantiMXC = sgs.CreateMaxCardsSkillV2{
	name = "jlsgliantiMXC",
	holder_selector = sgs.CorrectSkill_System,
	gate = { "mark:&jlsglianti" },
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if not target then return false end
		local n = target:getMark("&jlsglianti")
		if n > 0 then
			return n
		else
			return false
		end
	end,
}
jlsg_shenhuanggai:addSkill(jlsglianti)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("jlsgliantiMXC") then skills:append(jlsgliantiMXC) end
sgs.Sanguosha:addSkills(skills)
jlsgyanlieCard = sgs.CreateSkillCard{
	name = "jlsgyanlieCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local n = self:subcardsLength()
		if #targets == n then return false end
		return to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets == self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
	    local useto = sgs.SPlayerList()
		for _, p in pairs(targets) do
			useto:append(p)
		end
		local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0)
		iron_chain:setSkillName("jlsgyanlie")
		local chain_use = sgs.CardUseStruct(iron_chain, source, useto)
		local no_respond_list = chain_use.no_respond_list
		table.insert(no_respond_list, "_ALL_TARGETS")
		chain_use.no_respond_list = no_respond_list
		room:useCard(chain_use, false)
		iron_chain:deleteLater()
		local yanlieTargets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:isChained() then
				yanlieTargets:append(p)
			end
		end
		if yanlieTargets:isEmpty() then return false end
		local yanlieTarget
		if yanlieTargets:length() == 1 then
			yanlieTarget = yanlieTargets:first()
		else
			yanlieTarget = room:askForPlayerChosen(source, yanlieTargets, "jlsgyanlie")
		end
		local spk2 = math.random(1,4) --if math.random() <= 0.5 then
		if spk2 <= 2 then
			if spk2 == 1 then
				source:speak("原来他们敢打是看你胆大摸完")
			elseif spk2 == 2 then
				source:speak("是苦肉的我拿命给她挡的~")
			end
			room:broadcastSkillInvoke("jlsgyanlie", 1)
		else
			source:speak("没诸葛拿的，不哭我们投哦~")
			room:broadcastSkillInvoke("jlsgyanlie", 2)
		end
		room:damage(sgs.DamageStruct("jlsgyanlie", source, yanlieTarget, 1, sgs.DamageStruct_Fire))
	end,
}
jlsgyanlie = sgs.CreateViewAsSkillV2{
    name = "jlsgyanlie",
	n = 999,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isKongcheng() and not player:hasUsed("jlsgyanlie")
	end,
	can_select_card = function(skill, request, to_select)
		return not to_select:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() > 0
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		local n = #request:getSelectedCardIds()
		return player and candidate and #selected < n and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		local n = #request:getSelectedCardIds()
		return n > 0 and #selected == n
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids == 0 then return nil end
		local ylcard = jlsgyanlieCard:clone()
		for _, id in sgs.qlist(ids) do
			ylcard:addSubcard(id)
		end
		ylcard:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			ylcard:setSkillInstanceId(instance_id)
			ylcard:setActivationSkill("jlsgyanlie", instance_id)
			ylcard:setSourceSkill("jlsgyanlie", instance_id)
		end
		return ylcard
	end,
}
jlsg_shenhuanggai:addSkill(jlsgyanlie)



--

--神华佗
jlsg_shenhuatuo = sgs.General(extension, "jlsg_shenhuatuo", "sy_god", 3, true)

jlsgyuanhua = sgs.CreateTriggerSkillV2{
	name = "jlsgyuanhua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName ~= skill:objectName() then return false end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand
				and player:getMark(skill:objectName()) > 0) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart and player:hasSkill(self:objectName()) then --防止手气卡刷桃卡BUG
			room:setPlayerMark(player, self:objectName(), 1)
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName == self:objectName() then
				room:setPlayerMark(player, self:objectName(), 1)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand
			and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) > 0 then
				for _, id in sgs.qlist(move.card_ids) do
					local peach = sgs.Sanguosha:getCard(id)
					if peach:isKindOf("Peach") then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						if player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player))
						end
						room:drawCards(player, 2, self:objectName())
						player:addToPile(self:objectName(), peach)
					end
				end
			end
		end
		return false
	end,
}

jlsgyuanhuaClear = sgs.CreateTriggerSkillV2{
	name = "#jlsgyuanhua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		if data:toSkillChange().skillName ~= "jlsgyuanhua" then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if data:toSkillChange().skillName == "jlsgyuanhua" then
			room:setPlayerMark(player, "jlsgyuanhua", 0)
		end
		return false
	end,
}
jlsg_shenhuatuo:addSkill(jlsgyuanhua)
extension:insertRelatedSkills("jlsgyuanhua", "#jlsgyuanhua")

local function hasPeach(player)
	if player:isDead() then return false end
	local hP = false
	for _, c in sgs.qlist(player:getHandcards()) do
		if c:isKindOf("Peach") then
			hP = true
			break
		end
	end
	return hP
end
jlsgguiyuanCard = sgs.CreateSkillCard{
    name = "jlsgguiyuanCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    room:loseHp(source, 1, true, source, "jlsgguiyuan")
		if not source:isAlive() then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:isKongcheng() or not hasPeach(p) then continue end
			if p:getState() ~= "online" then
				local gyg = {}
				for _, ph in sgs.qlist(p:getHandcards()) do
					if ph:isKindOf("Peach") then
					table.insert(gyg, ph) end
				end
				local ph_card = gyg[math.random(1, #gyg)]
				room:obtainCard(source, ph_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), "jlsgguiyuan", ""), true)
			else
				local data = sgs.QVariant()
				data:setValue(p)
				local ph_card = room:askForCard(p, "peach", "@jlsgguiyuan-wtgy:" .. source:objectName(), data, sgs.Card_MethodNone)
				if ph_card then
					room:obtainCard(source, ph_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), "jlsgguiyuan", ""), true)
				else
					local gyg = {}
					for _, ph in sgs.qlist(p:getHandcards()) do
						if ph:isKindOf("Peach") then
							table.insert(gyg, ph)
						end
					end
					local ph_card = gyg[math.random(1, #gyg)]
					room:obtainCard(source, ph_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), "jlsgguiyuan", ""), true)
				end
			end
		end
		local rpg = {}
		for _, ph in sgs.qlist(room:getDrawPile()) do
			local tz = sgs.Sanguosha:getCard(ph)
			if tz:isKindOf("Peach") then
				table.insert(rpg, tz)
			end
		end
		for _, ph in sgs.qlist(room:getDiscardPile()) do
			local tz = sgs.Sanguosha:getCard(ph)
			if tz:isKindOf("Peach") then
				table.insert(rpg, tz)
			end
		end
		if #rpg > 0 then
			local phc = rpg[math.random(1, #rpg)]
			room:obtainCard(source, phc, "jlsgguiyuan")
		end
	end,
}
jlsgguiyuan = sgs.CreateViewAsSkillV2{
    name = "jlsgguiyuan",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("jlsgguiyuan")
	end,
	create_card = function(skill, request)
		local card = jlsgguiyuanCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("jlsgguiyuan", instance_id)
			card:setSourceSkill("jlsgguiyuan", instance_id)
		end
		return card
	end,
}
jlsg_shenhuatuo:addSkill(jlsgguiyuan)

jlsgchongsheng = sgs.CreateTriggerSkillV2{
	name = "jlsgchongsheng",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jlsgchongsheng",
	events = {sgs.Dying},
	can_trigger = function(skill, event, room, player, data)
		if player:getMark("@jlsgchongsheng") <= 0 then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local dying = data:toDying()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:loseMark("@jlsgchongsheng")
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("jlsg_shenhuatuo", self:objectName())
			local gy = player:getPile("jlsgyuanhua"):length()
			if gy < 1 then gy = 1 end
			room:setPlayerProperty(dying.who, "maxhp", sgs.QVariant(gy))
			local recover = dying.who:getMaxHp() - dying.who:getHp()
			if recover > 0 then --防极端情况-1
				room:recover(dying.who, sgs.RecoverStruct(player, nil, recover))
			end
			if dying.who:getState() ~= "online" or room:askForSkillInvoke(dying.who, "@jlsgchongsheng-generalChanged", data) then
				local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
				local rv_generals = {}
				for _, name in ipairs(all_generals) do
					local general = sgs.Sanguosha:getGeneral(name)
					if general:getKingdom() == dying.who:getKingdom() then
						table.insert(rv_generals, name)
					end
				end
				if #rv_generals == 0 then return false end --防极端情况-2
				local rv_general, rv = {}, 3
				while rv > 0 and #rv_generals > 0 do
					local cs = rv_generals[math.random(1, #rv_generals)]
					table.insert(rv_general, cs)
					table.removeOne(rv_generals, cs)
					rv = rv - 1
				end
				local generals = table.concat(rv_general, "+")
				local general = room:askForGeneral(dying.who, generals)
				room:changeHero(dying.who, general, false, false, false, true)
				if dying.who:getMaxHp() ~= gy then room:setPlayerProperty(dying.who, "maxhp", sgs.QVariant(gy)) end
				if dying.who:getHp() ~= gy then room:setPlayerProperty(dying.who, "hp", sgs.QVariant(gy)) end
			end
		end
		return false
	end,
}
jlsg_shenhuatuo:addSkill(jlsgchongsheng)

sgs.LoadTranslationTable{
	--神黄盖(SGK)
	["jlsg_shenhuanggai"] = "神黄盖[极略三国]",
	["&jlsg_shenhuanggai"] = "神黄盖",
	["#jlsg_shenhuanggai"] = "破舰炎天",
	["designer:jlsg_shenhuanggai"] = "极略三国",
	["cv:jlsg_shenhuanggai"] = "GK逆天广告",
	["illustrator:jlsg_shenhuanggai"] = "极略三国",
	--炼体
	["jlsglianti"] = "炼体",
	[":jlsglianti"] = "锁定技，你始终横置。其他角色于你的回合内第一次受到属性伤害后，你令其再受到一次此伤害。当你受到属性伤害后，令你的摸牌阶段摸牌数和手牌上限均+1，然后若此伤害是你本轮第一次受到的属性伤害，你减少1点体力上限。",
	["$jlsglianti1"] = "弓我还没得，不可能铁索，一体力我都没得~", --横置
	["$jlsglianti2"] = "好多的牌，摸 好多的牌哦，全局是闪哎~", --二段伤
	["$jlsglianti3"] = "苦肉一次，弓无闪有，弓啊在哪，苦肉无数，苦了没奶，还拿桃哦，你自己打~", --受伤
	--炎烈
	["jlsgyanlie"] = "炎烈",
	[":jlsgyanlie"] = "出牌阶段限一次，你可以弃置至少一张手牌并选择等量的其他角色，视为你对这些角色使用【铁索连环】（不能被【无懈可击】响应），然后对一名横置角色造成1点火焰伤害。",
	["$jlsgyanlie1"] = "原来他们敢打是看你胆大摸完，是苦肉的我拿命给她挡的~",
	["$jlsgyanlie2"] = "没诸葛拿的，不哭我们投哦~",
	--阵亡
	["~jlsg_shenhuanggai"] = "（现在是幻想时间：“莫急，有老夫在此~”羞答答的玫瑰，静悄悄地开~）",

	--神华佗(SGK)
	["jlsg_shenhuatuo"] = "神华佗[极略三国]",
	["&jlsg_shenhuatuo"] = "神华佗",
	["#jlsg_shenhuatuo"] = "桃市垄断", --为什么会这么起，看技能就懂了
	["designer:jlsg_shenhuatuo"] = "极略三国",
	["cv:jlsg_shenhuatuo"] = "极略三国",
	["illustrator:jlsg_shenhuatuo"] = "极略三国",
	--元化
	["jlsgyuanhua"] = "元化",
	[":jlsgyuanhua"] = "锁定技，当你获得【桃】后，你回复1点体力并摸两张牌；然后将此牌置于武将牌上。",
	["$jlsgyuanhua1"] = "两剂服下，自当痊愈。",
	["$jlsgyuanhua2"] = "怎么样，是不是感觉好点儿了？", --所以这语音和技能有半毛钱关系......
	--归元
	["jlsgguiyuan"] = "归元",
	[":jlsgguiyuan"] = "出牌阶段限一次，你可以失去1点体力，令所有其他角色各交给你一张【桃】，然后你从牌堆或弃牌堆获得一张【桃】。",
	["@jlsgguiyuan-wtgy"] = "请将一张【桃】交给%src<br /> 注：若点【取消】，则系统会帮你随机给一张",
	["$jlsgguiyuan"] = "这点小技，怕不足以救天下人吧......", --你是在嘲讽吗
	--重生
	["jlsgchongsheng"] = "重生",
	[":jlsgchongsheng"] = "限定技，当一名角色进入濒死状态时，你可以令其将体力上限调整至X并回复所有体力（X为你通过“元化”移出游戏的牌数且至少为1），" ..
	"然后其可以从随机三张同势力武将牌中选择一张替换之（体力上限与体力值不因此改变）。",
	["@jlsgchongsheng"] = "重生",
	["@jlsgchongsheng-generalChanged"] = "[重生]更换武将",
	["$jlsgchongsheng"] = "快好起来吧，还有人等着你......",
	--阵亡
	["~jlsg_shenhuatuo"] = "别担心，毕竟，也这个岁数了......",
}

new_sgkgodganning = sgs.General(extension, "new_sgkgodganning", "sy_god", 4)
new_sgkgodluezhen = sgs.CreateTriggerSkillV2 {
	name = "new_sgkgodluezhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local damage = data:toDamage()
		if not (damage.from and damage.from:objectName() == player:objectName()) then return false end
		if not (damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and player:canGet(damage.to, "he")) then return false end
		return skill:objectName()
	end,
	on_effect = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not (damage.to and damage.to:isAlive() and player:canGet(damage.to, "he")) then return false end
		if room:askForChoice(player, self:objectName(), "luezhen_getcard+cancel", ctx.original_data) ~= "luezhen_getcard" then return false end
		room:broadcastSkillInvoke(self:objectName())
		local id = room:askForCardChosen(player, damage.to, "he", self:objectName(), false, sgs.Card_MethodGet)
		if not player:canGet(damage.to, id) then return false end
		room:obtainCard(player, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), damage.to:objectName(), self:objectName(), ""), false)
		player:turnOver()
		if not player:faceUp() and room:askForChoice(player, self:objectName(), "luezhen_endturn+cancel") == "luezhen_endturn" then
			room:throwEvent(sgs.TurnBroken)
		end
		return false
	end
}
new_sgkgodyoulong = sgs.CreateTriggerSkillV2{
    name = "new_sgkgodyoulong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	can_trigger = function(skill, event, room, player, data)
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:objectName() ~= player:objectName() then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then return table.concat(names, "|"), table.concat(owners, "|") end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		if ctx.invoker and ctx.invoker:objectName() == player:objectName() then return false end
		room:broadcastSkillInvoke(self:objectName())
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		player:drawCards(1, self:objectName())
		PhaseExtra(player, sgs.Player_Play, true)
		return false
	end,
}

new_sgkgodganning:addSkill(new_sgkgodluezhen)
new_sgkgodganning:addSkill(new_sgkgodyoulong)


sgs.LoadTranslationTable{
    ["new_sgkgodganning"] = "SK神甘宁",
	["&new_sgkgodganning"] = "神甘宁",
	["#new_sgkgodganning"] = "江表之力牧",
	["~new_sgkgodganning"] = "",
	["new_sgkgodluezhen"] = "掠阵",
	[":new_sgkgodluezhen"] = "出牌阶段，当你对其他角色造成伤害后，你可以获得其一张牌并翻面，然后若你武将牌背面向上，你可以结束此回合。",
	["luezhen_getcard"] = "获得其一张牌并翻面",
	["luezhen_endturn"] = "结束此回合",
	["new_sgkgodyoulong"] = "游龙",
	[":new_sgkgodyoulong"] = "锁定技，其他角色的回合开始时，你摸一张牌并进行一个额外的出牌阶段。",

}

--SP神貂蝉
sgkgodspdiaochan = sgs.General(extension, "sgkgodspdiaochan", "sy_god", 1, false)


--[[
	技能名：离魂
	相关武将：SP神貂蝉
	技能描述：回合结束时，你可以选择一名其他角色，该角色执行一个你操纵的额外回合，此回合内，其使用牌无次数与距离限制，且使用牌时可以选择任意角色为目标。
	引用：sgkgodlihun, #sgkgodlihun_clear
	备注：平台不支持转移玩家操控权，改为目标角色自行执行额外回合；“可以选择任意角色为目标”以无次数与距离限制近似（标记经hunlie_tarmod生效，其回合结束时由全局技能清除）。
]]--
sgkgodlihun = sgs.CreateTriggerSkillV2{
	name = "sgkgodlihun",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_NotActive then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@sgkgodlihun-choose", true, true)
		if not (target and target:isAlive()) then return false end
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		room:doAnimate(1, player:objectName(), target:objectName())
		room:setPlayerMark(target, "sgkgodlihun_buff", 1)
		target:gainAnExtraTurn()
		return false
	end,
}


--離魂buff標記掛在被離魂角色身上、於其回合結束時清除，故以全局隱藏技能承載
sgkgodlihunClear = sgs.CreateTriggerSkillV2{
	name = "#sgkgodlihun_clear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getMark("sgkgodlihun_buff") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		room:setPlayerMark(player, "sgkgodlihun_buff", 0)
		return false
	end
}


--[[
	技能名：绝世
	相关武将：SP神貂蝉
	技能描述：锁定技，你的体力上限始终为1。当你进入濒死状态时，你随机使用场上角色手牌或牌堆中的【桃】、【酒】、【梅】，直到你脱离濒死状态或均没有这些牌。
	引用：sgkgodjueshi
]]--
local function sgkgodjueshi_savecard(card)
	return card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:objectName() == "mei"
end

sgkgodjueshi = sgs.CreateTriggerSkillV2{
	name = "sgkgodjueshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MaxHpChange, sgs.EnterDying},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			if change.who and change.who:objectName() == player:objectName() and change.change ~= 0 then
				return skill:objectName()
			end
		elseif event == sgs.EnterDying then
			local dying = data:toDying()
			if dying.who and dying.who:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			change.change = 0
			data:setValue(change)
		elseif event == sgs.EnterDying then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			local used = {}
			while player:isAlive() and player:getHp() <= 0 do
				local pool = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, c in sgs.qlist(p:getHandcards()) do
						if sgkgodjueshi_savecard(c) and not used[c:getEffectiveId()] then table.insert(pool, c) end
					end
				end
				if #pool == 0 then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local c = sgs.Sanguosha:getCard(id)
						if sgkgodjueshi_savecard(c) and not used[id] then table.insert(pool, c) end
					end
				end
				if #pool == 0 then break end
				local card = pool[math.random(1, #pool)]
				used[card:getEffectiveId()] = true
				room:useCard(sgs.CardUseStruct(card, player, player))
			end
		end
		return false
	end,
}


sgkgodspdiaochan:addSkill(sgkgodlihun)
sgkgodspdiaochan:addSkill(sgkgodjueshi)


sgs.LoadTranslationTable{
	["sgkgodspdiaochan"] = "SP神貂蝉",
	["&sgkgodspdiaochan"] = "神貂蝉",
	["#sgkgodspdiaochan"] = "绝世的舞姬",
	["~sgkgodspdiaochan"] = "",
	["sgkgodlihun"] = "离魂",
	[":sgkgodlihun"] = "回合结束时，你可以选择一名其他角色，该角色执行一个你操纵的额外回合，此回合内，其使用牌无次数与距离限制，且使用牌时可以选择任意角色为目标。",
	["@sgkgodlihun-choose"] = "离魂：令一名其他角色执行一个由你操纵的额外回合",
	["sgkgodjueshi"] = "绝世",
	[":sgkgodjueshi"] = "锁定技，你的体力上限始终为1。当你进入濒死状态时，你随机使用场上角色手牌或牌堆中的【桃】、【酒】、【梅】，直到你脱离濒死状态或均没有这些牌。",
	["designer:sgkgodspdiaochan"] = "极略三国",
	["illustrator:sgkgodspdiaochan"] = "极略三国",
	["cv:sgkgodspdiaochan"] = "极略三国",
}


--神周泰
sgkgodzhoutai = sgs.General(extension, "sgkgodzhoutai", "sy_god", 10, true)


--[[
	技能名：战魂
	相关武将：神周泰
	技能描述：锁定技，当你受到其他角色对你施加的负面效果时，你将此效果改为失去X点体力并摸两张牌（X为你本回合内已发动此技能的次数）；
	然后若这两张牌颜色不同/均为红色/均为黑色，你可以视为使用一张无次数与距离限制的【杀】/火【杀】/雷【杀】。
	当你使用【杀】对体力值不小于你的其他角色造成伤害时，你回复1点体力。
	引用：sgkgodzhanhun
	备注：负面效果沿用魔孟获「魔兽-熊」同一套判定（DamageInflicted伤害/PreHpLost失去体力/MaxHpChange减上限/
	BeforeCardsMove被弃置牌/MarkChange技能失效标记/ChainStateChange横置/TurnOver翻面/EventLoseSkill失去技能）；
	减上限、横置、翻面无来源信息，一律转化；转化产生的失去体力来源为自己，不会连环触发。
	摸到的两张实体牌经drawCardsList取得后判定颜色，再自选目标视为使用对应杀（m_addHistory=false、onUse直出，自带无次数与距离限制）。
]]--
sgkgodzhanhun = sgs.CreateTriggerSkillV2{
	name = "sgkgodzhanhun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.PreHpLost, sgs.MaxHpChange, sgs.BeforeCardsMove, sgs.MarkChange, sgs.ChainStateChange, sgs.TurnOver, sgs.EventLoseSkill, sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage > 0 and damage.to and damage.to:objectName() == player:objectName()
				and damage.from and damage.from:objectName() ~= player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			if lose.lose > 0 and lose.from and lose.from:objectName() ~= player:objectName() then
				return skill:objectName()
			end
		elseif event == sgs.MaxHpChange then
			if data:toMaxHp().change < 0 then return skill:objectName() end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
				and move.to_place == sgs.Player_DiscardPile
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and move.card_ids:length() > 0
				and ((move.reason.m_playerId and move.reason.m_playerId ~= player:objectName()) or player:getPhase() == sgs.Player_NotActive) then
				return skill:objectName()
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) then
				return skill:objectName()
			end
		elseif event == sgs.ChainStateChange then
			if not player:isChained() then return skill:objectName() end
		elseif event == sgs.TurnOver then
			if player:faceUp() then return skill:objectName() end
		elseif event == sgs.EventLoseSkill then
			if player:isAlive() then return skill:objectName() end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.damage > 0
				and damage.from and damage.from:objectName() == player:objectName()
				and damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName()
				and damage.to:getHp() >= player:getHp() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damage then
			local damage = data:toDamage()
			if not (damage.to and damage.to:isAlive() and damage.to:getHp() >= player:getHp()) then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			local rec = sgs.RecoverStruct()
			rec.recover = 1
			rec.who = player
			room:recover(player, rec, true)
			return false
		end
		local negated = false
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if not (damage.damage > 0 and damage.to and damage.to:objectName() == player:objectName()
				and damage.from and damage.from:objectName() ~= player:objectName()) then return false end
			negated = true
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			if not (lose.lose > 0 and lose.from and lose.from:objectName() ~= player:objectName()) then return false end
			negated = true
		elseif event == sgs.MaxHpChange then
			if data:toMaxHp().change >= 0 then return false end
			negated = true
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if not (move.from and move.from:objectName() == player:objectName()
				and move.to_place == sgs.Player_DiscardPile
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and move.card_ids:length() > 0) then return false end
			move.card_ids = sgs.IntList()
			data:setValue(move)
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			if not (mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu"))) then return false end
			negated = true
		elseif event == sgs.ChainStateChange then
			if player:isChained() then return false end
			negated = true
		elseif event == sgs.TurnOver then
			if not player:faceUp() then return false end
			negated = true
		elseif event == sgs.EventLoseSkill then
			player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
			room:addPlayerMark(player, data:toSkillChange().skillName .. "_temp_skill")
			room:handleAcquireDetachSkills(player, data:toString())
			room:setPlayerMark(player, data:toString() .. "_temp_skill", 0)
		end
		room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
		local x = player:getMark("sgkgodzhanhun_count-Clear")
		room:addPlayerMark(player, "sgkgodzhanhun_count-Clear")
		if x > 0 then room:loseHp(player, x, true, player, self:objectName()) end
		local slash_name = nil
		local drawn = player:drawCardsList(2, self:objectName())
		if drawn and drawn:length() == 2 then
			local c1 = sgs.Sanguosha:getCard(drawn:at(0))
			local c2 = sgs.Sanguosha:getCard(drawn:at(1))
			if c1:isRed() and c2:isRed() then
				slash_name = "fire_slash"
			elseif c1:isBlack() and c2:isBlack() then
				slash_name = "thunder_slash"
			else
				slash_name = "slash"
			end
		end
		if slash_name and player:isAlive() then
			local zhanhun_slash = sgs.Sanguosha:cloneCard(slash_name, sgs.Card_NoSuit, 0)
			zhanhun_slash:setSkillName("_sgkgodzhanhun")
			local zhanhun_targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p, nil, false) then zhanhun_targets:append(p) end
			end
			if not zhanhun_targets:isEmpty() then
				local target = room:askForPlayerChosen(player, zhanhun_targets, self:objectName(), "@sgkgodzhanhun-slash", true, true)
				if target then
					local to = sgs.SPlayerList()
					to:append(target)
					local new_use = sgs.CardUseStruct()
					new_use.from = player
					new_use.to = to
					new_use.card = zhanhun_slash
					new_use.m_addHistory = false
					zhanhun_slash:onUse(room, new_use)
				end
			end
			zhanhun_slash:deleteLater()
		end
		return negated
	end
}


sgkgodzhoutai:addSkill(sgkgodzhanhun)


sgs.LoadTranslationTable{
    ["sgkgodzhoutai"] = "神周泰",
	["&sgkgodzhoutai"] = "神周泰",
	["#sgkgodzhoutai"] = "不灭战魂",
	["~sgkgodzhoutai"] = "",
	["sgkgodzhanhun"] = "战魂",
	[":sgkgodzhanhun"] = "锁定技，当你受到其他角色对你施加的负面效果时，你将此效果改为失去X点体力并摸两张牌（X为你本回合内已发动此技能的次数）；"..
	"然后若这两张牌颜色不同/均为红色/均为黑色，你可以视为使用一张无次数与距离限制的【杀】/火【杀】/雷【杀】。"..
	"当你使用【杀】对体力值不小于你的其他角色造成伤害时，你回复1点体力。",
	["@sgkgodzhanhun-slash"] = "战魂：你可以视为对一名其他角色使用一张【杀】",
	["designer:sgkgodzhoutai"] = "极略三国",
	["illustrator:sgkgodzhoutai"] = "极略三国",
	["cv:sgkgodzhoutai"] = "极略三国",
}


--神祝融
sgkgodzhurong = sgs.General(extension, "sgkgodzhurong", "sy_god", 5, false)


--[[
	技能名：炎锋
	相关武将：神祝融
	技能描述：你可以将一张牌当作火【杀】使用。当你使用火【杀】指定目标后，若此牌：为红色，你令此牌不计入次数且伤害+1；
	实体牌为【杀】，此牌无视防具且不能被响应。若你使用火【杀】未造成伤害，你对自己造成1点火焰伤害。
	当你受到1点火焰伤害后，你摸两张牌。
	引用：sgkgodyanfeng
	备注：转化走ViewAsSkill；「实体牌为【杀】」按实体火杀或转化子牌中含【杀】判定（与专栏「用红杀转化可同吃两效果」一致）。
	不计入次数沿用addPlayerHistory(-1)+m_addHistory=false；无视防具用addQinggangTag；不能被响应用Jink_目标清零；
	未造成伤害以卡面flag标记DamageCaused是否发生过，CardFinished时结算自伤。受火焰伤害摸牌按每次伤害事件计。
]]--
local function sgkgodyanfeng_entity_slash(card)
	if card:subcardsLength() == 0 then return card:isKindOf("Slash") end
	for _, id in sgs.qlist(card:getSubcards()) do
		if sgs.Sanguosha:getCard(id):isKindOf("Slash") then return true end
	end
	return false
end

sgkgodyanfengvs = sgs.CreateViewAsSkillV2{
	name = "sgkgodyanfeng",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, to_select)
		local player = request:getInitiator()
		if not player then return false end
		if #request:getSelectedCardIds() >= 1 then return false end
		local fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		fire:addSubcard(to_select:getEffectiveId())
		fire:deleteLater()
		return not player:isJilei(fire)
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids == 0 then return nil end
		local yf_fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		for _, id in sgs.qlist(ids) do
			yf_fire:addSubcard(id)
		end
		yf_fire:setSkillName(skill:objectName())
		local instance_id = request:getActivationInstanceId()
		if instance_id > 0 then
			yf_fire:setSkillInstanceId(instance_id)
			yf_fire:setActivationSkill("sgkgodyanfeng", instance_id)
			yf_fire:setSourceSkill("sgkgodyanfeng", instance_id)
		end
		return yf_fire
	end,
}

sgkgodyanfeng = sgs.CreateTriggerSkillV2{
	name = "sgkgodyanfeng",
	view_as_skill = sgkgodyanfengvs,
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card and use.card:isKindOf("FireSlash")
				and (use.card:isRed() or sgkgodyanfeng_entity_slash(use.card)) then
				return skill:objectName()
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.damage > 0
				and damage.card and damage.card:isKindOf("FireSlash") then
				return skill:objectName()
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card and use.card:isKindOf("FireSlash")
				and not use.card:hasFlag("sgkgodyanfeng_damaged") then
				return skill:objectName()
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and damage.damage > 0
				and damage.nature == sgs.DamageStruct_Fire then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			room:notifySkillInvoked(player, self:objectName())
			if use.card:isRed() then
				if use.m_addHistory then
					room:addPlayerHistory(player, use.card:getClassName(), -1)
					use.m_addHistory = false
					data:setValue(use)
				end
			end
			if sgkgodyanfeng_entity_slash(use.card) then
				for _, t in sgs.qlist(use.to) do
					t:addQinggangTag(use.card)
				end
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, t in sgs.qlist(use.to) do
					jink_table[index] = 0
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card then room:setCardFlag(damage.card, "sgkgodyanfeng_damaged") end
			if damage.card and damage.card:isRed() and (not damage.chain) and (not damage.transfer) then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#YanfengBuff"
				msg.card_str = damage.card:toString()
				msg.arg = tostring(damage.damage)
				msg.arg2 = tostring(damage.damage + 1)
				room:sendLog(msg)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card:hasFlag("sgkgodyanfeng_damaged") and player:isAlive() then
				room:notifySkillInvoked(player, self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, player, 1, sgs.DamageStruct_Fire))
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and damage.damage > 0
				and damage.nature == sgs.DamageStruct_Fire then
				room:addPlayerMark(player, "sgkgodshenji_firedmg")
				player:drawCards(2, self:objectName())
			end
		end
		return false
	end
}


--[[
	技能名：神祭
	相关武将：神祝融
	技能描述：出牌阶段限一次，若你于未发动此技能前或上次发动此技能后受到过火焰伤害，你可以减若干点体力上限并选择等量角色，
	你对这些角色各造成X点火焰伤害（X为其体力上限）。
	引用：sgkgodshenji
	备注：以标记sgkgodshenji_firedmg记录「上次发动后（或开局以来）是否受过火焰伤害」，于炎锋受火伤分支写入；
	发动流程为先选点数、再选等量角色、最后减上限并依次结算伤害（先选角避免减上限致死无法询问）。
]]--
sgkgodshenjiCard = sgs.CreateSkillCard{
	name = "sgkgodshenjiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local others = room:getOtherPlayers(source)
		local max_n = math.min(source:getMaxHp(), others:length())
		if max_n <= 0 then return false end
		local choices = {}
		for i = 1, max_n do
			table.insert(choices, "shenji_num" .. i)
		end
		local choice = room:askForChoice(source, "sgkgodshenji", table.concat(choices, "+"))
		local n = tonumber(string.match(choice, "%d+"))
		if not n or n <= 0 then return false end
		local chosen = room:askForPlayersChosen(source, others, "sgkgodshenji", n, n, "@sgkgodshenji-choose:" .. n)
		room:setPlayerMark(source, "sgkgodshenji_firedmg", 0)
		room:loseMaxHp(source, n)
		for _, t in sgs.qlist(chosen) do
			if t:isAlive() then
				room:damage(sgs.DamageStruct("sgkgodshenji", source, t, t:getMaxHp(), sgs.DamageStruct_Fire))
			end
		end
	end
}

sgkgodshenji = sgs.CreateViewAsSkillV2{
	name = "sgkgodshenji",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("sgkgodshenji")
			and player:getMark("sgkgodshenji_firedmg") > 0
	end,
	create_card = function(skill, request)
		local instance_id = request:getActivationInstanceId()
		local card = sgkgodshenjiCard:clone()
		card:setSkillInstanceId(instance_id)
		card:setActivationSkill("sgkgodshenji", instance_id)
		card:setSourceSkill("sgkgodshenji", instance_id)
		return card
	end
}


sgkgodzhurong:addSkill(sgkgodyanfeng)
sgkgodzhurong:addSkill(sgkgodshenji)


sgs.LoadTranslationTable{
    ["sgkgodzhurong"] = "神祝融",
	["&sgkgodzhurong"] = "神祝融",
	["#sgkgodzhurong"] = "燎原火神",
	["~sgkgodzhurong"] = "",
	["sgkgodyanfeng"] = "炎锋",
	[":sgkgodyanfeng"] = "你可以将一张牌当作火【杀】使用。当你使用火【杀】指定目标后，若此牌：为红色，你令此牌不计入次数且伤害+1；"..
	"实体牌为【杀】，此牌无视防具且不能被响应。若你使用火【杀】未造成伤害，你对自己造成1点火焰伤害。当你受到1点火焰伤害后，你摸两张牌。",
	["#YanfengBuff"] = "由于“<font color = 'yellow'><b>炎锋</b></font>”的效果，%from 使用的 %card 造成的伤害从 %arg 点增加至 %arg2 点",
	["sgkgodshenji"] = "神祭",
	[":sgkgodshenji"] = "出牌阶段限一次，若你于未发动此技能前或上次发动此技能后受到过火焰伤害，你可以减若干点体力上限并选择等量角色，你对这些角色各造成X点火焰伤害（X为其体力上限）。",
	["@sgkgodshenji-choose"] = "神祭：选择 %arg 名角色，你对其各造成等同于其体力上限的火焰伤害",
	["shenji_num1"] = "减1点体力上限",
	["shenji_num2"] = "减2点体力上限",
	["shenji_num3"] = "减3点体力上限",
	["shenji_num4"] = "减4点体力上限",
	["shenji_num5"] = "减5点体力上限",
	["shenji_num6"] = "减6点体力上限",
	["shenji_num7"] = "减7点体力上限",
	["shenji_num8"] = "减8点体力上限",
	["shenji_num9"] = "减9点体力上限",
	["shenji_num10"] = "减10点体力上限",
	["designer:sgkgodzhurong"] = "极略三国",
	["illustrator:sgkgodzhurong"] = "极略三国",
	["cv:sgkgodzhurong"] = "极略三国",
}


--神孙策
sgkgodsunce = sgs.General(extension, "sgkgodsunce", "sy_god", 4)


--[[
	技能名：冯河
	相关武将：神孙策
	技能描述：当其他角色使用【杀】或普通基本牌指定你为目标后，或当你使用这些牌指定其他角色为目标后，
	你可以令目标角色与使用者中手牌数最少的角色摸三张牌；然后本回合内以此法获得牌的其他角色不能使用或打出这些牌、
	本回合弃牌阶段内其不能弃置这些牌。
	引用：sgkgodfenghe, #sgkgodfenghe_limit
	备注：按原文「【杀】或普通基本牌」处理（Slash或BasicCard）；手牌最少并列则同摸；
	牌面限制以标记sgkgodfenghe_card_{id}-Clear＋全局CardLimitSkill实现，弃置限制只在该角色本回合弃牌阶段生效。
]]--
sgkgodfenghe_limit = sgs.CreateCardLimitSkill{
	name = "#sgkgodfenghe_limit",
	limit_list = function(self, player)
		local room = player:getRoom()
		local current = room and room:getCurrent()
		if current and current:objectName() == player:objectName() and current:getPhase() == sgs.Player_Discard then
			return "use,response,discard"
		end
		return "use,response"
	end,
	limit_pattern = function(self, player, card)
		if not card then return "" end
		if player:getMark("sgkgodfenghe_card_" .. card:getEffectiveId() .. "-Clear") > 0 then
			return card:toString()
		end
		return ""
	end,
}

sgkgodfenghe = sgs.CreateTriggerSkillV2{
	name = "sgkgodfenghe",
	events = {sgs.TargetSpecified, sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.from and use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("BasicCard"))) then return false end
		if use.card:hasFlag("sgkgodfenghe_done_" .. player:objectName()) then return false end
		if event == sgs.TargetSpecified then
			if use.from:objectName() ~= player:objectName() then return false end
			local has_other = false
			for _, t in sgs.qlist(use.to) do
				if t:objectName() ~= player:objectName() then has_other = true break end
			end
			if not has_other then return false end
		elseif event == sgs.TargetConfirmed then
			if use.from:objectName() == player:objectName() or not use.to:contains(player) then return false end
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		room:setCardFlag(use.card, "sgkgodfenghe_done_" .. player:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local candidates = {}
		for _, t in sgs.qlist(use.to) do
			if t:isAlive() then table.insert(candidates, t) end
		end
		if use.from and use.from:isAlive() then
			local dup = false
			for _, t in ipairs(candidates) do
				if t:objectName() == use.from:objectName() then dup = true break end
			end
			if not dup then table.insert(candidates, use.from) end
		end
		local min_n = nil
		for _, t in ipairs(candidates) do
			local h = t:getHandcardNum()
			if not min_n or h < min_n then min_n = h end
		end
		if not min_n then return false end
		for _, t in ipairs(candidates) do
			if t:getHandcardNum() == min_n then
				local before = {}
				for _, c in sgs.qlist(t:getHandcards()) do before[c:getEffectiveId()] = true end
				t:drawCards(3, self:objectName())
				if t:objectName() ~= player:objectName() then
					for _, c in sgs.qlist(t:getHandcards()) do
						local id = c:getEffectiveId()
						if not before[id] then
							room:addPlayerMark(t, "sgkgodfenghe_card_" .. id .. "-Clear")
							if not t:hasSkill("#sgkgodfenghe_limit") then
								room:acquireSkill(t, "#sgkgodfenghe_limit")
							end
						end
					end
				end
			end
		end
		return false
	end,
}


--[[
	技能名：覆海
	相关武将：神孙策
	技能描述：蓄力技（2/5），当你令其他角色摸牌后，你获得1点蓄力点。出牌阶段，你可以消耗5点蓄力点，
	将一名其他角色的所有手牌洗入牌堆并摸与这些牌等量的牌，本回合内你以此法获得的【杀】无次数限制，
	然后你弃置本次洗入牌堆的牌并对该角色造成与弃牌数等量的伤害。
	引用：sgkgodfuhai, sgkgodfuhaiVS, sgkgodfuhaiCard
	备注：「令其他角色摸牌」以移动reason归属判定（m_playerId为你或m_skillName为你拥有的技能）；
	弃置本次洗入的牌按「洗入id∩摸后手牌」计算（专栏：正好摸到洗入的牌才弃），伤害为弃牌数；
	杀无次数限制以sgkgodfuhai_slash_{id}-Clear标记＋TargetSpecified时addPlayerHistory(-1)+m_addHistory=false实现。
]]--
local function sgkgodfuhai_xulimax(player)
	local n = 0
	for _, sk in sgs.qlist(player:getVisibleSkillList()) do
		local cn = sk:property("ChargeNum"):toString()
		if cn ~= "" and cn:match("/") then
			n = n + (tonumber(cn:split("/")[2]) or 0)
		end
	end
	return n
end

sgkgodfuhaiCard = sgs.CreateSkillCard{
	name = "sgkgodfuhaiCard",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local source, target = effect.from, effect.to
		local room = source:getRoom()
		source:loseMark("&charge_num", 5)
		local shuffled = {}
		local ids = sgs.IntList()
		for _, c in sgs.qlist(target:getHandcards()) do
			local id = c:getEffectiveId()
			ids:append(id)
			shuffled[id] = true
		end
		local n = ids:length()
		if n > 0 then
			room:shuffleIntoDrawPile(source, ids, "sgkgodfuhai", false)
		end
		local before = {}
		for _, c in sgs.qlist(source:getHandcards()) do before[c:getEffectiveId()] = true end
		source:drawCards(n, "sgkgodfuhai")
		local to_discard = sgs.IntList()
		for _, c in sgs.qlist(source:getHandcards()) do
			local id = c:getEffectiveId()
			if not before[id] then
				room:addPlayerMark(source, "sgkgodfuhai_slash_" .. id .. "-Clear")
				if shuffled[id] then to_discard:append(id) end
			end
		end
		local count = to_discard:length()
		if count > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			dummy:deleteLater()
			dummy:addSubcards(to_discard)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sgkgodfuhai", "")
			room:throwCard(dummy, reason, source)
			if target:isAlive() then
				room:damage(sgs.DamageStruct("sgkgodfuhai", source, target, count))
			end
		end
	end,
}

sgkgodfuhaiVS = sgs.CreateViewAsSkillV2{
	name = "sgkgodfuhai",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("&charge_num") >= 5
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	create_card = function(skill, request)
		local card = sgkgodfuhaiCard:clone()
		local instance_id = request:getActivationInstanceId()
		if card and instance_id > 0 then
			card:setSkillInstanceId(instance_id)
			card:setActivationSkill("sgkgodfuhai", instance_id)
			card:setSourceSkill("sgkgodfuhai", instance_id)
		end
		return card
	end,
}

sgkgodfuhai = sgs.CreateTriggerSkillV2{
	name = "sgkgodfuhai",
	view_as_skill = sgkgodfuhaiVS,
	events = {sgs.CardsMoveOneTime, sgs.TargetSpecified},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName()
				and move.to_place == sgs.Player_PlaceHand
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
					or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
				local sn = move.reason.m_skillName
				if move.reason.m_playerId == player:objectName() or (sn and sn ~= "" and player:hasSkill(sn)) then
					return skill:objectName()
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card and use.card:isKindOf("Slash") then
				local ids = {}
				if use.card:subcardsLength() == 0 then
					table.insert(ids, use.card:getEffectiveId())
				else
					for _, id in sgs.qlist(use.card:getSubcards()) do table.insert(ids, id) end
				end
				for _, id in ipairs(ids) do
					if player:getMark("sgkgodfuhai_slash_" .. id .. "-Clear") > 0 then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardsMoveOneTime then
			if player:getMark("&charge_num") < sgkgodfuhai_xulimax(player) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:gainMark("&charge_num")
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.m_addHistory then
				room:notifySkillInvoked(player, self:objectName())
				room:addPlayerHistory(player, use.card:getClassName(), -1)
				use.m_addHistory = false
				data:setValue(use)
			end
		end
		return false
	end,
}
sgkgodfuhai:setProperty("ChargeNum", sgs.QVariant("2/5"))


sgkgodsunce:addSkill(sgkgodfenghe)
sgkgodsunce:addSkill(sgkgodfuhai)


sgs.LoadTranslationTable{
	["sgkgodsunce"] = "神孙策",
	["&sgkgodsunce"] = "神孙策",
	["#sgkgodsunce"] = "踞江鬼雄",
	["~sgkgodsunce"] = "",
	["sgkgodfenghe"] = "冯河",
	[":sgkgodfenghe"] = "当其他角色使用【杀】或普通基本牌指定你为目标后，或当你使用这些牌指定其他角色为目标后，你可以令目标角色与使用者中手牌数最少的角色摸三张牌；然后本回合内以此法获得牌的其他角色不能使用或打出这些牌、本回合弃牌阶段内其不能弃置这些牌。",
	["sgkgodfuhai"] = "覆海",
	[":sgkgodfuhai"] = "蓄力技（2/5），当你令其他角色摸牌后，你获得1点蓄力点。出牌阶段，你可以消耗5点蓄力点，将一名其他角色的所有手牌洗入牌堆并摸与这些牌等量的牌，本回合内你以此法获得的【杀】无次数限制，然后你弃置本次洗入牌堆的牌并对该角色造成与弃牌数等量的伤害。",
	["charge_num"] = "蓄力",
	["designer:sgkgodsunce"] = "极略三国",
	["illustrator:sgkgodsunce"] = "极略三国",
	["cv:sgkgodsunce"] = "极略三国",
}


--延後定義的全局技能在此註冊（定義位置晚於 sgkgodhidden 註冊段）
local hunlie_late_global = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sgkgoddawu_fog") then hunlie_late_global:append(sgkgoddawuFog) end
if not sgs.Sanguosha:getSkill("#sgkgodluoyan_mark") then hunlie_late_global:append(sgkgodluoyanMark) end
if not sgs.Sanguosha:getSkill("#sgkgodzhenhun_clear") then hunlie_late_global:append(sgkgodzhenhunClear) end
if not sgs.Sanguosha:getSkill("#tongtian_wansha_clear") then hunlie_late_global:append(tongtian_wanshaClear) end
if not sgs.Sanguosha:getSkill("#sgkgodliangyuan_check") then hunlie_late_global:append(sgkgodliangyuan_check) end
if not sgs.Sanguosha:getSkill("#sgkgodliangyuan_exgive") then hunlie_late_global:append(sgkgodliangyuan_exgive) end
if not sgs.Sanguosha:getSkill("#sgkgodluncexia") then hunlie_late_global:append(sgkgodluncexia) end
if not sgs.Sanguosha:getSkill("#sgkgodluncezhong") then hunlie_late_global:append(sgkgodluncezhong) end
if not sgs.Sanguosha:getSkill("#sgkgodlunceshang") then hunlie_late_global:append(sgkgodlunceshang) end
if not sgs.Sanguosha:getSkill("#sgkgodmeixinClear") then hunlie_late_global:append(sgkgodmeixinClear) end
if not sgs.Sanguosha:getSkill("#sgkgodweizhen_mark") then hunlie_late_global:append(sgkgodweizhenMark) end
if not sgs.Sanguosha:getSkill("#jlsglianti_mark") then hunlie_late_global:append(jlsgliantiMark) end
if not sgs.Sanguosha:getSkill("#sgkgodlihun_clear") then hunlie_late_global:append(sgkgodlihunClear) end
if not sgs.Sanguosha:getSkill("#sgkgodfenghe_limit") then hunlie_late_global:append(sgkgodfenghe_limit) end
sgs.Sanguosha:addSkills(hunlie_late_global)

--V2 全局技能需要實例先會被調度；此處先為全部武將掛 innate 實例，
--結算時再由 on_record 的 hunlie_ensure_global_instances 補掛 acquired 實例
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	for _, skill_name in ipairs(hunlie_global_skill_names) do
		gen:addSkill(skill_name)
	end
end

return {extension}
