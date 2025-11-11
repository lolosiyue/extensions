module("extensions.newstar", package.seeall)
extension = sgs.Package("newstar")

xingcaocao = sgs.General(extension, "xingcaocao", "wei", 3)
--星包曹操

LuaNengchen_TM = sgs.CreateTargetModSkill {
	name = "#LuaNengchen_TM",
	pattern = "TrickCard",
	extra_target_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:isNDTrick() then
			return 1
		end
	end,
}



LuaNengchen = sgs.CreateViewAsSkill {
	name = "LuaNengchen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card_id = sgs.Self:getMark("luanengchenskill")
		local card = sgs.Sanguosha:getCard(card_id)
		local acard = cards[1]
		local new_card = sgs.Sanguosha:cloneCard(card:objectName(), acard:getSuit(), acard:getNumber())
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return player:hasFlag("jx")
	end,
}


luanengchenskill = sgs.CreateTriggerSkill {
	name = "#luanengchenskill",
	view_as_skill = LuaNengchen,
	events = { sgs.CardUsed },
	frequency = sgs.Skill_Frequency,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardUse().card
		if (player:getPhase() ~= sgs.Player_Play) then return false end
		if event == sgs.CardUsed and not player:hasFlag("jxused") and not card:isKindOf("Nullification") and not card:isKindOf("IronChain") then
			if card:isNDTrick() then
				room:setPlayerFlag(player, "jx")
				if not card:isVirtualCard() then
					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "LuaNengchen") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
					end
					room:setPlayerMark(player, "&LuaNengchen+" .. card:objectName() .. "-".. player:getPhase() .."Clear", 1)

					local card_id = card:getEffectiveId()
					room:setPlayerMark(player, "luanengchenskill", card_id)
				end
				if card:getSkillName() == "LuaNengchen" then
					room:setPlayerFlag(player, "jxused")
					room:setPlayerFlag(player, "-jx")
				end
			end
		end
	end
}


LuaJianxiong = sgs.CreateTriggerSkill {
	name = "LuaJianxiong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local x = player:getLostHp()
			local choices = { "LuaJianxiongdraw=" .. x }
			local card = damage.card
			local card_str = ""
			if card then
				local ids = sgs.IntList()
				if card:isVirtualCard() then
					card_str = card:objectName()
					ids = card:getSubcards()
				else
					ids:append(card:getEffectiveId())
					card_str = card:objectName()
				end
				if ids:length() > 0 then
					local all_place_table = true
					for _, id in sgs.qlist(ids) do
						if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
							all_place_table = false
							break
						end
					end
					if all_place_table then
						table.insert(choices, "LuaJianxiongobtain=" .. card_str)
					end
				end
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
			if choice ~= "cancel" then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke("LuaJianxiong")
				if string.startsWith(choice, "LuaJianxiongobtain") then
					player:obtainCard(card)
				else
					player:drawCards(x, self:objectName())
				end
			end
		end
	end
}


xingcaocao:addSkill(LuaNengchen)
xingcaocao:addSkill(LuaNengchen_TM)
xingcaocao:addSkill(luanengchenskill)
extension:insertRelatedSkills("LuaNengchen", "#LuaNengchen_TM")
extension:insertRelatedSkills("LuaNengchen", "#luanengchenskill")
xingcaocao:addSkill(LuaJianxiong)









