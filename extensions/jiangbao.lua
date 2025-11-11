extension = sgs.Package("jiangbao")
extension_jieol = sgs.Package("jieolbao")
extension_jie = sgs.Package("jiebao")
extension_gai = sgs.Package("gaibao")
funWeapon = sgs.Package("funWeapon", sgs.Package_CardPack)
local json = require ("json")
local ruszatxa=0
math.random()
--======================================自定义函数区======================================--
function sendComLog(player, name, only_notify, n)  --配音播放及技能触发提示整合函数
	if only_notify == nil then only_notify = false end
	local room = player:getRoom()
	if only_notify then
		room:notifySkillInvoked(player, name)
	else
		room:sendCompulsoryTriggerLog(player, name)
	end
	if n == nil then
		room:broadcastSkillInvoke(name)
	else
		room:broadcastSkillInvoke(name, n)
	end
end

function playEquipAudio(equip)  --播放装备置入装备区的音频
	if equip:isKindOf("Weapon") then sgs.Sanguosha:playAudioEffect("audio/card/common/weapon.ogg", false)
	elseif equip:isKindOf("Armor") or equip:isKindOf("Treasure") then sgs.Sanguosha:playAudioEffect("audio/card/common/armor.ogg", false)
	elseif equip:isKindOf("DefensiveHorse") or equip:isKindOf("OffensiveHorse") then sgs.Sanguosha:playAudioEffect("audio/card/common/horse.ogg", false) end
end

function destroyEquip(room, move, tag_name)  --销毁装备
	local id = room:getTag(tag_name):toInt()
	if move.to_place == sgs.Player_DiscardPile and id > 0 and move.card_ids:contains(id) then
		local move1 = sgs.CardsMoveStruct(id, nil, nil, room:getCardPlace(id), sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "destroy_equip", ""))
		local card = sgs.Sanguosha:getCard(id)
		local log = sgs.LogMessage()
		log.type = "#DestroyEqiup"
		log.card_str = card:toString()
		room:sendLog(log)
		room:moveCardsAtomic(move1, true)
		room:removeTag(card:getClassName())
	end
end
sgs.LoadTranslationTable{
	["#DestroyEqiup"] = "%card 被销毁",
	
}

function try2Forge(player, card, tag_name)  --尝试打造武器（蒲元“铸刃”专属）
	local room = player:getRoom()
	local id = room:getTag(tag_name):toInt()
	if id > 0 then
		local ran = math.random(1, 100)
		local weapon = sgs.Sanguosha:getCard(id)
		if room:getTag(weapon:getClassName()):toBool() then
			local log = sgs.LogMessage()
			log.type = "#WeaponHasExisted"
			log.from = player
			log.card_str = weapon:toString()
			room:sendLog(log)
		elseif ran <= math.min(card:getNumber() * 10, 100) then
			local log = sgs.LogMessage()
			log.type = "#ForgeSuccessfully"
			log.from = player
			log.card_str = weapon:toString()
			room:sendLog(log)
			room:obtainCard(player, id)
			room:setTag(weapon:getClassName(), sgs.QVariant(true))
			return
		else
			local log = sgs.LogMessage()
			log.type = "#Fail2Forge"
			log.from = player
			log.card_str = weapon:toString()
			room:sendLog(log)
		end
	end
	local ids = sgs.IntList()
	for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
			ids:append(id)
		end
	end
	if not ids:isEmpty() then
		room:obtainCard(player, ids:at(math.random(0, ids:length() - 1)))
	end
