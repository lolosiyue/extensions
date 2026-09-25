module("extensions.typemoon", package.seeall)
extension = sgs.Package("typemoon")

Ryougi_Shiki = sgs.General(extension, "Ryougi_Shiki", "god", 3, false, false)

shikistart = sgs.CreateTriggerSkillV2 {
	name = "#shikistart",
	events = { sgs.GameStart },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local id = -1
		if player:isFemale() then
			repeat
				id = room:drawCard()
				player:addToPile("maleshiki", sgs.Sanguosha:getCard(id), false)
			until player:getPile("maleshiki"):length() >= 4
		else
			repeat
				id = room:drawCard()
				player:addToPile("femaleshiki", sgs.Sanguosha:getCard(id), false)
			until player:getPile("femaleshiki"):length() >= 4
		end
		return false
	end,
}

yinyang = sgs.CreateTriggerSkillV2 {
	name = "yinyang",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		local counter = player:getPile("femaleshiki"):length() + player:getPile("maleshiki"):length() + player:getHandcardNum()
		if counter > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		if player:isFemale() then
			if not player:isKongcheng() then
				player:setGender(sgs.General_Male)
				player:addToPile("femaleshiki", player:handCards(), false)
			end
			if not player:getPile("maleshiki"):isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName())
				local move = sgs.CardsMoveStruct(player:getPile("maleshiki"), player, sgs.Player_PlaceHand, reason)
				room:moveCardsAtomic(move, false)
			end
		else
			if not player:isKongcheng() then
				player:setGender(sgs.General_Female)
				player:addToPile("maleshiki", player:handCards(), false)
			end
			if not player:getPile("femaleshiki"):isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName())
				local move = sgs.CardsMoveStruct(player:getPile("femaleshiki"), player, sgs.Player_PlaceHand, reason)
				room:moveCardsAtomic(move, false)
			end
		end
		return false
	end,
}

yinyangDetach = sgs.CreateTriggerSkillV2 {
	name = "#yinyangDetach",
	events = { sgs.EventLoseSkill },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if data:toSkillChange().skillName == "yinyang" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:isMale() then
			player:setGender(sgs.General_Female)
			player:throwAllHandCards()
			if not player:getPile("femaleshiki"):isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName())
				local move = sgs.CardsMoveStruct(player:getPile("femaleshiki"), player, sgs.Player_PlaceHand, reason)
				room:moveCardsAtomic(move, false)
			end
		end
		return false
	end,
}

shayi = sgs.CreateTriggerSkillV2 {
	name = "shayi",
	events = { sgs.Death },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local death = ctx.original_data:toDeath()
		if death.damage and death.damage.from then
			local sharengui = death.damage.from
			if sharengui:getMark("@sharengui") == 0 then
				sharengui:gainMark("@sharengui", 1)
			end
		end
		return false
	end,
}

JiuziCard = sgs.CreateSkillCard {
	name = "JiuziCard",
	skill_name = "Jiuzi",
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName())
	end,
	on_effect = function(self, effect)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
		slash:setSkillName("Jiuzi")
		local room = effect.from:getRoom()
		room:removePlayerMark(effect.from, "@jianding")
		room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
	end,
}

-- 兼容原型：AI 以 "#JiuziCard:.:" 字串發動，需保留 LuaSkillCard 供 Card_Parse 解析；
-- 產卡由 create_card 沿用本卡，filter/on_effect 邏輯不變。
Jiuzivs = sgs.CreateViewAsSkillV2 {
	name = "Jiuzi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@jianding") >= 1
			and player:usedTimes("#JiuziCard") + player:usedTimes("Jiuzi") < player:getHp()
	end,
	create_card = function(skill, request)
		local card = JiuziCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

Jiuzi = sgs.CreateTriggerSkillV2 {
	name = "Jiuzi",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart },
	view_as_skill = Jiuzivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addPlayerMark(player, "@jianding", 9)
		return false
	end,
}

sinzhisi = sgs.CreateTriggerSkillV2 {
	name = "sinzhisi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	priority = -2,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		local victim = damage.to
		local reason = damage.card
		if victim and victim:getHp() > damage.damage and reason and reason:isKindOf("Slash")
			and victim:getMark("@sharengui") == 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		room:setPlayerProperty(damage.to, "hp", sgs.QVariant(damage.damage))
		return false
	end,
}

