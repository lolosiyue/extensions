module("extensions.LuaOldEnemyGirls", package.seeall)
extension = sgs.Package("LuaOldEnemyGirls")

sgs.LoadTranslationTable {
	["LuaOldEnemyGirls"] = "宿敌规则专属",
}

LuaFengyu = sgs.CreateTriggerSkill {
	name = "LuaFengyu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.from_places:contains(sgs.Player_PlaceHand)) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				room:addPlayerMark(player, self:objectName(), move.card_ids:length())
			end
		end
		if event == sgs.EventPhaseEnd then
			for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if source and player:getMark(self:objectName()) >= source:getHp() then
					if room:askForSkillInvoke(source, self:objectName()) then source:drawCards(1) end
				end
			end
			room:setPlayerMark(player, self:objectName(), 0)
		end
	end,

	can_trigger = function(self, target)
		return target:isAlive() and target:getPhase() == sgs.Player_Discard and not target:hasSkill(self:objectName())
	end,
}

LuaFengxiCard = sgs.CreateSkillCard {
	name = "LuaFengxiCard",
	skill_name = "LuaFengxi",

	filter = function(self, targets, to_select, player)
		return #targets == 0 and not to_select:isNude() and getOEList(player):contains(to_select)
	end,

	feasible = function(self, targets)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		local target = targets[1]
		local card = room:askForExchange(target, "LuaFengxi", 1, 1, true, "@LuaFengxi_ChoiceCard:" ..
			source:objectName(), false)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceEquip then
			room:throwCard(card, targets[1])
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(),
				source:objectName(), "LuaFengxi", "")
			room:moveCardTo(card, source, sgs.Player_PlaceHand, reason, false)
		end
	end,
}

LuaFengxi = sgs.CreateZeroCardViewAsSkill {
	name = "LuaFengxi",
	view_as = function(self)
		return LuaFengxiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not getOEList(player):isEmpty() and not player:hasUsed("#LuaFengxiCard")
	end,
}

WindGirl = sgs.General(extension, "WindGirl", "qun", 3, false)
WindGirl:addSkill(LuaFengyu)
WindGirl:addSkill(LuaFengxi)

sgs.LoadTranslationTable {
	["WindGirl"] = "风",
	["#WindGirl"] = "摇曳的哀伤",
	["&WindGirl"] = "风",
	["LuaFengyu"] = "风语",
	[":LuaFengyu"] = "其他角色弃牌阶段结束时，若其于此阶段内弃置的手牌数不小于你当前体力值，你可摸一张牌。",
	["LuaFengxi"] = "风袭",
	[":LuaFengxi"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可令你的宿敌角色之一弃置其装备区的一张牌或交给你一张手牌。",
	["@LuaFengxi_ChoiceCard"] = "弃置装备区的一张牌或交给<font color=\"yellow\"><b>%src</b></font>一张手牌",
	["designer:WindGirl"] = "Amira",
	["illustrator:WindGirl"] = "monono",
}

LuaLinying = sgs.CreateTriggerSkill {
	name = "LuaLinying",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local n = player:getMaxHp() - player:getHandcardNum()
		if player:getPhase() == sgs.Player_Start and n > 0 and room:askForSkillInvoke(player, self:objectName()) then
			player:drawCards(n)
			-- player:setPhase(sgs.Player_NotActive)
			-- room:broadcastProperty(player, "phase")
			local OEs = getOEList(player, room)
			if OEs:isEmpty() then return false end
			local myoe = room:askForPlayerChosen(player, OEs, self:objectName(), "@LuaLinying-invoke", true, true)
			if myoe then
				myoe:drawCards(1)
				myoe:turnOver()
			end
			room:throwEvent(sgs.TurnBroken)
		end
		return false
	end,

	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName())
	end,
}

LuaLinluCard = sgs.CreateSkillCard {
	name = "LuaLinluCard",
	skill_name = "LuaLinlu",

	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,

	feasible = function(self, targets)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		source:loseMark("@LuaLinlu")
		room:damage(sgs.DamageStruct("LuaLinLu", source, targets[1]))
	end,
}

LuaLinluVS = sgs.CreateViewAsSkill {
	name = "LuaLinlu",
	n = 2,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			return to_select:sameColorWith(selected[1])
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local SCard = LuaLinluCard:clone()
			for _, card in pairs(cards) do SCard:addSubcard(card) end
			SCard:setSkillName(self:objectName())
			return SCard
		end
	end,

	enabled_at_play = function(self, player)
		return player:getMark("@LuaLinlu") > 0
	end,
}

