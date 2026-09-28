module("extensions.dmpdiva", package.seeall) --游戏包
extension = sgs.Package("dmpdiva") --增加拓展包

--势力

do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "diva")
	config.color_de = "#EEB422"
end

-- pin 首个有效实例，防止同一持有者同名多实例重复发动（s4_yuezhe/s4_zhaowu 惯例）
local function se_diva_first_instance_id(player, skill_name)
	for _, iid in sgs.qlist(player:getValidSkillInstanceIds(skill_name)) do
		return iid
	end
	return nil
end

--逆天
se_nitian = sgs.CreateTriggerSkillV2 {
	name = "se_nitian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.FinishJudge, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			-- 旧行为：judge.who 满血时整段中断，任何持有者都不询问
			if not judge.who or judge.who:getHp() >= judge.who:getMaxHp() then
				return false
			end
			local skills, whos = {}, {}
			for _, honoka in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if honoka:canDiscard(honoka, "h") then
					local iid = se_diva_first_instance_id(honoka, skill:objectName())
					if iid then
						table.insert(skills, skill:objectName() .. "#" .. iid)
						table.insert(whos, honoka:objectName())
					end
				end
			end
			if #skills > 0 then
				return table.concat(skills, "|"), table.concat(whos, "|")
			end
		elseif event == sgs.CardsMoveOneTime then
			-- CardsMoveOneTime 对每名角色逐一 dispatch；仅在持有者本人处触发
			if not player:hasSkill(skill:objectName()) then
				return false
			end
			local move = data:toMoveOneTime()
			if move.to_place ~= sgs.Player_DiscardPile then
				return false
			end
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("DelayedTrick") then
					local iid = se_diva_first_instance_id(player, skill:objectName())
					if iid then
						return skill:objectName() .. "#" .. iid
					end
					return false
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			-- 旧循环在每位持有者提问前重查 judge.who 体力：前一持有者回复至满则后续持有者不再被询问
			if not judge.who or judge.who:getHp() >= judge.who:getMaxHp() then
				return false
			end
			if not player:canDiscard(player, "h") then
				return false
			end
			local prompt = string.format("se_nitian_dis:%s", judge.who:objectName())
			-- AI ai_skill_discard.se_nitian 在询问期间读取此 Tag
			room:setTag("se_nitian_judge", ctx.original_data)
			local discarded = room:askForDiscard(player, skill:objectName(), 1, 1, true, false, prompt)
			room:removeTag("se_nitian_judge")
			return discarded ~= nil
		elseif event == sgs.CardsMoveOneTime then
			-- 旧行为：手牌数不小于上限时先问是否直接摸一张牌；拒绝后仍落入三选一
			if player:getHandcardNum() >= player:getMaxHp()
				and room:askForSkillInvoke(player, skill:objectName()) then
				ctx.choice = "se_nitian_draw"
				return true
			end
			-- AI ai_skill_choice.se_nitian 在询问期间读取此 Tag
			room:setTag("se_nitian_move", ctx.original_data)
			local choice = room:askForChoice(player, skill:objectName(), "se_nitian_gain+se_nitian_draw+cancel")
			room:removeTag("se_nitian_move")
			if choice ~= "se_nitian_gain" and choice ~= "se_nitian_draw" then
				return false
			end
			ctx.choice = choice
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			if judge.reason ~= "se_guwu" then
				room:broadcastSkillInvoke(skill:objectName())
			end
			local re = sgs.RecoverStruct()
			re.who = judge.who
			room:recover(judge.who, re, true)
			local msg = sgs.LogMessage()
			msg.type = "#se_nitian_recovery"
			msg.from = judge.who
			msg.arg = 1
			room:sendLog(msg)
		elseif event == sgs.CardsMoveOneTime then
			if ctx.choice == "se_nitian_draw" then
				player:drawCards(1, skill:objectName())
			elseif ctx.choice == "se_nitian_gain" then
				local move = ctx.original_data:toMoveOneTime()
				local newMove = sgs.CardsMoveStruct()
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("DelayedTrick") then
						newMove.card_ids:append(id)
					end
				end
				if newMove.card_ids:length() > 0 then
					newMove.to = player
					newMove.to_place = sgs.Player_PlaceHand
					newMove.reason = sgs.CardMoveReason(0x27, "", "se_nitian", "")
					room:broadcastSkillInvoke(skill:objectName())
					room:moveCardsAtomic(newMove, true)
				end
			end
		end
		return false
	end,
}

