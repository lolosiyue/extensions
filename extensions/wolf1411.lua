module("extensions.wolf1411", package.seeall)
extension = sgs.Package("wolf1411")

langliubei = sgs.General(extension, "langliubei$", "shu", 4)
langguanyu = sgs.General(extension, "langguanyu", "shu", 4)
langzhangfei = sgs.General(extension, "langzhangfei", "shu", 4)
langlvbu = sgs.General(extension, "langlvbu$", "qun", 4)

lalongCard = sgs.CreateSkillCard {
	name = "lalongCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		target:obtainCard(effect.card)
		local room = source:getRoom()
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
			local dest = room:askForPlayerChosen(source, dests, "lalong")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("lalong")
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = target
			use.to:append(dest)
			room:useCard(use)
			slash:deleteLater()
		end
		return false
	end
}
lalong = sgs.CreateViewAsSkill {
	name = "lalong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local lalongCard = lalongCard:clone()
			lalongCard:addSubcard(cards[1])
			return lalongCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and not player:hasUsed("#lalongCard")
	end
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
	end
}
renzha = sgs.CreateTriggerSkill {
	name = "renzha$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			local liubeis = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					liubeis:append(p)
				end
			end
			while not liubeis:isEmpty() and not player:isAllNude() do
				local liubei = room:askForPlayerChosen(player, liubeis, self:objectName(), "@renzha-to", true)
				if liubei then
					room:broadcastSkillInvoke(self:objectName())
					local card_id = room:askForCardChosen(liubei, player, "hej", self:objectName())
					room:obtainCard(liubei, sgs.Sanguosha:getCard(card_id),
						room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					liubeis:removeOne(liubei)
				else
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "shu")
	end
}
langliubei:addSkill(lalong)
langliubei:addSkill(fuhei)
langliubei:addSkill(renzha)

