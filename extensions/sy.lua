extension = sgs.Package("sy", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
	["sy"] = "三英",
}


-- function freezePlayer(who)  --冰冻
-- 	local room = who:getRoom()
-- 	room:setPlayerCardLimitation(who, "use,response", ".", false)
-- 	room:setPlayerMark(who, "@cold_snow", 0)
-- 	room:setPlayerMark(who, "@icebrick", 1)
-- 	for _, sk in sgs.qlist(who:getVisibleSkillList()) do  --为了确保“冰冻”能让目标翻面，先封锁所有技能，然后再翻面。
-- 		room:addPlayerMark(who, "skill_frozen_"..sk:objectName())
-- 		room:addPlayerMark(who, "Qingcheng"..sk:objectName())
-- 	end
-- 	if who:faceUp() then who:turnOver() end
-- 	room:broadcastSkillInvoke("frozen_effect")
-- 	local fre = sgs.LogMessage()
-- 	fre.from = who
-- 	fre.type = "#PlayerFrozen"
-- 	room:sendLog(fre)
-- end
	
-- function meltPlayer(who)  --解冻
-- 	local room = who:getRoom()
-- 	room:removePlayerCardLimitation(who, "use,response", "." .. "$0")
-- 	room:setPlayerMark(who, "@icebrick", 0)
-- 	if not who:faceUp() then who:turnOver() end  --与“冰冻”的结算相反，解冻后先翻面，然后恢复技能。
-- 	for _, sk in sgs.qlist(who:getVisibleSkillList()) do
-- 		room:setPlayerMark(who, "skill_frozen_"..sk:objectName(), 0)
-- 		room:setPlayerMark(who, "Qingcheng"..sk:objectName(), 0)
-- 	end
-- 	local mlt = sgs.LogMessage()
-- 	mlt.from = who
-- 	mlt.type = "#PlayerMelt"
-- 	room:sendLog(mlt)
-- end

-- function isFrozen(yeti)  --判断一名角色是否处于“冰冻”状态
-- 	if yeti:faceUp() then return false end
-- 	if yeti:getMark("@icebrick") == 0 then return false end
-- 	local flag = false
-- 	for _, mark in sgs.list(yeti:getMarkNames()) do
-- 		if string.find(mark, "skill_frozen_") and yeti:getMark(mark) > 0 then
-- 			flag = true
-- 			break
-- 		end
-- 	end
-- 	return flag
-- end

-- function isInitiallyFrozen(yeti)  --判断一名角色在自然翻面解除之前是否处于“冰冻”状态
-- 	if yeti:getMark("@icebrick") == 0 then return false end
-- 	local flag = false
-- 	for _, mark in sgs.list(yeti:getMarkNames()) do
-- 		if string.find(mark, "skill_frozen_") and yeti:getMark(mark) > 0 then
-- 			flag = true
-- 			break
-- 		end
-- 	end
-- 	return flag
-- end

function is2ndBossMode(who)
    if who:getGeneralName() == "sy_lvbu2" then return true end
    if who:getGeneralName() == "sy_dongzhuo2" then return true end
    if who:getGeneralName() == "sy_zhangjiao2" then return true end
    if who:getGeneralName() == "sy_zhangrang2" then return true end
    if who:getGeneralName() == "sy_weiyan2" then return true end
    if who:getGeneralName() == "sy_sunhao2" then return true end
    if who:getGeneralName() == "sy_sunhao3" then return true end
    if who:getGeneralName() == "sy_caifuren2" then return true end
    if who:getGeneralName() == "sy_simayi2" then return true end
    if who:getGeneralName() == "sy_miku2" then return true end
    if who:getGeneralName() == "sy_simashi2" then return true end
    if who:getGeneralName() == "sy_zhaoyun2" then return true end
    if who:getGeneralName() == "sy_zhangfei2" then return true end
    if who:getGeneralName() == "sy_sakura2" then return true end
	if who:getGeneralName() == "sy_xusheng2" then return true end
	if who:getGeneralName() == "sy_yuanshao2" then return true end
	if who:getGeneralName() == "berserk_miku2" then return true end
	return false
end


function isSanyingBoss(who)
    if who:getGeneral() and (string.find(who:getGeneralName(), "sy_") or string.find(who:getGeneralName(), "berserk_")) then return true end
	return false
end


function canSanyingBianshen(who)
    if who:getGeneral() and (string.find(who:getGeneralName(), "sy_") or string.find(who:getGeneralName(), "berserk_")) and string.find(who:getGeneralName(), "1") then return true end
	return false
end


function isEntireSanyingBoss(who)
	if canSanyingBianshen(who) and who:getGeneral2() and (string.find(who:getGeneral2Name(), "sy_") or string.find(who:getGeneral2Name(), "berserk_")) and string.find(who:getGeneral2Name(), "1") then return true end
	return false
end


-- function countLackedEquips(player)
-- 	local n = 0
-- 	if player:getWeapon() == nil then n = n + 1 end
-- 	if player:getArmor() == nil then n = n + 1 end
-- 	if player:getOffensiveHorse() == nil then n = n + 1 end
-- 	if player:getDefensiveHorse() == nil then n = n + 1 end
-- 	if player:getTreasure() == nil then n = n + 1 end
-- 	return n
-- end

-- function lackedEquipAreaNum(target)
-- 	local n = 5
-- 	for i = 0, 4 do
-- 		if target:hasEquipArea(i) then n = n - 1 end
-- 	end
-- 	return n
-- end

-- function throwRandomEquip(target)
-- 	local area = {}
-- 	local room = sgs.Sanguosha:currentRoom()
-- 	for i = 0, 4 do
-- 		if target:hasEquipArea(i) then table.insert(area, "EquipItem_"..i) end
-- 	end
-- 	if target:hasEquipArea() then
-- 		local area_str = area[math.random(1, #area)]
-- 		local x = tonumber(string.sub(area_str, string.len(area_str), string.len(area_str)))
-- 		target:throwEquipArea(x)
-- 		local msg = sgs.LogMessage()
-- 		msg.to:append(target)
-- 		msg.type = "#AreaBroken"
-- 		msg.arg = area_str
-- 		room:sendLog(msg)
-- 	end
-- end


function hasSameNameSkill(player, name)
	local skill_table = {}
	for _, sk in sgs.qlist(player:getVisibleSkillList()) do
		table.insert(skill_table, sk:objectName())
	end
	local skill_str = table.concat(skill_table, "|")
	if string.find(skill_str, name) then
		return true
	else
		return false
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



--完全隐藏武将
sy_nobody = sgs.General(extension, "sy_nobody", "god", 100, true, true, true)


sy_hp = sgs.CreateTriggerSkill{
    name = "#sy_hp",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if (not isSanyingBoss(player)) or (not canSanyingBianshen(player)) then return false end
		if event == sgs.GameStart then
			local general1 = player:getGeneral()
			local x = general1:getMaxHp()
			local general2 = player:getGeneral2()
			if general2 and isEntireSanyingBoss(player) then
				local y = general2:getMaxHp()
				local n = math.floor((x+y)/2)
				room:setPlayerProperty(player, "hp", sgs.QVariant(n))
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(n))
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			draw.num = draw.num + 4
			data:setValue(draw)
	    end
	end
}


sy_bianshen = sgs.CreateTriggerSkill{
    name = "#sy_bianshen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageDone, sgs.HpChanged},
	on_trigger = function(self, event, player, data, room)
		if not canSanyingBianshen(player) then return false end
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Lightning") and not damage.transfer and player:getHp() - damage.damage <= 4 then
				room:throwCard(damage.card, player)
			end
		elseif event == sgs.HpChanged then
		    if player:getHp() > 4 then return false end
			local general1 = player:getGeneral()
		    local general2 = player:getGeneral2()
			if (not canSanyingBianshen(player)) or (not isSanyingBoss(player)) then
				return false
			else
			    room:addPlayerMark(player, "@sy_wake")
				player:loseAllMarks("@syfirstturn")
				room:setTag("sy2ndmode", sgs.QVariant(true))
				room:setPlayerMark(player, "sy_2nd_stagechange", 1)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		        dummy:addSubcards(player:getJudgingArea())
		        room:throwCard(dummy, player)
			    if not player:faceUp() then player:turnOver() end
		        if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
				local first = player:getGeneralName()
			    if first == "sy_lvbu1" then
			        room:broadcastSkillInvoke(self:objectName(), 1)
			    elseif first == "sy_dongzhuo1" then
			        room:broadcastSkillInvoke(self:objectName(), 2)
			    elseif first == "sy_zhangjiao1" then
		 	        room:broadcastSkillInvoke(self:objectName(), 3)
			    elseif first == "sy_zhangrang1" then
			        room:broadcastSkillInvoke(self:objectName(), 4)
			    elseif first == "sy_weiyan1" then
			        room:broadcastSkillInvoke(self:objectName(), 5)
			    elseif first == "sy_sunhao1" then
			        room:broadcastSkillInvoke(self:objectName(), 6)
			    elseif first == "sy_caifuren1" then
			        room:broadcastSkillInvoke(self:objectName(), 7)
			    elseif first == "sy_simayi1" then
			        room:broadcastSkillInvoke(self:objectName(), 8)
				elseif first == "sy_sakura1" then
				    room:broadcastSkillInvoke(self:objectName(), 21)
				elseif first == "sy_simashi1" then
				    room:broadcastSkillInvoke(self:objectName(), 10)
				elseif first == "sy_miku1" then
				    room:broadcastSkillInvoke(self:objectName(), 11)
				elseif first == "berserk_miku1" then
				    room:broadcastSkillInvoke(self:objectName(), 13)
				elseif first == "sy_yuanshao1" then
				    room:broadcastSkillInvoke(self:objectName(), 14)
				elseif first == "sy_yasuo1" then
				    room:broadcastSkillInvoke(self:objectName(), 20)
				elseif first == "sy_zhaoyun1" then
				    room:broadcastSkillInvoke(self:objectName(), 22)
				elseif first == "sy_zhangfei1" then
				    room:broadcastSkillInvoke(self:objectName(), 23)
			    end
			    local msg = sgs.LogMessage()
			    msg.from = player
			    msg.type = "#sy_second_stage"
			    room:sendLog(msg)
				local is_sanying_scene = room:getTag("sanyingmode"):toBool()
				if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
				if is_sanying_scene then
					local current = room:getCurrent()
					local n = room:getAlivePlayers():length() - 1
					if current:isLord() then
						local all_done = 0
						local all_nodone = 0
						for _, p in sgs.qlist(room:getOtherPlayers(current)) do
							if p:getMark("@sy_actioned") == 0 then
								all_done = all_done + 1
							elseif p:getMark("@sy_actioned") > 0 then
								all_nodone = all_nodone + 1
							end
						end
						if all_done == n then
							for _, t in sgs.qlist(room:getOtherPlayers(player)) do
								room:setPlayerMark(t, "@sy_actioned", 0)
							end
							room:setPlayerMark(current, "sy_second", 1)
						else
							local tg
							for i = 1, 999, 1 do
								if current:getNextAlive(i):getMark("@sy_actioned") == 0 then
									tg = current:getNextAlive(i)
									break
								end
							end
							room:setPlayerMark(tg, "2nd_stop", 1)
							for i = 1, 999, 1 do
								if tg:getNextAlive(i):isLord() then
									break
								else
									room:setPlayerMark(tg:getNextAlive(i), "2nd_stop", 1)
								end
							end
						end
					else
						for i = 1, 999, 1 do
							if current:getNextAlive(i):isLord() then
								break
							else
								room:setPlayerMark(current:getNextAlive(i), "2nd_stop", 1)
							end
						end
					end
					for _, t in sgs.qlist(room:getOtherPlayers(player)) do
						room:setPlayerMark(t, "@sy_actioned", 0)
					end
				else
					if room:getCurrent():getNextAlive():objectName() ~= player:objectName() then
						room:setPlayerMark(player, "sy_second", 1)
					end
				end
				local current = room:getCurrent()
				if current:objectName() ~= player:objectName() then
					room:addPlayerMark(current, "stop_currentAction")
					current:setAlive(false)
					room:broadcastProperty(current, "alive")
				end
				room:throwEvent(sgs.TurnBroken)
			end
		end
	end
}


sy_2ndturnstart = sgs.CreateTriggerSkill{
    name = "#sy_2ndturnstart",
	frequency = sgs.Skill_Compulsory,
	priority = 50,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		local change = data:toPhaseChange()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if s and change.from == sgs.Player_NotActive then
			if s:getMark("sy_2nd_stagechange") > 0 then
				room:setPlayerMark(s, "sy_2nd_stagechange", 0)
				local first = s:getGeneralName()
				local fn = string.sub(first, 1, string.len(first)-1)
				if first ~= "sy_sunhao1" then
					room:changeHero(s, fn.."2", true, true, false, false)
				elseif first == "berserk_miku1" then
					room:changeHero(s, "berserk_miku2", true, true, false, false)
				else
					if s:getMark("&sy_mingzheng") > 0 then 
						room:changeHero(s, "sy_sunhao3", true, true, false, false)
					else
						room:changeHero(s, "sy_sunhao2", true, true, false, false)
					end
				end
				if s:getGeneral2() then
					local second = s:getGeneral2Name()
					local sn = string.sub(second, 1, string.len(second)-1)
					if string.find(second, "sy_") then
						if second ~= "sy_sunhao1" then
							room:changeHero(s, sn.."2", true, true, true, false)
						elseif first == "berserk_miku1" then
							room:changeHero(s, "berserk_miku2", true, true, true, false)
						else
							if s:getMark("&sy_mingzheng") > 0 then 
								room:changeHero(s, "sy_sunhao3", true, true, true, false)
							else
								room:changeHero(s, "sy_sunhao2", true, true, true, false)
							end
						end
					end
				end
				room:setPlayerProperty(s, "hp", sgs.QVariant(4))
				room:setPlayerProperty(s, "maxhp", sgs.QVariant(4))
				if s:getMark("sy_second") > 0 then
					room:setPlayerMark(s, "sy_second", 0)
					s:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
	    return true
	end
}


--是否允许所有人都拥有重铸装备的资格
everyone_can_recast = true
--是否允许身份局重铸
role_can_recast = true
W_recast = sgs.CreateTriggerSkill{
    name = "#W_recast",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local sanyingmode = room:getTag("sanyingmode"):toBool()
		if not sanyingmode then
			if not role_can_recast then return false end
		end
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if (card:isKindOf("Weapon") or card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")) and use.to:at(0):objectName() == player:objectName() then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:setCardFlag(card, "sy_recasted")
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(card:getEffectiveId())
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), "", "")
					move.to_place = sgs.Player_DiscardPile
					room:moveCardsAtomic(move, true)
					player:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#SkillEffect_Recast"
					log.from = player
					log.arg = self:objectName()
					log.card_str = card:toString()
					room:sendLog(log)
					player:drawCards(1, "weapon_recast")
					return true
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if use.card:hasFlag("sy_recasted") then
				room:setCardFlag(card, "sy_recasted")
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		if everyone_can_recast then
			return target and target:isAlive()
		else
			return target and target:isAlive() and target:hasSkill(self:objectName())
		end
	end
}

function Nil2Int(nil_value)
	if nil_value == false or nil_value == nil or nil_value == "" then
		return 0
	else
		return nil_value
	end
end

tianyou_lightningRecord = sgs.CreateTriggerSkill{
	name = "#tianyou_lightningRecord",
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = -3,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local x = Nil2Int(room:getTag("BT_lightning_count"):toInt())
		if (damage.reason == "lightning" or damage.reason == "Lightning") or (damage.card and damage.card:isKindOf("Lightning")) and damage.damage > 0 then
			x = x + 1
			room:setTag("BT_lightning_count", sgs.QVariant(x))
		end
	end
}

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
			original_places = sgs.IntList()
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, thrower:objectName(), nil, skill, nil)
			room:throwCard(dummy, reason, victim, thrower)
		end
	end
end

--[[
	技能名：嗜杀
	相关武将：魔孙皓
	技能描述：锁定技，当你使用【杀】指定目标后，你随机弃置目标角色1-3张牌。
	引用：sy_shisha
]]--
sy_shisha = sgs.CreateTriggerSkill{
    name = "sy_shisha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.from or player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
		room:broadcastSkillInvoke(self:objectName())
		room:sendCompulsoryTriggerLog(player, self:objectName())
		for _, t in sgs.qlist(use.to) do
			if not t:isNude() then throwRandomCards(true, player, t, math.random(1, 3), "he", self:objectName()) end
		end
	end,
	priority = 20
}


--[[
	技能名：制衡
	相关武将：神司马师
	技能描述：出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置的牌中包括所有手牌，你多摸一张牌。你以此技能获得的牌不能通过【荒淫】从其他角色
	处获得。
	引用：sy_zhiheng
]]--
sy_zhihengCard = sgs.CreateSkillCard{
	name = "sy_zhiheng",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local x = 0
			x = x + self:subcardsLength()
			if source:getMark("zhiheng_allhand") > 0 then
				room:setPlayerMark(source, "zhiheng_allhand", 0)
				x = x + 1
			end
			source:drawCards(x, self:objectName())
		end
	end
}

sy_zhihengVS = sgs.CreateViewAsSkill{
	name = "sy_zhiheng",
	n = 1000,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhiheng_card = sy_zhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end,
	enabled_at_play = function(self, player)
		if isSanyingBoss(player) then
			return is2ndBossMode(player) and not player:hasUsed("#sy_zhiheng")
		else
			return not player:hasUsed("#sy_zhiheng")
		end
	end
}

sy_zhiheng = sgs.CreateTriggerSkill{
	name = "sy_zhiheng",
	view_as_skill = sy_zhihengVS,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
			if move.reason.m_skillName == "sy_zhiheng" then
				local s = 0
				for _, id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(id) == sgs.Player_PlaceHand then s = s + 1 end
				end
				if s >= player:getHandcardNum() then room:addPlayerMark(player, "zhiheng_allhand") end
				s = 0
			end
		end
	end
}


pojun_returncards = sgs.CreateTriggerSkill{
	name = "#pojun_returncards",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:getPile("sy_pojun_cards"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile("sy_pojun_cards"))
					room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), "sy_pojun", ""), false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


sy_maxcards = sgs.CreateMaxCardsSkill{
	name = "#sy_maxcards",
	extra_func = function(self, target)
		local n = 0
		if target:getMark("&sy_taiping") > 0 then n = n - target:getMark("&sy_taiping") end
		if target:hasSkill("sy_jiancheng") then
			n = n + 1
		end
		return n
	end
}


sy_clear = sgs.CreateTriggerSkill{
	name = "#sy_clear",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventLoseSkill then
			local sk = data:toString()
			if sk == "sy_taiping" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:loseAllMarks("&sy_taiping")
				end
			end
		end
		return false
	end
}


--距离（-1）
sy_distance_from = sgs.CreateDistanceSkill{
	name = "#sy_distance_from",
	correct_func = function(self, from, to)
		if from:getMark("jiuqian_mark") >= 1 then return -1 end
	end
}


--距离（+1）
sy_distance_to = sgs.CreateDistanceSkill{
	name = "#sy_distance_to",
	correct_func = function(self, from, to)
		if to:getPile("jiancheng"):length() > 0 then return 1 end
	end
}


--攻击范围
sy_atk = sgs.CreateAttackRangeSkill{
	name = "#sy_atk",
	extra_func = function(self, player, include_weapon)
		local n = 0
		if player:getMark("jiuqian_mark") >= 2 then n = n + 1 end
		if player:hasSkill("sy_baodao") and player:getWeapon() == nil then n = n + 2 end
		return n
	end
}


--虚拟移动
fake_move = sgs.CreateTriggerSkill{
	name = "#fake_move",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	priority = 20,
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if string.find(p:getFlags(), "_InTempMoving") then
				return true
			end
		end
		return false
	end
}


-- --解除alive(false)
reset_alive = sgs.CreateTriggerSkill{
	name = "#reset_alive",
	global = true,
	priority = 233,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.from == sgs.Player_NotActive then
			for _, pe in sgs.qlist(room:getPlayers()) do
				if pe:getMark("stop_currentAction") > 0 then
					room:setPlayerMark(pe, "stop_currentAction", 0)
					pe:setAlive(true)
					room:broadcastProperty(pe, "alive")
				end
			end
		end
	end,
	can_trigger = function()
		return true
	end
}


local sy_hiddenskills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_hp") then sy_hiddenskills:append(sy_hp) end
if not sgs.Sanguosha:getSkill("#sy_atk") then sy_hiddenskills:append(sy_atk) end
if not sgs.Sanguosha:getSkill("#sy_distance_from") then sy_hiddenskills:append(sy_distance_from) end
if not sgs.Sanguosha:getSkill("#sy_distance_to") then sy_hiddenskills:append(sy_distance_to) end
if not sgs.Sanguosha:getSkill("#sy_maxcards") then sy_hiddenskills:append(sy_maxcards) end
if not sgs.Sanguosha:getSkill("#sy_clear") then sy_hiddenskills:append(sy_clear) end
if not sgs.Sanguosha:getSkill("#sy_bianshen") then sy_hiddenskills:append(sy_bianshen) end
if not sgs.Sanguosha:getSkill("#sy_2ndturnstart") then sy_hiddenskills:append(sy_2ndturnstart) end
if not sgs.Sanguosha:getSkill("#pojun_returncards") then sy_hiddenskills:append(pojun_returncards) end
if not sgs.Sanguosha:getSkill("#W_recast") then sy_hiddenskills:append(W_recast) end
if not sgs.Sanguosha:getSkill("#fake_move") then sy_hiddenskills:append(fake_move) end
if not sgs.Sanguosha:getSkill("#reset_alive") then sy_hiddenskills:append(reset_alive) end
if not sgs.Sanguosha:getSkill("#tianyou_lightningRecord") then sy_hiddenskills:append(tianyou_lightningRecord) end
sgs.Sanguosha:addSkills(sy_hiddenskills)
sy_nobody:addSkill(sy_shisha)
sy_nobody:addSkill(sy_zhiheng)


