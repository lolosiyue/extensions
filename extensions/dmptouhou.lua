module("extensions.dmptouhou", package.seeall) --游戏包
extension = sgs.Package("dmptouhou")           --增加拓展包

--势力

do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "touhou")
	config.color_de = "#7CCD7C"
end

local function doLog(logtype, logfrom, logarg, logto, logarg2)
	local alog = sgs.LogMessage()
	alog.type = logtype
	alog.from = logfrom
	if logto then
		alog.to:append(logto)
	end
	if logarg then
		alog.arg = logarg
	end
	if logarg2 then
		alog.arg2 = logarg2
	end
	local room = logfrom:getRoom()
	room:sendLog(alog)
end

--明窃
se_mingqie = sgs.CreateTriggerSkill {
	name = "se_mingqie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local targets = use.to
		local card = use.card
		local room = player:getRoom()
		if use.to:length() > 1 or use.to:length() == 0 then return end
		if not use.from or not use.from:hasSkill(self:objectName()) then return end
		if use.to:contains(use.from) then return end
		local to = use.to:at(0)
		local from = use.from
		if to:getEquips():length() == 0 then return end
		if to:hasFlag("se_mingqie_used") then return end
		if not from:askForSkillInvoke(self:objectName(), data) then return end
		room:broadcastSkillInvoke(self:objectName())
		local id = room:askForCardChosen(from, to, "he", self:objectName())
		room:obtainCard(from, id)
		to:setFlags("se_mingqie_used")
		if sgs.Sanguosha:getCard(id):isBlack() then
			from:gainMark("@p_point")
		end
	end
}

se_mingqie_filter = sgs.CreateFilterSkill {
	name = "#se_mingqie_filter",
	view_filter = function(self, to_select)
		return to_select:isKindOf("Dismantlement")
	end,
	view_as = function(self, card)
		local KScard
		KScard = sgs.Sanguosha:cloneCard("Snatch", card:getSuit(), card:getNumber())
		local acard = sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(KScard)
		acard:setSkillName("se_mingqie")
		return acard
	end,
}

se_mingqie_target_mod = sgs.CreateTargetModSkill {
	name = "#se_mingqie_target_mod",
	pattern = "Snatch",
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}

--魔炮
se_mopaocard = sgs.CreateSkillCard {
	name = "se_mopaocard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local count = source:getMark("@p_point")
		if count < 4 then return end
		source:loseMark("@p_point", 4)
		local direction = room:askForChoice(source, self:objectName(), "left+right")
		local damage = sgs.DamageStruct()
		damage.from = source
		if direction == "right" then
			local next_man = source:getNextAlive()
			while (next_man:objectName() ~= target:objectName()) do
				damage.to = next_man
				room:damage(damage)
				next_man = next_man:getNextAlive()
			end
			damage.to = target
			if target:getEquips():length() == 0 then
				room:doLightbox("se_mopao$", 3000)
				damage.damage = 3
				source:turnOver()
			end
			room:damage(damage)
		else
			local next_man = target:getNextAlive()
			local tos = sgs.SPlayerList()
			local num = 0
			while next_man:objectName() ~= source:objectName() do
				tos:append(next_man)
				num = num + 1
				next_man = next_man:getNextAlive()
			end
			for j = num - 1, 0, -1 do
				damage.to = tos:at(j)
				room:damage(damage)
			end


			damage.to = target
			if target:getEquips():length() == 0 then
				room:doLightbox("se_mopao$", 3000)
				damage.damage = 3
				source:turnOver()
			end
			room:damage(damage)
		end
	end,
}

se_mopao = sgs.CreateViewAsSkill {
	name = "se_mopao",
	n = 0,
	view_as = function(self, cards)
		return se_mopaocard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@p_point") > 3 and not player:hasUsed("#se_mopaocard")
	end,
}

--无意
se_wushi = sgs.CreateDistanceSkill {
	name = "se_wushi",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return 99
		end
		if to:hasSkill(self:objectName()) then
			return 99
		end
		return 0
	end
}

