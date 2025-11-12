module("extensions.new", package.seeall)
extension = sgs.Package("new")
----华丽的分割线
luayiheng = sgs.General(extension, "luayiheng", "qun", 3, true)

lualilian = sgs.CreateTriggerSkill { --新神杀已实现
	name = "lualilian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()                                       --获取伤害结构体
		if (not room:askForSkillInvoke(player, "lualilian")) then return false end --
		room:broadcastSkillInvoke("lualilian")                               --音效 OK 				
		for var = 1, damage.damage, 1 do
			local choice = room:askForChoice(player, self:objectName(), "luayihengmopai+luayihengturn")
			if choice == "luayihengmopai" then --选择1
				local fangzhu = sgs.Sanguosha:getTriggerSkill("yiji")
				if fangzhu then
					room:notifySkillInvoked(player, self:objectName())
					fangzhu:trigger(event, room, player, data)
				end
			end
			if choice == "luayihengturn" then ---选择2
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "lualilian")
				target:turnOver()
			end
			return false
		end
	end
}
luawu_card = sgs.CreateSkillCard { --限定技,新神杀已实现
	name = "luawu",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		local selfplayer = source
		selfplayer:loseMark("@luawu_mark")
		local b = true
		for var = 1, 2, 1 do
			local id_t = room:drawCard()
			local cd_t = sgs.Sanguosha:getCard(id_t)
			room:moveCardTo(cd_t, selfplayer, sgs.Player_DiscardPile, true)
			room:throwCard(cd_t, selfplayer)
			if not cd_t:isBlack() then b = false end
		end
		if not b then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
			room:broadcastSkillInvoke("luawu_trs") --音效  OK
			if p:getHp() <= 1 then
				p:turnOver()
				room:handleAcquireDetachSkills(selfplayer, "wansha")
				room:loseHp(p, 1)
				p:throwAllEquips()
				room:handleAcquireDetachSkills(selfplayer, "-wansha")
				--room:loseMaxHp(p,1)
			else
				room:loseMaxHp(p, 1)
				room:loseHp(p, 1)
			end
		end
	end,
}