xingguojia = sgs.General(extension, "xingguojia", "wei", 3)
--星包郭嘉
LuaXinyijicard = sgs.CreateSkillCard {
	name = "LuaXinyiji",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		source:addToPile("ji", self)
	end
}
LuaXinyijiVS = sgs.CreateViewAsSkill {
	name = "LuaXinyiji",
	response_pattern = "@@LuaXinyiji",
	n = 1,
	view_filter = function(self, selected, to_select)
		local suit = {}
		for _, card_id in sgs.qlist(sgs.Self:getPile("ji")) do
			local card = sgs.Sanguosha:getCard(card_id)
			table.insert(suit, card:getSuitString())
		end
		return not to_select:isEquipped() and (not table.contains(suit, to_select:getSuitString()))
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local snatch = LuaXinyijicard:clone()
			snatch:addSubcard(cards[1])
			snatch:setSkillName(self:objectName())
			return snatch
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
LuaXinyiji = sgs.CreateTriggerSkill {
	name = "LuaXinyiji",
	frequency = sgs.NotFrequent,
	events = { sgs.Damaged, sgs.EventPhaseEnd },
	view_as_skill = LuaXinyijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local ji = player:getPile("ji")
		local n = ji:length()
		if player:getPhase() == sgs.Player_Start and n < 4 then
			if not player:isKongcheng() then
				if player:getRoom():askForUseCard(player, "@@LuaXinyiji", "@LuaXinyiji-card", -1, sgs.Card_MethodNone) then
					room:broadcastSkillInvoke("LuaXinyiji")
				end
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 1, x, 1 do
				if room:askForSkillInvoke(player, "LuaXinyiji", data) then
					room:drawCards(player, 2)
					room:broadcastSkillInvoke("LuaXinyiji")
					if not player:isKongcheng() then
						player:getRoom():askForUseCard(player, "@@LuaXinyiji", "@LuaXinyiji-card", -1,
							sgs.Card_MethodNone)
					end
				end
			end
		end
	end
}

LuaJuececard = sgs.CreateSkillCard {
	name = "LuaJuece",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local damage = source:getTag("LuaJueceDamage"):toDamage()
		local victim = damage.to
		local dest = damage.from
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaJuece",
			"");
		room:throwCard(self, reason, nil)
		room:addPlayerMark(source, "&LuaJuece-Clear")
		local suit = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit()
		if suit == sgs.Card_Club then
			local x = victim:getLostHp()
			victim:drawCards(x + 1)
			if victim:isNude() then return false end
			room:askForDiscard(victim, self:objectName(), x, x, false, true)
			if dest and dest:isAlive() then
				local count = dest:getCardCount(true)
				if count > 0 then
					room:askForDiscard(dest, self:objectName(), x, x, false, true)
				end
			end
		elseif suit == sgs.Card_Spade then
			if dest and dest:isAlive() and not dest:isNude() then
				local card_id = room:askForCardChosen(source, dest, "he", "LuaJuece")
				if (room:getCardPlace(card_id) == sgs.Player_Hand) then
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), source, sgs.Player_Hand, false)
				else
					room:obtainCard(source, card_id, false)
				end
			end
		elseif suit == sgs.Card_Heart then
			if dest and dest:isAlive() then
				room:damage(sgs.DamageStruct("LuaJuece", source, dest))
			end
		elseif suit == sgs.Card_Diamond then
			if dest and dest:isAlive() then
				local count = dest:getLostHp() + 1
				dest:drawCards(count)
				dest:turnOver()
			end
		end
	end
}
LuaJueceVS = sgs.CreateOneCardViewAsSkill {
	name = "LuaJuece",
	response_pattern = "@@LuaJuece",
	expand_pile = "ji",
	filter_pattern = ".|.|.|ji",
	view_as = function(self, originalCard)
		local snatch = LuaJuececard:clone()
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end,

	enabled_at_play = function(self, player)
		return false
	end,
}
LuaJuece = sgs.CreateTriggerSkill {
	name = "LuaJuece",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.EventPhaseEnd },
	view_as_skill = LuaJueceVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local victim = damage.to
			if not victim:isDead() then
				local splayers = room:findPlayersBySkillName(self:objectName())
				for _, guojia in sgs.qlist(splayers) do
					guojia:setTag("LuaJueceDamage", data)
					if guojia:getPile("ji"):length() > 0 and guojia:getMark("&LuaJuece-Clear") == 0 then
						room:askForUseCard(guojia, "@@LuaJuece", "@LuaJuece-card", -1, sgs.Card_MethodDiscard)
					end
					guojia:removeTag("LuaJueceDamage")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}



xingguojia:addSkill(LuaXinyiji)
xingguojia:addSkill(LuaJuece)







xingsimayi = sgs.General(extension, "xingsimayi", "wei", 3)
--星包司马懿

LuaGuizha = sgs.CreateTriggerSkill {
	name = "LuaGuizha",
	events = { sgs.AskForRetrial },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isNude() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@LuaGuizha-card",
			judge.who:objectName(),
			self:objectName(),
			judge.reason,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local askforcardpattern = ".."
		local card = room:askForCard(player, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
			room:broadcastSkillInvoke("LuaGuizha")
		end
		return false
	end

}

LuaQuanbian = sgs.CreateTriggerSkill {
	name = "LuaQuanbian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage, sgs.Damaged },

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local from = data:toDamage().from
			local damage = data:toDamage()
			local x = damage.damage
			local data = sgs.QVariant(0)
			data:setValue(from)
			for i = 1, x, 1 do
				if (from and (not from:isNude()) and room:askForSkillInvoke(player, "LuaQuanbian", data)) then
					local card_id = room:askForCardChosen(player, from, "he", "LuaQuanbian")
					if (room:getCardPlace(card_id) == sgs.Player_Hand) then
						room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_Hand, false)
					else
						room:obtainCard(player, card_id, false)
					end
					room:broadcastSkillInvoke("LuaQuanbian")
				end
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			local from = damage.to
			local x = damage.damage
			local data = sgs.QVariant(0)
			data:setValue(from)
			if (from and from:getEquips():length() > 0 and room:askForSkillInvoke(player, "LuaQuanbian", data)) then
				local card_id = room:askForCardChosen(player, from, "e", "LuaQuanbian")
				if (room:getCardPlace(card_id) == sgs.Player_Hand) then
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_Hand, false)
				else
					room:obtainCard(player, card_id)
				end
				room:broadcastSkillInvoke("LuaQuanbian")
			end
		end
	end

}



