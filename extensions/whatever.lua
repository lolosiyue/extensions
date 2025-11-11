extension = sgs.Package("whatever", sgs.Package_GeneralPack)
sgs.LoadTranslationTable{
	["whatever"] = "随意包",
	
}

function sendComLog(player, name, only_notify, n)
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

function changeTranslation(player, skillName, toChange)
	local room = player:getRoom()
	sgs.Sanguosha:addTranslationEntry(":" .. skillName, toChange)
	room:detachSkillFromPlayer(player, skillName, true)
	player:addSkill(skillName)
	room:attachSkillToPlayer(player, skillName)
	local changed_skills = room:getTag("changed_skills"):toString():split("+")
	if not table.contains(changed_skills, skillName) then
		table.insert(changed_skills, skillName)
		ChoiceLog(player, table.concat(changed_skills, "+"))
		room:setTag("changed_skills", sgs.QVariant(table.concat(changed_skills, "+")))
	end
end

function TrueName(card)
	if card == nil then return "" end
	if (card:objectName() == "fire_slash" or card:objectName() == "thunder_slash") then return "slash" end
	return card:objectName()
end

function playerListIndexOf(playerList, theItem)
	local index = 1
	for _, p in sgs.qlist(playerList) do
		if p:objectName() == theItem:objectName() then return index end
		index = index + 1
	end
	return -1
end

function Table2SPList(t)
	local qlist = sgs.SPlayerList()
	for _, p in ipairs(t) do
		qlist:append(p)
	end
	return qlist
end

resume_translation = sgs.CreateTriggerSkill{
	name = "resume_translation",
	global = true,
	events = {sgs.BeforeGameOverJudge},
	priority = -1,
	on_trigger = function(self, event, splayer, data, room)
		local changed_skills = room:getTag("changed_skills"):toString()
		if changed_skills == "" then return false end
		for _, skill in pairs(changed_skills:split("+")) do
			sgs.Sanguosha:addTranslationEntry(":" .. skill, sgs.Sanguosha:translate(skill .. "_copy"))
		end
		room:removeTag("changed_skills")
		return false
	end
}

CalSavageAssaultDMG = sgs.CreateTriggerSkill{
	name = "cal_savage_assault_DMG",
	global = true,
	events = {sgs.DamageDone, sgs.CardFinished},
	priority = -1,
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.DamageDone then
			local card = data:toDamage().card
			if card and card:isKindOf("SavageAssault") then
				local n = room:getTag("SavageAssaultDMG" .. card:getEffectiveId()):toInt()
				n = n + 1
				room:setTag("SavageAssaultDMG" .. card:getEffectiveId(), sgs.QVariant(n))
			end
		else
			local card = data:toCardUse().card
			if card and card:isKindOf("SavageAssault") then
				room:removeTag("SavageAssaultDMG" .. card:getEffectiveId())
			end
		end
		return false
	end
}

MansiCount = sgs.CreateTriggerSkill{
	name = "mansi_count",
	global = true,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, splayer, data, room)
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == splayer:objectName() and move.reason.m_skillName == "mansi" and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW then
			local n = move.card_ids:length()
			room:addPlayerMark(splayer, "@mansi_draw_num", n)
		end
		return false
	end
}

