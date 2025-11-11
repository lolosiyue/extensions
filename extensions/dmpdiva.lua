module("extensions.dmpdiva", package.seeall) --游戏包
extension = sgs.Package("dmpdiva")           --增加拓展包

--势力

do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "diva")
	config.color_de = "#EEB422"
end

--逆天
se_nitian = sgs.CreateTriggerSkill {
	name = "se_nitian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.FinishJudge, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			local room = player:getRoom()
			for _, honoka in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if judge.who:getHp() >= judge.who:getMaxHp() then return end
				if honoka:canDiscard(honoka, "h") then
					local prompt = string.format("se_nitian_dis:%s", judge.who:objectName())
					room:setTag("se_nitian_judge", data)
					if room:askForDiscard(honoka, self:objectName(), 1, 1, true, false, prompt) then
						if judge.reason ~= "se_guwu" then
							room:broadcastSkillInvoke(self:objectName())
						end
						local re = sgs.RecoverStruct()
						re.who = judge.who
						room:recover(judge.who, re, true)
						local msg = sgs.LogMessage()
						msg.type = "#se_nitian_recovery"
						msg.from = judge.who
						msg.arg = 1
						room:sendLog(msg)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local room = player:getRoom()
			local move = data:toMoveOneTime()
			if move.to_place ~= sgs.Player_DiscardPile then return end
			for _, honoka in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:objectName() ~= honoka:objectName() then continue end

				local newMove = sgs.CardsMoveStruct()
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("DelayedTrick") then
						newMove.card_ids:append(id)
					end
				end
				if newMove.card_ids:length() > 0 then
					if honoka:getHandcardNum() >= honoka:getMaxHp() and room:askForSkillInvoke(honoka, self:objectName()) then
						honoka:drawCards(1, self:objectName())
						continue
					end
					room:setTag("se_nitian_move", data)
					local choice = room:askForChoice(honoka, self:objectName(), "se_nitian_gain+se_nitian_draw+cancel")
					if choice == "se_nitian_gain" then
						newMove.to = honoka
						newMove.to_place = sgs.Player_PlaceHand
						newMove.reason = sgs.CardMoveReason(0x27, "", "se_nitian", "")
						room:broadcastSkillInvoke(self:objectName())
						room:moveCardsAtomic(newMove, true)
					elseif choice == "se_nitian_draw" then
						honoka:drawCards(1, self:objectName())
					end
					room:removeTag("se_nitian_move")
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

--鼓舞
se_guwu = sgs.CreateTriggerSkill {
	name = "se_guwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.QuitDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		for _, mygod in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if mygod:isAlive() and source:isAlive() then
				local dest = sgs.QVariant()
				dest:setValue(source)
				if room:askForSkillInvoke(mygod, "se_guwu", dest) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.reason = self:objectName()
					judge.who = source
					judge.time_consuming = true
					room:judge(judge)
					if judge.card:isRed() then
						room:doLightbox("se_guwu$", 3000)
						local re = sgs.RecoverStruct()
						re.who = judge.who
						room:recover(judge.who, re, true)
					else
						room:doLightbox("se_guwu$", 1200)
						judge.who:drawCards(1)
						mygod:drawCards(1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

--抢镜
se_qiangjing = sgs.CreateTriggerSkill {
	name = "se_qiangjing",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not move.from_places:contains(sgs.Player_DrawPile) or move.from then return end
		if room:getTag("FirstRound"):toBool() then return false end
		for _, kotori in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if move.to_place == sgs.Player_PlaceHand and move.to:objectName() ~= kotori:objectName() and move.to:getPhase() ~= sgs.Player_Draw then
				if not kotori:askForSkillInvoke(self:objectName(), data) then continue end
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.reason = self:objectName()
				judge.who = kotori
				judge.play_animation = false
				judge.time_consuming = true
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke(self:objectName())
					room:doLightbox("se_qiangjing$", 500)
					local ran = math.random(1, 100)
					local num = 1
					if ran > 70 then num = 2 end
					if ran > 92 then num = 4 end
					if ran > 96 then num = 8 end
					if ran > 99 then num = 20 end
					kotori:drawCards(num)
				end
			end
		end
		return false
	end
}

--制服


se_zhifucard = sgs.CreateSkillCard {
	name = "se_zhifucard",
	will_throw = true,
	filter = function(self, selected, to_select)
		return #selected < 1
	end,
	on_use = function(self, room, source, targets)
		local choices
		local choicesDone = {}
		for _, id in sgs.qlist(room:getDrawPile()) do
			if not choices and sgs.Sanguosha:getCard(id):isKindOf("Armor") then
				choices = sgs.Sanguosha:getCard(id):objectName()
				table.insert(choicesDone, sgs.Sanguosha:getCard(id):objectName())
			else
				if not table.contains(choicesDone, sgs.Sanguosha:getCard(id):objectName()) and sgs.Sanguosha:getCard(id):isKindOf("Armor") then
					choices = string.format(choices .. "+" .. sgs.Sanguosha:getCard(id):objectName())
					table.insert(choicesDone, sgs.Sanguosha:getCard(id):objectName())
				end
			end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if not choices and sgs.Sanguosha:getCard(id):isKindOf("Armor") then
				choices = sgs.Sanguosha:getCard(id):objectName()
				table.insert(choicesDone, sgs.Sanguosha:getCard(id):objectName())
			else
				if not table.contains(choicesDone, sgs.Sanguosha:getCard(id):objectName()) and sgs.Sanguosha:getCard(id):isKindOf("Armor") then
					choices = string.format(choices .. "+" .. sgs.Sanguosha:getCard(id):objectName())
					table.insert(choicesDone, sgs.Sanguosha:getCard(id):objectName())
				end
			end
		end
		if not choices then return end
		local dest = sgs.QVariant()
		dest:setValue(targets[1])
		local choice = room:askForChoice(source, self:objectName(), choices, dest)
		if not choice then return end
		room:broadcastSkillInvoke("se_zhifu")
		local target = targets[1]

		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):objectName() == choice then
				local newuse = sgs.CardUseStruct()
				newuse.from = target
				newuse.to:append(target)
				newuse.card = sgs.Sanguosha:getCard(id)
				room:useCard(newuse)
				return
			end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):objectName() == choice then
				local newuse = sgs.CardUseStruct()
				newuse.from = target
				newuse.to:append(target)
				newuse.card = sgs.Sanguosha:getCard(id)
				room:useCard(newuse)
				return
			end
		end

		local msg = sgs.LogMessage()
		msg.type = "#se_zhifu_use"
		msg.from = target
		msg.arg = choice
		room:sendLog(msg)
	end
}

se_zhifu = sgs.CreateViewAsSkill {
	name = "se_zhifu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = se_zhifucard:clone()
			card:setSkillName(self:objectName())
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}


--nico
se_nikecard = sgs.CreateSkillCard {
	name = "se_nikecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and
			#targets < (sgs.Self:getHandcardNum() + sgs.Self:getEquips():length()) * 2
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		table.insert(targets, source)
		local num = math.floor(#targets / 2)
		--room:broadcastSkillInvoke("se_nike")
		room:doLightbox("se_nike$", 800)
		for _, p in ipairs(targets) do
			room:askForDiscard(p, self:objectName(), num, num, false, true)
			local re = sgs.RecoverStruct()
			re.who = p
			room:recover(p, re, true)
		end
	end
}

se_nike = sgs.CreateViewAsSkill {
	name = "se_nike",
	n = 0,
	view_as = function(self, cards)
		local card = se_nikecard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#se_nikecard") and not player:isNude()
	end,
}


se_yanyi = sgs.CreateTriggerSkill {
	name = "se_yanyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke("se_yanyi")
				for i = 1, damage.damage do
					local players = room:getAlivePlayers()
					local skill_name = ""
					local sks = {}
					local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
					for i = 1, #all_generals do
						if all_generals[i] == "Tukasa" or all_generals[i] == "mianma" or all_generals[i] == "Sakura" or all_generals[i] == "Riko" or all_generals[i] == "Nanami" or all_generals[i] == "Koishi" or all_generals[i] == "Mikoto" or all_generals[i] == "Natsume_Rin" or all_generals[i] == "Kazehaya" or all_generals[i] == "AiAstin" or all_generals[i] == "Reimu" or all_generals[i] == "Louise" then
							table.remove(all_generals, i)
							i = i - 1
						end
					end

					for _, general_name in ipairs(all_generals) do
						local general = sgs.Sanguosha:getGeneral(general_name)
						for _, sk in sgs.qlist(general:getVisibleSkillList()) do
							if not sk:isLordSkill() then
								if sk:getFrequency() ~= sgs.Skill_Wake and sk:getFrequency() ~= sgs.Skill_Limited then
									table.insert(sks, sk:objectName())
								end
							end
						end
					end

					for _, pl in sgs.qlist(players) do
						for _, ske in sgs.qlist(pl:getVisibleSkillList()) do
							if table.contains(sks, ske:objectName()) then table.removeOne(sks, ske:objectName()) end
						end
					end

					if #sks == 0 then return end
					local ran = math.random(1, #sks)
					skill_name = sks[ran]
					room:handleAcquireDetachSkills(damage.to, skill_name)
					local randomYanyi = math.random(1, 10)
					room:doLightbox("se_yanyi" .. randomYanyi .. "$", 800)
					room:doLightbox(skill_name, 600)
					local msg = sgs.LogMessage()
					msg.type = "#se_yanyi_use"
					msg.arg = skill_name
					room:sendLog(msg)
				end
			end
			return false
		elseif event == sgs.PreHpRecover then
			local re = data:toRecover()
			if re.who:hasSkill(self:objectName()) then
				choices = {}
				for _, skill in sgs.qlist(re.who:getSkillList()) do
					if skill:isVisible() and skill:objectName() ~= "zhuchangClone" then
						table.insert(choices, skill:objectName())
					end
				end
				local skl = room:askForChoice(re.who, self:objectName(), table.concat(choices, "+"))
				if not skl then skl = self:objectName() end
				room:detachSkillFromPlayer(re.who, skl)
			end
		end
	end
}



Honoka = sgs.General(extension, "Honoka", "diva", 3, false, false, false)
MKotori = sgs.General(extension, "MKotori", "diva", 3, false, false, false)
Nico = sgs.General(extension, "Nico", "diva", 3, false, false, false)


Honoka:addSkill(se_nitian)
Honoka:addSkill(se_guwu)
MKotori:addSkill(se_qiangjing)
MKotori:addSkill(se_zhifu)
Nico:addSkill(se_nike)
Nico:addSkill(se_yanyi)

sgs.LoadTranslationTable {
	["diva"] = "LL大法",
	["dmpdiva"] = "动漫包-LL大法",

	["se_nitian"] = "逆天「果皇之力」",
	["se_nitian_gain"] = "获得进入弃牌堆的延时锦囊",
	["se_nitian_draw"] = "摸一张牌",
	["$se_nitian1"] = "穗乃果运气也是相当不错的哟？…但是，也许不如小希。",
	["$se_nitian2"] = "为了达成目标，只有向前！",
	["$se_nitian3"] = "穗乃果的微笑，有没有能传递给大家呢？",
	["$se_nitian4"] = "辛苦啦！今天也努力了！！",
	[":se_nitian"] = "一名角色判定结束时，你可以弃置一张手牌，令其回复一点体力。延时锦囊进入弃牌堆时，若你的手牌数小于你的体力上限，你可以获得之，否则你摸一张牌。",
	["se_nitian_dis"] = "你可以弃置一张手牌，令 %src 回复一点体力。",

	["se_guwu"] = "鼓舞「Fightだよ」",
	["$se_guwu1"] = "好的，就和穗乃果一起来唱歌吧！",
	["$se_guwu2"] = "嘿，打起精神来挑战一下吧！",
	["$se_guwu3"] = "哦？好像还可以继续进行练习！那只好继续加油了！",
	["$se_guwu4"] = "穂乃果来支援你了~",
	["se_guwu$"] = "image=image/animate/se_guwu.png",
	[":se_guwu"] = "每当一名角色离开濒死阶段时，你可以令其进行一次判定。若为红色，其回复一点体力，否则你和其各摸一张牌。",


	["se_qiangjing"] = "抢镜「抢镜头的大头小鸟」",
	["$se_qiangjing1"] = "哇，吓我一跳…",
	["$se_qiangjing2"] = "耶耶哦",
	["se_qiangjing$"] = "image=image/animate/se_qiangjing.png",
	[":se_qiangjing"] = "其他角色在摸牌阶段外摸牌时，你可以进行一次判定：若为<font color=\"red\"><b>♥</b></font>，摸1~?（非平均且有大奖）张牌。",

	["se_zhifu"] = "制服 「服装制作」",
	["$se_zhifu1"] = "其实我的手还是非常巧的，所以也在做μ'ｓ的服装。",
	["$se_zhifu2"] = "后勤工作就交给小鸟吧。",
	["$se_zhifu3"] = "可以看到充满活力的你就觉得很开心。",
	["$se_zhifu4"] = "想用小鸟的歌声来抚慰大家的心♪",
	[":se_zhifu"] = "出牌阶段，你可以弃置一张手牌，然后从牌堆或弃牌堆中获得一张指定的防具，并令一名角色装备。",
	["se_zhifucard"] = "制服 「服装制作」",

	["se_nike"] = "妮可 「大家的妮可」",
	["$se_nike1"] = "niconiconi~",
	["$se_nike2"] = "大家的偶像妮可来了哦～妮可妮可妮~",
	["$se_nike3"] = "好了，粉丝都在等着妮可♪",
	[":se_nike"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>指定包括你在内的任意名角色各弃置X张牌，并回复一点体力。X为你指定的人数/2（向下取整）。",
	["se_nike$"] = "image=image/animate/se_nike.png",

	["se_yanyi"] = "颜艺 「恶意卖萌」",
	["$se_yanyi1"] = "很出色妮可♪",
	["$se_yanyi2"] = "努力加油♪",
	["$se_yanyi3"] = "主人，你是在叫我吗？",
	["$se_yanyi4"] = "来吧，让全世界都知道妮可的可爱！",
	[":se_yanyi"] = "<font color=\"blue\"><b>锁定技,</b></font>你每受到一点伤害后，需随机获得一个场上不存在的技能。你回复体力时，需选择一个技能失去。",
	["se_yanyi1$"] = "image=image/animate/se_yanyi1.png",
	["se_yanyi2$"] = "image=image/animate/se_yanyi2.png",
	["se_yanyi3$"] = "image=image/animate/se_yanyi3.png",
	["se_yanyi4$"] = "image=image/animate/se_yanyi4.png",
	["se_yanyi5$"] = "image=image/animate/se_yanyi5.png",
	["se_yanyi6$"] = "image=image/animate/se_yanyi6.png",
	["se_yanyi7$"] = "image=image/animate/se_yanyi7.png",
	["se_yanyi8$"] = "image=image/animate/se_yanyi8.png",
	["se_yanyi9$"] = "image=image/animate/se_yanyi9.png",
	["se_yanyi10$"] = "image=image/animate/se_yanyi10.png",

	["#se_nitian_recovery"] = "果果令判定结束的 %from 回复了 %arg 点体力。",
	["#se_zhifu_use"] = "小鸟给 %from 穿上了 %arg 。",
	["#se_yanyi_use"] = "妮可获得了技能 %arg 。",

	["Honoka"] = "高坂穗乃果",
	["&Honoka"] = "高坂穗乃果",
	["#Honoka"] = "果皇",
	["~Honoka"] = "不甘心！但是，不会放弃的！",
	["designer:Honoka"] = "Sword Elucidator",
	["cv:Honoka"] = "新田惠海",
	["illustrator:Honoka"] = "伍長",

	["MKotori"] = "南小鸟ことり",
	["&MKotori"] = "南小鸟",
	["#MKotori"] = "小鸟神教主",
	["~MKotori"] = "才刚开始！",
	["designer:MKotori"] = "Sword Elucidator",
	["cv:MKotori"] = "内田彩",
	["illustrator:MKotori"] = "りも",

	["Nico"] = "矢澤妮可にこ",
	["&Nico"] = "矢澤妮可",
	["#Nico"] = "妮可妮可妮",
	["~Nico"] = "......真不甘心",
	["designer:Nico"] = "Sword Elucidator",
	["cv:Nico"] = "德井青空",
	["illustrator:Nico"] = "ゆらん@C88三日目東ノ04a",
}