suzhandis = sgs.CreateDistanceSkill {
	name = "#suzhandis",
	correct_func = function(self, from, to)
		if from:hasSkill("suzhan") and to:getEquips():isEmpty() then
			return -999
		end
	end,
}
suzhan = sgs.CreateTriggerSkill {
	name = "suzhan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.chain or damage.transfer or not damage.by_user then return false end
		if not (damage.card and damage.card:isKindOf("Slash")) then return false end
		if damage.from and damage.to:getEquips():isEmpty() then
			room:broadcastSkillInvoke(self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
			local log = sgs.LogMessage()
			log.type = "#skill_add_damage"
			log.from = damage.from
			log.to:append(damage.to)
			log.arg  = self:objectName()
			log.arg2 = damage.damage
			room:sendLog(log)
		end
	end
}
shuiyanCard = sgs.CreateSkillCard {
	name = "shuiyanCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
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
					room:loseHp(p)
				elseif choice == "throw_equips" then
					p:throwAllEquips()
				end
			end
		end
		return false
	end
}
shuiyan = sgs.CreateViewAsSkill {
	name = "shuiyan",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected >= 3 then return false end
		if #selected == 1 then
			return to_select:getSuit() ~= selected[1]:getSuit()
		elseif #selected == 2 then
			return to_select:getSuit() ~= selected[1]:getSuit() and to_select:getSuit() ~= selected[2]:getSuit()
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = shuiyanCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:addSubcard(cards[3])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#shuiyanCard")) and player:getCardCount(true) >= 3
	end
}
langguanyu:addSkill(suzhan)
langguanyu:addSkill(suzhandis)
extension:insertRelatedSkills("suzhan", "#suzhandis")
langguanyu:addSkill(shuiyan)

chenmu = sgs.CreateTriggerSkill {
	name = "chenmu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName()) then
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
			end
		end
	end
}
chenmuMod = sgs.CreateTargetModSkill {
	name = "#chenmuMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("chenmu_a") then
			return 999
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("chenmu_b") then
			return 999
		else
			return 0
		end
	end
}
duanqiao = sgs.CreateTriggerSkill {
	name = "duanqiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local card = damage.card
		local from = damage.from
		if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:isAlive() then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p and from:objectName() ~= p:objectName() and from:isAlive() and p:inMyAttackRange(from) and p:canDiscard(from, "he") then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(p, self:objectName())
						local to_throw = room:askForCardChosen(p, from, "he", self:objectName())
						local card = sgs.Sanguosha:getCard(to_throw)
						room:throwCard(card, from, p)
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
langzhangfei:addSkill(chenmu)
langzhangfei:addSkill(chenmuMod)
extension:insertRelatedSkills("chenmu", "#chenmuMod")
langzhangfei:addSkill(duanqiao)

shengui = sgs.CreateTriggerSkill {
	name = "shengui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:objectName() == use.from:objectName() and player:isAlive() and player:hasSkill(self:objectName()) then
				local list = use.nullified_list
				for _, p in sgs.qlist(use.to) do
					if p:isKongcheng() then return false end
					local dest = sgs.QVariant()
					dest:setValue(p)
					if player:askForSkillInvoke(self:objectName(), dest) then
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
				end
				use.nullified_list = list
				data:setValue(use)
			end
		end
		return false
	end,
}
shejiCard = sgs.CreateSkillCard {
	name = "shejiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		target:obtainCard(effect.card, false)
		local room = source:getRoom()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("sheji")
		room:useCard(sgs.CardUseStruct(slash, source, target))
		slash:deleteLater()
	end
}
shejiVS = sgs.CreateZeroCardViewAsSkill {
	name = "sheji",
	view_as = function(self, cards)
		local card = shejiCard:clone()
		card:addSubcards(sgs.Self:getHandcards())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sheji"
	end
}
sheji = sgs.CreateTriggerSkill {
	name = "sheji",
	events = { sgs.EventPhaseEnd },
	view_as_skill = shejiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:isKongcheng() then return false end
		if room:askForUseCard(player, "@@sheji", "@sheji-card") then
		end
		return false
	end
}
feijiang = sgs.CreateDistanceSkill {
	name = "feijiang$",
	correct_func = function(self, from, to)
		local distance = 0
		local others = from:getSiblings()
		for _, other in sgs.qlist(others) do
			if other:isAlive() then
				if other:getKingdom() == "qun" then
					distance = distance - 1
				end
			end
		end
		if from:hasLordSkill(self:objectName()) then
			return distance
		end
	end
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
	[":lalong"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张黑桃牌交给一名其他角色并摸一张牌，然后视为该角色对另一名由你指定的同时在你与该角色攻击范围内的角色使用一张【杀】。",
	["fuhei"] = "腹黑",
	[":fuhei"] = "<font color=\"blue\"><b>锁定技，</b></font>你的红桃牌均视为黑桃牌。",
	["renzha"] = "仁诈",
	[":renzha"] = "<font color=\"orange\"><b>主公技，</b></font>一名其他蜀势力角色回合开始时，其可以令你获得其区域内一张牌。",
	["@renzha-to"] = "请选择“仁诈”的目标角色",

	["suzhan"] = "速斩",
	[":suzhan"] = "<font color=\"blue\"><b>锁定技，</b></font>你与装备区没有牌的角色距离为1，你使用【杀】对装备区没有牌的角色造成的伤害+1。",
	["$suzhan1"] = "关羽在此，尔等受死！",
	["$suzhan2"] = "看尔乃插标卖首！",

	["shuiyan"] = "水淹",
	["$shuiyan"] = "全都去死吧﹗",
	["be_lost"] = "失去一点体力",
	["throw_equips"] = "弃置装备区内所有装备",
	[":shuiyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置三张不同花色的牌，令所有其他角色依次选择一项：弃置所有装备区的所有装备牌（至少一张），或失去一点体力。",
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
	[":feijiang"] = "<font color=\"orange\"><b>主公技，</b></font><font color=\"blue\"><b>锁定技，</b></font>你与其他角色的距离-X。（X为其他群雄角色的数量）",
}




langmateng = sgs.General(extension, "langmateng", "qun", 4)
langmachao = sgs.General(extension, "langmachao", "qun", 4)
langmadai = sgs.General(extension, "langmadai", "qun", 4)
langmaxiumatie = sgs.General(extension, "langmaxiumatie", "qun", 4)

tengxun = sgs.CreateTriggerSkill {
	name = "tengxun",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > player:getHandcardNum() then
					targets:append(p)
				end
			end

			if targets:isEmpty() then return false end
			room:setPlayerFlag(player, "LuaXDuanzhi_InTempMoving");
			local target = room:askForPlayerChosen(player, targets, self:objectName(), nil, true, true)
			if target then
				local dummy = sgs.Sanguosha:cloneCard("slash") --没办法了，暂时用你代替DummyCard吧……
				local card_ids = sgs.IntList()
				local original_places = sgs.PlaceList()
				for i = 1, 2, 1 do
					if not player:canDiscard(target, "h") then break end
					card_ids:append(room:askForCardChosen(player, target, "h", self:objectName()))
					original_places:append(room:getCardPlace(card_ids:at(i - 1)))
					dummy:addSubcard(card_ids:at(i - 1))
					target:addToPile("#tengxun", card_ids:at(i - 1), false)
				end
				if dummy:subcardsLength() > 0 then
					for i = 1, dummy:subcardsLength(), 1 do
						room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1),
							false)
					end
				end
				room:setPlayerFlag(player, "-LuaXDuanzhi_InTempMoving")
				if dummy:subcardsLength() > 0 then
					room:throwCard(dummy, target, player)
				end
				dummy:deleteLater()
			end
		end
		return false
	end
}
wolfchichengCard = sgs.CreateSkillCard {
	name = "wolfchichengCard",
	mute = true,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 3
	end,
	feasible = function(self, targets)
		return true
	end,
	about_to_use = function(self, room, cardUse)
		local use = cardUse
		if not use.to:contains(use.from) then
			use.to:append(use.from)
		end
		room:removePlayerMark(use.from, "@chicheng")
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("wolfchicheng")
		room:getThread():delay(500)
		local x = source:getLostHp()
		for _, p in ipairs(targets) do
			p:drawCards(x)
		end
	end
}
wolfchichengVS = sgs.CreateViewAsSkill {
	name = "wolfchicheng",
	view_as = function(self, cards)
		return wolfchichengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@chicheng") >= 1 and player:isWounded()
	end
}
wolfchicheng = sgs.CreateTriggerSkill {
	name = "wolfchicheng",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart },
	limit_mark = "@chicheng",
	view_as_skill = wolfchichengVS,
	on_trigger = function()
	end
}
langmateng:addSkill(tengxun)
langmateng:addSkill(wolfchicheng)
langmateng:addSkill("mashu")

xionglie = sgs.CreateTriggerSkill {
	name = "xionglie",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName()) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				judge.play_animation = true
				room:judge(judge)
				if (judge:isGood()) then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:distanceTo(p) == 1 then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					if not target:isKongcheng() then
						target:addToPile("xionglie_lie", target:handCards(), false)
						room:broadcastSkillInvoke(self:objectName())
					end
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
	end
}
langmachao:addSkill(xionglie)
langmachao:addSkill("mashu")

