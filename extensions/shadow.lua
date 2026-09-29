module("extensions.shadow", package.seeall)
extension = sgs.Package("shadow")

y_liubei = sgs.General(extension, "y_liubei", "shu", 3)
y_mizhen = sgs.General(extension, "y_mizhen", "shu", 3, false)
y_ganmei = sgs.General(extension, "y_ganmei", "shu", 3, false)
y_jiangwei = sgs.General(extension, "y_jiangwei", "shu", 3)
y_mayunlu = sgs.General(extension, "y_mayunlu", "shu", 3, false)
--y_xushu = sgs.General(extension, "y_xushu", "shu", 3)
y_puyuan = sgs.General(extension, "y_puyuan", "shu", 3)
y_bulianshi = sgs.General(extension, "y_bulianshi", "wu", 3, false)
y_lvmeng = sgs.General(extension, "y_lvmeng", "wu", 4)
y_zhoutai = sgs.General(extension, "y_zhoutai", "wu", 4)
y_handang = sgs.General(extension, "y_handang", "wu", 4)
y_zhugejin = sgs.General(extension, "y_zhugejin", "wu", 3)
y_luxun = sgs.General(extension, "y_luxun", "wu", 3)
y_liubiao = sgs.General(extension, "y_liubiao", "qun", 3)
y_liru = sgs.General(extension, "y_liru", "qun", 3)
y_lvlingqi = sgs.General(extension, "y_lvlingqi", "qun", 3, false)
y_huangchengyan = sgs.General(extension, "y_huangchengyan", "qun", 3)
y_lukang = sgs.General(extension, "y_lukang", "wu", 3)
y_luji = sgs.General(extension, "y_luji", "wu", 3)
y_dongbai = sgs.General(extension, "y_dongbai", "qun", 3, false)
--y_liuxie = sgs.General(extension, "y_liuxie", "qun", 3)
y_zhouyu = sgs.General(extension, "y_zhouyu", "wu", 3)
y_caifuren = sgs.General(extension, "y_caifuren", "qun", 3, false)
--y_zhangsong = sgs.General(extension, "y_zhangsong", "shu", 3)
y_sunluyu = sgs.General(extension, "y_sunluyu", "wu", 3, false)
--y_guyong = sgs.General(extension, "y_guyong", "wu", 3)
--y_liufu = sgs.General(extension, "y_liufu", "wei", 3)
y_caojie = sgs.General(extension, "y_caojie", "qun", 3, false)
y_xushi = sgs.General(extension, "y_xushi", "wu", 3, false)
y_xinxianying = sgs.General(extension, "y_xinxianying", "wei", 3, false)


dofile "lua/sgs_ex.lua"

-- TriggerSkillV2 格式二：回傳所有可觸發的技能擁有者（供事件玩家非擁有者的技能使用）
local function y_v2_all_owners(skill, room, filter)
	local skills, owners = {}, {}
	for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
		if (not filter) or filter(p) then
			table.insert(skills, skill:objectName())
			table.insert(owners, p:objectName())
		end
	end
	if #skills == 0 then return false end
	return table.concat(skills, "|"), table.concat(owners, "|")
end

--影·刘备
y_rendecard = sgs.CreateSkillCard
	{ --仁德 （手牌数不小于2才可以仁德）
		name = "y_rendecard",
		target_fixed = false,
		will_throw = false,
		once = false,

		filter = function(self, targets, to_select, player)
			return #targets == 0 and to_select:getSeat() ~= player:getSeat()
		end,

		on_use = function(self, room, source, targets)
			source:addMark("rende", self:subcardsLength())
			--room:broadcastSkillInvoke("y_rende")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), "y_rende", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
			local x = source:getMark("rende")
			if x >= 2 and not source:hasFlag("recovered") then
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = source
				room:recover(source, recover)
				room:setPlayerFlag(source, "recovered")
				return true
			end
		end,
	}

y_rendevs = sgs.CreateViewAsSkillV2
	{
		name = "y_rende",
		n = 999,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and player:getHandcardNum() > 1
		end,

		can_select_card = function(skill, request, candidate)
			return candidate and not candidate:isEquipped()
				and request:getSelectedCardIds():length() < 999
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() > 0
		end,

		create_card = function(skill, request)
			local acard = y_rendecard:clone()
			for _, id in sgs.qlist(request:getSelectedCardIds()) do
				acard:addSubcard(id)
			end
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_rende = sgs.CreateTriggerSkillV2
	{
		name = "y_rende",
		view_as_skill = y_rendevs,
		events = { sgs.EventPhaseStart },

		on_record = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart and ctx.owner
				and player:objectName() == ctx.owner:objectName() then
				room:setPlayerMark(player, "rende", 0)
			end
		end,
	}


y_lianying = sgs.CreateTriggerSkillV2
	{ --连营
		name = "y_lianying",
		events = { sgs.CardsMoveOneTime },
		frequency = sgs.Skill_Compulsory,

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if player:isKongcheng() and move.from_places:contains(sgs.Player_PlaceHand) then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke("lianying")
			player:drawCards(1)
			return false
		end,
	}

--姜维
y_tiaoxincard = sgs.CreateSkillCard
	{ --挑衅
		name = "y_tiaoxincard",
		once = true,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			return to_select:getAttackRange() >= to_select:distanceTo(player) and not to_select:isNude()
		end,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			if not room:askForUseSlashTo(targets[1], source, "@txslash") then
				if not targets[1]:isNude() then
					local cardid = room:askForCardChosen(source, targets[1], "he", self:objectName())
					room:throwCard(cardid, targets[1])
				end
			end
		end,
	}

y_tiaoxin = sgs.CreateViewAsSkillV2 {
	name = "y_tiaoxin",
	n = 0,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#y_tiaoxincard")
	end,

	create_card = function(skill, request)
		local card = y_tiaoxincard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

y_zhiji = sgs.CreateTriggerSkillV2
	{ --志继
		name = "y_zhiji",
		events = { sgs.Damaged },

		can_trigger = function(skill, event, room, player, data)
			return skill:objectName()
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_pay = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke(skill:objectName())
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			room:askForGuanxing(player, room:getNCards(5), sgs.Room_GuanxingBothSides)
			player:drawCards(1)
			return false
		end,
	}


--糜贞
y_yongjue = sgs.CreateTriggerSkillV2
	{ --勇决
		name = "y_yongjue",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.TargetConfirming },

		can_trigger = function(skill, event, room, player, data)
			if not (player:getHandcardNum() < player:getHp()) then return false end
			local use = data:toCardUse()
			if not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
			return y_v2_all_owners(skill, room)
		end,

		on_cost = function(skill, event, room, player, ctx)
			local ai_data = sgs.QVariant()
			ai_data:setValue(ctx.invoker)
			return room:askForSkillInvoke(player, skill:objectName(), ai_data)
		end,

		on_pay = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke(skill:objectName())
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			--player 為技能擁有者（糜貞），ctx.invoker 為成為目標的角色
			local use = ctx.original_data:toCardUse()
			player:drawCards(1)
			if ctx.invoker:getSeat() ~= player:getSeat() then
				if not room:askForSkillInvoke(ctx.invoker, "y_yjtargetmove", ctx.original_data) then return false end
				local new_targets = sgs.SPlayerList()
				for _, t in sgs.qlist(use.to) do
					if t:getSeat() == ctx.invoker:getSeat() then
						new_targets:append(player)
					else
						new_targets:append(t)
					end
				end
				use.to = new_targets
				ctx.original_data:setValue(use)
				return true
			end
			return false
		end
	}

y_cunsi = sgs.CreateTriggerSkillV2
	{ --存嗣	
		name = "y_cunsi",
		events = { sgs.Dying },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			local dy = data:toDying()
			if dy.who:objectName() == player:objectName() then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName())
			local idlist = sgs.IntList()
			local cardsA, cardsB
			cardsA = player:getHandcards()
			cardsB = player:getEquips()
			for _, c in sgs.qlist(cardsA) do
				idlist:append(c:getId())
			end
			for _, e in sgs.qlist(cardsB) do
				idlist:append(e:getId())
			end
			local move = sgs.CardsMoveStruct()
			move.card_ids = idlist
			move.to = target
			move.to_place = sgs.Player_PlaceHand
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_GIVE
			room:moveCardsAtomic(move, false)
			room:handleAcquireDetachSkills(target, "y_yongjue")
			room:killPlayer(player)
			return true
		end
	}

--甘梅
y_shushen = sgs.CreateTriggerSkillV2
	{ --淑慎
		name = "y_shushen",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.EventPhaseChanging },

		can_trigger = function(skill, event, room, player, data)
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			return skill:objectName()
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local targets = room:getOtherPlayers(player)
			local target = room:askForPlayerChosen(player, targets, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			local choice = room:askForChoice(target, skill:objectName(), "Idraw+Udraw")
			if choice == "Idraw" then
				target:drawCards(1)
			else
				player:drawCards(1)
			end
			return false
		end,
	}

y_shenzhivs = sgs.CreateViewAsSkillV2
	{
		name = "y_shenzhi",
		n = 0,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			if not player then return false end
			local x = player:getHp()
			local y = player:getHandcardNum()
			if x < 0 then x = 0 end
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				return player:isWounded() and y > x
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				if x < y then
					return string.find(request:getPattern(), "peach") ~= nil
				end
			end
			return false
		end,

		create_card = function(skill, request)
			local card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
			card:setSkillName(skill:objectName())
			return card
		end,
	}

y_shenzhi = sgs.CreateTriggerSkillV2 {
	name = "y_shenzhi",
	view_as_skill = y_shenzhivs,
	events = { sgs.CardUsed },

	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		local card = use.card
		if card and table.contains(card:getSkillNames(), "y_shenzhi") then
			return skill:objectName()
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		local x = player:getHp()
		local y = player:getHandcardNum()
		if x < 0 then x = 0 end
		room:askForDiscard(player, skill:objectName(), y - x, y - x, false, false)
		return false
	end
}

--马云禄
local function y_rongzhuang_target_name(request)
	if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		return "slash"
	end
	local pattern = request:getPattern()
	if pattern == "slash" or pattern == "jink" then return pattern end
	return nil
end

local function y_rongzhuang_has_equip_suit(player, suit)
	if not player then return false end
	for _, acard in sgs.qlist(player:getEquips()) do
		if acard:getSuit() == suit then return true end
	end
	return false
end

y_rongzhuang = sgs.CreateViewAsSkillV2
	{ --戎装
		name = "y_rongzhuang",
		n = 1,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			if not player then return false end
			if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				return player:canSlashWithoutCrossbow() or
					(player:getWeapon() and player:getWeapon():getClassName() == "Crossbow")
			end
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				local pattern = request:getPattern()
				return pattern == "slash" or pattern == "jink"
			end
			return false
		end,

		can_select_card = function(skill, request, candidate)
			local name = y_rongzhuang_target_name(request)
			if not name or not candidate or candidate:isEquipped() then return false end
			local player = request:getInitiator()
			if name == "slash" then
				return y_rongzhuang_has_equip_suit(player, candidate:getSuit())
			elseif name == "jink" then
				return not y_rongzhuang_has_equip_suit(player, candidate:getSuit())
			end
			return false
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() == 1
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() ~= 1 then return nil end
			local name = y_rongzhuang_target_name(request)
			if not name then return nil end
			local sub = sgs.Sanguosha:getCard(ids:at(0))
			local card = sgs.Sanguosha:cloneCard(name, sub:getSuit(), sub:getNumber())
			card:addSubcard(sub)
			card:setSkillName(skill:objectName())
			return card
		end,
	}

