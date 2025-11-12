--module("extensions.Dragon", package.seeall)
extension = sgs.Package("Dragon")
local Promote_darksoul_mode = true
--™&©2008游卡桌游 三国杀 总设计师：KayaK MOD汇总：Super飞虎将军 主要编写人：786852516 其他参与人员：myetyet JOOOOKER 啦啦SLG 西域伊浪 youko1316
sgs.LoadTranslationTable{
	["Dragon"] = "龙版", 
}
--技能描述 由 Super飞虎将军 修改 （不规范之处请多多包涵
Dragon_liubei = sgs.General(extension, "Dragon_liubei$", "shu", "4")

Dragon_rendeCard = sgs.CreateSkillCard{
	name = "Dragon_rendeCard", 
	will_throw = false, 
	handling_method = sgs.Card_MethodNone, 
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end, 
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local old_value = source:getMark("Dragon_rende");
		local rende_list = {}
		if old_value > 0 then
			rende_list = source:property("Dragon_rende"):toString():split("+")
		else
			rende_list = sgs.QList2Table(source:handCards())
		end
		for _, id in sgs.qlist(self:getSubcards())do
			table.removeOne(rende_list, id)
		end
		room:setPlayerProperty(source, "Dragon_rende", sgs.QVariant(table.concat(rende_list, "+")));
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "Dragon_rende", "")
		room:moveCardTo(self, target, sgs.Player_PlaceHand, reason)
		room:broadcastSkillInvoke("rende")
		local new_value = old_value + self:getSubcards():length()
		room:setPlayerMark(source, "Dragon_rende", new_value);
		--[[room:obtainCard(target, self, false)
		local old_value = source:getMark("Dragon_rende")
		local new_value = old_value + self:getSubcards():length()]]
		while new_value >= 2 do
			local rec = sgs.RecoverStruct()
			rec.card = self
			rec.who = source
			room:recover(source, rec)
			new_value = new_value - 2
		end
		room:setPlayerMark(source, "Dragon_rende", new_value)
		if source:isKongcheng() or source:isDead() or #rende_list == 0 then return end
	end
}

Dragon_rendeVS = sgs.CreateViewAsSkill{
	name = "Dragon_rende", 
	n = 998, 
	response_pattern = "@@Dragon_rende", 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local rende_card = Dragon_rendeCard:clone()
		for _, c in ipairs(cards) do
			rende_card:addSubcard(c)
		end
		return rende_card
	end, 
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}

Dragon_rende = sgs.CreateTriggerSkill{
	name = "Dragon_rende", 
	events = {sgs.EventPhaseChanging}, 
	view_as_skill = Dragon_rendeVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
			room:setPlayerMark(player, "Dragon_rende", 0)
			return false
		end, 
	can_trigger = function(self, target)
		return target and (target:getMark("Dragon_rende") > 0)
	end
}
-- 仁德 由 myetyet 修改
Dragon_jijiangCard = sgs.CreateSkillCard{
	name = "Dragon_jijiangCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		local slash = nil
		local lieges = room:getLieges("shu", source)
		local tos = sgs.SPlayerList()
		for i = 1, #targets, 1 do
			tos:append(targets[i])
			targets[i]:setFlags("Dragon_jijiangTarget")
		end
		for _, liege in sgs.qlist(lieges) do
			slash = room:askForUseSlashTo(liege, tos, "@jijiang-slash:" .. source:objectName(), false, false)
			if slash then
				for i = 1, #targets, 1 do
					targets[i]:setFlags("-Dragon_jijiangTarget")
				end
				room:addPlayerHistory(source, "Slash", 1)
				return false
			end
		end
		for i = 1, #targets, 1 do
			targets[i]:setFlags("-Dragon_jijiangTarget")
		end
		room:setPlayerFlag(source, "Global_Dragon_jijiangFailed")
		return false
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
Dragon_jijiangVS = sgs.CreateZeroCardViewAsSkill{
	name = "Dragon_jijiang$" ,
	view_as = function()
		return Dragon_jijiangCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return hasShuGenerals(player) and player:hasLordSkill("Dragon_jijiang") and (not player:hasFlag("Global_Dragon_jijiangFailed")) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return hasShuGenerals(player) and player:hasLordSkill("Dragon_jijiang") and ((pattern == "slash") or (pattern == "@jijiang")) and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) and (not player:hasFlag("Global_Dragon_jijiangFailed"))
	end
}

Dragon_jijiang = sgs.CreateTriggerSkill{
	name = "Dragon_jijiang$" ,
	events = {sgs.CardAsked} ,
	view_as_skill = Dragon_jijiangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		if (pattern ~= "slash") or string.find(prompt, "@jijiang-slash") then return false end
		local source = player
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:objectName() == prompt:split(":")[2] then
				source = p
			end
		end
		local slash = false
		local _data = sgs.QVariant()
		_data:setValue(source)
		local lieges = room:getLieges("shu", player)
		if lieges:isEmpty() then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		for _, liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", "@jijiang-slash:" .. player:objectName(), _data, sgs.Card_MethodResponse, source)
			if slash then
				room:provide(slash)
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasLordSkill("Dragon_jijiang")
	end
}
-- 激将 由 Super飞虎将军 修改
Dragon_liubei:addSkill(Dragon_rende)
-- Dragon_liubei:addSkill(Dragon_jijiang)
Dragon_liubei:addSkill("jijiang")

sgs.LoadTranslationTable{
	["Dragon_liubei"] = "龙版刘备", 
	["designer:Dragon_liubei"] = "官方|Lua：myetyet", 
	["Dragon_rende"] = "仁德", 
	["dragon_rende"] = "仁德", 
	[":Dragon_rende"] = "出牌阶段，你可以将任意数量的手牌交给一名其他角色，以此法每给出两张牌你便回复1点体力。", 
	["~Dragon_rende"] = "选择至少一张手牌→选择一名其他角色→点击确定", 
	["Dragon_jijiang"] = "激将", 
	[":Dragon_jijiang"] = "<font color=\"orange\"><b>主公技，</b></font>当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色使用或打出一张【杀】。", 
}

Dragon_guanyu = sgs.General(extension, "Dragon_guanyu", "shu", "4")

Dragon_wushengCard = sgs.CreateBasicCard{
	name = "slash",
	class_name = "Slash",
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return slash and slash:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, slash, qtargets)
	end,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		card:addSubcards(self:getSubcards())
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		local use_card = sgs.Sanguosha:cloneCard("slash", self:getSuit(), self:getNumber())
		use_card:addSubcards(self:getSubcards())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to ) do
			if xunyou:isProhibited(p,use_card)	then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
Dragon_wusheng = sgs.CreateOneCardViewAsSkill{
	name = "Dragon_wusheng",
	response_or_use = true,
	filter_pattern = ".|red",
	view_as = function(self, card)
		local c = Dragon_wushengCard:clone()
		c:setSkillName(self:objectName())
		c:addSubcard(card)
		return c
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player,pattern)
		return pattern == "slash"
	end
}
-- 武圣 由 youko1316 编写
Dragon_guanyu:addSkill(Dragon_wusheng)

sgs.LoadTranslationTable{
	["Dragon_guanyu"] = "龙版关羽", 
	["Dragon_wusheng"] = "武圣", 
	[":Dragon_wusheng"] = "你可以无视武器效果将一张红色牌当【杀】使用或打出。", 
}

Dragon_zhangfei = sgs.General(extension, "Dragon_zhangfei", "shu", "4")

Dragon_feijiangCard = sgs.CreateSkillCard{
	name = "Dragon_feijiangCard",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, player, targets)
		if room:askForUseCard(player, "slash", "@paoxiao", -1, sgs.Card_MethodUse) then
		else
			room:addPlayerMark(player, "Dragon_feijiangFailed-PlayClear")
		end
	end,
}
Dragon_feijiang = sgs.CreateZeroCardViewAsSkill{
	name = "Dragon_feijiang",
	response_pattern = "@@paoxiao",
	view_as = function(self, ocard)
		local card = Dragon_feijiangCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function()
		return true
	end
}

Dragon_zhangfei:addSkill(Dragon_feijiang)

sgs.LoadTranslationTable{
	["Dragon_zhangfei"] = "龙版张飞", 
	["Dragon_feijiang"] = "飞将", 
	[":Dragon_feijiang"] = "出牌阶段，你可以使用任意数量的【杀】。", 
	["dragon_feijiang"] = "飞将", 
	["@paoxiao"] = "你可以使用一张【杀】", 
}

Dragon_zhugeliang = sgs.General(extension, "Dragon_zhugeliang", "shu", "3")

Dragon_guanxing = sgs.CreateTriggerSkill{
	name = "Dragon_guanxing", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("guanxing")
				local stars = room:getNCards(3, false)
				room:askForGuanxing(player, stars)
			end
		end
	end
}