jieffan = sgs.CreateTriggerSkill {
	name = "jieffan",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p and p:inMyAttackRange(dying.who) then
				local card = room:askForCard(p, ".Trick", self:objectName(), data)
				if card then
					local killer = sgs.DamageStruct()
					killer.from = p
					room:killPlayer(dying.who, killer)
					return false
				end
			end
		end
	end
}
langmadai:addSkill(jieffan)
langmadai:addSkill("mashu")

tietiCard = sgs.CreateSkillCard {
	name = "tietiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select) <= 1
	end,
	on_use = function(self, room, source, targets)
		room:damage(sgs.DamageStruct("tieti", source, targets[1]))
	end
}
tieti = sgs.CreateViewAsSkill {
	name = "tieti",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected < 2 and to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = tietiCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:setSkillName("tieti")
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tietiCard")
	end
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
	[":wolfchicheng"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令最多三名角色各摸X张牌（X为你已损失的体力值）。",
	["xionglie"] = "雄烈",
	["$xionglie"] = "目标敌阵，全军突击！",
	[":xionglie"] = "准备阶段开始时，你可以进行一次判定，若结果不为红桃，你令一名距离为1的角色将所有手牌置于其武将牌上，结束阶段开始时移回手牌。",
	["jieffan"] = "截返",
	[":jieffan"] = "每当一名角色进入濒死状态时，若其在你攻击范围内，你可以弃置一张锦囊牌，视为你杀死该角色。",
	["tieti"] = "铁蹄",
	[":tieti"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置两张黑色牌，对一名距离为1的角色造成一点伤害。",
	["xionglie_lie"] = "雄烈",


}




return { extension }
