extension = sgs.Package("hunliesp", sgs.Package_GeneralPack)


sgs.LoadTranslationTable{
	["hunliesp"] = "极略SP神",
}

do
    require  "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	        table.insert(kingdoms, "sy_god")
	config.kingdom_colors["sy_god"] = "#74029D"
end


sgs.LoadTranslationTable{
	["sy_god"] = "神",
}


--随机选取N个不同元素
function randomGetN(current_table, count)
	local new = {}
	if type(current_table) == "table" then
		for i = 1, math.min(count, #current_table) do
			local ri = math.random(i, #current_table)
			local tmp = current_table[i]
			current_table[i] = current_table[ri]
			current_table[ri] = tmp
		end
		for i = 1, count, 1 do
			table.insert(new, current_table[i])
		end
	end
	return new
end


function forbidSkills(skill_name, duration, exe, vic, random_bool, num)  --发起封禁技能的名称，持续时间，谁发起封技能，谁被封技能，是否随机封技能，封几个技能
	local room = sgs.Sanguosha:currentRoom()
	local skills, to_invalid = {}, {}
	for _, sk in sgs.qlist(vic:getVisibleSkillList()) do
		table.insert(skills, sk:objectName())
	end
	if num == "all" then
		to_invalid = skills
		vic:setTag("_hunlieforbid", sgs.QVariant(-99))
	else
		if type(num) == "number" and num > 0 then
			if random_bool == true then
				to_invalid = randomGetN(skills, num)
			elseif random_bool == false then
				if #skills > 0 and type(skill_name) == "string" then
					for i = 1, math.max(#skills, num) do
						local to_forbid = room:askForChoice(exe, skill_name, table.concat(skills, "+"), sgs.QVariant(), table.concat(to_invalid, "+"))
						table.removeOne(skills, to_forbid)
						table.insert(to_invalid, to_forbid)
						if #skills == 0 then break end
					end
				end
			end
			vic:setTag("_hunlieforbid", sgs.QVariant(num))
		end
	end
	if duration == 0 then  --如果封禁持续一回合
		if type(skill_name) == "string" then room:addPlayerMark(vic, skill_name.."_hunlieforbid-SelfClear") end
	elseif duration == 1 then  --如果封禁持续一轮
		if type(skill_name) == "string" then room:addPlayerMark(vic, skill_name.."_hunlieforbid_lun") end
	elseif duration == -1 then  --如果永久封禁
		if type(skill_name) == "string" then room:addPlayerMark(vic, skill_name.."_hunlieforbid") end
	end
	if #to_invalid > 0 then
		vic:setTag("Qingcheng", sgs.QVariant(table.concat(to_invalid, "+")))
		for _, skill_qc in ipairs(to_invalid) do
			room:addPlayerMark(vic, "Qingcheng"..skill_qc)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(p, p:getCards("he"), true)
			end
		end
	end
end


function activateAllSkills(vic)
	local room = sgs.Sanguosha:currentRoom()
	local qclist = vic:getTag("Qingcheng"):toString():split("+")
	if #qclist > 0 then
		for _, sk in ipairs(qclist) do
			room:setPlayerMark(vic, "Qingcheng"..sk, 0)
		end
		vic:removeTag("Qingcheng")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:filterCards(p, p:getCards("he"), true)
		end
	end
end


function throwRandomCards(random_bool, thrower, victim, n, flag, skill)  --随机弃置一定数量的牌，魔孙皓专用
	local room = sgs.Sanguosha:currentRoom()
	local x = victim:getCards(flag):length()
	local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
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
end

--是不是机关技能
function isSchemeSkill(skill_name)
	return string.find(skill_name, "sgkgodjiguan_")
end

--全局配置类技能
shajue_slash = sgs.CreateTriggerSkill{
	name = "shajue_slash",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end
}

jl_sgkgodlangxi = sgs.CreateTriggerSkill{
	name = "jl_sgkgodlangxi",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end
}

sgkgodmaxcards = sgs.CreateMaxCardsSkill{
	name = "#sgkgodmaxcards",
	extra_func = function(self, target)
		local n = 0
		return n
	end
}

yinyang_lose = sgs.CreateTriggerSkill{
	name = "#yinyang_lose",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if data:toString() == "sgkgodjiyang" then
			if player:getMark("&jiyang_positive") > 0 then
				local x = player:getMark("&jiyang_positive")
				player:loseAllMarks("&jiyang_positive")
				local red_cards, cards = {}, room:getDrawPile()
				if not cards:isEmpty() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isRed() then table.insert(red_cards, card) end
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				dummy:deleteLater()
				for i = 1, x do
					local j = math.random(1, #red_cards)
					dummy:addSubcard(red_cards[j])
					table.removeOne(red_cards, red_cards[j])
					if #red_cards == 0 then break end
				end
				if dummy:subcardsLength() > 0 then room:obtainCard(player, dummy, false) end
			end
		end
		if data:toString() == "sgkgodjiyin" then
			if player:getMark("&jiyin_negative") > 0 then
				local x = player:getMark("&jiyin_negative")
				player:loseAllMarks("&jiyin_negative")
				local black_cards, cards = {}, room:getDrawPile()
				if not cards:isEmpty() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isBlack() then table.insert(black_cards, card) end
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				dummy:deleteLater()
				for i = 1, x do
					local j = math.random(1, #black_cards)
					dummy:addSubcard(black_cards[j])
					table.removeOne(black_cards, black_cards[j])
					if #black_cards == 0 then break end
				end
				if dummy:subcardsLength() > 0 then room:obtainCard(player, dummy, false) end
			end
		end
		if data:toString() == "sgkgodxiangsheng" then
			if player:getMark("&xiangsheng_balance") > 0 then 
				local x = player:getMark("&xiangsheng_balance")
				player:loseAllMarks("&xiangsheng_balance")
				player:drawCards(x, "sgkgodxiangsheng")
			end
		end
	end
}

hunliesp_global_drawcards = sgs.CreateDrawCardsSkill{
	name = "#hunliesp_global_drawcards",
	global = true,
	draw_num_func = function(self, player, n)
		local room = player:getRoom()
		local x = 0
		for _, t in sgs.qlist(room:getAllPlayers()) do
			if t:hasSkill("sgkgodzhiti") then
				local enabled_items = player:property("_ZhitiEnabled"):toString():split("+")
				if #enabled_items > 0 then
					if table.contains(enabled_items, "spgodzl_stealOneDraw") then x = x - 1 end
				end
			end
		end
		if player:getMark("hunliesp_global_draw") > 0 then x = x + player:getMark("hunliesp_global_draw") end
		return n + x
	end
}

hunliesp_global_clear = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_clear",
	global = true,
	can_trigger = function(self, target)
		return true
	end,
	priority = 1,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardFinished, sgs.Death, sgs.PreHpRecover, sgs.PreHpLost, sgs.HpChanged, sgs.MaxHpChange, sgs.MaxHpChanged, sgs.Dying, sgs.BeforeCardsMove, sgs.DamageInflicted, sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("jieying_rob_temp") > 0 then room:setPlayerMark(p, "jieying_rob_temp", 0) end
			if p:getTag("hunlie_global_resist_invalid"):toBool() then p:removeTag("hunlie_global_resist_invalid") end
			if p:getTag("hunliesp_global_resistSkill"):toBool() then p:removeTag("hunliesp_global_resistSkill") end
		end
	end
}

hunliesp_global_clearScheme = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_clearScheme",
	global = true,
	can_trigger = function(self, target)
		return true
	end,
	priority = 1,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if not death.who:getVisibleSkillList():isEmpty() then
			for _, sk in sgs.qlist(death.who:getVisibleSkillList()) do
				if isSchemeSkill(sk:objectName()) then room:removeTag(""..sk:objectName()) end
			end
		end
	end
}

hunliesp_global_clearSchemeMarks = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_clearSchemeMarks",
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self, targets)
		return target
	end,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		local sk = data:toString()
		if isSchemeSkill(sk) then
			if player:getMark(sk.."hunlie_global_schemedraw") > 0 then room:removePlayerMark(player, sk.."hunlie_global_schemedraw", player:getMark(sk.."hunlie_global_schemedraw")) end
			if player:getMark(sk.."hunlie_global_schememaxcard") > 0 then room:removePlayerMark(player, sk.."hunlie_global_schememaxcard", player:getMark(sk.."hunlie_global_schememaxcard")) end
			if player:getMark(sk.."hunlie_global_schemeslashtime") > 0 then room:removePlayerMark(player, sk.."hunlie_global_schemeslashtime", player:getMark(sk.."hunlie_global_schemeslashtime")) end
		end
	end
}

hunliesp_global_controlSkill = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_controlSkill",
	events = {sgs.EventAcquireSkill, sgs.MarkChanged, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self, target)
		return true
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill then
			local num = player:getTag("_hunlieforbid"):toInt()
			if num < 0 then
				local to_valid = player:getTag("Qingcheng"):toString():split("+")
				table.insert(to_valid, data:toString())
				room:addPlayerMark(player, "Qingcheng"..data:toString())
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:filterCards(p, p:getCards("he"), true)
				end
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if string.find(mark.name, "_hunlieforbid") and mark.gain < 0 and mark.who:isAlive() then
				activateAllSkills(mark.who)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local names = player:getMarkNames()
				local nul = false
				for _, name in ipairs(names) do
					if string.find(name, "_hunlieforbid") then
						nul = true
						break
					end
				end
				if nul == false then activateAllSkills(player) end
				if player:getMark("qianyuan_random_invalidskill") > 0 then
					room:setPlayerMark(player, "qianyuan_random_invalidskill", 0)
					activateAllSkills(player)
				end
			end
		end
	end
}

hunliesp_targetmod = sgs.CreateTargetModSkill{
	name = "#hunliesp_targetmod",
	pattern = ".",
	residue_func = function(self, from, card)
		local n = 0
		if from:hasSkill("sgkgodyingshi") and card:hasTip("jlyingshi_eagle") then n = n + 9999 end
		return n
	end,
	distance_limit_func = function(self, from, card)
		local n = 0
		if from:hasSkill("sgkgodyingshi") and card:hasTip("jlyingshi_eagle") then n = n + 9999 end
		return n
	end
}

hunliesp_global_resistLoseSkill = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_resistLoseSkill",
	events = {sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if player:getTag("hunliesp_global_resistSkill"):toBool() then
			room:addPlayerMark(player, data:toString().."_temp_skill")
			room:handleAcquireDetachSkills(player, data:toString())
			room:addPlayerMark(player, "-"..data:toString().."_temp_skill")
		end
	end
}

hunliesp_global_breakTempCards = sgs.CreateTriggerSkill{
	name = "#hunliesp_global_breakTempCards",
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			local cards = sgs.IntList()
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
				if sgs.Sanguosha:getEngineCard(id):property("hunliesp_tempcard"):toBool() and room:getCardPlace(id) == sgs.Player_DrawPile then
					cards:append(id)
				end
			end
			if not cards:isEmpty() then
				for _, id in sgs.qlist(cards) do
					room:breakCard(id)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):property("hunliesp_tempcard"):toBool() and room:getCardPlace(id) == sgs.Player_DiscardPile then
						room:breakCard(id)
					end
				end
			end
			if move.to_place == sgs.Player_PlaceHand then
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):property("hunliesp_tempcard"):toBool() and room:getCardPlace(id) == sgs.Player_PlaceHand then
						if not sgs.Sanguosha:getCard(id):hasTip("hunliesp_tempcard") then room:setCardTip(card:getEffectiveId(), "hunliesp_tempcard") end
					end
				end
			end
		end	
	end
}


sgkgodjiguan = sgs.CreateTriggerSkill{
	name = "sgkgodjiguan",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end
}


hunliesp_global_maxcards = sgs.CreateMaxCardsSkill{
	name = "#hunliesp_global_maxcards",
	extra_func = function(self, target)
		local n = 0
		return n
	end
}

local sgkgodhidden = sgs.SkillList()
if not sgs.Sanguosha:getSkill("shajue_slash") then sgkgodhidden:append(shajue_slash) end
if not sgs.Sanguosha:getSkill("jl_sgkgodlangxi") then sgkgodhidden:append(jl_sgkgodlangxi) end
if not sgs.Sanguosha:getSkill("#sgkgodmaxcards") then sgkgodhidden:append(sgkgodmaxcards) end
if not sgs.Sanguosha:getSkill("#yinyang_lose") then sgkgodhidden:append(yinyang_lose) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_drawcards") then sgkgodhidden:append(hunliesp_global_drawcards) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_clear") then sgkgodhidden:append(hunliesp_global_clear) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_controlSkill") then sgkgodhidden:append(hunliesp_global_controlSkill) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_clearScheme") then sgkgodhidden:append(hunliesp_global_clearScheme) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_clearSchemeMarks") then sgkgodhidden:append(hunliesp_global_clearSchemeMarks) end
if not sgs.Sanguosha:getSkill("#hunliesp_targetmod") then sgkgodhidden:append(hunliesp_targetmod) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_resistLoseSkill") then sgkgodhidden:append(hunliesp_global_resistLoseSkill) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_breakTempCards") then sgkgodhidden:append(hunliesp_global_breakTempCards) end
if not sgs.Sanguosha:getSkill("sgkgodjiguan") then sgkgodhidden:append(sgkgodjiguan) end
if not sgs.Sanguosha:getSkill("#hunliesp_global_maxcards") then sgkgodhidden:append(hunliesp_global_maxcards) end
sgs.Sanguosha:addSkills(sgkgodhidden)


sgs.LoadTranslationTable{
	["shajue_slash"] = "杀绝",
	["sgkgodjiguan"] = "机关",
	["jl_sgkgodlangxi"] = "狼袭",
}


--智绝天下的星天武侯
--SP神诸葛亮
sgkgodspzhuge = sgs.General(extension, "sgkgodspzhuge", "sy_god", 7)


local json = require ("json")
function isNormalGameMode(mode_name)
	return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end
function getAllSkills()
	local room = sgs.Sanguosha:currentRoom()
	local Huashens = {}
	local generals = sgs.Sanguosha:getLimitedGeneralNames()
	local banned = {"zuoci", "guzhielai", "dengshizai", "jiangboyue", "bgm_xiahoudun"}
	local all_skills = {}
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
	if #generals > 0 then
		for i=1, #generals, 1 do
			table.insert(Huashens, generals[i])
		end
	end
	if #Huashens > 0 then
		for _, general_name in ipairs(Huashens) do
			local general = sgs.Sanguosha:getGeneral(general_name)		
			for _, sk in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(all_skills, sk:objectName())
			end
		end
	end
	if #all_skills > 0 then
		for _, pe in sgs.qlist(room:getAlivePlayers()) do
			for _, gsk in sgs.qlist(pe:getVisibleSkillList()) do
				if table.contains(all_skills, gsk:objectName()) then table.removeOne(all_skills, gsk:objectName()) end
			end
		end
	end
	if #all_skills > 0 then
		return all_skills
	else
		return {}
	end
end


--参数1：n，返回的table中技能的数量，Number类型（比如填3则最终的table里装填3个技能）
--参数2/3/4/5：description，所需的技能描述，String类型，一般利用string.find(skill:getDescription(), description)判断，彼此为并集。若无描述要求则填-1
--参数6：includeLord，是否包括主公技，Bool类型，true则包括，false则不包括
function getSpecificDescriptionSkills(n, player, description1, description2, description3, description4, description5, description6, description7, description8, includeLord)
	local skill_table = {}  --这个用来存放初选满足函数要求的技能
	local output_table = {}  --这个用来存放最终满足函数要求的技能
	local d_paras = {description1, description2, description3, description4, description5, description6, description7, description8}
	local d_needs = {}
	local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
	for i = 1, #d_paras do
		if d_paras[i] ~= -1 then table.insert(d_needs, d_paras[i]) end
	end
	local skills = getAllSkills()
	for _, _sk in ipairs(skills) do
		local _skill = sgs.Sanguosha:getSkill(_sk)
		local critical_des = sgs.Sanguosha:translate(":".._sk)
		if not table.contains(yaozhi_gained, _sk) then
			if #d_needs > 0 then
				for _, _des in ipairs(d_needs) do
					if critical_des:startsWith("".._des) then
						if includeLord == false then
							if (not _skill:isLordSkill()) and (not _skill:isAttachedLordSkill()) and _skill:getFrequency() ~= sgs.Skill_Wake then
								table.insert(skill_table, _sk)
								break
							end
						elseif includeLord == true then
							table.insert(skill_table, _sk)
							break
						end
					end
				end
			else
				if includeLord == false then
					if (not _skill:isLordSkill()) and (not _skill:isAttachedLordSkill()) and _skill:getFrequency() ~= sgs.Skill_Wake then
						table.insert(skill_table, _sk)
						break
					end
				elseif includeLord == true then
					table.insert(skill_table, _sk)
					break
				end
			end
		end
	end
	if #skill_table > 0 then  --整理，准备导出最终满足的技能table
		for i = 1, n do
			local j = math.random(1, #skill_table)
			table.insert(output_table, skill_table[j])
			table.removeOne(skill_table, skill_table[j])
			if #skill_table == 0 then break end
		end
	end
	return output_table
end


--[[
	技能名：妖智
	相关武将：SP神诸葛亮
	技能描述：回合开始阶段，回合结束阶段，出牌阶段限一次，当你受到伤害后，你可以摸一张牌，然后从随机三个能在此时机发动的技能中选择一个并发动。
	引用：sgkgodyaozhi
]]--
sgkgodyaozhi = sgs.CreateTriggerSkill{
	name = "sgkgodyaozhi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.Damaged, sgs.ChoiceMade, sgs.CardUsed, sgs.CardResponded},
	priority = {20, 20, 20, 20, 20, 20, 20, 20, 20},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1, self:objectName())
						local yaozhi_playerstart = getSpecificDescriptionSkills(3, player, "准备阶段", "回合开始阶段", "准备阶段开始时", "锁定技，准备阶段", "锁定技，回合开始阶段",
						"锁定技，准备阶段开始时", -1, -1, false)
						if #yaozhi_playerstart > 0 then
							local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerstart, "+"), data)
							local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
							if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
							player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
							local temp_msg = sgs.LogMessage()
							temp_msg.from = player
							temp_msg.arg = yaozhi
							temp_msg.type = "#YaozhiTempSkill"
							room:sendLog(temp_msg)
							room:addPlayerMark(player, yaozhi.."_temp_skill")
							room:acquireSkill(player, yaozhi, true, true, false)
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
			if player:getPhase() == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1, self:objectName())
						local yaozhi_playerplay = getSpecificDescriptionSkills(3, player, "出牌阶段", "出牌阶段限一次", "出牌阶段，若你", "出牌阶段限一次，若你", -1, -1, -1, -1, false)
						if #yaozhi_playerplay > 0 then
							local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerplay, "+"), data)
							local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
							if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
							player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
							local temp_msg = sgs.LogMessage()
							temp_msg.from = player
							temp_msg.arg = yaozhi
							temp_msg.type = "#YaozhiTempSkill"
							room:sendLog(temp_msg)
							room:addPlayerMark(player, yaozhi.."_temp_skill")
							room:acquireSkill(player, yaozhi, true, true, false)
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
			if player:getPhase() == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1, self:objectName())
						local yaozhi_playerfinish = getSpecificDescriptionSkills(3, player, "结束阶段", "结束阶段开始时", "回合结束时", "回合结束阶段", 
						"锁定技，结束阶段", "锁定技，结束阶段开始时", "锁定技，回合结束时", "锁定技，回合结束阶段", false)
						if #yaozhi_playerfinish > 0 then
							local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerfinish, "+"), data)
							local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
							if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
							player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
							local temp_msg = sgs.LogMessage()
							temp_msg.from = player
							temp_msg.arg = yaozhi
							temp_msg.type = "#YaozhiTempSkill"
							room:sendLog(temp_msg)
							room:addPlayerMark(player, yaozhi.."_temp_skill")
							room:acquireSkill(player, yaozhi, true, true, false)
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			for _, sk in sgs.qlist(player:getVisibleSkillList()) do
				local name = sk:objectName()
				if player:getMark(name.."_temp_skill") > 0 then
					room:handleAcquireDetachSkills(player, "-"..name)
					room:removePlayerMark(player, name.."_temp_skill", player:getMark(name.."_temp_skill"))
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage > 0 and player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					local yaozhi_damaged = getSpecificDescriptionSkills(3, player, "当你受到伤害后", "锁定技，当你受到伤害后", "当你受到1点伤害", "锁定技，当你受到1点伤害后", -1, -1, -1, -1, false)
					if #yaozhi_damaged > 0 then
						local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_damaged, "+"), data)
						local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
						if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
						player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
						local temp_msg = sgs.LogMessage()
						temp_msg.from = player
						temp_msg.arg = yaozhi
						temp_msg.type = "#YaozhiTempSkill"
						room:sendLog(temp_msg)
						room:addPlayerMark(player, yaozhi.."_temp_skill")
						room:acquireSkill(player, yaozhi, true, true, false)
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.ChoiceMade then
			local str = data:toString()
			if str:startsWith("notifyInvoked") then
				local strs = str:split(":")
				if player:getMark(strs[2].."_temp_skill") > 0 then
					room:handleAcquireDetachSkills(player, "-"..strs[2])
					local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
					if not table.contains(yaozhi_gained, strs[2]) then table.insert(yaozhi_gained, strs[2]) end
					player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
					room:removePlayerMark(player, strs[2].."_temp_skill", player:getMark(strs[2].."_temp_skill"))
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("SkillCard") then
				for _, name in sgs.list(card:getSkillNames()) do
					if player:getMark(name.."_temp_skill") > 0 then
						if player:hasSkill(name) then
							room:handleAcquireDetachSkills(player, "-"..name)
							room:removePlayerMark(player, name.."_temp_skill", player:getMark(name.."_temp_skill"))
						end
					end
				end
			end
		elseif event == sgs.CardResponded then
			local res = data:toCardResponse()
			local card = res.m_card
			if card and card:isKindOf("SkillCard") then
				for _, name in sgs.list(card:getSkillNames()) do
					if player:getMark(name.."_temp_skill") > 0 then
						if player:hasSkill(name) then
							room:handleAcquireDetachSkills(player, "-"..name)
							room:removePlayerMark(player, name.."_temp_skill", player:getMark(name.."_temp_skill"))
						end
					end
				end
			end
		end
		return false
	end
}


sgkgodspzhuge:addSkill(sgkgodyaozhi)


--[[
	技能名：星陨
	相关武将：SP神诸葛亮
	技能描述：锁定技，回合结束后，你减1点体力上限，然后获得因“妖智”选择过的一个技能。
	引用：sgkgodxingyun
]]--
sgkgodxingyun = sgs.CreateTriggerSkill{
	name = "sgkgodxingyun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	priority = 0,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.from == sgs.Player_Finish then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			room:loseMaxHp(player)
			if player:isAlive() then
				local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
				if #yaozhi_gained > 0 then
					local xingyun = room:askForChoice(player, self:objectName(), table.concat(yaozhi_gained, "+"), data)
					room:handleAcquireDetachSkills(player, xingyun)
					table.removeOne(yaozhi_gained, xingyun)
					player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
				end
			end
		end
	end
}


sgkgodspzhuge:addSkill(sgkgodxingyun)


sgs.LoadTranslationTable{
    ["sgkgodspzhuge"] = "SP神诸葛亮",
	["&sgkgodspzhuge"] = "神诸葛亮",
	["#sgkgodspzhuge"] = "绝代智谋",
	["~sgkgodspzhuge"] = "七星灯灭，魂归九州……",
	["sgkgodyaozhi"] = "妖智",
	["#yaozhiLog"] = "%from 记录的ChoiceMade时机的信息是 %arg",
	[":sgkgodyaozhi"] = "准备阶段，回合结束阶段，出牌阶段限一次，当你受到伤害后，你可以摸一张牌，然后从随机三个能在此时机发动的技能中选择一个并发动。",
	["$sgkgodyaozhi1"] = "星辰之力，助我灭敌！",
	["$sgkgodyaozhi2"] = "世间计谋，尽在掌控。",
	["#YaozhiTempSkill"] = "%from 临时获得技能“%arg”",
	["sgkgodxingyun"] = "星陨",
	[":sgkgodxingyun"] = "锁定技，回合结束后，你减1点体力上限，然后获得因“妖智”选择过的一个技能。",
	["$sgkgodxingyun1"] = "七星不灭，法力不竭！",
	["$sgkgodxingyun2"] = "斗转星移，七星借命！",
	["designer:sgkgodspzhuge"] = "极略三国",
	["illustrator:sgkgodspzhuge"] = "极略三国",
	["cv:sgkgodspzhuge"] = "极略三国",
}


--灭杀一切的地狱死神
--SP神吕布
sgkgodsplvbu = sgs.General(extension, "sgkgodsplvbu", "sy_god", 2)


