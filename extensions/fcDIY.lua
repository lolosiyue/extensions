extension = sgs.Package("fcDIY", sgs.Package_GeneralPack)
xiangyuEquip = sgs.Package("xiangyuEquip", sgs.Package_CardPack)
extension_Cards = sgs.Package("fcDIY_Cards", sgs.Package_CardPack)
--==V1.0==--
--1 神貂蝉-自改版
shendiaochan_change = sgs.General(extension, "shendiaochan_change", "god", 3, false)

f_meihun = sgs.CreateTriggerSkill{
    name = "f_meihun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) or (event == sgs.TargetConfirmed and data:toCardUse().card:isKindOf("Slash") and data:toCardUse().to:contains(player)) then
			local plist = room:getOtherPlayers(player)
			local victim = room:askForPlayerChosen(player, plist, self:objectName(), "f_meihun-invoke", true, true)
			if not victim then return false end
			if victim:isNude() then return false end
			local suit = room:askForSuit(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:getThread():delay()
			local card = room:askForCard(victim, ".|"..suit, "@f_meihun-suit", data, sgs.Card_MethodNone)
			if card then
				player:obtainCard(card)
			else
				if not victim:isKongcheng() then
					local ids = sgs.IntList()
					for _, c in sgs.qlist(victim:getHandcards()) do
						if c then
							ids:append(c:getEffectiveId())
						end
					end
					local card_id = room:doGongxin(player, victim, ids)
					if (card_id == -1) then return end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, self:objectName(), nil)
					room:throwCard(sgs.Sanguosha:getCard(card_id), reason, victim, player)
				end
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = "f_huoxin"
				room:judge(judge)
				if judge:isGood() then
					victim:gainMark("&f_meihuo")
					room:broadcastSkillInvoke("f_huoxin", 1)
				end
			end
			return false
		end
	end,
}
shendiaochan_change:addSkill(f_meihun)

f_huoxinCard = sgs.CreateSkillCard{ --选择拼点牌
    name = "f_huoxinCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
	    if #targets == 2 then return false end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
	    local lb = targets[1]
		local dz = targets[2]
		room:setPlayerFlag(lb, "f_huoxin_pindiantargets")
		room:setPlayerFlag(dz, "f_huoxin_pindiantargets")
		local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if card_id then
			card_id:deleteLater()
			card_id = self
		end
		source:addToPile("f_huoxinPindianCard", card_id)
		room:askForUseCard(source, "@@f_huoxin!", "@f_huoxinGPC-card1")
		room:askForUseCard(source, "@@f_huoxin!", "@f_huoxinGPC-card2")
	end,
}
f_huoxinGPCCard = sgs.CreateSkillCard{ --给出拼点牌
    name = "f_huoxinGPCCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasFlag("f_huoxin_pindiantargets") and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		targets[1]:obtainCard(self, true)
		if not source:hasFlag("f_huoxinGPC_distinguish") then
			room:setPlayerFlag(targets[1], "-f_huoxin_pindiantargets")
			room:setPlayerFlag(targets[1], "f_huoxin_pindiantargets1")
			room:setPlayerFlag(source, "f_huoxinGPC_distinguish")
		else
			room:setPlayerFlag(targets[1], "-f_huoxin_pindiantargets")
			room:setPlayerFlag(targets[1], "f_huoxin_pindiantargets2")
			room:setPlayerFlag(source, "-f_huoxinGPC_distinguish")
			for _, otr in sgs.qlist(room:getOtherPlayers(source)) do --找到先给牌的对象直接进行拼点
				if otr:hasFlag("f_huoxin_pindiantargets1") then
					room:setPlayerFlag(otr, "f_huoxin_pindiantargets1")
					room:setPlayerFlag(targets[1], "f_huoxin_pindiantargets2")
					room:broadcastSkillInvoke("f_huoxin", 2)
					otr:pindian(targets[1], "f_huoxin", nil)
					break
				end
			end
		end
	end,
}
f_huoxinVS = sgs.CreateViewAsSkill{
    name = "f_huoxin",
	n = 2,
	expand_pile = "f_huoxinPindianCard",
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@f_huoxin!" then
			return sgs.Self:getPile("f_huoxinPindianCard"):contains(to_select:getId())
		else
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
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@f_huoxin!" then
			if #cards == 1 then
				local pd_card = f_huoxinGPCCard:clone()
				pd_card:addSubcard(cards[1]:getId())
				return pd_card
			end
		else
			if #cards == 2 then
				local cardA = cards[1]
				local cardB = cards[2]
				local hx = f_huoxinCard:clone()
				hx:addSubcard(cardA)
				hx:addSubcard(cardB)
				hx:setSkillName(self:objectName())
				return hx
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:hasSkill(self:objectName()) and player:getHandcardNum() > 1 and not player:hasUsed("#f_huoxinCard")
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern=="@@f_huoxin!" then return true end
		return string.startsWith(pattern, "@@f_huoxin")
	end,
}
f_huoxinPindian = sgs.CreateTriggerSkill{ --拼点结算
    name = "#f_huoxinPindian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local pindian = data:toPindian()
		if pindian.reason == "f_huoxin" then
			local fromNumber = pindian.from_card:getNumber()
			local toNumber = pindian.to_card:getNumber()
			if fromNumber ~= toNumber then
				local winner
				local loser
				if fromNumber > toNumber then
					winner = pindian.from
					loser = pindian.to
				else
					winner = pindian.to
					loser = pindian.from
				end
				loser:gainMark("&f_meihuo")
			else
			    pindian.from:gainMark("&f_meihuo")
				pindian.to:gainMark("&f_meihuo")
			end
			room:broadcastSkillInvoke("f_huoxin", 1)
		end
	end,
	can_trigger = function(self, player)
	    return true
	end,
}
f_huoxin = sgs.CreateTriggerSkill{
    name = "f_huoxin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStart},
	view_as_skill = f_huoxinVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		for _, sdc in sgs.qlist(room:findPlayersBySkillName("f_huoxin")) do
			if sdc and room:askForSkillInvoke(sdc, "f_huoxin", data) then
				if not sdc:isKongcheng() then
					local hc = sdc:getHandcardNum()
					local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if card_id then
						card_id:deleteLater()
						card_id = room:askForExchange(sdc, self:objectName(), hc, hc, false, "")
					end
					sdc:addToPile("f_huoxin", card_id, false)
				end
				if not player:isKongcheng() then
					room:obtainCard(sdc, player:wholeHandCards(), false)
				end
				room:broadcastSkillInvoke("f_huoxin", 3)
				player:loseAllMarks("&f_meihuo")
				room:addPlayerMark(player, "f_huoxin_skip")
				room:addPlayerMark(sdc, "&f_huoxin_GetTurn")
				sdc:gainAnExtraTurn() --以此写法，先进行额外回合，再取消目标的回合
			end
		end
	end,
	can_trigger = function(self, player)				
	    return player and player:getMark("&f_meihuo") >= 2
	end,
}
f_huoxinEndTurn = sgs.CreateTriggerSkill{
    name = "#f_huoxinEndTurn",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
			return false
		end
		local plist = room:getAlivePlayers()
		for _, dmd in sgs.qlist(plist) do
            if dmd:getMark("f_huoxin_skip") > 0 and not player:isKongcheng() then
		        room:obtainCard(dmd, player:wholeHandCards(), false)
			end
		end
		if player:getPile("f_huoxin"):length() > 0 then
		    local dummy = sgs.Sanguosha:cloneCard("slash")
		    dummy:addSubcards(player:getPile("f_huoxin"))
		    room:obtainCard(player, dummy, false)
			dummy:deleteLater()
		end
		if player:getMark("&f_huoxin_GetTurn") > 0 then
			room:removePlayerMark(player, "&f_huoxin_GetTurn")
		end
	end,
	can_trigger = function(self, player)				
	    return player and player:hasSkill("f_huoxin") and player:getMark("&f_huoxin_GetTurn") > 0
	end,
}
f_huooxin = sgs.CreateTriggerSkill{ --配音专用
	name = "f_huooxin",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end,
}
--跳过回合：
f_huoxin_skip = sgs.CreateTriggerSkill{ --没找到直接跳过回合的函数，那就自己写个跳过回合内的所有阶段的技能吧
	name = "#f_huoxin_skip",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
	    if data:toPhaseChange().to == sgs.Player_RoundStart then
			player:skip(sgs.Player_RoundStart)
		end
		if data:toPhaseChange().to == sgs.Player_Start then
			player:skip(sgs.Player_Start)
		end
		if data:toPhaseChange().to == sgs.Player_Judge then
			player:skip(sgs.Player_Judge)
		end
		if data:toPhaseChange().to == sgs.Player_Draw then
			player:skip(sgs.Player_Draw)
		end
		if data:toPhaseChange().to == sgs.Player_Play then
			player:skip(sgs.Player_Play)
		end
		if data:toPhaseChange().to == sgs.Player_Discard then
			player:skip(sgs.Player_Discard)
		end
		if data:toPhaseChange().to == sgs.Player_Finish then
			player:skip(sgs.Player_Finish)
		end
		if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
		if player:getMark("f_huoxin_skip") > 0 then
			local n = player:getMark("f_huoxin_skip")
			room:removePlayerMark(player, "f_huoxin_skip", n)
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("f_huoxin_skip") > 0
	end,
}

shendiaochan_change:addSkill(f_huoxin)
shendiaochan_change:addSkill(f_huoxinEndTurn)
shendiaochan_change:addSkill(f_huoxinPindian)
shendiaochan_change:addSkill(f_huoxin_skip)
extension:insertRelatedSkills("f_huoxin", "#f_huoxinEndTurn")
extension:insertRelatedSkills("f_huoxin", "#f_huoxinPindian")
extension:insertRelatedSkills("f_huoxin", "#f_huoxin_skip")
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("f_huooxin") then skills:append(f_huooxin) end


--2 神张角
f_shenzhangjiao = sgs.General(extension, "f_shenzhangjiao", "god", 4, true)

f_taiping = sgs.CreateTriggerSkill{
    name = "f_taiping",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
		    local plist = room:getAllPlayers()
			local target = room:askForPlayerChosen(player, plist, self:objectName())
			local dest = sgs.QVariant()
			dest:setValue(target)
			if room:askForChoice(player, self:objectName(), "tpChain+tpRestore", dest) == "tpChain" then
			    if not target:isChained() then
					room:setPlayerChained(target)
				end
			    room:broadcastSkillInvoke(self:objectName(), 1)
			else
			    if target:isChained() then
				    room:setPlayerChained(target)
			    end
			    if not target:faceUp() then
				    target:turnOver()
			    end
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
		end
	end,
}
f_shenzhangjiao:addSkill(f_taiping)

f_yaoshuCard = sgs.CreateSkillCard{
	name = "f_yaoshuCard",
	skill_name = "f_yaoshu",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    if to_select:objectName() == sgs.Self:objectName() then return false end
		return #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
	    room:doLightbox("f_yaoshuAnimate")
	    for _, ct in sgs.list(targets) do
			ct:turnOver()
			room:loseHp(ct, 1, true, source, self:objectName())
		end
		room:removePlayerMark(source, "@f_yaoshu")
		room:setPlayerFlag(source, "f_yaoshu_used")
	end,
}
f_yaoshuVS = sgs.CreateZeroCardViewAsSkill{
	name = "f_yaoshu",
	view_as = function()
		return f_yaoshuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_yaoshu") > 0
	end,
}
f_yaoshu = sgs.CreateTriggerSkill{
	name = "f_yaoshu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_yaoshu",
	view_as_skill = f_yaoshuVS,
	on_trigger = function()
	end,
}
f_shenzhangjiao:addSkill(f_yaoshu)

f_luoleiCard = sgs.CreateSkillCard{
	name = "f_luoleiCard",
	skill_name = "f_luolei",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0
	end,
	on_use = function(self, room, source, targets)
	    room:doLightbox("f_luoleiAnimate")
		local dest = targets[1]
		if not dest:isChained() then
			room:setPlayerChained(dest)
		end
	    room:damage(sgs.DamageStruct("f_luolei", source, dest, 2, sgs.DamageStruct_Thunder))
		room:broadcastSkillInvoke("sp_guimen") --借一下鬼门的配音QVQ
		local plist = room:getOtherPlayers(dest)
		for _, ct in sgs.qlist(plist) do
			if ct:distanceTo(dest) == 1 then
				Thunder(source, ct, 1)
				room:broadcastSkillInvoke("f_luoleiYD")
			end
		end
		room:removePlayerMark(source, "@f_luolei")
		room:setPlayerFlag(source, "f_luolei_used")
	end,
}
f_luoleiVS = sgs.CreateZeroCardViewAsSkill{
	name = "f_luolei",
	view_as = function()
		return f_luoleiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_luolei") > 0
	end,
}
f_luolei = sgs.CreateTriggerSkill{
	name = "f_luolei",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_luolei",
	view_as_skill = f_luoleiVS,
	on_trigger = function()
	end,
}
f_luoleiYD = sgs.CreateTriggerSkill{ --配音专用
	name = "f_luoleiYD",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end,
}
f_shenzhangjiao:addSkill(f_luolei)
if not sgs.Sanguosha:getSkill("f_luoleiYD") then skills:append(f_luoleiYD) end

SZJLimitSkillSideEffect = sgs.CreateTriggerSkill{ --“妖术”和“落雷”的副作用
    name = "SZJLimitSkillSideEffect",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if player:hasSkill("f_yaoshu") and player:hasFlag("f_yaoshu_used") then
			    room:loseHp(player, 1, true, player, self:objectName())
			end
			if player:hasSkill("f_luolei") and player:hasFlag("f_luolei_used") then
			    room:loseMaxHp(player, 1)
			end
		end
	end,
	can_trigger = function(self, player)
	    return true
	end,
}
if not sgs.Sanguosha:getSkill("SZJLimitSkillSideEffect") then skills:append(SZJLimitSkillSideEffect) end

--

--3 神张飞
f_shenzhangfei = sgs.General(extension, "f_shenzhangfei", "god", 4, true)

f_doushenCard = sgs.CreateSkillCard{
	name = "f_doushenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    room:removePlayerMark(source, "@f_doushen")
		room:setPlayerFlag(source, "f_doushenBuff")
	end,
}
f_doushenVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_doushen",
	view_as = function()
		return f_doushenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_doushen") > 0
	end,
}
f_doushen = sgs.CreateTriggerSkill{
	name = "f_doushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_doushen",
	view_as_skill = f_doushenVS,
	on_trigger = function()
	end,
}
f_doushenBuff = sgs.CreateTargetModSkill{
	name = "#f_doushenBuff",
	pattern = "Card",
	residue_func = function(self, from, card, to)
		local n = 0
		if from:hasSkill("f_doushen") and from:hasFlag("f_doushenBuff") then
			n = n + 1000
		end
		return n
	end,
}
f_shenzhangfei:addSkill(f_doushen)
f_shenzhangfei:addSkill(f_doushenBuff)
extension:insertRelatedSkills("f_doushen","#f_doushenBuff")

f_jiuweiVS = sgs.CreateViewAsSkill{
	name = "f_jiuwei",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
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
		local newana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newana, sgs.Card_MethodUse) or player:isProhibited(player, newana) then return false end
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newana)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end,
}
f_jiuwei = sgs.CreateTriggerSkill{
    name = "f_jiuwei",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = f_jiuweiVS,
    events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if player:hasSkill("f_jiuwei") and player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
		    if use.card and use.card:isKindOf("Analeptic") then
			    room:broadcastSkillInvoke("f_jiuwei", 1)
			    room:setPlayerFlag(player, "f_jiuwei_throwBuff")
				room:setPlayerFlag(player, "f_jiuwei_maxdistance")
			end
		end
	end,
}
f_jiuwei_DistanceBuff = sgs.CreateTargetModSkill{
	name = "#f_jiuwei_DistanceBuff",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("f_jiuwei") and card:isKindOf("Slash") and from:hasFlag("f_jiuwei_maxdistance") then
		    return 1000
		else
		    return 0
		end
	end,
}
f_jiuwei_removeflag = sgs.CreateTriggerSkill{
    name = "#f_jiuwei_removeflag",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() and player:hasFlag("f_jiuwei_maxdistance") then
		    room:setPlayerFlag(player, "-f_jiuwei_maxdistance")
		end
	end,
	can_trigger = function(self, player)
	    return true
	end,
}
f_jiuwei_DamageBuff = sgs.CreateTriggerSkill{
	name = "#f_jiuwei_DamageBuff",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:hasSkill("f_jiuwei") then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:hasFlag("drank") then
				    room:broadcastSkillInvoke("f_jiuwei", 2)
				    local log = sgs.LogMessage()
				    log.type = "$f_jiuwei_Damage"
				    log.from = player
				    room:sendLog(log)
					local xiahoujie = damage.damage
					damage.damage = xiahoujie + 1
					data:setValue(damage)
					player:setFlags("-f_jiuwei_throwBuff")
				end
			end
	    end
    end,
}
f_jiuwei_throwBuff = sgs.CreateTriggerSkill{
	name = "#f_jiuwei_throwBuff",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardOffset},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card and effect.card:isKindOf("Slash") then
			if effect.to:isAlive() and player:canDiscard(effect.to, "he") then
				room:broadcastSkillInvoke("f_jiuwei", 3)
				local log = sgs.LogMessage()
				log.type = "$f_jiuwei_Miss"
				log.from = player
				room:sendLog(log)
				local to_throw = room:askForCardChosen(player, effect.to, "he", "f_jiuwei", false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(to_throw), effect.to, player)
				player:setFlags("-f_jiuwei_throwBuff")
			else
				--保险的一步，确保一定得用酒【杀】才能有此效果
				player:setFlags("-f_jiuwei_throwBuff")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_jiuwei") and player:hasFlag("f_jiuwei_throwBuff")
	end,
}
f_shenzhangfei:addSkill(f_jiuwei)
f_shenzhangfei:addSkill(f_jiuwei_DistanceBuff)
f_shenzhangfei:addSkill(f_jiuwei_removeflag)
f_shenzhangfei:addSkill(f_jiuwei_DamageBuff)
f_shenzhangfei:addSkill(f_jiuwei_throwBuff)
extension:insertRelatedSkills("f_jiuwei","#f_jiuwei_DistanceBuff")
extension:insertRelatedSkills("f_jiuwei","#f_jiuwei_removeflag")
extension:insertRelatedSkills("f_jiuwei","#f_jiuwei_DamageBuff")
extension:insertRelatedSkills("f_jiuwei","#f_jiuwei_throwBuff")

--

--4 神马超
f_shenmachao = sgs.General(extension, "f_shenmachao", "god", 4, true)

f_shenqi = sgs.CreateDistanceSkill{ --马术加强版
	name = "f_shenqi",
	correct_func = function(self, from)
		if from:hasSkill(self:objectName()) or (from:hasEquipArea() and from:hasSkill("fcj_qizhou")) then
			return -2
		else
			return 0
		end
	end,
}
f_shenmachao:addSkill(f_shenqi)

f_shenlinCard = sgs.CreateSkillCard{
	name = "f_shenlinCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:setFlags("f_shenlinSource")
		effect.to:setFlags("f_shenlinTarget")
		room:addPlayerMark(effect.to, "@skill_invalidity")
		room:addPlayerMark(effect.to, "Armor_Nullified")
		room:addPlayerMark(effect.to, "&f_shenlin+to+#"..effect.from:objectName().."-Clear")
	end,
}
f_shenlin = sgs.CreateViewAsSkill{
	name = "f_shenlin",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return not to_select:isKindOf("BasicCard")
	end,
    view_as = function(self, cards)
	    if #cards == 0 then return end
		local vs_card = f_shenlinCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_shenlinCard")
	end,
}
f_shenlin_Clear = sgs.CreateTriggerSkill{
	name = "#f_shenlin_Clear",
	events = {sgs.EventPhaseChanging, sgs.Death},
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
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("f_shenlinTarget") then
				p:setFlags("-f_shenlinTarget")
				if p:getMark("@skill_invalidity") then
					room:removePlayerMark(p, "@skill_invalidity")
				end
				if p:getMark("Armor_Nullified") then
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasFlag("f_shenlinSource")
	end,
}
f_shenmachao:addSkill(f_shenlin)
f_shenmachao:addSkill(f_shenlin_Clear)
extension:insertRelatedSkills("f_shenlin","#f_shenlin_Clear")

f_shennuCard = sgs.CreateSkillCard{
    name = "f_shennuCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    room:damage(sgs.DamageStruct("f_shennu", source, source, 1, sgs.DamageStruct_Normal))
		room:drawCards(source, 1, "f_shennu")
	    room:setPlayerFlag(source, "shenzhinuhuo")
		room:broadcastSkillInvoke("f_shennu")
		room:addPlayerMark(source, "&f_shennu-Clear")
	end,
}
f_shennu = sgs.CreateZeroCardViewAsSkill{
    name = "f_shennu",
	view_as = function()
		return f_shennuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_shennuCard")
	end,
}
f_shenmachao:addSkill(f_shennu)
--来感受神之怒火吧！
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
f_shennu_youcantjink = sgs.CreateTriggerSkill{
    name = "#f_shennu_youcantjink",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
		    if use.card:isKindOf("Slash") then
		        local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			    local index = 1
			    for _, p in sgs.qlist(use.to) do
		            local _data = sgs.QVariant()
			        _data:setValue(p)
				    jink_table[index] = 0
				    index = index + 1
				end
				local jink_data = sgs.QVariant()
			    jink_data:setValue(Table2IntList(jink_table))
			    player:setTag("Jink_" .. use.card:toString(), jink_data)
			    return false
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasFlag("shenzhinuhuo")
	end,
}
f_shennu_slashmore = sgs.CreateTargetModSkill{
	name = "#f_shennu_slashmore",
	global = true,
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player, card)
		if player:hasFlag("shenzhinuhuo") and card:isKindOf("Slash") then
			return 1
		else
			return 0
		end
	end,
}
f_shennu_caozeijianzeiezeinizei = sgs.CreateTriggerSkill{
	name = "#f_shennu_caozeijianzeiezeinizei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		local doublefuck = damage.to
		if card:isKindOf("Slash") then
			local caozei = damage.damage
			if card:isRed() and doublefuck:hasFlag("suodingcaozei") then
			    room:sendCompulsoryTriggerLog(player, "f_shennu")
			    damage.damage = caozei + 2
				data:setValue(damage)
				room:setPlayerFlag(doublefuck, "-suodingcaozei")
			elseif card:isRed() and not doublefuck:hasFlag("suodingcaozei") then
			    room:sendCompulsoryTriggerLog(player, "f_shennu")
			    damage.damage = caozei + 1
				data:setValue(damage)
			elseif not card:isRed() and doublefuck:hasFlag("suodingcaozei") then
			    room:sendCompulsoryTriggerLog(player, "f_shennu")
			    damage.damage = caozei + 1
				data:setValue(damage)
				room:setPlayerFlag(doublefuck, "-suodingcaozei")
			end
        end
	end,
	can_trigger = function(self, player)
	    return player and player:hasFlag("shenzhinuhuo")
	end,
}
f_shennu_gexuqipao = sgs.CreateTriggerSkill{
    name = "#f_shennu_gexuqipao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			room:sendCompulsoryTriggerLog(player, "f_shennu")
			for _, p in sgs.qlist(use.to) do
		        local _data = sgs.QVariant()
				_data:setValue(p)
				if not p:isNude() then
		            room:askForDiscard(p, "@f_shennu_gexuqipao", 1, 1, false, true)
				else
				    room:setPlayerFlag(p, "suodingcaozei")
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasFlag("shenzhinuhuo")
	end,
}
f_shenmachao:addSkill(f_shennu_youcantjink)
f_shenmachao:addSkill(f_shennu_caozeijianzeiezeinizei)
f_shenmachao:addSkill(f_shennu_gexuqipao)
f_shenmachao:addSkill(f_shennu_slashmore)
extension:insertRelatedSkills("f_shennu","#f_shennu_youcantjink")
extension:insertRelatedSkills("f_shennu","#f_shennu_caozeijianzeiezeinizei")
extension:insertRelatedSkills("f_shennu","#f_shennu_gexuqipao")
extension:insertRelatedSkills("f_shennu","#f_shennu_slashmore")


local function isSpecialOne(player, name)
	local g_name = sgs.Sanguosha:translate(player:getGeneralName())
	if string.find(g_name, name) then return true end
	if player:getGeneral2() then
		g_name = sgs.Sanguosha:translate(player:getGeneral2Name())
		if string.find(g_name, name) then return true end
	end
	return false
end
f_caohen = sgs.CreateTriggerSkill{
	name = "f_caohen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local caocao = damage.to
		if isSpecialOne(caocao, "曹操") or (caocao:getKingdom() == "wei" and caocao:isLord()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local caocaosima = damage.damage
			damage.damage = caocaosima + 1
			data:setValue(damage)
			room:broadcastSkillInvoke(self:objectName())
		end
	end,
}
f_shenmachao:addSkill(f_caohen)

--5 神姜维
f_shenjiangwei = sgs.General(extension, "f_shenjiangwei", "god", 7, true, false, false, 4)

f_beifaCard = sgs.CreateSkillCard{
	name = "f_beifaCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:acquireOneTurnSkills(effect.from, "f_beifa", "mobiletiaoxin")
		effect.from:gainMark("&Xing")
		effect.from:setFlags("f_beifaSource")
		effect.to:setFlags("f_beifaTarget")
		room:addPlayerMark(effect.to, "@skill_invalidity")
		room:addPlayerMark(effect.to, "&f_beifa+to+#"..effect.from:objectName().."-Clear")

	end,
}
f_beifa = sgs.CreateViewAsSkill{
	name = "f_beifa",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return true
	end,
    view_as = function(self, cards)
	    if #cards == 0 then return end
		local vs_card = f_beifaCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_beifaCard")
	end,
}
f_beifa_Clear = sgs.CreateTriggerSkill{
	name = "#f_beifa_Clear",
	events = {sgs.EventPhaseChanging, sgs.Death},
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
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("f_beifaTarget") then
				p:setFlags("-f_beifaTarget")
				if p:getMark("@skill_invalidity") then
					room:removePlayerMark(p, "@skill_invalidity")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasFlag("f_beifaSource")
	end,
}
f_shenjiangwei:addSkill(f_beifa)
f_shenjiangwei:addSkill(f_beifa_Clear)
extension:insertRelatedSkills("f_beifa", "#f_beifa_Clear")
f_shenjiangwei:addRelateSkill("mobiletiaoxin")

f_fuzhi_Trigger = sgs.CreateTriggerSkill{
    name = "#f_fuzhi_Trigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		room:sendCompulsoryTriggerLog(player, "f_fuzhi")
		player:gainMark("&Xing", damage.damage)
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_fuzhi")
	end,
}
f_fuzhi = sgs.CreateTriggerSkill{
    name = "f_fuzhi",
	priority = 6, --设置优先级在“志继”之前
	frequency = sgs.Skill_Wake,
	waked_skills = "olzhiji,fz_zhiyong,fz_mouxing",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start and player:getPhase() ~= sgs.Player_Finish then return false end
		if player:getMark("f_fuzhi") > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&Xing") < 3 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doLightbox("$f_fuzhi")
		room:loseMaxHp(player, 1)
		if not player:hasSkill("olzhiji") then
		    room:acquireSkill(player, "olzhiji")
		end
		if not player:hasSkill("fz_zhiyong") then
		    room:acquireSkill(player, "fz_zhiyong")
		end
		if not player:hasSkill("fz_mouxing") then
		    room:acquireSkill(player, "fz_mouxing")
		end
		room:addPlayerMark(player, "f_fuzhi")
		player:gainMark("@WAKEDD") --大觉醒标记
	end,
}
f_shenjiangwei:addSkill(f_fuzhi)
f_shenjiangwei:addSkill(f_fuzhi_Trigger)
extension:insertRelatedSkills("f_fuzhi", "#f_fuzhi_Trigger")


--☆“智勇”
fz_zhiyong = sgs.CreateTriggerSkill{
    name = "fz_zhiyong",
	frequency = sgs.Skill_Wake,
	waked_skills = "olkanpo,ollongdan",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if not player:isWounded() then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:doLightbox("$fz_zhiyong")
	    room:broadcastSkillInvoke(self:objectName())
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		local recover = sgs.RecoverStruct()
		recover.recover = 1
		recover.who = player
		room:recover(player, recover)
		room:drawCards(player, 1, self:objectName())
		if not player:hasSkill("olkanpo") then
		    room:acquireSkill(player, "olkanpo")
		end
		if not player:hasSkill("ollongdan") then
		    room:acquireSkill(player, "ollongdan")
		end
		room:addPlayerMark(player, "fz_zhiyong")
	end,
}
if not sgs.Sanguosha:getSkill("fz_zhiyong") then skills:append(fz_zhiyong) end
f_shenjiangwei:addRelateSkill("fz_zhiyong")
f_shenjiangwei:addRelateSkill("olkanpo")
f_shenjiangwei:addRelateSkill("ollongdan")
--☆“谋兴”
mouxingDying = sgs.CreateTriggerSkill{
    name = "#mouxingDying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:addPlayerMark(player, "mouxingDying")
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:getMark("mouxingDying") == 0
	end,
}
fz_mouxing = sgs.CreateTriggerSkill{
    name = "fz_mouxing",
	frequency = sgs.Skill_Wake,
	waked_skills = "mx_xinghan, mx_hanhun",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("mouxingDying") < 1 and player:getMark("&Xing") < 12 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:doLightbox("$fz_mouxing")
		room:broadcastSkillInvoke(self:objectName())
        room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:drawCards(player, 3, self:objectName())
		if not player:hasSkill("mx_xinghan") then
		    room:acquireSkill(player, "mx_xinghan")
		end
		if not player:hasSkill("mx_hanhun") then
		    room:acquireSkill(player, "mx_hanhun")
		end
		room:addPlayerMark(player, self:objectName())
	end,
}
if not sgs.Sanguosha:getSkill("#mouxingDying") then skills:append(mouxingDying) end
if not sgs.Sanguosha:getSkill("fz_mouxing") then skills:append(fz_mouxing) end
extension:insertRelatedSkills("fz_mouxing", "#mouxingDying")
f_shenjiangwei:addRelateSkill("fz_mouxing")
  --“兴汉”
mx_xinghanCard = sgs.CreateSkillCard{
    name = "mx_xinghanCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local num = source:getMark("&Xing")
        if num >= 1 then
		    local choices = {}
			if not source:hasSkill("tenyearrende") then
			    table.insert(choices, "addskill_rende")
			end
			if not source:hasSkill("kongcheng") then
			    table.insert(choices, "addskill_kongcheng")
			end
			if not source:hasSkill("tenyearwusheng") then
			    table.insert(choices, "addskill_wusheng")
			end
			if not source:hasSkill("olpaoxiao") then
			    table.insert(choices, "addskill_paoxiao")
			end
			if not source:hasSkill("olyajiao") then
			    table.insert(choices, "addskill_yajiao")
			end
			if not source:hasSkill("tenyearliegong") then
			    table.insert(choices, "addskill_liegong")
			end
			if not source:hasSkill("tieji") then
			    table.insert(choices, "addskill_tieqi")
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(source, "mx_xinghan", table.concat(choices, "+"))
			if choice == "cancel" then
			else
				source:loseMark("&Xing")
				if choice == "addskill_rende" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","tenyearrende")
				elseif choice == "addskill_kongcheng" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","kongcheng")
				elseif choice == "addskill_wusheng" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","tenyearwusheng")
				elseif choice == "addskill_paoxiao" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","olpaoxiao")
				elseif choice == "addskill_yajiao" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","olyajiao")
				elseif choice == "addskill_liegong" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","tenyearliegong")
				elseif choice == "addskill_tieqi" then
					room:broadcastSkillInvoke("mx_xinghan")
					room:acquireNextTurnSkills(source, "mx_xinghan","tieji")
				end
			end
		end
	end,
}
mx_xinghan = sgs.CreateZeroCardViewAsSkill{
    name = "mx_xinghan",
	view_as = function()
		return mx_xinghanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&Xing") >= 1
	end,
}
f_shenjiangwei:addRelateSkill("mx_xinghan")
f_shenjiangwei:addRelateSkill("tenyearrende")
f_shenjiangwei:addRelateSkill("kongcheng")
f_shenjiangwei:addRelateSkill("tenyearwusheng")
f_shenjiangwei:addRelateSkill("olpaoxiao")
f_shenjiangwei:addRelateSkill("olyajiao")
f_shenjiangwei:addRelateSkill("tenyearliegong")
f_shenjiangwei:addRelateSkill("tieji")

if not sgs.Sanguosha:getSkill("mx_xinghan") then skills:append(mx_xinghan) end
  --“汉魂”
mx_hanhunCard = sgs.CreateSkillCard{
	name = "mx_hanhunCard",
	will_throw = true,
	target_fixed = false,
	 filter = function(self, targets, to_select)
	    return #targets == 0 and (not to_select:isLord())
	end,
	on_use = function(self, room, source, targets)
	    room:doLightbox("$mx_hanhun")
		room:removePlayerMark(source, "@mx_hanhun")
		room:loseHp(source, 1, true, source, "mx_hanhun")
		local hanhun = targets[1]
        room:addPlayerMark(hanhun, "@ZhanDouXuXing")
        room:addPlayerMark(hanhun, "&mx_hanhun+to+#"..source:objectName())
		if source:getMark("@ZhanDouXuXing") == 0 then
		    room:killPlayer(source)
		end
	end,
}
mx_hanhun = sgs.CreateViewAsSkill{
	name = "mx_hanhun",
	n = 3,
	limit_mark = "@mx_hanhun",
	view_filter = function(self, selected, to_select)
	    if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getTypeId() ~= card:getTypeId() then
				return not to_select:isEquipped()
			end
		elseif #selected == 2 then
		    local card1 = selected[1]
			local card2 = selected[2]
			if to_select:getTypeId() ~= card1:getTypeId() and to_select:getTypeId() ~= card2:getTypeId() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
	    if #cards == 3 then
			local cardA = cards[1]
			local cardB = cards[2]
			local cardC = cards[3]
			local hh = mx_hanhunCard:clone()
		    hh:addSubcard(cardA)
			hh:addSubcard(cardB)
			hh:addSubcard(cardC)
			hh:setSkillName(self:objectName())
			return hh
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@mx_hanhun") > 0
	end,
}
f_shenjiangwei:addRelateSkill("mx_hanhun")

f_hanhunRevive = sgs.CreateTriggerSkill{
    name = "#f_hanhunRevive",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local death = data:toDeath()
		local hanhun = death.who
		if hanhun:getMark("@ZhanDouXuXing") > 0 and hanhun:getMaxHp() > 0 then
		    room:sendCompulsoryTriggerLog(player, "mx_hanhun")
			local m = hanhun:getHp()
		    room:revivePlayer(hanhun)
			local n = hanhun:getMaxHp()
			local rec = sgs.RecoverStruct()
			rec.who = hanhun
			rec.recover = n - m
			room:recover(hanhun, rec)
			room:broadcastSkillInvoke("f_hanhunRevive")
			room:removePlayerMark(hanhun, "@ZhanDouXuXing")
			room:drawCards(hanhun, 4, "mx_hanhun")
	    	room:setPlayerProperty(hanhun, "maxhp", sgs.QVariant(5))
	    	room:setPlayerProperty(hanhun, "kingdom", sgs.QVariant("shu"))
			room:acquireSkill(hanhun, "f_hunsan")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("@ZhanDouXuXing") > 0
	end,
}
    --“魂散”
f_hunsan = sgs.CreateTriggerSkill{
    name = "f_hunsan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if player:getPhase() == sgs.Player_Finish then
		    room:sendCompulsoryTriggerLog(player, self:objectName())
		    room:loseHp(player, 1, true, player, "f_hunsan")
		end
	end,
}
f_shenjiangwei:addRelateSkill("f_hunsan")
if not sgs.Sanguosha:getSkill("mx_hanhun") then skills:append(mx_hanhun) end
if not sgs.Sanguosha:getSkill("#f_hanhunRevive") then skills:append(f_hanhunRevive) end
if not sgs.Sanguosha:getSkill("f_hunsan") then skills:append(f_hunsan) end
extension:insertRelatedSkills("mx_hanhun", "#f_hanhunRevive")

--6 神邓艾
f_shendengai = sgs.General(extension, "f_shendengai", "god", 6, true, false, false, 2)

f_zhiqu = sgs.CreateTargetModSkill{
	name = "f_zhiqu",
	--global = true,
	pattern = "Card",
	distance_limit_func = function(self, from, card)
		if from:getMark("&mark_zhanshan") > 0 and from:hasFlag("f_zhiqu_blackBuff") and card:isBlack() then
			return 1000
		else
			return 0
		end
	end,
}
f_zhiquu = sgs.CreateTriggerSkill{
	name = "#f_zhiquu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getMark("&mark_zhanshan") > 0 then
		    room:setPlayerFlag(player, "f_zhiqu_blackBuff")
		else
		    if room:getCurrent():objectName() == player:objectName() and player:getMark("&mark_zhanshan") > 0 then
		        local use = data:toCardUse()
				local di = room:findPlayerBySkillName("f_zhiqu")
			    if not di then return false end
			    if not use.card then return false end
				if use.card:isBlack() then
				    room:sendCompulsoryTriggerLog(di, "f_zhiqu")
			        room:broadcastSkillInvoke("f_zhiqu", 1)
				elseif use.card:isRed() then
				    room:sendCompulsoryTriggerLog(di, "f_zhiqu")
			        room:drawCards(player, 1, "f_zhiqu")
				    room:broadcastSkillInvoke("f_zhiqu", 2)
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&mark_zhanshan") > 0
	end,
}
f_shendengai:addSkill(f_zhiqu)
f_shendengai:addSkill(f_zhiquu)
extension:insertRelatedSkills("f_zhiqu", "#f_zhiquu")

f_zhanshan_GMS = sgs.CreateTriggerSkill{
    name = "#f_zhanshan_GMS",
	priority = 10,
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards}, --时机：分发起始手牌时
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "InitialHandCards" then return false end
		draw.num = draw.num + 2
		data:setValue(draw)
		local count = room:alivePlayerCount()
		player:gainMark("&mark_zhanshan", count)
		room:broadcastSkillInvoke("f_zhanshan", 1)
		room:sendCompulsoryTriggerLog(player, "f_zhanshan")
	end,
}
f_zhanshanCard = sgs.CreateSkillCard{
    name = "f_zhanshanCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    local num = source:getMark("&mark_zhanshan")
        if num >= 1 then
		    room:broadcastSkillInvoke("f_zhanshan", 4)
		    source:loseMark("&mark_zhanshan")
			local weibing = targets[1]
			weibing:gainMark("&mark_zhanshan")
		end
	end,
}
f_zhanshanVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_zhanshan",
	view_as = function()
	    return f_zhanshanCard:clone()
	end,
	enabled_at_play = function(self, player)
	    return player:hasSkill(self:objectName()) and player:getMark("&mark_zhanshan") >= 1
	end,
}
f_zhanshan = sgs.CreateTriggerSkill{
    name = "f_zhanshan",
	view_as_skill = f_zhanshanVS,
	events = {sgs.EventPhaseStart, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:hasSkill("f_zhanshan") and player:getPhase() == sgs.Player_Start and player:getMark("&mark_zhanshan") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:loseMaxHp(player, 1)
			    player:gainMark("&mark_zhanshan")
				room:broadcastSkillInvoke("f_zhanshan", 2)
			end
		elseif event == sgs.Death then
		    local di = room:findPlayersBySkillName("f_zhanshan")
			if not di then return false end
		    local death = data:toDeath()
		    if death.who:objectName() == player:objectName() then return false end
            for _, p in sgs.qlist(di) do
			    if room:askForSkillInvoke(p, self:objectName(), data) then
                    p:gainMark("&mark_zhanshan")
                    room:broadcastSkillInvoke("f_zhanshan", 3)
				end
            end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_zhanshan")
	end,
}


f_zhanshanbuff = sgs.CreateTriggerSkill{
    name = "f_zhanshanbuff",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Normal and damage.to:getMark("&mark_zhanshan") > 0 then
		    room:broadcastSkillInvoke("f_zhanshan", 5)
			player:loseMark("&mark_zhanshan")
		    return damage.damage
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("&mark_zhanshan") > 0
	end,
}
f_shendengai:addSkill(f_zhanshan_GMS)
f_shendengai:addSkill(f_zhanshan)
extension:insertRelatedSkills("f_zhanshan", "#f_zhanshan_GMS")
if not sgs.Sanguosha:getSkill("f_zhanshanbuff") then skills:append(f_zhanshanbuff) end

--7 <汉中王>神刘备
hzw_shenliubei = sgs.General(extension, "hzw_shenliubei$", "god", 5, true, false, false, 3)

f_jieyiCard = sgs.CreateSkillCard{
	name = "f_jieyiCard",
	skill_name = "f_jieyi",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    if to_select:objectName() == sgs.Self:objectName() then return false end
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
	    room:doLightbox("f_jieyiAnimate")
		local guanyu = targets[1]
		local zhangfei = targets[2]
		room:addPlayerMark(source, "&XD")
		room:addPlayerMark(guanyu, "&XD")
		room:addPlayerMark(zhangfei, "&XD")
		if not source:hasSkill("jy_yizhi") then
		    room:acquireSkill(source, "jy_yizhi")
		end
		if not guanyu:hasSkill("jy_yizhi") then
		    room:acquireSkill(guanyu, "jy_yizhi")
		end
		if not zhangfei:hasSkill("jy_yizhi") then
		    room:acquireSkill(zhangfei, "jy_yizhi")
		end
		room:removePlayerMark(source, "@f_jieyi")
		--room:broadcastSkillInvoke("f_jieyi")
	end,
}
f_jieyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "f_jieyi",
	view_as = function()
		return f_jieyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_jieyi") > 0
	end,
}
f_jieyi = sgs.CreateTriggerSkill{
	name = "f_jieyi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_jieyi",
	view_as_skill = f_jieyiVS,
	on_trigger = function()
	end,
}
hzw_shenliubei:addSkill(f_jieyi)
hzw_shenliubei:addRelateSkill("jy_yizhi")
jy_yizhi = sgs.CreateTriggerSkill{ --为了符合“义志”的“全局生效”而做出的空壳
	name = "jy_yizhi",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end,
}
yizhiDraw = sgs.CreateTriggerSkill{
	name = "#yizhiDraw",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		draw.num = draw.num + 1
		data:setValue(draw)
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&XD") > 0
	end,
}
yizhiLoyalCard = sgs.CreateSkillCard{
    name = "yizhiLoyalCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:getMark("&XD") > 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    targets[1]:obtainCard(self, false)
		room:broadcastSkillInvoke("jy_yizhi")
	end,
}
yizhiLoyalVS = sgs.CreateViewAsSkill{
    name = "yizhiLoyal",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return true
	end,
    view_as = function(self, cards)
	    if #cards == 0 then return end
		local vs_card = yizhiLoyalCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	response_pattern = "@@yizhiLoyal",
}
yizhiLoyal = sgs.CreateTriggerSkill{
    name = "#yizhiLoyal",
	events = {sgs.EventPhaseEnd},
	view_as_skill = yizhiLoyalVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
		    room:askForUseCard(player, "@@yizhiLoyal", "@yizhiLoyal-card1")
		    room:askForUseCard(player, "@@yizhiLoyal", "@yizhiLoyal-card2")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&XD") > 0
	end,
}
yizhiRescue = sgs.CreateTriggerSkill{
    name = "#yizhiRescue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local rec = data:toRecover()
		if rec.card:isKindOf("Peach") and rec.who:getMark("&XD") > 0 and rec.who:objectName() ~= player:objectName() then
			local log = sgs.LogMessage()
			log.type = "$yizhiREC"
			log.from = player
			room:sendLog(log)
			rec.recover = rec.recover + 1
			data:setValue(rec)
			room:broadcastSkillInvoke("jy_yizhi")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&XD") > 0
	end,
}
if not sgs.Sanguosha:getSkill("jy_yizhi") then skills:append(jy_yizhi) end
if not sgs.Sanguosha:getSkill("#yizhiDraw") then skills:append(yizhiDraw) end
if not sgs.Sanguosha:getSkill("#yizhiLoyal") then skills:append(yizhiLoyal) end
if not sgs.Sanguosha:getSkill("#yizhiRescue") then skills:append(yizhiRescue) end
extension:insertRelatedSkills("jy_yizhi","#yizhiDraw")
extension:insertRelatedSkills("jy_yizhi","#yizhiLoyal")
extension:insertRelatedSkills("jy_yizhi","#yizhiRescue")

f_renyiCard = sgs.CreateSkillCard{
    name = "f_renyiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:drawCards(source, 3, "f_renyi")
		room:askForUseCard(source, "@@f_renyiX!", "@f_renyiX-card")
	end,
}
f_renyi = sgs.CreateViewAsSkill{
    name = "f_renyi",
	view_filter = function(self, selected, to_select)
	    return true
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return f_renyiCard:clone()
		else
			if #cards > 0 then 
				local RX_card = f_renyiXCard:clone()
				for _, c in pairs(cards) do
					RX_card:addSubcard(c)
				end
				RX_card:setSkillName("f_renyi")
				return RX_card
			end
		end
		
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_renyiCard")
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern=="@@f_renyiX!" then return true end
		return string.startsWith(pattern, "@@f_renyiX")
	end,
}
f_renyiXCard = sgs.CreateSkillCard{
    name = "f_renyiXCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    targets[1]:obtainCard(self, false)
		room:broadcastSkillInvoke("f_renyi", math.random(1,2))
		if targets[1]:getMark("&XD") > 0 then
		    room:addPlayerMark(targets[1], "f_renyiBUFF")
		end
		if source:isKongcheng() then
		    room:drawCards(source, 2, "f_renyi")
		end
		if source:getEquips():isEmpty() then
		    local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end,
}

f_renyiBuff = sgs.CreateTriggerSkill{
    name = "#f_renyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if player:getMark("f_renyiBUFF") > 0 and damage.card:isDamageCard() then
		    	local ren = damage.damage
				local n = player:getMark("f_renyiBUFF")
				damage.damage = ren + n
				data:setValue(damage)
				room:broadcastSkillInvoke("f_renyi", 3)
				local log = sgs.LogMessage()
				log.type = "$f_renyiBufff"
				log.from = player
				log.arg2 = n
				room:sendLog(log)
				room:removePlayerMark(player, "f_renyiBUFF", n)
			end
		elseif event == sgs.CardFinished then
		    local use = data:toCardUse()
			if player:getMark("f_renyiBUFF") > 0 and use.card:isDamageCard() then
				local m = player:getMark("f_renyiBUFF")
				room:removePlayerMark(player, "f_renyiBUFF", m)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&XD") > 0 and player:getMark("f_renyiBUFF") > 0
	end,
}
hzw_shenliubei:addSkill(f_renyi)
hzw_shenliubei:addSkill(f_renyiBuff)
extension:insertRelatedSkills("f_renyi","#f_renyiBuff")


f_chengwang_DamageRecord = sgs.CreateTriggerSkill{
    name = "#f_chengwang_DamageRecord",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		for _,LiuXD in sgs.qlist(room:findPlayersBySkillName("f_chengwang"))do
			if LiuXD:hasLordSkill("f_chengwang") then
				LiuXD:gainMark("&f_chengwang_DR", damage.damage)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and (player:getMark("&XD") > 0 or player:hasLordSkill("f_chengwang"))
	end,
}
f_chengwang = sgs.CreateTriggerSkill{
    name = "f_chengwang$",
	frequency = sgs.Skill_Wake,
	waked_skills = "f_hanzhongwang",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive or player:getMark(self:objectName()) > 0 then return false end
		if player:hasLordSkill(self:objectName()) then
			if player:canWake(self:objectName()) then return true end
			if player:getMark("@f_jieyi") > 0 or player:getMark("&f_chengwang_DR") < 12 then return false end
			return true
		end
		return false
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover)
		room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("hzw_shenliubei", self:objectName())
		if not player:hasSkill("f_hanzhongwang") then
		    room:acquireSkill(player, "f_hanzhongwang")
		end
		room:addPlayerMark(player, self:objectName())
	end,
}
hzw_shenliubei:addSkill(f_chengwang)
hzw_shenliubei:addSkill(f_chengwang_DamageRecord)
extension:insertRelatedSkills("f_chengwang","#f_chengwang_DamageRecord")
--“汉中王”
f_hanzhongwangCard = sgs.CreateSkillCard{
    name = "f_hanzhongwangCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return to_select:getKingdom() == "shu" and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isAllNude()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		if effect.from:isAlive() and effect.to:isAlive() and not effect.to:isAllNude() then
			local card_id = room:askForCardChosen(effect.from, effect.to, "hej", "f_hanzhongwang")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
			room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, false)
			room:broadcastSkillInvoke("f_hanzhongwang", 2)
			room:addPlayerMark(effect.to, "f_hanzhongwangBUFF")
			room:addPlayerMark(effect.to, "&f_hanzhongwang+to+#"..effect.from:objectName().."-SelfClear")
		end
	end,
}
f_hanzhongwangVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_hanzhongwang",
    view_as = function()
		return f_hanzhongwangCard:clone()
	end,
	response_pattern = "@@f_hanzhongwang",
}
f_hanzhongwang = sgs.CreateTriggerSkill{
    name = "f_hanzhongwang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = f_hanzhongwangVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local rencai = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "f_hanzhongwang-invoke", true, true)
			if not rencai then return false end
			room:setPlayerProperty(rencai, "kingdom", sgs.QVariant("shu"))
			room:broadcastSkillInvoke(self:objectName(), 1)
		elseif player:getPhase() == sgs.Player_Play then
		    room:askForUseCard(player, "@@f_hanzhongwang", "@f_hanzhongwang-card")
		end
	end,
}
f_hanzhongwang_BuffandClear = sgs.CreateTriggerSkill{
    name = "#f_hanzhongwang_BuffandClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.ConfirmDamage then
		    if player:getPhase() ~= sgs.Player_NotActive and player:getMark("f_hanzhongwangBUFF") > 0 then
			    local dmg = damage.damage
				damage.damage = dmg + 1
			    data:setValue(damage)
			    room:broadcastSkillInvoke("f_hanzhongwang", 3)
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:isAlive() and player:getMark("f_hanzhongwangBUFF") > 0 then
			    room:removePlayerMark(player, "f_hanzhongwangBUFF")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("f_hanzhongwangBUFF") > 0
	end,
}
if not sgs.Sanguosha:getSkill("f_hanzhongwang") then skills:append(f_hanzhongwang) end
if not sgs.Sanguosha:getSkill("#f_hanzhongwang_BuffandClear") then skills:append(f_hanzhongwang_BuffandClear) end
extension:insertRelatedSkills("f_hanzhongwang","#f_hanzhongwang_BuffandClear")


--8 神黄忠
f_shenhuangzhong = sgs.General(extension, "f_shenhuangzhong", "god", 4, true)

f_shengong = sgs.CreateTriggerSkill{
    name = "f_shengong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:drawCards(player, 10, self:objectName())
		room:broadcastSkillInvoke(self:objectName(), 1)
		if not player:isKongcheng() then
		    local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		        if card_id then
				card_id:deleteLater()
			    card_id = room:askForExchange(player, self:objectName(), 10, 10, false, "f_shengongPush")
			end
			player:addToPile("ShenJian", card_id)
			room:addPlayerMark(player, "f_shengong_triggered")
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName()) and player:getMark("f_shengong_triggered") == 0 and player:getPhase() == sgs.Player_RoundStart
	end,
}

--根据“神箭”数量拥有对应效果：
f_shengongBuff_4SJ = sgs.CreateTargetModSkill{
    name = "#f_shengongBuff_4SJ",
	pattern = "Slash",
	distance_limit_func = function(self, from)
	    if from:hasSkill("f_shengong") and from:getPile("ShenJian"):length() >= 4 then
			return 1000
		else
			return 0
		end
	end,
}
f_shengongBuff_8SJ = sgs.CreateTriggerSkill{
    name = "#f_shengongBuff_8SJ",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
		    if use.card:isKindOf("Slash") then
		        local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			    local index = 1
			    for _, p in sgs.qlist(use.to) do
		            local _data = sgs.QVariant()
			        _data:setValue(p)
				    jink_table[index] = 0
				    index = index + 1
				end
				local jink_data = sgs.QVariant()
			    jink_data:setValue(Table2IntList(jink_table))
			    player:setTag("Jink_" .. use.card:toString(), jink_data)
			    return false
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_shengong") and player:getPile("ShenJian"):length() >= 8
	end,
}
f_shengongBuff_12SJ = sgs.CreateTriggerSkill{
	name = "#f_shengongBuff_12SJ",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") then
		    room:sendCompulsoryTriggerLog(player, "f_shengong")
			local xiahouyuan = damage.damage
			damage.damage = xiahouyuan + 1
			data:setValue(damage)
			room:broadcastSkillInvoke("f_shengong", 2)
			room:sendCompulsoryTriggerLog(player, "f_shengong")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_shengong") and player:getPile("ShenJian"):length() >= 12
	end,
}
f_shengongBuff_16SJ = sgs.CreateTriggerSkill{
	name = "#f_shengongBuff_16SJ",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		local use = data:toCardUse()
		card = use.card
		if card:isKindOf("Slash") then
		    room:sendCompulsoryTriggerLog(player, "f_shengong")
			room:drawCards(player, 1, "f_shengong")
			room:broadcastSkillInvoke("f_shengong", 2)
			if not player:isKongcheng() then
				local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if card_id then
				    card_id:deleteLater()
					card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "f_shengong16SJPush")
				end
				player:addToPile("ShenJian", card_id)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_shengong") and player:getPile("ShenJian"):length() >= 16
	end,
}
f_shenhuangzhong:addSkill(f_shengong)
f_shenhuangzhong:addSkill(f_shengongBuff_4SJ)
f_shenhuangzhong:addSkill(f_shengongBuff_8SJ)
f_shenhuangzhong:addSkill(f_shengongBuff_12SJ)
f_shenhuangzhong:addSkill(f_shengongBuff_16SJ)
extension:insertRelatedSkills("f_shengong","#f_shengongBuff_4SJ")
extension:insertRelatedSkills("f_shengong","#f_shengongBuff_8SJ")
extension:insertRelatedSkills("f_shengong","#f_shengongBuff_12SJ")
extension:insertRelatedSkills("f_shengong","#f_shengongBuff_16SJ")


--“定军”（修改前）
f_dingjunCard = sgs.CreateSkillCard{ --配合触发视为技
    name = "f_dingjunCard",
	target_fixed = true,
	on_use = function()
		
	end,
}
f_dingjun = sgs.CreateZeroCardViewAsSkill{
    name = "f_dingjun",
	waked_skills = "tenyearliegong,f_luanshe",
	view_as = function()
		return f_dingjunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("f_dingjunCard_used")
	end,
}
f_dingjunTrigger = sgs.CreateTriggerSkill{
    name = "#f_dingjunTrigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	view_as_skill = getFShenJianSkillVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if table.contains(use.card:getSkillNames(), "f_dingjun") then
		    local choices = {}
		    if player:getMark("DJSZhanGong") == 0 and not player:hasFlag("f_dingjunCard_used") and player:getPile("ShenJian"):length() >= 4 then
			    table.insert(choices, "get4ShenJian")
		    end
		    if player:getMark("DJSZhanGong") == 0 and not player:hasFlag("f_dingjunCard_used") and player:getHandcardNum() >= 4 then
			    table.insert(choices, "add4ShenJian")
		    end
		    table.insert(choices, "cancel")
		    local choice = room:askForChoice(player, "f_dingjun", table.concat(choices, "+"))
		    if choice == "get4ShenJian" then
			    if room:askForUseCard(player, "@@getFShenJianSkill", "@getFShenJianSkill-card") then
				    room:setPlayerFlag(player, "f_dingjunCard_used")
			    end
		    elseif choice == "add4ShenJian" then
			    local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			    if card_id then
				    card_id:deleteLater()
				    card_id = room:askForExchange(player, "f_dingjun", 4, 4, false, "f_dingjunA4Push")
			    end
			    player:addToPile("ShenJian", card_id)
			    room:acquireSkill(player, "f_luanshe")
			    room:setPlayerFlag(player, "f_dingjunCard_used")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_dingjun")
	end,
}
f_shenhuangzhong:addSkill(f_dingjun)
f_shenhuangzhong:addSkill(f_dingjunTrigger)
extension:insertRelatedSkills("f_dingjun","#f_dingjunTrigger")
f_shenhuangzhong:addRelateSkill("tenyearliegong")
f_shenhuangzhong:addRelateSkill("f_luanshe")

--“定军”（修改后）
f_newdingjunCard = sgs.CreateSkillCard{
    name = "f_newdingjunCard",
	target_fixed = true,
	on_use = function()
	end,
}
f_newdingjun = sgs.CreateZeroCardViewAsSkill{
    name = "f_newdingjun",
	view_as = function()
		return f_newdingjunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("get1to4ShenJian_used") or not player:hasFlag("add1to4ShenJian_used")
	end,
}
f_newdingjunTrigger = sgs.CreateTriggerSkill{
    name = "#f_newdingjunTrigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	global = true,
	view_as_skill = getOTFShenJianSkillVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if table.contains(use.card:getSkillNames(), "f_newdingjun") then
		    local choices = {}
		    if player:getMark("DJSZhanGong") > 0 and not player:hasFlag("get1to4ShenJian_used") and player:getPile("ShenJian"):length() >= 1 then
			    table.insert(choices, "get1to4ShenJian")
		    end
		    if player:getMark("DJSZhanGong") > 0 and not player:hasFlag("add1to4ShenJian_used") and not player:isKongcheng() then
			    table.insert(choices, "add1to4ShenJian")
		    end
		    table.insert(choices, "cancel")
		    local choice = room:askForChoice(player, "f_newdingjun", table.concat(choices, "+"))
		    if choice == "get1to4ShenJian" then
			    if room:askForUseCard(player, "@@getOTFShenJianSkill", "@getOTFShenJianSkill-card") then
				    room:setPlayerFlag(player, "get1to4ShenJian_used")
			    end
		    elseif choice == "add1to4ShenJian" then
			    local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			    if card_id then
				    card_id:deleteLater()
				    card_id = room:askForExchange(player,  "f_newdingjun", 4, 1, false, "f_dingjunA1to4Push")
			    end
			    player:addToPile("ShenJian", card_id)
			    room:acquireSkill(player, "f_luanshe")
			    room:setPlayerFlag(player, "add1to4ShenJian_used")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_newdingjun")
	end,
}
if not sgs.Sanguosha:getSkill("f_newdingjun") then skills:append(f_newdingjun) end
if not sgs.Sanguosha:getSkill("#f_newdingjunTrigger") then skills:append(f_newdingjunTrigger) end
----
  --为选项1（未修改）写的技能卡牌：
getFShenJianSkillCard = sgs.CreateSkillCard{
    name = "getFShenJianSkillCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    source:obtainCard(self, false)
		if not source:hasSkill("tenyearliegong") then
		    room:acquireSkill(source, "tenyearliegong")
		end
	end,
}
getFShenJianSkillVS = sgs.CreateViewAsSkill{
    name = "getFShenJianSkill",
    n = 4,
	expand_pile = "ShenJian",
	view_filter = function(self, selected, to_select)
	    return sgs.Self:getPile("ShenJian"):contains(to_select:getId())
	end,
    view_as = function(self, cards)
	    if #cards == 4 then
		    local cardA = cards[1]
		    local cardB = cards[2]
		    local cardC = cards[3]
		    local cardD = cards[4]
		    local vs = getFShenJianSkillCard:clone()
		    vs:addSubcard(cardA)
		    vs:addSubcard(cardB)
		    vs:addSubcard(cardC)
		    vs:addSubcard(cardD)
		    vs:setSkillName("f_dingjun")
		    return vs
		end
	end,
	enabled_at_play = function(self, player)
	    return player:hasSkill("f_dingjun") and not player:hasUsed("#getFShenJianSkillCard") and player:getPile("ShenJian"):length() >= 4
	end,
	response_pattern = "@@getFShenJianSkill",
}
if not sgs.Sanguosha:getSkill("getFShenJianSkill") then skills:append(getFShenJianSkillVS) end
  --为选项1（修改后）写的技能卡牌：
getOTFShenJianSkillCard = sgs.CreateSkillCard{
    name = "getOTFShenJianSkillCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    source:obtainCard(self, false)
		if not source:hasSkill("tenyearliegong") then
		    room:acquireSkill(source, "tenyearliegong")
		end
	end,
}
getOTFShenJianSkillVS = sgs.CreateViewAsSkill{
    name = "getOTFShenJianSkill",
    n = 4,
	expand_pile = "ShenJian",
	view_filter = function(self, selected, to_select)
	    return sgs.Self:getPile("ShenJian"):contains(to_select:getId())
	end,
    view_as = function(self, cards)
	    if #cards >= 1 and #cards <= 4 then
			local c = getOTFShenJianSkillCard:clone()
			for _, card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end,
	enabled_at_play = function(self, player)
	    return player:hasSkill("f_newdingjun") and not player:hasUsed("#getOTFShenJianSkillCard") and player:getPile("ShenJian"):length() >= 1
	end,
	response_pattern = "@@getOTFShenJianSkill",
}
if not sgs.Sanguosha:getSkill("getOTFShenJianSkill") then skills:append(getOTFShenJianSkillVS) end
----
f_dingjun_SkillClear = sgs.CreateTriggerSkill{
    name = "#f_dingjun_SkillClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
		    if player:hasFlag("f_dingjunCard_used") or player:hasFlag("get1to4ShenJian_used") or player:hasFlag("f_dingjun_SkillClear") then
			    if player:hasSkill("tenyearliegong") then
			        room:detachSkillFromPlayer(player, "tenyearliegong", false, true)
				end
			end
			if player:hasSkill("f_luanshe") and (player:hasFlag("f_dingjunCard_used") or player:hasFlag("add1to4ShenJian_used") or player:hasFlag("f_dingjun_SkillClear")) then
			    room:detachSkillFromPlayer(player, "f_luanshe", false, true)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and (player:hasSkill("f_dingjun") or player:hasSkill("f_newdingjun"))
	end,
}
if not sgs.Sanguosha:getSkill("#f_dingjun_SkillClear") then skills:append(f_dingjun_SkillClear) end
extension:insertRelatedSkills("f_newdingjun","#f_dingjun_SkillClear")
extension:insertRelatedSkills("f_dingjun","#f_dingjun_SkillClear")
--“乱射”
f_luansheVS = sgs.CreateViewAsSkill{
	name = "f_luanshe",
	n = 999,
	expand_pile = "ShenJian",
	view_filter = function(self, selected, to_select)
	    local x = math.max(1, sgs.Self:getHp())
		local y = x + x
		if #selected >= y then return false end
		return sgs.Self:getPile("ShenJian"):contains(to_select:getId())
	end,
	view_as = function(self, cards)
	    local x = math.max(1, sgs.Self:getHp())
		local y = x + x
		if #cards ~= y then return end
	    local ls_card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
		if ls_card then
			ls_card:setSkillName(self:objectName())
			for _, z in ipairs(cards) do
				ls_card:addSubcard(z)
			end
		end
		return ls_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("f_luanshe_used") and player:getPile("ShenJian"):length() >= 1
	end,
}
f_luanshe = sgs.CreateTriggerSkill{
	name = "f_luanshe",
	view_as_skill = f_luansheVS,
	events = {sgs.CardUsed, sgs.ConfirmDamage, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		    local card = data:toCardUse().card
			if player:getPhase() == sgs.Player_Play and table.contains(card:getSkillNames(), "f_luanshe") then
		        room:setPlayerFlag(player, "f_luanshe_used")
			end
		elseif event == sgs.ConfirmDamage then
		    local damage = data:toDamage()
			local card = damage.card
		    if card:isKindOf("ArcheryAttack") and table.contains(card:getSkillNames(), "f_luanshe") then
		        local CH = damage.damage
				--暴击
				if math.random() > 0.5 then
			        damage.damage = CH + CH
				end
			    data:setValue(damage)
			end
		elseif event == sgs.Damage then
		    local damage = data:toDamage()
			local card = damage.card
			if card:isKindOf("ArcheryAttack") and table.contains(card:getSkillNames(), "f_luanshe") then
		        room:drawCards(player, damage.damage, "f_luanshe")
		        if not player:isKongcheng() then
			        local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			        if card_id then
				        card_id:deleteLater()
						card_id = room:askForExchange(player, "f_luanshe", damage.damage, damage.damage, false, "f_luansheXPush")
			        end
			        player:addToPile("ShenJian", card_id)
				end
			end
			room:broadcastSkillInvoke("f_luanshe")
		end
	end,
}
if not sgs.Sanguosha:getSkill("f_luanshe") then skills:append(f_luanshe) end

f_huanghansheng = sgs.CreateTriggerSkill{
	name = "f_huanghansheng",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Death, sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
		    local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() then
		        local killer
		        if death.damage then
			        killer = death.damage.from
		        else
			        killer = nil
		        end
		        local current = room:getCurrent()
		        if killer:hasSkill(self:objectName()) and killer:getMark("DJSZhanGong") == 0 and (current:isAlive() or current:objectName() == death.who:objectName()) and killer:getMark("hhh_triggered") == 0 then
			        --使命成功
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:doLightbox("$DJSZhanGong")
					local log = sgs.LogMessage()
				    log.type = "$hanshengSUC"
				    log.from = killer
				    room:sendLog(log)
				    room:drawCards(killer, 4, self:objectName())
			        killer:addMark("DJSZhanGong")
					if killer:hasSkill("f_dingjun") then
					    room:detachSkillFromPlayer(killer, "f_dingjun", true)
					end
					room:attachSkillToPlayer(killer, "f_newdingjun")
					if killer:hasFlag("f_dingjunCard_used") then
						room:setPlayerFlag(killer, "-f_dingjunCard_used")
						room:setPlayerFlag(killer, "f_dingjun_SkillClear")
					end
		        end
			end
		elseif event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:getMark("DJSZhanGong") == 0 and player:getMark("hhh_triggered") == 0 then
			    --使命失败
				local log = sgs.LogMessage()
				log.type = "$hanshengFAL"
				log.from = player
				room:sendLog(log)
			    local maxhp = player:getMaxHp()
				local recover = math.min(1 - player:getHp(), maxhp - player:getHp()) --local hp = math.min(1, maxhp)
				room:recover(player, sgs.RecoverStruct(player, nil, recover)) --room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:throwEquipArea()
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:addPlayerMark(player, "hhh_triggered")
			end
		end   
	end,
}
f_shenhuangzhong:addSkill(f_huanghansheng)

--9 神项羽
f_shenxiangyu = sgs.General(extension, "f_shenxiangyu", "god", 4, true)

f_bawangCard = sgs.CreateSkillCard{
    name = "f_bawangCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    if #targets == 1 then return false
		else return true
		end
	end,
	on_use = function(self, room, source, targets)
	    local dest = targets[1]
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = dest
		damage.nature = sgs.DamageStruct_Normal
		room:damage(damage)
		room:broadcastSkillInvoke(self:objectName())
        room:drawCards(source, 1, "f_bawang")
	end,
}
f_bawangVS = sgs.CreateViewAsSkill{
    name = "f_bawang",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
	    if #cards == 0 then return end
		local vs_card = f_bawangCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, player)
	    return not player:hasUsed("#f_bawangCard")
	end,
}
f_bawang = sgs.CreateTriggerSkill{
    name = "f_bawang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    local card = data:toCardUse().card
		if player:hasSkill("f_bawang") and player:getPhase() == sgs.Player_Play and card:isKindOf("Slash") then
		    room:setPlayerFlag(player, "f_bawang_used")
		end
	end,
}
f_bawangMaxCards = sgs.CreateMaxCardsSkill{
	name = "#f_bawangMaxCards",
	extra_func = function(self, target)
		if target:hasSkill("f_bawang") and target:hasFlag("f_bawang_used") then
			return -1
		else
			return 0
		end
	end,
}
f_shenxiangyu:addSkill(f_bawang)
f_shenxiangyu:addSkill(f_bawangMaxCards)
extension:insertRelatedSkills("f_bawang","#f_bawangMaxCards")


f_zhuifeng = sgs.CreateTargetModSkill{
	name = "f_zhuifeng",
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and from:getWeapon() == nil and card:isKindOf("Slash") then
		local hp = from:getLostHp()
		    return 1 + hp
		else
		    return 0
		end
	end,
}
f_zhuifengX = sgs.CreateTargetModSkill{
	name = "#f_zhuifengX",
	extra_target_func = function(self, from, card)
		if from:hasSkill("f_zhuifeng") and from:getArmor() == nil then
		local hp = from:getLostHp()
		    return 1 + hp
		else
			return 0
		end
	end,
}
f_zhuifengAudio = sgs.CreateTriggerSkill{
    name = "#f_zhuifengAudio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local use = data:toCardUse()
		if player:hasSkill("f_zhuifeng") and use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("f_zhuifeng")
		end
	end,
}
f_shenxiangyu:addSkill(f_zhuifeng)
f_shenxiangyu:addSkill(f_zhuifengX)
f_shenxiangyu:addSkill(f_zhuifengAudio)
extension:insertRelatedSkills("f_zhuifeng","#f_zhuifengX")
extension:insertRelatedSkills("f_zhuifeng","#f_zhuifengAudio")


f_wuzhui = sgs.CreateDistanceSkill{
	name = "f_wuzhui",
	correct_func = function(self, from)
		if from:hasSkill(self:objectName()) and from:getOffensiveHorse() == nil then
			return -1
		else
			return 0
		end
	end,
}
f_wuzhuiMaxCards = sgs.CreateMaxCardsSkill{
	name = "#f_wuzhuiMaxCards",
	extra_func = function(self, target)
		if target:hasSkill("f_wuzhui") and target:getDefensiveHorse() == nil then
			return 1
		else
			return 0
		end
	end,
}
f_shenxiangyu:addSkill(f_wuzhui)
f_shenxiangyu:addSkill(f_wuzhuiMaxCards)
extension:insertRelatedSkills("f_wuzhui","#f_wuzhuiMaxCards")

f_pofuchenzhou = sgs.CreateTriggerSkill{
    name = "f_pofuchenzhou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:isKongcheng() then
		    room:drawCards(player, 2, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
		elseif player:getPhase() == sgs.Player_Finish and player:isKongcheng() then
			local victim = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "f_pofuchenzhou-invoke", true, true)
			local damage = sgs.DamageStruct()
		    damage.from = player
		    damage.to = victim
		    damage.nature = sgs.DamageStruct_Normal
		    room:damage(damage)
			room:broadcastSkillInvoke(self:objectName())
		end
	end,
}
f_shenxiangyu:addSkill(f_pofuchenzhou)

--10 神孙悟空
f_shensunwukong = sgs.General(extension, "f_shensunwukong", "god", 4, true)

f_bianhua = sgs.CreateTriggerSkill{
	name = "f_bianhua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num - 1000
			if draw.num < 0 then
			    draw.num = 0
			end
			data:setValue(draw)
		elseif event == sgs.EventPhaseStart then
		    --为了防止鬼畜六重奏，将准备阶段与其他阶段分开写，仅在准备阶段开始时播放语音（要是和庞德公组双将那就是于摸牌阶段开始时播放）。
			if player:getPhase() == sgs.Player_Start then
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 1, self:objectName())
			elseif player:getPhase() == sgs.Player_Draw and player:hasSkill("yinshiy") then
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 1, self:objectName())
			elseif player:getPhase() == sgs.Player_Judge or player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Play
			or player:getPhase() == sgs.Player_Discard or player:getPhase() == sgs.Player_Finish then
			    room:sendCompulsoryTriggerLog(player, self:objectName())
				room:drawCards(player, 1, self:objectName())
			end
		end
	end,
}
f_shensunwukong:addSkill(f_bianhua)

f_doufaCard = sgs.CreateSkillCard{
    name = "f_doufaCard",
    target_fixed = false,
	filter = function(self, targets, to_select)
	    if #targets == 1 then return false
		else return true
		end
	end,
	on_use = function(self, room, source, targets)
	    local dest = targets[1]
		local df = math.random(0,3)
		local choices = {}
		table.insert(choices, "f_doufaFire")
		table.insert(choices, "f_doufaThunder")
		table.insert(choices, "f_doufaIce")
		table.insert(choices, "f_doufaPoison")
		table.insert(choices, "f_doufaNormal")
		if df == 0 then
		    table.insert(choices, "f_doufalosehp")
		end
		local choice = room:askForChoice(source, "f_doufa", table.concat(choices, "+"))
		if choice == "f_doufaFire" then
		    room:damage(sgs.DamageStruct("f_doufa", source, dest, 2, sgs.DamageStruct_Fire))
		elseif choice == "f_doufaThunder" then
		    room:damage(sgs.DamageStruct("f_doufa", source, dest, 2, sgs.DamageStruct_Thunder))
		elseif choice == "f_doufaIce" then
		    room:damage(sgs.DamageStruct("f_doufa", source, dest, 2, sgs.DamageStruct_Ice))
		elseif choice == "f_doufaPoison" then
		    room:damage(sgs.DamageStruct("f_doufa", source, dest, 2, sgs.DamageStruct_Poison))
		elseif choice == "f_doufaNormal" then
		    room:damage(sgs.DamageStruct("f_doufa", source, dest, 2, sgs.DamageStruct_Normal))
		elseif choice == "f_doufalosehp" then
		    room:loseHp(dest, 2, true, source, self:objectName())
		end
	end,
}
f_doufa = sgs.CreateViewAsSkill{
    name = "f_doufa",
	n = 999,
	view_filter = function(self, selected, to_select)
		local n = math.max(1, sgs.Self:getHp())
		if #selected >= n then return false end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	    local n = math.max(1, sgs.Self:getHp())
		if #cards ~= n then return end
	    local f_doufa_card = f_doufaCard:clone()
		if f_doufa_card then
			f_doufa_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				f_doufa_card:addSubcard(c)
			end
		end
		return f_doufa_card
	end,
	enabled_at_play = function(self, target)
	    return not target:hasUsed("#f_doufaCard")
	end,
}
f_shensunwukong:addSkill(f_doufa)
--

--11 神·君王霸王龙
f_Trex = sgs.General(extension, "f_Trex$", "god", 6, true)

f_diyuxiCard = sgs.CreateSkillCard{
    name = "f_diyuxiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local choices = {}
		if not source:hasFlag("L1D1SD1_used") then
			table.insert(choices, "L1D1SD1")
		end
		if not source:hasFlag("LM1D2D1_used") then
			table.insert(choices, "LM1D2D1")
		end
		table.insert(choices, "cancel")
		local choice = room:askForChoice(source, "f_diyuxi", table.concat(choices, "+"))
		if choice == "L1D1SD1" then
			room:broadcastSkillInvoke("f_diyuxi")
			room:loseHp(source, 1, true, source, "f_diyuxi")
			room:drawCards(source, 1, "f_diyuxi")
			room:setPlayerFlag(source, "L1D1SD1_BUFF")
			room:setPlayerFlag(source, "L1D1SD1_used")
			room:addPlayerMark(source, "&f_diyuxi-Clear")
		elseif choice == "LM1D2D1" then
			room:broadcastSkillInvoke("f_diyuxi")
			room:loseMaxHp(source, 1)
			room:drawCards(source, 2, "f_diyuxi")
			room:setPlayerFlag(source, "LM1D2D1_BUFF")
			room:setPlayerFlag(source, "LM1D2D1_used")
			room:addPlayerMark(source, "&f_diyuxi-Clear")
		end
	end,
}
f_diyuxi = sgs.CreateZeroCardViewAsSkill{
    name = "f_diyuxi",
	view_as = function()
		return f_diyuxiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("L1D1SD1_used") or not player:hasFlag("LM1D2D1_used")
	end,
}
f_diyuxiBUFF = sgs.CreateTriggerSkill{
	name = "#f_diyuxiBUFF",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.ConfirmDamage and (player:hasFlag("L1D1SD1_BUFF") or player:hasFlag("LM1D2D1_BUFF")) then
		    local damage = data:toDamage()
		    local card = damage.card
			local hurt = damage.damage
			if player:hasFlag("L1D1SD1_BUFF") and card and card:isKindOf("Slash") then
			    local log = sgs.LogMessage()
				log.type = "$f_diyuxibuff1"
				log.from = player
				log.to:append(damage.to)
				room:sendLog(log)
			    damage.damage = hurt + 1
			end
		    if player:hasFlag("LM1D2D1_BUFF") then
			    local log = sgs.LogMessage()
				log.type = "$f_diyuxibuff2"
				log.from = player
				log.to:append(damage.to)
				room:sendLog(log)
				local hurtt = damage.damage
			    damage.damage = hurtt + 1
			end
			data:setValue(damage)
			room:broadcastSkillInvoke("f_diyuxi")
		elseif event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Finish and ((not player:hasFlag("L1D1SD1_used") and not player:hasFlag("LM1D2D1_used")) or (player:hasFlag("L1D1SD1_used") and player:hasFlag("LM1D2D1_used"))) then
			    room:loseHp(player, 1, true, player, "f_diyuxi")
			end
		end
    end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_diyuxi")
	end,
}
f_Trex:addSkill(f_diyuxi)
f_Trex:addSkill(f_diyuxiBUFF)
extension:insertRelatedSkills("f_diyuxi","#f_diyuxiBUFF")

f_moshi = sgs.CreateTriggerSkill{
    name = "f_moshi$",
	frequency = sgs.Skill_Wake,
	waked_skills = "f_kuanglong",
	events = {sgs.EventPhaseEnd},
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if not player:hasLordSkill(self:objectName()) then return false end
 		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&f_moshiFQC") < 6 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doLightbox("$f_moshi")
		if player:hasSkill("f_diyuxi") then
		    room:detachSkillFromPlayer(player, "f_diyuxi")
		end
		room:drawCards(player, 2, self:objectName())
		if not player:hasSkill("f_kuanglong") then
		    room:acquireSkill(player, "f_kuanglong")
		end
		room:addPlayerMark(player, self:objectName())
		room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
		local n = player:getMark("&f_moshiFQC")
		room:removePlayerMark(player, "&f_moshiFQC", n)
	end,
}
f_moshiX = sgs.CreateTriggerSkill{
	name = "#f_moshiX",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.HpLost},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "&f_moshiFQC")
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_moshi") and player:getMark("f_moshi") == 0
		and player:isLord() and not player:hasSkill("bahu")
	end,
}
f_Trex:addSkill(f_moshi)
f_Trex:addSkill(f_moshiX)
extension:insertRelatedSkills("f_moshi","#f_moshiX")
--“狂龙”
f_kuanglong = sgs.CreateTriggerSkill{
    name = "f_kuanglong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local room = player:getRoom()
		local hp = player:getLostHp()
		local extra = (hp / 2)
		room:sendCompulsoryTriggerLog(player, self:objectName())
		draw.num = draw.num + extra
		data:setValue(draw)
	end,
}
f_kuanglongS = sgs.CreateTargetModSkill{
	name = "#f_kuanglongS",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player, card)
		if player:hasSkill("f_kuanglong") and card:isKindOf("Slash") then
		    local hp = player:getLostHp()
			local extra = (hp / 2)
		    return extra
		else
			return 0
		end
	end,
}
f_kuanglongC = sgs.CreateMaxCardsSkill{
    name = "#f_kuanglongC",
    extra_func = function(self, target)
	    if target:hasSkill("f_kuanglong") then
		    local hp = target:getLostHp()
			local extra = (hp / 2)
		    return extra
		else
			return 0
		end
	end,
}
f_kuanglongAudio = sgs.CreateTriggerSkill{
    name = "#f_kuanglongAudio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Discard then
			room:broadcastSkillInvoke("f_kuanglong")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("f_kuanglong")
	end,
}
if not sgs.Sanguosha:getSkill("f_kuanglong") then skills:append(f_kuanglong) end
if not sgs.Sanguosha:getSkill("f_kuanglongS") then skills:append(f_kuanglongS) end
if not sgs.Sanguosha:getSkill("f_kuanglongC") then skills:append(f_kuanglongC) end
if not sgs.Sanguosha:getSkill("f_kuanglongAudio") then skills:append(f_kuanglongAudio) end
extension:insertRelatedSkills("f_kuanglong","#f_kuanglongS")
extension:insertRelatedSkills("f_kuanglong","#f_kuanglongC")
extension:insertRelatedSkills("f_kuanglong","#f_kuanglongAudio")

--

--12 神·鲲鹏
f_kunpeng = sgs.General(extension, "f_kunpeng", "god", 24, true, false, false, 6)

f_juxingCard = sgs.CreateSkillCard{
    name = "f_juxingCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:getMark("&KunPeng") == 0 and not to_select:hasSkill("f_juxing")
	end,
	on_use = function(self, room, source, targets)
	    local DaSheng = targets[1]
		DaSheng:gainMark("&KunPeng")
		room:broadcastSkillInvoke("f_juxing", 1)
	end,
}
f_juxingVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_juxing",
    view_as = function()
		return f_juxingCard:clone()
	end,
	response_pattern = "@@f_juxing",
}
f_juxing = sgs.CreateTriggerSkill{
    name = "f_juxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = f_juxingVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
		    room:askForUseCard(player, "@@f_juxing", "@f_juxing-card")
		end
	end,
}
f_juxingMarkSkill = sgs.CreateTriggerSkill{
    name = "#f_juxingMarkSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		local plist = room:getAllPlayers()
		for _, f_kunpeng in sgs.qlist(plist) do
            if f_kunpeng:hasSkill("f_juxing") then
		        room:loseMaxHp(f_kunpeng, damage.damage)
				room:addPlayerMark(f_kunpeng, "&f_juxing_trigger")
				room:sendCompulsoryTriggerLog(f_kunpeng, "f_juxing")
				room:broadcastSkillInvoke("f_juxing", 2)
			end
		end
		if damage.to:hasSkill("f_juxing") or damage.to:getMark("&KunPeng") > 0 then
		    room:sendCompulsoryTriggerLog(player, "f_juxing")
		    damage.prevented = true
			data:setValue(damage)
			return true 
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil and (player:hasSkill("f_juxing") or player:getMark("&KunPeng") > 0)
	end,
}
f_juxingClearMark = sgs.CreateTriggerSkill{ --鲲鹏阵亡后，如果场上无人有技能“鲲鹏”，清除场上的“鲲鹏”标记
    name = "#f_juxingClearMark",
	frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
		    local plist = room:getOtherPlayers(player)
			local can_invoke = true
			for _, p in sgs.qlist(plist) do
			    if p:hasSkill("f_juxing") then
				    can_invoke = false
				end
			end
			
			if can_invoke then
		        for _, p in sgs.qlist(plist) do
			        if p:getMark("&KunPeng") > 0 then
				        local n = p:getMark("&KunPeng")
						room:removePlayerMark(p, "&KunPeng", n)
					end
				end
			end
		end
    end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_juxing")
	end,
}
f_kunpeng:addSkill(f_juxing)
f_kunpeng:addSkill(f_juxingMarkSkill)
f_kunpeng:addSkill(f_juxingClearMark)
extension:insertRelatedSkills("f_juxing","#f_juxingMarkSkill")
extension:insertRelatedSkills("f_juxing","#f_juxingClearMark")

f_jiutianCard = sgs.CreateSkillCard{
    name = "f_jiutianCard",
    target_fixed = true,
    on_use = function(self, room, source, targets)
	    room:loseMaxHp(source)
		room:removePlayerMark(source, "&f_juxing_trigger")
		room:broadcastSkillInvoke("f_jiutian", 1)
	end,
}
f_jiutian = sgs.CreateZeroCardViewAsSkill{
    name = "f_jiutian",
	view_as = function()
		return f_jiutianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&f_juxing_trigger") >= 1
	end,
}
f_jiutianContinue = sgs.CreateTriggerSkill{
    name = "#f_jiutianContinue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    if table.contains(use.card:getSkillNames(), "f_jiutian") and player:hasSkill("f_jiutian") then			
			    local ids = room:getNCards(1, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local id = ids:first()
				local card = sgs.Sanguosha:getCard(id)
				if card:isRed() then
				    local plistR = room:getAllPlayers()
					local beneficiaryR = room:askForPlayerChosen(player, plistR, self:objectName())
					beneficiaryR:obtainCard(card)
					room:broadcastSkillInvoke("f_jiutian", 2)
				elseif card:isBlack() then
				    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(card, reason, nil)
					local plistB = room:getAllPlayers()
					local beneficiaryB = room:askForPlayerChosen(player, plistB, self:objectName())
					local choice = room:askForChoice(player, self:objectName(), "RecoverHim+HeDrawCard")
					if choice == "RecoverHim" then
					    local rec = sgs.RecoverStruct()
		                rec.who = beneficiaryB
		                room:recover(beneficiaryB, rec)
					elseif choice == "HeDrawCard" then
					    room:drawCards(beneficiaryB, 1, "f_jiutian")
					end
					room:broadcastSkillInvoke("f_jiutian", 3)
				end
			end
		elseif event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Finish and player:getMark("&f_juxing_trigger") > 0 then
		        local m = player:getMark("&f_juxing_trigger")
			    room:loseMaxHp(player, m)
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
                return false
            end
            for _, f_kunpeng in sgs.qlist(room:getAllPlayers()) do
			    if f_kunpeng:getMark("&f_juxing_trigger") > 0 then
				    local n = f_kunpeng:getMark("&f_juxing_trigger")
					room:removePlayerMark(f_kunpeng, "&f_juxing_trigger", n)
				end
			end
		end
	end,
}
f_kunpeng:addSkill(f_jiutian)
f_kunpeng:addSkill(f_jiutianContinue)
extension:insertRelatedSkills("f_jiutian","#f_jiutianContinue")

--

--13 FC神吕蒙
fc_shenlvmeng = sgs.General(extension, "fc_shenlvmeng", "god", 3, true)

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end
fcshelie = sgs.CreateTriggerSkill{
	name = "fcshelie",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		local card_ids = room:getNCards(5)
		room:broadcastSkillInvoke(self:objectName())
		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		while not card_ids:isEmpty() do
			local card_id = room:askForAG(player, card_ids, false, "shelie")
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			local suit = card:getSuit()
			room:takeAG(player, card_id, false)
			local _card_ids = card_ids
			for i = 0, 150 do
				for _, id in sgs.qlist(_card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuit() == suit then
						card_ids:removeOne(id)
						room:takeAG(nil, id, false)
						to_throw:append(id)
					end
				end
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not to_get:isEmpty() then
			dummy:addSubcards(getCardList(to_get))
			player:obtainCard(dummy)
		end
		dummy:clearSubcards()
		if not to_throw:isEmpty() then
			dummy:addSubcards(getCardList(to_throw))
			if room:askForSkillInvoke(player, "@fcshelieGC", data) then
			    local sq = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			    room:obtainCard(sq, dummy, true)
				room:broadcastSkillInvoke(self:objectName())
			else
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
				room:throwCard(dummy, reason, nil)
			end
		end
		dummy:deleteLater()
		room:clearAG()
		return true
	end,
}
fc_shenlvmeng:addSkill(fcshelie)

fcgongxinCard = sgs.CreateSkillCard{
	name = "fcgongxinCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				ids:append(card:getEffectiveId())
			end
			local card_id = room:doGongxin(effect.from, effect.to, ids)
			if (card_id == -1) then return end
			local result = room:askForChoice(effect.from, "fcgongxin", "discard+put")
			effect.from:removeTag("fcgongxin")
			if result == "discard" then
				if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Heart then
				    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
					room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				else
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, effect.from:objectName(), nil, "fcgongxin", nil)
					room:throwCard(sgs.Sanguosha:getCard(card_id), reason, effect.to, effect.from)
				end
			else
				effect.from:setFlags("Global_GongxinOperatorr")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), nil, "fcgongxin", nil)
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), effect.to, nil, sgs.Player_DrawPile, reason, true)
				effect.from:setFlags("-Global_GongxinOperatorr")
			end
		end
	end,
}
fcgongxin = sgs.CreateZeroCardViewAsSkill{
	name = "fcgongxin",
	view_as = function()
		return fcgongxinCard:clone()
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#fcgongxinCard")
	end,
}
fc_shenlvmeng:addSkill(fcgongxin)

--14 FC神赵云
fc_shenzhaoyun = sgs.General(extension, "fc_shenzhaoyun", "god", 2, true)

fcweijing = sgs.CreateTriggerSkill{
	name = "fcweijing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying, sgs.QuitDying},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EnterDying then
		    local x = player:getLostHp()
	        room:broadcastSkillInvoke(self:objectName(), 3)
		    room:sendCompulsoryTriggerLog(player, self:objectName())
		    player:drawCards(x, self:objectName())
		elseif event == sgs.QuitDying then
		    local y = player:getHp()
	        room:broadcastSkillInvoke(self:objectName(), 3)
		    room:sendCompulsoryTriggerLog(player, self:objectName())
		    player:drawCards(y, self:objectName())
		end
	end,
}
fcweijing_MaxCards = sgs.CreateMaxCardsSkill{
	name = "#fcweijing_MaxCards",
	extra_func = function(self, target)
		if target:hasSkill("fcweijing") then
			return target:getLostHp() + target:getHp()
		else
			return 0
		end
	end,
}
fcweijing_MaxCards_Audio = sgs.CreateTriggerSkill{
    name = "#fcweijing_MaxCards_Audio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill("fcweijing") and player:getPhase() == sgs.Player_Discard then
			room:broadcastSkillInvoke("fcweijing", 2)
		end
	end,
}
fcweijing_Draw = sgs.CreateDrawCardsSkill{
	name = "#fcweijing_Draw",
	frequency = sgs.Skill_Compulsory,
	draw_num_func = function(self, player, n)
	    if player:hasSkill("fcweijing") then
			player:getRoom():broadcastSkillInvoke("fcweijing", 1)
		    if player:isWounded() then
			    player:getRoom():sendCompulsoryTriggerLog(player, "fcweijing")
		    end
		    return n + player:getLostHp()
		end
		return n
	end,
}
fc_shenzhaoyun:addSkill(fcweijing)
fc_shenzhaoyun:addSkill(fcweijing_MaxCards)
fc_shenzhaoyun:addSkill(fcweijing_MaxCards_Audio)
fc_shenzhaoyun:addSkill(fcweijing_Draw)
extension:insertRelatedSkills("fcweijing","#fcweijing_MaxCards")
extension:insertRelatedSkills("fcweijing","#fcweijing_MaxCards_Audio")
extension:insertRelatedSkills("fcweijing","#fcweijing_Draw")

fclongmingVS = sgs.CreateViewAsSkill{
	name = "fclongming",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected > 1 or to_select:hasFlag("using") then return false end
		if #selected > 0 then
			return to_select:getSuit() == selected[1]:getSuit()
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() or to_select:getSuit() == sgs.Card_Heart or to_select:getSuit() == sgs.Card_Spade then
				return true
			elseif sgs.Slash_IsAvailable(sgs.Self) and to_select:getSuit() == sgs.Card_Club then
				if sgs.Self:getWeapon() and to_select:getEffectiveId() == sgs.Self:getWeapon():getId()
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart or (to_select:getSuit() == sgs.Card_Spade and sgs.Self:hasFlag("Global_Dying"))
			elseif pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Diamond
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Club
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 and #cards ~= 2 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			if #cards == 1 then
				new_card:setSkillName(self:objectName())
			else
				new_card:setSkillName("fclongmingBuff")
			end
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
	    local newana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
		or player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newana)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" or pattern == "jink"
		or (string.find(pattern, "peach") and not player:hasFlag("Global_PreventPeach")) or string.find(pattern, "analeptic")
	end,
}
fclongming = sgs.CreateTriggerSkill{
	name = "fclongming",
	view_as_skill = fclongmingVS,
	events = {sgs.ConfirmDamage, sgs.PreHpRecover, sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isBlack() and table.contains(damage.card:getSkillNames(), "fclongmingBuff") then
				local log = sgs.LogMessage()
				log.type = "$fclongmingDMG"
				log.from = player
				room:sendLog(log)
				if player:hasFlag("fclongmingANA_Buff") then
				    damage.damage = damage.damage + 2
				else
				    damage.damage = damage.damage + 1
				end
				data:setValue(damage)
				player:setFlags("-fclongmingANA_Buff")
			elseif damage.card and damage.card:isKindOf("Slash") then
			    if player:hasFlag("fclongmingANA_Buff") then
				    damage.damage = damage.damage + 1
					data:setValue(damage)
				end
				player:setFlags("-fclongmingANA_Buff")
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:isRed() and rec.card:isKindOf("Peach") and table.contains(rec.card:getSkillNames(), "fclongmingBuff") then
				local log = sgs.LogMessage()
				log.type = "$fclongmingPREC"
				log.from = player
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			elseif rec.card and rec.card:isBlack() and rec.card:isKindOf("Analeptic") and table.contains(rec.card:getSkillNames(), "fclongmingBuff") then
				local log = sgs.LogMessage()
				log.type = "$fclongmingAREC"
				log.from = player
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:isRed() and card:isKindOf("Jink") and table.contains(card:getSkillNames(), "fclongmingBuff") then
				local current = room:getCurrent()
				if current:isNude() then return false end
				room:doAnimate(1, player:objectName(), current:objectName())
				local card_id = room:askForCardChosen(player, current, "he", "fclongmingBuff")
			    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
			    room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				local log = sgs.LogMessage()
				log.type = "$fclongmingJNK"
				log.from = player
				room:sendLog(log)
			end
			if card and card:isKindOf("Analeptic") and table.contains(card:getSkillNames(), "fclongmingBuff") then
			    local log = sgs.LogMessage()
				log.type = "$fclongmingANA"
				log.from = player
				room:sendLog(log)
				room:setPlayerFlag(player, "fclongmingANA_Buff")
			end
		end
	end,
}
fc_shenzhaoyun:addSkill(fclongming)


--“龙鸣”配音区--

fclongming_Audio = sgs.CreateTriggerSkill{
    name = "#fclongming_Audio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Peach") and (table.contains(card:getSkillNames(), "fclongming") or table.contains(card:getSkillNames(), "fclongmingBuff")) then
		    room:broadcastSkillInvoke("fclongming", 1)
		elseif card and card:isKindOf("Jink") and (table.contains(card:getSkillNames(), "fclongming") or table.contains(card:getSkillNames(), "fclongmingBuff")) then
		    room:broadcastSkillInvoke("fclongming", 2)
		elseif card and card:isKindOf("ThunderSlash") and (table.contains(card:getSkillNames(), "fclongming") or table.contains(card:getSkillNames(), "fclongmingBuff")) then
		    room:broadcastSkillInvoke("fclongming", 3)
		elseif card and card:isKindOf("Analeptic") and (table.contains(card:getSkillNames(), "fclongming") or table.contains(card:getSkillNames(), "fclongmingBuff")) then
		    room:broadcastSkillInvoke("fclongming", 4)
		end
		if card and card:isRed() and table.contains(card:getSkillNames(), "fclongmingBuff") then
		    room:broadcastSkillInvoke("fclongming", 5)
		elseif card and card:isBlack() and table.contains(card:getSkillNames(), "fclongmingBuff") then
		    room:broadcastSkillInvoke("fclongming", 6)
		end
		--彩蛋：
		if card and card:isKindOf("FireSlash") then
		    room:broadcastSkillInvoke("fclongming", 7)
		end
	end,
}
----
fc_shenzhaoyun:addSkill(fclongming_Audio)
extension:insertRelatedSkills("fclongming","#fclongming_Audio")

--15 FC神刘备
fc_shenliubei = sgs.General(extension, "fc_shenliubei", "god", 6, true)

fc_shenliubei:addSkill("longnu")

fcjieying_GMS = sgs.CreateTriggerSkill{
	name = "#fcjieying_GMS",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.ChainStateChange},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			if player:hasSkill("fcjieying") and not player:isChained() then
				room:setPlayerChained(player)
			end
		end
		if event == sgs.ChainStateChange and player:isChained() then
			return true
		end
	end,
}
fcjieying_MoreSlashUsed = sgs.CreateTargetModSkill{
	name = "#fcjieying_MoreSlashUsed",
	residue_func = function(self, player, card)
	    local n = 0
		if card:isKindOf("Slash") then
		    if player:hasSkill("fcjieying") and player:isChained() then
			    n = n + 1
		    end
		    for _, p in sgs.qlist(player:getAliveSiblings()) do
			    if p:hasSkill("fcjieying") and player:isChained() then
			        n = n + 1
			    end
			end
		end
		return n
	end,
}
fcjieying_MaxCards = sgs.CreateMaxCardsSkill{
	name = "#fcjieying_MaxCards",
	extra_func = function(self, target)
		local n = 0
		if target:hasSkill("fcjieying") and target:isChained() then
			n = n - 2 + 3
			--n = n + 1
		end
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:hasSkill("fcjieying") and target:isChained() then
				n = n - 2
			end
		end
		return n
	end,
}
fcjieying = sgs.CreateTriggerSkill{
	name = "fcjieying",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName(), data) then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isChained() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "fcjieying-invoke", false, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:setPlayerChained(target)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
	end,
}
fc_shenliubei:addSkill(fcjieying)
fc_shenliubei:addSkill(fcjieying_GMS)
fc_shenliubei:addSkill(fcjieying_MaxCards)
fc_shenliubei:addSkill(fcjieying_MoreSlashUsed)
extension:insertRelatedSkills("fcjieying","#fcjieying_GMS")
extension:insertRelatedSkills("fcjieying","#fcjieying_MaxCards")
extension:insertRelatedSkills("fcjieying","#fcjieying_MoreSlashUsed")



--16 FC神张辽
fc_shenzhangliao = sgs.General(extension, "fc_shenzhangliao", "god", 4, true)

fcduorui = sgs.CreateTriggerSkill{
    name = "fcduorui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
		    local damage = data:toDamage()
			local victim = damage.to
			if victim:objectName() == player:objectName() then return end
			if victim:isAlive() and not victim:isNude() and room:askForSkillInvoke(player, self:objectName(), data) then
			    local choices = {}
		        table.insert(choices, "obtain1card")
			    table.insert(choices, "CleanUpHandArea")
		        table.insert(choices, "CleanUpEquipArea")
				table.insert(choices, "cancel")
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
			    if choice == "obtain1card" then
			        local id = room:askForCardChosen(player, victim, "he", self:objectName())
				    room:obtainCard(player, id, false)
				    room:broadcastSkillInvoke(self:objectName())
			    elseif choice == "CleanUpHandArea" then
			        victim:throwAllHandCards()
                    room:broadcastSkillInvoke(self:objectName())
				    player:turnOver()
				    room:setPlayerFlag(player, "fcduorui_c2_used")
			    elseif choice == "CleanUpEquipArea" then
			        victim:throwAllEquips()
				    room:broadcastSkillInvoke(self:objectName())
				    room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("fcduorui") and not player:hasFlag("fcduorui_c2_used")
	end,
}
fc_shenzhangliao:addSkill(fcduorui)

fczhiti = sgs.CreateTriggerSkill{
	name = "fczhiti",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()
	end,
}
fczhitiX = sgs.CreateMaxCardsSkill{
	name = "#fczhitiX",
	extra_func = function(self, target)
		local n = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:hasSkill("fczhiti") and p:inMyAttackRange(target) and target:isWounded() and target:objectName() ~= p:objectName() then
				n = n - 1
			end
		end
		return n
	end,
}
fczhitiFlag = sgs.CreateTriggerSkill{
    name = "#fczhitiFlag",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local plist = room:getAlivePlayers()
			local wdd = 0
			for _, p in sgs.qlist(plist) do
				if p:isWounded() then
					wdd = wdd + 1
				end
			end
			if wdd >= 1 then
				room:setPlayerFlag(player, "fczhiti_1wdd")
			end
			if wdd >= 3 then
				room:setPlayerFlag(player, "fczhiti_3wdd")
			end
			if wdd >= 5 then
				room:setPlayerFlag(player, "fczhiti_5wdd")
			end
		end
	end,
}
fc_shenzhangliao:addSkill(fczhiti)
fc_shenzhangliao:addSkill(fczhitiX)
fc_shenzhangliao:addSkill(fczhitiFlag)
extension:insertRelatedSkills("fczhiti","#fczhitiX")
extension:insertRelatedSkills("fczhiti","#fczhitiFlag")

--“止啼”具体加成一览：
fczhiti_MaxCard = sgs.CreateMaxCardsSkill{
    name = "#fczhiti_MaxCard",
    extra_func = function(self, target)
	    if target:hasSkill("fczhiti") and target:hasFlag("fczhiti_1wdd") then
		    return 1
	    else
		    return 0
	    end
	end,
}
fczhiti_MoreDistance = sgs.CreateTargetModSkill{
    name = "#fczhiti_MoreDistance",
	pattern = "Card",
	distance_limit_func = function(self, from)
	    if from:hasSkill("fczhiti") and from:hasFlag("fczhiti_1wdd") then
			return 1
		else
			return 0
		end
	end,
}
fczhiti_DrawMoreCard = sgs.CreateTriggerSkill{
	name = "#fczhiti_DrawMoreCard",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if player:hasSkill("fczhiti") and player:hasFlag("fczhiti_3wdd") then
			room:sendCompulsoryTriggerLog(player, "fczhiti")
			draw.num = draw.num + 1
			data:setValue(draw)
		end
	end,
}
fczhiti_MoreSlashUsed = sgs.CreateTargetModSkill{
	name = "#fczhiti_MoreSlashUsed",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player, card)
		if player:hasSkill("fczhiti") and player:hasFlag("fczhiti_3wdd") and card:isKindOf("Slash") then
			return 1
		else
			return 0
		end
	end,
}
fczhiti_throwEquipArea_Damage = sgs.CreateTriggerSkill{
    name = "#fczhiti_throwEquipArea_Damage",
	frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:hasSkill("fczhiti") and player:hasFlag("fczhiti_5wdd") and room:askForSkillInvoke(player, "fczhiti", data) then
		    local plist = room:getOtherPlayers(player)
			local sunwu = room:askForPlayerChosen(player, plist, "fczhiti")
		    if sunwu:hasEquipArea() then
			    sunwu:throwEquipArea()
				room:addPlayerMark(sunwu, "EquipArea_lose")
			end
			local damage = sgs.DamageStruct()
		    damage.from = player
		    damage.to = sunwu
		    damage.nature = sgs.DamageStruct_Normal
		    room:damage(damage)
		    room:broadcastSkillInvoke(self:objectName())
		end
	end,
}
fczhiti_obtainEquipArea = sgs.CreateTriggerSkill{ --恢复装备区
    name = "#fczhiti_obtainEquipArea",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
            return false
        end
        for _, sunwu in sgs.qlist(room:getAllPlayers()) do
			if sunwu:getMark("EquipArea_lose") > 0 then
			    if not sunwu:hasEquipArea() then
				    sunwu:obtainEquipArea()
				end
			    local n = sunwu:getMark("EquipArea_lose")
			    room:removePlayerMark(sunwu, "EquipArea_lose", n)
			end
		end
	end,
	can_trigger = function(self, targets)
	    return targets:getMark("EquipArea_lose") > 0
	end,
}
fczhiti_Audio = sgs.CreateTriggerSkill{
    name = "#fczhiti_Audio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    local damage = data:toDamage()
		if player:hasSkill("fczhiti") and (player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Discard) then
		    room:broadcastSkillInvoke("fczhiti")
		end
	end,
}
fc_shenzhangliao:addSkill(fczhiti_MaxCard)
fc_shenzhangliao:addSkill(fczhiti_MoreDistance)
fc_shenzhangliao:addSkill(fczhiti_DrawMoreCard)
fc_shenzhangliao:addSkill(fczhiti_MoreSlashUsed)
fc_shenzhangliao:addSkill(fczhiti_throwEquipArea_Damage)
fc_shenzhangliao:addSkill(fczhiti_obtainEquipArea)
fc_shenzhangliao:addSkill(fczhiti_Audio)
extension:insertRelatedSkills("fczhiti","#fczhiti_MaxCard")
extension:insertRelatedSkills("fczhiti","#fczhiti_MoreDistance")
extension:insertRelatedSkills("fczhiti","#fczhiti_DrawMoreCard")
extension:insertRelatedSkills("fczhiti","#fczhiti_MoreSlashUsed")
extension:insertRelatedSkills("fczhiti","#fczhiti_throwEquipArea_Damage")
extension:insertRelatedSkills("fczhiti","#fczhiti_obtainEquipArea")
extension:insertRelatedSkills("fczhiti","#fczhiti_Audio")


--斗地主模式纪念--
--17 地主
f_landlord = sgs.General(extension, "f_landlord", "qun", 4, true)

f_feiyangCard = sgs.CreateSkillCard{
	name = "f_feiyang",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local judge = room:askForCardChosen(source, source, "j", self:objectName(), false, sgs.Card_MethodDiscard)
		room:throwCard(judge, source, source)
	end,
}
f_feiyangVS = sgs.CreateViewAsSkill{
	name = "f_feiyang",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected <= 2 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local c = f_feiyangCard:clone()
		for _, card in ipairs(cards) do
			c:addSubcard(card)
		end
		return c
	end,
	response_pattern = "@@f_feiyang",
}
f_feiyang = sgs.CreatePhaseChangeSkill{
	name = "f_feiyang",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = f_feiyangVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Judge and player:getJudgingArea():length() > 0 and player:getHandcardNum() >= 2 then
			room:askForUseCard(player, "@@f_feiyang", "@f_feiyang")
		end
	end,
}
f_landlord:addSkill(f_feiyang)

f_bahu = sgs.CreatePhaseChangeSkill{
	name = "f_bahu",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			player:drawCards(1, self:objectName())
		end
	end,
}
f_bahuSlashMore = sgs.CreateTargetModSkill{
	name = "#f_bahuSlashMore",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("f_bahu") then
			return 1
		end
		return 0
	end,
}
f_landlord:addSkill(f_bahu)
f_landlord:addSkill(f_bahuSlashMore)
extension:insertRelatedSkills("f_bahu","#f_bahuSlashMore")


f_yinfu = sgs.CreateTriggerSkill{
    name = "f_yinfu",
	--global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.TurnStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if event == sgs.TurnStart then
			local n = 15
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				n = math.min(p:getSeat(), n)
			end
			if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
				room:setPlayerMark(player, "f_yinfuTurn", player:getMark("Global_TurnCount") + 1)
				--[[for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, mark in sgs.list(p:getMarkNames()) do
						if string.find(mark, "_lun") and p:getMark(mark) > 0 then --乱抄代码，终造此祸
							room:setPlayerMark(p, mark, 0)
						end
					end
				end]]
			end
		elseif event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_RoundStart then
				local hp = player:getLostHp()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("f_yinfuTurn") > 0 then
						local n = p:getMark("f_yinfuTurn")
						if hp >= n then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:recover(player, sgs.RecoverStruct(player, nil, 1))
							room:addPlayerMark(player, "f_yinfuTriggered")
						end
					end
				end
				if player:getMark("f_yinfuTriggered") >= 3 then
					local m = player:getMark("f_yinfuTriggered")
					room:removePlayerMark(player, "f_yinfuTriggered", m)
					room:detachSkillFromPlayer(player, self:objectName())
				end
			end
		end
	end,
}
f_landlord:addSkill(f_yinfu)





--

--18 农民
f_farmer = sgs.General(extension, "f_farmer", "qun", 3, true)

f_gengzhongCard = sgs.CreateSkillCard{
    name = "f_gengzhongCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:addToPile("NT", self)
		---
		local Set = function(list)
			local set = {}
			for _, l in ipairs(list) do set[l] = true end
			return set
		end
		---
		local basic = {"slash", "normal_slash", "fire_slash", "thunder_slash", "ice_slash", "peach", "analeptic", "cancel"}
		for _, patt in ipairs(basic) do
			local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
			if poi and (not poi:isAvailable(source)) or (patt == "peach" and not source:isWounded()) then
				table.removeOne(basic, patt)
				if patt == "slash" then
					table.removeOne(basic, "normal_slash")
					table.removeOne(basic, "fire_slash")
					table.removeOne(basic, "thunder_slash")
					table.removeOne(basic, "ice_slash")
				end
			end
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(basic, "+"))
		if choice ~= "cancel" then
			--必须排除满血能吃桃的情况
			if choice == "peach" and not source:isWounded() then
			return false end
			room:setPlayerProperty(source, "f_gengzhong", sgs.QVariant(choice))
			room:askForUseCard(source, "@@f_gengzhong", "@f_gengzhong", -1, sgs.Card_MethodUse)
			room:setPlayerProperty(source, "f_gengzhong", sgs.QVariant())
		end
	end,
}
f_gengzhong = sgs.CreateViewAsSkill{
	name = "f_gengzhong",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@f_gengzhong" then return false end
		return true
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@f_gengzhong" then
			if #cards == 0 then
				local name = sgs.Self:property("f_gengzhong"):toString()
				local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
				card:setSkillName("_f_gengzhong")
				return card
			end
		else
			if #cards > 0 then
				local NTcard = f_gengzhongCard:clone()
				for _, c in ipairs(cards) do
					NTcard:addSubcard(c)
				end
				NTcard:setSkillName("f_gengzhong")
				return NTcard
			end
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and not player:hasUsed("#f_gengzhongCard")
	end,
	response_pattern = "@@f_gengzhong",
}
f_gengzhongNTGet = sgs.CreateTriggerSkill{
    name = "#f_gengzhongNTGet",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and room:askForSkillInvoke(player, "@f_gengzhongNTGet", data) then
				local NT = sgs.Sanguosha:cloneCard("slash")
				NT:addSubcards(player:getPile("NT"))
				room:obtainCard(player, NT)
				NT:deleteLater()
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if room:askForSkillInvoke(player, "@f_gengzhongNTGet", data) then
				local NT = sgs.Sanguosha:cloneCard("slash")
				NT:addSubcards(player:getPile("NT"))
				room:obtainCard(player, NT)
				NT:deleteLater()
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_gengzhong") and player:getPile("NT"):length() > 0
	end,
}
f_farmer:addSkill(f_gengzhong)
f_farmer:addSkill(f_gengzhongNTGet)
extension:insertRelatedSkills("f_gengzhong","#f_gengzhongNTGet")


f_gongkangCard = sgs.CreateSkillCard{
	name = "f_gongkangCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:removePlayerMark(effect.from, "@f_gongkang")
		room:doSuperLightbox("f_farmer", "f_gongkang")
		if not effect.to:hasSkill("f_gengzhong") then room:acquireSkill(effect.to, "f_gengzhong") end
		if not effect.from:hasSkill("f_tongxin") then room:acquireSkill(effect.from, "f_tongxin") end
		if not effect.to:hasSkill("f_tongxin") then room:acquireSkill(effect.to, "f_tongxin") end
	end,
}
f_gongkangVS = sgs.CreateZeroCardViewAsSkill{
	name = "f_gongkang",
	view_as = function()
		return f_gongkangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_gongkang") > 0
	end,
}
f_gongkang = sgs.CreateTriggerSkill{
	name = "f_gongkang",
	frequency = sgs.Skill_Limited,
	waked_skills = "f_tongxin",
	limit_mark = "@f_gongkang",
	view_as_skill = f_gongkangVS,
	on_trigger = function()
	end,
}
f_farmer:addSkill(f_gongkang)
f_farmer:addRelateSkill("f_tongxin")
--“同心”
f_tongxin = sgs.CreateTriggerSkill{
    name = "f_tongxin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    local death = data:toDeath()
		if death.who:objectName() == player:objectName() or not death.who:hasSkill(self:objectName()) then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local choices = {}
			table.insert(choices, "1")
			if player:isWounded() then
				table.insert(choices, "2")
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if choice == "1" then
				room:drawCards(player, 2, self:objectName())
			elseif choice == "2" then
				room:recover(player, sgs.RecoverStruct(player))
			end
			if death.damage.from:objectName() == player:objectName() then
				room:broadcastSkillInvoke("f_tongxinCDAudio")
			end
		end
	end,
}
f_tongxinCDAudio = sgs.CreateTriggerSkill{
	name = "f_tongxinCDAudio",
	on_trigger = function()
	end,
}
if not sgs.Sanguosha:getSkill("f_tongxin") then skills:append(f_tongxin) end
if not sgs.Sanguosha:getSkill("f_tongxinCDAudio") then skills:append(f_tongxinCDAudio) end

--项羽专属装备：乌骓马
local wuzhuii = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Spade, 5)
wuzhuii:setObjectName("wuzhuii")
--wuzhuii:setClassName("Wuzhuii")
wuzhuii:setParent(xiangyuEquip)
----


--

--============（V2.0）神话再临十二神将<<DIY翻创版本来袭!>>============--
extension_G = sgs.Package("fcDIY_twelveGod", sgs.Package_GeneralPack)

--19 武神·关羽
sp_shenguanyu = sgs.General(extension_G, "sp_shenguanyu", "god", 6, true, false, false, 5)

sp_taoyuanyi = sgs.CreateOneCardViewAsSkill{
	name = "sp_taoyuanyi",
	filter_pattern = ".|heart|.|hand",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local gs = sgs.Sanguosha:cloneCard("god_salvation", suit, point)
		gs:setSkillName(self:objectName())
		gs:addSubcard(id)
		return gs
	end,
	enabled_at_play = function(self, player)
	    return not player:hasFlag("sp_taoyuanyi_used")
	end,
}
sp_taoyuanyi_buffANDlimited = sgs.CreateTriggerSkill{
    name = "#sp_taoyuanyi_buffANDlimited",
	frequency = sgs.Skill_Frequent,
	events = {sgs.HpRecover, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			if recover.who and recover.who:hasSkill("sp_taoyuanyi") and recover.card:isKindOf("GodSalvation") then
				room:sendCompulsoryTriggerLog(recover.who, "sp_taoyuanyi")
				room:broadcastSkillInvoke("sp_taoyuanyi")
				local n = math.random(1,3)
				if n == 1 then
					room:drawCards(recover.who, 1, "sp_taoyuanyi")
				elseif n == 2 then
					local rec = sgs.RecoverStruct()
					rec.who = recover.who
					room:recover(recover.who, rec)
				elseif n == 3 then
					local count = recover.who:getMaxHp()
					local mhp = sgs.QVariant()
					mhp:setValue(count + 1)
					room:setPlayerProperty(recover.who, "maxhp", mhp)
				end
			end
		elseif event == sgs.CardUsed then
	    	local use = data:toCardUse()
			if player:getPhase() == sgs.Player_Play and player:hasSkill("sp_taoyuanyi") and table.contains(use.card:getSkillNames(), "sp_taoyuanyi") then
		        room:setPlayerFlag(player, "sp_taoyuanyi_used")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_shenguanyu:addSkill(sp_taoyuanyi)
sp_shenguanyu:addSkill(sp_taoyuanyi_buffANDlimited)
extension:insertRelatedSkills("sp_taoyuanyi","#sp_taoyuanyi_buffANDlimited")


sp_guoguanzhanjiang = sgs.CreateTriggerSkill{
    name = "sp_guoguanzhanjiang",
	frequency = sgs.Skill_Frequent,
	waked_skills = "sp_qianlixing",
	events = {sgs.EventPhaseStart, sgs.DamageCaused, sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local can_invoke = true
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("&alreadyPASSlevel") == 0 then
					can_invoke = true
					break
				end
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("&LeVeL") > 0 then
					can_invoke = false
					break
				end
			end
			if can_invoke then
				local levels = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("&alreadyPASSlevel") == 0 then
						levels:append(p)
					end
				end
				local all_alive_players = {}
				for _, p in sgs.qlist(levels) do
					table.insert(all_alive_players, p)
				end
				local random_target = all_alive_players[math.random(1, #all_alive_players)]
				random_target:gainMark("&LeVeL", 1)
				if not player:hasSkill("sp_qianlixing") then
					room:acquireSkill(player, "sp_qianlixing")
				end
			end
		elseif event == sgs.DamageCaused then --过关
	    	local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and damage.to:getMark("&LeVeL") > 0 then
				local log = sgs.LogMessage()
				log.type = "$ggzz_guoguan"
				log.from = player
				log.to:append(damage.to)
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName(), 1)
				if player:hasSkill("sp_qianlixing") then
					room:detachSkillFromPlayer(player, "sp_qianlixing", false, true)
				end
				damage.to:loseMark("&LeVeL")
				room:addPlayerMark(damage.to, "&alreadyPASSlevel")
				player:gainMark("&PASSlevel", 1)
				room:setPlayerFlag(player, "PASSlevel")
				local c = room:alivePlayerCount() - 1
				if c > 5 then c = 5 end
				if player:getMark("&PASSlevel") >= c then
					room:addPlayerMark(player, "ggzz_punishlose") --惩罚失效
				end
			end
		elseif event == sgs.Death then --斩将
			local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() then
		        local killer
		        if death.damage then
			        killer = death.damage.from
		        else
			        killer = nil
		        end
		        local current = room:getCurrent()
		        if killer:hasSkill(self:objectName()) and death.who:getMark("&alreadyPASSlevel") > 0 then
					local log = sgs.LogMessage()
					log.type = "$ggzz_zhanjiang"
					log.from = killer
					room:sendLog(log)
					room:broadcastSkillInvoke(self:objectName(), 2)
					killer:gainMark("&KILLgeneral", 1)
				end
			end
		end
	end,
}
sp_shenguanyu:addSkill(sp_guoguanzhanjiang)
--“千里行”
sp_qianlixing = sgs.CreateOneCardViewAsSkill{
	name = "sp_qianlixing",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isRed() then return false end
		if not (card:isKindOf("BasicCard") or card:isKindOf("EquipCard")) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
sp_qianlixingMD = sgs.CreateTargetModSkill{
	name = "#sp_qianlixingMD",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sp_qianlixing") and from:getPhase() == sgs.Player_Play and table.contains(card:getSkillNames(), "sp_qianlixing") then
			return 1000
		else
			return 0
		end
	end,
}
sp_qianlixingPF = sgs.CreateTriggerSkill{
    name = "#sp_qianlixingPF",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local use = data:toCardUse()
		if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play and table.contains(use.card:getSkillNames(), "sp_qianlixing") then
			player:setFlags("sp_qianlixingPFfrom")
			for _, p in sgs.qlist(use.to) do
				p:setFlags("sp_qianlixingPFto")
				room:addPlayerMark(p, "Armor_Nullified")
			end
		elseif event == sgs.CardFinished and table.contains(use.card:getSkillNames(), "sp_qianlixing") then
		    if not player:hasFlag("sp_qianlixingPFfrom") then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("sp_qianlixingPFto") then
					p:setFlags("-sp_qianlixingPFto")
					if p:getMark("Armor_Nullified") then
						room:removePlayerMark(p, "Armor_Nullified")
					end
				end
			end
			player:setFlags("-sp_qianlixingPFfrom")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("sp_qianlixing")
	end,
}
if not sgs.Sanguosha:getSkill("sp_qianlixing") then skills:append(sp_qianlixing) end
if not sgs.Sanguosha:getSkill("sp_qianlixingMD") then skills:append(sp_qianlixingMD) end
if not sgs.Sanguosha:getSkill("sp_qianlixingPF") then skills:append(sp_qianlixingPF) end
extension:insertRelatedSkills("sp_qianlixing","#sp_qianlixingMD")
extension:insertRelatedSkills("sp_qianlixing","#sp_qianlixingPF")

sp_shenguanyu:addRelateSkill("sp_qianlixing")
sp_guoguanzhanjiang_RAP = sgs.CreateTriggerSkill{
    name = "sp_guoguanzhanjiang_RAP",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
                return false
            end
			for _, spsgy in sgs.qlist(room:getAllPlayers()) do
			    if spsgy:hasSkill("sp_guoguanzhanjiang") then
					if spsgy:hasFlag("PASSlevel") then --过关奖励
				    	room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), 1)
						local n = spsgy:getMark("&PASSlevel")
						room:drawCards(spsgy, n, self:objectName())
					elseif not spsgy:hasFlag("PASSlevel") and spsgy:getMark("ggzz_punishlose") == 0 then --惩罚
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:loseMaxHp(spsgy, 1)
					end
					break
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getMark("&KILLgeneral") > 0 then --斩将奖励
	    	room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 2)
			local n = player:getMark("&KILLgeneral")
			room:drawCards(player, n, "sp_guoguanzhanjiang_RAP")
			if n > 1 then
				local rec = sgs.RecoverStruct()
				rec.who = player
				rec.recover = n - 1
				room:recover(player, rec)
			end
			if n > 2 then
				local count = player:getMaxHp()
				local mhp = sgs.QVariant()
				mhp:setValue(count + n - 2)
				room:setPlayerProperty(player, "maxhp", mhp)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("sp_guoguanzhanjiang")
	end,
}
if not sgs.Sanguosha:getSkill("sp_guoguanzhanjiang_RAP") then skills:append(sp_guoguanzhanjiang_RAP) end

sp_weizhen = sgs.CreateViewAsSkill{
	name = "sp_weizhen",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (to_select:getTypeId() == sgs.Card_TypeBasic or to_select:getTypeId() == sgs.Card_TypeTrick)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local DWN = sgs.Sanguosha:cloneCard("drowning", cards[1]:getSuit(), cards[1]:getNumber())
			DWN:addSubcard(cards[1])
			DWN:setSkillName(self:objectName())
			return DWN
		end
	end,
	enabled_at_play = function(self, player)
	    return player:hasSkill(self:objectName())
	end,
}
sp_weizhen_limited = sgs.CreateTriggerSkill{
    name = "#sp_weizhen_limited",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() and table.contains(use.card:getSkillNames(), "sp_weizhen") then
				room:addPlayerMark(player, "sp_weizhen_used")
				local n = player:getMark("sp_weizhen_used")
				if n == 2 then
					room:loseHp(player, 1, true, player, self:objectName())
				elseif n >= 3 then
					room:loseMaxHp(player, 1)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
                return false
            end
			for _, spsgy in sgs.qlist(room:getAllPlayers()) do
			    if spsgy:getMark("sp_weizhen_used") > 0 then
				    local m = spsgy:getMark("sp_weizhen_used")
					room:removePlayerMark(spsgy, "sp_weizhen_used", m)
					break
				end
			end
		end
	end,
}
sp_shenguanyu:addSkill(sp_weizhen)
sp_shenguanyu:addSkill(sp_weizhen_limited)
extension:insertRelatedSkills("sp_weizhen","#sp_weizhen_limited")


sp_xianshengCard = sgs.CreateSkillCard{
    name = "sp_xianshengCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 3 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in sgs.list(targets) do
		    room:drawCards(p, 2, "sp_xiansheng")
			local recover = sgs.RecoverStruct()
			recover.who = p
			room:recover(p, recover)
		end
	end,
}
sp_xianshengVS = sgs.CreateZeroCardViewAsSkill{
    name = "sp_xiansheng",
    view_as = function()
		return sp_xianshengCard:clone()
	end,
	response_pattern = "@@sp_xiansheng",
}
sp_xiansheng = sgs.CreateTriggerSkill{
	name = "sp_xiansheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	view_as_skill = sp_xianshengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		room:askForUseCard(player, "@@sp_xiansheng", "@sp_xiansheng-card")
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName())
	end,
}
sp_shenguanyu:addSkill(sp_xiansheng)

--20 风神·吕蒙
sp_shenlvmeng = sgs.General(extension_G, "sp_shenlvmeng", "god", 4, true)

sp_guamuCard = sgs.CreateSkillCard{
	name = "sp_guamuCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0
	end,
	on_use = function(self, room, source, targets)
	    local choice1 = room:askForChoice(targets[1], "sp_guamu", "sp_guamuBasic+sp_guamuTrick+sp_guamuEquip")
		if choice1 == "sp_guamuBasic" then
			room:setPlayerFlag(source, "sp_guamuBasic")
			local log = sgs.LogMessage()
			log.type = "$sp_guamuBasic"
			log.from = targets[1]
			room:sendLog(log)
		elseif choice1 == "sp_guamuTrick" then
			room:setPlayerFlag(source, "sp_guamuTrick")
			local log = sgs.LogMessage()
			log.type = "$sp_guamuTrick"
			log.from = targets[1]
			room:sendLog(log)
		elseif choice1 == "sp_guamuEquip" then
			room:setPlayerFlag(source, "sp_guamuEquip")
			local log = sgs.LogMessage()
			log.type = "$sp_guamuEquip"
			log.from = targets[1]
			room:sendLog(log)
		end
		local card_ids = room:getNCards(3)
		room:fillAG(card_ids)
		room:broadcastSkillInvoke("sp_guamu", 1)
		room:getThread():delay()
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		for _, c in sgs.qlist(card_ids) do
			local card = sgs.Sanguosha:getCard(c)
			if source:hasFlag("sp_guamuBasic") then
				if card:isKindOf("BasicCard") then
					to_get:append(c)
					room:addPlayerMark(source, "&sp_guamu")
				else
					to_throw:append(c)
				end
			end
			if source:hasFlag("sp_guamuTrick") then
				if card:isKindOf("TrickCard") then
					to_get:append(c)
					room:addPlayerMark(source, "&sp_guamu")
				else
					to_throw:append(c)
				end
			end
			if source:hasFlag("sp_guamuEquip") then
				if card:isKindOf("EquipCard") then
					to_get:append(c)
					room:addPlayerMark(source, "&sp_guamu")
				else
					to_throw:append(c)
				end
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		if not to_get:isEmpty() then
			for _, id in sgs.qlist(to_get) do
				dummy:addSubcard(id)
			end
			if targets[1]:objectName() ~= source:objectName() then
				local choice2 = room:askForChoice(source, "sp_guamu", "1+2")
				if choice2 == "1" then
					targets[1]:obtainCard(dummy)
				elseif choice2 == "2" then
					source:obtainCard(dummy)
				end
			else
				room:getThread():delay()
				source:obtainCard(dummy)
			end
		end
		dummy:clearSubcards()
		if not to_throw:isEmpty() then
			dummy:addSubcards(getCardList(to_throw))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), "sp_guamu", "")
			room:throwCard(dummy, reason, nil)
		end
		room:clearAG()
		local n = source:getMark("&sp_guamu")
		if n >= 1 then
			room:broadcastSkillInvoke("sp_guamu", 2)
			room:drawCards(source, 1, "sp_guamu")
			local choice3 = room:askForChoice(source, "sp_guamuONE", "sp_guamuONEthrow+sp_guamuONEput")
			if choice3 == "sp_guamuONEthrow" then
				room:askForDiscard(source, "sp_guamu", 1, 1, false, true)
			elseif choice3 == "sp_guamuONEput" then
				local cardd = room:askForCardChosen(source, source, "he", "sp_guamu")
				if cardd then
					room:setPlayerFlag(source, "sp_guamuPUT")
					local reasonx = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), nil, "sp_guamu", nil)
					room:moveCardTo(sgs.Sanguosha:getCard(cardd), source, nil, sgs.Player_DrawPile, reasonx, false)
					room:setPlayerFlag(source, "-sp_guamuPUT")
				end
			end
		end
		if n >= 2 then
			room:broadcastSkillInvoke("sp_guamu", 3)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
		if n >= 3 then
			room:broadcastSkillInvoke("sp_guamu", 4)
			room:acquireOneTurnSkills(source, "sp_guamu", "gongxin")
		end
		room:removePlayerMark(source, "&sp_guamu", n)
	end,
}
sp_guamu = sgs.CreateZeroCardViewAsSkill{
    name = "sp_guamu",
	view_as = function()
		return sp_guamuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_guamuCard")
	end,
}
sp_shenlvmeng:addSkill(sp_guamu)

sp_dujiangCard = sgs.CreateSkillCard{
	name = "sp_dujiangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.to:getRoom()
		room:setPlayerFlag(effect.from, "sp_dujiangSource")
		room:setPlayerFlag(effect.to, "sp_dujiangTarget")
		room:addPlayerMark(effect.to, "&sp_dujiang+to+#"..effect.from:objectName().."-Clear")
		room:setFixedDistance(effect.from, effect.to, 1)
		local new_data = sgs.QVariant()
		new_data:setValue(effect.to)
		effect.from:setTag("sp_dujiang", new_data)
	end,
}
sp_dujiang = sgs.CreateOneCardViewAsSkill{
    name = "sp_dujiang",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local boat = sp_dujiangCard:clone()
		boat:addSubcard(card:getId())
		boat:setSkillName(self:objectName())
		return boat
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_dujiangCard")
	end,
}
sp_dujiangxijing = sgs.CreateTargetModSkill{
	name = "#sp_dujiangxijing",
	residue_func = function(self, from, card, to)
		if from and from:hasFlag("sp_dujiangSource") and card and to and to:hasFlag("sp_dujiangTarget") then
			return 1000
		else
			return 0
		end
	end,
}
--重置距离
sp_dujiangFixedDistanceClear = sgs.CreateTriggerSkill{
	name = "#sp_dujiangFixedDistanceClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
			return false
		end
		local jingzhou = player:getTag("sp_dujiang"):toPlayer() 
		if jingzhou then
			room:removeFixedDistance(player, jingzhou, 1)
		end
		player:removeTag("sp_dujiang")
	end,
	can_trigger = function(self, player)
		return player
	end,
}
sp_shenlvmeng:addSkill(sp_dujiang)
sp_shenlvmeng:addSkill(sp_dujiangxijing)
sp_shenlvmeng:addSkill(sp_dujiangFixedDistanceClear)
extension:insertRelatedSkills("sp_dujiang","#sp_dujiangxijing")
extension:insertRelatedSkills("sp_dujiang","#sp_dujiangFixedDistanceClear")

--

--21 火神·周瑜
sp_shenzhouyu = sgs.General(extension_G, "sp_shenzhouyu", "god", 4, true)

sp_qinmo = sgs.CreateTriggerSkill{
    name = "sp_qinmo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "sp_qinmoloseHp+sp_qinmoaddHp")
			room:setPlayerFlag(player, choice)
			if choice == "sp_qinmoloseHp" then
			    local plistls = room:getAllPlayers()
				local victim = room:askForPlayerChosen(player, plistls, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(victim, 1, true, player, self:objectName())
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
			elseif choice == "sp_qinmoaddHp" then
			    local plistad = room:getAllPlayers()
				local beneficiary = room:askForPlayerChosen(player, plistad, self:objectName())
                local recover = sgs.RecoverStruct()
				recover.who = beneficiary
				room:recover(beneficiary, recover)
				room:broadcastSkillInvoke(self:objectName())
                room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
            end
			room:setPlayerFlag(player, "-"..choice)
        end
    end,
}
sp_shenzhouyu:addSkill(sp_qinmo)

sp_huoshen = sgs.CreateTriggerSkill{
	name = "sp_huoshen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local caobs = damage.to
		if player:hasSkill(self:objectName()) and player:inMyAttackRange(caobs) and damage.nature == sgs.DamageStruct_Fire then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local fire = damage.damage
			damage.damage = fire + 1
			data:setValue(damage)
			room:broadcastSkillInvoke(self:objectName())
		end
	end,
}
sp_shenzhouyu:addSkill(sp_huoshen)

Fire = function(player, target, damagePoint)
	local damage = sgs.DamageStruct()
	damage.from = player
	damage.to = target
	damage.damage = damagePoint
	damage.nature = sgs.DamageStruct_Fire
	player:getRoom():damage(damage)
end
function toSet(self)
	local set = {}
	for _, ele in pairs(self) do
		if not table.contains(set, ele) then
			table.insert(set, ele)
		end
	end
	return set
end
sp_chibiCard = sgs.CreateSkillCard{
	name = "sp_chibiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    room:removePlayerMark(source, "@sp_chibi")
		room:addPlayerMark(source, "sp_chibi_using")
	    room:broadcastSkillInvoke("sp_chibi")
		room:doLightbox("sp_chibiAnimate")
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			Fire(source, player, 1)
		end
		if source:getMark("sp_chibikill") > 0 then
		    source:drawCards(4, "sp_chibi")
		end
		room:removePlayerMark(source, "sp_chibi_using")
		room:addPlayerMark(source, "sp_chibi_used")
	end,
}
sp_chibiVS = sgs.CreateZeroCardViewAsSkill{
    name = "sp_chibi",
	view_as = function()
		return sp_chibiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sp_chibi") > 0
	end,
}
sp_chibi = sgs.CreateTriggerSkill{
	name = "sp_chibi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@sp_chibi",
	events = {sgs.Death},
	view_as_skill = sp_chibiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer and killer:getMark("sp_chibi_using") > 0 then
			killer:addMark("sp_chibikill")
		end
	end,
}

sp_shenzhouyu:addSkill(sp_chibi)


sp_qiangu = sgs.CreateTriggerSkill{
    name = "sp_qiangu",
	frequency = sgs.Skill_Wake,
	waked_skills = "sp_shenzi",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("sp_chibi_used") < 1 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doLightbox("$sp_qiangu")
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		if not player:hasSkill("sp_shenzi") then
		    room:acquireSkill(player, "sp_shenzi")
		end
		room:addPlayerMark(player, self:objectName())
	end,
}
sp_shenzhouyu:addSkill(sp_qiangu)

--“神姿”
sp_shenzi = sgs.CreateTriggerSkill{
    name = "sp_shenzi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "sp_shenzi", data) then
		    local choices = {}
			table.insert(choices, "sp_shenzi3cards")
			table.insert(choices, "sp_shenzi4cards")
			table.insert(choices, "sp_shenzi1card")
			table.insert(choices, "sp_shenzi0card")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			
			if choice == "sp_shenzi3cards" then
			    draw.num = draw.num + 1
			    data:setValue(draw)
				room:broadcastSkillInvoke(self:objectName())
			elseif choice == "sp_shenzi4cards" then
			    draw.num = draw.num + 2
			    data:setValue(draw)
				room:setPlayerFlag(player, "sp_shenzi_4cards")
				room:broadcastSkillInvoke(self:objectName())
			elseif choice == "sp_shenzi1card" then
			    draw.num = draw.num - 1
				if draw.num < 0 then
				    draw.num = 0
				end
			    data:setValue(draw)
				room:setPlayerFlag(player, "sp_shenzi_1card")
				room:broadcastSkillInvoke(self:objectName())
			elseif choice == "sp_shenzi0card" then
			    draw.num = draw.num - 2
				if draw.num < 0 then
				    draw.num = 0
				end
			    data:setValue(draw)
				local plist = room:getOtherPlayers(player)
		        local victim = room:askForPlayerChosen(player, plist, self:objectName())
		        local damage = sgs.DamageStruct()
		        damage.from = player
		        damage.to = victim
		        damage.nature = sgs.DamageStruct_Fire
		        room:damage(damage)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
}
sp_shenzic = sgs.CreateMaxCardsSkill{
	name = "#sp_shenzic",
	extra_func = function(self, target)
		if target:hasSkill("sp_shenzi") then
			if target:hasFlag("sp_shenzi_4cards") then
				return -1
			end
			if target:hasFlag("sp_shenzi_1card") then
				return 2
			end
		else
			return 0
		end
	end,
}

if not sgs.Sanguosha:getSkill("sp_shenzi") then skills:append(sp_shenzi) end
if not sgs.Sanguosha:getSkill("sp_shenzic") then skills:append(sp_shenzic) end
extension:insertRelatedSkills("sp_shenzi","#sp_shenzic")

--22 天神·诸葛
sp_shenzhuge = sgs.General(extension_G, "sp_shenzhuge", "god", 4, true)

sp_zhishen = sgs.CreateTriggerSkill{
	name = "sp_zhishen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() and use.card:isRed() then
			player:gainMark("&ShenZhi", 2)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
		elseif use.card:isNDTrick() and use.card:isBlack() then
			player:gainMark("&ShenZhi", 1)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
		elseif use.card:isKindOf("DelayedTrick") then
			player:drawCards(3, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 3)
		end
	end,
}
sp_zhishenX = sgs.CreateProhibitSkill{
	name = "#sp_zhishenX",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("sp_zhishen") and card:isKindOf("DelayedTrick")
	end,
}
sp_shenzhuge:addSkill(sp_zhishen)
sp_shenzhuge:addSkill(sp_zhishenX)
extension:insertRelatedSkills("sp_zhishen", "#sp_zhishenX")

sp_zhengshen_draw = sgs.CreateTriggerSkill{
	name = "#sp_zhengshen_draw",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "sp_zhengshen", data) then
			draw.num = draw.num + 2
			data:setValue(draw)
			room:broadcastSkillInvoke("sp_zhengshen")
			room:addPlayerMark(player, "sp_zhengshen_used")
		end
	end,
}
sp_zhengshenGCCard = sgs.CreateSkillCard{
    name = "sp_zhengshenGCCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    targets[1]:obtainCard(self, false)
	end,
}
sp_zhengshenVS = sgs.CreateViewAsSkill{
    name = "sp_zhengshen",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return not to_select:isEquipped()
	end,
    view_as = function(self, cards)
	    if #cards == 0 then return end
		local vs_card = sp_zhengshenGCCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern=="@@sp_zhengshenGC!" then return true end
		return string.startsWith(pattern, "@@sp_zhengshenGC")
	end,
}
sp_zhengshen = sgs.CreateTriggerSkill{
    name = "sp_zhengshen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sp_zhengshenVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and player:getMark("sp_zhengshen_used") > 0 then
		    if room:askForSkillInvoke(player, "@sp_zhengshenGC", data) then
		        room:askForUseCard(player, "@@sp_zhengshenGC!", "@sp_zhengshenGC-card1")
		        room:askForUseCard(player, "@@sp_zhengshenGC!", "@sp_zhengshenGC-card2")
				room:removePlayerMark(player, "sp_zhengshen_used")
			else
			    room:askForDiscard(player, self:objectName(), 2, 2)
			    room:removePlayerMark(player, "sp_zhengshen_used")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("sp_zhengshen_used") > 0
	end,
}
sp_shenzhuge:addSkill(sp_zhengshen)
sp_shenzhuge:addSkill(sp_zhengshen_draw)
extension:insertRelatedSkills("sp_zhengshen", "#sp_zhengshen_draw")

sp_junshen = sgs.CreateDistanceSkill{
	name = "sp_junshen",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			local equips = from:getEquips()
			local length = equips:length()
			return -length
		end
	end,
}
sp_shenzhuge:addSkill(sp_junshen)

sp_qitian = sgs.CreateTriggerSkill{
    name = "sp_qitian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:hasSkill(self:objectName()) then
			
			if player:getMark("&ShenZhi") > 0 and player:getPhase() == sgs.Player_Judge and room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local choices = {}
					for i = 1, player:getMark("&ShenZhi") do
						table.insert(choices, i)
					end
					
					table.insert(choices, "cancel")
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice ~= "cancel" then
						local num = tonumber(choice)
						room:removePlayerMark(player, "&ShenZhi", num)
						local judge = sgs.JudgeStruct()
						judge.pattern = "."
						judge.good = true
						judge.play_animation = false
						judge.who = player
						judge.reason = self:objectName()
						room:judge(judge)
						local suit = judge.card:getSuit()
						if suit == sgs.Card_Heart then --摸1、弃2、回1
							player:drawCards(num, self:objectName())
							room:askForDiscard(player, self:objectName(), 2, 2, false, true)
							local recover1 = sgs.RecoverStruct()
							recover1.who = player
							room:recover(player, recover1)
							room:broadcastSkillInvoke("sp_qitian", 1)
						elseif suit == sgs.Card_Diamond then --获得4枚“神智”标记，获得“界火计”
							player:gainMark("&ShenZhi", 4)
							if not player:hasSkill("olhuoji") then
								room:acquireOneTurnSkills(player, "sp_qitian", "olhuoji")
							end
							room:broadcastSkillInvoke("sp_qitian", 2)
						elseif suit == sgs.Card_Club then --令目标(永久)获得1枚“狂风”标记
							local plist1c = room:getAllPlayers()
							room:setPlayerFlag(player, "sp_qitian_Club")
							local victim1c = room:askForPlayerChosen(player, plist1c, self:objectName())
							room:setPlayerFlag(player, "-sp_qitian_Club")
							victim1c:gainMark("@sp_crazywind") --为了防止与神诸葛亮同时在场时“狂风”标记于其回合开始时被清掉，另设了一个和原“狂风”标记(@gale)中文名称和用处都一样，但时效不一样的“狂风”标记(@sp_crazywind)。
							room:broadcastSkillInvoke("sp_qitian", 3)
							if num == 4 then
								room:damage(sgs.DamageStruct(self:objectName(), player, victim1c, 1, sgs.DamageStruct_Fire))
							end
						elseif suit == sgs.Card_Spade then --弃置目标1张牌，再自弃1张牌
							local plist4s = room:getAllPlayers()
							local victim4s = room:askForPlayerChosen(player, plist4s, self:objectName())
							room:broadcastSkillInvoke("sp_qitian", 4)
							if num - 1 > 0 then
								room:damage(sgs.DamageStruct(self:objectName(), player, victim4s, num-1, sgs.DamageStruct_Thunder))
							end
							local discards = sgs.IntList()
							if player:canDiscard(victim4s, "he") then
								if num - 2 < 0 then
									num = 3
								end
								for i = 1, num - 2 do--进行多次执行
									local id = room:askForCardChosen(player, victim4s, "he", self:objectName(),
										false,--选择卡牌时手牌不可见
										sgs.Card_MethodDiscard,--设置为弃置类型
										discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
										i>1)--只有执行过一次选择才可取消
									if id < 0 then break end--如果卡牌id无效就结束多次执行
									discards:append(id)--将选择的id添加到虚拟卡的子卡表
								end
								room:throwCard(discards, "sp_qitian", victim4s, player)
								room:askForDiscard(player, self:objectName(), num, num, false, true)
							end
							
						end
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		
			
		end
	end,
}
sp_qitian_crazywind = sgs.CreateTriggerSkill{ --赋予“狂风”标记相应的技能
	name = "#sp_qitian_crazywind",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local n = player:getMark("@sp_crazywind")
		if damage.nature == sgs.DamageStruct_Fire then
			damage.damage = damage.damage + n --火焰伤害会随着“狂风”标记的叠加而叠加
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("@sp_crazywind") > 0
	end,
}

sp_shenzhuge:addSkill(sp_qitian)
sp_shenzhuge:addSkill(sp_qitian_crazywind)
extension:insertRelatedSkills("sp_qitian", "#sp_qitian_crazywind")
sp_shenzhuge:addRelateSkill("olhuoji")

sp_zhijueDying = sgs.CreateTriggerSkill{
    name = "#sp_zhijueDying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:addPlayerMark(player, "sp_zhijueDying")
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("sp_zhijue") and player:isAlive() and player:getMark("sp_zhijueDying") == 0
	end,
}
sp_zhijue = sgs.CreateTriggerSkill{
	name = "sp_zhijue",
	frequency = sgs.Skill_Wake,
	waked_skills = "bazhen,sp_guimen",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local x = 0
		if player:getHp() == 1 then
			x = x + 1
		end
		if player:getHandcardNum() <= 1 then
			x = x + 1
		end
		if player:getMark("sp_zhijueDying") >= 1 then
			x = x + 1
		end
		if x >= 2 then return true end
		return false
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:doLightbox("$sp_zhijue")
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		player:gainMark("@sp_fog")
		if not player:hasSkill("bazhen") then
		    room:acquireSkill(player, "bazhen")
		end
		if not player:hasSkill("sp_guimen") then
		    room:acquireSkill(player, "sp_guimen")
		end
		room:addPlayerMark(player, self:objectName())
	end,
}
sp_zhijue_fog = sgs.CreateTriggerSkill{ --赋予“大雾”标记相应的技能
	name = "#sp_zhijue_fog",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then
			return true
		else
			return false
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("@sp_fog") > 0
	end,
}
fog_Clear = sgs.CreateTriggerSkill{ --清除“大雾”标记
    name = "#fog_Clear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		player:loseMark("@sp_fog")
	end,
	can_trigger = function(self, player)
		return player and player:getMark("@sp_fog") > 0
	end,
}
sp_shenzhuge:addSkill(sp_zhijue)
sp_shenzhuge:addSkill(fog_Clear)
sp_shenzhuge:addSkill(sp_zhijueDying)
sp_shenzhuge:addSkill(sp_zhijue_fog)
extension:insertRelatedSkills("sp_zhijue", "#fog_Clear")
extension:insertRelatedSkills("sp_zhijue", "#sp_zhijueDying")
extension:insertRelatedSkills("sp_zhijue", "#sp_zhijue_fog")


--“鬼门”
Thunder = function(player, target, damagePoint)
	local damage = sgs.DamageStruct()
	damage.from = player
	damage.to = target
	damage.damage = damagePoint
	damage.nature = sgs.DamageStruct_Thunder
	player:getRoom():damage(damage)
end
function toSet(self)
	local set = {}
	for _, ele in pairs(self) do
		if not table.contains(set, ele) then
			table.insert(set, ele)
		end
	end
	return set
end
sp_guimenCard = sgs.CreateSkillCard{
    name = "sp_guimenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doLightbox("$sp_guimenn")
		local n = source:getMark("&ShenZhi")
		room:removePlayerMark(source, "&ShenZhi", n)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			Thunder(source, p, math.random(1,3))
		end
	end,
}
sp_guimen = sgs.CreateZeroCardViewAsSkill{
	name = "sp_guimen",
	view_as = function()
		return sp_guimenCard:clone()
	end,
	    enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_guimenCard") and player:getMark("&ShenZhi") > 9
	end,
}
if not sgs.Sanguosha:getSkill("sp_guimen") then skills:append(sp_guimen) end

--23 君神·曹操
sp_shencaocao = sgs.General(extension_G, "sp_shencaocao", "god", 4, true, false, false, 3)

sp_zhujiuStartandEnd = sgs.CreateTriggerSkill{
	name = "#sp_zhujiuStartandEnd",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, "sp_zhujiu", data) then
				room:drawCards(player, 2, "sp_zhujiu")
				local liubei = room:askForPlayerChosen(player, room:getOtherPlayers(player), "sp_zhujiu", "CaL_zhujiuLYX")
				room:broadcastSkillInvoke("sp_zhujiu")
				room:addPlayerMark(player, "&qingmei_zhujiu-PlayClear")
				room:addPlayerMark(liubei, "&qingmei_zhujiu-PlayClear")
			end
		end
	end,
}
sp_zhujiuCard = sgs.CreateSkillCard{
    name = "sp_zhujiuCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getMark("&qingmei_zhujiu-PlayClear") > 0 and player:canPindian(to_select)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:pindian(effect.to, "sp_zhujiu", nil)
		if effect.from:getMark("&sp_zhujiuFQC") <= 10 and effect.from:getMark("@duangexing") > 0 then
			room:addPlayerMark(effect.from, "&sp_zhujiuFQC")
		end
	end,
}
sp_zhujiuVS = sgs.CreateZeroCardViewAsSkill{
    name = "sp_zhujiu",
    view_as = function()
		return sp_zhujiuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&qingmei_zhujiu-PlayClear") > 0 and not player:isKongcheng() and not player:hasFlag("sp_zhujiulimited")
	end,
}
sp_zhujiu = sgs.CreateTriggerSkill{
    name = "sp_zhujiu",
	view_as_skill = sp_zhujiuVS,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "sp_zhujiu" and pindian.from:objectName() == player:objectName() then
				local fromNumber = pindian.from_card:getNumber()
				local toNumber = pindian.to_card:getNumber()
				if not player:hasFlag("sp_zhujiugetPindianCards_used") then
					if room:askForSkillInvoke(player, "@sp_zhujiugetPindianCards", data) then
						room:broadcastSkillInvoke("sp_zhujiu")
						room:obtainCard(player, pindian.from_card)
						room:obtainCard(player, pindian.to_card)
						room:setPlayerFlag(player, "sp_zhujiugetPindianCards_used")
					end
				end
				if fromNumber > toNumber then
					local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
					ana:deleteLater()
					ana:setSkillName("sp_zhujiu")
					room:useCard(sgs.CardUseStruct(ana, player, player, false))
					if (player:getMark("&sp_zhujiuFQC") <= 10 and player:getMark("@duangexing") > 0) then
					room:addPlayerMark(player, "&sp_zhujiuFQC") end
					room:broadcastSkillInvoke("sp_zhujiu")
				else
					room:setPlayerFlag(player, "sp_zhujiuPDlose")
					player:turnOver()
					if player:hasFlag("sp_zhujiuPDlose") and not player:faceUp() then
						if not player:isKongcheng() then
							room:askForDiscard(player, "sp_zhujiu", 1, 1)
						end
						room:setPlayerFlag(player, "-sp_zhujiuPDlose")
					elseif player:hasFlag("sp_zhujiuPDlose") and player:faceUp() then
						if not player:isNude() then
							local id = room:askForCardChosen(pindian.to, player, "he", "sp_zhujiu", false, sgs.Card_MethodDiscard)
							room:throwCard(id, player, pindian.to)
						end
						room:setPlayerFlag(player, "sp_zhujiulimited")
						room:setPlayerFlag(player, "-sp_zhujiuPDlose")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_shencaocao:addSkill(sp_zhujiu)
sp_shencaocao:addSkill(sp_zhujiuStartandEnd)
extension:insertRelatedSkills("sp_zhujiu", "#sp_zhujiuStartandEnd")

sp_gexing = sgs.CreateTriggerSkill{
	name = "sp_gexing",
	frequency = sgs.Skill_Limited,
	waked_skills = "sp_tianxia",
	limit_mark = "@duangexing",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@duangexing") > 0 and player:getMark("&sp_zhujiuFQC") >= 10 and room:askForSkillInvoke(player, self:objectName()) then
			room:removePlayerMark(player, "@duangexing")
			room:doLightbox("$duangexing")
			room:loseMaxHp(player, 1)
			room:acquireSkill(player, "sp_tianxia")
			local n = player:getMark("&sp_zhujiuFQC")
			room:removePlayerMark(player, "&sp_zhujiuFQC", n)
		end
	end,
}
sp_shencaocao:addSkill(sp_gexing)

--“天下”
sp_tianxiaCard = sgs.CreateSkillCard{
	name = "sp_tianxiaCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choice = room:askForChoice(source, "sp_tianxia", "1+2+3+cancel")
		if choice == "1" then
			room:loseHp(source, 1, true, source, "sp_tianxia")
			room:broadcastSkillInvoke("sp_tianxia", 1)
			for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    	local choices = {}
				if not t:isNude() then
					table.insert(choices, "1")
				end
				table.insert(choices, "2")
				local choiceO = room:askForChoice(t, "sp_tianxiaOther", table.concat(choices, "+"))
				if choiceO == "1" then
			    	local card = room:askForCardChosen(t, t, "he", "sp_tianxia")
					room:obtainCard(source, card, false)
				else
			    	room:damage(sgs.DamageStruct("sp_tianxia", source, t, 1, sgs.DamageStruct_Normal))
				end
			end
		elseif choice == "2" then
			room:addPlayerMark(source, "&SkipPlayerPlay")
			room:setPlayerFlag(source, "SkipPlayerPlayDoNotClear")
			room:broadcastSkillInvoke("sp_tianxia", 2)
			for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    	local choices = {}
				if not t:isAllNude() then
					table.insert(choices, "1")
				end
				table.insert(choices, "2")
				local choiceF = room:askForChoice(source, "sp_tianxiaSelf", table.concat(choices, "+"))
				if choiceF == "1" then
			    	local card = room:askForCardChosen(source, t, "hej", "sp_tianxia")
					room:obtainCard(source, card, false)
				else
			    	room:damage(sgs.DamageStruct("sp_tianxia", source, t, 1, sgs.DamageStruct_Normal))
				end
			end
		elseif choice == "3" then
			room:loseMaxHp(source, 1)
			--执行第一项
			room:loseHp(source, 1, true, source, "sp_tianxia")
			room:broadcastSkillInvoke("sp_tianxia", 1)
			for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    	local choices = {}
				if not t:isNude() then
					table.insert(choices, "1")
				end
				table.insert(choices, "2")
				local choiceO = room:askForChoice(t, "sp_tianxiaOther", table.concat(choices, "+"))
				if choiceO == "1" then
			    	local card1 = room:askForCardChosen(t, t, "he", "sp_tianxia")
					room:obtainCard(source, card1, false)
				else
			    	room:damage(sgs.DamageStruct("sp_tianxia", source, t, 1, sgs.DamageStruct_Normal))
				end
			end
			--执行第二项
			room:addPlayerMark(source, "&SkipPlayerPlay")
			room:setPlayerFlag(source, "SkipPlayerPlayDoNotClear")
			room:broadcastSkillInvoke("sp_tianxia", 2)
			for _, t in sgs.qlist(room:getOtherPlayers(source)) do
		    	local choicess = {}
				if not t:isAllNude() then
					table.insert(choicess, "1")
				end
				table.insert(choicess, "2")
				local dest = sgs.QVariant()
				dest:setValue(t)
				local choiceF = room:askForChoice(source, "sp_tianxiaSelf", table.concat(choicess, "+"), dest)
				if choiceF == "1" then
			    	local card2 = room:askForCardChosen(source, t, "hej", "sp_tianxia")
					room:obtainCard(source, card2, false)
				else
			    	room:damage(sgs.DamageStruct("sp_tianxia", source, t, 1, sgs.DamageStruct_Normal))
				end
			end
			room:broadcastSkillInvoke("sp_tianxia", 3)
		end
	end,
}
sp_tianxia = sgs.CreateZeroCardViewAsSkill{
    name = "sp_tianxia",
	view_as = function()
		return sp_tianxiaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_tianxiaCard")
	end,
}
if not sgs.Sanguosha:getSkill("sp_tianxia") then skills:append(sp_tianxia) end
--跳过出牌阶段--（通用代码）
SkipPlayerPlay = sgs.CreateTriggerSkill{
	name = "SkipPlayerPlay",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if not player:isSkipped(change.to) and change.to == sgs.Player_Play then
			player:skip(change.to)
		end
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
            	if p:getMark("&SkipPlayerPlay") > 0 and not p:hasFlag("SkipPlayerPlayDoNotClear") then
		        	room:removePlayerMark(p, "&SkipPlayerPlay")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&SkipPlayerPlay") > 0
	end,
}
if not sgs.Sanguosha:getSkill("SkipPlayerPlay") then skills:append(SkipPlayerPlay) end

--

--24 战神·吕布
sp_shenlvbuu = sgs.General(extension_G, "sp_shenlvbuu", "god", 6, true)

sp_wujiChoice = sgs.CreateTriggerSkill{
	name = "#sp_wujiChoice",
	priority = 4,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, "sp_wuji", data) then
			local choice = room:askForChoice(player, "sp_wuji", "1+2+cancel")
			if choice == "1" then
				room:loseMaxHp(player, 1)
				room:drawCards(player, 2, "sp_wuji")
				room:askForDiscard(player, "sp_wuji", 1, 1, false, true)
				room:broadcastSkillInvoke("sp_wuji", 1)
				room:acquireOneTurnSkills(player, "sp_wuji", "wushuang|sp_feijiang")
			elseif choice == "2" then
				room:loseMaxHp(player, 1)
				room:drawCards(player, 1, "sp_wuji")
				room:askForDiscard(player, "sp_wuji", 2, 2, false, true)
				room:broadcastSkillInvoke("sp_wuji", 2)
				room:acquireOneTurnSkills(player, "sp_wuji", "wushuang|sp_feijiang|sp_mengguan|sp_duyong")
				if player:getMark("sp_wuji") == 0 then
					room:addPlayerMark(player, "&sp_wujiAnger")
				end
			end
		end
	end,
}
sp_wuji = sgs.CreateTriggerSkill{
	name = "sp_wuji",
	frequency = sgs.Skill_Wake,
	waked_skills = "wushuang,sp_feijiang,sp_mengguan,sp_duyong,sp_hengsaoqianjun",
	events = {sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&sp_wujiAnger") < 3 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(), 3)
		room:doSuperLightbox("sp_shenlvbuu", "sp_wuji")
		room:acquireSkill(player, "sp_hengsaoqianjun")
		room:addPlayerMark(player, self:objectName())
		room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
		local n = player:getMark("&sp_wujiAnger")
		if n > 0 then room:removePlayerMark(player, "&sp_wujiAnger", n) end
	end,
}

sp_shenlvbuu:addSkill(sp_wuji)
sp_shenlvbuu:addSkill(sp_wujiChoice)
extension:insertRelatedSkills("sp_wuji", "#sp_wujiChoice")


--“无双”（即吕布的技能“无双”）
--“飞将”
sp_feijiangCard = sgs.CreateSkillCard{
    name = "sp_feijiangCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "sp_feijiang", nil)
		if success then
			if effect.from:hasFlag("drank") then
				room:setPlayerFlag(effect.from, "-drank")
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			slash:setSkillName("sp_feijiang")
			room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to), false)
		else
			if not effect.to:isAllNude() then
				local card = room:askForCardChosen(effect.from, effect.to, "hej", "sp_feijiang")
				room:obtainCard(effect.from, card, false)
			end
			room:setPlayerFlag(effect.from, "Global_PlayPhaseTerminated")
		end
	end,
}
sp_feijiang = sgs.CreateZeroCardViewAsSkill{
    name = "sp_feijiang",
    view_as = function()
		return sp_feijiangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_feijiangCard") and not player:isKongcheng()
	end,
}
--“猛冠”
sp_mengguan = sgs.CreateViewAsSkill{
    name = "sp_mengguan",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return to_select:isKindOf("Weapon")
	end,
	view_as = function(self, cards)
	    if #cards == 0 then return
		elseif #cards == 1 then
		    local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local mg_card = sgs.Sanguosha:cloneCard("duel", suit, point)
			mg_card:addSubcard(id)
			mg_card:setSkillName(self:objectName())
			return mg_card
		end
	end,
}
--“独勇”
sp_duyong = sgs.CreateTriggerSkill{
	name = "sp_duyong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName())
		and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) and not player:isNude() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForDiscard(player, self:objectName(), 1, 1, false, true)
				room:broadcastSkillInvoke(self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("sp_feijiang") then skills:append(sp_feijiang) end
if not sgs.Sanguosha:getSkill("sp_mengguan") then skills:append(sp_mengguan) end
if not sgs.Sanguosha:getSkill("sp_duyong") then skills:append(sp_duyong) end

--“横扫千军”
sp_hengsaoqianjunVS = sgs.CreateViewAsSkill{
    name = "sp_hengsaoqianjun",
	response_or_use = true,
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getColor() ~= card:getColor() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
	    if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		    slash:addSubcard(cardA)
			slash:addSubcard(cardB)
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
sp_hengsaoqianjun = sgs.CreateTriggerSkill{
	name = "sp_hengsaoqianjun",
	events = {sgs.PreCardUsed, sgs.ConfirmDamage},
	view_as_skill = sp_hengsaoqianjunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") or use.card:getSkillName() ~= "sp_hengsaoqianjun" or use.from:objectName() ~= player:objectName() then return false end
			room:setTag("sp_hengsaoqianjun", data)
			local choice = room:askForChoice(player, "sp_hengsaoqianjun", "1+2+3+cancel")
			if choice == "cancel" then return false end
			if choice == "1" then
				room:broadcastSkillInvoke("sp_hengsaoqianjun")
				room:setPlayerFlag(player, "sp_hengsaoqianjunDMGbuff")
			else
				if choice == "3" then
					room:loseMaxHp(player, 1)
					room:broadcastSkillInvoke("sp_hengsaoqianjun")
					room:setPlayerFlag(player, "sp_hengsaoqianjunDMGbuff")
				end
				local extra_targets = room:getCardTargets(player, use.card, use.to)
				if extra_targets:isEmpty() then return false end
				
				local targets = room:askForPlayersChosen(player, extra_targets, self:objectName(), 0, 2, "@sp_hengsaoqianjunBUFF:"..use.card:objectName(), true, true)
				
				if (not targets:isEmpty()) then
					local adds = sgs.SPlayerList()
					for _,to in sgs.qlist(targets) do
						use.to:append(to)
						adds:append(to)
					end
					if adds:isEmpty() then return false end
					room:sortByActionOrder(adds)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					local log = sgs.LogMessage()
					log.type = "#QiaoshuiAdd"
					log.from = player
					log.to = adds
					log.card_str = use.card:toString()
					log.arg = "sp_hengsaoqianjun"
					room:sendLog(log)
					for _, p in sgs.qlist(adds) do
						room:doAnimate(1, player:objectName(), p:objectName())
					end
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke("sp_hengsaoqianjun")
				end
			end
			room:removeTag("sp_hengsaoqianjun")
		else
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and player:hasFlag("sp_hengsaoqianjunDMGbuff")
			and damage.card and damage.card:isKindOf("Slash") and table.contains(damage.card:getSkillNames(), "sp_hengsaoqianjun") then
				local log = sgs.LogMessage()
				log.type = "$sp_hengsaoqianjunDMG"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = "sp_hengsaoqianjun"
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
				room:broadcastSkillInvoke("sp_hengsaoqianjun")
				room:setPlayerFlag(player, "-sp_hengsaoqianjunDMGbuff")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("sp_hengsaoqianjun")
	end,
}
if not sgs.Sanguosha:getSkill("sp_hengsaoqianjun") then skills:append(sp_hengsaoqianjun) end

sp_xixu = sgs.CreateTriggerSkill{
	name = "sp_xixu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.Damage}, --根据技能描述，需要分开为两个时机
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() then
				if player:getMaxHp() < damage.to:getMaxHp() then
					room:setPlayerFlag(player, "sp_xixu")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() then
				if player:hasFlag("sp_xixu") then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local count = player:getMaxHp()
					local mhp = sgs.QVariant()
					mhp:setValue(count + 1)
					room:setPlayerProperty(player, "maxhp", mhp)
					room:setPlayerFlag(player, "-sp_xixu")
				end
			end
		end
	end,
}
sp_shenlvbuu:addSkill(sp_xixu)

--25 枪神·赵云
sp_shenzhaoyun = sgs.General(extension_G, "sp_shenzhaoyun", "god", 8, true)

sp_qijinCard = sgs.CreateSkillCard{
	name = "sp_qijinCard",
    will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local players = sgs.PlayerList()
		for i = 1, #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetFilter(players, to_select, player) and not player:isProhibited(to_select, card, players)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local _card = player:getTag("sp_qijin"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:setCanRecast(false)
		card:deleteLater()
		return card and card:targetFilter(players, to_select, player) and not player:isProhibited(to_select, card, players)
	end,
	feasible = function(self, targets)
		local players = sgs.PlayerList()
		for i = 1, #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetsFeasible(players, sgs.Self)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local _card = sgs.Self:getTag("sp_qijin"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:setCanRecast(false)
		card:deleteLater()
		return card and card:targetsFeasible(players, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local spszy = card_use.from
		local room = spszy:getRoom()
		room:loseMaxHp(spszy, 1)
		room:removePlayerMark(spszy, "&canuse_qijin")
		--[[local to_sp_qijin = self:getUserString()
		if to_sp_qijin == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local sp_qijin_list = {}
			table.insert(sp_qijin_list, "slash")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(sp_qijin_list, "normal_slash")
				table.insert(sp_qijin_list, "fire_slash")
				table.insert(sp_qijin_list, "thunder_slash")
				table.insert(sp_qijin_list, "ice_slash")
			end
			to_sp_qijin = room:askForChoice(spszy, "sp_qijin_slash", table.concat(sp_qijin_list, "+"))
			spszy:setTag("sp_qijinSlash", sgs.QVariant(to_sp_qijin))
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local user_str = ""
		if to_sp_qijin == "slash" then
			if card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_sp_qijin == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_sp_qijin
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("sp_qijin")
		use_card:deleteLater()
		local tos = card_use.to
		for _, to in sgs.qlist(tos) do
			local skill = room:isProhibited(spszy, to, use_card)
			if skill then
				card_use.to:removeOne(to)
			end
		end
		return use_card
	end,]]
		local user_string = self:getUserString()
		if (string.find(user_string, "slash") or string.find(user_string, "Slash")) and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        	local slashs = sgs.Sanguosha:getSlashNames()
        	user_string = room:askForChoice(spszy, "sp_qijin_slash", table.concat(slashs, "+"))
    	end
    	local use_card = sgs.Sanguosha:cloneCard(user_string)
		if not use_card then return nil end
    	use_card:setSkillName("_sp_qijin")
    	use_card:deleteLater()
    	return use_card
	end,
	on_validate_in_response = function(self, spszy)
		local room = spszy:getRoom()
		room:loseMaxHp(spszy, 1)
		room:removePlayerMark(spszy, "&canuse_qijin")
		local to_sp_qijin = ""
		if self:getUserString() == "peach+analeptic" then
			local sp_qijin_list = {}
			table.insert(sp_qijin_list, "peach")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(sp_qijin_list, "analeptic")
			end
			to_sp_qijin = room:askForChoice(spszy, "sp_qijin_saveself", table.concat(sp_qijin_list, "+"))
			spszy:setTag("sp_qijinSaveSelf", sgs.QVariant(to_sp_qijin))
		elseif self:getUserString() == "slash" then
			local sp_qijin_list = {}
			table.insert(sp_qijin_list, "slash")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(sp_qijin_list, "normal_slash")
				table.insert(sp_qijin_list, "fire_slash")
				table.insert(sp_qijin_list, "thunder_slash")
				table.insert(sp_qijin_list, "ice_slash")
			end
			to_sp_qijin = room:askForChoice(spszy, "sp_qijin_slash", table.concat(sp_qijin_list, "+"))
			spszy:setTag("sp_qijinSlash", sgs.QVariant(to_sp_qijin))
		else
			to_sp_qijin = self:getUserString()
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local user_str = ""
		if to_sp_qijin == "slash" then
			if card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_sp_qijin == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_sp_qijin
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("_sp_qijin")
		use_card:deleteLater()
		return use_card
	end,
}
sp_qijin = sgs.CreateZeroCardViewAsSkill{
	name = "sp_qijin",
	response_or_use = true,
	view_as = function(self, cards)
		--[[if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = sp_qijinCard:clone()
			card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			return card
		end
		local c = sgs.Self:getTag("sp_qijin"):toCard()
        if c then
            local card = sp_qijinCard:clone()
            if not string.find(c:objectName(), "slash") then
                card:setUserString(c:objectName())
            else
				card:setUserString(sgs.Self:getTag("sp_qijinSlash"):toString())
			end
			return card
        else
			return nil
		end
	end,]]
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
			sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        	local c = sp_qijinCard:clone()
			c:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			return c
		end
	
		local card = sgs.Self:getTag("sp_qijin"):toCard()
		if card and card:isAvailable(sgs.Self) then
			local c = sp_qijinCard:clone()
			c:setUserString(card:objectName())
			return c
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		local current = false
		local players = player:getAliveSiblings()
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = true
				break
			end
		end
		if not current then return false end
		return player:getMark("&canuse_qijin") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		local current = false
		local players = player:getAliveSiblings()
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = true
				break
			end
		end
		if not current then return false end
		if player:getMark("&canuse_qijin") == 0 or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
            return false
		end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
        if string.find(pattern, "[%u%d]") then return false end
		return true
	end,
	enabled_at_nullification = function(self, player)
		local current = player:getRoom():getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end
		return player:getMark("&canuse_qijin") > 0
	end,
}
sp_qijinKey = sgs.CreateTriggerSkill{
    name = "#sp_qijinKey",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.MaxHpChanged, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasSkill("sp_qichu") then
			local n = player:getMaxHp()
			room:addPlayerMark(player, "sp_qichuMHP_Start", n) --记录游戏开始时SP神赵云的体力上限值
			room:addPlayerMark(player, "sp_qichuMHP", n) --SP神赵云体力上限实时动态记录
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:findPlayersBySkillName("sp_qijin")) do
					if p:getMark("&canuse_qijin") == 0 then
						room:addPlayerMark(p, "&canuse_qijin")
					end
				end
				if player:hasSkill("sp_qijin") and player:getMaxHp() > 1 then
					room:sendCompulsoryTriggerLog(player, "sp_qijin")
					room:broadcastSkillInvoke("sp_qijin")
					room:loseMaxHp(player, 1)
					room:drawCards(player, 1, "sp_qijin")
				end
			end
		elseif event == sgs.MaxHpChanged then
			local m = player:getMaxHp()
			local n = player:getMark("sp_qichuMHP")
			if n > 0 then --粗略判断是否为SP神赵云
				if m < n then
					if player:hasSkill("sp_qijin") then
						room:addPlayerMark(player, "sp_qichuMHP_reduse") --记录SP神赵云体力上限减少的次数
					end
					room:removePlayerMark(player, "sp_qichuMHP", n-m)
				elseif m > n then
					room:addPlayerMark(player, "sp_qichuMHP", m-n)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&canuse_qijin") > 0 then
						local m = p:getMark("&canuse_qijin")
						room:removePlayerMark(p, "&canuse_qijin", m)
					end
				end
				if player:hasSkill("sp_qijin") and player:getMaxHp() > 1 then
					room:sendCompulsoryTriggerLog(player, "sp_qijin")
					room:broadcastSkillInvoke("sp_qijin")
					room:loseMaxHp(player, 1)
					local n = player:getMark("sp_qichuMHP_reduse")
					if n > 4 then n = 4 end
					room:drawCards(player, n, "sp_qijin")
				end
            end
        end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
sp_qijin:setGuhuoDialog("lr")
sp_shenzhaoyun:addSkill(sp_qijin)
sp_shenzhaoyun:addSkill(sp_qijinKey)
extension:insertRelatedSkills("sp_qijin", "#sp_qijinKey")

sp_qichu = sgs.CreateTriggerSkill{
	name = "sp_qichu",
	frequency = sgs.Skill_Wake,
	waked_skills = "sp_danqi,sp_gudan,sp_lingyun",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start and player:getPhase() ~= sgs.Player_Finish then return false end
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMaxHp() ~= 1 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("sp_qichuAnimate")
			if player:hasSkill("sp_qijin") then
				room:detachSkillFromPlayer(player, "sp_qijin")
				room:removePlayerMark(player, "&canuse_qijin")
			end
			local n = player:getMark("sp_qichuMHP_Start")
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(n))
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
			room:acquireSkill(player, "sp_danqi")
			room:addPlayerMark(player, "&canuse_danqi")
			room:acquireSkill(player, "sp_gudan")
			room:acquireSkill(player, "sp_lingyun")
			room:addPlayerMark(player, self:objectName())
			room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
		end
	end,
}
sp_shenzhaoyun:addSkill(sp_qichu)

--“单骑”
sp_danqi = sgs.CreateViewAsSkill{
	name = "sp_danqi",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if (#selected > 0) and sgs.Self:getMaxHp() <= 1 and sgs.Self:getMark("@sp_lingyunAI") > 0 then return false end
		if (#selected > 0) and sgs.Self:getMaxHp() <= 2 and sgs.Self:getMark("@sp_lingyunAI") > 0 and sgs.Self:getMark("&canuse_danqi") == 0 then return false end
		if (#selected > 1) or to_select:hasFlag("using") then return false end
		if #selected > 0 then
			if selected[1]:isKindOf("Slash") then
				return to_select:isKindOf("Slash")
			elseif selected[1]:isKindOf("Jink") then
				return to_select:isKindOf("Jink")
			elseif selected[1]:isKindOf("Peach") then
				return to_select:isKindOf("Peach")
			elseif selected[1]:isKindOf("Analeptic") then
				return to_select:isKindOf("Analeptic")
			end
		end
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return to_select:isKindOf("Jink") or to_select:isKindOf("Peach") or to_select:isKindOf("Analeptic")
		elseif usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return to_select:isKindOf("Analeptic")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			elseif string.find(pattern, "peach") then
				return to_select:isKindOf("Jink") or to_select:isKindOf("Peach")
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 and #cards ~= 2 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:isKindOf("Slash") then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Jink") then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Peach") then
			new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Analeptic") then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			if #cards == 1 then
				new_card:setSkillName(self:objectName())
			else
				new_card:setSkillName("sp_danqi_buffs")
			end
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, target)
		local newana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		return not target:hasFlag("sp_danqiCardUsedTwice") and not (target:getMark("&canuse_danqi") == 0 and not target:hasSkill("sp_lingyun")) and not (target:getMark("&canuse_danqi") == 0 and target:getMark("@sp_lingyunAI") > 0 and target:getMaxHp() <= 1)
		and (target:isWounded() or sgs.Slash_IsAvailable(target) or target:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, target, newana))
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "slash" or pattern == "jink" or (string.find(pattern, "peach") and not target:hasFlag("Global_PreventPeach")) or string.find(pattern, "analeptic")
	end,
}
sp_danqi_buffs = sgs.CreateTriggerSkill{
    name = "#sp_danqi_buffs",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:findPlayersBySkillName("sp_danqi")) do
					if p:getMark("&canuse_danqi") == 0 then
						room:addPlayerMark(p, "&canuse_danqi")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&canuse_danqi") > 0 then
						local n = p:getMark("&canuse_danqi")
						room:removePlayerMark(p, "&canuse_danqi", n)
					end
					if p:hasFlag("sp_danqiCardUsedTwice") then
						room:setPlayerFlag(p, "-sp_danqiCardUsedTwice")
					end
					local s = p:getMark("sp_danqi_SlashBuff")
					local a = p:getMark("sp_danqi_AnalepticBuff")
					if s > 0 then room:removePlayerMark(p, "sp_danqi_SlashBuff", s) end
					if a > 0 then room:removePlayerMark(p, "sp_danqi_AnalepticBuff", a) end
				end
            end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card then
				if (table.contains(card:getSkillNames(), "sp_danqi") or table.contains(card:getSkillNames(), "sp_danqi_buffs")) and player:getMark("&canuse_danqi") == 0 then
					room:loseMaxHp(player, 1) --发动“凌云”额外使用一次，但减体力上限
					room:setPlayerFlag(player, "sp_danqiCardUsedTwice")
				end
				if player:hasSkill("sp_lingyun") and table.contains(card:getSkillNames(), "sp_danqi_buffs") then
					room:sendCompulsoryTriggerLog(player, "sp_lingyun")
					room:broadcastSkillInvoke("sp_lingyun")
					room:loseMaxHp(player, 1)
				end
				--【闪】--
				if card:isKindOf("Jink") and (table.contains(card:getSkillNames(), "sp_danqi") or table.contains(card:getSkillNames(), "sp_danqi_buffs")) then
					room:removePlayerMark(player, "&canuse_danqi")
					local target
					if event == sgs.CardResponded then
						target = data:toCardResponse().m_who
					elseif event == sgs.CardUsed then
						target = data:toCardUse().who
					end
					if not target then return false end
					local dest = sgs.QVariant()
					dest:setValue(target)
					if player:canDisCard(target, "he") and room:askForSkillInvoke(player, "sp_danqi_jink", dest) then
						local discards = sgs.IntList()

						local all = target:getCards("he"):length()
						local max = math.min(card:subcardsLength(), target:getCards("he"):length())
						
						for i = 1, max do--进行多次执行
							local id = room:askForCardChosen(player, target, "he", "sp_danqi",
								false,--选择卡牌时手牌不可见
								sgs.Card_MethodDiscard,--设置为弃置类型
								discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
								i>1)--只有执行过一次选择才可取消
							if id < 0 then break end--如果卡牌id无效就结束多次执行
							discards:append(id)--将选择的id添加到虚拟卡的子卡表
						end
						if discards:length() > 0 then
							local id = room:askForCardChosen(player, target, "he", "sp_lingyun",
								false,--选择卡牌时手牌不可见
								sgs.Card_MethodDiscard,--设置为弃置类型
								discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
								true)
							if id > 0 then 
								discards:append(id)--将选择的id添加到虚拟卡的子卡表
								room:sendCompulsoryTriggerLog(player, "sp_lingyun")
								room:broadcastSkillInvoke("sp_lingyun")
								room:loseMaxHp(player, 1)
							end

							room:broadcastSkillInvoke("sp_danqi")
							room:throwCard(discards, "sp_danqi", target, player)
						end
					end
				
					
				--【桃】--
				elseif card:isKindOf("Peach") and (table.contains(card:getSkillNames(), "sp_danqi") or table.contains(card:getSkillNames(), "sp_danqi_buffs")) and data:toCardUse().to then
					room:removePlayerMark(player, "&canuse_danqi")
					local choicesP = {}
					if card:getSkillName() ~= "sp_danqi_buffs" then
						table.insert(choicesP, "peach1")
					end
					if not (table.contains(card:getSkillNames(), "sp_danqi") and not player:hasSkill("sp_lingyun")) and not (table.contains(card:getSkillNames(), "sp_danqi") and player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesP, "peach2")
					end
					if player:hasSkill("sp_lingyun") and table.contains(card:getSkillNames(), "sp_danqi_buffs") and not (player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesP, "peach3")
					end
					table.insert(choicesP, "cancel")
					local choiceP = room:askForChoice(player, "sp_danqi", table.concat(choicesP, "+"), data)
					if choiceP == "peach1" then
						room:broadcastSkillInvoke("sp_danqi")
						for _, p in sgs.qlist(data:toCardUse().to) do
							room:drawCards(p, 1, self:objectName())
						end
					elseif choiceP == "peach2" then
						room:broadcastSkillInvoke("sp_danqi")
						if table.contains(card:getSkillNames(), "sp_danqi") then
							room:sendCompulsoryTriggerLog(player, "sp_lingyun")
							room:broadcastSkillInvoke("sp_lingyun")
							room:loseMaxHp(player, 1)
						end
						for _, p in sgs.qlist(data:toCardUse().to) do
							room:drawCards(p, 2, self:objectName())
						end
					elseif choiceP == "peach3" then
						room:broadcastSkillInvoke("sp_danqi")
						room:sendCompulsoryTriggerLog(player, "sp_lingyun")
						room:broadcastSkillInvoke("sp_lingyun")
						room:loseMaxHp(player, 1)
						for _, p in sgs.qlist(data:toCardUse().to) do
							room:drawCards(p, 3, self:objectName())
						end
					end
				--【酒】--
				elseif card:isKindOf("Analeptic") and (table.contains(card:getSkillNames(), "sp_danqi") or table.contains(card:getSkillNames(), "sp_danqi_buffs")) then
					room:removePlayerMark(player, "&canuse_danqi")
					local choicesA = {}
					if not (table.contains(card:getSkillNames(), "sp_danqi") and not player:hasSkill("sp_lingyun")) and not (table.contains(card:getSkillNames(), "sp_danqi") and player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesA, "analeptic1")
					end
					if player:hasSkill("sp_lingyun") and table.contains(card:getSkillNames(), "sp_danqi_buffs") and not (player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesA, "analeptic2")
					end
					table.insert(choicesA, "cancel")
					local choiceA = room:askForChoice(player, "sp_danqi", table.concat(choicesA, "+"), data)
					if choiceA == "analeptic1" then
						room:broadcastSkillInvoke("sp_danqi")
						if table.contains(card:getSkillNames(), "sp_danqi") then
							room:sendCompulsoryTriggerLog(player, "sp_lingyun")
							room:broadcastSkillInvoke("sp_lingyun")
							room:loseMaxHp(player, 1)
						end
						room:addPlayerMark(player, "sp_danqi_AnalepticBuff", 1)
						local log = sgs.LogMessage()
						log.type = "$sp_danqi_AnalepticADD"
						log.from = player
						log.card_str = card:toString()
						log.arg2 = 1
						room:sendLog(log)
					elseif choiceA == "analeptic2" then
						room:broadcastSkillInvoke("sp_danqi")
						room:sendCompulsoryTriggerLog(player, "sp_lingyun")
						room:broadcastSkillInvoke("sp_lingyun")
						room:loseMaxHp(player, 1)
						room:addPlayerMark(player, "sp_danqi_AnalepticBuff", 2)
						local log = sgs.LogMessage()
						log.type = "$sp_danqi_AnalepticADD"
						log.from = player
						log.card_str = card:toString()
						log.arg2 = 2
						room:sendLog(log)
					end
				--【杀】--
				elseif card:isKindOf("Slash") and (table.contains(card:getSkillNames(), "sp_danqi") or table.contains(card:getSkillNames(), "sp_danqi_buffs")) then
					player:setFlags("sp_danqiSlashfrom")
					for _, p in sgs.qlist(data:toCardUse().to) do
						p:setFlags("sp_danqiSlashto")
						room:addPlayerMark(p, "Armor_Nullified")
					end
					room:removePlayerMark(player, "&canuse_danqi")
					local choicesS = {}
					if not (table.contains(card:getSkillNames(), "sp_danqi") and not player:hasSkill("sp_lingyun")) and not (table.contains(card:getSkillNames(), "sp_danqi") and player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesS, "slash1")
					end
					if player:hasSkill("sp_lingyun") and table.contains(card:getSkillNames(), "sp_danqi_buffs") and not (player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
						table.insert(choicesS, "slash2")
					end
					table.insert(choicesS, "cancel")
					local choiceS = room:askForChoice(player, "sp_danqi", table.concat(choicesS, "+"), data)
					if choiceS ~= "cancel" then room:setCardFlag(card, "sp_danqi") end
					if choiceS == "slash1" then
						room:broadcastSkillInvoke("sp_danqi")
						if table.contains(card:getSkillNames(), "sp_danqi") then
							room:sendCompulsoryTriggerLog(player, "sp_lingyun")
							room:broadcastSkillInvoke("sp_lingyun")
							room:loseMaxHp(player, 1)
						end
						room:addPlayerMark(player, "sp_danqi_SlashBuff", 1)
						local log = sgs.LogMessage()
						log.type = "$sp_danqi_SlashADD"
						log.from = player
						log.card_str = card:toString()
						log.arg2 = 1
						room:sendLog(log)
					elseif choiceS == "slash2" then
						room:broadcastSkillInvoke("sp_danqi")
						room:sendCompulsoryTriggerLog(player, "sp_lingyun")
						room:broadcastSkillInvoke("sp_lingyun")
						room:loseMaxHp(player, 1)
						room:addPlayerMark(player, "sp_danqi_SlashBuff", 2)
						local log = sgs.LogMessage()
						log.type = "$sp_danqi_SlashADD"
						log.from = player
						log.card_str = card:toString()
						log.arg2 = 2
						room:sendLog(log)
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				local s = player:getMark("sp_danqi_SlashBuff")
				local a = player:getMark("sp_danqi_AnalepticBuff")
				if s > 0 then
					local log = sgs.LogMessage()
					log.type = "$sp_danqi_SlashDMG"
					log.from = player
					log.to:append(damage.to)
					log.card_str = damage.card:toString()
					log.arg2 = s
					room:sendLog(log)
				end
				if damage.card:hasFlag("drank") then
					damage.damage = damage.damage + a
				end
				if damage.card:hasFlag("sp_danqi") then
					damage.damage = damage.damage + s
				end
				data:setValue(damage)
				room:removePlayerMark(player, "sp_danqi_SlashBuff", s)
				room:removePlayerMark(player, "sp_danqi_AnalepticBuff", a)
			end
        elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasFlag("sp_danqiSlashfrom") and (table.contains(use.card:getSkillNames(), "sp_danqi") or table.contains(use.card:getSkillNames(), "sp_danqi_buffs")) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("sp_danqiSlashto") then
						p:setFlags("-sp_danqiSlashto")
						if p:getMark("Armor_Nullified") then
							room:removePlayerMark(p, "Armor_Nullified")
						end
					end
				end
				player:setFlags("-sp_danqiSlashfrom")
			end
			if use.card:isKindOf("Slash") then
				local s = player:getMark("sp_danqi_SlashBuff")
				local a = player:getMark("sp_danqi_AnalepticBuff")
				if s > 0 then room:removePlayerMark(player, "sp_danqi_SlashBuff", s) end
				if a > 0 then room:removePlayerMark(player, "sp_danqi_AnalepticBuff", a) end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
if not sgs.Sanguosha:getSkill("sp_danqi") then skills:append(sp_danqi) end
if not sgs.Sanguosha:getSkill("sp_danqi_buffs") then skills:append(sp_danqi_buffs) end
extension:insertRelatedSkills("sp_danqi", "#sp_danqi_buffs")
--“孤胆”
sp_gudanCard = sgs.CreateSkillCard{
    name = "sp_gudanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		targets[1]:obtainCard(self, false)
	end,
}
sp_gudanVS = sgs.CreateViewAsSkill{
    name = "sp_gudan",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return true
	end,
	view_as = function(self, cards)
	    if #cards == 1 then
			local gd_card = sp_gudanCard:clone()
			gd_card:addSubcard(cards[1])
			return gd_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@sp_gudan")
	end,
}
sp_gudan = sgs.CreateTriggerSkill{
    name = "sp_gudan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	view_as_skill = sp_gudanVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local choices = {}
		table.insert(choices, "1and0")
		if player:hasSkill("sp_lingyun") and not (player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 1) then
			table.insert(choices, "1and1")
			table.insert(choices, "2and0")
		end
		if player:hasSkill("sp_lingyun") and not (player:getMark("@sp_lingyunAI") > 0 and player:getMaxHp() <= 2) then
			table.insert(choices, "2and1")
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
		if choice == "1and0" then
			room:broadcastSkillInvoke(self:objectName())
			room:drawCards(player, 1, self:objectName())
		elseif choice == "1and1" then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, "sp_lingyun")
			room:broadcastSkillInvoke("sp_lingyun")
			room:loseMaxHp(player, 1)
			room:drawCards(player, 1, self:objectName())
			room:askForUseCard(player, "@@sp_gudan!", "@sp_gudan-card")
		elseif choice == "2and0" then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, "sp_lingyun")
			room:broadcastSkillInvoke("sp_lingyun")
			room:loseMaxHp(player, 1)
			room:drawCards(player, 2, self:objectName())
		elseif choice == "2and1" then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, "sp_lingyun")
			room:broadcastSkillInvoke("sp_lingyun")
			room:loseMaxHp(player, 2)
			room:drawCards(player, 2, self:objectName())
			room:askForUseCard(player, "@@sp_gudan!", "@sp_gudan-card")
		end
	end,
}
if not sgs.Sanguosha:getSkill("sp_gudan") then skills:append(sp_gudan) end
--“凌云”（主体部分已写在“单骑”与“孤胆”中，该部分为智能操作的切换）
sp_lingyunCard = sgs.CreateSkillCard{
	name = "sp_lingyunCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if source:getMark("@sp_lingyunAI") > 0 then
			room:removePlayerMark(source, "@sp_lingyunAI")
		else
			room:addPlayerMark(source, "@sp_lingyunAI")
		end
	end,
}
sp_lingyun = sgs.CreateZeroCardViewAsSkill{
	name = "sp_lingyun",
	view_as = function()
		return sp_lingyunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}
if not sgs.Sanguosha:getSkill("sp_lingyun") then skills:append(sp_lingyun) end


--

--26 暗神·司马
sp_shensima = sgs.General(extension_G, "sp_shensima", "god", 1, true)

sp_zhuangbing = sgs.CreateTriggerSkill{
    name = "sp_zhuangbing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Appear},
	hide_skill = true, --隐匿技
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local current = room:getCurrent()
		if current:objectName() == player:objectName() then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
		    room:broadcastSkillInvoke(self:objectName())
			room:setPlayerFlag(current, "sp_zhuangbingTarget")
			room:setPlayerCardLimitation(current, "use,response", ".|.|.|hand", false)
		end
	end,
}
sp_zhuangbingg = sgs.CreateTriggerSkill{
    name = "#sp_zhuangbingg",
	priority = 4,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Appear, sgs.EventPhaseChanging, sgs.TurnedOver, sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.DamageInflicted, sgs.PreHpLost},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.Appear and player:hasSkill("sp_zhuangbing") then
			room:sendCompulsoryTriggerLog(player, "sp_zhuangbing")
			room:broadcastSkillInvoke("sp_zhuangbing")
			player:turnOver()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("sp_zhuangbingTarget") then
						room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
						room:setPlayerFlag(p, "sp_zhuangbingTarget")
					end
				end
            end
		elseif event == sgs.TurnedOver and player:hasSkill("sp_zhuangbing") then
			if not player:faceUp() then
				room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false)
			else
				room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand")
			end
		elseif event == sgs.EventLoseSkill then --若期间失去“装病”，武将牌为背面时的效果不再生效
			if data:toString() == "sp_zhuangbing" then
				if not player:faceUp() then
					room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand")
					room:addPlayerMark(player, "sp_zhuangbingLose") --“防伪”标记
				end
			end
		elseif event == sgs.EventAcquireSkill then --若期间重新获得“装病”，武将牌为背面时的效果再度生效
			if data:toString() == "sp_zhuangbing" and player:getMark("sp_zhuangbingLose") > 0 then
				if not player:faceUp() then
					room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false)
					room:removePlayerMark(player, "sp_zhuangbingLose")
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:hasSkill("sp_zhuangbing") and not player:faceUp() then
				room:sendCompulsoryTriggerLog(player, "sp_zhuangbing")
				room:broadcastSkillInvoke("sp_zhuangbing")
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		--[[elseif event == sgs.PreHpLost then local int = data:toInt()
			if player:hasSkill("sp_zhuangbing") and not player:faceUp() then
				room:sendCompulsoryTriggerLog(player, "sp_zhuangbing")
				room:broadcastSkillInvoke("sp_zhuangbing")
				return true
			end]]
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_shensima:addSkill(sp_zhuangbing)
sp_shensima:addSkill(sp_zhuangbingg)
extension:insertRelatedSkills("sp_zhuangbing", "#sp_zhuangbingg")


sp_xiongxin = sgs.CreateTriggerSkill{
	name = "sp_xiongxin",
	priority = 5,
	frequency = sgs.Skill_Wake,
	waked_skills = "sp_yinren,sp_shenmou,sp_yinyang",
	events = {sgs.TurnedOver},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:faceUp() or player:canWake(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("sp_shensima", self:objectName())
			room:changeMaxHpForAwakenSkill(player, 3, self:objectName())
			room:recover(player, sgs.RecoverStruct(player, nil, 3))
			room:drawCards(player, 3, self:objectName())
			room:acquireSkill(player, "sp_yinren")
			room:acquireSkill(player, "sp_shenmou")
			room:acquireSkill(player, "sp_yinyang")
			room:addPlayerMark(player, self:objectName())
		end
	end,
}
sp_shensima:addSkill(sp_xiongxin)
--“隐忍”
sp_yinren = sgs.CreateTriggerSkill{
    name = "sp_yinren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
		    	room:broadcastSkillInvoke(self:objectName())
				local hc = player:getHandcardNum()
	            local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		        if card_id then
				    card_id:deleteLater()
			        card_id = room:askForExchange(player, self:objectName(), hc, hc, false, "")
		        end
		        player:addToPile(self:objectName(), card_id, false)
				player:turnOver()
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("sp_yinren") then skills:append(sp_yinren) end
--“深谋”
sp_shenmouCard = sgs.CreateSkillCard{
	name = "sp_shenmouCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local cards = room:getNCards(3)
		local right = cards
		local tricks = sgs.IntList()
		local non_tricks = sgs.IntList()
		for _, card_id in sgs.qlist(cards) do
			local card = sgs.Sanguosha:getCard(card_id)
			if card:isKindOf("TrickCard") then
				tricks:append(card_id)
			else
				non_tricks:append(card_id)
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		if not tricks:isEmpty() then
			room:fillAG(right, source, non_tricks)
			local id1 = room:askForAG(source, tricks, true, "sp_shenmou")
			tricks:removeOne(id1)
			right:removeOne(id1)
			dummy:addSubcard(id1)
		end
		room:clearAG(source)
		if dummy:subcardsLength() > 0 then
			source:obtainCard(dummy, false)
		end
		room:askForGuanxing(source, right, sgs.Room_GuanxingUpOnly)
	end,
}
sp_shenmou = sgs.CreateZeroCardViewAsSkill{
	name = "sp_shenmou",
	view_as = function()
		return sp_shenmouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sp_shenmouCard")
	end,
}
if not sgs.Sanguosha:getSkill("sp_shenmou") then skills:append(sp_shenmou) end
--“阴养”
sp_yinyang = sgs.CreateTriggerSkill{
    name = "sp_yinyang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local ss = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local id = room:askForCardChosen(player, ss, "he", self:objectName())
				ss:addToPile("sp_ss", id, false)
				if not ss:hasSkill("sp_sishi") then
					room:attachSkillToPlayer(ss, "sp_sishi") --给目标角色可以执行【出牌阶段可以失去1点体力并获得所有“死士”牌】的技能按钮（在其武将头像左上方）
				end
			end
				
		end
	end,
}
sp_yinyangSSJQ = sgs.CreateTriggerSkill{
	name = "sp_yinyangSSJQ",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		room:loseHp(damage.to, damage.damage, true, damage.from, self:objectName())
		return true
	end,
	can_trigger = function(self, player)
		return player and player:getPile("sp_ss"):length() > 0
	end,
}
  --“死士”技能按钮（出牌阶段可以失去1点体力并获得所有“死士”牌）
sp_sishiCard = sgs.CreateSkillCard{
	name = "sp_sishiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1, true, source, "sp_sishi")
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(source:getPile("sp_ss"))
		room:obtainCard(source, dummy, false)
		dummy:deleteLater()
		room:detachSkillFromPlayer(source, "sp_sishi", true)
	end,
}
sp_sishi = sgs.CreateZeroCardViewAsSkill{
	name = "sp_sishi&",
	view_as = function()
		return sp_sishiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getPile("sp_ss"):length() > 0
	end,
}
if not sgs.Sanguosha:getSkill("sp_yinyang") then skills:append(sp_yinyang) end
if not sgs.Sanguosha:getSkill("sp_yinyangSSJQ") then skills:append(sp_yinyangSSJQ) end
if not sgs.Sanguosha:getSkill("sp_sishi") then skills:append(sp_sishi) end

sp_zhengbianCard = sgs.CreateSkillCard{
	name = "sp_zhengbianCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@sp_zhengbian")
		room:doSuperLightbox("sp_shensima", "sp_zhengbian")
		if source:hasSkill("sp_zhuangbing") then
			room:detachSkillFromPlayer(source, "sp_zhuangbing")
		end
		if source:hasSkill("sp_yinren") then
			room:detachSkillFromPlayer(source, "sp_yinren", false, true)
		end
		if source:hasSkill("sp_shenmou") then
			room:detachSkillFromPlayer(source, "sp_shenmou", false, true)
		end
		if source:hasSkill("sp_yinyang") then
			room:detachSkillFromPlayer(source, "sp_yinyang", false, true)
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(source:getPile("sp_yinren"))
		local x = source:getPile("sp_yinren"):length()
		room:obtainCard(source, dummy, false)
		dummy:deleteLater()
		room:addPlayerMark(source, "&sp_zhengbian", x)
		room:setPlayerFlag(source, "sp_zhengbianTurn")
		local count = source:getMaxHp()
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(count+x))
		local caoshuang = room:askForPlayerChosen(source, room:getOtherPlayers(source), "sp_zhengbian", "sp_zhengbianToDo")
		room:broadcastSkillInvoke("sp_zhengbian")
		room:addPlayerMark(caoshuang, "&sp_zhengbianTarget")
	end,
}
sp_zhengbianVS = sgs.CreateZeroCardViewAsSkill{
	name = "sp_zhengbian",
	view_as = function()
		return sp_zhengbianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sp_zhengbian") > 0
	end,
}
sp_zhengbian = sgs.CreateTriggerSkill{
	name = "sp_zhengbian",
	frequency = sgs.Skill_Limited,
	waked_skills = "sp_kongju",
	limit_mark = "@sp_zhengbian",
	view_as_skill = sp_zhengbianVS,
	on_trigger = function()
	end,
}
sp_zhengbianBuff_distance = sgs.CreateDistanceSkill{
	name = "#sp_zhengbianBuff_distance",
	correct_func = function(self, from, to)
		if from:hasSkill("sp_zhengbian") and from:hasFlag("sp_zhengbianTurn") and to and to:getMark("&sp_zhengbianTarget") > 0 then
			local n = from:getMark("&sp_zhengbian")
			return -n
		else
			return 0
		end
	end,
}
sp_zhengbianBuff_slashmore = sgs.CreateTargetModSkill{
	name = "#sp_zhengbianBuff_slashmore",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, from, card, to)
		if from:hasSkill("sp_zhengbian") and from:hasFlag("sp_zhengbianTurn") and card:isKindOf("Slash") and to and to:getMark("&sp_zhengbianTarget") > 0 then
			local n = from:getMark("&sp_zhengbian")
			return n
		else
			return 0
		end
	end,
}
sp_zhengbianClear = sgs.CreateTriggerSkill{
	name = "#sp_zhengbianClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&sp_zhengbianTarget") > 0 then
					local n = p:getMark("&sp_zhengbianTarget")
					room:removePlayerMark(p, "&sp_zhengbianTarget", n)
				end
			end
			for _, q in sgs.qlist(room:getAllPlayers()) do
				if q:hasFlag("sp_zhengbianTurn") then
					room:setPlayerFlag(q, "-sp_zhengbianTurn")
					if q:hasSkill("sp_zhengbian") then
						room:sendCompulsoryTriggerLog(q, "sp_zhengbian")
						room:broadcastSkillInvoke("sp_zhengbian")
						room:acquireSkill(q, "sp_kongju")
						q:gainAnExtraTurn()
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
sp_shensima:addSkill(sp_zhengbian)
sp_shensima:addSkill(sp_zhengbianBuff_distance)
sp_shensima:addSkill(sp_zhengbianBuff_slashmore)
sp_shensima:addSkill(sp_zhengbianClear)
extension:insertRelatedSkills("sp_zhengbian", "#sp_zhengbianBuff_distance")
extension:insertRelatedSkills("sp_zhengbian", "#sp_zhengbianBuff_slashmore")
extension:insertRelatedSkills("sp_zhengbian", "#sp_zhengbianClear")

--“控局”
sp_kongjuCard = sgs.CreateSkillCard{
	name = "sp_kongjuCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local plist = room:getAllPlayers()
		local choice = room:askForChoice(source, "sp_kongju", "lose1MaxHptochosetodo+randomtodo")
		local choicees = {}
		table.insert(choicees, "one")
		table.insert(choicees, "two")
		if source:hasEquipArea() then
			table.insert(choicees, "three")
		end
		table.insert(choicees, "fail")
		local choicee
		if choice == "lose1MaxHptochosetodo" then
		    room:loseMaxHp(source, 1)
			choicee = room:askForChoice(source, "sp_kongju", table.concat(choicees, "+"))
		else
			local items = choicees
			local n = math.random(1,4)
			choicee = items[n]
		end
		local fail = false
		room:setTag("sp_kongju_choose", ToData(choicee))
		if choicee == "one" then
			local can_invoke = false
			for _, p in sgs.qlist(plist) do
				if p:getEquips():length() > 0 or p:getJudgingArea():length() > 0 then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local from = room:askForPlayerChosen(source, plist, "sp_kongju", "sp_kongjuOne")
				if from:getEquips():length() == 0 and from:getJudgingArea():length() == 0 then return false end
				local card_id = room:askForCardChosen(source, from, "ej", "sp_kongju")
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local equip_index = -1
				if place == sgs.Player_PlaceEquip then
					local equip = card:getRealCard():toEquipCard()
					equip_index = equip:location()
				end
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _, p in sgs.qlist(list) do
					if equip_index ~= -1 then
						if not p:getEquip(equip_index) then
							tos:append(p)
						end
					else
						if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							tos:append(p)
						end
					end
				end
				local tag = sgs.QVariant()
				tag:setValue(from)
				room:setTag("sp_kongjuOneTarget", tag)
				local to = room:askForPlayerChosen(source, tos, "sp_kongju", "@sp_kongjuOne-to:" .. card:objectName())
				if to then
					room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), "sp_kongju", ""))
				end
				room:removeTag("sp_kongjuOneTarget")
			else
				fail = true
			end
		elseif choicee == "two" then
			local can_invoke = false
			for _, p in sgs.qlist(plist) do
				if not p:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local from = room:askForPlayerChosen(source, plist, "sp_kongju", "sp_kongjuTwoF")
				if from:isKongcheng() then return false end
				local card = room:askForCardChosen(source, from, "h", "sp_kongju")
				local plistTwo = room:getOtherPlayers(from)
				local tag = sgs.QVariant()
				tag:setValue(from)
				room:setTag("sp_kongjuOneTarget", tag)
				local to = room:askForPlayerChosen(source, plistTwo, "sp_kongju", "sp_kongjuTwoT")
				room:obtainCard(to, card, false)
				room:removeTag("sp_kongjuOneTarget")
			else
				fail = true
			end
		elseif choicee == "three" then
			local can_invoke = false
			if source:hasEquipArea() then can_invoke = true end
			if can_invoke then
				-- local choices = {}
				-- for i = 0, 4 do
				-- 	if source:hasEquipArea(i) then
				-- 		table.insert(choices, i)
				-- 	end
				-- end
				-- if choices == "" then return false end
				-- local choiceee = room:askForChoice(source, "sp_kongju", table.concat(choices, "+"))
				-- local area = tonumber(choiceee), 0
				-- source:throwEquipArea(area)
				ThrowEquipArea(self,source,nil,nil)
				local dmd = room:askForPlayerChosen(source, plist, "sp_kongju", "sp_kongjuThree")
				dmd:throwAllMarks(true)
			else
				fail = true
			end
		elseif choicee == "fail" then
			fail = true
		end
		room:removeTag("sp_kongju_choose")
		if fail then
			local log = sgs.LogMessage()
			log.type = "$sp_kongjuFail"
			log.from = source
			room:sendLog(log)
			room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
		end
	end,
}
sp_kongju = sgs.CreateZeroCardViewAsSkill{
	name = "sp_kongju",
	view_as = function()
		return sp_kongjuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}
if not sgs.Sanguosha:getSkill("sp_kongju") then skills:append(sp_kongju) end

sp_tuntian = sgs.CreateTriggerSkill{
	name = "sp_tuntian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then
		    local killer
		    if death.damage then
			    killer = death.damage.from
		    else
			    killer = nil
		    end
		    local current = room:getCurrent()
		    if killer:hasSkill(self:objectName()) and (current:isAlive() or current:objectName() == death.who:objectName()) then
				room:sendCompulsoryTriggerLog(killer, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local count = killer:getMaxHp()
				room:setPlayerProperty(killer, "maxhp", sgs.QVariant(count+1))
			end
		end   
	end,
}
sp_shensima:addSkill(sp_tuntian)

--27 剑神·刘备
sp_shenliubei = sgs.General(extension_G, "sp_shenliubei", "god", 3, true)

sp_yingjieCard = sgs.CreateSkillCard{
    name = "sp_yingjieCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    targets[1]:obtainCard(self, false)
	end,
}
sp_yingjieVS = sgs.CreateViewAsSkill{
    name = "sp_yingjie",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return true
	end,
	view_as = function(self, cards)
	    if #cards == 1 then
			local zhangyi_card = sp_yingjieCard:clone()
			zhangyi_card:addSubcard(cards[1])
			return zhangyi_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@sp_yingjie")
	end,
}
sp_yingjie = sgs.CreateTriggerSkill{
	name = "sp_yingjie",
	priority = {3, 2},
	change_skill = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	view_as_skill = sp_yingjieVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		
		local n = player:getChangeSkillState(self:objectName())
		if card and not card:isKindOf("SkillCard") and player:hasSkill(self:objectName()) then
		    if n == 1 then
			    if room:askForSkillInvoke(player, "@sp_yingjie-xingxia", data) then
					local xingxia = room:getAllPlayers()
					local xiongdi = room:askForPlayerChosen(player, xingxia, self:objectName(), "sp_yingjie-invoke")
					room:drawCards(xiongdi, math.random(1,3))
					room:broadcastSkillInvoke(self:objectName())
					room:setChangeSkillState(player, self:objectName(), 2) --切换为“仗义”
				end
			elseif n == 2 then
                if not player:isNude() and room:askForSkillInvoke(player, "@sp_yingjie-zhangyi", data) then
					room:askForUseCard(player, "@@sp_yingjie!", "@sp_yingjie-card")
					local recover = sgs.RecoverStruct()
					recover.recover = math.random(0,1)
					recover.who = player
					room:recover(player, recover)
					room:setChangeSkillState(player, self:objectName(), 1) --切换为“行侠”
				end
			end
		end
	end,
}
sp_shenliubei:addSkill(sp_yingjie)

sp_yuanzhiCard = sgs.CreateSkillCard{
	name = "sp_yuanzhiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "sp_yuanzhi", nil)
		if success then
			room:drawCards(source, 1)
			room:addPlayerMark(source, "&sp_yuanzhiFQC")
			room:addPlayerMark(source, "sp_yuanzhiUF")
		else
			room:addPlayerMark(source, "sp_yuanzhiUF")
			room:addPlayerMark(source, "sp_yuanzhiFail")
			local choice = room:askForChoice(source, "sp_yuanzhi", "1+2")
			if choice == "1" then
				local n = source:getMark("sp_yuanzhiFail")
				if not source:isNude() then
					room:askForDiscard(source, "sp_yuanzhi", n, n, false, true)
				end
				room:removePlayerMark(source, "&sp_yuanzhiFQC")
			elseif choice == "2" then
			    local n = source:getMark("&sp_yuanzhiFQC")
				room:removePlayerMark(source, "&sp_yuanzhiFQC", n)
				room:addPlayerMark(source, "sp_yuanzhiTR", 2) --获得两枚此标记是为了下回合出牌阶段结束重置“远志”次数
			end
		end
	end,
}
sp_yuanzhiVS = sgs.CreateZeroCardViewAsSkill{
	name = "sp_yuanzhi",
	view_as = function()
		return sp_yuanzhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&sp_yuanzhiFQC") > player:getMark("sp_yuanzhiUF") and not player:isKongcheng()
	end,
}
sp_yuanzhi = sgs.CreateTriggerSkill{
    name = "sp_yuanzhi",
	view_as_skill = sp_yuanzhiVS,
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill("sp_rongma") then room:addPlayerMark(player, "sp_rongmaTrigger") end --游戏开始后，才能触发“戎马”
			if player:hasSkill("sp_yuanzhi") then room:addPlayerMark(player, "&sp_yuanzhiFQC") end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("sp_yuanzhiUF") > 0 then
					local n = p:getMark("sp_yuanzhiUF")
					room:removePlayerMark(p, "sp_yuanzhiUF", n)
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
		    if player:getMark("sp_yuanzhiTR") == 1 then
			    room:removePlayerMark(player, "sp_yuanzhiTR")
				if player:getMark("&sp_yuanzhiFQC") > 0 then --保证是让“远志”次数重置为1
					local n = player:getMark("&sp_yuanzhiFQC")
					room:removePlayerMark(player, "&sp_yuanzhiFQC", n)
				end
				room:addPlayerMark(player, "&sp_yuanzhiFQC")
			elseif player:getMark("sp_yuanzhiTR") == 2 then
			    room:removePlayerMark(player, "sp_yuanzhiTR")
				return false
			end
		end
	end,
}
sp_shenliubei:addSkill(sp_yuanzhi)


sp_rongma = sgs.CreateTriggerSkill{
    name = "sp_rongma",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.Damaged, sgs.BeforeCardsMove, sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			room:sendCompulsoryTriggerLog(player, self:objectName())
			player:gainMark("&sp_rongma")
		elseif event == sgs.BeforeCardsMove then
		    local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW and player:getMark("sp_rongmaTrigger") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:gainMark("&sp_rongma")
			end
		else
			local mark = data:toMark()
			if mark.name == "&sp_rongma" and mark.who:hasSkill(self:objectName()) and mark.who:objectName() == player:objectName() then
				if player:getMark("&sp_rongma") >= 10 and player:getMark("sp_rongma10triggered") == 0 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, "&sp_yuanzhiFQC", 2)
					room:addPlayerMark(player, "sp_rongma10triggered")
				end
				if player:getMark("&sp_rongma") >= 20 and player:getMark("sp_rongma20triggered") == 0 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:addPlayerMark(player, "sp_rongma20triggered") --必须写在摸牌前面，否则会无限触发“戎马”直接暴毙
					room:drawCards(player, 3, self:objectName())
				end
				if player:getMark("&sp_rongma") >= 30 and player:getMark("sp_rongma30triggered") == 0 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 3)
					local mhp = player:getMaxHp()
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(mhp+1))
					room:recover(player, sgs.RecoverStruct(player))
					room:addPlayerMark(player, "sp_rongma30triggered")
				end
				
				if player:getMark("&sp_rongma") >= 40 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:killPlayer(player)
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill(self:objectName())
	end,
}
sp_shenliubei:addSkill(sp_rongma)



--

--28 军神·陆逊
sp_shenluxun = sgs.General(extension_G, "sp_shenluxun", "god", 3, true)

sp_zaoyan = sgs.CreateTriggerSkill{
	name = "sp_zaoyan",
	priority = {3, 2},
	change_skill = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.to:length() ~= 1 then return false end
		if use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local n = p:getChangeSkillState(self:objectName())
				if n == 1 and use.card:isRed() and p:getMark("&sp_zaoyanLast") > 0 then
					if p:hasFlag("sp_zaoyan_dontAskMore") then return false end
					if room:askForSkillInvoke(p, "@sp_zaoyan-yang", data) then
						room:setChangeSkillState(p, self:objectName(), 2)
						room:removePlayerMark(p, "&sp_zaoyanLast")
						room:drawCards(p, 1, self:objectName())
						local cardR = room:askForCard(p, ".|red|.|.", "@sp_zaoyan-red", data, self:objectName())
						if cardR then
							for _, to in sgs.qlist(use.to) do
								local nullified_list = use.nullified_list
								table.insert(nullified_list, to:objectName())
								use.nullified_list = nullified_list
								data:setValue(use)
								room:damage(sgs.DamageStruct(self:objectName(), use.from, to, 1, sgs.DamageStruct_Fire))
							end
							room:broadcastSkillInvoke(self:objectName(), 1)
						end
					else
						room:setPlayerFlag(p, "sp_zaoyan_dontAskMore") --防止重复询问
					end
				elseif n == 2 and use.card:isBlack() and p:getMark("&sp_zaoyanLast") > 0 and p:canDiscard(p, "he") then
					if p:hasFlag("sp_zaoyan_dontAskMore") then return false end
					if room:askForSkillInvoke(p, "@sp_zaoyan-yin", data) then
						local cardB = room:askForCard(p, ".|black|.|.", "@sp_zaoyan-black", data, self:objectName())
						if cardB then
							room:setChangeSkillState(p, self:objectName(), 1)
							room:removePlayerMark(p, "&sp_zaoyanLast")
							room:drawCards(p, 1, self:objectName())
							for _, to in sgs.qlist(use.to) do
								local nullified_list = use.nullified_list
								table.insert(nullified_list, to:objectName())
								use.nullified_list = nullified_list
								data:setValue(use)
								room:loseHp(to, 1, true, p, self:objectName())
							end
							room:broadcastSkillInvoke(self:objectName(), 2)
						end
					else
						room:setPlayerFlag(p, "sp_zaoyan_dontAskMore")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_zaoyanClear = sgs.CreateTriggerSkill{
    name = "#sp_zaoyanClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("sp_zaoyan_dontAskMore") then
				room:setPlayerFlag(p, "-sp_zaoyan_dontAskMore")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_zaoyanTime = sgs.CreateTriggerSkill{
    name = "#sp_zaoyanTime",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.GameStart then
		    if player:hasSkill("sp_zaoyan") then
				room:sendCompulsoryTriggerLog(player, "sp_zaoyan")
				room:broadcastSkillInvoke("sp_zaoyan", 3)
				room:addPlayerMark(player, "&sp_zaoyanLast")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName("sp_zaoyan")) do
					if p:getMark("&sp_zaoyanLast") < 4 then
						room:sendCompulsoryTriggerLog(p, "sp_zaoyan")
						room:broadcastSkillInvoke("sp_zaoyan", 3)
						room:addPlayerMark(p, "&sp_zaoyanLast")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
sp_shenluxun:addSkill(sp_zaoyan)
sp_shenluxun:addSkill(sp_zaoyanClear)
sp_shenluxun:addSkill(sp_zaoyanTime)
extension:insertRelatedSkills("sp_zaoyan", "#sp_zaoyanClear")
extension:insertRelatedSkills("sp_zaoyan", "#sp_zaoyanTime")


sp_fenyingCard = sgs.CreateSkillCard{
	name = "sp_fenyingCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    return #targets < self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@sp_fenying")
		room:doSuperLightbox("sp_shenluxun", "sp_fenying")
		for _, sj in ipairs(targets) do
			room:setPlayerChained(sj)
		end
	end,
}
sp_fenyingVS = sgs.CreateViewAsSkill{
	name = "sp_fenying",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	    local card = sp_fenyingCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sp_fenying") > 0 and player:hasFlag("sp_fenying_CanUse")
	end,
	response_pattern = "@@sp_fenying",
}
sp_fenying = sgs.CreateTriggerSkill{
	name = "sp_fenying",
	--global = true,
	frequency = sgs.Skill_Limited,
	limit_mark = "@sp_fenying",
	view_as_skill = sp_fenyingVS,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Fire then return false end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:getMark("@sp_fenying") > 0 then
				room:setPlayerFlag(p, "sp_fenying_CanUse")
				room:setTag("sp_fenying", data)
				if not room:askForUseCard(p, "@@sp_fenying", "@sp_fenying-card") then
					room:setPlayerFlag(p, "-sp_fenying_CanUse")
				else
					local ly = damage.damage
					if p:getEquips():length() >= ly and p:canDiscard(p, "e") then
						if p:getEquips():length() == ly then
							p:throwAllEquips()
						else
							local ec1 = room:askForCardChosen(p, p, "e", self:objectName())
							room:throwCard(ec1, p, p)
							if ly >= 2 then
								local ec2 = room:askForCardChosen(p, p, "e", self:objectName())
								room:throwCard(ec2, p, p)
							end
							if ly >= 3 then
								local ec3 = room:askForCardChosen(p, p, "e", self:objectName())
								room:throwCard(ec3, p, p)
							end
							if ly >= 4 then
								local ec4 = room:askForCardChosen(p, p, "e", self:objectName())
								room:throwCard(ec4, p, p)
							end
						end
						damage.damage = ly*2
						local log = sgs.LogMessage()
						log.type = "$sp_fenyingDMG"
						log.from = p
						log.to:append(damage.to)
						log.arg = ly
						log.arg2 = damage.damage
						room:sendLog(log)
						data:setValue(damage)
						room:broadcastSkillInvoke(self:objectName())
					end
					local n = p:getMark("&sp_zaoyanLast")
					if n > 0 then
						room:removePlayerMark(p, "&sp_zaoyanLast", n)
						room:drawCards(p, n, self:objectName())
					end
				end
				room:removeTag("sp_fenying")
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
sp_shenluxun:addSkill(sp_fenying)

--29 孤神·张辽
sp_shenzhangliao = sgs.General(extension_G, "sp_shenzhangliao", "god", 4, true)

sp_qiangxiCard = sgs.CreateSkillCard{
	name = "sp_qiangxiCard",
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getMark("sp_qiangxi") or to_select:objectName() == sgs.Self:objectName() then return false end
		return not to_select:isNude()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("sp_qiangxiTarget")
	end,
}
sp_qiangxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "sp_qiangxi",
	view_as = function() 
		return sp_qiangxiCard:clone()
	end,
	response_pattern = "@@sp_qiangxi",
}
sp_qiangxi = sgs.CreateDrawCardsSkill{
	name = "sp_qiangxi",
	priority = 1,
	view_as_skill = sp_qiangxiVS,
	draw_num_func = function(self, player, n)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			targets:append(p)
		end
		local num = math.min(targets:length(), n)
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			p:setFlags("-sp_qiangxiTarget")
		end
		if num > 0 then
			room:setPlayerMark(player, "sp_qiangxi", num)
			local count = 0
			if room:askForUseCard(player, "@@sp_qiangxi", "@sp_qiangxi-card:::" .. tostring(num)) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("sp_qiangxiTarget") then
						count = count + 1
					end
				end
			else 
				room:setPlayerMark(player, "sp_qiangxi", 0)
			end
			return n - count
		else
			return n
		end
	end,
}
sp_qiangxiAct = sgs.CreateTriggerSkill{
	name = "#sp_qiangxiAct",
	frequency = sgs.Skill_Frequent,
	events = {sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if player:getMark("sp_qiangxi") == 0 then return false end
		room:setPlayerMark(player, "sp_qiangxi", 0)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("sp_qiangxiTarget") then
				p:setFlags("-sp_qiangxiTarget")
				targets:append(p)
			end
		end
		for _, p in sgs.qlist(targets) do
			if not player:isAlive() then
				break
			end
			if p:isAlive() and not p:isNude() then
				local card_id = room:askForCardChosen(player, p, "he", "sp_qiangxi")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:broadcastSkillInvoke("sp_qiangxi")
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
				room:damage(sgs.DamageStruct("sp_qiangxi", player, p, 1, sgs.DamageStruct_Normal))
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
sp_shenzhangliao:addSkill(sp_qiangxi)
sp_shenzhangliao:addSkill(sp_qiangxiAct)
extension:insertRelatedSkills("sp_qiangxi", "#sp_qiangxiAct")

sp_liaolai = sgs.CreateTriggerSkill{
	name = "sp_liaolai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local sunshiwan = damage.to
		if sunshiwan:getKingdom() == "wu" then
			local n = 0
			if player:getHp() < sunshiwan:getHp() then n = n + 1 end
			if player:getHandcardNum() < sunshiwan:getHandcardNum() then n = n + 1 end
			if n > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local sqxr = damage.damage
				damage.damage = sqxr + n
				data:setValue(damage)
			end
		end
	end,
}
sp_shenzhangliao:addSkill(sp_liaolai)





--

--30 奇神·甘宁
sp_shenganning = sgs.General(extension_G, "sp_shenganning", "god", 4, true)

sp_lvezhenCard = sgs.CreateSkillCard{
    name = "sp_lvezhenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local n = source:getChangeSkillState("sp_lvezhen")
		if n == 1 then
			room:setChangeSkillState(source, "sp_lvezhen", 2)
			room:addPlayerMark(source, "sp_lvezhenFQC")
			-- local choices = {}
			-- for i = 0, 4 do
			-- 	if source:hasEquipArea(i) then
			-- 		table.insert(choices, i)
			-- 	end
			-- end
			-- if choices == "" then return false end
			-- local choice = room:askForChoice(source, "sp_lvezhen", table.concat(choices, "+"))
			-- local area = tonumber(choice), 0
			-- source:throwEquipArea(area)
			ThrowEquipArea(self,source,nil,nil)
			room:askForUseCard(source, "@@sp_lvezhen_SSQY", "@sp_lvezhen_SSQY-yang")
		elseif n == 2 then
			room:setChangeSkillState(source, "sp_lvezhen", 1)
			room:addPlayerMark(source, "sp_lvezhenFQC")
			-- local choices = {}
			-- for i = 0, 4 do
			-- 	if source:hasEquipArea(i) then
			-- 		table.insert(choices, i)
			-- 	end
			-- end
			-- if choices == "" then return false end
			-- local choice = room:askForChoice(source, "sp_lvezhen", table.concat(choices, "+"))
			-- local area = tonumber(choice), 0
			-- source:throwEquipArea(area)
			ThrowEquipArea(self,source,nil,nil)
			room:askForUseCard(source, "@@sp_lvezhen_GHCQ", "@sp_lvezhen_GHCQ-yin")
		end
	end,
}
sp_lvezhenVS = sgs.CreateViewAsSkill {
	name = "sp_lvezhen",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		else
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@@sp_lvezhen_SSQY" then
				return to_select:isRed()
			elseif sgs.Sanguosha:getCurrentCardUsePattern() == "@@sp_lvezhen_GHCQ" then
				return to_select:isBlack()
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sp_lvezhenCard:clone()
		else
			if #cards > 0 then
				if sgs.Sanguosha:getCurrentCardUsePattern() == "@@sp_lvezhen_SSQY" then
					local acard = sgs.Sanguosha:cloneCard("snatch", sgs.Card_SuitToBeDecided, -1)
					for _, cd in pairs(cards) do
						acard:addSubcard(cd)
					end
					acard:setSkillName("sp_lvezhen")
					return acard
				elseif sgs.Sanguosha:getCurrentCardUsePattern() == "@@sp_lvezhen_GHCQ" then
					local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_SuitToBeDecided, -1)
					for _, cd in pairs(cards) do
						acard:addSubcard(cd)
					end
					acard:setSkillName("sp_lvezhen")
					return acard
				end
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:hasEquipArea() and player:getMark("sp_lvezhenFQC") < 2
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sp_lvezhen_SSQY" or pattern == "@@sp_lvezhen_GHCQ"
	end
}
sp_lvezhen = sgs.CreateTriggerSkill{
    name = "sp_lvezhen",
	change_skill = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.CardFinished},
	view_as_skill = sp_lvezhenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Dismantlement") and table.contains(use.card:getSkillNames(), "sp_lvezhen") then
				local extra_targets = room:getCardTargets(player, use.card, use.to)
				if extra_targets:isEmpty() then return false end
				room:setTag("sp_lvezhen", data)
				local target = room:askForPlayerChosen(player, extra_targets, "sp_lvezhen",
							"@sp_lvezhen_SkillCardBuff:" .. use.card:objectName() .. "::" .. 1, true)
				room:removeTag("sp_lvezhen")
				local adds = sgs.SPlayerList()
				if target then
					use.to:append(target)
					adds:append(target)
				end
				
				if adds:isEmpty() then return false end
				room:sortByActionOrder(adds)
				room:sortByActionOrder(use.to)
				data:setValue(use)
				local log = sgs.LogMessage()
				log.type = "#QiaoshuiAdd"
				log.from = player
				log.to = adds
				log.card_str = use.card:toString()
				log.arg = "sp_lvezhen"
				room:sendLog(log)
				for _, p in sgs.qlist(adds) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke("sp_lvezhen")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() ~= "sp_lvezhen" then return false end
			if use.card:isKindOf("Snatch") then
				for _, p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						local card = room:askForCardChosen(player, p, "h", "sp_lvezhen")
						room:obtainCard(player, card, false)
						room:broadcastSkillInvoke("sp_lvezhen")
					end
				end
			elseif use.card:isKindOf("Dismantlement") then
				for _, p in sgs.qlist(use.to) do
					if player:canDiscard(p, "hej") then
						local card = room:askForCardChosen(player, p, "hej", "sp_lvezhen")
						room:throwCard(card, p, player)
						room:broadcastSkillInvoke("sp_lvezhen")
					end
				end
			end
		end
	end,
}
sp_lvezhenFQC_Clear = sgs.CreateTriggerSkill{
	name = "#sp_lvezhenFQC_Clear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
			return false
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("sp_lvezhenFQC") > 0 then
				local n = p:getMark("sp_lvezhenFQC")
				room:removePlayerMark(p, "sp_lvezhenFQC", n)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}


--技能卡效果：
sp_lvezhen_SSQY_moredistance = sgs.CreateTargetModSkill{
	name = "#sp_lvezhen_SSQY_moredistance",
	pattern = "Snatch",
	distance_limit_func = function(self, from, card)
		if from and table.contains(card:getSkillNames(), "sp_lvezhen") then
			return 1
		else
			return 0
		end
	end,
}
--
----

sp_shenganning:addSkill(sp_lvezhen)
sp_shenganning:addSkill(sp_lvezhenFQC_Clear)
sp_shenganning:addSkill(sp_lvezhen_SSQY_moredistance)
extension:insertRelatedSkills("sp_lvezhen", "#sp_lvezhenFQC_Clear")
extension:insertRelatedSkills("sp_lvezhen", "#sp_lvezhen_SSQY_moredistance")

sp_xiyingCard = sgs.CreateSkillCard{
	name = "sp_xiyingCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:removePlayerMark(effect.from, "@sp_xiying")
		room:doSuperLightbox("sp_shenganning", "sp_xiying")
		room:setPlayerFlag(effect.from, "sp_xiyingSource")
		room:addPlayerMark(effect.to, "&sp_xiyingTarget")
		effect.from:throwAllHandCards()
		if not effect.to:isKongcheng() then
			room:obtainCard(effect.from, effect.to:wholeHandCards(), false)
		end
		room:setFixedDistance(effect.from, effect.to, 1)
		local new_data = sgs.QVariant()
		new_data:setValue(effect.to)
		effect.from:setTag("sp_xiying", new_data)
	end,
}
sp_xiyingVS = sgs.CreateZeroCardViewAsSkill{
	name = "sp_xiying",
	view_as = function()
		return sp_xiyingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sp_xiying") > 0
	end,
}
sp_xiying = sgs.CreateTriggerSkill{
	name = "sp_xiying",
	frequency = sgs.Skill_Limited,
	limit_mark = "@sp_xiying",
	events = {sgs.Damage, sgs.EventPhaseChanging},
	view_as_skill = sp_xiyingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and player:hasFlag("sp_xiyingSource") and damage.to and damage.to:getMark("&sp_xiyingTarget") > 0 then
				room:broadcastSkillInvoke("sp_xiying")
				room:addPlayerMark(player, "&sp_xiyingDMG", damage.damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local caoying = player:getTag("sp_xiying"):toPlayer() 
			if caoying then room:removeFixedDistance(player, caoying, 1)
			end
			player:removeTag("sp_xiying")
			if not player:hasFlag("sp_xiyingSource") then return false end
			for _, cy in sgs.qlist(room:getOtherPlayers(player)) do
				if cy:isAlive() and cy:getMark("&sp_xiyingTarget") > 0 then
					if not player:isKongcheng() then
						room:obtainCard(cy, player:wholeHandCards(), false)
					end
					room:removePlayerMark(cy, "&sp_xiyingTarget")
				end
			end
			local n = player:getMark("&sp_xiyingDMG")
			room:drawCards(player, n, "sp_xiying")
			room:broadcastSkillInvoke("sp_xiying")
			room:removePlayerMark(player, "&sp_xiyingDMG", n)
			room:setPlayerFlag(player, "-sp_xiyingSource")
		end
	end,
}

sp_shenganning:addSkill(sp_xiying)

sp_shenya = sgs.CreateTriggerSkill{
    name = "sp_shenya",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.EventPhaseChanging, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive and not player:hasFlag("sp_shenyaDMGCaused") then
				room:setPlayerFlag(player, "sp_shenyaDMGCaused")
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if not player:hasFlag("sp_shenyaDMGCaused") then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			-- local choices = {}
			-- for i = 0, 4 do
			-- 	if not player:hasEquipArea(i) then
			-- 		table.insert(choices, i)
			-- 	end
			-- end
			-- if choices == "" then return false end
			-- local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			-- local area = tonumber(choice), 0
			-- player:obtainEquipArea(area)
			ObtainEquipArea(self,player,false,false)
		elseif event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if player:getHp() <= 0 and dying.damage and dying.damage.from then
				room:killPlayer(dying.who)
				room:setTag("SkipGameRule", sgs.QVariant(true))
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
}
sp_shenganning:addSkill(sp_shenya)

--==（V3.0）DIY界限突破包==--
extension_J = sgs.Package("fcDIY_jxtp", sgs.Package_GeneralPack)

--31 界刘繇
fcj_liuyao = sgs.General(extension_J, "fcj_liuyao", "qun", 4, true)

fcj_kannanCard = sgs.CreateSkillCard{
	name = "fcj_kannanCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("fcj_kannanSelected") and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local kn = effect.from:pindian(effect.to, self:objectName(), nil)
		if kn then
			room:broadcastSkillInvoke("fcj_kannan")
			room:addPlayerMark(effect.from, "&fcj_kannan", 1)
		else
			room:broadcastSkillInvoke("fcj_kannan")
			room:addPlayerMark(effect.to, "&fcj_kannan", 1)
		end
		room:addPlayerMark(effect.from, "fcj_kannanUsed")
		room:setPlayerFlag(effect.to, "fcj_kannanSelected")
		local choice = room:askForChoice(effect.from, "fcj_kannan", "1+2+3+cancel")
		if choice == "1" then
			room:broadcastSkillInvoke("fcj_kannan")
			room:drawCards(effect.from, 1, "fcj_kannan")
		elseif choice == "2" then
			room:broadcastSkillInvoke("fcj_kannan")
			room:removePlayerMark(effect.from, "fcj_kannanUsed")
		elseif choice == "3" then
			room:broadcastSkillInvoke("fcj_kannan")
			room:setPlayerFlag(effect.to, "-fcj_kannanSelected")
		end
	end,
}
fcj_kannanVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_kannan",
	view_as = function()
		return fcj_kannanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("fcj_kannanUsed") < player:getHp() and not player:isKongcheng()
	end,
}
fcj_kannan = sgs.CreateTriggerSkill{
    name = "fcj_kannan",
	view_as_skill = fcj_kannanVS,
	events = {sgs.ConfirmDamage, sgs.EventPhaseChanging, sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and player:getMark("&fcj_kannan") > 0 then
				local jly = room:findPlayerBySkillName("fcj_kannan")
				if not jly then return false end
				room:sendCompulsoryTriggerLog(jly, "fcj_kannan")
				room:broadcastSkillInvoke("fcj_kannan")
				local n = player:getMark("&fcj_kannan")
				damage.damage = damage.damage + n
				room:setPlayerMark(player, "&fcj_kannan", 0)
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseChanging or event == sgs.Death then
		    if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(p, "fcj_kannanUsed", 0)
					if p:hasFlag("fcj_kannanSelected") then room:setPlayerFlag(p, "-fcj_kannanSelected") end
				end
			end
			if event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then return false end
				local jly = room:findPlayerBySkillName("fcj_kannan")
				if jly then return false end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(p, "&fcj_kannan", 0)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_liuyao:addSkill(fcj_kannan)


--32 界庞德公
fcj_pangdegong = sgs.General(extension_J, "fcj_pangdegong", "qun", 3, true)

fcj_pingcaiCard = sgs.CreateSkillCard{
	name = "fcj_pingcaiCard",
	skill_name = "fcj_pingcai",
	target_fixed = true,
	mute = true, --关闭技能卡牌声音，防止乱报语音
	on_use = function(self, room, source, targets)
		room:getThread():delay(4500) --等开始评价语音说完
		local choice = room:askForChoice(source, "@fcj_pingcai-ChooseTreasure", "wolong+fengchu+shuijing+xuanjian")
		--卧龙
		if choice == "wolong" then
			local log = sgs.LogMessage()
			log.type = "$fcj_pingcai-ChooseTreasure_wolong"
			log.from = source
			room:sendLog(log)
			if not room:askForUseCard(source, "@@fcj_pingcaiWolong", "@fcj_pingcaiWolong-card") then return false end
			local wl = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSpecialOne(p, "卧龙诸葛亮") then
					local log = sgs.LogMessage()
					log.type = "$fcj_pingcaiWolong"
					log.from = source
					log.to:append(p)
					room:sendLog(log)
					wl = wl + 1
					break
				end
			end
			if wl > 0 then
				room:askForUseCard(source, "@@fcj_pingcaiWolong", "@fcj_pingcaiWolong-card")
			end
		--凤雏
		elseif choice == "fengchu" then
			local log = sgs.LogMessage()
			log.type = "$fcj_pingcai-ChooseTreasure_fengchu"
			log.from = source
			room:sendLog(log)
			if not room:askForUseCard(source, "@@fcj_pingcaiFengchu", "@fcj_pingcaiFengchu-card") then return false end
			local fcu = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSpecialOne(p, "庞统") then
					local log = sgs.LogMessage()
					log.type = "$fcj_pingcaiFengchu"
					log.from = source
					log.to:append(p)
					room:sendLog(log)
					fcu = fcu + 1
					break
				end
			end
			if fcu > 0 then
				room:askForUseCard(source, "@@fcj_pingcaiFengchu", "@fcj_pingcaiFengchu-card")
			end
		--水镜
		elseif choice == "shuijing" then
			local log = sgs.LogMessage()
			log.type = "$fcj_pingcai-ChooseTreasure_shuijing"
			log.from = source
			room:sendLog(log)
			if not room:askForUseCard(source, "@@fcj_pingcaiShuijing", "@fcj_pingcaiShuijing-card") then return false end
			local sj = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSpecialOne(p, "司马徽") then
					local log = sgs.LogMessage()
					log.type = "$fcj_pingcaiFengchu"
					log.from = source
					log.to:append(p)
					room:sendLog(log)
					sj = sj + 1
					break
				end
			end
			if sj > 0 then
				room:askForUseCard(source, "@@fcj_pingcaiShuijing", "@fcj_pingcaiShuijing-card")
			end
		--玄剑
		elseif choice == "xuanjian" then
			local log = sgs.LogMessage()
			log.type = "$fcj_pingcai-ChooseTreasure_xuanjian"
			log.from = source
			room:sendLog(log)
			if not room:askForUseCard(source, "@@fcj_pingcaiXuanjian", "@fcj_pingcaiXuanjian-card") then return false
			end
			local xj = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSpecialOne(p, "徐庶") then
					local log = sgs.LogMessage()
					log.type = "$fcj_pingcaiFengchu"
					log.from = source
					log.to:append(p)
					room:sendLog(log)
					xj = xj + 1
					break
				end
			end
			if xj > 0 then
				room:askForUseCard(source, "@@fcj_pingcaiXuanjian", "@fcj_pingcaiXuanjian-card")
			end
		end
	end,
}
fcj_pingcaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_pingcai",
	view_as = function()
		local rpattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if rpattern == "@@fcj_pingcaiWolong" then
			return fcj_pingcaiWolongCard:clone()
		elseif rpattern == "@@fcj_pingcaiFengchu" then
			return fcj_pingcaiFengchuCard:clone()
		elseif rpattern == "@@fcj_pingcaiShuijing" then
			return fcj_pingcaiShuijingCard:clone()
		elseif rpattern == "@@fcj_pingcaiXuanjian" then
			return fcj_pingcaiXuanjianCard:clone()
		end
		return fcj_pingcaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fcj_pingcaiCard")
	end,
	enabled_at_response = function(self, player, pattern)
		local rpattern = sgs.Sanguosha:getCurrentCardUsePattern()
		return string.find(rpattern, "@@fcj_pingcai")
	end
}
fcj_pingcai = sgs.CreateTriggerSkill{
    name = "fcj_pingcai",
	view_as_skill = fcj_pingcaiVS,
	events = {sgs.PreCardUsed, sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() and table.contains(use.card:getSkillNames(), "fcj_pingcai") then
				room:broadcastSkillInvoke("fcj_pingcai", 1)
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "fcj_pingcaiRXJ" then
				room:broadcastSkillInvoke("fcj_pingcai", 4)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_pangdegong:addSkill(fcj_pingcai)
--“卧龙”：对至多两名角色各造成1点火焰伤害。（因缘人物：卧龙诸葛亮）
fcj_pingcaiWolongCard = sgs.CreateSkillCard{
	name = "fcj_pingcaiWolongCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in pairs(targets) do
			room:damage(sgs.DamageStruct("fcj_pingcaiWolong", source, p, 1, sgs.DamageStruct_Fire))
			room:broadcastSkillInvoke("fcj_pingcai", 2)
		end
	end,
}

--“凤雏”：让至多四名角色进入连环状态。（因缘人物：庞统）
fcj_pingcaiFengchuCard = sgs.CreateSkillCard{
	name = "fcj_pingcaiFengchuCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 4
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in pairs(targets) do
			if not p:isChained() then room:setPlayerChained(p) end
			room:broadcastSkillInvoke("fcj_pingcai", 3)
		end
	end,
}

--“水镜”：将一名角色装备区内的一张牌移动到另一名角色的相应位置。（因缘人物：司马徽）
fcj_pingcaiShuijingCard = sgs.CreateSkillCard{
	name = "fcj_pingcaiShuijingCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getEquips():length() > 0
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(source, targets[1], "e", "fcj_pingcaiShuijing")
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		local equip_index = -1
		if place == sgs.Player_PlaceEquip then
			local equip = card:getRealCard():toEquipCard()
			equip_index = equip:location()
		end
		local tos = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		for _, p in sgs.qlist(list) do
			if equip_index ~= -1 then
				if not p:getEquip(equip_index) then
					tos:append(p)
				end
			else
				if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
					tos:append(p)
				end
			end
		end
		local tag = sgs.QVariant()
		tag:setValue(targets[1])
		room:setTag("fcj_pingcaiShuijingEquipTarget", tag)
		local to = room:askForPlayerChosen(source, tos, "fcj_pingcaiShuijing", "@fcj_pingcaiShuijing_Equip-to:" .. card:objectName())
		if to then
			room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), "fcj_pingcaiShuijing", ""))
			room:broadcastSkillInvoke("fcj_pingcai", 4)
		end
		room:removeTag("fcj_pingcaiShuijingEquipTarget")
		room:setPlayerFlag(source, "fcj_pingcaiShuijingMove_do")
	end,
}

--“玄剑”：令一名角色摸一张牌并回复1点体力，然后你摸一张牌。（因缘人物：徐庶）
fcj_pingcaiXuanjianCard = sgs.CreateSkillCard{
	name = "fcj_pingcaiXuanjianCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("fcj_pingcai", 5)
		room:drawCards(targets[1], 1, "fcj_pingcaiXuanjian")
		room:recover(targets[1], sgs.RecoverStruct(source))
		room:broadcastSkillInvoke("fcj_pingcai", 5)
		room:drawCards(source, 1, "fcj_pingcaiXuanjian")
	end,
}

----

fcj_pangdegong:addSkill("yinshiy")

--33 界陈到
fcj_chendao = sgs.General(extension_J, "fcj_chendao", "shu", 4, true)

fcj_wanglie = sgs.CreateTriggerSkill{
	name = "fcj_wanglie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.TargetSpecified, sgs.ConfirmDamage, sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.from:objectName() == player:objectName() and use.card and not use.card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
				if player:getMark("fcj_wanglieFQC") < 2 then
					room:addPlayerMark(player, "fcj_wanglieFQC")
				end
				if player:getMark("fcj_wanglieFQC") == 1 then --第一张牌：不计入次数
					room:broadcastSkillInvoke(self:objectName())
					if use.card:isKindOf("Analeptic") then
						room:setPlayerFlag(player, "fcj_wanglie_AnaRmvHsty") --处理不计使用次数代码对【酒】不生效的问题
					elseif not use.card:isKindOf("Analeptic") and use.m_addHistory then
						room:addPlayerHistory(player, use.card:getClassName(), -1)
					end
				end
				if player:getMark("fcj_wanglieFQC") > 1 and use.card:isKindOf("Analeptic") and player:hasFlag("fcj_wanglie_AnaRmvHsty") then
					room:setPlayerFlag(player, "-fcj_wanglie_AnaRmvHsty")
				end
				if player:hasFlag("fcj_wanglie_cantchooseHit") and player:hasFlag("fcj_wanglie_cantchooseDamage")
				and player:hasFlag("fcj_wanglie_cantchooseBeishui") then return false end
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local choices = {}
					if not player:hasFlag("fcj_wanglie_cantchooseHit") then
						table.insert(choices, "Hit")
					end
					if not player:hasFlag("fcj_wanglie_cantchooseDamage") then
						table.insert(choices, "Damage")
					end
					if not player:hasFlag("fcj_wanglie_cantchooseBeishui") then
						table.insert(choices, "Beishui")
					end
					table.insert(choices, "cancel")
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice == "Hit" then
						room:setCardFlag(use.card, "fcj_wanglieHit")
						room:setPlayerFlag(player, "fcj_wanglie_cantchooseHit")
					elseif choice == "Damage" then
						room:setCardFlag(use.card, "fcj_wanglieDamage")
						room:setPlayerFlag(player, "fcj_wanglie_cantchooseDamage")
					elseif choice == "Beishui" then
						room:setCardFlag(use.card, "fcj_wanglieHit")
						room:setCardFlag(use.card, "fcj_wanglieDamage")
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false)
						room:setPlayerFlag(player, "fcj_wanglie_cantchooseBeishui")
					end
				end
			end
		
		elseif event == sgs.TargetSpecified then --不能被响应
			if use.card:hasFlag("fcj_wanglieHit") then
				room:setCardFlag(use.card, "-fcj_wanglieHit")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(use.to) do
					table.insert(no_respond_list, p:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		elseif event == sgs.ConfirmDamage then --伤害+1
			local damage = data:toDamage()
			if damage.card:hasFlag("fcj_wanglieDamage") then
				room:setCardFlag(damage.card, "-fcj_wanglieDamage")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			if use.card:hasFlag("fcj_wanglieHit") then room:setCardFlag(use.card, "-fcj_wanglieHit") end
			if use.card:hasFlag("fcj_wanglieDamage") then room:setCardFlag(use.card, "-fcj_wanglieDamage") end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player, "fcj_wanglieFQC", 0)
				if player:hasFlag("fcj_wanglie_AnaRmvHsty") then room:setPlayerFlag(player, "-fcj_wanglie_AnaRmvHsty") end
				if player:hasFlag("fcj_wanglie_cantchooseHit") then room:setPlayerFlag(player, "-fcj_wanglie_cantchooseHit") end
				if player:hasFlag("fcj_wanglie_cantchooseDamage") then room:setPlayerFlag(player, "-fcj_wanglie_cantchooseDamage") end
				if player:hasFlag("fcj_wanglie_cantchooseBeishui") then
					room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand")
					room:setPlayerFlag(player, "-fcj_wanglie_cantchooseBeishui")
				end
			end
		end
	end,
}
fcj_wanglieSecondCard = sgs.CreateTargetModSkill{ --第二张牌：无距离限制
	name = "#fcj_wanglieSecondCard",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("fcj_wanglie") and from:getPhase() == sgs.Player_Play and from:getMark("fcj_wanglieFQC") == 1
		and card and not card:isKindOf("SkillCard") then
			return 1000
		else
			return 0
		end
	end,
}
fcj_wanglieAnaleptic = sgs.CreateTargetModSkill{ --第一张牌为【酒】不计入次数，可以再(无次数限制地)使用一张【酒】
	name = "#fcj_wanglieAnaleptic",
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill("fcj_wanglie") and player:hasFlag("fcj_wanglie_AnaRmvHsty") then
			return 1000
		else
			return 0
		end
	end,
}
fcj_chendao:addSkill(fcj_wanglie)
fcj_chendao:addSkill(fcj_wanglieSecondCard)
fcj_chendao:addSkill(fcj_wanglieAnaleptic)
extension:insertRelatedSkills("fcj_wanglie", "#fcj_wanglieSecondCard")
extension:insertRelatedSkills("fcj_wanglie", "#fcj_wanglieAnaleptic")

--34 界赵统赵广
fcj_zhaotongzhaoguang = sgs.General(extension_J, "fcj_zhaotongzhaoguang", "shu", 4, true)

fcj_zhaotongzhaoguang:addSkill("yizan")
fcj_zhaotongzhaoguang:addSkill("longyuan")

fcj_yunxing = sgs.CreateTriggerSkill{
	name = "fcj_yunxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local fcj_yunxing_cards = {}
			local fcj_yunxing_one_basic_count = 0
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and not table.contains(fcj_yunxing_cards, id) and fcj_yunxing_one_basic_count < 1 then
					fcj_yunxing_one_basic_count = fcj_yunxing_one_basic_count + 1
					table.insert(fcj_yunxing_cards, id)
				end
			end
			local fcj_yunxing_one_weapon_count = 0
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("Weapon") and not table.contains(fcj_yunxing_cards, id) and fcj_yunxing_one_weapon_count < 1 then
					fcj_yunxing_one_weapon_count = fcj_yunxing_one_weapon_count + 1
					table.insert(fcj_yunxing_cards, id)
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, id in ipairs(fcj_yunxing_cards) do
				dummy:addSubcard(id)
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:obtainCard(player, dummy, false)
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				card = response.m_card
			end
			if card and table.contains(card:getSkillNames(), "yizan") then
				room:addPlayerMark(player, "&fcj_yunxing")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return false end
			local n = player:getMark("&fcj_yunxing")
			if n <= 0 then return false end
			local fcj_yunxing_cards = {}
			local fcj_yunxing_basic_count = 0
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and not table.contains(fcj_yunxing_cards, id) and fcj_yunxing_basic_count < n then
					fcj_yunxing_basic_count = fcj_yunxing_basic_count + 1
					table.insert(fcj_yunxing_cards, id)
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, id in ipairs(fcj_yunxing_cards) do
				dummy:addSubcard(id)
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:obtainCard(player, dummy, false)
			room:setPlayerMark(player, "&fcj_yunxing", 0)
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local n = player:getMark("&fcj_yunxing")
			if n <= 0 then return false end
			local fcj_yunxing_cards = {}
			local fcj_yunxing_basic_count = 0
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and not table.contains(fcj_yunxing_cards, id) and fcj_yunxing_basic_count < n then
					fcj_yunxing_basic_count = fcj_yunxing_basic_count + 1
					table.insert(fcj_yunxing_cards, id)
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, id in ipairs(fcj_yunxing_cards) do
				dummy:addSubcard(id)
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:obtainCard(player, dummy, false)
			room:setPlayerMark(player, "&fcj_yunxing", 0)
		end
	end,
}
fcj_zhaotongzhaoguang:addSkill(fcj_yunxing)





--

--35 界于禁-旧
fcj_yujin_old = sgs.General(extension_J, "fcj_yujin_old", "wei", 4, true)

local function fcjyzCandiscard(player)
	if player:isDead() then return false end
	local can_dis = false
	for _, c in sgs.qlist(player:getCards("he")) do
		if c:isBlack() and player:canDiscard(player, c:getEffectiveId()) then
			can_dis = true
			break
		end
	end
	return can_dis
end
fcj_yizhong = sgs.CreateTriggerSkill{
	name = "fcj_yizhong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected, sgs.TargetSpecified, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Slash") and effect.card:isBlack() then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:isBlack() and use.from:objectName() == player:objectName() then
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(use.to) do
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					table.insert(no_respond_list, p:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish or not fcjyzCandiscard(player) then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local card = room:askForCard(player, ".|black", "@fcj_yizhong-invoke", data, sgs.Card_MethodDiscard)
			if card then
				local other = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@fcj_yizhong-choose")
				room:broadcastSkillInvoke(self:objectName())
				if not other:hasSkill(self:objectName()) then
					room:addPlayerMark(other, self:objectName())
					room:acquireSkill(other, self:objectName())
				end
			end
		end
	end,
}
fcj_yizhongLS = sgs.CreateTriggerSkill{
	name = "#fcj_yizhongLS",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		room:detachSkillFromPlayer(player, "fcj_yizhong", false, true)
		room:setPlayerMark(player, "fcj_yizhong", 0)
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("fcj_yizhong") and player:getMark("fcj_yizhong") > 0
	end,
}
fcj_yujin_old:addSkill(fcj_yizhong)
fcj_yujin_old:addSkill(fcj_yizhongLS)
extension:insertRelatedSkills("fcj_yizhong", "#fcj_yizhongLS")






--

--36 界曹昂
fcj_caoang = sgs.General(extension_J, "fcj_caoang", "wei", 4, true)

fcj_kangkai = sgs.CreateTriggerSkill{
	name = "fcj_kangkai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isDamageCard() then
			local n = 0
			if use.card:isKindOf("Slash") then n = 1 end
			for _, to in sgs.qlist(use.to) do
				if not player:isAlive() then break end
				if player:distanceTo(to) <= n+1 and player:hasSkill(self:objectName()) then
					player:setTag("fcj_kangkaiSlash", data)
					local to_data = sgs.QVariant()
					to_data:setValue(to)
					local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
					player:removeTag("fcj_kangkaiSlash")
					if will_use then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1, self:objectName())
						if not player:isNude() --[[and player:objectName() ~= to:objectName()]] then
							local card = nil
							if player:getCardCount() > 1 then
								card = room:askForCard(player, "..!", "@fcj_kangkai-give:" .. to:objectName(), data, sgs.Card_MethodNone);
								if not card then
									card = player:getCards("he"):at(math.random(player:getCardCount()))
								end
							else
								card = player:getCards("he"):first()
							end
							to:obtainCard(card)
							if to:objectName() == player:objectName() then room:showCard(to, card:getEffectiveId()) end
							if card:isKindOf("BasicCard") or card:isKindOf("Nullification") then
								if room:askForSkillInvoke(player, "fcj_kangkai_hedraw", data) then
									to:drawCards(1, self:objectName())
								end
							elseif not card:isKindOf("BasicCard") and not card:isKindOf("Nullification")
							and room:getCardOwner(card:getEffectiveId()):objectName() == to:objectName() and not to:isLocked(card) then
								local xdata = sgs.QVariant()
								xdata:setValue(card)
								to:setTag("fcj_kangkaiSlash", data)
								to:setTag("fcj_kangkaiGivenCard", xdata)
								local will_use = room:askForSkillInvoke(to, "fcj_kangkai_use", sgs.QVariant("use"))
								to:removeTag("fcj_kangkaiSlash")
								to:removeTag("fcj_kangkaiGivenCard")
								if will_use then
									if to:getState() ~= "online" and card:isKindOf("EquipCard") then
										room:useCard(sgs.CardUseStruct(card, to, to))
									else
										--[[local pattern = "|.|.|.|."
										for _, p in sgs.qlist(room:getOtherPlayers(to)) do
											if not sgs.Sanguosha:isProhibited(to, p, card) then
												pattern = card:getClassName()..pattern
												break
											end
										end
										if pattern ~= "|.|.|.|." then
											room:askForUseCard(to, pattern, "@fcj_kangkai_ut:"..card:objectName(), -1)
										end]]
										local pattern = {}
										for _, p in sgs.qlist(room:getOtherPlayers(to)) do
											if not sgs.Sanguosha:isProhibited(to, p, card) and card:isAvailable(to) then
												table.insert(pattern, card:getEffectiveId())
											end
										end
										if #pattern > 0 then
											room:askForUseCard(to, table.concat(pattern, ","), "@fcj_kangkai_ut:"..card:objectName(), -1)
										end
									end
								end							
							end
						end
					end
				end
			end
		end
	end,
}
fcj_caoang:addSkill(fcj_kangkai)





--

--37 界吕岱
fcj_lvdai = sgs.General(extension_J, "fcj_lvdai", "wu", 4, true)

fcj_qinguoCard = sgs.CreateSkillCard{
	name = "fcj_qinguoCard",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("fcj_qinguo")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if not targets_list:isEmpty() then
			room:broadcastSkillInvoke("fcj_qinguo")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("fcj_qinguo")
			slash:deleteLater()
			room:useCard(sgs.CardUseStruct(slash, source, targets_list), false)
		end
	end,
}
fcj_qinguoVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_qinguo",
	view_as = function()
		return fcj_qinguoCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@fcj_qinguo"
	end,
}
fcj_qinguo = sgs.CreateTriggerSkill{
	name = "fcj_qinguo",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.CardFinished},
	view_as_skill = fcj_qinguoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			room:setPlayerMark(player, self:objectName(), player:getEquips():length())
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip)
			or (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip)) then 
				local n = 0
				if player:getHp() == player:getEquips():length() then n = n + 1 end
				if player:getEquips():length() ~= player:getMark(self:objectName()) then n = n + 1 end
				if n > 0 then
					while n > 0 do
						room:broadcastSkillInvoke(self:objectName())
						if player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player))
						end
						room:drawCards(player, 1, self:objectName())
						n = n - 1
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") then
				room:askForUseCard(player, "@@fcj_qinguo", "@fcj_qinguo-slash")
			end
		end
	end,
}
fcj_lvdai:addSkill(fcj_qinguo)

--38 界陆抗
fcj_lukang = sgs.General(extension_J, "fcj_lukang", "wu", 4, true)

fcj_lukang:addSkill("qianjie")

fcj_jueyanCard = sgs.CreateSkillCard{
	name = "fcj_jueyan",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local x = ThrowEquipArea(self, source)
		room:addPlayerMark(source, "fcj_jueyan"..x.."-Clear")
		if x == 1 then
			source:drawCards(3, self:objectName()) --废除防具栏：摸三张牌
		end
		local log = sgs.LogMessage()
		if x == 0 then log.type = "$fcj_jueyan-0"
		elseif x == 1 then log.type = "$fcj_jueyan-1"
		elseif x == 2 then log.type = "$fcj_jueyan-2"
		elseif x == 4 then log.type = "$fcj_jueyan-4"
		end
		log.from = source
		room:sendLog(log)
	end,
}
fcj_jueyanVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_jueyan",
	view_as = function()
		return fcj_jueyanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:hasEquipArea()
	end,
}
fcj_jueyan = sgs.CreateTriggerSkill{
	name = "fcj_jueyan",
	--global = true,
	--frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	view_as_skill = fcj_jueyanVS,
	waked_skills = "tenyearjizhi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then --废除宝物栏：本回合视为拥有“界集智”
			local use = data:toCardUse()
			local jizhi = sgs.Sanguosha:getTriggerSkill("tenyearjizhi")
			if jizhi and use.card and player:getMark("fcj_jueyan4-Clear") > 0 then
				jizhi:trigger(event, room, player, data)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			room:setPlayerMark(player, "fcj_jueyan0-Clear", 0)
			room:setPlayerMark(player, "fcj_jueyan1-Clear", 0)
			room:setPlayerMark(player, "fcj_jueyan2-Clear", 0)
			room:setPlayerMark(player, "fcj_jueyan4-Clear", 0)
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_jueyanWeapon = sgs.CreateTargetModSkill{ --废除武器栏：本回合杀次数+3
	name = "#fcj_jueyanWeapon",
	residue_func = function(self, player)
		if player:getMark("fcj_jueyan0-Clear") > 0 then
			return 3
		else
			return 0
		end
	end,
}
fcj_jueyanArmor = sgs.CreateMaxCardsSkill{ --废除防具栏：本回合手牌上限+3
	name = "#fcj_jueyanArmor",
	extra_func = function(self, player)
		if player:getMark("fcj_jueyan1-Clear") > 0 then
			return 3
		else
			return 0
		end
	end,
}
fcj_jueyanHorse = sgs.CreateTargetModSkill{ --废除坐骑栏：使用牌无距离限制
	name = "#fcj_jueyanHorse",
	pattern = "Card",
	distance_limit_func = function(self, player, card)
		if player:getMark("fcj_jueyan2-Clear") > 0 and not card:isKindOf("SkillCard") then
			return 1000
		else
			return 0
		end
	end,
}
fcj_lukang:addSkill(fcj_jueyan)
fcj_lukang:addSkill(fcj_jueyanWeapon)
fcj_lukang:addSkill(fcj_jueyanArmor)
fcj_lukang:addSkill(fcj_jueyanHorse)
extension:insertRelatedSkills("fcj_jueyan", "#fcj_jueyanWeapon")
extension:insertRelatedSkills("fcj_jueyan", "#fcj_jueyanArmor")
extension:insertRelatedSkills("fcj_jueyan", "#fcj_jueyanHorse")

fcj_poshi = sgs.CreateTriggerSkill{
    name = "fcj_poshi",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	waked_skills = "ps_huairou",
	can_wake = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:hasEquipArea() and player:getHp() ~= 1 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("fcj_lukang", self:objectName())
		room:addPlayerMark(player, self:objectName())
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			local n = player:getMaxHp() - player:getHandcardNum()
			for i = 0, 4 do
				if player:hasEquipArea(i) then
					n = n + 1
				end
			end
			if n > 0 then
				room:drawCards(player, n, self:objectName())
			end
			if player:hasSkill("fcj_jueyan") then
				room:detachSkillFromPlayer(player, "fcj_jueyan")
			end
			if not player:hasSkill("ps_huairou") then
				room:acquireSkill(player, "ps_huairou")
			end
		end
	end,
}
fcj_lukang:addSkill(fcj_poshi)

--“怀柔”
ps_huairouCard = sgs.CreateSkillCard{
	name = "ps_huairou",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), ""))
		room:broadcastSkillInvoke("@recast")
		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = source
		log.card_str = tostring(self:getSubcards():first())
		room:sendLog(log)
		room:drawCards(source, 1, "recast")
		room:addPlayerMark(source, "&ps_huairou", 1)
	end,
}
ps_huairou = sgs.CreateOneCardViewAsSkill{
	name = "ps_huairou",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local skill_card = ps_huairouCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
}
ps_huairou_qicai = sgs.CreateTargetModSkill{
	name = "#ps_huairou_qicai",
	pattern = "Slash",
	distance_limit_func = function(self, from)
		local n = from:getMark("&ps_huairou")
		if n > 0 then
			return n
		else
			return 0
		end
	end,
}
ps_huairouEnd = sgs.CreateTriggerSkill{
	name = "#ps_huairouEnd",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "&ps_huairou", 0)
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&ps_huairou") > 0
	end,
}
if not sgs.Sanguosha:getSkill("ps_huairou") then skills:append(ps_huairou) end
if not sgs.Sanguosha:getSkill("#ps_huairou_qicai") then skills:append(ps_huairou_qicai) end
if not sgs.Sanguosha:getSkill("#ps_huairouEnd") then skills:append(ps_huairouEnd) end
extension:insertRelatedSkills("ps_huairou", "#ps_huairou_qicai")
extension:insertRelatedSkills("ps_huairou", "#ps_huairouEnd")
--

--39 界麹义
fcj_quyi = sgs.General(extension_J, "fcj_quyi", "qun", 4, true)

fcj_fuqi = sgs.CreateTriggerSkill{
	name = "fcj_fuqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local n, no_respond_list = 0, use.no_respond_list
		for _, bm in sgs.qlist(room:getOtherPlayers(player)) do
			if bm:distanceTo(player) == 1 or player:distanceTo(bm) == 1 then
				table.insert(no_respond_list, bm:objectName())
				n = n + 1
			end
		end
		if n > 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
		end
		use.no_respond_list = no_respond_list
		data:setValue(use)
	end,
}
fcj_quyi:addSkill(fcj_fuqi)

fcj_jiaozi = sgs.CreateTriggerSkill{
	name = "fcj_jiaozi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local jiaozi = damage.damage
		local hc, n, m = player:getHandcardNum(), 0, 0
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > hc then --手牌数不为全场最多或之一
				n = n + 1
			end
			if p:getHandcardNum() < hc then --手牌数不为全场最少或之一
				m = m + 1
			end
		end
		if n == 0 or m == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local kjz, bcsk = 0, math.random(1,2)
			if n == 0 then
				kjz = kjz + 1
				room:broadcastSkillInvoke(self:objectName(), bcsk)
			end
			if m == 0 then
				kjz = kjz + 1
				room:broadcastSkillInvoke(self:objectName(), bcsk)
			end
			damage.damage = jiaozi + kjz
		end
		data:setValue(damage)
	end,
}
fcj_quyi:addSkill(fcj_jiaozi)

--40 界司马徽
fcj_simahui = sgs.General(extension_J, "fcj_simahui", "qun", 3, true)

fcj_jianjieCard = sgs.CreateSkillCard{
	name = "fcj_jianjieCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getMark("&fcj_Loong") > 0 or to_select:getMark("&fcj_Phoenix") > 0)
	end,
	on_use = function(self, room, source, targets)
		local removeFrom, removeTo = targets[1], nil
		local choices = {}
		if removeFrom:getMark("&fcj_Loong") > 0 then
			table.insert(choices, "1")
		end
		if removeFrom:getMark("&fcj_Phoenix") > 0 then
			table.insert(choices, "2")
		end
		local choice = room:askForChoice(source, "fcj_jianjie", table.concat(choices, "+"))
		if choice == "1" then
			removeTo = room:askForPlayerChosen(source, room:getOtherPlayers(removeFrom), "fcj_jianjie", "fcj_jianjiePlay-LY")
			removeFrom:loseMark("&fcj_Loong", 1)
			removeTo:gainMark("&fcj_Loong", 1)
		elseif choice == "2" then
			removeTo = room:askForPlayerChosen(source, room:getOtherPlayers(removeFrom), "fcj_jianjie", "fcj_jianjiePlay-FY")
			removeFrom:loseMark("&fcj_Phoenix", 1)
			removeTo:gainMark("&fcj_Phoenix", 1)
		end
	end,
}
fcj_jianjie = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_jianjie",
	waked_skills = "fcjiehuoji, fcjielianhuan, fczhizhe, fcjieniepan, fcluanfeng",
	view_as = function()
		return fcj_jianjieCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#fcj_jianjieCard") < 2
	end,
}
fcj_jianjieTrigger = sgs.CreateTriggerSkill{
	name = "#fcj_jianjieTrigger",
	priority = {4, 4},
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:hasSkill("fcj_jianjie") and player:getMark("fcj_jianjieStart") == 0 then
				room:addPlayerMark(player, "fcj_jianjieStart")
				room:sendCompulsoryTriggerLog(player, "fcj_jianjie")
				player:gainMark("&fcj_Loong", 1)
				player:gainMark("&fcj_Phoenix", 1)
				local players = room:getAllPlayers()
				local wolong = room:askForPlayerChosen(player, players, "fcj_jianjie", "fcj_jianjieStart-LY")
				room:setPlayerFlag(wolong, "fcj_jianjie_wolong")
				players:removeOne(wolong)
				local fengchu = room:askForPlayerChosen(player, players, --[["fcj_jianjie"]]"fcj_jianjied", "fcj_jianjieStart-FY")
				room:setPlayerFlag(fengchu, "fcj_jianjie_fengchu")
				room:broadcastSkillInvoke("fcj_jianjie", 1)
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("fcj_jianjie_wolong") then
						room:setPlayerFlag(p, "-fcj_jianjie_wolong")
						p:gainMark("&fcj_Loong", 1)
					elseif p:hasFlag("fcj_jianjie_fengchu") then
						room:setPlayerFlag(p, "-fcj_jianjie_fengchu")
						p:gainMark("&fcj_Phoenix", 1)
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() and (player:getMark("&fcj_Loong") > 0 or player:getMark("&fcj_Phoenix") > 0) then
				if player:getMark("&fcj_Loong") > 0 then
					for _, jsmh in sgs.qlist(room:findPlayersBySkillName("fcj_jianjie")) do
						local jcr = room:askForPlayerChosen(jsmh, room:getOtherPlayers(player), "fcj_jianjie", "fcj_jianjieDeath-LY", true, true)
						if jcr then
							local n = player:getMark("&fcj_Loong")
							player:loseAllMarks("&fcj_Loong")
							jcr:gainMark("&fcj_Loong", n)
						end
					end
				end
				if player:getMark("&fcj_Phoenix") > 0 then
					for _, jsmh in sgs.qlist(room:findPlayersBySkillName("fcj_jianjie")) do
						local jcr = room:askForPlayerChosen(jsmh, room:getOtherPlayers(player), "fcj_jianjie", "fcj_jianjieDeath-FY", true, true)
						if jcr then
							local m = player:getMark("&fcj_Phoenix")
							player:loseAllMarks("&fcj_Phoenix")
							jcr:gainMark("&fcj_Phoenix", m)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_jianjieMarks = sgs.CreateTriggerSkill{
	name = "#fcj_jianjieMarks",
	frequency = sgs.Skill_Frequent,
	events = {sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = data:toMark()
		if mark.who:objectName() ~= player:objectName() then return false end
		if mark.name == "&fcj_Loong" then
			if mark.gain > 0 then
				if player:getMark("&fcj_Loong") >= 1 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(2,3))
					if not player:hasSkill("fcjiehuoji") then
						room:attachSkillToPlayer(player, "fcjiehuoji")
					end
				end
				if player:getMark("&fcj_Loong") >= 2 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(4,5))
					if not player:hasSkill("fczhizhe") then
						room:attachSkillToPlayer(player, "fczhizhe")
					end
				end
				if player:getMark("&fcj_Loong") >= 2 and player:getMark("&fcj_Phoenix") >= 2 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(4,5))
					if not player:hasSkill("fcluanfeng") then
						room:acquireSkill(player, "fcluanfeng", false, false, false)
					end
				end
			elseif mark.gain < 0 then
				if player:getMark("&fcj_Loong") < 1 then
					if player:hasSkill("fcjiehuoji") then
						room:detachSkillFromPlayer(player, "fcjiehuoji", true)
					end
				end
				if player:getMark("&fcj_Loong") < 2 then
					if player:hasSkill("fczhizhe") then
						room:detachSkillFromPlayer(player, "fczhizhe", true)
					end
					if player:hasSkill("fcluanfeng") then
						--room:detachSkillFromPlayer(player, "fcluanfeng", true)
						room:handleAcquireDetachSkills(player, "-fcluanfeng")
					end
				end
			end
		elseif mark.name == "&fcj_Phoenix" then
			if mark.gain > 0 then
				if player:getMark("&fcj_Phoenix") >= 1 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(2,3))
					if not player:hasSkill("fcjielianhuan") then
						room:attachSkillToPlayer(player, "fcjielianhuan")
					end
				end
				if player:getMark("&fcj_Phoenix") >= 2 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(4,5))
					if not player:hasSkill("fcjieniepan") then
						-- room:attachSkillToPlayer(player, "fcjieniepan")
						room:acquireSkill(player, "fcjieniepan", false, false, false)
					end
				end
				if player:getMark("&fcj_Phoenix") >= 2 and player:getMark("&fcj_Loong") >= 2 then
					room:broadcastSkillInvoke("fcj_jianjie", math.random(4,5))
					if not player:hasSkill("fcluanfeng") then
						room:attachSkillToPlayer(player, "fcluanfeng")
					end
				end
			elseif mark.gain < 0 then
				if player:getMark("&fcj_Phoenix") < 1 then
					if player:hasSkill("fcjielianhuan") then
						room:detachSkillFromPlayer(player, "fcjielianhuan", true)
					end
				end
				if player:getMark("&fcj_Phoenix") < 2 then
					if player:hasSkill("fcjieniepan") then
						-- room:detachSkillFromPlayer(player, "fcjieniepan", true)
						room:handleAcquireDetachSkills(player, "-fcjieniepan")
					end
					if player:hasSkill("fcluanfeng") then
						-- room:detachSkillFromPlayer(player, "fcluanfeng", true)
						room:handleAcquireDetachSkills(player, "-fcluanfeng")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_simahui:addSkill(fcj_jianjie)
fcj_simahui:addSkill(fcj_jianjieTrigger)
fcj_simahui:addSkill(fcj_jianjieMarks)
extension:insertRelatedSkills("fcj_jianjie", "#fcj_jianjieTrigger")
extension:insertRelatedSkills("fcj_jianjie", "#fcj_jianjieMarks")
fcj_simahui:addRelateSkill("fcjiehuoji")
fcj_simahui:addRelateSkill("fcjielianhuan")
fcj_simahui:addRelateSkill("fczhizhe")
fcj_simahui:addRelateSkill("fcjieniepan")
fcj_simahui:addRelateSkill("fcluanfeng")

--1龙印：界火计
fcjiehuoji = sgs.CreateOneCardViewAsSkill{
	name = "fcjiehuoji",
	filter_pattern = ".|red",
	view_as = function(self, card)
		local fratk = sgs.Sanguosha:cloneCard("FireAttack", card:getSuit(), card:getNumber())
		fratk:setSkillName(self:objectName())
		fratk:addSubcard(card:getId())
		return fratk
	end,
}
if not sgs.Sanguosha:getSkill("fcjiehuoji") then skills:append(fcjiehuoji) end
--1凤印：界连环
fcjielianhuan = sgs.CreateOneCardViewAsSkill{
	name = "fcjielianhuan",
	filter_pattern = ".|club|.|hand",
	view_as = function(self, card)
		local irca = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
		irca:setSkillName(self:objectName())
		irca:addSubcard(card:getId())
		return irca
	end,
}
fcjielianhuan_trigger = sgs.CreateTriggerSkill{
	name = "#fcjielianhuan_trigger",
	global = true,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.from:objectName() == player:objectName() 
		and use.card and use.card:isKindOf("IronChain") and table.contains(use.card:getSkillNames(), "fcjielianhuan") then
			local extra_targets = room:getCardTargets(player, use.card, use.to)
			if extra_targets:isEmpty() then return false end
			
			room:setTag("fcjielianhuan", data)
			
			local target = room:askForPlayerChosen(player, extra_targets, "fcjielianhuan", "@fcjielianhuans-excard:" .. use.card:objectName() .. "::" .. 1, true, true)
			if not target then return false end
			room:removeTag("fcjielianhuan")
			local adds = sgs.SPlayerList()
			use.to:append(target)
			adds:append(target)
			if adds:isEmpty() then return false end
			room:sortByActionOrder(adds)
			room:sortByActionOrder(use.to)
			data:setValue(use)
			local log = sgs.LogMessage()
			log.type = "#QiaoshuiAdd"
			log.from = player
			log.to = adds
			log.card_str = use.card:toString()
			log.arg = "fcjielianhuan"
			room:sendLog(log)
			for _, p in sgs.qlist(adds) do
				room:doAnimate(1, player:objectName(), p:objectName())
			end
			room:notifySkillInvoked(player, "fcjielianhuan")
			room:broadcastSkillInvoke("fcjielianhuan")
		end
	end,
}
if not sgs.Sanguosha:getSkill("fcjielianhuan") then skills:append(fcjielianhuan) end
if not sgs.Sanguosha:getSkill("#fcjielianhuan_trigger") then skills:append(fcjielianhuan_trigger) end
extension:insertRelatedSkills("fcjielianhuan","#fcjielianhuan_trigger")
--2龙印：智哲
  --空白“智哲”卡·基本牌
FczhizheBasic = sgs.CreateBasicCard{
	name = "_fczhizhe_basic",
	class_name = "FczhizheBasic",
	subtype = "fczhizhe",
	on_use = function()
	end,
}
FczhizheBasic:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
FczhizheBasic:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
  --空白“智哲”卡·锦囊牌
FczhizheTrick = sgs.CreateTrickCard{
	name = "_fczhizhe_trick",
	class_name = "FczhizheTrick",
	subtype = "fczhizhe",
	on_use = function()
	end,
}
FczhizheTrick:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
FczhizheTrick:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
fczhizhe_vs = sgs.CreateFilterSkill{
	name = "fczhizhe_vs&",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:objectName() == "_fczhizhe_basic" or to_select:objectName() == "_fczhizhe_trick"
	end,
	view_as = function(self, card)
		local room = sgs.Sanguosha:currentRoom()
		local infos = room:getTag("fczhizhFilter_"..card:getId()):toString():split("+")
		if not infos or #infos < 2 then return card end
		-- local pattern = sgs.Self:property("fczhizhe_record_card"):toString()
		-- local suit = sgs.Self:property("fczhizhe_record_suit"):toString()
		-- local number = sgs.Self:property("fczhizhe_record_number"):toString()
		local suit = sgs.Card_NoSuit
		if infos[2] == "spade" then
			suit = sgs.Card_Spade
		elseif infos[2] == "heart" then
			suit = sgs.Card_Heart
		elseif infos[2] == "diamond" then
			suit = sgs.Card_Diamond
		elseif infos[2] == "club" then
			suit = sgs.Card_Club
		elseif infos[2] == "no_suit_black" then
			suit = sgs.Card_NoSuitBlack
		elseif infos[2] == "no_suit_red" then
			suit = sgs.Card_NoSuitRed
		end
		local zz_vs = sgs.Sanguosha:cloneCard(infos[1], suit, tonumber(infos[3]))
		if not zz_vs then return card end
		zz_vs:setSkillName("fczhizhe")
		local _card = sgs.Sanguosha:getWrappedCard(card:getId())
		_card:takeOver(zz_vs)
		return _card
	end,
}
fczhizheCard = sgs.CreateSkillCard{
	name = "fczhizheCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		room:doLightbox("$fczhizhe")
		local zz_id = self:getSubcards():first()
		local zz_card = sgs.Sanguosha:getCard(zz_id)
		
		
		local zz_cds = sgs.IntList()
		for _, zid in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			local zcd = sgs.Sanguosha:getEngineCard(zid)
			if (zcd:isKindOf("FczhizheBasic") or zcd:isKindOf("FczhizheTrick")) and zcd:getTypeId() == zz_card:getTypeId()
			and room:getCardPlace(zid) ~= sgs.Player_DrawPile and room:getCardPlace(zid) ~= sgs.Player_DiscardPile
			and room:getCardPlace(zid) ~= sgs.Player_PlaceHand and room:getCardPlace(zid) ~= sgs.Player_PlaceEquip and room:getCardPlace(zid) ~= sgs.Player_PlaceJudge
			--[[and room:getCardPlace(zid) ~= sgs.Player_PlaceTable]] and room:getCardPlace(zid) ~= sgs.Player_PlaceSpecial then
				zz_cds:append(zid)
				break
			end
		end
		if not zz_cds:isEmpty() then
			room:shuffleIntoDrawPile(source, zz_cds, "fczhizhe", true)
			for _, id in sgs.qlist(room:getDrawPile()) do
				local cd = sgs.Sanguosha:getCard(id)
				if cd:isKindOf("FczhizheBasic") or cd:isKindOf("FczhizheTrick") then
					room:obtainCard(source, cd, false)
					local info = {}
					table.insert(info, zz_card:objectName())
					table.insert(info, zz_card:getSuitString())
					table.insert(info, zz_card:getNumber())
					room:setTag("fczhizhFilter_" .. id, ToData(table.concat(info, "+")))
					break
				end
			end
		end
		

		-- local name, suit, number = zz_card:objectName(), zz_card:getSuit(), zz_card:getNumber()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			-- room:setPlayerProperty(p, "fczhizhe_record_card", sgs.QVariant(name))
			-- room:setPlayerProperty(p, "fczhizhe_record_suit", sgs.QVariant(suit))
			-- room:setPlayerProperty(p, "fczhizhe_record_number", sgs.QVariant(number))
			if not p:hasSkill("fczhizhe_vs") then
				room:attachSkillToPlayer(p, "fczhizhe_vs")
			end
		end
		source:loseMark("&fcj_Loong", 1) --room:detachSkillFromPlayer(source, "fczhizhe", true) --真·限定技
	end,
}
fczhizheVS = sgs.CreateOneCardViewAsSkill{
	name = "fczhizhe",
	view_filter = function(self, to_select)
		return not to_select:isEquipped() and not to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local zz_cd = fczhizheCard:clone()
		zz_cd:addSubcard(card:getId())
		zz_cd:setSkillName(self:objectName())
		return zz_cd
	end,
	enabled_at_play = function(self, player)
		return player:hasSkill(self:objectName()) and player:getMark("&fcj_Loong") >= 2
	end,
}
fczhizhe = sgs.CreateTriggerSkill{
	name = "fczhizhe",
	frequency = sgs.Skill_Limited,
	--limit_mark = "@fczhizhe", --不用标记，用完直接失去技能
	view_as_skill = fczhizheVS,
	on_trigger = function()
	end,
}
fczhizheFCB = sgs.CreateTriggerSkill{
	name = "fczhizheFCB",
	global = true,
	priority = {88, 888, 888},
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.CardUsed, sgs.CardResponded, sgs.EventLoseSkill, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local resp = data:toCardResponse()
				card = resp.m_card
			end
			if card and not card:isKindOf("SkillCard") and table.contains(card:getSkillNames(), "fczhizhe") then
				room:setCardFlag(card, "fczhizheFCB_UAR_card") room:addPlayerMark(player, "fczhizheFCB_UAR_" .. player:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					local mcd = sgs.Sanguosha:getCard(id)
					if mcd:hasFlag("fczhizheFCB_UAR_card") then --if table.contains(mcd:getSkillNames(), "fczhizhe") then
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:getMark("fczhizheFCB_UAR_" .. p:objectName()) > 0 then
								room:setPlayerMark(p, "fczhizheFCB_UAR_" .. p:objectName(), 0)
								room:obtainCard(p, mcd)
								room:setPlayerCardLimitation(p, "use,response", "" .. id, false)
								room:setPlayerFlag(p, self:objectName())
								break
							end
						end
					end
				end
			end
		elseif event == sgs.EventLoseSkill then --防老六
			if data:toString() == "fczhizhe_vs" then
				room:attachSkillToPlayer(player, "fczhizhe_vs")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:hasFlag(self:objectName()) then
				room:setPlayerFlag(player, "-fczhizheFCB")
				for _, c in sgs.qlist(player:getHandcards()) do
					if table.contains(c:getSkillNames(), "fczhizhe") then
						room:removePlayerCardLimitation(player, "use,response", "" .. c:getEffectiveId())
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
if not sgs.Sanguosha:getSkill("fczhizhe") then skills:append(fczhizhe) end
if not sgs.Sanguosha:getSkill("fczhizhe_vs") then skills:append(fczhizhe_vs) end
if not sgs.Sanguosha:getSkill("fczhizheFCB") then skills:append(fczhizheFCB) end
--2凤印：界涅槃
fcjieniepan = sgs.CreateTriggerSkill{
	name = "fcjieniepan",
	--global = true,
	frequency = sgs.Skill_Limited,
	--limit_mark = "@fcjieniepan",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() == player:objectName() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:doLightbox("$fcjieniepan")
				player:throwAllCards()
				if player:isChained() then
					local damage = dying_data.damage
					if damage == nil or damage.nature == sgs.DamageStruct_Normal then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
				player:turnOver() end
				room:drawCards(player, 3, self:objectName())
				local maxhp = player:getMaxHp()
				local recover = math.min(3 - player:getHp(), maxhp - player:getHp())
				room:recover(player, sgs.RecoverStruct(player, nil, recover))
				local choices = {}
				if not player:hasSkill("bazhen") then
					table.insert(choices, "bazhen")
				end
				if not player:hasSkill("olhuoji") then
					table.insert(choices, "olhuoji")
				end
				if not player:hasSkill("olkanpo") then
					table.insert(choices, "olkanpo")
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice == "bazhen" then
					room:acquireSkill(player, "bazhen")
				elseif choice == "olhuoji" then
					room:acquireSkill(player, "olhuoji")
				elseif choice == "olkanpo" then
					room:acquireSkill(player, "olkanpo")
				end
				player:loseMark("&fcj_Phoenix", 1)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&fcj_Phoenix") >= 2
	end,
}
if not sgs.Sanguosha:getSkill("fcjieniepan") then skills:append(fcjieniepan) end
--2龙印+2凤印：鸾凤
fcluanfeng = sgs.CreateTriggerSkill{
	name = "fcluanfeng",
	--global = true,
	frequency = sgs.Skill_Limited,
	--limit_mark = "@fcluanfeng",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:getMaxHp() >= player:getMaxHp() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local reviver = dying_data.who
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("fcj_simahui_wlfc", self:objectName())
				local maxhp = reviver:getMaxHp()
				local recover = math.min(3 - reviver:getHp(), maxhp - reviver:getHp())
				room:recover(reviver, sgs.RecoverStruct(player, nil, recover))
				local oe = 0
				for i = 0, 4 do
					if not reviver:hasEquipArea(i) then
						reviver:obtainEquipArea(i)
						oe = oe + 1
					end
				end
				local dr = 6 - oe
				if reviver:getHandcardNum() < dr then
					room:drawCards(reviver, dr-reviver:getHandcardNum(), self:objectName())
				end
				player:loseAllMarks("&fcj_Loong")
				player:loseAllMarks("&fcj_Phoenix")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&fcj_Loong") >= 2 and player:getMark("&fcj_Phoenix") >= 2
	end,
}
if not sgs.Sanguosha:getSkill("fcluanfeng") then skills:append(fcluanfeng) end

fcj_simahui:addSkill("chenghao")

fcj_yinshi = sgs.CreateTriggerSkill{
	name = "fcj_yinshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() and ((damage.card and damage.card:isKindOf("TrickCard")) or damage.nature ~= sgs.DamageStruct_Normal)
		and player:getMark("&fcj_Loong") == 0 and player:getMark("&fcj_Phoenix") == 0 and player:getArmor() == nil then
			room:notifySkillInvoked(player, self:objectName()) room:broadcastSkillInvoke(self:objectName())
			return true
		end
	end,
}
fcj_simahui:addSkill(fcj_yinshi)

--41 界马良
fcj_maliang = sgs.General(extension_J, "fcj_maliang", "shu", 3, true)

fcj_zishu = sgs.CreateTriggerSkill{
	name = "fcj_zishu",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive then
					for _, id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							room:addPlayerMark(player, self:objectName()..id)
							room:setCardTip(id,"fcj_zishu")
						end
					end
				elseif player:getPhase() ~= sgs.Player_NotActive and move.reason.m_skillName ~= "fcj_zishu" then
					for _, id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:drawCards(player, 1, self:objectName())
							break
						end
					end
				end
			end
			if move.from and move.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) and (move.from_places:contains(sgs.Player_PlaceTable)
			or move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceJudge))
			and move.to_place == sgs.Player_DiscardPile and player:getPhase() == sgs.Player_NotActive then
				local n = move.card_ids:length()
				room:addPlayerMark(player, "&fcj_zishu", n)
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, card in sgs.list(p:getHandcards()) do
					if p:getMark(self:objectName()..card:getEffectiveId()) > 0 then
						dummy:addSubcard(card:getEffectiveId())
					end
				end
				if dummy:subcardsLength() > 0 then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, p:objectName(), self:objectName(), nil), p)
				end
				dummy:deleteLater()
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("&fcj_zishu") > 0 then
			if player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 3)
				local n = player:getMark("&fcj_zishu")
				room:drawCards(player, n, self:objectName())
			end
			room:setPlayerMark(player, "&fcj_zishu", 0)
		end
		return false
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_maliang:addSkill(fcj_zishu)

fcj_maliang:addSkill("mobileyingyuan")

--42 界马忠
fcj_mazhong = sgs.General(extension_J, "fcj_mazhong", "shu", 4, true)

fcj_fumanCard = sgs.CreateSkillCard{
	name = "fcj_fumanCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("fcj_fuman-PlayClear") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:obtainCard(effect.to, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(), effect.to:objectName(), "fcj_fuman", ""), false)
		room:addPlayerMark(effect.to, "fcj_fuman" .. self:getSubcards():first() .. effect.from:objectName())
		room:addPlayerMark(effect.to, "fcj_fuman-PlayClear")
		room:drawCards(effect.from, 1, "fcj_fuman")
	end,
}
fcj_fumanVS = sgs.CreateOneCardViewAsSkill{
	name = "fcj_fuman",
	view_filter = function(self, card)
		return card:isDamageCard() or card:isKindOf("Weapon")
	end,
	view_as = function(self, card)
		local fmcard = fcj_fumanCard:clone()
		fmcard:addSubcard(card)
		return fmcard
	end,
}
fcj_fuman = sgs.CreateTriggerSkill{
	name = "fcj_fuman",
	view_as_skill = fcj_fumanVS,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
			if card and table.contains(card:getSkillNames(), "fcj_fuman") then
				room:broadcastSkillInvoke("fcj_fuman", math.random(1,2))
			end
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			end
		end
		if card and not card:isKindOf("SkillCard") then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("fcj_fuman" .. card:getId() .. p:objectName()) > 0 then
					room:removePlayerMark(player, "fcj_fuman" .. card:getId() .. p:objectName())
					room:sendCompulsoryTriggerLog(p, "fcj_fuman")
					room:broadcastSkillInvoke("fcj_fuman", math.random(3,4))
					room:drawCards(p, 1, self:objectName())
					room:drawCards(player, 1, self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_mazhong:addSkill(fcj_fuman)



--

--43 界乐进
fcj_yuejin = sgs.General(extension_J, "fcj_yuejin", "wei", 4, true)

fcj_xiaoguo = sgs.CreateTriggerSkill{
	name = "fcj_xiaoguo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, jyj in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if jyj:isNude() or not jyj:canDiscard(jyj, "he") then continue end
			if room:askForSkillInvoke(jyj, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local dis = room:askForDiscard(jyj, self:objectName(), 1, 1, false, true)
				local dis_card = sgs.Sanguosha:getCard(dis:getSubcards():first())
				local victim = room:askForPlayerChosen(jyj, room:getAllPlayers(), self:objectName())
				local n, dest = 0, player
				while true do
					local jxg_card = nil
					if dis_card:isKindOf("BasicCard") then
						jxg_card = room:askForCard(dest, ".Basic", "@fcj_xiaoguo-disBasic", ToData(jyj))
					elseif dis_card:isKindOf("TrickCard") then
						jxg_card = room:askForCard(dest, ".Trick", "@fcj_xiaoguo-disTrick", ToData(jyj))
					elseif dis_card:isKindOf("EquipCard") then
						jxg_card = room:askForCard(dest, ".Equip", "@fcj_xiaoguo-disEquip", ToData(jyj))
					end
					room:broadcastSkillInvoke(self:objectName())
					if not jxg_card or jxg_card == nil then
						room:damage(sgs.DamageStruct(self:objectName(), jyj, dest))
					else
						room:drawCards(jyj, 1, self:objectName())
					end
					n = n + 1
					if n > 1 or victim:isDead() then break end
					dest = victim
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getPhase() == sgs.Player_Finish
	end,
}
fcj_yuejin:addSkill(fcj_xiaoguo)

fcj_xiandeng = sgs.CreateTriggerSkill{
	name = "fcj_xiandeng",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damage, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 then
				room:addPlayerMark(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 1, self:objectName())
				if player:isWounded() then
					room:recover(player, sgs.RecoverStruct(player))
				end
			end
		elseif (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart)
			or (event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive) then
			if player:getMark(self:objectName()) > 0 then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_yuejin:addSkill(fcj_xiandeng)

--44 界文聘
fcj_wenpin = sgs.General(extension_J, "fcj_wenpin", "wei", 4, true)

fcj_jintangCard = sgs.CreateSkillCard{
    name = "fcj_jintangCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    if not sgs.Self:hasFlag("fcj_jintang") then
			return true
		else
			return to_select:getMark("&fcj_jintang_Friends") == 0 and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
	    for _, p in pairs(targets) do
			if not source:hasFlag("fcj_jintang") then
				room:addPlayerMark(p, "&fcj_jintang_Friends")
			else
				room:addPlayerMark(p, "&fcj_jintang_Enemies")
			end
		end
	end,
}
fcj_jintangVS = sgs.CreateZeroCardViewAsSkill{
    name = "fcj_jintang",
	view_as = function()
	    return fcj_jintangCard:clone()
	end,
	response_pattern = "@@fcj_jintang",
}
fcj_jintang = sgs.CreateTriggerSkill{
	name = "fcj_jintang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.RoundStart},
	view_as_skill = fcj_jintangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerMark(p, "&fcj_jintang_Friends", 0)
			room:setPlayerMark(p, "&fcj_jintang_Enemies", 0)
		end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:askForUseCard(player, "@@fcj_jintang", "@fcj_jintang-chooseFriends") --选己方
			room:setPlayerFlag(player, self:objectName()) --区分是选友还是选敌
			room:askForUseCard(player, "@@fcj_jintang", "@fcj_jintang-chooseEnemies") --选敌方
			room:setPlayerFlag(player, "-"..self:objectName())
		end
	end,
}
fcj_jintangDefense = sgs.CreateDistanceSkill{
	name = "#fcj_jintangDefense",
	correct_func = function(self, from, to)
		if (from and from:getMark("&fcj_jintang_Enemies") > 0)
		and (to and to:getMark("&fcj_jintang_Friends") > 0) then
			return 1
		else
			return 0
		end
	end,
}
fcj_wenpin:addSkill(fcj_jintang)
fcj_wenpin:addSkill(fcj_jintangDefense)
extension:insertRelatedSkills("fcj_jintang", "#fcj_jintangDefense")

fcj_zhenwei = sgs.CreateTriggerSkill{
	name = "fcj_zhenwei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard")) and use.to and use.to:length() == 1 then
				for _, p in sgs.qlist(use.to) do
					for _, jwp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if jwp:objectName() == p:objectName() or (use.from and jwp:objectName() == use.from:objectName())
						or jwp:isNude() or not jwp:canDiscard(jwp, "he") then continue end
						if (use.card:isKindOf("Slash") and p:getHp() ~= jwp:getHp())
						or (use.card:isKindOf("TrickCard") and use.card:isRed() and p:getHp() >= jwp:getHp() and jwp:getState() == "online") --避免AI坑队友
						or (use.card:isKindOf("TrickCard") and use.card:isBlack() and p:getHp() <= jwp:getHp()) then
							if room:askForSkillInvoke(jwp, self:objectName(), data) then
								room:askForDiscard(jwp, self:objectName(), 1, 1, false, true)
								room:broadcastSkillInvoke(self:objectName())
								local choice = room:askForChoice(jwp, self:objectName(), "1+2", data)
								if choice == "1" then
									room:drawCards(jwp, 1, self:objectName())
									use.to:removeOne(p)
									use.to:append(jwp)
									data:setValue(use)
								elseif choice == "2" then
									local nullified_list = use.nullified_list
									table.insert(nullified_list, p:objectName())
									use.nullified_list = nullified_list
									if use.from then
										use.from:addToPile(self:objectName(), use.card:getEffectiveId())
									end
									data:setValue(use)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getPile(self:objectName()):length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile(self:objectName()))
					room:obtainCard(p, dummy)
					dummy:deleteLater()
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_wenpin:addSkill(fcj_zhenwei)

--45 界诸葛瑾
fcj_zhugejin = sgs.General(extension_J, "fcj_zhugejin", "wu", 3, true)

fcj_huanshi = sgs.CreateTriggerSkill{
	name = "fcj_huanshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local card
			local ids, disabled_ids,all = sgs.IntList(),sgs.IntList(),sgs.IntList()
			for _,card in sgs.qlist(player:getCards("he"))do
				if player:isCardLimited(card, sgs.Card_MethodResponse) then
					disabled_ids:append(card:getEffectiveId())
				else
					ids:append(card:getEffectiveId())
				end
				all:append(card:getEffectiveId())
			end
			if (not ids:isEmpty()) and room:askForSkillInvoke(player, self:objectName(), data) then
				if judge.who:objectName() ~= player:objectName() and not player:isKongcheng() then
					local jsonLog ={
						"$ViewAllCards",
						judge.who:objectName(),
						player:objectName(),
						table.concat(sgs.QList2Table(player:handCards()),"+"),
						"",
						"",
					}
					room:doNotify(judge.who,sgs.CommandType.S_COMMAND_LOG_SKILL, json.encode(jsonLog))
				end
				judge.who:setTag("fcj_huanshiJudge", data)
				judge.who:setTag("fcj_huanshiFrom", ToData(player))
				room:fillAG(all, judge.who, disabled_ids)
				local card_id = room:askForAG(judge.who, ids, false, self:objectName())
				room:clearAG(judge.who)
				judge.who:removeTag("fcj_huanshiJudge")
				judge.who:removeTag("fcj_huanshiFrom")
				card = sgs.Sanguosha:getCard(card_id)
			end
			if card then
				local obtain = judge.card
				room:broadcastSkillInvoke(self:objectName())
				room:retrial(card, player, judge, self:objectName())
				room:obtainCard(player, obtain)
				local rcard = room:askForExchange(player, self:objectName(), 999, 1, true, "@fcj_huanshi-Recast")
				if rcard then
					room:moveCardTo(rcard, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), ""))
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = player
					log.card_str = rcard:toString()
					room:sendLog(log)
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(rcard:subcardsLength(), "recast")
				end
			end
		end
	end
}
fcj_zhugejin:addSkill(fcj_huanshi)

fcj_hongyuanCard = sgs.CreateSkillCard{
	name = "fcj_hongyuanCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if sgs.Self:hasFlag("fcj_hongyuan") then return to_select:objectName() ~= sgs.Self:objectName() end
		return #targets < sgs.Self:getMark("fcj_hongyuan") and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			if source:getMark("fcj_hongyuan") < 1 then
				room:drawCards(p, 1, "fcj_hongyuan")
			else
				local card = room:askForCardChosen(source, source, "he", "fcj_hongyuan")
				room:obtainCard(p, card, false)
			end
		end
	end,
}
fcj_hongyuanVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_hongyuan",
	view_as = function()
		return fcj_hongyuanCard:clone()
	end,
	response_pattern = "@@fcj_hongyuan",
}
fcj_hongyuan = sgs.CreateTriggerSkill{
	name = "fcj_hongyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.EventPhaseEnd, sgs.CardsMoveOneTime},
	view_as_skill = fcj_hongyuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag(self:objectName()) then
				room:setPlayerFlag(player, "-"..self:objectName())
			end
			if room:askForSkillInvoke(player, "@fcj_hongyuanDC", data) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(player, self:objectName())
				draw.num = draw.num - 1
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw and player:hasFlag(self:objectName()) then
				room:askForUseCard(player, "@@fcj_hongyuan", "@fcj_hongyuan-card1")
				room:setPlayerFlag(player, "-"..self:objectName())
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("fcj_hongyuanUsed") > 0 then
					room:setPlayerMark(p, "fcj_hongyuanUsed", 0)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName()
			and (move.to_place == sgs.Player_PlaceHand
			or ((not move.from or (move.from and move.from:objectName() ~= player:objectName())) and move.to_place == sgs.Player_PlaceEquip))
			and player:getMark("fcj_hongyuanUsed") == 0 then
				local mn = move.card_ids:length()
				if mn >= 2 then
					if room:askForSkillInvoke(player, "@fcj_hongyuanGC", data) then
						room:addPlayerMark(player, "fcj_hongyuanUsed")
						room:setPlayerMark(player, self:objectName(), mn)
						room:askForUseCard(player, "@@fcj_hongyuan", "@fcj_hongyuan-card2:" .. mn)
						room:setPlayerMark(player, self:objectName(), 0)
					end
				end
			end
		end
	end,
}
fcj_zhugejin:addSkill(fcj_hongyuan)

fcj_mingzhe = sgs.CreateTriggerSkill{
	name = "fcj_mingzhe",
	priority = 6,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:getPhase() == sgs.Player_Play then return false end
		if move.to and move.to:objectName() == player:objectName() and not player:hasFlag(self:objectName()) and (move.to_place == sgs.Player_PlaceHand
		or ((not move.from or (move.from and move.from:objectName() ~= player:objectName())) and move.to_place == sgs.Player_PlaceEquip)) then --获得
			local blkcard = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isBlack() then
					blkcard = blkcard + 1
				end
			end
			if blkcard == 0 then return false end
			if room:askForSkillInvoke(player, "@fcj_mingzheGC", data) then
				room:broadcastSkillInvoke(self:objectName())
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isBlack() then
						room:showCard(player, id)
						local pattern = {}
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if not sgs.Sanguosha:isProhibited(player, p, card) and card:isAvailable(player) then
								table.insert(pattern, card:getEffectiveId())
							end
						end
						if #pattern > 0 then
							room:setPlayerFlag(player, self:objectName())
							room:askForUseCard(player, table.concat(pattern, ","), "@fcj_mingzhe_usecard:"..card:objectName(), -1)
							room:setPlayerFlag(player, "-"..self:objectName())
						end
					end
				end
			end
		elseif move.from and move.from:objectName() == player:objectName() and not player:hasFlag(self:objectName())
		and ((move.from_places:contains(sgs.Player_PlaceHand) and (not move.to or (move.to and move.to_place ~= sgs.Player_PlaceHand)))
		or (move.from_places:contains(sgs.Player_PlaceEquip) and (not move.to or (move.to and move.to_place ~= sgs.Player_PlaceEquip)))) then --失去
			local redcard = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isRed() then
					redcard = redcard + 1
				end
			end
			if redcard == 0 then return false end
			if room:askForSkillInvoke(player, "@fcj_mingzheLC", data) then
				room:broadcastSkillInvoke(self:objectName())
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isRed() then
						room:showCard(player, id)
						room:setPlayerFlag(player, self:objectName())
						room:drawCards(player, 1, self:objectName())
						room:setPlayerFlag(player, "-"..self:objectName())
					end
				end
			end
		end
	end,
}
fcj_zhugejin:addSkill(fcj_mingzhe)


--

--46 界贺齐
fcj_heqi = sgs.General(extension_J, "fcj_heqi", "wu", 4, true)

function equip_change_acquire_or_detach_skill(room, player, skill_name_list)
	local skill_name_table = skill_name_list:split("|")
	for _, skill_name in ipairs(skill_name_table) do
		if string.startsWith(skill_name, "-") then
			local real_skill_name = string.gsub(skill_name, "-", "")
			if player:hasSkill(real_skill_name) then
				room:handleAcquireDetachSkills(player, skill_name, true)
			end
		else
			if not player:hasSkill(skill_name) then
				room:handleAcquireDetachSkills(player, skill_name, true)
			end
		end
	end
end
fcj_qizhou = sgs.CreateTriggerSkill{
	name = "fcj_qizhou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.GameStart},
	waked_skills = "f_shenqi, mobilepojun, jieyingg, tenyearxuanfeng, tenyearfenyin, xj_zhangcai, xj_ruxian",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip))
			or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) then
				local suit = {}
				for _, card in sgs.qlist(player:getEquips()) do
					if not table.contains(suit, card:getSuit()) then
						table.insert(suit, card:getSuit())
					end
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				--if #suit >= 0 then --“神骑”效果已体现在原技能中。（当然前提还是有的，得有装备栏（
					room:broadcastSkillInvoke(self:objectName())
				--end
				if #suit == 1 then
					equip_change_acquire_or_detach_skill(room, player, "mobilepojun|-jieyingg|-tenyearxuanfeng|-tenyearfenyin|-ny_10th_ruxian|-ny_10th_zhangcai")
				elseif #suit == 2 then
					equip_change_acquire_or_detach_skill(room, player, "mobilepojun|jieyingg|-tenyearxuanfeng|-tenyearfenyin|-ny_10th_ruxian|-ny_10th_zhangcai")
				elseif #suit == 3 then
					equip_change_acquire_or_detach_skill(room, player, "mobilepojun|jieyingg|tenyearxuanfeng|-tenyearfenyin|-ny_10th_ruxian|-ny_10th_zhangcai")
				elseif #suit == 4 then
					equip_change_acquire_or_detach_skill(room, player, "mobilepojun|jieyingg|tenyearxuanfeng|tenyearfenyin|-ny_10th_ruxian|-ny_10th_zhangcai")
				elseif #suit == 5 then
					equip_change_acquire_or_detach_skill(room, player, "mobilepojun|jieyingg|tenyearxuanfeng|tenyearfenyin|ny_10th_ruxian|ny_10th_zhangcai")
					
				end
				if #suit == 0 then
					equip_change_acquire_or_detach_skill(room, player, "-mobilepojun|-jieyingg|-tenyearxuanfeng|-tenyearfenyin|-ny_10th_ruxian|-ny_10th_zhangcai")
				end
			end
		elseif event == sgs.GameStart then
			local cds = sgs.IntList()
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				local myeq = sgs.Sanguosha:getEngineCard(id)
				if (myeq:isKindOf("FcjhqWeapon") or myeq:isKindOf("FcjhqArmor") or myeq:objectName() == "_fcjhq_dfhorse" or myeq:objectName() == "_fcjhq_ofhorse" or myeq:isKindOf("FcjhqTreasure"))
				and room:getCardPlace(id) ~= sgs.Player_DrawPile then
					cds:append(id)
				end
			end
			if not cds:isEmpty() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke("heqi") --(self:objectName())
				room:shuffleIntoDrawPile(player, cds, self:objectName(), true)
			end
		end
	end,
}

fcj_heqi:addSkill(fcj_qizhou)
fcj_heqi:addRelateSkill("f_shenqi")
fcj_heqi:addRelateSkill("mobilepojun")
fcj_heqi:addRelateSkill("jieyingg")
fcj_heqi:addRelateSkill("tenyearxuanfeng")
fcj_heqi:addRelateSkill("tenyearfenyin")
fcj_heqi:addRelateSkill("ny_10th_zhangcai")
fcj_heqi:addRelateSkill("ny_10th_ruxian")
--==我的装备==--
  --我的武器
FcjhqWeapon = sgs.CreateWeapon{
	name = "_fcjhq_weapon",
	class_name = "FcjhqWeapon",
	range = 4,
	on_install = function()
	end,
	on_uninstall = function()
	end,
}
FcjhqWeapon:clone(sgs.Card_NoSuit, 9):setParent(extension_Cards)
  --我的防具
function ArmorNotNullified(target)
	return target:getMark("Armor_Nullified") < 1
	and #target:getTag("Qinggang"):toStringList() < 1
	and target:getMark("Equips_Nullified_to_Yourself") < 1
end
FcjhqArmors = sgs.CreateTriggerSkill{
	name = "FcjhqArmor",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
			if room:askForCard(player, "jink", "FcjhqArmor-jink:"..use.from:objectName(), sgs.QVariant(), sgs.Card_MethodResponse) then
				room:setEmotion(player, "jink")
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getArmor() and player:getArmor():isKindOf("FcjhqArmor") and ArmorNotNullified(player)
	end,
}
FcjhqArmor = sgs.CreateArmor{
	name = "_fcjhq_armor",
	class_name = "FcjhqArmor",
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, FcjhqArmors, false, true, false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "FcjhqArmor", true, true)
	end,
}
FcjhqArmor:clone(sgs.Card_NoSuit, 10):setParent(extension_Cards)
if not sgs.Sanguosha:getSkill("FcjhqArmor") then skills:append(FcjhqArmors) end
  --我的+1马
local _fcjhq_dfhorse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_NoSuit, 11)
_fcjhq_dfhorse:setObjectName("_fcjhq_dfhorse")
--_fcjhq_dfhorse:setClassName("FcjhqDfhorse")
_fcjhq_dfhorse:setParent(extension_Cards)
  --我的-1马
local _fcjhq_ofhorse = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_NoSuit, 12)
_fcjhq_ofhorse:setObjectName("_fcjhq_ofhorse")
--_fcjhq_ofhorse:setClassName("FcjhqOfhorse")
_fcjhq_ofhorse:setParent(extension_Cards)
  --我的宝物
FcjhqTreasure = sgs.CreateTreasure{
	name = "_fcjhq_treasure",
	class_name = "FcjhqTreasure",
	on_install = function()
	end,
	on_uninstall = function()
	end,
}
FcjhqTreasureMXC = sgs.CreateMaxCardsSkill{
	name = "FcjhqTreasureMXC",
	fixed_func = function(self, player)
		if player and player:getTreasure() ~= nil and player:getTreasure():isKindOf("FcjhqTreasure") then
			return (player:getHp() + player:getMaxHp()) / 2
		end
		return -1
	end,
}
FcjhqTreasure:clone(sgs.Card_NoSuit, 13):setParent(extension_Cards)
if not sgs.Sanguosha:getSkill("FcjhqTreasureMXC") then skills:append(FcjhqTreasureMXC) end
--============--

local function isCardOne(card, name)
	local c_name = sgs.Sanguosha:translate(card:objectName())
	if string.find(c_name, name) then return true end
	return false
end
fcj_shanxiCard = sgs.CreateSkillCard{
	name = "fcj_shanxiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@fcj_shanxi" then return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude() end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude() and sgs.Self:canDiscard(to_select, "he")
	end,
	on_use = function(self, room, source, targets)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@fcj_shanxi" then
			local n = math.min(source:getHp(), targets[1]:getCards("he"):length())
			local dis_num = {}
			for i = 1, n do
				table.insert(dis_num, tostring(i))
			end
			local discard_n = tonumber(room:askForChoice(source, "fcj_shanxi_num", table.concat(dis_num, "+"))) - 1
			local orig_places = sgs.PlaceList()
			local cards = sgs.IntList()
			targets[1]:setFlags("fcj_shanxi_InTempMoving")
			for i = 0, discard_n do
				local id = room:askForCardChosen(source, targets[1], "he", "fcj_shanxi_dis", false, sgs.Card_MethodNone)
				local place = room:getCardPlace(id)
				orig_places:append(place)
				cards:append(id)
				targets[1]:addToPile("#fcj_shanxi", id, false)
			end
			for i = 0, discard_n do
				room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), targets[1], orig_places:at(i), false)
			end
			targets[1]:setFlags("-fcj_shanxi_InTempMoving")
			local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(cards)
			local targetslist = sgs.SPlayerList()
			targetslist:append(targets[1])
			targets[1]:addToPile("fcj_shanxi", dummy, true, targetslist)
			room:addPlayerHistory(source, "#fcj_shanxiCard", -1) --移除此技能卡使用记录，避免影响另一部分于出牌阶段的正常使用
		else
			local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], "he", "fcj_shanxi", false, sgs.Card_MethodDiscard))
			room:throwCard(card, targets[1], source)
			if isCardOne(card, "闪") and not targets[1]:isKongcheng() then
				room:doAnimate(1, source:objectName(), targets[1]:objectName())
				room:showAllCards(targets[1], source)
			elseif not isCardOne(card, "闪") and not source:isKongcheng() then
				room:doAnimate(1, targets[1]:objectName(), source:objectName())
				room:showAllCards(source, targets[1])
			end
		end
	end,
}
fcj_shanxi = sgs.CreateViewAsSkill{
	name = "fcj_shanxi",
	n = 1,
	view_filter = function(self, cards, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@fcj_shanxi" then return to_select:isBlack() and to_select:isKindOf("BasicCard")
		else return to_select:isRed() and to_select:isKindOf("BasicCard") end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local aaa = fcj_shanxiCard:clone()
		aaa:addSubcard(cards[1])
		return aaa
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fcj_shanxiCard") and not player:isNude() and player:canDiscard(player, "he")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@fcj_shanxi"
	end,
}
fcj_shanxiFakeMove = sgs.CreateTriggerSkill{
	name = "fcj_shanxiFakeMove",
	global = true,
	priority = 10,
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local allplayers = room:getAllPlayers()
		for _, p in sgs.qlist(allplayers) do
			if p:hasFlag("fcj_shanxi_InTempMoving") then
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_shanxix = sgs.CreateTriggerSkill{
	name = "fcj_shanxix",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and not player:isNude()
			and player:canDiscard(player, "he") and player:hasSkill("fcj_shanxi") then
				if room:askForSkillInvoke(player, "fcj_shanxi", data) then
					room:askForUseCard(player, "@@fcj_shanxi", "@fcj_shanxix")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getPile("fcj_shanxi"):length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile("fcj_shanxi"))
					room:obtainCard(p, dummy)
					dummy:deleteLater()
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_heqi:addSkill(fcj_shanxi)
if not sgs.Sanguosha:getSkill("fcj_shanxiFakeMove") then skills:append(fcj_shanxiFakeMove) end
if not sgs.Sanguosha:getSkill("fcj_shanxix") then skills:append(fcj_shanxix) end

--47 界·晋司马师
fcj_jinsimashi = sgs.General(extension_J, "fcj_jinsimashi$", "jin", 4, true, false, false, 3)

fcj_jinsimashi:addSkill("jintaoyin")

fcj_yimie = sgs.CreateTriggerSkill{
	name = "fcj_yimie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.DamageComplete},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.from and damage.from:objectName() == player:objectName()
			and player:hasSkill(self:objectName()) and player:getMark(self:objectName().."-Clear") == 0
			and damage.to and damage.to:objectName() ~= player:objectName() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:addPlayerMark(player, self:objectName().."-Clear")
					room:loseHp(player, 1, true, player, self:objectName())
					if damage.to:getHp() > 0 then
						room:setPlayerMark(damage.to, "fcj_yimieMoreDMG", damage.to:getHp())
						local log = sgs.LogMessage()
						log.type = "$fcj_yimieOPM"
						log.from = player
						log.to:append(damage.to)
						log.arg2 = damage.to:getHp()
						room:sendLog(log)
						room:broadcastSkillInvoke(self:objectName())
						damage.damage = damage.damage + damage.to:getHp()
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.DamageComplete then
			if damage.to and damage.to:isAlive() and damage.to:getMark("fcj_yimieMoreDMG") > 0 then
				local n = damage.to:getMark("fcj_yimieMoreDMG")
				room:setPlayerMark(damage.to, "fcj_yimieMoreDMG", 0)
				local recover = math.min(n - damage.to:getHp(), damage.to:getMaxHp() - damage.to:getHp())
				room:recover(player, sgs.RecoverStruct(damage.to, nil, recover))
			end
		end
	end,
}
fcj_jinsimashi:addSkill(fcj_yimie)

fcj_tairan = sgs.CreateTriggerSkill{
	name = "fcj_tairan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if not player:isWounded() and player:getHandcardNum() >= player:getMaxHp() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			if player:isWounded() then
				local recover = player:getMaxHp() - player:getHp()
				room:setPlayerMark(player, "&fcj_tairanR", recover)
				room:recover(player, sgs.RecoverStruct(player, nil, recover))
			end
			if player:getHandcardNum() < player:getMaxHp() then
				local draw = player:getMaxHp() - player:getHandcardNum()
				room:setPlayerMark(player, "&fcj_tairanD", draw) --可是，似乎实际上没什么卵用......
				local card_ids = room:getNCards(draw)
				for _, id in sgs.qlist(card_ids) do
					local cd = sgs.Sanguosha:getCard(id)
					room:setCardFlag(cd, "fcj_tairanD")
				end
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(card_ids)
				room:obtainCard(player, dummy, false)
				dummy:deleteLater()
				for _, id in sgs.qlist(card_ids) do
					room:setCardTip(id, "fcj_tairan")
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getMark("&fcj_tairanR") + player:getMark("&fcj_tairanD") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local r = player:getMark("&fcj_tairanR")
				room:setPlayerMark(player, "&fcj_tairanR", 0)
				local lhp = player:getHp() - 1
				if lhp >= r then
					room:loseHp(player, r, true, player, self:objectName())
				elseif lhp < r and lhp > 0 then
					room:loseHp(player, lhp, true, player, self:objectName())
				end
				if player:isAlive() and not player:isKongcheng() and player:getMark("&fcj_tairanD") > 0 then
					room:setPlayerMark(player, "&fcj_tairanD", 0)
					local rcard = sgs.Sanguosha:cloneCard("slash")
					local d = 0
					for _, c in sgs.qlist(player:getHandcards()) do
						if c:hasFlag("fcj_tairanD") then
							room:setCardFlag(c, "-fcj_tairanD")
							rcard:addSubcard(c:getEffectiveId())
							d = d + 1
						end
					end
					if d > 0 then
						room:broadcastSkillInvoke(self:objectName())
						room:moveCardTo(rcard, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), ""))
						local log = sgs.LogMessage()
						log.type = "#UseCard_Recast"
						log.from = player
						log.card_str = rcard:toString()
						room:sendLog(log)
						player:drawCards(d, "recast")
					end
					rcard:deleteLater()
				end
			end
		end
	end,
}
fcj_jinsimashi:addSkill(fcj_tairan)

fcj_jinsimashi:addSkill("jinruilve")

--48 界·晋杜预
fcj_jinduyu = sgs.General(extension_J, "fcj_jinduyu", "jin", 4, true)

fcj_sanchenCard = sgs.CreateSkillCard{
	name = "fcj_sanchenCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("&fcj_sanchenThree-Clear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:getMark("fcj_zhaotao") == 0 and effect.from:getMark("fcj_sanchen") < 3 then
			room:addPlayerMark(effect.from, "fcj_sanchen")
		end
		if effect.to:getMark("&fcj_sanchenTwo-Clear") > 0 then
			room:setPlayerMark(effect.to, "&fcj_sanchenTwo-Clear", 0)
			room:setPlayerMark(effect.to, "&fcj_sanchenThree-Clear", 1)
		elseif effect.to:getMark("&fcj_sanchenOne-Clear") > 0 then
			room:setPlayerMark(effect.to, "&fcj_sanchenOne-Clear", 0)
			room:setPlayerMark(effect.to, "&fcj_sanchenTwo-Clear", 1)
		else
			room:setPlayerMark(effect.to, "&fcj_sanchenOne-Clear", 1)
		end
		room:drawCards(effect.to, 3, "fcj_sanchen")
		local sc_cards = room:askForDiscard(effect.to, "fcj_sanchen", 3, 3, false, true)
		if sc_cards then
			local b, t, e = 0, 0, 0
			for _, id in sgs.qlist(sc_cards:getSubcards()) do
				local cd = sgs.Sanguosha:getCard(id)
				if cd:isKindOf("BasicCard") then
					b = b + 1
				elseif cd:isKindOf("TrickCard") then
					t = t + 1
				elseif cd:isKindOf("EquipCard") then
					e = e + 1
				end
			end
			if b < 2 and t < 2 and e < 2 then
				room:drawCards(effect.to, 1, "fcj_sanchen")
				room:addPlayerHistory(effect.from, "#fcj_sanchenCard", -1)
			end
		end
	end,
}
fcj_sanchen = sgs.CreateZeroCardViewAsSkill{
	name = "fcj_sanchen",
	view_as = function()
		return fcj_sanchenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#fcj_sanchenCard") < 3 and player:getMark("fcj_sanchenBan-SelfClear") == 0
	end,
}
fcj_jinduyu:addSkill(fcj_sanchen)

fcj_zhaotao = sgs.CreateTriggerSkill{
	name = "fcj_zhaotao",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	waked_skills = "jinpozhu",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_RoundStart)
		or (event == sgs.EventPhaseChanging and data:toPhaseChange().to ~= sgs.Player_NotActive)
		or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("fcj_sanchen") < 3 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("fcj_jinduyu", self:objectName())
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:addPlayerMark(player, self:objectName())
		if not player:hasSkill("jinpozhu") then
			room:acquireSkill(player, "jinpozhu")
		end
		room:setPlayerMark(player, "fcj_sanchenBan-SelfClear", 1)
		player:gainAnExtraTurn()
		room:setPlayerMark(player, "fcj_sanchenBan-SelfClear", 0)
	end,
}
fcj_jinduyu:addSkill(fcj_zhaotao)


--49 界·神刘备
fcj_shenliubei = sgs.General(extension_J, "fcj_shenliubei", "god", 6, true)

fcj_longnu = sgs.CreatePhaseChangeSkill{
	name = "fcj_longnu",
	priority = {3, 2},
	change_skill = true,
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local n = player:getChangeSkillState(self:objectName())
		if player:getPhase() == sgs.Player_Play then
			--龙怒·阳
			if n == 1 then
			    room:setChangeSkillState(player, self:objectName(), 2)
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player, 1, true, player, self:objectName())
				room:drawCards(player, player:getHp(), self:objectName())
				room:acquireSkill(player, "fcj_longnu_yang", false)
				room:filterCards(player, player:getCards("h"), true)
			--龙怒·阴
			elseif n == 2 then
			    room:setChangeSkillState(player, self:objectName(), 1)
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseMaxHp(player, 1)
				room:drawCards(player, player:getMaxHp(), self:objectName())
				room:acquireSkill(player, "fcj_longnu_yin", false)
				room:filterCards(player, player:getCards("h"), true)
			end
		end
	end,
}
fcj_longnu_yang = sgs.CreateFilterSkill{
	name = "fcj_longnu_yang",
	view_filter = function(self, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, card)
		local FireSlash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		FireSlash:setSkillName("fcj_longnu")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(FireSlash)
		return new
	end,
}
fcj_longnu_yin = sgs.CreateFilterSkill{
	name = "fcj_longnu_yin",
	view_filter = function(self, to_select)
		return to_select:isKindOf("TrickCard")
	end,
	view_as = function(self, card)
		local ThunderSlash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
		ThunderSlash:setSkillName("fcj_longnu")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(ThunderSlash)
		return new
	end,
}
fcj_longnu_Buff = sgs.CreateTargetModSkill{
    name = "#fcj_longnu_Buff",
	pattern = "^SkillCard",
	distance_limit_func = function(self, from, card, to)
	    if card and card:isKindOf("FireSlash") and table.contains(card:getSkillNames(), "fcj_longnu") then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, from, card, to)
		if card and card:isKindOf("ThunderSlash") and table.contains(card:getSkillNames(), "fcj_longnu") then
			return 1000
		else
			return 0
		end
	end,
}
fcj_longnu_BuffClear = sgs.CreateTriggerSkill{
    name = "#fcj_longnu_BuffClear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		if player:hasSkill("fcj_longnu_yang") then
			room:detachSkillFromPlayer(player, "fcj_longnu_yang")
		end
		if player:hasSkill("fcj_longnu_yin") then
			room:detachSkillFromPlayer(player, "fcj_longnu_yin")
		end
	end,
	can_trigger = function(self, player)
	    return player and (player:hasSkill("fcj_longnu_yang") or player:hasSkill("fcj_longnu_yin"))
	end,
}
fcj_shenliubei:addSkill(fcj_longnu)
if not sgs.Sanguosha:getSkill("fcj_longnu_yang") then skills:append(fcj_longnu_yang) end
if not sgs.Sanguosha:getSkill("fcj_longnu_yin") then skills:append(fcj_longnu_yin) end
fcj_shenliubei:addSkill(fcj_longnu_Buff)
fcj_shenliubei:addSkill(fcj_longnu_BuffClear)
extension:insertRelatedSkills("fcj_longnu", "#fcj_longnu_Buff")
extension:insertRelatedSkills("fcj_longnu", "#fcj_longnu_BuffClear")

fcj_jieying = sgs.CreateTriggerSkill{
	name = "fcj_jieying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.ChainStateChange, sgs.EventPhaseProceeding, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and not player:isChained() and player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerChained(player)
		elseif event == sgs.ChainStateChange and player:isChained() and player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			return true
		elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
			for _, fcjslb in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isChained() then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(fcjslb, targets, self:objectName(), "joyjieying-invoke")
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerChained(target)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
			local chained = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isChained() then
					chained = chained + 1
				end
			end
			if chained > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player, "&fcj_jieying-Clear", chained)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcj_jieying_MaxCards = sgs.CreateMaxCardsSkill{
	name = "#fcj_jieying_MaxCards",
	extra_func = function(self, player)
		local m, n = 0, 0
		if player:hasSkill("fcj_jieying") then
			m = m + 1
		else
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasSkill("fcj_jieying") then
					m = m + 1
					break
				end
			end
		end
		if m > 0 and player:isChained() then
			n = n + 2
		end
		return n
	end,
}
fcj_jieying_Buff = sgs.CreateTargetModSkill{
    name = "#fcj_jieying_Buff",
	pattern = "^SkillCard",
	distance_limit_func = function(self, from, card, to)
	   if from:hasSkill("fcj_jieying") and from:getPhase() ~= sgs.Player_NotActive and from:getMark("&fcj_jieying-Clear") > 0 then
			return from:getMark("&fcj_jieying-Clear")
		else
			return 0
		end
	end,
	residue_func = function(self, from, card, to)
		if from:hasSkill("fcj_jieying") and from:getPhase() ~= sgs.Player_NotActive and from:getMark("&fcj_jieying-Clear") > 0 then
			return from:getMark("&fcj_jieying-Clear")
		else
			return 0
		end
	end,
}

fcj_shenliubei:addSkill(fcj_jieying)
fcj_shenliubei:addSkill(fcj_jieying_Buff)
fcj_shenliubei:addSkill(fcj_jieying_MaxCards)
extension:insertRelatedSkills("fcj_jieying", "#fcj_jieying_Buff")
extension:insertRelatedSkills("fcj_jieying", "#fcj_jieying_MaxCards")
--

--50 界·神张辽
fcj_shenzhangliao = sgs.General(extension_J, "fcj_shenzhangliao", "god", 4, true)

fcj_shenzhangliao:addSkill("duorui")
fcj_shenzhangliao:addSkill("zhiti")

fcj_leixiVS = sgs.CreateViewAsSkill{
	name = "fcj_leixi",
	n = 1,
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@fcj_leixiSlash" then
			if not to_select:isBlack() or to_select:isEquipped() then return false end
			local ts = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
			ts:addSubcard(to_select:getEffectiveId())
			ts:deleteLater()
			return ts:isAvailable(sgs.Self)
		end
		return false
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@fcj_leixiSlash" and #cards == 1 then
			local ts = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
			for _,c in sgs.list(cards)do
				ts:addSubcard(c)
			end
			ts:setSkillName("fcj_leixi")
			return ts
		elseif pattern=="@@fcj_leixiDuel" and #cards == 0 then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("fcj_leixi")
			return duel
		end
		return nil
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"@@fcj_leixi")
	end,
}
fcj_leixi = sgs.CreateTriggerSkill{
	name = "fcj_leixi",
	view_as_skill = fcj_leixiVS,
	events = {sgs.EventPhaseStart, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local lea = 0
			for i = 0, 4 do
				if not player:hasEquipArea(i) then
					lea = lea + 1
				end
			end
			if lea >= 0 then --至少0个，从牌堆随机获得一张伤害类牌
				local dmg_cards = {}
				for _, id in sgs.qlist(room:getDrawPile()) do
					local dcd = sgs.Sanguosha:getCard(id)
					if dcd:isDamageCard() then
						table.insert(dmg_cards, dcd)
					end
				end
				if #dmg_cards > 0 then
					local dmg_card = dmg_cards[math.random(1, #dmg_cards)]
					room:obtainCard(player, dmg_card)
				end
			end
			if lea >= 1 then --至少1个，黑色手牌当无距雷【杀】
				room:askForUseCard(player, "@@fcj_leixiSlash", "@fcj_leixiSlash-onecard")
			end
			if lea >= 2 then --至少2个，印雷伤【决斗】
				room:askForUseCard(player, "@@fcj_leixiDuel", "@fcj_leixiDuel-zerocard")
			end
			if lea >= 3 then --至少3个，拼点造雷伤
			room:setPlayerMark(player, self:objectName(), 3)
				local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), self:objectName().."-pindian", true, true)
				if dest then
					room:drawCards(player, 1, self:objectName())
					room:drawCards(dest, 1, self:objectName())
					local success = player:pindian(dest, self:objectName(), nil)
					if success then
						room:doAnimate(1, player:objectName(), dest:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:damage(sgs.DamageStruct(self:objectName(), player, dest, 1, sgs.DamageStruct_Thunder))
					end
				end
			end
			if lea >= 4 then --至少4个，直接造雷伤
			room:setPlayerMark(player, self:objectName(), 4)
				local victim = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), self:objectName().."-damage", true, true)
				if victim then --不装了
					room:doAnimate(1, player:objectName(), victim:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), player, victim, 1, sgs.DamageStruct_Thunder))
				end
			end
			if lea == 5 then --☆5个，摸五张牌且本局造成的雷电伤害+1
				room:drawCards(player, 5, self:objectName())
				room:addPlayerMark(player, "&"..self:objectName())
			end
			room:setPlayerMark(player, self:objectName(), 0)
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from then
				if damage.nature ~= sgs.DamageStruct_Thunder and damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == self:objectName() then
					damage.nature = sgs.DamageStruct_Thunder
					data:setValue(damage)
				end
				if damage.nature == sgs.DamageStruct_Thunder and damage.from:objectName() == player:objectName() and player:getMark("&"..self:objectName()) > 0 then
					local n = player:getMark("&"..self:objectName())
					damage.damage = damage.damage + n
					data:setValue(damage)
				end
			end
		end
	end,
}

fcj_leixiSlashBuff = sgs.CreateTargetModSkill{
    name = "#fcj_leixiSlashBuff",
	distance_limit_func = function(self, player, card)
	    if card and card:isKindOf("ThunderSlash") and table.contains(card:getSkillNames(), "fcj_leixi") then
			return 1000
		else
			return 0
		end
	end,
}

fcj_shenzhangliao:addSkill(fcj_leixi)
fcj_shenzhangliao:addSkill(fcj_leixiSlashBuff)
extension:insertRelatedSkills("fcj_leixi", "#fcj_leixiSlashBuff")


--11 OL界赵云-自改版
fcb_oljiezhaoyun = sgs.General(extension_J, "fcb_oljiezhaoyun", "shu", 4, true)

fcb_oljiezhaoyun:addSkill("ollongdan")

fcbyajiaoCard = sgs.CreateSkillCard{
	name = "fcbyajiaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    room:obtainCard(targets[1], self, true)
	end,
}
fcbyajiaoVS = sgs.CreateOneCardViewAsSkill{
    name = "fcbyajiao",
	filter_pattern = ".|.|.|hand!",
	view_as = function(self, card) 
		local yj_card = fcbyajiaoCard:clone()
		yj_card:addSubcard(card)
		yj_card:setSkillName(self:objectName())
		return yj_card
	end,
	response_pattern = "@@fcbyajiao",
}
fcbyajiao = sgs.CreateTriggerSkill{
	name = "fcbyajiao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	view_as_skill = fcbyajiaoVS,
	on_trigger = function(self, event, player, data)
       	local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			local resp = data:toCardResponse()
			if resp.m_isUse then
				card = resp.m_card
			end
		end
		if card and (card:isKindOf("BasicCard") or card:isKindOf("Nullification")) and card:getHandlingMethod() == sgs.Card_MethodUse then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local ids = room:getNCards(1, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local id = ids:first()
				local yj_card = sgs.Sanguosha:getCard(id)
				room:getThread():delay()
				if yj_card:isKindOf("BasicCard") then
					room:obtainCard(player, yj_card)
					room:askForUseCard(player, "@@fcbyajiao", "@fcbyajiao-card")
				elseif yj_card:isKindOf("TrickCard") then
					local victim = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "@fcbyajiao-throw", true, true)
					if victim and not victim:isAllNude() and player:canDiscard(victim, "hej") then
						local tr_card = room:askForCardChosen(player, victim, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
						room:broadcastSkillInvoke(self:objectName())
						room:throwCard(tr_card, victim, player)
					end
				elseif yj_card:isKindOf("EquipCard") then
					player:setTag("fcbyajiaoCard", ToData(yj_card))
					local beneficiary = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName().."equip", "fcbyajiaoEquipUse:" .. yj_card:objectName(), true, true)
					player:removeTag("fcbyajiaoCard")
					if beneficiary ~= nil then
						local equip_index = yj_card:getRealCard():toEquipCard():location()
						if beneficiary:hasEquipArea(equip_index) then
							room:broadcastSkillInvoke(self:objectName())
							room:useCard(sgs.CardUseStruct(yj_card, beneficiary, beneficiary))
						else
							room:obtainCard(beneficiary, yj_card)
						end
					end
				end
			end
		end
	end,
}
fcb_oljiezhaoyun:addSkill(fcbyajiao)

--

--12 ☆SP赵云-自改版
fcb_starspzhaoyun = sgs.General(extension, "fcb_starspzhaoyun", "qun", 4, true)

fcb_starspzhaoyun:addSkill("longdan")

fcbpozhen = sgs.CreateTriggerSkill{
	name = "fcbpozhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardResponded, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
		    local resp = data:toCardResponse()
		    if resp.m_card and table.contains(resp.m_card:getSkillNames(), "longdan") and resp.m_who then
				local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
			    if player:askForSkillInvoke(self:objectName(), _data) then
			        if not resp.m_who:isNude() then
						local card = room:askForCardChosen(player, resp.m_who, "he", self:objectName(), false, sgs.Card_MethodDiscard, sgs.IntList(), true)
						if card >= 0 then
			        		room:broadcastSkillInvoke(self:objectName(), 1)
							room:throwCard(card, resp.m_who, player)
						else
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:drawCards(player, 1, self:objectName())
						end
					else
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:drawCards(player, 1, self:objectName())
					end
			    end
		    end
		else
		    local use = data:toCardUse()
		    if use.card and table.contains(use.card:getSkillNames(), "longdan") then
		        for _, p in sgs.qlist(use.to) do
		            local _data = sgs.QVariant()
					_data:setValue(p)
					p:setFlags("fcbpozhenTarget")
		            local invoke = player:askForSkillInvoke(self:objectName(), _data)
		            p:setFlags("-fcbpozhenTarget")
		            if invoke then
		                if p:isNude() then
						room:broadcastSkillInvoke(self:objectName(), 2) room:drawCards(player, 1, self:objectName()) continue end
						local card = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard, sgs.IntList(), true)
						if card >= 0 then
			        		room:broadcastSkillInvoke(self:objectName(), 1)
							room:throwCard(card, p, player)
						else
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:drawCards(player, 1, self:objectName())
						end
		            end
		        end
		    end
		end
	end,
}
fcb_starspzhaoyun:addSkill(fcbpozhen)

--13 界吕布-主公版
fcb_lordjielvbu = sgs.General(extension_J, "fcb_lordjielvbu$", "qun", 4, true)

fcb_lordjielvbu:addSkill("wushuang")

fcbmoji = sgs.CreateViewAsEquipSkill{
	name = "fcbmoji",
	view_as_equip = function(self, player)
		if player:getWeapon() == nil then
			return "__fcb_moji"
		else
			return ""
		end
	end,
}
fcb_lordjielvbu:addSkill(fcbmoji)
--伪实现：虚拟装备
FcbMoji = sgs.CreateWeapon{
	name = "__fcb_moji",
	class_name = "FcbMoji",
	range = 4,
	on_install = function()
	end,
	on_uninstall = function()
	end,
}
FcbMoji:clone(sgs.Card_NoSuit, 0):setParent(extension)

fcb_lordjielvbu:addSkill("sp_mengguan")

fcbshenwuCard = sgs.CreateSkillCard{
	name = "fcbshenwuCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("fcbshenwu") and to_select:objectName() ~= sgs.Self:objectName()
		and not to_select:hasFlag("fcbshenwuInvoked")
	end,
	on_use = function(self, room, source, targets)
		local lvbu = targets[1]
		if lvbu:hasLordSkill("fcbshenwu") then
			room:setPlayerFlag(lvbu, "fcbshenwuInvoked")
			room:notifySkillInvoked(lvbu, "fcbshenwu")
			lvbu:obtainCard(self)
			local lvbus = room:getLieges("qun", lvbu)
			if lvbus:isEmpty() then
				room:setPlayerFlag(source, "Forbidfcbshenwu")
			end
		end
	end,
}
fcbshenwuVS = sgs.CreateOneCardViewAsSkill{
	name = "fcbshenwuVS&",
	filter_pattern = "Slash,Duel,Weapon",
	view_as = function(self, card)
		local acard = fcbshenwuCard:clone()
		acard:addSubcard(card)
		return acard
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("Forbidfcbshenwu")
		end
	end,
}
fcbshenwu = sgs.CreateTriggerSkill{
	name = "fcbshenwu$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStart, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if event == sgs.TurnStart or (event == sgs.EventAcquireSkill and data:toString() == "fcbshenwu") then 
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if not p:hasSkill("fcbshenwuVS") then
					room:attachSkillToPlayer(p, "fcbshenwuVS")
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "fcbshenwu" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if p:hasSkill("fcbshenwuVS") then
					room:detachSkillFromPlayer(p, "fcbshenwuVS", true)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("Forbidfcbshenwu") then
				room:setPlayerFlag(player, "-Forbidfcbshenwu")
			end
			local players = room:getOtherPlayers(player)
			for _, p in sgs.qlist(players) do
				if p:hasFlag("fcbshenwuInvoked") then
					room:setPlayerFlag(p, "-fcbshenwuInvoked")
				end
			end
		end
	end,
}
fcb_lordjielvbu:addSkill(fcbshenwu)
if not sgs.Sanguosha:getSkill("fcbshenwuVS") then skills:append(fcbshenwuVS) end
--

--14 SP公孙瓒-主公版
fcb_lordspgongsunzan = sgs.General(extension, "fcb_lordspgongsunzan$", "qun", 4, true)

fcbyicong = sgs.CreateDistanceSkill{
	name = "fcbyicong",
	correct_func = function(self, from, to)
		local whitehorse = 0
		if from:hasSkill(self:objectName()) then
			whitehorse = whitehorse - 1
		end
		if to:hasSkill(self:objectName()) then
			whitehorse = whitehorse + 1
		end
		return whitehorse
	end,
}
fcb_lordspgongsunzan:addSkill(fcbyicong)

fcbgaolou = sgs.CreateTriggerSkill{
	name = "fcbgaolou$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("EquipCard") then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:drawCards(player, 1, self:objectName())
			if use.card:isKindOf("Armor") and player:isWounded() then
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasLordSkill(self:objectName())
	end,
}
fcbgaolouMXC = sgs.CreateMaxCardsSkill{
	name = "fcbgaolouMXC",
	extra_func = function(self, player)
		local quns = 0
		if player:hasLordSkill("fcbgaolou") then
			quns = quns + 1
			for _, q in sgs.qlist(player:getAliveSiblings()) do
				if q:getKingdom() == "qun" and q:getArmor() ~= nil then
					quns = quns + 1
				end
			end
		end
		return quns
	end,
}
fcb_lordspgongsunzan:addSkill(fcbgaolou)
if not sgs.Sanguosha:getSkill("fcbgaolouMXC") then skills:append(fcbgaolouMXC) end

sp_shenzhugeliang_ub = sgs.General(extension, "sp_shenzhugeliang_ub", "god", 7, true, false, false, 3)


--解禁包：FC·SP神诸葛亮
sp_yaozhi_ubCard = sgs.CreateSkillCard{
    name = "sp_yaozhi_ubCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		local id = ids:first()
		local cd = sgs.Sanguosha:getCard(id)
		if cd:isKindOf("BasicCard") and not source:hasFlag("sp_yaozhi_ub_Basicget") then
			room:setPlayerFlag(source, "sp_yaozhi_ub_Basicget")
		elseif cd:isKindOf("TrickCard") and not source:hasFlag("sp_yaozhi_ub_Trickget") then
			room:setPlayerFlag(source, "sp_yaozhi_ub_Trickget")
		elseif cd:isKindOf("EquipCard") and not source:hasFlag("sp_yaozhi_ub_Equipget") then
			room:setPlayerFlag(source, "sp_yaozhi_ub_Equipget")
		end
		room:obtainCard(source, cd, true)
		local dest = room:askForPlayerChosen(source, room:getAllPlayers(), "sp_yaozhi_ub", "sp_yaozhi_ub_giveCard", true, true) --不选就默认为将一张手牌交给自己
		if dest then
			local card = room:askForExchange(source, "sp_yaozhi_ub", 1, 1, true, "#sp_yaozhi_ub:".. dest:getGeneralName())
			if card then
				room:obtainCard(dest, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, dest:objectName(), source:objectName(), self:objectName(), ""), false)
			end
			room:setPlayerFlag(dest, "sp_yaozhi_ubTarget")
			local players = sgs.SPlayerList()
			players:append(dest)
			local destt = room:askForPlayerChosen(source, players, "sp_yaozhi_ubX", "sp_yaozhi_ub_putGodIncantation", true, true)
			if destt then
				room:loseMaxHp(source, 1)
				room:broadcastSkillInvoke("sp_yaozhi_ub")
				local GI = room:askForCardChosen(source, destt, "he", "sp_yaozhi_ub")
				destt:addToPile("GodIncantation_ub", GI)
			end
		end
		room:addPlayerMark(source, "sp_yaozhi_ubUsed")
	end,
}
sp_yaozhi_ub = sgs.CreateZeroCardViewAsSkill{
    name = "sp_yaozhi_ub",
	view_as = function()
		return sp_yaozhi_ubCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("sp_yaozhi_ubUsed") < 3 + player:getMark("&sp_yaozhi_ubAdd")
	end,
}
sp_yaozhi_ubAddandClear = sgs.CreateTriggerSkill{
	name = "#sp_yaozhi_ubAddandClear",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local x = 3 - 1 + player:getMark("&sp_yaozhi_ubAdd")
			if room:askForSkillInvoke(player, "sp_yaozhi_ub", ToData("sp_yaozhi_ubGX:"..x)) then
				room:broadcastSkillInvoke("sp_yaozhi_ub")
				local stars = room:getNCards(x, false)
				room:askForGuanxing(player, stars)
			end
		elseif event == sgs.EventPhaseEnd and player:getMark("sp_yaozhi_ubUsed") > 0 then
			if ((player:hasFlag("sp_yaozhi_ub_Basicget") and player:hasFlag("sp_yaozhi_ub_Trickget") and player:hasFlag("sp_yaozhi_ub_Equipget"))
			or (player:getMark("sp_yaozhi_ubUsed") >= 3 + player:getMark("&sp_yaozhi_ubAdd")
			and ((player:hasFlag("sp_yaozhi_ub_Basicget") and not player:hasFlag("sp_yaozhi_ub_Trickget") and not player:hasFlag("sp_yaozhi_ub_Equipget"))
			or (not player:hasFlag("sp_yaozhi_ub_Basicget") and player:hasFlag("sp_yaozhi_ub_Trickget") and not player:hasFlag("sp_yaozhi_ub_Equipget"))
			or (not player:hasFlag("sp_yaozhi_ub_Basicget") and not player:hasFlag("sp_yaozhi_ub_Trickget") and player:hasFlag("sp_yaozhi_ub_Equipget"))))) then
				room:sendCompulsoryTriggerLog(player, "sp_yaozhi_ub")
				room:broadcastSkillInvoke("sp_yaozhi_ub")
				room:addPlayerMark(player, "&sp_yaozhi_ubAdd")
			end
			room:setPlayerMark(player, "sp_yaozhi_ubUsed", 0)
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("sp_yaozhi_ub") and player:getPhase() == sgs.Player_Play
	end,
}


sp_shenzhugeliang_ub:addSkill(sp_yaozhi_ub)
sp_shenzhugeliang_ub:addSkill(sp_yaozhi_ubAddandClear)
extension_J:insertRelatedSkills("sp_yaozhi_ub", "#sp_yaozhi_ubAddandClear")



sp_shenqi_ubCard = sgs.CreateSkillCard{
	name = "sp_shenqi_ubCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:getPile("GodIncantation_ub"):length() > 0
	end,
	on_use = function(self, room, source, targets)
	    room:removePlayerMark(source, "@sp_shenqi_ub")
		local dest = targets[1]
		local n = dest:getPile("GodIncantation_ub"):length()
		room:loseMaxHp(source, n)
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:deleteLater()
		dummy:addSubcards(dest:getPile("GodIncantation_ub"))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "sp_shenqi_ub", nil)
		room:throwCard(dummy, reason, nil)
		local choice = room:askForChoice(source, "sp_shenqi_ub", "1+2", ToData(dest))
		if choice == "1" then
			room:broadcastSkillInvoke("sp_shenqi_ub", 1)
			local x = (n + 1) / 2
			room:drawCards(dest, x, "sp_shenqi_ub")
			local recover = sgs.RecoverStruct()
			local y = n / 2
			recover.who = dest
			recover.recover = y
			room:recover(dest, recover)
		else
			local choicee = room:askForChoice(source, "sp_shenqi_ub_zhuxie", "normal+fire+thunder+ice+poison", ToData(dest))
			if choicee == "normal" then
				room:broadcastSkillInvoke("sp_shenqi_ub", 2)
				room:damage(sgs.DamageStruct("sp_shenqi_ub_zhuxie", source, dest, n, sgs.DamageStruct_Normal))
			elseif choicee == "fire" then
				room:broadcastSkillInvoke("sp_shenqi_ub", 2)
				room:damage(sgs.DamageStruct("sp_shenqi_ub_zhuxie", source, dest, n, sgs.DamageStruct_Fire))
			elseif choicee == "thunder" then
				room:broadcastSkillInvoke("sp_shenqi_ub", 2)
				room:damage(sgs.DamageStruct("sp_shenqi_ub_zhuxie", source, dest, n, sgs.DamageStruct_Thunder))
			elseif choicee == "ice" then
				room:broadcastSkillInvoke("sp_shenqi_ub", 2)
				room:damage(sgs.DamageStruct("sp_shenqi_ub_zhuxie", source, dest, n, sgs.DamageStruct_Ice))
			elseif choicee == "poison" then
				room:broadcastSkillInvoke("sp_shenqi_ub", 2)
				room:damage(sgs.DamageStruct("sp_shenqi_ub_zhuxie", source, dest, n, sgs.DamageStruct_Poison))
			end
		end
	end,
}
sp_shenqi_ubVS = sgs.CreateZeroCardViewAsSkill{
    name = "sp_shenqi_ub",
	view_as = function()
		return sp_shenqi_ubCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sp_shenqi_ub") > 0
	end,
}
sp_shenqi_ub = sgs.CreateTriggerSkill{
	name = "sp_shenqi_ub",
	frequency = sgs.Skill_Limited,
	limit_mark = "@sp_shenqi_ub",
	view_as_skill = sp_shenqi_ubVS,
	on_trigger = function()
	end,
}

sp_shenzhugeliang_ub:addSkill(sp_shenqi_ub)

mb_miheng = sgs.General(extension, "mb_miheng", "qun", 3, true)

mbkuangcai = sgs.CreatePhaseChangeSkill{
	name = "mbkuangcai",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local data = sgs.QVariant()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerMark(player, "&mbkuangcai", 5)
		end
	end,
}
mbkuangcaiBuff = sgs.CreateTriggerSkill{
	name = "#mbkuangcaiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and not card:isKindOf("SkillCard") then
				room:sendCompulsoryTriggerLog(player, "mbkuangcai")
				room:broadcastSkillInvoke("mbkuangcai")
				room:drawCards(player, 1, "mbkuangcai")
				player:loseMark("&mbkuangcai", 1)
				if player:getMark("&mbkuangcai") == 0 then
					room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
				end
			end
		else
			room:setPlayerMark(player, "&mbkuangcai", 0)
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("mbkuangcai") and player:getMark("&mbkuangcai") > 0 and player:getPhase() == sgs.Player_Play
	end,
}
mbkuangcaiCardBuff = sgs.CreateTargetModSkill{
	name = "#mbkuangcaiCardBuff",
	pattern = "Card",
	distance_limit_func = function(self, from, card, to)
		local x = 0
		if from:hasSkill("mbkuangcai") and from:getMark("&mbkuangcai") > 0 and card and not card:isKindOf("SkillCard") then
			x = x + 1000
		end
		return x
	end,
	residue_func = function(self, from, card, to)
		local y = 0
		if from:hasSkill("mbkuangcai") and from:getMark("&mbkuangcai") > 0 and card and not card:isKindOf("SkillCard") then
			y = y + 1000
		end
		return y
	end,
}
mb_miheng:addSkill(mbkuangcai)
mb_miheng:addSkill(mbkuangcaiBuff)
mb_miheng:addSkill(mbkuangcaiCardBuff)
extension_J:insertRelatedSkills("mbkuangcai", "#mbkuangcaiBuff")
extension_J:insertRelatedSkills("mbkuangcai", "#mbkuangcaiCardBuff")

mb_miheng:addSkill("mobileshejian")


f_shenguojia = sgs.General(extension_J, "f_shenguojia", "god", 3, true)


f_huishiCard = sgs.CreateSkillCard{
    name = "f_huishiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local suits = {}
		while (source:isAlive() and source:getMaxHp() < 10)do		
			local judge = sgs.JudgeStruct()
			judge.who = source
			judge.reason = self:getSkillName()
			judge.pattern = ".|"..table.concat(suits,",")
			judge.throw_card = false
			judge.good = false
			room:judge(judge)
			table.insert(suits,judge.card:getSuitString())
			local id = judge.card:getEffectiveId()
			if room:getCardPlace(id)==sgs.Player_PlaceJudge then
				self:addSubcard(id)
			end
			
			if judge:isGood() and source:getMaxHp() < 10
			and source:isAlive() and source:askForSkillInvoke("@f_huishi_continue") then
				local choice = room:askForChoice(source, "@f_huishiAdd", "mhp+hp")
				if choice == "mhp" then
					room:gainMaxHp(source, 1, "f_huishi")
				else
					room:recover(source, sgs.RecoverStruct(source))
				end
			else
				break
			end
		end
		
		if source:isAlive() and self:subcardsLength() > 0 then
			room:fillAG(self:getSubcards(),source)
			local to = room:askForPlayerChosen(source,room:getAlivePlayers(),"f_huishi","f_huishi-give",true,false)
			room:clearAG(source)
			if to then
				room:doAnimate(1,source:objectName(),to:objectName())
				room:giveCard(source,to,self,"f_huishi",true)
				if to:isAlive() and source:isAlive() then
					local hand = to:getHandcardNum()
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getHandcardNum() > hand then return end
					end
					room:loseMaxHp(source,1,"f_huishi")
					return
				end
			end
			local can_invoke = true
		    for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			    if source:getHandcardNum() <= p:getHandcardNum() then
				    can_invoke = false
				    break
			    end
		    end
		    if can_invoke then
		        --room:loseMaxHp(source, 1)
				local choice = room:askForChoice(source, "@f_huishiLose", "mhp+hp")
				if choice == "mhp" then
					room:loseMaxHp(source, 1)
				else
					room:loseHp(source, 1, true, source, "f_huishi")
				end
		    end
		end
		room:throwCard(self,nil)
	end,
}
f_huishi = sgs.CreateZeroCardViewAsSkill{
    name = "f_huishi",
	view_as = function()
		return f_huishiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_huishiCard") and player:getMaxHp() < 10
	end,
}

f_shenguojia:addSkill(f_huishi)
f_shenguojia:addSkill("godtianyi")
f_shenguojia:addSkill("huishii")

f_shenxunyu = sgs.General(extension_J, "f_shenxunyu", "god", 3, true)

f_tianzuo = sgs.CreateTriggerSkill{
	name = "f_tianzuo",
	events = {sgs.GameStart,sgs.CardEffected},
	frequency = sgs.Skill_Compulsory,
	waked_skills = "_qizhengxiangsheng",
	on_trigger = function(self,event,player,data,room)
		if event == sgs.GameStart then
			local cards = sgs.IntList()
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
				if sgs.Sanguosha:getEngineCard(id):isKindOf("Qizhengxiangsheng") and room:getCardPlace(id) ~= sgs.Player_DrawPile then
					cards:append(id)
				end
			end
			if not cards:isEmpty() then
				room:sendCompulsoryTriggerLog(player,self)
				room:shuffleIntoDrawPile(player,cards,self:objectName(),true)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if not effect.card:isKindOf("Qizhengxiangsheng") then return false end
			local log = sgs.LogMessage()
			log.type = "#WuyanGooD"
			log.from = player
			log.to:append(effect.from)
			log.arg = effect.card:objectName()
			log.arg2 = self:objectName()
			room:sendLog(log)
			player:peiyin(self)
			room:notifySkillInvoked(player,self:objectName())
			return true	
		end
		return false
	end
}
f_tianzuo_buff = sgs.CreateTriggerSkill{
	name = "#f_tianzuo_buff",
	events = {sgs.CardEffected},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		local effect = data:toCardEffect()
		if not effect.card:isKindOf("Qizhengxiangsheng") then return false end
		if (effect.nullified) then
			local log = sgs.LogMessage()
			log.type = "#CardNullified";
			log.from = effect.to;
			log.card_str = effect.card:toString()
			room:sendLog(log)
			return true;
		end
		if not effect.offset_card then
			effect.offset_card = room:isCanceled(effect)
		end
		if (effect.offset_card) then
			data.setValue(effect)
			if (not room:getThread():trigger(sgs.CardOffset, room, effect.from, data))then
				return true;
			end
		end
		room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data);
		local data = sgs.QVariant()
		data:setValue(effect.to)
		local choice
		local invoke = false
		for _, p in sgs.qlist(room:findPlayersBySkillName("f_tianzuo")) do
			if room:askForSkillInvoke(p, "f_tianzuo", data) then
				room:showAllCards(effect.to, p)
				choice = room:askForChoice(p,"_qizhengxiangsheng","zhengbing="..effect.to:objectName().."+qibing="..effect.to:objectName(),data)
				invoke = true
			end
		end
		if invoke then
			local log = sgs.LogMessage()
			log.type = "#QizhengxiangshengLog"
			log.from = effect.rom
			log.to:append(effect.to)
			log.arg = "_qizhengxiangsheng_"..choice:split("=")[1]
			room:sendLog(log,effect.from)
			local card = room:askForCard(effect.to,"Slash,Jink","@_qizhengxiangsheng-card:",data,sgs.Card_MethodResponse,effect.from,false,"",false,effect.card)
			room:sendLog(log,room:getOtherPlayers(effect.from,true))
			if choice:startsWith("zhengbing") then
				if not(card and card:isKindOf("Jink")) then
					if effect.from:isDead() or effect.to:isNude() then return end
					local id = room:askForCardChosen(effect.from,effect.to,"he","_qizhengxiangsheng")
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,effect.from:objectName())
					room:obtainCard(effect.from,sgs.Sanguosha:getCard(id),reason,false)
				end
			elseif choice:startsWith("qibing") then
				if not(card and card:isKindOf("Slash")) then
					room:damage(sgs.DamageStruct(effect.card,effect.from,effect.to))
				end
			end
			room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_lingce = sgs.CreateTriggerSkill{
	name = "f_lingce",
	events = sgs.CardUsed,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,player)
		return player
	end,
	on_trigger = function(self,event,player,data,room)
		local use = data:toCardUse()
		if not use.card:isKindOf("TrickCard") or use.card:isVirtualCard() then return false end
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:isDead() or not p:hasSkill(self) then continue end
			local names = p:property("SkillDescriptionRecord_dinghan"):toString():split("+")
			if use.card:isZhinangCard() or use.card:isKindOf("Collateral") or use.card:isKindOf("Snatch") or use.card:isKindOf("IronChain") or
				(p:hasSkill("dinghan",true) and table.contains(names,use.card:objectName())) then
				room:sendCompulsoryTriggerLog(p,self)
				p:drawCards(1,self:objectName())
			end
		end
		return false
	end
}


f_shenxunyu:addSkill(f_tianzuo)
f_shenxunyu:addSkill(f_tianzuo_buff)
extension_J:insertRelatedSkills("f_tianzuo", "#f_tianzuo_buff")
f_shenxunyu:addSkill(f_lingce)
f_shenxunyu:addSkill("dinghan")



f_shensunce = sgs.General(extension_J, "f_shensunce", "god", 6, true, false, false, 1)


imbaCard = sgs.CreateSkillCard{
	name = "imbaCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMaxHp() > 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local yuji = targets[1]
		room:loseMaxHp(yuji, 1)
		yuji:gainMark("&sscybpingding")
		room:loseMaxHp(source, 1)
	end,
}
--yingba
imba = sgs.CreateZeroCardViewAsSkill{
	name = "imba",
	view_as = function()
		return imbaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#imbaCard")
	end,
}
imbaMaxDistance = sgs.CreateTargetModSkill{
    name = "#imbaMaxDistance",
	pattern = "Card",
	distance_limit_func = function(self, from, card, to)
	    local n = 0
		if from:hasSkill("imba") and to and to:getMark("&sscybpingding") > 0 then
			n = n + 1000
		end
		return n
	end,
}
imbaNoLimit = sgs.CreateTargetModSkill{
	name = "#imbaNoLimit",
	pattern = "Card",
	residue_func = function(self, from, card, to)
		local n = 0
		if from:hasSkill("imba") and to and to:getMark("&sscybpingding") > 0 then
			local m = to:getMark("&sscybpingding")
			n = n + m
		end
		return n
	end,
}


f_pinghe = sgs.CreateTriggerSkill{
	name = "f_pinghe",
	events = {sgs.DamageInflicted, sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if not damage.from or damage.from == player then return false end
			if player:isKongcheng() or player:getMaxHp() < 2 then return false end
			room:sendCompulsoryTriggerLog(player,self)
			room:loseMaxHp(player,1,"f_pinghe")
			if player:isAlive() and not player:isKongcheng() then
				local hands = player:handCards()
				if not room:askForYiji(player,hands,"f_pinghe",false,false,false,1) then
					local c = player:getRandomHandCard()
					local tos = room:getOtherPlayers(player)
					local to = tos:at(math.random(0,tos:length() - 1))
					room:giveCard(player,to,c,self:objectName())
				end
				if player:isAlive() and player:hasSkill("imba",true) and damage.from:isAlive() then
					damage.from:gainMark("&sscybpingding")
				end
			end
			return true
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			if player:getHp() > 1 then
				room:sendCompulsoryTriggerLog(player, "f_pinghe")
				room:broadcastSkillInvoke("f_pinghe")
				room:loseHp(player, 1, true, player, "f_pinghe")
				room:drawCards(player, player:getHp(), "f_pinghe")
			end
		end
	end
}

f_pinghe_cardmax = sgs.CreateMaxCardsSkill{
    name = "#f_pinghe_cardmax",
    fixed_func = function(self,player)
		local n = -1
		if player:hasSkill("f_pinghe") then
			n = math.max(n,player:getLostHp())
		end
		return n
	end
}


f_shensunce:addSkill(imba)
f_shensunce:addSkill(imbaMaxDistance)
f_shensunce:addSkill(imbaNoLimit)
extension_J:insertRelatedSkills("imba", "#imbaMaxDistance")
extension_J:insertRelatedSkills("imba", "#imbaNoLimit")
f_shensunce:addSkill("fuhaisc")
f_shensunce:addSkill(f_pinghe)
f_shensunce:addSkill(f_pinghe_cardmax)
extension_J:insertRelatedSkills("f_pinghe", "#f_pinghe_cardmax")

ty_shenmachao = sgs.General(extension_J, "ty_shenmachao", "god", 4, true)

tyshoulistart = sgs.CreateTriggerSkill{
    name = "#tyshoulistart",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local nextp = player:getNextAlive()
        local cards = sgs.IntList()
		for _,id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getEngineCard(id):isKindOf("Horse") then
				cards:append(id)
			end
		end
		for _,id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getEngineCard(id):isKindOf("Horse") then
				cards:append(id)
			end
		end
        room:sendCompulsoryTriggerLog(player, "tyshouli")
        room:broadcastSkillInvoke("tyshouli")
        while(true) do
			for _,id in sgs.qlist(cards) do
				if nextp:canUse(sgs.Sanguosha:getEngineCard(id), nextp, true) then
					cards:removeOne(id)
					local use = sgs.CardUseStruct(sgs.Sanguosha:getEngineCard(id), nextp, nextp)
					room:useCard(use)
					break
				end
			end
            room:setPlayerMark(nextp, "shouliget", 1)
            nextp = nextp:getNextAlive()
            if nextp:getMark("shouliget") > 0 then break end
        end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			room:setPlayerMark(p, "shouliget", 0)
		end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("tyshouli")
    end,
}
tyshouli = sgs.CreateViewAsSkill
{
    name = "tyshouli",
    n = 1,
    expand_pile = "/Horse/tyshouli",
    view_filter = function(self, selected, to_select)
        if sgs.Self:getHandcards():contains(to_select) then return false end
        if #selected >= 1 then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if (not to_select:isKindOf("OffensiveHorse")) then return false end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("tyshouli")
            slash:addSubcard(to_select)
            slash:deleteLater()
            return not sgs.Self:isLocked(slash)
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" then
                if (not to_select:isKindOf("OffensiveHorse")) then return false end
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                slash:setSkillName("tyshouli")
                slash:addSubcard(to_select)
                slash:deleteLater()
                return not sgs.Self:isCardLimited(slash, sgs.Card_MethodResponse)
            elseif pattern == "jink" then
                if (not to_select:isKindOf("DefensiveHorse")) then return false end
                local method = nil
                if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
                    method = sgs.Card_MethodUse
                elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
                    method = sgs.Card_MethodResponse
                end
                local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                jink:setSkillName("tyshouli")
                jink:addSubcard(to_select)
                jink:deleteLater()
                return not sgs.Self:isCardLimited(jink, method)
            end
        end
    end,
    view_as = function(self,cards)
        if #cards == 0 then return nil end
        local card = tyshouliCard:clone()
        for _,c in ipairs(cards) do
            card:addSubcard(c)
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            card:setUserString("slash")
            return card
        end
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        card:setUserString(pattern)
        return card
    end,
    enabled_at_play = function(self, player)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("tyshouli")
        slash:deleteLater()
        return slash:isAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" or pattern == "jink"
    end,
}
tyshouliCard = sgs.CreateSkillCard
{
    name = "tyshouli",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card, user_string = nil, self:getUserString()
            if user_string ~= "" then
                card = sgs.Sanguosha:cloneCard(user_string:split("+")[1])
                card:setSkillName("tyshouli")
            end
            return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
        end
    
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("tyshouli")
        
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        --[[local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("tyshouli")
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end
        slash:deleteLater()]]--

        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("tyshouli")
        for _,id in sgs.qlist(self:getSubcards()) do
            use_card:addSubcard(sgs.Sanguosha:getCard(id))
        end

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return use_card and use_card:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        
        local owner = nil
        for _,id in sgs.qlist(self:getSubcards()) do
            owner = room:getCardOwner(id)
        end
        room:setPlayerMark(owner, "&tyshouli-Clear", 1)
        room:setPlayerMark(source, "&tyshouli-Clear", 1)
        if owner:objectName() ~= source:objectName() then
            room:addPlayerMark(owner, "@skill_invalidity")
        end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("tyshouli")
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end
        room:setCardFlag(slash, "RemoveFromHistory")
        return slash
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

        local owner = nil
        for _,id in sgs.qlist(self:getSubcards()) do
            owner = room:getCardOwner(id)
        end
        room:setPlayerMark(owner, "&tyshouli-Clear", 1)
        room:setPlayerMark(source, "&tyshouli-Clear", 1)
        if owner:objectName() ~= source:objectName() then
            room:addPlayerMark(owner, "@skill_invalidity")
        end

        local user_string = sgs.Sanguosha:getCurrentCardUsePattern()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("tyshouli")
        for _,id in sgs.qlist(self:getSubcards()) do
            use_card:addSubcard(sgs.Sanguosha:getCard(id))
        end
        return use_card
    end,
}
tyshoulibuff = sgs.CreateTriggerSkill{
    name = "#tyshoulibuff",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_NotFrequent,
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local da = data:toDamage()

        local log = sgs.LogMessage()
        log.type = "$tyshoulida"
        log.arg = player:getGeneralName()
        log.arg2 = "tyshouli"
        log.arg3 = da.damage
        log.arg4 = da.damage + 1
        room:sendLog(log)
        da.damage = da.damage + 1
        da.nature = sgs.DamageStruct_Thunder
        data:setValue(da)
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&tyshouli-Clear") > 0
    end,
}
tyshouliClear = sgs.CreateTriggerSkill{
    name = "#tyshouliClear",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    priority = 10,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("&tyshouli-Clear") > 0 then
                room:removePlayerMark(p, "@skill_invalidity")
                room:setPlayerMark(p, "&tyshouli-Clear", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}


ty_shenmachao:addSkill(tyshoulistart)
ty_shenmachao:addSkill(tyshouli)
ty_shenmachao:addSkill(tyshoulibuff)
ty_shenmachao:addSkill(tyshouliClear)
extension_J:insertRelatedSkills("tyshouli", "#tyshoulistart")
extension_J:insertRelatedSkills("tyshouli", "#tyshoulibuff")
extension_J:insertRelatedSkills("tyshouli", "#tyshouliClear")
ty_shenmachao:addSkill("hengwu")

--神典韦-自改版(限时地主)
ty_shendianwei = sgs.General(extension, "ty_shendianwei", "god", 4, true)

tyjuanjiaGMS = sgs.CreateTriggerSkill{
	name = "#tyjuanjiaGMS",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.MarkChanged, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, "tyjuanjia")
			room:broadcastSkillInvoke("tyjuanjia")
			if player:hasEquipArea(1) then
				player:throwEquipArea(1)
			end
			local log = sgs.LogMessage()
			log.type = "$tyjuanjia_getJJea"
			log.from = player
			room:sendLog(log)
			room:addPlayerMark(player, "@tyjuanjia_equiparea")
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "@tyjuanjia_equiparea" and mark.who and mark.who:objectName() == player:objectName()
			and player:getMark("@tyjuanjia_equiparea") > 0 and not player:hasSkill("tyjuanjia_equiparea") then
				room:attachSkillToPlayer(player, "tyjuanjia_equiparea")
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == "tyjuanjia_equiparea" and player:getMark("@tyjuanjia_equiparea") > 0 then
				room:attachSkillToPlayer(player, "tyjuanjia_equiparea")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("tyjuanjia")
	end,
}
tyjuanjia = sgs.CreateViewAsEquipSkill{
	name = "tyjuanjia",
	view_as_equip = function(self, player)
		return "" .. player:property("tyjuanjia_equiparea_record"):toString()
	end,
}
tyjuanjia_equipareaCard = sgs.CreateSkillCard{
	name = "tyjuanjia_equipareaCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("tyjuanjia")
		room:setPlayerProperty(source, "tyjuanjia_equiparea_record", sgs.QVariant()) --先清空记录
		local jjea_names = source:property("tyjuanjia_equiparea_record"):toString():split(",")
		local jjea_eq = {}
		local jjea_id = self:getSubcards():first()
		local jjea_card = sgs.Sanguosha:getCard(jjea_id)
		table.insert(jjea_eq, jjea_card:objectName())
		if source:getPile("tyjuanjia"):length() > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(source:getPile("tyjuanjia"))
			room:throwCard(dummy, source, nil)
			dummy:deleteLater()
		end
		source:addToPile("tyjuanjia", self)
		for _, _name in ipairs(jjea_eq) do
			if not table.contains(jjea_names, _name) then
				table.insert(jjea_names, _name)
			end
		end
		room:setPlayerProperty(source, "tyjuanjia_equiparea_record", sgs.QVariant(table.concat(jjea_names, ",")))
	end,
}
tyjuanjia_equiparea = sgs.CreateViewAsSkill{
	name = "tyjuanjia_equiparea&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and to_select:isKindOf("Weapon")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local jj_ea = tyjuanjia_equipareaCard:clone()
		for _, wp in ipairs(cards) do
			jj_ea:addSubcard(wp)
		end
		return jj_ea
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:hasSkill("tyjuanjia")
	end,
}
ty_shendianwei:addSkill(tyjuanjia)
ty_shendianwei:addSkill(tyjuanjiaGMS)
extension:insertRelatedSkills("tyjuanjia", "#tyjuanjiaGMS")
if not sgs.Sanguosha:getSkill("tyjuanjia_equiparea") then skills:append(tyjuanjia_equiparea) end


function qiexieFilter(player, general, equipArea)
	local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
	local jqxs = player:property("tyqiexie_jjarea_record"):toString():split(",")
	for _, _skill in sgs.qlist(general:getVisibleSkillList()) do
		if string.find(_skill:getDescription(), "【杀】") then --含有“【杀】”
			if not string.find(_skill:getDescription(), "技，") then --不带类型标签(粗略过滤)
				table.insert(wqxs, _skill:objectName())
				table.insert(jqxs, _skill:objectName())
			else
				if string.find(_skill:getDescription(), "锁定技，")
				and not string.find(_skill:getDescription(), "主公技，")
				and not string.find(_skill:getDescription(), "限定技，")
				and not string.find(_skill:getDescription(), "觉醒技，")
				and not string.find(_skill:getDescription(), "联动技，")
				and not string.find(_skill:getDescription(), "转换技，")
				and not string.find(_skill:getDescription(), "隐匿技，")
				and not string.find(_skill:getDescription(), "势力技，")
				and not string.find(_skill:getDescription(), "使命技，")
				and not string.find(_skill:getDescription(), "宗族技，")
				and not string.find(_skill:getDescription(), "说明技，")
				and not string.find(_skill:getDescription(), "激活技，")
				and not string.find(_skill:getDescription(), "学习技，")
				and not string.find(_skill:getDescription(), "解锁技，")
				and not string.find(_skill:getDescription(), "命运技，")
				and not string.find(_skill:getDescription(), "阶梯技，")
				and not string.find(_skill:getDescription(), "聚气技，")
				and not string.find(_skill:getDescription(), "昂扬技，")
				and not string.find(_skill:getDescription(), "皇后技，")
				and not string.find(_skill:getDescription(), "持恒技，")
				and not string.find(_skill:getDescription(), "连招技")
				and not string.find(_skill:getDescription(), "威主技，")
				then --带有，但仅锁定技(基本过滤)
					table.insert(wqxs, _skill:objectName())
					table.insert(jqxs, _skill:objectName())
				end
			end
		end
	end
	if equipArea then
		return wqxs
	end
	return jqxs
end

tyqiexie = sgs.CreateTriggerSkill{
	name = "tyqiexie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	waked_skills = "_weapon_qiexie_one",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		if not player:hasEquipArea(0) and player:getMark("@tyjuanjia_equiparea") == 0 then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local qiexies = {}
		local qiexie = {}
		for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
			table.insert(qiexies, name)
		end
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if table.contains(qiexies, p:getGeneralName()) then
				table.removeOne(qiexies, p:getGeneralName())
			end
		end
		for i = 1, 5 do
			local first = qiexies[math.random(1, #qiexies)]
			table.insert(qiexie, first)
			table.removeOne(qiexies, first)
		end

		local n = 2
		if not player:hasEquipArea(0) then n = n - 1 end
		if player:getMark("@tyjuanjia_equiparea") == 0 then n = n - 1 end
		local qiexie_weapon_range = { "One", "Two", "Three", "Four", "Five" }
		local equip_description = {}
		local juanjia_description = {}
		--1.置入装备区
		if n > 0 and player:hasEquipArea(0) then
			local general = room:askForGeneral(player, table.concat(qiexie, "+"))
			room:doAnimate(4, player:objectName(), general)
			table.removeOne(qiexie, general)
			table.insert(equip_description, general)
			table.insert(equip_description, ":")
			local ggeneral = sgs.Sanguosha:getGeneral(general)
			room:setPlayerProperty(player, "tyqiexie_wparea_record", sgs.QVariant())
			local wqxs = qiexieFilter(player, ggeneral, true)
			room:setPlayerProperty(player, "tyqiexie_wparea_record", sgs.QVariant(table.concat(wqxs, ",")))
			for _,s in sgs.list(wqxs)do
				table.insert(equip_description, s)
			end
			room:setPlayerFlag(player, "tyqiexie_wparea") --识别置入的是装备区还是“捐甲”区
			local mhp = math.min(ggeneral:getMaxHp(), 5)
			local cds = sgs.IntList()
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				local wqx = sgs.Sanguosha:getEngineCard(id)
				if wqx:isKindOf("WeaponQiexie"..qiexie_weapon_range[mhp]) and room:getCardPlace(id) == sgs.Player_PlaceTable then
					cds:append(id)
					break
				end
			end
			if not cds:isEmpty() then
				local cid = cds:first()
				local exchangeMove = sgs.CardsMoveList()
				exchangeMove:append(sgs.CardsMoveStruct(cid, player, sgs.Player_PlaceEquip,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")))
				local card = sgs.Sanguosha:getCard(cid)
				local realEquip = sgs.Sanguosha:getCard(cid):getRealCard():toEquipCard()
				local equip = player:getEquip(realEquip:location())
				if equip then
					exchangeMove:append(sgs.CardsMoveStruct(equip:getEffectiveId(), nil, sgs.Player_DiscardPile,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())))
				end
				room:broadcastSkillInvoke(self:objectName())
				room:moveCardsAtomic(exchangeMove, true)
			end
			if player:hasFlag("tyqiexie_wparea") then room:setPlayerFlag(player, "-tyqiexie_wparea") end
			
			n = n - 1
		end
		--2.置入“捐甲”区
		if n > 0 and player:getMark("@tyjuanjia_equiparea") > 0 then
			local generall = room:askForGeneral(player, table.concat(qiexie, "+"))
			local ggenerall = sgs.Sanguosha:getGeneral(generall)
			table.insert(juanjia_description, generall)
			table.insert(juanjia_description, ":")
			room:doAnimate(4, player:objectName(), generall)
			room:setPlayerProperty(player, "tyqiexie_jjarea_record", sgs.QVariant())
			local jqxs = qiexieFilter(player, ggenerall, false)
			room:setPlayerProperty(player, "tyqiexie_jjarea_record", sgs.QVariant(table.concat(jqxs, ",")))
			for _,s in sgs.list(jqxs)do
				table.insert(juanjia_description, s)
			end
			local mhp = math.min(ggenerall:getMaxHp(), 5)
			local cds = sgs.IntList()
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				local wqx = sgs.Sanguosha:getEngineCard(id)
				if wqx:isKindOf("WeaponQiexie"..qiexie_weapon_range[mhp]) and room:getCardPlace(id) == sgs.Player_PlaceTable then
					cds:append(id)
					break
				end
			end
			if not cds:isEmpty() then
				room:setPlayerProperty(player, "tyjuanjia_equiparea_record", sgs.QVariant())
				if player:getPile("tyjuanjia"):length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("tyjuanjia"))
					room:throwCard(dummy, player, nil)
					dummy:deleteLater()
				end
				room:broadcastSkillInvoke(self:objectName())
				player:addToPile("tyjuanjia", cds)
				local jqxs = player:property("tyqiexie_jjarea_record"):toString():split(",")
				room:setPlayerProperty(player, "tyqiexie_jjarea_lost_record", sgs.QVariant())
				local jqxs_tolose = player:property("tyqiexie_jjarea_lost_record"):toString():split(",") --用于离开“捐甲”区时找到对应技能
				for _, sk in pairs(jqxs) do
					room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
					table.insert(jqxs_tolose, sk)
				end
				room:setPlayerProperty(player, "tyqiexie_jjarea_lost_record", sgs.QVariant(table.concat(jqxs_tolose, ",")))
			end

		end

		player:setSkillDescriptionSwap("tyqiexie","%arg1",table.concat(equip_description,"+"));
		player:setSkillDescriptionSwap("tyqiexie","%arg2",table.concat(juanjia_description,"+"));
		room:changeTranslation(player,"tyqiexie", 1)
	end,
}
ty_shendianwei:addSkill(tyqiexie)
-----
tyqiexieRemover = sgs.CreateTriggerSkill{
	name = "#tyqiexieRemover",
	priority = 15,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceEquip) or table.contains(move.from_pile_names, "tyjuanjia")) and move.reason.m_skillName~="BreakCard" then
			for i,id in sgs.list(move.card_ids)do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("WeaponQiexieOne") or card:isKindOf("WeaponQiexieTwo") or card:isKindOf("WeaponQiexieThree")
				or card:isKindOf("WeaponQiexieFour") or card:isKindOf("WeaponQiexieFive") then
					if room:getCardPlace(id)==sgs.Player_PlaceSpecial and table.contains(move.from_pile_names, "tyjuanjia") then
						local jqxs_tolose = player:property("tyqiexie_jjarea_lost_record"):toString():split(",")
						for _, sk in pairs(jqxs_tolose) do
							room:detachSkillFromPlayer(player, sk, false, true)--true, true)
						end
						player:setSkillDescriptionSwap("tyqiexie","%arg2","");
						room:setPlayerProperty(player, "tyqiexie_jjarea_lost_record", sgs.QVariant())
					else
						player:setSkillDescriptionSwap("tyqiexie","%arg1","");
					end
					room:changeTranslation(player,"tyqiexie", 1)
					local ids = sgs.IntList()
					ids:append(id)
					move:removeCardIds(ids)
					room:breakCard(id,player)
					data:setValue(move)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
ty_shendianwei:addSkill(tyqiexieRemover)
extension:insertRelatedSkills("tyqiexie", "#tyqiexieRemover")


--为“挈挟”而量身打造的武器：
  --攻击范围1
WeaponQiexieOne = sgs.CreateWeapon{
	name = "_weapon_qiexie_one",
	class_name = "WeaponQiexieOne",
	range = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasFlag("tyqiexie_wparea") then
			local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
			local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",") --用于失去装备时找到对应技能
			for _, sk in pairs(wqxs) do
				room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
				table.insert(wqxs_tolose, sk)
			end
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant(table.concat(wqxs_tolose, ",")))
		end
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",")
		for _, sk in pairs(wqxs_tolose) do
			room:detachSkillFromPlayer(player, sk, false, true)--true, true)
		end
		room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
		return false
	end,
}
WeaponQiexieOne:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieOne:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieOne:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieOne:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
  --攻击范围2
WeaponQiexieTwo = sgs.CreateWeapon{
	name = "_weapon_qiexie_two",
	class_name = "WeaponQiexieTwo",
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasFlag("tyqiexie_wparea") then
			local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
			local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",") --用于失去装备时找到对应技能
			for _, sk in pairs(wqxs) do
				room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
				table.insert(wqxs_tolose, sk)
			end
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant(table.concat(wqxs_tolose, ",")))
		end
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",")
		for _, sk in pairs(wqxs_tolose) do
			room:detachSkillFromPlayer(player, sk, false, true)--true, true)
		end
		room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
		return false
	end,
}
WeaponQiexieTwo:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieTwo:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieTwo:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieTwo:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
  --攻击范围3
WeaponQiexieThree = sgs.CreateWeapon{
	name = "_weapon_qiexie_three",
	class_name = "WeaponQiexieThree",
	range = 3,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasFlag("tyqiexie_wparea") then
			local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
			local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",") --用于失去装备时找到对应技能
			for _, sk in pairs(wqxs) do
				room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
				table.insert(wqxs_tolose, sk)
			end
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant(table.concat(wqxs_tolose, ",")))
		end
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",")
		for _, sk in pairs(wqxs_tolose) do
			room:detachSkillFromPlayer(player, sk, false, true)--true, true)
		end
		room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
		return false
	end,
}
WeaponQiexieThree:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieThree:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieThree:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieThree:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
  --攻击范围4
WeaponQiexieFour = sgs.CreateWeapon{
	name = "_weapon_qiexie_four",
	class_name = "WeaponQiexieFour",
	range = 4,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasFlag("tyqiexie_wparea") then
			local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
			local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",") --用于失去装备时找到对应技能
			for _, sk in pairs(wqxs) do
				room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
				table.insert(wqxs_tolose, sk)
			end
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant(table.concat(wqxs_tolose, ",")))
		end
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",")
		for _, sk in pairs(wqxs_tolose) do
			room:detachSkillFromPlayer(player, sk, false, true)--true, true)
		end
		room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
		return false
	end,
}
WeaponQiexieFour:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFour:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFour:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFour:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
  --攻击范围5
WeaponQiexieFive = sgs.CreateWeapon{
	name = "_weapon_qiexie_five",
	class_name = "WeaponQiexieFive",
	range = 5,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasFlag("tyqiexie_wparea") then
			local wqxs = player:property("tyqiexie_wparea_record"):toString():split(",")
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
			local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",") --用于失去装备时找到对应技能
			for _, sk in pairs(wqxs) do
				room:acquireSkill(player, sk)--room:attachSkillToPlayer(player, sk)
				table.insert(wqxs_tolose, sk)
			end
			room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant(table.concat(wqxs_tolose, ",")))
		end
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local wqxs_tolose = player:property("tyqiexie_wparea_lost_record"):toString():split(",")
		for _, sk in pairs(wqxs_tolose) do
			room:detachSkillFromPlayer(player, sk, false, true)--true, true)
		end
		room:setPlayerProperty(player, "tyqiexie_wparea_lost_record", sgs.QVariant())
		return false
	end,
}
WeaponQiexieFive:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFive:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFive:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
WeaponQiexieFive:clone(sgs.Card_NoSuit, 0):setParent(extension_Cards)
-----

tycuijueCard = sgs.CreateSkillCard{
	name = "tycuijueCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		local distance = 0
		for _, p in sgs.qlist(player:getAliveSiblings()) do --第一遍，算出(攻击范围内)最远距离
			if player:inMyAttackRange(p) then
				local dt = player:distanceTo(p)
				if dt > distance then distance = dt
				else continue end
			else
				continue
			end
		end
		local tgts = {}
		for _, q in sgs.qlist(player:getAliveSiblings()) do --第二遍，统计所有(攻击范围内)最远距离且符合其他所有限制的角色
			if not player:inMyAttackRange(q) or player:distanceTo(q) < distance then continue end
			if q:getMark("tycuijueTarget-Clear") > 0 then continue end
			table.insert(tgts, q)
		end
		if #tgts == 0 then return false end
		return table.contains(tgts, to_select)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:addPlayerMark(effect.to, "tycuijueTarget-Clear")
		room:damage(sgs.DamageStruct("tycuijue", effect.from, effect.to))
	end,
}
tycuijue = sgs.CreateOneCardViewAsSkill{
	name = "tycuijue",
	filter_pattern = ".!",
	view_as = function(self, card)
		local cj_card = tycuijueCard:clone()
		cj_card:addSubcard(card:getId())
		return cj_card
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and player:canDiscard(player, "he")
	end,
}
ty_shendianwei:addSkill(tycuijue)


  --威力加强版
wx_shenzhugeliangEX = sgs.General(extension_J, "wx_shenzhugeliangEX", "god", 3, true)

wxqixingEX = sgs.CreateTriggerSkill{
	name = "wxqixingEX",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getMark("wxqixingEX_lun") == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "wxqixingEX_lun")
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|.|8~13"
				judge.good = true
				judge.play_animation = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() or judge.card:getNumber() > 13 then --专门防老六
					room:broadcastSkillInvoke(self:objectName())
					local recover = math.min(1 - player:getHp(), player:getMaxHp() - player:getHp())
					room:recover(player, sgs.RecoverStruct(player, nil, recover))
				end
			end
		end
	end,
}
wx_shenzhugeliangEX:addSkill(wxqixingEX)

wxjifengEXCard = sgs.CreateSkillCard{
	name = "wxjifengEXCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local rtg = {}
		for _, t in sgs.qlist(room:getDrawPile()) do
			local trick = sgs.Sanguosha:getCard(t)
			if trick:isKindOf("TrickCard") then
				table.insert(rtg, trick)
			end
		end
		if #rtg == 0 then
			for _, t in sgs.qlist(room:getDiscardPile()) do
				local trick = sgs.Sanguosha:getCard(t)
				if trick:isKindOf("TrickCard") then
					table.insert(rtg, trick)
				end
			end
		end
		local trk = rtg[math.random(1, #rtg)]
		room:broadcastSkillInvoke("wxjifengEX")
		room:obtainCard(source, trk)
	end,
}
wxjifengEXVS = sgs.CreateOneCardViewAsSkill{
	name = "wxjifengEX",
	view_filter = function(self, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, card)
		local jf_card = wxjifengEXCard:clone()
		jf_card:addSubcard(card:getId())
		return jf_card
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#wxjifengEXCard") < player:getMark("wxjifengEX-PlayClear") and not player:isKongcheng()
	end,
}
wxjifengEX = sgs.CreateTriggerSkill{
	name = "wxjifengEX",
	view_as_skill = wxjifengEXVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local z, f = player:getMark("&exZUI"), player:getMark("&exFA")
			local zaf = z + f
			room:setPlayerMark(player, "wxjifengEX-PlayClear", zaf+1)
			room:setPlayerMark(player, "&wxjifengEX_add-PlayClear", zaf)
		end
	end,
}

wx_shenzhugeliangEX:addSkill(wxjifengEX)

wxtianzuiEXCard = sgs.CreateSkillCard{
	name = "wxtianzuiEXCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, player)
		return #targets < sgs.Self:getMark("&exZUI") and to_select:objectName() ~= sgs.Self:objectName()
		and not to_select:isAllNude() and player:canDiscard(to_select, "hej")
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			local card = room:askForCardChosen(source, p, "hej", "wxtianzuiEX", false, sgs.Card_MethodDiscard)
			room:throwCard(card, p, source)
		end
	end,
}
wxtianzuiEXVS = sgs.CreateZeroCardViewAsSkill{
    name = "wxtianzuiEX",
    view_as = function()
		return wxtianzuiEXCard:clone()
	end,
	response_pattern = "@@wxtianzuiEX",
}
wxtianzuiEX = sgs.CreateTriggerSkill{
	name = "wxtianzuiEX",
	view_as_skill = wxtianzuiEXVS,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play  then
			player:loseAllMarks("&exZUI")
		elseif (event==sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive) then
			if player:hasSkill(self:objectName()) then
				if player:getMark("&exZUI") > 0 and player:hasSkill(self:objectName()) then
					room:askForUseCard(player, "@@wxtianzuiEX", "@wxtianzuiEX-card")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
wx_shenzhugeliangEX:addSkill(wxtianzuiEX)

wxtianfaEXCard = sgs.CreateSkillCard{
	name = "wxtianfaEXCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("&exFA") and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			room:damage(sgs.DamageStruct("wxtianfaEX", source, p, 1, sgs.DamageStruct_Thunder))
		end
	end,
}
wxtianfaEXVS = sgs.CreateZeroCardViewAsSkill{
    name = "wxtianfaEX",
    view_as = function()
		return wxtianfaEXCard:clone()
	end,
	response_pattern = "@@wxtianfaEX",
}
wxtianfaEX = sgs.CreateTriggerSkill{
	name = "wxtianfaEX",
	view_as_skill = wxtianfaEXVS,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			player:loseAllMarks("&exFA")
		elseif (event==sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive) then
			if player:hasSkill(self:objectName()) then
				if player:getMark("&exFA") > 0 and player:hasSkill(self:objectName()) then
					room:askForUseCard(player, "@@wxtianfaEX", "@wxtianfaEX-card")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
wx_shenzhugeliangEX:addSkill(wxtianfaEX)

wx_ZUIandFA = sgs.CreateTriggerSkill{
	name = "#wx_ZUIandFA",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() then
				if use.card and use.card:isKindOf("TrickCard") and player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, self:objectName().."-PlayClear")
					if player:getMark(self:objectName().."-PlayClear") % 2 == 1 then
						if player:hasSkill("wxtianzuiEX") then
							room:sendCompulsoryTriggerLog(player, "wxtianzuiEX")
							room:broadcastSkillInvoke("wxtianzuiEX", 1)
							player:gainMark("&exZUI", 1)
						end
					elseif player:getMark(self:objectName().."-PlayClear") % 2 == 0 then
						if player:hasSkill("wxtianfaEX") then
							room:sendCompulsoryTriggerLog(player, "wxtianfaEX")
							room:broadcastSkillInvoke("wxtianfaEX", 1)
							player:gainMark("&exFA", 1)
						end
					end
				end
				if use.card and table.contains(use.card:getSkillNames(), "wxtianzuiex") then
					room:broadcastSkillInvoke("wxtianzuiEX", 2)
				end
				if use.card and table.contains(use.card:getSkillNames(), "wxtianfaex") then
					room:broadcastSkillInvoke("wxtianfaEX", 2)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
wx_shenzhugeliangEX:addSkill(wx_ZUIandFA)
extension_J:insertRelatedSkills("wxtianzuiEX", "#wx_ZUIandFA")
extension_J:insertRelatedSkills("wxtianfaEX", "#wx_ZUIandFA")


extension_M = sgs.Package("fcDIY_mg", sgs.Package_GeneralPack)


--FC谋黄忠
fc_mou_huangzhong = sgs.General(extension_M, "fc_mou_huangzhong", "shu", 4, true)

fcmouliegong = sgs.CreateTriggerSkill{
	name = "fcmouliegong",
	priority = {4, 4, 4, 4, 4, 4},
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.CardUsed, sgs.CardResponded, sgs.Death, sgs.CardFinished, sgs.TargetSpecified, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local can_invoke = false
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getGeneralName() == "fc_mou_huangzhong" or p:getGeneral2Name() == "fc_mou_huangzhong" then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
				if card:isKindOf("Slash") then room:setPlayerFlag(player, "fromfcmouliegong") end --触发斩杀语音用
			else
				card = data:toCardResponse().m_card
			end
			if card and not card:isKindOf("SkillCard") and card:hasSuit() then

				local record = player:property("fcmouliegongRecords"):toString()
				local suit = card:getSuitString()
				local records = {}
				if (record) then
					records = record:split(",")
				end
				if records and (table.contains(records, suit)) then
					if player:getMark("fcmouliegong"..card:getSuitString().."_lun") == 0 then
						room:addPlayerMark(player, "fcmouliegong"..card:getSuitString().."_lun")
						room:sendCompulsoryTriggerLog(player, self:objectName())
						player:drawCards(1, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
				else
					table.insert(records, suit)
				end
				room:setPlayerProperty(player, "fcmouliegongRecords", sgs.QVariant(table.concat(records, ",")));
				for _, mark in sgs.list(player:getMarkNames()) do
					if (string.startsWith(mark, "&fcmouliegong+#record") and player:getMark(mark) > 0) then
						room:setPlayerMark(player, mark, 0)
					end
				end
				local mark = "&fcmouliegong+#record"
				for _, suit in ipairs(records) do
					mark = mark .. "+" .. suit .. "_char"
				end
				room:setPlayerMark(player, mark, 1)
				room:broadcastSkillInvoke(self:objectName(), (#records+2))
			end
		elseif event == sgs.Death then
		    local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() then
		        local killer
		        if death.damage then
			        killer = death.damage.from
		        else
			        killer = nil
		        end
		        local current = room:getCurrent()
		        if killer:hasSkill(self:objectName()) and killer:hasFlag("fromfcmouliegong") and (current:isAlive() or current:objectName() == death.who:objectName()) then
					room:broadcastSkillInvoke(self:objectName(), 10)
		        end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
				local record = player:property("fcmouliegongRecords"):toString()
				local records = {}
				if (record) then
					records = record:split(",")
				end
				if #records >= 2 then
					if #records < 4 then
						room:broadcastSkillInvoke("fcmouliegong", math.random(7,8))
					end
					room:sendCompulsoryTriggerLog(player, "fcmouliegong")
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list, "_ALL_TARGETS")
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() then
				local record = player:property("fcmouliegongRecords"):toString()
				local records = {}
				if (record) then
					records = record:split(",")
				end
				if #records >= 3 then
					if #records == 4 then
						local wjqs = damage.card:getNumber()
						if (wjqs == 1 and math.random() <= 0.12) or (wjqs == 2 and math.random() <= 0.16) or (wjqs == 3 and math.random() <= 0.2)
						or (wjqs == 4 and math.random() <= 0.24) or (wjqs == 5 and math.random() <= 0.28) or (wjqs == 6 and math.random() <= 0.32)
						or (wjqs == 7 and math.random() <= 0.36) or (wjqs == 8 and math.random() <= 0.4) or (wjqs == 9 and math.random() <= 0.44)
						or (wjqs == 10 and math.random() <= 0.48) or (wjqs == 11 and math.random() <= 0.52) or (wjqs == 12 and math.random() <= 0.56)
						or (wjqs == 13 and math.random() <= 0.6) then
							local log = sgs.LogMessage()
							log.type = "$fcmouliegongCriticalHit"
							log.from = player
							log.to:append(damage.to)
							room:sendLog(log)
							damage.damage = (damage.damage+1)*2
							data:setValue(damage)
							room:broadcastSkillInvoke("fcmouliegong", 9)
							room:setPlayerProperty(player, "fcmouliegongRecords", sgs.QVariant(""))
							for _, mark in sgs.list(player:getMarkNames()) do
								if (string.startsWith(mark, "&fcmouliegong+#record") and player:getMark(mark) > 0) then
									room:setPlayerMark(player, mark, 0)
								end
							end
							room:loseHp(player, 1, true, player, self:objectName())
						else
							damage.damage = damage.damage + 1
							data:setValue(damage)
							room:broadcastSkillInvoke("fcmouliegong", math.random(7,8))
						end
					else
						damage.damage = damage.damage + 1
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasSuit() then

				local record = player:property("fcmouliegongRecords"):toString()
				local suit = use.card:getSuitString()
				local records
				if (record) then
					records = record:split(",")
				end
				if records and (table.contains(records, suit)) then
					table.removeOne(records, suit)
				end
				room:setPlayerProperty(player, "fcmouliegongRecords", sgs.QVariant(table.concat(records, ",")));
				for _, mark in sgs.list(player:getMarkNames()) do
					if (string.startsWith(mark, "&fcmouliegong+#record") and player:getMark(mark) > 0) then
						room:setPlayerMark(player, mark, 0)
					end
				end
				local mark = "&fcmouliegong+#record"
				for _, suit in ipairs(records) do
					mark = mark .. "+" .. suit .. "_char"
				end
				room:setPlayerMark(player, mark, 1)
				if player:hasFlag("fromfcmouliegong") then room:setPlayerFlag(player, "-fromfcmouliegong") end
			end
		end
	end,
}

--根据已记录的花色数，拥有对应的效果--
  --至少1种
fcmouliegong_buff = sgs.CreateTargetModSkill{
	name = "#fcmouliegong_buff",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("fcmouliegong") and card and card:isKindOf("Slash") then
			local record = player:property("fcmouliegongRecords"):toString()
			local records
			if (record) then
				records = record:split(",")
			end
			if #records >= 1 then
				local num = card:getNumber()
				return num - 1
			else
				return 0
			end
		else
			return 0
		end
	end,
}

fc_mou_huangzhong:addSkill(fcmouliegong)
fc_mou_huangzhong:addSkill(fcmouliegong_buff)
extension_M:insertRelatedSkills("fcmouliegong", "#fcmouliegong_buff")


--FC谋关羽
fc_mou_guanyu = sgs.General(extension_M, "fc_mou_guanyu", "shu", 4, true)

fcmouwushengVS = sgs.CreateOneCardViewAsSkill{
	name = "fcmouwusheng",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isRed() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
fcmouwusheng_buff = sgs.CreateTargetModSkill{
	name = "#fcmouwusheng_buff",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("fcmouwusheng") and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Diamond then
			return 1000
		else
			return 0
		end
	end,
}
fcmouwusheng = sgs.CreateTriggerSkill{
	name = "fcmouwusheng",
	view_as_skill = fcmouwushengVS,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:getSuit() == sgs.Card_Heart then
			room:sendCompulsoryTriggerLog(player, "fcmouwusheng")
			room:broadcastSkillInvoke("fcmouwusheng")
			local hurt = damage.damage
			damage.damage = hurt + 1
			data:setValue(damage)
		end
	end,
}
fc_mou_guanyu:addSkill(fcmouwusheng)

fcmouyijueCard = sgs.CreateSkillCard{
	name = "fcmouyijueCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local choiceFrom = room:askForChoice(effect.from, "@MouYi-yijue", "F1+F2") --谋攻篇新机制：“谋弈”
		local choiceTo = room:askForChoice(effect.to, "@MouYi-yijue", "T1+T2")
		if (choiceFrom == "F1" and choiceTo ~= "T1") or (choiceFrom ~= "F1" and choiceTo == "T1") then
			--“谋弈”成功
			local log = sgs.LogMessage()
			log.type = "$MouYi_success"
			log.from = effect.from
			log.to:append(effect.to)
			room:sendLog(log)
			room:broadcastSkillInvoke("fcmouyijue", math.random(1,2))
			effect.from:setFlags("fcmouyijueSource")
			effect.to:gainMark("&fcmouyijue")
			room:addPlayerMark(effect.to, "@skill_invalidity")
			room:setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", false)
		else
			--“谋弈”失败
			local log = sgs.LogMessage()
			log.type = "$MouYi_fail"
			log.from = effect.from
			log.to:append(effect.to)
			room:sendLog(log)
			if not effect.to:isAllNude() then
				local EnYi = room:askForCardChosen(effect.from, effect.to, "hej", "fcmouyijue")
				room:obtainCard(effect.from, EnYi, true)
				if effect.to:isWounded() and room:askForSkillInvoke(effect.from, "@fcmouyijue-Recover") then
					room:recover(effect.to, sgs.RecoverStruct(effect.from))
					room:broadcastSkillInvoke("fcmouyijue", math.random(1,2))
				end
			end
		end
	end,
}
fcmouyijueVS = sgs.CreateOneCardViewAsSkill{
	name = "fcmouyijue",
	view_filter = function(self, to_select)
		return true
	end,
    view_as = function(self, cards)
		local my_card = fcmouyijueCard:clone()
		my_card:addSubcard(cards)
		return my_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fcmouyijueCard") and not player:isNude()
	end,
}
fcmouyijue= sgs.CreateTriggerSkill{
	name = "fcmouyijue",
	view_as_skill = fcmouyijueVS,
	events = {sgs.ConfirmDamage, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and player:hasSkill("fcmouyijue") and damage.to:getMark("&fcmouyijue") > 0 and damage.card
			and damage.card:isKindOf("Slash") and damage.card:isRed() then
				room:sendCompulsoryTriggerLog(player, "fcmouyijue")
				room:broadcastSkillInvoke("fcmouyijue", math.random(3,4))
				local YDJ = damage.damage
				damage.damage = YDJ + 1
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&fcmouyijue") > 0 then
					room:setPlayerMark(p, "&fcmouyijue", 0)
					if p:getMark("@skill_invalidity") > 0 then
						room:setPlayerMark(p, "@skill_invalidity", 0)
					end
					room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fc_mou_guanyu:addSkill(fcmouyijue)




--谋马超-威力加强版
mou_machaoo = sgs.General(extension_M, "mou_machaoo", "shu", 4, true)

mou_machaoo:addSkill("mashu")

fcmoutieqii = sgs.CreateTriggerSkill{
	name = "fcmoutieqii",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) then
			local no_respond_list = use.no_respond_list
			for _, c in sgs.qlist(use.to) do
				if room:askForSkillInvoke(use.from, self:objectName(), ToData(c)) then
					room:sendCompulsoryTriggerLog(use.from, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					c:setFlags("fcmoutieqiiTarget")
					room:addPlayerMark(c, "@skill_invalidity")
					table.insert(no_respond_list, c:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
					--AI决策注释原因：威力加强版的“谋弈”成功有附加效果了，当自己没牌时对面就算选偷牌也有加伤收益
					local choiceFrom = room:askForChoice(use.from, "@MouYi-tieqi", "F1+F2")
					local choiceTo = room:askForChoice(c, "@MouYi-tieqi", "T1+T2")
						
					--“谋弈”成功
					if choiceFrom == "F1" and choiceTo ~= "T1" then --抢牌成功
						local log = sgs.LogMessage()
						log.type = "$MouYi_success"
						log.from = use.from
						log.to:append(c)
						room:sendLog(log)
						room:broadcastSkillInvoke(self:objectName(), 3)
						if not c:isNude() then
							local Ying = room:askForCardChosen(use.from, c, "he", self:objectName())
							room:obtainCard(use.from, Ying, false)
						end
						room:setCardFlag(use.card, "fcmoutieqii_successDMG")
					elseif choiceFrom ~= "F1" and choiceTo == "T1" then --摸牌成功
						local log = sgs.LogMessage()
						log.type = "$MouYi_success"
						log.from = use.from
						log.to:append(c)
						room:sendLog(log)
						room:broadcastSkillInvoke(self:objectName(), 4)
						room:drawCards(use.from, 2, self:objectName())
						room:obtainCard(use.from, use.card)
					else
						--“谋弈”失败
						local log = sgs.LogMessage()
						log.type = "$MouYi_fail"
						log.from = use.from
						log.to:append(c)
						room:sendLog(log)
						room:broadcastSkillInvoke(self:objectName(), 5)
					end
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
fcmoutieqii_buff = sgs.CreateTriggerSkill{
    name = "#fcmoutieqii_buff",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.EventPhaseChanging, sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.to
			and damage.card and damage.card:hasFlag("fcmoutieqii_successDMG") then
				room:setCardFlag(damage.card, "-fcmoutieqii_successDMG")
				local log = sgs.LogMessage()
				log.type = "$MouYi-tieqi_successDMG"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				room:sendLog(log)
				room:broadcastSkillInvoke("fcmoutieqii", 1)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("fcmoutieqiiTarget") then
				p:setFlags("-fcmoutieqiiTarget")
				if p:getMark("@skill_invalidity") > 0 then
					room:setPlayerMark(p, "@skill_invalidity", 0)
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
mou_machaoo:addSkill(fcmoutieqii)
mou_machaoo:addSkill(fcmoutieqii_buff)
extension_M:insertRelatedSkills("fcmoutieqii", "#fcmoutieqii_buff")

--谋徐晃-威力加强版
mou_xuhuangg = sgs.General(extension_M, "mou_xuhuangg", "wei", 4, true)

mouduanlianggCard = sgs.CreateSkillCard{
    name = "mouduanlianggCard",
	target_fixed = false,
	--mute = true, --防止技能卡牌乱报语音（然而实测整个技能卡都沉默了）
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:broadcastSkillInvoke(self:objectName(), 1)
		--注：不想手动设置智能AI了，看脸吧
		local choiceFrom = room:askForChoice(effect.from, "@MouYi-duanliang", "F1+F2")
		local choiceTo = room:askForChoice(effect.to, "@MouYi-duanliang", "T1+T2")
		--“谋弈”成功
		if choiceFrom == "F1" and choiceTo ~= "T1" then --兵粮成功
			local log = sgs.LogMessage()
			log.type = "$MouYi_success"
			log.from = effect.from
			log.to:append(effect.to)
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName(), 2)
			local n = 0
			if effect.to:getJudgingArea():length() > 0 then
				for _, c in sgs.qlist(effect.to:getJudgingArea()) do
					if c:isKindOf("SupplyShortage") then
						n = n + 1
					end
					break
				end
			end
			if n > 0 then
				if not effect.to:isNude() then
					local get = room:askForCardChosen(effect.from, effect.to, "he", "mouduanliangg")
					room:obtainCard(effect.from, get, false)
				end
			else
				local id = room:getNCards(1, false)
				local card = sgs.Sanguosha:getCard(id:first())
				local shortage = sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(), card:getNumber())
				shortage:setSkillName("mouduanliangv") --防止乱播报语音
				shortage:addSubcard(card)
				shortage:deleteLater()
				if not effect.from:isProhibited(effect.to, shortage) then
					room:useCard(sgs.CardUseStruct(shortage, effect.from, effect.to))
				else
					shortage:deleteLater()
				end
			end
		elseif choiceFrom ~= "F1" and choiceTo == "T1" then --决斗成功
			local log = sgs.LogMessage()
			log.type = "$MouYi_success"
			log.from = effect.from
			log.to:append(effect.to)
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName(), 3)
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("mouduanliangv")
			duel:deleteLater()
			if not effect.from:isProhibited(effect.to, duel) then
				room:useCard(sgs.CardUseStruct(duel, effect.from, effect.to))
			end
		else
			--“谋弈”失败
			local log = sgs.LogMessage()
			log.type = "$MouYi_fail"
			log.from = effect.from
			log.to:append(effect.to)
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName(), 4)
		end
	end,
}
mouduanliangg = sgs.CreateZeroCardViewAsSkill{
    name = "mouduanliangg",
	view_as = function()
		return mouduanlianggCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#mouduanlianggCard") < 2 --not player:hasUsed("#mouduanlianggCard")
	end,
}
mou_xuhuangg:addSkill(mouduanliangg)
local function handleExchangeAndDamage(room, player, target, skillname, card_ids, force)
    local baohufei
    if not target:isKongcheng() then
        baohufei = room:askForExchange(target, skillname, 1, 1, false, "#moushipoo:".. player:getGeneralName(), force)
        if baohufei then
            room:obtainCard(player, baohufei, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), skillname, ""), false)
            card_ids:append(baohufei:getSubcards():first())
            return true
        end
    end
    room:damage(sgs.DamageStruct(skillname, player, target, 1, sgs.DamageStruct_Normal))
    return false
end

local function getTargetList(room, player, flag)
    local targets = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
        if p:hasFlag(flag) then
            targets:append(p)
            room:setPlayerFlag(p, "-"..flag)
        end
    end
    return targets
end

moushipoo = sgs.CreateTriggerSkill{
    name = "moushipoo",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Finish then return false end
        
        -- Set initial flags
        for _, xd in sgs.qlist(room:getOtherPlayers(player)) do
            if xd:getHp() < player:getHp() then
                room:setPlayerFlag(xd, "moushipooWXTarget")
                if not player:hasFlag("moushipooWXSource") then
                    room:setPlayerFlag(player, "moushipooWXSource")
                end
            end
        end
        
        for _, dj in sgs.qlist(room:getOtherPlayers(player)) do
            if dj:getJudgingArea():length() > 0 then
                for _, s in sgs.qlist(dj:getJudgingArea()) do
                    if s:isKindOf("SupplyShortage") then
                        room:setPlayerFlag(dj, "moushipooXGTarget")
                        if not player:hasFlag("moushipooXGSource") then
                            room:setPlayerFlag(player, "moushipooXGSource")
                        end
                    end
                end
            end
        end

        if not player:hasFlag("moushipooWXSource") and not player:hasFlag("moushipooXGSource") then return false end
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end

        local choices = {}
        if player:hasFlag("moushipooWXSource") then table.insert(choices, "1") end
        if player:hasFlag("moushipooXGSource") then table.insert(choices, "2") end
        
        local card_ids = sgs.IntList()
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        
        if choice == "1" then
            local XiaoDi = getTargetList(room, player, "moushipooWXTarget")
            if not XiaoDi:isEmpty() then
                local to = room:askForPlayerChosen(player, XiaoDi, self:objectName(), "moushipoo_KHxd")
                room:broadcastSkillInvoke(self:objectName(), 1)
                
                if to:hasFlag("moushipooXGTarget") then
                    handleExchangeAndDamage(room, player, to, self:objectName(), card_ids, false)
                else
                    local choicee = room:askForChoice(to, self:objectName(), "3+4")
                    if choicee == "3" then
                        handleExchangeAndDamage(room, player, to, self:objectName(), card_ids, false)
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), player, to, 1, sgs.DamageStruct_Normal))
                    end
                end
            end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("moushipooXGTarget") then
					room:setPlayerFlag(p, "-moushipooXGTarget")
				end
			end
            
        elseif choice == "2" then
            room:broadcastSkillInvoke(self:objectName(), 2)
            local DiJun = getTargetList(room, player, "moushipooXGTarget")
            
            for _, p in sgs.qlist(DiJun) do
                if p:getHp() < player:getHp() then
                    handleExchangeAndDamage(room, player, p, self:objectName(), card_ids, false)
                else
                    local choicee = room:askForChoice(p, self:objectName(), "3+4")
                    if choicee == "3" then
                        handleExchangeAndDamage(room, player, p, self:objectName(), card_ids, false)
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Normal))
                    end
                end
            end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("moushipooWXTarget") then
					room:setPlayerFlag(p, "-moushipooWXTarget")
				end
			end
        end

        if not card_ids:isEmpty() then
            room:askForYiji(player, card_ids, self:objectName(), false, false, true, card_ids:length(), room:getOtherPlayers(player))
        end
        return false
    end,
}
mou_xuhuangg:addSkill(moushipoo)


--KJ谋夏侯霸
kj_mou_xiahouba = sgs.General(extension_M, "kj_mou_xiahouba", "wei", 4, true)

kjmoushifengCard = sgs.CreateSkillCard{
	name = "kjmoushifengCard",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select, nil, false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("kjmoushifeng")
		slash:deleteLater()
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for _, p in pairs(targets) do
			use.to:append(p)
		end
		room:useCard(use)
	end,
}
kjmoushifengVS = sgs.CreateZeroCardViewAsSkill{
	name = "kjmoushifeng",
	view_as = function()
		return kjmoushifengCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@kjmoushifeng"
	end,
}
kjmoushifeng = sgs.CreateTriggerSkill{
	name = "kjmoushifeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished, sgs.CardOffset},
	view_as_skill = kjmoushifengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() or player:getKingdom() ~= "wei" then return false end
			if use.card:isKindOf("Jink") or use.card:isKindOf("Nullification") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1, self:objectName())
					room:askForUseCard(player, "@@kjmoushifeng", "@kjmoushifeng-tuodao")
				end
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if table.contains(effect.card:getSkillNames(), "kjmoushifeng") and effect.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				room:loseHp(player, 1, true, player, self:objectName())
			end
		end
	end,
}
kj_mou_xiahouba:addSkill(kjmoushifeng)

kjmoujuezhan = sgs.CreateTriggerSkill{
	name = "kjmoujuezhan",
	frequency = sgs.Skill_Wake,
	events = {sgs.TurnStart, sgs.EventPhaseStart},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_Finish then return false end
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getHp() ~= 1 and not player:isKongcheng() then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHp() == 1 then
			room:broadcastSkillInvoke(self:objectName(), 1)
		end
		if player:isKongcheng() then
			room:broadcastSkillInvoke(self:objectName(), 2)
		end
		room:doSuperLightbox("kj_mou_xiahouba", "kjmoujuezhan")
		room:addPlayerMark(player, self:objectName())
		room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "1+2") == "1" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2, self:objectName())
			end
		else
			room:drawCards(player, 2, self:objectName())
		end
		room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
kj_mou_xiahouba:addSkill(kjmoujuezhan)

kjmoulijin = sgs.CreateTriggerSkill{
	name = "kjmoulijin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_RoundStart or not player:isWounded() or player:getKingdom() ~= "shu" then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "judge+draw+play+discard")
			
			if choice == "judge" then
				local n = player:getLostHp()
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isNude() and player:canDiscard(p, "he") then
						players:append(p)
					end
				end
				if not players:isEmpty() and n > 0 then
					local simawei = room:askForPlayerChosen(player, players, self:objectName(), "kjmoulijinTiaoXinS:" .. n)
					room:broadcastSkillInvoke(self:objectName(), 1)
					local remove = sgs.IntList()
					for i = 1, n do--进行多次执行
						local id = room:askForCardChosen(player, simawei, "he", self:objectName(),
							false,--选择卡牌时手牌不可见
							sgs.Card_MethodDiscard,--设置为弃置类型
							remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
							i>1)--只有执行过一次选择才可取消
						if id < 0 then break end--如果卡牌id无效就结束多次执行
						remove:append(id)--将选择的id添加到虚拟卡的子卡表
					end
                    room:throwCard(remove,self:objectName(),simawei,player)
				end
				player:setPhase(sgs.Player_Judge)
				room:broadcastProperty(player, "phase")
				local thread = room:getThread()
				if not thread:trigger(sgs.EventPhaseStart, room, player) then
					thread:trigger(sgs.EventPhaseProceeding, room, player)
				end
				thread:trigger(sgs.EventPhaseEnd, room, player)
				player:setPhase(sgs.Player_RoundStart)
				room:broadcastProperty(player, "phase")
			elseif choice == "draw" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:addMaxCards(player, 1, true)
				player:setPhase(sgs.Player_Draw)
				room:broadcastProperty(player, "phase")
				local thread = room:getThread()
				if not thread:trigger(sgs.EventPhaseStart, room, player) then
					thread:trigger(sgs.EventPhaseProceeding, room, player)
				end
				thread:trigger(sgs.EventPhaseEnd, room, player)
				player:setPhase(sgs.Player_RoundStart)
				room:broadcastProperty(player, "phase")
			elseif choice == "play" then
				local kjmoulijin_PlaySlash_cards = {}
				local kjmoulijin_one_slash_count = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("Slash") and not table.contains(kjmoulijin_PlaySlash_cards, id) and kjmoulijin_one_slash_count < 1 then
						kjmoulijin_one_slash_count = kjmoulijin_one_slash_count + 1
						table.insert(kjmoulijin_PlaySlash_cards, id)
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				for _, id in ipairs(kjmoulijin_PlaySlash_cards) do
					dummy:addSubcard(id)
				end
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:obtainCard(player, dummy, false)
				player:setPhase(sgs.Player_Play)
				room:broadcastProperty(player, "phase")
				local thread = room:getThread()
				if not thread:trigger(sgs.EventPhaseStart, room, player) then
					thread:trigger(sgs.EventPhaseProceeding, room, player)
				end
				thread:trigger(sgs.EventPhaseEnd, room, player)
				player:setPhase(sgs.Player_RoundStart)
				room:broadcastProperty(player, "phase")
			elseif choice == "discard" then
				room:broadcastSkillInvoke(self:objectName(), 4)
				player:gainHujia(1)
				player:setPhase(sgs.Player_Discard)
				room:broadcastProperty(player, "phase")
				local thread = room:getThread()
				if not thread:trigger(sgs.EventPhaseStart, room, player) then
					thread:trigger(sgs.EventPhaseProceeding, room, player)
				end
				thread:trigger(sgs.EventPhaseEnd, room, player)
				player:setPhase(sgs.Player_RoundStart)
				room:broadcastProperty(player, "phase")
			end
			
		end
	end,
}
kj_mou_xiahouba:addSkill(kjmoulijin)


--FC谋姜维
fc_mou_jiangwei = sgs.General(extension_M, "fc_mou_jiangwei", "shu", 4, true)

fcmoutiaoxinCard = sgs.CreateSkillCard{
	name = "fcmoutiaoxinCard",
	filter = function(self, targets, to_select)
		local n = sgs.Self:getMark("&charge_num")
		return #targets < n and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "fcmxt_getbazhen")
		room:acquireSkill(source, "bazhen")
		for _, xr in pairs(targets) do
			if xr then
				source:loseMark("&charge_num", 1)
				if source:getMark("fcmouzhiji") == 0 then
					room:addPlayerMark(source, "&tofcmouzhiji")
				end
			end
		end
		for _, xr in pairs(targets) do
			local use_slash = false
			if xr:canSlash(source, nil, false) then
				room:setPlayerFlag(xr, "fcmoutiaoxinSource")
				room:setPlayerFlag(source, "fcmoutiaoxinTarget")
				use_slash = room:askForUseSlashTo(xr, source, "@fcmoutiaoxin-slash:" .. source:objectName(), false, false, false, source, nil, "fcmoutiaoxin")
			end
			if not use_slash and not xr:isNude() then
				local card = room:askForCardChosen(source, xr, "he", "fcmoutiaoxin")
				room:obtainCard(source, card, false)
			end
		end
	end,
}
fcmoutiaoxinVS = sgs.CreateZeroCardViewAsSkill{
	name = "fcmoutiaoxin",
	view_as = function()
		return fcmoutiaoxinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fcmoutiaoxinCard") and player:getMark("&charge_num") > 0
	end,
}
fcmoutiaoxin = sgs.CreateTriggerSkill{
	name = "fcmoutiaoxin",
	view_as_skill = fcmoutiaoxinVS,
	waked_skills = "bazhen",
	events = {sgs.CardOffset, sgs.EventPhaseEnd, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.offset_card and effect.card:hasFlag("fcmoutiaoxin") and effect.to:canDiscard(effect.from, "he") and effect.to:hasSkill("fcmoutiaoxin") then
				local card = room:askForCardChosen(effect.to, effect.from, "he", "fcmoutiaoxin", false, sgs.Card_MethodDiscard)
				room:throwCard(card, effect.from, effect.to)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				if player:hasFlag("fcmxt_getbazhen") then
					if player:hasSkill("bazhen") then room:detachSkillFromPlayer(player, "bazhen", false, true) end
					room:setPlayerFlag(player, "-fcmxt_getbazhen")
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and player:hasSkill("fcmoutiaoxin") 
			and player:getPhase() == sgs.Player_Discard and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and player:getMark("&charge_num") < xuLiMax(player) then
				room:sendCompulsoryTriggerLog(player, "fcmoutiaoxin")
				room:broadcastSkillInvoke("fcmoutiaoxin")
				local add = math.min(move.card_ids:length(), xuLiMax(player)-player:getMark("&charge_num"))
				player:gainMark("&charge_num", add)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcmoutiaoxin:setProperty("ChargeNum",ToData("4/4"))
fc_mou_jiangwei:addSkill(fcmoutiaoxin)


fcmouzhiji = sgs.CreateTriggerSkill{
	name = "fcmouzhiji",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseProceeding},
	waked_skills = "fcmzj_yaozhi,fcmzj_jiezhuangshen",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&tofcmouzhiji") < 4 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "&tofcmouzhiji", 0)
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("fc_mou_jiangwei", "fcmouzhiji")
		
		room:addPlayerMark(player, self:objectName())
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			if not player:hasSkill("fcmzj_yaozhi") then
				room:acquireSkill(player, "fcmzj_yaozhi")
			end
			if not player:hasSkill("fcmzj_jiezhuangshen") then
				room:acquireSkill(player, "fcmzj_jiezhuangshen")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
fc_mou_jiangwei:addSkill(fcmouzhiji)

--==“妖智”(原作者：司马子元)==--
--[[
local json = require ("json")
function isNormalGameMode(mode_name)
	return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end
function getZhitianSkills()
	local room = sgs.Sanguosha:currentRoom()
	local Huashens = {}
	local generals = sgs.Sanguosha:getLimitedGeneralNames()
	local banned = {"zuoci", "guzhielai", "dengshizai", "jiangboyue", "bgm_xiahoudun"}
	local zhitian_skills = {}
	local alives = room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		if not table.contains(banned, p:getGeneralName()) then
			table.insert(banned, p:getGeneralName())
		end
		if p:getGeneral2() and not table.contains(banned, p:getGeneral2Name()) then
			table.insert(banned, p:getGeneral2Name())
		end
	end
	if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_")or room:getMode() == "custom_scenario") then
		table.removeTable(generals, sgs.GetConfig("Banlist/Roles", ""):split(","))
	elseif (room:getMode() == "04_1v3") then
		table.removeTable(generals, sgs.GetConfig("Banlist/HulaoPass", ""):split(","))
	elseif (room:getMode() == "06_XMode") then
		table.removeTable(generals, sgs.GetConfig("Banlist/XMode", ""):split(","))
		for _,p in sgs.qlist(room:getAlivePlayers())do
			table.removeTable(generals, (p:getTag("XModeBackup"):toStringList()) or {})
		end
	elseif (room:getMode() == "02_1v1") then
		table.removeTable(generals, sgs.GetConfig("Banlist/1v1", ""):split(","))
		for _,p in sgs.qlist(room:getAlivePlayers())do
			table.removeTable(generals, (p:getTag("1v1Arrange"):toStringList()) or {})
		end
	end
	for i=1, #generals, 1 do
		if table.contains(banned, generals[i]) then
			table.remove(generals, i)
		end
	end
	for i=1, #generals, 1 do
		local ageneral = sgs.Sanguosha:getGeneral(generals[i])
		if ageneral ~= nil then 
			local N = ageneral:getVisibleSkillList():length()
			local x = 0
			for _, pe in sgs.qlist(room:getAlivePlayers()) do
				for _, sk in sgs.qlist(ageneral:getVisibleSkillList()) do
					if pe:hasSkill(sk:objectName()) then x = x + 1 end
				end
			end
			if x == N then table.remove(generals, i) end
		end
	end
	if #generals > 0 then
		for i=1, #generals, 1 do
			table.insert(Huashens, generals[i])
		end
	end
	if #Huashens > 0 then
		for _, general_name in ipairs(Huashens) do
			local general = sgs.Sanguosha:getGeneral(general_name)		
			for _, sk in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(zhitian_skills, sk:objectName())
			end
		end
	end
	if #zhitian_skills > 0 then
		for _, pe in sgs.qlist(room:getAlivePlayers()) do
			for _, gsk in sgs.qlist(pe:getVisibleSkillList()) do
				if table.contains(zhitian_skills, gsk:objectName()) then table.removeOne(zhitian_skills, gsk:objectName()) end
			end
		end
	end
	if #zhitian_skills > 0 then
		return zhitian_skills
	else
		return {}
	end
end

--参数1：n，返回的table中技能的数量，Number类型（比如填3则最终的table里装填3个技能）
--参数2/3/4：description，所需的技能描述，String类型，一般利用string.find(skill:getDescription(), description)判断，彼此为并集。若无描述要求则填-1
--参数5：includeLord，是否包括主公技，Bool类型，true则包括，false则不包括
function getSpecificDescriptionSkills(n, description1, description2, description3, includeLord)
	local skill_table = {}  --这个用来存放初选满足函数要求的技能
	local output_table = {}  --这个用来存放最终满足函数要求的技能
	local d_paras = {description1, description2, description3}
	local d_needs = {}
	for i = 1, #d_paras do
		if d_paras[i] ~= -1 then table.insert(d_needs, d_paras[i]) end
	end
	local skills = getZhitianSkills()
	for _, _sk in ipairs(skills) do
		local _skill = sgs.Sanguosha:getSkill(_sk)
		local critical_des = string.sub(_skill:getDescription(), 1, 42)
		if #d_needs > 0 then
			for _, _des in ipairs(d_needs) do
				if string.find(critical_des, _des, 1) then
					if includeLord == false then
						if (not _skill:isLordSkill()) and (not _skill:isAttachedLordSkill()) and _skill:getFrequency() ~= sgs.Skill_Wake then
							table.insert(skill_table, _sk)
							break
						end
					elseif includeLord == true then
						table.insert(skill_table, _sk)
						break
					end
				end
			end
		else
			if includeLord == false then
				if (not _skill:isLordSkill()) and (not _skill:isAttachedLordSkill()) and _skill:getFrequency() ~= sgs.Skill_Wake then
					table.insert(skill_table, _sk)
					break
				end
			elseif includeLord == true then
				table.insert(skill_table, _sk)
				break
			end
		end
	end
	if #skill_table > 0 then  --整理，准备导出最终满足的技能table
		for i = 1, n do
			local j = math.random(1, #skill_table)
			table.insert(output_table, skill_table[j])
			table.removeOne(skill_table, skill_table[j])
			if #skill_table == 0 then break end
		end
	end
	return output_table
end
]]
fcmzj_yaozhi = sgs.CreateTriggerSkill{
	name = "fcmzj_yaozhi",
	frequency = sgs.Skill_NotFrequent,
	priority = 5,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart, sgs.Damaged, sgs.DamageComplete, sgs.CardFinished, sgs.EventPhaseEnd, sgs.MarkChanged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			local yaozhi_gained = {}
			player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
		elseif event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then
				local yaozhi_gained = {}
				player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removeTag("yaozhi_gained")
				player:removeTag("fcmzj_yaozhi_temp_skill")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
					local yaozhi_playerstart = getSpecificDescriptionSkills(3, player, "回合开始阶段，", "准备阶段，", "准备阶段开始时，", -1, -1, -1, -1, -1, false)
					if #yaozhi_playerstart > 0 then
						local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerstart, "+"), ToData())
						if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
						player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
						local temp_msg = sgs.LogMessage()
						temp_msg.from = player
						temp_msg.arg = yaozhi
						temp_msg.type = "#ZJYaozhiTempSkill"
						room:sendLog(temp_msg)
						room:acquireSkill(player, yaozhi)
						player:setTag("fcmzj_yaozhi_temp_skill", sgs.QVariant("yaozhi_temp_"..yaozhi))
					end
				end
			end
			if player:getPhase() == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
					local yaozhi_playerplay = getSpecificDescriptionSkills(3, player, "阶段技，", "出牌阶段，", "出牌阶段限一次，", -1, -1, -1, -1, -1, false)
					if #yaozhi_playerplay > 0 then
						local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerplay, "+"), data)
						if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
						player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
						local temp_msg = sgs.LogMessage()
						temp_msg.from = player
						temp_msg.arg = yaozhi
						temp_msg.type = "#ZJYaozhiTempSkill"
						room:sendLog(temp_msg)
						room:acquireSkill(player, yaozhi)
						player:setTag("fcmzj_yaozhi_temp_skill", sgs.QVariant("yaozhi_temp_"..yaozhi))
					end
				end
			end
			if player:getPhase() == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
					local yaozhi_playerfinish = getSpecificDescriptionSkills(3, player, "结束阶段，", "结束阶段开始时，", -1, -1, -1, -1, -1, -1, false)
					if #yaozhi_playerfinish > 0 then
						local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_playerfinish, "+"), data)
						if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
						player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
						local temp_msg = sgs.LogMessage()
						temp_msg.from = player
						temp_msg.arg = yaozhi
						temp_msg.type = "#ZJYaozhiTempSkill"
						room:sendLog(temp_msg)
						room:acquireSkill(player, yaozhi)
						player:setTag("fcmzj_yaozhi_temp_skill", sgs.QVariant("yaozhi_temp_"..yaozhi))
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage > 0 and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1, self:objectName())
				local yaozhi_gained = player:getTag("yaozhi_gained"):toString():split("+")
				local yaozhi_damaged = getSpecificDescriptionSkills(3, player, "当你受到伤害后", "锁定技，当你受到伤害后", "当你受到1点伤害", "锁定技，当你受到1点伤害后", -1, -1, -1, -1, false)
				if #yaozhi_damaged > 0 then
					local yaozhi = room:askForChoice(player, self:objectName(), table.concat(yaozhi_damaged, "+"), data)
					if not table.contains(yaozhi_gained, yaozhi) then table.insert(yaozhi_gained, yaozhi) end
					player:setTag("yaozhi_gained", sgs.QVariant(table.concat(yaozhi_gained, "+")))
					local temp_msg = sgs.LogMessage()
					temp_msg.from = player
					temp_msg.arg = yaozhi
					temp_msg.type = "#ZJYaozhiTempSkill"
					room:sendLog(temp_msg)
					room:acquireSkill(player, yaozhi)
					player:setTag("fcmzj_yaozhi_temp_skill", sgs.QVariant("yaozhi_temp_"..yaozhi))
				end
			end
		elseif event == sgs.DamageComplete then
			local temp_ta = player:getTag("fcmzj_yaozhi_temp_skill"):toString():split("+")
			if #temp_ta > 0 then
				local yaozhi_temp = string.sub(temp_ta[1], 13)
				if player:hasSkill(yaozhi_temp) then
					room:handleAcquireDetachSkills(player, "-"..yaozhi_temp)
					player:removeTag("fcmzj_yaozhi_temp_skill")
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local temp_ta = player:getTag("fcmzj_yaozhi_temp_skill"):toString():split("+")
			if #temp_ta > 0 then
				local yaozhi_temp = string.sub(temp_ta[1], 13)
				if use.card and (use.card:isVirtualCard() or use.card:getTypeId() == sgs.Card_TypeSkill) and string.find(temp_ta[1], use.card:getSkillName()) then
					if player:hasSkill(use.card:getSkillName()) or player:hasSkill(yaozhi_temp) then
						room:handleAcquireDetachSkills(player, "-"..yaozhi_temp)
						player:removeTag("fcmzj_yaozhi_temp_skill")
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Start or phase == sgs.Player_Play or phase == sgs.Player_Finish then
				local temp_ta = player:getTag("fcmzj_yaozhi_temp_skill"):toString():split("+")
				if #temp_ta > 0 then
					local yaozhi_temp = string.sub(temp_ta[1], 13)
					if player:hasSkill(yaozhi_temp) then room:handleAcquireDetachSkills(player, "-"..yaozhi_temp) end
				end
				player:removeTag("fcmzj_yaozhi_temp_skill")
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			local temp_ta = player:getTag("fcmzj_yaozhi_temp_skill"):toString():split("+")
			if #temp_ta > 0 then
				local temp_sk = string.sub(temp_ta[1], 13)
				if string.find(mark.name, temp_sk) and mark.gain == -1 and sgs.Sanguosha:getViewAsSkill(temp_sk) == nil then
					room:handleAcquireDetachSkills(player, "-"..temp_sk)
					room:removeTag("fcmzj_yaozhi_temp_skill")
				end
			end
		end
		return false
	end,
}
if not sgs.Sanguosha:getSkill("fcmzj_yaozhi") then skills:append(fcmzj_yaozhi) end
--==“界妆神”(原作者：小珂酱)==--
fcmzj_jiezhuangshen = sgs.CreateTriggerSkill{
	name = "fcmzj_jiezhuangshen", priority = -1,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("jzs_dawu") > 0 then
					local num = p:getMark("jzs_dawu")
					room:setPlayerMark(p,"jzs_dawu",0)
					room:removePlayerMark(p,"&dawu",num)
				end
				if p:getMark("jzs_kuangfeng") > 0 then
					local numm = p:getMark("jzs_kuangfeng")
					room:setPlayerMark(p,"jzs_kuangfeng",0)
					room:removePlayerMark(p,"&kuangfeng",numm)
				end
			end
		end
		if (player:getPhase() == sgs.Player_Start) or (player:getPhase() == sgs.Player_Finish) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				local suit = judge.card:getSuit()
				if judge.card:isBlack() then
					room:broadcastSkillInvoke(self:objectName(), 1)
					local person = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fcmzj_jiezhuangshenskill-ask", true, true)
					if person then 
						local skill_list = {}
						for _,skill in sgs.qlist(person:getVisibleSkillList()) do
							if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
								table.insert(skill_list,skill:objectName())
							end
						end
						local skill_qc = ""
						if (#skill_list > 0) then
							skill_qc = room:askForChoice(player, self:objectName(), table.concat(skill_list,"+"))
						end
						if (skill_qc ~= "") then
							room:acquireNextTurnSkills(player, self:objectName(), skill_qc)
						end
					end
				end
				if judge.card:isRed() then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local person = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName().."buff", "fcmzj_jiezhuangshengod-ask", true, true)
					if person then
						local choice = room:askForChoice(player,self:objectName().."buff","kfc+dwg+cancel", ToData(person))
						if choice == "kfc" then
						    room:addPlayerMark(person,"&kuangfeng",1)
							room:addPlayerMark(person,"jzs_kuangfeng",1)
						end
						if choice == "dwg" then
						    room:addPlayerMark(person,"&dawu",1)
							room:addPlayerMark(person,"jzs_dawu",1)
						end
					end
				end
			end
		end
	end,
}
fcmzj_jiezhuangshenDamage = sgs.CreateTriggerSkill{
	name = "#fcmzj_jiezhuangshenDamage",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen,sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageForseen then
			if (damage.nature ~= sgs.DamageStruct_Thunder) and (damage.to:getMark("&dawu") > 0) then
				room:sendCompulsoryTriggerLog(player, "fcmzj_jiezhuangshen")
				damage.prevent = true
				data:setValue(damage)
				return true 
			end
		end
		if event == sgs.ConfirmDamage then		
			if (damage.to:getMark("&kuangfeng") > 0) and (damage.nature == sgs.DamageStruct_Fire) then
				local hurt = damage.damage
				damage.damage = hurt + 1
				room:sendCompulsoryTriggerLog(player, "fcmzj_jiezhuangshen")
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcmzj_jiezhuangshenDeath = sgs.CreateTriggerSkill{
	name = "#fcmzj_jiezhuangshenDeath",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if p:getMark("jzs_dawu") > 0 then
						room:removePlayerMark(p,"jzs_dawu") 
						room:removePlayerMark(p,"&dawu")
					end
					if p:getMark("jzs_kuangfeng") > 0 then
						room:removePlayerMark(p,"jzs_kuangfeng") 
						room:removePlayerMark(p,"&kuangfeng")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("fcmzj_jiezhuangshen")
	end,
}
if not sgs.Sanguosha:getSkill("fcmzj_jiezhuangshen") then skills:append(fcmzj_jiezhuangshen) end
if not sgs.Sanguosha:getSkill("fcmzj_jiezhuangshenDamage") then skills:append(fcmzj_jiezhuangshenDamage) end
if not sgs.Sanguosha:getSkill("fcmzj_jiezhuangshenDeath") then skills:append(fcmzj_jiezhuangshenDeath) end
extension_M:insertRelatedSkills("fcmzj_jiezhuangshen", "#fcmzj_jiezhuangshenDamage")
extension_M:insertRelatedSkills("fcmzj_jiezhuangshen", "#fcmzj_jiezhuangshenDeath")


--FC谋孙策
fc_mou_sunce = sgs.General(extension_M, "fc_mou_sunce$", "wu", 8, true, false, false, 4)

fcmoujiang = sgs.CreateTriggerSkill{
    name = "fcmoujiang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.PreCardUsed, sgs.TargetSpecified, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.PreCardUsed then
			if use.from and use.from:objectName() == player:objectName() and use.card
			and (use.card:isRed() and use.card:isKindOf("Slash")) or use.card:isKindOf("Duel") then
				local extra_targets = room:getCardTargets(player, use.card, use.to)
				if extra_targets:isEmpty() then return false end
				room:setTag("fcmoujiang",data)
				local targets = room:askForPlayersChosen(player, extra_targets, self:objectName(), 0, 99,  "@fcmoujiang-excard:" .. use.card:objectName() .. "::", true, true)
				room:removeTag("fcmoujiang")
				
				if (not targets:isEmpty()) then
					local adds = sgs.SPlayerList()
					for _,to in sgs.qlist(targets) do
						use.to:append(to)
						adds:append(to)
					end
					if adds:isEmpty() then return false end
					room:sortByActionOrder(adds)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					local log = sgs.LogMessage()
					log.type = "#QiaoshuiAdd"
					log.from = player
					log.to = adds
					log.card_str = use.card:toString()
					log.arg = self:objectName()
					room:sendLog(log)
					for _, p in sgs.qlist(adds) do
						room:doAnimate(1, player:objectName(), p:objectName())
					end
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		elseif (event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player))) then
			if use.card and use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed()) then
				if event == sgs.TargetSpecified then
					for _, p in sgs.qlist(use.to) do
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:loseHp(player, 1, true, player, self:objectName())
						if player:isAlive() then
							room:drawCards(player, 1, self:objectName())
						end
					end
				elseif event == sgs.TargetConfirmed then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					if player:isWounded() then
						room:recover(player, sgs.RecoverStruct(player))
					end
					room:drawCards(player, 1, self:objectName())
				end
			end
		end
	end,
}
fc_mou_sunce:addSkill(fcmoujiang)

fcmouhunzi = sgs.CreateTriggerSkill{
	name = "fcmouhunzi",
	priority = 9500,
	frequency = sgs.Skill_Wake,
	events = {sgs.GameOverJudge},--sgs.Death},
	waked_skills = "fcmhz_yinzi,fcmhz_yinhun",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() or player:getMark(self:objectName()) > 0 then return false end
		--if player:canWake(self:objectName()) then return true end
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:doSuperLightbox("fc_mou_sunce", self:objectName())
			room:getThread():delay(5000)
			room:revivePlayer(player)
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:addPlayerMark(player, self:objectName())
			if room:changeMaxHpForAwakenSkill(player, -2, self:objectName()) then
				local recover = math.min(2 - player:getHp(), player:getMaxHp() - player:getHp())
				room:recover(player, sgs.RecoverStruct(player, nil, recover))
				local n = player:getMaxHp() - player:getHandcardNum()
				if n > 0 then
					room:drawCards(player, n, self:objectName())
				end
				if not player:hasSkill("fcmhz_yinzi") then
					room:acquireSkill(player, "fcmhz_yinzi")
				end
				if not player:hasSkill("fcmhz_yinhun") then
					room:acquireSkill(player, "fcmhz_yinhun")
				end
				--修复地主复活丢失地主技能的BUG：
				if room:getMode() == "03_1v2" and player:isLord() and not player:hasSkill("tyjuejing") then
					if not player:hasSkill("feiyang") then
						room:acquireSkill(player, "feiyang")
					end
					if not player:hasSkill("bahu") then
						room:acquireSkill(player, "bahu")
					end
				elseif room:getMode() == "03ty_1v2" and player:isLord() and not player:hasSkill("tyjuejing") then
					if not player:hasSkill("feiyang") then
						room:acquireSkill(player, "feiyang")
					end
					if not player:hasSkill("ty_bahu") then
						room:acquireSkill(player, "ty_bahu")
					end
				end
			end
			--
			room:setTag("SkipGameRule",sgs.QVariant(tonumber(event))) --不加这个代码的话如果游戏要结束了复活了也没用
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName())
	end,
}
fc_mou_sunce:addSkill(fcmouhunzi)
--“阴资”
fcmhz_yinzi = sgs.CreateTriggerSkill{
	name = "fcmhz_yinzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			draw.num = math.random(player:getHp(), player:getMaxHp())
			data:setValue(draw)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			local st = 0
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if p:isDead() then
					st = st + 1
				end
			end
			if st > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player, self:objectName(), st)
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			room:setPlayerMark(player, self:objectName(), 0)
		end
	end,
}
fcmhz_yinzi_MaxCards = sgs.CreateMaxCardsSkill{
	name = "#fcmhz_yinzi_MaxCards",
	extra_func = function(self, player)
		if player:hasSkill("fcmhz_yinzi") then
			local n = player:getMark("fcmhz_yinzi")
			return n
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("fcmhz_yinzi") then skills:append(fcmhz_yinzi) end
if not sgs.Sanguosha:getSkill("fcmhz_yinzi_MaxCards") then skills:append(fcmhz_yinzi_MaxCards) end
extension_M:insertRelatedSkills("fcmhz_yinzi", "#fcmhz_yinzi_MaxCards")
--“阴魂”
fcmhz_yinhun = sgs.CreateTriggerSkill{
	name = "fcmhz_yinhun",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fcmhz_yinhun",
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Judge and player:getJudgingArea():length() > 0 and player:canDiscard(player, "j") then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:loseMark("@fcmhz_yinhun")
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("fc_mou_sunces", self:objectName())
				local doublefuck = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "fcmhz_yinhun_choice")
				if doublefuck:isLord() then
					if player:getJudgingArea():length() < 2 then return false end
					local j1 = room:askForCardChosen(player, player, "j", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(j1), player, player)
					local j2 = room:askForCardChosen(player, player, "j", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(j2), player, player)
				else
					local jc = room:askForCardChosen(player, player, "j", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(jc), player, player)
				end
				local hp = doublefuck:getHp()
				local hc = doublefuck:getHandcardNum()
				room:killPlayer(doublefuck) --死生之地，不可不察
				room:revivePlayer(doublefuck) --死而复生，反复横跳
				if doublefuck:getHp() ~= hp then
					room:setPlayerProperty(doublefuck, "hp", sgs.QVariant(hp))
				end
				local hcd = hc - doublefuck:getHandcardNum()
				if hcd > 0 then
					room:drawCards(doublefuck, hcd, self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName()) and player:getMark("@fcmhz_yinhun") > 0
	end,
}
if not sgs.Sanguosha:getSkill("fcmhz_yinhun") then skills:append(fcmhz_yinhun) end

fcmouzhibaCard = sgs.CreateSkillCard{
	name = "fcmouzhibaCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:pindian(effect.to, "fcmouzhiba", nil)
	end,
}
fcmouzhiba = sgs.CreateZeroCardViewAsSkill{
	name = "fcmouzhiba$",
	waked_skills = "fc_mou_sunceWIN",
	view_as = function()
		return fcmouzhibaCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then return false end
		local n = 0
		if player:getKingdom() == "wu" and player:isAlive() then n = n + 1 end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:getKingdom() == "wu" then
				n = n + 1
			end
		end
		return player:usedTimes("#fcmouzhibaCard") < n
	end,
}
fcmouzhiba_pd = sgs.CreateTriggerSkill{
    name = "fcmouzhiba_pd",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.Pindian},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "fcmouzhiba") then
				room:broadcastSkillInvoke("fcmouzhiba", 1)
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "fcmouzhiba" then
				local fromNumber = pindian.from_card:getNumber()
				local toNumber = pindian.to_card:getNumber()
				if fromNumber ~= toNumber then
					local winner
					local loser
					if fromNumber > toNumber then
						winner = pindian.from
						loser = pindian.to
						if fromNumber - toNumber >= 3 and math.random() <= 0.25 then --触发胜点彩蛋
							sgs.Sanguosha:playAudioEffect("audio/skill/fcmouzhiba_success.ogg", false)
							room:doLightbox("fcmouzhiba_successAnimate", 5000)
						end
					else
						winner = pindian.to
						loser = pindian.from
						room:broadcastSkillInvoke("fcmouzhiba", 2)
					end
				else --平点彩蛋：FC谋孙策播放专属音乐，并获得两张拼点牌！
					local log = sgs.LogMessage()
				    log.type = "$fcmouzhiba_same"
				    log.from = pindian.from
					log.to:append(pindian.to)
				    room:sendLog(log)
					room:broadcastSkillInvoke("fc_mou_sunceWIN")
					room:obtainCard(pindian.from, pindian.from_card)
					room:obtainCard(pindian.from, pindian.to_card)
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
fc_mou_sunce:addSkill(fcmouzhiba)
fc_mou_sunce:addRelateSkill("fc_mou_sunceWIN")
if not sgs.Sanguosha:getSkill("fcmouzhiba_pd") then skills:append(fcmouzhiba_pd) end
--胜利专属音乐：
fc_mou_sunceWIN = sgs.CreateTriggerSkill{
	name = "fc_mou_sunceWIN",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameOver},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local winner = data:toString():split("+")
		for _, p in sgs.list(room:getAllPlayers()) do
			if (table.contains(winner, p:objectName()) or table.contains(winner, p:getRole()))
			and isSpecialOne(p, "FC谋孙策") then
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
if not sgs.Sanguosha:getSkill("fc_mou_sunceWIN") then skills:append(fc_mou_sunceWIN) end


--AH谋诸葛亮
ah_mou_zhugeliang = sgs.General(extension_M, "ah_mou_zhugeliang", "shu", 6, true)

ahmoukuangfu = sgs.CreateTriggerSkill{
	name = "ahmoukuangfu",
	--global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Judge and player:hasSkill(self:objectName()) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:setPlayerFlag(player, "ahmoukuangfu_SkipDrawPhase")
				local houzhu = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName())
				local ahmoukuangfu_cards = {}
				local ahmoukuangfu_one_count = 21
				--以下代码默认一张牌的点数不超过13
				while ahmoukuangfu_one_count > 13 do
					local ahmoukuangfu_this_count = 0
					for _, id in sgs.qlist(room:getDrawPile()) do
						if not table.contains(ahmoukuangfu_cards, id) and ahmoukuangfu_this_count < 1 then
							local num = sgs.Sanguosha:getCard(id):getNumber()
							ahmoukuangfu_one_count = ahmoukuangfu_one_count - num
							ahmoukuangfu_this_count = ahmoukuangfu_this_count + 1
							table.insert(ahmoukuangfu_cards, id)
						end
					end
				end
				--当“ahmoukuangfu_one_count”计数已减至不超过13且不为0时，精准拿最后一张点数已定死的牌
				local ahmoukuangfu_last_count = 0
				if ahmoukuangfu_one_count > 0 then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):getNumber() == ahmoukuangfu_one_count and not table.contains(ahmoukuangfu_cards, id) and ahmoukuangfu_last_count < 1 then
							ahmoukuangfu_last_count = ahmoukuangfu_last_count + 1
							table.insert(ahmoukuangfu_cards, id)
						end
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in ipairs(ahmoukuangfu_cards) do
					dummy:addSubcard(id)
				end
				if math.random() <= 0.5 then
					player:speak("受遗托孤，匡辅幼主，\
					犹念三顾之恩。")
				else
					player:speak("入汉中，出祁山，\
					竭股肱之力，效忠贞之节。")
				end
				room:broadcastSkillInvoke(self:objectName())
				room:obtainCard(houzhu, dummy, false)
				dummy:deleteLater()
				if player:getJudgingArea():length() > 0 then
					local dummi = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
					dummi:addSubcards(player:getCards("j"))
					room:obtainCard(player, dummi, true)
					dummi:deleteLater()
				end
			end
		elseif event == sgs.EventPhaseChanging and change.to == sgs.Player_Draw
		and player:hasFlag("ahmoukuangfu_SkipDrawPhase") then
			room:setPlayerFlag(player, "-ahmoukuangfu_SkipDrawPhase")
			player:skip(change.to)
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
ah_mou_zhugeliang:addSkill(ahmoukuangfu)

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end
ahmoushizhi_shiCard = sgs.CreateSkillCard{
	name = "ahmoushizhi_shiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 4 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets >= 2
	end,
	on_use = function(self, room, source, targets)
		local count, n = #targets, #targets
		local sto = sgs.SPlayerList()
		for _, p in pairs(targets) do
			sto:append(p)
		end
		--if source:getState() == "online" then
			while n > 0 do --决定均分次序
				local m = count - n + 1
				local shiTarget = room:askForPlayerChosen(source, sto, "ahmoushizhi_shi", "ahmoushizhi_shiTarget:" .. m)
				room:setPlayerMark(shiTarget, "ahmoushizhi_shiTarget", m)
				sto:removeOne(shiTarget)
				n = n - 1
			end
		--[[else
			for _, p in pairs(targets) do
				local m = count - n + 1
				room:setPlayerMark(p, "ahmoushizhi_shiTarget", m)
				n = n - 1
			end
		end]]
		local sjf_cards = {}
		for _, id in sgs.qlist(room:getDiscardPile()) do
			local cd = sgs.Sanguosha:getCard(id)
			table.insert(sjf_cards, cd)
		end
		local a, sjf_ints = 12, sgs.IntList()
		while a > 0 do
			local sjf_card = sjf_cards[math.random(1, #sjf_cards)]
			sjf_ints:append(sjf_card:getEffectiveId())
			table.removeOne(sjf_cards, sjf_card)
			a = a - 1
		end
		local one, two, three, four, five = nil, nil, nil, nil, 0
		for _, p in pairs(targets) do
			if p:getMark("ahmoushizhi_shiTarget") == 1 then
				one = p
			elseif p:getMark("ahmoushizhi_shiTarget") == 2 then
				two = p
			elseif p:getMark("ahmoushizhi_shiTarget") == 3 then
				three = p
			elseif p:getMark("ahmoushizhi_shiTarget") == 4 then
				four = p
			end
			room:setPlayerMark(p, "ahmoushizhi_shiTarget", 0)
		end
		if count == 2 then --2人，每人6张
			five = 6
		elseif count == 3 then --3人，每人4张
			five = 4
		elseif count == 4 then --4人，每人3张
			five = 3
		end
		room:fillAG(sjf_ints) --开始均分
		source:speak("约官职，抚百姓，\
		无岁不征而食兵足。")
		room:broadcastSkillInvoke("ahmoushizhi")
		if one ~= nil and not sjf_ints:isEmpty() then
			local six = five
			local to_get = sgs.IntList()
			while six > 0 do
				local card_id = room:askForAG(one, sjf_ints, false, "ahmoushizhi_shi")
				sjf_ints:removeOne(card_id)
				to_get:append(card_id)
				room:takeAG(nil, card_id, false)
				six = six - 1
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(getCardList(to_get))
				one:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		if two ~= nil and not sjf_ints:isEmpty() then
			local six = five
			local to_get = sgs.IntList()
			while six > 0 do
				local card_id = room:askForAG(two, sjf_ints, false, "ahmoushizhi_shi")
				sjf_ints:removeOne(card_id)
				to_get:append(card_id)
				room:takeAG(nil, card_id, false)
				six = six - 1
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(getCardList(to_get))
				two:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		if three ~= nil and not sjf_ints:isEmpty() then
			local six = five
			local to_get = sgs.IntList()
			while six > 0 do
				local card_id = room:askForAG(three, sjf_ints, false, "ahmoushizhi_shi")
				sjf_ints:removeOne(card_id)
				to_get:append(card_id)
				room:takeAG(nil, card_id, false)
				six = six - 1
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(getCardList(to_get))
				three:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		if four ~= nil and not sjf_ints:isEmpty() then
			local six = five
			local to_get = sgs.IntList()
			while six > 0 do
				local card_id = room:askForAG(four, sjf_ints, false, "ahmoushizhi_shi")
				sjf_ints:removeOne(card_id)
				to_get:append(card_id)
				room:takeAG(nil, card_id, false)
				six = six - 1
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(getCardList(to_get))
				four:obtainCard(dummy)
			end
			dummy:deleteLater()
		end
		room:clearAG()
	end,
}


ahmoushizhi_zhiCard = sgs.CreateSkillCard{
	name = "ahmoushizhi_zhiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		source:speak("明赏罚，布公道，\
		刑政虽峻而民无忿。")
		room:broadcastSkillInvoke("ahmoushizhi")
		room:addPlayerMark(source, "ahmoushizhi_zhiSource")
		for _, p in pairs(targets) do
			room:addPlayerMark(p, "&ahmoushizhi_zhiTarget")
		end
	end,
}
ahmoushizhiVS = sgs.CreateZeroCardViewAsSkill{
	name = "ahmoushizhi",
	view_as = function()
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoushizhi_zhi" then
			return ahmoushizhi_zhiCard:clone()
		end
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoushizhi_shi" then
			return ahmoushizhi_shiCard:clone()
		end
	end,
	enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoushizhi_zhi" then return true end
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoushizhi_shi" then return true end
	end
}

ahmoushizhi = sgs.CreateTriggerSkill{
	name = "ahmoushizhi",
	view_as_skill = ahmoushizhiVS,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local count = room:alivePlayerCount()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, "@ahmoushizhi-ZHI", data) then --治
				room:askForUseCard(player, "@@ahmoushizhi_zhi", "@ahmoushizhi_zhi-card")
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and count > 2 then
			if room:getDiscardPile():length() < 12 then return false end
			if room:askForSkillInvoke(player, "@ahmoushizhi-SHI", data) then --识
				room:askForUseCard(player, "@@ahmoushizhi_shi", "@ahmoushizhi_shi-card")
			end
		end
	end,
}

ahmoushizhi_zx = sgs.CreateTriggerSkill{
	name = "#ahmoushizhi_zx",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local resp = data:toCardResponse()
				card = resp.m_card
			end
			if card and not card:isKindOf("SkillCard") and player:getMark("&ahmoushizhi_zhiTarget") > 0 and not player:isNude() and player:canDiscard(player, "he") then
				--不设置触发文字播报和语音播放了，不然太频繁
				room:askForDiscard(player, "ahmoushizhi_zx", 1, 1, false, true)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("ahmoushizhi_zhiSource") > 0 then
			room:setPlayerMark(player, "ahmoushizhi_zhiSource", 0)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&ahmoushizhi_zhiTarget") > 0 then
					room:setPlayerMark(p, "&ahmoushizhi_zhiTarget", 0)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and (player:getMark("&ahmoushizhi_zhiTarget") > 0 or player:getMark("ahmoushizhi_zhiSource") > 0)
	end,
}

ah_mou_zhugeliang:addSkill(ahmoushizhi)
ah_mou_zhugeliang:addSkill(ahmoushizhi_zx)
extension_M:insertRelatedSkills("ahmoushizhi", "#ahmoushizhi_zx")
--“识治-治”

--“识治-识”

----

ahmoutaozeiCard = sgs.CreateSkillCard{
	name = "ahmoutaozeiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if math.random() <= 0.5 then
			source:speak("降羌蛮，复二郡，\
			神武赫然震八荒。")
		else
			source:speak("志靖乱，整三军，\
			兵出祁山兴炎汉。")
		end
		local qcs = {}
		for _, id in sgs.qlist(source:getPile("ahmtz_QC")) do
			local qc_card = sgs.Sanguosha:getCard(id)
			table.insert(qcs, qc_card)
		end
		local qc = qcs[math.random(1, #qcs)]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "ahmoutaozei", nil)
		room:throwCard(qc, reason, nil)
	end,
}
ahmoutaozeiVS = sgs.CreateZeroCardViewAsSkill{
	name = "ahmoutaozei",
	n = 0,
	view_as = function()
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoutaozei_tm" then
			local pattern = sgs.Self:property("ahmoutaozei_tm"):toString()
			local cd = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
			cd:setSkillName("ahmoutaozei")
			return cd
		end
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoutaozei" then
			return ahmoutaozeiCard:clone()
		end
	end,
	enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoutaozei" then return true end
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ahmoutaozei_tm" then return true end
	end
}
ahmoutaozei = sgs.CreateTriggerSkill{
	name = "ahmoutaozei",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.TargetSpecified},
	view_as_skill = ahmoutaozeiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:isKongcheng() then continue end
				room:sendCompulsoryTriggerLog(p, self:objectName())
				if math.random() <= 0.5 then
					p:speak("降羌蛮，复二郡，\
					神武赫然震八荒。")
				else
					p:speak("志靖乱，整三军，\
					兵出祁山兴炎汉。")
				end
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(p:getHandcards())
				p:addToPile("ahmtz_QC", dummy, false)
				dummy:deleteLater()
			end
		elseif event == sgs.CardUsed then
			if use.card and not use.card:isKindOf("SkillCard") and use.card:getSkillName() ~= self:objectName() and not use.card:isKindOf("Nullification") then
				for _, ah in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if ah:getPile("ahmtz_QC"):length() == 0 then continue end
					room:setTag("ahmoutaozei", data)
					local QC = room:askForUseCard(ah, "@@ahmoutaozei", "@ahmoutaozei-qc")
					room:removeTag("ahmoutaozei")
					if QC then
						if use.card:isKindOf("EquipCard") then
							room:throwCard(use.card, nil, nil)
						else
							local nullified_list = use.nullified_list
							table.insert(nullified_list, "_ALL_TARGETS")
				    		use.nullified_list = nullified_list
				   			data:setValue(use)
						end
						if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
							local name = use.card:objectName()
							if name ~= "jink" and name ~= "nullification" and name ~= "jl_wuxiesy" then
								room:setPlayerProperty(ah, "ahmoutaozei_tm", sgs.QVariant(name))
								room:askForUseCard(ah, "@@ahmoutaozei_tm", "@ahmoutaozei_tm-card:" .. name)
								room:setPlayerProperty(ah, "ahmoutaozei_tm", sgs.QVariant(false))
							end
						else
							room:drawCards(ah, 1, self:objectName())
						end
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			if use.card and use.card:isVirtualCard() and use.card:subcardsLength() == 0 and not use.card:isKindOf("SkillCard")
			and use.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(room:getAllPlayers()) do
					table.insert(no_respond_list, p:objectName())
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
ahmoutaozeiVC = sgs.CreateTargetModSkill{
	name = "#ahmoutaozeiVC",
	pattern = "^SkillCard",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("ahmoutaozei") and card and card:isVirtualCard() and card:subcardsLength() == 0 then
			return 1000
		else
			return 0
		end
	end,
}
ah_mou_zhugeliang:addSkill(ahmoutaozei)
ah_mou_zhugeliang:addSkill(ahmoutaozeiVC)
extension_M:insertRelatedSkills("ahmoutaozei", "#ahmoutaozeiVC")


--FC谋诸葛亮
fc_mou_zhugeliang = sgs.General(extension_M, "fc_mou_zhugeliang", "shu", 3, true) --, false, false, 3, 0, 3)

fcmouguanxing = sgs.CreateTriggerSkill{
	name = "fcmouguanxing",
	--global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:gainMark("&fcmouguanxing", 7)
			if player:getMark("&fcmouguanxing") > 7 then --基本没有意义的一段，形式主义罢了
				room:setPlayerMark(player, "&fcmouguanxing", 7)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, fcmzg in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if fcmzg:getMark("&fcmouguanxing") == 0 or fcmzg:hasFlag(self:objectName()) then continue end
				if room:askForSkillInvoke(fcmzg, self:objectName(), data) then
					local s = fcmzg:getMark("&fcmouguanxing")
					local stars = room:getNCards(s, false)
					room:broadcastSkillInvoke(self:objectName())
					room:askForGuanxing(fcmzg, stars)
					if fcmzg:objectName() ~= player:objectName() then
						room:sendCompulsoryTriggerLog(fcmzg, self:objectName())
						fcmzg:loseMark("&fcmouguanxing", 1)
					elseif fcmzg:objectName() == player:objectName() and fcmzg:getMark("&fcmouguanxing") < 7 then
						room:sendCompulsoryTriggerLog(fcmzg, self:objectName())
						fcmzg:gainMark("&fcmouguanxing", 1)
					end
				else
					room:setPlayerFlag(fcmzg, self:objectName())
				end
			end
		elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag(self:objectName()) then
					room:setPlayerFlag(p, "-fcmouguanxing")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fcmouguanxingSL = sgs.CreateTriggerSkill{
	name = "#fcmouguanxingSL",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = data:toMark()
		if mark.name == "@fcSOUL" and mark.gain < 0 and mark.who and mark.who:objectName() == player:objectName() then
			if player:getMark("&fcmouguanxing") + mark.gain >= 0 then
				room:sendCompulsoryTriggerLog(player, "fcmouguanxing")
				player:loseMark("&fcmouguanxing", 0-mark.gain)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("fcmouguanxing")
	end,
}
fc_mou_zhugeliang:addSkill(fcmouguanxing)
fc_mou_zhugeliang:addSkill(fcmouguanxingSL)
extension_M:insertRelatedSkills("fcmouguanxing", "#fcmouguanxingSL")

fcmoukongcheng = sgs.CreateTriggerSkill{
	name = "fcmoukongcheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
				room:broadcastSkillInvoke("kongcheng")
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel"))
			and damage.to and damage.to:objectName() == player:objectName() and player:isKongcheng() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke("kongcheng")
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
	end,
}
fcmoukongchengMY = sgs.CreateTriggerSkill{
	name = "#fcmoukongchengMY",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.Damage,sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.from and use.from:isAlive() and player:hasSkill("fcmoukongcheng")
			and player:getMark("fcmoukongchengMY-Clear") == 0 and player:getMark("fcmoukongchengMY_FAIL") == 0 and not player:isKongcheng() then
				if room:askForSkillInvoke(player, "fcmoukongchengMY", data) then
					room:addPlayerMark(player, "fcmoukongchengMY-Clear")
					room:sendCompulsoryTriggerLog(player, "fcmoukongcheng")
					room:broadcastSkillInvoke("fcmoukongcheng", 1)
					local choiceFrom = room:askForChoice(player, "@MouYi-fckc", "F1+F2")
					local choiceTo = room:askForChoice(use.from, "@MouYi-fckc", "T1+T2")
				
					--“谋弈”成功
					if choiceFrom == "F1" and choiceTo ~= "T1" then --空城成功
						local log = sgs.LogMessage()
						log.type = "$MouYi_success"
						log.from = player
						log.to:append(use.from)
						room:sendLog(log)
						room:broadcastSkillInvoke("fcmoukongcheng", 2)
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(player:getHandcards())
						player:addToPile("fcmoukongcheng", dummy, false)
						dummy:deleteLater()
					elseif choiceFrom ~= "F1" and choiceTo == "T1" then --突击成功
						local log = sgs.LogMessage()
						log.type = "$MouYi_success"
						log.from = player
						log.to:append(use.from)
						room:sendLog(log)
						room:broadcastSkillInvoke("fcmoukongcheng", 3)
						room:setPlayerFlag(player, "fcmoukongchengMY_trcjFrom")
						room:setPlayerFlag(use.from, "fcmoukongchengMY_trcjTo")
						if not use.from:isKongcheng() then
							local chuqibuyi = sgs.Sanguosha:cloneCard("chuqibuyi", sgs.Card_NoSuit, 0)
							chuqibuyi:deleteLater()
							chuqibuyi:setSkillName("fcmoukongcheng")
							room:useCard(sgs.CardUseStruct(chuqibuyi, player, use.from), false)
						else
							room:damage(sgs.DamageStruct("fcmoukongcheng", player, use.from))
						end
						if player:hasFlag("fcmoukongchengMY_trcjFrom") or use.from:hasFlag("fcmoukongchengMY_trcjTo") then --残存有标志，证明没能通过造成伤害清标志
							if use.from:isAlive() then
								room:broadcastSkillInvoke("fcmoukongcheng", 4)
								local fj_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								fj_slash:setSkillName("fcmoukongcheng")
								fj_slash:deleteLater()
								room:useCard(sgs.CardUseStruct(fj_slash, use.from, player), false)
							end
						end
						room:setPlayerFlag(player, "-fcmoukongchengMY_trcjFrom")
						room:setPlayerFlag(use.from, "-fcmoukongchengMY_trcjTo")
					else
						--“谋弈”失败
						local log = sgs.LogMessage()
						log.type = "$MouYi_fail"
						log.from = player
						log.to:append(use.from)
						room:sendLog(log)
						room:broadcastSkillInvoke("fcmoukongcheng", 4)
						room:addPlayerMark(player, "fcmoukongchengMY_FAIL")
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.to then
				if damage.from:hasFlag("fcmoukongchengMY_trcjFrom") then room:setPlayerFlag(damage.from, "-fcmoukongchengMY_trcjFrom") end
				if damage.to:hasFlag("fcmoukongchengMY_trcjTo") and damage.to:isAlive() then room:setPlayerFlag(damage.to, "-fcmoukongchengMY_trcjTo") end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getPile("fcmoukongcheng"):length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile("fcmoukongcheng"))
					room:obtainCard(p, dummy, false)
					dummy:deleteLater()
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("fcmoukongchengMY_FAIL") > 0 then
				room:setPlayerMark(player, "fcmoukongchengMY_FAIL", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fc_mou_zhugeliang:addSkill(fcmoukongcheng)
fc_mou_zhugeliang:addSkill(fcmoukongchengMY)
extension_M:insertRelatedSkills("fcmoukongcheng", "#fcmoukongchengMY")
fc_mou_zhugeliang:addRelateSkill("fcSOUL_three")
--

--灬魂灵灬--
fcSOUL = sgs.CreateTriggerSkill{
	name = "fcSOUL",
	global = true,
	priority = {9999, 9999},
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			--[[if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 1)
			end]]
			if isSpecialOne(player, "谋陈宫[FC]") or player:getGeneralName() == "fc_mou_chengong" or player:getGeneral2Name() == "fc_mou_chengong" then
				player:gainMark("@fcSOUL", 2)
			end
			if isSpecialOne(player, "谋诸葛亮[FC]") or player:getGeneralName() == "fc_mou_zhugeliang" or player:getGeneral2Name() == "fc_mou_zhugeliang" then
				player:gainMark("@fcSOUL", 3)
			end
			--[[if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 4)
			end
			if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 5)
			end
			if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 6)
			end
			if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 7)
			end
			if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 8)
			end
			if isSpecialOne(player, "？") then
				player:gainMark("@fcSOUL", 9)
			end]]
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:getMark("@fcSOUL") == 0 or dying.who:objectName() ~= player:objectName() then return false end
			while player:getHp() <= 0 and player:getMark("@fcSOUL") > 0 do
				sgs.Sanguosha:playSystemAudioEffect("fcSOUL_used")
				player:loseMark("@fcSOUL", 1)
				local log, recover = sgs.LogMessage(), nil
				log.type = "$fcSOUL_used"
				log.from = player
				log.arg = player:getHp()
				if player:getHp() < -1 then
					log.arg2 = 0
					recover = math.min(0 - player:getHp(), player:getMaxHp() - player:getHp())
				else
					log.arg2 = 1
					recover = math.min(1 - player:getHp(), player:getMaxHp() - player:getHp())
				end
				room:sendLog(log)
				room:recover(player, sgs.RecoverStruct(player, nil, recover))
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
if not sgs.Sanguosha:getSkill("fcSOUL") then skills:append(fcSOUL) end
--🔥=====🔥--
fcSOUL_one = sgs.CreateTriggerSkill{
	name = "fcSOUL_one",
	priority = 1,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_two = sgs.CreateTriggerSkill{
	name = "fcSOUL_two",
	priority = 2,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_three = sgs.CreateTriggerSkill{
	name = "fcSOUL_three",
	priority = 3,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_four = sgs.CreateTriggerSkill{
	name = "fcSOUL_four",
	priority = 4,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_five = sgs.CreateTriggerSkill{
	name = "fcSOUL_five",
	priority = 5,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_six = sgs.CreateTriggerSkill{
	name = "fcSOUL_six",
	priority = 6,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_seven = sgs.CreateTriggerSkill{
	name = "fcSOUL_seven",
	priority = 7,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_eight = sgs.CreateTriggerSkill{
	name = "fcSOUL_eight",
	priority = 8,
	events = {},
	on_trigger = function()
	end,
}
fcSOUL_nine = sgs.CreateTriggerSkill{
	name = "fcSOUL_nine",
	priority = 9,
	events = {},
	on_trigger = function()
	end,
}
if not sgs.Sanguosha:getSkill("fcSOUL_one") then skills:append(fcSOUL_one) end
if not sgs.Sanguosha:getSkill("fcSOUL_two") then skills:append(fcSOUL_two) end
if not sgs.Sanguosha:getSkill("fcSOUL_three") then skills:append(fcSOUL_three) end
if not sgs.Sanguosha:getSkill("fcSOUL_four") then skills:append(fcSOUL_four) end
if not sgs.Sanguosha:getSkill("fcSOUL_five") then skills:append(fcSOUL_five) end
if not sgs.Sanguosha:getSkill("fcSOUL_six") then skills:append(fcSOUL_six) end
if not sgs.Sanguosha:getSkill("fcSOUL_seven") then skills:append(fcSOUL_seven) end
if not sgs.Sanguosha:getSkill("fcSOUL_eight") then skills:append(fcSOUL_eight) end
if not sgs.Sanguosha:getSkill("fcSOUL_nine") then skills:append(fcSOUL_nine) end
  ---------
--



--FC谋陈宫
fc_mou_chengong = sgs.General(extension_M, "fc_mou_chengong", "qun", 3, true, false, false, 2) --, 0, 2)

fcmoumingceCard = sgs.CreateSkillCard{
	name = "fcmoumingceCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("fcmoumingced")
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:setPlayerFlag(effect.to, "fcmoumingced")
		room:obtainCard(effect.to, self, false)
		local choice = room:askForChoice(effect.to, "fcmoumingce", "1+2")
		if choice == "1" then
			room:loseHp(effect.to, 1, true, effect.from, self:objectName())
			room:drawCards(effect.from, 2, "fcmoumingce")
			effect.from:gainMark("&fcmCe", 1)
		else
			room:drawCards(effect.to, 1, "fcmoumingce")
		end
	end,
}
fcmoumingceVS = sgs.CreateOneCardViewAsSkill{
	name = "fcmoumingce",
	filter_pattern = ".!",
	view_as = function(self, card)
		local fcmc_card = fcmoumingceCard:clone()
		fcmc_card:addSubcard(card:getId())
		fcmc_card:setSkillName(self:objectName())
		return fcmc_card
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}
fcmoumingce = sgs.CreateTriggerSkill{
	name = "fcmoumingce",
	view_as_skill = fcmoumingceVS,
	events = {sgs.CardUsed, sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "fcmoumingce") then
				room:broadcastSkillInvoke("fcmoumingce", math.random(1,2))
			end
		else
			if player:getPhase() ~= sgs.Player_Play then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("fcmoumingced") then
					room:setPlayerFlag(p, "-fcmoumingced")
				end
			end
			if not player:hasSkill("fcmoumingce") or player:getMark("&fcmCe") == 0 then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local n = player:getMark("&fcmCe")
				local dbfk = room:askForPlayerChosen(player, room:getOtherPlayers(player), "fcmoumingce", "fcmoumingce-DMGto:" .. n, true, true)
				if dbfk then
					if n < 3 then
						room:broadcastSkillInvoke("fcmoumingce", 3)
					else
						room:broadcastSkillInvoke("fcmoumingce", 4)
						room:getThread():delay(3500)
					end
					room:damage(sgs.DamageStruct("fcmoumingce", player, dbfk, n))
					player:loseAllMarks("&fcmCe")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
fc_mou_chengong:addSkill(fcmoumingce)

fcmouzhichi = sgs.CreateTriggerSkill{
	name = "fcmouzhichi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			if damage.to and damage.to:objectName() == player:objectName() and player:getMark("&fcmouzhichi-Clear") == 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				player:gainMark("&fcmCe-Clear", 1)
				player:gainMark("&fcmouzhichi-Clear", 1)
			end
		elseif event == sgs.DamageInflicted then
			if damage.to and damage.to:objectName() == player:objectName() and player:getMark("&fcmouzhichi-Clear") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				damage.prevented = true
                data:setValue(damage)
                return true
			end
		end
	end,
}

fc_mou_chengong:addSkill(fcmouzhichi)
fc_mou_chengong:addRelateSkill("fcSOUL_two")

--

--AH谋吕布
ah_mou_lvbu = sgs.General(extension_M, "ah_mou_lvbu", "qun", 5, true)

ahmouwushuang = sgs.CreateTriggerSkill {
	name = "ahmouwushuang",
	events = { sgs.TargetSpecified, sgs.CardEffected, sgs.CardResponded, sgs.PreCardResponded, sgs.ConfirmDamage, sgs.CardUsed, sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf("Duel") then
                local wushuang = {}
                if player:hasSkill(self:objectName()) then
                    for _, p in sgs.qlist(use.to) do
                        table.insert(wushuang, p:objectName())
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    if p:hasSkill(self:objectName()) then
                        table.insert(wushuang, player:objectName())
                    end
                end
                room:setTag("ahmouwushuang_"..use.card:toString(), sgs.QVariant(table.concat(wushuang, "+")))
            elseif use.card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
                local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
                local index = 1
                for _, p in sgs.qlist(use.to) do
                    jink_table[index] = jink_table[index] + 1
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_table))
                player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("Duel") then
                local wushuang = room:getTag("ahmouwushuang_" .. effect.card:toString()):toString()
                if wushuang and wushuang ~= "" then
                    if string.find(wushuang, effect.to:objectName()) or string.find(wushuang, effect.from:objectName()) then
                        room:setTag("ahmouwushuangData", data)
                    end
                end
            end
        elseif event == sgs.PreCardResponded then
			local resp = data:toCardResponse()
			if resp.m_toCard and resp.m_toCard:isDamageCard() and resp.m_who and resp.m_who:hasSkill(self:objectName()) and player:objectName() ~= resp.m_who:objectName() then
				room:setCardFlag(resp.m_card, "ahmouwushuangObtain"..resp.m_who:objectName())
			end
        elseif event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_toCard and resp.m_toCard:isKindOf("Duel") and not player:hasFlag("ahmouwushuangSlash") then
                local wushuang = room:getTag("ahmouwushuang_" .. resp.m_toCard:toString()):toString()
                if wushuang and wushuang ~= "" then
                    if string.find(wushuang, player:objectName()) then
                        room:setPlayerFlag(player,"ahmouwushuangSlash")
						local card = room:askForCard(player, "slash", "duel-slash:"..resp.m_who:objectName(), room:getTag("ahmouwushuangData"), sgs.Card_MethodResponse, resp.m_who, false, "",false,resp.m_toCard)
                        if not card then
                            resp.nullified = true
                            data:setValue(resp)
						else
							room:setCardFlag(resp.m_toCard, "ahmouwushuang"..player:objectName())
							room:setCardFlag(resp.m_card, "ahmouwushuangObtain"..resp.m_who:objectName())
                        end
                        room:setPlayerFlag(player,"-ahmouwushuangSlash")
                    end
                end
            end
			
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.whocard and use.whocard:isDamageCard() and use.who and use.who:hasSkill(self:objectName()) and player:objectName() ~= use.who:objectName() then
                room:setCardFlag(use.whocard, "ahmouwushuang"..player:objectName())
				room:setCardFlag(use.card, "ahmouwushuangObtain"..use.who:objectName())
            end
        elseif event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.card and damage.card:isDamageCard() and player:hasSkill(self:objectName()) and not damage.card:hasFlag("ahmouwushuang"..damage.to:objectName()) then
               	local killfather = damage.damage
				local log = sgs.LogMessage()
				log.type = "$ahmouwushuang_double"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = killfather
				log.arg2 = killfather*2
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				damage.damage = killfather*2
				data:setValue(damage)
            end
        elseif event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) and (move.to_place == sgs.Player_DiscardPile) and (bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_LETUSE or bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_RESPONSE  or bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_USE)   then
				local card = move.reason.m_extraData:toCard()
				if card and card:hasFlag("ahmouwushuangObtain"..player:objectName())  then
					local dc = dummyCard()
					for _, id in sgs.qlist(move.card_ids) do
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						dc:addSubcard(id)
					end
					
					if dc:subcardsLength() > 0 then
						room:obtainCard(player, dc, false)
					end
				end
				
            end
        end
    end,
}
ah_mou_lvbu:addSkill(ahmouwushuang)

ahmoujiedouCard = sgs.CreateSkillCard{
	name = "ahmoujiedouCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:hasFlag("ahmoujiedouTarget")
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:obtainCard(effect.to, self, false)
		room:setPlayerFlag(effect.to, "-ahmoujiedouTarget")
	end,
}
ahmoujiedouVS = sgs.CreateOneCardViewAsSkill{
	name = "ahmoujiedou",
	filter_pattern = ".!",
	view_as = function(self, card)
		local ahmjd_card = ahmoujiedouCard:clone()
		ahmjd_card:addSubcard(card:getId())
		ahmjd_card:setSkillName(self:objectName())
		return ahmjd_card
	end,
	response_pattern = "@@ahmoujiedou",
}
ahmoujiedou = sgs.CreateTriggerSkill{
	name = "ahmoujiedou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecifying},
	view_as_skill = ahmoujiedouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:alivePlayerCount() < 3 then return false end --少于三人不可能满足条件
		local use = data:toCardUse()
		if use.from and use.card and use.card:isDamageCard() then
			for _, p in sgs.qlist(use.to) do
				if p:objectName() == use.from:objectName() then continue end
				for _, ahmlb in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if ahmlb:inMyAttackRange(use.from) and ahmlb:inMyAttackRange(p) and ahmlb:getCards("he"):length() >= 2 then
						room:setPlayerFlag(use.from, "ahmoujiedouTarget")
						room:setPlayerFlag(p, "ahmoujiedouTarget")
						if not room:askForUseCard(ahmlb, "@@ahmoujiedou", "@ahmoujiedou-cardgive") then
							room:setPlayerFlag(ahmlb, "ahmoujiedouBreak")
						end
						if not ahmlb:hasFlag("ahmoujiedouBreak") then
							if not room:askForUseCard(ahmlb, "@@ahmoujiedou", "@ahmoujiedou-cardgive") then
								room:setPlayerFlag(ahmlb, "ahmoujiedouBreak")
							end
						end
						if use.from:hasFlag("ahmoujiedouTarget") then room:setPlayerFlag(use.from, "-ahmoujiedouTarget") end
						if p:hasFlag("ahmoujiedouTarget") then room:setPlayerFlag(p, "-ahmoujiedouTarget") end
						if ahmlb:hasFlag("ahmoujiedouBreak") then
							room:setPlayerFlag(ahmlb, "-ahmoujiedouBreak")
							break
						else
							room:broadcastSkillInvoke(self:objectName())
							room:obtainCard(ahmlb, use.card)
							room:setPlayerFlag(p, "ahmoujiedouAllBreak")
							break
						end
					end
				end
				if p:hasFlag("ahmoujiedouAllBreak") then
					room:setPlayerFlag(p, "-ahmoujiedouAllBreak")
					break
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
ah_mou_lvbu:addSkill(ahmoujiedou)

ahmoubaifu = sgs.CreateTriggerSkill{
	name = "ahmoubaifu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == player:objectName() and move.from and move.from:objectName() ~= player:objectName()
		and player:getMark("&ahmoubaifu_lun") < 3 then
			for _, id in sgs.qlist(move.card_ids) do
				if not room:askForSkillInvoke(player, self:objectName(), data) then continue end
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 1, self:objectName())
				local _movefrom
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if move.from:objectName() == p:objectName() then
						_movefrom = p
					break end
				end
				if _movefrom then
					room:drawCards(_movefrom, 1, self:objectName())
				end
				room:addPlayerMark(player, "&ahmoubaifu_lun")
				if player:getMark("&ahmoubaifu_lun") >= 3 then break end
			end
		end
	end,
}
ah_mou_lvbu:addSkill(ahmoubaifu)


--SD1 003 神黄盖
f_shenhuanggai = sgs.General(extension, "f_shenhuanggai", "god", 8, true)

f_kuzhaCard = sgs.CreateSkillCard{
    name = "f_kuzhaCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    room:loseMaxHp(source, 1)
		if not source:hasSkill("noskurou") then
		    room:acquireOneTurnSkills(source, "f_kuzha","noskurou")
		end
	end,
}
f_kuzha = sgs.CreateZeroCardViewAsSkill{
    name = "f_kuzha",
	waked_skills = "noskurou",
	view_as = function()
		return f_kuzhaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_kuzhaCard")
	end,
}

f_shenhuanggai:addSkill(f_kuzha)

f_shenxianshizuCard = sgs.CreateSkillCard{
	name = "f_shenxianshizuCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.to:getRoom()
		room:removePlayerMark(effect.from, "@f_shenxianshizu")
		room:obtainCard(effect.to, effect.from:wholeHandCards(), false)
		room:setPlayerMark(effect.to, "zbkcTarget+to+"..effect.from:objectName().."-Clear", 1)
		room:setPlayerMark(effect.to, "&f_shenxianshizu+to+"..effect.from:objectName().."-Clear", 1)
		--room:setEmotion(effect.to, "huoshaochibi")
		room:doSuperLightbox("f_shenhuanggai", "huoshaochibi")
	end,
}
f_shenxianshizuVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_shenxianshizu",
	view_as = function()
		return f_shenxianshizuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_shenxianshizu") > 0
	end,
}
f_shenxianshizu = sgs.CreateTriggerSkill{
	name = "f_shenxianshizu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_shenxianshizu",
	events = {sgs.ConfirmDamage},
	view_as_skill = f_shenxianshizuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire and damage.from:objectName() == player:objectName() and damage.to:getMark("zbkcTarget+to+"..player:objectName().."-Clear") > 0 then
			room:sendCompulsoryTriggerLog(player, "f_shenxianshizu")
			room:broadcastSkillInvoke("f_shenxianshizu")
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_shenxianshizu")
	end,
}
f_shenhuanggai:addSkill(f_shenxianshizu)
--通过“身先”获得的BUFF：
f_shenxianshizu_buff = sgs.CreateTargetModSkill{
	name = "#f_shenxianshizu_buff",
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("f_shenxianshizu") and card:isKindOf("Slash") and to and to:getMark("zbkcTarget+to+"..from:objectName().."-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, from, card, to)
		if from:hasSkill("f_shenxianshizu") and card:isKindOf("Slash") and to and to:getMark("zbkcTarget+to+"..from:objectName().."-Clear") > 0  then
			return 1000
		else
			return 0
		end
	end,
}

f_shenhuanggai:addSkill(f_shenxianshizu_buff)
extension:insertRelatedSkills("f_shenxianshizu","#f_shenxianshizu_buff")



--

--SD1 004 神华佗
f_shenhuatuo = sgs.General(extension, "f_shenhuatuo", "god", 3, true)

f_liaoduCard = sgs.CreateSkillCard{
    name = "f_liaoduCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    return #targets == 0
	end,
	on_use = function(self, room, source, targets)
	    local gy = targets[1]
		local recover = sgs.RecoverStruct()
		recover.recover = 1
		recover.who = gy
		room:recover(gy, recover)
		room:drawCards(gy, 1, "f_liaodu")
		if gy:hasJudgeArea() then
			gy:throwJudgeArea() --以此来实现清空判定区
			gy:obtainJudgeArea()
		end
		if gy:isChained() then
			room:setPlayerProperty(gy, "chained", sgs.QVariant(false))
		end
		if not gy:faceUp() then
			gy:turnOver()
		end
	end,
}
f_liaodu = sgs.CreateViewAsSkill{
    name = "f_liaodu",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
	    if #cards == 0 then return end
		local guagu_card = f_liaoduCard:clone()
		guagu_card:addSubcard(cards[1])
		return guagu_card
	end,
	enabled_at_play = function(self, player)
	    return not player:hasUsed("#f_liaoduCard")
	end,
}
f_shenhuatuo:addSkill(f_liaodu)

f_mafeiCard = sgs.CreateSkillCard{
    name = "f_mafeiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    return #targets == 0
	end,
	on_use = function(self, room, source, targets)
	    local br = targets[1]
		br:turnOver()
		if not br:faceUp() then
			room:addPlayerMark(br, "&f_mafeisan")
		end
	end,
}
f_mafeiVS = sgs.CreateViewAsSkill{
    name = "f_mafei",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return to_select:isKindOf("TrickCard")
	end,
	view_as = function(self, cards)
	    if #cards == 0 then return end
		local yao_card = f_mafeiCard:clone()
		yao_card:addSubcard(cards[1])
		return yao_card
	end,
	enabled_at_play = function(self, player)
	    return not player:hasUsed("#f_mafeiCard")
	end,
}
f_mafei = sgs.CreateTriggerSkill{
    name = "f_mafei",
	view_as_skill = f_mafeiVS,
	events = {sgs.DamageInflicted, sgs.PreHpRecover, sgs.TurnedOver},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted and not player:faceUp() then
		    local damage = data:toDamage()
			if not player:isNude() then
				room:askForDiscard(player, "f_mafei", 1, 1, false, true)
			end
			local log = sgs.LogMessage()
			log.type = "$f_mafeiBuff_jianshang"
			log.from = player
			room:sendLog(log)
			room:broadcastSkillInvoke("f_mafei")
			player:damageRevises(data, -1)
		elseif event == sgs.PreHpRecover and not player:faceUp() then
		    local recover = data:toRecover()
			local log = sgs.LogMessage()
			log.type = "$f_mafeiBuff_recover"
			log.from = player
			room:sendLog(log)
			room:broadcastSkillInvoke("f_mafei")
			recover.recover = recover.recover + 1
			data:setValue(recover)
		elseif event == sgs.TurnedOver and player:faceUp() then
			room:broadcastSkillInvoke("f_mafei")
			room:removePlayerMark(player, "&f_mafeisan")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&f_mafeisan") > 0
	end,
}
f_shenhuatuo:addSkill(f_mafei)

f_wuqinCard = sgs.CreateSkillCard{
    name = "f_wuqinCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    return #targets == 0
	end,
	on_use = function(self, room, source, targets)
	    local tudi = targets[1]
		--room:doLightbox("$f_wuqin_start")
		if math.random() > 0.2 then
		    room:getThread():delay(2000)
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_tiger_success"
			log.from = source
			room:sendLog(log)
			if tudi:getMark("&f_wuqin_tiger-SelfClear") == 0 then
				room:addPlayerMark(tudi, "&f_wuqin_tiger-SelfClear")
			end
		end
		if math.random() > 0.2 then
		    room:getThread():delay(2000)
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_deer_success"
			log.from = source
			room:sendLog(log)
			if tudi:getMark("&f_wuqin_deer-SelfClear") == 0 then
				room:addPlayerMark(tudi, "&f_wuqin_deer-SelfClear")
			end
		end
		if math.random() > 0.2 then
		    room:getThread():delay(2000)
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_bear_success"
			log.from = source
			room:sendLog(log)
			if tudi:getMark("&f_wuqin_bear-SelfClear") == 0 then
				room:addPlayerMark(tudi, "&f_wuqin_bear-SelfClear")
			end
		end
		if math.random() > 0.2 then
		    room:getThread():delay(2000)
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_ape_success"
			log.from = source
			room:sendLog(log)
			if tudi:getMark("&f_wuqin_ape-SelfClear") == 0 then
				room:addPlayerMark(tudi, "&f_wuqin_ape-SelfClear")
			end
		end
		if math.random() > 0.2 then
		    room:getThread():delay(2000)
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_bird_success"
			log.from = source
			room:sendLog(log)
			if tudi:getMark("&f_wuqin_bird-SelfClear") == 0 then
				room:addPlayerMark(tudi, "&f_wuqin_bird-SelfClear")
			end
		end
		local log = sgs.LogMessage()
		log.type = "$f_wuqin_finish"
		log.from = source
		room:sendLog(log)
	end,
}
f_wuqin = sgs.CreateViewAsSkill{
    name = "f_wuqin",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
	    if #cards == 0 then return end
		local wqx_card = f_wuqinCard:clone()
		wqx_card:addSubcard(cards[1])
		return wqx_card
	end,
	enabled_at_play = function(self, player)
	    return not player:hasUsed("#f_wuqinCard")
	end,
}
f_shenhuatuo:addSkill(f_wuqin)
--“五禽戏”
  --虎戏
f_wuqin_tigerBuff = sgs.CreateTriggerSkill{
	name = "#f_wuqin_tigerBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_tigerBuff"
			log.from = player
			log.card_str = damage.card:toString()
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&f_wuqin_tiger-SelfClear") > 0
	end,
}
  --鹿戏
f_wuqin_deerBuff = sgs.CreateTriggerSkill{
	name = "#f_wuqin_deerBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		if recover.card and (recover.card:isKindOf("Peach") or recover.card:isKindOf("Analeptic")) then
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_deerBuff"
			log.from = player
			log.card_str = recover.card:toString()
			room:sendLog(log)
			recover.recover = recover.recover + 1
			data:setValue(recover)
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&f_wuqin_deer-SelfClear") > 0
	end,
}
  --熊戏
f_wuqin_bearBuff = sgs.CreateTriggerSkill{
	name = "#f_wuqin_bearBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		else
			card = data:toCardResponse().m_card
		end
		if card and (card:isKindOf("Jink") or card:isKindOf("Nullification")) then
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_bearBuff"
			log.from = player
			room:sendLog(log)
			room:drawCards(player, 1, "f_wuqin")
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&f_wuqin_bear-SelfClear") > 0
	end,
}
  --猿戏
f_wuqin_apeBuff = sgs.CreateTargetModSkill{
	name = "#f_wuqin_apeBuff",
	frequency = sgs.Skill_Frequent,
	pattern = "Snatch, SupplyShortage",
	distance_limit_func = function(self, from)
		if from:getMark("&f_wuqin_ape-SelfClear") > 0 then
			return 1000
		else
			return 0
		end
	end,
}
f_wuqin_apeBuff_message = sgs.CreateTriggerSkill{
	name = "#f_wuqin_apeBuff_message",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and (use.card:isKindOf("Snatch") or use.card:isKindOf("SupplyShortage")) then
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_apeBuff"
			log.from = player
			log.card_str = use.card:toString()
			room:sendLog(log)
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&f_wuqin_ape-SelfClear") > 0
	end,
}
  --鸟戏
f_wuqin_birdBuff = sgs.CreateTriggerSkill{
    name = "#f_wuqin_birdBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.card then return false end
		if damage.card:isVirtualCard() then return false end
		if math.random() > 0.5 then
			local log = sgs.LogMessage()
			log.type = "$f_wuqin_birdBuff"
			log.from = player
			room:sendLog(log)
			room:setEmotion(player, "jink")
			damage.prevented = true
			data:setValue(damage)
		    return true
		end
	end,
	can_trigger = function(self, player)
	    return player and player:getMark("&f_wuqin_bird-SelfClear") > 0
	end,
}
f_shenhuatuo:addSkill(f_wuqin_tigerBuff)
extension:insertRelatedSkills("f_wuqin","#f_wuqin_tigerBuff")
f_shenhuatuo:addSkill(f_wuqin_deerBuff)
extension:insertRelatedSkills("f_wuqin","#f_wuqin_deerBuff")
f_shenhuatuo:addSkill(f_wuqin_bearBuff)
extension:insertRelatedSkills("f_wuqin","#f_wuqin_bearBuff")
f_shenhuatuo:addSkill(f_wuqin_apeBuff)
f_shenhuatuo:addSkill(f_wuqin_apeBuff_message)
extension:insertRelatedSkills("f_wuqin","#f_wuqin_apeBuff")
extension:insertRelatedSkills("f_wuqin","#f_wuqin_apeBuff_message")
extension:insertRelatedSkills("#f_wuqin_apeBuff","#f_wuqin_apeBuff_message")
f_shenhuatuo:addSkill(f_wuqin_birdBuff)
extension:insertRelatedSkills("f_wuqin","#f_wuqin_birdBuff")



--




--SD2 007 狂暴流氓云
f_KBliumangyun = sgs.General(extension, "f_KBliumangyun", "qun", 4, true)

f_KBliumangyun:addSkill("ollongdan")

f_chongzhen = sgs.CreateTriggerSkill{
	name = "f_chongzhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") and use.from:objectName() == player:objectName() then
				if table.contains(use.card:getSkillNames(), "ollongdan") then
					local me = 0
					for _, p in sgs.qlist(use.to) do
						if p:objectName() == player:objectName() then
							me = 1
							break
						end
					end
					if me == 0 then
						local victim = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "f_SuperChongzhen", true, true)
						if not victim:isAllNude() then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							local card_id = room:askForCardChosen(player, victim, "hej", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
						end
					elseif me == 1 then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:drawCards(player, 1, self:objectName())
					end
				else
					for _, p in sgs.qlist(use.to) do
						if p:isAllNude() or p:objectName() == player:objectName() then continue end
						local _data = sgs.QVariant()
						_data:setValue(p)
						p:setFlags("f_chongzhenTarget")
						local invoke = room:askForSkillInvoke(player, self:objectName(), _data)
						p:setFlags("-f_chongzhenTarget")
						if invoke then
							room:broadcastSkillInvoke(self:objectName())
							local card_id = room:askForCardChosen(player, p, "hej", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
						end
					end
				end
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card:isKindOf("BasicCard") and resp.m_who then
				if table.contains(resp.m_card:getSkillNames(), "ollongdan") then
					if resp.m_who:objectName() ~= player:objectName() then
						local victim = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "f_SuperChongzhen", true, true)
						if not victim:isAllNude() then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							local card_id = room:askForCardChosen(player, victim, "hej", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
						end
					else
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:drawCards(player, 1, self:objectName())
					end
				else
					if resp.m_who:objectName() == player:objectName() or resp.m_who:isAllNude() then return false end
					local _data = sgs.QVariant()
					_data:setValue(resp.m_who)
					if room:askForSkillInvoke(player, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						local card_id = room:askForCardChosen(player, resp.m_who, "hej", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
		        	end
				end
			end
		end
	end,
}
f_KBliumangyun:addSkill(f_chongzhen)

f_yicon = sgs.CreateDistanceSkill{
	name = "f_yicon",
	correct_func = function(self, from)
		if from:hasSkill(self:objectName()) then
			return -1
		else
			return 0
		end
	end,
}
f_yicon_cardmax = sgs.CreateMaxCardsSkill{
	name = "#f_yicon_cardmax",
	extra_func = function(self, player)
		if player:hasSkill("f_yicon") and player:getHp() <= 2 then
			return 1
		else
			return 0
		end
	end,
}
f_yiconAudio = sgs.CreateTriggerSkill{
	name = "#f_yiconAudio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHp() <= 2 then
			room:sendCompulsoryTriggerLog(player, "f_yicon")
			room:broadcastSkillInvoke("f_yicon")
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_yicon")
	end,
}
f_KBliumangyun:addSkill(f_yicon)
f_KBliumangyun:addSkill(f_yicon_cardmax)
f_KBliumangyun:addSkill(f_yiconAudio)
extension:insertRelatedSkills("f_yicon","#f_yicon_cardmax")
extension:insertRelatedSkills("f_yicon","#f_yiconAudio")

--


--SD2 009 神徐盛
f_shenxusheng = sgs.General(extension, "f_shenxusheng", "god", 4, false)
f_shenxusheng_skin = sgs.General(extension, "f_shenxusheng_skin", "god", 4, false, true, true)
f_shenxusheng_forSHZ = sgs.General(extension, "f_shenxusheng_forSHZ", "god", 4, false, true, true)

f_pojun = sgs.CreateTriggerSkill{
	name = "f_pojun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if use.card and use.card:isDamageCard() and not use.card:isKindOf("SkillCard") then
				for _, t in sgs.qlist(use.to) do
					if (t:isMale() and t:getMark("f_pojuned-Clear") > 1) or (not t:isMale() and t:getMark("f_pojuned-Clear") >= 1) then continue end
					if t:objectName() == player:objectName() then continue end
					local n = math.min(t:getCards("he"):length(), t:getHp())
					local _data = sgs.QVariant() _data:setValue(t)
					if n > 0 and player:askForSkillInvoke(self:objectName(), _data) then
						room:addPlayerMark(t, "f_pojuned-Clear")
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), t:objectName())
						local remove = sgs.IntList()
						for i = 1, n do--进行多次执行
							local id = room:askForCardChosen(player, t, "he", self:objectName(),
								false,--选择卡牌时手牌不可见
								sgs.Card_MethodNone,--设置为弃置类型
								remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
								i>1)--只有执行过一次选择才可取消
							if id < 0 then break end--如果卡牌id无效就结束多次执行
							remove:append(id)--将选择的id添加到虚拟卡的子卡表
						end
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(remove)
						local tt = sgs.SPlayerList()
						tt:append(t)
						t:addToPile("f_pojun", dummy, false, tt)
						dummy:deleteLater()
						local to_throw, bsc, trk, eqp = {}, 0, 0, 0
						for _, id in sgs.qlist(t:getPile("f_pojun")) do
							local cd = sgs.Sanguosha:getCard(id)
							if cd:isKindOf("BasicCard") then bsc = bsc + 1 end
							if cd:isKindOf("TrickCard") then trk = trk + 1 end
							if cd:isKindOf("EquipCard") then eqp = eqp + 1 end
							table.insert(to_throw, cd)
						end
						if bsc > 0 and player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player), true)
						end
						if trk > 0 then
							room:drawCards(player, 1, self:objectName())
						end
						if eqp > 0 and #to_throw > 0 then
							local totw = to_throw[math.random(1, #to_throw)]
							room:throwCard(totw, t, player)
						end
					end
				end
			end
		else
			local damage = data:toDamage()
			local to = damage.to
			if damage.card and damage.card:isDamageCard() and to and to:isAlive() then
				local tag = room:getTag("UseHistory"..damage.card:toString())
                if not tag then return end
				local use = tag:toCardUse()
                if not use then return end
				if use.to:length() <= player:getHp()  then
					if to:getHandcardNum() > player:getHandcardNum() or to:getEquips():length() > player:getEquips():length() then return false end
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), to:objectName())
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			end
		end
	end,
}
f_pojunReturn = sgs.CreateTriggerSkill{
	name = "#f_pojunReturn",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:getPile("f_pojun"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(p:getPile("f_pojun"))
					dummy:deleteLater()
					room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), self:objectName(), ""), false)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}

f_shenxusheng:addSkill(f_pojun)
f_shenxusheng:addSkill(f_pojunReturn)
f_shenxusheng_skin:addSkill("f_pojun")
f_shenxusheng_skin:addSkill("#f_pojunReturn")
f_shenxusheng_forSHZ:addSkill("f_pojun")
f_shenxusheng_forSHZ:addSkill("#f_pojunReturn")
extension:insertRelatedSkills("f_pojun","#f_pojunReturn")


f_yicheng = sgs.CreateTriggerSkill{
	name = "f_yicheng",
	priority = 3,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed, sgs.TargetConfirming, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed then
			if use.from and use.card and use.card:isDamageCard() and use.to then
				if use.from:objectName() == player:objectName() then return end
				for _, p in sgs.qlist(use.to) do
					if player:getMark("f_yichenged-Clear") == 0 and room:askForSkillInvoke(player, self:objectName(), ToData(p)) then
						room:addPlayerMark(player, "f_yichenged-Clear")
						room:broadcastSkillInvoke(self:objectName())
						if p:isMale() then
							room:drawCards(p, 2, self:objectName())
						else
							room:drawCards(p, 1, self:objectName())
						end
						local yic = room:askForDiscard(p, self:objectName(), 1, 1)
						if yic then
							for _, c in sgs.qlist(yic:getSubcards()) do
								local cd = sgs.Sanguosha:getCard(c)
								if cd:getSuit() == use.card:getSuit() then
									local nullified_list = use.nullified_list
									table.insert(nullified_list, p:objectName())
									use.nullified_list = nullified_list
									data:setValue(use)
									break
								end
							end
						end
					end
				end
			end
		end
	end,
}
f_shenxusheng:addSkill(f_yicheng)
f_shenxusheng_skin:addSkill("f_yicheng")
f_shenxusheng_forSHZ:addSkill("f_yicheng")

f_dazhuang = sgs.CreateTriggerSkill{
	name = "f_dazhuang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName()
		and player:getMark("f_dazhuang_lun") == 0 and player:hasEquipArea() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "f_dazhuang_lun")
				room:broadcastSkillInvoke(self:objectName())
				local dz = damage.damage
				while dz > 0 do
					local use_id = -1
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("EquipCard") then
							local e = card:getRealCard():toEquipCard():location()
							if player:hasEquipArea(e) then
								use_id = id
								break
							end
						end
					end
					if use_id >= 0 then
						local use_card = sgs.Sanguosha:getCard(use_id)
						if player:isAlive() and player:canUse(use_card, player, true) then
							room:useCard(sgs.CardUseStruct(use_card, player, player))
						end
					end
					dz = dz - 1
				end
			end
		end
	end,
}
f_shenxusheng:addSkill(f_dazhuang)
f_shenxusheng_skin:addSkill("f_dazhuang")
f_shenxusheng_forSHZ:addSkill("f_dazhuang")

f_haishiSM = sgs.CreateTriggerSkill{
	name = "f_haishiSM",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_haishiSM",
	events = {sgs.AskForPeachesDone, sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:hasSkill(self:objectName()) or p:getMark("@f_haishiSM") == 0 then continue end
					if not isSpecialOne(p, "七夕纪念") then continue end
					if (isSpecialOne(p, "神徐盛") and isSpecialOne(player, "神黄忠"))
					or (isSpecialOne(p, "神黄忠") and isSpecialOne(player, "神徐盛")) then
						if room:askForSkillInvoke(p, self:objectName(), data) then
							p:loseMark("@f_haishiSM")
							room:broadcastSkillInvoke(self:objectName())
							room:doLightbox("$f_haishiSM_toSHZ")
							if player:isWounded() then
								local rec = player:getMaxHp() - player:getHp()
								room:recover(player, sgs.RecoverStruct(p, nil, rec))
							end
							if not p:isAllNude() then
								local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _, cd in sgs.qlist(p:getCards("hej")) do
									dummy_card:addSubcard(cd)
								end
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), p:objectName(), self:objectName(), nil)
								room:moveCardTo(dummy_card, p, player, sgs.Player_PlaceHand, reason, false)
								dummy_card:deleteLater()
							end
							--代价：
							room:killPlayer(p)
						end
					end
				end
			end
		elseif event == sgs.PreHpRecover then
			local recover = data:toRecover()
			if recover.who and recover.who:objectName() == player:objectName() and player:hasSkill(self:objectName())
			and isSpecialOne(player, "神徐盛") and isSpecialOne(player, "神黄忠") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				recover.recover = recover.recover + 1
				data:setValue(recover)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and isSpecialOne(player, "七夕纪念") and (isSpecialOne(player, "神徐盛") or isSpecialOne(player, "神黄忠"))
	end,
}
f_shenxusheng:addSkill(f_haishiSM)
f_shenxusheng_skin:addSkill("f_haishiSM")
f_shenxusheng_forSHZ:addSkill("f_haishiSM")





--

--SD2 010 神黄忠
f_shenhuangzhongg = sgs.General(extension, "f_shenhuangzhongg", "god", 4, true)
f_shenhuangzhongg_skin = sgs.General(extension, "f_shenhuangzhongg_skin", "god", 4, true, true, true)
f_shenhuangzhongg_forSXS = sgs.General(extension, "f_shenhuangzhongg_forSXS", "god", 4, true, true, true)

f_kaigong = sgs.CreateTriggerSkill{
	name = "f_kaigong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card and use.card:isKindOf("Slash") then
				if player:getMark("f_kaigong_d1") > 0 and player:getMark("f_kaigong_d2") > 0
				and player:getMark("f_kaigong_d3") > 0 and player:getMark("f_kaigong_d4") > 0 then return false end
				for _, p in sgs.qlist(use.to) do
					local up_damage = 0
					if player:getMark("f_kaigong_d1") == 0 and p:getHandcardNum() >= player:getHp() then
						up_damage = up_damage + 1
					end
					if player:getMark("f_kaigong_d2") == 0 and p:getHandcardNum() <= player:getAttackRange() then
						up_damage = up_damage + 1
					end
					if player:getMark("f_kaigong_d3") == 0 and player:getHandcardNum() >= p:getHandcardNum() then
						up_damage = up_damage + 1
					end
					if player:getMark("f_kaigong_d4") == 0 and player:getHp() <= p:getHp() then
						up_damage = up_damage + 1
					end
					if up_damage == 0 then return false end
					room:setTag("f_kaigong", ToData(p))
					if room:askForSkillInvoke(player, self:objectName(), ToData("f_kaigongUpDamage:" .. up_damage)) then
						if not use.card:hasFlag(self:objectName()) then room:setCardFlag(use.card, self:objectName()) end
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(p, self:objectName(), up_damage)
					else if player:getState() ~= "online" then return false end
						local choices = {}
						for i = 0, up_damage do
							table.insert(choices, i)
						end
						local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
						local UD = tonumber(choice)
						if UD > 0 then
							if not use.card:hasFlag(self:objectName()) then room:setCardFlag(use.card, self:objectName()) end
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(p, self:objectName(), UD)
						end
					end
					room:removeTag("f_kaigong")
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.to and damage.to:getMark(self:objectName()) > 0
			and damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag(self:objectName()) then
				local n = damage.to:getMark(self:objectName())
				room:setPlayerMark(damage.to, self:objectName(), 0)
				local log = sgs.LogMessage()
				log.type = "$f_kaigongUD"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg2 = n
				room:sendLog(log)
			    damage.damage = damage.damage + n
				room:broadcastSkillInvoke(self:objectName())
				data:setValue(damage)
			end
		end
	end,
}
f_shenhuangzhongg:addSkill(f_kaigong)
f_shenhuangzhongg_skin:addSkill("f_kaigong")
f_shenhuangzhongg_forSXS:addSkill("f_kaigong")

f_gonghun = sgs.CreateTriggerSkill{
	name = "f_gonghun",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.MarkChanged, sgs.ConfirmDamage},
	waked_skills = "liegong,tenyearliegong,mobilemouliegong,sgkgodliegong",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setPlayerMark(player, "&f_gonghun", 1)
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&f_gonghun" and mark.gain > 0 and mark.who and mark.who:objectName() == player:objectName() then
				if player:getMark("&f_gonghun") == 1 then --一阶
					if not player:hasSkill("liegong") then
						room:acquireSkill(player, "liegong")
					end
				elseif player:getMark("&f_gonghun") == 2 then --升至二阶
					room:broadcastSkillInvoke(self:objectName(), 1)
					local log = sgs.LogMessage()
					log.type = "$f_gonghun_1to2"
					log.from = player
					room:sendLog(log)
					player:setSkillDescriptionSwap("f_gonghun","%arg1", player:getMark("&f_gonghun"))
					player:setSkillDescriptionSwap("f_gonghun","%arg2", "s")
                	room:changeTranslation(player, "f_gonghun",1)
					if not player:hasSkill("tenyearliegong") then
						room:acquireSkill(player, "tenyearliegong")
					end
				elseif player:getMark("&f_gonghun") == 3 then --升至三阶
					room:broadcastSkillInvoke(self:objectName(), 2)
					local log = sgs.LogMessage()
					log.type = "$f_gonghun_2to3"
					log.from = player
					room:sendLog(log)
					if not player:hasSkill("mobilemouliegong") then
						room:acquireSkill(player, "mobilemouliegong")
					end

					local records = player:getTag("MobileMouLiegongRecords"):toStringList()
					table.insert(records, "heart")
					table.insert(records, "diamond")
					table.insert(records, "club")
					table.insert(records, "spade")
					local mark = "&mobilemouliegong"
					for _, suit in ipairs(records) do
						mark = mark .. "+" .. suit .. "_char"
					end
					room:setPlayerMark(player, mark, 1)
					player:setTag("MobileMouLiegongRecords", sgs.QVariant(table.concat(records, "|")))
					player:setSkillDescriptionSwap("f_gonghun","%arg1", player:getMark("&f_gonghun"))
					player:setSkillDescriptionSwap("f_gonghun","%arg2", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg3", "s")
                	room:changeTranslation(player, "f_gonghun",1)
				elseif player:getMark("&f_gonghun") == 4 then --升至四阶
					room:broadcastSkillInvoke(self:objectName(), 3)
					local log = sgs.LogMessage()
					log.type = "$f_gonghun_3to4"
					log.from = player
					room:sendLog(log)
					player:setSkillDescriptionSwap("f_gonghun","%arg1", player:getMark("&f_gonghun"))
					player:setSkillDescriptionSwap("f_gonghun","%arg2", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg3", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg4", "s")
                	room:changeTranslation(player, "f_gonghun",1)
					if not player:hasSkill("sgkgodliegong") then
						room:acquireSkill(player, "sgkgodliegong")
					end
					room:loseHp(player, 1, true, player, self:objectName())
				elseif player:getMark("&f_gonghun") == 5 then --升至满阶
					room:broadcastSkillInvoke(self:objectName(), 4)
					local log = sgs.LogMessage()
					log.type = "$f_gonghun_4to5"
					log.from = player
					room:sendLog(log)
					player:setSkillDescriptionSwap("f_gonghun","%arg1", player:getMark("&f_gonghun"))
					player:setSkillDescriptionSwap("f_gonghun","%arg2", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg3", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg4", "s")
					player:setSkillDescriptionSwap("f_gonghun","%arg5", "s")
                	room:changeTranslation(player, "f_gonghun",1)
					local cds, mssb_gw = sgs.IntList(), math.random(0,99)
					for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
						local mssb = sgs.Sanguosha:getEngineCard(id)
						if mssb_gw < 23 or mssb_gw > 97 then
							if mssb:isKindOf("Fchixieren") and room:getCardPlace(id) ~= sgs.Player_DrawPile then
								cds:append(id)
								break
							end
						end
						if mssb_gw >= 23 then
							if mssb:isKindOf("Fmorigong") and room:getCardPlace(id) ~= sgs.Player_DrawPile then
								cds:append(id)
								break
							end
						end
					end
					if not cds:isEmpty() then
						room:shuffleIntoDrawPile(player, cds, self:objectName(), true)
						local ids = sgs.IntList()
						for _, id in sgs.qlist(room:getDrawPile()) do
							local cd = sgs.Sanguosha:getCard(id)
							if mssb_gw < 23 or mssb_gw > 97 then
								if cd:isKindOf("Fchixieren") then
									--room:setTag("CXR_ID", sgs.QVariant(id))
									ids:append(id)
								end
							end
							if mssb_gw >= 23 then
								if cd:isKindOf("Fmorigong") then
									--room:setTag("MRG_ID", sgs.QVariant(id))
									ids:append(id)
								end
							end
						end
						if not ids:isEmpty() then
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							for _, i in sgs.qlist(ids) do
								dummy:addSubcard(i)
								break
							end
							room:obtainCard(player, dummy)
							dummy:deleteLater()
						end
					end
				end
				if player:getMark("&f_gonghun") > 1 then
					if player:hasSkill("f_kaigong") then
						local choices = {}
						if player:getMark("f_kaigong_d1") == 0 then
							table.insert(choices, "1")
						end
						if player:getMark("f_kaigong_d2") == 0 then
							table.insert(choices, "2")
						end
						if player:getMark("f_kaigong_d3") == 0 then
							table.insert(choices, "3")
						end
						if player:getMark("f_kaigong_d4") == 0 then
							table.insert(choices, "4")
						end
						if #choices == 0 then return false end
						local choice = room:askForChoice(player, "f_gonghunDelete", table.concat(choices, "+"))
						local rmove = tonumber(choice)
						room:addPlayerMark(player, "f_kaigong_d" .. rmove)
						local names = player:property("SkillDescriptionRecord_f_kaigong"):toString():split("+")
                        table.insert(names,rmove)
                        room:setPlayerProperty(player, "SkillDescriptionRecord_f_kaigong", sgs.QVariant(table.concat(names, "+")))
						player:setSkillDescriptionSwap("f_kaigong","%arg1", "")
						player:setSkillDescriptionSwap("f_kaigong","%arg2", "")
						player:setSkillDescriptionSwap("f_kaigong","%arg3", "")
						player:setSkillDescriptionSwap("f_kaigong","%arg4", "")
						for i, v in ipairs(names) do
							player:setSkillDescriptionSwap("f_kaigong","%arg"..v, "s")
						end
                		room:changeTranslation(player, "f_kaigong",1)
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and player:getMark("&f_gonghun") > 1
			and damage.card and damage.card:isKindOf("Slash") then
				local n = player:getMark("&f_gonghun") - 1
				local log = sgs.LogMessage()
				log.type = "$f_gonghunMD"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg2 = n
				room:sendLog(log)
			    damage.damage = damage.damage + n
				data:setValue(damage)
			end
		end
	end,
}
f_gonghunMission = sgs.CreateTriggerSkill{
	name = "#f_gonghunMission",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:isKindOf("SkillCard") then
			--升二阶
			if card:isKindOf("Slash") and not card:isVirtualCard()
			and player:getMark("&f_gonghun") == 1 and player:getMark("f_gonghun_1to2") == 0 then
				room:addPlayerMark(player, "f_gonghun_1to2")
			--升三阶
			elseif card:isKindOf("Slash") and (card:isRed() or card:isBlack()) and player:getMark("&f_gonghun") == 2 then
				if card:isRed() and player:getMark("f_gonghun_2to3_red") == 0 then
					room:addPlayerMark(player, "f_gonghun_2to3_red")
				end
				if card:isBlack() and player:getMark("f_gonghun_2to3_black") == 0 then
					room:addPlayerMark(player, "f_gonghun_2to3_black")
				end
			--升四阶
			elseif card:isKindOf("Slash") and card:getSuit() ~= sgs.Card_NoSuit and player:getMark("&f_gonghun") == 3 then
				if player:getMark("f_gonghun_3to4_"..card:getSuitString()) == 0 then
					room:addPlayerMark(player, "f_gonghun_3to4_"..card:getSuitString())
				end
			--升满阶
			elseif card:isKindOf("Slash") and card:isVirtualCard() and (card:subcardsLength() == 0 or card:subcardsLength() >= 4)
			and player:getMark("&f_gonghun") == 4 and player:getMark("f_gonghun_4to5") == 0 then
				room:addPlayerMark(player, "f_gonghun_4to5")
			end
			--==升阶之路==--
			if not player:hasSkill("f_gonghun") then return false end
			if player:getMark("f_gonghun_1to2") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), ToData("toTwo")) then
					room:setPlayerMark(player, "f_gonghun_1to2", 0)
					if math.random() <= 0.9 then
						room:addPlayerMark(player, "&f_gonghun")
					else
						local log = sgs.LogMessage()
						log.type = "$f_gonghun_fail"
						log.from = player
						room:sendLog(log)
						sgs.Sanguosha:playSystemAudioEffect("lose")
					end
				end
			elseif player:getMark("f_gonghun_2to3_red") > 0 and player:getMark("f_gonghun_2to3_black") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), ToData("toThree")) then
					room:setPlayerMark(player, "f_gonghun_2to3_red", 0)
					room:setPlayerMark(player, "f_gonghun_2to3_black", 0)
					if math.random() <= 0.8 then
						room:addPlayerMark(player, "&f_gonghun")
					else
						local log = sgs.LogMessage()
						log.type = "$f_gonghun_fail"
						log.from = player
						room:sendLog(log)
						sgs.Sanguosha:playSystemAudioEffect("lose")
					end
				end
			elseif player:getMark("f_gonghun_3to4_heart") > 0 and player:getMark("f_gonghun_3to4_diamond") > 0
			and player:getMark("f_gonghun_3to4_club") > 0 and player:getMark("f_gonghun_3to4_spade") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), ToData("toFour")) then
					room:setPlayerMark(player, "f_gonghun_3to4_heart", 0)
					room:setPlayerMark(player, "f_gonghun_3to4_diamond", 0)
					room:setPlayerMark(player, "f_gonghun_3to4_club", 0)
					room:setPlayerMark(player, "f_gonghun_3to4_spade", 0)
					if math.random() <= 0.7 then
						room:addPlayerMark(player, "&f_gonghun")
					else
						local log = sgs.LogMessage()
						log.type = "$f_gonghun_fail"
						log.from = player
						room:sendLog(log)
						sgs.Sanguosha:playSystemAudioEffect("lose")
					end
				end
			elseif player:getMark("f_gonghun_4to5") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), ToData("toMaxFive")) then
					room:setPlayerMark(player, "f_gonghun_4to5", 0)
					if math.random() <= 0.6 then
						room:addPlayerMark(player, "&f_gonghun")
					else
						local log = sgs.LogMessage()
						log.type = "$f_gonghun_fail"
						log.from = player
						room:sendLog(log)
						sgs.Sanguosha:playSystemAudioEffect("lose")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenhuangzhongg:addSkill(f_gonghun)
f_shenhuangzhongg:addSkill(f_gonghunMission)
extension:insertRelatedSkills("f_gonghun","#f_gonghunMission")
f_shenhuangzhongg_skin:addSkill("f_gonghun")
f_shenhuangzhongg_skin:addSkill("#f_gonghunMission")
f_shenhuangzhongg_forSXS:addSkill("f_gonghun")
f_shenhuangzhongg_forSXS:addSkill("#f_gonghunMission")

f_shanmengHSCard = sgs.CreateSkillCard{
	name = "f_shanmengHSCard",
	target_fixed = true,--false,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    local choices = {}
		local yes = 0
		for _, p in sgs.qlist(room:getAllPlayers(true)) do --死亡角色加入表中
			if p:isDead() then
				table.insert(choices, p:getGeneralName())
				yes = 1
			end
		end
		if yes == 1 then
			table.insert(choices, "cancel")
			local choice = room:askForChoice(source, "f_shanmengHS-ask", table.concat(choices, "+")) --玩家选择一名死亡的角色
			if choice ~= "cancel" then
				for _, air in sgs.qlist(room:getAllPlayers(true)) do
					if air:isDead() and air:getGeneralName() == choice then --判断死亡的人的名字，跟选择的人是否符合，令其复活
						room:removePlayerMark(source, "@f_shanmengHS")
						room:doLightbox("$f_shanmengHS_toSXS")
						room:doAnimate(1, source:objectName(), air:objectName())
						room:revivePlayer(air) --复活吧，偶滴...对不起走错片场了
						if isSpecialOne(source, "神黄忠") then
							room:changeHero(air, "f_shenxusheng_forSHZ", true, true, false, true)
						elseif isSpecialOne(source, "神徐盛") then
							room:changeHero(air, "f_shenhuangzhongg_forSXS", true, true, false, true)
						end
						local dc = air:getMaxHp() - air:getHandcardNum()
						if dc > 0 then room:drawCards(air, dc, "f_shanmengHS")
						end
						local mhp = source:getMaxHp()
						local hp = source:getHp()
						--代价：
						if isSpecialOne(source, "神黄忠") then
							if source:getGeneralName() == "f_shenhuangzhongg" or source:getGeneralName() == "f_shenhuangzhongg_skin"
							or source:getGeneralName() == "f_shenhuangzhongg_forSXS" then
								room:changeHero(source, "sujiang", false, false, false, true)
							end
							if source:getGeneral2Name() == "f_shenhuangzhongg" or source:getGeneral2Name() == "f_shenhuangzhongg_skin"
							or source:getGeneral2Name() == "f_shenhuangzhongg_forSXS" then
								room:changeHero(source, "sujiang", false, false, true, true)
							end
						end
						if isSpecialOne(source, "神徐盛") then
							if source:getGeneralName() == "f_shenxusheng" or source:getGeneralName() == "f_shenxusheng_skin"
							or source:getGeneralName() == "f_shenxusheng_forSXS" then
								room:changeHero(source, "sujiangf", false, false, false, true)
							end
							if source:getGeneral2Name() == "f_shenxusheng" or source:getGeneral2Name() == "f_shenxusheng_skin"
							or source:getGeneral2Name() == "f_shenxusheng_forSXS" then
								room:changeHero(source, "sujiangf", false, false, true, true)
							end
						end
						if source:getMaxHp() ~= mhp then room:setPlayerProperty(source, "maxhp", sgs.QVariant(mhp)) end
						if source:getHp() ~= hp then room:setPlayerProperty(source, "hp", sgs.QVariant(hp)) end
						room:setPlayerMark(source, "&f_gonghun", 0)
					end
				end
			end
		end
	end,
}
f_shanmengHSVS = sgs.CreateViewAsSkill{
    name = "f_shanmengHS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Fchixieren") or to_select:isKindOf("Fmorigong")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = f_shanmengHSCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if isSpecialOne(player, "神黄忠") and isSpecialOne(player, "神徐盛") then return false end
		for _, lvr in sgs.qlist(player:getAliveSiblings()) do
			if (isSpecialOne(player, "神黄忠") and isSpecialOne(lvr, "神徐盛"))
			or (isSpecialOne(player, "神徐盛") and isSpecialOne(lvr, "神黄忠")) then return false end
		end
		return isSpecialOne(player, "七夕纪念") and player:getMark("@f_shanmengHS") > 0
	end,
}
f_shanmengHS = sgs.CreateTriggerSkill{
	name = "f_shanmengHS",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_shanmengHS",
	view_as_skill = f_shanmengHSVS,
	events = {sgs.BeforeCardsMove, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.BeforeCardsMove) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="BreakCard"
			and move.from:objectName()==player:objectName() then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceEquip
					and (sgs.Sanguosha:getCard(id):isKindOf("Fchixieren") or sgs.Sanguosha:getCard(id):isKindOf("Fmorigong")) then
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						room:breakCard(id,player)
                    end
                end
            end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName())
			and isSpecialOne(player, "神黄忠") and isSpecialOne(player, "神徐盛") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenhuangzhongg:addSkill(f_shanmengHS)
f_shenhuangzhongg_skin:addSkill("f_shanmengHS")
f_shenhuangzhongg_forSXS:addSkill("f_shanmengHS")


--==【灭世“神兵”】==--
--赤血刃
Fchixierens = sgs.CreateTriggerSkill{
	name = "Fchixieren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and player:isWounded() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local recover = damage.damage
				room:recover(player, sgs.RecoverStruct(player, nil, recover))
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getWeapon():isKindOf("Fchixieren")
	end,
}
Fchixieren = sgs.CreateWeapon{
	name = "_f_chixieren",
	class_name = "Fchixieren",
	range = 1,
	equip_skill = Fchixierens,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, Fchixierens, false, true, false)
		room:acquireSkill(player, "f_mieshiSB")
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "Fchixieren", true, true)
		room:detachSkillFromPlayer(player, "f_mieshiSB", false, true)
	end,
}
Fchixieren:clone(sgs.Card_Diamond, 1):setParent(extension_Cards)
--没日弓
Fmorigongs = sgs.CreateTriggerSkill{
	name = "Fmorigong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and damage.to then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:loseHp(damage.to, damage.damage, true, player, self:objectName())
				return true
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getWeapon():isKindOf("Fmorigong")
	end,
}
Fmorigong = sgs.CreateWeapon{
	name = "_f_morigong",
	class_name = "Fmorigong",
	range = 6,
	equip_skill = Fmorigongs,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, Fmorigongs, false, true, false)
		room:acquireSkill(player, "f_mieshiSB")
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "Fmorigong", true, true)
		room:detachSkillFromPlayer(player, "f_mieshiSB", false, true)
	end,
}
Fmorigong:clone(sgs.Card_Heart, 12):setParent(extension_Cards)
--<神兵灭世>--
f_mieshiSBCard = sgs.CreateSkillCard{
	name = "f_mieshiSBCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local mssb = sgs.Sanguosha:getCard(self:getSubcards():first())
		if mssb:isKindOf("Fchixieren") then
			return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select) == 1
		elseif mssb:isKindOf("Fmorigong") then
			return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
		end
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		local mssb = sgs.Sanguosha:getCard(self:getSubcards():first())
		if mssb:isKindOf("Fchixieren") then
			local hp = effect.from:getHp()
			room:loseHp(effect.from, hp, true, effect.from, "f_mieshiSB")
			local mhp = effect.to:getMaxHp()
			room:loseMaxHp(effect.to, mhp)
		elseif mssb:isKindOf("Fmorigong") then
			for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
				if p:getMark("Global_PreventPeach") == 0 and not p:hasFlag("Global_PreventPeach") then
					room:setPlayerFlag(p, "Fmorigong_cupTarget")
					room:setPlayerMark(p, "Global_PreventPeach", 1)
				end
			end
			local hp = effect.to:getHp()
			room:loseHp(effect.to, hp, true, effect.from, "f_mieshiSB")
			for _, q in sgs.qlist(room:getAllPlayers()) do
				if q:hasFlag("Fmorigong_cupTarget") then
					room:setPlayerFlag(q, "-Fmorigong_cupTarget")
					room:setPlayerMark(q, "Global_PreventPeach", 0)
				end
			end
		end
	end,
}
f_mieshiSB = sgs.CreateViewAsSkill{
    name = "f_mieshiSB&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Fchixieren") or to_select:isKindOf("Fmorigong")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = f_mieshiSBCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}
if not sgs.Sanguosha:getSkill("f_mieshiSB") then skills:append(f_mieshiSB) end




--

sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["fcDIY"] = "FC·DIY扩展包",
	["fcDIY_Cards"] = "FC·DIY卡牌",
	["fcDIY_twelveGod"] = "FC·DIY十二神将",
	["fcDIY_jxtp"] = "FC·DIY界限突破",
	["fcDIY_mg"] = "FC·DIY谋攻·幻想",
	--==V1.0(来自<自动包>)==--
	--神貂蝉-自改版
	["shendiaochan_change"] = "神貂蝉[FC]",
	["#shendiaochan_change"] = "欲界非天",
	["designer:shendiaochan_change"] = "面杀",
	["cv:shendiaochan_change"] = "英雄杀",
	["&shendiaochan_change"] = "神貂蝉",
	["f_meihun-invoke"] = "你可以发动“魅魂”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["f_meihun"] = "魅魂",
	[":f_meihun"] = "结束阶段开始时或当你成为【杀】的目标后，你可以令一名其他角色交给你一张你声明的花色的牌，若其没有或拒绝则你观看其手牌然后弃置其中一张，且你进行判定：若判定结果为红色，你令其获得1枚“魅惑”标记。",
	["@f_meihun-suit"] = "请交给其一张与其声明花色相同的牌",
	["$f_meihun1"] = "膜拜吧~", --结束阶段
	["$f_meihun2"] = "哼，不怕你！", --成为【杀】的目标
	["f_huoxin"] = "惑心", --由操控回合改为夺取回合。
	["f_huoxinGPC"] = "惑心",
	["f_huoxingpc"] = "惑心",
	["f_huoxinPindian"] = "惑心",
	["f_huoxinGetTurn"] = "惑心",
	["f_huoxinEndTurn"] = "惑心",
	[":f_huoxin"] = "出牌阶段限一次，你可以将两张花色相同的手牌展示并分别交给两名其他角色，然后令这两名角色拼点，没赢的角色获得1枚“魅惑”标记（你先选择交给牌的角色会成为发起拼点的对象；若拼点点数相等，则二者都算没赢）。\
	拥有2枚或更多“魅惑”标记的角色回合开始前，你可以将所有手牌扣置于武将牌上并获得其所有手牌，取消其回合，改为由你进行一个新回合，并移除其所有“魅惑”标记。此回合结束时，你将所有手牌返还给其，再获得通过此技能扣置于你武将牌上的所有牌。",
	["f_meihuo"] = "魅惑",
	["f_huoxinPindianCard"] = "惑心拼点",
	["@f_huoxinGPC-card1"] = "请选择其中一名角色，交给其一张牌",
	["@f_huoxinGPC-card2"] = "请选择另一名角色，交给其一张牌",
	["~f_huoxinGPC"] = "你先选择交给牌的角色会成为发起拼点的对象",
	["f_huoxin_GetTurn"] = "惑心额外回合",
	["f_huoxin_skip"] = "",
	["$f_huoxin"] = "嗯呵呵~~呵呵~~", --一名角色获得“魅惑”标记
	["f_huooxin"] = "", --惑心配音
	["$f_huooxin1"] = "谁，更勇猛呢？", --拼点
	["$f_huooxin2"] = "我，漂亮吗？", --夺取回合
	["~shendiaochan_change"] = "奉先，妾身随你而去......",
	
	--神张角
	["f_shenzhangjiao"] = "神张角[FC]",
	["&f_shenzhangjiao"] = "神张角",
	["#f_shenzhangjiao"] = "乱世之始",
	["designer:f_shenzhangjiao"] = "时光流逝FC",
	["cv:f_shenzhangjiao"] = "Benoitm,官方,网络",
	["illustrator:f_shenzhangjiao"] = "LiuHeng",
	["f_taiping"] = "太平",
	[":f_taiping"] = "准备阶段开始时，你可以选择一项：横置一名角色，或复原一名角色的武将牌。",
	["tpChain"] = "横置该角色",
	["tpRestore"] = "复原该角色的武将牌",
	["$f_taiping1"] = "太平天数，一统天下！", --横置
	["$f_taiping2"] = "黄天在上，福佑万民！", --复原
	["f_yaoshu"] = "妖术",
	[":f_yaoshu"] = "限定技，出牌阶段，你令至多三名其他角色翻面并失去1点体力。若如此做，出牌阶段结束时，你失去1点体力。",
	["@f_yaoshu"] = "妖术",
	["f_yaoshuAnimate"] = "image=image/animate/f_yaoshu.png",
	["$f_yaoshu"] = "鬼道大开，峰回路转！",
	["f_luolei"] = "落雷",
	[":f_luolei"] = "限定技，出牌阶段，你横置一名角色并对其造成2点雷电伤害，再对与其距离为1的所有角色各造成1点雷电伤害。若如此做，出牌阶段结束时，你减1点体力上限。",
	["@f_luolei"] = "落雷",
	["f_luoleiAnimate"] = "image=image/animate/f_luolei.png",
	["$f_luolei1"] = "（雷电声中）雷~公~助~我~！",
	["$f_luolei2"] = "（雷电声中）电闪雷鸣，改天换日！",
	["f_luoleiYD"] = "",
	["$f_luoleiYD"] = "（爆炸的电流声）",
	["SZJLimitSkillSideEffect"] = "",
	["~f_shenzhangjiao"] = "逆天而行，必遭天谴呐！...",
	
	--神张飞
	["f_shenzhangfei"] = "神张飞[FC]",
	["&f_shenzhangfei"] = "神张飞",
	["#f_shenzhangfei"] = "万人敌",
	["designer:f_shenzhangfei"] = "时光流逝FC",
	["cv:f_shenzhangfei"] = "官方,英雄杀",
	["illustrator:f_shenzhangfei"] = "鬼画府",
	["f_doushen"] = "斗神",
	["f_doushenBuff"] = "斗神",
	[":f_doushen"] = "限定技，出牌阶段，你令你于此回合使用牌无次数限制。",
	["@f_doushen"] = "斗神",
	["$f_doushen"] = "谁，还敢过来一战？！",
	["f_jiuwei"] = "酒威",
	["f_jiuwei_getBuff"] = "酒威",
	["f_jiuwei_DistanceBuff"] = "酒威",
	["f_jiuwei_DamageBuff"] = "酒威",
	["f_jiuwei_throwBuff"] = "酒威",
	["f_jiuwei_removeflag"] = "",
	[":f_jiuwei"] = "你可以将你的任意一张牌当作【酒】使用；锁定技，你的有【酒】加成的【杀】无距离限制且：命中，伤害+1；未命中，你弃置目标的一张牌。",
	["$f_jiuwei1"] = "燕人张飞在此！", --喝酒
	["$f_jiuwei2"] = "今，必斩汝（于）马下！", --酒杀命中
	["$f_jiuwei_Damage"] = "%from 酒杀命中，此【<font color='yellow'><b>杀</b></font>】伤害+1",
	["$f_jiuwei3"] = "谁来与我大战三百回合？！", --酒杀未命中
	["$f_jiuwei_Miss"] = "%from 酒杀未命中，弃置目标的一张牌",
	["~f_shenzhangfei"] = "饮酒误事啊！",
	
	--神马超
	["f_shenmachao"] = "神马超[FC]",
	["&f_shenmachao"] = "神马超",
	["#f_shenmachao"] = "神威天将军",
	["designer:f_shenmachao"] = "时光流逝FC",
	["cv:f_shenmachao"] = "官方",
	["illustrator:f_shenmachao"] = "Asker",
	["f_shenqi"] = "神骑",
	[":f_shenqi"] = "锁定技，你计算与其他角色的距离-2。",
	["f_shenlin"] = "神临",
	["f_shenlin_Clear"] = "神临",
	[":f_shenlin"] = "出牌阶段限一次，你可以弃置一张非基本牌并选择一名其他角色，则该角色的非锁定技和防具失效，直到回合结束。",
	["$f_shenlin"] = "目标敌阵，全军突击！",
	["f_shennu"] = "神怒",
	["f_shennu_youcantjink"] = "神怒",
	["f_shennu_slashmore"] = "神怒",
	["f_shennu_caozeijianzeiezeinizei"] = "神怒",
	["f_shennu_gexuqipao"] = "神怒",
	[":f_shennu"] = "出牌阶段限一次，你可以对自己造成1点伤害并摸一张牌，然后你获得以下效果直到回合结束：你的【杀】不可被【闪】响应且使用次数+1、你的红色【杀】伤害+1、你的【杀】的目标需弃置一张牌（只要有牌就必须执行），若无法做到则此【杀】伤害+1。",
	["@f_shennu_gexuqipao"] = "您必须弃置一张牌，若无牌可弃则此【杀】伤害+1",
	["$f_shennu"] = "敌人阵型已乱，随我杀！！",
	--["$f_shennu"] = "你可闪得过此一击！",
	["f_caohen"] = "曹恨",
	[":f_caohen"] = "<b>联动技，</b>锁定技，你对“曹操”或主公身份的魏势力角色造成伤害时，此伤害+1。",
	["$f_caohen"] = "灭族之恨，不共戴天！",
	["~f_shenmachao"] = "请将我，葬在西凉......",
	
	--神姜维
	["f_shenjiangwei"] = "神姜维[FC]",
	["&f_shenjiangwei"] = "神姜维",
	["#f_shenjiangwei"] = "麒麟儿",
	["designer:f_shenjiangwei"] = "时光流逝FC",
	["cv:f_shenjiangwei"] = "官方,Jr.Wakaran",
	["illustrator:f_shenjiangwei"] = "斗破苍穹",
	["f_beifa"] = "北伐！",
	["f_beifa_Clear"] = "北伐！",
	[":f_beifa"] = "出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，则你获得“手杀界挑衅”，且该角色的非锁定技失效，直到回合结束。",
	["$f_beifa1"] = "克复中原，指日可待！",
	["$f_beifa2"] = "贼将早降，可免一死。",
	["f_fuzhi"] = "复志",
	["f_fuzhi_Trigger"] = "复志",
	[":f_fuzhi"] = "锁定技，你每造成、受到1点伤害或发动一次“北伐！”，获得1枚“兴”标记；觉醒技，准备阶段开始时或结束阶段开始时，若你的“兴”标记不少于3枚，你减1点体力上限，获得技能“OL界志继”、“智勇”、“谋兴”。",
	["Xing"] = "兴",
	["@WAKEDD"] = "大觉醒",
	["$f_fuzhi"] = "...今虽穷极，然先帝之志，丞相之托，维..岂敢忘！",
	  ["olzhiji_sjwUse"] = "志继",
	  [":olzhiji_sjwUse"] = "觉醒技，准备阶段/结束阶段开始时，若你没有手牌，你回复1点体力或摸两张牌，然后你减1点体力上限并获得技能“界观星”。",
	  ["recover"] = "回复",
	  ["olzhiji_sjwUse:recover"] = "回复1点体力",
	  ["olzhiji_sjwUse:draw"] = "摸两张牌",
	  ["fz_zhiyong"] = "智勇",
	  [":fz_zhiyong"] = "觉醒技，准备阶段开始时，若你体力值未满，你减1点体力上限，回复1点体力并摸一张牌，获得技能“界看破”、“OL界龙胆”。",
	  ["$fz_zhiyong"] = "继丞相之智慧，负子龙之忠胆！",
	  ["fz_mouxing"] = "谋兴",
	  ["mouxingDying"] = "谋兴",
	  [":fz_mouxing"] = "觉醒技，准备阶段开始时，若你于本局进入过濒死状态或“兴”标记不少于12枚，你减1点体力上限并摸三张牌，获得技能“兴汉”、“汉魂”。",
	  ["$fz_mouxing"] = "臣欲使社稷危而复安，日月幽而复明！",
		["mx_xinghan"] = "兴汉",
		["mx_xinghan_SkillClear"] = "兴汉",
		[":mx_xinghan"] = "出牌阶段，你可以移去1枚“兴”标记，获得以下其一技能直到下回合开始（各技能不可重复存在）：“界仁德”、“空城”、“界武圣”、“OL界咆哮”、“OL涯角”、“界烈弓”、“铁骑”。",
		["xinghan_skillget"] = "",
		["addskill_rende"] = "界仁德",
		["addskill_kongcheng"] = "空城",
		["addskill_wusheng"] = "界武圣",
		["addskill_paoxiao"] = "OL界咆哮",
		["addskill_yajiao"] = "OL涯角",
		["addskill_liegong"] = "界烈弓",
		["addskill_tieqi"] = "铁骑",
		["$mx_xinghan"] = "继丞相之遗志，讨篡汉之逆贼！",
		["mx_hanhun"] = "汉魂", --以此纪念大汉的最后一位大将姜维。姜维死，汉室亡。
		[":mx_hanhun"] = "限定技，出牌阶段，你弃置不同类别的手牌各一张并失去1点体力，选择一名非主公身份的存活角色，则该角色于之后死亡时获得以下效果：立即复活并回复至满体力，摸四张牌，势力变更为“蜀”，获得技能“魂散”。若如此做，除非你选择的角色为你自己，否则你立即死亡。",
		["$mx_hanhun"] = "只有如此了！愿以吾之魂魄，复兴季汉！",
		["@mx_hanhun"] = "汉魂",
		["@ZhanDouXuXing"] = "",
	    ["f_hanhunRevive"] = "汉魂重生",
	    ["$f_hanhunRevive"] = "", --复活音效
		  ["f_hunsan"] = "魂散",
		  [":f_hunsan"] = "锁定技，结束阶段结束时，你失去1点体力。",
	["~f_shenjiangwei"] = "愧丞相，今生无法完成夙愿；愿来生，大汉一统，大好河山再现......", --暂无语音
	
	--神邓艾
	["f_shendengai"] = "神邓艾[FC]",
	["&f_shendengai"] = "神邓艾",
	["#f_shendengai"] = "破蜀奇功",
	["designer:f_shendengai"] = "时光流逝FC",
	["cv:f_shendengai"] = "官方,阿澈",
	["illustrator:f_shendengai"] = "小肚皮",
	["f_zhiqu"] = "直取",
	["f_zhiquu"] = "直取",
	[":f_zhiqu"] = "锁定技，一名有“毡衫”标记的角色于其回合内：使用黑色牌无距离限制；每使用一张红色牌，摸一张牌。",
	["$f_zhiqu1"] = "偷渡阴平，直取蜀汉！", --使用黑色牌
	["$f_zhiqu2"] = "屯田日久，当建奇功！", --使用红色牌
	["f_zhanshan"] = "毡衫",
	["f_zhanshan_GMS"] = "毡衫",
	["f_zhanshan_Trigger"] = "毡衫",
	["f_zhanshanbuff"] = "毡衫",
	[":f_zhanshan"] = "游戏开始时，你起始手牌数+2且获得等同于游戏人数的“毡衫”标记；准备阶段开始时，若你没有“毡衫”标记，你可以减1点体力上限并获得1枚“毡衫”标记；每当有一名其他角色阵亡后，你可以获得1枚“毡衫”标记。出牌阶段，你可以将你的1枚“毡衫”标记移交给一名其他角色；有“毡衫”标记的角色即将受到普通伤害时，其弃置1枚“毡衫”标记，防止此伤害（若你死亡或全场没有技能“毡衫”，“毡衫”标记依然生效）。",
	["mark_zhanshan"] = "毡衫",
	["$f_zhanshan1"] = "已至马革山，宜速进军破蜀！", --游戏开始
	["$f_zhanshan2"] = "奇兵正功，敌何能为？", --准备阶段开始时发动
	["$f_zhanshan3"] = "蹇利西南，不利东北；破蜀功高，难以北回！", --其他角色阵亡时发动
	["$f_zhanshan4"] = "攻其不备，出其不意！", --出牌阶段发动
	["$f_zhanshan5"] = "用兵以险，则战之以胜！", --免伤
	["~f_shendengai"] = "吾破蜀克敌，竟葬于奸贼之手！",
	
	--<汉中王>神刘备
	["hzw_shenliubei"] = "<汉中王>神刘备[FC]",
	["&hzw_shenliubei"] = "<汉中王>神刘备",
	["#hzw_shenliubei"] = "仁贯终生",
	["designer:hzw_shenliubei"] = "时光流逝FC",
	["cv:hzw_shenliubei"] = "官方,三国演义影视作品",
	["illustrator:hzw_shenliubei"] = "DH",
	["&hzw_shenliubei"] = "神刘备",
	["f_jieyi"] = "结义",
	[":f_jieyi"] = "限定技，出牌阶段，你选择两名其他角色，则本局你们三人结为“兄弟”，且你们获得技能“义志”（你于摸牌阶段多摸一张牌，并可于摸牌阶段结束时将至多两张牌分配给其他“兄弟”；你对其他“兄弟”使用【桃】时，此【桃】回复量+1）且全局生效。",
	["@f_jieyi"] = "结义",
	["XD"] = "兄弟",
	["f_jieyiAnimate"] = "image=image/animate/f_jieyi.png",
	["$f_jieyi1"] = "不求同年同月同日生，但愿同年同月同日死！", --新三国
	["$f_jieyi2"] = "我们兄弟三人，不求同年同月同日生，但愿同年同月同日死！", --三国演义动画片
	  ["jy_yizhi"] = "义志",
	  ["yizhiDraw"] = "义志",
	  ["yizhiLoyal"] = "义志",
	  ["yizhiloyal"] = "义志",
	  ["yizhiRescue"] = "义志",
	  [":jy_yizhi"] = "(此技能全局生效)你于摸牌阶段多摸一张牌，并可于摸牌阶段结束时将至多两张牌分配给其他“兄弟”；你对其他“兄弟”使用【桃】时，此【桃】回复量+1。",
	  ["@yizhiLoyal-card1"] = "你可以选择其中一个“兄弟”，给其一张牌(第一张)",
	  ["@yizhiLoyal-card2"] = "你可以选择其中一个“兄弟”，给其一张牌(第二张)",
	  ["~yizhiLoyal"] = "点击一名可被选择的角色，点【确定】",
	  ["$yizhiREC"] = "其他兄弟对 %from 使用了【<font color='yellow'><b>桃</b></font>】，此【<font color='yellow'><b>桃</b></font>】的回复量+1",
	  ["$jy_yizhi1"] = "桃园结义，营一世之交。",
	  ["$jy_yizhi2"] = "兄弟三人结义志，桃园英气久长存。",
	["f_renyi"] = "仁义",
	["f_renyiX"] = "仁义",
	["f_renyix"] = "仁义",
	["f_renyiBuff"] = "仁义",
	[":f_renyi"] = "出牌阶段限一次，你可以摸三张牌，然后将你的1~6张牌交给一名其他角色。若你选择的目标角色是“兄弟”，则其下一张伤害牌造成的伤害+1。然后若此时：你没有手牌，摸两张牌；你没有装备牌，回复1点体力。",
	["f_renyiBUFF"] = "",
	["@f_renyiX-card"] = "请选择一名其他角色并选择你要给的牌，若选择的是“兄弟”则有额外效果",
	["~f_renyiX"] = "选择1~6张牌，点击一名可被选择的角色，点【确定】",
	["$f_renyiBufff"] = "因为“<font color='yellow'><b>仁义</b></font>”的加成，%from 使用的此伤害牌造成的伤害 + %arg2",
	["$f_renyi1"] = "以德服人。",
	["$f_renyi2"] = "惟贤惟德，能服于人。", --(语音1,2)给牌
	["$f_renyi3"] = "同心同德，救困扶危！", --兄弟造成伤害
	["f_chengwang"] = "称王",
	["f_chengwang_DamageRecord"] = "称王",
	["f_chengwang_DR"] = "战功",
	[":f_chengwang"] = "主公技，觉醒技，回合内的任意阶段开始时，若你已发动“结义”并于之后与其他“兄弟”累计造成了至少12点伤害，你减1点体力上限并回复1点体力，势力重置为“蜀”，获得技能“汉中王”。",
	["$f_chengwang"] = "杀出重围，成王者霸业！",
	  ["f_hanzhongwang-invoke"] = "你可以发动“汉中王”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	  ["f_hanzhongwang"] = "汉中王",
	  ["f_hanzhongwang_BuffandClear"] = "汉中王",
	  [":f_hanzhongwang"] = "准备阶段开始时，你可以将一名其他角色的势力变更为“蜀”；出牌阶段开始时，你可以选择任意名其他“蜀”势力角色并获得他们区域里的一张牌，若如此做，则他们在其下回合造成的伤害+1。",
	  ["f_hanzhongwangBUFF"] = "兴复汉室",
	  ["@hzw_zhaomu"] = "[招募]您可以将一名其他角色的势力变更为“蜀”势力",
	  ["@hzw_haozhao"] = "[汉中王]号令群臣，兴复汉室！",
	  ["@f_hanzhongwang-card"] = "请选择任意名“蜀”势力的其他角色",
	  ["~f_hanzhongwang"] = "臣法正，参见汉中王！",
	  ["$f_hanzhongwang1"] = "物尽其用，方可人尽其才。", --改势力
	  ["$f_hanzhongwang2"] = "上报国家，下安黎庶！", --收保护费
	  ["$f_hanzhongwang3"] = "夺得首功者，封侯拜将！", --伤害+1
	["~hzw_shenliubei"] = "（新三国BGM：白帝城托孤）",
	
	--神黄忠
	["f_shenhuangzhong"] = "神黄忠[FC]",
	["&f_shenhuangzhong"] = "神黄忠",
	["#f_shenhuangzhong"] = "定军山斩夏侯",
	["designer:f_shenhuangzhong"] = "时光流逝FC",
	["cv:f_shenhuangzhong"] = "官方,新三国电视剧",
	["illustrator:f_shenhuangzhong"] = "福州光域",
	["f_shengong"] = "神弓",
	["f_shengongBuff_4SJ"] = "神弓",
	["f_shengongBuff_8SJ"] = "神弓",
	["f_shengongBuff_12SJ"] = "神弓",
	["f_shengongBuff_16SJ"] = "神弓",
	[":f_shengong"] = "锁定技，你的第一个回合开始时，摸十张牌，然后将你的十张手牌置于武将牌上，称为“神箭”。锁定技，若你的“神箭”数量：不少于4，你的【杀】无距离限制；不少于8，你的【杀】不可被【闪】响应；不少于12，你的【杀】伤害+1；不少于16，你每使用一张【杀】，摸一张牌并将你的一张手牌转化为“神箭”。",
	["ShenJian"] = "神箭",
	["f_shengongPush"] = "请选择将总计10张手牌置于武将牌上",
	["f_shengong_triggered"] = "",
	["f_shengong16SJPush"] = "请选择您的一张手牌置于武将牌上",
	["$f_shengong1"] = "哈哈哈哈哈哈哈哈哈哈......哈哈哈哈哈哈哈", --第一个回合获得“神箭”
	["$f_shengong2"] = "中！", --触发效果
	["f_dingjun"] = "定军", --修改前
	["f_dingjunTrigger"] = "定军",
	["f_dingjun_SkillClear"] = "定军",
	[":f_dingjun"] = "出牌阶段限一次(修改后:出牌阶段每个选项限一次)，你可以选择一项：1.获得四张(修改后:获得1~4张)“神箭”，然后获得“界烈弓”直到此阶段结束；2.将四张手牌(修改后:将1~4张手牌)转化为“神箭”，然后获得“乱射”直到此阶段结束。",
	["get4ShenJian"] = "获得四张“神箭”，获得“界烈弓”",
	["add4ShenJian"] = "装上四张“神箭”，获得“乱射”",
	["f_dingjunA4Push"] = "请选择您的四张手牌置于武将牌上",
	["getFShenJianSkill"] = "定军(获得“神箭”)",
	["getfshenjianskill"] = "定军(获得“神箭”)",
	["@getFShenJianSkill-card"] = "请选择四张“神箭”获得",
	["$f_dingjun"] = "弓不离手，自有转机！",
	  ["f_luanshe"] = "乱射",
	  ["f_luansheX"] = "乱射",
	  [":f_luanshe"] = "出牌阶段限一次，你可以将2X张“神箭”当【万箭齐发】使用（造成伤害时，有一定概率暴击）；你每以此法造成1点伤害，可以摸一张牌并将你的一张手牌转化为“神箭”。（暴击：伤害翻倍；X为你的当前体力值）",
	  ["f_luansheXPush"] = "请选择等同于伤害量的手牌置于武将牌上",
	  ["$f_luanshe"] = "箭阵开道，所向无敌！",
	["f_newdingjun"] = "定军", --修改后
	["f_newdingjunTrigger"] = "定军",
	[":f_newdingjun"] = "出牌阶段每个选项限一次，你可以选择一项：1.获得1~4张“神箭”，然后获得“界烈弓”直到此阶段结束；2.将1~4张手牌转化为“神箭”，然后获得“乱射”直到此阶段结束。",
	["get1to4ShenJian"] = "获得1~4张“神箭”，获得“界烈弓”",
	["add1to4ShenJian"] = "装上1~4张“神箭”，获得“乱射”",
	["f_dingjunA1to4Push"] = "请选择您的1~4张手牌置于武将牌上",
	["getOTFShenJianSkill"] = "定军(获得“神箭”)",
	["getotfshenjianskill"] = "定军(获得“神箭”)",
	["@getOTFShenJianSkill-card"] = "请选择1~4张“神箭”获得",
	["$f_newdingjun"] = "弓不离手，自有转机！",
	["f_huanghansheng"] = "汉升",
	[":f_huanghansheng"] = "<font color='yellow'><b>使命技，</b></font>你需要于第一次进入濒死状态之前杀死一名其他角色。若使命：成功，你摸四张牌并修改“定军”；失败，你废除装备栏并将体力值回复至1点。",
	["DJSZhanGong"] = "定军山战功",
	["$DJSZhanGong"] = "老将说黄忠，收川立大功。重披金锁甲，双挽铁胎弓！",
	["$hanshengSUC"] = "%from 使命成功，摸四张牌并修改“<font color='yellow'><b>定军</b></font>”",
	["$hanshengFAL"] = "%from 使命失败，废除装备栏并将体力值回复至1点",
	["hhh_triggered"] = "",
	["$f_huanghansheng1"] = "主公啊，哈哈哈哈哈哈！主公，定军山被攻下来了！", --使命成功
	["$f_huanghansheng2"] = "不得不服老了...", --使命失败
	["~f_shenhuangzhong"] = "你服不服啊！呃哈哈哈哈..呃啊",
	
	--神项羽
	["f_shenxiangyu"] = "神项羽[FC]",
	["&f_shenxiangyu"] = "神项羽",
	["#f_shenxiangyu"] = "千古无二",
	["designer:f_shenxiangyu"] = "时光流逝FC",
	["cv:f_shenxiangyu"] = "英雄杀,神赵云,张学友", --神项羽的阵亡语音节选自张学友/夏妙然的《霸王别姬》
	["illustrator:f_shenxiangyu"] = "英雄杀",
	["f_bawang"] = "霸王",
	["f_bawangCard_used"] = "霸王",
	["f_bawangMaxCards"] = "霸王",
	[":f_bawang"] = "出牌阶段限一次，你可以弃置一张基本牌并指定一名角色，对其造成1点伤害，然后你摸一张牌。若如此做，除非你于此阶段未使用过【杀】，否则本回合你的手牌上限-1。",
	["$f_bawang"] = "挡我者死！",
	["f_zhuifeng"] = "追风",
	["f_zhuifengX"] = "追风",
	["f_zhuifengAudio"] = "追风（配音）",
	[":f_zhuifeng"] = "锁定技，当你的装备区里没有武器牌时，你的攻击范围+X；当你的装备区里没有防具牌时，你的【杀】可额外指定X个目标。（X为1+你已损失的体力值）",
	["$f_zhuifeng"] = "杀啊~！",
	["f_wuzhui"] = "乌骓",
	["#f_wuzhuiMaxCards"] = "乌骓",
	[":f_wuzhui"] = "锁定技，当你的装备区里没有-1马时，你计算与其他角色的距离-1；当你的装备区里没有+1马时，你的手牌上限+1。",
	["f_pofuchenzhou"] = "决意 破釜沉舟",
	[":f_pofuchenzhou"] = "[破釜]准备阶段开始时，若你没有手牌，你摸两张牌。\
	[沉舟]结束阶段开始时，若你没有手牌，你可以对一名其他角色造成1点伤害。",
	["f_pofuchenzhou-invoke"] = "你可以发动“决意 破釜沉舟”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["$f_pofuchenzhou1"] = "背水一战，不胜便死！",
	["$f_pofuchenzhou2"] = "置于死地，方能后生！",
	["~f_shenxiangyu"] = "力拔山兮气盖世，时不利兮骓不逝。... 骓不逝兮可奈何，虞兮虞兮奈若何。",
	
	--神孙悟空
	["f_shensunwukong"] = "神孙悟空[FC]",
	["&f_shensunwukong"] = "神孙悟空",
	["#f_shensunwukong"] = "齐天大圣",
	["designer:f_shensunwukong"] = "时光流逝FC",
	["cv:f_shensunwukong"] = "86西游记电视剧,戴荃",
	["illustrator:f_shensunwukong"] = "网络",
	["f_bianhua"] = "变化",
	[":f_bianhua"] = "锁定技，你不于摸牌阶段内摸牌，改为在你回合内的每个阶段开始时，你摸一张牌。",
	["$f_bianhua1"] = "（西游记电视剧主题曲前奏）",
	["$f_bianhua2"] = "刚擒住了几个妖，又降住了几个魔，魑魅魍魉怎么它就这么多（嘿嘿，吃俺老孙一棒！）",
	["f_doufa"] = "斗法",
	[":f_doufa"] = "出牌阶段限一次，你弃置X张手牌，对一名角色造成2点任意属性（包括无属性）的伤害或令其失去2点体力(有25%的可能出现)（类型自选；X为你的当前体力值且至少为1）。",
	["f_doufaFire"] = "火焰伤害",
	["f_doufaThunder"] = "雷电伤害",
	["f_doufaIce"] = "冰冻伤害",
	["f_doufaPoison"] = "毒素伤害",
	["f_doufaNormal"] = "普通伤害",
	["f_doufalosehp"] = "失去体力",
	["$f_doufa1"] = "（齐天大圣，登场！）",
	["$f_doufa2"] = "踏碎凌霄，放肆桀骜；世恶道险，终究难逃~",
	["~f_shensunwukong"] = "五百年了.....", --暂无语音
	
	--霸霸
	["f_Trex"] = "[神]君王霸王龙[FC]",
	["&f_Trex"] = "[神]君王霸王龙",
	["#f_Trex"] = "恐龙之王",
	["designer:f_Trex"] = "时光流逝FC",
	["cv:f_Trex"] = "霸王龙吼声还原,亿载龙殿",
	["illustrator:f_Trex"] = "网络",
	["&f_Trex"] = "君王霸王龙",
	["f_diyuxi"] = "地狱溪",
	["f_diyuxiBUFF"] = "地狱溪",
	[":f_diyuxi"] = "出牌阶段每个选项限一次：1.失去1点体力并摸一张牌，则你本回合【杀】的伤害+1；2.减1点体力上限并摸两张牌，则你本回合造成的伤害+1。结束阶段开始时，若你于此回合的出牌阶段没作出选择或两项皆选，你失去1点体力。",
	["L1D1SD1"] = "失去1点体力并摸一张牌，本回合【杀】的伤害+1",
	["LM1D2D1"] = "减1点体力上限并摸两张牌，本回合造成的伤害+1",
	["$f_diyuxibuff1"] = "因为“<font color='yellow'><b>地狱溪</b></font>”的效果，%from 的【<font color='yellow'><b>杀</b></font>】对 %to 造成的伤害+1",
	["$f_diyuxibuff2"] = "因为“<font color='yellow'><b>地狱溪</b></font>”的效果，%from 对 %to 造成的伤害+1",
	["$f_diyuxi1"] = "（低沉的吼声）",
	["$f_diyuxi2"] = "（高昂的吼声）",
	["f_moshi"] = "末世",
	["f_moshiX"] = "末世",
	[":f_moshi"] = "主公技，觉醒技，准备阶段结束时，若你已于本局受到/失去过伤害/体力的次数之和至少为6，你失去技能“地狱溪”，摸两张牌，获得技能“狂龙”。",
	["f_moshiFQC"] = "末世次数",
	["$f_moshi"] = "地狱溪畔，末代辉煌，千古留名自霸王；\
金甲钢矛皆避让，地狱溪主称帝皇！", --“附歌词：金甲钢矛皆避让，恐龙帝皇~”
	  ["f_kuanglong"] = "狂龙",
	  ["f_kuanglongS"] = "狂龙",
	  ["f_kuanglongC"] = "狂龙",
	  [":f_kuanglong"] = "锁定技，你于摸牌阶段多摸X张牌，出牌阶段可使用【杀】的次数+X，手牌上限+X。（X为你已损失的体力值/2，向下取整）",
	  ["$f_kuanglong1"] = "（低沉的吼声）",
	  ["$f_kuanglong2"] = "（高昂的吼声）", --1,2皆同“地狱溪”的技能配音
	["~f_Trex"] = "飞越六世的跌宕，魂断百年的疯狂；一朝巧缘换兽王，再难思量......",
	
	--鲲鹏
	["f_kunpeng"] = "[神]鲲鹏[FC]",
	["&f_kunpeng"] = "[神]鲲鹏",
	["#f_kunpeng"] = "天地之间",
	["designer:f_kunpeng"] = "时光流逝FC",
	["cv:f_kunpeng"] = "网络",
	["illustrator:f_kunpeng"] = "网络",
	["&f_kunpeng"] = "鲲鹏",
	["KunPeng"] = "鲲鹏",
	["f_juxing"] = "巨形",
	["f_juxingMarkSkill"] = "巨形",
	["f_juxingClearMark"] = "巨形",
	[":f_juxing"] = "准备阶段开始时，你可以选择一名其他（没有“鲲鹏”标记的）角色，其获得1枚“鲲鹏”标记。锁定技，每当你或拥有“鲲鹏”标记的角色受到伤害时，你防止此伤害，改为你减少与伤害值等量的体力上限。",
	["KunPeng"] = "鲲鹏",
	["@f_juxing-card"] = "请选择一名没有“鲲鹏”标记的其他角色",
	["~f_juxing"] = "点击一名可被选择的角色，点【确定】",
	["f_juxing_trigger"] = "九天",
	["$f_juxing1"] = "", --给“鲲鹏”标记
	["$f_juxing2"] = "", --防止伤害
	["f_jiutian"] = "九天",
	["#f_jiutianContinue"] = "九天",
	[":f_jiutian"] = "<font color='green'><b>出牌阶段限X次，</b></font>你可以减1点体力上限，展示牌堆顶的一张牌：若为红色牌，你将其交给一名角色；若为黑色牌，你弃置之，令一名角色回复1点体力或摸一张牌。锁定技，结束阶段开始时，你减Y点体力上限。（X为你从上轮回合结束至本回合内触发“巨形”[锁定技部分]的次数；Y=X-本回合你发动“九天”[主动技部分]的次数）",
	["RecoverHim"] = "令其回复1点体力",
	["HeDrawCard"] = "令其摸一张牌",
	["$f_jiutian1"] = "", --出牌阶段发动技能减体力上限
	["$f_jiutian2"] = "", --翻开是红色牌并交给一名角色
	["$f_jiutian3"] = "", --翻开是黑色牌弃置并让一名角色回复体力或摸牌
	["~f_kunpeng"] = "（飞离声）",
	
	--FC神吕蒙
	["fc_shenlvmeng"] = "神吕蒙[FC]",
	["&fc_shenlvmeng"] = "神吕蒙",
	["#fc_shenlvmeng"] = "兼资文武",
	["designer:fc_shenlvmeng"] = "时光流逝FC",
	["cv:fc_shenlvmeng"] = "官方",
	["illustrator:fc_shenlvmeng"] = "小牛",
	["&fc_shenlvmeng"] = "☆神吕蒙",
	["fcshelie"] = "涉猎",
	[":fcshelie"] = "摸牌阶段开始时，你可以放弃摸牌，改为亮出牌堆顶的五张牌：若如此做，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆或交给一名其他角色。",
	["@fcshelieGC"] = "[涉猎]将剩余的牌交给一名其他角色",
	["$fcshelie1"] = "尘世之间，岂有吾所未闻之事。",
	["$fcshelie2"] = "往事皆知，未来尽料！",
	["fcgongxin"] = "攻心",
	[":fcgongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以展示其中一张牌并选择一项：弃置之（若此牌花色为红桃，改为获得之），或将之置于牌堆顶。",
	["fcgongxin:discard"] = "弃置(若此牌为♥则获得之)",
	["fcgongxin:put"] = "置于牌堆顶",
	["$fcgongxin1"] = "知敌所欲为，则此战，已尽在掌握。",
	["$fcgongxin2"] = "敌将虽有破军之勇，然未必有弑神之心。",
	["~fc_shenlvmeng"] = "吾能已通神，却难逆天命。",
	
	--FC神赵云
	["fc_shenzhaoyun"] = "神赵云[FC]",
	["&fc_shenzhaoyun"] = "神赵云",
	["#fc_shenzhaoyun"] = "天神下凡",
	["designer:fc_shenzhaoyun"] = "时光流逝FC",
	["cv:fc_shenzhaoyun"] = "极略三国,神赵云皮肤",
	["illustrator:fc_shenzhaoyun"] = "三国志幻想大陆",
	["&fc_shenzhaoyun"] = "☆神赵云",
	["fcweijing"] = "危境",
	["fcweijing_MaxCards"] = "危境",
	["fcweijing_MaxCards_Audio"] = "危境",
	["fcweijing_Draw"] = "危境",
	["fcweijing_Draw_Audio"] = "危境",
	[":fcweijing"] = "锁定技，你于摸牌阶段额外摸X张牌；你的手牌上限为你的体力上限+Y；当你进入/脱离濒死状态时，你摸X/Y张牌。（X为你已损失的体力值；Y为你的当前体力值）",
	["$fcweijing1"] = "龙战于野，其血玄黄!!", --摸牌阶段额外摸牌
	["$fcweijing2"] = "腾龙行云，首尾不见！", --弃牌阶段
	["$fcweijing3"] = "常山赵子龙在此！", --进入/脱离濒死状态
	["fclongming"] = "龙鸣",
	["fclongmingBuff"] = "龙鸣",
	[":fclongming"] = "你可以将至多两张花色相同的牌按以下规则使用或打出：红桃当【桃】；方块当【闪】；梅花当雷【杀】；黑桃当【酒】。若你以此法使用了两张牌且花色为：红桃，回复值+1；方块，获得当前回合角色的一张牌；梅花，伤害值+1；黑桃，效果量+1。",
	["$fclongmingPREC"] = "通过发动“<font color='yellow'><b>龙鸣</b></font>”使用两张红桃牌，此【<font color='yellow'><b>桃</b></font>】对 %from 的回复值+1",
	["$fclongmingJNK"] = "%from 发动“<font color='yellow'><b>龙鸣</b></font>”使用了两张方块牌，获得当前回合角色的一张牌",
	["$fclongmingDMG"] = "%from 发动“<font color='yellow'><b>龙鸣</b></font>”使用了两张梅花牌，此【<font color='yellow'><b>杀</b></font>】的伤害值+1",
	["$fclongmingANA"] = "%from 发动“<font color='yellow'><b>龙鸣</b></font>”使用了两张黑桃牌，此【<font color='yellow'><b>酒</b></font>】的伤害加成值+1",
	["$fclongmingAREC"] = "%from 发动“<font color='yellow'><b>龙鸣</b></font>”使用了两张黑桃牌，此【<font color='yellow'><b>酒</b></font>】的回复值+1",
	["fclongmingx"] = "配音-龙鸣", --“龙鸣”的专属配音技能
	["fclongming_Audio"] = "配音-龙鸣",
	[":fclongmingx"] = "[配音技]此技能为“龙鸣”的专属配音。",
	["$fclongming1"] = "潜龙于渊，涉灵愈伤。", -- ♥
	["$fclongming2"] = "潜龙勿用，藏锋守拙！", -- ♦
	["$fclongming3"] = "（雷电声）", -- ♣
	["$fclongming4"] = "金甲映日，驱邪祛秽！", -- ♠
	["$fclongming5"] = "龙战于野，其血玄黄！", -- 两张红色牌
	["$fclongming6"] = "来感受这，降世神龙的力量吧！", -- 两张黑色牌
	["$fclongming7"] = "千里一怒，红莲灿世！", --彩蛋：使用火【杀】
	["~fc_shenzhaoyun"] = "龙身虽死，魂魄不灭！",
	
	--FC神刘备
	["fc_shenliubei"] = "神刘备[FC]",
	["&fc_shenliubei"] = "神刘备",
	["#fc_shenliubei"] = "昭烈怒火",
	["designer:fc_shenliubei"] = "时光流逝FC",
	["cv:fc_shenliubei"] = "官方",
	["illustrator:fc_shenliubei"] = "佚名",
	["&fc_shenliubei"] = "☆神刘备",
	["$longnu3"] = "怒伤心肝，也阻止不了这复仇之火！",
	["$longnu4"] = "灼艾分痛失，虽万劫，亦杀之！",
	["fcjieying"] = "结营",
	["fcjieying_GMS"] = "结营",
	["fcjieying_MoreSlashUsed"] = "结营",
	["fcjieying_MaxCards"] = "结营",
	[":fcjieying"] = "锁定技，你始终处于横置状态；已横置的角色出牌阶段可额外使用一张【杀】、手牌上限-2；你的手牌上限+3。结束阶段开始时，你可以横置一名其他角色。",
	["fcjieying-invoke"] = "你发动了技能“结营”<br/> <b>操作提示</b>: 选择一名不处于连环状态的角色→点击确定<br/>",
	["$fcjieying1"] = "结连营之策，拒暴虐之贼。",
	["$fcjieying2"] = "兄弟三人结义志，桃园英气久长存。",
	["~fc_shenliubei"] = "鹡鸰在原，来生再聚......",
	
	--FC神张辽
	["fc_shenzhangliao"] = "神张辽[FC]",
	["&fc_shenzhangliao"] = "神张辽",
	["#fc_shenzhangliao"] = "威震逍遥津",
	["designer:fc_shenzhangliao"] = "时光流逝FC",
	["cv:fc_shenzhangliao"] = "官方",
	["illustrator:fc_shenzhangliao"] = "未知",
	["&fc_shenzhangliao"] = "☆神张辽",
	["fcduorui"] = "夺锐",
	[":fcduorui"] = "当你于出牌阶段对一名其他角色造成伤害后，你可以选择一项：1.获得其一张牌；2.清空其手牌区，然后你翻面，且于此阶段内你不能再发动“夺锐”；3.清空其装备区，然后（在所有结算完成后）结束你的出牌阶段。",
	["obtain1card"] = "获得其一张牌",
	["CleanUpHandArea"] = "清空其手牌区",
	["CleanUpEquipArea"] = "清空其装备区",
	["$fcduorui1"] = "夺敌军锐气，杀敌方士气！",
	["$fcduorui2"] = "尖锐之势，吾亦可一人夺之！",
	["fczhiti"] = "止啼",
	["fczhitiX"] = "止啼",
	["fczhiti_Audio"] = "止啼",
	[":fczhiti"] = "锁定技，你攻击范围内已受伤的角色手牌上限-1；准备阶段开始时，若场上已受伤的角色数：不少于1，本回合你的手牌上限+1、使用牌的距离+1；不少于3，摸牌阶段你的摸牌数+1、出牌阶段你可使用【杀】的次数+1；不少于5，结束阶段开始时你可以废除一名其他角色的装备区（直到其下回合结束）并对其造成1点伤害。",
	["fczhitiFlag"] = "止啼",
	["fcweijing_MaxCards"] = "止啼",
	["fczhiti_MoreDistance"] = "止啼",
	["fczhiti_DrawMoreCard"] = "止啼",
	["fczhiti_MoreSlashUsed"] = "止啼",
	["fczhiti_throwEquipArea_Damage"] = "止啼",
	["fczhiti_obtainEquipArea"] = "止啼",
	["$fczhiti1"] = "江东小儿，安敢啼哭？！",
	["$fczhiti2"] = "娃闻名止啼，孙损十万休！",
	["~fc_shenzhangliao"] = "我也有被孙仲谋所伤之时？！",
	
	--地主
	["f_landlord"] = "地主[FC]",
	["&f_landlord"] = "地主",
	["#f_landlord"] = "豆递主",
	["designer:f_landlord"] = "时光流逝FC",
	["cv:f_landlord"] = "祖茂",
	["illustrator:f_landlord"] = "欢乐斗地主",
	["f_feiyang"] = "飞扬",
	[":f_feiyang"] = "判定阶段开始时，若你的判定区有牌，你可以弃置两张手牌，弃置你判定区的其中一张牌。",
	["@f_feiyang"] = "你可以弃置两张手牌来弃置你判定区里的一张牌",
	["~f_feiyang"] = "选择两张手牌→点击确定",
	["f_bahu"] = "跋扈",
	["f_bahuSlashMore"] = "跋扈",
	[":f_bahu"] = "锁定技，准备阶段，你摸一张牌；你出牌阶段使用【杀】的次数上限+1。",
	["f_yinfu"] = "殷富",
	[":f_yinfu"] = "回合开始时，若你已损失的体力值不小于游戏轮次，你回复1点体力。此技能发动三次后，你失去此技能。",
	["f_yinfuTurn"] = "",
	["f_yinfuTriggered"] = "",
	["~f_landlord"] = "将军走此小道：（托管中... 逃跑）",
	
	--农民
	["f_farmer"] = "农民[FC]",
	["&f_farmer"] = "农民",
	["#f_farmer"] = "逗地主",
	["designer:f_farmer"] = "时光流逝FC",
	["cv:f_farmer"] = "邓艾,??",
	["illustrator:f_farmer"] = "欢乐斗地主",
	["f_gengzhong"] = "耕种",
	["f_gengzhongCard"] = "耕种",
	["f_gengzhongNTGet"] = "耕种",
	[":f_gengzhong"] = "出牌阶段限一次，你可以将一张牌置于武将牌上，称为“农田”，然后你可以视为使用一种(官方)基本牌(<font color='red'><b>注意！：满血选择【桃】，视为点【取消】</b></font>)；回合开始时或回合结束时，你可以获得你武将牌上的所有“农田”。",
	["NT"] = "农田",
	["@f_gengzhong"] = "你可以视为使用【杀】",
	["~f_gengzhong"] = "选择目标角色→点击确定",
	["@f_gengzhongNTGet"] = "[耕种]获得所有“农田”",
	["$f_gengzhong"] = "锄禾日当午，汗滴禾下土。",
	["f_gongkang"] = "共抗",
	[":f_gongkang"] = "限定技，出牌阶段，你选择一名其他角色，则其获得技能“耕种”且你们获得技能“同心”。",
	["@f_gongkang"] = "共抗",
	["f_tongxin"] = "同心",
	[":f_tongxin"] = "当一名有此技能的角色死亡后，场上其他有此技能的角色可选择一项：摸两张牌，或回复1点体力(彩蛋：如果伤害来源有此技能，会触发隐藏语音)。",
	["f_tongxin:1"] = "摸两张牌",
	["f_tongxin:2"] = "回复1点体力",
	["f_tongxinCDAudio"] = "同心-彩蛋",
	["$f_tongxinCDAudio"] = "无用之人，死！",
	["~f_farmer"] = "（砸蛋砸蛋砸蛋砸蛋砸蛋）哥，你不刷个桃的吗？",
	
	--J.SP赵云强化
	["chixinDrawANDGive"] = "赤心",
	["chixindrawandgive"] = "赤心",
	["@chixinDrawANDGive-card"] = "请将你的一张牌正面朝上交给一名角色",
	["~chixinDrawANDGive"] = "选择一张牌，点【确定】",
	["suirenChangeKingdom"] = "随仁",
	["sCKinvoked"] = "",
	["$chixin1"] = "匹马单枪出重围，英风锐气敌胆寒！",
	["$chixin2"] = "八面威风杀气飘，擎王保驾显功劳！",
	["$suiren"] = "纵死侠骨香，不愧知遇恩！",
	["~jsp_zhaoyun"] = "魂归在何处，仰天长问三两声......",
	
	--项羽专属装备：乌骓马（正好与防御马数量4:4对齐，强迫症福音）
	["xiangyuEquip"] = "项羽专属装备",
	["wuzhuii"] = "乌骓",
	--["Wuzhuii"] = "乌骓",
	[":wuzhuii"] = "[进攻马]锁定技，你与其他角色的距离-1。",
	
	--==V2.0(DIY十二神将)==--
	--武神·关羽
	["sp_shenguanyu"] = "武神·关羽[FC]",
	["&sp_shenguanyu"] = "武神关羽",
	["#sp_shenguanyu"] = "威震华夏",
	["designer:sp_shenguanyu"] = "时光流逝FC",
	["cv:sp_shenguanyu"] = "官方,三国志13",
	["illustrator:sp_shenguanyu"] = "Thinking",
	  --桃园义
	["sp_taoyuanyi"] = "桃园义", --刘关张三人桃园结义
	["sp_taoyuanyi_buffANDlimited"] = "桃园义",
	[":sp_taoyuanyi"] = "出牌阶段限一次，你可以将一张红桃手牌当【桃园结义】使用；你使用的【桃园结义】每让一名角色回复体力，你随机执行一项：1.摸一张牌；2.回复1点体力；3.加1点体力上限。",
	["$sp_taoyuanyi1"] = "策马挥刀，安天下，复汉室！",
	["$sp_taoyuanyi2"] = "忠心赤胆，青龙啸天！",
	  --[决意]过关斩将
	["sp_guoguanzhanjiang"] = "决意 过关斩将", --过五关，斩六将
	[":sp_guoguanzhanjiang"] = "[过关]回合开始时，若场上没有“关”标记，随机一名未获得过“关”标记的其他角色获得1枚“关”标记。然后你拥有技能“千里行”直到你对其造成伤害。然后你弃置其“关”标记，视为对其完成一次“过关”。\
	[斩将]你每杀死一名角色且该角色为你对其完成“过关”的角色，你视为完成一次“斩将”。\
	<font color='purple'><b>奖惩结算</b></font>：\
	<font color=\"#66FF66\"><b>奖励</b></font>：锁定技，回合结束时，若你于本回合完成“过关”，你摸X张牌（X为你累计完成“过关”的次数）；出牌阶段开始时，你摸Y张牌、回复Y-1点体力、加Y-2点体力上限（Y为你累计完成“斩将”的次数）；\
	<font color='red'><b>惩罚</b></font>：锁定技，回合结束时，若你未于本回合完成“过关”，你减1点体力上限。当你累计完成Z次“过关”后，此惩罚失效。（Z为此时场上其他角色的数量且至多为5）",
	["LeVeL"] = "关",
	["alreadyPASSlevel"] = "已过关",
	["PASSlevel"] = "过关",
	["KILLgeneral"] = "斩将",
	["$ggzz_guoguan"] = "%from 已成功完成对 %to 的 <font color='orange'><b>过关</b></font>！",
	["$ggzz_zhanjiang"] = "%from 成功完成一次 <font color='red'><b>斩将</b></font>！",
	["ggzz_punishlose"] = "",
	["$sp_guoguanzhanjiang1"] = "关某向来恩怨分明！", --过关
	["$sp_guoguanzhanjiang2"] = "又一个刀下亡魂！", --斩将
	    --千里行
	  ["sp_qianlixing"] = "千里行", --三国志12关羽战法
	  ["sp_qianlixingMD"] = "千里行",
	  ["sp_qianlixingPF"] = "千里行",
	  [":sp_qianlixing"] = "你可以将一张红色基本牌或装备牌当【杀】使用或打出：若此时是你的出牌阶段，你以此法使用的【杀】无距离限制且无视防具。",
	  ["$sp_qianlixing"] = "刀锋所向，战无不克！",
	    --（奖惩结算）
	  ["sp_guoguanzhanjiang_RAP"] = "过关斩将:奖惩结算",
	  [":sp_guoguanzhanjiang_RAP"] = "\
	  <font color='purple'><b>奖惩结算</b></font>：\
	  <font color=\"#66FF66\"><b>奖励</b></font>：锁定技，回合结束时，若你于本回合完成“过关”，你摸X张牌（X为你累计完成“过关”的次数）；出牌阶段开始时，你摸Y张牌、回复Y-1点体力、加Y-2点体力上限（Y为你累计完成“斩将”的次数）；\
	  <font color='red'><b>惩罚</b></font>：锁定技，回合结束时，若你未于本回合完成“过关”，你减1点体力上限。当你累计完成Z次“过关”后，此惩罚失效。（Z为此时场上其他角色的数量且至多为5）",
	  ["$sp_guoguanzhanjiang_RAP1"] = "过关斩将:过关奖励音效",
	  ["$sp_guoguanzhanjiang_RAP2"] = "过关斩将:斩将奖励音效",
	  --威震
	["sp_weizhen"] = "威震", --水淹七军，斩庞德，擒于禁，威震华夏！
	["sp_weizhen_limited"] = "威震",
	[":sp_weizhen"] = "出牌阶段，你可以将一张黑色基本牌或锦囊牌当【水淹七军】使用。若你于一个出牌阶段使用此技能的次数达到：2次，失去1点体力；3次及以上，每使用一次减1点体力上限。",
	["sp_weizhen_used"] = "",
	["$sp_weizhen1"] = "以义传魂，以武入圣！",
	["$sp_weizhen2"] = "义击逆流，武安黎庶！",
	  --显圣
	["sp_xiansheng"] = "显圣", --玉泉山关公显圣
	[":sp_xiansheng"] = "你死亡时，可以选择至多三名其他角色，若如此做，这些角色于你死亡后摸两张牌并回复1点体力。",
	["@sp_xiansheng-card"] = "桃园梦，忠义魂，玉泉山关公显圣",
	["~sp_xiansheng"] = "你可以选择至多三名其他角色",
	["$sp_xiansheng"] = "（赤面秉赤心，骑赤兔追风，驰不忘先帝。青灯观青史，仗青龙偃月，隐不愧青天！）",
	  --阵亡
	["~sp_shenguanyu"] = "桃园之梦，再也不会回来了...",
	
	--风神·吕蒙
	["sp_shenlvmeng"] = "风神·吕蒙[FC]",
	["&sp_shenlvmeng"] = "风神吕蒙",
	["#sp_shenlvmeng"] = "渡江夺荆",
	["designer:sp_shenlvmeng"] = "时光流逝FC",
	["cv:sp_shenlvmeng"] = "官方",
	["illustrator:sp_shenlvmeng"] = "biou09",
	  --刮目
	["sp_guamu"] = "刮目", --士别三日，当刮目相待
	[":sp_guamu"] = "出牌阶段限一次，你可以令一名角色选择一种牌的类别，然后你展示牌堆顶的三张牌：你将其中所有与选择类别相同的牌交给其或你，将其余的置入弃牌堆。然后根据此次获得的牌数：\
	至少一张，你摸一张牌并将你的一张牌弃置或置于牌堆顶；\
	至少两张，你回复1点体力；\
	至少三张，你获得技能“攻心”直到回合结束。",
	["sp_guamuBasic"] = "基本牌",
	["sp_guamuTrick"] = "锦囊牌",
	["sp_guamuEquip"] = "装备牌",
	["$sp_guamuBasic"] = "%from 选择了 <font color='yellow'><b>基本牌</b></font>",
	["$sp_guamuTrick"] = "%from 选择了 <font color='yellow'><b>锦囊牌</b></font>",
	["$sp_guamuEquip"] = "%from 选择了 <font color='yellow'><b>装备牌</b></font>",
	["sp_guamu:1"] = "交给其",
	["sp_guamu:2"] = "交给你",
	["sp_guamuONE"] = "刮目",
	["sp_guamuONEthrow"] = "弃置一张牌",
	["sp_guamuONEput"] = "将一张牌置于牌堆顶",
	["$sp_guamu1"] = "还有什么我不知道的。", --展示
	["$sp_guamu2"] = "书读五车，云开见日。", --至少一张
	["$sp_guamu3"] = "心里如何想的，我已知八九。", --至少两张
	["$sp_guamu4"] = "在我的眼中，你没有秘密。", --至少三张
	  --渡江
	["sp_dujiang"] = "渡江", --白衣渡江
	["sp_dujiangxijing"] = "渡江",
	["sp_dujiangFixedDistanceClear"] = "渡江",
	[":sp_dujiang"] = "出牌阶段限一次，你可以弃置一张装备牌并选择一名其他角色，则直到回合结束，你与其距离视为1且对其使用牌无次数限制。",
	["$sp_dujiang1"] = "快舟轻甲，速袭其后！",
	["$sp_dujiang2"] = "白衣摇橹，昼夜兼行！",
	  --阵亡
	["~sp_shenlvmeng"] = "而我，又何去何从。",
	
	--火神·周瑜
	["sp_shenzhouyu"] = "火神·周瑜[FC]",
	["&sp_shenzhouyu"] = "火神周瑜",
	["#sp_shenzhouyu"] = "人间英才",
	["designer:sp_shenzhouyu"] = "时光流逝FC",
	["cv:sp_shenzhouyu"] = "官方,血桜の涙",
	["illustrator:sp_shenzhouyu"] = "木美人",
	  --琴魔
	["sp_qinmo"] = "琴魔", --曲有误，周郎顾
	[":sp_qinmo"] = "出牌阶段开始时，你可以令一名角色失去或回复1点体力。若如此做，结束你的出牌阶段。",
	["sp_qinmoloseHp"] = "令一名角色失去1点体力",
	["sp_qinmoaddHp"] = "令一名角色回复1点体力",
	["$sp_qinmo"] = "（琴声）",
	  --火神
	["sp_huoshen"] = "火神", --三国志11周瑜特技
	[":sp_huoshen"] = "锁定技，你对一名在你攻击范围内的其他角色造成火焰伤害时，此伤害+1。",
	["$sp_huoshen"] = "让这熊熊业火，焚尽你的罪恶！",
	  --赤壁
	["sp_chibi"] = "赤壁", --赤壁之战
	["sp_chibiCount"] = "赤壁",
	[":sp_chibi"] = "限定技，出牌阶段，你对所有其他角色各造成1点火焰伤害。若你以此法造成有角色死亡，在所有伤害结算完成后你摸四张牌。",
	["@sp_chibi"] = "赤壁",
	["sp_chibiAnimate"] = "image=image/animate/sp_chibi.png",
	["$sp_chibi"] = "红莲业火，焚尽世间万物！",
	  --千古
	["sp_qiangu"] = "千古", --大江东去，浪淘尽，千古风流人物
	[":sp_qiangu"] = "觉醒技，准备阶段开始时，若你已发动过“赤壁”，你减1点体力上限，获得技能“神姿”。",
	["$sp_qiangu"] = "逝者不死，浴火重生......",
	    --神姿
	  ["sp_shenzi"] = "神姿", --对应“英姿”
	  [":sp_shenzi"] = "摸牌阶段，你可以选择一项：1.多摸一张牌；2.多摸两张牌，本回合手牌上限-1；3.少摸一张牌，本回合手牌上限+2；4.少摸两张牌，对一名其他角色造成1点火焰伤害。",
	  ["sp_shenzi3cards"] = "多摸一张牌",
	  ["sp_shenzi4cards"] = "多摸两张牌，本回合手牌上限-1",
	  ["sp_shenzi1card"] = "少摸一张牌，本回合手牌上限+2",
	  ["sp_shenzi0card"] = "少摸两张牌，对一名其他角色造成1点火焰伤害",
	  ["$sp_shenzi"] = "哈哈哈哈哈哈哈哈",
	  --阵亡
	["~sp_shenzhouyu"] = "天下已三分，我的使命..已结束了...",
	
	--天神·诸葛
	["sp_shenzhuge"] = "天神·诸葛[FC]",
	["&sp_shenzhuge"] = "天神诸葛",
	["#sp_shenzhuge"] = "天之骄子",
	["designer:sp_shenzhuge"] = "时光流逝FC",
	["cv:sp_shenzhuge"] = "官方,英雄杀,背后灵",
	["illustrator:sp_shenzhuge"] = "网络",
	  --智神
	["sp_zhishen"] = "智神",
	["sp_zhishenX"] = "智神",
	[":sp_zhishen"] = "你每使用一张非延时锦囊牌，可以获得X枚“神智”标记（若使用的是红色牌X为2，否则为1）；你每使用一张延时锦囊牌，可以摸三张牌；锁定技，你不能成为延时锦囊牌的目标。",
	["ShenZhi"] = "神智",
	["$sp_zhishen1"] = "淡泊以明志，宁静以致远。",
	["$sp_zhishen2"] = "志，当存高远；静，以修身。", --(语音1,2)使用非延时锦囊牌
	["$sp_zhishen3"] = "七星皆明，此战定胜。", --使用延时锦囊牌
	  --政神
	["sp_zhengshen"] = "政神",
	["sp_zhengshenGC"] = "政神",
	["sp_zhengshengc"] = "政神",
	[":sp_zhengshen"] = "摸牌阶段，你可以多摸两张牌，若如此做，出牌阶段开始时，你选择一项：依次将总计两张手牌交给一或两名其他角色，或弃置两张手牌。",
	["sp_zhengshen_used"] = "",
	["@sp_zhengshenGC"] = "[政神]你需要将两张手牌分配给其他角色，若点【取消】则弃置两张手牌",
	["@sp_zhengshenGC-card1"] = "请选择一名其他角色，给第一张牌",
	["@sp_zhengshenGC-card2"] = "请选择一名其他角色，给第二张牌",
	["~sp_zhengshenGC"] = "点击一名可被选择的角色，点击要交给其的牌，点【确定】",
	["$sp_zhengshen"] = "伏望天恩，兴汉破曹。",
	  --军神
	["sp_junshen"] = "军神",
	[":sp_junshen"] = "锁定技，你计算与其他角色的距离-Y。（Y为你装备区里的装备牌数）",
	  --祈天
	["sp_qitian"] = "祈天", --设七星坛祭风
	["sp_qitian_SkillClear"] = "祈天",
	[":sp_qitian"] = "判定阶段开始时，你可以弃置Z枚“神智”标记（1≤Z≤4）进行判定，根据判定的花色执行相应效果：\
	红桃，你摸Z张牌，弃两张牌，回复1点体力；\
	方块，你获得4枚“神智”标记，获得“界火计”直到回合结束；\
	梅花，你令一名角色获得1枚“狂风”标记，然后若Z=4，你对其造成1点火焰伤害（“狂风”标记：你受到的火焰伤害+1）；\
	黑桃，你对一名角色造成Z-1点雷电伤害，然后你弃置其Z-2张牌（至少一张），再自弃Z张牌。",
	["sp_qitian:1"] = "弃置1枚“神智”标记",
	["sp_qitian:2"] = "弃置2枚“神智”标记",
	["sp_qitian:3"] = "弃置3枚“神智”标记",
	["sp_qitian:4"] = "弃置4枚“神智”标记",
	["sp_qitianaddskill_data"] = "",
	["$sp_qitian1"] = "伏望天慈，延我之寿。", --判定结果：♥
	["$sp_qitian2"] = "知天易，逆天难。", --判定结果：♦
	["$sp_qitian3"] = "风......~起......！", --判定结果：♣
	["@sp_crazywind"] = "狂风",
	["sp_qitian_crazywind"] = "祈天-狂风",
	["$sp_qitian4"] = "（电闪，雷鸣！）", --判定结果：♠
	  --智绝
	["sp_zhijue"] = "智绝", --《三国演义》“三绝”其一
	[":sp_zhijue"] = "觉醒技，准备阶段开始时，若你满足以下三个条件其二（1.体力值为1；2.手牌数≤1；3.于本局进入过濒死状态），你减1点体力上限，获得1枚“大雾”标记（“大雾”标记：直到你的下回合开始前，防止你受到的非雷电伤害），获得技能“八阵”、“鬼门”。",
	["@sp_fog"] = "大雾",
	["sp_zhijue_fog"] = "智绝-大雾",
	["fog_Clear"] = "",
	["$sp_zhijue"] = "庶竭驽钝，攘除奸凶；兴复汉室，还于旧都！",
	    --鬼门
	  ["sp_guimen"] = "鬼门", --三国志11的一种特技
	  [":sp_guimen"] = "出牌阶段限一次，若你的“神智”标记有十位数，你可以弃置所有“神智”标记对所有其他角色各造成随机1~3点雷电伤害。",
	  ["$sp_guimen"] = "（恸天之雷霆！！！）",
	  ["$sp_guimenn"] = "鬼门大开，天地重启！！！",
	  --阵亡
	["~sp_shenzhuge"] = "今当远离..临表涕零...不知所言....",
	
	--君神·曹操
	["sp_shencaocao"] = "君神·曹操[FC]",
	["&sp_shencaocao"] = "君神曹操",
	["#sp_shencaocao"] = "一统北方",
	["designer:sp_shencaocao"] = "时光流逝FC",
	["cv:sp_shencaocao"] = "官方,军师联盟",
	["illustrator:sp_shencaocao"] = "网络",
	  --煮酒
	["sp_zhujiu"] = "煮酒", --煮酒论英雄
	["sp_zhujiuStartandEnd"] = "煮酒",
	["sp_zhujiuPindian"] = "煮酒",
	[":sp_zhujiu"] = "出牌阶段开始时，你可以<font color='red'><b>摸两张牌</b></font>并选择一名其他角色。则本回合的出牌阶段，你可以与其拼点：若你赢，你视为使用了【酒】（以此法使用的【酒】无次数限制）；若你没赢，你将武将牌翻面，若你以此法翻为：背面，你弃置一张手牌；正面，其弃置你一张牌且你不能再发动此技能直到回合结束。出牌阶段限一次，你可以获得你与目标以此法拼点的牌。",
	["CaL_zhujiuLYX"] = "选择一名其他角色，煮酒论英雄！",
	["qingmei_zhujiu"] = "青梅煮酒",
	["@sp_zhujiugetPindianCards"] = "[煮酒]获得双方拼点的牌",
	["sp_zhujiuFQC"] = "煮酒次数",
	["$sp_zhujiu1"] = "奸略逐鹿原，雄才扫狼烟！",
	["$sp_zhujiu2"] = "量小非君子，无奸不成雄！",
	  --歌行
	["sp_gexing"] = "歌行", --《短歌行》
	[":sp_gexing"] = "限定技，准备阶段结束时，若你于本局<font color='red'><b>通过“煮酒”的拼点次数与通过“煮酒”使用【酒】的次数之和</b></font>至少为10，你可以减1点体力上限，获得技能“天下”。", --10：袁术、袁绍、刘表、孙策、刘璋、张绣、张鲁、韩遂、刘备、曹操
	["@duangexing"] = "短歌行",
	["@sp_gexing-card"] = "已达成发动条件，你是否发动技能“歌行”？",
	["$duangexing"] = "青青子衿，悠悠我心；\
	但为君故，沉吟至今。",
	["$sp_gexing1"] = "明明如月，何时可掇~",
	["$sp_gexing2"] = "忧从中来，不可断绝~",
	  --天下
	  ["sp_tianxia"] = "天下", --曹操欲通过赤壁之战实现一统天下的抱负
	  [":sp_tianxia"] = "出牌阶段限一次，你可以选择一项：\
	  1.失去1点体力，令所有其他角色各选择一项：交给你一张牌(必须有牌)，或受到你造成的1点伤害。\
	  2.跳过下回合的出牌阶段，对所有其他角色依次执行一项：获得其区域里的一张牌，或对其造成1点伤害。\
	  3.减1点体力上限，依次执行前两项。",
	  ["sp_tianxia:1"] = "失去1点体力，令所有其他角色做出选择",
	  ["sp_tianxia:2"] = "跳过下回合的出牌阶段，对所有其他角色做出选择",
	  ["sp_tianxia:3"] = "减1点体力上限，依次执行前两项",
	  ["sp_tianxiaOther"] = "天下",
	  ["sp_tianxiaOther:1"] = "交给其一张牌",
	  ["sp_tianxiaOther:2"] = "受到其造成的1点伤害",
	  ["sp_tianxiaSelf"] = "天下",
	  ["sp_tianxiaSelf:1"] = "获得其区域里的一张牌",
	  ["sp_tianxiaSelf:2"] = "对其造成1点伤害",
	  ["SkipPlayerPlay"] = "跳过出牌阶段", --通用
	  ["$sp_tianxia1"] = "即便背负骂名，我也是为这天下！", --执行第一项
	  ["$sp_tianxia2"] = "天下人才，皆入我麾下！", --执行第二项
	  ["$sp_tianxia3"] = "挟天子以令诸侯，握敕令以致四方！", --两项皆执行
	  --阵亡
	["~sp_shencaocao"] = "平生诸憾，终不可追......",
	
	--战神·吕布
	["sp_shenlvbuu"] = "战神·吕布[FC]",
	["&sp_shenlvbuu"] = "战神吕布",
	["#sp_shenlvbuu"] = "独战六将",
	["designer:sp_shenlvbuu"] = "时光流逝FC",
	["cv:sp_shenlvbuu"] = "官方",
	["illustrator:sp_shenlvbuu"] = "魔奇士",
	  --武极
	["sp_wuji"] = "武极", --三国（演义）武力的顶点
	["sp_wujiChoice"] = "武极",
	[":sp_wuji"] = "出牌阶段开始时，你可以减1点体力上限并选择一项：摸两张牌，弃一张牌；或摸一张牌，弃两张牌。\
	◆若你选择前者，你获得技能“无双”、“飞将”，直到回合结束；\
	◆若你选择后者，你获得技能“无双”、“飞将”、“猛冠”、“独勇”，直到回合结束。觉醒技，若你本局累计至少三次选择此项，你获得技能“横扫千军”。",
	["sp_wuji:1"] = "摸两张牌，弃一张牌",
	["sp_wuji:2"] = "摸一张牌，弃两张牌",
	["sp_wujiAnger"] = "武极怒气",
	["$sp_wuji1"] = "谁能挡我？", --选前者
	["$sp_wuji2"] = "神挡杀神，佛挡杀佛！", --选后者
	["$sp_wuji3"] = "且断轮回化魔躯，不擒汝首誓不还！", --觉醒
	    --飞将
	  ["sp_feijiang"] = "飞将", --吕布的称号
	  [":sp_feijiang"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，视为你对其使用一张（无距离限制且不计次的）【杀】；若你没赢，你获得其区域里的一张牌，然后结束出牌阶段。",
	  ["$sp_feijiang1"] = "沉沦吧，在这无边的恐惧！",
	  ["$sp_feijiang2"] = "项上人头，待我来取！",
	    --猛冠
	  ["sp_mengguan"] = "猛冠", --吕布的头冠，修饰吕布的勇猛
	  [":sp_mengguan"] = "出牌阶段，你可以将一张武器牌当作【决斗】使用。",
	  ["$sp_mengguan1"] = "蚍蜉撼树，不自量力！",
	  ["$sp_mengguan2"] = "让你见识一下，什么才是天下无双！",
	    --独勇
	  ["sp_duyong"] = "独勇", --独战曹营六将
	  [":sp_duyong"] = "当你的【杀】或【决斗】即将造成伤害时，你可以弃置一张牌，令此伤害+1。",
	  ["$sp_duyong1"] = "汝等纵有万军，也难挡我吕布一人！",
	  ["$sp_duyong2"] = "戟间血未冷，再添马下魂！",
	    --横扫千军
	  ["sp_hengsaoqianjun"] = "横扫千军", --源自于英雄杀吕布的技能
	  ["sp_hengsaoqianjunBUFF"] = "横扫千军",
	  ["sp_hengsaoqianjunbuff"] = "横扫千军",
	  [":sp_hengsaoqianjun"] = "你可以将两张不同颜色的手牌当作【杀】使用或打出；你以此法使用【杀】时，你可以选择一项：\
	  1.伤害+1；\
	  2.额外选择至多两个目标；\
	  3.减1点体力上限，依次执行前两项。",
	  ["sp_hengsaoqianjun:1"] = "此【杀】伤害+1",
	  ["sp_hengsaoqianjun:2"] = "此【杀】额外选择目标",
	  ["sp_hengsaoqianjun:3"] = "减1点体力上限，依次执行前两项",
	  ["@sp_hengsaoqianjunBUFF"] = "你可以为【%src】选择至多两名额外目标",
	  ["$sp_hengsaoqianjunDMG"] = "%from 的 %card 对 %to 造成的伤害+1",
	  ["$sp_hengsaoqianjun1"] = "千钧之势，力贯苍穹！",
	  ["$sp_hengsaoqianjun2"] = "风扫六合，威震八荒！",
	  --袭徐
	["sp_xixu"] = "袭徐", --趁刘备与袁术交战时袭取徐州
	[":sp_xixu"] = "锁定技，当你对体力上限大于你的角色造成伤害后，你加1点体力上限。",
	["$sp_xixu1"] = "乱世天下，唯利当先！",
	["$sp_xixu2"] = "汝为江山，吾为名利！",
	  --阵亡
	["~sp_shenlvbuu"] = "我在修罗炼狱，等着你们！呵呵呵哈哈哈哈......",
	
	--枪神·赵云
	["sp_shenzhaoyun"] = "枪神·赵云[FC]",
	["&sp_shenzhaoyun"] = "枪神赵云",
	["#sp_shenzhaoyun"] = "单骑救主",
	["designer:sp_shenzhaoyun"] = "时光流逝FC",
	["cv:sp_shenzhaoyun"] = "官方,暴走大事件MC子龙",
	["illustrator:sp_shenzhaoyun"] = "秋呆呆",
	  --七进
	["sp_qijin"] = "七进", --[七进]七出
	["sp_qijinKey"] = "七进",
	[":sp_qijin"] = "每个回合限一次，你可以减1点体力上限，视为使用一种基本牌或普通锦囊牌。锁定技，回合开始时，若你的体力上限大于1，你减1点体力上限并摸一张牌；回合结束时，若你的体力上限大于1，你减1点体力上限并摸X张牌（X为你减过体力上限的次数<font color='blue'><b>且至多为4</b></font>）。",
	["sp_qijin_list"] = "七进",
	["sp_qijin_slash"] = "七进",
	["sp_qijin_saveself"] = "七进",
	["canuse_qijin"] = "可使用七进",
	["sp_qichuMHP_Start"] = "",
	["sp_qichuMHP"] = "",
	["sp_qichuMHP_reduse"] = "",
	["$sp_qijin1"] = "乐昌笃实，不屈不挠！",
	["$sp_qijin2"] = "以身报君，不求偷生！",
	  --七出
	["sp_qichu"] = "七出", --七进[七出]
	[":sp_qichu"] = "觉醒技，准备阶段开始时或结束阶段结束时，若你的体力上限为1，你失去技能“七进”，将体力上限重置至与游戏开始时相同并回复<font color='blue'><b>1</b></font>点体力，获得技能“单骑”、“孤胆”、“凌云”。",
	["sp_qichuAnimate"] = "image=image/animate/sp_qichu.png",
	["$sp_qichu"] = "单骑救主敌胆寒，常山赵云威名传！",
	    --单骑
	  ["sp_danqi"] = "单骑", --长坂坡单骑救主
	  ["sp_danqi_buffs"] = "单骑",
	  [":sp_danqi"] = "<font color='green'><b>每个回合限【1】次，</b></font>你可以将【1】张（同名）基本牌按以下规则使用或打出：\
	  杀->闪；闪->桃；桃->酒；酒->(普通)杀。\
	  若你以此法使用或打出了：\
	  <font color=\"#00FFFF\">[闪]弃置对方【Y】张牌</font>\
	  <font color='pink'>[桃]令目标摸【Y】张牌</font>\
	  <font color='black'>[酒]伤害加成值+【Y-1】</font>\
	  <font color='red'>[杀]无视防具且伤害值+【Y-1】</font>\
	  Y为你以此法使用或打出的牌数（注：可不选择执行）。",
	  ["canuse_danqi"] = "可使用单骑",
	  --["@sp_danqiJink"] = "单骑-闪",
	  --["@sp_danqiPeach"] = "单骑-桃",
	  --["@sp_danqiAnaleptic"] = "单骑-酒",
	  --["@sp_danqiSlash"] = "单骑-杀",
	  ["$sp_danqi_AnalepticADD"] = "%from 发动“<font color='yellow'><b>单骑</b></font>”将 %card 当作【<font color='yellow'><b>酒</b></font>】使用，此【<font color='yellow'><b>酒</b></font>】伤害加成值 + %arg2",
	  ["$sp_danqi_SlashADD"] = "%from 发动“<font color='yellow'><b>单骑</b></font>”将 %card 当作【<font color='yellow'><b>杀</b></font>】使用，此【<font color='yellow'><b>杀</b></font>】伤害值 + %arg2",
	  ["$sp_danqi_SlashDMG"] = "因为“<font color='yellow'><b>单骑</b></font>”的加成，%from 使用的 %card 对 %to 造成的伤害 + %arg2",
	  ["@sp_lingyunUTA"] = "凌云(增加“单骑”使用次数)",
	  ------------
	    --【闪】
	  ["sp_danqi_jink"] = "单骑-闪：弃置对方1张牌",
	  ["sp_danqi:jink1"] = "弃置对方1张牌",
	  ["sp_danqi:jink2"] = "弃置对方2张牌",
	  ["sp_danqi:jink3"] = "弃置对方3张牌",
	    --【桃】
	  ["sp_danqi:peach1"] = "令目标摸1张牌",
	  ["sp_danqi:peach2"] = "令目标摸2张牌",
	  ["sp_danqi:peach3"] = "令目标摸3张牌",
	    --【酒】
	  ["sp_danqi:analeptic1"] = "伤害加成值+1",
	  ["sp_danqi:analeptic2"] = "伤害加成值+2",
	    --【杀】
	  ["sp_danqi:slash1"] = "伤害值+1",
	  ["sp_danqi:slash2"] = "伤害值+2",
	  ------------
	  ["$sp_danqi1"] = "龙魂之力，百战皆克！",
	  ["$sp_danqi2"] = "龙游中原，魂魄不息！",
	    --孤胆
	  ["sp_gudan"] = "孤胆", --源自于神赵云皮肤“孤胆救主”
	  [":sp_gudan"] = "锁定技，每当你的体力值变化后，你摸【1】张牌并将【0】张牌交给一名其他角色。",
	  ["sp_gudan:1and0"] = "摸 1 张牌",
	  ["sp_gudan:1and1"] = "摸 1 张牌并将 1 张牌交给一名其他角色",
	  ["sp_gudan:2and0"] = "摸 2 张牌",
	  ["sp_gudan:2and1"] = "摸 2 张牌并将 1 张牌交给一名其他角色",
	  ["@sp_gudan-card"] = "请将你的一张牌交给一名其他角色",
	  ["~sp_gudan"] = "选择一张牌，选择要交给的角色，点【确定】",
	  ["$sp_gudan1"] = "横枪勒马，舍我其谁！",
	  ["$sp_gudan2"] = "枪挑四海，咫尺天涯！",
	    --凌云
	  ["sp_lingyun"] = "凌云", --壮志凌云
	  [":sp_lingyun"] = "在合适的时机下，你可以令“单骑”、“孤胆”描述中“【】”+1直到对应效果结算结束（不可叠加）。若如此做，你减1点体力上限。\
	  <font color='blue'>◆智能操作：出牌阶段，你可以按此按钮，切换为智能操作（不会出现不小心将体力上限扣减为0的失误）/纯人工操作。</font>", --我小高达模仿一下金玉大帝怎么了？:)
	  ["@sp_lingyunAI"] = "智能",
	  ["$sp_lingyun1"] = "破阵御敌，傲然屹立！",
	  ["$sp_lingyun2"] = "平战乱，享太平！",
	  --阵亡
	["~sp_shenzhaoyun"] = "来生，愿再遇主公。",
	
	--暗神·司马
	["sp_shensima"] = "暗神·司马[FC]",
	["&sp_shensima"] = "暗神司马",
	["#sp_shensima"] = "政变吞天",
	["designer:sp_shensima"] = "时光流逝FC",
	["cv:sp_shensima"] = "官方",
	["illustrator:sp_shensima"] = "墨三千",
	  --装病
	["sp_zhuangbing"] = "装病", --装病骗曹爽
	["sp_zhuangbingg"] = "装病",
	[":sp_zhuangbing"] = "隐匿技，当你于其他角色的回合登场后，你可以令当前回合角色不能使用或打出手牌直到其回合结束。锁定技，当你登场后，你翻面；若你的武将牌为背面，你不能使用或打出手牌，并防止一切伤害。",
	["sp_zhuangbingLose"] = "",
	["$sp_zhuangbing1"] = "老夫患病在身，恕不见客！",
	["$sp_zhuangbing2"] = "小不忍则乱大谋。",
	  --雄心
	["sp_xiongxin"] = "雄心", --源自于晋司马懿技能名“雄志”
	[":sp_xiongxin"] = "觉醒技，当你的武将牌翻为正面后，你加3点体力上限、回复3点体力并摸三张牌。然后你获得技能“隐忍”、“深谋”、“阴养”。",
	["$sp_xiongxin1"] = "养兵千日，用在一时。",
	["$sp_xiongxin2"] = "天赐良机，岂能逆天而行？",
	    --隐忍
	  ["sp_yinren"] = "隐忍", --隐忍装病等待翻盘曹爽的时机
	  [":sp_yinren"] = "回合开始时，你可以将你的所有手牌扣置于武将牌上并将你的武将牌翻面。",
	  ["$sp_yinren1"] = "忍一时，风平浪静~",
	  ["$sp_yinren2"] = "退一步，海阔天空~",
	    --深谋
	  ["sp_shenmou"] = "深谋", --深谋远虑
	  [":sp_shenmou"] = "出牌阶段限一次，你可以观看牌堆顶的三张牌，获得其中的一张锦囊牌，将其余牌以任意顺序置于牌堆顶。",
	  ["$sp_shenmou1"] = "天之道，轮回也~",
	  ["$sp_shenmou2"] = "顺应天意，得道多助~",
	    --阴养
	  ["sp_yinyang"] = "阴养", --司马懿与其子司马师阴养三千死士
	  ["sp_yinyangSSJQ"] = "阴养",
	  [":sp_yinyang"] = "回合结束时，你可以将一名其他角色的一张牌扣置于其武将牌上，称为“死士”。拥有“死士”的角色造成的伤害视为体力流失，且在其出牌阶段可以失去1点体力并获得所有“死士”牌。",
	  ["sp_ss"] = "死士",
	    ["sp_sishi"] = "死士",
		[":sp_sishi"] = "出牌阶段，你可以失去1点体力，获得所有扣置于你武将牌上的“死士”牌。",
	  ["$sp_yinyang1"] = "是福不是祸，是祸躲不过~",
	  ["$sp_yinyang2"] = "天时不如地利，地利不如人和~",
	  --政变
	["sp_zhengbian"] = "政变", --高平陵事变
	["sp_zhengbianBuff_distance"] = "政变",
	["sp_zhengbianBuff_slashmore"] = "政变",
	["sp_zhengbianClear"] = "政变",
	[":sp_zhengbian"] = "限定技，出牌阶段，你失去技能“装病”、“隐忍”、“深谋”、“阴养”，获得所有你因“隐忍”扣置于你武将牌上的牌，将以此法获得的牌数记录为X。然后你加X点体力上限，选择一名其他角色：直到回合结束，你与其距离-X，你可多对其使用X张【杀】。\
	然后于回合结束时，你获得技能“控局”并获得额外的一个回合。",
	["@sp_zhengbian"] = "政变",
	["sp_zhengbianToDo"] = "请选择一名其他角色作为你发动政变的对象",
	["sp_zhengbianTarget"] = "政变对象",
	["$sp_zhengbian1"] = "一鼓作气，破敌制胜！",
	["$sp_zhengbian2"] = "天要亡你，谁人能救？",
	    --控局
	  ["sp_kongju"] = "控局", --发动事变后掌控曹魏军政大权
	  [":sp_kongju"] = "出牌阶段，你可以减1点体力上限并选择执行一项，或直接随机执行一项：\
	  1、移动场上的一张牌；（若场上没有牌则控局失败，结束出牌阶段）\
	  2、将一名角色的一张手牌背面朝上移交给另一名角色；（若没有角色有手牌则控局失败，结束出牌阶段）\
	  3、废除自己的一个装备栏，令两名角色交换座位；（若你没有装备栏则控局失败，结束出牌阶段）\
	  4、控局失败，结束出牌阶段。",
	  ["lose1MaxHptochosetodo"] = "减1点体力上限并选择执行一项",
	  ["randomtodo"] = "随机执行一项",
	  ["sp_kongju:one"] = "移动场上的一张牌",
	  ["sp_kongju:two"] = "将一名角色的一张手牌背面朝上移交给另一名角色",
	--   ["sp_kongju:three"] = "废除一个装备栏，令两名角色交换座位",
	  ["sp_kongju:three"] = "废除一个装备栏，令一名角色棄置所有標記",
	  ["sp_kongju:fail"] = "控局失败，结束出牌阶段",
	  ["sp_kongjuOne"] = "请选择一名场上区域里有牌的角色",
	  ["@sp_kongjuOne-to"]  = "请选择移动的目标角色",
	  ["sp_kongjuTwoF"] = "请选择一名有手牌的角色",
	  ["sp_kongjuTwoT"] = "请选择移交手牌的目标角色",
	  ["sp_kongju:0"] = "废除武器栏",
	  ["sp_kongju:1"] = "废除防具栏",
	  ["sp_kongju:2"] = "废除+1马栏",
	  ["sp_kongju:3"] = "废除-1马栏",
	  ["sp_kongju:4"] = "废除宝物栏",
	  ["sp_kongjuThree"] = "请选择要棄置所有標記的一名角色",
	  ["sp_kongjuThreeOne"] = "请选择要交换座位的其中一名角色",
	  ["sp_kongjuThreeTwo"] = "请选择另一名角色",
	  ["$sp_kongjuFail"] = "%from 控局失败，结束出牌阶段",
	  ["$sp_kongju1"] = "老夫需再做权衡。",
	  ["$sp_kongju2"] = "用兵勿要弄险，细节决定成败！",
	  --吞天
	["sp_tuntian"] = "吞天", --司马家族的狼子野心
	[":sp_tuntian"] = "锁定技，你每杀死一名角色，加1点体力上限。",
	["sp_tuntian_kill"] = "",
	["$sp_tuntian1"] = "受命于天，既寿永昌！",
	["$sp_tuntian2"] = "老夫即是天命！",
	  --阵亡
	["~sp_shensima"] = "鼎足三分已成梦，一切，都结束了......",
	
	--剑神·刘备
	["sp_shenliubei"] = "剑神·刘备[FC]",
	["&sp_shenliubei"] = "剑神刘备",
	["#sp_shenliubei"] = "刘郎才气", --求田问舍，怕应羞见，刘郎才气
	["designer:sp_shenliubei"] = "时光流逝FC",
	["cv:sp_shenliubei"] = "官方",
	["illustrator:sp_shenliubei"] = "时空立方",
	  --英杰
	["sp_yingjie"] = "英杰", --忠胆英杰（bushi
	[":sp_yingjie"] = "转换技，①行侠：你每使用一张牌，可以令一名角色随机摸1~3张牌；②仗义：你每使用一张牌，可以交给一名其他角色一张牌，然后随机回复0~1点体力。",
	[":sp_yingjie1"] = "转换技，①行侠：你每使用一张牌，可以令一名角色随机摸1~3张牌；<font color=\"#01A5AF\"><s>②仗义：你每使用一张牌，可以交给一名其他角色一张牌，然后随机回复0~1点体力</s></font>。",
	[":sp_yingjie2"] = "转换技，<font color=\"#01A5AF\"><s>①行侠：你每使用一张牌，可以令一名角色随机摸1~3张牌</s></font>；②仗义：你每使用一张牌，可以交给一名其他角色一张牌，然后随机回复0~1点体力。",
	["@sp_yingjie-xingxia"] = "[英杰]行侠",
	["sp_yingjie-invoke"] = "选择一名角色，令其摸牌",
	["@sp_yingjie-zhangyi"] = "[英杰]仗义",
	["@sp_yingjie-card"] = "选择一名角色，交给其一张牌",
	["$sp_yingjie1"] = "备，愿结交天下豪杰！",
	["$sp_yingjie2"] = "得人心者，得天下！",
	  --远志
	["sp_yuanzhi"] = "远志", --远大的志向
	["sp_yuanzhiExtra"] = "远志",
	[":sp_yuanzhi"] = "<font color='green'><b>出牌阶段限X次，</b></font>（X>=0且X初始值为1）你可以与一名其他角色拼点。若你赢，你摸一张牌并令X+1；若你没赢，你选择一项：弃置Y张牌并令X-1(Y为你<font color='blue'><b>本局累计</b></font>以此法拼点没赢的次数)，或将X归0直到下回合的出牌阶段结束，将X重置为1。",
	["sp_yuanzhiFQC"] = "远志次数",
	["sp_yuanzhiUF"] = "",
	["sp_yuanzhi:1"] = "弃置牌并令“远志”的出牌阶段可使用次数-1（提示：注意不要让可使用次数永久为0）",
	["sp_yuanzhi:2"] = "将“远志”的出牌阶段可使用次数归0（于下回合的出牌阶段结束再将次数重置为1）",
	["sp_yuanzhiFail"] = "",
	["sp_yuanzhiTR"] = "",
	["$sp_yuanzhi1"] = "举大事者，必以民为本！",
	["$sp_yuanzhi2"] = "建功立业，正在此时！",
	  --戎马
	["sp_rongma"] = "戎马", --刘备戎马一生，终于白帝城
	[":sp_rongma"] = "锁定技，你每造成/受到一次伤害或摸一次牌时，获得1枚“戎马”标记。当你的“戎马”标记累计达到：10枚，你令“远志”中的X+2；20枚，你摸三张牌；30枚，你加1点体力上限并回复1点体力；40枚，你死亡。",
	["sp_rongmaTrigger"] = "",
	--[[（暂无语音）
	["$sp_rongma1"] = "", --10枚
	["$sp_rongma2"] = "", --20枚
	["$sp_rongma3"] = "", --30枚
	]]
	  --阵亡
	["~sp_shenliubei"] = "夷陵之火，焚尽了我一生心力......",
	
	--军神·陆逊
	["sp_shenluxun"] = "军神·陆逊[FC]",
	["&sp_shenluxun"] = "军神陆逊",
	["#sp_shenluxun"] = "火烧连营",
	["designer:sp_shenluxun"] = "时光流逝FC",
	["cv:sp_shenluxun"] = "官方",
	["illustrator:sp_shenluxun"] = "木美人",
	  --燥炎
	["sp_zaoyan"] = "燥炎", --陆逊沉住气并以逸待劳，抓住酷暑季节蜀军斗志涣散松懈的时机（技能内容灵感源自于极略三国神陆逊的技能“劫焰”）
	["sp_zaoyanTime"] = "燥炎",
	[":sp_zaoyan"] = "转换技，<font color='green'><b>剩余可用X次，</b></font>①当一名角色成为红色【杀】或红色普通锦囊牌的唯一目标时，你可以摸一张牌并弃置一张红色牌。若如此做，取消之，改为该角色受到此牌使用者的1点火焰伤害；②当一名角色成为黑色【杀】或黑色普通锦囊牌的唯一目标时，你可以弃置一张黑色牌并摸一张牌。若如此做，取消之，改为该角色失去1点体力。（X初始为1且至多为4；每名角色的回合结束后，X加1）",
	[":sp_zaoyan1"] = "转换技，<font color='green'><b>剩余可用X次，</b></font>①当一名角色成为红色【杀】或红色普通锦囊牌的唯一目标时，你可以摸一张牌并弃置一张红色牌。若如此做，取消之，改为该角色受到此牌使用者的1点火焰伤害；<font color=\"#01A5AF\"><s>②当一名角色成为黑色【杀】或黑色普通锦囊牌的唯一目标时，你可以弃置一张黑色牌并摸一张牌。若如此做，取消之，改为该角色失去1点体力</s></font>。（X初始为1且至多为4；每名角色的回合结束后，X加1）",
	[":sp_zaoyan2"] = "转换技，<font color='green'><b>剩余可用X次，</b></font><font color=\"#01A5AF\"><s>①当一名角色成为红色【杀】或红色普通锦囊牌的唯一目标时，你可以摸一张牌并弃置一张红色牌。若如此做，取消之，改为该角色受到此牌使用者的1点火焰伤害</s></font>；②当一名角色成为黑色【杀】或黑色普通锦囊牌的唯一目标时，你可以弃置一张黑色牌并摸一张牌。若如此做，取消之，改为该角色失去1点体力。（X初始为1且至多为4；每名角色的回合结束后，X加1）",
	["sp_zaoyanLast"] = "燥炎剩余",
	["@sp_zaoyan-yang"] = "燥炎[阳]",
	["@sp_zaoyan-red"] = "请弃置一张红色牌",
	["@sp_zaoyan-yin"] = "燥炎[阴]",
	["@sp_zaoyan-black"] = "请弃置一张黑色牌",
	["$sp_zaoyan1"] = "摧敌军阵，克敌锋锐。", --阳
	["$sp_zaoyan2"] = "动敌阵，乱敌心，此战已胜。", --阴
	["$sp_zaoyan3"] = "三军用备，吾有何忧？", --增加次数
	  --焚营
	["sp_fenying"] = "焚营", --火烧连营七百里（技能名同极略三国神陆逊）
	[":sp_fenying"] = "限定技，当一名角色即将受到火焰伤害时，你可以弃置任意张手牌令等量的角色横置（若其已横置，则重置之），然后弃置Y张装备区里的牌令该伤害翻倍。若如此做，你移除所有“燥炎”剩余可使用次数并摸等同于以此法移除的“燥炎”剩余可使用次数的牌。（Y为该角色即将受到的伤害值）",
	["@sp_fenying"] = "焚营",
	["@sp_fenying-card"] = "你可以发动技能“焚营”",
	["~sp_fenying"] = "选择任意张手牌并选择等量的角色，点【确定】",
	["$sp_fenyingDMG"] = "%from 发动了“<font color='yellow'><b>焚营</b></font>”，%to 受到的火焰伤害由 %arg 点翻倍为 %arg2 点",
	["$sp_fenying1"] = "业火绽放，敌营尽焚！",
	["$sp_fenying2"] = "这红莲，为大吴的胜利而绽放！",
	  --阵亡
	["~sp_shenluxun"] = "虽大败蜀军，却未能破孔明之策吗......",
	
	--孤神·张辽
	["sp_shenzhangliao"] = "孤神·张辽[FC]",
	["&sp_shenzhangliao"] = "孤神张辽",
	["#sp_shenzhangliao"] = "白狼声,逍遥名",
	["designer:sp_shenzhangliao"] = "时光流逝FC",
	["cv:sp_shenzhangliao"] = "官方",
	["illustrator:sp_shenzhangliao"] = "云涯",
	  --强袭
	["sp_qiangxi"] = "强袭", --三国志12张辽战法
	["sp_qiangxiAct"] = "强袭",
	[":sp_qiangxi"] = "摸牌阶段，你可以少摸任意张牌，获得等量的其他角色的各一张<font color='red'><b>牌</b></font>并各造成1点伤害。",
	["@sp_qiangxi-card"] = "你可以发动“强袭”，选择至多 %arg 名其他角色",
	["~sp_qiangxi"] = "选择合法数量内的其他角色→点击【确定】",
	["$sp_qiangxi1"] = "八百虎贲踏江去，十万吴兵丧胆还！",
	["$sp_qiangxi2"] = "虎啸逍遥震千里，江东碧眼犹梦惊！",
	  --辽来
	["sp_liaolai"] = "辽来", --（在东吴）用来吓小孩不哭的用语
	[":sp_liaolai"] = "锁定技，当你对“吴”势力角色造成伤害时，若：1.你的体力值小于其；2.你的手牌数小于其，每满足一项，此伤害就+1。",
	["$sp_liaolai1"] = "敌无心恋战，亦无力嚎哭乎？",
	["$sp_liaolai2"] = "定教吴儿，闻名止啼！",
	  --阵亡
	["~sp_shenzhangliao"] = "不擒碧眼儿，岂能罢休！......",
	
	--奇神·甘宁
	["sp_shenganning"] = "奇神·甘宁[FC]",
	["&sp_shenganning"] = "奇神甘宁",
	["#sp_shenganning"] = "蚀灵的神鸦",
	["designer:sp_shenganning"] = "时光流逝FC",
	["cv:sp_shenganning"] = "官方",
	["illustrator:sp_shenganning"] = "未知",
	  --掠阵
	["sp_lvezhen"] = "掠阵", --同极略三国神甘宁的技能名
	["sp_lvezhenFQC_Clear"] = "掠阵",
	["sp_lvezhen_SSQY"] = "掠阵",
	["sp_lvezhen_GHCQ"] = "掠阵",
	["sp_lvezhen_SSQY_moredistance"] = "掠阵",
	["sp_lvezhen_SkillCardBuff"] = "掠阵",
	[":sp_lvezhen"] = "转换技，<font color='green'><b>出牌阶段限两次，</b></font>①你可以废除一个装备栏，将一张红色牌当作使用距离+1的【顺手牵羊】使用，然后于结算结束后获得目标的一张手牌；②你可以废除一个装备栏，将一张黑色牌当作可选择目标+1的【过河拆桥】使用，然后于结算结束后弃置目标区域里的一张牌。",
	[":sp_lvezhen1"] = "转换技，<font color='green'><b>出牌阶段限两次，</b></font>①你可以废除一个装备栏，将一张红色牌当作使用距离+1的【顺手牵羊】使用，然后于结算结束后获得目标的一张手牌；<font color=\"#01A5AF\"><s>②你可以废除一个装备栏，将一张黑色牌当作可选择目标+1的【过河拆桥】使用，然后于结算结束后弃置目标区域里的一张牌</s></font>。",
	[":sp_lvezhen2"] = "转换技，<font color='green'><b>出牌阶段限两次，</b></font><font color=\"#01A5AF\"><s>①你可以废除一个装备栏，将一张红色牌当作使用距离+1的【顺手牵羊】使用，然后于结算结束后获得目标的一张手牌</s></font>；②你可以废除一个装备栏，将一张黑色牌当作可选择目标+1的【过河拆桥】使用，然后于结算结束后弃置目标区域里的一张牌。",
	["sp_lvezhen:0"] = "废除武器栏",
	["sp_lvezhen:1"] = "废除防具栏",
	["sp_lvezhen:2"] = "废除+1马栏",
	["sp_lvezhen:3"] = "废除-1马栏",
	["sp_lvezhen:4"] = "废除宝物栏",
	["sp_lvezhenFQC"] = "",
	["@sp_lvezhen_SSQY-yang"] = "请将你的一张红色牌当作【顺手牵羊】使用（可使用距离+1）",
	["@sp_lvezhen_GHCQ-yin"] = "请将你的一张黑色牌当作【过河拆桥】使用（可选择目标+1）",
	["@sp_lvezhen_SkillCardBuff"] = "你可以为【%src】选择一名额外目标",
	["$sp_lvezhen1"] = "战胜群敌，展江东豪杰之魄！",
	["$sp_lvezhen2"] = "此次进击，定要丧敌胆魄！",
	  --袭营
	["sp_xiying"] = "袭营", --百骑劫曹营
	["sp_xiyingSettle"] = "袭营",
	[":sp_xiying"] = "限定技，出牌阶段，你弃置所有手牌，获得一名其他角色的所有手牌，然后你与其距离视为1直到回合结束。回合结束时，其获得你所有手牌，然后你摸X张牌（X为你从发动此技能至回合结束对其造成的伤害值）。",
	["@sp_xiying"] = "袭营",
	["sp_xiyingTarget"] = "被袭营",
	["sp_xiyingDMG"] = "袭营伤害",
	["$sp_xiying1"] = "劫敌营寨，以破其胆！",
	["$sp_xiying2"] = "百骑劫魏营，功震天下英！",
	  --神鸦
	["sp_shenya"] = "神鸦", --神鸦能显圣，香火永千秋
	[":sp_shenya"] = "锁定技，回合结束时，若你于本回合造成了伤害，你恢复一个装备栏；杀死你的角色不执行奖惩。",
	["sp_shenya:0"] = "恢复武器栏",
	["sp_shenya:1"] = "恢复防具栏",
	["sp_shenya:2"] = "恢复+1马栏",
	["sp_shenya:3"] = "恢复-1马栏",
	["sp_shenya:4"] = "恢复宝物栏",
	["$sp_shenya"] = "（群鸦齐鸣）",
	  --阵亡
	["~sp_shenganning"] = "神鸦不佑，此身竟陨......",
	
	--==V3.0(DIY界限突破)==--
	--界刘繇
	["fcj_liuyao"] = "界刘繇[FC]",
	["&fcj_liuyao"] = "界刘繇",
	["#fcj_liuyao"] = "雨凄悲流",
	["designer:fcj_liuyao"] = "时光流逝FC",
	["cv:fcj_liuyao"] = "官方",
	["illustrator:fcj_liuyao"] = "DH",
	  --戡难
	["fcj_kannan"] = "戡难",
	["fcj_kannanCard"] = "“戡难”拼点",
	["fcj_kannanBUFF"] = "戡难",
	[":fcj_kannan"] = "出牌阶段，若你于此阶段内发动过此技能的次数<font color='red'><b>不大于</b></font>X（X为你的体力值），你可与你于此阶段内未以此法拼点过的一名其他角色拼点。" ..
						"若：你赢，你使用的下一张<font color='red'><b>造成伤害的</b></font>【杀】伤害+1；其赢，其使用的下一张<font color='red'><b>造成伤害的</b></font>【杀】伤害+1。" ..
						"<font color='red'><b>然后你选择一项：1.摸一张牌；2.此次发动此技能不计入次数；3.视为此阶段内未与该角色以此法拼点。</b></font>",
	["fcj_kannanUsed"] = "",
	["fcj_kannan:1"] = "摸一张牌",
	["fcj_kannan:2"] = "此次发动此技能不计入次数",
	["fcj_kannan:3"] = "视为此阶段内未与该角色以此法拼点",
	["$fcj_kannan1"] = "避公明谋乱，逐公明心腹。",
	["$fcj_kannan2"] = "权贵争斗，吾只求戡难。",
	  --阵亡
	["~fcj_liuyao"] = "固守一方，果不是长久之法......",
	
	--界庞德公
	["fcj_pangdegong"] = "界庞德公[FC]",
	["&fcj_pangdegong"] = "界庞德公",
	["#fcj_pangdegong"] = "超脱于世",
	["designer:fcj_pangdegong"] = "时光流逝FC",
	["cv:fcj_pangdegong"] = "官方",
	["illustrator:fcj_pangdegong"] = "JanusLausDeo",
	  --评才
	["fcj_pingcai"] = "评才",
	["fcj_pingcaiIDO"] = "评才",
	[":fcj_pingcai"] = "出牌阶段限一次，你可以挑选一个宝物，并根据宝物类型执行对应的效果：\
	<font color='red'><b>[卧龙]</b></font>对至多<font color='red'><b>两</b></font>名角色各造成1点火焰伤害。（因缘人物：卧龙诸葛亮）\
	<font color='orange'><b>[凤雏]</b></font>让至多<font color='red'><b>四</b></font>名角色进入连环状态。（因缘人物：庞统）\
	<font color=\"#00FFFF\"><b>[水镜]</b></font>将一名角色装备区内的<font color='red'><b>一张牌</b></font>移动到另一名角色的相应位置。（因缘人物：司马徽）\
	<font color=\"#4DB873\"><b>[玄剑]</b></font>令一名角色摸一张牌并回复1点体力，<font color='red'><b>然后你摸一张牌。</b></font>（因缘人物：徐庶）\
	<font color='red'><b>执行一次相应效果后，若场上有存活的对应“因缘人物”，则可以再执行一次对应效果。</b></font>",
	["@fcj_pingcai-ChooseTreasure"] = "请挑选一个宝物",
	["@fcj_pingcai-ChooseTreasure:wolong"] = "卧龙",
	["$fcj_pingcai-ChooseTreasure_wolong"] = "%from 选择了宝物【<font color='red'><b>东官苍龙·卧龙</b></font>】",
	["@fcj_pingcai-ChooseTreasure:fengchu"] = "凤雏",
	["$fcj_pingcai-ChooseTreasure_fengchu"] = "%from 选择了宝物【<font color='orange'><b>南官朱雀·凤雏</b></font>】",
	["@fcj_pingcai-ChooseTreasure:shuijing"] = "水镜",
	["$fcj_pingcai-ChooseTreasure_shuijing"] = "%from 选择了宝物【<font color=\"#00FFFF\"><b>北官玄武·水镜</b></font>】",
	["@fcj_pingcai-ChooseTreasure:xuanjian"] = "玄剑",
	["$fcj_pingcai-ChooseTreasure_xuanjian"] = "%from 选择了宝物【<font color=\"#4DB873\"><b>西官白虎·玄剑</b></font>】",
	["fcj_pingcaiRXJ"] = "",
	["$fcj_pingcai1"] = "时值乱世，当出奇才。", --开始评价
	    --卧龙
	  ["$fcj_pingcai2"] = "东官苍龙，动则烈火焚天。", --卧龙
	  ["fcj_pingcaiWolong"] = "评才-卧龙",
	  ["fcj_pingcaiwolong"] = "评才-卧龙",
	  ["@fcj_pingcaiWolong-card"] = "你可以选择至多两名角色，对他们各造成1点火焰伤害",
	  ["$fcj_pingcaiWolong"] = "因为场上有因缘人物 %to 存活，%from 可以再发动一次宝物【<font color='red'><b>东官苍龙·卧龙</b></font>】的效果",
	    --凤雏
	  ["$fcj_pingcai3"] = "南官朱雀，舞则人间血海。", --凤雏
	  ["fcj_pingcaiFengchu"] = "评才-凤雏",
	  ["fcj_pingcaifengchu"] = "评才-凤雏",
	  ["@fcj_pingcaiFengchu-card"] = "你可以横置至多四名角色",
	  ["$fcj_pingcaiFengchu"] = "因为场上有因缘人物 %to 存活，%from 可以再发动一次宝物【<font color='orange'><b>南官朱雀·凤雏</b></font>】的效果",
	    --水镜
	  ["$fcj_pingcai4"] = "北官玄武，伏则隐士于野。", --水镜
	  ["fcj_pingcaiShuijing"] = "评才-水镜",
	  ["fcj_pingcaishuijing"] = "评才-水镜",
	  ["@fcj_pingcaiShuijing-card"] = "你可以将场上装备区的一张牌移动到另一个合法位置",
	  ["@fcj_pingcaiShuijing_Equip-to"]  = "请选择移动的目标角色",
	  ["$fcj_pingcaiShuijing"] = "因为场上有因缘人物 %to 存活，%from 可以再发动一次宝物【<font color=\"#00FFFF\"><b>北官玄武·水镜</b></font>】的效果",
	    --玄剑
	  ["$fcj_pingcai5"] = "西官白虎，出则平乱济世。", --玄剑
	  ["fcj_pingcaiXuanjian"] = "评才-玄剑",
	  ["fcj_pingcaixuanjian"] = "评才-玄剑",
	  ["@fcj_pingcaiXuanjian-card"] = "你可以令一名角色摸一张牌并回复1点体力",
	  ["~fcj_pingcaiXuanjian"] = "然后你也可以摸一张牌",
	  ["$fcj_pingcaiXuanjian"] = "因为场上有因缘人物 %to 存活，%from 可以再发动一次宝物【<font color=\"#4DB873\"><b>西官白虎·玄剑</b></font>】的效果",
	  --隐世（同原版）
	  --阵亡
	["~fcj_pangdegong"] = "身处乱世，还是当效仿戒子之道......",
	
	--界陈到
	["fcj_chendao"] = "界陈到[FC]",
	["&fcj_chendao"] = "界陈到",
	["#fcj_chendao"] = "忠勇敢战",
	["designer:fcj_chendao"] = "时光流逝FC",
	["cv:fcj_chendao"] = "官方",
	["illustrator:fcj_chendao"] = "梦回唐朝·久吉",
	  --往烈
	["fcj_wanglie"] = "往烈",
	["fcj_wanglieSecondCard"] = "往烈",
	["fcj_wanglieAnaleptic"] = "往烈",
	[":fcj_wanglie"] = "出牌阶段，你使用的第一张牌<font color='red'><b>不计入次数限制、第二张牌无距离限制</b></font>。当你于出牌阶段使用一张牌时，" ..
	"你可令此牌：1.不能被响应；<font color='red'><b>2.伤害+1；3.[背水]依次执行前两项，若如此做，此阶段你不能再使用牌。（每个出牌阶段每项各限选择一次）</b></font>",
	["fcj_wanglieFQC"] = "",
	["fcj_wanglie:Hit"] = "令此牌不能被响应",
	["fcj_wanglie:Damage"] = "令此牌伤害+1",
	["fcj_wanglie:Beishui"] = "[背水]依次执行前两项(强命+加伤)，此阶段不能再使用牌",
	["$fcj_wanglie1"] = "精锐之师，何人能挡？",
	["$fcj_wanglie2"] = "击敌百里，一往无前！",
	  --阵亡
	["~fcj_chendao"] = "由来征战地，不见有人还......",
	
	--界赵统赵广
	["fcj_zhaotongzhaoguang"] = "界赵统赵广[FC]",
	["&fcj_zhaotongzhaoguang"] = "界赵统赵广",
	["#fcj_zhaotongzhaoguang"] = "子承父业",
	["designer:fcj_zhaotongzhaoguang"] = "时光流逝FC",
	["cv:fcj_zhaotongzhaoguang"] = "官方",
	["illustrator:fcj_zhaotongzhaoguang"] = "云涯",
	  --翊赞、龙渊（同手杀原版）
	  --云兴
	["fcj_yunxing"] = "云兴",--<font color='red'><b>云兴</b></font>",
	[":fcj_yunxing"] = "<font color='red'><b>(新增技能)</b></font>游戏开始时，你从牌堆随机获得一张基本牌和一张武器牌。回合开始时/回合结束时，你从牌堆随机获得X/Y张基本牌。（X为你上轮回合外发动“翊赞”的次数；Y为你本回合发动“翊赞”的次数）",
	["$fcj_yunxing1"] = "我们兄弟齐心合力，也能和父亲一样！", --这一切，都是为了护佑大汉！
	["$fcj_yunxing2"] = "是时候让敌人见识赵家真正的本领了！", --我们的武艺，已经足够精进了！
	  --阵亡
	["~fcj_zhaotongzhaoguang"] = "可惜，看不到伯约大人成功了......",
	
	--界于禁-旧
	["fcj_yujin_old"] = "界于禁-旧[FC]",
	["&fcj_yujin_old"] = "界于禁",
	["#fcj_yujin_old"] = "魏武之强", --三国志12曹操：？
	["designer:fcj_yujin_old"] = "时光流逝FC",
	["cv:fcj_yujin_old"] = "官方",
	["illustrator:fcj_yujin_old"] = "XXX", --难道画师真的是叫这个名字
	  --毅重
	["fcj_yizhong"] = "毅重",
	["fcj_yizhongLS"] = "毅重",
	[":fcj_yizhong"] = "锁定技，<font color='blue'><s>若你的装备区里没有防具牌，</s></font>黑色【杀】对你无效；<font color='black'><b>你的黑色【杀】不可被响应。" ..
	"结束阶段开始时，你可以弃置一张黑色牌，令一名其他角色获得此技能直到其下回合结束。</b></font>",
	["@fcj_yizhong-invoke"] = "请弃置一张黑色牌",
	["@fcj_yizhong-choose"] = "请选择一名其他角色，令其获得“毅重”直到其下回合结束",
	["$fcj_yizhong1"] = "有我坐镇，岂会有所差池！",
	["$fcj_yizhong2"] = "持军严整，镇威御敌！",
	  --阵亡
	["~fcj_yujin_old"] = "若不降蜀，此节可保......",
	
	--界曹昂
	["fcj_caoang"] = "界曹昂[FC]",
	["&fcj_caoang"] = "界曹昂",
	["#fcj_caoang"] = "竭战鳞伤",
	["designer:fcj_caoang"] = "时光流逝FC",
	["cv:fcj_caoang"] = "官方",
	["illustrator:fcj_caoang"] = "tswck",
	  --慷忾
	["fcj_kangkai"] = "慷忾",
	[":fcj_kangkai"] = "每当一名距离<font color='red'><b>X</b></font>以内的角色成为<font color='red'><b>伤害类卡牌</b></font>的目标后<font color='red'><b>（X为1；若该牌为【杀】，则改为2）</b></font>，" ..
	"你可以摸一张牌，然后正面朝上交给该角色<font color='red'><b>(注:若交给自己则改为展示之)</b></font>一张牌<font color='red'><b>：若此牌为基本牌或【无懈可击】，你可以令该角色摸一张牌；否则该角色可以使用之</b></font>。",
	["@fcj_kangkai-give"] = "请选择一张牌交给 %src",
	["fcj_kangkai_hedraw"] = "[慷忾]令其摸一张牌",
	["fcj_kangkai_use:use"] = "[慷忾]你是否要使用这张交给你的牌？<br/>\
	注：点【确定】->可以使用这张牌<br/>\
	点【取消】->不使用这张牌",
	["@fcj_kangkai_ut"] = "你可以使用这张【<font color='yellow'><b>%src</b></font>】",
	["$fcj_kangkai1"] = "能与典将军一同杀敌，实在痛快！",
	["$fcj_kangkai2"] = "岂能让尔等轻易得逞？",
	  --阵亡
	["~fcj_caoang"] = "典将军，还请...保护好父亲......",
	
	--界吕岱
	["fcj_lvdai"] = "界吕岱[FC]",
	["&fcj_lvdai"] = "界吕岱",
	["#fcj_lvdai"] = "交趾震威",
	["designer:fcj_lvdai"] = "时光流逝FC",
	["cv:fcj_lvdai"] = "官方",
	["illustrator:fcj_lvdai"] = "福州光域",
	  --勤国
	["fcj_qinguo"] = "勤国",
	[":fcj_qinguo"] = "当你<font color='blue'><s>于回合内</s></font>使用装备牌结算结束后，你可视为使用一张<font color='red'><b>无距离限制且</b></font>不计次的【杀】。" ..
	"当你装备区里的牌移动后或有装备牌移至你的装备区后，若你装备区里的牌数：1.与你的体力值相等；2.与此次移动之前你装备区里的牌数不等，" ..
	"<font color='red'><b>每满足一项，</b></font>你回复1点体力<font color='red'><b>并摸一张牌</b></font>。",
	["@fcj_qinguo-slash"] = "你可以视为使用一张无距离限制且不计次的【杀】",
	["~fcj_qinguo"] = "选择一名可被选择的目标角色，点【确定】",
	["$fcj_qinguo1"] = "戮力奉公，勤心侍国！",
	["$fcj_qinguo2"] = "忠心为国，有国奉公！",
	  --阵亡
	["~fcj_lvdai"] = "我..还想守护这山河......",
	
	--界陆抗
	["fcj_lukang"] = "界陆抗[FC]",
	["&fcj_lukang"] = "界陆抗",
	["#fcj_lukang"] = "毁堰破晋",
	["designer:fcj_lukang"] = "时光流逝FC",
	["cv:fcj_lukang"] = "官方",
	["illustrator:fcj_lukang"] = "第七个桔子",
	  --谦节（同原版）
	  --决堰
	["fcj_jueyan"] = "决堰",
	["fcj_jueyanWeapon"] = "决堰",
	["fcj_jueyanArmor"] = "决堰",
	["fcj_jueyanHorse"] = "决堰",
	[":fcj_jueyan"] = "出牌阶段<font color='blue'><s>限一次</s></font>，你可以废除你装备区里的一个装备栏，然后执行对应的一项：\
	武器栏，本回合你可以多使用三张【杀】；\
	防具栏，摸三张牌，本回合你的手牌上限+3；\
	两个坐骑栏，本回合你使用牌无距离限制；\
	宝物栏，本回合你视为拥有“<font color='red'><b>界</b></font>集智”。",
	["fcj_jueyan0"] = "武器栏",
	["fcj_jueyan1"] = "防具栏",
	["fcj_jueyan2"] = "两个坐骑栏",
	["fcj_jueyan4"] = "宝物栏",
	["$fcj_jueyan-0"] = "%from 发动“<font color='yellow'><b>决堰</b></font>”废除了 <font color='red'><b>武器栏</b></font> ，本回合可以多使用三张【<font color='yellow'><b>杀</b></font>】",
	["$fcj_jueyan-1"] = "%from 发动“<font color='yellow'><b>决堰</b></font>”废除了 <font color='red'><b>防具栏</b></font> ，本回合手牌上限+3",
	["$fcj_jueyan-2"] = "%from 发动“<font color='yellow'><b>决堰</b></font>”废除了 <font color='red'><b>两个坐骑栏</b></font> ，本回合使用牌无距离限制",
	["$fcj_jueyan-4"] = "%from 发动“<font color='yellow'><b>决堰</b></font>”废除了 <font color='red'><b>宝物栏</b></font> ，本回合视为拥有“<font color='yellow'><b>集智</b></font>”",
	["$fcj_jueyan1"] = "毁堰废坝，阻晋军粮道。",
	["$fcj_jueyan2"] = "吾已毁堰阻碍，晋军有计也难施！",
	  --破势
	["fcj_poshi"] = "破势",
	[":fcj_poshi"] = "觉醒技，准备阶段<font color='red'>开始时</font>，若你的装备栏均被废除或体力值为1，你减1点体力上限，然后将手牌补至<font color='red'><b>X（X为你的体力上限+你未被废除的装备栏数）</b></font>，失去技能“决堰”并获得技能“怀柔”。",
	["$fcj_poshi1"] = "良谋益策，破敌腹背。",
	["$fcj_poshi2"] = "破晋军雄威，断敌心谋略！",
	    --怀柔
	  ["ps_huairou"] = "怀柔",
	  ["ps_huairou_qicai"] = "怀柔",
	  ["ps_huairouEnd"] = "怀柔",
	  [":ps_huairou"] = "出牌阶段，你可以重铸装备牌，<font color='red'><b>若如此做，此阶段你的攻击范围+1。</b></font>",
	  ["$ps_huairou1"] = "一邑一乡，不可以无信义。",
	  ["$ps_huairou2"] = "彼专为德我专为暴，是不战而自服也！",
	  --阵亡
	["~fcj_lukang"] = "唉，陛下不听，社稷恐有危难......",
	
	--界麹义
	["fcj_quyi"] = "界麹义[FC]",
	["&fcj_quyi"] = "界麹义",
	["#fcj_quyi"] = "界桥先登",
	["designer:fcj_quyi"] = "时光流逝FC",
	["cv:fcj_quyi"] = "官方",
	["illustrator:fcj_quyi"] = "王立雄",
	  --伏骑
	["fcj_fuqi"] = "伏骑",
	[":fcj_fuqi"] = "锁定技，当你使用【杀】或普通锦囊牌指定目标后，<font color='red'><b>与你距离为1或你距离其为1</b></font>的其他角色不能响应此牌。",
	["$fcj_fuqi1"] = "白马？不足挂齿！",
	["$fcj_fuqi2"] = "掌握之中，岂可逃之？",
	  --骄恣
	["fcj_jiaozi"] = "骄恣",
	[":fcj_jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌数：1.为全场最多<font color='red'><b>（或之一）；2.为全场最少（或之一），每满足一项</b></font>，此伤害+1。",
	["$fcj_jiaozi1"] = "数战之功，吾应得此赏！",
	["$fcj_jiaozi2"] = "无我出力，怎会连胜？",
	  --阵亡
	["~fcj_quyi"] = "主公，我无异心啊！......",
	
	--界司马徽
	["fcj_simahui"] = "界司马徽[FC]",
	["&fcj_simahui"] = "界司马徽",
	["#fcj_simahui"] = "龙兴凤举",
	["designer:fcj_simahui"] = "时光流逝FC",
	["cv:fcj_simahui"] = "官方",
	["illustrator:fcj_simahui"] = "方心宇",
	  --荐杰
	["fcj_jianjie"] = "荐杰",
	["fcj_jianjieTrigger"] = "荐杰",
	["fcj_jianjieMarks"] = "荐杰",
	[":fcj_jianjie"] = "<b>①</b><font color='blue'><s>你的第一个</s></font>回合开始时，<font color='red'><b>若你本局未于此时机触发过该条技能，</b></font>" ..
	"<font color='red'><b>你获得“龙印”和“凤印”各一个</b></font>并选择两名不同角色<font color='red'><b>（可以选自己）</b></font>，其中一位获得一个“龙印”，另一位获得一个“凤印”；\
	<b>②</b><b><font color='green'>出牌阶段限<font color='red'>两次</font><font color='blue'><s>（第一轮除外）</s></font>，</font></b>你可以转移一个“龙印”/“凤印”；\
	<b>③</b>当有“龙印”/“凤印”的角色死亡时，你可以转移其<font color='red'><b>所有</b></font>“龙印”/“凤印”。\
	------------\
	<font color=\"#FFCC00\"><b>◇</b>拥有至少一个“龙印”/“凤印”的角色视为拥有技能“界火计(手杀)”/“界连环(手杀,OL)”<font color='blue'><s>（每个回合限三次）</s></font>；</font>\
	<font color='orange'><b>○</b>拥有至少两个“龙印”/“凤印”的角色视为拥有技能“智哲(十周年)”/“界涅槃(OL)”，且发动后移去一个“龙印”/“凤印” ；</font>\
	<font color='red'><b>☆</b>拥有至少两个“龙印”+至少两个“凤印”的角色视为拥有技能“鸾凤(OL)”，且发动后移去所有“龙印”和“凤印”。</font>\
	<font color='purple'><b>△注：</b>为避免出现“技能掠夺者”行为，所有衍生技能都是我自己重新写的。</font>",
	["fcj_Loong"] = "[龙印]",
	["fcj_Phoenix"] = "[凤印]",
	["fcj_jianjied"] = "荐杰",
	["fcj_jianjie:1"] = "移动其“龙印”",
	["fcj_jianjie:2"] = "移动其“凤印”",
	["fcj_jianjieStart-LY"] = "[卧龙出山]请选择一名角色，其获得一个“龙印”",
	["fcj_jianjieStart-FY"] = "[凤出东方]请选择一名角色，其获得一个“凤印”",
	["fcj_jianjiePlay-LY"] = "请选择转移“龙印”的目标",
	["fcj_jianjiePlay-FY"] = "请选择转移“凤印”的目标",
	["fcj_jianjieDeath-LY"] = "你可以将其所有“龙印”转移给除其之外的一名角色",
	["fcj_jianjieDeath-FY"] = "你可以将其所有“凤印”转移给除其之外的一名角色",
	["$fcj_jianjie1"] = "使君匡扶天下之愿，此二人可助之。", --开局
	["$fcj_jianjie2"] = "使君如欲匡扶汉室，我可荐一人。", --0->1
	["$fcj_jianjie3"] = "此人定可成为使君之国公。", --0->1
	["$fcj_jianjie4"] = "将军武艺超绝，当立斩将破城之功！", --0/1->2
	["$fcj_jianjie5"] = "先生才通天地，必能造福黎庶！", --0/1->2
	    --1龙印：界火计
	  ["fcjiehuoji"] = "火计",
	  [":fcjiehuoji"] = "出牌阶段，你可以将一张红色牌当【火攻】使用。",
	    --1凤印：界连环
	  ["fcjielianhuan"] = "连环",
	  ["fcjielianhuans"] = "连环",
	  [":fcjielianhuan"] = "出牌阶段，你可以将一张梅花手牌当【铁索连环】使用或重铸；当你使用【铁索连环】时，你可以额外指定一个目标。",
	  ["@fcjielianhuans-excard"] = "你可以为【%src】选择一名额外目标",
	    --2龙印：智哲
	  ["fczhizhe"] = "智哲",
	  ["fczhizhe_vs"] = "智哲",
	  ["fczhizheFCB"] = "智哲",
	  [":fczhizhe"] = "限定技，出牌阶段，你可以“复制”一张<font color='red'><b>非装备</b></font>手牌。当此牌因被你使用或打出而进入弃牌堆时，你获得之，" ..
	  "然后你本回合不能再使用或打出此牌。",
	  ["$fczhizhe"] = "三顾之谊铭心，隆中之言在耳，请托臣讨贼兴复之效。",
	  ["_fczhizhe_basic"] = "智哲[基本牌]",
	  ["FczhizheBasic"] = "智哲[基本牌]",
	  ["_fczhizhe_trick"] = "智哲[锦囊牌]",
	  ["FczhizheTrick"] = "智哲[锦囊牌]",
	    --2凤印：界涅槃
	  ["fcjieniepan"] = "涅槃",
	  [":fcjieniepan"] = "限定技，当你处于濒死状态时，你可以弃置你区域内所有牌、复原你的武将牌并摸三张牌。若如此做，你将体力值回复至3点，" ..
	  "然后获得【“八阵”、“OL界火计”、“OL界看破”】中的其中一个技能。",
	  ["$fcjieniepan"] = "烈火脱胎，涅槃重生！",
	    --2龙印+2凤印：鸾凤
	  ["fcluanfeng"] = "鸾凤",
	  [":fcluanfeng"] = "限定技，当一名体力上限不小于你的角色进入濒死状态时，你可以令其将体力值回复至3点，恢复其所有被废除的装备栏，令其将手牌摸至X张（X为6-以此法恢复的装备栏数量）。" ..
	  "<font color='blue'><s>若该角色是你，重置你“游龙”使用过的牌名</s></font>。",
	  ["fcj_simahui_wlfc"] = "司马徽·卧龙凤雏",
	  --称好（同原版）
	  --隐士（削了）
	["fcj_yinshi"] = "隐士",
	[":fcj_yinshi"] = "锁定技，当你受到属性伤害或锦囊牌造成的伤害时，若你没有“龙印”<font color='blue'><b>和</b></font>“凤印”且装备区内没有防具牌，防止此伤害。",
	["$fcj_yinshi1"] = "乱世浮沉，非我所能改变。",
	["$fcj_yinshi2"] = "我不过一介村夫，公何必多言。",
	  --阵亡
	["~fcj_simahui"] = "天下之事，果然无人可免......",
	
	--界马良
	["fcj_maliang"] = "界马良[FC]",
	["&fcj_maliang"] = "界马良",
	["#fcj_maliang"] = "文经勤类",
	["designer:fcj_maliang"] = "时光流逝FC",
	["cv:fcj_maliang"] = "官方",
	["illustrator:fcj_maliang"] = "NOVART",
	  --自书
	["fcj_zishu"] = "自书",
	[":fcj_zishu"] = "锁定技，你的回合外，你获得的牌均会在当前回合结束后置入弃牌堆；<font color='red'><b>你的回合开始时，你摸X张牌；</b></font>" ..
	"你的回合内，当你不因此技能效果获得牌时，摸一张牌。<font color='red'><b>（X为：自你上回合结束后至此时，在你有此技能的期间，从你的区域离开后进入弃牌堆的牌数）</b></font>",
	["$fcj_zishu1"] = "此物，于我已无用。", --弃牌
	["$fcj_zishu2"] = "好东西，要一起分享~", --摸牌
	["$fcj_zishu3"] = "自己的才是最好的。", --大摸牌
	  --应援（同手杀新版）
	  --阵亡
	["~fcj_maliang"] = "兴汉大业，谁来继续......",
	
	--界马忠
	--["fcj_mazhong"] = "界马忠",
	["fcj_mazhong"] = "界马忠[FC]", --我写的过程中才发现新杀已出有界马忠了，于是乎就这样尬住了
	["&fcj_mazhong"] = "界马忠",
	["#fcj_mazhong"] = "意气风发",
	["designer:fcj_mazhong"] = "时光流逝FC",
	["cv:fcj_mazhong"] = "官方",
	["illustrator:fcj_mazhong"] = "影紫C",
	  --抚蛮
	["fcj_fuman"] = "抚蛮",
	["fcj_fuman"] = "抚蛮",
	[":fcj_fuman"] = "出牌阶段，你可以将一张<font color='red'><b>伤害牌或武器牌</b></font>交给一名本阶段未获得过“抚蛮”牌的其他角色" ..
	"<font color='red'><b>，然后摸一张牌</b></font>。之后当其使用“抚蛮”牌时，你<font color='red'><b>与其各</b></font>摸一张牌。",
	["$fcj_fuman1"] = "拿着家伙，跟我上！", --给牌
	["$fcj_fuman2"] = "请各位，助我一臂之力！", --给牌
	["$fcj_fuman3"] = "国家兴亡，匹夫有责！", --一起摸牌
	["$fcj_fuman4"] = "跟着我们丞相走，错不了！", --一起摸牌
	  --阵亡
	["~fcj_mazhong"] = "你们为何...拿钱不出力？......",
	
	--界乐进
	["fcj_yuejin"] = "界乐进[FC]",
	["&fcj_yuejin"] = "界乐进",
	["#fcj_yuejin"] = "勇猛精进",
	["designer:fcj_yuejin"] = "时光流逝FC",
	["cv:fcj_yuejin"] = "官方",
	["illustrator:fcj_yuejin"] = "小北风巧绘",
	  --骁果
	["fcj_xiaoguo"] = "骁果",
	[":fcj_xiaoguo"] = "<font color='red'><b>一名</b></font>角色的结束阶段<font color='red'>开始时</font>，" ..
	"你可以弃置一张<font color='blue'><s>基本</s></font>牌，选择一名角色，然后令当前回合角色与该角色依次选择一项：" ..
	"1.弃置一张<font color='red'><b>与你弃置的牌类型相同的</b></font>牌，你摸一张牌；2.受到你造成的1点伤害。",
	["fcj_xiaoguo:1"] = "弃置一张与其弃置的牌同类型的牌并令其摸一张牌(否则仍受到其伤害)",
	["fcj_xiaoguo:2"] = "受到其造成的1点伤害",
	["@fcj_xiaoguo-disBasic"] = "[骁果]请弃置一张基本牌",
	["@fcj_xiaoguo-disTrick"] = "[骁果]请弃置一张锦囊牌",
	["@fcj_xiaoguo-disEquip"] = "[骁果]请弃置一张装备牌",
	["$fcj_xiaoguo1"] = "当敌制决，靡有遗失！",
	["$fcj_xiaoguo2"] = "奋强突固，无坚不可陷！",
	  --先登
	["fcj_xiandeng"] = "先登",
	[":fcj_xiandeng"] = "<b><font color='red'>(新增技能)</font><font color='green'>回合内与回合外各限一次，</font></b>当你造成伤害后，你摸一张牌并回复1点体力。",
	["$fcj_xiandeng1"] = "两阵相邻，必有一战！",
	["$fcj_xiandeng2"] = "先登攻城，以立战功！",
	  --阵亡
	["~fcj_yuejin"] = "不能再为主公...杀敌了......",
	
	--界文聘
	--["fcj_wenpin"] = "界文聘",
	["fcj_wenpin"] = "界文聘[FC]", --梅开二度！XD
	["&fcj_wenpin"] = "界文聘",
	["#fcj_wenpin"] = "勇者不惧",
	["designer:fcj_wenpin"] = "时光流逝FC",
	["cv:fcj_wenpin"] = "官方",
	["illustrator:fcj_wenpin"] = "凝聚永恒",
	  --镇卫->金汤
	["fcj_jintang"] = "金汤",
	["fcj_jintangDefense"] = "金汤",
	[":fcj_jintang"] = "<font color='red'><b>每轮开始时，你清除上轮通过此技能选择的“己方”和“敌方”，然后先选择任意名角色（称为“己方”），再选择任意名其他非“己方”角色（称为“敌方”），" ..
	"则本轮内，</b></font>“敌方”角色计算与“己方”角色的距离+1。",
	["fcj_jintang_Friends"] = "己方",
	["fcj_jintang_Enemies"] = "敌方",
	["@fcj_jintang-chooseFriends"] = "[“己方”选择]你可以选择任意名角色成为“己方”",
	["@fcj_jintang-chooseEnemies"] = "[“敌方”选择]你可以选择任意名其他非“己方”角色成为“敌方”",
	["$fcj_jintang1"] = "某在此镇守，尔等某要再来献丑！",
	["$fcj_jintang2"] = "十万大军，某也叫你无路可进！",
	  --镇卫
	["fcj_zhenwei"] = "镇卫",
	[":fcj_zhenwei"] = "当其他角色成为<font color='red'><b>不为你使用的</b></font>【杀】/<font color='red'><b>红色锦囊牌</b></font>/黑色锦囊牌的唯一目标时，" ..
	"若其体力值<font color='red'><b>不等于/不小于/不大于</b></font>你，你可以弃置一张牌并选择一项：1.摸一张牌，然后将此牌转移给你；" ..
	"2.令此牌无效<font color='red'><b>并将此牌置于使用者的武将牌上</b></font>，回合结束后，其获得此牌。", --从单纯的守变为攻守兼备
	["fcj_zhenwei:1"] = "摸一张牌，将此牌转移给自己",
	["fcj_zhenwei:2"] = "令此牌无效并将此牌置于其武将牌上",
	["$fcj_zhenwei1"] = "我来奉陪！",
	["$fcj_zhenwei2"] = "喝！有本事就冲我来吧！",
	  --阵亡
	["~fcj_wenpin"] = "边疆有失，我之过也......",
	
	--界诸葛瑾
	["fcj_zhugejin"] = "界诸葛瑾[FC]",
	["&fcj_zhugejin"] = "界诸葛瑾",
	["#fcj_zhugejin"] = "文墨为箭",
	["designer:fcj_zhugejin"] = "时光流逝FC",
	["cv:fcj_zhugejin"] = "官方",
	["illustrator:fcj_zhugejin"] = "枭瞳",
	  --缓释
	["fcj_huanshi"] = "缓释",
	[":fcj_huanshi"] = "当一名角色的判定牌生效前，你可以令其观看你的牌并用其中一张牌<font color='red'><b>替换</b></font>判定牌，然后你可以重铸任意张牌。",
	["@fcj_huanshi-card"] = "你可以选择其中一张牌替换此判定牌",
	["fcj_huanshi:h"] = "用其中的一张手牌改判",
	["fcj_huanshi:e"] = "用其装备区里的一张牌改判",
	["@fcj_huanshi-Recast"] = "你可以选择任意张牌进行重铸",
	["$fcj_huanshi1"] = "君子，成人之美。",
	["$fcj_huanshi2"] = "言者无罪，闻者足戒。",
	  --弘援
	["fcj_hongyuan"] = "弘援",
	[":fcj_hongyuan"] = "摸牌阶段，你可以少摸一张牌，若如此做，摸牌阶段结束时，你令<font color='red'><b>任意名其他角色</b></font>各摸一张牌；" ..
	"<font color='green'><b>每阶段限一次，</b></font>当你一次获得至少两张牌后，你可以交给至多<font color='red'><b>X</b></font>名其他角色各一张牌（X为你此次获得的牌数）。",
	["@fcj_hongyuanDC"] = "[弘援]少摸张牌，让队友们各摸一张牌",
	["@fcj_hongyuanGC"] = "[弘援]获得了牌，分给队友们各一张牌",
	["@fcj_hongyuan-card1"] = "你可以令任意名其他角色各摸一张牌",
	["@fcj_hongyuan-card2"] = "你可以选择至多%src名其他角色，交给这些角色各一张牌",
	["$fcj_hongyuan1"] = "增援至矣，一改我军劣势！",
	["$fcj_hongyuan2"] = "鼓噪而进，振士气，定军心！",
	  --明哲
	["fcj_mingzhe"] = "明哲",
	[":fcj_mingzhe"] = "<s>锁定技，</s>当你于出牌阶段外<font color='red'><b>不因此技能[获得黑色牌/</b></font>失去红色牌<b>]</b>后，" ..
	"你<font color='red'><b>可以</b></font>展示之，并<b><font color='red'>立即使用之<font color='orange'>(注:询问优先级高于“弘援”)</font>/</font></b>摸一张牌。",
	["@fcj_mingzheGC"] = "[明哲]展示获得的牌并使用",
	["@fcj_mingzheLC"] = "[明哲]展示失去的牌并摸牌",
	["@fcj_mingzhe_usecard"] = "你可以使用这张【<font color='yellow'><b>%src</b></font>】",
	["$fcj_mingzhe1"] = "穷则独善其身，达则兼济天下！",
	["$fcj_mingzhe2"] = "义之所在，不倾于权，不顾其利。",
	  --阵亡
	["~fcj_zhugejin"] = "为富国政，此身何惜......",
	
	--界贺齐
	["fcj_heqi"] = "界贺齐[FC]",
	["&fcj_heqi"] = "界贺齐",
	["#fcj_heqi"] = "奢绮之军",
	["designer:fcj_heqi"] = "时光流逝FC",
	["cv:fcj_heqi"] = "官方",
	["illustrator:fcj_heqi"] = "白夜零BYL",
	  --绮胄
	["fcj_qizhou"] = "绮胄",
	[":fcj_qizhou"] = "锁定技，你根据装备区里牌的花色数视为拥有以下技能：\
	0种或以上：“<font color='red'><b>神骑</b></font>”<font color='orange'><b>(注:不会给技能按钮,但实际上效果已体现)</b></font>；\
	1种或以上：“<font color='red'><b>手杀界破军</b></font>”；\
	2种或以上：“<font color='red'><b>劫营</b></font>”；\
	3种或以上：“<font color='red'><b>新杀界旋风</b></font>”；\
	4种或以上：“<font color='red'><b>新杀奋音</b></font>”；\
	5种：“<font color='red'><b>彰才+儒贤</b></font>”<font color='orange'><b></b></font>。\
	<font color='red'><b>游戏开始时，你将“我的装备”套装洗入牌堆。</b></font>", --5种条件极为苛刻，要全装有且有一件为无花色。
	--["$fcj_qizhou1"] = "",
	--["$fcj_qizhou2"] = "",
	  --==我的装备==--
	  ["fcjhq_equips"] = "别拿走，我的装备......",
	  --我的武器
	  ["_fcjhq_weapon"] = "我的武器",
	  ["FcjhqWeapon"] = "我的武器",
	  [":_fcjhq_weapon"] = "装备牌·武器<br /><b>攻击范围</b>：？ <br /><b>武器技能</b>：你的初始攻击范围改为4。",
	  --我的防具
	  ["_fcjhq_armor"] = "我的防具",
	  ["FcjhqArmor"] = "我的防具",
	  [":_fcjhq_armor"] = "装备牌·防具<br /><b>防具技能</b>：当你成为【杀】的目标时，你可以打出一张【闪】，令此【杀】对你无效。",
	  ["FcjhqArmor-jink"] = "请打出一张【闪】以无效化%src对你使用的【杀】",
	  --我的+1马
	  ["_fcjhq_dfhorse"] = "我的+1马",
	  ["FcjhqDfhorse"] = "我的+1马",
	  [":_fcjhq_dfhorse"] = "装备牌·坐骑<br /><b>坐骑技能</b>：锁定技，其他角色与你的距离+1。",
	  --我的-1马
	  ["_fcjhq_ofhorse"] = "我的-1马",
	  ["FcjhqOfhorse"] = "我的-1马",
	  [":_fcjhq_ofhorse"] = "装备牌·坐骑<br /><b>坐骑技能</b>：锁定技，你与其他角色的距离-1。",
	  --我的宝物
	  ["_fcjhq_treasure"] = "我的宝物",
	  ["FcjhqTreasure"] = "我的宝物",
	  [":_fcjhq_treasure"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，你的手牌上限为你的当前体力值与体力上限值的平均数（向下取整）。",
	  --============--
	  --闪袭
	["fcj_shanxi"] = "闪袭",
	["fcj_shanxiFakeMove"] = "闪袭",
	["fcj_shanxix"] = "闪袭",
	[":fcj_shanxi"] = "出牌阶段开始时，你可以弃置一张<font color='red'><b>黑</b></font>色基本牌并选择一名其他角色，然后你将该角色的至多X张牌置于其武将牌上（X为你的体力值）。" ..
	"回合结束时，其获得这些牌；出牌阶段限一次，你可以弃置一张红色基本牌，然后弃置<font color='blue'><s>攻击范围内的</s></font>一名其他角色的一张牌，" ..
	"若弃置的牌<font color='red'><b>的牌名含有</b></font>“闪”字，你观看其手牌；否则其观看你的手牌。",
	["@fcj_shanxix"] = "你可以发动“闪袭”：选择一张黑色基本牌->选中一名(有牌的)其他角色->锁定为犯大吴疆土者",
	["fcj_shanxi_num"] = "闪袭-选牌数",
	["fcj_shanxi_dis"] = "闪袭-选择牌",
	["$fcj_shanxi1"] = "有进无退，溃敌图克！",
	["$fcj_shanxi2"] = "速破叛寇，不容敌守！",
	  --阵亡
	["~fcj_heqi"] = "我军器精甲坚，竟也落败......",
	
	--界·晋司马师(主公)
	["fcj_jinsimashi"] = "界·晋司马师[FC]",
	["&fcj_jinsimashi"] = "界司马师",
	["#fcj_jinsimashi"] = "锐意无当",
	["designer:fcj_jinsimashi"] = "时光流逝FC",
	["cv:fcj_jinsimashi"] = "官方",
	["illustrator:fcj_jinsimashi"] = "夜小雨",
	  --韬隐+睿略（同原版）
	  --夷灭
	["fcj_yimie"] = "夷灭",
	[":fcj_yimie"] = "每个回合限一次，当你对其他角色造成伤害时，你可以失去1点体力，令此伤害+X（X为其体力值<font color='blue'><s>减去伤害值</s></font>），" ..
	"若如此做，此伤害结算完成后，该角色回复<font color='red'><b>至</b></font>X点体力。",
	["$fcj_yimieOPM"] = "👊一拳超人！因为“<font color='yellow'><b>夷灭</b></font>”的加成，%from 此次对 %to 造成的伤害 + %arg2",
	["$fcj_yimie1"] = "大逆之贼，当斩无赦！",
	["$fcj_yimie2"] = "司马氏刀下焉有活口乎？",
	  --泰然
	["fcj_tairan"] = "泰然",
	[":fcj_tairan"] = "锁定技，回合结束时，你将体力回复至体力上限并将手牌补充至体力上限；" ..
	"出牌阶段开始时，你失去上回合以此法回复的体力值<font color='red'><b>（至多以此法减至1点）</b></font>、<font color='red'><b>重铸</b></font>上回合以此法获得的手牌。",
	["fcj_tairanR"] = "泰然回复",
	["fcj_tairanD"] = "泰然补牌",
	["$fcj_tairan1"] = "海纳百川，量宏方豪杰。",
	["$fcj_tairan2"] = "养气数载，喜怒自当不浮于色。",
	  --阵亡
	["~fcj_jinsimashi"] = "二弟，切负父兄之厚望......",
	
	--界·晋杜预
	["fcj_jinduyu"] = "界·晋杜预[FC]",
	["&fcj_jinduyu"] = "界杜预",
	["#fcj_jinduyu"] = "委任修律",
	["designer:fcj_jinduyu"] = "时光流逝FC",
	["cv:fcj_jinduyu"] = "官方",
	["illustrator:fcj_jinduyu"] = "妙喵",
	  --三陈
	["fcj_sanchen"] = "三陈",
	[":fcj_sanchen"] = "<b><font color='green'>出牌阶段限<font color='red'>三</font>次</font></b>，你可以令一名角色摸三张牌<font color='red'><b>（每个回合至多以此法选择同一角色三次）</b></font>，" ..
	"然后弃置三张牌。若其以此法弃置的牌种类均不同，则其摸一张牌，<font color='blue'><b>并令该技能发动次数记录-1</b></font>。",
	["fcj_sanchenOne"] = "一陈",
	["fcj_sanchenTwo"] = "二陈",
	["fcj_sanchenThree"] = "三陈",
	["$fcj_sanchen1"] = "三陈累累，皆老臣珠玑之言，望陛下纳之任之。",
	["$fcj_sanchen2"] = "一陈谏固国，再陈论整军，三陈表吞吴！",
	  --昭讨
	["fcj_zhaotao"] = "昭讨",
	[":fcj_zhaotao"] = "觉醒技，回合开始时<font color='red'><b>或回合结束时</b></font>，若你本局游戏发动过至少三次“界三陈”，你减1点体力上限并获得技能“破竹”" ..
	"<font color='red'><b>，然后立即执行一个额外的回合（不可于该回合内发动“界三陈”）</b></font>。",
	["$fcj_zhaotao1"] = "得皇命之诏，伐不臣之贼！",
	["$fcj_zhaotao2"] = "今奉天承运，三军听诏：齐整军备，即日伐吴！",
	    --破竹（同原版）
	  --阵亡
	["~fcj_jinduyu"] = "司马氏得国不正，吾却助纣为虐，此天伐之......", --这个阵亡台词未免太抽象
	
	--界·神刘备
	["fcj_shenliubei"] = "界·神刘备[FC]",
	["&fcj_shenliubei"] = "界神刘备",
	["#fcj_shenliubei"] = "江山不过兄弟情",
	["designer:fcj_shenliubei"] = "时光流逝FC",
	["cv:fcj_shenliubei"] = "(皮肤:怒火复仇/帝王之姿)",
	["illustrator:fcj_shenliubei"] = "emoji组合",
	  --龙怒
	["fcj_longnu"] = "龙怒",
	["fcj_longnu_yang"] = "龙怒·阳",
	["fcj_longnu_yin"] = "龙怒·阴",
	["fcj_longnu_jieying_Buff"] = "",
	["fcj_longnu_BuffClear"] = "",
	[":fcj_longnu"] = "转换技，锁定技，出牌阶段开始时：" ..
	"①你失去1点体力并摸<font color='red'><b>X</b></font>张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制；" ..
	"②你减1点体力上限并摸<font color='red'><b>Y</b></font>张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。\
	<font color='red'><b>（X为你此时的体力值；Y为你此时的体力上限值）</b></font>",
	[":fcj_longnu1"] = "转换技，锁定技，出牌阶段开始时：" ..
	"①你失去1点体力并摸<font color='red'><b>X</b></font>张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制。" ..
	"<font color=\"#01A5AF\"><s>②你减1点体力上限并摸<font color='red'><b>Y</b></font>张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。</s></font>\
	<font color='red'><b>（X为你此时的体力值；Y为你此时的体力上限值）</b></font>",
	[":fcj_longnu2"] = "转换技，锁定技，出牌阶段开始时：" ..
	"<font color=\"#01A5AF\"><s>①你失去1点体力并摸<font color='red'><b>X</b></font>张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制。</s></font>" ..
	"②你减1点体力上限并摸<font color='red'><b>Y</b></font>张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。\
	<font color='red'><b>（X为你此时的体力值；Y为你此时的体力上限值）</b></font>",
	["$fcj_longnu1"] = "神龙降天怒，雷火镇仇雠！",
	["$fcj_longnu2"] = "手足之殇，不共戴天！",
	  --结营
	["fcj_jieying"] = "结营",
	[":fcj_jieying"] = "锁定技，你始终处于横置状态；已横置的角色手牌上限+2；<font color='red'><b>每名角色的</b></font>结束阶段，你横置一名其他角色" ..
	"<font color='red'><b>；你于回合内使用牌的距离和次数上限+Z（Z为回合开始时场上已横置的角色数）</b></font>。",
	["fcj_jieying-invoke"] = "你可以发动“结营”<br/> <b>操作提示</b>: 选择一名不处于连环状态的角色→点击确定<br/>",
	["$fcj_jieying1"] = "结桃园之义，雪手足之仇！",
	["$fcj_jieying2"] = "吾弟且慢行，待为兄报仇雪恨！",
	  --阵亡
	["~fcj_shenliubei"] = "云长，翼德，为兄来也......",
	
	--界·神张辽
	["fcj_shenzhangliao"] = "界·神张辽[FC]",
	["&fcj_shenzhangliao"] = "界神张辽",
	["#fcj_shenzhangliao"] = "且看八百破十万",
	["designer:fcj_shenzhangliao"] = "时光流逝FC",
	["cv:fcj_shenzhangliao"] = "官方+(皮肤:夺锐争锋)",
	["illustrator:fcj_shenzhangliao"] = "原画恶搞",
	  --夺锐+止啼（同新杀原版）
	  --雷袭
	["fcj_leixi"] = "雷袭",
	["fcj_leixiSlash"] = "雷袭",
	["fcj_leixislash"] = "雷袭",
	["fcj_leixiSlashBuff"] = "雷袭",
	["fcj_leixiDuel"] = "雷袭",
	["fcj_leixiduel"] = "雷袭",
	[":fcj_leixi"] = "<font color='red'><b>(新增技能)</b></font>出牌阶段开始时，根据你此时已被废除的装备栏数，你依次执行以下效果：\
	->至少0个，你从牌堆随机获得一张伤害类牌；\
	->至少1个，你可以将一张黑色手牌当无距离限制的雷【杀】使用；\
	->至少2个，你可以视为使用一张【决斗】（你以此法造成的伤害属性为雷电伤害）；\
	->至少3个，你可以选择一名其他角色，你们各摸一张牌后拼点：若你赢，你对其造成1点雷电伤害；\
	->至少4个，你可以直接对一名其他角色造成1点雷电伤害；\
	☆5个，你摸五张牌且本局造成的雷电伤害+1。",
	["@fcj_leixiSlash-onecard"] = "[雷袭-雷杀]你可以选择一张黑色手牌，将其当作一张雷【杀】使用",
	["~fcj_leixiSlash"] = "以此法使用的雷【杀】无距离限制",
	["@fcj_leixiDuel-zerocard"] = "[雷袭-决斗]你可以视为使用一张【决斗】",
	["~fcj_leixiDuel"] = "你以此法造成的伤害属性为雷电伤害",
	["fcj_leixi-pindian"] = "[雷袭-拼点]你可以选择一名其他角色，你们各摸一张牌后(你没手牌也得跟我拼)拼点",
	["fcj_leixi-damage"] = "[雷袭-直伤]你可以选择一名其他角色，直接对其造成1点雷电伤害",
	["$fcj_leixi1"] = "凌烟常忆张文远，逍遥常哭孙仲谋！",
	["$fcj_leixi2"] = "吾名如良药，可医吴儿夜啼！",
	  --阵亡
	["~fcj_shenzhangliao"] = "辽来，辽来！辽去，辽去......",

	--11 OL界赵云-自改版
	["fcb_oljiezhaoyun"] = "界赵云[FC]",
	["&fcb_oljiezhaoyun"] = "界赵云",
	["#fcb_oljiezhaoyun"] = "龙威虎将",
	["designer:fcb_oljiezhaoyun"] = "时光流逝FC",
	["cv:fcb_oljiezhaoyun"] = "官方",
	["illustrator:fcb_oljiezhaoyun"] = "原版精修",
	  --龙胆（OL界龙胆）
	  --涯角
	["fcbyajiao"] = "涯角",
	["fcbyajiaoequip"] = "涯角",
	["fcbyajiaoo"] = "涯角",
	[":fcbyajiao"] = "当你使用一张基本牌或【无懈可击】后，你可以展示牌堆顶的一张牌：若为基本牌，你获得之，然后可以将你的一张手牌（正面朝上）交给一名其他角色；" ..
	"若为锦囊牌，你可以弃置一名角色区域里的一张牌；若为装备牌，你可以令一名角色装备之（若其没有对应装备栏则改为获得之）。",
	["@fcbyajiao-card"] = "[涯角]你可以选择一张手牌并选择一名其他角色，将这张牌交予之",
	["@fcbyajiao-throw"] = "[涯角]你可以选择一名角色，弃置其区域里的一张牌",
	["fcbyajiaoEquipUse"] = "[涯角]你可以选择一名角色，其装备此【<font color='yellow'><b>%src</b></font>】",
	["$fcbyajiao1"] = "待敌需有略，孤勇岂可为？",
	["$fcbyajiao2"] = "天崩可寻路，海角誓相随！",
	  --阵亡
	["~fcb_oljiezhaoyun"] = "伐逆寇，兴汉室，吾难忘之......",

	--12 ☆SP赵云-自改版
	["fcb_starspzhaoyun"] = "☆SP赵云[FC]",
	["&fcb_starspzhaoyun"] = "☆SP赵云",
	["#fcb_starspzhaoyun"] = "白马少将",
	["designer:fcb_starspzhaoyun"] = "时光流逝FC",
	["cv:fcb_starspzhaoyun"] = "官方",
	["illustrator:fcb_starspzhaoyun"] = "绯雪工作室",
	  --龙胆（原版）
	  --(冲阵->)破阵
	["fcbpozhen"] = "破阵",
	[":fcbpozhen"] = "当你发动“龙胆”时，你可以弃置对方的一张牌或摸一张牌。\
	<b>◆<font color='red'>操作提示：</font><font color='blue'>弹出卡牌选择窗口时，你可以点[取消]，则视为你选择摸牌。</font></b>",
	["$fcbpozhen1"] = "一人一枪一匹马，疆场尽驰骋！", --弃牌
	["$fcbpozhen2"] = "为将者，自当尽忠尽职！", --摸牌
	  --阵亡
	["~fcb_starspzhaoyun"] = "这次，有负主公所托了......",
	
	--13 界吕布-主公版
	["fcb_lordjielvbu"] = "界吕布[FC]",
	["&fcb_lordjielvbu"] = "界吕布",
	["#fcb_lordjielvbu"] = "天下无双",
	["designer:fcb_lordjielvbu"] = "时光流逝FC",
	["cv:fcb_lordjielvbu"] = "官方",
	["illustrator:fcb_lordjielvbu"] = "魔奇士",
	  --无双（原版）
	  --魔戟
	["fcbmoji"] = "魔戟",
	["FcbMoji"] = "魔戟",
	[":fcbmoji"] = "锁定技，当你的装备区里没有武器牌时，你的初始攻击范围改为4。",
	["__fcb_moji"] = "魔戟",
	--[":__fcb_moji"] = "装备牌·武器<br /><b>攻击范围</b>：４",
	  --猛冠（战神·吕布的“猛冠”即是从这里搬过去的）
	  --神武
	["fcbshenwu"] = "神武",
	[":fcbshenwu"] = "主公技，其他群势力角色的出牌阶段限一次，可以交给你一张【杀】、【决斗】或武器牌。",
	["$fcbshenwu1"] = "不论何求，来者不拒！",
	["$fcbshenwu2"] = "既受其利，自要依言而行！",
	["fcbshenwuVS"] = "神武送牌",
	["fcbshenwuvs"] = "神武送牌",
	[":fcbshenwuVS"] = "出牌阶段限一次，你可以将你的一张【杀】、【决斗】或武器牌交给一名有<font color='red'><b>主公技</b></font>“神武”的其他角色。",
	["$fcbshenwuVS1"] = "",
	["$fcbshenwuVS2"] = "",
	  --阵亡
	["~fcb_lordjielvbu"] = "人，无信不立；吾，悔之晚矣......",
	
	--14 SP公孙瓒-主公版
	["fcb_lordspgongsunzan"] = "SP公孙瓒[FC]",
	["&fcb_lordspgongsunzan"] = "SP公孙瓒",
	["#fcb_lordspgongsunzan"] = "白马！",
	["designer:fcb_lordspgongsunzan"] = "时光流逝FC",
	["cv:fcb_lordspgongsunzan"] = "官方",
	["illustrator:fcb_lordspgongsunzan"] = "Vincent",
	  --义从
	["fcbyicong"] = "义从",
	[":fcbyicong"] = "锁定技，你与其他角色的距离-1；其他角色与你的距离+1。",
	  --高楼
	["fcbgaolou"] = "高楼",
	[":fcbgaolou"] = "主公技，锁定技，你每使用一张装备牌，摸一张牌，且若你使用的牌为防具，回复1点体力；你的手牌上限+X（X为装备区里有防具牌的其他存活群势力角色数+1）。",
	["$fcbgaolou1"] = "避敌锋芒，以守为攻！",
	["$fcbgaolou2"] = "义之所至，生死相随！",
	  --阵亡
	["~fcb_lordspgongsunzan"] = "魂断高楼陨易京，此身犹望守龙城......",
	----



	--FC·SP神诸葛亮
	["sp_shenzhugeliang_ub"] = "SP神诸葛亮[FC]",
	["&sp_shenzhugeliang_ub"] = "☆SP神诸葛亮",
	["#sp_shenzhugeliang_ub"] = "七星诛邪",
	["designer:sp_shenzhugeliang_ub"] = "时光流逝FC",
	["cv:sp_shenzhugeliang_ub"] = "极略三国,官方",
	["illustrator:sp_shenzhugeliang_ub"] = "极略三国",
	  --妖智
	["sp_yaozhi_ub"] = "妖智",
	["sp_yaozhi_ubX"] = "妖智",
	["sp_yaozhi_ubAddandClear"] = "妖智",
	[":sp_yaozhi_ub"] = "出牌阶段开始时，你可以“观星”X-1。<font color='green'><b>出牌阶段限X次，</b></font>你可以加1点体力上限，" ..
	"从牌堆顶展示一张牌并获得之，然后将你的一张牌交给一名角色。然后你可以减1点体力上限，将其一张牌置于其武将牌上，称为“神咒”。" ..
	"（X初始为3；此阶段结束时，若你于此阶段以此法获得的牌至少满足一项：1.都是同类型牌且至少获得了X张；2.基本牌/锦囊牌/装备牌至少各一张，你令本局游戏X+1）",
	["sp_yaozhi_ub:sp_yaozhi_ubGX"] = "[妖智]你可以“观星”%src张牌",
	["sp_yaozhi_ubUsed"] = "妖智",
	["sp_yaozhi_ubAdd"] = "妖智次数+",
	["sp_yaozhi_ub_giveCard"] = "请选择一名角色，交给其一张牌",
	["#sp_yaozhi_ub"] = "请选择一张牌交给 %src",
	["sp_yaozhi_ub_putGodIncantation"] = "你可以将其一张牌置于其武将牌上，称为“神咒”",
	["GodIncantation_ub"] = "神咒",
	["$sp_yaozhi_ub1"] = "星辰之力，助我灭敌！",
	["$sp_yaozhi_ub2"] = "七星不灭，法力不竭！",
	  --神启
	["sp_shenqi_ub"] = "神启",
	[":sp_shenqi_ub"] = "限定技，出牌阶段，你减Y点体力上限并选择一名武将牌上有“神咒”的角色（X为其“神咒”数），移除其所有“神咒”，选择一项：\
	<font color='red'><b>[行正]</b></font>令其摸Y/2张牌(向上取整)并回复Y/2点体力(向下取整)；\
	<font color='purple'><b>[诛邪]</b></font>对其造成Y点普通或属性(火/雷/冰/毒)伤害。\
	<font color='blue'><b>◆操作提示：要保证自己体力上限不会减为0，否则会终止后续结算。</b></font>",
	["@sp_shenqi_ub"] = "神启",
	["sp_shenqi_ub:1"] = "行正：令其摸牌并回复体力",
	["sp_shenqi_ub:2"] = "诛邪：对其造成伤害",
	["sp_shenqi_ub_zhuxie"] = "神启-诛邪",
	["sp_shenqi_ub_zhuxie:normal"] = "普通伤害",
	["sp_shenqi_ub_zhuxie:fire"] = "火焰伤害",
	["sp_shenqi_ub_zhuxie:thunder"] = "雷电伤害",
	["sp_shenqi_ub_zhuxie:ice"] = "冰冻伤害",
	["sp_shenqi_ub_zhuxie:poison"] = "毒素伤害",
	["$sp_shenqi_ub1"] = "起星辰之力，佑我蜀汉！", --行正
	["$sp_shenqi_ub2"] = "伏望天恩，誓讨汉贼！", --诛邪
	  --阵亡
	["~sp_shenzhugeliang_ub"] = "今当远离，临表涕零，不知...所言....",

	--祢衡
	["mb_miheng"] = "祢衡[FC]", --官方版本是涉及到了出牌时间的
	["&mb_miheng"] = "祢衡",
	["#mb_miheng"] = "鸷鹗啄孤凤",
	["designer:mb_miheng"] = "官方",
	["cv:mb_miheng"] = "官方",
	["illustrator:mb_miheng"] = "Thinking",
	  --狂才
	["mbkuangcai"] = "狂才",
	["mbkuangcaiBuff"] = "狂才",
	["mbkuangcaiCardBuff"] = "狂才",
	[":mbkuangcai"] = "出牌阶段开始时，你可以拥有5枚“狂才”标记(你至多有5枚)。若你有“狂才”标记，你使用牌无距离和次数限制，且当你于此阶段内使用牌时，你摸一张牌并弃置1枚“狂才”标记。" ..
	"当你以此法失去最后1枚“狂才”标记时，你结束此阶段；出牌阶段结束时，你清空所有“狂才”标记。",
	["$mbkuangcai1"] = "博古揽今，信手拈来。",
	["$mbkuangcai2"] = "功名为尘，光阴为金。",
	  --阵亡
	["~mb_miheng"] = "这天地都容不下我.....",


	["f_shenguojia"] = "界·神郭嘉[FC]",
	["&f_shenguojia"] = "界神郭嘉",
	["#f_shenguojia"] = "星月奇佐",
	["designer:f_shenguojia"] = "黑稻子,官方,时光流逝FC",
	["cv:f_shenguojia"] = "官方",
	["illustrator:f_shenguojia"] = "木美人,紫髯的小乔",
	--慧识（界）
	["f_huishi"] = "慧识",
	[":f_huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以进行判定：若结果与此阶段内以此法进行判定的结果的花色均不同且此时你的体力上限小于10，你可以重复此流程并<font color=\"#00CCFF\"><b>选择</b></font>加1点体力上限<font color=\"#00CCFF\"><b>或回复1点体力</b></font>，否则你终止判定。" ..
	"所有流程结束后，你可以将所有判定牌交给一名角色。然后若<font color=\"#00CCFF\"><b>你</b></font>手牌数为全场最多，你须<font color=\"#00CCFF\"><b>选择</b></font>减1点体力上限<font color=\"#00CCFF\"><b>或失去1点体力</b></font>。",
	["HandcarddataHS"] = "慧识",
	["@f_huishiAdd"] = "慧识",
	["@f_huishiAdd:mhp"] = "加1点体力上限",
	["@f_huishiAdd:hp"] = "回复1点体力",
	["@f_huishi_continue"] = "[慧识]你可以继续判定",
	["f_huishi-give"] = "请将所有判定牌交给一名角色",
	["@f_huishiLose"] = "慧识",
	["@f_huishiLose:mhp"] = "减1点体力上限",
	["@f_huishiLose:hp"] = "失去1点体力",
	["$f_huishi1"] = "聪以知远，明以察微。",
	["$f_huishi2"] = "见微知著，识人心智。",
	["~f_shenguojia"] = "可叹桢干命也迂..........",

	--神荀彧(手杀)-->界限突破
	["f_shenxunyu"] = "界·神荀彧[FC]",
	["&f_shenxunyu"] = "界神荀彧",
	["#f_shenxunyu"] = "洞心先识",
	["designer:f_shenxunyu"] = "官方,时光流逝FC",
	["cv:f_shenxunyu"] = "官方",
	["illustrator:f_shenxunyu"] = "枭瞳,紫髯的小乔",
	  --天佐（原测试版）
	["f_tianzuo"] = "天佐",
	[":f_tianzuo"] = "游戏开始时，你将八张【奇正相生】洗入牌堆。。" ..
	"<font color=\"#FFCC00\"><b>当有一名角色成为【奇正相生】的目标时，你可以查看其手牌，然后为其重新指定“正兵”或“奇兵”；</b></font>" ..
	"【奇正相生】对你无效。",
	["zhengbing"] = "指定为“正兵”",
	["qibing"] = "指定为“奇兵”",
	["$f_tianzuo1"] = "此时进之多弊，守之多利，愿主公熟虑。",
	["$f_tianzuo2"] = "主公若不时定，待四方生心，则无及矣！",

	["f_lingce"] = "灵策",
	[":f_lingce"] = "锁定技，一名角色使用智囊牌名的锦囊牌([官方]:<s>无中生有/</s>过河拆桥/无懈可击;<font color=\"#FFCC00\"><b>[三十六计]:借刀杀人/无中生有/顺手牵羊/铁索连环</b></font>)、“定汉”已记录的牌名或【奇正相生】时，你摸一张牌。",
	["$f_lingce1"] = "绍士卒虽众，其实难用，必无为也！",
	["$f_lingce2"] = "袁军不过一盘砂砾，主公用奇则散！",

	--神孙策(手杀)-->界限突破
	["f_shensunce"] = "界·神孙策[FC]",
	["&f_shensunce"] = "界神孙策",
	["#f_shensunce"] = "踞江鬼雄",
	["designer:f_shensunce"] = "官方,时光流逝FC",
	["cv:f_shensunce"] = "官方",
	["illustrator:f_shensunce"] = "枭瞳,紫髯的小乔",
	  --英霸（界）
	["imba"] = "英霸",
	["imbaMaxDistance"] = "英霸",
	["imbaNoLimit"] = "英霸",
	[":imba"] = "出牌阶段限一次，你可以选择一名体力上限大于1的其他角色，令其减1点体力上限并获得1枚“平定”标记，然后你减1点体力上限。你对拥有“平定”标记的角色使用牌无距离限制<font color=\"#FF0066\"><b>且次数+X</b></font>（X为其拥有的“平定”标记数）。",
	["PingDing"] = "平定",
	["$imba1"] = "卧榻之侧，岂容他人酣睡！",
	["$imba2"] = "从我者可免，拒我者难容！",
	  --覆海
	["f_fuhai"] = "覆海",
	[":f_fuhai"] = "锁定技，当你对拥有“平定”标记的角色使用牌时，你令其不能响应此牌且你摸一张牌（每回合限摸两次）。拥有“平定”标记的角色死亡时，你加X点体力上限并摸X张牌。",
	["f_fuhaiDraw"] = "",
	["$f_fuhai1"] = "翻江覆蹈海，六合定乾坤！",
	["$f_fuhai2"] = "力攻平江东，威名扬天下！",
	["$f_fuhai3"] = "平定三郡，稳踞江东！！", --拥有“平定”标记的角色死亡
	  --冯河（界）
	["f_pinghe"] = "冯河",
	["f_pingheDefuseDamage"] = "冯河",
	["f_pinghedefusedamage"] = "冯河",
	["f_pingheAudio"] = "冯河",
	[":f_pinghe"] = "锁定技，你的手牌上限等于你已损失的体力值。当你受到其他角色造成的伤害时，若你有手牌且体力上限大于1，防止本次伤害，然后你减1点体力上限并将一张手牌交给一名其他角色，然后若你拥有“英霸”，令伤害来源获得1枚“平定”标记。" ..
	"<font color=\"#FF0066\"><b>锁定技，当你回复体力后，若你的体力值大于1，你失去1点体力，然后摸Y张牌（Y为你此时的体力值数）。</b></font>",
	["@f_pingheDefuseDamage-card"] = "请选择一名其他角色，交给其一张手牌",
	["~f_pingheDefuseDamage"] = "优先给队友好牌，如果没有队友则给对手废牌或卡对手手牌",
	["$f_pinghe1"] = "只可得胜而返，岂能败战而归？！",
	["$f_pinghe2"] = "不过胆小鼠辈，吾等有何惧哉？！",
	  --阵亡
	["~f_shensunce"] = "无耻小人，胆敢暗算于我！......",

	--神马超(新杀)-->界限突破
	["ty_shenmachao"] = "界·神马超[FC]",
	["&ty_shenmachao"] = "界神马超",
	["#ty_shenmachao"] = "神威天将军",
	["designer:ty_shenmachao"] = "官方",
	["cv:ty_shenmachao"] = "官方",
	["illustrator:ty_shenmachao"] = "君桓文化",
	  --狩骊（真·猎马）（界）
	["tyshouliGMS"] = "狩骊",
	["tyshouli"] = "狩骊",
	["tyshoulii"] = "狩骊",

	[":tyshouli"] = "锁定技，<font color='red'><b>每轮开始时，</b></font>" ..
	"从下家开始所有角色依次从牌堆<font color='red'><b>和弃牌堆</b></font>中随机使用一张坐骑牌直到牌堆<font color='red'><b>和弃牌堆</b></font>中没有坐骑牌。" ..
	"当你需要使用或打出【杀】/【闪】时，你可获得场上的一张进攻马/防御马，并立即将该牌当做【杀】（不计次）/【闪】使用或打出" ..
	"且获得此牌时，失去该坐骑的角色本回合非锁定技失效，你与失去该坐骑的角色本回合受到的伤害+1且改为雷电伤害。",
	["$tyshoulida"] = "%arg 受到的伤害因 %arg2 由 %arg3 点增加到了 %arg4 点并改为了雷电伤害。",
	["$tyshouli1"] = "赤骊骋疆，巡狩八荒！", --送马；猎进攻马
	["$tyshouli2"] = "长缨在手，百骥可降！", --送马；猎防御马
	["$tyshouli3"] = "敢缚苍龙擒猛虎，一枪纵横定天山！", --用马当杀；触发增伤
	["$tyshouli4"] = "马踏祁连山河动，兵起玄黄奈何天！", --用马当闪；触发增伤
	  --阵亡
	["~ty_shenmachao"] = "离群之马，虽强亦亡......", --七情难言，六欲难消，何谓之神......


	--神典韦(新杀-限时地主/魔改)
	["ty_shendianwei"] = "神典韦[FC]",
	["&ty_shendianwei"] = "神典韦",
	["#ty_shendianwei"] = "襢裼暴虎",
	["designer:ty_shendianwei"] = "Walker(源自“飞鸿印雪”)",
	["cv:ty_shendianwei"] = "官方",
	["illustrator:ty_shendianwei"] = "君桓文化,紫髯的小乔",
	  --地主之魂
	  --捐甲
    ["tyjuanjia"] = "捐甲",
	["tyjuanjiaGMS"] = "捐甲",
	["tyjuanjia_equiparea"] = "捐甲",
    [":tyjuanjia"] = "锁定技，游戏开始时，废除你的防具栏，然后你获得一个<font color='blue'><s>额外</s></font><font color='red'><b>特殊</b></font>的" ..
	"<font color='red'><b>(被称为“捐甲”的)</b></font>武器<font color='blue'><s>栏</s></font><font color='red'><b>区域</b></font>" ..
	"<font color='orange'><b>(用法:只能容纳一张武器牌,你视为装备置入该区域的武器牌;出牌阶段,你可以<font color='green'><b>点击武将头像左上角的“捐甲”按钮</b></font>," ..
	"选择手牌中的一张武器牌置入该区域(若该区域已有牌,则替代))</b></font>。",
	["@tyjuanjia_equiparea"] = "“捐甲”区",
	["$tyjuanjia_getJJea"] = "%from 获得了一个特殊的武器区域【<font color='yellow'><b>捐甲</b></font>】",
	[":tyjuanjia_equiparea"] = "出牌阶段，你可以<font color='green'><b>点击此按钮</b></font>，选择手牌中的一张武器牌置入“捐甲”区(若此区域已有牌，则替代)。",
	["$tyjuanjia1"] = "善攻者弃守，其提双刃，斩万敌！",
	["$tyjuanjia2"] = "舍衣事力，提兵驱敌！",
	  --挈挟
    ["tyqiexie"] = "挈挟",
	["tyqiexieRemover"] = "挈挟",
    [":tyqiexie"] = "锁定技，准备阶段，你在剩余武将牌堆中随机观看五张武将牌，然后依次选择其中<font color='red'><b>总计X张牌(X为2.若你没有武器栏,X-1;若你没有“捐甲”区,X-1)，将对应的(被称为“挈挟”的)武器牌依次置入你的：1.武器栏；2.“捐甲”区</b></font>。" ..
	"以此法获得的“挈挟”武器牌拥有如下规则：\
	1.无花色与点数且攻击范围为武将牌上的体力上限<font color='red'><b>(至多为5)</b></font>；\
	2.武器效果为武将牌上描述中含有“【杀】”的无类型标签或仅有锁定技标签的技能；\
	3.此牌离开你的装备区<font color='red'><b>或“捐甲”区</b></font>时，你令其销毁。",
    [":tyqiexie1"] = "锁定技，准备阶段，你在剩余武将牌堆中随机观看五张武将牌，然后依次选择其中<font color='red'><b>总计X张牌(X为2.若你没有武器栏,X-1;若你没有“捐甲”区,X-1)，将对应的(被称为“挈挟”的)武器牌依次置入你的：1.武器栏；2.“捐甲”区</b></font>。" ..
	"以此法获得的“挈挟”武器牌拥有如下规则：\
	1.无花色与点数且攻击范围为武将牌上的体力上限<font color='red'><b>(至多为5)</b></font>；\
	2.武器效果为武将牌上描述中含有“【杀】”的无类型标签或仅有锁定技标签的技能；\
	3.此牌离开你的装备区<font color='red'><b>或“捐甲”区</b></font>时，你令其销毁。\
	挈挟[装备区]: %arg1 \
	挈挟[“捐甲”区]: %arg2",
	--【挈挟】--
	--攻击范围1
	["_weapon_qiexie_one"] = "挈挟[1]",
	["WeaponQiexieOne"] = "挈挟[1]",
	["weaponqiexieone"] = "挈挟[1]",
	[":_weapon_qiexie_one"] = "装备牌·武器<br /><b>攻击范围</b>：１\
	<br /><b>武器技能</b>：\
	1.无花色与点数且攻击范围为对应因缘武将牌上的体力上限(至多为5)；\
	2.武器效果为对应因缘武将牌上描述中含有“【杀】”的：无类型标签或仅有锁定技标签的技能(新杀)/除觉醒技、限定技、转换技、主公技之外的技能(OL)；\
	3.离开装备区或“捐甲”区时销毁。",
	--攻击范围2
	["_weapon_qiexie_two"] = "挈挟[2]",
	["WeaponQiexieTwo"] = "挈挟[2]",
	["weaponqiexietwo"] = "挈挟[2]",
	[":_weapon_qiexie_two"] = "装备牌·武器<br /><b>攻击范围</b>：２\
	<br /><b>武器技能</b>：\
	1.无花色与点数且攻击范围为对应因缘武将牌上的体力上限(至多为5)；\
	2.武器效果为对应因缘武将牌上描述中含有“【杀】”的：无类型标签或仅有锁定技标签的技能(新杀)/除觉醒技、限定技、转换技、主公技之外的技能(OL)；\
	3.离开装备区或“捐甲”区时销毁。",
	--攻击范围3
	["_weapon_qiexie_three"] = "挈挟[3]",
	["WeaponQiexieThree"] = "挈挟[3]",
	["weaponqiexiethree"] = "挈挟[3]",
	[":_weapon_qiexie_three"] = "装备牌·武器<br /><b>攻击范围</b>：３\
	<br /><b>武器技能</b>：\
	1.无花色与点数且攻击范围为对应因缘武将牌上的体力上限(至多为5)；\
	2.武器效果为对应因缘武将牌上描述中含有“【杀】”的：无类型标签或仅有锁定技标签的技能(新杀)/除觉醒技、限定技、转换技、主公技之外的技能(OL)；\
	3.离开装备区或“捐甲”区时销毁。",
	--攻击范围4
	["_weapon_qiexie_four"] = "挈挟[4]",
	["WeaponQiexieFour"] = "挈挟[4]",
	["weaponqiexiefour"] = "挈挟[4]",
	[":_weapon_qiexie_four"] = "装备牌·武器<br /><b>攻击范围</b>：４\
	<br /><b>武器技能</b>：\
	1.无花色与点数且攻击范围为对应因缘武将牌上的体力上限(至多为5)；\
	2.武器效果为对应因缘武将牌上描述中含有“【杀】”的：无类型标签或仅有锁定技标签的技能(新杀)/除觉醒技、限定技、转换技、主公技之外的技能(OL)；\
	3.离开装备区或“捐甲”区时销毁。",
	--攻击范围5
	["_weapon_qiexie_five"] = "挈挟[5]",
	["WeaponQiexieFive"] = "挈挟[5]",
	["weaponqiexiefive"] = "挈挟[5]",
	[":_weapon_qiexie_five"] = "装备牌·武器<br /><b>攻击范围</b>：５\
	<br /><b>武器技能</b>：\
	1.无花色与点数且攻击范围为对应因缘武将牌上的体力上限(至多为5)；\
	2.武器效果为对应因缘武将牌上描述中含有“【杀】”的：无类型标签或仅有锁定技标签的技能(新杀)/除觉醒技、限定技、转换技、主公技之外的技能(OL)；\
	3.离开装备区或“捐甲”区时销毁。",
	-----
	["$tyqiexie1"] = "今挟双戟搏战，定护主公太平！",
	["$tyqiexie2"] = "吾乃典韦是也，谁敢向前？谁敢向前！",
	  --摧决
    ["tycuijue"] = "摧决",
    [":tycuijue"] = "<font color='green'><b>每个回合对每名角色限一次，</b></font>出牌阶段，你可以弃置一张牌，然后对一名在你攻击范围内且距离你最远的其他角色造成1点伤害。",
	["$tycuijue1"] = "当锋摧决，贯瑕洞坚！",
	["$tycuijue2"] = "殒身不恤，死战成仁！",
	  --阵亡
	["~ty_shendianwei"] = "战死沙场，快哉快哉！......",


	  --威力加强版
	["wx_shenzhugeliangEX"] = "界·神诸葛亮[FC]",
	["&wx_shenzhugeliangEX"] = "神诸葛亮",
	["#wx_shenzhugeliangEX"] = "赤壁的大神",
	["designer:wx_shenzhugeliangEX"] = "时光流逝FC",
	["cv:wx_shenzhugeliangEX"] = "官方",
	["illustrator:wx_shenzhugeliangEX"] = "小程序精修",
	  --七星
	["wxqixingEX"] = "七星",
	[":wxqixingEX"] = "每轮限一次，当你处于濒死状态时，你可以进行判定：若判定点数大于7，你回复至1点体力。",
	["$wxqixingEX1"] = "斗转星移，七星借命！", --观星唤雨
	["$wxqixingEX2"] = "七星不灭，法力不绝！", --孟章诛邪
	  --祭风
	["wxjifengEX"] = "祭风",
	["wxjifengex"] = "祭风",
	["wxjifengEX_zuiandfa"] = "祭风",
	[":wxjifengEX"] = "<font color='green'><b>出牌阶段限X+1次，</b></font>你可以弃置一张手牌，从牌堆（若牌堆中没有，则改为弃牌堆）随机获得一张锦囊牌。" ..
	"（X为出牌阶段开始时你的“罪”标记数与“罚”标记数之和）",
	["wxjifengEX_add"] = "祭风次数+",
	["$wxjifengEX1"] = "东风生，旗幡动！", --剑祭通天
	["$wxjifengEX2"] = "狂风起，江水腾！", --剑祭通天
	  --天罪
	["wxtianzuiEX"] = "天罪",
	["wxtianzuiex"] = "天罪",
	[":wxtianzuiEX"] = "出牌阶段，你使用第奇数张锦囊牌时，你获得1枚“罪”标记（“罪”标记持续至下个出牌阶段开始时）；" ..
	"回合结束时，你可以弃置至多Y名其他角色各一张区域内的牌（Y为你的“罪”标记数）。",
	["exZUI"] = "罪",
	["@wxtianzuiEX-card"] = "你可以选择数量至多为你“罪”标记数的其他角色，弃置他们区域内各一张牌",
	["~wxtianzuiEX"] = "汝罪之大，似彻天之山、盈渊之海！",
	["$wxtianzuiEX1"] = "借天风，浴业火，可破万敌！", --合纵破曹 --叠标记
	["$wxtianzuiEX2"] = "星辰之力，助我灭敌！", --极略三国SP神诸葛亮“妖智” --拆人
	  --天罚
	["wxtianfaEX"] = "天罚",
	["wxtianfaex"] = "天罚",
	[":wxtianfaEX"] = "出牌阶段，你使用第偶数张锦囊牌时，你获得1枚“罚”标记（“罚”标记持续至下个出牌阶段开始时）；" ..
	"回合结束时，你可以对至多Z名其他角色各造成1点雷电伤害（Z为你的“罚”标记数）。",
	["exFA"] = "罚",
	["@wxtianfaEX-card"] = "你可以对数量至多为你“罚”标记数的其他角色各造成1点雷电伤害",
	["~wxtianfaEX"] = "请叫我：罪罚哥",
	["$wxtianfaEX1"] = "星象为我控，七星握掌中！", --合纵破曹 --叠标记
	["$wxtianfaEX2"] = "七星八阵，敌军将困！", --孟章诛邪 --砸人
	--
	["wx_ZUIandFA"] = "罪与罚",
	  --阵亡
	["~wx_shenzhugeliangEX"] = "时也，命也......", --孟章诛邪




	--FC谋黄忠
	["fc_mou_huangzhong"] = "谋黄忠[FC]",
	["&fc_mou_huangzhong"] = "☆谋黄忠",
	["#fc_mou_huangzhong"] = "丹心见苍天",
	["designer:fc_mou_huangzhong"] = "时光流逝FC",
	["cv:fc_mou_huangzhong"] = "屠洪刚",
	["illustrator:fc_mou_huangzhong"] = "屠洪刚",
	  --烈弓
	["fcmouliegong"] = "烈弓",
	["fcmouliegong_one"] = "烈弓",
	["fcmouliegong_two"] = "烈弓",
	["fcmouliegong_threemore"] = "烈弓",
	[":fcmouliegong"] = "当你使用或打出牌后，若此牌的花色未被“烈弓”记录，你记录此种花色，否则你摸一张牌（每轮每种花色限触发一次以此法摸牌）。若你以此法已记录的花色数至少为：\
    <font color=\"#66FF66\">1，你的【杀】可以选择此【杀】点数距离内的角色为目标；</font>\
    <font color=\"#00CCFF\">2，你的【杀】不可被响应；</font>\
    <font color='purple'>3，你的【杀】伤害+1；</font>\
    <font color='orange'>4，你的【杀】根据其点数造成伤害时有概率暴击<b>(概率表：A-12%,K-60%,每多一点加4%)</b>，且若暴击成功，你清除所有已记录的花色并失去1点体力。</font>\
    你使用的【杀】结算结束后，你移除与此【杀】相同花色的记录。",
	["fcmouliegongheartDrawed_lun"] = "",
	["fcmouliegongdiamondDrawed_lun"] = "",
	["fcmouliegongclubDrawed_lun"] = "",
	["fcmouliegongspadeDrawed_lun"] = "",
	["$fcmouliegongCriticalHit"] = "<font color='red'><b>丹心见苍天</b></font>！%from 对 %to <font color='orange'><b>暴击</b></font>，此【<font color='yellow'>杀</b></font>】<font color='yellow'>伤害翻倍</b></font>！",
	["$fcmouliegong1"] = "黄忠将近古稀年，犹开弯弓射月满；众人笑我我不言，背朝尔等喝牙官。", --游戏开始
	["$fcmouliegong2"] = "抬宝刀，备宝鞍，随我纵马定军山；西风烈，吹长髯，须发如雪铁甲玄。", --当轮每种花色皆触发一次摸牌
	["$fcmouliegong3"] = "头通鼓，战饭造", --记录至1种花色
	["$fcmouliegong4"] = "二通鼓，紧战袍", --记录至2种花色
	["$fcmouliegong5"] = "三通鼓，刀出鞘", --记录至3种花色
	["$fcmouliegong6"] = "四通鼓，把兵交", --记录至4种花色
	["$fcmouliegong7"] = "定军山！大丈夫舍身不问年；百战余勇，我以丹心见苍天！", --出杀后记录有花色
	["$fcmouliegong8"] = "定军山！念人生如同雕翎箭；来去如烟，唯有恩义不离弦！", --出杀后记录有花色
	["$fcmouliegong9"] = "丹心见苍天！今日换余年！", --暴击
	["$fcmouliegong10"] = "定军山！我愿以今日换余年，也当回报平生知遇汉王前！", --通过发动技能使得目标死亡
	  --☠️阵亡
	["~fc_mou_huangzhong"] = "定军山！待到那灯火满长安，征衣轻弹拜见我一统江山......",



	--FC谋关羽
	["fc_mou_guanyu"] = "谋关羽[FC]",
	["&fc_mou_guanyu"] = "☆谋关羽",
	["#fc_mou_guanyu"] = "名传千古",
	["designer:fc_mou_guanyu"] = "时光流逝FC",
	["cv:fc_mou_guanyu"] = "官方",
	["illustrator:fc_mou_guanyu"] = "白",
	  --武圣
	["fcmouwusheng"] = "武圣",
	["fcmouwushengDiamond"] = "武圣",
	["fcmouwushengHeart"] = "武圣",
	[":fcmouwusheng"] = "你可以将一张红色牌当【杀】使用或打出；你使用方块【杀】无距离限制、红桃【杀】伤害+1。",
	["$fcmouwusheng1"] = "青龙知酒温，饮尽贼酋血！",
	["$fcmouwusheng2"] = "刀饮青龙血，马踏佞鬼魂！",
	  --义绝
	["fcmouyijue"] = "义绝",
	["fcmouyijueBuffANDClear"] = "义绝",
	[":fcmouyijue"] = "出牌阶段限一次，你可以弃置一张牌，与一名其他角色进行“谋弈”：\
	<font color='red'><b>成功</b></font>：该角色视为被你“义绝”（非锁定技失效、不能使用或打出手牌、你使用红色【杀】对其造成的伤害+1）直到回合结束；\
	<font color='black'><b>失败</b></font>：你展示该角色区域里的一张牌并获得之，然后你可以令其回复1点体力。",
	["@MouYi-yijue"] = "谋弈：义绝",
	["@MouYi-yijue:F1"] = "威震华夏，红牌当杀",
	["@MouYi-yijue:F2"] = "无名小卒，一轮八十牌",
	["@MouYi-yijue:T1"] = "威震华夏，义薄云天",
	["@MouYi-yijue:T2"] = "无名小卒，被无双万军取首",
	["$MouYi_success"] = "%from 对 %to <font color='yellow'><b>谋弈</b></font> <font color='red'><b>成功</b></font>！",
	["$MouYi_fail"] = "%from 对 %to <font color='yellow'><b>谋弈</b></font> <font color='blue'><b>失败</b></font>",
	["@fcmouyijue-Recover"] = "[义绝]令其回复体力",
	["$fcmouyijue1"] = "降汉不降曹，斩佞不斩忠！", --谋弈
	["$fcmouyijue2"] = "心念桃园兄弟义，不背屯土忠君誓！", --谋弈
	["$fcmouyijue3"] = "青龙嬉江海，虎将破敌酋！", --增伤
	["$fcmouyijue4"] = "黯云从龙，啸风从虎！", --增伤
	  --☠️阵亡
	["~fc_mou_guanyu"] = "哈哈哈哈哈哈哈哈哈！有死而已，何必多言。",

	--谋马超->谋马超-威力加强版
	["mou_machaoo"] = "谋马超[FC]",
	["&mou_machaoo"] = "谋马超",
	["#mou_machaoo"] = "阻戎负勇",
	["designer:mou_machaoo"] = "时光流逝FC",
	["cv:mou_machaoo"] = "官方",
	["illustrator:mou_machaoo"] = "佚名",
	  --马术（-1马）
	  --铁骑
	["fcmoutieqii"] = "铁骑",
	["fcmoutieqiiDC"] = "铁骑",
	[":fcmoutieqii"] = "当你使用【杀】指定一名角色为目标时，你可以令其非锁定失效直到回合结束，且其不能使用【闪】响应此【杀】，然后你与其进行“谋弈”：\
	<b>直取敌营</b>：若成功，你获得其一张牌<font color='red'><b>，且此【杀】对其造成的伤害+1</b></font>；\
	<b>扰阵疲敌</b>：若成功，你摸两张牌<font color='red'><b>，然后收回此【杀】</b></font>。",
	["@MouYi-tieqi"] = "谋弈：铁骑",
	["@MouYi-tieqi:F1"] = "直取敌营(获得目标的一张牌)",
	["@MouYi-tieqi:F2"] = "扰阵疲敌(摸两张牌)",
	["@MouYi-tieqi:T1"] = "拱卫中军(防止对手获得你的牌)",
	["@MouYi-tieqi:T2"] = "出阵迎战(防止对手摸牌)",
	["$MouYi-tieqi_successDMG"] = "因为 %from 对 %to <font color='yellow'><b>直取敌营</b></font> <font color='red'><b>成功</b></font>，" ..
	"此【%card】对 %to 造成的伤害将+1",
	["$fcmoutieqii1"] = "你可闪得过此一击！！", --锁技能+强命
	["$fcmoutieqii2"] = "厉兵秣马，只待今日！", --谋弈
	["$fcmoutieqii3"] = "敌军防备空虚，出击直取敌营！", --抢牌成功
	["$fcmoutieqii4"] = "敌军早有防备，先行扰阵疲敌！", --摸牌成功
	["$fcmoutieqii5"] = "全军速撤回营，以期再觅良机！", --谋弈失败
	  --☠️阵亡
	["~mou_machaoo"] = "父兄妻儿俱丧，吾有何面目活于世间......", --父亲！不能为汝报仇雪恨矣......

	--谋徐晃->谋徐晃-威力加强版
	["mou_xuhuangg"] = "谋徐晃[FC]",
	["&mou_xuhuangg"] = "谋徐晃",
	["#mou_xuhuangg"] = "径行截辎",
	["designer:mou_xuhuangg"] = "时光流逝FC",
	["cv:mou_xuhuangg"] = "官方",
	["illustrator:mou_xuhuangg"] = "佚名",
	  --断粮
	["mouduanliangg"] = "断粮",
	[":mouduanliangg"] = "出牌阶段限两次，你可以与一名其他角色进行“谋弈”：\
	<b>围城断粮</b>：若成功，你将牌堆顶的一张牌当无距离限制的【兵粮寸断】对其使用（若其判定区中已有【兵粮寸断】，则改为获得其一张牌）；\
	<b>擂鼓进军</b>：若成功，你视为对其使用一张【决斗】。",
	["@MouYi-duanliang"] = "谋弈：断粮",
	["@MouYi-duanliang:F1"] = "围城断粮(直接饿死你不多哔哔)",
	["@MouYi-duanliang:F2"] = "擂鼓进军(有本事就与老子单挑)",
	["@MouYi-duanliang:T1"] = "全军突击(防止对手断你粮草)",
	["@MouYi-duanliang:T2"] = "闭门守城(防止对手决斗你)",
	["mouduanliangv"] = "断粮",
	["$mouduanliangg1"] = "常读兵法，终有良策也！", --谋弈
	["$mouduanliangg2"] = "烧敌粮草，救主于危急！", --成功使用兵粮
	["$mouduanliangg3"] = "敌陷混乱之机，我军可长驱直入！", --成功发起决斗
	["$mouduanliangg4"] = "敌既识破吾计，则断不可行矣！", --谋弈失败
	  --势迫
	["moushipoo"] = "势迫",
	[":moushipoo"] = "结束阶段，你可以令一名体力值小于你的角色或所有判定区里有【兵粮寸断】的其他角色依次选择一项：" ..
	"1.交给你一张手牌；2.受到1点伤害。<font color='red'><b>若目标角色体力值小于你且判定区里有【兵粮寸断】，则改为依次执行两项。</b></font>" ..
	"若你以此法获得了牌，则你可以将其中任意张牌交给一名其他角色。",
	["moushipoo:1"] = "威胁一名体力比你少的角色",
	["moushipoo:2"] = "对所有判定区有【兵粮寸断】的其他角色发出宣告",
	["moushipoo:3"] = "交给其一张手牌",
	["moushipoo:4"] = "受到其对你造成的1点伤害",
	["moushipoo_KHxd"] = "请选择一名体力值小于你的角色",
	["#moushipoo"] = "请交给 %src 一张手牌",
	["@moushipoo-give"] = "[势迫]给牌",
	["moushipoo_givecards"] = "请选择一名其他角色，将你获得的这张牌交予之",
	["@moushipoo-card"] = "请选择任意张你获得的牌，交给一名其他角色",
	["~moushipoo"] = "点击你想交予的可被选择的牌，点【确定】",
	["$moushipoo1"] = "已向尔等陈明利害，奉劝尔等早日归降！", --威胁
	["$moushipoo2"] = "此时归降或可封赏，及至城破立斩无赦！", --宣告
	  --☠️阵亡
	["~mou_xuhuangg"] = "为主效劳，何畏生死......",

	--KJ谋夏侯霸
	["kj_mou_xiahouba"] = "谋夏侯霸[KJ]",
	["&kj_mou_xiahouba"] = "○谋夏侯霸",
	["#kj_mou_xiahouba"] = "来之坎坎",
	["designer:kj_mou_xiahouba"] = "小珂酱",--(卯兔包投稿)",
	["cv:kj_mou_xiahouba"] = "官方",
	["illustrator:kj_mou_xiahouba"] = "琛·美弟奇",
	  --试锋
	["kjmoushifeng"] = "试锋",
	[":kjmoushifeng"] = "魏势力技，每当你使用【闪】或【无懈可击】结算完毕后，你可以摸一张牌并视为使用一张无距离限制的【杀】（不计次），当此【杀】被【闪】响应后，你失去1点体力。",
	["@kjmoushifeng-tuodao"] = "你可以视为使用一张无距离限制的【杀】",
	["~kjmoushifeng"] = "副作用：如若此【杀】被【闪】回避，你将失去1点体力",
	["$kjmoushifeng1"] = "尔等，也配与本将军对阵？",
	["$kjmoushifeng2"] = "取你头颅，亦如探囊取物！",
	  --绝辗
	["kjmoujuezhan"] = "绝辗",
	[":kjmoujuezhan"] = "觉醒技，<font color='red'><b>回合开始前</b></font>或结束阶段开始时，若你的体力值为1或没有手牌，你回复1点体力或摸两张牌，然后将势力改为“蜀”。",
	["kjmoujuezhan:1"] = "回复1点体力",
	["kjmoujuezhan:2"] = "摸两张牌",
	--["$kjmoujuezhan1"] = "父亲在上，魂佑大汉(夏侯渊:?)；伯约在旁，智定天下！", --体力值为1觉醒
	["$kjmoujuezhan1"] = "丞相在上，魂佑大汉；伯约在旁，谋定天下！", --体力值为1觉醒
	["$kjmoujuezhan2"] = "先帝之志，丞相之托，不可忘也！", --没有手牌觉醒
	  --励进
	["kjmoulijin"] = "励进",
	["kjmoulijinMXC"] = "励进",
	[":kjmoulijin"] = "蜀势力技，回合开始时，若你已受伤，你可以选择并执行一个阶段，若你选择了：\
	○判定阶段，你弃置一名其他角色的至多X张牌（X为你已损失的体力值；弃牌时，点【取消】即中止弃牌流程）；\
	○摸牌阶段，你本回合手牌上限+1；\
	○出牌阶段，你从牌堆获得一张【杀】；\
	○弃牌阶段，你获得1点护甲。",
	["kjmoulijin:judge"] = "执行一个【判定阶段】",
	["kjmoulijin:draw"] = "执行一个【摸牌阶段】",
	["kjmoulijin:play"] = "执行一个【出牌阶段】",
	["kjmoulijin:discard"] = "执行一个【弃牌阶段】",
	["kjmoulijinTiaoXinS"] = "请选择一名其他角色，弃置其至多 %src 张牌",
	["$kjmoulijin1"] = "汝等小儿，可敢杀我？", --执行判定阶段
	["$kjmoulijin2"] = "屯粮事大，暂不与尔等计较。", --执行摸牌阶段
	["$kjmoulijin3"] = "老将虽白发，宝刀刃犹锋！", --执行出牌阶段
	["$kjmoulijin4"] = "勤学潜习，始觉自新。", --执行弃牌阶段
	  --☠️阵亡
	["~kj_mou_xiahouba"] = "终是..逃不过这一劫....呃......",
	--==作者的设计思路==--
	--[[基本思路（历史契合度）
	【试锋】夏侯霸虽是夏侯渊后代，初次上阵还是略显青涩，曹真任命其为先锋，作战不利，夏侯霸亲临阵前防御，所以将此时机设计为使用防御牌之后，并且可以看到父亲夏侯渊的影子，但却不那么从容。“杀”未造成伤害代表作战失败，而失去体力则体现了魏国朝廷对夏侯霸的排挤和打压，一步一步将夏侯霸推向悬崖边缘。
	【绝辗】顾名思义，在绝境中辗转，夏侯霸继续留在魏国必被小人所害，不得已而投降蜀国。
	【励进】夏侯霸的史料记载并不多，但我们可以看出他的一生并不安稳，夏侯霸在蜀汉连一个朋友也交不得，但却一点一滴得到晋升，正所谓“棘途壮志”——故将此技能发动限制设计为跟受伤有关，根据不同的情形采用不同的手段，体现人物处世机敏和智慧。
	※（设计彩蛋）：关于【励进】，我选择了众多与夏侯霸有着或多或少联系的武将作为参考：例如，判定阶段的效果对应蜀将姜维的挑衅弃牌，摸牌阶段对应钟会的手牌上限，出牌阶段的效果对应张飞的多刀，弃牌阶段我则是参考了游戏“真·三国无双”里夏侯霸的形象：有着不让其父的性格与异常年轻的容貌，因此以盔甲来掩饰。所以设计为增添护甲。
	※（一些思考）我曾想过在【试锋】中去掉“魏势力技，”这样这个武将的强度将获得提升，但我认为既然在魏国受到排挤投靠蜀国之后，就应当与以往一刀两断，最终放弃了这个想法。]]

	--FC谋姜维
	["fc_mou_jiangwei"] = "谋姜维[FC]",
	["&fc_mou_jiangwei"] = "☆谋姜维",
	["#fc_mou_jiangwei"] = "最后的汉臣", --“见危授命”
	["designer:fc_mou_jiangwei"] = "时光流逝FC",
	["cv:fc_mou_jiangwei"] = "官方", --谋姜维语音(主体,阵亡)+标姜维语音(衍生技)
	["illustrator:fc_mou_jiangwei"] = "鬼画符", --没用谋姜维原画，个人不太喜欢
	  --挑衅
	["fcmoutiaoxin"] = "挑衅",
	["fcmoutiaoxinStart"] = "挑衅",
	["fcmoutiaoxinTrigger"] = "挑衅",
	[":fcmoutiaoxin"] = "<b><font color='yellow'>蓄</font><font color='orange'>力</font><font color='red'>技</font>（<font color='red'>4</font>/<font color='red'>4</font>）</b>"..
	"，出牌阶段限一次，你可以获得技能“八阵”直到此阶段结束并选择至多X名其他角色（X为你拥有的蓄力点数），令这些角色依次选择一项：\
	1.对你使用一张无距离限制的【杀】，且若此【杀】被你的【闪】响应，你弃置其一张牌；\
	2.令你获得其一张牌。\
	然后你每选择一名角色，蓄力点就-1。弃牌阶段，你每弃置一张牌，蓄力点+1（不能超过上限）。",
	["@fcXuLi"] = "蓄力点",
	["fcXuLiMAX"] = "", --体现蓄力点上限的标记
	["tofcmouzhiji"] = "挑衅角色",
	--["fcmoutiaoxin:1"] = "对其使用一张【杀】（无距离限制）",
	--["fcmoutiaoxin:2"] = "令其获得你一张牌",
	["@fcmoutiaoxin-slash"] = "请对 %src 使用一张【杀】（无距离限制）",
	["$fcmoutiaoxin1"] = "汝等小儿，还不快跨马来战！",
	["$fcmoutiaoxin2"] = "哼！既匹夫不战，不如归耕陇亩！",
	  --志继
	["fcmouzhiji"] = "志继",
	[":fcmouzhiji"] = "觉醒技，准备阶段，若你发动“挑衅”选择过至少四名角色，你减1点体力上限，获得技能" ..
	"“<font color='purple'><b>妖智</b>(魂烈SP包-SP神诸葛亮<b>[作者:司马子元]</b>)</font>”、“<font color=\"#66FFFF\"><b>界妆神</b>(鬼包-界鬼诸葛亮<b>[作者:小珂酱]</b>)</font>”。",
	["$fcmouzhiji1"] = "丞相之志，维岂敢忘之！",
	["$fcmouzhiji2"] = "北定中原终有日！",
	--妖智(极略三国-SP神诸葛亮)
	["fcmzj_yaozhi"] = "妖智",
	[":fcmzj_yaozhi"] = "准备阶段，结束阶段，出牌阶段限一次，当你受到伤害后，你可以摸一张牌，然后从随机三个能在此时机发动的技能中选择一个并发动。",
	["#ZJYaozhiTempSkill"] = "%from 于此阶段可以发动技能“%arg”",
	["$fcmzj_yaozhi1"] = "继丞相之遗志，讨篡汉之逆贼！",
	["$fcmzj_yaozhi2"] = "克复中原，指日可待！",
	--界妆神(民间鬼包界限突破-界鬼诸葛亮)
	["fcmzj_jiezhuangshenbuff"] = "妆神",
	["fcmzj_jiezhuangshen"] = "妆神",
	["fcmzj_jiezhuangshenDamage"] = "妆神",
	["fcmzj_jiezhuangshenDeath"] = "妆神",
	[":fcmzj_jiezhuangshen"] = "准备阶段开始时或结束阶段开始时，你可以摸一张牌并判定，若结果为黑色，你可以选择一名其他角色的一个技能，你拥有此技能直到你下回合开始；" ..
	"若结果为红色，你可以对一名角色发动“狂风”或“大雾”。",
	["fcmzj_jiezhuangshenskill-ask"] = "你可以选择一名其他角色，获得其一个技能",
	["fcmzj_jiezhuangshengod-ask"] = "你可以选择发动“狂风”或“大雾”的角色",
	["fcmzj_jiezhuangshenbuff:kfc"] = "狂风",
	["fcmzj_jiezhuangshenbuff:dwg"] = "大雾",
	["jzs_kuangfeng"] = "狂风",
	["jzs_dawu"] = "大雾",
	["$fcmzj_jiezhuangshen1"] = "贼将早降，可免一死。", --判黑
	["$fcmzj_jiezhuangshen2"] = "汝等小儿，可敢杀我？", --判红
	--☠️阵亡
	["~fc_mou_jiangwei"] = "市井鱼龙易一统，护国麒麟难擎天......",

	--FC谋孙策
	["fc_mou_sunce"] = "谋孙策[FC]", 
	["fc_mou_sunces"] = "幽冥大帝·孙策",
	["&fc_mou_sunce"] = "☆谋孙策",
	["#fc_mou_sunce"] = "阴霸",
	["designer:fc_mou_sunce"] = "时光流逝FC",
	["cv:fc_mou_sunce"] = "新三国,Rarondo9,Jack Swagger",
	["illustrator:fc_mou_sunce"] = "沙溢,Rarondo9",
	  --激昂
	["fcmoujiang"] = "激昂",
	[":fcmoujiang"] = "你使用【决斗】或红色【杀】无目标数限制；当你使用【决斗】或红色【杀】指定一个目标后/成为【决斗】或红色【杀】的目标后，" ..
	"你失去1点体力/回复1点体力，并摸一张牌。",
	["@fcmoujiang-excard"] = "[激昂]你可以为【%src】指定任意名额外目标",
	["$fcmoujiang1"] = "我上表汉帝，让他封我为汉帝的事情，许昌已经回消息了...竟 然 不 许 ！",
	["$fcmoujiang2"] = "曹操是看我在江东日渐强盛，才故意驳回我的请求！",
	  --魂资
	["fcmouhunzi"] = "魂资",
	[":fcmouhunzi"] = "觉醒技，当你死亡时<font color='red'><b>(游戏胜负判定前)</b></font>，你立即复活，减2点体力上限，然后将体力回复至2点并将手牌数补至体力上限，" ..
	"获得技能“阴资”和“阴魂”。",
	["$fcmouhunzi1"] = "我上表权弟，让他追封我为帝的事情，江东已经回消息了...竟 然 不 许 ！", --9450s
	["$fcmouhunzi2"] = "孙权是看我在江东日渐强盛，才故意驳回我的请求！",
	--阴资
	["fcmhz_yinzi"] = "阴资",
	["fcmhz_yinzi_MaxCards"] = "阴资",
	[":fcmhz_yinzi"] = "锁定技，摸牌阶段，你改为摸X~Y张牌；弃牌阶段，你的手牌上限+Z。（X为你的当前体力值；Y为你的体力上限；Z为场上已阵亡的角色数）",
	["$fcmhz_yinzi1"] = "我上表汉帝，让他攻克江东的事情，许昌已经回消息了...竟 然... 许 ！",
	["$fcmhz_yinzi2"] = "汉帝上表我，让我封他为我父亲的事情，我已经回消息了... 不 许 ！",
	--阴魂
	["fcmhz_yinhun"] = "阴魂",
	[":fcmhz_yinhun"] = "限定技，判定阶段，你可以弃置一张判定区内的牌并选择一名角色（若其为主公，则改为需弃置两张），令其直接死亡，" ..
	"然后其立即复活，将体力调整至阵亡之前的体力值、将手牌摸至阵亡之前的手牌数。",
	["@fcmhz_yinhun"] = "阴魂",
	["fcmhz_yinhun_choice"] = "请选择一位阳间角色，带ta到阴界一日游",
	["$fcmhz_yinhun1"] = "我上表汉帝，让他锄死曹操馬的事情，许昌已经回消息了...竟 然 不 许 ！",
	["$fcmhz_yinhun2"] = "我上表汉帝，让他封我为曹操的事情，许昌已经不回消息了...竟 然 不 回 ！",
	  --制霸
	["fcmouzhiba"] = "制霸",
	["fcmouzhiba_pd"] = "制霸",
	[":fcmouzhiba"] = "主公技，<font color='green'><b>出牌阶段限K次，</b></font>你可以与一名其他角色拼点。（K为场上的存活“吴”势力角色数；若你拼点成功，将有几率触发彩蛋）",
	["$fcmouzhiba1"] = "你去，提他人头来见我。",
	["$fcmouzhiba2"] = "（掀桌子(╯‵□′)╯︵┻━┻）大胆！竟敢谋害于我！",
	["fcmouzhiba_successAnimate"] = "image=image/animate/fcmouzhiba_success.png",
	["$fcmouzhiba_success"] = "哈哈哈哈蛤哈哈哈哈...看来，我上表汉帝的时机到了！",
	["$fcmouzhiba_same"] = "就这么巧？！%from 对 %to 的“<font color='yellow'><b>制霸</b></font>”拼点为<font color='yellow'><b>平点</b></font>，" ..
	"触发了【🥚<font color='yellow'><b>隐藏彩蛋</b></font>】！",
	  --☠️阵亡
	["~fc_mou_sunce"] = "曹操的馬！如若不锄，必成大患......",
	  --胜利
	["fc_mou_sunceWIN"] = "胜利",
	[":fc_mou_sunceWIN"] = "[配音技]此技能为FC谋孙策胜利的专属配音。",
	["$fc_mou_sunceWIN"] = "（BGM:Patriot）属于我们的时代，开始了！",
	

		--AH谋诸葛亮
	["ah_mou_zhugeliang"] = "谋诸葛亮[AH]",
	["&ah_mou_zhugeliang"] = "△谋诸葛亮",
	["#ah_mou_zhugeliang"] = "武乡侯",
	["designer:ah_mou_zhugeliang"] = "爱好者s2",
	["cv:ah_mou_zhugeliang"] = "官方,爱好者s2",
	["illustrator:ah_mou_zhugeliang"] = "", --正式原画将为武诸葛的第二张皮肤
	  --匡辅
	["ahmoukuangfu"] = "匡辅",
	[":ahmoukuangfu"] = "判定阶段开始时，你可以跳过本回合的摸牌阶段，然后令一名角色随机获得牌堆中点数之和为21的牌，若如此做，你获得你判定区内的所有牌。",
	["#ahmoukuangfu1"] = "受遗托孤，匡辅幼主，犹念三顾之恩。",
	["#ahmoukuangfu2"] = "入汉中，出祁山，竭股肱之力，效忠贞之节。",
	["$ahmoukuangfu1"] = "",
	["$ahmoukuangfu2"] = "",
	  --识治
	["ahmoushizhi"] = "识治",
	[":ahmoushizhi"] = "准备阶段开始时，你可以选择至多两名角色，则直到你下个回合开始时，每当其使用或打出牌时，弃置一张牌；" ..
	"弃牌阶段结束时，若弃牌堆的牌数不少于十二张，你可以选择2~4名其他角色，这些角色依次均分弃牌堆中的随机十二张牌。",
	["@ahmoushizhi-ZHI"] = "[识治]治",
	["@ahmoushizhi-SHI"] = "[识治]识",
	    --治
	  ["ahmoushizhi_zhi"] = "识治-治",
	  ["ahmoushizhi_zx"] = "识治-治理",
	  ["@ahmoushizhi_zhi-card"] = "你可以选择至多两名角色，直到你下个回合开始时，他们用一弃一",
	  ["~ahmoushizhi_zhi"] = "明赏罚，布公道，刑政虽峻而民无忿。",
	  ["ahmoushizhi_zhiTarget"] = "治理对象",
	    --识
	  ["ahmoushizhi_shi"] = "识治-识",
	  ["@ahmoushizhi_shi-card"] = "你可以选择2~4名其他角色，他们均分弃牌堆中的12张牌",
	  ["~ahmoushizhi_shi"] = "约官职，抚百姓，无岁不征而食兵足。",
	  ["ahmoushizhi_shiTarget"] = "请决定第 %src 位参与均分的角色",
	--
	["#ahmoushizhi1"] = "明赏罚，布公道，刑政虽峻而民无忿。", --治(限制)
	["#ahmoushizhi2"] = "约官职，抚百姓，无岁不征而食兵足。", --识(分牌)
	["$ahmoushizhi1"] = "",
	["$ahmoushizhi2"] = "",
	  --讨贼
	["ahmoutaozei"] = "讨贼",
	["ahmoutaozei_tm"] = "讨贼",
	["ahmoutaozeiVC"] = "讨贼",
	[":ahmoutaozei"] = "一名角色的回合结束时，你将所有手牌扣置于你的武将牌旁，称为“奇策”。当一名角色使用（非通过该技能视为使用的且不为【无懈可击】的）牌指定目标时，" ..
	"你可以弃置一张“奇策”取消之，若如此做，你可以视为使用一张同名牌（若此牌为延时锦囊牌或装备牌，改为你摸一张牌）；你使用虚拟牌无距离限制且无法被响应。",
	["ahmtz_QC"] = "奇策",
	["@ahmoutaozei-qc"] = "你可以弃置一张“奇策”，取消该牌对目标角色的效果",
	["~ahmoutaozei"] = "☯[诸葛工坊·全自动化]系统将会自动帮你弃一张",
	["@ahmoutaozei_tm-card"] = "你可以视为使用一张【<font color='yellow'><b>%src</b></font>】",
	["~ahmoutaozei_tm"] = "☯[诸葛工坊·智能印卡]免费提供，放心使用。",
	["#ahmoutaozei1"] = "降羌蛮，复二郡，神武赫然震八荒。",
	["#ahmoutaozei2"] = "志靖乱，整三军，兵出祁山兴炎汉。",
	["$ahmoutaozei1"] = "",
	["$ahmoutaozei2"] = "",
	  --☠️阵亡
	--["~ah_mou_zhugeliang"] = "",
	
	--FC谋诸葛亮
	["fc_mou_zhugeliang"] = "谋诸葛亮[FC]",
	["&fc_mou_zhugeliang"] = "☆谋诸葛亮",
	["#fc_mou_zhugeliang"] = "空城绝唱",
	["designer:fc_mou_zhugeliang"] = "时光流逝FC",
	["cv:fc_mou_zhugeliang"] = "官方",
	["illustrator:fc_mou_zhugeliang"] = "沉睡千年",
	  --观星
	["fcmouguanxing"] = "观星",
	["fcmouguanxingSL"] = "观星",
	--[":fcmouguanxing"] = "一名角色的准备阶段开始时，若X大于0，你可以观看牌堆顶的X张牌，然后将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。若该角色不是你，" ..
	--"执行完上述操作后，你令X值-1；否则你令X值+1。锁定技，你每消耗1点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>，你令X值-1。（X初始为7，且至多为7、至少为0）",
	[":fcmouguanxing"] = "游戏开始时，你获得7枚“观星”标记（你至多拥有7枚“观星”标记）。一名角色的准备阶段开始时，若你的“观星”标记数大于0，你可以从牌堆顶观看" ..
	"等同于你“观星”标记数的牌，然后将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。若该角色不是你，执行完上述操作后，你移去1枚“观星”标记；否则你获得1枚“观星”标记。\
	锁定技，你每消耗1点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>，若你的“观星”标记数大于0，你失去1枚“观星”标记。",
	["$fcmouguanxing1"] = "观星定中原，毕其功于一役！",
	["$fcmouguanxing2"] = "天有不测风云，谨慎为妙。",
	  --空城
	["fcmoukongcheng"] = "空城",
	["fcmoukongchengMY"] = "空城",
	[":fcmoukongcheng"] = "锁定技，若你没有手牌，你防止【杀】和【决斗】对你造成的伤害。每个回合限一次，当你成为【杀】或【决斗】的目标时，若你有手牌，" ..
	"你可以与该牌的使用者进行“谋弈”：\
	<b>悠然弹琴</b>：若成功，你将所有手牌扣置于武将牌上，当前回合结束后，你获得这些牌；\
	<b>突然出击</b>：若成功，你视为对其使用一张【出其不意】（若其没有手牌，改为直接对其造成1点伤害），若你未能以此法对其造成伤害，其视为对你使用一张无距离限制且不计次的【杀】。\
	若你“谋弈”失败，直到你的下个回合开始前，你不能通过此技能进行“谋弈”。",
	["@MouYi-fckc"] = "谋弈：空城",
	["@MouYi-fckc:F1"] = "悠然弹琴(手动空城)",
	["@MouYi-fckc:F2"] = "突然出击(偷袭！)",
	["@MouYi-fckc:T1"] = "杀进城中(抱歉，我读过《三国演义》)",
	["@MouYi-fckc:T2"] = "等候多时(喵啊~)",
	["$fcmoukongcheng1"] = "一曲高山流水，还请诸位静听。", --谋弈
	["$fcmoukongcheng2"] = "空城一曲古琴调，管教天下英豪惊！", --空城成功
	["$fcmoukongcheng3"] = "如此虚虚实实之法，方能以少胜多！", --突击成功
	["$fcmoukongcheng4"] = "唉，天意终不可违......", --谋弈失败、突击未能造成伤害
	  --☠️阵亡
	["~fc_mou_zhugeliang"] = "悠悠苍天，何薄于我......",

	
	--灬魂灵灬--
	["fcSOUL"] = "魂灵",
	["@fcSOUL"] = "魂灵",
	["$fcSOUL_used"] = "%from 消耗了 <font color='yellow'><b>1</b></font> 点 <font color=\"#00CCFF\"><b>🔥魂灵</b></font> ，将体力从 %arg 点回复至 %arg2 点",
	--1点
	["fcSOUL_one"] = "魂灵[1]",
	[":fcSOUL_one"] = "你开局拥有【1】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--2点
	["fcSOUL_two"] = "魂灵[2]",
	[":fcSOUL_two"] = "你开局拥有【2】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--3点
	["fcSOUL_three"] = "魂灵[3]",
	[":fcSOUL_three"] = "你开局拥有【3】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--4点
	["fcSOUL_four"] = "魂灵[4]",
	[":fcSOUL_four"] = "你开局拥有【4】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--5点
	["fcSOUL_five"] = "魂灵[5]",
	[":fcSOUL_five"] = "你开局拥有【5】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--6点
	["fcSOUL_six"] = "魂灵[6]",
	[":fcSOUL_six"] = "你开局拥有【6】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--7点
	["fcSOUL_seven"] = "魂灵[7]",
	[":fcSOUL_seven"] = "你开局拥有【7】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--8点
	["fcSOUL_eight"] = "魂灵[8]",
	[":fcSOUL_eight"] = "你开局拥有【8】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--9点
	["fcSOUL_nine"] = "魂灵[9]",
	[":fcSOUL_nine"] = "你开局拥有【9】点<font color=\"#00CCFF\"><b>🔥魂灵</b></font>。\
	<font color=\"#00CCFF\"><b>🔥魂灵：</b></font>当你的体力值为0或更低时，若你的体力值小于-1/不小于-1，你消耗1点魂灵，将体力值回复至0/1点。",
	--
	
	--FC谋陈宫
	["fc_mou_chengong"] = "谋陈宫[FC]",
	["&fc_mou_chengong"] = "☆谋陈宫",
	["#fc_mou_chengong"] = "必要的牺牲",
	["designer:fc_mou_chengong"] = "时光流逝FC,Fate/GO",
	["cv:fc_mou_chengong"] = "真殿光昭",
	["illustrator:fc_mou_chengong"] = "WADA ARUKO",
	  --明策
	["fcmoumingce"] = "明策",
	["fcmoumingceDMG"] = "明策",
	[":fcmoumingce"] = "<font color='green'><b>出牌阶段对每名角色各限一次，</b></font>你可以将一张牌交给一名其他角色，然后其选择一项：" ..
	"1、失去1点体力，你摸两张牌并获得1枚“策”标记；2、摸一张牌。出牌阶段开始时/结束时，若你拥有“策”标记，" ..
	"你可以选择一名其他角色，对其造成X点伤害并移除你的所有“策”标记。（X为你的“策”标记数量）",
	["fcmoumingce:1"] = "失去1点体力，令其摸两张牌并获得1枚“策”标记",
	["fcmoumingce:2"] = "摸一张牌",
	["fcmCe"] = "策",
	["fcmoumingce-DMGto"] = "你可以选择一名其他角色，对其造成 %src 点伤害",
	["$fcmoumingce1"] = "唔......闪现出点子了！", --给牌
	["$fcmoumingce2"] = "唔......只能用自爆了！", --给牌
	["$fcmoumingce3"] = "吕将军！现在应该自爆！", --砸人(小[伤害<3])（吕布：？我阐释你的梦）
	["$fcmoumingce4"] = "凭奇策、冷血终结一切吧：爆发的乃是掎角一阵！哼......这是必要的牺牲。", --砸人(大[伤害>=3])
	  --智迟
	["fcmouzhichi"] = "智迟",
	["fcmouzhichiClear"] = "智迟",
	[":fcmouzhichi"] = "锁定技，当你受到伤害后，你获得1枚“策”标记；你于本回合再受到伤害时，防止之。",
	["$fcmouzhichi1"] = "没什么大不了的！", --激发
	["$fcmouzhichi2"] = "真单纯真单纯，这样可不行哦。", --防伤
	  --☠️阵亡
	["~fc_mou_chengong"] = "心有不甘......至少应该毁灭敌阵......",
	
	--AH谋吕布
	["ah_mou_lvbu"] = "谋吕布[AH]",
	["&ah_mou_lvbu"] = "△谋吕布",
	["#ah_mou_lvbu"] = "辕门射戟",
	["designer:ah_mou_lvbu"] = "爱好者s2",
	["cv:ah_mou_lvbu"] = "官方,老三国",
	["illustrator:ah_mou_lvbu"] = "凡果", --皮肤：傲睨万物
	  --无双
	["ahmouwushuang"] = "无双",
	[":ahmouwushuang"] = "锁定技，每当你指定【杀】的目标后，目标角色需使用两张【闪】抵消此【杀】；你指定或成为【决斗】的目标后，与你进行“决斗”的角色每次需连续打出两张【杀】。" ..
	"当其他角色使用或打出的牌因响应你使用的伤害类牌而进入弃牌堆时<font color='red'><b>(注:若遇到BUG请不要惊讶)</b></font>，你可以获得之；" ..
	"你使用的伤害类牌若未被目标角色响应，对其造成的伤害值翻倍。",
	["$ahmouwushuang_double"] = "因为 %to 没有响应 %from 使用的 %card，此次 %from 对 %to 的伤害将由 %arg 翻为 %arg2",
	["$ahmouwushuang1"] = "画戟一击，五脏俱损！",
	["$ahmouwushuang2"] = "尔等凡夫，怎敌吾千钧之力！",
	  --解斗
	["ahmoujiedou"] = "解斗",
	[":ahmoujiedou"] = "当你攻击范围内的一名其他角色使用伤害类牌指定你攻击范围内的另一名其他角色为目标时，你可以交给这两名角色各一张牌，然后获得这张牌。",
	["@ahmoujiedou-cardgive"] = "[解斗]请选择一张牌，交给一名可选角色(“解斗”目标角色其一)",
	["$ahmoujiedou1"] = "不论何求，来者不拒！",
	["$ahmoujiedou2"] = "既受其利，自要依言而行！",
	  --拜父
	["ahmoubaifu"] = "拜父",  --后续新杀推出了吕布的彩蛋语音即为以下两条语音，不过我觉得还是老三国的经典。
	[":ahmoubaifu"] = "每当你获得一名其他角色的一张牌时，你与其各摸一张牌（每轮你至多以此法获得三张牌）。",
	["$ahmoubaifu1"] = "吕布飘零半生，只恨未逢明主。",
	["$ahmoubaifu2"] = "公若不弃，布愿拜为义父。",
	  --☠️阵亡
	["~ah_mou_lvbu"] = "大耳贼！不记辕门射戟之日乎？......",
	


	--神黄盖
	["f_shenhuanggai"] = "神黄盖[FC]",
	["#f_shenhuanggai"] = "破天焚舰",
	["designer:f_shenhuanggai"] = "时光流逝FC",
	["cv:f_shenhuanggai"] = "官方",
	["illustrator:f_shenhuanggai"] = "嗑瞌一休",
	  --苦诈
	["f_kuzha"] = "苦诈",
	["f_kuzha_finish"] = "苦诈",
	[":f_kuzha"] = "出牌阶段限一次，你可以减1点体力上限并获得“苦肉-旧版”直到回合结束。",
	["$f_kuzha1"] = "披甲转战南北！",
	["$f_kuzha2"] = "攻城略地，尚不惧生死，又何惧鞭挞！",
	  --身先
	["f_shenxianshizu"] = "身先",
	["f_shenxianshizuA"] = "身先",
	["f_shenxianshizuB"] = "身先",
	["f_shenxianshizu_fire"] = "身先",
	[":f_shenxianshizu"] = "限定技，出牌阶段，你将所有手牌交给一名其他角色。若如此做，直到回合结束，你对其使用【杀】无距离和次数限制，你对其造成的火焰伤害+1。",
	["@f_shenxianshizu"] = "身先",
	["huoshaochibi"] = "火烧赤壁！",
	["$f_shenxianshizu1"] = "诈降之术，因势利导！",
	["$f_shenxianshizu2"] = "东风已起，点火，冲啊！",
	  --阵亡
	["~f_shenhuanggai"] = "赤壁今已寒，犹忆当年火......",
	
	--神华佗
	["f_shenhuatuo"] = "神华佗[FC]",
	["#f_shenhuatuo"] = "悬壶济世",
	["designer:f_shenhuatuo"] = "时光流逝FC",
	["cv:f_shenhuatuo"] = "官方,音频怪物,Aki阿杰",
	["illustrator:f_shenhuatuo"] = "凝聚永恒",
	  --疗毒
	["f_liaodu"] = "疗毒",
	[":f_liaodu"] = "出牌阶段限一次，你可以弃置一张装备牌并选择一名角色，则其回复1点体力、摸一张牌、复原武将牌并清空判定区。",
	["$f_liaodu1"] = "血脉流通，则诸病不生。",
	["$f_liaodu2"] = "正本清源，则药到病除。",
	  --麻沸
	["f_mafei"] = "麻沸",
	["f_mafeiBuff"] = "麻沸",
	[":f_mafei"] = "出牌阶段限一次，你可以弃置一张锦囊牌，令一名角色翻面。锁定技，以此法翻为背面的角色：受到伤害时，弃置一张牌令此伤害-1；回复体力时，回复量+1。该角色拥有上述效果直到其翻为正面为止。",
	["f_mafeisan"] = "麻沸散",
	["$f_mafeiBuff_jianshang"] = "因为 <font color='yellow'><b>麻沸散</b></font> 的效果，%from 受到的伤害-1",
	["$f_mafeiBuff_recover"] = "因为 <font color='yellow'><b>麻沸散</b></font> 的效果，%from 的回复量+1",
	["$f_mafei1"] = "祛病除魔，妙手回春。",
	["$f_mafei2"] = "悬壶济世，普度众生。",
	  --五禽
	["f_wuqin"] = "五禽",
	["f_wuqin_tigerBuff"] = "[五禽戏]虎戏",
	["f_wuqin_deerBuff"] = "[五禽戏]鹿戏",
	["f_wuqin_bearBuff"] = "[五禽戏]熊戏",
	["f_wuqin_apeBuff"] = "[五禽戏]猿戏",
	["f_wuqin_apeBuff_message"] = "[五禽戏]猿戏",
	["f_wuqin_bird"] = "[五禽戏]鸟戏",
	["f_wuqin_MarkClear"] = "五禽",
	[":f_wuqin"] = "出牌阶段限一次，你可以弃置一张基本牌并选择一名角色，表演“<font color='green'><b>五禽戏</b></font>”。根据你成功表演的功法数，其获得对应效果直到其回合结束：\
	<font color='orange'><b>[虎戏]</b></font>【杀】或【决斗】的伤害+1；\
	<font color='yellow'><b>[鹿戏]</b></font>【桃】或【酒】的回复量+1；\
	<font color='brown'><b>[熊戏]</b></font>每使用或打出一张【闪】或【无懈可击】，摸一张牌；\
	<font color='grey'><b>[猿戏]</b></font>使用【顺手牵羊】或【兵粮寸断】无距离限制；\
	<font color='blue'><b>[鸟戏]</b></font>受到实体卡牌的伤害时，有一定概率闪避(防止伤害)。",
	["$f_wuqin_start"] = "五禽戏",
	["f_wuqin_tiger"] = "虎戏",
	["f_wuqin_deer"] = "鹿戏",
	["f_wuqin_bear"] = "熊戏",
	["f_wuqin_ape"] = "猿戏",
	["f_wuqin_bird"] = "鸟戏",
	["$f_wuqin_tiger_success"] = "%from 表演“<font color='green'><b>五禽戏</b></font>”之“<font color='orange'><b>虎戏</b></font>” <font color='red'><b>成功</b></font>！",
	["$f_wuqin_deer_success"] = "%from 表演“<font color='green'><b>五禽戏</b></font>”之“<font color='yellow'><b>鹿戏</b></font>” <font color='red'><b>成功</b></font>！",
	["$f_wuqin_bear_success"] = "%from 表演“<font color='green'><b>五禽戏</b></font>”之“<font color='brown'><b>熊戏</b></font>” <font color='red'><b>成功</b></font>！",
	["$f_wuqin_ape_success"] = "%from 表演“<font color='green'><b>五禽戏</b></font>”之“<font color='grey'><b>猿戏</b></font>” <font color='red'><b>成功</b></font>！",
	["$f_wuqin_bird_success"] = "%from 表演“<font color='green'><b>五禽戏</b></font>”之“<font color='blue'><b>鸟戏</b></font>” <font color='red'><b>成功</b></font>！",
	["$f_wuqin_finish"] = "%from 的“<font color='green'><b>五禽戏</b></font>” <font color='red'><b>表演结束</b></font>",
	["$f_wuqin_tigerBuff"] = "因为“<font color='orange'><b>虎戏</b></font>”的加成效果，此 %card 造成的伤害+1",
	["$f_wuqin_deerBuff"] = "因为“<font color='yellow'><b>鹿戏</b></font>”的加成效果，此 %card 回复量+1",
	["$f_wuqin_bearBuff"] = "因为“<font color='brown'><b>熊戏</b></font>”的加成效果，%from 摸一张牌",
	["$f_wuqin_apeBuff"] = "因为“<font color='grey'><b>猿戏</b></font>”的加成效果，此 %card 无距离限制",
	["$f_wuqin_birdBuff"] = "因为“<font color='blue'><b>鸟戏</b></font>”的加成效果，%from 回避此伤害",
	["$f_wuqin1"] = "（音乐：五禽戏<男声>“一起来五禽戏！......”）",
	["$f_wuqin2"] = "（音乐：五禽戏<女声>“一支华佗五禽曲，虎鹿熊猿鸟戏；一段中医养生道理，逍遥人欢喜”）",
	  --阵亡
	["~f_shenhuatuo"] = "人心不古，药石难治......",

	--狂暴流氓云
	["f_KBliumangyun"] = "狂暴流氓云[FC]",
	["#f_KBliumangyun"] = "8说了,开冲",
	["designer:f_KBliumangyun"] = "时光流逝FC",
	["cv:f_KBliumangyun"] = "官方",
	["illustrator:f_KBliumangyun"] = "DH", --皮肤：单骑救主
	  --龙胆(OL界限突破版)
	  --冲阵
	["f_chongzhen"] = "冲阵",
	[":f_chongzhen"] = "当你使用或打出一张基本牌时，你可以获得【目标角色】区域里的一张牌；若目标角色为你，改为你摸《0》张牌。\
	<font color='blue'><b>超级冲阵：若此基本牌为发动“龙胆”使用或打出的牌，【】内的内容改为“任意一名角色”、《》内的数字改为“1”。</b></font>",
	["f_SuperChongzhen"] = "【<font color='blue'><b>超级冲阵</b></font>】你可以选择任意一名角色，获得其区域里的一张牌",
	["$f_chongzhen1"] = "欲破强敌，须乱其阵！",
	["$f_chongzhen2"] = "冲敌破阵，斩将之刃！",
	  --义丛
	["f_yicon"] = "义丛",
	["f_yiconn"] = "义丛",
	["f_yiconAudio"] = "义丛",
	[":f_yicon"] = "锁定技，你与其他角色的距离-1；当你的体力值不大于2时，你的手牌上限+1。",
	["$f_yicon1"] = "敞开营门，随我号令！",
	["$f_yicon2"] = "勇者，以退为进！",
	  --阵亡
	["~f_KBliumangyun"] = "魂归在何处，仰天长问三两声......",

	--神徐盛
	["f_shenxusheng"] = "神徐盛[七夕纪念]",
	["&f_shenxusheng"] = "神徐盛",
	["f_shenxusheng_skin"] = "神徐盛[七夕纪念]",
	["&f_shenxusheng_skin"] = "神徐盛",
	["f_shenxusheng_forSHZ"] = "神徐盛[七夕纪念]",
	["&f_shenxusheng_forSHZ"] = "神徐盛",
	["#f_shenxusheng"] = "海誓山盟",
	["designer:f_shenxusheng"] = "时光流逝FC",
	["cv:f_shenxusheng"] = "网络,张馨予",
	["illustrator:f_shenxusheng"] = "云涯",
	--
	["f_forSXSandSHZ"] = "",
	["@f_forSXSandSHZ_changeSkin"] = "更换武将皮肤",
	["@f_forSXSandSHZ_changeSkin:1"] = "原画",
	["@f_forSXSandSHZ_changeSkin:2"] = "皮肤",
	--
	  --魄君
	["f_pojun"] = "魄君",
	["f_pojunReturn"] = "魄君",
	["f_pojunFakeMove"] = "魄君",
	[":f_pojun"] = "<font color='green'><b>每个回合对每名其他角色限一次</b></font><font color='red'><b>（若为男性角色，则改为限两次）</b></font>，当你使用伤害类牌指定一个目标后，" ..
	"你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值），若其中有：基本牌，你回复1点体力；锦囊牌，你摸一张牌；装备牌，你弃置其中一张牌。" ..
	"若如此做，当前回合结束后，该角色获得这些牌。当你使用目标数不超过你当前体力值的伤害类牌对手牌数与装备数均不大于你的其他角色造成伤害时，此伤害+1。",
	["f_pojun_num"] = "魄君-扣置数",
	["f_pojun_dis"] = "魄君-扣置",
	["$f_pojun1"] = "犯大吴疆土者，盛必击而破之。",
	["$f_pojun2"] = "江东铁壁据长江兮，魄君剑舞正此时。",
	  --怡娍
	["f_yicheng"] = "怡娍",
	[":f_yicheng"] = "每个回合限一次，当一名其他角色成为使用来源不为你的伤害类牌的目标后，你可以令该角色摸一张牌<font color='red'><b>（若为男性角色，则改为摸两张牌）</b></font>" ..
	"然后弃置一张牌。若以此法弃置的牌的花色与该伤害类牌相同，则此伤害类牌对该角色无效。",
	["$f_yicheng1"] = "问世间情是何物，直教生死相许。",
	["$f_yicheng2"] = "天南地北双飞客，老翅几回寒暑。",
	  --搭妆
	["f_dazhuang"] = "搭妆",
	[":f_dazhuang"] = "每轮限一次，当你造成伤害后，你可以连续使用牌堆中的Y张装备牌（Y为你此次造成的伤害值）。",
	["$f_dazhuang1"] = "欢乐趣，离别苦~",
	["$f_dazhuang2"] = "就中更有痴儿女~",
	  --❤海誓❤
	["f_haishiSM"] = "海誓",
	[":f_haishiSM"] = "<b><font color='pink'>情侣</font>联动技<font color='#FE2E86'>【情侣：神徐盛[七夕纪念]×神黄忠[七夕纪念]】</font>，</b>限定技，" ..
	"当你的（为其他角色的）“情侣”濒死状态询问结束后，你可以令其回满体力并将你区域内的所有牌交给其。若如此做，<font color='red'><b>代价：</b></font>你死亡。\
	<font color='pink'><b>❤/海誓山盟/：</b></font><font color='#FE2E86'>若你的主将与副将互为“情侣”，你的回复值+1。</font>",
	["@f_haishiSM"] = "海誓",
	["$f_haishiSM_toSHZ"] = "你说，如果有来生，我们还会再相见吗？",
	["$f_haishiSM1"] = "君应有语，渺万里层云......",
	["$f_haishiSM2"] = "千山暮雪，只影向谁去......",
	  --阵亡
	["~f_shenxusheng"] = "忠......",
	["~f_shenxusheng_skin"] = "忠......",
	["~f_shenxusheng_forSHZ"] = "忠......",
	
	--神黄忠
	["f_shenhuangzhongg"] = "神黄忠[七夕纪念]",
	["&f_shenhuangzhongg"] = "神黄忠",
	["f_shenhuangzhongg_skin"] = "神黄忠[七夕纪念]",
	["&f_shenhuangzhongg_skin"] = "神黄忠",
	["f_shenhuangzhongg_forSXS"] = "神黄忠[七夕纪念]",
	["&f_shenhuangzhongg_forSXS"] = "神黄忠",
	["#f_shenhuangzhongg"] = "山盟海誓",
	["designer:f_shenhuangzhongg"] = "时光流逝FC,小霸汪孙伯符",
	["cv:f_shenhuangzhongg"] = "官方,TI intro,古巨基",
	["illustrator:f_shenhuangzhongg"] = "石琨,一串糖葫芦,三国志12",
	  --开弓
	["f_kaigong"] = "开弓",
	[":f_kaigong"] = "当你使用【杀】指定一个目标后，每满足下列一项条件，你可以令此【杀】伤害+1：\
	1、目标的手牌数不小于你的体力值；\
	2、目标的手牌数不大于你的攻击范围；\
	3、你的手牌数不小于目标的手牌数；\
	4、你的体力值不大于目标的体力值。",
	[":f_kaigong1"] = "当你使用【杀】指定一个目标后，每满足下列一项条件，你可以令此【杀】伤害+1：\
	1、<%arg1>目标的手牌数不小于你的体力值；</%arg1>\
	2、<%arg2>目标的手牌数不大于你的攻击范围；</%arg2>\
	3、<%arg3>你的手牌数不小于目标的手牌数；</%arg3>\
	4、<%arg4>你的体力值不大于目标的体力值</%arg4>。",

	["f_kaigong:f_kaigongUpDamage"] = "你可以发动“开弓”令此【杀】伤害+%src<br/> ->你也可以点【取消】，自定义此【杀】伤害的增值（至多+%src）",
	["f_kaigong:0"] = "此【杀】伤害+0",
	["f_kaigong:1"] = "此【杀】伤害+1",
	["f_kaigong:2"] = "此【杀】伤害+2",
	["f_kaigong:3"] = "此【杀】伤害+3",
	["f_kaigong:4"] = "此【杀】伤害+4",
	["$f_kaigongUD"] = "因为“<font color='yellow'><b>开弓</b></font>”的加成，%from 使用的 %card 对 %to 造成的伤害 + %arg2",
	["$f_kaigong1"] = "还有哪个愿饮我锋矢？",
	["$f_kaigong2"] = "老夫张弓一射，便叫敌军立毙一将！",
	  --弓魂
	["f_gonghun"] = "弓魂",
	["f_gonghunMission"] = "弓魂",
	["#f_gonghunMission"] = "弓魂",
	[":f_gonghun"] = "<b><font color='blue'>阶</font><font color='#5A2DFF'>梯</font><font color='purple'>技</font>，</b>游戏开始时，你为【1阶】。" ..
	"你每完成一次“升阶”，你的【杀】伤害+1，且你删除“开弓”中的一项条件。\
	【1阶】你获得技能“标烈弓”；当你使用或打出一张非虚拟非转化【杀】后，你可以进行一次“升阶”（成功率90%）；\
	【2阶】你获得技能“界烈弓”；当你使用或打出不同颜色的【杀】（不包括无颜色）各一张后，你可以进行一次“升阶”（成功率80%）；\
	【3阶】你获得技能“谋烈弓”并输入核密码；当你使用或打出不同花色的【杀】（不包括无花色）各一张后，你可以进行一次“升阶”（成功率70%）；\
	【4阶】你获得技能“神烈弓”并失去1点体力；当你使用或打出一张虚拟【杀】或转化前的牌数不少于4的转化【杀】后，你可以进行一次“升阶”（成功率60%）；\
	【5阶】（满阶）你随机获得一张<font color='red'><b>【灭世“神兵”】</b>（赤血刃(23%)/没日弓(75%)/<font color='orange'>彩蛋:二者皆得(2%)</font>）</font>。",
	[":f_gonghun1"] = "<b><font color='blue'>阶</font><font color='#5A2DFF'>梯</font><font color='purple'>技</font>，</b>你为【%arg1 阶】。" ..
	"你每完成一次“升阶”，你的【杀】伤害+1，且你删除“开弓”中的一项条件。\
	<%arg2>【1阶】你获得技能“标烈弓”；当你使用或打出一张非虚拟非转化【杀】后，你可以进行一次“升阶”（成功率90%）；</%arg2>\
	<%arg3>【2阶】你获得技能“界烈弓”；当你使用或打出不同颜色的【杀】（不包括无颜色）各一张后，你可以进行一次“升阶”（成功率80%）；</%arg3>\
	<%arg4>【3阶】你获得技能“谋烈弓”并输入核密码；当你使用或打出不同花色的【杀】（不包括无花色）各一张后，你可以进行一次“升阶”（成功率70%）；</%arg4>\
	<%arg5>【4阶】你获得技能“神烈弓”并失去1点体力；当你使用或打出一张虚拟【杀】或转化前的牌数不少于4的转化【杀】后，你可以进行一次“升阶”（成功率60%）；</%arg5>\
	【5阶】（满阶）你随机获得一张<font color='red'><b>【灭世“神兵”】</b>（赤血刃(23%)/没日弓(75%)/<font color='orange'>彩蛋:二者皆得(2%)</font>）</font>。",
	["$f_gonghun_fail"] = "很遗憾，%from 升阶<font color='red'><b>失败</b></font>",
	["f_gonghunMission:toTwo"] = "[弓魂-升阶]你可以升至<b><font color='yellow'>//</font><font color=\"#66FF66\">二阶</font><font color='yellow'>//</font></b>",
	["$f_gonghun_1to2"] = "%from 升阶<font color=\"#4DB873\"><b>成功</b></font>，升入“<font color='yellow'><b>弓魂</b></font>”<font color=\"#66FF66\"><b>二阶</b></font>！",
	["f_gonghunMission:toThree"] = "[弓魂-升阶]你可以升至<b><font color='yellow'>//</font><font color=\"#00CCFF\"><b>三阶</b></font><font color='yellow'>//</font></b>",
	["$f_gonghun_2to3"] = "%from 升阶<font color=\"#4DB873\"><b>成功</b></font>，升入“<font color='yellow'><b>弓魂</b></font>”<font color=\"#00CCFF\"><b>三阶</b></font>！",
	["f_gonghunMission:toFour"] = "[弓魂-升阶]你可以升至<b><font color='yellow'>//</font><font color='purple'><b>四阶</b></font><font color='yellow'>//</font></b>",
	["$f_gonghun_3to4"] = "%from 升阶<font color=\"#4DB873\"><b>成功</b></font>，升入“<font color='yellow'><b>弓魂</b></font>”<font color='purple'><b>四阶</b></font>！",
	["f_gonghunMission:toMaxFive"] = "[弓魂-升阶]你可以升至<b><font color='yellow'>//</font><font color='orange'><b>五阶</b></font><font color='yellow'>//</font></b>",
	["$f_gonghun_4to5"] = "%from 升阶<font color=\"#4DB873\"><b>成功</b></font>，升入“<font color='yellow'><b>弓魂</b></font>”<font color='orange'><b>五阶</b></font>，" ..
	"达到<font color='red'><b>满阶</b></font>！",
	["f_gonghunDelete"] = "删除“开弓”条件",
	["f_gonghunDelete:1"] = "删除“开弓”条件：目标的手牌数不小于你的体力值",
	["f_gonghunDelete:2"] = "删除“开弓”条件：目标的手牌数不大于你的攻击范围",
	["f_gonghunDelete:3"] = "删除“开弓”条件：你的手牌数不小于目标的手牌数",
	["f_gonghunDelete:4"] = "删除“开弓”条件：你的体力值不大于目标的体力值",
	["$f_gonghunMD"] = "因为“<font color='yellow'><b>弓魂</b></font>”的加成，%from 使用的 %card 对 %to 造成的伤害 + %arg2",
	["$f_gonghun1"] = "（成功提示音：升至2阶）",
	["$f_gonghun2"] = "（成功提示音：升至3阶）",
	["$f_gonghun3"] = "（成功提示音：升至4阶）",
	["$f_gonghun4"] = "（成功提示音：升至5阶，恭喜达到满阶！）",
	    --谋烈弓
	  ["f_mouliegong"] = "谋·烈弓",
	  ["f_mouliegong_limit"] = "烈弓",
	  ["f_mouliegong_record"] = "烈弓",
	  [":f_mouliegong"] = "若你的装备区里没有武器牌，你的【杀】只能当普通【杀】使用或打出。你使用牌时或成为其他角色使用牌的目标后，若此牌的花色未被“烈弓”记录，则记录此种花色。" ..
	  "当你使用【杀】指定唯一目标后，你可以亮出牌堆顶的X张牌（X为你记录的花色数-1，且至少为0），每有一张牌花色与“烈弓”记录的花色相同，你令此【杀】伤害+1，" ..
	  "且其不能使用“烈弓”记录花色的牌响应此【杀】。若如此做，此【杀】结算结束后，清除“烈弓”记录的花色。",
	  ["f_mouliegong_MoreDamage"] = "",
	  ["$f_mouliegongBUFF"] = "因为“<font color='yellow'><b>烈弓</b></font>”的加成，%from 使用的 %card 对 %to 造成的伤害 + %arg2",
	  ["$f_mouliegong1"] = "矢贯坚石，劲冠三军！",
	  ["$f_mouliegong2"] = "吾虽年迈，箭矢犹锋！",
	    --神烈弓
	  ["smzy_shenliegong"] = "神·烈弓",
	  ["smzy_shenliegong_tarmod"] = "烈弓",
	  [":smzy_shenliegong"] = "你可以将至少一张花色各不相同的手牌当无距离和次数限制的【火杀】使用，若以此法使用的转化前的牌数不小于：1，此【火杀】不可被【闪】响应；" ..
	  "2，此【火杀】结算完毕后，你摸三张牌；3，此【火杀】的伤害+1；4，此【火杀】造成伤害后，你令目标角色随机失去一个技能。" ..
	  "每回合限一次。若你已受伤，改为每回合限两次。",
	  ["#smzy_FireLiegong1"] = "由于“%arg”的技能效果，%from 使用的 %card 不能被【<font color = 'yellow'><b>闪</b></font>】响应",
	  ["#smzy_FireLiegong2"] = "由于“%arg”的技能效果，%from 使用的 %card 在结算完毕后，%from摸 <font color = 'yellow'><b>3</b></font> 张牌",
	  ["#smzy_FireLiegong3"] = "由于“<font color = 'yellow'><b>烈弓</b></font>”的技能效果，%from 使用的 %card 造成的伤害从 %arg 点增加至 %arg2 点",
	  ["#smzy_FireLiegong4"] = "由于“%arg”的技能效果，%to 受到 %from 使用的 %card 造成的伤害后将随机失去1个武将技能",
	  ["$smzy_shenliegong1"] = "烈弓神威，箭矢毙敌！",
	  ["$smzy_shenliegong2"] = "鋷甲锵躯，肝胆俱裂！",
	  --❤山盟❤
	["f_shanmengHS"] = "山盟",
	["f_shanmenghs"] = "山盟",
	[":f_shanmengHS"] = "<b><font color='pink'>情侣</font>联动技<font color='#FE2E86'>【情侣：神黄忠[七夕纪念]×神徐盛[七夕纪念]】</font>，</b>限定技，" ..
	"出牌阶段，若场上没有你的“情侣”，你可以销毁一张<font color='red'><b>【灭世“神兵”】</b></font>，令一名已阵亡角色重生为你的“情侣”，并令其将体力值与手牌数补至体力上限。" ..
	"若如此做，<font color='red'><b>代价：</b></font>你将武将牌替换为“士兵”并失去“弓魂”的【杀】伤害加成效果（替换前后体力上限与体力值保持不变）。\
	<font color='pink'><b>❤/山盟海誓/：</b></font><font color='#FE2E86'>若你的主将与副将互为“情侣”，你的伤害值+1。</font>",
	["@f_shanmengHS"] = "山盟",
	["f_shanmengHS-ask"] = "山盟:复活爱人",
	["$f_shanmengHS_toSXS"] = "会的，遇见你是我的命中注定。到那一次，\
	我一定要紧紧抓住你的手，永远不放开。",
	["$f_shanmengHS1"] = "苦海，翻起爱恨...在世间，难逃避命运...",
	["$f_shanmengHS2"] = "相亲，竟不可接近...或我应该，相信是缘分...",
	--["$f_shanmengHS3"] = "复~活~吧~，我~的~爱~人~!~!~!~",
	  --==【灭世“神兵”】==--
	  --<赤血刃>--
	  ["_f_chixieren"] = "赤血刃",
	  ["Fchixieren"] = "赤血刃", --血杀！
	  [":_f_chixieren"] = "装备牌·武器<br /><b>攻击范围</b>：1\
	  <b>武器技能</b>：当你的【杀】造成伤害后，你可以回复与此【杀】造成的伤害值等量的体力。<font color='black'><b>此牌进入弃牌堆时销毁。</b></font>\
	  <font color='red'><b>神兵灭世：</b></font>出牌阶段，你可以销毁此牌并选择一名距离为1的其他角色，你失去所有体力，然后移除其所有体力卡。",
	  --<没日弓>--
	  ["_f_morigong"] = "没日弓",
	  ["Fmorigong"] = "没日弓", --暗杀！
	  [":_f_morigong"] = "装备牌·武器<br /><b>攻击范围</b>：6\
	  <b>武器技能</b>：你可以令你的【杀】造成的伤害改为体力流失。<font color='black'><b>此牌进入弃牌堆时销毁。</b></font>\
	  <font color='red'><b>神兵灭世：</b></font>出牌阶段，你可以销毁此牌并选择一名其他角色，移除其所有体力值，<font color='red'><b>且期间仅该角色能使用【桃】</b></font>。",
	  --原版：神兵灭世：出牌阶段，你可以销毁此牌并选择一名其他角色，移除其所有体力值。
	  -------
	    --神兵灭世
	  ["f_mieshiSB"] = "灭世",
	  ["f_mieshisb"] = "神兵灭世",
	  [":f_mieshiSB"] = "出牌阶段，你可以<font color='green'><b>点击此按钮</b></font>，选择一张【灭世“神兵”】（赤血刃/没日弓），" ..
	  "触发其<font color='red'><b>神兵灭世</b></font>效果。",
	  --==================--
	  --阵亡
	["~f_shenhuangzhongg"] = "宝儿..对不起，我再也不能...守护......",
	["~f_shenhuangzhongg_skin"] = "宝儿..对不起，我再也不能...守护......",
	["~f_shenhuangzhongg_forSXS"] = "宝儿..对不起，我再也不能...守护......",
	
	["f_forTOMandJERRY"] = "《猫和老鼠》",

}
---
return {extension, xiangyuEquip, extension_Cards, extension_G, extension_J, extension_M}