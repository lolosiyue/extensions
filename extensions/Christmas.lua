module("extensions.Christmas", package.seeall)
extension = sgs.Package("Christmas")

sgs.LoadTranslationTable {
	["Christmas"] = "圣诞快乐",
}


RLiwaCard = sgs.CreateSkillCard{
	name = "RLiwaCard",
	skill_name = "RLiwa",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		targets[1]:addToPile("liwas", self, true)
		room:setPlayerMark(targets[1], "RLiwa"..source:objectName()..self:getSubcards():at(0), 1)
	end,
}

RLiwaVS = sgs.CreateOneCardViewAsSkill{
	name = "RLiwa",
	filter_pattern = ".",
	view_as = function(self, originalCard)
		local skillcard = RLiwaCard:clone()
		skillcard:addSubcard(originalCard)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#RLiwaCard")
	end, 
	--
}

RLiwa = sgs.CreateTriggerSkill{
	name = "RLiwa",
	events = {sgs.EventPhaseStart, sgs.CardFinished},
	view_as_skill = RLiwaVS,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local RLiwa_types = {}
			for _, card in sgs.qlist(player:getPile("liwas")) do
				table.insert(RLiwa_types, sgs.Sanguosha:getCard(card):getTypeId())
				for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("RLiwa"..source:objectName()..card) > 0 then
						room:setPlayerMark(player, "RLiwa"..source:objectName()..card, 0)
						room:setPlayerMark(source, "RLiwa"..sgs.Sanguosha:getCard(card):getTypeId().."-Clear", 1)
					end
				end
			end
			player:setTag("RLiwa", sgs.QVariant(table.concat(RLiwa_types, ",")))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName())
			local move = sgs.CardsMoveStruct(player:getPile("liwas"), player, sgs.Player_PlaceHand, reason)
			room:moveCardsAtomic(move, true)
			
		end
		if event == sgs.CardFinished and player:getPhase() == sgs.Player_Play then
			local RLiwa_types = player:getTag("RLiwa"):toString():split(",")
			local use = data:toCardUse()
			for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if source and table.contains(RLiwa_types, tostring(use.card:getTypeId())) and source:getMark("RLiwa"..use.card:getTypeId().."-Clear") > 0 then
					if room:askForSkillInvoke(source, self:objectName(), data) then
						source:drawCards(1)
					end
				end
			end
		end
		return false
	end,
	
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

ReindeerGirl = sgs.General(extension, "ReindeerGirl", "god", 4, false)
ReindeerGirl:addSkill(RLiwa)

sgs.LoadTranslationTable {
	["ReindeerGirl"] = "驯鹿娘", 
	["&ReindeerGirl"] = "驯鹿娘",
	["#ReindeerGirl"] = "飞奔的礼物",
	["RLiwa"] = "礼袜",
	[":RLiwa"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可将一张牌置于其他角色武将牌旁，称为“袜子”。该角色准备阶段开始时获得此“袜子”。\
当一名角色其于出牌阶段使用与其此回合获得的“袜子”类别相同的牌后，你可摸一张牌。",
	["liwas"] = "袜子",
	["designer:ReindeerGirl"] = "Amira",
	["illustrator:ReindeerGirl"]	= "ピスケ",
}