XiliBuff = sgs.CreateTriggerSkill{
	name = "xili_buff",
	global = true,
	events = {sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				local n = card:getTag("xiliBuff"):toInt()
				if not (card:isKindOf("Slash") and n > 0) then return false end
				card:removeTag("xiliBuff")
				local log = sgs.LogMessage()
				log.type = "$CardBuff"
				log.card_str = card:toString()
				log.arg = "xili"
				log.arg2 = n
				room:sendLog(log)
				damage.damage = damage.damage + n
				data:setValue(damage)
			end
		else
			local card = data:toCardUse().card
			if card:isKindOf("Slash") and card:getTag("xiliBuff"):toInt() > 0 then
				card:removeTag("xiliBuff")
			end
		end
		return false
	end
}
sgs.LoadTranslationTable{
	["$CardBuff"] = "%card 因“%arg”的效果增加了 %arg2 点伤害",
	
}


HandleXujing = sgs.CreateTriggerSkill{
	name = "handle_xujing",
	global = true,
	events = {sgs.EventPhaseChanging, sgs.CardFinished},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive and splayer:getMark("shijian_skill") > 0 then
				room:detachSkillFromPlayer(splayer, "yuxu")
				room:setPlayerMark("shijian_skill", 0)
			end
		else
			local card = data:toCardUse().card
			if card:getTag("second_use"):toBool() then
				card:removeTag("second_use")
			end
		end
		return false
	end
}

CardUsedRecorder = sgs.CreateTriggerSkill{
	name = "card_used_recorder",
	global = true,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local card
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			end
		end
		if card and not card:isKindOf("SkillCard") then
			if splayer:getPhase() == sgs.Player_Play then
				room:addPlayerMark(splayer, "card_used_play")
				if splayer:getMark("card_used_play") == 2 then
					card:setTag("second_use", sgs.QVariant(true))
				end
			end
		end
		return false
	end
}

whateverMCS = sgs.CreateMaxCardsSkill{
	name = "whateverMCS",
	extra_func = function(self, target)
		local n = 0
		if target:hasFlag("m_qianxin_debuff") then
			n = n - 2
		end
		return n
	end
}

StartRemover = sgs.CreateTriggerSkill{
	name = "start_remover",
	global = true,
	events = {sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getPhase() == sgs.Player_Start then
			for _, mark in sgs.list(splayer:getMarkNames()) do
				if string.endsWith(mark, "-Start") and splayer:getMark(mark) > 0 then
					room:setPlayerMark(splayer, mark, 0)
				end
			end
		end
		return false
	end
}

WhateverTMDS = sgs.CreateTargetModSkill{
	name = "WhateverTMDS",
	pattern = ".",
	residue_func = function(self, from, card, to)
		local n = 0
		if to and to:property("beyond_xianzhen"):toString() == from:objectName() then
			n = n + 1000
		end
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		local n = 0
		if to and to:property("beyond_xianzhen"):toString() == from:objectName() then
			n = n + 1000
		end
		return n
	end
}



ZhongzuoRecorder = sgs.CreateTriggerSkill{
	name = "zhongzuo_recorder",
	global = true,
	events = {sgs.DamageDone},
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getMark("damaged_round-Clear") == 0 then
			room:setPlayerMark(splayer, "damaged_round-Clear", 1)
		end
		local source = data:toDamage().from
		if source and source:isAlive() and source:getMark("damage_round-Clear") == 0 then
			room:setPlayerMark(source, "damage_round-Clear", 1)
		end
		return false
	end
}

ZhiyiCount = sgs.CreateTriggerSkill{
	name = "zhiyi-count",
	global = true,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local card
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("BasicCard") then
			room:addPlayerMark(splayer, "zhiyiCount-Clear")
		end
		return false
	end
}

AnalepticDamage = sgs.CreateTriggerSkill{
	name = "analeptic-damage",
	global = true,
	events = {sgs.ConfirmDamage, sgs.DamageComplete},
	on_trigger = function(self, event, splayer, data, room)
		local card = data:toDamage().card
		if not (card and card:isKindOf("Slash")) then return false end
		if event == sgs.ConfirmDamage then
			local n = data:toDamage().to:getMark("SlashIsDrank")
			if n > 0 then
				card:setTag(self:objectName(), sgs.QVariant(n))
			end
		else
			if card:getTag(self:objectName()):toInt() > 0 then
				card:removeTag(self:objectName())
			end
		end
		return false
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("resume_translation") then skills:append(resume_translation) end
if not sgs.Sanguosha:getSkill("cal_savage_assault_DMG") then skills:append(CalSavageAssaultDMG) end
--if not sgs.Sanguosha:getSkill("mansi_count") then skills:append(MansiCount) end
if not sgs.Sanguosha:getSkill("xili_buff") then skills:append(XiliBuff) end

if not sgs.Sanguosha:getSkill("handle_xujing") then skills:append(HandleXujing) end
if not sgs.Sanguosha:getSkill("card_used_recorder") then skills:append(CardUsedRecorder) end
if not sgs.Sanguosha:getSkill("whateverMCS") then skills:append(whateverMCS) end
if not sgs.Sanguosha:getSkill("start_remover") then skills:append(StartRemover) end
if not sgs.Sanguosha:getSkill("WhateverTMDS") then skills:append(WhateverTMDS) end
if not sgs.Sanguosha:getSkill("zhongzuo_recorder") then skills:append(ZhongzuoRecorder) end
if not sgs.Sanguosha:getSkill("zhiyi-count") then skills:append(ZhiyiCount) end
if not sgs.Sanguosha:getSkill("analeptic-damage") then skills:append(AnalepticDamage) end

-- zhangwen = sgs.General(extension, "zhangwen", "wu", "3")
-- sgs.LoadTranslationTable{
	-- ["zhangwen"] = "张温",
	-- ["#zhangwen"] = "冲天孤鹭",
	-- ["~zhangwen"] = "",
	
-- }

-- songshuCard = sgs.CreateSkillCard{
	-- name = "songshu",
	-- handling_method = sgs.Card_MethodPindian,
	-- filter = function(self, targets, to_select)
		-- return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select, self:objectName())
	-- end,
	-- on_use = function(self, room, source, targets)
		-- if source:pindian(targets[1], self:objectName(), nil) then
			-- room:addPlayerHistory(source, "#songshu", -1)
		-- else
			-- room:doAnimate(1, source:objectName(), targets[1]:objectName())
			-- targets[1]:drawCards(2, self:objectName())
		-- end
	-- end
-- }
-- songshu = sgs.CreateZeroCardViewAsSkill{
	-- name = "songshu",
	-- view_as = function()
		-- return songshuCard:clone()
	-- end,
	-- enabled_at_play = function(self, player)
		-- return not (player:hasUsed("#songshu") or player:isKongcheng())
	-- end
-- }
-- zhangwen:addSkill(songshu)
-- sgs.LoadTranslationTable{
	-- ["songshu"] = "颂蜀",
	-- [":songshu"] = "出牌阶段限一次，你可以与其他角色拼点，若你：没赢，则其摸两张牌；赢，视为此技能于本回合内未发动过。",
	-- ["$songshu1"] = "",
	-- ["$songshu2"] = "",
	
-- }

-- sibian = sgs.CreateTriggerSkill{
	-- name = "sibian",
	-- events = {sgs.EventPhaseStart},
	-- on_trigger = function(self, event, player, data, room)
		-- if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName(), data) then
			-- room:broadcastSkillInvoke(self:objectName())
			-- local ids = room:getNCards(4)
			-- local to_get, to_give = sgs.IntList(), sgs.IntList()
			-- local max_num, min_num = 0, 999
			-- for _, id in sgs.qlist(ids) do
				-- local number = sgs.Sanguosha:getCard(id):getNumber()
				-- if number > max_num then max_num = number end
				-- if number < min_num then min_num = number end
			-- end
			-- for _, id in sgs.qlist(ids) do
				-- local number = sgs.Sanguosha:getCard(id):getNumber()
				-- if number == max_num or number == min_num then to_get:append(id)
				-- else to_give:append(id) end
			-- end
			-- room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
				-- sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")), true)
			-- room:getThread():delay()
			-- local getDummy = sgs.Sanguosha:cloneCard("slash")
			-- getDummy:addSubcards(to_get)
			-- room:obtainCard(player, getDummy)
			-- getDummy:deleteLater()
			-- if to_get:length() == 2 and max_num - min_num < room:alivePlayerCount() then
				-- local min_handNum = 999
				-- for _, p in sgs.qlist(room:getAlivePlayers()) do
					-- if p:getHandcardNum() < min_handNum then min_handNum = p:getHandcardNum() end
				-- end
				-- local targets = sgs.SPlayerList()
				-- for _, p in sgs.qlist(room:getAlivePlayers()) do
					-- if p:getHandcardNum() == min_handNum then targets:append(p) end
				-- end
				-- local to = room:askForPlayerChosen(player, targets, self:objectName(), "@sibian-give", true)
				-- if to then
					-- room:doAnimate(1, player:objectName(), to:objectName())
					-- local giveDummy = sgs.Sanguosha:cloneCard("slash")
					-- giveDummy:addSubcards(to_give)
					-- room:obtainCard(to, giveDummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), to:objectName(), self:objectName(), ""))
					-- giveDummy:deleteLater()
					-- to_give = sgs.IntList()
				-- end
			-- end
			-- if not to_give:isEmpty() then
				-- local giveDummy = sgs.Sanguosha:cloneCard("slash")
				-- giveDummy:addSubcards(to_give)
				-- local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
				-- room:throwCard(giveDummy, reason, nil)
				-- giveDummy:deleteLater()
			-- end
			-- return true
		-- end
		-- return false
	-- end