LuaLinlu = sgs.CreateTriggerSkill {
	name = "LuaLinlu",
	frequency = sgs.Skill_Limited,
	events = { },
	view_as_skill = LuaLinluVS,
	limit_mark = "@LuaLinlu",
	on_trigger = function(self, event, player, data)
	end
}

ThicketGirl = sgs.General(extension, "ThicketGirl", "wu", 4, false)
ThicketGirl:addSkill(LuaLinying)
ThicketGirl:addSkill(LuaLinlu)

sgs.LoadTranslationTable {
	["ThicketGirl"] = "林",
	["#ThicketGirl"] = "难抑的生机",
	["&ThicketGirl"] = "林",
	["LuaLinying"] = "林影",
	[":LuaLinying"] = "准备阶段开始时，你可将手牌补至体力上限并结束当前回合。若如此做，你可令你的一名宿敌角色摸一张牌并翻面。",
	["@LuaLinying-invoke"] = "你可以令你的一名<font color=\"yellow\">宿敌角色</font>翻面",
	["LuaLinlu"] = "林麓",
	["@LuaLinlu"] = "林麓",
	[":LuaLinlu"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可弃置两张相同颜色的手牌对一名角色造成一点伤害。",
	["designer:ThicketGirl"] = "Amira",
	["illustrator:ThicketGirl"] = "lack",
}

LuaHuoweiCard = sgs.CreateSkillCard {
	name = "LuaHuoweiCard",

	filter = function(self, selected, to_select, player)
		return #selected == 0 and getOEList(player):contains(to_select)
	end,

	feasible = function(self, targets)
		return #targets == 1
	end,

	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local damage = effect.from:getTag("LuaHuoweiDamage"):toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			effect.from:removeQinggangTag(damage.card)
		end
		effect.to:setFlags("LuaHuoweiTarget")
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage)
	end
}

LuaHuoweiVS = sgs.CreateOneCardViewAsSkill {
	name = "LuaHuowei",
	response_pattern = "@@LuaHuowei",
	filter_pattern = ".|red|.|hand",

	view_as = function(self, card)
		local Card = LuaHuoweiCard:clone()
		Card:addSubcard(card)
		return Card
	end,

	enabled_at_play = function(self, player)
		return false
	end,
}

LuaHuowei = sgs.CreateTriggerSkill {
	name = "LuaHuowei",
	view_as_skill = LuaHuoweiVS,
	events = { sgs.DamageCaused, sgs.DamageInflicted },

	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Fire then return false end
		local room = player:getRoom()
		if damage.to:hasFlag("LuaHuoweiTarget") then
			damage.to:setFlags("-LuaHuoweiTarget")
			return false
		end
		local OEs = getOEList(player, room)
		if OEs:isEmpty() or not player:canDiscard(player, "h") then return false end
		player:setTag("LuaHuoweiDamage", data)
		return room:askForUseCard(player, "@@LuaHuowei", "@LuaHuowei", -1, sgs.Card_MethodDiscard)
	end,

	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName())
	end,
}

LuaYinyan = sgs.CreateTriggerSkill {
	name = "LuaYinyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardResponded },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = data:toCardUse().card
		end
		if event == sgs.CardResponded then
			local response = data:toCardResponse()
			card = response.m_card
		end

		if card and card:isRed() and card:isKindOf("BasicCard") then
			for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if source:getPhase() == sgs.Player_Play and source:canPindian(player) then
					local target_data = sgs.QVariant()
					target_data:setValue(player)
					if room:askForSkillInvoke(source, self:objectName(), target_data) then
						local success = source:pindian(player, self:objectName(), nil)
						if success then
							room:damage(sgs.DamageStruct(self:objectName(), source, player, 1,
								sgs.DamageStruct_Fire))
						end
					end
				end
			end
		end
		return false
	end,

	can_trigger = function(self, target)
		return target:isAlive() and not target:hasSkill(self:objectName())
	end,
}

FireGirl = sgs.General(extension, "FireGirl", "shu", 3, false)
FireGirl:addSkill(LuaHuowei)
FireGirl:addSkill(LuaYinyan)

sgs.LoadTranslationTable {
	["FireGirl"] = "火",
	["#FireGirl"] = "炽热的爱意",
	["&FireGirl"] = "火",
	["LuaHuowei"] = "火延",
	["luahuowei"] = "火延",
	[":LuaHuowei"] = "每当你造成或受到火属性伤害时，你可弃置一张红色手牌将此伤害转移给你的宿敌角色之一。",
	["@LuaHuowei"] = "你可以发动技能<font color=\"yellow\"><b>火延</b></font>将此伤害转移给一名宿敌角色",
	["~LuaHuowei"] = "选择一张红色手牌并指定一名宿敌角色",
	["LuaYinyan"] = "引炎",
	[":LuaYinyan"] = "每当其他角色于你的出牌阶段使用或打出红色基本牌时，你可与其拼点，若其没赢，你对其造成1点火属性伤害。",
	["designer:FireGirl"] = "Amira",
	["illustrator:FireGirl"] = "lack",
}