--无识
se_wuyi = sgs.CreateTriggerSkill {
	name = "se_wuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
			local wore = math.random(2, 10)
			local hp = player:getHp()
			local maxhp = player:getMaxHp()
			if hp - wore > 3 then
				room:doLightbox("se_wuyi$", 1500)
			end
			if wore < maxhp then
				room:loseMaxHp(player, maxhp - wore)
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_losehp", "se_wuyi_losehp")
				if target then room:loseHp(target) end
				if player:getHp() < hp then
					local x = 2 * (hp - player:getHp())
					room:setPlayerMark(player, "se_wuyi-draw", x)
					target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_draw", "se_wuyi_draw")
					if target then target:drawCards(2 * (hp - player:getHp())) end
				end
			elseif wore > maxhp then
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(wore))
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_recover",
					"se_wuyi_recover")
				local re = sgs.RecoverStruct()
				re.who = target
				if target then room:recover(target, re, true) end
			end
		end
	end
}

--窥心
se_kuixincard = sgs.CreateSkillCard {
	name = "se_kuixincard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select) == 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			room:broadcastSkillInvoke("se_kuixin")
			room:doLightbox("se_kuixin$", 800)
			room:showAllCards(effect.to, effect.from)
			room:setPlayerFlag(effect.to, "se_kuixin_used")
		end
	end
}
se_kuixin = sgs.CreateZeroCardViewAsSkill {
	name = "se_kuixin",
	view_as = function()
		return se_kuixincard:clone()
	end,
	enabled_at_play = function(self, target)
		return true
	end
}