-- }
-- zhangwen:addSkill(sibian)
-- sgs.LoadTranslationTable{
	-- ["sibian"] = "思辨",
	-- [":sibian"] = "摸牌阶段，你可以改为亮出牌堆顶四张牌，然后获得其中所有点数最大和最小的牌，若你以此法获得的牌数为2且它们点数之差小于存活角色数，你可将剩余的牌交给手牌数最少的一名角色。",
	-- ["$sibian1"] = "",
	-- ["$sibian2"] = "",
	-- ["@sibian-give"] = "思辨：你可以将剩余的牌交给手牌数最少的一名角色",
	
-- }





mobile_weiwenzhugezhi = sgs.General(extension, "mobile_weiwenzhugezhi", "wu", 4)
sgs.LoadTranslationTable{
	["mobile_weiwenzhugezhi"] = "手杀-卫温&诸葛直",
	["&mobile_weiwenzhugezhi"] = "卫温诸葛直",
	["#mobile_weiwenzhugezhi"] = "夷洲使节",
	["~mobile_weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
	
}

mobile_fuhaiCard = sgs.CreateSkillCard{
	name = "mobile_fuhai",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local players = room:getOtherPlayers(source)
		room:sortByActionOrder(players)
		local choiceList = {}
		for _, p in sgs.qlist(players) do
			room:doAnimate(1, source:objectName(), p:objectName())
			local choice = room:askForChoice(p, self:objectName(), "fuhai_flow+fuhai_ebb")
			table.insert(choiceList, choice)
		end
		for _, p in sgs.qlist(players) do
			ChoiceLog(p, choiceList[playerListIndexOf(players, p)])
		end
		local i = 1
		while i < #choiceList do
			if choiceList[i] ~= choiceList[i + 1] then break end
			i = i + 1
		end
		if i > 1 then
			source:drawCards(i, self:objectName())
		end
	end
}
mobile_fuhai = sgs.CreateOneCardViewAsSkill{
	name = "mobile_fuhai",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = mobile_fuhaiCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_fuhai") and player:canDiscard(player, "he")
	end
}
mobile_weiwenzhugezhi:addSkill(mobile_fuhai)
sgs.LoadTranslationTable{
	["mobile_fuhai"] = "浮海",
	[":mobile_fuhai"] = "出牌阶段限一次，你可以弃置一张牌，令所有其他角色同时选择“潮起”或“潮落”，然后若X大于1，你摸X张牌（X为自你下家开始与其所选结果连续相同的角色数）。",
	["$mobile_fuhai1"] = "宦海沉浮，生死难料！",
	["$mobile_fuhai2"] = "跨海南征，波涛起伏！",
	["fuhai_flow"] = "潮起",
	["fuhai_ebb"] = "潮落",
	
}

mobile_zhanggong = sgs.General(extension, "mobile_zhanggong", "wei", 3)
sgs.LoadTranslationTable{
	["mobile_zhanggong"] = "手杀-张恭",
	["&mobile_zhanggong"] = "张恭",
	["#mobile_zhanggong"] = "西域长歌",
	["~mobile_zhanggong"] = "大漠孤烟，孤立无援啊……",
	
}
mobile_qianxinCard = sgs.CreateSkillCard{
	name = "mobile_qianxin",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local others, tars = room:getOtherPlayers(source), sgs.SPlayerList()
		for i = 1, self:subcardsLength() do
			local p = others:at(math.random(0, others:length() - 1))
			tars:append(p)
			others:removeOne(p)
		end
		local ids = self:getSubcards()
		room:sortByActionOrder(tars)
		for _, p in sgs.qlist(tars) do
			room:doAnimate(1, source:objectName(), p:objectName())
			local id = ids:at(math.random(0, ids:length() - 1))
			room:obtainCard(p, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), p:objectName(), self:objectName(), ""), false)
			room:setPlayerMark(p, self:objectName() .. source:objectName() .. "-Start", id)
			ids:removeOne(id)
		end
		local msg = sgs.LogMessage()
		msg.type = "#MobileQianxin"
		msg.from = source
		msg.to = tars
		room:sendLog(msg)
	end
}
mobile_qianxinVS = sgs.CreateViewAsSkill{
	n = 2,
	name = "mobile_qianxin",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and #selected < sgs.Self:getAliveSiblings():length()
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local skillcard = mobile_qianxinCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_qianxin") and not player:isKongcheng()
	end
}
mobile_qianxin = sgs.CreateTriggerSkill{
	name = "mobile_qianxin",
	view_as_skill = mobile_qianxinVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local id = player:getMark(self:objectName() .. p:objectName() .. "-Start")
			if id > 0 then
				for _, card in sgs.qlist(player:getCards("he")) do
					if card:getId() ~= id then continue end
					room:doAnimate(1, p:objectName(), player:objectName())
					sendComLog(p, self:objectName(), false, 2)
					local _data = sgs.QVariant()
					_data:setValue(p)
					local choice = room:askForChoice(player, self:objectName(), "m_qianxin_draw+m_qianxin_debuff", _data)
					ChoiceLog(player, choice)
					if choice == "m_qianxin_draw" then
						p:drawCards(2, self:objectName())
					else
						room:setPlayerFlag(player, "m_qianxin_debuff")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Start
	end
}
mobile_zhanggong:addSkill(mobile_qianxin)
sgs.LoadTranslationTable{
	["mobile_qianxin"] = "遣信",
	[":mobile_qianxin"] = "出牌阶段限一次，你可以将一至两张手牌作为“信”随机交给等量其他角色。这些角色的下个准备阶段，若其有“信”，其选择一项：1.令你摸两张牌；2.其本回合内手牌上限-2。",
	["$mobile_qianxin1"] = "兵困绝地，将至如归！",
	["$mobile_qianxin2"] = "临危之际，速速来援！",
	["m_qianxin_draw"] = "令其摸两张牌",
	["m_qianxin_debuff"] = "你本回合内手牌上限-2",
	["#MobileQianxin"] = "%from 的“信”被送至 %to 手中",
	
}