Dragon_kongcheng = sgs.CreateTriggerSkill{
	name = "Dragon_kongcheng" , 
	events = {sgs.CardEffected, sgs.CardResponded, sgs.CardFinished, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			if not effect.card:isKindOf("Slash") then return false end
			if effect.from:objectName() ~= player:objectName() and player:isKongcheng() then
				room:broadcastSkillInvoke("kongcheng")
				return true
			end
		elseif event == sgs.CardResponded then
			local card = data:toCardResponse().m_card
			if card and card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke("kongcheng")
				room:setPlayerMark(player, "Dragon_kongcheng", 0)
			end
		elseif event == sgs.CardFinished or event == sgs.DamageInflicted then
			local use = data:toCardUse()
			local damage = data:toDamage()
			local damaged = false
			if damage.card and damage.card:isKindOf("Duel") and damage.to:getMark("Dragon_kongcheng") > 0 then
				damaged = true
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("Dragon_kongcheng") > 0 then
					player:setMark("Dragon_kongcheng", 0)
				end
			end
			if event == sgs.DamageInflicted and damaged then
				damage.prevented = true
				data:setValue(damage)
				return damaged
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
-- 空城 由 786852516 编写 （中间响应的部分由 啦啦SLG 提供建议）
Dragon_zhugeliang:addSkill(Dragon_guanxing)
Dragon_zhugeliang:addSkill(Dragon_kongcheng)

sgs.LoadTranslationTable{
	["Dragon_zhugeliang"] = "龙版诸葛亮", 
	["designer:Dragon_zhugeliang"] = "官方|Lua：红月⑦ & 啦啦SLG", 
	["illustrator:Dragon_zhugeliang"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_guanxing"] = "观星", 
	[":Dragon_guanxing"] = "摸牌阶段开始时，你可以观看牌堆顶三张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。", 
	["Dragon_kongcheng"] = "空城", 
	[":Dragon_kongcheng"] = "<font color=\"blue\"><b>锁定技，</b></font>若你没有手牌，其他角色的【杀】对你无效。\
	<font color=\"black\"><b>◆其他角色使用的【杀】对你无效，与你进行决斗的角色打出【杀】不能对你造成伤害。</b></font>", 
}

Dragon_zhaoyun = sgs.General(extension, "Dragon_zhaoyun", "shu", "4")

Dragon_zhaoyun:addSkill("longdan")

sgs.LoadTranslationTable{
	["Dragon_zhaoyun"] = "龙版赵云", 
	["illustrator:Dragon_zhaoyun"] = "KayaK|Card：赵云涯角七无懈", 
}

Dragon_machao = sgs.General(extension, "Dragon_machao", "shu", "4")

Dragon_mashuthrow = sgs.CreateTriggerSkill{
	name = "#Dragon_mashuthrow" , 
	events = {sgs.CardsMoveOneTime}, 
	frequency = sgs.Skill_Compulsory , 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:isAlive() and player:hasSkill(self:objectName()) and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip then
			local flag1
			local flag2
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("DefensiveHorse") then
					flag1 = true break
				elseif card:isKindOf("OffensiveHorse") then
					flag2 = true break
				end
			end
			if flag1 then 
				local ids = sgs.IntList()
				for _, card in sgs.qlist(player:getEquips()) do
					if card:isKindOf("OffensiveHorse") then
						ids:append(card:getId())
					end
				end
				if not ids:isEmpty() then 
					local move2 = sgs.CardsMoveStruct()
					move2.card_ids = ids
					move2.to = nil
					move2.to_place = sgs.Player_DiscardPile
					move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
					room:moveCardsAtomic(move2, true)
				end
			elseif flag2 then 
				local ids = sgs.IntList()
				for _, card in sgs.qlist(player:getEquips()) do
					if card:isKindOf("DefensiveHorse") then
						ids:append(card:getId())
					end
				end
				if not ids:isEmpty() then 
					local move2 = sgs.CardsMoveStruct()
					move2.card_ids = ids
					move2.to = nil
					move2.to_place = sgs.Player_DiscardPile
					move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
					room:moveCardsAtomic(move2, true)
				end
			end
		end
	end
}

Dragon_mashu = sgs.CreateDistanceSkill{
	name = "Dragon_mashu", 
	correct_func = function(self, from, to)
		if from:hasSkill("Dragon_mashu") then
			return -1
		end
		if to:hasSkill("Dragon_mashu") == 0 then
			return 1
		end
	end, 
}
-- 马术 由 786852516 编写
Dragon_machao:addSkill(Dragon_mashu)
Dragon_machao:addSkill(Dragon_mashuthrow)
extension:insertRelatedSkills("Dragon_mashu", "#Dragon_mashuthrow")

sgs.LoadTranslationTable{
	["Dragon_machao"] = "龙版马超", 
	["designer:Dragon_machao"] = "官方|Lua：红月⑦", 
	["illustrator:Dragon_machao"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_mashu"] = "马术", 
	[":Dragon_mashu"] = "<font color=\"blue\"><b>锁定技，</b></font>当你计算与其他角色的距离时，始终-1，当其他角色计算与你的距离时，始终+1，当一张坐骑牌置入你的装备区时，将你装备区里其他的坐骑牌置入弃牌堆。", 
}

Dragon_huangyueying = sgs.General(extension, "Dragon_huangyueying", "shu", "3", false)

Dragon_jizhi = sgs.CreateTriggerSkill{
	name = "Dragon_jizhi", 
	events = {sgs.CardFinished}, 
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardUse().card
		if card:isKindOf("TrickCard") then 
			if card:getSkillName() ~= "" then return false end
			if not room:askForSkillInvoke(player, "jizhi") then return false end
			player:drawCards(1)
			room:broadcastSkillInvoke("jizhi")
		end
	end, 
}

Dragon_huangyueying:addSkill(Dragon_jizhi)
Dragon_huangyueying:addSkill("nosqicai")

sgs.LoadTranslationTable{
	["Dragon_huangyueying"] = "龙版黄月英", 
	["illustrator:Dragon_huangyueying"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_jizhi"] = "集智", 
	[":Dragon_jizhi"] = "每当你使用一张锦囊牌时，你可以摸一张牌。", 
}

Dragon_sunquan = sgs.General(extension, "Dragon_sunquan$", "wu", "4")

Dragon_zhiheng = sgs.CreateTriggerSkill{
	name = "Dragon_zhiheng", 
	events = {sgs.EventPhaseChanging}, 
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				if not player:isKongcheng() then
					room:askForDiscard(player, self:objectName(), 999, 0, true, false, "Dragon_zhiheng-prompt")
				end
				if player:getHandcardNum() <= player:getHp() then
					player:drawCards(player:getHp()-player:getHandcardNum())
					room:broadcastSkillInvoke("zhiheng")
				end
			end
		end
	end
}
-- 制衡 由 786852516 编写
Dragon_fuyuanCard = sgs.CreateSkillCard{
	name = "Dragon_fuyuanCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("Dragon_fuyuan") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("Dragon_fuyuanInvoked")
				end
			end
		end
		return false
	end, 
	on_use = function(self, room, source, targets)
		local sunquan = targets[1]
		if sunquan:hasLordSkill("Dragon_fuyuan") then
			room:setPlayerFlag(sunquan, "Dragon_fuyuanInvoked")
			sunquan:obtainCard(self)
			room:broadcastSkillInvoke("jiuyuan")
			local subcards = self:getSubcards()
			for _, card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(sunquan, "good")
			local sunquans = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _, p in sgs.qlist(players) do
				if p:hasLordSkill("Dragon_fuyuan") then
					if not p:hasFlag("Dragon_fuyuanInvoked") then
						sunquans:append(p)
					end
				end
			end
			if sunquans:length() == 0 then
				room:setPlayerFlag(source, "Dragon_fuyuan")
			end
		end
	end
}

Dragon_fuyuanVS = sgs.CreateViewAsSkill{
	name = "Dragon_fuyuanVS&", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local card = Dragon_fuyuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getKingdom() == "wu" then
			return not player:hasFlag("Dragon_fuyuan")
		end
		return false
	end
}

Dragon_fuyuan = sgs.CreateTriggerSkill{
	name = "Dragon_fuyuan$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.Death}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local skill_exist = false
		if player:hasLordSkill(self:objectName()) then skill_exist = true end
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == "wu" and not p:hasSkill("Dragon_fuyuanVS") then
					room:attachSkillToPlayer(p, "Dragon_fuyuanVS")
				end
			end
		elseif ((event == sgs.EventLoseSkill and data:toString() == self:objectName()) or event == sgs.Death ) and not skill_exist then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("Dragon_fuyuanVS") then
					room:detachSkillFromPlayer(p, "Dragon_fuyuanVS")
				end
			end
		end
		return false
	end
}

Dragon_fuyuanClear = sgs.CreateTriggerSkill{
	name = "#Dragon_fuyuanClear", 
	events = {sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.from == sgs.Player_Play then
			if player:hasFlag("Dragon_fuyuan") then
				room:setPlayerFlag(player, "-Dragon_fuyuan")
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("Dragon_fuyuanInvoked") then
					room:setPlayerFlag(p, "-Dragon_fuyuanInvoked")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_fuyuanVS") then skill_list:append(Dragon_fuyuanVS)end
sgs.Sanguosha:addSkills(skill_list)
-- 辅援 由 786852516 编写
Dragon_sunquan:addSkill(Dragon_zhiheng)
Dragon_sunquan:addSkill(Dragon_fuyuan)
Dragon_sunquan:addSkill(Dragon_fuyuanClear)
extension:insertRelatedSkills("Dragon_fuyuan", "#Dragon_fuyuanClear")

sgs.LoadTranslationTable{
	["Dragon_sunquan"] = "龙版孙权", 
	["designer:Dragon_sunquan"] = "官方|Lua：红月⑦", 
	["Dragon_zhiheng"] = "制衡", 
	["dragon_zhiheng"] = "制衡", 
	[":Dragon_zhiheng"] = "回合结束时，你可以弃置任意数量的手牌，然后将你的手牌数补至你当前的体力值。", 
	["Dragon_zhiheng-prompt"] = "请弃置任意数量的手牌", 
	["Dragon_fuyuan"] = "辅援", 
	["dragon_fuyuan"] = "辅援", 
	[":Dragon_fuyuan"] = "<font color=\"orange\"><b>主公技，</b></font>其他角色吴势力于其<font color=\"green\"><b>出牌阶段限一次，</b></font>该角色可以交给你一张手牌。", 
	["Dragon_fuyuanVS"] = "辅援", 
	[":Dragon_fuyuanVS"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给<font color=\"green\"><b>龙版孙权</b></font>一张手牌。", 
}

Dragon_ganning = sgs.General(extension, "Dragon_ganning", "wu", "4")

tonglingCard = sgs.CreateSkillCard{
	name = "tonglingCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@bell")
		room:cardEffect(self, source, source)
		--source:setShownRole(true)
		--room:setPlayerProperty(source, "role", sgs.QVariant(source:getRole()))
		room:broadcastProperty(source,"role")
		local log = sgs.LogMessage()
			log.type = "#SkillEffect_Role"
			log.from = source
			log.arg = self:objectName()
			log.arg2 = source:getRole()
		room:sendLog(log)
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(source, recover)
	end, 
}

tonglingVS = sgs.CreateViewAsSkill{
	name = "tongling", 
	n = 0, 
	view_as = function(self, cards)
		return tonglingCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@bell") >= 1
	end--[[, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@tonglingCard"
	end]]
}

tongling = sgs.CreateTriggerSkill{
	name = "tongling" , 
	limit_mark = "@bell", 
	frequency = sgs.Skill_Limited , --sgs.PostHpReduced, HpReducedsgs.CardsMoving, sgs.CardDrawing, 
	events = {--[[sgs.NonTrigger, sgs.GameStart, sgs.TurnStart, sgs.EventPhaseStart, sgs.EventPhaseProceeding, sgs.EventPhaseEnd, 
	sgs.EventPhaseChanging, sgs.DrawNCards, sgs.AfterDrawNCards, sgs.DrawInitialCards, sgs.AfterDrawInitialCards, sgs.PreHpRecover, 
	sgs.HpRecover, sgs.PreHpLost, sgs.HpLost, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.StartJudge, 
	sgs.AskForRetrial, sgs.FinishRetrial, sgs.FinishJudge, sgs.PindianVerifying, sgs.Pindian, sgs.TurnedOver, sgs.ChainStateChanged, 
	sgs.ConfirmDamage, sgs.Predamage, sgs.DamageForseen, sgs.DamageCaused, sgs.DamageInflicted, sgs.PreDamageDone, sgs.DamageDone, sgs.Damage,
	sgs.Damaged, sgs.DamageComplete, sgs.EnterDying, sgs.Dying, sgs.QuitDying, sgs.AskForPeaches, sgs.AskForPeachesDone, sgs.Death, sgs.BuryVictim, 
	sgs.BeforeGameOverJudge, sgs.GameOverJudge, sgs.GameFinished, sgs.SlashEffect, sgs.SlashEffected, sgs.SlashProceed, sgs.SlashHit, sgs.SlashMissed,
	sgs.JinkEffect, sgs.NullificationEffect, sgs.CardAsked, sgs.PreCardResponded, sgs.CardResponded, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, 
	sgs.PreCardUsed, sgs.CardUsed, sgs.TargetSpecifying, sgs.TargetConfirming, sgs.TargetSpecified, sgs.TargetConfirmed, sgs.CardEffect, 
	sgs.CardEffected, sgs.PostCardEffected, sgs.CardFinished, sgs.TrickCardCanceling, sgs.TrickEffect, sgs.ChoiceMade, sgs.StageChange, 
	sgs.FetchDrawPileCard, sgs.ActionedReset, sgs.Debut, sgs.TurnBroken, sgs.NumOfEvents]]}, 
	view_as_skill = tonglingVS , 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		-- local ganning = room:findPlayerBySkillName(self:objectName())
		-- if ganning:isLord() then
		-- 	room:detachSkillFromPlayer(ganning, "tongling")
		if player:isLord() then
			room:detachSkillFromPlayer(player, "tongling")
		--[[else
			room:askForUseCard(ganning, "@@tonglingCard", "@tongling-card")]]
		end
	end, 
	-- can_trigger = function(self, target)
	-- 	return target and (target:objectName() == sgs.Self:objectName() or target:objectName() ~= sgs.Self:objectName())and sgs.Self:getMark("@bell") >= 1
	-- end
}
	--[[events = {sgs.GameStart}, 
	view_as_skill = tonglingVS , 
	on_trigger = function(self, event, player, data)
		if player:isLord() then
			player:getRoom():detachSkillFromPlayer(player, "tongling")
		else
			player:gainMark("@bell", 1)
		end
	end
}]]

Dragon_tongling = sgs.CreateTriggerSkill{
	name = "Dragon_tongling" , 
	events = {sgs.GameStart}, 
	frequency = sgs.Skill_Compulsory , 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if not player:isLord() then
				room:setPlayerProperty(source, "role", sgs.QVariant(source:getRole()))
				local log = sgs.LogMessage()
					log.type = "#SkillEffect_Role"
					log.from = source
					log.arg = self:objectName()
					log.arg2 = source:getRole()
				room:sendLog(log)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))			--锁定技
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				--player:getRole()
				--table.insert(player, "role")			--不会用
			elseif player:isLord() then
			room:detachSkillFromPlayer(player, "Dragon_tongling")
			end
		end
		return false
	end
}
-- 铜铃 由 Super飞虎将军 修改 （任何时候实现不能，保留觉醒版本，可以替换使用）
Dragon_ganning:addSkill(tongling)

sgs.LoadTranslationTable{
	["Dragon_ganning"] = "龙版甘宁", 
	["designer:Dragon_ganning"] = "官方|Lua：Super飞虎将军", 
	["illustrator:Dragon_ganning"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_tongling"] = "铜铃", 
	[":Dragon_tongling"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，若你不为主公，你增加1点体力上限，回复1点体力。", 
	["tongling"] = "铜铃", 
	[":tongling"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，若你不为主公，你可以亮出身份，然后你增加1点体力上限并回复1点体力。", 
	["tonglingCard"] = "铜铃", 
	["#SkillEffect_Role"] = "%from 由于“%arg”的效果，亮出了身份 【%arg2】", 
}

Dragon_lvmeng = sgs.General(extension, "Dragon_lvmeng", "wu", "4")

Dragon_kejiLimit = sgs.CreateMaxCardsSkill{
	name = "#Dragon_kejiLimit",
	extra_func = function(self, target)
		if target:getMark("Dragon_keji") > 0 and target:hasSkill("Dragon_keji") then
			return 998
		else
			return 0
		end
	end
}
Dragon_keji = sgs.CreateTriggerSkill{
	name = "Dragon_keji" ,
	frequency = sgs.Skill_Frequent ,
--	global = true ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local can_trigger = true
			if player:hasFlag("Dragon_kejiSlashInPlayPhase") then
				can_trigger = false
				player:setFlags("-Dragon_kejiSlashInPlayPhase")
			end
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard and player:isAlive() and player:hasSkill(self:objectName()) then
				if can_trigger and player:askForSkillInvoke(self:objectName()) then
					player:getRoom():setPlayerMark(player, self:objectName(), 1)
				end
			elseif change.to == sgs.Player_Finish and player:isAlive() and player:hasSkill(self:objectName()) then
				player:getRoom():setPlayerMark(player, self:objectName(), 0)
			end
		else
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card			 
				end
				if card:isKindOf("Slash") then
					player:setFlags("Dragon_kejiSlashInPlayPhase")
				end
			end
		end
		return false
	end
}

Dragon_lvmeng:addSkill(Dragon_keji)
Dragon_lvmeng:addSkill(Dragon_kejiLimit)
extension:insertRelatedSkills("Dragon_keji", "#Dragon_kejiLimit")

sgs.LoadTranslationTable{
	["Dragon_lvmeng"] = "龙版吕蒙", 
	["illustrator:Dragon_lvmeng"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_keji"] = "克己", 
	[":Dragon_keji"] = "若你未于出牌阶段使用或打出过【杀】，你的手牌上限无限。", 
	["Dragon_kejiLimit"] = "克己", 
}

Dragon_huanggai = sgs.General(extension, "Dragon_huanggai", "wu", "4")

Dragon_kurouCard = sgs.CreateSkillCard{
	name = "Dragon_kurouCard", 
	target_fixed = true, 
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		room:broadcastSkillInvoke("kurou")
		if source:isAlive() then
			room:drawCards(source, 2, "Dragon_kurou")
		end
	end
}
Dragon_kurou = sgs.CreateZeroCardViewAsSkill{
	name = "Dragon_kurou", 
	view_as = function()
		return Dragon_kurouCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getHp() > 1
	end
}

Dragon_huanggai:addSkill(Dragon_kurou)

sgs.LoadTranslationTable{
	["Dragon_huanggai"] = "龙版黄盖", 
	["designer:Dragon_huanggai"] = "官方|Lua：Super飞虎将军", 
	["illustrator:Dragon_huanggai"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_kurou"] = "苦肉", 
	["dragon_kurou"] = "苦肉", 
	[":Dragon_kurou"] = "出牌阶段，若你的体力值大于1，你可以失去1点体力，摸两张牌。", 
}

Dragon_zhouyu = sgs.General(extension, "Dragon_zhouyu", "wu", "3")

--[[Dragon_change_weaponCard = sgs.CreateSkillCard{
	name = "Dragon_change_weaponCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "Dragon_collateral")
		local card_ids = source:getPile("Dragon_collateral")
		room:fillAG(card_ids)
		local card_id = room:askForAG(source, card_ids, true, "Dragon_collateral")
		if card_id ~= -1 then
		    room:setPlayerFlag(source, "collateral_moving")
		    source:addToPile("Dragon_collateral", source:getWeapon())
			room:setPlayerFlag(source, "-collateral_moving")
			room:moveCardTo(sgs.Sanguosha:getCard(card_id), source, source, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), "Dragon_collateral", ""))
		end
		room:clearAG()
	end
}
Dragon_change_weaponVS = sgs.CreateZeroCardViewAsSkill{
	name = "Dragon_change_weapon",
	view_as = function()
		return Dragon_change_weaponCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:getPile("Dragon_collateral"):isEmpty()
	end
}]]
--备用接口，针对expand_pile不可用的版本
Dragon_change_weaponCard = sgs.CreateSkillCard{
	name = "Dragon_change_weaponCard", 
    target_fixed = true,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then
			room:cardEffect(self, source, source)
		else
			for _, t in ipairs(targets) do
				room:cardEffect(self, source, t)
			end
		end
	end,
    on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:notifySkillInvoked(effect.from, "Dragon_collateral")
		if effect.from:getWeapon() then
			room:setPlayerFlag(effect.from, "collateral_moving")
			effect.from:addToPile("Dragon_collateral", effect.to:getWeapon())
			room:setPlayerFlag(effect.from, "-collateral_moving")
		end
		room:moveCardTo(sgs.Sanguosha:getCard(self:getEffectiveId()), effect.from, effect.to, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, effect.from:objectName(), "Dragon_collateral", ""))
	end
}
Dragon_change_weaponVS = sgs.CreateOneCardViewAsSkill{
	name = "Dragon_change_weapon", 
	relate_to_place = "head",
	filter_pattern = ".|.|.|Dragon_collateral",
	expand_pile = "Dragon_collateral",
	view_as = function(self, ocard)
		local card =  Dragon_change_weaponCard:clone()
			card:addSubcard(ocard)
		card:setSkillName(self:objectName())
		return card
	end,
}
Dragon_change_weapon = sgs.CreateTriggerSkill{
	name = "Dragon_change_weapon&", 
	events = {sgs.BeforeCardsMove, sgs.EventPhaseChanging}, 
	view_as_skill = Dragon_change_weaponVS, 
	global = true,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local source = nil
		for _, p in sgs.qlist(room:getAllPlayers()) do
		    if p:hasFlag("Dragon_collateral") then
			    source = p
			end 
		end
		if not source then return end
		local card_ids1 = room:getTag("collateralSource"):toIntList()
		if card_ids1:isEmpty() then
		    return
		end	
		if event == sgs.BeforeCardsMove then
	        local move = data:toMoveOneTime()
			if source:hasFlag("collateral_moving") then
			    return true
			end
		    if move.from and source:objectName() == move.from:objectName() and source:hasFlag("Dragon_collateral") and move.from_places:contains(sgs.Player_PlaceEquip) and move.to_place ~= sgs.Player_PlaceSpecial then
				local card_id = nil
		        for _, id in sgs.qlist(move.card_ids) do
				    if card_ids1:contains(id) and sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
					    card_id = id
			            move.card_ids:removeOne(id)
			        end
			    end
				if card_id and move.reason.m_skillName ~= "Dragon_collateral" then
			        source:addToPile("Dragon_collateral", card_id)
					for _, id in sgs.qlist(source:getPile("Dragon_collateral")) do
					    if not card_ids1:contains(id) then
					        room:moveCardTo(sgs.Sanguosha:getCard(id), source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "Dragon_collateral", ""), true)
					    end
					end	
				end
				room:notifySkillInvoked(source, "Dragon_collateral")
				data:setValue(move)
			end
		elseif event == sgs.CardsMoveOneTime then	
		    if source:hasFlag("collateral_moving") then
			    return true
			end
		end
		if event ==  sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
			    room:setPlayerFlag(source, "-Dragon_collateral")
				if source:hasSkill("Dragon_change_weapon") then
			        room:detachSkillFromPlayer(source, "Dragon_change_weapon")	
			    end
			    for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			        local card_ids2 = room:getTag("collateralTarget" .. p:objectName()):toIntList()
					if not card_ids2:isEmpty() then
					    for _, id in sgs.qlist(card_ids1) do
			                if card_ids2:contains(id) and room:getCardOwner(id):objectName() == source:objectName() then
						        local to, place = nil, sgs.Player_DiscardPile
						        if not p:getWeapon() then
							        to, place = p, sgs.Player_PlaceEquip
							    end
			                    room:moveCardTo(sgs.Sanguosha:getCard(id), source, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Dragon_collateral", ""), true)
								room:getThread():delay()
			                end
						end	 
			        end
			    end
				local card_ids = source:getPile("Dragon_collateral")
				if not card_ids:isEmpty() then
				    for _, id in sgs.qlist(card_ids) do
						if not card_ids1:contains(id) then
						    local to, place = nil, sgs.Player_DiscardPile
						    if not source:getWeapon() then
							    to, place = source, sgs.Player_PlaceEquip
							end
							room:moveCardTo(sgs.Sanguosha:getCard(id), source, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Dragon_collateral", ""), true)
						else	
							if room:getCardOwner(id):objectName() == source:objectName() then
							    room:moveCardTo(sgs.Sanguosha:getCard(id), source, nil, sgs.Player_DiscardPile, 
								    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Dragon_collateral", ""), true)
							end
						end
				    end
				end
				room:setTag("collateralSource", sgs.QVariant())
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do 
				    room:setTag("collateralTarget" .. p:objectName(), sgs.QVariant()) 
				end
			end
		end
	    return false
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_change_weapon") then skills:append(Dragon_change_weapon) end
sgs.Sanguosha:addSkills(skills)

Dragon_jiedaoCard = sgs.CreateSkillCard{
	name = "Dragon_jiedaoCard", 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:getWeapon() and to_select:objectName() ~= sgs.Self:objectName() 
	end,
	--[[available = function(self, player)
	    local canUse = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:getWeapon() then
                canUse = true
                break
			end	
        end
        return canUse
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
		local weapon1 = effect.from:getWeapon()
		local weapon2 = effect.to:getWeapon()
		if weapon1 then
		    effect.from:addToPile(self:objectName(), weapon1)
			if not effect.from:hasSkill("Dragon_change_weapon") then
			    room:attachSkillToPlayer(effect.from, "Dragon_change_weapon")	
			end
		end
		-- room:setCardFlag(weapon2, "collateral")
		local card_ids1 = room:getTag("collateralSource"):toIntList()
		local card_ids2 = room:getTag("collateralTarget" .. effect.to:objectName()):toIntList()
		if card_ids1:contains(weapon2:getId()) then return false end
		card_ids1:append(weapon2:getId())
		card_ids2:append(weapon2:getId())
		local card_ids_data1, card_ids_data2 = sgs.QVariant(), sgs.QVariant()
		card_ids_data1:setValue(card_ids1)
		card_ids_data2:setValue(card_ids2)
		room:setTag("collateralSource", card_ids_data1)
		room:setTag("collateralTarget" .. effect.to:objectName(), card_ids_data2)
		room:setPlayerFlag(effect.from, self:objectName())
        room:moveCardTo(weapon2, effect.to, effect.from, sgs.Player_PlaceEquip, 
		    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.to:objectName(), "dragon_collateral", ""), true)
    end]]
	available = function(self, player)
	    local canUse = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:getWeapon() then
                canUse = true
                break
			end	
        end
        return canUse
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1] 
        local room = source:getRoom()
		local weapon1 = source:getWeapon()
		local weapon2 = target:getWeapon()
		if weapon1 then
		    source:addToPile("Dragon_collateral", weapon1)
			if not source:hasSkill("Dragon_change_weapon") then
			    room:attachSkillToPlayer(source, "Dragon_change_weapon")	
			end
		end
		-- room:setCardFlag(weapon2, "collateral")
		local card_ids1 = room:getTag("collateralSource"):toIntList()
		local card_ids2 = room:getTag("collateralTarget" .. target:objectName()):toIntList()
		if card_ids1:contains(weapon2:getId()) then return false end
		card_ids1:append(weapon2:getId())
		card_ids2:append(weapon2:getId())
		local card_ids_data1, card_ids_data2 = sgs.QVariant(), sgs.QVariant()
		card_ids_data1:setValue(card_ids1)
		card_ids_data2:setValue(card_ids2)
		room:setTag("collateralSource", card_ids_data1)
		room:setTag("collateralTarget" .. target:objectName(), card_ids_data2)
		room:setPlayerFlag(source, "Dragon_collateral")
        room:moveCardTo(weapon2, target, source, sgs.Player_PlaceEquip, 
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, target:objectName(), "Dragon_collateral", ""), true)
	end
}

Dragon_jiedao = sgs.CreateViewAsSkill{
	name = "Dragon_jiedao", 
	n = 0, 
	view_as = function() 
		return Dragon_jiedaoCard:clone() 
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Dragon_jiedaoCard") 
	end
}
-- 借刀 由 西域伊浪 编写
Dragon_zhouyu:addSkill("nosyingzi")
Dragon_zhouyu:addSkill(Dragon_jiedao)
--Dragon_zhouyu:addSkill(Dragon_jiedaoBack)
extension:insertRelatedSkills("Dragon_jiedao", "#Dragon_jiedaoBack")

sgs.LoadTranslationTable{
	["Dragon_zhouyu"] = "龙版周瑜", 
	["designer:Dragon_zhouyu"] = "官方|Lua：红月⑦ & 西域伊浪", 
	["illustrator:Dragon_zhouyu"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_jiedao"] = "借刀", 
	[":Dragon_jiedao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名装备区有武器牌的其他角色，将你装备区里的武器牌置于你的武将牌上，并将该角色装备区里的武器牌置入你的装备区，若如此做，本回合结束时，若该角色装备区没有武器牌，将此武器牌置入其装备区，然后若你的装备区没有武器牌，将你武将牌上的牌置入装备区，否则分别置入弃牌堆。", 
	["Dragon_change_weapon"] = "帷幄",
	[":Dragon_change_weapon"] = "出牌阶段，你可以将装备区里的武器牌和武将牌上的武器牌交换。",
}

Dragon_daqiao = sgs.General(extension, "Dragon_daqiao", "wu", "3", false)

Dragon_guose = sgs.CreateOneCardViewAsSkill{
	name = "Dragon_guose", 
	response_or_use = true, 
	filter_pattern = ".|diamond", 
	view_as = function(self, ocard)
		local indulgence = sgs.Sanguosha:cloneCard("Dragon_indulgence", ocard:getSuit(), ocard:getNumber())
		indulgence:addSubcard(ocard:getId())
		indulgence:setSkillName(self:objectName())
		return indulgence
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@nosguose" or pattern == "@@guose"
	end, 
}

--Dragon_daqiao:addSkill("nosguose")
Dragon_daqiao:addSkill(Dragon_guose)
Dragon_daqiao:addSkill("liuli")

sgs.LoadTranslationTable{
	["Dragon_daqiao"] = "龙版大乔", 
	["designer:Dragon_daqiao"] = "官方|Lua：myetyet", 
	["illustrator:Dragon_daqiao"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_guose"] = "国色", 
	[":Dragon_guose"] = "出牌阶段，你可以将一张方块牌当【乐不思蜀】使用。", 
}

Dragon_luxun = sgs.General(extension, "Dragon_luxun", "wu", "3")

Dragon_luxun:addSkill("nosqianxun")
Dragon_luxun:addSkill("noslianying")

sgs.LoadTranslationTable{
	["Dragon_luxun"] = "龙版陆逊", 
	["illustrator:Dragon_luxun"] = "KayaK|Card：赵云涯角七无懈", 
}

Dragon_caocao = sgs.General(extension, "Dragon_caocao$", "wei", "4")

Dragon_caocao:addSkill("nosjianxiong")
Dragon_caocao:addSkill("hujia")

sgs.LoadTranslationTable{
	["Dragon_caocao"] = "龙版曹操", 
}

Dragon_simayi = sgs.General(extension, "Dragon_simayi", "wei", "3")

Dragon_fankui = sgs.CreateTriggerSkill{
	frequency = sgs.Skill_NotFrequent, 
	name = "Dragon_fankui", 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local from = data:toDamage().from
		local data = sgs.QVariant()
		data:setValue(from)
		if(from and (not from:isKongcheng()) and room:askForSkillInvoke(player, self:objectName(), data)) then
			room:broadcastSkillInvoke("fankui")
			local card_id = room:askForCardChosen(player, from, "h", self:objectName())
			room:obtainCard(player, card_id)
		end
	end
}
-- 反馈 为 JOOOOKER 编写
Dragon_simayi:addSkill("nosguicai")
Dragon_simayi:addSkill(Dragon_fankui)

sgs.LoadTranslationTable{
	["Dragon_simayi"] = "龙版司马懿", 
	["designer:Dragon_simayi"] = "官方|Lua：霓炎", 
	["illustrator:Dragon_simayi"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_fankui"] = "反馈", 
	[":Dragon_fankui"] = "每当你受到伤害后，你可以获得伤害来源的一张手牌。", 
}

Dragon_xiahoudun = sgs.General(extension, "Dragon_xiahoudun", "wei", "4")

Dragon_ganglie = sgs.CreateTriggerSkill{
	name = "Dragon_ganglie", 
	events = {sgs.Damaged}, 
	on_trigger=function(self, event, player, data)
		local room = player:getRoom()
		local from = data:toDamage().from
		if(from and from:isAlive() and room:askForSkillInvoke(player, self:objectName(), data)) then
			room:broadcastSkillInvoke("ganglie")
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = from
			room:judge(judge)
			if(judge:isGood()) then
				if from:getHandcardNum() < 2 then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				elseif(not room:askForDiscard(from, self:objectName(), 2, 2, true)) then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				end
			end
		end
	end
}

Dragon_xiahoudun:addSkill(Dragon_ganglie)

sgs.LoadTranslationTable{
	["Dragon_xiahoudun"] = "龙版夏侯惇", 
	["designer:Dragon_xiahoudun"] = "官方|Lua：Super飞虎将军", 
	["illustrator:Dragon_xiahoudun"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_ganglie"] = "刚烈", 
	[":Dragon_ganglie"] = "每当你受到伤害后，你可以令伤害来源进行一次判定，若结果为<font color=\"black\"><b>黑色</b></font>，该角色弃置两张手牌，或受到你对其造成一点伤害。", 	
}

Dragon_zhangliao = sgs.General(extension, "Dragon_zhangliao", "wei", "4")

Dragon_zhangliao:addSkill("nostuxi")

sgs.LoadTranslationTable{
	["Dragon_zhangliao"] = "龙版张辽", 
	["designer:Dragon_zhangliao"] = "官方|Lua：myetyet", 
	["illustrator:Dragon_zhangliao"] = "KayaK|Card：赵云涯角七无懈", 
}

Dragon_xuchu = sgs.General(extension, "Dragon_xuchu", "wei", "4")

Dragon_luoyi=sgs.CreateTriggerSkill{
	name = "Dragon_luoyi", 
	events = {sgs.Predamage}, 
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if(event == sgs.Predamage and not player:getWeapon() and player:hasSkill("Dragon_luoyi") and card and card:inherits("Slash")) then
			damage.damage = damage.damage + 1
			data:setValue(damage)
			return false
		end
	end, 
}
-- 裸衣 由 恨伯约 编写
Dragon_xuchu:addSkill(Dragon_luoyi)

sgs.LoadTranslationTable{
	["Dragon_xuchu"] = "龙版许褚", 
	["designer:Dragon_xuchu"] = "官方|Lua：恨伯约", 
	["illustrator:Dragon_xuchu"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_luoyi"] = "裸衣", 
	[":Dragon_luoyi"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用的【杀】造成伤害时，若你的装备区没有武器牌，此伤害+1。", 
}

Dragon_guojia = sgs.General(extension, "Dragon_guojia", "wei", "3")

Dragon_guojia:addSkill("tiandu")
Dragon_guojia:addSkill("nosyiji")

sgs.LoadTranslationTable{
	["Dragon_guojia"] = "龙版郭嘉", 
	["illustrator:Dragon_guojia"] = "KayaK|Card：赵云涯角七无懈", 
}

Dragon_zhenji = sgs.General(extension, "Dragon_zhenji", "wei", "3", false)

Dragon_luoshen = sgs.CreateTriggerSkill{
	name = "Dragon_luoshen", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Judge then
				while player:askForSkillInvoke(self:objectName()) do
					room:broadcastSkillInvoke("luoshen")
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
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:obtainCard(card)
					return true
				end
			end
		end
		return false
	end
}

Dragon_qingguo = sgs.CreateViewAsSkill{
	name = "Dragon_qingguo", 
	n = 1, 
	response_or_use = true, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end, 
	enabled_at_play = function()
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

Dragon_zhenji:addSkill(Dragon_luoshen)
Dragon_zhenji:addSkill(Dragon_qingguo)

sgs.LoadTranslationTable{
	["Dragon_zhenji"] = "龙版甄姬", 
	["designer:Dragon_zhenji"] = "官方|Lua：红月⑦", 
	["illustrator:Dragon_zhenji"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_luoshen"] = "洛神", 
	[":Dragon_luoshen"] = "判定阶段结束时，你可以进行一次判定，若结果为<font color=\"black\"><b>黑色</b></font>，你获得此牌，你可以重复此流程，直到出现<font color=\"red\"><b>红色</b></font>的判定结果为止。", 
	["Dragon_qingguo"] = "倾国", 
	[":Dragon_qingguo"] = "你可以将一张手牌当【闪】使用或打出。", 
}

Dragon_huatuo = sgs.General(extension, "Dragon_huatuo", "qun", "3")

Dragon_qingnangCard = sgs.CreateSkillCard{
	name = "Dragon_qingnangCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(source, recover)
		room:broadcastSkillInvoke("qingnang")
	end
}

Dragon_qingnang = sgs.CreateOneCardViewAsSkill{
	name = "Dragon_qingnang", 
	filter_pattern = ".", 
	view_as = function(self, ocard)
		local card = Dragon_qingnangCard:clone()
		card:addSubcard(ocard)
		return card
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and player:isWounded()
	end
}
-- 青囊 由 786852516 编写
Dragon_jijiu = sgs.CreateTriggerSkill{
	name = "Dragon_jijiu", 
	events = {sgs.DamageInflicted}, 
	can_trigger = function(self, target)
		return target ~= nil
	end, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not player:isAlive() then return false end
		for _, me in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			while damage.damage > 0 do
				if (not me:canDiscard(me, "h")) then break end
				local ai_data = sgs.QVariant()
				ai_data:setValue(player)
				if not room:askForCard(me, ".|red|.|hand", "@Dragon_jijiu:"..player:getGeneralName(), data, self:objectName()) then break end
				damage.damage = damage.damage - 1 
				data:setValue(damage)
				room:broadcastSkillInvoke("jijiu")
				local msg = sgs.LogMessage()
				msg.type = "$Dragon_Jijiu"
				msg.from = me
				local tos = sgs.SPlayerList()
				tos:append(player)
				msg.to = tos
				room:sendLog(msg)
				if damage.damage <= 0 then return true end
			end
		end
	end, 
}
-- 急救 由 786852516 编写
Dragon_huatuo:addSkill(Dragon_qingnang)
Dragon_huatuo:addSkill(Dragon_jijiu)

sgs.LoadTranslationTable{
	["Dragon_huatuo"] = "龙版华佗", 
	["designer:Dragon_huatuo"] = "官方|Lua：红月⑦", 
	["illustrator:Dragon_huatuo"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_qingnang"] = "青囊", 
	[":Dragon_qingnang"] = "出牌阶段，若你已受伤，你可以弃置一张牌回复1点体力。", 
	["Dragon_jijiu"] = "急救", 
	[":Dragon_jijiu"] = "每当一名角色受到1点伤害时，你可以弃置一张<font color=\"red\"><b>红色</b></font>手牌抵消此次伤害。", 
	["@Dragon_jijiu"] = "%src 受到1点伤害，是否弃置一张<font color=\"red\">红色</font>手牌发动“急救”，令此伤害-1？", 
	["$Dragon_Jijiu"] = "%from 发动的“急救”抵消了 %to 受到的1点伤害",
}

Dragon_lvbu = sgs.General(extension, "Dragon_lvbu", "qun", "4")

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
Dragon_wushuang = sgs.CreateTriggerSkill{
	name = "Dragon_wushuang", 
	frequency = sgs.Skill_Compulsory , 
	events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.CardFinished}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local effect = data:toCardEffect()
		if event == sgs.TargetConfirmed then
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardEffected then
			if effect.card:isKindOf("TrickCard") and (effect.card:isKindOf("AOE")) and (effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName())) then
				if not room:askForDiscard(effect.to, self:objectName(), 1, 1, true) then
					effect.to:setFlags("Dragon_wushuang_")
				end
				if effect.to:hasFlag("Dragon_wushuang_") then
					room:setPlayerMark(effect.to, "&Dragon_wushuang+to+#"..effect.from:objectName(), 1)
					room:setPlayerCardLimitation(effect.to, "response", ".|.|.|hand", false)
				end
			end
		elseif event == sgs.CardFinished then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				if use.card:isKindOf("AOE") then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						p:setFlags("-Dragon_wushuang_")
						room:setPlayerMark(p, "&Dragon_wushuang+to+#"..player:objectName(), 0)
						room:removePlayerCardLimitation(p, "response", ".|.|.|hand$0")
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
-- 无双 由 786852516 编写
Dragon_lvbu:addSkill(Dragon_wushuang)

sgs.LoadTranslationTable{
	["Dragon_lvbu"] = "龙版吕布", 
	["designer:Dragon_lvbu"] = "官方|Lua：红月⑦", 
	["illustrator:Dragon_lvbu"] = "KayaK|Card：赵云涯角七无懈", 
	["Dragon_wushuang"] = "无双", 
	[":Dragon_wushuang"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用的【杀】指定目标后，目标角色需连续使用两张【闪】；当你使用的范围锦囊生效后，目标角色需选择一项：弃置一张手牌；或不能打出手牌直到此牌结算完毕。", 
}

Dragon_diaochan = sgs.General(extension, "Dragon_diaochan", "qun", "3", false)

Dragon_diaochan:addSkill("lijian")
Dragon_diaochan:addSkill("biyue")

sgs.LoadTranslationTable{
	["Dragon_diaochan"] = "龙版貂蝉", 
	["illustrator:Dragon_diaochan"] = "KayaK|Card：赵云涯角七无懈", 
}

Dragon_sunshangxiang = sgs.General(extension, "Dragon_sunshangxiang", "wu+shu", "4", false)

Dragon_qiankun = sgs.CreateTriggerSkill{ 
	name = "Dragon_qiankun", 
	events = {sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.Death}, 
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:getLord():getKingdom() == "shu" then
			room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
		end
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player, "Equips_of_Others_Nullified_to_You", 1)
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) or event == sgs.Death then
			room:setPlayerMark(player, "Equips_of_Others_Nullified_to_You", 0)
		end
	end, 
}

Dragon_qiankunSlash = sgs.CreateProhibitSkill{ 
	name = "#Dragon_qiankunSlash", 
	is_prohibited = function(self, from, to, card) 
		return to:hasSkill("Dragon_qiankun") and card:isKindOf("Slash") and (from:distanceTo(to) > 1 --[[and (card:getSkillName() == "" ]]or card:getSkillName() == "spear" or card:getSkillName() == "fan" or card:getSkillName() == "halberd")
	end
}

Dragon_qiankunWeapon = sgs.CreateTriggerSkill{
	name = "#Dragon_qiankunWeapon", 
	events = {sgs.CardUsed, sgs.CardFinished, sgs.EventLoseSkill, sgs.Death}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom() 
		 local sunshangxiang = room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardUsed then 
			local use = data:toCardUse() 
			if player:isAlive() --[[and player:hasSkill("Dragon_qiankun")]] then 
				if use.from:objectName() ~= player:objectName() then 
					if use.card:isKindOf("Slash") then 
						--match(use.from:getWeapon(), "spear")
						use.from:setWeapon("spear")
					end
				end
			end
		else 
			if event == sgs.EventLoseSkill then 
				if data:toString() ~= "Dragon_qiankun" then return false end
			end
			if event == sgs.Death then 
				if data:toDeath().who:objectName() ~= player:objectName() or (not player:hasSkill("Dragon_qiankun")) then return false end
			end
			if event == sgs.CardFinished then 
				local use = data:toCardUse() 
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:hasSkill("Dragon_qiankun") then else return false end
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				while p:getMark("Dragon_qiankun_Weapon") > 0 do
					room:removePlayerMark(p, "Weapon_Nullified") 
					room:removePlayerMark(p, "Dragon_qiankun_Weapon") 
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		return target 
	end, 
}

Dragon_qiankunArmor = sgs.CreateTriggerSkill{ 
	name = "#Dragon_qiankunArmor", 
	events = {sgs.TargetConfirmed, sgs.CardFinished, sgs.EventLoseSkill, sgs.Death}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom() 
		if event == sgs.TargetConfirmed then 
			local use = data:toCardUse() 
			if player:isAlive() and player:hasSkill("Dragon_qiankun") then 
				if use.from:objectName() == player:objectName() then 
					if use.card:isKindOf("Slash") or use.card:isNDTrick() then 
						for _, to in sgs.qlist(use.to) do
							room:addPlayerMark(to, "Armor_Nullified") 
							room:addPlayerMark(to, "Dragon_qiankun_armor") 
						end
					end
				end
			end
		else 
			if event == sgs.EventLoseSkill then 
				if data:toString() ~= "Dragon_qiankun" then return false end
			end
			if event == sgs.Death then 
				if data:toDeath().who:objectName() ~= player:objectName() or (not player:hasSkill("Dragon_qiankun")) then return false end
			end
			if event == sgs.CardFinished then 
				local use = data:toCardUse() 
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:hasSkill("Dragon_qiankun") then else return false end
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				while p:getMark("Dragon_qiankun_armor") > 0 do
					room:removePlayerMark(p, "Armor_Nullified") 
					room:removePlayerMark(p, "Dragon_qiankun_armor") 
				end
			end
		end
	end--[[, 
	can_trigger = function(self, target) 
		return target 
	end, ]]
}
-- 乾坤 由 786852516 编写
Dragon_sunshangxiang:addSkill(Dragon_qiankun)
Dragon_sunshangxiang:addSkill(Dragon_qiankunSlash)
Dragon_sunshangxiang:addSkill(Dragon_qiankunWeapon)
Dragon_sunshangxiang:addSkill(Dragon_qiankunArmor)
extension:insertRelatedSkills("Dragon_qiankun", "#Dragon_qiankunSlash")
extension:insertRelatedSkills("Dragon_qiankun", "#Dragon_qiankunArmor")

sgs.LoadTranslationTable{
	["Dragon_sunshangxiang"] = "龙版孙尚香", 
	["designer:Dragon_sunshangxiang"] = "官方|Lua：红月⑦", 
	["Dragon_qiankun"] = "乾坤", 
	[":Dragon_qiankun"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时， 若主公为蜀势力，改变你的势力为蜀；其他角色的装备牌对你无效；你不能成为与你距离大于1的角色的【杀】的目标；你使用【杀】或非延时类锦囊牌指定其他角色为目标后，无视其防具；你计算距离时不受坐骑牌的影响。", 
}

extensionC = sgs.Package("DragonCardPack", sgs.Package_CardPack)
--™&©2008游卡桌游 三国杀 总设计师：KayaK MOD汇总：Super飞虎将军 主要编写人：Super飞虎将军 LUA指导：克己庸肆 慕霜霖 youko1316 czb0598 西域伊浪
sgs.LoadTranslationTable{
	["DragonCardPack"] = "龙版游戏牌", 
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "slash" and card:getSuit() == sgs.Card_Club) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 7)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 8)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 8)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 9)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 9)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 0, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 2)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 3)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 4)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 5)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 6)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 7)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 8)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 8)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 9)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 9)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 11)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 1, 11)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 2, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 2, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 2, 11)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 6)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 7)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 8)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 9)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 10)
			slash:setParent(extensionC)
			local slash = sgs.Sanguosha:cloneCard(card:objectName(), 3, 13)
			slash:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "jink" and card:getSuit() == sgs.Card_Heart) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 2, 2)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 2, 2)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 2, 13)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 2)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 2)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 3)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 4)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 5)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 6)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 7)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 8)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 9)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 10)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 11)
			jink:setParent(extensionC)
			local jink = sgs.Sanguosha:cloneCard(card:objectName(), 3, 11)
			jink:setParent(extensionC)
		end
	end