end
sgs.LoadTranslationTable{
	["#ForgeSuccessfully"] = "%from 成功打造 %card",
	["#Fail2Forge"] = "%from 打造 %card 失败",
	["#WeaponHasExisted"] = "%card 已存在，%from 无法打造",
	
}


	local json = require ("json")--照搬的lua化身
	function isNormalGameMode (mode_name)
		return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
	end
	function GetAvailableGenerals(zuoci)
		local all = sgs.Sanguosha:getLimitedGeneralNames()
		local room = zuoci:getRoom()
			if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_")or room:getMode() == "custom_scenario") then
				table.removeTable(all,sgs.GetConfig("Banlist/Roles",""):split(","))
			elseif (room:getMode() == "04_1v3") then
				table.removeTable(all,sgs.GetConfig("Banlist/HulaoPass",""):split(","))
			elseif (room:getMode() == "06_XMode") then
				table.removeTable(all,sgs.GetConfig("Banlist/XMode",""):split(","))
				for _,p in sgs.qlist(room:getAlivePlayers())do
					table.removeTable(all,(p:getTag("XModeBackup"):toStringList()) or {})
				end
			elseif (room:getMode() == "02_1v1") then
				table.removeTable(all,sgs.GetConfig("Banlist/1v1",""):split(","))
				for _,p in sgs.qlist(room:getAlivePlayers())do
					table.removeTable(all,(p:getTag("1v1Arrange"):toStringList()) or {})
				end
			end
			local Huashens = {}
			local Hs_String = zuoci:getTag("jiehuashens"):toString()
			if Hs_String and Hs_String ~= "" then
				Huashens = Hs_String:split("+")
			end
			table.removeTable(all,Huashens)
			for _,player in sgs.qlist(room:getAlivePlayers())do
				local name = player:getGeneralName()
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all,name)	
				if player:getGeneral2() == nil then continue end	
				name = player:getGeneral2Name();
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all,name)
			end	
			local banned = {"zuoci","jie_zuoci", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"}
			table.removeTable(all,banned)	
			return all
	end
	function AcquireGenerals(zuoci, n)
		local room = zuoci:getRoom();
		local Huashens = {}
		local Hs_String = zuoci:getTag("jiehuashens"):toString()
		if Hs_String and Hs_String ~= "" then
			Huashens = Hs_String:split("+")
		end
		local list = GetAvailableGenerals(zuoci)
		if #list == 0 then return end
		n = math.min(n, #list)
		local acquired = {}
		repeat
			local rand = math.random(1,#list)
			if not table.contains(acquired,list[rand]) then
				table.insert(acquired,(list[rand]))
			end
		until #acquired == n		
			for _,name in pairs(acquired)do
				table.insert(Huashens,name)
				localgeneral = sgs.Sanguosha:getGeneral(name)
				if general then
					for _,skill in sgs.list(general:getTriggerSkills()) do
						if skill:isVisible() then
							room:getThread():addTriggerSkill(skill)
						end
					end
				end
			end
			zuoci:setTag("jiehuashens", sgs.QVariant(table.concat(Huashens, "+")))	
			local hidden = {}
			for i = 1,n,1 do
				table.insert(hidden,"unknown")
			end
			for _,p in sgs.qlist(room:getAllPlayers())do
				local splist = sgs.SPlayerList()
				splist:append(p)
				if p:objectName() == zuoci:objectName() then
					room:doAnimate(4, zuoci:objectName(), table.concat(acquired,":"), splist)
				else
					room:doAnimate(4, zuoci:objectName(),table.concat(hidden,":"),splist);
				end
			end	
			local log = sgs.LogMessage()
			log.type = "#GetHuashen"
			log.from = zuoci
			log.arg = n
			log.arg2 = #Huashens
			room:sendLog(log)
			local jsonLog ={
				"#GetHuashenDetail",
				zuoci:objectName(),
				"",
				"",
				table.concat(acquired,"\\, \\"),
				"",
			}
			room:setPlayerMark(zuoci, "@xin_huashen", #Huashens)
	end
	function SelectSkill(zuoci)
		local room = zuoci:getRoom();
		local ac_dt_list = {}
		local huashen_skill = zuoci:getTag("jiehuashenSkill"):toString();
			if huashen_skill ~= "" then
				table.insert(ac_dt_list,"-"..huashen_skill)
			end
			local Huashens = {}
			local Hs_String = zuoci:getTag("jiehuashens"):toString()
			if Hs_String and Hs_String ~= "" then
				Huashens = Hs_String:split("+")
			end
			if #Huashens == 0 then return end
			local huashen_generals = {}
			for _,huashen in pairs(Huashens)do
				table.insert(huashen_generals,huashen)
			end
			local skill_names = {}
			local skill_name
			local general 
			local ai = zuoci:getAI();
			if (ai) then
				local hash = {}
				for _,general_name in pairs (huashen_generals) do
					local general = sgs.Sanguosha:getGeneral(general_name)
					for _,skill in (general:getVisibleSkillList())do
						if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
							continue
						end
						if not table.contains(skill_names,skill:objectName()) then
							hash[skill:objectName()] = general;
							table.insert(skill_names,skill:objectName())
						end
					end
				end
				if #skill_names == 0 then return end
				skill_name = ai:askForChoice("huashen",table.concat(skill_names,"+"), sgs.QVariant());
				general = hash[skill_name]
			else
				local general_name = room:askForGeneral(zuoci, table.concat(huashen_generals,"+"))
				general = sgs.Sanguosha:getGeneral(general_name)
				assert(general)
				for _,skill in sgs.qlist(general:getVisibleSkillList())do
					if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
						continue
					end
					if not table.contains(skill_names,skill:objectName()) then
						table.insert(skill_names,skill:objectName())
					end
				end
				if #skill_names > 0 then
					skill_name = room:askForChoice(zuoci, "huashen",table.concat(skill_names,"+"))
				end
			end
			local kingdom = general:getKingdom()
			if zuoci:getKingdom() ~= kingdom then
				if kingdom == "god" then
					kingdom = room:askForKingdom(zuoci);
					local log = sgs.LogMessage()
					log.type = "#ChooseKingdom";
					log.from = zuoci;
					log.arg = kingdom;
					room:sendLog(log);
				end
				room:setPlayerProperty(zuoci, "kingdom", sgs.QVariant(kingdom))
			end
			if zuoci:getGender() ~= general:getGender() then
				zuoci:setGender(general:getGender())
			end
			local jsonValue = {
				9,
				zuoci:objectName(),
				general:objectName(),
				skill_name,
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			zuoci:setTag("jiehuashenSkill",sgs.QVariant(skill_name))
			if skill_name ~= "" then
				table.insert(ac_dt_list,skill_name)
			end
			room:handleAcquireDetachSkills(zuoci, table.concat(ac_dt_list,"|"), true)
	end
	
function Set(list)
		local set = {}
		for _, l in ipairs(list) do set[l] = true end
		return set
	end
	local patterns = {"slash", "jink", "peach", "analeptic", "nullification", "snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
	if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
		table.insert(patterns, 2, "thunder_slash")
		table.insert(patterns, 2, "fire_slash")
		table.insert(patterns, 2, "normal_slash")
	end
	local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
	function getPos(table, value)
		for i, v in ipairs(table) do
			if v == value then
				return i
			end
		end
		return 0
	end
	local pos = 0
	
function questionOrNot(player)
		local room = player:getRoom()
		local yuji = room:findPlayerBySkillName("jieguhuo")
		local guhuoname = room:getTag("GuhuoType"):toString()
		if guhuoname == "peach+analeptic" then guhuoname = "peach" end
		if guhuoname == "normal_slash" then guhuoname = "slash" end
		local guhuocard = sgs.Sanguosha:cloneCard(guhuoname, sgs.Card_NoSuit, 0)
		local guhuotype = guhuocard:getClassName()
		if guhuotype and guhuotype == "AmazingGrace" then return "noquestion" end
		if guhuotype:match("Slash") then
			if yuji:getState() ~= "robot" and math.random(1, 4) == 1 and not sgs.questioner then return "question" end
		end
		if math.random(1, 6) == 1 and player:getHp() >= 3 and player:getHp() > player:getLostHp() then return "question" end
		local players = room:getOtherPlayers(player)
		players = sgs.QList2Table(players)
		local x = math.random(1, 5)
		if sgs.questioner then return "noquestion" end
		local questioner = room:getOtherPlayers(player):at(0)
		return player:objectName() == questioner:objectName() and x ~= 1 and "question" or "noquestion"
	end
	function guhuo(self, yuji)
			local room = yuji:getRoom()
			room:addPlayerMark(yuji, "jieguhuo_Play")		
			local players = room:getOtherPlayers(yuji)		
			local used_cards = sgs.IntList()
			local moves = sgs.CardsMoveList()
			for _, card_id in sgs.qlist(self:getSubcards()) do
				used_cards:append(card_id)
			end		
			local questioned = sgs.SPlayerList()
			for _, p  in sgs.qlist(players) do
				if p:hasSkill("LuaChanyuan") then
					local log = sgs.LogMessage()
					log.type = "#LuaChanyuan"
					log.from = yuji
					log.to:append(p)
					log.arg = "LuaChanyuan"
					room:sendLog(log)				
					room:notifySkillInvoked(p, "LuaChanyuan")
					room:setEmotion(p, "no-question")
				else
					local choice = "noquestion"
					if p:getState() == "online" then
						choice = room:askForChoice(p, "guhuo", "noquestion+question")
					else
						room:getThread():delay(sgs.GetConfig("OriginAIDelay", ""))
						choice = questionOrNot(p)
					end
					if choice == "question" then
						sgs.questioner = p
						room:setEmotion(p, "question")
						questioned:append(p)					
					else
						room:setEmotion(p, "no-question")					
					end			
					local log = sgs.LogMessage()
					log.type = "#GuhuoQuery"
					log.from = p
					log.arg = choice
					room:sendLog(log)				
				end
			end
			room:removeTag("GuhuoType")
			local log = sgs.LogMessage()
			log.type = "$GuhuoResult"
			log.from = yuji
			local subcards = self:getSubcards()
			log.card_str = tostring(subcards:first())
			room:sendLog(log)
			local success = false
			local canuse = false
			if questioned:isEmpty() then
				canuse = true
				for _, p in sgs.qlist(players) do
					room:setEmotion(p, ".")
				end			
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "guhuo")
				local move = sgs.CardsMoveStruct()
				move.card_ids = used_cards
				move.from = yuji
				move.to = nil
				move.to_place = sgs.Player_PlaceTable
				move.reason = reason
				moves:append(move)
				room:moveCardsAtomic(moves, true)
			else
				local card = sgs.Sanguosha:getCard(subcards:first())
				local user_string = self:getUserString()						
				if user_string == "peach+analeptic" then
					success = card:objectName() == yuji:getTag("GuhuoSaveSelf"):toString()
				elseif user_string == "slash" then
					success = string.sub(card:objectName(), -5, -1) == "slash"
				elseif user_string == "normal_slash" then
					success = card:objectName() == "slash"
				else
					success = card:match(user_string)
				end
				if success then
					for _, p in sgs.qlist(questioned) do
						room:loseHp(p)
						room:handleAcquireDetachSkills(p, "chanyuan", true)
					end
				else
					for _, p in sgs.qlist(questioned) do
						if p:isAlive() then
							p:drawCards(1)
						end
					end
				end
				if success	then canuse = true end	
				if canuse then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "guhuo")
					local move = sgs.CardsMoveStruct()
					move.card_ids = used_cards
					move.from = yuji
					move.to = nil
					move.to_place = sgs.Player_PlaceTable
					move.reason = reason
					moves:append(move)
					room:moveCardsAtomic(moves, true)
				else
					room:moveCardTo(self, yuji, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, yuji:objectName(), "", "guhuo"), true)
				end
				for _, p in sgs.qlist(players) do
					room:setEmotion(p, ".")
				end			
			end
			yuji:removeTag("GuhuoSaveSelf")		
			return canuse
		end	
	
--======================================全局技能区======================================--
equipRemover = sgs.CreateTriggerSkill{  --执行装备的移出游戏操作
	name = "equip_remover",
	global = true,
	priority = 10,
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.GameStart then
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("RibbonLance") then
					room:setTag("RL_ID", sgs.QVariant(id))
					local move = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("BlazeBlade") then
					room:setTag("BB_ID", sgs.QVariant(id))
					local move = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("WaveSword") then
					room:setTag("WS_ID", sgs.QVariant(id))
					local move = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("VenomousBlade") then
					room:setTag("VB_ID", sgs.QVariant(id))
					local move = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("ThunderBlade") then
					room:setTag("TB_ID", sgs.QVariant(id))
					local move = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
			end
		else
			if splayer:objectName() == room:getCurrent():objectName() then
				local move = data:toMoveOneTime()
				destroyEquip(room, move, "RL_ID")
				destroyEquip(room, move, "BB_ID")
				destroyEquip(room, move, "WS_ID")
				destroyEquip(room, move, "VB_ID")
				destroyEquip(room, move, "TB_ID")
			end
		end
		return false
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("equip_remover") then skills:append(equipRemover) end

--======================================游戏牌区======================================--
RibbonLanceSkill = sgs.CreateTriggerSkill{
	name = "RibbonLanceSkill",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			local current = room:getCurrent()
			if not (current and current:isAlive() and not current:hasFlag(self:objectName())) or not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			room:setPlayerFlag(current, self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("RibbonLance")
	end
}

RibbonLance = sgs.CreateWeapon{  --蒲元专属装备：【红缎枪】
	name = "ribbon_lance",
	class_name = "RibbonLance",
	suit = sgs.Card_Heart,
	number = 1,
	range = 3,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RibbonLanceSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "RibbonLanceSkill")
	end
}
RibbonLance:setParent(funWeapon)
sgs.LoadTranslationTable{
	["ribbon_lance"] = "红缎枪",
	[":ribbon_lance"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：每回合限一次，当你使用【杀】造成伤害后，你可以进行判定，若结果为红色，你回复1点体力。",
	["RibbonLanceSkill"] = "红缎枪",
	
}

BlazeBladeSkill = sgs.CreateTriggerSkill{
	name = "BlazeBladeSkill",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not damage.chain and not damage.transfer
			and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			if not room:askForCard(player, "Slash,Weapon+^BlazeBlade", "@BlazeBlade-invoke::" .. damage.to:objectName(), data, self:objectName()) then return false end
			local log = sgs.LogMessage()
			log.type = "#BlazeBladeEffect"
			log.from = damage.from
			log.arg = damage.damage
			damage.damage = damage.damage + 1
			log.arg2 = damage.damage
			room:sendLog(log)
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("BlazeBlade")
	end
}

BlazeBlade = sgs.CreateWeapon{  --蒲元专属装备：【烈淬刀】
	name = "blaze_blade",
	class_name = "BlazeBlade",
	suit = sgs.Card_Diamond,
	number = 1,
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("BlazeBladeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "BlazeBladeSkill")
	end
}
BlazeBlade:setParent(funWeapon)
sgs.LoadTranslationTable{
	["blaze_blade"] = "烈淬刀",
	[":blaze_blade"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：当你使用【杀】对目标角色造成伤害时，你可以弃置一张【杀】或武器牌，令此伤害+1。",
	["BlazeBladeSkill"] = "烈淬刀",
	["@BlazeBlade-invoke"] = "烈淬刀：你可以弃置一张【杀】或武器牌，令 %dest 受到的伤害+1",
	["#BlazeBladeEffect"] = "%from 的【<font color=\"yellow\"><b>烈淬刀</b></font>】效果被触发，伤害从 %arg 增加至 %arg2",
	
}

WaveSwordSkill = sgs.CreateTriggerSkill{
	name = "WaveSwordSkill",
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local card, use
		if event == sgs.CardUsed then
			use = data:toCardUse()
			card = use.card
		else
			use = data:toCardResponse()
			if use.m_isUse then
				card = use.m_card
			end
		end
		if card and player:getMark("card_used_play") <= 1 and (card:isKindOf("Slash") or card:isNDTrick()) then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not (use.to:contains(p) or room:isProhibited(player, p, card)) and card:targetFilter(sgs.PlayerList(), p, player) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "wave_sword-invoke:::" .. card:objectName(), true, true)
				if to then
					use.to:append(to)
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("WaveSword")
	end
}

WaveSword = sgs.CreateWeapon{  --蒲元专属装备：【水波剑】
	name = "wave_sword",
	class_name = "WaveSword",
	suit = sgs.Card_Club,
	number = 1,
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("WaveSwordSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "WaveSwordSkill")
	end
}
WaveSword:setParent(funWeapon)
sgs.LoadTranslationTable{
	["wave_sword"] = "水波剑",
	[":wave_sword"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：当你于出牌阶段使用第一张牌时，若其为【杀】或普通锦囊牌，你可以多选择一个目标。",
	["WaveSwordSkill"] = "水波剑",
	["wave_sword-invoke"] = "水波剑：你可以为 %arg 多选择一个目标",
	
}

VenomousBladeSkill = sgs.CreateTriggerSkill{
	name = "VenomousBladeSkill",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.card:isBlack() and use.to:length() == 1 then
			local to, _data = use.to:first(), sgs.QVariant()
			_data:setValue(to)
			if to:getMark("Equips_of_Others_Nullified_to_You") > 0 or not room:askForSkillInvoke(player, self:objectName(), _data) then return false end
			room:doAnimate(1, player:objectName(), to:objectName())
			room:obtainCard(to, use.card)
			room:loseHp(to)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("VenomousBlade")
	end
}

VenomousBlade = sgs.CreateWeapon{  --蒲元专属装备：【混毒弯刃】
	name = "venomous_blade",
	class_name = "VenomousBlade",
	suit = sgs.Card_Spade,
	number = 1,
	range = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("VenomousBladeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "VenomousBladeSkill")
	end
}
VenomousBlade:setParent(funWeapon)
sgs.LoadTranslationTable{
	["venomous_blade"] = "混毒弯刃",
	[":venomous_blade"] = "装备牌·武器<br /><b>攻击范围</b>：1<br /><b>武器技能</b>：当你使用黑色【杀】仅指定一名角色为目标后，你可以令其获得此【杀】，然后其失去1点体力。",
	["VenomousBladeSkill"] = "混毒弯刃",
	
}

ThunderBladeSkill = sgs.CreateTriggerSkill{
	name = "ThunderBladeSkill",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.to:length() == 1 then
			local to, _data = use.to:first(), sgs.QVariant()
			_data:setValue(to)
			if to:getMark("Equips_of_Others_Nullified_to_You") > 0 or not room:askForSkillInvoke(player, self:objectName(), _data) then return false end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|spade|2~9"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = to
			room:judge(judge)
			if judge:isGood() then
				room:damage(sgs.DamageStruct(self:objectName(), nil, to, 3, sgs.DamageStruct_Thunder))
				local nullified_list = use.nullified_list
				table.insert(nullified_list, to:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("ThunderBlade")
	end
}

ThunderBlade = sgs.CreateWeapon{  --蒲元专属装备：【天雷刃】
	name = "thunder_blade",
	class_name = "ThunderBlade",
	suit = sgs.Card_Spade,
	number = 1,
	range = 4,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("ThunderBladeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "ThunderBladeSkill")
	end
}
ThunderBlade:setParent(funWeapon)
sgs.LoadTranslationTable{
	["thunder_blade"] = "天雷刃",
	[":thunder_blade"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：当你使用【杀】仅指定一名角色为目标后，你可以令其进行判定，若结果为黑桃2~9，其受到3点雷电伤害，然后此【杀】对其无效。",
	["ThunderBladeSkill"] = "天雷刃",
	
}

--======================================武将及其技能区======================================--


shenpeii = sgs.General(extension, "shenpeii", "qun", 3, true, false, false, 2)
        shouyeee = sgs.CreateTriggerSkill{
			name = "shouyeee" ,
			events = {sgs.TargetConfirmed,sgs.BeforeCardsMove} , 
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.TargetConfirmed then
					local use = data:toCardUse()
					local diyu =false
					if use.to:contains(player) and  not room:getCurrent():hasFlag(self:objectName()..player:objectName()) and use.from:objectName()~=player:objectName() and not use.card:isKindOf("SkillCard") and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:getCurrent():setFlags(self:objectName()..player:objectName())
					local  choic=room:askForChoice(player, self:objectName(), "kaichengyoudi+qixiliangdao")
                    local  choie=room:askForChoice(use.from, self:objectName(), "kaichengyou+qixiliang")
				local msg = sgs.LogMessage()
				msg.type = "#xuanze"..choic..""
				msg.from = player
				room:sendLog(msg)
				msg.type = "#xuanze"..choie..""
				msg.from = use.from
				room:sendLog(msg)  
					if  choic=="kaichengyoudi"  then
                    if choie=="kaichengyou" then
				local msg = sgs.LogMessage()
				msg.type = "#shenpei_chenggong"
				msg.from = player
				room:sendLog(msg)
					 diyu=true
				else
				local msg = sgs.LogMessage()
				msg.type = "#shibai"
				msg.from = player
				room:sendLog(msg)
					end
			end
			        if  choic=="qixiliangdao"  then
                    if choie=="qixiliang" then
				local msg = sgs.LogMessage()
				msg.type = "#shenpei_chenggong2"
				msg.from = player
				room:sendLog(msg)
					 diyu=true
				else
				local msg = sgs.LogMessage()
				msg.type = "#shibai2"
				msg.from = player
				room:sendLog(msg)
					end
			end
			                        if diyu==true then
									local card = use.card
									if card then
										local ids = sgs.IntList()
										if card:isVirtualCard() then
											ids = card:getSubcards()
										else
											ids:append(card:getEffectiveId())
										end
										if ids:length() > 0 then
											local all_place_table = true
											for _, id in sgs.qlist(ids) do
												if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
													all_place_table = false
													break
												end
											end
											if all_place_table then
												room:setCardFlag(use.card:getEffectiveId(), "real_S"..self:objectName())
											end
										end
									end
                                    use.to:removeOne(player)
									data:setValue(use)
			end
							end
	end
	if event == sgs.BeforeCardsMove then
				local move = data:toMoveOneTime()
				local room = player:getRoom()
					local card = sgs.Sanguosha:getCard(move.card_ids:first())
					if card:hasFlag("real_S"..self:objectName()) then
					for _, id in sgs.qlist(move.card_ids) do
					room:setCardFlag(sgs.Sanguosha:getCard(id), "-real_S"..self:objectName())	
			end
    move.to = player
	move.to_place = sgs.Player_PlaceHand
	move.reason.m_reason = sgs.CardMoveReason_S_REASON_GOTBACK
	move.reason.m_playerId = player:objectName()
	move.reason.m_skillName = "mobile_shouyeee"
                        data:setValue(move)
					end
				end
			end
}
shenpeii:addSkill(shouyeee)
gangzhjCard = sgs.CreateSkillCard{
	name = "gangzhj",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isAllNude()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
			local id = room:askForCardChosen(effect.from, effect.to, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(id, effect.to, effect.from)
	end
}
gangzhjVS = sgs.CreateViewAsSkill{
	name = "gangzhj",
	response_or_use = false,
	response_pattern = "@@gangzhj",
			view_as = function(self, card)
		local card = gangzhjCard:clone()
		card:addSubcard(card:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return  false 
	end
}
gangzhj = sgs.CreateTriggerSkill{
	name = "gangzhj",
	view_as_skill = gangzhjVS,
	events = {sgs.EventPhaseStart,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName().."gangzhi") == 0 then
			room:askForUseCard(player, "@@gangzhj", "@gangzhj")
	end
	    if player:getPhase() == sgs.Player_Finish then
	    if  player:getMark(self:objectName().."gangzhi") ~= 0 then
	   room:removePlayerMark(player, self:objectName().."gangzhi")
	end
		end
	end
	 if event == sgs.Damaged then
	  if  player:getMark(self:objectName().."gangzhi") == 0 then
		room:addPlayerMark(player, self:objectName().."gangzhi")
	   if  player:getPhase() ~= sgs.Player_NotActive  then
	   room:addPlayerMark(player, self:objectName().."gangzhi")
			end
	end
	end
	end
}
shenpeii:addSkill(gangzhj)
xin_zhuling = sgs.General(extension_gai,"xin_zhuling","wei",4,true)
xin_zhayi_jibenCard = sgs.CreateSkillCard{
	name = "xin_zhayi_jiben",
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = sgs.Self:getTag("xin_zhayi_jiben"):toCard()
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
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
		local card = sgs.Self:getTag("xin_zhayi_jiben"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("xin_zhayi_jiben"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_xin_zhayi_jiben = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(player, "xin_zhayi_jiben_slash", table.concat(xin_zhayi_jiben_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_xin_zhayi_jiben")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_xin_zhayi_jiben
		if user_str == "peach+analeptic" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "analeptic")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "xin_zhayi_jiben_saveself", table.concat(xin_zhayi_jiben_list, "+"))
		elseif user_str == "slash" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "xin_zhayi_jiben_slash", table.concat(xin_zhayi_jiben_list, "+"))
		else
			to_xin_zhayi_jiben = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_xin_zhayi_jiben")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
xin_zhayi_jiben = sgs.CreateViewAsSkill{
	name = "xin_zhayi_jiben",
	n=1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
				return to_select:isKindOf("BasicCard")
	end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local skillcard = xin_zhayi_jibenCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("xin_zhayi_jiben"):toCard()
		if c then
			skillcard:setUserString(c:objectName())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
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
		return false
	end,
	enabled_at_response = function(self, player, pattern)
        if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
        return pattern ~= "nullification"
	end
}
xin_zhayi_jiben:setGuhuoDialog("l")
xin_zhanyiBuff = sgs.CreateTriggerSkill{
	name = "#xin_zhanyiBUff",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if  RIGHT(self, effect.from) and effect.from:getMark( "xin_zhanyi-Clear") ~= 0  then
			SendComLog(self, effect.from)
				return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
xin_zhanyixiaogu = sgs.CreateTriggerSkill{
	name = "#xin_zhanyixiaogu",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isKindOf("Slash") and player:getMark( "xin_zhayi-Clear") ~= 0 then
			for _, p in sgs.qlist(use.to) do
				if not p:isNude() then		
     local cards=room:askForExchange(p, self:objectName(), 2, 2, true, "@xin_zhayi")
		local dummy = sgs.Sanguosha:cloneCard("slash") 
        dummy:addSubcards(cards:getSubcards()) 
	room:throwCard(dummy, p, p)
	room:fillAG(cards:getSubcards())
	local  id=room:askForAG(player,cards:getSubcards(),false,self:objectName())
	room:clearAG()
		room:obtainCard(player, id, false)
			end
		end
	end
	end
}
xin_zhanyiuff = sgs.CreateTriggerSkill{
	name = "#xin_zhanyiuff",
	events = {sgs.PreHpRecover, sgs.ConfirmDamage, sgs.CardResponded,sgs.CardUsed, sgs.CardFinished},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.CardUsed   then
		local use = data:toCardUse()
		if use.from:getMark( "xin_zhan-Clear") ~= 0 and use.card:isKindOf("BasicCard") then
			room:setCardFlag(use.card, "xinF")
			room:removePlayerMark(use.from, "xin_zhan-Clear")
		end
	elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:isKindOf("BasicCard") and rec.card:hasFlag("xinF") then
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
	elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card:isKindOf("BasicCard") and damage.card:hasFlag("xinF")then
				damage.damage = damage.damage + 1
				data:setValue(damage)
	end
	    elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag(self:objectName()) then
			room:setCardFlag(data:toCardUse().card, "-xinF")
	end
end
}
xin_zhanyiwe = sgs.CreateTriggerSkill{
	name = "#xin_zhanyiwe",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			if  player:getPhase() == sgs.Player_Play  and player:hasSkill("xin_zhayi_jiben") then
            room:detachSkillFromPlayer(player, "xin_zhayi_jiben", true)
			room:detachSkillFromPlayer(player, "xin_zhayi_jiben", true)
			room:detachSkillFromPlayer(player, "xin_zhayi_jiben", true)
		   player:addSkill("xin_zhanyi")		
           room:attachSkillToPlayer(player, "xin_zhanyi")
		end
	end
}
xin_zhanyiCard = sgs.CreateSkillCard{
		name = "xin_zhanyi",
		target_fixed = true,
		on_use = function(self, room, source, targets)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			room:loseHp(source, 1)
			if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("BasicCard") then
			room:addPlayerMark(source, "xin_zhan-Clear")
            room:detachSkillFromPlayer(source, "xin_zhanyi", true)
		    room:detachSkillFromPlayer(source, "xin_zhanyi", true)
			room:detachSkillFromPlayer(source, "xin_zhanyi", true)
		   source:addSkill("xin_zhayi_jiben")		
           room:attachSkillToPlayer(source, "xin_zhayi_jiben")
			end
			if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("TrickCard") then
			source:drawCards(3)
			room:addPlayerMark(source, "xin_zhanyi-Clear")
			end
			if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
			room:addPlayerMark(source, "xin_zhayi-Clear")
	end
		end	
}
xin_zhanyi = sgs.CreateOneCardViewAsSkill{
        name = "xin_zhanyi",
       filter_pattern = ".!",
		view_as = function(self, card)
			local xin_zhayi = xin_zhanyiCard:clone()
			xin_zhayi:addSubcard(card)
			xin_zhayi:setSkillName(self:objectName())
			return xin_zhayi
end,
		enabled_at_play = function(self, player)
			return  not player:hasUsed("#xin_zhanyi") or player:getMark("xin_zhnyi-Clear") ~=0
		end, 
}
xin_zhuling:addSkill(xin_zhanyi)
xin_zhuling:addSkill(xin_zhanyiuff)
xin_zhuling:addSkill(xin_zhanyiBuff)
xin_zhuling:addSkill(xin_zhanyixiaogu)
xin_zhuling:addSkill(xin_zhanyiwe)
extension:insertRelatedSkills("xin_zhayi_jiben", "#xin_zhanyiuff")
extension:insertRelatedSkills("xin_zhayi_jiben", "#xin_zhanyiwe")
extension:insertRelatedSkills("xin_zhanyi", "#xin_zhanyiBUff")
extension:insertRelatedSkills("xin_zhanyi", "#xin_zhanyixiaogu")
xin_beimihu = sgs.General(extension_gai, "xin_beimihu$", "qun", 3, false)
xin_guju = sgs.CreateTriggerSkill{
	name = "xin_guju",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getMark("@puppet") > 0 then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				SendComLog(self, p)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
				local bianji=true
					if p:getMark("@shubingzhao")>0 then
				if  player:getKingdom()=="shu" then
                 bianji=false
				end
				end
				   if p:getMark("@weibingzhao")>0 then
				if  player:getKingdom()=="wei" then
                 bianji=false
				end
				end
				if p:getMark("@wubingzhao")>0 then
				if  player:getKingdom()=="wu" then
                 bianji=false
				end
				end
				if p:getMark("@qunbingzhao")>0 then
				if  player:getKingdom()=="qun" then
                 bianji=false
				end
				end
			    if bianji then
					room:addPlayerMark(p, "guju")
					p:drawCards(1,self:objectName())
				else
					room:addPlayerMark(p, "guju",2)
					p:drawCards(2,self:objectName())
				end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
bingzhao = sgs.CreateTriggerSkill{ 
	name = "bingzhao$",
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
	local types = {"wei", "shu", "wu","qun"}
				table.removeOne(types,player:getKingdom())
				room:setTag("bishaoType", sgs.QVariant(table.concat(types, "+")))
		local kingdom = room:askForChoice(player, self:objectName(),  table.concat(types, "+"))
		room:removeTag("bishaoType")
		player:gainMark("@"..kingdom..""..self:objectName().."")
end
}
xin_beimihu:addSkill(xin_guju)
xin_beimihu:addSkill(bingzhao)
xinbaijia = sgs.CreatePhaseChangeSkill{
	name = "xinbaijia",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("guju") >= 7 and player:getMark(self:objectName()) == 0 then
			SendComLog(self, player)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				room:addPlayerMark(player, self:objectName())
				if room:changeMaxHpForAwakenSkill(player, 1) then
					room:recover(player, sgs.RecoverStruct(player))
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@puppet") == 0 then
							p:gainMark("@puppet")
						end
					end
					room:handleAcquireDetachSkills(player, "-xin_guju|canshib")
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}
xin_beimihu:addSkill(xinbaijia)
xin_beimihu:addSkill("zongkui")
xin_beimihu:addRelateSkill("canshib")
nanshengmi = sgs.General(extension, "nanshengmi", "qun", 3, true)
chijian = sgs.CreateTriggerSkill{ 
	name = "chijian",
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
	local types = {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if  not table.contains(types,p:getKingdom()) then
					table.insert(types,p:getKingdom() )
			end
					end
				room:setTag("bishaoType", sgs.QVariant(table.concat(types, "+")))
		local kingdom = room:askForChoice(player, self:objectName(),  table.concat(types, "+"))
		room:broadcastSkillInvoke("chijian", 1)
		room:removeTag("bishaoType")
		room:setPlayerProperty(player, "kingdom", sgs.QVariant(kingdom))
end
}
	waishiCard = sgs.CreateSkillCard{
		name = "waishi" ,
		will_throw = false ,
		handling_method = sgs.Card_MethodNone ,
		filter = function(self, selected, to_select)
			return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
		end ,
		on_use = function(self, room, source, targets)
			room:broadcastSkillInvoke("waishi", math.random(1,2))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "LuaNosRende", "")
			room:obtainCard(targets[1], self, reason, false)
			if not targets[1]:isKongcheng()then
			     local cards=room:askForExchange(targets[1], self:objectName(),self:getSubcards():length(), self:getSubcards():length(), false, "@waishi")
		local dummy = sgs.Sanguosha:cloneCard("slash") 
        dummy:addSubcards(cards:getSubcards()) 
	room:obtainCard(source, dummy, false)
	   if source:getKingdom()==targets[1]:getKingdom() or source:getHandcardNum()<targets[1]:getHandcardNum() then
		source:drawCards(1,"waishi")
	end
	end
end
	}
waishi = sgs.CreateViewAsSkill{
	name = "waishi" ,
       n=999,
	view_filter = function(self, selected, to_select)
		local types = {sgs.Self:getKingdom()}
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
		if  not table.contains(types,p:getKingdom()) then
			table.insert(types,p:getKingdom() )
			end
					end
		if #selected == #types then
		return false
	else
		return true
	end
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local rende_card = waishiCard:clone()
		for _, c in ipairs(cards) do
			rende_card:addSubcard(c)
		end
			return rende_card
		end ,
	enabled_at_play = function(self, player)
			return not player:isNude() and player:usedTimes("#waishi") < 1+player:getMark("renshe")
		end
	}
rienshe = sgs.CreateTriggerSkill{
	name = "#rienshe",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			if  event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play  then
				room:addPlayerMark(player, "waishi",player:getMark("renshe"))
			end
			if  event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play   then
				room:removePlayerMark(player, "renshe",player:getMark("waishi"))
				room:removePlayerMark(player, "waishi",player:getMark("waishi"))
			end			
	end
}
renshe = sgs.CreateMasochismSkill{
		name = "renshe" ,
		on_damaged = function(self, player, damage)
			local room = player:getRoom()
			local data = sgs.QVariant()
			local players = sgs.SPlayerList()
			local xiaoe = {}
					local types = {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if  not table.contains(types,p:getKingdom()) then
					table.insert(types,p:getKingdom() )
			end
					end
			if #types>1 then
			xiaoe={"shilii+shiyongcishu+shuangmopai"}
	  else
		     xiaoe={"shiyongcishu+shuangmopai"}
	     end
		    xiaoguo = room:askForChoice(player, self:objectName(), table.concat(xiaoe, ""))
			room:broadcastSkillInvoke("renshe", math.random(1,2))
			if xiaoguo == "shilii" then
				table.removeOne(types,player:getKingdom())
				room:setTag("bishaoType", sgs.QVariant(table.concat(types, "+")))
		local kingdom = room:askForChoice(player, "renshe2",  table.concat(types, "+"))
		room:removeTag("bishaoType")
		room:setPlayerProperty(player, "kingdom", sgs.QVariant(kingdom))
		end
		    if xiaoguo == "shiyongcishu" then
			room:addPlayerMark(player, self:objectName())
	end
			if xiaoguo == "shuangmopai" then
             		for _, p in sgs.qlist(room:getAlivePlayers()) do
					if  p:objectName()~=player:objectName() then
					players:append(p)
			end
			end
			if not players:isEmpty() then
				local to = room:askForPlayerChosen(player, players, self:objectName(), self:objectName().."-invoke", false, true)
				if to then
				to:drawCards(1)
				player:drawCards(1)
			end
				end
		end		
end
	}
nanshengmi:addSkill(chijian)
nanshengmi:addSkill(rienshe)
nanshengmi:addSkill(waishi)
nanshengmi:addSkill(renshe)
extension:insertRelatedSkills("renshe", "#rienshe")
jiedianwei = sgs.General(extension_jie, "jiedianwei", "wei", 4, true)
	luaqiangxiCard = sgs.CreateSkillCard{
		name = "luaqiangxi", 
		filter = function(self, targets, to_select) 
			if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName()  then return false end--根据规则集描述应该可以选择自己才对
			local rangefix = 0
			if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
				local card = sgs.Self:getWeapon():getRealCard():toWeapon()
				rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
			end
			return to_select:getMark("luaqiangxiy-Clear")==0  and sgs.Self:inMyAttackRange(to_select, rangefix);
		end,
		on_effect = function(self, effect)
			local room = effect.to:getRoom()
			if self:getSubcards():isEmpty() then 
				room:loseHp(effect.from)
			end
			room:broadcastSkillInvoke("luaqiangxi", math.random(1,2))
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
			room:addPlayerMark(effect.to, self:objectName().."y-Clear")
		end
	}
	luaqiangxi = sgs.CreateViewAsSkill{
		name = "luaqiangxi", 
		n = 1, 
		enabled_at_play = function(self, player)
			local x=0
		for _, p in sgs.qlist(player:getAliveSiblings()) do
		if  player:inMyAttackRange(p)  then
			x=x+1
			end
					end
			return player:usedTimes("#luaqiangxi") ~=x
		end,
		view_filter = function(self, selected, to_select)
			return  #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select) 
		end, 
		view_as = function(self, cards) 
			if #cards == 0  then
				return luaqiangxiCard:clone()
	       elseif #cards == 1  then
				local card = luaqiangxiCard:clone()
				card:addSubcard(cards[1])
				return card
			else 
				return nil
			end
		end
	}
jiedianwei:addSkill(luaqiangxi)
jieyuanshao = sgs.General(extension_jie, "jieyuanshao$", "qun", 4, true)
lualuanjivs = sgs.CreateViewAsSkill{
		name = "lualuanji",
		n = 2,
		view_filter = function(self, selected, to_select)
				return not (to_select:isEquipped() or string.find(sgs.Self:property(self:objectName()):toString(),to_select:getSuitString()))
		end,
		view_as = function(self, cards)
			if #cards ~= 2 then return nil end
			local card = sgs.Sanguosha:cloneCard("archery_attack",sgs.Card_SuitToBeDecided,-1)
			for _,c in pairs(cards) do
			card:addSubcard(c)
	       end
	        card:setSkillName(self:objectName())
				return card
		end,
		enabled_at_play=function(self,player)
			local x=0
				for _, card in sgs.qlist(player:getHandcards()) do
			if  string.find(player:property(self:objectName()):toString(),card:getSuitString()) then
				x = x + 1
			end	
	end
		return player:getHandcardNum()>=2 and player:getHandcardNum()-x>1
		end,
	}
lualuanji = sgs.CreateTriggerSkill{
       name = "lualuanji",
       view_as_skill=lualuanjivs,
       events ={sgs.PreCardUsed,sgs.EventPhaseEnd,sgs.Damage,sgs.CardFinished},
	   on_trigger=function(self,event,player,data,room)
		if  event==sgs.PreCardUsed then
		local use=data:toCardUse()
		if use.card:getSkillName()==self:objectName() then
		room:addPlayerMark(use.from, self:objectName().."n-Clear",use.to:length())
		local suits =player:property(self:objectName()):toString()==""and{}or player:property(self:objectName()):toString():split("+")
		for _,id in sgs.qlist(use.card:getSubcards()) do
		 table.insert(suits,sgs.Sanguosha:getCard(id):getSuitString())
		end
		room:setPlayerProperty(player,self:objectName(),sgs.QVariant(table.concat(suits,"+")))
		end
		return false
	end
	    if event == sgs.EventPhaseEnd then
		if player:getPhase() == sgs.Player_Play then
		local room = player:getRoom()
		room:setPlayerProperty(player,self:objectName(),sgs.QVariant(nil))
		end
	end
			if event == sgs.Damage then
			local damage = data:toDamage()	
		if  damage.card:getSkillName()=="lualuanji" then
		if player:getMark(self:objectName().."-Clear")==0 then
		room:addPlayerMark(damage.from, self:objectName().."-Clear")
		end
		end
	end
				if event == sgs.CardFinished then
		if  data:toCardUse().card:getSkillName()=="lualuanji" then
		if player:getMark(self:objectName().."-Clear")==0 then
		player:drawCards(player:getMark(self:objectName().."n-Clear"), self:objectName())
		room:removePlayerMark(player, self:objectName().."n-Clear",player:getMark(self:objectName().."n-Clear"))
	else
		room:removePlayerMark(player, self:objectName().."n-Clear",player:getMark(self:objectName().."n-Clear"))
		room:removePlayerMark(player, self:objectName().."-Clear")
			end
		end
	end
end
}
xin_luanjii = sgs.CreateTriggerSkill{
       name = "#lualuanjii",
       events ={sgs.CardResponded},
	     on_trigger=function(self,event,player,data,room)
		if   data:toCardResponse().main_card:getSkillName()=="lualuanji" then
				player:drawCards(1, self:objectName())
end
end,
	can_trigger = function(self, target)
		return target
end
}
jieyuanshao:addSkill(xin_luanjii)
jieyuanshao:addSkill(lualuanji)
jieyuanshao:addSkill("xueyi")
extension:insertRelatedSkills("lualuanji", "#xin_luanjii")
jiepangtong = sgs.General(extension_jie, "jiepangtong", "shu", 3, true)
	jie_lianhuan = sgs.CreateViewAsSkill{
		name = "jie_lianhuan",
		n = 1,
		view_filter = function(self, selected, to_select)
			return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Club)
		end,
		view_as = function(self, cards)
			if #cards == 1 then
				local chain = sgs.Sanguosha:cloneCard("iron_chain", cards[1]:getSuit(), cards[1]:getNumber())
				chain:addSubcard(cards[1])
				chain:setSkillName(self:objectName())
				return chain
			end
		end
	}
jie_lianhuanMod = sgs.CreateTargetModSkill{
	name = "#jie_lianhuan" ,
	pattern = "IronChain" ,
	extra_target_func = function(self, from)
		if (from:hasSkill("jie_lianhuan")) then
			return 1
		end
			return 0
		end
	}
xinniepanCard = sgs.CreateSkillCard{
	name = "xinniepan",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
					source:loseMark("@nirvana")
					room:broadcastSkillInvoke("xinniepan", math.random(1,2))
					source:throwAllCards()
                    room:recover(source, sgs.RecoverStruct(player,nil,3-source:getHp()))
					source:drawCards(3)
			    	if source:isChained() then
						local damage = dying_data.damage
						if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
							room:setPlayerProperty(source, "chained", sgs.QVariant(false))
						end
					end
					if not source:faceUp() then
						source:turnOver()
					end
			return false
		end,
}
xinniepanVS = sgs.CreateViewAsSkill{
	name = "xinniepan",
	response_or_use = false,
	response_pattern = "@@xinniepan",
			view_as = function(self, card)
		local card = xinniepanCard:clone()
		card:addSubcard(card:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return  player:getMark("@nirvana") > 0
	end
}
xinniepan = sgs.CreateTriggerSkill{
	name = "xinniepan",
	view_as_skill = xinniepanVS,
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
		on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
		if player:getMark("@nirvana") > 0 and player:askForSkillInvoke(self:objectName(), data) then
             room:askForUseCard(player, "@@xinniepan", "@xinniepan")
		end
	end
	can_trigger = function(self, target)
		if target then
		if target:hasSkill(self:objectName()) then
			if target:isAlive() then
		return target:getMark("@nirvana") > 0
		end
			end
		end
			return false
		end
end
	}
	xinniepanstart = sgs.CreateTriggerSkill{
		name = "#xinniepanstart",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.GameStart},
		on_trigger = function(self, event, player, data)
			player:gainMark("@nirvana")
		end
	}
jiepangtong:addSkill(xinniepan)
jiepangtong:addSkill(jie_lianhuanMod)
jiepangtong:addSkill(jie_lianhuan)
jiepangtong:addSkill(xinniepanstart)
extension:insertRelatedSkills("jie_lianhuan", "#jie_lianhuan")
extension:insertRelatedSkills("xinniepan", "#xinniepanstart")
jieyanchou = sgs.General(extension_jie, "jieyanchou", "qun", 4, true)
xin_shuangxiongavs = sgs.CreateOneCardViewAsSkill{
		name = "xin_shuangxiong",
		view_filter = function(self,to_select)
			if to_select:isEquipped() then return false end
			if sgs.Self:getMark(self:objectName().."Black") > 0 then
				return to_select:isBlack()
	      elseif  sgs.Self:getMark(self:objectName().."Red") > 0 then
				return to_select:isRed()
			end
			return false
		end,
		view_as = function(self, card)
			local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
			duel:addSubcard(card)
			duel:setSkillName(self:objectName())
			return duel
		end,
		enabled_at_play = function(self, player)
						local x=0
		for _, card in sgs.qlist(player:getHandcards()) do
		if  (player:getMark(self:objectName().."Red") >0 and card:isRed()) or (player:getMark(self:objectName().."Black") >0 and card:isBlack()) then
			x=x+1
			end
					end
			return  x~=0
		end
	}
xin_shuangxiong = sgs.CreateTriggerSkill{
	name = "xin_shuangxiong",
	view_as_skill = xin_shuangxiongavs,
	global = true,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.Damaged,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and RIGHT(self, player) and player:askForSkillInvoke(self:objectName(), data) then
				local list=room:getNCards(2)
	            room:fillAG(list)
	            local id=room:askForAG(player,list,false,self:objectName())
	            room:clearAG()
				room:obtainCard(player, id, true)
				room:broadcastSkillInvoke("xin_shuangxiong", math.random(1,2))
				list:removeOne(id)
				room:throwCard(sgs.Sanguosha:getCard(list:first()), nil, nil)
				if sgs.Sanguosha:getCard(id):isRed() then
				room:addPlayerMark(player, self:objectName().."Black")
			    end
				if sgs.Sanguosha:getCard(id):isBlack() then
				room:addPlayerMark(player, self:objectName().."Red")
				end
			room:sendCompulsoryTriggerLog(player, self:objectName())
				return true
		end
	end
		if  event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish   then
		room:removePlayerMark(player, self:objectName().."Black",player:getMark(self:objectName().."Black"))
		room:removePlayerMark(player, self:objectName().."Red",player:getMark(self:objectName().."Red"))
			end
	if event == sgs.Damaged then
	local damage = data:toDamage()	
		if  damage.card~=nil and damage.card:getSkillName()=="xin_shuangxiong" and damage.to:hasSkill(self:objectName()) then
           		local ids = sgs.IntList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, card in sgs.qlist(p:getCards("hej")) do
				if card:hasFlag(self:objectName()) then
					ids:append(card:getId())
				end
			end
		end
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
				ids:append(id)
				end
			end
		for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
				ids:append(id)
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash") 
        dummy:addSubcards(ids) 
		room:obtainCard(damage.to, dummy, false)
		end
	end
		if event == sgs.CardFinished then
	if  data:toCardUse().card:getSkillName()=="xin_shuangxiong" then
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, card in sgs.qlist(p:getCards("hej")) do
			if card:hasFlag(self:objectName()) then
				room:setCardFlag(card, "-"..self:objectName())
				end
			end
		end
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
			end
				end
			for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
			room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
			end
					end
			end
	end
end
}
xin_shuangxiongg = sgs.CreateTriggerSkill{
       name = "#xin_shuangxiong",
       events ={sgs.CardResponded},
	     on_trigger=function(self,event,player,data,room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do	
		if   data:toCardResponse().main_card:getSkillName()=="xin_shuangxiong" and player:objectName()~=p:objectName()  then
			   for _,id in sgs.qlist(data:toCardResponse().m_card:getSubcards()) do
						room:setCardFlag(sgs.Sanguosha:getCard(id), "xin_shuangxiong")
			end
end
end
end,
	can_trigger = function(self, target)
		return target
end
}
jieyanchou:addSkill(xin_shuangxiongg)
jieyanchou:addSkill(xin_shuangxiong)
extension:insertRelatedSkills("xin_shuangxiong", "#xin_shuangxiongg")
jiewolong = sgs.General(extension_jie, "jiewolong", "shu", 3, true)
jieKanpo = sgs.CreateOneCardViewAsSkill{
   name = "jieKanpo",
	filter_pattern = ".|black",
   response_pattern = "nullification",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(self:objectName())
		return ncard
	end,
	enabled_at_nullification = function(self, player)
	for _, card in sgs.qlist(player:getCards("he")) do
		if card:isBlack() then return true end
		end
	return false
	end
	}
 jieHuoji = sgs.CreateOneCardViewAsSkill{
    name = "jieHuoji",
	filter_pattern = ".|red",
	view_as = function(self, card)
	local suit = card:getSuit()
	local point = card:getNumber()
	local id = card:getId()
	local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
	fireattack:setSkillName(self:objectName())
	fireattack:addSubcard(id)
	return fireattack
	end
}
jiewolong:addSkill(jieHuoji)
jiewolong:addSkill(jieKanpo)
jiewolong:addSkill("bazhen")
jiexunyu = sgs.General(extension_jie, "jiexunyu", "wei", 3, true)
jiejieming = sgs.CreateTriggerSkill{
		name = "jiejieming" ,
		events = {sgs.Damaged} ,
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local room = player:getRoom()
			for i = 0, damage.damage - 1, 1 do
				local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieming-invoke", true, true)
				if not to then break end
				room:broadcastSkillInvoke("jiejieming", math.random(1,2))
				to:drawCards(2,self:objectName())
				if  to:getHandcardNum()<to:getMaxHp() then
				player:drawCards(1,self:objectName())	
				end
			end
		end
	}
jiexunyu:addSkill(jiejieming)
jiexunyu:addSkill("quhu")
jiemenghuo = sgs.General(extension_jie, "jiemenghuo", "shu", 4, true)
jiezaiqiCard = sgs.CreateSkillCard{
	name = "jiezaiqi",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("jiezaiqi")
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:broadcastSkillInvoke("jiezaiqi", math.random(1,2))
		    local x={}
		     if  effect.from:getHp()==effect.from:getMaxHp() then
			x={"mopai1"}
	      else
			x={"huixie1+mopai1"}
			end
			if room:askForChoice(effect.to, self:objectName(), table.concat(x, ""))=="huixie1" then
			 room:recover(effect.from, sgs.RecoverStruct(effect.from))    
	    else
				effect.to:drawCards(1,"jiezaiqi")
	end
	end
}
jiezaiqiVS = sgs.CreateViewAsSkill{
	name = "jiezaiqi",
	response_or_use = false,
	response_pattern = "@@jiezaiqi",
			view_as = function(self, card)
		local card = jiezaiqiCard:clone()
		card:addSubcard(card:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return  false 
	end
}
jiezaiqi = sgs.CreateTriggerSkill{
	name = "jiezaiqi",
	view_as_skill = jiezaiqiVS,
	events = {sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from  and move.to_place == sgs.Player_DiscardPile and player:getPhase() ~= sgs.Player_NotActive then
			for _,id in sgs.qlist(move.card_ids) do
			if	sgs.Sanguosha:getCard(id):isRed() then
			 room:addPlayerMark(player, self:objectName())
			end
			end
		end
	   elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and RIGHT(self, player) then
		if  player:getMark(self:objectName())>0 then
		room:addPlayerMark(player, self:objectName().."i")--为了ai辅助
		room:askForUseCard(player, "@@jiezaiqi", "@jiezaiqi")
		room:removePlayerMark(player, self:objectName(),player:getMark(self:objectName()))
		room:removePlayerMark(player, self:objectName().."i",1)
	end
end
end
}
jiemenghuo:addSkill(jiezaiqi)
jiemenghuo:addSkill("huoshou")
jie_zhurong = sgs.General(extension_jie, "jie_zhurong", "shu", 4, false)
jielieren = sgs.CreateTriggerSkill{
	name = "jielieren",
		events = {sgs.TargetSpecified},
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local use = data:toCardUse()
			for _, p in sgs.qlist(use.to) do
			room:setTag("jielieren-objectName", sgs.QVariant(p:objectName()))
			if  use.card:isKindOf("Slash") and not player:isKongcheng() and not p:isKongcheng() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("jielieren", math.random(1,2))
					local success = player:pindian(p, self:objectName())
					if not success then return false end
					if not p:isNude() then
						local card_id = room:askForCardChosen(player, p, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= Player_PlaceHand)
					end
				end
			end
		    room:setTag("jielieren-objectName", sgs.QVariant(nil))
	end
		end
	}
jieliereni = sgs.CreateTriggerSkill{
	name = "#jieliereni",
	global = true,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data, room)
			local pindian = data:toPindian()
			if pindian.reason == "jielieren" then
			if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
			room:obtainCard(pindian.to,pindian.from_card,true )
			room:obtainCard(pindian.from,pindian.to_card,true )
		end	
		end	
			end
}
jie_zhurong:addSkill(jielieren)
jie_zhurong:addSkill(jieliereni)
jie_zhurong:addSkill("juxiang")
extension:insertRelatedSkills("jielieren", "#jieliereni")
jie_xuhuang = sgs.General(extension_jie, "jie_xuhuang", "wei", 4, true, sgs.GetConfig("EnableHidden", true))
jie_duanliang = sgs.CreateOneCardViewAsSkill{
	name = "jie_duanliang",
	filter_pattern = "BasicCard,EquipCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end
}
jie_duanliang_buff = sgs.CreateTargetModSkill{
	name = "#jie_duanliang",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("jie_duanliang") and to then
			if to:getHandcardNum() >= from:getHandcardNum()  then
			return 1000
		else
			return 2
		end
		end
		return 0
	end
}
jie_xuhuang:addSkill(jie_duanliang)
jie_xuhuang:addSkill(jie_duanliang_buff)
jie_xuhuang:addSkill("jiezi")
extension:insertRelatedSkills("jie_duanliang", "#jie_duanliang")
jie_caopi= sgs.General(extension_jie, "jie_caopi$", "wei", 3, true)
banbanbanban = sgs.CreateProhibitSkill{
	name = "#banbanbanban",
	is_prohibited = function(self, from, to, card)
		return  not card:isKindOf("SkillCard") and (from:getMark("jiefangzuwu")>0 and from:objectName()~=to:objectName())
	end
}
jiefangzu= sgs.CreateMasochismSkill{
		name = "jiefangzu",
		on_damaged = function(self, player)
			local room = player:getRoom()
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fangzhu-invoke", player:getMark("JilveEvent") ~= 35, true)
			if to then
			room:addPlayerMark(player, self:objectName().."i")
			room:broadcastSkillInvoke("jiefangzu", math.random(1,2))
			local n=to:getHandcardNum()-player:getLostHp()
		    if n>0 and room:askForDiscard(to, self:objectName(), n, n, true,false,"jiefangzu-dis") then
			room:addPlayerMark(to, "jiefangzuwu")
		else
				to:drawCards(player:getLostHp(), self:objectName())
				to:turnOver()
		end
		    room:removePlayerMark(player, self:objectName().."i",1)
			end
end
	}
jiefangzuwe = sgs.CreateTriggerSkill{
	name = "#jiefangzuwe",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
				for _, p in sgs.qlist(room:getPlayers()) do
				    if p:getMark("jiefangzuwu")>0 then
					    room:removePlayerMark(p, "jiefangzuwu")
					end
		end
	end,
	can_trigger = function(self, target)
		return target:getPhase() == sgs.Player_Finish
end
}
jie_caopi:addSkill(banbanbanban)
jie_caopi:addSkill(jiefangzu)
jie_caopi:addSkill(jiefangzuwe)
extension:insertRelatedSkills("jiefangzu", "#banbanbanban")
extension:insertRelatedSkills("jiefangzu", "#jiefangzuwe")
jiexingshang = sgs.CreateTriggerSkill{
		name = "jiexingshang",
		events = {sgs.Death},
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() ~= player:objectName()  then
			if player:isAlive()  then
			local c={"dedaopai","huixie11"}
				if player:getHp()==player:getMaxHp() then
			table.removeOne(c,"huixie11")
		end
		  if splayer:isNude() then
		    table.removeOne(c,"dedaopai")
	     end
		         if #c>0 then
				if player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(splayer, self:objectName().."i")
				if room:askForChoice(player, self:objectName(), table.concat(c, "+"))=="dedaopai" then
				room:broadcastSkillInvoke("jiexingshang", math.random(1,2))	
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local cards = splayer:getCards("he")
				for _,card in sgs.qlist(cards) do
					dummy:addSubcard(card)
				end
				if cards:length() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
					room:obtainCard(player, dummy, reason, false)
				end
				dummy:deleteLater()
		else
			 room:broadcastSkillInvoke("jiexingshang", math.random(1,2))
			 room:recover(player, sgs.RecoverStruct(player))
			end
	end
	          room:removePlayerMark(splayer, self:objectName().."i")
			end
	end
	end
		end
}
jie_caopi:addSkill(jiexingshang)
jie_caopi:addSkill("songwei")
jie_dongzhuo= sgs.General(extension_jie, "jie_dongzhuo$", "qun", 8, true)
jiejiuchiVS = sgs.CreateViewAsSkill{
		name = "jiejiuchi",
		n = 1,
		view_filter = function(self, selected, to_select)
			return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Spade)
		end,
		view_as = function(self, cards)
			if #cards == 1 then
				local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
				analeptic:setSkillName(self:objectName())
				analeptic:addSubcard(cards[1])
				return analeptic
			end
		end,
		enabled_at_play = function(self, player)
			local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
			return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
		end,
		enabled_at_response = function(self, player, pattern)
			return string.find(pattern, "analeptic")
		end
}
jiejiuchi = sgs.CreateTriggerSkill{
		name = "jiejiuchi" ,
		view_as_skill = jiejiuchiVS,
		events = {sgs.Damage,sgs.EventPhaseEnd} ,
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local room=player:getRoom()
		if event==sgs.Damage then
			if damage.card and  damage.card:hasFlag("drank") then
							room:addPlayerMark(player, "Qingchengbenghuai")
	               end
else
	   	    if player:getPhase() == sgs.Player_Finish then
            room:removePlayerMark(player, "Qingchengbenghuai")
	end
		end
end
	}
jie_dongzhuo:addSkill(jiejiuchi)
jie_dongzhuo:addSkill("roulin")
jie_dongzhuo:addSkill("benghuai")
jie_dongzhuo:addSkill("baonue")
gai_zhangrang= sgs.General(extension_gai, "gai_zhangrang", "qun", 3, true)
gaitaoluan_select = sgs.CreateSkillCard{
	name = "gaitaoluan",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("gaitaoluan"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "gaitaoluan", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("gaitaoluan")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "gaitaoluanpos", pos)
					room:setPlayerProperty(source, "gaitaoluan", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@gaitaoluan", "@gaitaoluan:"..pattern)--%src
				end
			end
		end
	end
}
gaitaoluanCard = sgs.CreateSkillCard{
	name = "gaitaoluanCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			card:addSubcard(self:getSubcards():first())
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if user:getMark("gaitaoluan"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "gaitaoluan", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("gaitaoluan")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("gaitaoluan"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "gaitaoluan", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("gaitaoluan")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
		use_card:addSubcard(self:getSubcards():first())
		return use_card
	end
}
gaitaoluanVS = sgs.CreateViewAsSkill{
	name = "gaitaoluan",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@gaitaoluan" then
			return false
		else return true end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = gaitaoluan_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = gaitaoluanCard:clone()
			if pattern and pattern == "@@gaitaoluan" then
				pattern = patterns[sgs.Self:getMark("gaitaoluanpos")]
				acard:addSubcard(sgs.Self:property("gaitaoluan"):toInt())
				if #cards ~= 0 then return end
			else
				if #cards ~= 1 then return end
				acard:addSubcard(cards[1]:getId())
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
				pattern = "analeptic"
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("gaitaoluan"..name) == 0 then
				table.insert(choices, name)
			end
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if sgs.GetConfig("gaitaoluan_down", true) and (p:hasFlag("Global_Dying") or player:hasFlag("Global_Dying")) then
				return false
			end
		end
		return next(choices) and player:getMark("gaitaoluan-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or player:getMark("gaitaoluan-Clear") > 0 then return false end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if sgs.GetConfig("gaitaoluan_down", true) and (p:hasFlag("Global_Dying") or player:hasFlag("Global_Dying")) then
				return false
			end
		end
		for _, p in pairs(pattern:split("+")) do
			if player:getMark(self:objectName()..p) == 0 then return true end
		end
	end,
	enabled_at_nullification = function(self, player, pattern)
		return player:getMark("gaitaoluannullification") == 0 and player:getMark("gaitaoluan-Clear") == 0
	end
}
gaitaoluan = sgs.CreateTriggerSkill{
	name = "gaitaoluan",
	view_as_skill = gaitaoluanVS,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if  player:getMark("gaitaoluan"..card:objectName()) == 0 then
					room:addPlayerMark(player, "gaitaoluan"..card:objectName())
			local biaoji =player:property(self:objectName()):toString()==""and{}or player:property(self:objectName()):toString():split("+")
			if  not table.contains(biaoji,card:objectName()) then
					table.insert(biaoji,card:objectName() )
			end
					room:setPlayerProperty(player,"gaitaoluanwe",sgs.QVariant(table.concat(biaoji,"+")))
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "gaitaoluan" and use.card:getTypeId() ~= 0 then
				room:addPlayerMark(player, "gaitaoluann")
				room:addPlayerMark(player, "gaitaoluani")
				room:addPlayerMark(player, "gaitaoluan"..use.card:getTypeId())--大部分标记都是ai辅助别乱改
				local types = {"BasicCard", "TrickCard", "EquipCard"}
				table.removeOne(types,types[use.card:getTypeId()])
				room:setTag("gaitaoluanType", sgs.QVariant(table.concat(types, ",")))
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@gaitaoluan-ask:" .. use.card:objectName(), false, true)
				room:removeTag("gaitaoluanType")
				if target then
					local x=math.min(player:getMark("gaitaoluann"),3)
					--if not target:isKongcheng() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					if target:getHandcardNum()+target:getEquips():length()>=x then
					local cards=room:askForExchange(target, self:objectName(), x, x, true, "@gaitaoluan-give",true, table.concat(types, ","))
					room:removePlayerMark(player, "gaitaoluani",1)
					room:removePlayerMark(player, "gaitaoluan"..use.card:getTypeId(),1)
					if cards then
					dummy:addSubcards(cards:getSubcards())	
					room:obtainCard(player, dummy)
					else
						room:loseHp(player,x)
						room:addPlayerMark(player, "gaitaoluan-Clear")
					end
				else
				room:loseHp(player,x)
				room:addPlayerMark(player, "gaitaoluan-Clear")	
				end
				end
			end
		end
	end
}
gai_zhangrang:addSkill(gaitaoluan)
gaitaoluanwe = sgs.CreateTriggerSkill{
	name = "#gaitaoluanwe",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:removePlayerMark(p, "gaitaoluann",p:getMark("gaitaoluann"))
			for _, name in pairs(p:property("gaitaoluanwe"):toString():split("+")) do
				if p:getMark("gaitaoluan"..name) > 0 then
				room:removePlayerMark(p, "gaitaoluan"..name)
				local biaoji = p:property(self:objectName()):toString():split("+")
					table.removeOne(biaoji,name)
					room:setPlayerProperty(p,"gaitaoluanwe",sgs.QVariant(table.concat(biaoji,"+")))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getPhase() == sgs.Player_Finish
end
}
gai_zhangrang:addSkill(gaitaoluanwe)
extension:insertRelatedSkills("gaitaoluan", "#gaitaoluanwe")
jie_sunjian= sgs.General(extension_jie, "jie_sunjian", "wu", 4, true)
xinpoluCard = sgs.CreateSkillCard{
	name = "xinpolu",
	filter = function(self, targets, to_select)
		return #targets < 999
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
				effect.to:drawCards(effect.from:getMark("xinpolun"),"xinpolu")
	end
}
xinpoluVS = sgs.CreateViewAsSkill{
	name = "xinpolu",
	response_or_use = false,
	response_pattern = "@@xinpolu",
			view_as = function(self, card)
		local card = xinpoluCard:clone()
		card:addSubcard(card:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return  false 
	end
}
xinpolu= sgs.CreateTriggerSkill{
	name = "xinpolu",
	view_as_skill = xinpoluVS,
		events = {sgs.BuryVictim,sgs.Death},
		can_trigger = function(target)
			return target ~= nil
		end,
		on_trigger = function(self, event, player, data)
			local death = data:toDeath()
			local room = player:getRoom()
			if event==sgs.BuryVictim then
			if death.damage and death.damage.from and death.damage.from:hasSkill(self:objectName()) then
			room:addPlayerMark(death.damage.from, "xinpolun")	
          room:askForUseCard(death.damage.from, "@@xinpolu", "@xinpolu")
		end
	else
		if death.who:objectName() == player:objectName() and death.who:hasSkill(self:objectName()) then
		room:addPlayerMark(player, "xinpolun")	
        room:askForUseCard(player, "@@xinpolu", "@xinpolu")
		end
	end
end,
}
jie_sunjian:addSkill("yinghun")
jie_sunjian:addSkill(xinpolu)
gai_yujin= sgs.General(extension_gai, "gai_yujin", "wei", 4, true)
gaizhengjunCard = sgs.CreateSkillCard{
	name = "gaizhengjun",
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:broadcastSkillInvoke("gaizhengjun", math.random(1,2))
		local reason = room:obtainCard(effect.to, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(), effect.to:objectName(), self:objectName(), ""), true)
		room:setPlayerCardLimitation(effect.to, "use, response", ".|black", false)--感谢t神和板蓝根，惑神3位大佬提供的方法
		room:addPlayerMark(effect.to, self:objectName().."slash")
		room:addPlayerMark(effect.to, self:objectName())
		room:addPlayerMark(effect.from, self:objectName().."i")
		 local bool=room:askForUseCard(effect.to, "slash", "@askforfhslash")
		room:removePlayerMark(effect.from, self:objectName().."i")
		if not bool then
				local players = sgs.SPlayerList()
				players:append(effect.to)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if effect.to:inMyAttackRange(p) then
					players:append(p)
				end
			end
			if not players:isEmpty() then
			local to = room:askForPlayerChosen(effect.from, players, self:objectName(), self:objectName().."-invoke", true, true)
				if to then
				room:damage(sgs.DamageStruct(self:objectName(), effect.from,to, 1))
				end
			end
	end	
	end
}
gaizhengjunfuzhu = sgs.CreateTriggerSkill{
	name = "#gaizhengjunfuzhu",
	events = {sgs.ChoiceMade,sgs.CardUsed,sgs.Damage,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
	local room=player:getRoom()
	for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
	if p:getMark("gaizhengjuni")>0 then
	if event==sgs.ChoiceMade then
	if player:getMark("gaizhengjunslash")>0 then
	room:removePlayerCardLimitation(player, "use, response", ".|black")
	room:removePlayerMark(player, "gaizhengjunslash")
	end
	end
	if event==sgs.CardUsed then
	if player:getMark("gaizhengjun")>0 then
	local use = data:toCardUse()
	room:removePlayerMark(player, "gaizhengjun")
	room:setCardFlag(use.card, "gaizhengjun")
	end
	end
	if event==sgs.Damage  then
	if data:toDamage().card:hasFlag("gaizhengjun") then
	p:drawCards(data:toDamage().damage,"gaizhengjun")
	end
	end
	if event==sgs.CardFinished  then
	if data:toCardUse().card:hasFlag("gaizhengjun") then
	room:setCardFlag(data:toCardUse().card, "-gaizhengjun")
	p:drawCards(1,"gaizhengjun")
	end
    end
	end
	end
	end,
	can_trigger = function(self, target)
		return target
end	
}
gai_yujin:addSkill(gaizhengjunfuzhu)
gaizhengjunVS = sgs.CreateViewAsSkill{
	name = "gaizhengjun",
	response_pattern = "@@gaizhengjun",
	n=1,
	view_filter = function(self, selected, to_select)
		return true
	end ,
		view_as = function(self, cards)
			if #cards ~= 1 then return nil end
			local card = gaizhengjunCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end ,
	enabled_at_play = function(self, player)
		return  false 
	end
}
gaizhengjun = sgs.CreateTriggerSkill{
	name = "gaizhengjun",
	view_as_skill = gaizhengjunVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
	    if  not player:isNude() then
			room:askForUseCard(player, "@@gaizhengjun", "@gaizhengjun")
		end
	end
end
}
gai_yujin:addSkill(gaizhengjun)
extension:insertRelatedSkills("gaizhengjun", "#gaizhengjunfuzhu")
gai_liaohua= sgs.General(extension_gai, "gai_liaohua", "shu", 4, true)
gaidangxian = sgs.CreateTriggerSkill{
	name = "gaidangxian" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
	if player:getPhase() == sgs.Player_RoundStart then
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
		room:loseHp(player,1)
		local cards={}
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		if #cards>0 then
		room:obtainCard(player, cards[math.random(1,#cards)], false)	
		end
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
			thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		end
end
}
gaidangxia = sgs.CreateTriggerSkill{
	name = "gaidangxia" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart and player:askForSkillInvoke("gaidangxian", data) then
		local room = player:getRoom()
		room:broadcastSkillInvoke("gaidangxian", math.random(1,2))
		room:loseHp(player,1)
		local cards={}
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		if #cards>0 then
		room:obtainCard(player, cards[math.random(1,#cards)], false)	
		end
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
			thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		end
end
}
gai_liaohua:addSkill(gaidangxian)
gaifuli = sgs.CreateTriggerSkill{
	name = "gaifuli" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.AskForPeaches} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				room:removePlayerMark(player, "@gaifuli")
                room:recover(player, sgs.RecoverStruct(player, nil, getKingdoms(player) - player:getHp()))
                player:drawCards(getKingdoms(player) - player:getHandcardNum())
			local skill = sgs.Sanguosha:getTriggerSkill("gaidangxia")
		if skill then room:getThread():addTriggerSkill(skill) end
		   player:addSkill("gaidangxia")
           room:attachSkillToPlayer(player, "gaidangxia")
		room:detachSkillFromPlayer(player, "gaidangxian", true)
		room:detachSkillFromPlayer(player, "gaidangxian", true)
		room:detachSkillFromPlayer(player, "gaidangxian", true)
				if getKingdoms(player)>=3 then
				player:turnOver()
	end
	end
	end ,
can_trigger = function(self, target)
	return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getMark("@gaifuli") > 0)
end
}
gaifulist = sgs.CreateTriggerSkill{
	name = "#@gaifulist" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@gaifuli", 1)
end
}
gai_liaohua:addSkill(gaifuli)
gai_liaohua:addSkill(gaifulist)
extension:insertRelatedSkills("gaifuli", "#@gaifulist")

gai_liuyu = sgs.General(extension_gai, "gai_liuyu", "qun", 2,true)
gaizhigeCard = sgs.CreateSkillCard{
	name = "gaizhige",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:inMyAttackRange(sgs.Self) and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
		       room:addPlayerMark(effect.from, self:objectName().."i")--一样还是ai辅助emmmm
				local card = room:askForCard(effect.to, "Slash,Weapon", "@gaizhige", sgs.QVariant(), sgs.Card_MethodNone)
				room:removePlayerMark(effect.from, self:objectName().."i")
				room:obtainCard(effect.from, card, false)
				if not card then
				local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if effect.to:inMyAttackRange(p) and effect.to:canSlash(p, nil, false) and p:objectName()~=effect.from:objectName() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
			local to = room:askForPlayerChosen(effect.from, players, self:objectName(), self:objectName().."-invoke", true, true)
				if to then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, effect.to, to))
		end
			end
		end
	end
}
gaizhige = sgs.CreateZeroCardViewAsSkill{
	name = "gaizhige",
	view_as = function()
		return gaizhigeCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gaizhige")
	end
}
gai_liuyu:addSkill(gaizhige)
gaizongzuo = sgs.CreateTriggerSkill{
	name = "gaizongzuo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Deathed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:sendCompulsoryTriggerLog(player, self:objectName())
				room:gainMaxHp(player, getKingdoms(player))
				room:recover(player, sgs.RecoverStruct(player, nil, getKingdoms(player)))
		elseif event == sgs.Deathed then
			local death = data:toDeath()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if death.who:getKingdom() == p:getKingdom() then return false end
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if RIGHT(self, p) then
					room:broadcastSkillInvoke(self:objectName(), 2)
						room:loseMaxHp(p)
                        p:drawCards(2,self:objectName())
				end
	end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
gai_liuyu:addSkill(gaizongzuo)
gai_zhuran = sgs.General(extension_gai, "gai_zhuran", "wu", 4,true)
gaidanshouf = sgs.CreateTriggerSkill{
			name = "#gaidanshouf" ,
			events = {sgs.TargetConfirmed} , 
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
					local use = data:toCardUse()
					if not use.card:isKindOf("SkillCard") and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and use.to:contains(player) then
					room:addPlayerMark(player, "gaidanshou_Play")
					if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and not room:getCurrent():hasFlag(self:objectName()..player:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
               room:getCurrent():setFlags(self:objectName()..player:objectName())
			   room:broadcastSkillInvoke(self:objectName(), 1)
			   player:drawCards(player:getMark("gaidanshou_Play"),self:objectName())
			if self:isFriend(use.from) then
			player:drawCards(player:getMark("gaidanshou_Play"),self:objectName())	
			end
		end
	end
end
}
gaidanshouCard = sgs.CreateSkillCard{
	name = "gaidanshou",
	target_fixed = true,
	mute = true,
     on_use = function(self, room, source, targets)
       for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:getMark("gaidanshoui")>0 then
			room:damage(sgs.DamageStruct(self:objectName(), source,p , 1))
		end
	end
	end
}
gaidanshouVS = sgs.CreateViewAsSkill{
	name = "gaidanshou",
	n = 999,
	response_pattern = "@@gaidanshou",
  view_filter = function(self, selected, to_select)
		return  #selected==sgs.Self:getMark("gaidanshouo")
	end,
	view_as = function(self, cards)
	if #cards~=sgs.Self:getMark("gaidanshouo") then return nil end
	local gaidanshouCard = gaidanshouCard:clone()
		for _,card in pairs(cards) do
			gaiyaomingCard:addSubcard(card)
		end
	gaiyaomingCard:setSkillName(self:objectName())
				return gaidanshouCard
		end,
}
gaidanshou = sgs.CreateTriggerSkill{
	name = "gaidanshou",
	events = {sgs.EventPhaseEnd},
	view_as_skill =gaidanshouVS, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
		local room = player:getRoom()	
	for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
		local x=player:getHandcardNum()
		    room:addPlayerMark(player, "gaidanshoui")
			if x>0 then
			room:setPlayerMark(p, "gaidanshouo",x)
		end
			ruszatxa=x
			if p:getHandcardNum()+p:getEquips():length()>=x and not room:getCurrent():hasFlag("gaidanshou"..p:objectName())  and  room:askForUseCard(p, "@@gaidanshou", "@gaidanshou") then
			room:broadcastSkillInvoke("gaidanshou", 2)
		end
	    room:removePlayerMark(p, "gaidanshouo",player:getMark("gaidanshouo"))
		room:removePlayerMark(player,"gaidanshoui")
		end
	end
end,
	can_trigger = function(self, target)
		return target
end
}
gai_zhuran:addSkill(gaidanshou)
gai_zhuran:addSkill(gaidanshouf)
extension:insertRelatedSkills("gaidanshou", "#gaidanshouf")
xingexuan = sgs.General(extension, "xingexuan", "wu", 3,true)
xinlianhua = sgs.CreateTriggerSkill{
	name = "xinlianhua",
	events = {sgs.Damaged, sgs.EventPhaseStart,sgs.EventPhaseEnd},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
	if event == sgs.Damaged and data:toDamage().to:objectName()~=p:objectName() and p:getPhase() == sgs.Player_NotActive then
	p:gainMark("@danxibiaojix")
	room:broadcastSkillInvoke(self:objectName(),2)
	if p:getSmartAI():isFriend(player) then
		room:addPlayerMark(p, "xinlianhuaRed")
	else
		room:addPlayerMark(p, "xinlianhuaBlack")
		end
		end
	if  event == sgs.EventPhaseStart then
	if p:getPhase() == sgs.Player_Start then
		room:broadcastSkillInvoke(self:objectName(),1)
           if p:getMark("@danxibiaojix")<=3  then
				local cards={}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Peach") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		if #cards>0 then
		room:obtainCard(p, cards[math.random(1,#cards)], false)	
		end
		room:addPlayerMark(p, self:objectName().."yingzi")
		room:handleAcquireDetachSkills(p, "yingzi", true)
	else
		 if  p:getMark("xinlianhuaRed")== p:getMark("xinlianhuaBlack") then
						local cards={}
						local cardx={}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			if sgs.Sanguosha:getCard(id):isKindOf("Duel") then
				table.insert(cardx, sgs.Sanguosha:getCard(id))
				end	
			end
		if #cards>0 then
		room:obtainCard(p, cards[math.random(1,#cards)], false)
		end
		if #cardx>0 then
		room:obtainCard(p, cardx[math.random(1,#cardx)], false)
		end
	room:addPlayerMark(p, self:objectName().."gongxin")
		room:handleAcquireDetachSkills(p, "gongxin", true)
	else
		if  p:getMark("xinlianhuaRed")> p:getMark("xinlianhuaBlack") then
						local cards={}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("ExNihilo") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		if #cards>0 then
		room:obtainCard(p, cards[math.random(1,#cards)], false)	
		end
		room:addPlayerMark(p, self:objectName().."guanxing")
		room:handleAcquireDetachSkills(p, "guanxing", true)
else
	  			local cards={}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Snatch") then
				table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		if #cards>0 then
		room:obtainCard(p, cards[math.random(1,#cards)], false)	
		end
		room:addPlayerMark(p, self:objectName().."zhiyan")
		room:handleAcquireDetachSkills(p, "zhiyan", true)
		    end
		end
			end
		room:removePlayerMark(p, "@danxibiaojix",p:getMark("@danxibiaojix"))
        room:removePlayerMark(p, "xinlianhuaRed",p:getMark("xinlianhuaRed"))
         room:removePlayerMark(p, "xinlianhuaBlack",p:getMark("xinlianhuaBlack"))   	
					end
end
		if event == sgs.EventPhaseEnd and p:getPhase() == sgs.Player_Finish then
		for _, skill in sgs.qlist(p:getVisibleSkillList()) do
	      if p:getMark(self:objectName()..skill:objectName())>0 then
		room:removePlayerMark(p, self:objectName()..skill:objectName())
		room:handleAcquireDetachSkills(p, "-"..skill:objectName(), true)
		end
		end
end
	end
	end,
	can_trigger = function(self, target)
		return target
	end
}
xinlifuCard = sgs.CreateSkillCard{
	name = "xinlifu",
	filter = function(self, targets, to_select)
		return #targets ==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	room:handleAcquireDetachSkills(source, "#xinlifushiqu", true)
	room:addPlayerMark(targets[1], source:objectName()..self:objectName())
	room:removePlayerMark(source, "@xinlifus",1)
	room:addPlayerMark(source, targets[1]:objectName()..self:objectName().."i")
end
}
xinlifuVS = sgs.CreateZeroCardViewAsSkill{
	name = "xinlifu",
	view_as = function()
		return xinlifuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@xinlifus")>0
	end
}
xinlifu = sgs.CreateTriggerSkill{
	name = "xinlifu",
	view_as_skill = xinlifuVS,
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
	    if   player:getMark(p:objectName().."xinlifu")>0 then
		if not player:isKongcheng() then
		local cards=room:askForExchange(player, self:objectName(), 1, 1, true, "xinlifux-y",false, ".|.|.|hand")	
					local ids = sgs.IntList()
	for _, card in sgs.list(player:getHandcards()) do
	if sgs.Sanguosha:getCard(cards:getSubcards():first()):getEffectiveId()~=card:getEffectiveId() then
	ids:append(card:getEffectiveId())
	end
	end
		local dummy = sgs.Sanguosha:cloneCard("slash") 
        dummy:addSubcards(ids)
		for _, sun in sgs.qlist(room:getAlivePlayers()) do
		if sun:getMark(player:objectName().."xinlifui")>0 then
		room:obtainCard(sun, dummy, false)
		room:removePlayerMark(sun, player:objectName().."xinlifui",1)
		if sun:getMark("xinlifushiqu")>0 then
		   room:detachSkillFromPlayer(sun, "xinlifu", true)
			room:detachSkillFromPlayer(sun, "xinlifu", true)
			room:detachSkillFromPlayer(sun, "xinlifu", true)
		   room:detachSkillFromPlayer(sun, "#xinlifushiqu", true)
			room:detachSkillFromPlayer(sun, "#xinlifushiqu", true)
			room:detachSkillFromPlayer(sun, "#xinlifushiqu", true)
			room:removePlayerMark(sun, "xinlifushiqu",sun:getMark("xinlifushiqu"))
		end
			end
	end
		room:removePlayerMark(player, p:objectName().."xinlifu",1)
	else
		room:removePlayerMark(player, p:objectName().."xinlifu",1)
		end
			end
		end
	end
end,
	can_trigger = function(self, target)
		return target
	end
}
xinlifustart = sgs.CreateTriggerSkill{
	name = "#xinlifustart",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.GameStart},
		on_trigger = function(self, event, player, data)
			player:gainMark("@xinlifus")
		end
}
xinlifushiqu = sgs.CreateTriggerSkill{
	name = "#xinlifushiqu",
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	local xx=nil
			for _, sun in sgs.qlist(room:getAlivePlayers()) do
		if sun:getMark(player:objectName().."xinlifu")>0 then
        xx=sun
			end
	end
		if  data:toString() == "xinlifu" and xx~=nil and player:getMark(xx:objectName().."xinlifui")>0 then
			local skill = sgs.Sanguosha:getTriggerSkill("xinlifu")
               if skill then room:getThread():addTriggerSkill(skill) end
					player:addSkill("xinlifu")
                room:attachSkillToPlayer(player, "xinlifu")  
				room:addPlayerMark(player, "xinlifushiqu")
             room:handleAcquireDetachSkills(player, "#xinlifushiqu", true)
					end
		end
}
xingexuan:addSkill(xinlifustart)
xingexuan:addSkill(xinlianhua)
xingexuan:addSkill(xinlifu)
xingexuan:addSkill(xinlifushiqu)
xingexuan:addRelateSkill("yingzi")
xingexuan:addRelateSkill("guanxing")
xingexuan:addRelateSkill("zhiyan")
xingexuan:addRelateSkill("gongxin")
extension:insertRelatedSkills("xinlifu", "#xinlifustart")
xinguanlu = sgs.General(extension, "xinguanlu", "wei", 3,true)
xintuiyan = sgs.CreateTriggerSkill{
	name = "xintuiyan",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
				local list = room:getNCards(2)
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local cards={list:first(),list:last()}--帮助电脑认识头两张牌（简称ai外挂）
				room:setPlayerProperty(player,self:objectName(),sgs.QVariant(table.concat(cards,"+")))
				room:fillAG(list, player)
				if room:askForExchange(player, self:objectName(), 0, 0, false, "tuiyangguankan",false) then
				room:moveCardTo(sgs.Sanguosha:getCard(list:last()), player, sgs.Player_DrawPile,false)
				room:moveCardTo(sgs.Sanguosha:getCard(list:first()), player, sgs.Player_DrawPile,false)
				room:clearAG(player)
		end
		end
	end
}
xinguanlu:addSkill(xintuiyan)
xinmingjie = sgs.CreateTriggerSkill {
	name = "xinmingjie",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EventPhaseStart then
		if  player:getPhase() == sgs.Player_Finish then
		for i=1,3 do
		if player:getMark("xinmingjiei")==0 and room:askForSkillInvoke(player, self:objectName(),data) then
         player:drawCards(1,self:objectName())
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
	else
		room:removePlayerMark(player, "xinmingjiei")
		break
		end
		end
	end
    else
		local move = data:toMoveOneTime()
		if move.reason.m_skillName == self:objectName() and move.to:objectName()==player:objectName() then
		for _, id in sgs.qlist(move.card_ids) do
         if sgs.Sanguosha:getCard(id):isBlack() then
		 room:loseHp(player)
		 room:addPlayerMark(player, "xinmingjiei")
			end	
			end
		end
	end
	end
}
xinguanlu:addSkill(xinmingjie)
xinpusuanCard = sgs.CreateSkillCard{
	name = "xinpusuan",
	filter = function(self, targets, to_select)
		return #targets ==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
local ban_list,choices = {},sgs.IntList()
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and not table.contains(ban_list, card:objectName()) then
					if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
						table.insert(ban_list, card:objectName())
					end
				end
			end
			local announce_table = {}
			for _,name in ipairs(ban_list) do
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if card:objectName() == name and card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
						if not table.contains(announce_table, card:objectName()) then
							table.insert(announce_table, card:objectName())
							choices:append(i)
						end
					end
				end
			end
		local cards={}
		local cardx={}
		local x=false
	      for i=1,2 do
		  room:addPlayerMark(targets[1], self:objectName().."i")
			room:fillAG(choices,source)
			if i==2 then
			x=true
			end
			local id=room:askForAG(source,choices,x,self:objectName())
			room:clearAG(source)
			if id ~= -1 then
			table.insert(cards,sgs.Sanguosha:getCard(id):objectName())
			table.insert(cardx,id)
			choices:removeOne(id)
	    end
	end
			local log = sgs.LogMessage()
			log.type = "$xinpusuanxuanze"
			log.from = source
			log.to:append(targets[1])
			log.card_str = table.concat(cardx,"+")
			room:sendLog(log)
	room:setPlayerProperty(targets[1],self:objectName(),sgs.QVariant(table.concat(cards,"+")))
	room:removePlayerMark(targets[1], self:objectName().."i",2)
end
}
xinpusuanVS = sgs.CreateZeroCardViewAsSkill{
	name = "xinpusuan",
	view_as = function()
		return xinpusuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#xinpusuan")
	end
}
xinpusuan = sgs.CreateTriggerSkill{
	name = "xinpusuan",
	view_as_skill = xinpusuanVS,
	priority = -5 ,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		local cardi=player:property("xinpusuan"):toString():split("+")
		if player:getPhase() == sgs.Player_Draw and #cardi>0 then
			local cards={}
			local x=1
			local ids = sgs.IntList()
			local ys = sgs.IntList()
				for _, id in sgs.qlist(room:getDiscardPile()) do
				ys:append(id)
			end	
				for _, id in sgs.qlist(room:getDrawPile()) do
				ys:append(id)
			end	
		for _, id in sgs.qlist(ys) do
		if sgs.Sanguosha:getCard(id):objectName()==cardi[x] then
		if #cardi>1 then
		x=x+1
		end
		ids:append(id)
		if x>2 or #cardi==1 then
		break
		end
		end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(ids)
		room:obtainCard(player, dummy,true)
		room:setPlayerProperty(player,self:objectName(),sgs.QVariant(nil))
		room:sendCompulsoryTriggerLog(player, self:objectName())
				return true	
	end
end,
	can_trigger = function(self, target)
		return target
	end
}
xinguanlu:addSkill(xinpusuan)
gai_guohuai = sgs.General(extension_gai, "gai_guohuai", "wei", 4,true)
gaijingce = sgs.CreateTriggerSkill{
	name = "gaijingce" ,
		events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
		frequency = sgs.Skill_Frequent ,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if ((event == sgs.PreCardUsed) or (event == sgs.CardResponded)) and (player:getPhase() <= sgs.Player_Play) then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					local response = data:toCardResponse()
					if response.m_isUse then
						card = response.m_card
					end
				end
				if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
					player:addMark(self:objectName())
				end
			elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart) then
				player:setMark(self:objectName(), 0)
			elseif event == sgs.EventPhaseEnd then
				if (player:getPhase() == sgs.Player_Finish) and (player:getMark(self:objectName()) >= player:getHp()) then
					if room:askForSkillInvoke(player, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						player:drawCards(2)
					end
				end
			end
		return false
	end
}
gai_guohuai:addSkill(gaijingce)
gai_manchong = sgs.General(extension_gai, "gai_manchong", "wei", 3,true)
gaijunxingCard = sgs.CreateSkillCard{
		name = "gaijunxing" ,
		filter = function(self, targets, to_select)
			return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
		end ,
		on_use = function(self, room, source, targets)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			local target = targets[1]
			if not target:isAlive() then return end
			local type_name = {"BasicCard", "TrickCard", "EquipCard"}
			local types = {"BasicCard", "TrickCard", "EquipCard"}
			for _, id in sgs.qlist(self:getSubcards()) do
				local c = sgs.Sanguosha:getCard(id)
				table.removeOne(types,type_name[c:getTypeId()])
				if #types == 0 then break end
			end
			if (not target:canDiscard(target, "h")) or #types == 0 then
				target:turnOver()
				target:drawCards(4-target:getHandcardNum(), "gaijunxing")
			elseif not room:askForCard(target, table.concat(types, ",") .. "|.|.|hand", "@gaijunxing-discard") then
				target:turnOver()
				target:drawCards(4-target:getHandcardNum(), "gaijunxing")
			end
	end
}
gaijunxing = sgs.CreateViewAsSkill{
		name = "gaijunxing" ,
		n = 999 ,
		view_filter = function(self, selected, to_select)
			return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		end ,
		view_as = function(self, cards)
			if #cards == 0 then return nil end
			local card = gaijunxingCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			card:setSkillName(self:objectName())
			return card
		end ,
		enabled_at_play = function(self, player)
			return player:canDiscard(player, "h") and (not player:hasUsed("#gaijunxing"))
	end
}
gai_manchong:addSkill(gaijunxing)
gai_manchong:addSkill("yuce")
gai_xinxianying = sgs.General(extension_gai, "gai_xinxianying", "wei", 3,false)
gaizhongjianCard = sgs.CreateSkillCard{
	name = "gaizhongjian",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
        for _, sd in sgs.qlist(self:getSubcards()) do
            room:showCard(source, sd)
        end
		local ys = sgs.IntList()
		local ids = getIntList(targets[1]:getHandcards())
		for i = 1, source:getMark("gaizhongjianzs")+3 do
            local id = ids:at(math.random(0, ids:length() - 1))
            room:showCard(targets[1], id)
            ids:removeOne(id)
            ys:append(id)
        end
        for _, id in sgs.qlist(ys) do
            local suit, num,butong = false, false,false
            for _, sd in sgs.qlist(self:getSubcards()) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(sd):getSuit() then suit = true end
				if sgs.Sanguosha:getCard(id):getNumber() == sgs.Sanguosha:getCard(sd):getNumber() then num = true end
				if sgs.Sanguosha:getCard(id):getNumber() ~= sgs.Sanguosha:getCard(sd):getNumber()and sgs.Sanguosha:getCard(id):getSuit() ~= sgs.Sanguosha:getCard(sd):getSuit() then butong = true end
                if suit then
                    source:drawCards(1)
                end
                if num then
                 room:damage(sgs.DamageStruct(self:objectName(),source, targets[1], 1))
                end
                if butong then
                room:askForDiscard(source, self:objectName(), 1, 1, false,false)
                end
		end
	end
end
}
gaizhongjian = sgs.CreateViewAsSkill{
	name = "gaizhongjian",
	n=999,
	view_filter = function(self, selected, to_select)
		return #selected<sgs.Self:getMark("gaizhongjiansz")+1  and not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards>0 then
		local card = gaizhongjianCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			card:setSkillName(self:objectName())
			return card
	end
		end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gaizhongjian") and not player:isKongcheng() and player:getMark("gaizhongjian")==0
	end
}
gaicaishi = sgs.CreatePhaseChangeSkill{
	name = "gaicaishi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
				local choice = room:askForChoice(player, self:objectName(), "xuanzembyz+xuanzezjyz+mopai2")
			if choice == "xuanzembyz" then
			sgs.Sanguosha:addTranslationEntry(":gaizhongjian", ""..string.gsub(sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian1"),4))
			room:addPlayerMark(player, "gaizhongjianzs")
            ChangeCheck(player, "gai_xinxianying")	
			end
			if choice == "xuanzezjyz" then
			sgs.Sanguosha:addTranslationEntry(":gaizhongjian", ""..string.gsub(sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian2")))
			room:addPlayerMark(player, "gaizhongjiansz")
            ChangeCheck(player, "gai_xinxianying")
			end
			if choice == "mopai2" then
			room:addPlayerMark(player, "gaizhongjian")
			player:drawCards(2)
			end
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
		local log = sgs.LogMessage()
			log.type = "$xuanzeyixia"..choice..""
			log.from = player
			room:sendLog(log)
    end
	end
}
gaicaishis = sgs.CreateTriggerSkill{
	name = "#gaicaishis",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			if  player:getPhase() == sgs.Player_Finish then
				sgs.Sanguosha:addTranslationEntry(":gaizhongjian", ""..string.gsub(sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian"), sgs.Sanguosha:translate(":gaizhongjian4")))
				ChangeCheck(player, "gai_xinxianying")
				room:removePlayerMark(player, "gaizhongjianzs",player:getMark("gaizhongjianzs"))
				room:removePlayerMark(player, "gaizhongjiansz",player:getMark("gaizhongjiansz"))
				room:removePlayerMark(player, "gaizhongjian",player:getMark("gaizhongjian"))
			end			
	end
}
gai_xinxianying:addSkill(gaicaishis)
gai_xinxianying:addSkill(gaizhongjian)
gai_xinxianying:addSkill(gaicaishi)
extension:insertRelatedSkills("gaicaishi", "#gaicaishis")

gai_quancong = sgs.General(extension_gai, "gai_quancong", "wu", 4, true)
gaiyaomingCard = sgs.CreateSkillCard{
	name = "gaiyaoming",
	target_fixed = true,
	mute = true,
     on_use = function(self, room, source, targets)
				if source:isAlive() and self:subcardsLength()>0 then
					room:drawCards(source, self:subcardsLength(), "gaiyaoming")
				end
	end
}
gaiyaomingVS = sgs.CreateViewAsSkill{
	name = "gaiyaoming",
	n = 2,
	response_pattern = "@@gaiyaoming!",
  view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select) and not to_select:isEquipped()
			end,
	view_as = function(self, cards)
	local gaiyaomingCard = gaiyaomingCard:clone()
		for _,card in pairs(cards) do
			gaiyaomingCard:addSubcard(card)
		end
	gaiyaomingCard:setSkillName(self:objectName())
				return gaiyaomingCard
		end,
}
gaiyaoming = sgs.CreateTriggerSkill{
	name = "gaiyaoming",
	events = {sgs.Damage, sgs.Damaged},
	view_as_skill =gaiyaomingVS, 
	on_trigger = function(self, event, player, data, room)
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName()~=player:objectName() then
			if  (not room:getCurrent():hasFlag(self:objectName().."i"..player:objectName()) and p:getHandcardNum() == player:getHandcardNum()) or (not room:getCurrent():hasFlag(self:objectName().."o"..player:objectName()) and p:getHandcardNum() < player:getHandcardNum()) or (not room:getCurrent():hasFlag(self:objectName()..player:objectName()) and p:getHandcardNum() > player:getHandcardNum()) then
				players:append(p)
			end
		end
		end
            if players:length()>0 then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "yaoming-invoke", true, true)
			if target then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				if target:getHandcardNum() > player:getHandcardNum() then
					room:getCurrent():setFlags(self:objectName()..player:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					local to_throw = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
			elseif target:getHandcardNum() < player:getHandcardNum() then
				   room:getCurrent():setFlags(self:objectName().."o"..player:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
						target:drawCards(1)
			elseif target:getHandcardNum() == player:getHandcardNum() then
				   room:getCurrent():setFlags(self:objectName().."i"..player:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
              room:askForUseCard(player, "@@gaiyaoming!", "@gaiyaoming")--本来想用选牌，但是选牌不支持0牌....
              room:askForUseCard(target, "@@gaiyaoming!", "@gaiyaoming")	
		end
		end
	end
	end
}
gai_quancong:addSkill(gaiyaoming)
mobile_baosanniang = sgs.General(extension_gai, "mobile_baosanniang", "shu", 3, false)--感谢惑神
sgs.LoadTranslationTable{
	["mobile_baosanniang"] = "鲍三娘",
	["#mobile_baosanniang"] = "清不协扶",
	["~mobile_baosanniang"] = "我还想与你…共骑这雪花骏",
	
}

shuyong = sgs.CreateTriggerSkill{
	name = "shuyong",
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardUsed and data:toCardUse().card:isKindOf("Slash")) or (event == sgs.CardResponded and data:toCardResponse().m_card:isKindOf("Slash")) then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isAllNude() then targets:append(p) end
			end
			if not targets:isEmpty() then
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "shuyong-invoke", true, true)
				if to then
					local id = room:askForCardChosen(player, to, "hej", self:objectName())
					if id ~= -1 then
						room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
						room:obtainCard(player, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
						to:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}
mobile_baosanniang:addSkill(shuyong)
sgs.LoadTranslationTable{
	["shuyong"] = "姝勇",
	[":shuyong"] = "当你使用或打出【杀】时，你可以获得一名其他角色区域里的一张牌，然后其摸一张牌。",
	["$shuyong1"] = "虽为女子身，不输男儿郎。",
	["$shuyong2"] = "剑舞轻影，沙场克敌。",
	["shuyong-invoke"] = "姝勇：你可以获得一名其他角色区域里的一张牌，然后其摸一张牌",
	
}

mobile_xushenCard = sgs.CreateSkillCard{
	name = "mobile_xushen",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@m_xushen")
		local n = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isMale() then n = n + 1 end
		end
		room:setPlayerFlag(source, "xushen_used")
		room:loseHp(source, n)
		room:setPlayerFlag(source, "-xushen_used")
	end
}
mobile_xushenVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_xushen",
	view_as = function(self)
		return mobile_xushenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@m_xushen") > 0
	end
}
mobile_xushen = sgs.CreateTriggerSkill{
	name = "mobile_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@m_xushen",
	view_as_skill = mobile_xushenVS,
	events = {sgs.HpRecover, sgs.QuitDying},
	on_trigger = function(self, event, player, data, room)
		if not player:hasFlag("xushen_used") then return false end
		if event == sgs.HpRecover then
			local saver = data:toRecover().who
			if player:getHp() > 0 then
				room:setPlayerFlag(saver, "xushen_saver")
			end
		else
			local saver = nil
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("xushen_saver") then
					room:setPlayerFlag(p, "-xushen_saver")
					saver = p
					break
				end
			end
			if saver and saver:isAlive() then
				if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("xushen_gift::" .. saver:objectName())) then return false end
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), saver:objectName())
				room:handleAcquireDetachSkills(saver, "wusheng|dangxian")
			end
		end
		return false
	end
}
mobile_baosanniang:addSkill(mobile_xushen)
sgs.LoadTranslationTable{
	["mobile_xushen"] = "许身",
	[":mobile_xushen"] = "限定技，出牌阶段，你可以失去等同于存活男性角色数的体力。若你因此进入濒死状态，则当你脱离濒死状态后，你可令使你脱离濒死状态的角色获得“武圣”和“当先”。",
	["$mobile_xushen1"] = "救命之恩，涌泉相报。",
	["$mobile_xushen2"] = "解我危难，报君华彩。",
	["mobile_xushen:xushen_gift"] = "许身：你可以令 %dest 获得技能“武圣”和“当先”",
	
}

mobile_zhennan = sgs.CreateTriggerSkill{
	name = "mobile_zhennan",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("SkillCard") then return false end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if use.from and use.from:isAlive() and use.to and use.to:contains(p) and use.to:length() > 1 and use.to:length() > use.from:getHp() and not p:isNude() then
				if not room:askForCard(p, "..", "@m_zhennan-discard::" .. use.from:objectName(), data, self:objectName()) then return false end
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, p:objectName(), use.from:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), p, use.from))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
mobile_baosanniang:addSkill(mobile_zhennan)
sgs.LoadTranslationTable{
	["mobile_zhennan"] = "镇南",
	[":mobile_zhennan"] = "当一张牌指定包括你在内的多名角色为目标后，若其目标数大于其使用者的体力值，你可以弃置一张牌，然后对使用者造成1点伤害。",
	["$mobile_zhennan1"] = "镇守南中，夫君无忧。",
	["$mobile_zhennan2"] = "与君携手，定平蛮夷。",
	["@m_zhennan-discard"] = "镇南：你可以弃置一张牌，对 %dest 造成1点伤害",
	
}

beyond_dengai = sgs.General(extension_jie, "beyond_dengai", "wei", 4)
sgs.LoadTranslationTable{
	["beyond_dengai"] = "界邓艾",
	["&beyond_dengai"] = "邓艾",
	["#beyond_dengai"] = "矫然的壮士",
	["~beyond_dengai"] = "吾破蜀克敌，竟葬于奸贼之手！",
	
}

beyond_tuntian = sgs.CreateTriggerSkill{
	name = "beyond_tuntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))
				and player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, self:objectName() .. "engine")
				if player:getMark(self:objectName() .. "engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					room:removePlayerMark(player, self:objectName() .. "engine")
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason == self:objectName() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				if judge:isGood() then
					if sgs.GetConfig("heg_skill", true) and not room:askForSkillInvoke(player, self:objectName(), data) then return false end
					player:addToPile("field", judge.card:getEffectiveId())
				elseif judge.card:getSuit() == sgs.Card_Heart then
					player:obtainCard(judge.card)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_NotActive and target:hasSkill(self:objectName())
	end
}
beyond_tuntianDistance = sgs.CreateDistanceSkill{
	name = "#beyond_tuntian-distance",
	correct_func = function(self, from, to)
		if from:hasSkill("beyond_tuntian") then
			return -from:getPile("field"):length()
		end
		return 0
	end
}
beyond_dengai:addSkill(beyond_tuntian)
beyond_dengai:addSkill(beyond_tuntianDistance)
extension:insertRelatedSkills("beyond_tuntian", "#beyond_tuntian-distance")
sgs.LoadTranslationTable{
	["beyond_tuntian"] = "屯田",
	[":beyond_tuntian"] = "当你于回合外失去牌后，你可以判定，若结果：不为红桃，你将判定牌置于你的武将牌上，称为“田”；为红桃，你获得判定牌。你计算与其他角色的距离-X（X为“田”的数量）。",
	["$beyond_tuntian1"] = "休养生息，备战待敌。",
	["$beyond_tuntian2"] = "锄禾日当午，汗滴禾下土。",
	
}

beyond_dengai:addSkill("zaoxian")
beyond_dengai:addRelateSkill("jixi")

beyond_caiwenji = sgs.General(extension_jie, "beyond_caiwenji", "qun", 3, false)
sgs.LoadTranslationTable{
	["beyond_caiwenji"] = "界蔡文姬",
	["&beyond_caiwenji"] = "蔡文姬",
	["#beyond_caiwenji"] = "异乡的孤女",
	["~beyond_caiwenji"] = "人生几何时，怀忧终年岁……",
	
}

beyond_beige = sgs.CreateTriggerSkill{
	name = "beyond_beige",
	events = {sgs.Damaged, sgs.FinishJudge},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not (damage.card and damage.card:isKindOf("Slash")) or damage.to:isDead() then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:canDiscard(p, "he") and room:askForCard(p, "..", "@beyond_beige::" .. player:objectName(), data, self:objectName()) then
					room:addPlayerMark(p, self:objectName() .. "engine")
					if p:getMark(self:objectName() .. "engine") > 0 then
						local judge = sgs.JudgeStruct()
						judge.good = true
						judge.play_animation = false
						judge.who = player
						judge.reason = self:objectName()
						room:judge(judge)
						local suit = tonumber(judge.pattern)
						local index = 1
						if suit == sgs.Card_Heart then
							room:doAnimate(1, p:objectName(), player:objectName())
							index = 4
							room:recover(player, sgs.RecoverStruct(p, nil, damage.damage))
						elseif suit == sgs.Card_Diamond then
							room:doAnimate(1, p:objectName(), player:objectName())
							index = 3
							player:drawCards(3, self:objectName())
						elseif suit == sgs.Card_Club then
							room:doAnimate(1, p:objectName(), damage.from:objectName())
							if damage.from and damage.from:isAlive() then
								room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
							end
						elseif suit == sgs.Card_Spade then
							room:doAnimate(1, p:objectName(), damage.from:objectName())
							index = 2
							if damage.from and damage.from:isAlive() then
								damage.from:turnOver()
							end
						end
						room:broadcastSkillInvoke(self:objectName(), sgs.GetConfig("music", true) and nil or index)
						room:removePlayerMark(p, self:objectName() .. "engine")
                    end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getSuit())
			data:setValue(judge)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
beyond_caiwenji:addSkill(beyond_beige)
sgs.LoadTranslationTable{
	["beyond_beige"] = "悲歌",
	[":beyond_beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，然后令其判定。若结果为：红桃，其回复X点体力（X为伤害值）；方块，其摸三张牌；梅花，伤害来源弃置两张牌；黑桃，伤害来源翻面。",
	["$beyond_beige1"] = "制兹八拍兮拟排忧，何知曲成兮心转愁。",
	["$beyond_beige2"] = "悲歌可以当泣，远望可以当归。",
	["@beyond_beige"] = "悲歌：你可以弃置一张牌，令 %dest 判定，然后执行与判定结果对应的效果",
	
}

beyond_caiwenji:addSkill("duanchang")

xin_lixiao = sgs.General(extension, "xin_lixiao", "qun", 2, true)
xin_lixun = sgs.CreateTriggerSkill{
	name = "xin_lixun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
    if event==sgs.DamageInflicted then
		local damage = data:toDamage()
		player:gainMark("@lixiao_zhu", damage.damage)
				damage.damage = 0
		data:setValue(damage)
		return true
else
	if player:getPhase() == sgs.Player_Play then
		local x=player:getMark("@lixiao_zhu")
		if x>0 then
		local judge = sgs.JudgeStruct()
		if x==1 then
		judge.pattern = ".|.|A|."
	else
		judge.pattern = ".|.|A~"..tostring(x-1).."|."
		end
		judge.good = false
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
        if not judge:isGood() then			
		local cards=room:askForExchange(player, self:objectName(), x, x, false, "@xin_lixun",false)
		local dummy = sgs.Sanguosha:cloneCard("slash") 
        dummy:addSubcards(cards:getSubcards()) 
	    room:throwCard(dummy, player, player)
		if cards:getSubcards():length()<x then
			room:loseHp(player,x-cards:getSubcards():length())
		end
			end
	end
	end
end
end
}
xin_kuizhuCard = sgs.CreateSkillCard{
	name = "xin_kuizhu",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
				room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName().."i")
			else
				room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName().."o")
			end
		end
	end
}
xin_kuizhuVS = sgs.CreateViewAsSkill{
	name = "xin_kuizhu",
	n = 999,
	view_filter = function(self, selected, to_select)
		local x,n=0,0
		 for _, card in ipairs(selected) do
		if card:hasFlag(self:objectName()) then
		n=n+1
        else
        x=x+1	
		end
	end
	    if x==sgs.Self:getMark("kplayer_Num") then
		 return to_select:hasFlag(self:objectName())	
	end	
		if x==sgs.Self:getMark("kplayer_Num") and n==sgs.Self:getMark("kplayer_Num") then
        return false
	else
        return not to_select:isEquipped()
		end
	end,
	response_pattern = "@@xin_kuizhu",
	view_as = function(self, cards)
	local n,x=0,0
		local xin_kuizhu = xin_kuizhuCard:clone()
        for _, card in ipairs(cards) do
		if card:hasFlag(self:objectName()) then
		n=n+1
        else
        x=x+1	
		end	
		if x>0 and n>0 and x==n then
	    		for _, c in ipairs(cards) do
			xin_kuizhu:addSubcard(c)
		end
	    return xin_kuizhu
		end
			end
	end
}
xin_kuizhu = sgs.CreateTriggerSkill{
	name = "xin_kuizhu",
	view_as_skill = xin_kuizhuVS,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
	if player:getPhase() == sgs.Player_Play then
	local n = room:getAlivePlayers():first():getHp()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				n = math.max(n, p:getHp())
			end
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() == n then
					targets:append(p)
				end
			end
			local to = room:askForPlayerChosen(player, targets, self:objectName(), "xin_kuizhu-invoke", true, true)
			if to then
		    local x=math.min(5,to:getHandcardNum())-player:getHandcardNum()
			if x>0 then
             player:drawCards(x,self:objectName())
		end
		local GroupId={}
				local ids = sgs.IntList()
		    for _, card in sgs.list(player:getHandcards()) do
			ids:append(card:getId())
			table.insert(GroupId,tostring(card:getEffectiveId()))
			room:setCardFlag(card:getEffectiveId(), self:objectName())
			end
		    room:setTag("kuizhu_give_cards_id_list", sgs.QVariant(table.concat(GroupId,"+")))
			local _guojia = sgs.SPlayerList()
			_guojia:append(to)
			local move_to = sgs.CardsMoveStruct(ids, player, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves_to = sgs.CardsMoveList()
			moves_to:append(move_to)
			room:notifyMoveCards(true, moves_to, false, _guojia)
			room:notifyMoveCards(false, moves_to, false, _guojia)
			room:addPlayerMark(player, "useplayer",1)
			room:addPlayerMark(to, "useplayeri",1)
			room:addPlayerMark(to, "kplayer_Num",player:getHandcardNum())
			local use=room:askForUseCard(to, "@@xin_kuizhu", "@xin_kuizhu")
			room:setTag("kuizhu_give_cards_id_list", sgs.QVariant(nil))
			room:setPlayerMark(to, "kplayer_Num",0)
			room:setPlayerMark(player, "useplayer",0)
			room:setPlayerMark(player, "useplayeri",0)
			local move = sgs.CardsMoveStruct(ids, to, player, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false,  _guojia)
			room:notifyMoveCards(false, moves, false,  _guojia)
			if use then
           local dummy = sgs.Sanguosha:cloneCard("slash")
		    for _, card in sgs.list(player:getHandcards()) do
			if card:hasFlag(self:objectName().."i") then
			dummy:addSubcard(card:getId())
			room:setCardFlag(card, "-"..self:objectName().."i")
			room:setCardFlag(card, "-"..self:objectName())
				end
			end
			local n=0
			room:obtainCard(to,dummy, false)
			local used = sgs.Sanguosha:cloneCard("slash")
			for _, card in sgs.list(to:getHandcards()) do
			if card:hasFlag(self:objectName().."o") then
			used:addSubcard(card:getId())
			n=n+1
			room:setCardFlag(card, "-"..self:objectName().."o")
				end
			end
			room:throwCard(used, to, to)
			if n>1 then
			if room:askForChoice(player, self:objectName(),"shiquzhu+incite")=="shiquzhu" then
			player:loseMark("@lixiao_zhu")
	    else
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if to:inMyAttackRange(p) then
					players:append(p)
				end
			end
			if not players:isEmpty() then
			local target = room:askForPlayerChosen(player, players, self:objectName().."i", self:objectName().."-invokes", true, true)
				if target then
				room:damage(sgs.DamageStruct(self:objectName(), to,target, 1))
			end
				end
				end	
			end
     end
       end
	end
end
}	
xin_lixiao:addSkill(xin_kuizhu)
xin_lixiao:addSkill(xin_lixun)
jie_zuoci = sgs.General(extension_jie, "jie_zuoci", "qun", 3, true)
	local json = require ("json")--照搬的lua化身
	function isNormalGameMode (mode_name)
		return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
	end
	function GetAvailableGenerals(zuoci)
		local all = sgs.Sanguosha:getLimitedGeneralNames()
		local room = zuoci:getRoom()
			if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_")or room:getMode() == "custom_scenario") then
				table.removeTable(all,sgs.GetConfig("Banlist/Roles",""):split(","))
			elseif (room:getMode() == "04_1v3") then
				table.removeTable(all,sgs.GetConfig("Banlist/HulaoPass",""):split(","))
			elseif (room:getMode() == "06_XMode") then
				table.removeTable(all,sgs.GetConfig("Banlist/XMode",""):split(","))
				for _,p in sgs.qlist(room:getAlivePlayers())do
					table.removeTable(all,(p:getTag("XModeBackup"):toStringList()) or {})
				end
			elseif (room:getMode() == "02_1v1") then
				table.removeTable(all,sgs.GetConfig("Banlist/1v1",""):split(","))
				for _,p in sgs.qlist(room:getAlivePlayers())do
					table.removeTable(all,(p:getTag("1v1Arrange"):toStringList()) or {})
				end
			end
			local Huashens = {}
			local Hs_String = zuoci:getTag("jiehuashens"):toString()
			if Hs_String and Hs_String ~= "" then
				Huashens = Hs_String:split("+")
			end
			table.removeTable(all,Huashens)
			for _,player in sgs.qlist(room:getAlivePlayers())do
				local name = player:getGeneralName()
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all,name)	
				if player:getGeneral2() == nil then continue end	
				name = player:getGeneral2Name();
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all,name)
			end	
			local banned = {"zuoci","jie_zuoci", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"}
			table.removeTable(all,banned)	
			return all
	end
	function AcquireGenerals(zuoci, n)
		local room = zuoci:getRoom();
		local Huashens = {}
		local Hs_String = zuoci:getTag("jiehuashens"):toString()
		if Hs_String and Hs_String ~= "" then
			Huashens = Hs_String:split("+")
		end
		local list = GetAvailableGenerals(zuoci)
		if #list == 0 then return end
		n = math.min(n, #list)
		local acquired = {}
		repeat
			local rand = math.random(1,#list)
			if not table.contains(acquired,list[rand]) then
				table.insert(acquired,(list[rand]))
			end
		until #acquired == n		
			for _,name in pairs(acquired)do
				table.insert(Huashens,name)
				localgeneral = sgs.Sanguosha:getGeneral(name)
				if general then
					for _,skill in sgs.list(general:getTriggerSkills()) do
						if skill:isVisible() then
							room:getThread():addTriggerSkill(skill)
						end
					end
				end
			end
			zuoci:setTag("jiehuashens", sgs.QVariant(table.concat(Huashens, "+")))	
			local hidden = {}
			for i = 1,n,1 do
				table.insert(hidden,"unknown")
			end
			for _,p in sgs.qlist(room:getAllPlayers())do
				local splist = sgs.SPlayerList()
				splist:append(p)
				if p:objectName() == zuoci:objectName() then
					room:doAnimate(4, zuoci:objectName(), table.concat(acquired,":"), splist)
				else
					room:doAnimate(4, zuoci:objectName(),table.concat(hidden,":"),splist);
				end
			end	
			local log = sgs.LogMessage()
			log.type = "#GetHuashen"
			log.from = zuoci
			log.arg = n
			log.arg2 = #Huashens
			room:sendLog(log)
			local jsonLog ={
				"#GetHuashenDetail",
				zuoci:objectName(),
				"",
				"",
				table.concat(acquired,"\\, \\"),
				"",
			}
			room:setPlayerMark(zuoci, "@xin_huashen", #Huashens)
	end
	function SelectSkill(zuoci)
		local room = zuoci:getRoom();
		local ac_dt_list = {}
		local huashen_skill = zuoci:getTag("jiehuashenSkill"):toString();
			if huashen_skill ~= "" then
				table.insert(ac_dt_list,"-"..huashen_skill)
			end
			local Huashens = {}
			local Hs_String = zuoci:getTag("jiehuashens"):toString()
			if Hs_String and Hs_String ~= "" then
				Huashens = Hs_String:split("+")
			end
			if #Huashens == 0 then return end
			local huashen_generals = {}
			for _,huashen in pairs(Huashens)do
				table.insert(huashen_generals,huashen)
			end
			local skill_names = {}
			local skill_name
			local general 
			local ai = zuoci:getAI();
			if (ai) then
				local hash = {}
				for _,general_name in pairs (huashen_generals) do
					local general = sgs.Sanguosha:getGeneral(general_name)
					for _,skill in (general:getVisibleSkillList())do
						if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
							continue
						end
						if not table.contains(skill_names,skill:objectName()) then
							hash[skill:objectName()] = general;
							table.insert(skill_names,skill:objectName())
						end
					end
				end
				if #skill_names == 0 then return end
				skill_name = ai:askForChoice("huashen",table.concat(skill_names,"+"), sgs.QVariant());
				general = hash[skill_name]
			else
				local general_name = room:askForGeneral(zuoci, table.concat(huashen_generals,"+"))
				general = sgs.Sanguosha:getGeneral(general_name)
				assert(general)
				for _,skill in sgs.qlist(general:getVisibleSkillList())do
					if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
						continue
					end
					if not table.contains(skill_names,skill:objectName()) then
						table.insert(skill_names,skill:objectName())
					end
				end
				if #skill_names > 0 then
					skill_name = room:askForChoice(zuoci, "huashen",table.concat(skill_names,"+"))
				end
			end
			local kingdom = general:getKingdom()
			if zuoci:getKingdom() ~= kingdom then
				if kingdom == "god" then
					kingdom = room:askForKingdom(zuoci);
					local log = sgs.LogMessage()
					log.type = "#ChooseKingdom";
					log.from = zuoci;
					log.arg = kingdom;
					room:sendLog(log);
				end
				room:setPlayerProperty(zuoci, "kingdom", sgs.QVariant(kingdom))
			end
			if zuoci:getGender() ~= general:getGender() then
				zuoci:setGender(general:getGender())
			end
			local jsonValue = {
				9,
				zuoci:objectName(),
				general:objectName(),
				skill_name,
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			zuoci:setTag("jiehuashenSkill",sgs.QVariant(skill_name))
			if skill_name ~= "" then
				table.insert(ac_dt_list,skill_name)
			end
			room:handleAcquireDetachSkills(zuoci, table.concat(ac_dt_list,"|"), true)
	end
jiehushen = sgs.CreateTriggerSkill{
		name = "jiehushen",
		frequency = sgs.Skill_NotFrequent,
		events = {sgs.GameStart, sgs.EventPhaseStart},
		priority = -1,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.GameStart then
				room:notifySkillInvoked(player, "huashen")
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				AcquireGenerals(player, 3)
				SelectSkill(player)
			else
				local phase = player:getPhase()
			if phase == sgs.Player_RoundStart or phase == sgs.Player_NotActive then
				if room:askForSkillInvoke(player, "huashen") then
					if room:askForChoice(player, self:objectName(),"huanhuashen+huanjineng")=="huanjineng" then
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						SelectSkill(player)
				else
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))	
		    local ac_dt_list = {}
		    local huashen_skill = player:getTag("jiehuashenSkill"):toString();
			if huashen_skill ~= "" then
				table.insert(ac_dt_list,"-"..huashen_skill)
			end
			local Huashens = {}
			local Hs_String = player:getTag("jiehuashens"):toString()
			if Hs_String and Hs_String ~= "" then
				Huashens = Hs_String:split("+")
			end
			if #Huashens == 0 then return end
			local huashen_generals = {}
			for _,huashen in pairs(Huashens)do
				table.insert(huashen_generals,huashen)
			end
			local general_names = {}
			local aigeneral_name
			local general 
			local x=0
			local ai = player:getAI();
			if (ai) then
				for _,general in pairs (huashen_generals) do
                table.insert(general_names,general)
				end
				for i=1,2 do
				if room:askForChoice(player, "hushenallornot","all+not")=="all" then--无奈之举
				aigeneral_name = ai:askForChoice("generalhuashen",table.concat(general_names,"+"), sgs.QVariant());
				table.removeOne(huashen_generals,aigeneral_name)
		   else
			break
			end
			end
			else
				for i=1,2 do
				if room:askForChoice(player, "hushenallornot","all+not")=="all" then--无奈之举
				local general_name = room:askForGeneral(player, table.concat(huashen_generals,"+"))
				      table.removeOne(huashen_generals,general_name)
					  x=x+1
			else
				break
				end
					end
				end
				if x>0 then
				local log = sgs.LogMessage()
					log.type = "#jiehushen";
					log.from = player;
					log.arg = tostring(x);
					room:sendLog(log);					
				player:setTag("jiehuashens", sgs.QVariant(table.concat(huashen_generals, "+")))
				AcquireGenerals(player, x)
					end	
		end
			end
		end
	end
end
}
jiehushenDetach = sgs.CreateTriggerSkill{
		name = "#jiehushen-clear",
		frequency = sgs.Skill_NotFrequent,
		events = {sgs.EventLoseSkill},
		priority = -1,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local skill_name = data:toString()
			if skill_name == "jiehuashen" then
				if player:getKingdom() ~= player:getGeneral():getKingdom() and player:getGeneral():getKingdom() ~= "god" then
					room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getGeneral():getKingdom()))
				end
				if player:getGender() ~= player:getGeneral():getGender() then
					player:setGender(player:getGeneral():getGender())
				end
				local huashen_skill = player:getTag("jiehuashenSkill"):toString()
				if  huashen_skill ~= "" then
					room:detachSkillFromPlayer(player, huashen_skill, false, true)
				end
				player:removeTag("jiehuashens")
				room:setPlayerMark(player, "@huashen", 0)
			end
		end,
	can_trigger = function(self, target)
		return target
	end,
}
jiexinsheng = sgs.CreateTriggerSkill{
	name = "jiexinsheng",
	frequency = sgs.Skill_Frequent,
		events = {sgs.Damaged},
		on_trigger = function(self, event, player, data)
		if player:getRoom():askForSkillInvoke(player, self:objectName()) then
			player:getRoom():broadcastSkillInvoke(self:objectName(), math.random(1,2))	
				AcquireGenerals(player, data:toDamage().damage) 
		end
	end
}
jie_zuoci:addSkill(jiehushen)
jie_zuoci:addSkill(jiehushenDetach)
jie_zuoci:addSkill(jiexinsheng)
extension:insertRelatedSkills("jiehushen", "#jiehushen-clear")


zhangwen = sgs.General(extension, "zhangwen", "wu", 3)
sgs.LoadTranslationTable{
	["zhangwen"] = "张温",
	["#zhangwen"] = "冲天孤鹭",
	["~zhangwen"] = "",
	
}

songshuCard = sgs.CreateSkillCard{
	name = "songshu",
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select, self:objectName())
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "songshui",1)
		if source:pindian(targets[1], self:objectName(),nil) then
			room:addPlayerHistory(source, "#songshu", -1)
		else
			room:doAnimate(1, source:objectName(), targets[1]:objectName())
			targets[1]:drawCards(2, self:objectName())
		end
		room:setPlayerMark(source, "songshui",0)
	end
}
songshu = sgs.CreateZeroCardViewAsSkill{
	name = "songshu",
	view_as = function()
		return songshuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#songshu") or player:isKongcheng())
	end
}
zhangwen:addSkill(songshu)
sgs.LoadTranslationTable{
	["songshu"] = "颂蜀",
	[":songshu"] = "出牌阶段限一次，你可以与其他角色拼点，若你：没赢，则其摸两张牌；赢，视为此技能于本回合内未发动过。",
	["$songshu1"] = "",
	["$songshu2"] = "",
	
}

sibian = sgs.CreateTriggerSkill{
	name = "sibian",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local ids = room:getNCards(4)
			local to_get, to_give = sgs.IntList(), sgs.IntList()
			local max_num, min_num = 0, 999
			for _, id in sgs.qlist(ids) do
				local number = sgs.Sanguosha:getCard(id):getNumber()
				if number > max_num then max_num = number end
				if number < min_num then min_num = number end
			end
			for _, id in sgs.qlist(ids) do
				local number = sgs.Sanguosha:getCard(id):getNumber()
				if number == max_num or number == min_num then to_get:append(id)
				else to_give:append(id) end
			end
			room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")), true)
			room:getThread():delay()
			local getDummy = sgs.Sanguosha:cloneCard("slash")
			getDummy:addSubcards(to_get)
			room:obtainCard(player, getDummy)
			getDummy:deleteLater()
			if to_get:length() == 2 and max_num - min_num < room:alivePlayerCount() then
				local min_handNum = 999
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHandcardNum() < min_handNum then min_handNum = p:getHandcardNum() end
				end
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHandcardNum() == min_handNum then targets:append(p) end
				end
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "@sibian-give", true)
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					local giveDummy = sgs.Sanguosha:cloneCard("slash")
					giveDummy:addSubcards(to_give)
					room:obtainCard(to, giveDummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), to:objectName(), self:objectName(), ""))
					giveDummy:deleteLater()
					to_give = sgs.IntList()
				end
			end
			if not to_give:isEmpty() then
				local giveDummy = sgs.Sanguosha:cloneCard("slash")
				giveDummy:addSubcards(to_give)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
				room:throwCard(giveDummy, reason, nil)
				giveDummy:deleteLater()
			end
			return true
		end
		return false
	end
}
zhangwen:addSkill(sibian)
sgs.LoadTranslationTable{
	["sibian"] = "思辨",
	[":sibian"] = "摸牌阶段，你可以改为亮出牌堆顶四张牌，然后获得其中所有点数最大和最小的牌，若你以此法获得的牌数为2且它们点数之差小于存活角色数，你可将剩余的牌交给手牌数最少的一名角色。",
	["$sibian1"] = "",
	["$sibian2"] = "",
	["@sibian-give"] = "思辨：你可以将剩余的牌交给手牌数最少的一名角色",
	
}

jie_sunce = sgs.General(extension_jie, "jie_sunce$", "wu", 4)
jiehunzi = sgs.CreateTriggerSkill{
	name = "jiehunzi" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "jiehunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("jiehunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() <= 2)
	end
}

jie_sunce:addSkill("jiang")
jie_sunce:addSkill(jiehunzi)
jie_sunce:addSkill("zhiba")

jie_erzhang = sgs.General(extension_jie, "jie_erzhang", "wu", 3)
jiezhijianCard = sgs.CreateSkillCard{
	name = "jiezhijianCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local erzhang = effect.from
		erzhang:getRoom():moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "zhijian", ""))
		erzhang:drawCards(1, "zhijian")
	end
}
jiezhijianVS = sgs.CreateOneCardViewAsSkill{
	name = "jiezhijian",	
	filter_pattern = "EquipCard|.|.|hand",
	view_as = function(self, card)
		local jiezhijiancard = jiezhijianCard:clone()
		jiezhijiancard:addSubcard(card)
		jiezhijiancard:setSkillName(self:objectName())
		return jiezhijiancard
	end
}
jiezhijian = sgs.CreateTriggerSkill{
        name = "jiezhijian",
		view_as_skill=jiezhijianVS,
        events ={sgs.CardUsed},
		on_trigger=function(self,event,player,data,room)
		local use = data:toCardUse()
		if use.card:isKindOf("EquipCard") then
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))	
		   	use.from:drawCards(1)
		end

end
}
jie_erzhang:addSkill(jiezhijian)
jie_erzhang:addSkill("guzheng")

jie_liushan = sgs.General(extension_jie, "jie_liushan$", "shu", 3)
jiefangquanCard = sgs.CreateSkillCard{
	name = "jiefangquan",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local playerdata = sgs.QVariant()
		playerdata:setValue(targets[1])
		room:setTag("jiefangquanTarget", playerdata)
		room:broadcastSkillInvoke(self:objectName(), 2)
	end
}
jiefangquanVS = sgs.CreateOneCardViewAsSkill{
	name = "jiefangquan",
	response_pattern = "@@jiefangquan",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local Card = jiefangquanCard:clone()
		Card:addSubcard(card:getId())
		Card:setSkillName(self:objectName())
		return Card
	end,
}
jiefangquan = sgs.CreateTriggerSkill{
	name = "jiefangquan",
	view_as_skill = jiefangquanVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if	change.to == sgs.Player_Play  and not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:addPlayerMark(player,"jiefangquan-Max-Clear")
			player:skip(sgs.Player_Play)
			room:broadcastSkillInvoke(self:objectName(), 1)
			elseif change.to == sgs.Player_NotActive then
				if player:getMark("jiefangquan-Max-Clear")>0 then
					room:askForUseCard(player, "@@jiefangquan", "@jiefangquan")
				end
		end
	end
}
jiefangquanGive = sgs.CreateTriggerSkill{
	name = "#jiefangquan-give" ,
	priority = 1,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("jiefangquanTarget") then
			local target = room:getTag("jiefangquanTarget"):toPlayer()
			room:removeTag("jiefangquanTarget")
			if target and target:isAlive() then
			target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end
}
jiefangquanMax = sgs.CreateMaxCardsSkill{
	name = "#jiefangquan-Max",
	fixed_func = function(self, target)
		if target:getMark("jiefangquan-Max-Clear")>0 then
           			return target:getMaxHp()
        	else
           			return -1
		end
	end
}
jie_liushan:addSkill("xiangle")
jie_liushan:addSkill("ruoyu")
jie_liushan:addSkill(jiefangquan)
jie_liushan:addSkill(jiefangquanGive)
jie_liushan:addSkill(jiefangquanMax)
extension:insertRelatedSkills("jiefangquan", "#jiefangquan-give")
extension:insertRelatedSkills("jiefangquan", "#jiefangquan-Max")


puyuan = sgs.General(extension, "puyuan", "shu", 4)
sgs.LoadTranslationTable{
	["puyuan"] = "蒲元",
	["#puyuan"] = "淬炼百兵",
	["~puyuan"] = "",
	
}

tianjiangCard = sgs.CreateSkillCard{
    name = "tianjiang",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasEquipArea(equip_index)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local card_id = self:getSubcards():first()
		local exchangeMove = sgs.CardsMoveList()
		exchangeMove:append(sgs.CardsMoveStruct(card_id, effect.to, sgs.Player_PlaceEquip,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.to:objectName(), self:objectName(), "")))
		local card = sgs.Sanguosha:getCard(card_id)
		playEquipAudio(card)
		local log = sgs.LogMessage()
		log.type = "#put_equip"
		log.from = effect.from
		log.to:append(effect.to)
		log.card_str = card:toString()
		room:sendLog(log)
		local realEquip = sgs.Sanguosha:getCard(card_id):getRealCard():toEquipCard()
		local equip = effect.to:getEquip(realEquip:location())
		if equip then
			exchangeMove:append(sgs.CardsMoveStruct(equip:getEffectiveId(), nil, sgs.Player_DiscardPile,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, effect.to:objectName())))
		end
		room:moveCardsAtomic(exchangeMove, true)
	end
}
tianjiangVS = sgs.CreateOneCardViewAsSkill{
    name = "tianjiang",
    filter_pattern = ".|.|.|equipped",
	view_as = function(self, card)
        local skillcard = tianjiangCard:clone()
		skillcard:addSubcard(card)
		return skillcard
    end,
	enabled_at_play = function(self, player)
		return player:hasEquip()
	end
}
tianjiang = sgs.CreateTriggerSkill{
	name = "tianjiang",
	view_as_skill = tianjiangVS,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		local cards, cards_copy = sgs.CardList(), sgs.CardList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then
				cards:append(card)
				cards_copy:append(card)
			end
		end
		if not cards:isEmpty() then
			local equipA, equipB
			while not (equipA and equipB) do
				if cards:isEmpty() then break end
				if not equipA then
					equipA = cards:at(math.random(0, cards:length() - 1))
					for _, card in sgs.qlist(cards_copy) do
						if card:getSubtype() == equipA:getSubtype() then
							cards:removeOne(card)
						end
					end
				elseif not equipB then
					equipB = cards:at(math.random(0, cards:length() - 1))
				end
			end
			if equipA then
				sendComLog(player, self:objectName())
				local Moves = sgs.CardsMoveList()
				local equip = equipA:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if player:getEquip(equip_index) == nil and player:hasEquipArea(equip_index) then
					Moves:append(sgs.CardsMoveStruct(equipA:getId(), player, sgs.Player_PlaceEquip, sgs.CardMoveReason()))
					local log = sgs.LogMessage()
					log.type = "#gain_equip"
					log.from = player
					log.card_str = equipA:toString()
					room:sendLog(log)
				else
					Moves:append(sgs.CardsMoveStruct(equipA:getId(), player, sgs.Player_PlaceHand, sgs.CardMoveReason()))
				end
				if equipB then
					equip = equipB:getRealCard():toEquipCard()
					equip_index = equip:location()
					if player:getEquip(equip_index) == nil and player:hasEquipArea(equip_index) then
						Moves:append(sgs.CardsMoveStruct(equipB:getId(), player, sgs.Player_PlaceEquip, sgs.CardMoveReason()))
						local log = sgs.LogMessage()
						log.type = "#gain_equip"
						log.from = player
						log.card_str = equipB:toString()
						room:sendLog(log)
					else
						Moves:append(sgs.CardsMoveStruct(equipB:getId(), player, sgs.Player_PlaceHand, sgs.CardMoveReason()))
					end
				end
				room:moveCardsAtomic(Moves, true)
			end
		end
		return false
	end
}
puyuan:addSkill(tianjiang)
sgs.LoadTranslationTable{
	["tianjiang"] = "天匠",
	[":tianjiang"] = "游戏开始时，你随机获得副类别不同的两张装备牌，并将其置入你的装备区；出牌阶段，你可以将你装备区里的牌置入其他角色的装备区（可替换原装备）。",
	["#gain_equip"] = "%card 被置入 %from 的装备区",
	["#put_equip"] = "%from 将 %card 置入 %to 的装备区",
	
}

zhurenCard = sgs.CreateSkillCard{
    name = "zhuren",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("Lightning") then
			try2Forge(source, card, "TB_ID")
		elseif card:getSuit() == sgs.Card_Spade then
			try2Forge(source, card, "VB_ID")
		elseif card:getSuit() == sgs.Card_Club then
			try2Forge(source, card, "WS_ID")
		elseif card:getSuit() == sgs.Card_Diamond then
			try2Forge(source, card, "BB_ID")
		elseif card:getSuit() == sgs.Card_Heart then
			try2Forge(source, card, "RL_ID")
		end
	end
}
zhuren = sgs.CreateOneCardViewAsSkill{
    name = "zhuren",
    filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
        local skillcard = zhurenCard:clone()
		skillcard:addSubcard(card)
		return skillcard
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zhuren") and player:canDiscard(player, "h")
	end
}
puyuan:addSkill(zhuren)
sgs.LoadTranslationTable{
	["zhuren"] = "铸刃",
	[":zhuren"] = "出牌阶段限一次，你可以弃置一张手牌，然后根据此牌的花色点数，你有一定概率打造成功并获得一张武器牌（若打造失败或武器已有则改为获得一张【杀】，花色决定武器名称，点数决定成功率）。此武器牌进入弃牌堆时，将其移出游戏。",
	
}

hujinding = sgs.General(extension, "hujinding", "shu", 6, false, false, false, 2)
sgs.LoadTranslationTable{
	["hujinding"] = "胡金定",
	["#hujinding"] = "怀子求怜",
	["~hujinding"] = "",
	
}

renshi = sgs.CreateTriggerSkill{
	name = "renshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local card = data:toDamage().card
		if card and card:isKindOf("Slash") and player:isWounded() then
			sendComLog(player, self:objectName())
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then room:obtainCard(player, card) end
			end
			room:loseMaxHp(player)
			return true
		end
		return false
	end
}
hujinding:addSkill(renshi)
sgs.LoadTranslationTable{
	["renshi"] = "仁释",
	[":renshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害并获得此【杀】，然后你减1点体力上限。",
	
}

wuyuanCard = sgs.CreateSkillCard{
    name = "wuyuan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:obtainCard(targets[1], card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""))
		room:recover(source, sgs.RecoverStruct(source, nil, card:isRed() and 2 or 1))
		room:drawCards(targets[1], card:objectName() ~= "slash" and 2 or 1, self:objectName())
	end
}
wuyuan = sgs.CreateOneCardViewAsSkill{
    name = "wuyuan",
	view_filter = function(self, card)
		return card:isKindOf("Slash")
	end,
    view_as = function(self, card)
        local skillcard = wuyuanCard:clone()
		skillcard:addSubcard(card)
		return skillcard
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#wuyuan")
	end
}
hujinding:addSkill(wuyuan)
sgs.LoadTranslationTable{
	["wuyuan"] = "武缘",
	[":wuyuan"] = "出牌阶段限一次，你可以将一张【杀】交给一名其他角色，然后你回复1点体力且其摸一张牌。若此【杀】为：红色，你额外回复1点体力；属性【杀】，其额外摸一张牌。",
	
}

huaizi = sgs.CreateMaxCardsSkill{
	name = "huaizi",
	frequency = sgs.Skill_Compulsory,
	fixed_func = function(self, target)
		return target:hasSkill(self:objectName()) and target:getMaxHp() or -1
	end
}
huaiziAudio = sgs.CreateTriggerSkill{
	name = "#huaizi-audio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill("huaizi") and player:getPhase() == sgs.Player_Discard then
			sendComLog(player, "huaizi")
		end
		return false
	end
}
hujinding:addSkill(huaizi)
hujinding:addSkill(huaiziAudio)
extension:insertRelatedSkills("huaizi", "#huaizi-audio")
sgs.LoadTranslationTable{
	["huaizi"] = "怀子",
	[":huaizi"] = "锁定技，你的手牌上限等同于你的体力上限。",
	
}

if not sgs.Sanguosha:getSkill("VenomousBladeSkill") then skills:append(VenomousBladeSkill) end
if not sgs.Sanguosha:getSkill("WaveSwordSkill") then skills:append(WaveSwordSkill) end
if not sgs.Sanguosha:getSkill("BlazeBladeSkill") then skills:append(BlazeBladeSkill) end
if not sgs.Sanguosha:getSkill("RibbonLanceSkill") then skills:append(RibbonLanceSkill) end
if not sgs.Sanguosha:getSkill("xin_zhayi_jiben") then skills:append(xin_zhayi_jiben) end
if not sgs.Sanguosha:getSkill("gaidangxia") then skills:append(gaidangxia) end
if not sgs.Sanguosha:getSkill("ThunderBladeSkill") then skills:append(ThunderBladeSkill) end









---jieol
jieol_liubei = sgs.General(extension_jieol, "jieol_liubei$", "shu", 4)

jieol_jijiangCard = sgs.CreateSkillCard{
	name = "jieol_jijiang" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end ,
	on_validate = function(self, cardUse) --这是0610新加的哦~~~~
		cardUse.m_isOwnerUse = false
		local liubei = cardUse.from
		local targets = cardUse.to
		room = liubei:getRoom()
		local slash = nil
		local lieges = room:getLieges("shu", liubei)
		for _, target in sgs.qlist(targets) do
			target:setFlags("JijiangTarget")
		end
		for _, liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", "@jieol_jijiang-slash:" .. liubei:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, liubei) --未处理胆守
			if slash then
				for _, target in sgs.qlist(targets) do
					target:setFlags("-JijiangTarget")
				end
				return slash
			end
		end
		for _, target in sgs.qlist(targets) do
			target:setFlags("-JijiangTarget")
		end
		room:setPlayerFlag(liubei, "Global_jieol_jijiangFailed")
		return nil
	end
}
hasShuGenerals = function(player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and (p:getKingdom() == "shu") then
			return true
		end
	end
	return false
end
jieol_jijiangVS = sgs.CreateViewAsSkill{
	name = "jieol_jijiang$" ,
	n = 0 ,
	view_as = function()
		return jieol_jijiangCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return hasShuGenerals(player)
		   and player:hasLordSkill("jieol_jijiang")
		   and (not player:hasFlag("Global_jieol_jijiangFailed"))
		   and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return hasShuGenerals(player)
		   and player:hasLordSkill("jieol_jijiang")
		   and ((pattern == "slash") or (pattern == "@jijiang"))
		   and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
		   and (not player:hasFlag("Global_jieol_jijiangFailed"))
	end
}
jieol_jijiang = sgs.CreateTriggerSkill{
	name = "jieol_jijiang$" ,
	events = {sgs.CardAsked, sgs.CardResponded, sgs.CardUsed} ,
	view_as_skill = jieol_jijiangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked and player:hasLordSkill(self:objectName()) then
			local pattern = data:toStringList()[1]
			local prompt = data:toStringList()[2]
			if (pattern ~= "slash") or string.find(prompt, "@jieol_jijiang-slash") then return false end
			local lieges = room:getLieges("shu", player)
			if lieges:isEmpty() then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			for _, liege in sgs.qlist(lieges) do
				local slash = room:askForCard(liege, "slash", "@jieol_jijiang-slash:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, player)
				if slash then
					room:provide(slash)
					return true
				end
			end
			return false
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:isKindOf("Slash") and player:getKingdom() == "shu" and player:getPhase() == sgs.Player_NotActive then
				local liubeis = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasLordSkill(self:objectName()) and p:getMark("hasusejijiang-Clear") == 0 then
							liubeis:append(p)
						end
					end
				if not liubeis:isEmpty() then
					local _data = sgs.QVariant()
					for _, p in sgs.qlist(liubeis) do
						_data:setValue(p)
						room:setPlayerFlag(p, "jieol_jijiang_Target")
						if room:askForSkillInvoke(player, "jieol_jijiang_draw", _data) then
							room:broadcastSkillInvoke(self:objectName())
							room:sendCompulsoryTriggerLog(p, self:objectName())
							room:notifySkillInvoked(p, self:objectName())
							p:drawCards(1, self:objectName())
							room:addPlayerMark(p, "hasusejijiang-Clear")
						end
						room:setPlayerFlag(p, "-jieol_jijiang_Target")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target 
	end
}

jieol_liubei:addSkill("ol_rende")
jieol_liubei:addSkill(jieol_jijiang)


jieol_zhangfei = sgs.General(extension_jieol, "jieol_zhangfei", "shu", 4)

jieol_paoxiao = sgs.CreateTargetModSkill{
	name = "jieol_paoxiao",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}

jieol_paoxiao_tr = sgs.CreateTriggerSkill{
	name = "#jieol_paoxiao_tr" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.SlashMissed, sgs.DamageCaused, sgs.EventPhaseEnd } ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.SlashMissed then 
			local effect = data:toSlashEffect()
			if effect.from and effect.from:hasSkill("jieol_paoxiao") and effect.from:getPhase() == sgs.Player_Play then
			room:addPlayerMark(effect.from, "@jieol_paoxiao")
			room:sendCompulsoryTriggerLog(effect.from, "jieol_paoxiao",  true)
				end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from:getMark("@jieol_paoxiao")==0 then return false end
			if damage.card and damage.card:isKindOf("Slash") then
				damage.damage = damage.damage + damage.from:getMark("@jieol_paoxiao")
				local log= sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg = "jieol_paoxiao"
				log.arg2  = damage.damage
				room:sendLog(log)
				room:setPlayerMark(damage.from, "@jieol_paoxiao", 0)
				room:broadcastSkillInvoke("jieol_paoxiao", math.random(1, 2))
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseEnd then
			for _,to in sgs.qlist(room:getAlivePlayers()) do
				if to:getMark("@jieol_paoxiao") > 0 then
				room:setPlayerMark(to, "@jieol_paoxiao", 0)
			end
		end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}


jieol_tishen = sgs.CreateTriggerSkill{
	name = "jieol_tishen",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@jieol_tishen",
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			if player:isWounded() and player:getMark("@jieol_tishen") > 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					player:loseMark("@jieol_tishen")
					room:broadcastSkillInvoke("jieol_tishen", math.random(1, 2))
					local x = player:getMaxHp() - player:getHp()
					if x > 0 then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = x 
						room:recover(player,recover)
						player:drawCards(x)
					end
				end
			end
		end
		return false
	end
}



jieol_zhangfei:addSkill(jieol_paoxiao)
jieol_zhangfei:addSkill(jieol_paoxiao_tr)
extension_jieol:insertRelatedSkills("jieol_paoxiao","#jieol_paoxiao_tr")
jieol_zhangfei:addSkill(jieol_tishen)




jieol_zhaoyun = sgs.General(extension_jieol, "jieol_zhaoyun", "shu", 4)



jieol_longdan = sgs.CreateViewAsSkill{
	name = "jieol_longdan" ,
	n = 1 ,
    response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, -1)
			local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, -1)
			local peach = sgs.Sanguosha:cloneCard("Peach", sgs.Card_NoSuit, -1)
		
			return ((card:isKindOf("Jink") and slash:isAvailable(sgs.Self)) or (card:isKindOf("Peach") and analeptic:isAvailable(sgs.Self))
			or (card:isKindOf("Analeptic") and peach:isAvailable(sgs.Self) and sgs.Self:isWounded()))
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			elseif pattern == "jink" then
				return card:isKindOf("Slash")
			elseif pattern == "peach" then
				return card:isKindOf("Analeptic")
			elseif pattern == "analeptic" then
				return card:isKindOf("Peach")
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		elseif originalCard:isKindOf("Peach") then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", originalCard:getSuit(), originalCard:getNumber())
			analeptic:addSubcard(originalCard)
			analeptic:setSkillName(self:objectName())
			return analeptic
		elseif originalCard:isKindOf("Analeptic") then
			local peach = sgs.Sanguosha:cloneCard("peach", originalCard:getSuit(), originalCard:getNumber())
			peach:addSubcard(originalCard)
			peach:setSkillName(self:objectName())
			return peach
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, -1)
		local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, -1)
		local peach = sgs.Sanguosha:cloneCard("Peach", sgs.Card_NoSuit, -1)
		
		--return sgs.Slash_IsAvailable(target)
		return slash:isAvailable(target) or analeptic:isAvailable(target) or (peach:isAvailable(target) and target:isWounded())
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink") or (pattern == "peach" and target:getMark("Global_PreventPeach") == 0 ) or (pattern == "analeptic")
	end
}


jieol_yajiao = sgs.CreateTriggerSkill{
	name = "jieol_yajiao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if  player:getPhase() ~= sgs.Player_NotActive then return false end
		local card
		local isHandcard = false
		if event == sgs.CardUsed then
			card = data:toCardUse().card
			isHandcard = data:toCardUse().m_isHandcard
		else
			card = data:toCardResponse().m_card
			isHandcard = data:toCardResponse().m_isHandcard
		end
		if card and not card:isKindOf("SkillCard") and isHandcard then
			if room:askForSkillInvoke(player,self:objectName(),data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				local ids = room:getNCards(1, false)
				local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, 
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), ""))
				room:moveCardsAtomic(move, true)
				
				local id = ids:first()
				local cardex = sgs.Sanguosha:getCard(id)
				room:fillAG(ids, player)
				local dealt = false
				if card:getTypeId() == cardex:getTypeId() then
					player:setMark("jieol_yajiao", id)
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 
					string.format("@jieol_yajiao-give:%s:%s:%s", cardex:objectName(), cardex:getSuitString(), cardex:getNumberString()), true, true)
					if  target then 
						room:clearAG(player)
						dealt = true
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), self:objectName(), "")
						room:obtainCard(target, cardex, reason)
					end
				else
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:inMyAttackRange(player) and player:canDiscard(p, "hej") then 
							targets:append(p)
						end
					end
						if not targets:isEmpty() then 
							local target = room:askForPlayerChosen(player, targets, "jieol_yajiao_dis", "jieol_yajiao-invoke", true, true)
							if target then
								local to_throw = room:askForCardChosen(player, target, "hej", self:objectName())
								local card = sgs.Sanguosha:getCard(to_throw)
								room:throwCard(card, target, player);
							end
						end
				end
				if not dealt then
					room:clearAG(player)
					room:returnToTopDrawPile(ids)
				end
			end
		end
		return false
	end
}

jieol_zhaoyun:addSkill(jieol_longdan)
jieol_zhaoyun:addSkill(jieol_yajiao)


jieol_weiyan = sgs.General(extension_jieol, "jieol_weiyan", "shu", 4)



jieol_qimouCard = sgs.CreateSkillCard{
	name = "jieol_qimou",
	target_fixed = true,
	on_use = function(self, room, source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local lose_num = {}
			for i = 1, source:getHp() do
				table.insert(lose_num, tostring(i))
			end
			local choice = room:askForChoice(source, "jieol_qimou", table.concat(lose_num, "+"))
			room:removePlayerMark(source, "@jieol_qimou")
			room:loseHp(source, tonumber(choice))
			source:drawCards(tonumber(choice))
			room:addPlayerMark(source, "@qimou-Clear", tonumber(choice))
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jieol_qimouVS = sgs.CreateZeroCardViewAsSkill{
	name = "jieol_qimou",
	view_as = function()
		return jieol_qimouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@jieol_qimou") >= 1 and player:getHp() > 1
	end
}
jieol_qimou = sgs.CreateTriggerSkill{
	name = "jieol_qimou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jieol_qimou",
	view_as_skill = jieol_qimouVS,
	on_trigger = function()
	end
}

jieol_weiyan:addSkill("ol_kuanggu")
jieol_weiyan:addSkill(jieol_qimou)



jieol_zhurong = sgs.General(extension_jieol, "jieol_zhurong", "shu", 4, false)



jieolzhangbiaoVS = sgs.CreateViewAsSkill{
	name = "jieolzhangbiao" ,
	n = 999,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		for _,card in ipairs(cards) do
			slash:addSubcard(card)
		end
		return slash
	end ,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() > 0) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
jieolzhangbiao = sgs.CreateTriggerSkill{
	name = "jieolzhangbiao" ,
	events = {sgs.Damage, sgs.EventPhaseChanging} ,
	view_as_skill = jieolzhangbiaoVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName()) and not damage.transfer
					and (player:getPhase() == sgs.Player_Play) then
				room:addPlayerMark(player, self:objectName(), damage.card:subcardsLength())
				player:setMark(self:objectName(), damage.card:subcardsLength())
				end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark(self:objectName()) > 0) then
				room:sendCompulsoryTriggerLog(player,self:objectName(), true)
				player:drawCards(player:getMark(self:objectName()), self:objectName())
				player:setMark(self:objectName(), 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

jieolzhangbiaoTargetMod = sgs.CreateTargetModSkill{
	name = "#jieolzhangbiao" ,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if (player:hasSkill("jieolzhangbiao")) and (card:getSkillName() == "jieolzhangbiao") then
			return 998
		end
		return 0
	end
}


jieol_zhurong:addSkill("juxiang")
jieol_zhurong:addSkill("lieren")
jieol_zhurong:addSkill(jieolzhangbiao)
jieol_zhurong:addSkill(jieolzhangbiaoTargetMod)
extension_jieol:insertRelatedSkills("jieolzhangbiao","#jieolzhangbiaoTargetMod")










jieol_wolong = sgs.General(extension_jieol, "jieol_wolong", "shu", 3)

jieol_huoji = sgs.CreateOneCardViewAsSkill{
	name = "jieol_huoji",
	response_or_use = true,
	filter_pattern = ".|red|.|.",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName(self:objectName())
		fireattack:addSubcard(id)
		return fireattack
	end
}

jieol_kanpo = sgs.CreateOneCardViewAsSkill{
	name = "jieol_kanpo",
	response_or_use = true,
	filter_pattern = ".|black|.|.",
	response_pattern = "nullification",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(self:objectName())
		return ncard
	end,
	enabled_at_nullification = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() then return true end
		end
		return false
	end
}



jieol_cangzhuo = sgs.CreateTriggerSkill{
	name = "jieol_cangzhuo",
	events = {sgs.CardUsed, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if  player:getPhase() ~= sgs.Player_NotActive and use.card and  use.card:isKindOf("TrickCard") then
				room:addPlayerMark(player, self:objectName().."-Clear")
			end
		else
			if player:getMark(self:objectName().."-Clear") == 0 then
				local n = room:getTag("DiscardNum"):toInt()
				for _,card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("TrickCard") then
						n = n - 1
					end
				end
				if event == sgs.AskForGameruleDiscard then
					room:setPlayerCardLimitation(player, "discard", "TrickCard|.|.|hand", true)
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				else
					room:removePlayerCardLimitation(player, "discard", "TrickCard|.|.|hand$1")
				end
				room:setTag("DiscardNum", sgs.QVariant(n))
			end
		end
		return false
	end,
}


jieol_wolong:addSkill("bazhen")
jieol_wolong:addSkill(jieol_huoji)
jieol_wolong:addSkill(jieol_kanpo)
jieol_wolong:addSkill(jieol_cangzhuo)


jieol_pangtong = sgs.General(extension_jieol, "jieol_pangtong", "shu", 3)

jieol_niepan = sgs.CreateTriggerSkill{
	name = "jieol_niepan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jieol_niepan",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@jieol_niepan")
				player:throwAllCards()
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local maxhp = player:getMaxHp()
				local hp = math.min(3, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:drawCards(3)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
				local choice = room:askForChoice(player,self:objectName(),"bazhen+huoji+kanpo")
				if choice == "bazhen" then
					room:handleAcquireDetachSkills(player, "bazhen")
				elseif choice == "huoji" then
					room:handleAcquireDetachSkills(player, "jieol_huoji")
				elseif choice == "kanpo" then
					room:handleAcquireDetachSkills(player, "jieol_kanpo")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@jieol_niepan") > 0
				end
			end
		end
		return false
	end
}

jieol_pangtong:addSkill("jie_lianhuan")
jieol_pangtong:addSkill(jieol_niepan)
jieol_pangtong:addRelateSkill("bazhen")
jieol_pangtong:addRelateSkill("jieol_huoji")
jieol_pangtong:addRelateSkill("jieol_kanpo")






jieol_liuchan = sgs.General(extension_jieol, "jieol_liuchan$", "shu", 3)

jieol_fangquan = sgs.CreateTriggerSkill{
	name = "jieol_fangquan" ,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				local invoked = false
				if player:isSkipped(sgs.Player_Play) then return false end
				invoked = player:askForSkillInvoke(self:objectName())
				if invoked then
					player:setFlags("jieol_fangquan")
					player:skip(sgs.Player_Play)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if player:hasFlag("jieol_fangquan") then
					if not player:canDiscard(player, "h") then return false end
					if not room:askForDiscard(player, "jieol_fangquan", 1, 1, true) then return false end
					local _player = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					local p = _player
					local playerdata = sgs.QVariant()
					playerdata:setValue(p)
					room:setTag("jieol_fangquan", playerdata)
				end
			end
		end
		return false
	end
}
jieol_fangquanGive = sgs.CreateTriggerSkill{
	name = "#jieol_fangquan-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("jieol_fangquan") then
			local target = room:getTag("jieol_fangquan"):toPlayer()
			room:removeTag("jieol_fangquan")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}

jieol_ruoyu = sgs.CreateTriggerSkill{
	name = "jieol_ruoyu$",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			room:addPlayerMark(player, "jieol_ruoyu")
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			if room:changeMaxHpForAwakenSkill(player, 1) then
				local x = 3 - player:getHp()
				if x > 0 then
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = x
					room:recover(player, recover)
				end
				if player:isLord() then
					room:handleAcquireDetachSkills(player, "jieol_jijiang")
					room:handleAcquireDetachSkills(player, "jieol_sishu")
				end
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("jieol_ruoyu")
				and target:isAlive()
				and (target:getMark("jieol_ruoyu") == 0)
	end
}

jieol_sishu = sgs.CreateTriggerSkill{
	name = "jieol_sishu",
	events = {sgs.StartJudge, sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge then
			local judge = data:toJudge()
			if judge.reason == "indulgence" and player:getMark("@jieol_sishu") > 0 then
				judge.good = not judge.good
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
		elseif event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieol_sishu-invoke", true, true)
				if not target then return false end
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				if target:getMark("@jieol_sishu") == 0 then
					room:addPlayerMark(target, "@jieol_sishu")
				else
					room:setPlayerMark(target, "@jieol_sishu", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("jieol_sishu") then skills:append(jieol_sishu) end
jieol_liuchan:addSkill("xiangle")
jieol_liuchan:addSkill(jieol_fangquan)
jieol_liuchan:addSkill(jieol_fangquanGive)
jieol_liuchan:addSkill(jieol_ruoyu)
extension_jieol:insertRelatedSkills("jieol_fangquan","#jieol_fangquan-give")
jieol_liuchan:addRelateSkill("jieol_jijiang")
jieol_liuchan:addRelateSkill("jieol_sishu")






jieol_jiangwei = sgs.General(extension_jieol, "jieol_jiangwei", "shu", 4)

jieol_tiaoxinCard = sgs.CreateSkillCard{
	name = "jieol_tiaoxin" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:inMyAttackRange(sgs.Self) and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			room:setPlayerFlag(effect.to, "jieol_tiaoxin")
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin-slash:" .. effect.from:objectName())
			room:setPlayerFlag(effect.to, "-jieol_tiaoxin")
		end
		if ((not use_slash) or not effect.from:hasFlag("jieol_tiaoxin_damage") ) and effect.from:canDiscard(effect.to, "he") then
			room:setPlayerFlag(effect.from, "jieol_tiaoxinUsed")
			room:throwCard(room:askForCardChosen(effect.from,effect.to, "he", "jieol_tiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
		end
		room:setPlayerFlag(effect.to, "-jieol_tiaoxin_damage") 
	end
}
jieol_tiaoxinVS = sgs.CreateViewAsSkill{
	name = "jieol_tiaoxin",
	n = 0 ,
	view_as = function()
		return jieol_tiaoxinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		local x = 1
		if player:hasFlag("jieol_tiaoxinUsed") then
			x = x + 1
		end
		return player:usedTimes("#jieol_tiaoxin") < x
	end
}
jieol_tiaoxin = sgs.CreateTriggerSkill{
	name = "jieol_tiaoxin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreCardUsed},
	view_as_skill = jieol_tiaoxinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			if not player:hasFlag("jieol_tiaoxin") then return false end
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "-jieol_tiaoxin")
				room:setCardFlag(use.card,"jieol_tiaoxin-slash")
			end
		elseif event == sgs.Damage then 
		local damage = data:toDamage()
		if not damage.card or (not damage.card:hasFlag("jieol_tiaoxin-slash")) then return false end
			if damage.to:objectName() == player:objectName() then
			room:setPlayerFlag(damage.to, "jieol_tiaoxin_damage") 
		end
end			
	end,
    can_trigger = function(self, target)
		return target and target:hasFlag("jieol_tiaoxin")
	end,
}

jieol_zhiji = sgs.CreateTriggerSkill{
	name = "jieol_zhiji" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
		room:addPlayerMark(player, "jieol_zhiji")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "guanxing")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("jieol_zhiji") == 0)
				and ((target:getPhase() == sgs.Player_Start) or target:getPhase() == sgs.Player_Finish)
				and target:isKongcheng()
	end
}

jieol_jiangwei:addSkill(jieol_tiaoxin)
jieol_jiangwei:addSkill(jieol_zhiji)
jieol_jiangwei:addRelateSkill("guanxing")


jieol_caocao = sgs.General(extension_jieol, "jieol_caocao$", "wei", 4)


jieol_hujia = sgs.CreateTriggerSkill{
	name = "jieol_hujia$" ,
	events = {sgs.CardAsked, sgs.CardResponded, sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked and player:hasLordSkill(self:objectName()) then
			local pattern = data:toStringList()[1]
			local prompt = data:toStringList()[2]
			if (pattern ~= "jink") or string.find(prompt, "@hujia-jink") then return false end
			local lieges = room:getLieges("wei", player)
			if lieges:isEmpty() then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			for _, liege in sgs.qlist(lieges) do
				local jink = room:askForCard(liege, "jink", "@hujia-jink:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, player)
				if jink then
					room:provide(jink)
					return true
				end
			end
			return false
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:isKindOf("Jink") and player:getKingdom() == "wei" and player:getPhase() == sgs.Player_NotActive then
				local liubeis = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasLordSkill(self:objectName()) and p:getMark("jieol_hujia-Clear") == 0 then
							liubeis:append(p)
						end
					end
				if not liubeis:isEmpty() then
					local _data = sgs.QVariant()
					for _, p in sgs.qlist(liubeis) do
						_data:setValue(p)
						room:setPlayerFlag(p, "jieol_hujia_Target")
						if room:askForSkillInvoke(player, "jieol_hujia_draw", _data) then
							room:broadcastSkillInvoke(self:objectName())
							room:sendCompulsoryTriggerLog(p, self:objectName())
							room:notifySkillInvoked(p, self:objectName())
							p:drawCards(1, self:objectName())
							room:addPlayerMark(p, "jieol_hujia-Clear")
						end
						room:setPlayerFlag(p, "-jieol_hujia_Target")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target 
	end
}


jieol_caocao:addSkill("jianxiong")
jieol_caocao:addSkill(jieol_hujia)

jieol_xiahouyuan = sgs.General(extension_jieol, "jieol_xiahouyuan", "wei", 4)


jieol_shebian = sgs.CreateTriggerSkill{
	name = "jieol_shebian",
	events = {sgs.TurnedOver} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if not p:getEquips():isEmpty() then
				targets:append(p)
			end
		end
			local from = room:askForPlayerChosen(player, targets, "jieol_shebian_from", "jieol_shebian-invoke", true, true)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			if from and not from:getEquips():isEmpty() then
				local card_id = room:askForCardChosen(player, from, "e", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local i = -1
				if place == sgs.Player_PlaceEquip then
					if card:isKindOf("Weapon") then
						i = 1
					end
					if card:isKindOf("Armor") then
						i = 2
					end
					if card:isKindOf("DefensiveHorse") then
						i = 3
					end
					if card:isKindOf("OffensiveHorse") then
						i = 4
					end
				end
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if i ~= -1 then
						if i == 1 then
							if not p:getWeapon() then
								tos:append(p)
							end
						end
						if i == 2 then
							if not p:getArmor() then
								tos:append(p)
							end
						end
						if i == 3 then
							if not p:getDefensiveHorse() then
								tos:append(p)
							end
						end
						if i == 4 then
							if not p:getOffensiveHorse() then
								tos:append(p)
							end
						end
						if i == 5 then
							if not p:getTreasure() then 
								tos:append(p)
							end
						end
					end
				end
				if tos:isEmpty() then return false end
				local tag = sgs.QVariant()
				tag:setValue(from)
				room:setTag("jieol_shebianTarget", tag)
				local to = room:askForPlayerChosen(player, tos, "jieol_shebian_to")
				if to then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), "")
					room:moveCardTo(card, from, to, place, reason)
				end
				room:removeTag("jieol_shebianTarget")
			end
		return false
	end	
}


jieol_xiahouyuan:addSkill("ol_shensu")
jieol_xiahouyuan:addSkill(jieol_shebian)

jieol_xuhuang = sgs.General(extension_jieol, "jieol_xuhuang", "wei", 4)


jieol_duanliang = sgs.CreateOneCardViewAsSkill{
	name = "jieol_duanliang",
	filter_pattern = "BasicCard,EquipCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end
}
jieol_duanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#jieol_duanliang-target",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, from)
		if from:hasSkill("jieol_duanliang") and  from:getMark("damage_point_round") == 0 then
			return 1000
		else
			return 0
		end
	end
}

jieol_jiezi = sgs.CreateTriggerSkill{
	name = "jieol_jiezi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseSkipping, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseSkipping then
			if player:getPhase() == sgs.Player_Draw then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					--if p:objectName() ~= player:objectName() then
						SendComLog(self, p)
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							--p:drawCards(1, self:objectName())
							local target = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), "jieol_jiezi-invoke", true, true)
							if target then
								local x = 999
								for _, q in sgs.qlist(room:getAlivePlayers()) do
									if q:getHandcardNum() < x then
										x = q:getHandcardNum()
									end
								end
								if target:getHandcardNum() <= x  and target:getMark("@jieol_jiezi") == 0 then
									room:addPlayerMark(target, "@jieol_jiezi")
								else
									target:drawCards(1)
								end
							end
							room:removePlayerMark(p, self:objectName().."engine")
						end
					--end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if (player:getMark("@jieol_jiezi") > 0) and player:getPhase() == sgs.Player_Draw then
			room:setPlayerMark(player, "@jieol_jiezi", 0)
			local phslist = sgs.PhaseList()
			phslist:append(sgs.Player_Draw)
			player:play(phslist)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

jieol_xuhuang:addSkill(jieol_duanliang)
jieol_xuhuang:addSkill(jieol_duanliangTargetMod)
extension_jieol:insertRelatedSkills("jieol_duanliang","#jieol_duanliang-target")
jieol_xuhuang:addSkill(jieol_jiezi)

jieol_dengai = sgs.General(extension_jieol, "jieol_dengai", "wei", 4)


jieol_tuntian = sgs.CreateTriggerSkill{
	name = "jieol_tuntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))
				and player:getPhase() == sgs.Player_NotActive 
				and player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, self:objectName() .. "engine")
				if player:getMark(self:objectName() .. "engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					room:removePlayerMark(player, self:objectName() .. "engine")
				end
			end
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))
				and player:getPhase() ~= sgs.Player_NotActive then
				local can_invoke = false
				for _,card_id in sgs.qlist(move.card_ids) do
							local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
							if flag == sgs.CardMoveReason_S_REASON_DISCARD then
								if sgs.Sanguosha:getCard(card_id):isKindOf("Slash") then
									can_invoke = true
								end
							end
						end
				if can_invoke and player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, self:objectName() .. "engine")
				if player:getMark(self:objectName() .. "engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					room:removePlayerMark(player, self:objectName() .. "engine")
					end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason == self:objectName() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				if judge:isGood() then
					player:addToPile("field", judge.card:getEffectiveId())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
jieol_tuntianDistance = sgs.CreateDistanceSkill{
	name = "#jieol_tuntian-distance",
	correct_func = function(self, from, to)
		if from:hasSkill("jieol_tuntian") then
			return -from:getPile("field"):length()
		end
		return 0
	end
}

jieol_zaoxian = sgs.CreateTriggerSkill{
	name = "jieol_zaoxian" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "jieol_zaoxian")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "jixi")
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				local playerdata = sgs.QVariant()
				playerdata:setValue(player)
				room:setTag("jieol_zaoxianTarget", playerdata)
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
			and (target:getPhase() == sgs.Player_Start)
			and (target:getMark("jieol_zaoxian") == 0)
			and (target:getPile("field"):length() >= 3)
	end
}
jieol_zaoxianGive = sgs.CreateTriggerSkill{
	name = "#jieol_zaoxian-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("jieol_zaoxianTarget") then
			local target = room:getTag("jieol_zaoxianTarget"):toPlayer()
			room:removeTag("jieol_zaoxianTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}


jieol_dengai:addSkill(jieol_tuntian)
jieol_dengai:addSkill(jieol_tuntianDistance)
extension:insertRelatedSkills("jieol_tuntian", "#jieol_tuntian-distance")
jieol_dengai:addSkill(jieol_zaoxian)
jieol_dengai:addSkill(jieol_zaoxianGive)
extension:insertRelatedSkills("jieol_zaoxian", "#jieol_zaoxian-give")
jieol_dengai:addRelateSkill("jixi")

jieol_zhanghe = sgs.General(extension_jieol, "jieol_zhanghe", "wei", 4)


jieol_qiaobianCard = sgs.CreateSkillCard{
	name = "jieol_qiaobian",
	feasible = function(self, targets)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			return #targets <= 2 and #targets > 0
		elseif phase == sgs.Player_Play then
			return #targets == 1
		end
		return false
	end,
	filter = function(self, targets, to_select)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			return #targets < 2 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
		elseif phase == sgs.Player_Play then
			return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local phase = source:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets == 0 then return end
			for _, target in pairs(targets)do
				if source:isAlive() and target:isAlive() then
					room:cardEffect(self, source, target)
				end
			end
		elseif phase == sgs.Player_Play then
			if #targets == 0 then return end
			local from = targets[1]
			if not from:hasEquip() and from:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, from, "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _, p in sgs.qlist(list) do
				if equip_index ~= -1 then
					if not p:getEquip(equip_index) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(from)
			room:setTag("QiaobianTarget", tag)
			local to = room:askForPlayerChosen(source, tos, "jieol_qiaobian", "@qiaobian-to" .. card:objectName())
			if to then
				room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
		end
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			local card_id = room:askForCardChosen(effect.from, effect.to, "h", "jieol_qiaobian")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
			room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, false)
		end
	end,
}
jieol_qiaobianVS = sgs.CreateZeroCardViewAsSkill{
	name = "jieol_qiaobian",
	response_pattern = "@@jieol_qiaobian",
	view_as = function(self, cards)
		return jieol_qiaobianCard:clone()
	end
}
jieol_qiaobian = sgs.CreateTriggerSkill{
	name = "jieol_qiaobian",
	events = {sgs.EventPhaseChanging},
	view_as_skill = jieol_qiaobianVS,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:isAlive() and target:canDiscard(target, "he")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		room:setPlayerMark(player, "qiaobianPhase", change.to)
		local index = 0
		if change.to == sgs.Player_Judge then
			index = 1
		elseif change.to == sgs.Player_Draw then
			index = 2
		elseif change.to == sgs.Player_Play then
			index = 3
		elseif change.to == sgs.Player_Discard then
			index = 4
		end
		local discard_prompt = string.format("#jieol_qiaobian-%d", index)
		local use_prompt = string.format("@jieol_qiaobian-%d", index)
		if index > 0 then--and room:askForDiscard(player, self:objectName(), 1, 0, true, true, discard_prompt) then
            local discard = false
            if player:getMark("@jieol_qiaobian") > 0 and room:askForSkillInvoke(player, "jieol_qiaobian_Mark") then
                discard = true
                room:removePlayerMark(player, "@jieol_qiaobian", 1)
            elseif room:askForDiscard(player, self:objectName(), 1, 1, true, true, discard_prompt) then 
                discard = true
            end
            if discard then    
                if not player:isAlive() then return false end
                if not player:isSkipped(change.to) and (index == 2 or index == 3) then
                    room:askForUseCard(player, "@@jieol_qiaobian", use_prompt, index)
                end
                player:skip(change.to)
            end
		end
		return false
	end
}

jieol_qiaobianMark = sgs.CreateTriggerSkill{
	name = "#jieol_qiaobianMark",
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, "jieol_qiaobian")
			room:broadcastSkillInvoke("jieol_qiaobian")
			player:gainMark("@jieol_qiaobian", 2)
		else
			if player:getPhase() == sgs.Player_Finish then
                if player:getMark("jieol_qiaobianMark"..player:getHandcardNum()) == 0 then
                    room:addPlayerMark(player, "jieol_qiaobianMark"..player:getHandcardNum())
                    room:addPlayerMark(player, "@jieol_qiaobian")
                    room:sendCompulsoryTriggerLog(player, "jieol_qiaobian")
                    room:broadcastSkillInvoke("jieol_qiaobian")
                end
            end
		end
		return false
	end
}

jieol_zhanghe:addSkill(jieol_qiaobian)
jieol_zhanghe:addSkill(jieol_qiaobianMark)
extension:insertRelatedSkills("jieol_qiaobian", "#jieol_qiaobianMark")






jieol_xunyu = sgs.General(extension_jieol, "jieol_xunyu", "wei", 3)


jieol_jieming = sgs.CreateTriggerSkill{
	name = "jieol_jieming" ,
	events = {sgs.Damaged, sgs.Death} ,
	on_trigger = function(self, event, player, data)
    if event == sgs.Damaged then
		local damage = data:toDamage()
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieol_jieming-invoke", true, true)
			if not to then break end
            room:broadcastSkillInvoke("jieol_jieming", math.random(1,2))
			local upper = math.min(5, to:getMaxHp())
            to:drawCards(upper)
            if to:canDiscard(to, "h") and to:getHandcardNum() - upper > 0 then
                room:askForDiscard(to, self:objectName(), to:getHandcardNum() - upper, to:getHandcardNum() - upper, false, false)
            end
		end
    elseif event == sgs.Death then
        local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieol_jieming-invoke", true, true)
			if not to then end
            room:broadcastSkillInvoke("jieol_jieming", math.random(1,2))
			local upper = math.min(5, to:getMaxHp())
            to:drawCards(upper)
            if to:canDiscard(to, "h")  and to:getHandcardNum() - upper > 0 then
                room:askForDiscard(to, self:objectName(), to:getHandcardNum() - upper, to:getHandcardNum() - upper, false, false)
            end
        end
	end
}



jieol_xunyu:addSkill("quhu")
jieol_xunyu:addSkill(jieol_jieming)


jieol_dianwei = sgs.General(extension_jieol, "jieol_dianwei", "wei", 4)


jieol_qiangxiCard = sgs.CreateSkillCard{
	name = "jieol_qiangxi", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:getMark(self:objectName().."-Clear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			local damage = sgs.DamageStruct()
            damage.to = effect.from
            damage.damage = 1
            room:damage(damage)
		end
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
        room:addPlayerMark(effect.to, self:objectName().."-Clear")
	end
}
jieol_qiangxi = sgs.CreateViewAsSkill{
	name = "jieol_qiangxi", 
	n = 1, 
	enabled_at_play = function(self, player)
		return player:usedTimes("#jieol_qiangxi") < 2
	end,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return jieol_qiangxiCard:clone()
		elseif #cards == 1 then
			local card = jieol_qiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		else 
			return nil
		end
	end
}

jieol_ninge = sgs.CreateTriggerSkill{
	name = "jieol_ninge",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then 
            local damage = data:toDamage()
            if damage.damage > 0 then 
                room:addPlayerMark(player, self:objectName().."-Clear")
                if player:getMark(self:objectName().."-Clear") == 2 then
                    if (damage.from and damage.from:hasSkill(self:objectName())) then
                        damage.from:drawCards(1)
                        SendComLog(self, damage.from)
                        if damage.from:canDiscard(player, "ej") then
                            local id = room:askForCardChosen(damage.from, player, "ej", self:objectName(), false, sgs.Card_MethodDiscard)
                            room:throwCard(id, player, damage.from)
                        end
                    end
                    if (player:hasSkill(self:objectName())) then
                        player:drawCards(1)
                        SendComLog(self, player)
                        if player:canDiscard(player, "ej") then
                            local id = room:askForCardChosen(player, player, "ej", self:objectName(), false, sgs.Card_MethodDiscard)
                            room:throwCard(id, player, player)
                        end
                    end
                end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


jieol_dianwei:addSkill(jieol_qiangxi)
jieol_dianwei:addSkill(jieol_ninge)






jieol_lvmeng = sgs.General(extension_jieol, "jieol_lvmeng", "wu", 4)

jieol_botu_tr = sgs.CreateTriggerSkill{
	name = "#jieol_botu",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local current = room:getCurrent()
			if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive or current:objectName() ~= player:objectName() then return false end		
				local move = data:toMoveOneTime()					
				if (move.to_place == sgs.Player_DiscardPile) then
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:getSuit() == sgs.Card_Spade then
							room:addPlayerMark(player, "jieol_botu_suit_"..card:getSuit().."_-Clear")
							if  player:getMark("@Spade") == 0 then
								room:setPlayerMark(player, "@Spade", 1)
							end
						elseif card:getSuit() == sgs.Card_Heart then
							room:addPlayerMark(player, "jieol_botu_suit_"..card:getSuit().."_-Clear")
							if  player:getMark("@Heart") == 0 then
								room:setPlayerMark(player, "@Heart", 1)
							end
						elseif card:getSuit() == sgs.Card_Club then
							room:addPlayerMark(player, "jieol_botu_suit_"..card:getSuit().."_-Clear")
							if  player:getMark("@Club") == 0 then
								room:setPlayerMark(player, "@Club", 1)
							end
						elseif card:getSuit() == sgs.Card_Diamond then
							room:addPlayerMark(player, "jieol_botu_suit_"..card:getSuit().."_-Clear")
							if  player:getMark("@Diamond") == 0 then
								room:setPlayerMark(player, "@Diamond", 1)
							end
						end
					end	
				end		
				local suit = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "jieol_botu_suit_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
				end
				local x = math.min(3, room:getAlivePlayers():length())
				if #suit >= 4 and player:getMark("jieol_botu_lun") < x then
					room:addPlayerMark(player, "jieol_botu_lun", 1)
					room:setPlayerMark(player, "jieol_botu", 1)
				end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			room:setPlayerMark(player, "@Spade", 0)
			room:setPlayerMark(player, "@Heart", 0)
			room:setPlayerMark(player, "@Club", 0)
			room:setPlayerMark(player, "@Diamond", 0)
			end
		return false
	end
}
jieol_botu = sgs.CreatePhaseChangeSkill{
	name = "jieol_botu" ,
	frequency = sgs.Skill_Frequent ,
	priority = 1 ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			local shensimayi = player:getRoom():findPlayerBySkillName(self:objectName())
			if not shensimayi or shensimayi:getMark("jieol_botu") <= 0 or not shensimayi:askForSkillInvoke(self:objectName()) then return false end
			shensimayi:setMark("jieol_botu", 0)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			shensimayi:gainAnExtraTurn()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

jieol_qinxue = sgs.CreateTriggerSkill{
	name = "jieol_qinxue" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "jieol_qinxue")
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
			room:handleAcquireDetachSkills(player, "gongxin")
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("jieol_qinxue") == 0)
				and (target:getPhase() == sgs.Player_Start or target:getPhase() == sgs.Player_Finish)
				and (target:getHandcardNum() - target:getHp() >= 2)
	end
}


jieol_lvmeng:addSkill("keji")
jieol_lvmeng:addSkill(jieol_botu)
jieol_lvmeng:addSkill(jieol_botu_tr)
extension:insertRelatedSkills("jieol_botu", "#jieol_botu")
jieol_lvmeng:addSkill(jieol_qinxue)
jieol_lvmeng:addRelateSkill("gongxin")


jieol_xiaoqiao = sgs.General(extension_jieol, "jieol_xiaoqiao", "wu", 3, false)

jieol_tianxiangCard = sgs.CreateSkillCard{
	name = "jieol_tianxiang",
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local damage = source:getTag("jieol_tianxiangDamage"):toDamage()	--yun
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 and damage.from then
			local choices = {"tianxiang1"}
			if targets[1]:getHp() > 0 then
				table.insert(choices, "tianxiang2")
			end
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			if choice == "tianxiang1" then
				--room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
				room:damage(sgs.DamageStruct(self:objectName(), damage.from, targets[1]))
				targets[1]:drawCards(math.min(targets[1]:getLostHp(), 5), "tianxiang")
			else
				room:loseHp(targets[1])
				if targets[1]:isAlive() then
					room:obtainCard(targets[1], self)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jieol_tianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "jieol_tianxiang",
	view_filter = function(self, selected)
		return  selected:getSuit() == sgs.Card_Heart and not sgs.Self:isJilei(selected)
	end,
	view_as = function(self, card)
		local jieol_tianxiangCard = jieol_tianxiangCard:clone()
		jieol_tianxiangCard:addSubcard(card)
		return jieol_tianxiangCard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jieol_tianxiang"
	end
}
jieol_tianxiang = sgs.CreateTriggerSkill{
	name = "jieol_tianxiang",
	events = {sgs.DamageInflicted},
	view_as_skill = jieol_tianxiangVS,
	on_trigger = function(self, event, player, data, room)
		if player:canDiscard(player, "he") then
			player:setTag("jieol_tianxiangDamage", data)	--yun
			return room:askForUseCard(player, "@@jieol_tianxiang", "@jieol_tianxiang", -1, sgs.Card_MethodDiscard)
		end
		return false
	end
}


jieol_hongyan = sgs.CreateFilterSkill{
	name = "jieol_hongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}
jieol_hongyanMC = sgs.CreateMaxCardsSkill{
	name = "#jieol_hongyanMC" ,
	fixed_func = function(self, target)
		if target:hasSkill("jieol_hongyan") and target:hasEquip() then
			local can_invoke = false
			for _,c in sgs.qlist(target:getEquips()) do
				if c:getSuit() == sgs.Card_Heart then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				return target:getMaxHp()
			end
		end
	end
}

jieol_piaoling = sgs.CreateTriggerSkill{
	name = "jieol_piaoling" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then
			if player:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					player:setMark("jieol_piaoling", judge.card:getEffectiveId())
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieol_piaoling-invoke", true, true)
					if target then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
						target:obtainCard(judge.card)
						if target:objectName() == player:objectName() and player:canDiscard(player, "he") then
							room:askForDiscard(player, self:objectName(),1,1,false,true)
						end
					else
						local move = sgs.CardsMoveStruct()
						move.card_ids:append(judge.card:getEffectiveId())
						move.to_place = sgs.Player_DrawPile
						move.reason.m_reason=sgs.CardMoveReason_S_REASON_PUT
						room:moveCardsAtomic(move,true)
					end
				end
		end
		end
		return false
	end
}


jieol_xiaoqiao:addSkill(jieol_tianxiang)
jieol_xiaoqiao:addSkill(jieol_hongyan)
jieol_xiaoqiao:addSkill(jieol_hongyanMC)
extension:insertRelatedSkills("jieol_hongyan", "#jieol_hongyanMC")
jieol_xiaoqiao:addSkill(jieol_piaoling)

jieol_sunjian = sgs.General(extension_jieol, "jieol_sunjian", "wu", 5, true, false, false, 4)

jieol_wulieCard = sgs.CreateSkillCard{
	name = "jieol_wulie",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getHp() and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:loseHp(source, #targets)
		source:loseMark("@jieol_wulie")
		if source:isAlive() then
			for _,p in ipairs(targets) do
				p:gainMark("@jieol_lie")
			end
		end
	end,
}
jieol_wulieVS = sgs.CreateViewAsSkill{
	name = "jieol_wulie", 
	n = 0,
	response_pattern = "@@jieol_wulie",
	view_as = function(self, cards)
		if #cards == 0 then
			local dw = jieol_wulieCard:clone()
			return dw
		end
		return nil
	end,
}
jieol_wulie = sgs.CreateTriggerSkill{
	name = "jieol_wulie",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Limited,
	limit_mark = "@jieol_wulie",
	view_as_skill = jieol_wulieVS,
	global = true,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("@jieol_lie") > 0
	end,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		room:notifySkillInvoked(player, "jieol_wulie")
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		player:loseMark("@jieol_lie")
		return true
	end,
}
jieol_wulieAsk = sgs.CreateTriggerSkill{
	name = "#jieol_wulieAsk",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if  player:hasSkill("jieol_wulie") and player:getMark("@jieol_wulie") > 0 then
				room:askForUseCard(player, "@@jieol_wulie", "@jieol_wulie-card", -1, sgs.Card_MethodNone)
			end
		end
		return false
	end,
}
jieol_sunjian:addSkill("yinghun")
jieol_sunjian:addSkill(jieol_wulie)
jieol_sunjian:addSkill(jieol_wulieAsk)
extension:insertRelatedSkills("jieol_wulie", "#jieol_wulieAsk")


jieol_lusu = sgs.General(extension_jieol, "jieol_lusu", "wu", 3)

jieol_haoshiCard = sgs.CreateSkillCard{
	name = "jieol_haoshi",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:getHandcardNum() == sgs.Self:getMark("jieol_haoshi")
	end,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, false)
		room:setPlayerMark(targets[1], "@jieol_haoshi", 1)
		local playerdata = sgs.QVariant()
		playerdata:setValue(targets[1])
		source:setTag("jieol_haoshi", playerdata)
	end
}
jieol_haoshiVS = sgs.CreateViewAsSkill{
	name = "jieol_haoshi",
	n = 999,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end,
	view_as = function(self, cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = jieol_haoshiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jieol_haoshi"
	end
}
jieol_haoshiGive = sgs.CreateTriggerSkill{
	name = "#jieol_haoshiGive",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasFlag("jieol_haoshi") then
			player:setFlags("-jieol_haoshi")
			if player:getHandcardNum() <= 5 then return false end
			local other_players = room:getOtherPlayers(player)
			local least = 1000
			for _, _player in sgs.qlist(other_players) do
				least = math.min(_player:getHandcardNum(), least)
			end
			room:setPlayerMark(player, "jieol_haoshi", least)
			local used = room:askForUseCard(player, "@@jieol_haoshi", "@haoshi", -1, sgs.Card_MethodNone)
			if not used then
				local beggar
				for _, _player in sgs.qlist(other_players) do
					if _player:getHandcardNum() == least then
						beggar = _player
						break
					end
				end
				local n = math.floor(player:getHandcardNum() / 2)
				local to_give = player:handCards():mid(0, n)
				local haoshi_card = jieol_haoshiCard:clone()
				for _, card_id in sgs.qlist(to_give) do
					haoshi_card:addSubcard(card_id)
				end
				local targets = {beggar}
				haoshi_card:on_use(room, player, targets)
			end
		end
	end
}
jieol_haoshi = sgs.CreateTriggerSkill{
	name = "jieol_haoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.TargetConfirmed},
	view_as_skill = jieol_haoshiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if room:askForSkillInvoke(player, "jieol_haoshi") then
				room:setPlayerFlag(player, "jieol_haoshi")
				local count = data:toInt() + 2
				data:setValue(count)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local target =  player:getTag("jieol_haoshi"):toPlayer()
			if target and target:isAlive() then
				room:setPlayerMark(target, "@jieol_haoshi", 0)
				player:setTag("jieol_haoshi", sgs.QVariant())
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isNDTrick() then
				if use.to:contains(player) then
					local target = player:getTag("jieol_haoshi"):toPlayer()
					if target and target:isAlive() then
						if target:getCardCount() > 1 then
							local card = room:askForCard(target, "..", "@jieol_haoshi-give:" .. player:objectName(), data, sgs.Card_MethodNone);
							if card then
								player:obtainCard(card)
								room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
							end
						end
					end
				end
			end
		end
	end
}


local json = require ("json")
jieol_dimengCard = sgs.CreateSkillCard{
	name = "jieol_dimeng",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets == 1 then
			return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) <= sgs.Self:getCardCount()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("DimengTarget")
		b:setFlags("DimengTarget")
		local n1 = a:getHandcardNum()
		local n2 = b:getHandcardNum()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() ~= a:objectName() and p:objectName() ~= b:objectName() then
				room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({a:objectName(), b:objectName()}))
			end
		end
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "dimeng", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "dimeng", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
        	room:moveCardsAtomic(exchangeMove, false);
	end
}
jieol_dimengVS = sgs.CreateViewAsSkill{
	name = "jieol_dimeng",
	n = 0 ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local card = jieol_dimengCard:clone()
	   	return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jieol_dimeng")
	end
}
jieol_dimeng = sgs.CreateTriggerSkill{
	name = "jieol_dimeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	view_as_skill = jieol_dimengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and player:hasUsed("#jieol_dimeng") then
			local a, b
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("DimengTarget") then
					p:setFlags("-DimengTarget")
					if a then
						b = p
					else
						a = p
					end
				end
			end
			if a and b then
				local x = math.abs(a:getHandcardNum() - b:getHandcardNum())
				if x > 0 then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:askForDiscard(player, self:objectName(), x, x, false, true)
				end
			end
		end
	end
}


jieol_lusu:addSkill(jieol_haoshi)
jieol_lusu:addSkill(jieol_haoshiGive)
extension:insertRelatedSkills("jieol_haoshi", "#jieol_haoshiGive")
jieol_lusu:addSkill(jieol_dimeng)

jieol_taishici = sgs.General(extension_jieol, "jieol_taishici", "wu", 4)

jieol_hanzhan = sgs.CreateTriggerSkill{
	name = "jieol_hanzhan",
	events = {sgs.AskforPindianCard, sgs.Pindian},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskforPindianCard then 
			room:setPlayerFlag(player, "jieol_hanzhan")
			if 	RIGHT(self, player) then 
				local other_players = room:getOtherPlayers(player)
				for _, p in sgs.qlist(other_players) do
					local dest = sgs.QVariant()
					dest:setValue(p)
					if p:hasFlag("jieol_hanzhan") and not player:hasFlag("jieol_hanzhan_using") and player:askForSkillInvoke(self:objectName(), dest)  then
						room:setPlayerFlag(player, "jieol_hanzhan_using")
						local card_id = room:askForCardChosen(player, p, "h", self:objectName())
						SendComLog(self, player, 1)
						if data:toInt() == 1 then
						room:setTag("pindian"..2, sgs.QVariant(card_id))
						else
						room:setTag("pindian"..1, sgs.QVariant(card_id))
						end
						return false
					end
				end
			end
				local other_players = room:getOtherPlayers(player)
				local dest = sgs.QVariant()
				dest:setValue(player)
				for _, p in sgs.qlist(other_players) do
					if p:hasFlag("jieol_hanzhan") and not p:hasFlag("jieol_hanzhan_using") and p:hasSkill(self:objectName()) and p:askForSkillInvoke(self:objectName(), dest) then
						room:setPlayerFlag(p, "jieol_hanzhan_using")
						local card_id = room:askForCardChosen(p, player, "h", self:objectName())
						SendComLog(self, p, 2)
						if data:toInt() == 1 then
						room:setTag("pindian"..1, sgs.QVariant(card_id))
						else
						room:setTag("pindian"..2, sgs.QVariant(card_id))
						end
					end
				end
		elseif event == sgs.Pindian  then
			local pindian = data:toPindian()
			room:setPlayerFlag(player, "-jieol_hanzhan")
			room:setPlayerFlag(player, "-jieol_hanzhan_using")
			if (pindian.from:objectName() == player:objectName() and player:hasSkill(self:objectName())) 
			or (pindian.to:objectName() == player:objectName() and player:hasSkill(self:objectName() )) then
				local to_obtain 
				if pindian.from_card:isKindOf("Slash") and pindian.to_card:isKindOf("Slash") then
					if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
						if room:getCardPlace(pindian.from_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.from_card
						end
					elseif pindian.from_card:getNumber() < pindian.to_card:getNumber() then
						if room:getCardPlace(pindian.to_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.to_card
						end
					else
						if room:getCardPlace(pindian.from_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.from_card
						end
						if room:getCardPlace(pindian.to_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.to_card
						end
					end
				elseif pindian.from_card:isKindOf("Slash") then
					if room:getCardPlace(pindian.from_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.from_card
						end
				elseif pindian.to_card:isKindOf("Slash") then
					if room:getCardPlace(pindian.to_card:getEffectiveId()) == sgs.Player_PlaceTable then
							to_obtain = pindian.to_card
					end
				end	
				if to_obtain and player:askForSkillInvoke(self:objectName()) then
					SendComLog(self, player, 2)
					room:obtainCard(player, to_obtain)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

jieol_taishici:addSkill("tianyi")
jieol_taishici:addSkill(jieol_hanzhan)


jieol_sunce = sgs.General(extension_jieol, "jieol_sunce$", "wu", 4)

jieol_hunzi = sgs.CreateTriggerSkill{
	name = "jieol_hunzi" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "jieol_hunzi")
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		if room:changeMaxHpForAwakenSkill(player) then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("jieol_hunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() <= 1)
	end
}

jieol_zhibaPindianCard = sgs.CreateSkillCard{
	name = "jieol_zhibaCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("jieol_zhiba") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isKongcheng() then
						return not to_select:hasFlag("jieol_zhibaInvoked")
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:setPlayerFlag(target, "jieol_zhibaInvoked")
			local choice = room:askForChoice(target, "jieol_zhibaPindian", "accept+reject")
			if choice == "reject" then
				return
			end
		room:broadcastSkillInvoke("jieol_zhiba", math.random(1, 2))
		source:pindian(target, "jieol_zhibaPindian", nil)
		local sunces = sgs.SPlayerList()
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:hasLordSkill("jieol_zhiba") then
				if not p:hasFlag("jieol_zhibaInvoked") then
					sunces:append(p)
				end
			end
		end
		if sunces:length() == 0 then
			room:setPlayerFlag(source, "Forbidjieol_zhiba")
		end
	end
}
jieol_zhibaPindian = sgs.CreateViewAsSkill{
	name = "jieol_zhibaPindian",
	n = 0,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = jieol_zhibaPindianCard:clone()
			--card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "wu" then
			if not player:isKongcheng() then
				return not player:hasFlag("Forbidjieol_zhiba")
			end
		end
		return false
	end
}

jieol_zhibaCard = sgs.CreateSkillCard{
	name = "jieol_zhiba",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:getKingdom() == "wu" then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isKongcheng() then
						return true
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		target:pindian(source, "jieol_zhibaPindian", nil)
		--source:pindian(target, "jieol_zhibaPindian", self)
	end
}
jieol_zhibaVS = sgs.CreateViewAsSkill{
	name = "jieol_zhiba",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = jieol_zhibaCard:clone()
			--card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return  not player:hasUsed("#jieol_zhiba")
	end
}
jieol_zhiba = sgs.CreateTriggerSkill{
	name = "jieol_zhiba$",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = jieol_zhibaVS,
	events = {sgs.TurnStart, sgs.Pindian, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart or event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			local lords = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:isEmpty() then return false end
			local players = sgs.SPlayerList()
			if lords:length()>1 then player = room:getAlivePlayers()
			else players = room:getOtherPlayers(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if not p:hasSkill("jieol_zhibaPindian") then
					room:attachSkillToPlayer(p, "jieol_zhibaPindian")
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "jieol_zhiba" then
			local lords = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:length() > 2 then return false end
			local players = sgs.SPlayerList()
			if lords:isEmpty() then player = room:getAlivePlayers()
			else players:append(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if p:hasSkill("jieol_zhibaPindian") then
					room:detachSkillToPlayer(p, "jieol_zhibaPindian", true)
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "jieol_zhibaPindian" then
				local target = pindian.to
				if target:hasLordSkill(self:objectName()) then
					if pindian.from_card:getNumber() <= pindian.to_card:getNumber() then
						local choice = room:askForChoice(target, "jieol_zhiba", "yes+no")
						if choice == "yes" then
							target:obtainCard(pindian.from_card)
							target:obtainCard(pindian.to_card)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("Forbidjieol_zhiba") then
					room:setPlayerFlag(player, "-Forbidjieol_zhiba")
				end
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:hasFlag("jieol_zhibaInvoked") then
						room:setPlayerFlag(p, "-jieol_zhibaInvoked")
					end
				end
			end
		end
		return false
	end,
	priority = -1,
}


jieol_sunce:addSkill("jiang")
jieol_sunce:addSkill(jieol_hunzi)
jieol_sunce:addSkill(jieol_zhiba)

jieol_sunce:addRelateSkill("yingzi")
jieol_sunce:addRelateSkill("yinghun")


jieol_huatuo = sgs.General(extension_jieol, "jieol_huatuo", "qun", 3)

jieol_huatuo:addSkill("chuli")
jieol_huatuo:addSkill("jijiu")

jieol_huaxiong = sgs.General(extension_jieol, "jieol_huaxiong", "qun", 6)

jieol_yaowu = sgs.CreateTriggerSkill{
	name = "jieol_yaowu" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card  then 
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if  damage.card:isRed() and damage.from and damage.from:isAlive() then
				damage.from:drawCards(1)
			else
				damage.to:drawCards(1)
			end
		end
		return false
	end
}



jieol_shizhanCard = sgs.CreateSkillCard{
	name = "jieol_shizhan" ,
	filter = function(self, targets, to_select)
        local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
        duel:setSkillName(self:objectName())
		return #targets == 0 and not to_select:isProhibited(sgs.Self, duel) 
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
        duel:setSkillName(self:objectName())
        local use=sgs.CardUseStruct()
        use.card=duel
        use.from=effect.to
        use.to:append(effect.from)
        room:useCard(use,false)
	end
}
jieol_shizhan = sgs.CreateViewAsSkill{
	name = "jieol_shizhan",
	n = 0 ,
	view_as = function()
		return jieol_shizhanCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:usedTimes("#jieol_shizhan") < 2
	end
}


jieol_huaxiong:addSkill(jieol_yaowu)
jieol_huaxiong:addSkill(jieol_shizhan)




jieol_gongsunzan = sgs.General(extension_jieol, "jieol_gongsunzan", "qun", 4)

jieol_qiaomeng = sgs.CreateTriggerSkill{
	name = "jieol_qiaomeng" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and (target:hasEquip() or target:getJudgingArea():length() > 0 or not target:isKongcheng()) and (not damage.chain) and (not damage.transfer) then
			if player:askForSkillInvoke(self:objectName(), data) then
				local to_throw = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(to_throw), damage.to, player)
                if (sgs.Sanguosha:getCard(to_throw):isKindOf("DefensiveHorse") or sgs.Sanguosha:getCard(to_throw):isKindOf("OffensiveHorse"))  and  room:getCardPlace(to_throw) == sgs.Player_DiscardPile then
                    room:obtainCard(p, card)
                end
			end
		end
		return false
	end
}

jieol_gongsunzan:addSkill("ol_yicong")
jieol_gongsunzan:addSkill(jieol_qiaomeng)


jie_zhangjiao = sgs.General(extension_jieol, "jie_zhangjiao$", "qun", 3, true)
jieleiji = sgs.CreateTriggerSkill{
		name = "jieleiji",
		events = {sgs.CardUsed,sgs.CardResponded,sgs.FinishJudge},	
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
		if event==sgs.CardUsed or event==sgs.CardResponded then
			local card
			if event==sgs.CardUsed then
           card = data:toCardUse().card
	     else
           card = data:toCardResponse().m_card	
			end
			if (card:isKindOf("Jink") or card:isKindOf("Lightning"))and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
        end		
     end
        if event==sgs.FinishJudge then
		local judge = data:toJudge()
        if judge.card:isBlack() and judge.reason~="baonue" then
   	    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieleiji-invoke", true, true)
		if target then
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
	    if judge.card:getSuit()== sgs.Card_Spade then
		room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
	else
		if player:isAlive() then
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover)
			end
		room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
	end
			end
		end
	end        
end
}
jieguidao = sgs.CreateTriggerSkill{
	name = "jieguidao" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, target)
	if not (target and target:isAlive() and target:hasSkill(self:objectName())) then return false end
		if target:isKongcheng() then
			local has_black = false
			for i = 0, 3, 1 do
				local equip = target:getEquip(i)
				if equip and equip:isBlack() then
					has_black = true
					break
				end
			end
			return has_black
		else
			return true
		end
	end ,
		on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local prompt_list = {
			"@guidao-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			tostring(judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".|black", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			room:retrial(card, player, judge, self:objectName(), true)
			if card:getSuit()== sgs.Card_Spade and card:getNumber()>1 and card:getNumber()<10 then
			player:drawCards(1)	
			end
		end
		return false
	end
}

jieol_huangtianCard = sgs.CreateSkillCard{
	name = "jieol_huangtian",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("jieol_huangtian")
		   and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("jieol_huangtianInvoked")
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("jieol_huangtian") then
			room:setPlayerFlag(zhangjiao, "jieol_huangtianInvoked")
			room:notifySkillInvoked(zhangjiao, "jieol_huangtian")
			zhangjiao:obtainCard(self);
			local zhangjiaos = room:getLieges("qun",zhangjiao)
			if zhangjiaos:isEmpty() then
				room:setPlayerFlag(source, "Forbidjieol_huangtian")
			end
		end
	end
}
jieol_huangtianVS = sgs.CreateOneCardViewAsSkill{
	name = "jieol_huangtianVS",
		view_filter = function(self, card)
		return card:isKindOf("Jink") or card:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local acard = jieol_huangtianCard:clone()
		acard:addSubcard(card)
		return acard
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("Forbidjieol_huangtian")
		end
		return false
	end
}
jieol_huangtian = sgs.CreateTriggerSkill{
	name = "jieol_huangtian$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStart, sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if (triggerEvent == sgs.TurnStart)or(triggerEvent == sgs.EventAcquireSkill and data:toString() == "jieol_huangtian") then 
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if not p:hasSkill("jieol_huangtianVS") then
					room:attachSkillToPlayer(p, "jieol_huangtianVS")
				end
			end
		elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "jieol_huangtian" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if p:hasSkill("jieol_huangtianVS") then
					room:detachSkillFromPlayer(p, "jieol_huangtianVS", true)
				end
			end
		elseif (triggerEvent == sgs.EventPhaseChanging) then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("Forbidjieol_huangtian") then
				room:setPlayerFlag(player, "-Forbidjieol_huangtian")
			end
			local players = room:getOtherPlayers(player);
			for _,p in sgs.qlist(players) do
				if p:hasFlag("jieol_huangtianInvoked") then
					room:setPlayerFlag(p, "-jieol_huangtianInvoked")
				end
			end
		end
		return false
	end,
}

jie_zhangjiao:addSkill(jieleiji)
jie_zhangjiao:addSkill(jieguidao)
jie_zhangjiao:addSkill(jieol_huangtian)


jie_yuji = sgs.General(extension_jieol, "jie_yuji", "qun", 3, true, true)
jieguhuo_select = sgs.CreateSkillCard {
	name = "jieguhuo_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local type = {}
		local basic = {}
		local sttrick = {}
		local mttrick = {}
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if card:getTypeId() == sgs.Card_TypeBasic then
						table.insert(basic, cd)
					elseif card:isKindOf("SingleTargetTrick") then
						table.insert(sttrick, cd)
					else
						table.insert(mttrick, cd)
					end
					if cd == "slash" then
						table.insert(basic, "normal_slash")
					end
				end
			end
		end
		if #basic ~= 0 then table.insert(type, "basic") end
		if #sttrick ~= 0 then table.insert(type, "single_target_trick") end
		if #mttrick ~= 0 then table.insert(type, "multiple_target_trick") end
		local typechoice = ""
		if #type > 0 then
			typechoice = room:askForChoice(source, "nosguhuo", table.concat(type, "+"))
		end
		local choices = {}
		if typechoice == "basic" then
			choices = table.copyFrom(basic)
		elseif typechoice == "single_target_trick" then
			choices = table.copyFrom(sttrick)    
		elseif typechoice == "multiple_target_trick" then
			choices = table.copyFrom(mttrick)
		end
		local pattern = room:askForChoice(source, "guhuo-new", table.concat(choices, "+"))
		if pattern then
			if string.sub(pattern, -5, -1) == "slash" then
				pos = getPos(slash_patterns, pattern)
				room:setPlayerMark(source, "GuhuoSlashPos", pos)
			end
			pos = getPos(patterns, pattern)
			room:setPlayerMark(source, "GuhuoPos", pos)
			room:askForUseCard(source, "@jieguhuo", "@@jieguhuo")
         	room:setTag("guhuo_select", sgs.QVariant(pattern))	
		end
	end,
}
jieguhuoCard = sgs.CreateSkillCard {
		name = "jieguhuo",
		will_throw = false,
		handling_method = sgs.Card_MethodNone,
		player = nil,
		on_use = function(self, room, source)
			player = source
		end,
		filter = function(self, targets, to_select, player)
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jieguhuo" then
				local card = nil
				if self:getUserString() ~= "" then
					card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
					card:setSkillName("guhuo")
				end
				if card and card:targetFixed() then
					return false
				end
				local qtargets = sgs.PlayerList()
				for _, p in ipairs(targets) do
					qtargets:append(p)
				end
				return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
			elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				return false
			end		
			local pattern = patterns[player:getMark("GuhuoPos")]
			if pattern == "normal_slash" then pattern = "slash" end
			local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
			card:setSkillName("guhuo")
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		end,	
		target_fixed = function(self)
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jieguhuo" then
				local card = nil
				if self:getUserString() ~= "" then
					card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				end
				return card and card:targetFixed()
			elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				return true
			end		
			local pattern = patterns[player:getMark("GuhuoPos")]
			if pattern == "normal_slash" then pattern = "slash" end
			local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
			return card and card:targetFixed()
		end,	
		feasible = function(self, targets)
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jieguhuo" then
				local card = nil
				if self:getUserString() ~= "" then
					card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
					card:setSkillName("guhuo")
				end
				local qtargets = sgs.PlayerList()
				for _, p in ipairs(targets) do
					qtargets:append(p)
				end
				return card and card:targetsFeasible(qtargets, sgs.Self)
			elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				return true
			end		
			local pattern = patterns[sgs.Self:getMark("GuhuoPos")]
			if pattern == "normal_slash" then pattern = "slash" end
			local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
			card:setSkillName("guhuo")
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		end,	
		on_validate = function(self, card_use)
			local yuji = card_use.from
			local room = yuji:getRoom()		
			local to_guhuo = self:getUserString()		
			if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jieguhuo" then
				local guhuo_list = {}
				table.insert(guhuo_list, "slash")
				if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
					table.insert(guhuo_list, "normal_slash")
					table.insert(guhuo_list, "thunder_slash")
					table.insert(guhuo_list, "fire_slash")
				end
				to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
				pos = getPos(slash_patterns, to_guhuo)
				room:setPlayerMark(yuji, "GuhuoSlashPos", pos)
			end
			room:broadcastSkillInvoke("guhuo")		
			local log = sgs.LogMessage()
			if card_use.to:isEmpty() then
				log.type = "#GuhuoNoTarget"
			else
				log.type = "#Guhuo"
			end
			log.from = yuji
			log.to = card_use.to
			log.arg = to_guhuo
			log.arg2 = "guhuo"		
			room:sendLog(log)		
			room:setTag("GuhuoType", sgs.QVariant(self:getUserString()))		
			if guhuo(self, yuji) then
				local subcards = self:getSubcards()
				local card = sgs.Sanguosha:getCard(subcards:first())
				local user_str
				if to_guhuo == "slash"  then
					if card:isKindOf("Slash") then
						user_str = card:objectName()
					else
						user_str = "slash"
					end
				elseif to_guhuo == "normal_slash" then
					user_str = "slash"
				else
					user_str = to_guhuo
				end
				local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
				use_card:setSkillName("guhuo")
				use_card:addSubcard(card)
				use_card:deleteLater()			
				return use_card
			else
				return nil
			end
		end,
		on_validate_in_response = function(self, yuji)
			local room = yuji:getRoom()
			room:broadcastSkillInvoke("guhuo")		
			local to_guhuo
			if self:getUserString() == "peach+analeptic" then
				local guhuo_list = {}
				table.insert(guhuo_list, "peach")
				if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
					table.insert(guhuo_list, "analeptic")
				end
				to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
				yuji:setTag("GuhuoSaveSelf", sgs.QVariant(to_guhuo))
			elseif self:getUserString() == "slash" then
				local guhuo_list = {}
				table.insert(guhuo_list, "slash")
				if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
					table.insert(guhuo_list, "normal_slash")
					table.insert(guhuo_list, "thunder_slash")
					table.insert(guhuo_list, "fire_slash")
				end
				to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
				pos = getPos(slash_patterns, to_guhuo)
				room:setPlayerMark(yuji, "GuhuoSlashPos", pos)
			else
				to_guhuo = self:getUserString()
			end		
			local log = sgs.LogMessage()
			log.type = "#GuhuoNoTarget"
			log.from = yuji
			log.arg = to_guhuo
			log.arg2 = "guhuo"
			room:sendLog(log)		
			room:setTag("GuhuoType", sgs.QVariant(self:getUserString()))		
			if guhuo(self, yuji) then
				local subcards = self:getSubcards()
				local card = sgs.Sanguosha:getCard(subcards:first())
				local user_str
				if to_guhuo == "slash" then
					if card:isKindOf("Slash") then
						user_str = card:objectName()
					else
						user_str = "slash"
					end
				elseif to_guhuo == "normal_slash" then
					user_str = "slash"
				else
					user_str = to_guhuo
				end
				local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
				use_card:setSkillName("guhuo")
				use_card:addSubcard(subcards:first())
				use_card:deleteLater()
				return use_card
			else
				return nil
			end
		end
	}
jieguhuo = sgs.CreateViewAsSkill {
		name = "jieguhuo",	
		n = 1,	
		enabled_at_response = function(self, player, pattern)
			if player:getMark("jieguhuo_Play")==0 then
			if pattern == "@jieguhuo" then
				return not player:isKongcheng() 
			end		
			if player:isKongcheng() or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
				return false
			end
			if pattern == "peach" and player:hasFlag("Global_PreventPeach") then return false end
			return true
			end
		end,	
		enabled_at_play = function(self, player)				
			return not player:isKongcheng() and player:getMark("jieguhuo_Play")==0
		end,	
		view_filter = function(self, selected, to_select)
			return not to_select:isEquipped() 
		end,
		view_as = function(self, cards)
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				if sgs.Sanguosha:getCurrentCardUsePattern() == "@jieguhuo" then
					local pattern = patterns[sgs.Self:getMark("GuhuoPos")]
					if pattern == "normal_slash" then pattern = "slash" end
					local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
					if c and #cards == 1 then
						c:deleteLater()
						local card = jieguhuoCard:clone()
						if not string.find(c:objectName(), "slash") then
							card:setUserString(c:objectName())
						else
							card:setUserString(slash_patterns[sgs.Self:getMark("GuhuoSlashPos")])
						end
						card:addSubcard(cards[1])
						return card
					else
						return nil
					end
				elseif #cards == 1 then
					local card = jieguhuoCard:clone()
					card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
					card:addSubcard(cards[1])
					return card
				else
					return nil
				end
			elseif #cards == 0 then
				local cd = jieguhuo_select:clone()
				return cd
			end
		end,	
		enabled_at_nullification = function(self, player)				
			return not player:isKongcheng() and player:getMark("jieguhuo_Play")==0
		end
	}
jie_yuji:addSkill(jieguhuo)
jie_yuji:addRelateSkill("chanyuan")



jieol_yuanshao = sgs.General(extension_jieol, "jieol_yuanshao$", "qun", 4)


jieol_luanjiVS = sgs.CreateViewAsSkill{
	name = "jieol_luanji",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end
}

jieol_luanji = sgs.CreateTriggerSkill{
	name = "jieol_luanji",
	events = {sgs.TargetSpecified},
	view_as_skill = jieol_luanjiVS,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.from:objectName() == player:objectName() and use.card:isKindOf("ArcheryAttack") then
			local players = sgs.SPlayerList()
			if use.to:length() > 1 then
				for _, p in sgs.qlist(use.to) do
					players:append(p)
				end
			end
			if not players:isEmpty() then
				room:setTag("jieol_luanjiData", data)
				local to = room:askForPlayerChosen(player, players, self:objectName(), "jieol_luanji-invoke", true, true)
				if to then
					if use.to:contains(to) then
						use.to:removeOne(to)
						room:broadcastSkillInvoke(self:objectName(), 1)
					end
						room:sortByActionOrder(use.to)
						data:setValue(use)
						
				end
				room:removeTag("jieol_luanjiData")
			end
		end
		return false
	end
}


jieol_xueyi = sgs.CreateMaxCardsSkill{
	name = "jieol_xueyi$",
	extra_func = function(self, target)
		if target:hasLordSkill(self:objectName()) then
			return target:getMark("@jieol_xueyi")
		end
	end
}
jieol_xueyi_tr = sgs.CreateTriggerSkill{
	name = "#jieol_xueyi_tr$",
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			if player:hasLordSkill("jieol_xueyi") then
				local quns = room:getLieges("qun",player)
				local x = quns:length()
				if player:getKingdom() == "qun" then
					x = x + 1
				end
				player:gainMark("@jieol_xueyi", x * 2)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if player:getMark("@jieol_xueyi") > 0 and room:askForSkillInvoke(player, "jieol_xueyi") then
				room:broadcastSkillInvoke("jieol_xueyi", math.random(1,2))
				player:drawCards(1)
				player:loseMark("@jieol_xueyi")
			end
		end
		return false
	end
}
jieol_yuanshao:addSkill(jieol_luanji)
jieol_yuanshao:addSkill(jieol_xueyi)
jieol_yuanshao:addSkill(jieol_xueyi_tr)
extension:insertRelatedSkills("jieol_xueyi", "#jieol_xueyi_tr")




jieol_pangde = sgs.General(extension_jieol, "jieol_pangde", "qun", 4, true)
jieol_pangde:addSkill("mashu")
jieol_jianchu = sgs.CreateTriggerSkill{
	name = "jieol_jianchu",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isKindOf("Slash") then
			local index = 1
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			for _, p in sgs.qlist(use.to) do
				if not player:isAlive() then break end
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:canDiscard(p, "he") and room:askForSkillInvoke(player, self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(id), p, player)
						if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
							jink_table[index] = 0
							room:addPlayerMark(player, "jieol_jianchu-Clear")
						else
							local ids = sgs.IntList()
							if use.card:isVirtualCard() then
								ids = use.card:getSubcards()
							else
								ids:append(use.card:getEffectiveId())
							end
							if ids:length() > 0 then
								local all_place_table = true
								for _, id in sgs.qlist(ids) do
									if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
										all_place_table = false
										break
									end
								end
								if all_place_table then
									p:obtainCard(use.card)
								end
							end
						end
						
				end
				index = index+1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
		return false
	end
}
jieol_pangde:addSkill(jieol_jianchu)

jieol_dongzhuo= sgs.General(extension_jieol, "jieol_dongzhuo$", "qun", 8, true)
jieol_jiuchiVS = sgs.CreateViewAsSkill{
		name = "jieol_jiuchi",
		n = 1,
		response_or_use = true,
		view_filter = function(self, selected, to_select)
			return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Spade)
		end,
		view_as = function(self, cards)
			if #cards == 1 then
				local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
				analeptic:setSkillName(self:objectName())
				analeptic:addSubcard(cards[1])
				return analeptic
			end
		end,
		enabled_at_play = function(self, player)
			local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
			return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
		end,
		enabled_at_response = function(self, player, pattern)
			return string.find(pattern, "analeptic")
		end
}
jieol_jiuchi = sgs.CreateTriggerSkill{
		name = "jieol_jiuchi" ,
		view_as_skill = jieol_jiuchiVS,
		events = {sgs.Damage,sgs.EventPhaseEnd} ,
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local room=player:getRoom()
		if event==sgs.Damage then
			if  damage.card and damage.card:hasFlag("drank") then
							room:addPlayerMark(player, "Qingchengbenghuai")
	               end
else
	   	    if player:getPhase() == sgs.Player_Finish then
            room:removePlayerMark(player, "Qingchengbenghuai")
	end
		end
end
}
jieol_jiuchiTargetMod = sgs.CreateTargetModSkill{
	name = "#jieol_jiuchi-target",
	residue_func = function(self, from, card)
		if from:hasSkill("jieol_jiuchi") and card:isKindOf("Analeptic") then
			return 1000
		else
			return 0
		end
	end
}

jieol_baonue = sgs.CreateTriggerSkill{
	name = "jieol_baonue$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreDamageDone, sgs.FinishJudge},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.PreDamageDone and damage.from then
			damage.from:setTag("InvokeBaonue", sgs.QVariant(damage.from:getKingdom() == "qun"))
		elseif event == sgs.Damage and player:getTag("InvokeBaonue"):toBool() and player:isAlive() then
			local dongzhuos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					dongzhuos:append(p)
				end
			end
			for _, p in sgs.qlist(dongzhuos) do
				for i=1, damage.damage, 1 do
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|spade"
						judge.good = true
						judge.reason = self:objectName()
						judge.who = p
						room:judge(judge)
						if judge:isGood() then
							room:recover(p, sgs.RecoverStruct(p))
							if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
								p:obtainCard(judge.card)
							end
						end
					else
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge.who:hasLordSkill(self:objectName()) and judge.who:objectName() == player:objectName()
			and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				player:obtainCard(judge.card)
			end
		end
		return false
	end,
}

jieol_dongzhuo:addSkill(jieol_jiuchi)
jieol_dongzhuo:addSkill(jieol_jiuchiTargetMod)
extension:insertRelatedSkills("jieol_jiuchi", "#jieol_jiuchi-target")
jieol_dongzhuo:addSkill("roulin")
jieol_dongzhuo:addSkill("benghuai")
jieol_dongzhuo:addSkill(jieol_baonue)


jieol_jiaxu = sgs.General(extension_jieol, "jieol_jiaxu", "qun", 3, true)


jieol_wansha = sgs.CreateTriggerSkill{
	name = "jieol_wansha",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone, sgs.EnterDying, sgs.QuitDying},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive and current:getMark("lua_wansha_voice") == 0 then
				room:addPlayerMark(current, "lua_wansha_voice")
				room:broadcastSkillInvoke(self:objectName())
			end
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive then
				if dying.who and dying.who:objectName() ~= player:objectName() and current:objectName() ~= player:objectName() then
					return true
				end
				--return not (player:getSeat() == current:getSeat() or player:getSeat() == dying.who:getSeat())
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("lua_wansha_voice") > 0 then
					room:setPlayerMark(p, "lua_wansha_voice", 0)
				end
			end
		elseif event == sgs.EnterDying then
			local target = room:getCurrentDyingPlayer()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				SendComLog(self, p)
				for _, q in sgs.qlist(room:getOtherPlayers(p)) do
					if not q:hasSkill(self:objectName()) and  q:objectName() ~= target:objectName() then
						room:setPlayerMark(q, "@skill_invalidity", 1)
					end
				end
			
		end
		elseif event == sgs.QuitDying then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@skill_invalidity") > 0 then
					room:setPlayerMark(p, "@skill_invalidity", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return true
	end
}



jieol_weimu_tr = sgs.CreateTriggerSkill{
	name = "#jieol_weimu_tr",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event==sgs.DamageInflicted then
			local current = room:getCurrent()
			if current and current:objectName() == player:objectName() then
				local damage = data:toDamage()
				room:sendCompulsoryTriggerLog(player, "jieol_weimu")
				room:broadcastSkillInvoke("jieol_weimu", math.random(1,2))
                player:drawCards(2 * damage.damage)
				damage.damage = 0
				data:setValue(damage)
				return true
			end
		end
	end
}

jieol_weimu = sgs.CreateProhibitSkill{
	name = "jieol_weimu" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard")) 
		and card:isBlack() and card:getSkillName() ~= "nosguhuo" --特别注意旧蛊惑
	end
}

jieol_luanwuCard = sgs.CreateSkillCard{
	name = "jieol_luanwu",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@chaos")
        room:setEmotion(source,"skill/luanwu")
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
			room:getThread():delay()
		end
        local targets_list = sgs.SPlayerList()
        for _,target in sgs.qlist(players) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
        if not targets_list:isEmpty() then
            local target = room:askForPlayerChosen(source, targets_list, self:objectName(), "jieol_luanwu-invoke", true, true)
			if not target then return false end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName("_"..self:objectName())
            room:useCard(sgs.CardUseStruct(slash, source, target))
        end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to)
		local distance_list = sgs.IntList()
		local nearest = 1000
		for _,player in sgs.qlist(players) do
			local distance = effect.to:distanceTo(player)
			distance_list:append(distance)
			nearest = math.min(nearest, distance)
		end
		local luanwu_targets = sgs.SPlayerList()
		for i = 0, distance_list:length() - 1, 1 do
			if distance_list:at(i) == nearest and effect.to:canSlash(players:at(i), nil, false) then
				luanwu_targets:append(players:at(i))
			end
		end
		if luanwu_targets:length() == 0 or not room:askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash") then
			room:loseHp(effect.to)
		end
	end
}
jieol_luanwuVS = sgs.CreateZeroCardViewAsSkill{
	name = "jieol_luanwu",
	view_as = function(self, cards)
		return jieol_luanwuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@chaos") >= 1
	end
}
jieol_luanwu = sgs.CreateTriggerSkill{
	name = "jieol_luanwu" ,
	frequency = sgs.Skill_Limited ,
	view_as_skill = jieol_luanwuVS ,
	limit_mark = "@chaos" ,
	on_trigger = function()
	end
}




jieol_jiaxu:addSkill(jieol_wansha)
jieol_jiaxu:addSkill(jieol_luanwu)
jieol_jiaxu:addSkill(jieol_weimu)
jieol_jiaxu:addSkill(jieol_weimu_tr)
extension:insertRelatedSkills("jieol_weimu", "#jieol_weimu_tr")


jieol_caiwenji = sgs.General(extension_jieol, "jieol_caiwenji", "qun", 3, false)

jieol_beige = sgs.CreateTriggerSkill{
	name = "jieol_beige",
	events = {sgs.Damaged, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card == nil or not damage.card:isKindOf("Slash") or damage.to:isDead() then
				return false
			end
			for _, caiwenji in sgs.qlist(room:getAllPlayers()) do
				if not caiwenji or caiwenji:isDead() or not caiwenji:hasSkill(self:objectName()) then continue end
				if caiwenji:canDiscard(caiwenji, "he") and room:askForSkillInvoke(caiwenji, self:objectName()) then
                    room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = false
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
                    local card = room:askForCard(caiwenji, "..", "@jieol_beige", data, self:objectName())
                    room:removeTag("jieol_beige")
                    if card then
                        room:sendCompulsoryTriggerLog(caiwenji, self:objectName())
                        local suit = judge.card:getSuit()
                        if suit == sgs.Card_Heart then
                            room:recover(player, sgs.RecoverStruct(caiwenji))
                        elseif suit == sgs.Card_Diamond then
                            player:drawCards(2, self:objectName())
                        elseif suit == sgs.Card_Club then
                            if damage.from and damage.from:isAlive() then
                                room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
                            end
                        elseif suit == sgs.Card_Spade then
                            if damage.from and damage.from:isAlive() then
                                damage.from:turnOver()
                            end
                        end
                        if card:getNumber() == judge.card:getNumber() and room:getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardPile then
                            room:obtainCard(caiwenji, card)
                        end
                        if card:getSuit() == judge.card:getSuit() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_DiscardPile then
                            room:obtainCard(caiwenji, judge.card)
                        end
                    end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getEffectiveId())
            room:setTag("jieol_beige", data)
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}




jieol_caiwenji:addSkill(jieol_beige)
jieol_caiwenji:addSkill("duanchang")















sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
["jiebao"] ="新界限突破",
["jieolbao"] ="新界限突破OL",
["jiangbao"] = "新包",
["gaibao"] = "改包",


["funWeapon"] = "蒲元专属装备",


["shenpeii"] = "审配",
["#shenpeii"] = "忠烈之士",
["shouyeee"] = "守邺",
[":shouyeee"] = "每回合限一次，当你成为其他角色使用牌的目标时，你可以与其对策，若你对策成功，此牌对你无效，且在此牌进入弃牌堆前你获得该牌。",
["gangzhj"] = "烈直",
[":gangzhj"] = "在你的准备阶段开始时，你可以选择两名角色弃置其区域内的一张牌，若你受到过伤害，在你下个结束阶段开始时，你不能使用此技能。",
["@gangzhj"] = "烈直效果被触发",
["~gangzhj"] = "请选择不大于2数量的目标",
["qixiliangdao"] = "奇袭粮道",
["kaichengyoudi"] = "开城诱敌",
["qixiliang"] = "全力攻城",
["kaichengyou"] = "坚守粮道",
["#xuanzekaichengyoudi"] = " %from 选择了开城诱敌",
["#xuanzekaichengyou"] = " %from 选择了坚守粮道",
["#xuanzeqixiliangdao"] = " %from 选择了奇袭粮道",
["#xuanzeqixiliang"] = " %from 选择了全力攻城",
["#shenpei_chenggong"]=" %from  对策成功！",
["#shenpei_chenggong2"]=" %from  对策成功！",
["#shibai"]=" %from  对策失败。",
["#shibai2"]=" %from  对策失败。",


["xin_zhuling"] = "朱灵",
["#xin_zhuling"] = "良将之亚",
["xin_zhanyi"]="战意",
["#xin_zhanyiBUff"]="战意",
[":xin_zhanyi"]="出牌阶段限一次，你可以弃置一张牌，根据你所弃置的牌获得以下效果直到出牌阶段结束，基本牌，你可以将任意一张基本牌当做任意一张基本牌使用，你使用的第一张基本牌造成的伤害或回复量+1，锦囊牌，你摸三张牌，且你使用的锦囊牌不能被无懈可击响应，装备牌，当你的杀指定目标后，目标弃置2张牌，然后你选择其中一张牌并获得之。",
["xin_zhayi_jiben"]="战意",
[":xin_zhayi_jiben"]="出牌阶段限一次，你可以弃置一张牌，根据你所弃置的牌获得以下效果直到出牌阶段结束，基本牌，你可以将任意一张基本牌当做任意一张基本牌使用，你使用的第一张基本牌造成的伤害或回复量+1，锦囊牌，你摸三张牌，且你使用的锦囊牌不能被无懈可击响应，装备牌，当你的杀指定目标后，目标弃置2张牌，然后你选择其中一张牌并获得之。",
["@xin_zhayi"]="请弃置两张牌。",
["$xin_zhanyi1"]="以战养战，视敌而战。",
["$xin_zhanyi2"]="战可以破敌，意可以守御。",

["xin_beimihu"] = "卑弥呼",
["bingzhao"] = "秉诏",
["xin_guju"] = "骨疽",
["@shubingzhao"] ="蜀势力",
["@weibingzhao"] ="魏势力",
["@wubingzhao"] ="吴势力",
["@qunbingzhao"] ="群势力",
[":xin_guju"] = "锁定技，当拥有“傀”标记的角色受到伤害后，你摸一张牌。",
["$xin_guju1"] = "我能看到，你的灵魂在颤抖。",
["$xin_guju2"] = "你死后，我将超度你的亡魂。",
["$xin_guju"] = "我能看到，你的灵魂在颤抖。",
["$xin_guju"] = "你死后，我将超度你的亡魂。",
[":bingzhao"] = "主公技 ，游戏开始时，你可以选择一个除你的势力，以外的势力，本局游戏该势力的角色受到伤害时，可以让你的“骨疽”额外摸一张牌。",
["xinbaijia"] = "拜假",
[":xinbaijia"] = "觉醒技，准备阶段开始时，若你因“骨疽”而获得的牌数不小于7，你加1点体力上限，回复1点体力，然后令所有没有“傀”标记的其他角色获得1枚“傀”标记，你失去“骨疽”，获得“蚕食”。",
["$xinbaijia1"] = "以邪马台的名义！",
["$xinbaijia2"] = "我要摧毁你的一切，然后建立我的国度。",
["illustrator:beimihu"] = "Town",
["~xin_beimihu"] = "我还会从黄泉比良坂回来的。",

["nanshengmi"] = "难升米",
["#nanshengmi"] = "率善中郎将",
["chijian"] = "持简",
[":chijian"]= "游戏开始时，你可以选择一个场上所存在的势力，然后将你的势力变更为此势力",
["$chijian1"] = "按照女王的命令，选择目标吧。",
["waishi"] = "外使",
[":waishi"] = "出牌阶段限一次，你可以选择x张牌（x为你场上所存活的势力数），交给一名角色，然后该角色必须交给你等量的牌，若其势力与你相同或者其手牌数大于你，你摸一张牌。",
["$waishi1"] = "贵国的繁荣，在下都看到了。",
["$waishi2"] = "希望我们两国，能世代修好。",
["renshe"]="忍涉",
[":renshe"] = "当你受到伤害后，你可以选择一下三项，一：将势力变更为场上存在的另一个势力，二：可以额外使用一次外史，直到你下个出牌阶段结束，三：选择一名其他角色，你与其各摸一张牌。",
["shilii"] ="选择另一个场上存在的势力。",
["@waishi"]= "请选择等量的牌交还给目标。",
["shiyongcishu"] ="额外使用一次“外史”，直到你下一个出牌阶段结束。",
["shuangmopai"] ="选择一名其他单位，你与其各摸一张牌。",
["$renshe1"] = "无论风雨在大，都无法阻挡我的脚步。",
["$renshe2"] = "一定不能辜负女王的期望。",
["~nanshengmi"] = "请把这身残躯，带回我的家乡。",
["renshe-invoke"] = "请选择一名其他角色。",

["jiedianwei"] ="典韦",
["#jiedianwei"] = "古之恶来",
["luaqiangxi"] = "强袭",
[":luaqiangxi"]= "出牌阶段，你可以弃置一张武器牌或失去一点体力值，然后选择一个目标对其造成一点伤害（不能选择相同目标,且目标必须在你的攻击范围内）。",
["$luaqiangxi1"] = "看我三步之内，取你小命。",
["$luaqiangxi2"] = "吃我一戟。",
["~jiedianwei"] = "主公快走！。",

["jieyuanshao"] ="袁绍",
["#jieyuanshao"] = "高贵名门",
["lualuanji"] = "乱击",
[":lualuanji"]= "出牌阶段，你可以将任意两张牌当做万箭齐发使用（不能使用该技能本出牌阶段已经使用过的花色），当有人使用闪响应该万箭齐发时，其摸一张牌，该万箭齐发使用结束时若没人受到该万箭齐发的伤害，你摸x张牌（x为该万箭所指定的目标数）。",
["$lualuanji1"] = "弓箭手,准备放箭。",
["$lualuanji2"] = "全都去死吧！。",
["~jieyuanshao"] = "老天不助我袁家啊！。",

["jiepangtong"] = "庞统",
["#jiepangtong"] = "凤雏",
["jie_lianhuan"] = "连环",
[":jie_lianhuan"] = "出牌阶段，你可以将一张梅花牌当做铁索连环来使用或重铸;你使用的铁索连环可以多指定一个目标。",
["$jie_lianhuan1"] = "伤一敌可连其百。",
["$jie_lianhuan2"] = "统统连起来。",
["xinniepan"] = "涅槃",
["$xinniepan1"] = "凤雏岂能消亡。",
["$xinniepan2"] = "浴火重生！",
[":xinniepan"] = "限定技，出牌阶段或你进入濒死状态时，你可以弃置区域内的所有牌，并复原武将牌，然后你将体力值回复到三，然后你摸三张牌。",
["~jiepangtong"] = "看来，我今天注定要命丧于此。",

["jieyanchou"] = "颜良文丑",
["#jieyanchou"] = "虎狼兄弟",
["xin_shuangxiong"] = "双雄",
[":xin_shuangxiong"] = "摸牌阶段开始时，你可以放弃摸牌，改为展示牌堆顶的两张牌，然后你获得其中一张，本回合你可以将于你获得的牌颜色不同的牌，当决斗使用，当你受到此决斗的伤害时，你获得其因此决斗打出的杀。",
["$xin_shuangxiong1"] = "吾乃河北上将颜良/文丑是也！。",
["$xin_shuangxiong2"] = "快来与我等决一死战！",
["~jieyanchou"] = "这红脸长须大将是....",

["jiewolong"] = "卧龙诸葛亮",
["#jiewolong"] = "卧龙",
["jieHuoji"] = "火计",
[":jieHuoji"] = "出牌阶段，你可以将一张红色牌当火攻使用。",
["$jieHuoji1"] = "燃烧吧。",
["$jieHuoji2"] = "此火可助我军大获全胜。",
["jieKanpo"] = "看破",
[":jieKanpo"] = "你可以将一张黑色牌当无懈可击使用。",
["$jieKanpo1"] = "雕虫小技。",
["$jieKanpo2"] = "你的计谋被识破了。",
["~jiewolong"] = "我的计谋竟被....",


["jiexunyu"] = "荀彧",
["#jiexunyu"] = "王佐之才",
["jiejieming"] = "节命",
[":jiejieming"] = "当你受到1点伤害时，你可以令一名角色摸两张牌，若其手牌数小于其的体力值上限，你摸一张牌。",
["$jiejieming1"] = "秉忠贞之志，守谦退之节。",
["$jiejieming2"] = "我，永不背弃。",
["~jiexunyu"] = "主公要臣死，臣不得不死。",

["jiemenghuo"] = "孟获",
["#jiemenghuo"] = "南蛮王",
["jiezaiqi"] = "再起",
[":jiezaiqi"] = "结束阶段，你可以令至多X名角色各选择一项（X为本回合置入弃牌堆的红色牌数量）：1.摸一张牌；2.令你回复1点体力。",
["huixie1"] = "令再起的发动者回复一点体力值",
["mopai1"] = "摸一张牌",
["$jiezaiqi1"] = "挫而弥坚，战而弥勇！。",
["$jiezaiqi2"] = "蛮人骨硬，其势复来！",
["@jiezaiqi"] = "再起效果被触发",
["~jiezaiqi"] = "请选择不大于x数量的目标",
["~jiemenghuo"] = "勿再放我，但求速死！",

["jie_zhurong"] = "祝融",
["jielieren"] = "烈刃",
["$jielieren1"] = "亮兵器吧。",
["$jielieren2"] = "尝尝我飞刀的厉害！",
[":jielieren"] = "当你使用杀指定目标后，你可以与其拼点，若你赢你获得其一张牌，没赢，你获得其点拼的牌，其获得你点拼的牌。",

["jie_xuhuang"] = "徐晃",
["jie_duanliang"] = "断粮",
["$jie_duanliang1"] = "人是铁，饭是刚。",
["$jie_duanliang2"] = "截其源，断其粮，贼可擒也。",
[":jie_duanliang"] = "你可以将一张非锦囊黑色牌当做兵粮寸断使用，你使用的兵粮寸断至少可以指定与你距离为2的角色为目标，且你对手牌数不小于你的单位使用兵粮寸断无距离限制。",

["jie_caopi"] = "曹丕",
["jiefangzu"] ="放逐",
["$jiefangzu1"] = "死罪可免，活罪难赦！",
["$jiefangzu2"] = "给我翻过来！",
[":jiefangzu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1. 翻面，然后摸X张牌；2. 将手牌弃至X张，且本回合不能使用牌指定除其外的角色为目标。（x为你已损失的体力值）",
["jiexingshang"] = "行殇",
["$jiexingshang1"] ="我的是我的，你的还是我的！",
["$jiexingshang2"] ="来，管杀还管埋！",
[":jiexingshang"] = "当其他角色死亡时，你可以选择一项：1. 获得其所有牌；2. 回复1点体力。",
["huixie11"]="恢复一点体力值",
["dedaopai"]="获得其所有牌",
["jiefangzu-dis"] = "请弃置 %arg  张牌或者点击取消（若你点击取消你将会摸张x牌然后将武将牌翻面）",

["jie_dongzhuo"]="董卓",
["jiejiuchi"]="酒池",
["$jiejiuchi1"]="诶嘿嘿，好酒~好酒~",
["$jiejiuchi2"]="emm...再来~一壶~",
[":jiejiuchi"]="你可以将一张黑桃牌当酒使用，你使用的受【酒】影响的【杀】造成伤害后，本回合你的崩坏失效。",

["gai_zhangrang"]="张让",
["gaitaoluan"]="滔乱",
["$gaitaoluan1"]="睁开你的眼睛看看，现在，是谁说了算",
["$gaitaoluan2"]="国家承平，神气稳固，陛下勿忧~",
[":gaitaoluan"]="你可以将任意一张牌当做本回合未使用的基本牌或非延迟锦囊牌使用，然后你选择一名角色，令其选择一项，1.交给你x张牌，2.令你失去x点体力值，且本回合滔乱无效。（x为你本回合发动滔乱的次数，且x至多为3）",
["@gaitaoluan-give"]="请交给其x张牌（否则其失去x点体力值）",
["@gaitaoluan"] = "请选择目标",
["~gaitaoluan"] = "选择若干名角色→点击确定",
["@gaitaoluan-ask"] = "请选择一名其他角色",
["@gaitaoluan-give"] = "请交给其 %arg 张牌（否则其失去 %arg 点体力值）",

["jie_sunjian"]="孙坚",
["xinpolu"]="破虏",
[":xinpolu"]="当你杀死一名角色或你死亡后，你可以令任意数量的角色各摸x张牌。（x为此技能的发动次数）",

["gai_yujin"]="于禁",
["gaizhengjun"]="镇军",
["$gaizhengjun1"]="不动如泰山！",
["$gaizhengjun2"]="纪法严明，无懈可击！",
["@gaizhengjun"]="镇军的效果被触发",
["~gaizhengjun"]="请选择一张牌再选择一个目标→点击确定",
["gaizhengjun-invoke"]="请选择一个目标",
["@askforfhslash"]="请使用一张非黑色杀",
[":gaizhengjun"]="你的回合开始时，你可以交给一名角色一张牌，然后其可以使用一张杀，若其使用了杀，该杀结算后你摸一张牌，若该杀造成了伤害你额外摸同等于伤害数值的牌，若其未使用杀，则你可以对其或者其攻击范围内的角色造成一点伤害。",

["gai_liaohua"]="廖化",
["gaidangxian"]="当先",
["gaidangxia"]="当先",
["$gaidangxian1"]="先锋就由老夫来当！",
["$gaidangxian2"]="看我先行破敌！",
[":gaidangxian"]="锁定技，回合开始时，你失去一点体力值，并从弃牌堆里获得一张【杀】，然后你执行一次额外的出牌阶段。",
[":gaidangxia"]="回合开始时，你可以失去一点体力值，并从弃牌堆里获得一张【杀】，然后你执行一次额外的出牌阶段。",
["gaifuli"]="伏枥",
["$gaifuli1"]="今天是个拼命的好日子，哈哈哈哈！",
["$gaifuli2"]="有老夫在，蜀汉就不会倒下！",
[":gaifuli"]="限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张(X为全场势力数),并将“当先”修改为非锁定技。若X大于等于3，你翻面。",


["gai_liuyu"]="刘虞",
["gaizhige"]="止戈",
["@gaizhige"]="请交给其一张杀或武器牌",
["gaizhige-invoke"]="请为其选择一个杀的目标",
["$gaizhige1"]="天下和，而平乱~ 神器宁，而止戈~",
["$gaizhige2"]="刀兵纷争即止，国运福祚绵长~",
[":gaizhige"]="出牌阶段限一次，你可以选择一名攻击范围内含有你的其他角色，除非该角色交给你一张【杀】或武器牌，否则视为对其攻击范围内你选择的另一名角色使用一张【杀】。",
["gaizongzuo"]="宗柞",
["$gaizongzuo1"]="尽死生之力，保大厦不倾~",
["$gaizongzuo2"]="乾坤倒，黎民苦，高祖后，岂任之？",
[":gaizongzuo"]="锁定技，游戏开始时，你加X点体力和体力上限(X为全场势力数):当某势力的最后一名角色死亡后，你减1点体力上限井摸两张牌。",

["gai_zhuran"]="朱然",
["gaidanshou"]="胆守",
["$gaidanshou1"]="以胆为守，扼敌咽喉",
["$gaidanshou2"]="到此为止了",
["@gaidanshou"]="",
["~gaidanshou"]="请弃置"..tostring(ruszatxa).."张牌然后对当前回合的角色造成一点伤害。",
["#gaidanshouf"]="胆守",
["@gaidanshou-dis"]="你可以弃置 %arg 张牌，对%dest造成一点伤害",
[":gaidanshou"]="每回合限一次，当你成为基本牌或锦囊牌的目标后，你可以摸X张牌(X为你本回合成为牌的目标次数):当前回合角色的结束阶段，若你本回合没有以此法摸牌，你可以弃置与其手牌数相同的牌数对其造成1点伤害。",

["xingexuan"]="葛玄",
["~xingexuan"]="善变化，拙用身......",
["@danxibiaojix"]="丹血",
["#xingexuan"]="太极仙翁",
["xinlianhua"]="炼化",
["$xinlianhua1"]="白日清山，飞升化仙。",
["$xinlianhua2"]="草木精炼，万物化丹。",
["xinlifux-y"]="请选择你要保留的 %arg 张手牌",
[":xinlianhua"]="你的回合外，当其他角色受到伤害时，你获得一枚“丹血”标记（若受伤的角色与你为同一阵营，获得的“丹血”为红色，不为同一阵营，则为黑色，且此颜色对玩家不可见），准备阶段开始时，你需弃置所有“丹血”，然后你获得以下效果，1,弃置的丹血数量小于三，你本回合获得“英姿”，并从牌堆里获取一张【桃】。2,弃置的“丹血”数量大于3，且红色大于黑色，你本回合获得“观星”，并从牌堆里获取一张【无中生有】。3,弃置的“丹血”数量大于3，且黑色大于红色，你本回合获得“直言”，并从牌堆里获取一张【顺手牵羊】。4,弃置的“丹血”数量大于3，且红色等于黑色，你本回合获得“攻心”，并从牌堆里获得一张【杀】和【决斗】。",
["xinlifu"]="札符",
["$xinlifu1"]="垂恩广救，慈悲在怀。",
["$xinlifu2"]="行符敕鬼，神变善易。",
[":xinlifu"]="限定技，出牌阶段你可以选择一名其他角色，该角色的弃牌阶段开始时，其选择一张手牌，然后你获得其没有选择的手牌。",

["xinguanlu"]="管辂",
["#xinguanlu"]="问天通神",
["xintuiyan"]="推演",
["$xintuiyan1"]="鸟语略知，万物略懂。",
["$xintuiyan2"]="玄妙之殊巧，推微而知晓。",
[":xintuiyan"]="出牌阶段开始时，你可以观看牌堆顶的两张牌",
["xinmingjie"]="命戒",
["$xinmingjie1"]="今日一卦，便知命数。",
["$xinmingjie2"]="喜仰视星辰，夜不肯寐。",
[":xinmingjie"]="结束阶段开始时，你可以摸1张牌，若你以此法摸取的牌不为黑色，则你可以重复此流程直至你以此法摸到第3张为止，若你以此法摸取的牌是黑色，你失去一点体力值。",
["xinpusuan"]="仆算",
["$xinpusuan1"]="戒律循规，不可妄贪。",
["$xinpusuan2"]="王道文明，何忧不平？",
[":xinpusuan"]="出牌阶段限一次，你可以选择一名其他单位，然后你可以至多声明两张牌的牌名，然后该角色的摸牌阶段开始时，放弃摸牌改为获得牌堆里或弃牌堆里你所声明的牌名相同的牌。",
["tuiyangguankan"]="",
["$xinpusuanxuanze"]="%from 令 %to 下回合摸牌阶段改为获取 %card 的同名牌",
["~xinguanlu"]="怀我好音，心非草木。",

["gai_guohuai"]="郭淮",
["gaijingce"]="精策",
["$gaijingce1"]="方策精详，有备无患。",
["$gaijingce2"]="精兵据敌，策守如山。",
[":gaijingce"]="你的回合结束时，若你于此回合内使用过的牌数不小于体力值，你可以摸两张牌。",

["gai_manchong"]="满宠",
["@gaijunxing-discard"]="请弃置一张与“峻刑”类别不相同的牌",
["gaijunxing"]="峻刑",
["$gaijunxing1"]="你招还是不招？",
["$gaijunxing2"]="严刑峻法，以破奸诡之胆。",
[":gaijunxing"]="出牌阶段限一次，你可以弃置至少一张手牌并选择一名其他角色，令其选择是否弃置与你弃置的牌类别均不同的一张手牌，若其选择否，其翻面，然后将手牌数摸至四张。",

["gai_xinxianying"]="辛宪英",
["gaizhongjian"]="忠鉴",
["$gaizhongjian1"]="浊世风云变幻，当以明眸洞察。",
["$gaizhongjian2"]="心中自有明镜，可鉴奸佞忠良。",
[":gaizhongjian"]="出牌阶段限一次，你可以选择一名其他角色然后展示一张手牌，然后你展示其至多三张手牌，其中每有一张花色与你所展示的牌花色相同，你摸一张牌，点数相同，你对其造成一点伤害，均不同，你弃置一张牌。",
[":gaizhongjian1"]="出牌阶段限一次，你可以选择一名其他角色然后展示一张手牌，然后你展示其至多四张手牌，其中每有一张花色与你所展示的牌花色相同，你摸一张牌，点数相同，你对其造成一点伤害，均不同，你弃置一张牌。",
[":gaizhongjian2"]="出牌阶段限一次，你可以选择一名其他角色然后展示二张手牌，然后你展示其至多三张手牌，其中每有一张花色与你所展示的牌花色相同，你摸一张牌，点数相同，你对其造成一点伤害，均不同，你弃置一张牌。",
[":gaizhongjian4"]="出牌阶段限一次，你可以选择一名其他角色然后展示一张手牌，然后你展示其至多三张手牌，其中每有一张花色与你所展示的牌花色相同，你摸一张牌，点数相同，你对其造成一点伤害，均不同，你弃置一张牌。",
["gaicaishi"]="识才",
["$gaicaishi1"]="清识难尚，至德可师。",
["$gaicaishi2"]="知书达礼，博古通今。",
[":gaicaishi"]="摸牌阶段开始时，你可以选择以下一项：1.本回合“忠鉴”可以多展示目标一张牌，2.本回合“忠鉴”可以多展示自己一张牌，3.摸两张牌，本回合你不能发动“忠鉴”。",
["xuanzembyz"]="多展示目标一张手牌",
["xuanzezjyz"]="多展示自己一张手牌",
["mopai2"]="摸两张牌,本回合你不能发动忠鉴。",
["$xuanzeyixiaxuanzembyz"]="%from 选择了，本回合多展示目标一张手牌",
["$xuanzeyixiaxuanzezjyz"]="%from 选择了，本回合多展示自己一张手牌",
["$xuanzeyixiamopai2"]="%from 选择了，摸两张牌，本回合不能使用“<font color=\"red\"><b>忠鉴</b></font>”",


["~mangyazhang"]="黄骠马也跑不快了......",
["$jiedao1"]="截头大刀的威力，你来尝尝？",
["$jiedao2"]="我这大刀，可是不看情面的。",

["~xugong"]="终究还是被其所害......",
["$yechou1"]="会有人替我报仇的！",
["$yechou2"]="我的门客，是不会放过你的！",
["$biaozhao1"]="此人有祸患之相，望丞相慎之。",
["$biaozhao2"]="孙策宜加贵宠，须召还京邑。",

["~zhangchangpu"]="我还是小看了，孙氏的伎俩......",
["$yanjiao1"]="会虽童稚，勤见规诲。",
["$yanjiao2"]="性矜严教，明于教训。",
["$shengshen1"]="居上不骄，制节谨度。",
["$shengshen2"]="君子之行，皆积小以致高大。",

["gai_quancong"]="全琮",
["gaiyaoming"]="邀名",
["$gaiyaoming1"]="看我如何以无用之栗，换己所需，哈哈哈......",
["$gaiyaoming2"]="民不足食，何以养君。",
[":gaiyaoming"]="每回合各限一次，当你受到或造成伤害后你可以选择以下一项，1.选择一名手牌数大于你的角色，然后你弃置其一张手牌，2.选择一名手牌数小于你的角色，令其摸一张牌，3.选择一名手牌数等于你的单位，你与其各弃置至多2张牌，然后摸等量的牌。",
["@gaiyaoming"]="邀名",
["~gaiyaoming"]="请至多弃置两张手牌",

["xin_lixiao"]="李肃",
["#xin_lixiao"]="魔使",
["@lixiao_zhu"]="珠",
["xin_lixun"]="利熏",
[":xin_lixun"]="锁定技，当你受到伤害时，你防止此伤害，获得同等于伤害值的“珠”标记，在你的出牌阶段开始时，你进行一次判定，若判定牌的点数小于你所持有的“珠”标记总数量，你必须弃置同等于“珠”标记总数量的牌（不足则全弃），你每少弃一张便失去一点体力值，",
["xin_kuizhu"]="馈珠",
[":xin_kuizhu"]="出牌阶段结束时，你可以选择一名场上血量最多的一名角色，然后你摸x张牌（x为其手牌数减去你的手牌数，且至多为5），其观看你的手牌，然后其可以弃置任意数量的牌（不能大于你的手牌数），获得你等量的牌，若其以此法获得了大于1的牌数，你可以选择以下弃置一项，1.失去一枚“珠”标记，2.令其对攻击范围内的一名角色造成一点伤害。",
["@xin_lixun"]="请弃置%arg张牌",
["xin_kuizhu-invoke"]="请选择一名体力值最大的一名角色",
["xin_kuizhu-invokes"]="请选择其攻击范围内的一名角色",
["@xin_kuizhu"]="馈珠",
["shiquzhu"]="失去一个“珠”",
["incite"]="选择一名在其攻击范围内的一名角色对其造成一点伤害。",
["~xin_kuizhu"]="选择自己的手牌，选择其的手牌，数量相同就可以点确定。",

["jie_zuoci"]="左慈",
["jiehushen"]="化身",
["hushenallornot"]="是否继续弃置化身",
["all"]="是",
["not"]="否",
["$jiehushen1"]="万物苍生，幻化由心！",
["$jiehushen2"]="哼！肉眼凡胎，岂能窥视仙人变幻？",
["whetherjiehushen"]="化身",
[":jiehushen"]="游戏开始时，你将武将牌堆顶三张牌置于武将牌上，称为“化身牌堆”（扣置入过“化身牌堆”的牌称为“化身牌”，武将牌须扣置入“化身牌堆”，“化身牌堆”里的牌对你可见），然后选择一张“化身牌”；回合开始时和结束后，你可以选择一项，1.选择一张“化身牌”，2.弃置至多两张“化身牌”，然后从武将牌堆里获得等量的“化身牌”（注：若你弃置了已化身的“化身牌”，不会失去技能，被弃置的化身牌有可能被重新获取。）",
["huanjineng"]="选择一张“化身牌”",
["huanhuashen"]="弃置至多两张“化身牌”，然后从武将牌堆里获得等量的“化身牌”",
["#jiehushen"]="%from 弃置了 %arg 张“化身牌”",
["jiexinsheng"]="新生",
["$jiexinsheng1"]="幻幻无穷，生生不息。",
["$jiexinsheng2"]="吐故纳新，师法天地。",
[":jiexinsheng"]="当你受到1点伤害后，你可以随机将一张游戏外的武将牌置入“化身牌堆”。",


["jie_sunce"]="孙策",
["jiehunzi"]="魂姿",
["$jiehunzi1"]="父亲在上，魂佑江东；公瑾在旁，智定天下！",
["$jiehunzi2"]="愿承父志，与公瑾，共谋天下！",
[":jiehunzi"]="觉醒技，回合开始阶段开始时，若你的体力值小于或等于2，你须减1点体力上限，并获得技能“英姿”和“英魂”。",

["jie_erzhang"]="张昭＆张纮 ",
["jiezhijian"]="直谏",
["$jiezhijian1"]="请恕…老臣直言！",
["$jiezhijian2"]="为臣者，当冒死以谏。",
[":jiezhijian"]="出牌阶段，你可以将手牌区里的一张装备牌置入一名其他角色的装备区，摸一张牌；当你使用一张装备牌时，你摸一张牌。",


["jie_liushan"]="刘禅",
["jiefangquan"]="放权",
["$jiefangquan1"]="诶？…这可如何是好啊？！",
["$jiefangquan2"]="嘿，你办事儿，我放心！",
["@jiefangquan"]="放权",
["~jiefangquan"]="请弃置一张牌，并选择一名玩家",
[":jiefangquan"]="你可以跳过出牌阶段，若如此做，此回合结束时，你可以弃置一张手牌并选择一名其他角色，若如此做，本回合你的手牌数上限等于你的体力值上限，其获得一个额外的回合。",





--jieol
["jieol_liubei"] = "界刘备",
["#jieol_liubei"] = "汉昭烈帝",
--["~jieol_liubei"] = "",
["jieol_jijiang"] = "激将",
["jieol_jijiang_draw"] = "激将",
[":jieol_jijiang"] = "主公技，其他蜀势力角色可以在你需要时代替你使用或打出【杀】（视为由你使用或打出）；其他蜀势力角色于其回合外使用或打出【杀】时，可令你摸一张牌（每回合限一次）。",
["$jieol_jijiang1"] = "哪位将军，替我拿下此贼！",
["$jieol_jijiang2"] = "欺我军无人乎？",


["jieol_zhangfei"] = "界張飛",
["#jieol_zhangfei"] = "万夫不当",
["jieol_paoxiao"] = "咆哮",
[":jieol_paoxiao"] = "锁定技，你使用【杀】无次数限制；当你于出牌阶段内使用【杀】被抵消后，此阶段你下一次通过【杀】造成的伤害+1。",
["$jieol_paoxiao1"] = "看我杀他个人仰马翻！",
["$jieol_paoxiao2"] = "哇呀呀呀呀呀呀~",
["jieol_tishen"] = "替身",
["$jieol_tishen1"] = "哈哈哈哈哈！上当的滋味如何啊？",
["$jieol_tishen2"] = "替身诱敌，真身擒杀！",
["@jieol_tishen"] = "替身",
[":jieol_tishen"] = "限定技，准备阶段，你可以将体力值回复至体力上限。你摸X张牌。（X为以此法回复的体力值数）",
--["~jieol_zhangfei"] = "",

["jieol_zhaoyun"] = "界赵云",
["#jieol_zhaoyun"] = "虎威将军",
["jieol_longdan"] = "龙胆",
[":jieol_longdan"] = "你可以将【杀】/【闪】当做【闪】/【杀】使用或打出；你可以将【桃】/【酒】当做【酒】/【桃】使用。",
["$jieol_longdan1"] = "破阵御敌，傲然屹立。",
["$jieol_longdan2"] = "平战乱，享太平。",
["@jieol_yajiao-give"] = "你可以令一名角色获得 %src [%dest %arg]",
["jieol_yajiao"] = "涯角",
["jieol_yajiao_dis"] = "涯角",
["jieol_yajiao-invoke"] = "你可以发动“涯角”<br/> <b>操作提示</b>: 选择一名攻击范围内包含你的角色→点击确定<br/>",
[":jieol_yajiao"] = "当你于回合外使用或打出手牌时，你可以展示牌堆顶一张牌。若两张牌种类：相同，你可以令一名角色获得展示的牌；不同，你可以弃置攻击范围内包含你的一名角色区域里一张牌。",
["$jieol_yajiao1"] = "横枪勒马，舍我其谁。",
["$jieol_yajiao2"] = "枪挑四海，咫尺天涯。",


["jieol_weiyan"] = "界魏延",
["#jieol_weiyan"] = "嗜血的獨狼",
["~jieol_weiyan"] = "这次失败，意料之中……",
["jieol_qimou"] = "奇謀",
[":jieol_qimou"] = "限定技，出牌階段，你可以失去X點體力。你摸X張牌。此階段內，你與其他角色距離-X且你可以多使用X張【殺】。",
--["$jieol_kuanggu1"] = "只有战场，能让我感到兴奋。",
--["$jieol_kuanggu2"] = "反骨狂傲，彰显本色！",
["$jieol_qimou1"] = "勇战不如奇谋。",
["$jieol_qimou2"] = "为了胜利，可以出其不意。",


["jieol_wolong"] = "界諸葛亮",
["#jieol_wolong"] = "卧龍",
["~jieol_wolong"] = "星途半废，夙愿未完。",
--["$bazhen1"] = "八阵连星，日月同辉。",
--["$bazhen2"] = "此阵变化，岂是汝等可解？",
["jieol_kanpo"] = "看破",
[":jieol_kanpo"] = "你可以將一張黑色牌當【無懈可擊】使用。",
["$jieol_kanpo1"] = "此计奥妙，我已看破。",
["$jieol_kanpo2"] = "还有什么是我看不破的呢？",
["jieol_huoji"] = "火計",
[":jieol_huoji"] = "你可以將一張紅色牌當【火攻】使用。",
["$jieol_huoji1"] = "赤壁借东风，燃火灭魏军。",
["$jieol_huoji2"] = "东风，让这火烧得再猛烈些吧！",
["jieol_cangzhuo"] = "藏拙",
[":jieol_cangzhuo"] = "锁定技，棄牌階段開始時，若你本回合未使用過錦囊牌，你的錦囊牌不計入手牌上限。",
["$jieol_cangzhuo1"] = "藏巧于拙，用晦而明。",
["$jieol_cangzhuo2"] = "寓清于浊，以屈为伸。",

["jieol_pangtong"] = "界龐統",
["#jieol_pangtong"] = "凤凰涅槃",
["~jieol_pangtong"] = "鸡飞羽落，坡道归尘。",
["@jieol_niepan"] = "涅槃",
["$jieol_niepan1"] = "破而后立，方有大成。",
["$jieol_niepan2"] = "烈火脱胎，涅槃重生。",
["jieol_niepan"] = "涅槃",
[":jieol_niepan"] = "限定技，當你處於瀕死狀態時，你可以棄置所有牌，復原你的武將牌，摸三張牌，將體力回復至3點。然後選擇一個技能獲得：“八陣”、“火計”、“看破”。",
--["$jie_lianhuan1"] = "连环之策，攻敌之计。",
--["$jie_lianhuan2"] = "锁链连舟，困步难行。",
--["$jieol_kanpo1"] = "卧龙之才，吾也略懂。",
--["$jieol_kanpo2"] = "这些小伎俩，逃不出我的眼睛。",
--["$jieol_huoji1"] = "火计诱敌，江水助势。",
--["$jieol_huoji2"] = "火烧赤壁，曹贼必败。",
--["$bazhen1"] = "八卦四象，阴阳运转。,
--["$bazhen2"] = "离火艮山，皆随我用。",



["jieol_zhurong"] = "界祝融",
["~jieol_zhurong"] = "这汉人，竟...如此厉害...",

["jieolzhangbiao"] = "长标",
["$jieolzhangbiao1"] = "长标如虹，以伐蜀汉！",
["$jieolzhangbiao2"] = "长标在此，谁敢拦我？",
[":jieolzhangbiao"] = "出牌阶段限一次，你可将任意张手牌当无距离限制的【杀】使用。此阶段结束时，若此【杀】对目标角色造成过伤害，你摸等量的牌。",

["jieol_liuchan"] = "界刘禅",
["#jieol_liuchan"] = "蜀后主",
["~jieol_liuchan"] = "将军英勇，我…我投降……",
["jieol_fangquan"] = "放权",
[":jieol_fangquan"] = "你可以跳过出牌阶段，然后弃牌阶段开始时，你可以弃置一张手牌并令一名其他角色获得一个额外的回合。",
["jieol_ruoyu"] = "若愚",
[":jieol_ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值最小的角色，你加1点体力上限，將體力回覆至3點，然后获得“激将”和“思蜀”。",
["jieol_sishu"] = "思蜀",
["jieol_sishu-invoke"] = "你可以发动“思蜀”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
[":jieol_sishu"] = "出牌阶段开始时，你可以指定一名角色，令其本局游戏中【乐不思蜀】判定效果反转。",
--["$xiangle1"] = "诶嘿嘿嘿，还是玩耍快乐~",
--["$xiangle2"] = "美好的日子，应该好好享受。",
["$jieol_fangquan1"] = "蜀汉有相父在，我可安心。",
["$jieol_fangquan2"] = "这些事情，你们安排就好。",
["$jieol_ruoyu1"] = "若愚故泰，巧骗众人。",
["$jieol_ruoyu2"] = "愚昧者，非真傻也。",
--["$jieol_jijiang1"] = "爱卿爱卿，快来护驾！",
--["$jieol_jijiang2"] = "将军快替我，拦下此贼！",
["$jieol_sishu1"] = "蜀乐乡土，怎不思念？",
["$jieol_sishu2"] = "思乡心切，徘徊惶惶。",


["jieol_jiangwei"] = "界姜維",
["#jieol_jiangwei"] = "龍的衣缽",
["~jieol_jiangwei"] = "星散流离……",
["jieol_tiaoxin"] = "挑釁",
[":jieol_tiaoxin"] = "出牌阶段限一次，你可以令一名攻击范围内含有你的角色对你使用一张【杀】。若其未使用【杀】或此【杀】未对你造成伤害，你弃置其一张牌且此阶段此技能修改为“<font color=\"green\"><b>出牌阶段限两次</b></font>”。",
["jieol_zhiji"] = "志繼",
[":jieol_zhiji"] = "觉醒技，准备阶段或结束阶段，若你没有手牌，你回复1点体力或摸两张牌，减1点体力上限，获得“观星”。",
["$jieol_tiaoxin1"] = "会闻用师，观衅而动。",
["$jieol_tiaoxin2"] = "宜乘其衅会，以挑敌将！",
["$jieol_zhiji1"] = "丞相遗志，不死不休！",
["$jieol_zhiji2"] = "大业未成，矢志不渝！",
--["$guanxing1"] = "星象相衔，此乃吉兆！/,
--["$guanxing2"] = "星之分野，各有所属。",


["jieol_caocao"] = "界曹操",
["#jieol_caocao"] = "亂世的奸雄",
--["~jieol_caocao"] = "",
["jieol_hujia"] = "護駕",
[":jieol_hujia"] = "主公技，其他魏势力角色可以在你需要时代替你使用或打出【闪】（视为由你使用或打出）；其他魏势力角色于其回合外使用或打出【闪】时，可令你摸一张牌（每回合限一次）。",
["$jieol_hujia1"] = "群臣侧立，助我御敌！",
["$jieol_hujia2"] = "魏将何人，可将其拦下！",
["$jieol_hujia3"] = "众将忠义，护我周全！",



["jieol_xiahouyuan"] = "界夏侯渊",
["#jieol_xiahouyuan"] = "風馳電掣",
["~jieol_xiahouyuan"] = "我的速度，还是不够……",
["jieol_shebian"] = "设变",
["jieol_shebian_to"] = "设变",
["jieol_shebian_from"] = "设变",
[":jieol_shebian"] = "当你翻面后，你可以移动场上的一张装备牌",
["jieol_shebian-invoke"] = "你可以发动“设变”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
["$jieol_shebian1"] = "设变力战，虏敌千万！",
["$jieol_shebian2"] = "随机应变，临机设变。",
--["$ol_shensu1"] = "奔轶绝尘，不留踪影！",
--["$ol_shensu2"] = "健步如飞，破敌不备！",

["jieol_xuhuang"] = "界徐晃",
["#jieol_xuhuang"] = "周亚夫之风",
["~jieol_xuhuang"] = "亚夫易老，李广难封。",
["jieol_duanliang"] = "断粮",
[":jieol_duanliang"] = "你可以将一张黑色基本牌或黑色装备牌当【兵粮寸断】使用；若你本回合未造成过伤害，你使用【兵粮寸断】无距离限制。",
["jieol_jiezi"] = "截辎",
[":jieol_jiezi"] = "当一名角色跳过摸牌阶段后，你可选择一名角色，若其手牌数为全场最少且没有“辎”标记，其获得“辎”，否则其摸一张牌。有“辎”的角色的摸牌阶段结束时，其弃“辎”，执行一个额外的摸牌阶段。",
["jieol_jiezi-invoke"] = "你可以发动“截辎”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
["$jieol_duanliang1"] = "兵行无常，既行断粮。",
["$jieol_duanliang2"] = "焚其粮营，断其粮道。",
["$jieol_jiezi1"] = "剪径截辎，馈泽同袍。",
["$jieol_jiezi2"] = "截敌粮草，以资袍泽。",

["jieol_dengai"] = "界邓艾",
["#jieol_dengai"] = "壮士解腕",
["~jieol_dengai"] = "钟会，你为何害我……",
["jieol_tuntian"] = "屯田",
[":jieol_tuntian"] = "当你于回合外失去牌后，或于回合内弃置【杀】后，你可以判定。若结果不为♡，你将判定牌置于你的武将牌上，称为“田”；你与其他角色的距离-X（X为“田”数）。",
["jieol_zaoxian"] = "凿险",
[":jieol_zaoxian"] = "觉醒技，准备阶段，若“田”数不小于3，你减1点体力上限，获得“急袭”。此回合结束后，你获得一个额外的回合。",
["$jieol_tuntian1"] = "垦田南山，志在西川。",
["$jieol_tuntian2"] = "兵农一体，以屯养战。",
["$jieol_zaoxian1"] = "良田厚土，足平蜀道之难。",
["$jieol_zaoxian2"] = "效仿五丁开川，赢粮直捣黄龙。",
--["$jixi1"] = "明至剑阁，暗袭蜀都。",
--["$jixi2"] = "良田为济，神兵天降。",

["jieol_zhanghe"] = "界张郃",
["#jieol_zhanghe"] = "料敌机先",
["~jieol_zhanghe"] = "何处之流矢……",
["@jieol_qiaobian"] = "变",
["jieol_qiaobian"] = "巧变",
[":jieol_qiaobian"] = "游戏开始时，你获得2枚“变”；你可以弃置一张牌或移去1枚“变”，跳过你的一个阶段（准备阶段和结束阶段除外）。若以此法跳过：摸牌阶段，你可以获得至多两名其他角色各一张手牌；出牌阶段，你可以移动场上的一张牌；结束阶段，你记录你当前的手牌数（此效果不会被无效）。若此数值与已记录的其他数值均不相同，你获得1枚“变”。",
["@jieol_qiaobian-2"] = "你可以依次获得一至两名其他角色的各一张手牌",
["@jieol_qiaobian-3"] = "你可以将场上的一张牌移动至另一名角色相应的区域内",
["#jieol_qiaobian-1"] = "你可以弃置 %arg 张牌跳过判定阶段",
["#jieol_qiaobian-2"] = "你可以弃置 %arg 张牌跳过摸牌阶段",
["#jieol_qiaobian-3"] = "你可以弃置 %arg 张牌跳过出牌阶段",
["#jieol_qiaobian-4"] = "你可以弃置 %arg 张牌跳过弃牌阶段",
["jieol_qiaobian_Mark"] = "巧变-移去“变”",
["~jieol_qiaobian2"] = "选择 1-2 名其他角色→点击确定",
["~jieol_qiaobian3"] = "选择一名角色→点击确定",
["$jieol_qiaobian1"] = "顺势而变，则胜矣。",
["$jieol_qiaobian2"] = "万物变化，固无休息。",


["jieol_xunyu"] = "界荀彧",
["#jieol_xunyu"] = "王佐之才",
["~jieol_xunyu"] = "一招不慎，为虎所噬。",
["jieol_jieming"] = "节命",
[":jieol_jieming"] = "当你受到1点伤害后或死亡后，你可以令一名角色摸X张牌，然后将手牌弃至X张（X为其体力上限且最多为5）。",
["jieol_jieming-invoke"] = "你可以发动“节命”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
["$jieol_jieming1"] = "含气在胸，有进无退。",
["$jieol_jieming2"] = "蕴节于形，生死无惧。",
--["$quhu1"] = "两虎相斗，旁观成败。",
--["$quhu2"] = "驱兽相争，坐收渔利。",

["jieol_dianwei"] = "界典韦",
["#jieol_dianwei"] = "临危横贯",
["~jieol_dianwei"] = "为将者，怎可徒手而亡？",
["jieol_qiangxi"] = "强袭",
[":jieol_qiangxi"] = "出牌阶段限两次，你可以受到1点伤害或弃置一张武器牌，对一名本回合内未以此法指定过的其他角色造成1点伤害。",
["jieol_ninge"] = "狞恶",
[":jieol_ninge"] = "锁定技，当一名角色每回合第二次受到伤害后，若其为你或伤害来源为你，你摸一张牌并弃置其场上一张牌。 ",
["$jieol_qiangxi1"] = "典韦来也！谁敢一战？",
["$jieol_qiangxi2"] = "双戟青钢，百死无生！",
["$jieol_ninge1"] = "古之恶来，今之典韦！",
["$jieol_ninge2"] = "宁为刀俎，不为鱼肉！",



["jieol_lvmeng"] = "界吕蒙",
["#jieol_lvmeng"] = "白衣渡江",
["~jieol_lvmeng"] = "你，给我等着。",
["jieol_qinxue"] = "勤学",
[":jieol_qinxue"] = "觉醒技，准备阶段或结束阶段，若你的手牌数比你的体力值多2或更多，你减1点体力上限，回复1点体力或摸两张牌，然后获得“攻心”。",
["jieol_botu"] = "博圖",
[":jieol_botu"] = "每轮限X次，回合结束时，若此回合内置入弃牌堆的牌包含四种花色，则你可以获得一个额外回合。（X为存活角色数且至多为3） ",
["$jieol_qinxue1"] = "兵书熟读，了然于胸。",
["$jieol_qinxue2"] = "勤以修身，学以报国。",
["$jieol_botu1"] = "时机已到，全军出击！",
["$jieol_botu2"] = "今日起兵，渡江攻敌！",


["jieol_sunce"] = "界孙策",
["#jieol_sunce"] = "江東的小霸王",
["~jieol_sunce"] = "汝等，怎能受于吉蛊惑？",
["jieol_zhibaPindian"] = "制霸",
["jieol_zhiba"] = "制霸",
[":jieol_zhiba"] = "主公技，其他吴势力角色的出牌阶段限一次，其可以与你拼点（你可以拒绝）；你的出牌阶段限一次，你可以与一名其他吴势力角色拼点。若其没赢，你可以获得两张拼点牌。",
["jieol_hunzi"] = "魂姿",
[":jieol_hunzi"] = "觉醒技，准备阶段，若你体力值为1，你减1点体力上限，回复1点体力，获得“英魂”、“英姿”。",
["$jieol_zhiba1"] = "让将军在此恭候多时了。",
["$jieol_zhiba2"] = "有诸位将军在，此战岂会不胜？",
["$jieol_hunzi1"] = "江东新秀，由此崛起。",
["$jieol_hunzi2"] = "看汝等大展英气！",
--["$jiang1"] = "收合流散，东据吴会。",
--["$jiang2"] = "策虽暗稚，窃有微志。",
--["$yingzi1"] = "得公瑾辅助，策必当一战！",
--["$yingzi2"] = "公瑾在此，此战无忧！",
--["$yinghun1"] = "东吴繁盛，望父亲可知。",
--["$yinghun2"] = "父亲，吾定不负你期望！",



["jieol_xiaoqiao"] = "界小乔",
["#jieol_xiaoqiao"] = "矯情之花",
["~jieol_xiaoqiao"] = "同心而离居，忧伤以终老。",
["jieol_tianxiang"] = "天香",
[":jieol_tianxiang"] = "你受到伤害时，你可以弃置一张红桃牌，防止此伤害并选择一名其他角色，若如此做，你选择一项：1.令其受到伤害来源对其造成的1点伤害，然后摸X张牌（X为其已损失的体力值且至多为5）；2.令其失去1点体力，然后其获得你弃置的牌。",
["@jieol_tianxiang"] = "请选择“天香”的目标",
["~jieol_tianxiang"] = "选择一张<font color=\"red\">♥</font>牌→选择一名其他角色→点击确定",
["jieol_hongyan"] = "红颜",
[":jieol_hongyan"] = "锁定技，你的黑桃牌视为红桃牌。若你的装备区有红桃牌，你的手牌上限等于体力上限。",
["jieol_piaoling"] = "飘零",
[":jieol_piaoling"] = "回合结束时，你可进行判定，若结果为红桃，你将判定牌置于牌堆顶或交给一名角色，若该角色是你，你弃置一张牌。",
["jieol_piaoling-invoke"] = "你可以发动“飘零”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
["$jieol_tianxiang1"] = "你岂会懂我的美丽？",
["$jieol_tianxiang2"] = "碧玉闺秀，只可远观。",
["$jieol_hongyan1"] = "我的容貌，让你心动了吗？",
["$jieol_hongyan2"] = "红颜娇花好，折花门前盼。",
["$jieol_piaoling1"] = "花自飘零水自流。",
["$jieol_piaoling2"] = "清风拂君，落花飘零。",

["jieol_sunjian"] = "界孙坚",
["#jieol_sunjian"] = "武烈帝",
["~jieol_sunjian"] = "袁术之辈，不可共谋！",
["jieol_wulie"] = "武烈",
[":jieol_wulie"] = "限定技，结束阶段，你可以选择至多X名其他角色（X为你体力值），你失去等量的体力。若你存活，这些角色各获得一个“烈”（拥有“烈”的角色受到伤害时，移去其“烈”并防止之）。 ",
["@jieol_wulie-card"] = "你可以发动“武烈”",
["~jieol_wulie"] = "选择至多X名其他角色→点击确定",
["@jieol_wulie"] = "武烈",
["@jieol_lie"] = "烈",
--["$yinghun1"] = "提刀奔走，灭敌不休！",
--["$yinghun2"] = "贼寇草莽，我且出战！",
["$jieol_wulie1"] = "孙武之后，英烈勇战！",
["$jieol_wulie2"] = "兴义之中，忠烈之名。",


["jieol_taishici"] = "界太史慈",
["#jieol_taishici"] = "信义笃烈",
["~jieol_taishici"] = "无妄之灾，难以避免。",
["jieol_hanzhan"] = "酣战",
[":jieol_hanzhan"] = "你与其他角色拼点，或其他角色与你拼点时，你可以选择其一张手牌拼点；当你拼点后，你可以获得拼点牌中点数最大的【杀】。",
--["$tianyi1"] = "天降大任，速战解围！",
--["$tianyi2"] = "义不从之，天必不佑！",
["$jieol_hanzhan1"] = "伯符，且与我一战！",
["$jieol_hanzhan2"] = "与君酣战，快哉快哉！",


["jieol_lusu"] = "界鲁肃",
["#jieol_lusu"] = "独断的外交家",
["~jieol_lusu"] = "一生为国，纵死无憾！",
["jieol_dimeng"] = "缔盟",
[":jieol_dimeng"] = "出牌阶段限一次，你可以令两名手牌数之差不大于你牌数的角色交换手牌。此阶段结束时，你弃置其手牌数之差的牌。 ",
["~jieol_haoshi"] = "选择一半手牌→点击确定",
["@jieol_haoshi-give:"] = "你可以交给 %src 一张牌",
["jieol_haoshi"] = "好施",
[":jieol_haoshi"] = "摸牌阶段，你可以多摸两张牌。摸牌阶段结束时，若你的手牌数大于5，你将一半手牌交给手牌数最少的一名其他角色。直到你下回合开始，当你成为【杀】或普通锦囊牌的目标后，其可以交给你一张牌。",
["$jieol_dimeng1"] = "同盟之人，言归于好。",
["$jieol_dimeng2"] = "深知其奇，相与亲结。",
["$jieol_haoshi1"] = "仗义疏财，深得人心。",
["$jieol_haoshi2"] = "招聚少年，给其衣食。",

["jieol_huatuo"] = "界华佗",
["#jieol_huatuo"] = "神医",
["~jieol_huatuo"] = "生老病死，命不可违。",


["jieol_huaxiong"] = "界华雄",
["#jieol_huaxiong"] = "飞扬跋扈",
["~jieol_huaxiong"] = "这，怎么可能……",
["jieol_yaowu"] = "耀武",
[":jieol_yaowu"] = "锁定技，当你受到牌造成的伤害时，若此牌：为红色，伤害来源摸一张牌；不为红色，你摸一张牌。 ",
["jieol_shizhan"] = "势斩",
[":jieol_shizhan"] = "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以令一名其他角色视为对你使用一张【决斗】。",
["$jieol_yaowu1"] = "这些杂兵，我有何惧！",
["$jieol_yaowu2"] = "有吾在此，解太师烦忧。",
["$jieol_shizhan1"] = "兀那汉子，且报上名来！",
["$jieol_shizhan2"] = "看你能坚持几个回合！",

["jieol_gongsunzan"] = "界公孙瓒",
["#jieol_gongsunzan"] = "飞扬跋扈",
["~jieol_gongsunzan"] = "这，怎么可能……",
["jieol_qiaomeng"] = "趫猛",
[":jieol_qiaomeng"] = "当你使用【杀】对目标角色造成伤害后，你可以弃置其区域里的一张牌。若以此法弃置的牌为坐骑牌，则此牌进入弃牌堆后，你获得之。",
["$jieol_qiaomeng1"] = "夺敌辎重，以为己用。",
["$jieol_qiaomeng2"] = "秣马厉兵，枕戈待战。",
--["$ol_yicong1"] = "列阵锋矢，直取要害。",
--["$ol_yicong2"] = "变阵冲轭，以守代攻。",




["jie_zhangjiao"]="界张角",
["~jie_zhangjiao"]="天书无效，人心难聚。",
["jieleiji"]="雷击",
["$jieleiji1"]="雷霆之诛，灭军毁城！",
["$jieleiji2"]="疾雷迅电，不可趋避！",
[":jieleiji"]="当你使用或打出【闪】或【闪电】时，你可以进行一次判定，当你判定结束后，若判定牌为黑桃，你可以对一名其他角色造成2点伤害，为梅花，你回复一点体力值 然后你对一名其他角色造成1点雷电伤害。",
["jieguidao"]="鬼道",
["$jieguidao1"]="汝之命运，吾来改之！",
["$jieguidao2"]="鬼道运行，由我把控！",
[":jieguidao"]="每当一名角色的判定牌生效前，你可以打出一张黑色牌替换之，若你打出的牌是黑桃2~9，你摸一张牌。",
["jieleiji-invoke"]="请选择一名角色",
["jieol_huangtian"] = "黃天",
[":jieol_huangtian"] = "主公技，其他羣勢力角色的出牌阶段限一次，該角色可以將一張【閃】或黑桃手牌交給你。",
["$jieol_huangtian1"] = "天书庇佑，黄巾可兴！",
["$jieol_huangtian2"] = "黄天法力，万军可灭！",

["jie_yuji"]="界于吉",
["jieguhuo"]="蛊惑",
["@@jieguhuo"]="蛊惑",
["guhuo-new"]="蛊惑",
["~jieguhuo"]="请选择目标",
["$jieguhuo1"]="道法玄机，变幻莫测。",
["$jieguhuo2"]="如真似幻，扑朔迷离。",
["guhuo_select"]="蛊惑",
[":jieguhuo"]="每回合限一次，当需要打出或使用牌时，你可以扣置一张手牌当做任意基本牌或锦囊牌打出，然后其他玩家可以选择是否质疑，然后将牌翻回正面，若为真，质疑者全都失去一点体力值并获得技能“缠怨”，该牌将按照你声明的牌继续进行，若为假，则此牌作废，且所有质疑者各摸一张牌。",

["jieol_yuanshao"] = "界袁绍",
["#jieol_yuanshao"] = "高贵的名门",
["~jieol_yuanshao"] = "孟德此计，防不胜防。",
["jieol_xueyi"] = "血裔",
[":jieol_xueyi"] = "主公技，游戏开始时，你获得X个“裔”标记（X为群势力角色数的两倍）；出牌阶段开始时，你可以移除1个“裔”并摸一张牌；你的手牌上限+X（X为“裔”数的两倍）。",
["@jieol_xueyi"] = "裔",
["jieol_luanji"] = "乱击",
[":jieol_luanji"] = "你可以将两张花色相同的手牌当【万箭齐发】使用；你使用【万箭齐发】可以少选一个目标。",
["jieol_luanji-invoke"] = "你可以发动“乱击”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
["$jieol_xueyi1"] = "高贵名门，族裔盛名。",
["$jieol_xueyi2"] = "贵裔之脉，后起之秀！",
["$jieol_luanji1"] = "我的箭支，准备颇多！",
["$jieol_luanji2"] = "谁都挡不住我的箭阵！",

["jieol_pangde"] = "界庞德",
["#jieol_pangde"] = "人马一体",
["~jieol_pangde"] = "人亡马倒，命之所归……",
["jieol_jianchu"] = "鞬出",
[":jieol_jianchu"] = "当你使用【杀】指定一名角色为目标后，你可以弃置其一张牌。若你弃置的牌是：非基本牌，此【杀】不能被响应且你此阶段可以多使用一张【杀】；基本牌，其获得此【杀】。 ",
["$jieol_jianchu1"] = "你这身躯，怎么能快过我？",
["$jieol_jianchu2"] = "这些，怎么能挡住我的威力！",

["jieol_dongzhuo"] = "界董卓",
["#jieol_dongzhuo"] = "魔王",
["~jieol_dongzhuo"] = "地府，可有美人乎？",
["jieol_jiuchi"] = "酒池",
[":jieol_jiuchi"] = "你可以将一张黑桃手牌当【酒】使用。你使用【酒】无次数限制。当你使用受【酒】影响的【杀】造成伤害后，本回合“崩坏”失效。",
["jieol_baonue"] = "暴虐",
[":jieol_baonue"] = "主公技，当其他群势力角色造成1点伤害后，你可进行判定，若结果为黑桃，你回覆1点体力并获得此判定牌。",
["$jieol_jiuchi1"] = "好酒，痛快！",
["$jieol_jiuchi2"] = "某，千杯不醉！",
["$jieol_baonue1"] = "天下群雄，唯我独尊！",
["$jieol_baonue2"] = "吾乃人屠，当以兵为贡。",
--["$roulin1"] = "醇酒美人，幸甚乐甚！",
--["$roulin2"] = "这些美人，都可进贡。",
--["$benghuai1"] = "何人伤我？",
--["$benghuai2"] = "酒色伤身哪……",


["jieol_jiaxu"] = "界贾诩",
["#jieol_jiaxu"] = "冷酷的毒士",
["~jieol_jiaxu"] = "此劫我亦有所算！",
["jieol_weimu"] = "帷幕",
[":jieol_weimu"] = "锁定技，你不能成为黑色锦囊牌的目标；防止你于回合内受到的伤害并摸两倍伤害数的牌。",
["jieol_wansha"] = "完杀",
[":jieol_wansha"] = "锁定技，你的回合内，只有你和处于濒死状态的角色才能使用【桃】；一名角色的濒死结算中，除你和濒死角色外的其他角色非锁定技无效。",
["jieol_luanwu"] = "乱武",
[":jieol_luanwu"] = "限定技，出牌阶段，你可以令所有其他角色依次选择一项：1.对其距离最小的另一名角色使用一张【杀】；2.失去1点体力。所有角色结算完毕后，你可以视为使用一张无距离限制的【杀】。",
["jieol_luanwu-invoke"] = "乱武<br>你可以视为使用一张无距离限制的【杀】",
["$jieol_wansha1"] = "有谁敢试试？",
["$jieol_wansha2"] = "斩草务尽，以绝后患。",
["$jieol_weimu1"] = "此伤与我无关。",
["$jieol_weimu2"] = "还是另寻他法吧！",
["$jieol_luanwu1"] = "一切都在我的掌控中！",
["$jieol_luanwu2"] = "这乱世还不够乱！",

["jieol_caiwenji"] = "界蔡文姬",
["#jieol_caiwenji"] = "异乡的孤女",
["~jieol_caiwenji"] = "飘飘外域里，何日能归乡？",
["jieol_beige"] = "悲歌",
[":jieol_beige"] = "当一名角色受到【杀】造成的伤害后，若你有牌，你可以令其进行一次判定，然后你可以弃置一张牌，根据判定结果执行：红桃，其回复1点体力；方块，其摸两张牌；梅花，伤害来源弃置两张牌；黑桃，伤害来源将武将牌翻面；点数相同，你获得你弃置的牌；花色相同，你获得判定牌。",
["$jieol_beige1"] = "箜篌鸣九霄，闻者心俱伤。",
["$jieol_beige2"] = "琴弹十八拍，听此双泪流。",
--["$duanchang1"] = "红颜留塞外，愁思欲断肠。",
--["$duanchang2"] = "莫吟苦辛曲，此生谁忍闻。",









}
return {extension,extension_jieol,extension_jie,extension_gai, funWeapon}