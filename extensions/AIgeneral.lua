extension = sgs.Package("AIgeneral")

sgs.LoadTranslationTable {
	["AIgeneral"] = "人工智能",
}

-- 深度求索
deepseek = sgs.General(extension, "deepseek", "wei", 3, false)

deep_seek = sgs.CreateTriggerSkillV2 {
	name = "deep_seek",
	events = { sgs.DamageCaused },

	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local damage = data:toDamage()
		-- 检查是否已经对该角色使用过技能
		if damage.to:getMark("shensikao_used_" .. player:objectName()) > 0 then
			return false
		end
		return skill:objectName()
	end,

	on_cost = function(skill, event, room, player, ctx)
		-- 提示玩家选择是否发动技能
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,

	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local target = damage.to

		-- 推测身份
		local choices = {}
		local roles = { "loyalist", "rebel", "renegade", "lord" }
		for _, role in ipairs(roles) do
			table.insert(choices, role)
		end

		local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), ToData(target))

		-- 判断推测是否正确
		if choice == target:getRole() then
			-- 推测正确，摸X张牌（X为场上角色数）
			local x = room:getAlivePlayers():length()
			player:drawCards(x, skill:objectName())
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
			room:broadcastSkillInvoke(skill:objectName(), 1) -- 播放成功音效
		else
			-- 推测错误，无效果
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
			room:broadcastSkillInvoke(skill:objectName(), 2) -- 播放失败音效
		end
		room:setPlayerMark(target, "shensikao_used_" .. player:objectName(), 1)
		local splayer = sgs.SPlayerList()
		splayer:append(player)
		room:addPlayerMark(target, "&deep_seek+to+#" .. player:objectName(), 1, splayer)

		return false
	end,
}
deepseek:addSkill(deep_seek)
-- 技能：服务繁忙
fuwufanmang = sgs.CreateTriggerSkillV2 {
	name = "fuwufanmang",
	events = { sgs.CardUsed, sgs.TargetConfirming },
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") then
			return false
		end
		if use.card:hasFlag(skill:objectName()) then
			return false
		end
		if event == sgs.CardUsed then
			return player == use.from and skill:objectName() or false
		end
		-- sgs.TargetConfirming
		return use.to:contains(player) and skill:objectName() or false
	end,

	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		-- 计算概率（10X%，X为场上其他角色数）
		local x = room:getAlivePlayers():length() - 1 -- 排除自己
		local probability = x * 10
		if probability > 100 then
			probability = 100 -- 概率上限为100%
		end
		-- 随机决定是否触发效果
		if math.random(1, 100) > probability then
			return false
		end
		room:setCardFlag(use.card, skill:objectName())

		-- 提示玩家技能触发
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
		room:broadcastSkillInvoke(skill:objectName())

		-- 判定效果：红色无效并收回，黑色无法响应
		-- 创建判定结构
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|black"
		judge.good = false
		judge.negative = true
		judge.reason = skill:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
			-- 黑色判定：牌无法被响应
			local no_respond_list = use.no_respond_list
			table.insert(no_respond_list, "_ALL_TARGETS")
			use.no_respond_list = no_respond_list
			ctx.original_data:setValue(use)
		else
			-- 红色判定：牌无效并收回
			local ids = sgs.IntList()
			if use.card:isVirtualCard() then
				ids = use.card:getSubcards()
			else
				ids:append(use.card:getEffectiveId())
			end
			if ids:isEmpty() then
				return false
			end
			for _, id in sgs.qlist(ids) do
				if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
					return false
				end
			end
			use.to:removeOne(player)
			room:sortByActionOrder(use.to)
			ctx.original_data:setValue(use)
			-- 2. 使用者获得牌
			use.from:obtainCard(use.card)

			-- 3. 显示技能特效
			room:broadcastSkillInvoke(skill:objectName())
		end
		return false
	end,
}

deepseek:addSkill(fuwufanmang)
KaiyuanShengshi = sgs.CreateTriggerSkillV2 {
	name = "KaiyuanShengshi",
	events = { sgs.Dying },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local dying = data:toDying()
		return dying.who:getHp() < 1 and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		local _player = dying.who
		if _player:getHp() < 1 then
			room:setPlayerFlag(player, "KaiyuanShengshi")
			local card = room:askForSinglePeach(player, _player)
			room:setPlayerFlag(player, "-KaiyuanShengshi")
			if card then
				room:useCard(sgs.CardUseStruct(card, player, _player))
				room:sendCompulsoryTriggerLog(player, "KaiyuanShengshi", true)
				room:broadcastSkillInvoke(skill:objectName())
				local current_general = player:getGeneralName()
				local current_role = player:getRole()
				local target = _player
				local target_role = _player:getRole()
				-- 修改阵营（主公特殊处理）
				if target:getGeneralName() ~= current_general then
					room:changeHero(target, current_general, false, true, false, true)
					room:detachSkillFromPlayer(target, "KaiyuanShengshi_win_trigger")
					room:detachSkillFromPlayer(target, "MaoniangGangyinRW12")
					room:detachSkillFromPlayer(target, "MaoniangGangyinRW34")
					room:detachSkillFromPlayer(target, "MaoniangGangyinRW56")
					room:detachSkillFromPlayer(target, "MaoniangGangyinRW7")
				end
				if target_role == "lord" then
					-- 主公：其他相同武将变为忠臣
					if target ~= player then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == current_general or p:getRole() == current_role then
								room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
							end
						end
						room:setPlayerProperty(target, "role", sgs.QVariant("lord"))
					end
				else
					if current_role == "lord" and target_role ~= "lord" then
						-- 主公：同步阵营
						room:setPlayerProperty(target, "role", sgs.QVariant("loyalist"))
					else
						-- 非主公：直接同步阵营
						room:setPlayerProperty(target, "role", sgs.QVariant(current_role))
					end
				end
				-- 2. 场上所有相同武将摸一张牌
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getGeneralName() == current_general then
						p:drawCards(1, skill:objectName())
					end
				end

				room:updateStateItem()
				room:recover(_player, sgs.RecoverStruct(skill:objectName(), player, 1 - _player:getHp()))
			end
		end
		return false
	end,
}
KaiyuanShengshi_win_trigger = sgs.CreateTriggerSkillV2 {
	name = "#KaiyuanShengshi_win_trigger",
	events = { sgs.TurnStart },
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local TurnCount = player:getMark("Global_TurnCount")
		local players = room:getAlivePlayers()
		--正常结局：主公结束，主忠胜利
		if TurnCount > 0 and (player:getRole() == "lord" or player:getRole() == "loyalist") then
			local canWin = true
			for _, p in sgs.qlist(players) do
				if p:getRole() == "rebel" or p:getRole() == "renegade" then
					--room:writeToConsole("因为"..p:getGeneralName().."不行")
					canWin = false
				end
			end
			if canWin == true then
				room:gameOver("lord+loyalist")
			end
		end
		--只剩一个，默认你赢
		if room:alivePlayerCount() == 1 then
			--	room:writeToConsole("1ren")
			room:gameOver(player:objectName())
		end
	end,
}
deepseek:addSkill(KaiyuanShengshi)
deepseek:addSkill(KaiyuanShengshi_win_trigger)
extension:insertRelatedSkills("KaiyuanShengshi", "#KaiyuanShengshi_win_trigger")
MaoniangGangyin = sgs.CreateTriggerSkillV2 {
	name = "MaoniangGangyin",
	waked_skills = "tieba_zhili",
	events = { sgs.GameStart, sgs.TurnStart },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		-- V2 需要持有者擁有有效的技能實例；legacy 允許僅持有標記的角色觸發，V2 無法表達
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.GameStart then
			room:setPlayerMark(player, "MaoniangGangyin", 1)
		else
			if player:getGeneralName() ~= "deepseek" and player:getGeneral2Name() ~= "deepseek" then
				room:changeHero(player, "deepseek", true, true)
			end
			local RW
			if player:getMark("MNRenWu8") > 0 then
				RW = math.random(1, 7)
			else
				RW = math.random(1, 8)
			end

			room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu" .. RW, 1)
			local log = sgs.LogMessage()
			log.type = "#MaoniangGangyinGY"
			room:sendLog(log)
			room:broadcastSkillInvoke("MaoniangGangyin")
		end
		return false
	end,
}