luawu_vs = sgs.CreateViewAsSkill {
	name = "luawu_vs",
	n = 0,
	--view_filter=function(self, selected, to_select)
	--return true
	--end,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local a_luawu_card = luawu_card:clone()
		--a!!_card:addSubcard(cards[1])
		a_luawu_card:setSkillName(self:objectName())
		return a_luawu_card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@luawu_mark") >= 1
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

luawu_trs = sgs.CreateTriggerSkill {
	name = "luawu_trs",
	view_as_skill = luawu_vs,
	events = {},
	frequency = sgs.Skill_Limited,
	limit_mark = "@luawu_mark",
	on_trigger = function(self, event, player, data)
	end,

}
luajuemou = sgs.CreateTriggerSkill { --觉醒 可实现
	name = "luajuemou",
	frequency = sgs.Skill_Wake,
	priority = 3,
	events = { sgs.EventPhaseStart },
	--[[can_trigger=function(self,player)
                return player:hasSkill(self:objectName()) and (player:getMark("luajuemou")==0) and player:getPhase() == sgs.Player_Start and player:isWounded()
        end,]]
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.from = player
		log.type = "#luaxiaoxi"
		room:sendLog(log)
		room:broadcastSkillInvoke("luajuemou") --音效  ok
		local choice = room:askForChoice(player, self:objectName(), "luajuemouHp+luajuemouCd")
		if choice == "luajuemouHp" then
			room:recover(player, sgs.RecoverStruct(player))
		end
		if choice == "luajuemouCd" then
			player:drawCards(2)
		end
		if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
			room:addPlayerMark(player, self:objectName())
			room:handleAcquireDetachSkills(player, "lualveji_vs")
			return false
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		return player:isWounded()
	end,
}
lualveji_card = sgs.CreateSkillCard { --略计
	name = "lualveji",
	target_fixed = true,
	will_throw = true,
	once = true,
	on_use = function(self, room, source, targets)
		local selfplayer = source
		local card_ids = room:getNCards(3)
		room:loseHp(selfplayer, 1)
		if selfplayer:isAlive() then
			for var = 1, 3, 1 do
				room:broadcastSkillInvoke("lualveji_vs") --音效  ok
				local cd_id
				if card_ids:length() == 1 then
					cd_id = card_ids:first()
				else
					room:fillAG(card_ids, selfplayer)

					cd_id = room:askForAG(selfplayer, card_ids, false, "lualveji")
					--if cd_id == -1 then return end
				end

				if sgs.Sanguosha:getCard(cd_id):isBlack() then
					room:setPlayerFlag(selfplayer, "lualveji_vsblack")
				end
				local choice = room:askForChoice(selfplayer, self:objectName(), "lualvejiFZ+lualvejiQZ")

				room:setPlayerFlag(selfplayer, "-lualveji_vsblack")
				if choice == "lualvejiQZ" then
					room:moveCardTo(sgs.Sanguosha:getCard(cd_id), selfplayer, sgs.Player_PlaceHand, true)
					card_ids:removeOne(cd_id)
					room:clearAG(selfplayer)
				else
					--room:moveCardTo(sgs.Sanguosha:getCard(cd_id), selfplayer, sgs.Player_DrawPile, true)
					room:moveCardTo(sgs.Sanguosha:getCard(cd_id), selfplayer, sgs.Player_DrawPile)
					card_ids:removeOne(cd_id)
					room:clearAG(selfplayer)
				end
				if not selfplayer:isAlive() then
					break
				end
			end
		end
	end
}

lualveji_vs = sgs.CreateViewAsSkill {
	name = "lualveji_vs",
	n = 0,
	--view_filter=function(self, selected, to_select)
	--return true
	--end,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local a_lualveji_card = lualveji_card:clone()
		--a!!_card:addSubcard(cards[1])
		a_lualveji_card:setSkillName(self:objectName())
		return a_lualveji_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lualveji")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
local skill = sgs.Sanguosha:getSkill("lualveji_vs")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(lualveji_vs)
	sgs.Sanguosha:addSkills(skillList)
end
luayiheng:addSkill(lualilian)
luayiheng:addSkill(luawu_trs)
luayiheng:addSkill(luajuemou)
luayiheng:addRelateSkill("lualveji_vs")
luayiheng:addRelateSkill("wansha")
sgs.LoadTranslationTable {
	["luayiheng"] = "伊衡",


	["lualvejiFZ"] = "放置于卡牌堆顶",
	["lualvejiQZ"] = "加入于你的手牌",

	["lualveji"] = "略计",
	["lualveji_vs"] = "略计",
	["Hp"] = "恢复一点体力",
	["#luaxiaoxi"] = "%from 已受伤，触发了觉醒技<font color='yellow'>【绝谋】</font>",
	["luajuemou"] = "绝谋",
	["$lualilian"] = "一发不可迁，玄之斗全身",
	["$luawu_trs"] = "以地为盘，以兵为棋，布局之间，颠倒阴阳",
	["$luajuemou"] = "知凶定吉，断死衍生",
	["$lualveji_vs"] = "呵呵一切尽在掌握。",
	["@luawu_mark"] = "鶩",
	["luawu"] = "鶩群",
	[":lualilian"] = "每当你受到一次伤害你可以选择一项：1.选择一名其他角色，其翻面 2.发动“遗计”。 ",
	[":lualveji_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去一点体力，然后观看牌堆顶的三张牌并以任意顺序将其置于牌堆顶或加入手牌。",
	["luawu_trs"] = "鶩群",
	["lualilian"] = "搦略",

	["luayihengmopai"] = "发动“遗计”",
	["luayihengturn"] = "选择一名其他角色，其翻面",
	["luajuemouHp"] = "回复1点体力",
	["luajuemouCd"] = "摸两张牌",

	[":luajuemou"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你已受伤，你选择一项：1．回复1点体力；2．摸两张牌。然后获得“略计”。",
	[":luawu_trs"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以亮出牌堆顶2张牌，若皆为黑色则所有其他角色：若其的体力值不大于1，则其翻面，然后进入濒死状态，在此时视为你拥有技能“完杀”；若其的体力值大于1：其减去1点体力上限，然后流失一点体力。",
	["~luayiheng"] = "听潮而圆，听信而既矣",
	["#luayiheng"] = "谋定而动",
	["designer:luayiheng"] = "程春阳",
}
luazhangjiao = sgs.General(extension, "luazhangjiao", "god", 3, true)

luafan = sgs.CreateTriggerSkill {
	name = "luafan",
	events = { sgs.CardResponded, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local jink
		if event == sgs.CardResponded then
            local card = data:toCardResponse().m_card
            if card and card:isKindOf("Jink") then
				jink = card
			end
		elseif event == sgs.CardUsed then
			local card = data:toCardUse().card
            if card and card:isKindOf("Jink") then
				jink = card
			end
		end
		local room = player:getRoom()
		if jink then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "luafan-invoke",
				true, true)
			if target then
				room:broadcastSkillInvoke("luafan")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade|2~9"
				judge.good = false
				judge.negative = true
				judge.reason = self:objectName()
				judge.who = target
				room:judge(judge)
				if judge:isBad() then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
				else
					player:obtainCard(jink)
				end
			end
		end
		return false
	end
}




luaqiyi = sgs.CreateViewAsSkill {
	name = "luaqiyi",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return true
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("jink", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "jink")
	end
}



luaguidao = sgs.CreateTriggerSkill {
	name = "luaguidao",
	events = { sgs.AskForRetrial },
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		local prompt_list = {
			"@luaguidao",
			judge.who:objectName(),
			self:objectName(),
			judge.reason,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local room = player:getRoom()
		local card = room:askForCard(player, ".|.|.|.|.", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
		end
		return false
	end,
}
luaxumou = sgs.CreateTriggerSkill { --蓄谋 实现
	name = "luaxumou",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.from = player
		log.type = "#luaxumou"
		room:sendLog(log)

		room:broadcastSkillInvoke("luaxumou") --音效  ok
		room:addPlayerMark(player, "luaxumou")
		if room:changeMaxHpForAwakenSkill(player, 1, self:objectName()) then
			player:drawCards(2)
			room:handleAcquireDetachSkills(player, "luaguidao")
			room:handleAcquireDetachSkills(player, "luaqiyi")
		end

		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHp() < player:getHp() then return false end
		end
		return true
	end,
}



local skill = sgs.Sanguosha:getSkill("luaqiyi")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(luaqiyi)
	sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("luaguidao")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(luaguidao)
	sgs.Sanguosha:addSkills(skillList)
end
luazhangjiao:addSkill(luafan)
luazhangjiao:addSkill(luaxumou)
luazhangjiao:addRelateSkill("luaqiyi")
luazhangjiao:addRelateSkill("luaguidao")

sgs.LoadTranslationTable {
	["luazhangjiao"] = "☆张角",
	["luafan"] = "天雷",
	["$luafan"] = "雷公助我!",
	["$luafan1"] = "雷公助我!",
	["$luaguidao1"] = "天下大事为我所控",
	["luaxumou"] = "天公",
	["$luaxumou1"] = "苍天已死，黄天当立",
	["$luaxumou"] = "苍天已死，黄天当立",
	["luatianzhu"] = "天助",
	["luaqiyi"] = "起义",
	["luaguidao_effect"] = "天道",
	["$luaguidao"] = "天下大事，为我所控",
	["luaguidao"] = "天道",
	["#luaxumou"] = "%from 体力值为全场最小，触发了觉醒技<font color='yellow'>【天公】</font>\
%from 增加了一点体力上限",


	[":luaqiyi"] = "你可以将两张相同花色的手牌当【闪】使用或打出。",
	[":luaguidao"] = "任意判定牌生效前你可以用你的一张牌替换之",
	["~luaguidao"] = "任意判定牌生效前你可以用你的一张牌替换之",
	["@luaguidao"] = "请选择一张牌",
	[":luaxumou"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为场上最少（或之一），你加1点体力上限，然后摸两张牌，获得“天道”和“起义”",
	[":luafan"] = "当你使用或打出【闪】时，你可以令一名其他角色判定，若结果为♠2-9，你对该角色造成2点雷电伤害，否则你可以获得你所使用或打出的【闪】。",
	[":@luafan"] = "是否对一名角色进行判定？",
	["luafan-invoke"] = "你可以发动“天雷”<br> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["~luazhangjiao"] = "黄天，也死了··",
	["#luazhangjiao"] = "天公将军",
	["designer:luazhangjiao"] = "程春阳",
}
luaqiqi = sgs.General(extension, "luaqiqi", "wei", 4, true) --实现
luajiejiangcard = sgs.CreateSkillCard {
	name = "luajiejiang",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select)
		if (#targets > 1) then return false end

		if (to_select == self) then return false end

		return not to_select:isAllNude()
	end,

	on_effect = function(self, effect)
		local from = effect.from
		local to = effect.to
		local room = to:getRoom()

		room:broadcastSkillInvoke("tuxi") --音效  ok

		local card_id = room:askForCardChosen(from, to, "hej", "luajiejiang2_main")
		--local card = sgs.Sanguosha:getCard(card_id)
		--room:moveCardTo(card, from, sgs.Player_PlaceHand, false)
		room:obtainCard(from, card_id)
	end,
}

luajiejiangVS = sgs.CreateViewAsSkill
	{
		name = "luajiejiang",
		n = 0,

		view_as = function()
			return luajiejiangcard:clone()
		end,

		enabled_at_play = function()
			return false
		end,

		enabled_at_response = function(self, player, pattern)
			return pattern == "@@luajiejiang"
		end
	}



luajiejiang = sgs.CreateTriggerSkill { --溃袭
	name = "luajiejiang",
	view_as_skill = luajiejiangVS,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if not (room:askForSkillInvoke(player, "luajiejiang", data)) then return false end
			local judge = sgs.JudgeStruct()
			judge.pattern = "."
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if (judge:isGood()) then
				player:obtainCard(judge.card)
				room:broadcastSkillInvoke("luajiejiang") --音效  ok

				if judge.card:isRed() then
					local cd_t = room:askForUseCard(player, "@@luajiejiang", "@luajiejiang2_card")
				else
					local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"luajiejiang-invoke")
					if to then
						to:turnOver()
						if (to:getHandcardNum() >= player:getHp()) then
							room:loseHp(to, 1)
						end
					end
				end
			end
			return true
		end
	end,
}


luaqiqi:addSkill(luajiejiang)
sgs.LoadTranslationTable {
	["luaqiqi"] = "何进",
	["luajiejiang"] = "溃袭",
	[":luajiejiang"] = "摸牌阶段开始时，你可以放弃摸牌并进行一次判定，当判定牌生效后，你获得之，若结果为红色：则你可以选择1-2名角色获得这些角色的区域内的一张牌\
；黑色：则你选择一名其他角色，其翻面，若该角色的手牌数大于或等于你的体力值，则其失去一点体力。",
	["luajiejiang2_main"] = "溃袭",
	["@luajiejiang2_card"] = "请选择1-2名角色获得他们的区域内的一张牌。",
	["luajiejiang2"] = "溃袭",
	["luajiejiang-invoke"] = "你可以发动“溃袭”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["~luajiejiang"] = "选择1-2名角色",
	["~luaqiqi"] = "哈哈···",
	["#luaqiqi"] = "先拔头筹",
	["designer:luaqiqi"] = "程春阳",
	["$luajiejiang"] = "谁敢拦我！",
}
luazg = sgs.General(extension, "luazg", "shu", 2, true) --皆实现
luaxiuyang = sgs.CreateTriggerSkill {
	name = "luaxiuyang",
	events = { sgs.GameStart, sgs.TurnedOver },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if (player:getHp() > 0) then
				room:broadcastSkillInvoke("luaxiuyang") --音效  ok
				room:setPlayerMark(player, "&luaxiuyang+kongcheng+kanpo", 1)
				room:handleAcquireDetachSkills(player, "kongcheng")
				room:handleAcquireDetachSkills(player, "kanpo")
			end
		end
		if event == sgs.TurnedOver then
			if player:faceUp() then         --正面朝上
				room:broadcastSkillInvoke("luaxiuyang") --音效  ok

				room:handleAcquireDetachSkills(player, "-wuyan")
				room:handleAcquireDetachSkills(player, "-bazhen")
				room:handleAcquireDetachSkills(player, "kanpo")
				room:handleAcquireDetachSkills(player, "kongcheng")
				room:setPlayerMark(player, "&luaxiuyang+kongcheng+kanpo", 1)
				room:setPlayerMark(player, "&luaxiuyang+wuyan+bazhen", 0)
			else                            --背面朝上
				room:broadcastSkillInvoke("luaxiuyang") --音效
				room:setPlayerMark(player, "&luaxiuyang+kongcheng+kanpo", 0)
				room:setPlayerMark(player, "&luaxiuyang+wuyan+bazhen", 1)
				room:handleAcquireDetachSkills(player, "-kongcheng")
				room:handleAcquireDetachSkills(player, "-kanpo")
				room:handleAcquireDetachSkills(player, "wuyan")
				room:handleAcquireDetachSkills(player, "bazhen")
			end
		end
	end
}
luamoucecard = sgs.CreateSkillCard { --实现
	name = "luamouce",
	once = true,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:isWounded()
	end,
	on_effect = function(self, effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()

		room:broadcastSkillInvoke("mouce") --音效  ok

		room:throwCard(room:askForCardChosen(from, to, "hej", self:objectName()), to)
		room:loseHp(to, 2)
		room:setPlayerFlag(from, "luamouce_used")
		from:turnOver()
	end,
}
luamouce = sgs.CreateViewAsSkill {
	name = "luamouce",
	n = 0,
	view_filter = function()
		return false
	end,
	view_as = function(self, cards)
		return luamoucecard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luamouce")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}
luaJC = sgs.CreateTriggerSkill {
	name = "luaJC",
	frequency = sgs.Skill_Limited,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasSkill(self:objectName()) then return false end
		local dying = data:toDying()
		if dying.who and dying.who:objectName() ~= player:objectName() then
			return false
		end
		if not room:askForSkillInvoke(player, self:objectName()) then return false end

		room:broadcastSkillInvoke("luaJC") --音效  	ok	

		local target1 = room:askForPlayerChosen(player, room:getOtherPlayers(player), "ask_1")
		--target1:gainMark("@distance_from")
		room:addPlayerMark(target1, "&luaJC")
		target1:drawCards(2)
		local target2 = room:askForPlayerChosen(player, room:getOtherPlayers(target1), "ask_2")
		--target2:gainMark("@distance")
		room:addPlayerMark(target2, "&luaJC_target")
		room:setFixedDistance(target1, target2, 1);
		room:killPlayer(player)
	end

}

luazg:addSkill(luamouce)
luazg:addSkill(luaxiuyang)
luazg:addSkill(luaJC)
luazg:addRelateSkill("kanpo")
luazg:addRelateSkill("kongcheng")
luazg:addRelateSkill("wuyan")
luazg:addRelateSkill("bazhen")

sgs.LoadTranslationTable {
	["luazg"] = "☆诸葛亮",
	["luamouce"] = "攻破",
	["luaxiuyang"] = "无隙",
	["@distance"] = "遗托to",
	["@distance_from"] = "遗托from",
	["ask_1"] = "这名角色可以摸2张牌,然后由你指定另一名角色,则你指定的第一名角色和第二名角色的距离始终视为1。",
	["ask_2"] = "请指定另一名角色",
	["luaJC_target"] = "遗托目标",
	["luaJC"] = "遗托",
	["Distance"] = "遗托from",
	[":luamouce"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一名已受伤的其他角色区域内的一张牌，然后该角色流失2点体力，若如此做你需将你的武将牌翻面。",
	["$luamouce"] = "巧变制敌，谋定而动",
	["$luaxiuyang"] = "我，永不背弃!",
	["$luaJC"] = "知天易,逆天难。",
	[":luaxiuyang"] = "<font color=\"blue\"><b>锁定技，</b></font>当你的武将正面朝上时你拥有“空城”“看破”，背面朝上时你拥有“无言”“八阵”。",
	[":luaJC"] = "<font color=\"red\"><b>限定技，</b></font>当你处于濒死状态时，你可以放弃求桃，然后指定两名角色则:第一名角色摸两张牌，第一名角色和第二名角色的距离始终为1。",
	["~luazg"] = "天命有旋转，地星而应之。",
	["#luazg"] = "迟暮的丞相",
	["designer:luazg"] = "程春阳",
}
luaguanyu = sgs.General(extension, "luaguanyu", "shu", 4, true) --实现
luaqinglong = sgs.CreateTriggerSkill
	{
		name = "luaqinglong",
		events = { sgs.EventPhaseStart, sgs.Damage },
		frequency = sgs.Skill_Compulsory,
		--view_as_skill = luaqinglong,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			local card = damage.card
			if player:getPhase() == sgs.Player_Start then
				local blade = nil
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					for _, cd in sgs.qlist(p:getCards("hej")) do
						if cd:isKindOf("Blade") then
							blade = cd
							break
						end
					end
				end
				if blade ~= nil then
					room:broadcastSkillInvoke("luaqinglong") --音效

					room:moveCardTo(blade, player, sgs.Player_PlaceHand, true)
				end
			elseif (event == sgs.Damage and player:hasWeapon("Blade") and card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)) then
				room:broadcastSkillInvoke("luaqinglong") --音效

				local x = player:getLostHp()
				player:drawCards(x)
				room:loseHp(damage.to)
				return false
			end
		end,
	}
luawuwu = sgs.CreateProhibitSkill { --无误
	name = "luawuwu",
	is_prohibited = function(self, from, to, card)
		if (to:hasSkill(self:objectName())) then
			return (card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("Collateral"))
		end
	end,
}

chitunew = sgs.CreateDistanceSkill
	{
		name = "chitunew",
		correct_func = function(self, from, to)
			if from:hasSkill("Chitu") then return -1 end
		end,
	}


luaxiaoyong = sgs.CreateTriggerSkill
	{
		name = "luaxiaoyong",
		events = { sgs.EventPhaseStart, sgs.GameStart },
		frequency = sgs.Skill_Compulsory,
		view_as_skill = luaxiaoyong,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) or (event == sgs.GameStart)) then
				room:broadcastSkillInvoke("luaxiaoyong") --音效  ok

				room:handleAcquireDetachSkills(player, "luawuwu")
				room:handleAcquireDetachSkills(player, "-wusheng")
				room:handleAcquireDetachSkills(player, "-chitunew")
				room:setPlayerMark(player, "&luaxiaoyong+wusheng+chitunew", 0)
				room:setPlayerMark(player, "&luaxiaoyong+luawuwu", 1)
			elseif (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) then
				room:broadcastSkillInvoke("luaxiaoyong") --音效  ok
				room:setPlayerMark(player, "&luaxiaoyong+luawuwu", 0)
				room:setPlayerMark(player, "&luaxiaoyong+wusheng+chitunew", 1)
				room:handleAcquireDetachSkills(player, "-luawuwu")
				room:handleAcquireDetachSkills(player, "wusheng")
				room:handleAcquireDetachSkills(player, "chitunew")
				return false
			end
		end

	}

local skill = sgs.Sanguosha:getSkill("luawuwu")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(luawuwu)
	sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("chitunew")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(chitunew)
	sgs.Sanguosha:addSkills(skillList)
end

luaguanyu:addSkill(luaxiaoyong)
luaguanyu:addSkill(luaqinglong)
luaguanyu:addRelateSkill("wusheng")
luaguanyu:addRelateSkill("chitunew")
luaguanyu:addRelateSkill("luawuwu")
sgs.LoadTranslationTable {
	["luaguanyu"] = "☆关羽",
	[":luaqinglong"] = "<font color=\"blue\"><b>锁定技，</b></font>回合开始阶段，若场上有 <font color=\"green\"><b>【青龙偃月刀】</b></font>，你获得之，当你拥有<font color=\"green\"><b>【青龙偃月刀】</b></font>你使用【杀】对目标角色造成伤害后，其流失1点体力，然后你摸X张牌(x为你的已损体力值)。\
★只要<font color=\"green\"><b>【青龙偃月刀】</b></font>出现在某个玩家都手中，或出现在其他角色的判定区／装备区里你都可以在回合开始阶段加入你的手牌。",
	[":luaxiaoyong"] = "<font color=\"blue\"><b>锁定技，</b></font>在你的回合內你拥有“武圣”和“赤兔”；在你的回合外，你拥有技能“无误”，直到你的下一个回合开始阶段。",
	[":luawuwu"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能成为【顺手牵羊】【过河拆桥】【借刀杀人】的目标。",
	[":chitunew"] = "【赤兔】 装备牌·坐骑\
坐骑效果：<font color=\"blue\"><b>锁定技，</b></font>你计算的与其他角色的距离-1。",
	["luaqinglong"] = "青龙",
	["chitunew"] = "赤兔",
	["$luaqinglong"] = "取汝狗头，有如探囊取物！",
	["luawuwu"] = "无误",
	["luaxiaoyong"] = "斩将",
	["$luaxiaoyong"] = "还不速速领死！",
	["designer:luaguanyu"] = "程春阳",
	["~luaguanyu"] = "什么!此地名叫麦城?",
	["#luaguanyu"] = "过关斩将",
}
luachenggeng = sgs.General(extension, "luachenggeng", "shu", 4, true) --实现
luazhenshe = sgs.CreateTriggerSkill {                                 --震慑
	name = "luazhenshe",
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local y = player:getLostHp()
			if damage.card and damage.card:isKindOf("Slash") and not damage.card:hasFlag("luazhenshe_double") then
				if damage.to and damage.to:isAlive() then
					if player:canPindian(damage.to) or damage.to:isKongcheng() then
					else
						return
					end


					if not room:askForSkillInvoke(player, self:objectName(), data) then return end
					room:broadcastSkillInvoke("luazhenshe") --音效  ok
					local log1 = sgs.LogMessage()
					log1.type = "$luazhenshe1"
					room:sendLog(log1)
					if player:canPindian(damage.to) then
						local success = player:pindian(damage.to, "luazhenshe", nil)
						if not success then
							player:throwAllEquips()
							player:drawCards(y + 1)
							if player:faceUp() then
								player:turnOver()
							end
							return
						end
					elseif not damage.to:isKongcheng() then
						return
					end

					log1.type = "$luazhenshe2"
					room:sendLog(log1)
					room:setPlayerFlag(damage.to, "luazhenshe")
					room:setCardFlag(damage.card, "luazhenshe_double")
				end
			end
		end
	end
}

luazhensheDouble = sgs.CreateTriggerSkill {
	name = "#luazhensheDouble",
	events = sgs.CardFinished,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.card:hasFlag("luazhenshe_double") then return false end
		room:setCardFlag(use.card, "-luazhenshe_double")
		--if use.card:hasPreAction() then end
		if use.card:isKindOf("Slash") then --【杀】需要单独处理
			-- for _, p in sgs.qlist(use.to) do
			-- 	if p:hasFlag("luazhenshe") then
			-- 		room:setPlayerFlag(p, "-luazhenshe")
			-- 		local se = sgs.SlashEffectStruct()
			-- 		se.from = use.from
			-- 		se.to = p
			-- 		se.slash = use.card
			-- 		se.nullified = table.contains(use.nullified_list, "_ALL_TARGETS") or
			-- 			table.contains(use.nullified_list, p:objectName())
			-- 		se.no_offset = table.contains(use.no_offset_list, "_ALL_TARGETS") or
			-- 			table.contains(use.no_offset_list, p:objectName())
			-- 		se.no_respond = table.contains(use.no_respond_list, "_ALL_TARGETS") or
			-- 			table.contains(use.no_respond_list, p:objectName())
			-- 		se.multiple = use.to:length() > 1
			-- 		se.nature = sgs.DamageStruct_Normal
			-- 		if use.card:objectName() == "fire_slash" then
			-- 			se.nature = sgs.DamageStruct_Fire
			-- 		elseif use.card:objectName() == "thunder_slash" then
			-- 			se.nature = sgs.DamageStruct_Thunder
			-- 		elseif use.card:objectName() == "ice_slash" then
			-- 			se.nature = sgs.DamageStruct_Ice
			-- 		end
			-- 		if use.from:getMark("drank") > 0 then
			-- 			room:setCardFlag(use.card, "drank")
			-- 			use.card:setTag("drank", sgs.QVariant(use.from:getMark("drank")))
			-- 		end
			-- 		se.drank = use.card:getTag("drank"):toInt()
			-- 		room:slashEffect(se)
			-- 	end
			-- end
			use.card:use(room,use.from,use.to)
			player:drawCards(1)
		end
		return false
	end
}




luaqibing = sgs.CreateTriggerSkill {
	name = "luaqibing",
	events = { sgs.CardFinished, sgs.Predamage },
	priority = 2,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--local siyeliuyue=room:findPlayerBySkillName(self:objectName())		
		local log = sgs.LogMessage()
		log.from = player
		if (event == sgs.CardFinished) and (player:getPhase() == sgs.Player_Play) then
			local use = data:toCardUse()
			local card = use.card
			if use.from:objectName() ~= player:objectName() then return false end
			if player:getPile("luaqibingcards"):length() == 3 then return false end
			if player:hasFlag("luaqibing_source") then return false end
			if (room:askForSkillInvoke(player, "@luaqibing", data) ~= true) then return false end
			--room:setPlayerFlag(player,"luaqibing_source")
			local x = 0
			if card:isVirtualCard() then
				for _, id in sgs.qlist(card:getSubcards()) do
					if room:CardInPlace(sgs.Sanguosha:getCard(id), sgs.Player_DiscardPile) then
						player:addToPile("luaqibingcards", id, true)
						x = x + 1
					end
				end
			else
				if room:CardInPlace(card, sgs.Player_DiscardPile) then
					player:addToPile("luaqibingcards", card:getEffectiveId(), true)
					x = x + 1
				end
			end
			--room:setPlayerFlag(player,"-luaqibing_source")
			if x > 0 then
				local log = sgs.LogMessage()
				log.type = "#luaqibing"
				log.from = player
				room:sendLog(log)
			end
			--return true		
		elseif event == sgs.Predamage then
			local damage = data:toDamage()
			if not damage.card:isKindOf("Slash") then return false end
			if not player:getPile("luaqibingcards"):isEmpty() and room:askForSkillInvoke(player, "luaqibing", data) then
				room:broadcastSkillInvoke("luaqibing") --音效  ok
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(player:getPile("luaqibingcards"):first()), reason, nil)

				--room:throwCard(player:getPile("luaqibingcards"):first(),player)
				--room:obtainCard(player, card_id)
				local log = sgs.LogMessage()
				log.type = "#luaqibingbuff"
				log.from = player
				log.to:append(damage.to)
				log.arg = tonumber(damage.damage)
				log.arg2 = tonumber(damage.damage + 1)
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
}
luachenggeng:addSkill(luaqibing)
luachenggeng:addSkill(luazhensheDouble)
luachenggeng:addSkill(luazhenshe)
extension:insertRelatedSkills("luazhenshe", "#luazhensheDouble")
sgs.LoadTranslationTable {
	["luachenggeng"] = "程庚",
	["luazhenshe"] = "震慑",
	["luaqibingcards"] = "奇兵",
	["$luazhenshe1"] = "贼将休走，可敢与我一战！",
	["$luazhenshe2"] = "陷阵杀敌，一马当先",
	["luaqibing"] = "埋伏",
	["@luaqibing"] = "【埋伏】；将你使用的牌置于【奇兵牌】区？",
	["$luaqibing"] = "攻其不意，掩其无备。",
	["#luaqibing"] = "由于%from 的技能【埋伏】，它使用的牌被加入【奇兵牌】区",
	["#luaqibingbuff"] = "%from 的技能 <font color='yellow'><b>【埋伏】</b></font> 被触发，此【杀】伤害+1",
	--[[[":luazhenshe"]=" 每当你使用【杀】对其他角色造成伤害后，你可以选择与对方拼点，若你赢则这张【杀】可以再次对其结算一次，然后你摸一张牌，若你输了则你立刻摸x+1张牌（X为你已损体力值），然后弃掉所有的装备，并将武将翻面。 \
 ★1若对方没有手牌则视为你赢了这次拼点 2再次结算的伤害和上一次杀造成的伤害相同",]]
	[":luazhenshe"] = " 每当你使用【杀】对其他角色造成伤害后，你可以与该角色拼点：若你赢，令此【杀】再次对其结算一次，然后你摸一张牌；若你没赢，你摸x+1张牌（X为你已损体力值），然后弃置所有的装备牌，并将武将翻面。 \
 ★若对方没有手牌则视为你赢了这次拼点",
	[":luaqibing"] = " 出牌阶段，每当你使用了一张牌，你可以选择在其结算完之后把此牌置于武将上称之为“奇兵”；当你使用【杀】对其他角色造成伤害时，你可以随机弃掉一张“奇兵牌”使伤害+1 (奇兵牌不可超过3张).",
	["~luachenggeng"] = "不可能·",
	["#luachenggeng"] = "敌莫敢当",
	["designer:luachenggeng"] = "程春阳",
}

luajiaxu = sgs.General(extension, "luajiaxu", "qun", 3, true) --贾诩
luahuntian_card = sgs.CreateSkillCard
	{                                                         --弃掉4张花色牌，让--1个玩家执行效果
		name = "luahuntian",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select)
			return (#targets < 998)
		end,

		on_effect = function(self, effect)
			local from = effect.from
			local to = effect.to --
			local room = to:getRoom()

			room:broadcastSkillInvoke("luahuntian") --音效 ok


			if (to:getHp() > 1) then
				room:setPlayerFlag(from, "@LHT_used")
				local damage = sgs.DamageStruct()
				damage.from = from
				damage.to = effect.to
				damage.nature = sgs.DamageStruct_Fire
				room:damage(damage)
				if from:canDiscard(to, "he") then
					local to_throw = room:askForCardChosen(from, to, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, to, from);
				end
			else
				room:loseHp(to, 1)
				to:throwAllEquips()
				return false
			end
		end,
	}

luahuntian = sgs.CreateViewAsSkill
	{
		name = "luahuntian",
		n = 5, --

		view_filter = function(self, selected, to_select)
			return (#selected < 5) and (to_select:getSuit() == sgs.Card_Spade)
		end,

		view_as = function(self, cards)
			if #cards ~= 5 then return false end
			new_card = luahuntian_card:clone()
			new_card:addSubcard(cards[1]:getId())
			new_card:addSubcard(cards[2]:getId())
			new_card:addSubcard(cards[3]:getId())
			new_card:addSubcard(cards[4]:getId())
			new_card:addSubcard(cards[5]:getId())
			new_card:setSkillName("luahuntian")
			return new_card
		end,

		enabled_at_play = function(self, player)
			return not player:hasUsed("#luahuntian")
		end,

		enabled_at_response = function()
			return false
		end
	}
luajiaodi = sgs.CreateTriggerSkill {
	name = "luajiaodi",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Frequent,
	--priority
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.to:hasSkill(self:objectName()) then return false end
			if not room:askForSkillInvoke(player, "luajiaodi") then return false end
			room:broadcastSkillInvoke("luajiaodi") --音效
			local x = 3 * damage.damage
			--[[for i=1,x*3,1 do
                local card_Id = room:drawCard()
                local card = sgs.Sanguosha:getCard(card_Id)
                room:moveCardTo(card,nil,sgs.Player_DiscardPile,true)
                if card:getSuit()== sgs.Card_Spade then
                    room:obtainCard(player, card)
                else
                    player:addToPile("luamou", card)
			
				end
			end]]
			local ids = room:getNCards(x, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(),
				nil)
			room:moveCardsAtomic(move, true)
			local card_to_throw = {}
			local card_to_gotback = {}
			for i = 0, x - 1, 1 do
				local id = ids:at(i)
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuit() ~= sgs.Card_Spade then
					table.insert(card_to_throw, id)
				else
					table.insert(card_to_gotback, id)
				end
			end
			if #card_to_throw > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				for _, id in ipairs(card_to_throw) do
					dummy:addSubcard(id)
				end
				player:addToPile("luamou", dummy)
			end
			if #card_to_gotback > 0 then
				local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy2:deleteLater()
				for _, id in ipairs(card_to_gotback) do
					dummy2:addSubcard(id)
				end
				room:obtainCard(player, dummy2)
			end

			if player:getPile("luamou"):length() >= 8 then
				room:loseMaxHp(player, player:getMaxHp() - 1)
				room:handleAcquireDetachSkills(player, "-luajiaodi")
				room:handleAcquireDetachSkills(player, "-luajilue")
				room:handleAcquireDetachSkills(player, "wansha")
				local dummy = sgs.Sanguosha:cloneCard("slash")
				for _, cd in sgs.qlist(player:getPile("luamou")) do
					dummy:addSubcard(sgs.Sanguosha:getCard(cd))
				end
				player:obtainCard(dummy)
				dummy:deleteLater()
			end
		end
	end
}

luajilue = sgs.CreateTriggerSkill {
	name = "luajilue",
	events = { sgs.Damaged },
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and
			target:getPile("luamou"):length() > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 1, x, 1 do
				local choice = room:askForChoice(player, self:objectName(), "c1+c2+c3+c4+c5")
				local skill
				if choice == "c1" then
					skill = sgs.Sanguosha:getTriggerSkill("fankui")
				elseif choice == "c2" then
					skill = sgs.Sanguosha:getTriggerSkill("jieming")
				elseif choice == "c3" then
					skill = sgs.Sanguosha:getTriggerSkill("fangzhu")
				elseif choice == "c4" then
					skill = sgs.Sanguosha:getTriggerSkill("yiji")
				end
				if choice ~= "c5" and skill then
					room:broadcastSkillInvoke("luajilue") --音效
					room:notifySkillInvoked(player, self:objectName())
					local luamous = player:getPile("luamou")
					local card_id
					if luamous:length() == 1 then
						card_id = luamous:first()
					else
						room:fillAG(luamous, player)
						card_id = room:askForAG(player, luamous, false, "luamou")
						room:clearAG()
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(),
						"")
					room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
					--room:throwCard(card_id,player)
					skill:trigger(event, room, player, data)
				end
			end
		end
		return false
	end
}


luaguiwei = sgs.CreateTriggerSkill {
	name = "luaguiwei",
	events = sgs.GameStart,
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if not room:askForSkillInvoke(player, "luaguiwei") then return false end
			room:changeHero(player, "luahuatuo", true, false, player:getGeneral2Name()=="luajiaxu", true)
			-- for _,p in sgs.qlist(room:getAlivePlayers()) do
			--  p:invoke("animate", "lightbox:$luaguiwei")				
			--       end
		end
	end,

}
luajiaxu:addSkill(luajilue)
luajiaxu:addSkill(luahuntian)
luajiaxu:addSkill(luajiaodi)
luajiaxu:addSkill(luaguiwei)
luajiaxu:addRelateSkill("wansha")
sgs.LoadTranslationTable {
	["luajiaxu"] = "☆贾文和",
	["luahuntian"] = "混天",
	["luajiaodi"] = "搅地",
	["luajilue"] = "极略",
	["$luaguiwei"] = "归魏",
	["luaguiwei"] = "归魏",
	["luamou"] = "谋",
	["c1"] = "反馈",
	["c2"] = "节命",
	["c3"] = "放逐",
	["c4"] = "遗计",
	["c5"] = "不发动",
	[":luahuntian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置5张♠牌，然后对任意名角色造成以下效果:1.若其体力值大于1，你对其造成1点火焰伤害，并且你弃置其一张牌. 2.若体力值小于等于1，则其失去一点体力，然后弃置所有装备牌。",
	[":luajiaodi"] = "每当你受到1点伤害后，你可以亮出牌堆顶的三张牌，获得其中的黑桃牌并将其余的牌置于武将牌上，称为“谋”，若“谋”数不小于8，你将体力上限减为1，失去“搅地”和“极略”，获得“完杀”，然后你获得所有“谋”。",
	[":luajilue"] = "每当你受到1点伤害后，你可以将“谋”置入弃牌堆，发动下列技能之一：“反馈”、“放逐”、“节命”、“遗计”",
	[":luaguiwei"] = "<font color=\"red\"><b>限定技，</b></font>游戏开始时，你可以选择变身为SP贾文和，势力为魏。",
	["~luajiaxu"] = "我的时辰…也…到…了……",
	["#luajiaxu"] = "算无遗策",
	["designer:luajiaxu"] = "程春阳",
	["$luahuntian"] = "让这熊熊业火，焚尽你的罪恶！", --配音
	["$luajilue"] = "天意如何，我命由我。", --配音
	["$luajiaodi"] = "你奈我何？", --配音

}
luahuatuo = sgs.General(extension, "luahuatuo", "wei", "3", true, true, false) --隐藏武将(变身将)

luafentian_card = sgs.CreateSkillCard
	{ --<b>限定技</b>,出牌阶段,你可以选择弃掉1张黑桃牌选择对若干名角色造成1点火焰伤害然后让对方弃掉一张牌(以此法照成的伤害没有伤害来源)。
		name = "luafentian",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select)
			return (#targets < 998) --若干名角色
		end,

		on_effect = function(self, effect)
			local from = effect.from
			local to = effect.to --
			local room = from:getRoom()
			from:loseMark("@fentian_mark")
			room:broadcastSkillInvoke("luafentian_trs") --音效
			if (to:isAlive()) then
				local damage = sgs.DamageStruct()
				damage.card = nil
				damage.damage = 1
				damage.from = nil
				damage.to = effect.to
				damage.nature = sgs.DamageStruct_Fire
				room:damage(damage)
				if not to:isNude() then
					room:askForDiscard(to, "luafentian", 1, 1, false)
				end
				return false
			end
		end,
	}
luafentianVS = sgs.CreateViewAsSkill
	{
		name = "luafentian",
		n = 1, --

		view_filter = function(self, selected, to_select)
			return (#selected < 1) and (to_select:getSuit() == sgs.Card_Spade)
		end,

		view_as = function(self, cards)
			if #cards ~= 1 then return false end
			new_card = luafentian_card:clone()
			new_card:addSubcard(cards[1]:getId())
			new_card:setSkillName("luafentian")
			return new_card
		end,

		enabled_at_play = function(self, player)
			return player:getMark("@fentian_mark") > 0
		end,
		enabled_at_response = function(self, player, pattern)
			return false
		end
	}
luafentian = sgs.CreateTriggerSkill {
	name = "luafentian",
	view_as_skill = luafentianVS,
	events = { sgs.GameStart },
	frequency = sgs.Skill_Limited,
	limit_mark = "@fentian_mark",
	--priority
	on_trigger = function(self, event, player, data)
	end,

}








function strcontain(a, b)
	if a == "" then return false end
	local c = a:split("+")
	local k = false
	for i = 1, #c, 1 do
		if a[i] == b then
			k = true
			break
		end
	end
	return k
end

lualianji = sgs.CreateTriggerSkill {
	name = "lualianji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and current then
			if player:objectName() == source:objectName() then
				if current:getPhase() == sgs.Player_Discard then
					local tag = room:getTag("lualianjiToGet")
					local guzhengToGet = tag:toString()
					if guzhengToGet == nil then
						guzhengToGet = ""
					end
					for _, card_id in sgs.qlist(move.card_ids) do
						local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
						if flag == sgs.CardMoveReason_S_REASON_DISCARD then
							if source:objectName() == current:objectName() then
								if guzhengToGet == "" then
									guzhengToGet = tostring(card_id)
								else
									guzhengToGet = guzhengToGet .. "+" .. tostring(card_id)
								end
							end
						end
					end
					if guzhengToGet then
						room:setTag("lualianjiToGet", sgs.QVariant(guzhengToGet))
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
lualianjiGet = sgs.CreateTriggerSkill {
	name = "#lualianjiGet",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		if not player:isDead() then
			local room = player:getRoom()
			local tag = room:getTag("lualianjiToGet")
			local guzheng_cardsToGet
			if tag then
				guzheng_cardsToGet = tag:toString():split("+")
			else
				return false
			end

			room:removeTag("lualianjiToGet")
			local cardsToGet = sgs.IntList()
			local cards = sgs.IntList()
			for i = 1, #guzheng_cardsToGet, 1 do
				local card_data = guzheng_cardsToGet[i]
				if card_data == nil then return false end
				if card_data ~= "" then --弃牌阶段没弃牌则字符串为""
					local card_id = tonumber(card_data)
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						cardsToGet:append(card_id)
						cards:append(card_id)
					end
				end
			end
			for _, erzhang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if erzhang:getPhase() ~= sgs.Player_Discard and cardsToGet:length() > 0 and erzhang:getPile("Plianji"):length() < 9 then
					local ai_data = sgs.QVariant()
					ai_data:setValue(cards:length())
					if erzhang:askForSkillInvoke("lualianji", ai_data) then
						room:fillAG(cards, erzhang)
						local to_back = room:askForAG(erzhang, cardsToGet, false, self:objectName())
						local backcard = sgs.Sanguosha:getCard(to_back)
						--player:obtainCard(backcard)
						room:clearAG(erzhang)
						local log    = sgs.LogMessage()
						log.from     = erzhang
						log.type     = "$luoying"
						log.card_str = sgs.Sanguosha:getCard(to_back):toString()
						room:sendLog(log)
						erzhang:addToPile("Plianji", sgs.Sanguosha:getCard(to_back))
						cardsToGet:removeOne(to_back)

						--erzhang:gainMark("@MAXH_mark", 1)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_Discard
		end
		return false
	end
}




--[[
lualianji = sgs.CreateTriggerSkill
{--当其他角色的牌于弃牌阶段置入弃牌堆时，你可以选择1张置于武将牌上称之为'计'
	name = "lualianji",
	events = {sgs.CardDiscarded },
    frequency = sgs.Skill_Frequent,
	can_trigger = function(self, player)
		return not player:hasSkill("lualianji")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getPile("Plianji"):length()
		local selfplayer = room:findPlayerBySkillName("lualianji")
		if not selfplayer then return false end

		if room:getCurrent()== selfplayer then return false end
		if event == sgs.CardDiscarded and player:getPhase() == sgs.Player_Discard then
			local card = data:toCard()
			if card:subcardsLength() == 0 then return false end	
			if  selfplayer:getPile("Plianji"):length() == 7 then return false end
			if not selfplayer:askForSkillInvoke("lualianji") then return false end
  		room:broadcastSkillInvoke("lualianji")  --音效
			local discard_ids = card:getSubcards()
					local card_id
		if discard_ids:length() == 1 then
			id = discard_ids:first()
		else
			room:fillAG(discard_ids, selfplayer)
			id = room:askForAG(selfplayer, discard_ids, true, "lualianji")
			selfplayer:invoke("clearAG")
					if card_id == -1 then return end
		end		
				local log=sgs.LogMessage()
				log.from = selfplayer
				log.type = "$luoying"
				log.card_str  = sgs.Sanguosha:getCard(id):toString()
				room:sendLog(log)	
				discard_ids:removeOne(id)
				selfplayer:addToPile("Plianji", sgs.Sanguosha:getCard(id))
				selfplayer:gainMark("@MAXH_mark", 1)
				
			
		end
	end
}]]

lualianji_result = sgs.CreateTriggerSkill { --敛计延伸技1
	frequency = sgs.Skill_Compulsory,
	name = "#lualianji_result",
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getPile("Plianji"):length()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:sendCompulsoryTriggerLog(player, "lualianji", true)
			draw.num = draw.num + x / 3
			data:setValue(draw)
		end
	end
}
lualianji_result_2 = sgs.CreateDistanceSkill { --敛计延伸技2
	name = "#lualianji_result_2",
	correct_func = function(self, from, to)
		local x = to:getPile("Plianji"):length()
		local y = from:getPile("Plianji"):length()
		if to:hasSkill("lualianji") then return x / 2 end
		if from:hasSkill("lualianji") then return 0 - y / 2 end
	end
}
--[[lualianji_result_3=sgs.CreateTriggerSkill--敛计延伸技3
{
	name="#lualianji_result_3",
	events={sgs.EventPhaseStart},
	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local x =player:getPile("Plianji"):length()
		if(player:getPhase() == sgs.Player_Discard ) then
			local discardnum = player:getHandcardNum() - player:getHp() - x
			if(discardnum > 0) then
				room:askForDiscard(player,"lualianji_result_3",discardnum,discardnum,false,false)
			end
			return true
		end
	end,
}]]
lualianji_result_3 = sgs.CreateMaxCardsSkill {
	name = "#lualianji_result_3",
	extra_func = function(self, target)
		if target:hasSkill("lualianji") then
			return target:getPile("Plianji"):length()
		end
	end
}
lualianji_result_4 = sgs.CreateTriggerSkill --敛计延伸技4
	{
		name = "#lualianji_result_4",
		events = { sgs.EventPhaseStart },

		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			--local x =player:getMark("@MAXH_mark")
			local x = player:getPile("Plianji"):length()
			if (player:getPhase() == sgs.Player_Finish) then
				if x >= 7 then
					room:handleAcquireDetachSkills(player, "weimu")
					room:handleAcquireDetachSkills(player, "wansha")
					room:setPlayerMark(player, "&lualianji+weimu+wansha", 1)
				else
					room:handleAcquireDetachSkills(player, "-weimu")
					room:handleAcquireDetachSkills(player, "-wansha")
					room:setPlayerMark(player, "&lualianji+weimu+wansha", 0)
				end
				return true
			end
		end,
	}
luajice_card = sgs.CreateSkillCard --‘计’使用技能
	{
		name = "luajice",
		once = true,
		filter = function(self, targets, to_select, player)
			if #targets > 0 then return false end
			return not to_select:isKongcheng()
		end,

		on_use = function(self, room, luajiaxu, targets)
			local target = targets[1]
			local Plianjis = luajiaxu:getPile("Plianji")
			if Plianjis:isEmpty() then return end
			room:fillAG(Plianjis, luajiaxu)
			card_id = room:askForAG(luajiaxu, Plianjis, true, "luajiece_vs")
			room:clearAG(luajiaxu)

			if target:getHandcardNum() > 0 then
				room:broadcastSkillInvoke("luajice_vs") --音效

				local card1 = sgs.Sanguosha:getCard(card_id)
				local card_id2 = room:askForCardChosen(luajiaxu, target, "h", "luajice_vs")
				local card2 = sgs.Sanguosha:getCard(card_id2)
				room:showCard(luajiaxu, card1:getEffectiveId())
				room:showCard(target, card2:getEffectiveId())
				if (card1:getSuit() == card2:getSuit()) then
					local damage = sgs.DamageStruct()
					damage.card = card1
					damage.damage = 1
					damage.from = luajiaxu
					damage.to = target
					room:damage(damage)
					--room:throwCard(card_id,luajiaxu)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(),
						"")
					room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
					luajiaxu:addToPile("Plianji", card2)
				else
					local one = room:askForPlayerChosen(luajiaxu, room:getAlivePlayers(), "@luageipai2")
					room:moveCardTo(card1, one, sgs.Player_PlaceHand, false)
					room:moveCardTo(card2, one, sgs.Player_PlaceHand, false)
					--luajiaxu: loseMark("@MAXH_mark")
				end
			end
		end,
	}
luajice = sgs.CreateViewAsSkill
	{
		name = "luajice",
		n = 0,
		view_as = function(self, cards)
			return luajice_card:clone()
		end,

		enabled_at_play = function(self, player)
			return not player:getPile("Plianji"):isEmpty() and not player:hasUsed("#luajice")
		end,
	}
luahuatuo:addSkill(lualianji_result_4)
luahuatuo:addSkill(lualianji_result_3)
luahuatuo:addSkill(lualianji_result_2)
luahuatuo:addSkill(lualianji_result)
luahuatuo:addSkill(luafentian)
luahuatuo:addSkill(lualianji)
luahuatuo:addSkill(lualianjiGet)
extension:insertRelatedSkills("lualianji", "#lualianjiGet")
extension:insertRelatedSkills("lualianji", "#lualianji_result")
extension:insertRelatedSkills("lualianji", "#lualianji_result_2")
extension:insertRelatedSkills("lualianji", "#lualianji_result_3")
extension:insertRelatedSkills("lualianji", "#lualianji_result_4")
luahuatuo:addSkill(luajice)
sgs.LoadTranslationTable {
	["luahuatuo"] = "☆SP贾文和",
	["Plianji"] = "计",
	["lualianji"] = "敛计",
	["luajice"] = "计策",
	["luajice_card"] = "计策",
	["@MAXH_mark"] = "手牌上限+1",
	["luafentian_card"] = "焚天",
	["luafentian"] = "焚天",
	["@fentian_mark"] = "焚天",
	[":luafentian"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置1张黑桃牌，令任意名角色受到1点没有伤害来源的火焰伤害，然后令其弃置一张牌。",
	[":lualianji"] = "当其他角色的牌于弃牌阶段置入弃牌堆时，你可以选择1张置于武将牌上称之为'计'，\
	1.每有3张'计':摸牌阶段，你额外摸1张牌,\
	2.每有2张'计'其他角色与你计算距离+1,你与其他角色计算距离-1，\
	3.每有一张'计'手牌上限+1\
	4.回合结束阶段,若你的'计'数目达到7张，则你获得技能“帷幕”&“完杀”\
	('计'不可超过8张')\
	☆如果在下一个回合结束阶段时你的'计'数目小于7则你立刻失去技能  “帷幕”&“完杀”",
	[":luajice"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名有手牌的角色先展示你的一张'计'牌，再选择对方的一张手牌展示之，若:\
	1.两张牌的花色相同则你对其造成1点伤害，其展示的牌会置于'计'牌区，弃置你展示的'计'牌\
	2.花色不同则你选择一名角色获得展示牌。",
	["@luageipai2"] = "请选择一名角色交给他这两张展示的牌",
	["designer:luahuatuo"] = "鹜心不已",
	["#luahuatuo"] = "算无遗策",
	["$luoying"] = "由于%from 的技能【敛计】,弃牌堆里的 %card 被置于%from武将牌上的'计'牌区。",
	["new"] = "坤包",
	["~luahuatuo"] = "我的时辰…也…到…了……",
	["$luafentian"] = "哭喊吧！哀求吧！挣扎吧！然后死吧！", --配音
	["$lualianji"] = "你奈我何？", --配音
	["$luajice"] = "巧变制敌，谋定而动", --配音	
}
return { extension }
