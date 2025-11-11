--==《四害改造包》==--
extension = sgs.Package("sihaigaizao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

--曹冲
kecaochong = sgs.General(extension, "kecaochong", "wei", 3, true)

--慧算技能卡
kehuisuanCard = sgs.CreateSkillCard {
	name = "kehuisuanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and
			((to_select:getHp() >= sgs.Self:getHp()) or (to_select:getHandcardNum() >= sgs.Self:getHandcardNum())) and
			(not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local dest = sgs.QVariant()
		dest:setValue(target)
		local guess = room:askForChoice(player, "caochong_guess", "ccbeyond+ccunder", dest)
		local sum = 0
		for _, c in sgs.qlist(target:getCards("h")) do
			sum = sum + c:getNumber()
		end
		if (guess == "ccbeyond") then
			local log = sgs.LogMessage()
			log.type = "$caochongcaida"
			log.from = player
			room:sendLog(log)
			if sum >= 13 then
				room:broadcastSkillInvoke("kehuisuan", 2)
				local log = sgs.LogMessage()
				log.type = "$caochongcaidui"
				log.from = player
				room:sendLog(log)
				local card_id = room:askForCardChosen(player, target, "he", self:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
					room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				--room:drawCards(player, 1, self:objectName())
			end
			if sum < 13 then
				room:broadcastSkillInvoke("kehuisuan", 3)
				local log = sgs.LogMessage()
				log.type = "$caochongcaicuo"
				log.from = player
				room:sendLog(log)
				local damage = sgs.DamageStruct()
				damage.from = target
				damage.to = player
				damage.damage = 1
				room:damage(damage)
			end
		end
		if (guess == "ccunder") then
			local log = sgs.LogMessage()
			log.type = "$caochongcaixiao"
			log.from = player
			room:sendLog(log)
			if sum < 13 then
				room:broadcastSkillInvoke("kehuisuan", 2)
				local log = sgs.LogMessage()
				log.type = "$caochongcaidui"
				log.from = player
				room:sendLog(log)
				local card_id = room:askForCardChosen(player, target, "he", self:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
					room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				--room:drawCards(player, 1, self:objectName())
			end
			if sum >= 13 then
				room:broadcastSkillInvoke("kehuisuan", 3)
				local log = sgs.LogMessage()
				log.type = "$caochongcaicuo"
				log.from = player
				room:sendLog(log)
				local damage = sgs.DamageStruct()
				damage.from = target
				damage.to = player
				damage.damage = 1
				room:damage(damage)
			end
		end
		--end
		--end
	end
}
--慧算主技能
kehuisuan = sgs.CreateViewAsSkill {
	name = "kehuisuan",
	n = 0,
	view_as = function(self, cards)
		return kehuisuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kehuisuanCard"))
	end,
}
kecaochong:addSkill(kehuisuan)

--原版称象
kecaochong:addSkill("chengxiang")

--仁心
kerenxinCard = sgs.CreateSkillCard {
	name = "kerenxinCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if who then
			local hp = 1
			local re = sgs.RecoverStruct()
			re.recover = 1 - who:getHp()
			re.who = source
			room:recover(who, re, true)
			source:turnOver()
			room:drawCards(source, 1, self:objectName())
			room:drawCards(who, 1, self:objectName())
		end
	end
}
kerenxin = sgs.CreateZeroCardViewAsSkill {
	name = "kerenxin",
	view_as = function(self)
		return kerenxinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "peach" and player:faceUp()
	end
}
kecaochong:addSkill(kerenxin)


--王异

kewangyi = sgs.General(extension, "kewangyi", "wei", 4, false)

kezhenlie = sgs.CreateTriggerSkill {
	name = "kezhenlie",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:loseHp(player)
						if player:isAlive() then
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							if player:canDiscard(use.from, "he") then
								local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false,
									sgs.Card_MethodDiscard)
								room:throwCard(id, use.from, player)
							end
						end
					end
				end
			end
		end
		return false
	end
}
kewangyi:addSkill(kezhenlie)

--贞烈响应
kezhenliexiangying = sgs.CreateTriggerSkill {
	name = "#kezhenliexiangying",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.card:isDamageCard() then
			if room:askForSkillInvoke(player, "kezhenliexiangying", data) then
				room:broadcastSkillInvoke("kezhenlie")
				room:loseHp(player)
				--local rs = 0
				local no_respond_list = use.no_respond_list
				for _, szm in sgs.qlist(use.to) do
					table.insert(no_respond_list, szm:objectName())
					--rs = rs + 1
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
				for _, p in sgs.qlist(use.to) do
					if player:canDiscard(p, "he") then
						local id = room:askForCardChosen(player, p, "he", "kezhenlie", false,
							sgs.Card_MethodDiscard)
						room:throwCard(id, p, player)
					end
				end
			end
		end
	end,
}
kewangyi:addSkill(kezhenliexiangying)
extension:insertRelatedSkills("kezhenlie", "#kezhenliexiangying")

--秘计
kemiji = sgs.CreateTriggerSkill {
	name = "kemiji",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:isWounded() then
			if player:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				local num = player:getLostHp()
				player:drawCards(num, self:objectName())
				local players = sgs.SPlayerList()
				local allplayers = room:getOtherPlayers(player)
				for _, p in sgs.qlist(allplayers) do
					players:append(p)
				end
				--是否给人牌
				if room:askForSkillInvoke(player, "kewangyi-geipai", data) then
					local depai = room:askForPlayerChosen(player, players, self:objectName(), "kewangyi-geipai-juese",
						true, true)
					local card = room:askForExchange(player, self:objectName(), 100, 0, true,
						"#kemiji:" .. depai:getGeneralName())
					if card then
						room:obtainCard(depai, card,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(),
								self:objectName(), ""), false)
					end
				end
			end
		end
		return false
	end
}
kewangyi:addSkill(kemiji)


keguojia = sgs.General(extension, "keguojia", "wei", 3, true)

ketianduoo = sgs.CreateTriggerSkill {
	name = "ketianduoo",
	frequency = sgs.Skill_Frequent,
	events = { sgs.FinishJudge, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			local card = judge.card
			local card_data = sgs.QVariant()
			card_data:setValue(card)
			if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and player:askForSkillInvoke(self:objectName(), card_data) then
				player:obtainCard(card)
				room:broadcastSkillInvoke(self:objectName())
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish or (player:getMark("ketianduoo_jh") > 0 and player:getPhase() == sgs.Player_Start) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade|2,3,4,5,6,7,8,9|."
				if player:getMark("ketianduoo_jh") > 0 then
					judge.pattern = ".|spade"
				end
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isBad() then
					local damage = sgs.DamageStruct()
					damage.to = player
					damage.damage = 1
					damage.nature = sgs.DamageStruct_Thunder
					room:damage(damage)
				end
			end
		end
	end
}
keguojia:addSkill(ketianduoo)
keguojia:addSkill("tenyearyiji")

keyijideath = sgs.CreateTriggerSkill {
	name = "keyijideath",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
			local players = room:getOtherPlayers(player)
			if players:isEmpty() then return end
			local target = room:askForPlayerChosen(player, players, "keyijideath", "keyijideath-ask", true, true)
			if target ~= nil then
				room:drawCards(target, 2, self:objectName())
				room:obtainCard(target, player:wholeHandCards(), false)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
keguojia:addSkill(keyijideath)


--十论

keshilunCard = sgs.CreateSkillCard {
	name = "keshilun",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@keshilun")
		room:doSuperLightbox("keguojia", "keshilun")
		--room:handleAcquireDetachSkills(source, "ketianduoo_jh|-ketianduoo")
		room:addPlayerMark(source, "ketianduoo_jh")
		room:changeTranslation(source, "ketianduoo", 1)
		room:drawCards(targets[1], 10, self:objectName())


		--统计一下阵营人数
		local fanzei = 0
		local neijian = 0
		local zhongchen = 0
		local allplayers = room:getAllPlayers()
		for _, p in sgs.qlist(allplayers) do
			if p:getRole() == "loyalist" then
				zhongchen = zhongchen + 1
			end
			if p:getRole() == "renegade" then
				neijian = neijian + 1
			end
			if p:getRole() == "rebel" then
				fanzei = fanzei + 1
			end
		end
		local lost = targets[1]:getLostHp()


		if targets[1]:getRole() == "lord" then
			local zg = 10 - fanzei - neijian - lost
			room:askForDiscard(targets[1], self:objectName(), zg, zg, false, true)
		end
		if targets[1]:getRole() == "loyalist" then
			local zc = 10 - fanzei - neijian - lost
			room:askForDiscard(targets[1], self:objectName(), zc, zc, false, true)
		end
		if targets[1]:getRole() == "renegade" then
			local nj = 10 - fanzei - zhongchen - 1 - lost
			room:askForDiscard(targets[1], self:objectName(), nj, nj, false, true)
		end
		if targets[1]:getRole() == "rebel" then
			local fz = 10 - 1 - neijian - zhongchen - lost
			room:askForDiscard(targets[1], self:objectName(), fz, fz, false, true)
		end
	end
}
keshilunVS = sgs.CreateZeroCardViewAsSkill {
	name = "keshilun",
	view_as = function(self, cards)
		return keshilunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@keshilun") > 0
	end
}
keshilun = sgs.CreatePhaseChangeSkill {
	name = "keshilun",
	frequency = sgs.Skill_Limited,
	view_as_skill = keshilunVS,
	limit_mark = "@keshilun",
	on_phasechange = function()
	end
}

keguojia:addSkill(keshilun)




kesimayi = sgs.General(extension, "kesimayi", "wei", 3, true)


--游戏开始时先获得反馈和鬼才
kesmystart = sgs.CreateTriggerSkill {
	name = "#kesmystart",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:handleAcquireDetachSkills(player, "fankui|guicai")
		if player:getGender() == sgs.General_Male then
			room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			player:loseAllMarks("&nvzhuangbj")
			room:handleAcquireDetachSkills(player, "fankui|guicai")
			room:handleAcquireDetachSkills(player, "-shangshi|-tenyearbiyue")
		elseif player:getGender() == sgs.General_Female then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			player:gainMark("&nvzhuangbj")
			room:handleAcquireDetachSkills(player, "-fankui|-guicai")
			room:handleAcquireDetachSkills(player, "shangshi|tenyearbiyue")
		end
	end,
}
kesimayi:addSkill(kesmystart)

--女装
--player:setGender(sgs.General_Female)
kenvzhuang = sgs.CreateTriggerSkill {
	name = "kenvzhuang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("&kenvzhuang-Clear") == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "&kenvzhuang-Clear")
				if player:getGender() == sgs.General_Female then
					room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					player:setGender(sgs.General_Male)
					player:loseAllMarks("&nvzhuangbj")
					room:handleAcquireDetachSkills(player, "fankui|guicai")
					room:handleAcquireDetachSkills(player, "-shangshi|-tenyearbiyue")
				elseif player:getGender() == sgs.General_Male then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					player:setGender(sgs.General_Female)
					player:gainMark("&nvzhuangbj")
					room:handleAcquireDetachSkills(player, "-fankui|-guicai")
					room:handleAcquireDetachSkills(player, "shangshi|tenyearbiyue")
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						players:append(p)
					end
					local qpr = room:askForPlayerChosen(player, players, self:objectName(), "kewangyi-qipai", true, true)
					if qpr then
						if player:canDiscard(qpr, "he") then
							local id = room:askForCardChosen(player, qpr, "he", self:objectName(), false,
								sgs.Card_MethodDiscard)
							room:throwCard(id, qpr, player)
						end
					end
				end
			end
		end
	end
}
kesimayi:addSkill(kenvzhuang)

--受伤后更换性别
kenvzhuanggh = sgs.CreateTriggerSkill {
	name = "#kenvzhuanggh",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:canDiscard(player, "he") and player:getMark("&kenvzhuang-Clear") == 0 then
			if room:askForSkillInvoke(player, "kenvzhuang", data) then
				room:askForDiscard(player, "kenvzhuang", 1, 1, false, true)
				room:addPlayerMark(player, "&kenvzhuang-Clear")
				if player:getGender() == sgs.General_Female then
					room:broadcastSkillInvoke("kenvzhuang", math.random(3, 4))
					player:setGender(sgs.General_Male)
					player:loseAllMarks("&nvzhuangbj")
					room:handleAcquireDetachSkills(player, "fankui|guicai")
					room:handleAcquireDetachSkills(player, "-shangshi|-tenyearbiyue")
				elseif player:getGender() == sgs.General_Male then
					room:broadcastSkillInvoke("kenvzhuang", math.random(1, 2))
					player:setGender(sgs.General_Female)
					player:gainMark("&nvzhuangbj")
					room:handleAcquireDetachSkills(player, "-fankui|-guicai")
					room:handleAcquireDetachSkills(player, "shangshi|tenyearbiyue")
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						players:append(p)
					end
					local qpr = room:askForPlayerChosen(player, players, "kenvzhuang", "kewangyi-qipai", true, true)
					if qpr then
						if player:canDiscard(qpr, "he") then
							local id = room:askForCardChosen(player, qpr, "he", "kenvzhuang", false,
								sgs.Card_MethodDiscard)
							room:throwCard(id, qpr, player)
						end
					end
				end
			end
		end
	end,
}
kesimayi:addSkill(kenvzhuanggh)
extension:insertRelatedSkills("kenvzhuang", "#kesmystart")
extension:insertRelatedSkills("kenvzhuang", "#kenvzhuanggh")

kesimayi:addRelateSkill("fankui")
kesimayi:addRelateSkill("guicai")
kesimayi:addRelateSkill("nosshangshi")
kesimayi:addRelateSkill("tenyearbiyue")

kezhangchunhua = sgs.General(extension, "kezhangchunhua", "wei", 3, false)

kezhangchunhua:addSkill("tenyearjueqing")
kezhangchunhua:addSkill("shangshi")

--张春华响应
kezhangchunhuaxiangying = sgs.CreateTriggerSkill {
	name = "kezhangchunhuaxiangying",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local ss = player:getLostHp()
		local yy = player:getHandcardNum() + player:getEquips():length()
		if use.card:isKindOf("Slash") and yy >= ss and player:getMark("kezhangchunhuaxiangying-PlayClear") == 0 then --or use.card:isNDTrick()) and use.card:isDamageCard() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, "kezhangchunhuaxiangying-PlayClear")
				if ss ~= 0 then
					if room:askForDiscard(player, self:objectName(), ss, ss, true, true) then
						local no_respond_list = use.no_respond_list
						for _, szm in sgs.qlist(use.to) do
							table.insert(no_respond_list, szm:objectName())
						end
						use.no_respond_list = no_respond_list
						data:setValue(use)
					end
				end
				if ss == 0 then
					local no_respond_list = use.no_respond_list
					for _, szm in sgs.qlist(use.to) do
						table.insert(no_respond_list, szm:objectName())
					end
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		end
	end,
}
kezhangchunhua:addSkill(kezhangchunhuaxiangying)


--孙策
kesunce = sgs.General(extension, "kesunce$", "wu", 4, true)

kejiang = sgs.CreateTriggerSkill {
	name = "kejiang",
	events = { sgs.TargetConfirmed, sgs.TargetSpecified },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
			if use.card:isDamageCard() and player:getMark("&banjiang-Clear") == 0 and not use.card:isKindOf("Lightning") then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					if not ((use.card:isRed()) or (use.card:isKindOf("Duel"))) then
						player:gainMark("&banjiang-Clear")
					end
				end
			end
		end
		return false
	end
}
kesunce:addSkill(kejiang)



kesunce:addSkill("hunzi")
kesunce:addSkill("olzhiba")






sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["sihaigaizao"] = "改造包",



	--曹冲
	["kecaochong"] = "曹冲",
	["&kecaochong"] = "曹冲",
	["#kecaochong"] = "英雄少年",
	["designer:kecaochong"] = "小珂&脑洞大开",
	["cv:kecaochong"] = "官方",
	["illustrator:kecaochong"] = "官方",
	--慧算
	[":kehuisuan"] = "出牌阶段限一次，你可以指定一名有手牌且体力值或手牌数不小于你的其他角色，你猜测其手牌的点数总和是否大于等于13，若猜对，你获得其一张牌；若没猜对，其对你造成一点伤害。",
	["kehuisuan"] = "慧算",
	["kehuisuanCard"] = "慧算",
	--仁心
	[":kerenxin"] = "当一名其他角色进入濒死状态时，<font color='red'><b>若你的武将牌正面向上</b></font>，你可以令其将体力值回复至1点，且你与其各摸一张牌，然后你翻面。",
	["kerenxin"] = "仁心",
	--猜测
	["caochong-invoke"] = "请选择一名角色猜测其手牌点数之和",
	["ccbeyond"] = "大于等于13",
	["ccunder"] = "小于13",
	["$caochongcaixiao"] = "%from“<font color='yellow'><b>猜测对方手牌点数<13</b></font>”。",
	["$caochongcaida"] = "%from“<font color='yellow'><b>猜测对方手牌点数>=13</b></font>”。",
	["$caochongcaidui"] = "%from“<font color='yellow'><b>猜测正确</b></font>”。",
	["$caochongcaicuo"] = "%from“<font color='yellow'><b>猜测错误</b></font>”。",



	["$kehuisuan1"] = "容我来算上一算。",
	["$kehuisuan2"] = "物以载之，校可知矣。",
	["$kehuisuan3"] = "这道题，冲儿解不出来...",
	["$kerenxin1"] = "仁者爱人，人恒爱之。",
	["$kerenxin2"] = "有我在，别怕！",
	["~kecaochong"] = "子桓哥哥！",




	--王异
	["kewangyi"] = "王异",
	["&kewangyi"] = "王异",
	["#kewangyi"] = "决意的巾帼",
	["designer:kewangyi"] = "小珂&脑洞大开",
	["cv:kewangyi"] = "官方",
	["illustrator:kewangyi"] = "官方",

	--贞烈
	[":kezhenlie"] = "当你使用伤害类牌指定目标时/成为一名其他角色使用的【杀】或普通锦囊牌的目标后，你可以失去1点体力，然后可以弃置目标角色/该角色的一张牌，若如此做，你令此牌不能被响应/此牌对你无效。",
	["kezhenlie"] = "贞烈",
	["kezhenliexiangying"] = "贞烈",
	[":kemiji"] = "结束阶段开始时，你可以摸X张牌（X为你已损失的体力值），然后你可以交给一名其他角色任意张牌。",
	["kemiji"] = "秘计",
	["kewangyi-geipai"] = "给牌给其他角色",
	["kewangyi-qipai"] = "选择弃牌的角色",
	["kewangyi-geipai-juese"] = "请选择给牌的角色",
	["kezhenliexiangying"] = "秘计:失去体力令此牌不可被响应",
	["#kemiji"] = "选择给出的牌",


	["$kezhenlie1"] = "持节有度，守节不辱。",
	["$kezhenlie2"] = "宁为玉碎，不能瓦全！",
	["$kemiji1"] = "此等九计，可驱马贼。",
	["$kemiji2"] = "放手一搏，不惧凉州贼寇！",
	["~kewangyi"] = "城池既破，吾当以死殉之。",


	--郭嘉
	["keguojia"] = "郭嘉",
	["&keguojia"] = "郭嘉",
	["#keguojia"] = "风流才子",
	["designer:keguojia"] = "小珂&脑洞大开",
	["cv:keguojia"] = "官方",
	["illustrator:keguojia"] = "官方",

	--天妒
	[":ketianduoo"] = "在你的判定牌生效后，你可以获得此牌。\
				◆<font color='red'><b>结束阶段开始时，你判定，若结果为♠2~9，你受到一点无来源的雷电伤害</b></font>。",
	[":ketianduoo1"] = "在你的判定牌生效后，你可以获得此牌。\
				◆<font color='red'><b>准备阶段或结束阶段开始时，你判定，若结果为♠，你受到一点无来源的雷电伤害</b></font>。",
	[":ketianduoo_jh"] = "在你的判定牌生效后，你可以获得此牌。\
				◆<font color='red'><b>准备阶段或结束阶段开始时，你判定，若结果为♠，你受到一点无来源的雷电伤害</b></font>。",
	["ketianduoo"] = "天妒",
	["ketianduoo_jh"] = "天妒",
	["ketiandu_extra"] = "天妒",
	["ketiandu"] = "天妒",
	["keyijideath"] = "死亡遗计",
	["keyijideath-ask"] = "请选择交付手牌的角色",
	[":keyijideath"] = "◆<font color='red'><b>当你死亡时，你可以将所有手牌交给一名其他角色并令其摸两张牌</b></font>。",

	--十论
	["keshilun"] = "十论",
	["keshilunCard"] = "十论",
	[":keshilun"] = "限定技，出牌阶段，你可以令一名角色摸十张牌，然后其弃置10-X张牌（X为其已损失体力值，与和该角色不同阵营角色数量之和）。\
				然后你修改“天妒”。（判定结果改为♠，且准备阶段开始时也判定）",

	["~keguojia"] = "咳...咳...咳...",


	["$ketianduoo1"] = "天意如此吗...",
	["$ketianduoo2"] = "那，就这样吧。",
	["$keshilun1"] = "就这样吧。",
	["$keshilun2"] = "哦？",

	--司马懿
	["kesimayi"] = "司马懿",
	["&kesimayi"] = "司马懿",
	["#kesimayi"] = "能屈能伸",
	["designer:kesimayi"] = "小珂",
	["cv:kesimayi"] = "官方",
	["illustrator:kesimayi"] = "官方",

	--女装
	[":kenvzhuang"] = "准备阶段，你可以更改你的性别；每回合限一次，当你受到伤害时，你可以弃一张牌更改你的性别。当你改变为女性时，可以弃置一名角色的一张牌。\
				◆若你为男性，你视为拥有“反馈”和“鬼才”；\
				◆若你为女性，你视为拥有“伤逝”和“闭月”；",
	["nvzhuangbj"] = "女装",
	["kenvzhuang"] = "女装",
	["#kenvzhuanggh"] = "女装",


	["$kenvzhuang1"] = "呵呵，啊哈哈...",
	["$kenvzhuang2"] = "呵呵呵...",
	["$kenvzhuang3"] = "吾乃天命之子。",
	["$kenvzhuang4"] = "哈哈哈哈哈！",

	["~kesimayi"] = "我的气数，就到这里了吗？",



	--张春华
	["kezhangchunhua"] = "张春华",
	["&kezhangchunhua"] = "张春华",
	["#kezhangchunhua"] = "冷血皇后",
	["designer:kezhangchunhua"] = "小珂",
	["cv:kezhangchunhua"] = "官方",
	["illustrator:kezhangchunhua"] = "官方",
	["kezhangchunhuaxiangying"] = "狠断",

	--狠断
	[":kezhangchunhuaxiangying"] = "出牌阶段限一次，当你使用【杀】指定目标后，你可以弃置X张牌令此牌不可被响应。（X为你已损失的体力值）",

	["~kezhangchunhua"] = "怎能如此对我。",


	--孙策
	["kesunce"] = "孙策",
	["&kesunce"] = "孙策",
	["#kesunce"] = "江东的小霸王",
	["designer:kesunce"] = "小珂&脑洞大开",
	["cv:kesunce"] = "官方",
	["illustrator:kesunce"] = "官方",

	--激昂
	["kejiang"] = "激昂",
	[":kejiang"] = "当你使用/成为一张非【闪电】的伤害类牌指定目标后/的目标后，你可以摸一张牌，然后若该伤害类牌不为红色或【决斗】，当前回合“激昂”失效。",
	["banjiang"] = "禁激昂",

	["$kejiang1"] = "江东子弟，何惧于天下？！",
	["$kejiang2"] = "吾乃江东小霸王，孙伯符！",


	["~kesunce"] = "内事不决问张昭，外事不决问周瑜。",



}
return { extension }