mobile_zhanggong:addSkill("zhenxing")

new_huangfusong = sgs.General(extension, "new_huangfusong", "qun", 4)
sgs.LoadTranslationTable{
	["new_huangfusong"] = "新-皇甫嵩",
	["&new_huangfusong"] = "皇甫嵩",
	["#new_huangfusong"] = "志定雪霜",
	["~new_huangfusong"] = "",
	
}

new_fenyueCard = sgs.CreateSkillCard{
	name = "new_fenyue",
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:canPindian(to_select, self:objectName())
	end,
	on_use = function(self, room, source, targets)
		source:pindian(targets[1], self:objectName())
	end
}
new_fenyueVS = sgs.CreateZeroCardViewAsSkill{
	name = "new_fenyue",
	view_as = function(self)
		return new_fenyueCard:clone()
	end,
	enabled_at_play = function(self, player)
		local n = 0
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if not p:isYourFriend(player) then n = n + 1 end
		end
		return player:usedTimes("#new_fenyue") < n and not player:isKongcheng()
	end
}
new_fenyue = sgs.CreateTriggerSkill{
	name = "new_fenyue",
	events = {sgs.Pindian},
	view_as_skill = new_fenyueVS,
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local number = pindian.from_number
			if number <= pindian.to_number then return false end
			if number <= 5 and pindian.to:isAlive() and not pindian.to:isNude() then
				local id = room:askForCardChosen(player, pindian.to, "he", self:objectName())
				if id ~= -1 then
					room:obtainCard(player, sgs.Sanguosha:getCard(id),
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), pindian.to:objectName(), self:objectName(), ""), false)
				end
			end
			if number <= 9 then
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Slash") then
						room:obtainCard(player, id, true)
						break
					end
				end
			end
			local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			if number <= 13 and pindian.to:isAlive() and sgs.Slash_IsAvailable(player) and player:canSlash(pindian.to, slash, false)
				and not player:isProhibited(pindian.to, slash) then
				room:useCard(sgs.CardUseStruct(slash, player, pindian.to))
			end
			slash:deleteLater()
		end
		return false
	end
}
new_huangfusong:addSkill(new_fenyue)
sgs.LoadTranslationTable{
	["new_fenyue"] = "奋钺",
	[":new_fenyue"] = "出牌阶段限X次（X为与你阵营不同的存活角色数），你可以与一名角色拼点，若你赢，则根据你拼点牌的点数依次执行以下效果：不大于5，你获得其一张牌；不大于9，你获得牌堆里的一张【杀】；不大于K，你视为对其使用一张雷【杀】。",
	
}