y_chongqi = sgs.CreateTriggerSkillV2
	{ --冲骑
		name = "y_chongqi",
		events = { sgs.TargetConfirmed },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			local use = data:toCardUse()
			local card = use.card
			if not card or not card:isKindOf("Slash") then return false end
			if not use.from or use.from:getSeat() ~= player:getSeat() then return false end
			for _, p in sgs.qlist(use.to) do
				for _, e in sgs.qlist(p:getEquips()) do
					if e:getSuit() == card:getSuit() and player:canDiscard(p, "he") then
						return skill:objectName()
					end
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local use = ctx.original_data:toCardUse()
			local card = use.card
			for _, p in sgs.qlist(use.to) do
				local can_cq = false
				for _, e in sgs.qlist(p:getEquips()) do
					if e:getSuit() == card:getSuit() then
						can_cq = true
						break
					end
				end
				if can_cq == true and player:canDiscard(p, "he") then
					local ai_data = sgs.QVariant()
					ai_data:setValue(p)
					if not player:askForSkillInvoke(skill:objectName(), ai_data) then return false end
					local card = room:askForCardChosen(player, p, "he", skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:throwCard(card, p, player)
				end
			end
			return false
		end
	}

--吕蒙
y_baiyi = sgs.CreateTriggerSkillV2
	{
		name = "y_baiyi",
		events = { sgs.CardEffected },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			local effect = data:toCardEffect()
			local slash = effect.card
			if not (slash and slash:isKindOf("Slash")) then return false end
			--player 為成為【殺】目標的角色（effect.to）；擁有者須在其攻擊範圍內或是其本人
			return y_v2_all_owners(skill, room, function(lm)
				return lm:inMyAttackRange(player) or player:objectName() == lm:objectName()
			end)
		end,

		on_cost = function(skill, event, room, player, ctx)
			local effect = ctx.original_data:toCardEffect()
			if effect.card and effect.card:isBlack() then
				if effect.to:getSeat() ~= player:getSeat() then return false end
				return player:askForSkillInvoke("y_baiyi", ctx.original_data)
			end
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			return player:askForSkillInvoke("y_baiyier", ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local effect = ctx.original_data:toCardEffect()
			if effect.card and effect.card:isBlack() then
				player:drawCards(1)
				room:broadcastSkillInvoke(skill:objectName(), 1)
				room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
			else
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:canDiscard(p, "hej") then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, skill:objectName())
				local cardid = room:askForCardChosen(player, target, "hej", skill:objectName())
				room:broadcastSkillInvoke("y_baiyi", 2)
				room:throwCard(cardid, target, player)
			end
			return false
		end
	}

--周泰
y_yuanjiu = sgs.CreateTriggerSkillV2
	{ --援救
		name = "y_yuanjiu",
		events = { sgs.AskForPeaches },

		can_trigger = function(skill, event, room, player, data)
			return skill:objectName()
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local x = player:getPile("y_yuanjiuPile"):length()
			local cards = player:getPile("y_yuanjiuPile")
			local can_peach = true
			if x > 0 then
				for _, acard in sgs.qlist(cards) do
					for _, bcard in sgs.qlist(cards) do
						if acard ~= bcard and sgs.Sanguosha:getCard(acard):getNumber() == sgs.Sanguosha:getCard(bcard):getNumber() then
							can_peach = false
							break
						end
					end
					if can_peach == false then break end
				end
			end
			if can_peach == true then
				room:broadcastSkillInvoke(skill:objectName())
				local hp = player:getHp()
				if hp < 0 then hp = 0 end

				player:drawCards(hp + 2)
				for i = 1, hp + 2, 1 do
					local y = player:getPile("y_yuanjiuPile"):length()
					local pcards = player:getPile("y_yuanjiuPile")
					if y > 0 then
						room:fillAG(pcards, player)
					end
					local cardid = room:askForCardChosen(player, player, "h", skill:objectName())
					player:addToPile("y_yuanjiuPile", cardid)
					room:clearAG()
					if player:isKongcheng() then break end
				end

				local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
				peach:setSkillName(skill:objectName())
				peach:deleteLater()
				local use = sgs.CardUseStruct()
				use.card = peach
				use.from = player
				local dy = ctx.original_data:toDying()
				use.to:append(dy.who)
				room:useCard(use)
			elseif can_peach == false then
				room:fillAG(cards, player)
				local card = room:askForAG(player, cards, false, skill:objectName())
				room:obtainCard(player, card)
				room:clearAG(player)
			end
			return false
		end,
	}

--韩当
--jfskills = {"buqu","tuntian","quanji"}
--jfpiles = {"buqu","field","power"}

y_jiefan = sgs.CreateViewAsSkillV2
	{ --解烦
		name = "y_jiefan",
		n = 0,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("#y_jiefancard")
		end,

		create_card = function(skill, request)
			local acard = y_jiefancard:clone()
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_jiefancard = sgs.CreateSkillCard
	{ --
		name = "y_jiefancard",
		target_fixed = false,
		will_throw = false,
		once = true,

		filter = function(self, targets, to_select, player)
			return #targets == 0 and player:canDiscard(to_select, "he")
		end,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			--room:broadcastSkillInvoke("y_jiefan")
			local choice = "He"
			--[[local tarPile = nil
		for i=1, 99, 1 do
	        if targets[1]:hasSkill(jfskills[i]) and targets[1]:getPile(jfpiles[i]):length()>0 then
		        tarPile = jfpiles[i] break
			end
		end
		if tarPile~=nil then
		    choice = room:askForChoice(source,"y_jiefan","Pile+Hej")
		elseif targets[1]:isAllNude() then return nil
		end
		if choice=="Pile" then
			local cards=targets[1]:getPile(tarPile)
            room:fillAG(cards,source)
		    local cardid =room:askForAG(source,cards,false,"y_jiefan")
		    room:throwCard(cardid,targets[1])
		    room:clearAG(source)
			choice="draw"
		elseif choice=="Hej" then]]
			local cardid = room:askForCardChosen(source, targets[1], "he", self:objectName())
			room:throwCard(cardid, targets[1])
			choice = "draw"
			--end
			if choice == room:askForChoice(targets[1], "y_jiefan", "draw+No") then
				targets[1]:drawCards(1)
			end
		end,
	}

--步练师
y_anxu = sgs.CreateViewAsSkillV2
	{ --安恤
		name = "y_anxu",
		n = 0,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("#y_anxucard")
		end,

		create_card = function(skill, request)
			local acard = y_anxucard:clone()
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_anxucard = sgs.CreateSkillCard
	{
		name = "y_anxucard",
		target_fixed = false,
		--will_throw = true,

		filter = function(self, targets, to_select, player)
			return #targets == 0
		end,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			targets[1]:drawCards(1)
			local dest = targets[1]
			local cardid = room:askForCardChosen(targets[1], targets[1], "he", "y_anxu")
			room:throwCard(cardid, targets[1], source)
			if not sgs.Sanguosha:getCard(cardid):isKindOf("BasicCard") then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if dest:canDiscard(p, "hej") then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(dest, targets, "y_anxu")
				local id = room:askForCardChosen(dest, target, "hej", "y_anxu", false, sgs.Card_MethodDiscard)
				room:throwCard(id, target, dest)
			end
		end
	}

y_chongguan = sgs.CreateTriggerSkillV2
	{ --宠冠
		name = "y_chongguan",
		events = { sgs.CardsMoveOneTime },
		priority = 5,
		frequency = sgs.Skill_Compulsory,

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if not move.from or not move.from:isAlive() then return false end
			if not move.from_places:contains(sgs.Player_PlaceEquip) then return false end
			return skill:objectName()
		end,

		on_effect = function(skill, event, room, player, ctx)
			for _, selfplayer in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				room:broadcastSkillInvoke(skill:objectName())
				local log = sgs.LogMessage()
				log.type = "#y_chongguan"
				log.from = selfplayer
				room:sendLog(log)

				selfplayer:drawCards(1)
			end
			return false
		end,
	}

--诸葛瑾
y_hongyuancard = sgs.CreateSkillCard
	{ --弘援
		name = "y_hongyuancard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			return player:inMyAttackRange(to_select) or player:getSeat() == to_select:getSeat()
		end,

		on_use = function(self, room, source, targets)
			--room:broadcastSkillInvoke("y_hongyuan")
			for i = 1, #targets, 1 do
				targets[i]:drawCards(1)
			end
		end,
	}

y_hongyuanvs = sgs.CreateViewAsSkillV2
	{
		name = "y_hongyuan",
		n = 0,

		can_activate = function(skill, request)
			return request:getPattern() == "@@y_hongyuan"
		end,

		create_card = function(skill, request)
			local acard = y_hongyuancard:clone()
			acard:setSkillName("y_hongyuan")
			return acard
		end,
	}

y_hongyuan = sgs.CreateTriggerSkillV2
	{
		name = "y_hongyuan",
		view_as_skill = y_hongyuanvs,
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			local move = data:toMoveOneTime()
			if move.from == nil or move.from:objectName() ~= player:objectName() then return false end
			local reason = move.reason.m_reason
			if reason == sgs.CardMoveReason_S_REASON_USE or reason == sgs.CardMoveReason_S_REASON_RESPONSE
				or reason == sgs.CardMoveReason_S_REASON_LETUSE or reason == sgs.CardMoveReason_S_REASON_DISCARD
				or reason == sgs.CardMoveReason_S_REASON_THROW or reason == sgs.CardMoveReason_S_REASON_DISMANTLE then
				if move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand) then
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isRed() then
							return skill:objectName()
						end
					end
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isRed() then
					room:askForUseCard(player, "@@y_hongyuan", "@y_hongyuan")
				end
			end
			return false
		end,
	}

y_huanshi = sgs.CreateViewAsSkillV2
	{ --缓释
		name = "y_huanshi",
		n = 0,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("#y_huanshicard")
		end,

		create_card = function(skill, request)
			local acard = y_huanshicard:clone()
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_huanshicard = sgs.CreateSkillCard
	{
		name = "y_huanshicard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			return #targets < 2 and to_select:getSeat() ~= player:getSeat() and not to_select:isKongcheng()
		end,

		feasible = function(self, targets, player)
			return #targets == 2
		end,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			--room:broadcastSkillInvoke("y_huanshi")
			local card
			for i = 1, 2, 1 do
				card = room:askForCardChosen(targets[i], targets[i], "h", "y_huanshi")
				room:moveCardTo(sgs.Sanguosha:getCard(card), source, sgs.Player_PlaceHand, false)
			end
			for j = 1, 2, 1 do
				card = room:askForCardChosen(source, source, "h", "y_huanshi")
				room:moveCardTo(sgs.Sanguosha:getCard(card), targets[j], sgs.Player_PlaceHand, false)
			end
		end
	}

--刘表
y_yangzhengcard = sgs.CreateSkillCard
	{ --养政
		name = "y_yangzhengcard",
		target_fixed = false,
		will_throw = false,
		once = false,

		filter = function(self, targets, to_select, player)
			return #targets == 0 and to_select:objectName() ~= player:objectName()
		end,

		on_use = function(self, room, source, targets)
			for i = 1, self:subcardsLength(), 1 do
				source:addMark("y_yangzheng")
			end
			--room:broadcastSkillInvoke("y_yangzheng")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), "y_yangzheng", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
			local x = source:getMark("y_yangzheng")
			local y = source:getHp()
			if x >= y and source:getMark("y_yzRec") ~= 1 then
				local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = source
				room:recover(source, recover)
				source:setMark("y_yzRec", 1)
			end
			if source:getHandcardNum() ~= 0 then
				room:askForUseCard(source, "@@y_yangzheng", "@y_yangzheng")
			end
		end,
	}

y_yangzhengvs = sgs.CreateViewAsSkillV2
	{
		name = "y_yangzheng",
		n = 999,

		can_activate = function(skill, request)
			return request:getPattern() == "@@y_yangzheng"
		end,

		can_select_card = function(skill, request, candidate)
			return candidate and not candidate:isEquipped()
				and request:getSelectedCardIds():length() < 999
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() > 0
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() == 0 then return nil end
			local acard = y_yangzhengcard:clone()
			for i = 0, ids:length() - 1, 1 do
				acard:addSubcard(ids:at(i))
			end
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_yangzheng = sgs.CreateTriggerSkillV2
	{
		name = "y_yangzheng",
		view_as_skill = y_yangzhengvs,
		events = { sgs.Damaged },

		can_trigger = function(skill, event, room, player, data)
			if player:getHandcardNum() < 1 then return false end
			return skill:objectName()
		end,

		on_effect = function(skill, event, room, player, ctx)
			player:setMark("y_yangzheng", 0)
			player:setMark("y_yzRec", 0)
			--if not player:askForSkillInvoke("y_yangzheng",data) then return false end
			room:askForUseCard(player, "@@y_yangzheng", "@y_yangzheng")
			return false
		end
	}

y_zishou = sgs.CreateTriggerSkillV2
	{ --自守
		name = "y_zishou",
		events = { sgs.EventPhaseStart, sgs.DrawNCards },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.DrawNCards then
				if player:getPhase() ~= sgs.Player_Draw then return false end
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				if draw.num < 1 then return false end
				return skill:objectName()
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Finish and player:hasFlag("y_zs") then
					return skill:objectName()
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			if event == sgs.DrawNCards then
				return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
			end
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.DrawNCards then
				local draw = ctx.original_data:toDraw()
				room:broadcastSkillInvoke(skill:objectName())
				draw.num = draw.num - 1
				player:setFlags("y_zs")
				ctx.original_data:setValue(draw)
				room:addPlayerMark(player, "&" .. skill:objectName() .. "-Clear")
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Finish and player:hasFlag("y_zs") then
					player:setFlags("-y_zs")
					local x = player:getMaxHp()
					local y = player:getHandcardNum()
					if x <= y then return false end
					room:broadcastSkillInvoke(skill:objectName())
					player:drawCards((x - y))
				end
			end
			return false
		end,
	}

y_zhensha = sgs.CreateTriggerSkillV2
	{ --鸩杀
		name = "y_zhensha",
		events = { sgs.CardUsed, sgs.CardOffset },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.CardUsed then
				local card = data:toCardUse().card
				if not (card and card:isKindOf("Peach")) then return false end
				return y_v2_all_owners(skill, room, function(splayer)
					return player:objectName() ~= splayer:objectName()
				end)
			elseif event == sgs.CardOffset then
				local effect = data:toCardEffect()
				if not effect.to then return false end
				return y_v2_all_owners(skill, room, function(splayer)
					return effect.to:objectName() ~= splayer:objectName()
				end)
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			local ai_data = sgs.QVariant()
			if event == sgs.CardUsed then
				ai_data:setValue(ctx.invoker)
			else
				local effect = ctx.original_data:toCardEffect()
				ai_data:setValue(effect.to)
			end
			return player:askForSkillInvoke(skill:objectName(), ai_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local ai_data = sgs.QVariant()
			local pattern
			if event == sgs.CardUsed then
				ai_data:setValue(ctx.invoker)
				pattern = "peach"
			else
				local effect = ctx.original_data:toCardEffect()
				ai_data:setValue(effect.to)
				pattern = "jink"
			end
			if room:askForCard(player, pattern, skill:objectName(), ai_data, sgs.Card_MethodResponse, nil, false, skill:objectName(), false) ~= nil then
				room:broadcastSkillInvoke(skill:objectName())
				return true
			end
			return false
		end
	}

y_shipo = sgs.CreateTriggerSkillV2
	{ --识破
		name = "y_shipo",
		events = { sgs.CardAsked, sgs.AskForPeaches },
		priority = 4,
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			local str
			if event == sgs.CardAsked then
				str = data:toStringList()[1]
			elseif event == sgs.AskForPeaches then
				local dy = data:toDying()
				if dy.who:getSeat() == player:getSeat() then
					str = "peach+analeptic"
				else
					str = "peach"
				end
			end
			if not str then return false end
			local targets = room:getOtherPlayers(player)
			local players = room:getOtherPlayers(player)
			for _, p in sgs.qlist(players) do
				if p:getHandcardNum() < player:getHandcardNum() or p:isKongcheng() then
					targets:removeOne(p)
				end
			end
			if targets:isEmpty() then return false end
			return skill:objectName()
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local str
			if event == sgs.CardAsked then
				str = ctx.original_data:toStringList()[1]
			elseif event == sgs.AskForPeaches then
				local dy = ctx.original_data:toDying()
				if dy.who:getSeat() == player:getSeat() then
					str = "peach+analeptic"
				else
					str = "peach"
				end
			end
			if not str then return false end
			local targets = room:getOtherPlayers(player)
			local players = room:getOtherPlayers(player)
			for _, p in sgs.qlist(players) do
				if p:getHandcardNum() < player:getHandcardNum() or p:isKongcheng() then
					targets:removeOne(p)
				end
			end
			if targets:isEmpty() then return false end
			room:setTag("y_shipo", ctx.original_data)
			local target = room:askForPlayerChosen(player, targets, skill:objectName())
			local card_id = room:askForCardChosen(player, target, "h", skill:objectName())
			room:removeTag("y_shipo")
			local card = sgs.Sanguosha:getCard(card_id)
			room:showCard(target, card_id)
			if str == card:objectName() or (str == "slash" and card:isKindOf("Slash")) or (str == "peach+analeptic" and (card:isKindOf("Peach") or card:isKindOf("Analeptic"))) then
				room:broadcastSkillInvoke(skill:objectName())
				room:obtainCard(player, card)
			end
			return false
		end
	}

--陆逊
y_fenying = sgs.CreateViewAsSkillV2
	{ --焚营
		name = "y_fenying",
		n = 999,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:isNude()
		end,

		can_select_card = function(skill, request, candidate)
			return candidate ~= nil
				and request:getSelectedCardIds():length() < 999
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() > 0
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() < 1 then return nil end
			local acard = y_fenyingcard:clone()
			for i = 0, ids:length() - 1, 1 do
				acard:addSubcard(ids:at(i))
			end
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_fenyingcard = sgs.CreateSkillCard
	{
		name = "y_fenyingcard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			local x = self:subcardsLength()
			if #targets == 0 then
				return to_select:getHandcardNum() == x and to_select:getSeat() ~= player:getSeat() and
					player:canPindian(to_select)
			end
		end,

		on_use = function(self, room, source, targets)
			local room = source:getRoom()
			if source:canPindian(targets[1]) then
				if room:askForSkillInvoke(source, "y_fenying") then
					if source:pindian(targets[1], "y_fenying") then
						--room:broadcastSkillInvoke("y_fenying")
						local damage = sgs.DamageStruct()
						damage.card = nil
						damage.damage = 1
						damage.from = source
						damage.to = targets[1]
						damage.nature = sgs.DamageStruct_Fire
						room:damage(damage)
					end
				end
			end
		end
	}

y_dushi = sgs.CreateTriggerSkillV2
	{ --度势
		name = "y_dushi",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.CardEffected },

		can_trigger = function(skill, event, room, player, data)
			local ef = data:toCardEffect()
			if not ef.card or not (ef.card:isNDTrick() or ef.card:isKindOf("BasicCard")) then return false end
			if player:getHandcardNum() < player:getHp() then
				return skill:objectName()
			elseif player:getHandcardNum() > player:getHp() then
				local targets = room:getAlivePlayers()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not player:canDiscard(p, "hej") then
						targets:removeOne(p)
					end
				end
				if not targets:isEmpty() then return skill:objectName() end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			if player:getHandcardNum() < player:getHp() then
				room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			elseif player:getHandcardNum() > player:getHp() then
				local targets = room:getAlivePlayers()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not player:canDiscard(p, "hej") then
						targets:removeOne(p)
					end
				end
				if targets:isEmpty() then return false end
				room:broadcastSkillInvoke(skill:objectName())
				local target = room:askForPlayerChosen(player, targets, skill:objectName())
				local card = room:askForCardChosen(player, target, "hej", skill:objectName())
				room:throwCard(card, target, player)
			end
			return false
		end,
	}

--吕玲绮
y_wujicard = sgs.CreateSkillCard
	{ --舞戟
		name = "y_wujicard",
		target_fixed = true,
		will_throw = true,
		once = true,

		on_use = function(self, room, source, targets)
			room:broadcastSkillInvoke("y_wuji", 3)
			local choices
			local flags = { "addtar", "addjink", "addrange" }
			for i = 1, 3, 1 do
				if not source:hasFlag(flags[i]) then
					if choices ~= nil then
						choices = choices .. "+" .. flags[i]
					else
						choices = flags[i]
					end
				end
			end
			local choice = room:askForChoice(source, self:objectName(), choices)
			room:setPlayerMark(source, choice, 1)
			room:setPlayerMark(source, "&y_wuji+:+" .. choice .. "+-Clear", 1)

			room:setPlayerFlag(source, choice)
			local log = sgs.LogMessage()
			log.type = "#" .. choice
			log.from = source
			log.arg = "y_wuji"
			room:sendLog(log)
		end,
	}

y_wujivs = sgs.CreateViewAsSkillV2
	{
		name = "y_wuji",
		n = 1,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not (player:hasFlag("addjink") and player:hasFlag("addtar") and player:hasFlag("addrange"))
		end,

		can_select_card = function(skill, request, candidate)
			return candidate ~= nil
				and request:getSelectedCardIds():length() < 1
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() == 1
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() ~= 1 then return nil end
			local acard = y_wujicard:clone()
			acard:addSubcard(ids:at(0))
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_wuji = sgs.CreateTriggerSkillV2
	{
		name = "y_wuji",
		view_as_skill = y_wujivs,
		events = { sgs.CardUsed, sgs.TargetSpecified },

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				local card = use.card
				if not card or not card:isKindOf("Slash") then return false end
				if player:hasFlag("addtar") then
					return skill:objectName()
				end
			elseif event == sgs.TargetSpecified then
				local use = data:toCardUse()
				if not use.from or (player:objectName() ~= use.from:objectName()) or (not use.card or not use.card:isKindOf("Slash")) then return false end
				if player:hasFlag("addjink") then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.CardUsed then
				room:broadcastSkillInvoke(skill:objectName(), 1)
			elseif event == sgs.TargetSpecified then
				local use = ctx.original_data:toCardUse()
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
				local index = 1
				for _, p in sgs.qlist(use.to) do
					jink_table[index] = jink_table[index] + 1
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
			return false
		end
	}

y_wujitar = sgs.CreateTargetModSkillV2 {
	name = "#y_wujitar",
	pattern = "Slash",

	correct_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not player then return nil end
		local modType = ctx:getModType()
		if modType == sgs.TargetModSkill_ExtraTarget then
			if player:hasSkill("y_wuji") and player:hasFlag("addtar") then
				return 1
			end
		elseif modType == sgs.TargetModSkill_DistanceLimit then
			if player:hasSkill("y_wuji") and player:hasFlag("addrange") then
				return 1
			end
		end
		return nil
	end,
}

y_laoyue = sgs.CreateTriggerSkillV2
	{ --捞月
		name = "y_laoyue",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			local reason = move.reason.m_reason
			if reason ~= sgs.CardMoveReason_S_REASON_USE and reason ~= sgs.CardMoveReason_S_REASON_LETUSE then
				return false
			end
			for _, llq in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if move.from and move.from:getSeat() == llq:getSeat() then continue end
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("Jink") and room:getCardPlace(id) == sgs.Player_DiscardPile then
						return skill:objectName()
					end
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, llq in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if move.from and move.from:getSeat() == llq:getSeat() then continue end
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("Jink") and room:getCardPlace(id) == sgs.Player_DiscardPile then
						if player:askForSkillInvoke(skill:objectName(), ctx.original_data) then
							room:broadcastSkillInvoke(skill:objectName())
							room:obtainCard(llq, id)
						end
					end
				end
			end
			return false
		end,
	}

--蒲元
y_shenzhucard = sgs.CreateSkillCard
	{ --神铸
		name = "y_shenzhucard",
		target_fixed = true,
		will_throw = true,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			local cardsid = room:getDiscardPile()
			--local equips = sgs.IntList()
			local eq = sgs.IntList()
			--local slash = sgs.IntList()
			for _, eid in sgs.qlist(cardsid) do
				local ecard = sgs.Sanguosha:getCard(eid)
				if ecard:isKindOf("EquipCard") then
					--equips:append(eid)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if (ecard:isKindOf("Weapon") and not p:getWeapon()) or (ecard:isKindOf("Armor") and not p:getArmor())
							or (ecard:isKindOf("DefensiveHorse") and not p:getDefensiveHorse())
							or (ecard:isKindOf("OffensiveHorse") and not p:getOffensiveHorse()) then
							p:setMark("y_shenzhu", 1)
							if not eq:contains(eid) then
								eq:append(eid)
							end
						end
					end
				elseif ecard:isKindOf("Slash") then
					eq:append(eid)
				end
			end
			if eq:isEmpty() then return end
			local sz = true
			--if not room:askForSkillInvoke(source,"y_shenzhu") then sz=false end
			if sz == true then
				room:fillAG(eq, source)
				local ep = room:askForAG(source, eq, false, "y_shenzhu")
				local card = sgs.Sanguosha:getCard(ep)
				room:clearAG(source)
				if card:isKindOf("Slash") then
					source:obtainCard(card)
				else
					local players = sgs.SPlayerList()
					local i = card:getRealCard():toEquipCard():location()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasEquipArea(i) and not p:getEquip(i) then
							players:append(p)
						end
					end
					if players:isEmpty() then return end
					local target = room:askForPlayerChosen(source, players, "y_shenzhu")
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "y_shenzhu",
						"")
					room:moveCardTo(card, source, target, sgs.Player_PlaceEquip, reason)
				end
			end
		end,
	}

y_shenzhu = sgs.CreateViewAsSkillV2 {
	name = "y_shenzhu",
	n = 1,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if not player:hasUsed("#y_shenzhucard") then
			for _, h in sgs.qlist(player:getHandcards()) do
				if h:isKindOf("Slash") then return true end
			end
		end
		return false
	end,

	can_select_card = function(skill, request, candidate)
		return candidate and not candidate:isEquipped() and candidate:isKindOf("Slash")
			and request:getSelectedCardIds():length() < 1
	end,

	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,

	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = y_shenzhucard:clone()
		card:addSubcard(ids:at(0))
		card:setSkillName(skill:objectName())
		return card
	end,
}

y_bailian = sgs.CreateTriggerSkillV2
	{ --百炼
		name = "y_bailian",
		events = { sgs.CardAsked },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			local str = data:toStringList()[1]
			if str ~= "slash" and str ~= "jink" then return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, card in sgs.qlist(p:getEquips()) do
					if (card:isBlack() and str == "slash") or (card:isRed() and str == "jink") then
						return skill:objectName()
					end
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local str = ctx.original_data:toStringList()[1]
			if str == "slash" or str == "jink" then
				local plist = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					for _, card in sgs.qlist(p:getEquips()) do
						if (card:isBlack() and str == "slash") or (card:isRed() and str == "jink") then
							plist:append(p)
							break
						end
					end
				end
				if plist:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, plist, skill:objectName())
				local ids = sgs.IntList()
				for _, e in sgs.qlist(target:getEquips()) do
					if (e:isBlack() and str == "slash") or (e:isRed() and str == "jink") then
						ids:append(e:getId())
					end
				end
				local js
				room:fillAG(ids, player)
				local card_id = room:askForAG(player, ids, true, skill:objectName())
				js = sgs.Sanguosha:getCard(card_id)
				room:clearAG(player)
				local jinkslash = sgs.Sanguosha:cloneCard(str, js:getSuit(), js:getNumber())
				jinkslash:addSubcard(js)
				jinkslash:setSkillName(skill:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, player:objectName(),
					skill:objectName(), "")
				room:moveCardTo(jinkslash, nil, sgs.Player_PlaceTable, reason, true)
				room:provide(jinkslash)
				target:drawCards(2)
				return true
			end
			return false
		end,
	}

--黄承彦
y_caipei = sgs.CreateTriggerSkillV2
	{ --才配
		name = "y_caipei",
		events = { sgs.CardUsed },
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			local use = data:toCardUse()
			if not use.card or not use.card:isNDTrick() then return false end
			--player 為使用錦囊者；擁有者須可棄牌，且使用者為女性或擁有者本人
			return y_v2_all_owners(skill, room, function(hcy)
				return hcy:canDiscard(hcy, "he")
					and (player:isFemale() or player:objectName() == hcy:objectName())
			end)
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local tar = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			tar:drawCards(1)
			if not player:isKongcheng() then
				room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
			end
			return false
		end,
	}

y_kongzhen = sgs.CreateTriggerSkillV2
	{ --空阵
		name = "y_kongzhen",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.CardAsked },

		can_trigger = function(skill, event, room, player, data)
			if not player:isKongcheng() then return false end
			local pattern = data:toStringList()[1]
			if pattern ~= "jink" and pattern ~= "slash" then return false end
			return y_v2_all_owners(skill, room)
		end,

		on_cost = function(skill, event, room, player, ctx)
			local ai_data = sgs.QVariant()
			ai_data:setValue(ctx.invoker)
			return player:askForSkillInvoke(skill:objectName(), ai_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local pattern = ctx.original_data:toStringList()[1]
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red|.|."
			judge.good = true
			judge.reason = skill:objectName()
			judge.who = ctx.invoker
			judge.play_animation = true
			room:setEmotion(ctx.invoker, "armor/EightDiagram")
			room:judge(judge)
			if judge:isGood() then
				local js = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
				js:setSkillName(skill:objectName())
				js:deleteLater()
				room:provide(js)
				return true
			end
			return false
		end,
	}


--陆绩
y_huntiancard = sgs.CreateSkillCard
	{ --浑天
		name = "y_huntiancard",
		target_fixed = true,
		will_throw = false,
		once = false,

		on_use = function(self, room, source, targets)
			--room:broadcastSkillInvoke("y_huntian")
			room:moveCardTo(self, source, sgs.Player_PlaceTable, true)
			local n = room:getDrawPile():length()
			if n >= 5 then n = 5 end
			local num = "1"
			for i = 1, n, 1 do
				if i > 1 then
					num = num .. "+" .. tostring(i)
				end
			end
			local ch = room:askForChoice(source, self:objectName(), num)
			for j = 1, n, 1 do
				if j == tonumber(ch) then
					n = j
					break
				end
			end
			local getid = room:getDrawPile():at(n - 1)
			local cards = room:getNCards(n - 1)
			local move = sgs.CardsMoveStruct()
			move.to = source
			move.to_place = sgs.Player_PlaceTable
			move.card_ids = cards
			room:moveCardsAtomic(move, false)
			
			room:moveCardTo(self, source, sgs.Player_DrawPile, true)
			room:obtainCard(source, getid)
			move.to = nil
			move.to_place = sgs.Player_DrawPile
			move.card_ids = cards
			room:moveCardsAtomic(move, false)
			local card = self:getSubcards():at(0)
			room:setCardFlag(card, "y_huntian")
			room:setCardFlag(card, "y_huntian"..source:objectName())
		end,
	}

y_huntianvs = sgs.CreateViewAsSkillV2
	{
		name = "y_huntian",
		n = 1,

		can_activate = function(skill, request)
			return request:getPattern() == "@@y_huntian"
		end,

		can_select_card = function(skill, request, candidate)
			return candidate and not candidate:isEquipped()
				and request:getSelectedCardIds():length() < 1
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() == 1
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() ~= 1 then return nil end
			local acard = y_huntiancard:clone()
			acard:addSubcard(ids:at(0))
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_huntian = sgs.CreateTriggerSkillV2
	{
		name = "y_huntian",
		view_as_skill = y_huntianvs,
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.EventPhaseStart then
				if player:getPhase() ~= sgs.Player_Start then return false end
				if player:isKongcheng() then return false end
				return skill:objectName()
			elseif event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):hasFlag("y_huntian") and move.to_place ~= sgs.Player_DrawPile then
						return skill:objectName()
					end
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.EventPhaseStart then
				--if not player:askForSkillInvoke(skill:objectName(),data) then return false end
				room:askForUseCard(player, "@@y_huntian", "@y_huntian")
			elseif event == sgs.CardsMoveOneTime then
				local move = ctx.original_data:toMoveOneTime()
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):hasFlag("y_huntian") and move.to_place ~= sgs.Player_DrawPile then
						room:setCardFlag(sgs.Sanguosha:getCard(id), "-y_huntian")
						if move.to_place ~= sgs.Player_PlaceHand then return false end
						for _, lj in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
							if sgs.Sanguosha:getCard(id):hasFlag("y_huntian"..lj:objectName()) then
								room:setCardFlag(sgs.Sanguosha:getCard(id), "-y_huntian"..lj:objectName())
								if not lj:askForSkillInvoke("y_huntian2", ctx.original_data) then return false end
								room:notifySkillInvoked(lj, skill:objectName())
								--room:broadcastSkillInvoke(skill:objectName())
								local tar
								for _, p in sgs.qlist(room:getAlivePlayers()) do
									if p:getSeat() == move.to:getSeat() then
										tar = p
										break
									end
								end
								local ai_data = sgs.QVariant()
								ai_data:setValue(tar)
								local choicelist = "htdraw"
								if lj:canDiscard(tar, "he") then
									choicelist = choicelist .. "+htdiscard"
								end
								local ch = room:askForChoice(lj, "y_huntian2", choicelist, ai_data)
								if ch == "htdraw" then
									tar:drawCards(1)
								elseif ch == "htdiscard" then
									local cardid = room:askForCardChosen(lj, tar, "he", skill:objectName())
									room:throwCard(cardid, tar, lj)
								end
							end
						end
					end
				end
			end
			return false
		end,
	}

y_huaiju = sgs.CreateTriggerSkillV2
	{ --怀橘
		name = "y_huaiju",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if not move.from or not move.from:isAlive() then return false end
			local reason = move.reason.m_reason
			if reason ~= sgs.CardMoveReason_S_REASON_RULEDISCARD and reason ~= sgs.CardMoveReason_S_REASON_THROW
				and reason ~= sgs.CardMoveReason_S_REASON_DISMANTLE then return false end
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if (card:isKindOf("Peach") or (card:isKindOf("Jink") and card:getSuit() == sgs.Card_Heart))
					and room:getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardPile then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, lj in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if (card:isKindOf("Peach") or (card:isKindOf("Jink") and card:getSuit() == sgs.Card_Heart)) and room:getCardPlace(card:getEffectiveId())==sgs.Player_DiscardPile then
						if lj:askForSkillInvoke(skill:objectName(), ctx.original_data) then
							room:broadcastSkillInvoke(skill:objectName())
							if move.from:getSeat() == lj:getSeat() then
								room:setPlayerMark(lj, skill:objectName(), card:getEffectiveId())
								local tar = room:askForPlayerChosen(lj, room:getOtherPlayers(lj), skill:objectName())
								room:setPlayerMark(lj, skill:objectName(), 0)
								room:obtainCard(tar, id)
							else
								room:obtainCard(lj, id)
							end
						end
					end
				end
			end
			return false
		end,
	}

--董白
y_weiji = sgs.CreateTriggerSkillV2
	{ --未笄
		name = "y_weiji",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.EventPhaseStart, --[[sgs.EventPhaseEnd]] },

		can_trigger = function(skill, event, room, player, data)
			--if player:getPhase() ~= sgs.Player_Discard then return false end
			if player:getPhase() ~= sgs.Player_Finish then return false end
			if event == sgs.EventPhaseStart then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMaxHp() >= player:getMaxHp() then
						return skill:objectName()
					end
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke(skill:objectName())
			room:loseHp(player, 1, true, player, skill:objectName())
			local maxhp = player:getMaxHp()
			local value = sgs.QVariant(maxhp + 1)
			room:setPlayerProperty(player, "maxhp", value)
			local tar = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName())
			local x = player:getHp()
			--local x = math.floor(tar:getMaxHp()/2)
			tar:drawCards(x)
			return false
		end
	}