function getSlashRelatedSkills(n, includeWake)
	local skill_table = {}  --这个用来存放初选满足函数要求的技能
	local output_table = {}  --这个用来存放最终满足函数要求的技能
	local skills = getAllSkills()
	for _, _sk in ipairs(skills) do
		local _skill = sgs.Sanguosha:getSkill(_sk)
		if string.find(_skill:getDescription(), "【杀】") then
			if (not _skill:isLordSkill()) and (not _skill:isAttachedLordSkill()) then
				if includeWake == true then
					table.insert(skill_table, _sk)
				else
					if _skill:getFrequency() ~= sgs.Skill_Wake then table.insert(skill_table, _sk) end
				end
			end
		end
	end
	if #skill_table > 0 then  --整理，准备导出最终满足的技能table
		for i = 1, n do
			local j = math.random(1, #skill_table)
			table.insert(output_table, skill_table[j])
			table.removeOne(skill_table, skill_table[j])
			if #skill_table == 0 then break end
		end
	end
	return output_table
end


--[[
	技能名：罗刹
	相关武将：SP神吕布
	技能描述：锁定技，游戏开始时，你随机获得3个与【杀】有关的技能。当其他角色进入濒死状态时，你摸两张牌，然后随机获得1个与【杀】有关的技能。
	引用：sgkgodluocha
]]--
sgkgodluocha = sgs.CreateTriggerSkill{
	name = "sgkgodluocha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.FetchDrawPileCard, sgs.Dying},
	priority = 10,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.FetchDrawPileCard then
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local slash_skills = getSlashRelatedSkills(3, true)
				room:handleAcquireDetachSkills(player, table.concat(slash_skills, "|"))
				room:removePlayerMark(player, self:objectName().."engine")
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			local vic = dying.who
			if player:getSeat() ~= vic:getSeat() then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:drawCards(2, self:objectName())
					local slash_sk = getSlashRelatedSkills(1, true)
					room:handleAcquireDetachSkills(player, slash_sk[1])
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}


sgkgodsplvbu:addSkill(sgkgodluocha)


--[[
	技能名：杀绝
	相关武将：SP神吕布
	技能描述：出牌阶段限一次，你可以失去1点体力并选择一名其他角色，若如此做，你将随机一张手牌当随机属性且无视防具的【杀】对其使用，你重复此流程直至失去这些牌或该角色死亡。
	引用：sgkgodshajue
]]--
function random_nature()
	local k = math.random(1, 3)
	if k == 1 then
		return "slash"
	elseif k == 2 then
		return "fire_slash"
	elseif k == 3 then
		return "thunder_slash"
	end
end

function randomTable(_table, _num)  --把一个table中的所有序数打乱
	local _result = {}
	local _index = 1
	local _num = _num or #_table
	while #_table ~= 0 do
		local ran = math.random(0, #_table)
		if _table[ran] ~= nil then
			_result[_index] = _table[ran]
			table.remove(_table, ran)
			_index = _index + 1
			if _index > _num then break end
		end
	end
	return _result
end

sgkgodshajueCard = sgs.CreateSkillCard{
	name = "sgkgodshajueCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
        if #targets == 0 then
		    return to_select:getSeat() ~= sgs.Self:getSeat() and sgs.Self:canSlash(to_select, nil, false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "sgkgodshajue".."engine")
		if source:getMark("sgkgodshajue".."engine") > 0 then
			room:loseHp(source, 1, true)
			room:doSuperLightbox("sgkgodsplvbu", "sgkgodshajue")
			local vic = targets[1]
			local inicards = sgs.CardList()
			for _, c in sgs.qlist(source:getCards("h")) do
				inicards:append(c)
			end
			inicards = sgs.QList2Table(inicards)
			local N = #inicards
			for i = 1, N do
				if vic:isDead() then break end
				local t = math.random(1, #inicards)
				if room:getCardPlace(inicards[t]:getEffectiveId()) == sgs.Player_PlaceHand then
					local random_slash = sgs.Sanguosha:cloneCard(random_nature(), sgs.Card_SuitToBeDecided, -1)
					random_slash:addSubcard(inicards[t])
					random_slash:setSkillName("shajue_slash")
					random_slash:deleteLater()
					table.removeOne(inicards, inicards[t])
					vic:addQinggangTag(random_slash)
					local use = sgs.CardUseStruct()
					use.from = source
					use.to:append(vic)
					use.card = random_slash
					room:useCard(use, false)
				end
				if #inicards == 0 then break end
			end
			room:removePlayerMark(source, "sgkgodshajue".."engine")
		end
	end
}

sgkgodshajue = sgs.CreateZeroCardViewAsSkill{
	name = "sgkgodshajue",
	view_as = function()
		return sgkgodshajueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sgkgodshajueCard") and not player:isKongcheng()
	end
}


sgkgodsplvbu:addSkill(sgkgodshajue)


--[[
	技能名：鬼躯
	相关武将：SP神吕布
	技能描述：锁定技，你的手牌上限为你的技能数。当你处于濒死状态时，你可以失去一个技能，视为使用【桃】。
	引用：sgkgodguiqu
]]--
sgkgodguiqu = sgs.CreateZeroCardViewAsSkill{
	name = "sgkgodguiqu",
	view_as = function(self, cards)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		peach:setSkillName("sgkgodguiqu")
		return peach
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("Global_Dying") then
			return string.find(pattern, "peach")
		end
		return false
	end
}

sgkgodguiquPeach = sgs.CreateTriggerSkill{
	name = "#sgkgodguiquPeach",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Peach") and use.card:getSkillName() == "sgkgodguiqu" then
			room:addPlayerMark(player, "sgkgodguiqu".."engine")
			if player:getMark("sgkgodguiqu".."engine") > 0 then
				local my_skills = {}
				for _, skill in sgs.qlist(player:getVisibleSkillList()) do
					table.insert(my_skills, skill:objectName())
				end
				local to_lose = room:askForChoice(player, "sgkgodguiqu", table.concat(my_skills, "+"))
				room:handleAcquireDetachSkills(player, "-"..to_lose)
				room:removePlayerMark(player, "sgkgodguiqu".."engine")
			end
		end
	end
}

sgkgodguiquMax = sgs.CreateMaxCardsSkill{
	name = "#sgkgodguiquMax",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then return math.max(0, target:getVisibleSkillList():length() - target:getHp()) end
	end
}

sgkgodsplvbu:addSkill(sgkgodguiqu)
sgkgodsplvbu:addSkill(sgkgodguiquPeach)
sgkgodsplvbu:addSkill(sgkgodguiquMax)
extension:insertRelatedSkills("sgkgodguiqu", "#sgkgodguiquPeach")
extension:insertRelatedSkills("sgkgodguiqu", "#sgkgodguiquMax")


sgs.LoadTranslationTable{
    ["sgkgodsplvbu"] = "SP神吕布",
	["&sgkgodsplvbu"] = "神吕布",
	["#sgkgodsplvbu"] = "罗刹天",
	["~sgkgodsplvbu"] = "不……我是不朽的！",
	["sgkgodluocha"] = "罗刹",
	[":sgkgodluocha"] = "锁定技，游戏开始时，你随机获得3个与【杀】有关的技能。当其他角色进入濒死状态时，你摸两张牌，然后随机获得1个与【杀】有关的技能。",
	["$sgkgodluocha1"] = "超越，死亡的，恐惧！",
	["$sgkgodluocha2"] = "我，即是，不灭！",
	["sgkgodshajue"] = "杀绝",
	[":sgkgodshajue"] = "出牌阶段限一次，你可以失去1点体力并选择一名其他角色，若如此做，你将随机一张手牌当随机属性且无视防具的【杀】对其使用，你重复此流程"..
	"直至失去这些牌或该角色死亡。",
	["$sgkgodshajue1"] = "不死不休！",
	["$sgkgodshajue2"] = "这，就是地狱！",
	["sgkgodguiqu"] = "鬼躯",
	[":sgkgodguiqu"] = "锁定技，你的手牌上限为你的技能数。当你处于濒死状态时，你可以失去一个技能，视为使用【桃】。",
	["sgkgodguiquPeach"] = "鬼躯",
	[":sgkgodguiquPeach"] = "锁定技，你的手牌上限为你的技能数。当你处于濒死状态时，你可以失去一个技能，视为使用【桃】。",
	["$sgkgodguiqu1"] = "天雷？吾亦不惧！",
	["$sgkgodguiqu2"] = "鬼神之驱，怎能被凡人摧毁！",
	["designer:sgkgodsplvbu"] = "极略三国",
	["illustrator:sgkgodsplvbu"] = "极略三国",
	["cv:sgkgodsplvbu"] = "极略三国",
}


--游走生死的大阴阳师
--SP神张角
sgkgodspzhangjiao = sgs.General(extension, "sgkgodspzhangjiao", "sy_god", 3)


--[[
	技能名：极阳
	相关武将：SP神张角
	技能描述：锁定技，当你获得/失去“极阳”时，你获得3个/弃置所有“阳”标记并摸等量红色牌。当你失去红色牌后，你可弃置1个“阳”标记，令一名角色回复1点体力，若其
	未受伤，改为加1点体力上限。
	引用：sgkgodjiyang
]]--
local zhangjiao_yinyangskills = sgs.SkillList()
sgkgodjiyang = sgs.CreateTriggerSkill{
	name = "sgkgodjiyang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventAcquireSkill, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then player:gainMark("&jiyang_positive", 3) end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getMark("&jiyang_positive") == 0 then return false end
			if move.from and move.from:hasSkill(self:objectName()) and move.from:objectName() == player:objectName() then
				if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
					local can_do = false
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isRed() then
							can_do = true
							break
						end
					end
					if can_do then
						local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@jiyang-recover", true, false)
						if target then
							room:broadcastSkillInvoke(self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName())
							player:loseMark("&jiyang_positive")
							room:doAnimate(1, player:objectName(), target:objectName())
							if target:isWounded() then
								local yinyangrec = sgs.RecoverStruct()
								yinyangrec.recover = 1
								yinyangrec.who = player
								room:recover(target, yinyangrec, true)
							else
								local msg = sgs.LogMessage()
								msg.type = "#GainMaxHp"
								msg.from = target
								msg.arg = "1"
								room:sendLog(msg)
								room:setPlayerProperty(target, "maxhp", sgs.QVariant(target:getMaxHp() + 1))
							end
						end
					end
				end
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("sgkgodjiyang") then zhangjiao_yinyangskills:append(sgkgodjiyang) end


--[[
	技能名：极阴
	相关武将：SP神张角
	技能描述：锁定技，当你获得/失去“极阴”时，你获得3个/弃置所有“阴”标记。当你失去黑色牌后，你选择是否弃置1个“阴”标记，若为是，你对一名角色造成1点雷电伤害，
	若其已受伤，改为减1点体力上限。
	引用：sgkgodjiyin
]]--
sgkgodjiyin = sgs.CreateTriggerSkill{
	name = "sgkgodjiyin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventAcquireSkill, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then player:gainMark("&jiyin_negative", 3) end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getMark("&jiyin_negative") == 0 then return false end
			if move.from and move.from:hasSkill(self:objectName()) and move.from:objectName() == player:objectName() then
				if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
					local can_do = false
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isBlack() then
							can_do = true
							break
						end
					end
					if can_do then
						local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@jiyin-thunder", true, false)
						if target then
							room:broadcastSkillInvoke(self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName())
							player:loseMark("&jiyin_negative")
							room:doAnimate(1, player:objectName(), target:objectName())
							if target:isWounded() then
								room:loseMaxHp(target)
							else
								room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
							end
						end
					end
				end
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("sgkgodjiyin") then zhangjiao_yinyangskills:append(sgkgodjiyin) end


--[[
	技能名：相生
	相关武将：SP神张角
	技能描述：锁定技，当你获得/失去“相生”时，你获得6个/弃置所有“生”标记。当你失去黑色/红色牌后，你弃置1个“生”标记，从牌堆或弃牌堆中随机获得一张红色/黑色牌。
	引用：sgkgodxiangsheng
]]--
sgkgodxiangsheng = sgs.CreateTriggerSkill{
	name = "sgkgodxiangsheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventAcquireSkill, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then player:gainMark("&xiangsheng_balance", 6) end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getMark("&xiangsheng_balance") == 0 then return false end
			if move.from and move.from:hasSkill(self:objectName()) and move.from:objectName() == player:objectName() then
				if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
					local can_getred = false
					local can_getblack = false
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isBlack() then
							can_getred = true
							break
						end
					end
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isRed() then
							can_getblack = true
							break
						end
					end
					local rcards, bcards = sgs.CardList(), sgs.CardList()
					if not room:getDrawPile():isEmpty() then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local icard = sgs.Sanguosha:getCard(id)
							if icard:isRed() then
								rcards:append(icard)
							elseif icard:isBlack() then
								bcards:append(icard)
							end
						end
					end
					if not room:getDiscardPile():isEmpty() then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							local icard = sgs.Sanguosha:getCard(id)
							if icard:isRed() then
								rcards:append(icard)
							elseif icard:isBlack() then
								bcards:append(icard)
							end
						end
					end
					if (can_getred and rcards:length() > 0) or (can_getblack and bcards:length() > 0) then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						player:loseMark("&xiangsheng_balance")
						local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
						if can_getred and rcards:length() > 0 then
							rcards = sgs.QList2Table(rcards)
							local random_red = rcards[math.random(1, #rcards)]
							jink:addSubcard(random_red)
						end
						if can_getblack and bcards:length() > 0 then
							bcards = sgs.QList2Table(bcards)
							local random_black = bcards[math.random(1, #bcards)]
							jink:addSubcard(random_black)
						end
						room:obtainCard(player, jink, false)
						jink:deleteLater()
					end
				end
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("sgkgodxiangsheng") then zhangjiao_yinyangskills:append(sgkgodxiangsheng) end
sgs.Sanguosha:addSkills(zhangjiao_yinyangskills)


--[[
	技能名：阴阳
	相关武将：SP神张角
	技能描述：锁定技，若你的体力值：多于已损失体力，你拥有“极阳”；少于已损失体力，你拥有“极阴”；等于已损失体力，你拥有“相生”。
	引用：sgkgodyinyang
]]--
function getYinyangState(player)
	if player:getHp() > player:getLostHp() then  --体力值大于损失体力，阳
		return "hp_Yang"
	end
	if player:getHp() == player:getLostHp() then  --体力值等于损失体力，生
		return "hp_Sheng"
	end
	if player:getHp() < player:getLostHp() then  --体力值小于损失体力，阴
		return "hp_Yin"
	end
end

function YinyangChange(room, player, yinyang_flag, skill_name)
	local spyinyang_skills = player:getTag("SPYinyangSkills"):toString():split("+")
	if not player:isAlive() then return false end
	if getYinyangState(player) == yinyang_flag then
		if not table.contains(spyinyang_skills, skill_name) then
			room:notifySkillInvoked(player, "sgkgodyinyang")
			room:broadcastSkillInvoke("sgkgodyinyang")
			room:sendCompulsoryTriggerLog(player, "sgkgodyinyang")
			table.insert(spyinyang_skills, skill_name)
			room:handleAcquireDetachSkills(player, skill_name)
		end
	else
		if table.contains(spyinyang_skills, skill_name) then
			room:handleAcquireDetachSkills(player, "-"..skill_name)
			table.removeOne(spyinyang_skills, skill_name)
		end
	end
	player:setTag("SPYinyangSkills", sgs.QVariant(table.concat(spyinyang_skills, "+")))
end

sgkgodyinyang = sgs.CreateTriggerSkill{
	name = "sgkgodyinyang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TurnStart then
			for _, spzhangjiao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			YinyangChange(room, spzhangjiao, "hp_Yang", "sgkgodjiyang")
			YinyangChange(room, spzhangjiao, "hp_Sheng", "sgkgodxiangsheng")
			YinyangChange(room, spzhangjiao, "hp_Yin", "sgkgodjiyin")
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not player:isAlive() or (not player:hasSkill(self:objectName())) then return false end
		YinyangChange(room, player, "hp_Yang", "sgkgodjiyang")
		YinyangChange(room, player, "hp_Sheng", "sgkgodxiangsheng")
		YinyangChange(room, player, "hp_Yin", "sgkgodjiyin")
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


sgkgodspzhangjiao:addSkill(sgkgodyinyang)


--[[
	技能名：定命
	相关武将：SP神张角
	技能描述：准备阶段，或当你受到其他角色造成的伤害后，你可交换体力与已损失体力，然后若你的体力多于已损失体力，你减1点体力上限；当你对其他角色造成伤害后，可
	令其交换体力与已损失体力，然后若其体力少于已损失体力，你减1点体力上限。若如此做，你摸X张牌（X为交换的体力与已损失体力的差）。
	交换形式：多体力与少损失体力交换，流失差额体力；少体力与多损失体力交换，回复差额体力。
	引用：sgkgoddingming
]]--
function exchangeYinYang(from, target)  --“交换”一名角色的体力与损失体力
	local room = from:getRoom()
	local x = math.abs(target:getHp() - target:getLostHp())  --先计算目标体力与已损失体力的差（取绝对值）
	if x > 0 then
		if getYinyangState(target) == "hp_Yang" then  --阳：体力大于已损失体力，则以体力流失的形式，失去等同于差额值的体力
			room:doAnimate(1, from:objectName(), target:objectName())
			room:loseHp(target, x, true)
		elseif getYinyangState(target) == "hp_Yin" then  --阴：体力小于已损失体力，则回复等同于差额值的体力
			room:doAnimate(1, from:objectName(), target:objectName())
			local yinyangrec = sgs.RecoverStruct()
			yinyangrec.recover = x
			yinyangrec.who = from
			room:recover(target, yinyangrec, true)
		end
	end
	--生：体力等于已损失体力，什么也不触发
end


sgkgoddingming = sgs.CreateTriggerSkill{
	name = "sgkgoddingming",
	events = {sgs.EventPhaseStart, sgs.Damaged, sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and getYinyangState(player) ~= "hp_Sheng" then  --你都“相生”了还交换个锤子啊
				local _data = sgs.QVariant()
				_data:setValue(player)
				if player:isAlive() and player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					local x = math.abs(player:getHp() - player:getLostHp())
					exchangeYinYang(player, player)
					if getYinyangState(player) == "hp_Yang" then room:loseMaxHp(player) end
					if player:isAlive() then player:drawCards(x, self:objectName()) end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.from then return false end
			if getYinyangState(player) ~= "hp_Sheng" then  --你都“相生”了还交换个锤子啊
				local _data = sgs.QVariant()
				_data:setValue(player)
				if player:isAlive() and player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					local x = math.abs(player:getHp() - player:getLostHp())
					exchangeYinYang(player, player)
					if getYinyangState(player) == "hp_Yang" then room:loseMaxHp(player) end
					if player:isAlive() then player:drawCards(x, self:objectName()) end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:getSeat() ~= player:getSeat() and getYinyangState(damage.to) ~= "hp_Sheng" then  --你都“相生”了还交换个锤子啊
				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if damage.to:isAlive() and player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					local x = math.abs(damage.to:getHp() - damage.to:getLostHp())
					exchangeYinYang(player, damage.to)
					if getYinyangState(damage.to) == "hp_Yin" then room:loseMaxHp(player) end
					if player:isAlive() and damage.to:isAlive() then player:drawCards(x, self:objectName()) end
				end
			end
		end
		return false
	end
}


sgkgodspzhangjiao:addSkill(sgkgoddingming)
sgkgodspzhangjiao:addRelateSkill("sgkgodjiyang")
sgkgodspzhangjiao:addRelateSkill("sgkgodjiyin")
sgkgodspzhangjiao:addRelateSkill("sgkgodxiangsheng")

sgs.LoadTranslationTable{
    ["sgkgodspzhangjiao"] = "SP神张角",
	["&sgkgodspzhangjiao"] = "神张角",
	["#sgkgodspzhangjiao"] = "大道无常",
	["~sgkgodspzhangjiao"] = "为何苍天……还没死……",
	["sgkgodyinyang"] = "阴阳",
	[":sgkgodyinyang"] = "锁定技，若你的体力值：多于已损失体力，你拥有“极阳”；少于已损失体力，你拥有“极阴”；等于已损失体力，你拥有“相生”。",
	["$sgkgodyinyang1"] = "世间万物，皆有阴阳之道。",
	["$sgkgodyinyang2"] = "一阴一阳，道用无穷。",
	["sgkgoddingming"] = "定命",
	[":sgkgoddingming"] = "准备阶段，或当你受到其他角色造成的伤害后，你可交换体力与已损失体力，然后若你的体力多于已损失体力，你减1点体力上限；当你对其他角色"..
	"造成伤害后，可令其交换体力与已损失体力，然后若其体力少于已损失体力，你减1点体力上限。若如此做，你摸X张牌（X为交换的体力与已损失体力的差）。",
	["$sgkgoddingming1"] = "苍天不复，黄天立命！",
	["$sgkgoddingming2"] = "窥晓阴阳，逆天改命！",
	["sgkgodjiyang"] = "极阳",
	["jiyang_positive"] = "阳",
	[":sgkgodjiyang"] = "锁定技，当你获得/失去“极阳”时，你获得3个/弃置所有“阳”标记并摸等量红色牌。当你失去红色牌后，你可弃置1个“阳”标记，令一名角色回复1点体"..
	"力，若其未受伤，改为加1点体力上限。",
	["@jiyang-recover"] = "【极阳】选择一名已受伤/未受伤的角色令其回复1点体力/加1点体力上限<br/> <b>操作提示</b>: 选择一名需要“极阳”治疗的（友方）角色→点击确定<br/>",
	["$sgkgodjiyang1"] = "极阳之力，救苍生万民。",
	["$sgkgodjiyang2"] = "道以扬善，平天下乱世。",
	["sgkgodjiyin"] = "极阴",
	["jiyin_negative"] = "阴",
	[":sgkgodjiyin"] = "锁定技，当你获得/失去“极阴”时，你获得3个/弃置所有“阴”标记并摸等量黑色牌。当你失去黑色牌后，你可弃置1个“阴”标记，对一名角色造成1点雷"..
	"电伤害，若其已受伤，改为减1点体力上限。",
	["@jiyin-thunder"] = "【极阴】选择一名已受伤/未受伤的角色令其减1点体力上限/受到1点雷电伤害<br/> <b>操作提示</b>: 选择一名需要“极阴”打击的（敌方）角色→点击确定<br/>",
	["$sgkgodjiyin1"] = "极阴之力，毁灭一切！",
	["$sgkgodjiyin2"] = "阴雷诛灭，电纵九天！",
	["sgkgodxiangsheng"] = "相生",
	["xiangsheng_balance"] = "生",
	[":sgkgodxiangsheng"] = "锁定技，当你获得/失去“相生”时，你获得6个/弃置所有“生”标记并摸等量的牌。当你失去黑色/红色牌后，你弃置1个“生”标记，从牌堆或弃牌堆中随机获得一"..
	"张红色/黑色牌。",
	["$sgkgodxiangsheng1"] = "阴阳相生，道法自然。",
	["$sgkgodxiangsheng2"] = "周而复始，生生不息。",
	["designer:sgkgodspzhangjiao"] = "极略三国",
	["illustrator:sgkgodspzhangjiao"] = "极略三国",
	["cv:sgkgodspzhangjiao"] = "极略三国",
}


--SP神张辽
--物理意义的刑天梦魇
sgkgodspzhangliao = sgs.General(extension, "sgkgodspzhangliao", "sy_god", 4)


--[[
	技能名：锋影
	相关武将：SP神张辽
	技能描述：当你摸一张牌前，你可改为视为对一名其他角色使用【雷杀】（无距离限制），每回合限四次。
	引用：sgkgodfengying, sgkgodfengyingClear
]]--
sgkgodfengying = sgs.CreateTriggerSkill{
	name = "sgkgodfengying",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if room:getTag("FirstRound"):toBool() then return false end
		if not player:hasSkill(self:objectName()) then return false end
	    if not move.from_places:contains(sgs.Player_DrawPile) or move.from then return false end
	    if move.to_place == sgs.Player_PlaceHand and move.to:objectName() == player:objectName() 
	            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW 
			    or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
			if player:getMark("fengying_thunderslash-Clear") >= 4 then return false end
			local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
			thunder_slash:setSkillName(self:objectName())
			thunder_slash:deleteLater()
			local k = move.card_ids:length()
			for _, id in sgs.qlist(move.card_ids) do
				local targets = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					if not sgs.Sanguosha:isProhibited(player, pe, thunder_slash) and pe:getHp() > 0 then targets:append(pe) end
				end
				if targets:isEmpty() then
					break
				else
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "@fengying-target", true, true)
					if target then
						room:addPlayerMark(player, "fengying_thunderslash-Clear")
						room:addPlayerMark(player, "fengying_tempcount")
						local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(target)
						use.card = thunder_slash
						room:useCard(use, true)
						if player:getMark("fengying_thunderslash-Clear") >= 4 then break end
					else
						break
					end
				end
			end
			if player:getMark("fengying_tempcount") > 0 then
				local final_ids = sgs.IntList()
				local x = k - player:getMark("fengying_tempcount")
				if room:getDrawPile():length() < x then room:swapPile() end
				for i = 1, x do
					final_ids:append(room:getDrawPile():at(i-1))
				end
				move.card_ids = final_ids
				data:setValue(move)
			end
			room:setPlayerMark(player, "fengying_tempcount", 0)
		end
	end
}


sgkgodspzhangliao:addSkill(sgkgodfengying)


--[[
	技能名：止啼
	相关武将：SP神张辽
	技能描述：当你对其他角色即将造成伤害时，你可选择一项：①偷取其1点体力和体力上限；②偷取其摸牌阶段的1摸牌数；③偷取其1个技能；④令其不能使用装备牌；⑤令其翻面。
	每项对每名其他角色限一次。
	引用：sgkgodzhiti
]]--
sgkgodzhiti = sgs.CreateTriggerSkill{
	name = "sgkgodzhiti",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:getSeat() == player:getSeat() then return false end
		if damage.damage == 0 then return false end
		local zhiti_items = {"spgodzl_stealOneHpAndMaxhp", "spgodzl_stealOneDraw", "spgodzl_stealOneSkill", "spgodzl_banEquip", "spgodzl_turnOver"}
		local enabled_items = damage.to:property("_ZhitiEnabled"):toString():split("+")
		local rest_items = {}
		if #enabled_items > 0 then
			for i = 1, #zhiti_items, 1 do
				if not table.contains(enabled_items, zhiti_items[i]) then table.insert(rest_items, zhiti_items[i]) end
			end
		else
			for i = 1, #zhiti_items, 1 do
				table.insert(rest_items, zhiti_items[i])
			end
		end
		if #rest_items > 0 then
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if player:askForSkillInvoke(self:objectName(), _data) then
				local choice = room:askForChoice(player, self:objectName(), table.concat(rest_items, "+"), _data)
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				if choice == "spgodzl_stealOneHpAndMaxhp" then
					local msg1 = sgs.LogMessage()
					msg1.from = player
					msg1.to:append(damage.to)
					msg1.type = "#SPGodZhiti1"
					room:sendLog(msg1)
					room:loseHp(damage.to, 1, true)
					room:loseMaxHp(damage.to, 1)
					room:gainMaxHp(player, 1)
					if player:isWounded() then
						local rec = sgs.RecoverStruct()
						rec.recover = 1
						rec.who = player
						room:recover(player, rec, true)
					end
					table.insert(enabled_items, choice)
					room:setPlayerProperty(damage.to, "_ZhitiEnabled", sgs.QVariant(table.concat(enabled_items, "+")))
				elseif choice == "spgodzl_stealOneDraw" then
					room:addPlayerMark(player, "hunliesp_global_draw")
					local msg2 = sgs.LogMessage()
					msg2.from = player
					msg2.to:append(damage.to)
					msg2.type = "#SPGodZhiti2"
					room:sendLog(msg2)
					table.insert(enabled_items, choice)
					room:setPlayerProperty(damage.to, "_ZhitiEnabled", sgs.QVariant(table.concat(enabled_items, "+")))
				elseif choice == "spgodzl_stealOneSkill" then
					local msg3 = sgs.LogMessage()
					msg3.from = player
					msg3.to:append(damage.to)
					msg3.type = "#SPGodZhiti3"
					room:sendLog(msg3)
					local to_steal = {}
					for _, _skill in sgs.qlist(damage.to:getVisibleSkillList()) do
						table.insert(to_steal, _skill:objectName())
					end
					if #to_steal > 0 then
						local askill = room:askForChoice(player, "zhiti_stealWhat", table.concat(to_steal, "+"), _data)
						room:handleAcquireDetachSkills(damage.to, "-"..askill)
						if not player:hasSkill(askill) then room:handleAcquireDetachSkills(player, askill) end
					end
					table.insert(enabled_items, choice)
					room:setPlayerProperty(damage.to, "_ZhitiEnabled", sgs.QVariant(table.concat(enabled_items, "+")))
				elseif choice == "spgodzl_banEquip" then
					local msg4 = sgs.LogMessage()
					msg4.from = player
					msg4.to:append(damage.to)
					msg4.type = "#SPGodZhiti4"
					room:sendLog(msg4)
					room:setPlayerCardLimitation(damage.to, "use,response", "EquipCard|.|.|hand", false)
					table.insert(enabled_items, choice)
					room:setPlayerProperty(damage.to, "_ZhitiEnabled", sgs.QVariant(table.concat(enabled_items, "+")))
				elseif choice == "spgodzl_turnOver" then
					local msg5 = sgs.LogMessage()
					msg5.from = player
					msg5.to:append(damage.to)
					msg5.type = "#SPGodZhiti5"
					room:sendLog(msg5)
					damage.to:turnOver()
					table.insert(enabled_items, choice)
					room:setPlayerProperty(damage.to, "_ZhitiEnabled", sgs.QVariant(table.concat(enabled_items, "+")))
				end
			end
		end
	end
}


sgkgodspzhangliao:addSkill(sgkgodzhiti)


sgs.LoadTranslationTable{
    ["sgkgodspzhangliao"] = "SP神张辽",
	["&sgkgodspzhangliao"] = "神张辽",
	["#sgkgodspzhangliao"] = "雁门之刑天",
	["~sgkgodspzhangliao"] = "患病之躯，亦当战死沙场……",
	["sgkgodfengying"] = "锋影",
	[":sgkgodfengying"] = "当你摸一张牌前，你可改为视为对一名其他角色使用【雷杀】（无距离限制），每回合限四次。",
	["$sgkgodfengying1"] = "刀锋如影，破敌无形！",
	["$sgkgodfengying2"] = "东吴十万，吾亦可夺之锐气！",
	["@fengying-target"] = "你可以发动“锋影”不摸这张牌，改为视为对一名其他角色使用【雷杀】<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["sgkgodzhiti"] = "止啼",
	[":sgkgodzhiti"] = "当你对其他角色即将造成伤害时，你可选择一项：①偷取其1点体力和体力上限；②偷取其摸牌阶段的1摸牌数；③偷取其1个技能；④令其不能使用装备牌"..
	"；⑤令其翻面。每项对每名其他角色限一次。",
	["$sgkgodzhiti1"] = "江东小儿，安敢啼哭！",
	["$sgkgodzhiti2"] = "吾便是，东吴的梦魇！",
	["spgodzl_stealOneHpAndMaxhp"] = "止啼1：偷取其1点体力和体力上限",
	["spgodzl_stealOneDraw"] = "止啼2：偷取其摸牌阶段的1摸牌数",
	["spgodzl_stealOneSkill"] = "止啼3：偷取其1个技能",
	["spgodzl_banEquip"] = "止啼4：令其不能使用装备牌",
	["spgodzl_turnOver"] = "止啼5：令其翻面",
	["zhiti_stealWhat"] = "选择偷取的技能",
	["#SPGodZhiti1"] = "%from 偷取了 %to 的 <font color = 'yellow'><b>1</b></font> 点体力和 <font color = 'yellow'><b>1</b></font> 点体力上限",
	["#SPGodZhiti2"] = "%from 偷取了 %to 的摸牌阶段的 <font color = 'yellow'><b>1</b></font> 摸牌数",
	["#SPGodZhiti3"] = "%from 偷取了 %to 的 <font color = 'yellow'><b>1</b></font> 个武将技能",
	["#SPGodZhiti4"] = "%from 令 %to 直至本局游戏结束都不能使用 <font color = 'yellow'><b>装备牌</b></font>",
	["#SPGodZhiti5"] = "%from 令 %to 将其武将牌翻面",
	["designer:sgkgodspzhangliao"] = "极略三国",
	["illustrator:sgkgodspzhangliao"] = "极略三国",
	["cv:sgkgodspzhangliao"] = "极略三国",
}


--什么都抢的锦翎大盗
--SP神甘宁
sgkgodspganning = sgs.General(extension, "sgkgodspganning", "sy_god", 4)


--[[
	技能名：劫营
	相关武将：SP神甘宁
	技能描述：摸牌阶段，你可以放弃摸牌，然后令一名未拥有“劫营”标记的其他角色获得3个“劫营”标记。则拥有“劫营”标记的角色摸牌/回复体力/加体力上限/执行额外回合/
	获得技能前，其移去1个“劫营”标记，改为由你执行对应的效果。
	引用：sgkgodjieying, sgkgodjieyingRob
]]--
sgkgodjieying = sgs.CreateTriggerSkill{
	name = "sgkgodjieying",
	events = {sgs.EventPhaseStart, sgs.Death, sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				local can_invoke = false
				local targets = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					if pe:getMark("&"..self:objectName()) == 0 then targets:append(pe) end
				end
				if not targets:isEmpty() then can_invoke = true end
				if can_invoke and player:askForSkillInvoke(self:objectName()) then
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					room:doAnimate(1, player:objectName(), target:objectName())
					room:broadcastSkillInvoke(self:objectName())
					target:gainMark("&"..self:objectName(), 3)
					return true
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) and death.who:objectName() == player:objectName() then
				for _, pe in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(pe, "&"..self:objectName(), 0)
				end
			end
		elseif event == sgs.BeforeCardsMove then  --偷摸牌
			local move = data:toMoveOneTime()
			if move.card_ids:length() == 0 then return false end
			if move.to_place == sgs.Player_PlaceHand and move.to:getMark("&"..self:objectName()) > 0 and move.to:objectName() ~= player:objectName()
	            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW 
			    or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
				room:broadcastSkillInvoke(self:objectName())
				local to = -1
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					if move.to:objectName() == pe:objectName() then
						to = pe
						break
					end
				end
				to:loseMark("&"..self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				move.to = player
				data:setValue(move)
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#jieyingRobCard"
				msg.to:append(to)
				msg.arg = "sgkgodjieying"
				msg.arg2 = tostring(move.card_ids:length())
				room:sendLog(msg)
			end
		end
		return false
	end
}

--劫营的抢劫部分
sgkgodjieyingRob = sgs.CreateTriggerSkill{
	name = "#sgkgodjieyingRob",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpRecover, sgs.MaxHpChange, sgs.TurnStart, sgs.EventAcquireSkill},
	priority = {10, 100, 100, 100},
	global = true,
	on_trigger = function(self, event, player, data, room)
		for _, sgn in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.PreHpRecover then  --偷体力回复
				local rec = data:toRecover()
				local x = rec.recover
				local source = rec.from
				if player:getMark("&sgkgodjieying") > 0 then
					room:broadcastSkillInvoke("sgkgodjieying")
					player:loseMark("&sgkgodjieying")
					if sgn:isWounded() then
						local rec = sgs.RecoverStruct()
						rec.recover = x
						rec.who = source
						room:recover(sgn, rec, true)
					end
					room:broadcastSkillInvoke("sgkgodjieying")
					local msg = sgs.LogMessage()
					msg.from = sgn
					msg.type = "#jieyingRobRecover"
					msg.to:append(player)
					msg.arg = "sgkgodjieying"
					msg.arg2 = tostring(x)
					room:sendLog(msg)
					return true
				end
			elseif event == sgs.MaxHpChange then  --偷体力上限
				if player:getMark("&sgkgodjieying") > 0 then
					local change = data:toMaxHp()
					local n = change.change
					if n > 0 then
						room:broadcastSkillInvoke("sgkgodjieying")
						player:loseMark("&sgkgodjieying")
						local msg = sgs.LogMessage()
						msg.from = sgn
						msg.type = "#jieyingRobMaxHp"
						msg.to:append(player)
						msg.arg = "sgkgodjieying"
						msg.arg2 = tostring(n)
						room:sendLog(msg)
						room:gainMaxHp(sgn, n)
						change.change = 0
						data:setValue(change)
					end
				end
			elseif event == sgs.TurnStart then  --偷额外回合
				if player:getMark("&sgkgodjieying") > 0 and player:getMark("@extra_turn") > 0 then
					room:removePlayerMark(player, "@extra_turn")
					room:broadcastSkillInvoke("sgkgodjieying")
					player:loseMark("&sgkgodjieying")
					local msg = sgs.LogMessage()
					msg.from = sgn
					msg.type = "#jieyingRobExtraTurn"
					msg.to:append(player)
					msg.arg = "sgkgodjieying"
					room:sendLog(msg)
					sgn:gainAnExtraTurn()
					return true
				end
			elseif event == sgs.EventAcquireSkill then  --偷技能
				local skill = data:toString()
				if player:getMark("&sgkgodjieying") > 0 or (player:getMark("&sgkgodjieying") == 0 and sgn:getMark("jieying_rob_temp") > 0 and player:objectName() ~= sgn:objectName()) then
					if data:toString() == "sgkgodjieying" then return false end
					if sgn:getMark("jieying_rob_temp") == 0 then
						if player:getMark(skill.."_temp_skill") == 0 then
							room:addPlayerMark(sgn, "jieying_rob_temp")
							player:loseMark("&sgkgodjieying")
						end
					end
					if player:getMark(skill.."_temp_skill") == 0 then
						room:handleAcquireDetachSkills(player, "-"..skill, false, true, false)
						if not sgn:hasSkill(skill) then
							local msg = sgs.LogMessage()
							msg.from = sgn
							msg.type = "#jieyingRobSkill"
							msg.to:append(player)
							msg.arg = "sgkgodjieying"
							msg.arg2 = skill
							room:sendLog(msg)
							room:handleAcquireDetachSkills(sgn, skill)
						end
					end
				end
			end
		end
		return false
	end			
}


sgkgodspganning:addSkill(sgkgodjieying)
sgkgodspganning:addSkill(sgkgodjieyingRob)
extension:insertRelatedSkills("sgkgodjieying", "#sgkgodjieyingRob")


--[[
	技能名：锦龙
	相关武将：SP神甘宁
	技能描述：锁定技，当一张装备牌被你获得或进入弃牌堆后，你将其置于武将牌上并摸1张牌，且视为拥有这些装备牌的技能。
	引用：sgkgodjinlong, sgkgodjinlongLose
]]--
sgkgodjinlong = sgs.CreateTriggerSkill{
	name = "sgkgodjinlong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	priority = -2,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if room:getTag("FirstRound"):toBool() then return false end
		if (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))
			or move.to_place == sgs.Player_DiscardPile then
			local contains_eq = false
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
					contains_eq = true
					break
				end
			end
			if contains_eq and player:hasSkill("sgkgodjinlong") then
				room:sendCompulsoryTriggerLog(player, "sgkgodjinlong", true, true)
				local jl = player:getTag("sgkgodjinlong_equips"):toString():split("+")
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					local place = room:getCardPlace(card:getEffectiveId())
					if card:isKindOf("EquipCard") then
						if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip or place == sgs.Player_DiscardPile then
							local name = sgs.Sanguosha:getEngineCard(id):objectName()
							if not table.contains(jl, name) then
								table.insert(jl, name)
								local msg = sgs.LogMessage()
								msg.from = player
								msg.type = "#jinlongEquip"
								msg.card_str = card:toString()
								room:sendLog(msg)
								player:setTag("sgkgodjinlong_equips", sgs.QVariant(table.concat(jl, "+")))
								if #jl > 0 then
									local eqs = {}
									for _, pn in sgs.list(jl) do
										table.insert(eqs, pn)
										table.insert(eqs, " ")
									end
									player:setSkillDescriptionSwap("sgkgodjinlong", "%arg11", table.concat(eqs, "+"))
									room:changeTranslation(player, "sgkgodjinlong")
								end
							end
							player:addToPile("jinlong_equips", card)
							player:drawCards(1, "sgkgodjinlong")
							player:ViewAsEquip(name, true)
						end
					end
				end
			end
		end
		return false
	end
}


sgkgodjinlongLose = sgs.CreateTriggerSkill{
	name = "#sgkgodjinlongLose",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if data:toString() == "sgkgodjinlong" then
			local eqs = player:getTag("sgkgodjinlong_equips"):toString():split("+")
			for _, name in ipairs(eqs) do
				player:removeViewAsEquip(name)
			end
			player:clearOnePrivatePile("jinlong_equips")
			player:removeTag("sgkgodjinlong_equips")
		end
	end
}


sgkgodspganning:addSkill(sgkgodjinlong)
sgkgodspganning:addSkill(sgkgodjinlongLose)
extension:insertRelatedSkills("sgkgodjinlong", "#sgkgodjinlongLose")


sgs.LoadTranslationTable{
    ["sgkgodspganning"] = "SP神甘宁",
	["&sgkgodspganning"] = "神甘宁",
	["#sgkgodspganning"] = "锦翎如龙",
	["~sgkgodspganning"] = "神乌啼鸣尽悲哀，梧桐树下待涅槃!",
	["sgkgodjieying"] = "劫营",
	[":sgkgodjieying"] = "摸牌阶段，你可以放弃摸牌，然后令一名未拥有“劫营”标记的其他角色获得3个“劫营”标记。则拥有“劫营”标记的角色摸牌/回复体力/加体力上限/"..
	"执行额外回合/获得技能前，其移去1个“劫营”标记，改为由你执行对应的效果。",
	["$sgkgodjieying1"] = "劫寨将轻骑，驱兵饮巨瓯！",
	["$sgkgodjieying2"] = "衔枚夜袭觇敌向，如若万鬼临人间！",
	["#jieyingRobCard"] = "%from 的“%arg”被触发，抢走了 %to 本应该摸的 %arg2 张牌",
	["#jieyingRobRecover"] = "%from 的“%arg”被触发，抢走了 %to 本应该回复的 %arg2 点体力",
	["#jieyingRobMaxHp"] = "%from 的“%arg”被触发，抢走了 %to 本应该增加的 %arg2 点体力上限",
	["#jieyingRobExtraTurn"] = "%from 的“%arg”被触发，抢走了 %to 本应该进行的额外回合",
	["#jieyingRobSkill"] = "%from 的“%arg”被触发，抢走了 %to 本应该获得的技能“%arg2”",
	["sgkgodjinlong"] = "锦龙",
	[":sgkgodjinlong"] = "锁定技，当一张装备牌被你获得或进入弃牌堆后，你将其置于武将牌上并摸1张牌，且视为拥有这些装备牌的技能。",
	[":sgkgodjinlong1"] = "锁定技，当一张装备牌被你获得或进入弃牌堆后，你将其置于武将牌上并摸1张牌，且视为拥有这些装备牌的技能。\
	<font color=\"#9400D3\">“锦龙”记录的装备：%arg11</font>",
	["jinlong_equips"] = "锦龙",
	["#jinlongEquip"] = "%from 获得了装备牌 %card 的技能",
	["$sgkgodjinlong1"] = "身披锦衣卧沙场，银铃声声似龙吟！",
	["$sgkgodjinlong2"] = "锦龙锐甲，金鳞为开！",
	["designer:sgkgodspganning"] = "极略三国",
	["illustrator:sgkgodspganning"] = "极略三国",
	["cv:sgkgodspganning"] = "极略三国",
}


--蚕食天地的鹰狼之魂
--SP神司马懿
sgkgodspsimayi = sgs.General(extension, "sgkgodspsimayi", "sy_god", 3)


--[[
	技能名：鹰视
	相关武将：SP神司马懿
	技能描述：锁定技，分发起始手牌后，你选择一种基本牌名并随机获得一张，然后将手牌中所有基本牌标记为“鹰”。每回合限一次，当你获得其他角色的牌后，若这些牌均为基本牌，你将这些牌标记为“鹰”。任意角色的回合结束时，你从所有区域里获得全部“鹰”。
	你使用“鹰”无距离和次数限制。当你使用“鹰”后，你摸一张牌。
	引用：sgkgodyingshi, sgkgodyingshiRob
]]--
sgkgodyingshi = sgs.CreateTriggerSkill{
	name = "sgkgodyingshi",
	frequency = sgs.Skill_Compulsory,
	priority = {10, 0},
	events = {sgs.GameStart, sgs.CardsMoveOneTime, sgs.CardFinished, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, "sgkgodyingshi")
			room:broadcastSkillInvoke(self:objectName())
			local basics = sgs.IntList()
			local basicnames = {}
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
				local c = sgs.Sanguosha:getEngineCard(id)
				local name = c:objectName()
				if c:isKindOf("BasicCard") and (not basics:contains(id)) then
					if not table.contains(basicnames, name) then
						table.insert(basicnames, name)
						basics:append(id)
					end
				end
			end
			if not basics:isEmpty() then
				room:fillAG(basics, player)
				local id = room:askForAG(player, basics, false, self:objectName(), "@yingshi-initial")
				room:clearAG(player)
				local name = sgs.Sanguosha:getEngineCard(id):objectName()
				for _, _id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(_id)
					if card:objectName() == name then
						player:obtainCard(card)
						break
					end
				end
			end
			for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("BasicCard") then
					card:setTag("jlyingshi_eagle", sgs.QVariant(true))
					room:setCardTip(card:getEffectiveId(), "jlyingshi_eagle")
				end
            end
			local yingshi_basics = {}
			for _, card in sgs.qlist(player:getHandcards()) do
                if card:getTag("jlyingshi_eagle"):toBool() then
					table.insert(yingshi_basics, tostring(card:getEffectiveId()))
				end
            end
			room:setPlayerProperty(player, "yingshi_dynamic_record", sgs.QVariant(table.concat(yingshi_basics, "+"))) 
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive()
				and (move.from:objectName() ~= move.to:objectName())
				and (move.to_place == sgs.Player_PlaceHand)
				and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				local _movefrom
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
					if t:objectName() == move.from:objectName() then
						_movefrom = t
						break
					end
				end
				if _movefrom:getMark("jlyingshi_moved") == 0 then
					local can_do = true
					for _, id in sgs.qlist(move.card_ids) do
						if (not sgs.Sanguosha:getCard(id):isKindOf("BasicCard")) then
							can_do = false
							break
						end
					end
					if can_do then
						local _all = true
						for _, id in sgs.qlist(move.card_ids) do
							if not sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then
								_all = false
								break
							end
						end
						if not _all then
							room:addPlayerMark(_movefrom, "jlyingshi_moved")
							local yingshi_basics = player:property("yingshi_dynamic_record"):toString():split("+")
							room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
							for _, id in sgs.qlist(move.card_ids) do
								if not sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then
									sgs.Sanguosha:getCard(id):setTag("jlyingshi_eagle", sgs.QVariant(true))
									room:setCardTip(id, "jlyingshi_eagle")
									if not table.contains(yingshi_basics, tostring(id)) then table.insert(yingshi_basics, tostring(id)) end
								end
							end
							room:setPlayerProperty(player, "yingshi_dynamic_record", sgs.QVariant(table.concat(yingshi_basics, "+")))
						end
					end
				end
			end
			if move.to_place == sgs.Player_PlaceHand then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getTag("jlyingshi_eagle"):toBool() and not card:hasTip("jlyingshi_eagle") then
						room:setCardTip(id, "jlyingshi_eagle")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.from:getSeat() == player:getSeat() and use.card then
				local has_yingshi = false
				if not use.card:getSubcards():isEmpty() then
					for _, id in sgs.qlist(use.card:getSubcards()) do
						if sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then
							has_yingshi = true
							break
						end
					end
				end
				if (use.card:getTag("jlyingshi_eagle"):toBool() or has_yingshi) and use.card:getTypeId() ~= sgs.Card_TypeSkill then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:drawCards(1, "sgkgodyingshi")
				end
			end
		elseif event == sgs.CardResponded then
			local res = data:toCardResponse()
			if res.m_isUse and res.m_who:getSeat() == player:getSeat() then
				local has_yingshi = false
				if not res.m_card:getSubcards():isEmpty() then
					for _, id in sgs.qlist(res.m_card:getSubcards()) do
						if sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then
							has_yingshi = true
							break
						end
					end
				end
				if res.m_card:getTag("jlyingshi_eagle"):toBool() or has_yingshi then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:drawCards(1, "sgkgodyingshi")
				end
			end
		end
		return false
	end
}

sgkgodyingshiRob = sgs.CreateTriggerSkill{
	name = "#sgkgodyingshiRob",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		for _, smy in sgs.qlist(room:findPlayersBySkillName("sgkgodyingshi")) do
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local yingshi = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				yingshi:deleteLater()
				--1. 统计牌堆和弃牌堆
				if not room:getDrawPile():isEmpty() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then yingshi:addSubcard(sgs.Sanguosha:getCard(id)) end
					end
				end
				if not room:getDiscardPile():isEmpty() then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then yingshi:addSubcard(sgs.Sanguosha:getCard(id)) end
					end
				end
				--2. 统计全场的手牌、装备和判定区
				for _, pe in sgs.qlist(room:getOtherPlayers(smy)) do
					if not pe:getCards("hej"):isEmpty() then
						for _, c in sgs.qlist(pe:getCards("hej")) do
							if c:getTag("jlyingshi_eagle"):toBool() then yingshi:addSubcard(c) end
						end
					end
				end
				if yingshi:subcardsLength() > 0 then
					room:sendCompulsoryTriggerLog(smy, "sgkgodyingshi", true, true)
					room:obtainCard(smy, yingshi, false)
					for _, _id in sgs.qlist(yingshi:getSubcards()) do
						if not sgs.Sanguosha:getCard(_id):hasTip("jlyingshi_eagle") then room:setCardTip(_id, "jlyingshi_eagle") end
					end
				end
				for _, pe in sgs.qlist(room:getPlayers()) do
					if pe:getMark("jlyingshi_moved") > 0 then room:setPlayerMark(pe, "jlyingshi_moved", 0) end
				end
			end
		end
	end
}


sgkgodspsimayi:addSkill(sgkgodyingshi)
sgkgodspsimayi:addSkill(sgkgodyingshiRob)
extension:insertRelatedSkills("sgkgodyingshi", "#sgkgodyingshiRob")


--[[
	技能名：狼袭
	相关武将：SP神司马懿
	技能描述：每种牌名限一次，游戏开始时/当你使用手牌里的非延时锦囊牌时，你可以将任一种非延时锦囊牌的牌名/此牌名称标记为“狼”。当你使用手牌里的非延时锦囊牌后，你可视为对其中任意个目标依次使用所有“狼”。
	引用：sgkgodlangxi
]]--
function prepareLangxiRecord(player, langxi_str)
	local room = player:getRoom()
	local langxi_names = player:property(langxi_str):toString():split("+")
	local lx = sgs.IntList()
	local lxnames = {}
	for i = 1, #langxi_names, 1 do
		if not table.contains(lxnames, langxi_names[i]) then
			table.insert(lxnames, langxi_names[i])
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
				local c = sgs.Sanguosha:getEngineCard(id)
				if c:objectName() == langxi_names[i] then lx:append(id) break end
			end
		end
	end
	lxnames = {}
	return lx
end

sgkgodlangxi = sgs.CreateTriggerSkill{
	name = "sgkgodlangxi",
	priority = {3, 3, -10, -10},
	events = {sgs.GameStart, sgs.PreCardUsed, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			local tricks = sgs.IntList()
			local lx = player:property("langxi_dynamic_record"):toString():split("+")
			local tricknames = {}
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
				local c = sgs.Sanguosha:getEngineCard(id)
				local name = c:objectName()
				if c:isNDTrick() and (not tricks:contains(id)) and (not c:isKindOf("Nullification")) and (not c:isKindOf("Suijiyingbian")) and (not c:isKindOf("ZhizheTrick")) then
					if not table.contains(tricknames, name) then
						table.insert(tricknames, name)
						tricks:append(id)
					end
				end
			end
			if not tricks:isEmpty() then
				room:fillAG(tricks, player)
				local id = room:askForAG(player, tricks, false, self:objectName(), "@langxi-initial")
				room:clearAG(player)
				local name = sgs.Sanguosha:getEngineCard(id):objectName()
				local msg = sgs.LogMessage()
				msg.type = "$langxiRecord"
				msg.from = player
				msg.arg = name
				msg.arg2 = "jllangxi_wolf"
				room:sendLog(msg)
				table.insert(lx, name)
				room:setPlayerProperty(player, "SkillDescriptionRecord_sgkgodlangxi", sgs.QVariant(table.concat(lx, "+")))
				room:setPlayerProperty(player, "langxi_dynamic_record", sgs.QVariant(table.concat(lx, "+")))
				if #lx > 0 then
					local tks = {}
					for _, pn in sgs.list(lx) do
						table.insert(tks, pn)
						table.insert(tks, " ")
					end
					player:setSkillDescriptionSwap("sgkgodlangxi", "%arg11", table.concat(tks, "+"))
					room:changeTranslation(player, "sgkgodlangxi")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.to and use.to:length() > 0 and use.card:isNDTrick() and (not use.card:isKindOf("Suijiyingbian")) and use.card:subcardsLength() > 0 then
				if use.card:isVirtualCard() or use.card:getSkillName() ~= "" then return false end
				local id = use.card:getEffectiveId()
				local langxi_names = player:property("langxi_dynamic_record"):toString():split("+")
				room:addPlayerMark(player, "langxi_viewAs_trick")
				if room:getCardPlace(id) == sgs.Player_PlaceHand and not table.contains(langxi_names, sgs.Sanguosha:getEngineCard(id):objectName()) then
					if player:askForSkillInvoke(self:objectName(), data) then
						local _name = sgs.Sanguosha:getEngineCard(id):objectName()
						table.insert(langxi_names, _name)
						local msg = sgs.LogMessage()
						msg.type = "$langxiRecord"
						msg.from = player
						msg.arg = _name
						msg.arg2 = "jllangxi_wolf"
						room:sendLog(msg)
						room:setPlayerProperty(player, "SkillDescriptionRecord_sgkgodlangxi", sgs.QVariant(table.concat(langxi_names, "+")))
						room:setPlayerProperty(player, "langxi_dynamic_record", sgs.QVariant(table.concat(langxi_names, "+")))
						local lx = player:property("langxi_dynamic_record"):toString():split("+")
						if #lx > 0 then
							local tks = {}
							for _, pn in sgs.list(lx) do
								table.insert(tks, pn)
								table.insert(tks, " ")
							end
							player:setSkillDescriptionSwap("sgkgodlangxi", "%arg11", table.concat(tks, "+"))
							room:changeTranslation(player, "sgkgodlangxi")
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.to and use.to:length() > 0 and use.card:isNDTrick() and use.card:subcardsLength() > 0 then
				if use.to:length() == 1 and use.to:at(0):getSeat() == player:getSeat() then return false end
				if player:getMark("langxi_viewAs_trick") > 0 then
					room:setPlayerMark(player, "langxi_viewAs_trick", 0)
					if not prepareLangxiRecord(player, "langxi_dynamic_record"):isEmpty() then room:fillAG(prepareLangxiRecord(player, "langxi_dynamic_record"), player) else return false end
					local tos = sgs.SPlayerList()
					for _, t in sgs.qlist(use.to) do
						if t:isAlive() then tos:append(t) end
					end
					if tos:isEmpty() then return false end
					local targets = room:askForPlayersChosen(player, tos, self:objectName(), 0, tos:length(), "@langxi_select", true)
					if not targets:isEmpty() then
						targets = sgs.QList2Table(targets)
						local langxi_names = player:property("langxi_dynamic_record"):toString():split("+")
						room:clearAG(player)
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
						for _, _name in ipairs(langxi_names) do
							local langxi_card = sgs.Sanguosha:cloneCard(_name, sgs.Card_NoSuit, 0)
							langxi_card:setSkillName("_sgkgodlangxi")
							langxi_card:deleteLater()
							local langxi_to = sgs.SPlayerList()
							for i = 1, #targets, 1 do
								if targets[i]:isAlive() then langxi_to:append(targets[i]) end
							end
							if not langxi_to:isEmpty() then
								local use = sgs.CardUseStruct()
								use.from = player
								use.to = langxi_to
								use.card = langxi_card
								room:useCard(use, false)
							end
						end
					end
					room:clearAG(player)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}


sgkgodspsimayi:addSkill(sgkgodlangxi)


--[[
	技能名：神隐
	相关武将：SP神司马懿
	技能描述：锁定技，游戏开始或你杀死其他角色时，你获得1个“神隐”标记，记录你当前的体力、体力上限、技能、“鹰”、“狼”标记。准备阶段，若你有“神隐”标记，你可将以此法记录的信息更新并获得1个“神隐”标记。当你进入濒死
	状态或失去此技能后，你可移去所有“神隐”标记，将你回溯至记录状态，并摸2X张牌（X为你移去的“神隐”标记数）。
	引用：sgkgodshenyin
]]--
function getAllCardIds()
	local room = sgs.Sanguosha:currentRoom()
	local allInts = sgs.IntList()
	for _, id in sgs.qlist(room:getDrawPile()) do
		allInts:append(id)
	end
	for _, id in sgs.qlist(room:getDiscardPile()) do
		allInts:append(id)
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		for _, _card in sgs.qlist(pe:getCards("hej")) do
			allInts:append(_card:getEffectiveId())
		end
	end
	return allInts
end

function shenyinRecord(player)
	local room = sgs.Sanguosha:currentRoom()
	local shenyin_data = {"shenyin_hp", "shenyin_maxhp", "shenyin_skills", "shenyin_yingshi", "shenyin_langxi"}  --前两项记录体力、体力上限
	--记录生命值
	room:setPlayerProperty(player, shenyin_data[1], sgs.QVariant(player:getHp()))
	--记录最大生命值
	room:setPlayerProperty(player, shenyin_data[2], sgs.QVariant(player:getMaxHp()))
	--记录武将技能、“鹰”标记和“狼”标记
	local shenyin_skills, shenyin_yingshi, shenyin_langxi = {}, {}, {}
	--记录当前武将技能
	for _, _skill in sgs.qlist(player:getVisibleSkillList()) do
		if not table.contains(shenyin_skills, _skill:objectName()) then table.insert(shenyin_skills, _skill:objectName()) end
	end
	room:setPlayerProperty(player, shenyin_data[3], sgs.QVariant(table.concat(shenyin_skills, "+")))
	--记录已有的“鹰”
	local yingshi_current = player:property("yingshi_dynamic_record"):toString():split("+")
	room:setPlayerProperty(player, shenyin_data[4], sgs.QVariant(table.concat(yingshi_current, "+")))
	--记录已有的“狼”
	local langxi_current = player:property("langxi_dynamic_record"):toString():split("+")
	room:setPlayerProperty(player, shenyin_data[5], sgs.QVariant(table.concat(langxi_current, "+")))
	--将所有的信息全部储存记录进入“神隐”的Data中，以便SP神司马懿进入濒死或失去“神隐”时调用
	room:setPlayerProperty(player, "shenyin_data", sgs.QVariant(table.concat(shenyin_data, "+")))
end

function shenyinRewrite(player)
	local room = sgs.Sanguosha:currentRoom()
	local shenyin_data = player:property("shenyin_data"):toString():split("+")
	local rec_hp_data, rec_maxhp_data, rec_skills_data, rec_yingshi_data, rec_langxi_data, X = shenyin_data[1], shenyin_data[2], shenyin_data[3], shenyin_data[4], shenyin_data[5], player:getMark("&sgkgodshenyin")
	player:loseAllMarks("&sgkgodshenyin")
	local msg = sgs.LogMessage()
	msg.from = player
	msg.type = "$shenyinRewrite"
	msg.arg = "sgkgodshenyin"
	room:sendLog(msg)
	local rec_hp = player:property(rec_hp_data):toInt()
	local rec_maxhp = player:property(rec_maxhp_data):toInt()
	local hp_dif, maxhp_dif = math.abs(player:getHp()-rec_hp), math.abs(player:getMaxHp()-rec_maxhp)
	--回溯体力上限
	if player:getMaxHp() > rec_maxhp then
		room:loseMaxHp(player, maxhp_dif)
	elseif player:getMaxHp() < rec_maxhp then
		room:gainMaxHp(player, maxhp_dif)
	end
	--回溯体力
	if player:getHp() > rec_hp then
		room:loseHp(player, hp_dif, true)
	elseif player:getHp() < rec_hp then
		local recover = sgs.RecoverStruct()
		recover.recover = math.min(hp_dif, player:getLostHp())
		room:recover(player, recover)
	end
	--回溯技能（蔡文姬遇到SP神司马懿直接被逮到死，断肠无效）
	local rec_skills = player:property(rec_skills_data):toString():split("+")
	local shenyin_remove, shenyin_regain, currents = {}, {}, player:getVisibleSkillList()   
	if not currents:isEmpty() then
		for _, _current in sgs.qlist(currents) do
			if not table.contains(rec_skills, _current:objectName()) then table.insert(shenyin_remove, _current:objectName()) end
		end
	end
	for _, _rec in pairs(rec_skills) do
		if not currents:contains(sgs.Sanguosha:getSkill(_rec)) then table.insert(shenyin_regain, _rec) end
	end
	if #shenyin_remove > 0 then room:handleAcquireDetachSkills(player, "-"..table.concat(shenyin_remove, "|-")) end
	if #shenyin_regain > 0 then room:handleAcquireDetachSkills(player, table.concat(shenyin_regain, "|")) end
	--回溯“鹰”标记
	local rec_yingshi = player:property(rec_yingshi_data):toString():split("+")
	room:setPlayerProperty(player, "yingshi_dynamic_record", sgs.QVariant(table.concat(rec_yingshi, "+")))
	for _, id in sgs.qlist(getAllCardIds()) do
		if table.contains(rec_yingshi, tostring(id)) and not sgs.Sanguosha:getCard(id):getTag("jlyingshi_eagle"):toBool() then
			sgs.Sanguosha:getCard(id):setTag("jlyingshi_eagle", sgs.QVariant(true))
			sgs.Sanguosha:getCard(id):setFlags("jlyingshi_eagle")
			room:setCardTip(id, "jlyingshi_eagle")
		end
	end
	--回溯“狼”标记
	local rec_langxi = player:property(rec_langxi_data):toString():split("+")  
	room:setPlayerProperty(player, "langxi_dynamic_record", sgs.QVariant(table.concat(rec_langxi, "+")))
	--执行“神隐”回溯的最后操作：摸2X张牌
	player:drawCards(2*X, "sgkgodshenyin")
end

sgkgodshenyin = sgs.CreateTriggerSkill{
	name = "sgkgodshenyin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Death, sgs.EventPhaseStart, sgs.Dying},
	priority = {-99, 99, -10, -10, 99},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then  --把记录的优先级降到-99，因为有人可能这个时候副将配的SP神吕布【罗刹】先拿技能
			room:sendCompulsoryTriggerLog(player, "sgkgodshenyin", true, true)
			player:gainMark("&sgkgodshenyin", 1)
			shenyinRecord(player)
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then return false end
			if death.damage and death.damage.from and death.damage.from:hasSkill("sgkgodshenyin") and death.damage.from:isAlive() then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				player:gainMark("&sgkgodshenyin", 1)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("&sgkgodshenyin") > 0 then
				if player:askForSkillInvoke("sgkgodshenyin", data) then
					room:broadcastSkillInvoke("sgkgodshenyin")
					player:gainMark("&sgkgodshenyin", 1)
					shenyinRecord(player)
				end
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and dying.who:hasSkill("sgkgodshenyin") and dying.who:getMark("&sgkgodshenyin") > 0 then
				if player:askForSkillInvoke("sgkgodshenyin", data) then
					room:broadcastSkillInvoke("sgkgodshenyin")
					room:doSuperLightbox("sgkgodspsimayi", "sgkgodshenyin")
					shenyinRewrite(dying.who)
				end
			end
		end
		return false
	end
}


sgkgodshenyinLose = sgs.CreateTriggerSkill{
	name = "#sgkgodshenyinLose",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if data:toString() == "sgkgodshenyin" and p:objectName() == player:objectName() and p:getMark("&sgkgodshenyin") > 0 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke("sgkgodshenyin")
					room:doSuperLightbox("sgkgodspsimayi", "sgkgodshenyin")
					shenyinRewrite(player)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


sgkgodspsimayi:addSkill(sgkgodshenyin)
sgkgodspsimayi:addSkill(sgkgodshenyinLose)
extension:insertRelatedSkills("sgkgodshenyin", "#sgkgodshenyinLose")


sgs.LoadTranslationTable{
    ["sgkgodspsimayi"] = "SP神司马懿",
	["&sgkgodspsimayi"] = "神司马懿",
	["#sgkgodspsimayi"] = "鹰挚狼食",
	["~sgkgodspsimayi"] = "天数已定，乱世终焉……",
	["sgkgodyingshi"] = "鹰视",
	["@yingshi-initial"] = "请选择一张基本牌，从牌堆中获得之",
	[":sgkgodyingshi"] = "锁定技，分发起始手牌后，你选择一种基本牌名并随机获得一张，然后将手牌中所有基本牌标记为“鹰”。每回合每名角色限一次，当你获得其他角色的牌后，若这些牌均为基本牌，你将这些牌标记为“鹰”。任意角色的回合结束时，你从所有区域里获得"..
	"全部“鹰”。你使用“鹰”无距离和次数限制。当你使用“鹰”后，你摸一张牌。",
	["$sgkgodyingshi1"] = "狡兔难逃，苍鹰之目！",
	["$sgkgodyingshi2"] = "独占峰巅，展翅逐风！",
	["jlyingshi_eagle"] = "鹰",
	["sgkgodlangxi"] = "狼袭",
	["jllangxi_wolf"] = "狼",
	["$langxiRecord"] = "%from 将 %arg 记入了“%arg2”",
	["@langxi-initial"] = "请选择一种普通锦囊牌的名称，记录入“狼”的牌名中",
	[":sgkgodlangxi"] = "每种牌名限一次，游戏开始时/当你使用手牌里的非延时锦囊牌时，你可以将任一种非延时锦囊牌的牌名/此牌名称标记为“狼”。当你使用手牌里的非延时锦囊牌后，你可视为对其中任意个目标依次使用所有“狼”。",
	[":sgkgodlangxi1"] = "每种牌名限一次，游戏开始时/当你使用手牌里的非延时锦囊牌时，你可以将任一种非延时锦囊牌的牌名/此牌名称标记为“狼”。当你使用手牌里的非延时锦囊牌后，你可视为对其中任意个目标依次使用所有“狼”。\
	<font color=\"#9400D3\">“狼”记录的非延时锦囊名：%arg11</font>",
	["$sgkgodlangxi1"] = "权变之袭，如狼噬骨！",
	["$sgkgodlangxi2"] = "复生贰心，自取罪戾！",
	["@langxi_select"] = "你可以对任意名目标依次视为使用你记录的“狼”牌（记录过的“狼”已在窗口中呈现，按窗口中从左到右的顺序使用）",
	["sgkgodshenyin"] = "神隐",
	["#sgkgodshenyinLose"] = "神隐",
	["#sgkgodshenyinLose:sgkgodshenyin"] = "你失去了“神隐”，是否将你的体力值、体力上限、技能、“鹰”和“狼”恢复至上一次“神隐”记录的状态？",
	["$shenyinRewrite"] = "%from 恢复至上一次因“%arg”记录的状态",
	["sgkgodshenyinLose"] = "神隐",
	[":sgkgodshenyin"] = "锁定技，游戏开始时，你获得1个“神隐”标记，然后记录你当前的体力、体力上限、技能和“鹰”“狼”标记。准备阶段，若你有“神隐”标记，你可将以此法记录的信息更新为当前状态并获得1个“神隐”标记。当你进入濒死状态或失去此技能后，你可移去所有"..
	"“神隐”标记，将你恢复至记录的状态，并摸2X张牌（X为你移去的“神隐”标记数）。当你杀死一名其他角色后，你获得1个“神隐”标记。",
	["$sgkgodshenyin1"] = "神幻幽妙，无以窥测。",
	["$sgkgodshenyin2"] = "形藏于身，神隐于中。",
	["designer:sgkgodspsimayi"] = "极略三国",
	["illustrator:sgkgodspsimayi"] = "极略三国",
	["cv:sgkgodspsimayi"] = "极略三国",
}


--金刚不坏的不死神龙
--SP神赵云
sgkgodspzhaoyun = sgs.General(extension, "sgkgodspzhaoyun", "sy_god", 1)


--[[
	技能名：潜渊
	相关武将：SP神赵云
	技能描述：当你承受未记录的效果前，你可令此效果对你无效，然后获得1个“潜渊”标记并记录此负面效果。每回合限X次（X为存活角色数），当你承受已记录
	的负面效果前，你可以将此效果随机改为另一种负面效果。
	引用：sgkgodqianyuan
]]--
function qy_debuffs()
	return {"qianyuan_damaged", "qianyuan_losehp", "qianyuan_losemaxhp", "qianyuan_discard", 
	"qianyuan_loseskill", "qianyuan_invalidskill", "qianyuan_chained", "qianyuan_turnover"}
	--【潜渊】定义的8种负面效果：受到伤害、失去体力、减少体力上限、弃置牌、失去技能、技能被无效、被横置、被翻至背面。其中前4项需要记录对应数值
end

qianyuanDoDebuff = function(spshenzhaoyun, exe)
	local room = sgs.Sanguosha:currentRoom()
	local qy_recorded = spshenzhaoyun:getTag("qianyuan_recorded_debuff"):toString():split("+")
	if exe == "qianyuan_loseskill" then  --如果“失去技能”没被记录，则执行“失去技能”效果：随机失去一个武将技能
		local skills = spshenzhaoyun:getVisibleSkillList()
		local _sk = {}
		for _, skill in sgs.qlist(skills) do
			table.insert(_sk, skill:objectName())
		end
		if #_sk > 0 then room:handleAcquireDetachSkills(spshenzhaoyun, "-".._sk[math.random(1, #_sk)]) end
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_invalidskill" then  --如果“技能被无效”没被记录，则执行“技能被无效”效果：随机一个武将技能永久失效
		local skills = spshenzhaoyun:getVisibleSkillList()
		local _sk = {}
		for _, skill in sgs.qlist(skills) do
			table.insert(_sk, skill:objectName())
		end
		if #_sk > 0 then
			room:addPlayerMark(spshenzhaoyun, "qianyuan_random_invalidskill")
			forbidSkills("sgkgodqianyuan", 0, spshenzhaoyun, spshenzhaoyun, true, 1)
		end
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_chained" then  --如果“被横置”没被记录，则执行“被横置”效果：横置武将牌
		if not spshenzhaoyun:isChained() then room:setPlayerChained(spshenzhaoyun) end
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_turnover" then  --如果“被翻至背面”没被记录，则执行“被翻至背面”效果：将武将牌翻面至背面朝上
		if spshenzhaoyun:faceUp() then spshenzhaoyun:turnOver() end
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_damaged" then
		room:damage(sgs.DamageStruct(nil, nil, spshenzhaoyun, 1, sgs.DamageStruct_Normal))
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_losehp" then
		room:loseHp(spshenzhaoyun)
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_losemaxhp" then
		room:loseMaxHp(spshenzhaoyun)
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	elseif exe == "qianyuan_discard" then
		throwRandomCards(true, spshenzhaoyun, spshenzhaoyun, 1, "he", "sgkgodqianyuan")
		if not table.contains(qy_recorded, exe) then
			table.insert(qy_recorded, exe)
			spshenzhaoyun:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
		end
	end
end

sgkgodqianyuan = sgs.CreateTriggerSkill{
	name = "sgkgodqianyuan",
	events = {sgs.DamageInflicted, sgs.PreHpLost, sgs.MaxHpChange, sgs.BeforeCardsMove, sgs.MarkChange, sgs.ChainStateChange, sgs.TurnOver},
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("&"..self:objectName().."_usedtimes") < target:getAliveSiblings():length() + 1
	end,
	priority = {-99, -99, -99, -99, -99, -99, -99},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			if damage.damage > 0 and damage.to and damage.to:objectName() == player:objectName() then
				if not table.contains(qy_recorded, "qianyuan_damaged") then  --如果“受到伤害”没被记录，则防止此伤害，记录“受到伤害”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_damaged")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_damaged"
						room:sendLog(msg)
						table.insert(qy_recorded, "qianyuan_damaged")
						table.insert(qy_play_debuff, "qianyuan_damaged")
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_damaged")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_damaged")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“受到伤害”已被记录，且还有没被记录的负面效果，则防止此伤害，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_damaged"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						if db == "qianyuan_losehp" then
							if not damage.from then
								room:loseHp(player, 1)
							else
								room:loseHp(player, 1, true, damage.from)
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_losemaxhp" then
							room:loseMaxHp(player)
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_discard" then
							if not damage.from then
								throwRandomCards(true, player, player, 1, "he", self:objectName())
							else
								throwRandomCards(true, damage.from, player, 1, "he", self:objectName())
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						else
							qianyuanDoDebuff(player, db)
						end
						return true
					end
				end
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			if lose.lose > 0 then
				if not table.contains(qy_recorded, "qianyuan_losehp") then  --如果“失去体力”没被记录，则防止此次失去体力，记录“失去体力”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_losehp")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						table.insert(qy_recorded, "qianyuan_losehp")
						table.insert(qy_play_debuff, "qianyuan_losehp")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_losehp"
						room:sendLog(msg)
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_losehp")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_losehp")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“失去体力”已被记录，且还有没被记录的负面效果，则防止此伤害，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_losehp"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						if db == "qianyuan_damaged" then
							if not lose.from then
								room:damage(sgs.DamageStruct(nil, nil, player, 1, sgs.DamageStruct_Normal))
							else
								room:damage(sgs.DamageStruct(nil, lose.from, player, 1, sgs.DamageStruct_Normal))
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_losemaxhp" then
							room:loseMaxHp(player, 1)
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_discard" then
							if not lose.from then
								throwRandomCards(true, player, player, 1, "he", self:objectName())
							else
								throwRandomCards(true, lose.from, player, 1, "he", self:objectName())
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						else
							qianyuanDoDebuff(player, db)
						end
						return true
					end
				end
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			local x = 0 - change.change
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			if x > 0 then
				if not table.contains(qy_recorded, "qianyuan_losemaxhp") then  --如果“失去体力上限”没被记录，则防止之，记录“失去体力上限”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_losemaxhp")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						table.insert(qy_recorded, "qianyuan_losemaxhp")
						table.insert(qy_play_debuff, "qianyuan_losemaxhp")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_losemaxhp"
						room:sendLog(msg)
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_losemaxhp")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_losemaxhp")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“失去体力上限”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_losemaxhp"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						if db == "qianyuan_damaged" then
							room:damage(sgs.DamageStruct(nil, nil, player, 1, sgs.DamageStruct_Normal))
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_losehp" then
							room:loseHp(player)
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_discard" then
							throwRandomCards(true, player, player, 1, "he", self:objectName())
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						else
							qianyuanDoDebuff(player, db)
						end
						return true
					end
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			local qy_unrecorded = {}
			for _, debuff in ipairs(qy_debuffs()) do
				if not table.contains(qy_recorded, debuff) then table.insert(qy_unrecorded, debuff) end
			end
			if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand)
				or move.from_places:contains(sgs.Player_PlaceEquip)) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick) and 
				bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and x > 0 then
				local source = -1
				for _, t in sgs.qlist(room:getAlivePlayers()) do
					if t:objectName() == move.reason.m_playerId then
						source = t
						break
					end
				end
				if not table.contains(qy_recorded, "qianyuan_discard") then  --如果“弃置牌”没被记录，则防止此次弃牌，记录“弃置牌”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_discard")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_discard"
						room:sendLog(msg)
						table.insert(qy_recorded, "qianyuan_discard")
						table.insert(qy_play_debuff, "qianyuan_discard")
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_discard")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_discard")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“弃置牌”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_discard"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						if db == "qianyuan_damaged" then
							if source == -1 then
								room:damage(sgs.DamageStruct(nil, nil, player, 1, sgs.DamageStruct_Normal))
							else
								room:damage(sgs.DamageStruct(nil, source, player, 1, sgs.DamageStruct_Normal))
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_losemaxhp" then
							room:loseMaxHp(player, 1)
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						elseif db == "qianyuan_losehp" then
							if source == -1 then
								room:loseHp(player, 1)
							else
								room:loseHp(player, 1, true, source)
							end
							if not table.contains(qy_recorded, db) then table.insert(qy_recorded, db) end
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						else
							qianyuanDoDebuff(player, db)
						end
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				end
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			local qy_unrecorded = {}
			for _, debuff in ipairs(qy_debuffs()) do
				if not table.contains(qy_recorded, debuff) then table.insert(qy_unrecorded, debuff) end
			end
			if player:getTag("hunlie_global_resist_invalid"):toBool() then return true end
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) and not player:getTag("hunlie_global_resist_invalid"):toBool() then
				if not table.contains(qy_recorded, "qianyuan_invalidskill") then  --如果“技能被失效”没被记录，则防止之，记录“技能被失效”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_invalidskill")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						table.insert(qy_recorded, "qianyuan_invalidskill")
						table.insert(qy_play_debuff, "qianyuan_invalidskill")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_invalidskill"
						room:sendLog(msg)
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						player:setTag("hunlie_global_resist_invalid", sgs.QVariant(true))
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_invalidskill")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_invalidskill")
					if #debuffs > 0 and not player:getTag("hunlie_global_resist_invalid"):toBool() and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“技能被失效”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_invalidskill"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						qianyuanDoDebuff(player, db)
						player:setTag("hunlie_global_resist_invalid", sgs.QVariant(true))
						return true
					end
				end
			end	
		elseif event == sgs.ChainStateChange then
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			local qy_unrecorded = {}
			for _, debuff in ipairs(qy_debuffs()) do
				if not table.contains(qy_recorded, debuff) then table.insert(qy_unrecorded, debuff) end
			end
			if not player:isChained() then
				if not table.contains(qy_recorded, "qianyuan_chained") then  --如果“被横置”没被记录，则防止之，记录“被横置”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_chained")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						table.insert(qy_recorded, "qianyuan_chained")
						table.insert(qy_play_debuff, "qianyuan_chained")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_chained"
						room:sendLog(msg)
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_chained")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_chained")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“被横置”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_chained"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						qianyuanDoDebuff(player, db)
						return true
					end
				end
			end
		elseif event == sgs.TurnOver then
			local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			local qy_unrecorded = {}
			for _, debuff in ipairs(qy_debuffs()) do
				if not table.contains(qy_recorded, debuff) then table.insert(qy_unrecorded, debuff) end
			end
			if player:faceUp() then
				if not table.contains(qy_recorded, "qianyuan_turnover") then  --如果“被翻面”没被记录，则防止之，记录“被翻面”这一负面效果
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_turnover")
					if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
						room:broadcastSkillInvoke(self:objectName())
						table.insert(qy_recorded, "qianyuan_turnover")
						table.insert(qy_play_debuff, "qianyuan_turnover")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_turnover"
						room:sendLog(msg)
						local ag1, ag2 = {}, {}
						for _, a1 in sgs.list(qy_recorded) do
							table.insert(ag1, a1)
							table.insert(ag1, ", ")
						end
						for _, a2 in sgs.list(qy_play_debuff) do
							table.insert(ag2, a2)
							table.insert(ag2, ", ")
						end
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
						player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
						room:changeTranslation(player, "sgkgodqianyuan")
						player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
						player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
						player:gainMark("&"..self:objectName())
						return true
					end
				else
					local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_turnover")
					local debuffs = qy_debuffs()
					table.removeOne(debuffs, "qianyuan_turnover")
					if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“被翻面”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
						room:addPlayerMark(player, "&"..self:objectName().."_usedtimes")
						local msg = sgs.LogMessage()
						msg.from = player
						msg.type = "#qianyuanNul"
						msg.arg = "sgkgodqianyuan"
						msg.arg2 = "qianyuan_turnover"
						room:sendLog(msg)
						local db = debuffs[math.random(1, #debuffs)]
						qianyuanDoDebuff(player, db)
						return true
					end
				end
			end
		end
		return false
	end
}

sgkgodqianyuanLose = sgs.CreateTriggerSkill{
	name = "#sgkgodqianyuanLose",
	events = {sgs.EventLoseSkill, sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventLoseSkill then
			if player:hasSkill(self:objectName()) then
				local qy_recorded = player:getTag("qianyuan_recorded_debuff"):toString():split("+")  --读取整局游戏已经记录过的防止过的负面效果
				local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
				local qy_unrecorded = {}
				for _, debuff in ipairs(qy_debuffs()) do
					if not table.contains(qy_recorded, debuff) then table.insert(qy_unrecorded, debuff) end
				end
				if player:getMark("&sgkgodqianyuan_usedtimes") < room:getAlivePlayers():length() then
					if not table.contains(qy_recorded, "qianyuan_loseskill") then  --如果“失去技能”没被记录，则防止之，记录“失去技能”这一负面效果
						local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_loseskill")
						if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
							room:broadcastSkillInvoke("sgkgodqianyuan")
							player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
							table.insert(qy_recorded, "qianyuan_loseskill")
							table.insert(qy_play_debuff, "qianyuan_loseskill")
							local msg = sgs.LogMessage()
							msg.from = player
							msg.type = "#qianyuanNul"
							msg.arg = "sgkgodqianyuan"
							msg.arg2 = "qianyuan_loseskill"
							room:sendLog(msg)
							local ag1, ag2 = {}, {}
							for _, a1 in sgs.list(qy_recorded) do
								table.insert(ag1, a1)
								table.insert(ag1, ", ")
							end
							for _, a2 in sgs.list(qy_play_debuff) do
								table.insert(ag2, a2)
								table.insert(ag2, ", ")
							end
							player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg1", table.concat(ag1, "+"))
							player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", table.concat(ag2, "+"))
							room:changeTranslation(player, "sgkgodqianyuan")
							player:setTag("qianyuan_recorded_debuff", sgs.QVariant(table.concat(qy_recorded, "+")))
							player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
							player:gainMark("&sgkgodqianyuan")
							room:addPlayerMark(player, data:toString().."_temp_skill")
							room:handleAcquireDetachSkills(player, data:toString())
							room:setPlayerMark(player, data:toString().."_temp_skill", 0)
						end
					else
						local prompt = string.format("qianyuan_prevent:%s:", "qianyuan_loseskill")
						local debuffs = qy_debuffs()
						table.removeOne(debuffs, "qianyuan_loseskill")
						if #debuffs > 0 and player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then  --如果“失去技能”已被记录，且还有没被记录的负面效果，则防止之，随机切换为其他的负面效果
							room:addPlayerMark(player, "&sgkgodqianyuan_usedtimes")
							local msg = sgs.LogMessage()
							msg.from = player
							msg.type = "#qianyuanNul"
							msg.arg = "sgkgodqianyuan"
							msg.arg2 = "qianyuan_loseskill"
							room:sendLog(msg)
							local db = debuffs[math.random(1, #debuffs)]
							qianyuanDoDebuff(player, db)
							room:addPlayerMark(player, data:toString().."_temp_skill")
							room:handleAcquireDetachSkills(player, data:toString())
							room:setPlayerMark(player, data:toString().."_temp_skill", 0)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName("sgkgodqianyuan")) do
					room:setPlayerMark(p, "&sgkgodqianyuan_usedtimes", 0)
				end
			end
		end
		return false
	end
}


sgkgodspzhaoyun:addSkill(sgkgodqianyuan)
sgkgodspzhaoyun:addSkill(sgkgodqianyuanLose)
extension:insertRelatedSkills("sgkgodqianyuan", "#sgkgodqianyuanLose")


--[[
	技能名：化龙
	相关武将：SP神赵云
	技能描述：准备阶段，你可选择一名其他角色并移去全部“潜渊”标记，令其依次执行这些标记记录的负面效果，然后将你的体力上限、体力值、摸牌阶段摸牌数、使用牌次数上限、攻击范围和最小手牌数改为
	以此法弃置的“潜渊”标记总数。
	引用：sgkgodhualong, sgkgodhualongTargetMod, sgkgodhualongDraw
]]--
sgkgodhualong = sgs.CreateTriggerSkill{
	name = "sgkgodhualong",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			local qy_play_debuff = player:getTag("qianyuan_play_debuff"):toString():split("+")
			local qianyuan_count = player:getMark("&sgkgodqianyuan")
			local n = #qy_play_debuff
			if n > 0 and qianyuan_count > 0 then
				if player:askForSkillInvoke(self:objectName(), data) then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), target:objectName())
					player:loseAllMarks("&sgkgodqianyuan")
					local msg = sgs.LogMessage()
					msg.from = player
					msg.to:append(target)
					msg.arg = "sgkgodqianyuan"
					msg.arg2 = self:objectName()
					msg.type = "#hualongBurst"
					room:sendLog(msg)
					room:addPlayerMark(player, self:objectName(), qianyuan_count)
					room:doSuperLightbox("sgkgodspzhaoyun", "sgkgodhualong")
					for _, debuff in ipairs(qy_play_debuff) do
						if debuff == "qianyuan_damaged" then
							room:damage(sgs.DamageStruct(self:objectName(), player, target, n))
						elseif debuff == "qianyuan_losehp" then
							room:loseHp(target, n, true, player, self:objectName())
						elseif debuff == "qianyuan_losemaxhp" then
							room:loseMaxHp(target, n)
						elseif debuff == "qianyuan_discard" then
							throwRandomCards(true, player, target, n, "he", self:objectName())
						elseif debuff == "qianyuan_loseskill" then
							local to_lose = {}
							if not target:getVisibleSkillList():isEmpty() then
								for _, _skill in sgs.qlist(target:getVisibleSkillList()) do
									table.insert(to_lose, "-".._skill:objectName())
								end
							end
							if #to_lose > 0 then
								local lost = randomGetN(to_lose, n)
								room:handleAcquireDetachSkills(target, table.concat(lost, "|"))
							end
						elseif debuff == "qianyuan_invalidskill" then
							room:addPlayerMark(target, "hualong_invalid_onephase")
							forbidSkills("sgkgodhualong", 0, player, target, false, "all")
							local msg = sgs.LogMessage()
							msg.from = player
							msg.type = "#hualong_invalid"
							msg.to:append(target)
							room:sendLog(msg)
						elseif debuff == "qianyuan_chained" then
							if not target:isChained() then room:setPlayerChained(target) end
						elseif debuff == "qianyuan_turnover" then
							if target:faceUp() then target:turnOver() end
						end
					end
					local dif1 = math.abs(player:getMark(self:objectName()) - player:getMaxHp())
					if player:getMaxHp() < player:getMark(self:objectName()) then
						room:gainMaxHp(player, dif1)
					elseif player:getMaxHp() > player:getMark(self:objectName()) then
						room:loseMaxHp(player, dif1)
					end
					local dif2 = math.abs(player:getMark(self:objectName()) - player:getHp())
					if player:getHp() > player:getMark(self:objectName()) then
						room:loseHp(player, dif2)
					else
						if player:isWounded() and player:getHp() < player:getMark(self:objectName()) then
							room:recover(player, sgs.RecoverStruct(player, nil, dif2))
						end
					end
					qy_play_debuff = {}
					player:setTag("qianyuan_play_debuff", sgs.QVariant(table.concat(qy_play_debuff, "+")))
					player:setSkillDescriptionSwap("sgkgodqianyuan", "%arg2", " ")
					room:changeTranslation(player, "sgkgodqianyuan")
				end
			end
		end
		if player:getPhase() == sgs.Player_Finish then
			for _, t in sgs.qlist(room:getAlivePlayers()) do
				if t:getMark("hualong_invalid_onephase") > 0 then
					room:setPlayerMark(t, "hualong_invalid_onephase", 0)
					activateAllSkills(t)
				end
			end
		end
	end
}

sgkgodhualongDraw1 = sgs.CreateDrawCardsSkill{
	name = "#sgkgodhualongDraw1",
	global = true,
	draw_num_func = function(self, player, n)
		local x = 0
		if player:getMark("sgkgodhualong") > 0 then
			x = x + player:getMark("sgkgodhualong") - 2
		end
		return n + x
	end
}

sgkgodhualongDraw2 = sgs.CreateTriggerSkill{
	name = "#sgkgodhualongDraw2",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard then
				local changed = false
				if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					changed = true
				end
				if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
					changed = true
				end
				if changed then
					player:addMark("hualong_change")
				end
				return false
			else
				local can_invoke = false
				if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					can_invoke = true
				end
				if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
					can_invoke = true
				end
				if not can_invoke then
					return false
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from ~= sgs.Player_Discard then
				return false
			end
			if player:getMark("hualong_change") <= 0 then
				return false
			end
			player:setMark("hualong_change", 0)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				return false
			end
			if player:getHandcardNum() < player:getMark("sgkgodhualong") then
				player:drawCards(player:getMark("sgkgodhualong") - player:getHandcardNum(), "sgkgodhualong")
			end
		end
		if player:getHandcardNum() < player:getMark("sgkgodhualong") and player:getPhase() ~= sgs.Player_Discard then
			player:drawCards(player:getMark("sgkgodhualong") - player:getHandcardNum(), "sgkgodhualong")
		end
		return false
	end
}

sgkgodhualongATK = sgs.CreateAttackRangeSkill{
	name = "#sgkgodhualongATK",
	extra_func = function(self, target, include_weapon)
		if target:getMark("sgkgodhualong") > 0 then return target:getMark("sgkgodhualong") - 1 end
	end
}

sgkgodhualongTargetMod = sgs.CreateTargetModSkill{
	name = "#sgkgodhualongTargetMod",
	pattern = ".",
	residue_func = function(self, from, card, to)
		if from:getMark("sgkgodhualong") > 0 then
			return from:getMark("sgkgodhualong") - 1
		end
	end
}


sgkgodspzhaoyun:addSkill(sgkgodhualong)
sgkgodspzhaoyun:addSkill(sgkgodhualongATK)
sgkgodspzhaoyun:addSkill(sgkgodhualongTargetMod)
sgkgodspzhaoyun:addSkill(sgkgodhualongDraw1)
sgkgodspzhaoyun:addSkill(sgkgodhualongDraw2)
extension:insertRelatedSkills("sgkgodhualong", "#sgkgodhualongATK")
extension:insertRelatedSkills("sgkgodhualong", "#sgkgodhualongTargetMod")
extension:insertRelatedSkills("sgkgodhualong", "#sgkgodhualongDraw1")
extension:insertRelatedSkills("sgkgodhualong", "#sgkgodhualongDraw2")


sgs.LoadTranslationTable{
    ["sgkgodspzhaoyun"] = "SP神赵云",
	["&sgkgodspzhaoyun"] = "神赵云",
	["#sgkgodspzhaoyun"] = "破渊追天",
	["~sgkgodspzhaoyun"] = "龙鳞虽毁，龙魂不灭……",
	["sgkgodqianyuan"] = "潜渊",
	["#sgkgodqianyuanLose"] = "潜渊",
	["sgkgodqianyuan_usedtimes"] = "潜渊抵抗",
	["$sgkgodqianyuan1"] = "晦明潜渊，一日登天！",
	["$sgkgodqianyuan2"] = "幽冥隐蔽，负上青云！",
	[":sgkgodqianyuan"] = "当你承受未记录的负面效果前，你可令此效果对你无效，然后获得1个“潜渊”标记并记录此负面效果。每回合限X次（X为存活角色数），"..
	"当你承受已记录的负面效果前，你可以将此效果随机改为另一种负面效果。",
	[":sgkgodqianyuan1"] = "当你承受未记录的负面效果前，你可令此效果对你无效，然后获得1个“潜渊”标记并记录此负面效果。每回合限X次（X为存活角色数），"..
	"当你承受已记录的负面效果前，你可以将此效果随机改为另一种负面效果。\
	<font color=\"#FF4500\">本局“潜渊”已记录的负面效果：%arg1</font>\
	<font color=\"#00BFFF\">下一次“化龙”前“潜渊”已记录：%arg2</font>",
	["sgkgodqianyuan:qianyuan_prevent"] = "你可以发动“潜渊”，防止%src并记录此效果（若“%src”已被记录，则将随机转化为一项其他未被记录的负面效果）",
	["#sgkgodqianyuanLose:qianyuan_prevent"] = "你可以发动“潜渊”，防止%src并记录此效果（若“%src”已被记录，则将随机转化为一项其他未被记录的负面效果）",
	["qianyuan_damaged"] = "受到伤害",
	["qianyuan_losehp"] = "失去体力",
	["qianyuan_losemaxhp"] = "失去体力上限",
	["qianyuan_discard"] = "被弃置牌",
	["qianyuan_loseskill"] = "失去技能",
	["qianyuan_invalidskill"] = "技能被无效",
	["qianyuan_chained"] = "被横置",
	["qianyuan_turnover"] = "被翻至背面",
	["#qianyuanNul"] = "%from 发动了“%arg”令负面效果“%arg2”无效",
	["sgkgodhualong"] = "化龙",
	["#hualong_invalid"] = "%from 令 %to 的所有技能于本回合内失效",
	["$sgkgodhualong1"] = "金鳞开雾，九霄龙吟！",
	["$sgkgodhualong2"] = "风云际会，蹲踞苍天！",
	["#hualongBurst"] = "%from 令 %to 开始依次结算 %from 上一次发动“%arg2”前通过“%arg”积累的所有负面效果",
	[":sgkgodhualong"] = "准备阶段，你可选择一名其他角色并移去全部“潜渊”标记，令其依次执行这些标记记录的负面效果（负面效果的数值为此次弃置“潜渊”标记"..
	"数，“技能无效”的效果改为“所有技能无效直至其回合结束时”），然后将你的体力上限、体力值、摸牌阶段摸牌数、使用牌次数上限、攻击范围和最小手牌数改为以"..
	"此法弃置的“潜渊”标记总数。",
	["designer:sgkgodspzhaoyun"] = "极略三国",
	["illustrator:sgkgodspzhaoyun"] = "极略三国",
	["cv:sgkgodspzhaoyun"] = "极略三国",
}


--机关百变的玄妙魔女
--SP神黄月英
sgkgodsphuangyueying = sgs.General(extension, "sgkgodsphuangyueying", "sy_god", 3, false)


--[[
	技能名：天工
	相关武将：SP神黄月英
	技能描述：游戏开始/准备阶段/回合结束时，你可以创造2/1/1个机关技能并令一名角色获得之。所有角色至多拥有7个机关技能。
	引用：sgkgodtiangong, sgkgodjiguan_prototype
	备注：你永远想象不到这一句话蕴含的工作量有多么逆天，该机关在神杀平台有80种备选时机，28种备选目标，55种执行动作，总共123200种组合（不计入晋势力和冰属性伤害则为116640
	种组合）。OL南华老仙是什么废物也配在我SP月神面前撒野？区区废物天书也敢挑战12W机关神兽？
]]--


--【天工】可选的发动时机
local tiangong_timings = {
	"phase_begin", "judge_begin", "draw_begin", "play_begin", "play_end", "discard_begin", "discard_end", "finish_begin",
	--以下时机均附带“每回合限X次（X为1-3的随机正整数）”的效果
	"effectjudgecard", "gainedcard", "loseequip",
	"afterusebasic", "afterusetrick", "afteruseequip", "afterusered", "afteruseblack", 
	"afterNDTricktarget", "afterSlashtarget",
	"confirmingslash", "useorrespondslash", "useorrespondjink",
	"damagecaused", "damageinflicted", "afterdamage", "afterstrike",
	"recoverorgainmaxhp", "loseorlosemaxhp",
	"playerenterdying", "playerquitdying",
	"turnorchain",
	"playergainskill", "playerloseskill"
}

local tiangong_phases = {"phase_begin", "judge_begin", "draw_begin", "play_begin", "play_end", "discard_begin", "discard_end", "finish_begin"}

local TG_Event = {}
TG_Event["phase_begin"] = function(self, event, player, data, room)  --准备阶段开始时
	if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Start then
			return player
		end
	end
end

TG_Event["judge_begin"] = function(self, event, player, data, room)  --判定阶段开始时
	if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Judge then
			return player
		end
	end
end

TG_Event["draw_begin"] = function(self, event, player, data, room)  --摸牌阶段开始时
	if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Draw then
			return player
		end
	end
end

TG_Event["play_begin"] = function(self, event, player, data, room)  --出牌阶段开始时
	if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Play then
			return player
		end
	end
end

TG_Event["play_end"] = function(self, event, player, data, room)  --出牌阶段结束时
	if event == sgs.EventPhaseEnd and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Play then
			return player
		end
	end
end

TG_Event["discard_begin"] = function(self, event, player, data, room)  --弃牌阶段开始时
	if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Discard then
			return player
		end
	end
end

TG_Event["discard_end"] = function(self, event, player, data, room)  --弃牌阶段结束时
	if event == sgs.EventPhaseEnd and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Discard then
			return player
		end
	end
end

TG_Event["finish_begin"] = function(self, event, player, data, room)  --回合结束阶段
	if event == sgs.EventPhaseEnd and player:hasSkill(self:objectName()) then
		if player:getPhase() == sgs.Player_Discard then
			return player
		end
	end
end

TG_Event["effectjudgecard"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你的判定牌生效后
	if event == sgs.FinishJudge then
		local judge = data:toJudge()
		local card = judge.card
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge then
			if player:objectName() == judge.who:objectName() and player:hasSkill(self:objectName()) then
				return player
			end
		end
	end
end

TG_Event["gainedcard"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你获得牌后
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
			for _, id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
					return player
				end
			end
		end
	end
end

TG_Event["loseequip"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你失去装备区里的牌后
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			return player
		end
	end
end

TG_Event["afterusebasic"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用基本牌后
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isKindOf("BasicCard") then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afterusetrick"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用锦囊牌后
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isKindOf("TrickCard") then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afteruseequip"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用装备牌后
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isKindOf("EquipCard") then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afterusered"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用红色牌后
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isRed() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afteruseblack"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用黑色牌后
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isBlack() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afterNDTricktarget"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你成为非延时锦囊牌的目标后
	if event == sgs.TargetConfirmed then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isNDTrick() then
			for _, t in sgs.qlist(use.to) do
				if t:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
					return player
				end
			end
		end
	end
end

TG_Event["confirmingslash"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你成为【杀】的目标时
	if event == sgs.TargetConfirming then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isKindOf("Slash") then
			for _, t in sgs.qlist(use.to) do
				if t:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
					return player
				end
			end
		end
	end
end

TG_Event["afterSlashtarget"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你成为【杀】的目标后
	if event == sgs.TargetConfirmed then
		local use = data:toCardUse()
		if use.card and use.card:getTypeId() > 0 and use.card:isKindOf("Slash") then
			for _, t in sgs.qlist(use.to) do
				if t:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
					return player
				end
			end
		end
	end
end

TG_Event["useorrespondslash"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用或打出【杀】时
	local acard
	if event == sgs.CardUsed then
		acard = data:toCardUse().card
	elseif event == sgs.CardResponded then
		acard = data:toCardResponse().m_card
	end
	if acard and acard:getTypeId() > 0 and acard:isKindOf("Slash") then
		if player:hasSkill(self:objectName()) then return player end
	end
end

TG_Event["useorrespondjink"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你使用或打出【闪】时
	local acard
	if event == sgs.CardUsed then
		acard = data:toCardUse().card
	elseif event == sgs.CardResponded then
		acard = data:toCardResponse().m_card
	end
	if acard and acard:getTypeId() > 0 and acard:isKindOf("Jink") then
		if player:hasSkill(self:objectName()) then return player end
	end
end

TG_Event["damaging"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你造成伤害时
	if event == sgs.DamageCaused then
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afterdamage"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你造成伤害后
	if event == sgs.Damage then
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["damageinflicted"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你受到伤害时
	if event == sgs.DamageInflicted then
		local damage = data:toDamage()
		if damage.to and damage.damage > 0 and damage.to:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["afterstrike"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你受到伤害后
	if event == sgs.Damaged then
		local damage = data:toDamage()
		if damage.to and damage.damage > 0 and damage.to:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["recoverorgainmaxhp"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你回复体力或加体力上限后
	if event == sgs.HpRecover then
		local rec = data:toRecover()
		if rec.recover > 0 then
			if player:hasSkill(self:objectName()) then return player end
		end
	elseif event == sgs.MaxHpChanged then
		local change = data:toMaxHp()
		if change.change > 0 then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["loseorlosemaxhp"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你失去体力或减体力上限后
	if event == sgs.HpLost then
		local lose = data:toHpLost()
		if lose.lose > 0 then
			if player:hasSkill(self:objectName()) then return player end
		end
	elseif event == sgs.MaxHpChanged then
		local change = data:toMaxHp()
		if change.change < 0 then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["playerenterdying"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你进入濒死状态时
	if event == sgs.EnterDying then
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["playerenterdying"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你脱离濒死状态后
	if event == sgs.QuitDying then
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["playergainskill"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你获得技能后
	if event == sgs.EventAcquireSkill then
		local name = data:toString()
		if player:getMark(name.."_temp_skill") == 0 then  --不能是SP神诸葛亮【妖智】临时获得的技能
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["playerloseskill"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你失去技能后
	if event == sgs.EventLoseSkill then
		local name = data:toString()
		if player:getMark(name.."_temp_skill") == 0 then  --不能是SP神诸葛亮【妖智】临时获得的技能
			if player:hasSkill(self:objectName()) then return player end
		end
	end
end

TG_Event["turnorchain"] = function(self, event, player, data, room)  --每回合限X（1~3）次，当你横置/重置/翻面后
	if event == sgs.ChainStateChanged then
		if player:hasSkill(self:objectName()) then return player end
	elseif event == sgs.TurnedOver then
		if player:hasSkill(self:objectName()) then return player end
	end
end


--【天工】可选的发动时机
sgs.LoadTranslationTable{
	["phase_begin"] = "准备阶段开始时",
	["judge_begin"] = "判定阶段开始时",
	["draw_begin"] = "摸牌阶段开始时",
	["play_begin"] = "出牌阶段开始时",
	["play_end"] = "出牌阶段结束时",
	["discard_begin"] = "弃牌阶段开始时",
	["discard_end"] = "弃牌阶段结束时",
	["finish_begin"] = "回合结束阶段",
	["effectjudgecard1"] = "每回合限一次，当你的判定牌生效后",
	["effectjudgecard2"] = "每回合限两次，当你的判定牌生效后",
	["effectjudgecard3"] = "每回合限三次，当你的判定牌生效后",
	["gainedcard1"] = "每回合限一次，当你获得牌后",
	["gainedcard2"] = "每回合限两次，当你获得牌后",
	["gainedcard3"] = "每回合限三次，当你获得牌后",
	["loseequip1"] = "每回合限一次，当你失去装备区里的牌后",
	["loseequip2"] = "每回合限两次，当你失去装备区里的牌后",
	["loseequip3"] = "每回合限三次，当你失去装备区里的牌后",
	["afterusebasic1"] = "每回合限一次，当你使用基本牌后",
	["afterusebasic2"] = "每回合限两次，当你使用基本牌后",
	["afterusebasic3"] = "每回合限三次，当你使用基本牌后",
	["afterusetrick1"] = "每回合限一次，当你使用锦囊牌后",
	["afterusetrick2"] = "每回合限两次，当你使用锦囊牌后",
	["afterusetrick3"] = "每回合限三次，当你使用锦囊牌后",
	["afteruseequip1"] = "每回合限一次，当你使用装备牌后",
	["afteruseequip2"] = "每回合限两次，当你使用装备牌后",
	["afteruseequip3"] = "每回合限三次，当你使用装备牌后",
	["afterusered1"] = "每回合限一次，当你使用红色牌后",
	["afterusered2"] = "每回合限两次，当你使用红色牌后",
	["afterusered3"] = "每回合限三次，当你使用红色牌后",
	["afteruseblack1"] = "每回合限一次，当你使用黑色牌后",
	["afteruseblack2"] = "每回合限两次，当你使用黑色牌后",
	["afteruseblack3"] = "每回合限三次，当你使用黑色牌后",
	["afterNDTricktarget1"] = "每回合限一次，当你成为非延时锦囊牌的目标后",
	["afterNDTricktarget2"] = "每回合限两次，当你成为非延时锦囊牌的目标后",
	["afterNDTricktarget3"] = "每回合限三次，当你成为非延时锦囊牌的目标后",
	["confirmingslash1"] = "每回合限一次，当你成为【杀】的目标时",
	["confirmingslash2"] = "每回合限两次，当你成为【杀】的目标时",
	["confirmingslash3"] = "每回合限三次，当你成为【杀】的目标时",
	["afterSlashtarget1"] = "每回合限一次，当你成为【杀】的目标后",
	["afterSlashtarget2"] = "每回合限两次，当你成为【杀】的目标后",
	["afterSlashtarget3"] = "每回合限三次，当你成为【杀】的目标后",
	["useorrespondslash1"] = "每回合限一次，当你使用或打出【杀】时",
	["useorrespondslash2"] = "每回合限两次，当你使用或打出【杀】时",
	["useorrespondslash3"] = "每回合限三次，当你使用或打出【杀】时",
	["useorrespondjink1"] = "每回合限一次，当你使用或打出【闪】时",
	["useorrespondjink2"] = "每回合限两次，当你使用或打出【闪】时",
	["useorrespondjink3"] = "每回合限三次，当你使用或打出【闪】时",
	["damagecaused1"] = "每回合限一次，当你造成伤害时",
	["damagecaused2"] = "每回合限两次，当你造成伤害时",
	["damagecaused3"] = "每回合限三次，当你造成伤害时",
	["afterdamage1"] = "每回合限一次，当你造成伤害后",
	["afterdamage2"] = "每回合限两次，当你造成伤害后",
	["afterdamage3"] = "每回合限三次，当你造成伤害后",
	["damageinflicted1"] = "每回合限一次，当你受到伤害时",
	["damageinflicted2"] = "每回合限两次，当你受到伤害时",
	["damageinflicted3"] = "每回合限三次，当你受到伤害时",
	["afterstrike1"] = "每回合限一次，当你受到伤害后",
	["afterstrike2"] = "每回合限两次，当你受到伤害后",
	["afterstrike3"] = "每回合限三次，当你受到伤害后",
	["recoverorgainmaxhp1"] = "每回合限一次，当你回复体力或加体力上限后",
	["recoverorgainmaxhp2"] = "每回合限两次，当你回复体力或加体力上限后",
	["recoverorgainmaxhp3"] = "每回合限三次，当你回复体力或加体力上限后",
	["loseorlosemaxhp1"] = "每回合限一次，当你失去体力或减体力上限后",
	["loseorlosemaxhp2"] = "每回合限两次，当你失去体力或减体力上限后",
	["loseorlosemaxhp3"] = "每回合限三次，当你失去体力或减体力上限后",
	["playerenterdying1"] = "每回合限一次，当你进入濒死状态时",
	["playerenterdying2"] = "每回合限两次，当你进入濒死状态时",
	["playerenterdying3"] = "每回合限三次，当你进入濒死状态时",
	["playerquitdying1"] = "每回合限一次，当你脱离濒死状态后",
	["playerquitdying2"] = "每回合限两次，当你脱离濒死状态后",
	["playerquitdying3"] = "每回合限三次，当你脱离濒死状态后",
	["playergainskill1"] = "每回合限一次，当你获得技能后",
	["playergainskill2"] = "每回合限两次，当你获得技能后",
	["playergainskill3"] = "每回合限三次，当你获得技能后",
	["playerloseskill1"] = "每回合限一次，当你失去技能后",
	["playerloseskill2"] = "每回合限两次，当你失去技能后",
	["playerloseskill3"] = "每回合限三次，当你失去技能后",
	["turnorchain1"] = "每回合限一次，当你横置/重置/翻面后",
	["turnorchain2"] = "每回合限两次，当你横置/重置/翻面后",
	["turnorchain3"] = "每回合限三次，当你横置/重置/翻面后",
}


--【天工】备选目标
local tiangong_targets = {
	"niziji", "suoyoujuese", "suoyouqitajuese", "suoyounanxingjuese", "suoyounvxingjuese",
	"suoyoushujuese", "suoyouweijuese", "suoyouwujuese", "suoyouqunjuese", "suoyoujinjuese", "suoyoujlgodjuese", "suoyoujlmojuese",
	"suijijuese", "suijitwojuese", "suijithreejuese", "maxhpmost", "maxhpleast", "hpmost", "hpleast", "suijiweishoushang", "suijitwoweishoushang", "suoyouweishoushang",
	"suijishoushang", "suijitwoshoushang", "suoyoushoushang", "shoupaizuiduo", "shoupaizuishao"
}

local TG_Targets = {}
TG_Targets["niziji"] = function(self, room, player)  --你
	local targets = sgs.SPlayerList()
	if player:hasSkill(self:objectName()) then targets:append(player) end
	return targets
end

TG_Targets["suoyoujuese"] = function(self, room, player)  --所有角色
	return room:getAlivePlayers()
end

TG_Targets["suoyouqitajuese"] = function(self, room, player)  --所有其他角色
	local targets = sgs.SPlayerList()
	if player:hasSkill(self:objectName()) then 
		for _, t in sgs.qlist(room:getOtherPlayers(player)) do
			targets:append(t)
		end
	end
	return targets
end

TG_Targets["suoyounanxingjuese"] = function(self, room, player)  --所有男性角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:isMale() then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyounvxingjuese"] = function(self, room, player)  --所有女性角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:isFemale() then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyoushujuese"] = function(self, room, player)  --所有蜀势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "shu" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyouweijuese"] = function(self, room, player)  --所有魏势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "wei" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyouwujuese"] = function(self, room, player)  --所有吴势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "wu" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyouqunjuese"] = function(self, room, player)  --所有群势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "qun" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyoujinjuese"] = function(self, room, player)  --所有晋势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "jin" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyoujlgodjuese"] = function(self, room, player)  --所有（极略）神势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "jl_god" then targets:append(t) end
	end
	return targets
end

TG_Targets["suoyoujlmojuese"] = function(self, room, player)  --所有魔势力角色
	local targets = sgs.SPlayerList()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getKingdom() == "sgk_magic" then targets:append(t) end
	end
	return targets
end

TG_Targets["suijijuese"] = function(self, room, player)  --随机角色
	local targets = sgs.SPlayerList()
	local alives = sgs.QList2Table(room:getAlivePlayers())
	alives = randomGetN(alives, math.random(1, #alives))
	for _, a in sgs.list(alives) do
		targets:append(a)
	end
	return targets
end

TG_Targets["suijitwojuese"] = function(self, room, player)  --随机两名角色
	local targets = sgs.SPlayerList()
	local alives = sgs.QList2Table(room:getAlivePlayers())
	local ps = randomGetN(alives, 2)
	for _, a in sgs.list(ps) do
		targets:append(a)
	end
	return targets
end

TG_Targets["suijithreejuese"] = function(self, room, player)  --随机三名角色
	local targets = sgs.SPlayerList()
	local alives = sgs.QList2Table(room:getAlivePlayers())
	local ps = randomGetN(alives, 3)
	for _, a in sgs.list(ps) do
		targets:append(a)
	end
	return targets
end

TG_Targets["maxhpmost"] = function(self, room, player)  --体力上限最多的角色
	local targets = sgs.SPlayerList()
	local _max = -1
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_max = math.max(_max, pe:getMaxHp())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getMaxHp() == _max then targets:append(pe) end
	end
	return targets
end

TG_Targets["maxhpleast"] = function(self, room, player)  --体力上限最少的角色
	local targets = sgs.SPlayerList()
	local _min = 999
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_min = math.min(_min, pe:getMaxHp())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getMaxHp() == _min then targets:append(pe) end
	end
	return targets
end

TG_Targets["hpmost"] = function(self, room, player)  --体力最多的角色
	local targets = sgs.SPlayerList()
	local _max = -1
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_max = math.max(_max, pe:getHp())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getHp() == _max then targets:append(pe) end
	end
	return targets
end

TG_Targets["hpleast"] = function(self, room, player)  --体力最少的角色
	local targets = sgs.SPlayerList()
	local _min = 999
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_min = math.min(_min, pe:getHp())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getHp() == _min then targets:append(pe) end
	end
	return targets
end

TG_Targets["suijiweishoushang"] = function(self, room, player)  --随机一名未受伤的角色
	local targets = sgs.SPlayerList()
	local healthy = {}
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if (not pe:isWounded()) then table.insert(healthy, pe) end
	end
	local ps = randomGetN(healthy, 1)
	targets:append(ps[1])
	return targets
end

TG_Targets["suijitwoweishoushang"] = function(self, room, player)  --随机两名未受伤的角色
	local targets = sgs.SPlayerList()
	local healthy = {}
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if (not pe:isWounded()) then table.insert(healthy, pe) end
	end
	local ps = randomGetN(healthy, 2)
	for i = 1, #ps do
		targets:append(ps[i])
	end
	return targets
end

TG_Targets["suoyouweishoushang"] = function(self, room, player)  --所有未受伤的角色
	local targets = sgs.SPlayerList()
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if (not pe:isWounded()) then targets:append(pe) end
	end
	return targets
end

TG_Targets["suijishoushang"] = function(self, room, player)  --随机一名已受伤的角色
	local targets = sgs.SPlayerList()
	local injured = {}
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:isWounded() then table.insert(injured, pe) end
	end
	local ps = randomGetN(injured, 1)
	targets:append(ps[1])
	return targets
end

TG_Targets["suijitwoshoushang"] = function(self, room, player)  --随机两名已受伤的角色
	local targets = sgs.SPlayerList()
	local injured = {}
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:isWounded() then table.insert(injured, pe) end
	end
	local ps = randomGetN(injured, 2)
	for i = 1, #ps do
		targets:append(ps[i])
	end
	return targets
end

TG_Targets["suoyoushoushang"] = function(self, room, player)  --所有已受伤的角色
	local targets = sgs.SPlayerList()
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:isWounded() then targets:append(pe) end
	end
	return targets
end

TG_Targets["shoupaizuiduo"] = function(self, room, player)  --手牌最多的角色
	local targets = sgs.SPlayerList()
	local _max = -1
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_max = math.max(_max, pe:getHandcardNum())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getHandcardNum() == _max then targets:append(pe) end
	end
	return targets
end

TG_Targets["shoupaizuishao"] = function(self, room, player)  --手牌最少的角色
	local targets = sgs.SPlayerList()
	local _min = 999
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		_min = math.min(_min, pe:getHandcardNum())
	end
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		if pe:getHandcardNum() == _min then targets:append(pe) end
	end
	return targets
end


sgs.LoadTranslationTable{
	["niziji"] = "你",
	["suoyoujuese"] = "所有角色",
	["suoyouqitajuese"] = "所有其他角色",
	["suoyounanxingjuese"] = "所有男性角色",
	["suoyounvxingjuese"] = "所有女性角色",
	["suoyoushujuese"] = "所有蜀势力角色",
	["suoyouweijuese"] = "所有魏势力角色",
	["suoyouwujuese"] = "所有吴势力角色",
	["suoyouqunjuese"] = "所有群势力角色",
	["suoyoujinjuese"] = "所有晋势力角色",
	["suoyoujlgodjuese"] = "所有（极略）神势力角色",
	["suoyoujlmojuese"] = "所有魔势力角色",
	["suijijuese"] = "随机一名角色",
	["suijitwojuese"] = "随机两名角色",
	["suijithreejuese"] = "随机三名角色",
	["maxhpmost"] = "体力上限最多的角色",
	["maxhpleast"] = "体力上限最少的角色",
	["hpmost"] = "体力最多的角色",
	["hpleast"] = "体力最少的角色",
	["suijiweishoushang"] = "随机一名未受伤的角色",
	["suijitwoweishoushang"] = "随机两名未受伤的角色",
	["suoyouweishoushang"] = "所有未受伤的角色",
	["suijishoushang"] = "随机一名已受伤的角色",
	["suijitwoshoushang"] = "随机两名已受伤的角色",
	["suoyoushoushang"] = "所有已受伤的角色",
	["shoupaizuiduo"] = "手牌最多的角色",
	["shoupaizuishao"] = "手牌最少的角色",
}


tiangong_effects = {
	"fanmian", "shandianpanding", "shoupaishangxianjiayi", "suijishiquyigejineng", "suijishujineng", "suijiweijineng", "suijiwujineng", "suijiqunjineng",
	"suijigodjineng", "suijijinjineng", "suijijlgodjineng", "suijimojineng", "view_as_nanmanruqin", "view_as_taoyuanjieyi", "view_as_wugufengdeng",
	"view_as_wuzhongshengyou", "view_as_wanjianqifa", "view_as_peach", "view_as_otherslash", "view_as_otherfireslash", "view_as_otherthunderslash",
	"view_as_othericeslash", "view_as_otherBigSlash", "view_as_otherduel", "view_as_othersnatch", 
	"suijitwored", "suijitwoblack", "suijitwobasic", "suijitwotrick", "suijitwoequip",
	"onedamage", "onefiredamage", "onethunderdamage", "oneicedamage", "damageothers",
	"addonemaxhp", "loseonemaxhp", "recoveronehp", "recovertwohp", "loseonehp", "losetwohp", "loseonehpthendraw",
	"mopaishumore", "mopaitwo", "mopaithree", "mopaifour",
	"suijiqizhitwo", "suijiqizhithree", "suijiqizhifour", "suijiguixin",
	"exchangewithmore", "exchangewithless", "giantzhiheng"
}

--【天工】备选效果
local TG_Effect = {}
TG_Effect["fanmian"] = function(self, room, player, source)  --翻面
	player:turnOver()
end

TG_Effect["shandianpanding"] = function(self, room, player, source)  --进行【闪电】判定
	local lightning = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0)
	lightning:deleteLater()
	local effect = sgs.CardEffectStruct()
	effect.from = nil
	effect.to = player
	effect.card = lightning
	lightning:onEffect(effect)
end

TG_Effect["shoupaishangxianjiayi"] = function(self, room, player, source)  --手牌上限+1
	room:addPlayerMark(player, self:objectName().."hunlie_global_schememaxcards")
end

TG_Effect["shiyongshacishujiayi"] = function(self, room, player, source)  --每回合使用【杀】次数+1
	room:addPlayerMark(player, self:objectName().."hunlie_global_schemeslashtime")
end

TG_Effect["suijishiquyigejineng"] = function(self, room, player, source)  --随机失去一个技能
	local to_lose = {}
	if not player:getVisibleSkillList():isEmpty() then
		for _, _skill in sgs.qlist(player:getVisibleSkillList()) do
			table.insert(to_lose, "-".._skill:objectName())
		end
	end
	room:handleAcquireDetachSkills(player, to_lose[math.random(1, #to_lose)])
end

TG_Effect["suijishujineng"] = function(self, room, player, source)  --随机获得一个蜀势力技能
	local sk = getOneKingdomSkills("shu", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijiweijineng"] = function(self, room, player, source)  --随机获得一个魏势力技能
	local sk = getOneKingdomSkills("wei", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijiwujineng"] = function(self, room, player, source)  --随机获得一个吴势力技能
	local sk = getOneKingdomSkills("wu", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijiqunjineng"] = function(self, room, player, source)  --随机获得一个群势力技能
	local sk = getOneKingdomSkills("qun", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijijinjineng"] = function(self, room, player, source)  --随机获得一个晋势力技能
	local sk = getOneKingdomSkills("jin", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijigodjineng"] = function(self, room, player, source)  --随机获得一个（普通）神势力技能
	local sk = getOneKingdomSkills("god", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijijlgodjineng"] = function(self, room, player, source)  --随机获得一个（极略）神势力技能
	local sk = getOneKingdomSkills("jl_god", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["suijimojineng"] = function(self, room, player, source)  --随机获得一个魔势力技能
	local sk = getOneKingdomSkills("sgk_magic", 1)
	room:handleAcquireDetachSkills(player, sk[1])
end

TG_Effect["view_as_nanmanruqin"] = function(self, room, player, source)  --视为使用【南蛮入侵】
	local acard = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_taoyuanjieyi"] = function(self, room, player, source)  --视为使用【桃园结义】
	local acard = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getAlivePlayers()))
end

TG_Effect["view_as_wugufengdeng"] = function(self, room, player, source)  --视为使用【五谷丰登】
	local acard = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getAlivePlayers()))
end

TG_Effect["view_as_wuzhongshengyou"] = function(self, room, player, source)  --视为使用【无中生有】
	local acard = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, player))
end

TG_Effect["view_as_wanjianqifa"] = function(self, room, player, source)  --视为使用【万箭齐发】
	local acard = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_peach"] = function(self, room, player, source)  --视为使用【桃】
	local acard = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, player))
end

TG_Effect["view_as_otherslash"] = function(self, room, player, source)  --视为对所有其他角色使用【杀】
	local acard = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_otherfireslash"] = function(self, room, player, source)  --视为对所有其他角色使用【火杀】
	local acard = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_otherthunderslash"] = function(self, room, player, source)  --视为对所有其他角色使用【雷杀】
	local acard = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_othericeslash"] = function(self, room, player, source)  --视为对所有其他角色使用【冰杀】
	local acard = sgs.Sanguosha:cloneCard("ice_slash", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_otherBigSlash"] = function(self, room, player, source)  --视为对所有其他角色使用【刺杀】
	local acard = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_otherduel"] = function(self, room, player, source)  --视为对所有其他角色使用【决斗】
	local acard = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["view_as_othersnatch"] = function(self, room, player, source)  --视为对所有其他角色使用【顺手牵羊】
	local acard = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
	acard:setSkillName(self:objectName())
	acard:deleteLater()
	room:useCard(sgs.CardUseStruct(acard, player, room:getOtherPlayers(player)))
end

TG_Effect["suijitwored"] = function(self, room, player, source)  --随机从牌堆或弃牌堆中获得两张红色牌
	local cards = sgs.CardList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isRed() then cards:append(card) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isRed() then cards:append(card) end
		end
	end
	cards = sgs.QList2Table(cards)
	local rcards = randomGetN(cards, 2)
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	for i = 1, #rcards do
		dummy:addSubcard(rcards[i])
	end
	player:obtainCard(dummy, false)
end

TG_Effect["suijitwoblack"] = function(self, room, player, source)  --随机从牌堆或弃牌堆中获得两张黑色牌
	local cards = sgs.CardList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isBlack() then cards:append(card) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isBlack() then cards:append(card) end
		end
	end
	cards = sgs.QList2Table(cards)
	local rcards = randomGetN(cards, 2)
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	for i = 1, #rcards do
		dummy:addSubcard(rcards[i])
	end
	player:obtainCard(dummy, false)
end

TG_Effect["suijitwobasic"] = function(self, room, player, source)  --随机从牌堆或弃牌堆中获得两张基本牌
	local cards = sgs.CardList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("BasicCard") then cards:append(card) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("BasicCard") then cards:append(card) end
		end
	end
	cards = sgs.QList2Table(cards)
	local rcards = randomGetN(cards, 2)
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	for i = 1, #rcards do
		dummy:addSubcard(rcards[i])
	end
	player:obtainCard(dummy, false)
end

TG_Effect["suijitwotrick"] = function(self, room, player, source)  --随机从牌堆或弃牌堆中获得两张锦囊牌
	local cards = sgs.CardList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("TrickCard") then cards:append(card) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("TrickCard") then cards:append(card) end
		end
	end
	cards = sgs.QList2Table(cards)
	local rcards = randomGetN(cards, 2)
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	for i = 1, #rcards do
		dummy:addSubcard(rcards[i])
	end
	player:obtainCard(dummy, false)
end

TG_Effect["suijitwoequip"] = function(self, room, player, source)  --随机从牌堆或弃牌堆中获得两张装备牌
	local cards = sgs.CardList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then cards:append(card) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then cards:append(card) end
		end
	end
	cards = sgs.QList2Table(cards)
	local rcards = randomGetN(cards, 2)
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	for i = 1, #rcards do
		dummy:addSubcard(rcards[i])
	end
	player:obtainCard(dummy, false)
end

TG_Effect["onedamage"] = function(self, room, player, source)  --受到1点伤害
	room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Normal))
end

TG_Effect["onefiredamage"] = function(self, room, player, source)  --受到1点火焰伤害
	room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Fire))
end

TG_Effect["onethunderdamage"] = function(self, room, player, source)  --受到1点雷电伤害
	room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Thunder))
end

TG_Effect["oneicedamage"] = function(self, room, player, source)  --受到1点冰冻伤害
	room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Ice))
end

TG_Effect["damageothers"] = function(self, room, player, source)  --对其他角色各造成1点伤害
	for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
		room:damage(sgs.DamageStruct(self:objectName(), player, pe, 1, sgs.DamageStruct_Normal))
	end
end

TG_Effect["addonemaxhp"] = function(self, room, player, source)  --加1点体力上限
	room:gainMaxHp(player, 1, self:objectName())
end

TG_Effect["loseonemaxhp"] = function(self, room, player, source)  --减1点体力上限
	room:loseMaxHp(player, 1, self:objectName())
end

TG_Effect["recoveronehp"] = function(self, room, player, source)  --回复1点体力
	local recover = sgs.RecoverStruct()
	recover.recover = 1
	room:recover(player, recover)
end

TG_Effect["recovertwohp"] = function(self, room, player, source)  --回复2点体力
	local recover = sgs.RecoverStruct()
	recover.recover = 2
	room:recover(player, recover)
end

TG_Effect["loseonehp"] = function(self, room, player, source)  --失去1点体力
	room:loseHp(player, 1, true, source, self:objectName())
end

TG_Effect["losetwohp"] = function(self, room, player, source)  --失去2点体力
	room:loseHp(player, 2, true, source, self:objectName())
end

TG_Effect["loseonehpthendraw"] = function(self, room, player, source)  --失去1点体力然后摸五张牌
	room:loseHp(player, 1, true, source, self:objectName())
	player:drawCards(5, self:objectName())
end

TG_Effect["mopaishumore"] = function(self, room, player, source)  --摸牌阶段摸牌数+1
	room:addPlayerMark(p, self:objectName().."hunlie_global_schemedraw")
end

TG_Effect["mopaitwo"] = function(self, room, player, source)  --摸两张牌
	player:drawCards(2, self:objectName())
end

TG_Effect["mopaithree"] = function(self, room, player, source)  --摸三张牌
	player:drawCards(3, self:objectName())
end

TG_Effect["mopaifour"] = function(self, room, player, source)  --摸四张牌
	player:drawCards(4, self:objectName())
end

TG_Effect["suijiqizhitwo"] = function(self, room, player, source)  --随机弃置两张牌
	throwRandomCards(true, source, player, 2, "he", self:objectName())
end

TG_Effect["suijiqizhithree"] = function(self, room, player, source)  --随机弃置三张牌
	throwRandomCards(true, source, player, 3, "he", self:objectName())
end

TG_Effect["suijiqizhifour"] = function(self, room, player, source)  --随机弃置四张牌
	throwRandomCards(true, source, player, 4, "he", self:objectName())
end

TG_Effect["suijiguixin"] = function(self, room, player, source)  --随机获得其他角色各一张牌
	for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
		local tcards = pe:getCards("he")
		tcards = sgs.QList2Table(tcards)
		if #tcards > 0 then player:obtainCard(tcards[math.random(1, #tcards)], false) end
	end
end

TG_Effect["exchangewithmore"] = function(self, room, player, source)  --与手牌数更多的随机角色交换手牌
	local more = {}
	for _, t in sgs.qlist(room:getOtherPlayers(player)) do
		if t:getHandcardNum() > player:getHandcardNum() then table.insert(more, t) end
	end
	if #more > 0 then
		local who = more[math.random(1, #more)]
		local exchange = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(player:handCards(), who, sgs.Player_PlaceHand, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), who:objectName(), self:objectName(), ""))
		local move2 = sgs.CardsMoveStruct(who:handCards(), player, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), who:objectName(), self:objectName(), ""))
		exchange:append(move2)
		exchange:append(move1)
		room:moveCardsAtomic(exchange, false)
	end
end

TG_Effect["exchangewithless"] = function(self, room, player, source)  --与手牌数更少的随机角色交换手牌
	local less = {}
	for _, t in sgs.qlist(room:getOtherPlayers(player)) do
		if t:getHandcardNum() < player:getHandcardNum() then table.insert(less, t) end
	end
	if #less > 0 then
		local who = less[math.random(1, #less)]
		local exchange = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(player:handCards(), who, sgs.Player_PlaceHand, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), who:objectName(), self:objectName(), ""))
		local move2 = sgs.CardsMoveStruct(who:handCards(), player, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), who:objectName(), self:objectName(), ""))
		exchange:append(move2)
		exchange:append(move1)
		room:moveCardsAtomic(exchange, false)
	end
end

TG_Effect["giantzhiheng"] = function(self, room, player, source)  --弃置所有牌并摸等量的牌
	local x = player:getCards("he"):length()
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
	dummy:deleteLater()
	dummy:addSubcards(player:getCards("he"))
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), "")
	room:throwCard(dummy, reason, nil)
	if x > 0 then player:drawCards(x, self:objectName()) end
end

sgs.LoadTranslationTable{
	["fanmian"] = "翻面",
	["shandianpanding"] = "进行【闪电】判定",
	["shoupaishangxianjiayi"] = "手牌上限+1",
	["suijishiquyigejineng"] = "随机失去一个技能",
	["suijishujineng"] = "随机获得一个蜀势力技能",
	["suijiweijineng"] = "随机获得一个魏势力技能",
	["suijiwujineng"] = "随机获得一个吴势力技能",
	["suijiqunjineng"] = "随机获得一个群势力技能",
	["suijijinjineng"] = "随机获得一个晋势力技能",
	["suijigodjineng"] = "随机获得一个（普通）神势力技能",
	["suijijlgodjineng"] = "随机获得一个（极略）神势力技能",
	["suijimojineng"] = "随机获得一个魔势力技能",
	["view_as_nanmanruqin"] = "视为使用【南蛮入侵】",
	["view_as_taoyuanjieyi"] = "视为使用【桃园结义】",
	["view_as_wugufengdeng"] = "视为使用【五谷丰登】",
	["view_as_wuzhongshengyou"] = "视为使用【无中生有】",
	["view_as_wanjianqifa"] = "视为使用【万箭齐发】",
	["view_as_peach"] = "视为使用【桃】",
	["view_as_otherslash"] = "视为对所有其他角色使用【杀】",
	["view_as_otherfireslash"] = "视为对所有其他角色使用【火杀】",
	["view_as_otherthunderslash"] = "视为对所有其他角色使用【雷杀】",
	["view_as_othericeslash"] = "视为对所有其他角色使用【冰杀】",
	["view_as_otherBigSlash"] = "视为对所有其他角色使用【刺杀】",
	["view_as_otherduel"] = "视为对所有其他角色使用【决斗】",
	["view_as_othersnatch"] = "视为对所有其他角色使用【顺手牵羊】",
	["suijitwored"] = "从牌堆或弃牌堆中随机获得两张红色牌",
	["suijitwoblack"] = "从牌堆或弃牌堆中随机获得两张黑色牌",
	["suijitwobasic"] = "从牌堆或弃牌堆中随机获得两张基本牌",
	["suijitwotrick"] = "从牌堆或弃牌堆中随机获得两张锦囊牌",
	["suijitwoequip"] = "从牌堆或弃牌堆中随机获得两张装备牌",
	["onedamage"] = "受到1点伤害",
	["onefiredamage"] = "受到1点火焰伤害",
	["onethunderdamage"] = "受到1点雷电伤害",
	["oneicedamage"] = "受到1点冰冻伤害",
	["damageothers"] = "对其他角色各造成1点伤害",
	["addonemaxhp"] = "加1点体力上限",
	["loseonemaxhp"] = "减1点体力上限",
	["recoveronehp"] = "回复1点体力",
	["recovertwohp"] = "回复2点体力",
	["loseonehp"] = "失去1点体力",
	["losetwohp"] = "失去2点体力",
	["loseonehpthendraw"] = "失去1点体力然后摸五张牌",
	["mopaishumore"] = "摸牌阶段摸牌数+1",
	["mopaitwo"] = "摸两张牌",
	["mopaithree"] = "摸三张牌",
	["mopaifour"] = "摸四张牌",
	["suijiqizhitwo"] = "随机弃置两张牌",
	["suijiqizhithree"] = "随机弃置三张牌",
	["suijiqizhifour"] = "随机弃置四张牌",
	["suijiguixin"] = "随机获得其他角色各一张牌",
	["exchangewithmore"] = "与手牌数更多的随机角色交换手牌",
	["exchangewithless"] = "与手牌数更少的随机角色交换手牌",
	["giantzhiheng"] = "弃置所有牌并摸等量的牌",
}


local scheme_events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.FinishJudge, sgs.CardsMoveOneTime, sgs.CardUsed, sgs.CardResponded, sgs.CardFinished, 
sgs.TargetConfirming, sgs.TargetConfirmed, sgs.DamageCaused, sgs.Damage, sgs.DamageInflicted, sgs.Damaged, sgs.HpRecover, sgs.MaxHpChanged, sgs.EnterDying, 
sgs.QuitDying, sgs.TurnedOver, sgs.ChainStateChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill}

local scheme_first_char = {"sgkgodjiguan_jia", "sgkgodjiguan_yi", "sgkgodjiguan_bing", "sgkgodjiguan_ding", "sgkgodjiguan_wu",
"sgkgodjiguan_ji", "sgkgodjiguan_geng", "sgkgodjiguan_xin", "sgkgodjiguan_ren", "sgkgodjiguan_gui"}

local scheme_second_char = {"zi", "chou", "yin", "mao", "chen", "si", "wu", "wei", "shen", "you", "xu", "hai"}

local scheme_prototypes = {}

for _, _first in sgs.list(scheme_first_char) do
	for _, _second in sgs.list(scheme_second_char) do
		local sgkgodjiguan_prototype = sgs.CreateTriggerSkill{
			name = "".._first.._second,
			events = scheme_events,
			frequency = sgs.Skill_Compulsory,
			can_trigger = function(self, player)
				return player and player:isAlive()
			end,
			on_trigger = function(self, event, player, data, room)
				local scheme_info = room:getTag(self:objectName()):toString():split("+")  --记录信息：1机关技能名、2发动时机、3执行目标、4技能效果、5限制次数（0代表不限制）
				local event_str, targets_str, effect_str, limit_time = scheme_info[2], scheme_info[3], scheme_info[4], tonumber(scheme_info[5])
				if event_str ~= "" then
					local owner = TG_Event[event_str](self, event, player, data, room)
					if owner and (limit_time == 0 or (limit_time > 0 and owner:getMark(self:objectName().."_scheme_usedtimes-Clear") < limit_time)) and player:objectName() == owner:objectName() then
						local targets = TG_Targets[targets_str](self, room, owner)
						if not targets:isEmpty() then
							room:sendCompulsoryTriggerLog(owner, self:objectName())
							room:broadcastSkillInvoke("sgkgodjiguan", math.random(1, 2))
							if limit_time > 0 then room:addPlayerMark(owner, self:objectName().."_scheme_usedtimes-Clear") end
							for _, p in sgs.qlist(targets) do
								room:doAnimate(1, owner:objectName(), p:objectName())
							end
							for _, p in sgs.qlist(targets) do
								TG_Effect[effect_str](self, room, p, owner)
							end
						end
					end
				end
			end
		}
		extension:addSkills(sgkgodjiguan_prototype)
		table.insert(scheme_prototypes, sgkgodjiguan_prototype)
	end
end

for _, _first in ipairs(scheme_first_char) do
	for _, _second in ipairs(scheme_second_char) do
		local sgkgodjiguan_exdraw = sgs.CreateDrawCardsSkill{
			name = "#".._first.._second.."draw",
			global = true,
			draw_num_func = function(self, player, n)
				local x = 0
				local skname = string.sub(self:objectName(), 2, -5)
				if player:hasSkill(skname) then x = x + player:getMark(skname.."hunlie_global_schemedraw") end
				return n + x
			end
		}
		extension:addSkills(sgkgodjiguan_exdraw)
		local sgkgodjiguan_maxcards = sgs.CreateMaxCardsSkill{
			name = "#".._first.._second.."maxcard",
			extra_func = function(self, target)
				local n = 0
				local skname = string.sub(self:objectName(), 2, -8)
				if target:hasSkill(skname) then n = n + target:getMark(skname.."hunlie_global_schememaxcards") end
				return n
			end
		}
		extension:addSkills(sgkgodjiguan_maxcards)
		local sgkgodjiguan_slashtime = sgs.CreateTargetModSkill{
			name = "#".._first.._second.."slashtime",
			pattern = ".",
			residue_func = function(self, from, card)
				local n = 0
				local skname = string.sub(self:objectName(), 2, -10)
				if from:hasSkill(skname) and card:isKindOf("Slash") then n = n + from:getMark(skname.."hunlie_global_schemeslashtime") end
				return n
			end,
		}
		extension:addSkills(sgkgodjiguan_slashtime)
	end
end


--做好机关之后，需要赋予其描述
function updateSchemeSkill(player, scheme_tag)
    local room = sgs.Sanguosha:currentRoom()
    local scheme = room:getTag(scheme_tag):toString():split("+")  --机关技能组装后包含5条信息，分别是机关技能名，时机，发动目标，执行效果，限制次数
    local scheme_name, new_timing, new_targets, new_effect, limit_time = scheme[1], scheme[2], scheme[3], scheme[4], tonumber(scheme[5])
    if limit_time > 0 then new_timing = ""..new_timing..scheme[5] end
    local trs = "<font color=\"#8582d6\">『机关·"..sgs.Sanguosha:translate(scheme_name).."』</font>锁定技，"..sgs.Sanguosha:translate(new_timing)..
    "，"..sgs.Sanguosha:translate(new_targets)..sgs.Sanguosha:translate(new_effect).."。"
    room:changeTranslation(player, scheme_name, trs)
end

--机关命名，开始组装机关
function schemeName(player)
	local room = player:getRoom()
	local first = {"sgkgodjiguan_jia", "sgkgodjiguan_yi", "sgkgodjiguan_bing", "sgkgodjiguan_ding", "sgkgodjiguan_wu",
	"sgkgodjiguan_ji", "sgkgodjiguan_geng", "sgkgodjiguan_xin", "sgkgodjiguan_ren", "sgkgodjiguan_gui"}
	local second = {"zi", "chou", "yin", "mao", "chen", "si", "wu", "wei", "shen", "you", "xu", "hai"}
	local used1 = room:getTag("schemeNames_used_1stchar"):toString():split("+")
	local used2 = room:getTag("schemeNames_used_2ndchar"):toString():split("+")
	if #used1 > 0 then
		for _, _1st in pairs(used1) do
			if table.contains(first, _1st) then table.removeOne(first, _1st) end
		end
	end
	if #used2 > 0 then
		for _, _2nd in pairs(used2) do
			if table.contains(second, _2nd) then table.removeOne(second, _2nd) end
		end
	end
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		for _, _skill in sgs.qlist(t:getVisibleSkillList()) do
			_name = _skill:objectName()
			for _, _firstchar in pairs(first) do
				if isSchemeSkill(_name) and _name:startsWith(_firstchar) then
					table.removeOne(first, _firstchar)
				end
			end
			for _, _secondchar in pairs(second) do
				if isSchemeSkill(_name) and string.find(_name, _secondchar) then
					table.removeOne(second, _secondchar)
				end
			end
		end
	end
	if #first == 0 then
		first = {"sgkgodjiguan_jia", "sgkgodjiguan_yi", "sgkgodjiguan_bing", "sgkgodjiguan_ding", "sgkgodjiguan_wu",
		"sgkgodjiguan_ji", "sgkgodjiguan_geng", "sgkgodjiguan_xin", "sgkgodjiguan_ren", "sgkgodjiguan_gui"}
		used1 = {}
	end
	table.insert(used1, first[1])
	local _name = ""..first[1]
	if #second == 0 then
		second = {"zi", "chou", "yin", "mao", "chen", "si", "wu", "wei", "shen", "you", "xu", "hai"}
		used2 = {}
	end
	table.insert(used2, second[1])
	_name = _name..second[1]
	room:setTag("schemeNames_used_1stchar", sgs.QVariant(table.concat(used1, "+")))
	room:setTag("schemeNames_used_2ndchar", sgs.QVariant(table.concat(used2, "+")))
	return ""..first[1]..second[1]
end

--统计【机关】技能个数，等于7个禁止发动
function countSchemeNum(room)
	local sum = 0
	for _, pe in sgs.qlist(room:getAlivePlayers()) do
		for _, skill in sgs.qlist(pe:getVisibleSkillList()) do
			if string.find(skill:objectName(), "sgkgodjiguan_") then
				sum = sum + 1
			end
		end
	end
	return sum
end

--判断某角色是否有【机关】技能
function hasSchemeSkill(target)
	local has = false
	for _, skill in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(skill:objectName(), "sgkgodjiguan_") then
			has = true
			break
		end
	end
	return has
end


sgs.LoadTranslationTable{
	["sgkgodjiguan_jiazi"] = "甲子",
	["sgkgodjiguan_jiachou"] = "甲丑",
	["sgkgodjiguan_jiayin"] = "甲寅",
	["sgkgodjiguan_jiamao"] = "甲卯",
	["sgkgodjiguan_jiachen"] = "甲辰",
	["sgkgodjiguan_jiasi"] = "甲巳",
	["sgkgodjiguan_jiawu"] = "甲午",
	["sgkgodjiguan_jiawei"] = "甲未",
	["sgkgodjiguan_jiashen"] = "甲申",
	["sgkgodjiguan_jiayou"] = "甲酉",
	["sgkgodjiguan_jiaxu"] = "甲戌",
	["sgkgodjiguan_jiahai"] = "甲亥",
	["sgkgodjiguan_yizi"] = "乙子",
	["sgkgodjiguan_yichou"] = "乙丑",
	["sgkgodjiguan_yiyin"] = "乙寅",
	["sgkgodjiguan_yimao"] = "乙卯",
	["sgkgodjiguan_yichen"] = "乙辰",
	["sgkgodjiguan_yisi"] = "乙巳",
	["sgkgodjiguan_yiwu"] = "乙午",
	["sgkgodjiguan_yiwei"] = "乙未",
	["sgkgodjiguan_yishen"] = "乙申",
	["sgkgodjiguan_yiyou"] = "乙酉",
	["sgkgodjiguan_yixu"] = "乙戌",
	["sgkgodjiguan_yihai"] = "乙亥",
	["sgkgodjiguan_bingzi"] = "丙子",
	["sgkgodjiguan_bingchou"] = "丙丑",
	["sgkgodjiguan_bingyin"] = "丙寅",
	["sgkgodjiguan_bingmao"] = "丙卯",
	["sgkgodjiguan_bingchen"] = "丙辰",
	["sgkgodjiguan_bingsi"] = "丙巳",
	["sgkgodjiguan_bingwu"] = "丙午",
	["sgkgodjiguan_bingwei"] = "丙未",
	["sgkgodjiguan_bingshen"] = "丙申",
	["sgkgodjiguan_bingyou"] = "丙酉",
	["sgkgodjiguan_bingxu"] = "丙戌",
	["sgkgodjiguan_binghai"] = "丙亥",
	["sgkgodjiguan_dingzi"] = "丁子",
	["sgkgodjiguan_dingchou"] = "丁丑",
	["sgkgodjiguan_dingyin"] = "丁寅",
	["sgkgodjiguan_dingmao"] = "丁卯",
	["sgkgodjiguan_dingchen"] = "丁辰",
	["sgkgodjiguan_dingsi"] = "丁巳",
	["sgkgodjiguan_dingwu"] = "丁午",
	["sgkgodjiguan_dingwei"] = "丁未",
	["sgkgodjiguan_dingshen"] = "丁申",
	["sgkgodjiguan_dingyou"] = "丁酉",
	["sgkgodjiguan_dingxu"] = "丁戌",
	["sgkgodjiguan_dinghai"] = "丁亥",
	["sgkgodjiguan_wuzi"] = "戊子",
	["sgkgodjiguan_wuchou"] = "戊丑",
	["sgkgodjiguan_wuyin"] = "戊寅",
	["sgkgodjiguan_wumao"] = "戊卯",
	["sgkgodjiguan_wuchen"] = "戊辰",
	["sgkgodjiguan_wusi"] = "戊巳",
	["sgkgodjiguan_wuwu"] = "戊午",
	["sgkgodjiguan_wuwei"] = "戊未",
	["sgkgodjiguan_wushen"] = "戊申",
	["sgkgodjiguan_wuyou"] = "戊酉",
	["sgkgodjiguan_wuxu"] = "戊戌",
	["sgkgodjiguan_wuhai"] = "戊亥",
	["sgkgodjiguan_jizi"] = "己子",
	["sgkgodjiguan_jichou"] = "己丑",
	["sgkgodjiguan_jiyin"] = "己寅",
	["sgkgodjiguan_jimao"] = "己卯",
	["sgkgodjiguan_jichen"] = "己辰",
	["sgkgodjiguan_jisi"] = "己巳",
	["sgkgodjiguan_jiwu"] = "己午",
	["sgkgodjiguan_jiwei"] = "己未",
	["sgkgodjiguan_jishen"] = "己申",
	["sgkgodjiguan_jiyou"] = "己酉",
	["sgkgodjiguan_jixu"] = "己戌",
	["sgkgodjiguan_jihai"] = "己亥",
	["sgkgodjiguan_gengzi"] = "庚子",
	["sgkgodjiguan_gengchou"] = "庚丑",
	["sgkgodjiguan_gengyin"] = "庚寅",
	["sgkgodjiguan_gengmao"] = "庚卯",
	["sgkgodjiguan_gengchen"] = "庚辰",
	["sgkgodjiguan_gengsi"] = "庚巳",
	["sgkgodjiguan_gengwu"] = "庚午",
	["sgkgodjiguan_gengwei"] = "庚未",
	["sgkgodjiguan_gengshen"] = "庚申",
	["sgkgodjiguan_gengyou"] = "庚酉",
	["sgkgodjiguan_gengxu"] = "庚戌",
	["sgkgodjiguan_genghai"] = "庚亥",
	["sgkgodjiguan_xinzi"] = "辛子",
	["sgkgodjiguan_xinchou"] = "辛丑",
	["sgkgodjiguan_xinyin"] = "辛寅",
	["sgkgodjiguan_xinmao"] = "辛卯",
	["sgkgodjiguan_xinchen"] = "辛辰",
	["sgkgodjiguan_xinsi"] = "辛巳",
	["sgkgodjiguan_xinwu"] = "辛午",
	["sgkgodjiguan_xinwei"] = "辛未",
	["sgkgodjiguan_xinshen"] = "辛申",
	["sgkgodjiguan_xinyou"] = "辛酉",
	["sgkgodjiguan_xinxu"] = "辛戌",
	["sgkgodjiguan_xinhai"] = "辛亥",
	["sgkgodjiguan_renzi"] = "壬子",
	["sgkgodjiguan_renchou"] = "壬丑",
	["sgkgodjiguan_renyin"] = "壬寅",
	["sgkgodjiguan_renmao"] = "壬卯",
	["sgkgodjiguan_renchen"] = "壬辰",
	["sgkgodjiguan_rensi"] = "壬巳",
	["sgkgodjiguan_renwu"] = "壬午",
	["sgkgodjiguan_renwei"] = "壬未",
	["sgkgodjiguan_renshen"] = "壬申",
	["sgkgodjiguan_renyou"] = "壬酉",
	["sgkgodjiguan_renxu"] = "壬戌",
	["sgkgodjiguan_renhai"] = "壬亥",
	["sgkgodjiguan_guizi"] = "癸子",
	["sgkgodjiguan_guichou"] = "癸丑",
	["sgkgodjiguan_guiyin"] = "癸寅",
	["sgkgodjiguan_guimao"] = "癸卯",
	["sgkgodjiguan_guichen"] = "癸辰",
	["sgkgodjiguan_guisi"] = "癸巳",
	["sgkgodjiguan_guiwu"] = "癸午",
	["sgkgodjiguan_guiwei"] = "癸未",
	["sgkgodjiguan_guishen"] = "癸申",
	["sgkgodjiguan_guiyou"] = "癸酉",
	["sgkgodjiguan_guixu"] = "癸戌",
	["sgkgodjiguan_guihai"] = "癸亥",
}


tiangong_targets_me_welfare = true  --特殊福利：这一项如果变为true，那么“天工”备选的【可执行目标】中，有较大概率包含“你”这个选项
sgkgodtiangong = sgs.CreateTriggerSkill{
	name = "sgkgodtiangong",
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if countSchemeNum(room) >= 7 then return false end
		if event == sgs.GameStart then
			for i = 1, 2 do
				if player:askForSkillInvoke(self:objectName(), data) then
					local scheme_timings, scheme_targets, scheme_effects = randomGetN(tiangong_timings, 3), randomGetN(tiangong_targets, 3), randomGetN(tiangong_effects, 3)
					local scheme_name = schemeName(player)
					local new_scheme_infos = {}
					table.insert(new_scheme_infos, scheme_name)
					local s_timings = {}
					for _, _sc in pairs(scheme_timings) do
						if table.contains(tiangong_phases, _sc) then 
							table.insert(s_timings, _sc)
						else
							local multi = {"".._sc.."1", "".._sc.."2", "".._sc.."3"}
							table.insert(s_timings, multi[math.random(1, 3)])
						end
					end
					local timing = room:askForChoice(player, "tiangong_timings", table.concat(s_timings, "+"))  --选择发动时机
					if tonumber(string.sub(timing, -1, -1)) == nil then
						table.insert(new_scheme_infos, timing)
					else
						table.insert(new_scheme_infos, string.sub(timing, 1, -2))
					end
					if tiangong_targets_me_welfare == true then
						if not table.contains(scheme_targets, "niziji") then
							if math.random(1, 100) <= 75 then 
								local ri = math.random(1, 3)
								table.remove(scheme_targets, ri)
								table.insert(scheme_targets, ri, "niziji")
							end
						end
					end
					player:removeTag("tiangong_timing_AI")
					player:setTag("tiangong_timing_AI", sgs.QVariant(timing))
					local target = room:askForChoice(player, "tiangong_targets", table.concat(scheme_targets, "+"))  --选择执行目标
					table.insert(new_scheme_infos, target)
					player:removeTag("tiangong_targets_AI")
					player:setTag("tiangong_targets_AI", sgs.QVariant(target))
					local effect = room:askForChoice(player, "tiangong_effects", table.concat(scheme_effects, "+"))  --选择技能效果
					table.insert(new_scheme_infos, effect)
					player:removeTag("tiangong_effects_AI")
					player:setTag("tiangong_effects_AI", sgs.QVariant(effect))
					if tonumber(string.sub(timing, -1, -1)) == nil then
						table.insert(new_scheme_infos, "0")
					else
						table.insert(new_scheme_infos, string.sub(timing, -1, -1))
					end
					room:setTag(scheme_name, sgs.QVariant(table.concat(new_scheme_infos, "+")))  --记录信息：机关技能名、发动时机、执行目标、技能效果、限制次数（0代表不限制）
					player:setTag("tiangong_schemesetup_AI", sgs.QVariant(table.concat(new_scheme_infos, "+")))
					local prompt = string.format("@sgkgodtiangong_scheme:%s:%s:%s:%s", scheme_name, timing, target, effect)
					local who = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), prompt)
					player:removeTag("tiangong_schemesetup_AI")
					room:doAnimate(1, player:objectName(), who:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local msg = sgs.LogMessage()
					msg.type = "#tiangongSetup"
					msg.from = player
					msg.arg = scheme_name
					msg.arg2 = timing
					msg.arg3 = target
					msg.arg4 = effect
					room:sendLog(msg)
					local sgkgodtiangong_scheme = -1
					for _, _prototype in ipairs(scheme_prototypes) do
						if scheme_name ~= "" and _prototype:objectName() == scheme_name then
							sgkgodtiangong_scheme = _prototype
							break
						end
					end
					if sgkgodtiangong_scheme ~= -1 then
						room:acquireSkill(who, sgkgodtiangong_scheme)
						updateSchemeSkill(who, sgkgodtiangong_scheme:objectName())
					end
				else
					break
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName(), data) then
					local scheme_timings, scheme_targets, scheme_effects = randomGetN(tiangong_timings, 3), randomGetN(tiangong_targets, 3), randomGetN(tiangong_effects, 3)
					local scheme_name = schemeName(player)
					local new_scheme_infos = {}
					table.insert(new_scheme_infos, scheme_name)
					local s_timings = {}
					for _, _sc in pairs(scheme_timings) do
						if table.contains(tiangong_phases, _sc) then 
							table.insert(s_timings, _sc)
						else
							local multi = {"".._sc.."1", "".._sc.."2", "".._sc.."3"}
							table.insert(s_timings, multi[math.random(1, 3)])
						end
					end
					local timing = room:askForChoice(player, "tiangong_timings", table.concat(s_timings, "+"))  --选择发动时机
					if tonumber(string.sub(timing, -1, -1)) == nil then
						table.insert(new_scheme_infos, timing)
					else
						table.insert(new_scheme_infos, string.sub(timing, 1, -2))
					end
					if tiangong_targets_me_welfare == true then
						if not table.contains(scheme_targets, "niziji") then
							if math.random(1, 100) <= 75 then 
								local ri = math.random(1, 3)
								table.remove(scheme_targets, ri)
								table.insert(scheme_targets, ri, "niziji")
							end
						end
					end
					player:removeTag("tiangong_timing_AI")
					player:setTag("tiangong_timing_AI", sgs.QVariant(timing))
					local target = room:askForChoice(player, "tiangong_targets", table.concat(scheme_targets, "+"))  --选择执行目标
					table.insert(new_scheme_infos, target)
					player:removeTag("tiangong_targets_AI")
					player:setTag("tiangong_targets_AI", sgs.QVariant(target))
					local effect = room:askForChoice(player, "tiangong_effects", table.concat(scheme_effects, "+"))  --选择技能效果
					table.insert(new_scheme_infos, effect)
					player:removeTag("tiangong_effects_AI")
					player:setTag("tiangong_effects_AI", sgs.QVariant(effect))
					if tonumber(string.sub(timing, -1, -1)) == nil then
						table.insert(new_scheme_infos, "0")
					else
						table.insert(new_scheme_infos, string.sub(timing, -1, -1))
					end
					room:setTag(scheme_name, sgs.QVariant(table.concat(new_scheme_infos, "+")))  --记录信息：机关技能名、发动时机、执行目标、技能效果、限制次数（0代表不限制）
					player:setTag("tiangong_schemesetup_AI", sgs.QVariant(table.concat(new_scheme_infos, "+")))
					local prompt = string.format("@sgkgodtiangong_scheme:%s:%s:%s:%s", scheme_name, timing, target, effect)
					local who = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), prompt)
					player:removeTag("tiangong_schemesetup_AI")
					room:doAnimate(1, player:objectName(), who:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local msg = sgs.LogMessage()
					msg.type = "#tiangongSetup"
					msg.from = player
					msg.arg = scheme_name
					msg.arg2 = timing
					msg.arg3 = target
					msg.arg4 = effect
					room:sendLog(msg)
					local sgkgodtiangong_scheme = -1
					for _, _prototype in ipairs(scheme_prototypes) do
						if scheme_name ~= "" and _prototype:objectName() == scheme_name then
							sgkgodtiangong_scheme = _prototype
							break
						end
					end
					if sgkgodtiangong_scheme ~= -1 then
						room:acquireSkill(who, sgkgodtiangong_scheme)
						updateSchemeSkill(who, sgkgodtiangong_scheme:objectName())
					end
				end
			end
		end
		return false
	end
}


sgkgodsphuangyueying:addSkill(sgkgodtiangong)


--[[
	技能名：玲珑
	相关武将：SP神黄月英
	技能描述：当其他角色令你受到伤害/失去体力/减体力上限/失去技能时，你可以令你失去一个非初始技能以抵消对应效果，或令一名其他角色失去1个机关技能，然后
	将此效果转移给该角色。
	引用：sgkgodlinglong, sgkgodlinglonglose
]]--
function getOtherSkills(player)
	local others = {}
	for _, skill in sgs.qlist(player:getVisibleSkillList()) do
		if not player:hasInnateSkill(skill:objectName()) then table.insert(others, skill:objectName()) end
	end
	return others
end

--统计可【玲珑】的角色
function getLinglongTargets(yueying)
	local room = sgs.Sanguosha:currentRoom()
	local targets = sgs.SPlayerList()
	local extra = getOtherSkills(yueying)
	if #extra > 0 then targets:append(yueying) end
	for _, p in sgs.qlist(room:getOtherPlayers(yueying)) do
		if hasSchemeSkill(p) then targets:append(p) end
	end
	return targets
end

function getSchemeSkills(target)
	local schemes = {}
	for _, sk in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(sk:objectName(), "sgkgodjiguan_") then table.insert(schemes, sk:objectName()) end
	end
	return schemes
end

sgkgodlinglong = sgs.CreateTriggerSkill{
	name = "sgkgodlinglong",
	events = {sgs.DamageInflicted, sgs.PreHpLost, sgs.MaxHpChange, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local targets = getLinglongTargets(player)
			if not targets:isEmpty() and damage.damage > 0 and damage.from and damage.from:objectName() ~= player:objectName() then
				local _q = sgs.QVariant()
				_q:setValue(damage)
				player:setTag("linglong_damageData", _q)
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "@linglong_damage:"..tostring(damage.damage), true, true)
				player:removeTag("linglong_damageData")
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					local _t = sgs.QVariant()
					_t:setValue(to)
					if to:objectName() == player:objectName() then
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getOtherSkills(player), "+"), _t)
						room:addPlayerMark(player, to_lose.."_mark")
						room:handleAcquireDetachSkills(player, "-"..to_lose)
						room:setPlayerMark(player, to_lose.."_mark", 0)
						return true
					else
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getSchemeSkills(to), "+"), _t)
						room:handleAcquireDetachSkills(to, "-"..to_lose)
						local sourcereason = -1
						if damage.card then sourcereason = damage.card end
						if damage.reason then sourcereason = damage.reason end
						if sourcereason == -1 then sourcereason = nil end
						local source = -1
						if damage.from then source = damage.from else source = nil end
						room:damage(sgs.DamageStruct(sourcereason, source, to, damage.damage, damage.nature))
						return true
					end
				end
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			local targets = getLinglongTargets(player)
			if not targets:isEmpty() and lose.lose > 0 and lose.from and lose.from:objectName() ~= player:objectName() then
				local _q = sgs.QVariant()
				_q:setValue(lose)
				player:setTag("linglong_losehpData", _q)
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "@linglong_lose:"..tostring(lose.lose), true, true)
				player:removeTag("linglong_losehpData")
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					local _t = sgs.QVariant()
					_t:setValue(to)
					if to:objectName() == player:objectName() then
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getOtherSkills(player), "+"), _t)
						room:addPlayerMark(player, to_lose.."_mark")
						room:handleAcquireDetachSkills(player, "-"..to_lose)
						room:setPlayerMark(player, to_lose.."_mark", 0)
						return true
					else
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getSchemeSkills(to), "+"), _t)
						room:handleAcquireDetachSkills(to, "-"..to_lose)
						lose.to = to
						data:setValue(lose)
					end
				end
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			local targets = getLinglongTargets(player)
			if not targets:isEmpty() and change.change < 0 and (not string.find(change.reason, "sgkgodjiguan_")) then
				local x = 0 - change.change
				local _q = sgs.QVariant()
				_q:setValue(change)
				player:setTag("linglong_maxhpData", _q)
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "@linglong_maxhp:"..tostring(x), true, true)
				player:removeTag("linglong_maxhpData")
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					local _t = sgs.QVariant()
					_t:setValue(to)
					if to:objectName() == player:objectName() then
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getOtherSkills(player), "+"), _t)
						room:addPlayerMark(player, to_lose.."_mark")
						room:handleAcquireDetachSkills(player, "-"..to_lose)
						room:setPlayerMark(player, to_lose.."_mark", 0)
						return true
					else
						local to_lose = room:askForChoice(player, self:objectName(), table.concat(getSchemeSkills(to), "+"), _t)
						room:handleAcquireDetachSkills(to, "-"..to_lose)
						change.who = to
						data:setValue(change)
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if player:getMark(data:toString().."_temp_skill") > 0 then return false end
			if player:getMark(data:toString().."_mark") == 0 or player:hasInnateSkill(data:toString()) then
				local targets = getLinglongTargets(player)
				if (not targets:isEmpty()) and (not player:getTag("hunliesp_global_resistSkill"):toBool()) then
					player:setTag("linglong_loseskillData", sgs.QVariant(data:toString()))
					local to = room:askForPlayerChosen(player, targets, self:objectName(), "@linglong_loseskill:"..data:toString(), true, true)
					player:removeTag("linglong_loseskillData")
					if to then
						room:doAnimate(1, player:objectName(), to:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
						local _t = sgs.QVariant()
						_t:setValue(to)
						if to:objectName() == player:objectName() then
							local to_lose = room:askForChoice(player, self:objectName(), table.concat(getOtherSkills(player), "+"), _t)
							room:addPlayerMark(player, to_lose.."_mark")
							room:handleAcquireDetachSkills(player, "-"..to_lose)
							room:setPlayerMark(player, to_lose.."_mark", 0)
							room:addPlayerMark(player, data:toString().."_temp_skill")
							room:handleAcquireDetachSkills(player, data:toString())
							room:setPlayerMark(player, data:toString().."_temp_skill")
							player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
						else
							room:handleAcquireDetachSkills(player, data:toString())
							player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
							local to_lose = room:askForChoice(player, self:objectName(), table.concat(getSchemeSkills(to), "+"), _t)
							room:handleAcquireDetachSkills(to, "-"..to_lose)
							local skills = sgs.QList2Table(to:getVisibleSkillList())
							if #skills > 0 then room:handleAcquireDetachSkills(to, "-"..skills[math.random(1, #skills)]:objectName()) end
						end
					end
				end
			end
		end
		return false
	end
}