xingsimayi:addSkill(LuaGuizha)
xingsimayi:addSkill(LuaQuanbian)







xingzhugeliang = sgs.General(extension, "xingzhugeliang", "shu", 3)
--星诸葛亮

LuaDongchaB = sgs.CreateTriggerSkill {
	name = "#LuaDongchaB",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Nullification") then
			player:drawCards(1)
		end
	end
}

LuaNixing = sgs.CreateTriggerSkill {
	name = "LuaNixing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("LuaNixing")
				local count3 = player:getHp()
				local x = 8
				if count3 > 0 then
					x = 8 - count3;
				end
				local stars = room:getNCards(x)
				if x > 0 then
					room:askForGuanxing(player, stars)
				end
			end
		end
		return false
	end
}

LuaDongcha = sgs.CreateViewAsSkill {
	name = "LuaDongcha",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local ncard = sgs.Sanguosha:cloneCard("nullification", suit, point)
			ncard:addSubcard(card)
			ncard:setSkillName(self:objectName())
			return ncard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "nullification"
	end,
	enabled_at_nullification = function(self, player)
		local handcards = player:getHandcards()
		for _, card in sgs.qlist(handcards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
			if card:objectName() == "nullification" then
				return true
			end
		end
		local cards = player:getEquips()
		for _, card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		return false
	end
}

LuaNixingEx = sgs.CreateTriggerSkill {
	name = "#LuaNixingEx",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason~="draw_phase" then return end
		local y = player:getHp()
		if (8 - y) >= 7 then
			draw.num = draw.num+1
			room:sendCompulsoryTriggerLog(player, "LuaDongcha", true, true)
			data:setValue(draw)
		end
	end
}

xingzhugeliang:addSkill(LuaDongcha)
xingzhugeliang:addSkill(LuaDongchaB)
xingzhugeliang:addSkill(LuaNixing)
xingzhugeliang:addSkill(LuaNixingEx)
extension:insertRelatedSkills("LuaDongcha", "#LuaDongchaB")
extension:insertRelatedSkills("LuaNixing", "#LuaNixingEx")





xingzhaoyun = sgs.General(extension, "xingzhaoyun", "shu", 3)
--星包赵云

sgs.LuaLongzhenPattern = { "pattern" }
LuaLongzhen = sgs.CreateViewAsSkill {
	name = "LuaLongzhen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.LuaLongzhenPattern[1]
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			sgs.LuaLongzhenPattern = { "slash" }
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "jink" or pattern == "slash" then
			sgs.LuaLongzhenPattern = { pattern }
			return true
		end
		return false
	end
}


LuaChongzhen = sgs.CreateTriggerSkill {
	name = "#LuaChongzhen",
	events = { sgs.CardResponded, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:getSkillName() == "LuaLongzhen" or resp.m_card:isKindOf("Jink") or resp.m_card:isKindOf("Slash") or resp.m_card:isKindOf("FireSlash") or resp.m_card:isKindOf("ThunderSlash")) and resp.m_who and (not resp.m_who:isKongcheng()) then
				room:broadcastSkillInvoke("#LuaChongzhen")
				local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
				resp.m_who:setFlags("LuaChongzhenTarget")
				if player:askForSkillInvoke(self:objectName(), _data) then
					local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
				end
				resp.m_who:setFlags("-LuaChongzhenTarget")
			end
		else
			local use = data:toCardUse()
			if ((use.from:objectName() == player:objectName()) and (use.card:getSkillName() == "LuaLongzhen" or use.card:isKindOf("Slash") or use.card:isKindOf("FireSlash") or use.card:isKindOf("ThunderSlash"))) then
				for _, p in sgs.qlist(use.to) do
					if p:isNude() then continue end
					local _data = sgs.QVariant()
					_data:setValue(p)
					p:setFlags("LuaChongzhenTarget")
					local invoke = nil
					if not player:hasFlag("LuaChongzhenTarget") then
						invoke = player:askForSkillInvoke(self:objectName(), _data)
					end
					p:setFlags("-LuaChongzhenTarget")
					if invoke then
						room:broadcastSkillInvoke("#LuaChongzhen")
						local card_id = room:askForCardChosen(player, p, "he", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
				end
			end
		end
		return false
	end
}



xingzhaoyun:addSkill(LuaLongzhen)
xingzhaoyun:addSkill(LuaChongzhen)
extension:insertRelatedSkills("LuaLongzhen", "#LuaChongzhen")





xingzhouyu = sgs.General(extension, "xingzhouyu", "wu", 3)
--星包周瑜


LuaFanjianCard = sgs.CreateSkillCard {
	name = "LuaFanjianCard",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "LuaFanjian")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = target
		log.arg = sgs.Card_Suit2String(suit)
		room:sendLog(log)
		room:broadcastSkillInvoke("LuaFanjian")
		room:getThread():delay()
		target:obtainCard(self)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			local count1 = source:getHandcardNum()
			local count = target:getHandcardNum()
			if count1 + count1 < count then
				target:throwAllHandCards()
			else
				room:showAllCards(target)
				target:throwAllEquips()
			end
		else
			room:loseHp(target, 1)
		end
	end
}
LuaFanjian = sgs.CreateViewAsSkill {
	name = "LuaFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaFanjianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaFanjianCard")
		end
		return false
	end
}

