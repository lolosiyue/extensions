--module("extensions.moshen", package.seeall)
extension = sgs.Package("moshen")

sgs.LoadTranslationTable{
	["moshen"] = "魔神",
}

--[[
do
    require  "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	        table.insert(kingdoms, "sy_god")
	config.color_de = "#74029D"
end


sgs.LoadTranslationTable{
	--["sy_god"] = "神",
}
]]

function getExceptionDrawpileIds(except_pattern)
	local room = sgs.Sanguosha:currentRoom()
	local ids = sgs.IntList()
	for _, id in sgs.qlist(room:getDrawPile()) do
		if not sgs.Sanguosha:getCard(id):isKindOf(except_pattern) then ids:append(id) end
	end
	if not ids:isEmpty() then
		return ids
	else
		return sgs.IntList()
	end
end

function getOnePatternIds(pattern)
	local room = sgs.Sanguosha:currentRoom()
	local ids = sgs.IntList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf(pattern) then ids:append(id) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf(pattern) then ids:append(id) end
		end
	end
	if not ids:isEmpty() then
		return ids
	else
		return sgs.IntList()
	end
end

function getOneSuitIds(suit)
	local room = sgs.Sanguosha:currentRoom()
	local ids = sgs.IntList()
	if not room:getDrawPile():isEmpty() then
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):getSuit() == suit then ids:append(id) end
		end
	end
	if not room:getDiscardPile():isEmpty() then
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):getSuit() == suit then ids:append(id) end
		end
	end
	if not ids:isEmpty() then
		return ids
	else
		return sgs.IntList()
	end
end

function hasNullifiedSkill(who)
	local flag = false
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
		if who:getMark("Qingcheng"..sk:objectName()) > 0 then
			flag = true
			break
		end
	end
	return flag or who:getMark("@skill_invalidity") > 0
end

