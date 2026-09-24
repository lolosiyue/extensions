extension = sgs.Package("Dan", sgs.Package_GeneralPack)
local tr = sgs.LoadTranslationTable
local isHegemony = sgs.Sanguosha:getVersionName() == "Heg"
if isHegemony then
	local kingdomtab = table.Shuffle { "wei", "shu", "wu", "qun" }
	dan_gen = sgs.General(extension, "dan_amira", kingdomtab[math.random(1, 4)], 2)
else
	dan_gen = sgs.General(extension, "dan_amira", "god", 2, false)
end

tr {
	["Dan"] = "年",

	["dan_amira"] = "新年娘",
	["#dan_amira"] = "新年快乐",

	["designer:dan_amira"] = "Amira",
	["illustrator:dan_amira"] = "",
}

LuaJiangfu = sgs.CreateTriggerSkillV2 {
	name = "LuaJiangfu",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if player:getPhase() ~= sgs.Player_NotActive then
			return false
		end
		local num_tab = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			local c = sgs.Sanguosha:getCard(id)
			if table.contains(num_tab, c:getNumber()) then
				return skill:objectName()
			end
			table.insert(num_tab, c:getNumber())
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getLostHp() > 0 then
				targets:append(p)
			end
		end
		local pl = room:askForPlayerChosen(player, targets, skill:objectName(), skill:objectName() .. "_Invoke", true, true)
		if pl then
			ctx.targets:append(pl)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:recover(target, sgs.RecoverStruct(player))
		return false
	end,
}

dan_gen:addSkill(LuaJiangfu)

tr {
	["LuaJiangfu"] = "降福",
	[":LuaJiangfu"] = "每当你于回合外受到伤害后，若牌堆里还有点数相同的牌，你可令一名角色回复一点体力",
	["LuaJiangfu_Invoke"] = "请选择一名受伤的角色来发动技能 降福 ~",
}

LuaYanjiuVS = sgs.CreateViewAsSkillV2 {
	name = "LuaYanjiu",
	n = 1,
	response_or_use = true,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Analeptic_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern(), "analeptic") ~= nil
		end
		return false
	end,

	can_select_card = function(skill, request, card)
		if not card or not request:getSelectedCardIds():isEmpty() then
			return false
		end
		local player = request:getInitiator()
		if not player then
			return false
		end
		local suits = player:property(skill:objectName()):toString():split("+")
		return table.contains(suits, card:getSuitString())
	end,

	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local player = request:getInitiator()
		if ids:length() ~= 1 or not player then
			return nil
		end
		local material = sgs.Sanguosha:getCard(ids:first())
		if not material then
			return nil
		end
		local suits = player:property(skill:objectName()):toString():split("+")
		if not table.contains(suits, material:getSuitString()) then
			return nil
		end
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if not analeptic then
			return nil
		end
		analeptic:addSubcard(material)
		analeptic:setSkillName(skill:objectName())
		if isHegemony then
			analeptic:setShowSkill(skill:objectName())
		end
		return analeptic
	end,
}

LuaYanjiu = sgs.CreateTriggerSkillV2 {
	name = "LuaYanjiu",
	events = { sgs.CardsMoveOneTime },
	view_as_skill = LuaYanjiuVS,

	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:isAlive() and owner:hasSkill(skill:objectName())) then
			return
		end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_DrawPile) or move.to_place == sgs.Player_DrawPile then
			local hash = {}
			for _, id in sgs.qlist(room:getDrawPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if hash[c:getSuitString()] then
					hash[c:getSuitString()] = hash[c:getSuitString()] + 1
				else
					hash[c:getSuitString()] = 1
				end
			end
			local max = 0
			for _, v in pairs(hash) do
				if v > max then
					max = v
				end
			end
			local big_suit = {}
			for s, v in pairs(hash) do
				if v == max then
					table.insert(big_suit, s)
				end
			end
			room:setPlayerProperty(owner, skill:objectName(), sgs.QVariant(table.concat(big_suit, "+")))
		end
	end,
}

dan_gen:addSkill(LuaYanjiu)

tr {
	["LuaYanjiu"] = "言酒",
	[":LuaYanjiu"] = "你可将一张花色为O的牌当【酒】使用或打出（O为牌堆剩余最多的花色数之一）",
}

return extension