sgs.LoadTranslationTable{
	["@sy_wake"] = "暴怒",
	["#W_recast"] = "装备重铸",
	["systatechange$"] = "第二阶段",
	["bafu_slash"] = "霸府",
	["#sy_second_stage"] = "%from 暴怒了！即将进入<font color = \"yellow\"><b>三英</b></font>·<font color = \"pink\"><b>第二阶段</b></font>！",
	["sy_shazhao_wansha"] = "完杀",
	[":sy_shazhao_wansha"] = "<font color=\"blue\"><b>锁定技，</b></font>在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。",
	["$sy_shazhao_wansha1"] = "现在不管说什么都迟了，蠢才！",
	["$sy_shazhao_wansha2"] = "凡愚，带着你的野心下地狱吧！",
	["sy_zhiheng"] = "制衡",
	[":sy_zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置的牌中包括所有手牌，你多摸一张牌。你以此技能获得的牌不能通过【荒淫】从"..
	"其他角色处获得。<font color = \"#EFABCD\">（此技能在第二阶段之前无效）</font>",
}


--神吕布
sy_lvbu1 = sgs.General(extension, "sy_lvbu1", "sy_god", 8, true)
--暴怒战神
sy_lvbu2 = sgs.General(extension, "sy_lvbu2", "sy_god", 4, true, true)
sy_lvbu1:addSkill("#sy_hp")
sy_lvbu1:addSkill("#sy_bianshen")
sy_lvbu1:addSkill("#W_recast")
sy_lvbu1:addSkill("#sy_2ndturnstart")
sy_lvbu2:addSkill("#W_recast")


--[[
	技能名：无双
	相关武将：神吕布
	技能描述：锁定技，你使用点数为奇数的牌对其他角色造成的伤害为3点。
	引用：sy_wushuang
]]--
sy_wushuang = sgs.CreateTriggerSkill{
	name = "sy_wushuang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:hasSkill("sy_wushuang") and player:getSeat() ~= damage.to:getSeat() then
			if damage.card and math.fmod(damage.card:getNumber(), 2) ~= 0 then
				room:sendCompulsoryTriggerLog(player, "sy_wushuang")
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				damage.damage = 3
				data:setValue(damage)
			end
		end
	end
}



--[[
	技能名：神威
	相关武将：神吕布
	技能描述：锁定技，你攻击范围内的所有其他角色手牌上限-1。
	引用：sy_shenwei
]]--
sy_shenwei = sgs.CreateMaxCardsSkill{
    name = "sy_shenwei",
	extra_func = function(self, player)
		local n = 0
		local shenwei_lvbu = -1
		for _, pe in sgs.qlist(player:getAliveSiblings()) do
			if pe:hasSkill(self:objectName()) then
				shenwei_lvbu = pe
				break
			end
		end
		if shenwei_lvbu ~= -1 then
			if shenwei_lvbu:inMyAttackRange(player) then n = n - 1 end
		end
		return n
	end,
}


--[[
	技能名：修罗
	相关武将：神吕布
	技能描述：当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。
	引用：sy_xiuluo
]]--
sy_xiuluo = sgs.CreateTriggerSkill{
	name = "sy_xiuluo" ,
	events = {sgs.TargetConfirming} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.from then return false end
		if use.from and use.from:getSeat() ~= player:getSeat() and use.to:contains(player) and use.to:length() == 1 then
			if use.card:isKindOf("Slash") or use.card:isNDTrick() then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1, self:objectName())
					local ini_card = use.card
					if use.card:isKindOf("Duel") then
						room:broadcastSkillInvoke(self:objectName())
					else
						local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
						if not use.card:isVirtualCard() then
							duel:addSubcard(use.card)
						elseif use.card:subcardsLength() > 0 then
							for _, id in sgs.qlist(use.card:getSubcards()) do
								duel:addSubcard(id)
							end
						end
						duel:setSkillName(self:objectName())
						use.card = duel
						data:setValue(use)
						local msg = sgs.LogMessage()
						msg.from = player
						msg.to:append(use.from)
						msg.type = "#XiuluoDuel"
						msg.arg = self:objectName()
						msg.card_str = ini_card:toString()
						room:sendLog(msg)
						room:broadcastSkillInvoke(self:objectName())
					end
				end
			end
		end
	end
}


--[[
	技能名：神戟
	相关武将：神吕布
	技能描述：锁定技，你使用的【杀】目标上限数+2。
	引用：sy_shenji
]]--
sy_shenji = sgs.CreateTargetModSkill{
    name = "sy_shenji",
	pattern = ".",
	extra_target_func = function(self, player, card)
	    if player:hasSkill(self:objectName()) and card:isKindOf("Slash") and (not card:getSubcards():isEmpty()) then
		    return 2
		else
		    return 0
		end
	end
}


sy_shenjiAudio = sgs.CreateTriggerSkill{
    name = "#sy_shenji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:hasSkill("sy_shenji") and use.to and use.to:length() >= 2 then
				room:sendCompulsoryTriggerLog(use.from, "sy_shenji")
				room:notifySkillInvoked(use.from, "sy_shenji")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:hasSkill("sy_shenji") and use.to and use.to:length() >= 2 then
				room:broadcastSkillInvoke("sy_shenji") --战神之力，开！
			end
		end
		return false
	end,
	can_trigger = function()
	    return true
	end
}


extension:insertRelatedSkills("sy_shenji", "#sy_shenji")


sy_lvbu1:addSkill(sy_wushuang)
sy_lvbu1:addSkill("mashu")
sy_lvbu2:addSkill("sy_wushuang")
sy_lvbu2:addSkill("mashu")
sy_lvbu2:addSkill(sy_xiuluo)
sy_lvbu2:addSkill(sy_shenwei)
sy_lvbu2:addSkill(sy_shenji)
sy_lvbu2:addSkill(sy_shenjiAudio)


sgs.LoadTranslationTable{
    ["sy_lvbu2"] = "神吕布",
	["#sy_lvbu2"] = "暴怒战神",
	["sy_lvbu1"] = "神吕布",
	["#sy_lvbu1"] = "最强神话",
	["~sy_lvbu2"] = "我在地狱等着你们！",
	["sy_shenwei"] = "神威",
	["#sy_shenwei"] = "神威",
	["$sy_shenwei"] = "唔唔唔唔唔唔——！！！",
	[":sy_shenwei"] = "锁定技，你攻击范围内的所有其他角色手牌上限-1。",
	["sy_wushuang"] = "无双",
	["$sy_wushuang1"] = "你的人头，我要定了！",
	["$sy_wushuang2"] = "这就让你去死！",
	[":sy_wushuang"] = "锁定技，你使用点数为奇数的牌对其他角色造成的伤害为3点。",
	["sy_shenji"] = "神戟",
	["$sy_shenji"] = "战神之力，开！",
	[":sy_shenji"] = "锁定技，你使用【杀】的目标上限+2。",
	["sy_xiuluo"] = "修罗",
	["$sy_xiuluo"] = "不可饶恕，不可饶恕！",
	[":sy_xiuluo"] = "当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。",
	["#XiuluoDuel"] = "由于 %from 的“%arg”效果，%to 对 %from 使用的 %card 的效果被改为 <font color = \"yellow\"><b>决斗</b></font>",
	["#W_recast"] = "装备重铸",
	["#SkillEffect_Recast"] = "%from 由于“%arg”的效果，重铸了 %card",
}


--神董卓
sy_dongzhuo1 = sgs.General(extension, "sy_dongzhuo1", "sy_god", 8, true)
sy_dongzhuo2 = sgs.General(extension, "sy_dongzhuo2", "sy_god", 4, true, true)
sy_dongzhuo1:addSkill("#sy_hp")
sy_dongzhuo1:addSkill("#sy_bianshen")
sy_dongzhuo1:addSkill("#W_recast")
sy_dongzhuo1:addSkill("#sy_2ndturnstart")
sy_dongzhuo2:addSkill("#W_recast")


--[[
	技能名：纵欲
	相关武将：神董卓
	技能描述：锁定技，出牌阶段，当你使用锦囊牌后，你视为使用【酒】。
	引用：sy_zongyu
]]--
sy_zongyu = sgs.CreateTriggerSkill{
	name = "sy_zongyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		local current = room:getCurrent()
		if use.from and use.from:objectName() == player:objectName() and use.from:objectName() == current:objectName() then
			if use.card:isKindOf("TrickCard") then
				local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				analeptic:setSkillName(self:objectName())
				analeptic:deleteLater()
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke("analeptic")
				room:useCard(sgs.CardUseStruct(analeptic, player, sgs.SPlayerList(), true))
			end
		end
	end
}


sy_dongzhuo1:addSkill(sy_zongyu)
sy_dongzhuo2:addSkill("sy_zongyu")


--[[
	技能名：凌虐
	相关武将：神董卓
	技能描述：当你造成不小于2点伤害时，你可以摸两张牌并加1点体力上限。
	引用：sy_lingnue
]]--
sy_lingnue = sgs.CreateTriggerSkill{
	name = "sy_lingnue",
	events = {sgs.DamageCaused},
	priority = -100,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:hasSkill(self:objectName()) and damage.damage >= 2 then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				room:gainMaxHp(player, 1)
			end
		end
	end
}


sy_dongzhuo1:addSkill(sy_lingnue)
sy_dongzhuo2:addSkill("sy_lingnue")


--[[
	技能名：暴政
	相关武将：神董卓
	技能描述：锁定技，其他角色摸牌阶段结束时，其选择一项：交给你一张锦囊牌，或视为你对其使用【杀】。
	引用：sy_baozheng
]]--
sy_baozheng = sgs.CreateTriggerSkill{
	name = "sy_baozheng",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		for _, s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
		    if player:getPhase() == sgs.Player_Draw and player:getSeat() ~= s:getSeat() then
			    local dz = sgs.QVariant()
				dz:setValue(s)
				local card = room:askForCard(player, "TrickCard", "@baozheng:" .. s:objectName(), dz, sgs.Card_MethodNone)
			    if card then
					room:doAnimate(1, s:objectName(), player:objectName())
			        room:sendCompulsoryTriggerLog(s, self:objectName())
			        room:broadcastSkillInvoke("sy_baozheng")
			        room:notifySkillInvoked(s, "sy_baozheng")
				    s:obtainCard(card)
			    else
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					slash:deleteLater()
					if not s:isProhibited(player, slash) then
						room:sendCompulsoryTriggerLog(s, self:objectName())
						room:notifySkillInvoked(s, "sy_baozheng")
						room:doAnimate(1, s:objectName(), player:objectName())
						local use = sgs.CardUseStruct()
						use.from = s
						use.to:append(player)
						use.card = slash
						room:useCard(use, false)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


sy_dongzhuo2:addSkill(sy_baozheng)


--[[
	技能名：逆施
	相关武将：神董卓
	技能描述：锁定技，当你受到其他角色造成的伤害后，其选择一项：弃置装备区里的所有牌，或视为你对其使用【杀】。
	引用：sy_nishi
]]--
sy_nishi = sgs.CreateTriggerSkill{
	name = "sy_nishi",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not damage.from or damage.from:objectName() == player:objectName() then return false end
		local choices = {"clearEquipArea", "ViewAsUseSlash="..player:objectName()}
		if damage.from:getCards("e"):isEmpty() then table.removeOne(choices, "clearEquipArea") end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		if player:isProhibited(damage.from, slash) then table.removeOne(choices, "ViewAsUseSlash="..player:objectName()) end
		if #choices > 0 then
			local item = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"))
			if item == "clearEquipArea" then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				room:doAnimate(1, player:objectName(), damage.from:objectName())
				damage.from:throwAllEquips()
			else
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:doAnimate(1, player:objectName(), damage.from:objectName())
				local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(damage.from)
				use.card = slash
				room:useCard(use, false)
			end
		end
	end
}

sy_dongzhuo2:addSkill(sy_nishi)


--[[
	技能名：横行
	相关武将：神董卓
	技能描述：锁定技，当你于出牌阶段外造成伤害时，你令此伤害+1。
	引用：sy_hengxing
]]--
sy_hengxing = sgs.CreateTriggerSkill{
	name = "sy_hengxing",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	priority = 10,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if player:getPhase() ~= sgs.Player_Play then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			room:doAnimate(1, player:objectName(), damage.to:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

sy_dongzhuo2:addSkill(sy_hengxing)


sgs.LoadTranslationTable{
    ["sy_dongzhuo2"] = "神董卓",
	["#sy_dongzhuo2"] = "狱魔王",
	["sy_dongzhuo1"] = "神董卓",
	["#sy_dongzhuo1"] = "狱魔王",
	["~sy_dongzhuo2"] = "那酒池肉林……都是我的……",
	["sy_zongyu"] = "纵欲",
	["$sy_zongyu"] = "呃……好酒！再来一壶！",
	[":sy_zongyu"] = "锁定技，出牌阶段，当你使用锦囊牌后，你视为使用【酒】。",
	["sy_lingnue"] = "凌虐",
	["$sy_lingnue"] = "来人！活捉了他！斩首祭旗！",
	[":sy_lingnue"] = "当你造成不小于2点伤害时，你可以摸两张牌并加1点体力上限。",
	["sy_baozheng"] = "暴政",
	["$sy_baozheng"] = "顺我者昌，逆我者亡！",
	[":sy_baozheng"] = "锁定技，其他角色摸牌阶段结束时，其选择一项：交给你一张锦囊牌，或视为你对其使用【杀】。",
	["@baozheng"] = "【暴政】效果触发，请交给%src一张锦囊牌，否则视为%src对你使用【杀】。",
	["sy_nishi"] = "逆施",
	["$sy_nishi"] = "看我不活剐了你们！",
	[":sy_nishi"] = "锁定技，当你受到其他角色造成的伤害后，其选择一项：弃置装备区里的所有牌，或视为你对其使用【杀】。",
	["clearEquipArea"] = "弃置装备区内的所有牌",
	["sy_nishi:ViewAsUseSlash"] = "视为%src对你使用【杀】",
	["sy_hengxing"] = "横行",
	["$sy_hengxing"] = "都被我踏平吧！哈哈哈哈哈哈哈哈！",
	[":sy_hengxing"] = "锁定技，当你于出牌阶段外造成伤害时，你令此伤害+1。",
}


--神张角
sy_zhangjiao1 = sgs.General(extension, "sy_zhangjiao1", "sy_god", 7, true)
sy_zhangjiao2 = sgs.General(extension, "sy_zhangjiao2", "sy_god", 4, true, true)
sy_zhangjiao1:addSkill("#sy_hp")
sy_zhangjiao1:addSkill("#sy_bianshen")
sy_zhangjiao1:addSkill("#W_recast")
sy_zhangjiao1:addSkill("#sy_2ndturnstart")
sy_zhangjiao2:addSkill("#W_recast")


--[[
	技能名：布教
	相关武将：神张角
	技能描述：其他角色的准备阶段，你可令其摸1张牌并获得1个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。
	引用：sy_bujiao
]]--
sy_bujiao = sgs.CreateTriggerSkill{
	name = "sy_bujiao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		for _, zhangjiao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local _data = sgs.QVariant()
			_data:setValue(player)
		    if player:getPhase() == sgs.Player_Start and player:getSeat() ~= zhangjiao:getSeat() and zhangjiao:askForSkillInvoke(self:objectName(), _data) then
				room:doAnimate(1, zhangjiao:objectName(), player:objectName())
		        room:broadcastSkillInvoke(self:objectName())
			    room:notifySkillInvoked(zhangjiao, "sy_bujiao")
			    player:drawCards(1, self:objectName())
				player:gainMark("&sy_taiping")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：太平
	相关武将：神张角
	技能描述：准备阶段，你可以弃置所有其他角色的“太平”标记并摸等量的牌，然后若你的手牌数大于其他角色的手牌数之和，你可以对其他角色各造成1点伤害。
	引用：sy_taiping
]]--
sy_taiping = sgs.CreateTriggerSkill{
	name = "sy_taiping",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			local tp_mark = 0
			local tp_hand = 0
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				tp_mark = tp_mark + pe:getMark("&sy_taiping")
				tp_hand = tp_hand + pe:getHandcardNum()
			end
			if tp_mark > 0 then
				if player:askForSkillInvoke(self:objectName(), data) then
					for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
						pe:loseAllMarks("&sy_taiping")
					end
					player:drawCards(tp_mark, self:objectName())
					if player:getHandcardNum() > tp_hand then
						local taiping = room:askForChoice(player, self:objectName(), "taiping_damage+cancel")
						if taiping == "taiping_damage" then
							for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
								room:doAnimate(1, player:objectName(), pe:objectName())
							end
							for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
								room:damage(sgs.DamageStruct(self:objectName(), player, pe))
							end
						end
					end
				end
			end
		end
	end
}


--[[
	技能名：妖惑
	相关武将：神张角
	技能描述：出牌阶段限一次，你选择一名其他角色，然后选择一项：①弃置等同于其手牌数的牌，获得其所有手牌；②弃置等同于其技能数的牌，然后偷取其所有技能，直至其下个回合开始或死亡。
	引用：sy_yaohuo
]]--
sy_yaohuoCard = sgs.CreateSkillCard{
	name = "sy_yaohuoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    if #targets == 0 then
		    return to_select:objectName() ~= sgs.Self:objectName() and (sgs.Self:getHandcardNum() + sgs.Self:getEquips():length() >= math.min(to_select:getHandcardNum(), to_select:getVisibleSkillList():length()))
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = sgs.Sanguosha:currentRoom()
		local choices = {"yaohuo_card"}
		local count = 0
		local skill_list = effect.to:getVisibleSkillList()
		local sks = {}
		for _,sk in sgs.qlist(skill_list) do
			table.insert(sks, sk:objectName())
			count = 1
		end
		if count > 0 then
			table.insert(choices, "yaohuo_skill")
		end
		local choice = room:askForChoice(effect.from, "sy_yaohuo", table.concat(choices, "+"))
		if choice == "yaohuo_card" then
			local n = effect.to:getHandcardNum()
			room:askForDiscard(effect.from, "sy_yaohuo", n, n, false, true)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, cd in sgs.qlist(effect.to:getHandcards()) do
				dummy:addSubcard(cd)
			end
			room:obtainCard(effect.from, dummy, false)
			dummy:deleteLater()
		elseif choice == "yaohuo_skill" then
			local n = effect.to:getVisibleSkillList():length()
			room:askForDiscard(effect.from, "sy_yaohuo", n, n, false, true)
			room:handleAcquireDetachSkills(effect.from, table.concat(sks, "|"))
			room:handleAcquireDetachSkills(effect.to, "-"..table.concat(sks, "|-"))
			effect.to:setTag("sy_yaohuoSkills", sgs.QVariant(table.concat(sks, "+")))
			room:setPlayerFlag(effect.to, "yaodao")
			room:setPlayerMark(effect.to, "sy_yaohuo"..effect.from:objectName(), 0)
			local skills = effect.from:getTag("Skills"):toString():split("+")
			table.insert(skills, table.concat(sks, "+"))
			effect.from:setTag("Skills", sgs.QVariant(table.concat(skills, "+")))
		end
	end
}

sy_yaohuoVs = sgs.CreateZeroCardViewAsSkill{
	name = "sy_yaohuo",
	view_as = function()
		return sy_yaohuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_yaohuoCard")
	end
}

sy_yaohuo = sgs.CreateTriggerSkill{
	name = "sy_yaohuo",
	view_as_skill = sy_yaohuoVs,
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.Death},
	can_trigger = function(self, target)
		return target and (target:hasSkill(self:objectName()) or target:hasFlag("yaodao"))
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:hasFlag("yaodao") then
				for _, zhangjiao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("sy_yaohuo"..zhangjiao:objectName()) > 0 then
						room:setPlayerMark(player, "sy_yaohuo"..zhangjiao:objectName(), 0)
						local skills = zhangjiao:getTag("Skills"):toString():split("+")
						room:handleAcquireDetachSkills(zhangjiao, "-"..table.concat(skills, "|-"))
						room:handleAcquireDetachSkills(player, table.concat(skills, "|"))
						zhangjiao:removeTag("Skills")
						room:setPlayerFlag(player, "-yaodao")
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local skills = player:getTag("Skills"):toString():split("+")
				room:handleAcquireDetachSkills(player, "-"..table.concat(skills, "|-"))
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("yaodao") and p:getMark("sy_yaohuo"..player:objectName()) > 0 then
						room:setPlayerMark(p, "sy_yaohuo"..player:objectName(), 0)
						local yaodao_skills = p:getTag("sy_yaohuoSkills"):toString():split("+")
						room:handleAcquireDetachSkills(p, table.concat(yaodao_skills, "|"))
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasFlag("yaodao") then
				for _, zhangjiao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if death.who:getMark("sy_yaohuo"..zhangjiao:objectName()) > 0 then
						room:setPlayerMark(death.who, "sy_yaohuo"..zhangjiao:objectName(), 0)
						local skills = zhangjiao:getTag("Skills"):toString():split("+")
						room:handleAcquireDetachSkills(zhangjiao, "-"..table.concat(skills, "|-"))
						room:handleAcquireDetachSkills(death.who, table.concat(skills, "|"))
						zhangjiao:removeTag("Skills")
						room:setPlayerFlag(death.who, "-yaodao")
					end
				end
			end
		end
	end
}


--[[
	技能名：三治
	相关武将：神张角
	技能描述：每当你使用3种不同类型的牌后，你可令所有其他角色获得1个“太平”标记。
	引用：sy_sanzhi
]]--
function getTypeString(card)
	if card:isKindOf("BasicCard") then return "basic" end
	if card:isKindOf("TrickCard") then return "trick" end
	if card:isKindOf("EquipCard") then return "equip" end
end
sy_sanzhi = sgs.CreateTriggerSkill{
	name = "sy_sanzhi",
	events = {sgs.CardFinished, sgs.EventLoseSkill},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(self:objectName()) and use.from:objectName() == player:objectName() and  use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill then
				if use.card:isVirtualCard() and use.card:subcardsLength() == 0 then return false end
				local type_str = player:getTag("sanzhi_types"):toString():split("+")
				if not table.contains(type_str, getTypeString(use.card)) then table.insert(type_str, getTypeString(use.card)) end
				if #type_str == 3 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
							room:doAnimate(1, player:objectName(), pe:objectName())
						end
						for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
							pe:gainMark("&sy_taiping")
						end
					end
					type_str = {}
				end
				player:setTag("sanzhi_types", sgs.QVariant(table.concat(type_str, "+")))
			end
		end
	end
}


sy_zhangjiao1:addSkill(sy_bujiao)
sy_zhangjiao1:addSkill(sy_taiping)
sy_zhangjiao2:addSkill("sy_bujiao")
sy_zhangjiao2:addSkill("sy_taiping")
sy_zhangjiao2:addSkill(sy_yaohuo)
sy_zhangjiao2:addSkill(sy_sanzhi)


sgs.LoadTranslationTable{	
	["sy_zhangjiao2"] = "神张角",
	["#sy_zhangjiao2"] = "大贤良师",
	["sy_zhangjiao1"] = "神张角",
	["#sy_zhangjiao1"] = "大贤良师",
	["~sy_zhangjiao2"] = "逆道者，必遭天谴而亡！",
	["sy_bujiao"] = "布教",
	["$sy_bujiao"] = "众星熠熠，不若一日之明。",
	[":sy_bujiao"] = "其他角色的准备阶段，你可令其摸1张牌并获得1个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。",
	["sy_taiping"] = "太平",
	["taiping_damage"] = "对所有其他角色造成1点伤害",
	["$sy_taiping"] = "行大舜之道，救苍生万民。",
	[":sy_taiping"] = "准备阶段，你可以弃置所有其他角色的“太平”标记并摸等量的牌，然后若你的手牌数大于其他角色的手牌数之和，你可以对其他角色各造成1点伤害。",
	["sy_yaohuo"] = "妖惑",
	["sy_yaohuoCard"] = "妖惑",
	["$sy_yaohuo"] = "存恶害义，善必诛之！",
	[":sy_yaohuo"] = "出牌阶段限一次，你选择一名其他角色，然后选择一项：①弃置等同于其手牌数的牌，获得其所有手牌；②弃置等同于其技能数的牌，然后偷取其所有技能"..
	"，直至其下个回合开始或死亡。",
	["yaohuo_card"] = "获得其所有手牌",
	["yaohuo_skill"] = "获得其所有技能且其失去所有技能",
	["sy_sanzhi"] = "三治",
	["$sy_sanzhi"] = "三气集，万物治！",
	[":sy_sanzhi"] = "当你使用3种不同类型的牌后，你可令所有其他角色获得1个“太平”标记。",
}


--神张让
sy_zhangrang1 = sgs.General(extension, "sy_zhangrang1", "sy_god", 7, true)
sy_zhangrang2 = sgs.General(extension, "sy_zhangrang2", "sy_god", 4, true, true)
sy_zhangrang1:addSkill("#sy_hp")
sy_zhangrang1:addSkill("#sy_bianshen")
sy_zhangrang1:addSkill("#W_recast")
sy_zhangrang1:addSkill("#sy_2ndturnstart")
sy_zhangrang2:addSkill("#W_recast")


--[[
	技能名：谗陷
	相关武将：神张让
	技能描述：出牌阶段限一次，你可以移动一名角色区域里的一张牌，若如此做，视为失去牌的角色对获得牌的角色使用【决斗】，然后你获得受到此【决斗】伤害的角色的
	一张牌。
	引用：sy_chanxian
]]--
function canMoveCard(target)
	if not target:isKongcheng() then return true end
	local others = target:getAliveSiblings()
	local tos = sgs.PlayerList()
	if target:getJudgingArea():length() > 0 then
		for _, card in sgs.qlist(target:getJudgingArea()) do
			for _, pe in sgs.qlist(others) do
				if not target:isProhibited(pe, card) and not pe:containsTrick(card:objectName()) and (not tos:contains(pe)) then
					tos:append(pe)
				end
			end
		end
	end
	if target:hasEquip() then
		for _, card in sgs.qlist(target:getEquips()) do
			local equip = card:getRealCard():toEquipCard()
			local index = equip:location()
			for _, pe in sgs.qlist(others) do
				if pe:hasEquipArea(index) and (not tos:contains(pe)) then
					tos:append(pe)
				end
			end
		end
	end
	if tos:isEmpty() then return false else return true end
end


sy_chanxianCard = sgs.CreateSkillCard{
    name = "sy_chanxianCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
        if #targets == 0 then
		    return canMoveCard(to_select)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local from = targets[1]
		local card_id = room:askForCardChosen(source, from, "hej", "sy_chanxian")
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		local tos = sgs.SPlayerList()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), "sy_chanxian", nil)
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("sy_chanxian")
		duel:deleteLater()
		room:setPlayerFlag(source, "sy_chanxian")
		if place == sgs.Player_PlaceHand then
			local _to = room:askForPlayerChosen(source, room:getOtherPlayers(from), "sy_chanxian", "@chanxian_to:"..card:objectName()..":"..card:getSuitString().."_char"..":"..card:getNumberString())
			room:moveCardTo(card, from, _to, place, reason)
			room:doAnimate(1, from:objectName(), _to:objectName())
			if (not from:isCardLimited(duel, sgs.Card_MethodUse)) and (not from:isProhibited(_to, duel)) and from:isAlive() and _to:isAlive() then
				room:useCard(sgs.CardUseStruct(duel, from, _to))
			end
		elseif place == sgs.Player_PlaceDelayedTrick then
			for _, pe in sgs.qlist(room:getOtherPlayers(from)) do
				if not from:isProhibited(pe, card) and not pe:containsTrick(card:objectName()) then
					tos:append(pe)
				end
			end
			local _to = room:askForPlayerChosen(source, tos, "sy_chanxian", "@chanxian_to:"..card:objectName()..":"..card:getSuitString().."_char"..":"..card:getNumberString())
			room:moveCardTo(card, from, _to, place, reason)
			room:doAnimate(1, from:objectName(), _to:objectName())
			if (not from:isCardLimited(duel, sgs.Card_MethodUse)) and (not from:isProhibited(_to, duel)) and from:isAlive() and _to:isAlive() then
				room:useCard(sgs.CardUseStruct(duel, from, _to))
			end
		elseif place == sgs.Player_PlaceEquip then
			local equip = card:getRealCard():toEquipCard()
			local index = equip:location()
			for _, pe in sgs.qlist(room:getOtherPlayers(from)) do
				if pe:hasEquipArea(index) then
					tos:append(pe)
				end
			end
			local _to = room:askForPlayerChosen(source, tos, "sy_chanxian", "@chanxian_to:"..card:objectName()..":"..card:getSuitString().."_char"..":"..card:getNumberString())
			local exchangeMove = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct(card_id, _to, place, reason)
			exchangeMove:append(move1)
			if _to:getEquip(index) ~= nil then
				local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, _to:objectName())
				local move2 = sgs.CardsMoveStruct(_to:getEquip(index):getId(), nil, sgs.Player_DiscardPile, reason2)
				exchangeMove:append(move2)
			end
			room:doAnimate(1, from:objectName(), _to:objectName())
			room:moveCardsAtomic(exchangeMove, false)
			if (not from:isCardLimited(duel, sgs.Card_MethodUse)) and (not from:isProhibited(_to, duel)) and from:isAlive() and _to:isAlive() then
				room:useCard(sgs.CardUseStruct(duel, from, _to))
			end
		
		end
		room:setPlayerFlag(source, "-sy_chanxian")
	end
}