y_jiushangvs = sgs.CreateViewAsSkillV2
	{ --酒殇
		name = "y_jiushang",
		n = 0,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			if not player then return false end
			local reason = request:getReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				return not player:hasUsed("Analeptic")
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				return string.find(request:getPattern(), "analeptic") ~= nil
			end
			return false
		end,

		create_card = function(skill, request)
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			analeptic:setSkillName(skill:objectName())
			return analeptic
		end,
	}

y_jiushang = sgs.CreateTriggerSkillV2
	{
		name = "y_jiushang",
		view_as_skill = y_jiushangvs,
		events = { sgs.CardUsed },

		can_trigger = function(skill, event, room, player, data)
			local use = data:toCardUse()
			local card = use.card
			if card and table.contains(card:getSkillNames(), "y_jiushang") then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			room:loseMaxHp(player)
			return false
		end
	}

--陆抗
y_kegou = sgs.CreateTriggerSkillV2
	{                                                    --克构
		name = "y_kegou",
		events = { sgs.EventPhaseChanging, sgs.CardEffected }, --sgs.EventPhaseSkipping
		frequency = sgs.Skill_NotFrequent,

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Play then
					if player:hasFlag("y_kglbsh") then
						return y_v2_all_owners(skill, room)
					end
				elseif player:hasFlag("y_kegou") then
					return y_v2_all_owners(skill, room)
				else
					return y_v2_all_owners(skill, room, function(lk)
						return lk:getMark("y_kegou") == 1
					end)
				end
				return false
			elseif event == sgs.CardEffected then
				local effect = data:toCardEffect()
				if effect.card and effect.card:isKindOf("Indulgence") then
					return y_v2_all_owners(skill, room)
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			--player 為技能持有者（lk）；ctx.invoker 為原事件角色
			local invoker = ctx.invoker
			if event == sgs.EventPhaseChanging then
				local change = ctx.original_data:toPhaseChange()
				if change.to == sgs.Player_Play then
					if not invoker:hasFlag("y_kglbsh") then return false end
					invoker:setFlags("-y_kglbsh")
					if invoker:isSkipped(sgs.Player_Play) then
						invoker:setFlags("y_kegou")
					end
				elseif invoker:hasFlag("y_kegou") then
					invoker:setFlags("-y_kegou")
					if not player:askForSkillInvoke(skill:objectName(), ctx.original_data) then return false end
					room:broadcastSkillInvoke(skill:objectName())
					player:drawCards(1)
					player:setMark("y_kegou", 1)
					player:gainAnExtraTurn()
				elseif player:getMark("y_kegou") == 1 then
					if change.to ~= sgs.Player_Play then
						if change.to == sgs.Player_Finish then
							player:setMark("y_kegou", 0)
						end
						player:skip(change.to)
					end
				end
			elseif event == sgs.CardEffected then
				local effect = ctx.original_data:toCardEffect()
				if effect.card and effect.card:isKindOf("Indulgence") then
					invoker:setFlags("y_kglbsh")
				end
			end
			return false
		end,
	}