end

Dragon_peach = sgs.CreateBasicCard{
	name = "Dragon_peach", 
	class_name = "DragonPeach", 
	subtype = "recover_card", 
	can_recast = false, 
	suit = 2, 
	number = 3, 
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return true
		end
		return #targets == 0 and to_select:isWounded()
	end, 
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return #targets == 0
		else
			return #targets > 0
		end
	end, 
	available = function(self, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return true
		end
		local can = false
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isWounded() and not player:isProhibited(p, self) then
				can = true
				break
			end
		end
		if player:isWounded() and not player:isProhibited(player, self) then
			can = true
		end
		return can
	end, 
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end, 
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return true
		end
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end, 
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:setEmotion(effect.from, "peach")
		if not (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			room:recover(effect.to, sgs.RecoverStruct(effect.from, self))
		end
	end
}
Dragon_peach:setParent(extensionC)
--西域伊浪

Dragon_Peach = sgs.CreateTriggerSkill{
	name = "Dragon_Peach", 
	global = true,
	events = {sgs.DamageInflicted}, 
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.damage < player:getHp() or not player:isAlive() then return false end
		while damage.damage >= player:getHp() do
			if (not room:askForUseCard(player, "DragonPeach", "@Dragon_Peach:"..player:getGeneralName(), -1)) then break end
			damage.damage = damage.damage - 1
			data:setValue(damage)
			local msg = sgs.LogMessage()
			msg.type = "$Dragon_Peach"
			msg.from = player
			local tos = sgs.SPlayerList()
			tos:append(player)
			msg.to = tos
			room:sendLog(msg)
			if damage.damage <= 0 then return true end
		end
	end,
	priority = -1,
}
local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_Peach") then skill_list:append(Dragon_Peach)end
sgs.Sanguosha:addSkills(skill_list)

local DragonPeach = Dragon_peach:clone(2, 4)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(2, 6)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(2, 7)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(2, 8)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(2, 9)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(2, 12)
DragonPeach:setParent(extensionC)
local DragonPeach = Dragon_peach:clone(3, 12)
DragonPeach:setParent(extensionC)

sgs.LoadTranslationTable{
["Dragon_peach"] = "桃", 
[":Dragon_peach"] = "基本牌<br /><b>时机</b>：出牌阶段/你因受到伤害而即将进入濒死状态时<br /><b>目标</b>：已受伤的一名角色/你<br /><b>效果</b>：目标角色回复1点体力/抵消目标角色受到的最后1点伤害。", 
["@Dragon_Peach"] = "%src 受到伤害即将进入濒死状态，是否使用一张龙版【桃】，令此伤害-1？", 
["$Dragon_Peach"] = "%from 使用的【桃】抵消了 %to 受到的1点伤害",
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "crossbow" and card:getSuit() == sgs.Card_Club) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local crossbow = sgs.Sanguosha:cloneCard(card:objectName(), 1, 1)
			crossbow:setParent(extensionC)
			local crossbow = sgs.Sanguosha:cloneCard(card:objectName(), 3, 1)
			crossbow:setParent(extensionC)
		end
	end
end

Dragon_double_sword = sgs.CreateWeapon{
	name = "Dragon_double_sword", 
	class_name = "Dragon_DoubleSword", 
	suit = sgs.Card_Spade, 
	number = 2, 
	range = 2, 
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Dragon_double_swordSkill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end, 
	on_uninstall = function(self, player)
	end, 
}
Dragon_double_sword:clone():setParent(extensionC)

Dragon_double_swordSkill = sgs.CreateTriggerSkill{
	name = "Dragon_double_swordSkill", 
	events = {sgs.CardEffected}, 
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, TriggerEvent, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local draw_card = false
		local card
		if not effect.card:isKindOf("Slash") then return end
		if effect.from:getGender() == effect.to:getGender() or effect.from:getGender() == sgs.General_SexLess or effect.to:getGender() == sgs.General_SexLess then return end
		if effect.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			if effect.from:askForSkillInvoke(self:objectName()) then
				local log = sgs.LogMessage()
				log.type = "#InvokeSkill"
				log.from = effect.from
				log.arg = self:objectName()
				room:sendLog(log)
				effect.to:getRoom():setEmotion(effect.from, "weapon/double_sword");
				if not effect.to:canDiscard(effect.to, "h") then
					draw_card = true
				else
					card = room:askForCard(effect.to, ".", "double-sword-card:"..effect.from:objectName(), data)
					if not card then draw_card = true end
				end
				if draw_card then
					effect.from:drawCards(1, self:objectName())
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		return target and target:getWeapon() and target:getWeapon():objectName() == "Dragon_double_sword" and target:getMark("Equips_Nullified_to_Yourself") == 0
	end, 
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_double_swordSkill") then skills:append(Dragon_double_swordSkill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
["Dragon_double_sword"] = "雌雄双股剑", 
[":Dragon_double_sword"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：每当你的【杀】即将生效时，<b>若该角色为异性角色，</b>你可以令其选择一项：弃置一张手牌，或令你摸一张牌。", 
["Dragon_double_swordSkill"] = "雌雄双股剑", 
["Dragon_DoubleSword"] = "雌雄双股剑", 
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "qinggang_sword" and card:getSuit() == sgs.Card_Spade) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local qinggang_sword = sgs.Sanguosha:cloneCard(card:objectName(), 0, 6)
			qinggang_sword:setParent(extensionC)
		end
	end
end

Dragon_blade = sgs.CreateWeapon{
	name = "Dragon_blade", 
	class_name = "Dragon_Blade", 
	suit = sgs.Card_Spade, 
	number = 5, 
	range = 3, 
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Dragon_bladeSkill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end, 
	on_uninstall = function(self, player)
	end, 
}
Dragon_blade:clone():setParent(extensionC)

Dragon_bladeSkill = sgs.CreateTriggerSkill{
	name = "Dragon_bladeSkill", 
	events = {sgs.CardOffset}, 
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, TriggerEvent, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if not effect.card:isKindOf("Slash") then return false end
		local weapon_id
		local use
		if (not effect.to:isAlive()) or effect.to:getMark("Equips_of_Others_Nullified_to_You") > 0 then return false end
		if effect.from:canSlash(effect.to, nil, false) and not effect.from:getWeapon():hasFlag("bladeused") then
			weapon_id = effect.from:getWeapon():getId()
			room:setCardFlag(weapon_id, "using")
			effect.from:setFlags("BladeUse")
			room:setCardFlag(weapon_id, "bladeused")
			use = room:askForUseSlashTo(effect.from, effect.to, "blade-slash:"..effect.to:objectName(), false, true)
			if not use then
				effect.from:setFlags("-BladeUse")
				room:setCardFlag(weapon_id, "-using")
			end
			room:setCardFlag(weapon_id, "-bladeused")
			return use
		end
		return false
	end, 
	can_trigger = function(self, target) 
		return target and target:getWeapon() and target:getWeapon():objectName() == "Dragon_blade" and target:getMark("Equips_Nullified_to_Yourself") == 0 and target:getHp() > 2
	end, 
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_bladeSkill") then skills:append(Dragon_bladeSkill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
["Dragon_blade"] = "青龙偃月刀", 
[":Dragon_blade"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你使用的【杀】第一次被【闪】抵消后，<b>若你的体力值大于2，</b>你可以对该角色再使用一张【杀】（无距离限制且不能选择额外目标）。", 
["Dragon_bladeSkill"] = "青龙偃月刀", 
["Dragon_Blade"] = "青龙偃月刀", 
}

Dragon_spear = sgs.CreateWeapon{
	name = "Dragon_spear", 
	class_name = "Dragon_Spear", 
	suit = sgs.Card_Spade, 
	number = 12, 
	range = 3, 
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			elseif skill:inherits("TriggerSkill") then
				local tirggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
				room:getThread():addTriggerSkill(tirggerskill)
			end
		end
	end, 
	on_uninstall = function(self, player)
	end, 
}

Dragon_spear:clone():setParent(extensionC)

Dragon_spear = sgs.CreateViewAsSkill{
	name = "Dragon_spear", 
	n = 1, 
	response_or_use = true, 
	--filter_pattern = ".", 
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE --[[and sgs.Self:hasFlag("Dragon_spear")]] then
			return not to_select:isEquipped()
		end
	end, 
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and player:getMark("Equips_Nullified_to_Yourself") == 0 and player:getHp() > 2 and player:hasFlag("Dragon_spear")
	end
}
Dragon_spearEmotion = sgs.CreateTriggerSkill{
	name = "Dragon_spearEmotion", 
	frequency = sgs.Skill_Compulsory, 
	global = true, 
	events = {sgs.CardAsked, sgs.CardResponded}, 
	on_trigger = function(self, TriggerEvent, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		local source
		if TriggerEvent == sgs.CardAsked then
			room:setPlayerFlag(player, "-Dragon_spear")
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:objectName() == prompt:split(":")[2] then
					source = p
				end
			end
			if (pattern ~= "slash") or ((not string.find(prompt, "duel")) and (not string.find(prompt, "@wushuang"))) or source:getMark("Equips_of_Others_Nullified_to_You") > 0 then return false end
			room:setPlayerFlag(player, "Dragon_spear")
		else
			local card = data:toCardResponse().m_card
			if card:isKindOf("Slash") and card:getSkillName() == "Dragon_spear" then
				room:setEmotion(player, "weapon/spear")
			end
		end
		return false
	end
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_spear") then skills:append(Dragon_spear) end
sgs.Sanguosha:addSkills(skills)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_spearEmotion") then skills:append(Dragon_spearEmotion) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
["Dragon_spear"] = "丈八蛇矛", 
[":Dragon_spear"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：【决斗】中，<b>若你的体力值大于2，</b>你可以将一张手牌当【杀】打出。", 
["Dragon_spearSkill"] = "丈八蛇矛", 
["Dragon_Spear"] = "丈八蛇矛", 
}

Dragon_axe = sgs.CreateWeapon{
	name = "Dragon_axe", 
	class_name = "Dragon_Axe", 
	suit = sgs.Card_Diamond, 
	number = 5, 
	range = 3, 
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Dragon_axeSkill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end, 
	on_uninstall = function(self, player)
	end, 
}
Dragon_axe:clone():setParent(extensionC)

Dragon_axeSkill = sgs.CreateTriggerSkill{
	name = "Dragon_axeSkill", 
	events = {sgs.CardOffset}, 
	view_as_skill = Dragon_axeViewAsSkill, 
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, TriggerEvent, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if not effect.card:isKindOf("Slash") then return false end
		local card
		if (not effect.to:isAlive()) or effect.to:getMark("Equips_of_Others_Nullified_to_You") > 0 then return false end
		if player:getCardCount() >= 3 then
			card = room:askForCard(player, "@axe", "@axe:"..effect.to:objectName(), data, self:objectName())
			if card then
				room:setEmotion(effect.from, "weapon/axe")
				return true
			end
		end
		return false
	end, 
	can_trigger = function(self, target) 
		return target and target:getWeapon() and target:getWeapon():objectName() == "Dragon_axe" and target:getMark("Equips_Nullified_to_Yourself") == 0 and target:getMaxHp() > 3
	end, 
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_axeSkill") then skills:append(Dragon_axeSkill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
["Dragon_axe"] = "贯石斧", 
[":Dragon_axe"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：每当你使用的【杀】被【闪】抵消后，<b>若你的体力上限大于3，</b>你可以弃置两张牌，则此【杀】继续造成伤害。", 
["Dragon_axeSkill"] = "贯石斧", 
["Dragon_Axe"] = "贯石斧", 
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "halberd" and card:getSuit() == sgs.Card_Diamond) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local halberd = sgs.Sanguosha:cloneCard(card:objectName(), 3, 12)
			halberd:setParent(extensionC)
		end
	end
end

Dragon_kylin_bow = sgs.CreateWeapon{
	name = "Dragon_kylin_bow", 
	class_name = "Dragon_KylinBow", 
	suit = sgs.Card_Heart, 
	number = 5, 
	range = 5, 
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Dragon_kylin_bowSkill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end, 
	on_uninstall = function(self, player)
	end, 
}
Dragon_kylin_bow:clone():setParent(extensionC)

Dragon_kylin_bowSkill = sgs.CreateTriggerSkill{
	name = "Dragon_kylin_bowSkill", 
	events = {sgs.DamageCaused}, 
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, TriggerEvent, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local horses = {}
		local horse_type
		if (damage.card and damage.card:isKindOf("Slash") and damage.by_user and not damage.chain and not damage.transfer and damage.from:distanceTo(damage.to) > 2 and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0) then
			if (damage.to:getDefensiveHorse() and damage.from:canDiscard(damage.to, damage.to:getDefensiveHorse():getEffectiveId())) then
				table.insert(horses, "defensive_horse")
			end
			if (damage.to:getOffensiveHorse() and damage.from:canDiscard(damage.to, damage.to:getOffensiveHorse():getEffectiveId())) then
				table.insert(horses, "offensive_horse")
			end
		end
		if #horses == 0 then return false end
		if player == nil then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		room:setEmotion(player, "weapon/kylin_bow")
		horse_type = room:askForChoice(damage.to, self:objectName(), table.concat(horses, "+"))
		if (horse_type == "defensive_horse") then
			room:throwCard(damage.to:getDefensiveHorse(), damage.to, damage.from)
		elseif (horse_type == "offensive_horse") then
			room:throwCard(damage.to:getOffensiveHorse(), damage.to, damage.from)
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():objectName() == "Dragon_kylin_bow" and target:getMark("Equips_Nullified_to_Yourself") == 0
	end, 
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_kylin_bowSkill") then skills:append(Dragon_kylin_bowSkill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
["Dragon_kylin_bow"] = "麒麟弓", 
[":Dragon_kylin_bow"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>：每当你使用【杀】对目标角色造成伤害时，<b>若你与该角色的距离大于2，</b>你可以令其弃置其装备区里的一张坐骑牌。", 
["Dragon_kylin_bowSkill"] = "麒麟弓", 
["Dragon_KylinBow"] = "麒麟弓", 
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "eight_diagram" and card:getSuit() == sgs.Card_Spade) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local eight_diagram = sgs.Sanguosha:cloneCard(card:objectName(), 0, 2)
			eight_diagram:setParent(extensionC)
			local eight_diagram = sgs.Sanguosha:cloneCard(card:objectName(), 1, 2)
			eight_diagram:setParent(extensionC)
		end
	end
end

local jueying = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Spade, 5)
local dilu = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Club, 5)
local zhuahuangfeidian = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Heart, 13)
local chitu = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Heart, 13)
local dayuan = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Spade, 13)
local zixing = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Diamond, 13)
jueying:setObjectName("jueying")
dilu:setObjectName("dilu")
zhuahuangfeidian:setObjectName("zhuahuangfeidian")
chitu:setObjectName("chitu")
dayuan:setObjectName("dayuan")
zixing:setObjectName("zixing")
jueying:setParent(extensionC)
dilu:setParent(extensionC)
zhuahuangfeidian:setParent(extensionC)
chitu:setParent(extensionC)
dayuan:setParent(extensionC)
zixing:setParent(extensionC)

Dragon_Horse = sgs.CreateDistanceSkill{ 
	name = "Dragon_Horse", 
	correct_func = function(self, from, to) 
		if from:getMark("Equips_of_Others_Nullified_to_You") > 0 then 
			if to:getDefensiveHorse() then 
				return -1 
			end
		else
			if to:getDefensiveHorse() and to:getMark("Equips_Nullified_to_Yourself") > 0 then 
				return -1 
			end
		end
		if to:getMark("Equips_of_Others_Nullified_to_You") > 0 then 
			if from:getOffensiveHorse() then 
				return 1 
			end
		else
			if from:getOffensiveHorse() and from:getMark("Equips_Nullified_to_Yourself") > 0 then 
				return 1 
			end
		end
	end, 
	priority = -1, 
}
local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_Horse") then
	skill_list:append(Dragon_Horse)
end
sgs.Sanguosha:addSkills(skill_list)

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "amazing_grace" and card:getSuit() == sgs.Card_Heart) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local amazing_grace = sgs.Sanguosha:cloneCard(card:objectName(), 2, 3)
			amazing_grace:setParent(extensionC)
			local amazing_grace = sgs.Sanguosha:cloneCard(card:objectName(), 2, 4)
			amazing_grace:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "god_salvation" and card:getSuit() == sgs.Card_Heart) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local god_salvation = sgs.Sanguosha:cloneCard(card:objectName(), 2, 1)
			god_salvation:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "savage_assault" and card:getSuit() == sgs.Card_Club) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local savage_assault = sgs.Sanguosha:cloneCard(card:objectName(), 0, 7)
			savage_assault:setParent(extensionC)
			local savage_assault = sgs.Sanguosha:cloneCard(card:objectName(), 0, 13)
			savage_assault:setParent(extensionC)
			local savage_assault = sgs.Sanguosha:cloneCard(card:objectName(), 1, 7)
			savage_assault:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "archery_attack" and card:getSuit() == sgs.Card_Heart) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local archery_attack = sgs.Sanguosha:cloneCard(card:objectName(), 2, 1)
			archery_attack:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "duel" and card:getSuit() == sgs.Card_Diamond) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local duel = sgs.Sanguosha:cloneCard(card:objectName(), 0, 1)
			duel:setParent(extensionC)
			local duel = sgs.Sanguosha:cloneCard(card:objectName(), 1, 1)
			duel:setParent(extensionC)
			local duel = sgs.Sanguosha:cloneCard(card:objectName(), 3, 1)
			duel:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "ex_nihilo" and card:getSuit() == sgs.Card_Heart) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local ex_nihilo = sgs.Sanguosha:cloneCard(card:objectName(), 2, 7)
			ex_nihilo:setParent(extensionC)
			local ex_nihilo = sgs.Sanguosha:cloneCard(card:objectName(), 2, 8)
			ex_nihilo:setParent(extensionC)
			local ex_nihilo = sgs.Sanguosha:cloneCard(card:objectName(), 2, 9)
			ex_nihilo:setParent(extensionC)
			local ex_nihilo = sgs.Sanguosha:cloneCard(card:objectName(), 2, 11)
			ex_nihilo:setParent(extensionC)
		end
	end