sp_zhangyi = sgs.General(extension, "sp_zhangyi", "shu", 4)
sgs.LoadTranslationTable{
	["sp_zhangyi"] = "张翼",
	["#sp_zhangyi"] = "亢锐怀忠",
	["~sp_zhangyi"] = "惟愿百姓不受此乱所害……",
	
}
zhiyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhiyi",
	response_pattern = "@@zhiyi!",
	view_as = function(self)
		local card_str = sgs.Self:property(self:objectName()):toString():split("|")
		local zhiyiCard = sgs.Sanguosha:cloneCard(card_str[1], tonumber(card_str[2]), 0)
		zhiyiCard:setSkillName("_" .. self:objectName())
		return zhiyiCard
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
zhiyi = sgs.CreateTriggerSkill{
	name = "zhiyi",
	view_as_skill = zhiyiVS,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("BasicCard") and player:getMark("zhiyiCount-Clear") < 2 then
			local choiceList = {"zhiyi_draw"}
			local virtual_card = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
			virtual_card:setSkillName("_" .. self:objectName())
			if virtual_card:isAvailable(player) then
				local can_use = virtual_card:targetFixed()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if card:targetFilter(sgs.PlayerList(), p, player) then
						can_use = true
						break
					end
				end
				if can_use then
					table.insert(choiceList, 1, "zhiyi_use")
				end
			end
			local _data = sgs.QVariant()
			_data:setValue(card)
			local choice = room:askForChoice(player, self:objectName(), table.concat(choiceList, "+"), _data)
			sendComLog(player, self:objectName())
			if choice == "zhiyi_use" then
				if event == sgs.CardResponded and not data:toCardResponse().m_isUse then
					if card:targetFixed() then
						room:useCard(sgs.CardUseStruct(virtual_card, player, nil), true)
					else
						local card_str = string.format("%s|%s", card:objectName(), tostring(card:getSuit()))
						room:setPlayerProperty(player, "zhiyi", sgs.QVariant(card_str))
						room:askForUseCard(player, "@@zhiyi!", "@zhiyi")
						room:setPlayerProperty(player, "zhiyi", sgs.QVariant())
					end
					virtual_card:deleteLater()
				else
					room:setPlayerMark(player, card:objectName() .. card:getEffectiveId() .. "-Clear", 1)
				end
			else
				player:drawCards(1, self:objectName())
			end
		end
		return false
	end
}
ZhiyiUse = sgs.CreateTriggerSkill{
	name = "#zhiyi-use",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local card = data:toCardUse().card
		if not card:isKindOf("BasicCard") then return false end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local mark_name = card:objectName() .. card:getEffectiveId() .. "-Clear"
			if p:getMark(mark_name) > 0 then
				room:setPlayerMark(p, mark_name, 0)
				local virtual_card = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
				virtual_card:setSkillName("_zhiyi")
				if not virtual_card:isAvailable(p) then return false end
				if card:targetFixed() then
					room:useCard(sgs.CardUseStruct(virtual_card, p, p), true)
				else
					local can_use = false
					for _, to_select in sgs.qlist(room:getAlivePlayers()) do
						if card:targetFilter(sgs.PlayerList(), to_select, p) then
							can_use = true
							break
						end
					end
					if can_use then
						local card_str = string.format("%s|%s", card:objectName(), tostring(card:getSuit()))
						room:setPlayerProperty(p, "zhiyi", sgs.QVariant(card_str))
						room:askForUseCard(p, "@@zhiyi!", string.format("@zhiyi:::%s:%s", card:objectName(), card:getSuitString() .. "_char"))
						room:setPlayerProperty(p, "zhiyi", sgs.QVariant())
					end
				end
				virtual_card:deleteLater()
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhiyiBuff = sgs.CreateTargetModSkill{
	name = "#zhiyi-buff",
	pattern = ".",
	residue_func = function(self, from, card, to)
		return card:getSkillName() == "zhiyi" and 1000 or 0
	end
}
sp_zhangyi:addSkill(zhiyi)
sp_zhangyi:addSkill(ZhiyiUse)
sp_zhangyi:addSkill(ZhiyiBuff)
extension:insertRelatedSkills("zhiyi", "zhiyi-use")
extension:insertRelatedSkills("zhiyi", "zhiyi-buff")
sgs.LoadTranslationTable{
	["zhiyi"] = "执义",
	[":zhiyi"] = "锁定技，当你于一回合第一次使用或打出基本牌时，你选择一项：1.于此牌结算结束后，视为你使用此牌（无次数限制）；2.摸一张牌。",
	["zhiyi_use"] = "于此牌结算结束后，视为你使用此牌（无次数限制）",
	["zhiyi_draw"] = "摸一张牌",
	["@zhiyi"] = "请视为使用一张 %arg[%arg2]",
	["~zhiyi"] = "按此牌的使用方式使用",
	["$zhiyi1"] = "岂可擅退而误国家之功！",
	["$zhiyi2"] = "统摄不懈，只为破敌！",
	["no_suit_black_char"] = "黑色",
	["no_suit_red_char"] = "红色",
	
}

jiakui = sgs.General(extension, "jiakui", "wei", 3)
sgs.LoadTranslationTable{
	["jiakui"] = "贾逵",
	["#jiakui"] = "肃齐万里",
	["~jiakui"] = "不斩孙权，九泉之下愧见先帝啊！",
	
}

zhongzuo = sgs.CreateTriggerSkill{
	name = "zhongzuo",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:getMark("damage_round-Clear") == 0 and p:getMark("damaged_round-Clear") == 0 then continue end
			local to = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), "zhongzuo-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				to:drawCards(2, self:objectName())
				if to:isWounded() then
					p:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
jiakui:addSkill(zhongzuo)
sgs.LoadTranslationTable{
	["zhongzuo"] = "忠佐",
	[":zhongzuo"] = "一名角色的回合结束时，若你于此回合内造成或受到过伤害，则你可以令一名角色摸两张牌。若该角色已受伤，则你摸一张牌。",
	["zhongzuo-invoke"] = "忠佐：你可以令一名角色摸两张牌，若该角色已受伤，则你摸一张牌",
	["$zhongzuo1"] = "历经磨难，不改祖国之志！",
	["$zhongzuo2"] = "建立功业，惟愿天下早定。",
	
}

wanlan = sgs.CreateTriggerSkill{
	name = "wanlan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@wanlan",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		local to = data:toDying().who
		local current = room:getCurrent()
		if to:getHp() < 1 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(string.format("wanlan-to:%s:%s", to:objectName(), current:objectName()))) then
			room:broadcastSkillInvoke(self:objectName())
			room:removePlayerMark(player, "@wanlan")
			player:throwAllHandCards()
			room:doAnimate(1, player:objectName(), to:objectName())
			room:recover(to, sgs.RecoverStruct(player, nil, 1 - to:getHp()))
			room:getThread():delay()
			if current and current:isAlive() then
				room:doAnimate(1, player:objectName(), current:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, current))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:canDiscard(target, "h") and target:getMark("@wanlan") > 0
	end
}
jiakui:addSkill(wanlan)
sgs.LoadTranslationTable{
	["wanlan"] = "挽澜",
	[":wanlan"] = "限定技，当一名角色进入濒死状态时，你可以弃置所有手牌令其回复体力至1点，然后你对当前回合角色造成1点伤害。",
	["wanlan:wanlan-to"] = "挽澜：你可以弃置所有手牌令 %src 回复体力至1点，然后你对 %dest 造成1点伤害",
	["$wanlan1"] = "挽狂澜于既倒，扶大厦于将倾！",
	["$wanlan2"] = "深受国恩，今日便是报偿之时！",
	
}