LuaYanling = sgs.CreateTriggerSkill {
	name = "LuaYanling",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecifying },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				local targets = getOEList(player, room)
				for _, p in sgs.qlist(targets) do
					if use.to:contains(p) or sgs.Sanguosha:isProhibited(player, p, use.card) then
						targets:removeOne(p)
					end
				end
				if targets:isEmpty() then return false end
				local OE = room:askForPlayerChosen(player, targets, self:objectName(), "@LuaYanling-invoke", true,
					true)
				if OE then use.to:append(OE) end
				data:setValue(use)
			end
		end
		return false
	end,
}

LuaShandie = sgs.CreateProhibitSkill {
	name = "LuaShandie",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and findMyOE(to) and not getOEList(to):contains(from) and
			(card:isKindOf("Slash") or card:isKindOf("DelayedTrickCard"))
	end
}

MountainGirl = sgs.General(extension, "MountainGirl", "wei", 3, false)
MountainGirl:addSkill(LuaYanling)
MountainGirl:addSkill(LuaShandie)

sgs.LoadTranslationTable {
	["MountainGirl"] = "山",
	["#MountainGirl"] = "堆积的温柔",
	["&MountainGirl"] = "山",
	["LuaYanling"] = "岩灵",
	[":LuaYanling"] = "每当你使用【杀】指定一名角色为目标时，你可令你的一名宿敌角色成为此杀的额外目标。",
	["@LuaYanling-invoke"] = "你可以令你的一名<font color=\"yellow\">宿敌角色</font>成为此 杀 额外目标",
	["LuaShandie"] = "山叠",
	[":LuaShandie"] = "<font color=\"blue\"><b>锁定技</b></font>，当你存在宿敌关系时，非你宿敌的角色使用【杀】和延时类锦囊不能指定你为目标。",
	["designer:MountainGirl"] = "Amira",
	["illustrator:MountainGirl"] = "Tobi",
}


LuaDuanjianCard = sgs.CreateSkillCard {
	name = "LuaDuanjianCard",
	skill_name = "LuaDuanjian",
	will_throw = true,

	filter = function(self, targets, to_select, player)
		if #targets == 0 then return findMyOE(to_select) end
		if #targets == 1 then return to_select:objectName() == findMyOE(targets[1]):objectName() end
	end,

	feasible = function(self, targets)
		return #targets == 2
	end,

	on_use = function(self, room, source, targets)
		relieveOE(room, targets[1])
		return false
	end,
}

LuaDuanjian = sgs.CreateOneCardViewAsSkill {
	name = "LuaDuanjian",
	filter_pattern = "Weapon",
	view_as = function(self, card)
		local scard = LuaDuanjianCard:clone()
		scard:setSkillName(self:objectName())
		scard:addSubcard(card)
		return scard
	end,

	enabled_at_play = function(self, player)
		return true
	end,
}

LuaLianzhanTest = sgs.CreateTriggerSkill {
	name = "LuaLianzhanTest",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source and source:getPhase() == sgs.Player_NotActive then
				if effect.card and table.contains(effect.card:getSkillNames(), "establishOECard") then
					room:notifySkillInvoked(source, self:objectName())
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = source
					log.arg = self:objectName()
					room:sendLog(log)
					source:drawCards(1)
				end
			end
		end
		return false
	end,

	can_trigger = function(self, target)
		return target:isAlive()
	end,
}

SwordGirl = sgs.General(extension, "SwordGirl", "qun", 3, false)
SwordGirl:addSkill(LuaDuanjian)
SwordGirl:addSkill(LuaLianzhanTest)

sgs.LoadTranslationTable {
	["SwordGirl"] = "剑士妹子",
	["#SwordGirl"] = "战场武神",
	["&SwordGirl"] = "女剑士",
	["LuaDuanjianTest"] = "断剑",
	["LuaDuanjian"] = "断剑",
	[":LuaDuanjian"] = "出牌阶段，你可弃置一张武器牌令两名存在对应宿敌关系的角色解除此关系。",
	["LuaLianzhanTest"] = "恋战",
	[":LuaLianzhanTest"] = "<font color=\"blue\"><b>锁定技 </b></font>，回合外每当一名角色建立宿敌关系时，你摸一张牌。",
	["designer:SwordGirl"] = "Amira",
	["illustrator:SwordGirl"] = "opiu",
}
return { extension }