xingzhouyu:addSkill("yingzi")
xingzhouyu:addSkill(LuaFanjian)






xingluxun = sgs.General(extension, "xingluxun", "wu", 3)
--星包陆逊

LuaRusheng = sgs.CreateProhibitSkill {
	name = "LuaRusheng",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence"))
	end
}


LuaXiongcai = sgs.CreateTriggerSkill {
	name = "LuaXiongcai",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local num = player:getHandcardNum()
		local lost = 3
		if num >= lost then return end
		if player:getPhase() ~= sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() then
					room:sendCompulsoryTriggerLog(player, "LuaXiongcai", true)
					player:drawCards(lost - num)
					room:broadcastSkillInvoke("LuaXiongcai")
				end
			end
		end
	end
}

xingluxun:addSkill(LuaRusheng)
xingluxun:addSkill(LuaXiongcai)




xinglvbu = sgs.General(extension, "xinglvbu", "qun", 4)
--星包吕布

LuaShenji = sgs.CreateTargetModSkill {
	name = "#LuaShenji",
	extra_target_func = function(self, from, card)
		if from:hasSkill("LuaGuishen") and (card:isRed()) then
			local count = math.min(from:getLostHp() + 1, 2)
			return count
		else
			return 0
		end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaGuishen") and (card:isBlack()) then
			return 1000
		else
			return 0
		end
	end
}

LuaGuishen = sgs.CreateViewAsSkill {
	name = "LuaGuishen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) and sgs.Self:getWeapon()
			and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId()) and to_select:isKindOf("Crossbow") then
			return sgs.Self:canSlashWithoutCrossbow()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card:getId())
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaWushuang = sgs.CreateTriggerSkill {
	name = "#LuaWushuang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local can_invoke = false
			local room = player:getRoom()
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				room:broadcastSkillInvoke("wushuang")
				room:sendCompulsoryTriggerLog(player, "LuaGuishen", true)
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

xinglvbu:addSkill(LuaShenji)
xinglvbu:addSkill(LuaGuishen)
extension:insertRelatedSkills("LuaGuishen", "#LuaShenji")
xinglvbu:addSkill(LuaWushuang)
extension:insertRelatedSkills("LuaGuishen", "#LuaWushuang")



xingzhaoyun_o = sgs.General(extension, "xingzhaoyun_o", "shu", 3)
mobanzhaoyun = sgs.General(extension, "mobanzhaoyun", "shu", 3, true, true, true)
--星赵云
sgs.LongdanPattern = { "pattern" }
LuaLongzhen_o = sgs.CreateViewAsSkill {
	name = "LuaLongzhen_o",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.LongdanPattern[1]
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			sgs.LongdanPattern = { "slash" }
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "jink" or pattern == "slash" then
			sgs.LongdanPattern = { pattern }
			return true
		end
		return false
	end
}

LuaChongzhen_o = sgs.CreateTriggerSkill {
	name = "#LuaChongzhen_o",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardResponded, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			local dest = resp.m_who
			local card = resp.m_card
			if card:getSkillName() == "LuaLongzhen_o" then
				if dest and not dest:isKongcheng() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(dest)
					if player:askForSkillInvoke("LuaLongzhen_o", ai_data) then
						card_id = room:askForCardChosen(player, dest, "h", "LuaLongzhen_o")
						local destcard = sgs.Sanguosha:getCard(card_id)
						room:obtainCard(player, destcard)
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
				if use.card:getSkillName() == "LuaLongzhen_o" then
					local targets = use.to
					for _, dest in sgs.qlist(targets) do
						if not dest:isKongcheng() then
							local ai_data = sgs.QVariant()
							ai_data:setValue(dest)
							if player:askForSkillInvoke("LuaLongzhen_o", ai_data) then
								local card_id = room:askForCardChosen(player, dest, "h", "LuaLongzhen_o")
								local destcard = sgs.Sanguosha:getCard(card_id)
								room:obtainCard(player, destcard)
							end
						end
					end
				end
			end
		end
		return false
	end
}

LuaXDuojian = sgs.CreateTriggerSkill {
	name = "#LuaXDuojian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _, p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "QinggangSword" then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:obtainCard(weapon)
					end
				end
			end
		end
		return false
	end
}



listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
LuaLongwei = sgs.CreateTriggerSkill {
	name = "LuaLongwei",
	frequency = sgs.Skill_Frequent,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile)
			and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				or (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
			local card_ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				if (sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Diamond or sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Heart)
					and (((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)
							and (move.from_places:at(i) == sgs.Player_PlaceJudge)
							and (move.to_place == sgs.Player_DiscardPile))
						or ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE)
							and (room:getCardOwner(card_id):objectName() == move.from:objectName())
							and ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip)))) then
					card_ids:append(card_id)
				end
				i = i + 1
			end
			if card_ids:isEmpty() then
				return false
			elseif player:askForSkillInvoke(self:objectName(), data) then
				if not card_ids:length() == 1 then
					while not card_ids:isEmpty() do
						room:fillAG(card_ids, player)
						local id = room:askForAG(player, card_ids, true, self:objectName())
						if id == -1 then
							room:clearAG(player)
							break
						end
						card_ids:removeOne(id)
						room:clearAG(player)
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not card_ids:isEmpty() then
					for _, id in sgs.qlist(card_ids) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						dummy:addSubcard(id)
						--room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
					end
				end
				room:obtainCard(player, dummy)
				dummy:deleteLater()
			end
		end
		return false
	end
}


