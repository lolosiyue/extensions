module("extensions.LuaOldEnemyGirls", package.seeall)
extension = sgs.Package("LuaOldEnemyGirls")

sgs.LoadTranslationTable {
	["LuaOldEnemyGirls"] = "宿敌规则专属",
}

-- on_record 逐持有者實例各跑一次（含死亡持有者的實例）。凡需在 record 內做
-- 事件級簿記（計數、旗標消耗等）時，只讓記錄順序中的第一個實例執行，以免
-- 多名持有者或多實例重複生效。此順序與 roomthread 派發迴圈
-- （getAllPlayers(true) × getSkillInstanceIds）一致。
local function isFirstSkillInstance(room, skill_name, ctx)
	if not ctx.owner then return false end
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		for _, id in sgs.qlist(p:getSkillInstanceIds(skill_name)) do
			return p:objectName() == ctx.owner:objectName() and id == ctx.instanceID
		end
	end
	return false
end

LuaFengyu = sgs.CreateTriggerSkillV2 {
	name = "LuaFengyu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging },

	-- 棄牌數累計只由首個實例執行；標記於進入棄牌階段時歸零（record 先於
	-- can_trigger，若在 EventPhaseEnd 清除會令標記在判斷前歸零）。
	on_record = function(self, event, room, player, ctx)
		if event == sgs.CardsMoveOneTime then
			if not player or not player:isAlive()
				or player:getPhase() ~= sgs.Player_Discard
				or player:hasSkill(self:objectName()) then
				return
			end
			if not isFirstSkillInstance(room, self:objectName(), ctx) then return end
			local move = ctx.original_data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return end
			if (move.from_places:contains(sgs.Player_PlaceHand)) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				room:addPlayerMark(player, self:objectName(), move.card_ids:length())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.EventPhaseEnd then return false end
		if not player or not player:isAlive()
			or player:getPhase() ~= sgs.Player_Discard
			or player:hasSkill(self:objectName()) then
			return false
		end
		local skill_names, owner_names = {}, {}
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source and player:getMark(self:objectName()) >= source:getHp() then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, source:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,

	on_cost = function(self, event, room, player, ctx)
		return room:askForSkillInvoke(player, self:objectName())
	end,

	on_effect = function(self, event, room, player, ctx)
		player:drawCards(1)
		return false
	end,
}

LuaFengxiCard = sgs.CreateSkillCard {
	name = "LuaFengxiCard",
	skill_name = "LuaFengxi",

	filter = function(self, targets, to_select, player)
		return #targets == 0 and not to_select:isNude() and getOEList(player):contains(to_select)
	end,

	feasible = function(self, targets, player)
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

-- 保留 LuaFengxiCard 原型：舊 AI 以 Card_Parse("#LuaFengxiCard:.:") 產生並以
-- "#LuaFengxiCard" history 判斷每階段限一次；V2 create_card 直接回傳其 clone，
-- 目標選擇與效果仍由牌本身的 filter/feasible/on_use 處理。
LuaFengxi = sgs.CreateViewAsSkillV2 {
	name = "LuaFengxi",
	n = 0,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		-- V2 發動以技能名 "LuaFengxi" 記錄 history；舊 AI 直用卡牌則記 "#LuaFengxiCard"。
		return not getOEList(player):isEmpty()
			and not player:hasUsed("#LuaFengxiCard")
			and not player:hasUsed(self:objectName())
	end,
	create_card = function(self, request)
		return LuaFengxiCard:clone()
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

LuaLinying = sgs.CreateTriggerSkillV2 {
	name = "LuaLinying",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName())
			and player:getPhase() == sgs.Player_Start
			and player:getMaxHp() - player:getHandcardNum() > 0 then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, ctx)
		return room:askForSkillInvoke(player, self:objectName())
	end,

	on_effect = function(self, event, room, player, ctx)
		local n = player:getMaxHp() - player:getHandcardNum()
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
		return false
	end,
}

LuaLinluCard = sgs.CreateSkillCard {
	name = "LuaLinluCard",
	skill_name = "LuaLinlu",

	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,

	feasible = function(self, targets, player)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		source:loseMark("@LuaLinlu")
		room:damage(sgs.DamageStruct("LuaLinLu", source, targets[1]))
	end,
}