sgkgodlinglonglose = sgs.CreateTriggerSkill{
	name = "#sgkgodlinglonglose",
	events = {sgs.EventLoseSkill},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if data:toString() == "sgkgodlinglong" and player:hasSkill(self:objectName()) then
			local targets = getLinglongTargets(player)
			if (not targets:isEmpty()) and (not player:getTag("hunliesp_global_resistSkill"):toBool()) then
				player:setTag("linglong_loseskillData", sgs.QVariant(data:toString()))
				local to = room:askForPlayerChosen(player, targets, "sgkgodlinglong", "@linglong_loseskill:"..data:toString(), true, true)
				player:removeTag("linglong_loseskillData")
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					room:broadcastSkillInvoke("sgkgodlinglong", math.random(1, 2))
					local _t = sgs.QVariant()
					_t:setValue(to)
					if to:objectName() == player:objectName() then
						local to_lose = room:askForChoice(player, "sgkgodlinglong", table.concat(getOtherSkills(player), "+"), _t)
						room:addPlayerMark(player, to_lose.."_mark")
						room:handleAcquireDetachSkills(player, "-"..to_lose)
						room:setPlayerMark(player, to_lose.."_mark", 0)
						room:addPlayerMark(player, data:toString().."_temp_skill")
						room:handleAcquireDetachSkills(player, data:toString())
						room:setPlayerMark(player, data:toString().."_temp_skill")
						player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
					else
						room:handleAcquireDetachSkills(player, data:toString())
						player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
						local to_lose = room:askForChoice(player, "sgkgodlinglong", table.concat(getSchemeSkills(to), "+"), _t)
						room:handleAcquireDetachSkills(to, "-"..to_lose)
						local skills = sgs.QList2Table(to:getVisibleSkillList())
						if #skills > 0 then room:handleAcquireDetachSkills(to, "-"..skills[math.random(1, #skills)]:objectName()) end
					end
				end
			end
		end
	end
}


