--==《三国 杀神附体——鬼》==--
extension = sgs.Package("keguibao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()


guichangetupo = sgs.CreateTriggerSkill {
	name = "guichangetupo",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--鬼曹操
		if (player:hasSkill("keguiduoyi")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguicaocao", false, true, player:getGeneral2Name()=="keguicaocao", false)
			end
		end
		--鬼张飞
		if (player:hasSkill("keguilongyin")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguizhangfei", false, true, player:getGeneral2Name()=="keguizhangfei", false)
			end
		end
		--鬼关羽
		if (player:hasSkill("keguiwumo")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguiguanyu", false, true, player:getGeneral2Name()=="keguiguanyu", false)
			end
		end
		if (player:hasSkill("keguisheji")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguilvbu", false, true, player:getGeneral2Name()=="keguilvbu", false)
			end
		end
		if (player:hasSkill("keguixiaoshou")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguihuaxiong", false, true, player:getGeneral2Name()=="keguihuaxiong", false)
			end
		end
		if (player:hasSkill("keguizhuangshen")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguizhugeliang", false, true, player:getGeneral2Name()=="keguizhugeliang", false)
			end
		end
		if (player:hasSkill("keguitiqi")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguicaojie", false, true, player:getGeneral2Name()=="keguicaojie", false)
			end
		end
		if (player:hasSkill("keguishouye")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguisimahui", false, true, player:getGeneral2Name()=="keguisimahui", false)
			end
		end
		if (player:hasSkill("keguiqinwang")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieguishamoke", false, true, player:getGeneral2Name()=="keguishamoke", false)
				local hp = player:getMaxHp()
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
			end
		end
	end,
	priority = 5,
}
if not sgs.Sanguosha:getSkill("guichangetupo") then skills:append(guichangetupo) end









keguicaocao = sgs.General(extension, "keguicaocao$", "kegui", 4, true)

--多疑
keguiduoyi = sgs.CreateTriggerSkill {
	name = "keguiduoyi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if (use.card:isNDTrick()) and use.from:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.play_animation = true
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						local players = sgs.SPlayerList()
						for _, pp in sgs.qlist(use.to) do
							players:append(pp)
						end
						if players:contains(player) then
							players:removeOne(player)
						end
						if not players:isEmpty() then
							local daomeidan = room:askForPlayersChosen(player, players, self:objectName(), 0, 99,
								"guicaocao-ask", false, true)
							local no_respond_list = use.no_respond_list
							for _, szm in sgs.qlist(daomeidan) do
								table.insert(no_respond_list, szm:objectName())
							end
							use.no_respond_list = no_respond_list
							data:setValue(use)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
keguicaocao:addSkill(keguiduoyi)


keguixianjiCard = sgs.CreateSkillCard {
	name = "keguixianjiCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("keguixianji")
			and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("keguixianjiInvoked")
	end,
	on_use = function(self, room, source, targets)
		local caocao = targets[1]
		if caocao:hasLordSkill("keguixianji") then
			room:setPlayerFlag(caocao, "keguixianjiInvoked")
			room:notifySkillInvoked(caocao, "keguixianji")
			caocao:obtainCard(self)
			room:setPlayerFlag(source, "Forbidkeguixianji")
		end
	end
}

keguixianjiVS = sgs.CreateViewAsSkill {
	name = "keguixianjiVS&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isNDTrick()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local xjcard = keguixianjiCard:clone()
		xjcard:addSubcard(cards[1])
		return xjcard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasFlag("Forbidkeguixianji"))
	end
}
if not sgs.Sanguosha:getSkill("keguixianjiVS") then skills:append(keguixianjiVS) end


keguixianji = sgs.CreateTriggerSkill {
	name = "keguixianji$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnStart, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if (triggerEvent == sgs.TurnStart) or (triggerEvent == sgs.EventAcquireSkill and data:toString() == "keguixianji") then
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if not p:hasSkill("keguixianjiVS") then
					room:attachSkillToPlayer(p, "keguixianjiVS")
				end
			end
		elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "keguixianji" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if p:hasSkill("keguixianjiVS") then
					room:detachSkillFromPlayer(p, "keguixianjiVS", true)
				end
			end
		elseif (triggerEvent == sgs.EventPhaseChanging) then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("Forbidkeguixianji") then
				room:setPlayerFlag(player, "-Forbidkeguixianji")
			end
			local players = room:getOtherPlayers(player);
			for _, p in sgs.qlist(players) do
				if p:hasFlag("keguixianjiInvoked") then
					room:setPlayerFlag(p, "-keguixianjiInvoked")
				end
			end
		end
		return false
	end,
}
keguicaocao:addSkill(keguixianji)






keguizhangfei = sgs.General(extension, "keguizhangfei", "kegui", 4, true)

--龙吟
keguilongyin = sgs.CreateTargetModSkill {
	name = "keguilongyin",
	distance_limit_func = function(self, from, card)
		if (from:hasSkill(self:objectName())) and card:isKindOf("Slash") and card:isBlack() then
			return 1000
		else
			return 0
		end
	end,
}
keguizhangfei:addSkill(keguilongyin)

keguihuxiao = sgs.CreateTargetModSkill {
	name = "keguihuxiao",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and card:isRed() then
			return 1
		else
			return 0
		end
	end,
}
keguizhangfei:addSkill(keguihuxiao)

keguizhangfeiaaa = sgs.CreateTriggerSkill {
	name = "#keguizhangfeiaaa",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("keguilongyin")
		end
	end
}
keguizhangfei:addSkill(keguizhangfeiaaa)


keguiguanyu = sgs.General(extension, "keguiguanyu", "kegui", 4, true)

keguiwumo = sgs.CreateTriggerSkill {
	name = "keguiwumo",
	events = { sgs.TargetSpecified, sgs.CardResponded },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.TargetSpecified and player:getPhase() == sgs.Player_Play then
			if use.card:isKindOf("Slash") then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1, self:objectName())
				end
			end
		end
		if event == sgs.CardResponded and player:getPhase() == sgs.Player_Play then
			local card_star = data:toCardResponse().m_card
			local room = player:getRoom()
			if card_star:isKindOf("Slash") then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1, self:objectName())
				end
			end
		end
	end
}
keguiguanyu:addSkill(keguiwumo)

keguituodao = sgs.CreateTriggerSkill {
	name = "keguituodao",
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Jink") then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:inMyAttackRange(p, 0, true) and player:canSlash(p, nil, false) then
					players:append(p)
				end
			end
			--local target = room:askForPlayerChosen(player, players, self:objectName(), "tuodao-ask", true, true)
			--if target then
			--	slash = room:askForUseSlashTo(player, target, "usetuodao", false)
			--end
			room:askForUseSlashTo(player, players, "usetuodao", false)
		end
	end
}
keguiguanyu:addSkill(keguituodao)



keguilvbu = sgs.General(extension, "keguilvbu", "kegui", 4, true)

keguisheji = sgs.CreateTriggerSkill {
	name = "keguisheji",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if player:getPhase() == sgs.Player_Play and use.card:isKindOf("Slash") then
			local no_respond_list = use.no_respond_list
			local targets = sgs.SPlayerList()
			for _, szm in sgs.qlist(use.to) do
				if player:inMyAttackRange(szm, 0, true) and szm:inMyAttackRange(player, 0, true) then
					table.insert(no_respond_list, szm:objectName())
					targets:append(szm)
					room:broadcastSkillInvoke(self:objectName())
				end
			end
			use.no_respond_list = no_respond_list
			data:setValue(use)
			if not targets:isEmpty() then
                local log = sgs.LogMessage()
				log.type = "$NoRespond"
				log.from = use.from
				log.to = targets
				log.arg = self:objectName()
				log.card_str = use.card:toString()
				room:sendLog(log)
            end
		end
	end
}
keguilvbu:addSkill(keguisheji)

keguijueluone = sgs.CreateTargetModSkill {
	name = "keguijueluone",
	distance_limit_func = function(self, from, card)
		if (from:hasSkill(self:objectName())) and card:isKindOf("Slash") and from:isLastHandCard(card) then
			return 1000
		else
			return 0
		end
	end,
}
keguilvbu:addSkill(keguijueluone)

keguijuelutwo = sgs.CreateTargetModSkill {
	name = "#keguijuelutwo",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill("keguijueluone") and from:isLastHandCard(card) then
			return 1
		else
			return 0
		end
	end,
}
keguilvbu:addSkill(keguijuelutwo)
extension:insertRelatedSkills("keguijueluone", "#keguijuelutwo")


keguihuaxiong = sgs.General(extension, "keguihuaxiong", "kegui", 4, true)

keguixiaoshou = sgs.CreateTriggerSkill {
	name = "keguixiaoshou",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local target = damage.from
		if target and target:hasEquip() then
			local equiplist = {}
			for i = 0, 3, 1 do
				if not target:getEquip(i) then continue end
				if player:canDiscard(target, target:getEquip(i):getEffectiveId()) or (player:getEquip(i) == nil) then
					table.insert(equiplist, tostring(i))
				end
			end
			if #equiplist == nil then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local _data = sgs.QVariant()
			_data:setValue(target)
			local room = player:getRoom()
			local equip_index = tonumber(room:askForChoice(player, "keguixiaoshou_equip", table.concat(equiplist, "+"),
				_data))
			local card = target:getEquip(equip_index)
			local card_id = card:getEffectiveId()
			room:broadcastSkillInvoke(self:objectName())
			player:obtainCard(card)
			local choice = room:askForChoice(player, self:objectName(), "give+move+cancel")
			if choice == "give" then
				local fri = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "xiaoshou-ask", true,
					true)
				if fri then
					fri:obtainCard(card)
				end
			end
			if choice == "move" then
				local fri = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "xiaoshou-ask", true,
					true)
				if fri then
					if (fri:getEquip(equip_index) == nil) then
						room:moveCardTo(card, fri, sgs.Player_PlaceEquip)
					else
						fri:obtainCard(card)
					end
				end
			end
		end
		return false
	end
}
keguihuaxiong:addSkill(keguixiaoshou)



--鬼诸葛亮
keguizhugeliang = sgs.General(extension, "keguizhugeliang", "kegui", 3, true)

keguizhuangshen = sgs.CreateTriggerSkill {
	name = "keguizhuangshen",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					local person = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"zhuangshenskill-ask", true, true)
					local skill_list = {}
					for _, skill in sgs.qlist(person:getVisibleSkillList()) do
						if (not table.contains(skill_list, skill:objectName())) and not skill:isAttachedLordSkill() then
							table.insert(skill_list, skill:objectName())
						end
					end
					local skill_qc = ""
					if (#skill_list > 0) then
						local dest = sgs.QVariant()
						dest:setValue(person)
						skill_qc = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"), dest)
					end
					if (skill_qc ~= "") then
						room:acquireNextTurnSkills(player, self:objectName(), skill_qc)
					end
				end
			end
		end
	end,
}
keguizhugeliang:addSkill(keguizhuangshen)

keguiqimen = sgs.CreateProhibitSkill {
	name = "keguiqimen",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("DelayedTrick"))
	end
}
keguizhugeliang:addSkill(keguiqimen)


--鬼曹节
keguicaojie = sgs.General(extension, "keguicaojie", "kegui", 3, false)

keguitiqiCard = sgs.CreateSkillCard {
	name = "keguitiqiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets < self:subcardsLength()) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		room:loseHp(player)
		for _, p in ipairs(targets) do
			room:damage(sgs.DamageStruct(self:objectName(), player, p))
		end
	end
}

keguitiqi = sgs.CreateViewAsSkill {
	name = "keguitiqi",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = keguitiqiCard:clone()
			for i = 1, #cards, 1 do
				card:addSubcard(cards[i])
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#keguitiqiCard"))
	end,
}
keguicaojie:addSkill(keguitiqi)

keguizhixi = sgs.CreateTriggerSkill {
	name = "keguizhixi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
						or move.from_places:contains(sgs.Player_PlaceEquip)))
				and not (move.to and (move.to:objectName() == player:objectName()
					and (move.to_place == sgs.Player_PlaceHand
						or move.to_place == sgs.Player_PlaceEquip))) then
				local canuse = false
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Jink") then
						canuse = true
						break
					end
				end
				if canuse then
					if player:askForSkillInvoke("keguizhixi", data) then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
					end
				end
			end
		end
	end,
}
keguicaojie:addSkill(keguizhixi)

keguifuwang = sgs.CreateTriggerSkill {
	name = "keguifuwang",
	on_trigger = function()
	end
}
keguicaojie:addSkill(keguifuwang)





keguisimahui = sgs.General(extension, "keguisimahui", "qun", 3)

--授业
keguishouyeCard = sgs.CreateSkillCard {
	name = "keguishouyeCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		target:drawCards(2, self:objectName())
	end
}
keguishouyeVS = sgs.CreateViewAsSkill {
	name = "keguishouye",
	n = 1,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end,

	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = keguishouyeCard:clone()
		card:addSubcard(cards[1])
		return card
	end,

	enabled_at_play = function(self, player)
		return not (player:hasUsed("#keguishouyeCard"))
	end,
}
keguishouye = sgs.CreatePhaseChangeSkill {
	name = "keguishouye",
	view_as_skill = keguishouyeVS,
	on_phasechange = function()
	end
}
keguisimahui:addSkill(keguishouye)

--解惑

keguijiehuoCard = sgs.CreateSkillCard {
	name = "keguijiehuoCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {}
		--死亡角色加入表中
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if p:isDead() then
				table.insert(choices, p:getGeneralName())
			end
		end
		if #choices > 0 then
			table.insert(choices, "cancel")
			--玩家选择一名死亡的角色
			local choice = room:askForChoice(source, "shenji-ask", table.concat(choices, "+"))
			if not (choice == "cancel") then
				for _, pp in sgs.qlist(room:getAllPlayers(true)) do
					--判断死亡的人的名字，跟选择的人是否符合，令其复活
					if pp:isDead() and (pp:getGeneralName() == choice) then
						room:removePlayerMark(source, "@guijiehuo")
						room:doAnimate(1, source:objectName(), pp:objectName())
						room:revivePlayer(pp)
						pp:throwAllMarks()
						local hp = math.min(pp:getMaxHp(), 3)
						room:setPlayerProperty(pp, "hp", sgs.QVariant(hp))
						pp:drawCards(3)
					end
				end
			end
		end
	end
}

keguijiehuoVS = sgs.CreateViewAsSkill {
	name = "keguijiehuo",
	n = 4,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() or sgs.Self:isJilei(to_select) then
			return false
		end
		for _, ca in sgs.list(selected) do
			if ca:getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 4 then return nil end
		local jhCard = keguijiehuoCard:clone()
		for _, card in ipairs(cards) do
			jhCard:addSubcard(card)
		end
		return jhCard
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@guijiehuo") > 0) and (player:getMark("canjiehuo") > 0)
	end
}
keguijiehuo = sgs.CreateTriggerSkill {
	name = "keguijiehuo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@guijiehuo",
	view_as_skill = keguijiehuoVS,
	on_trigger = function()
	end
}
keguisimahui:addSkill(keguijiehuo)

keguisimahuimarkget = sgs.CreateTriggerSkill {
	name = "#keguisimahuimarkget",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local smhs = room:findPlayersBySkillName("keguijiehuo")
		for _, smh in sgs.qlist(smhs) do
			if (smh:getMark("@guijiehuo") > 0) then
				room:setPlayerMark(smh, "canjiehuo", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
keguisimahui:addSkill(keguisimahuimarkget)




keguishamoke = sgs.General(extension, "keguishamoke", "shu", 4)

keguiqinwang = sgs.CreateTriggerSkill {
	name = "keguiqinwang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted, sgs.EventPhaseChanging, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local be = damage.to
			for _, smk in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (smk:getPhase() == sgs.Player_NotActive) and (be:objectName() ~= smk:objectName()) then
					local to_data = sgs.QVariant()
					to_data:setValue(be)
					room:setTag("CurrentDamageStruct", data)
					if room:askForSkillInvoke(smk, self:objectName(), to_data) then
						damage.to = smk
						room:broadcastSkillInvoke(self:objectName())
						damage.transfer = true
						data:setValue(damage)
						room:addPlayerMark(smk, "@guiqinwang", damage.damage)
						break
					end
					room:removeTag("CurrentDamageStruct")
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@guiqinwang", 0)
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if (damage.from:getPhase() == sgs.Player_Play) and (damage.from:getMark("@guiqinwang") > 0)
				and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				local hurt = damage.damage
				damage.damage = hurt + damage.from:getMark("@guiqinwang")
				room:broadcastSkillInvoke(self:objectName())
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
keguishamoke:addSkill(keguiqinwang)











--界鬼曹操
kejieguicaocao = sgs.General(extension, "kejieguicaocao$", "kegui", 4, true)

--多疑
kejieguiduoyi = sgs.CreateTriggerSkill {
	name = "kejieguiduoyi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetSpecified, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if (use.card:isNDTrick() or use.card:isKindOf("Slash")) and use.from:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = true
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					if judge.card:isBlack() then
						local players = sgs.SPlayerList()
						for _, pp in sgs.qlist(use.to) do
							players:append(pp)
						end
						if players:contains(player) then
							players:removeOne(player)
						end
						if not players:isEmpty() then
							local daomeidan = room:askForPlayersChosen(player, players, self:objectName(), 0, 99,
								"guicaocao-ask", false, true)
							local no_respond_list = use.no_respond_list
							for _, szm in sgs.qlist(daomeidan) do
								table.insert(no_respond_list, szm:objectName())
								room:addPlayerMark(szm, "@skill_invalidity")
								room:setPlayerFlag(szm, "beduoyiskill")
							end
							use.no_respond_list = no_respond_list
							data:setValue(use)
						end
					elseif judge.card:isRed() then
						player:drawCards(1)
					end
				end
			end
		end
		if event == sgs.CardFinished then
			if (use.card:isNDTrick() or use.card:isKindOf("Slash")) and use.from:hasSkill(self:objectName()) then
				for _, dmd in sgs.qlist(room:getAllPlayers()) do
					if dmd:getMark("@skill_invalidity") > 0 and dmd:hasFlag("beduoyiskill") then
						room:removePlayerMark(dmd, "@skill_invalidity")
						room:setPlayerFlag(dmd, "-beduoyiskill")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
kejieguicaocao:addSkill(kejieguiduoyi)



kejieguixianjiCard = sgs.CreateSkillCard {
	name = "kejieguixianjiCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("kejieguixianji")
			and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("kejieguixianjiInvoked")
	end,
	on_use = function(self, room, source, targets)
		local caocao = targets[1]
		if caocao:hasLordSkill("kejieguixianji") then
			room:setPlayerFlag(caocao, "kejieguixianjiInvoked")
			room:notifySkillInvoked(caocao, "kejieguixianji")
			caocao:obtainCard(self)
			local id = self:getSubcards():first()
			if sgs.Sanguosha:getCard(id):isAvailable(caocao) then
				--room:askForUseCard(caocao, ""..id, "jieguixianji-ask")
				room:askForUseCard(caocao, "TrickCard+^Nullification|.|.|hand", "jieguixianji-ask")
			end
			room:setPlayerFlag(source, "Forbidkejieguixianji")
		end
	end
}

kejieguixianjiVS = sgs.CreateViewAsSkill {
	name = "kejieguixianjiVS&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isNDTrick()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local xjCard = kejieguixianjiCard:clone()
		xjCard:addSubcard(cards[1])
		return xjCard
	end,
	enabled_at_play = function(self, player)
		--if player:getKingdom() == "gui" then
		return (not player:hasFlag("Forbidkejieguixianji"))
		--end
	end
}
if not sgs.Sanguosha:getSkill("kejieguixianjiVS") then skills:append(kejieguixianjiVS) end


kejieguixianji = sgs.CreateTriggerSkill {
	name = "kejieguixianji$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnStart, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if (triggerEvent == sgs.TurnStart) or (triggerEvent == sgs.EventAcquireSkill and data:toString() == "kejieguixianji") then
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if not p:hasSkill("kejieguixianjiVS") then
					room:attachSkillToPlayer(p, "kejieguixianjiVS")
				end
			end
		elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "kejieguixianji" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if p:hasSkill("kejieguixianjiVS") then
					room:detachSkillFromPlayer(p, "kejieguixianjiVS", true)
				end
			end
		elseif (triggerEvent == sgs.EventPhaseChanging) then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("Forbidkejieguixianji") then
				room:setPlayerFlag(player, "-Forbidkejieguixianji")
			end
			local players = room:getOtherPlayers(player);
			for _, p in sgs.qlist(players) do
				if p:hasFlag("kejieguixianjiInvoked") then
					room:setPlayerFlag(p, "-kejieguixianjiInvoked")
				end
			end
		end
		return false
	end,
}
kejieguicaocao:addSkill(kejieguixianji)



--界鬼诸葛亮
kejieguizhugeliang = sgs.General(extension, "kejieguizhugeliang", "kegui", 3, true)

kejieguizhuangshen = sgs.CreateTriggerSkill {
	name = "kejieguizhuangshen",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("guidawu") > 0 then
					local num = p:getMark("guidawu")
					room:setPlayerMark(p, "guidawu", 0)
					room:removePlayerMark(p, "&dawu", num)
				end
				if p:getMark("guikuangfeng") > 0 then
					local numm = p:getMark("guikuangfeng")
					room:setPlayerMark(p, "guikuangfeng", 0)
					room:removePlayerMark(p, "&kuangfeng", numm)
				end
			end
		end
		if (player:getPhase() == sgs.Player_Start) or (player:getPhase() == sgs.Player_Finish) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge.card:isBlack() then
					local person = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"zhuangshenskill-ask", true, true)
					if person then
						local skill_list = {}
						for _, skill in sgs.qlist(person:getVisibleSkillList()) do
							if (not table.contains(skill_list, skill:objectName())) and not skill:isAttachedLordSkill() then
								table.insert(skill_list, skill:objectName())
							end
						end
						local skill_qc = ""
						if (#skill_list > 0) then
							local dest = sgs.QVariant()
							dest:setValue(person)
							skill_qc = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"), dest)
						end
						if (skill_qc ~= "") then
							room:acquireNextTurnSkills(player, self:objectName(), skill_qc)
						end
					end
				elseif judge.card:isRed() then
					local person = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName() .. "buff",
						"zhuangshengod-ask", true, true)
					if person then
						local dest = sgs.QVariant()
						dest:setValue(person)
						local choice = room:askForChoice(player, self:objectName() .. "buff",
							"guikuangfeng+guidawu+cancel", dest)
						ChoiceLog(player, choice)
						if choice == "guidawu" then
							room:addPlayerMark(person, "&dawu", 1)
							room:addPlayerMark(person, "guidawu", 1)
						end
						if choice == "guikuangfeng" then
							room:addPlayerMark(person, "&kuangfeng", 1)
							room:addPlayerMark(person, "guikuangfeng", 1)
						end
					end
				end
			end
		end
	end,
}
kejieguizhugeliang:addSkill(kejieguizhuangshen)

kejieguiqimen = sgs.CreateProhibitSkill {
	name = "kejieguiqimen",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("DelayedTrick"))
	end
}
kejieguizhugeliang:addSkill(kejieguiqimen)

keguizgldamage = sgs.CreateTriggerSkill {
	name = "#keguizgldamage",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageForseen, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if event == sgs.DamageForseen then
			local benti = room:findPlayerBySkillName("qixing")
			if not benti then
				if (damage.nature ~= sgs.DamageStruct_Thunder) and (damage.to:getMark("&dawu") > 0) then
					room:sendCompulsoryTriggerLog(player, "kejieguizhuangshen")
					return true
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local benti = room:findPlayerBySkillName("qixing")
			if not benti then
				if (damage.to:getMark("&kuangfeng") > 0) and (damage.nature == sgs.DamageStruct_Fire) then
					local hurt = damage.damage
					damage.damage = hurt + 1
					room:sendCompulsoryTriggerLog(player, "kejieguiqimen")
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejieguizhugeliang:addSkill(keguizgldamage)

extension:insertRelatedSkills("kejieguizhuangshen", "#keguizgldamage")

kejieguizhugeliangdeath = sgs.CreateTriggerSkill {
	name = "kejieguizhugeliangdeath",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("guidawu") > 0 then
						room:removePlayerMark(p, "guidawu")
						room:removePlayerMark(p, "&dawu")
					end
					if p:getMark("guikuangfeng") > 0 then
						room:removePlayerMark(p, "guikuangfeng")
						room:removePlayerMark(p, "&kuangfeng")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill("kejieguizhuangshen")
	end,
}
if not sgs.Sanguosha:getSkill("kejieguizhugeliangdeath") then skills:append(kejieguizhugeliangdeath) end

--界鬼诸葛亮第二版
kejieguizhugeliangtwo = sgs.General(extension, "kejieguizhugeliangtwo", "kegui", 3, true)

kejieguiqideng = sgs.CreateTriggerSkill {
	name = "kejieguiqideng",
	events = { sgs.EnterDying },
	frequency = sgs.Skill_Limited,
	limit_mark = "@kejieguiqideng",
	on_trigger = function(self, event, player, data, room)
		if (player:getMark("@kejieguiqideng") == 0) and (player:getMark("@kedeng") > 0) then
			room:setPlayerFlag(player, "-Global_Dying")
			return true
		end
		if (player:getMark("@kejieguiqideng") > 0) and (room:askForSkillInvoke(player, self:objectName(), data)) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:doSuperLightbox("kejieguizhugeliangtwo", "kejieguiqideng")
			player:gainMark("@kedeng", 7)
			room:removePlayerMark(player, "@kejieguiqideng")
			room:setPlayerFlag(player, "-Global_Dying")
			local currentdying = room:getTag("CurrentDying"):toStringList()
			table.removeOne(currentdying,player:objectName())
			room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
			return true
		end
	end,
}
kejieguizhugeliangtwo:addSkill(kejieguiqideng)

kejieguiqidengex = sgs.CreateTriggerSkill {
	name = "kejieguiqidengex",
	global = true,
	events = { sgs.EventPhaseStart, sgs.Damaged, sgs.MarkChanged },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start)
			or (event == sgs.Damaged) then
			if player:getMark("@kedeng") > 0 then
				room:broadcastSkillInvoke("kejieguiqideng", 3)
				player:loseMark("@kedeng")
			end
		end
		if (event == sgs.MarkChanged) then
			local mark = data:toMark()
			if mark.name == "@kedeng" then
				if mark.count == 0 then
					room:broadcastSkillInvoke("kejieguijingmu", 2)
					room:killPlayer(player)
				end
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("kejieguiqidengex") then skills:append(kejieguiqidengex) end



kejieguizhashiCard = sgs.CreateSkillCard {
	name = "kejieguizhashiCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to, effect.from, "keguizhashi-ask", true, false, false, nil, nil,
				"zhashicardflag")
		end
		if (not use_slash) then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
		end
	end
}
kejieguizhashiVS = sgs.CreateViewAsSkill {
	name = "kejieguizhashi",
	n = 0,
	view_as = function()
		return kejieguizhashiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kejieguizhashiCard")
	end
}

kejieguizhashi = sgs.CreateTriggerSkill {
	name = "kejieguizhashi",
	view_as_skill = kejieguizhashiVS,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local room = player:getRoom()
			if damage.card and damage.card:hasFlag("zhashicardflag") then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade,club,diamond|.|."
				judge.who = player
				judge.play_animation = true
				judge.reason = "kejieguizhashi"
				judge.good = true
				room:judge(judge)
				if judge:isGood() then
					local death = sgs.DeathStruct()
					death.who = player
					death.damage = damage
					local _data = sgs.QVariant()
					_data:setValue(death)
					room:getThread():delay(500)
					room:getThread():trigger(sgs.Death, room, player, _data)
					room:getThread():trigger(sgs.BuryVictim, room, player, _data)
					return true
				end
			end
		end
	end,
}
kejieguizhugeliangtwo:addSkill(kejieguizhashi)

kejieguijingmu = sgs.CreateTriggerSkill {
	name = "kejieguijingmu",
	events = { sgs.Death },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer and killer:objectName() ~= player:objectName() then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(killer, "@skill_invalidity", 1)
			room:addPlayerMark(killer, "keguijingmumark", 1)
		end
		return false
	end
}
kejieguizhugeliangtwo:addSkill(kejieguijingmu)

kejieguijingmubuff = sgs.CreateTriggerSkill {
	name = "kejieguijingmubuff",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageCaused then
			if player:getMark("keguijingmumark") > 0 then
				local damage = data:toDamage()
				local room = player:getRoom()
				room:sendCompulsoryTriggerLog(player, self:objectName())

				local sh = damage.damage
				if sh == 1 then
					room:removePlayerMark(player, "@skill_invalidity", player:getMark("keguijingmumark"))
					room:removePlayerMark(player, "keguijingmumark", player:getMark("keguijingmumark"))
					return true
				end
				if sh > 1 then
					damage.damage = sh - 1
					room:removePlayerMark(player, "@skill_invalidity", player:getMark("keguijingmumark"))
					room:removePlayerMark(player, "keguijingmumark", player:getMark("keguijingmumark"))
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end,
}
if not sgs.Sanguosha:getSkill("kejieguijingmubuff") then skills:append(kejieguijingmubuff) end













--界鬼张飞
kejieguizhangfei = sgs.General(extension, "kejieguizhangfei", "kegui", 4, true)

function getCardListgui(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

kejieguilongyin = sgs.CreateTriggerSkill {
	name = "kejieguilongyin",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local choices = {}
					for i = 0, 4 do
						if player:hasEquipArea(i) then
							table.insert(choices, i)
						end
					end
					if choices == "" then return false end
					local choice = room:askForChoice(player, "guijueqiao-ask", table.concat(choices, "+"))
					local area = tonumber(choice), 0
					player:throwEquipArea(area)
					room:addPlayerMark(player, "guijueqiao")
					room:addPlayerMark(player, "kejieguijueqiaocishu")
					local num = player:getMark("kejieguijueqiaocishu")
					local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(),
						"guijueqiaoplayer-ask", true, true)
					if target then
						room:addPlayerMark(target, "&kejieguijueqiao", num)
					end
				end
			end
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kejieguijueqiao") > 0 then
						room:setPlayerMark(p, "&kejieguijueqiao", 0)
					end
					if p:getMark("guijueqiao") > 0 then
						room:setPlayerMark(p, "guijueqiao", 0)
					end
				end
			end
		end
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from == nil or move.from:objectName() == player:objectName() then return false end
			if move.to_place == sgs.Player_DiscardPile and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				local card_ids = sgs.IntList()
				local to_get = sgs.IntList()
				local i = 0
				for _, card_id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(card_id):isKindOf("Slash") and ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE and room:getCardOwner(card_id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip))) then
						card_ids:append(card_id)
					end
					i = i + 1
				end
				if card_ids:isEmpty() then
					return false
				else
					if player:getMark("guijueqiao") > 0 then
						if player:askForSkillInvoke("jueqiaogainslash", data) then
							while not card_ids:isEmpty() do
								room:fillAG(card_ids, player)
								local card_id = room:askForAG(player, card_ids, true, self:objectName())
								if card_id then
									card_ids:removeOne(card_id)
									to_get:append(card_id)
									room:takeAG(player, card_id, false)
								end
								room:clearAG(player)
							end
							if not to_get:isEmpty() then
								move:removeCardIds(to_get)
								data:setValue(move)
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								dummy:addSubcards(to_get)
								dummy:deleteLater()
								room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
							end

							--[[if not to_get:isEmpty() then
							    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

								dummy:addSubcards(getCardListgui(to_get))
								--dummy:addSubcards(getCardList(to_throw))
								player:obtainCard(dummy)
								dummy:deleteLater()
							end
							]]
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
kejieguizhangfei:addSkill(kejieguilongyin)

--距离
kejieguijueqiaojl = sgs.CreateDistanceSkill {
	name = "kejieguijueqiaojl",
	global = true,
	correct_func = function(self, from, to)
		if (to:getMark("&kejieguijueqiao") > 0) then
			return to:getMark("&kejieguijueqiao")
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kejieguijueqiaojl") then skills:append(kejieguijueqiaojl) end

kejieguijueqiaosjl = sgs.CreateTargetModSkill {
	name = "#kejieguijueqiaosjl",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("kejieguilongyin") then
			return from:getMark("kejieguijueqiaocishu")
		end
	end
}
kejieguizhangfei:addSkill(kejieguijueqiaosjl)


--啸吟
kejieguixiaoyin = sgs.CreateTargetModSkill {
	name = "kejieguixiaoyin",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill("kejieguixiaoyin") and card:isRed() then
			return 1
		else
			return 0
		end
	end,
	residue_func = function(self, from, card)
        if from:hasSkill("kejieguixiaoyin")
			and card:isBlack() then return 1000 end
        return 0
    end,
}
kejieguizhangfei:addSkill(kejieguixiaoyin)


kejieguixiaoyinex = sgs.CreateTriggerSkill {
	name = "#kejieguixiaoyinex",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.card:isBlack() then
			if use.from:hasSkill(self:objectName()) then
				if use.m_addHistory then
					room:addPlayerHistory(player, use.card:getClassName(), -1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
kejieguizhangfei:addSkill(kejieguixiaoyinex)
extension:insertRelatedSkills("kejieguixiaoyin", "#kejieguixiaoyinex")

kejieguixiaoyinexex = sgs.CreateTriggerSkill {
	name = "#kejieguixiaoyinexex",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
			local hurt = damage.damage
			damage.damage = hurt + 1
			data:setValue(damage)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end
}
kejieguizhangfei:addSkill(kejieguixiaoyinexex)
extension:insertRelatedSkills("kejieguixiaoyin", "#kejieguixiaoyinexex")
kejieguizhangfeiaaa = sgs.CreateTriggerSkill {
	name = "#kejieguizhangfeiaaa",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("kejieguilongyin")
		end
	end
}

kejieguizhangfei:addSkill(kejieguizhangfeiaaa)
extension:insertRelatedSkills("kejieguixiaoyin", "#kejieguizhangfeiaaa")




--界鬼关羽
kejieguiguanyu = sgs.General(extension, "kejieguiguanyu", "kegui", 4, true)

kejieguiwumo = sgs.CreateTriggerSkill {
	name = "kejieguiwumo",
	events = { sgs.TargetSpecified, sgs.CardResponded },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local room = player:getRoom()
			if use.card:isKindOf("Slash") then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local mp = 1
					if use.card:isRed() then
						mp = 2
					end
					player:drawCards(mp, self:objectName())
				end
			end
		end
		if event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card
			local room = player:getRoom()
			if card_star:isKindOf("Slash") then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local mp = 1
					if card_star:isRed() then
						mp = 2
					end
					player:drawCards(mp, self:objectName())
				end
			end
		end
	end
}
kejieguiguanyu:addSkill(kejieguiwumo)


kejieguituodao = sgs.CreateTriggerSkill {
	name = "kejieguituodao",
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Jink") then
			local result = room:askForChoice(player, self:objectName(), "dao+sha")
			if result == "dao" then
				room:setPlayerMark(player, "&jieguiwumozhuangbei-SelfClear", 1)
			end
			if result == "sha" then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(p, nil, false) then
						players:append(p)
					end
				end
				if players:length() > 0 then
					local eny = room:askForPlayerChosen(player, players, self:objectName(), "kejieguituodao-ask")
					if eny then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("kejieguituodao")
						local use = sgs.CardUseStruct()
						use.card = slash
						use.from = player
						use.to:append(eny)
						room:useCard(use)
						slash:deleteLater()
					end
				end
			end
		end
	end
}
kejieguiguanyu:addSkill(kejieguituodao)

kejieguituodaoex = sgs.CreateViewAsEquipSkill {
	name = "#kejieguituodaoex",
	view_as_equip = function(self, player)
		if player:getMark("&jieguiwumozhuangbei-SelfClear") > 0 then
			return "blade,chitu"
		end
	end
}
kejieguiguanyu:addSkill(kejieguituodaoex)
extension:insertRelatedSkills("kejieguituodao", "#kejieguituodaoex")


--界鬼吕布
kejieguilvbu = sgs.General(extension, "kejieguilvbu", "kegui", 5, true)

kejieguisheji = sgs.CreateTriggerSkill {
	name = "kejieguisheji",
	events = { sgs.TargetConfirmed, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local eny = use.from
			local to_data = sgs.QVariant()
			if use.card:isKindOf("Slash") then
				local jglbs = room:findPlayersBySkillName("kejieguisheji")
				if not jglbs:isEmpty() then
					for _, lb in sgs.qlist(jglbs) do
						if (lb:objectName() ~= eny:objectName()) and (lb:getMark("canusejieguisheji") == 0) then
							for _, fri in sgs.qlist(use.to) do
								if (lb:distanceTo(fri) <= 1) and lb:canPindian(eny) then
									to_data:setValue(fri)
									room:setTag("CurrentUseStruct", data)
									local will_use = room:askForSkillInvoke(lb, self:objectName(), to_data)
									if will_use then
										room:broadcastSkillInvoke(self:objectName())
										room:setPlayerMark(lb, "canusejieguisheji", 1)
										room:setPlayerFlag(fri, "kejieguishejiPindianTarget")
										local success = lb:pindian(eny, self:objectName(), nil)
										room:setPlayerFlag(fri, "-kejieguishejiPindianTarget")
										if success then
											local nullified_list = use.nullified_list
											table.insert(nullified_list, fri:objectName())
											use.nullified_list = nullified_list
											data:setValue(use)
											lb:drawCards(1)
										end
										if not success then
											room:damage(sgs.DamageStruct(self:objectName(), lb, eny))
										end
									end
									room:removeTag("CurrentUseStruct")
								end
							end
						end
					end
				end
			end
		end
	end,
}
kejieguilvbu:addSkill(kejieguisheji)

kejieguishejics = sgs.CreateTriggerSkill {
	name = "#kejieguishejics",
	global = true,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local glbs = room:findPlayersBySkillName("kejieguisheji")
				if not glbs:isEmpty() then
					for _, glb in sgs.qlist(glbs) do
						if glb:getMark("canusejieguisheji") > 0 then
							room:setPlayerMark(glb, "canusejieguisheji", 0)
						end
					end
				end
			end
		end
	end
}
kejieguilvbu:addSkill(kejieguishejics)
extension:insertRelatedSkills("kejieguisheji", "#kejieguishejics")

kejieguijueluone = sgs.CreateTargetModSkill {
	name = "kejieguijueluone",
	distance_limit_func = function(self, from, card)
		if (from:hasSkill(self:objectName())) and card:isKindOf("Slash") and from:isLastHandCard(card) then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and from:isLastHandCard(card) then
			return 999
		else
			return 0
		end
	end,
}
kejieguilvbu:addSkill(kejieguijueluone)




--界鬼吕布第二版
kejieguilvbutwo = sgs.General(extension, "kejieguilvbutwo", "kegui", 5, true)

kejieguilvbutwo:addSkill("kejieguisheji")
kejieguilvbutwo:addSkill("#kejieguishejics")

kejieguijuelu = sgs.CreateTriggerSkill {
	name = "kejieguijuelu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke("kejieguisheji")
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = math.max(player:getHp(), 1)
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
kejieguilvbutwo:addSkill(kejieguijuelu)


kejieguijuelutwotwo = sgs.CreateTargetModSkill {
	name = "#kejieguijuelutwotwo",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end,
}
kejieguilvbutwo:addSkill(kejieguijuelutwotwo)
extension:insertRelatedSkills("kejieguijuelu", "#kejieguijuelutwotwo")

kejieguihuaxiong = sgs.General(extension, "kejieguihuaxiong", "kegui", 4, true)

kejieguixiaoshou = sgs.CreateTriggerSkill {
	name = "kejieguixiaoshou",
	events = { sgs.Damaged, sgs.Damage },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target
		if event == sgs.Damaged then
			target = damage.from
		else
			target = damage.to
		end
		if target and target:isAlive() and player and player:isAlive() and target:hasEquip() then
			local equiplist = {}
			for i = 0, 3, 1 do
				if not target:getEquip(i) then continue end
				if player:canDiscard(target, target:getEquip(i):getEffectiveId()) or (player:getEquip(i) == nil) then
					table.insert(equiplist, tostring(i))
				end
			end
			if #equiplist == nil then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local _data = sgs.QVariant()
			_data:setValue(target)
			local room = player:getRoom()
			local equip_index = tonumber(room:askForChoice(player, "kejieguixiaoshou_equip", table.concat(equiplist, "+"),
				_data))
			local card = target:getEquip(equip_index)
			local card_id = card:getEffectiveId()
			room:broadcastSkillInvoke(self:objectName())
			player:obtainCard(card)
			player:drawCards(1)
			local choice = room:askForChoice(player, self:objectName(), "give+move+cancel")
			if choice == "give" then
				local fri = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "xiaoshou-ask", true,
					true)
				if fri then
					fri:obtainCard(card)
				end
			end
			if choice == "move" then
				local fri = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "xiaoshou-ask", true,
					true)
				if fri then
					if (fri:getEquip(equip_index) == nil) then
						room:moveCardTo(card, fri, sgs.Player_PlaceEquip)
					else
						fri:obtainCard(card)
					end
				end
			end
		end
		return false
	end
}
kejieguihuaxiong:addSkill(kejieguixiaoshou)

kejieguihuaxiongtwo = sgs.General(extension, "kejieguihuaxiongtwo", "kegui", 6, true)

kejieguilifeng = sgs.CreateTriggerSkill {
	name = "kejieguilifeng",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.GameStart, sgs.EventPhaseChanging, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("&kejieguilifeng") > 0 then
					room:addSlashCishu(player, 1, true)
					room:removePlayerMark(player, "&kejieguilifeng", 1)
				end
			end
		end
		if event == sgs.GameStart then
			room:setPlayerMark(player, "&kejieguilifeng", 4)
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				room:setPlayerMark(player, "&lfnotdamage", 1)
				room:setPlayerMark(player, "lfout", 1)
			end
			if (change.to == sgs.Player_RoundStart) then
				room:setPlayerMark(player, "lfout", 0)
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isRed() and (player:getMark("lfout") > 0) then
				room:setPlayerMark(player, "&lfnotdamage", 0)
				room:setPlayerMark(player, "&lfyesdamage", 1)
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
kejieguihuaxiongtwo:addSkill(kejieguilifeng)

kejieguilifengex = sgs.CreatePhaseChangeSkill {
	name = "kejieguilifengex",
	global = true,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if (player:getMark("&lfyesdamage") == 0) then
				local result = room:askForChoice(player, self:objectName(), "moslash+mopai")
				room:broadcastSkillInvoke("kejieguilifeng")
				if result == "moslash" then
					local slashs = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						if (sgs.Sanguosha:getCard(id):isKindOf("Slash")) then
							slashs:append(id)
						end
					end
					if not slashs:isEmpty() then
						local numone = math.random(0, slashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(slashs:at(numone)))
						local numtwo = math.random(0, slashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(slashs:at(numtwo)))
					end
					local noslashs = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						if not (sgs.Sanguosha:getCard(id):isKindOf("Slash")) then
							noslashs:append(id)
						end
					end
					if not noslashs:isEmpty() then
						local numthree = math.random(0, noslashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(noslashs:at(numthree)))
					end
				end
				if result == "mopai" then
					local slashs = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						if (sgs.Sanguosha:getCard(id):isKindOf("Slash")) then
							slashs:append(id)
						end
					end
					if not slashs:isEmpty() then
						local numone = math.random(0, slashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(slashs:at(numone)))
					end
					local noslashs = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						if not (sgs.Sanguosha:getCard(id):isKindOf("Slash")) then
							noslashs:append(id)
						end
					end
					if not noslashs:isEmpty() then
						local numtwo = math.random(0, noslashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(noslashs:at(numtwo)))
						local numthree = math.random(0, noslashs:length() - 1)
						player:obtainCard(sgs.Sanguosha:getCard(noslashs:at(numthree)))
					end
				end
				room:setPlayerMark(player, "&lfnotdamage", 0)
				room:setPlayerMark(player, "&lfyesdamage", 0)
				return true
			end
			room:setPlayerMark(player, "&lfnotdamage", 0)
			room:setPlayerMark(player, "&lfyesdamage", 0)
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill("kejieguilifeng")
	end,
}
if not sgs.Sanguosha:getSkill("kejieguilifengex") then skills:append(kejieguilifengex) end

kejieguishiyong = sgs.CreateTriggerSkill {
	name = "kejieguishiyong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local room = player:getRoom()
			if event == sgs.TargetConfirming and use.to:contains(player) and player:hasSkill(self:objectName()) then
				if use.card:isRed() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list, player:objectName())
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isRed() and damage.card:isKindOf("Slash") then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				local jius = sgs.IntList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Analeptic")) then
						jius:append(id)
					end
				end
				if not jius:isEmpty() then
					local numone = math.random(0, jius:length() - 1)
					damage.from:obtainCard(sgs.Sanguosha:getCard(jius:at(numone)))
				end
			end
		end
	end,
}
kejieguihuaxiongtwo:addSkill(kejieguishiyong)









sgs.LoadTranslationTable {
	["kejieguihuaxiongtwo"] = "界鬼华雄-第二版",
	["&kejieguihuaxiongtwo"] = "界鬼华雄",
	["#kejieguihuaxiongtwo"] = "温酒之痛",
	["designer:kejieguihuaxiongtwo"] = "杀神附体",
	["cv:kejieguihuaxiongtwo"] = "官方",
	["illustrator:kejieguihuaxiongtwo"] = "官方",

	["kejieguilifeng"] = "利锋",
	[":kejieguilifeng"] = "锁定技，你在前四个出牌阶段使用【杀】的次数限制+1。摸牌阶段，若你从上个回合结束开始没有受到过红色牌造成的伤害，你放弃摸牌并选择一项：\
	○从牌堆随机获得一张【杀】和两张不是【杀】的牌。\
	○从牌堆随机获得两张【杀】和一张不是【杀】的牌。",
	["kejieguilifengex"] = "利锋",

	["kejieguishiyong"] = "恃勇",
	[":kejieguishiyong"] = "锁定技，你不能响应红色牌。当你受到其他角色使用的红色【杀】造成的伤害后，你摸一张牌，该角色从牌堆获得一张【酒】。",

	["lfnotdamage"] = "利锋：未受到",
	["lfyesdamage"] = "利锋：已受到",

	["kejieguilifengex:moslash"] = "从牌堆获得两张【杀】和一张不是【杀】的牌",
	["kejieguilifengex:mopai"] = "从牌堆获得一张【杀】和两张不是【杀】的牌",

	["$kejieguilifeng1"] = "哼，还未接我三合，谁还来战？",
	["$kejieguilifeng2"] = "雄一人便可挡诸侯百万之众！",
	["$kejieguishiyong1"] = "关外诸侯？哼，不过草芥尔。",
	["$kejieguishiyong2"] = "待我出手，与其项上人头。",

	["~kejieguihuaxiongtwo"] = "你，你是何人？！",

}
























--界鬼曹节
kejieguicaojie = sgs.General(extension, "kejieguicaojie", "kegui", 3, false)


kejieguicaojie:addSkill("keguitiqi")

kejieguizhixi = sgs.CreateTriggerSkill {
	name = "kejieguizhixi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
						or move.from_places:contains(sgs.Player_PlaceEquip)))
				and not (move.to and (move.to:objectName() == player:objectName()
					and (move.to_place == sgs.Player_PlaceHand
						or move.to_place == sgs.Player_PlaceEquip))) then
				local canuse = 0
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Jink") then
						canuse = 1
					end
				end
				if canuse == 1 then
					if player:askForSkillInvoke("kejieguizhixi", data) then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(2)
						if player:getHp() <= 1 then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
	end
}
kejieguicaojie:addSkill(kejieguizhixi)

kejieguifuwang = sgs.CreateTriggerSkill {
	name = "kejieguifuwang",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local canuse = 0
		for _, cjdad in sgs.qlist(room:getAllPlayers()) do
			if (cjdad:getRole() == "lord") and (cjdad:getGender() == sgs.General_Male) and (damage.from and damage.from:getGender() == sgs.General_Female) then
				canuse = 1
			end
		end
		if canuse == 1 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
	end
}
kejieguicaojie:addSkill(kejieguifuwang)




kejieguisimahui = sgs.General(extension, "kejieguisimahui", "qun", 3)

--授业
kejieguishouyeCard = sgs.CreateSkillCard {
	name = "kejieguishouyeCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		target:drawCards(3, self:objectName())
		if target ~= player then
			player:drawCards(1)
		end
	end
}
kejieguishouyeVS = sgs.CreateViewAsSkill {
	name = "kejieguishouye",
	n = 1,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end,

	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kejieguishouyeCard:clone()
		card:addSubcard(cards[1])
		return card
	end,

	enabled_at_play = function(self, player)
		return not (player:hasUsed("#kejieguishouyeCard"))
	end,
}
kejieguishouye = sgs.CreatePhaseChangeSkill {
	name = "kejieguishouye",
	view_as_skill = kejieguishouyeVS,
	on_phasechange = function()
	end
}
kejieguisimahui:addSkill(kejieguishouye)

--解惑

kejieguijiehuoCard = sgs.CreateSkillCard {
	name = "kejieguijiehuoCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {}
		local yes = 0
		--死亡角色加入表中
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if p:isDead() then
				table.insert(choices, p:getGeneralName())
				yes = 1
			end
		end
		if yes == 1 then
			table.insert(choices, "cancel")
			--玩家选择一名死亡的角色
			local choice = room:askForChoice(source, "shenji-ask", table.concat(choices, "+"))
			if not (choice == "cancel") then
				for _, pp in sgs.qlist(room:getAllPlayers(true)) do
					--判断死亡的人的名字，跟选择的人是否符合，令其复活
					if pp:isDead() and (pp:getGeneralName() == choice) then
						room:setPlayerMark(source, "canjiehuo", 0)
						room:doAnimate(1, source:objectName(), pp:objectName())
						room:revivePlayer(pp)
						pp:throwAllMarks()
						room:setPlayerMark(source, "canjiehuo", 0)
						local hp = math.min(pp:getMaxHp(), 2)
						room:setPlayerProperty(pp, "hp", sgs.QVariant(hp))
						pp:drawCards(2)
						if source:getMark("&kejieguijiehuo") < 4 then
							room:addPlayerMark(source, "&kejieguijiehuo")
						end
						local oo = math.random(1, 4)
						if (oo == 1) then
							if not pp:hasSkill("olhuoji") then
								room:handleAcquireDetachSkills(pp, "olhuoji")
							else
								pp:drawCards(2)
							end
						end
						if (oo == 2) then
							if not pp:hasSkill("ollianhuan") then
								room:handleAcquireDetachSkills(pp, "ollianhuan")
							else
								pp:drawCards(2)
							end
						end
						if (oo == 3) then
							if not pp:hasSkill("jujian") then
								room:handleAcquireDetachSkills(pp, "jujian")
							else
								pp:drawCards(2)
							end
						end
						if (oo == 4) then
							if not pp:hasSkill("yinshi") then
								room:handleAcquireDetachSkills(pp, "yinshi")
							else
								pp:drawCards(2)
							end
						end
					end
				end
			end
		end
	end
}

kejieguijiehuoVS = sgs.CreateViewAsSkill {
	name = "kejieguijiehuo",
	n = 3,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() or sgs.Self:isJilei(to_select) then
			return false
		end
		for _, ca in sgs.list(selected) do
			if ca:getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 3 then return nil end
		local jhCard = kejieguijiehuoCard:clone()
		for _, card in ipairs(cards) do
			jhCard:addSubcard(card)
		end
		return jhCard
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&kejieguijiehuo") < 4) and (player:getMark("canjiehuo") > 0)
	end
}
kejieguijiehuo = sgs.CreateTriggerSkill {
	name = "kejieguijiehuo",
	view_as_skill = kejieguijiehuoVS,
	on_trigger = function()
	end
}
kejieguisimahui:addSkill(kejieguijiehuo)



kejieguisimahuimarkget = sgs.CreateTriggerSkill {
	name = "#kejieguisimahuimarkget",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local smhs = room:findPlayersBySkillName("kejieguijiehuo")
		for _, smh in sgs.qlist(smhs) do
			if (smh:hasSkill("kejieguijiehuo")) then
				room:setPlayerMark(smh, "canjiehuo", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
kejieguisimahui:addSkill(kejieguisimahuimarkget)

















kejieguishamoke = sgs.General(extension, "kejieguishamoke", "shu", 6)

kejieguishamoke:addSkill("keguiqinwang")










sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["keguibao"] = "鬼包",

	["guichangetupo"] = "将武将更换为界限突破版本",
	--鬼曹操
	["keguicaocao"] = "鬼曹操",
	["&keguicaocao"] = "鬼曹操",
	["#keguicaocao"] = "魏武祖",
	["designer:keguicaocao"] = "杀神附体",
	["cv:keguicaocao"] = "官方",
	["illustrator:keguicaocao"] = "三国无双",

	--多疑
	["keguiduoyi"] = "多疑",
	["guicaocao-ask"] = "请选择发动“多疑”的角色",
	[":keguiduoyi"] = "当你使用普通锦囊牌指定目标后，你可以进行判定，若结果为黑色，你可以令任意名目标角色不能响应此牌。",

	--献计
	["keguixianji"] = "献计",
	["jieguixianji-ask"] = "你可以使用这张“献计”牌",
	["keguixianjiVS"] = "献计",
	["kejieguixianjiVS"] = "献计",
	[":keguixianji"] = "主公技，其他角色的出牌阶段限一次，其可以交给你一张普通锦囊牌。",


	["$keguiduoyi1"] = "宁教我负天下人，休教天下人负我！",
	["$keguiduoyi2"] = "吾好梦中杀人。",

	["~keguicaocao"] = "大爷胃疼，胃疼啊！",

	--鬼张飞
	["keguizhangfei"] = "鬼张飞",
	["&keguizhangfei"] = "鬼张飞",
	["#keguizhangfei"] = "急雪兄仇",
	["designer:keguizhangfei"] = "杀神附体",
	["cv:keguizhangfei"] = "官方",
	["illustrator:keguizhangfei"] = "三国无双",

	["keguilongyin"] = "龙吟",
	[":keguilongyin"] = "锁定技，你使用的黑色【杀】无距离限制。",
	["keguihuxiao"] = "虎啸",
	[":keguihuxiao"] = "锁定技，你使用的红色【杀】目标数上限+1。",

	["$keguilongyin1"] = "（咆哮）",
	["$keguilongyin2"] = "燕人张飞在此！",

	["~keguizhangfei"] = "实在是杀不动了...",

	--鬼关羽
	["keguiguanyu"] = "鬼关羽",
	["&keguiguanyu"] = "鬼关羽",
	["#keguiguanyu"] = "麦城之恨",
	["designer:keguiguanyu"] = "杀神附体",
	["cv:keguiguanyu"] = "官方",
	["illustrator:keguiguanyu"] = "三国无双",

	["keguiwumo"] = "武魔",
	[":keguiwumo"] = "<font color='green'><b>出牌阶段，</b></font>每当你使用或打出【杀】时，你可以摸一张牌。",

	["keguituodao"] = "拖刀",
	[":keguituodao"] = "当你使用【闪】结算完毕后，你可以对攻击范围内的一名角色使用一张【杀】。",
	["tuodao-ask"] = "你可以选择发动“拖刀”的角色",
	["usetuodao"] = "你可以对其使用一张【杀】",

	["$keguiwumo1"] = "呵啊！",
	["$keguiwumo2"] = "呵诶！",
	["$keguituodao1"] = "关羽在此，尔等受死！",
	["$keguituodao2"] = "看尔乃插标卖首。",

	["~keguiguanyu"] = "什么，此地名叫麦城？",

	--鬼吕布
	["keguilvbu"] = "鬼吕布",
	["&keguilvbu"] = "鬼吕布",
	["#keguilvbu"] = "白门厉鬼",
	["designer:keguilvbu"] = "杀神附体",
	["cv:keguilvbu"] = "官方",
	["illustrator:keguilvbu"] = "三国无双",

	["keguisheji"] = "射戟",
	[":keguisheji"] = "锁定技，出牌阶段，当你使用【杀】指定目标后，若你在目标角色的攻击范围内，且目标角色在你的的攻击范围内，其不能响应此牌。",

	["keguijueluone"] = "绝戮",
	[":keguijueluone"] = "锁定技，若你使用的【杀】是你最后的手牌，则此【杀】无距离限制且目标数上限+1。",

	["$keguisheji1"] = "谁能挡我？",
	["$keguisheji2"] = "神挡杀神，佛挡杀佛！",

	["~keguilvbu"] = "不可能！",

	--鬼华雄
	["keguihuaxiong"] = "鬼华雄",
	["&keguihuaxiong"] = "鬼华雄",
	["#keguihuaxiong"] = "温酒之痛",
	["designer:keguihuaxiong"] = "杀神附体",
	["cv:keguihuaxiong"] = "官方",
	["illustrator:keguihuaxiong"] = "三国无双",

	["keguixiaoshou"] = "枭首",
	["keguixiaoshou_equip"] = "请选择一个装备",
	[":keguixiaoshou"] = "<font color='green'><b>每当你受到伤害后，</b></font>你可以获得伤害来源装备区的一张牌，然后你可以将其交给一名角色或置于一名角色对应空置的装备栏。",

	["keguixiaoshou_equip:0"] = "武器牌",
	["keguixiaoshou_equip:1"] = "防具牌",
	["keguixiaoshou_equip:2"] = "防御马",
	["keguixiaoshou_equip:3"] = "进攻马",
	["keguixiaoshou_equip:4"] = "宝物牌",
	["keguixiaoshou:give"] = "交给一名角色",
	["keguixiaoshou:move"] = "置于一名角色的装备区",
	["keguixiaoshou:cancel"] = "取消",
	["xiaoshou-ask"] = "请选择一名角色",

	["$keguixiaoshou1"] = "哼，还未接我三合，谁还来战？",
	["$keguixiaoshou2"] = "雄一人便可挡诸侯百万之众！",
	["$keguixiaoshou3"] = "关外诸侯？哼，不过草芥尔。",
	["$keguixiaoshou4"] = "待我出手，与其项上人头。",


	["~keguihuaxiong"] = "你， 你是何人？",

	--鬼诸葛亮
	["keguizhugeliang"] = "鬼诸葛亮",
	["&keguizhugeliang"] = "鬼诸葛亮",
	["#keguizhugeliang"] = "五丈原忠魂",
	["designer:keguizhugeliang"] = "杀神附体",
	["cv:keguizhugeliang"] = "官方",
	["illustrator:keguizhugeliang"] = "三国无双",

	["keguizhuangshen"] = "妆神",
	[":keguizhuangshen"] = "<font color='green'><b>准备阶段开始时，</b></font>你可以进行判定，若结果为黑色，你可以选择一名其他角色的一个技能，你拥有此技能直到你下回合开始。",


	["keguiqimen"] = "奇门",
	[":keguiqimen"] = "锁定技，你不能成为延时类锦囊牌的目标。",

	["$keguizhuangshen1"] = "观今夜天象，知天下大事。",
	["$keguizhuangshen2"] = "知天易，逆天难。",

	["~keguizhugeliang"] = "将星陨落，天命难违。",

	--鬼曹节
	["keguicaojie"] = "鬼曹节",
	["&keguicaojie"] = "鬼曹节",
	["#keguicaojie"] = "汉献帝后",
	["designer:keguicaojie"] = "杀神附体",
	["cv:keguicaojie"] = "官方",
	["illustrator:keguicaojie"] = "三国无双",

	["keguitiqi"] = "涕泣",
	["guitiqi-ask"] = "涕泣",
	[":keguitiqi"] = "出牌阶段限一次，你可以选择任意数量的其他角色并弃置等量的牌，若如此做，你失去1点体力，然后对这些角色各造成1点伤害。",

	["keguizhixi"] = "掷玺",
	[":keguizhixi"] = "每当你失去【闪】时，你可以摸一张牌。",

	["keguifuwang"] = "父王",
	[":keguifuwang"] = "<font color='pink'><b>公主技，</b></font>若主公为男性角色，你不受其他女性角色技能的影响。\
	【<font color='red'><b>此效果神杀无法实现</b></font>】",

	["$keguitiqi1"] = "天子之位，乃归刘汉！",
	["$keguitiqi2"] = "吾父功盖寰区，然且不敢篡窃神器。",
	["$keguizhixi1"] = "悬壶济世，施医救民 。",
	["$keguizhixi2"] = "心系百姓，惠布山阳。",

	["~keguicaojie"] = "皇天必不祚尔。",


	--司马徽
	["keguisimahui"] = "司马徽",
	["&keguisimahui"] = "司马徽",
	["#keguisimahui"] = "水镜先生",
	["designer:keguisimahui"] = "杀神附体",
	["cv:keguisimahui"] = "官方",
	["illustrator:keguisimahui"] = "三国无双",

	["keguishouye"] = "授业",
	[":keguishouye"] = "出牌阶段限一次，你可以弃置一张牌并令一名角色摸两张牌。",

	["keguijiehuo"] = "解惑",
	[":keguijiehuo"] = "限定技，出牌阶段，你可以弃置四张不同花色的手牌复活一名已阵亡角色，该角色回复3点体力并摸三张牌。",


	--沙摩柯
	["keguishamoke"] = "沙摩柯",
	["&keguishamoke"] = "沙摩柯",
	["#keguishamoke"] = "南蛮大王",
	["designer:keguishamoke"] = "杀神附体",
	["cv:keguishamoke"] = "官方",
	["illustrator:keguishamoke"] = "三国无双",

	["keguiqinwang"] = "勤王",
	[":keguiqinwang"] = "<font color='green'><b>在你的回合外，</b></font>当一名其他角色受到伤害时，你可以将此伤害转移给你。出牌阶段，以你为来源的【杀】和【决斗】造成的伤害+X（X为此前一轮你以此法转移的伤害数）。",

	["$keguiqinwang1"] = "蒺藜骨朵，威震慑敌！",
	["$keguiqinwang2"] = "看我一招，铁蒺藜骨朵！",

	["~keguishamoke"] = "五溪蛮夷，不可能输！！！",

	--界鬼曹操
	["kejieguicaocao"] = "界鬼曹操",
	["&kejieguicaocao"] = "界鬼曹操",
	["#kejieguicaocao"] = "魏武祖",
	["designer:kejieguicaocao"] = "杀神附体",
	["cv:kejieguicaocao"] = "官方",
	["illustrator:kejieguicaocao"] = "三国无双",

	--多疑
	["kejieguiduoyi"] = "多疑",
	["guicaocao-ask"] = "请选择发动“多疑”的角色",
	[":kejieguiduoyi"] = "当你使用【杀】或普通锦囊牌指定目标后，你可以进行判定，若结果为黑色，你可以令任意名目标角色不能响应此牌且在结算完毕前其非锁定技失效；若结果为红色，你摸一张牌。",

	--献计
	["kejieguixianji"] = "献计",

	[":kejieguixianji"] = "主公技，其他角色的出牌阶段限一次，其可以交给你一张普通锦囊牌，然后你可以使用此牌。",

	["$kejieguiduoyi1"] = "宁教我负天下人，休教天下人负我！",
	["$kejieguiduoyi2"] = "吾好梦中杀人。",

	["~kejieguicaocao"] = "大爷胃疼，胃疼啊！",

	--界鬼诸葛亮
	["kejieguizhugeliang"] = "界鬼诸葛亮",
	["&kejieguizhugeliang"] = "界鬼诸葛亮",
	["#kejieguizhugeliang"] = "军师忠魂",
	["designer:kejieguizhugeliang"] = "杀神附体",
	["cv:kejieguizhugeliang"] = "官方",
	["illustrator:kejieguizhugeliang"] = "三国无双",

	["kejieguizhuangshen"] = "妆神",
	["kejieguizhuangshenbuff"] = "妆神",
	[":kejieguizhuangshen"] = "<font color='green'><b>准备阶段或结束阶段开始时，</b></font>你可以摸一张牌并进行判定，若结果为黑色，你可以选择一名其他角色的一个技能，你拥有此技能直到你下回合开始；若结果为红色，你可以对一名角色发动“狂风”或“大雾”。",

	["kejieguiqimen"] = "奇门",
	[":kejieguiqimen"] = "锁定技，你不能成为延时类锦囊牌的目标。",

	["kejieguizhuangshen:guidawu"] = "大雾",
	["kejieguizhuangshen:guikuangfeng"] = "狂风",

	["zhuangshenskill-ask"] = "你可以选择一名其他角色获得其一个技能",
	["zhuangshengod-ask"] = "你可以选择发动“狂风”或“大雾”的角色",

	["gzgldawu"] = "大雾",
	["gzglkuangfeng"] = "狂风",

	["$kejieguizhuangshen1"] = "观今夜天象，知天下大事。",
	["$kejieguizhuangshen2"] = "知天易，逆天难。",

	["~kejieguizhugeliang"] = "将星陨落，天命难违。",

	--界鬼张飞
	["kejieguizhangfei"] = "界鬼张飞",
	["&kejieguizhangfei"] = "界鬼张飞",
	["#kejieguizhangfei"] = "横刀立马",
	["designer:kejieguizhangfei"] = "杀神附体",
	["cv:kejieguizhangfei"] = "官方",
	["illustrator:kejieguizhangfei"] = "三国无双",

	["kejieguilongyin"] = "决桥",
	[":kejieguilongyin"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以废除一个装备栏并选择一名角色，直到你下回合开始时，其余角色与该角色距离+X，且你可以获得所有即将因弃置进入弃牌堆的【杀】。\
	○你使用杀的距离限制+X（X为你以此法废除的装备栏的数量）。",

	["kejieguixiaoyin"] = "啸吟",
	[":kejieguixiaoyin"] = "锁定技，你使用的黑色【杀】不计入次数；你使用的红色【杀】目标数上限+1；当你使用的红色【杀】造成伤害时，此伤害+1且你回复1点体力。",

	["kejieguijueqiaocishu"] = "决桥次数",
	["jueqiaogainslash"] = "决桥：获得弃置的杀",
	["kejieguijueqiao"] = "决桥距离",
	["guijueqiaoplayer-ask"] = "请选择发动“决桥”保护的角色",
	["guijueqiao-ask"] = "请选择废除的装备栏",

	["$kejieguilongyin1"] = "（咆哮）",
	["$kejieguilongyin2"] = "燕人张飞在此！",


	["guijueqiao-ask:0"] = "废除武器栏",
	["guijueqiao-ask:1"] = "废除防具栏",
	["guijueqiao-ask:2"] = "废除防御马栏",
	["guijueqiao-ask:3"] = "废除进攻马栏",
	["guijueqiao-ask:4"] = "废除宝物栏",

	["~kejieguizhangfei"] = "实在是杀不动了...",

	--界鬼关羽
	["kejieguiguanyu"] = "界鬼关羽",
	["&kejieguiguanyu"] = "界鬼关羽",
	["#kejieguiguanyu"] = "麦城之恨",
	["designer:kejieguiguanyu"] = "杀神附体",
	["cv:kejieguiguanyu"] = "官方",
	["illustrator:kejieguiguanyu"] = "三国无双",

	["kejieguiwumo"] = "武魔",
	[":kejieguiwumo"] = "每当你使用或打出【杀】时，你可以摸一张牌，若此【杀】为红色，改为摸两张。",

	["kejieguituodao"] = "拖刀",
	[":kejieguituodao"] = "每当你使用【闪】结算完毕后，你可以选择一项：视为装备“青龙偃月刀”和“赤兔”直到你的回合结束，或视为使用一张【杀】。",

	["jietuodaoslash-ask"] = "你可以选择视为使用【杀】的目标",
	["kejieguituodao:dao"] = "视为装备“青龙偃月刀”和“赤兔”",
	["kejieguituodao:sha"] = "视为使用【杀】",
	["jieguiwumozhuangbei"] = "拖刀装备",

	["$kejieguiwumo1"] = "呵啊！",
	["$kejieguiwumo2"] = "呵诶！",
	["$kejieguituodao1"] = "关羽在此，尔等受死！",
	["$kejieguituodao2"] = "看尔乃插标卖首。",

	["~kejieguiguanyu"] = "什么，此地名叫麦城？",


	--界鬼吕布
	["kejieguilvbu"] = "界鬼吕布",
	["&kejieguilvbu"] = "界鬼吕布",
	["#kejieguilvbu"] = "白门厉鬼",
	["designer:kejieguilvbu"] = "杀神附体",
	["cv:kejieguilvbu"] = "官方",
	["illustrator:kejieguilvbu"] = "三国无双",

	["kejieguisheji"] = "射戟",
	[":kejieguisheji"] = "<font color='green'><b>每回合限一次，</b></font>当你距离1以内的角色成为【杀】的目标后，你可以与使用者拼点：若你赢，此牌对该目标无效，且你摸一张牌；若你没赢，你对使用者造成1点伤害。",

	["kejieguijueluone"] = "绝戮",
	[":kejieguijueluone"] = "锁定技，若你使用的【杀】是你最后的手牌，则此【杀】无距离和目标数限制。",

	["$kejieguisheji1"] = "谁能挡我？",
	["$kejieguisheji2"] = "神挡杀神，佛挡杀佛！",

	["~kejieguilvbu"] = "不可能！",


	--界鬼吕布第二版
	["kejieguilvbutwo"] = "界鬼吕布-第二版",
	["&kejieguilvbutwo"] = "界鬼吕布",
	["#kejieguilvbutwo"] = "白门厉鬼",
	["designer:kejieguilvbutwo"] = "杀神附体",
	["cv:kejieguilvbutwo"] = "官方",
	["illustrator:kejieguilvbutwo"] = "三国无双",

	["kejieguijuelu"] = "绝戮",
	[":kejieguijuelu"] = "锁定技，你使用【杀】的目标数限制+2，当你使用【杀】指定一名角色为目标后，该角色需连续使用X张【闪】才能抵消（X为你的体力值且至少为1）。",


	["~kejieguilvbutwo"] = "不可能！",

	--界鬼华雄
	["kejieguihuaxiong"] = "界鬼华雄",
	["&kejieguihuaxiong"] = "界鬼华雄",
	["#kejieguihuaxiong"] = "先锋战神",
	["designer:kejieguihuaxiong"] = "杀神附体",
	["cv:kejieguihuaxiong"] = "官方",
	["illustrator:kejieguihuaxiong"] = "三国无双",

	["kejieguixiaoshou"] = "枭首",
	[":kejieguixiaoshou"] = "每当你对一名角色造成伤害后，或受到一名角色造成的伤害后，你可以获得其装备区的一张牌并摸一张牌，然后你可以将这张装备牌交给一名角色或置于一名角色对应空置的装备栏。",

	["kejieguixiaoshou_equip:0"] = "武器牌",
	["kejieguixiaoshou_equip:1"] = "防具牌",
	["kejieguixiaoshou_equip:2"] = "防御马",
	["kejieguixiaoshou_equip:3"] = "进攻马",
	["kejieguixiaoshou_equip:4"] = "宝物牌",
	["kejieguixiaoshou:give"] = "交给一名角色",
	["kejieguixiaoshou:move"] = "置于一名角色的装备区",
	["kejieguixiaoshou:cancel"] = "取消",

	["$kejieguixiaoshou1"] = "哼，还未接我三合，谁还来战？",
	["$kejieguixiaoshou2"] = "雄一人便可挡诸侯百万之众！",
	["$kejieguixiaoshou3"] = "关外诸侯？哼，不过草芥尔。",
	["$kejieguixiaoshou4"] = "待我出手，与其项上人头。",


	["~kejieguihuaxiong"] = "你， 你是何人？",

	--界鬼曹节
	["kejieguicaojie"] = "界鬼曹节",
	["&kejieguicaojie"] = "界鬼曹节",
	["#kejieguicaojie"] = "汉献皇后",
	["designer:kejieguicaojie"] = "杀神附体",
	["cv:kejieguicaojie"] = "官方",
	["illustrator:kejieguicaojie"] = "三国无双",

	["kejieguizhixi"] = "掷玺",
	[":kejieguizhixi"] = "每当你失去【闪】时，你可以摸两张牌，若你的体力值不大于1，你回复1点体力。",

	["kejieguifuwang"] = "父王",
	[":kejieguifuwang"] = "<font color='pink'><b>公主技，</b></font>若主公为男性角色，每当你受到女性角色造成的伤害后，你可以摸两张牌。",

	["$kejieguitiqi1"] = "天子之位，乃归刘汉！",
	["$kejieguitiqi2"] = "吾父功盖寰区，然且不敢篡窃神器。",
	["$kejieguizhixi1"] = "悬壶济世，施医救民 。",
	["$kejieguizhixi2"] = "心系百姓，惠布山阳。",

	["~kejieguicaojie"] = "皇天必不祚尔。",


	--界司马徽
	["kejieguisimahui"] = "界司马徽",
	["&kejieguisimahui"] = "界司马徽",
	["#kejieguisimahui"] = "水镜先生",
	["designer:kejieguisimahui"] = "杀神附体",
	["cv:kejieguisimahui"] = "官方",
	["illustrator:kejieguisimahui"] = "官方",

	["kejieguishouye"] = "授业",
	[":kejieguishouye"] = "出牌阶段限一次，你可以弃置一张牌并令一名角色摸三张牌，若这名角色不是你，你摸一张牌。",

	["kejieguijiehuo"] = "解惑",
	[":kejieguijiehuo"] = "<font color='green'><b>每局游戏限四次，</b></font>出牌阶段，你可以弃置三张不同花色的手牌复活一名已阵亡角色，该角色回复2点体力并摸两张牌，然后该角色从技能“火计”、“连环”、“举荐”和“隐世”中随机获得一个，若该角色已拥有该技能，改为摸两张牌。",


	--界沙摩柯
	["kejieguishamoke"] = "界沙摩柯",
	["&kejieguishamoke"] = "界沙摩柯",
	["#kejieguishamoke"] = "五溪蛮王",
	["designer:kejieguishamoke"] = "杀神附体",
	["cv:kejieguishamoke"] = "官方",
	["illustrator:kejieguishamoke"] = "官方",

	["$kejieguiqinwang1"] = "蒺藜骨朵，威震慑敌！",
	["$kejieguiqinwang2"] = "看我一招，铁蒺藜骨朵！",

	["~kejieguishamoke"] = "五溪蛮夷，不可能输！！！",

	--界鬼诸葛亮——第二版
	["kejieguizhugeliangtwo"] = "界鬼诸葛亮-第二版",
	["&kejieguizhugeliangtwo"] = "界鬼诸葛亮",
	["#kejieguizhugeliangtwo"] = "武乡侯",
	["designer:kejieguizhugeliangtwo"] = "杀神附体",
	["cv:kejieguizhugeliangtwo"] = "官方",
	["illustrator:kejieguizhugeliangtwo"] = "三国无双",

	["kejieguiqideng"] = "祈灯",
	[":kejieguiqideng"] = "限定技，当你进入濒死状态时，你可以获得7枚“灯”，若如此做，你始终终止你的濒死结算并存活，每当你受到伤害后或每轮开始时，你弃置1枚“灯”，当你失去所有“灯”后，你死亡。",

	["kejieguizhashi"] = "诈亡",
	["kejieguizhashiex"] = "诈亡",
	[":kejieguizhashi"] = "出牌阶段限一次，你可以选择一名其他角色，该角色须对你使用一张【杀】，否则你对其造成1点雷电伤害，当此【杀】对你造成伤害时，你进行判定，若结果不为♥，视为你因此伤害被该角色<font color='red'><b>杀死过</b></font>，然后你防止此伤害。",

	["kejieguijingmu"] = "惊木",
	["kejieguijingmubuff"] = "惊木",
	[":kejieguijingmu"] = "锁定技，当你被一名其他角色杀死后，该角色的非锁定技无效直到其下一次造成伤害时，且此伤害-1。",

	["@kedeng"] = "灯",
	["keguizhashi-ask"] = "请对其使用一张【杀】",

	["$kejieguiqideng1"] = "请再帮我一次，延续大汉的国运吧！",
	["$kejieguiqideng2"] = "星象凶险，须谨慎再三，方有一线生机。",
	["$kejieguiqideng3"] = "（风吹灯灭）",

	["$kejieguizhashi1"] = "事已至此，只能险中求胜了。",
	["$kejieguizhashi2"] = "心疑，则难进。",

	["$kejieguijingmu1"] = "真是险中用险啊！",
	["$kejieguijingmu2"] = "悠悠苍天，何薄于我？",


}
return { extension }