beyond_xusheng = sgs.General(extension, "beyond_xusheng", "wu", 4)
sgs.LoadTranslationTable{
	["beyond_xusheng"] = "界徐盛",
	["#beyond_xusheng"] = "整军经武",
	["~beyond_xusheng"] = "盛只恨……不能再为主公……破敌制胜了……",
	
}

beyond_pojun = sgs.CreateTriggerSkill{
	name = "beyond_pojun",
	events = {sgs.TargetSpecified, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				for _, t in sgs.qlist(use.to) do
					local n = math.min(t:getCards("he"):length(), t:getHp())
					local _data = sgs.QVariant()
					_data:setValue(t)
					if n > 0 and player:askForSkillInvoke(self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), t:objectName())
						local dis_num = {}
						for i = 1, n do
							table.insert(dis_num, tostring(i))
						end
						local discard_n = tonumber(room:askForChoice(player, self:objectName() .. "_num", table.concat(dis_num, "+"))) - 1
						local orig_places = sgs.PlaceList()
						local cards = sgs.IntList()
						t:setFlags("beyond_pojun_InTempMoving")
						for i = 0, discard_n do
							local id = room:askForCardChosen(player, t, "he", self:objectName() .. "_dis", false, sgs.Card_MethodNone)
							local place = room:getCardPlace(id)
							orig_places:append(place)
							cards:append(id)
							t:addToPile("#beyond_pojun", id, false)
						end
						for i = 0, discard_n do
							room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), t, orig_places:at(i), false)
						end
						t:setFlags("-beyond_pojun_InTempMoving")
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(cards)
						local tt = sgs.SPlayerList()
						tt:append(t)
						t:addToPile("beyond_pojun", dummy, false, tt)
					end
				end
			end
		else
			local damage = data:toDamage()
			local to = damage.to
			if damage.card and damage.card:isKindOf("Slash") and to and to:isAlive() then
				if to:getHandcardNum() > player:getHandcardNum() or to:getEquips():length() > player:getEquips():length() then return false end
				sendComLog(player, self:objectName())
				room:doAnimate(1, player:objectName(), to:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end
}

beyond_pojunReturn = sgs.CreateTriggerSkill{
	name = "#beyond_pojun-return",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:getPile("beyond_pojun"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile("beyond_pojun"))
					room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), self:objectName(), ""), false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

