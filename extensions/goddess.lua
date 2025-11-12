--Tip: The imformation of this package is at the end of this file.
--温馨提示：版本信息，武将及技能总汇见最后。
---------------------------------------------------------------------------
--Ver变量：若版本不为2017.2.11，请将该变量设为0.
Ver = 1
---------------------------------------------------------------------------
--SetLuaPackage	建立扩展包
extension = sgs.Package("goddess", sgs.Package_GeneralPack)
extension_card = sgs.Package("goddesscard", sgs.Package_CardPack)
--extension_v2 = sgs.Package("goddessv2", sgs.Package_GeneralPack)
extension_n = sgs.Package("goddessth", sgs.Package_GeneralPack)
---------------------------------------------------------------------------
--SetGenerals	建立武将
LuaSP_guanyu = sgs.General(extension_n, "LuaSP_guanyu", "wei", 4, true)
LuaTest_caoren = sgs.General(extension_n, "LuaTest_caoren", "wei", 4, true)
Lua_caoren = sgs.General(extension_n, "Lua_caoren", "wei", 4, true)
baiban = sgs.General(extension, "baiban", "god", 6, false)
godzhurong = sgs.General(extension, "godzhurong", "god", 3, false)
godzhenji = sgs.General(extension, "godzhenji", "god", 3, false)
godsunshangxiang = sgs.General(extension, "godsunshangxiang", "god", 3, false)
goddiaochan = sgs.General(extension, "goddiaochan", "god", 3, false)
--wusheng	(武圣)
LuaSP_guanyu:addSkill("wusheng")
--NewDanji	单骑
LuaDanji = sgs.CreateTriggerSkill{
	name = "LuaDanji",
	frequency = sgs.Skill_Wake,
	waked_skills = "mashu",
	events = {sgs.EventPhaseStart},
	-- can_trigger = function(self, target)
	-- 	return target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
	-- 		and target:getMark("danji") == 0 and target:getHandcardNum() > target:getHp()
	-- end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local lord = room:getLord()
		if lord and (string.find(lord:getGeneralName(), "caocao") or string.find(lord:getGeneral2Name(), "caocao")) and player:getHandcardNum() > player:getHp() then
			return true
		end
		return false
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		-- local lord = room:getLord()
		--if lord and (string.find(lord:getGeneralName(), "caocao") or string.find(lord:getGeneral2Name(), "caocao")) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			local choicelist = "loseonehp"
			if player:canDiscard(player, "he") and player:getHandcardNum() + player:getEquips():length() >= 2 then
				choicelist = string.format("%s+%s", choicelist, "distwocards")
			end
			local result = room:askForChoice(player, self:objectName(), choicelist )
			if result == "loseonehp" then
				room:loseHp(player, 1)
			else
				room:askForDiscard(player, self:objectName(), 2, 2)
			end
			local msg = sgs.LogMessage()
			msg.type = "#NewDanji"
			msg.from = player
			msg.arg = result
			room:sendLog(msg)
			room:acquireSkill(player, "mashu")
			room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
			room:setPlayerMark(player, "LuaDanji", 1)
			room:setPlayerMark(player, "danji", 1)
		-- end
	end,
}
LuaSP_guanyu:addSkill(LuaDanji)
--LuaXJianshou	坚守
LuaXJianshou = sgs.CreateTriggerSkill{
	name = "LuaXJianshou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName(), data) then
				local room = player:getRoom()
				local msg = sgs.LogMessage()
				msg.type = "#Dunkeng"
				msg.from = player
				room:sendLog(msg)
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				player:drawCards(5)
				player:turnOver()
			end
		end
	end
}
LuaTest_caoren:addSkill(LuaXJianshou)
--nosjushou	据守
Lua_caoren:addSkill("nosjushou")
--LuaTiebi	铁壁
LuaTiebi = sgs.CreateTriggerSkill{
	name = "LuaTiebi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		if not player:faceUp() then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Dismantlement") then
				return true
			end
		end
	end
}
LuaTiebiD = sgs.CreateDistanceSkill{
	name = "#LuaTiebiD",
	correct_func = function(self, from, to)
		if to:hasSkill("#LuaTiebiD") and not to:faceUp() then
			return 1
		else
			return 0
		end
	end
}
Lua_caoren:addSkill(LuaTiebi)
Lua_caoren:addSkill(LuaTiebiD)
extension_n:insertRelatedSkills("LuaTiebi","#LuaTiebiD")
--GodXiaoshi	消逝
GodXiaoshi = sgs.CreateTriggerSkill{
	name = "GodXiaoshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local list = room:getOtherPlayers(player)
			local cantrigger = false
			for _,p in sgs.qlist(list) do
				if p:getHp() < player:getHp() then
					cantrigger = true
					break
				end
			end
			if cantrigger then
				room:loseHp(player)
				room:broadcastSkillInvoke(self:objectName())
			end
			return false
		end
	end
}
baiban:addSkill(GodXiaoshi)
--GodMeizi	美姿
GodMeizi = sgs.CreateTriggerSkill{
	name = "GodMeizi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		draw.num = draw.num + 1
		data:setValue(draw)
	end
}
GodMeiziMaxCard = sgs.CreateMaxCardsSkill{
	name = "#GodMeiziMaxCard",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			local hp = target:getHp()
			--local room = target:getRoom()
			if hp>0 then
				if hp>4 then
					return 0
				else
					local delta = 4 - hp
					return delta
				end
			else
				return 4
			end
		end
	end
}
baiban:addSkill(GodMeizi)
baiban:addSkill(GodMeiziMaxCard)
extension:insertRelatedSkills("GodMeizi","#GodMeiziMaxCard")
--GodQuxiang	驱象
GodQuxiang = sgs.CreateOneCardViewAsSkill{
	name = "GodQuxiang",
	filter_pattern = ".|black",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local savageassault = sgs.Sanguosha:cloneCard("SavageAssault", suit, point)
		savageassault:setSkillName(self:objectName())
		savageassault:addSubcard(id)
		return savageassault
	end
}
godzhurong:addSkill(GodQuxiang)
--GodSaodang	扫荡
GodSaodang = sgs.CreateTargetModSkill{
	name = "GodSaodang", 
	frequency = sgs.Skill_Compulsory, 
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) then
			return 1
		else
			return 0
		end
	end
}
godzhurong:addSkill(GodSaodang)
--GodYuxiang	御象
GodYuxiang = sgs.CreateTriggerSkill{
	name = "GodYuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			local room = player:getRoom()
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			return true
		else
			return false
		end
	end
}
godzhurong:addSkill(GodYuxiang)
--GodShenfu	神赋
GodShenfu = sgs.CreateTriggerSkill{
	name = "GodShenfu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				while player:askForSkillInvoke(self:objectName()) do
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					local result = room:askForChoice(player, self:objectName(), "blackcard+redcard")
					if result == "blackcard" then
						judge.pattern = ".|black"
						room:setPlayerMark(player, "Shenfublack", 1)
					else
						judge.pattern = ".|red"
						room:setPlayerMark(player, "Shenfublack", 0)
					end
					local msg = sgs.LogMessage()
					msg.type = "#color"
					msg.from = player
					msg.arg = result
					room:sendLog(msg)
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if player:getMark("Shenfublack") > 0 then
					if card:isBlack() then
						player:obtainCard(card)
						return true
					end
				else
					if card:isRed() then
						player:obtainCard(card)
						return true
					end
				end
			end
		end
		return false
	end
}
godzhenji:addSkill(GodShenfu)
--GodShijun	侍君
GodShijunCard = sgs.CreateSkillCard{
	name = "GodShijunCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, source)
		return to_select:getMark("@shijun") == 0 and to_select:objectName() ~= source:objectName()
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		room:setFixedDistance(source, dest, 1)
		room:setFixedDistance(dest, source, 1)
		room:setPlayerMark(dest, "@shijun", 1)
		room:setPlayerMark(dest, "&GodShijun+to+#"..source:objectName().."-Clear", 1)
	end
}
GodShijun = sgs.CreateViewAsSkill{
	name = "GodShijun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return
		end
		local	SkillCard = GodShijunCard:clone()
		SkillCard:addSubcard(cards[1])
		return	SkillCard
	end
}
GodShijunClear = sgs.CreateTriggerSkill{
	name = "#GodShijunClear",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local room = player:getRoom()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@shijun") > 0 then
					room:removeFixedDistance(player, p, 1)
					room:removeFixedDistance(p, player, 1)
					room:setPlayerMark(p, "@shijun", 0)
				end
			end
		end
	end
}	
godzhenji:addSkill(GodShijun)
godzhenji:addSkill(GodShijunClear)
extension:insertRelatedSkills("GodShijun","#GodShijunClear")
--GodYouhua	幼化
GodYouhuaMark = sgs.CreateTriggerSkill{
	name = "#GodYouhuaMark",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local card = data:toCardUse().card
		local IdofLast = card:getId()
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return end
		if card:isKindOf("EquipCard") then
			room:setPlayerMark(player, "LastId", 0)
		else
			room:setPlayerMark(player, "LastId", IdofLast)
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "GodYouhua") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
			room:setPlayerMark(player, "&GodYouhua+:+" .. card:objectName() .. "-Clear", 1)
		end
	end
}
GodYouhuaClear = sgs.CreateTriggerSkill{
	name = "#GodYouhuaClear",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "LastId", 0)
	end
}
GodYouhuaVS = sgs.CreateViewAsSkill{
	name = "GodYouhua",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local Id = sgs.Self:getMark("LastId")
		if Id > 0 then
			if #cards == 1 then
				local card = cards[1]
				if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
					local NewCard = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(Id):objectName(), sgs.Card_SuitToBeDecided, -1)
					NewCard:addSubcard(card:getEffectiveId())
					NewCard:setSkillName("GodYouhua")
					return NewCard
				end
			end
		end
	return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("YouhuaUsed") and player:getMark("LastId") > 0
	end,
}
GodYouhua = sgs.CreateTriggerSkill{
	name = "GodYouhua",
	events = {sgs.CardUsed},
	view_as_skill = GodYouhuaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "GodYouhua" then
			room:setPlayerFlag(player, "YouhuaUsed")
		end
	end
}	
godzhenji:addSkill(GodYouhuaMark)
godzhenji:addSkill(GodYouhuaClear)
godzhenji:addSkill(GodYouhua)
extension:insertRelatedSkills("GodYouhua","#GodYouhuaMark")
extension:insertRelatedSkills("GodYouhua","#GodYouhuaClear")
--GodGongshen	弓神
GodGongshen = sgs.CreateOneCardViewAsSkill{
	name = "GodGongshen",
	filter_pattern = "EquipCard|.|.|.|.",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local ArcheryAttack = sgs.Sanguosha:cloneCard("ArcheryAttack", suit, point)
		ArcheryAttack:setSkillName(self:objectName())
		ArcheryAttack:addSubcard(id)
		return ArcheryAttack
	end
}
godsunshangxiang:addSkill(GodGongshen)
--GodJinguo	巾帼
GodJinguo = sgs.CreateTriggerSkill{
	name = "GodJinguo",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isMale() and player:hasEquip() then
			for _,Sun in sgs.qlist(room:getAllPlayers()) do
				if not Sun or Sun:isDead() or not Sun:hasSkill(self:objectName()) then continue end
				local phase = Sun:getPhase()
				if phase == sgs.Player_NotActive then
					if Sun:askForSkillInvoke(self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						Sun:drawCards(1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
godsunshangxiang:addSkill(GodJinguo)
--GodJiuse	酒色
GodJiuse = sgs.CreateTriggerSkill{
	name = "GodJiuse",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Play then
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.card == nil or not damage.card:isKindOf("Slash") then
				return false
			end
			local Jiugui = sgs.SPlayerList()
			local count = 0
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isMale() and p:inMyAttackRange(damage.to) then
					Jiugui:append(p)
					count = count + 1
				end
			end
			if count>0 then
				--if player:askForSkillInvoke(self:objectName()) then
					room:setTag("CurrentDamageStruct", data)
					local chosenp = room:askForPlayerChosen(player, Jiugui, self:objectName(), "GodJiuse-invoke", true, true)
					room:removeTag("CurrentDamageStruct")
					if not chosenp then return false end
					local msg = sgs.LogMessage()
					msg.type = "#Jiuse"
					msg.from = player
					msg.to:append(chosenp)
					room:sendLog(msg)
					room:broadcastSkillInvoke(self:objectName())
					damage.from = chosenp
					damage.damage = damage.damage + 1
					room:setCardFlag(damage.card, "GodJiuse")
					data:setValue(damage)
				--end
			end	
		end
	end
}
goddiaochan:addSkill(GodJiuse)
--GodManwu	曼舞
GodManwu = sgs.CreateTriggerSkill{
	name = "GodManwu",
	events = {sgs.BeforeCardsMove,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:isMale() then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		elseif player and player:isAlive() and player:hasSkill(self:objectName()) then
			local phase = player:getPhase()
			if phase == sgs.Player_NotActive then
				local PileA = player:getPile("&GodManwuPile")
				if PileA:length() == 0 then
					local move = data:toMoveOneTime()
					if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable)
							and (move.to_place == sgs.Player_DiscardPile)
							and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
						local card = sgs.Sanguosha:getCard(move.card_ids:first())
						if move.from and card:hasFlag("real_SA") and (player:objectName() ~= move.from:objectName()) then
						local CardtoGet = sgs.QVariant()
						CardtoGet:setValue(tostring(move.card_ids:first()))
						room:setTag("GodManwu", CardtoGet)
							if player:askForSkillInvoke(self:objectName()) then
								room:broadcastSkillInvoke(self:objectName())
								player:addToPile("&GodManwuPile", card)
								move.card_ids = sgs.IntList()
								data:setValue(move)
							end
						room:removeTag("GodManwu")
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
GodManwuClear = sgs.CreateTriggerSkill{
	name = "#GodManwuClear",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Play then
			--player:removePileByName("&GodManwuPile")
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _,cd in sgs.qlist(player:getPile("&GodManwuPile")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
						local room = player:getRoom()
						room:throwCard(dummy, reason, nil)
			local room = player:getRoom()
			room:setPlayerCardLimitation(player, "use,response", ".|.|.|&GodManwuPile", true)
		end
	end
}
GodManwuCantdo = sgs.CreateProhibitSkill{
	name = "#GodManwuCantdo",
	is_prohibited = function(self, from, to, card)
		if from and from:getPhase() == sgs.Player_NotActive then
			return sgs.Sanguosha:matchExpPattern(".|.|.|&GodManwuPile", from, card)
		end
	end
}
goddiaochan:addSkill(GodManwu)
goddiaochan:addSkill(GodManwuClear)
goddiaochan:addSkill(GodManwuCantdo)
extension:insertRelatedSkills("GodManwu","#GodManwuClear")
extension:insertRelatedSkills("GodManwu","#GodManwuCantdo")
--GodMeihuo	魅惑
GodMeihuo = sgs.CreateTriggerSkill{
	name = "GodMeihuo",
	events = {sgs.TargetConfirmed, sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:contains(player) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				if player:getMark("GodMeihuoUsed") == 0 then
					room:setPlayerMark(player, "GodSexJudge", player:getGender())
				end
				room:broadcastSkillInvoke(self:objectName())
				player:setGender(sgs.General_Sexless)
				room:setPlayerMark(player, "GodMeihuoUsed", 1)
			end
		elseif event == sgs.CardFinished then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:contains(player) then
				player:setGender(player:getMark("GodSexJudge"))
				room:setPlayerMark(player, "GodMeihuoUsed", 0)
			end
		end
	end
}
goddiaochan:addSkill(GodMeihuo)
--GodShenyou	神佑
GodShenyou = sgs.CreateTriggerSkill{
	name = "GodShenyou",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if (string.find(p:getGeneralName(), "shenlvbu1") or string.find(p:getGeneralName(), "shenlvbu2") or string.find(p:getGeneralName(), "shenlvbu_gui")) then continue end
				if p and (string.find(p:getGeneralName(), "shenlvbu") or string.find(p:getGeneral2Name(), "shenlvbu")) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					p:gainMark("@wrath", damage.damage)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if (string.find(p:getGeneralName(), "shenlvbu1") or string.find(p:getGeneralName(), "shenlvbu2") or string.find(p:getGeneralName(), "shenlvbu_gui")) then continue end
				if p and (string.find(p:getGeneralName(), "shenlvbu") or string.find(p:getGeneral2Name(), "shenlvbu")) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					p:loseMark("@wrath", damage.damage)
				end
			end
		end
	end
}
goddiaochan:addSkill(GodShenyou)
--Translation Part	翻译表
sgs.LoadTranslationTable{
	["goddess"] = "女神包",
	["goddessth"] = "女神雷包",
	["LuaSP_guanyu"] = "新SP关羽",
	["#LuaSP_guanyu"] = "汉寿亭侯",
	["&LuaSP_guanyu"] = "关羽",
	["designer:LuaSP_guanyu"] = "MichaelZ",
	["cv:LuaSP_guanyu"] = "喵小林，官方",
	["illustrator:LuaSP_guanyu"] = "LiuHeng",
	["LuaDanji"] = "单骑",
	[":LuaDanji"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你选择一项：失去一点体力，或弃置2张牌。然后你获得技能“马术”。 ",
	["$LuaDanji"] = "吾兄待我甚厚，誓以共死，今往投之，望曹公见谅。",
	["~LuaSP_guanyu"] = "桃源一拜，恩义常在。",
	["loseonehp"] = "失去一点体力",
	["distwocards"] = "弃置两张牌",
	["#NewDanji"] = "%from  选择了  %arg 。",
	["LuaTest_caoren"] = "蹲坑曹仁",
	["#LuaTest_caoren"] = "大司马",
	["&LuaTest_caoren"] = "曹仁",
	["designer:LuaTest_caoren"] = "民间",
	["LuaXJianshou"] = "坚守",
	[":LuaXJianshou"] = "结束阶段开始时，你可以摸五张牌，然后将你的武将牌翻面。",
	["$LuaXJianshou1"] = "我先蹲坑一会儿。",
	["$LuaXJianshou2"] = "尽管来吧！",
	["~LuaTest_caoren"] = "实在是，守不住了……",
	["#Dunkeng"] = "震惊！ %from  在光天化日之下竟然做出这种事！男人看了沉默，女人看了流泪！没想到 %from  去蹲坑了！",
	["Lua_caoren"] = "民间曹仁",
	["#Lua_caoren"] = "大将军",
	["&Lua_caoren"] = "曹仁",
	["designer:Lua_caoren"] = "民间",
	["LuaTiebi"] = "铁壁",
	[":LuaTiebi"] = "<font color=\"blue\"><b>锁定技，</b></font>你的武将牌背面朝上时，其他角色计算与你的距离时+1，且【过河拆桥】对你无效。",
	["#LuaTiebiD"] = "铁壁",
	["baiban"] = "仙女",
	["#baiban"] = "天国的使者",
	["designer:baiban"] = "MichaelZ",
	["illustrator:baiban"] = "网络",
	["GodXiaoshi"] = "消逝",
	[":GodXiaoshi"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，若你的体力值不为场上最少（或之一），你失去1点体力。",
	["$GodXiaoshi"] = "[升仙]",
	["~baiban"] = "我先走一步。",
	["GodMeizi"] = "美姿",
	[":GodMeizi"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段，你额外摸1张牌。若你的体力值小于4，则你的手牌上限+X，X为4-你的体力值且至多为4。",
	["$GodMeizi"] = "哼！不要小瞧女孩子哟！",
	["godzhurong"] = "神祝融",
	["#godzhurong"] = "火神的后裔",
	["designer:godzhurong"] = "民间",
	["illustrator:godzhurong"] = "降龙之剑",
	["cv:godzhurong"] = "妙妙，三国群英传",
	["GodQuxiang"] = "驱象",
	[":GodQuxiang"] = "出牌阶段，你可以将你的任意一张黑色牌当做【南蛮入侵】使用。",
	["$GodQuxiang"] = "万象奔腾，随吾心意。",
	["$GodSaodang"] = "烈刃之火，橫掃千軍",
	["GodSaodang"] = "扫荡",
	[":GodSaodang"] = "<font color=\"blue\"><b>锁定技，</b></font>你的杀可额外指定一个目标。",
	["GodYuxiang"] = "御象",
	[":GodYuxiang"] = "<font color=\"blue\"><b>锁定技，</b></font>【南蛮入侵】对你无效。",
	["$GodYuxiang1"] = "（象叫声）",
	["$GodYuxiang2"] = "（象啼声）",
	["~godzhurong"] = "火神湮逝，妾身去矣。",
	["godzhenji"] = "神甄姬",
	["#godzhenji"] = "流浪之美姬",
	["designer:godzhenji"] = "民间",
	["illustrator:godzhenji"] = "火凤三国OL",
	["GodShenfu"] = "神赋",
	[":GodShenfu"] = "准备阶段开始时，你可以选择一种颜色并进行一次判定，若判定结果与你选择的颜色相同，你获得生效后的判定牌且你可以再次发动技能“神赋”。",
	["$GodShenfu1"] = "仿佛兮若轻云之蔽月。",
	["$GodShenfu2"] = "飘摇兮若流风之回雪。",
	["blackcard"] = "黑色",
	["redcard"] = "红色",
	["#color"] = "%from  选择了颜色  %arg 。",
	["GodShijun"] = "侍君",
	["godshijun"] = "侍君",
	[":GodShijun"] = "出牌阶段，你可以弃置一张手牌并指定一名本回合内未用此法指定过的其他角色，该角色本回合内与你的距离始终为1。",
	["$GodShijun1"] = "请休息吧。",
	["$GodShijun2"] = "你累了。",
	["@shijun"] = "侍君",
	["GodYouhua"] = "幼化",
	[":GodYouhua"] = "<font color=\"green\"><b>阶段技，</b></font>出牌阶段，若本回合内你使用的上一张牌不为装备牌且不为转化的牌，则你可以将一张牌当做本回合内你使用的上一张牌使用。",
	["$GodYouhua"] = "你可要看好了！",
	["~godzhenji"] = "悼良会之永绝兮，哀一逝而异乡。",
	["godsunshangxiang"] = "神孙尚香",
	["#godsunshangxiang"] = "习武的郡主",
	["designer:godsunshangxiang"] = "民间",
	["illustrator:godsunshangxiang"] = "三国群英传2 Online",
	["GodGongshen"] = "弓神",
	[":GodGongshen"] = "出牌阶段，你可以将你的任意一张装备牌当做【万箭齐发】使用。",
	["$GodGongshen"] = "弓马何须系红妆？",
	["GodJinguo"] = "巾帼",
	[":GodJinguo"] = "你的回合外，一名男性角色受到伤害后，若其装备区内有牌，你可以摸一张牌。",
	["$GodJinguo1"] = "双剑夸俏，不让须眉！",
	["$GodJinguo2"] = "谁说女子不如男？",
	["~godsunshangxiang"] = "不，还不可以死！",
	["goddiaochan"] = "神貂蝉",
	["#goddiaochan"] = "连环美人",
	["designer:goddiaochan"] = "民间",
	["illustrator:goddiaochan"] = "三国群英传2 Online",
	["GodJiuse"] = "酒色",
	["$GodJiuse"] = "妾身，向來仰慕勇武強者",
	["GodJiuse"] = "酒色",
	[":GodJiuse"] = "出牌阶段，当你对一名角色使用【杀】造成伤害时，你可以指定该角色在其攻击范围内的一名男性角色，伤害来源为该男性角色且此【杀】造成的伤害+1。",
	["GodJiuse-invoke"] =  "你可以发动“酒色”<br/> <b>操作提示</b>: 选择一名男性角色→点击确定<br/>",
	["#Jiuse"] = "%from  把伤害来源转移给了 %to  ",
	["GodManwu"] = "曼舞",
	["$GodManwu"] = "名花傾國兩相歡，願得將軍帶笑看",
	[":GodManwu"] = "你的回合外，当任意一名其他男性角色使用的非转化的牌在结算后置入弃牌堆时，若你的武将牌上没有牌，你可以将其置于你的武将牌上。出牌阶段，你可以将你的“曼舞”牌当做手牌使用或打出。出牌阶段结束时，你须弃置你的“曼舞”牌。",
	["&GodManwuPile"] = "曼舞",
	["GodMeihuo"] = "魅惑",
	["$GodMeihuo"] = "縱有萬般不捨，又能如何",
	[":GodMeihuo"] = "<font color=\"blue\"><b>锁定技，</b></font>当你成为【杀】的目标时，你视为无性别，直至该【杀】结算完毕。",
	["GodShenyou"] = "神佑",
	[":GodShenyou"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到1点伤害后，神吕布获得1枚“暴怒”标记。每当你造成1点伤害后，神吕布失去1枚“暴怒”标记。",
}
---------------------------------------------------------------------------
--Card Package
shot = sgs.CreateBasicCard{
	name = "shot",
	class_name = "shot",
	subtype = "attack_card",
	suit = 0,
	number = 7,
	target_fixed = false,
	can_recast = false,
	damage_card = true,
	single_target = true,
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("UseHistory"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			room:cardEffect(effect)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setEmotion(source, "killer");
		local card_use = sgs.CardUseStruct()
		card_use.from = source
		card_use.to:append(target)
		card_use.card = effect.card
		if not room:askForCard(target, "jink", "shot-jink", ToData(effect), sgs.Card_MethodUse, source, false, "", false,effect.card) then
			room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
		end
	end,
}
shot:setParent(extension_card)
local shot_clone = shot:clone(1, 6)
shot_clone:setParent(extension_card)
local shot_clone = shot:clone(1, 8)
shot_clone:setParent(extension_card)
local shot_clone = shot:clone(2, 10)
shot_clone:setParent(extension_card)
local shot_clone = shot:clone(3, 11)
shot_clone:setParent(extension_card)

thunder_shot = sgs.CreateBasicCard{
	name = "thunder_shot",
	class_name = "thunder_shot",
	subtype = "attack_card",
	suit = 0,
	number = 7,
	target_fixed = false,
	can_recast = false,
	damage_card = true,
	single_target = true,
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("UseHistory"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			room:cardEffect(effect)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setEmotion(source, "killer");
		local card_use = sgs.CardUseStruct()
		card_use.from = source
		card_use.to:append(target)
		card_use.card = effect.card
		if not room:askForCard(target, "jink", "shot-jink", ToData(effect), sgs.Card_MethodUse, source, false, "", false,effect.card) then
			room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, sgs.DamageStruct_Thunder))
		end
	end,
}
thunder_shot:setParent(extension_card)
local thunder_shot_clone = thunder_shot:clone(0, 8)
thunder_shot_clone:setParent(extension_card)

fire_shot = sgs.CreateBasicCard{
	name = "fire_shot",
	class_name = "fire_shot",
	subtype = "attack_card",
	suit = 3,
	number = 4,
	target_fixed = false,
	can_recast = false,
	damage_card = true,
	single_target = true,
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("UseHistory"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			room:cardEffect(effect)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setEmotion(source, "killer");
		local card_use = sgs.CardUseStruct()
		card_use.from = source
		card_use.to:append(target)
		card_use.card = effect.card
		if not room:askForCard(target, "jink", "shot-jink", ToData(effect), sgs.Card_MethodUse, source, false, "", false,effect.card) then
			room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, sgs.DamageStruct_Fire))
		end
	end,
}
fire_shot:setParent(extension_card)
local fire_shot_clone = fire_shot:clone(3, 8)
fire_shot_clone:setParent(extension_card)

Kai = sgs.CreateBasicCard{
	name = "Kai",
	class_name = "Kai",
	suit = 1,
	number = 11,
	subtype = "defense_card",
	target_fixed = true,
	can_recast = false,
	filter = function(self, targets, to_select)
		return false
	end,
	available = function(self, player)
		return false
	end,
}
--Why Kai_Skill is so long is it must be used with Weikai_Skill, or there will be something wrong with the game.
Kai_Skill = sgs.CreateTriggerSkill{
	name = "Kai_Skill",
	events = {sgs.TargetConfirmed, sgs.CardAsked},
	global = true,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.to:contains(player) then
				if use.card:isKindOf("Slash") or use.card:isKindOf("shot") or use.card:isKindOf("thunder_shot") or use.card:isKindOf("fire_shot") then
					room:setPlayerMark(player, "KaiMark", 1)
				else
					room:setPlayerMark(player, "KaiMark", 0)
				end
			end
		elseif event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			local prompt = data:toStringList()[2]
			local room = player:getRoom()
			if player:getMark("KaiMark")>0 then
				local Kaihave = 0
				for _, c in sgs.qlist(player:getHandcards()) do
					if c:isKindOf("Kai") then 
						Kaihave = 1 
					end
				end
				if Kaihave ~= nil then
					if Kaihave>0 and pattern == "jink" then
						local card = room:askForCard(player, "Kai", "Kai-Jink", data, sgs.Card_MethodResponse)
						if card then
							if Ver == 1 then
								room:setPlayerMark(player, "PoAskNotBreak", 1)
								room:setPlayerMark(player, "PoUsed", 0)
								room:setPlayerMark(player, "WillDisable", 0)
								--player:speak("0001")
								while (player:getMark("PoAskNotBreak")>0)
								do	
									--player:speak("0001.1")
									for _, p in sgs.qlist(room:getAlivePlayers()) do
										if player:getMark("WillDisable") == 0 then
											room:setPlayerMark(p, "Pohave", 0)
											for _, c in sgs.qlist(p:getHandcards()) do
												if c:isKindOf("Weikai") then 
													room:setPlayerMark(p, "Pohave", 1)
												end
											end
											--player:speak("0001.2")
											if p:getMark("Pohave")>0 then
												local pro
												if player:getMark("PoUsed") == 0 then
													pro = string.format("@PoAsk:::%s:", "Kai")
												else
													pro = "PoAskPo"
												end										
												--player:speak("0001.3")
												local cardkai = room:askForCard(p, "Weikai", pro, data, sgs.Card_MethodUse)
												if cardkai then
													room:setPlayerMark(player, "WillDisable", 1)
												end
											end
										end
									end
									room:setPlayerMark(player, "PoAskNotBreak", 0)
									for _, p in sgs.qlist(room:getAlivePlayers()) do
										if player:getMark("WillDisable")>0 then
											room:setPlayerMark(p, "Pohave", 0)
												for _, c in sgs.qlist(p:getHandcards()) do
													if c:isKindOf("Weikai") then 
													room:setPlayerMark(p, "Pohave", 1)
												end
											end
											if p:getMark("Pohave")>0 then
												local cardkaidisable = room:askForCard(p, "Weikai", "PoAskPo", data, sgs.Card_MethodUse)
												if cardkaidisable then
													room:setPlayerMark(player, "WillDisable", 0)	
													room:setPlayerMark(player, "PoAskNotBreak", 1)
												end
											end
										end
									end
									if player:getMark("WillDisable")>0 then
										--This part is a joke of the Card.You can delete it if you'd like.
										player:speak("Fuck You!")
										for _, p in sgs.qlist(room:getAllPlayers()) do
											if p:objectName() ~= player:objectName() then
												p:speak("Language!")
											end
										end
										--Joke End
										local againmes = string.format("@PoAskAgain:::%s:", "Kai")
										room:setPlayerMark(player, "Again", 1)
										
										local cardagain = room:askForCard(player, "Kai", againmes, data, sgs.Card_MethodResponse)
										if cardagain then
											room:setPlayerMark(player, "WillDisable", 0)	
											room:setPlayerMark(player, "PoAskNotBreak", 1)
										else
											room:setPlayerMark(player, "Again", 0)
										end
									end
								end
							end
							--player:speak("0002")
							if player:getMark("WillDisable")>0 then
								--This part is a joke of the Card.You can delete it if you'd like.
								player:speak("Fuck You!")
								for _, p in sgs.qlist(room:getAllPlayers()) do
									if p:objectName() ~= player:objectName() then
										p:speak("Language!")
									end
								end
							else
								room:setPlayerMark(player, "KaiName", 1)
								--player:speak("0003")
								local clone_jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
								clone_jink:addSubcard(card)
								--player:speak("0004")
								room:provide(clone_jink)
								player:drawCards(1)								
								room:setPlayerMark(player, "WillDisable", 0)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	priority = 1
}
local Kai_SkillList=sgs.SkillList()
if not sgs.Sanguosha:getSkill("Kai_Skill") then 
	Kai_SkillList:append(Kai_Skill) 
end
sgs.Sanguosha:addSkills(Kai_SkillList)
Kai:setParent(extension_card)
local Kai_clone = Kai:clone(2, 3)
Kai_clone:setParent(extension_card)
local Kai_clone = Kai:clone(3, 2)
Kai_clone:setParent(extension_card)
local Kai_clone = Kai:clone(3, 5)
Kai_clone:setParent(extension_card)
local Kai_clone = Kai:clone(3, 5)
Kai_clone:setParent(extension_card)

Weikai = sgs.CreateBasicCard{
	name = "Weikai",
	class_name = "Weikai",
	subtype = "solve_card",
	suit = 1,
	number = 9,
	target_fixed = true,
	can_recast = false,
	filter = function(self, targets, to_select)
		return false
	end,
	available = function(self, player)
		return false
	end,
}
--Weikai_Skill must be used with Kai_Skill, or there will be something wrong with the game.
Weikai_Skill = sgs.CreateTriggerSkill{
	name = "Weikai_Skill",
	events = {sgs.CardUsed, sgs.CardResponded},
	global = true,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		if event == sgs.CardUsed then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") and not use.card:isKindOf("Weikai") and not use.card:isKindOf("Kai") then
				if use.card:isKindOf("Jink") and player:getMark("KaiName")>0 then
					room:setPlayerMark(player, "KaiName", 0)
				else
					--player:speak("0005")
					room:setPlayerMark(player, "PoAskNotBreak", 1)
					room:setPlayerMark(player, "PoUsed", 0)
					while (player:getMark("PoAskNotBreak")>0)
					do	
						local temp
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if not use.card:hasFlag("WillDisable") then
								room:setPlayerMark(p, "Pohave", 0)
								for _, c in sgs.qlist(p:getHandcards()) do
									if c:isKindOf("Weikai") then 
										room:setPlayerMark(p, "Pohave", 1)
									end
								end
								if p:getMark("Pohave")>0 then
									local pro
									if player:getMark("PoUsed") == 0 then
										pro = string.format("@PoAsk:::%s:", use.card:objectName())
									else
										pro = "PoAskPo"
									end
									local card = room:askForCard(p, "Weikai", pro, data, sgs.Card_MethodUse, use.from, false,  "", false, use.card)
									if card then
										room:setCardFlag(use.card, "WillDisable")
										temp = card
										-- player:speak("SetFlagSuccessful-Use")
									end
								end
							end
						end
						room:setPlayerMark(player, "PoAskNotBreak", 0)
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if use.card:hasFlag("WillDisable") then
								room:setPlayerMark(p, "Pohave", 0)
									for _, c in sgs.qlist(p:getHandcards()) do
										if c:isKindOf("Weikai") then 
										room:setPlayerMark(p, "Pohave", 1)
									end
								end
								if p:getMark("Pohave")>0 then
									room:setTag("Weikai", ToData(temp))
									local card = room:askForCard(p, "Weikai", "PoAskPo", data, sgs.Card_MethodUse, use.from, false,  "", false, temp)
									room:removeTag("Weikai")
									if card then
										room:setCardFlag(use.card, "-WillDisable")									
										room:setCardFlag(use.card, "-response_failed")
										room:setPlayerMark(player, "PoAskNotBreak", 1)
									end
								end
							end
						end
					end
				end
				if use.card:hasFlag("WillDisable") or use.card:hasFlag("response_failed") then			
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		elseif event == sgs.CardEffected then
			local room = player:getRoom()
			local card = data:toCardEffect().card
			if card:hasFlag("WillDisable") or card:hasFlag("response_failed") then			
				--player:speak("GetFlagSuccessful-Card")	
				return true
			end
		elseif Ver == 1 then
			if event == sgs.CardResponded then
				local room = player:getRoom()
				local resp = data:toCardResponse()
				if resp.m_card:isKindOf("BasicCard") and not resp.m_card:isKindOf("Weikai") and not resp.m_card:isKindOf("Kai") then
					if resp.m_card:isKindOf("Jink") and player:getMark("KaiName")>0 then
						room:setPlayerMark(player, "KaiName", 0)
					elseif player:getMark("Again")>0 then
						room:setPlayerMark(player, "Again", 0)
					else
						--player:speak("0006")
						room:setPlayerMark(player, "PoAskNotBreak", 1)
						room:setPlayerMark(player, "PoUsed", 0)
						while (player:getMark("PoAskNotBreak")>0)
						do				
							local temp
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if not resp.m_card:hasFlag("WillDisable") then
									room:setPlayerMark(p, "Pohave", 0)
									for _, c in sgs.qlist(p:getHandcards()) do
										if c:isKindOf("Weikai") then 
											room:setPlayerMark(p, "Pohave", 1)
										end
									end
									if p:getMark("Pohave")>0 then
										local pro
										if player:getMark("PoUsed") == 0 then
											pro = string.format("@PoAsk:::%s:", resp.m_card:objectName())
										else
											pro = "PoAskPo"
										end
										local card = room:askForCard(p, "Weikai", pro, data, sgs.Card_MethodUse)
										if card then
											room:setCardFlag(resp.m_card, "WillDisable")
											room:setCardFlag(resp.m_card, "response_failed")
											room:setPlayerMark(player, "JinkPoed", resp.m_card:getEffectiveId()+666)
											temp = card
											--player:speak("SetFlagSuccessful-Response")
										end
									end
								end
							end
							room:setPlayerMark(player, "PoAskNotBreak", 0)
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if resp.m_card:hasFlag("WillDisable") then
									room:setPlayerMark(p, "Pohave", 0)
										for _, c in sgs.qlist(p:getHandcards()) do
											if c:isKindOf("Weikai") then 
											room:setPlayerMark(p, "Pohave", 1)
										end
									end
									if p:getMark("Pohave")>0 then
										room:setTag("Weikai", ToData(temp))
										local card = room:askForCard(p, "Weikai", "PoAskPo", data, sgs.Card_MethodUse)
										room:removeTag("Weikai")
										if card then
											room:setCardFlag(resp.m_card, "-WillDisable")									
											room:setCardFlag(resp.m_card, "-response_failed")
											room:setPlayerMark(player, "JinkPoed", 0)
											room:setPlayerMark(player, "PoAskNotBreak", 1)
										end
									end
								end
							end
							if resp.m_card:hasFlag("WillDisable") then
								local cardresped
								if resp.m_card:objectName() == "thunder_slash" or resp.m_card:objectName() == "fire_slash" then
									cardresped = "slash"
								else
									cardresped = resp.m_card:objectName()
								end
								local againmes = string.format("@PoAskAgain:::%s:", cardresped)
								room:setPlayerMark(player, "Again", 1)
								local cardagain = room:askForCard(player, cardresped, againmes, data, sgs.Card_MethodResponse)
								if cardagain then
									room:setCardFlag(resp.m_card, "-WillDisable")									
									room:setCardFlag(resp.m_card, "-response_failed")
									room:setPlayerMark(player, "JinkPoed", 0)
									room:setPlayerMark(player, "PoAskNotBreak", 1)
								else
									room:setPlayerMark(player, "Again", 0)
								end
							end
						end
					end
					if resp.m_card and resp.m_card:hasFlag("response_failed") then
						resp.nullified = true
						data:setValue(resp)
					end
				end			
			elseif event == sgs.JinkEffect then	
				local jink = data:toCard()			
				--player:speak(jink:getEffectiveId())
				if jink and jink:getEffectiveId() >= 0 and player:getMark("JinkPoed") == jink:getEffectiveId()+666 then
					local room = player:getRoom()
					room:setPlayerMark(player, "JinkPoed", 0)
					--player:speak(jink:getEffectiveId())	
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	priority = 4
}
local Weikai_SkillList=sgs.SkillList()
if not sgs.Sanguosha:getSkill("Weikai_Skill") then 
	Weikai_SkillList:append(Weikai_Skill) 
end
sgs.Sanguosha:addSkills(Weikai_SkillList)
Weikai:setParent(extension_card)
local Weikai_clone = Weikai:clone(1, 11)
Weikai_clone:setParent(extension_card)
local Weikai_clone = Weikai:clone(2, 3)
Weikai_clone:setParent(extension_card)
local Weikai_clone = Weikai:clone(2, 7)
Weikai_clone:setParent(extension_card)
local Weikai_clone = Weikai:clone(3, 2)
Weikai_clone:setParent(extension_card)

Su = sgs.CreateBasicCard{
	name = "Su",
	class_name = "Su",
	subtype = "recover_card",
	suit = 2,
	number = 9,
	target_fixed = false,
	damage_card = false,
	single_target = false,
	can_recast = false,
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:getHp() < to_select:getMaxHp() and #targets < 2
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets < 3
	end,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local recover = sgs.RecoverStruct()
		recover.recover = 1
		recover.who = source
		room:recover(target, recover, true)
	end,
}
Su:setParent(extension_card)
local Su_clone = Su:clone(3, 12)
Su_clone:setParent(extension_card)

gongcheng = sgs.CreateTrickCard{
	name = "gongcheng",
	class_name = "gongcheng",
	subtype = "single_target_trick",
	suit = 1,
	number = 5,
	target_fixed = true,
	can_recast = false,
	available = function(self, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local room = source:getRoom()
		room:setPlayerMark(source, "@GongchengM", 1)
	end,
}
gongcheng_skill = sgs.CreateTargetModSkill{
	name = "gongcheng_skill",
	global = true,
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player)
		if player:getMark("@GongchengM")>0 then
			return 1000
		else
			return 0
		end
	end
}
gongcheng_clear = sgs.CreateTriggerSkill{
	name = "gongcheng_clear",
	events = {sgs.EventPhaseEnd},
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		if player:getMark("@GongchengM")>0 then
			local room = player:getRoom()
			room:setPlayerMark(player, "@GongchengM", 0)
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}	
local Gongcheng_SkillList=sgs.SkillList()
if not sgs.Sanguosha:getSkill("gongcheng_skill") then 
	Gongcheng_SkillList:append(gongcheng_skill) 
end
if not sgs.Sanguosha:getSkill("gongcheng_clear") then 
	Gongcheng_SkillList:append(gongcheng_clear) 
end
sgs.Sanguosha:addSkills(Gongcheng_SkillList)
gongcheng:setParent(extension_card)
local gongcheng_clone = gongcheng:clone(1, 7)
gongcheng_clone:setParent(extension_card)

xianzhencard = sgs.CreateTrickCard{
	name = "xianzhencard",
	class_name = "xianzhencard",
	subtype = "special_AOE",
	suit = 0,
	number = 10,
	target_fixed = true,
	can_recast = false,
	available = function(self, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		local targets = room:getOtherPlayers(source)
		for _, target in sgs.qlist(targets) do
			if target:isAlive() and (not target:isAllNude()) and (not source:isProhibited(target, self)) then
				room:cardEffect(self, source, target)
			end
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		if source:canDiscard(target, "hej") then
			local id = room:askForCardChosen(source, target, "jhe", "xianzhencard")
			room:throwCard(id, target, source)
		end
	end
}
xianzhencard:setParent(extension_card)
local xianzhencard_clone = xianzhencard:clone(2, 4)
xianzhencard_clone:setParent(extension_card)
local xianzhencard_clone = xianzhencard:clone(3, 12)
xianzhencard_clone:setParent(extension_card)

manbing = sgs.CreateTrickCard{
	name = "manbing",
	class_name = "manbing",
	subtype = "single_target_trick",
	suit = 3,
	number = 3,
	damage_card = true,
	target_fixed = false,
	can_recast = false,	
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local responsecard1 = room:askForCard(target, "slash", "manbing-slash1", ToData(effect), sgs.Card_MethodResponse, source, false, "manbing", true, effect.card)
		if responsecard1 then
			local responsecard2 = room:askForCard(target, "slash", "manbing-slash2", ToData(effect), sgs.Card_MethodResponse,source, false, "manbing", true, effect.card)
			if responsecard2 then
			--This part is a joke of the Card.You can delete it if you'd like.
				local msg = sgs.LogMessage()
				msg.type = "#ManbingSuccess"
				msg.from = target
				room:sendLog(msg)
				source:speak("Fuck You!")
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:objectName() ~= source:objectName() then
						p:speak("Language!")
					end
				end
				target:speak("2333???")
			else
				room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
			end
		else
			room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))	
		end
	end
}
manbing:setParent(extension_card)
local manbing_clone = manbing:clone(3, 4)
manbing_clone:setParent(extension_card)

quanxiang = sgs.CreateTrickCard{
	name = "quanxiang",
	class_name = "quanxiang",
	subtype = "single_target_trick",
	suit = 0,
	number = 4,
	target_fixed = false,
	can_recast = false,	
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and to_select:getHandcardNum()<source:getHandcardNum() and to_select:getHandcardNum()>0 and to_select:getMark("@RemoveGeneral") == 0 and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local card = room:askForCardShow(target, source, "quanxiang")
		if card then
			local id = card:getEffectiveId()
			room:showCard(target, id)
			local realnumber = card:getNumber()
			local number = card:getNumber()+1
			local message
			if realnumber == 1 then
				message = string.format("@quanxiangmessage:%s::%s", target:getGeneralName(), "A")
			elseif realnumber == 11 then			
				message = string.format("@quanxiangmessage:%s::%s", target:getGeneralName(), "J")
			elseif realnumber == 12 then			
				message = string.format("@quanxiangmessage:%s::%s", target:getGeneralName(), "Q")
			elseif realnumber == 13 then			
				message = string.format("@quanxiangmessage:%s::%s", target:getGeneralName(), "K")
			else		
				message = string.format("@quanxiangmessage:%s::%d", target:getGeneralName(), realnumber)
			end
			local responsecard = room:askForCard(source, ".|.|"..number.."~|hand|.", message, ToData(effect), sgs.Card_MethodDiscard,target, false, "quanxiang", true, effect.card)
			if responsecard then
				room:setPlayerMark(target, "@RemoveGeneral", 1)
				local msg = sgs.LogMessage()
				msg.type = "#RemoveGeneral"
				msg.from = target
				room:sendLog(msg)
			end
		end
	end
}
quanxiang:setParent(extension_card)
local quanxiang_clone = quanxiang:clone(1, 12)
quanxiang_clone:setParent(extension_card)
local quanxiang_clone = quanxiang:clone(2, 1)
quanxiang_clone:setParent(extension_card)

shuigong = sgs.CreateTrickCard{
	name = "shuigong",
	class_name = "shuigong",
	subtype = "single_target_trick",
	suit = 0,
	number = 5,
	target_fixed = false,
	damage_card = true,
	can_recast = false,	
	filter = function(self, targets, to_select,source)
		if source:isProhibited(to_select,self) then return end
		return to_select:objectName() ~= source:objectName() and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = target
		judge.good = true
		judge.reason = self:objectName()
		room:judge(judge)
		if judge.card:isKindOf("BasicCard") then
			local message = string.format("@shuigongmessage_BasicCard:%s:::", target:getGeneralName())
			local responsecard = room:askForCard(source, "BasicCard|.|.|hand|.", message, sgs.QVariant(), sgs.Card_MethodDiscard)
			if responsecard then
				room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
			end	
		elseif judge.card:isKindOf("TrickCard") then
			local message = string.format("@shuigongmessage_TrickCard:%s:::", target:getGeneralName())
			local responsecard = room:askForCard(source, "TrickCard|.|.|hand|.", message, sgs.QVariant(), sgs.Card_MethodDiscard)
			if responsecard then
				room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
			end	
		elseif judge.card:isKindOf("EquipCard") then
			local message = string.format("@shuigongmessage_EquipCard:%s:::", target:getGeneralName())
			local responsecard = room:askForCard(source, "EquipCard|.|.|hand|.", message, sgs.QVariant(), sgs.Card_MethodDiscard)
			if responsecard then
				room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
			end	
		end		
	end
}
shuigong:setParent(extension_card)
local shuigong_clone = shuigong:clone(1, 3)
shuigong_clone:setParent(extension_card)
local shuigong_clone = shuigong:clone(1, 12)
shuigong_clone:setParent(extension_card)
local shuigong_clone = shuigong:clone(2, 5)
shuigong_clone:setParent(extension_card)
local shuigong_clone = shuigong:clone(3, 11)
shuigong_clone:setParent(extension_card)

boyidujiang = sgs.CreateTrickCard{
	name = "boyidujiang",
	class_name = "boyidujiang",
	subtype = "single_target_trick",
	suit = 0,
	number = 11,
	target_fixed = false,
	can_recast = true,	
	filter = function(self, targets, to_select)
		return sgs.self:distanceTo(targets)>=3 and #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local responsecard1 = room:askForCard(target, "jink", "boyidujiang-jink1", sgs.QVariant(), sgs.Card_MethodResponse)
		if responsecard1 then
			local responsecard2 = room:askForCard(target, "jink", "boyidujiang-jink2", sgs.QVariant(), sgs.Card_MethodResponse)
			if responsecard2 then
			else
				room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
			end
		else
			room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))	
		end
	end,
}
--boyidujiang:setParent(extension_card)
local boyidujiang_clone = boyidujiang:clone(0, 13)
--boyidujiang_clone:setParent(extension_card)
local boyidujiang_clone = boyidujiang:clone(3, 12)
--boyidujiang_clone:setParent(extension_card)

sgs.LoadTranslationTable{
	["goddesscard"] = "女神包",
	["shot"] = "射",
	[":shot"] = "基本牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名其他角色<br /><b>效果：</b>对目标角色造成1点伤害。<br /><font color=\"red\"><b>注意：</b></font>不能触发任何有关【杀】的技能，如铁骑，寒冰剑等。",
	["shot-jink"] = "%src 使用了<font color=\"red\">【射】</font>，请使用一张<font color=\"red\">【闪】</font>",
	["thunder_shot"] = "雷射",
	[":thunder_shot"] = "基本牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名其他角色<br /><b>效果：</b>对目标角色造成1点雷属性伤害。<br /><font color=\"red\"><b>注意：</b></font>不能触发任何有关【杀】的技能，如铁骑，寒冰剑等。",
	["fire_shot"] = "火射",
	[":fire_shot"] = "基本牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名其他角色<br /><b>效果：</b>对目标角色造成1点火属性伤害。<br /><font color=\"red\"><b>注意：</b></font>不能触发任何有关【杀】的技能，如铁骑，寒冰剑等。",
	["Kai"] = "正開",
	[":Kai"] = "基本牌<br /><b>时机：</b>成为【杀】或【射】的目标时<br /><b>效果：</b>将此牌当做【闪】打出，并摸一张牌",
	["Kai-Jink"] = "你成为了【杀】或【射】的目标，现在可以将一张【正開】当做【闪】使用或打出，并摸一张牌。",
	["Kai_Skill"] = "開",
	["Weikai"] = "开",
	["solve_card"] = "破解牌",
	["@PoAsk"] = "是否对该【%arg】使用【开】",
	["PoAskPo"] = "是否对该【开】使用【开】",
	["@PoAskAgain"] = "请再打出一张【%arg】",
	["Su"] = "酥",
	[":Su"] = "基本牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一至两名已受伤的角色<br /><b>效果：</b>所有目标角色恢复1点体力",
	["gongcheng"] = "攻城",
	[":gongcheng"] = "锦囊牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>你<br /><b>效果：</b>本回合内你可以使用任意数量的【杀】",
	["@GongchengM"] = "攻城",
	["xianzhencard"] = "陷阵",
	[":xianzhencard"] = "锦囊牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>所有其他角色<br /><b>效果：</b>你弃置每名其他角色区域里的一张牌",
	["special_AOE"] = "群体锦囊",
	["manbing"] = "蛮兵",
	[":manbing"] = "锦囊牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名其他角色<br /><b>效果：</b>该角色须连续打出2张【杀】，否则受到1点伤害",
	["manbing-slash1"] = "使用者使用了<font color=\"red\">【蛮兵】</font>，你须连续打出2张<font color=\"red\">【杀】</font>",
	["manbing-slash2"] = "使用者使用了<font color=\"red\">【蛮兵】</font>，你须再打出1张<font color=\"red\">【杀】</font>",
	["#ManbingSuccess"] = "<font color=\"red\"><b>恭喜！</b></font> %from  成功抵御了蛮兵的攻击！",
	["quanxiang"] = "劝降",
	[":quanxiang"] = "锦囊牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名手牌数小于你且武将牌未移出游戏的其他角色<br /><b>效果：</b>该角色展示一张手牌，然后若你弃置一张点数大于所展示牌的手牌，则该角色武将牌移出游戏<br /><b>备注：</b><font color=\"pink\"><b>武将牌移出游戏：</b></font>当你的武将被移出游戏后，你的所有技能无效。回合开始时，若你的武将牌被移出游戏，则你跳过本回合并将你的武将牌移回游戏（优先于翻面）",
	["@quanxiangmessage"] = "你可以弃置一张点数大于%arg的牌，令%src的武将牌移出游戏",
	["shuigong"] = "水攻",
	[":shuigong"] = "锦囊牌<br /><b>时机：</b>出牌阶段<br /><b>目标：</b>任意一名其他角色<br /><b>效果：</b>该角色需进行一次判定，然后若你弃置一张与判定牌类别相同的手牌，则【水攻】对该角色造成1点伤害。",
	["@shuigongmessage_BasicCard"] = "你可以弃置一张类型为<font color=\"red\"><b>基本牌</b></font>的手牌，令%src受到1点伤害",	
	["@shuigongmessage_TrickCard"] = "你可以弃置一张类型为<font color=\"red\"><b>锦囊牌</b></font>的手牌，令%src受到1点伤害",
	["@shuigongmessage_EquipCard"] = "你可以弃置一张类型为<font color=\"red\"><b>装备牌</b></font>的手牌，令%src受到1点伤害",
}
if Ver == 1 then
	sgs.LoadTranslationTable{
		[":Weikai"] = "基本牌<br /><b>时机：</b>基本牌生效前，或一张【开】生效前<br /><b>目标：</b>该基本牌<br /><b>效果：</b>抵消该基本牌产生的效果，或抵消另一张【开】产生的效果。<br /><b>注意：</b>不同于无懈可击的是，【开】生效后该牌对所有目标均无效。<br /><b>提示：</b>若你的游戏版本低于20170211版本，或在游戏中发现了此牌的Bug，由于游戏不支持打出的牌的无效的效果，请打开游戏根目录的/extensions/goddess,lua文件，将第5行的Ver变量设置为0，以添加对基本牌的限制（<font color=\"red\">使用的</font>）。",
	}
else
	sgs.LoadTranslationTable{
		[":Weikai"] = "基本牌<br /><b>时机：</b><font color=\"red\">使用的</font>基本牌生效前，或一张【开】生效前<br /><b>目标：</b>该基本牌<br /><b>效果：</b>抵消该基本牌产生的效果，或抵消另一张【开】产生的效果。<br /><b>注意：</b>不同于无懈可击的是，【开】生效后该牌对所有目标均无效。<br /><b>提示：</b>若你的游戏版本高于20170211版本，由于系统支持，请打开游戏根目录的/extensions/goddess,lua文件，将第5行的Ver变量设置为1，以取消对基本牌的限制（<font color=\"red\">使用的</font>）。",
	}
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
--SpecialPublicPart-RemoveGeneral
RemoveGeneral_Skill = sgs.CreateTriggerSkill{
	name = "RemoveGeneral_Skill",
	events = {sgs.MarkChanged, sgs.TurnStart},
	global = true,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "@RemoveGeneral" then
				local skills = player:getVisibleSkillList()
				local room = player:getRoom()
				if player:getMark("@RemoveGeneral")>0 then
					for _, skill in sgs.qlist(skills) do
						room:addPlayerMark(player, "Qingcheng"..skill:objectName())
					end
				else
					for _, skill in sgs.qlist(skills) do
						room:removePlayerMark(player, "Qingcheng"..skill:objectName())
					end
				end
			end
		elseif event == sgs.TurnStart then	
			local room = player:getRoom()
			if player:getMark("@RemoveGeneral")>0 then
				room:setPlayerMark(player, "@RemoveGeneral", 0)
				local msg = sgs.LogMessage()
				msg.type = "#RemoveGeneralBack"
				msg.from = player
				room:sendLog(msg)
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	priority = 12
}
local RemoveGeneral_SkillList=sgs.SkillList()
if not sgs.Sanguosha:getSkill("RemoveGeneral_Skill") then 
	RemoveGeneral_SkillList:append(RemoveGeneral_Skill) 
end
sgs.Sanguosha:addSkills(RemoveGeneral_SkillList)
sgs.LoadTranslationTable{
--ForRemoveGeneralEspecially
	["@RemoveGeneral"] = "武将牌移出游戏",
	["#RemoveGeneral"] = "%from  的武将牌被移出游戏",
	["#RemoveGeneralBack"] = "───────────────<br />%from  的武将牌被移回游戏",
}
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
return {extension, extension_card, extension_n}