--回想
se_huixiangCard = sgs.CreateSkillCard {
	name = "se_huixiang",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:obtainCard(source, self)
		if source:getPile("satori_memory"):length() > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, cd in sgs.qlist(source:getPile("satori_memory")) do
				dummy:addSubcard(cd)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(),
				"")
			room:throwCard(dummy, reason, nil)
		end
	end
}
se_huixiangVS = sgs.CreateViewAsSkill {
	name = "se_huixiang",
	n = 999,
	expand_pile = "satori_memory",
	view_filter = function(self, selected, to_select)
		local max = math.ceil(sgs.Self:getHp() / 2)
		if #selected < max then
			return sgs.Self:getPile("satori_memory"):contains(to_select:getId())
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local se_huixiang = se_huixiangCard:clone()
			for i = 1, #cards, 1 do
				se_huixiang:addSubcard(cards[i]:getId())
			end
			return se_huixiang
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@se_huixiang"
	end

}
se_huixiang = sgs.CreateTriggerSkill {
	name = "se_huixiang",
	view_as_skill = se_huixiangVS,
	--frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.CardFinished, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) and player:getPile("satori_memory"):length() > 0 then
				local max = math.ceil(player:getHp() / 2)
				if max <= 0 then return end
				local prompt = string.format("@se_huixiang:%s", max)
				if room:askForUseCard(player, "@@se_huixiang", prompt) then
					room:broadcastSkillInvoke(self:objectName())
				end
				--[[		local pile = player:getPile("satori_memory")
				for i = 1, max, 1 do
					if pile:length() <= 0 then break end
					room:fillAG(pile, player)
					local id = room:askForAG(player, pile, false, self:objectName())
					if id ~= -1 then
						room:obtainCard(player, id, true)
					end
					pile:removeOne(id)
					room:clearAG(player)
				end
				--player:removePileByName("satori_memory")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _,cd in sgs.qlist(source:getPile("satori_memory")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
						room:throwCard(dummy, reason, nil)]]
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card then return end
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return end

			for _, satori in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if satori:getPhase() ~= sgs.Player_NotActive then continue end
				if satori:objectName() == player:objectName() then continue end

				local id
				if use.card:getSubcards():length() > 0 then
					for _, id in sgs.qlist(use.card:getSubcards()) do
						if room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
							--		if not satori:askForSkillInvoke(self:objectName(), data) then return end
							room:broadcastSkillInvoke(self:objectName())
							satori:addToPile("satori_memory", id)
						end
					end
				else
					id = use.card:getEffectiveId()

					if id == -1 then return end
					if use.card:isVirtualCard() then return end
					if room:getCardPlace(use.card:getEffectiveId()) ~= sgs.Player_DiscardPile then return end
					--	if not satori:askForSkillInvoke(self:objectName(), data) then return end
					room:broadcastSkillInvoke(self:objectName())
					satori:addToPile("satori_memory", id)
				end
			end
		elseif event == sgs.CardResponded then
			local use = data:toCardResponse()
			if not use.m_card then return end
			if use.m_card:isVirtualCard() then return end
			if room:getCardPlace(use.m_card:getEffectiveId()) ~= sgs.Player_PlaceTable then return end
			if not use.m_card:isKindOf("BasicCard") and not use.m_card:isKindOf("TrickCard") then return end
			for _, satori in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if satori:getPhase() ~= sgs.Player_NotActive then continue end
				if satori:objectName() == player:objectName() then continue end


				--	if not satori:askForSkillInvoke(self:objectName(), data) then return end
				room:broadcastSkillInvoke(self:objectName())
				satori:addToPile("satori_memory", use.m_card:getEffectiveId())
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

se_fuzhi = sgs.CreateTriggerSkill {
	name = "se_fuzhi$",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			local lieges = room:getLieges("touhou", player)
			if lieges:length() == 0 then return end
			if player:getHandcardNum() > player:getHp() then
				local target = room:askForPlayerChosen(player, lieges, self:objectName(), "se_fuzhi-invoke", true, true)
				if target then
					room:broadcastSkillInvoke("se_fuzhi")
					local x = player:getHandcardNum() - player:getHp()
					local prompt = string.format("se_fuzhi-card:%s:%s", target:objectName(), x)
					local to_obtain = room:askForExchange(player, "se_fuzhi", x, x, false, prompt, false)
					if not to_obtain then return end
					room:moveCardTo(to_obtain, target, sgs.Player_PlaceHand, false)
					player:setFlags("se_fuzhi")
					target:setFlags("se_fuzhi_target")
					player:skip(sgs.Player_Play)
				end
			end
		elseif change.to == sgs.Player_NotActive then
			if player:hasFlag("se_fuzhi") then
				local target
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("se_fuzhi_target") then
						target = p
					end
				end
				local playerdata = sgs.QVariant()
				playerdata:setValue(target)
				room:setTag("se_fuzhi_givetarget", playerdata)
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		if player then
			return player:hasLordSkill(self:objectName())
		end
		return false
	end
}
se_fuzhi_give = sgs.CreateTriggerSkill {
	name = "#se_fuzhi-give$",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("se_fuzhi_givetarget") then
			local target = room:getTag("se_fuzhi_givetarget"):toPlayer()
			room:removeTag("se_fuzhi_givetarget")
			if target and target:isAlive() then
				doLog("#se_fuzhi_give_message", target)
				target:setPhase(sgs.Player_Play)
				room:broadcastProperty(target, "phase")
				local thread = room:getThread()
				if not thread:trigger(sgs.EventPhaseStart, room, target) then
					thread:trigger(sgs.EventPhaseProceeding, room, target)
				end
				thread:trigger(sgs.EventPhaseEnd, room, target)

				player:setPhase(sgs.Player_RoundStart)
				room:broadcastProperty(player, "phase")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}

Marisa = sgs.General(extension, "Marisa", "touhou", 4, false, false, false)
Koishi = sgs.General(extension, "Koishi", "touhou", 8, false, false, false)
Satori = sgs.General(extension, "Satori", "touhou", 4, false, false, false)

Marisa:addSkill(se_mopao)
Marisa:addSkill(se_mingqie)
Marisa:addSkill(se_mingqie_target_mod)
Marisa:addSkill(se_mingqie_filter)
extension:insertRelatedSkills("se_mingqie", "#se_mingqie_target_mod")
extension:insertRelatedSkills("se_mingqie", "#se_mingqie_filter")
Koishi:addSkill(se_wushi)
Koishi:addSkill(se_wuyi)
Satori:addSkill(se_kuixin)
Satori:addSkill(se_huixiang)
Satori:addSkill(se_fuzhi)
Satori:addSkill(se_fuzhi_give)
extension:insertRelatedSkills("se_fuzhi$", "#se_fuzhi-give$")

sgs.LoadTranslationTable {
	["touhou"] = "东方",
	["dmptouhou"] = "动漫包-东方",

	["se_mingqie"] = "明窃「魔理沙偷走了重要的东西」",
	["$se_mingqie"] = "",
	[":se_mingqie"] = "每阶段每角色限一次，你指定一名其他角色为唯一目标时，若该角色有装备牌，你可以获得其一张装备区的牌或获得一张手牌并展示：若此牌为黑色，你获得一个P点。你的【过河拆桥】和【顺手牵羊】均视为无视距离限制的【顺手牵羊】",

	["se_mopao"] = "魔炮「终极火花」",
	["$se_mopao"] = "",
	[":se_mopao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>失去4个P点，指定方向和座位，对该路线上的所有角色造成1点伤害。若指定座位的角色装备区没有牌，额外造成2点伤害并将你的武将牌翻面。",
	["se_mopaocard"] = "魔炮「前方高能反应」",
	["se_mopao$"] = "image=image/animate/se_mopao.png",
	["left"] = "左侧",
	["right"] = "右侧",

	["Marisa"] = "霧雨魔理沙",
	["&Marisa"] = "霧雨魔理沙",
	["#Marisa"] = "蘑菇大盗",
	["@p_point"] = "P点",
	["~Marisa"] = "",
	["designer:Marisa"] = "Sword Elucidator",
	["cv:Marisa"] = "",
	["illustrator:Marisa"] = "えふぇ",

	["se_wushi"] = "遗忘「完全遗忘的存在」",
	["$se_wushi"] = "",
	[":se_wushi"] = "<font color=\"blue\"><b>锁定技,</b></font>你与其他角色计算距离时+99，其他角色与你计算距离时+99。",

	["se_wuyi"] = "无意「无意识的花火」",
	["$se_wuyi"] = "",
	[":se_wuyi"] = "<font color=\"blue\"><b>锁定技,</b></font>回合结束时你的最大血量随机变为2-10，以此法失去体力时，你令一名角色摸等同于失去的体力值*2的牌。以此法失去体力上限时，你令一名角色失去一点体力；以此法增长体力上限时，你令一名角色回复一点体力。",
	["se_wuyi_losehp"] = "选择一名角色失去一点体力",
	["se_wuyi_draw"] = "选择一名角色摸牌",
	["se_wuyi_recover"] = "选择一名角色回复一点体力",

	["se_wuyi$"] = "image=image/animate/se_wuyi.png",

	["se_kuixin"] = "窥心",
	["$se_kuixin"] = "",
	[":se_kuixin"] = "出牌阶段，你可以观看与你距离为1的一名其他角色的手牌。",
	["se_kuixincard"] = "窥心",
	["se_kuixin$"] = "image=image/animate/se_kuixin.png",

	["se_huixiang"] = "回想",
	["$se_huixiang"] = "",
	["satori_memory"] = "忆",
	--[":se_huixiang"] = "你的回合外，你以外的角色打出或使用一张基本牌或和非延时锦囊牌结算完毕时，你可将该牌移出游戏，称为“忆”。你的回合开始，你选择“忆”中的X张牌加入手牌，剩余的置于弃牌堆。X为你的血量的一半（向上取整）",
	["@se_huixiang"] = "你可以选择“忆”中的 %src 张牌加入手牌，剩余的置于弃牌堆。",
	["~se_huixiang"] = "选择“忆”中的牌→确定",
	[":se_huixiang"] = "你的回合外，你以外的角色打出或使用一张基本牌或和非延时锦囊牌结算完毕时，你将该牌移出游戏，称为“忆”。你的回合开始，你选择“忆”中的X张牌加入手牌，剩余的置于弃牌堆。X为你的血量的一半（向上取整）",

	["se_fuzhi"] = "赋职",
	["#se_fuzhi_give_message"] = "%from 获得了额外的出牌阶段",
	["$se_fuzhi"] = "",
	["se_fuzhi-invoke"] = "你可以发动“赋职”<br/> <b>操作提示</b>: 选择一名其他东方势力角色→点击确定<br/>",
	["se_fuzhi-card"] = "选择 %dest 张手牌交给 %src →点击确定<br/>",
	[":se_fuzhi"] = "<font color=\"orange\"><b>主公技，</b></font>若你手牌数大于你当前体力值，你可以跳过你的出牌阶段，你可指定一名其他东方势力角色，将手牌数与体力值之差的手牌交给该角色。若如此做，回合结束时，该角色执行一个额外的出牌阶段。",

	["Koishi"] = "古明地恋こいし",
	["&Koishi"] = "古明地恋",
	["#Koishi"] = "紧闭的恋之瞳",
	["~Koishi"] = "",
	["designer:Koishi"] = "Sword Elucidator",
	["cv:Koishi"] = "",
	["illustrator:Koishi"] = "tecoyuke",

	["Satori"] = "古明地覚さとり",
	["&Satori"] = "古明地覚",
	["#Satori"] = "地底的读心少女",
	["~Satori"] = "",
	["designer:Satori"] = "夜华",
	["cv:Satori"] = "",
	["illustrator:Satori"] = "夜华提供",
}

return { extension }