sy_chanxianVS = sgs.CreateZeroCardViewAsSkill{
    name = "sy_chanxian",
	view_as = function()
		return sy_chanxianCard:clone()
	end,
	enabled_at_play = function(self, player)
		local tos = sgs.PlayerList()
		for _, pe in sgs.qlist(player:getAliveSiblings()) do
			if canMoveCard(pe) then tos:append(pe) end
		end
		return (not player:hasUsed("#sy_chanxianCard")) and not tos:isEmpty()
	end
}

sy_chanxian = sgs.CreateTriggerSkill{
	name = "sy_chanxian",
	events = {sgs.Damaged},
	can_trigger = function(self, target)
		return target
	end,
	view_as_skill = sy_chanxianVS,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == self:objectName() and damage.damage > 0 then
			if not damage.to:isNude() then
				for _, zhangrang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if zhangrang:hasFlag(self:objectName()) then
						local id = room:askForCardChosen(zhangrang, damage.to, "he", self:objectName())
						zhangrang:obtainCard(sgs.Sanguosha:getCard(id), false)
					end
				end
			end
		end
	end
}


--[[
	技能名：残掠
	相关武将：神张让
	技能描述：每当你从其他角色处获得1张牌时，你可对其造成1点伤害。每当其他角色从你处获得1张牌时，须弃置1张牌。
	引用：sy_canlue
]]--
sy_canlue = sgs.CreateTriggerSkill{
    name = "sy_canlue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive()
				and (move.from:objectName() ~= move.to:objectName())
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and (move.to_place == sgs.Player_PlaceHand)
				and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
			local _movefrom
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if move.from:objectName() == p:objectName() then
					_movefrom = p
					break
				end
			end
			room:setPlayerFlag(_movefrom, "canlueDamageTarget")
			local invoke = room:askForSkillInvoke(player, self:objectName(), data)
			room:setPlayerFlag(_movefrom, "-canlueDamageTarget")
			if invoke then
				room:doAnimate(1, player:objectName(), _movefrom:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, _movefrom, move.card_ids:length()))
			end
		end
		if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill("sy_canlue") and 
			(move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
			if move.to and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
			    local _to
				for _, _player in sgs.qlist(room:getAlivePlayers()) do
				    if move.to:objectName() == _player:objectName() then
					    _to = _player
						break
					end
				end
				room:doAnimate(1, player:objectName(), _to:objectName())
				room:broadcastSkillInvoke("sy_canlue")
				room:notifySkillInvoked(player, "sy_canlue")
				room:sendCompulsoryTriggerLog(player, "sy_canlue")
			    room:askForDiscard(_to, "sy_canlue", move.card_ids:length(), move.card_ids:length(), false, true)
			end
		end
	end
}



--[[
	技能名：乱政
	相关武将：神张让
	技能描述：每回合限一次，一名角色使用基本牌或非延时锦囊牌指定唯一目标时，你可令另一名角色也成为此牌的目标。
	引用：sy_luanzheng
]]--
sy_luanzheng = sgs.CreateTriggerSkill{
    name = "sy_luanzheng",
	events = {sgs.EventPhaseStart, sgs.TargetConfirming, sgs.EventLoseSkill},
	can_trigger = function(self, target)
		return target
	end,
	priority = 3,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_Start then
				for _, zhangrang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if zhangrang:getMark("luanzheng_current") > 0 then room:setPlayerMark(zhangrang, "luanzheng_current", 0) end
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.from and use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and (not use.card:isKindOf("Analeptic")) and use.to:length() == 1 then
				local to = use.to:at(0)
				local extra = sgs.SPlayerList()
				for _, pe in sgs.qlist(room:getOtherPlayers(to)) do
					if not room:isProhibited(use.from, pe, use.card) then extra:append(pe) end
				end
				if extra:isEmpty() then return false end
				for _, zhangrang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if zhangrang:getMark("luanzheng_current") > 0 then continue end
					local q = sgs.QVariant()
					q:setValue(use)
					zhangrang:setTag("luanzheng_data", q)
					local exone = room:askForPlayerChosen(zhangrang, extra, self:objectName(), "@luanzheng-extra:"..use.card:objectName()..":"..use.card:getSuitString().."_char"..":"..use.card:getNumberString(), true, true)
					if exone then
						room:addPlayerMark(zhangrang, "luanzheng_current")
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, use.from:objectName(), exone:objectName())
						local msg = sgs.LogMessage()
						msg.from = zhangrang
						msg.type = "#LuanzhengExTarget"
						msg.to:append(exone)
						msg.card_str = use.card:toString()
						room:sendLog(msg)
						use.to:append(exone)
						room:setPlayerFlag(use.from, "ZenhuiUser_" .. use.card:toString())
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then room:setPlayerMark(player, "luanzheng_current", 0) end
		end
		return false
	end
}


sy_zhangrang1:addSkill(sy_chanxian)
sy_zhangrang2:addSkill("sy_chanxian")
sy_zhangrang2:addSkill(sy_luanzheng)
sy_zhangrang2:addSkill(sy_canlue)


sgs.LoadTranslationTable{	
	["sy_zhangrang2"] = "神张让",
	["~sy_zhangrang2"] = "小的怕是活不成了，陛下，保重……",
	["#sy_zhangrang2"] = "祸乱之源",
	["sy_zhangrang1"] = "神张让",
	["#sy_zhangrang1"] = "祸乱之源",
	["sy_chanxian"] = "谗陷",
	["sy_chanxianCard"] = "谗陷",
	["@chanxian_to"] = "请选择获得此%src[%dest%arg]的角色",
	["sy_chanxianeCard"] = "谗陷",
	["$sy_chanxian1"] = "懂不懂宫里的规矩？",
	["$sy_chanxian2"] = "活得不耐烦了吧？",
	[":sy_chanxian"] = "出牌阶段限一次，你可以移动一名角色区域里的一张牌，若如此做，视为失去牌的角色对获得牌的角色使用【决斗】，然后你获得受到此【决斗】伤"..
	"害的角色的一张牌。",
	["sy_canlue"] = "残掠",
	["$sy_canlue"] = "没钱？没钱，就拿命来抵吧！",
	[":sy_canlue"] = "当你从其他角色处获得一张牌后，你可对其造成1点伤害。当其他角色获得的一张牌时，你令其弃置1张牌。",
	["sy_luanzheng"] = "乱政",
	["#LuanzhengExTarget"] = "%from 令 %to 成为 %card 的额外目标",
	["$sy_luanzheng1"] = "陛下，都、都是他们干的！",
	["$sy_luanzheng2"] = "大、大、大事不好！有人造反了！",
	[":sy_luanzheng"] = "每回合限一次，一名角色使用基本牌或非延时锦囊牌指定唯一目标时，你可令另一名角色也成为此牌的目标。",
	["@luanzheng-extra"] = "你可以发动【乱政】为此%src[%dest%arg]选择一名其他角色作为额外目标",
}


--神魏延
sy_weiyan1 = sgs.General(extension, "sy_weiyan1", "sy_god", 8, true)
sy_weiyan2 = sgs.General(extension, "sy_weiyan2", "sy_god", 4, true, true)
sy_weiyan1:addSkill("#sy_hp")
sy_weiyan1:addSkill("#sy_bianshen")
sy_weiyan1:addSkill("#W_recast")
sy_weiyan1:addSkill("#sy_2ndturnstart")
sy_weiyan2:addSkill("#W_recast")


--[[
	技能名：恃傲
	相关武将：神魏延
	技能描述：准备阶段或回合结束阶段开始时，你可以视为对一名其他角色使用一张【杀】（不计次、无距离限制）。
	引用：sy_shiao
]]--
sy_shiao = sgs.CreateTriggerSkill{
	name = "sy_shiao",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			local players = sgs.SPlayerList()
			local slash = dummyCard()
			slash:setSkillName("sy_shiao")
			
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not sgs.Sanguosha:isProhibited(player, p, slash) then
					players:append(p)
				end
			end
			if players:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "@shiao-tar", true, true)
			if target then
			    room:notifySkillInvoked(player, "sy_shiao")
				if player:getPhase() == sgs.Player_Start then
			    	room:broadcastSkillInvoke(self:objectName(), 1)
				elseif player:getPhase() == sgs.Player_Finish then
					room:broadcastSkillInvoke(self:objectName(), 2)
				end
				room:useCard(sgs.CardUseStruct(slash, player, target), false)
			end
			slash:deleteLater()
		end
	end
}


