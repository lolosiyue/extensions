module("extensions.leo", package.seeall)
extension = sgs.Package("leo")

--傅佥
leo_fuqian = sgs.General(extension, "leo_fuqian", "shu", "4", true)

luajuesii = sgs.CreateViewAsSkill
	{
		name = "luajuesii",
		n = 0,

		enabled_at_play = function(self, player)
			return player:isWounded()
		end,
		view_filter = function()
			return true
		end,

		view_as = function(self, cards)
			local lcard = luajuesii_card:clone()
			lcard:setSkillName(self:objectName())
			return lcard
		end
	}


luajuesii_card = sgs.CreateSkillCard {
	name = "luajuesii",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		card:setSkillName("luajuesii")
		card:deleteLater()
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		card:setSkillName("luajuesii")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local source = card_use.from
		local room = source:getRoom()
		local use_card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		use_card:setSkillName("luajuesii")
		--use_card:deleteLater()			
		local choice = room:askForChoice(source, "luajuesii", "luajuesii1+luajuesii2")
		if (choice == "luajuesii1") then
			room:loseMaxHp(source, 1)
		else
			room:loseHp(source, 1, true, source, self:objectName())
		end
		return use_card
	end,
}


leo_fuqian:addSkill(luajuesii)

sgs.LoadTranslationTable {
	["leo_fuqian"] = "傅佥",
	["luajuesii"] = "决死",
	[":luajuesii"] = "出牌阶段，若你已经受伤，你可以失去1点体力或体力上限，视为对一名其他角色使用一张【决斗】。",
	["luajuesii1"] = "失去1点体力上限",
	["luajuesii2"] = "失去1点体力",

	--设计者(不写默认为官方)
	["designer:leo_fuqian"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_fuqian"] = "暂无",

	--称号
	["#leo_fuqian"] = "忠勇壮烈",

	--插画(默认为KayaK)
	["illustrator:leo_fuqian"] = "",
}





--张辽
leoshenzhangliao = sgs.General(extension, "leoshenzhangliao", "god", "4", true)

--突袭ex技能卡
luatuxiex_card = sgs.CreateSkillCard
	{
		name = "luatuxiex_card",
		filter = function(self, targets, to_select, player)
			return not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName() and #targets < 1
		end,
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			room:setPlayerFlag(effect.to, "leo_InTempMoving");
			local x = math.max(effect.from:getLostHp(), 1)
			local original_places = sgs.PlaceList()
			local card_ids = sgs.IntList()
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for i = 1, x, 1 do
				card_ids:append(room:askForCardChosen(effect.from, effect.to, "h", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i - 1)))
				dummy:addSubcard(card_ids:at(i - 1))
				effect.to:addToPile("#luatuxiex", card_ids:at(i - 1), false)
				if effect.to:isKongcheng() then break end
			end
			if dummy:subcardsLength() > 0 then
				for i = 1, dummy:subcardsLength(), 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), effect.to, original_places:at(i - 1),
						false)
				end
			end
			room:setPlayerFlag(effect.to, "-leo_InTempMoving")
			effect.from:obtainCard(dummy, false)
			dummy:deleteLater()
			room:broadcastSkillInvoke("tuxi")
		end,
	}
leo_InTempMoving = sgs.CreateTriggerSkill {
	name = "#leo_InTempMoving",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		--[[if player:hasFlag("leo_InTempMoving") then
			return true
		end]]
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("leo_InTempMoving") then return true end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}


local s_skillList = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#leo_InTempMoving") then
	s_skillList:append(leo_InTempMoving)
end

--突袭ex视为技
luatuxiexVS = sgs.CreateViewAsSkill
	{
		name = "luatuxiex",
		n = 0,
		view_as = function(self, cards)
			if #cards == 0 then
				local acard = luatuxiex_card:clone()
				acard:setSkillName(self:objectName())
				return acard
			end
		end,

		enabled_at_play = function(self, player)
			return false
		end,

		enabled_at_response = function(self, player, pattern)
			return pattern == "@@luatuxiex"
		end,
	}


luatuxiex = sgs.CreateTriggerSkill
	{ --突袭ex
		name = "luatuxiex",
		view_as_skill = luatuxiexVS,
		events = { sgs.EventPhaseStart, sgs.DrawNCards },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if (event == sgs.EventPhaseStart) then
				if (player:getPhase() == sgs.Player_Finish) then
					local room = player:getRoom()
					if room:getTag("luatuxiex"):toBool() == false then
						return false
					end
					room:setTag("luatuxiex", sgs.QVariant(false))
					room:askForUseCard(player, "@@luatuxiex", "@luatuxiex")

					return false
				end
			elseif (event == sgs.DrawNCards) then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				if (not room:askForSkillInvoke(player, "luatuxiex")) then
					return false
				else
					room:setTag("luatuxiex", sgs.QVariant(true))
					room:addPlayerMark(player, "&luatuxiex-Clear")
					draw.num = draw.num - 1
					data:setValue(draw)
				end
			end
		end
	}

--轻骑技能卡
luaqingqi_card = sgs.CreateSkillCard
	{
		name = "luaqingqi_card",
		filter = function(self, targets, to_select, player)
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return (not to_select:isAllNude() and to_select:objectName() ~= sgs.Self:objectName() and #targets < 1) or
				(card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets))
		end,
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			local choicelist = "cancel"
			if (effect.from:canSlash(effect.to, nil, false)) then
				choicelist = string.format("%s+%s", choicelist, "luaqingqi1")
			end
			if not effect.to:isAllNude() then
				choicelist = string.format("%s+%s", choicelist, "luaqingqi2")
			end
			local dest = sgs.QVariant()
			dest:setValue(effect.to)
			local choice = room:askForChoice(effect.from, "luaqingqi", choicelist, dest)
			if (choice == "luaqingqi1") then
				room:broadcastSkillInvoke("shensu", 2)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:deleteLater()
				slash:setSkillName(self:objectName())
				local use_card = sgs.CardUseStruct()
				use_card.from = effect.from
				use_card.to:append(effect.to)
				use_card.card = slash
				room:useCard(use_card, false)
			elseif (choice == "luaqingqi2") then
				local card_id = room:askForCardChosen(effect.from, effect.to, "hej", "luaqingqi")
				room:broadcastSkillInvoke("xianzhen", 2)
				effect.from:obtainCard(sgs.Sanguosha:getCard(card_id))
			end
		end
	}

luaqingqiVS = sgs.CreateViewAsSkill
	{ --轻骑视为技
		name = "luaqingqi",
		n = 0,

		view_filter = function()
			return true
		end,

		view_as = function(self, cards)
			local acard = luaqingqi_card:clone()
			acard:setSkillName(self:objectName())
			return acard
		end,

		enabled_at_play = function(self, player)
			return false
		end,

		enabled_at_response = function(self, player, pattern)
			return pattern == "@@luaqingqi"
		end

	}