local skillList = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sinzhisi") then
	skillList:append(sinzhisi)
end
sgs.Sanguosha:addSkills(skillList)

jialan = sgs.CreateTriggerSkillV2 {
	name = "jialan",
	frequency = sgs.Skill_Wake,
	events = { sgs.Dying },
	priority = 2,
	waked_skills = "sinzhisi",
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getMark("jialan") == 0) then return false end
		local dying_data = data:toDying()
		if dying_data.who:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:doLightbox("$jialanAnimate", 4000)
		player:turnOver()
		player:drawCards(3)
		local recover = sgs.RecoverStruct()
		recover.recover = 3 - player:getHp()
		recover.who = player
		room:recover(player, recover)
		-- local maxhp = player:getMaxHp()
		-- local hp = math.min(3, maxhp)
		-- room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
		if player:hasSkill("yinyang") then
			room:handleAcquireDetachSkills(player, "-yinyang")
		end
		room:changeMaxHpForAwakenSkill(player, 0, skill:objectName())
		room:addPlayerMark(player, "jialan")
		room:handleAcquireDetachSkills(player, "sinzhisi")
		return false
	end,
}

Ryougi_Shiki:addSkill(shayi)
Ryougi_Shiki:addSkill(shikistart)
Ryougi_Shiki:addSkill(yinyang)
Ryougi_Shiki:addSkill(yinyangDetach)
extension:insertRelatedSkills("yinyang", "#yinyangDetach")
extension:insertRelatedSkills("yinyang", "#shikistart")
Ryougi_Shiki:addSkill(jialan)
Ryougi_Shiki:addSkill(Jiuzi)
Ryougi_Shiki:addRelateSkill("sinzhisi")

sgs.LoadTranslationTable {
	["typemoon"] = "型月世界",
	["Ryougi_Shiki"] = "两仪式",
	["&Ryougi_Shiki"] = "两仪式",
	["#Ryougi_Shiki"] = "虚无之壳",
	["cv:Ryougi_Shiki"] = "坂本真绫",
	["designer:Ryougi_Shiki"] = "楼阁寺",
	["illustrator:Ryougi_Shiki"] = "P站",
	["yinyang"] = "阴阳",
	[":yinyang"] = "准备阶段开始时，若你为男性，你可以将所有手牌扣置于武将牌旁，称为“织”，然后你获得所有“式”并转为女性；若你为女性，你可以将所有手牌扣置于武将牌旁，称为“式”，然后你获得所有“织”并转为男性。",
	["$yinyang"] = "没见过的面孔啊，嘛，无所谓了。",
	["femaleshiki"] = "式",
	["maleshiki"] = "织",
	["sinzhisi"] = "直死",
	[":sinzhisi"] = "<font color=blue><b>锁定技</b></font>，你使用【杀】对有“杀人鬼”标记的角色造成伤害时，他将直接进入濒死状态。",
	["Jiuzi"] = "九字",
	[":Jiuzi"] = "<font color=red><b>限定技</b></font>，出牌阶段时你可以选择一名角色，视为对他使用一张无距离限制的【杀】。此技能一回合内最多只能使用X次（X为你当前体力值），此技能在游戏中最多只能使用9次。",
	["$Jiuzi"] = "一刀",
	["@jianding"] = "兼定",
	["jialan"] = "伽蓝",
	[":jialan"] = "<font color=purple><b>觉醒技</b></font>，你处于濒死状态时，将你的武将牌翻面摸三张牌并回复至3点体力 ，失去技能“阴阳”，然后获得技能“直死”。",
	["$jialan"] = "只要是活着的东西，就算是神也杀给你看。",
	["recover"] = "回血",
	["shayi"] = "杀意",
	[":shayi"] = "<font color=blue><b>锁定技</b></font>，每当有角色死亡时，凶手获得一枚“杀人鬼”标记",
	["@sharengui"] = "杀人鬼",
	["~Ryougi_Shiki"] = "怎么会失败呢",
	["$jialanAnimate"] = "image=image/animate/Ryougi_Shiki.png",
}

Tohno_Shiki = sgs.General(extension, "Tohno_Shiki", "god", 3, true, true)

