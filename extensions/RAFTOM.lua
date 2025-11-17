extension = sgs.Package("RAFTOM", sgs.Package_GeneralPack)

--==============================================全局变量及函数区==============================================--
local GER, winTimes = "GER.lua", "winTimes.txt"
local ban_marks = {"@clock_time", "@qizhi-Clear", "@puppet", "@nightmare", "@benxi", "@biluan", "@brutal", "@ChangeSkill1", "@ChangeSkill2", "@ChangeSkill3"}  --禁记录mark表
local difficulty_marks = {"easy", "normal", "insane"}
local ban_piles = {"reward"}  --禁记录pile表
local translation = ""  --暂时无用
local reward_types = {"re_type1", "re_type2", "re_type3", "re_type4", "re_type5", "re_type6", "re_type7", "re_type8", "re_type9", "re_type10", "re_type11", "re_type12"
					  , "re_type13", "re_type14", "re_type15", "re_type16", "re_type17", "re_type18", "re_type19"}  --奖励类型

function checkLength(check_table)  --检测table是否为空并返回对应值
	return #check_table > 0 and table.concat(check_table, ",") or "NULL"
end

Table2IntList = function(theTable)  --表转数组
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function useEquip(player, pattern)        			  --随机使用牌堆中的武器牌
	if pattern == nil then pattern = "EquipCard" end  --参数[ServerPlayer *player：武器使用者; QString pattern：使用的装备牌样式，默认值为“EquipCard”;]
	local room = player:getRoom()
	local equips = sgs.CardList()
	for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf(pattern) then
			equips:append(sgs.Sanguosha:getCard(id))
		end
	end
	if not equips:isEmpty() then
		local card = equips:at(math.random(0, equips:length() - 1))
		room:useCard(sgs.CardUseStruct(card, player, player))
	end
end

function gainCardRandomly(player, pattern, num)
	if pattern == nil then pattern = "BasicCard" end
	if num == nil then num = 1 end
	local room = player:getRoom()
	local card_ids = sgs.IntList()
	for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf(pattern) then
			card_ids:append(id)
		end
	end
	if not card_ids:isEmpty() then
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for i = 1, num do
			if card_ids:isEmpty() then break end
			local card_id = card_ids:at(math.random(0, card_ids:length() - 1))
			dummy:addSubcard(card_id)
			card_ids:removeOne(card_id)
		end
		room:obtainCard(player, dummy, false)
		dummy:deleteLater()
	end
end

function judgeHp(player, general_name, fixed)
	if fixed == nil then fixed = 0 end
	local room = player:getRoom()
	local startingHp = player:getMaxHp()
	if general_name == "shenganning" then
		startingHp = 3 + fixed
	end
	room:setPlayerProperty(player, "hp", sgs.QVariant(startingHp))
end

