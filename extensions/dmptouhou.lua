module("extensions.dmptouhou", package.seeall) --游戏包
extension = sgs.Package("dmptouhou") --增加拓展包

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
se_mingqie = sgs.CreateTriggerSkillV2{
	name = "se_mingqie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:hasSkill(skill:objectName()) then
			return false
		end
		local use = data:toCardUse()
		if not use.from or not use.from:hasSkill(skill:objectName()) then
			return false
		end
		if use.to:length() ~= 1 or use.to:contains(use.from) then
			return false
		end
		local to = use.to:at(0)
		if to:getEquips():length() == 0 then
			return false
		end
		if to:hasFlag("se_mingqie_used") then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if not use.from then
			return false
		end
		return use.from:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local from = use.from
		local to = use.to:at(0)
		room:broadcastSkillInvoke(skill:objectName())
		local id = room:askForCardChosen(from, to, "he", skill:objectName())
		room:obtainCard(from, id)
		to:setFlags("se_mingqie_used")
		if sgs.Sanguosha:getCard(id):isBlack() then
			from:gainMark("@p_point")
		end
		return false
	end,
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

se_mingqie_target_mod = sgs.CreateTargetModSkillV2{
	name = "#se_mingqie_target_mod",
	pattern = "Snatch",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit then
			return nil
		end
		return 1000
	end,
}

--魔炮
se_mopao = sgs.CreateViewAsSkillV2{
	name = "se_mopao",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	limit_scope = sgs.Skill_Limit_Phase,
	max_usage_limit = 1,
	phase_name = "Play",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@p_point") > 3
	end,
	can_select_target = function(skill, request, selected, candidate)
		return candidate ~= nil and #selected == 0
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if not source or source:getMark("@p_point") < 4 then
			return false
		end
		source:loseMark("@p_point", 4)
		return true
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then
			return
		end
		local room = source:getRoom()
		local direction = room:askForChoice(source, "se_mopaocard", "left+right")
		local damage = sgs.DamageStruct()
		damage.from = source
		if direction == "right" then
			local next_man = source:getNextAlive()
			while next_man:objectName() ~= target:objectName() do
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

--无意
se_wushi = sgs.CreateDistanceSkillV2{
	name = "se_wushi",
	holder_selector = sgs.CorrectSkill_Participants,
	correct_func = function(skill, ctx)
		local holder = ctx:getHolder()
		local primary = ctx:getPrimary()
		if not holder or not primary then
			return nil
		end
		if holder:objectName() == primary:objectName() then
			return 99
		end
		if not primary:hasSkill(skill:objectName()) then
			return 99
		end
		return nil
	end,
}

--无识
se_wuyi = sgs.CreateTriggerSkillV2{
	name = "se_wuyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Finish
			and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local wore = math.random(2, 10)
		local hp = player:getHp()
		local maxhp = player:getMaxHp()
		if hp - wore > 3 then
			room:doLightbox("se_wuyi$", 1500)
		end
		if wore < maxhp then
			room:loseMaxHp(player, maxhp - wore)
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_losehp", "se_wuyi_losehp")
			if target then
				room:loseHp(target, 1, true, player, skill:objectName())
			end
			if player:getHp() < hp then
				local x = 2 * (hp - player:getHp())
				room:setPlayerMark(player, "se_wuyi-draw", x)
				target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_draw", "se_wuyi_draw")
				if target then
					target:drawCards(2 * (hp - player:getHp()))
				end
			end
		elseif wore > maxhp then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(wore))
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "se_wuyi_recover", "se_wuyi_recover")
			local re = sgs.RecoverStruct()
			re.who = target
			if target then
				room:recover(target, re, true)
			end
		end
		return false
	end,
}