--鼓舞
se_guwu = sgs.CreateTriggerSkillV2 {
	name = "se_guwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.QuitDying },
	can_trigger = function(skill, event, room, player, data)
		local source = data:toDying().who
		if not source or not source:isAlive() then
			return false
		end
		local skills, whos = {}, {}
		for _, mygod in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if mygod:isAlive() then
				local iid = se_diva_first_instance_id(mygod, skill:objectName())
				if iid then
					table.insert(skills, skill:objectName() .. "#" .. iid)
					table.insert(whos, mygod:objectName())
				end
			end
		end
		if #skills > 0 then
			return table.concat(skills, "|"), table.concat(whos, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local source = ctx.original_data:toDying().who
		if not source or not source:isAlive() then
			return false
		end
		-- AI ai_skill_invoke.se_guwu 以 data:toPlayer() 读取脱离濒死者
		local dest = sgs.QVariant()
		dest:setValue(source)
		if room:askForSkillInvoke(player, skill:objectName(), dest) then
			ctx.targets:append(source)
			return true
		end
		return false
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		room:broadcastSkillInvoke(skill:objectName())
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.reason = skill:objectName()
		judge.who = target
		judge.time_consuming = true
		room:judge(judge)
		if judge.card:isRed() then
			room:doLightbox("se_guwu$", 3000)
			local re = sgs.RecoverStruct()
			re.who = target
			room:recover(target, re, true)
		else
			room:doLightbox("se_guwu$", 1200)
			target:drawCards(1)
			player:drawCards(1)
		end
		return false
	end,
}

--抢镜
se_qiangjing = sgs.CreateTriggerSkillV2 {
	name = "se_qiangjing",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		-- CardsMoveOneTime 对每名角色逐一 dispatch；仅在持有者本人处触发
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local move = data:toMoveOneTime()
		if move.from or not move.from_places:contains(sgs.Player_DrawPile) then
			return false
		end
		if room:getTag("FirstRound"):toBool() then
			return false
		end
		if move.to_place ~= sgs.Player_PlaceHand or not move.to then
			return false
		end
		if move.to:objectName() == player:objectName() then
			return false
		end
		if move.to:getPhase() == sgs.Player_Draw then
			return false
		end
		local iid = se_diva_first_instance_id(player, skill:objectName())
		if not iid then
			return false
		end
		return skill:objectName() .. "#" .. iid
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.reason = skill:objectName()
		judge.who = player
		judge.play_animation = false
		judge.time_consuming = true
		room:judge(judge)
		if judge:isGood() then
			room:broadcastSkillInvoke(skill:objectName())
			room:doLightbox("se_qiangjing$", 500)
			local ran = math.random(1, 100)
			local num = 1
			if ran > 70 then
				num = 2
			end
			if ran > 92 then
				num = 4
			end
			if ran > 96 then
				num = 8
			end
			if ran > 99 then
				num = 20
			end
			player:drawCards(num)
		end
		return false
	end,
}

--制服

se_zhifucard = sgs.CreateSkillCard {
	name = "se_zhifucard",
	will_throw = true,
	filter = function(self, selected, to_select, player)
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
		if not choices then
			return
		end
		local dest = sgs.QVariant()
		dest:setValue(targets[1])
		local choice = room:askForChoice(source, self:objectName(), choices, dest)
		if not choice then
			return
		end
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
	end,
}

-- 兼容原型：AI 以 "#se_zhifucard:.:" 字符串发动，需保留 LuaSkillCard 供 Card_Parse 解析；
-- 产卡由 create_card 沿用本卡，filter/on_use 逻辑不变。
se_zhifu = sgs.CreateViewAsSkillV2 {
	name = "se_zhifu",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isKongcheng()
	end,
	can_select_card = function(skill, request, candidate)
		return request:getSelectedCardIds():length() < 1 and not candidate:isEquipped()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then
			return nil
		end
		local card = se_zhifucard:clone()
		card:setSkillName(skill:objectName())
		card:addSubcard(ids:at(0))
		return card
	end,
}

--nico
se_nikecard = sgs.CreateSkillCard {
	name = "se_nikecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < (player:getHandcardNum() + player:getEquips():length()) * 2
	end,
	feasible = function(self, targets, player)
		return true
	end,
	on_use = function(self, room, source, targets)
		-- V2 以技能名 "se_nike" 记录历史；AI 与 can_activate 以 "#se_nikecard" 判断每回合限一次，故手动补记。
		room:addPlayerHistory(source, "#se_nikecard")
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
	end,
}

-- 兼容原型：AI 以 "#se_nikecard:.:" 字符串发动，需保留 LuaSkillCard 供 Card_Parse 解析。
se_nike = sgs.CreateViewAsSkillV2 {
	name = "se_nike",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#se_nikecard")
			and not player:isNude()
	end,
	create_card = function(skill, request)
		local card = se_nikecard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

se_yanyi = sgs.CreateTriggerSkillV2 {
	name = "se_yanyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.PreHpRecover },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.to or damage.to:objectName() ~= player:objectName() then
				return false
			end
		elseif event == sgs.PreHpRecover then
			local re = data:toRecover()
			if not re.who or re.who:objectName() ~= player:objectName() then
				return false
			end
		else
			return false
		end
		local iid = se_diva_first_instance_id(player, skill:objectName())
		if not iid then
			return false
		end
		return skill:objectName() .. "#" .. iid
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			local damage = ctx.original_data:toDamage()
			room:broadcastSkillInvoke("se_yanyi")
			for i = 1, damage.damage do
				local players = room:getAlivePlayers()
				local skill_name = ""
				local sks = {}
				local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
				for i = 1, #all_generals do
					if
						all_generals[i] == "Tukasa"
						or all_generals[i] == "mianma"
						or all_generals[i] == "Sakura"
						or all_generals[i] == "Riko"
						or all_generals[i] == "Nanami"
						or all_generals[i] == "Koishi"
						or all_generals[i] == "Mikoto"
						or all_generals[i] == "Natsume_Rin"
						or all_generals[i] == "Kazehaya"
						or all_generals[i] == "AiAstin"
						or all_generals[i] == "Reimu"
						or all_generals[i] == "Louise"
					then
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
						if table.contains(sks, ske:objectName()) then
							table.removeOne(sks, ske:objectName())
						end
					end
				end

				if #sks == 0 then
					return false
				end
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
		elseif event == sgs.PreHpRecover then
			local re = ctx.original_data:toRecover()
			local choices = {}
			for _, skill in sgs.qlist(re.who:getSkillList()) do
				if skill:isVisible() and skill:objectName() ~= "zhuchangClone" then
					table.insert(choices, skill:objectName())
				end
			end
			local skl = room:askForChoice(re.who, skill:objectName(), table.concat(choices, "+"))
			if not skl then
				skl = skill:objectName()
			end
			room:detachSkillFromPlayer(re.who, skl)
		end
		return false
	end,
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
	[":se_qiangjing"] = '其他角色在摸牌阶段外摸牌时，你可以进行一次判定：若为<font color="red"><b>♥</b></font>，摸1~?（非平均且有大奖）张牌。',

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
	[":se_nike"] = '<font color="green"><b>出牌阶段限一次，</b></font>指定包括你在内的任意名角色各弃置X张牌，并回复一点体力。X为你指定的人数/2（向下取整）。',
	["se_nike$"] = "image=image/animate/se_nike.png",

	["se_yanyi"] = "颜艺 「恶意卖萌」",
	["$se_yanyi1"] = "很出色妮可♪",
	["$se_yanyi2"] = "努力加油♪",
	["$se_yanyi3"] = "主人，你是在叫我吗？",
	["$se_yanyi4"] = "来吧，让全世界都知道妮可的可爱！",
	[":se_yanyi"] = '<font color="blue"><b>锁定技,</b></font>你每受到一点伤害后，需随机获得一个场上不存在的技能。你回复体力时，需选择一个技能失去。',
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