LuaShenyong = sgs.CreateTriggerSkill {
	name = "LuaShenyong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local source = effect.from
		local dest = effect.to
		if effect.card:isKindOf("Slash") and dest:isAlive() then
			if not dest:isNude() then
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = source:getRoom()
					room:broadcastSkillInvoke("LuaShenyong")
					local prompt = string.format("@tiaoxin-slash:%s", source:objectName())
					if not room:askForUseSlashTo(dest, source, prompt) then
						if player:canDiscard(dest, "he") then
							local chosen = room:askForCardChosen(source, dest, "he", self:objectName())
							room:throwCard(chosen, dest, source)
						end
					end
				end
			end
		end
		return false
	end,
	priority = 2
}

LuaJuejing = sgs.CreateTriggerSkill {
	name = "LuaJuejing",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:hasSkill(self:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				for _, rh in sgs.qlist(player:handCards()) do
					if not move.card_ids:contains(rh) then return end
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return end
				player:removeMark(self:objectName())
				if not room:askForSkillInvoke(player, self:objectName(), data) then return end
				room:broadcastSkillInvoke("LuaJuejing");
				if room:changeMaxHpForAwakenSkill(player) then
					room:handleAcquireDetachSkills(player, "LuaLongwei|-LuaJuejing|-LuaShenyong")
					room:addMaxCards(player, 1, false)
					room:addPlayerMark(player, "&LuaJuejing")
					player:drawCards(4)
				end
			end
		end
	end,
}

mobanzhaoyun:addSkill(LuaLongwei)


xingzhaoyun_o:addSkill(LuaXDuojian)
xingzhaoyun_o:addSkill(LuaJuejing)
xingzhaoyun_o:addSkill(LuaShenyong)
xingzhaoyun_o:addSkill(LuaLongzhen_o)
xingzhaoyun_o:addSkill(LuaChongzhen_o)
xingzhaoyun_o:addRelateSkill("LuaLongwei")
extension:insertRelatedSkills("LuaLongzhen_o", "#LuaChongzhen_o")
extension:insertRelatedSkills("LuaShenyong", "#LuaXDuojian")

mubanXlubu = sgs.General(extension, "mubanXlubu", "qun", 4, true, true, true)


exshenji = sgs.CreateTriggerSkill {
	name = "exshenji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards(2)
				room:broadcastSkillInvoke("exshenji")
			end
		end
	end
}
xingLuashenji = sgs.CreateTriggerSkill {
	name = "xingLuashenji",
	frequency = sgs.Skill_Wake,
	waked_skills = "exshenji",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				Exchange1(player)
				room:addPlayerMark(player, self:objectName())
			end
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			if player:canWake(self:objectName()) then return true end
			if player:getPile("wrath"):length() > 2 then return true end
		end


		return false
	end,
}
mubanXlubu:addSkill(exshenji)
mubanXlubu:addSkill(xingLuashenji)

xinglvbu_o = sgs.General(extension, "xinglvbu_o", "qun", 4)


LuaMashu = sgs.CreateDistanceSkill {
	name = "#LuaMashu",
	correct_func = function(self, from, to)
		if from:hasSkill("#LuaMashu") then
			return -1
		end
	end,
}

--赤兔
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
os_chitu = sgs.CreateTriggerSkill {
	name = "os_chitu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}

--画戟
LuaHuaji = sgs.CreateTriggerSkill {
	name = "LuaHuaji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local wrath = player:getPile("wrath")
		local damage = data:toDamage()
		local x = damage.damage
		local n = wrath:length()
		if n < 3 then
			if n + x > 3 then
				x = 1
			end
			if x < 1 then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				for i = 1, x, 1 do
					room:drawCards(player, 1)
					room:broadcastSkillInvoke("LuaHuaji")
					if not player:isKongcheng() then
						local card_id = -1
						local handcards = player:handCards()
						if handcards:length() == 1 then
							room:getThread():delay(500)
							card_id = handcards:first()
						else
							local cards = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush")
							card_id = cards:getSubcards():first()
						end
						player:addToPile("wrath", card_id)
					end
				end
			end
		end
	end
}



Exchange1 = function(xinglvbu)
	local wrath = xinglvbu:getPile("wrath")
	if wrath:length() > 0 then
		local room = xinglvbu:getRoom()
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(xinglvbu:getPile("wrath")) do
			dummy:addSubcard(cd)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "LuaBaonu", "")
		room:throwCard(dummy, reason, nil)
		dummy:deleteLater()

		room:broadcastSkillInvoke("LuaBaonu")
		if xinglvbu:hasSkill("xingLuashenji") then
			if room:changeMaxHpForAwakenSkill(xinglvbu) then
				room:addMaxCards(xinglvbu, 1, false)
				room:handleAcquireDetachSkills(xinglvbu, "exshenji")
				room:handleAcquireDetachSkills(xinglvbu, "-LuaBaonu")
				room:handleAcquireDetachSkills(xinglvbu, "-LuaHuaji")
			end
		else
			if room:changeMaxHpForAwakenSkill(xinglvbu) then
				room:addMaxCards(xinglvbu, 1, false)
				room:handleAcquireDetachSkills(xinglvbu, "xingLuashenji")
			end
		end
	end
end

LuaBaonu = sgs.CreateTriggerSkill {
	name = "LuaBaonu",
	frequency = sgs.Skill_Wake,
	waked_skills = "xingLuashenji",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				Exchange1(player)
				room:addPlayerMark(player, self:objectName())
			end
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			if player:canWake(self:objectName()) then return true end
			if player:getPile("wrath"):length() > 2 then return true end
		end


		return false
	end,
}



xinglvbu_o:addSkill(LuaMashu)
xinglvbu_o:addSkill(os_chitu)
extension:insertRelatedSkills("os_chitu", "#LuaMashu")
xinglvbu_o:addSkill(LuaHuaji)
xinglvbu_o:addSkill(LuaBaonu)


sgs.LoadTranslationTable {
	["newstar"] = "星包",
	["xingcaocao"] = "星曹操",
	["#xingcaocao"] = "乱世奸雄",
	["LuaNengchen"] = "能臣",
	[":LuaNengchen"] = "你使用的非延时类锦囊可额外指定一个目标。<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张牌当作本阶段出的上一张非延时类锦囊牌使用。",
	["$LuaNengchen1"] = "以其人之道还治其身",
	["$LuaNengchen2"] = "再来啊",
	["LuaJianxiong"] = "奸雄",
	[":LuaJianxiong"] = "当你受到伤害后，你可以选择一项：获得对你造成伤害的牌，或摸x张牌。(X为你已损失的体力值)",
	["LuaJianxiongdraw"] = "摸 %src 张牌",
	["LuaJianxiongobtain"] = "获得 %src ",
	["$LuaJianxiong1"] = "我好梦中杀人",
	["$LuaJianxiong2"] = "宁教我负天下人，休教天下人负我",
	["~xingcaocao"] = "世人皆看错我曹操",


	["xingguojia"] = "星郭嘉",
	["#xingguojia"] = "天妒英才",
	["LuaXinyiji"] = "遗计",
	[":LuaXinyiji"] = "准备阶段开始时，你可将一张手牌置于武将牌上；每当你受到1点伤害后，你可以摸两张牌，然后将一张牌手牌置于武将牌上。置于武将牌上的牌称为“计”。(“计”至多为4张，且花色不可重复。) ",
	["$LuaXinyiji1"] = "就这样吧",
	["$LuaXinyiji2"] = "哦",
	["LuaJuece"] = "决策",
	["@LuaJuece-card"] = "你可以弃置一张“计”",
	["~LuaJuece"] = "选择一张“计”",
	[":LuaJuece"] = "每当一名角色受到伤害后，你可以将一张“计”置入弃牌堆，若该张“计”花色为♥，伤害来源受到你对其一点伤害；♦，伤害来源摸x+1牌（X为其已损失的体力值），然后翻面；♣，受伤角色摸x+1张牌再弃置x张牌，然后伤害来源弃置x张牌，（X为受伤角色已损失的体力值）；♠，你获得伤害来源一张牌。<font color=\"green\"><b>每名角色的回合限一次</b></font>。 ",
	["$LuaJuece1"] = "也好",
	["$LuaJuece2"] = "罢了",
	["ji"] = "计",
	["luaxinyiji"] = "遗计",
	["@LuaXinyiji-card"] = "你可将一张手牌置于武将牌上",
	["~LuaXinyiji"] = "选择一张的手牌",
	["LuaJueceR"] = "请弃掉x张牌 （x为你失去的体力加一）",
	["LuaJueceR1"] = "请弃掉x张牌 （x为受伤角色失去的体力）",
	["~xingguojia"] = "咳嗽~~",
	["luajuece"] = "决策",


	["xingsimayi"] = "星司马懿",
	["#xingsimayi"] = "鬼神莫测",
	["#LuaGuizhaVS"] = "鬼诈",
	["LuaGuizha"] = "鬼诈",
	["$LuaGuizha1"] = "天命，哈哈哈哈哈哈哈哈",
	["$LuaGuizha2"] = "吾乃天命之子",
	[":LuaGuizha"] = "当一名角色的判定牌生效前，你可以打出一张牌替换之。 ",
	["~LuaGuizha"] = "请选择一张牌，替换当前判定牌",
	["@LuaGuizha-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
	["LuaQuanbian"] = "权变",
	[":LuaQuanbian"] = "当你受到一点伤害后，你可以获得伤害来源一张牌。当你造成伤害后，你可以获得伤害目标装备区里一张牌。",
	["$LuaQuanbian1"] = "下次注意点儿",
	["$LuaQuanbian2"] = "出来混，迟早是要还的",
	["~xingsimayi"] = "难道真是天命难为",


	["xingzhugeliang"] = "星诸葛亮",
	["#xingzhugeliang"] = "经天纬地",
	["LuaDongcha"] = "洞察",
	[":LuaDongcha"] = "你可以将一张黑桃花色的牌当【无懈可击】使用。你每使用一张【无懈可击】，摸一张牌。 ",
	["$LuaDongcha1"] = "雕虫小技",
	["$LuaDongcha2"] = "你的计谋被识破了",
	["LuaNixing"] = "逆星",
	[":LuaNixing"] = "准备阶段开始时，你可以观看牌堆顶的X张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。摸牌阶段若X等于7，你额外摸1张牌。（X为8-你已损失的体力值，至多为7）",
	["$LuaNixing1"] = "伏望天恩，誓讨汉贼",
	["$LuaNixing2"] = "祈星辰之力，佑我蜀汉",
	["~xingzhugeliang"] = "我的计谋竟被~",


	["xingzhaoyun"] = "星赵云",
	["#xingzhaoyun"] = "浑身是胆",
	["LuaLongzhen"] = "龙阵",
	[":LuaLongzhen"] = "你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。每当使用或打出一张【杀】/【闪】时，你可以获得对方的一张牌/手牌。",
	["#LuaChongzhen"] = "龙阵",
	["$LuaLongzhen1"] = "能进能退，乃真正法器",
	["$LuaLongzhen2"] = "吾乃常山赵子龙也",
	["~xingzhaoyun"] = "这就是失败的滋味吗",


	["xingzhouyu"] = "星周瑜",
	["#xingzhouyu"] = "乱世俊杰",
	--[[["LuaYingcai"] = "英才",
	[":LuaYingcai"] =
	"摸牌阶段，你可以额外摸1张牌；你的手牌上限不会因为你的血量而改变。 ",
	["$LuaYingcai1"] = "汝等看好了",
	["$LuaYingcai2"] = "哈哈哈哈",]]
	["LuaFanjian"] = "反间",
	[":LuaFanjian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一张手牌，令一名其他角色说出一种花色后展示并获得之，若猜对则其流失1点体力；若猜错且其手牌大于你的手牌的2倍，其弃掉所有手牌；否则其展示所有手牌，并弃掉所有装备。",
	["$LuaFanjian1"] = "挣扎吧，在血和暗的深渊里",
	["$LuaFanjian2"] = "痛苦吧，在仇与恨的地狱中",
	["~xingzhouyu"] = "逝者不死，浴火重生",
	["luafanjian"] = "反间",


	["xingluxun"] = "星陆逊",
	["#xingluxun"] = "出将入相",
	["LuaRusheng"] = "儒生",
	[":LuaRusheng"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能成为【乐不思蜀】和【顺手牵羊】的目标。",
	["LuaXiongcai"] = "雄才",
	[":LuaXiongcai"] = "<font color=\"blue\"><b>锁定技，</b></font>弃牌阶段外，当你的手牌数小于3时，你将手牌补至3张。 ",
	["$LuaXiongcai1"] = "牌不是万能的，但是没牌是万万不能的",
	["$LuaXiongcai2"] = "旧的不去，新的不来",
	["~xingluxun"] = "主公，伯言终没有负了对你的承诺",


	["xinglvbu"] = "星吕布",
	["#xinglvbu"] = "乱世猛将",
	["LuaGuishen"] = "鬼神",
	[":LuaGuishen"] = "你可以将一张手牌当【杀】使用或打出；你的黑【杀】无视距离；红【杀】可额外指定x个目标(X为你已损失的体力值+1，至多为2)；当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消。",
	["$LuaGuishen1"] = "看我神威，无坚不摧",
	["$LuaGuishen2"] = "天王老子也保不住你",
	["~xinglvbu"] = "不可能~~",


	["xingzhaoyun_o"] = "星赵云0224",
	["&xingzhaoyun_o"] = "星赵云",
	["#xingzhaoyun_o"] = "浑身是胆",
	["LuaLongzhen_o"] = "龙阵",
	[":LuaLongzhen_o"] = "你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。每当你发动“龙阵”使用或打出一张手牌时，你可以获得对方的一张手牌。",
	["LuaChongzhen_o"] = "龙阵",
	["$LuaLongzhen_o1"] = "能进能退，乃真正法器",
	["$LuaLongzhen_o2"] = "吾乃常山赵子龙也",
	["LuaShenyong"] = "神勇",
	["#LuaXDuojian"] = "神勇",
	[":LuaShenyong"] = "当你使用的【杀】被目标角色的【闪】抵消时，你可以令其对你使用一张【杀】，否则弃置其一张牌。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。",
	["$LuaShenyong1"] = "贼将休走，可敢与我一战",
	["$LuaShenyong2"] = "陷阵杀敌，一马当先",
	["LuaJuejing"] = "绝境",
	[":LuaJuejing"] = "当你失去最后的手牌时，你可以减1点体力上限，失去技能“神勇”、“绝境”，手牌上限+1，然后摸四张牌，获得技能“神威”。（当其他角色的方片牌和红桃牌因弃置或判定而置入弃牌堆时，你可以获得之。） ",
	["$LuaJuejing"] = "龙战于野，其血玄黄",
	["LuaLongwei"] = "龙威",
	[":LuaLongwei"] = "当其他角色的方片牌和红桃牌因弃置或判定而置入弃牌堆时，你可以获得之。",
	["~xingzhaoyun_o"] = "这就是失败的滋味吗",

	["exyingzi"] = "EX英姿",
	["chitu"] = "赤兔",
	["LuaShenjiHid"] = "神戟",
	["LuaShenji"] = "神戟",

	["xinglvbu_o"] = "星吕布0224",
	["&xinglvbu_o"] = "星吕布",
	["#xinglvbu_o"] = "乱世猛将",
	["os_chitu"] = "赤兔",
	[":os_chitu"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你指定【杀】的目标后，目标角色须使用两张【闪】抵消此【杀】；你与其他角色计算距离时，始终-1。",
	["LuaBaonu"] = "暴怒",
	[":LuaBaonu"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段或结束阶段开始时，若“戟”等于三张，将“戟”置入弃牌堆，你失去1点体力上限，手牌上限+1，获得“神戟”。<font color=\"purple\"><b>觉醒技，</b></font>准备阶段或结束阶段开始时，若“戟”等于三张，若你已有技能“神戟”，将“戟”置入弃牌堆，你失去1点体力上限，失去技能“暴怒”、“画戟”，手牌上限+1，获得“神迹”。",
	["$LuaBaonu1"] = "凡人们，颤抖吧，这是神之怒火！",
	["$LuaBaonu2"] = "这，才是活生生的地狱！",
	["LuaHuaji"] = "画戟",
	[":LuaHuaji"] = "当你受到或造成1点伤害后，你可以摸一张牌，然后将一张手牌置于你的武将牌上，称为“戟”。◆戟是移出游戏的牌，至多为三。",
	["$LuaHuaji1"] = "神挡杀神，佛挡杀佛！",
	["$LuaHuaji2"] = "谁能当我！",
	["xingLuashenji"] = "神戟",
	[":xingLuashenji"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段或结束阶段开始时，若“戟”等于三张，若你已有技能“神戟”，将“戟”置入弃牌堆，你失去1点体力上限，失去技能“暴怒”、“画戟”，手牌上限+1，获得“神迹”。",
	["wrath"] = "戟",
	["HuajiCard"] = "暴怒",
	["exshenji"] = "神迹",
	[":exshenji"] = "结束阶段开始时，你可以摸两张牌。",
	["~xinglvbu_o"] = "不可能~~",
}

return { extension }