Tohnozhisi = sgs.CreateTriggerSkillV2 {
	name = "Tohnozhisi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	priority = -2,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() == sgs.Player_Play and player:getMark("@yanjing") == 1 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:loseAllMarks("@yanjing")
		return false
	end,
}

zhisimod = sgs.CreateTriggerSkillV2 {
	name = "#zhisimod",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	priority = -2,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if damage.to and damage.to:getHp() > damage.damage then
			local reason = damage.card
			if reason and reason:isKindOf("Slash") and player:getMark("@yanjing") == 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, "Tohnozhisi", true)
		room:setPlayerProperty(damage.to, "hp", sgs.QVariant(damage.damage))
		return false
	end,
}

pinxue = sgs.CreateTriggerSkillV2 {
	name = "pinxue",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if player:getPhase() == sgs.Player_Finish and player:getMark("@yanjing") == 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, "pinxue", true)
		room:loseHp(player, 1, true, player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		player:gainMark("@yanjing", 1)
		return false
	end,
}

Tohno_Shiki:addSkill(zhisimod)
Tohno_Shiki:addSkill(Tohnozhisi)
Tohno_Shiki:addSkill(pinxue)
extension:insertRelatedSkills("Tohnozhisi", "#zhisimod")

Nanaya_Shiki = sgs.General(extension, "Nanaya_Shiki", "god", 4, true, true)

jishaCard = sgs.CreateSkillCard {
	name = "jishaCard",
	skill_name = "jisha",
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and to_select:getPile("ren"):length() == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|black"
		judge.good = false
		judge.negative = true
		judge.reason = "jisha"
		judge.who = effect.to
		room:judge(judge)
		if judge:isBad() then
			effect.to:addToPile("ren", judge.card, true)
			room:setFixedDistance(effect.from, effect.to, 1)
		end
	end,
}