end

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "snatch" and card:getSuit() == sgs.Card_Diamond) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local snatch = sgs.Sanguosha:cloneCard(card:objectName(), 0, 3)
			snatch:setParent(extensionC)
			local snatch = sgs.Sanguosha:cloneCard(card:objectName(), 0, 4)
			snatch:setParent(extensionC)
			local snatch = sgs.Sanguosha:cloneCard(card:objectName(), 0, 11)
			snatch:setParent(extensionC)
			local snatch = sgs.Sanguosha:cloneCard(card:objectName(), 3, 3)
			snatch:setParent(extensionC)
			local snatch = sgs.Sanguosha:cloneCard(card:objectName(), 3, 4)
			snatch:setParent(extensionC)
		end
	end
end

Dragon_dismantlement = sgs.CreateTrickCard{
	name = "Dragon_dismantlement", 
	class_name = "Dismantlement", 
	subtype = "single_target_trick", 
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick, 
	target_fixed = false, 
	can_recast = false, 
	suit = 0, 
	number = 3, 
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isAllNude()
	end, 
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local target = nil
		if effect.from:canDiscard(effect.to, "hej") then else return end
		local card_id = room:askForCardChosen(effect.from, effect.to, "hej", "dismantlement", false, sgs.Card_MethodDiscard)
		if room:getCardPlace(card_id) ~= sgs.Player_PlaceDelayedTrick then target = effect.to end
		room:throwCard(card_id, target, effect.from)
	end, 
}
Dragon_dismantlement:setParent(extensionC)
local DragonDismantlement = Dragon_dismantlement:clone(0, 4)
DragonDismantlement:setParent(extensionC)
local DragonDismantlement = Dragon_dismantlement:clone(0, 12)
DragonDismantlement:setParent(extensionC)
local DragonDismantlement = Dragon_dismantlement:clone(1, 3)
DragonDismantlement:setParent(extensionC)
local DragonDismantlement = Dragon_dismantlement:clone(1, 4)
DragonDismantlement:setParent(extensionC)
local DragonDismantlement = Dragon_dismantlement:clone(2, 12)
DragonDismantlement:setParent(extensionC)

