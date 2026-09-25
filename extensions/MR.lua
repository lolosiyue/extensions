--== << 新·神话再临 >> ==--
extension_MRmou = sgs.Package("MRmou", sgs.Package_GeneralPack)
--extension_MRwu = sgs.Package("MRwu", sgs.Package_GeneralPack)
--......
extension_MRcard = sgs.Package("MRcard", sgs.Package_CardPack)
---------------------------------
sgs.LoadTranslationTable{
    ["MRmou"] = "神话再临·谋",
	--["MRwu"] = "神话再临·武", --2024.10.24上线
	--......
	["MRcard"] = "新·神话再临-专属卡牌",
}
---------------------------------
local skills = sgs.SkillList()
---------------------------------
--==《神话再临·谋》==--
--[[
【魏】郭嘉、司马懿
【蜀】庞统、法正
【吴】周瑜、鲁肃
【群】荀彧、曹操
《神》神吕蒙、神诸葛亮
]]
--===================--
---------------------------------
--郭嘉
MR_guojia = sgs.General(extension_MRmou, "MR_guojia", "wei", 3)
MR_yijiCard = sgs.CreateSkillCard{
	name = "MR_yiji",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if self:getSubcards():length() == 1 then
		    return #targets < 1
		elseif self:getSubcards():length() == 2 then
		    return #targets < 2
		end
	end,
	feasible = function(self, targets, player)
		if self:getSubcards():length() == 1 then
		    return #targets == 1
		elseif self:getSubcards():length() == 2 then
		    return #targets > 0
		end
	end,
	on_use = function(self, room, source, targets)
		if self:getSubcards():length() == 1 then
		    room:obtainCard(targets[1], self, false)
		elseif self:getSubcards():length() == 2 then
		    if #targets > 1 then
			    room:obtainCard(targets[1], self:getSubcards():first(), false)
			    room:obtainCard(targets[2], self:getSubcards():last(), false)
			else
			    room:obtainCard(targets[1], self, false)
			end
		end
	end,
}
MR_yijivs = sgs.CreateViewAsSkillV2{
    name = "MR_yiji",
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern(), "@@MR_yiji") ~= nil and not player:isKongcheng()
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		return card and not card:isEquipped() and request:getSelectedCardIds():length() < 2
	end,
	card_selection_feasible = function(skill, request)
		local n = request:getSelectedCardIds():length()
		return n >= 1 and n <= 2
	end,
	create_card = function(skill, request)
		local new_card = MR_yijiCard:clone()
		if new_card then
			new_card:setSkillName("yiji")
			for _, id in sgs.qlist(request:getSelectedCardIds()) do
				new_card:addSubcard(id)
			end
		end
		return new_card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_yiji", 1) end
		return true
	end,
}
MR_yiji = sgs.CreateTriggerSkillV2 {
	name = "MR_yiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	view_as_skill = MR_yijivs,
	priority = -2,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local n, invoke = 0, nil
		while n < damage.damage do
		    invoke = room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
			n = n + 1
		end
		return invoke
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke("yiji")
		player:drawCards(2)
		room:askForUseCard(player, "@@MR_yiji", "@MR_yiji")
		return false
	end,
}
MR_huishiCard = sgs.CreateSkillCard{
	name = "MR_huishi",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "MR_huishi")
		local skills = {}
		for _, sk in sgs.qlist(targets[1]:getVisibleSkillList()) do
			if sk:getFrequency(targets[1]) ~= sgs.Skill_Wake or targets[1]:getMark(sk:objectName()) > 0 then continue end
			table.insert(skills, sk:objectName())
		end
		if #skills > 0 then
			local data = sgs.QVariant()
			data:setValue(targets[1])
			local skill = room:askForChoice(source, self:objectName(), table.concat(skills, "+"), data)
			targets[1]:setCanWake("MR_huishi", skill)
		else
			targets[1]:drawCards(4, "MR_huishi")
		end
		if source:isDead() then return end
		source:throwEquipArea()
		room:gainMaxHp(source, 2, self:objectName())
		room:recover(source, sgs.RecoverStruct(source, nil, source:getMaxHp()))
	end,
}
MR_huishi = sgs.CreateViewAsSkillV2{
	name = "MR_huishi",
	frequency = sgs.Skill_Limited,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("MR_huishi") < 1
	end,
	create_card = function(skill, request)
		return MR_huishiCard:clone()
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_huishi", 1) end
		return true
	end,
}
MR_guojia:addSkill("tiandu")
MR_guojia:addSkill(MR_yiji)
MR_guojia:addSkill(MR_huishi)
sgs.LoadTranslationTable{
	["MR_guojia"] = "郭嘉",
	["#MR_guojia"] = "遗计定辽东",
	["designer:MR_guojia"] = "俺的西木野Maki",
	["cv:MR_guojia"] = "“一世风华+虎年清明”",
	["illustrator:MR_guojia"] = "三国志12,时光流逝FC",
	["MR_yiji"] = "遗计",
	["mr_yiji"] = "遗计",
	["@MR_yiji"] = "你可以发动“遗计”将至多两张手牌交给任意名角色<br/> <b>操作提示</b>: 点击确定<br/>",
	[":MR_yiji"] = "每当你受到1点伤害后，你可以摸两张牌，然后将至多两张手牌分给任意角色。",
	["$MR_yiji1"] = "策谋本天成，妙手偶得之。",
	["$MR_yiji2"] = "此有锦囊若干，公可依计行事。",
	["MR_huishi"] = "辉逝",
	["mr_huishi"] = "辉逝",
	[":MR_huishi"] = "限定技，你可以选择一名角色：若其有未触发的觉醒技，则你选择其中一个觉醒技，其视为已满足觉醒条件，否则其摸四张牌，然后你废除所有装备栏。若如此做，你增加2点体力上限并恢复体力至体力上限。",
	["$MR_huishi1"] = "殚思极虑，以临制变。",
	["$MR_huishi2"] = "沥血书辞，以效区区之忠。",
	["~MR_guojia"] = "死亡，并不是结束......",
}
---------------------------------
--司马懿
MR_simayi = sgs.General(extension_MRmou, "MR_simayi", "wei", 3)
MR_jilveCard = sgs.CreateSkillCard{
	name = "MR_jilve",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {}
		if not source:hasFlag("MR_jilveZhiheng") and source:canDiscard(source, "he") then
			table.insert(choices,"zhiheng")
		end
		if not source:hasFlag("MR_jilveWansha") then
			table.insert(choices,"wansha")
		end
		table.insert(choices,"cancel")
		if #choices == 1 then return end
		local choice = room:askForChoice(source, "MR_jilve", table.concat(choices,"+"))
		if choice == "cancel" then
			room:addPlayerHistory(source, "#MR_jilveCard", -1)
			return
		end
		source:loseMark("&bear")
		room:notifySkillInvoked(source, "MR_jilve")
		if choice == "wansha" then
			room:setPlayerFlag(source, "MR_jilveWansha")
			room:acquireSkill(source, "olwansha")
		else
			room:setPlayerFlag(source, "MR_jilveZhiheng")
			room:setPlayerMark(source, "&mobilemouye", 2)
			room:askForUseCard(source, "@mobilemouzhiheng", "@jilve-zhiheng", -1, sgs.Card_MethodDiscard)
			room:setPlayerMark(source, "&mobilemouye", 0)
		end
	end,
}
MR_jilveVS = sgs.CreateViewAsSkillV2{--完杀和制衡
	name = "MR_jilve",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:usedTimes("#MR_jilve") < 2 and player:getMark("&bear") > 0
	end,
	create_card = function(skill, request)
		return MR_jilveCard:clone()
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_jilve", 1) end
		return true
	end,
}
MR_jilve = sgs.CreateTriggerSkillV2{
	name = "MR_jilve",
	events = {sgs.CardUsed, sgs.AskForRetrial, sgs.Damaged},
	view_as_skill = MR_jilveVS,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getMark("&bear") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		player:setMark("JilveEvent",tonumber(event))
		if event == sgs.CardUsed then
			local jizhi = sgs.Sanguosha:getTriggerSkill("tenyearjizhi")
			local use = data:toCardUse()
			if jizhi and use.card and use.card:getTypeId() == sgs.Card_TypeTrick and player:askForSkillInvoke("jilve_jizhi", data) then
				room:notifySkillInvoked(player, skill:objectName())
				player:loseMark("&bear")
				jizhi:trigger(event, room, player, data)
			end
		elseif event == sgs.AskForRetrial then
			local guicai = sgs.Sanguosha:getTriggerSkill("guicai")
			if guicai and not player:isKongcheng() and player:askForSkillInvoke("jilve_guicai", data) then
				room:notifySkillInvoked(player, skill:objectName())
				player:loseMark("&bear")
				guicai:trigger(event, room, player, data)
			end
		elseif event == sgs.Damaged then
		    local damage = data:toDamage()
			local n = 0
			local fangzhu = sgs.Sanguosha:getTriggerSkill("fangzhu")
			if fangzhu and player:askForSkillInvoke("jilve_fangzhu", data) then
				room:notifySkillInvoked(player, skill:objectName())
				player:loseMark("&bear")
				fangzhu:trigger(event, room, player, data)
			end
			while n < damage.damage do
			    if not damage.from:isNude() and player:askForSkillInvoke("fankui", ToData(damage.from)) then
				    room:broadcastSkillInvoke("fankui")
				    player:loseMark("&bear")
				    local id = room:askForCardChosen(player, damage.from, "he", skill:objectName())
					room:obtainCard(player, id, false)
				end
				n = n + 1
			end
		end
		player:setMark("JilveEvent", 0)
		return false
	end,
}
MR_jilveClear = sgs.CreateTriggerSkillV2{
	name = "#MR_jilve-clear",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasFlag("MR_jilveWansha") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		room:detachSkillFromPlayer(player, "olwansha", false, true)
		return false
	end,
}
MR_jilveMark = sgs.CreateTriggerSkillV2{
	name = "#MR_jilveMark",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill("MR_jilve")) then return false end
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) or event == sgs.GameStart then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, "MR_jilve", true, true)
		player:gainMark("&bear", player:getMaxHp())
		return false
	end,
}
MR_simayi:addSkill("renjie")
MR_simayi:addSkill(MR_jilve)
MR_simayi:addSkill(MR_jilveClear)
MR_simayi:addSkill(MR_jilveMark)
extension_MRmou:insertRelatedSkills("MR_jilve", "#MR_jilve-clear")
extension_MRmou:insertRelatedSkills("MR_jilve", "#MR_jilveMark")
MR_simayi:addRelateSkill("tenyearjizhi")
MR_simayi:addRelateSkill("guicai")
MR_simayi:addRelateSkill("fangzhu")
MR_simayi:addRelateSkill("fankui")
sgs.LoadTranslationTable{
	["MR_simayi"] = "司马懿",
	["#MR_simayi"] = "三马同槽",
	["designer:MR_simayi"] = "俺的西木野Maki",
	["cv:MR_simayi"] = "官方,“鉴往知来”",
	["illustrator:MR_simayi"] = "三国志12,时光流逝FC",
	["MR_jilve"] = "极略",
	["mr_jilve"] = "极略",
	[":MR_jilve"] = "你可以弃置一张牌并发动以下技能之一：“鬼才”、“放逐”、“界集智”、“谋制衡”(满“业”标记)、“OL界完杀”、“反馈”。游戏开始时/回合开始时/回合结束后，你获得X个“忍”标记。（X为你的体力上限）",
	["$MR_jilve1"] = "别急，还有下一个！",
	["$MR_jilve2"] = "老夫倒要看看，谁敢和司马氏作对？",
	["~MR_simayi"] = "我的时代......还没开始就结束了吗？",
}
---------------------------------
--庞统
MR_pangtong = sgs.General(extension_MRmou, "MR_pangtong", "shu", 3)
MR_lianhuan = sgs.CreateViewAsSkillV2{
	name = "MR_lianhuan",
	expand_pile = "wooden_ox",	--yun
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:usedTimes("#MR_lianhuan") < player:getMaxHp() + player:getLostHp()
	end,
	can_select_card = function(skill, request, card)
		return card and not card:isKindOf("BasicCard") and request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local selected = sgs.Sanguosha:getCard(ids:first())
		if not selected then return nil end
		local chain = sgs.Sanguosha:cloneCard("iron_chain", selected:getSuit(), selected:getNumber())
		chain:addSubcard(selected)
		chain:setSkillName(skill:objectName())
		return chain
	end,
}
MR_niepanCard = sgs.CreateSkillCard{
	name = "MR_niepan",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName())
		source:throwAllCards()
        room:recover(source, sgs.RecoverStruct(source, nil, 3 - source:getHp()))
		source:drawCards(3)
		if source:isChained() then
			local damage = room:getTag("CurrentDamageStruct"):toDamage()	--yun
			if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
				room:setPlayerProperty(source, "chained", sgs.QVariant(false))
			end
		end
		if not source:faceUp() then
			source:turnOver()
		end
		local choices = {"bazhen", "olhuoji", "olkanpo", "olcangzhuo", "MR_luofeng"}
		for _, choice_list in ipairs(choices) do
			if source:hasSkill(choice_list) then
				table.removeOne(choices, choice_list)
			end
		end
		if #choices > 0 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			room:acquireSkill(source, choice)
		end
	end,
}
MR_niepanVS = sgs.CreateViewAsSkillV2{
	name = "MR_niepan",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getMark(skill:objectName()) < 1
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern(), "@@MR_niepan") ~= nil
		end
		return false
	end,
	create_card = function(skill, request)
		return MR_niepanCard:clone()
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_niepan", 1) end
		return true
	end,
}
MR_niepan = sgs.CreateTriggerSkillV2{
	name = "MR_niepan",
	view_as_skill = MR_niepanVS,
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() and player:getMark(skill:objectName()) < 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@MR_niepan", "@MR_niepan")
		return false
	end,
}
MR_luofeng = sgs.CreateTriggerSkillV2{
	name = "MR_luofeng",
	events = {sgs.Death, sgs.DamageCaused},
	frequency = sgs.Skill_Limited,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
			if player and death.who and player:objectName() == death.who:objectName()
				and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.DamageCaused then return end
		local owner = ctx.owner
		if not owner then return end
		local first_owner, first_id
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			local ids = p:getSkillInstanceIds(skill:objectName())
			if ids:length() > 0 then
				first_owner, first_id = p, ids:at(0)
				break
			end
		end
		if not first_owner or owner:objectName() ~= first_owner:objectName() or ctx.instanceID ~= first_id then return end
		local damage = ctx.original_data:toDamage()
		if damage.from and damage.from:getMark("luofeng_damage") > 0 and damage.card
			and (damage.card:isKindOf("SkillCard") or (damage.card:isVirtualCard() and damage.card:subcardsLength() > 0)) then
			local fengchu = room:findPlayersBySkillName(skill:objectName())
			for _, p in sgs.qlist(fengchu) do
				room:sendCompulsoryTriggerLog(p, skill:objectName(), true, true)
			end
			damage.damage = damage.damage + 1
			ctx.original_data:setValue(damage)
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Death then
		    local death = ctx.original_data:toDeath()
		    local alives = room:getAlivePlayers()
		    if not alives:isEmpty() then
			    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@choose-players", false, true)
			    room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
			    local choices = {"bazhen", "olhuoji", "olkanpo", "olcangzhuo", "MR_lianhuan", "MR_niepan"}
		        for _, choice_list in ipairs(choices) do
			        if target:hasSkill(choice_list) then
				        table.removeOne(choices, choice_list)
				    end
			    end
			    if #choices > 0 then
				    local choice = room:askForChoice(target, skill:objectName(), table.concat(choices, "+"))
				    room:acquireSkill(target, choice)
				    room:setPlayerMark(target, "luofeng_damage", 1)
				    room:setPlayerMark(target, "&MR_luofeng", 1)
				end
			end
		end
	end,
}
MR_lianhuanTarget = sgs.CreateTargetModSkillV2{
	name = "#MR_lianhuanTarget",
	pattern = "Card",
	correct_func = function(skill, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_ExtraTarget then return 0 end
		local card = ctx:getCard()
		if card and table.contains(card:getSkillNames(), "MR_lianhuan") then
			return 1000
		end
		return 0
	end,
}
MR_pangtong:addSkill(MR_lianhuan)
MR_pangtong:addSkill(MR_lianhuanTarget)
MR_pangtong:addSkill(MR_niepan)
if not sgs.Sanguosha:getSkill("MR_luofeng") then skills:append(MR_luofeng) end
extension:insertRelatedSkills("MR_lianhuan","#MR_lianhuanTarget")
MR_pangtong:addRelateSkill("MR_luofeng")
MR_pangtong:addRelateSkill("bazhen")
MR_pangtong:addRelateSkill("olhuoji")
MR_pangtong:addRelateSkill("olkanpo")
MR_pangtong:addRelateSkill("olcangzhuo")
sgs.LoadTranslationTable{
    ["MR_pangtong"] = "庞统",
    ["#MR_pangtong"] = "入蜀得川",
	["designer:MR_pangtong"] = "Maki,FC",
	["cv:MR_pangtong"] = "“龙跃凤鸣+梧凤之鸣+落凤坡劫”",
	["illustrator:MR_pangtong"] = "三国志12,时光流逝FC",
    ["MR_lianhuan"] = "连环",
    ["#lianhuan"] = "%from 发动了 %arg ，将 %card 当做 %arg 重铸",
    --[":MR_lianhuan"] = "出牌阶段，你可以将一张牌当做【铁索连环】使用或重铸；你以此法使用的【铁索连环】无目标数限制。", --必须改，不然可以直接永动机无限刷牌了
	--[":MR_lianhuan"] = "<font color='green'><b>出牌阶段限X次，</b></font>你可以将一张牌当做【铁索连环】使用或重铸；你以此法使用的【铁索连环】无目标数限制。（X为你的体力上限+你已损失体力值）",
	[":MR_lianhuan"] = "你可以将一张<font color='blue'><b>非基本</b></font>牌当做【铁索连环】使用或重铸；你以此法使用的【铁索连环】无目标数限制。",
    ["$MR_lianhuan1"] = "铁索系舟，遇火难逃。",
    ["$MR_lianhuan2"] = "大小战船，皆连锁之，则风浪难覆。",
    ["MR_niepan"] = "涅槃",
	["mr_niepan"] = "涅槃",
    [":MR_niepan"] = "限定技，出牌阶段或当你处于濒死状态时，你可以弃置区域内的所有牌并复原武将牌，然后你将体力值回复至3点并摸三张牌。若如此做，你从“八阵”、“OL界火计”、“OL界看破”、“OL藏拙”、“落凤”中选择一个技能并获得。",
    ["@MR_niepan"] = "你是否发动技能“涅槃”？",
	["$MR_niepan1"] = "雏凤展翼，风尘翕张！",
    ["$MR_niepan2"] = "吾胸中之志，岂可终亡于此！",
	["MR_luofeng"] = "落凤",
	[":MR_luofeng"] = "限定技，当你死亡时，选择一名其他角色，令该角色从“八阵”、“OL界火计”、“OL界看破”、“OL界藏拙”、“连环”(谋包)、“涅槃”(谋包)中选择一个技能并获得，且其本局游戏因技能或转化牌而造成的伤害+1。",
    ["$MR_luofeng1"] = "抱负未展，命数先至......",
    ["$MR_luofeng2"] = "落...凤...坡...",
    ["~MR_pangtong"] = "卧龙...以后，便交给你了！",
}
---------------------------------
--法正
MR_fazheng = sgs.General(extension_MRmou, "MR_fazheng", "shu", 3)
MR_enyuan = sgs.CreateTriggerSkillV2{
    name = "MR_enyuan",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() and use.to:contains(player) and player:hasSkill(skill:objectName()) and use.card:isKindOf("Peach") then
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				use.from:drawCards(1)
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() and player:hasSkill(skill:objectName()) then
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				if damage.from:isKongcheng() then
				    room:loseHp(damage.from, 1, true, player, skill:objectName())
				else
				    local card_id = room:askForExchange(damage.from, skill:objectName(), 1, 1, false, "@MR_enyuan"..player:objectName(), true)
					if not card_id then
					    room:loseHp(damage.from, 1, true, player, skill:objectName())
					else
					    room:obtainCard(player, card_id, false)
					end
				end
			end
		end
	end,
}
MR_xuanhuoCard = sgs.CreateSkillCard{
	name = "MR_xuanhuo",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local skill_list, players = {"tenyearwusheng", "tenyearpaoxiao", "ollongdan", "tenyearliegong", "tieji", "tenyearkuanggu"}, source:getSiblings()
		players:append(source)
		for _, sib in sgs.qlist(players) do
		    for _, choice_list in ipairs(skill_list) do
			    if sib:hasSkill(choice_list) then
				    table.removeOne(skill_list, choice_list)
			    end
			end
		end
		if #skill_list > 0 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(skill_list, "+"))
			room:acquireSkill(source, choice)
			room:addPlayerMark(source, choice..self:objectName())
		end
	end,
}
MR_xuanhuo = sgs.CreateTriggerSkillV2{
	name = "MR_xuanhuo",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	can_trigger = function(skill, event, room, player, data)
		if not (player and (player:getGeneralName() == "MR_fazheng" or player:getGeneral2Name() == "MR_fazheng")) then
			return false
		end
		if event == sgs.EventAcquireSkill then
			local change = data:toSkillChange()
			if change.skillName ~= skill:objectName() then return false end
		elseif event ~= sgs.GameStart then
			return false
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:hasSkill("MR_xuanhuo") then
			for _,p in sgs.qlist(room:getAllPlayers()) do
			    if not p:hasSkill("MR_xuanhuoTag") then
				    room:attachSkillToPlayer(p, "MR_xuanhuoTag")
				end
			end
		end
		return false
	end,
}
MR_xuanhuoTagvs = sgs.CreateViewAsSkillV2{
	name = "MR_xuanhuoTag&",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local skill_list, players = {"tenyearwusheng", "tenyearpaoxiao", "ollongdan", "tenyearliegong", "tieji", "tenyearkuanggu"}, player:getSiblings()
		players:append(player)
		for _, sib in sgs.qlist(players) do
		    for _, choice_list in ipairs(skill_list) do
			    if sib:hasSkill(choice_list) then
				    table.removeOne(skill_list, choice_list)
			    end
			end
		end
		if #skill_list > 0 then
			return player:usedTimes("#MR_xuanhuo") < 1 and not player:isKongcheng()
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		return card and not card:isEquipped() and request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local vscard = MR_xuanhuoCard:clone()
		for _, i in sgs.qlist(ids) do
			vscard:addSubcard(i)
		end
		return vscard
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_xuanhuo", 1) end
		return true
	end,
}
MR_xuanhuoTag = sgs.CreateTriggerSkillV2{
	name = "MR_xuanhuoTag&",
	global = true,
	view_as_skill = MR_xuanhuoTagvs,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
	    	for _, sk in sgs.qlist(player:getVisibleSkillList()) do
			    if player:getMark(sk:objectName().."MR_xuanhuo") > 0 then
				    room:detachSkillFromPlayer(player, sk:objectName())
					room:removePlayerMark(player, sk:objectName().."MR_xuanhuo")
				end
		    end
		end
		return false
	end,
}
MR_fazheng:addSkill(MR_xuanhuo)
MR_fazheng:addSkill(MR_enyuan)
if not sgs.Sanguosha:getSkill("MR_xuanhuoTag") then skills:append(MR_xuanhuoTag) end
MR_fazheng:addRelateSkill("tenyearwusheng")
MR_fazheng:addRelateSkill("tenyearpaoxiao")
MR_fazheng:addRelateSkill("ollongdan")
MR_fazheng:addRelateSkill("tenyearliegong")
MR_fazheng:addRelateSkill("tieji")
MR_fazheng:addRelateSkill("tenyearkuanggu")
sgs.LoadTranslationTable{
	["MR_fazheng"] = "法正",
	["#MR_fazheng"] = "进取汉中",
	["designer:MR_fazheng"] = "俺的西木野Maki",
	["cv:MR_fazheng"] = "“上兵伐谋”",
	["illustrator:MR_fazheng"] = "三国志12,时光流逝FC",
	["MR_enyuan"] = "恩怨",
	["@MR_enyuan"] = "交给%src一张手牌，否则失去1点体力",
    [":MR_enyuan"] = "锁定技，每当其他角色对你使用【桃】后，其摸一张牌；每当你受到伤害后，伤害来源选择一项：1.交给你一张手牌；2.失去1点体力。",
	["$MR_enyuan1"] = "生以报恩，死亦相随。",
	["$MR_enyuan2"] = "一朝权在手，杀尽负我人。",
	["MR_xuanhuo"] = "眩惑",
	["mr_xuanhuo"] = "眩惑",
	["MR_xuanhuoTag"] = "眩惑",
    [":MR_xuanhuo"] = "<font color='green'><b>每名角色的出牌阶段限一次，</b></font>该角色可以弃置一张手牌，然后其选择并获得以下技能之一直到回合结束：" ..
	"“界武圣”、“界咆哮”、“OL界龙胆”、“界烈弓”、“铁骑”、“狂骨”（场上已有的技能无法选择）。",
	["$MR_xuanhuo1"] = "用许靖之名望，揽天下之贤士。", --这就是许神！我许伟大，无需多言！
	["$MR_xuanhuo2"] = "取舍之间，仁义自现。",
	["~MR_fazheng"] = "此生再不能与将军出秦川了......",
}
---------------------------------
--周瑜
MR_zhouyu = sgs.General(extension_MRmou, "MR_zhouyu", "wu", 3)
MR_fanjianCard = sgs.CreateSkillCard{
	name = "MR_fanjian",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "MR_fanjian")
		room:getThread():delay()
		room:showCard(source, card_id)
		if card:getSuit() ~= suit then
		    room:throwCard(self, source, nil)
		    room:loseHp(target, 1, true, source, self:objectName())
		else
			room:obtainCard(target, self, false)
			if source:getMark("MR_fanjian_fail-PlayClear") == 0 then
				room:addPlayerMark(source, "MR_fanjian_fail-PlayClear")
				source:drawCards(1)
			else
				room:addPlayerMark(source, "MR_fanjian_used-PlayClear")
			end
		end
	end,
}
MR_fanjian = sgs.CreateViewAsSkillV2{
	name = "MR_fanjian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if not player:isKongcheng() then
			return player:getMark("MR_fanjian_used-PlayClear") == 0
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		return card and not card:isEquipped() and request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = MR_fanjianCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_fanjian", 1) end
		return true
	end,
}
MR_zhouyu:addSkill("yingzi")
MR_zhouyu:addSkill(MR_fanjian)
sgs.LoadTranslationTable{
	["MR_zhouyu"] = "周瑜",
	["#MR_zhouyu"] = "千古风流",
	["designer:MR_zhouyu"] = "Maki,FC",
	["cv:MR_zhouyu"] = "官方,“运筹帷幄”",
	["illustrator:MR_zhouyu"] = "三国志12,时光流逝FC",
	["MR_fanjian"] = "反间",
	["mr_fanjian"] = "反间",
	[":MR_fanjian"] = "出牌阶段，你可以选择一张手牌，令一名其他角色说出一种花色后展示之，若猜错则弃置此牌并令其失去1点体力，" ..
	"若猜对则其获得此牌然后你摸一张牌<font color='blue'><b>(第一次猜对)/不能再发动此技能直到此阶段结束(第二次猜对)</b></font>。",
	["$MR_fanjian1"] = "此敌中作敌之计，倒看汝如何破解。",
	["$MR_fanjian2"] = "如今之势，便让你进退两难！",
	["~MR_zhouyu"] = "吾虽将陨，自忖未愧伯符之托，无憾矣......",
}
---------------------------------
--鲁肃
MR_lusu = sgs.General(extension_MRmou, "MR_lusu", "wu", 3)
MR_haoshi = sgs.CreateTriggerSkillV2{
	name = "MR_haoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then return skill:objectName() end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard
			and player:getMark(skill:objectName().."_replay") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			return room:askForSkillInvoke(player, skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			room:broadcastSkillInvoke(skill:objectName())
			room:addPlayerMark(player, skill:objectName().."_replay")
			draw.num = draw.num + room:askForChoice(player, skill:objectName(), "1+2+3+4")
			data:setValue(draw)
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark(skill:objectName().."_replay") > 0 then
			local players = sgs.SPlayerList()
			local n = player:getHandcardNum()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				n = math.min(p:getHandcardNum(), n)
			end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() == n then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, skill:objectName(), "@choose-players", player:getHandcardNum() == n, true)
				if target then
					room:broadcastSkillInvoke(skill:objectName(), 2)
					local exchangeMove = sgs.CardsMoveList()
					exchangeMove:append(sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), skill:objectName(), "")))
					exchangeMove:append(sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), skill:objectName(), "")))
					room:moveCardsAtomic(exchangeMove, false)
				end
			end
		end
		return false
	end,
}
MR_lusu:addSkill(MR_haoshi)
MR_lusu:addSkill("rushB_dimeng") --来自Maki·DIY包
sgs.LoadTranslationTable{
	["MR_lusu"] = "鲁肃",
	["#MR_lusu"] = "联盟大局",
	["designer:MR_lusu"] = "俺的西木野Maki",
	["cv:MR_lusu"] = "“众人之表+联刘抗曹”",
	["illustrator:MR_lusu"] = "三国志12,时光流逝FC",
	["MR_haoshi"] = "好施",
    [":MR_haoshi"] = "你可以令你的额定摸牌数至多+4。若如此做，弃牌阶段结束时，若你：为手牌数最少（或之一）的角色，你可以与手牌数最少之一的一名其他角色交换手牌；不为手牌数最少的角色，你须与手牌数最少之一的一名其他角色交换手牌。",
	["$MR_haoshi1"] = "千金散尽，一笑置之。",
	["$MR_haoshi2"] = "施财而得贤友，善莫大焉。",
	["~MR_lusu"] = "联盟是长远大计，切记，切记...咳咳......",
}
---------------------------------
--荀彧
MR_xunyu = sgs.General(extension_MRmou, "MR_xunyu", "qun", 3)
MR_quhuCard = sgs.CreateSkillCard{
	name = "MR_quhu",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 2 and not to_select:isKongcheng()
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		targets[1]:pindian(targets[2], self:objectName(), nil)
	end,
}
MR_quhuvs = sgs.CreateViewAsSkillV2{
	name = "MR_quhu",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return (not player:hasUsed("#MR_quhu")) and not player:isKongcheng()
	end,
	create_card = function(skill, request)
		return MR_quhuCard:clone()
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_quhu", 1) end
		return true
	end,
}
MR_quhu = sgs.CreateTriggerSkillV2{
	name = "MR_quhu",
    --global = true,
	events = {sgs.Pindian},
	view_as_skill = MR_quhuvs,
	can_trigger = function(skill, event, room, player, data)
		local pindian = data:toPindian()
		if not pindian or pindian.reason ~= skill:objectName() then return false end
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if p:getSkillInstanceIds(skill:objectName()):length() > 0 then
				return skill:objectName(), p:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pindian = ctx.original_data:toPindian()
		local quhu = true
		if pindian.reason == skill:objectName() then
			local winner = pindian.from
			local loser = pindian.to
			local players = sgs.SPlayerList()
			if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
				winner = pindian.to
				loser = pindian.from
			elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() and ctx.invoker:hasSkill(skill:objectName()) then
				ctx.invoker:drawCards(2)
				quhu = false
			elseif pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				winner = pindian.from
				loser = pindian.to
			end
			if quhu then
				room:damage(sgs.DamageStruct(skill:objectName(), winner, loser))
			end
		end
		return false
	end,
}
MR_jieming = sgs.CreateTriggerSkillV2{
	name = "MR_jieming",
	--global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.Death then
			local death = data:toDeath()
			if not (death.who and death.who:objectName() == player:objectName()) then return false end
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			local damage = ctx.original_data:toDamage()
			for i = 0, damage.damage - 1, 1 do
				local cc = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "MR_jieming-invoke", true, true)
				if not cc then break end
				local upper = math.min(5, cc:getMaxHp())
				room:broadcastSkillInvoke(skill:objectName())
				room:drawCards(cc, upper, skill:objectName())
				room:askForDiscard(cc, skill:objectName(), 2, 2)
				local x = cc:getHandcardNum() - cc:getMaxHp()
				if x > 0 then
					room:askForDiscard(cc, skill:objectName(), 1, 1)
				end
			end
		else
			local death = ctx.original_data:toDeath()
			if death.who:objectName() == player:objectName() then
				local cc = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@choose-players", true, true)
				if not cc then return false end
				local upper = math.min(5, cc:getMaxHp())
				room:broadcastSkillInvoke(skill:objectName())
				room:drawCards(cc, upper, skill:objectName())
				room:askForDiscard(cc, skill:objectName(), 2, 2)
				local x = cc:getHandcardNum() - cc:getMaxHp()
				if x > 0 then
					room:askForDiscard(cc, skill:objectName(), 1, 1)
				end
			end
		end
		return false
	end,
}
MR_xunyu:addSkill(MR_quhu)
MR_xunyu:addSkill(MR_jieming)
sgs.LoadTranslationTable{
    ["MR_xunyu"] = "荀彧",
	["#MR_xunyu"] = "忠节于汉",
	["designer:MR_xunyu"] = "俺的西木野Maki",
	["cv:MR_xunyu"] = "“命世之才”",
	["illustrator:MR_xunyu"] = "三国志12,时光流逝FC",
	["MR_quhu"] = "驱虎",
	["mr_quhu"] = "驱虎",
	[":MR_quhu"] = "出牌阶段限一次，你可以令两名有手牌的角色拼点，拼点点数大的一方对点数小的一方造成1点伤害。若拼点点数相同，则你摸两张牌。",
	["$MR_quhu1"] = "借力打力，隔山打牛！",
	["$MR_quhu2"] = "去敌，吾自有良策。",
	["MR_jieming"] = "节命",
	["MR_jieming-invoke"] = "你可以选择一名角色，对其发动“节命”",
	[":MR_jieming"] = "当你受到1点伤害后或死亡时，你可以令一名角色摸X张牌（若为死亡时发动“节命”，则一名角色改为一名其他角色），然后令其弃置两张手牌，若其手牌数仍大于体力上限则额外弃置一张牌。（X为其体力上限且至多为5）",
	["$MR_jieming1"] = "德行周备，名重天下！",
	["$MR_jieming2"] = "举贤荐能，心怀坦荡！",
	["~MR_xunyu"] = "大汉气数如此，吾何必苟活世间......",
}
---------------------------------
--曹操
MR_caocao = sgs.General(extension_MRmou, "MR_caocao", "qun")
MR_lingfa = sgs.CreateTriggerSkillV2{
    name = "MR_lingfa",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player)
			and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and not (use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Dongzhuxianji")))) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
	    local data = ctx.original_data
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() and use.to:contains(player) and player:hasSkill(skill:objectName()) and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and not (use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Dongzhuxianji")))) then
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				player:drawCards(1)
				if use.from:isNude() then
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
				else
					room:setTag("MR_lingfa", data)
				    local card_id = room:askForExchange(use.from, skill:objectName(), 1, 1, true, "@MR_enyuan"..player:objectName(), true)
					room:removeTag("MR_lingfa")
					if not card_id then
					    local nullified_list = use.nullified_list
					    table.insert(nullified_list, player:objectName())
					    use.nullified_list = nullified_list
					    data:setValue(use)
					else
					    room:obtainCard(player, card_id, false)
					end
				end
			end
		end
		return false
	end,
}
MR_zhian = sgs.CreateTriggerSkillV2{
	name = "MR_zhian",
	--global = true,
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.card and (use.card:isKindOf("EquipCard") or use.card:isKindOf("DelayedTrick"))) then return false end
		local names, owners = {}, {}
		for _, cc in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if cc:getMark(skill:objectName().."-Clear") < 1 and cc:hasSkill(skill:objectName()) then
				table.insert(names, skill:objectName())
				table.insert(owners, cc:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
			room:broadcastSkillInvoke(skill:objectName())
			room:addPlayerMark(player, skill:objectName().."-Clear")
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local choices = {}
		table.insert(choices, "1")
		if not player:isKongcheng() then table.insert(choices, "2") end
		table.insert(choices, "3")
		if #choices > 0 then
	        local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), ctx.original_data)
			if choice == "1" then
			    room:throwCard(use.card, use.from, player)
			elseif choice == "2" then
			    room:askForDiscard(player, skill:objectName(), 1, 1)
				room:obtainCard(player, use.card, false)
			else
			    room:damage(sgs.DamageStruct(skill:objectName(), player, use.from))
			end
		end
		return false
	end,
}
MR_caocao:addSkill(MR_lingfa)
MR_caocao:addSkill(MR_zhian)
sgs.LoadTranslationTable{
	["MR_caocao"] = "曹操",
	["#MR_caocao"] = "峥嵘而立",
	["designer:MR_caocao"] = "俺的西木野Maki",
	["cv:MR_caocao"] = "官方",
	["illustrator:MR_caocao"] = "三国志12,时光流逝FC",
	["MR_lingfa"] = "令法",
	["@MR_lingfa"] = "交给%src一张牌，否则此牌无效",
	[":MR_lingfa"] = "锁定技，当其他角色对你使用不为【桃园结义】、【五谷丰登】、【洞烛先机】、【无中生有】的普通锦囊牌或【杀】后，你摸一张牌，其选择一项：1.交给你一张牌；2.此牌对你无效。",
	["$MR_lingfa1"] = "吾明令在此，汝何以犯之？",
	["$MR_lingfa2"] = "法不阿贵，绳不挠曲！",
	["MR_zhian"] = "治暗",
	["MR_zhian:1"] = "弃置此牌",
	["MR_zhian:2"] = "弃置一张手牌并获得此牌",
	["MR_zhian:3"] = "造成1点伤害",
	[":MR_zhian"] = "每回合限一次，当有角色使用装备牌或延时锦囊牌后，你可以选择一项：1.弃置此牌；2.弃置一张手牌并获得此牌；3.对其造成1点伤害。",
	["$MR_zhian1"] = "此等蝼蚁不除，必溃千丈之堤！",
	["$MR_zhian2"] = "尔等权贵贪赃枉法，岂可轻饶？",
	["~MR_caocao"] = "奸宦当道，难以匡正啊......",
}
---------------------------------
--神吕蒙
MR_shenlvmeng = sgs.General(extension_MRmou, "MR_shenlvmeng", "god", 3)
MR_shelie = sgs.CreateTriggerSkillV2{
	name = "MR_shelie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw then return skill:objectName() end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		if change.to == sgs.Player_Draw then
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
			player:skip(change.to)
			local card_ids = room:getNCards(5)
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
			room:clearAG()
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(getCardList(to_get))
				player:obtainCard(dummy)
			end
			room:addPlayerMark(player, skill:objectName().."-Clear", dummy:subcardsLength())
			room:addPlayerMark(player, "&MR_shelie-Clear", dummy:subcardsLength())
			dummy:clearSubcards()
			if not to_throw:isEmpty() then
				dummy:addSubcards(getCardList(to_throw))
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), skill:objectName(), "")
				room:throwCard(dummy, reason, nil)
			end
			dummy:deleteLater()
		end
		return false
	end,
}
MR_gongxinCard = sgs.CreateSkillCard{
	name = "MR_gongxin",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				if card:getSuit() ~= sgs.Card_Club then
					ids:append(card:getEffectiveId())
				end
			end
			room:setTag("MR_gongxin", ToData(effect.to))
			local card_id = room:doGongxin(effect.from, effect.to, ids)
			room:removeTag("MR_gongxin")
			if (card_id == -1) then return end
			local result = room:askForChoice(effect.from, "MR_gongxin", "obtain+throw+put")
			if result == "obtain" then
				room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), false)
			elseif result == "throw" then
			    room:throwCard(sgs.Sanguosha:getCard(card_id), effect.to, effect.from)
			else
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DrawPile)
			end
		end
	end,
}	
MR_gongxin = sgs.CreateViewAsSkillV2{
	name = "MR_gongxin",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#MR_gongxin")
	end,
	create_card = function(skill, request)
		return MR_gongxinCard:clone()
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then room:addPlayerHistory(source, "#MR_gongxin", 1) end
		return true
	end,
}
MR_shelie_MaxCards = sgs.CreateMaxCardsSkillV2{
	name = "#MR_shelie_MaxCards",
	correct_func = function(skill, ctx)
		local holder = ctx:getHolder()
		if holder and holder:hasSkill("MR_shelie") then
			return holder:getMark("MR_shelie-Clear")
		end
		return 0
	end,
}
MR_shenlvmeng:addSkill(MR_shelie)
MR_shenlvmeng:addSkill(MR_gongxin)
MR_shenlvmeng:addSkill(MR_shelie_MaxCards)
extension:insertRelatedSkills("MR_shelie","#MR_shelie_MaxCards")
sgs.LoadTranslationTable{
	["MR_shenlvmeng"] = "神吕蒙",
	["#MR_shenlvmeng"] = "国士无双",
	["designer:MR_shenlvmeng"] = "俺的西木野Maki",
	["cv:MR_shenlvmeng"] = "“白衣渡江”",
	["illustrator:MR_shenlvmeng"] = "三国志13,时光流逝FC",
	["MR_shelie"] = "涉猎",
	[":MR_shelie"] = "锁定技，你跳过摸牌阶段，然后改为亮出牌堆顶的五张牌并获得每种花色的牌各一张。你的手牌上限+X。（X为于摸牌阶段发动“涉猎”时获得的牌数）",
	["$MR_shelie1"] = "从主之劝，博览群书。",
	["$MR_shelie2"] = "为将者，自当识天晓地。",
	["MR_gongxin"] = "攻心",
	["mr_gongxin"] = "攻心",
	["MR_gongxin:obtain"] = "获得",
	[":MR_gongxin"] = "出牌阶段限一次，你可以选择一名其他角色，然后观看该角色的手牌，选择其中的一张不为梅花花色的牌并选择一项：1.获得之；2.弃置之；3.置于牌堆顶。",
	["$MR_gongxin1"] = "一眼看透你的心事。",
	["$MR_gongxin2"] = "你心中的防线已失陷，还不速速退走？",
	["~MR_shenlvmeng"] = "终是逃不开，追魂索命之咒......",
}
---------------------------------
--神诸葛亮
MR_shenzhugeliang = sgs.General(extension_MRmou, "MR_shenzhugeliang", "god", 3)
MR_jincui = sgs.CreateTriggerSkillV2{
	name = "MR_jincui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.GameStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.GameStart then return skill:objectName() end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart or change.to == sgs.Player_NotActive then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(7))
				room:setPlayerProperty(player, "hp", sgs.QVariant(7))
				local cards = room:getNCards(5)
				room:askForGuanxing(player, cards)
			elseif change.to == sgs.Player_NotActive then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMark(skill:objectName().."wumiao")))
				room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMark(skill:objectName().."wumiao")))
			end
		else
		    room:setPlayerMark(player, skill:objectName().."wumiao", player:getMaxHp())
		end
		return false
	end,
}
MR_qingshi = sgs.CreateTriggerSkillV2{
	name = "MR_qingshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.DamageCaused},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and not (use.card:isKindOf("SkillCard") or use.card:isKindOf("EquipCard") or use.card:isKindOf("Collateral"))
				and player:getMark(skill:objectName().."-Clear") < 1 then
				return skill:objectName()
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("mrqingshi") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
		    if not (use.card:isKindOf("SkillCard") or use.card:isKindOf("EquipCard") or use.card:isKindOf("Collateral")) and player:getMark(skill:objectName().."-Clear") < 1 then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				local choices = {}
				if use.card:isDamageCard() then
				    table.insert(choices, "1")
				end
				if use.to:length() > 0 then
				    table.insert(choices, "2")
				end
				table.insert(choices, "3")
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), data)
			    local log = sgs.LogMessage()
			    log.type = "#mrqingshichoice"
			    log.from = player
			    log.arg = skill:objectName()..":"..choice
				room:sendLog(log)
				if choice == "1" then
			        local log = sgs.LogMessage()
			        log.type = "#mrqingshicarddamage"
			        log.from = player
		            log.card_str = use.card:toString()
				    room:sendLog(log)
				    room:setCardFlag(use.card, "mrqingshi")
				elseif choice == "2" then
			        local players = sgs.SPlayerList()
			        for _, p in sgs.qlist(room:getAlivePlayers()) do
				        if not use.to:contains(p) then players:append(p) end
			        end
			        if players:isEmpty() then return false end
			        for _, p in sgs.qlist(players) do
				        p:drawCards(1)
			        end
				else
			        local log = sgs.LogMessage()
			        log.type = "#mrqingshifail"
			        log.from = player
			        log.arg = skill:objectName()..":"..choice
					log.arg2 = skill:objectName()
				    room:sendLog(log)
				    player:drawCards(player:getMaxHp())
					room:addPlayerMark(player, skill:objectName().."-Clear")
				end
			end
		elseif event == sgs.DamageCaused then
		    local damage = data:toDamage()
			if damage.card:hasFlag("mrqingshi") then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
		    	damage.damage = damage.damage + 1
			    data:setValue(damage)
			end
		end
		return false
	end,
}
MR_zhizhevs = sgs.CreateViewAsSkillV2{
	name = "MR_zhizhe",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getInitiator() ~= nil
	end,
	can_select_card = function(skill, request, card)
		if not card or not request:getSelectedCardIds():isEmpty() then return false end
		local player = request:getInitiator()
		if not player then return false end
		return (card:isKindOf("BasicCard") or card:isNDTrick())
		and not (card:isKindOf("Jink") or card:isKindOf("Nullification"))
		and player:getMark(card:objectName().."+"..skill:objectName().."-Clear") < 1
	end,
    create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local selected = sgs.Sanguosha:getCard(ids:first())
		if not selected then return nil end
		local card = sgs.Sanguosha:cloneCard(selected:objectName(), sgs.Card_NoSuit, 0)
		card:setSkillName(skill:objectName())
		return card
	end,
}
MR_zhizhe = sgs.CreateTriggerSkillV2{
	name = "MR_zhizhe",
	events = {sgs.CardFinished},
	view_as_skill = MR_zhizhevs,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card and table.contains(use.card:getSkillNames(), "MR_zhizhe") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
	    if use.card and table.contains(use.card:getSkillNames(), "MR_zhizhe") and player:hasSkill(skill:objectName()) then
		    if player:getMark(skill:objectName()..use.card:objectName().."-Clear") < 1 then
				room:addPlayerMark(player, use.card:objectName().."+"..skill:objectName().."-Clear")
			end
		end
		return false
	end,
}
MR_shenzhugeliang:addSkill(MR_jincui)
MR_shenzhugeliang:addSkill(MR_qingshi)
MR_shenzhugeliang:addSkill(MR_zhizhe)
sgs.LoadTranslationTable{
	["MR_shenzhugeliang"] = "神诸葛亮",
	["#MR_shenzhugeliang"] = "丞相千古",
	["designer:MR_shenzhugeliang"] = "俺的西木野Maki",
	["cv:MR_shenzhugeliang"] = "“千古一相”",
	["illustrator:MR_shenzhugeliang"] = "三国志13,时光流逝FC",
	["MR_jincui"] = "尽瘁",
	[":MR_jincui"] = "锁定技，回合开始时，你将体力上限和体力值调整为7并于回合结束后调整为原始体力上限和体力值，然后观看牌堆顶五张牌，并将这些牌以任意顺序置于牌堆顶或牌堆底。",
	["$MR_jincui1"] = "此身抱薪，可付丹鼎，五十四年春秋昭炎汉长明。",
	["$MR_jincui2"] = "南征北伐，誓还旧都，二十四代王业不偏安一隅。",
	["MR_qingshi"] = "情势",
	["MR_qingshi:1"] = "造成的伤害+1",
	["MR_qingshi:2"] = "非目标摸一张牌",
	["MR_qingshi:3"] = "摸等量于体力上限数量的牌",
	["#mrqingshichoice"] = "%from 选择了 %arg",
	["#mrqingshicarddamage"] = "%from 选择令 %card 造成的伤害+1",
	["#mrqingshicardremove"] = "%from 选择将 %to 从 %card 的目标中移除",
	["#mrqingshicardadd"] = "%from 选择令 %to 成为 %card 的目标",
	["#mrqingshifail"] = "%from 因选择了 %arg ，本回合 %arg2 失效",
	[":MR_qingshi"] = "锁定技，当你使用牌时，若你的手牌中有同名牌，你选择一项：1.令此牌造成的伤害+1；2.令不为此牌的目标摸一张牌；3.摸等量于你体力上限数量的牌，然后本回合此技能无效。",
	["$MR_qingshi1"] = "平二川，定三足，恍惚草堂梦里，挥斥千古风流。",
	["$MR_qingshi2"] = "战群儒，守空城，今摆乱石八阵，笑谈将军死生。",
	["MR_zhizhe"] = "智哲",
	[":MR_zhizhe"] = "<font color='green'><b>出牌阶段每种牌名限一次，</b></font>你可以选择一张手牌中的基本牌或普通锦囊牌，若如此做，你视为使用这张牌。",
	["$MR_zhizhe1"] = "三顾之谊铭心，隆中之言在耳，请托臣讨贼兴复之效。",
	["$MR_zhizhe2"] = "著大义于四海，揽天下之弼士，诚如是，则汉室可兴。",
	["~MR_shenzhugeliang"] = "一别隆中三十载，归来犹唱梁甫吟......",
}
---------------------------------
sgs.Sanguosha:addSkills(skills)
---------------------------------
return {extension_MRmou}