--相惜
y_xiangxicard = sgs.CreateSkillCard {
	name = "y_xiangxicard",
	target_fixed = false,
	will_throw = true,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getSeat() ~= player:getSeat()
	end,

	on_use = function(self, room, source, targets)
		room:addPlayerHistory(source, "#"..self:objectName())
		--room:broadcastSkillInvoke("y_xiangxi",1)
		local s = source
		local t = targets[1]

		local idlistA = sgs.IntList()
		local idlistB = sgs.IntList()
		local cardsA, cardsB, place
		local ai_data = sgs.QVariant()
		ai_data:setValue(source)
		local ch = room:askForChoice(t, "y_xiangxi", "h+e+j", ai_data)
		if ch == "h" then
			cardsA = s:getHandcards()
			cardsB = t:getHandcards()
			place = sgs.Player_PlaceHand
		elseif ch == "e" then
			cardsA = s:getEquips()
			cardsB = t:getEquips()
			place = sgs.Player_PlaceEquip
		elseif ch == "j" then
			cardsA = s:getJudgingArea()
			cardsB = t:getJudgingArea()
			place = sgs.Player_PlaceDelayedTrick
		end
		for _, c in sgs.qlist(cardsA) do
			idlistA:append(c:getId())
		end
		for _, c in sgs.qlist(cardsB) do
			idlistB:append(c:getId())
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = idlistA
		move.to = t
		move.to_place = sgs.Player_PlaceTable
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_SWAP
		room:moveCardsAtomic(move, false)
		move.card_ids = idlistB
		move.to = s
		move.to_place = place
		room:moveCardsAtomic(move, false)
		move.card_ids = idlistA
		move.to = t
		move.to_place = place
		room:moveCardsAtomic(move, false)
		if ch == "j" and s:isWounded() then
			--if room:askForDiscard(s,"y_xiangxi",1,1,true,true) then
			room:broadcastSkillInvoke("y_xiangxi", 2)
			local recover = sgs.RecoverStruct()
			recover.recover = 1
			recover.who = s
			room:recover(s, recover)
			--end
		end
	end
}