function selectHero(player, changer, num, ban_general)  --选择武将函数 [参数：player-选择玩家; changer-变更武将玩家; num-选择武将数; ban_general-应移除武将（可以为空）]
	local room = player:getRoom()
	if num == nil or num < 1 then num = 1 end
	local generals = sgs.Sanguosha:getLimitedGeneralNames()
	if ban_general then table.removeOne(generals, ban_general) end
	local choiceList = {}
	for i = 1, num do
		if #generals == 0 then break end
		local general = generals[math.random(1, #generals)]
		table.insert(choiceList, general)
		table.removeOne(generals, general)
	end
	local general = room:askForGeneral(player, table.concat(choiceList, "+"))
	room:changeHero(changer, general, false, false)
	judgeHp(changer, general)
end

function reward(player, enemy, reward_type)  --奖励函数：用于进行奖励结算 [参数：player-受奖励者/玩家, enemy-敌方, reward_type-奖励类型]
	local room = player:getRoom()
	if reward_type == "re_type1" then
		if player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player))
		end
		room:drawCards(player, 1, "reward")
	elseif reward_type == "re_type2" then
		room:drawCards(player, 3, "reward")
	elseif reward_type == "re_type3" then
		useEquip(player, "Armor")
		room:drawCards(player, 1, "reward")
	elseif reward_type == "re_type4" then
		useEquip(player, "Weapon")
		room:drawCards(player, 1, "reward")
	elseif reward_type == "re_type5" then
		if player:getHp() < 2 then
			room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp()))
		end
		room:askForDiscard(player, "reward", 1, 1, false, true)
	elseif reward_type == "re_type6" then
		room:drawCards(player, 5, "reward")
		room:askForDiscard(player, "reward", 3, 3, false, true)
	elseif reward_type == "re_type7" then
		room:drawCards(player, 5, "reward")
		room:drawCards(enemy, 2, "reward")
	elseif reward_type == "re_type8" then
		useEquip(player, "Weapon")
		useEquip(player, "Armor")
	elseif reward_type == "re_type9" then
		useEquip(player, "DefensiveHorse")
		useEquip(player, "Weapon")
	elseif reward_type == "re_type10" then
		player:throwAllHandCards()
		if not player:hasSkill(self:objectName()) then
			room:acquireSkill(player, "niepan")
			player:setTag("niepan_thisGame", sgs.QVariant(true))
		end
	elseif reward_type == "re_type11" then
		gainCardRandomly(player, "TrickCard", 2)
	elseif reward_type == "re_type12" then
		if player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player, nil, player:getMaxHp() - player:getHp()))
		end
		room:askForDiscard(player, "reward", 1, 1, false, true)
	elseif reward_type == "re_type13" then
		room:askForDiscard(player, "reward", 2, 2, false, true)
		local playerdata = sgs.QVariant()
		playerdata:setValue(player)
		room:setTag("rewardExtraTurn", playerdata)
	elseif reward_type == "re_type14" then
		room:drawCards(player, 1, "reward")
		enemy:turnOver()
	elseif reward_type == "re_type15" then
		room:drawCards(player, 1, "reward")
		room:damage(sgs.DamageStruct("reward", player, enemy))
	elseif reward_type == "re_type16" then
		gainCardRandomly(player, "BasicCard", 5)
	elseif reward_type == "re_type17" then
		room:loseHp(player, 1, true, nil, "reward")
		room:drawCards(player, 5, "reward")
	elseif reward_type == "re_type18" then
		if player:getHp() > 1 then
			room:loseHp(player, player:getHp() - 1, true, nil, "reward")
		end
		room:drawCards(player, 7, "reward")
	elseif reward_type == "re_type19" then
		room:askForDiscard(player, "reward", 1, 1, false, true)
		room:damage(sgs.DamageStruct("reward", player, enemy, 2))
	end
end

function enemyBuff(enemy, level)  --敌方加成函数：用于结算敌方加成 [参数：enemy-敌方, level-关卡数]
	local room = enemy:getRoom()
	local fixed = 0
	if level == 2 then
		fixed = 1
		enemy:setTag("enemy_buff", sgs.QVariant(1))
	elseif level == 3 then
		fixed = 1
		room:setPlayerProperty(enemy, "maxhp", sgs.QVariant(enemy:getMaxHp() + 1))
		enemy:setTag("enemy_buff", sgs.QVariant(1))
	elseif level == 4 then
		fixed = 2
		room:setPlayerProperty(enemy, "maxhp", sgs.QVariant(enemy:getMaxHp() + 1))
		enemy:setTag("enemy_buff", sgs.QVariant(2))
	elseif level == 5 then
		fixed = 2
		room:setPlayerProperty(enemy, "maxhp", sgs.QVariant(enemy:getMaxHp() + 2))
		enemy:setTag("enemy_buff", sgs.QVariant(2))
	end
	local general = enemy:getGeneralName()
	judgeHp(enemy, general, fixed)
end