sgkgodsphuangyueying:addSkill(sgkgodlinglong)
sgkgodsphuangyueying:addSkill(sgkgodlinglonglose)
extension:insertRelatedSkills("sgkgodlinglong", "#sgkgodlinglonglose")


sgs.LoadTranslationTable{
    ["sgkgodsphuangyueying"] = "SP神黄月英",
	["&sgkgodsphuangyueying"] = "神黄月英",
	["#sgkgodsphuangyueying"] = "巧绝天艺",
	["~sgkgodsphuangyueying"] = "纵有慧心，乱世难安……",  --除了我的双生瞬影梦蝶罗刹鬼躯知天乱政阴阳无双左幽，游戏里真的有人听过这句台词吗？
	["sgkgodtiangong"] = "天工",
	["$sgkgodtiangong1"] = "巧艺天工，燃灯昼同。",
	["$sgkgodtiangong2"] = "机关奇术，工巧若神。",
	[":sgkgodtiangong"] = "游戏开始/准备阶段/回合结束时，你可以创造2/1/1个机关技能并令一名角色获得之。所有角色至多拥有7个机关技能。",
	["tiangong_timings"] = "请选择【天工】机关的时机",
	["tiangong_targets"] = "请选择【天工】机关的执行角色",
	["tiangong_effects"] = "请选择【天工】机关的效果",
	["@sgkgodtiangong_scheme"] = "请选择一名其他角色获得此机关（【%src】锁定技，%dest，%arg%arg2。）",
	["#tiangongSetup"] = "%from 创造了一个名为“%arg”的机关技能：“<font color=\"yellow\"><b>锁定技，</b></font>%arg2<font color=\"yellow\"><b>"..
	"，</b></font>%arg3%arg4<font color=\"yellow\"><b>。</b></font>”",
	["sgkgodlinglong"] = "玲珑",
	["$sgkgodlinglong1"] = "心罗锦绣，七窍玲珑。",
	["$sgkgodlinglong2"] = "星眸流转，顾盼生姿。",
	[":sgkgodlinglong"] = "当其他角色令你受到伤害/失去体力/减体力上限/失去技能时，你可以令你失去一个非初始技能以抵消对应效果，或令一名其他角色"..
	"失去1个机关技能，然后将此效果转移给该角色。",
	["@linglong_damage"] = "你可以发动“玲珑”以防止受到%src点伤害（选择其他有【机关】技能的角色时，此效果转移给该角色）",
	["@linglong_lose"] = "你可以发动“玲珑”以防止失去%src点体力（选择其他有【机关】技能的角色时，此效果转移给该角色）",
	["@linglong_maxhp"] = "你可以发动“玲珑”以防止失去%src点体力上限（选择其他有【机关】技能的角色时，此效果转移给该角色）",
	["@linglong_loseskill"] = "你可以发动“玲珑以防止失去技能“%src”（选择其他有【机关】技能的角色时，此效果转移给该角色）",
	["designer:sgkgodsphuangyueying"] = "极略三国",
	["illustrator:sgkgodsphuangyueying"] = "极略三国",
	["cv:sgkgodsphuangyueying"] = "极略三国",
}


