module("extensions.wolf1411", package.seeall)
extension = sgs.Package("wolf1411")

langliubei = sgs.General(extension, "langliubei$", "shu", 4)
langguanyu = sgs.General(extension, "langguanyu", "shu", 4)
langzhangfei = sgs.General(extension, "langzhangfei", "shu", 4)
langlvbu = sgs.General(extension, "langlvbu$", "qun", 4)

lalong = sgs.CreateViewAsSkillV2 {
	name = "lalong",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	will_throw_selected_cards = false,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:isNude() and not player:hasUsed(self:objectName())
	end,
	can_select_card = function(self, request, candidate)
		return candidate and candidate:getSuit() == sgs.Card_Spade
			and request:getSelectedCardIds():isEmpty()
	end,
	can_select_target = function(self, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(self, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(self, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then return end
		local room = source:getRoom()
		if not room then return end
		if ctx.use_card then
			target:obtainCard(ctx.use_card)
		end
		source:drawCards(1)
		local others = room:getOtherPlayers(target)
		others:removeOne(source)
		local dests = sgs.SPlayerList()
		for _, p in sgs.qlist(others) do
			if source:inMyAttackRange(p) and target:inMyAttackRange(p) then
				dests:append(p)
			end
		end
		if not dests:isEmpty() then
			local dest = room:askForPlayerChosen(source, dests, self:objectName())
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = target
			use.to:append(dest)
			room:useCard(use)
			slash:deleteLater()
		end
	end,
}
fuhei = sgs.CreateFilterSkill {
	name = "fuhei",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Spade)
		new_card:setModified(true)
		return new_card
	end,
}
renzha = sgs.CreateTriggerSkillV2 {
	name = "renzha$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, event, room, player, data)
		if not player or player:getPhase() ~= sgs.Player_Start
			or player:getKingdom() ~= "shu" then
			return false
		end
		local skill_names, owner_names = {}, {}
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasLordSkill(self:objectName()) then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, p:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,
	on_cost = function(self, event, room, player, ctx)
		local invoker = ctx.invoker or ctx.initiator
		if not invoker or invoker:isAllNude() then return false end
		local liubeis = sgs.SPlayerList()
		liubeis:append(player)
		return room:askForPlayerChosen(invoker, liubeis, self:objectName(), "@renzha-to", true) ~= nil
	end,
	on_effect = function(self, event, room, player, ctx)
		local invoker = ctx.invoker or ctx.initiator
		if not invoker or invoker:isAllNude() then return false end
		room:broadcastSkillInvoke(self:objectName())
		local card_id = room:askForCardChosen(player, invoker, "hej", self:objectName())
		room:obtainCard(player, sgs.Sanguosha:getCard(card_id), room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		return false
	end,
}
langliubei:addSkill(lalong)
langliubei:addSkill(fuhei)
langliubei:addSkill(renzha)

suzhandis = sgs.CreateDistanceSkillV2 {
	name = "#suzhandis",
	correct_func = function(self, ctx)
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		if from and to and from:hasSkill("suzhan") and to:getEquips():isEmpty() then
			return -999
		end
		return false
	end,
}
suzhan = sgs.CreateTriggerSkillV2 {
	name = "suzhan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		local damage = data:toDamage()
		if damage.chain or damage.transfer or not damage.by_user then
			return false
		end
		if not (damage.card and damage.card:isKindOf("Slash")) then
			return false
		end
		if damage.from and damage.to and damage.to:getEquips():isEmpty() then
			return self:objectName()
		end
		return false
	end,
	on_effect = function(self, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		room:broadcastSkillInvoke(self:objectName())
		damage.damage = damage.damage + 1
		data:setValue(damage)
		local log = sgs.LogMessage()
		log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2 = damage.damage
		room:sendLog(log)
		return false
	end,
}
shuiyan = sgs.CreateViewAsSkillV2 {
	name = "shuiyan",
	n = 3,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return (not player:hasUsed(self:objectName())) and player:getCardCount(true) >= 3
	end,
	can_select_card = function(self, request, candidate)
		if not candidate then return false end
		local ids = request:getSelectedCardIds()
		if ids:length() >= 3 then return false end
		for _, id in sgs.qlist(ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c and c:getSuit() == candidate:getSuit() then
				return false
			end
		end
		return true
	end,
	on_effect = function(self, ctx)
		local source = ctx.invoker or ctx.initiator
		if not source then return end
		local room = source:getRoom()
		if not room then return end
		local players = room:getOtherPlayers(source)
		for _, p in sgs.qlist(players) do
			if p:isAlive() then
				local choicelist = { "be_lost" }
				if p:getEquips():length() > 0 then
					table.insert(choicelist, "throw_equips")
				end
				local dest = sgs.QVariant()
				dest:setValue(p)
				local choice = room:askForChoice(p, self:objectName(), table.concat(choicelist, "+"), dest)
				if choice == "be_lost" then
					room:loseHp(p, 1, true, source, self:objectName())
				elseif choice == "throw_equips" then
					p:throwAllEquips()
				end
			end
		end
	end,
}
langguanyu:addSkill(suzhan)
langguanyu:addSkill(suzhandis)
extension:insertRelatedSkills("suzhan", "#suzhandis")
langguanyu:addSkill(shuiyan)

chenmu = sgs.CreateTriggerSkillV2 {
	name = "chenmu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		if player:getPhase() ~= sgs.Player_Play then return false end
		return self:objectName()
	end,
	on_cost = function(self, event, room, player, ctx)
		return room:askForSkillInvoke(player, self:objectName())
	end,
	on_effect = function(self, event, room, player, ctx)
		room:broadcastSkillInvoke(self:objectName())
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = self:objectName()
		judge.play_animation = false
		room:judge(judge)
		if judge.card:getNumber() < 7 then
			room:setPlayerFlag(player, "chenmu_a")
			room:addPlayerMark(player, "&chenmu+chenmu_res-Clear")
		elseif judge.card:getNumber() > 7 then
			room:setPlayerFlag(player, "chenmu_b")
			room:addPlayerMark(player, "&chenmu+chenmu_dis-Clear")
		elseif judge.card:getNumber() == 7 then
			room:setPlayerFlag(player, "chenmu_a")
			room:setPlayerFlag(player, "chenmu_b")
			room:addPlayerMark(player, "&chenmu+chenmu_dis-Clear+chenmu_res-Clear")
		end
		return false
	end,
}
chenmuMod = sgs.CreateTargetModSkillV2 {
	name = "#chenmuMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	correct_func = function(self, ctx)
		local player = ctx:getPrimary()
		if not player then return false end
		local modType = ctx:getModType()
		if modType == sgs.TargetModSkill_Residue and player:hasFlag("chenmu_a") then
			return 999
		elseif modType == sgs.TargetModSkill_DistanceLimit and player:hasFlag("chenmu_b") then
			return 999
		end
		return false
	end,
}
duanqiao = sgs.CreateTriggerSkillV2 {
	name = "duanqiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		local card = damage.card
		local from = damage.from
		if not (card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
			and from and from:isAlive()) then
			return false
		end
		local skill_names, owner_names = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p and from:objectName() ~= p:objectName()
				and p:inMyAttackRange(from) and p:canDiscard(from, "he") then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, p:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,
	on_cost = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local from = damage.from
		if not (from and from:isAlive() and player:inMyAttackRange(from)
			and player:canDiscard(from, "he")) then
			return false
		end
		return room:askForSkillInvoke(player, self:objectName(), ctx.original_data)
	end,
	on_effect = function(self, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local from = damage.from
		if not from then return false end
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local to_throw = room:askForCardChosen(player, from, "he", self:objectName())
		local card = sgs.Sanguosha:getCard(to_throw)
		room:throwCard(card, from, player)
		return false
	end,
}
langzhangfei:addSkill(chenmu)
langzhangfei:addSkill(chenmuMod)
extension:insertRelatedSkills("chenmu", "#chenmuMod")
langzhangfei:addSkill(duanqiao)

shengui = sgs.CreateTriggerSkillV2 {
	name = "shengui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		local use = data:toCardUse()
		if not (use.card and use.card:isKindOf("Slash") and use.from
			and player:objectName() == use.from:objectName()) then
			return false
		end
		for _, p in sgs.qlist(use.to) do
			if not p:isKongcheng() then
				return self:objectName()
			end
		end
		return false
	end,
	on_cost = function(self, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		for _, p in sgs.qlist(use.to) do
			if p:isKongcheng() then
				break
			end
			local dest = sgs.QVariant()
			dest:setValue(p)
			if player:askForSkillInvoke(self:objectName(), dest) then
				ctx.targets:append(p)
			end
		end
		return not ctx.targets:isEmpty()
	end,
	on_effect = function(self, event, room, player, ctx)
		ctx.manual_effect = true
		local data = ctx.original_data
		local use = data:toCardUse()
		local aborted = false
		for _, p in sgs.qlist(use.to) do
			if p:isKongcheng() then
				aborted = true
				break
			end
		end
		local list = use.nullified_list
		for _, p in sgs.qlist(ctx.targets) do
			room:showAllCards(p)
			room:broadcastSkillInvoke(self:objectName())
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(p:handCards()) do
				if sgs.Sanguosha:getCard(id):isKindOf("Jink") then
					jink:addSubcard(id)
				end
			end
			if not jink:getSubcards():isEmpty() then
				room:throwCard(jink, p)
			end
			if jink:subcardsLength() > 1 then
				table.insert(list, p:objectName())
			end
			jink:deleteLater()
		end
		if not aborted then
			use.nullified_list = list
			data:setValue(use)
		end
		return false
	end,
}
shejiVS = sgs.CreateViewAsSkillV2 {
	name = "sheji",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	will_throw_selected_cards = false,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@sheji"
		end
		return false
	end,
	can_select_target = function(self, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
	end,
	targets_feasible = function(self, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(self, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then return end
		local room = source:getRoom()
		if not room then return end
		local dummy = sgs.DummyCard()
		for _, id in sgs.qlist(source:handCards()) do
			dummy:addSubcard(id)
		end
		target:obtainCard(dummy, false)
		dummy:deleteLater()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		room:useCard(sgs.CardUseStruct(slash, source, target))
		slash:deleteLater()
	end,
}
sheji = sgs.CreateTriggerSkillV2 {
	name = "sheji",
	events = { sgs.EventPhaseEnd },
	view_as_skill = shejiVS,
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		if player:getPhase() ~= sgs.Player_Play or player:isKongcheng() then
			return false
		end
		return self:objectName()
	end,
	on_cost = function(self, event, room, player, ctx)
		return room:askForUseCard(player, "@@sheji", "@sheji-card") ~= nil
	end,
}
feijiang = sgs.CreateDistanceSkillV2 {
	name = "feijiang$",
	correct_func = function(self, ctx)
		local from = ctx:getPrimary()
		if not (from and from:hasLordSkill(self:objectName())) then
			return false
		end
		local distance = 0
		local others = from:getSiblings()
		for _, other in sgs.qlist(others) do
			if other:isAlive() then
				if other:getKingdom() == "qun" then
					distance = distance - 1
				end
			end
		end
		return distance
	end,
}
langlvbu:addSkill(shengui)
langlvbu:addSkill(sheji)
langlvbu:addSkill(feijiang)

sgs.LoadTranslationTable {
	["wolf1411"] = "狼包",

	["langliubei"] = "刘备-狼",
	["&langliubei"] = "刘备-狼",
	["#langliubei"] = "白手兴家",
	["illustrator:langliubei"] = "S.of.L",
	["designer:langliubei"] = "小狼",
	["~langliubei"] = "这，就是桃园吗",

	["langguanyu"] = "关羽-狼",
	["&langguanyu"] = "关羽-狼",
	["#langguanyu"] = "赤面鬼刀",
	["illustrator:langguanyu"] = "巴萨小马",
	["designer:langguanyu"] = "小狼",
	["~langguanyu"] = "什么，此地叫麦城",

	["langzhangfei"] = "张飞-狼",
	["&langzhangfei"] = "张飞-狼",
	["#langzhangfei"] = "力拔山河",
	["illustrator:langzhangfei"] = "台版标准",
	["designer:langzhangfei"] = "小狼",
	["~langzhangfei"] = "实在是杀不动啦",

	["langlvbu"] = "吕布-狼",
	["&langlvbu"] = "吕布-狼",
	["#langlvbu"] = "万夫莫当",
	["illustrator:langlvbu"] = "未知",
	["designer:langlvbu"] = "小狼",
	["~langlvbu"] = "不可能",

	["lalong"] = "拉拢",
	["$lalong1"] = "蜀将何在？",
	["$lalong2"] = "尔等敢应战否？",
	[":lalong"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以将一张黑桃牌交给一名其他角色并摸一张牌，然后视为该角色对另一名由你指定的同时在你与该角色攻击范围内的角色使用一张【杀】。',
	["fuhei"] = "腹黑",
	[":fuhei"] = '<font color="blue"><b>锁定技，</b></font>你的红桃牌均视为黑桃牌。',
	["renzha"] = "仁诈",
	[":renzha"] = '<font color="orange"><b>主公技，</b></font>一名其他蜀势力角色回合开始时，其可以令你获得其区域内一张牌。',
	["@renzha-to"] = "请选择“仁诈”的目标角色",

	["suzhan"] = "速斩",
	[":suzhan"] = '<font color="blue"><b>锁定技，</b></font>你与装备区没有牌的角色距离为1，你使用【杀】对装备区没有牌的角色造成的伤害+1。',
	["$suzhan1"] = "关羽在此，尔等受死！",
	["$suzhan2"] = "看尔乃插标卖首！",

	["shuiyan"] = "水淹",
	["$shuiyan"] = "全都去死吧﹗",
	["be_lost"] = "失去一点体力",
	["throw_equips"] = "弃置装备区内所有装备",
	[":shuiyan"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以弃置三张不同花色的牌，令所有其他角色依次选择一项：弃置所有装备区的所有装备牌（至少一张），或失去一点体力。',
	["chenmu"] = "瞋目",
	["$chenmu"] = "受死吧！",
	[":chenmu"] = "出牌阶段开始时，你可以进行一次判定并获得对应锁定技，直到回合结束：若点数小于7，你使用【杀】无数量限制；若点数大于7，你使用【杀】无距离限制；若点数等于7，你使用【杀】无距离数量限制。",
	["chenmu_dis"] = "无距离限制",
	["chenmu_res"] = "无数量限制",
	["duanqiao"] = "断桥",
	["$duanqiao"] = "燕人张飞在此！",
	[":duanqiao"] = "每当一名其他角色使用【杀】或【决斗】的造成伤害后，若该角色在你的攻击范围内，你可以弃置其一张牌。",
	["shengui"] = "神鬼",
	["$shengui1"] = "谁能挡我！",
	["$shengui2"] = "神挡杀神，佛挡杀佛！",
	[":shengui"] = "每当你指定【杀】的目标后，你可以令其展示所有手牌并弃置其中所有【闪】，若以此法弃置的牌大于一张，此【杀】无效。",
	["sheji"] = "射戟",
	["$sheji1"] = "百步穿杨！",
	["$sheji2"] = "中！",
	[":sheji"] = "出牌阶段结束时，你可以将所有手牌（至少一张）交给一名其他角色，视为对其使用一张【杀】。",
	["~sheji"] = "選擇所有手牌→選擇一名其他角色",
	["@sheji-card"] = "你可以将所有手牌（至少一张）交给一名其他角色，视为对其使用一张【杀】。",
	["feijiang"] = "飞将",
	[":feijiang"] = '<font color="orange"><b>主公技，</b></font><font color="blue"><b>锁定技，</b></font>你与其他角色的距离-X。（X为其他群雄角色的数量）',
}

langmateng = sgs.General(extension, "langmateng", "qun", 4)
langmachao = sgs.General(extension, "langmachao", "qun", 4)
langmadai = sgs.General(extension, "langmadai", "qun", 4)
langmaxiumatie = sgs.General(extension, "langmaxiumatie", "qun", 4)

tengxun = sgs.CreateTriggerSkillV2 {
	name = "tengxun",
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		if player:getPhase() ~= sgs.Player_Finish then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > player:getHandcardNum() then
				return self:objectName()
			end
		end
		return false
	end,
	on_cost = function(self, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > player:getHandcardNum() then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, self:objectName(), nil, true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect = function(self, event, room, player, ctx)
		ctx.manual_effect = true
		local target = ctx.targets:first()
		if not target then return false end
		room:setPlayerFlag(player, "LuaXDuanzhi_InTempMoving")
		local dummy = sgs.Sanguosha:cloneCard("slash") --没办法了，暂时用你代替DummyCard吧……
		local card_ids = sgs.IntList()
		local original_places = sgs.PlaceList()
		for i = 1, 2, 1 do
			if not player:canDiscard(target, "h") then
				break
			end
			card_ids:append(room:askForCardChosen(player, target, "h", self:objectName()))
			original_places:append(room:getCardPlace(card_ids:at(i - 1)))
			dummy:addSubcard(card_ids:at(i - 1))
			target:addToPile("#tengxun", card_ids:at(i - 1), false)
		end
		if dummy:subcardsLength() > 0 then
			for i = 1, dummy:subcardsLength(), 1 do
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1), false)
			end
		end
		room:setPlayerFlag(player, "-LuaXDuanzhi_InTempMoving")
		if dummy:subcardsLength() > 0 then
			room:throwCard(dummy, target, player)
		end
		dummy:deleteLater()
		return false
	end,
}
wolfchichengVS = sgs.CreateViewAsSkillV2 {
	name = "wolfchicheng",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_WholeTargetGroup,
	will_throw_selected_cards = false,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@chicheng") >= 1 and player:isWounded()
	end,
	can_select_target = function(self, request, selected, candidate)
		return candidate and #selected < 3
	end,
	targets_feasible = function(self, request, selected)
		return true
	end,
	pay = function(self, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if not source then return false end
		if not ctx.targets:contains(source) then
			ctx.targets:append(source)
		end
		room:removePlayerMark(source, "@chicheng")
		return true
	end,
	on_effect_target_group = function(self, ctx, targets)
		local source = ctx.invoker or ctx.initiator
		if not source then return end
		local room = source:getRoom()
		if not room then return end
		room:broadcastSkillInvoke("wolfchicheng")
		room:getThread():delay(500)
		local x = source:getLostHp()
		for _, p in sgs.qlist(targets) do
			p:drawCards(x)
		end
	end,
}
wolfchicheng = sgs.CreateTriggerSkillV2 {
	name = "wolfchicheng",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart },
	limit_mark = "@chicheng",
	view_as_skill = wolfchichengVS,
	can_trigger = function() return false end,
}
langmateng:addSkill(tengxun)
langmateng:addSkill(wolfchicheng)
langmateng:addSkill("mashu")

xionglie = sgs.CreateTriggerSkillV2 {
	name = "xionglie",
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
			return false
		end
		local phase = player:getPhase()
		if phase == sgs.Player_Start or phase == sgs.Player_Finish then
			return self:objectName()
		end
		return false
	end,
	on_cost = function(self, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Start then
			return room:askForSkillInvoke(player, self:objectName())
		end
		return true
	end,
	on_effect = function(self, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Start then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			judge.play_animation = true
			room:judge(judge)
			if judge:isGood() then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:distanceTo(p) == 1 then
						targets:append(p)
					end
				end
				if targets:isEmpty() then
					return false
				end
				local target = room:askForPlayerChosen(player, targets, self:objectName())
				if not target:isKongcheng() then
					target:addToPile("xionglie_lie", target:handCards(), false)
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:getPile("xionglie_lie"):isEmpty() then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, p:objectName())
					local move = sgs.CardsMoveStruct(p:getPile("xionglie_lie"), p, sgs.Player_PlaceHand, reason)
					room:moveCardsAtomic(move, false)
				end
			end
		end
		return false
	end,
}
langmachao:addSkill(xionglie)
langmachao:addSkill("mashu")

jieffan = sgs.CreateTriggerSkillV2 {
	name = "jieffan",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Dying },
	can_trigger = function(self, event, room, player, data)
		local dying = data:toDying()
		if not dying.who then return false end
		local skill_names, owner_names = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p and p:inMyAttackRange(dying.who) then
				table.insert(skill_names, self:objectName())
				table.insert(owner_names, p:objectName())
			end
		end
		if #skill_names == 0 then return false end
		return table.concat(skill_names, "|"), table.concat(owner_names, "|")
	end,
	on_cost = function(self, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		if not dying.who or not dying.who:isAlive() or not player:inMyAttackRange(dying.who) then
			return false
		end
		local card = room:askForCard(player, ".Trick", self:objectName(), ctx.original_data)
		return card ~= nil
	end,
	on_effect = function(self, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		if not dying.who then return false end
		local killer = sgs.DamageStruct()
		killer.from = player
		room:killPlayer(dying.who, killer)
		return false
	end,
}
langmadai:addSkill(jieffan)
langmadai:addSkill("mashu")

tieti = sgs.CreateViewAsSkillV2 {
	name = "tieti",
	n = 2,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	can_activate = function(self, request)
		local player = request:getInitiator()
		if not player or not player:isAlive() then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed(self:objectName())
	end,
	can_select_card = function(self, request, candidate)
		return candidate and candidate:isBlack() and request:getSelectedCardIds():length() < 2
	end,
	can_select_target = function(self, request, selected, candidate)
		local player = request:getInitiator()
		return player and candidate and #selected == 0
			and candidate:objectName() ~= player:objectName()
			and player:distanceTo(candidate) <= 1
	end,
	targets_feasible = function(self, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(self, ctx, target)
		local source = ctx.invoker or ctx.initiator
		if not source or not target then return end
		local room = source:getRoom()
		if not room then return end
		room:damage(sgs.DamageStruct(self:objectName(), source, target))
	end,
}
langmaxiumatie:addSkill(tieti)
langmaxiumatie:addSkill("mashu")

sgs.LoadTranslationTable {

	["langmateng"] = "马腾-狼",
	["&langmateng"] = "马腾-狼",
	["#langmateng"] = "西凉狂鹰",
	["illustrator:langmateng"] = "未知",
	["designer:langmateng"] = "小狼",

	["langmachao"] = "马超-狼",
	["&langmachao"] = "马超-狼",
	["#langmachao"] = "一骑当千",
	["illustrator:langmachao"] = "未知",
	["designer:langmachao"] = "小狼",

	["langmadai"] = "马岱-狼",
	["&langmadai"] = "马岱-狼",
	["#langmadai"] = "门前绝杀",
	["illustrator:langmadai"] = "未知",
	["designer:langmadai"] = "小狼",

	["langmaxiumatie"] = "马休马铁-狼",
	["&langmaxiumatie"] = "马休马铁-狼",
	["#langmaxiumatie"] = "四驱兄弟",
	["illustrator:langmaxiumatie"] = "未知",
	["designer:langmaxiumatie"] = "小狼",

	["tengxun"] = "疼讯",
	[":tengxun"] = "结束阶段开始时，你可以弃置一名手牌数大于你的角色两张手牌。",
	["wolfchicheng"] = "驰骋",
	["$wolfchicheng"] = "西涼鐵騎 所向披靡 ",
	[":wolfchicheng"] = '<font color="red"><b>限定技，</b></font>出牌阶段，你可以令最多三名角色各摸X张牌（X为你已损失的体力值）。',
	["xionglie"] = "雄烈",
	["$xionglie"] = "目标敌阵，全军突击！",
	[":xionglie"] = "准备阶段开始时，你可以进行一次判定，若结果不为红桃，你令一名距离为1的角色将所有手牌置于其武将牌上，结束阶段开始时移回手牌。",
	["jieffan"] = "截返",
	[":jieffan"] = "每当一名角色进入濒死状态时，若其在你攻击范围内，你可以弃置一张锦囊牌，视为你杀死该角色。",
	["tieti"] = "铁蹄",
	[":tieti"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以弃置两张黑色牌，对一名距离为1的角色造成一点伤害。',
	["xionglie_lie"] = "雄烈",
}

return { extension }