--[[
	技能名：反骨
	相关武将：神魏延
	技能描述：锁定技，当你受到的伤害结算完毕后，你令当前回合结束，然后你进行一个额外的回合。
	引用：sy_fangu
]]--
sy_fangu = sgs.CreateTriggerSkill{
	name = "sy_fangu",
	events = {sgs.Damaged, sgs.DamageComplete, sgs.TurnStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and damage.damage > 0 then
				if damage.nature ~= sgs.DamageStruct_Normal then damage.to:setChained(false) end
				room:setPlayerFlag(damage.to, "fangu_do")
			end
		elseif event == sgs.DamageComplete then
		    local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() and player:hasFlag("fangu_do") and player:isAlive() then
			    room:setPlayerFlag(player, "-fangu_do")
				room:addPlayerMark(player, "sy_fangu", 1)
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = self:objectName()
				msg.type = "#fanguExTurn"
				room:sendLog(msg)
				room:broadcastSkillInvoke(self:objectName())
				room:throwEvent(sgs.TurnBroken)
			end
		elseif event == sgs.TurnStart then
			for _, s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if s:getMark("sy_fangu") > 0 then
					room:setPlayerMark(s, "sy_fangu", 0)
					s:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}



--[[
	技能名：狂袭
	相关武将：神魏延
	技能描述：当你使用锦囊牌指定其他角色为目标后，你可以视为对这些目标使用一张【杀】（不计入出牌阶段使用次数限制）。若以此法使用的【杀】未造成伤害，你失去1点体力。
	引用：sy_kuangxi
]]--
sy_kuangxi = sgs.CreateTriggerSkill{
	name = "sy_kuangxi",
	events = {sgs.CardFinished, sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") and (use.to:length() > 1 or (not use.to:contains(player) and use.to:length() == 1) ) then
				if player:askForSkillInvoke(self:objectName(), data) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					slash:deleteLater()
					room:notifySkillInvoked(player, "sy_kuangxi")
					local to = sgs.SPlayerList()
					for _,p in sgs.qlist(use.to) do
						if player:canSlash(p, nil, false) and player:objectName() ~= p:objectName() then to:append(p) end
					end
					local use = sgs.CardUseStruct()
					use.from = player
					use.to = to
					use.card = slash
					use.m_addHistory = false
					slash:onUse(room, use)
				end
			end
			if use.card and use.card:getSkillName() == self:objectName() and player:getMark(self:objectName()) == 0 then
				room:loseHp(player, 1, true, player, self:objectName())
			end
			room:setPlayerMark(player, self:objectName(), 0)
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.card and damage.card:getSkillName() == self:objectName() then
				room:addPlayerMark(player, self:objectName())
			end
		end
	end
}

sy_weiyan1:addSkill(sy_shiao)
sy_weiyan2:addSkill("sy_shiao")
sy_weiyan2:addSkill(sy_fangu)
sy_weiyan2:addSkill(sy_kuangxi)


sgs.LoadTranslationTable{	
	["sy_weiyan2"] = "神魏延",
	["#sy_weiyan2"] = "嗜血狂狼",
	["sy_weiyan1"] = "神魏延",
	["#sy_weiyan1"] = "嗜血狂狼",
	["~sy_weiyan2"] = "这……就是老子追求的东西吗？",
	["sy_shiao"] = "恃傲",
	["@shiao-tar"] = "你可以发动“恃傲”视为对一名其他角色使用一张【杀】<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["shiao-slash"] = "恃傲",
	["$sy_shiao1"] = "靠手里的家伙来说话吧。",
	["$sy_shiao2"] = "少废话！真有本事就来打！",
	[":sy_shiao"] = "准备阶段或回合结束阶段开始时，你可以视为对一名其他角色使用一张【杀】（不计次、无距离限制）。",
	["sy_fangu"] = "反骨",
	["fangu"] = "反骨",
	["$sy_fangu"] = "一群胆小之辈，成天坏我大事！",
	[":sy_fangu"] = "锁定技，当你受到的伤害结算完毕后，你令当前回合结束，然后你进行一个额外的回合。",
	["sy_kuangxi"] = "狂袭",
	["$sy_kuangxi1"] = "敢挑战老子，你就后悔去吧！",
	["$sy_kuangxi2"] = "凭你们，是阻止不了老子的！",
	[":sy_kuangxi"] = "当你使用锦囊牌指定其他角色为目标后，你可以视为对这些目标使用一张【杀】（不计入出牌阶段使用次数限制）。若以此法使用的【杀】未造成伤害，"..
	"你失去1点体力。",
}


--神孙皓
sy_sunhao1 = sgs.General(extension, "sy_sunhao1", "sy_god", 8, true)
sy_sunhao2 = sgs.General(extension, "sy_sunhao2", "sy_god", 4, true, true)
sy_sunhao3 = sgs.General(extension, "sy_sunhao3", "sy_god", 4, true, true)
sy_sunhao1:addSkill("#sy_hp")
sy_sunhao1:addSkill("#sy_bianshen")
sy_sunhao1:addSkill("#W_recast")
sy_sunhao1:addSkill("#sy_2ndturnstart")
sy_sunhao2:addSkill("#W_recast")
sy_sunhao3:addSkill("#W_recast")


--[[
	技能名：明政
	相关武将：神孙皓
	技能描述：锁定技，其他角色/你的摸牌阶段摸牌数+1/+2。当你受到伤害后，你摸X张牌（X为已进行的回合数）并失去“明政”，然后获得“嗜杀”。
	引用：sy_mingzheng
]]--
sy_mingzheng = sgs.CreateTriggerSkill{
    name = "sy_mingzheng",
	events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local flag = 1
		for _, p in sgs.qlist(room:getAllPlayers()) do
		    if p:getMark("mingzheng_damaged") > 0 then
			    flag = 0
			end
		end
		if event == sgs.EventPhaseStart then
			if flag == 0 then return false end
			if player:getPhase() == sgs.Player_RoundStart then 
				for _, sunhao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do 
					room:addPlayerMark(sunhao, "&"..self:objectName(), 1) 
				end
			end
		elseif event == sgs.DrawNCards then
		    if flag == 0 then return false end
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return end
		    room:broadcastSkillInvoke("sy_mingzheng")
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _, sunhao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do 
				room:notifySkillInvoked(sunhao, self:objectName())
				local x = 2
				if player:getSeat() ~= sunhao:getSeat() then x = 1 end
				draw.num = draw.num + x
			end
			data:setValue(draw)
		elseif event == sgs.Damaged then
		    local damage = data:toDamage()
			if damage.to:objectName() ~= player:objectName() then return false end
			if not player:hasSkill(self:objectName()) then return false end
			room:addPlayerMark(player, "mingzheng_damaged", 999)
			room:sendCompulsoryTriggerLog(player, self:objectName())
		    room:notifySkillInvoked(player, "sy_mingzheng")
		    room:broadcastSkillInvoke("sy_mingzheng")
			player:drawCards(player:getMark("&"..self:objectName()), self:objectName())
			room:setPlayerMark(player, "&"..self:objectName(), 0)
			if not player:hasSkill("sy_mingzheng") then return false end
		    if not player:hasSkill("sy_shisha") then room:acquireSkill(player, "sy_shisha") end
		    if player:hasSkill("sy_mingzheng") then room:detachSkillFromPlayer(player, "sy_mingzheng") end
		end
	end,
	can_trigger = function(self, target)
	    return target
	end
}


--[[
	技能名：荒淫
	相关武将：神孙皓
	技能描述：当你弃置其他角色的牌时，你可以从这些牌里随机获得一张牌。
	引用：sy_huangyin
]]--
sy_huangyin = sgs.CreateTriggerSkill{
    name = "sy_huangyin",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		local source = -1
		local players = room:findPlayersBySkillName(self:objectName())
		if players:isEmpty() then return false end
		if move.from and move.reason.m_playerId and move.to_place == sgs.Player_DiscardPile then
			for _, sunhao in sgs.qlist(players) do
				if move.reason.m_playerId == sunhao:objectName() and move.from:getSeat() ~= player:getSeat() then
					source = sunhao
					break
				end
			end
			if source ~= -1 and player:askForSkillInvoke(self:objectName(), data) then
				local ids = sgs.QList2Table(move.card_ids)
				local card = sgs.Sanguosha:getCard(ids[math.random(1, #ids)])
				player:obtainCard(card)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end
}


--[[
	技能名：醉酒
	相关武将：神孙皓
	技能描述：出牌阶段，你可以随机弃置X张手牌（X为你于本阶段内再次发动“醉酒”的次数），然后视为随机使用【酒】或【杀】，且以此法使用的牌不计入次数限制。
	引用：sy_zuijiu
]]--
sy_zuijiuCard = sgs.CreateSkillCard{
	name = "sy_zuijiuCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local zuijiu_items = {"slash", "analeptic"}
		local zuijiu = zuijiu_items[math.random(1, #zuijiu_items)]
		if zuijiu == "slash" then
			room:setPlayerFlag(source, "zuijiu_beingInvoke")
			local n = source:getMark("&sy_zuijiu")
			if n > 0 then throwRandomCards(true, source, source, n, "h", "sy_zuijiu") end
			if not room:askForUseCard(source, "@@sy_zuijiuNormalSlash", "@sy_zuijiuNormalSlash") then
				room:setPlayerFlag(source, "-zuijiu_beingInvoke")
			end
		else
			local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
			analeptic:setSkillName("sy_zuijiu")
			local n = source:getMark("&sy_zuijiu")
			if n > 0 then throwRandomCards(true, source, source, n, "h", "sy_zuijiu") end
			room:useCard(sgs.CardUseStruct(analeptic, source, source, false), false)
			analeptic:deleteLater()
		end
		room:addPlayerMark(source, "&sy_zuijiu", 1)
	end
}

sy_zuijiu = sgs.CreateZeroCardViewAsSkill{
	name = "sy_zuijiu",
	view_as = function()
		return sy_zuijiuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getHandcardNum() >= player:getMark("&sy_zuijiu")
	end,
}

--“醉酒”普通杀技能卡
sy_zuijiuNormalSlashCard = sgs.CreateSkillCard{
	name = "sy_zuijiuNormalSlashCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select, false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("sy_zuijiu")
		slash:deleteLater()
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for _, p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, false)
	end,
}

sy_zuijiuNormalSlash = sgs.CreateZeroCardViewAsSkill{
	name = "sy_zuijiuNormalSlash",
	view_as = function()
		return sy_zuijiuNormalSlashCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sy_zuijiuNormalSlash"
	end,
}


sy_zuijiuu = sgs.CreateTriggerSkill{
    name = "sy_zuijiuu",
	events = {sgs.EventPhaseChanging, sgs.EventLoseSkill},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:hasSkill("sy_zuijiu") and change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "&sy_zuijiu", 0)
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == "sy_zuijiu" then
				if player:getMark("&sy_zuijiu") > 0 then room:setPlayerMark(player, "&sy_zuijiu", 0) end
			end
		end
		return false
	end
}

local zuijiu_global = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sy_zuijiuu") then zuijiu_global:append(sy_zuijiuu) end
if not sgs.Sanguosha:getSkill("sy_zuijiuNormalSlash") then zuijiu_global:append(sy_zuijiuNormalSlash) end
sgs.Sanguosha:addSkills(zuijiu_global)



--[[
	技能名：归命
	相关武将：神孙皓
	技能描述：限定技，当你进入濒死状态时，你可以回复体力至X点，然后你依次弃置所有其他角色随机X张牌（X为存活角色数）。
	引用：sy_guiming
]]--
sy_guiming = sgs.CreateTriggerSkill{
    name = "sy_guiming",
	frequency = sgs.Skill_Limited,
	limit_mark = "@guiming",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
		    local x = room:getAlivePlayers():length()
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("mo_sunhao", "sy_guiming")
			local guiming_self = sgs.RecoverStruct()
			guiming_self.recover = x - player:getHp()
			guiming_self.who = player
			room:recover(player, guiming_self, true)
			player:loseMark("@guiming")
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1, player:objectName(), pe:objectName())
			end
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				throwRandomCards(true, player, pe, math.random(1, x), "he", self:objectName())
			end
			return false
		end
	end,
	can_trigger = function(self, target)
	    return target and target:hasSkill("sy_guiming") and target:getMark("@guiming") > 0
	end
}


sy_sunhao1:addSkill(sy_mingzheng)
sy_sunhao1:addRelateSkill("sy_shisha")
sy_sunhao2:addSkill("sy_mingzheng")
sy_sunhao2:addRelateSkill("sy_shisha")
sy_sunhao2:addSkill(sy_huangyin)
sy_sunhao2:addSkill(sy_zuijiu)
sy_sunhao2:addSkill(sy_guiming)
sy_sunhao3:addSkill("sy_huangyin")
sy_sunhao3:addSkill("sy_zuijiu")
sy_sunhao3:addSkill("sy_guiming")


sgs.LoadTranslationTable{	
	["sy_sunhao3"] = "神孙皓",
	["#sy_sunhao3"] = "末世暴君",
	["~sy_sunhao3"] = "乱臣贼子，不得好死！",
	["sy_sunhao2"] = "神孙皓",
	["#sy_sunhao2"] = "末世暴君",
	["sy_sunhao1"] = "神孙皓",
	["#sy_sunhao1"] = "末世暴君",
	["~sy_sunhao2"] = "乱臣贼子，不得好死！",
	["sy_mingzheng"] = "明政",
	[":sy_mingzheng"] = "锁定技，其他角色/你的摸牌阶段摸牌数+1/+2。当你受到伤害后，你摸X张牌（X为已进行的回合数）并失去“明政”，然后获得“嗜杀”。",
	["$sy_mingzheng"] = "开仓放粮，赈济百姓！",
	["sy_shisha"] = "嗜杀",
	[":sy_shisha"] = "锁定技，当你使用【杀】指定目标后，你随机弃置目标角色1-3张牌。",
	["$sy_shisha"] = "净是些碍眼的家伙，都杀！都杀！",
	["sy_zuijiu"] = "醉酒",
	["$sy_zuijiu"] = "酒……酒呢！拿酒来！",
	["sy_zuijiunormalslash"] = "醉酒",
	["sy_zuijiuNormalSlashCard"] = "醉酒",
	["@sy_zuijiuNormalSlash"] = "你可以视为对一名其他角色使用不计入次数限制的【杀】",
	["~sy_zuijiuNormalSlash"] = "选择目标角色，点击“确定”",
	[":sy_zuijiu"] = "出牌阶段，你可以随机弃置X张手牌（X为你于本阶段内再次发动“醉酒”的次数），然后视为随机使用【酒】或【杀】，以此法使用的牌不计入次数限制。",
	["sy_huangyin"] = "荒淫",
	["$sy_huangyin"] = "美人儿来来来，让朕瞧瞧！",
	[":sy_huangyin"] = "当你弃置其他角色的牌时，你可以从这些牌里随机获得一张牌。",
	["sy_guiming"] = "归命",
	["@guiming"] = "归命",
	["$sy_guiming"] = "你们！难道忘了朝廷之恩吗！",
	[":sy_guiming"] = "限定技，当你进入濒死状态时，你可以回复体力至X点，然后你依次弃置所有其他角色随机X张牌（X为存活角色数）。",
}


--神蔡夫人
sy_caifuren1 = sgs.General(extension, "sy_caifuren1", "sy_god", 7, false)
sy_caifuren2 = sgs.General(extension, "sy_caifuren2", "sy_god", 4, false, true)
sy_caifuren1:addSkill("#sy_hp")
sy_caifuren1:addSkill("#sy_bianshen")
sy_caifuren1:addSkill("#W_recast")
sy_caifuren1:addSkill("#sy_2ndturnstart")
sy_caifuren2:addSkill("#W_recast")


--[[
	技能名：诋毁
	相关武将：神蔡夫人
	技能描述：出牌阶段限一次，你可以令一名角色对另一名体力较少的角色造成1点伤害。若你不是伤害来源，你回复1点体力。
	引用：sy_dihui
]]--
sy_dihuiCard = sgs.CreateSkillCard{
    name = "sy_dihuiCard",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local players = sgs.Self:getAliveSiblings()
			local _min = 1000
			for _, t in sgs.qlist(players) do
			    _min = math.min(_min, t:getHp())
			end
			return to_select:getHp() > _min
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		local others = sgs.SPlayerList()
		for _, pe in sgs.qlist(room:getOtherPlayers(target)) do
			if pe:getHp() < target:getHp() then others:append(pe) end
		end
		local t = room:askForPlayerChosen(source, others, "sy_dihui")
	    if t then
			room:doAnimate(1, target:objectName(), t:objectName())
			room:damage(sgs.DamageStruct("sy_dihui", target, t))
		end
	end
}

sy_dihuiVS = sgs.CreateZeroCardViewAsSkill{
    name = "sy_dihui",
	view_as = function()
	    return sy_dihuiCard:clone()
	end,
	enabled_at_play = function(self, player)
	    local n = 0
		local players = player:getAliveSiblings()
		local _min = 1000
		for _, t in sgs.qlist(players) do
		    _min = math.min(_min, t:getHp())
		end
		for _, pe in sgs.qlist(players) do
			if pe:getHp() > _min then n = n + 1 end
		end
	    return n >= 1 and (not player:hasUsed("#sy_dihuiCard"))
	end
}

sy_dihui = sgs.CreateTriggerSkill{
	name = "sy_dihui",
	view_as_skill = sy_dihuiVS,
	events = {sgs.DamageDone},
	priority = 10,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.reason == self:objectName() and damage.from  and damage.damage > 0 then
			for _, cfr in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.from:objectName() ~= cfr:objectName() then
					if cfr:isWounded() then
						local rec = sgs.RecoverStruct()
						rec.recover = 1
						rec.who = cfr
						room:recover(cfr, rec, true)
					end
				end
			end
		end
	end
}


--[[
	技能名：乱嗣
	相关武将：神蔡夫人
	技能描述：出牌阶段限一次，你可以令两名有手牌的角色拼点：当一名角色没赢后，你弃置其两张牌。若拼点赢的角色不是你，你摸两张牌。
	引用：sy_luansi
]]--
sy_luansiCard = sgs.CreateSkillCard{
    name = "sy_luansiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    if to_select:isKongcheng() then return false end
		if #targets == 0 then
		    return true
		elseif #targets == 1 then
		    return not to_select:isKongcheng()
		elseif #targets == 2 then
		    return false
		end
	end,
	feasible = function(self, targets)
		return #targets == 2 and (not targets[1]:isKongcheng()) and (not targets[2]:isKongcheng()) and targets[1]:canPindian(targets[2]) and targets[2]:canPindian(targets[1])
	end,
	on_use = function(self, room, source, targets)
		local win = targets[1]:pindian(targets[2], "sy_luansi", nil)
		if win then end
	end
}

sy_luansiVS = sgs.CreateZeroCardViewAsSkill{
    name = "sy_luansi",
	enabled_at_play = function(self, player)
	    return not player:hasUsed("#sy_luansiCard")
	end,
	view_as = function()
	    return sy_luansiCard:clone()
	end
}

sy_luansi = sgs.CreateTriggerSkill{
	name = "sy_luansi",
	view_as_skill = sy_luansiVS,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local losers = sgs.SPlayerList()
			local winner, loser = nil, nil
			if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				winner = pindian.from
				loser = pindian.to
				losers:append(pindian.to)
			elseif pindian.from_card:getNumber() < pindian.to_card:getNumber() then
				winner = pindian.to
				loser = pindian.from
				losers:append(pindian.from)
			elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() then
				losers:append(pindian.from)
				losers:append(pindian.to)
			end
			for _, cfr in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				for _, l in sgs.qlist(losers) do
					if not l:isNude() then
						local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
						jink:deleteLater()
						for i = 1, math.max(1, l:getCards("he"):length()) do
							if l:isNude() then break end
							local c = room:askForCardChosen(cfr, l, "he", "sy_luansi", false, sgs.Card_MethodDiscard, jink:getSubcards())
							jink:addSubcard(c)
						end
						room:throwCard(jink, l, cfr)
					end
				end
				if winner == nil then
					cfr:drawCards(2, self:objectName())
				else
					if cfr:objectName() ~= winner:objectName() then
						cfr:drawCards(2, self:objectName())
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：祸心
	相关武将：神蔡夫人
	技能描述：锁定技，当你即将受到伤害时，伤害来源选择一项：①令你获得其区域里各一张牌；②防止此伤害，其失去1点体力。
	引用：sy_huoxin
]]--
sy_huoxin = sgs.CreateTriggerSkill{
    name = "sy_huoxin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
		    if damage.from:isAllNude() then
			    room:loseHp(damage.from, 1, true, player, self:objectName())
				return true
			else
			    local choices = {"obtain_onebyone", "lose_hp"}
				local choice = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"))
				if choice == "obtain_onebyone" then
				    local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
					local flags = {}
					if damage.from:getCards("h"):length() > 0 then table.insert(flags, "h") end
					if damage.from:getCards("e"):length() > 0 then table.insert(flags, "e") end
					if damage.from:getCards("j"):length() > 0 then table.insert(flags, "j") end
					for i = 1, #flags, 1 do
						local id = room:askForCardChosen(player, damage.from, flags[i], self:objectName(), false, sgs.Card_MethodNone, dummy:getSubcards(), false)
						dummy:addSubcard(id)
						if id < 0 then break end
					end
					if dummy:subcardsLength() > 0 then room:obtainCard(player, dummy, false) end
				else
				    room:loseHp(damage.from, 1, true, player, self:objectName())
					return true
				end
			end
		end
	end,
	priority = -3
}


sy_caifuren1:addSkill(sy_dihui)
sy_caifuren2:addSkill("sy_dihui")
sy_caifuren2:addSkill(sy_luansi)
sy_caifuren2:addSkill(sy_huoxin)


sgs.LoadTranslationTable{	
	["sy_caifuren2"] = "神蔡夫人",
	["#sy_caifuren2"] = "蛇蝎美人",
	["sy_caifuren1"] = "神蔡夫人",
	["#sy_caifuren1"] = "蛇蝎美人",
	["~sy_caifuren2"] = "做鬼也不会放过你的！",
	["sy_dihui"] = "诋毁",
	["$sy_dihui1"] = "夫君，此人留不得！",
	["$sy_dihui2"] = "养虎为患，须尽早除之！",
	["$sy_luansi1"] = "教你见识一下我的手段！",
	["$sy_luansi2"] = "求饶？呵呵……晚了！",
	[":sy_dihui"] = "出牌阶段限一次，你可以令一名角色对另一名体力较少的角色造成1点伤害。若你不是伤害来源，你回复1点体力。",
	["dihuiothers-choose"] = "请选择因“诋毁”受到伤害的另一名其他角色。",
	["sy_luansi"] = "乱嗣",
	[":sy_luansi"] = "出牌阶段限一次，你可以令两名有手牌的角色拼点：当一名角色没赢后，你弃置其两张牌。若拼点赢的角色不是你，你摸两张牌。",
	["sy_huoxin"] = "祸心",
	["$sy_huoxin"] = "别敬酒不吃吃罚酒！",
	[":sy_huoxin"] = "锁定技，当你即将受到伤害时，伤害来源选择一项：①令你获得其区域里各一张牌；②失去1点体力，然后防止此伤害。",
	["obtain_equip"] = "该角色获得你每个区域各一张牌",
	["lose_hp"] = "防止此伤害，然后失去一点体力",
}


--神司马懿
sy_simayi1 = sgs.General(extension, "sy_simayi1", "sy_god", 7, true)
sy_simayi2 = sgs.General(extension, "sy_simayi2", "sy_god", 4, true, true)
sy_simayi1:addSkill("#sy_hp")
sy_simayi1:addSkill("#sy_bianshen")
sy_simayi1:addSkill("#W_recast")
sy_simayi1:addSkill("#sy_2ndturnstart")
sy_simayi2:addSkill("#W_recast")


--[[
	技能名：博略
	相关武将：神司马懿
	技能描述：锁定技，回合开始前，你随机获得你一个你拥有的魏/蜀/吴势力的技能，直至下个回合开始。
	引用：sy_bolue
]]--
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

function getTableIndex(table, item)
	local k = 0
	for i = 1, #table, 1 do
		if table[i] == item then
			k = i
			break
		end
	end
	return k
end

sy_bolue = sgs.CreateTriggerSkill{
	name = "sy_bolue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.TurnStart},
	priority = 10,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			local bolue_kingdoms = player:property("bolue_kingdom_rec"):toString():split("+")  --存放“忍忌”记录的伤害来源势力
			local bolue_data = player:property("bolue_data_rec"):toString():split("+")  --存放“忍忌”记录的伤害来源势力的伤害次数
			if #bolue_kingdoms == 0 or #bolue_data == 0 then
				room:setPlayerProperty(player, "bolue_kingdom_rec", sgs.QVariant("wei+shu+wu"))
				room:setPlayerProperty(player, "bolue_data_rec", sgs.QVariant("1+1+1"))
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then
				local bolue_kingdoms = player:property("bolue_kingdom_rec"):toString():split("+")
				local bolue_data = player:property("bolue_data_rec"):toString():split("+")
				if #bolue_kingdoms == 0 or #bolue_data == 0 then
					room:setPlayerProperty(player, "bolue_kingdom_rec", sgs.QVariant("wei+shu+wu"))
					room:setPlayerProperty(player, "bolue_data_rec", sgs.QVariant("1+1+1"))
				end
			end
		elseif event == sgs.TurnStart then
			local bolue_sks = player:getTag("bolue_gained"):toString():split("+")
			room:handleAcquireDetachSkills(player, "-"..table.concat(bolue_sks, "|-"))
			player:removeTag("bolue_gained")
			room:getThread():delay(1000)
			local bolue_kingdoms = player:property("bolue_kingdom_rec"):toString():split("+")  
			local bolue_data = player:property("bolue_data_rec"):toString():split("+")
			if #bolue_kingdoms == 0 or #bolue_data == 0 then
				bolue_kingdoms = {"wei", "shu", "wu"}
				bolue_data = {"1", "1", "1"}
				room:setPlayerProperty(player, "bolue_kingdom_rec", sgs.QVariant(table.concat(bolue_kingdoms, "+")))
				room:setPlayerProperty(player, "bolue_data_rec", sgs.QVariant(table.concat(bolue_data, "+")))
			end
			local bolue_skills = {}
			for i = 1, #bolue_kingdoms, 1 do
				local kingdom_skills = getOneKingdomSkills(bolue_kingdoms[i], tonumber(bolue_data[i]))
				if #kingdom_skills > 0 then
					for _, _skill in ipairs(kingdom_skills) do
						table.insert(bolue_skills, _skill)
					end
				end
			end
			if #bolue_skills > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:handleAcquireDetachSkills(player, table.concat(bolue_skills, "|"))
				player:setTag("bolue_gained", sgs.QVariant(table.concat(bolue_skills, "+")))
			end
		end
	end
}


--[[
	技能名：忍忌
	相关武将：神司马懿
	技能描述：当你受到伤害后，你可以摸一张牌，则你发动“博略”时额外随机获得一个你拥有的与来源势力相同的技能。
	引用：sy_renji
]]--
sy_renji = sgs.CreateTriggerSkill{
    name = "sy_renji",
	events = {sgs.Damaged},
	frequency = sgs.Skill_NotFrequent,
	priority = -2,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if player:askForSkillInvoke(self:objectName(), data) then    --是否发动忍忌
			if damage.from then room:doAnimate(1, player:objectName(), damage.from:objectName()) end
			room:notifySkillInvoked(player, "sy_renji")
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
			player:drawCards(1, self:objectName())
			local kingdom_str = nil
			if damage.from then
				if damage.from:getGeneral():getKingdom() == "god" then
					kingdom_str = "god"
				else
					kingdom_str = damage.from:getKingdom()
				end
			end
			if kingdom_str == nil then return false end
			local bolue_kingdoms = player:property("bolue_kingdom_rec"):toString():split("+")
			local bolue_data = player:property("bolue_data_rec"):toString():split("+")
			if not table.contains(bolue_kingdoms, kingdom_str) then
				table.insert(bolue_kingdoms, kingdom_str)
				table.insert(bolue_data, getTableIndex(bolue_kingdoms, kingdom_str), "1")
				local msg1 = sgs.LogMessage()
				msg1.type = "#RenjiRecNew"
				msg1.from = player
				msg1.arg = kingdom_str
				msg1.arg2 = "1"
				room:sendLog(msg1)
			else
				local index = getTableIndex(bolue_kingdoms, kingdom_str)
				local value = tonumber(bolue_data[index])
				bolue_data[index] = tostring(value + 1)
				local msg2 = sgs.LogMessage()
				msg2.type = "#RenjiRec"
				msg2.from = player
				msg2.arg = kingdom_str
				msg2.arg2 = tostring(value + 1)
				room:sendLog(msg2)
			end
			room:setPlayerProperty(player, "bolue_kingdom_rec", sgs.QVariant(table.concat(bolue_kingdoms, "+")))
			room:setPlayerProperty(player, "bolue_data_rec", sgs.QVariant(table.concat(bolue_data, "+")))
		end
	end
}



--[[
	技能名：变天
	相关武将：神司马懿
	技能描述：锁定技，其他角色的判定阶段，须进行一次额外的【闪电】判定。
	引用：sy_biantian
]]--
sy_biantian = sgs.CreateTriggerSkill{
    name = "sy_biantian",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		if player:getPhase() == sgs.Player_Judge and (not player:isSkipped(sgs.Player_Judge)) then
			for _, simayi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if simayi:objectName() ~= player:objectName() then
					room:doAnimate(1, simayi:objectName(), player:objectName())
					room:notifySkillInvoked(simayi, "sy_biantian")
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(simayi, self:objectName())
					local lightning = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0)
					local effect = sgs.CardEffectStruct()
					effect.from = nil
					effect.to = player
					effect.card = lightning
					lightning:onEffect(effect)
				end
			end
		end
	end,
	can_trigger = function(self, target)
	    return target and target:isAlive()
	end
}


--[[
	技能名：天佑
	相关武将：神司马懿
	技能描述：锁定技，回合结束阶段，若没有角色受到过【闪电】伤害，你回复1点体力，否则你摸X张牌（X为全场所有角色受到的【闪电】伤害次数）。
	引用：sy_tianyou
]]--
sy_tianyou = sgs.CreateTriggerSkill{
    name = "sy_tianyou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local n = Nil2Int(room:getTag("BT_lightning_count"):toInt())
			if n == 0 then
				if player:isWounded() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local recover = sgs.RecoverStruct()
					recover.recover = 1
					room:recover(player, recover, true)
				end
			elseif n > 0 then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#TianyouDraw"
				msg.arg = self:objectName()
				msg.arg2 = tostring(n)
				room:sendLog(msg)
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(n, self:objectName())
			end
		end
	end,
	priority = 1
}


sy_simayi1:addSkill(sy_bolue)
sy_simayi2:addSkill("sy_bolue")
sy_simayi2:addSkill(sy_renji)
sy_simayi2:addSkill(sy_biantian)
sy_simayi2:addSkill(sy_tianyou)


sgs.LoadTranslationTable{		
	["sy_simayi2"] = "神司马懿",
	["~sy_simayi2"] = "呃哦……呃啊……",
	["sy_simayi1"] = "神司马懿",
	["#sy_simayi1"] = "三分归晋",
	["#sy_simayi2"] = "三分归晋",
	["sy_bolue"] = "博略",
	["$sy_bolue1"] = "老夫，想到一些有趣之事。",
	["$sy_bolue2"] = "无用之物，老夫毫无兴趣。",
	["$sy_bolue3"] = "杀人伎俩，偶尔一用无妨。",
	["$sy_bolue4"] = "此种事态，老夫早有准备。",
	[":sy_bolue"] = "锁定技，回合开始前，你随机获得你一个你拥有的魏/蜀/吴势力的技能，直至下个回合开始。",
	["sy_renji"] = "忍忌",
	["$sy_renji1"] = "老夫也不得不认真起来了。",
	["$sy_renji2"] = "你们，是要置老夫于死地吗？",
	["$sy_renji3"] = "休要聒噪，吵得老夫头疼！",
	[":sy_renji"] = "当你受到伤害后，你可以摸一张牌，则你发动“博略”时额外随机获得一个你拥有的与来源势力相同的技能。",
	["#RenjiRecNew"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["#RenjiRec"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["sy_biantian"] = "变天",
	["$sy_biantian"] = "雷起！喝！",
	[":sy_biantian"] = "锁定技，其他角色的判定阶段，你令其进行【闪电】判定。",
	["sy_tianyou"] = "天佑",
	["$sy_tianyou"] = "好好看着吧！",
	["#TianyouDraw"] = "%from 的“%arg”被触发，本局游戏中【<font color=\"gold\"><b>闪电</b></font>】已一共造成了 %arg2 次伤害，将摸 %arg2 张牌",
	["you"] = "佑",
	[":sy_tianyou"] = "锁定技，回合结束阶段，若没有角色受到过【闪电】伤害，你回复1点体力，否则你摸X张牌（X为全场所有角色受到的【闪电】伤害次数）。"
}


--神袁绍
sy_yuanshao1 = sgs.General(extension, "sy_yuanshao1", "sy_god", 8, true)
sy_yuanshao2 = sgs.General(extension, "sy_yuanshao2", "sy_god", 4, true, true)
sy_yuanshao1:addSkill("#sy_hp")
sy_yuanshao1:addSkill("#sy_bianshen")
sy_yuanshao1:addSkill("#W_recast")
sy_yuanshao1:addSkill("#sy_2ndturnstart")
sy_yuanshao2:addSkill("#W_recast")


--[[
	技能名：魔箭
	相关武将：神袁绍
	技能描述：锁定技，准备阶段，你视为使用【万箭齐发】，若有角色打出【闪】响应此牌，回合结束阶段，你视为使用【万箭齐发】。
	引用：sy_mojian
]]--
sy_mojian = sgs.CreateTriggerSkill{
	name = "sy_mojian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardResponded},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if not player:hasSkill(self:objectName()) then return false end
			if player:getPhase() == sgs.Player_Start or (player:getPhase() == sgs.Player_Finish and player:getMark("&mojian_jink") > 0) then
				if player:getPhase() == sgs.Player_Finish then room:setPlayerMark(player, "&mojian_jink", 0) end
				local aa = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
				aa:setSkillName(self:objectName())
				aa:deleteLater()
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local use = sgs.CardUseStruct()
				use.card = aa
				use.from = player
				use.to = room:getOtherPlayers(player)
				room:useCard(use)
			end
		elseif event == sgs.CardResponded then
			if data:toCardResponse().m_toCard and data:toCardResponse().m_toCard:getSkillName() == "sy_mojian" then
				for _, yuanshao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if yuanshao:getMark("&mojian_jink") == 0 and yuanshao:getPhase() ~= sgs.Player_Finish then
					room:addPlayerMark(yuanshao, "&mojian_jink")
				end
			end
			end
		end
		return false
	end
}

--[[
	技能名：主宰
	相关武将：神袁绍
	技能描述：锁定技，你受到锦囊牌造成的伤害-1，以你为来源的锦囊牌造成的伤害+1。
	引用：sy_zhuzai
]]--
sy_zhuzai = sgs.CreateTriggerSkill{
	name = "sy_zhuzai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local _buff = 0
		local _debuff = 0
		if damage.card and damage.card:isKindOf("TrickCard") then
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.damage > 0 then
				_buff = _buff + 1
			end
			if damage.to and damage.to:hasSkill(self:objectName()) and damage.damage > 0 then
				_debuff = _debuff + 1
			end
		end
		if _buff > 0 or _debuff > 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if _debuff > 0 and damage.damage + _buff - _debuff == 0 then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
			room:broadcastSkillInvoke(self:objectName(), 2)
			damage.damage = damage.damage + _buff - _debuff
			data:setValue(damage)
		end
	end
}



--[[
	技能名：夺冀
	相关武将：神袁绍
	技能描述：锁定技，当你杀死其他角色时，若其有手牌，你获得其所有手牌和武将技能。
	引用：sy_duoji
]]--
sy_duoji = sgs.CreateTriggerSkill{
	name = "sy_duoji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		local victim = death.who
		if victim:getSeat() ~= player:getSeat() then
			if death.damage.from and death.damage.from:getSeat() == player:getSeat() then
				if (not victim:isKongcheng()) then
					local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
					for _, _card in sgs.qlist(victim:getCards("h")) do
						jink:addSubcard(_card)
					end
					if jink:subcardsLength() > 0 then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
						room:obtainCard(player, jink, reason, false)
					end
				jink:deleteLater()
				end
				local skill_list = {}
				for _, sk in sgs.qlist(victim:getVisibleSkillList()) do
					table.insert(skill_list, sk:objectName())
				end
				if #skill_list > 0 then
					room:handleAcquireDetachSkills(victim, "-"..table.concat(skill_list, "|-"))
					room:handleAcquireDetachSkills(player, table.concat(skill_list, "|"))
				end
			end
		end
	end
}


sy_yuanshao1:addSkill(sy_mojian)
sy_yuanshao2:addSkill("sy_mojian")
sy_yuanshao2:addSkill(sy_zhuzai)
sy_yuanshao2:addSkill(sy_duoji)


sgs.LoadTranslationTable{		
	["sy_yuanshao2"] = "神袁绍",
	["~sy_yuanshao2"] = "我不甘心！我不甘心啊！",
	["sy_yuanshao1"] = "神袁绍",
	["#sy_yuanshao1"] = "魔君",
	["#sy_yuanshao2"] = "魔君",
	["sy_mojian"] = "魔箭",
	["$sy_mojian1"] = "血肉之躯，怎可挡我万箭穿心！",
	["$sy_mojian2"] = "全都去死，去死吧！",
	["mojian_jink"] = "魔箭被闪响应",
	[":sy_mojian"] = "锁定技，准备阶段，你视为使用【万箭齐发】，若有角色打出【闪】响应此牌，回合结束阶段，你视为使用【万箭齐发】。",
	["sy_zhuzai"] = "主宰",
	["$sy_zhuzai1"] = "天命在我，尔等凡人还不跪拜！",
	["$sy_zhuzai2"] = "四世三公，名动天下！",
	[":sy_zhuzai"] = "锁定技，你受到锦囊牌造成的伤害-1，以你为来源的锦囊牌造成的伤害+1。",
	["sy_duoji"] = "夺冀",
	["$sy_duoji1"] = "冀州已得，这天下迟早是我的！",
	["$sy_duoji2"] = "属于我的东西，不如趁早双手奉上！",
	[":sy_duoji"] = "锁定技，当你杀死其他角色时，你获得其所有手牌和武将技能。",
}


--绝望者
jwz = sgs.General(extension, "jwz", "sy_god", 5, true, true, true)


--确定一个名为XX的人
function findTarget(name_str)
	local target = nil
	local room = sgs.Sanguosha:currentRoom()
	for _, t in sgs.qlist(room:getPlayers()) do
		if string.find(t:getGeneralName(), name_str) or (t:getGeneral2() and string.find(t:getGeneral2Name(), name_str)) then
			target = t
			break
		end
	end
	return target
end


--[[
	技能名：黑羊
	相关武将：绝望者
	技能描述：锁定技，你成为【杀】的目标时，初音未来摸1张牌。当你使用【无懈可击】时，初音未来对你造成1点随机属性的伤害。
	引用：jw_heiyang
]]--
jw_heiyang = sgs.CreateTriggerSkill{
    name = "jw_heiyang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local miku = findTarget("sy_miku")
		if not miku then return false end
		if miku:isDead() then return false end
		if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from then
				for _, t in sgs.qlist(use.to) do
				    if t:hasSkill(self:objectName()) then
						room:sendCompulsoryTriggerLog(t, self:objectName())
						room:notifySkillInvoked(t, self:objectName())
						miku:drawCards(1)
					end
				end
			end
		elseif event == sgs.CardUsed then
		    for _, p in sgs.qlist(room:getAlivePlayers()) do
		        if (p:getGeneral() and (string.find(p:getGeneralName(), "_miku"))) or (p:getGeneral2() and (string.find(p:getGeneral2Name(), "_miku"))) then
			        miku = p
				    break
			    end
		    end
		    if not miku then return false end
		    if miku:isDead() then return false end
		    local use = data:toCardUse()
			if use.card:isKindOf("Nullification") and use.from:hasSkill(self:objectName()) then
			    room:sendCompulsoryTriggerLog(use.from, self:objectName())
				room:notifySkillInvoked(use.from, self:objectName())
				room:doAnimate(1, miku:objectName(), use.from:objectName())
				local a = math.random(1, 3)
				if a == 1 then room:damage(sgs.DamageStruct(self:objectName(), miku, use.from, 1, sgs.DamageStruct_Normal))
				elseif a == 2 then room:damage(sgs.DamageStruct(self:objectName(), miku, use.from, 1, sgs.DamageStruct_Fire))
				elseif a == 3 then room:damage(sgs.DamageStruct(self:objectName(), miku, use.from, 1, sgs.DamageStruct_Thunder)) end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
	    return target
	end
}


jwz:addSkill(jw_heiyang)


--[[
	技能名：神嘲
	相关武将：绝望者
	技能描述：锁定技，你对其他角色使用的【杀】有39%的概率无效。
	引用：jw_shenchao
]]--
jw_shenchao = sgs.CreateTriggerSkill{
    name = "jw_shenchao",
	events = {sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local effect = data:toSlashEffect()
		if effect.from:hasSkill(self:objectName()) then
		    if math.random(1, 100) <= 39 then
			    local msg = sgs.LogMessage()
				msg.from = effect.from
				msg.to:append(effect.to)
				msg.card_str = effect.slash:toString()
				msg.arg = self:objectName()
				msg.type = "#shenchaoslash"
				room:sendLog(msg)
				room:notifySkillInvoked(effect.from, self:objectName())
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
	    return target
	end
}


jwz:addSkill(jw_shenchao)


--[[
	技能名：软弱
	相关武将：绝望者
	技能描述：锁定技，你受到伤害时，该伤害有39%的概率+1。你对初音未来造成伤害时，该伤害有39%的概率-1。
	引用：jw_ruanruo
]]--
jw_ruanruo = sgs.CreateTriggerSkill{
    name = "jw_ruanruo",
	priority = 10,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
	    local damage = data:toDamage()
		if damage.to and damage.to:hasSkill(self:objectName()) then
		    if math.random(1, 100) <= 39 then
			    room:sendCompulsoryTriggerLog(damage.to, self:objectName())
				room:notifySkillInvoked(damage.to, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		    if (p:getGeneral() and (string.find(p:getGeneralName(), "_miku"))) or (p:getGeneral2() and (string.find(p:getGeneral2Name(), "_miku"))) then
			    miku = p
				break
			end
		end
		if not miku then return false end
		if miku:isDead() then return false end
		if damage.to:objectName() == miku:objectName() and damage.from:hasSkill(self:objectName()) then
		    if math.random(1, 100) >= 40 then return false end
			if damage.damage <= 1 then
			    room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				room:notifySkillInvoked(damage.from, self:objectName())
				return true
			else
			    room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				room:notifySkillInvoked(damage.from, self:objectName())
				damage.damage = damage.damage - 1
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, target)
	    return true
	end
}


jwz:addSkill(jw_ruanruo)


--[[
	技能名：声浪
	相关武将：绝望者
	技能描述：锁定技，每当你受到属性伤害时，初音未来回复1点体力。
	引用：jw_shenglang
]]--
jw_shenglang = sgs.CreateTriggerSkill{
    name = "jw_shenglang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local miku = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		    if (p:getGeneral() and (string.find(p:getGeneralName(), "_miku"))) or (p:getGeneral2() and (string.find(p:getGeneral2Name(), "_miku"))) then
			    miku = p
				break
			end
		end
		if not miku or miku:isDead() then return false end
		if damage.to:hasSkill(self:objectName()) and damage.nature ~= sgs.DamageStruct_Normal then
		    if not miku:isWounded() then return false end
		    room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:doAnimate(1, miku:objectName(), damage.to:objectName())
			local re = sgs.RecoverStruct()
			re.who = miku
		    room:recover(miku, re, true)
		end
	end,
	can_trigger = function(self, target)
	    return true
	end
}


jwz:addSkill(jw_shenglang)


--[[
	技能名：纯白
	相关武将：绝望者
	技能描述：锁定技，若初音未来没有【布教】，则视为初音未来可对你发动【布教】。
	引用：jw_chunbai
]]--
jw_chunbai = sgs.CreateTriggerSkill{
    name = "jw_chunbai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local miku = false
		for _, p in sgs.qlist(room:getAllPlayers()) do
		    if (p:getGeneral() and (string.find(p:getGeneralName(), "sy_miku"))) or (p:getGeneral2() and (string.find(p:getGeneral2Name(), "sy_miku"))) then
			    miku = p
				break
			end
		end
		if not miku or miku:isDead() then return false end
		if miku:hasSkill("sy_bujiao") then return false end
		if player:getHandcardNum() > 0 and player:getPhase() == sgs.Player_Play and player:objectName() ~= miku:objectName() then
		    room:broadcastSkillInvoke("sy_bujiao")
			room:notifySkillInvoked(player, self:objectName())
		    room:sendCompulsoryTriggerLog(player, self:objectName())
			local _data = sgs.QVariant()
			_data:setValue(miku)
			room:doAnimate(1, miku:objectName(), player:objectName())
			local card = room:askForCard(player, ".!", "@bujiao:" .. miku:objectName(), _data, sgs.Card_MethodNone)
			room:obtainCard(miku, card, false)
			player:drawCards(1)
		end
	end
}


jwz:addSkill(jw_chunbai)


--[[
	技能名：残梦
	相关武将：绝望者
	技能描述：锁定技，若初音未来已受伤或死亡，则当你回复体力时，有39%的概率无法回复。
	引用：jw_canmeng
]]--
jw_canmeng = sgs.CreateTriggerSkill{
	name = "jw_canmeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpRecover},
	on_trigger = function(self, event, player, data, room)
		local miku = findTarget("sy_miku")
		if not miku then return false end
		if miku:isWounded() or miku:isDead() then
			local n = math.random(1, 100)
			if n >= 1 and n <= 39 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				return true
			end
		end
	end
}


jwz:addSkill(jw_canmeng)


sgs.LoadTranslationTable{
    ["jwz"] = "绝望者",
	["jw_heiyang"] = "黑羊",
	[":jw_heiyang"] = "锁定技，你成为【杀】的目标时，<font color = \"#39C5BB\">初音未来</font>摸1张牌。当你使用【无懈可击】时，"..
	"<font color = \"#39C5BB\">初音未来</font>对你造成1点随机属性的伤害。",
	["jw_chunbai"] = "纯白",
	[":jw_chunbai"] = "锁定技，若<font color = \"#39C5BB\">初音未来</font>没有【布教】，则视为<font color = \"#33FFCC\">初音未来</font>"..
	"可对你发动【（旧）布教】。",
	["jw_shenchao"] = "神嘲",
	["#shenchaoslash"] = "%from 的“%arg”被触发，%from 对 %to 使用的 %card 无效",
	[":jw_shenchao"] = "锁定技，你对其他角色使用的【杀】有39%的概率无效。",
	["jw_ruanruo"] = "软弱",
	[":jw_ruanruo"] = "锁定技，你受伤害时，该伤害有39%的概率+1。你对<font color = \"#39C5BB\">初音未来</font>造成伤害时，该伤害有39%的概率-1。",
	["jw_shenglang"] = "声浪",
	[":jw_shenglang"] = "锁定技，每当你受到属性伤害时，<font color = \"#39C5BB\">初音未来</font>回复1点体力。",
	["jw_canmeng"] = "残梦",
	[":jw_canmeng"] = "锁定技，若<font color = \"#39C5BB\">初音未来</font>已受伤或死亡，则当你回复体力时，有39%的概率无法回复。",
}


--初音未来
sy_miku1 = sgs.General(extension, "sy_miku1", "sy_god", 7, false)
sy_miku2 = sgs.General(extension, "sy_miku2", "sy_god", 4, false, true)
sy_miku1:addSkill("#sy_hp")
sy_miku1:addSkill("#sy_bianshen")
sy_miku1:addSkill("#W_recast")
sy_miku1:addSkill("#sy_2ndturnstart")
sy_miku2:addSkill("#W_recast")


--统计目标有几个【绝望者】技能
function countJuewangSkills(target)
	local n = 0
	if target:hasSkill("jw_chunbai") then n = n + 1 end
	if target:hasSkill("jw_heiyang") then n = n + 1 end
	if target:hasSkill("jw_shenchao") then n = n + 1 end
	if target:hasSkill("jw_shenglang") then n = n + 1 end
	if target:hasSkill("jw_ruanruo") then n = n + 1 end
	if target:hasSkill("jw_canmeng") then n = n + 1 end
	return n
end


--失去一定数量的【绝望者】技能
function detachNJuewangSkills(room, target, n)
	local jw_list = {}
	local detach_list = {}
	for _, skill in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(skill:objectName(), "jw_") then
			table.insert(jw_list, skill:objectName())
		end
	end
	local x = #jw_list
	for i = 1, math.min(n, x) do
		local y = math.random(1, #jw_list)
		table.insert(detach_list, "-" .. jw_list[y])
		table.remove(jw_list, y)
		if #jw_list == 0 then break end
	end
	room:handleAcquireDetachSkills(target, table.concat(detach_list, "|"))
	jw_list = {}
	detach_list = {}
end

--获得一定数量的【绝望者】技能
function acquireNJuewangSkills(room, target, n)
	local jw_list = {"jw_chunbai", "jw_heiyang", "jw_ruanruo", "jw_shenglang", "jw_shenchao", "jw_canmeng"}
	local acquire_list = {}
	for _, skill in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(skill:objectName(), "jw_") then
			table.removeOne(jw_list, skill:objectName())
		end
	end
	local x = #jw_list
	for i = 1, math.min(n, x) do
		local y = math.random(1, #jw_list)
		table.insert(acquire_list, jw_list[y])
		table.remove(jw_list, y)
		if #jw_list == 0 then break end
	end
	room:handleAcquireDetachSkills(target, table.concat(acquire_list, "|"))
	jw_list = {}
	acquire_list = {}
end

--随机属性
function randomNatrue()
	local nature
	local x = math.random(1, 3)
	if x == 1 then
		nature = sgs.DamageStruct_Normal
	elseif x == 2 then
		nature = sgs.DamageStruct_Fire
	elseif x == 3 then
		nature = sgs.DamageStruct_Thunder
	end
	return nature
end

--发送消息（没有to）
function sendRoomMsg(room, msgtype, msgfrom, msgarg, msgarg2)
	local msg = sgs.LogMessage()
	msg.from = msgfrom
	msg.type = msgtype
	msg.arg = msgarg
	msg.arg2 = msgarg2
	room:sendLog(msg)
end


--[[
	初音未来专属特殊规则：场上任一武将的【绝望者】技能数至多为3。如果超过，则失去多余的【绝望者】技能。
	引用：#arrangejw_skills
]]--
jw_lists = {"jw_chunbai", "jw_heiyang", "jw_ruanruo", "jw_shenglang", "jw_shenchao", "jw_canmeng"}
arrangejw_skills = sgs.CreateTriggerSkill{
	name = "#arrangejw_skills",
	global = true,
	priority = 10,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		local skill = data:toString()
		if table.contains(jw_lists, skill) then
			if countJuewangSkills(player) > 3 then
				local x = countJuewangSkills(player)
				detachNJuewangSkills(room, player, x-3)
			end
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#arrangejw_skills") then skills:append(arrangejw_skills) end
sgs.Sanguosha:addSkills(skills)


sy_miku1:addSkill("#arrangejw_skills")
sy_miku2:addSkill("#arrangejw_skills")


--[[
	技能名：终章
	相关武将：初音未来（三英）
	技能描述：出牌阶段限一次，你可令一名其他角色摸一张牌并随机获得一个【绝望者】技能。若其手牌数大于你，则其弃置两张牌。当你受到伤害时，你也可如此做。
	◆目标至多只能有3个【绝望者】技能，若超过3个，则目标失去多余的【绝望者】技能。
	引用：sy_zhongzhang
]]--
sy_zhongzhangCard = sgs.CreateSkillCard{
    name = "sy_zhongzhang",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
        if #targets == 0 then
		    return to_select:getSeat() ~= sgs.Self:getSeat()
		end
		return false
	end,
	feasible = function(self, targets)
	    return #targets == 1
	end,
	on_use = function(self, room, source, targets)
	    local target = targets[1]
		target:drawCards(1, self:objectName())
		acquireNJuewangSkills(room, target, 1)
		if target:getHandcardNum() > source:getHandcardNum() then room:askForDiscard(target, self:objectName(), 2, 2, false, true) end
	end
}

sy_zhongzhangVS = sgs.CreateZeroCardViewAsSkill{
	name = "sy_zhongzhang",
	view_as = function()
		return sy_zhongzhangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#sy_zhongzhang"))
	end
}

sy_zhongzhang = sgs.CreateTriggerSkill{
	name = "sy_zhongzhang",
	view_as_skill = sy_zhongzhangVS,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.damage <= 0 then return false end
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@zhongzhang-target", true, true)
		if target then
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			target:drawCards(1, self:objectName())
			acquireNJuewangSkills(room, target, 1)
			if target:getHandcardNum() > player:getHandcardNum() then room:askForDiscard(target, self:objectName(), 2, 2, false, true) end
		end
	end
}


sy_miku1:addSkill(sy_zhongzhang)
sy_miku2:addSkill("sy_zhongzhang")


--[[
	技能名：终曲
	相关武将：初音未来（三英）
	技能描述：锁定技，回合结束阶段，若有3个【绝望者】技能的角色数不小于你的体力值，你对这些角色造成1点雷电伤害，且这些角色失去所有【绝望者】技能。
	引用：sy_zhongqu
]]--
sy_zhongqu = sgs.CreateTriggerSkill{
	name = "sy_zhongqu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local x = 0
			local targets = sgs.SPlayerList()
			for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
				if countJuewangSkills(pe) >= 3 then
					x = x + 1
					targets:append(pe)
				end
			end
			if x >= player:getHp() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				for _, t in sgs.qlist(targets) do
					room:doAnimate(1, player:objectName(), t:objectName())
				end
				for _, t in sgs.qlist(targets) do
					room:damage(sgs.DamageStruct(self:objectName(), player, t, 1, sgs.DamageStruct_Thunder))
				end
				for _, t in sgs.qlist(targets) do
					detachNJuewangSkills(room, t, 3)
				end
			end
		end
	end
}


sy_miku2:addSkill(sy_zhongqu)


--[[
	技能名：天愿
	相关武将：初音未来（三英）
	技能描述：锁定技，摸牌阶段，若你的体力值小于3，每少1点体力便多摸一张牌。
	引用：sy_tianyuan
]]--
sy_tianyuan = sgs.CreateTriggerSkill{
	name = "sy_tianyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local tianyuan = player:getHp() <= 2
		if tianyuan then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			draw.num = draw.num + 3 - player:getHp()
			data:setValue(draw)
		end
	end
}


--[[
	技能名：悲愿
	相关武将：初音未来（三英）
	技能描述：当你受到伤害时，你可令伤害来源随机获得一个【绝望者】技能，然后观看牌堆顶的3张牌，以任意顺序置于牌堆顶或牌堆底并摸一张牌。
	引用：sy_beiyuan
]]--
sy_beiyuan = sgs.CreateTriggerSkill{
	name = "sy_beiyuan",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	priority = 6,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not player:isAlive() then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		room:broadcastSkillInvoke(self:objectName())
		if damage.from then
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			acquireNJuewangSkills(room, damage.from, 1)
		end
		local cards = room:getNCards(3, true)
		room:askForGuanxing(player, cards)
		player:drawCards(1, self:objectName())
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sy_tianyuan") then skills:append(sy_tianyuan) end
if not sgs.Sanguosha:getSkill("sy_beiyuan") then skills:append(sy_beiyuan) end
sgs.Sanguosha:addSkills(skills)


--[[
	技能名：消失
	相关武将：初音未来（三英）
	技能描述：限定技，当你进入濒死状态时，你可将体力值回复至1点，然后进行一次判定并获得判定牌，令所有其他角色选择一项：交给你一张与此牌花色相同的牌，或令你回
	复1点体力。此后你获得【天愿】与【悲愿】并失去此技能。
	引用：sy_xiaoshi
]]--
sy_xiaoshi = sgs.CreateTriggerSkill{
    name = "sy_xiaoshi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xiaoshi",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		local dying = data:toDying()
		local victim = dying.who
		if victim:objectName() == player:objectName() then
			if player:getHp() > 0 then return false end
		    if player:askForSkillInvoke(self:objectName(), data) then
			    player:loseMark("@xiaoshi")
				room:broadcastSkillInvoke(self:objectName())
				local re = sgs.RecoverStruct()
				re.who = player
				re.recover = 1 - player:getHp()
				room:recover(player, re, true)
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.reason = self:objectName()
				judge.play_animation = false
				room:judge(judge)
				local suitstring = judge.card:getSuitString()
				local pattern
				local suit = judge.card:getSuit()
				if suit == sgs.Card_Spade then
				    pattern = ".S"
				elseif suit == sgs.Card_Heart then
				    pattern = ".H"
				elseif suit == sgs.Card_Club then
				    pattern = ".C"
				elseif suit == sgs.Card_Diamond then
				    pattern = ".D"
				end
				player:obtainCard(judge.card)
				local _miku = sgs.QVariant()
				_miku:setValue(player)
				local prompt = string.format("@xiaoshiask:%s:%s", player:objectName(), judge.card:getSuitString())
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:doAnimate(1, player:objectName(), p:objectName())
				    local c = room:askForCard(p, pattern, prompt, _miku, sgs.Card_MethodNone)
					if c then
					    room:obtainCard(player, c, true)
					else
					    local re = sgs.RecoverStruct()
				        re.who = p
				        room:recover(player, re, true)
					end
				end
				if not player:hasSkill("sy_tianyuan") then room:acquireSkill(player, "sy_tianyuan") end
				if not player:hasSkill("sy_beiyuan") then room:acquireSkill(player, "sy_beiyuan") end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:getMark("@xiaoshi") > 0
	end
}


sy_miku2:addSkill(sy_xiaoshi)
sy_miku2:addRelateSkill("sy_tianyuan")
sy_miku2:addRelateSkill("sy_beiyuan")


sgs.LoadTranslationTable{
    ["sy_miku1"] = "初音未来",
	["designer:sy_miku1"] = "司马子元",
	["illustrator:sy_miku1"] = "夕薙(id=29041654)",
	["cv:sy_miku1"] = "藤田咲",
	["#sy_miku1"] = "终焉歌姬",
	["sy_miku2"] = "初音未来",
	["#sy_miku2"] = "最后之音",
	["~sy_miku2"] = "……歌いたい……ま、まだ……歌いたい……",
	["sy_zhongzhang"] = "终章",
	["$sy_zhongzhang1"] = "今は歌さえも",
	["$sy_zhongzhang2"] = "体蝕む行為に",
	["$sy_zhongzhang3"] = "奇跡願うたび",
	["$sy_zhongzhang4"] = "独り追い詰められる",
	[":sy_zhongzhang"] = "出牌阶段限一次，你可令一名其他角色摸一张牌并随机获得一个【绝望者】技能。若其手牌数大于你，则其弃置两张牌。当你受到伤害时，你也可如此做。"..
	"\n<font color=\"#FF33CC\">◆目标至多只能有3个【绝望者】技能，若超过3个，则目标失去多余的【绝望者】技能。</font>",
	["@zhongzhang-target"] = "你可以发动“终章”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["sy_zhongqu"] = "终曲",
	[":sy_zhongqu"] = "锁定技，回合结束阶段，若有3个【绝望者】技能的角色数不小于你的体力值，你对这些角色造成1点雷电伤害，且这些角色失去所有【绝望者】技能。",
	["sy_xiaoshi"] = "消失",
	["@xiaoshi"] = "消失",
	[":sy_xiaoshi"] = "<font color = \"red\"><b>限定技，</b></font>当你进入濒死状态时，你可将体力值回复至1点，然后进行一次判定并获得判定牌，令所有其他角色选择"..
	"一项：交给你一张与此牌花色相同的牌，或令你回复1点体力。此后你获得【天愿】与【悲愿】并失去此技能。",
	["@xiaoshiask"] = "<font color=\"#39C5BB\">[初音ミクの消失]</font>请交给%src一张%dest牌，否则你令%src回复1点体力。",
	["sy_tianyuan"] = "天愿",
	[":sy_tianyuan"] = "<font color = \"blue\"><b>锁定技，</b></font>摸牌阶段，若你的体力值小于3，每少1点体力便多摸一张牌。",
	["sy_beiyuan"] = "悲愿",
	[":sy_beiyuan"] = "当你受到伤害时，你可令伤害来源随机获得一个【绝望者】技能，然后观看牌堆顶的3张牌，以任意顺序置于牌堆顶或牌堆底并摸一张牌。",
}


--神司马师
sy_simashi1 = sgs.General(extension, "sy_simashi1", "sy_god", 8, true)
sy_simashi2 = sgs.General(extension, "sy_simashi2", "sy_god", 4, true, true)
sy_simashi1:addSkill("#sy_hp")
sy_simashi1:addSkill("#sy_bianshen")
sy_simashi1:addSkill("#W_recast")
sy_simashi1:addSkill("#sy_2ndturnstart")
sy_simashi2:addSkill("#W_recast")


--[[
	技能名：纠虔
	相关武将：神司马师（三英）
	技能描述：锁定技，当你使用或受到【杀】造成的伤害时，你依次执行一项：与其他角色的距离-1；攻击范围+1；准备阶段，你摸1张牌；废除判定区并获得【制衡】。
	引用：sy_jiuqian
]]--
sy_jiuqian = sgs.CreateTriggerSkill{
	name = "sy_jiuqian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.Damaged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:getMark("jiuqian_mark") < 4 then
				room:addPlayerMark(player, "jiuqian_mark")
				room:broadcastSkillInvoke(self:objectName(), player:getMark("jiuqian_mark"))
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = self:objectName()
				msg.type = "#jiuqian_slash" .. tostring(player:getMark("jiuqian_mark"))
				room:sendLog(msg)
				if player:getMark("jiuqian_mark") >= 4 then
					player:throwJudgeArea()
					room:acquireSkill(player, "sy_zhiheng")
				end
			end
		else
			if player:getPhase() == sgs.Player_Start and player:getMark("jiuqian_mark") >= 3 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
				player:drawCards(1, self:objectName())
			end
		end
		return false 
	end
}

sy_simashi1:addSkill(sy_jiuqian)
sy_simashi2:addSkill("sy_jiuqian")
function isOddInteger(int)  --某量为奇数
	return math.ceil(int/2) - math.floor(int/2) == 1
end
function isEvenInteger(int)  --某量为偶数
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

--[[
	技能名：坚城
	相关武将：神司马师（三英）
	技能描述：准备阶段，若你没有“坚城”，你可将牌堆顶的牌作为“坚城”置于武将牌上。你的武将牌上有“坚城”时：①当你成为【杀】、【决斗】、【火攻】的目标时，你令来源
	判定，若其不弃置一张与之花色相同的牌，此牌对你无效；②其他角色计算与你的距离+1；③当你即将受到属性伤害时，移去“坚城”并防止此伤害。
	引用：sy_jiancheng
]]--
sy_jiancheng = sgs.CreateTriggerSkill{
	name = "sy_jiancheng",
	events = {sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPile("jiancheng"):isEmpty() and player:getPhase() == sgs.Player_Start and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local ids = room:getNCards(1, true)
			    local id = ids:first()
			    local card = sgs.Sanguosha:getCard(id)
				player:addToPile("jiancheng", card)
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:getSeat() ~= player:getSeat() and use.to:contains(player) and (not player:getPile("jiancheng"):isEmpty()) then
				if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel") or use.card:isKindOf("FireAttack")) then
					room:doAnimate(1, player:objectName(), use.from:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:sendCompulsoryTriggerLog(player, self:objectName())
					local judge = sgs.JudgeStruct()
					judge.reason = self:objectName()
					judge.who = use.from
					judge.play_animation = false
					room:judge(judge)
					local pmt = string.format("@jiancheng-discard:%s:%s", player:objectName(), judge.card:getSuitString())
					local c = room:askForCard(use.from, ".|"..judge.card:getSuitString(), pmt, ToData(player), sgs.Card_MethodNone)
					if c then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), self:objectName(), "")
						room:throwCard(c, reason, nil)
					else
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				if not player:getPile("jiancheng"):isEmpty() then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local jiancheng = player:getPile("jiancheng")
					local idx = jiancheng:first()
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "sy_jiancheng","")
					local card = sgs.Sanguosha:getCard(idx)
					room:throwCard(card, reason, nil)
				end
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
		return false
	end
}


sy_simashi2:addSkill(sy_jiancheng)


--[[
	技能名：峻平
	相关武将：神司马师（三英）
	技能描述：锁定技，任一角色的判定牌生效后，若此牌的花色与“坚城”相同，你摸1张牌。
	引用：sy_junping
]]--
sy_junping = sgs.CreateTriggerSkill{
	name = "sy_junping",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data, room)
		if not room:findPlayerBySkillName("sy_junping") then return false end
		local s = room:findPlayerBySkillName("sy_junping")
		if s:getPile("jiancheng"):isEmpty() then return false end
		local id = s:getPile("jiancheng"):first()
		local acard = sgs.Sanguosha:getCard(id)
		local judge = data:toJudge()
		local card = judge.card
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and judge.card:getSuit() == acard:getSuit() then
			room:notifySkillInvoked(s, "sy_junping")
			room:broadcastSkillInvoke("sy_junping")
			s:drawCards(1, self:objectName())
		end
	end,
	can_trigger = function(self, target)
	    return true
	end
}


sy_simashi2:addSkill(sy_junping)


sgs.LoadTranslationTable{
	["sy_simashi1"] = "神司马师",
	["#sy_simashi1"] = "西晋之元",
	["sy_simashi2"] = "神司马师",
	["#sy_simashi2"] = "西晋之元",
	["~sy_simashi2"] = "私に、天命は、ないのか……",
	["sy_jiuqian"] = "纠虔",
	[":sy_jiuqian"] = "锁定技，当你使用或受到【杀】造成的伤害时，你依次执行一项：与其他角色的距离-1；攻击范围+1；准备阶段，你摸1张牌；废除判定区并获得【制衡】。",
	["$sy_jiuqian1"] = "奇袭敌军本营，了结此战！",
	["$sy_jiuqian2"] = "加强对文钦的包围，勒紧凡愚的咽喉。",
	["$sy_jiuqian3"] = "接下来，不会就此了结的。",
	["$sy_jiuqian4"] = "呃……都走到这一步了……",
	["#jiuqian_slash1"] = "%from 的“%arg”被触发，%from 计算与其他角色的距离时始终-1",
	["#jiuqian_slash2"] = "%from 的“%arg”被触发，%from 的攻击范围+1",
	["#jiuqian_slash3"] = "%from 的“%arg”被触发，%from 此后的准备阶段都将摸1张牌",
	["#jiuqian_slash4"] = "%from 的“%arg”被触发，%from 的判定区将被废除",
	["sy_jiancheng"] = "坚城",
	["jiancheng"] = "坚城",
	[":sy_jiancheng"] = "准备阶段，若你没有“坚城”，你可将牌堆顶的牌作为“坚城”置于武将牌上。你的武将牌上有“坚城”时：①当你成为【杀】、【决斗】、【火攻】的目标时"..
	"，你令来源判定，若其不弃置一张与之花色相同的牌，此牌对你无效；②其他角色计算与你的距离+1；③当你即将受到属性伤害时，移去“坚城”并防止此伤害。",
	["@jiancheng-discard"] = "请弃置一张%src牌，否则此牌对%dst无效",
	["$sy_jiancheng1"] = "你的抵抗会造成什么后果，你自己最好想清楚。",
	["$sy_jiancheng2"] = "仅凭如此，奈何不了我分毫。",
	["sy_junping"] = "峻平",
	[":sy_junping"] = "锁定技，任一角色的判定牌生效后，若此牌的花色与“坚城”相同，你摸1张牌。",
	["$sy_junping"] = "吾之天命，绝不可被人阻挠！",
}


--神徐盛
sy_xusheng1 = sgs.General(extension, "sy_xusheng1", "sy_god", 8, true)
sy_xusheng2 = sgs.General(extension, "sy_xusheng2", "sy_god", 4, true, true)
sy_xusheng1:addSkill("#sy_hp")
sy_xusheng1:addSkill("#sy_bianshen")
sy_xusheng1:addSkill("#W_recast")
sy_xusheng1:addSkill("#sy_2ndturnstart")
sy_xusheng2:addSkill("#W_recast")


--[[
	技能名：宝刀
	相关武将：神徐盛（三英）
	技能描述：锁定技，你的攻击范围+2，你使用的【杀】对手牌数不大于1的角色造成的伤害+1。
	引用：sy_baodao
]]--
sy_baodao = sgs.CreateTriggerSkill{
	name = "sy_baodao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local to = damage.to
		if damage.card and damage.card:isKindOf("Slash") and to and to:isAlive() then
			if to:isKongcheng() and player:getWeapon() == nil then
				room:doAnimate(1, player:objectName(), to:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end
}


sy_xusheng1:addSkill(sy_baodao)
sy_xusheng2:addSkill("sy_baodao")


--[[
	技能名：破军
	相关武将：神徐盛（三英）
	技能描述：锁定技，当你使用【杀】指定目标后，你须将目标的X张牌扣置于其武将牌旁（X为其体力上限），若如此做，当前回合结束后，目标获得这些牌。当你使用【杀】
	对手牌数与装备数均不大于你的角色造成伤害时，此伤害+1。
	引用：sy_pojun
]]--
sy_pojun = sgs.CreateTriggerSkill{
	name = "sy_pojun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				for _, t in sgs.qlist(use.to) do
					local n = math.min(t:getCards("he"):length(), t:getMaxHp())
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), t:objectName())
					local orig_places = sgs.PlaceList()
					local cards = sgs.IntList()
					t:setFlags("sy_pojun_InTempMoving")
					for i = 1, n do
						local id = room:askForCardChosen(player, t, "he", self:objectName(), false, sgs.Card_MethodNone)
						local place = room:getCardPlace(id)
						orig_places:append(place)
						cards:append(id)
						t:addToPile("#sy_pojun", id, false)
					end
					for i = 0, n-1, 1 do
						room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), t, orig_places:at(i), false)
					end
					t:setFlags("-sy_pojun_InTempMoving")
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(cards)
					dummy:deleteLater()
					local tt = sgs.SPlayerList()
					tt:append(t)
					t:addToPile("sy_pojun_cards", dummy, false, tt)
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local to = damage.to
			if damage.card and damage.card:isKindOf("Slash") and to and to:isAlive() then
				if to:getHandcardNum() > player:getHandcardNum() or to:getEquips():length() > player:getEquips():length() then return false end
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:doAnimate(1, player:objectName(), to:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end
}


sy_xusheng1:addSkill(sy_pojun)
sy_xusheng2:addSkill("sy_pojun")


--[[
	技能名：鬼刃
	相关武将：神徐盛（三英）
	技能描述：出牌阶段开始时，你可亮出牌堆顶的3张牌并弃置（若不足3张则先洗牌），则你于本阶段首次使用【杀】时，所有体力值不大于X（X为这些牌中的最大点数，且若
	其中有【杀】或武器牌，则X=99）的其他角色也成为此【杀】的目标。
	引用：sy_guiren
]]--
sy_guiren = sgs.CreateTriggerSkill{
	name = "sy_guiren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if room:getAlivePlayers():length() <= 2 then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:askForSkillInvoke(self:objectName(), data) then
				if room:getDrawPile():length()< 3 then room:swapPile() end
				local cards = room:getDrawPile()
				local pts = 0
				local guiren = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for i = 1, 3 do
					local cardsid = cards:at(0)
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(cardsid)
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local c = sgs.Sanguosha:getCard(cardsid)
					if c:isKindOf("Slash") or c:isKindOf("Weapon") then
						pts = math.max(pts, 99)
					else
						pts = math.max(pts, c:getNumber())
					end
					guiren:addSubcard(cardsid)
					if cards:length() == 0 then room:swapPile() end
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
				room:throwCard(guiren, reason, nil)
				guiren:deleteLater()
				room:addPlayerMark(player, "&guiren_ex", pts)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:getSeat() == player:getSeat() and use.card and use.card:isKindOf("Slash") then
				if player:getMark("&guiren_ex") > 0 then
					for _, pe in sgs.qlist(room:getOtherPlayers(player)) do
						if not use.to:contains(pe) and pe:getHp() <= player:getMark("&guiren_ex") and (not room:isProhibited(player, pe, use.card)) then
							use.to:append(pe)
							room:doAnimate(1, player:objectName(), pe:objectName())
						end
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
					room:setPlayerMark(player, "&guiren_ex", 0)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then room:setPlayerMark(player, "&guiren_ex", 0) end
		end
		return false
	end
}


sy_xusheng2:addSkill(sy_guiren)


function RandomSelectFromTable(i_table, select_num)
	local k = math.min(#i_table, select_num)
	local output_table = {}
	for i = 1, k do
		local j = math.random(1, #i_table)
		table.insert(output_table, i_table[j])
		table.removeOne(i_table, i_table[j])
		if #i_table == 0 then break end
	end
	return output_table
end


--[[
	技能名：阴兵
	相关武将：神徐盛（三英）
	技能描述：准备阶段开始时，你可从牌堆中随机获得一张【酒】和属性杀，然后从『阴兵点将录』中随机获得3个技能直至你下个回合准备阶段开始。
	『阴兵点将录』中包含的技能：劫营、铁骑、无双、骄恣、杀绝、裸衣、奋音、自书
	引用：sy_yinbing
]]--
sy_yinbing = sgs.CreateTriggerSkill{
	name = "sy_yinbing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			local evil_skills = player:getTag("death_sk"):toString():split("+")
			room:handleAcquireDetachSkills(player, "-"..table.concat(evil_skills, "|-"))
			player:removeTag("death_sk")
			if player:askForSkillInvoke(self:objectName(), data) then
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				local ana = sgs.QList2Table(getOnePatternIds("Analeptic"))
				local slashes = sgs.QList2Table(getOnePatternIds("NatureSlash"))
				local j1 = math.random(1, #ana)
				local card1 = sgs.Sanguosha:getCard(ana[j1])
				jink:addSubcard(card1)
				local j2 = math.random(1, #slashes)
				local card2 = sgs.Sanguosha:getCard(slashes[j2])
				jink:addSubcard(card2)
				room:obtainCard(player, jink, false)
				jink:deleteLater()
				local evil = {"jieyingg", "tieji", "wushuang", "jiaozi", "sgkgodshajue", "luoyi", "fenyin", "zishu"}
				for _, name in ipairs(evil) do
					if hasSameNameSkill(player, name) then table.removeOne(evil, name) end
				end
				if #evil > 0 then
					local death_skills = RandomSelectFromTable(evil, 3)
					player:setTag("death_sk", sgs.QVariant(table.concat(death_skills, "+")))
					room:handleAcquireDetachSkills(player, table.concat(death_skills, "|"))
				end
			end
		end
	end
}


sy_xusheng2:addSkill(sy_yinbing)


sgs.LoadTranslationTable{
	["sy_xusheng1"] = "神徐盛",
	["#sy_xusheng1"] = "阎罗王",
	["sy_xusheng2"] = "神徐盛",
	["#sy_xusheng2"] = "阎罗王",
	["~sy_xusheng2"] = "盛只恨……不能再为主公……破敌制胜了……",
	["sy_baodao"] = "宝刀",
	[":sy_baodao"] = "锁定技，当你没装备武器时，你的攻击范围+2，你使用的【杀】对没有手牌的角色造成的伤害+1。",
	["sy_pojun"] = "破军",
	["sy_pojun_cards"] = "破军",
	[":sy_pojun"] = "锁定技，当你使用【杀】指定目标后，你须将目标的X张牌扣置于其武将牌旁（X为其体力上限），若如此做，当前回合结束后，目标获得这些牌。当你使"..
	"用【杀】对手牌数与装备数均不大于你的角色造成伤害时，此伤害+1。",
	["$sy_pojun1"] = "犯大吴疆土者，盛必击而破之！",
	["$sy_pojun2"] = "若敢来犯，必叫你大败而归！",
	["sy_guiren"] = "鬼刃",
	["guiren_ex"] = "鬼刃",
	[":sy_guiren"] = "出牌阶段开始时，你可亮出牌堆顶的3张牌并弃置（若不足3张则先洗牌），则你于本阶段首次使用【杀】时，所有体力值不大于X（X为这些牌中的最大"..
	"点数，且若其中有【杀】或武器牌，则X=99）的其他角色也成为此【杀】的目标。",
	["sy_yinbing"] = "阴兵",
	[":sy_yinbing"] = "准备阶段开始时，你可从牌堆中随机获得一张【酒】和属性杀，然后从<font color = \"#FF4500\"><b>『阴兵点将录』<b></font>中随机获得3个"..
	"技能直至你下个回合准备阶段开始。\
	<font color = \"#FF4500\"><b>『阴兵点将录』<b></font>中包含的技能：劫营、铁骑、无双、骄恣、杀绝、裸衣、奋音、自书",
}


--黑化间桐樱
sy_sakura1 = sgs.General(extension, "sy_sakura1", "sy_god", 7, false)
sy_sakura2 = sgs.General(extension, "sy_sakura2", "sy_god", 4, false, true)


--虚数：锁定技，对你造成的伤害和你造成的伤害视为体力流失。准备阶段开始时，你需令一名其他角色流失一点体力。
sy_xushu = sgs.CreateTriggerSkill{
    name = "sy_xushu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local sakura = room:findPlayerBySkillName(self:objectName())
		if event == sgs.DamageInflicted then
		    local damage = data:toDamage()
			local n = damage.damage
			if (damage.from and damage.from:objectName() == sakura:objectName()) or (damage.to:objectName() == sakura:objectName()) then
			    room:sendCompulsoryTriggerLog(sakura, self:objectName())
				room:notifySkillInvoked(sakura, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(damage.to, n, true, sakura, self:objectName())
				return true
			end
		elseif event == sgs.EventPhaseStart then
		    if sakura:getPhase() == sgs.Player_Start then
			    local target = room:askForPlayerChosen(sakura, room:getOtherPlayers(sakura), self:objectName())
				if target then
				    room:sendCompulsoryTriggerLog(sakura, self:objectName())
				    room:notifySkillInvoked(sakura, self:objectName())
				    room:broadcastSkillInvoke(self:objectName())
					room:loseHp(target, 1, true, sakura, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function()
	    return true
	end
}


sy_sakura1:addSkill(sy_xushu)
sy_sakura2:addSkill(sy_xushu)


--吸收：一名其他角色进入濒死时，你可以获得其一个技能并回复一点体力。
sy_xishou = sgs.CreateTriggerSkill{
    name = "sy_xishou",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local dying = data:toDying()
		local victim = dying.who
		if victim:objectName() == player:objectName() then return false end
		local xishou_skills = {}
		local my_skills = {}
		for _, _mysk in sgs.qlist(player:getVisibleSkillList()) do
		    table.insert(my_skills, _mysk:objectName())
		end
		if #my_skills > 0 then
		    for _, _skill in sgs.qlist(victim:getVisibleSkillList()) do
		        if not table.contains(my_skills, _skill:objectName()) then table.insert(xishou_skills, _skill:objectName()) end
		    end
		end
		my_skills = {}
		if #xishou_skills == 0 then
		    if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			if player:isWounded() then
		        local re = sgs.RecoverStruct()
		        re.who = player
	            re.recover = 1
	            room:recover(player, re)
			end
		else
		    if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
		    local skill = room:askForChoice(player, self:objectName(), table.concat(xishou_skills, "+"))
		    room:acquireSkill(player, skill)
		    if player:isWounded() then
		        local re = sgs.RecoverStruct()
		        re.who = player
	            re.recover = 1
	            room:recover(player, re)
			end
		end
		return false
	end
}


sy_sakura1:addSkill(sy_xishou)
sy_sakura2:addSkill(sy_xishou)


--圣杯：锁定技，回合开始前，弃置你判定区内的所有牌，若你背面朝上，将你的武将牌翻面。你的摸牌数+3，你的手牌上限+3。
sy_shengbei = sgs.CreateTriggerSkill{
    name = "sy_shengbei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart, sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
	    if event == sgs.TurnStart then
		    if not player:getJudgingArea():isEmpty() then
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:notifySkillInvoked(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
			    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			    dummy:addSubcards(player:getJudgingArea())
			    room:throwCard(dummy, player)
				dummy:deleteLater()
			end
			if not player:faceUp() then player:turnOver() end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num + 3
			data:setValue(draw)
		end
		return false
	end
}

sy_shengbeiMax = sgs.CreateMaxCardsSkill{
    name = "#sy_shengbei",
	extra_func = function(self, target)
	    if target:hasSkill("sy_shengbei") then
		    return 3
		else
		    return 0
		end
	end
}


extension:insertRelatedSkills("sy_shengbei", "#sy_shengbei")
sy_sakura2:addSkill(sy_shengbei)
sy_sakura2:addSkill(sy_shengbeiMax)


--操影：其他角色指定你为目标时，获得一个“影”标记。一名角色流失体力时，你可以弃置其“影”标记，然后弃置其相同数量的牌。
sy_caoying = sgs.CreateTriggerSkill{
    name = "sy_caoying",
	events = {sgs.TargetConfirming, sgs.HpLost},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.TargetConfirming then
		    local use = data:toCardUse()
			if use.from and player:hasSkill(self:objectName()) and use.from:objectName() ~= player:objectName() and use.to and use.to:contains(player) then
			    room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				use.from:gainMark("@kage")
			end
		elseif event == sgs.HpLost then
			for _,sakura in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:objectName() ~= sakura:objectName() and player:getMark("@kage") > 0 then
					if player:isNude() then return false end
					room:setPlayerMark(player, "caoying_AI", 1)
					if sakura:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerFlag(player, "sy_caoying_InTempMoving")
						local n = player:getMark("@kage")
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
						local card_ids = sgs.IntList()
						local original_places = sgs.IntList()
						player:loseAllMarks("@kage")
						for i = 0, n-1, 1 do
							if not sakura:canDiscard(player, "he") then break end
							local c = room:askForCardChosen(sakura, player, "he", self:objectName())
							card_ids:append(c)
							original_places:append(room:getCardPlace(card_ids:at(i)))
							dummy:addSubcard(card_ids:at(i))
							player:addToPile("#caoying", card_ids:at(i), false)
						end
						for i = 0, dummy:subcardsLength() - 1, 1 do
							room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), player, original_places:at(i), false)
						end
						room:setPlayerFlag(player, "-sy_caoying_InTempMoving")
						if dummy:subcardsLength() > 0 then
							room:throwCard(dummy, player, sakura)
						end
						dummy:deleteLater()
						n = player:getMark("@kage")
					end
					room:setPlayerMark(player, "caoying_AI", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}

sy_caoyingFakeMove = sgs.CreateTriggerSkill{
    name = "#sy_caoying",
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	priority = 10,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
		    if p:hasFlag("sy_caoying_InTempMoving") then return true end
		end
		return false
	end,
	can_trigger = function()
	    return true
	end
}


extension:insertRelatedSkills("sy_caoying", "#sy_caoying")


sy_sakura2:addSkill(sy_caoying)
sy_sakura2:addSkill(sy_caoyingFakeMove)


--黑·约束胜利之剑：当你失去体力时，你可以对一名其他角色造成X点伤害，X为你和其装备区牌的差，然后弃置其所有的装备牌。
sy_shengjian_black = sgs.CreateTriggerSkill{
    name = "sy_shengjian_black",
	events = {sgs.HpLost},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
		if target then
		    room:broadcastSkillInvoke(self:objectName())
		    local x = math.abs(player:getEquips():length()-target:getEquips():length())
			room:damage(sgs.DamageStruct(self:objectName(), player, target, x))
			if not target:getEquips():isEmpty() then target:throwAllEquips() end
		end
	end
}


sy_sakura2:addSkill(sy_shengjian_black)

sy_sakura1:addSkill("#sy_hp")
sy_sakura1:addSkill("#sy_bianshen")
sy_sakura1:addSkill("#W_recast")
sy_sakura1:addSkill("#sy_2ndturnstart")
sy_sakura2:addSkill("#W_recast")



sgs.LoadTranslationTable{
	["sy_xushu"] = "虚数",
	["$sy_xushu1"] = "（咒语）",
	["$sy_xushu2"] = "太碍眼了！",
	["$sy_xushu3"] = "哈哈..哈哈..哈哈哈哈哈。",
	["$sy_xushu4"] = "能够给你的，只有后悔和绝望。",
	[":sy_xushu"] = "<font color=\"blue\"><b>锁定技。</b></font>对你造成的伤害和你造成的伤害视为体力流失。准备阶段开始时，你需令一名其他角色流失一点体力。",
	["sy_xishou"] = "吸收",
	["$sy_xishou1"] = "和我一起溶解吧。",
	["$sy_xishou2"] = "死吧，呵呵呵呵呵。",
	["$sy_xishou3"] = "安心吧，大家都会死的。",
	[":sy_xishou"] = "一名其他角色进入濒死时，你可以获得其一个技能并回复一点体力。",
	["sy_shengbei"] = "圣杯",
	["$sy_shengbei"] = "不会停下的，妨碍我的话就毁掉你。",
	[":sy_shengbei"] = "<font color=\"blue\"><b>锁定技。</b></font>回合开始前，弃置你判定区内的所有牌，若你背面朝上，将你的武将牌翻面。你的摸牌数+3，你的手牌上限+3。",
	["@kage"] = "影",
	["sy_caoying"] = "操影",
	["$sy_caoying1"] = "如果非要妨碍我的话就抹杀你。",
	["$sy_caoying2"] = "消失吧！",
	["$sy_caoying3"] = "明明就，明明就因为你我才......",
	["$sy_caoying4"] = "那么，来玩玩吧。",
	[":sy_caoying"] = "其他角色指定你为目标时，获得一个“影”标记。一名角色流失体力时，你可以弃置其“影”标记，然后弃置其相同数量的牌。",
	["sy_shengjian_black"] = "黑·约束胜利之剑",
	["$sy_shengjian_black1"] = "好吧，我就陪你玩玩。",
	["$sy_shengjian_black2"] = "消失吧！",
	["$sy_shengjian_black3"] = "同吾之极光一同消逝吧！Excalibur！！",
	["$sy_shengjian_black4"] = "被吾之剑光吞噬吧，Excalibur！！！",
	[":sy_shengjian_black"] = "当你失去体力时，你可以对一名其他角色造成X点伤害，X为你和其装备区牌的差，然后弃置其所有的装备牌。",
	["sy_sakura1"] = "黑化间桐樱", 
	["#sy_sakura1"] = "间桐家的御主", 
	["designer:sy_sakura1"] = "Sword Elucidator",
	["cv:sy_sakura1"] = "下屋则子",
	["illustrator:sy_sakura1"] = "月本葵",
	["sy_sakura2"] = "黑化间桐樱", 
	["#sy_sakura2"] = "间桐家的圣杯", 
	["~sy_sakura2"] = "哎，学长...我...到底做了什么...", 
	["designer:sy_sakura2"] = "Sword Elucidator",
	["cv:sy_sakura2"] = "下屋则子",
	["illustrator:sy_sakura2"] = "皇♦小J",
}


--神亚索
sy_yasuo1 = sgs.General(extension, "sy_yasuo1", "sy_god", 8, true)
sy_yasuo2 = sgs.General(extension, "sy_yasuo2", "sy_god", 4, true, true)


--风斩：准备阶段，你可进行一次判定，并根据判定结果视为对一名其他角色使用：红桃-火杀；黑桃-雷杀；其他-普通杀（若无可杀的目标，你获得此判定牌）。
sy_fengzhan = sgs.CreateTriggerSkill{
    name = "sy_fengzhan",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = self:objectName()
		judge.play_animation = false
		room:judge(judge)
		local slash
		local suit = judge.card:getSuit()
		if suit == sgs.Card_Heart then
		    slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		elseif suit == sgs.Card_Spade then
		    slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
		elseif suit == sgs.Card_Diamond or suit == sgs.Card_Club then
		    slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		end
		slash:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _, t in sgs.qlist(room:getOtherPlayers(player)) do
		    if not sgs.Sanguosha:isProhibited(player, t, slash) then targets:append(t) end
		end
		if targets:isEmpty() then
		    player:obtainCard(judge.card)
			slash:deleteLater()
		end
		local to = room:askForPlayerChosen(player, targets, self:objectName())
		if to then
		    local card_use = sgs.CardUseStruct()
			card_use.from = player
			card_use.card = slash
			card_use.to:append(to)
			room:useCard(card_use, false)
		else
		    return false
		end
		slash:deleteLater()
		targets = sgs.SPlayerList()
	end
}


sy_yasuo1:addSkill(sy_fengzhan)


--暴风：锁定技，你使用【杀】或此技能造成伤害时目标获得1个“暴风”标记，且获得第3个“暴风”标记时被击飞（若此时该角色武将牌正面朝上，则翻面）。准备阶段，你可弃置一
--张杀，然后对至多3名其他角色各造成1点伤害。
sy_baofengCard = sgs.CreateSkillCard{
    name = "sy_baofengCard",
	filter = function(self, targets, to_select)
	    return to_select:objectName() ~= sgs.Self:objectName() and #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= 3
	end,
	on_use = function(self, room, source, targets)
		for i = 1, #targets, 1 do
		    room:damage(sgs.DamageStruct("sy_baofeng", source, targets[i]))
			targets[i]:gainMark("@fiercewind", 1)
		end
	end
}

sy_baofengVS = sgs.CreateViewAsSkill{
    name = "sy_baofeng",
	n = 1,
	response_pattern = "@@sy_baofeng",
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
		    local card = sy_baofengCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName("sy_baofeng")
			return card
		end
	end
}

sy_baofeng = sgs.CreateTriggerSkill{
    name = "sy_baofeng",
	view_as_skill = sy_baofengVS,
	events = {sgs.DamageCaused, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.DamageCaused then
		    local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.to:objectName() ~= player:objectName() and damage.card and (damage.card:isKindOf("Slash") or damage.reason == "sy_baofeng") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				damage.to:gainMark("@fiercewind", 1)
				if damage.to:getMark("@fiercewind") >= 3 then
					if damage.to:faceUp() then damage.to:turnOver() end
				end
			end
		elseif event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Finish then
			    for _, t in sgs.qlist(room:getOtherPlayers(player)) do
			        if (not t:faceUp()) and t:getMark("@fiercewind") >= 3 then t:loseAllMarks("@fiercewind") end
				end
			end
			if player:getPhase() == sgs.Player_Start then
			    room:askForUseCard(player, "@@sy_baofeng", "@baofeng_damage")
			end
		end
		return false
	end
}


sy_yasuo2:addSkill(sy_baofeng)


--无鞘：你成为【杀】的目标或你使用【杀】对其他角色造成伤害时，你可弃置目标一张牌。锁定技，你使用的【杀】被【闪】响应时，你摸1张牌。
sy_wuqiao = sgs.CreateTriggerSkill{
    name = "sy_wuqiao",
	events = {sgs.TargetConfirmed, sgs.Damage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local can_do = false
		local to = nil
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() then
			    if not use.to:contains(player) then return false end
			    if not use.card:isKindOf("Slash") then return false end
			    if use.from:isNude() then return false end
				to = use.from
				can_do = true
			end
		elseif event == sgs.Damage then
		    local damage = data:toDamage()		
			if damage.from and damage.from:objectName() == player:objectName() and damage.card and damage.card:isKindOf("Slash") then
			    if damage.to:isNude() then return false end
				to = damage.to
				can_do = true
			end
		end
		if can_do and to ~= nil then
		    if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:broadcastSkillInvoke(self:objectName())
			room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
		end
		return false
	end
}

sy_wuqiaojink = sgs.CreateTriggerSkill{
    name = "#sy_wuqiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
			if use.card:isKindOf("Jink") and use.whocard and use.whocard:isKindOf("Slash") and use.who and use.who:hasSkill("sy_wuqiao") then
				 room:sendCompulsoryTriggerLog(use.who, self:objectName())
					room:notifySkillInvoked(use.who, self:objectName())
					use.who:drawCards(1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
	    return target
	end
}


extension:insertRelatedSkills("sy_wuqiao", "#sy_wuqiao")
sy_yasuo1:addSkill(sy_wuqiao)
sy_yasuo1:addSkill(sy_wuqiaojink)
sy_yasuo2:addSkill(sy_wuqiao)
sy_yasuo2:addSkill(sy_wuqiaojink)


--风影：你即将受到【杀】或【决斗】的伤害时，你可将牌堆顶的3张牌置入弃牌堆，若其中有【杀】或【决斗】，你摸1张牌，然后此伤害-1。锁定技，与你距离大于1的角色不能对
--你造成伤害。
sy_fengying = sgs.CreateTriggerSkill{
    name = "sy_fengying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:objectName() == player:objectName() then
		    if damage.from then
			    if damage.from:distanceTo(player) > 1 then
				    room:sendCompulsoryTriggerLog(player, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
			if not damage.card then return false end
		    if ((not damage.card:isKindOf("Slash")) and (not damage.card:isKindOf("Duel"))) then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			if room:getDrawPile():isEmpty() then room:swapPile() end
			local cards = room:getDrawPile()
			local a = 0
			local b = 0
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			room:broadcastSkillInvoke(self:objectName())
			while b < 3 do
			    local cardsid = cards:at(0)
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(cardsid)
				move.to = player
			    move.to_place = sgs.Player_PlaceTable
			    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			    room:moveCardsAtomic(move, true)
				local c = sgs.Sanguosha:getCard(cardsid)
				if c:isKindOf("Slash") or c:isKindOf("Duel") then a = a + 1 end
				dummy:addSubcard(cardsid)
				b = b + 1
				if cards:length() == 0 then room:swapPile() end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), "")
			room:moveCardTo(dummy, player, sgs.Player_DiscardPile, reason)
			dummy:deleteLater()
			if a > 0 then
			    player:drawCards(1)
			    damage.damage = damage.damage - 1
				data:setValue(damage)
				if damage.damage < 1 then return true end
			end
		end
	end
}


sy_yasuo2:addSkill(sy_fengying)


--真·狂风绝息斩：回合结束阶段，你可对所有被击飞的角色造成2+X点伤害（X为你已损失体力值的一半，向下取整），然后你将武将牌翻面。
sy_juexi = sgs.CreateTriggerSkill{
    name = "sy_juexi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
		    if (not p:faceUp()) and p:getMark("@fiercewind") > 0 then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
		    room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("death_breath$", 1500)
			for _, target in sgs.qlist(targets) do
			    room:damage(sgs.DamageStruct(self:objectName(), player, target, 2+math.floor(player:getLostHp()/2)))
			end
			player:turnOver()
		end
		for _, t in sgs.qlist(room:getAlivePlayers()) do
		    if t:getMark("@fiercewind") > 0 then t:loseAllMarks("@fiercewind") end
		end
	end
}


sy_yasuo2:addSkill(sy_juexi)

sy_yasuo1:addSkill("#sy_hp")
sy_yasuo1:addSkill("#sy_bianshen")
sy_yasuo1:addSkill("#W_recast")
sy_yasuo1:addSkill("#sy_2ndturnstart")
sy_yasuo2:addSkill("#W_recast")

sgs.LoadTranslationTable{
    ["sy_yasuo2"] = "神亚索",
	["~sy_yasuo2"] = "不是你死，就是我亡！",
	["sy_yasuo1"] = "神亚索",
	["#sy_yasuo1"] = "孤高的浪客",
	["#sy_yasuo2"] = "疾行之刃",
	["sy_fengzhan"] = "风斩",
	["$sy_fengzhan1"] = "灭亡之路，短的超乎你的想象。",
	["$sy_fengzhan2"] = "呵，汝欲赴死，易如反掌。",
	["$sy_fengzhan3"] = "速战速决。",
	["$sy_fengzhan4"] = "我会给你个痛快的。",
	[":sy_fengzhan"] = "准备阶段，你可进行一次判定，并根据判定结果视为对一名其他角色使用：红桃-火杀；黑桃-雷杀；其他-普通杀（若无可杀的目标，你获得此判定牌）。",
	["sy_wuqiao"] = "无鞘",
	["#sy_wuqiao"] = "无鞘",
	["sy_wuqiaojink"] = "无鞘",
	["$sy_wuqiao1"] = "想杀我？你可以试一试。",
	["$sy_wuqiao2"] = "回首往昔，更进一步。",
	["$sy_wuqiao3"] = "有些失误无法犯两次。",
	["$sy_wuqiao4"] = "有些事绝对不会无趣。",
	[":sy_wuqiao"] = "你成为【杀】的目标或你使用【杀】对其他角色造成伤害时，你可弃置目标一张牌。<font color = \"blue\"><b>锁定技。</b></font>你使用的【杀】被"..
	"【闪】响应时，你摸1张牌。",
	["sy_baofeng"] = "暴风",
	["@baofeng_damage"] = "暴风",
	["~sy_baofeng"] = "选择一张杀→至多3名其他角色→点击确定",
	["@fiercewind"] = "暴风",
	["$sy_baofeng1"] = "hasaki",
	["$sy_baofeng2"] = "杀人是种恶习，但我似乎戒不掉了。",
	["$sy_baofeng3"] = "死亡而已，没什么大不了的。",
	["$sy_baofeng4"] = "一剑，一念。",
	[":sy_baofeng"] = "<font color = \"blue\"><b>锁定技。</b></font>你使用【杀】或由此技能造成伤害时目标获得1个“暴风”标记，且获得第3个“暴风”标记时被击飞（若此"..
	"时该角色武将牌正面朝上，则翻面）。准备阶段，你可弃置一张杀，然后对至多3名其他角色各造成1点伤害。",
	["sy_fengying"] = "风影",
	["$sy_fengying1"] = "面对疾风吧！",
	["$sy_fengying2"] = "且随疾风前行，身后亦需留心。",
	["$sy_fengying3"] = "吾虽浪迹天涯，却未迷失本心。",
	[":sy_fengying"] = "你即将受到【杀】或【决斗】的伤害时，你可将牌堆顶的3张牌置入弃牌堆，若其中有【杀】或【决斗】，你摸1张牌，然后此伤害-1。<font color = \"blue\"><b>锁定技。</b></font>"..
	"与你距离大于1的角色不能对你造成伤害。",
	["sy_juexi"] = "真·狂风绝息斩",
	["death_breath$"] = "image=image/animate/sy_juexi.png",
	["$sy_juexi1"] = "醋裂",
	["$sy_juexi2"] = "索里耶给痛",
	["$sy_juexi3"] = "爷给洞",
	[":sy_juexi"] = "回合结束阶段，你可对所有被击飞的角色造成2+X点伤害（X为你已损失体力值的一半，向下取整），然后你将武将牌翻面。"
}



--下面两位大哥都是长坂坡的BOSS
--神赵云
sy_zhaoyun1 = sgs.General(extension, "sy_zhaoyun1", "sy_god", 8, true)
sy_zhaoyun2 = sgs.General(extension, "sy_zhaoyun2", "sy_god", 4, true, true)


function throwNRamdomCardsFromPile(odin, n, pile)
    local room = odin:getRoom()
	local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
	if pile:length() >= n then
	    for i = 1, n do
		    local k = pile:at(math.random(1,pile:length())-1)
		    local c = sgs.Sanguosha:getCard(k)
			dummy:addSubcard(c)
			pile:removeOne(k)
		end
		room:throwCard(dummy, odin)
	end
	dummy:deleteLater()
end

--特定：聚气阶段
--在回合开始阶段之后，判定阶段之前，加入一个聚气阶段。在聚气阶段，你从牌堆顶亮出一张牌置于你的武将牌上，称之为“怒”。上限为4张，若超出4张，需立即选择一张弃
--置。无论拥有多少聚气技，只能翻一张牌作为“怒”。
sy_juqi = sgs.CreateTriggerSkill{
	name = "#sy_juqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.from == sgs.Player_Start and change.to == sgs.Player_Judge then
			local thread = room:getThread()
			local id = room:getNCards(1, true)
			player:addToPile("Angers", id, true)
			thread:trigger(sgs.EventForDiy, room, player, sgs.QVariant("JuQiDiscard"))
			thread:trigger(sgs.EventForDiy, room, player, sgs.QVariant("JuQiPhase"))
		end
	end
}

sy_juqidiscard = sgs.CreateTriggerSkill{
	name = "#sy_juqidiscard",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventForDiy},
	on_trigger = function(self, event, player, data)
		if data:toString() == "JuQiDiscard" then
			local angers = player:getPile("Angers")
			if angers:length() > 4 then
				local x = angers:length()
				throwNRamdomCardsFromPile(player, x-4, angers)
			end
		end
		return false
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_juqi") then skills:append(sy_juqi) end
if not sgs.Sanguosha:getSkill("#sy_juqidiscard") then skills:append(sy_juqidiscard) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("#sy_juqi", "#sy_juqidiscard")


sy_zhaoyun1:addSkill("#sy_juqi")
sy_zhaoyun1:addSkill("#sy_juqidiscard")
sy_zhaoyun2:addSkill("#sy_juqi")
sy_zhaoyun2:addSkill("#sy_juqidiscard")


--青釭
sy_qinggang = sgs.CreateTriggerSkill{
	name = "sy_qinggang",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and damage.to:objectName() ~= player:objectName() then
			if damage.damage <= 0 then return false end
			if damage.to:isNude() then return false end
			for i = 1, damage.damage do
				if not player:askForSkillInvoke(self:objectName(), data) then break end
				if damage.to:isKongcheng() and (not damage.to:getEquips():isEmpty()) then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local equip_id = room:askForCardChosen(player, damage.to, "e", self:objectName())
					local equip = sgs.Sanguosha:getCard(equip_id)
					player:obtainCard(equip)
				elseif damage.to:getEquips():isEmpty() and (not damage.to:isKongcheng()) then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:askForDiscard(damage.to, self:objectName(), 1, 1, false, false)
				else
					room:setPlayerFlag(damage.to, "qinggang_AI")
					if not room:askForDiscard(damage.to, self:objectName(), 1, 1, true, false, "@qinggang:" .. player:objectName()) then
						room:broadcastSkillInvoke(self:objectName(), 2)
						local equip_id = room:askForCardChosen(player, damage.to, "e", self:objectName())
						local equip = sgs.Sanguosha:getCard(equip_id)
						player:obtainCard(equip)
					else
						room:broadcastSkillInvoke(self:objectName(), 1)
					end
					room:setPlayerFlag(damage.to, "-qinggang_AI")
				end
				if damage.to:isNude() then break end
			end
		end
	end
}

sy_zhaoyun1:addSkill(sy_qinggang)
sy_zhaoyun1:addSkill("longdan")
sy_zhaoyun2:addSkill(sy_qinggang)
sy_zhaoyun2:addSkill("longdan")


--龙怒
sy_longnuCard = sgs.CreateSkillCard{
	name = "sy_longnuCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "longnu_nojink", 1)
	end
}

sy_longnuVS = sgs.CreateViewAsSkill{
	name = "sy_longnu",
	n = 2,
	expand_pile = "Angers",
	view_filter = function(self, selected, to_select)
		local id = to_select:getEffectiveId()
		if sgs.Self:getPile("Angers"):contains(id) then
			if #selected == 0 then
				return true
			elseif #selected == 1 then
				return to_select:sameColorWith(selected[1])
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = sy_longnuCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("Angers"):length() >= 2
	end
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

sy_longnu = sgs.CreateTriggerSkill{
	name = "sy_longnu",
	view_as_skill = sy_longnuVS,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card then return false end
		if not use.card:isKindOf("Slash") then return false end
		local n = player:getMark("longnu_nojink")
		if n <= 0 then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local n = player:getMark("longnu_nojink")
		room:setPlayerMark(player, "longnu_nojink", n-1)
		for _, p in sgs.qlist(use.to) do
			jink_table[index] = 0
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		room:setPlayerMark(player, "longnu_nojink", n-1)
		return false
	end
}


sy_zhaoyun2:addSkill(sy_longnu)


--浴血
sy_yuxue = sgs.CreateViewAsSkill{
	name = "sy_yuxue",
	n = 1,
	expand_pile = "Angers",
	view_filter = function(self, selected, to_select)
		if #selected == 0 and to_select:isRed() then
			local id = to_select:getEffectiveId()
			if sgs.Self:getPile("Angers"):contains(id) then
				return true
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:addSubcard(card)
			peach:setSkillName(self:objectName())
			return peach
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("Global_PreventPeach") > 0 then
			return false
		elseif player:getLostHp() > 0 then
			if player:getPile("Angers"):length() > 0 then
				return true
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if string.find(pattern, "peach") then
			if player:getMark("Global_PreventPeach") > 0 then
				return false
			elseif player:getPile("Angers"):length() > 0 then
				return true
			end
		end
		return false
	end
}


sy_zhaoyun2:addSkill(sy_yuxue)


--龙吟
sy_longyin = sgs.CreateTriggerSkill{
	name = "sy_longyin",
	events = {sgs.EventForDiy},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toString() == "JuQiPhase" then
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local ids = room:getNCards(3, true)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
			room:moveCardsAtomic(move, true)
			local thread = room:getThread()
			thread:delay()
			room:fillAG(ids, player)
			local id = room:askForAG(player, ids, false, self:objectName())
			room:clearAG(player)
			ids:removeOne(id)
			player:addToPile("Angers", id, true)
			thread:trigger(sgs.EventForDiy, room, player, sgs.QVariant("JuQiDiscard"))
			local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			if ids:length() > 0 then
				for _, ic in sgs.qlist(ids) do
					dummy:addSubcard(sgs.Sanguosha:getCard(ic))
				end
				player:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		return false
	end
}


sy_zhaoyun2:addSkill(sy_longyin)

sy_zhaoyun1:addSkill("#sy_hp")
sy_zhaoyun1:addSkill("#sy_bianshen")
sy_zhaoyun1:addSkill("#W_recast")
sy_zhaoyun1:addSkill("#sy_2ndturnstart")
sy_zhaoyun2:addSkill("#W_recast")

sgs.LoadTranslationTable{
	["sy_zhaoyun1"] = "神赵云",
	["#sy_zhaoyun1"] = "长坂坡圣骑",
	["sy_zhaoyun2"] = "神赵云",
	["#sy_zhaoyun2"] = "不败神话",
	["~sy_zhaoyun2"] = "未能保幼主周全，子龙愧对主公啊……",
	["Angers"] = "怒",
	["sy_qinggang"] = "青釭",
	[":sy_qinggang"] = "你每造成1点伤害，你可以让目标选择弃掉一张手牌或者让你从其装备区获得一张牌。",
	["$sy_qinggang1"] = "青釭利刃，无坚不摧！",
	["$sy_qinggang2"] = "如此神器，汝留之有何用？",
	["@qinggang"] = "请弃置一张手牌，否则%src获得你装备区的一张牌。",
	["sy_longnu"] = "龙怒",
	[":sy_longnu"] = "<font color = \"#FF0033\"><b>聚气技，</b></font>出牌阶段，你可以弃两张相同颜色的“怒”，若如此做，你使用的下一张【杀】不可被闪避。",
	["$sy_longnu"] = "枪搅垓心蛇动荡，马冲阵势虎飞腾！",
	["sy_yuxue"] = "浴血",
	[":sy_yuxue"] = "<font color = \"#FF0033\"><b>聚气技，</b></font>你可以将你的任意红桃或方块花色的“怒”当【桃】使用。",
	["$sy_yuxue"] = "血染征袍透甲红，当阳谁敢与争锋！",
	["sy_longyin"] = "龙吟",
	["sy_longyin:JuQiPhase"] = "你想发动“龙吟”吗？",
	[":sy_longyin"] = "<font color = \"#FF0033\"><b>特定技，</b></font>聚气阶段，你可以从牌堆顶亮出三张牌，选择其中一张做为“怒”，其余收为手牌。",
	["$sy_longyin"] = "匹马单枪出重围，英风锐气敌胆寒！",
	["designer:sy_zhaoyun1"] = "洛神工作室",
	["cv:sy_zhaoyun1"] = "黄昏",
	["illustrator:sy_zhaoyun1"] = "洛神工作室",
}


--神张飞
sy_zhangfei1 = sgs.General(extension, "sy_zhangfei1", "sy_god", 10, true)
sy_zhangfei2 = sgs.General(extension, "sy_zhangfei2", "sy_god", 5, true, true)


sy_zhangfei1:addSkill("#sy_juqi")
sy_zhangfei1:addSkill("#sy_juqidiscard")
sy_zhangfei2:addSkill("#sy_juqi")
sy_zhangfei2:addSkill("#sy_juqidiscard")


--整军
sy_zhengjun = sgs.CreateTriggerSkill{
	name = "sy_zhengjun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local x = 0
			if player:getWeapon() == nil then
				x = x + 3
			else
				x = x + player:getAttackRange(true)
			end
			room:askForDiscard(player, self:objectName(), x, x, false, true)
		end
		if player:getPhase() == sgs.Player_Finish then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local x = 0
			if player:getWeapon() == nil then
				x = x + 3
			else
				x = x + player:getAttackRange(true)
			end
			player:drawCards(x+1)
			player:turnOver()
		end
	end
}


sy_zhangfei1:addSkill(sy_zhengjun)


--仗八
sy_zhangba = sgs.CreateAttackRangeSkill{
	name = "sy_zhangba",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) and target:getWeapon() == nil then
			return 2
		else
			return 0
		end
	end
}


sy_zhangfei1:addSkill(sy_zhangba)


--备粮
sy_beiliang = sgs.CreateTriggerSkill{
	name = "sy_beiliang",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHandcardNum() >= player:getHp() then return false end
		if player:getPhase() == sgs.Player_Draw then
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(player:getHp() - player:getHandcardNum())
			return true
		end
	end
}


sy_zhangfei2:addSkill(sy_beiliang)


--聚武
sy_juwuCard = sgs.CreateSkillCard{
	name = "sy_juwuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then
			if to_select:getGeneral2() then
				return string.find(to_select:getGeneralName(), "sy_zhaoyun") or string.find(to_select:getGeneral2Name(), "sy_zhaoyun")
			else
				return string.find(to_select:getGeneralName(), "sy_zhaoyun")
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		local zhaoyun = targets[1]
		room:obtainCard(zhaoyun, self, false)
		room:addPlayerMark(source, "juwu_given", self:subcardsLength())
	end
}

sy_juwuVS = sgs.CreateViewAsSkill{
	name = "sy_juwu",
	n = 1000,
	view_filter = function(self, selected, to_select)
		if #selected >= sgs.Self:getHp() then return false end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local juwu = sy_juwuCard:clone()
		for _, card in ipairs(cards) do
			juwu:addSubcard(card)
		end
		juwu:setSkillName(self:objectName())
		return juwu
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and player:getMark("juwu_given") < player:getHp()
	end
}

sy_juwu = sgs.CreateTriggerSkill{
	name = "sy_juwu",
	view_as_skill = sy_juwuVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			room:setPlayerMark(player, "juwu_given", 0)
		end
	end
}


sy_zhangfei2:addSkill(sy_juwu)


--缠蛇
sy_chanshe = sgs.CreateViewAsSkill{
	name = "sy_chanshe",
	n = 1,
	expand_pile = "Angers",
	view_filter = function(self, selected, to_select)
		if to_select:getSuit() == sgs.Card_Diamond then
			local id = to_select:getEffectiveId()
			if sgs.Self:getPile("Angers"):contains(id) then
				return true
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local indulgence = sgs.Sanguosha:cloneCard("indulgence", suit, point)
			indulgence:addSubcard(card)
			indulgence:setSkillName(self:objectName())
			return indulgence
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("Angers"):length() > 0
	end
}


sy_zhangfei2:addSkill(sy_chanshe)


--弑神
sy_shishenCard = sgs.CreateSkillCard{
	name = "sy_shishenCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() or to_select:objectName() == sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local room = source:getRoom()
		room:loseHp(target, 1, true, source, "sy_shishen")
	end
}

sy_shishen = sgs.CreateViewAsSkill{
	name = "sy_shishen",
	n = 2,
	expand_pile = "Angers",
	view_filter = function(self, selected, to_select)
		local id = to_select:getEffectiveId()
		if sgs.Self:getPile("Angers"):contains(id) then
			if #selected == 0 then
				return true
			elseif #selected == 1 then
				return to_select:sameColorWith(selected[1])
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = sy_shishenCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("Angers"):length() >= 2
	end
}


sy_zhangfei2:addSkill(sy_shishen)
sy_zhangfei2:addSkill(sy_zhangba)

sy_zhangfei1:addSkill("#sy_hp")
sy_zhangfei1:addSkill("#sy_bianshen")
sy_zhangfei1:addSkill("#W_recast")
sy_zhangfei1:addSkill("#sy_2ndturnstart")
sy_zhangfei2:addSkill("#W_recast")
sgs.LoadTranslationTable{
	["sy_zhangfei1"] = "神张飞",
	["#sy_zhangfei1"] = "待战的猛虎",
	["sy_zhangfei2"] = "神张飞",
	["#sy_zhangfei2"] = "虎啸盘蛇",
	["~sy_zhangfei2"] = "曹贼势大，断了此桥，撤……",
	["sy_zhengjun"] = "整军",
	[":sy_zhengjun"] = "<font color = \"blue\"><b>锁定技，</b></font>回合开始阶段，你弃X张牌（不足则全弃），回合结束阶段，你须将你的武将牌翻面并摸X+1张牌。X为"..
	"你的攻击范围。",
	["$sy_zhengjun1"] = "汝等速速召集残部来助阵！",
	["$sy_zhengjun2"] = "待吾摆个疑兵阵，唬住贼军！",
	["sy_zhangba"] = "仗八",
	[":sy_zhangba"] = "<font color = \"blue\"><b>锁定技，</b></font>当你没有装备武器时，你的攻击范围始终为3。",
	["$sy_zhangba"] = "蛇矛在手，吾还惧何人？",
	["sy_beiliang"] = "备粮",
	[":sy_beiliang"] = "摸牌阶段，你可以选择放弃摸牌，将手牌补至等同于你体力上限的张数。",
	["$sy_beiliang"] = "吾粗中有细，自然留有后手。",
	["sy_juwu"] = "聚武",
	[":sy_juwu"] = "出牌阶段，你可以将至多X张手牌交给神赵云（X为你的当前体力值）。",
	["$sy_juwu"] = "子龙莫慌，我来助你！",
	["sy_chanshe"] = "缠蛇",
	[":sy_chanshe"] = "<font color = \"#FF0033\"><b>聚气技，</b></font>出牌阶段，你可以将你的任意方块花色的“怒”当【乐不思蜀】使用。",
	["$sy_chanshe"] = "欲战不战，匹夫如此不济乎？",
	["sy_shishen"] = "弑神",
	[":sy_shishen"] = "<font color = \"#FF0033\"><b>聚气技，</b></font>出牌阶段，你可以弃两张相同颜色的“怒”，令任一角色失去1点体力。",
	["$sy_shishen"] = "汝等可是想尝尝吾的丈八蛇矛！",
	["designer:sy_zhangfei1"] = "洛神工作室",
	["cv:sy_zhangfei1"] = "清水浊流",
	["illustrator:sy_zhangfei1"] = "洛神工作室",
}




return {extension}