--封天绝地的青龙帝君
--SP神关羽
sgkgodspguanyu = sgs.General(extension, "sgkgodspguanyu", "sy_god", 4, true)


--[[
	技能名：斩月
	相关武将：SP神关羽
	技能描述：当你使用【杀】指定唯一目标后，你可以令至多两名其他角色也成为目标（你指定的目标和包含此【杀】目标在内的角色座次须连续），然后此【杀】无视防具、不计入次数限制且造成目标
	一半体力的伤害（向上取整），此【杀】结算后，你摸此【杀】造成伤害总数的牌。
	引用：sgkgodzhanyue
]]--
sgkgodzhanyue = sgs.CreateTriggerSkill{
	name = "sgkgodzhanyue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecifying, sgs.DamageCaused, sgs.Damage, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") and use.to:length() == 1 then
				local _q = sgs.QVariant()
				local to = use.to:first()
				_q:setValue(to)
				if player:askForSkillInvoke(self:objectName(), _q) then
					room:broadcastSkillInvoke(self:objectName())
					room:setCardFlag(use.card, "zhanyue_buff")
					room:addPlayerHistory(player, use.card:getClassName(), -1)
					local targets1, targets2 = sgs.SPlayerList(), sgs.SPlayerList()
					for _, t in sgs.qlist(room:getOtherPlayers(player)) do
						if t:objectName() ~= to:objectName() and to:isAdjacentTo(t) then targets1:append(t) end
					end
					local extargets = sgs.SPlayerList()
					if not targets1:isEmpty() then
						local first  = room:askForPlayerChosen(player, targets1, self:objectName(), "@zhanyue-target1:"..to:objectName(), true, false)
						if first then
							use.to:append(first)
							extargets:append(first)
							for _, p in sgs.qlist(room:getOtherPlayers(player)) do
								if p:objectName() ~= to:objectName() and p:objectName() ~= first:objectName() then
									if first:isAdjacentTo(p) or to:isAdjacentTo(p) then targets2:append(p) end
								end
							end
							if not targets2:isEmpty() then
								local second  = room:askForPlayerChosen(player, targets2, self:objectName(), "@zhanyue-target2:"..to:objectName().."::"..first:objectName(), true, false)
								if second then
									use.to:append(second)
									extargets:append(second)
								end
							end
						end
					end
					room:sortByActionOrder(use.to)
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = self:objectName()
					msg.card_str = use.card:toString()
					if not extargets:isEmpty() then
						msg.to = extargets
						msg.type = "#zhangyueExtratargets"
						room:sendLog(msg)
					else
						msg.type = "#zhangyueBuff"
						room:sendLog(msg)
					end
					for _, t in sgs.qlist(use.to) do
						room:doAnimate(1, player:objectName(), t:objectName())
						t:addQinggangTag(use.card)
					end
					data:setValue(use)
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("zhanyue_buff") and (not damage.transfer) then
				damage.damage = math.ceil(damage.to:getHp()/2)
				data:setValue(damage)
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("zhanyue_buff") then
				room:addPlayerMark(player, self:objectName(), damage.damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:hasFlag("zhanyue_buff") then
				room:setCardFlag(use.card, "-zhanyue_buff")
				if player:getMark(self:objectName()) > 0 then
					local x = player:getMark(self:objectName())
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = tostring(x)
					msg.type = "#zhangyueDraw"
					msg.card_str = use.card:toString()
					room:sendLog(msg)
					room:removePlayerMark(player, self:objectName(), x)
					player:drawCards(x, self:objectName())
				end
			end
		end
		return false
	end
}