y_xiangxi = sgs.CreateViewAsSkillV2 {
	name = "y_xiangxi",
	n = 0,

	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#y_xiangxicard")
	end,

	create_card = function(skill, request)
		local card = y_xiangxicard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
}

--周瑜
y_yingzi = sgs.CreateTriggerSkillV2
	{ --英姿
		name = "y_yingzi",
		frequency = sgs.Skill_Frequent,
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if move.from == nil or move.from:getPhase() ~= sgs.Player_NotActive then return false end
			local reason = move.reason.m_reason
			if reason == sgs.CardMoveReason_S_REASON_USE or reason == sgs.CardMoveReason_S_REASON_RESPONSE
				or reason == sgs.CardMoveReason_S_REASON_LETUSE or reason == sgs.CardMoveReason_S_REASON_DISCARD
				or reason == sgs.CardMoveReason_S_REASON_THROW or reason == sgs.CardMoveReason_S_REASON_DISMANTLE then
				if move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand) then
					for _, id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
							return skill:objectName()
						end
					end
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
					for _, zy in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
						if zy:askForSkillInvoke(skill:objectName(), ctx.original_data) then
						room:broadcastSkillInvoke(skill:objectName())
						zy:drawCards(1)
						end
					end
				end
			end
			return false
		end,
	}


y_shouju = sgs.CreateTriggerSkillV2
	{ --守矩
		name = "y_shouju",
		frequency = sgs.Skill_NotFrequent,
		events = { --[[sgs.BeforeCardsMove,]] sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD then
				return false
			end
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("EquipCard") or card:isKindOf("DelayedTrick") then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("EquipCard") or card:isKindOf("DelayedTrick") then
					for _, sly in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							local targets = sgs.SPlayerList()
							local place
							if card:isKindOf("EquipCard") then
								place = sgs.Player_PlaceEquip
								local i = card:getRealCard():toEquipCard():location()
								for _, p in sgs.qlist(room:getAlivePlayers()) do
									if p:hasEquipArea(i) and not p:getEquip(i) then
										targets:append(p)
									end
								end
							elseif card:isKindOf("DelayedTrick") then
								place = sgs.Player_PlaceDelayedTrick
								local no = true
								for _, p in sgs.qlist(room:getAlivePlayers()) do
									for _, c in sgs.qlist(p:getJudgingArea()) do
										if c:objectName() == card:objectName() then
											no = false
											break
										end
									end
									if no == true then
										targets:append(p)
									end
								end
							end
							if not targets:isEmpty() then
								local ai_data = sgs.QVariant()
								ai_data:setValue(id)
								if room:askForCard(sly, ".Basic", skill:objectName(), ai_data) then
									room:broadcastSkillInvoke(skill:objectName())
									room:setTag("y_shouju", ai_data)
									local tar = room:askForPlayerChosen(sly, targets, skill:objectName())
									room:removeTag("y_shouju")
									local log = sgs.LogMessage()
									log.type = "#y_shouju"
									log.from = sly
									log.arg = skill:objectName()
									room:sendLog(log)
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, sly:objectName(),
										skill:objectName(), "")
									room:moveCardTo(card, tar, place, reason)
								end
							end
						end
					end
				end
			end
			return false
		end
	}

y_wenliang = sgs.CreateTriggerSkillV2
	{ --温良
		name = "y_wenliang",
		events = { sgs.TargetConfirmed, sgs.CardEffected },

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.TargetConfirmed then
				local use = data:toCardUse()
				if not use.card or not use.card:isKindOf("Slash") then return false end
				if not use.to:contains(player) then return false end
				if player:getEquips():length() <= 0 then return false end
				--player 為【殺】目標之一；擁有者須非其本人且在其攻擊範圍內
				return y_v2_all_owners(skill, room, function(sly)
					return player:objectName() ~= sly:objectName() and sly:inMyAttackRange(player)
				end)
			elseif event == sgs.CardEffected then
				local eff = data:toCardEffect()
				if eff.card and eff.card:isKindOf("Slash") and player:hasFlag("y_wenliang") then
					return y_v2_all_owners(skill, room)
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			if event == sgs.TargetConfirmed then
				local ai_data = sgs.QVariant()
				ai_data:setValue(ctx.invoker)
				return player:askForSkillInvoke(skill:objectName(), ai_data)
			end
			return true
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.TargetConfirmed then
				local log = sgs.LogMessage()
				log.type = "#y_wenliang"
				room:broadcastSkillInvoke(skill:objectName())
				local id = room:askForCardChosen(player, ctx.invoker, "e", skill:objectName())
				room:throwCard(id, ctx.invoker, player)
				ctx.invoker:setFlags("y_wenliang")
				log.from = ctx.invoker
				room:sendLog(log)
			elseif event == sgs.CardEffected then
				ctx.invoker:setFlags("-y_wenliang")
				return true
			end
			return false
		end,
	}

--蔡夫人
y_huiyu = sgs.CreateTriggerSkillV2
	{ --毁誉
		name = "y_huiyu",
		events = { sgs.TargetSpecifying },

		can_trigger = function(skill, event, room, player, data)
			local use = data:toCardUse()
			if not (use.card and use.card:isBlack() and use.card:isNDTrick() and not use.card:isKindOf("Nullification")) then
				return false
			end
			if not use.from or use.from:getSeat() ~= player:getSeat() then return false end
			--player 為使用來源；擁有者須為來源本人或目標之一
			return y_v2_all_owners(skill, room, function(cfr)
				return cfr:getSeat() == use.from:getSeat() or use.to:contains(cfr)
			end)
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke("y_huiyu", ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local use = ctx.original_data:toCardUse()
			if use.from:getSeat() == player:getSeat() then
				room:broadcastSkillInvoke(skill:objectName(), 1)
			else
				room:broadcastSkillInvoke(skill:objectName(), 2)
			end
			player:drawCards(1)
			local slash = sgs.Sanguosha:cloneCard("slash", use.card:getSuit(), use.card:getNumber())
			slash:addSubcard(use.card)
			slash:setSkillName(skill:objectName())
			slash:deleteLater()
			use.card = slash
			ctx.original_data:setValue(use)
			local log = sgs.LogMessage()
			log.type = "#y_huiyu"
			log.from = player
			log.arg = skill:objectName()
			room:sendLog(log)
			return true
		end,
	}

y_xianzhoucard = sgs.CreateSkillCard
	{ --献州
		name = "y_xianzhoucard",
		target_fixed = true,
		will_throw = false,
		once = false,

		on_use = function(self, room, source, targets)
		end
	}

y_xianzhouvs = sgs.CreateViewAsSkillV2
	{
		name = "y_xianzhou",
		n = 9,

		can_activate = function(skill, request)
			return request:getPattern() == "@@y_xianzhou"
		end,

		can_select_card = function(skill, request, candidate)
			local player = request:getInitiator()
			return candidate and not candidate:isEquipped()
				and player and request:getSelectedCardIds():length() < player:getHp()
		end,

		card_selection_feasible = function(skill, request)
			local player = request:getInitiator()
			return player and request:getSelectedCardIds():length() == player:getHp()
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			local player = request:getInitiator()
			if not player or ids:length() ~= player:getHp() then return nil end
			local acard = y_xianzhoucard:clone()
			for i = 0, ids:length() - 1, 1 do
				acard:addSubcard(ids:at(i))
			end
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_xianzhou = sgs.CreateTriggerSkillV2
	{ --献州
		name = "y_xianzhou",
		view_as_skill = y_xianzhouvs,
		events = { sgs.DamageInflicted },

		can_trigger = function(skill, event, room, player, data)
			if player:getHandcardNum() >= player:getHp() then
				return skill:objectName()
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local damage = ctx.original_data:toDamage()
			local from = damage.from
			room:setTag("y_xianzhou", ctx.original_data)
			local card = room:askForUseCard(player, "@@y_xianzhou", "@y_xianzhou")
			room:removeTag("y_xianzhou")
			if card then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), "y_xianzhou",
					"")
				room:moveCardTo(card, from, sgs.Player_PlaceHand, reason)
				return true
			end
			return false
		end,
	}

--刘馥
y_zhucheng = sgs.CreateMaxCardsSkillV2
	{ --筑城
		name = "y_zhucheng",
		fixed_func = function(skill, ctx)
			local target = ctx:getHolder()
			if target and target:hasSkill(skill:objectName()) then
				local x = target:getHp()
				for _, p in sgs.qlist(target:getSiblings()) do
					if p:isAlive() and p:inMyAttackRange(target) then
						x = x + 1
					end
				end
				return x
			end
			return nil
		end
	}

y_duoqi = sgs.CreateTriggerSkillV2
	{ --夺气
		name = "y_duoqi",
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			if player:getPhase() ~= sgs.Player_Play or player:hasFlag("y_dqlf") then return false end
			local move = data:toMoveOneTime()
			local reason = move.reason.m_reason
			if reason == sgs.CardMoveReason_S_REASON_DISCARD or reason == sgs.CardMoveReason_S_REASON_THROW or reason == sgs.CardMoveReason_S_REASON_DISMANTLE then
				local lf = room:findPlayerBySkillName(skill:objectName())
				if lf then
					return skill:objectName(), lf:objectName()
				end
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			room:broadcastSkillInvoke(skill:objectName())
			local x = move.card_ids:length()
			local y = player:getLostHp()
			player:drawCards(x + y)
			local hs = sgs.IntList()
			local hhs = sgs.IntList()
			local hhhs = player:getHandcards()
			for _, c in sgs.qlist(hhhs) do
				hhs:append(c:getId())
			end
			for i = 1, x, 1 do
				room:fillAG(hhs, player)
				local id = room:askForAG(player, hhs, false, skill:objectName())
				hs:append(id)
				hhs:removeOne(id)
				room:clearAG(player)
			end
			local mv = sgs.CardsMoveStruct()
			mv.card_ids = hs
			mv.to_place = sgs.Player_DrawPile
			room:moveCardsAtomic(mv, false)
			ctx.invoker:setFlags("y_dqlf")
			return false
		end,
	}