--==============================================全局技能区==============================================--
GameEndRecording = sgs.CreateTriggerSkill{  --游戏结束时记录玩家各种状态
	name = "GameEndRecording",
	global = true,
	events = {sgs.GameOverJudge},
	on_trigger = function(self, event, splayer, data, room)
		if not room:getTag("InRAFTOM"):toBool() then return false end
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if not p:getTag("RAFTOM"):toBool() then continue end
			local recordFile = assert(io.open(GER, "r"))
			local level = recordFile:read("*l"):split("=")
			level = tonumber(level[2])
			recordFile:close()
			local record = assert(io.open(GER, "w"))
			if p:isDead() or level == 6 then
				record:write("level=1")
				record:close()
				if p:isAlive() and level == 6 then
					local winFile = assert(io.open(winTimes, "r"))
					local win_count = winFile:read("*l")
					winFile:close()
					local winRecord = assert(io.open(winTimes, "w"))
					if win_count == nil then
						winRecord:write("1")
					else
						local chance = 0
						if p:getMark("easy") > 0 then chance = 40
						elseif p:getMark("normal") > 0 then chance = 70
						elseif p:getMark("insane") > 0 then chance = 100
						end
						if math.random(1, 100) <= chance then
							local count = math.min(3, (tonumber(win_count) + 1))
							winRecord:write("" .. count)
							local msg = sgs.LogMessage()
							msg.type = "#showWinCount"
							msg.arg = count
							room:sendLog(msg)
						else
							winRecord:write("" .. math.min(3, tonumber(win_count)))
						end
					end
					winRecord:close()
				end
				return false
			end
			record:write("level=" .. tostring(level + 1) .. "\n")
			record:write("general=" .. p:getGeneralName() .. "\n")
			local skill_table = {}
			for _, skill in sgs.qlist(p:getVisibleSkillList()) do
				if not ((skill:objectName() == "niepan" and p:getTag("niepan_thisGame"):toBool()) or skill:isAttachedLordSkill()) then
					table.insert(skill_table, skill:objectName())
				end
			end
			record:write("hp=" .. tostring(p:getHp()) .. "/" .. tostring(p:getMaxHp()) .. "\n")
			record:write("skills=" .. checkLength(skill_table) .. "\n")
			local equips, hand = sgs.IntList(), sgs.IntList()
			for _, card in sgs.qlist(p:getCards("he")) do
				local id = card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceEquip then
					equips:append(id)
				elseif room:getCardPlace(id) == sgs.Player_PlaceHand then
					hand:append(id)
				end
			end
			record:write("equip_ids=" .. checkLength(sgs.QList2Table(equips)) .. "\n")
			record:write("hand_ids=" .. checkLength(sgs.QList2Table(hand)) .. "\n")
			local chained = p:isChained() and "1" or "0"
			record:write("isChained=" .. chained .. "\n")
			local faceDown = p:faceUp() and "0" or "1"
			record:write("faceDown=" .. faceDown .. "\n")
			local mark_table, mark_num = {}, {}
			for _, mark in sgs.list(p:getMarkNames()) do
				if (table.contains(ban_marks, mark) or not (string.startsWith(mark, "@") or (p:hasSkill(mark) and
					sgs.Sanguosha:getSkill(mark):getFrequency() == sgs.Skill_Wake))) and not table.contains(difficulty_marks, mark) then continue end
				local n = p:getMark(mark)
				if n > 0 then
					table.insert(mark_table, mark)
					table.insert(mark_num, tostring(n))
				end
			end
			record:write("marks=" .. checkLength(mark_table) .. "\n")
			record:write("marks_num=" .. checkLength(mark_num) .. "\n")
			local pile_names, pile_cards = p:getPileNames(), sgs.IntList()
			if #pile_names > 0 then
				for i = 1, #pile_names do
					if table.contains(ban_piles, pile_names[i]) then continue end
					pile_cards = p:getPile(pile_names[i])
					if pile_cards:length() == 0 then continue end
					record:write(pile_names[i] .. "=" .. checkLength(sgs.QList2Table(pile_cards)) .. "\n")
				end
			end
			record:close()
			break
		end
		return false
	end
}

rewardExtraTurn = sgs.CreatePhaseChangeSkill{
	name = "rewardExtraTurn", 
	global = true,
	priority = 0,
	on_phasechange = function(self, splayer)
		local room = splayer:getRoom()
		local player = room:getTag(self:objectName()):toPlayer()
		if splayer:getPhase() == sgs.Player_NotActive and player and player:isAlive() then
			room:removeTag(self:objectName())
			player:gainAnExtraTurn()
		end
		return false
	end
}