sgkgodspguanyu:addSkill(sgkgodzhanyue)


--[[
	技能名：封天
	相关武将：SP神关羽
	技能描述：其他角色的准备阶段，你可以弃置一张牌，若如此做，该角色于本回合内首次摸牌、弃置牌或使用本回合未使用的牌名的牌后，你视为对其使用【杀】，若你弃置的牌为【杀】，
	你令其所有技能无效，上述效果持续至本回合结束或其对你造成伤害。
	引用：sgkgodfengtian
]]--
sgkgodfengtian = sgs.CreateTriggerSkill{
	name = "sgkgodfengtian",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.DrawNCards, sgs.CardsMoveOneTime, sgs.CardFinished, sgs.Damage, sgs.EventAcquireSkill},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if room:findPlayerBySkillName(self:objectName()) == nil then return false end
			local gy = room:findPlayerBySkillName(self:objectName())
			if player:getPhase() == sgs.Player_Start and player:objectName() ~= gy:objectName() and (not gy:isNude()) then
				if player:isDead() then return false end
				local _q = sgs.QVariant()
				_q:setValue(player)
				if gy:askForSkillInvoke(self:objectName(), _q) then
					local card = room:askForCard(gy, ".!", "@fengtian-target:"..player:objectName(), _q, sgs.Card_MethodNone)
					if card then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, gy:objectName(), self:objectName(), "")
						room:throwCard(card, reason, nil)
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, "&"..self:objectName().."-Clear")
						room:doAnimate(1, gy:objectName(), player:objectName())
						player:setTag(self:objectName(), sgs.QVariant(true))
						if card:isKindOf("Slash") then
							local to_invalid = {}
							for _, sk in sgs.qlist(player:getVisibleSkillList()) do
								table.insert(to_invalid, sk:objectName())
							end
							if #to_invalid > 0 then
								player:setTag("fengtian_forbid", sgs.QVariant(table.concat(to_invalid, "+")))
								local tob = sgs.SPlayerList()
								tob:append(player)
								for _, skill_qc in ipairs(to_invalid) do
									if player:getMark(self:objectName().."_forbid_"..skill_qc) == 0 then
										room:addPlayerMark(player, self:objectName().."_forbid_"..skill_qc)
										if player:getMark("Qingcheng"..skill_qc) == 0 then
											room:addPlayerMark(player, "Qingcheng"..skill_qc)
											for _, p in sgs.qlist(room:getAlivePlayers()) do
												room:filterCards(p, p:getCards("hej"), true)
											end
											local msg = sgs.LogMessage()
											msg.from = player
											msg.type = "#fengtianForbid"
											msg.arg = skill_qc
											msg.arg2 = self:objectName()
											room:sendLog(msg)
											room:doBroadcastNotify(tob, sgs.CommandType.S_COMMAND_UPDATE_SKILL, sgs.QVariant(skill_qc))
										end
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getTag(self:objectName()):toBool() == true then
					player:removeTag(self:objectName())
					player:removeTag("fengtian_names")
					local qclist = player:getTag("fengtian_forbid"):toString():split("+")
					local tob = sgs.SPlayerList()
					tob:append(player)
					for _, skill_qc in ipairs(qclist) do
						if player:getMark(self:objectName().."_forbid_"..skill_qc) > 0 then
							room:removePlayerMark(player, self:objectName().."_forbid_"..skill_qc, player:getMark(self:objectName().."_forbid_"..skill_qc))
							if player:getMark("Qingcheng"..skill_qc) > 0 then
								room:removePlayerMark(player, "Qingcheng"..skill_qc, player:getMark("Qingcheng"..skill_qc))
								room:doBroadcastNotify(tob, sgs.CommandType.S_COMMAND_UPDATE_SKILL, sgs.QVariant(skill_qc))
							end
						end
						for _, p in sgs.qlist(room:getAllPlayers()) do
							room:filterCards(p, p:getCards("he"), true)
						end
					end
					player:removeTag("fengtian_forbid")
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if room:findPlayerBySkillName(self:objectName()) == nil then return false end
			local gy = room:findPlayerBySkillName(self:objectName())
			if player:getTag(self:objectName()):toBool() == true or player:getMark("&"..self:objectName().."-Clear") > 0 then
				if draw.num > 0 and player:getMark("fengtian_draw-Clear") == 0 then
					room:addPlayerMark(player, "fengtian_draw-Clear")
					room:sendCompulsoryTriggerLog(gy, self:objectName(), true, true)
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_sgkgodfengtian")
					slash:deleteLater()
					local use = sgs.CardUseStruct()
					use.from = gy
					use.to:append(player)
					use.card = slash
					room:useCard(use, false)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if room:findPlayerBySkillName(self:objectName()) == nil then return false end
			local gy = room:findPlayerBySkillName(self:objectName())
			if move.from and gy and move.from:objectName() == player:objectName() and (player:getMark("&"..self:objectName().."-Clear") > 0 or player:getTag(self:objectName()):toBool() == true) then
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					if player:getMark("fengtian_discard-Clear") == 0 then
						room:addPlayerMark(player, "fengtian_discard-Clear")
						room:sendCompulsoryTriggerLog(gy, self:objectName(), true, true)
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_sgkgodfengtian")
						slash:deleteLater()
						local use = sgs.CardUseStruct()
						use.from = gy
						use.to:append(player)
						use.card = slash
						room:useCard(use, false)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if room:findPlayerBySkillName(self:objectName()) == nil then return false end
			local gy = room:findPlayerBySkillName(self:objectName())
			if use.from and use.from:objectName() == player:objectName() and (player:getMark("&"..self:objectName().."-Clear") > 0 or player:getTag(self:objectName()):toBool() == true) then
				local names = player:getTag("fengtian_names"):toString():split("+")
				if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and (not table.contains(names, use.card:objectName())) then
					table.insert(names, use.card:objectName())
					player:setTag("fengtian_names", sgs.QVariant(table.concat(names, "+")))
					room:sendCompulsoryTriggerLog(gy, self:objectName(), true, true)
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_sgkgodfengtian")
					slash:deleteLater()
					local use = sgs.CardUseStruct()
					use.from = gy
					use.to:append(player)
					use.card = slash
					room:useCard(use, false)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if room:findPlayerBySkillName(self:objectName()) == nil then return false end
			local gy = room:findPlayerBySkillName(self:objectName())
			if damage.from and damage.from:objectName() == player:objectName() and (player:getMark("&"..self:objectName().."-Clear") > 0 or player:getTag(self:objectName()):toBool() == true) then
				room:removePlayerMark(player, "&"..self:objectName().."-Clear", player:getMark("&"..self:objectName().."-Clear"))
				room:removePlayerMark(player, "fengtian_draw-Clear", player:getMark("fengtian_draw-Clear"))
				room:removePlayerMark(player, "fengtian_discard-Clear", player:getMark("fengtian_discard-Clear"))
				local qclist = player:getTag("fengtian_forbid"):toString():split("+")
				local tob = sgs.SPlayerList()
				tob:append(player)
				for _, skill_qc in ipairs(qclist) do
					if player:getMark(self:objectName().."_forbid_"..skill_qc) > 0 then
						room:removePlayerMark(player, self:objectName().."_forbid_"..skill_qc, player:getMark(self:objectName().."_forbid_"..skill_qc))
						if player:getMark("Qingcheng"..skill_qc) > 0 then
							room:removePlayerMark(player, "Qingcheng"..skill_qc, player:getMark("Qingcheng"..skill_qc))
							room:doBroadcastNotify(tob, sgs.CommandType.S_COMMAND_UPDATE_SKILL, sgs.QVariant(skill_qc))
						end
					end
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:filterCards(p, p:getCards("he"), true)
					end
				end
				player:removeTag("fengtian_forbid")
				player:removeTag(self:objectName())
				player:removeTag("fengtian_names")
			end
		elseif event == sgs.EventAcquireSkill then
			local skill_name = data:toString()
			if player:getMark("&"..self:objectName().."-Clear") > 0 or player:getTag(self:objectName()):toBool() == true and player:hasSkill(skill_name) then
				local qclist = player:getTag("fengtian_forbid"):toString():split("+")
				table.insert(qclist, skill_name)
				if player:getMark(self:objectName().."_forbid_"..skill_name) == 0 then
					room:addPlayerMark(player, self:objectName().."_forbid_"..skill_name)
					if player:getMark("Qingcheng"..skill_name) == 0 then
						local tob = sgs.SPlayerList()
						tob:append(player)
						room:addPlayerMark(player, "Qingcheng"..skill_name)
						room:doBroadcastNotify(tob, sgs.CommandType.S_COMMAND_UPDATE_SKILL, sgs.QVariant(skill_qc))
					end
				end
				for _, p in sgs.qlist(room:getPlayers()) do
					room:filterCards(p, p:getCards("he"), true)
				end
				player:setTag("fengtian_forbid", sgs.QVariant(table.concat(qclist, "+")))
			end
		end
		return false
	end
}