--曹节
y_youfang = sgs.CreateTriggerSkillV2
	{ --游方
		name = "y_youfang",
		events = { sgs.CardsMoveOneTime },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if not move.from or not move.from:isAlive() then return false end
			local reason = move.reason.m_reason
			if reason ~= sgs.CardMoveReason_S_REASON_RULEDISCARD and reason ~= sgs.CardMoveReason_S_REASON_THROW
				and reason ~= sgs.CardMoveReason_S_REASON_DISMANTLE then return false end
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
					return skill:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			for _, cj in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if cj:askForSkillInvoke(skill:objectName(), ctx.original_data) then
					local chs = "recover1+draw1"
					if not move.from:isWounded() then chs = "draw1" end
					local ch = room:askForChoice(cj, skill:objectName(), chs, ctx.original_data)
					local tar
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getSeat() == move.from:getSeat() then
							tar = p
							break
						end
					end
					if ch == "recover1" then
						room:broadcastSkillInvoke(skill:objectName())
						local recover = sgs.RecoverStruct()
						recover.recover = 1
						recover.who = cj
						room:recover(tar, recover)
					else
						room:broadcastSkillInvoke(skill:objectName())
						tar:drawCards(1)
					end
				end
			end
			return false
		end,
	}

y_zhixi = sgs.CreateTriggerSkillV2
	{ --掷玺
		name = "y_zhixi",
		events = { sgs.BeforeCardsMove },

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if not move.from then return false end
			if move.from:getSeat() ~= player:getSeat() or move.from:objectName() ~= player:objectName() then return false end
			if not (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand)) then return false end
			local reason = move.reason.m_reason
			if reason == sgs.CardMoveReason_S_REASON_GIVE or reason == sgs.CardMoveReason_S_REASON_ROB or reason == sgs.CardMoveReason_S_REASON_SWAP
				or reason == sgs.CardMoveReason_S_REASON_EXTRACTION or reason == sgs.CardMoveReason_S_REASON_TRANSFER
				or reason == sgs.CardMoveReason_S_REASON_GOTCARD or reason == sgs.CardMoveReason_S_REASON_UNKNOWN then
				return skill:objectName()
			end
			return false
		end,

		on_cost = function(skill, event, room, player, ctx)
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			local move = ctx.original_data:toMoveOneTime()
			room:broadcastSkillInvoke(skill:objectName())
			move.to_place = sgs.Player_DiscardPile
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_THROW
			ctx.original_data:setValue(move)
			local log = sgs.LogMessage()
			log.type = "#y_zhixi"
			room:sendLog(log)
			return true
		end,
	}

--徐氏
y_xiaoyi = sgs.CreateTriggerSkillV2
	{ --晓义
		name = "y_xiaoyi",
		events = { sgs.CardsMoveOneTime },
		--frequency=sgs.Skill_Compulsory,

		can_trigger = function(skill, event, room, player, data)
			local move = data:toMoveOneTime()
			if not move.from then return false end
			if move.from:getSeat() ~= player:getSeat() or move.from:objectName() ~= player:objectName() then return false end
			if not move.from_places:contains(sgs.Player_PlaceEquip) then return false end
			return skill:objectName()
		end,

		on_cost = function(skill, event, room, player, ctx)
			room:broadcastSkillInvoke(skill:objectName())
			--[[local log=sgs.LogMessage()
		log.type ="#y_xiaoyi"
		log.from=player
        room:sendLog(log)]]
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end,

		on_effect = function(skill, event, room, player, ctx)
			for i = 1, 999, 1 do
				local ids = room:getNCards(1, false)
				room:fillAG(ids, nil)
				room:getThread():delay(1000)
				room:clearAG()
				local cdata = sgs.QVariant()
				cdata:setValue(sgs.Sanguosha:getCard(ids:first()))
				player:setTag(skill:objectName(), cdata)
				local to = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName())

				local card = sgs.Sanguosha:getCard(ids:first())
				room:obtainCard(to, card, false)
				if not card:isKindOf("BasicCard") then break end
			end
			return false
		end,
	}

y_lianzhu = sgs.CreateViewAsSkillV2
	{ --联诛
		name = "y_lianzhu",
		n = 99,

		can_activate = function(skill, request)
			local player = request:getInitiator()
			return player
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
				and not player:hasUsed("#y_lianzhucard")
		end,

		can_select_card = function(skill, request, candidate)
			return candidate ~= nil
				and request:getSelectedCardIds():length() < 99
		end,

		card_selection_feasible = function(skill, request)
			return request:getSelectedCardIds():length() > 0
		end,

		create_card = function(skill, request)
			local ids = request:getSelectedCardIds()
			if ids:length() == 0 then return nil end
			local acard = y_lianzhucard:clone()
			for i = 0, ids:length() - 1, 1 do
				acard:addSubcard(ids:at(i))
			end
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_lianzhucard = sgs.CreateSkillCard
	{
		name = "y_lianzhucard",
		target_fixed = false,
		will_throw = true,

		filter = function(self, targets, to_select, player)
			return #targets < self:subcardsLength()
		end,

		feasible = function(self, targets, player)
			return #targets == self:subcardsLength()
		end,

		on_use = function(self, room, source, targets)
			room:addPlayerHistory(source, "#"..self:objectName())
			local room = source:getRoom()
			for _, p in ipairs(targets) do
				if p:isAlive() then
					local tars = sgs.SPlayerList()
					for _, q in sgs.qlist(room:getOtherPlayers(p)) do
						if p:canSlash(q, nil, false) then
							tars:append(q)
						end
					end
					if tars:length() == 0 or not room:askForUseSlashTo(p, tars, "@y_lianzhu-slash") then
						p:drawCards(1)
					end
				end
				--room:getThread():delay()
			end
		end,
	}

--影·徐庶
y_wuyan = sgs.CreateProhibitSkill
	{ --无言
		name = "y_wuyan",

		is_prohibited = function(self, from, to, card)
			return card:isNDTrick() and
				((to:getHandcardNum() <= from:getHandcardNum() and to:hasSkill(self:objectName()) and not from:hasSkill(self:objectName()))
					or (to:getHandcardNum() < from:getHandcardNum() and from:hasSkill(self:objectName())))
		end
	}


--[[y_wuyan = sgs.CreateTriggerSkill{
	name = "y_wuyan" ,
	events = {sgs.CardEffected,} ,
	frequency = sgs.Skill_Compulsory ,
	
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.to:objectName() == effect.from:objectName() then return false end
		if effect.card:isNDTrick() then
		    if effect.to:getHandcardNum()>effect.from:getHandcardNum()-1 then return false end
			if effect.from and effect.from:hasSkill(self:objectName()) then
				return true
			elseif effect.to:hasSkill(self:objectName()) and effect.from then
				return true
			end
		end
		return false
	end ,
	
	can_trigger = function(self, target)
		return true
	end
}]]

y_mingjiancard = sgs.CreateSkillCard
	{
		name = "y_mingjiancard",
		target_fixed = false,
		will_throw = false,

		filter = function(self, targets, to_select, player)
			return player:inMyAttackRange(to_select) and (not to_select:isKongcheng()) and #targets < 1
		end,

		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			room:setTag("Dongchaee", sgs.QVariant())
			room:setTag("Dongchaee", sgs.QVariant(effect.to:objectName()))
			room:showAllCards(effect.to, player)
			room:getThread():delay(1000)
		end
	}

y_mingjianvs = sgs.CreateViewAsSkillV2
	{
		name = "y_mingjian",

		can_activate = function(skill, request)
			return request:getInitiator()
				and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
		end,

		create_card = function(skill, request)
			local acard = y_mingjiancard:clone()
			acard:setSkillName(skill:objectName())
			return acard
		end,
	}

y_mingjian = sgs.CreateTriggerSkillV2
	{
		name = "y_mingjian",
		view_as_skill = y_mingjianvs,
		events = { sgs.GameStart, sgs.CardEffected },

		can_trigger = function(skill, event, room, player, data)
			if event == sgs.GameStart then
				return skill:objectName()
			elseif event == sgs.CardEffected then
				local effect = data:toCardEffect()
				if not effect.from then return false end
				--擁有者為錦囊來源；記錄目標供其他模組（extra/gaoda）讀取
				if effect.from:hasSkill(skill:objectName()) and effect.from:inMyAttackRange(effect.to) then
					return skill:objectName(), effect.from:objectName()
				end
			end
			return false
		end,

		on_effect = function(skill, event, room, player, ctx)
			if event == sgs.GameStart then
				room:setTag("Dongchaer", sgs.QVariant(player:objectName()))
				local plist = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:inMyAttackRange(p) then plist:append(p) end
				end
				if not plist:isEmpty() then
					for _, q in sgs.qlist(plist) do
						room:showAllCards(q, player)
						room:getThread():delay(1000)
					end
				end
			elseif event == sgs.CardEffected then
				local effect = ctx.original_data:toCardEffect()
				room:setTag("Dongchaee", sgs.QVariant())
				room:setTag("Dongchaee", sgs.QVariant(effect.to:objectName()))
			end
			return false
		end
	}

local function FanjinMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "y_fanjin", ""))
		move.to_pile_name = "&y_fanjin"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "y_fanjin", ""))
		move.from_pile_name = "&y_fanjin"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

y_fanjin = sgs.CreateTriggerSkillV2 {
	name = "y_fanjin",
	events = { sgs.Damaged, sgs.Damage, sgs.CardsMoveOneTime },

	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged or event == sgs.Damage then
			local cur = room:getCurrent()
			if cur and cur:hasFlag(skill:objectName()) then return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					return skill:objectName()
				end
			end
			return false
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceHand) then
				local list = player:property("y_fanjin"):toString():split("+")
				if #list > 0 then
					for _, l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							return skill:objectName()
						end
					end
				end
			end
		end
		return false
	end,

	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.Damaged or event == sgs.Damage then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		end
		return true
	end,

	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged or event == sgs.Damage then
			--local dm = ctx.original_data:toDamage()
			--if not dm.card:isKindOf("Slash") then return false end
			local plist = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then plist:append(p) end
			end
			if plist:isEmpty() then return false end
			room:broadcastSkillInvoke(skill:objectName())
			room:setTag("Dongchaee", sgs.QVariant())
			local to = room:askForPlayerChosen(player, plist, skill:objectName())
			if player:inMyAttackRange(to) then
				room:setTag("Dongchaee", sgs.QVariant(to:objectName()))
			end
			local id = room:askForCardChosen(player, to, "h", skill:objectName())
			if id then
				room:showCard(player, id)
				local list = player:property("y_fanjin"):toString():split("+")
				if #list > 0 then
					local has = false
					for _, l in pairs(list) do
						if id == tonumber(l) then
							has = true
						end
					end
					if has == true then return false end
				end
				local ids = sgs.IntList()
				ids:append(id)
				FanjinMove(ids, true, player)
				table.insert(list, tostring(id))
				room:setPlayerProperty(player, "y_fanjin", sgs.QVariant(table.concat(list, "+")))
				room:getCurrent():setFlags(skill:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceHand) then
				--local xxy = room:findPlayerBySkillName(skill:objectName())
				local list = player:property("y_fanjin"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					for _, l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						end
					end
					FanjinMove(to_remove, false, player)
					for _, id in sgs.qlist(to_remove) do
						table.removeOne(list, tostring(id))
					end
					local pattern = sgs.QVariant()
					if #list > 0 then
						pattern = sgs.QVariant(table.concat(list, "+"))
					end
					room:setPlayerProperty(player, "y_fanjin", pattern)
				end
			end
		end
		return false
	end
}

y_liubei:addSkill(y_rende)
y_liubei:addSkill(y_lianying)
y_mizhen:addSkill(y_yongjue)
y_mizhen:addSkill(y_cunsi)
y_bulianshi:addSkill(y_anxu)
y_bulianshi:addSkill(y_chongguan)
--y_jiangwei:addSkill(y_tiaoxin)
y_jiangwei:addSkill("tiaoxin")
y_jiangwei:addSkill(y_zhiji)
y_ganmei:addSkill(y_shushen)
y_ganmei:addSkill(y_shenzhi)
y_mayunlu:addSkill(y_rongzhuang)
y_mayunlu:addSkill(y_chongqi)
y_lvmeng:addSkill(y_baiyi)
y_zhoutai:addSkill(y_yuanjiu)
y_handang:addSkill(y_jiefan)
y_zhugejin:addSkill(y_huanshi)
y_zhugejin:addSkill(y_hongyuan)
y_liubiao:addSkill(y_zishou)
y_liubiao:addSkill(y_yangzheng)
y_luxun:addSkill(y_fenying)
y_luxun:addSkill(y_dushi)
y_luji:addSkill(y_huaiju)
y_luji:addSkill(y_huntian)
y_liru:addSkill(y_zhensha)
y_liru:addSkill(y_shipo)
y_lvlingqi:addSkill(y_wuji)
y_lvlingqi:addSkill(y_wujitar)
y_lvlingqi:addSkill(y_laoyue)
y_puyuan:addSkill(y_shenzhu)
y_puyuan:addSkill(y_bailian)
y_huangchengyan:addSkill(y_caipei)
y_huangchengyan:addSkill(y_kongzhen)
y_dongbai:addSkill(y_weiji)
y_dongbai:addSkill(y_jiushang)
--y_liuxie:addSkill(y_kuilei)
--y_liuxie:addSkill(y_tianming)
y_lukang:addSkill(y_kegou)
y_lukang:addSkill(y_xiangxi)
y_zhouyu:addSkill(y_yingzi)
y_zhouyu:addSkill("fanjian")
y_sunluyu:addSkill(y_shouju)
y_sunluyu:addSkill(y_wenliang)
y_caojie:addSkill(y_youfang)
y_caojie:addSkill(y_zhixi)

