module("extensions.meizl", package.seeall)
extension = sgs.Package("meizl")
--遊戲包名稱：魅包
--版本號：V2.35.1
--最後更新時間：2/3/2014
do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "sevendevil")
	config.color_de = "#FF77FF"
end
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 001 大乔
meizldaqiao = sgs.General(extension, "meizldaqiao", "wu", 3, false)

--春深（大乔）
meizlchunshencard = sgs.CreateSkillCard {
	name = "meizlchunshencard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		if to_select:objectName() ~= player:objectName() then
			if to_select:getHp() >= player:getHp() then
				return player:distanceTo(to_select) <= player:getAttackRange()
			end
		end
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		local tag = room:getTag("meizlchunshenDamage")
		local damage = tag:toDamage()
		local log = sgs.LogMessage()
		log.type = "#meizlchunshen"
		log.from = effect.from
		log.to:append(target)
		log.arg  = self:objectName()
		log.arg2 = tonumber(damage.damage)
		room:sendLog(log)
		damage.to = target
		damage.transfer = true
		room:damage(damage)
	end
}
meizlchunshenskill = sgs.CreateViewAsSkill {
	name = "meizlchunshen",
	n = 2,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local meizlchunshencard = meizlchunshencard:clone()
			meizlchunshencard:addSubcard(cards[1])
			meizlchunshencard:addSubcard(cards[2])
			return meizlchunshencard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlchunshen"
	end
}
meizlchunshen = sgs.CreateTriggerSkill {
	name = "meizlchunshen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	view_as_skill = meizlchunshenskill,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHandcardNum() >= 2 then
			local damage = data:toDamage()
			local value = sgs.QVariant()
			value:setValue(damage)
			room:setTag("meizlchunshenDamage", value)
			if room:askForUseCard(player, "@@meizlchunshen", "@meizlchunshen-card") then
				return true
			end
		end
	end
}
--矜怜（大乔）
meizljinlian = sgs.CreateTriggerSkill {
	name = "meizljinlian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					if player:askForSkillInvoke(self:objectName(), data) then
						player:drawCards(1)
					end
				end
			end
		end
	end
}

meizldaqiao:addSkill(meizlchunshen)
meizldaqiao:addSkill(meizljinlian)

sgs.LoadTranslationTable {
	["meizl"] = "魅包",
	["meizldaqiao"] = "大乔",
	["designer:meizldaqiao"] = "Mark1469",
	["illustrator:meizldaqiao"] = "三国杀OL",
	["illustrator:meizldaqiao_1"] = "啪啪三国",
	["#meizldaqiao"] = "深锁铜雀台",
	["meizlchunshen"] = "春深",
	["meizlchunshencard"] = "春深",
	["#meizlchunshen"] = "%from发动了技能【%arg】并指定%to成为目标，%to将代替%from承受%arg2点伤害",
	["@meizlchunshen-card"] = "请选择“春深”的目标",
	["~meizlchunshen"] = "选择两张手牌→选择一名其他角色→点击确定",
	[":meizlchunshen"] = "每当你受到伤害时，你可以弃置两张手牌并选择你攻击范围内一名体力值不小于你的其他角色，将此伤害转移给该角色。",
	["meizljinlian"] = "矜怜",
	[":meizljinlian"] = "你的回合外，每当你失去牌后，你可以摸一张牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 002 步练师
meizlbulianshi = sgs.General(extension, "meizlbulianshi", "wu", 3, false)
--宠媛（步练师）
meizlchongyuan = sgs.CreateTriggerSkill {
	name = "meizlchongyuan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if not effect.from or not effect.from:getGeneral():isMale() then return end
		if effect.card:isNDTrick() then
			local log = sgs.LogMessage()
			log.type = "#Meizlchongyuan"
			log.from = effect.to
			log.to:append(effect.from)
			log.arg  = effect.card:objectName()
			log.arg2 = self:objectName()
			room:sendLog(log)
			return true
		end
	end
}

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
--淑懿（步练师）
meizlshuyi = sgs.CreateTriggerSkill {
	name = "meizlshuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:getPhase() == sgs.Player_Discard then return false end
		if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile) then
			local card_ids = sgs.IntList()
			local ids = sgs.QList2Table(move.card_ids)
			for i = 1, #ids, 1 do
				local card_id = ids[i]
				if ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip)) then
					card_ids:append(card_id)
				end
			end

			if card_ids:length() > player:getHandcardNum() then
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				--[[for _, id in sgs.qlist(card_ids) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break
						end]]
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(card_ids)
				for _, id in sgs.qlist(card_ids) do
					if move.card_ids:contains(id) then
						move.from_places:removeAt(listIndexOf(move.card_ids, id))
						move.card_ids:removeOne(id)
						data:setValue(move)
					end
					if not player:isAlive() then break end
				end
				room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
				dummy:deleteLater()
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,

}

meizlbulianshi:addSkill(meizlchongyuan)
meizlbulianshi:addSkill(meizlshuyi)

sgs.LoadTranslationTable {
	["meizlbulianshi"] = "步练师",
	["designer:meizlbulianshi"] = "Mark1469",
	["#meizlbulianshi"] = "宠冠后庭",
	["illustrator:meizlbulianshi"] = "小刺",
	["illustrator:meizlbulianshi_1"] = "大戦乱!!三国志バトル",
	["meizlshuyi"] = "淑懿",
	[":meizlshuyi"] = "<font color=\"blue\"><b>锁定技，</b></font>弃牌阶段外，当其他角色的牌置入弃牌堆时，若牌的数量大于你的手牌数，你获得之。",
	["meizlchongyuan"] = "宠媛",
	[":meizlchongyuan"] = "<font color=\"blue\"><b>锁定技，</b></font>男性角色使用的非延时类锦囊牌对你无效。",
	["#Meizlchongyuan"] = "%from触发【%arg2】，%to使用的锦囊【%arg】对%from无效",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 003 王异
meizlwangyi = sgs.General(extension, "meizlwangyi", "wei", 3, false)
--奇计（王异）
meizlqiji = sgs.CreateTriggerSkill
	{
		name = "meizlqiji",
		events = { sgs.Damaged },
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from and damage.card and damage.card:isKindOf("Slash") and player:canDiscard(player, "he") then
				-- room:setTag("CurrentDamageStruct", data)
				if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@meizlqiji") then
					room:notifySkillInvoked(player, self:objectName())
					room:loseHp(damage.from, 1)
				end
				-- room:removeTag("CurrentDamageStruct")
			end
		end
	}
--忍辱（王异）
meizlrenru = sgs.CreateTriggerSkill
	{
		name = "meizlrenru",
		events = { sgs.EventPhaseStart, sgs.DamageInflicted, sgs.TurnedOver },
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				player:turnOver()
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			elseif event == sgs.DamageInflicted then
				local damage = data:toDamage()
				if not player:faceUp() then
					local log = sgs.LogMessage()
					log.type  = "#Meizlrenru"
					log.from  = player
					log.arg   = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
					return true
				end
			elseif event == sgs.TurnedOver then
				if player:faceUp() then
					room:setPlayerMark(player, "&meizlrenru", 0)
				else
					room:setPlayerMark(player, "&meizlrenru", 1)
				end
			end
		end
	}

meizlwangyi:addSkill(meizlqiji)
meizlwangyi:addSkill(meizlrenru)

sgs.LoadTranslationTable {
	["meizlwangyi"] = "王异",
	["designer:meizlwangyi"] = "Mark1469",
	["#meizlwangyi"] = "复仇的烈女",
	["illustrator:meizlwangyi"] = "小刺",
	["illustrator:meizlwangyi_1"] = "霸三国OL",
	["meizlqiji"] = "奇计",
	[":meizlqiji"] = "每当你受到【杀​​】造成的一次伤害后，你可以弃置一张牌，然后伤害来源失去1点体力。",
	["@meizlqiji"] = "你可以弃置一张牌，然后伤害来源失去1点体力。",
	["meizlrenru"] = "忍辱",
	[":meizlrenru"] = "结束阶段开始时，你可以将武将牌翻面，然后回复1点体力；若你的武将牌背面朝上，你防止你受到的伤害。",
	["#Meizlrenru"] = "%from 触发【%arg】， 防止了%arg2点伤害",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 004　张春华
meizlzhangchunhua = sgs.General(extension, "meizlzhangchunhua", "wei", 3, false)
--无情（张春华）
meizlwuqing = sgs.CreateTriggerSkill {
	name = "meizlwuqing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Predamage },
	on_trigger = function(self, event, player, data)
		local log = sgs.LogMessage()
		local damage = data:toDamage()
		local room = player:getRoom()
		if player:isWounded() and damage.nature == sgs.DamageStruct_Normal then
			log.from = player
			log.type = "#Meizlwuqingnormal"
			log.arg = self:objectName()
			log.to:append(damage.to)
			room:sendLog(log)
			room:loseHp(damage.to, damage.damage)
			return true
		elseif player:getHp() == 1 and damage.nature ~= sgs.DamageStruct_Normal then
			log.from = player
			log.type = "#Meizlwuqingfire"
			log.arg = self:objectName()
			log.to:append(damage.to)
			room:sendLog(log)
			room:loseMaxHp(damage.to, damage.damage)
			return true
		end
	end,
}
--闺怨（张春华）
meizlguiyuan = sgs.CreateTriggerSkill {
	name = "meizlguiyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if player:isAlive() then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive then
					if event == sgs.Damaged then
						if not current:isNude() then
							if player:askForSkillInvoke(self:objectName(), data) then
								local card_id = room:askForCardChosen(player, current, "he", self:objectName())
								room:throwCard(card_id, current, player)
							end
						end
					elseif event == sgs.CardsMoveOneTime then
						local move = data:toMoveOneTime()
						local source = move.from
						if source and source:objectName() == player:objectName() then
							local places = move.from_places
							if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
								if not current:isNude() then
									if player:askForSkillInvoke(self:objectName(), data) then
										local card_id = room:askForCardChosen(player, current, "he", self:objectName())
										room:throwCard(card_id, current, player)
									end
								end
							end
						end
					end
				end
			end
		end
	end

}

meizlzhangchunhua:addSkill(meizlwuqing)
meizlzhangchunhua:addSkill(meizlguiyuan)

sgs.LoadTranslationTable {
	["meizlzhangchunhua"] = "张春华",
	["designer:meizlzhangchunhua"] = "Mark1469",
	["#meizlzhangchunhua"] = "冷艳的皇后",
	["illustrator:meizlzhangchunhua"] = "小刺",
	["meizlwuqing"] = "无情",
	["#Meizlwuqingnormal"] = "【%arg】被触发，%from对%to即将造成的非属性伤害视为失去体力。",
	["#Meizlwuqingfire"] = "【%arg】被触发，%from对%to即将造成的属性伤害视为失去体力上限。",
	[":meizlwuqing"] = "<font color=\"blue\"><b>锁定技，</b></font>若你已受伤，你即将造成的非属性伤害均视为失去体力；若你的体力值为1，你即将造成的属性伤害均视为失去体力上限。",
	["meizlguiyuan"] = "闺怨",
	[":meizlguiyuan"] = "你的回合外，每当你受到一次伤害后或失去牌时，你可以弃置当前回合角色的一张牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 005 祝融
meizlzhurong = sgs.General(extension, "meizlzhurong", "shu", 3, false)
--驭象（祝融）
meizlyuxiang = sgs.CreateTriggerSkill {
	name = "meizlyuxiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					splayer:drawCards(2)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
meizlyuxiangavoid = sgs.CreateTriggerSkill {
	name = "#meizlyuxiangavoid",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.from = player
			log.arg = "meizlyuxiang"
			log.arg2 = "savage_assault"
			room:sendLog(log)
			return true
		end
	end
}
--飞刃（祝融）
meizlfeiren = sgs.CreateTriggerSkill {
	name = "meizlfeiren",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local dest = effect.to
		if dest:isAlive() and effect.card and effect.card:isKindOf("Slash") then
			if not dest:isKongcheng() then
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local card = room:askForCardChosen(player, dest, "h", self:objectName())
					local cd = sgs.Sanguosha:getCard(card)
					player:addToPile("meizlfeiren", cd, true)
					if player:getPile("meizlfeiren"):length() == 3 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:deleteLater()
						for _, id in sgs.qlist(player:getPile("meizlfeiren")) do
							local cdq = sgs.Sanguosha:getCard(id)
							dummy:addSubcard(cdq)
						end
						room:obtainCard(player, dummy)
						local damage = sgs.DamageStruct()
						damage.damage = 1
						damage.from = player
						damage.to = effect.to
						room:damage(damage)
					end
				end
			end
		end
		return false
	end,
	priority = 2
}

meizlzhurong:addSkill(meizlyuxiangavoid)
meizlzhurong:addSkill(meizlyuxiang)
meizlzhurong:addSkill(meizlfeiren)
extension:insertRelatedSkills("meizlyuxiang", "#meizlyuxiangavoid")

sgs.LoadTranslationTable {
	["meizlzhurong"] = "祝融",
	["designer:meizlzhurong"] = "Mark1469",
	["#meizlzhurong"] = "刺美人",
	["illustrator:meizlzhurong"] = "Generals Order",
	["illustrator:meizlzhurong_1"] = "三国輪舞曲",
	["meizlyuxiang"] = "驭象",
	[":meizlyuxiang"] = "<font color=\"blue\"><b>锁定技，</b></font>【南蛮入侵】对你无效；当一名角色使用【南蛮入侵】选择目标后，你摸两张牌。",
	["meizlfeiren"] = "飞刃",
	[":meizlfeiren"] = "当你使用的【杀】被目标角色的【闪】抵消时，你可以将其一张手牌置于你的武将牌上。若此时你武将牌上的牌达到三张，你获得之并对该角色造成1点伤害。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 006 糜夫人
meizlmifuren = sgs.General(extension, "meizlmifuren", "shu", 3, false)
--扶君（糜夫人）
meizlfujuncount = sgs.CreateTriggerSkill {
	name = "#meizlfujuncount",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data, room)
		local recover = data:toRecover()
		player:addMark("meizlfujun")
		room:setPlayerMark(player, "&meizlfujun-Clear", 1)
	end

}
meizlfujun = sgs.CreateTriggerSkill {
	name = "meizlfujun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source:getMark("meizlfujun") > 0 then
				source:setMark("meizlfujun", 0)
				local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(),
					"meizlfujun-invoke", true, true)
				if not target then return false end
				local p = sgs.QVariant()
				p:setValue(target)
				room:setTag("MeizlfujunInvoke", p)
				break
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end,
	priority = -1
}
meizlfujundo = sgs.CreateTriggerSkill {
	name = "#meizlfujundo",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("MeizlfujunInvoke")
		if tag then
			local target = tag:toPlayer()
			room:removeTag("MeizlfujunInvoke")
			if target then
				if target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end,
	priority = -3
}
--让马（糜夫人）
meizlrangma = sgs.CreateTriggerSkill {
	name = "meizlrangma",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local idlistA = sgs.IntList()
		local idlistB = sgs.IntList()
		local targets = room:getAlivePlayers()
		if not death.who:hasSkill(self:objectName()) then return end
		targets:removeOne(death.who)
		if death.damage and death.damage.from then
			targets:removeOne(death.damage.from)
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(death.who, targets, self:objectName(), "meizlrangma-invoke", true,
				true)
			if not target then return false end
			if not death.who:isNude() then
				for _, equip in sgs.qlist(death.who:getEquips()) do
					idlistA:append(equip:getId())
				end
				for _, card in sgs.qlist(death.who:getHandcards()) do
					idlistA:append(card:getId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = idlistA
				move.to = target
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, false)
			end
			if death.damage and death.damage.from and not death.damage.from:isNude() then
				for _, equip in sgs.qlist(death.damage.from:getEquips()) do
					idlistB:append(equip:getId())
				end
				for _, card in sgs.qlist(death.damage.from:getHandcards()) do
					idlistB:append(card:getId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = idlistB
				move.to = target
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, false)
			end
		end
	end
}
--托孤（糜夫人）
meizltuogucard = sgs.CreateSkillCard {
	name = "meizltuogucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizltuogu")
		room:setPlayerFlag(source, "meizltuogu")
		room:addPlayerMark(source, "&meizltuogu-Clear")
		for _, p in sgs.qlist(room:getAllPlayers(false)) do
			if p:getKingdom() ~= "shu" then
				room:loseHp(p, 1)
			end
		end

		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getKingdom() == "shu" then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return end
		local target = room:askForPlayerChosen(source, targets, "meizltuogu", "meizltuogu-invoke", true, true)
		if not target then return false end
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(target, recover)
	end,
}
meizltuoguskill = sgs.CreateViewAsSkill {
	name = "meizltuogu",
	n = 0,
	view_as = function(self, cards)
		return meizltuogucard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizltuogu")
		return count > 0
	end
}
meizltuogu = sgs.CreateTriggerSkill {
	name = "meizltuogu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizltuoguskill,
	events = { sgs.EventPhaseChanging },
	limit_mark = "@meizltuogu",
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive and player:getMark("@meizltuogu") == 0 and player:hasFlag("meizltuogu") then
			local room = player:getRoom()
			room:killPlayer(player)
		end
	end
}

meizlmifuren:addSkill(meizlfujun)
meizlmifuren:addSkill(meizlfujuncount)
meizlmifuren:addSkill(meizlfujundo)
meizlmifuren:addSkill(meizltuogu)
meizlmifuren:addSkill(meizlrangma)
extension:insertRelatedSkills("meizlfujun", "#meizlfujuncount")
extension:insertRelatedSkills("meizlfujun", "#meizlfujundo")

sgs.LoadTranslationTable {
	["meizlmifuren"] = "糜夫人",
	["designer:meizlmifuren"] = "Mark1469",
	["#meizlmifuren"] = "舍身存嗣",
	["illustrator:meizlmifuren"] = "木美人",
	["illustrator:meizlmifuren_1"] = "霸三国OL",
	["meizlfujun"] = "扶君",
	[":meizlfujun"] = "若你在一回合内回复了至少1点体力，此回合结束后，你可以令一名其他角色进行一个额外的回合。",
	["meizlfujun-invoke"] = "你可以发动“扶君”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizltuogu"] = "托孤",
	["meizltuogu-invoke"] = "你可以发动“托孤”回复1点体力<br/> <b>操作提示</b>: 选择一名蜀势力角色→点击确定<br/>",
	["@meizltuogu"] = "托孤",
	["meizltuogucard"] = "托孤",
	[":meizltuogu"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令所有非蜀势力角色失去1点体力，并可以令一名蜀势力角色回复1点体力，若如此做，你在回合结束时阵亡。",
	["meizlrangma"] = "让马",
	[":meizlrangma"] = "你死亡时，你可以令一名其他角色（杀死你的角色除外）获得你和杀死你的角色所有牌。",
	["meizlrangma-invoke"] = "你可以发动“让马”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 007 貂蝉
meizldiaochan = sgs.General(extension, "meizldiaochan", "qun", 3, false)
--离魄（貂蝉）
meizllipo = sgs.CreateViewAsSkill
	{
		name = "meizllipo",
		n = 0,

		view_as = function(self, cards)
			return meizllipocard:clone()
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#meizllipocard")
		end,
	}

meizllipocard = sgs.CreateSkillCard
	{
		name = "meizllipocard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select)
			if (not to_select:getGeneral():isMale()) or #targets > 0 or to_select:isKongcheng() then return false end
			return true
		end,

		on_use = function(self, room, source, targets)
			if (#targets ~= 1) then return end
			local x = targets[1]:getHandcardNum()
			source:obtainCard(targets[1]:wholeHandCards(), false)
			local to_goback
			local prompt = string.format("@meizllipomove:%s", x)
			to_goback = room:askForExchange(source, self:objectName(), x, x, true, prompt)
			room:obtainCard(targets[1], to_goback, false)
		end
	}

meizldiaochan:addSkill(meizllipo)
meizldiaochan:addSkill("biyue")

sgs.LoadTranslationTable {
	["meizldiaochan"] = "貂蝉",
	["#meizldiaochan"] = "闭月的傀儡师",
	["designer:meizldiaochan"] = "Mark1469",
	["illustrator:meizldiaochan"] = "三国轮舞曲",
	["illustrator:meizldiaochan_1"] = "啪啪三国",
	["meizllipo"] = "离魄",
	["@meizllipomove"] = "离魄\
请返還%src张牌",
	["meizllipocard"] = "离魄",
	[":meizllipo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名男性角色的所有手牌，然后返还等量的牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 008 蔡夫人
meizlcaifuren = sgs.General(extension, "meizlcaifuren", "qun", 3, false)
--毒言（蔡夫人）
meizlduyan = sgs.CreateTriggerSkill {
	name = "meizlduyan",
	events = { sgs.EventPhaseStart },

	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:getPhase() == sgs.Player_NotActive then
				if splayer:getMark("@meizlduyan") > 0 then
					splayer:loseMark("@meizlduyan")
					room:removePlayerCardLimitation(splayer, "use,response", ".|.|.|hand|.|")
				end
				return
			end
			if player:getPhase() ~= sgs.Player_RoundStart then return end

			if player:objectName() == splayer:objectName() or splayer:isKongcheng() or player:isKongcheng() or not splayer:canPindian(player) then return end
			if not splayer:askForSkillInvoke(self:objectName()) then return end
			local win = splayer:pindian(player, self:objectName(), nil)
			if win then
				player:skip(sgs.Player_Play)
			else
				local pattern = ".|.|.|hand|.|"
				room:setPlayerCardLimitation(splayer, "use,response", pattern, false)
				splayer:gainMark("@meizlduyan")
				room:addPlayerMark(splayer, "&meizlduyan-Clear")
			end
		end
	end,
}
--蛇心（蔡夫人）
meizlshexinmaxcard = sgs.CreateMaxCardsSkill {
	name = "meizlshexinmaxcard&",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill(self:objectName()) then
			for _, p in sgs.qlist(target:getSiblings()) do
				if p:hasSkill("meizlshexin") and target:getHp() > p:getHp() then
					x = p:getLostHp()
				end
			end
			return -x
		end
	end
}

meizlshexin = sgs.CreateTriggerSkill {
	name = "meizlshexin",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:attachSkillToPlayer(p, "meizlshexinmaxcard")
		end
	end

}

meizlshexinclear = sgs.CreateTriggerSkill {
	name = "#meizlshexinclear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill, sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlshexin" then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:detachSkillFromPlayer(p, "meizlshexinmaxcard")
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlshexinmaxcard") then skills:append(meizlshexinmaxcard) end
sgs.Sanguosha:addSkills(skills)
meizlcaifuren:addSkill(meizlduyan)
meizlcaifuren:addSkill(meizlshexin)
meizlcaifuren:addSkill(meizlshexinclear)
extension:insertRelatedSkills("meizlshexin", "#meizlshexinclear")

sgs.LoadTranslationTable {
	["meizlcaifuren"] = "蔡夫人",
	["#meizlcaifuren"] = "蛇蝎美人",
	["designer:meizlcaifuren"] = "Mark1469",
	["illustrator:meizlcaifuren"] = "夏季",
	["illustrator:meizlcaifuren_1"] = "大戦乱!!三国志バトル",
	["meizlduyan"] = "毒言",
	["@meizlduyan"] = "毒言",
	[":meizlduyan"] = "其他角色的回合开始时，你可以与该角色拼点。若你赢，该角色跳过出牌阶段；若你没赢，你不能使用或打出手牌直至回合结束。",
	["meizlshexin"] = "蛇心",
	[":meizlshexin"] = "<font color=\"blue\"><b>锁定技，</b></font>体力值大于你的角色的手牌上限-X（X为你已损失的体力值）。",
	["meizlshexinmaxcard"] = "蛇心",
	[":meizlshexinmaxcard"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的体力值大于蔡夫人，你的手牌上限-X（X为蔡夫人已损失的体力值）。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 009 吴国太
meizlwuguotai = sgs.General(extension, "meizlwuguotai", "wu", 3, false)
--招婿（吴国太）
meizlzhaoxucard = sgs.CreateSkillCard {
	name = "meizlzhaoxucard",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select)
		return #targets == 0
	end,

	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:showAllCards(effect.from, nil)
		local x = effect.from:getHandcardNum()
		local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, p in sgs.qlist(effect.from:getHandcards()) do
			if p:isRed() then
				dummy_card:addSubcard(p)
			end
		end
		room:obtainCard(effect.to, dummy_card)
		dummy_card:deleteLater()
		local y = effect.from:getHandcardNum()
		effect.from:drawCards(x - y)
		return false
	end,
}

meizlzhaoxu = sgs.CreateViewAsSkill {
	name = "meizlzhaoxu",
	n = 0,
	view_as = function()
		return meizlzhaoxucard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlzhaoxucard")
	end,
}
--助治（吴国太）
meizlzhuzhi = sgs.CreateTriggerSkill {
	name = "meizlzhuzhi",
	events = { sgs.Death },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName()) and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local x = death.who:getMaxHp()
		room:setPlayerMark(player, "meizlzhuzhi", x)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "meizlzhuzhi", "meizlzhuzhi-invoke",
			true, true)
		room:setPlayerMark(player, "meizlzhuzhi", 0)
		if not target then return false end
		local choice = room:askForChoice(player, "meizlzhuzhi", "d1tx+dxt1")

		if choice == "d1tx" then
			target:drawCards(1)
			if target:getHandcardNum() + target:getEquips():length() > x then
				room:askForDiscard(target, self:objectName(), x, x, false, true)
			else
				target:throwAllCards()
			end
		else
			target:drawCards(x)
			if target:getHandcardNum() + target:getEquips():length() > 1 then
				room:askForDiscard(target, self:objectName(), 1, 1, false, true)
			else
				target:throwAllCards()
			end
		end
	end
}

meizlwuguotai:addSkill(meizlzhaoxu)
meizlwuguotai:addSkill(meizlzhuzhi)
sgs.LoadTranslationTable {
	["meizlwuguotai"] = "吴国太",
	["#meizlwuguotai"] = "雍容华贵",
	["designer:meizlwuguotai"] = "Mark1469",
	["illustrator:meizlwuguotai"] = "小刺",
	["illustrator:meizlwuguotai_1"] = "三国杀OL",
	["meizlzhaoxu"] = "招婿",
	["meizlzhaoxucard"] = "招婿",
	[":meizlzhaoxu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名其他角色并展示所有手牌，该角色获得当中的红色牌，每以此法失去一张牌，你摸一张牌。",
	["meizlzhuzhi"] = "助治",
	["meizlzhuzhi-invoke"] = "你可以发动“助治”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlzhuzhi:d1tx"] = "摸一张牌，然后弃置X张牌",
	["meizlzhuzhi:dxt1"] = "摸X张牌，然后弃置一张牌",
	[":meizlzhuzhi"] = "一名角色死亡时，你可以选择一项：令一名其他角色摸X张牌，然后弃置一张牌；或令一名其他角色摸一张牌，然后弃置X张牌（X为死亡角色的体力上限）。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 010 卞夫人
meizlbainfuren = sgs.General(extension, "meizlbainfuren", "wei", 3, false)
--素贤（卞夫人）
meizlsuxianskill = sgs.CreateViewAsSkill {
	name = "meizlsuxian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if sgs.Self:getMark("meizlsuxian") > 0 then
			if #cards == 1 then
				local card_id = sgs.Self:getMark("meizlsuxiancard")
				local card = sgs.Sanguosha:getCard(card_id)
				local first = cards[1]
				local name = card:objectName()
				local suit = first:getSuit()
				local point = first:getNumber()
				local new_card = sgs.Sanguosha:cloneCard(name, suit, point)
				new_card:addSubcard(first)
				new_card:setSkillName(self:objectName())
				return new_card
			end
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("meizlsuxian") > 0 then
			local card_id = player:getMark("meizlsuxiancard")
			local card = sgs.Sanguosha:getCard(card_id)
			return card:isAvailable(player)
		end
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getMark("meizlsuxian") > 0 then
			local card_id = player:getMark("meizlsuxiancard")
			local card = sgs.Sanguosha:getCard(card_id)
			return string.find(pattern, card:objectName())
		end
	end,
	enabled_at_nullification = function(self, player)
		if player:getMark("meizlsuxian") > 0 then
			local card_id = player:getMark("meizlsuxiancard")
			local card = sgs.Sanguosha:getCard(card_id)
			if card:objectName() == "nullification" then
				local cards = player:getHandcards()
				for _, c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:isRed() then
						return true
					end
				end
				cards = player:getEquips()
				for _, c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:isRed() then
						return true
					end
				end
			end
		end
		return false
	end
}

meizlsuxian = sgs.CreateTriggerSkill {
	name = "meizlsuxian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.EventPhaseStart },
	view_as_skill = meizlsuxianskill,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.from:isKongcheng() then
				if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
				local card = room:askForCardChosen(player, damage.from, "h", self:objectName())
				room:obtainCard(player, card)
				room:showCard(player, card)
				local cd = sgs.Sanguosha:getCard(card)
				if (cd:isNDTrick() or cd:isKindOf("BasicCard")) and player:getPile("meizlsuxian"):length() == 0 then
					room:setPlayerMark(player, "&meizlsuxian+" .. cd:objectName(), 1)
					room:setPlayerMark(player, "meizlsuxiancard", card)
					room:setPlayerMark(player, "meizlsuxian", 1)
					player:addToPile("meizlsuxian", cd, true)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			player:setMark("meizlsuxian", 0)
			for _, p in sgs.qlist(player:getPile("meizlsuxian")) do
				room:obtainCard(player, sgs.Sanguosha:getCard(p))
				room:setPlayerMark(player, "meizlsuxian", 0)
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "meizlsuxian") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end
				end
			end
		end
	end
}
--慈悯（卞夫人）
meizlcimin = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "meizlcimin",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:objectName() == splayer:objectName() then continue end
				if splayer:isKongcheng() or not player:isAlive() then continue end
				local qq = sgs.QVariant()
				qq:setValue(player)
				-- room:setTag("CurrentDamageStruct", data)
				if not room:askForSkillInvoke(splayer, self:objectName(), qq) then
					-- room:removeTag("CurrentDamageStruct")
					continue
				end
				-- room:removeTag("CurrentDamageStruct")
				player:obtainCard(splayer:wholeHandCards(), false)
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = splayer
				room:recover(player, recover)
			end
		end,
		can_trigger = function(self, player)
			return true
		end
	}

meizlbainfuren:addSkill(meizlsuxian)
meizlbainfuren:addSkill(meizlcimin)

sgs.LoadTranslationTable {
	["meizlbainfuren"] = "卞夫人",
	["#meizlbainfuren"] = "武宣皇后",
	["designer:meizlbainfuren"] = "Mark1469",
	["illustrator:meizlbainfuren"] = "群龍三國伝",
	["illustrator:meizlbainfuren_1"] = "大戦乱!!三国志バトル",
	["meizlsuxian"] = "素贤",
	[":meizlsuxian"] = "每当你受到一次伤害后，你可以获得并展示伤害来源的一张手牌，若为基本牌或非延时类锦囊牌且你的武将牌上没有牌，你将之置于武将牌上。你可以将一张红色牌当武将牌上的牌使用或打出。结束阶段开始时，你获得武将牌上的牌。",
	["meizlcimin"] = "慈悯",
	[":meizlcimin"] = "每当其他角色受到一次伤害后，你可以将所有手牌（至少一张）交给该角色，然后令该角色回复1点体力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 011 蔡文姬
meizlcaiwenji = sgs.General(extension, "meizlcaiwenji", "qun", 3, false)
--胡笳（蔡文姬）
meizlhujiacard = sgs.CreateSkillCard {
	name = "meizlhujiacard",
	will_throw = false,

	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:canPindian(to_select) and to_select:objectName() ~= sgs.Self:objectName()
	end,

	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "meizlhujia", nil)
		if success then
			source:gainMark("@meizlhujia")
			room:addPlayerMark(source, "&meizlhujia")
		else
			if not source:isKongcheng() then
				room:askForDiscard(source, self:objectName(), 1, 1)
			end
		end
	end
}

meizlhujia = sgs.CreateViewAsSkill {
	name = "meizlhujia",
	n = 0,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = meizlhujiacard:clone()
			--card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlhujiacard")
	end,
}

meizlhujiamaxcard = sgs.CreateMaxCardsSkill {
	name = "#meizlhujiamaxcard",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getMark("@meizlhujia")
		end
	end
}
--归汉（蔡文姬）
meizlguihancard = sgs.CreateSkillCard {
	name = "meizlguihancard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlguihan")
		local x = room:alivePlayerCount()
		source:drawCards(x)
		if x < 5 then
			local recover = sgs.RecoverStruct()
			recover.recover = source:getMaxHp() - source:getHp()
			recover.who = source
			room:recover(source, recover)
		end
		room:setPlayerProperty(source, "kingdom", sgs.QVariant("wei"))
	end,
}
meizlguihanskill = sgs.CreateViewAsSkill {
	name = "meizlguihan",
	n = 0,
	view_as = function(self, cards)
		return meizlguihancard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlguihan") > 0
	end
}
meizlguihan = sgs.CreateTriggerSkill {
	name = "meizlguihan",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlguihanskill,
	limit_mark = "@meizlguihan",
	events = {},
	on_trigger = function(self, event, player, data)
	end
}
--魂逝（蔡文姬）
meizlhunshi = sgs.CreateTriggerSkill {
	name = "meizlhunshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		--local damage = data:toDamage()
		local room = death.who:getRoom()
		local targets
		if not death.who:hasSkill(self:objectName()) then return end
		if not player:objectName() == death.who:objectName() then return end
		if death.damage and death.damage.from then
			room:loseHp(death.damage.from, 1)
			room:handleAcquireDetachSkills(death.damage.from, "meizlhunshidistance")
			room:addPlayerMark(death.damage.from, "&meizlhunshi+to+#" .. player:objectName())
		end
	end
}

meizlhunshidistance = sgs.CreateDistanceSkill {
	name = "meizlhunshidistance",
	correct_func = function(self, from, to)
		if to:hasSkill("meizlhunshidistance") then
			return -1
		end
	end,
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlhunshidistance") then skills:append(meizlhunshidistance) end
sgs.Sanguosha:addSkills(skills)
meizlcaiwenji:addSkill(meizlhujia)
meizlcaiwenji:addSkill(meizlhujiamaxcard)
meizlcaiwenji:addSkill(meizlguihan)
meizlcaiwenji:addSkill(meizlhunshi)
extension:insertRelatedSkills("meizlhujia", "#meizlhujiamaxcard")
sgs.LoadTranslationTable {
	["meizlcaiwenji"] = "蔡文姬",
	["#meizlcaiwenji"] = "悲愤的才女",
	["designer:meizlcaiwenji"] = "Mark1469",
	["illustrator:meizlcaiwenji"] = "霸王兔",
	["meizlhujia"] = "胡笳",
	["@meizlhujia"] = "胡笳",
	["meizlhujiacard"] = "胡笳",
	[":meizlhujia"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点。若你赢，你的手牌上限+1。若你没赢，你弃置一张手牌。",
	["meizlguihan"] = "归汉",
	["meizlguihancard"] = "归汉",
	["@meizlguihan"] = "归汉",
	[":meizlguihan"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以摸X张牌并将势力变为“魏”（X为存活角色数）。若以此法摸的牌张数不多于五张，你将体力回复至体力上限。",
	["meizlhunshi"] = "魂逝",
	[":meizlhunshi"] = "<font color=\"blue\"><b>锁定技，</b></font>你死亡时，杀死你的角色失去1点体力且其他角色与其距离-1。",
	["meizlhunshidistance"] = "魂逝",
	[":meizlhunshidistance"] = "<font color=\"blue\"><b>锁定技，</b></font>其他角色与你的距离-1",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 012 黄月英
meizlhuangyueying = sgs.General(extension, "meizlhuangyueying", "shu", 3, false)
--流马（黄月英）
meizlliuma = sgs.CreateTriggerSkill {
	name = "meizlliuma",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardResponsed },
	on_trigger = function(self, event, player, data)
		local card = nil
		if event == sgs.CardUsed then
			use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponsed then
			local response = data:toCardResponse()
			card = response.m_card
		end
		local room = player:getRoom()
		if card:isNDTrick() then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "meizlliuma",
				"meizlliuma-invoke", true, true)
			if not target then return false end
			target:throwAllHandCards()
			target:drawCards(target:getHp() - target:getHandcardNum())
		end
	end
}
--智囊（黄月英）
meizlzhinangcard = sgs.CreateSkillCard
	{
		name = "meizlzhinangcard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select)
			if #targets == 0 then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end,

		on_use = function(self, room, source, targets)
			local x = self:subcardsLength()
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.good = true
			judge.reason = "meizlzhinang"
			judge.who = source
			room:judge(judge)
			if judge:isGood() then
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = targets[1]
				damage.damage = x
				damage.reason = self:objectName()
				room:damage(damage)
			else
				--[[while x > 0 do
if not source:isNude() then
local card_id = room:askForCardChosen(targets[1], source, "he", self:objectName())
room:throwCard(card_id, source, targets[1])
end
x = x-1
end]]
				room:setPlayerFlag(targets[1], "LuaXDuanzhi_InTempMoving");
				local dummy = sgs.Sanguosha:cloneCard("slash") --没办法了，暂时用你代替DummyCard吧……
				local card_ids = sgs.IntList()
				local original_places = sgs.PlaceList()
				for i = 1, x, 1 do
					if not targets[1]:canDiscard(source, "he") then break end
					card_ids:append(room:askForCardChosen(targets[1], source, "he", self:objectName()))
					original_places:append(room:getCardPlace(card_ids:at(i - 1)))
					dummy:addSubcard(card_ids:at(i - 1))
					source:addToPile("#meizlzhinang", card_ids:at(i - 1), false)
				end
				if dummy:subcardsLength() > 0 then
					for i = 1, dummy:subcardsLength(), 1 do
						room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), source, original_places:at(i - 1),
							false)
					end
				end
				room:setPlayerFlag(targets[1], "-LuaXDuanzhi_InTempMoving")
				if dummy:subcardsLength() > 0 then
					room:throwCard(dummy, source, targets[1])
				end
				dummy:deleteLater()
			end
		end,
	}


meizlzhinang = sgs.CreateViewAsSkill
	{
		name = "meizlzhinang",
		n = 999,

		view_filter = function(self, selected, to_select)
			return to_select:isKindOf("BasicCard")
		end,

		view_as = function(self, cards)
			if #cards > 0 then
				local new_card = meizlzhinangcard:clone()
				local i = 0
				while (i < #cards) do
					i = i + 1
					local card = cards[i]
					new_card:addSubcard(card:getId())
				end
				new_card:setSkillName("meizlzhinang")
				return new_card
			else
				return nil
			end
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#meizlzhinangcard")
		end
	}
meizlzhinang_InTempMoving = sgs.CreateTriggerSkill {
	name = "#meizlzhinang_InTempMoving",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("LuaXDuanzhi_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}




meizlhuangyueying:addSkill(meizlliuma)
meizlhuangyueying:addSkill(meizlzhinang)
meizlhuangyueying:addSkill(meizlzhinang_InTempMoving)
extension:insertRelatedSkills("meizlzhinang", "#meizlzhinang_InTempMoving")

sgs.LoadTranslationTable {
	["meizlhuangyueying"] = "黄月英",
	["#meizlhuangyueying"] = "隐世之才",
	["designer:meizlhuangyueying"] = "Mark1469",
	["illustrator:meizlhuangyueying"] = "木美人",
	["illustrator:meizlhuangyueying_1"] = "霸三国OL",
	["meizlliuma"] = "流马",
	[":meizlliuma"] = "当你使用非延时锦囊牌选择目标后，你可以弃置一名其他角色的所有手牌，然后该角色将手牌补至其当前体力值的张数。",
	["meizlliuma-invoke"] = "你可以发动“流马”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlzhinang"] = "智囊",
	["meizlzhinangcard"] = "智囊",
	[":meizlzhinang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置任意数量的基本牌（至少一张），并选择一名其他角色，然后进行一次判定，若判定结果为黑色，该角色受到你造成的等量伤害；若判定结果为红色，该角色弃置你等量的牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 013 马云禄
meizlmayunlu = sgs.General(extension, "meizlmayunlu", "shu", 3, false)
--域帼（马云禄）
meizlyuguo = sgs.CreateTriggerSkill {
	name = "meizlyuguo",
	events = sgs.CardOffset, sgs.EventPhaseEnd,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			if player:getPhase() == sgs.Player_Play then
				local effect = data:toCardEffect()
				if effect.card and effect.card:isKindOf("Slash")  then
					if not room:askForSkillInvoke(player, self:objectName()) then return false end
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|red"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local card = effect.card
						if not card then return end
						local ids = sgs.IntList()
						if card:isVirtualCard() then
							ids = card:getSubcards()
						else
							ids:append(card:getEffectiveId())
						end
						if ids:isEmpty() then return end
						for _, id in sgs.qlist(ids) do
							if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
						end
						player:obtainCard(card)
						room:addSlashCishu(player, 1, true)
						room:addPlayerMark(player, "&meizlyuguo-Clear")
					end
				end
			end
		end
	end
}

--戎装（马云禄）

meizlrongzhuangVS = sgs.CreateOneCardViewAsSkill {
	name = "meizlrongzhuang",
	view_filter = function(self, card)
		return sgs.Self:getMark(self:objectName().."Card" .. card:getId() .. "-Clear") == 2
	end,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:getCard(sgs.Self:getMark("meizlrongzhuang_cd"))
		return acard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@meizlrongzhuang")
	end,

}
meizlrongzhuang = sgs.CreateTriggerSkill {
	name = "meizlrongzhuang",
	view_as_skill = meizlrongzhuangVS,
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damage, sgs.CardFinished },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isRed() and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if not room:askForSkillInvoke(p, self:objectName()) then return false end
					local card = sgs.Sanguosha:getCard(room:drawCard())
					p:obtainCard(card)
					room:showCard(p, card:getId())
					if card:isKindOf("Slash") then
						if card:isAvailable(p) then
							local can_use = card:targetFixed()
							for _, q in sgs.qlist(room:getAlivePlayers()) do
								if card:targetFilter(sgs.PlayerList(), q, p) then
									can_use = true
									break
								end
							end
							if can_use then
								--room:setPlayerMark(splayer, card:objectName() .. card:getEffectiveId() .. "-Clear", 1)
								room:addPlayerMark(p, self:objectName() .."Card".. card:getEffectiveId() .. "-Clear", 2)
								room:addPlayerMark(p, self:objectName(), 1)
								room:setPlayerMark(p, "meizlrongzhuang_cd", card:getId())
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (p:getMark("meizlrongzhuang") > 0) and not p:hasFlag("meizlrongzhuang_using") then
						local scard = sgs.Sanguosha:getCard(p:getMark("meizlrongzhuang_cd"))
						room:setPlayerFlag(p, "meizlrongzhuang_using")
						local use = room:askForUseCard(p, "@@meizlrongzhuang",
							("#meizlrongzhuang:%s:%s:%s:%s"):format(scard:objectName(), scard:getSuitString(),
								scard:getNumber(), scard:getEffectiveId()))
						room:setPlayerMark(p, self:objectName() .. scard:getEffectiveId() .. "-Clear", 0)
						room:setPlayerMark(p, "meizlrongzhuang", 0)
						room:setPlayerFlag(p, "-meizlrongzhuang_using")
						room:setPlayerMark(p, "meizlrongzhuang_cd", 0)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return true
	end,
}


meizlmayunlu:addSkill(meizlyuguo)
meizlmayunlu:addSkill(meizlrongzhuang)
meizlmayunlu:addSkill("mashu")

sgs.LoadTranslationTable {
	["meizlmayunlu"] = "马云禄",
	["#meizlmayunlu"] = "西凉巾帼",
	["designer:meizlmayunlu"] = "Mark1469",
	["illustrator:meizlmayunlu"] = "霸王兔",
	["meizlyuguo"] = "域帼",
	[":meizlyuguo"] = "当你于出牌阶段内使用的【杀】被目标角色的【闪】抵消时，你可以进行一次判定，若判定结果为红色，你获得你使用的【杀】，然后此阶段你可以额外使用一张【杀】。",
	["meizlrongzhuang"] = "戎装",
	["~meizlrongzhuang"] = "选择目标→确定",
	["#meizlrongzhuang"] = "请选择【%src】的目标",
	["meizlrongzhuang:usesl"] = "對攻擊範圍內的一名其他角色使用此【杀】",
	[":meizlrongzhuang"] = "每当一名角色使用红色【杀】对目标角色造成一次伤害后，你可以摸一张牌并展示之，若为【杀】，于此牌结算结束后，你可以对攻击范围内一名其他角色使用。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 014 吕玲绮
meizllvlingqi = sgs.General(extension, "meizllvlingqi", "qun", 3, false)
--舞戟（吕玲绮）
meizlwuji = sgs.CreateTargetModSkill {
	name = "meizlwuji",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHandcardNum() <= player:getMaxHp() then
			return 1
		end
	end,
}
--疾驰（吕玲绮）
meizljichi = sgs.CreateTriggerSkill {
	name = "meizljichi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardOffset, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
				local log = sgs.LogMessage()
				log.type = "#Meizljichi"
				log.from = effect.from
				log.to:append(effect.to)
				log.arg  = self:objectName()
				log.arg2 = 1
				room:sendLog(log)
				local tag = sgs.QVariant()
				tag:setValue(effect.to)
				effect.from:setTag("MeizljichiTarget", tag)
				room:setFixedDistance(effect.from, effect.to, 1)
				room:addPlayerMark(effect.to, "&meizljichi+to+#" .. effect.from:objectName() .. "+-Clear")
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if player:distanceTo(damage.to) == 1 and player:objectName() ~= damage.to:objectName() and player:isWounded() then
				local log = sgs.LogMessage()
				log.type = "#Meizljichidamage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = tonumber(damage.damage)
				log.arg2 = tonumber(damage.damage + player:getLostHp())
				room:sendLog(log)
				damage.damage = damage.damage + player:getLostHp()
				data:setValue(damage)
			end
		end
	end
}

meizljichiclear = sgs.CreateTriggerSkill {
	name = "#meizljichiclear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizljichi" then
				return false
			end
		end
		local tag = player:getTag("MeizljichiTarget")
		if tag then
			local target = tag:toPlayer()
			if target then
				room:removeFixedDistance(player, target, 1)
				player:removeTag("MeizljichiTarget")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			local tag = target:getTag("MeizljichiTarget")
			if tag then
				return tag:toPlayer()
			end
		end
		return false
	end
}

meizllvlingqi:addSkill(meizlwuji)
meizllvlingqi:addSkill(meizljichi)
meizllvlingqi:addSkill(meizljichiclear)
extension:insertRelatedSkills("meizljichi", "#meizljichiclear")
sgs.LoadTranslationTable {
	["meizllvlingqi"] = "吕玲绮",
	["#meizllvlingqi"] = "飞将之后",
	["designer:meizllvlingqi"] = "Mark1469",
	["illustrator:meizllvlingqi"] = "三国轮舞曲",
	["illustrator:meizllvlingqi_1"] = "三国轮舞曲",
	["meizlwuji"] = "舞戟",
	[":meizlwuji"] = "若你的手牌数少于或等于体力上限，当你使用【杀】时，你可以额外选择一个目标。",
	["meizljichi"] = "疾驰",
	["#Meizljichi"] = "%from的技能【%arg】被触发，%from与%to距离为%arg2直至回合结束。",
	["#Meizljichidamage"] = "%from的技能【<font color=\"yellow\"><b>疾驰</b></font>】被触发，%from对%to造成的伤害由%arg点至增加至%arg2点。",
	[":meizljichi"] = "<font color=\"blue\"><b>锁定技，</b></font>当你在出牌阶段内使用的【杀】被目标角色的【闪】抵消时，你与该角色距离为1直至回合结束；你对距离1以内的其他角色造成的伤害+X（X为你已损失的体力值） 。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 015 王元姬
meizlwangyuanji = sgs.General(extension, "meizlwangyuanji", "wei", 3, false)
--睿目（王元姬）
meizlruimucard = sgs.CreateSkillCard {
	name = "meizlruimucard",
	will_throw = true,

	on_use = function(self, room, source, targets)
		targets[1]:drawCards(2)
		room:setPlayerMark(targets[1], "meizlruimu", targets[1]:getMaxHp())
		room:loseMaxHp(targets[1], targets[1]:getMaxHp() - 1)
		room:addPlayerMark(targets[1], "&meizlruimu+to+#" .. source:objectName() .. "-SelfClear")
	end
}

meizlruimuskill = sgs.CreateViewAsSkill {
	name = "meizlruimu",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlruimucard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlruimu"
	end
}

meizlruimu = sgs.CreateTriggerSkill
	{
		name = "meizlruimu",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_NotFrequent,
		view_as_skill = meizlruimuskill,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("meizlruimu") > 0 then
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMark("meizlruimu")))
					room:setPlayerMark(player, "meizlruimu", 0)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				end
				if player:hasSkill(self:objectName()) then
					if not player:isNude() then
						room:askForUseCard(player, "@@meizlruimu", "@meizlruimu-card")
					end
				end
			end
		end,
		can_trigger = function(self, target)
			return true
		end
	}
--贤淑（王元姬）
meizlxianshu = sgs.CreateTriggerSkill {
	name = "meizlxianshu",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local _player = damage.to
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer:canDiscard(_player, "h") and room:askForSkillInvoke(splayer, self:objectName(), data) then
				local card
				local id = room:askForCardChosen(splayer, _player, "h", self:objectName())
				card = sgs.Sanguosha:getCard(id)
				if not _player:isJilei(card) then
					room:throwCard(card, _player)
					if card:isRed() then
						local recover = sgs.RecoverStruct()
						recover.who = splayer
						room:recover(_player, recover)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}

meizlwangyuanji:addSkill(meizlruimu)
meizlwangyuanji:addSkill(meizlxianshu)
sgs.LoadTranslationTable {
	["meizlwangyuanji"] = "王元姬",
	["#meizlwangyuanji"] = "慧眼美姬",
	["designer:meizlwangyuanji"] = "Mark1469",
	["illustrator:meizlwangyuanji"] = "Yang Fan",
	["meizlruimu"] = "睿目",
	["meizlruimucard"] = "睿目",
	["~meizlruimu"] = "选择一张红桃牌→选择一名其他角色→点击确定",
	["@meizlruimu-card"] = "请选择“睿目”的目标",
	[":meizlruimu"] = "结束阶段开始时，你可以弃置一张红桃牌，然后令一名其他角色摸两张牌并将体力上限减至1，该角色的回合结束时，该角色重置其体力上限并回复1点体力。",
	["meizlxianshu"] = "贤淑",
	[":meizlxianshu"] = "每当一名角色受到一次伤害后，你可以弃置该角色的一张手牌，若该牌为红色，该角色回复1点体力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 016 陆郁生
meizlluyusheng = sgs.General(extension, "meizlluyusheng", "wu", 3, false)
--孤孀（陆郁生）
meizlgushuang = sgs.CreateTriggerSkill {
	name = "meizlgushuang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death, sgs.HpRecover },
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local log = sgs.LogMessage()
			log.from = splayer
			log.arg = self:objectName()
			if event == sgs.Death then
				local death = data:toDeath()
				if not player:hasSkill("meizlgushuang") then return end
				if splayer:objectName() == death.who:objectName() then return end
				log.type = "#Meizlgushuangthrow"
				room:sendLog(log)
				splayer:throwAllHandCards()
			elseif event == sgs.HpRecover then
				if not player:isWounded() then
					log.type = "#Meizlgushuangdraw"
					room:sendLog(log)
					splayer:drawCards(2)
				end
			end
		end
	end
}
--昭节（陆郁生）
meizlzhaojiecard = sgs.CreateSkillCard {
	name = "meizlzhaojiecard",
	will_throw = false,


	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and (#targets < 1)
	end,

	on_use = function(self, room, source, targets)
		local x = self:subcardsLength()
		room:obtainCard(targets[1], self, false)
		if x >= source:getHp() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end
}

meizlzhaojie = sgs.CreateViewAsSkill {
	name = "meizlzhaojie",
	n = 999,

	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local rende_card = meizlzhaojiecard:clone()
			for i = 1, #cards, 1 do
				local id = cards[i]:getId()
				rende_card:addSubcard(id)
			end
			return rende_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlzhaojiecard")
	end,
}

meizlluyusheng:addSkill(meizlzhaojie)
meizlluyusheng:addSkill(meizlgushuang)
sgs.LoadTranslationTable {
	["meizlluyusheng"] = "陆郁生",
	["#meizlluyusheng"] = "义姑",
	["designer:meizlluyusheng"] = "Mark1469",
	["illustrator:meizlluyusheng"] = "夏季",
	["meizlzhaojie"] = "昭节",
	["meizlzhaojiecard"] = "昭节",
	[":meizlzhaojie"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意数量的红色牌交给一名其他角色，若你以此法给出的牌张数不少于X张，你回复1点体力（X为你当前的体力值）。",
	["meizlgushuang"] = "孤孀",
	[":meizlgushuang"] = "<font color=\"blue\"><b>锁定技，</b></font>每当一名角色回复一次体力后，若该角色没有受伤，你摸两张牌；每当其他角色死亡时，你弃置所有手牌。",
	["#Meizlgushuangthrow"] = "%from的技能【%arg】被触发，%from弃置所有手牌。",
	["#Meizlgushuangdraw"] = "%from的技能【%arg】被触发，%from摸两张牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 017 杨婉
meizlyangwan = sgs.General(extension, "meizlyangwan", "shu", 3, false)
--请宴（杨婉）
meizlqingyancard = sgs.CreateSkillCard {
	name = "meizlqingyancard",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		dest:obtainCard(self)
		local room = effect.to:getRoom()
		room:obtainCard(dest, self)
		local pattern = "BasicCard|.|.|hand$1"
		room:setPlayerCardLimitation(dest, "use,response", pattern, false)
		room:setPlayerMark(dest, "@meizlqingyan", 1)
		local log = sgs.LogMessage()
		log.type = "#Meizlqingyan"
		log.from = source
		log.to:append(dest)
		log.arg = self:objectName()
		room:sendLog(log)
		room:addPlayerMark(dest, "&meizlqingyan+to+#" .. source:objectName())
	end
}
meizlqingyanskill = sgs.CreateViewAsSkill {
	name = "meizlqingyan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local meizlqingyancard = meizlqingyancard:clone()
			meizlqingyancard:addSubcard(cards[1])
			return meizlqingyancard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

meizlqingyan = sgs.CreateTriggerSkill {
	name = "meizlqingyan",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlqingyanskill,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@meizlqingyan") > 0 then
					room:removePlayerCardLimitation(p, "use,response", "BasicCard|.|.|hand$1")
					room:setPlayerMark(p, "@meizlqingyan", 0)
					for _, mark in sgs.list(p:getMarkNames()) do
						if string.find(mark, "meizlqingyan") and p:getMark(mark) > 0 then
							room:setPlayerMark(p, mark, 0)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end
}

meizlqingyanclear = sgs.CreateTriggerSkill {
	name = "#meizlqingyanclear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:getMark("@meizlqingyan") > 0 then
			room:removePlayerCardLimitation(player, "use,response", "BasicCard")
			room:setPlayerMark(player, "@meizlqingyan", 0)
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "meizlqingyan") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
		end
		if event == sgs.EventLoseSkill then
			for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if splayer and player:objectName() == splayer:objectName() then
					if data:toString() == "meizlqingyan" then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("@meizlqingyan") > 0 then
								room:removePlayerCardLimitation(p, "use,response", "BasicCard")
								room:setPlayerMark(p, "@meizlqingyan", 0)
								for _, mark in sgs.list(p:getMarkNames()) do
									if string.find(mark, "meizlqingyan") and p:getMark(mark) > 0 then
										room:setPlayerMark(p, mark, 0)
									end
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
--相接（杨婉）
meizlxiangjie = sgs.CreateTriggerSkill {
	name = "meizlxiangjie",
	frequency = sgs.NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer and player:getPhase() == sgs.Player_Play and player:objectName() ~= splayer:objectName() then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:inMyAttackRange(p) then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return end
				if splayer:isKongcheng() then return end
				if room:askForSkillInvoke(splayer, self:objectName()) then
					local tohelp = sgs.QVariant()
					tohelp:setValue(player)
					local prompt = string.format("@meizlxiangjie-slash:%s", player:objectName())
					local slash = room:askForCard(splayer, "slash", prompt, tohelp, sgs.Card_MethodResponse, player)
					if slash then
						local target = room:askForPlayerChosen(splayer, targets, self:objectName())
						slash:setSkillName("meizlxiangjie")
						local use = sgs.CardUseStruct()
						use.card = slash
						use.from = player
						use.to:append(target)
						room:useCard(use)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}

meizlyangwan:addSkill(meizlqingyan)
meizlyangwan:addSkill(meizlxiangjie)
meizlyangwan:addSkill(meizlqingyanclear)
extension:insertRelatedSkills("meizlqingyan", "#meizlqingyanclear")

sgs.LoadTranslationTable {
	["meizlyangwan"] = "杨婉",
	["#meizlyangwan"] = "猛狮之妻",
	["illustrator:meizlyangwan"] = "あおひと",
	["designer:meizlyangwan"] = "Mark1469",
	["meizlqingyan"] = "请宴",
	["meizlqingyancard"] = "请宴",
	["#Meizlqingyan"] = "%from 发动了“%arg”，%to 不能使用或打出基本牌直至其回合结束",
	[":meizlqingyan"] = "出牌阶段，你可以将一张牌交给一名其他角色，然后该角色不能使用或打出基本牌直至该角色的回合结束。",
	["meizlxiangjie"] = "相接",
	["@meizlxiangjie-slash"] = "你可以打出一张【杀】时，视为由%src对其攻击范围内你选择的另一名角色使用",
	[":meizlxiangjie"] = "其他角色的出牌阶段开始时，你可以打出一张【杀】，视为由当前回合角色对其攻击范围内你选择的另一名角色使用（不​​计入出牌阶段内的使用次数限制）。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 018 王悦
meizlwangyue = sgs.General(extension, "meizlwangyue", "shu", 3, false)
--护关（王悦）
meizlhuguan = sgs.CreateTriggerSkill {
	name = "meizlhuguan",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:askForSkillInvoke(player, self:objectName()) then return false end
		player:drawCards(1)
	end
}
--武姻（王悦）
meizlwuyinskill = sgs.CreateViewAsSkill {
	name = "meizlwuyin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = meizlwuyincard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlwuyincard")
	end,
}

meizlwuyincard = sgs.CreateSkillCard {
	name = "meizlwuyincard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return to_select:getGeneral():isMale() and #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("meizlwuyin")
		room:cardEffect(duel, source, targets[1])
		duel:deleteLater()
	end
}

meizlwuyin = sgs.CreateTriggerSkill
	{
		name = "meizlwuyin",
		events = { sgs.DamageCaused },
		view_as_skill = meizlwuyinskill,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Duel") then
				if room:askForSkillInvoke(player, self:objectName()) then
					local log = sgs.LogMessage()
					log.type = "#Meizlwuyin"
					log.from = player
					log.to:append(damage.to)
					log.arg = self:objectName()
					room:sendLog(log)
					local recover = sgs.RecoverStruct()
					recover.recover = 1
					recover.who = player
					room:recover(player, recover)
					return true
				end
			end
		end
	}

meizlwangyue:addSkill(meizlhuguan)
meizlwangyue:addSkill(meizlwuyin)
sgs.LoadTranslationTable {
	["meizlwangyue"] = "王悦",
	["#meizlwangyue"] = "盗贼娇花",
	["designer:meizlwangyue"] = "Mark1469",
	["illustrator:meizlwangyue"] = "三国轮舞曲",
	["illustrator:meizlwangyue_1"] = "三国轮舞曲",
	["meizlhuguan"] = "护关",
	[":meizlhuguan"] = "每当你受到一次伤害后，你可以摸一张牌。",
	["meizlwuyin"] = "武姻",
	["#Meizlwuyin"] = "%from发动技能【%arg】，防止对%to造成的伤害并回复1点体力。",
	["meizlwuyincard"] = "武姻",
	[":meizlwuyin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择一名男性角色，视为你对该角色使用一张【决斗】。每当你因【决斗】而造成伤害时，你可以防止此伤害并回复1点体力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 019 杜氏
meizldushi = sgs.General(extension, "meizldushi", "qun", 3, false)
--迷魂（杜氏）
meizlmihuncard = sgs.CreateSkillCard {
	name = "meizlmihuncard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return not (to_select == sgs.Self or to_select:isNude()) and to_select:objectName() ~= sgs.Self:objectName() and
			(#targets < 2)
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(targets[1], targets[2], "he", "meizlmihun")
		room:throwCard(card_id, targets[2], targets[1])
		local card_id = room:askForCardChosen(targets[2], targets[1], "he", "meizlmihun")
		room:throwCard(card_id, targets[1], targets[2])
	end
}

meizlmihun = sgs.CreateViewAsSkill {
	name = "meizlmihun",
	n = 1,

	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlmihuncard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlmihuncard")
	end,
}
--妖娆（杜氏）
meizlyaorao = sgs.CreateTriggerSkill {
	name = "meizlyaorao",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	limit_mark = "@meizlyaorao",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getMark("@meizlyaorao") > 0 then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			player:loseMark("@meizlyaorao", 1)
			room:setPlayerMark(player, "meizlyaorao", 1)
			room:addPlayerMark(player, "&meizlyaorao-Clear")
			player:drawCards(2)
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getMark("meizlyaorao") > 0 then
			room:setPlayerMark(player, "meizlyaorao", 0)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, cd in sgs.qlist(player:getPile("meizlyaorao")) do
				dummy:addSubcard(sgs.Sanguosha:getCard(cd))
			end
			room:obtainCard(player, dummy)
			dummy:deleteLater()
		end
	end
}
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
meizlyaoraoskill = sgs.CreateTriggerSkill {
	name = "#meizlyaoraoskill",
	frequency = sgs.Skill_Limited,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local card_ids = sgs.IntList()
		if player:getMark("meizlyaorao") > 0 and (move.to_place == sgs.Player_DiscardPile) then
			local i = 0
			if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) or
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_RESPONSE) or
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				for _, card_id in sgs.qlist(move.card_ids) do
					if (move.to_place == sgs.Player_DiscardPile) then
						card_ids:append(card_id)
						i = i + 1
					end
				end
			end
		end
		if not card_ids:isEmpty() then
			for _, id in sgs.qlist(card_ids) do
				if move.card_ids:contains(id) then
					move.from_places:removeAt(listIndexOf(move.card_ids, id))
					move.card_ids:removeOne(id)
					data:setValue(move)
					if not player:isAlive() then break end
				end
			end
			player:addToPile("meizlyaorao", card_ids, true)
			--	room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
		end
		return false
	end
}

meizldushi:addSkill(meizlmihun)
meizldushi:addSkill(meizlyaorao)
meizldushi:addSkill(meizlyaoraoskill)
extension:insertRelatedSkills("meizlyaorao", "#meizlyaoraoskill")
sgs.LoadTranslationTable {
	["meizldushi"] = "杜氏",
	["#meizldushi"] = "魂倾义奸",
	["designer:meizldushi"] = "Mark1469",
	["illustrator:meizldushi"] = "三国志大战TCG",
	["illustrator:meizldushi_1"] = "啪啪三国",
	["meizlmihun"] = "迷魂",
	["meizlmihuncard"] = "迷魂",
	[":meizlmihun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择两名手牌数不少于1的其他角色，他们各弃置对方的一张牌。",
	["meizlyaorao"] = "妖娆",
	["@meizlyaorao"] = "妖娆",
	[":meizlyaorao"] = "<font color=\"red\"><b>限定技，</b></font>回合开始阶段开始时，你可以摸两限牌，然后此回合内，当一名角色的牌因使用、打出或弃置而置入弃牌堆时，你将之置于武将牌上。回合结束时，你获得武将牌上的所有牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 020 伏寿
meizlfushou = sgs.General(extension, "meizlfushou", "qun", 3, false)
--密笺（伏寿）
meizlmijiancard = sgs.CreateSkillCard {
	name = "meizlmijiancard",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select, player)
		return not to_select:objectName() ~= player:objectName() and (#targets < 1)
	end,

	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:obtainCard(target, self, false)
		if source:isAlive() then
			local count = self:subcardsLength()
			local card = room:askForExchange(target, "meizlmijian", self:subcardsLength(), self:subcardsLength(), true,
				"@meizlmijian", false)
			source:obtainCard(card, false)
			if count > source:getHp() then
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = source
				room:recover(source, recover)
			end
		end
	end
}
meizlmijian = sgs.CreateViewAsSkill {
	name = "meizlmijian",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local meizlmijiancard = meizlmijiancard:clone()
			for _, card in pairs(cards) do
				meizlmijiancard:addSubcard(card)
			end
			meizlmijiancard:setSkillName(self:objectName())
			return meizlmijiancard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlmijiancard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlnibi"
	end
}
--匿壁（伏寿）
meizlnibi = sgs.CreateTriggerSkill {
	name = "meizlnibi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForPeaches, sgs.TurnedOver },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local source = dying.who
			if source:objectName() == player:objectName() then
				if not source:faceUp() then return false end
				if source:askForSkillInvoke(self:objectName(), data) then
					local recover = sgs.RecoverStruct()
					recover.recover = 1 - source:getHp()
					recover.who = source
					room:recover(source, recover)
					source:turnOver()
				end
			end
		elseif event == sgs.TurnedOver then
			if player:hasSkill("meizlmijian") then
				room:setPlayerFlag(player, "meizlnibi")
				room:askForUseCard(player, "@@meizlnibi", "@meizlnibi")
				room:setPlayerFlag(player, "-meizlnibi")
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

meizlfushou:addSkill(meizlmijian)
meizlfushou:addSkill(meizlnibi)
sgs.LoadTranslationTable {
	["meizlfushou"] = "伏寿",
	["#meizlfushou"] = "孝献皇后",
	["designer:meizlfushou"] = "Mark1469",
	["illustrator:meizlfushou"] = "樱花闪乱",
	["illustrator:meizlfushou_1"] = "大戦乱!!三国志バトル",
	["meizlmijian"] = "密笺",
	["meizlmijiancard"] = "密笺",
	["@meizlmijian"] = "请交还伏寿等量的牌",
	[":meizlmijian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意数量的牌（至少一张）交给一名其他角色，然后该角色须交给你等量的牌。若以此法给出的牌张牌大于你的体力值，你回复1点体力。",
	["meizlnibi"] = "匿壁",
	["@meizlnibi"] = "【匿壁】效果被触发，你可以发动技能【密笺】",
	["~meizlnibi"] = "选择任意数量的牌和一名其他角色→点击确定",
	[":meizlnibi"] = "当你处于濒死状态时，若你的武将牌正面朝上，你可以将体力回复至1点，然后将你的武将牌翻面；当你的武将牌翻面时，你可以发动技能“密笺”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 021 郭女王
meizlguonvwang = sgs.General(extension, "meizlguonvwang", "wei", 3, false)
--谮言（郭女王）
meizlzenyan = sgs.CreateTriggerSkill {
	name = "meizlzenyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer and player:getPhase() == sgs.Player_Draw and player:objectName() ~= splayer:objectName() then
				if player:getHandcardNum() > player:getHp() and not splayer:isKongcheng() then
					if room:askForDiscard(splayer, self:objectName(), 1, 1, true, false, "meizlzenyan-invoke") then
						local x = player:getHandcardNum() - player:getHp()
						room:askForDiscard(player, "meizlzenyan_dis", x, x, false, false)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
--专宠（郭女王）
meizlzhuanchong = sgs.CreateTriggerSkill {
	name = "meizlzhuanchong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.HpChanged },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if (splayer:objectName() == player:objectName()) then continue end
			if player:getHp() <= 0 then
				local dest = sgs.QVariant()
				dest:setValue(player)
				if splayer:askForSkillInvoke(self:objectName(), dest) then
					player:drawCards(2)
					if not room:askForCard(player, ".Equip", "@meizlzhuanchong", sgs.QVariant(), self:objectName()) then
						room:killPlayer(player, nil)
					else
						local recover = sgs.RecoverStruct()
						recover.recover = 1 - player:getHp()
						recover.who = player
						room:recover(player, recover)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
--干政（郭女王）
meizlganzhengcard = sgs.CreateSkillCard {
	name = "meizlganzhengcard",
	target_fixed = false,
	will_throw = true,


	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and (#targets < 1)
	end,

	on_use = function(self, room, source, targets)
		source:loseMark("@meizlganzheng")
		local recover = sgs.RecoverStruct()
		recover.recover = source:getMaxHp() - source:getHp()
		recover.who = source
		room:recover(source, recover)
		local recover = sgs.RecoverStruct()
		recover.recover = targets[1]:getMaxHp() - targets[1]:getHp()
		recover.who = source
		room:recover(targets[1], recover)
		source:drawCards(4)
		targets[1]:drawCards(4)
		targets[1]:turnOver()
	end
}
meizlganzhengskill = sgs.CreateViewAsSkill {
	name = "meizlganzheng",
	n = 0,
	view_as = function(self, cards)
		return meizlganzhengcard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlganzheng") > 0
	end
}
meizlganzheng = sgs.CreateTriggerSkill {
	name = "meizlganzheng",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlganzhengskill,
	limit_mark = "@meizlganzheng",
	events = {},
	on_trigger = function(self, event, player, data)
	end
}

meizlguonvwang:addSkill(meizlzenyan)
meizlguonvwang:addSkill(meizlzhuanchong)
meizlguonvwang:addSkill(meizlganzheng)
sgs.LoadTranslationTable {
	["meizlguonvwang"] = "郭女王",
	["#meizlguonvwang"] = "文德皇后",
	["designer:meizlguonvwang"] = "Mark1469",
	["illustrator:meizlguonvwang"] = "Generals Order",
	["illustrator:meizlguonvwang_1"] = "大戦乱!!三国志バトル",
	["meizlzenyan"] = "谮言",
	["meizlzenyan_dis"] = "谮言",
	[":meizlzenyan"] = "其他角色的摸牌阶段结束时，你可以弃置一张手牌，然后该角色将手牌弃置至等同其体力值的张牌。",
	["meizlzenyan-invoke"] = "你可以弃置一张手牌，發動技能“谮言”",
	["meizlzhuanchong"] = "专宠",
	["@meizlzhuanchong"] = "你可以弃置一张装备牌，然后将体力回复至1点。否则，你跳过濒死结算。",
	[":meizlzhuanchong"] = "当其他角色体力值扣减至0后，你可以令该角色摸两张牌，然后该角色选择一项：弃置一张装备牌，然后将体力回复至1点，或跳过濒死结算，立即阵亡。",
	["meizlganzheng"] = "干政",
	["meizlganzhengcard"] = "干政",
	["@meizlganzheng"] = "干政",
	[":meizlganzheng"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以选择一名其他角色，该角色与你各将体力回复至体力上限并摸4张牌，然后该角色将其武将牌翻面。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 022 甄姬
meizlzhenji = sgs.General(extension, "meizlzhenji", "wei", 3, false)
--薄幸（甄姬）
meizlboxing = sgs.CreateTriggerSkill {
	name = "meizlboxing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForPeaches },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and not player:isKongcheng() then
				if player:faceUp() and player:askForSkillInvoke(self:objectName(), data) then
					local x = math.min(player:getHandcardNum(), player:getMaxHp() - player:getHp())
					player:throwAllHandCards()
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = x
					room:recover(player, recover)
					player:turnOver()
				end
			end
		end
	end,
}
--游龙（甄姬）
meizlyoulong = sgs.CreateTriggerSkill {
	name = "meizlyoulong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			while player:askForSkillInvoke(self:objectName()) do
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				judge.time_consuming = true
				room:judge(judge)
				if judge:isBad() then
					break
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:addToPile("meizlyoulong", judge.card:getEffectiveId())
					return true
				elseif card:isRed() then
					local x = 0
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(),
						"meizlyoulong", "");
					for _, p in sgs.qlist(player:getPile("meizlyoulong")) do
						x = x + 1
						dummy:addSubcard(sgs.Sanguosha:getCard(p))
						--room:obtainCard(player,sgs.Sanguosha:getCard(p),true)
					end
					room:obtainCard(player, dummy, reason, false)
					if x >= 3 then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						room:recover(player, recover)
					end
				end
			end
		end
		return false
	end
}

meizlzhenji:addSkill(meizlboxing)
meizlzhenji:addSkill(meizlyoulong)
sgs.LoadTranslationTable {
	["meizlzhenji"] = "甄姬",
	["#meizlzhenji"] = "文昭皇后",
	["designer:meizlzhenji"] = "Mark1469",
	["illustrator:meizlzhenji"] = "群龍三國伝",
	["illustrator:meizlzhenji_1"] = "三国轮舞曲",
	["meizlboxing"] = "薄幸",
	[":meizlboxing"] = "当你处于濒死状态时，若你的武将牌正面朝上，你可以将你的武将牌翻面，然后弃置所有手牌并回复等量的体力。",
	["meizlyoulong"] = "游龙",
	[":meizlyoulong"] = "每当你受到一次伤害后，你可以进行一次判定，若结果为黑色，你可以再次进行判定，直到出现红色的判定结果为止。然后你获得所有黑色的判定牌。若以此法获得的牌不少于3张，你回复1点体力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 023 孙鲁育
meizlsunluyu = sgs.General(extension, "meizlsunluyu", "wu", 3, false)
--循德（孙鲁育）
meizlxunde = sgs.CreateTriggerSkill {
	name = "meizlxunde",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile) and
			(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			local card_ids = sgs.IntList()
			local ids = sgs.QList2Table(move.card_ids)
			for i = 1, #ids, 1 do
				local card_id = ids[i]
				if room:getCardOwner(card_id):objectName() == move.from:objectName()
					and ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip)) then
					card_ids:append(card_id)
				end
			end

			if not card_ids:isEmpty() then
				local x = card_ids:length()
				local dummy = sgs.Sanguosha:cloneCard("Slash")
				for _, id in sgs.qlist(card_ids) do
					if move.card_ids:contains(id) then
						move.from_places:removeAt(listIndexOf(move.card_ids, id))
						move.card_ids:removeOne(id)
						data:setValue(move)
						dummy:addSubcard(sgs.Sanguosha:getCard(id))
					end
					--	room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
					--	if not player:isAlive() then break end
				end
				room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
				room:broadcastSkillInvoke(self:objectName())
				local discard = room:askForExchange(player, self:objectName(), x, x, true, "meizlxundediscard")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(),
					"")
				room:moveCardTo(discard, nil, nil, sgs.Player_DiscardPile, reason)
				dummy:deleteLater()
			end
		end
	end
}
--冤逝（孙鲁育）
meizlyuanshi = sgs.CreateTriggerSkill {
	name = "meizlyuanshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()

		local room = death.who:getRoom()
		local targets
		if not death.who:hasSkill(self:objectName()) then return dalse end
		if player:objectName() ~= death.who:objectName() then return false end
		if death.damage and death.damage.from then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:loseMaxHp(death.damage.from, 1)
			room:addPlayerMark(death.damage.from, "&meizlyuanshi")
		end
	end
}

meizlsunluyu:addSkill(meizlxunde)
meizlsunluyu:addSkill(meizlyuanshi)
sgs.LoadTranslationTable {
	["meizlsunluyu"] = "孙鲁育",
	["#meizlsunluyu"] = "江东的幽兰",
	["illustrator:meizlsunluyu"] = "夕也",
	["illustrator:meizlsunluyu_1"] = "大戦乱!!三国志バトル",
	["designer:meizlsunluyu"] = "Mark1469",
	["meizlxunde"] = "循德",
	["meizlxundediscard"] = "请你选择等量的牌并将之置于弃牌堆",
	[":meizlxunde"] = "<font color=\"blue\"><b>锁定技，</b></font>当其他角色的牌因弃置而置入弃牌堆时，你获得之并将等量的牌置于弃牌堆。",
	["meizlyuanshi"] = "冤逝",
	[":meizlyuanshi"] = "<font color=\"blue\"><b>锁定技，</b></font>杀死你的角色减1点体力上限。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 024 小乔
meizlxiaoqiao = sgs.General(extension, "meizlxiaoqiao", "wu", 3, false)
--香闺（小乔）
meizlxianggui = sgs.CreateTriggerSkill {
	name = "meizlxianggui",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and player:getHandcardNum() > player:getHp() then
			if player:askForSkillInvoke(self:objectName(), data) then
				local x = math.min(player:getHandcardNum() - player:getHp(), 2)
				player:drawCards(x)
			end
		end
	end
}
--羞花（小乔）
meizlxiuhua = sgs.CreateTriggerSkill {
	name = "meizlxiuhua",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:distanceTo(damage.from) <= 2 and damage.nature ~= sgs.DamageStruct_Normal then
			local log = sgs.LogMessage()
			log.type = "#Meizlxiuhua"
			log.from = player
			log.to:append(damage.from)
			log.arg  = tonumber(damage.damage)
			log.arg2 = tonumber(damage.damage - 1)
			room:sendLog(log)
			damage.damage = damage.damage - 1
			if damage.damage < 1 then
				return true
			end
			data:setValue(damage)
		end
	end
}

meizlxiaoqiao:addSkill(meizlxianggui)
meizlxiaoqiao:addSkill(meizlxiuhua)

sgs.LoadTranslationTable {
	["meizlxiaoqiao"] = "小乔",
	["#meizlxiaoqiao"] = "秋水芙蓉",
	["illustrator:meizlxiaoqiao"] = "Snowfox",
	["illustrator:meizlxiaoqiao_1"] = "三国轮舞曲",
	["designer:meizlxiaoqiao"] = "Mark1469",
	["meizlxianggui"] = "香闺",
	[":meizlxianggui"] = "摸牌阶段结束時，若你的手牌数大于体力值，你可以摸X张牌（X为你手牌数与体力值之差且至多为2）。",
	["meizlxiuhua"] = "羞花",
	["#Meizlxiuhua"] = "%from的技能【<font color=\"yellow\"><b>羞花</b></font>】被触发，%to对%from造成的伤害由%arg点至减至%arg2点。",
	[":meizlxiuhua"] = "<font color=\"blue\"><b>锁定技，</b></font>你距离2以内的角色对你造成的属性伤害-1。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 025 孙鲁班
meizlsunluban = sgs.General(extension, "meizlsunluban", "wu", 3, false)
--谗惑（孙鲁班）
meizlchanhuocard = sgs.CreateSkillCard {
	name = "meizlchanhuocard",
	will_throw = false,


	filter = function(self, targets, to_select, player)
		return not to_select:isKongcheng() and to_select:objectName() ~= player:objectName() and to_select:getHp() == 1 and
			(#targets < 1)
	end,

	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "meizlchanhuo", nil)
		if success then
			room:killPlayer(targets[1], nil)
		else
			room:detachSkillFromPlayer(source, "meizlchanhuo")
		end
	end
}
meizlchanhuo = sgs.CreateViewAsSkill {
	name = "meizlchanhuo",
	n = 0,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = meizlchanhuocard:clone()
			--card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlchanhuocard")
	end,
}
--谮毁（孙鲁班）
meizlzenhuicard = sgs.CreateSkillCard {
	name = "meizlzenhuicard",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		if source:getMark("@meizlzenhui") > 0 then
			source:loseMark("@meizlzenhui")
			room:setPlayerMark(source, "&meizlzenhui", 0)
		else
			source:gainMark("@meizlzenhui")
			room:setPlayerMark(source, "&meizlzenhui", 1)
		end
	end
}
meizlzenhuiskill = sgs.CreateViewAsSkill {
	name = "meizlzenhui",
	n = 1,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlzenhuicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlzenhuicard")
	end,
}
meizlzenhui = sgs.CreateTriggerSkill {
	name = "meizlzenhui",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlzenhuiskill,
	events = { sgs.ConfirmDamage, sgs.DrawNCards, sgs.Death, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death and player:getPhase() ~= sgs.Player_NotActive then
			room:setPlayerMark(player, "&meizlzenhuiskill", 1)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if player:getMark("&meizlzenhuiskill") == 0 and player:getMark("@meizlzenhui") > 0 then
				room:loseMaxHp(player, 1)
			else
				room:setPlayerMark(player, "&meizlzenhuiskill", 0)
			end
		end
		if player:getMark("@meizlzenhui") > 0 then
			if event == sgs.ConfirmDamage then
				local damage = data:toDamage()
				if damage.card and damage.card:isKindOf("Slash") and damage.to:isMale() then
					damage.damage = damage.damage + 1
					data:setValue(damage)
					local log = sgs.LogMessage()
					log.type = "#skill_add_damage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg  = self:objectName()
					log.arg2 = damage.damage
					room:sendLog(log)
				end
			elseif event == sgs.DrawNCards then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				draw.num = draw.num + 1
				data:setValue(draw)
			end
		end
	end
}

meizlsunluban:addSkill(meizlchanhuo)
meizlsunluban:addSkill(meizlzenhui)

sgs.LoadTranslationTable {
	["meizlsunluban"] = "孙鲁班",
	["#meizlsunluban"] = "东吴的毒刺",
	["illustrator:meizlsunluban"] = "双剣のクロスエイジ",
	["designer:meizlsunluban"] = "Mark1469",
	["meizlchanhuo"] = "谗惑",
	["meizlchanhuocard"] = "谗惑",
	[":meizlchanhuo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以和一名体力值为1的其他角色拼点。若你赢，该角色立即死亡。若你没赢，你失去技能“谗惑”。",
	["meizlzenhui"] = "谮毁",
	["@meizlzenhui"] = "谮毁",
	["meizlzenhuicard"] = "谮毁",
	[":meizlzenhui"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌，然后获得或取消以下效果：摸牌阶段，你额外摸一张牌；你使用【杀】对男性目标角色造成的伤害+1；回合结束时，若此回合内没有角色死亡，你减1点体力上限。",
	["meizlzenhuiskill"] = "谮毁:有角色死亡",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 026 黄蝶舞
meizlhuangdiewu = sgs.General(extension, "meizlhuangdiewu", "shu", 3, false)
--箭舞（黄蝶舞）
meizljianwucard = sgs.CreateSkillCard {
	name = "meizljianwucard",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		if source:getMark("@meizljianwu") > 0 then
			source:loseMark("@meizljianwu")
			room:handleAcquireDetachSkills(source, "-meizljianwuskill2")
			room:setPlayerMark(source, "&meizljianwu", 0)
		else
			source:gainMark("@meizljianwu")
			room:handleAcquireDetachSkills(source, "meizljianwuskill2")
			room:setPlayerMark(source, "&meizljianwu", 1)
		end
	end
}
meizljianwuskill = sgs.CreateViewAsSkill {
	name = "meizljianwu",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizljianwucard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizljianwucard")
	end,
}
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
meizljianwu = sgs.CreateTriggerSkill {
	name = "meizljianwu",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizljianwuskill,
	events = { sgs.DrawNCards, sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@meizljianwu") > 0 then
			if event == sgs.TargetSpecified then
				local use = data:toCardUse()
				local card = use.card
				local source = use.from
				local room = player:getRoom()
				if card:isKindOf("Slash") then
					if source:objectName() == player:objectName() then
						local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
						local index = 1
						local range = player:getAttackRange()
						local targets = use.to
						for _, target in sgs.qlist(targets) do
							local count = target:getHandcardNum()
							if count <= range then
								jink_table[index] = 0
								local log = sgs.LogMessage()
								log.type = "#skill_cant_jink"
								log.from = player
								log.to:append(target)
								log.arg = self:objectName()
								room:sendLog(log)
							end
							index = index + 1
						end
						local jink_data = sgs.QVariant()
						jink_data:setValue(Table2IntList(jink_table))
						player:setTag("Jink_" .. use.card:toString(), jink_data)
						return false
					end
				end
			elseif event == sgs.DrawNCards then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				draw.num = draw.num - 1
				data:setValue(draw)
			end
		end
	end
}
meizljianwudistance = sgs.CreateDistanceSkill {
	name = "#meizljianwudistance",
	correct_func = function(self, from, to)
		if from:getMark("@meizljianwu") > 0 then
			return -1
		end
	end,
}
meizljianwuskill2 = sgs.CreateViewAsSkill {
	name = "meizljianwuskill2",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon then
			if to_select:objectName() == weapon:objectName() then
				if to_select:objectName() == "Crossbow" then
					return sgs.Self:canSlashWithoutCrossbow()
				end
			end
		end
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end
}
--毒矢（黄蝶舞）
meizldushiskill = sgs.CreateTriggerSkill {
	name = "meizldushiskill",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getHandcardNum() <= player:getHp() then
			damage.damage = damage.damage + 1
			data:setValue(damage)
			local log = sgs.LogMessage()
			log.type = "#skill_add_damage"
			log.from = damage.from
			log.to:append(damage.to)
			log.arg  = self:objectName()
			log.arg2 = damage.damage
			room:sendLog(log)
		end
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizljianwuskill2") then skills:append(meizljianwuskill2) end
sgs.Sanguosha:addSkills(skills)

meizlhuangdiewu:addSkill(meizljianwu)
meizlhuangdiewu:addSkill(meizljianwudistance)
extension:insertRelatedSkills("meizljianwu", "meizljianwuskill2")
extension:insertRelatedSkills("meizljianwu", "#meizljianwudistance")
meizlhuangdiewu:addSkill(meizldushiskill)
sgs.LoadTranslationTable {
	["meizlhuangdiewu"] = "黄蝶舞",
	["#meizlhuangdiewu"] = "梦蝶",
	["illustrator:meizlhuangdiewu"] = "双剣のクロスエイジ",
	["designer:meizlhuangdiewu"] = "Mark1469",
	["meizljianwu"] = "箭舞",
	["meizljianwucard"] = "箭舞",
	["@meizljianwu"] = "箭舞",
	[":meizljianwu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张黑色牌，然后获得或取消以下效果：摸牌阶段，你少摸一张牌；你与其他角色的距离-1；手牌数小于或等于你攻击范围的角色不能使用【闪】响应你对其使用的【杀】；你可以将一张装备牌当【杀】使用。",
	["meizljianwuskill2"] = "箭舞效果",
	[":meizljianwuskill2"] = "你可以将一张装备牌当【杀】使用。",
	["meizldushiskill"] = "毒矢",
	[":meizldushiskill"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的手牌数少于或等于体力值，你使用【杀】对目标角色造成的伤害+1。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 027 诸葛果
meizlzhugeguo = sgs.General(extension, "meizlzhugeguo", "shu", 3, false)
--禳斗（诸葛果）
meizlrangdoucard = sgs.CreateSkillCard {
	name = "meizlrangdoucard",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		if source:getMark("@meizlrangdou") > 0 then
			source:loseMark("@meizlrangdou")
			room:setPlayerMark(source, "&meizlrangdou", 0)
		else
			source:gainMark("@meizlrangdou")
			room:setPlayerMark(source, "&meizlrangdou", 1)
		end
	end
}
meizlrangdouskill = sgs.CreateViewAsSkill {
	name = "meizlrangdou",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlrangdoucard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlrangdoucard")
	end,
}
meizlrangdou = sgs.CreateTriggerSkill {
	name = "meizlrangdou",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlrangdouskill,
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@meizlrangdou") > 0 then
			local damage = data:toDamage()
			damage.damage = damage.damage - 1
			room:sendCompulsoryTriggerLog(player, "meizlrangdou", true)
			if damage.damage < 1 then
				return true
			end
			data:setValue(damage)
		end
	end
}
meizlrangdoumaxcard = sgs.CreateMaxCardsSkill {
	name = "#meizlrangdoumaxcard",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) and target:getMark("@meizlrangdou") > 0 then
			return -1000
		end
	end
}
--乘烟（诸葛果）
meizlchengyan = sgs.CreateTriggerSkill {
	name = "meizlchengyan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BeforeCardsMove, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if player:getPhase() ~= sgs.Player_Discard then return false end
			if (move.from == nil) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				for _, cdid in sgs.qlist(move.card_ids) do
					room:setPlayerMark(player, "&meizlchengyan", player:getMark("&meizlchengyan") + 1)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			room:setPlayerMark(player, "&meizlchengyan", 0)
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			if player:getMark("&meizlchengyan") > 0 then
				local log = sgs.LogMessage()
				log.type = "#Meizlchengyan"
				log.from = player
				log.arg = tonumber(player:getMark("&meizlchengyan"))
				log.arg2 = self:objectName()
				room:sendLog(log)
			end
		end
	end
}
meizlchengyandistance = sgs.CreateDistanceSkill {
	name = "#meizlchengyandistance",
	correct_func = function(self, from, to)
		if to:getMark("&meizlchengyan") > 0 then
			return to:getMark("&meizlchengyan")
		end
	end,
}

meizlzhugeguo:addSkill(meizlrangdou)
meizlzhugeguo:addSkill(meizlrangdoumaxcard)
meizlzhugeguo:addSkill(meizlchengyandistance)
meizlzhugeguo:addSkill(meizlchengyan)
extension:insertRelatedSkills("meizlrangdou", "#meizlrangdoumaxcard")
extension:insertRelatedSkills("meizlchengyan", "#meizlchengyandistance")

sgs.LoadTranslationTable {
	["meizlzhugeguo"] = "诸葛果",
	["#meizlzhugeguo"] = "羽化升天",
	["illustrator:meizlzhugeguo"] = "大戦乱!!三国志バトル",
	["designer:meizlzhugeguo"] = "Mark1469",
	["meizlrangdou"] = "禳斗",
	["@meizlrangdou"] = "禳斗",
	["meizlrangdoucard"] = "禳斗",
	[":meizlrangdou"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张基本牌，然后获得或取消以下效果：你的手牌上限为0；你造成的伤害-1；你受到的伤害-1。",
	["meizlchengyan"] = "乘烟",
	["#Meizlchengyan"] = "%from的技能【%arg2】触发，其他角色与其距离+%arg，至其下个回合开始时。",
	[":meizlchengyan"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你于弃牌阶段弃置一张牌，其他角色与你的距离便+1，直至你的下个回合开始时。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 028 董白
meizldongbai = sgs.General(extension, "meizldongbai", "qun", 3, false)
--奢华（董白）
meizlshehuaskill = sgs.CreateTargetModSkill {
	name = "#meizlshehuaskill",
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}
meizlshehua = sgs.CreateViewAsSkill {
	name = "meizlshehua",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
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
		newanal:deleteLater()
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:usedTimes("Analeptic") <=
			sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}
--血殇（董白）
meizlxueshang = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_Compulsory,
		name = "meizlxueshang",
		events = { sgs.HpChanged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local allplayers = room:findPlayersBySkillName(self:objectName())
			for _, splayer in sgs.qlist(allplayers) do
				if (splayer:getPhase() ~= sgs.Player_Play) or (splayer:objectName() == player:objectName()) then continue end
				if player:getHp() <= 1 then
					room:killPlayer(player, nil)
				end
			end
		end,
		can_trigger = function(self, player)
			return true
		end
	}
--魔嗣（董白）
meizlmosicard = sgs.CreateSkillCard {
	name = "meizlmosicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlmosi")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		local card_use = sgs.CardUseStruct()
		card_use.from = source
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:canSlash(p, nil, false) then
				card_use.to:append(p)
			end
		end
		card_use.card = slash
		room:useCard(card_use, true)
		slash:deleteLater()
	end
}
meizlmosiskill = sgs.CreateViewAsSkill {
	name = "meizlmosi",
	n = 0,
	view_as = function(self, cards)
		return meizlmosicard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlmosi") > 0 and sgs.Slash_IsAvailable(player)
	end
}
meizlmosi = sgs.CreateTriggerSkill {
	name = "meizlmosi",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlmosiskill,
	events = {},
	limit_mark = "@meizlmosi",
	on_trigger = function(self, event, player, data)
	end
}

meizldongbai:addSkill(meizlshehua)
meizldongbai:addSkill(meizlshehuaskill)
meizldongbai:addSkill(meizlxueshang)
meizldongbai:addSkill(meizlmosi)
extension:insertRelatedSkills("meizlshehua", "#meizlshehuaskill")
sgs.LoadTranslationTable {
	["meizldongbai"] = "董白",
	["#meizldongbai"] = "魔姬",
	["illustrator:meizldongbai"] = "三国轮舞曲",
	["designer:meizldongbai"] = "Mark1469",
	["meizlshehua"] = "奢华",
	[":meizlshehua"] = "你可以将一张装备牌当【酒】使用；你于出牌阶段内使用【酒】无数量限制。",
	["meizlxueshang"] = "血殇",
	[":meizlxueshang"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段，当其他角色体力值扣减至1或更低后，该角色阵亡。",
	["meizlmosi"] = "魔嗣",
	["@meizlmosi"] = "魔嗣",
	["meizlmosicard"] = "魔嗣",
	[":meizlmosi"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以视为对所有其他角色使用了一张【杀】。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 029 丁夫人
meizldingfuren = sgs.General(extension, "meizldingfuren", "wei", 3, false)
--欲绝（丁夫人）
meizlyujuecard = sgs.CreateSkillCard {
	name = "meizlyujuecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canDiscard(to_select, "he")
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(source, targets[1], "he", "meizlyujue")
		room:throwCard(card_id, targets[1], source)
		if source:canDiscard(targets[1], "he") then
			local card_id = room:askForCardChosen(source, targets[1], "he", "meizlyujue")
			room:throwCard(card_id, targets[1], source)
		end
		local damage = sgs.DamageStruct()
		damage.from = targets[1]
		damage.to = source
		room:damage(damage)
	end,
}

meizlyujue = sgs.CreateViewAsSkill {
	name = "meizlyujue",
	n = 0,
	view_as = function(self, cards)
		return meizlyujuecard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlyujuecard")
	end
}
--哭骂（丁夫人）
meizlkuma = sgs.CreateTriggerSkill
	{
		name = "meizlkuma",
		events = { sgs.Damaged },
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from and not damage.from:isNude() then
				if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
				local prompt = string.format("@meizlkuma-move:%s", player:objectName())
				local card = room:askForExchange(damage.from, self:objectName(), 1, 1, true, prompt)
				player:obtainCard(card)
				local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				slash:setSkillName(self:objectName())
				slash:addSubcard(card)
				local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(damage.from)
				use.card = slash
				room:useCard(use, false)
				slash:deleteLater()
			end
		end
	}
--离异（丁夫人）
meizlliyi = sgs.CreateTriggerSkill {
	name = "meizlliyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		local targets
		if not death.who:hasSkill(self:objectName()) then return end
		if not player:objectName() == death.who:objectName() then return end
		if death.damage.from then
			room:handleAcquireDetachSkills(death.damage.from, "meizlkuijiu")
		end
	end
}
--愧疚（丁夫人）
meizlkuijiu = sgs.CreateFilterSkill {
	name = "meizlkuijiu",
	view_filter = function(self, card)
		return card:objectName() == "jink"
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlkuijiu") then skills:append(meizlkuijiu) end
sgs.Sanguosha:addSkills(skills)
meizldingfuren:addSkill(meizlkuma)
meizldingfuren:addSkill(meizlyujue)
meizldingfuren:addSkill(meizlliyi)
sgs.LoadTranslationTable {
	["meizldingfuren"] = "丁夫人",
	["#meizldingfuren"] = "魏王太后",
	["illustrator:meizldingfuren"] = "",
	["designer:meizldingfuren"] = "Mark1469",
	["meizlkuma"] = "哭骂",
	["@meizlkuma-move"] = "%src发动了技能【哭骂】，你须交给%src一张牌。",
	[":meizlkuma"] = "每当你受到一次伤害后，你可以令伤害来源交给你一张牌，然后将该牌当【杀】对其使用（不​​计入出牌阶段内的使用次数限制）。",
	["meizlyujue"] = "欲绝",
	["meizlyujuecard"] = "欲绝",
	[":meizlyujue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一名其他角色至多两张牌，然后受到该角色造成的1点伤害。",
	["meizlliyi"] = "离异",
	[":meizlliyi"] = "<font color=\"blue\"><b>锁定技，</b></font>当你死亡时，杀死你的角色获得技能“愧疚”（<font color=\"blue\"><b>锁定技，</b></font>你的【闪】均视为【杀】）。",
	["meizlkuijiu"] = "愧疚",
	[":meizlkuijiu"] = "<font color=\"blue\"><b>锁定技，</b></font>你的【闪】均视为【杀】。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 030 辛宪英
meizlxinxianying = sgs.General(extension, "meizlxinxianying", "wei", 3, false)
--才鉴（辛宪英）
meizlcaijian = sgs.CreateTriggerSkill {
	name = "meizlcaijian",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num + 2
			data:setValue(draw)
			room:sendCompulsoryTriggerLog(player, self:objectName())
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
			room:askForDiscard(player, self:objectName(), 2, 2, false, true)
		end
	end
}
--隐智（辛宪英）
meizlyinzhicard = sgs.CreateSkillCard {
	name = "meizlyinzhicard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = self:getSubcards()
		for _, id in sgs.qlist(ids) do
			source:addToPile("meizlyinzhi", id, false)
		end
	end
}
meizlyinzhiskill = sgs.CreateViewAsSkill {
	name = "meizlyinzhi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlyinzhicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlyinzhi"
	end
}
meizlyinzhi = sgs.CreateTriggerSkill {
	name = "meizlyinzhi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd, sgs.Damaged, sgs.EventPhaseStart },
	view_as_skill = meizlyinzhiskill,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local card_id
				for _, p in sgs.qlist(player:getPile("meizlyinzhi")) do
					room:obtainCard(player, sgs.Sanguosha:getCard(p))
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				if not player:isKongcheng() then
					room:askForUseCard(player, "@@meizlyinzhi", "@meizlyinzhi")
				end
			end
		elseif event == sgs.Damaged then
			local dam = data:toDamage()
			local zhi = player:getPile("meizlyinzhi")
			if zhi:length() == 0 then return end
			if not player:askForSkillInvoke(self:objectName(), data) then return end
			local card_id
			for _, p in sgs.qlist(zhi) do
				card_id = p
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
			local card = sgs.Sanguosha:getCard(card_id)
			room:throwCard(card, reason, nil)
			if card:isKindOf("BasicCard") then
				player:drawCards(3)
			elseif card:isKindOf("TrickCard") then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				if dam.from ~= nil and dam.from:isAlive() and player:canDiscard(dam.from, "he") then
					local disc = room:askForCardChosen(player, dam.from, "he", self:objectName())
					room:throwCard(disc, dam.from, player)
				end
			elseif card:isKindOf("EquipCard") then
				if dam.from ~= nil then
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = dam.from
					room:damage(damage)
				end
				local newcard = room:drawCard()
				local newcd = sgs.Sanguosha:getCard(newcard)
				player:addToPile("meizlyinzhi", newcd, false)
			end
		end
	end
}


meizlxinxianying:addSkill(meizlcaijian)
meizlxinxianying:addSkill(meizlyinzhi)
sgs.LoadTranslationTable {
	["meizlxinxianying"] = "辛宪英",
	["#meizlxinxianying"] = "乱世才女",
	["designer:meizlxinxianying"] = "Mark1469",
	["illustrator:meizlxinxianying"] = "大戦乱!!三国志バトル",
	["meizlcaijian"] = "才鉴",
	[":meizlcaijian"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段摸牌时，你额外摸两张牌；摸牌阶段结束时，你弃置两张牌。",
	["@meizlyinzhi"] = "你可以发动技能【隐智】",
	["meizlyinzhicard"] = "隐智",
	["meizlyinzhi"] = "隐智",
	["~meizlyinzhi"] = "选择一张手牌→点击确定",
	[":meizlyinzhi"] = "出牌阶段结束时，你可以将一张手牌背面朝下置于你的武将牌上。每当你受到一次伤害后，若你的武将牌上有牌，你可以弃置之，并根据此牌的类型执行以下效果。基本牌：摸三张牌；锦囊牌：回复1点体力并弃置伤害来源的一张牌；装备牌：对伤害来源造成1点伤害并将牌堆顶的一张牌背面朝下置于你的武将牌上。回合开始时，你获得你武将牌上的牌。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 031 孙茹
meizlsunru = sgs.General(extension, "meizlsunru", "wu", 3, false)
--抚内（孙茹）
meizlfunei = sgs.CreateTriggerSkill {
	name = "meizlfunei",
	events = { sgs.EventPhaseStart },

	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
		if player:getPhase() ~= sgs.Player_Start then return end
		for _, splayer in sgs.qlist(allplayers) do
			if splayer:askForSkillInvoke(self:objectName()) then
				room:loseHp(splayer, 1)
				player:drawCards(2)
				room:attachSkillToPlayer(player, "meizlfuneix")
				room:addPlayerMark(player, "&meizlfunei+to+#" .. splayer:objectName() .. "+-Clear")
			end
		end
	end,
}

meizlfuneix = sgs.CreateTargetModSkill {
	name = "meizlfuneix",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end
}

meizlfuneiskill = sgs.CreateTriggerSkill {
	name = "#meizlfuneiskill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventLoseSkill, sgs.Death, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlfunei" then
				return false
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_NotActive then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:detachSkillFromPlayer(p, "meizlfuneix")
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
--娇娆（孙茹）
meizljiaoraocard = sgs.CreateSkillCard {
	name = "meizljiaoraocard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local x = self:subcardsLength()
			local choice = room:askForChoice(source, "meizljiaorao", "d1tx+dxt1")
			if choice == "d1tx" then
				targets[1]:drawCards(1)
				if targets[1]:getHandcardNum() + targets[1]:getEquips():length() > x then
					room:askForDiscard(targets[1], "meizljiaorao", x, x, false, true)
				else
					targets[1]:throwAllCards()
				end
			else
				targets[1]:drawCards(x)
				if targets[1]:getHandcardNum() + targets[1]:getEquips():length() > 1 then
					room:askForDiscard(targets[1], "meizljiaorao", 1, 1, false, true)
				else
					targets[1]:throwAllCards()
				end
			end
		end
	end
}
meizljiaorao = sgs.CreateViewAsSkill {
	name = "meizljiaorao",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local meizljiaoraocard = meizljiaoraocard:clone()
			for _, card in pairs(cards) do
				meizljiaoraocard:addSubcard(card)
			end
			meizljiaoraocard:setSkillName(self:objectName())
			return meizljiaoraocard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlfuneix") then skills:append(meizlfuneix) end
sgs.Sanguosha:addSkills(skills)
meizlsunru:addSkill(meizljiaorao)
meizlsunru:addSkill(meizlfunei)
meizlsunru:addSkill(meizlfuneiskill)
extension:insertRelatedSkills("meizlfunei", "#meizlfuneiskill")
sgs.LoadTranslationTable {
	["meizlsunru"] = "孙茹",
	["#meizlsunru"] = "玲珑之花",
	["designer:meizlsunru"] = "Mark1469",
	["illustrator:meizlsunru"] = "大戦乱!!三国志バトル",
	["meizljiaorao"] = "娇娆",
	["meizljiaoraocard"] = "娇娆",
	["meizljiaorao:d1tx"] = "摸一张牌，然后弃置等量的牌",
	["meizljiaorao:dxt1"] = "摸等量的牌，然后弃置一张牌",
	[":meizljiaorao"] = "出牌阶段，你可以弃置任意数量的牌，然后选择一名角色并选择一项：1.令其摸一张牌，然后弃置等量的牌；2.令其摸等量的牌，然后弃置一张牌。",
	["meizlfunei"] = "抚内",
	[":meizlfunei"] = "一名角色的回合开始时，你可以失去1点体力，然后该角色摸两张牌并可以使用任意数量的【杀】，直到回合结束。",
	["meizlfuneix"] = "抚内效果",
	[":meizlfuneix"] = "你可以使用任意数量的【杀】，直到回合结束。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 032 樊氏
meizlfanshi = sgs.General(extension, "meizlfanshi", "qun", 3, false)
--绝色（樊氏）
meizljuese = sgs.CreateTriggerSkill {
	name = "meizljuese",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			while player:askForSkillInvoke(self:objectName()) do
				player:drawCards(2)
				room:askForDiscard(player, self:objectName(), 1, 1, false, false)
				local x = math.random(1, 10)
				if x > 4 then
					break
				end
			end
		end
	end
}
--择夫（樊氏）
meizlzefu = sgs.CreateViewAsSkill
	{
		name = "meizlzefu",
		n = 0,

		view_as = function(self, cards)
			return meizlzefucard:clone()
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#meizlzefucard")
		end,
	}

meizlzefucard = sgs.CreateSkillCard
	{
		name = "meizlzefucard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select)
			if #targets == 0 then
				return to_select:getHandcardNum() >= sgs.Self:getHandcardNum() and to_select:getHp() >= sgs.Self:getHp() and
					to_select:getAttackRange() >= sgs.Self:getAttackRange()
			end
		end,

		on_use = function(self, room, source, targets)
			targets[1]:drawCards(2)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	}


meizlfanshi:addSkill(meizlzefu)
meizlfanshi:addSkill(meizljuese)
sgs.LoadTranslationTable {
	["meizlfanshi"] = "樊氏",
	["#meizlfanshi"] = "赵氏寡孀",
	["designer:meizlfanshi"] = "Mark1469",
	["illustrator:meizlfanshi"] = "大戦乱!!三国志バトル",
	["meizlzefu"] = "择夫",
	["meizlzefucard"] = "择夫",
	[":meizlzefu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名手牌数、体力值和攻击范围均不小于你的角色，该角色摸两张牌，然后你回复1点体力。",
	["meizljuese"] = "绝色",
	[":meizljuese"] = "每当你受到一次伤害后，你可以摸两张牌并弃置一张手牌，然后你有40%机率可以重覆此流程。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZL 033 严氏
meizlyanshi = sgs.General(extension, "meizlyanshi", "qun", 3, false)
--哭诉（严氏）
meizlkusu = sgs.CreateTriggerSkill {
	name = "meizlkusu",
	events = { sgs.Damaged },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from then
			local dest = sgs.QVariant()
			dest:setValue(damage.from)
			if damage.from:isKongcheng() or not room:askForSkillInvoke(player, self:objectName(), dest) then return false end
			local ids = damage.from:handCards()
			room:fillAG(ids, player)
			local card_id = room:askForAG(player, ids, true, "meizlkusu")
			local cardchose = sgs.Sanguosha:getCard(card_id)
			room:obtainCard(player, cardchose)
			room:clearAG()
			room:askForUseCard(player, "TrickCard+^Nullification|.|.|hand", "@meizlkusu")
		end
	end
}
--持家（严氏）
meizlchijia = sgs.CreateTriggerSkill {
	name = "meizlchijia",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TrickCardCanceling, sgs.TargetConfirmed },
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.from:isAlive() then
				return true
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.card:getTypeId() == sgs.Card_TypeTrick) then
				if use.from and player:isAlive() and player:hasSkill(self:objectName()) and player:objectName() == use.from:objectName() then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(use.to) do
						if player:canDiscard(p, "he") and p:objectName() ~= use.from:objectName() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						local target = room:askForPlayerChosen(player, targets, self:objectName(), "meizlchijiachoose",
							true)
						if target then
							local card_id = room:askForCardChosen(player, target, "he", self:objectName())
							room:throwCard(card_id, target, player)
						end
					end
				end
			end
		end
	end
}

meizlyanshi:addSkill(meizlkusu)
meizlyanshi:addSkill(meizlchijia)

sgs.LoadTranslationTable {
	["meizlyanshi"] = "严氏",
	["#meizlyanshi"] = "飞将之妻",
	["designer:meizlyanshi"] = "Mark1469",
	["illustrator:meizlyanshi"] = "霸三国OL",
	["meizlkusu"] = "哭诉",
	["@meizlkusu"] = "你可以使用一张锦囊牌",
	[":meizlkusu"] = "每当你受到一次伤害后，你可以观看伤害来源的手牌并获得其中一张，然后你可以使用一张锦囊牌。",
	["meizlchijia"] = "持家",
	["meizlchijiachoose"] = "你可以发动【持家】，弃置其中一名目标角色的一张牌；或按取消。",
	[":meizlchijia"] = "你使用的非延时类锦囊牌不能被【无懈可击】响应；每当你使用锦囊牌选择目标后，你可以弃置其中一名其他目标角色的一张牌。",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 001 神孙尚香
meizlshensunshangxiang = sgs.General(extension, "meizlshensunshangxiang", "god", 3, false)
--梦缘（神孙尚香）
meizlmengyuan = sgs.CreateTriggerSkill
	{
		name = "meizlmengyuan",
		events = { sgs.MaxHpChanged },
		priority = 2,
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local splayer = room:findPlayerBySkillName(self:objectName())
			local dest = sgs.QVariant()
			dest:setValue(player)
			if splayer:faceUp() and room:askForSkillInvoke(splayer, self:objectName(), dest) then
				room:doLightbox("$meizlmengyuananimate", 1000)
				local log = sgs.LogMessage()
				log.from = splayer
				log.type = "#Meizlmengyuan"
				log.arg = self:objectName()
				log.to:append(player)
				room:sendLog(log)
				splayer:turnOver()
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
			end
		end,
		can_trigger = function(self, target)
			return true
		end
	}
--巾帼（神孙尚香）
meizljinguo = sgs.CreateTriggerSkill {
	name = "meizljinguo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		
		if player:getEquips():length() > 0 then
			room:doLightbox("$meizljinguoanimate", 1000)
		end
		draw.num = draw.num + player:getEquips():length()
		data:setValue(draw)
	end
}
--尚武（神孙尚香）
meizlshangwu = sgs.CreateTriggerSkill {
	name = "meizlshangwu",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart, sgs.Damage },
	waked_skills = "xiaoji,ganlu,xuanfeng",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlshangwu_canWake1") > 0 and player:getMark("meizlshangwu1") == 0 then
				room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
				player:addMark("meizlshangwu1")
				room:doLightbox("$meizlshangwuanimate", 1000)
				room:handleAcquireDetachSkills(player, "xiaoji")
			end
			if player:getMark("meizlshangwu_canWake2") > 0 and player:getMark("meizlshangwu2") == 0 then
				player:addMark("meizlshangwu2")
				room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
				room:doLightbox("$meizlshangwuanimate", 1000)
				room:handleAcquireDetachSkills(player, "ganlu")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal and player:getMark("meizlshangwu3") == 0 then
				room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
				player:addMark("meizlshangwu3")
				room:loseHp(player, 1)
				room:doLightbox("$meizlshangwuanimate", 1000)
				room:handleAcquireDetachSkills(player, "xuanfeng")
			end
		end
		if player:getMark("meizlshangwu1") > 0 and player:getMark("meizlshangwu2") > 0 and player:getMark("meizlshangwu3") > 0 then
			player:addMark("meizlshangwu")
		end
	end,
	can_wake = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) then
			if player:canWake(self:objectName()) then
				room:addPlayerMark(player, "meizlshangwu_canWake1")
				room:addPlayerMark(player, "meizlshangwu_canWake2")
				return true
			end
			if (player:getHp() == 2 and player:getMark("meizlshangwu1") == 0) or (player:getHp() == 1 and player:getMark("meizlshangwu2") == 0) then
				if player:getHp() == 2 and player:getMark("meizlshangwu1") == 0 then
					room:addPlayerMark(player, "meizlshangwu_canWake1")
				end
				if player:getHp() == 1 and player:getMark("meizlshangwu2") == 0 then
					room:addPlayerMark(player, "meizlshangwu_canWake2")
				end
				return true
			end
		elseif event == sgs.Damage then
			return true
		end
		return false
	end,
}

meizlshensunshangxiang:addSkill(meizlmengyuan)
meizlshensunshangxiang:addSkill(meizlshangwu)
meizlshensunshangxiang:addSkill(meizljinguo)
sgs.LoadTranslationTable {
	["meizlshensunshangxiang"] = "神孙尚香",
	["#meizlshensunshangxiang"] = "江东郡主",
	["designer:meizlshensunshangxiang"] = "Mark1469",
	["illustrator:meizlshensunshangxiang"] = "三国志大战",
	["illustrator:meizlshensunshangxiang_1"] = "大戦乱!!三国志バトル",
	["meizlmengyuan"] = "梦缘",
	["$meizlmengyuananimate"] = "image=image/animate/meizlmengyuan.png",
	["#Meizlmengyuan"] = "%from发动了技能【%arg】，%to增加1点体力上限。",
	[":meizlmengyuan"] = "当一名角色体力上限产生变化，若你的武将牌正面朝上，你可以将你的武将牌翻面，然后该角色增加1点体力上限。",
	["meizlshangwu"] = "尚武",
	["$meizlshangwuanimate"] = "image=image/animate/meizlshangwu.png",
	[":meizlshangwu"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若你的体力为2，你须减1点体力上限，并获得技能“枭姬”； 若你的体力为1，你须减1点体力上限，并获得技能“甘露”。当你造成一次属性伤害后，你须失去1点体力，并获得技能“旋风”。",
	["meizljinguo"] = "巾帼",
	["$meizljinguoanimate"] = "image=image/animate/meizljinguo.png",
	[":meizljinguo"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段，你额外摸X张牌（X为你装备区的牌数量）。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 002 神貂蝉
meizlshendiaochan = sgs.General(extension, "meizlshendiaochan", "god", 3, false)
--落红（神貂蝉）
meizlluohongcard = sgs.CreateSkillCard
	{
		name = "meizlluohongcard",
		target_fixed = true,
		will_throw = true,

		on_use = function(self, room, source, targets)
			if (source:isAlive()) then
				room:doLightbox("$meizlluohonganimate", 1000)
				local x = 0
				while (self:subcardsLength() > x) do
					local card_id = room:drawCard()
					local card = sgs.Sanguosha:getCard(card_id)
					room:getThread():delay(500)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(),
						"meizlluohong", "")
					room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
					if card:isRed() then
						source:obtainCard(card)
						x = x + 1
					end
				end
			end
		end,
	}

meizlluohong = sgs.CreateViewAsSkill
	{
		name = "meizlluohong",
		n = 998,

		view_filter = function(self, selected, to_select)
			return to_select:isBlack()
		end,

		view_as = function(self, cards)
			if #cards > 0 then
				local new_card = meizlluohongcard:clone()
				local i = 0
				while (i < #cards) do
					i = i + 1
					local card = cards[i]
					new_card:addSubcard(card:getId())
				end
				new_card:setSkillName("luohong")
				return new_card
			else
				return nil
			end
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#meizlluohongcard")
		end
	}
--曼舞（神貂蝉）
meizlmanwu = sgs.CreateTriggerSkill {
	name = "meizlmanwu",
	events = { sgs.EventPhaseStart },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
			local pattern = ".|red|.|hand"
			local card = room:askForCard(player, pattern, "@meizlmanwu", sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				local log = sgs.LogMessage()
				log.type = "#InvokeSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				room:doLightbox("$meizlmanwuanimate", 1000)
				player:addToPile("meizlmanwu", card)
				if player:getPile("meizlmanwu"):length() >= 3 then
					player:removePileByName("meizlmanwu")
					local victims = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:isMale() then
							victims:append(p)
						end
					end
					if victims:isEmpty() then return end
					local victim = room:askForPlayerChosen(player, victims, self:objectName())
					victim:throwAllHandCardsAndEquips()
				end
			end
		end
	end,
}
--诱魄（神貂蝉）
meizlyoupo = sgs.CreateTriggerSkill {
	name = "meizlyoupo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart,
		sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local meizlyoupo_skills = player:getTag("meizlyouposkills"):toString():split("+")
				for _, skill_name in ipairs(meizlyoupo_skills) do
					room:detachSkillFromPlayer(player, skill_name)
				end
				player:setTag("meizlyouposkills", sgs.QVariant())
			end
			return false
		end
		if player:isAlive() and player:hasSkill(self:objectName()) then
			meizlyoupohpchange(room, player, 2, "lijian")
			meizlyoupocardchange(room, player, 2, "lihun")
			meizlyoupopilechange(room, player, 2, "meizllipo")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

meizlyoupohpchange = function(room, player, hp, skill_name)
	local room = player:getRoom()
	local meizlyoupo_skills = player:getTag("meizlyouposkills"):toString():split("+")
	if player:getHp() <= hp then
		if not table.contains(meizlyoupo_skills, skill_name) then
			room:handleAcquireDetachSkills(player, skill_name)
			table.insert(meizlyoupo_skills, skill_name)
		end
	else
		room:detachSkillFromPlayer(player, skill_name)
		for i = 1, #meizlyoupo_skills, 1 do
			if meizlyoupo_skills[i] == skill_name then
				table.remove(meizlyoupo_skills, i)
			end
		end
	end
	player:setTag("meizlyouposkills", sgs.QVariant(table.concat(meizlyoupo_skills, "+")))
end

meizlyoupocardchange = function(room, player, cardnum, skill_name)
	local room = player:getRoom()
	local meizlyoupo_skills = player:getTag("meizlyouposkills"):toString():split("+")
	if player:getHandcardNum() <= cardnum then
		if not table.contains(meizlyoupo_skills, skill_name) then
			room:handleAcquireDetachSkills(player, skill_name)
			table.insert(meizlyoupo_skills, skill_name)
		end
	else
		room:detachSkillFromPlayer(player, skill_name)
		for i = 1, #meizlyoupo_skills, 1 do
			if meizlyoupo_skills[i] == skill_name then
				table.remove(meizlyoupo_skills, i)
			end
		end
	end
	player:setTag("meizlyouposkills", sgs.QVariant(table.concat(meizlyoupo_skills, "+")))
end

meizlyoupopilechange = function(room, player, pile, skill_name)
	local room = player:getRoom()
	local meizlyoupo_skills = player:getTag("meizlyouposkills"):toString():split("+")
	if player:getPile("meizlmanwu"):length() == pile then
		if not table.contains(meizlyoupo_skills, skill_name) then
			room:handleAcquireDetachSkills(player, skill_name)
			table.insert(meizlyoupo_skills, skill_name)
		end
	else
		room:detachSkillFromPlayer(player, skill_name)
		for i = 1, #meizlyoupo_skills, 1 do
			if meizlyoupo_skills[i] == skill_name then
				table.remove(meizlyoupo_skills, i)
			end
		end
	end
	player:setTag("meizlyouposkills", sgs.QVariant(table.concat(meizlyoupo_skills, "+")))
end

meizlshendiaochan:addSkill(meizlluohong)
meizlshendiaochan:addSkill(meizlmanwu)
meizlshendiaochan:addSkill(meizlyoupo)
meizlshendiaochan:addRelateSkill("meizllipo")
meizlshendiaochan:addRelateSkill("lihun")
meizlshendiaochan:addRelateSkill("lijian")

sgs.LoadTranslationTable {
	["meizlshendiaochan"] = "神貂蝉",
	["#meizlshendiaochan"] = "醉心的天仙",
	["designer:meizlshendiaochan"] = "Mark1469",
	["illustrator:meizlshendiaochan"] = "真三国无双7",
	["illustrator:meizlshendiaochan_1"] = "天空のクリスタリア",
	["meizlluohong"] = "落红",
	["$meizlluohonganimate"] = "image=image/animate/meizlluohong.png",
	["meizlluohongcard"] = "落红",
	[":meizlluohong"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置任意数量的黑色牌，然后从牌堆顶亮出一张牌并置于弃牌堆，若为红色，你获得之，你重复此流程，直到获得等量的牌为止。",
	["$meizlmanwuanimate"] = "image=image/animate/meizlmanwu.png",
	["meizlmanwu"] = "曼舞",
	["@meizlmanwu"] = "你可以发动技能“曼舞”",
	[":meizlmanwu"] = "弃牌阶段开始时，你可以将一张红色手牌置于武将牌上，若此时你武将牌上的牌达到三张，你弃置之并选择一名男性角色，弃置其所有牌。",
	["meizlyoupo"] = "诱魄",
	[":meizlyoupo"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的体力值为2或更少，你视为拥有技能“​​离间”;若你的手牌数为2或更少，你视为拥有技能“​​离魂”;若你武将牌上的牌达到两张，你视为拥有技能“​​离魄”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 003 神甄姬
meizlshenzhenji = sgs.General(extension, "meizlshenzhenji", "god", 3, false)
--惊鸿（神甄姬）
meizljinghong = sgs.CreateTriggerSkill {
	name = "meizljinghong",
	events = { sgs.DamageInflicted, sgs.EventPhaseStart },
	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from then
				if splayer and splayer:isAlive() and splayer:objectName() == damage.to:objectName() and splayer:objectName() ~= damage.from:objectName() then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.who = splayer
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						if not splayer:isKongcheng() then
							if room:askForDiscard(splayer, self:objectName(), 1, 1, true, false, "meizljinghong-invoke") then
								room:doLightbox("$meizljinghonganimate", 1000)
								local log = sgs.LogMessage()
								log.type = "#Meizljinghong"
								log.from = splayer
								log.to:append(damage.from)
								log.arg = self:objectName()
								room:sendLog(log)
								room:setPlayerMark(damage.from, "@meizljinghong", 1)
								return true
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if current:getMark("@meizljinghong") > 0 and splayer and splayer:isAlive() then
				splayer:gainAnExtraTurn()
				current:skip(sgs.Player_Start)
				current:skip(sgs.Player_Judge)
				current:skip(sgs.Player_Draw)
				current:skip(sgs.Player_Play)
				current:skip(sgs.Player_Discard)
				current:skip(sgs.Player_Finish)
				room:setPlayerMark(current, "@meizljinghong", 0)
			end
		end
	end,
}
--玉殒（神甄姬）
meizlyuyuncard = sgs.CreateSkillCard {
	name = "meizlyuyuncard",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		room:doLightbox("$meizlyuyunanimate", 1000)
		local recover = sgs.RecoverStruct()
		recover.recover = source:getMaxHp() - source:getHp()
		recover.who = source
		room:recover(source, recover)
	end
}
meizlyuyunskill = sgs.CreateViewAsSkill {
	name = "meizlyuyun",
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
			local meizlyuyuncard = meizlyuyuncard:clone()
			meizlyuyuncard:addSubcard(cards[1])
			meizlyuyuncard:addSubcard(cards[2])
			return meizlyuyuncard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlyuyun"
	end
}

meizlyuyun = sgs.CreateTriggerSkill {
	name = "meizlyuyun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying, sgs.AskForPeaches },
	view_as_skill = meizlyuyunskill,
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local room = dying.who:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if event == sgs.Dying then
			if dying.who:objectName() == splayer:objectName() then
				if room:askForSkillInvoke(player, "meizlyuyundying", data) then
					local x = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if splayer:distanceTo(p) <= 1 then
							x = x + 1
						end
					end
					room:doLightbox("$meizlyuyunanimate", 1000)
					splayer:drawCards(x)
				end
			end
		elseif event == sgs.AskForPeaches then
			if dying.who:objectName() == splayer:objectName() and dying.who:getHandcardNum() >= 2 then
				room:askForUseCard(player, "@@meizlyuyun", "@meizlyuyun-card")
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end
}

meizlshenzhenji:addSkill(meizljinghong)
meizlshenzhenji:addSkill(meizlyuyun)
sgs.LoadTranslationTable {
	["meizlshenzhenji"] = "神甄姬",
	["#meizlshenzhenji"] = "洛水之神",
	["designer:meizlshenzhenji"] = "Mark1469",
	["illustrator:meizlshenzhenji"] = "Gseoning",
	["illustrator:meizlshenzhenji_1"] = "Aoin",
	["meizljinghong"] = "惊鸿",
	["meizljinghong-invoke"] = "你可以弃置一张手牌，發動技能“惊鸿”",
	["$meizljinghonganimate"] = "image=image/animate/meizljinghong.png",
	["#Meizljinghong"] = "%from发动了技能【%arg】，防止了%to造成的伤害并代替%to执行其下一个回合。",
	[":meizljinghong"] = "每当你受到其他角色对你造成的伤害时，你进行一次判定，若判定结果为黑色，你可以弃置一张手牌，然后防止此伤害并代替该角色执行其下一个回合。",
	["meizlyuyun"] = "玉殒",
	["meizlyuyuncard"] = "玉殒",
	["~meizlyuyun"] = "选择两张花色相同的手牌→点击确定",
	["@meizlyuyun-card"] = "玉殒 ②（处于濒死状态时）",
	["$meizlyuyunanimate"] = "image=image/animate/meizlyuyun.png",
	["meizlyuyundying"] = "玉殒 ①（进入濒死状态时）",
	["meizlyuyunaskforpeaches"] = "玉殒 ②（处于濒死状态时）",
	[":meizlyuyun"] = "当你进入濒死状态时，你可以摸X张牌（X为你距离1以内的存活角色数）；当你处于濒死状态时，你可以弃置两张花色相同的手牌，然后将体力值回复至体力上限。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 004 神关银屏
meizlshenguanyinping = sgs.General(extension, "meizlshenguanyinping", "god", 3, false)
--虎魂（神关银屏）
meizlhuhuncard = sgs.CreateSkillCard {
	name = "meizlhuhuncard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:objectName() ~= sgs.Self:objectName() then
			return sgs.Self:distanceTo(to_select) == 1
		end
	end,
	on_use = function(self, room, source, targets)
		while source:askForSkillInvoke("meizlhuhun") and source:canSlash(targets[1], nil, false) do
			room:doLightbox("$meizlhuhunanimate", 1000)
			room:setPlayerMark(source, "meizlhuhunslash", 0)
			room:setPlayerMark(source, "meizlhuhunFail", 0)
			local card_id = room:drawCard()
			local card = sgs.Sanguosha:getCard(card_id)
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:setSkillName("meizlhuhun")
			slash:addSubcard(card)
			slash:deleteLater()
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(targets[1])
			use.card = slash
			room:useCard(use, false)
			if (source:getMark("meizlhuhunslash") == 0) or (not targets[1]:isAlive()) or (source:getMark("meizlhuhunFail") == 1) then
				break
			end
		end
	end
}
meizlhuhunskill = sgs.CreateViewAsSkill {
	name = "meizlhuhun",
	n = 0,
	view_as = function(self, cards)
		return meizlhuhuncard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlhuhun"
	end
}

meizlhuhun = sgs.CreateTriggerSkill {
	name = "meizlhuhun",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlhuhunskill,
	events = { sgs.EventPhaseStart, sgs.Damage, sgs.QuitDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) then
			if room:askForUseCard(player, "@@meizlhuhun", "@meizlhuhun-draw") then
				return true
			end
		elseif event == sgs.Damage and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") then
					if card:getSkillName() == self:objectName() then
						room:setPlayerMark(player, "meizlhuhunslash", 1)
					end
				end
			end
		elseif event == sgs.QuitDying then
			local dying = data:toDying()
			if dying.damage and dying.damage.card and dying.damage.card:getSkillName() == "meizlhuhun" and not dying.damage.chain and not dying.damage.transfer then
				local from = dying.damage.from
				if from and from:isAlive() then
					room:setPlayerMark(from, "meizlhuhunFail", 1)
					room:loseHp(from, 1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--雪雠（神关银屏）
meizlxuechou = sgs.CreateTriggerSkill {
	name = "meizlxuechou",
	events = { sgs.Death },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:isKongcheng() then return end
		if player:objectName() == death.who:objectName() then return end
		if not player:askForSkillInvoke(self:objectName()) then return end
		room:doLightbox("$meizlxuechouanimate", 1000)
		local current = room:getCurrent()
		local idlistA = sgs.IntList()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		for _, card in sgs.qlist(death.who:getHandcards()) do
			idlistA:append(card:getId())
			slash:addSubcard(card)
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = idlistA
		move.to = player
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, false)
		if current and current:isAlive() and player:canSlash(current, nil, false) then
			local use = sgs.CardUseStruct()
			use.from = player
			use.to:append(current)
			use.card = slash
			room:useCard(use, false)
		end
	end
}

meizlshenguanyinping:addSkill(meizlhuhun)
meizlshenguanyinping:addSkill(meizlxuechou)
sgs.LoadTranslationTable {
	["meizlshenguanyinping"] = "神关银屏",
	["#meizlshenguanyinping"] = "艳丽的武姬",
	["designer:meizlshenguanyinping"] = "Mark1469",
	["illustrator:meizlshenguanyinping"] = "碧风羽（真三国无双7）",
	["illustrator:meizlshenguanyinping_1"] = "真三国輪舞曲",
	["meizlhuhun"] = "虎魂",
	["$meizlhuhunanimate"] = "image=image/animate/meizlhuhun.png",
	["meizlhuhuncard"] = "虎魂",
	["~meizlhuhun"] = "选择一名其他角色→点击确定",
	["@meizlhuhun-draw"] = "请选择“虎魂”的目标",
	[":meizlhuhun"] = "摸牌阶段开始时，你可以选择距离1以内的一名其他角色并放弃摸牌，改为从牌堆顶亮出一张牌，然后将此牌当作【杀】对该角色使用，若以此法使用的【杀】造成伤害，在此【杀】结算后你可以重复此流程。若此【杀】令该角色进入濒死状态，濒死结算后你失去1点体力，且本回合“虎魂”无效。 ",
	["meizlxuechou"] = "雪雠",
	["$meizlxuechouanimate"] = "image=image/animate/meizlxuechou.png",
	[":meizlxuechou"] = "其他角色死亡时，你可以获得该角色的所有手牌（至少一张）并将之当作【杀】对当前回合角色使用。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 005 神黄月英
meizlshenhuangyueying = sgs.General(extension, "meizlshenhuangyueying", "god", 3, false)
--木牛（神黄月英）
meizlmuniu = sgs.CreateTriggerSkill {
	name = "meizlmuniu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if not player:askForSkillInvoke(self:objectName()) then return end
			room:doLightbox("$meizlmuniuanimate", 1000)
			room:showAllCards(player, nil)
			local x = 0
			for _, p in sgs.qlist(player:getHandcards()) do
				if p:isKindOf("TrickCard") then
					x = x + 1
				end
			end
			player:drawCards(x)
		end
	end
}
--智袭（神黄月英）
meizlzhixicard = sgs.CreateSkillCard {
	name = "meizlzhixicard",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select)
		return to_select:getPile("meizlzhixi"):length() == 0 and to_select:objectName() ~= sgs.Self:objectName() and
			(#targets < 1)
	end,
	on_use = function(self, room, source, targets)
		local ids = self:getSubcards()
		for _, id in sgs.qlist(ids) do
			targets[1]:addToPile("meizlzhixi", id, false)
		end
	end
}
meizlzhixiskill = sgs.CreateViewAsSkill {
	name = "meizlzhixi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlzhixicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

meizlzhixi = sgs.CreateTriggerSkill {
	name = "meizlzhixi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlzhixiskill,
	events = { sgs.Damaged, sgs.HpRecover, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets1 = sgs.SPlayerList()
		local targets2 = sgs.SPlayerList()
		local targets3 = sgs.SPlayerList()
		local target
		local card_id
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getPile("meizlzhixi"):length() > 0 then
				for _, card in sgs.qlist(p:getPile("meizlzhixi")) do
					card_id = card
				end
				local carda = sgs.Sanguosha:getCard(card_id)
				if carda:isKindOf("BasicCard") then
					targets1:append(p)
				elseif carda:isKindOf("TrickCard") then
					targets2:append(p)
				elseif carda:isKindOf("EquipCard") then
					targets3:append(p)
				end
			end
		end
		if event == sgs.Damaged then
			if targets1:isEmpty() then return end
			target = room:askForPlayerChosen(player, targets1, self:objectName(), "meizlzhixi-invoke", true, true)
			if not target then return false end
		elseif event == sgs.HpRecover then
			if targets2:isEmpty() then return end
			target = room:askForPlayerChosen(player, targets2, self:objectName(), "meizlzhixi-invoke", true, true)
			if not target then return false end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local places = move.from_places
			local source = move.from
			if source and source:getPhase() == sgs.Player_NotActive then
				if source and source:objectName() == player:objectName() then
					if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
						if targets3:isEmpty() then return end
						target = room:askForPlayerChosen(player, targets3, self:objectName(), "meizlzhixi-invoke", true,
							true)
						if not target then return false end
					end
				end
			end
		end
		if target then
			local card_throw
			for _, p in sgs.qlist(target:getPile("meizlzhixi")) do
				card_throw = p
			end
			room:doLightbox("$meizlzhixianimate", 1000)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
			local card = sgs.Sanguosha:getCard(card_throw)
			room:throwCard(card, reason, target)
			room:loseHp(target, 1)
			if card:isKindOf("EquipCard") then
				player:drawCards(2)
			end
		end
	end
}
--隐才（神黄月英）
meizlyincaicard = sgs.CreateSkillCard {
	name = "meizlyincaicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlyincai")
		room:doLightbox("$meizlyincaianimate", 1000)
		local x = 999
		while x > 0 do
			local targetgroup = sgs.SPlayerList()
			local y = 0
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getPile("meizlzhixi"):length() == 0 then
					y = y + 1
					targetgroup:append(p)
				end
			end
			x = y
			if x > 0 then
				local card = sgs.Sanguosha:getCard(room:drawCard())
				source:obtainCard(card)
				local target = room:askForPlayerChosen(source, targetgroup, self:objectName())
				target:addToPile("meizlzhixi", card, false)
			end
		end
	end
}
meizlyincaiskill = sgs.CreateViewAsSkill {
	name = "meizlyincai",
	n = 0,
	view_as = function(self, cards)
		return meizlyincaicard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlyincai") > 0
	end
}
meizlyincai = sgs.CreateTriggerSkill {
	name = "meizlyincai",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlyincaiskill,
	events = {},
	limit_mark = "@meizlyincai",
	on_trigger = function(self, event, player, data)
	end
}

meizlshenhuangyueying:addSkill(meizlmuniu)
meizlshenhuangyueying:addSkill(meizlzhixi)
meizlshenhuangyueying:addSkill(meizlyincai)
sgs.LoadTranslationTable {
	["meizlshenhuangyueying"] = "神黄月英",
	["#meizlshenhuangyueying"] = "隐居的智者",
	["designer:meizlshenhuangyueying"] = "Mark1469",
	["illustrator:meizlshenhuangyueying"] = "司淳",
	["illustrator:meizlshenhuangyueying_1"] = "司淳",
	["meizlmuniu"] = "木牛",
	["$meizlmuniuanimate"] = "image=image/animate/meizlmuniu.png",
	[":meizlmuniu"] = "出牌阶段开始时，你可以展示所有手牌，当中每有一张锦囊牌，你摸一张牌。",
	["meizlzhixi-invoke"] = "你可以发动“智袭”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlzhixi"] = "智袭",
	["$meizlzhixianimate"] = "image=image/animate/meizlzhixi.png",
	["meizlzhixicard"] = "智袭",
	[":meizlzhixi"] = "出牌阶段，你可以选择一名武将牌旁没有牌的其他角色，并将一张牌背面朝下置于其武将牌旁。你可以根据此牌的种类在对应的时机弃置之，然后该角色失去1点体力。基本牌：受到一次伤害后；锦囊牌：回复一次体力后；装备牌：你的回合外，失去牌时。若你以此法弃置的牌为装备牌，你摸两张牌。",
	["meizlyincai"] = "隐才",
	["$meizlyincaianimate"] = "image=image/animate/meizlyincai.png",
	["meizlyincaicard"] = "隐才",
	["@meizlyincai"] = "隐才",
	[":meizlyincai"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，若任一其他角色武将牌旁没有牌，你可以摸一张牌并将之背面朝下置于其武将牌旁，你重复此流程，直到所有其他角色武将牌旁均有牌为止。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 006 神王异
meizlshenwangyi = sgs.General(extension, "meizlshenwangyi", "god", 3, false)
--贞誓（神王异）
meizlzhenshicard = sgs.CreateSkillCard {
	name = "meizlzhenshicard",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		local choices = "cancel"
		if source:getHandcardNum() >= 3 then
			choices = choices .. "+meizlzhenshih"
		end
		if source:getEquips():length() > 0 then
			choices = choices .. "+meizlzhenshie"
		end
		local choice = room:askForChoice(source, "meizlzhenshi", choices)
		if choice == "meizlzhenshih" then
			source:throwAllHandCards()
		elseif choice == "meizlzhenshie" then
			source:throwAllEquips()
		elseif choice == "cancel" then
			return false
		end
		room:doLightbox("$meizlzhenshianimate", 1000)
		room:setPlayerFlag(source, "meizlzhenshi")
		local recover = sgs.RecoverStruct()
		recover.recover = source:getMaxHp() - source:getHp()
		recover.who = source
		room:recover(source, recover)
	end
}

meizlzhenshi = sgs.CreateViewAsSkill {
	name = "meizlzhenshi",
	n = 0,
	view_as = function()
		return meizlzhenshicard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() >= 3 or player:getEquips():length() > 0) and (not player:hasFlag("meizlzhenshi")) and
			player:isWounded()
	end,
}
--缓计（神王异）
meizlhuanji = sgs.CreateTriggerSkill {
	name = "meizlhuanji",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart, sgs.TargetConfirming, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("@meizlhuanji", 5)
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local slash = use.card
			if slash and slash:isKindOf("Slash") then
				if player:getMark("@meizlhuanji") > 0 and not use.from:isNude() then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:doLightbox("$meizlhuanjianimate", 1000)
						player:loseMark("@meizlhuanji", 1)
						local card_id = room:askForCardChosen(use.from, use.from, "he", self:objectName())
						room:throwCard(card_id, use.from, use.from)
						player:addMark("meizlhuanji")
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and player:getMark("meizlhuanji") > 0 then
				player:setMark("meizlhuanji", 0)
				return true
			end
		end
	end
}
--犒赏（神王异）
meizlkaoshangcard = sgs.CreateSkillCard {
	name = "meizlkaoshangcard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local id = self:getEffectiveId()
			local card = sgs.Sanguosha:getCard(id)
			local equip = card:getRealCard():toEquipCard()
			local index = equip:location()
			return to_select:getEquip(index) == nil and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:doLightbox("$meizlkaoshanganimate", 1000)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "meizlkaoshang", "")
		room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip, reason)
		local kshtargets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
			if targets[1]:inMyAttackRange(p) then
				kshtargets:append(p)
			end
		end
		if kshtargets:isEmpty() then
			return
		end
		local kshtarget = room:askForPlayerChosen(source, kshtargets, self:objectName(),
			"@meizlkaoshang-damage:" .. targets[1]:objectName())
		room:damage(sgs.DamageStruct(self:objectName(), targets[1], kshtarget))
	end
}
meizlkaoshangskill = sgs.CreateViewAsSkill {
	name = "meizlkaoshang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local first = meizlkaoshangcard:clone()
			first:addSubcard(cards[1]:getId())
			first:setSkillName(self:objectName())
			return first
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlkaoshang"
	end
}
meizlkaoshang = sgs.CreateTriggerSkill {
	name = "meizlkaoshang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = meizlkaoshangskill,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:isNude() then
				room:askForUseCard(player, "@@meizlkaoshang", "@meizlkaoshang-equip")
			end
		end
		return false
	end
}

meizlshenwangyi:addSkill(meizlzhenshi)
meizlshenwangyi:addSkill(meizlhuanji)
meizlshenwangyi:addSkill(meizlkaoshang)

sgs.LoadTranslationTable {
	["meizlshenwangyi"] = "神王异",
	["#meizlshenwangyi"] = "复仇的妖花",
	["designer:meizlshenwangyi"] = "Mark1469",
	["illustrator:meizlshenwangyi"] = "三国轮舞曲",
	["illustrator:meizlshenwangyi_1"] = "COGA",
	["meizlzhenshi"] = "贞誓",
	["$meizlzhenshianimate"] = "image=image/animate/meizlzhenshi.png",
	["meizlzhenshicard"] = "贞誓",
	["meizlzhenshi:meizlzhenshih"] = "所有手牌",
	["meizlzhenshi:meizlzhenshie"] = "装备区里的所有牌",
	[":meizlzhenshi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你已受伤，你可以弃置装备区里的所有牌（至少一张）或所有手牌（至少三张），然后将体力回复至体力上限。",
	["meizlhuanji"] = "缓计",
	["$meizlhuanjianimate"] = "image=image/animate/meizlhuanji.png",
	["@meizlhuanji"] = "缓计",
	[":meizlhuanji"] = "每局游戏限五次，当你成为当其他角色使用【杀】的目标时，你可以令其弃置一张牌，然后此【杀】对你无效。",
	["meizlkaoshang"] = "犒赏",
	["$meizlkaoshanganimate"] = "image=image/animate/meizlkaoshang.png",
	["meizlkaoshangcard"] = "犒赏",
	["@meizlkaoshang-equip"] = "你可以发动“犒赏”",
	["@meizlkaoshang-damage"] = "请选择 %src 攻击范围内的一名角色",
	["~meizlkaoshang"] = "选择一张装备牌→选择一名其他角色→点击确定",
	[":meizlkaoshang"] = "结束阶段开始时，你可以将一张装备牌置于一名其他角色的装备区里，然后视为该角色对其攻击范围内另一名由你指定的角色造成了1点伤害。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 007 神张星彩
meizlshenzhangxingcai = sgs.General(extension, "meizlshenzhangxingcai", "god", 3, false)
--庇荫（神张星彩）
meizlbiyincard = sgs.CreateSkillCard
	{
		name = "meizlbiyincard",
		target_fixed = false,
		will_throw = false,

		feasible = function(self, targets)
			return #targets == 1
		end,

		filter = function(self, targets, to_select)
			return true
		end,
		on_use = function(self, room, source, targets)
			room:doLightbox("$meizlbiyinanimate", 1000)
			source:loseMark("@meizlbiyin")
			--room:attachSkillToPlayer(targets[1], "meizlbiyinx")
			room:handleAcquireDetachSkills(targets[1], "meizlbiyinx")
			room:setPlayerMark(targets[1], "@meizlbiyinx", 1)
			room:addPlayerMark(targets[1], "&meizlbiyin+to+#" .. source:objectName())
		end
	}

meizlbiyinskill = sgs.CreateViewAsSkill
	{
		name = "meizlbiyin",
		n = 0,

		view_as = function(self, cards)
			return meizlbiyincard:clone()
		end,

		enabled_at_play = function(self, player)
			return not (player:hasUsed("#meizlbiyincard") or player:getMark("@meizlbiyin") == 0)
		end,
	}
meizlbiyin = sgs.CreateTriggerSkill {
	name = "meizlbiyin",
	view_as_skill = meizlbiyinskill,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		player:gainMark("@meizlbiyin", 8)
	end
}
meizlbiyinskill2 = sgs.CreateTriggerSkill {
	name = "#meizlbiyinskill2",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventLoseSkill, sgs.Death, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlbiyin" then
				return false
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			--room:detachSkillFromPlayer(p, "meizlbiyinx")
			if p:getMark("&meizlbiyin+to+#" .. player:objectName()) > 0 then
				room:handleAcquireDetachSkills(p, "-meizlbiyinx")
				room:setPlayerMark(p, "@meizlbiyinx", 0)
				room:setPlayerMark(p, "&meizlbiyin+to+#" .. player:objectName(), 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

meizlbiyinx = sgs.CreateTriggerSkill {
	name = "meizlbiyinx",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isKindOf("Slash") then
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.from = player
			log.arg = "meizlbiyinx"
			log.arg2 = "slash"
			room:sendLog(log)
			return true
		end
	end
}
--虎裔（神张星彩）
meizlhuyi = sgs.CreateTargetModSkill {
	name = "meizlhuyi",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			local x
			if player:getMark("@meizlkuangji") > 0 then
				x = 2
			else
				x = player:getLostHp()
			end
			return x
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			local x = 0
			if player:getMark("@meizlkuangji") > 0 then
				x = 2
			else
				x = player:getLostHp()
			end
			return x
		end
	end
}
--匡济（神张星彩）
meizlkuangjicard = sgs.CreateSkillCard {
	name = "meizlkuangjicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:doLightbox("$meizlkuangjianimate", 1000)
		room:detachSkillFromPlayer(source, "meizlbiyin")
		source:gainMark("@meizlkuangji")
		room:addPlayerMark(source, "&meizlkuangji")
		room:changeTranslation(source, "meizlhuyi", 2)
	end
}
meizlkuangjiskill = sgs.CreateViewAsSkill {
	name = "meizlkuangji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlkuangjicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlkuangji") == 0
	end
}
meizlkuangji = sgs.CreateTriggerSkill {
	name = "meizlkuangji",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlkuangjiskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlbiyinx") then skills:append(meizlbiyinx) end
sgs.Sanguosha:addSkills(skills)
meizlshenzhangxingcai:addSkill(meizlbiyin)
meizlshenzhangxingcai:addSkill(meizlbiyinskill2)
meizlshenzhangxingcai:addSkill(meizlkuangji)
meizlshenzhangxingcai:addSkill(meizlhuyi)
extension:insertRelatedSkills("meizlbiyin", "#meizlbiyinskill2")
sgs.LoadTranslationTable {
	["meizlshenzhangxingcai"] = "神张星彩",
	["#meizlshenzhangxingcai"] = "蜀汉之凤",
	["designer:meizlshenzhangxingcai"] = "Mark1469",
	["illustrator:meizlshenzhangxingcai"] = "蝎逐鱼",
	["illustrator:meizlshenzhangxingcai_1"] = "三国轮舞曲",
	["meizlbiyin"] = "庇荫",
	["$meizlbiyinanimate"] = "image=image/animate/meizlbiyin.png",
	["@meizlbiyin"] = "庇荫",
	["meizlbiyincard"] = "庇荫",
	["meizlbiyinx"] = "庇荫效果",
	[":meizlbiyinx"] = "<font color=\"blue\"><b>锁定技，</b></font>【杀】对你无效。",
	["#Meizlbiyinx"] = "%from触发【%arg2】，【%arg】对其无效",
	[":meizlbiyin"] = "每局游戏限八次，<font color=\"green\"><b>出牌阶段限一次，</b></font>你可令一名角色获得以下效果，直​​​​到你下回合开始时：【杀】对你无效。",
	["meizlkuangji"] = "匡济",
	["$meizlkuangjianimate"] = "image=image/animate/meizlkuangji.png",
	["@meizlkuangji"] = "匡济",
	["meizlkuangjicard"] = "匡济",
	[":meizlkuangji"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，你可以弃置一张牌，然后失去技能“庇荫”，并将“虎裔”描述中的X改为2。",
	["meizlhuyi"] = "虎裔",
	[":meizlhuyi"] = "你可额外使用X张【杀】；使用【杀】时可额外指定X个目标。 （X为你已损失的体力值）。",
	[":meizlhuyi2"] = "你可额外使用2张【杀】；使用【杀】时可额外指定2个目标。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 008A 神大乔
meizlshendaqiao = sgs.General(extension, "meizlshendaqiao", "god", 3, false)
--啼痕（神大乔）
meizltihen = sgs.CreateTriggerSkill
	{
		name = "meizltihen",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					local y = p:getHp()
					local x = math.max(p:getHandcardNum(), 1)
					if y > x then
						room:loseHp(p, y - x)
					elseif y < x then
						local recover = sgs.RecoverStruct()
						recover.recover = x - y
						room:recover(p, recover)
					end
				end
			end
		end
	}
--佐政（神大乔）
meizlzuozheng = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_Frequent,
		name = "meizlzuozheng",
		events = { sgs.CardsMoveOneTime },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local move = data:toMoveOneTime()
			if not move.to or move.to:objectName() == player:objectName() then return false end
			if move.from_places:contains(sgs.Player_DrawPile) and move.to_place == sgs.Player_PlaceHand then
				if move.to:getPhase() == sgs.Player_Draw or move.to:getPhase() == sgs.Player_NotActive then return end
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				if player:hasSkill("meizlbiyi") then
					player:gainMark("@meizlbiyi")
				end
				player:drawCards(1)
			end
		end
	}
--颦蹙（神大乔、神小乔）
meizlpincu = sgs.CreateTriggerSkill {
	name = "meizlpincu",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_RoundStart then return end
		if player:getGeneralName() == "meizlshendaqiao" then
			room:changeHero(player, "meizlshenxiaoqiao", false, false, false, true)
		elseif player:getGeneral2Name() == "meizlshendaqiao" then
			room:changeHero(player, "meizlshenxiaoqiao", false, false, true, true)
		elseif player:getGeneralName() == "meizlshenxiaoqiao" then
			room:changeHero(player, "meizlshendaqiao", false, false, false, true)
		elseif player:getGeneral2Name() == "meizlshenxiaoqiao" then
			room:changeHero(player, "meizlshendaqiao", false, false, true, true)
		end
	end
}
--比翼（神大乔、神小乔）
meizlbiyicard = sgs.CreateSkillCard {
	name = "meizlbiyicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlbiyi", 1)
		local x = math.random(1, 5)
		if x < 4 then
			if source:getGeneralName() == "meizlshendaqiao" or source:getGeneralName() == "meizlshenxiaoqiao" then
				room:changeHero(source, "meizlshendaqiaoxiaoqiao", false, true, false, true)
			elseif source:getGeneral2Name() == "meizlshendaqiao" or source:getGeneral2Name() == "meizlshenxiaoqiao" then
				room:changeHero(source, "meizlshendaqiaoxiaoqiao", false, true, true, true)
			else
				room:handleAcquireDetachSkills(source, "-meizltihen")
				room:handleAcquireDetachSkills(source, "-meizlzuozheng")
				room:handleAcquireDetachSkills(source, "-meizlpincu")
				room:handleAcquireDetachSkills(source, "-meizlxiaohun")
				room:handleAcquireDetachSkills(source, "-meizlxiuse")
				room:handleAcquireDetachSkills(source, "-meizlbiyi")
				room:handleAcquireDetachSkills(source, "meizlpingting")
				room:handleAcquireDetachSkills(source, "meizlhuawu")
				room:handleAcquireDetachSkills(source, "meizlyangxiu")
				room:handleAcquireDetachSkills(source, "meizlyanhong")
			end
		end
	end
}
meizlbiyiskill = sgs.CreateViewAsSkill {
	name = "meizlbiyi",
	n = 0,
	view_as = function(self, cards)
		return meizlbiyicard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlbiyi")
		return count >= 1
	end
}
meizlbiyi = sgs.CreateTriggerSkill {
	name = "meizlbiyi",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlbiyiskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlshendaqiao:addSkill(meizltihen)
meizlshendaqiao:addSkill(meizlzuozheng)
meizlshendaqiao:addSkill(meizlpincu)
meizlshendaqiao:addSkill(meizlbiyi)

sgs.LoadTranslationTable {
	["meizlshendaqiao"] = "神大乔",
	["&meizlshendaqiao"] = "神大乔",
	["#meizlshendaqiao"] = "江东的流莺",
	["designer:meizlshendaqiao"] = "Mark1469",
	["illustrator:meizlshendaqiao"] = "大戦乱!!三国志バトル",
	["illustrator:meizlshendaqiao_1"] = "rae",
	["meizltihen"] = "啼痕",
	[":meizltihen"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，所有角色将体力扣减或回复至X点(X为该角色的手牌数且且至少为1)。",
	["meizlzuozheng"] = "佐政",
	["meizlzuozhengmove"] = "佐政\
	请交给目标角色一张牌",
	["meizlzuozhengmove"] = "佐政",
	[":meizlzuozheng"] = "摸牌阶段外，当其他角色于其回合内摸牌时，你可以摸一张牌。",
	["meizlpincu"] = "颦蹙",
	[":meizlpincu"] = "<font color=\"blue\"><b>锁定技，</b></font>回合开始时，若你当前武将为神大乔，你变身为神小乔；若你当前武将为神小乔，你变身为神大乔。",
	["meizlbiyi"] = "比翼",
	["meizlbiyicard"] = "比翼",
	["@meizlbiyi"] = "乔",
	[":meizlbiyi"] = "<font color=\"lemonchiffon\"><b>净化技，</b></font>每当你发动技能“佐政”或“羞涩”时，你获得一枚“乔”标记；出牌阶段，你可以弃一枚“乔”标记，然后你有20%机率变身为“神大乔＆小乔”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 008B 神小乔
meizlshenxiaoqiao = sgs.General(extension, "meizlshenxiaoqiao", "god", 3, false, true)
--销魂（神小乔）
meizlxiaohun = sgs.CreateTriggerSkill
	{
		name = "meizlxiaohun",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					p:throwAllHandCards()
					local y = p:getHp()
					p:drawCards(y)
				end
			end
		end
	}
--羞涩（神小乔）
meizlxiuse = sgs.CreateTriggerSkill {
	name = "meizlxiuse",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
		
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			if player:hasSkill("meizlbiyi") then
				player:gainMark("@meizlbiyi")
			end
			draw.num = draw.num - 1
			data:setValue(draw)
			room:setPlayerMark(player, "meizlxiuse", 1)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
			if player:getMark("meizlxiuse") > 0 then
				room:setPlayerMark(player, "meizlxiuse", 0)
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				local phslist = sgs.PhaseList()
				phslist:append(sgs.Player_Draw)
				target:play(phslist)
			end
		end
	end
}

meizlshenxiaoqiao:addSkill(meizlxiaohun)
meizlshenxiaoqiao:addSkill(meizlxiuse)
meizlshenxiaoqiao:addSkill(meizlpincu)
meizlshenxiaoqiao:addSkill(meizlbiyi)
sgs.LoadTranslationTable {
	["meizlshenxiaoqiao"] = "神小乔",
	["&meizlshenxiaoqiao"] = "神小乔",
	["#meizlshenxiaoqiao"] = "东吴的飞燕",
	["designer:meizlshenxiaoqiao"] = "Mark1469",
	["illustrator:meizlshenxiaoqiao"] = "大戦乱!!三国志バトル",
	["illustrator:meizlshenxiaoqiao_1"] = "rae",
	["meizlxiaohun"] = "销魂",
	[":meizlxiaohun"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，所有角色弃置所有手牌，然后摸X张牌(X为该角色的体力值)。",
	["meizlxiuse"] = "羞涩",
	[":meizlxiuse"] = "摸牌阶段，你可以少摸一张牌，然后令一名其他角色执行一个额外的摸牌阶段。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEIZLG 008 神大乔＆小乔
meizlshendaqiaoxiaoqiao = sgs.General(extension, "meizlshendaqiaoxiaoqiao", "god", 3, false, true)

meizlpingtingprevent = sgs.CreateProhibitSkill {
	name = "#meizlpingtingprevent",
	is_prohibited = function(self, from, to, card)
		for _, p in sgs.qlist(to:getPile("meizlpingting")) do
			local cd = sgs.Sanguosha:getCard(p)
			if cd:objectName() == card:objectName() then
				return card
			end
		end
	end
}


meizlpingting = sgs.CreateTriggerSkill {
	name = "meizlpingting",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() and player:hasSkill("meizlpingting") then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if player:askForSkillInvoke("meizlpingting", data) then
					local card = room:drawCard()
					room:getThread():delay()
					local cd = sgs.Sanguosha:getCard(card)
					room:showCard(player, cd:getEffectiveId())
					if cd:isKindOf("TrickCard") then
						player:addToPile("meizlpingting", cd, true)
					else
						player:obtainCard(cd)
						player:drawCards(1)
					end
				end
			end
		end
	end
}

meizlhuawucard = sgs.CreateSkillCard {
	name = "meizlhuawucard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = self:getSubcards()
		for _, id in sgs.qlist(ids) do
			local x = sgs.Sanguosha:getCard(id)
			if x:isKindOf("BasicCard") then
				source:addToPile("meizlshan", id, true)
			elseif x:isKindOf("TrickCard") then
				source:addToPile("meizlhua", id, true)
			elseif x:isKindOf("EquipCard") then
				source:addToPile("meizlqun", id, true)
			end
		end
	end
}
meizlhuawu = sgs.CreateViewAsSkill {
	name = "meizlhuawu",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local meizlhuawucard = meizlhuawucard:clone()
			for _, card in pairs(cards) do
				meizlhuawucard:addSubcard(card)
			end
			meizlhuawucard:setSkillName(self:objectName())
			return meizlhuawucard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

meizlhuawudistance = sgs.CreateDistanceSkill {
	name = "#meizlhuawudistance",
	correct_func = function(self, from, to)
		if to:hasSkill(self:objectName()) then
			local qun = to:getPile("meizlqun")
			local count = qun:length()
			return count
		end
	end
}

meizlhuawumaxhand = sgs.CreateMaxCardsSkill {
	name = "#meizlhuawumaxhand",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			local hua = target:getPile("meizlhua")
			return hua:length()
		end
	end
}

meizlhuaremove = sgs.CreateTriggerSkill {
	name = "#meizlhuaremove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local name = data:toString()
		if name == "meizlhua" then
			player:removePileByName("meizlhua")
			player:removePileByName("meizlqun")
			player:removePileByName("meizlshan")
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}

meizlyangxiucard = sgs.CreateSkillCard {
	name = "meizlyangxiucard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets < sgs.Self:getPile("meizlqun"):length() then
			return to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select)
		end
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlyangxiu")
		local x = source:getPile("meizlhua"):length()
		local y = source:getPile("meizlshan"):length()
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		for _, cd in sgs.qlist(source:getPile("meizlshan")) do
			dummy:addSubcard(cd)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
		room:throwCard(dummy, reason, nil)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(source:getPile("meizlhua")) do
			dummy:addSubcard(cd)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
		room:throwCard(dummy, reason, nil)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(source:getPile("meizlqun")) do
			dummy:addSubcard(cd)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
		room:throwCard(dummy, reason, nil)
		--source:removePileByName("meizlshan")
		--		source:removePileByName("meizlhua")
		--		source:removePileByName("meizlqun")
		local damage = sgs.DamageStruct()
		damage.from = source

		for _, p in pairs(targets) do
			if source:isAlive() then
				room:askForDiscard(p, self:objectName(), y, y, false, true)
				damage.damage = x
				damage.to = p
				room:damage(damage)
			end
		end
		room:detachSkillFromPlayer(source, "meizlhuawu")
		room:loseMaxHp(source, 1)
	end
}
meizlyangxiuskill = sgs.CreateViewAsSkill {
	name = "meizlyangxiu",
	n = 0,
	view_as = function(self, cards)
		return meizlyangxiucard:clone()
	end,
	enabled_at_play = function(self, player)
		if (player:getPile("meizlshan"):length() > 0) and (player:getPile("meizlqun"):length() > 0) and (player:getPile("meizlhua"):length() > 0) then
			return player:getMark("@meizlyangxiu") > 0
		end
	end
}

meizlyangxiu = sgs.CreateTriggerSkill {
	name = "meizlyangxiu",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlyangxiuskill,
	limit_mark = "@meizlyangxiu",
	on_trigger = function(self, event, player, data)
	end
}

meizlyanhongcard = sgs.CreateSkillCard {
	name = "meizlyanhongcard",
	will_throw = true,
	target_fixed = true,

	on_use = function(self, room, source, targets)
		local x = self:getSuit()
		local current = room:getCurrent()
		if x == sgs.Card_Heart then
			current:skip(sgs.Player_Discard)
		elseif x == sgs.Card_Spade then
			current:skip(sgs.Player_Play)
		elseif x == sgs.Card_Club then
			current:skip(sgs.Player_Draw)
		elseif x == sgs.Card_Diamond then
			current:skip(sgs.Player_Judge)
		end
	end
}

meizlyanhongskill = sgs.CreateViewAsSkill {
	name = "meizlyanhong",
	n = 1,

	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlyanhongcard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlyanhong"
	end
}

meizlyanhong = sgs.CreateTriggerSkill {
	name = "meizlyanhong",
	events = { sgs.EventPhaseStart },
	view_as_skill = meizlyanhongskill,
	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if not splayer then return end
		if player:getPhase() ~= sgs.Player_RoundStart then return end
		if player:objectName() == splayer:objectName() or splayer:isNude() then return end
		room:askForUseCard(splayer, "@@meizlyanhong", "@meizlyanhong")
	end
}

meizlshendaqiaoxiaoqiao:addSkill(meizlpingting)
meizlshendaqiaoxiaoqiao:addSkill(meizlpingtingprevent)
extension:insertRelatedSkills("meizlpingting", "#meizlpingtingprevent")
meizlshendaqiaoxiaoqiao:addSkill(meizlhuawu)
meizlshendaqiaoxiaoqiao:addSkill(meizlhuawudistance)
meizlshendaqiaoxiaoqiao:addSkill(meizlhuawumaxhand)
extension:insertRelatedSkills("meizlpingting", "#meizlhuawudistance")
extension:insertRelatedSkills("meizlpingting", "#meizlhuawumaxhand")
meizlshendaqiaoxiaoqiao:addSkill(meizlyangxiu)
meizlshendaqiaoxiaoqiao:addSkill(meizlyanhong)

sgs.LoadTranslationTable {
	["meizlshendaqiaoxiaoqiao"] = "神大乔＆小乔",
	["&meizlshendaqiaoxiaoqiao"] = "神二乔",
	["#meizlshendaqiaoxiaoqiao"] = "魅倾江东",
	["designer:meizlshendaqiaoxiaoqiao"] = "Mark1469",
	["illustrator:meizlshendaqiaoxiaoqiao"] = "大戦乱!!三国志バトル",
	["illustrator:meizlshendaqiaoxiaoqiao_1"] = "rae",
	["meizlhuawu"] = "花舞",
	["meizlhuawucard"] = "花舞",
	["meizlhua"] = "花",
	["meizlqun"] = "裙",
	["meizlshan"] = "扇",
	[":meizlhuawu"] = "出牌阶段，你可以将任意数量的牌置于你的武将牌上，当中的锦囊牌称为“花”；装备牌称为“裙”；基本牌称为“扇”。每有一张“花”，你的手牌上限便+1；每有一张“裙”，其他角色计算与你的距离便+1。",
	["meizlyangxiu"] = "扬袖",
	["@meizlyangxiu"] = "扬袖",
	["meizlyangxiucard"] = "扬袖",
	[":meizlyangxiu"] = "<font color=\"red\"><b>限定技，</b></font>若“花”、“裙”和“扇”的数量各达到1或更多，你可以弃置武将牌上的所有牌，然后令攻击范围内至多X名角色弃置与此法弃置的“扇”等量的牌，并对该角色造成与此法弃置的“花”等量的伤害（X为以此法弃置的“裙”的数量）。此技能发动后，你失去技能“花舞”并减1点体力上限。",
	["meizlpingting"] = "娉婷",
	[":meizlpingting"] = "每当你受到1点伤害后，你可以亮出牌埋顶的一张牌，若为锦囊牌，你将之置于你的武将牌上；否则，你获得之并摸一张牌；你不能成为与武将牌上相同名称的牌的目标。",
	["meizlyanhong"] = "嫣红",
	["meizlyanhongcard"] = "嫣红",
	["@meizlyanhong"] = "你可以发动技能【嫣红】",
	["~meizlyanhong"] = "选择一张牌→点击确定",
	[":meizlyanhong"] = "其他角色的回合开始时，你可以弃置一张牌，并令该角色根据此牌的花色跳过指定的阶段：黑桃，出牌阶段；红桃，弃牌阶段；梅花，摸牌阶段；方块，判定阶段。",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--MEISP 001 娘-赵云
meispniangzhaoyun          = sgs.General(extension, "meispniangzhaoyun", "shu", 3, false)
--凤胆（娘-赵云）
meispfengdan               = sgs.CreateTriggerSkill {
	name = "meispfengdan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.Damage, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			player:loseMark("@meispfeng")
		elseif event == sgs.Damage then
			player:gainMark("@meispfeng")
		elseif event == sgs.DamageCaused then
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				damage.damage = damage.damage + tonumber(player:getMark("@meispfeng"))
				local log = sgs.LogMessage()
				log.type = "#meispfengdan"
				log.from = player
				log.to:append(damage.to)
				log.arg = self:objectName()
				log.arg2 = tonumber(player:getMark("@meispfeng"))
				room:sendLog(log)
				data:setValue(damage)
			end
		end
	end
}
--梨舞（娘-赵云）
meispliwucard              = sgs.CreateSkillCard {
	name = "meispliwucard",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		source:loseMark("@meispfeng", 2)
		if source:getMark("@meispliwu") > 0 then
			source:loseMark("@meispliwu")
			room:detachSkillFromPlayer(source, "meispliwuskill2")
		else
			source:gainMark("@meispliwu")
			room:handleAcquireDetachSkills(source, "meispliwuskill2")
			room:setPlayerMark(source, "@meispliwuprevent", 1)
		end
	end
}

meispliwuskill             = sgs.CreateViewAsSkill {
	name = "meispliwu",
	n = 0,

	view_as = function(self, cards)
		return meispliwucard:clone()
	end,

	enabled_at_play = function(self, player)
		return player:getKingdom() == "shu" and player:getMark("@meispfeng") >= 2 and
			not player:hasUsed("#meispliwucard")
	end,
}

meispliwu                  = sgs.CreateTriggerSkill {
	name = "meispliwu",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meispliwuskill,
	events = { sgs.DrawNCards, sgs.Damaged, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@meispliwu") > 0 then
			if event == sgs.DrawNCards then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				draw.num = draw.num + 1
				data:setValue(draw)
			elseif event == sgs.DamageInflicted then
				if player:getMark("@meispliwuprevent") > 0 then
					room:setPlayerMark(player, "@meispliwuprevent", tonumber(player:getMark("@meispliwuprevent")) - 1)
					local log = sgs.LogMessage()
					log.type = "#Meispliwu"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					return true
				end
			elseif event == sgs.Damaged then
				player:loseMark("@meispliwu")
				room:detachSkillFromPlayer(player, "meispliwuskill2")
			end
		end
	end
}

sgs.meispliwuskill2Pattern = { "pattern" }
meispliwuskill2            = sgs.CreateViewAsSkill {
	name = "meispliwuskill2",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.meispliwuskill2Pattern[1]
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			sgs.meispliwuskill2Pattern = { "slash" }
			return true
		end
		return false
	end
}
--瑞雪（娘‧赵云）
meispruixuecard            = sgs.CreateSkillCard {
	name = "meispruixuecard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meispruixue")
		source:drawCards(3)
		room:setPlayerMark(source, "@meispruixueeffect", 1)
		room:addPlayerMark(source, "&meispruixue-Clear")
	end
}
meispruixueskill           = sgs.CreateViewAsSkill {
	name = "meispruixue",
	n = 0,
	view_as = function(self, cards)
		local card = meispruixuecard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meispruixue") > 0 and player:getKingdom() == "qun"
	end
}
meispruixue                = sgs.CreateTriggerSkill {
	name = "meispruixue",
	frequency = sgs.Skill_Limited,
	view_as_skill = meispruixueskill,
	limit_mark = "@meispruixue",
	events = { sgs.Damage, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if player:getMark("@meispruixueeffect") > 0 then
				local damage = data:toDamage()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:objectName() ~= damage.to:objectName() then
						room:loseHp(p, tonumber(damage.damage))
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "@meispruixueeffect", 0)
		end
	end
}

meispniangzhaoyunkingdom   = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meispniangzhaoyunkingdom",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getGeneralName() == "meispniangzhaoyun" then
			local choice = room:askForChoice(player, "meispniangzhaoyunkingdom", "shu+qun")
			room:setPlayerProperty(player, "kingdom", sgs.QVariant(choice))
		end
	end
}

meichunjiefulicard         = sgs.CreateSkillCard {
	name = "meichunjiefulicard",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		local choice = room:askForChoice(source, "meispniangzhaoyunkingdom", "shu+qun")
		room:setPlayerProperty(source, "kingdom", sgs.QVariant(choice))
		--local choice = room:askForKingdom(source)
		--room:setPlayerProperty(source, "kingdom", sgs.QVariant(choice))
	end
}

meichunjiefuli             = sgs.CreateViewAsSkill {
	name = "meichunjiefuli",
	n = 0,

	view_as = function(self, cards)
		return meichunjiefulicard:clone()
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#meichunjiefulicard")
	end,
}
local skills               = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meispliwuskill2") then skills:append(meispliwuskill2) end
sgs.Sanguosha:addSkills(skills)
meispniangzhaoyun:addSkill(meispfengdan)
meispniangzhaoyun:addSkill(meispliwu)
meispniangzhaoyun:addSkill(meispruixue)
meispniangzhaoyun:addSkill(meispniangzhaoyunkingdom)
meispniangzhaoyun:addSkill(meichunjiefuli)

sgs.LoadTranslationTable {
	["meispniangzhaoyun"] = "娘-赵云",
	["&meispniangzhaoyun"] = "赵云",
	["designer:meispniangzhaoyun"] = "Mark1469",
	["illustrator:meispniangzhaoyun"] = "Sive",
	["#meispniangzhaoyun"] = "长坂坡女将",
	["meispfengdan"] = "凤胆",
	["#meispfengdan"] = "%from的【%arg】被触发，对%to造成的伤害增加%arg2点。",
	["@meispfeng"] = "凤",
	[":meispfengdan"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你造成一次伤害后，你获得一枚“凤”标记；每当你受到一次伤害后，你失去一枚“凤”标记；你造成【杀】或【决斗】的伤害+X（X为你拥有的“凤”标记数量）。",
	["meispliwu"] = "梨舞",
	["meispliwuskill2"] = "梨舞效果",
	[":meispliwuskill2"] = "你可以将【闪】当作【杀】；【杀】当作【闪】使用。",
	["@meispliwu"] = "梨舞",
	["meispliwucaed"] = "梨舞",
	[":meispliwu"] = "<b><font color=\"darkslategray\">势力技<font color=\"red\">（蜀）</font>，</font></b><font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置两枚“凤”标记，然后获得或取消以下效果：你防止获得此效果后首次受到的伤害；摸牌阶段时，你额外摸一张牌；你可以将【闪】当作【杀】；【杀】当作【闪】使用。每当你受到一次伤害后，你失去此效果。",
	["meispruixue"] = "瑞雪",
	["meispruixuecard"] = "瑞雪",
	["@meispruixue"] = "瑞雪",
	[":meispruixue"] = "<b><font color=\"darkslategray\">势力技<font color=\"gray\">（群）</font>，</font></b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以摸三张牌，然后此回合内，每当你对其他角色造成一次伤害后，除该角色以外的其他角色失去与造成的伤害等量的体力。",
	["meispniangzhaoyunkingdom"] = "娘-赵云-势力选择",
	["meichunjiefuli"] = "春节福利",
	["meichunjiefulicard"] = "春节福利",
	[":meichunjiefuli"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以改变你的势力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISP 002 SP貂蝉
meispdiaochan = sgs.General(extension, "meispdiaochan", "qun", 3, false)
--拜月（SP貂蝉）
meispbaiyuecard = sgs.CreateSkillCard {
	name = "meispbaiyuecard",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets < 1)
	end,

	on_use = function(self, room, source, targets)
		room:swapSeat(source, targets[1])
		source:turnOver()
		source:drawCards(source:distanceTo(targets[1]))
	end
}

meispbaiyueskill = sgs.CreateViewAsSkill {
	name = "meispbaiyue",
	n = 0,

	view_as = function(self, cards)
		return meispbaiyuecard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meispbaiyue"
	end
}

meispbaiyue = sgs.CreateTriggerSkill
	{
		name = "meispbaiyue",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_NotFrequent,
		view_as_skill = meispbaiyueskill,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				room:askForUseCard(player, "@@meispbaiyue", "@meispbaiyue-card")
			end
		end
	}
--梳妆（SP貂蝉）
meispshuzhuang = sgs.CreateTriggerSkill {
	name = "meispshuzhuang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnedOver },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:faceUp() then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isMale() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "meispshuzhuangchoose", true)
				if target then
					room:loseHp(target)
				end
			end
		end
	end
}

meispshuzhuangeffect = sgs.CreateProhibitSkill {
	name = "#meispshuzhuangeffect",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
			and from:isMale() and not to:faceUp()
	end
}

meispdiaochan:addSkill(meispshuzhuang)
meispdiaochan:addSkill(meispshuzhuangeffect)
meispdiaochan:addSkill(meispbaiyue)

extension:insertRelatedSkills("meispshuzhuang", "#meispshuzhuangeffect")
sgs.LoadTranslationTable {
	["meispdiaochan"] = "SP貂蝉",
	["&meispdiaochan"] = "貂蝉",
	["#meispdiaochan"] = "倾城的妖姬",
	["designer:meispdiaochan"] = "Mark1469",
	["illustrator:meispdiaochan"] = "大戦乱!!三国志バトル",
	["meispbaiyue"] = "拜月",
	["@meispbaiyue-card"] = "请选择“拜月”的目标",
	["~meispbaiyue"] = "选择一名其他角色→点击确定",
	[":meispbaiyue"] = "结束阶段开始时，你可以选择一名其他角色，你将你的武将牌翻面，并和该角色交换位置，然后摸X张牌（X为你和该角色的距离）。",
	["meispshuzhuang"] = "梳妆",
	["#meispshuzhuangeffect"] = "梳妆",
	["meispshuzhuangchoose"] = "你可以发动【梳妆】，令一名男性角色失去1点体力。；或按取消。",
	[":meispshuzhuang"] = "若你的武将牌背面朝上，你不能成为男性角色的锦囊牌目标；每当你的武将牌翻至正面朝上时，你可以令一名男性角色失去1点体力。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISP 003 娘‧吕布
meispnianglvbu = sgs.General(extension, "meispnianglvbu", "qun", 3, false)
sgs.meispxiaojiPattern = { "pattern" }
--虓姬（娘‧吕布）
meispxiaojicard = sgs.CreateSkillCard {
	name = "meispxiaojicard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local pattern = sgs.meispxiaojiPattern[1]
		if pattern == "slash" then
			return to_select:objectName() ~= sgs.Self:objectName() and (#targets == 0)
		elseif pattern == "jink" then
			if to_select:getPile("meispji"):length() > 0 then
				for _, card_id in sgs.qlist(to_select:getPile("meispji")) do
					local card = sgs.Sanguosha:getCard(card_id)
					if card:getId() == sgs.Sanguosha:getCard(self:getSubcards():first()):getId() then
						return true
					end
				end
			end
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local meispxiaoji_dis = false
		if target:getPile("meispji"):length() > 0 then
			for _, card_id in sgs.qlist(target:getPile("meispji")) do
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getId() == sgs.Sanguosha:getCard(self:getSubcards():first()):getId() then
					meispxiaoji_dis = true
					break
				end
			end
		end



		local pattern = sgs.meispxiaojiPattern[1]
		local count = self:subcardsLength()
		if meispxiaoji_dis then
			local dummy = sgs.Sanguosha:cloneCard("jink")
			for i = 1, count, 1 do
				dummy:addSubcard(self:getSubcards():at(i - 1))
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "meispxiaoji", "");
			room:throwCard(dummy, reason, nil);
			dummy:deleteLater()
			room:setPlayerFlag(source, "LuaXDuanzhi_InTempMoving");
			local dummy_card = sgs.Sanguosha:cloneCard("jink")
			dummy_card:deleteLater()
			local card_ids = sgs.IntList()
			local original_places = sgs.PlaceList()
			for i = 1, count, 1 do
				if targets[1]:isNude() then break end
				card_ids:append(room:askForCardChosen(source, targets[1], "he", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i - 1)))
				dummy_card:addSubcard(card_ids:at(i - 1))
				targets[1]:addToPile("#meispxiaoji", card_ids:at(i - 1), false)
			end
			if dummy_card:subcardsLength() > 0 then
				for i = 1, dummy_card:subcardsLength(), 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), targets[1], original_places:at(i - 1),
						false)
				end
			end
			room:setPlayerFlag(source, "-LuaXDuanzhi_InTempMoving")
			if dummy_card:subcardsLength() > 0 then
				room:obtainCard(source, dummy_card)
			end
		else
			local ids = self:getSubcards()
			for _, id in sgs.qlist(ids) do
				targets[1]:addToPile("meispji", id)
			end
		end
	end
}

meispxiaojiskill = sgs.CreateViewAsSkill {
	name = "meispxiaoji",
	n = 999,
	expand_pile = "%meispji",
	view_filter = function(self, selected, to_select)
		if #selected > 0 then
			if sgs.Self:getHandcards():contains(selected[1]) then
				sgs.meispxiaojiPattern = { "slash" }
				return false
			else
				for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
					if p:getPile("meispji"):length() > 0 and p:getPile("meispji"):contains(selected[1]:getId()) then
						sgs.meispxiaojiPattern = { "jink" }
						return p:getPile("meispji"):contains(to_select:getId()) and
							not (#selected == p:getHandcardNum() + p:getEquips():length())
					end
				end
			end
		else
			return not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = meispxiaojicard:clone()
			for i = 1, #cards, 1 do
				card:addSubcard(cards[i])
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meispxiaoji"
	end
}

meispxiaoji = sgs.CreateTriggerSkill {
	name = "meispxiaoji",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meispxiaojiskill,
	events = { sgs.CardOffset, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			local dest = effect.to
			if effect.card and effect.card:isKindOf("Slash") and dest:isAlive() then
				if not dest:isNude() then
					local victim = sgs.QVariant()
					victim:setValue(dest)
					if effect.from:askForSkillInvoke(self:objectName(), victim) then
						local card = room:askForCardChosen(effect.from, dest, "he", self:objectName())
						local cd = sgs.Sanguosha:getCard(card)
						dest:addToPile("meispji", cd, true)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:askForUseCard(player, "@@meispxiaoji", "@meispxiaoji-card")
		end
	end
}
--战魂（娘‧吕布）
meispzhanhun = sgs.CreateTriggerSkill {
	name = "meispzhanhun",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			if player:objectName() == use.from:objectName() and (player:getMaxHp() == 4 or player:getHp() == 1) then
				--if player:objectName() == use.from:objectName() then
				local log = sgs.LogMessage()
				log.type = "#meispzhanhun"
				log.from = player
				log.arg = self:objectName()
				local x = 0
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if use.from:canSlash(p, use.card, false) and p:getPile("meispji"):length() > 0 then
						use.to:append(p)
						log.to:append(p)
						x = x + 1
					end
				end
				if x > 0 then
					room:sendLog(log)
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			end
		end
	end
}
--蹂躏（娘‧吕布）
meisproulinIntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

meisproulin = sgs.CreateTriggerSkill {
	name = "meisproulin",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) and (use.from:getMaxHp() == 3 or use.from:getHp() == 1) then
			--if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName())then
			local log = sgs.LogMessage()
			log.type = "#meisproulin"
			log.from = player
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if p:getPile("meispji"):length() > 0 then
					jink_table[index] = 1 + p:getPile("meispji"):length()
					log.to:append(p)
					log.arg  = self:objectName()
					log.arg2 = p:getPile("meispji"):length() + 1
					room:sendLog(log)
				end
				index = index + 1
			end

			--[[local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = x+1
					end
				end]]
			local jink_data = sgs.QVariant()
			jink_data:setValue(meisproulinIntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--掷戟（娘‧吕布）
meispzhijicard = sgs.CreateSkillCard {
	name = "meispzhijicard",
	will_throw = false,

	filter = function(self, targets, to_select)
		local Piles = to_select:getPileNames()
		for i = 1, #Piles do
			local length = to_select:getPile(Piles[i]):length()
			if length > 0 and to_select:objectName() ~= sgs.Self:objectName() then return true end
		end
	end,

	feasible = function(self, targets)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		local x = 0
		local Piles = targets[1]:getPileNames()
		for i = 1, #Piles do
			local length = targets[1]:getPile(Piles[i]):length()
			x = x + length
		end
		if targets[1]:getHandcardNum() + targets[1]:getEquips():length() > x then
			room:askForDiscard(targets[1], self:objectName(), x, x, false, true)
		else
			targets[1]:throwAllCards()
		end
	end
}

meispzhijiskill = sgs.CreateViewAsSkill {
	name = "meispzhiji",
	n = 0,

	view_as = function(self, cards)
		return meispzhijicard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meispzhiji"
	end
}

meispzhiji = sgs.CreateTriggerSkill {
	name = "meispzhiji",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meispzhijiskill,
	events = { sgs.Damage, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and (damage.from:getMaxHp() == 2 or damage.from:getHp() == 1) and damage.to:isAlive() then
				--if damage.from and damage.from:hasSkill(self:objectName()) and damage.to:isAlive() then
				local dest = sgs.QVariant()
				dest:setValue(damage.to)
				if damage.from:askForSkillInvoke(self:objectName(), dest) then
					damage.to:drawCards(2)
					local Piles = damage.to:getPileNames()
					for i = 1, #Piles do
						--damage.to:removePileByName(Piles[i])
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:deleteLater()
						for _, cd in sgs.qlist(damage.to:getPile(Piles[i])) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil,
							self:objectName(), "")
						room:throwCard(dummy, reason, nil)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and (player:getMaxHp() == 2 or player:getHp() == 1) then
			--elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			room:askForUseCard(player, "@@meispzhiji", "@meispzhiji-card")
		end
	end
}
--娘-吕布-体力上限选择（娘‧吕布）
meispnianglvbumaxhp = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meispnianglvbumaxhp",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getMaxHp()
		local choices = "cancel"
		if player:getMaxHp() > 2 then
			choices = choices .. "+2"
		end
		if player:getMaxHp() > 3 then
			choices = choices .. "+3"
		end
		if player:getMaxHp() > 4 then
			choices = choices .. "+4"
		end
		local choice = room:askForChoice(player, "meispnianglvbumaxhp", choices)
		if choice ~= "cancel" then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(choice))
			local y = player:getMaxHp()
			local z = x - y
			player:drawCards(z + z)
		end
	end
}
--珠联璧合 — 娘-吕布
meispnianglvbuzhulianbihe = sgs.CreateTriggerSkill {
	name = "#meispnianglvbuzhulianbihe",
	frequency = sgs.Skill_Limited,
	priority = 2,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getGeneralName() == "meispdiaochan" and player:getGeneral2Name() == "meispnianglvbu") or (player:getGeneral2Name() == "meispdiaochan" and player:getGeneralName() == "meispnianglvbu") then
			room:detachSkillFromPlayer(player, "meispshuzhuang")
			room:detachSkillFromPlayer(player, "meispbaiyue")
			room:detachSkillFromPlayer(player, "meispxiaoji")
			room:detachSkillFromPlayer(player, "meispzhanhun")
			room:detachSkillFromPlayer(player, "meisproulin")
			room:detachSkillFromPlayer(player, "meispzhiji")
			room:handleAcquireDetachSkills(player, "meispzlbhbaiyue")
			room:handleAcquireDetachSkills(player, "meispzlbhshuzhuang")
			local log = sgs.LogMessage()
			log.type  = "#meispnianglvbuzhulianbihe1"
			log.from  = player
			log.arg   = "meispnianglvbuzhulianbihe1"
			log.arg2  = 1
			room:sendLog(log)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
		end
	end
}

meispnianglvbu:addSkill(meispnianglvbuzhulianbihe)
meispnianglvbu:addSkill(meispxiaoji)
meispnianglvbu:addSkill(meispzhanhun)
meispnianglvbu:addSkill(meisproulin)
meispnianglvbu:addSkill(meispzhiji)
meispnianglvbu:addSkill(meispnianglvbumaxhp)

sgs.LoadTranslationTable {
	["meispnianglvbu"] = "娘-吕布",
	["&meispnianglvbu"] = "吕布",
	["#meispnianglvbu"] = "虎牢关战姬",
	["designer:meispnianglvbu"] = "Mark1469",
	["illustrator:meispnianglvbu"] = "大戦乱!!三国志バトル",
	["meispnianglvbumaxhp"] = "娘-吕布-体力上限选择",
	["meispnianglvbumaxhp:2"] = "体力上限：2",
	["meispnianglvbumaxhp:3"] = "体力上限：3",
	["meispnianglvbumaxhp:4"] = "体力上限：4",
	["meispxiaoji"] = "虓姬",
	["meispji"] = "戟",
	["meispxiaojicard"] = "虓姬",
	["@meispxiaoji-card"] = "请选择“虓姬”的目标",
	["~meispxiaoji"] = "选择一名其他角色→点击确定",
	[":meispxiaoji"] = "你使用的【杀】被目标角色的【闪】抵消后，你可以将该角色的一张牌置于其武将牌上，称为“戟”。准备阶段开始时，你可以选择一名其他角色，并选择一项：弃置其武将牌上任意数量的“戟”，并获得其等量的牌；或将一张手牌置于其武将牌上，称为“戟”。",
	["meispzhanhun"] = "战魂",
	["#meispzhanhun"] = "%from的技能【%arg】被触发，%to被额外指定为目标。",
	[":meispzhanhun"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】指定目标后，若你的体力上限为4或体力值为1，所有武将牌上有“戟”的角色将被额外指定为目标。",
	["meisproulin"] = "蹂躏",
	["#meisproulin"] = "%from的技能【%arg】被触发，%to需要 %arg2 张【闪】才能抵消此【杀】。",
	[":meisproulin"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定目标角色后，若你的体力上限为3或体力值为1，该角色需依次使用X+1张【闪】 才能抵消。 （X为目标角色“戟”的数量之和）。",
	["meispzhiji"] = "掷戟",
	["meispzhijicard"] = "掷戟",
	["@meispzhiji-card"] = "请选择“掷戟”的目标",
	["~meispzhiji"] = "选择一名其他角色→点击确定",
	[":meispzhiji"] = "每当你使用【杀】对目标角色造成一次伤害后，若你的体力上限为2或体力值为1，你可以令该角色摸两张牌，然后弃置武将牌上的所有牌；出牌阶段开始时，你可以令一名其他角色弃置X张牌（X为该角色武将牌上的牌数量）。",
	["#meispnianglvbuzhulianbihe1"] = "【%arg】加成效果被触发，%from增加了%arg2点体力上限。",
	["meispnianglvbuzhulianbihe1"] = "珠联璧合",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--MEIBoss 001 董白
meizlbossdongbai  = sgs.General(extension, "meizlbossdongbai", "qun", 10, false, true, true)
--奢华（魔王‧董白）
meizlbossshehua   = sgs.CreateTriggerSkill {
	name = "meizlbossshehua",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			if damage.nature == sgs.DamageStruct_Normal then
				local log = sgs.LogMessage()
				log.type = "#meizlbossshehua1"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				return true
			else
				local x       = damage.from:distanceTo(player)
				damage.damage = damage.damage - x
				local log     = sgs.LogMessage()
				log.type      = "#meizlbossshehua2"
				log.from      = player
				log.arg       = self:objectName()
				log.arg2      = tonumber(damage.damage)
				room:sendLog(log)
				if damage.damage < 1 then
					return true
				end
				data:setValue(damage)
			end
		elseif event == sgs.DamageCaused and damage.nature ~= sgs.DamageStruct_Normal then
			local x       = damage.to:distanceTo(player)
			damage.damage = damage.damage + x
			local log     = sgs.LogMessage()
			log.type      = "#meizlbossshehua3"
			log.from      = player
			log.arg       = self:objectName()
			log.arg2      = tonumber(damage.damage)
			room:sendLog(log)
			data:setValue(damage)
		end
	end
}
--血殇（魔王‧董白）
meizlbossxueshang = sgs.CreateTriggerSkill
	{
		name = "meizlbossxueshang",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
				local x = 10000
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHp() < x then
						x = p:getHp()
					end
				end
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHp() == x then
						targets:append(p)
					end
					if targets:length() > 1 then
						return false
					end
				end
				local target = targets:first()
				if target then
					local log = sgs.LogMessage()
					log.type = "#meizlbossxueshang"
					log.from = player
					log.to:append(target)
					log.arg = self:objectName()
					room:sendLog(log)
					room:killPlayer(target)
				end
			end
		end
	}
--魔嗣（魔王‧董白）
meizlbossmosi     = sgs.CreateTriggerSkill
	{
		name = "meizlbossmosi",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
				local log = sgs.LogMessage()
				log.type = "#meizlbossmosi"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = 1
				room:sendLog(log)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHandcardNum() > player:getHp() then
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = p
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Fire
						room:damage(damage)
					end
				end
			end
		end
	}
--特别效果（魔王‧董白）
meizlbossskill    = sgs.CreateTriggerSkill {
	name = "#meizlbossskill",
	events = { sgs.EventPhaseStart, sgs.BeforeGameOverJudge },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			if event == sgs.EventPhaseStart and splayer:getPhase() == sgs.Player_Start then
				if splayer:getHp() <= 5 and splayer:getMark("meizlbossskill1") == 0 and splayer:aliveCount() < 10 then
					room:doLightbox("$meizlbossskill1animate", 5000)
					local log = sgs.LogMessage()
					log.type = "#meizlbossskill1"
					room:sendLog(log)
					for _, p in sgs.qlist(room:getAllPlayers(true)) do
						if p:isDead() then
							room:revivePlayer(p)
							room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(1))
							room:setPlayerProperty(p, "hp", sgs.QVariant(1))
						end
					end
					room:updateStateItem()
					room:setPlayerMark(splayer, "meizlbossskill1", 1)
				elseif splayer:getHp() <= 1 and splayer:getMark("meizlbossskill2") == 0 and splayer:aliveCount() < 10 then
					room:doLightbox("$meizlbossskill2animate", 5000)
					local log = sgs.LogMessage()
					log.type = "#meizlbossskill2"
					room:sendLog(log)
					for _, p in sgs.qlist(room:getAllPlayers(true)) do
						if p:isDead() then
							room:revivePlayer(p)
							room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(2))
							room:setPlayerProperty(p, "hp", sgs.QVariant(2))
						end
					end
					room:updateStateItem()
					room:setPlayerMark(splayer, "meizlbossskill2", 1)
				elseif splayer:getHp() <= 3 and splayer:getMark("meizlbossskill3") == 0 then
					room:doLightbox("$meizlbossskill3animate", 5000)
					local log = sgs.LogMessage()
					log.type = "#meizlbossskill3"
					room:sendLog(log)
					for _, p in sgs.qlist(room:getOtherPlayers(splayer)) do
						if p:getRole() == "rebel" then
							room:loseMaxHp(p, 1)
						end
					end
					room:setPlayerMark(splayer, "meizlbossskill3", 1)
				elseif splayer:aliveCount() <= 6 and splayer:getMark("meizlbossskill4") == 0 then
					room:doLightbox("$meizlbossskill4animate", 5000)
					local log = sgs.LogMessage()
					log.type = "#meizlbossskill4"
					room:sendLog(log)
					room:loseMaxHp(splayer, 5)
					room:setPlayerMark(splayer, "meizlbossskill4", 1)
				end
			elseif event == sgs.BeforeGameOverJudge then
				local death = data:toDeath()
				room:setPlayerProperty(death.who, "role", sgs.QVariant("rebel"))
				room:updateStateItem()
			end
		end
	end
}

meizlbossdongbai:addSkill(meizlbossshehua)
meizlbossdongbai:addSkill(meizlbossxueshang)
meizlbossdongbai:addSkill(meizlbossmosi)
meizlbossdongbai:addSkill(meizlbossskill)
sgs.LoadTranslationTable {
	["sevenangel"] = "七天使",
	["sevendevil"] = "魔界七将",
	["meizlbossdongbai"] = "魔王‧董白",
	["&meizlbossdongbai"] = "董白",
	["designer:meizlbossdongbai"] = "Mark1469",
	["illustrator:meizlbossdongbai"] = "",
	["cv:meizlbossdongbai"] = "",
	["#meizlbossdongbai"] = "魔姬",
	["meizlbossshehua"] = "奢华",
	["#meizlbossshehua1"] = "%from的技能【%arg】触发，防止了非属性伤害。",
	["#meizlbossshehua2"] = "%from的技能【%arg】触发，受到的伤害变为%arg2点。",
	["#meizlbossshehua3"] = "%from的技能【%arg】触发，造成的伤害变为%arg2点。",
	[":meizlbossshehua"] = "<font color=\"blue\"><b>锁定技，</b></font>当你受到其他角色造成的伤害时，此伤害-X；你防止你受到的非属性伤害；你造成的属性伤害+X（X为该角色与你的距离）。",
	["meizlbossxueshang"] = "血殇",
	["#meizlbossxueshang"] = "%from的技能【%arg】触发，体力值最少的其他角色（%to）立即死亡。",
	[":meizlbossxueshang"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，除你以外体力值最少的其他角色立即死亡。",
	["meizlbossmosi"] = "魔嗣",
	["#meizlbossmosi"] = "%from的技能【%arg】触发，所有手牌数大于%from当前体力值的角色将受到%from造成的%arg2点火焰伤害。",
	[":meizlbossmosi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，所有手牌数大于你体力值的其他角色各受到你造成的1点火焰伤害。",
	["#meizlbossskill1"] = "特别效果【还魂术】触发，所有已死亡的武将复活并变为魔王‧董白的仆人。",
	["$meizlbossskill1animate"] = "image=image/animate/meizlbossskill1.png",
	["#meizlbossskill2"] = "特别效果【咒‧还魂术】触发，所有已死亡的武将复活并变为魔王‧董白忠诚的仆人。",
	["$meizlbossskill2animate"] = "image=image/animate/meizlbossskill2.png",
	["$meizlbossskill3animate"] = "image=image/animate/meizlbossskill3.png",
	["$meizlbossskill4animate"] = "image=image/animate/meizlbossskill4.png",
	["#meizlbossskill3"] = "特别效果【冤魂的诅咒】触发，所有讨伐军受到诅咒。",
	["#meizlbossskill4"] = "特别效果【圣之制裁】触发，魔王‧董白遭到制裁。",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--魔界七将系列
--MEISE 001 魔界七将‧玛门‧郭女王
meizlseguonvwang   = sgs.General(extension, "meizlseguonvwang", "sevendevil", 6, false, false)
--掠夺（魔界七将‧玛门‧郭女王）
meizlselueduo      = sgs.CreateTriggerSkill {
	name = "meizlselueduo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
		for _, splayer in sgs.qlist(allplayers) do
			if player:getPhase() == sgs.Player_Draw and player:objectName() ~= splayer:objectName() then
				if player:getHandcardNum() > player:getHp() then
					local dest = sgs.QVariant()
					dest:setValue(player)
					if splayer:askForSkillInvoke(self:objectName(), dest) then
						if splayer:getMark("@meizlsetanlan") > 0 then
							if not room:askForCard(splayer, ".Trick", "@meizlselueduo", sgs.QVariant(), self:objectName()) then
								return false
							end
						else
							room:loseHp(splayer, 1)
						end
						local x = player:getHandcardNum() - player:getHp()
						local card = room:askForExchange(player, self:objectName(), x, x, true, "@meizlselueduocard",
							false)
						room:obtainCard(splayer, card, false)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
--贪婪（魔界七将‧玛门‧郭女王）
meizlsetanlancard  = sgs.CreateSkillCard {
	name = "meizlsetanlancard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:loseMaxHp(source, 1)
		source:gainMark("@meizlsetanlan")
		room:changeTranslation(source, "meizlselueduo", 2)
	end
}
meizlsetanlanskill = sgs.CreateViewAsSkill {
	name = "meizlsetanlan",
	n = 0,
	view_as = function(self, cards)
		local card = meizlsetanlancard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlsetanlan") == 0 and player:getHp() <= 2
	end
}
meizlsetanlan      = sgs.CreateTriggerSkill {
	name = "meizlsetanlan",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlsetanlanskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}
--诱杀（魔界七将‧玛门‧郭女王）
meizlseyoushacard  = sgs.CreateSkillCard {
	name = "meizlseyoushacard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:isMale() and #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		--[[local damage = sgs.DamageStruct()
damage.from = targets[2]
damage.to = targets[1]
damage.damage = 1
room:damage(damage)]]
		room:damage(sgs.DamageStruct("meizlseyousha", targets[2], targets[1], 1, sgs.DamageStruct_Normal))
		if targets[2]:isAlive() then
			--local damage = sgs.DamageStruct()
			if targets[1]:isAlive() then
				--damage.from = targets[1]
				room:damage(sgs.DamageStruct("meizlseyousha", targets[1], targets[2], 1, sgs.DamageStruct_Normal))
			else
				--damage.from = nil
				room:damage(sgs.DamageStruct("meizlseyousha", nil, targets[2], 1, sgs.DamageStruct_Normal))
			end
			--damage.to = targets[2]
			--damage.damage = 1
			--room:damage(damage)
		end
	end
}

meizlseyousha      = sgs.CreateViewAsSkill {
	name = "meizlseyousha",
	n = 1,

	view_filter = function(self, selected, to_select)
		return not to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlseyoushacard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlseyoushacard")
	end,
}

meizlseguonvwang:addSkill(meizlselueduo)
meizlseguonvwang:addSkill(meizlseyousha)
meizlseguonvwang:addSkill(meizlsetanlan)

sgs.LoadTranslationTable {
	["meizlseguonvwang"] = "魔界七将‧玛门‧郭女王",
	["&meizlseguonvwang"] = "郭女王",
	["designer:meizlseguonvwang"] = "Mark1469",
	["illustrator:meizlseguonvwang"] = "双剣のクロスエイジ",
	["cv:meizlseguonvwang"] = "",
	["#meizlseguonvwang"] = "错误之神",
	["meizlselueduo"] = "掠夺",
	["@meizlselueduo"] = "你可以弃置一张锦囊牌，然后发动“掠夺”后续技能",
	["@meizlselueduocard"] = "请交给魔界七将‧玛门‧郭女王X张手牌（X为该角色的手牌数与体力值之差）",
	[":meizlselueduo"] = "其他角色的摸牌阶段结束时，若其手牌数大于体力值，你可以失去1点体力，然后令该角色交给你X张手牌（X为该角色的手牌数与体力值之差）。",
	[":meizlselueduo2"] = "其他角色的摸牌阶段结束时，若其手牌数大于体力值，你可以弃置一张锦囊牌，然后令该角色交给你X张手牌（X为该角色的手牌数与体力值之差）。",
	["meizlseyousha"] = "诱杀",
	["meizlseyoushacard"] = "诱杀",
	[":meizlseyousha"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张非基本牌并选择两名男性角色，视为这两名角色各对对方造成1点伤害。",
	["@meizlsetanlan"] = "贪婪",
	["meizlsetanlan"] = "贪婪",
	["meizlsetanlancard"] = "贪婪",
	[":meizlsetanlan"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，若你的体力值为2或更低，你可以减1点体力上限，并将“掠夺”描述中的“失去1点体力”改为“弃置一张锦囊牌”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 002 魔界七将‧萨麦尔‧董白
meizlsedongbai     = sgs.General(extension, "meizlsedongbai", "sevendevil", 10, false, false)
--炼狱（魔界七将‧萨麦尔‧董白）
meizlselianyucard  = sgs.CreateSkillCard {
	name = "meizlselianyucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlselianyu")
		local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		slash:setSkillName("meizlselianyu")
		local card_use = sgs.CardUseStruct()
		card_use.from = source
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:canSlash(p, nil, false) then
				card_use.to:append(p)
			end
		end
		card_use.card = slash
		room:useCard(card_use, true)
	end
}
meizlselianyuskill = sgs.CreateViewAsSkill {
	name = "meizlselianyu",
	n = 0,
	view_as = function(self, cards)
		return meizlselianyucard:clone()
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and
			(player:getMark("@meizlselianyu") > 0 or player:getMark("@meizlsebaonu") > 0) and
			not player:hasUsed("#meizlselianyucard")
	end
}
meizlselianyu      = sgs.CreateTriggerSkill {
	name = "meizlselianyu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlselianyuskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getKingdom() == "sevendevil" then
				x = x + 1
			end
		end
		player:gainMark("@meizlselianyu", x)
	end
}
--灭绝（魔界七将‧萨麦尔‧董白）
meizlsemiejue      = sgs.CreateTriggerSkill {
	name = "meizlsemiejue",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:objectName() ~= damage.from:objectName() and damage.nature ~= sgs.DamageStruct_Normal then
				local x = damage.damage
				damage.damage = damage.to:getHp() - 1
				if damage.damage <= 0 then
					damage.damage = 1
				end
				local y = damage.damage
				if y > x then
					local log = sgs.LogMessage()
					log.type = "#skill_add_damage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg  = self:objectName()
					log.arg2 = damage.damage
					room:sendLog(log)
				end
				data:setValue(damage)
			end
		elseif event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:loseMaxHp(p, 1)
			end
		end
	end
}
--暴怒（魔界七将‧萨麦尔‧董白）
meizlsebaonucard   = sgs.CreateSkillCard {
	name = "meizlsebaonucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:detachSkillFromPlayer(source, "meizlsemiejue")
		source:gainMark("@meizlsebaonu")
		room:changeTranslation(source, "meizlselianyu", 2)
	end
}
meizlsebaonuskill  = sgs.CreateViewAsSkill {
	name = "meizlsebaonu",
	n = 0,
	view_as = function(self, cards)
		local card = meizlsebaonucard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlsebaonu") == 0 and player:isKongcheng()
	end
}
meizlsebaonu       = sgs.CreateTriggerSkill {
	name = "meizlsebaonu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlsebaonuskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlsedongbai:addSkill(meizlselianyu)
meizlsedongbai:addSkill(meizlsemiejue)
meizlsedongbai:addSkill(meizlsebaonu)

sgs.LoadTranslationTable {
	["meizlsedongbai"] = "魔界七将‧萨麦尔‧董白",
	["&meizlsedongbai"] = "董白",
	["designer:meizlsedongbai"] = "Mark1469",
	["illustrator:meizlsedongbai"] = "双剣のクロスエイジ",
	["cv:meizlsedongbai"] = "",
	["#meizlsedongbai"] = "暴怒魔王",
	["meizlselianyu"] = "炼狱",
	["meizlselianyucard"] = "炼狱",
	["@meizlselianyu"] = "炼狱",
	[":meizlselianyu"] = "每局游戏限X次，<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以视为对所有其他角色使用了一张火【杀】（X为游戏开始时的魔界七将势力角色数）。",
	[":meizlselianyu2"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以视为对所有其他角色使用了一张火【杀】。",
	["meizlsemiejue"] = "灭绝",
	[":meizlsemiejue"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，所有其他角色减1点体力上限；当你对其他角色造成属性伤害时，该伤害为X(X为该角色的体力值-1且至少为1)。",
	["meizlsebaonu"] = "暴怒",
	["@meizlsebaonu"] = "暴怒",
	["meizlsebaonucard"] = "暴怒",
	[":meizlsebaonu"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，若你没有手牌，你可以失去技能“灭绝”，并去除“炼狱”描述中的“每局游戏限X次”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 003 魔界七将‧利维坦‧张春华
meizlsezhangchunhua       = sgs.General(extension, "meizlsezhangchunhua", "sevendevil", 4, false, false)
--惭恚（魔界七将‧利维坦‧张春华）
meizlsecanhui             = sgs.CreateTriggerSkill {
	name = "meizlsecanhui",
	frequency = sgs.Skill_Frequent,
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				if player:isKongcheng() then return false end
				for _, id in sgs.qlist(player:handCards()) do
					if not move.card_ids:contains(id) then return false end
				end
				if (player:getMaxCards() == 0) and (player:getPhase() == sgs.Player_Discard)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD) then
					player:getRoom():setPlayerFlag(player, "meizlsecanhuiZeroMaxCards")
					return false
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				--if player:askForSkillInvoke(self:objectName(), data) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"meizlsecanhui-invoke", true, true)
				if target then
					room:loseHp(target, 1)
					if player:getMark("@meizlsejidu") > 0 then player:drawCards(1) end
				end
			end
		end
		return false
	end
}
meizlsecanhuiZeroMaxCards = sgs.CreateTriggerSkill {
	name = "#meizlsecanhuiZeroMaxcards",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.from == sgs.Player_Discard) and player:hasFlag("meizlsecanhuiZeroMaxCards") then
			player:getRoom():setPlayerFlag(player, "-meizlsecanhuiZeroMaxCards")
			if player:askForSkillInvoke("meizlsecanhui") then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				room:loseHp(target, 1)
				if player:getMark("@meizlsejidu") > 0 then player:drawCards(1) end
			end
		end
		return false
	end
}
--执爨（魔界七将‧利维坦‧张春华）
meizlsezhicuan            = sgs.CreateTriggerSkill {
	name = "meizlsezhicuan",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if not splayer then return end
		if player:getPhase() ~= sgs.Player_Start then return end
		if player:objectName() == splayer:objectName() then return end
		if player:getHp() <= splayer:getHp() then return end
		room:sendCompulsoryTriggerLog(splayer, self:objectName(), true)
		--[[local damage = sgs.DamageStruct()
damage.from = splayer
damage.to = player
damage.damage = 1
room:damage(damage)]]
		room:damage(sgs.DamageStruct("meizlsezhicuan", splayer, player, 1, sgs.DamageStruct_Normal))
		local recover = sgs.RecoverStruct()
		recover.recover = 1
		recover.who = splayer
		room:recover(splayer, recover)
	end
}
--嫉妒（魔界七将‧利维坦‧张春华）
meizlsejiducard           = sgs.CreateSkillCard {
	name = "meizlsejiducard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:gainMark("@meizlsejidu")
	end
}
meizlsejiduskill          = sgs.CreateViewAsSkill {
	name = "meizlsejidu",
	n = 4,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then
			return to_select:getSuit() == selected[1]:getSuit()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 4 then
			local card = meizlsejiducard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:addSubcard(cards[3])
			card:addSubcard(cards[4])
			card:setSkillName(self:objectName())
			return card
		end
	end,

	enabled_at_play = function(self, player)
		return player:getMark("@meizlsejidu") == 0
	end
}
meizlsejidu               = sgs.CreateTriggerSkill {
	name = "meizlsejidu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlsejiduskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlsezhangchunhua:addSkill(meizlsecanhui)
meizlsezhangchunhua:addSkill(meizlsecanhuiZeroMaxCards)
meizlsezhangchunhua:addSkill(meizlsezhicuan)
meizlsezhangchunhua:addSkill(meizlsejidu)
extension:insertRelatedSkills("meizlsecanhui", "#meizlsecanhuiZeroMaxcards")
sgs.LoadTranslationTable {
	["meizlsezhangchunhua"]             = "魔界七将‧利维坦‧张春华",
	["&meizlsezhangchunhua"]            = "张春华",
	["designer:meizlsezhangchunhua"]    = "Mark1469",
	["illustrator:meizlsezhangchunhua"] = "神魔×継承!ラグナブレイク",
	["cv:meizlsezhangchunhua"]          = "",
	["#meizlsezhangchunhua"]            = "邪恶的象征",
	["meizlsecanhui"]                   = "惭恚",
	[":meizlsecanhui"]                  = "每当你失去最后的手牌后，你可以令一名其他角色失去1点体力。",
	[":meizlsecanhui2"]                 = "每当你失去最后的手牌后，你可以令一名其他角色失去1点体力，然后摸一张牌。",
	["meizlsecanhui-invoke"]            = "你可以发动“惭恚”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlsezhicuan"]                  = "执爨",
	[":meizlsezhicuan"]                 = "<font color=\"blue\"><b>锁定技，</b></font>其他角色的准备阶段开始时，若当前回合角色的体力值大于你，则视为你对该角色造成1点伤害并回复1点体力。",
	["meizlsejidu"]                     = "嫉妒",
	["@meizlsejidu"]                    = "嫉妒",
	["meizlsejiducard"]                 = "嫉妒",
	[":meizlsejidu"]                    = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，你可以弃置四张相同花色的牌，然后增加'惭恚'的描述“你每发动一次'惭恚'便摸一张牌”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 004 魔界七将‧阿斯莫德‧孙鲁班
meizlsesunluban     = sgs.General(extension, "meizlsesunluban", "sevendevil", 4, false, false)
--荡漾（魔界七将‧阿斯莫德‧孙鲁班）
meizlsedangyangcard = sgs.CreateSkillCard {
	name = "meizlsedangyangcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:getMark("@meizlseyinyu") > 0 then
				if not p:isAllNude() then
					local card_id = room:askForCardChosen(source, p, "hej", "meizlsedangyang")
					room:obtainCard(source, card_id, true)
				end
			else
				local card
				if not p:isKongcheng() then
					card = room:askForExchange(p, self:objectName(), 1, 1, false, "meizlsedangyangGive", false)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(),
						source:objectName(), "meizlsedangyang", nil)
					reason.m_playerId = source:objectName()
					room:moveCardTo(card, p, source, sgs.Player_PlaceHand, reason)
				end
			end
		end
	end
}
meizlsedangyang     = sgs.CreateViewAsSkill {
	name = "meizlsedangyang",
	n = 0,
	view_as = function(self, cards)
		local card = meizlsedangyangcard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlsedangyangcard")
	end
}
--妖惑（魔界七将‧阿斯莫德‧孙鲁班）
meizlseyaohuo       = sgs.CreateTriggerSkill
	{
		name = "meizlseyaohuo",
		events = { sgs.Damaged },
		frequency = sgs.Skill_Frequent,
		can_trigger = function(self, player)
			return true
		end,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if splayer and splayer:isWounded() then
					if player:objectName() == splayer:objectName() then continue end
					if damage.nature ~= sgs.DamageStruct_Normal then
						if not room:askForSkillInvoke(splayer, self:objectName()) then continue end
						local recover = sgs.RecoverStruct()
						recover.recover = splayer:getMaxHp() - splayer:getHp()
						recover.who = splayer
						room:recover(splayer, recover)
						splayer:drawCards(4)
						room:setPlayerMark(splayer, "meizlseyaohuo", 1)
					end
				end
			end
		end,
	}
--淫欲（魔界七将‧阿斯莫德‧孙鲁班）
meizlseyinyucard    = sgs.CreateSkillCard {
	name = "meizlseyinyucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:loseMaxHp(source, 1)
		source:gainMark("@meizlseyinyu")
		room:changeTranslation(source, "meizlsedangyang", 2)
	end
}
meizlseyinyuskill   = sgs.CreateViewAsSkill {
	name = "meizlseyinyu",
	n = 0,
	view_as = function(self, cards)
		local card = meizlseyinyucard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlseyinyu") == 0 and player:getMark("meizlseyaohuo") > 0
	end
}
meizlseyinyu        = sgs.CreateTriggerSkill {
	name = "meizlseyinyu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlseyinyuskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlsesunluban:addSkill(meizlsedangyang)
meizlsesunluban:addSkill(meizlseyaohuo)
meizlsesunluban:addSkill(meizlseyinyu)

sgs.LoadTranslationTable {
	["meizlsesunluban"] = "魔界七将‧阿斯莫德‧孙鲁班",
	["&meizlsesunluban"] = "孙鲁班",
	["designer:meizlsesunluban"] = "Mark1469",
	["illustrator:meizlsesunluban"] = "サブロー",
	["cv:meizlsesunluban"] = "",
	["#meizlsesunluban"] = "色欲的魔神",
	["meizlsedangyang"] = "荡漾",
	["meizlsedangyangcard"] = "荡漾",
	[":meizlsedangyang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令所有其他角色交给你一张手牌。",
	[":meizlsedangyang2"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得所有其他角色区域里的一张牌。",
	["meizlsedangyangGive"] = "请交给目标角色1张手牌",
	["meizlseyaohuo"] = "妖惑",
	[":meizlseyaohuo"] = "每当其他角色受到属性伤害时，若你已受伤，你可以回复体力至体力上限，然后摸4张牌。",
	["meizlseyinyu"] = "淫欲",
	["@meizlseyinyu"] = "淫欲",
	["meizlseyinyucard"] = "淫欲",
	[":meizlseyinyu"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，若你已发动技能“妖惑”，你可以减1点体力上限并将“荡漾”描述中的“令所有其他角色交给你一张手牌”改为“获得这些角色区域里的一张牌”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 005 魔界七将‧路西法‧蔡夫人
meizlsecaifuren       = sgs.General(extension, "meizlsecaifuren", "sevendevil", 3, false, false)
--复仇（魔界七将‧路西法‧蔡夫人）
meizlsefuchoumaxcard  = sgs.CreateMaxCardsSkill {
	name = "meizlsefuchoumaxcard&",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill(self:objectName()) then
			for _, p in sgs.qlist(target:getSiblings()) do
				if p:hasSkill("meizlsefuchou") and (target:getHp() > p:getHp() or p:getMark("@meizlseaoman") > 0) then
					x = p:getLostHp()
				end
			end
			return -x
		end
	end
}
meizlsefuchoudrawcard = sgs.CreateTriggerSkill {
	name = "meizlsefuchoudrawcard&",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
				
		local target
		local count
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("meizlsefuchou") then
				target = p
			end
		end
		if target and (player:getHp() > target:getHp() or target:getMark("@meizlseaoman") > 0) then
			local log = sgs.LogMessage()
			log.type = "#skill_add_damage_byother1"
			log.from = target
			log.arg = "meizlsefuchou"
			room:sendLog(log)
			draw.num = math.max(draw.num - target:getLostHp(), 0)
			data:setValue(draw)
		end
	end
}

meizlsefuchou         = sgs.CreateTriggerSkill {
	name = "meizlsefuchou",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:attachSkillToPlayer(p, "meizlsefuchoumaxcard")
			room:handleAcquireDetachSkills(p, "meizlsefuchoudrawcard")
		end
	end

}

meizlsefuchouclear    = sgs.CreateTriggerSkill {
	name = "#meizlsefuchouclear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill, sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlsefuchou" then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:detachSkillFromPlayer(p, "meizlsefuchoumaxcard")
			room:detachSkillFromPlayer(p, "meizlsefuchoudrawcard")
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
--破晓（魔界七将‧路西法‧蔡夫人）
meizlsepoxiaocard     = sgs.CreateSkillCard {
	name = "meizlsepoxiaocard",
	will_throw = false,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isKongcheng() and
			to_select:getMark("@meizlsepoxiaotarget") == 0
	end,


	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], "@meizlsepoxiaotarget", 1)
		local success = source:pindian(targets[1], "meizlsepoxiao", self)
		if success then
			room:setPlayerMark(targets[1], "@meizlsepoxiao", 1)
		end
	end
}

meizlsepoxiaoskill    = sgs.CreateViewAsSkill {
	name = "meizlsepoxiao",
	n = 1,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = meizlsepoxiaocard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#meizlsepoxiaocard") and player:getMark("@meizlseaoman") > 0)
	end
}

meizlsepoxiao         = sgs.CreateTriggerSkill {
	name = "meizlsepoxiao",
	events = { sgs.EventPhaseStart },
	view_as_skill = meizlsepoxiaoskill,
	can_trigger = function()
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if current:getMark("@meizlsepoxiao") > 0 then
					current:skip(sgs.Player_Play)
					room:setPlayerMark(current, "@meizlsepoxiao", 0)
				end
			elseif player:getPhase() == sgs.Player_Finish then
				if current:hasSkill(self:objectName()) then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:setPlayerMark(p, "@meizlsepoxiaotarget", 0)
					end
				end
			end
		end
	end
}
--傲慢（魔界七将‧路西法‧蔡夫人）
meizlseaomancard      = sgs.CreateSkillCard {
	name = "meizlseaomancard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:gainMark("@meizlseaoman")
		room:changeTranslation(source, "meizlsefuchou", 2)
		room:changeTranslation(source, "meizlsepoxiao", 2)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:changeTranslation(p, "meizlsefuchoumaxcard", 2)
			room:changeTranslation(p, "meizlsefuchoudrawcard", 2)
		end
	end
}
meizlseaomanskill     = sgs.CreateViewAsSkill {
	name = "meizlseaoman",
	n = 0,
	view_as = function(self, cards)
		local card = meizlseaomancard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlseaoman") == 0 and player:getHp() == 1
	end
}
meizlseaoman          = sgs.CreateTriggerSkill {
	name = "meizlseaoman",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlseaomanskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

local skills          = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlsefuchoumaxcard") then skills:append(meizlsefuchoumaxcard) end
sgs.Sanguosha:addSkills(skills)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlsefuchoudrawcard") then skills:append(meizlsefuchoudrawcard) end
sgs.Sanguosha:addSkills(skills)
meizlsecaifuren:addSkill(meizlsefuchou)
meizlsecaifuren:addSkill(meizlsefuchouclear)
meizlsecaifuren:addSkill(meizlsepoxiao)
meizlsecaifuren:addSkill(meizlseaoman)
extension:insertRelatedSkills("meizlsefuchou", "#meizlsefuchouclear")
sgs.LoadTranslationTable {
	["meizlsecaifuren"] = "魔界七将‧路西法‧蔡夫人",
	["&meizlsecaifuren"] = "蔡夫人",
	["designer:meizlsecaifuren"] = "Mark1469",
	["illustrator:meizlsecaifuren"] = "神魔×継承!ラグナブレイク",
	["cv:meizlsecaifuren"] = "",
	["#meizlsecaifuren"] = "撒旦之化身",
	["meizlsefuchou"] = "复仇",
	["meizlsefuchoumaxcard"] = "复仇效果 （一）",
	["meizlsefuchoudrawcard"] = "复仇效果 （二）",
	[":meizlsefuchou"] = "<font color=\"blue\"><b>锁定技，</b></font>体力值大于你的角色的手牌上限-X，并于摸牌阶段少摸X张牌（X为你已损失的体力值）。",
	[":meizlsefuchou2"] = "<font color=\"blue\"><b>锁定技，</b></font>其他角色的手牌上限-X，并于摸牌阶段少摸X张牌（X为你已损失的体力值）。",
	[":meizlsefuchoumaxcard"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的体力值大于魔界七将‧路西法‧蔡夫人，你的手牌上限-X（X为蔡夫人已损失的体力值）。",
	[":meizlsefuchoudrawcard"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的体力值大于魔界七将‧路西法‧蔡夫人，你于摸牌阶段少摸X张牌（X为蔡夫人已损失的体力值）。",
	[":meizlsefuchoumaxcard2"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限-X（X为蔡夫人已损失的体力值）。",
	[":meizlsefuchoudrawcard2"] = "<font color=\"blue\"><b>锁定技，</b></font>你于摸牌阶段少摸X张牌（X为蔡夫人已损失的体力值）。",
	["meizlsepoxiao"] = "破晓",
	["meizlsepoxiaocard"] = "破晓",
	[":meizlsepoxiao"] = "<font color=\"green\"><b>出牌阶段对每名角色限一次，</b></font>你可以与一名其他角色拼点。若你赢，该角色跳过其下一个出牌阶段。",
	[":meizlsepoxiao2"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点。若你赢，该角色跳过其下一个出牌阶段。",
	["meizlseaoman"] = "傲慢",
	["@meizlseaoman"] = "傲慢",
	["meizlseaomancard"] = "傲慢",
	[":meizlseaoman"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，若你的体力值为1，你可以将“破晓”描述中的“<font color=\"green\"><b>出牌阶段对每名角色限一次</b></font>”改为“<font color=\"green\"><b>出牌阶段限一次</b></font>”。并将“复仇”描述中的“体力值大于你的角色”改为“其他角色”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 006 魔界七将‧别西卜‧吕玲琦
meizlselvlingqi    = sgs.General(extension, "meizlselvlingqi", "sevendevil", 8, false, false)
--避讳（魔界七将‧别西卜‧吕玲琦）
meizlsebihui       = sgs.CreateTargetModSkill {
	name = "meizlsebihui",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHandcardNum() <= player:getMaxHp() then
			return 2
		end
	end,
}
--君王（魔界七将‧别西卜‧吕玲琦）
Table2IntList      = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
meizlsejunwang     = sgs.CreateTriggerSkill {
	name = "meizlsejunwang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getLostHp()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if player:objectName() ~= damage.to:objectName() and player:isWounded() then
				if (player:distanceTo(damage.to) <= 1) or (player:getMark("@meizlsebaoshi") > 0 and player:distanceTo(damage.to) <= x) then
					local log = sgs.LogMessage()
					log.type = "#Meizlsejunwangdamage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg  = tonumber(damage.damage)
					log.arg2 = tonumber(damage.damage + x)
					room:sendLog(log)
					damage.damage = damage.damage + x
					data:setValue(damage)
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:hasSkill(self:objectName()) then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					if player:distanceTo(p) <= x then
						jink_table[index] = 0
						local log = sgs.LogMessage()
						log.type = "#skill_cant_jink"
						log.from = player
						log.to:append(p)
						log.arg = self:objectName()
						room:sendLog(log)
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
				return false
			end
		end
	end
}
--暴食（魔界七将‧别西卜‧吕玲琦）
meizlsebaoshicard  = sgs.CreateSkillCard {
	name = "meizlsebaoshicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:gainMark("@meizlsebaoshi")
		room:changeTranslation(source, "meizlsejunwang", 2)
	end
}
meizlsebaoshiskill = sgs.CreateViewAsSkill {
	name = "meizlsebaoshi",
	n = 4,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 4 then
			local card = meizlsebaoshicard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:addSubcard(cards[3])
			card:addSubcard(cards[4])
			card:setSkillName(self:objectName())
			return card
		end
	end,

	enabled_at_play = function(self, player)
		return player:getMark("@meizlsebaoshi") == 0
	end
}
meizlsebaoshi      = sgs.CreateTriggerSkill {
	name = "meizlsebaoshi",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlsebaoshiskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlselvlingqi:addSkill(meizlsebihui)
meizlselvlingqi:addSkill(meizlsejunwang)
meizlselvlingqi:addSkill(meizlsebaoshi)

sgs.LoadTranslationTable {
	["meizlselvlingqi"] = "魔界七将‧别西卜‧吕玲琦",
	["&meizlselvlingqi"] = "吕玲琦",
	["designer:meizlselvlingqi"] = "Mark1469",
	["illustrator:meizlselvlingqi"] = "神魔×継承!ラグナブレイク",
	["cv:meizlselvlingqi"] = "",
	["#meizlselvlingqi"] = "鬼王",
	["meizlsebihui"] = "避讳",
	[":meizlsebihui"] = "若你的手牌数少于或等于体力上限，当你使用【杀】时，你可以额外选择两个目标。",
	["meizlsejunwang"] = "君王",
	[":meizlsejunwang"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离X以内的其他角色不能使用【闪】响应你对其使用的【杀】；你对距离1以内的其他角色造成的伤害+X（X为你已损失的体力值） 。",
	[":meizlsejunwang2"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离X以内的其他角色不能使用【闪】响应你对其使用的【杀】；你对距离X以内的其他角色造成的伤害+X（X为你已损失的体力值） 。",
	["#Meizlsejunwangdamage"] = "%from的技能【<font color=\"yellow\"><b>君王</b></font>】被触发，%from对%to造成的伤害由%arg点至增加至%arg2点。",
	["meizlsebaoshi"] = "暴食",
	["@meizlsebaoshi"] = "暴食",
	["meizlsebaoshicard"] = "暴食",
	[":meizlsebaoshi"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，你可以弃置四张装备牌，然后将“君王”描述中的“你对距离1以内的其他角色造成的伤害+X”改为“你对距离X以内的其他角色造成的伤害+X”。",
}
------------------------------------------------------------------------------------------------------------------------------
--MEISE 007 魔界七将‧贝尔芬格‧大乔
meizlsedaqiao      = sgs.General(extension, "meizlsedaqiao", "sevendevil", 5, false, false)
--肆意（魔界七将‧贝尔芬格‧大乔）
meizlsesiyi        = sgs.CreateTriggerSkill {
	name = "meizlsesiyi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				local room = player:getRoom()
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					if player:askForSkillInvoke(self:objectName(), data) then
						local x = 0
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getKingdom() == "sevendevil" then
								x = x + 1
							end
						end
						player:drawCards(x)
					end
				end
			end
		end
	end
}
--嫉俗（魔界七将‧贝尔芬格‧大乔）
meizlsejisu        = sgs.CreateTriggerSkill {
	name = "meizlsejisu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local invoke = false
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getMark("@meizlselanduo") > 0 then
					p:throwAllCards()
					invoke = true
				elseif p:getHp() > player:getHp() then
					p:throwAllEquips()
					invoke = true
				end
			end
			if invoke then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			end
		end
	end
}
--懒惰（魔界七将‧贝尔芬格‧大乔）
meizlselanduocard  = sgs.CreateSkillCard {
	name = "meizlselanduocard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:throwAllHandCards()
		source:gainMark("@meizlselanduo")
		room:changeTranslation(source, "meizlsejisu", 2)
	end
}
meizlselanduoskill = sgs.CreateViewAsSkill {
	name = "meizlselanduo",
	n = 0,
	view_as = function(self, cards)
		return meizlselanduocard:clone()
	end,

	enabled_at_play = function(self, player)
		return player:getHandcardNum() >= 10 and player:getMark("@meizlselanduo") == 0
	end
}
meizlselanduo      = sgs.CreateTriggerSkill {
	name = "meizlselanduo",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlselanduoskill,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlsedaqiao:addSkill(meizlsejisu)
meizlsedaqiao:addSkill(meizlsesiyi)
meizlsedaqiao:addSkill(meizlselanduo)

sgs.LoadTranslationTable {
	["meizlsedaqiao"] = "魔界七将‧贝尔芬格‧大乔",
	["&meizlsedaqiao"] = "大乔",
	["designer:meizlsedaqiao"] = "Mark1469",
	["illustrator:meizlsedaqiao"] = "神魔×継承!ラグナブレイク",
	["cv:meizlsedaqiao"] = "",
	["#meizlsedaqiao"] = "亚述的魔神",
	["meizlsejisu"] = "嫉俗",
	[":meizlsejisu"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段开始时，体力值大于你的角色弃置所有装备牌。",
	[":meizlsejisu2"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段开始时，其他角色弃置所有牌。",
	["meizlsesiyi"] = "肆意",
	[":meizlsesiyi"] = "你的回合外，每当你失去牌后，你可以摸X张牌（X为当前的魔界七将势力角色数）。",
	["meizlselanduo"] = "懒惰",
	["@meizlselanduo"] = "懒惰",
	["meizlselanduocard"] = "懒惰",
	[":meizlselanduo"] = "<font color=\"magenta\"><b>强化技，</b></font>出牌阶段，若你的手牌数为10或更多时，你可以弃置所有手牌，并将“嫉俗”描述中的“体力值大于你的角色弃置所有装备牌”改为“其他角色弃置所有牌”。",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--升华系列
meizlshdaqiao = sgs.General(extension, "meizlshdaqiao", "wu", 3, false, true, true)
meizlshcaiwenji = sgs.General(extension, "meizlshcaiwenji", "qun", 3, false, true, true)
meizlshyangwan = sgs.General(extension, "meizlshyangwan", "shu", 3, false, true, true)
meizlshfanshi = sgs.General(extension, "meizlshfanshi", "qun", 3, false, true, true)
meizlshxiaoqiao = sgs.General(extension, "meizlshxiaoqiao", "wu", 3, false, true, true)
meizlshmayunlu = sgs.General(extension, "meizlshmayunlu", "shu", 3, false, true, true)
meizlshlvlingqi = sgs.General(extension, "meizlshlvlingqi", "qun", 3, false, true, true)
meizlshmifuren = sgs.General(extension, "meizlshmifuren", "shu", 3, false, true, true)
meispshniangzhaoyun = sgs.General(extension, "meispshniangzhaoyun", "shu", 3, false, true, true)

meizlshchunshencard = sgs.CreateSkillCard {
	name = "meizlshchunshencard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		if to_select:objectName() ~= player:objectName() then
			if to_select:getHp() >= player:getHp() then
				return player:distanceTo(to_select) == 1
			end
		end
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		local tag = room:getTag("meizlshchunshenDamage")
		local damage = tag:toDamage()
		damage.to = target
		damage.transfer = true
		room:damage(damage)
		effect.from:gainMark("@meizldaqiaomark", 2)
	end
}
meizlshchunshenskill = sgs.CreateViewAsSkill {
	name = "meizlshchunshen",
	n = 0,
	view_as = function(self, cards)
		return meizlshchunshencard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@meizlshchunshen"
	end
}
meizlshchunshen = sgs.CreateTriggerSkill {
	name = "meizlshchunshen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	view_as_skill = meizlshchunshenskill,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local value = sgs.QVariant()
		value:setValue(damage)
		room:setTag("meizlshchunshenDamage", value)
		if room:askForUseCard(player, "@@meizlshchunshen", "@meizlshchunshen-card") then
			return true
		end
	end
}

meizlshjinlian = sgs.CreateTriggerSkill {
	name = "meizlshjinlian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				local room = player:getRoom()
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					if player:askForSkillInvoke(self:objectName(), data) then
						player:drawCards(2)
						player:gainMark("@meizldaqiaomark")
					end
				end
			end
		end
	end
}

meizlluoyingbinfencard = sgs.CreateSkillCard {
	name = "meizlluoyingbinfencard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		if source:getMark("@meizldaqiaomark") >= 15 then
			source:loseMark("@meizldaqiaomark", 15)
		else
			source:loseMark("@meizlxiaoqiaomark", 15)
		end
		local allplayers = room:getAllPlayers()
		room:sortByActionOrder(allplayers)
		for _, p in sgs.qlist(allplayers) do
			if p:isMale() then
				local damage = sgs.DamageStruct()
				damage.from = p
				damage.to = p
				damage.damage = p:getHandcardNum()
				room:damage(damage)
			end
		end
	end
}
meizlluoyingbinfen = sgs.CreateViewAsSkill {
	name = "meizlluoyingbinfen",
	n = 0,
	view_as = function(self, cards)
		return meizlluoyingbinfencard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizldaqiaomark")
		local counts = player:getMark("@meizlxiaoqiaomark")
		return count >= 15 or counts >= 15
	end
}

meizlshhujiacard = sgs.CreateSkillCard {
	name = "meizlshhujiacard",
	will_throw = false,


	filter = function(self, targets, to_select, player)
		return player:canPindian(to_select) and to_select:objectName() ~= player:objectName() and (#targets == 0)
	end,

	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "meizlshhujia", nil)
		if success then
			room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
		end
		source:gainMark("@meizlcaiwenjimark")
	end
}

meizlshhujia = sgs.CreateViewAsSkill {
	name = "meizlshhujia",
	n = 0,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = meizlshhujiacard:clone()
			--card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#meizlshhujiacard")
	end,
}

meizlshguihancard = sgs.CreateSkillCard {
	name = "meizlshguihancard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlshguihan")
		local x = room:alivePlayerCount()
		source:drawCards(x + 2)
		if x + 2 < 8 then
			local recover = sgs.RecoverStruct()
			recover.recover = source:getMaxHp() - source:getHp()
			recover.who = source
			room:recover(source, recover)
		end
		room:setPlayerProperty(source, "kingdom", sgs.QVariant("wei"))
		source:gainMark("@meizlcaiwenjimark", 3)
	end,
}
meizlshguihanskill = sgs.CreateViewAsSkill {
	name = "meizlshguihan",
	n = 0,
	view_as = function(self, cards)
		return meizlshguihancard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meizlshguihan") > 0
	end
}
meizlshguihan = sgs.CreateTriggerSkill {
	name = "meizlshguihan",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlshguihanskill,
	limit_mark = "@meizlshguihan",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
	end
}

meizlshhunshi = sgs.CreateTriggerSkill {
	name = "meizlshhunshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local targets
		if not death.who:hasSkill(self:objectName()) then return end
		if not player:objectName() == death.who:objectName() then return end
		if death.damage.from then
			room:loseHp(death.damage.from, 2)
			room:attachSkillToPlayer(death.damage.from, "meizlshhunshidistance")
			room:addPlayerMark(death.damage.from, "&meizlshhunshidistance")
		end
	end
}

meizlshhunshidistance = sgs.CreateDistanceSkill {
	name = "meizlshhunshidistance",
	correct_func = function(self, from, to)
		if to:hasSkill("meizlshhunshidistance") then
			return -2
		end
	end,
}

meizlzhenhunqucard = sgs.CreateSkillCard {
	name = "meizlzhenhunqucard",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlcaiwenjimark", 5)
		local card_id = room:drawCard()
		local card = sgs.Sanguosha:getCard(card_id)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), "meizlzhenhunqu", "")
		room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
		local card_id2 = room:drawCard()
		local card2 = sgs.Sanguosha:getCard(card_id2)
		room:moveCardTo(card2, nil, sgs.Player_DiscardPile, reason, true)
		local x = card:getNumber() + card2:getNumber()
		if x ~= 18 then
			if x > 18 then
				room:loseHp(targets[1], x - 18)
			else
				room:loseHp(targets[1], 18 - x)
			end
		end
	end
}
meizlzhenhunqu = sgs.CreateViewAsSkill {
	name = "meizlzhenhunqu",
	n = 0,
	view_as = function(self, cards)
		return meizlzhenhunqucard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlcaiwenjimark")
		return count >= 5
	end
}

meizlshqingyancard = sgs.CreateSkillCard {
	name = "meizlshqingyancard",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		dest:obtainCard(self)
		local room = effect.to:getRoom()
		source:gainMark("@meizlyangwanmark", 1)
		room:obtainCard(dest, self)
		local pattern = "BasicCard,TrickCard|.|.|.$1"
		room:setPlayerCardLimitation(dest, "use,response", pattern, false)

		room:setPlayerMark(dest, "@meizlshqingyan", 1)
		room:addPlayerMark(dest, "&meizlshqingyan+to+#" .. source:objectName() .. "_flag")
		local log = sgs.LogMessage()
		log.type = "#Meizlshqingyan"
		log.from = source
		log.to:append(dest)
		log.arg = self:objectName()
		room:sendLog(log)
	end
}
meizlshqingyanskill = sgs.CreateViewAsSkill {
	name = "meizlshqingyan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local meizlshqingyancard = meizlshqingyancard:clone()
			meizlshqingyancard:addSubcard(cards[1])
			return meizlshqingyancard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

meizlshqingyan = sgs.CreateTriggerSkill {
	name = "meizlshqingyan",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlshqingyanskill,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@meizlshqingyan") > 0 and p:getMark("&meizlshqingyan+to+#" .. player:objectName() .. "_flag") > 0 then
					room:removePlayerCardLimitation(p, "use,response", "BasicCard,TrickCard|.|.|.$1")
					room:setPlayerMark(p, "@meizlshqingyan", 0)
					room:setPlayerMark(p, "&meizlshqingyan+to+#" .. player:objectName() .. "_flag", 0)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end
}

meizlshqingyanclear = sgs.CreateTriggerSkill {
	name = "#meizlshqingyanclear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer then
				if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and (player:getMark("@meizlshqingyan") > 0) then
					room:removePlayerCardLimitation(player, "use,response", "BasicCard,TrickCard")
					room:setPlayerMark(player, "@meizlshqingyan", 0)
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						room:setPlayerMark(player, "&meizlshqingyan+to+#" .. p:objectName() .. "_flag", 0)
					end
				end
				if event == sgs.EventLoseSkill then
					if player:objectName() == splayer:objectName() then
						if data:toString() == "meizlshqingyan" then
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:getMark("@meizlshqingyan") > 0 and p:getMark("&meizlshqingyan+to+#" .. player:objectName() .. "_flag") > 0 then
									room:removePlayerCardLimitation(p, "use,response", "BasicCard,TrickCard")
									room:setPlayerMark(p, "@meizlshqingyan", 0)
									room:setPlayerMark(p, "&meizlshqingyan+to+#" .. player:objectName() .. "_flag", 0)
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}

meizlshxiangjie = sgs.CreateTriggerSkill {
	name = "meizlshxiangjie",
	frequency = sgs.NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer and player:getPhase() == sgs.Player_Play and player:objectName() ~= splayer:objectName() then
				if splayer:isKongcheng() then return end
				if room:askForSkillInvoke(splayer, self:objectName()) then
					local tohelp = sgs.QVariant()
					tohelp:setValue(player)
					local prompt = string.format("@meizlshxiangjie-slash:%s", player:objectName())
					local slash = room:askForCard(splayer, "slash", prompt, tohelp, sgs.Card_MethodResponse, player)
					if slash then
						local target = room:askForPlayerChosen(splayer, room:getOtherPlayers(player), self:objectName())
						slash:setSkillName("meizlshxiangjie")
						splayer:gainMark("@meizlyangwanmark", 2)
						local use = sgs.CardUseStruct()
						use.card = slash
						use.from = player
						use.to:append(target)
						room:useCard(use, false)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}

meizlshjuese = sgs.CreateTriggerSkill {
	name = "meizlshjuese",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			while player:askForSkillInvoke(self:objectName()) do
				player:gainMark("@meizlfanshimark")
				player:drawCards(3)
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				local x = math.random(1, 10)
				if x > 7 then
					break
				end
			end
		end
	end
}

meizlshzefu = sgs.CreateViewAsSkill
	{
		name = "meizlshzefu",
		n = 0,

		view_as = function(self, cards)
			return meizlshzefucard:clone()
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#meizlshzefucard")
		end,
	}

meizlshzefucard = sgs.CreateSkillCard
	{
		name = "meizlshzefucard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			if #targets == 0 then
				return to_select:getHandcardNum() >= player:getHandcardNum() and to_select:getHp() >= player:getHp() and
					to_select:getAttackRange() >= player:getAttackRange()
			end
		end,

		on_use = function(self, room, source, targets)
			source:gainMark("@meizlfanshimark", 4)
			source:drawCards(2)
			targets[1]:drawCards(2)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
			room:recover(targets[1], recover)
		end
	}

meizlshxianggui = sgs.CreateTriggerSkill {
	name = "meizlshxianggui",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and player:getHandcardNum() > player:getHp() then
			if player:askForSkillInvoke(self:objectName(), data) then
				local x = player:getHandcardNum() - player:getHp()
				player:drawCards(x)
				player:gainMark("@meizlxiaoqiaomark", 3)
			end
		end
	end
}

meizlshxiuhua = sgs.CreateTriggerSkill {
	name = "meizlshxiuhua",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then
			damage.prevented = true
			data:setValue(damage)
			return true
		end
	end
}

meizlshyuguo = sgs.CreateTriggerSkill {
	name = "meizlshyuguo",
	events = { sgs.CardOffset, sgs.DamageCaused, sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				room:getThread():delay(100)
				player:gainMark("@meizlmayunlumark")
				local x = math.random(1, 2)
				if x == 1 then
					room:getThread():delay(100)
					if effect.card and effect.card:getSubcards():length() > 0 then
						player:obtainCard(effect.card)
					end
					if player:getPhase() == sgs.Player_Play then
						room:getThread():delay(100)
						room:addPlayerHistory(player, effect.card:getClassName(), -1)
					end
					room:setPlayerMark(player, "@meizlshyuguo", player:getMark("@meizlshyuguo") + 1)
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:getThread():delay(100)
				damage.damage = damage.damage + damage.from:getMark("@meizlshyuguo")
				local log = sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = self:objectName()
				log.arg2 = damage.damage
				room:sendLog(log)
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			room:setPlayerMark(player, "@meizlshyuguo", 0)
		end
	end
}

meizlshrongzhuangVS = sgs.CreateOneCardViewAsSkill {
	name = "meizlshrongzhuang",
	view_filter = function(self, card)
		return sgs.Self:getMark(self:objectName().."Card" .. card:getId() .. "-Clear") == 2
	end,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:getCard(sgs.Self:getMark("meizlshrongzhuang_cd"))
		return acard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@meizlshrongzhuang")
	end,

}
meizlshrongzhuang = sgs.CreateTriggerSkill {
	name = "meizlshrongzhuang",
	view_as_skill = meizlshrongzhuangVS,
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damage, sgs.CardFinished },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			local current = room:getCurrent()
			if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) and current and not current:hasFlag("meizlshrongzhuang") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if not room:askForSkillInvoke(p, self:objectName()) then continue end
					room:setPlayerFlag(current, "meizlshrongzhuang")
					p:gainMark("@meizlmayunlumark")
					local card = sgs.Sanguosha:getCard(room:drawCard())
					p:obtainCard(card)
					room:showCard(p, card:getId())
					if card:isKindOf("Slash") then
						if card:isAvailable(p) then
							local can_use = card:targetFixed()
							for _, q in sgs.qlist(room:getAlivePlayers()) do
								if card:targetFilter(sgs.PlayerList(), q, p) then
									can_use = true
									break
								end
							end
							if can_use then
								--room:setPlayerMark(splayer, card:objectName() .. card:getEffectiveId() .. "-Clear", 1)
								room:addPlayerMark(p, self:objectName() .."Card".. card:getEffectiveId() .. "-Clear", 2)
								room:addPlayerMark(p, self:objectName(), 1)
								room:setPlayerMark(p, "meizlshrongzhuang_cd", card:getId())
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (p:getMark("meizlshrongzhuang") > 0) and not p:hasFlag("meizlshrongzhuang_using") then
						local scard = sgs.Sanguosha:getCard(p:getMark("meizlshrongzhuang_cd"))
						room:setPlayerFlag(p, "meizlshrongzhuang_using")
						local use = room:askForUseCard(p, "@@meizlshrongzhuang",
							("#meizlshrongzhuang:%s:%s:%s:%s"):format(scard:objectName(), scard:getSuitString(),
								scard:getNumber(), scard:getEffectiveId()))
						room:setPlayerMark(p, self:objectName() .. scard:getEffectiveId() .. "-Clear", 0)
						room:setPlayerMark(p, "meizlshrongzhuang", 0)
						room:setPlayerFlag(p, "-meizlshrongzhuang_using")
						room:setPlayerMark(p, "meizlshrongzhuang_cd", 0)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return true
	end,
}













meizlshmashu = sgs.CreateDistanceSkill {
	name = "meizlshmashu",
	correct_func = function(self, from, to)
		if from:hasSkill("meizlshmashu") then
			local x = from:getEquips():length()
			if x == 0 then x = 1 end
			return -x
		end
	end,
}

meizlshwuji = sgs.CreateTargetModSkill {
	name = "meizlshwuji",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			local x = player:getEquips():length()
			if x == 0 then x = 1 end
			return x
		end
	end,
}

meizlshjichi = sgs.CreateTriggerSkill {
	name = "meizlshjichi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardOffset, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if player:getPhase() == sgs.Player_Play and effect.card and effect.card:isKindOf("Slash") then
				player:gainMark("@meizllvlingqimark", 1)
				local log = sgs.LogMessage()
				log.type = "#Meizlshjichi"
				log.from = effect.from
				log.to:append(effect.to)
				log.arg  = self:objectName()
				log.arg2 = 1
				room:sendLog(log)
				local tag = sgs.QVariant()
				tag:setValue(effect.to)
				effect.from:setTag("MeizlshjichiTarget", tag)
				room:setFixedDistance(effect.from, effect.to, 1)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if player:inMyAttackRange(damage.to) and player:objectName() ~= damage.to:objectName() and player:isWounded() then
				player:gainMark("@meizllvlingqimark", 1)
				local log = sgs.LogMessage()
				log.type = "#Meizlshjichidamage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = tonumber(damage.damage)
				log.arg2 = tonumber(damage.damage + player:getLostHp())
				room:sendLog(log)
				damage.damage = damage.damage + player:getLostHp()
				data:setValue(damage)
			end
		end
	end
}

meizlshjichiclear = sgs.CreateTriggerSkill {
	name = "#meizlshjichiclear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlshjichi" then
				return false
			end
		end
		local tag = player:getTag("MeizlshjichiTarget")
		if tag then
			local target = tag:toPlayer()
			if target then
				room:removeFixedDistance(player, target, 1)
				player:removeTag("MeizlshjichiTarget")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			local tag = target:getTag("MeizlshjichiTarget")
			if tag then
				return tag:toPlayer()
			end
		end
		return false
	end
}

meizlshfujuncount = sgs.CreateTriggerSkill {
	name = "#meizlshfujuncount",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local recover = data:toRecover()
		player:addMark("meizlshfujun")
	end

}
meizlshfujun = sgs.CreateTriggerSkill {
	name = "meizlshfujun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source then
				if source:getMark("meizlshfujun") > 0 then
					source:setMark("meizlshfujun", 0)
					local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(),
						"meizlshfujun-invoke", true, true)
					if not target then return false end
					source:gainMark("@meizlmifurenmark")
					source:drawCards(2)
					local p = sgs.QVariant()
					p:setValue(target)
					room:setTag("MeizlshfujunInvoke", p)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end,
	priority = -1
}
meizlshfujundo = sgs.CreateTriggerSkill {
	name = "#meizlshfujundo",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("MeizlshfujunInvoke")
		if tag then
			local target = tag:toPlayer()
			room:removeTag("MeizlshfujunInvoke")
			if target then
				if target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end,
	priority = -3
}

meizlshrangma = sgs.CreateTriggerSkill {
	name = "meizlshrangma",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local idlistA = sgs.IntList()
		local idlistB = sgs.IntList()
		local targets
		if not death.who:hasSkill(self:objectName()) then return end
		if death.damage and death.damage.from then
			targets = room:getOtherPlayers(death.damage.from)
		else
			targets = room:getAlivePlayers()
		end
		local target = room:askForPlayerChosen(death.who, targets, self:objectName(), "meizlshrangma-invoke", true, true)
		if not target then return false end
		if not death.who:isNude() then
			for _, equip in sgs.qlist(death.who:getEquips()) do
				idlistA:append(equip:getId())
			end
			for _, card in sgs.qlist(death.who:getHandcards()) do
				idlistA:append(card:getId())
			end
			local move = sgs.CardsMoveStruct()
			move.card_ids = idlistA
			move.to = target
			move.to_place = sgs.Player_PlaceHand
			room:moveCardsAtomic(move, false)
		end
		if death.damage and death.damage.from and not death.damage.from:isNude() then
			for _, equip in sgs.qlist(death.damage.from:getEquips()) do
				idlistB:append(equip:getId())
			end
			for _, card in sgs.qlist(death.damage.from:getHandcards()) do
				idlistB:append(card:getId())
			end
			local move = sgs.CardsMoveStruct()
			move.card_ids = idlistB
			move.to = target
			move.to_place = sgs.Player_PlaceHand
			room:moveCardsAtomic(move, false)
		end
		if target:isAlive() then
			target:gainAnExtraTurn()
		end
	end
}

meizlshtuogucard = sgs.CreateSkillCard {
	name = "meizlshtuogucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlshtuogu")
		source:gainMark("@meizlmifurenmark", 3)
		for _, p in sgs.qlist(room:getAllPlayers(false)) do
			if p:getKingdom() ~= "shu" then
				room:loseHp(p, 1)
			end
		end

		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getKingdom() == "shu" then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return end
		local target = room:askForPlayerChosen(source, targets, self:objectName(), "meizlshtuogu-recover", true, true)
		if not target then return false end
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(target, recover)
	end,
}
meizlshtuoguskill = sgs.CreateViewAsSkill {
	name = "meizlshtuogu",
	n = 0,
	view_as = function(self, cards)
		return meizlshtuogucard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlshtuogu")
		return count > 0
	end
}
meizlshtuogu = sgs.CreateTriggerSkill {
	name = "meizlshtuogu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlshtuoguskill,
	events = { sgs.GameStart },
	limit_mark = "@meizlshtuogu",
	on_trigger = function(self, event, player, data)
	end
}

meizlkujingguhuncard = sgs.CreateSkillCard {
	name = "meizlkujingguhuncard",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlmifurenmark", 1)
		targets[1]:throwAllHandCards()
		targets[1]:turnOver()
		if source:getMark("meizlkujingguhun") == 0 then
			local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName())
			local randomtarget
			while source:isAlive() do
				randomtarget = room:getAlivePlayers():at(math.random(1, room:alivePlayerCount()) - 1)
				if randomtarget:objectName() ~= target:objectName() then
					break
				end
			end
			room:setPlayerMark(randomtarget, "meizlkujingguhundeath", 1)
			room:setPlayerMark(source, "meizlkujingguhun", 1)
		end
	end

}
meizlkujingguhunskill = sgs.CreateViewAsSkill {
	name = "meizlkujingguhun",
	n = 0,
	view_as = function(self, cards)
		return meizlkujingguhuncard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlmifurenmark")
		return count >= 1 and not player:hasUsed("#meizlkujingguhuncard")
	end
}

meizlkujingguhun = sgs.CreateTriggerSkill {
	name = "meizlkujingguhun",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlkujingguhunskill,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local log = sgs.LogMessage()
		if not death.who:hasSkill(self:objectName()) then return end
		local target
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("meizlkujingguhundeath") > 0 then
				target = p
			end
		end
		if target then
			log.type = "#meizlkujingguhun1"
			log.from = death.who
			log.to:append(target)
			log.arg = self:objectName()
			room:sendLog(log)
			room:getThread():delay(2000)
			local x = math.random(1, 5)
			if x > 1 then
				log.type = "#meizlkujingguhun2"
				log.from = death.who
				log.arg = self:objectName()
				room:sendLog(log)
				room:getThread():delay(1000)
				room:killPlayer(target)
			else
				log.type = "#meizlkujingguhun3"
				log.from = death.who
				log.arg = self:objectName()
				room:sendLog(log)
			end
		else
			log.type = "#meizlkujingguhun4"
			log.from = death.who
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlmengshilongcard = sgs.CreateSkillCard {
	name = "meizlmengshilongcard",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlyangwanmark", 4)
		local log = sgs.LogMessage()
		log.type = "#meizlmengshilong1"
		log.from = source
		log.to:append(targets[1])
		log.arg = self:objectName()
		room:sendLog(log)
		room:addPlayerMark(targets[1], "&meizlmengshilong+to+#" .. source:objectName())
		targets[1]:gainMark("@meizlmengshilong", 2)
		room:attachSkillToPlayer(targets[1], "meizlmengshilongmaxcard")
	end

}
meizlmengshilongskill = sgs.CreateViewAsSkill {
	name = "meizlmengshilong",
	n = 0,
	view_as = function(self, cards)
		return meizlmengshilongcard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlyangwanmark")
		return count >= 4
	end
}

meizlmengshilong = sgs.CreateTriggerSkill {
	name = "meizlmengshilong",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlmengshilongskill,
	events = { sgs.EventPhaseStart, sgs.DamageForseen },
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if splayer then
				local log = sgs.LogMessage()
				if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
					if player:objectName() == splayer:objectName() then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("@meizlmengshilong") > 0 and p:getMark("&meizlmengshilong+to+#" .. player:objectName()) > 0 then
								p:loseMark("@meizlmengshilong")
								if p:getMark("@meizlmengshilong") == 0 then
									room:detachSkillFromPlayer(p, "meizlmengshilongmaxcard")
									room:setPlayerMark(p, "&meizlmengshilong+to+#" .. player:objectName(), 0)
								end
							end
						end
					else
						if player:getMark("@meizlmengshilong") > 0 and player:getMark("&meizlmengshilong+to+#" .. splayer:objectName()) > 0 then
							local x = math.random(1, 2)
							if x == 1 then
								log.type = "#meizlmengshilong2"
								log.from = splayer
								log.to:append(player)
								log.arg = self:objectName()
								room:sendLog(log)
								player:skip(sgs.Player_Draw)
								local phslist = sgs.PhaseList()
								phslist:append(sgs.Player_Draw)
								splayer:play(phslist)
							end
						end
					end
				elseif event == sgs.DamageForseen then
					local damage = data:toDamage()
					if damage.from and damage.from:getMark("@meizlmengshilong") > 0 and damage.from:getMark("&meizlmengshilong+to+#" .. splayer:objectName()) > 0 then
						log.type = "#meizlmengshilong3"
						log.from = splayer
						log.to:append(damage.from)
						log.arg = self:objectName()
						room:sendLog(log)
						damage.prevented = true
						data:setValue(damage)
						return true
					end
				end
			end
		end
	end
}

meizlmengshilongmaxcard = sgs.CreateMaxCardsSkill {
	name = "meizlmengshilongmaxcard",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return -3
		end
	end
}

meizlmengshilongclear = sgs.CreateTriggerSkill {
	name = "#meizlmengshilongclear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill, sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "meizlmengshilong" then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("&meizlmengshilong+to+#" .. player:objectName()) > 0 then
				room:setPlayerMark(p, "&meizlmengshilong+to+#" .. player:objectName(), 0)
				room:setPlayerMark(p, "@meizlmengshilong", 0)
				room:detachSkillFromPlayer(p, "meizlmengshilongmaxcard")
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

meizlyanranyixiaocard = sgs.CreateSkillCard {
	name = "meizlyanranyixiaocard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlfanshimark", 8)
		local log = sgs.LogMessage()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			log.from = source
			log.to:append(p)
			local x = math.random(1, 10)
			local y = x * 10
			log.type = "#meizlyanranyixiao1"
			log.arg = self:objectName()
			log.arg2 = y
			room:sendLog(log)
			room:getThread():delay(2000)
			if p:getMark("meizlyanranyixiao") > 0 then
				x = x + p:getMark("meizlyanranyixiao")
				if x > 10 then x = 10 end
				y = x * 10
				log.type = "#meizlyanranyixiao2"
				log.arg = tonumber(p:getMark("meizlyanranyixiao"))
				log.arg2 = y
				room:sendLog(log)
				room:getThread():delay(2000)
			end
			local z = math.random(1, 10)
			if z <= x then
				log.type = "#meizlyanranyixiao3"
				log.arg = self:objectName()
				room:sendLog(log)
				room:getThread():delay(2000)
				p:turnOver()
			else
				log.type = "#meizlyanranyixiao4"
				log.arg = self:objectName()
				room:sendLog(log)
			end
			log.to:removeOne(p)
		end
	end

}
meizlyanranyixiaoskill = sgs.CreateViewAsSkill {
	name = "meizlyanranyixiao",
	n = 0,
	view_as = function(self, cards)
		return meizlyanranyixiaocard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlfanshimark")
		return count >= 8 and not player:hasUsed("#meizlyanranyixiaocard")
	end
}

meizlyanranyixiao = sgs.CreateTriggerSkill {
	name = "meizlyanranyixiao",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlyanranyixiaoskill,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			local count = damage.damage
			for i = 1, count, 1 do
				room:setPlayerMark(damage.from, "meizlyanranyixiao", damage.from:getMark("meizlyanranyixiao") + 1)
			end
		end
	end
}

meizlyuezhanyueqiangcard = sgs.CreateSkillCard {
	name = "meizlyuezhanyueqiangcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlmayunlumark", 4)
		source:gainMark("@meizlyuezhanyueqiang", 2)
	end

}
meizlyuezhanyueqiangskill = sgs.CreateViewAsSkill {
	name = "meizlyuezhanyueqiang",
	n = 0,
	view_as = function(self, cards)
		return meizlyuezhanyueqiangcard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlmayunlumark")
		return count >= 4 and not player:hasUsed("#meizlyuezhanyueqiangcard")
	end
}

meizlyuezhanyueqiang = sgs.CreateTriggerSkill {
	name = "meizlyuezhanyueqiang",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlyuezhanyueqiangskill,
	events = { sgs.Damage, sgs.DamageCaused, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local log = sgs.LogMessage()
		if player:getMark("@meizlyuezhanyueqiang") > 0 then
			if event == sgs.Damage then
				local damage = data:toDamage()
				room:setPlayerMark(player, "@meizlyuezhanyueqiangdamage", tonumber(damage.damage))
			elseif event == sgs.DamageCaused then
				local damage = data:toDamage()
				log.type = "#meizlyuezhanyueqiang"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = tonumber(player:getMark("@meizlyuezhanyueqiangdamage"))
				room:sendLog(log)
				damage.damage = damage.damage + tonumber(player:getMark("@meizlyuezhanyueqiangdamage"))
				data:setValue(damage)
			elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
				room:setPlayerMark(player, "@meizlyuezhanyueqiang", player:getMark("@meizlyuezhanyueqiang") - 1)
				if player:getMark("@meizlyuezhanyueqiang") == 0 then
					room:setPlayerMark(player, "@meizlyuezhanyueqiangdamage", 0)
				end
			end
		end
	end
}

meizlwuzhijingjichangcard = sgs.CreateSkillCard {
	name = "meizlwuzhijingjichangcard",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizllvlingqimark", 5)
		source:gainMark("@meizlwuzhijingjichang", 3)
		room:setPlayerMark(source, "@meizlwuzhijingjichangstate", 1)
		room:setPlayerMark(targets[1], "@meizlwuzhijingjichangstate", 1)
	end

}
meizlwuzhijingjichangskill = sgs.CreateViewAsSkill {
	name = "meizlwuzhijingjichang",
	n = 0,
	view_as = function(self, cards)
		return meizlwuzhijingjichangcard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizllvlingqimark")
		return count >= 5 and player:getMark("@meizlwuzhijingjichang") == 0
	end
}

meizlwuzhijingjichang = sgs.CreateTriggerSkill {
	name = "meizlwuzhijingjichang",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlwuzhijingjichangskill,
	events = { sgs.DamageCaused, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local log = sgs.LogMessage()
			if splayer and splayer:getMark("@meizlwuzhijingjichang") > 0 then
				if event == sgs.DamageCaused then
					local damage = data:toDamage()
					if damage.from:getMark("@meizlwuzhijingjichangstate") > 0 then
						log.type = "#meizlwuzhijingjichang1"
						log.from = damage.from
						log.arg = self:objectName()
						log.arg2 = tonumber(damage.damage)
						room:sendLog(log)
						room:addPlayerMark(damage.from, "@meizlwuzhijingjichangdamage", tonumber(damage.damage))
						damage.prevented = true
						data:setValue(damage)
						return true
					end
				elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
					if player:getMark("@meizlwuzhijingjichangstate") == 0 then
						local current = room:getCurrent()
						current:skip(sgs.Player_Start)
						current:skip(sgs.Player_Judge)
						current:skip(sgs.Player_Draw)
						current:skip(sgs.Player_Play)
						current:skip(sgs.Player_Discard)
						current:skip(sgs.Player_Finish)
					end
				elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
					if player:getMark("@meizlwuzhijingjichang") > 0 then
						player:loseMark("@meizlwuzhijingjichang", 1)
						if player:getMark("@meizlwuzhijingjichang") == 0 then
							local x
							local y
							local target
							local victaim
							x = player:getMark("@meizlwuzhijingjichangdamage")
							for _, p in sgs.qlist(room:getOtherPlayers(splayer)) do
								if p:getMark("@meizlwuzhijingjichangstate") > 0 then
									target = p
								end
							end
							y = target:getMark("@meizlwuzhijingjichangdamage")
							room:setPlayerMark(splayer, "@meizlwuzhijingjichangstate", 0)
							room:setPlayerMark(splayer, "@meizlwuzhijingjichangdamage", 0)
							room:setPlayerMark(target, "@meizlwuzhijingjichangstate", 0)
							room:setPlayerMark(target, "@meizlwuzhijingjichangdamage", 0)
							if x > y then
								log.type = "#meizlwuzhijingjichang2"
								log.from = splayer
								log.to:append(target)
								log.arg = tonumber(x)
								log.arg2 = tonumber(y)
								room:sendLog(log)
								room:killPlayer(target)
							elseif x < y then
								log.type = "#meizlwuzhijingjichang3"
								log.from = target
								log.to:append(splayer)
								log.arg = tonumber(y)
								log.arg2 = tonumber(x)
								room:sendLog(log)
								room:killPlayer(splayer)
							else
								log.type = "#meizlwuzhijingjichang4"
								log.from = splayer
								log.to:append(target)
								log.arg = tonumber(x)
								log.arg2 = tonumber(y)
								room:sendLog(log)
							end
						end
					end
				end
			end
		end
	end
}

meizlshdaqiao:addSkill(meizlshchunshen)
meizlshdaqiao:addSkill(meizlshjinlian)
meizlshdaqiao:addSkill(meizlluoyingbinfen)

meizlshcaiwenji:addSkill(meizlshhujia)
meizlshcaiwenji:addSkill(meizlshguihan)
meizlshcaiwenji:addSkill(meizlshhunshi)
meizlshcaiwenji:addSkill(meizlzhenhunqu)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlshhunshidistance") then skills:append(meizlshhunshidistance) end
sgs.Sanguosha:addSkills(skills)

meizlshyangwan:addSkill(meizlshqingyanclear)
meizlshyangwan:addSkill(meizlshqingyan)
meizlshyangwan:addSkill(meizlshxiangjie)
meizlshyangwan:addSkill(meizlmengshilong)
meizlshyangwan:addSkill(meizlmengshilongclear)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlmengshilongmaxcard") then skills:append(meizlmengshilongmaxcard) end
sgs.Sanguosha:addSkills(skills)

meizlshfanshi:addSkill(meizlshzefu)
meizlshfanshi:addSkill(meizlshjuese)
meizlshfanshi:addSkill(meizlyanranyixiao)

meizlshxiaoqiao:addSkill(meizlshxianggui)
meizlshxiaoqiao:addSkill(meizlshxiuhua)
meizlshxiaoqiao:addSkill(meizlluoyingbinfen)

meizlshmayunlu:addSkill(meizlshyuguo)
meizlshmayunlu:addSkill(meizlshrongzhuang)
meizlshmayunlu:addSkill(meizlshmashu)
meizlshmayunlu:addSkill(meizlyuezhanyueqiang)

meizlshlvlingqi:addSkill(meizlshwuji)
meizlshlvlingqi:addSkill(meizlshjichi)
meizlshlvlingqi:addSkill(meizlshjichiclear)
meizlshlvlingqi:addSkill(meizlwuzhijingjichang)

meizlshmifuren:addSkill(meizlshfujuncount)
meizlshmifuren:addSkill(meizlshfujun)
meizlshmifuren:addSkill(meizlshfujundo)
meizlshmifuren:addSkill(meizlshrangma)
meizlshmifuren:addSkill(meizlshtuogu)
meizlshmifuren:addSkill(meizlkujingguhun)

sgs.LoadTranslationTable {
	["meizlshdaqiao"] = "大乔‧升华",
	["&meizlshdaqiao"] = "大乔",
	["designer:meizlshdaqiao"] = "Mark1469",
	["illustrator:meizlshdaqiao"] = "三国杀OL",
	["#meizlshdaqiao"] = "深锁铜雀台",
	["@meizldaqiaomark"] = "无双标记‧大乔",
	["meizlshchunshen"] = "春深‧升华",
	["@meizlshchunshen-card"] = "请选择“春深”的目标",
	["~meizlshchunshen"] = "选择一名其他角色→点击确定",
	[":meizlshchunshen"] = "每当你受到伤害时，你可以选择你距离1以内的一名体力值不小于你的其他角色，将此伤害转移给该角色。",
	["meizlshjinlian"] = "矜怜‧升华",
	[":meizlshjinlian"] = "你的回合外，每当你失去牌后，你可以摸两张牌。",
	["meizlluoyingbinfen"] = "落英缤纷",
	["meizlluoyingbinfencard"] = "落英缤纷",
	[":meizlluoyingbinfen"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(15)</font></b>，所有男性角色视为对自己造成与其手牌数等量的伤害。",
	["meizlshcaiwenji"] = "蔡文姬‧升华",
	["&meizlshcaiwenji"] = "蔡文姬",
	["#meizlshcaiwenji"] = "悲愤的才女",
	["designer:meizlshcaiwenji"] = "Mark1469",
	["illustrator:meizlshcaiwenji"] = "霸王兔",
	["@meizlcaiwenjimark"] = "无双标记‧蔡文姬",
	["meizlshhujia"] = "胡笳‧升华",
	["@meizlshhujia"] = "胡笳‧升华",
	["meizlshhujiacard"] = "胡笳‧升华",
	[":meizlshhujia"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点。若你赢，你的体力上限+1。",
	["meizlshguihan"] = "归汉‧升华",
	["meizlshguihancard"] = "归汉‧升华",
	["@meizlshguihan"] = "归汉‧升华",
	[":meizlshguihan"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以摸X+2张牌并将势力变为“魏”（X为存活角色数）。若以此法摸的牌张数不多于八张，你将体力回复至体力上限。",
	["meizlshhunshi"] = "魂逝‧升华",
	[":meizlshhunshi"] = "<font color=\"blue\"><b>锁定技，</b></font>你死亡时，杀死你的角色失去2点体力且其他角色计算与其距离-2。",
	["meizlshhunshidistance"] = "魂逝‧升华",
	[":meizlshhunshidistance"] = "<font color=\"blue\"><b>锁定技，</b></font>其他角色计算与你的距离-2",
	["meizlzhenhunqu"] = "镇魂曲",
	["meizlzhenhunqucard"] = "镇魂曲",
	[":meizlzhenhunqu"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(5)</font></b>，你可以指定一名角色，并展示牌顶堆的两张牌并将之置于弃牌堆，以此法展示的牌点数总和与18每差1，该角色便失去1点体力。",
	["meizlshyangwan"] = "杨婉‧升华",
	["&meizlshyangwan"] = "杨婉",
	["#meizlshyangwan"] = "猛狮之妻",
	["illustrator:meizlshyangwan"] = "あおひと",
	["designer:meizlshyangwan"] = "Mark1469",
	["@meizlyangwanmark"] = "无双标记‧杨婉",
	["meizlshqingyan"] = "请宴‧升华",
	["meizlshqingyancard"] = "请宴‧升华",
	["#Meizlshqingyan"] = "%from 发动了“%arg”，%to 不能使用或打出非装备牌直至其回合结束",
	[":meizlshqingyan"] = "出牌阶段，你可以将一张牌交给一名其他角色，然后该角色不能使用或打出非装备牌直至该角色的回合结束。",
	["meizlshxiangjie"] = "相接‧升华",
	["meizlshxiangjie:yesuse"] = "计入出牌阶段内的使用次数限制",
	["meizlshxiangjie:nouse"] = "不计入出牌阶段内的使用次数限制",
	["@meizlshxiangjie-slash"] = "你可以打出一张【杀】时，视为由%src对其攻击范围内你选择的另一名角色使用",
	[":meizlshxiangjie"] = "其他角色的出牌阶段开始时，你可以打出一张【杀】，视为由当前回合角色对你选择的另一名角色使用（不计入出牌阶段内的使用次数限制）。",
	["#meizlmengshilong1"] = "%from发动技能【%arg】，两回合内，%to的手牌上限-3，并防止%to造成的伤害。",
	["#meizlmengshilong2"] = "%from的技能【%arg】被触发，%to跳过其本回合的摸牌阶段，并令%from执行一个额外的摸牌阶段。",
	["#meizlmengshilong3"] = "%from的技能【%arg】被触发，防止了%to造成的伤害。",
	["meizlmengshilongmaxcard"] = "猛狮笼效果",
	[":meizlmengshilongmaxcard"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限-3。",
	["meizlmengshilong"] = "猛狮笼",
	["@meizlmengshilong"] = "猛狮笼",
	["meizlmengshilongcard"] = "猛狮笼",
	[":meizlmengshilong"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(4)</font></b>，出牌阶段，你可以选择一名其他角色，该角色获得以下效果：两回合内，你的手牌上限-3，并防止你造成的伤害。受此技能效果影响的角色回合开始时，你有50%机率代替其执行摸牌阶段。",
	["meizlshfanshi"] = "樊氏‧升华",
	["&meizlshfanshi"] = "樊氏",
	["#meizlshfanshi"] = "赵氏寡孀",
	["designer:meizlshfanshi"] = "Mark1469",
	["illustrator:meizlshfanshi"] = "大戦乱!!三国志バトル",
	["@meizlfanshimark"] = "无双标记‧樊氏",
	["meizlshzefu"] = "择夫‧升华",
	["meizlshzefucard"] = "择夫‧升华",
	[":meizlshzefu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名手牌数、体力值和攻击范围均不小于你的角色，你和该角色各摸两张牌并回复1点体力",
	["meizlshjuese"] = "绝色‧升华",
	[":meizlshjuese"] = "每当你受到一次伤害后，你可以摸三张牌并弃置两张牌，然后你有70%机率可以重覆此流程。",
	["meizlyanranyixiao"] = "嫣然一笑",
	["#meizlyanranyixiao1"] = "%from发动了技能【%arg】，经系统判定后，%to有%arg2%机率将其武将牌翻面。",
	["#meizlyanranyixiao2"] = "由于%to曾对%from造成%arg点伤害，其翻面机率将调整为%arg2%。",
	["#meizlyanranyixiao3"] = "%from的技能【%arg】判定结果发布，对%to的判定结果为生效，系统将会继续执行【%arg】的后续效果，%to须将其武将牌翻面。",
	["#meizlyanranyixiao4"] = "%from的技能【%arg】判定结果发布，对%to的判定结果为失效，系统将不会执行【%arg】的后续效果。",
	["meizlyanranyixiaocard"] = "嫣然一笑",
	[":meizlyanranyixiao"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(8)</font></b>，<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令所有其他角色将随机有10~100%机率将其武将牌翻面。若该角色曾对你造成伤害，每曾造成1点伤害，机率提高10%。",
	["meizlshxiaoqiao"] = "小乔‧升华",
	["&meizlshxiaoqiao"] = "小乔",
	["#meizlshxiaoqiao"] = "秋水芙蓉",
	["illustrator:meizlshxiaoqiao"] = "Snowfox",
	["designer:meizlshxiaoqiao"] = "Mark1469",
	["@meizlxiaoqiaomark"] = "无双标记‧小乔",
	["meizlshxianggui"] = "香闺‧升华",
	[":meizlshxianggui"] = "摸牌阶段结束后，若你的手牌数大于体力值，你可以摸X张牌（X为你手牌数与体力值之差）。",
	["meizlshxiuhua"] = "羞花‧升华",
	[":meizlshxiuhua"] = "<font color=\"blue\"><b>锁定技，</b></font>你防止你受到的属性伤害。",
	["meizlshmayunlu"] = "马云禄‧升华",
	["&meizlshmayunlu"] = "马云禄",
	["#meizlshmayunlu"] = "西凉巾帼",
	["designer:meizlshmayunlu"] = "Mark1469",
	["illustrator:meizlshmayunlu"] = "霸王兔",
	["@meizlmayunlumark"] = "无双标记‧马云禄",
	["meizlshyuguo"] = "域帼‧升华",
	[":meizlshyuguo"] = "当你使用的【杀】被目标角色的【闪】抵消时，你有50%机率可以获得你使用的【杀】，然后此阶段你可以额外使用一张【杀】且你本回合内使用【杀】造成的伤害+1。",
	["meizlshrongzhuang"] = "戎装‧升华",
	[":meizlshrongzhuang"] = "每当一名角色使用【杀】对目标角色造成一次伤害后，你可以摸一张牌并展示之，若为【杀】，你可以对攻击范围内的一名其他角色使用。每名角色的回合限一次。 ",
	["~meizlshrongzhuang"] = "选择目标→确定",
	["#meizlshrongzhuang"] = "请选择【%src】的目标",
	["meizlshrongzhuang:usesl"] = "對攻擊範圍內的一名其他角色使用此【杀】",

	["meizlshmashu"] = "马术‧升华",
	[":meizlshmashu"] = "<font color=\"blue\"><b>锁定技，</b></font>你与其他角色的距离-X（X为你装备区的牌数量且至少为1）。",
	["meizlyuezhanyueqiangcard"] = "越战越强",
	["meizlyuezhanyueqiang"] = "越战越强",
	["@meizlyuezhanyueqiang"] = "越战越强",
	["#meizlyuezhanyueqiang"] = "%from的【%arg】被触发，造成的伤害增加%arg2点。",
	[":meizlyuezhanyueqiang"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(4)</font></b>，<font color=\"green\"><b>出牌阶段限一次，</b></font>你获得以下效果：两回合内，你造成的伤害+X（X为你上次造成的伤害）（技能发动后开始计算）。",
	["meizlshlvlingqi"] = "吕玲绮‧升华",
	["&meizlshlvlingqi"] = "吕玲绮",
	["#meizlshlvlingqi"] = "飞将之后",
	["designer:meizlshlvlingqi"] = "Mark1469",
	["illustrator:meizlshlvlingqi"] = "三国轮舞曲",
	["@meizllvlingqimark"] = "无双标记‧吕玲绮",
	["meizlshwuji"] = "舞戟‧升华",
	[":meizlshwuji"] = "当你使用【杀】时，你可以额外选择X个目标（X为你装备区牌的数量且至少为1） 。",
	["meizlshjichi"] = "疾驰‧升华",
	["#Meizlshjichi"] = "%from的技能【%arg】被触发，%from与%to距离为%arg2直至回合结束。",
	["#Meizlshjichidamage"] = "%from的技能【<font color=\"yellow\"><b>疾驰</b></font>】被触发，%from对%to造成的伤害由%arg点至增加至%arg2点。",
	[":meizlshjichi"] = "<font color=\"blue\"><b>锁定技，</b></font>当你在出牌阶段内使用的【杀】被目标角色的【闪】抵消时，你与该角色距离为1直至回合结束；你对攻击范围内的其他角色造成的伤害+ X（X为你已损失的体力值） 。",
	["meizlwuzhijingjichangcard"] = "武之竞技场",
	["meizlwuzhijingjichang"] = "武之竞技场",
	["@meizlwuzhijingjichang"] = "竞技",
	["#meizlwuzhijingjichang1"] = "【%arg】效果触发，由于%from处于竞技状态，系统将防止其造成的伤害，并改为令%from获得%arg2枚“武之竞技场”标记。",
	["#meizlwuzhijingjichang2"] = "【武之竞技场】结果公布：%from拥有%arg枚“武之竞技场”标记；%to拥有%arg2枚“武之竞技场”标记，由于%from拥有较多“武之竞技场”标记，%to判定为<b><font color=\"red\">失格</font></b>，须立即死亡，系统将优先处理其死亡事件。",
	["#meizlwuzhijingjichang3"] = "【武之竞技场】结果公布：%from拥有%arg枚“武之竞技场”标记；%to拥有%arg2枚“武之竞技场”标记，由于%from拥有较多“武之竞技场”标记，%to判定为<b><font color=\"red\">失格</font></b>，须立即死亡，系统将优先处理其死亡事件。",
	["#meizlwuzhijingjichang4"] = "【武之竞技场】结果公布：%from拥有%arg枚“武之竞技场”标记；%to拥有%arg2枚“武之竞技场”标记，由于双方拥有标记数目相同，双方判定为<b><font color=\"red\">和局</font></b>，系统不会执行后续效果。",
	[":meizlwuzhijingjichang"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(5)</font></b>，出牌阶段，若你未获得此技能效果，你可以指定一名其他角色，然后三回合内根据以下效果执行：跳过除你和该角色以外的所有角色的回合；你和该角色造成伤害时，防止之并改为获得与造成的伤害等量的“武之竞技场”标记；三回合内获得较少标记的一方被判为阵亡。",
	["meizlshmifuren"] = "糜夫人‧升华",
	["&meizlshmifuren"] = "糜夫人",
	["designer:meizlshmifuren"] = "Mark1469",
	["#meizlshmifuren"] = "舍身存嗣",
	["illustrator:meizlshmifuren"] = "木美人",
	["@meizlmifurenmark"] = "无双标记‧糜夫人",
	["meizlshfujun"] = "扶君‧升华",
	[":meizlshfujun"] = "若你在一回合内回复了至少1点体力，此回合结束后，你可以摸两张牌并令一名其他角色进行一个额外的回合。",
	["meizlshfujun-invoke"] = "你可以发动“扶君‧升华”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlshtuogu"] = "托孤‧升华",
	["@meizlshtuogu"] = "托孤‧升华",
	["meizlshtuogucard"] = "托孤‧升华",
	[":meizlshtuogu"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令所有非蜀势力角色失去1点体力，并令一名蜀势力角色回复1点体力。",
	["meizlshtuogu-recover"] = "你可以发动“托孤‧升华-回复”<br/> <b>操作提示</b>: 选择一名蜀势力角色→点击确定<br/>",
	["meizlshrangma"] = "让马‧升华",
	[":meizlshrangma"] = "你死亡时，可以令一名其他角色（杀死你的角色除外）获得你和杀死你的角色所有牌并进行一个额外的回合。",
	["meizlshrangma-invoke"] = "你可以发动“让马‧升华”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["meizlkujingguhun"] = "枯井孤魂",
	["#meizlkujingguhun1"] = "%from的技能【%arg】被触发，系统即将发表判定结果，被系统指定的%to将有80%机率死亡。",
	["#meizlkujingguhun2"] = "%from的技能【%arg】被触发，判定结果公布：%to死亡，系统将优先处理%to的死亡事件。",
	["#meizlkujingguhun3"] = "%from的技能【%arg】被触发，判定结果公布：%to存活，系统将继续执行结算。",
	["#meizlkujingguhun4"] = "%from的技能【%arg】被触发，但由于被指定的角色已阵亡，不会发动技能后续效果，系统将继续执行结算。",
	["meizlkujingguhuncard"] = "枯井孤魂",
	[":meizlkujingguhun"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(1)</font></b>，<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色弃置所有手牌并将其武将牌翻面。此技能首次发动时，你选择​​一名角色，系统将随机指定该角色以外的另一名角色；当你死亡时，被指定的角色将有80%机率死亡。",

}
------------------------------------------------------
meizldaqiaochangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizldaqiaochangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizldaqiao" then
			local choice = room:askForChoice(player, "meizldaqiaochangehero", "nomode+shmode")
			--if choice == "shmode" and x <= 75 then
			if choice == "shmode" then
				room:changeHero(player, "meizlshdaqiao", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizldaqiao" then
			local choice = room:askForChoice(player, "meizldaqiaochangehero", "nomode+shmode")
			--if choice == "shmode" and x <= 75 then
			if choice == "shmode" then
				room:changeHero(player, "meizlshdaqiao", false, false, true, true)
				return false
			end
		end
	end,
}

meizldaqiao:addSkill(meizldaqiaochangehero)
meizlcaiwenjichangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlcaiwenjichangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlcaiwenji" then
			local choice = room:askForChoice(player, "meizlcaiwenjichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshcaiwenji", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizlcaiwenji" then
			local choice = room:askForChoice(player, "meizlcaiwenjichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshcaiwenji", false, false, true, true)
				return false
			end
		end
	end,
}

meizlcaiwenji:addSkill(meizlcaiwenjichangehero)

meizlyangwanchangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlyangwanchangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlyangwan" then
			local choice = room:askForChoice(player, "meizlyangwanchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshyangwan", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizlyangwan" then
			local choice = room:askForChoice(player, "meizlyangwanchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshyangwan", false, false, true, true)
				return false
			end
		end
	end,
}

meizlyangwan:addSkill(meizlyangwanchangehero)

meizlfanshichangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlfanshichangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlfanshi" then
			local choice = room:askForChoice(player, "meizlfanshichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshfanshi", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizlfanshi" then
			local choice = room:askForChoice(player, "meizlfanshichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshfanshi", false, false, true, true)
				return false
			end
		end
	end,
}

meizlfanshi:addSkill(meizlfanshichangehero)

meizlxiaoqiaochangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlxiaoqiaochangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlxiaoqiao" then
			local choice = room:askForChoice(player, "meizlxiaoqiaochangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshxiaoqiao", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizlxiaoqiao" then
			local choice = room:askForChoice(player, "meizlxiaoqiaochangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshxiaoqiao", false, false, true, true)
				return false
			end
		end
	end,
}

meizlxiaoqiao:addSkill(meizlxiaoqiaochangehero)

meizlmayunluchangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlmayunluchangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlmayunlu" then
			local choice = room:askForChoice(player, "meizlmayunluchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshmayunlu", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizlmayunlu" then
			local choice = room:askForChoice(player, "meizlmayunluchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshmayunlu", false, false, true, true)
				return false
			end
		end
	end,
}

meizlmayunlu:addSkill(meizlmayunluchangehero)

meizllvlingqichangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizllvlingqichangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizllvlingqi" then
			local choice = room:askForChoice(player, "meizllvlingqichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 100 then
				room:changeHero(player, "meizlshlvlingqi", false, false, false, true)
				return false
			end
		end
		if player:getGeneral2Name() == "meizllvlingqi" then
			local choice = room:askForChoice(player, "meizllvlingqichangehero", "nomode+shmode")
			if choice == "shmode" and x <= 100 then
				room:changeHero(player, "meizlshlvlingqi", false, false, true, true)
				return false
			end
		end
	end,
}

meizllvlingqi:addSkill(meizllvlingqichangehero)

meizlmifurenchangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meizlmifurenchangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meizlmifuren" then
			local choice = room:askForChoice(player, "meizlmifurenchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshmifuren", false, false, false, true)
			end
		end
		if player:getGeneral2Name() == "meizlmifuren" then
			local choice = room:askForChoice(player, "meizlmifurenchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 75 then
				room:changeHero(player, "meizlshmifuren", false, false, true, true)
			end
		end
	end,
}

meizlmifuren:addSkill(meizlmifurenchangehero)

meispniangzhaoyunchangehero = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Limited,
	name = "#meispniangzhaoyunchangehero",
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 100)
		if player:getGeneralName() == "meispniangzhaoyun" then
			local choice = room:askForChoice(player, "meispniangzhaoyunchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 100 then
				room:changeHero(player, "meispshniangzhaoyun", false, false, false, true)
			end
		end
		if player:getGeneral2Name() == "meispniangzhaoyun" then
			local choice = room:askForChoice(player, "meispniangzhaoyunchangehero", "nomode+shmode")
			if choice == "shmode" and x <= 100 then
				room:changeHero(player, "meispshniangzhaoyun", false, false, true, true)
			end
		end
	end,
}

meispniangzhaoyun:addSkill(meispniangzhaoyunchangehero)
sgs.LoadTranslationTable {
	["nomode"] = "普通模式",
	["shmode"] = "升华模式（成功率：75%）",
	["zshmode"] = "真-升华模式 （成功率：40%）",
	["meizldaqiaochangehero"] = "模式转换-大乔",
	["meizlcaiwenjichangehero"] = "模式转换-蔡文姬",
	["meizlyangwanchangehero"] = "模式转换-杨婉",
	["meizlfanshichangehero"] = "模式转换-樊氏",
	["meizlxiaoqiaochangehero"] = "模式转换-小乔",
	["meizlmayunluchangehero"] = "模式转换-马云禄",
	["meizllvlingqichangehero"] = "模式转换-吕玲琦",
	["meizlmifurenchangehero"] = "模式转换-糜夫人",
	["meispniangzhaoyunchangehero"] = "模式转换-娘-赵云",
}

-----------------------------------------------------------------------------------------------
--MEISP.SH 001 娘‧赵云‧升华
--凤胆‧升华（娘‧赵云‧升华）

meispshfengdan = sgs.CreateTriggerSkill {
	name = "meispshfengdan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.Damage, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			player:loseMark("@meispshfeng")
			player:gainMark("@meispniangzhaoyunmark", 1)
		elseif event == sgs.Damage then
			player:gainMark("@meispshfeng")
			player:gainMark("@meispniangzhaoyunmark", 1)
		elseif event == sgs.DamageCaused then
			damage.damage = damage.damage + tonumber(player:getMark("@meispshfeng"))
			local log = sgs.LogMessage()
			log.type = "#meispfengdan"
			log.from = player
			log.to:append(damage.to)
			log.arg = self:objectName()
			log.arg2 = tonumber(player:getMark("@meispshfeng"))
			room:sendLog(log)
			data:setValue(damage)
			player:gainMark("@meispniangzhaoyunmark", 1)
		end
	end
}
--梨舞‧升华（娘‧赵云‧升华）
meispshliwucard = sgs.CreateSkillCard {
	name = "meispshliwucard",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		source:loseMark("@meispshfeng", 1)
		source:gainMark("@meispniangzhaoyunmark", 1)
		if source:getMark("@meispshliwu") > 0 then
			source:loseMark("@meispshliwu")
			room:detachSkillFromPlayer(source, "meispshliwuskill2")
			room:setPlayerMark(source, "@meispshliwuprevent", 0)
		else
			source:gainMark("@meispshliwu")
			room:attachSkillToPlayer(source, "meispshliwuskill2")
			room:setPlayerMark(source, "@meispshliwuprevent", 2)
		end
	end
}

meispshliwuskill = sgs.CreateViewAsSkill {
	name = "meispshliwu",
	n = 0,

	view_as = function(self, cards)
		return meispshliwucard:clone()
	end,

	enabled_at_play = function(self, player)
		return player:getKingdom() == "shu" and player:getMark("@meispshfeng") >= 1 and
			not player:hasUsed("#meispshliwucard")
	end,
}

meispshliwu = sgs.CreateTriggerSkill {
	name = "meispshliwu",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meispshliwuskill,
	events = { sgs.DrawNCards, sgs.Damaged, sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@meispshliwu") > 0 then
			if event == sgs.DrawNCards then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				draw.num = draw.num + 1
				data:setValue(draw)
			elseif event == sgs.DamageForseen then
				if player:getMark("@meispshliwuprevent") > 0 then
					room:setPlayerMark(player, "@meispshliwuprevent", tonumber(player:getMark("@meispshliwuprevent")) - 1)
					local log = sgs.LogMessage()
					log.type = "#Meispliwu"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					return true
				end
			elseif event == sgs.Damaged then
				player:loseMark("@meispshliwu")
				room:detachSkillFromPlayer(player, "meispshliwuskill2")
			end
		end
	end
}

sgs.meispshliwuskill2Pattern = { "pattern" }
meispshliwuskill2 = sgs.CreateViewAsSkill {
	name = "meispshliwuskill2",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.meispshliwuskill2Pattern[1]
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			sgs.meispshliwuskill2Pattern = { "slash" }
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "jink" or pattern == "slash" then
			sgs.meispshliwuskill2Pattern = { pattern }
			return true
		end
		return false
	end
}
--瑞雪‧升华（娘‧赵云‧升华）
meispshruixuecard = sgs.CreateSkillCard {
	name = "meispshruixuecard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meispshruixue")
		source:gainMark("@meispniangzhaoyunmark", 5)
		source:drawCards(5)
		room:setPlayerMark(source, "@meispshruixueeffect", 1)
		room:addPlayerMark(source, "&meispshruixue-Clear")
	end
}
meispshruixueskill = sgs.CreateViewAsSkill {
	name = "meispshruixue",
	n = 0,
	view_as = function(self, cards)
		local card = meispshruixuecard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@meispshruixue") > 0 and player:getKingdom() == "qun"
	end
}
meispshruixue = sgs.CreateTriggerSkill {
	name = "meispshruixue",
	frequency = sgs.Skill_Limited,
	view_as_skill = meispshruixueskill,
	limit_mark = "@meispshruixue",
	events = { sgs.Damage, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if player:getMark("@meispshruixueeffect") > 0 then
				local damage = data:toDamage()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:loseHp(p, tonumber(damage.damage))
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "@meispshruixueeffect", 0)
		end
	end
}

meispshengguangjiahu = sgs.CreateTriggerSkill {
	name = "meispshengguangjiahu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:getMark("@meispniangzhaoyunmark") >= 2 then
			damage.to:loseMark("@meispniangzhaoyunmark", 2)
			local log = sgs.LogMessage()
			log.type  = "#Meispshengguangjiahu"
			log.from  = player
			log.arg   = tonumber(damage.damage)
			log.arg2  = tonumber(damage.damage - 1)
			room:sendLog(log)
			damage.damage = damage.damage - 1
			if damage.damage < 1 then
				return true
			end
			data:setValue(damage)
		end
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meispshliwuskill2") then skills:append(meispshliwuskill2) end
sgs.Sanguosha:addSkills(skills)
meispshniangzhaoyun:addSkill(meispshfengdan)
meispshniangzhaoyun:addSkill(meispshliwu)
meispshniangzhaoyun:addSkill(meispshruixue)
meispshniangzhaoyun:addSkill(meispshengguangjiahu)
meispshniangzhaoyun:addSkill(meichunjiefuli)

sgs.LoadTranslationTable {
	["meispshniangzhaoyun"] = "娘‧赵云‧升华",
	["&meispshniangzhaoyun"] = "赵云",
	["designer:meispshniangzhaoyun"] = "Mark1469",
	["illustrator:meispshniangzhaoyun"] = "",
	["#meispshniangzhaoyun"] = "长坂坡女将",
	["@meispniangzhaoyunmark"] = "无双标记‧娘‧赵云",
	["meispshfengdan"] = "凤胆‧升华",
	["#meispshfengdan"] = "%from的【%arg】被触发，对%to造成的伤害增加%arg2点。",
	["@meispshfeng"] = "凤",
	[":meispshfengdan"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你造成一次伤害后，你获得一枚“凤”标记；每当你受到一次伤害后，你失去一枚“凤”标记；你造成的伤害+X（X为你拥有的“凤”标记数量）。",
	["meispshliwu"] = "梨舞‧升华",
	["#Meispliwu"] = "%from的技能【%arg】被触发，防止了此次受到的伤害。",
	["meispshliwuskill2"] = "梨舞效果",
	[":meispshliwuskill2"] = "你可以将【闪】当作【杀】；【杀】当作【闪】使用。",
	["@meispshliwu"] = "梨舞‧升华",
	["meispshliwucaed"] = "梨舞‧升华",
	[":meispshliwu"] = "<b><font color=\"darkslategray\">势力技<font color=\"red\">（蜀）</font>，</font></b><font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一枚“凤”标记，然后获得或取消以下效果：你防止获得此效果后首两次受到的伤害；摸牌阶段时，你额外摸一张牌；你可以将【闪】当作【杀】；【杀】当作【闪】使用。每当你受到一次伤害后，你失去此效果。",
	["meispshruixue"] = "瑞雪‧升华",
	["meispshruixuecard"] = "瑞雪‧升华",
	["@meispshruixue"] = "瑞雪‧升华",
	[":meispshruixue"] = "<b><font color=\"darkslategray\">势力技<font color=\"gray\">（群）</font>，</font></b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以摸五张牌，然后此回合内，每当你对其他角色造成一次伤害后，所有其他角色失去与造成的伤害等量的体力。",
	["meispshengguangjiahu"] = "圣光加护",
	[":meispshengguangjiahu"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(2)</font></b>，<font color=\"blue\"><b>锁定技，</b></font>你受到的伤害-1。",
	["#Meispshengguangjiahu"] = "%from的技能【<font color=\"yellow\"><b>圣光加护</b></font>】被触发，此次受到的伤害由%arg点至减至%arg2点。",
}
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
meizlzshfujun = sgs.CreateTriggerSkill {
	name = "meizlzshfujun",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		for i = 1, recover.recover, 1 do
			if player:askForSkillInvoke("meizlzshfujun") then
				player:gainMark("@meizlmifurenmark")
				player:drawCards(2)
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
				target:gainAnExtraTurn()
			end
		end
	end

}

meizlzshrangma = sgs.CreateTriggerSkill {
	name = "meizlzshrangma",
	frequency = sgs.Skill_Frequent,
	events = { sgs.AskForPeaches },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDying()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local idlistA = sgs.IntList()
		local idlistB = sgs.IntList()
		local targets
		if not death.who:hasSkill(self:objectName()) then return end
		if room:askForSkillInvoke(death.who, self:objectName()) then
			if death.damage and death.damage.from then
				targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(death.damage.from)) do
					if p:objectName() ~= death.who:objectName() then
						targets:append(p)
					end
				end
			else
				targets = room:getAlivePlayers()
			end
			local target = room:askForPlayerChosen(death.who, targets, self:objectName())
			if not death.who:isNude() then
				for _, equip in sgs.qlist(death.who:getEquips()) do
					idlistA:append(equip:getId())
				end
				for _, card in sgs.qlist(death.who:getHandcards()) do
					idlistA:append(card:getId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = idlistA
				move.to = target
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, false)
			end
			if death.damage and death.damage.from and not death.damage.from:isNude() then
				for _, equip in sgs.qlist(death.damage.from:getEquips()) do
					idlistB:append(equip:getId())
				end
				for _, card in sgs.qlist(death.damage.from:getHandcards()) do
					idlistB:append(card:getId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = idlistB
				move.to = target
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, false)
			end
			if target:isAlive() then
				death.who:gainMark("@meizlmifurenmark", 3)
				target:gainAnExtraTurn()
			end
		end
	end
}

meizlzshtuogucard = sgs.CreateSkillCard {
	name = "meizlzshtuogucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlzshtuogu")
		source:gainMark("@meizlmifurenmark", 3)
		for _, p in sgs.qlist(room:getAllPlayers(false)) do
			if p:getKingdom() ~= "shu" then
				room:loseHp(p, 2)
			end
		end
		if not source:askForSkillInvoke("meizlzshtuogu") then return end
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "meizlzshtuogu")
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = target:getLostHp()
		room:recover(target, recover)
	end,
}
meizlzshtuoguskill = sgs.CreateViewAsSkill {
	name = "meizlzshtuogu",
	n = 0,
	view_as = function(self, cards)
		return meizlzshtuogucard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlzshtuogu")
		return count > 0
	end
}
meizlzshtuogu = sgs.CreateTriggerSkill {
	name = "meizlzshtuogu",
	frequency = sgs.Skill_Limited,
	view_as_skill = meizlzshtuoguskill,
	events = { },
	limit_mark = "@meizlzshtuogu",
	on_trigger = function(self, event, player, data)
	end
}

meizlzhenkujingguhuncard = sgs.CreateSkillCard {
	name = "meizlzhenkujingguhuncard",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@meizlmifurenmark", 1)
		targets[1]:throwAllHandCards()
		targets[1]:turnOver()
		if source:getMark("meizlzhenkujingguhun") == 0 then
			local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName())
			local target2 = room:askForPlayerChosen(source, room:getOtherPlayers(target), self:objectName())
			local randomtarget
			while source:isAlive() do
				randomtarget = room:getAlivePlayers():at(math.random(1, room:alivePlayerCount()) - 1)
				if randomtarget:objectName() ~= target:objectName() and randomtarget:objectName() ~= target:objectName() then
					break
				end
			end
			room:setPlayerMark(randomtarget, "meizlzhenkujingguhundeath", 1)
			room:setPlayerMark(source, "meizlzhenkujingguhun", 1)
		end
	end

}
meizlzhenkujingguhunskill = sgs.CreateViewAsSkill {
	name = "meizlzhenkujingguhun",
	n = 0,
	view_as = function(self, cards)
		return meizlzhenkujingguhuncard:clone()
	end,
	enabled_at_play = function(self, player)
		local count = player:getMark("@meizlmifurenmark")
		return count >= 1 and not player:hasUsed("#meizlzhenkujingguhuncard")
	end
}

meizlzhenkujingguhun = sgs.CreateTriggerSkill {
	name = "meizlzhenkujingguhun",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = meizlzhenkujingguhunskill,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local damage = data:toDamage()
		local room = death.who:getRoom()
		local log = sgs.LogMessage()
		if not death.who:hasSkill(self:objectName()) then return end
		local target
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("meizlzhenkujingguhundeath") > 0 then
				target = p
			end
		end
		if target then
			log.type = "#meizlzhenkujingguhun1"
			log.from = death.who
			log.to:append(target)
			log.arg = self:objectName()
			room:sendLog(log)
			room:getThread():delay(2000)
			room:killPlayer(target)
		else
			log.type = "#meizlzhenkujingguhun2"
			log.from = death.who
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
mei_lunhui = sgs.CreateTriggerSkill {
	name = "#mei_lunhui",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseStart, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getHandcardNum() + player:getEquips():length()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getMark("mei_lunhui") == 0 then
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				p:setTag("mei_lunhuicard", sgs.QVariant(0))
				p:setTag("mei_lunhuihp", sgs.QVariant(0))
				p:setTag("mei_lunhuimaxhp", sgs.QVariant(0))
			end
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if p:isAlive() then
					p:setTag("mei_lunhuicard", sgs.QVariant(p:getHandcardNum() + p:getEquips():length()))
					p:setTag("mei_lunhuihp", sgs.QVariant(p:getHp()))
					p:setTag("mei_lunhuimaxhp", sgs.QVariant(p:getMaxHp()))
				else
					p:setTag("mei_lunhuicard", sgs.QVariant(0))
					p:setTag("mei_lunhuihp", sgs.QVariant(0))
					p:setTag("mei_lunhuimaxhp", sgs.QVariant(0))
				end
			end
		elseif event == sgs.Damaged and x == 0 and player:hasSkill("xiaoji") and player:hasSkill("ganlu") and player:hasSkill("xuanfeng") and player:getMark("mei_lunhui") == 0 then
			room:setPlayerMark(player, "mei_lunhui", 1)
			if room:askForSkillInvoke(player, "mei_lunhui") then
				local log = sgs.LogMessage()
				log.type = "#Meilunhui"
				log.from = player
				log.arg = "mei_lunhui"
				room:sendLog(log)
				for _, p in sgs.qlist(room:getAllPlayers(true)) do
					if p:isDead() then
						room:revivePlayer(p)
					end
					p:throwAllHandCardsAndEquips()
					p:drawCards(p:getTag("mei_lunhuicard"):toString())
					room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getTag("mei_lunhuimaxhp"):toString()))
					room:setPlayerProperty(p, "hp", sgs.QVariant(p:getTag("mei_lunhuihp"):toString()))
					if p:getMaxHp() <= 0 then
						room:killPlayer(p)
					end
				end
			end
		end
	end
}

mei_chongsheng = sgs.CreateTriggerSkill {
	name = "#mei_chongsheng",
	frequency = sgs.Skill_Limited,
	events = { sgs.AskForPeachesDone },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		local dying_data = data:toDying()
		if dying_data.who:objectName() == splayer:objectName() and dying_data.who:getHp() <= 0 then
			if splayer:getMark("mei_chongshengused") > 1 then return end
			if (splayer:getMark("@mei_chongsheng") == 0 and splayer:hasSkill("lijian") and splayer:hasSkill("lihun") and splayer:hasSkill("meizllipo")) then
				room:setPlayerMark(splayer, "mei_chongshengused", 1)
				if splayer:askForSkillInvoke("mei_chongsheng", data) then
					player:gainMark("@mei_chongsheng")
					local log = sgs.LogMessage()
					log.type  = "#Meichongsheng"
					log.from  = splayer
					log.arg   = "mei_chongsheng"
					room:sendLog(log)
					local recover = sgs.RecoverStruct()
					recover.recover = splayer:getMaxHp() - splayer:getHp()
					recover.who = splayer
					room:recover(splayer, recover)
				end
			elseif splayer:getMark("@mei_chongsheng") > 0 and splayer:getMark("mei_chongsheng") == 0 then
				room:setPlayerMark(splayer, "mei_chongshengused", 1)
				splayer:loseMark("@mei_chongsheng", 1)
				room:setPlayerMark(splayer, "mei_chongsheng", splayer:getMark("mei_chongshengused") + 1)
				local log = sgs.LogMessage()
				log.type  = "#Meichongsheng2"
				log.from  = splayer
				log.arg   = "mei_chongsheng"
				room:sendLog(log)
				local recover = sgs.RecoverStruct()
				recover.recover = splayer:getMaxHp() - splayer:getHp()
				recover.who = splayer
				room:recover(splayer, recover)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

mei_jinji = sgs.CreateTriggerSkill {
	name = "#mei_jinji",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("meizljinghongused") <= 5 and player:getMark("mei_jinji") == 0 and player:getHp() == 1 then
			room:setPlayerMark(player, "mei_jinji", 1)
			if room:askForSkillInvoke(player, "mei_jinji") then
				room:setPlayerMark(player, "mei_jinji2", 1)
				local log = sgs.LogMessage()
				log.type  = "#meijinji"
				log.from  = player
				log.arg   = "mei_jinji"
				room:sendLog(log)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(999))
				room:setPlayerProperty(player, "hp", sgs.QVariant(999))
			end
		elseif player:getPhase() == sgs.Player_Finish and player:getMark("mei_jinji2") > 0 and player:getMaxHp() > 1 then
			local log = sgs.LogMessage()
			log.type  = "#meijinjibad"
			log.from  = player
			log.arg   = "mei_jinji"
			room:sendLog(log)
			room:loseMaxHp(player, player:getMaxHp() / 2)
		end
	end
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--小型场景：大危机！ ！ ！蜀之防卫战
---------------------------------------------------------------
---------------------------------------------------------------
--MEIZL BOSS2 L001 步兵
meizlboss2bubing = sgs.General(extension, "meizlboss2bubing", "shu", 3, false, true, true)

meizlboss2chongfeng = sgs.CreateTriggerSkill {
	name = "meizlboss2chongfeng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.SlashProceed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		local effect = data:toSlashEffect()
		room:slashResult(effect, nil)
		return true
	end
}

meizlboss2bubing:addSkill(meizlboss2chongfeng)

sgs.LoadTranslationTable {
	["meizlboss2bubing"] = "步兵",
	["#meizlboss2bubing"] = "蜀汉的将士",
	["illustrator:meizlboss2bubing"] = "",
	["designer:meizlboss2bubing"] = "Mark1469",
	["meizlboss2chongfeng"] = "冲锋",
	[":meizlboss2chongfeng"] = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】不可被目标角色的【闪】响应。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L002 骑兵
meizlboss2qibing = sgs.General(extension, "meizlboss2qibing", "shu", 3, false, true, true)

meizlboss2feiqi = sgs.CreateDistanceSkill {
	name = "meizlboss2feiqi",
	correct_func = function(self, from, to)
		if from:hasSkill("meizlboss2feiqi") then
			return -5
		end
	end,
}

meizlboss2qibing:addSkill(meizlboss2feiqi)

sgs.LoadTranslationTable {
	["meizlboss2qibing"] = "骑兵",
	["#meizlboss2qibing"] = "蜀汉的将士",
	["illustrator:meizlboss2qibing"] = "",
	["designer:meizlboss2qibing"] = "Mark1469",
	["meizlboss2feiqi"] = "飞骑",
	[":meizlboss2feiqi"] = "<font color=\"blue\"><b>锁定技，</b></font>你计算与其他角色的距离-5。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L003 弓手
meizlboss2gongshou = sgs.General(extension, "meizlboss2gongshou", "shu", 3, false, true, true)

meizlboss2chuanyang = sgs.CreateTriggerSkill {
	name = "meizlboss2chuanyang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if player:objectName() == use.from:objectName() then
			local slash = use.card
			if slash:isKindOf("Slash") then
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				for _, p in sgs.qlist(use.to) do
					if p:getHandcardNum() + p:getEquips():length() > 2 then
						room:askForDiscard(p, self:objectName(), 2, 2, false, true)
					else
						p:throwAllCards()
					end
				end
			end
		end
	end

}
meizlboss2gongshou:addSkill(meizlboss2chuanyang)

sgs.LoadTranslationTable {
	["meizlboss2gongshou"] = "弓手",
	["#meizlboss2gongshou"] = "蜀汉的将士",
	["illustrator:meizlboss2gongshou"] = "",
	["designer:meizlboss2gongshou"] = "Mark1469",
	["meizlboss2chuanyang"] = "穿扬",
	[":meizlboss2chuanyang"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定目标后，目标角色须弃置两张牌（不足则全弃）。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L004 弩兵
meizlboss2nubing = sgs.General(extension, "meizlboss2nubing", "shu", 3, false, true, true)

meizlboss2qiangnu = sgs.CreateTargetModSkill {
	name = "meizlboss2qiangnu",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}

meizlboss2nubing:addSkill(meizlboss2qiangnu)

sgs.LoadTranslationTable {
	["meizlboss2nubing"] = "弩兵",
	["#meizlboss2nubing"] = "蜀汉的将士",
	["illustrator:meizlboss2nubing"] = "",
	["designer:meizlboss2nubing"] = "Mark1469",
	["meizlboss2qiangnu"] = "强弩",
	[":meizlboss2qiangnu"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】无次数和距离限制。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L005 军师
meizlboss2junshi = sgs.General(extension, "meizlboss2junshi", "shu", 3, false, true, true)

meizlboss2guantian = sgs.CreateTriggerSkill {
	name = "meizlboss2guantian",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getKingdom() == player:getKingdom() then
					p:drawCards(1)
				end
			end
		end
	end
}

meizlboss2junshi:addSkill(meizlboss2guantian)

sgs.LoadTranslationTable {
	["meizlboss2junshi"] = "军师",
	["#meizlboss2junshi"] = "蜀汉的将士",
	["illustrator:meizlboss2junshi"] = "",
	["designer:meizlboss2junshi"] = "Mark1469",
	["meizlboss2guantian"] = "观天",
	[":meizlboss2guantian"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，与你势力相同的角色各摸一张牌。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L006 援兵
meizlboss2yuanbing = sgs.General(extension, "meizlboss2yuanbing", "shu", 3, false, true, true)

meizlboss2ziliang = sgs.CreateTriggerSkill {
	name = "meizlboss2ziliang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == player:getKingdom() and p:getHp() < player:getHp() then
					local recover = sgs.RecoverStruct()
					recover.recover = 1
					recover.who = player
					room:recover(p, recover)
				end
			end
		end
	end
}

meizlboss2yuanbing:addSkill(meizlboss2ziliang)

sgs.LoadTranslationTable {
	["meizlboss2yuanbing"] = "援兵",
	["#meizlboss2yuanbing"] = "蜀汉的将士",
	["illustrator:meizlboss2yuanbing"] = "",
	["designer:meizlboss2yuanbing"] = "Mark1469",
	["meizlboss2ziliang"] = "资粮",
	[":meizlboss2ziliang"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，与你势力相同且体力值低于你的角色各回复1点体力。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L007 炮兵
meizlboss2paobing = sgs.General(extension, "meizlboss2paobing", "shu", 3, false, true, true)

meizlboss2yinhuo = sgs.CreateTriggerSkill {
	name = "meizlboss2yinhuo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = p
				damage.damage = 1
				damage.nature = sgs.DamageStruct_Fire
				room:damage(damage)
			end
		end
	end
}

meizlboss2paobing:addSkill(meizlboss2yinhuo)

sgs.LoadTranslationTable {
	["meizlboss2paobing"] = "炮兵",
	["#meizlboss2paobing"] = "蜀汉的将士",
	["illustrator:meizlboss2paobing"] = "",
	["designer:meizlboss2paobing"] = "Mark1469",
	["meizlboss2yinhuo"] = "引火",
	[":meizlboss2yinhuo"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你对所有其他角色各造成1点火焰伤害。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L008 将军
meizlboss2jiangjun = sgs.General(extension, "meizlboss2jiangjun", "shu", 10, false, true, true)

meizlboss2haoling = sgs.CreateTriggerSkill {
	name = "meizlboss2haoling",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == player:getKingdom() then
					p:drawCards(1)
				else
					room:askForDiscard(p, self:objectName(), 1, 1, false, true)
				end
			end
		end
	end
}

meizlboss2jiangjunkingdom = sgs.CreateTriggerSkill {
	name = "#meizlboss2jiangjunkingdom",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	priority = 4,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
	end
}

meizlboss2jiangjun:addSkill(meizlboss2haoling)
meizlboss2jiangjun:addSkill(meizlboss2jiangjunkingdom)

sgs.LoadTranslationTable {
	["meizlboss2jiangjun"] = "将军",
	["#meizlboss2jiangjun"] = "蜀军之首",
	["illustrator:meizlboss2jiangjun"] = "",
	["designer:meizlboss2jiangjun"] = "Mark1469",
	["meizlboss2haoling"] = "号令",
	[":meizlboss2haoling"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，与你势力相同的角色各摸一张牌；与你势力不同的角色各弃置一张牌。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L009 魔兵
meizlboss2mobing = sgs.General(extension, "meizlboss2mobing", "sevendevil", 3, false, true, true)
meizlboss2dusha = sgs.CreateTriggerSkill {
	name = "meizlboss2dusha",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if player:objectName() == use.from:objectName() then
			local slash = use.card
			if slash:isKindOf("Slash") then
				local x = math.random(1, 4)
				if x == 1 then
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					for _, p in sgs.qlist(use.to) do
						room:loseHp(p, 1)
					end
				end
			end
		end
	end

}

meizlboss2mobingchange = sgs.CreateTriggerSkill {
	name = "#meizlboss2mobingchange",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	priority = 4,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getGeneralName() == "meizlbooss2rhmufunren" then return false end
		local log = sgs.LogMessage()
		log.type = "#meizlboss2mobingchange"
		log.from = player
		room:sendLog(log)
		room:setPlayerProperty(player, "kingdom", sgs.QVariant("sevendevil"))
		room:changeHero(player, "meizlboss2mobing", false, false, true, true)
	end
}

meizlboss2mobing:addSkill(meizlboss2dusha)
meizlboss2bubing:addSkill(meizlboss2mobingchange)
meizlboss2qibing:addSkill(meizlboss2mobingchange)
meizlboss2gongshou:addSkill(meizlboss2mobingchange)
meizlboss2nubing:addSkill(meizlboss2mobingchange)
meizlboss2junshi:addSkill(meizlboss2mobingchange)
meizlboss2yuanbing:addSkill(meizlboss2mobingchange)
meizlboss2paobing:addSkill(meizlboss2mobingchange)


sgs.LoadTranslationTable {
	["meizlboss2mobing"] = "魔兵",
	["#meizlboss2mobing"] = "罪恶的根源",
	["illustrator:meizlboss2mobing"] = "",
	["designer:meizlboss2mobing"] = "Mark1469",
	["meizlboss2dusha"] = "毒杀",
	[":meizlboss2dusha"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定目标后，目标角色有25%机率失去1点体力。",
	["#meizlboss2mobingchange"] = "%from受到妖气影响，变成了魔界七将的傀儡。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L010 魔将
meizlboss2mojiang = sgs.General(extension, "meizlboss2mojiang", "sevendevil", 20, false, true, true)

meizlboss2nuesha = sgs.CreateTriggerSkill {
	name = "meizlboss2nuesha",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if player:objectName() == use.from:objectName() then
			local slash = use.card
			if slash:isKindOf("Slash") then
				local x = math.random(1, 2)
				if x == 1 then
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					for _, p in sgs.qlist(use.to) do
						room:loseHp(p, 1)
					end
				end
			end
		end
	end

}
meizlboss2mojiang:addSkill(meizlboss2nuesha)

sgs.LoadTranslationTable {
	["meizlboss2mojiang"] = "魔将",
	["#meizlboss2mojiang"] = "罪魁祸首",
	["illustrator:meizlboss2mojiang"] = "",
	["designer:meizlboss2mojiang"] = "Mark1469",
	["meizlboss2nuesha"] = "虐杀",
	[":meizlboss2nuesha"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定目标后，目标角色有50%机率失去1点体力。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L011 野心家
meizlboss2yexinjia = sgs.General(extension, "meizlboss2yexinjia", "sevendevil", 30, false, true, true)

meizlboss2tuji = sgs.CreateTriggerSkill {
	name = "meizlboss2tuji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() then
				local slash = use.card
				if slash:isKindOf("Slash") then
					if not room:askForSkillInvoke(player, self:objectName()) then return false end
					local x = math.random(1, 4)
					if x ~= 1 then
						for _, p in sgs.qlist(use.to) do
							room:loseHp(p, 1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			local card_use = sgs.CardUseStruct()
			card_use.from = player
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p, nil, false) then
					card_use.to:append(p)
				end
			end
			card_use.card = slash
			room:useCard(card_use, true)
		end
	end

}
meizlboss2yexinjia:addSkill(meizlboss2tuji)
meizlboss2yexinjia:addSkill("lianpo")
meizlboss2yexinjia:addSkill("wansha")
meizlboss2yexinjia:addSkill("zhaoxin")
meizlboss2yexinjia:addSkill("mieji")

sgs.LoadTranslationTable {
	["meizlboss2yexinjia"] = "野心家",
	["#meizlboss2yexinjia"] = "背叛的佼佼者",
	["illustrator:meizlboss2yexinjia"] = "",
	["designer:meizlboss2yexinjia"] = "Mark1469",
	["meizlboss2tuji"] = "突击",
	[":meizlboss2tuji"] = "准备阶段开始时，你可以视为对所有其他角色使用一张【杀】；每当你使用【杀】指定目标后，目标角色有75%机率失去1点体力。",
}
---------------------------------------------------------------
--MEIZL BOSS2 RH L001 穆夫人‧弱化
meizlbooss2rhmufunren = sgs.General(extension, "meizlbooss2rhmufunren", "shu", 10, false, true, true)
meizlbooss2rhmufunren:addSkill(meizlboss2mobingchange)
sgs.LoadTranslationTable {
	["meizlbooss2rhmufunren"] = "穆夫人‧弱化",
	["&meizlbooss2rhmufunren"] = "穆夫人",
	["#meizlbooss2rhmufunren"] = "昭穆皇后",
	["illustrator:meizlbooss2rhmufunren"] = "",
	["designer:meizlbooss2rhmufunren"] = "Mark1469",
}
---------------------------------------------------------------
--MEIZL BOSS2 RH L002 甘夫人‧弱化
meizlbooss2rhganfunren = sgs.General(extension, "meizlbooss2rhganfunren", "shu", 8, false, true, true)
sgs.LoadTranslationTable {
	["meizlbooss2rhganfunren"] = "甘夫人‧弱化",
	["&meizlbooss2rhganfunren"] = "甘夫人",
	["#meizlbooss2rhganfunren"] = "神智妇人",
	["illustrator:meizlbooss2rhganfunren"] = "",
	["designer:meizlbooss2rhganfunren"] = "Mark1469",
}
---------------------------------------------------------------
--MEIZL BOSS2 L001 穆夫人
meizlbooss2mufunren = sgs.General(extension, "meizlbooss2mufunren", "shu", 10, false, true, true)

meizlbooss2muyi     = sgs.CreateTriggerSkill {
	name = "meizlbooss2muyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHandcardNum() > player:getHp() then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2muyi"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			return true
		end
	end
}

meizlbooss2zhangle  = sgs.CreateTriggerSkill {
	name = "meizlbooss2zhangle",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:drawCards(1)
		end
	end
}

meizlbooss2zhaomu   = sgs.CreateTriggerSkill {
	name = "meizlbooss2zhaomu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() > player:getHp() and p:getHandcardNum() > player:getHandcardNum() then
					room:askForDiscard(p, self:objectName(), 1, 1, false, true)
				end
			end
		end
	end
}


meizlbooss2mufunren:addSkill(meizlbooss2muyi)
meizlbooss2mufunren:addSkill(meizlbooss2zhaomu)
meizlbooss2mufunren:addSkill(meizlbooss2zhangle)
sgs.LoadTranslationTable {
	["meizlbooss2mufunren"] = "穆夫人",
	["#meizlbooss2mufunren"] = "昭穆皇后",
	["illustrator:meizlbooss2mufunren"] = "",
	["designer:meizlbooss2mufunren"] = "Mark1469",
	["meizlbooss2muyi"] = "母仪",
	[":meizlbooss2muyi"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，若你手牌数大于体力值，你防止你受到的伤害。",
	["#meizlbooss2muyi"] = "%from的技能【%arg】被触发，防止此次受到的伤害。",
	["meizlbooss2zhaomu"] = "昭穆",
	[":meizlbooss2zhaomu"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，所有体力值大于你且手牌数大于你的角色各弃置一张牌。",
	["meizlbooss2zhangle"] = "长乐",
	[":meizlbooss2zhangle"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，你摸一张牌。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L002 甘夫人
meizlbooss2ganfunren = sgs.General(extension, "meizlbooss2ganfunren", "shu", 8, false, true, true)

meizlbooss2huangsi = sgs.CreateTriggerSkill {
	name = "meizlbooss2huangsi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:isWounded() then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:throwAllHandCards()
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end
	end
}

meizlbooss2xiuren = sgs.CreateTriggerSkill {
	name = "meizlbooss2xiuren",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		for i = 1, recover.recover, 1 do
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() then
					room:askForDiscard(p, "meizlbooss2xiuren", 1, 1, false, true)
				end
			end
		end
	end
}

meizlbooss2baiyu = sgs.CreateTriggerSkill {
	name = "meizlbooss2baiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 4)
		if x == 1 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2baiyu1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2baiyu2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2ganfunren:addSkill(meizlbooss2huangsi)
meizlbooss2ganfunren:addSkill(meizlbooss2xiuren)
meizlbooss2ganfunren:addSkill(meizlbooss2baiyu)
sgs.LoadTranslationTable {
	["meizlbooss2ganfunren"] = "甘夫人",
	["#meizlbooss2ganfunren"] = "神智妇人",
	["illustrator:meizlbooss2ganfunren"] = "",
	["designer:meizlbooss2ganfunren"] = "Mark1469",
	["meizlbooss2huangsi"] = "皇思",
	[":meizlbooss2huangsi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，若你已受伤，你弃置所有手牌并回复1点体力。",
	["meizlbooss2xiuren"] = "修仁",
	[":meizlbooss2xiuren"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你回复1点体力后，所有角色各弃置一张牌。",
	["meizlbooss2baiyu"] = "白玉",
	["#meizlbooss2baiyu1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害。",
	["#meizlbooss2baiyu2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	[":meizlbooss2baiyu"] = "<font color=\"blue\"><b>锁定技，</b></font>你有25%机率防止你受到的伤害。",
}
---------------------------------------------------------------
--MEIZL BOSS2 SH L001 穆夫人-升华
meizlbooss2shmufunren    = sgs.General(extension, "meizlbooss2shmufunren", "shu", 12, false, true, true)

meizlbooss2shmuyi        = sgs.CreateTriggerSkill {
	name = "meizlbooss2shmuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 2)
		if x == 1 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2shmuyi1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2shmuyi2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2shzhangle     = sgs.CreateTriggerSkill {
	name = "meizlbooss2shzhangle",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2mufunrenmark")
			player:drawCards(3)
		end
	end
}

meizlbooss2shzhaomu      = sgs.CreateTriggerSkill {
	name = "meizlbooss2shzhaomu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2mufunrenmark")
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() > player:getHp() then
					room:askForDiscard(p, self:objectName(), 1, 1, false, true)
				end
			end
		end
	end
}

meizlbooss2shuzhihaoling = sgs.CreateTriggerSkill {
	name = "meizlbooss2shuzhihaoling",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("@meizlbooss2mufunrenmark") >= 2 then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				player:loseMark("@meizlbooss2mufunrenmark", 2)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				local card_use = sgs.CardUseStruct()
				card_use.from = player
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(p, nil, false) and p:getKingdom() ~= "shu" then
						card_use.to:append(p)
					end
				end
				card_use.card = slash
				room:useCard(card_use, false)
			end
		end
	end
}
meizlbooss2shmufunren:addSkill(meizlbooss2shmuyi)
meizlbooss2shmufunren:addSkill(meizlbooss2shzhaomu)
meizlbooss2shmufunren:addSkill(meizlbooss2shzhangle)
meizlbooss2shmufunren:addSkill(meizlbooss2shuzhihaoling)

sgs.LoadTranslationTable {
	["meizlbooss2shmufunren"] = "穆夫人-升华",
	["&meizlbooss2shmufunren"] = "穆夫人",
	["@meizlbooss2mufunrenmark"] = "无双标记-穆夫人",
	["#meizlbooss2shmufunren"] = "昭穆皇后",
	["illustrator:meizlbooss2shmufunren"] = "",
	["designer:meizlbooss2shmufunren"] = "Mark1469",
	["meizlbooss2shmuyi"] = "母仪-升华",
	[":meizlbooss2shmuyi"] = "<font color=\"blue\"><b>锁定技，</b></font>你有50%机率防止你受到的伤害。",
	["#meizlbooss2shmuyi1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害。",
	["#meizlbooss2shmuyi2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	["meizlbooss2shzhaomu"] = "昭穆-升华",
	[":meizlbooss2shzhaomu"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你弃置所有体力值大于你的角色各一张牌。",
	["meizlbooss2shzhangle"] = "长乐-升华",
	[":meizlbooss2shzhangle"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，你摸三张牌。",
	["meizlbooss2shuzhihaoling"] = "蜀之号令",
	[":meizlbooss2shuzhihaoling"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(2)</font></b>，准备阶段开始时，你可以视为你对所有非蜀势力角色使用了一张【杀】。",
}
---------------------------------------------------------------
--MEIZL BOSS2 L002 甘夫人-升华
meizlbooss2shganfunren = sgs.General(extension, "meizlbooss2shganfunren", "shu", 8, false, true, true)

meizlbooss2shhuangsi = sgs.CreateTriggerSkill {
	name = "meizlbooss2shhuangsi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:isWounded() then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2ganfunrenmark", 1)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end
	end
}

meizlbooss2shxiuren = sgs.CreateTriggerSkill {
	name = "meizlbooss2shxiuren",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		player:gainMark("@meizlbooss2ganfunrenmark", 1)
		for i = 1, recover.recover, 1 do
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() and p:getKingdom() ~= "shu" then
					room:askForDiscard(p, "meizlbooss2shxiuren", 1, 1, false, true)
				end
			end
		end
	end
}

meizlbooss2shbaiyu = sgs.CreateTriggerSkill {
	name = "meizlbooss2shbaiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 4)
		if x == 1 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2shbaiyu1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2shbaiyu2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2dadideenze = sgs.CreateTriggerSkill {
	name = "meizlbooss2dadideenze",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlbooss2dadideenze") > 0 then
				room:setPlayerMark(player, "meizlbooss2dadideenze", 0)
				room:detachSkillFromPlayer(player, "meizlbooss2dadideenzeskill")
			end
			if player:getMark("@meizlbooss2ganfunrenmark") >= 3 then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				room:setPlayerMark(player, "meizlbooss2dadideenze", 1)
				player:loseMark("@meizlbooss2ganfunrenmark", 3)
				room:acquireSkill(player, "meizlbooss2dadideenzeskill")
			end
		end
	end
}

meizlbooss2dadideenzeskill = sgs.CreateTriggerSkill {
	name = "meizlbooss2dadideenzeskill",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			player:drawCards(2)
		end
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlbooss2dadideenzeskill") then skills:append(meizlbooss2dadideenzeskill) end
sgs.Sanguosha:addSkills(skills)
meizlbooss2shganfunren:addSkill(meizlbooss2shhuangsi)
meizlbooss2shganfunren:addSkill(meizlbooss2shxiuren)
meizlbooss2shganfunren:addSkill(meizlbooss2shbaiyu)
meizlbooss2shganfunren:addSkill(meizlbooss2dadideenze)
sgs.LoadTranslationTable {
	["meizlbooss2shganfunren"] = "甘夫人-升华",
	["&meizlbooss2shganfunren"] = "甘夫人",
	["@meizlbooss2ganfunrenmark"] = "无双标记-甘夫人",
	["#meizlbooss2shganfunren"] = "神智妇人",
	["illustrator:meizlbooss2shganfunren"] = "",
	["designer:meizlbooss2shganfunren"] = "Mark1469",
	["meizlbooss2shhuangsi"] = "皇思-升华",
	[":meizlbooss2shhuangsi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，若你已受伤，你回复1点体力。",
	["meizlbooss2shxiuren"] = "修仁-升华",
	[":meizlbooss2shxiuren"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你回复1点体力后，非蜀势力角色各弃置一张牌。",
	["meizlbooss2shbaiyu"] = "白玉-升华",
	["#meizlbooss2shbaiyu1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害并回复1点体力。",
	["#meizlbooss2shbaiyu2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	[":meizlbooss2shbaiyu"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，你有25%机率防止伤害并改为回复1点体力。",
	["meizlbooss2dadideenze"] = "大地的恩泽",
	[":meizlbooss2dadideenze"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(3)</font></b>，准备阶段开始时，你可以获得以下效果：一回合内，每当你受到一次伤害后，你摸两张牌。",
	["meizlbooss2dadideenzeskill"] = "大地的恩泽（效果）",
	[":meizlbooss2dadideenzeskill"] = "每当你受到一次伤害后，你摸两张牌。",
}
---------------------------------------------------------------
--MEIZL BOSS2 JF L001 穆夫人-解放
meizlbooss2jfmufunren        = sgs.General(extension, "meizlbooss2jfmufunren", "shu", 12, false, true, true)

meizlbooss2jfmuyi            = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfmuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 4)
		if x <= 3 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jfmuyi1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jfmuyi2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2jfzhangle         = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfzhangle",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2mufunrenmark")
			player:drawCards(player:getMaxHp() - player:getHandcardNum())
		end
	end
}

meizlbooss2jfzhaomu          = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfzhaomu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2mufunrenmark")
			local damage = sgs.DamageStruct()
			damage.from = player
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() > player:getHp() then
					damage.to = p
					damage.damage = 1
					room:damage(damage)
				end
			end
		end
	end
}

meizlbooss2jishuhandahaoling = sgs.CreateTriggerSkill {
	name = "meizlbooss2jishuhandahaoling",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("@meizlbooss2mufunrenmark") >= 2 then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				player:loseMark("@meizlbooss2mufunrenmark", 2)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getKingdom() ~= "shu" then
						room:loseHp(p, math.ceil(p:getHp() / 10))
					end
				end
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				local card_use = sgs.CardUseStruct()
				card_use.from = player
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(p, nil, false) and p:getKingdom() ~= "shu" then
						card_use.to:append(p)
					end
				end
				card_use.card = slash
				room:useCard(card_use, false)
			end
		end
	end
}
meizlbooss2jfmufunren:addSkill(meizlbooss2jfmuyi)
meizlbooss2jfmufunren:addSkill(meizlbooss2jfzhaomu)
meizlbooss2jfmufunren:addSkill(meizlbooss2jfzhangle)
meizlbooss2jfmufunren:addSkill(meizlbooss2jishuhandahaoling)

sgs.LoadTranslationTable {
	["meizlbooss2jfmufunren"] = "穆夫人-解放",
	["&meizlbooss2jfmufunren"] = "穆夫人",
	["#meizlbooss2jfmufunren"] = "昭穆皇后",
	["illustrator:meizlbooss2jfmufunren"] = "",
	["designer:meizlbooss2jfmufunren"] = "Mark1469",
	["meizlbooss2jfmuyi"] = "母仪-解放",
	[":meizlbooss2jfmuyi"] = "<font color=\"blue\"><b>锁定技，</b></font>你有75%机率防止你受到的伤害。",
	["#meizlbooss2jfmuyi1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害。",
	["#meizlbooss2jfmuyi2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	["meizlbooss2jfzhaomu"] = "昭穆-解放",
	[":meizlbooss2jfzhaomu"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你对所有体力值大于你的角色各造成1点伤害。",
	["meizlbooss2jfzhangle"] = "长乐-解放",
	[":meizlbooss2jfzhangle"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，你将手牌补至体力上限。",
	["meizlbooss2jishuhandahaoling"] = "极-蜀汉大号令",
	[":meizlbooss2jishuhandahaoling"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(2)</font></b>，准备阶段开始时，你可以令所有非蜀势力角色扣减10%体力（向上取整），并视为你对所有非势力角色使用了一张【杀】。",
}
---------------------------------------------------------------
--MEIZL BOSS2 JF L002 甘夫人-解放
meizlbooss2jfganfunren = sgs.General(extension, "meizlbooss2jfganfunren", "shu", 8, false, true, true)

meizlbooss2jfhuangsi = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfhuangsi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2ganfunrenmark", 1)
			local recover = sgs.RecoverStruct()
			recover.who = player
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "shu" then
					room:recover(p, recover)
				end
			end
		end
	end
}

meizlbooss2jfxiuren = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfxiuren",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		player:gainMark("@meizlbooss2ganfunrenmark", 1)
		for i = 1, recover.recover, 1 do
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() and p:getKingdom() ~= "shu" then
					room:askForDiscard(p, self:objectName(), 2, 2, false, true)
				end
			end
		end
	end
}

meizlbooss2jfbaiyu = sgs.CreateTriggerSkill {
	name = "meizlbooss2jfbaiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 2)
		if x == 1 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jfbaiyu1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jfbaiyu2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2nvshendeenci = sgs.CreateTriggerSkill {
	name = "meizlbooss2nvshendeenci",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlbooss2nvshendeenci") > 0 then
				room:setPlayerMark(player, "meizlbooss2nvshendeenci", 0)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:detachSkillFromPlayer(p, "meizlbooss2nvshendeenciskill")
				end
			end
			if player:getMark("@meizlbooss2ganfunrenmark") >= 2 then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				room:setPlayerMark(player, "meizlbooss2nvshendeenci", 1)
				player:loseMark("@meizlbooss2ganfunrenmark", 2)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getKingdom() == "shu" then
						room:acquireSkill(p, "meizlbooss2nvshendeenciskill")
					end
				end
			end
		end
	end
}

meizlbooss2nvshendeenciskill = sgs.CreateTriggerSkill {
	name = "meizlbooss2nvshendeenciskill",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			player:drawCards(2)
		end
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlbooss2nvshendeenciskill") then skills:append(meizlbooss2nvshendeenciskill) end
sgs.Sanguosha:addSkills(skills)
meizlbooss2jfganfunren:addSkill(meizlbooss2jfhuangsi)
meizlbooss2jfganfunren:addSkill(meizlbooss2jfxiuren)
meizlbooss2jfganfunren:addSkill(meizlbooss2jfbaiyu)
meizlbooss2jfganfunren:addSkill(meizlbooss2nvshendeenci)
sgs.LoadTranslationTable {
	["meizlbooss2jfganfunren"] = "甘夫人-解放",
	["&meizlbooss2jfganfunren"] = "甘夫人",
	["#meizlbooss2jfganfunren"] = "神智妇人",
	["illustrator:meizlbooss2jfganfunren"] = "",
	["designer:meizlbooss2jfganfunren"] = "Mark1469",
	["meizlbooss2jfhuangsi"] = "皇思-解放",
	[":meizlbooss2jfhuangsi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，所有蜀势力各回复1点体力。",
	["meizlbooss2jfxiuren"] = "修仁-解放",
	[":meizlbooss2jfxiuren"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你回复1点体力后，非蜀势力角色各弃置两张牌。",
	["meizlbooss2jfbaiyu"] = "白玉-解放",
	["#meizlbooss2jfbaiyu1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害并回复1点体力。",
	["#meizlbooss2jfbaiyu2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	[":meizlbooss2jfbaiyu"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，你有50%机率防止伤害并改为回复1点体力。",
	["meizlbooss2nvshendeenci"] = "女神的恩赐",
	[":meizlbooss2nvshendeenci"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(2)</font></b>，准备阶段开始时，你可以令所有蜀势力角色获得以下效果：一回合内，每当你受到一次伤害后，你摸两张牌。",
	["meizlbooss2nvshendeenciskill"] = "女神的恩赐（效果）",
	[":meizlbooss2nvshendeenciskill"] = "每当你受到一次伤害后，你摸两张牌。",
}
---------------------------------------------------------------
--MEIZL BOSS2 JJJF L001 穆夫人-究极解放
meizlbooss2jjjfmufunren      = sgs.General(extension, "meizlbooss2jjjfmufunren", "shu", 8, false, true, true)

meizlbooss2jjjfmuyi          = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfmuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alive = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == "meizlbooss2jjjfganfunren" then
				alive = true
			end
		end
		if alive == true then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jjjfmuyi"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			return true
		end
	end
}

meizlbooss2jjjfzhangle       = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfzhangle",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local target
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if p:getGeneralName() == "meizlbooss2jjjfganfunren" then
					target = p
				end
			end
			if target:isDead() then
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				player:throwAllCards()
				room:revivePlayer(target)
			end
		end
	end
}

meizlbooss2jjjfzhaomu        = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfzhaomu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			local damage = sgs.DamageStruct()
			damage.from = player
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() ~= "shu" then
					damage.to = p
					damage.damage = 1
					room:damage(damage)
				end
			end
		end
	end
}

meizlbooss2bashuhandahaoling = sgs.CreateTriggerSkill {
	name = "meizlbooss2bashuhandahaoling",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			player:loseMark("@meizlbooss2mufunrenmark", 0)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() ~= "shu" then
					room:loseHp(p, math.ceil(p:getHp() / 20))
				end
			end
			for _, q in sgs.qlist(room:getAlivePlayers()) do
				if q:getKingdom() == "shu" and q:isAlive() then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					local card_use = sgs.CardUseStruct()
					card_use.from = q
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canSlash(p, nil, false) and p:getKingdom() ~= "shu" and p:isAlive() then
							card_use.to:append(p)
						end
					end
					card_use.card = slash
					room:useCard(card_use, false)
				end
			end
		end
	end
}
meizlbooss2jjjfmufunren:addSkill(meizlbooss2jjjfmuyi)
meizlbooss2jjjfmufunren:addSkill(meizlbooss2jjjfzhaomu)
meizlbooss2jjjfmufunren:addSkill(meizlbooss2jjjfzhangle)
meizlbooss2jjjfmufunren:addSkill(meizlbooss2bashuhandahaoling)

sgs.LoadTranslationTable {
	["meizlbooss2jjjfmufunren"] = "穆夫人-究极解放",
	["&meizlbooss2jjjfmufunren"] = "穆夫人",
	["#meizlbooss2jjjfmufunren"] = "昭穆皇后",
	["illustrator:meizlbooss2jjjfmufunren"] = "",
	["designer:meizlbooss2jjjfmufunren"] = "Mark1469",
	["meizlbooss2jjjfmuyi"] = "母仪-究极解放",
	[":meizlbooss2jjjfmuyi"] = "<font color=\"blue\"><b>锁定技，</b></font>甘夫人‧究极解放存活时，你防止你受到的伤害。",
	["#meizlbooss2jjjfmuyi"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害。",
	["meizlbooss2jjjfzhaomu"] = "昭穆-究极解放",
	[":meizlbooss2jjjfzhaomu"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你对所有非蜀势力角色各造成1点伤害。",
	["meizlbooss2jjjfzhangle"] = "长乐-究极解放",
	[":meizlbooss2jjjfzhangle"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，若甘夫人‧究极解放已阵亡，你弃置所有牌并将你的武将牌翻面，然后甘夫人‧究极解放复活。",
	["meizlbooss2bashuhandahaoling"] = "霸-蜀汉大号令",
	[":meizlbooss2bashuhandahaoling"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(2)</font></b>，<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，所有非蜀势力角色扣减20%体力（向上取整），并视为所有蜀势力角色各对所有非势力角色使用了一张［杀］。",
}
---------------------------------------------------------------
--MEIZL BOSS2 JJJF L002 甘夫人-究极解放
meizlbooss2jjjfganfunren = sgs.General(extension, "meizlbooss2jjjfganfunren", "shu", 2, false, true, true)

meizlbooss2jjjfhuangsi = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfhuangsi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			player:gainMark("@meizlbooss2ganfunrenmark", 1)
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 2
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "shu" then
					room:recover(p, recover)
					p:drawCards(2)
				end
			end
		end
	end
}

meizlbooss2jjjfxiuren = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfxiuren",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		can_trigger = function(self, target)
			return target:getKingdom() == "shu"
		end
		local room = player:getRoom()
		local recover = data:toRecover()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = splayer
			log.arg = self:objectName()
			room:sendLog(log)
			for i = 1, recover.recover, 1 do
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isNude() and p:getKingdom() ~= "shu" then
						room:askForDiscard(p, self:objectName(), 2, 2, false, true)
					end
				end
			end
		end
	end
}

meizlbooss2jjjfbaiyu = sgs.CreateTriggerSkill {
	name = "meizlbooss2jjjfbaiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.random(1, 4)
		if x <= 3 then
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jjjfbaiyu1"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			return true
		else
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2jjjfbaiyu2"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end
}

meizlbooss2shenglinvshendeweixiao = sgs.CreateTriggerSkill {
	name = "meizlbooss2shenglinvshendeweixiao",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlbooss2shenglinvshendeweixiao") > 0 then
				room:setPlayerMark(player, "meizlbooss2shenglinvshendeweixiao", 0)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:detachSkillFromPlayer(p, "meizlbooss2shenglinvshendeweixiaoskill")
				end
			end
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			room:setPlayerMark(player, "meizlbooss2shenglinvshendeweixiao", 1)
			player:loseMark("@meizlbooss2ganfunrenmark", 0)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "shu" then
					room:acquireSkill(p, "meizlbooss2shenglinvshendeweixiaoskill")
				end
			end
		end
	end
}

meizlbooss2shenglinvshendeweixiaoskill = sgs.CreateTriggerSkill {
	name = "meizlbooss2shenglinvshendeweixiaoskill",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			player:drawCards(1)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
		end
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meizlbooss2shenglinvshendeweixiaoskill") then
	skills:append(
		meizlbooss2shenglinvshendeweixiaoskill)
end
sgs.Sanguosha:addSkills(skills)
meizlbooss2jjjfganfunren:addSkill(meizlbooss2jjjfhuangsi)
meizlbooss2jjjfganfunren:addSkill(meizlbooss2jjjfxiuren)
meizlbooss2jjjfganfunren:addSkill(meizlbooss2jjjfbaiyu)
meizlbooss2jjjfganfunren:addSkill(meizlbooss2shenglinvshendeweixiao)
sgs.LoadTranslationTable {
	["meizlbooss2jjjfganfunren"] = "甘夫人-究极解放",
	["&meizlbooss2jjjfganfunren"] = "甘夫人",
	["#meizlbooss2jjjfganfunren"] = "神智妇人",
	["illustrator:meizlbooss2jjjfganfunren"] = "",
	["designer:meizlbooss2jjjfganfunren"] = "Mark1469",
	["meizlbooss2jjjfhuangsi"] = "皇思-究极解放",
	[":meizlbooss2jjjfhuangsi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，所有蜀势力各回复2点体力并摸两张牌。",
	["meizlbooss2jjjfxiuren"] = "修仁-究极解放",
	[":meizlbooss2jjjfxiuren"] = "<font color=\"blue\"><b>锁定技，</b></font>每当蜀势力角色回复1点体力后，非蜀势力角色各弃置两张牌。",
	["meizlbooss2jjjfbaiyu"] = "白玉-究极解放",
	["#meizlbooss2jjjfbaiyu1"] = "%from的技能【%arg】被触发，成功防止此次受到的伤害并回复1点体力。",
	["#meizlbooss2jjjfbaiyu2"] = "%from的技能【%arg】发动失败，无法防止此次受到的伤害。",
	[":meizlbooss2jjjfbaiyu"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，你有75%机率防止伤害并改为回复1点体力。",
	["meizlbooss2shenglinvshendeweixiao"] = "胜利女神的微笑",
	[":meizlbooss2shenglinvshendeweixiao"] = "<b><font color=\"red\">无</font><font color=\"orange\">双</font><font color=\"purple\">技</font><font color=\"green\">(0)</font></b>，准备阶段开始时，你可以令所有蜀势力角色获得以下效果：一回合内，每当你受到一次伤害后，你摸一张牌并增加1点体力上限。",
	["meizlbooss2shenglinvshendeweixiaoskill"] = "胜利女神的微笑（效果）",
	[":meizlbooss2shenglinvshendeweixiaoskill"] = "每当你受到一次伤害后，你摸一张牌并增加1点体力上限。",
}
----------------------------------------------------------------------
meizlbooss2spskill = sgs.CreateTriggerSkill {
	name = "#meizlbooss2spskill",
	frequency = sgs.Skill_Frequent,
	events = { sgs.GameStart, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:getMark("@meizlbooss2round") == 0 then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(30))
			room:setPlayerProperty(player, "hp", sgs.QVariant(30))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spskill1"
			room:sendLog(log)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "@meizlbooss2round", player:getMark("@meizlbooss2round") + 1)
			elseif player:getPhase() == sgs.Player_NotActive then
				if player:getMark("@meizlbooss2round") == 1 then
					local log = sgs.LogMessage()
					log.type = "#meizlbooss2spskill2"
					room:sendLog(log)
				elseif player:getMark("@meizlbooss2round") == 2 then
					local log = sgs.LogMessage()
					log.type = "#meizlbooss2spskill3"
					room:sendLog(log)
				elseif player:getMark("@meizlbooss2round") == 3 then
					local log = sgs.LogMessage()
					log.type = "#meizlbooss2spskill4"
					room:sendLog(log)
					room:changeHero(player, "meizlboss2mojiang", true, true, true, true)
					room:setPlayerProperty(player, "kingdom", sgs.QVariant("sevendevil"))
					room:setPlayerProperty(player, "role", sgs.QVariant("rebel"))
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(40))
					room:setPlayerProperty(player, "hp", sgs.QVariant(40))
					room:updateStateItem()
					for _, p in sgs.qlist(room:getAllPlayers(true)) do
						if p:getKingdom() == "sevendevil" then
							if p:isDead() then
								room:revivePlayer(p)
								room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
							end
							room:setPlayerMark(p, "meizlbooss2revive", 1)
						end
					end
				elseif player:getMark("@meizlbooss2round") == 4 then
					local log = sgs.LogMessage()
					log.type = "#meizlbooss2spskill5"
					room:sendLog(log)
				elseif player:getMark("@meizlbooss2round") == 5 then
					local log = sgs.LogMessage()
					log.type = "#meizlbooss2spskill6"
					room:sendLog(log)
					room:changeHero(player, "meizlboss2yexinjia", true, false, true, true)
					room:setPlayerProperty(player, "kingdom", sgs.QVariant("sevendevil"))
					room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(80))
					room:setPlayerProperty(player, "hp", sgs.QVariant(80))
					room:updateStateItem()
				end
			end
		end
	end
}

meizlboss2jiangjun:addSkill(meizlbooss2spskill)
meizlboss2mojiang:addSkill(meizlbooss2spskill)
meizlboss2yexinjia:addSkill(meizlbooss2spskill)

meizlbooss2ganfunrenchangehero = sgs.CreateTriggerSkill {
	name = "#meizlbooss2ganfunrenchangehero",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlbooss2ganfunrenchangehero") == 1 then
				room:changeHero(player, "meizlbooss2ganfunren", true, true, false, true)
			elseif player:getMark("meizlbooss2ganfunrenchangehero") == 2 then
				room:changeHero(player, "meizlbooss2shganfunren", true, true, false, true)
			elseif player:getMark("meizlbooss2ganfunrenchangehero") == 3 then
				room:changeHero(player, "meizlbooss2jfganfunren", true, true, false, true)
			elseif player:getMark("meizlbooss2ganfunrenchangehero") == 4 then
				room:changeHero(player, "meizlbooss2jjjfganfunren", true, true, false, true)
			end
			room:setPlayerMark(player, "meizlbooss2ganfunrenchangehero",
				player:getMark("meizlbooss2ganfunrenchangehero") + 1)
		end
	end
}

meizlbooss2rhganfunren:addSkill(meizlbooss2ganfunrenchangehero)
meizlbooss2ganfunren:addSkill(meizlbooss2ganfunrenchangehero)
meizlbooss2shganfunren:addSkill(meizlbooss2ganfunrenchangehero)
meizlbooss2jfganfunren:addSkill(meizlbooss2ganfunrenchangehero)

meizlbooss2mufunrenchangehero = sgs.CreateTriggerSkill {
	name = "#meizlbooss2mufunrenchangehero",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("meizlbooss2mufunrenchangehero") == 1 then
				room:changeHero(player, "meizlbooss2mufunren", true, true, false, true)
			elseif player:getMark("meizlbooss2mufunrenchangehero") == 2 then
				room:changeHero(player, "meizlbooss2shmufunren", true, true, false, true)
			elseif player:getMark("meizlbooss2mufunrenchangehero") == 3 then
				room:changeHero(player, "meizlbooss2jfmufunren", true, true, false, true)
			elseif player:getMark("meizlbooss2mufunrenchangehero") == 4 then
				room:changeHero(player, "meizlbooss2jjjfmufunren", true, true, false, true)
			end
			room:setPlayerMark(player, "meizlbooss2mufunrenchangehero", player:getMark("meizlbooss2mufunrenchangehero") +
				1)
		end
	end
}

meizlbooss2rhmufunren:addSkill(meizlbooss2mufunrenchangehero)
meizlbooss2mufunren:addSkill(meizlbooss2mufunrenchangehero)
meizlbooss2shmufunren:addSkill(meizlbooss2mufunrenchangehero)
meizlbooss2jfmufunren:addSkill(meizlbooss2mufunrenchangehero)

sgs.LoadTranslationTable {
	["#meizlbooss2spskill1"] = "！ ！ ！紧急情况！ ！ ！若你不能在3回合内撃退敌军，你将会受魔气效果影响，变为反贼。",
	["#meizlbooss2spskill2"] = "！ ！ ！紧急情况！ ！ ！ 2回合后将受妖气影响！ ！ ！",
	["#meizlbooss2spskill3"] = "！ ！ ！紧急情况！ ！ ！ 1回合后将变身为反贼！请尽快击败敌人！",
	["#meizlbooss2spskill4"] = "！ ！ ！紧急情况！ ！ ！你受到妖气影响，变身为反贼！同时，所有魔兵将会复活。",
	["#meizlbooss2spskill5"] = "！ ！ ！紧急情况！ ！ ！在体内的妖气影响下，你的野心逐渐浮现出来，下回合将变为内奸。",
	["#meizlbooss2spskill6"] = "请注意！ ！ ！你已变为内奸，请尽快杀死所有其他武将。",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
meizlboss2bubingchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2bubingchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shenguanyu", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(9999))
			room:setPlayerProperty(player, "hp", sgs.QVariant(9999))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero1"
			room:sendLog(log)
		end
	end
}

meizlboss2qibingchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2qibingchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shencaocao", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(5000))
			room:setPlayerProperty(player, "hp", sgs.QVariant(5000))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero2"
			room:sendLog(log)
		end
	end
}

meizlboss2gongshouchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2gongshouchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shenzhouyu", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(7272))
			room:setPlayerProperty(player, "hp", sgs.QVariant(7272))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero3"
			room:sendLog(log)
		end
	end
}

meizlboss2nubingchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2nubingchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shenlvmeng", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(6000))
			room:setPlayerProperty(player, "hp", sgs.QVariant(6000))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero4"
			room:sendLog(log)
		end
	end
}

meizlboss2junshichangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2junshichangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shensimayi", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(5555))
			room:setPlayerProperty(player, "hp", sgs.QVariant(5555))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero5"
			room:sendLog(log)
		end
	end
}

meizlboss2yuanbingchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2yuanbingchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shenzhaoyun", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(30))
			room:setPlayerProperty(player, "hp", sgs.QVariant(30))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero6"
			room:sendLog(log)
		end
	end
}

meizlboss2paobingchangehero = sgs.CreateTriggerSkill {
	name = "#meizlboss2paobingchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = death.who:getRoom()
		if not death.who:hasSkill(self:objectName()) then return end
		if death.who:getMark("meizlbooss2revive") > 0 then
			room:revivePlayer(death.who)
			room:setPlayerMark(death.who, "meizlbooss2revive", 0)
			room:changeHero(player, "shenlvbu2", false, false, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(9899))
			room:setPlayerProperty(player, "hp", sgs.QVariant(9899))
			local log = sgs.LogMessage()
			log.type = "#meizlbooss2spchangehero7"
			room:sendLog(log)
		end
	end
}

meizlboss2bubing:addSkill(meizlboss2bubingchangehero)
meizlboss2qibing:addSkill(meizlboss2qibingchangehero)
meizlboss2gongshou:addSkill(meizlboss2gongshouchangehero)
meizlboss2nubing:addSkill(meizlboss2nubingchangehero)
meizlboss2junshi:addSkill(meizlboss2junshichangehero)
meizlboss2yuanbing:addSkill(meizlboss2yuanbingchangehero)
meizlboss2paobing:addSkill(meizlboss2paobingchangehero)
sgs.LoadTranslationTable {
	["#meizlbooss2spchangehero1"] = "以鬼神之名义起誓，我定必把这个世界陷入恐慌之中。",
	["#meizlbooss2spchangehero2"] = "来吧，臣服于我脚下，然后委曲求全吧！",
	["#meizlbooss2spchangehero3"] = "借此熊熊烈火洗涤大地，把一切野心、欲望都烧成灰烬！",
	["#meizlbooss2spchangehero4"] = "攻心为上，攻城为下，今天我就要你就葬身于此恐惧之中，永不超生。",
	["#meizlbooss2spchangehero5"] = "观今夜之星象，吾军定当大获全胜！",
	["#meizlbooss2spchangehero6"] = "飞龙在天，腾云驾雾，要你今天长眠于此！",
	["#meizlbooss2spchangehero7"] = "杂鱼们，挡我者死！",
}
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--珠联璧合 SP貂蝉 — 娘-吕布
--拜月（珠联璧合 SP貂蝉 — 娘-吕布）

meispzlbhbaiyue = sgs.CreateTriggerSkill
	{
		name = "meispzlbhbaiyue",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				if (player:getGeneralName() == "meispdiaochan" and player:getGeneral2Name() == "meispnianglvbu") or (player:getGeneral2Name() == "meispdiaochan" and player:getGeneralName() == "meispnianglvbu") then
					if player:askForSkillInvoke(self:objectName(), data) then
						local x = 0
						player:turnOver()
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("meispzlbhbaiyue")
						slash:deleteLater()
						local card_use = sgs.CardUseStruct()
						card_use.from = player
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canSlash(p, nil, false) then
								card_use.to:append(p)
								x = x + 1
							end
						end
						card_use.card = slash
						room:useCard(card_use, true)
						player:drawCards(x)
					end
				end
			end
		end
	}
--梳妆（珠联璧合 SP貂蝉 — 娘-吕布）
meispzlbhshuzhuangIntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

meispzlbhshuzhuang = sgs.CreateTriggerSkill {
	name = "meispzlbhshuzhuang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnedOver, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getGeneralName() == "meispdiaochan" and player:getGeneral2Name() == "meispnianglvbu") or (player:getGeneral2Name() == "meispdiaochan" and player:getGeneralName() == "meispnianglvbu") then
			if event == sgs.TurnedOver then
				if player:hasSkill(self:objectName()) then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isMale() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						local target = room:askForPlayerChosen(player, targets, self:objectName(),
							"meispzlbhshuzhuangchoose", true)
						if target then
							room:loseHp(target)
						end
					end
				end
			elseif event == sgs.TargetConfirmed then
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and not player:faceUp() and (use.from:objectName() == player:objectName()) then
					local log = sgs.LogMessage()
					log.type = "#meispzlbhshuzhuang"
					log.from = player
					for _, p in sgs.qlist(use.to) do
						log.to:append(p)
					end
					log.arg  = self:objectName()
					log.arg2 = 2
					room:sendLog(log)
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					for i = 0, use.to:length() - 1, 1 do
						if jink_table[i + 1] == 1 then
							jink_table[i + 1] = 2
						end
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(meispzlbhshuzhuangIntList(jink_table))
					player:setTag("Jink_" .. use.card:toString(), jink_data)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

meispzlbhshuzhuangeffect = sgs.CreateProhibitSkill {
	name = "#meispzlbhshuzhuangeffect",
	is_prohibited = function(self, from, to, card)
		return ((to:getGeneralName() == "meispdiaochan" and to:getGeneral2Name() == "meispnianglvbu") or (to:getGeneral2Name() == "meispdiaochan" and to:getGeneralName() == "meispnianglvbu")) and
			to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
			and from:isMale() and not to:faceUp()
	end
}



local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meispzlbhshuzhuang") then skills:append(meispzlbhshuzhuang) end
if not sgs.Sanguosha:getSkill("meispzlbhbaiyue") then skills:append(meispzlbhbaiyue) end
if not sgs.Sanguosha:getSkill("#meispzlbhshuzhuangeffect") then skills:append(meispzlbhshuzhuangeffect) end
sgs.Sanguosha:addSkills(skills)

extension:insertRelatedSkills("meispzlbhshuzhuang", "#meispzlbhshuzhuangeffect")
sgs.LoadTranslationTable {
	["meispzlbhbaiyue"] = "拜月",
	["@meispzlbhbaiyue-card"] = "请选择“拜月”的目标",
	["~meispzlbhbaiyue"] = "选择一名其他角色→点击确定",
	[":meispzlbhbaiyue"] = "<font color=\"pink\"><b>牵绊技，</b></font>结束阶段开始时，你可以将你的武将牌翻面，然后视为对所有其他角色使用了一张【杀】并摸X张牌（X为此【杀】的目标角色数）。",
	["meispzlbhshuzhuang"] = "梳妆",
	["#meispzlbhshuzhuangeffect"] = "梳妆",
	["#meispzlbhshuzhuang"] = "%from的技能【%arg】被触发，%to需要%arg2张【闪】才能抵消此【杀】。",
	["meispzlbhshuzhuangchoose"] = "你可以发动【梳妆】，令一名男性角色失去1点体力；或按取消。",
	[":meispzlbhshuzhuang"] = "<font color=\"pink\"><b>牵绊技，</b></font>每当你的武将牌翻面时，你可以令一名男性角色失去1点体力；若你的武将牌背面朝上，你获得以下技能：你不能成为男性角色的锦囊牌目标；每当你使用【杀】指定目标角色后，该角色需依次使用2张【闪】 才能抵消。",
}
mspzhurong = sgs.General(extension, "mspzhurong", "shu", 4, false)
newmspcaiwenji = sgs.General(extension, "newmspcaiwenji", "qun", 3, false)
newmspcaiwenjijh = sgs.General(extension, "newmspcaiwenjijh", "wei", 3, false, true)

newmspgodzhenji = sgs.General(extension, "newmspgodzhenji", "god", 3, false)
newmspgodzhenjijh = sgs.General(extension, "newmspgodzhenjijh", "god", 3, false, true)
newmspgodzhenjijhnd = sgs.General(extension, "newmspgodzhenjijhnd", "god", 3, false, true)



meizl_o_yuxiang = sgs.CreateTriggerSkill {
	name = "meizl_o_yuxiang",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark("&spirit") > 5 then
				if not room:askForSkillInvoke(player, "meizl_o_yuxiang") then return false end
				player:loseMark("&spirit", 6)
				local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
				savage_assault:setSkillName(self:objectName())
				local use = sgs.CardUseStruct()
				use.card = savage_assault
				savage_assault:deleteLater()
				use.from = player
				room:useCard(use, false)
			end
		end
	end
}

meizl_o_yuxiangs = sgs.CreateTriggerSkill
	{
		name = "#meizl_o_yuxiang",
		events = { sgs.Damage },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			local num = damage.damage
			local n = 0
			while n < num do
				player:gainMark("&spirit")
				n = n + 1
			end
			return
		end
	}

feiren = sgs.CreateTriggerSkill
	{
		name = "feiren",
		events = { sgs.Damage },
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if not damage.card then return end
			if not damage.card:isKindOf("Slash") then return end
			if damage.to:isAlive() then
				if player:getMark("&spirit") > 1 or player:getHp() < damage.to:getHandcardNum() then
					local dest = sgs.QVariant()
					dest:setValue(damage.to)
					if not room:askForSkillInvoke(player, "feiren", dest) then return false end
					if player:getHp() >= damage.to:getHandcardNum() then
						player:loseMark("&spirit", 2)
					end
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|red"
					judge.reason = "feiren"
					judge.who = player
					room:judge(judge)
					if (judge:isGood()) and not damage.to:isNude() then
						local card_id = room:askForCardChosen(player, damage.to, "he", "feiren")
						player:obtainCard(sgs.Sanguosha:getCard(card_id))
					end
				end
			end
		end
	}

mspzhurong:addSkill("juxiang")
mspzhurong:addSkill("#sa_avoid_juxiang")
mspzhurong:addSkill(meizl_o_yuxiang)
mspzhurong:addSkill(meizl_o_yuxiangs)
extension:insertRelatedSkills("meizl_o_yuxiang", "#meizl_o_yuxiang")
mspzhurong:addSkill(feiren)


hujias = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "hujias",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from == nil then return end
			if not room:askForSkillInvoke(player, "hujias", data) then return false end
			room:loseMaxHp(damage.from, 1)
			room:loseHp(damage.from, 1)
			local recover = sgs.RecoverStruct()
			recover.recover = 1
			recover.who = player
			room:recover(damage.from, recover)
			room:setPlayerProperty(damage.from, "maxhp", sgs.QVariant(damage.from:getMaxHp() + 1))
		end
	}
guyan_card = sgs.CreateSkillCard {
	name = "guyan",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,

	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local suit = room:askForSuit(effect.to, "guyan")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = effect.to
		log.arg = sgs.Card_Suit2String(suit)
		room:sendLog(log)
		local judge = sgs.JudgeStruct()
		judge.reason = self:objectName()
		judge.pattern = "."
		judge.who = effect.to
		room:judge(judge)
		if judge.card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.damage = 1
			damage.from = effect.from
			damage.to = effect.to
			room:damage(damage)
		end
		if effect.to:isAlive() then
			effect.to:obtainCard(judge.card)
		end
	end
}

guyan = sgs.CreateViewAsSkill {
	name = "guyan",
	n = 0,
	view_as = function()
		return guyan_card:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#guyan")
	end,
}
guihans = sgs.CreateTriggerSkill {
	name = "guihans",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:isWounded() then return false end
			if not room:askForSkillInvoke(player, "guihans") then return false end
			room:setPlayerMark(player, "&guihans", 1)
			room:handleAcquireDetachSkills(player, "-hujias|-guyan")
		end
	end
}

guihanss = sgs.CreateTriggerSkill {
	name = "#guihans",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("&guihans") > 0 then
				room:broadcastInvoke("animate", "lightbox:$Guihans:3000")
				room:getThread():delay(3000)
				room:handleAcquireDetachSkills(player, "-guihans")
				if player:getGeneralName() == "newmspcaiwenji" then
					room:changeHero(player, "newmspcaiwenjijh", false, false, false, false)
				elseif player:getGeneral2Name() == "newmspcaiwenji" then
					room:changeHero(player, "newmspcaiwenjijh", false, false, true, false)
				else
					player:getRoom():setPlayerProperty(player, "kingdom", sgs.QVariant("wei"))
					player:getRoom():handleAcquireDetachSkills(player, "guyanjh")
					player:getRoom():handleAcquireDetachSkills(player, "hujiajh")
				end
				room:setPlayerMark(player, "&guihans", 0)
			end
		end
	end,
}
newmspcaiwenji:addSkill(guyan)
newmspcaiwenji:addSkill(hujias)
newmspcaiwenji:addSkill(guihans)
newmspcaiwenji:addSkill(guihanss)
extension:insertRelatedSkills("guihans", "#guihans")

guyanjh = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "guyanjh",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from == nil then return end
			for _, splayer in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not player:isAlive() then return false end
				if splayer:isNude() then return false end
				if not room:askForSkillInvoke(splayer, "guyanjh", data) then return false end
				--room:setTag("CurrentDamageStruct", data)
				if room:askForDiscard(splayer, self:objectName(), 1, 1, true, true) then
					local suit = room:askForSuit(damage.from, "guyanjh")
					local log = sgs.LogMessage()
					log.type = "#ChooseSuit"
					log.from = damage.from
					log.arg = sgs.Card_Suit2String(suit)
					room:sendLog(log)
					local judge = sgs.JudgeStruct()
					judge.reason = self:objectName()
					judge.pattern = "."
					judge.who = damage.from
					room:judge(judge)
					if judge.card:getSuit() ~= suit then
						room:loseHp(damage.from, 1)
					end
				end
				--room:removeTag("CurrentDamageStruct")
			end
		end,
		can_trigger = function(self, player)
			return true
		end
	}
hujiajh = sgs.CreateTriggerSkill {
	name = "hujiajh",
	events = { sgs.BuryVictim },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local damage = death.damage
		if death.damage then
			local source = damage.from
			if source == nil then return false end
			room:loseMaxHp(source, player:getHandcardNum())
			room:loseHp(source, source:getHandcardNum())
		end
	end,
}
newmspcaiwenjijh:addSkill(guyanjh)
newmspcaiwenjijh:addSkill(hujiajh)



huixue = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "huixue",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if not room:askForSkillInvoke(player, "huixue") then return false end
			if not room:askForCard(player, "BasicCard", "@huixue", data, sgs.CardDiscarded) then return end
			local recover = sgs.RecoverStruct()
			recover.recover = 1
			recover.who = player
			room:recover(player, recover)
		end
	}

luoshenjh = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "luoshenjh",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if room:askForSkillInvoke(player, "luoshenjh") then
				local x = player:getHandcardNum()
				local ids = room:getNCards(x, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
					self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local card_to_throw = {}
				local card_to_gotback = {}
				for i = 0, x - 1, 1 do
					local id = ids:at(i)
					local card = sgs.Sanguosha:getCard(id)
					if card:isRed() then
						table.insert(card_to_throw, id)
					else
						table.insert(card_to_gotback, id)
					end
				end
				if #card_to_throw > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in ipairs(card_to_throw) do
						dummy:addSubcard(id)
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
						self:objectName(), nil)
					room:throwCard(dummy, reason, nil)
					dummy:deleteLater()
				end
				if #card_to_gotback > 0 then
					local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in ipairs(card_to_gotback) do
						dummy2:addSubcard(id)
					end
					dummy2:deleteLater()
					room:obtainCard(player, dummy2)
				end
			end
		end
	}

huixuejh = sgs.CreateTriggerSkill {
	name = "huixuejh",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if not player:isWounded() then return false end
			if not room:askForSkillInvoke(player, "huixuejh") then return false end
			local recover = sgs.RecoverStruct()
			recover.recover = 1
			recover.who = player
			room:recover(player, recover)
		end
	end
}

biyues = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "biyues",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from == nil then return end
			if damage.from:getGeneral():isMale() then
				if room:askForSkillInvoke(player, "biyues", data) then
					if damage.from:isNude() then return end
					local card = room:askForCardChosen(player, damage.from, "he", "biyues")
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(sgs.Sanguosha:getCard(card):getEffectiveId())
					move.to_place = sgs.Player_DrawPile
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move, true)
				end
			end
		end
	}

xiehou = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "xiehou",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Fire or damage.nature == sgs.DamageStruct_Thunder then
				if room:askForSkillInvoke(player, "xiehou") then
					room:broadcastInvoke("animate", "lightbox:$Xiehou:3000")
					room:getThread():delay(3000)
					if player:getGeneralName() == "newmspgodzhenji" then
						room:changeHero(player, "newmspgodzhenjijh", false, false, false, false)
					elseif player:getGeneral2Name() == "newmspgodzhenji" then
						room:changeHero(player, "newmspgodzhenjijh", false, false, true, false)
					else
						player:getRoom():handleAcquireDetachSkills(player, "-luoshen")
						player:getRoom():handleAcquireDetachSkills(player, "-huixue")
						player:getRoom():handleAcquireDetachSkills(player, "-xiehou")
						player:getRoom():handleAcquireDetachSkills(player, "luoshenjh")
						player:getRoom():handleAcquireDetachSkills(player, "biyues")
						player:getRoom():handleAcquireDetachSkills(player, "huixuejh")
						player:getRoom():handleAcquireDetachSkills(player, "meizi_shenfu")
					end
				end
			end
		end
	}

luoshenjhnd = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "luoshenjhnd",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			for i = 1, damage.damage, 1 do
				if room:askForSkillInvoke(player, "luoshenjhnd") then
					local x = player:getHandcardNum()
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
						self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i = 0, x - 1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						if card:isRed() then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
							self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						dummy:deleteLater()
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)
						dummy2:deleteLater()
					end
				end
			end
		end
	}

biyuejh = sgs.CreateTriggerSkill
	{
		frequency = sgs.Skill_NotFrequent,
		name = "biyuejh",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local dam = data:toDamage()
			if dam.from == nil then return end
			if dam.from:getGeneral():isMale() then
				if room:askForSkillInvoke(player, "biyuejh", data) then
					if dam.from:isNude() then return end
					local card = room:askForCardChosen(player, dam.from, "he", "biyuejh")
					local card_id = sgs.Sanguosha:getCard(card)
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(sgs.Sanguosha:getCard(card):getEffectiveId())
					move.to_place = sgs.Player_DrawPile
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move, true)
					if card_id:isBlack() then
						local damage = sgs.DamageStruct()
						damage.damage = 1
						damage.from = player
						damage.to = dam.from
						room:damage(damage)
					end
				end
			end
		end
	}

huixuejhnd = sgs.CreateTriggerSkill {
	name = "huixuejhnd",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if not room:askForSkillInvoke(player, "huixuejhnd") then return false end
			local choices = "draw"
			if player:isWounded() then
				choices = choices .. "+recover"
			end
			local choice = room:askForChoice(player, "huixuejhnd", choices)
			if choice == "draw" then
				player:drawCards(2)
			elseif choice == "recover" then
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
				room:recover(player, recover)
			end
		end
	end
}

shijuncard = sgs.CreateSkillCard {
	name = "shijun",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and sgs.Self:distanceTo(to_select) > 1 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], "shijuntarget", 1)
		room:setFixedDistance(source, targets[1], 1)
		room:setPlayerMark(targets[1], "&shijun+to+#" .. source:objectName(), 1)
	end,
}

shijunVS = sgs.CreateViewAsSkill {
	name = "shijun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local card = shijuncard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shijun")
	end,
}

shijun = sgs.CreateTriggerSkill {
	name = "shijun",
	events = { sgs.EventPhaseStart },
	view_as_skill = shijunVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("shijuntarget") > 0 then
				room:setPlayerMark(p, "shijuntarget", 0)
				room:setPlayerMark(p, "&shijun+to+#" .. player:objectName(), 0)
				room:removeFixedDistance(player, p, 1)
			end
		end
	end,
}

shixiang = sgs.CreateTriggerSkill {
	name = "shixiang",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shixiang",
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw then
			if player:getMark("@shixiang") > 0 then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, "shixiang") then
					room:broadcastInvoke("animate", "lightbox:$Shixiang:3000")
					room:getThread():delay(3000)
					local x = math.min(9, player:getHandcardNum() * 3)
					player:throwAllHandCards()
					player:drawCards(x)
					player:loseMark("@shixiang")
					room:setPlayerMark(player, "&shixiang", 1)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			if player:getMark("@shixiang") == 0 and player:getMark("&shixiang") > 0 then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Discard then
					room:setPlayerMark(player, "&shixiang", 0)
					player:skip(change.to)
				end
			end
		end
	end
}

meizi_shenfu = sgs.CreateTriggerSkill {
	name = "meizi_shenfu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
			if room:askForSkillInvoke(player, "meizi_shenfu") then
				room:broadcastInvoke("animate", "lightbox:$Shenfu:3000")
				room:getThread():delay(3000)
				if player:getGeneralName() == "newmspgodzhenjijh" then
					room:changeHero(player, "newmspgodzhenjijhnd", false, false, false, false)
				elseif player:getGeneral2Name() == "newmspgodzhenjijh" then
					room:changeHero(player, "newmspgodzhenjijhnd", false, false, true, false)
				else
					player:getRoom():handleAcquireDetachSkills(player, "-luoshenjh")
					player:getRoom():handleAcquireDetachSkills(player, "-biyues")
					player:getRoom():handleAcquireDetachSkills(player, "-huixuejh")
					player:getRoom():handleAcquireDetachSkills(player, "-meizi_shenfu")
					player:getRoom():handleAcquireDetachSkills(player, "luoshenjhnd")
					player:getRoom():handleAcquireDetachSkills(player, "biyuejh")
					player:getRoom():handleAcquireDetachSkills(player, "huixuejhnd")
					player:getRoom():handleAcquireDetachSkills(player, "shixiang")
					player:getRoom():handleAcquireDetachSkills(player, "shijun")
				end
			end
		end
	end,

}

newmspgodzhenji:addSkill("luoshen")
newmspgodzhenji:addSkill(huixue)
newmspgodzhenji:addSkill(xiehou)

newmspgodzhenjijh:addSkill(luoshenjh)
newmspgodzhenjijh:addSkill(biyues)
newmspgodzhenjijh:addSkill(huixuejh)
newmspgodzhenjijh:addSkill(meizi_shenfu)

newmspgodzhenjijhnd:addSkill(luoshenjhnd)
newmspgodzhenjijhnd:addSkill(biyuejh)
newmspgodzhenjijhnd:addSkill(huixuejhnd)
newmspgodzhenjijhnd:addSkill(shixiang)
newmspgodzhenjijhnd:addSkill(shijun)

sgs.LoadTranslationTable {
	["mei"] = "魅包",
	["spirit"] = "灵力值",

	["mspzhurong"] = "祝融",
	["#mspzhurong"] = "刺美人",
	["meizl_o_yuxiang"] = "御象",
	[":meizl_o_yuxiang"] = "<b><font color='pink'>灵动技:6</font></b>，回合开始阶段开始时，可​​以视为你使用了​​一张【南蛮入侵】。",
	["feiren"] = "飞刃",
	[":feiren"] = "<b><font color='pink'>灵动技:2</font></b>，每当你使用【杀】对目标角色造成一次伤害后，你可以进行一次判定，若判定结果为红色，你获得该角色的一张牌。若你的体力值少于目标角色的手牌数，你可以无视灵动条件。",
	["newmspcaiwenji"] = "蔡文姬",
	["#newmspcaiwenji"] = "悲惨的才女",
	["guyan"] = "孤雁",
	["guyan_card"] = "孤雁",
	[":guyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色说出一种花色，然后该角色进行一次判定，若判定结果不为其所述之花色，你对该角色造成1点伤害。无论结果如何，该角色获得该判定牌。",
	["hujias"] = "胡笳",
	[":hujias"] = "每当你受到一次伤害后，伤害来源减1点体力上限，失去1点体力，然后回复1点体力并增加1点体力上限。",
	["guihans"] = "归汉",
	["$Guihans"] = "蔡文姬发动技能【归汉】\
并进化成蔡文姬‧进化",
	[":guihans"] = "<b><font color='yellow'>进化技，</font></b>回合结束阶段开始时，若你已受伤，你可以失去所有技能，然后在下个回合开始阶段开始时进化。",
	["newmspcaiwenjijh"] = "蔡文姬‧进化",
	["#newmspcaiwenjijh"] = "悲惨的才女",
	["guyanjh"] = "孤雁‧进化",
	[":guyanjh"] = "每当一名角色受到一次伤害后，你可以弃置一张牌并令伤害来源说出一种花色，然后该角色进行一次判定，若判定结果不为其所述之花色，该角色失去1点体力。",
	["hujiajh"] = "胡笳‧进化",
	[":hujiajh"] = "<font color=\"blue\"><b>锁定技，</b></font>你死亡时，杀死你的角色减与你手牌数等量的体力上限，并失去与其手牌数等量的体力。",
	["newmspgodzhenji"] = "神甄姬",
	["#newmspgodzhenji"] = "洛水之神",
	["huixue"] = "回雪",
	[":huixue"] = "每当你受到一次伤害后，你可以弃置一张基本牌，然后回复1点体力。",
	["@huixue"] = "请弃置一张基本牌",
	["xiehou"] = "邂逅",
	["$Xiehou"] = "神甄姬发动技能【邂逅】\
并进化成神甄姬‧进化",
	[":xiehou"] = "<b><font color='yellow'>进化技，</font></b>每当你受到一次属性伤害后，你可以进化。",
	["newmspgodzhenjijh"] = "神甄姬‧进化",
	["#newmspgodzhenjijh"] = "洛水之神",
	["luoshenjh"] = "洛神‧进化",
	[":luoshenjh"] = "每当你受到一次伤害后，你可以从牌堆顶亮出与你手牌数等量的牌，你获得当中黑色的牌，将其余的牌置入弃牌堆。",
	["biyues"] = "蔽月",
	[":biyues"] = "每当你受到男性角色造成的1点伤害后，你可以将该角色的一张牌置于牌堆顶。",
	["huixuejh"] = "回雪‧进化",
	[":huixuejh"] = "回合开始阶段开始时，若你已受伤，你可以回复1点体力。",
	["meizi_shenfu"] = "神赋",
	["$Shenfu"] = "神甄姬‧进化发动技能【神赋】\
并进化成神甄姬‧二次进化",
	[":meizi_shenfu"] = "<b><font color='yellow'>进化技，</font></b>当你处于濒死状态时，你可以进化。",
	["newmspgodzhenjijhnd"] = "神甄姬‧二次进化",
	["#newmspgodzhenjijhnd"] = "洛水之神",
	["luoshenjhnd"] = "洛神‧二次进化",
	[":luoshenjhnd"] = "每当你受到1点伤害后，你可以从牌堆顶亮出与你手牌数等量的牌，你获得当中黑色的牌，将其余的牌置入弃牌堆。",
	["biyuejh"] = "蔽月‧进化",
	[":biyuejh"] = "每当你受到男性角色造成的1点伤害后，你可以将该角色的一张牌置于牌堆顶，若该牌为黑色，你对该角色造成1点伤害。",
	["huixuejhnd"] = "回雪‧二次进化",
	["recover"] = "回复1点体力",
	[":huixuejhnd"] = "回合开始阶段开始时，你可以回复1点体力或摸两张牌。",
	["shixiang"] = "诗想",
	["@shixiang"] = "诗想",
	["$Shixiang"] = "边地多悲风，树木何翛翛！\
从君致独乐，延年寿千秋。 ",
	[":shixiang"] = "<font color=\"red\"><b>限定技，</b></font>摸牌阶段开始时，你可以放弃摸牌，改为弃置所有手牌，然后摸三倍的牌（最多九张），并跳过此回合的弃牌阶段。",
	["shijun"] = "侍君",
	["shijunvs"] = "侍君",
	["shijuncard"] = "侍君",
	[":shijun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并指定一名其他角色，你与该角色的距离始终视为1，直到回合结束。",
}



return { extension }
------------------------------------------------------------------------------------------------------------------------------