-- 兼容原型：AI 以 "#jishaCard:.:" 字串發動，需保留 LuaSkillCard 供 Card_Parse 解析；
-- 產卡由 create_card 沿用本卡，filter/on_effect 邏輯不變。
jisha = sgs.CreateViewAsSkillV2 {
	name = "jisha",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not (player:hasUsed("#jishaCard") or player:hasUsed("jisha"))
	end,
	create_card = function(skill, request)
		local card = jishaCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

jishamod = sgs.CreateTriggerSkillV2 {
	name = "#jishamod",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if not use.from or player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then
			return false
		end
		for _, p in sgs.qlist(use.to) do
			if p:getPile("ren"):length() > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		for _, p in sgs.qlist(use.to) do
			if p:getPile("ren"):length() > 0 then
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(skill:objectName(), _data) then
					ctx.targets:append(p)
				end
			end
		end
		return not ctx.targets:isEmpty()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local accepted = {}
		for i = 0, ctx.targets:length() - 1 do
			accepted[ctx.targets:at(i):objectName()] = true
		end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if p:getPile("ren"):length() > 0 and accepted[p:objectName()] then
				jink_table[index] = 0
				room:broadcastSkillInvoke(skill:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, p:objectName())
				local move = sgs.CardsMoveStruct(p:getPile("ren"), player, sgs.Player_PlaceHand, reason)
				room:moveCardsAtomic(move, false)
				room:removeFixedDistance(player, p, 1)
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end,
}

jishaDetach = sgs.CreateTriggerSkillV2 {
	name = "#jishaDetach",
	events = { sgs.EventPhaseChanging },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if data:toPhaseChange().to == sgs.Player_NotActive then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getPile("ren"):length() > 0 then
				room:broadcastSkillInvoke(skill:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, p:objectName())
				local move = sgs.CardsMoveStruct(p:getPile("ren"), p, sgs.Player_PlaceHand, reason)
				room:moveCardsAtomic(move, false)
				room:removeFixedDistance(player, p, 1)
			end
		end
		return false
	end,
}

Nanaya_Shiki:addSkill(jisha)
Nanaya_Shiki:addSkill(jishamod)
Nanaya_Shiki:addSkill(jishaDetach)
extension:insertRelatedSkills("jisha", "#jishamod")
extension:insertRelatedSkills("jisha", "#jishaDetach")

shiki = sgs.General(extension, "shiki", "god", 3, true, false)

kaiyan = sgs.CreateTriggerSkillV2 {
	name = "kaiyan",
	frequency = sgs.Skill_Wake,
	events = { sgs.Dying },
	priority = 2,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local dying_data = data:toDying()
		if dying_data.who:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local isSecondaryHero = (player:getGeneralName() ~= "shiki")
		room:broadcastSkillInvoke(skill:objectName())
		room:doLightbox("$kaiyanAnimate", 4000)
		room:changeHero(player, "Tohno_Shiki", true, true, isSecondaryHero, true)
		player:gainMark("@yanjing", 1)
		room:setPlayerFlag(player, "-Global_Dying")
		local currentdying = room:getTag("CurrentDying"):toStringList()
		table.removeOne(currentdying, player:objectName())
		room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
		return false
	end,
}

fanzhuan = sgs.CreateTriggerSkillV2 {
	name = "fanzhuan",
	frequency = sgs.Skill_Wake,
	events = { sgs.Death },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName()
			and death.damage and death.damage.from == player then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local isSecondaryHero = (player:getGeneralName() ~= "shiki")
		room:broadcastSkillInvoke(skill:objectName())
		room:doLightbox("$fanzhuanAnimate", 4000)
		room:changeHero(player, "Nanaya_Shiki", true, true, isSecondaryHero, true)
		return false
	end,
}

shiki:addSkill(kaiyan)
shiki:addSkill(fanzhuan)

sgs.LoadTranslationTable {
	["shiki"] = "日常志贵",
	["&shiki"] = "日常志贵",
	["#shiki"] = "推土机",
	["cv:shiki"] = "铃村健一",
	["designer:shiki"] = "楼阁寺",
	["illustrator:shiki"] = "P站",
	["Tohno_Shiki"] = "远野志贵",
	["#Tohno_Shiki"] = "十七分割",
	["Tohnozhisi"] = "直死",
	[":Tohnozhisi"] = "出牌阶段开始时，你可以选择发动技能“直死”。若如此做，本回合你使用【杀】对其他角色造成伤害时，其将直接进入濒死状态。",
	["$Tohnozhisi"] = "全力以赴地上了",
	["@yanjing"] = "眼镜",
	["pinxue"] = "贫血",
	[":pinxue"] = "<font color=blue><b>锁定技</b></font>，回合结束阶段结束时，若本回合内，你发动过技能“直死”，你流失一点体力。",
	["$pinxue"] = "还能行",
	["~Tohno_Shiki"] = "啊",
	["Nanaya_Shiki"] = "七夜志贵",
	["#Nanaya_Shiki"] = "杀人鬼",
	["jisha"] = "极杀",
	[":jisha"] = "<font color=green><b>阶段技</b></font>，你令一名角色进行判定：若结果为黑色，你将判定牌扣置于其武将牌旁，称为“刃”，扣有“刃”牌的该武将与你的距离为1。你可以使该武将无法使用【闪】响应你打出的【杀】，若如此做，当此【杀】对其造成伤害时，你将获得其”刃“牌。 你的回合结束时，该武将获得其武将牌上的“刃”牌。",
	["$jisha"] = "来厮杀吧。",
	["#jishamod"] = "极杀",
	["ren"] = "刃",
	["~Nanaya_Shiki"] = "啊、以前就很想和你两人相斗一次的。现在结果也有了，我已经够熟练了。就是说，以后也只可能会是这种结果了吧。",
	["kaiyan"] = "开眼",
	[":kaiyan"] = "<font color=purple><b>觉醒技</b></font>，你处于濒死状态时，你将变为“远野志贵”。",
	["$kaiyan"] = "想打的话，我来做你的对手。",
	["fanzhuan"] = "反转",
	[":fanzhuan"] = "<font color=purple><b>觉醒技</b></font>，当你杀死了一名角色后，你将变为“七夜志贵”。",
	["$fanzhuan"] = "安心地消失吧志贵，你的继任人会由我来当的。",
	["$kaiyanAnimate"] = "image=image/animate/Tohno_Shiki.png",
	["$fanzhuanAnimate"] = "image=image/animate/Nanaya_Shiki.png",
}
return { extension }