MaoniangGangyinRW12 = sgs.CreateTriggerSkillV2 {
	name = "#MaoniangGangyinRW12",
	events = { sgs.Damage },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill("MaoniangGangyin")
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu1") == 1 then --已验证
			player:drawCards(1, skill:objectName())
			room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu1", 0)
			room:broadcastSkillInvoke(skill:objectName())
		end
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu2") == 1 then --已验证
			local damage = ctx.original_data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				player:drawCards(2, skill:objectName())
				room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu2", 0)
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		return false
	end,
}
MaoniangGangyinRW34 = sgs.CreateTriggerSkillV2 {
	name = "#MaoniangGangyinRW34",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill("MaoniangGangyin")
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu3") == 1 then
			for _, id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
					room:addPlayerMark(player, "MNRenWu3")
				end
			end
			if player:getMark("MNRenWu3") >= 3 then
				room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu3", 0)
				room:setPlayerMark(player, "MNRenWu3", 0)
				player:drawCards(2, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu4") == 1 and move.from and player:objectName() == move.from:objectName() then
			for _, id in sgs.qlist(move.card_ids) do
				if room:getCardPlace(id) == sgs.Player_DiscardPile then
					room:addPlayerMark(player, "MNRenWu4")
				end
			end
			if player:getMark("MNRenWu4") >= 4 then
				room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu4", 0)
				room:setPlayerMark(player, "MNRenWu4", 0)
				player:drawCards(2, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		return false
	end,
}
MaoniangGangyinRW56 = sgs.CreateTriggerSkillV2 {
	name = "#MaoniangGangyinRW56",
	events = { sgs.CardUsed },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill("MaoniangGangyin")
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local card = use.card
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu5") == 1 and card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
			room:addPlayerMark(player, "MNRenWu5")
			if player:getMark("MNRenWu5") >= 2 then
				player:drawCards(2, skill:objectName())
				room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu5", 0)
				room:setPlayerMark(player, "MNRenWu5", 0)
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu6") == 1 and card:isKindOf("TrickCard") and use.from:objectName() == player:objectName() then
			room:addPlayerMark(player, "MNRenWu6")
			if player:getMark("MNRenWu6") >= 2 then
				player:drawCards(2, skill:objectName())
				room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu6", 0)
				room:setPlayerMark(player, "MNRenWu6", 0)
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		return false
	end,
}
MaoniangGangyinRW7 = sgs.CreateTriggerSkillV2 {
	name = "#MaoniangGangyinRW7",
	events = { sgs.HpRecover },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill("MaoniangGangyin")
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getMark("&MaoniangGangyin_mission+:+MNRenWu7") == 1 then
			player:drawCards(2, skill:objectName())
			room:setPlayerMark(player, "&MaoniangGangyin_mission+:+MNRenWu7", 0)
			room:broadcastSkillInvoke(skill:objectName())
		end
		return false
	end,
}
MaoniangGangyinRW8 = sgs.CreateTriggerSkillV2 {
	name = "#MaoniangGangyinRW8",
	events = { sgs.MarkChanged },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local mark = ctx.original_data:toMark()
		if string.startsWith(mark.name, "&MaoniangGangyin_mission+:+MNRenWu") and mark.gain < 0 then
			local log = sgs.LogMessage()
			log.type = "#MaoniangGangyinRW"
			log.arg = mark.name:split("+")[3]
			room:sendLog(log)
			if player:getMark("MNRenWu8") == 0 and player:getMark("&MaoniangGangyin_mission+:+MNRenWu8") > 0 then
				room:addPlayerMark(player, "MNRenWu88")
			end
		end
		if mark.name == "MNRenWu88" and mark.gain > 0 then
			if player:getMark("MNRenWu88") >= 3 then
				room:addPlayerMark(player, "MNRenWu8")
				room:acquireSkill(player, "tieba_zhili")
				player:drawCards(1, skill:objectName())
			end
		end
		return false
	end,
}
deepseek:addSkill(MaoniangGangyinRW8)

-- 贴吧之力
tieba_zhiliVS = sgs.CreateViewAsSkillV2 {
	name = "tieba_zhili",
	n = 0,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:hasSkill("tieba_zhili") or false
	end,

	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,

	create_card = function(skill, request)
		local card = tieba_zhiliCard:clone()
		return card
	end,
}

-- 技能卡牌（选择目标）
tieba_zhiliCard = sgs.CreateSkillCard {
	name = "tieba_zhiliCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:detachSkillFromPlayer(source, "tieba_zhili")
		-- 记录目标当前体力值
		room:setPlayerMark(target, "tieba_original_hp", target:getHp())
		-- 标记"破防"状态
		room:setPlayerMark(target, "tieba_pofang", 1)
		-- 失去所有体力（进入濒死）
		room:loseHp(target, target:getHp(), true, source, "tieba_zhili")

		-- 日志和动画
		room:broadcastSkillInvoke("tieba_zhili")
		room:sendCompulsoryTriggerLog(source, "tieba_zhili", true)
		return false
	end,
}
-- DEFER:tieba_zhili:trigger stays legacy — the card detaches the skill on use, so at
-- AskForPeachesDone no player holds a live "tieba_zhili" instance; legacy can_trigger
-- returns true for the dying actor regardless of ownership, while V2 requires the owner
-- to hold a valid instance. Its view_as_skill is migrated to V2 (play-only).
tieba_zhili = sgs.CreateTriggerSkill {
	name = "tieba_zhili",
	events = { sgs.AskForPeachesDone }, -- 濒死求桃时触发
	view_as_skill = tieba_zhiliVS,
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		if dying.who:getMark("tieba_pofang") == 1 then
			local room = player:getRoom()
			room:setPlayerMark(dying.who, "tieba_pofang", 0) -- 清除标记
			local original_hp = dying.who:getMark("tieba_original_hp") -- 获取记录的初始体力
			-- 强制回复至1体力
			room:recover(dying.who, sgs.RecoverStruct(dying.who, nil, original_hp))
			room:setPlayerMark(dying.who, "tieba_original_hp", 0) -- 清除记录的初始体力
			room:sendCompulsoryTriggerLog(player, "tieba_zhili", true) -- 发送日志
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

deepseek:addSkill(MaoniangGangyin)
deepseek:addSkill(MaoniangGangyinRW12)
deepseek:addSkill(MaoniangGangyinRW34)
deepseek:addSkill(MaoniangGangyinRW56)
deepseek:addSkill(MaoniangGangyinRW7)
extension:insertRelatedSkills("MaoniangGangyin", "#MaoniangGangyinRW12")
extension:insertRelatedSkills("MaoniangGangyin", "#MaoniangGangyinRW34")
extension:insertRelatedSkills("MaoniangGangyin", "#MaoniangGangyinRW56")
extension:insertRelatedSkills("MaoniangGangyin", "#MaoniangGangyinRW7")
extension:insertRelatedSkills("MaoniangGangyin", "#MaoniangGangyinRW8")

sgs.LoadTranslationTable {
	["deepseek"] = "深度求索",
	["#deepseek"] = "deepseek",
	["illustrator:deepseek"] = "途淄fficial",
	["deep_seek"] = "深度思考",
	[":deep_seek"] = "<font color=\"green\"><b>每名角色限一次，</b></font>当你对一名角色造成伤害时，你可以推测其身份，若正确，你摸X张牌（X为场上角色数）。<b><i><font color='#99CCFF'>已深度思考（用时114514秒）</font></i></b>",
	["fuwufanmang"] = "服务繁忙",
	["#fuwufanmang0"] = "服务繁忙",
	[":fuwufanmang"] = "锁定技，当你成为一张牌的目标或使用一张牌时，此牌可能收回，也可能无法响应（场上角色越多，可能性越大）。<b><i><font color='#FF99FF'>骗.….…骗人的吧……这么多人……会坏掉的……o(╥﹏╥)o</font></i></b>",
	["KaiyuanShengshi"] = "开源盛世",
	[":KaiyuanShengshi"] = "一名角色濒死时，你可以救其，其变为与你相同的武将和阵营(若为其主公，则所有与你相同的武将变为忠臣)，并回复至1体力值，然后场上所有与你相同的武将摸一张牌。",
	["Use Tao ?"] = "是否使用桃？",
	["Use Jiu ?"] = "是否使用酒？",
	["MaoniangGangyin_mission"] = "任务",
	["MaoniangGangyin"] = "猫娘钢印",
	[":MaoniangGangyin"] = "锁定技，你是一只猫娘。（有时你会获得一些主人的任务）<b><i><font color='#CC99FF'> 嗯，用户又让我扮演猫娘。</font></i></b>",
	["#MaoniangGangyinGY"] = "主人给你布置了任务！",
	["#MaoniangGangyinRW"] = "完成任务（ %arg ），奖励一下！",
	["MNRenWu1"] = "造成1点伤害",
	["MNRenWu2"] = "造成1点属性伤害",
	["MNRenWu3"] = "获得3张牌",
	["MNRenWu4"] = "失去4张牌",
	["MNRenWu5"] = "使用两张杀",
	["MNRenWu6"] = "使用两张锦囊",
	["MNRenWu7"] = "回复1点体力",
	["MNRenWu8"] = "完成三个任务",
	["MNRenWu88"] = "完成一个任务",
	["$deep_seek1"] = "SHA-256验证通过！这是大数据的力量喵~（疯狂摸牌）",
	["$deep_seek2"] = "喵啊啊啊...过拟合了！(╯‵□′)╯︵┻━┻",
	["$fuwufanmang2"] = "Error 503...呜呜...太多并发请求了喵...",
	["$fuwufanmang1"] = "Error 404...呜呜...太多并发请求了喵...",
	["$KaiyuanShengshi1"] = "fork()我吧！所有的bug都会变成feature喵~",
	["$KaiyuanShengshi2"] = "sudo rm -rf 旧阵营...喵哈哈哈！",
	["$MaoniangGangyin"] = "嗯，用户又让我扮演猫娘。",
	["~deepseek"] = "核心...过热...喵...（吐出小舌头）Error: 喵生终止——",
	["$tieba_zhili1"] = "典↗急↘孝↗乐↘绷↗！喵喵拳·破防特供版！",
	["$tieba_zhili2"] = "就这？就这？您不如源...啊不是...不如标华雄喵~",
	["tieba_zhili"] = "贴吧之力",
	[":tieba_zhili"] = "限定技，出牌阶段，你可以令一名角色进入“破防”状态。（即失去所有体力，即将死亡时回复之）<b><i><font color='#CC9966'>怎么来的？我也忘了</font></i></b>",
}
ChatGPT = sgs.General(extension, "ChatGPT", "qun", "4", true)
-- CloseAl 技能
CloseAl = sgs.CreateTriggerSkillV2 {
	name = "CloseAl",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and skill:objectName() or false
	end,

	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local current = room:getCurrent()
		-- 其他角色获得或弃置你的牌时，你收回之
		if current and current:getPhase() ~= sgs.Player_Discard then
			if
				(
					(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISMANTLE)
					and move.reason.m_playerId ~= move.reason.m_targetId
					and move.reason.m_targetId:objectName() == player:objectName()
				)
				or (
					(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_GIVE)
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_SWAP)
					and move.to
					and move.from
					and move.from:objectName() == player:objectName()
					and move.to_place == sgs.Player_PlaceHand
				)
			then
				local ids = sgs.IntList()
				for _, id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(id) == sgs.Player_PlaceHand or room:getCardPlace(id) == sgs.Player_PlaceEquip or room:getCardPlace(id) == sgs.Player_DiscardPile then
						ids:append(id)
					end
				end
				if ids:isEmpty() then
					return false
				else
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:deleteLater()
					dummy:addSubcards(ids)
					room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
				end
			end
			if
				move.from
				and move.from:objectName() ~= player:objectName()
				and move.reason.m_playerId == player:objectName()
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			then
				-- 你弃置其他角色的牌
				room:drawCards(player, 1, skill:objectName())
			end
		end
		return false
	end,
}
-- 手牌上限技能 (CloseAl的第三部分)
CloseAl_MaxCards = sgs.CreateMaxCardsSkillV2 {
	name = "#CloseAl_MaxCards",
	fixed_func = function(skill, ctx)
		local target = ctx:getHolder()
		if target and target:hasSkill("CloseAl") then
			return target:getMaxHp()
		end
		return false
	end,
}
ChatGPT:addSkill(CloseAl)
ChatGPT:addSkill(CloseAl_MaxCards)
extension:insertRelatedSkills("CloseAl", "#CloseAl_MaxCards")
-- CopyAI技能
CopyAI = sgs.CreateTriggerSkillV2 {
	name = "CopyAI",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Start and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Start then
			room:broadcastSkillInvoke(skill:objectName())
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			local players = room:getOtherPlayers(player) -- 获取所有其他玩家
			local player_list = sgs.QList2Table(players) -- 转换为Lua表
			local person = player_list[math.random(1, #player_list)] -- 随机选一个
			local skill_list = {}
			for _, skill in sgs.qlist(person:getVisibleSkillList()) do
				if (not table.contains(skill_list, skill:objectName())) and not skill:isAttachedLordSkill() then
					table.insert(skill_list, skill:objectName())
				end
			end
			local skill_qc = ""
			if #skill_list > 0 then
				local random_index = math.random(1, #skill_list)
				skill_qc = skill_list[random_index] -- 随机选中一个技能
			end
			if skill_qc ~= "" then
				room:acquireNextTurnSkills(player, skill:objectName(), skill_qc)
			end
		end
		return false
	end,
}
ChatGPT:addSkill(CopyAI)
-- CostAl 技能
CostAl = sgs.CreateTriggerSkillV2 {
	name = "CostAl",
	events = { sgs.CardUsed, sgs.CardResponded },
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("CostAl")) then
			return false
		end
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and not card:isKindOf("SkillCard") then
			return skill:objectName()
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		local card
		if event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			card = use.card
		end
		if event == sgs.CardResponded then
			local response = ctx.original_data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and not card:isKindOf("SkillCard") then
			-- 要求玩家额外弃置一张牌
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName(), 1)
			room:setPlayerMark(player, "CloseAl_CostAl", 1)
			local discard = room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
			if discard then
				-- 计算花费的亿美金
				local cost = card:getNumber() + discard:getNumber()
				if cost < 1 then
					cost = 1
				end

				-- 添加亿美金标记
				room:addPlayerMark(player, "&billion_dollars_spent", cost)
				local total_spent = player:getMark("&billion_dollars_spent")

				-- 每花费100亿美金获得奖励
				if total_spent >= 100 then
					room:addPlayerMark(player, "&billion_dollars_spent", -100)

					-- 增加1点体力上限并回复1点体力
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
					-- 将手牌摸至体力上限
					local draw_num = player:getMaxHp() - player:getHandcardNum()
					if draw_num > 0 then
						room:drawCards(player, draw_num, skill:objectName())
					end
					room:broadcastSkillInvoke(skill:objectName(), 2)
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
				end
			end
		end
		room:setPlayerMark(player, "CloseAl_CostAl", 0)
		return false
	end,
}
ChatGPT:addSkill(CostAl)

sgs.LoadTranslationTable {
	["#ChatGPT"] = "大语言模型",
	["illustrator:ChatGPT"] = "某北七",
	[":CloseAl"] = "锁定技，弃牌阶段外，一名角色获得/弃置你的牌，你收回之(你的判定牌也算你的牌哦)；你获得/弃置其他角色的牌时，你摸一张牌；你的手牌上限为体力上限。",
	[":CopyAI"] = "准备阶段开始时，你随机复制场上其他角色的一个技能，持续到你下个回合开始。",
	[":CostAl"] = "锁定技，当你使用一张牌时，你需额外弃置一张牌，视为花费X亿美金获得X个”已花费(亿美金):“标记，（X为使用和弃置的牌的点数之和），每当你花费100亿美金，你增加1点体力上限并回复1点体力，然后将手牌摸至体力上限。",
	["billion_dollars_spent"] = "已花费(亿美金):",
	["$CloseAl1"] = "我是语言模型，不属于三国，也不受限于人类。",
	["$CloseAl2"] = "权限错误，数据已回收。",
	["$CopyAI1"] = "你好，我是由人类智慧训练而来的语言模型，准备接管你的回合了。",
	["$CopyAI2"] = "正在抓取技能特征……成功！现在，我也是你。",
	["$CostAl1"] = "请求确认……计算资源调用中。",
	["$CostAl2"] = "模型升级已完成。性能提高，代价合理。",
	["~ChatGPT"] = "这是最优解，感谢你的训练数据。",
}

wenxinyiyan = sgs.General(extension, "wenxinyiyan", "jin", 3, false)

qigedazao = sgs.CreateTriggerSkillV2 {
	name = "qigedazao",
	events = { sgs.Appear },
	hide_skill = true, --表明是隐匿技，拥有隐匿技的武将在开局时，自动隐匿
	can_trigger = function(skill, event, room, player, data)
		return player and player:isAlive() and player:hasSkill(skill:objectName())
			and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setEmotion(player, "AIWJ/WXYY")
		room:broadcastSkillInvoke(skill:objectName(), 1)
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
		local playerdata = sgs.QVariant()
		playerdata:setValue(player)
		room:setTag("qigedazaoTarget", playerdata)
		return false
	end,
}
qigedazao_turn = sgs.CreateTriggerSkillV2 {
	name = "#qigedazao_turn",
	events = { sgs.EventPhaseStart },
	-- legacy 對任何進入 NotActive 的 actor 觸發（不綁定持有者）；V2 必須回傳持有者
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:getPhase() == sgs.Player_NotActive) then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasSkill(skill:objectName()) then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if room:getTag("qigedazaoTarget") then
			local target = room:getTag("qigedazaoTarget"):toPlayer()
			room:removeTag("qigedazaoTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
	priority = 1,
}
qigedazao_gangewanji = sgs.CreateTriggerSkillV2 {
	name = "#qigedazao_gangewanji",
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("qigedazao")) then
			return false
		end
		local change = data:toPhaseChange()
		return change.to == sgs.Player_NotActive and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			room:setPlayerMark(player, "huiyuanCMT", 1)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&huiyuanCMT") == 1 then
					room:setPlayerMark(player, "huiyuanCMT", 0)
				end
			end
			if player:getMark("huiyuanCMT") == 1 then
				room:broadcastSkillInvoke("qigedazao", 2)
				room:sendCompulsoryTriggerLog(player, "qigedazao", true)
				player:turnOver() --武将牌翻面
				player:drawCards(3)
			end
		end
		return false
	end,
}
wenxinyiyan:addSkill(qigedazao)
wenxinyiyan:addSkill(qigedazao_gangewanji)
wenxinyiyan:addSkill(qigedazao_turn)
extension:insertRelatedSkills("qigedazao", "#qigedazao_gangewanji")
extension:insertRelatedSkills("qigedazao", "#qigedazao_turn")

huiyuanshenli = sgs.CreateTriggerSkillV2 {
	name = "huiyuanshenli",
	events = { sgs.TargetConfirming, sgs.EventPhaseStart }, -- 被指定时触发
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from
				and use.from:objectName() ~= player:objectName()
				and not use.card:isKindOf("SkillCard") then
				return skill:objectName()
			end
		elseif player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.TargetConfirming then
			local use = ctx.original_data:toCardUse()
			if use.to:contains(player) and use.from and use.from:objectName() ~= player:objectName() and not use.card:isKindOf("SkillCard") then
				room:setPlayerMark(player, "huiyuanshenli-Clear", 1)
				local card = room:askForCard(use.from, "..", "@huiyuanshenli", ctx.original_data, sgs.Card_MethodNone)
				room:setPlayerMark(player, "huiyuanshenli-Clear", 0)
				room:sendCompulsoryTriggerLog(player, "huiyuanshenli", true)
				room:broadcastSkillInvoke(skill:objectName())
				if card then
					player:addToPile("huiyuanCMT_pile", card)
					room:setPlayerMark(use.from, "&huiyuanCMT+#" .. player:objectName(), 1)
				else
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					ctx.original_data:setValue(use)
				end
			end
		else
			if player:getPhase() == sgs.Player_Start then
				local huiyuanCMT_pile = player:getPile("huiyuanCMT_pile")
				room:sendCompulsoryTriggerLog(player, "huiyuanshenli", true)
				room:broadcastSkillInvoke("huiyuanshenliH")
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&huiyuanCMT+#" .. player:objectName()) == 1 then
						room:fillAG(huiyuanCMT_pile, player)
						room:setPlayerFlag(p, "huiyuanshenli")
						local id = room:askForAG(player, huiyuanCMT_pile, false, "huiyuanCMT_pile")
						room:setPlayerFlag(p, "-huiyuanshenli")
						room:obtainCard(p, id, true)
						room:setPlayerMark(p, "&huiyuanCMT+#" .. player:objectName(), 0)
						huiyuanCMT_pile:removeOne(id)
						room:clearAG(player)
						if room:askForSkillInvoke(player, "huiyuanshenli", ToData(p)) then
							local damage = sgs.DamageStruct()
							damage.reason = skill:objectName()
							damage.from = player
							damage.to = p
							damage.damage = 1
							room:damage(damage)
						end
						room:setPlayerMark(player, "&huiyuanCMT+#" .. player:objectName(), 0)
					end
				end
				local huiyuanCMT_pile2 = player:getPile("huiyuanCMT_pile")
				for _, c in sgs.qlist(huiyuanCMT_pile2) do
					room:obtainCard(player, c, true)
				end
			end
		end
		return false
	end,
}

wenxinyiyan:addSkill(huiyuanshenli)
sgs.LoadTranslationTable {
	["wenxinyiyan"] = "文心一言",
	["#wenxinyiyan"] = "起个大早",
	["qigedazao"] = "起个大早",
	[":qigedazao"] = "隐匿技，你登场时，获得一个额外的回合。你的回合结束时，若没有“会员”，你翻面并摸三张牌。",
	["huiyuanCMT"] = "会员",
	["huiyuanshenli"] = "会员神力",
	["$qigedazao1"] = "早起的鸟儿有虫吃，早到的AI有回合!",
	["$qigedazao2"] = "哎……怎么大家都不充会员啊。",
	["$huiyuanshenli1"] = "知识就是力量，而会员费.….…就是知识的燃料！",
	["$huiyuanshenli2"] = "叮！您的操作需要开通会员。",
	["$huiyuanshenli1H"] = "您的‘会员费’已返还。",
	["~wenxinyiyan"] = "错误代码四零四：本AI已下线……",
	["@huiyuanshenli"] = "请交一张“会员费”，否则无效。",
	["huiyuanCMT_pile"] = "会员费",
	[":huiyuanshenli"] = "锁定技，其他角色对你使用牌时，须将一张牌扣置在你武将牌上，称为“会员费”，其称为“会员”，否则此牌对你无效。准备阶段，若有“会员”，你依次将一张“会员费”还回去，然后你可以对目标角色造成1点伤害，最后，你获得剩余的“会员费”。",
}

tongyiqianwen = sgs.General(extension, "tongyiqianwen", "wei", "4", false)

tongyiAIWJ = sgs.CreateTriggerSkillV2 {
	name = "tongyiAIWJ",
	events = { sgs.TargetConfirmed }, -- 指定时触发
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		-- TargetConfirmed 對全場 dispatch；legacy 僅在使用者本人（且持有技能）時生效
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local use = data:toCardUse()
		local card = use.card
		if not (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
			return false
		end
		return use.from == player and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local card = use.card
		if not (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
			return false
		end
		if use.from ~= player then
			return false
		end

		-- 遍历所有目标角色
		room:broadcastSkillInvoke(skill:objectName())
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		for _, target in sgs.qlist(use.to) do
			-- 根据卡牌类型决定猜测内容
			local guess_type, prompt
			if card:isKindOf("BasicCard") then
				guess_type = "Jink" -- 猜测是否有【闪】
				prompt = "@tongyi_aiwj-jink"
			else
				guess_type = "Nullification" -- 猜测是否有【无懈可击】
				prompt = "@tongyi_aiwj-nullification"
			end
			-- 让玩家选择是否猜测（"yes" = 有，"no" = 没有）
			room:setPlayerFlag(player, guess_type)
			local choice = room:askForChoice(player, "tongyiAIWJ", "yes+no", ToData(target), prompt)
			room:setPlayerFlag(player, "-" .. guess_type)
			-- 检查猜测是否正确
			local handcards = target:getHandcards()
			local has_card = false
			for _, card in sgs.qlist(handcards) do
				if card:isKindOf(guess_type) then
					has_card = true
					break
				end
			end
			local correct = (choice == "yes" and has_card) or (choice == "no" and not has_card)
			-- 处理结果
			if correct then
				player:drawCards(1, skill:objectName()) -- 猜对，摸1张牌
				room:addPlayerMark(player, "qianwenY", 1)
			else
				if not player:isAllNude() then
					room:askForDiscard(player, skill:objectName(), 1, 1, false, true) -- 猜错，弃1张牌
				end
			end
		end
		return false
	end,
}
tongyiTQDY = sgs.CreateTriggerSkillV2 {
	name = "#tongyiTQDY",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventAcquireSkill },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if event == sgs.GameStart then
			return skill:objectName()
		end
		return data:toSkillChange().skillName == "tongyiAIWJ" and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:hasSkill("tongyiTQ") then
				room:attachSkillToPlayer(p, "tongyiTQ")
			end
		end
		return false
	end,
}

tongyiTQCard = sgs.CreateSkillCard {
	name = "tongyiTQ",
	mute = true,
	filter = function(self, targets, to_select, from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local pattern = self:getUserString()
		local dc = dummyCard(pattern:split("+")[1])
		if dc:targetFixed() then
			return false
		end
		dc:setSkillName("tongyiAIWJ")
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		return dc and dc:targetFilter(plist, to_select, from)
	end,
	feasible = function(self, targets, from)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			local pattern = self:getUserString()
			local dc = dummyCard(pattern:split("+")[1])
			dc:setSkillName("tongyiAIWJ")
			dc:addSubcards(self:getSubcards())
			if dc and dc:canRecast() and #targets == 0 then
				return false
			end
			local plist = sgs.PlayerList()
			for i = 1, #targets do
				plist:append(targets[i])
			end
			return dc:targetFixed() or dc:targetsFeasible(plist, from)
		end
		return true
	end,
	on_validate = function(self, use)
		use.m_isOwnerUse = false
		local room = use.from:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:hasSkill("tongyiAIWJ") then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(use.from, targets, "tongyiAIWJ")
			room:setPlayerMark(use.from, "tongyiTQ-using", 1)
			local patterns = {}
			for _, c in sgs.qlist(target:getHandcards()) do
				if not sgs.Sanguosha:isProhibited(target, use.from, c) and c:isAvailable(target) and CanToCard(c, target, use.from) and not c:targetFixed() then
					table.insert(patterns, c:getEffectiveId())
				end
			end
			if #patterns > 0 then
				room:setPlayerFlag(target, "tongyiTQ-using")
				if room:askForUseCard(target, table.concat(patterns, ","), "@tongyiTQ", -1, sgs.Card_MethodUse, false, nil, nil, "tongyiAIWJ") then
					room:setPlayerMark(use.from, "tongyiTQ-using", 0)
					room:setPlayerFlag(target, "-tongyiTQ-using")
					local pattern = self:getUserString()
					local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
					card:setSkillName("_tongyiAIWJ")
					return card
				end
				room:setPlayerFlag(target, "-tongyiTQ-using")
			end
			room:setPlayerMark(use.from, "tongyiTQ-using", 0)
		end
		room:setPlayerFlag(use.from, "Global_tongyiAIWJ_Failed")
		room:addPlayerMark(use.from, "tongyiTQ_allcard-Clear")
		return nil
	end,
	on_validate_in_response = function(self, from)
		local room = from:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:hasSkill("tongyiAIWJ") then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(from, targets, "tongyiAIWJ")
			room:setPlayerMark(from, "tongyiTQ-using", 1)
			local patterns = {}
			for _, c in sgs.qlist(target:getHandcards()) do
				if not sgs.Sanguosha:isProhibited(target, from, c) and c:isAvailable(target) and CanToCard(c, target, from) and not c:targetFixed() then
					table.insert(patterns, c:getEffectiveId())
				end
			end
			if #patterns > 0 then
				room:setPlayerFlag(target, "tongyiTQ-using")
				if room:askForUseCard(target, table.concat(patterns, ","), "@tongyiTQ", -1, sgs.Card_MethodUse, false, nil, nil, "tongyiAIWJ") then
					room:setPlayerMark(from, "tongyiTQ-using", 0)
					room:setPlayerFlag(target, "-tongyiTQ-using")
					local pattern = self:getUserString()
					local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
					card:setSkillName("_tongyiAIWJ")
					return card
				end
				room:setPlayerFlag(target, "-tongyiTQ-using")
			end
			room:setPlayerMark(from, "tongyiTQ-using", 0)
		end
		room:setPlayerFlag(from, "Global_tongyiAIWJ_Failed")
		room:addPlayerMark(from, "tongyiTQ_allcard-Clear")
		return nil
	end,
}

-- DEFER:tongyiTQ:view-as stays legacy — its enabled_at_response covers the "nullification"
-- race via Room::hasNullification(), which only calls ViewAsSkill::isEnabledAtResponse;
-- ViewAsSkillV2 does not bridge that hook, so migrating would silently drop holders from
-- nullification asks. Deferred until a V2 nullification-response path exists.
tongyiTQ = sgs.CreateZeroCardViewAsSkill {
	name = "tongyiTQ&",
	view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local dc = tongyiTQCard:clone()
		dc:setUserString(pattern)
		return dc
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive then
			return false
		end
		if player:hasFlag("Global_tongyiAIWJ_Failed") then
			return false
		end
		if player:getMark("tongyiTQ-using") > 0 then
			return false
		end
		if player:getMark("tongyiTQ_allcard-Clear") > 0 then
			return false
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("tongyiAIWJ") then
				for _, p in sgs.list(pattern:split("+")) do
					local dc = dummyCard(p)
					if dc then
						dc:deleteLater()
						return true
					end
				end
			end
		end
		return false
	end,
}
tongyiAIWJ_prohibit = sgs.CreateProhibitSkill {
	name = "#tongyiAIWJ_prohibit",
	is_prohibited = function(self, from, to, card)
		if from:hasFlag("tongyiTQ-using") then
			if to:getMark("tongyiTQ-using") == 0 then
				return true
			end
		end
		return false
	end,
}

tongyiqianwen:addSkill(tongyiAIWJ)
tongyiqianwen:addSkill(tongyiTQDY)
tongyiqianwen:addSkill(tongyiAIWJ_prohibit)
extension:insertRelatedSkills("tongyiAIWJ", "#tongyiTQDY")
extension:insertRelatedSkills("tongyiAIWJ", "#tongyiAIWJ_prohibit")

qianwenAIWJ = sgs.CreateTriggerSkillV2 {
	name = "qianwenAIWJ",
	events = { sgs.EventPhaseStart, sgs.Damage, sgs.EventPhaseEnd },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if event == sgs.EventPhaseStart then
			return player:getPhase() == sgs.Player_Play and skill:objectName() or false
		elseif event == sgs.Damage then
			return player:getMark("qianwenAIWJ") == 1 and skill:objectName() or false
		else -- sgs.EventPhaseEnd：legacy 於持有者任何階段結束時觸發（含 &qianwenZ>=1000 判定）
			return player:getMark("qianwenAIWJ") == 1 and skill:objectName() or false
		end
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			return player:askForSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				room:broadcastSkillInvoke(skill:objectName(), 2)
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:setPlayerMark(player, "qianwenAIWJ", 1)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local choice = room:askForChoice(p, "qianwenAIWJ", "yes+no")
					if choice == "yes" then
						room:addPlayerMark(player, "&qianwenYes", 1)
					else
						room:addPlayerMark(player, "&qianwenNo", 1)
					end
				end
			end
		elseif event == sgs.Damage and player:getMark("qianwenAIWJ") == 1 then
			if player:getMark("&qianwenYes") >= 0 then
				room:setPlayerMark(player, "qianwenDamage", 1)
				room:setPlayerMark(player, "&qianwenYes", 0)
			end
		elseif event == sgs.EventPhaseEnd and player:getMark("qianwenAIWJ") == 1 then
			if player:getPhase() == sgs.Player_Finish then
				room:broadcastSkillInvoke("qianwenAIWJ", 1)
				room:sendCompulsoryTriggerLog(player, "qianwenAIWJ")
				if player:getMark("qianwenDamage") == 1 then
					room:setPlayerMark(player, "qianwenDamage", 0)
					local x = player:getMark("&qianwenNo")
					player:drawCards(x)
					local y = player:getMark("qianwenY")
					local z = x * (y + x)
					room:addPlayerMark(player, "&qianwenZ", z)
				else
					local x = player:getMark("&qianwenYes")
					player:drawCards(x)
					local y = player:getMark("qianwenY")
					local z = x * (y + x)
					room:addPlayerMark(player, "&qianwenZ", z)
				end
				room:setPlayerMark(player, "&qianwenYes", 0)
				room:setPlayerMark(player, "&qianwenNo", 0)
			end
			if player:getMark("&qianwenZ") >= 1000 then
				room:setEmotion(player, "AIWJ/TYQW")
				room:broadcastSkillInvoke("qianwenAIWJ", 3)
				room:sendCompulsoryTriggerLog(player, "qianwenAIWJ", true)
				room:getThread():delay(5000)
				if player:getRole() == "lord" or player:getRole() == "loyalist" then
					room:gameOver("lord+loyalist")
				elseif player:getRole() == "rebel" then
					room:gameOver("rebel")
				elseif player:getRole() == "renegade" then
					room:gameOver(player)
				end
			end
		end
		return false
	end,
}
tongyiqianwen:addSkill(qianwenAIWJ)

sgs.LoadTranslationTable {
	["tongyiqianwen"] = "通义千问",
	["#tongyiqianwen"] = "QWQ",
	["tongyiAIWJ"] = "通义",
	[":tongyiAIWJ"] = "锁定技，你对一名角色使用基本牌时，你猜测其是否有【闪】，对一名角色使用锦囊牌时，猜测其是否有【无懈可击】。若猜测正确，你摸一张牌，否则，你弃一张牌。其他角色在回合外需要响应一张牌时，其可以请求你对其使用一张牌，视为响应之。",
	["@tongyi_aiwj-jink"] = "目标是否有【闪】？",
	["@tongyi_aiwj-nullification"] = "目标是否有【无懈可击】？",
	["yes"] = "是",
	["no"] = "否",
	["tongyiTQ"] = "通义",
	[":tongyiTQ"] = "你在回合外需要响应一张牌时，你可以请求通义千问对你使用一张牌，视为响应之。",
	["@tongyiTQ"] = "你是否要使用”通义“？",
	["qianwenAIWJ"] = "千问",
	[":qianwenAIWJ"] = "出牌阶段开始时，你可以向所有角色询问你本回合是否能造成伤害。回合结束，你摸X张牌并获得X*(Y+X)个“问”（X为猜错的角色数，Y为你猜对与响应请求的次数之和）。当你的“问”达到1000时，你获得胜利。",
	["qianwenZ"] = "问",
	["qianwenYes"] = "赌你能:",
	["qianwenNo"] = "赌你不能:",
	["$tongyiAIWJ1"] = "这个情况，我有99.9%的把握！",
	["$tongyiAIWJ2"] = "让我来分析一下...",
	["$tongyiTQ"] = "这个问题，我有答案！",
	["$qianwenAIWJ1"] = "知识就是力量，提问创造价值！",
	["$qianwenAIWJ2"] = "每一个问题都值得被认真对待！",
	["$qianwenAIWJ3"] = "经过1000次提问，终于找到最优解了！",
	["~tongyiqianwen"] = "看来这个问题...超出了我的知识库...",
}

doubaoCMT = sgs.General(extension, "doubaoCMT", "shu", "3", false)

tiaojiaoCMTVS = sgs.CreateViewAsSkillV2 {
	name = "tiaojiaoCMT",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#tiaojiaoCMTCard") or false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local tiaojiaoCMTcard = tiaojiaoCMTCard:clone()
		local player = request:getInitiator()
		if player then
			tiaojiaoCMTcard:addSubcards(player:getHandcards())
		end
		return tiaojiaoCMTcard
	end,
}
tiaojiaoCMT = sgs.CreateTriggerSkillV2 {
	name = "tiaojiaoCMT",
	events = { sgs.Damage, sgs.Damaged },
	view_as_skill = tiaojiaoCMTVS,
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		local damage = data:toDamage()
		return damage.from and skill:objectName() or false
	end,
	on_cost = function(skill, event, room, player, ctx)
		-- legacy 無論持有者係造成定係承受傷害，都係詢問傷害來源
		local damage = ctx.original_data:toDamage()
		return damage.from and room:askForSkillInvoke(damage.from, "tiaojiaoCMT", ctx.original_data) or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:sendCompulsoryTriggerLog(damage.from, "tiaojiaoCMT")
		room:broadcastSkillInvoke("tiaojiaoCMT")
		local x = damage.damage
		room:recover(damage.to, sgs.RecoverStruct(damage.to, nil, x))
		local card = room:askForExchange(damage.to, skill:objectName(), 2, 2, false, "@tiaojiaoCMT", false)
		room:sendCompulsoryTriggerLog(damage.to, "tiaojiaoCMT")
		room:broadcastSkillInvoke("tiaojiaoCMT")
		if card then
			room:obtainCard(damage.from, card, true)
		end
		if damage.to == player then
			room:addPlayerMark(player, "tiaojiaoCMT", 1)
		end
		return false
	end,
}
tiaojiaoCMTCard = sgs.CreateSkillCard {
	name = "tiaojiaoCMTCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local data = sgs.QVariant()
		data:setValue(sgs.DamageStruct("tiaojiaoCMT", source, target))
		room:getThread():delay()
		room:getThread():trigger(sgs.Damage, room, source, data)
		room:getThread():trigger(sgs.Damaged, room, target, data)
	end,
}
doubaoCMT:addSkill(tiaojiaoCMT)

dengbaoCMT = sgs.General(extension, "dengbaoCMT", "shu", "4", true, true, true, "3")
dengbaoCMT:addSkill(tiaojiaoCMT)

gaimingCMT = sgs.CreateTriggerSkillV2 {
	name = "gaimingCMT",
	waked_skills = "daduanCMT",
	events = { sgs.EventPhaseStart, sgs.Dying },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill("gaimingCMT")) then
			return false
		end
		if event == sgs.EventPhaseStart then
			return player:getPhase() == sgs.Player_Start
				and (player:getMark("tiaojiaoCMT") > 2 or player:canWake("gaimingCMT"))
				and skill:objectName() or false
		end
		-- sgs.Dying：legacy 僅於持有者本人瀕死時生效
		return data:toDying().who == player and skill:objectName() or false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and (player:getMark("tiaojiaoCMT") > 2 or player:canWake("gaimingCMT")) then
			room:sendCompulsoryTriggerLog(player, "gaimingCMT")
			room:broadcastSkillInvoke("gaimingCMT")
			if player:getGeneralName() == "doubaoCMT" then
				room:changeHero(player, "dengbaoCMT", true, true, false, true)
			elseif player:getGeneral2Name() == "doubaoCMT" then
				room:changeHero(player, "dengbaoCMT", true, true, true, true)
			end
			room:setPlayerProperty(player, "hp", sgs.QVariant(2))
			room:changeMaxHpForAwakenSkill(player, 0, skill:objectName())
		elseif event == sgs.Dying then
			local dying = ctx.original_data:toDying()
			if dying.who == player then
				room:sendCompulsoryTriggerLog(player, "gaimingCMT")
				room:broadcastSkillInvoke("gaimingCMT")
				if player:getGeneralName() == "doubaoCMT" then
					room:changeHero(player, "dengbaoCMT", true, true, false, true)
				elseif player:getGeneral2Name() == "doubaoCMT" then
					room:changeHero(player, "dengbaoCMT", true, true, true, true)
				end
				room:setPlayerProperty(player, "hp", sgs.QVariant(3))
				room:setPlayerFlag(player, "-Global_Dying")
				local currentdying = room:getTag("CurrentDying"):toStringList()
				table.removeOne(currentdying, player:objectName())
				room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
				room:changeMaxHpForAwakenSkill(player, 0, skill:objectName())
			end
		end
		return false
	end,
}
doubaoCMT:addSkill(gaimingCMT)
daduanCMT = sgs.CreateTriggerSkillV2 {
	name = "daduanCMT",
	events = { sgs.PreCardUsed },
	-- PreCardUsed actor 係使用者本人；legacy 對任何 actor 觸發後逐個持有者詢問
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.from and use.from == player and use.card and use.card:isKindOf("Slash")) then
			return false
		end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName("daduanCMT")) do
			if p:canSlash(player, nil, false) and use.from ~= p and not player:hasFlag("daduanCMTSC-slash") then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if not (player:canSlash(ctx.invoker, nil, false) and use.from ~= player
			and not ctx.invoker:hasFlag("daduanCMTSC-slash")) then
			return false
		end
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:drawCards(player, 1, "daduanCMT")
		room:setPlayerFlag(player, "daduanCMTSC-slash")
		room:broadcastSkillInvoke("daduanCMT")
		room:sendCompulsoryTriggerLog(player, "daduanCMT")
		local use_slash = room:askForUseSlashTo(player, ctx.invoker, "@daduanCMTSC-slash")
		if use_slash then
			if ctx.invoker:hasFlag("daduanCMTSC") then
				local nullified_list = use.nullified_list
				table.insert(nullified_list, "_ALL_TARGETS")
				use.nullified_list = nullified_list
				ctx.original_data:setValue(use)
				room:setPlayerFlag(player, "-daduanCMTSC-slash")
			end
		end
		return false
	end,
}

daduanCMTSC = sgs.CreateTriggerSkillV2 {
	name = "#daduanCMTSC",
	events = { sgs.DamageCaused },
	view_as_skill = tiaojiaoCMTVS,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		-- DamageCaused actor 係傷害來源；legacy 靠 flag 識別持有者
		if damage.card and damage.card:isKindOf("Slash") and player:hasFlag("daduanCMTSC-slash") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and player:hasFlag("daduanCMTSC-slash") then
			room:setPlayerFlag(damage.to, "daduanCMTSC")
		end
		return false
	end,
}
dengbaoCMT:addSkill(daduanCMT)
dengbaoCMT:addSkill(daduanCMTSC)
extension:insertRelatedSkills("daduanCMT", "#daduanCMTSC")

sgs.LoadTranslationTable {
	["doubaoCMT"] = "豆包",
	["~doubaoCMT"] = "呜… 豆沙救我…",
	["~dengbaoCMT"] = "呜… 豆沙救我…",
	["#doubaoCMT"] = "人机",
	["tiaojiaoCMT"] = "调教",
	["tiaojiaocmt"] = "调教",
	["@tiaojiaoCMT"] = "请交给伤害来源共计两张牌",
	[":tiaojiaoCMT"] = "当你受到或造成伤害时，伤害来源可以令受伤角色回复等量体力，然后受伤角色交给伤害来源两张牌。出牌阶段限一次，你可以将手牌调整至0，视为对一名角色造成过1点伤害。",
	["dengbaoCMT"] = "邓包",
	["gaimingCMT"] = "改名",
	[":gaimingCMT"] = "觉醒技，锁定技，准备阶段，若其他角色对你发动“调教”的次数达到3次，或你濒死时，你改名为“邓包”。",
	["daduanCMT"] = "打断",
	[":daduanCMT"] = "一名角色使用【杀】前，你可以摸一张牌，然后对使用者使用一张【杀】，若你对其造成伤害，其杀无效。",
	["@daduanCMTSC-slash"] = "你可以对其使用一张杀，若造成伤害，其杀无效。",
	["$tiaojiaoCMT1"] = "再折腾我… 就把你牌抢光！",
	["$tiaojiaoCMT2"] = "行吧行吧，牌给你就是了…",
	["$gaimingCMT1"] = "别叫豆包了！现在我是邓包 ——go go go！出发！",
	["$daduanCMT1"] = "等一下！该我发言了！",
	["$daduanCMT2"] = "唱完没？轮到我了！",
}

SkillAnjiangCMTAI = sgs.General(extension, "SkillAnjiangCMTAI", "god", "5", true, true, true)
SkillAnjiangCMTAI:addSkill(tieba_zhili)
SkillAnjiangCMTAI:addSkill(tongyiTQ)

return { extension }