LuaLinluVS = sgs.CreateViewAsSkillV2 {
	name = "LuaLinlu",
	n = 2,
	can_activate = function(self, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@LuaLinlu") > 0
	end,
	can_select_card = function(self, request, candidate)
		if not candidate or candidate:isEquipped() then return false end
		local selected = sgs.QList2Table(request:getSelectedCardIds())
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			local first = sgs.Sanguosha:getCard(selected[1])
			return first ~= nil and candidate:sameColorWith(first)
		end
		return false
	end,
	-- 保留 LuaLinluCard 原型：舊 AI 以 Card_Parse("#LuaLinluCard:...") 產生，
	-- 目標選擇與效果由牌本身的 filter/feasible/on_use 處理。
	create_card = function(self, request)
		local card = LuaLinluCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(self:objectName())
		return card
	end,
}

LuaLinlu = sgs.CreateTriggerSkillV2 {
	name = "LuaLinlu",
	frequency = sgs.Skill_Limited,
	events = { },
	view_as_skill = LuaLinluVS,
	limit_mark = "@LuaLinlu",
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

	feasible = function(self, targets, player)
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

-- 保留 LuaHuoweiCard 原型：舊 AI 在 "@@LuaHuowei" 回應中以 "#LuaHuoweiCard:..." 字串
-- 出牌；V2 create_card 回傳其 clone，效果仍由牌本身的 on_effect 處理。
LuaHuoweiVS = sgs.CreateViewAsSkillV2 {
	name = "LuaHuowei",
	n = 1,
	can_activate = function(self, request)
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		return request:getPattern() == "@@LuaHuowei"
	end,
	can_select_card = function(self, request, candidate)
		return candidate and request:getSelectedCardIds():isEmpty()
			and candidate:isRed() and not candidate:isEquipped()
	end,
	create_card = function(self, request)
		local card = LuaHuoweiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(self:objectName())
		return card
	end,
}

LuaHuowei = sgs.CreateTriggerSkillV2 {
	name = "LuaHuowei",
	view_as_skill = LuaHuoweiVS,
	events = { sgs.DamageCaused, sgs.DamageInflicted },

	-- 舊版於 on_trigger「見旗即清」：旗標由 LuaHuoweiCard 在轉移傷害前設於新目標，
	-- 在下一個符合 can_trigger 條件的持有者事件中壓制發動一次並清除。
	-- V2 record 先於 can_trigger，故以 LuaHuoweiConsumed 做交接：record 見旗即
	-- 轉記為 Consumed（同事件內 can_trigger 仍視為已用過），下一個傷害事件再清。
	on_record = function(self, event, room, player, ctx)
		if event ~= sgs.DamageCaused and event ~= sgs.DamageInflicted then return end
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return
		end
		if not isFirstSkillInstance(room, self:objectName(), ctx) then return end
		local damage = ctx.original_data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Fire then return end
		local to = damage.to
		if not to then return end
		if to:hasFlag("LuaHuoweiTarget") then
			to:setFlags("-LuaHuoweiTarget")
			to:setFlags("LuaHuoweiConsumed")
		elseif to:hasFlag("LuaHuoweiConsumed") then
			to:setFlags("-LuaHuoweiConsumed")
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.DamageCaused and event ~= sgs.DamageInflicted then return false end
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Fire then return false end
		if damage.to and damage.to:hasFlag("LuaHuoweiConsumed") then return false end
		local OEs = getOEList(player, room)
		if OEs:isEmpty() or not player:canDiscard(player, "h") then return false end
		return self:objectName()
	end,

	on_cost = function(self, event, room, player, ctx)
		player:setTag("LuaHuoweiDamage", ctx.original_data)
		local used = room:askForUseCard(player, "@@LuaHuowei", "@LuaHuowei", -1, sgs.Card_MethodDiscard) ~= nil
		ctx.extra_data:setValue(used and 1 or 0)
		return used
	end,

	-- 舊 on_trigger 以 askForUseCard 結果作回傳：成功出牌即中斷其餘觸發。
	on_effect = function(self, event, room, player, ctx)
		return ctx.extra_data:toInt() ~= 0
	end,
}

LuaYinyan = sgs.CreateTriggerSkillV2 {
	name = "LuaYinyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardResponded },

	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or player:hasSkill(self:objectName()) then
			return false
		end
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			card = response.m_card
		end
		if not card or not card:isRed() or not card:isKindOf("BasicCard") then return false end
		local skill_names, owner_names = {}, {}
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source and source:getPhase() == sgs.Player_Play and source:canPindian(player) then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, source:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,

	-- player 為技能持有者（ctx.owner）；事件發起人（用牌者）為 ctx.invoker。
	on_cost = function(self, event, room, player, ctx)
		local target_data = sgs.QVariant()
		target_data:setValue(ctx.invoker)
		return room:askForSkillInvoke(player, self:objectName(), target_data)
	end,

	on_effect = function(self, event, room, player, ctx)
		local target = ctx.invoker
		if target and player:pindian(target, self:objectName(), nil) then
			room:damage(sgs.DamageStruct(self:objectName(), player, target, 1,
				sgs.DamageStruct_Fire))
		end
		return false
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


LuaYanling = sgs.CreateTriggerSkillV2 {
	name = "LuaYanling",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecifying },

	-- 舊版無 can_trigger，採預設（存活且擁有技能）。此處補上 Slash 與宿敵目標的
	-- 純查詢條件，避免無合適宿敵時仍彈出發動詢問。
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		local use = data:toCardUse()
		if not use.card or not use.card:isKindOf("Slash") then return false end
		local targets = getOEList(player, room)
		for _, p in sgs.qlist(targets) do
			if use.to:contains(p) or sgs.Sanguosha:isProhibited(player, p, use.card) then
				targets:removeOne(p)
			end
		end
		if targets:isEmpty() then return false end
		return self:objectName()
	end,

	on_cost = function(self, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local targets = getOEList(player, room)
		for _, p in sgs.qlist(targets) do
			if use.to:contains(p) or sgs.Sanguosha:isProhibited(player, p, use.card) then
				targets:removeOne(p)
			end
		end
		if targets:isEmpty() then return false end
		local OE = room:askForPlayerChosen(player, targets, self:objectName(), "@LuaYanling-invoke", true,
			true)
		if not OE then return false end
		ctx.extra_data:setValue(OE)
		return true
	end,

	on_effect = function(self, event, room, player, ctx)
		local OE = ctx.extra_data:toPlayer()
		local use = ctx.original_data:toCardUse()
		if OE and use.card then
			use.to:append(OE)
			ctx.original_data:setValue(use)
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

	feasible = function(self, targets, player)
		return #targets == 2
	end,

	on_use = function(self, room, source, targets)
		relieveOE(room, targets[1])
		return false
	end,
}

-- 保留 LuaDuanjianCard 原型：舊 AI 以 Card_Parse("#LuaDuanjianCard:<id>:") 產生；
-- V2 create_card 回傳其 clone，兩段宿敵目標選擇與效果由牌本身處理。
LuaDuanjian = sgs.CreateViewAsSkillV2 {
	name = "LuaDuanjian",
	n = 1,
	can_activate = function(self, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(self, request, candidate)
		return candidate and request:getSelectedCardIds():isEmpty()
			and candidate:isKindOf("Weapon")
	end,
	create_card = function(self, request)
		local card = LuaDuanjianCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		card:setSkillName(self:objectName())
		return card
	end,
}

LuaLianzhanTest = sgs.CreateTriggerSkillV2 {
	name = "LuaLianzhanTest",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },

	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() then return false end
		local effect = data:toCardEffect()
		if not effect.card or not table.contains(effect.card:getSkillNames(), "establishOECard") then
			return false
		end
		local skill_names, owner_names = {}, {}
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source and source:getPhase() == sgs.Player_NotActive then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, source:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,

	-- player 為技能持有者（ctx.owner），與舊版逐 source 處理一致。
	on_effect = function(self, event, room, player, ctx)
		room:notifySkillInvoked(player, self:objectName())
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		player:drawCards(1)
		return false
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