luaqingqi = sgs.CreateTriggerSkill
	{ --轻骑
		name = "luaqingqi",
		view_as_skill = luaqingqiVS,
		events = { sgs.CardUsed, sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if (event == sgs.CardUsed) and data:toCardUse().card:isKindOf("BasicCard") and player:getPhase() == sgs.Player_Play then
				room:setTag("luaqingqi", sgs.QVariant(false))
				room:setPlayerMark(player, "&luaqingqi-Clear", 0)
			elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
				room:setTag("luaqingqi", sgs.QVariant(true))
				room:addPlayerMark(player, "&luaqingqi-Clear")
			elseif event == sgs.CardsMoveOneTime then
				if player:getPhase() == sgs.Player_Discard then
					local move = data:toMoveOneTime()
					if move.from and (move.from:objectName() == player:objectName())
						and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
						local n = move.card_ids:length()
						if n > 0 and room:getTag("luaqingqi"):toBool() then
							room:setTag("luaqingqi", sgs.QVariant(true))
						else
							room:setTag("luaqingqi", sgs.QVariant(false))
							room:setPlayerMark(player, "&luaqingqi-Clear", 0)
						end
					end
				end
			elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and room:getTag("luaqingqi"):toBool() then
				room:askForUseCard(player, "@@luaqingqi", "@luaqingqi")
			end
		end
	}

leoshenzhangliao:addSkill(luatuxiex)
leoshenzhangliao:addSkill(luaqingqi)

sgs.LoadTranslationTable {
	["leoshenzhangliao"] = "张辽",
	["luatuxiex"] = "突袭",
	["luatuxiex_card"] = "突袭",
	["luatuxiex_"] = "突袭",
	[":luatuxiex"] = "摸牌阶段，你可以少摸一张牌，则回合结束时你可以获得一名其他角色的X张手牌(X为你损失的体力值且至少为1)。",
	["@luatuxiex"] = "请指定一名其他角色发动技能【突袭】",
	["luaqingqi"] = "轻骑",
	["luaqingqi_card"] = "轻骑",
	["luaqingqi_"] = "轻骑",
	[":luaqingqi"] = "弃牌阶段，若你弃置了至少一张手牌，且你于出牌阶段没有使用过基本牌，你可以选择一项：1.视为对一名角色使用了一张【杀】，2.获得一名其他角色区域处的一张牌。",
	["@luaqingqi"] = "是否发动【轻骑】？",
	["luaqingqi1"] = "对该角色使用一张【杀】",
	["luaqingqi2"] = "获得该角色区域处的一张牌",

	--设计者(不写默认为官方)
	["designer:leoshenzhangliao"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leoshenzhangliao"] = "暂无",

	--称号
	["#leoshenzhangliao"] = "威震逍遥津",

	--插画(默认为KayaK)
	["illustrator:leoshenzhangliao"] = "暂无",
}





--吕布
splvbus = sgs.General(extension, "splvbus", "qun", "4", true)

xinwushuangTM = sgs.CreateTargetModSkill {
	name = "#xinwushuangTM",
	pattern = "Duel",
	extra_target_func = function(self, player, card)
		if player:hasSkill("xinwushuang") and (card:getSkillName() == "xinwushuang") then
			return card:subcardsLength() - 1
		else
			return 0
		end
	end,
}
xinwushuangVS = sgs.CreateViewAsSkill { --新无双 by之语
	name = "xinwushuang",
	response_or_use = true,
	n = 998,                        --需要两张牌
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() --非装备
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0) --克隆一张无颜色无点数的决斗
			local i = 0
			while (i < #cards) do
				i = i + 1
				acard:addSubcard(cards[i]) --X张牌成为子卡
				--新增代码
				--
			end
			acard:setSkillName("xinwushuang")
			return acard ----返回这个决斗
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("xinwushuang-SelfPlayClear") == 0
	end,
	enabled_at_response = function(self, pattern)
		return false --不响应打出
	end
}

xinwushuang = sgs.CreateTriggerSkill
{ --争锋 触发技能 by 之语
	name = "xinwushuang",
	events = { sgs.TargetSpecified, sgs.CardEffected, sgs.CardResponded },
	view_as_skill = xinwushuangVS,
	priority = 1,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = false
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") and use.card:getSkillName() == "xinwushuang" then
				if use.from and use.from:isAlive() and use.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if use.card:isKindOf("Duel") then
				room:setPlayerMark(use.from, "xinwushuang-SelfPlayClear",1 )

				local wushuang_tag = {}
				for _, p in sgs.qlist(use.to) do
					table.insert(wushuang_tag, p:objectName())
				end
				room:setTag("Wushuang_"..use.card:toString(), sgs.QVariant(table.concat(wushuang_tag, "+")))
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf("Duel") and effect.to and effect.to:isAlive() then
				local wushuang_tag = room:getTag("Wushuang_"..effect.card:toString()):toString():split("+")
				if table.contains(wushuang_tag, effect.to:objectName()) then
					room:setTag("xinwushuangData",data)
				end
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_toCard and resp.m_toCard:isKindOf("Duel")and not player:hasFlag("xinwushuangSlash") then
				local effect = room:getTag("xinwushuangData"):toCardEffect()
				if resp.m_toCard == effect.card then
					local wushuang_tag = room:getTag("Wushuang_"..effect.card:toString()):toString():split("+")
					if table.contains(wushuang_tag, player:objectName()) then
						room:setPlayerFlag(player,"xinwushuangSlash")
						for i = 1, effect.card:getSubcards():length() - 1, 1 do
							if(not room:askForCard(player,"slash","duel-slash:"..effect.from:objectName(),data, sgs.Card_MethodResponse,effect.from,false,"",false,effect.card))then
								resp.nullified = true
								data:setValue(resp)
								break
							end
						end
						room:setPlayerFlag(player,"-xinwushuangSlash")
						room:addPlayerMark(player, "AI_xinwushuang-Clear")
					end
				end
			end
		end
	end,
}

feijiangts = sgs.CreateTriggerSkill {
	name = "feijiangts",
	events = { sgs.EventPhaseStart, sgs.CardResponded, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local qinggang_sword = nil
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, cd in sgs.qlist(p:getCards("ej")) do
					if cd:isKindOf("Halberd") then
						qinggang_sword = cd
						break
					end
				end
			end
			if qinggang_sword ~= nil and player:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke("wuqian", math.random(1, 2))
				player:obtainCard(qinggang_sword)
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:isKindOf("Slash")) and resp.m_who and (not resp.m_who:isKongcheng()) and player:isLastHandCard(resp.m_card) then
				local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
				end
			end
		else
			local use = data:toCardUse()
			if use.from and (use.from:objectName() == player:objectName()) and use.card and (use.card:isKindOf("Slash")) and player:isLastHandCard(use.card) then
				for _, p in sgs.qlist(use.to) do
					if p:isKongcheng() then continue end
					local _data = sgs.QVariant()
					_data:setValue(p)
					p:setFlags("feijiangtsTarget")
					local invoke = player:askForSkillInvoke(self:objectName(), _data)
					p:setFlags("-feijiangtsTarget")
					if invoke then
						local card_id = room:askForCardChosen(player, p, "h", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
				end
			end
		end
		return false
	end
}


splvbus:addSkill(xinwushuangTM)
splvbus:addSkill(xinwushuang)
extension:insertRelatedSkills("xinwushuang", "#xinwushuangTM")
splvbus:addSkill(feijiangts)

sgs.LoadTranslationTable {
	["splvbus"] = "SP吕布",
	["xinwushuangvs"] = "争锋",
	["xinwushuang"] = "争锋",
	[":xinwushuang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意X张手牌当一张【决斗】使用，以此法使用【决斗】可以至多指定X名目标角色，且每名目标角色每次须连续打出X张【杀】。",
	["xinwushuangts"] = "争锋ts",
	["xinwushuangvs_card"] = "争锋",
	["@xinwushuang-slash"] = "%src 对你【决斗】，你须连续打出 %dest 张【杀】",

	[":xinwushuangvs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意X张手牌当一张【决斗】使用，以此法使用【决斗】可以至多指定X名目标角色，且每名目标角色每次须连续打出X张【杀】。",

	["feijiangts"] = "飞将",
	[":feijiangts"] = "若你使用或打出的【杀】是你最后一张手牌，你可以获得对方的一张牌。",


	--设计者(不写默认为官方)
	["designer:splvbus"] = "leowebber，之语，晴心~雨忆~", --lua制作：之语; 构思：leowebber

	--配音(不写默认为官方)
	["cv:splvbus"] = "暂无",

	--称号
	["#splvbus"] = "无双飞将",

	--插画(默认为KayaK)
	["illustrator:splvbus"] = "未知",
}





--王基
leo_wangji = sgs.General(extension, "leo_wangji", "wei", "4", true)

luayuanlue = sgs.CreateViewAsSkill
	{
		name = "luayuanlue",
		n = 0,
		enabled_at_play = function(self, player)
			return not player:hasUsed("#luayuanlue")
		end,


		view_filter = function(self, selected, to_select)
			return true
		end,

		view_as = function(self, cards)
			local lcard = luayuanlue_card:clone()
			lcard:setSkillName(self:objectName())
			return lcard
		end
	}

luayuanlue_card = sgs.CreateSkillCard
	{
		name = "luayuanlue",


		filter = function(self, targets, to_select)
			if #targets > 0 then return false end
			local handcardnum = to_select:getHandcardNum()
			local hp = to_select:getHp()
			return handcardnum > hp or handcardnum < hp
		end,

		on_effect = function(self, effect)
			local to = effect.to
			local from = effect.from
			local room = effect.from:getRoom()
			local handcardnum = to:getHandcardNum()
			local hp = to:getHp()
			local x = math.min(math.abs(handcardnum - hp), 4)
			if handcardnum > hp then
				room:broadcastSkillInvoke("qiaobian", 3)
				x = handcardnum - hp
				if x > 4 then x = 4 end
				room:askForDiscard(to, "luayuanlue", x, x, false, false)
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = to
				room:recover(to, recover)
			elseif handcardnum < hp then
				room:broadcastSkillInvoke("xianzhen", 1)
				x = hp - handcardnum
				if x > 4 then x = 4 end
				to:drawCards(x)
				room:loseHp(to, 1, true, from, self:objectName())
			end
		end
	}



leo_wangji:addSkill(luayuanlue)

sgs.LoadTranslationTable {
	["leo_wangji"] = "王基",
	["luayuanlue"] = "远略",
	[":luayuanlue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名手牌数大于体力值的角色，令其弃置X张手牌并回复1点体力，或指定一名手牌数小于体力值的角色，令其摸X张牌并失去1点体力（X为手牌数与体力值之差且至多为4）。",
	["luayuanlue_card"] = "远略",

	--设计者(不写默认为官方)
	["designer:leo_wangji"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_wangji"] = "暂无",

	--称号
	["#leo_wangji"] = "文武兼备",

	--插画(默认为KayaK)
	["illustrator:leo_wangji"] = "三国群英传",
}




--姜维
spjw = sgs.General(extension, "spjw", "shu", "4", true)


luajiezhiVS = sgs.CreateViewAsSkill {
	name = "luajiezhi",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card_id = sgs.Self:getMark("luajiezhiskill")
		local card = sgs.Sanguosha:getCard(card_id)
		local acard = cards[1]
		local new_card = sgs.Sanguosha:cloneCard(card:objectName(), acard:getSuit(), acard:getNumber())
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return player:hasFlag("luajiezhix")
	end,
}


luajiezhi = sgs.CreateTriggerSkill {
	name = "luajiezhi",
	events = { sgs.CardUsed },
	view_as_skill = luajiezhiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardUse().card
		if (player:getPhase() ~= sgs.Player_Play) then return false end
		if event == sgs.CardUsed and not player:hasFlag("luajiezhiused") and not card:isKindOf("Nullification") then
			if (card:isNDTrick() or card:isKindOf("BasicCard")) and card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if not card:isVirtualCard() then
					room:setPlayerFlag(player, "luajiezhix")
					local card_id = card:getEffectiveId()

					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "luajiezhiMark") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
					end
					room:setPlayerMark(player, "&luajiezhiMark+" .. card:objectName() .. "+-Clear", 1)



					room:setPlayerMark(player, "luajiezhiskill", card_id)
				end
				if card:getSkillName() == "luajiezhi" then
					room:setPlayerFlag(player, "luajiezhiused")
					room:setPlayerFlag(player, "-luajiezhix")
					local use = data:toCardUse()
					use.m_addHistory = false
					data:setValue(use)
				end
			end
		end
	end
}
luajiezhiTargetMod = sgs.CreateTargetModSkill {
	name = "#luajiezhi",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("luajiezhi") and card:getSkillName() == "luajiezhi" then
			return 999
		else
			return 0
		end
	end,
}




spjw:addSkill(luajiezhi)
spjw:addSkill(luajiezhiTargetMod)
extension:insertRelatedSkills("luajiezhi", "#luajiezhi")
spjw:addSkill("zhiji")
spjw:addRelateSkill("guanxing")

sgs.LoadTranslationTable {
	["spjw"] = "姜维",
	["luajiezhi"] = "竭智",
	[":luajiezhi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可将一张手牌当上一张你使用的基本牌或非延时锦囊使用，以此法使用的【杀】不受出牌阶段限制。",
	["luajiezhiMark"] = "竭智",
	["@jiezhiused"] = "竭智",
	["luazhiji1"] = "摸两张牌",
	["luazhiji2"] = "回复1点体力",

	--设计者(不写默认为官方)
	["designer:spjw"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spjw"] = "暂无",

	--称号
	["#spjw"] = "天水异才",

	--插画(默认为KayaK)
	["illustrator:spjw"] = "真三国无双",
}





--马超
leo_spmachao = sgs.General(extension, "leo_spmachao", "qun", "4", true)



luafeiqi = sgs.CreateTriggerSkill
	{
		name = "luafeiqi",
		events = { sgs.TargetSpecified, sgs.CardResponded, sgs.CardUsed },
		frequency = sgs.Skill_Frequent,

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if (event == sgs.TargetSpecified) then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash") then
					for _, p in sgs.qlist(use.to) do
						if player:canDiscard(p, "h") then
							local tohelp = sgs.QVariant()
							tohelp:setValue(p)
							if room:askForSkillInvoke(player, "luafeiqi", tohelp) then
								local card_id = room:askForCardChosen(player, p, "h", "luafeiqi")
								room:throwCard(card_id, p)
								room:broadcastSkillInvoke("longdan", 2)
							end
						end
					end
				end
			elseif (event == sgs.CardResponded) then
				local card = data:toCardResponse().m_card
				if (not card:isKindOf("Jink")) then return false end
				if room:askForSkillInvoke(player, "luafeiqi") then
					player:drawCards(1)
					room:broadcastSkillInvoke("longdan", 1)
				end
			elseif (event == sgs.CardUsed) then
				local card = data:toCardUse().card
				if (not card:isKindOf("Jink")) then return false end
				if room:askForSkillInvoke(player, "luafeiqi") then
					player:drawCards(1)
					room:broadcastSkillInvoke("longdan", 1)
				end
			end
		end
	}

luazhuixi_card = sgs.CreateSkillCard
	{
		name = "luazhuixi",
		--target_fixed = false,
		--will_throw = true,

		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			room:setFixedDistance(effect.from, effect.to, 1)
			local data = sgs.QVariant()
			data:setValue(effect.to)
			effect.from:setTag("luazhuixiTarget", data)
			room:addPlayerMark(effect.to, "&luazhuixi+to+#" .. effect.from:objectName() .. "-Clear")
		end
	}

luazhuixi_viewas = sgs.CreateViewAsSkill
	{
		name = "luazhuixi",
		n = 1,

		view_filter = function()
			return true
		end,

		view_as = function(self, cards)
			if (#cards ~= 1) then return nil end
			local acard = luazhuixi_card:clone()
			acard:addSubcard(cards[1])
			acard:setSkillName(self:objectName())
			return acard
		end,

		enabled_at_play = function(self, player)
			return false
		end,

		enabled_at_response = function(self, player, pattern)
			return pattern == "@@luazhuixi"
		end

	}


luazhuixi = sgs.CreateTriggerSkill {
	name = "luazhuixi",
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	view_as_skill = luazhuixi_viewas,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				local target = player:getTag("luazhuixiTarget"):toPlayer()
				if target then
					room:removeFixedDistance(player, target, 1)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				room:askForUseCard(player, "@@luazhuixi", "@luazhuixi_card")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}


leo_spmachao:addSkill(luafeiqi)
leo_spmachao:addSkill(luazhuixi)

sgs.LoadTranslationTable {
	["leo_spmachao"] = "SP马超",
	["luafeiqi"] = "飞骑",
	[":luafeiqi"] = "每当你指定【杀】的目标后，你可以弃置目标角色的一张手牌；每当你使用或打出一张【闪】时，你可以摸一张牌。",
	["@luazhuixi_card"] = "请指定一名角色发动【追袭】",
	["luazhuixi"] = "追袭",
	[":luazhuixi"] = "出牌阶段开始时，你可以弃置一张牌并指定一名其他角色，你与该角色的距离视为1，直至回合结束。",
	["luazhuixi_"] = "追袭",


	--设计者(不写默认为官方)
	["designer:leo_spmachao"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leo_spmachao"] = "暂无",

	--称号
	["#leo_spmachao"] = "一骑当千",

	--插画(默认为KayaK)
	["illustrator:leo_spmachao"] = "暂无",
}





--魏延
spwy = sgs.General(extension, "spwy", "shu", "4", true)

luayongluecard = sgs.CreateSkillCard {
	name = "luayonglue",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		if (#targets > 0) then return false end
		if (to_select == self) then return false end
		return not to_select:isKongcheng() or to_select:hasEquip()
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(source, targets[1], "he", "luayonglue")
		local card = sgs.Sanguosha:getCard(card_id)
		room:throwCard(card, targets[1])
		room:broadcastSkillInvoke("toudu", 1)
		room:setFixedDistance(source, targets[1], 1)
		local target = player2serverplayer(room, targets[1])
		room:addPlayerMark(target, "&luayonglue+to+#" .. source:objectName() .. "+-Clear")
	end,
}

luayongluevs = sgs.CreateViewAsSkill {
	name = "luayonglue",
	n = 0,
	view_as = function(self, cards)
		return luayongluecard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@luayonglue"
	end,
}

luayonglue = sgs.CreateTriggerSkill {
	name = "luayonglue",
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	view_as_skill = luayongluevs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DrawNCards) then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local can_invoke = false
			local other = room:getOtherPlayers(player)
			for _, aplayer in sgs.qlist(other) do
				if player:canDiscard(aplayer, "he") then
					can_invoke = true
					break
				end
			end
			if can_invoke and room:askForUseCard(player, "@@luayonglue", "@luayongluecard") then
				draw.num = draw.num - 1
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Finish) then
			local players = room:getAllPlayers()
			for _, p in sgs.qlist(players) do
				room:removeFixedDistance(player, p, 1)
			end
		end
	end,
}



luaqingzhanRecord = sgs.CreateTriggerSkill {
	name = "#luaqingzhanRecord",
	events = { sgs.PreCardUsed, sgs.CardResponded },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if card:isKindOf("Slash") then
					local ids = sgs.IntList()
					if not card:isVirtualCard() then
						ids:append(card:getEffectiveId())
					else
						if card:subcardsLength() > 0 then
							ids = card:getSubcards()
						end
					end
					if not ids:isEmpty() then
						room:setCardFlag(card, "luaqingzhan")
						local pdata, cdata = sgs.QVariant(), sgs.QVariant()
						pdata:setValue(player)
						cdata:setValue(card)
						room:setTag("luaqingzhan_user", pdata)
						room:setTag("luaqingzhan_card", cdata)
					end
				end
			end
		end
		return false
	end
}
luaqingzhan = sgs.CreateTriggerSkill {
	name = "luaqingzhan",
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.card_ids:isEmpty() then return false end
		if not (move.from and move.from:isAlive()) then return false end
		local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile and
			(basic == sgs.CardMoveReason_S_REASON_USE) then
			local yongjue_user = room:getTag("luaqingzhan_user"):toPlayer()
			local yongjue_card = room:getTag("luaqingzhan_card"):toCard()
			room:removeTag("luaqingzhan_card")
			room:removeTag("luaqingzhan_user")
			if yongjue_card and yongjue_user and yongjue_card:hasFlag("luaqingzhan") and move.from:objectName() == yongjue_user:objectName() and not yongjue_user:hasSkill(self:objectName()) then
				local ids = sgs.IntList()
				if not yongjue_card:isVirtualCard() then
					ids:append(yongjue_card:getEffectiveId())
				else
					if yongjue_card:subcardsLength() > 0 then
						ids = yongjue_card:getSubcards()
					end
				end
				if not ids:isEmpty() then
					for _, id in sgs.qlist(ids) do
						if not move.card_ids:contains(id) then return false end
					end
				else
					return false
				end
				if room:askForDiscard(player, "luaqingzhan", 1, 1, true, true) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in sgs.qlist(ids) do
						slash:addSubcard(id)
					end
					player:obtainCard(slash)
					slash:deleteLater()
					move.card_ids = sgs.IntList()
					data:setValue(move)
				end
			end
		end
		return false
	end
}

spwy:addSkill(luayonglue)
spwy:addSkill(luaqingzhan)
spwy:addSkill(luaqingzhanRecord)
extension:insertRelatedSkills("luaqingzhan", "#luaqingzhanRecord")






sgs.LoadTranslationTable {
	["spwy"] = "魏延",
	["luayonglue"] = "勇略",
	[":luayonglue"] = "摸牌阶段，你可以摸少一张牌，并弃置一名其他角色的一张牌，则你与该角色的距离视为1，直至回合结束。",
	["@luayongluecard"] = "请指定一名角色发动技能【勇略】",
	["luaqingzhan"] = "请战",
	[":luaqingzhan"] = "其他角色使用的【杀】进入弃牌堆时，你可以用一张牌替换之。",


	--设计者(不写默认为官方)
	["designer:spwy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spwy"] = "暂无",

	--称号
	["#spwy"] = "奇袭关中",

	--插画
	["illustrator:spwy"] = "三国志大战",

}








--神典韦
sdw = sgs.General(extension, "sdw", "god", "5", true)



--忠魂触发技
luazhonghun = sgs.CreateTriggerSkill
	{
		name = "luazhonghun",
		events = { sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.DamageInflicted },
		can_trigger = function(self, target)
			return true
		end,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if player:hasSkill("luazhonghun") and event == sgs.EventPhaseStart then
				if (player:getPhase() == sgs.Player_RoundStart) then
					local players = room:getAllPlayers()
					for _, p in sgs.qlist(players) do
						if (p:getMark("&luazhonghun+to+#" .. player:objectName())) then
							room:setPlayerMark(p, "&luazhonghun+to+#" .. player:objectName(), 0)
						end
					end
				end
			elseif event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive and player:hasSkill("luazhonghun") then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"luazhonghun-invoke", true, true)
					if not target then return false end
					--target:gainMark("@zhonghuned")
					room:addPlayerMark(target, "&luazhonghun+to+#" .. player:objectName())
				end
			elseif not player:hasSkill("luazhonghun") and event == sgs.DamageInflicted then
				local damage = data:toDamage()
				local target
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (p:hasSkill("luazhonghun")) then
						if (player:getMark("&luazhonghun+to+#" .. p:objectName()) > 0) then
							room:broadcastSkillInvoke("ganglie")
							target = p
							break
						end
					end
				end
				if not target then return false end
				local newdamage = damage
				newdamage.to = target
				newdamage.transfer = true
				room:damage(newdamage)
				return true
			end
			return false
		end
	}

--死战距离技
luasizhanjl = sgs.CreateAttackRangeSkill {
	name = "luasizhanjl",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("luasizhanjl") then
			return player:getMark("&luasizhanjl")
		end
	end,
}
luasizhanjl_t = sgs.CreateTriggerSkill
	{
		name = "#luasizhanjl_t",
		events = { sgs.Damaged },

		on_trigger = function(self, event, player, data)
			if event == sgs.Damaged then
				local room = player:getRoom()
				local damage = data:toDamage()
				room:addPlayerMark(player, "&luasizhanjl", damage.damage)
			end
		end
	}


--猛袭触发技
luamengxi = sgs.CreateTriggerSkill
	{
		name = "luamengxi",
		events = { sgs.Predamage },

		on_trigger = function(self, event, player, data)
			if event == sgs.Predamage then
				if (player:getMark("&luasizhanjl") > 0) then
					local damage = data:toDamage()
					local room = player:getRoom()
					local reason = damage.card
					if (not reason) then return false end
					if (reason:isKindOf("Slash") or reason:isKindOf("Duel"))
						and (room:askForSkillInvoke(player, "luamengxi", data)) then
						room:broadcastSkillInvoke("qiangxi")
						--player:loseMark("@struggle")
						room:removePlayerMark(player, "&luasizhanjl")
						damage.damage = damage.damage + 1
						data:setValue(damage)
						local log = sgs.LogMessage()
						log.type = "#skill_add_damage"
						log.from = damage.from
						log.to:append(damage.to)
						log.arg  = self:objectName()
						log.arg2 = damage.damage
						player:getRoom():sendLog(log)
						return false
					end
				else
					return false
				end
			end
		end
	}

--决死
luajuesi = sgs.CreateFilterSkill {
	name = "luajuesi",
	view_filter = function(self, to_select)
		return (to_select:isBlack() and to_select:isNDTrick()) or (to_select:isKindOf("EquipCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local filtered = nil
		if (card:isBlack() and card:isNDTrick()) then
			local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
			filtered = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
			filtered:takeOver(duel)
		elseif (card:isKindOf("EquipCard")) then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:setSkillName(self:objectName())
			filtered = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
			filtered:takeOver(slash)
		end
		return filtered
	end
}


sdw:addSkill(luazhonghun)
sdw:addSkill(luasizhanjl)
sdw:addSkill(luasizhanjl_t)
extension:insertRelatedSkills("luasizhanjl", "#luasizhanjl_t")
sdw:addSkill(luamengxi)
sdw:addSkill(luajuesi)

sgs.LoadTranslationTable {
	["sdw"] = "典韦",
	["luazhonghun"] = "忠魂",
	["@luazhonghun"] = "忠魂",
	[":luazhonghun"] = "回合结束时，你可以指定一名其他角色，该角色受到伤害时均由你承受此伤害，直至下回合开始。",
	["@luazhonghun_card"] = "请指定一名角色发动技能忠魂",
	["luazhonghun-invoke"] = "你可以发动“忠魂”<b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["luasizhanjl"] = "死战",
	[":luasizhanjl"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到1点伤害后，你获得1枚死战标记，每有1枚死战标记，你的攻击范围+1。",
	["luamengxi"] = "猛袭",
	[":luamengxi"] = "你使用【杀】或【决斗】造成伤害时，你可以弃置1枚死战标记令此伤害+1。",
	["luajuesi"] = "决死",
	[":luajuesi"] = "<font color=\"blue\"><b>锁定技，</b></font>你的黑色非延时锦囊均视为【决斗】，你的装备牌均视为【杀】。",

	--设计者(不写默认为官方)
	["designer:sdw"] = "leowebber",

	--配音(不写默认为官方)
	["cv:sdw"] = "暂无",

	--称号
	["#sdw"] = "宛城的死士",

	--插画(默认为KayaK)
	["illustrator:sdw"] = "火凤燎原",
}





--诸葛亮
spwolong = sgs.General(extension, "spwolong", "shu", "3", true)

--帷幄
luaweiwo = sgs.CreateTriggerSkill
	{
		name = "luaweiwo",
		events = { sgs.EventPhaseChanging },
		frequency = sgs.Skill_Frequent,

		on_trigger = function(self, event, player, data)
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				local room = player:getRoom()
				if player:askForSkillInvoke(self:objectName()) then
					player:drawCards(3)
					--将x张手牌依次置于牌堆顶
					local x = player:getHp()
					if (x > 3) then x = 3 end
					local card_ids = sgs.IntList()
					for _, cd in sgs.qlist(player:getHandcards()) do
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
					for var = 1, x, 1 do
						room:fillAG(card_ids, player)
						local cdid = room:askForAG(player, card_ids, false, self:objectName())
						room:setPlayerFlag(player, "Global_GongxinOperator")
						room:moveCardTo(sgs.Sanguosha:getCard(cdid), player, nil, sgs.Player_DrawPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "luaweiwo", ""),
							true)
						card_ids:removeOne(cdid)
						room:setPlayerFlag(player, "-Global_GongxinOperator")
						room:clearAG(player)
					end
				end
			end
			return false
		end
	}

--决胜
luajuesheng = sgs.CreateTriggerSkill
	{
		name = "luajuesheng",
		events = { sgs.Predamage },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(self, target)
			return target
		end,

		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local room = player:getRoom()
			local reason = damage.card
			if (not reason) then return false end
			if reason:isKindOf("Slash") then
				for _, spwolong in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local tohelp = sgs.QVariant()
					tohelp:setValue(damage.from)
					room:setPlayerFlag(spwolong, "luajueshengTarget")
					if room:askForSkillInvoke(spwolong, "luajuesheng", tohelp) then
						room:broadcastSkillInvoke("mingce", math.random(1, 2))
						damage.from:drawCards(1, self:objectName())
					end
					room:setPlayerFlag(spwolong, "-luajueshengTarget")
				end
			end
			return false
		end
	}

spwolong:addSkill(luaweiwo)
spwolong:addSkill(luajuesheng)

sgs.LoadTranslationTable {
	["spwolong"] = "SP诸葛亮",
	["luaweiwo"] = "帷幄",
	[":luaweiwo"] = "回合结束时，你可以摸3张牌，并将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",
	["luajuesheng"] = "决胜",
	[":luajuesheng"] = "一名角色使用【杀】造成伤害时，你可以令该角色摸一张牌。",


	--设计者(不写默认为官方)
	["designer:spwolong"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spwolong"] = "暂无",

	--称号
	["#spwolong"] = "卧龙",

	--插画(默认为KayaK)
	["illustrator:spwolong"] = "北",
}





--刘备
lgz = sgs.General(extension, "lgz", "shu", "3", true)

luajieyicard = sgs.CreateSkillCard {
	name = "luajieyicard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if (#targets > 1) then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		local jieyiflag = false
		--让指定角色选择一张手牌
		local cardid1 = room:askForCardChosen(targets[1], targets[1], "h", "luajieyivs")
		local card1 = sgs.Sanguosha:getCard(cardid1)
		local cardid2
		local card2
		if #targets == 1 then
			if (self:isRed() and card1:isRed())
				or (self:isBlack() and card1:isBlack()) then
				jieyiflag = true
			end
		elseif #targets > 1 then
			cardid2 = room:askForCardChosen(targets[2], targets[2], "h", "luajieyivs")
			card2 = sgs.Sanguosha:getCard(cardid2)
			if (self:isRed() and card1:isRed() and card2:isRed())
				or (self:isBlack() and card1:isBlack() and card2:isBlack()) then
				jieyiflag = true
			end
		end
		--依次展示手牌
		room:showCard(source, self:getEffectiveId())
		room:showCard(targets[1], card1:getEffectiveId())
		if #targets > 1 then
			room:showCard(targets[2], card2:getEffectiveId())
		end
		--如果颜色相同
		if jieyiflag then
			local choice = room:askForChoice(source, "luajieyi", "luajieyi1+luajieyi2")
			if (choice == "luajieyi1") then --各摸一张牌
				source:drawCards(1)
				targets[1]:drawCards(1)
				if #targets > 1 then targets[2]:drawCards(1) end
			else --弃牌回复体力
				local recover = sgs.RecoverStruct()
				recover.recover = 1

				room:throwCard(self, source)
				recover.who = source
				room:recover(source, recover)

				room:throwCard(card1, targets[1])
				recover.who = targets[1]
				room:recover(targets[1], recover)

				if #targets > 1 then
					room:throwCard(card2, targets[2])
					recover.who = targets[2]
					room:recover(targets[2], recover)
				end
			end
		end
	end,
}

luajieyi = sgs.CreateViewAsSkill {
	name = "luajieyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local card = luajieyicard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		card:setSuit(cards[1]:getSuit())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luajieyicard")
	end,
}

luafuweicard = sgs.CreateSkillCard {
	name = "luafuweicard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if (#targets > 0) then return false end
		if (to_select:getHandcardNum() > player:getHandcardNum()) then return false end
		return to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		targets[1]:obtainCard(self)
	end,
}

luafuweivs = sgs.CreateViewAsSkill {
	name = "luafuwei",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local card = luafuweicard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@luafuwei"
	end,
}

luafuwei = sgs.CreateTriggerSkill {
	name = "luafuwei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = luafuweivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Play) then
			player:drawCards(1)
			local invoke = false
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() <= player:getHandcardNum() then
					invoke = true
				end
			end
			if invoke then
				room:askForUseCard(player, "@@luafuwei", "@luafuweicard")
			end
			return false
		end
	end,
}
luafuwei_h = sgs.CreateMaxCardsSkill {
	name = "#luafuwei_h",
	extra_func = function(self, target)
		if target:hasSkill("luafuwei") then
			return 2
		else
			return 0
		end
	end
}


lgz:addSkill(luajieyi)
lgz:addSkill(luafuwei)
lgz:addSkill(luafuwei_h)
extension:insertRelatedSkills("luafuwei", "#luafuwei_h")

sgs.LoadTranslationTable {
	["lgz"] = "刘备",
	["luajieyi"] = "结义",
	[":luajieyi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定至多两名其他角色与你各展示一张牌，若颜色相同，你与该角色各摸一张牌，或弃置所展示的牌然后各回复1点体力。",
	["@luajieyicard"] = "请指定一至两名角色发动技能【结义】",
	["luajieyi1"] = "各摸一张牌",
	["luajieyi2"] = "弃置此牌回复1点体力",
	["luafuwei"] = "扶危",
	[":luafuwei"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限始终+2，出牌阶段开始时，你摸一张牌，然后将一张手牌交给一名手牌数不大于你的角色。",
	["@luafuweicard"] = "请指定一名角色发动技能【扶危】",


	--设计者(不写默认为官方)
	["designer:lgz"] = "leowebber",

	--配音(不写默认为官方)
	["cv:lgz"] = "暂无",

	--称号
	["#lgz"] = "桃园义士",

	--插画(默认为KayaK)
	["illustrator:lgz"] = "三国游侠",
}





--关羽
wzgy = sgs.General(extension, "wzgy", "shu", "4", true)


--虎踞

luahuju = sgs.CreateTriggerSkill {
	name = "luahuju",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local getKingdoms = function() --可以在函数中定义函数
			local kingdoms = {}
			local kingdom_number = 0
			local players = room:getAlivePlayers()
			for _, aplayer in sgs.qlist(players) do
				if not kingdoms[aplayer:getKingdom()] then
					kingdoms[aplayer:getKingdom()] = true
					kingdom_number = kingdom_number + 1
				end
			end
			if kingdom_number > 3 then kingdom_number = 3 end
			return kingdom_number
		end
		local num = player:getHandcardNum()
		local lost = getKingdoms()
		if num >= lost then return end
		if player:getPhase() ~= sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from:objectName() == player:objectName() then
					room:sendCompulsoryTriggerLog(player, "luahuju", true)
					player:drawCards(lost - num)
					room:broadcastSkillInvoke("luahuju")
				end
			elseif event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_NotActive then
				room:sendCompulsoryTriggerLog(player, "luahuju", true)
				player:drawCards(lost - num)
			end
		end
	end
}


wzgy:addSkill(luahuju)

sgs.LoadTranslationTable {
	["wzgy"] = "关羽",
	["luahuju"] = "虎踞",
	[":luahuju"] = "<font color=\"blue\"><b>锁定技，</b></font>回合外你的手牌数至少为X(X为场上现存的势力数且至多为3)。",


	--设计者(不写默认为官方)
	["designer:wzgy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:wzgy"] = "暂无",

	--称号
	["#wzgy"] = "威震华夏",

	--插画(默认为KayaK)
	["illustrator:wzgy"] = "",
}





--司马兄弟
simabro = sgs.General(extension, "simabro", "jin", "4", true)

--擅权

luashanquan_card = sgs.CreateSkillCard
	{
		name = "luashanquan",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			if #targets > 0 or to_select:isKongcheng() then return false end
			return to_select:objectName() ~= player:objectName()
		end,

		on_use = function(self, room, source, targets)
			if (#targets ~= 1) then return end
			local target = targets[1]
			room:setPlayerFlag(target, "leo_InTempMoving");
			local original_places = sgs.PlaceList()
			local card_ids = sgs.IntList()
			local y = 0
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for i = 1, target:getMaxHp(), 1 do
				card_ids:append(room:askForCardChosen(source, target, "h", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i - 1)))
				dummy:addSubcard(card_ids:at(i - 1))
				target:addToPile("#luashanquan", card_ids:at(i - 1), false)
				if target:isKongcheng() then break end
			end
			if dummy:subcardsLength() > 0 then
				for i = 1, dummy:subcardsLength(), 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1), false)
				end
			end
			room:setPlayerFlag(target, "-leo_InTempMoving")
			local x = dummy:subcardsLength()
			source:obtainCard(dummy, false)
			dummy:deleteLater()
			local to_goback
			local prompt = string.format("@luashanquanmove:%s", x)
			to_goback = room:askForExchange(source, self:objectName(), x, x, true, prompt)
			room:obtainCard(target, to_goback, false)
		end
	}


luashanquan = sgs.CreateViewAsSkill
	{
		name = "luashanquan",
		n = 0,
		view_as = function(self, cards)
			if #cards == 0 then
				local acard = luashanquan_card:clone()
				acard:setSkillName(self:objectName())
				return acard
			end
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#luashanquan")
		end,

		enabled_at_response = function(self, player, pattern)
			return false
		end,
	}


--继业
luajiye = sgs.CreateTriggerSkill {
	name = "luajiye",
	frequency = sgs.Skill_Wake,
	waked_skills = "fankui,lianpo",
	events = { sgs.EventPhaseStart },
	--[[can_trigger = function(self,target)
  return target:hasSkill("luajiye") and (target:getMark("luajiye") == 0)
end,]]
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local x = 999
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, p:getHp())
		end
		if player:getHp() <= x then return true end
		return false
	end,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Start then return false end
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			player:drawCards(2)
			room:handleAcquireDetachSkills(player, "fankui")
			room:handleAcquireDetachSkills(player, "lianpo")
			room:addPlayerMark(player, "luajiye")
			return false
		end
	end,
}


simabro:addSkill(luashanquan)
simabro:addSkill(luajiye)

sgs.LoadTranslationTable {
	["simabro"] = "司马兄弟",
	["luashanquan"] = "擅权",
	[":luashanquan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名其他角色的至多X张手牌(X为该角色的体力上限)，然后你交还等量的牌。",
	["@luashanquanmove"] = "擅权\
请返還%src张牌",
	["luajiye"] = "继业",
	[":luajiye"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为场上最少（或之一），你失去1点体力上限，摸两张牌，并获得“反馈”和“连破”。",

	--设计者(不写默认为官方)
	["designer:simabro"] = "leowebber",

	--配音(不写默认为官方)
	["cv:simabro"] = "暂无",

	--称号
	["#simabro"] = "开晋二帝",

	--插画(默认为KayaK)
	["illustrator:simabro"] = "三国无双",
}





--文鸯
leowenyang = sgs.General(extension, "leowenyang", "wei", "4", true)

--骁猛
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

luaxiaomeng = sgs.CreateTriggerSkill {
	name = "luaxiaomeng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:distanceTo(p) <= 1 then
					local room = player:getRoom()
					local log = sgs.LogMessage()
					log.type = "#skill_cant_jink"
					log.from = player
					log.to:append(p)
					log.arg = self:objectName()
					room:sendLog(log)
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and (player:distanceTo(effect.from) < 2) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("longdan", 1)
				local log = sgs.LogMessage()
				log.type = "#SkillNullify"
				log.arg = self:objectName()
				log.from = effect.to
				log.arg2 = effect.card:objectName()
				room:sendLog(log)
				return true
			end
		end
	end
}


--突围
luatuwei = sgs.CreateTriggerSkill {
	name = "luatuwei",
	frequency = sgs.Skill_Wake,
	waked_skills = "mashu",
	events = { sgs.EventPhaseStart },
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local x = 999
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			x = math.min(x, p:getHp())
		end
		if player:getHp() <= x then return true end
		return false
	end,
	on_trigger = function(self, event, player, data, room)
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			room:handleAcquireDetachSkills(player, "mashu")
			room:addPlayerMark(player, "luatuwei")
			return false
		end
	end,
}


leowenyang:addSkill(luaxiaomeng)
leowenyang:addSkill(luatuwei)

sgs.LoadTranslationTable {
	["leowenyang"] = "文鸯",
	["luaxiaomeng"] = "骁猛",
	[":luaxiaomeng"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离1以内的角色使用的【杀】不可被闪避，距离1以内的角色对你使用的【杀】无效。",
	["luatuwei"] = "突围",
	[":luatuwei"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为场上最少（或之一），你失去1点体力上限，并获得“马术”。",

	--设计者(不写默认为官方)
	["designer:leowenyang"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leowenyang"] = "暂无",

	--称号
	["#leowenyang"] = "单骑退雄兵",

	--插画(默认为KayaK)
	["illustrator:leowenyang"] = "三国战魂",
}


zhaoyungd = sgs.General(extension, "zhaoyungd", "shu", "4", true)

luakongying = sgs.CreateDistanceSkill
	{
		name = "luakongying",
		correct_func = function(self, from, to)
			if to:hasSkill("luakongying") and to:isKongcheng() then
				return 1
			end
		end,
	}


luagudan = sgs.CreateViewAsSkill {
	name = "luagudan",
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isEquipped()
		else
			if selected[1]:isEquipped() then
				return false
			end
		end
	end,
	view_as = function(self, cards)
		local card
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() == "slash") then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if #cards > 0 then
				--card = luagudanCard:clone()

				for _, cd in ipairs(cards) do
					slash:addSubcard(cd)
				end
				slash:setSkillName("luagudan_dis")
				return slash
			elseif #cards == 0 then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if sgs.Self:getHandcardNum() == 0 then return nil end
				slash:addSubcards(sgs.Self:getHandcards())
				slash:setSkillName("luagudan_ex")
				return slash
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() == "jink") then
			card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCurrentCardUsePattern(), sgs.Card_NoSuit, 0)
			if #cards > 0 then
				for _, cd in ipairs(cards) do
					card:addSubcard(cd)
				end
				card:setSkillName("luagudan_dis")
			else
				if sgs.Self:getHandcardNum() == 0 then return nil end
				card:addSubcards(sgs.Self:getHandcards())
				card:setSkillName("luagudan_ex")
			end
			return card
		end
	end,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target) and not target:isNude()
	end,
	enabled_at_response = function(self, target, pattern)
		return ((pattern == "slash") or (pattern == "jink")) and not target:isNude()
	end
}



luagudanSlash = sgs.CreateTargetModSkill {
	name = "#luagudanSlash",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("luagudan") and ((card:getSkillName() == "luagudan_dis") or (card:getSkillName() == "luagudan_ex")) then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("luagudan") and (card:getSkillName() == "luagudan_ex") then
			return card:subcardsLength() - 1
		end
	end,
}





zhaoyungd:addSkill(luagudan)
zhaoyungd:addSkill(luagudanSlash)
extension:insertRelatedSkills("luagudan", "#luagudanSlash")
zhaoyungd:addSkill(luakongying)

sgs.LoadTranslationTable {
	["zhaoyungd"] = "赵云",
	["luakongying"] = "空营",
	[":luakongying"] = "<font color=\"blue\"><b>锁定技，</b></font>若你没有手牌，其他角色计算与你的距离时始终+1。",
	["$longdan4"] = "吾乃常山赵子龙也~",
	["luagudan"] = "孤胆",
	[":luagudan"] = "你可以将装备区的一张牌当【杀】或【闪】使用或打出，以此法使用的杀无距离限制。你可以将所有手牌当【杀】或【闪】使用或打出，以此法使用的【杀】无距离限制且可以指定至多X名目标角色(X为你弃置牌的张数)。",
	["luagudan_dis"] = "孤胆",
	["luagudan_ex"] = "孤胆",


	--设计者(不写默认为官方)
	["designer:zhaoyungd"] = "leowebber",

	--配音(不写默认为官方)
	["cv:zhaoyungd"] = "暂无",

	--称号
	["#zhaoyungd"] = "一身是胆",

	--插画(默认为KayaK)
	["illustrator:zhaoyungd"] = "暂无",
}


--周瑜
spzhouyu = sgs.General(extension, "spzhouyu", "god", "3", true)

--醇醪
luachunl = sgs.CreateTriggerSkill
	{
		name = "luachunl",
		events = { sgs.DamageInflicted },

		can_trigger = function(self, target)
			return true
		end,

		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local to = damage.to
			local from = damage.from
			local room = player:getRoom()
			if from ~= nil and from:hasSkill("luachunl") and room:askForSkillInvoke(from, "luachunl", data) then
				local recov = sgs.RecoverStruct()
				recov.who = from
				room:recover(from, recov)
				return true
			elseif to:hasSkill("luachunl") and room:askForSkillInvoke(to, "luachunl", data) then
				room:loseHp(to, 1, true, to, self:objectName())
				local x = to:getMaxHp() - to:getHp()
				if x > 2 then x = 2 end
				to:drawCards(x)
				return true
			else
				return false
			end
		end
	}


spzhouyu:addSkill("qinyin")
spzhouyu:addSkill(luachunl)
spzhouyu:addSkill("yingzi")

sgs.LoadTranslationTable {
	["spzhouyu"] = "周瑜",
	["luachunl"] = "醇醪",
	[":luachunl"] = " 当你对其他角色造成伤害时，你可以防止此伤害，然后你回复1点体力。 当你受到伤害时，你可以防止此次伤害，然后你失去1点体力并摸X张牌(X为你损失的体力值且至多为2)。",



	--设计者(不写默认为官方)
	["designer:spzhouyu"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spzhouyu"] = "暂无",

	--称号
	["#spzhouyu"] = "剑胆琴心",

	--插画(默认为KayaK)
	["illustrator:spzhouyu"] = "暂无",
}





--黄月英
sphyy = sgs.General(extension, "sphyy", "shu", "3", false)

--博学
leo_luaboxue = sgs.CreateTriggerSkill
	{
		name = "leo_luaboxue",
		events = { sgs.CardUsed, sgs.CardResponded },
		frequency = sgs.Skill_Frequent,

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local curcard = nil
			if (event == sgs.CardUsed) then
				curcard = data:toCardUse().card
			else
				curcard = data:toCardResponse().m_card
				if curcard == nil then return false end
			end
			if curcard:isKindOf("SkillCard") then return false end
			if not player:askForSkillInvoke(self:objectName()) then return false end
			local card = sgs.Sanguosha:getCard(room:drawCard())
			local cardid = card:getEffectiveId()
			--	player:drawCards(1)
			--展示此牌
			player:obtainCard(card)
			room:showCard(player, cardid);
			if (curcard:isKindOf("BasicCard") and not card:isKindOf("BasicCard")) or (curcard:isKindOf("TrickCard") and not card:isKindOf("TrickCard")) or (curcard:isKindOf("EquipCard") and not card:isKindOf("EquipCard")) then
				--将1张手牌依次置于牌堆顶
				local card_ids = sgs.IntList()
				for _, cd in sgs.qlist(player:getHandcards()) do
					if cd:getEffectiveId() ~= curcard:getEffectiveId() then
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
				end
				for _, cd in sgs.qlist(player:getEquips()) do
					if cd:getEffectiveId() ~= curcard:getEffectiveId() then
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
				end
				room:fillAG(card_ids, player)
				local cdid = room:askForAG(player, card_ids, false, self:objectName())
				room:setPlayerFlag(player, "Global_GongxinOperator")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid), player, nil, sgs.Player_DrawPile,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "leo_luaboxue", ""), true)
				card_ids:removeOne(cdid)
				room:clearAG(player)
				room:setPlayerFlag(player, "-Global_GongxinOperator")
			end
			return false
		end
	}

--巧械
luaqiaoxie = sgs.CreateTriggerSkill
	{
		name = "luaqiaoxie",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Frequent,

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local ecard = nil
			if (player:getPhase() == sgs.Player_Start) then
				local hasej = false
				for _, ecard in sgs.qlist(player:getEquips()) do
					hasej = true
				end
				for _, jcard in sgs.qlist(player:getJudgingArea()) do
					hasej = true
				end
				if (hasej == true) then
					if player:askForSkillInvoke(self:objectName()) then
						local ejcard = room:askForCardChosen(player, player, "ej", "luaqiaoxie")
						room:obtainCard(player, ejcard)
					end
				end
			end
			return false
		end
	}


sphyy:addSkill(leo_luaboxue)
sphyy:addSkill(luaqiaoxie)
sphyy:addSkill("qicai")

sgs.LoadTranslationTable {
	["sphyy"] = "黄月英",
	["leo_luaboxue"] = "博学",
	[":leo_luaboxue"] = "你使用或打出一张牌时，可以摸一张牌并展示之，若此牌与你使用或打出的牌类型不同，你需将一张牌置于牌堆顶。",
	["luaqiaoxie"] = "巧械",
	[":luaqiaoxie"] = "回合开始时，你可以将判定区或装备区的一张牌收归手牌。",


	--设计者(不写默认为官方)
	["designer:sphyy"] = "leowebber",

	--配音(不写默认为官方)
	["cv:sphyy"] = "暂无",

	--称号
	["#sphyy"] = "归隐的杰女",

	--插画(默认为KayaK)
	["illustrator:sphyy"] = "真三国无双",
}



shenlvbuII = sgs.General(extension, "shenlvbuII", "god", "4", true)


--[[
luafeijiang = sgs.CreateDistanceSkill
{
	name = "luafeijiang",
	correct_func = function(self, from, to)
		if from:hasSkill("luafeijiang") then
			return -10
		end
	end,
}]]
luafeijiang = sgs.CreateTriggerSkill {
	name = "luafeijiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.GameStart) or (event == sgs.EventAcquireSkill and data:toString() == "luafeijiang")) then
			local list = room:getAlivePlayers()
			for _, p in sgs.qlist(list) do
				room:setFixedDistance(player, p, 1)
			end
			room:sendCompulsoryTriggerLog(player, "luafeijiang", true)
		elseif event == sgs.EventLoseSkill and data:toString() == "luafeijiang" then
			local list = room:getAlivePlayers()
			for _, p in sgs.qlist(list) do
				room:removeFixedDistance(player, p, 1)
			end
		end
	end
}




shenlvbuII:addSkill(xinwushuangTM)
shenlvbuII:addSkill(xinwushuang)

shenlvbuII:addSkill("shenwei")
shenlvbuII:addSkill(luafeijiang)


sgs.LoadTranslationTable {
	["shenlvbuII"] = "吕布",

	["luafeijiang"] = "飞将",
	[":luafeijiang"] = "<font color=\"blue\"><b>锁定技，</b></font>你与其他角色的距离视为1。",

	--设计者(不写默认为官方)
	["designer:shenlvbuII"] = "leowebber，之语，晴心~雨忆~", --lua制作：之语; 构思：leowebber

	--配音(不写默认为官方)
	["cv:shenlvbuII"] = "暂无",

	--称号
	["#shenlvbuII"] = "暴怒的战神",

	--插画(默认为KayaK)
	["illustrator:shenlvbuII"] = "未知",
}









czyex = sgs.General(extension, "czyex", "qun", "3", true)


luachongzhenex = sgs.CreateTriggerSkill {
	name = "luachongzhenex",
	events = { sgs.CardOffset },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if not effect.card or not effect.card:isKindOf("Slash") then return end
		if not player then return end
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) or effect.to:hasSkill(self:objectName()) then
			if player:hasSkill(self:objectName()) then
				if effect.offset_card and (room:getCardPlace(effect.offset_card:getEffectiveId()) == sgs.Player_DiscardPile) then
					if player:askForSkillInvoke(self:objectName(), data) then
						player:obtainCard(effect.offset_card)
					end
				end
			else
				if effect.card and (room:getCardPlace(effect.card:getEffectiveId()) == sgs.Player_PlaceTable) then
					if effect.to:askForSkillInvoke(self:objectName(), data) then
						effect.to:obtainCard(effect.card)
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


luashenweiex1 = sgs.CreateTriggerSkill {
	name = "luashenweiex1",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if player:isWounded() then
			draw.num = draw.num + 1
			room:sendCompulsoryTriggerLog(player, "luashenweiex1", true)
			data:setValue(draw)
		end
	end
}
luashenweiex1_Keep = sgs.CreateMaxCardsSkill {
	name = "#luashenweiex1_Keep",
	extra_func = function(self, target)
		if target:hasSkill("luashenweiex1") and target:isWounded() then
			return 1
		else
			return 0
		end
	end
}

czyex:addSkill(luachongzhenex)
czyex:addSkill(luashenweiex1)
czyex:addSkill(luashenweiex1_Keep)
extension:insertRelatedSkills("luashenweiex1", "#luashenweiex1_Keep")
czyex:addSkill("longdan")

sgs.LoadTranslationTable {
	["czyex"] = "赵云",
	["luachongzhenex"] = "冲阵",
	[":luachongzhenex"] = "你使用【杀】被【闪】抵消时可以获得这张【闪】。你使用【闪】抵消【杀】时可以获得这张【杀】。",
	["luashenweiex1"] = "逆鳞",
	[":luashenweiex1"] = "<font color=\"blue\"><b>锁定技，</b></font>若你已受伤，摸牌阶段你额外摸一张牌，你的手牌上限+1。",

	--设计者(不写默认为官方)
	["designer:czyex"] = "leowebber",

	--配音(不写默认为官方)
	["cv:czyex"] = "暂无",

	--称号
	["#czyex"] = "白马先锋",

	--插画(默认为KayaK)
	["illustrator:czyex"] = "真三国无双",
}



wyzf = sgs.General(extension, "wyzf", "shu", "4", true)

--泼墨
wyzf_pomo = sgs.CreateTriggerSkill
	{
		name = "wyzf_pomo",
		events = { sgs.EventPhaseStart },
		frequency = sgs.Skill_Frequent,

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local players = room:getAllPlayers()
			if player:getPhase() == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName(), data) then
					local id = room:drawCard()
					local card = sgs.Sanguosha:getCard(id)
					player:obtainCard(card)
					--展示此牌
					room:showCard(player, card:getEffectiveId());
					if card:isBlack() then
						--将1张手牌依次置于牌堆顶
						local carda = room:askForExchange(player, self:objectName(), 1, 1, false, "wyzf_pomoGoBack",
							false)
						if carda then
							local move = sgs.CardsMoveStruct()
							move.card_ids = carda:getSubcards()
							move.to_place = sgs.Player_DrawPile
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
								"wyzf_pomo", "");
							move.reason = reason
							room:setPlayerFlag(player, "Global_GongxinOperator")
							room:moveCardsAtomic(move, false)
							room:setPlayerFlag(player, "-Global_GongxinOperator")
						end
						room:addPlayerMark(player, "&wyzf_pomo-Clear")
						for _, p in sgs.qlist(players) do
							room:setFixedDistance(player, p, 1)
						end
						room:broadcastSkillInvoke("wyzf_pomo", 2)
					else
						room:broadcastSkillInvoke("wyzf_pomo", 1)
					end
				end
			elseif player:getPhase() == sgs.Player_Finish then
				room:broadcastSkillInvoke("wyzf_pomo", 3)
				for _, p in sgs.qlist(players) do
					room:removeFixedDistance(player, p, 1)
				end
			end
			return false
		end
	}


wyzf:addSkill(wyzf_pomo)

sgs.LoadTranslationTable {
	["wyzf"] = "张飞",
	["wyzf_pomo"] = "泼墨",
	[":wyzf_pomo"] = "出牌阶段开始时，你可以摸一张牌并展示之。若为黑色，你需将一张手牌置于牌堆顶，且本阶段内，你使用黑色牌无距离限制。",
	["wyzf_pomoGoBack"] = "你需将一张手牌置于牌堆顶",
	["$wyzf_pomo1"] = "风劲角弓鸣，将军猎渭城",
	["$wyzf_pomo2"] = "草枯鹰眼疾，雪尽马蹄轻",
	["$wyzf_pomo3"] = "回看射雕处，千里暮云平",


	--设计者(不写默认为官方)
	["designer:wyzf"] = "leowebber",

	--配音(不写默认为官方)
	["cv:wyzf"] = "暂无",

	--称号
	["#wyzf"] = "涿郡英豪",

	--插画(默认为KayaK)
	["illustrator:wyzf"] = "火凤三国",
}


leozhangxiu = sgs.General(extension, "leozhangxiu", "qun", "4", true)


luafanfu_card = sgs.CreateSkillCard
	{
		name = "luafanfu",

		on_effect = function(self, effect)
			local from = effect.from
			local to = effect.to
			local room = from:getRoom()
			local kdfrom = from:getKingdom()
			local kdto = to:getKingdom()

			if kdfrom ~= kdto then
				from:drawCards(1, self:objectName())
				to:drawCards(1, self:objectName())
				room:setPlayerProperty(from, "kingdom", sgs.QVariant(kdto))
			else
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				slash:deleteLater()
				local use_card = sgs.CardUseStruct()
				use_card.from = from
				use_card.to:append(to)
				use_card.card = slash
				room:useCard(use_card, false)
				local kd = sgs.Sanguosha:getKingdoms()
				table.removeOne(kd,from:getKingdom())
				if #kd<1 then return end
				kd = table.concat(kd,"+")
				kd = room:askForChoice(from,self:objectName(),kd)
				local log = sgs.LogMessage()
				log.type = "#ChangeKingdom2"
				log.from = from
				log.arg = from:getKingdom()
				log.arg2 = kd
				room:sendLog(log)
				room:setPlayerProperty(from, "kingdom", sgs.QVariant(kd))
			end
		end
	}

luafanfu_viewas = sgs.CreateViewAsSkill
	{
		name = "luafanfu",
		n = 1,

		view_filter = function()
			return true
		end,

		view_as = function(self, cards)
			if (#cards ~= 1) then return nil end
			local acard = luafanfu_card:clone()
			acard:addSubcard(cards[1])
			acard:setSkillName(self:objectName())
			return acard
		end,

		enabled_at_play = function(self, player)
			return false
		end,

		enabled_at_response = function(self, player, pattern)
			return pattern == "@@luafanfu"
		end

	}

luafanfu = sgs.CreateTriggerSkill
	{
		name = "luafanfu",
		view_as_skill = luafanfu_viewas,
		events = { sgs.EventPhaseStart },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
				room:askForUseCard(player, "@@luafanfu", "@luafanfu_card")
			end
		end
	}


luaqiangwang = sgs.CreateTriggerSkill {
	name = "luaqiangwang",
	events = { sgs.TargetSpecified },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local can_invoke = false
			if use.from and use.from:hasSkill(self:objectName()) then
				if use.card:isKindOf("Slash") then
					if use.from:objectName() == player:objectName() then
						for _, p in sgs.qlist(use.to) do
							if (player:distanceTo(p) > 1) then
								if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then
									p:addQinggangTag(use.card)
									can_invoke = true
								end
							end
						end
						if can_invoke then
							room:setEmotion(use.from, "weapon/qinggang_sword")
							room:sendCompulsoryTriggerLog(use.from, "luaqiangwang", true)
						end
					end
				end
			end
			return false
		end
	end,
}


leozhangxiu:addSkill(luafanfu)
leozhangxiu:addSkill(luaqiangwang)

sgs.LoadTranslationTable {
	["leozhangxiu"] = "张绣",
	["luafanfu"] = "反复",
	[":luafanfu"] = "回合开始时，你可以弃置一张牌并指定一名其他角色：若势力不同，你与其各摸一张牌，然后你需变为该角色的势力。若势力相同，视为你对其使用了一张【杀】，然后你需变为一个其他势力。",
	["@luafanfu_card"] = "请指定一名角色发动【反复】",
	["luaqiangwang"] = "枪王",
	[":luaqiangwang"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离大于1的角色使用【杀】时，无视其防具。",
	["luafanfu_"] = "反复",

	--设计者(不写默认为官方)
	["designer:leozhangxiu"] = "leowebber",

	--配音(不写默认为官方)
	["cv:leozhangxiu"] = "暂无",

	--称号
	["#leozhangxiu"] = "宛城侯",

	--插画(默认为KayaK)
	["illustrator:leozhangxiu"] = "三国志12",
}


spjwh = sgs.General(extension, "spjwh", "qun", "3", true)

dushicardname = nil

--洞察
luadushi = sgs.CreateTriggerSkill {
	name = "luadushi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.CardUsed },

	can_trigger = function(self, target)
		return true
	end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local curp = room:getCurrent()
		if event == sgs.EventPhaseStart and player:hasSkill("luadushi") then
			if player:getPhase() == sgs.Player_Play then
				local alplayers = room:getAlivePlayers()
				local duship = room:askForPlayerChosen(player, alplayers, "@luadushi1")
				if (duship ~= nil and not duship:isKongcheng()) then
					local cdid = room:askForCardChosen(player, duship, "h", self:objectName(), true)
					local dest = sgs.QVariant()
					dest:setValue(cdid)
					room:setTag("luadushi", dest)
					room:showCard(duship, cdid)
					local dushic = sgs.Sanguosha:getCard(cdid)
					dushicardname = dushic:objectName()
					room:addPlayerMark(player, "&luadushi+" .. dushicardname .. "-PlayClear")
					room:broadcastSkillInvoke("weimu", 1)
				end
			elseif player:getPhase() == sgs.Player_Finish then
				dushicardname = nil
				room:removeTag("luadushi")
			end
		elseif event == sgs.CardsMoveOneTime and data:toMoveOneTime().from
			and not data:toMoveOneTime().from:hasSkill("luadushi")
			and player:getGeneralName() == data:toMoveOneTime().from:getGeneralName()
			and curp:hasSkill("luadushi")
		then
			move = data:toMoveOneTime()

			if (move.to_place == 5) then
				local dushidiscardids = move.card_ids
				local dushidiscard = nil
				for _, cdid in sgs.qlist(dushidiscardids) do
					dushidiscard = sgs.Sanguosha:getCard(cdid)
					if (dushidiscard:match(dushicardname)) then
						if player:isKongcheng() and not player:hasEquip() then
							room:broadcastSkillInvoke("wansha", 1)
							room:loseHp(player, 1, true, nil, self:objectName())
						else
							choice = room:askForChoice(curp, "luadushi", "luadushi1+luadushi2")
							if (choice == "luadushi1") then
								local movecard_id = room:askForCardChosen(curp, player, "he", "luadushi1")
								room:broadcastSkillInvoke("fankui", 1)
								curp:obtainCard(sgs.Sanguosha:getCard(movecard_id))
							else
								room:broadcastSkillInvoke("wansha", 1)
								room:loseHp(player, 1, true, nil, self:objectName())
							end
						end
					end
				end
			end
		elseif event == sgs.CardUsed and player:hasSkill("luadushi") then
			local card = data:toCardUse().card
			local acard = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
			local scard = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())
			if card:match(acard:objectName()) or card:match(scard:objectName()) then
				room:broadcastSkillInvoke("luanwu", 1)
			end
		end
	end,
}


--韬晦
luataohui = sgs.CreateTriggerSkill
	{
		name = "luataohui",
		events = { sgs.DamageInflicted },
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.DamageInflicted then
				local from = data:toDamage().from
				if (data:toDamage().nature == sgs.DamageStruct_Thunder
						or data:toDamage().nature == sgs.DamageStruct_Fire) then
					return false
				end
				if (player:getHp() < from:getHp()) then
					room:broadcastSkillInvoke("weimu", 2)
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
					return true
				else
					return false
				end
			end
		end
	}
luataohui_c = sgs.CreateMaxCardsSkill {
	name = "#luataohui_c",
	fixed_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getMaxHp()
		else
			return -1
		end
	end
}


spjwh:addSkill(luadushi)
spjwh:addSkill(luataohui)
spjwh:addSkill(luataohui_c)
extension:insertRelatedSkills("luataohui", "#luataohui_c")

sgs.LoadTranslationTable {
	["spjwh"] = "贾文和",
	["luadushi"] = "洞察",

	[":luadushi"] = "出牌阶段开始时，你可以观看一名角色的手牌并展示其中一张牌。则本阶段内，除你外的角色与此牌同名的牌进入弃牌堆时，你获得该角色的一张牌或令其失去1点体力。",
	["@luadushi1"] = "选择一名角色并展示该角色的一张手牌。",
	["@luadushi2"] = "选择展示一张手牌。",
	["luadushi1"] = "获得该角色的一张牌。",
	["luadushi2"] = "令该角色失去1点体力。",
	["luataohui"] = "韬晦",
	[":luataohui"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限始终等于体力上限，你防止体力值大于你的角色对你造成的无属性伤害。",



	--设计者(不写默认为官方)
	["designer:spjwh"] = "leowebber",

	--配音(不写默认为官方)
	["cv:spjwh"] = "暂无",

	--称号
	["#spjwh"] = "算无遗策",

	--插画(默认为KayaK)
	["illustrator:spjwh"] = "三国志12",
}


guanyuzy = sgs.General(extension, "guanyuzy", "shu", "4", true)
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local patterns = { "slash", "jink", "peach", "analeptic" }
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end
local slash_patterns = { "slash", "normal_slash", "thunder_slash", "fire_slash" }
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end

local pos = 0
luazhiyong_select = sgs.CreateSkillCard {
	name = "luazhiyong_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local basic = {}
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if card:getTypeId() == sgs.Card_TypeBasic then
						table.insert(basic, cd)
					end
					if cd == "slash" then
						table.insert(basic, "normal_slash")
					end
				end
			end
		end
		local pattern = room:askForChoice(source, "luazhiyong-new", table.concat(basic, "+"))
		if pattern then
			if string.sub(pattern, -5, -1) == "slash" then
				pos = getPos(slash_patterns, pattern)
				room:setPlayerMark(source, "luazhiyongSlashPos", pos)
			end
			pos = getPos(patterns, pattern)
			room:setPlayerMark(source, "luazhiyongPos", pos)
			local prompt = string.format("@@luazhiyong:%s", pattern)
			room:askForUseCard(source, "@luazhiyong", prompt)
		end
	end,
}

luazhiyongCard = sgs.CreateSkillCard {
	name = "luazhiyong",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@luazhiyong" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("luazhiyong")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, player) and
				not player:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local pattern = patterns[player:getMark("luazhiyongPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("luazhiyong")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player) and
			not player:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@luazhiyong" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = patterns[player:getMark("luazhiyongPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,
	feasible = function(self, targets, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@luazhiyong" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("luazhiyong")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, player)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = patterns[player:getMark("luazhiyongPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("luazhiyong")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()
		local to_guhuo = self:getUserString()
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@luazhiyong" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "luazhiyong_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "luazhiyongSlashPos", pos)
		end
		local subcards = self:getSubcards()
		local card = sgs.Sanguosha:getCard(subcards:first())
		local user_str
		if to_guhuo == "slash" then
			if card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_guhuo == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_guhuo
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
		use_card:setSkillName("luazhiyong")
		use_card:addSubcard(card)
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo
		if self:getUserString() == "peach+analeptic" then
			local guhuo_list = {}
			table.insert(guhuo_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "analeptic")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
		elseif self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "luazhiyong_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "luazhiyongSlashPos", pos)
		else
			to_guhuo = self:getUserString()
		end
		local subcards = self:getSubcards()
		local card = sgs.Sanguosha:getCard(subcards:first())
		local user_str
		if to_guhuo == "slash" then
			if card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_guhuo == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_guhuo
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
		use_card:setSkillName("luazhiyong")
		use_card:addSubcard(subcards:first())
		use_card:deleteLater()
		return use_card
	end
}

luazhiyongVS = sgs.CreateViewAsSkill {
	name = "luazhiyong",
	n = 1,
	response_or_use = true,
	enabled_at_response = function(self, player, pattern)
		if pattern == "@luazhiyong" then
			return not player:isKongcheng()
		end
		if pattern == "peach" and player:hasFlag("Global_PreventPeach") then return false end
		return (pattern == "slash")
			or (pattern == "jink")
			or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
			or (string.find(pattern, "analeptic"))
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then
			return player:usedTimes("Analeptic") <=
				sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
		end
		return sgs.Slash_IsAvailable(player) or player:isWounded()
	end,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@luazhiyong" then
				local pattern = patterns[sgs.Self:getMark("luazhiyongPos")]
				if pattern == "normal_slash" then pattern = "slash" end
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards == 1 then
					c:deleteLater()
					local card = luazhiyongCard:clone()
					if not string.find(c:objectName(), "slash") then
						card:setUserString(c:objectName())
					else
						card:setUserString(slash_patterns[sgs.Self:getMark("luazhiyongSlashPos")])
					end
					card:addSubcard(cards[1])
					return card
				else
					return nil
				end
			elseif #cards == 1 then
				local card = luazhiyongCard:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				card:addSubcard(cards[1])
				return card
			else
				return nil
			end
		else
			local cd = luazhiyong_select:clone()
			return cd
		end
	end,
}

luazhiyong = sgs.CreateTriggerSkill
	{
		name = "luazhiyong",
		events = { sgs.CardUsed, sgs.CardResponded },
		view_as_skill = luazhiyongVS,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if player:hasSkill("luazhiyong") then --关羽触发此处
				if event == sgs.CardUsed then
					local curcard = data:toCardUse().card
					if curcard:getSkillName() == "luazhiyong" and player:getPhase() == sgs.Player_NotActive then
						room:broadcastSkillInvoke("wusheng", 1)
						player:drawCards(1)
					end
				elseif event == sgs.CardResponded then
					local card = data:toCardResponse().m_card
					if card:getSkillName() == "luazhiyong" and player:getPhase() == sgs.Player_NotActive then
						room:broadcastSkillInvoke("wusheng", 1)
						player:drawCards(1)
					end
				end
			end
		end
	}

luayijuedestCard = sgs.CreateSkillCard {
	name = "luayijuedestCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, from)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local guanyu = room:findPlayerBySkillName("luayijue")
		if not guanyu:isAlive() or guanyu:isNude() then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@luayijue:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card = room:askForCard(guanyu, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse,
			guanyu);
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_luayijueFailed")
		room:setPlayerFlag(user, "Global_luayijueFailed_AI")
		return false
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local guanyu = room:findPlayerBySkillName("luayijue")
		if not guanyu or not guanyu:isAlive() or guanyu:isNude() then
			room:setPlayerFlag(user, "Global_luayijueFailed")
			room:setPlayerFlag(user, "Global_luayijueFailed_AI")
			return false
		end

		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@luayijue:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		local card = room:askForCard(guanyu, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse,
			guanyu);
		if card then
			return card
		end
		room:setPlayerFlag(user, "Global_luayijueFailed")
		room:setPlayerFlag(user, "Global_luayijueFailed_AI")
		return false
	end
}
luayijuedest = sgs.CreateZeroCardViewAsSkill {
	name = "luayijuedest&",
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_luayijueFailed") then return end
		if pattern == "slash" then
			return true
		elseif pattern == "peach" then
			return player:getMark("Global_PreventPeach") == 0
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = luayijuedestCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "peach+analeptic" and sgs.Self:getMark("Global_PreventPeach") > 0 then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
		return acard
	end
}


luayijue = sgs.CreateTriggerSkill
	{
		name = "luayijue",
		events = { sgs.EventPhaseStart, sgs.CardAsked },
		frequency = sgs.Skill_Limited,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) and not (player:getMark("luayijue_used") > 0) then
				local yijueed = false
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (p:getMark("@luayijue") > 0) then
						yijueed = true
						break
					end
				end
				if not yijueed and room:askForSkillInvoke(player, "luayijue_xianfu") then
					local yijuetarget = room:askForPlayerChosen(player, room:getOtherPlayers(player), "luayijue")
					room:addPlayerMark(yijuetarget, "&luayijue+to+#" .. player:objectName())
					yijuetarget:gainMark("@luayijue")
					room:setPlayerMark(player, "luayijue_used", 1)
					room:broadcastSkillInvoke("danji", 1)
					room:attachSkillToPlayer(yijuetarget, "luayijuedest")
				end
			end
			if event == sgs.CardAsked and player:getPhase() == sgs.Player_NotActive and (player:getMark("@luayijue") > 0) then
				local pattern = data:toStringList()[1]
				if (pattern ~= "jink"
						and pattern ~= "slash"
						and not string.find(pattern, "peach")
					) then
					return false
				end
				local asktext = pattern
				if string.find(pattern, "peach") then
					asktext = "peach"
				end
				local guanyu = nil
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (p:hasSkill(self:objectName())) then
						guanyu = p
						break
					end
				end
				if guanyu ~= nil then
					if not player:askForSkillInvoke(self:objectName(), data) then return false end
					local dt = sgs.QVariant(0)
					local supplycard = 0
					dt:setValue(player)
					if asktext == "slash" then
						supplycard = room:askForCard(guanyu, asktext, "luayijueslash", dt, sgs.Card_MethodResponse,
							guanyu);
					elseif asktext == "jink" then
						supplycard = room:askForCard(guanyu, asktext, "luayijuejink", dt, sgs.Card_MethodResponse, guanyu);
					elseif asktext == "peach" then
						supplycard = room:askForCard(guanyu, asktext, "luayijuepeach", dt, sgs.Card_MethodResponse,
							guanyu);
					end
					if (supplycard) then
						room:provide(supplycard)
						return true
					end
				end
			end
		end,
		can_trigger = function(self, target)
			return target
		end,
	}



guanyuzy:addSkill(luazhiyong)
guanyuzy:addSkill(luayijue)

sgs.LoadTranslationTable {
	["guanyuzy"]             = "关羽",
	["luazhiyong"]           = "智勇",
	[":luazhiyong"]          = "你的红桃牌可以当任意一张基本牌使用或打出，若在回合外如此做，你摸一张牌。",
	["luazhiyongcard"]       = "智勇",
	["luazhiyongcancel"]     = "取消",
	["luazhiyong-new"]       = "智勇",
	["luazhiyong_select"]    = "智勇",
	["@@luazhiyong"]         = "你可以将一张基本牌 当 %src 使用或打出。",
	["~luazhiyong"]          = "选择一张牌→点击确定",
	["luayijue"]             = "义绝",
	["luayijue_xianfu"]      = "义绝",
	[":luayijue"]            = "<font color=\"red\"><b>限定技，</b></font>回合开始阶段，你可以指定一名其他角色：该角色回合外需要使用或打出一张基本牌时，你可以替其使用或打出，直至该角色阵亡或游戏结束。",
	["luayijueslash"]        = "是否发动义绝打出一张【杀】",
	["luayijuejink"]         = "是否发动义绝打出一张【闪】",
	["luayijuepeach"]        = "是否发动义绝打出一张【桃】",
	["@luayijue"]            = "义绝",
	["@@luayijue"]           = "是否发动义绝使用或打出一张 %src",
	["luayijuedest"]         = "义绝",

	--设计者(不写默认为官方)
	["designer:guanyuzy"]    = "leowebber",

	--配音(不写默认为官方)
	["cv:guanyuzy"]          = "暂无",

	--称号
	["#guanyuzy"]            = "忠义两全",

	--插画(默认为KayaK)
	["illustrator:guanyuzy"] = "暂无",
}

if not sgs.Sanguosha:getSkill("luayijuedest") then
	s_skillList:append(luayijuedest)
end


bazhenwolong=sgs.General(extension, "bazhenwolong", "shu", "3", true)
--帷幄
leo_luaweiwo = sgs.CreateTriggerSkill
{
	name = "leo_luaweiwo",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	
	on_trigger = function(self, event, player, data)
		if(player:getPhase() == sgs.Player_Finish) then
			local room = player:getRoom()
			player:drawCards(3)
			--将x张手牌依次置于牌堆顶
			local x = player:getHp()
			if(x > 3) then x = 3 end
			local card_ids = sgs.IntList()
			for _,cd in sgs.qlist(player:getHandcards()) do
				local id = cd:getEffectiveId()
				card_ids:append(id)
			end
			for var = 1 , x, 1 do
				room:fillAG(card_ids, player)
				local cdid = room:askForAG(player, card_ids, false, self:objectName())
				room:moveCardTo(sgs.Sanguosha:getCard(cdid), nil, sgs.Player_DrawPile, true)
				card_ids:removeOne(cdid)
				room:clearAG()
			end
		end
		return false
	end
}

--八阵梅花
luabazhen_club = sgs.CreateSkillCard
{
	name = "luabazhen_club",
	filter = function(self, targets, to_select)
		if #targets > 1 then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		local use_card = sgs.CardUseStruct()
		use_card.from = source
		use_card.to:append(targets[1])
		if(#targets == 2) then 
			use_card.to:append(targets[2])
		end
		local card = sgs.Sanguosha:cloneCard("iron_chain",sgs.Card_NoSuit,0)
		card:deleteLater()
		card:setSkillName("luaspbazhen")
		use_card.card = card
		room:useCard(use_card,false)
	end

}

luabazhen_viewas = sgs.CreateViewAsSkill
{
	name = "luabazhen_viewas",
	n = 0,
	view_as = function(self, cards)
		if #cards == 0 then 
			local acard = luabazhen_club:clone()
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self, player)
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return false
	end
}

--八阵
luaspbazhen = sgs.CreateTriggerSkill {
	name = "luaspbazhen",
	view_as_skill = luabazhen_viewas,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local room = player:getRoom()
				if player:getPhase() == sgs.Player_NotActive then
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						local places = move.from_places
						if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
							room:broadcastSkillInvoke("fankui",1)
							--展示此牌
							room:showCard(player, card:getEffectiveId());
							local targetPlayers = room:getAlivePlayers()
							--如果失去的是基本牌或装备牌
							if(not card:isKindOf("TrickCard")) then 
								room:broadcastSkillInvoke("bazhen",2)
								local cardid = 0
								--红桃则先摸一张牌
								if(card:getSuit()==sgs.Card_Heart) then
									cardid = room:drawCard()
									local move = sgs.CardsMoveStruct()
									move.card_ids:append(cardid)
									move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,source:objectName(),"luaspbazhen","")
									move.to_place = sgs.Player_PlaceTable
									room:moveCardsAtomic(move,true)
									--player:drawCards(1) 
								end
			
								local targetp = nil
								
								--黑桃
								if(card:getSuit()==sgs.Card_Spade) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen1")
									if(targetp:isKongcheng() and not targetp:hasEquip()) or targetp==player then 
										return false
									else
										room:broadcastSkillInvoke("fankui",1)
										cardid = room:askForCardChosen(player, targetp, "he", "luaspbazhen");
										player:obtainCard(sgs.Sanguosha:getCard(cardid))
									end
								--梅花
								elseif(card:getSuit()==sgs.Card_Club) then
									room:askForUseCard(player, "@@luaspbazhen", "@luabazhen_club")
								--红桃
								elseif(card:getSuit()==sgs.Card_Heart) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen3")
									room:broadcastSkillInvoke("yiji",1)
									if(targetp==player) then 
										player:obtainCard(sgs.Sanguosha:getCard(cardid))
									else
										targetp:obtainCard(sgs.Sanguosha:getCard(cardid))
									end
								--方片
								elseif(card:getSuit()==sgs.Card_Diamond) then
									targetp = room:askForPlayerChosen(player, targetPlayers, "@luaspbazhen4")
									if(targetp:isKongcheng()) then 
										return false
									else
										room:broadcastSkillInvoke("huoji",1)
										local use_card = sgs.CardUseStruct()
										use_card.from = player
										use_card.to:append(targetp)
										local fire_attack = sgs.Sanguosha:cloneCard("fire_attack",sgs.Card_NoSuit,0)
										fire_attack:setSkillName("luaspbazhen")
										use_card.card = fire_attack
										fire_attack:deleteLater()
										room:useCard(use_card,false)
									end
								end
							end
						end
					end
				end
			end
		end
		return false
	end
}


bazhenwolong:addSkill("luaweiwo")
bazhenwolong:addSkill(luaspbazhen)

sgs.LoadTranslationTable{
	["bazhenwolong"]="八阵诸葛",
	["leo_luaweiwo"] = "帷幄",	
	[":leo_luaweiwo"] = "回合结束时可摸3张牌，并将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",
	["luaspbazhen"] = "八阵ex",	
	[":luaspbazhen"] = "回合外你失去一张牌时，可展示此牌，若为基本牌或装备牌，按此牌的花色执行一项：1、黑桃，获得任意一名角色的一张牌 2、梅花，将一至两名角色的武将牌横置或重置 3、红桃，摸一张牌交给任意一名角色 4、方片，视为使用了一张【火攻】。",
	["@luaspbazhen1"] = "发动技能八阵，选择一名角色，获得该角色的一张牌。",
	--["@luaspbazhen2"] = "发动技能八阵，选择一名角色，将该角色的武将牌横置或重置。",
	["@luaspbazhen3"] = "发动技能八阵，选择一名角色，将你摸的一张牌交给该角色。",
	["@luaspbazhen4"] = "发动技能八阵，选择一名角色，对该角色使用一张【火攻】。",
	["@luabazhen_club"] = "指定一到两名角色，将其武将牌横置或重置",
	["~luabazhen"] = "若为基本牌或装备牌，按此牌的花色执行一项：1、黑桃，获得任意一名角色的一张牌 2、梅花，将一至两名角色的武将牌横置或重置 3、红桃，摸一张牌交给任意一名角色 4、方片，视为使用了一张【火攻】。",
	["luabazhen_club"] = "八阵",
--设计者(不写默认为官方)
	["designer:bazhenwolong"] = "leowebber",
	
--配音(不写默认为官方)
	["cv:bazhenwolong"] = "暂无",
	
--称号
	["#bazhenwolong"] = "多智而近妖",
	
--插画(默认为KayaK)
	["illustrator:bazhenwolong"] = "暂无",
}

leo_spwolong=sgs.General(extension, "leo_spwolong", "shu", "3", true)

luatianming = sgs.CreateTriggerSkill{
	name = "luatianming", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.AskForPeaches},
	waked_skills = "bazhen,kanpo,jizhi",
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		room:setPlayerMark(player, "luatianming", 1)
		room:broadcastSkillInvoke("qixing",2)
		
		while player:getHp()<1 do
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end
		
		--while player:getMaxHp()>1 do
		--	room:loseMaxHp(player)
		--end
		
		local count = player:getMark("&luarangxingRX")
		player:drawCards(count)
		room:addMaxCards(player, count, false)
		room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) 
		room:acquireSkill(player, "bazhen")
		room:acquireSkill(player, "kanpo")
		room:acquireSkill(player, "jizhi")
		room:detachSkillFromPlayer(player,"luarangxing")
		return false
	end, 
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() then return false end
			if player:canWake(self:objectName()) then return true end
			if player:getMark("&luarangxingRX") < 7 then
				return false
			end
			return true
		end
	end,
}

luarangxing = sgs.CreateTriggerSkill
{
	name = "luarangxing",
	events = {sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_NotFrequent,
	
	can_trigger = function(self, target)
        return target:hasSkill(self:objectName()) 
    end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill("luarangxing") and player:getMark("tianming") == 0 then
			room:addPlayerMark(player, "&luarangxingRX")
			room:broadcastSkillInvoke("qixing",1)
		end
		return false
	end
}

luajincui = sgs.CreateTriggerSkill
{
	name = "luajincui",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	
	can_trigger = function(self, target)
        return target:hasSkill(self:objectName())  
    end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:hasSkill("luajincui") and player:getMaxHp()>1 then
			local jincuiTarget = room:askForPlayerChosen(player, room:getAllPlayers(), "luajincui")
		    room:broadcastSkillInvoke("yiji",1)
			local choice = room:askForChoice(player, "luajincui", "luajincui1+luajincui2")
			jincuiTarget:drawCards(2) 
			if(choice == "luajincui1") then
				room:loseHp(player, 1, true, player, self:objectName())
			else
				room:loseMaxHp(player)
			end	
		end
		return false
	end
}

newluaweiwo = sgs.CreateTriggerSkill
{
	name = "newluaweiwo",
	events = {sgs.StartJudge, sgs.EventPhaseChanging},
	frequency = sgs.Skill_NotFrequent,
	
	can_trigger = function(self, target)
        return true 
    end,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.StartJudge and player:hasSkill("newluaweiwo")
		then
			local allPlayers = room:getAlivePlayers()
			for _,p in sgs.qlist(allPlayers) do
				if p:hasSkill("newluaweiwo") and room:askForSkillInvoke(p, "newluaweiwo", data) then
				    room:broadcastSkillInvoke("guanxing",2)
					p:drawCards(3)
					room:setTag("newluaweiwo", data)
					--将x张手牌依次置于牌堆顶
					local x = p:getHp()
					if(x > 3) then x = 3 end
					local card_ids = sgs.IntList()
					for _,cd in sgs.qlist(p:getHandcards()) do
						local id = cd:getEffectiveId()
						card_ids:append(id)
					end
					for var = 1 , x, 1 do
						room:addPlayerMark(p, "newluaweiwo")
						room:fillAG(card_ids, p)
						local cdid = room:askForAG(p, card_ids, false, self:objectName())
						
						local moveA = sgs.CardsMoveStruct()
						local ln = sgs.IntList()
						ln:append(cdid)
						moveA.card_ids = ln
						moveA.to_place = sgs.Player_DrawPile
						room:moveCardsAtomic(moveA, false)
						
						card_ids:removeOne(cdid)
						room:clearAG(p)
					end
					room:setPlayerMark(p, "newluaweiwo", 0)
					room:removeTag("newluaweiwo")
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:hasSkill("newluaweiwo") then
				room:broadcastSkillInvoke("guanxing",1)
				player:drawCards(3)
				--将x张手牌依次置于牌堆顶
				local x = player:getHp()
				if(x > 3) then x = 3 end
				local card_ids = sgs.IntList()
				for _,cd in sgs.qlist(player:getHandcards()) do
					local id = cd:getEffectiveId()
					card_ids:append(id)
				end
				for var = 1 , x, 1 do
					room:fillAG(card_ids, player)
					local cdid = room:askForAG(player, card_ids, false, self:objectName())
					
					local moveA = sgs.CardsMoveStruct()
					local ln = sgs.IntList()
					ln:append(cdid)
					moveA.card_ids = ln
					moveA.to_place = sgs.Player_DrawPile
					room:moveCardsAtomic(moveA, false)
					
					card_ids:removeOne(cdid)
					room:clearAG(player)
				end
			end
		end
		return false
	end
}

leo_spwolong:addSkill(newluaweiwo)
leo_spwolong:addSkill(luajincui)
leo_spwolong:addSkill(luarangxing)
leo_spwolong:addSkill(luatianming)

sgs.LoadTranslationTable{
	["leo_spwolong"]="诸葛亮",
	["newluaweiwo"] = "帷帐",	
	[":newluaweiwo"] = "你即将进行一次判定或你的回合结束时，可以摸3张牌，然后你须将X张手牌依次置于牌堆顶(X为你的体力值且至多为3)。",	
	["luajincui"] = "尽瘁",
	[":luajincui"] = "锁定技，出牌阶段开始时若你的体力上限大于1，须减1点体力或体力上限令一名角色摸两张牌。",
	["luajincui1"] = "体力值",
	["luajincui2"] = "体力上限",
	["luarangxingRX"] = "星",
	["luarangxing"] = "禳星",
	[":luarangxing"] = "锁定技，每当体力值或体力上限变化时，你获得一枚“星”标记。",
	["luatianming"] = "天命",
	[":luatianming"] = "觉醒技，你濒死状态时若“星”不少于7枚，你将体力值回复至1，摸等同于“星”数量的牌并增加等量的手牌上限，然后失去“禳星”并获得“八阵”，“看破”，“集智”。",
	

--设计者(不写默认为官方)
	["designer:leo_spwolong"] = "leowebber",
	
--配音(不写默认为官方)
	["cv:leo_spwolong"] = "暂无",
	
--称号
	["#leo_spwolong"] = "秋风五丈原",
}

sgs.Sanguosha:addSkills(s_skillList)

return { extension }