sgs.LoadTranslationTable{
["Dragon_dismantlement"] = "过河拆桥", 
[":Dragon_dismantlement"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名区域内有牌的角色。<br /><b>效果</b>：你弃置目标角色区域里的一张牌。", 
}

Dragon_collateral = sgs.CreateTrickCard{ 
	name = "Dragon_collateral",
	class_name = "DragonCollateral",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	suit = 1,
	number = 12,
	filter = function(self, targets, to_select, player)
		if #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getWeapon() then
		    return true
		end
		return false
	end,
	available = function(self, player)
	    local canUse = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:getWeapon() then
                canUse = true
                break
			end	
        end
        return canUse
	end,
	is_cancelable = true,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
		local weapon1 = effect.from:getWeapon()
		local weapon2 = effect.to:getWeapon()
		if weapon1 then
		    effect.from:addToPile(self:objectName(), weapon1)
			if not effect.from:hasSkill("Dragon_change_weapon") then
			    room:attachSkillToPlayer(effect.from, "Dragon_change_weapon")	
			end
		end
		-- room:setCardFlag(weapon2, "collateral")
		local card_ids1 = room:getTag("collateralSource"):toIntList()
		local card_ids2 = room:getTag("collateralTarget" .. effect.to:objectName()):toIntList()
		if card_ids1:contains(weapon2:getId()) then return false end
		card_ids1:append(weapon2:getId())
		card_ids2:append(weapon2:getId())
		local card_ids_data1, card_ids_data2 = sgs.QVariant(), sgs.QVariant()
		card_ids_data1:setValue(card_ids1)
		card_ids_data2:setValue(card_ids2)
		room:setTag("collateralSource", card_ids_data1)
		room:setTag("collateralTarget" .. effect.to:objectName(), card_ids_data2)
		room:setPlayerFlag(effect.from, self:objectName())
        room:moveCardTo(weapon2, effect.to, effect.from, sgs.Player_PlaceEquip, 
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.to:objectName(), "Dragon_collateral", ""), true)
    end
}
Dragon_collateral:setParent(extensionC)
local DragonCollateral = Dragon_collateral:clone(1, 13)
DragonCollateral:setParent(extensionC)