function invalidateRandomSkill(who, room)
	local ava = {}
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
		if who:getMark("Qingcheng"..sk:objectName()) == 0 then table.insert(ava, sk:objectName()) end
	end
	if #ava > 0 then
		local rsk = ava[math.random(1, #ava)]
		room:addPlayerMark(who, "Qingcheng"..rsk)
		local msg = sgs.LogMessage()
		msg.from = who
		msg.type = "#InvalidateRandomSkill"
		msg.arg = rsk
		room:sendLog(msg)
	end
end

function activateRandomSkill(who, room)
	local inv = {}
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
		if who:getMark("Qingcheng"..sk:objectName()) > 0 then table.insert(inv, sk:objectName()) end
	end
	if #inv > 0 then
		local rsk = inv[math.random(1, #inv)]
		room:removePlayerMark(who, "Qingcheng"..rsk)
		local msg = sgs.LogMessage()
		msg.from = who
		msg.type = "#ActivateRandomSkill"
		msg.arg = rsk
		room:sendLog(msg)
	end
end

function allSkillNull(who)
	local flag = false
	local ava = {}
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
		if who:getMark("Qingcheng"..sk:objectName()) == 0 then table.insert(ava, sk:objectName()) end
	end
	if #ava == 0 then flag = true end
	return flag
end

function isSishi(who)
	return not who:getPile("sishi"):isEmpty()
end

function throwRandomEquip(target)
	local area = {}
	local room = sgs.Sanguosha:currentRoom()
	for i = 0, 4 do
		if target:hasEquipArea(i) then table.insert(area, "EquipItem_"..i) end
	end
	if target:hasEquipArea() then
		local area_str = area[math.random(1, #area)]
		local x = tonumber(string.sub(area_str, string.len(area_str), string.len(area_str)))
		target:throwEquipArea(x)
		local msg = sgs.LogMessage()
		msg.to:append(target)
		msg.type = "#AreaBroken"
		msg.arg = area_str
		room:sendLog(msg)
	end
end


function hasCorrespondingEquip(who, i)
	if who:hasEquipArea(i) then
		if i == 0 and who:getWeapon() ~= nil then return true end
		if i == 1 and who:getArmor() ~= nil then return true end
		if i == 2 and who:getDefensiveHorse() ~= nil then return true end
		if i == 3 and who:getOffensiveHorse() ~= nil then return true end
		if i == 4 and who:getTreasure() ~= nil then return true end
	end
	return false
end


function throwRandomEquipWithExtra(source, target, reason)
	local area = {}
	local room = sgs.Sanguosha:currentRoom()
	for i = 0, 4 do
		if target:hasEquipArea(i) then table.insert(area, "EquipItem_"..i) end
	end
	if target:hasEquipArea() then
		local area_str = area[math.random(1, #area)]
		local x = tonumber(string.sub(area_str, string.len(area_str), string.len(area_str)))
		local flag = hasCorrespondingEquip(target, x)
		target:throwEquipArea(x)
		local msg = sgs.LogMessage()
		msg.to:append(target)
		msg.type = "#AreaBroken"
		msg.arg = area_str
		room:sendLog(msg)
		if flag then room:damage(sgs.DamageStruct(reason, source, target, 2, sgs.DamageStruct_Thunder)) end
	end
end


function lackEquipArea(target)
	local area = {}
	for i = 0, 4 do
		if target:hasEquipArea(i) then table.insert(area, "EquipItem_"..i) end
	end
	if #area < 5 then
		return true
	else
		return false
	end
end


function lackedEquipAreaNum(target)
	local n = 5
	for i = 0, 4 do
		if target:hasEquipArea(i) then n = n - 1 end
	end
	return n
end


function lackedEquipNum(target)
	local n = 0
	if target:getWeapon() == nil then n = n + 1 end
	if target:getArmor() == nil then n = n + 1 end
	if target:getOffensiveHorse() == nil then n = n + 1 end
	if target:getDefensiveHorse() == nil then n = n + 1 end
	if target:getTreasure() == nil then n = n + 1 end
	return n
end


function freezePlayer(who)  --冰冻
	local room = who:getRoom()
	room:setPlayerCardLimitation(who, "use,response", ".", false)
	room:setPlayerMark(who, "@cold_snow", 0)
	room:setPlayerMark(who, "@icebrick", 1)
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do  --为了确保“冰冻”能让目标翻面，先封锁所有技能，然后再翻面。
		room:addPlayerMark(who, "skill_frozen_"..sk:objectName())
		room:addPlayerMark(who, "Qingcheng"..sk:objectName())
	end
	if who:faceUp() then who:turnOver() end
	room:broadcastSkillInvoke("frozen_effect")
	local fre = sgs.LogMessage()
	fre.from = who
	fre.type = "#PlayerFrozen"
	room:sendLog(fre)
end
	
function meltPlayer(who)  --解冻
	local room = who:getRoom()
	room:removePlayerCardLimitation(who, "use,response", "." .. "$0")
	room:setPlayerMark(who, "@icebrick", 0)
	if not who:faceUp() then who:turnOver() end  --与“冰冻”的结算相反，解冻后先翻面，然后恢复技能。
	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
		room:setPlayerMark(who, "skill_frozen_"..sk:objectName(), 0)
		room:setPlayerMark(who, "Qingcheng"..sk:objectName(), 0)
	end
	local mlt = sgs.LogMessage()
	mlt.from = who
	mlt.type = "#PlayerMelt"
	room:sendLog(mlt)
end

function isFrozen(yeti)  --判断一名角色是否处于“冰冻”状态
	if yeti:faceUp() then return false end
	if yeti:getMark("@icebrick") == 0 then return false end
	local flag = false
	for _, mark in sgs.list(yeti:getMarkNames()) do
		if string.find(mark, "skill_frozen_") and yeti:getMark(mark) > 0 then
			flag = true
			break
		end
	end
	return flag
end

function isInitiallyFrozen(yeti)  --判断一名角色在自然翻面解除之前是否处于“冰冻”状态
	if yeti:getMark("@icebrick") == 0 then return false end
	local flag = false
	for _, mark in sgs.list(yeti:getMarkNames()) do
		if string.find(mark, "skill_frozen_") and yeti:getMark(mark) > 0 then
			flag = true
			break
		end
	end
	return flag
end

function isOddInteger(int)
	return math.ceil(int/2) - math.floor(int/2) == 1
end

function isEvenInteger(int)
	return math.ceil(int/2) - math.floor(int/2) == 0
end

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

akn_BeforeFrozen = sgs.CreateTriggerSkill{
	name = "#akn_BeforeFrozen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MarkChanged},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local mark = data:toMark()
		if mark.name == "@cold_snow" then
			if player:getMark("@cold_snow") >= 3 then freezePlayer(player) end
		end
	end
}


akn_AfterFrozen = sgs.CreateTriggerSkill{
	name = "#akn_AfterFrozen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnedOver, sgs.Dying, sgs.AskForPeachesDone},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TurnedOver then
			if player:faceUp() and player:getMark("@icebrick") > 0 then meltPlayer(player) end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if isFrozen(dying.who) then
				room:removePlayerCardLimitation(dying.who, "use,response", "." .. "$0")
			end
		elseif event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if isFrozen(dying.who) then
				room:setPlayerCardLimitation(dying.who, "use,response", ".", false)
			end
		end
		return false
	end
}


frozen_effect = sgs.CreateTriggerSkill{
	name = "frozen_effect",
	events = {},
	on_trigger = function()
	end
}


local sks = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#akn_BeforeFrozen") then sks:append(akn_BeforeFrozen) end
if not sgs.Sanguosha:getSkill("#akn_AfterFrozen") then sks:append(akn_AfterFrozen) end
if not sgs.Sanguosha:getSkill("frozen_effect") then sks:append(frozen_effect) end
sgs.Sanguosha:addSkills(sks)


sgs.LoadTranslationTable{
	["#FrozenDamage"] = "%from 处在“<font color = \"#00A0EA\"><b>冰冻<b></font>”状态，受到的伤害从 %arg 点增加至 %arg2 点",
	["#PlayerFrozen"] = "%from 进入了“<font color = \"#00A0EA\"><b>冰冻<b></font>”状态",
	["#PlayerMelt"] = "%from 解除了“<font color = \"#00A0EA\"><b>冰冻<b></font>”状态",
	["EquipItem_0"] = "武器栏",
	["EquipItem_1"] = "防具栏",
	["EquipItem_2"] = "防御马栏",
	["EquipItem_3"] = "进攻马栏",
	["EquipItem_4"] = "宝物栏",
	["#AreaBroken"] = "%to 的 %arg 被废除",
}


guimou_slash = sgs.CreateTriggerSkill{
	name = "guimou_slash",
	events = {},
	on_trigger = function()
	end
}


--[[
	技能名：景纪
	相关武将：神司马师
	技能描述：出牌阶段限一次，你可摸X张牌并回复X点体力（X在你体力值不大于1时为2，大于1时为1）。
	引用：ms_jingji
]]--
ms_jingjiCard = sgs.CreateSkillCard{
	name = "ms_jingji",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local x = 0
		if source:getHp() <= 1 then
			x = 2
		else
			x = 1
		end
		source:drawCards(x, self:objectName())
		local rec = sgs.RecoverStruct()
		rec.recover = x
		rec.who = source
		room:recover(source, rec, true)
	end
}

ms_jingji = sgs.CreateZeroCardViewAsSkill{
	name = "ms_jingji",
	view_as = function()
		return ms_jingjiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ms_jingji")
	end
}


hidden_shisha = sgs.CreateTriggerSkill{
	name = "hidden_shisha",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.CardUsed, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
			if player:getMark("skill_do_shisha") == 0 then return false end
		    if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
			room:sendCompulsoryTriggerLog(player, "sy_shisha")
			room:notifySkillInvoked(player, "sy_shisha")
			room:broadcastSkillInvoke("sy_shisha")
		    for _, t in sgs.qlist(use.to) do
			    local shishaprompt = string.format("shishadiscard:%s", player:objectName())
			    if t:getEquips():length() + t:getHandcardNum() <= 1 then
					room:setPlayerFlag(t, "shisha_done")
				else
					if room:askForDiscard(t, "sy_shisha", 2, 2, true, true, shishaprompt) then
				        room:setPlayerFlag(t, "shisha_failed")
					else
						room:setPlayerFlag(t, "shisha_done")
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if player:getMark("skill_do_shisha") == 0 then return false end
			if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, t in sgs.qlist(use.to) do
				if (not t:hasFlag("shisha_failed")) and (not t:hasFlag("shisha_done")) then
			        local shishaprompt = string.format("shishadiscard:%s", player:objectName())
			        if t:getEquips():length() + t:getHandcardNum() <= 1 then
					    room:setPlayerFlag(t, "shisha_done")
				    else
					    if room:askForDiscard(t, "sy_shisha", 2, 2, true, true, shishaprompt) then
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
					data:setValue(use)
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

hidden_exdraw = sgs.CreateDrawCardsSkill{
	name = "hidden_exdraw",
	global = true,
	draw_num_func = function(self, player, n)
		local x = 0
		if player:hasSkill("ms_juelu") then
			x = x + player:getMark("shoubing_drawc")
		end
		if player:getMark("niyuan_over") > 0 then x = x + 1 end
		return n + x
	end
}

hidden_maxcard = sgs.CreateMaxCardsSkill{
	name = "hidden_maxcard",
	extra_func = function(self, target)
	    local x = 0
		if target:hasSkill("ms_juelu") then
			x = x + target:getMark("shoubing_maxcards")
		end
		if target:getMark("@renpo") >= 3 then
			x = x + 1
		end
		if target:getMark("niyuan_over") >= 1 then
			x = x + 1
		end
		return x
	end
}

hidden_extarget = sgs.CreateTargetModSkill{
	name = "hidden_extarget",
	pattern = ".",
	extra_target_func = function(self, player, card)
	    local x = 0
		if player:getMark("moren_losthp") > 0 and card:isKindOf("Slash") and (not card:getSubcards():isEmpty()) then
		    x = x + player:getMark("moren_losthp")
		end
		if player:hasSkill("ss_shenjian") and card:isKindOf("Slash") and (not card:getSubcards():isEmpty()) then
			x = x + 2
		end
		return x
	end
}

hidden_atkrange = sgs.CreateAttackRangeSkill{
	name = "hidden_atkrange",
	extra_func = function(self, player, include_weapon)
		local n = 0
		if player:getMark("@renpo") >= 1 then n = n + 1 end
		if player:getMark("moren_atk") > 0 then n = n + 9999 end
		if player:hasSkill("ss_shenjian") then n = n + 1 end
		return n
	end
}


hidden_clearcardflag = sgs.CreateTriggerSkill{
	name = "hidden_clearcardflag",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_USE then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					for _, flag in sgs.list(card:getFlags()) do
						if string.find(flag, "_slash_effect") then room:setCardFlag(card, "-"..flag) end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card then
				for _, flag in sgs.list(use.card:getFlags()) do
					if string.find(flag, "_slash_effect") then room:setCardFlag(use.card, "-"..flag) end
				end
			end
		end
	end
}


--[[
	技能名：冰狱
	相关武将：神司马师
	技能描述：锁定技，当你使用【杀】或【决斗】对其他角色造成非火焰伤害时，你令目标获得1个“寒冷”标记。若目标已冻结，你令此伤害+1。
	引用：ms_bingyu
]]--
ms_bingyu = sgs.CreateTriggerSkill{
	name = "ms_bingyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and damage.to:getSeat() ~= player:getSeat() and damage.card then
			if damage.nature == sgs.DamageStruct_Fire then return false end
			if (not damage.card:isKindOf("Slash")) and (not damage.card:isKindOf("Duel")) then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:doAnimate(1, player:objectName(), damage.to:objectName())
			if damage.to:isDead() then return false end
			if isFrozen(damage.to) then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#FrozenDamage"
				msg.from = damage.to
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				room:broadcastSkillInvoke(self:objectName(), 2)
				data:setValue(damage)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(damage.to, "@cold_snow", 1)
			end
		end
		return false
	end
}


--[[
	技能名：魔刃
	相关武将：神司马师
	技能描述：锁定技，当你失去1点体力时，你摸X张牌。若此时在你的回合内，本回合你攻击范围无限，且你使用的下一张【杀】的目标上限+X（X为此时你已损失体力值）。
	引用：ms_bingyu
]]--
ms_moren = sgs.CreateTriggerSkill{
	name = "ms_moren",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpLost, sgs.EventPhaseChanging, sgs.EventLoseSkill, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.HpLost then
			if player:getPhase() ~= sgs.Player_NotActive then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:addPlayerMark(player, "moren_losthp", player:getLostHp())
				room:addPlayerMark(player, "moren_atk")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "moren_losthp", 0)
				room:setPlayerMark(player, "moren_atk", 0)
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				room:setPlayerMark(player, "moren_losthp", 0)
				room:setPlayerMark(player, "moren_atk", 0)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.from:getMark("moren_losthp") > 0 then
				if use.card and use.card:isKindOf("Slash") then
					if use.to and use.to:length() >= 1 then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					end
					room:setPlayerMark(player, "moren_losthp", 0)
				end
			end
		end
		return false
	end
}


--[[
	技能名：天晖
	相关武将：神司马师
	技能描述：锁定技，成为过“成务”目标的角色的准备阶段，你摸1张牌；摸牌阶段，你额外摸1张牌。
	引用：ms_tianhui
]]--
ms_tianhui = sgs.CreateTriggerSkill{
	name = "ms_tianhui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("chengwu_aaabbbccc") > 0 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:notifySkillInvoked(s, self:objectName())
				s:drawCards(1, self:objectName())
			end
		elseif event == sgs.DrawNCards then
			if player:objectName() == s:objectName() then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:notifySkillInvoked(s, self:objectName())
				data:setValue(data:toInt()+1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


local sks = sgs.SkillList()
if not sgs.Sanguosha:getSkill("ms_jingji") then sks:append(ms_jingji) end
if not sgs.Sanguosha:getSkill("ms_bingyu") then sks:append(ms_bingyu) end
if not sgs.Sanguosha:getSkill("ms_tianhui") then sks:append(ms_tianhui) end
if not sgs.Sanguosha:getSkill("ms_moren") then sks:append(ms_moren) end
if not sgs.Sanguosha:getSkill("guimou_slash") then sks:append(guimou_slash) end
if not sgs.Sanguosha:getSkill("hidden_shisha") then sks:append(hidden_shisha) end
if not sgs.Sanguosha:getSkill("hidden_exdraw") then sks:append(hidden_exdraw) end
if not sgs.Sanguosha:getSkill("hidden_maxcard") then sks:append(hidden_maxcard) end
if not sgs.Sanguosha:getSkill("hidden_extarget") then sks:append(hidden_extarget) end
if not sgs.Sanguosha:getSkill("hidden_atkrange") then sks:append(hidden_atkrange) end
if not sgs.Sanguosha:getSkill("hidden_clearcardflag") then sks:append(hidden_clearcardflag) end
sgs.Sanguosha:addSkills(sks)


sgs.LoadTranslationTable{
	["guimou_slash"] = "鬼谋",
	["ms_tianhui"] = "天晖",
	[":ms_tianhui"] = "锁定技，成为过“成务”目标的角色的准备阶段，你摸1张牌；摸牌阶段，你额外摸1张牌。",
	["ms_moren"] = "魔刃",
	[":ms_moren"] = "锁定技，当你失去体力时，若此时在你的回合内，本回合你使用牌无距离限制，且你使用的下一张【杀】的目标上限+X（X为此时你已损失体力值）。",
	["ms_jingji"] = "景纪",
	[":ms_jingji"] = "出牌阶段限一次，你可摸X张牌并回复X点体力（X在你体力值不大于1时为2，大于1时为1）。",
	["ms_bingyu"] = "冰狱",
	["$ms_bingyu1"] = "（冰块）",
	["$ms_bingyu2"] = "（冰块破碎）",
	[":ms_bingyu"] = "锁定技，当你使用【杀】或【决斗】对其他角色造成非火焰伤害时，你令目标获得1个“寒冷”标记。若目标已冻结，你令此伤害+1。",
}


--[[
	技能名：云垂
	相关武将：？？？
	技能描述：锁定技，当非死士角色使用【杀】时，所有非死士角色依次弃置一张牌。
	引用：ss_yunchui
]]--
ss_yunchui = sgs.CreateTriggerSkill{
	name = "ss_yunchui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		if use.from and use.from:getPile("sishi"):isEmpty() then
			if use.card and use.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:notifySkillInvoked(s, self:objectName())
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not isSishi(pe) then room:doAnimate(1, s:objectName(), pe:objectName()) end
				end
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not isSishi(pe) then room:askForDiscard(pe, self:objectName(), 1, 1, false, true) end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：风杨
	相关武将：？？？
	技能描述：锁定技，当死士成为锦囊牌的目标后，其摸一张牌。
	引用：ss_fengyang
]]--
ss_fengyang = sgs.CreateTriggerSkill{
	name = "ss_fengyang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)	
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("TrickCard") and use.to:contains(player) then
			local flag = false
			for _, pe in sgs.qlist(use.to) do
				if isSishi(pe) then flag = true break end
			end
			if flag then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:notifySkillInvoked(s, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, s:objectName(), player:objectName())
				player:drawCards(1, self:objectName())
			end
		end
	end,
	can_trigger = function(self, target)
		return target and isSishi(target)
	end
}



--[[
	技能名：燃魂
	相关武将：？？？
	技能描述：锁定技，回合结束阶段，你与所有非死士角色失去1点体力。
	引用：ss_ranhun
]]--
ss_ranhun = sgs.CreateTriggerSkill{
	name = "ss_ranhun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			targets:append(player)
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSishi(pe) then targets:append(pe) end
			end
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			for _, t in sgs.qlist(targets) do
				room:doAnimate(1, player:objectName(), t:objectName())
			end
			for _, t in sgs.qlist(targets) do
				room:loseHp(t, 1, true, player, self:objectName())
			end
		end
		return false
	end
}


--[[
	技能名：玄冰
	相关武将：？？？
	技能描述：锁定技，准备阶段，你须令一名非死士角色弃置两张牌。
	引用：ss_xuanbing
]]--
ss_xuanbing = sgs.CreateTriggerSkill{
	name = "ss_xuanbing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSishi(pe) then targets:append(pe) end
			end
			if targets:isEmpty() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local t = room:askForPlayerChosen(player, targets, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), t:objectName())
			room:askForDiscard(t, self:objectName(), 2, 2, false, true)
		end
		return false
	end
}


--[[
	技能名：地载
	相关武将：？？？
	技能描述：锁定技，死士角色的回合结束阶段，其摸两张牌。
	引用：ss_dizai
]]--
ss_dizai = sgs.CreateTriggerSkill{
	name = "ss_dizai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Finish then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(s, self:objectName())
			room:notifySkillInvoked(s, self:objectName())
			room:doAnimate(1, s:objectName(), player:objectName())
			player:drawCards(2, self:objectName())
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and isSishi(target)
	end
}


--[[
	技能名：应战
	相关武将：？？？
	技能描述：锁定技，当死士角色成为【杀】的目标后，所有死士角色各摸一张牌。
	引用：ss_yingzhan
]]--
ss_yingzhan = sgs.CreateTriggerSkill{
	name = "ss_yingzhan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)	
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
			local flag = false
			for _, pe in sgs.qlist(use.to) do
				if isSishi(pe) then flag = true break end
			end
			if flag then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:notifySkillInvoked(s, self:objectName())
				local targets = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if isSishi(pe) then targets:append(pe) end
				end
				for _, t in sgs.qlist(targets) do
					if isSishi(t) then room:doAnimate(1, s:objectName(), t:objectName()) end
				end
				for _, t in sgs.qlist(targets) do
					if isSishi(t) then t:drawCards(1, self:objectName()) end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and isSishi(target)
	end
}


--[[
	技能名：灵虚
	相关武将：？？？
	技能描述：锁定技，回合结束阶段，你令体力值最少（或之一）的一名死士角色回复1点体力。
	引用：ss_lingxu
]]--
ss_lingxu = sgs.CreateTriggerSkill{
	name = "ss_lingxu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				if isSishi(pe) then targets:append(pe) end
			end
			if targets:isEmpty() then return false end
			local t2 = sgs.SPlayerList()
			local _min = 9999
			for _, ss in sgs.qlist(targets) do
				_min = math.min(_min, ss:getHp())
			end
			for _, ss in sgs.qlist(targets) do
				if ss:getHp() <= _min and ss:isWounded() then t2:append(ss) end
			end
			if t2:isEmpty() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local t = room:askForPlayerChosen(player, t2, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), t:objectName())
			local rec = sgs.RecoverStruct()
			rec.who = player
			room:recover(t, rec, true)
		end
		return false
	end
}


--[[
	技能名：血色
	相关武将：？？？
	技能描述：锁定技，当你使用红色【杀】时，你摸1张牌，此【杀】不可被【闪】响应。
	引用：ss_xuese
]]--
ss_xuese = sgs.CreateTriggerSkill{
	name = "ss_xuese",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)	
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() and use.card:isRed() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1, self:objectName())
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
	end
}


--[[
	技能名：神剑
	相关武将：？？？
	技能描述：锁定技，你的攻击范围+1，使用【杀】的目标上限数+2。
	引用：ss_shenjian
]]--
ss_shenjian = sgs.CreateTriggerSkill{
	name = "ss_shenjian",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end
}


--[[
	技能名：吞噬
	相关武将：？？？
	技能描述：锁定技，非死士角色死亡时，其他死士角色摸两张牌，你摸3张牌。
	引用：ss_tunshi
]]--
ss_tunshi = sgs.CreateTriggerSkill{
	name = "ss_tunshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Deathed},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		local death = data:toDeath()
		local vic = death.who
		if not isSishi(vic) then
			room:sendCompulsoryTriggerLog(s, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(s, self:objectName())
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(s)) do
				if isSishi(pe) then targets:append(pe) end
			end
			if not targets:isEmpty() then
				for _, t in sgs.qlist(targets) do
					room:doAnimate(1, s:objectName(), t:objectName())
				end
				for _, t in sgs.qlist(targets) do
					t:drawCards(2, self:objectName())
				end
			end
			s:drawCards(3, self:objectName())
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：雷牢
	相关武将：？？？
	技能描述：锁定技，准备阶段，你对一名体力值最大（或之一）的非死士角色造成1点雷电伤害。
	引用：ss_leilao
]]--
ss_leilao = sgs.CreateTriggerSkill{
	name = "ss_leilao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSishi(pe) then targets:append(pe) end
			end
			if targets:isEmpty() then return false end
			local t2 = sgs.SPlayerList()
			local _max = -100
			for _, ss in sgs.qlist(targets) do
				_max = math.max(_max, ss:getHp())
			end
			for _, ss in sgs.qlist(targets) do
				if ss:getHp() >= _max then t2:append(ss) end
			end
			if t2:isEmpty() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local t = room:askForPlayerChosen(player, t2, self:objectName())
			room:doAnimate(1, player:objectName(), t:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), player, t, 1, sgs.DamageStruct_Thunder))
		end
		return false
	end
}


local skills2 = sgs.SkillList()
if not sgs.Sanguosha:getSkill("ss_yunchui") then skills2:append(ss_yunchui) end
if not sgs.Sanguosha:getSkill("ss_fengyang") then skills2:append(ss_fengyang) end
if not sgs.Sanguosha:getSkill("ss_ranhun") then skills2:append(ss_ranhun) end
if not sgs.Sanguosha:getSkill("ss_xuanbing") then skills2:append(ss_xuanbing) end
if not sgs.Sanguosha:getSkill("ss_dizai") then skills2:append(ss_dizai) end
if not sgs.Sanguosha:getSkill("ss_yingzhan") then skills2:append(ss_yingzhan) end
if not sgs.Sanguosha:getSkill("ss_lingxu") then skills2:append(ss_lingxu) end
if not sgs.Sanguosha:getSkill("ss_xuese") then skills2:append(ss_xuese) end
if not sgs.Sanguosha:getSkill("ss_shenjian") then skills2:append(ss_shenjian) end
if not sgs.Sanguosha:getSkill("ss_tunshi") then skills2:append(ss_tunshi) end
if not sgs.Sanguosha:getSkill("ss_leilao") then skills2:append(ss_leilao) end
sgs.Sanguosha:addSkills(skills2)


sgs.LoadTranslationTable{
	["ss_yunchui"] = "云垂",
	[":ss_yunchui"] = "锁定技，当非死士角色使用【杀】时，所有非死士角色依次弃置一张牌。",
	["ss_fengyang"] = "风杨",
	[":ss_fengyang"] = "锁定技，当死士角色成为锦囊牌的目标后，其摸一张牌。",
	["ss_ranhun"] = "燃魂",
	[":ss_ranhun"] = "锁定技，回合结束阶段，你与所有非死士角色失去1点体力。",
	["ss_xuanbing"] = "玄冰",
	[":ss_xuanbing"] = "锁定技，准备阶段，你须令一名非死士角色弃置两张牌。",
	["ss_dizai"] = "地载",
	[":ss_dizai"] = "锁定技，死士角色的回合结束阶段，其摸两张牌。",
	["ss_yingzhan"] = "应战",
	[":ss_yingzhan"] = "锁定技，当死士角色成为【杀】的目标后，所有死士角色各摸一张牌。",
	["ss_lingxu"] = "灵虚",
	[":ss_lingxu"] = "锁定技，回合结束阶段，你令体力值最少（或之一）的一名死士角色回复1点体力。",
	["ss_xuese"] = "血色",
	[":ss_xuese"] = "锁定技，当你使用红色【杀】时，你摸1张牌，此【杀】不可被【闪】响应。",
	["ss_shenjian"] = "神剑",
	[":ss_shenjian"] = "锁定技，你的攻击范围+1，使用【杀】的目标上限数+2。",
	["ss_tunshi"] = "吞噬",
	[":ss_tunshi"] = "锁定技，非死士角色死亡时，其他死士角色摸两张牌，你摸3张牌。",
	["ss_leilao"] = "雷牢",
	[":ss_leilao"] = "锁定技，准备阶段，你对一名体力值最大（或之一）的非死士角色造成1点雷电伤害。",
	
}


--神嬴政
shenyingzheng = sgs.General(extension, "shenyingzheng", "sy_god", 3)


function throwNRamdomCardsFromPile(to, n, pile)
    local room = to:getRoom()
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
	if pile:length() >= n then
	    for i = 1, n do
		    local k = pile:at(math.random(1,pile:length())-1)
		    local c = sgs.Sanguosha:getCard(k)
			dummy:addSubcard(c)
			pile:removeOne(k)
		end
		room:throwCard(dummy, to)
	end
	dummy:deleteLater()
end


--[[
	技能名：皇威
	相关武将：神嬴政
	技能描述：准备阶段，若你没有“皇”，你可将一名其他角色区域内的一张牌置于你的武将牌上，称为“皇”。当你有“皇”时，你的摸牌阶段摸牌数和手牌上限+1。
	引用：ms_huangwei, ms_huangweimax
]]--
ms_huangwei = sgs.CreateTriggerSkill{
	name = "ms_huangwei",
	events = {sgs.EventPhaseStart, sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if not player:getPile("Emp"):isEmpty() then return false end
				local targets = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
					if not pe:isNude() then targets:append(pe) end
				end
				if targets:isEmpty() then return false end
				local t = room:askForPlayerChosen(player, targets, self:objectName(), "@huangwei-target", true, true)
				if t then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, t, "he", self:objectName())
					player:addToPile("Emp", id, true)
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if not player:getPile("Emp"):isEmpty() then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				draw.num = draw.num + 1
				data:setValue(draw)
			end
		end
	end
}

ms_huangweimax = sgs.CreateMaxCardsSkill{
    name = "#ms_huangweimax",
	extra_func = function(self, target)
	    if target:hasSkill("ms_huangwei") and (not target:getPile("Emp"):isEmpty()) then
		    return 1
		else
		    return 0
		end
	end
}


shenyingzheng:addSkill(ms_huangwei)
shenyingzheng:addSkill(ms_huangweimax)
extension:insertRelatedSkills("ms_huangwei", "#ms_huangweimax")


--[[
	技能名：杀威
	相关武将：神嬴政
	技能描述：你的回合外，当你成为其他角色使用的与“皇”颜色相同的杀、顺手牵羊、过河拆桥、火攻的目标时，你可对使用者造成1点伤害并令其弃置1张手牌（若无手牌则改为2
	点火焰伤害）。
	引用：ms_shawei, ms_shaweislash
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function isShaweiPattern(card)
	if card:isKindOf("Slash") then return true end
	if card:isKindOf("Snatch") then return true end
	if card:isKindOf("Dismantlement") then return true end
	if card:isKindOf("FireAttack") then return true end
	return false
end

ms_shawei = sgs.CreateTriggerSkill{
	name = "ms_shawei",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		if player:getPile("Emp"):isEmpty() then return false end
		local id = player:getPile("Emp"):first()
		local acard = sgs.Sanguosha:getCard(id)
		if use.from and use.from:objectName() ~= player:objectName() and use.card and isShaweiPattern(use.card) and acard:sameColorWith(use.card) and use.to:contains(player) then
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			if not use.from:isKongcheng() then
				room:damage(sgs.DamageStruct(self:objectName(), player, use.from))
				room:askForDiscard(use.from, self:objectName(), 1, 1, false, false)
			else
				room:damage(sgs.DamageStruct(self:objectName(), player, use.from, 2, sgs.DamageStruct_Fire))
			end
			room:addPlayerMark(player, "shawei_triggered")
		end
	end
}


shenyingzheng:addSkill(ms_shawei)


--[[
	技能名：仙术
	相关武将：神嬴政
	技能描述：锁定技，当你发动X-1次【杀威】时（X为场上存活角色数），你将“皇”置入弃牌堆，然后摸两张牌并回复1点体力。
	引用：ms_xianshu
]]--
function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

ms_xianshu = sgs.CreateTriggerSkill{
	name = "ms_xianshu",
	events = {sgs.MarkChanged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local mark = data:toMark()
		if mark.name == "shawei_triggered" then
			if player:getMark("shawei_triggered") >= room:getAlivePlayers():length() - 1 and (not player:getPile("Emp"):isEmpty()) then
				room:setPlayerMark(player, "shawei_triggered", 0)
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local to_throw = sgs.IntList()
				to_throw:append(player:getPile("Emp"):first())
				if not to_throw:isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
					dummy:addSubcards(getCardList(to_throw))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), "")
					room:throwCard(dummy, reason, nil)
					dummy:deleteLater()
				end
				player:drawCards(2)
				local rec = sgs.RecoverStruct()
				rec.who = player
				room:recover(player, rec, true)
			end
		end
	end
}


shenyingzheng:addSkill(ms_xianshu)


sgs.LoadTranslationTable{
	["shenyingzheng"] = "神嬴政",
	["#shenyingzheng"] = "始皇帝",
	["~shenyingzheng"] = "不可能！朕可是……永恒不灭的皇帝！朕——",
	["ms_huangwei"] = "皇威",
	["Emp"] = "皇",
	["@huangwei-target"] = "你可以将一名其他角色区域内的一张牌作为“皇”置于你的武将牌上",
	[":ms_huangwei"] = "准备阶段，若你没有“皇”，你可将一名其他角色区域内的一张牌置于你的武将牌上，称为“皇”。当你有“皇”时，你的摸牌阶段摸牌数和手牌上限+1。",
	["$ms_huangwei1"] = "朕为万世不变之皇帝！",
	["$ms_huangwei2"] = "快把你们的斗气献给朕吧！",
	["ms_shawei"] = "杀威",
	[":ms_shawei"] = "你的回合外，当你成为其他角色使用的与“皇”颜色相同的杀、顺手牵羊、过河拆桥、火攻的目标时，你可对使用者造成1点伤害并令其弃置1张手牌（若无手"..
	"牌则改为2点火焰伤害）。",
	["$ms_shawei1"] = "贱民们，统统给朕跪下！",
	["$ms_shawei2"] = "哈哈哈哈！就是这股力量！",
	["ms_xianshu"] = "仙术",
	[":ms_xianshu"] = "<font color=\"blue\"><b>锁定技，</b></font>当你发动X-1次【杀威】时（X为场上存活角色数），你将“皇”置入弃牌堆，然后摸两张牌并回复1点体力。",
	["$ms_xianshu"] = "呵哈哈哈哈……那么，来吧！",
	["designer:shenyingzheng"] = "司马子元",
	["cv:shenyingzheng"] = "小山力也",
	["illustrator:shenyingzheng"] = "TECMO KOEI",
}


--神司马师
shensimashi = sgs.General(extension, "shensimashi", "sy_god", 4)


--[[
	技能名：晋书
	相关武将：神司马师
	技能描述：锁定技，任一角色回合结束阶段，你重置武将牌并将手牌数补充至4张。你的准备阶段，你从牌堆或弃牌堆中随机获得一张你缺少的花色的牌。
	引用：ms_jinshu
]]--
function can_reset(player)
	if not player:faceUp() then return true end
	if player:isChained() then return true end
	return false
end

function resetPlayer(player)
	local room = player:getRoom()
	if not player:faceUp() then player:turnOver() end
	if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
end
ms_jinshu = sgs.CreateTriggerSkill{
	name = "ms_jinshu",
	frequency = sgs.Skill_Compulsory,
	priority = -2,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Finish then
			local _p = s:getHandcardNum() < 4 or can_reset(s)
			if _p then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:notifySkillInvoked(s, self:objectName())
				if can_reset(s) then resetPlayer(s) end
				if s:getHandcardNum() < 4 then s:drawCards(4 - s:getHandcardNum(), self:objectName()) end
			end
		end
		if player:getPhase() == sgs.Player_Start and player:objectName() == s:objectName() then
			local ids = sgs.IntList()
			local suits = {"spade", "heart", "club", "diamond"}
			if not s:isKongcheng() then
				for _, c in sgs.qlist(s:getHandcards()) do
					if table.contains(suits, c:getSuitString()) then table.removeOne(suits, c:getSuitString()) end
				end
			end
			if #suits > 0 then
				if not room:getDrawPile():isEmpty() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local c = sgs.Sanguosha:getCard(id)
						if table.contains(suits, c:getSuitString()) then ids:append(id) end
					end
				end
				if not room:getDiscardPile():isEmpty() then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local c = sgs.Sanguosha:getCard(id)
						if table.contains(suits, c:getSuitString()) then ids:append(id) end
					end
				end
			end
			ids = sgs.QList2Table(ids)
			if #ids > 0 then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:notifySkillInvoked(s, self:objectName())
				local move = sgs.CardsMoveStruct()
				local j = ids[math.random(1, #ids)]
				move.card_ids:append(j)
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				dummy:addSubcard(j)
				room:obtainCard(player, dummy)
				dummy:deleteLater()
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


shensimashi:addSkill(ms_jinshu)


--[[
	技能名：鬼谋
	相关武将：神司马师
	技能描述：限定技，出牌阶段，你可以弃置任意数量不同花色的牌各一张，然后根据所弃置牌的花色获得对应技能：黑桃-忍忌，红桃-博略，梅花-完杀，方片-嗜杀。
	引用：ms_guimou
]]--
ms_guimouCard = sgs.CreateSkillCard{
	name = "ms_guimou",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("shensimashi", self:objectName())
		source:loseMark("@guimou")
		local skills = {}
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getSuit() == sgs.Card_Spade then
			    if (not source:hasSkill("sy_renji")) then table.insert(skills, "sy_renji") end
			elseif c:getSuit() == sgs.Card_Heart then
			    if not source:hasSkill("sy_bolue") then table.insert(skills, "sy_bolue") end
			elseif c:getSuit() == sgs.Card_Club then
			    if not source:hasSkill("wansha") then table.insert(skills, "wansha") end
			elseif c:getSuit() == sgs.Card_Diamond then
			    if not source:hasSkill("sy_shisha") then table.insert(skills, "sy_shisha") end
			end
		end
		if #skills > 0 then
			room:handleAcquireDetachSkills(source, table.concat(skills, "|"))
			if #skills >= 1 then room:loseMaxHp(source) end
			if #skills >= 2 then room:loseHp(source, 1, true, source, "ms_guimou") end
			if #skills >= 3 then source:throwJudgeArea() end
		end
	end
}

ms_guimouViewAsSkill = sgs.CreateViewAsSkill{
	name = "ms_guimou",
	n = 4,
	view_filter = function(self, selected, to_select)
		if #selected >= 4 then return false end
		for _,card in ipairs(selected) do
			if card:getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local ttCard = ms_guimouCard:clone()
		for _,card in ipairs(cards) do
			ttCard:addSubcard(card)
		end
		return ttCard
	end,
	enabled_at_play=function(self, player)
		return player:getMark("@guimou") >= 1
	end
}

ms_guimou = sgs.CreateTriggerSkill{
	name = "ms_guimou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@guimou",
	events = {},
	view_as_skill = ms_guimouViewAsSkill,
	on_trigger = function()
	end
}


shensimashi:addSkill(ms_guimou)
shensimashi:addRelateSkill("sy_renji")
shensimashi:addRelateSkill("sy_bolue")
shensimashi:addRelateSkill("wansha")
shensimashi:addRelateSkill("sy_shisha")


sgs.LoadTranslationTable{
	["shensimashi"] = "神司马师",
	["#shensimashi"] = "睿略创基",
	["~shensimashi"] = "天命……并不在我身上吗……",
	["ms_jinshu"] = "晋书",
	[":ms_jinshu"] = "锁定技，任一角色回合结束阶段，你重置武将牌并将手牌数补充至4张。你的准备阶段，你从牌堆或弃牌堆中随机获得一张你缺少的花色的牌。",
	["$ms_jinshu1"] = "真是愚蠢。",
	["$ms_jinshu2"] = "只是个凡愚而已吗？",
	["$ms_jinshu3"] = "从曹爽一党灭亡之始，我就知道会有这么一天。",
	["ms_guimou"] = "鬼谋",
	["$ms_guimou1"] = "放弃吧，你以为我有闲心跟贼人浪费时间？",
	["$ms_guimou2"] = "专横？原来如此，在你们眼中便是如此。",
	[":ms_guimou"] = "限定技，出牌阶段，你可以弃置任意数量不同花色的牌各一张，然后根据所弃置牌的花色获得对应技能：黑桃-忍忌，红桃-博略，梅花-完杀，方块-嗜杀。"..
	"你以此法获得的技能数不小于：2-减1点体力上限；3-失去1点体力；4-废除判定区。",
	["designer:shensimashi"] = "司马子元",
	["cv:shensimashi"] = "置鲇龙太郎",
	["illustrator:shensimashi"] = "蒼樹(ID=15489617)",
}


--(神)初音未来
ms_god_miku = sgs.General(extension, "ms_god_miku", "sy_god", 3, false)


--[[
	技能名：祈愿
	相关武将：(神)初音未来
	技能描述：锁定技，回合开始前，你重置你的武将牌并摸X张牌（X在你受伤时为2，否则为1），然后失去该技能。
	引用：ms_qiyuan
]]--
ms_qiyuan = sgs.CreateTriggerSkill{
	name = "ms_qiyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data, room)
		room:sendCompulsoryTriggerLog(player, self:objectName())
		if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
		if not player:faceUp() then player:turnOver() end
		local X = 1
		if player:isWounded() then X = 2 end
		player:drawCards(X)
		room:detachSkillFromPlayer(player, self:objectName())
	end
}


--[[
	技能名：乐动
	相关武将：(神)初音未来
	技能描述：准备阶段，你可以将手牌数补至体力上限。若你的判定区里有【乐不思蜀】，你弃置之。此阶段结束后，你失去该技能。
	引用：ms_yuedong
]]--
ms_yuedong = sgs.CreateTriggerSkill{
	name = "ms_yuedong",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local can_invoke = player:getHandcardNum() < player:getMaxHp() or player:containsTrick("Indulgence")
				if can_invoke and player:askForSkillInvoke(self:objectName(), data) then
					if player:getHandcardNum() < player:getMaxHp() then
						local dif = player:getMaxHp() - player:getHandcardNum()
						player:drawCards(dif)
					end
					if player:containsTrick("indulgence") then
						for _, card in sgs.qlist(player:getJudgingArea()) do
							if card:isKindOf("Indulgence") then
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), "")
								room:throwCard(card, reason, nil)
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Start then room:detachSkillFromPlayer(player, self:objectName()) end
		end
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("ms_qiyuan") then skills:append(ms_qiyuan) end
if not sgs.Sanguosha:getSkill("ms_yuedong") then skills:append(ms_yuedong) end
sgs.Sanguosha:addSkills(skills)


--[[
	技能名：永恒
	相关武将：(神)初音未来
	技能描述：出牌阶段限一次，你可以令一名角色进行判定，该角色根据判定结果执行：
	黑桃-从牌堆中随机获得一张与之不同类的牌。
	红桃-摸1张牌并回复1点体力。
	梅花-下个回合摸牌阶段摸牌数+2。
	方块-随机获得【祈愿】或【乐动】中的一个技能。
	引用：ms_yongheng
]]--
ms_yonghengCard = sgs.CreateSkillCard{
	name = "ms_yonghengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		end
		return false
	end,
	feasible = function(self, targets)
	    return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local judge = sgs.JudgeStruct()
		judge.reason = "ms_yongheng"
		judge.who = target
		judge.play_animation = false
		judge.pattern = "."
		room:judge(judge)
		local suit = judge.card:getSuit()
		local msg = sgs.LogMessage()
		msg.from = target
		if suit == sgs.Card_Spade then
			msg.type = "#yongheng_spade"
			msg.card_str = judge.card:toString()
			room:sendLog(msg)
			local pattern = ""
			if judge.card:isKindOf("BasicCard") then
				pattern = "BasicCard"
			elseif judge.card:isKindOf("TrickCard") then
				pattern = "TrickCard"
			elseif judge.card:isKindOf("EquipCard") then
				pattern = "EquipCard"
			end
			local ids = getExceptionDrawpileIds(pattern)
			if not ids:isEmpty() then
				local k = math.random(0, ids:length()-1)
				local r_id = ids:at(k)
				local acard = sgs.Sanguosha:getCard(r_id)
				target:obtainCard(acard)
			end
			
		elseif suit == sgs.Card_Heart then
			msg.type = "#yongheng_heart"
			msg.arg = tostring(1)
			room:sendLog(msg)
			target:drawCards(1)
			if target:isWounded() then
				local rec = sgs.RecoverStruct()
				rec.who = source
				room:recover(target, rec, true)
			end
		elseif suit == sgs.Card_Club then
			msg.type = "#yongheng_club"
			room:sendLog(msg)
			target:setTag("yongheng_draw", sgs.QVariant(true))
		elseif suit == sgs.Card_Diamond then
			local sks = {"ms_qiyuan", "ms_yuedong"}
			for _, name in ipairs(sks) do
				if target:hasSkill(name) then table.removeOne(sks, name) end
			end
			if #sks <= 0 then return false end
			local iskill = sks[math.random(1, #sks)]
			msg.type = "#yongheng_diamond"
			msg.arg = iskill
			room:sendLog(msg)
			room:acquireSkill(target, iskill)
		end
	end
}

ms_yonghengVS = sgs.CreateZeroCardViewAsSkill{
	name = "ms_yongheng",
	view_as = function()
		return ms_yonghengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ms_yonghengCard")
	end
}


ms_yongheng = sgs.CreateTriggerSkill{
	name = "ms_yongheng",
	view_as_skill = ms_yonghengVS,
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Draw and player:isSkipped(change.to) then
				player:removeTag("yongheng_draw")
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			player:removeTag("yongheng_draw")
			draw.num = draw.num + 2
			data:setValue(draw)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getTag("yongheng_draw"):toBool() == true
	end
}


ms_god_miku:addSkill(ms_yongheng)


--[[
	技能名：梦幻
	相关武将：(神)初音未来
	技能描述：锁定技，你不能成为顺手牵羊、过河拆桥和延时类锦囊的目标。当你即将扣减体力时，你有39%的概率防止此次体力扣减。
	引用：ms_menghuan
]]--
ms_menghuan = sgs.CreateTriggerSkill{
	name = "ms_menghuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.PreHpLost},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill(self:objectName()) then
			if math.random(1, 100) <= 39 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
	end,
	priority = 10
}

ms_menghuanNo = sgs.CreateProhibitSkill{
	name = "#ms_menghuan",
	is_prohibited = function(self, from, to, card)
		return to and to:hasSkill("ms_menghuan") and (card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or card:isKindOf("DelayedTrick"))
	end
}


extension:insertRelatedSkills("ms_menghuan", "#ms_menghuan")
ms_god_miku:addSkill(ms_menghuan)
ms_god_miku:addSkill(ms_menghuanNo)
ms_god_miku:addRelateSkill("ms_qiyuan")
ms_god_miku:addRelateSkill("ms_yuedong")


sgs.LoadTranslationTable{
	["ms_god_miku"] = "初音未来",
	["#ms_god_miku"] = "永恒之歌",
	["~ms_god_miku"] = "~",
	["ms_yongheng"] = "永恒",
	["#yongheng_spade"] = "%from 将执行“<font color=\"yellow\"><b>永恒</b></font>”的技能效果：从牌堆中随机获得一张与 %card 不同类别的牌",
	["#yongheng_heart"] = "%from 将执行“<font color=\"yellow\"><b>永恒</b></font>”的技能效果：摸 %arg 张牌并回复 %arg 点体力",
	["#yongheng_club"] = "%from 将执行“<font color=\"yellow\"><b>永恒</b></font>”的技能效果：下个回合摸牌阶段摸牌时，摸牌数<font color=\"yellow\"><b>+2</b></fo"..
	"nt>",
	["#yongheng_diamond"] = "%from 将执行“<font color=\"yellow\"><b>永恒</b></font>”的技能效果：获得技能“%arg”",
	[":ms_yongheng"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名角色进行判定，该角色根据判定结果执行："..
	"\n黑桃-从牌堆中随机获得一张与之不同类的牌。"..
	"\n红桃-摸1张牌并回复1点体力。"..
	"\n梅花-下个回合摸牌阶段摸牌数+2。"..
	"\n方块-随机获得【祈愿】或【乐动】中的一个技能。",
	["$ms_yongheng1"] = "你的眼中所映照出的那个世界……",
	["$ms_yongheng2"] = "我也想跟你一起去看见",
	["$ms_yongheng3"] = "从0诞生 直至∞(永恒)",
	["$ms_yongheng4"] = "给予了我回答的人 是你",
	["ms_qiyuan"] = "祈愿",
	[":ms_qiyuan"] = "<font color=\"blue\"><b>锁定技，</b></font>回合开始前，你重置你的武将牌并摸X张牌（X在你受伤时为2，否则为1），然后失去该技能。",
	["ms_yuedong"] = "乐动",
	[":ms_yuedong"] = "准备阶段，你可以将手牌数补至体力上限。若你的判定区里有【乐不思蜀】，你弃置之。此阶段结束后，你失去该技能。",
	["ms_menghuan"] = "梦幻",
	[":ms_menghuan"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能成为顺手牵羊、过河拆桥和延时类锦囊的目标。当你即将扣减体力时，你有39%的概率防止此次体"..
	"力扣减。",
	["$ms_menghuan1"] = "扭曲了的梦的形态→「能被看见就是幸福」",
	["$ms_menghuan2"] = "回过神来的时候，我的身旁充满了伪物。",
	["designer:ms_god_miku"] = "司马子元",
	["cv:ms_god_miku"] = "藤田咲",
	["illustrator:ms_god_miku"] = "1055(ID=56953207)",
}


--神司马昭
shensimazhao = sgs.General(extension, "shensimazhao", "sy_god", 3, true)


--[[
	技能名：远途
	相关武将：神司马昭
	技能描述：锁定技，当其他角色从你处获得牌时，你摸1张牌。不在你攻击范围内的角色对你使用的【杀】无效。
	引用：ms_yuantu
]]--
ms_yuantu = sgs.CreateTriggerSkill{
	name = "ms_yuantu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.TargetConfirming},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName()) and 
			(move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				if move.to and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
					local _to
					for _, _player in sgs.qlist(room:getAlivePlayers()) do
						if move.to:objectName() == _player:objectName() then
							_to = _player
							break
						end
					end
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:drawCards(1, self:objectName())
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if not use.from then return false end
			if use.from:objectName() == player:objectName() then return false end
			if use.card:isKindOf("Slash") and use.to:contains(player) and (not player:inMyAttackRange(use.from)) then
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
			end
		end
		return false
	end
}


shensimazhao:addSkill(ms_yuantu)


--[[
	技能名：縻谋
	相关武将：神司马昭
	技能描述：出牌阶段限一次，你可将一张手牌交给一名其他角色，令其选择一项：1. 交给你两张手牌，然后摸1张牌；2. 你摸3张牌，且若你没有“残掠”，你获得之，并修改此技能。
	引用：ms_muyin, ms_muyindeath
]]--
ms_mimouCard = sgs.CreateSkillCard{
	name = "ms_mimou",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
        if #targets == 0 then
		    return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), "ms_mimou", "")
		room:obtainCard(target, self, reason, true)
		local _data = sgs.QVariant()
		_data:setValue(source)
		if not source:hasSkill("sy_canlue") then
			local choices = {"selfdraw3"}
			if target:getHandcardNum() >= 2 then table.insert(choices, "giveself2") end
			local choice = room:askForChoice(target, "ms_mimou", table.concat(choices, "+"), _data)
			if choice == "giveself2" then
				local prom = string.format("@mimou_to:%s", source:objectName())
				local cards = room:askForExchange(target, "ms_mimou", 2, 2, false, prom)
				room:obtainCard(source, cards, false)
				target:drawCards(1)
			else
				source:drawCards(3)
				if not source:hasSkill("sy_canlue") then
					room:handleAcquireDetachSkills(source, "sy_canlue")
					sgs.Sanguosha:addTranslationEntry(":ms_mimou", "" .. string.gsub(sgs.Sanguosha:translate(":ms_mimou"), sgs.Sanguosha:translate(":ms_mimou"), sgs.Sanguosha:translate(":ms_mimouEX")))
				end
			end
		else
			local choices = {"selfdraw2"}
			if target:getCards("he"):length() >= 2 then table.insert(choices, "throw2cards") end
			local choice = room:askForChoice(target, "ms_mimou", table.concat(choices, "+"), _data)
			if choice == "throw2cards" then
				room:askForDiscard(target, self:objectName(), 2, 2, false, true)
			else
				source:drawCards(2, self:objectName())
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				slash:deleteLater()
				local to = sgs.SPlayerList()
				to:append(target)
				local use = sgs.CardUseStruct()
				use.from = source
				use.to = to
				use.card = slash
				room:useCard(use, false)
			end
		end
	end
}

ms_mimou = sgs.CreateViewAsSkill{
	name = "ms_mimou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = ms_mimouCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#ms_mimou"))
	end
}
shensimazhao:addSkill(ms_mimou)


sgs.LoadTranslationTable{
	["shensimazhao"] = "神司马昭",
	["#shensimazhao"] = "雄才成务",
	["~shensimazhao"] = "我的器量，果然就只有这样而已……抱歉了，各位……",
	["ms_yuantu"] = "远途",
	[":ms_yuantu"] = "锁定技，当其他角色从你处获得牌时，你摸1张牌。不在你攻击范围内的角色对你使用的【杀】无效。",
	["ms_mimou"] = "縻谋",
	[":ms_mimou"] = "出牌阶段限一次，你可将一张手牌交给一名其他角色，令其选择一项：1. 交给你两张手牌，然后摸1张牌；2. 你摸3张牌，且若你没有“残掠”，你获得之。"..
	"若你有技能“残掠”，你将第一项改为令其弃置两张牌，第二项改为摸两张牌并视为对其使用一张【杀】（不计入每回合使用次数限制）。",
	["$ms_mimou1"] = "你想逃也逃不掉了。",
	["$ms_mimou2"] = "带走，带回到许昌处决。",
	["$ms_mimou3"] = "我有想要的东西，所以……觉悟吧。",
	["selfdraw3"] = "令发起者摸3张牌",
	["selfdraw2"] = "发起者摸两张牌，并视为发起者对你使用一张【杀】",
	["giveself2"] = "将两张手牌交给发起者，然后摸1张牌",
	["throw2cards"] = "弃置两张牌",
	["@mimou_to"] = "【縻谋】技能效果，请将两张手牌交给%src，然后摸1张牌",
	[":ms_mimouEX"] = "出牌阶段限一次，你可将一张手牌交给一名其他角色，令其选择一项：1. 弃置两张牌；2. 你摸两张牌并视为对其使用一张【杀】（不计入每回合使用次"..
	"数限制）。",
	--[[
	["$ms_jinwang1"] = "这是个英明的决断。",
	["$ms_jinwang2"] = "我接受你的降伏。",
	["$ms_jinwang6"] = "（文钦）终于受不了对司马昭摇尾巴的日子了吗？",
	["$ms_suni3"] = "我只再问最后一次。",
	]]--
	["designer:shensimazhao"] = "司马子元",
	["cv:shensimazhao"] = "岸尾大辅",
	["illustrator:shensimazhao"] = "蒼樹(ID=15489617)",
}
---
return {extension}