--窥心
se_kuixin = sgs.CreateViewAsSkillV2{
	name = "se_kuixin",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return player ~= nil and candidate ~= nil and #selected == 0
			and candidate:objectName() ~= player:objectName()
			and player:distanceTo(candidate) == 1
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(skill, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target or target:isKongcheng() then
			return
		end
		local room = source:getRoom()
		room:broadcastSkillInvoke("se_kuixin")
		room:doLightbox("se_kuixin$", 800)
		room:showAllCards(target, source)
		room:setPlayerFlag(target, "se_kuixin_used")
	end,
}

--回想
se_huixiangVS = sgs.CreateViewAsSkillV2{
	name = "se_huixiang",
	n = 999,
	expand_pile = "satori_memory",
	will_throw_selected_cards = false,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		return request:getPattern() == "@@se_huixiang"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player or not candidate then
			return false
		end
		local max = math.ceil(player:getHp() / 2)
		if request:getSelectedCardIds():length() >= max then
			return false
		end
		return skill:getExpandPileCardIds(player):contains(candidate:getEffectiveId())
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then
			return false
		end
		local max = math.ceil(player:getHp() / 2)
		local selected = request:getSelectedCardIds():length()
		return selected > 0 and selected <= max
	end,
	on_effect = function(skill, ctx)
		local source = ctx.invoker or ctx.initiator
		if not source or not ctx.use_card then
			return
		end
		local room = source:getRoom()
		room:obtainCard(source, ctx.use_card)
		if source:getPile("satori_memory"):length() > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, cd in sgs.qlist(source:getPile("satori_memory")) do
				dummy:addSubcard(cd)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "se_huixiang", "")
			room:throwCard(dummy, reason, nil)
		end
	end,
}
se_huixiang = sgs.CreateTriggerSkillV2{
	name = "se_huixiang",
	view_as_skill = se_huixiangVS,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardFinished, sgs.CardResponded },
	can_trigger = function(skill, event, room, player, data)
		if not player then
			return false
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start
				and player:hasSkill(skill:objectName())
				and player:getPile("satori_memory"):length() > 0 then
				return skill:objectName()
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card then
				return false
			end
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then
				return false
			end
		elseif event == sgs.CardResponded then
			local use = data:toCardResponse()
			if not use.m_card then
				return false
			end
			if use.m_card:isVirtualCard() then
				return false
			end
			if room:getCardPlace(use.m_card:getEffectiveId()) ~= sgs.Player_PlaceTable then
				return false
			end
			if not use.m_card:isKindOf("BasicCard") and not use.m_card:isKindOf("TrickCard") then
				return false
			end
		else
			return false
		end
		local names = {}
		local owners = {}
		for _, satori in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if satori:getPhase() == sgs.Player_NotActive
				and satori:objectName() ~= player:objectName() then
				table.insert(names, skill:objectName())
				table.insert(owners, satori:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event ~= sgs.EventPhaseStart then
			return true
		end
		local max = math.ceil(player:getHp() / 2)
		if max <= 0 then
			return false
		end
		local prompt = string.format("@se_huixiang:%s", max)
		return room:askForUseCard(player, "@@se_huixiang", prompt) ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			room:broadcastSkillInvoke(skill:objectName())
			return false
		elseif event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if not use.card then
				return false
			end
			if use.card:getSubcards():length() > 0 then
				for _, id in sgs.qlist(use.card:getSubcards()) do
					if room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
						room:broadcastSkillInvoke(skill:objectName())
						player:addToPile("satori_memory", id)
					end
				end
			else
				local id = use.card:getEffectiveId()
				if id ~= -1 and not use.card:isVirtualCard()
					and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
					room:broadcastSkillInvoke(skill:objectName())
					player:addToPile("satori_memory", id)
				end
			end
			return false
		elseif event == sgs.CardResponded then
			local use = ctx.original_data:toCardResponse()
			if use.m_card then
				room:broadcastSkillInvoke(skill:objectName())
				player:addToPile("satori_memory", use.m_card:getEffectiveId())
			end
			return false
		end
		return false
	end,
}