y_xushi:addSkill(y_xiaoyi)
y_xushi:addSkill(y_lianzhu)
--y_xushu:addSkill(y_wuyan)
--y_xushu:addSkill("nosjujian")
y_caifuren:addSkill(y_huiyu)
y_caifuren:addSkill(y_xianzhou)
--y_liufu:addSkill(y_zhucheng)
--y_liufu:addSkill(y_duoqi)
y_xinxianying:addSkill(y_mingjian)
y_xinxianying:addSkill(y_fanjin)



sgs.LoadTranslationTable
{
	["shadow"] = "影包",

	["y_liubei"] = "刘备[影]",
	["y_rende"] = "仁德",
	["y_rendecard"] = "仁德",
	["rendecount"] = "仁德",
	[":y_rende"] = "出牌阶段，若你的手牌不少于两张，你可将任意数量的手牌交给其他角色，若你于此阶段给出的牌累计不少于两张，你回复1点体力。",
	["$y_rende1"] = "以德服人",
	["$y_rende2"] = "惟贤惟德能服于人",
	["y_lianying"] = "连营",
	[":y_lianying"] = "锁定技，当你失去最后一张手牌时，你摸一张牌。",
	["$y_lianying"] = "牌不是万能的，但是没有牌是万万不能的",
	["designer:y_liubei"] = "香澄果穗",
	["#y_liubei"] = "汉昭烈帝",

	["#y_bulianshi"] = "无冕之后",
	["y_bulianshi"] = "步炼师[影]",
	["y_chongguan"] = "宠冠",
	[":y_chongguan"] = "每当有角色失去一次装备区的牌时，你摸一张牌。",
	["y_anxu"] = "安恤",
	["y_anxucard"] = "安恤",
	[":y_anxu"] = "出牌阶段限一次，你可令一名角色摸1张牌，弃1张牌。若弃置的不为基本牌，其弃置一名角色区域内的一张牌。",
	["#y_chongguan"] = "%from 的锁定技【宠冠】被触发！",
	["$y_anxu"] = "需要帮忙吗",
	["$y_chongguan"] = "额呵呵",
	["~y_bulianshi"] = "吾若有灵常伴君侧",
	["designer:y_bulianshi"] = "ByArt",
	["#y_bulianshi"] = "无冕之后",
	["illustrator:y_bulianshi"] = "兔小笨",

	["y_jiangwei"] = "姜维[影]",
	["y_tiaoxin"] = "挑衅",
	["tiaoxinm_card"] = "挑衅",
	["@txslash"] = "姜维对你发动挑衅，你可对其使用一张杀！",
	[":y_tiaoxin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名你在其攻击范围内的其他角色选择一项：对你使用一张【杀】，或令你弃置其一张牌。",
	["y_zhiji"] = "志继",
	[":y_zhiji"] = "你每受到一次伤害，可观看牌堆顶5张牌，将其中任意数量的牌置于牌堆顶，其余置于牌堆底，然后你摸一张牌。",
	["$y_tiaoxin"] = "汝等小儿，可敢杀我",
	["$y_zhiji"] = "丞相厚恩，维万死不能相报",
	["~y_jiangwei"] = "臣等正欲死战，陛下何故先降",
	["designer:y_jiangwei"] = "ByArt",
	["#y_jiangwei"] = "龙的衣钵",
	["illustrator:y_jiangwei"] = "官方",

	["y_mizhen"] = "糜贞[影]",
	["#y_mizhen"] = "乱世沉香",
	["y_huyou"] = "护幼",
	["y_yongjue"] = "勇决",
	["y_cunsi"] = "存嗣",
	["y_yjtargetmove"] = "勇决",
	[":y_yongjue"] = "当一名角色成为【杀】或非延时锦囊牌的目标时，若其手牌数小于其体力值，你可摸一张牌，则该角色可将目标转移给你。",
	[":y_cunsi"] = "当你处于濒死状态时，你可将所有牌交给一名其他角色，令其获得技能“勇决”，然后你立即死亡。",
	["$y_cunsi"] = "交给你了",
	["$y_yongjue"] = "快来护驾",
	["~y_mizhen"] = "死有何惧也",
	["designer:y_mizhen"] = "ByArt",
	["illustrator:y_mizhen"] = "木美人",

	["y_ganmei"] = "甘梅[影]",
	["#y_ganmei"] = "昭烈皇后",
	["y_shushen"] = "淑慎",
	["y_shenzhi"] = "神智",
	["Idraw"] = "摸一张牌",
	["Udraw"] = "甘梅摸一张牌",
	["y_shenzhicard"] = "神智",
	[":y_shenzhi"] = "当你需要使用【桃】时，若你的手牌数大于体力值，你可将手牌弃至体力值的张数，视为使用一张【桃】。",
	[":y_shushen"] = "回合结束时，你可令一名其他角色选择：摸一张牌或令你摸一张牌。",
	["$y_shushen"] = "履行修仁，淑慎其身",
	["$y_shenzhi"] = "万物以丧志，弃之可修身",
	["~y_ganmei"] = "生同事，死同穴",
	["designer:y_ganmei"] = "ByArt",

	["y_mayunlu"] = "马云禄[影]",
	["#y_mayunlu"] = "巾帼冰枪",
	["y_rongzhuang"] = "戎装",
	["y_chongqi"] = "冲骑",
	[":y_rongzhuang"] = "你可将与装备区内的牌花色相同的手牌当【杀】使用或打出；不与装备区内的牌花色相同的手牌当【闪】使用或打出。",
	[":y_chongqi"] = "当你使用【杀】指定一名角色为目标后，若其装备区内有与此【杀】花色相同的牌，你弃置其一张牌。",
	["$y_rongzhuang"] = "看我的厉害",
	["$y_chongqi"] = "螳臂当车",
	["~y_mayunlu"] = "马蹄声",
	["designer:y_mayunlu"] = "ByArt",
	["illustrator:y_mayunlu"] = "宇峻画廊",

	["y_lvmeng"] = "吕蒙[影]",
	["y_baiyi"] = "白衣",
	[":y_baiyi"] = "当你或你攻击范围内的一名角色成为【杀】的目标后，若此【杀】不为黑色，你可弃置一名角色区域内的一张牌；若此【杀】为黑色且目标为你时，你可摸一张牌，然后弃置一张牌。",
	["$y_baiyi1"] = "君子藏器于身待时而动",
	["$y_baiyi2"] = "进攻时机已到",
	["designer:y_lvmeng"] = "ByArt",
	["~y_lvmeng"] = "被看穿了吗",
	["#y_lvmeng"] = "国士之风",
	["illustrator:y_lvmeng"] = "官方",

	["y_zhoutai"] = "周泰[影]",
	["y_yuanjiuPile"] = "援救",
	["y_yuanjiu"] = "援救",
	["y_yuanjiu_card"] = "援救",
	[":y_yuanjiu"] = "一名角色向你求【桃】时，1.若你的武将牌上有相同点数的牌，你可获得你武将牌上的一张牌；2.若你的武将牌上没有相同点数的牌，你可摸等于你当前体力值+2数量的牌，然后将等量的手牌明置于你的武将牌之上，视为你对其使用一个【桃】。每轮求【桃】限一次",
	["$y_yuanjiu"] = "主公别怕，我来救你",
	["~y_zhoutai"] = "已经尽力了",
	["designer:y_zhoutai"] = "ByArt",
	["#y_zhoutai"] = "历战之躯",
	["illustrator:y_zhoutai"] = "官方",

	["y_handang"] = "韩当[影]",
	["y_jiefan"] = "解烦",
	["y_jiefancard"] = "解烦",
	[":y_jiefan"] = "出牌阶段限一次，你可弃置一名角色的一张牌，然后该角色可摸一张牌。",
	["$y_jiefan"] = "一物换一物",
	--["Pile"]="弃武将牌上的牌",
	--["Hej"]="弃区域内的牌",
	["~y_handang"] = "尽力啦",
	["designer:y_handang"] = "ByArt",
	["#y_handang"] = "石城侯",
	["illustrator:y_handang"] = "官方",

	["y_zhugejin"] = "诸葛瑾[影]",
	["y_hongyuan"] = "弘援",
	[":y_hongyuan"] = "回合外，每当你因使用打出或弃置而失去一张红色牌时，可指定你攻击范围内任意数量的角色和你各摸一张牌。",
	["y_huanshi"] = "缓释",
	["y_hongyuancard"] = "弘援",
	["~y_hongyuan"] = "指定你攻击范围内任意数量的角色",
	["@y_hongyuan"] = "是否发动技能【弘援】？",
	[":y_huanshi"] = "出牌阶段限一次，你可指定其他两名有手牌的角色,他们须各交给你一张手牌，然后你交给他们各一张手牌。",
	["y_huanshicard"] = "缓释",
	["$y_hongyuan"] = "和诸公之力攻讨奸贼",
	["$y_huanshi"] = "将军可愿听我一言",
	["~y_zhugejin"] = "君臣不相负，来世复君臣",
	["#y_zhugejin"] = "联盟的维系者",
	["designer:y_zhugejin"] = "ByArt",
	["cv:y_zhugejin"] = "韩旭",
	["illustrator:zhugejin"] = "liuheng",

	["y_liubiao"] = "刘表[影]",
	["y_zishou"] = "自守",
	[":y_zishou"] = "摸牌阶段你可少摸一张牌，若如此做，回合结束阶段时你将手牌补至体力上限。",
	["y_yangzheng"] = "养政",
	["y_yangzhengcard"] = "养政",
	["@y_yangzheng"] = "是否发动技能【养政】？",
	["~y_yangzheng"] = "选择任意数量的手牌，然后选择一名角色",
	[":y_yangzheng"] = "你每受到一次伤害，可将任意数量的手牌交给其他角色，若给出的牌张数累计不少于你当前的体力值张，你回复1点体力。",
	["$y_zishou"] = "让我好好考虑一下",
	["$y_yangzheng"] = "惟贤惟德能服于人",
	["#y_liubiao"] = "跨蹈汉南",
	["~y_liubiao"] = "何人继承大业啊",
	["designer:y_liubiao"] = "ByArt",
	["cv:y_liubiao"] = "",
	["illustrator:liubiaom"] = "官方",

	["y_liru"] = "李儒[影]",
	["y_zhensha"] = "鸩杀",
	["y_shipo"] = "识破",
	[":y_shipo"] = "当你于回合外需要使用或打出基本牌时，你可展示一名手牌数不小于你的角色的一张手牌，若为你需要使用或打出的牌，你获得之。",
	[":y_zhensha"] = "其他角色使用【闪】或【桃】时，你可打出一张与其相同名称的牌令其无效。",
	["$y_shipo"] = "你的计谋被识破啦",
	["$y_zhensha"] = "汝今势孤，命必绝矣",
	["~y_liru"] = "",
	["designer:y_liru"] = "ByArt",
	["#y_liru"] = "魔仕",
	["illustrator:y_zliru"] = "天空之城",

	["y_luxun"] = "陆逊[影]",
	["y_dushi"] = "度势",
	[":y_dushi"] = "当你成为【杀】或非延时锦囊牌的目标后，若你手牌数小于体力值，你可摸一张牌；若你手牌数大于体力值，你可弃置一名角色区域内的一张牌。",
	["y_fenying"] = "焚营",
	["y_fenyingcard"] = "焚营",
	[":y_fenying"] = "出牌阶段，你可弃置相当于一名其他角色手牌数的牌，然后可与其拼点，若你赢，你对其造成1点火焰伤害。",
	["$y_dushi"] = "审时度势，方能出奇制胜",
	["$y_fenying"] = "血色火海，葬敌万千",
	["~y_luxun"] = "我还是太年轻了",
	["designer:y_luxun"] = "ByArt",
	["#y_luxun"] = "儒生雄才",

	["y_lvlingqi"] = "吕玲绮[影]",
	["y_wuji"] = "舞戟",
	["y_laoyue"] = "捞月",
	[":y_wuji"] = "出牌阶段，你可弃置一张牌令你此阶段：攻击范围+1，或使用【杀】可指定目标数+1，或你【杀】的目标须使用【闪】+1；每项选择限一次。",
	["$y_wuji1"] = "你们两个谁更厉害？",
	["$y_wuji2"] = "敢挡我？",
	["$y_wuji3"] = "只能这样了",
	["$y_laoyue"] = "小女子有礼了",
	[":y_laoyue"] = "你可获得其他角色因使用而进入弃牌堆的【闪】。",
	["addtar"] = "目标+1",
	["addjink"] = "【闪】+1",
	["addrange"] = "攻击范围+1",
	["#addtar"] = "%from发动了技能%arg，本阶段使用【杀】可额外指定一个攻击范围内的目标",
	["#addjink"] = "%from发动了技能%arg，本阶段使用【杀】的目需额外使用一张【闪】",
	["#addrange"] = "%from发动了技能%arg，本阶段攻击范围+1",
	["designer:y_lvlingqi"] = "ByArt",
	["~y_lvlingqi"] = "父亲大人对不起",
	["#y_lvlingqi"] = "飞将之女",

	["y_puyuan"] = "蒲元[影]",
	["y_shenzhu"] = "神铸",
	["y_shenzhucard"] = "神铸",
	["y_bailian"] = "百炼",
	[":y_shenzhu"] = "出牌阶段限一次，你可弃置一张【杀】，然后从弃牌堆中选择一张装备牌置于一名角色的装备区内或选择一张【杀】获得。 ",
	["y_bailian:jink"] = "是否发动“百炼”？",
	["y_bailian:slash"] = "是否发动技能“百炼”？",
	["$y_bailian"] = "你的装备太多啦",
	["$y_shenzhu"] = "变变变",
	[":y_bailian"] = "回合外，你可将其他角色装备区内牌黑色牌当【杀】、红色牌【闪】使用或打出，然后该角色摸两张牌。",
	["designer:y_puyuan"] = "ByArt",
	["~y_puyuan"] = "江郎才尽了么？",
	["#y_puyuan"] = "铸造大师",

	["y_huangchengyan"] = "黄承彦[影]",
	["y_caipei"] = "才配",
	["y_kongzhen"] = "空阵",
	[":y_caipei"] = "每当你或女性角色使用非延时类锦囊牌选定目标时，你可令一名角色摸一张牌，然后你弃置一张牌。",
	["$y_caipei"] = "我看好你",
	["$y_kongzhen"] = "此阵可挡精兵十万",
	[":y_kongzhen"] = "每当没有手牌的角色需要响应【杀】或【闪】时，你可令其进行一次判定，若判定结果为红色，视为该角色响应了需要响应的牌。",
	["designer:y_huangchengyan"] = "ByArt",
	["~y_huangchengyan"] = "唉",
	["#y_huangchengyan"] = "沔南名士",

	["y_luji"] = "陆绩[影]",
	["y_huaiju"] = "怀橘",
	[":y_huaiju"] = "你可获得其他角色因弃置而失去的【桃】或红桃【闪】；你可令其他角色获得你因弃置而失去的【桃】或红桃【闪】",
	["y_huntian"] = "浑天",
	["y_huntian2"] = "浑天2",
	["y_huntiancard"] = "浑天",
	["@y_huntian"] = "是否发动技能【浑天】？",
	["~y_huntian"] = "选择一张手牌",
	[":y_huntian"] = "准备阶段开始时，你可将一张手牌正面朝替换牌堆顶前五张牌中的一张牌，此后，当一名角色获得牌堆中此明置的牌时，你可弃置其一张牌或令其摸一张牌。",
	["htdraw"] = "令其摸一张牌",
	["htdiscard"] = "弃置其一张牌",
	["$y_huaiju"] = "别着急哟，给我就好",
	["$y_huntian"] = "斗转星移，万物乾坤",
	["~y_luji"] = "知天命，尽人事",
	["designer:y_luji"] = "ByArt",
	["#y_luji"] = "怀橘遗亲",
	["illustrator:y_luji"] = "三国志大战",

	["y_dongbai"] = "董白[影]",
	["y_weiji"] = "未笄",
	["y_jiushang"] = "酒殇",
	[":y_weiji"] = "结束阶段开始时，若你的体力上限不为全场唯一最高，你可失去1点体力再增加1点体力上限，然后令一名角色摸X张牌。X为你当前的体力值。",
	[":y_jiushang"] = "当你需要使用酒时，你可减少1点体力上限视为使用一张【酒】。",
	["$y_jiushang"] = "酒",
	["$y_weiji"] = "哎呀！不！不可以的~",
	["designer:y_dongbai"] = "ByArt",
	["~y_dongbai"] = "去死吧变态~",
	["#y_dongbai"] = "渭阳君",
	["illustrator:y_dongbai"] = "三国志大战",

	["y_lukang"] = "陆抗[影]",
	["y_kegou"] = "克构",
	["y_xiangxi"] = "相惜",
	["y_xiangxicard"] = "相惜",
	[":y_kegou"] = "每当一名角色因【乐不思蜀】而跳过出牌阶段后，你可摸一张牌然后执行一个额外的出牌阶段。",
	[":y_xiangxi"] = "出牌阶段限一次，你可令一名其他角色选择其一个区域，你们交换该区域里的牌。若该区域为判定区，你回复1点体力。",
	["h"] = "手牌区",
	["e"] = "装备区",
	["j"] = "判定区",
	["$y_xiangxi1"] = "兼相爱，交相利",
	["$y_xiangxi2"] = "补个",
	["$y_kegou"] = "没这么简单",
	["designer:y_lukang"] = "ByArt",
	["~y_lukang"] = "我还是太年轻了",
	["#y_lukang"] = "吴末的良将",
	["illustrator:y_lukang"] = "日神",

	["y_zhouyu"] = "周瑜[影]",
	["y_yingzi"] = "英姿",
	["y_fanjian"] = "反间",
	[":y_yingzi"] = "每当一名角色于回合外因使用打出或弃置而失去一张红桃牌时，你可摸一张牌。",
	[":y_fanjian"] = "出牌阶段限一次，你可选择一张手牌，令一名其他角色展示一张手牌后获得你选择的牌并展示之，若两张展示的牌花色的不同，你可对其造成1点伤害或弃置其两张牌。",
	["$y_fanjian1"] = "挣扎吧，在血和暗的深渊里！",
	["$y_fanjian2"] = "痛苦吧，在仇与恨的地狱中！",
	["$y_yingzi1"] = "哈哈哈",
	["$y_yingzi2"] = "汝等看好了",
	["damage"] = "伤害",
	["designer:y_zhouyu"] = "ByArt",
	["~y_zhouyu"] = "既生瑜，何生。。。",
	["#y_zhouyu"] = "大都督",
	["illustrator:y_zhouyu"] = "桌游志",

	["y_sunluyu"] = "孙鲁育[影]",
	["y_shouju"] = "守矩",
	["y_wenliang"] = "温良",
	[":y_shouju"] = "每当一张装备牌或延时锦囊牌因弃置而置入弃牌堆时，你可弃置一张基本牌将该装备牌或延时锦囊牌置于一名角色的对应区域内。",
	[":y_wenliang"] = "每当你攻击范围内的角色成为【杀】的目标后，你可弃置其装备区内的一张牌令此【杀】对其无效",
	["$y_wenliang"] = "啊？这样也可以啊",
	["#y_wenliang"] = "此【杀】对%from无效",
	["#y_shouju"] = "%from发动了技能%arg",
	["$y_shouju"] = "请留步",
	["designer:y_sunluyu"] = "ByArt",
	["~y_sunluyu"] = "",
	["#y_sunluyu"] = "朱公主",
	["illustrator:y_sunluyu"] = "网络",

	["y_caifuren"] = "蔡夫人[影]",
	["y_huiyu"] = "毁誉",
	["y_xianzhou"] = "献州",
	["~y_xianzhou"] = "选择相当于体力值数量的牌交给伤害来源",
	[":y_huiyu"] = "其他角色使用牌指定你为的目标时或你使用牌指定其他角色为目标时，若为黑色非延时锦囊牌，你可摸一张牌令此锦囊牌变为【杀】。",
	[":y_xianzhou"] = "当你受到伤害时，可将相当于你体力值数量的牌交给伤害来源，防止此伤害。",
	["y_huiyu1"] = "毁誉",
	["y_huiyu2"] = "毁誉",
	["@y_xianzhou"] = "是否发动技能【献州】？",
	["#y_huiyu"] = "%from发动了技能%arg，令此锦囊变为了【杀】",
	["$y_xianzhou"] = "献荆襄九郡，图一世之安",
	["$y_huiyu1"] = "此人不露锋芒，断不可留",
	["$y_huiyu2"] = "想削我蔡氏，痴心妄想",
	["designer:y_caifuren"] = "ByArt",
	["~y_caifuren"] = "",
	["#y_caifuren"] = "襄江的蒲苇",
	["illustrator:y_caifuren"] = "网络",

	["y_liufu"] = "刘馥[影]",
	["y_zhucheng"] = "筑城",
	["y_duoqi"] = "夺气",
	[":y_zhucheng"] = "你每在一名角色的攻击范围内手牌上限便+1。",
	[":y_duoqi"] = "每角色出牌阶段限一次，当有牌被弃置时，你可模相当于此弃牌数加你已损失体力值的牌，然后将相当于此弃牌数的手牌以任意顺序置于牌堆顶。",
	["designer:y_liufu"] = "ByArt",
	["~y_liufu"] = "",
	["#y_liufu"] = "神塞护百载",
	["illustrator:y_liufu"] = "Thinking",

	["y_caojie"] = "曹节[影]",
	["y_youfang"] = "游方",
	["y_zhixi"] = "掷玺",
	["recover1"] = "令其回复1点体力",
	["draw1"] = "令其摸一张牌",
	[":y_youfang"] = "每当有角色因弃置而失去方块牌时，你可令其回复1点体力或摸一张牌。",
	[":y_zhixi"] = "你的牌将被其他角色获得或移动时，你可改为弃置。",
	["#y_zhixi"] = "将此牌改为弃置",
	["designer:y_caojie"] = "ByArt",
	["$y_zhixi"] = "岂可如此无礼",
	["$y_youfang"] = "愿尽己力，为君分忧",
	["~y_caojie"] = "",
	["#y_caojie"] = "献穆皇后",
	["illustrator:y_caojie"] = "2B铅笔",

	["y_xushi"] = "徐氏[影]",
	["y_xiaoyi"] = "晓义",
	["y_lianzhu"] = "联诛",
	[":y_xiaoyi"] = "每当你失去装备区的牌时，你可亮出牌堆顶的一张牌令一名角色获得，若为基本牌，你重复此流程。",
	[":y_lianzhu"] = "出牌阶段限一次，你可弃置任意数量的牌并指定等量的角色这些角色各选择：摸一张牌或使用一张杀。",
	["@y_lianzhu-slash"] = "请使用一张杀，点取消则一张牌",
	["designer:y_xushi"] = "ByArt",
	["~y_xushi"] = "",
	["#y_xushi"] = "东吴女丈夫",
	["illustrator:y_xushi"] = "阿端",

	["y_xushu"] = "徐庶[影]",
	["y_wuyan"] = "无言",
	[":y_wuyan"] = "手牌数不小于你的其他角色使用的非延时锦囊牌不能指定你为目标，你使用的非延时锦囊牌不能指定手牌数小于你的角色为目标。",
	["designer:y_xushu"] = "ByArt",
	["~y_xushu"] = "",
	["#y_xushu"] = "忠孝的侠士",
	["illustrator:y_xushu"] = "XINA",

	["y_xinxianying"] = "辛宪英[影]",
	["&y_fanjin"] = "锦",
	["y_fanjin"] = "翻锦",
	["y_mingjian"] = "明鉴",
	[":y_fanjin"] = "每角色回合限一次，你造成或受到一次杀的伤害后，可明置其他角色的一张手牌。你可如手牌般使用或打出此明置手牌。\
	<font color=\"purple\"><b>(不完全实现）</b></font>",
	[":y_mingjian"] = "你可随时观看你攻击范围内的角色的手牌。\
	<font color=\"purple\"><b>(实现部分，出牌阶段空闲点观看，拆、顺选牌时可见。发动“翻锦”选牌时可见。)</b></font>",
	["designer:y_xinxianying"] = "ByArt",
	["~y_xinxianying"] = "",
	["#y_xinxianying"] = "蕙质兰心",
	["illustrator:y_xinxianying"] = "玫芍之言",
}
return { extension }