beyond_pojunFakeMove = sgs.CreateTriggerSkill{
	name = "#beyond_pojun-fake_move",
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	priority = 10,
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("beyond_pojun_InTempMoving") then return true end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

beyond_xusheng:addSkill(beyond_pojun)
beyond_xusheng:addSkill(beyond_pojunReturn)
beyond_xusheng:addSkill(beyond_pojunFakeMove)
extension:insertRelatedSkills("beyond_pojun", "#beyond_pojun-return")
extension:insertRelatedSkills("beyond_pojun", "#beyond_pojun-fake_move")
sgs.LoadTranslationTable{
	["beyond_pojun"] = "破军",
	[":beyond_pojun"] = "当你使用【杀】指定一个目标后，你可以将其一至X张牌扣置于其武将牌旁（X为其体力值），若如此做，当前回合结束时，其获得这些牌；当你使用【杀】对手牌数与装备区牌数均不大于的角色造成伤害时，此伤害+1。",
	["beyond_pojun_num"] = "移除数",
	["beyond_pojun_dis"] = "选择牌",
	["$beyond_pojun1"] = "犯大吴疆土者，盛必击而破之！",
	["$beyond_pojun2"] = "若敢来犯，必教你大败而归！",
	
}

beyond_wuguotai = sgs.General(extension, "beyond_wuguotai", "wu", 3, false)
sgs.LoadTranslationTable{
	["beyond_wuguotai"] = "界吴国太",
	["#beyond_wuguotai"] = "慈怀瑾瑜",
	["~beyond_wuguotai"] = "诸位卿家，还请务必辅佐仲谋啊……",
	
}

function swapEquip(first, second)
	local room = first:getRoom()
	
	local equips1, equips2 = sgs.IntList(), sgs.IntList()
	local to_throw1, to_throw2 = sgs.IntList(), sgs.IntList()
	for _, equip in sgs.qlist(first:getEquips()) do
		local equipcard = equip:getRealCard():toEquipCard()
		local equip_index = equipcard:location()
		if second:hasEquipArea(equip_index) then
			equips1:append(equip:getId())
		else
			to_throw1:append(equip:getId())
		end
	end
	for _, equip in sgs.qlist(second:getEquips()) do
		local equipcard = equip:getRealCard():toEquipCard()
		local equip_index = equipcard:location()
		if first:hasEquipArea(equip_index) then
			equips2:append(equip:getId())
		else
			to_throw2:append(equip:getId())
		end
	end
	
	local exchangeMove = sgs.CardsMoveList()
	exchangeMove:append(sgs.CardsMoveStruct(equips1, second, sgs.Player_PlaceEquip,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, first:objectName(), second:objectName(), "ganlu", "")))
	exchangeMove:append(sgs.CardsMoveStruct(to_throw1, nil, sgs.Player_DiscardPile,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "ganlu", "")))
	exchangeMove:append(sgs.CardsMoveStruct(equips2, first, sgs.Player_PlaceEquip,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, second:objectName(), first:objectName(), "ganlu", "")))
	exchangeMove:append(sgs.CardsMoveStruct(to_throw2, nil, sgs.Player_DiscardPile,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "ganlu", "")))
	room:moveCardsAtomic(exchangeMove, false)
	sgs.Sanguosha:playAudioEffect("audio/card/common/armor.ogg", false)
end

beyond_ganluCard = sgs.CreateSkillCard{
	name = "beyond_ganlu",
	filter = function(self, targets, to_select)
		if #targets == 0 then return true
		elseif #targets == 1 then
			local n1 = targets[1]:getEquips():length()
            local n2 = to_select:getEquips():length()
            return math.abs(n1 - n2) <= sgs.Self:getLostHp() or (targets[1]:objectName() == sgs.Self:objectName() or to_select:objectName() == sgs.Self:objectName())
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local msg = sgs.LogMessage()
		msg.type = "#GanluSwap"
		msg.from = source
		msg.to = Table2SPList(targets)
		room:sendLog(msg)
		swapEquip(targets[1], targets[2])
	end
}
beyond_ganlu = sgs.CreateZeroCardViewAsSkill{
	name = "beyond_ganlu",
	view_as = function(self)
		return beyond_ganluCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#beyond_ganlu")
	end
}
beyond_wuguotai:addSkill(beyond_ganlu)
sgs.LoadTranslationTable{
	["beyond_ganlu"] = "甘露",
	[":beyond_ganlu"] = "出牌阶段限一次，你可以选择两名装备区里的牌数之差不大于你已损失体力值的角色，交换他们装备区里的牌。若你选择的角色中有你，则无牌数之差的限制。",
	["$beyond_ganlu1"] = "玄德实乃佳婿啊。",
	["$beyond_ganlu2"] = "好一个郎才女貌，真是天作之合啊。",
	
}

beyond_wuguotai:addSkill("buyi")

beyond_gaoshun = sgs.General(extension, "beyond_gaoshun", "qun", 4)
sgs.LoadTranslationTable{
	["beyond_gaoshun"] = "界高顺",
	["#beyond_gaoshun"] = "攻无不克",
	["~beyond_gaoshun"] = "可叹主公，知而不用啊……",
	
}