heroesNeverDie = sgs.CreateTriggerSkill{
	name = "heroesNeverDie",
	events = {sgs.AskForPeachesDone},
	global = true,
	priority = 0,
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getTag("RAFTOM"):toBool() and splayer:getHp() <= 0 then
			local winFile = assert(io.open(winTimes, "r"))
			local win_count = tonumber(winFile:read("*l"))
			winFile:close()
			if win_count > 0 and room:askForSkillInvoke(splayer, self:objectName(), sgs.QVariant("HND:" .. win_count)) then
				local winRecord = assert(io.open(winTimes, "w"))
				winRecord:write("" .. math.max(0, math.min(3, win_count - 1)))
				winRecord:close()
				splayer:throwAllHandCardsAndEquips()
				room:recover(splayer, sgs.RecoverStruct(splayer, nil, 2 - splayer:getHp()))
				room:drawCards(splayer, 3, self:objectName())
			end
		end
		return false
	end
}

RAFTOM_start = sgs.CreateTriggerSkill{  --用于使“千里走单骑”模式开始
	name = "#RAFTOM_start",
	events = {sgs.GameStart, sgs.TurnStart, sgs.DrawNCards, sgs.AfterDrawNCards},
	global = true,
	priority = 10,
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.GameStart then
			if room:getMode() == "02p" and room:alivePlayerCount() == 2 and not room:getTag("InRAFTOM"):toBool() then
				local player, robot = nil, nil
				for _, p in sgs.list(room:getAlivePlayers()) do
					if p:getState() ~= "robot" then
						player = p
					else
						robot = p
					end
				end
				local recordFile = assert(io.open(GER, "r"))
				local rf = recordFile:read("*all"):split("\n")
				recordFile:close()
				local level = tonumber(rf[1]:split("=")[2])
				if player and robot and player:objectName() == splayer:objectName() and room:askForSkillInvoke(player, "RAFTOM_start", sgs.QVariant("RA_start:" .. tostring(level))) then
					if level < 1 or level > 6 or #rf < 11 then
						local record = assert(io.open(GER, "w"))
						record:write("level=1")
						record:close()
						level = 1
					end
					if level == 1 and player:getSeat() ~= 1 then
						player:setSeat(1)
						robot:setSeat(2)
						player:setTag("getFirstTurn", sgs.QVariant(true))
					elseif level > 1 and level < 7 and player:getSeat() == 1 then
						player:setSeat(2)
						robot:setSeat(1)
						robot:setTag("getFirstTurn", sgs.QVariant(true))
					end
					if not player:isLord() then
						player:setRole("lord")
						robot:setRole("rebel")
						room:setPlayerProperty(player, "role", sgs.QVariant("lord"))
						room:setPlayerProperty(robot, "role", sgs.QVariant("rebel"))
						room:updateStateItem()
					end
					if level ~= 1 then
						local general_name = rf[2]:split("=")[2]
						room:changeHero(player, general_name, false, false)
						local total_hp = rf[3]:split("=")[2]
						local hp, maxhp = tonumber(total_hp:split("/")[1]), tonumber(total_hp:split("/")[2])
						room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
						room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
						local skill_list = rf[4]:split("=")[2]
						if skill_list ~= "NULL" then
							local skillList = skill_list:split(",")
							local skillstring = table.concat(skillList, "|")
							room:handleAcquireDetachSkills(player, skillstring)
						end
						local equip_ids = rf[5]:split("=")[2]
						local moves = sgs.CardsMoveList()
						if equip_ids ~= "NULL" then
							local move_e = sgs.CardsMoveStruct(Table2IntList(equip_ids:split(",")), nil, player, sgs.Player_DrawPile, sgs.Player_PlaceEquip,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), ""))
							moves:append(move_e)
						end
						local hand_ids = rf[6]:split("=")[2]
						if hand_ids ~= "NULL" then
							local move_h = sgs.CardsMoveStruct(Table2IntList(hand_ids:split(",")), nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), ""))
							moves:append(move_h)
						end
						local isChained = rf[7]:split("=")[2]
						if isChained == "1" then
							player:setChained(true)
							room:broadcastProperty(player, "chained")
						end
						local faceDown = rf[8]:split("=")[2]
						if faceDown == "1" then
							player:setFaceUp(false)
							room:broadcastProperty(player, "faceup")
						end
						room:moveCardsAtomic(moves, false)
						local marks = rf[9]:split("=")[2]
						if marks ~= "NULL" then
							local markList = marks:split(",")
							local marks_num = rf[10]:split("=")[2]
							local num = Table2IntList(marks_num:split(","))
							for i = 1, #markList do
								room:setPlayerMark(player, markList[i], num:at(i - 1))
							end
						end
						if #rf > 11 then
							for i = 11, #rf - 1 do
								local pile_name, ids_string = rf[i]:split("=")[1], rf[i]:split("=")[2]
								local pile_ids = Table2IntList(ids_string:split(","))
								player:addToPile(pile_name, pile_ids)
							end
						end
					end
					room:setTag("InRAFTOM", sgs.QVariant(true))
					player:setTag("RAFTOM", sgs.QVariant(true))
					room:doLightbox("$WelcomeToRAFTOM", 3000)
					local msg = sgs.LogMessage()
					msg.type = "$AppendSeparator"
					room:sendLog(msg)
					msg.type = "#RAFTOMStart"
					room:sendLog(msg)
					local choice = nil
					if level > 1 and level < 6 then
						local choiceList, types = {}, {}
						for _, t in pairs(reward_types) do
							table.insert(types, t)
						end
						math.random()
						for i = 1, 3 do
							if #types == 0 then break end
							local reward_type = types[math.random(1, #types)]
							table.insert(choiceList, reward_type)
							table.removeOne(types, reward_type)
						end
						if #choiceList > 0 then
							choice = room:askForChoice(player, "reward", table.concat(choiceList, "+"))
						end
					elseif level == 1 then
						selectHero(player, player, 7)
						local difficulty = room:askForChoice(player, "select_dif", "easy+normal+insane")
						if difficulty == "easy" then
							room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
							judgeHp(player, player:getGeneralName(), 2)
						elseif difficulty == "normal" then
							room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
							judgeHp(player, player:getGeneralName(), 1)
						else
							player:speak("rua")
						end
						room:setPlayerMark(player, difficulty, 1)
					end
					if level ~= 6 then
						selectHero(player, robot, 3, player:getGeneralName())
					else
						room:changeHero(robot, "RA_caiyang", false, false)
					end
					enemyBuff(robot, level)
					if choice then
						robot:setTag("reward_type", sgs.QVariant(choice))
					end
				end
			end
		elseif event == sgs.TurnStart then
			if room:getTag("InRAFTOM"):toBool() then
				for _, p in sgs.list(room:getAlivePlayers()) do
					if p:getTag("getFirstTurn"):toBool() then
						p:removeTag("getFirstTurn")
						room:setPlayerMark(p, "@clock_time", 1)
						room:throwEvent(sgs.TurnBroken)
						break
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			local recordFile = assert(io.open(GER, "r"))
			local level = recordFile:read("*l"):split("=")
			level = tonumber(level[2])
			recordFile:close()
			if splayer:getTag("RAFTOM"):toBool() and level ~= 1 then
				data:setValue(0)
			end
			if splayer:getTag("enemy_buff"):toInt() > 0 then
				data:setValue(data:toInt() + splayer:getTag("enemy_buff"):toInt())
			end
		else
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			local reward_type = splayer:getTag("reward_type"):toString()
			if reward_type ~= "" and table.contains(reward_types, reward_type) then
				reward(splayer:getNextAlive(), splayer, reward_type)
				splayer:removeTag("reward_type")
			end
		end
		return false
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("GameEndRecording") then skills:append(GameEndRecording) end
if not sgs.Sanguosha:getSkill("rewardExtraTurn") then skills:append(rewardExtraTurn) end
if not sgs.Sanguosha:getSkill("heroesNeverDie") then skills:append(heroesNeverDie) end
if not sgs.Sanguosha:getSkill("#RAFTOM_start") then skills:append(RAFTOM_start) end

--==============================================技能区==============================================--
RA_caiyang = sgs.General(extension, "RA_caiyang", "wei", 1, true, true)
yinka = sgs.CreateTriggerSkill{
	name = "#yinka",
	events = {sgs.DrawNCards, sgs.AfterDrawNCards},
	priority = 10,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			draw.num = 0
			data:setValue(draw)
		else
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			local perfect_cards = {}
			local opponent = player:getNextAlive()
			if opponent:getHp() <= 2 and opponent:getArmor() and not opponent:getArmor():isKindOf("SiverLion") and opponent:hasSkill("buqu") then
				perfect_cards = {"analeptic", "axe", "fire_slash", "vine"}
			elseif math.abs(opponent:getHandcardNum() - opponent:getMaxCards()) > 0 then
				perfect_cards = {"indulgence", "dismentlement", "jink", "vine"}
			elseif player:inMyAttackRange(opponent, -1) then
				perfect_cards = {"jueying", "dismentlement", "jink", "fire_slash"}
			else
				perfect_cards = {"vine", "dismentlement", "jink", "fire_slash"}
			end
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, id in sgs.qlist(room:getDrawPile()) do
				if next(perfect_cards) == nil then break end
				local name = sgs.Sanguosha:getCard(id):objectName()
				if table.contains(perfect_cards, name) then
					dummy:addSubcard(id)
					table.removeOne(perfect_cards, name)
				end
			end
			local fix = 4 - dummy:subcardsLength()
			room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), self:objectName(), ""), false)
			if fix > 0 then
				room:drawCards(player, fix, self:objectName())
			end
		end
		return false
	end
}
RA_caiyang:addSkill(yinka)

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	
	["RAFTOM"] = "千里走单骑",
	
	["reward"] = "奖励",
	["$WelcomeToRAFTOM"] = "千里走单骑",
	["#RAFTOMStart"] = "欢迎进入“千里走单骑”模式！",
	["#showWinCount"] = "恭喜你获得一次复活机会，当前拥有 %arg 次复活机会",
	["RAFTOM_start:RA_start"] = "是否进入“千里走单骑”模式？（当前为第 %src 关卡）",
	
	["re_type1"] = "回复1点体力，并摸一张牌",
	["re_type2"] = "摸三张牌",
	["re_type3"] = "随机装备一个防具牌，并摸一张牌",
	["re_type4"] = "随机装备一个武器牌，并摸一张牌",
	["re_type5"] = "回复2点体力，并弃置一张牌",
	["re_type6"] = "摸五张牌，然后弃置三张牌",
	["re_type7"] = "摸五张牌，然后敌方摸两张牌",
	["re_type8"] = "随机装备一个武器牌，和一个防具牌",
	["re_type9"] = "随机装备一个防御坐骑牌，和一个武器牌",
	["re_type10"] = "弃置所有手牌，仅在本局中获得技能“涅槃”",
	["re_type11"] = "随机获得两张锦囊牌",
	["re_type12"] = "回复至满体力，然后弃置一张牌",
	["re_type13"] = "弃置两张牌，在当前回合结束后，进行一次额外的回合",
	["re_type14"] = "摸一张牌，并使敌方翻面",
	["re_type15"] = "摸一张牌，然后对敌方造成1点伤害",
	["re_type16"] = "随机获得五张基本牌",
	["re_type17"] = "失去1点体力，并摸五张牌",
	["re_type18"] = "失去体力至1点，然后摸七张牌",
	["re_type19"] = "弃置一张牌，并对敌方造成2点伤害",
	
	["heroesNeverDie:HND"] = "你是否选择复活？（你还有 %src 次复活机会）",
	
	["select_dif"] = "难度",
	["easy"] = "简单（+2体力上限和体力）",
	["normal"] = "普通（+1体力上限和体力）",
	["insane"] = "疯狂（一无所有者）",
	
	["RA_caiyang"] = "蔡阳",
	
}

return {extension}