se_fuzhi = sgs.CreateTriggerSkillV2{
	name = "se_fuzhi$",
	events = { sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not player or not ctx.owner
			or player:objectName() ~= ctx.owner:objectName() then
			return
		end
		if not player:hasLordSkill(skill:objectName()) then
			return
		end
		local change = ctx.original_data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
			return
		end
		if not player:hasFlag("se_fuzhi") then
			return
		end
		local target
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("se_fuzhi_target") then
				target = p
			end
		end
		local playerdata = sgs.QVariant()
		playerdata:setValue(target)
		room:setTag("se_fuzhi_givetarget", playerdata)
	end,
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:hasLordSkill(skill:objectName()) then
			return false
		end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Play then
			return false
		end
		if player:isSkipped(sgs.Player_Play) then
			return false
		end
		if player:getHandcardNum() <= player:getHp() then
			return false
		end
		local lieges = room:getLieges("touhou", player)
		if lieges:length() == 0 then
			return false
		end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local lieges = room:getLieges("touhou", player)
		local target = room:askForPlayerChosen(player, lieges, skill:objectName(), "se_fuzhi-invoke", true, true)
		if not target then
			return false
		end
		room:broadcastSkillInvoke("se_fuzhi")
		local x = player:getHandcardNum() - player:getHp()
		local prompt = string.format("se_fuzhi-card:%s:%s", target:objectName(), x)
		local to_obtain = room:askForExchange(player, "se_fuzhi", x, x, false, prompt, false)
		if not to_obtain then
			return false
		end
		ctx.targets:append(target)
		local ids = {}
		for _, id in sgs.qlist(to_obtain:getSubcards()) do
			table.insert(ids, tostring(id))
		end
		ctx.choice = table.concat(ids, "+")
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if ctx.targets:isEmpty() then
			return false
		end
		local target = ctx.targets:first()
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		for s in string.gmatch(ctx.choice or "", "%d+") do
			dummy:addSubcard(tonumber(s))
		end
		room:moveCardTo(dummy, target, sgs.Player_PlaceHand, false)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if not ctx.targets:isEmpty() then
			ctx.targets:first():setFlags("se_fuzhi_target")
		end
		player:setFlags("se_fuzhi")
		player:skip(sgs.Player_Play)
		return false
	end,
}
se_fuzhi_give = sgs.CreateTriggerSkillV2{
	name = "#se_fuzhi-give$",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	priority = 1,
	can_trigger = function(skill, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_NotActive then
			return false
		end
		local tag = room:getTag("se_fuzhi_givetarget")
		if not tag or not tag:toPlayer() then
			return false
		end
		local names = {}
		local owners = {}
		for _, holder in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(owners, holder:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tag = room:getTag("se_fuzhi_givetarget")
		if not tag then
			return false
		end
		local target = tag:toPlayer()
		room:removeTag("se_fuzhi_givetarget")
		if target and target:isAlive() then
			doLog("#se_fuzhi_give_message", target)
			PhaseExtra(target, sgs.Player_Play)
		end
		return false
	end,
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
	[":se_mopao"] = '<font color="green"><b>出牌阶段限一次，</b></font>失去4个P点，指定方向和座位，对该路线上的所有角色造成1点伤害。若指定座位的角色装备区没有牌，额外造成2点伤害并将你的武将牌翻面。',
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
	[":se_wushi"] = '<font color="blue"><b>锁定技,</b></font>你与其他角色计算距离时+99，其他角色与你计算距离时+99。',

	["se_wuyi"] = "无意「无意识的花火」",
	["$se_wuyi"] = "",
	[":se_wuyi"] = '<font color="blue"><b>锁定技,</b></font>回合结束时你的最大血量随机变为2-10，以此法失去体力时，你令一名角色摸等同于失去的体力值*2的牌。以此法失去体力上限时，你令一名角色失去一点体力；以此法增长体力上限时，你令一名角色回复一点体力。',
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
	[":se_fuzhi"] = '<font color="orange"><b>主公技，</b></font>若你手牌数大于你当前体力值，你可以跳过你的出牌阶段，你可指定一名其他东方势力角色，将手牌数与体力值之差的手牌交给该角色。若如此做，回合结束时，该角色执行一个额外的出牌阶段。',

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