sgs.LoadTranslationTable{
["Dragon_collateral"] = "借刀杀人", 
[":Dragon_collateral"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名装备区内有武器牌的其他角色<br /><b>效果</b>：你获得目标角色装备区里的武器牌，并可以与你装备区里的武器牌替换使用。<br />回合结束后，你需要归还以此法获得的武器牌。", 
}

existed_cards = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if (card:objectName() == "nullification" and card:getSuit() == sgs.Card_Spade) and not table.contains(existed_cards, card:objectName()) then
		table.insert(existed_cards, card:objectName())
		for j = 1, 1, 1 do
			local nullification = sgs.Sanguosha:cloneCard(card:objectName(), 0, 11)
			nullification:setParent(extensionC)
			local nullification = sgs.Sanguosha:cloneCard(card:objectName(), 1, 12)
			nullification:setParent(extensionC)
			local nullification = sgs.Sanguosha:cloneCard(card:objectName(), 1, 13)
			nullification:setParent(extensionC)
		end
	end
end

Dragon_indulgence = sgs.CreateTrickCard{
	name = "Dragon_indulgence", 
	class_name = "Indulgence", 
	suit = sgs.Card_Spade, 
	number = 6, 
	subtype = "delayed_trick", 
	target_fixed = false, 
	can_recast = false, 
	subclass = sgs.LuaTrickCard_TypeDelayedTrick, 
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isLord()
	end, 
	on_effect = function(self, effect)
		local judge = sgs.JudgeStruct()
		local room = effect.to:getRoom()
		judge.pattern = ".|heart"
		judge.good = true
		judge.reason = "indulgence"--self:objectName()
		judge.who = effect.to
		room:judge(judge)
		if not judge:isGood() then
			if room:askForNullification(self, nil, effect.to, true) then else
				effect.to:clearHistory()
				effect.to:skip(sgs.Player_Play)
			end
		end
		self.on_nullified(self, effect.to)
	end, 
	available = function(self, player)
		local can = false
		for _, p in sgs.qlist(player:getSiblings()) do
			-- if nonSameDelay(p, self) and not p:isLord() then
			 if not p:isLord() then
				can = true
				break
			end
		end
		-- if nonSameDelay(player, self) and not player:isLord() then
		if not player:isLord() then
			can = true
		end
		return can
	end, 
}
Dragon_indulgence:setParent(extensionC)
local DragonIndulgence = Dragon_indulgence:clone(1, 6)
DragonIndulgence:setParent(extensionC)
local DragonIndulgence = Dragon_indulgence:clone(2, 6)
DragonIndulgence:setParent(extensionC)

sgs.LoadTranslationTable{
["Dragon_indulgence"] = "乐不思蜀", 
[":Dragon_indulgence"] = "延时锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名<b>非主公</b>角色<br /><b>效果</b>：将此牌置于目标角色判定区内。其判定阶段进行判定：若结果不为红桃，其跳过出牌阶段。然后将【乐不思蜀】置入弃牌堆。", 
}

Dragon_lightning = sgs.CreateTrickCard{
	name = "Dragon_lightning", 
	class_name = "Lightning", 
	suit = sgs.Card_Spade, 
	number = 1, 
	subtype = "delayed_trick", 
	target_fixed = false, 
	can_recast = false, 
	subclass = sgs.LuaTrickCard_TypeDelayedTrick, 
	movable = true, 
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() == player:objectName()
	end, 
	on_effect = function(self, effect)
		local judge = sgs.JudgeStruct()
		local room = effect.to:getRoom()
		judge.pattern = ".|spade|2~9"
		judge.good = false
		judge.reason = "lightning"--self:objectName()
		judge.who = effect.to
		room:judge(judge)
		if not judge:isGood() then
			if room:askForNullification(self, nil, effect.to, true) then else
				room:damage(sgs.DamageStruct(self:objectName(), nil, effect.to, 3, sgs.DamageStruct_Thunder))
			end
			onNullified_DelayedTrick_unmovable(self, effect.to)
		else
			self.on_nullified(self, effect.to)
		end
	end, 
}
Dragon_lightning:setParent(extensionC)

Dragon_Lightning = sgs.CreateTriggerSkill{
	name = "Dragon_Lightning", 
	global = true,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if event == sgs.CardsMoveOneTime then
			if move.to and move.to_place == sgs.Player_PlaceDelayedTrick then else return false end
			local sword_id = -1
			for _, card_id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getClassName() ~= "Lightning" then
					for _, jcard in sgs.qlist(move.to:getJudgingArea()) do
						if jcard:getClassName() == "Lightning" then
							sword_id = card_id
						end
					end
					if sword_id == -1 then return false end
					--[[move.to:addToPile(self:objectName(), sword_id)
					local card_ids = sgs.IntList()
					card_ids:append(move.to:getPile(self:objectName()):first())]]
					local card_ids = sgs.IntList()
					card_ids:append(sword_id)
					local fake = sgs.CardsMoveStruct()
						fake.card_ids = card_ids
						fake.to = move.to
						fake.to_place = sgs.Player_PlaceDelayedTrick
						fake.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DEMONSTRATE, move.to:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(fake, true)
					break
				end
			end
		end
		return false
	end,
	priority = -1,
}
local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Dragon_Lightning") then skill_list:append(Dragon_Lightning)end
sgs.Sanguosha:addSkills(skill_list)

sgs.LoadTranslationTable{
["Dragon_lightning"] = "闪电", 
[":Dragon_lightning"] = "延时锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：将此牌置于目标角色判定区内。其判定阶段进行判定：若结果为黑桃2-9，其受到3点雷电伤害并将【闪电】置入弃牌堆，否则将【闪电】移动至其下家判定区内。", 
}

extensionP = sgs.Package("Promote")

sgs.LoadTranslationTable{
	["Promote"] = "推广版", 
}
-- --技能描述 由 Super飞虎将军 修改 （不规范之处请多多包涵
-- Promote_liubei = sgs.General(extensionP, "Promote_liubei$", "shu", "4")

-- Promote_liubei:addSkill(Dragon_rende)
-- Promote_liubei:addSkill(Dragon_jijiang)

-- sgs.LoadTranslationTable{
-- 	["Promote_liubei"] = "推广版刘备", 
-- 	["designer:Promote_liubei"] = "官方|Lua：myetyet", 
-- }

-- Promote_guanyu = sgs.General(extensionP, "Promote_guanyu", "shu", "4")

-- Promote_guanyu:addSkill("wusheng")

-- sgs.LoadTranslationTable{
-- 	["Promote_guanyu"] = "推广版关羽", 
-- }

-- Promote_zhangfei = sgs.General(extensionP, "Promote_zhangfei", "shu", "4")

-- Promote_zhangfei:addSkill("paoxiao")

-- sgs.LoadTranslationTable{
-- 	["Promote_zhangfei"] = "推广版张飞", 
-- }

Promote_zhugeliang = sgs.General(extensionP, "Promote_zhugeliang", "shu", "3")

Promote_guanxing = sgs.CreateTriggerSkill{
	name = "Promote_guanxing", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("guanxing")
				local stars = room:getNCards(3, false)
				room:askForGuanxing(player, stars)
			end
		end
	end
}

Promote_zhugeliang:addSkill(Promote_guanxing)
Promote_zhugeliang:addSkill(Dragon_kongcheng)

sgs.LoadTranslationTable{
	["Promote_zhugeliang"] = "推广版诸葛亮", 
	["Promote_guanxing"] = "观星", 
	[":Promote_guanxing"] = "准备阶段开始时，你可以观看牌堆顶三张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。", 

}

-- Promote_zhaoyun = sgs.General(extensionP, "Promote_zhaoyun", "shu", "4")

-- Promote_zhaoyun:addSkill("longdan")

-- sgs.LoadTranslationTable{
-- 	["Promote_zhaoyun"] = "推广版赵云", 
-- }

Promote_machao = sgs.General(extensionP, "Promote_machao", "shu", "4")

Promote_mashu = sgs.CreateDistanceSkill{
	name = "#Promote_mashu", 
	correct_func = function(self, from, to)
		if from:hasSkill("Promote_mashu") and from:getMark("Equips_Nullified_to_Yourself") == 0 and to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			return -1
		end
	end, 
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
Promote_tieji = sgs.CreateTriggerSkill{
	name = "Promote_tieji" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
				p:setFlags("Promote_tiejiTarget")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = p
				player:getRoom():judge(judge)
				if judge:isGood() then
					jink_table[index] = 0
				end
				p:setFlags("-Promote_tiejiTarget")
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}

Promote_machao:addSkill(Promote_tieji)
Promote_machao:addSkill(Promote_mashu)
extensionP:insertRelatedSkills("Promote_tieji", "#Promote_mashu")

sgs.LoadTranslationTable{
	["Promote_machao"] = "推广版马超", 
	["Promote_tieji"] = "铁骑", 
	[":Promote_tieji"] = "当你使用【杀】指定一名角色为目标后，你可以令其进行一次判定，若判定结果为红色，该角色不可以使用【闪】响应此【杀】；当你计算与其他角色的距离时，始终-1。", 
	["Promote_mashu"] = "铁骑", 
}

Promote_huangyueying = sgs.General(extensionP, "Promote_huangyueying", "shu", "3", false)

Promote_jizhi = sgs.CreateTriggerSkill{
	name = "Promote_jizhi", 
	events = {sgs.CardUsed}, 
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardUse().card
		if card:isKindOf("TrickCard") then 
			if card:getSkillName() ~= "" then return false end
			if not room:askForSkillInvoke(player, "jizhi") then return false end
			player:drawCards(1)
			room:broadcastSkillInvoke("jizhi")
		end
	end, 
}

Promote_huangyueying:addSkill(Promote_jizhi)
Promote_huangyueying:addSkill("nosqicai")

sgs.LoadTranslationTable{
	["Promote_huangyueying"] = "推广版黄月英", 
	["Promote_jizhi"] = "集智", 
	[":Promote_jizhi"] = "每当你使用一张锦囊牌时，你可以摸一张牌。", 
}

Promote_sunquan = sgs.General(extensionP, "Promote_sunquan$", "wu", "4")

Promote_zhihengCard = sgs.CreateSkillCard{
	name = "Promote_zhihengCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}
Promote_zhiheng = sgs.CreateViewAsSkill{
	name = "Promote_zhiheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhiheng_card = Promote_zhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end,
	enabled_at_play = function(self, player)
		local lost = player:getLostHp()
		local used = player:usedTimes("#Promote_zhihengCard")
		return used < (lost + 1)
	end
}

Promote_jiuyuanCard = sgs.CreateBasicCard{
	name = "Peach", 
	class_name = "Peach", 
	subtype = "recover_card", 
	can_recast = false, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:isWounded() and to_select:hasLordSkill("Promote_jiuyuan") and self:isAvailable(to_select) and not sgs.Self:isProhibited(to_select, self)
		end
	end, 
	on_use = function(self, room, source, targets)
		if #targets == 0 then
			room:cardEffect(self, source, source)
		else
			for _, t in ipairs(targets) do
				room:cardEffect(self, source, t)
			end
		end
	end, 
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:setEmotion(effect.from, "peach")
		room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
		room:broadcastSkillInvoke("peach")
	end, 
	--[[available = function(self, player)
		local can = false
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isWounded() and p:hasLordSkill("Promote_jiuyuan") and not player:isProhibited(p, self) then
				can = true
				break
			end
		end
		return can
	end,]] 
}

Promote_jiuyuanVS = sgs.CreateOneCardViewAsSkill{
	name = "Promote_jiuyuanVS&", 
	filter_pattern = "Peach",
	response_or_use = true,
	view_as = function(self, ocard)
		local card = Promote_jiuyuanCard:clone()
		card:addSubcard(ocard)
		return card
	end, 
	enabled_at_play = function(self, player)
		local can = false
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isWounded() and p:hasLordSkill("Promote_jiuyuan") then
				can = true
			end
		end
		return can
	end, 
}

Promote_jiuyuan = sgs.CreateTriggerSkill{
	name = "Promote_jiuyuan$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.GameStart, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.Death}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local skill_exist = false
		if player:hasLordSkill(self:objectName()) then skill_exist = true end
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == "wu" and not p:hasSkill("Promote_jiuyuanVS") then
					room:attachSkillToPlayer(p, "Promote_jiuyuanVS")
				end
			end
		elseif ((event == sgs.EventLoseSkill and data:toString() == self:objectName()) or event == sgs.Death ) and not skill_exist then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("Promote_jiuyuanVS") then
					room:detachSkillFromPlayer(p, "Promote_jiuyuanVS")
				end
			end
		end
		return false
	end
}

Promote_jiuyuanClear = sgs.CreateTriggerSkill{
	name = "#Promote_jiuyuanClear", 
	events = {sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.from == sgs.Player_Play then
			if player:hasFlag("Promote_jiuyuan") then
				room:setPlayerFlag(player, "-Promote_jiuyuan")
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("Promote_jiuyuanInvoked") then
					room:setPlayerFlag(p, "-Promote_jiuyuanInvoked")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}

local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Promote_jiuyuanVS") then skill_list:append(Promote_jiuyuanVS)end
sgs.Sanguosha:addSkills(skill_list)

Promote_sunquan:addSkill(Promote_zhiheng)
Promote_sunquan:addSkill(Promote_jiuyuan)
Promote_sunquan:addSkill(Promote_jiuyuanClear)
extensionP:insertRelatedSkills("Promote_jiuyuan", "#Promote_jiuyuanClear")

sgs.LoadTranslationTable{
	["Promote_sunquan"] = "推广版孙权", 
	["designer:Promote_sunquan"] = "官方|Lua：红月⑦", 
	["Promote_zhiheng"] = "制衡", 
	["promote_zhiheng"] = "制衡", 
	[":Promote_zhiheng"] = "<font color=\"green\"><b>出牌阶段限X+1次，</b></font>你可以弃置任意数量的牌，然后摸等量的牌，X为你已损失的体力值。", 
	["Promote_zhiheng-prompt"] = "请弃置任意数量的手牌", 
	["Promote_jiuyuan"] = "救援", 
	[":Promote_jiuyuan"] = "<font color=\"orange\"><b>主公技，</b></font>其他角色吴势力可以于其出牌阶段对你使用【桃】。", 
	["Promote_jiuyuanVS"] = "救援", 
	[":Promote_jiuyuanVS"] = "出牌阶段，你可以对<font color=\"green\"><b>推广版孙权</b></font>使用【桃】。", 
}

-- Promote_ganning = sgs.General(extensionP, "Promote_ganning", "wu", "4")

-- Promote_ganning:addSkill("qixi")

-- sgs.LoadTranslationTable{
-- 	["Promote_ganning"] = "推广版甘宁", 
-- }

-- Promote_lvmeng = sgs.General(extensionP, "Promote_lvmeng", "wu", "4")

-- Promote_lvmeng:addSkill(Dragon_keji)
-- Promote_lvmeng:addSkill(Dragon_kejiLimit)

-- sgs.LoadTranslationTable{
-- 	["Promote_lvmeng"] = "推广版吕蒙", 
-- }

-- Promote_huanggai = sgs.General(extensionP, "Promote_huanggai", "wu", "4")

-- Promote_huanggai:addSkill("kurou")

-- sgs.LoadTranslationTable{
-- 	["Promote_huanggai"] = "推广版黄盖", 
-- }

Promote_zhouyu = sgs.General(extensionP, "Promote_zhouyu", "wu", "3")

Promote_fanjianCard = sgs.CreateSkillCard{
	name = "Promote_fanjianCard",	
	on_effect = function(self, effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = zhouyu:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForChoice(target, "Promote_fanjian", "red+black")
		if (suit == "red" and card:isRed()) or (suit == "black" and card:isBlack()) then
			room:damage(sgs.DamageStruct("Promote_fanjian", zhouyu, target))
		end
		room:getThread():delay()
		target:obtainCard(card)
	end
}
Promote_fanjian = sgs.CreateZeroCardViewAsSkill{
	name = "Promote_fanjian",	
	view_as = function()
		return Promote_fanjianCard:clone()
	end,	
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#Promote_fanjianCard"))
	end
}

Promote_zhouyu:addSkill("nosyingzi")
Promote_zhouyu:addSkill(Promote_fanjian)

sgs.LoadTranslationTable{
	["Promote_zhouyu"] = "推广版周瑜", 
	["Promote_fanjian"] = "反间", 
	["promote_fanjian"] = "反间", 
	[":Promote_fanjian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名角色，其选择你的一张手牌并声明一种颜色，若颜色不符，你对其造成1点伤害，无论颜色是否相符，其获得之。", 
}

-- Promote_daqiao = sgs.General(extensionP, "Promote_daqiao", "wu", "3", false)

-- Promote_daqiao:addSkill("nosguose")
-- Promote_daqiao:addSkill("liuli")

-- sgs.LoadTranslationTable{
-- 	["Promote_daqiao"] = "推广版大乔", 
-- }

-- Promote_luxun = sgs.General(extensionP, "Promote_luxun", "wu", "3")

-- Promote_luxun:addSkill("nosqianxun")
-- Promote_luxun:addSkill("noslianying")

-- sgs.LoadTranslationTable{
-- 	["Promote_luxun"] = "推广版陆逊", 
-- }

-- Promote_sunshangxiang = sgs.General(extensionP, "Promote_sunshangxiang", "wu", "3", false)

-- Promote_sunshangxiang:addSkill("xiaoji")
-- Promote_sunshangxiang:addSkill("jieyin")

-- sgs.LoadTranslationTable{
-- 	["Promote_sunshangxiang"] = "推广版孙尚香", 
-- }

-- Promote_caocao = sgs.General(extensionP, "Promote_caocao$", "wei", "4")

-- Promote_caocao:addSkill("nosjianxiong")
-- Promote_caocao:addSkill("hujia")

-- sgs.LoadTranslationTable{
-- 	["Promote_caocao"] = "推广版曹操", 
-- }

-- Promote_simayi = sgs.General(extensionP, "Promote_simayi", "wei", "3")

-- Promote_simayi:addSkill("nosguicai")
-- Promote_simayi:addSkill("nosfankui")

-- sgs.LoadTranslationTable{
-- 	["Promote_simayi"] = "推广版司马懿", 
-- }

Promote_xiahoudun = sgs.General(extensionP, "Promote_xiahoudun", "wei", "4")

Promote_ganglie = sgs.CreateTriggerSkill{
	name = "Promote_ganglie", 
	events = {sgs.Damaged}, 
	on_trigger=function(self, event, player, data)
		local room = player:getRoom()
		local from = data:toDamage().from
		if(from and from:isAlive() and room:askForSkillInvoke(player, self:objectName(), data)) then
			room:broadcastSkillInvoke("ganglie")
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = from
			room:judge(judge)
			if(judge:isGood()) then
				if from:getHandcardNum() < 2 then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				elseif(not room:askForDiscard(from, self:objectName(), 2, 2, true)) then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				end
			end
		end
	end
}

Promote_xiahoudun:addSkill(Promote_ganglie)

sgs.LoadTranslationTable{
	["Promote_xiahoudun"] = "推广版夏侯惇", 
	["designer:Promote_xiahoudun"] = "官方|Lua：Super飞虎将军", 
	["Promote_ganglie"] = "刚烈", 
	[":Promote_ganglie"] = "当你受到伤害后，你可以令伤害来源进行一次判定，若结果不为<font color=\"red\"><b>♥</b></font>，该角色弃置两张手牌，或受到你对其造成一点伤害。", 	
}

-- Promote_zhangliao = sgs.General(extensionP, "Promote_zhangliao", "wei", "4")

-- Promote_zhangliao:addSkill("nostuxi")

-- sgs.LoadTranslationTable{
-- 	["Promote_zhangliao"] = "推广版张辽", 
-- }

Promote_xuchu = sgs.General(extensionP, "Promote_xuchu", "wei", "4")

Promote_luoyiBuff = sgs.CreateTriggerSkill{
	name = "#Promote_luoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("Promote_luoyi") and target:isAlive()
	end
}
Promote_luoyi = sgs.CreateTriggerSkill{
	name = "Promote_luoyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local room = player:getRoom()
		--local count = data:toInt()
		--if count > 0 then
		if draw.num > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				draw.num = draw.num - 2
				room:setPlayerFlag(player, "Promote_luoyi")
				data:setValue(draw)
			end
		end
	end
}

Promote_xuchu:addSkill(Promote_luoyi)
Promote_xuchu:addSkill(Promote_luoyiBuff)
extensionP:insertRelatedSkills("Promote_luoyi", "#Promote_luoyiBuff")

sgs.LoadTranslationTable{
	["Promote_xuchu"] = "推广版许褚", 
	["Promote_luoyi"] = "裸衣", 
	[":Promote_luoyi"] = "摸牌阶段摸牌时，你可以少摸两张牌，然后你为来源的【杀】和【决斗】造成的伤害+1。", 
}

-- Promote_guojia = sgs.General(extensionP, "Promote_guojia", "wei", "3")

-- Promote_guojia:addSkill("tiandu")
-- Promote_guojia:addSkill("nosyiji")

-- sgs.LoadTranslationTable{
-- 	["Promote_guojia"] = "推广版郭嘉", 
-- }

Promote_zhenji = sgs.General(extensionP, "Promote_zhenji", "wei", "3", false)

Promote_luoshen = sgs.CreateTriggerSkill{
	name = "Promote_luoshen", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:obtainCard(card)
					return true
				end
			end
		else
			if player:getPhase() == sgs.Player_Judge then
				if event == sgs.EventPhaseEnd and player:getMark(self:objectName()) ~= 0 then
					room:setPlayerMark(player, self:objectName(), 0)
					return false
				end
				while player:askForSkillInvoke(self:objectName()) do
					if event == sgs.EventPhaseStart then
						room:setPlayerMark(player, self:objectName(), 1)
					end
					room:broadcastSkillInvoke("luoshen")
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
			end
		end
		return false
	end
}

Promote_zhenji:addSkill(Promote_luoshen)
Promote_zhenji:addSkill("qingguo")

sgs.LoadTranslationTable{
	["Promote_zhenji"] = "推广版甄姬", 
	["Promote_luoshen"] = "洛神", 
	[":Promote_luoshen"] = "你可以选择一项：判定阶段开始时；或判定阶段结束时。选择完成后，你可以于此时机进行一次判定，若结果为<font color=\"black\"><b>黑色</b></font>，你获得此牌，你可以重复此流程，直到出现<font color=\"red\"><b>红色</b></font>的判定结果为止。", 
}

Promote_huatuo = sgs.General(extensionP, "Promote_huatuo", "qun", "3")

Promote_qingnangCard = sgs.CreateSkillCard{
	name = "Promote_qingnangCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(source, recover)
		room:broadcastSkillInvoke("qingnang")
	end
}

Promote_qingnangCard = sgs.CreateSkillCard{
	name = "Promote_qingnangCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(source, recover)
		room:broadcastSkillInvoke("qingnang")
	end
}

Promote_qingnang = sgs.CreateViewAsSkill{
	name = "Promote_qingnang", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local card = Promote_qingnangCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and player:isWounded()
	end
}

Promote_huatuo:addSkill(Promote_qingnang)
Promote_huatuo:addSkill("jijiu")

sgs.LoadTranslationTable{
	["Promote_huatuo"] = "推广版华佗", 
	["Promote_qingnang"] = "青囊", 
	["promote_qingnang"] = "青囊", 
	[":Promote_qingnang"] = "出牌阶段，若你已受伤，你可以弃置一张手牌回复1点体力。", 
}

-- Promote_lvbu = sgs.General(extensionP, "Promote_lvbu", "qun", "4")

-- Promote_lvbu:addSkill("wushuang")

-- sgs.LoadTranslationTable{
-- 	["Promote_lvbu"] = "推广版吕布", 
-- }

-- Promote_diaochan = sgs.General(extensionP, "Promote_diaochan", "qun", "3", false)

-- Promote_diaochan:addSkill("noslijian")
-- Promote_diaochan:addSkill("biyue")

-- sgs.LoadTranslationTable{
-- 	["Promote_diaochan"] = "推广版貂蝉", 
-- }
extensionD = sgs.Package("Promote_d")
Promote_darksoul = sgs.General(extensionD, "Promote_darksoul", "god", 0, true, true)


Promote_darksoul_rule = sgs.CreateTriggerSkill{
	name = "Promote_darksoul_rule",
	events = {sgs.GameStart, sgs.Damaged, sgs.Death},
	global = true,
	priority = 3,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setTag("DeathNum", sgs.QVariant(0))
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("lightning") then
				if damage.to and damage.to:isAlive() and damage.to:getTag("Promote_luohan"):toPlayer() then
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					damage.to:removeTag("Promote_luohan")
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						damage.to:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
				end
				if damage.to and damage.to:isAlive() and damage.to:getTag("Promote_xuanwu"):toPlayer() then
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					damage.to:removeTag("Promote_xuanwu")
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						damage.to:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
				end
				if damage.to and damage.to:isAlive() and damage.to:getTag("Promote_zhuyou"):toPlayer() then
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					damage.to:removeTag("Promote_zhuyou")
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						damage.to:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				room:setTag("DeathNum", sgs.QVariant(room:getTag("DeathNum"):toInt()+1))
			end
		end
	end,
	can_trigger = function(self, player)
        return not table.contains(sgs.Sanguosha:getBanPackages(), "Promote_d")
    end
}
Promote_luohan = sgs.CreateTriggerSkill{
	name = "Promote_luohan",
	events = {sgs.Death, sgs.DamageInflicted},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				if room:getTag("DeathNum"):toInt() == 1 and player:getRole() == "loyalist" then
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "Promote_luohan-invoke",
								true, true)
					if target then
						local jsonValue = {
							10,
							target:objectName(),
							"Promote_darksoul",
							"Promote_luohan",
						}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
						local dest = sgs.QVariant()
						dest:setValue(player)
						target:setTag("Promote_luohan", dest)
						room:addPlayerMark(player, "HandcardVisible_"..target:objectName())
						room:setPlayerFlag(player, "HandcardVisible_"..target:objectName())
						room:showAllCards(target, player)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:objectName() == player:objectName() and player:getTag("Promote_luohan"):toPlayer() then
				if player:canDiscard(player, "h") and room:askForSkillInvoke(player:getTag("Promote_luohan"):toPlayer(), "Promote_luohan", data) then
					room:askForDiscard(player, self:objectName(), 1, 1, false, false)
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						player:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					player:removeTag("Promote_luohan")
					damage.to:removeTag("Promote_luohan")
					damage.prevented = true
					data:setValue(damage)
					local log = sgs.LogMessage()
					log.type  = "#SkillNullifyDamage"
					log.from  = player
					log.arg   = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, player)
        return true
    end
}
Promote_xuanwu = sgs.CreateTriggerSkill{
	name = "Promote_xuanwu",
	events = {sgs.Death, sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				if room:getTag("DeathNum"):toInt() == 1 and player:getRole() == "rebel"  then
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "Promote_xuanwu-invoke",
								true, true)
					if target then
						local jsonValue = {
							10,
							target:objectName(),
							"Promote_darksoul",
							"Promote_xuanwu",
						}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
						local dest = sgs.QVariant()
						dest:setValue(player)
						target:setTag("Promote_xuanwu", dest)
						room:addPlayerMark(player, "HandcardVisible_"..target:objectName())
						room:setPlayerFlag(player, "HandcardVisible_"..target:objectName())
						room:showAllCards(target, player)
						local id = room:drawCard()
						local players = sgs.SPlayerList()
						players:append(player)
						target:addToPile("Promote_xuanwu", sgs.Sanguosha:getCard(id), false, players)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local current = room:getCurrent()
			if current and current:getPhase() == sgs.Player_Start and player:getTag("Promote_xuanwu"):toPlayer() then
				if player:canDiscard(player, "h") and room:askForSkillInvoke(player:getTag("Promote_xuanwu"):toPlayer(), "Promote_xuanwu", data) then
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						player:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					local id = room:askForCardChosen(player:getTag("Promote_xuanwu"):toPlayer(), player, "h", self:objectName())
					room:throwCard(id, player, player:getTag("Promote_xuanwu"):toPlayer())
					if player:getPile("Promote_xuanwu"):length() > 0 then
						for _, id in sgs.qlist(player:getPile("Promote_xuanwu")) do
							room:obtainCard(player, id)
						end
					end
					player:removeTag("Promote_xuanwu")
				end
			end
		end
	end,
	can_trigger = function(self, player)
        return true
    end
}
Promote_zhuyou = sgs.CreateTriggerSkill{
	name = "Promote_zhuyou",
	events = {sgs.Death, sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				if room:getTag("DeathNum"):toInt() == 1 and player:getRole() == "renegade"  then
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "Promote_zhuyou-invoke",
								true, true)
					if target then
						local jsonValue = {
							10,
							target:objectName(),
							"Promote_darksoul",
							"Promote_zhuyou",
						}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
						local dest = sgs.QVariant()
						dest:setValue(player)
						target:setTag("Promote_zhuyou", dest)
						room:addPlayerMark(player, "HandcardVisible_"..target:objectName())
						room:setPlayerFlag(player, "HandcardVisible_"..target:objectName())
						room:showAllCards(target, player)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getTag("Promote_zhuyou"):toPlayer() then
				if player:canDiscard(player, "h") and room:askForSkillInvoke(player:getTag("Promote_zhuyou"):toPlayer(), "Promote_zhuyou", data) then
					local jsonValue={9}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					local jsonValue = {
						4, --sgs.CommandType.S_GAME_EVENT_DETACH_SKILL leads to SOS logo
						player:objectName(),
						"huashen", --dummy skill
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					local x = player:getHandcardNum()
					player:throwAllHandCards()
					player:drawCards(x)
					player:removeTag("Promote_zhuyou")
				end
			end
		end
	end,
	can_trigger = function(self, player)
        return true
    end
}

-- Promote_darksoul:addSkill(Promote_luohan)
-- Promote_darksoul:addSkill(Promote_xuanwu)
-- Promote_darksoul:addSkill(Promote_zhuyou)
local skill_list = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Promote_darksoul_rule") then skill_list:append(Promote_darksoul_rule)end
if not sgs.Sanguosha:getSkill("Promote_luohan") then skill_list:append(Promote_luohan)end
if not sgs.Sanguosha:getSkill("Promote_xuanwu") then skill_list:append(Promote_xuanwu)end
if not sgs.Sanguosha:getSkill("Promote_zhuyou") then skill_list:append(Promote_zhuyou)end
sgs.Sanguosha:addSkills(skill_list)
Promote_darksoul:addSkill("Promote_luohan")
Promote_darksoul:addSkill("Promote_xuanwu")
Promote_darksoul:addSkill("Promote_zhuyou")

sgs.LoadTranslationTable{
	["Promote_d"] = "暗魂", 
	["Promote_darksoul"] = "暗魂", 
	["#Promote_darksoul"] = "縱橫時空", 
	["information:Promote_darksoul"] = "当游戏中出现第一个选择死亡的角色时，该玩家可以变成暗魂，自主选择放置在任意一个仍然拥有的角色搭配上。玩家选择角色牌时，取一张暗魂角色牌，将暗魂角色牌收纳在被附体的玩家角色牌后面。（只有第一名死亡角色选择可以变成暗魂。）\
	暗魂可以随时查看被附体角色的玩家手牌，但被附体玩家无法查看暗魂的手牌。\
	任何时候，若被附体玩家的手牌不满足暗魂技能发动条件时，暗魂技能就无法发动。\
	当被浇注的玩家被闪电命中时，无论生死，暗魂都会魂飞魄散。", 

	["Promote_luohan"] = "羅漢", 
	[":Promote_luohan"] = "忠臣死亡后，可选择变成罗汉暗魂：可以在被附体玩家受到伤害时，替他承受伤害，这样做时，被附体玩家不能拒绝，且承受后被附体玩家需弃掉一张手牌，同时，罗汉暗魂消失。", 
	["Promote_luohan-invoke"] = "你可以选择变成羅漢暗魂附体一名角色",

	["&Promote_xuanwu"] = "玄武", 
	["Promote_xuanwu"] = "玄武", 
	[":Promote_xuanwu"] = "反贼死亡后，选择变成玄武暗魂：玄武暗魂附体时立即从牌堆摸一张手牌，玄武暗魂可以在<s>任何时候</s>每回合開始時将自己手上的这张牌与被附体玩家手上的暗魂指定的一张牌进行交换，同时，玄武暗魂消失。", 
	["Promote_xuanwu-invoke"] = "你可以选择变成玄武暗魂附体一名角色",

	["Promote_zhuyou"] = "祝由", 
	[":Promote_zhuyou"] = "内奸死亡后，可选择变成祝由暗魂：祝游暗魂可以在被附体玩家的出牌阶段開始時命令被附体玩家弃掉手上所有牌，然后从牌堆抽取与弃掉的手牌立即数量相同的牌，当祝由暗魂随后，消失。", 
	["Promote_zhuyou-invoke"] = "你可以选择变成祝由暗魂附体一名角色",

}





return {extension, extensionC, extensionP, extensionD}
--	本MOD仅供广大喜爱三国杀的玩家交流和学习使用，请勿用于商业用途，请在下载后24小时之内删除，如有违者后果自负！！！