sgkgodspguanyu:addSkill(sgkgodfengtian)


sgs.LoadTranslationTable{
    ["sgkgodspguanyu"] = "SP神关羽",
	["&sgkgodspguanyu"] = "神关羽",
	["#sgkgodspguanyu"] = "青龙",
	["~sgkgodspguanyu"] = "麦城可葬关某骨，青龙难断忠义魂！",
	["sgkgodzhanyue"] = "斩月",
	["$sgkgodzhanyue1"] = "刀光所至，万军辟易，尔等凡躯，岂堪神锋！",
	["$sgkgodzhanyue2"] = "桃园一诺，忠义不负，此刃既出，天地同戮！",
	[":sgkgodzhanyue"] = "当你使用【杀】指定唯一目标后，你可以令至多两名其他角色也成为目标（你指定的目标和包含此【杀】目标在内的角色座次须连续），"..
	"然后此【杀】无视防具、不计入次数限制且造成目标一半体力的伤害（向上取整），此【杀】结算后，你摸此【杀】造成伤害总数的牌。",
	["@zhanyue-target1"] = "你可以选择一名其他角色，令其也成为此【杀】的目标（座次须与%src连续）",
	["@zhanyue-target2"] = "你可以再选择一名其他角色，令其也成为此【杀】的目标（座次须与%src和%dest连续）",
	["#zhangyueBuff"] = "%from 发动“%arg”令此 %card 无视防具、不计入次数限制且造成目标一半体力的伤害",
	["#zhangyueExtratargets"] = "%from 发动“%arg”令 %to 也成为 %card 的目标，且此 %card 无视防具、不计入次数限制且造成目标一半体力的伤害",
	["#zhangyueDraw"] = "%from 使用的 %card 因“%arg”技能效果累积造成了 %arg2 点伤害，此 %card 结算完毕后 %from 将摸 %arg2 张牌",
	["sgkgodfengtian"] = "封天",
	["$sgkgodfengtian1"] = "天道如炼，神威如狱，此方天地，敕令生死！",
	["$sgkgodfengtian2"] = "汉运未逆，汝命已尽，封天绝地，誓戮奸邪！",
	["@fengtian-target"] = "请弃置一张牌对%src发动“封天”，且若你弃置的是【杀】，%src的所有技能无效直至其回合结束或对你造成伤害",
	[":sgkgodfengtian"] = "其他角色的准备阶段，你可以弃置一张牌，若如此做，该角色于本回合内首次摸牌、弃置牌或使用每种牌名的牌后，你视为"..
	"对其使用【杀】，若你弃置的牌为【杀】，你令其所有技能无效，上述效果持续至本回合结束或其对你造成伤害。",
	["#fengtianForbid"] = "%from 的技能“%arg”受到“%arg2”的影响被无效",
	["designer:sgkgodspguanyu"] = "极略三国",
	["illustrator:sgkgodspguanyu"] = "极略三国",
	["cv:sgkgodspguanyu"] = "极略三国",
}
return {extension}