beyond_xianzhenCard = sgs.CreateSkillCard{
	name = "beyond_xianzhen",
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select, self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("Slash") then room:setPlayerFlag(effect.from, self:objectName()) end
		if effect.from:pindian(effect.to, self:objectName(), self) then
			room:setPlayerProperty(effect.to, self:objectName(), sgs.QVariant(effect.from:objectName()))
			local assignee_list = effect.from:property("extra_slash_specific_assignee"):toString():split("+")
            table.insert(assignee_list, effect.to:objectName())
            room:setPlayerProperty(effect.from, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list, "+")))
			room:addPlayerMark(effect.to, "Armor_Nullified")
		else
			room:setPlayerFlag(effect.from, "beyond_xianzhen-limited")
			room:setPlayerCardLimitation(effect.from, "use", "Slash", true)
		end
		effect.from:setTag(self:objectName(), sgs.QVariant(true))
	end
}
beyond_xianzhen = sgs.CreateOneCardViewAsSkill{
	name = "beyond_xianzhen",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local skillcard = beyond_xianzhenCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#beyond_xianzhen") or player:isKongcheng())
	end
}

beyond_xianzhenClear = sgs.CreateTriggerSkill{
	name = "#beyond_xianzhen-clear",
	events = {sgs.EventPhaseChanging, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			if not player:getTag("beyond_xianzhen"):toBool() then return false end
			if data:toPhaseChange().from == sgs.Player_Play then
				player:removeTag("beyond_xianzhen")
				local assignee_list = player:property("extra_slash_specific_assignee"):toString():split("+")
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:property("beyond_xianzhen"):toString() == "" then continue end
					table.removeOne(assignee_list, p:objectName())
					room:setPlayerProperty(p, "beyond_xianzhen", sgs.QVariant())
					room:removePlayerMark(p, "Armor_Nullified")
				end
				room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list, "+")))
				if player:hasFlag("beyond_xianzhen-limited") then
					room:setPlayerFlag(player, "-beyond_xianzhen-limited")
					room:removePlayerCardLimitation(player, "use", "Slash$1")
				end
			end
		else
			if player:isKongcheng() or not player:hasFlag("beyond_xianzhen") then return false end
			if event == sgs.AskForGameruleDiscard then
				local n = room:getTag("DiscardNum"):toInt()
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("Slash") then
						n = n - 1
					end
				end
				room:setPlayerCardLimitation(player, "discard", "Slash", true)
				room:setTag("DiscardNum", sgs.QVariant(n))
			else
				room:removePlayerCardLimitation(player, "discard", "Slash$1")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
beyond_gaoshun:addSkill(beyond_xianzhen)
beyond_gaoshun:addSkill(beyond_xianzhenClear)
extension:insertRelatedSkills("beyond_xianzhen", "#beyond_xianzhen-Clear")
sgs.LoadTranslationTable{
	["beyond_xianzhen"] = "陷阵",
	[":beyond_xianzhen"] = "出牌阶段限一次，你可以与一名角色拼点，若你：赢，则你于此阶段内无视其防具且对其使用牌无距离和次数限制；没赢，你此阶段内不能使用【杀】。若你以此法拼点的牌为【杀】，则本回合内你手牌中的【杀】不计入手牌上限。\
							PS:使用技能时请先选择卡牌再选择拼点对象（为实现部分效果不得已而为）。",
	["$beyond_xianzhen1"] = "陷阵之志，有死无生！",
	["$beyond_xianzhen2"] = "攻则破城，战则破敌！",
	
}

beyond_jinjiu = sgs.CreateFilterSkill{
	name = "beyond_jinjiu",
	frequency = sgs.Skill_Compulsory,
	view_filter = function(self, to_select)
		return to_select:objectName() == "analeptic"
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
}

beyond_jinjiuTrigger = sgs.CreateTriggerSkill{
	name = "#beyond_jinjiu-trigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local card = damage.card
			if card and card:isKindOf("Slash") and card:getTag("analeptic-damage"):toInt() > 0 then
				sendComLog(player, "beyond_jinjiu")
				damage.damage = math.max(damage.damage - card:getTag("analeptic-damage"):toInt(), 0)
				data:setValue(damage)
				if damage.damage == 0 then
					return true
				end
			end
		else
			if (event == sgs.EventPhaseChanging and data:toPhaseChange().from == sgs.Player_NotActive)
				or (event == sgs.EventAcquireSkill and data:toString() == "beyond_jinjiu") then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setPlayerCardLimitation(p, "use", "Analeptic", true)
				end
			elseif (event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive)
				or (event == sgs.EventLoseSkill and data:toString() == "beyond_jinjiu") then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:removePlayerCardLimitation(p, "use", "Analeptic$1")
				end
			end
		end
		return false
	end
}
beyond_gaoshun:addSkill(beyond_jinjiu)
beyond_gaoshun:addSkill(beyond_jinjiuTrigger)
extension:insertRelatedSkills("beyond_jinjiu", "#beyond_jinjiu-trigger")
sgs.LoadTranslationTable{
	["beyond_jinjiu"] = "禁酒",
	[":beyond_jinjiu"] = "锁定技，你的【酒】均视为【杀】；当你受到【酒】【杀】造成的伤害时，此伤害-X（X为增加此【杀】伤害的【酒】数）；其他角色于你的回合内不能使用【酒】。",
	["$beyond_jinjiu1"] = "啖此黄汤，岂不误事？",
	["$beyond_jinjiu2"] = "陷阵营中，不可饮酒。",
	
}

sgs.Sanguosha:addSkills(skills)

return {extension}
