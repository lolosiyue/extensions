--==《三国 杀神附体——仙》==--
extension = sgs.Package("kexianbao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

--跳过阶段合集
function jiexiangetCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

kexianxiuzhenex = sgs.CreateTriggerSkill {
	name = "kexianxiuzhenex",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Draw) and (player:isAlive())
				and ((player:getMark("&kexianmabimopai") > 0)
					or (player:getMark("&kejiexianmabimp") > 0)
					or (player:getMark("&kexianguiyimopai") > 0)) then
				room:setPlayerMark(player, "&kexianmabimopai", 0)
				room:setPlayerMark(player, "&kexianguiyimopai", 0)
				room:setPlayerMark(player, "&kejiexianmabimp", 0)
				if not player:isSkipped(sgs.Player_Draw) then
					player:skip(sgs.Player_Draw)
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Play) and (player:isAlive()) and (player:getMark("&kejiexianmabicp") > 0) then
				room:setPlayerMark(player, "&kejiexianmabicp", 0)
				if not player:isSkipped(sgs.Player_Play) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Discard) and (player:isAlive()) and (player:getMark("&kexianguiyiqipai") > 0) then
				room:setPlayerMark(player, "&kexianguiyiqipai", 0)
				if not player:isSkipped(sgs.Player_Discard) then
					player:skip(sgs.Player_Discard)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return (target:getMark("&kexianmabimopai") > 0)
			or (target:getMark("&kejiexianmabimp") > 0)
			or (target:getMark("&kejiexianmabicp") > 0)
			or (target:getMark("&kexianguiyimopai") > 0)
			or (target:getMark("&kexianguiyiqipai") > 0)
	end
}
if not sgs.Sanguosha:getSkill("kexianxiuzhenex") then skills:append(kexianxiuzhenex) end

xianchangetupo = sgs.CreateTriggerSkill {
	name = "xianchangetupo",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill("kexianhuoqi")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexiannanhualaoxian", false, true, player:getGeneral2Name()=="kexiannanhualaoxian", false)
			end
		end
		if (player:hasSkill("kexianchanxin")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexianpujing", false, true, player:getGeneral2Name()=="kexianpujing", false)
			end
		end
		if (player:hasSkill("kexianlunhui")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexianzuoci", false, true, player:getGeneral2Name()=="kexianzuoci", false)
			end
		end
		if (player:hasSkill("kexianmabi")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexianyuji", false, true, player:getGeneral2Name()=="kexianyuji", false)
			end
		end
		if (player:hasSkill("kexianhanyan")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexianmasu", false, true, player:getGeneral2Name()=="kexianmasu", false)
			end
		end
		if (player:hasSkill("kexianbenxi")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejiexianzhanghe", false, true, player:getGeneral2Name()=="kexianzhanghe", false)
			end
		end
	end,
	priority = 5,
}
if not sgs.Sanguosha:getSkill("xianchangetupo") then skills:append(xianchangetupo) end


kexiannanhualaoxian = sgs.General(extension, "kexiannanhualaoxian", "kexian", 3)

kexianhuoqi = sgs.CreateTriggerSkill {
	name = "kexianhuoqi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.Pindian },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:addMark("kexianhuoqi", move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark("kexianhuoqi") >= 2 and (player:hasSkill(self:objectName())) then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local players = sgs.SPlayerList()
				for _, pp in sgs.qlist(room:getAllPlayers()) do
					if pp:canPindian() then
						players:append(pp)
					end
				end
				local choicelist = "recover"
				if players:length() >= 2 then
					choicelist = string.format("%s+%s", choicelist, "pindian")
				end
				choicelist = string.format("%s+%s", choicelist, "cancel")

				local result = room:askForChoice(player, self:objectName(), choicelist)
				if result == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				elseif result == "pindian" then
					local pdplayers = room:askForPlayersChosen(player, players, self:objectName(), 2, 2, "nhlxpd-ask",
						false, false)
					local fq = pdplayers:at(0)
					local bfq = pdplayers:at(1)
					if fq and bfq and fq:canPindian(bfq) then
						fq:pindian(bfq, self:objectName(), nil)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			player:setMark("kexianhuoqi", 0)
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				local fromNumber = pindian.from_card:getNumber()
				local toNumber = pindian.to_card:getNumber()
				if fromNumber ~= toNumber then
					local winner
					local loser
					if fromNumber > toNumber then
						winner = pindian.from
						loser = pindian.to
					else
						winner = pindian.to
						loser = pindian.from
					end
					if winner:isAlive() and loser:isAlive() then
						room:setPlayerFlag(winner, "kexianhuoqi_winner")
						if not room:askForDiscard(loser, self:objectName(), 2, 2, true, true, "nhlx-discard") then
							local damage = sgs.DamageStruct()
							damage.damage = 1
							damage.from = winner
							damage.to = loser
							damage.reason = "kexianhuoqi"
							room:damage(damage)
						end
						room:setPlayerFlag(winner, "-kexianhuoqi_winner")
					end
				end
			end
		end
		return false
	end
}
kexiannanhualaoxian:addSkill(kexianhuoqi)

kexianyuli = sgs.CreateTriggerSkill {
	name = "kexianyuli",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Pindian },
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			local nhlxs = room:findPlayersBySkillName(self:objectName())
			if not nhlxs:isEmpty() then
				for _, nhlx in sgs.qlist(nhlxs) do
					if not nhlx:hasFlag("alreadyyuli") then
						if nhlx:askForSkillInvoke(self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							nhlx:drawCards(1)
						end
						room:setPlayerFlag(nhlx, "alreadyyuli")
					end
				end
			end
		end
		return false
	end,
	priority = -1
}
kexiannanhualaoxian:addSkill(kexianyuli)

kexianyuliclear = sgs.CreateTriggerSkill {
	name = "kexianyuliclear",
	events = { sgs.Pindian },
	global = true,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Pindian then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("alreadyyuli") then
					room:setPlayerFlag(p, "-alreadyyuli")
				end
			end
		end
		if event == sgs.Pindian then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("alreadyjieyuli") then
					room:setPlayerFlag(p, "-alreadyjieyuli")
				end
			end
		end
		return false
	end,
	priority = -2
}
if not sgs.Sanguosha:getSkill("kexianyuliclear") then skills:append(kexianyuliclear) end


kexiantianbian_DummyCard = sgs.CreateSkillCard {
	name = "kexiantianbian_DummyCard",
	target_fixed = true,
	will_throw = false,
}
kexiantianbian_Card = sgs.CreateSkillCard {
	name = "kexiantianbian_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("kexiantianbian_Source") or to_select:hasFlag("kexiantianbian_Target")
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setPlayerFlag(target, "kexiantianbian_Modify")
		local card_id = effect.card:getSubcards():first()
		room:setTag("kexiantianbian_Card", sgs.QVariant(card_id))
	end,
}
kexiantianbianVS = sgs.CreateViewAsSkill {
	name = "kexiantianbian",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = kexiantianbian_Card:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@kexiantianbian"
	end
}
kexiantianbian = sgs.CreateTriggerSkill {
	name = "kexiantianbian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PindianVerifying },
	view_as_skill = kexiantianbianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			local room = player:getRoom()
			local list = room:findPlayersBySkillName(self:objectName())
			for _, zhangjiao in sgs.qlist(list) do
				if not zhangjiao:isNude() then
					local source = pindian.from
					local target = pindian.to
					room:setTag("CurrentPindianStruct", data)
					room:setPlayerFlag(source, "kexiantianbian_Source")
					room:setPlayerFlag(target, "kexiantianbian_Target")
					local prompt = string.format("@kexiantianbian_Pindian::%s:%s", self:objectName(), pindian.reason)
					room:askForUseCard(zhangjiao, "@kexiantianbian", prompt)
					room:setPlayerFlag(source, "-kexiantianbian_Source")
					room:setPlayerFlag(target, "-kexiantianbian_Target")
					room:removeTag("CurrentPindianStruct")
					local card_id = room:getTag("kexiantianbian_Card"):toInt()
					local card = sgs.Sanguosha:getCard(card_id)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						local dest
						local oldcard
						if source:hasFlag("kexiantianbian_Modify") then
							dest = source
							oldcard = pindian.from_card
							pindian.from_card = card
							pindian.from_number = card:getNumber()
						elseif target:hasFlag("kexiantianbian_Modify") then
							dest = target
							oldcard = pindian.to_card
							pindian.to_card = card
							pindian.to_number = card:getNumber()
						end
						if oldcard then
							local move = sgs.CardsMoveStruct()
							move.card_ids:append(card_id)
							move.to = dest
							move.to_place = sgs.Player_PlaceTable
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, zhangjiao:objectName())
							local move2 = sgs.CardsMoveStruct()
							move2.card_ids:append(oldcard:getEffectiveId())
							move2.to = zhangjiao
							move2.to_place = sgs.Player_PlaceHand
							move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,
								zhangjiao:objectName())
							local moves = sgs.CardsMoveList()
							moves:append(move)
							moves:append(move2)
							room:moveCardsAtomic(moves, true)

							local msg = sgs.LogMessage()
							msg.type = "$kexiantianbian_PindianOne"
							msg.from = zhangjiao
							msg.to:append(dest)
							msg.arg = self:objectName()
							msg.card_str = card:toString()
							room:sendLog(msg)
							data:setValue(pindian)
							local msg = sgs.LogMessage()
							msg.type = "$kexiantianbian_PindianFinal"
							msg.from = source
							msg.card_str = pindian.from_card:toString()
							room:sendLog(msg)
							msg.from = target
							msg.card_str = pindian.to_card:toString()
							room:sendLog(msg)
						end
					end
					room:removeTag("kexiantianbian_Card")
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kexiannanhualaoxian:addSkill(kexiantianbian)




kexianpujing = sgs.General(extension, "kexianpujing", "kexian", 3)

kexianchanxinCard = sgs.CreateSkillCard {
	name = "kexianchanxinCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			local mopai = count
			room:drawCards(source, mopai)
		end
	end
}
kexianchanxin = sgs.CreateViewAsSkill {
	name = "kexianchanxin",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local js_card = kexianchanxinCard:clone()
			for _, card in pairs(cards) do
				js_card:addSubcard(card)
			end
			js_card:setSkillName(self:objectName())
			return js_card
		end
	end,
}
kexianpujing:addSkill(kexianchanxin)


function xiangetCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

kexianhuiyan = sgs.CreateTriggerSkill {
	name = "kexianhuiyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.StartJudge },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge then
			if player:askForSkillInvoke("xianhuiyanfadong", data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = data:toJudge()
				local card_ids = room:getNCards(2)
				room:fillAG(card_ids)
				local to_get = sgs.IntList()
				room:setTag("kexianhuiyan", data)
				local card_id = room:askForAG(player, card_ids, false, self:objectName(), "kexianhuiyan-choice")
				room:removeTag("kexianhuiyan")
				card_ids:removeOne(card_id)
				room:takeAG(player, card_id, false)
				local judgeone = sgs.Sanguosha:getCard(card_id)

				local _card_ids = card_ids
				for _, id in sgs.qlist(_card_ids) do
					to_get:append(id)
					card_ids:removeOne(id)
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not to_get:isEmpty() then
					dummy:addSubcards(xiangetCardList(to_get))
					player:obtainCard(dummy)
				end
				dummy:deleteLater()
				room:clearAG()

				judge.card = judgeone
				room:moveCardTo(judge.card, nil, judge.who, sgs.Player_PlaceJudge,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGE, judge.who:objectName(), self:objectName(), "",
						judge.reason), true)
				judge:updateResult()
				room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
kexianpujing:addSkill(kexianhuiyan)


kexianguiyi = sgs.CreateTriggerSkill {
	name = "kexianguiyi",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canPindian(p) then
					players:append(p)
				end
			end
			if (not players:isEmpty()) and player:canPindian() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local target = room:askForPlayerChosen(player, players, self:objectName(), "xianguiyi-ask", true,
						true)
					if target ~= nil then
						local success = player:pindian(target, self:objectName(), nil)
						if success then
							room:setPlayerMark(target, "&kexianguiyimopai", 1)
						else
							room:setPlayerMark(player, "&kexianguiyiqipai", 1)
						end
					end
				end
			end
		end
	end
}
kexianpujing:addSkill(kexianguiyi)




kexianzuoci = sgs.General(extension, "kexianzuoci", "kexian", 3)

kexianlunhui = sgs.CreateTriggerSkill {
	name = "kexianlunhui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Finish then
			if player:getMark("usexianlunhui") <= 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.play_animation = true
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					if judge.card:isBlack() then
						room:setPlayerMark(player, "kexianlunhui", 1)
						room:setPlayerMark(player, "usexianlunhui", 2)
					end
				end
			end
			room:removePlayerMark(player, "usexianlunhui", 1)
		end
		if change.to == sgs.Player_NotActive then
			if player:getMark("kexianlunhui") <= 0 then return false end
			room:setPlayerMark(player, "kexianlunhui", 0)
			local log = sgs.LogMessage()
			log.type = "$kexianlunhui_ex"
			log.from = player
			room:sendLog(log)
			player:gainAnExtraTurn()
		end
	end,
}
kexianzuoci:addSkill(kexianlunhui)



kexianfenshenCard = sgs.CreateSkillCard {
	name = "kexianfenshenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:gainMark("&kexianfenshen")
	end
}
kexianfenshenVS = sgs.CreateViewAsSkill {
	name = "kexianfenshen",
	n = 1,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kexianfenshenCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&xianzuociji") > 0) and not (player:hasUsed("#kexianfenshenCard"))
	end
}

kexianfenshen = sgs.CreateTriggerSkill {
	name = "kexianfenshen",
	view_as_skill = kexianfenshenVS,
	events = { sgs.DamageInflicted, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_RoundStart) and player:faceUp() then
				if (player:getMark("kexianzuociturn") == 0) then
					room:setPlayerMark(player, "kexianzuociturn", 1)
					local already = 0
					if (player:getMark("&xianzuociji") <= 0) and (player:getMark("&xianzuociou") <= 0) then
						room:setPlayerMark(player, "&xianzuociji", 1)
						already = 1
					end
					if (player:getMark("&xianzuociji") > 0) and (already == 0) then
						room:setPlayerMark(player, "&xianzuociji", 0)
						room:setPlayerMark(player, "&xianzuociou", 1)
						already = 1
					end
					if (player:getMark("&xianzuociou") > 0) and (already == 0) then
						room:setPlayerMark(player, "&xianzuociji", 1)
						room:setPlayerMark(player, "&xianzuociou", 0)
					end
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and player:hasSkill(self:objectName()) and (player:getPhase() == sgs.Player_Start) then
			room:setPlayerMark(player, "kexianzuociturn", 0)
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			local hurt = damage.damage
			if player:getMark("&kexianfenshen") > 0 then
				local fs = player:getMark("&kexianfenshen")
				if hurt <= fs then
					player:loseMark("&kexianfenshen", hurt)
					local log = sgs.LogMessage()
					log.type = "$kexianfenshen_hujia"
					log.from = player
					room:sendLog(log)
					damage.prevented = true
					data:setValue(damage)
					return true
				end
				if hurt > fs then
					damage.damage = hurt - fs
					player:loseAllMarks("&kexianfenshen")
					local log = sgs.LogMessage()
					log.type = "$kexianfenshen_hujia"
					log.from = player
					room:sendLog(log)
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
kexianzuoci:addSkill(kexianfenshen)

kexianfeijian = sgs.CreateTriggerSkill {
	name = "kexianfeijian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_RoundStart) and player:faceUp() then
				if (player:getMark("kexianzuociturn") == 0) then
					room:setPlayerMark(player, "kexianzuociturn", 1)
					local already = 0
					if (player:getMark("&xianzuociji") <= 0) and (player:getMark("&xianzuociou") <= 0) then
						room:setPlayerMark(player, "&xianzuociji", 1)
						already = 1
					end
					if (player:getMark("&xianzuociji") > 0) and (already == 0) then
						room:setPlayerMark(player, "&xianzuociji", 0)
						room:setPlayerMark(player, "&xianzuociou", 1)
						already = 1
					end
					if (player:getMark("&xianzuociou") > 0) and (already == 0) then
						room:setPlayerMark(player, "&xianzuociji", 1)
						room:setPlayerMark(player, "&xianzuociou", 0)
					end
				end
			end
			if player:getPhase() == sgs.Player_Play and player:getMark("&xianzuociou") > 0 then
				local num = player:getMark("&kexianfenshen")
				local log = sgs.LogMessage()
				log.type = "$kexianfeijian_cs"
				log.from = player
				room:sendLog(log)
				room:addSlashCishu(player, num, true)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Start) then
			room:setPlayerMark(player, "kexianzuociturn", 0)
		end
	end,
}
kexianzuoci:addSkill(kexianfeijian)


kexianyuji = sgs.General(extension, "kexianyuji", "kexian", 3)

kexianmabi = sgs.CreateTriggerSkill {
	name = "kexianmabi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.card and damage.card:isKindOf("Slash") then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(damage.to, "&kexianmabimopai", 1)
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
	end,
}
kexianyuji:addSkill(kexianmabi)

kexianxiuzhen = sgs.CreateTriggerSkill {
	name = "kexianxiuzhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		if damage.from then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.who = damage.from
				judge.reason = self:objectName()
				room:judge(judge)
				local suit = judge.card:getSuit()
				if suit == sgs.Card_Spade then
					local damagee = sgs.DamageStruct()
					damagee.to = damage.from
					damagee.damage = 1
					damagee.nature = sgs.DamageStruct_Thunder
					room:damage(damagee)
				end
				if suit == sgs.Card_Club then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				end
				if suit == sgs.Card_Heart then
					if damage.from:canDiscard(damage.from, "h") then
						room:askForDiscard(damage.from, self:objectName(), 1, 1, false, false)
					end
				end
				if suit == sgs.Card_Diamond then
					player:drawCards(1)
					damage.from:drawCards(1)
				end
			end
		end
	end
}
kexianyuji:addSkill(kexianxiuzhen)





kexianmasu = sgs.General(extension, "kexianmasu", "shu", 4)

kexianhanyan = sgs.CreateTriggerSkill {
	name = "kexianhanyan",
	events = { sgs.CardUsed, sgs.CardResponded },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.CardUsed then
			if (use.from:objectName() == player:objectName()) and (player:getPhase() == sgs.Player_Play) and not (use.card:isKindOf("SkillCard")) then
				if (player:getHandcardNum() <= player:getAttackRange()) then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if player:inMyAttackRange(p) then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						local eny = room:askForPlayerChosen(player, players, self:objectName(), "kexianhanyan-ask", true,
							true)
						if eny and (eny:getCardCount() > 0) then
							room:broadcastSkillInvoke(self:objectName())
							room:askForDiscard(eny, self:objectName(), 1, 1, false, true, "kexianhanyan-dis")
						end
					end
				end
			end
		end
		if event == sgs.CardResponded and (player:getPhase() == sgs.Player_Play) then
			if player:getHandcardNum() <= player:getAttackRange() then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:inMyAttackRange(player) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local eny = room:askForPlayerChosen(player, players, self:objectName(), "kexianhanyan-ask", true,
						true)
					if eny and (eny:getCardCount() > 0) then
						room:broadcastSkillInvoke(self:objectName())
						room:askForDiscard(eny, self:objectName(), 1, 1, false, true, "kexianhanyan-dis")
					end
				end
			end
		end
	end,
}

kexianmasu:addSkill(kexianhanyan)


kexianxiaocai = sgs.CreateTriggerSkill {
	name = "kexianxiaocai",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				local ok = true
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					for _, id2 in sgs.qlist(move.card_ids) do
						local card2 = sgs.Sanguosha:getCard(id2)
						if card:getSuit() ~= card2:getSuit() then
							ok = false 
							break
						end
					end

				end
				if (move.card_ids:length() < 2) then
					ok = false
				end
				if (ok) then
					room:setPlayerMark(player, "xiaocaimopai-Clear", 1)
				end
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if (player:getMark("xiaocaimopai-Clear") > 0) then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
					end
				end
			end
		end

		return false
	end
}
kexianmasu:addSkill(kexianxiaocai)


kexianmoyong = sgs.CreateCardLimitSkill {
	name = "kexianmoyong",
	limit_list = function(self, player)
		if player:hasSkill(self) then
			return "use,response"
		else
			return ""
		end
	end,
	limit_pattern = function(self, player)
		if player:hasSkill(self) then
			return "Nullification"
		else
			return ""
		end
	end
}
kexianmasu:addSkill(kexianmoyong)




kexianzhanghe = sgs.General(extension, "kexianzhanghe", "wei", 4)

kexianbenxi = sgs.CreateTriggerSkill {
	name = "kexianbenxi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.from and (damage.from:getMark("&kexianbenxi-PlayClear") > 0) and damage.card and damage.card:isKindOf("Slash") then
				local hurt = damage.damage
				damage.damage = hurt + damage.from:getMark("&kexianbenxi-PlayClear")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseStart) and player:getPhase() == sgs.Player_Draw then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					players:append(p)
				end
			end
			if not players:isEmpty() and player:askForSkillInvoke(self:objectName()) then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "kexianbenxi-ask", true,
					true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:showAllCards(target, player)
					room:addPlayerMark(player, "&kexianbenxi-PlayClear")
					return true
				end
			end
		end
	end,

}
kexianzhanghe:addSkill(kexianbenxi)

kexianbenxijl = sgs.CreateTargetModSkill {
	name = "kexianbenxijl",
	distance_limit_func = function(self, from, card)
		if (from:getMark("&kexianbenxi-PlayClear") > 0) and (card:isKindOf("Slash")) then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("kexianbenxijl") then skills:append(kexianbenxijl) end




--仙神华佗
kexianhuatuo = sgs.General(extension, "kexianhuatuo", "kexian", 3)

kexianjishiCard = sgs.CreateSkillCard {
	name = "kexianjishiCard",
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
						room:removePlayerMark(source, "@xianjishi")
						room:doAnimate(1, source:objectName(), pp:objectName())
						room:revivePlayer(pp)
						pp:throwAllMarks()
						local hp = pp:getMaxHp()
						room:setPlayerProperty(pp, "hp", sgs.QVariant(hp))
						pp:drawCards(hp)
					end
				end
			end
		end
	end
}

kexianjishiVS = sgs.CreateViewAsSkill {
	name = "kexianjishi",
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
		local jsCard = kexianjishiCard:clone()
		for _, card in ipairs(cards) do
			jsCard:addSubcard(card)
		end
		return jsCard
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@xianjishi") > 0) and (player:getMark("canjishi") > 0)
	end
}
kexianjishi = sgs.CreateTriggerSkill {
	name = "kexianjishi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xianjishi",
	events = { sgs.BuryVictim },
	view_as_skill = kexianjishiVS,
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		local death = data:toDeath()
		local xhts = room:findPlayersBySkillName("kexianjishi")
		if not xhts:isEmpty() then
			for _, xht in sgs.qlist(xhts) do
				if (xht:getMark("@xianjishi") > 0) then
					room:setPlayerMark(xht, "canjishi", 1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kexianhuatuo:addSkill(kexianjishi)


kexianwuqin = sgs.CreateTriggerSkill {
	name = "kexianwuqin",
	events = { sgs.CardUsed, sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (player:getPhase() == sgs.Player_Play) and not use.card:isKindOf("SkillCard") then
				if player:getMark("canusewuqin") > 0 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(player, "canusewuqin", 0)
						local pattern = ""
						local prompt = ""
						if use.card:isKindOf("BasicCard") then
							pattern = "BasicCard"
							prompt = "wuqinbasic-ask"
						elseif use.card:isKindOf("TrickCard") then
							pattern = "TrickCard"
							prompt = "wuqintrick-ask"
						elseif use.card:isKindOf("EquipCard") then
							pattern = "EquipCard"
							prompt = "wuqinequip-ask"
						end

						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if not room:askForUseCard(p, pattern, prompt, -1, sgs.Card_MethodUse) then
								if not p:isKongcheng() then
									local card_id = room:askForCardChosen(player, p, "h", self:objectName())
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
										player:objectName())
									room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
										room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
								end
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player, "canusewuqin", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
}
kexianhuatuo:addSkill(kexianwuqin)



kexianbencao = sgs.CreateTriggerSkill {
	name = "kexianbencao",
	events = { sgs.CardUsed },
	--global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.CardUsed then
			if use.card:isKindOf("Peach") then
				local hts = room:findPlayersBySkillName(self:objectName())
				for _, ht in sgs.qlist(hts) do
					if (use.from:objectName() ~= ht:objectName()) then
						room:broadcastSkillInvoke("kexianjishi")
						room:recover(ht, sgs.RecoverStruct())
						local log = sgs.LogMessage()
						log.type = "$bencaorecover"
						log.from = ht
						room:sendLog(log)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kexianhuatuo:addSkill(kexianbencao)




kejiexiannanhualaoxian = sgs.General(extension, "kejiexiannanhualaoxian", "kexian", 3)

kejiexianhuoqi = sgs.CreateTriggerSkill {
	name = "kejiexianhuoqi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.Pindian },
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:addMark("kejiexianhuoqi", move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and (player:getMark("kejiexianhuoqi") >= 1) and (player:hasSkill(self:objectName())) then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local choicelist = "recover"
				local players = sgs.SPlayerList()
				for _, pp in sgs.qlist(room:getAllPlayers()) do
					if pp:canPindian() then
						players:append(pp)
					end
				end
				if players:length() >= 2 then
					choicelist = string.format("%s+%s", choicelist, "pindian")
				end
				choicelist = string.format("%s+%s", choicelist, "cancel")

				local result = room:askForChoice(player, self:objectName(), choicelist)
				if result == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				elseif result == "pindian" then
					local pdplayers = room:askForPlayersChosen(player, players, self:objectName(), 2, 2, "nhlxpd-ask",
						false, false)
					local fq = pdplayers:at(0)
					local bfq = pdplayers:at(1)
					if fq and bfq and fq:canPindian(bfq) then
						fq:pindian(bfq, self:objectName(), nil)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			player:setMark("kejiexianhuoqi", 0)
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				local fromNumber = pindian.from_card:getNumber()
				local toNumber = pindian.to_card:getNumber()
				if fromNumber ~= toNumber then
					local winner
					local loser
					if fromNumber > toNumber then
						winner = pindian.from
						loser = pindian.to
					else
						winner = pindian.to
						loser = pindian.from
					end
					if winner:isAlive() and loser:isAlive() then
						local current = room:getCurrent()
						local xuanze = room:askForChoice(current, "jienhlxloser", "damage+qipai", data)
						if xuanze == "damage" then
							room:damage(sgs.DamageStruct(self:objectName(), winner, loser))
						end
						if xuanze == "qipai" then
							if loser:getCardCount() > 0 then
								local card_id = room:askForCardChosen(current, loser, "he", self:objectName())
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
									current:objectName())
								room:obtainCard(current, sgs.Sanguosha:getCard(card_id), reason,
									room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
							end
						end
					end
				end
			end
		end
		return false
	end
}
kejiexiannanhualaoxian:addSkill(kejiexianhuoqi)

kejiexianyuli = sgs.CreateTriggerSkill {
	name = "kejiexianyuli",
	events = { sgs.Pindian },
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			local nhlxs = room:findPlayersBySkillName(self:objectName())
			if not nhlxs:isEmpty() then
				for _, nhlx in sgs.qlist(nhlxs) do
					if not nhlx:hasFlag("alreadyyuli") then
						if nhlx:askForSkillInvoke(self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							nhlx:drawCards(1)
						end
						room:setPlayerFlag(nhlx, "alreadyyuli")
					end
				end
			end
		end
		return false
	end,
	priority = -1
}
kejiexiannanhualaoxian:addSkill(kejiexianyuli)

kejiexiantianbian_DummyCard = sgs.CreateSkillCard {
	name = "kejiexiantianbian_DummyCard",
	target_fixed = true,
	will_throw = false,
}
kejiexiantianbian_Card = sgs.CreateSkillCard {
	name = "kejiexiantianbian_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("kejiexiantianbian_Source") or to_select:hasFlag("kejiexiantianbian_Target")
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setPlayerFlag(target, "kejiexiantianbian_Modify")
		local card_id = effect.card:getSubcards():first()
		room:setTag("kejiexiantianbian_Card", sgs.QVariant(card_id))
	end,
}
kejiexiantianbianVS = sgs.CreateViewAsSkill {
	name = "kejiexiantianbian",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = kejiexiantianbian_Card:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@kejiexiantianbian"
	end
}
kejiexiantianbian = sgs.CreateTriggerSkill {
	name = "kejiexiantianbian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PindianVerifying, sgs.EventPhaseStart },
	view_as_skill = kejiexiantianbianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			local room = player:getRoom()
			local list = room:findPlayersBySkillName(self:objectName())
			for _, zhangjiao in sgs.qlist(list) do
				if not zhangjiao:isNude() then
					local source = pindian.from
					local target = pindian.to
					room:setTag("CurrentPindianStruct", data)
					room:setPlayerFlag(source, "kejiexiantianbian_Source")
					room:setPlayerFlag(target, "kejiexiantianbian_Target")
					local prompt = string.format("@kexiantianbian_Pindian::%s:%s", self:objectName(), pindian.reason)
					room:askForUseCard(zhangjiao, "@kejiexiantianbian", prompt)
					room:setPlayerFlag(source, "-kejiexiantianbian_Source")
					room:setPlayerFlag(target, "-kejiexiantianbian_Target")
					room:removeTag("CurrentPindianStruct")
					local card_id = room:getTag("kejiexiantianbian_Card"):toInt()
					local card = sgs.Sanguosha:getCard(card_id)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						local dest
						local oldcard
						local can_use = false
						if source:hasFlag("kejiexiantianbian_Modify") then
							dest = source
							oldcard = pindian.from_card
							pindian.from_card = card
							pindian.from_number = card:getNumber()
							room:setPlayerFlag(source, "-kejiexiantianbian_Modify")
							if (card:getNumber() > pindian.to_number and oldcard:getNumber() < pindian.to_number)
								or (card:getNumber() < pindian.to_number and oldcard:getNumber() > pindian.to_number) then
								can_use = true
							end
						elseif target:hasFlag("kejiexiantianbian_Modify") then
							dest = target
							oldcard = pindian.to_card
							pindian.to_card = card
							pindian.to_number = card:getNumber()
							room:setPlayerFlag(target, "-kejiexiantianbian_Modify")
							if (card:getNumber() > pindian.from_number and oldcard:getNumber() < pindian.from_number)
								or (card:getNumber() < pindian.from_number and oldcard:getNumber() > pindian.from_number) then
								can_use = true
							end
						end

						if oldcard then
							local move = sgs.CardsMoveStruct()
							move.card_ids:append(card_id)
							move.to = dest
							move.to_place = sgs.Player_PlaceTable
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, zhangjiao:objectName())
							local move2 = sgs.CardsMoveStruct()
							move2.card_ids:append(oldcard:getEffectiveId())
							move2.to = zhangjiao
							move2.to_place = sgs.Player_PlaceHand
							move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,
								zhangjiao:objectName())
							local moves = sgs.CardsMoveList()
							moves:append(move)
							moves:append(move2)
							room:moveCardsAtomic(moves, true)

							local msg = sgs.LogMessage()
							msg.type = "$kexiantianbian_PindianOne"
							msg.from = zhangjiao
							msg.to:append(dest)
							msg.arg = self:objectName()
							msg.card_str = card:toString()
							room:sendLog(msg)
							data:setValue(pindian)
							local msg = sgs.LogMessage()
							msg.type = "$kexiantianbian_PindianFinal"
							msg.from = source
							msg.card_str = pindian.from_card:toString()
							room:sendLog(msg)
							msg.from = target
							msg.card_str = pindian.to_card:toString()
							room:sendLog(msg)

							if can_use then
								local log = sgs.LogMessage()
								log.type = "$xiantianbianexmopai"
								log.from = zhangjiao
								room:sendLog(log)
								zhangjiao:drawCards(1)
								room:setPlayerMark(zhangjiao, "tianbianexplay", 1)
								local current = room:getCurrent()
								room:setPlayerMark(current, "tianbianatyou", 1)
							end
						end
					end
					room:removeTag("kejiexiantianbian_Card")
				end
			end
		elseif event == sgs.EventPhaseStart and (player:getMark("tianbianatyou") > 0) then
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if (p:getMark("tianbianexplay") > 0) then
					local log = sgs.LogMessage()
					log.type = "$xiantianbianexplaylog"
					log.from = p
					room:sendLog(log)
					room:setPlayerMark(p, "tianbianexplay", 0)
					room:broadcastSkillInvoke(self:objectName())
					p:setPhase(sgs.Player_Play)
					room:broadcastProperty(p, "phase")
					local thread = room:getThread()
					if not thread:trigger(sgs.EventPhaseStart, room, p) then
						thread:trigger(sgs.EventPhaseProceeding, room, p)
					end
					thread:trigger(sgs.EventPhaseEnd, room, player)
					p:setPhase(sgs.Player_NotActive)
					room:broadcastProperty(p, "phase")
				end
			end
			room:setPlayerMark(player, "tianbianatyou", 0)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kejiexiannanhualaoxian:addSkill(kejiexiantianbian)



--界仙普净
kejiexianpujing = sgs.General(extension, "kejiexianpujing", "kexian", 3)

kejiexianchanxinCard = sgs.CreateSkillCard {
	name = "kejiexianchanxinCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			local mopai = count
			room:drawCards(source, mopai)
			if count >= 1 then
				source:drawCards(1)
			end
			if count >= 2 then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(source, recover)
			end
			if count >= 3 then
				local eny = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(),
					"kejiexianchanxin-ask", true, true)
				if eny and (eny:getCardCount() > 0) then
					local qizhi = math.min(count, eny:getCardCount())
					room:askForDiscard(eny, self:objectName(), qizhi, qizhi, false, true, "kejiexianchanxin-dis")
				end
			end
		end
	end
}
kejiexianchanxin = sgs.CreateViewAsSkill {
	name = "kejiexianchanxin",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:isDamageCard() or to_select:isKindOf("Weapon")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local cx_card = kejiexianchanxinCard:clone()
			for _, card in pairs(cards) do
				cx_card:addSubcard(card)
			end
			cx_card:setSkillName(self:objectName())
			return cx_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#kejiexianchanxinCard")
	end,
}
kejiexianpujing:addSkill(kejiexianchanxin)


kejiexianhuiyan = sgs.CreateTriggerSkill {
	name = "kejiexianhuiyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.StartJudge },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge then
			for _, pj in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if pj:askForSkillInvoke("xianhuiyanfadong", data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = data:toJudge()
					local card_ids = room:getNCards(2)
					room:fillAG(card_ids)
					local to_get = sgs.IntList()
					room:setTag("kejiexianhuiyan", data)
					local card_id = room:askForAG(pj, card_ids, false, self:objectName(), "kexianhuiyan-choice")
					room:removeTag("kejiexianhuiyan")
					card_ids:removeOne(card_id)
					room:takeAG(pj, card_id, false)
					local judgeone = sgs.Sanguosha:getCard(card_id)

					local _card_ids = card_ids
					for i = 0, 150 do
						for _, id in sgs.qlist(_card_ids) do
							to_get:append(id)
							card_ids:removeOne(id)
						end
					end
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if not to_get:isEmpty() then
						dummy:addSubcards(jiexiangetCardList(to_get))
						pj:obtainCard(dummy)
					end
					dummy:deleteLater()
					room:clearAG()

					judge.card = judgeone
					room:moveCardTo(judge.card, nil, judge.who, sgs.Player_PlaceJudge,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGE, judge.who:objectName(), self:objectName(),
							"", judge.reason), true)
					judge:updateResult()
					room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kejiexianpujing:addSkill(kejiexianhuiyan)


kejiexianguiyi = sgs.CreateTriggerSkill {
	name = "kejiexianguiyi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local _data = sgs.QVariant()
		_data:setValue(from)
		if room:askForSkillInvoke(player, self:objectName(), _data) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)

			local guess = room:askForChoice(player, self:objectName(), "have+nothave", _data)
			local da_cards = sgs.IntList()
			for _, c in sgs.qlist(from:getCards("h")) do
				if c:isDamageCard() then
					da_cards:append(c:getId())
				end
			end
			if (guess == "have") then
				local log = sgs.LogMessage()
				log.type = "$kejiexianguiyi-caiyou"
				log.from = player
				log.to:append(from)
				room:sendLog(log)
				if da_cards:isEmpty() then
					local log = sgs.LogMessage()
					log.type = "$kejiexianguiyi-wrongy"
					log.from = player
					log.to:append(from)
					room:sendLog(log)
					player:drawCards(1)
					from:drawCards(1)
				else
					local log = sgs.LogMessage()
					log.type = "$kejiexianguiyi-righty"
					log.from = player
					log.to:append(from)
					room:sendLog(log)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcards(xiangetCardList(da_cards))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, from:objectName(),
						self:objectName(), "")
					room:throwCard(dummy, reason, nil)
					dummy:deleteLater()
				end
			end
			if (guess == "nothave") then
				local log = sgs.LogMessage()
				log.type = "$kejiexianguiyi-caimeiyou"
				log.from = player
				log.to:append(from)
				room:sendLog(log)
				if da_cards:isEmpty() then
					local log = sgs.LogMessage()
					log.type = "$kejiexianguiyi-rightn"
					log.from = player
					log.to:append(from)
					room:sendLog(log)
					room:loseHp(from, 1, true, player, self:objectName())
				end
				if not da_cards:isEmpty() then
					local log = sgs.LogMessage()
					log.type = "$kejiexianguiyi-wrongn"
					log.from = player
					log.to:append(from)
					room:sendLog(log)
					local useda = math.random(0, da_cards:length() - 1)
					local players = sgs.SPlayerList()
					players:append(player)
					room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(da_cards:at(useda)), damage.from, players))
				end
			end
		end
	end
}
kejiexianpujing:addSkill(kejiexianguiyi)









kejiexianzuoci = sgs.General(extension, "kejiexianzuoci", "kexian", 3)

kejiexianlunhui = sgs.CreateTriggerSkill {
	name = "kejiexianlunhui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.to == sgs.Player_Finish) then
			if player:getMark("usejiexianlunhui") <= 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.play_animation = true
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					if judge.card:isBlack() then
						room:setPlayerMark(player, "kejiexianlunhui", 1)
						room:setPlayerMark(player, "usejiexianlunhui", 2)
					end
					if not judge.card:isBlack() then
						if player:getMark("&kexianfenshen") < 3 then
							player:gainMark("&kexianfenshen")
						end
					end
				end
			end
			room:removePlayerMark(player, "usejiexianlunhui", 1)
		end
		if (change.to == sgs.Player_NotActive) then
			if player:getMark("kejiexianlunhui") <= 0 then return false end
			room:setPlayerMark(player, "kejiexianlunhui", 0)
			local log = sgs.LogMessage()
			log.type = "$kexianlunhui_ex"
			log.from = player
			room:sendLog(log)
			player:gainAnExtraTurn()
		end
	end,
}
kejiexianzuoci:addSkill(kejiexianlunhui)


kejiexianfenshenCard = sgs.CreateSkillCard {
	name = "kejiexianfenshenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:gainMark("&kexianfenshen")
	end
}
kejiexianfenshenVS = sgs.CreateViewAsSkill {
	name = "kejiexianfenshen",
	n = 1,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kejiexianfenshenCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&jiexianzuociji") > 0) and (player:getMark("&kexianfenshen") < 3) and
			not (player:hasUsed("#kejiexianfenshenCard"))
	end
}

kejiexianfenshen = sgs.CreateTriggerSkill {
	name = "kejiexianfenshen",
	view_as_skill = kejiexianfenshenVS,
	events = { sgs.DamageInflicted, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_RoundStart) and player:faceUp() then
				if (player:getMark("kejiexianzuociturn") == 0) then
					room:setPlayerMark(player, "kejiexianzuociturn", 1)
					local already = 0
					if (player:getMark("&jiexianzuociji") <= 0) and (player:getMark("&jiexianzuociou") <= 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 1)
						already = 1
					end
					if (player:getMark("&jiexianzuociji") > 0) and (already == 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 0)
						room:setPlayerMark(player, "&jiexianzuociou", 1)
						already = 1
					end
					if (player:getMark("&jiexianzuociou") > 0) and (already == 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 1)
						room:setPlayerMark(player, "&jiexianzuociou", 0)
					end
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and player:hasSkill(self:objectName()) and (player:getPhase() == sgs.Player_RoundStart) then
			room:setPlayerMark(player, "kejiexianzuociturn", 0)
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			local hurt = damage.damage
			if player:getMark("&kexianfenshen") > 0 then
				local fs = player:getMark("&kexianfenshen")
				if hurt <= fs then
					player:loseMark("&kexianfenshen", hurt)
					local log = sgs.LogMessage()
					log.type = "$kexianfenshen_hujia"
					log.from = player
					room:sendLog(log)
					return true
				end
				if hurt > fs then
					damage.damage = hurt - fs
					player:loseAllMarks("&kexianfenshen")
					local log = sgs.LogMessage()
					log.type = "$kexianfenshen_hujia"
					log.from = player
					room:sendLog(log)
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
kejiexianzuoci:addSkill(kejiexianfenshen)


kejiexianfeijian = sgs.CreateTriggerSkill {
	name = "kejiexianfeijian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_RoundStart) and player:faceUp() then
				if (player:getMark("kejiexianzuociturn") == 0) then
					room:setPlayerMark(player, "kejiexianzuociturn", 1)
					local already = 0
					if (player:getMark("&jiexianzuociji") <= 0) and (player:getMark("&jiexianzuociou") <= 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 1)
						already = 1
					end
					if (player:getMark("&jiexianzuociji") > 0) and (already == 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 0)
						room:setPlayerMark(player, "&jiexianzuociou", 1)
						already = 1
					end
					if (player:getMark("&jiexianzuociou") > 0) and (already == 0) then
						room:setPlayerMark(player, "&jiexianzuociji", 1)
						room:setPlayerMark(player, "&jiexianzuociou", 0)
					end
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and player:hasSkill(self:objectName()) and (player:getPhase() == sgs.Player_RoundStart) then
			room:setPlayerMark(player, "kejiexianzuociturn", 0)
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) and (player:getMark("&jiexianzuociou") > 0) then
				local num = player:getMark("&kexianfenshen")
				local log = sgs.LogMessage()
				log.type = "$kexianfeijian_cs"
				log.from = player
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				room:addSlashCishu(player, num, true)
				if (player:getMark("&kexianfenshen") > 0) then
					local players = sgs.SPlayerList()
					for _, pp in sgs.qlist(room:getAllPlayers()) do
						if player:canSlash(pp) then
							players:append(pp)
						end
					end
					if not players:isEmpty() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							local eny = room:askForPlayerChosen(player, players, self:objectName(),
								"kejiexianfeijian-ask", true, true)
							if eny then
								room:removePlayerMark(player, "&kexianfenshen", 1)
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("kejiexianfeijian")
								local card_use = sgs.CardUseStruct()
								card_use.card = slash
								card_use.from = player
								card_use.to:append(eny)
								room:setCardFlag(card_use.card, "SlashIgnoreArmor")
								room:useCard(card_use, false)
								slash:deleteLater()
							end
						end
					end
				end
			end
		end
	end,
}
kejiexianzuoci:addSkill(kejiexianfeijian)


kejiexianyuji = sgs.General(extension, "kejiexianyuji", "kexian", 3)

kejiexianmabi = sgs.CreateTriggerSkill {
	name = "kejiexianmabi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			local room = player:getRoom()
			if player:hasSkill(self:objectName()) then
				if damage.from and damage.from:objectName() == player:objectName() and player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local hurt = damage.damage
					local eny = damage.to
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = true
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					if judge.card:isBlack() then
						room:setPlayerMark(eny, "&kejiexianmabimp", 1)
					end
					if judge.card:isRed() then
						room:setPlayerMark(eny, "&kejiexianmabicp", 1)
					end
					if (hurt == 1) then
						return true
					end
					if hurt > 1 then
						damage.damage = hurt - 1
						data:setValue(damage)
					end
					local log = sgs.LogMessage()
					log.type = "$kejiexianmabida"
					log.from = player
					room:sendLog(log)
				end
			end
		end
	end,
}
kejiexianyuji:addSkill(kejiexianmabi)




kejiexianxiuzhen = sgs.CreateTriggerSkill {
	name = "kejiexianxiuzhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.FinishJudge, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if player:askForSkillInvoke("kejiexianxiuzhenpd", data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
			end
		end
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			local st = judge.card:getSuit()
			if st == sgs.Card_Spade then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(),
					"xiuzhenspade-ask", true, true)
				if target then
					room:damage(sgs.DamageStruct(self:objectName(), nil, target, 1, sgs.DamageStruct_Thunder))
				end
			end
			if st == sgs.Card_Club then
				room:gainMaxHp(player, 1, self:objectName())
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
			if st == sgs.Card_Diamond then
				player:drawCards(2)
			end
			if st == sgs.Card_Heart then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName() .. "dis",
					"xiuzhenheart-ask", true, true)
				if target then
					local color = room:askForChoice(player, self:objectName(), "black+red+cancel")

					local to_throw = sgs.IntList()
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, c in sgs.qlist(target:getCards("he")) do
						if (c:isBlack() and color == "black") or (c:isRed() and color == "red") then
							to_throw:append(c:getId())
						end
					end
					if not to_throw:isEmpty() then
						for _, id in sgs.qlist(to_throw) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
							player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, target)
						dummy:deleteLater()
					end
				end
			end
		end
	end,
}
kejiexianyuji:addSkill(kejiexianxiuzhen)




kejiexianmasu = sgs.General(extension, "kejiexianmasu", "shu", 4)

kejiexianjuao = sgs.CreateTriggerSkill {
	name = "kejiexianjuao",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		--room:doLightbox("xianmasuani")
		room:getThread():delay(2000)
		room:setPlayerFlag(player, "masustart")
		for _, q in sgs.qlist(room:getOtherPlayers(player)) do
			room:insertAttackRangePair(q, player)
		end
		if player:hasEquipArea(1) then
			player:throwEquipArea(1)
		end
		if player:hasEquipArea(2) then
			player:throwEquipArea(2)
		end
		--武器牌使用
		local weapons = sgs.IntList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			if (sgs.Sanguosha:getCard(id):isKindOf("Weapon")) then
				weapons:append(id)
			end
		end
		if not weapons:isEmpty() then
			local numone = math.random(0, weapons:length() - 1)
			room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(weapons:at(numone)), player, player))
		end
		-- -1马使用
		local offensivehorses = sgs.IntList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			if (sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse")) then
				offensivehorses:append(id)
			end
		end
		if not offensivehorses:isEmpty() then
			local numtwo = math.random(0, offensivehorses:length() - 1)
			room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(offensivehorses:at(numtwo)), player, player))
		end
		room:setPlayerFlag(player, "-masustart")
	end,
}
kejiexianmasu:addSkill(kejiexianjuao)

kejiexianjuaoex = sgs.CreateFilterSkill {
	name = "#kejiexianjuaoex",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return ((to_select:isKindOf("Armor")) or (to_select:isKindOf("DefensiveHorse"))) and
			(place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName("kejiexianjuao")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
kejiexianmasu:addSkill(kejiexianjuaoex)

kejiexianjuaoexget = sgs.CreateTriggerSkill {
	name = "kejiexianjuaoexget",
	events = { sgs.EventAcquireSkill, sgs.EventLoseSkill },
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == "kejiexianjuao" then
			room:attachSkillToPlayer(player, "kejiexianjuaoex")
		end
		if event == sgs.EventLoseSkill and data:toString() == "kejiexianjuao" then
			room:detachSkillFromPlayer(player, "kejiexianjuaoex")
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
if not sgs.Sanguosha:getSkill("kejiexianjuaoexget") then skills:append(kejiexianjuaoexget) end


kejiexianliwei = sgs.CreateTriggerSkill {
	name = "kejiexianliwei",
	events = { sgs.CardFinished, sgs.CardUsed, sgs.EventPhaseEnd },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			if (use.from:objectName() == player:objectName()) and (player:hasSkill(self:objectName())) and not (use.card:isKindOf("SkillCard")) then
				if player:getMark("&kejiexianliwei") >= player:getHp() then
					--if player:askForSkillInvoke(self:objectName(), data) then
						local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
							"kejiexianliwei-ask", true, true)
						if target ~= nil then
							room:broadcastSkillInvoke(self:objectName())
							if target:canDiscard(target, "he") then
								local to_throw = room:askForCardChosen(player, target, "he", self:objectName())
								local card = sgs.Sanguosha:getCard(to_throw)
								room:throwCard(card, target, player);
							end
						end
					--end
				end
			end
		end
		if event == sgs.CardUsed then
			if (use.from:objectName() == player:objectName()) and (player:hasSkill(self:objectName())) and not ((use.card:isKindOf("SkillCard"))) then
				if not player:hasFlag("masustart") then
					room:addPlayerMark(player, "&kejiexianliwei", 1)
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&kejiexianliwei") > 0 then
					room:setPlayerMark(p, "&kejiexianliwei", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kejiexianmasu:addSkill(kejiexianliwei)


kejiexianaoce = sgs.CreateTriggerSkill {
	name = "kejiexianaoce",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming, sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirming and (player:hasSkill(self:objectName())) then
			local use = data:toCardUse()
			local room = player:getRoom()
			if event == sgs.TargetConfirming and use.to:contains(player) then
				if (use.card:isNDTrick()) and (use.from ~= player) then
					if player:askForSkillInvoke("kejiexianaoce", data) then
						room:broadcastSkillInvoke(self:objectName())
						local slash = sgs.Sanguosha:cloneCard("slash", use.card:getSuit(), use.card:getNumber())
						slash:setSkillName(self:objectName())
						use.card = slash
						room:setCardFlag(use.card, self:objectName())
						data:setValue(use)
						slash:deleteLater()
					end
				end
			end
			return false
		end
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("kejiexianaoce") and effect.to:hasSkill(self:objectName()) then
				effect.to:drawCards(2)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kejiexianmasu:addSkill(kejiexianaoce)


kejiexianzhanghe = sgs.General(extension, "kejiexianzhanghe", "wei", 4)


kejiexianjibian = sgs.CreateTriggerSkill {
	name = "kejiexianjibian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if (damage.from:getMark("&kejiexianjibianda-PlayClear") > 0) and damage.card and damage.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) then
				local hurt = damage.damage
				damage.damage = hurt + damage.from:getMark("&kejiexianjibianda-PlayClear")
				room:sendCompulsoryTriggerLog(player, "kejiexianjibian")
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			local num = player:getLostHp() + 1
			if num > 4 then
				num = 4
			end
			if player:getPhase() == sgs.Player_Start then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local choices = {}
					table.insert(choices, "benxione")
					table.insert(choices, "benxitwo")
					table.insert(choices, "benxithree")
					table.insert(choices, "benxifour")
					for i = 0, num - 1, 1 do
						local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
						if (choice == "benxione") then
							num = num - 1
							table.removeOne(choices, "benxione")
							player:drawCards(1)
						end
						if (choice == "benxitwo") then
							num = num - 1
							table.removeOne(choices, "benxitwo")
							local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
								"kejiexianjibian-ask", true, true)
							if eny then
								if (not eny:isKongcheng()) then
									local ids = sgs.IntList()
									for _, card in sgs.qlist(eny:getHandcards()) do
										ids:append(card:getEffectiveId())
									end
									local card_id = room:doGongxin(player, eny, ids)
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,
										player:objectName(), nil, self:objectName(), nil)
									room:throwCard(sgs.Sanguosha:getCard(card_id), reason, eny, player)
								end
							end
						end
						if (choice == "benxithree") then
							num = num - 1
							table.removeOne(choices, "benxithree")
							room:addPlayerMark(player, "&kejiexianjibianda-PlayClear")
						end
						if (choice == "benxifour") then
							num = num - 1
							table.removeOne(choices, "benxifour")
							room:addPlayerMark(player, "&kejiexianjibianjl-PlayClear")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejiexianzhanghe:addSkill(kejiexianjibian)


kejiexianjibianjlex = sgs.CreateTargetModSkill {
	name = "kejiexianjibianjlex",
	distance_limit_func = function(self, from, card)
		if (from:getMark("&kejiexianjibianjl-PlayClear") > 0) then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("kejiexianjibianjlex") then skills:append(kejiexianjibianjlex) end




sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["kexianbao"] = "仙包",
	["xianchangetupo"] = "将武将更换为界限突破版本",

	--仙南华老仙
	["kexiannanhualaoxian"] = "仙南华老仙",
	["&kexiannanhualaoxian"] = "仙南华老仙",
	["#kexiannanhualaoxian"] = "乱世罪魁",
	["designer:kexiannanhualaoxian"] = "杀神附体",
	["cv:kexiannanhualaoxian"] = "官方",
	["illustrator:kexiannanhualaoxian"] = "杀神附体",

	["kexianhuoqi"] = "祸起",
	["kexianhuoqi:recover"] = "回复1点体力",
	["kexianhuoqi:pindian"] = "令两名角色拼点",
	["nhlxloser"] = "你拼点没赢",
	["nhlxloser:damage"] = "受到拼点赢的角色造成的1点伤害",
	["nhlxloser:qipai"] = "弃置两张牌",
	["nhlxpd-ask"] = "请选择拼点的角色（第一个选择的为发起者）",


	[":kexianhuoqi"] = "<font color='green'><b>弃牌阶段结束时，</b></font>若你于此阶段内弃置过你的至少两张牌，则你可以选择一项：1.回复1点体力；2.令两名角色拼点，然后拼点没赢的角色选择一项：受到拼点赢的角色造成的1点伤害，或弃置两张牌。",


	["kexianyuli"] = "渔利",
	["changepindian-ask"] = "请选择一张牌用于更换拼点牌",
	[":kexianyuli"] = "每当一次拼点结束后，你可以摸一张牌。",

	["kexiantianbian"] = "天变",
	["kexiantianbian_"] = "天变",
	["nhlxtianbian-ask"] = "更换一名角色的拼点牌",
	[":kexiantianbian"] = "每当一次拼点牌亮出后，你可以打出一张牌替换一名角色的拼点牌。",
	["@kexiantianbian_Pindian"] = "你可以发动【%dest】来修改一名角色的 %arg 拼点牌",
	["~kexiantianbian"] = "选择一张牌→点击确定",
	["$kexiantianbian_PindianOne"] = "%from 发动 “%arg”把 %to 的拼点牌改为 %card",
	["$kexiantianbian_PindianFinal"] = "%from 最终的拼点牌为 %card",

	["$xiantianbian"] = "%from 发动了“<font color='yellow'><b>天变</b></font>”，%to 的拼点牌被改为 %card。",


	["$kexianhuoqi1"] = "福祸与共，业山可移。",
	["$kexianhuoqi2"] = "修行退智，遂之道也。",
	["$kexiantianbian1"] = "大哉乾元，万物资始。",
	["$kexiantianbian2"] = "无极之外，复无无极。",
	["~kexiannanhualaoxian"] = "道亦有穷时！",


	--界仙南华老仙
	["kejiexiannanhualaoxian"] = "界仙南华老仙",
	["&kejiexiannanhualaoxian"] = "界仙南华老仙",
	["#kejiexiannanhualaoxian"] = "乱世罪魁",
	["designer:kejiexiannanhualaoxian"] = "杀神附体",
	["cv:kejiexiannanhualaoxian"] = "官方",
	["illustrator:kejiexiannanhualaoxian"] = "杀神附体",

	["kejiexianhuoqi"] = "祸起",
	["kejiexianhuoqi:recover"] = "回复1点体力",
	["kejiexianhuoqi:pindian"] = "令两名角色拼点",
	["jienhlxloser"] = "请选择一项",
	["jienhlxloser:damage"] = "拼点赢的角色对拼点没赢的角色造成1点伤害",
	["jienhlxloser:qipai"] = "你获得拼点没赢的角色的一张牌",


	[":kejiexianhuoqi"] = "<font color='green'><b>弃牌阶段结束时，</b></font>若你于此阶段弃置了你的至少一张牌，你可以选择一项：1.回复1点体力；2.选择两名角色拼点，若有角色赢，你选择一项：拼点赢的角色对拼点没赢的角色造成1点伤害，或你获得拼点没赢的角色的一张牌。",


	["kejiexianyuli"] = "渔利",
	[":kejiexianyuli"] = "每当一次拼点结束后，你可以摸一张牌。",

	["kejiexiantianbian_"] = "天变",
	["kejiexiantianbian"] = "天变",
	[":kejiexiantianbian"] = "每当一次拼点牌亮出后，你可以打出一张牌替换一名角色的拼点牌，然后若你改变了双方拼点牌的大小关系，你摸一张牌并于当前回合结束后获得一个出牌阶段。",

	["$xiantianbianexplaylog"] = "%from 获得了一个额外的出牌阶段！",
	["$xiantianbianexmopai"] = "%from 改变了本次拼点牌大小关系！",

	["$kejiexianhuoqi1"] = "福祸与共，业山可移。",
	["$kejiexianhuoqi2"] = "修行退智，遂之道也。",
	["$kejiexiantianbian1"] = "大哉乾元，万物资始。",
	["$kejiexiantianbian2"] = "无极之外，复无无极。",
	["~kejiexiannanhualaoxian"] = "道亦有穷时！",


	--仙普净
	["kexianpujing"] = "仙普净",
	["&kexianpujing"] = "仙普净",
	["#kexianpujing"] = "镇国长老",
	["designer:kexianpujing"] = "杀神附体",
	["cv:kexianpujing"] = "渡世行者",
	["illustrator:kexianpujing"] = "杀神附体",

	["kexianchanxin"] = "禅心",
	[":kexianchanxin"] = "<font color='green'><b>出牌阶段，</b></font>你可以弃置任意数量的【杀】并摸等量的牌。",

	["kexianhuiyan"] = "慧眼",
	["kexianhuiyan-choice"] = "请选择一张牌作为判定牌",
	[":kexianhuiyan"] = "当你需要判定时，你可以观看牌堆顶的两张牌并选择其中一张，你获得另一张牌，并将你选择的牌作为判定牌。",


	["kexianguiyi"] = "皈依",
	["xianguiyi-ask"] = "请选择发动“皈依”拼点的角色",

	["kexianguiyimopai"] = "皈依跳过摸牌",
	["kexianguiyiqipai"] = "皈依跳过弃牌",
	[":kexianguiyi"] = "<font color='green'><b>回合开始时，</b></font>你可以与一名角色拼点，若你赢，该角色跳过其下一个摸牌阶段；若你没赢，你跳过下一个弃牌阶段。",

	["$kexianchanxin1"] = "尘寰万丈却困众生，仁心虽小但容慈悲。",
	["$kexianchanxin2"] = "多行善事，莫问前程。",
	["$kexianchanxin3"] = "善哉善哉，修行者以慈悲为怀。",
	["$kexianhuiyan1"] = "世事无常亦有常，天边皓月去还来。",
	["$kexianhuiyan2"] = "一花一世界，一木一浮生。",
	["$kexianguiyi1"] = "行者餐风宿水，卧月眠霜，随处是家。",
	["$kexianguiyi2"] = "心生，种种魔生；心灭，种种魔灭。",

	["~kexianpujing"] = "凡身虽陨,信念长存。",


	--仙左慈
	["kexianzuoci"] = "仙左慈",
	["&kexianzuoci"] = "仙左慈",
	["#kexianzuoci"] = "雅帝道人",
	["designer:kexianzuoci"] = "杀神附体",
	["cv:kexianzuoci"] = "官方",
	["illustrator:kexianzuoci"] = "杀神附体",

	["kexianlunhui"] = "轮回",
	[":kexianlunhui"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以进行判定，若结果为黑色，你获得一个额外的回合且你下个结束阶段不能再发动“轮回”。",

	["kexianfenshen"] = "分身",

	[":kexianfenshen"] = "出牌阶段限一次，若当前是你的奇数次回合，你可以弃置一张手牌并获得一枚“分身”标记。\
	○当你受到伤害时，你每有一枚“分身”，此伤害-1，然后你移去等量的“分身”。",

	["kexianfeijian"] = "飞剑",
	[":kexianfeijian"] = "<font color='green'><b>出牌阶段开始时，</b></font>若当前是你的偶数次回合，你令你本回合使用【杀】的次数限制+X（X为你“分身”标记的数量）。",
	["$kexianfeijian_cs"] = "%from 因 “<font color='yellow'><b>飞剑</b></font>” 增加了【杀】的使用次数！",

	["xianzuociji"] = "奇数次",
	["xianzuociou"] = "偶数次",
	["$kexianfenshen_hujia"] = "%from 的 “<font color='yellow'><b>分身</b></font>” 被触发，本次伤害被减少！",
	["$kexianlunhui_ex"] = "%from 因 “<font color='yellow'><b>轮回</b></font>” 获得了一个额外的回合！",


	["$kexianlunhui1"] = "幻幻无穷，生生不息。",
	["$kexianlunhui2"] = "吐故纳新，师法天地。",
	["$kexianfenshen1"] = "万物苍生，幻化由心。",
	["$kexianfenshen2"] = "哼，肉眼凡胎，岂能窥视仙人变幻？",
	["~kexianzuoci"] = "腾云跨风，飞升太虚...",

	--仙于吉
	["kexianyuji"] = "仙于吉",
	["&kexianyuji"] = "仙于吉",
	["#kexianyuji"] = "太平青领道",
	["designer:kexianyuji"] = "杀神附体",
	["cv:kexianyuji"] = "官方",
	["illustrator:kexianyuji"] = "杀神附体",

	["kexianmabi"] = "麻痹",
	["kexianmabimopai"] = "麻痹跳过摸牌",
	[":kexianmabi"] = "当你使用【杀】对一名角色造成伤害时，你可以防止此伤害，若如此做，该角色跳过其下一个摸牌阶段。",

	["kexianxiuzhen"] = "修真",
	[":kexianxiuzhen"] = "每当你受到一名角色造成的伤害后，你可以令其进行判定，若结果为：\
	♠：该角色受到1点无来源的雷电伤害；\
	♣：你回复1点体力；\
	♥：该角色弃置一张手牌；\
	♦：你与该角色各摸一张牌。",

	["$kexianmabi1"] = "如真似幻，扑朔迷离。",
	["$kexianmabi2"] = "道法玄机，变幻莫测。",
	["$kexianxiuzhen1"] = "此咒甚重，怨念缠身。",
	["$kexianxiuzhen2"] = "不信吾法，无福之源。",

	["~kexianyuji"] = "道法玄机，竟被参破...",


	--马谡
	["kexianmasu"] = "马谡",
	["&kexianmasu"] = "马谡",
	["#kexianmasu"] = "纸上谈兵",
	["designer:kexianmasu"] = "杀神附体",
	["cv:kexianmasu"] = "官方",
	["illustrator:kexianmasu"] = "杀神附体",

	["kexianhanyan"] = "汗颜",
	[":kexianhanyan"] = "<font color='green'><b>出牌阶段，</b></font>每当你使用或打出牌时，若你的手牌数不大于你的攻击范围，你可以令一名攻击范围内的角色弃置一张牌。",

	["kexianxiaocai"] = "小才",
	[":kexianxiaocai"] = "<font color='green'><b>弃牌阶段结束时，</b></font>若你弃置了你的至少两张牌且花色相同，本回合结束阶段开始时，你可以摸一张牌。",

	["kexianmoyong"] = "莫用",
	[":kexianmoyong"] = "锁定技，你不能使用【无懈可击】。",

	["kexianhanyan-ask"] = "请选择一名角色令其弃置一张牌",
	["kexianhanyan-dis"] = "请弃置一张牌",

	["$kexianhanyan1"] = "散谣惑敌，不攻自破。",
	["$kexianhanyan2"] = "三人成虎，事多有。",
	["$kexianxiaocai1"] = "丞相多虑，且看我的。",
	["$kexianxiaocai2"] = "兵法谙熟于心，取胜千里之外！",

	["~kexianmasu"] = "丞相视某如子，某以丞相为父！",


	--界仙左慈
	["kejiexianzuoci"] = "界仙左慈",
	["&kejiexianzuoci"] = "界仙左慈",
	["#kejiexianzuoci"] = "雅帝道人",
	["designer:kejiexianzuoci"] = "杀神附体",
	["cv:kejiexianzuoci"] = "官方",
	["illustrator:kejiexianzuoci"] = "杀神附体",

	["kejiexianlunhui"] = "轮回",
	[":kejiexianlunhui"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以进行判定，若结果为黑色，你获得一个额外的回合且你下个结束阶段不能再发动“轮回”；若结果为红色，你获得一枚“分身”标记。",

	["kejiexianfenshen"] = "分身",

	[":kejiexianfenshen"] = "出牌阶段限一次，若当前是你的奇数次回合，你可以弃置一张手牌并获得一枚“分身”标记。（至多三枚）\
	○当你受到伤害时，你每有一枚“分身”，此伤害-1，然后你移去等量的“分身”。",

	["kejiexianfeijian"] = "飞剑",
	[":kejiexianfeijian"] = "<font color='green'><b>出牌阶段开始时，</b></font>若当前是你的偶数次回合，你令你本回合使用【杀】的次数限制+X（X为你“分身”标记的数量），然后你可以移去一枚“分身”视为使用一张无视防具且不计入次数的【杀】。",
	["$kexianfeijian_cs"] = "%from 因 “<font color='yellow'><b>飞剑</b></font>” 增加了【杀】的使用次数！",

	["jiexianzuociji"] = "奇数次",
	["jiexianzuociou"] = "偶数次",
	["$kexianfenshen_hujia"] = "%from 的 “<font color='yellow'><b>分身</b></font>” 被触发，本次伤害被减少！",
	["$kexianlunhui_ex"] = "%from 因 “<font color='yellow'><b>轮回</b></font>” 获得了一个额外的回合！",
	["kejiexianfeijian-ask"] = "请选择使用【杀】的目标",

	["$kejiexianlunhui1"] = "幻幻无穷，生生不息。",
	["$kejiexianlunhui2"] = "吐故纳新，师法天地。",
	["$kejiexianfenshen1"] = "万物苍生，幻化由心。",
	["$kejiexianfenshen2"] = "哼，肉眼凡胎，岂能窥视仙人变幻？",
	["~kejiexianzuoci"] = "腾云跨风，飞升太虚...",

	--界马谡
	["kejiexianmasu"] = "界马谡",
	["&kejiexianmasu"] = "界马谡",
	["#kejiexianmasu"] = "胸中甲兵",
	["designer:kejiexianmasu"] = "杀神附体",
	["cv:kejiexianmasu"] = "官方",
	["illustrator:kejiexianmasu"] = "杀神附体",

	["kejiexianjuao"] = "倨傲",
	[":kejiexianjuao"] = "锁定技，你视为在所有其他角色的攻击范围内。游戏开始时，你废除防具栏和防御马栏并随机使用牌堆中的武器牌和进攻马牌各一张。你手牌中的防具牌和防御马牌视为【杀】。",

	["kejiexianliwei"] = "立危",
	[":kejiexianliwei"] = "每当你使用牌结算完毕后，若你于当前回合使用的牌数不小于你的体力值，你可以弃置一名其他角色的一张牌。",

	["kejiexianaoce"] = "骜策",
	["kejiexianaoce-use"] = "骜策：将此牌改为【杀】",
	["kejiexianliwei-ask"] = "请选择一名其他角色弃置其一张牌",
	[":kejiexianaoce"] = "每当你成为其他角色使用的普通锦囊牌的目标时，你可以令此牌当作【杀】结算且不计入次数，当此【杀】被你抵消时，你摸两张牌。",

	["$kejiexianjuao1"] = "吾通晓兵法，世人皆知。",
	["$kejiexianliwei1"] = "丞相多虑，且看我的。",
	["$kejiexianliwei2"] = "兵法谙熟于心，取胜千里之外！",
	["$kejiexianaoce1"] = "散谣惑敌，不攻自破。",
	["$kejiexianaoce2"] = "三人成虎，事多有。",
	["~kejiexianmasu"] = "丞相视某如子，某以丞相为父！",

	--["xianmasuani"] = "image=image/animate/kejiexianmasuani.png",


	--张郃
	["kexianzhanghe"] = "张郃",
	["&kexianzhanghe"] = "张郃",
	["#kexianzhanghe"] = "穷寇莫追",
	["designer:kexianzhanghe"] = "杀神附体",
	["cv:kexianzhanghe"] = "官方",
	["illustrator:kexianzhanghe"] = "杀神附体",

	["kexianbenxi"] = "奔袭",
	[":kexianbenxi"] = "摸牌阶段，你可以改为观看一名其他角色的手牌，若如此做，本回合出牌阶段你使用【杀】无距离限制且造成的伤害+1。",
	["kexianbenxi-ask"] = "请选择一名角色观看其手牌",

	["$kexianbenxi1"] = "兵无常势，水无常形。",
	["$kexianbenxi2"] = "用兵之道，变化万千。",
	["~kexianzhanghe"] = "膝盖中箭了...",

	--界仙普净
	["kejiexianpujing"] = "界仙普净",
	["&kejiexianpujing"] = "界仙普净",
	["#kejiexianpujing"] = "镇国长老",
	["designer:kejiexianpujing"] = "杀神附体",
	["cv:kejiexianpujing"] = "渡世行者",
	["illustrator:kejiexianpujing"] = "杀神附体",

	["kejiexianchanxin"] = "禅心",
	["kejiexianchanxinCard"] = "禅心",
	[":kejiexianchanxin"] = "<font color='green'><b>出牌阶段限一次，</b></font>你可以弃置任意数量的武器牌或伤害类牌并摸等量的牌，然后若你弃置的牌数不少于：一张，你摸一张牌；两张，你回复1点体力；三张，你可以令一名其他角色弃置等量的牌。",

	["kejiexianhuiyan"] = "慧眼",
	["xianhuiyanfadong"] = "慧眼：选择判定结果",
	[":kejiexianhuiyan"] = "当一名角色需要判定时，你可以观看牌堆顶的两张牌并选择其中一张，你获得另一张牌，并将你选择的牌作为判定牌。",

	["kejiexianguiyi"] = "皈依",
	["kejiexianguiyi:have"] = "其手牌中还有伤害类牌",
	["kejiexianguiyi:nothave"] = "其手牌中没有伤害类牌",
	[":kejiexianguiyi"] = "<font color='green'><b>每当你受到伤害后，</b></font>你可以摸一张牌并猜测伤害来源手牌中是否有伤害类牌，若你：\
	○猜对且该角色有伤害类牌，其弃置这些牌；\
	○猜对且该角色没有伤害类牌，其失去1点体力；\
	○没猜对且该角色有伤害类牌，其随机对你使用其中一张；\
	○没猜对且该角色没有伤害类牌，你与其各摸一张牌。",

	["kejiexianchanxin-ask"] = "请选择一名角色弃置等量的牌",
	["kejiexianchanxin-dis"] = "请弃置等量的牌",
	["$kejiexianguiyi-caiyou"] = "%from 猜测 %to 手牌中还有伤害类牌！",
	["$kejiexianguiyi-caimeiyou"] = "%from 猜测 %to 手牌中没有伤害类牌了！",
	["$kejiexianguiyi-wrongy"] = "%from 猜测错误！各摸一张牌！",
	["$kejiexianguiyi-righty"] = "%from 猜测正确！%to 弃置所有的伤害类牌！ ",
	["$kejiexianguiyi-wrongn"] = "%from 猜测错误！%to 将对 %from 使用一张伤害类牌！",
	["$kejiexianguiyi-rightn"] = "%from 猜测正确! %to 失去1点体力！",

	["$kejiexianchanxin1"] = "尘寰万丈却困众生，仁心虽小但容慈悲。",
	["$kejiexianchanxin2"] = "多行善事，莫问前程。",
	["$kejiexianchanxin3"] = "善哉善哉，修行者以慈悲为怀。",
	["$kejiexianhuiyan1"] = "世事无常亦有常，天边皓月去还来。",
	["$kejiexianhuiyan2"] = "一花一世界，一木一浮生。",
	["$kejiexianguiyi1"] = "行者餐风宿水，卧月眠霜，随处是家。",
	["$kejiexianguiyi2"] = "心生，种种魔生；心灭，种种魔灭。",
	["~kejiexianpujing"] = "凡身虽陨,信念长存。",


	--界张郃
	["kejiexianzhanghe"] = "界张郃",
	["&kejiexianzhanghe"] = "界张郃",
	["#kejiexianzhanghe"] = "街亭败蜀",
	["designer:kejiexianzhanghe"] = "杀神附体",
	["cv:kejiexianzhanghe"] = "官方",
	["illustrator:kejiexianzhanghe"] = "杀神附体",

	["kejiexianjibian"] = "机变",
	["kejiexianjibianda"] = "机变：伤害",
	["kejiexianjibianjl"] = "机变：距离",
	[":kejiexianjibian"] = "<font color='green'><b>准备阶段开始时，</b></font>你可以选择执行1+X项：1.摸1张牌；2.观看一名其他角色的手牌并弃置其中一张；3.本回合出牌阶段你使用【杀】造成的伤害+1；4.本回合出牌阶段使用牌无距离限制。（X为你已损失的体力值且至多为3）",
	["kejiexianjibian-ask"] = "请选择一名其他角色",
	["kejiexianjibian:benxione"] = "摸一张牌",
	["kejiexianjibian:benxitwo"] = "观看一名其他角色的手牌并弃置其中一张",
	["kejiexianjibian:benxithree"] = "出牌阶段【杀】伤害+1",
	["kejiexianjibian:benxifour"] = "出牌阶段使用牌无距离限制",

	["$kejiexianjibian1"] = "兵无常势，水无常形。",
	["$kejiexianjibian2"] = "用兵之道，变化万千。",
	["~kejiexianzhanghe"] = "膝盖中箭了...",


	--界仙于吉
	["kejiexianyuji"] = "界仙于吉",
	["&kejiexianyuji"] = "界仙于吉",
	["#kejiexianyuji"] = "太平道人",
	["designer:kejiexianyuji"] = "杀神附体",
	["cv:kejiexianyuji"] = "官方",
	["illustrator:kejiexianyuji"] = "杀神附体",

	["kejiexianmabi"] = "麻痹",
	[":kejiexianmabi"] = "每当你对一名其他角色造成伤害时，你可以令此伤害-1，若如此做，你进行判定，若结果为：黑色，其跳过下一个摸牌阶段；红色，其跳过下一个出牌阶段。",

	["kejiexianxiuzhen"] = "修真",
	["kejiexianxiuzhendis"] = "修真",
	[":kejiexianxiuzhen"] = "当你受到伤害后，你可以进行判定。每当你进行判定后，若判定结果为：\
	♠：你可以令一名角色受到1点无来源的雷电伤害；\
	♣：你加1点体力上限并回复1点体力；\
	♥：你可以令一名角色弃置一种颜色的所有牌；\
	♦：你摸2张牌。",

	["kejiexianmabimp"] = "麻痹跳过摸牌",
	["kejiexianmabicp"] = "麻痹跳过出牌",
	["kejiexianxiuzhenpd"] = "修真：进行判定",
	["xiuzhenspade-ask"] = "你可以令一名角色受到1点雷电伤害",
	["xiuzhenheart-ask"] = "你可以令一名角色弃置一种颜色的所有牌",

	["$kejiexianmabi1"] = "如真似幻，扑朔迷离。",
	["$kejiexianmabi2"] = "道法玄机，变幻莫测。",
	["$kejiexianxiuzhen1"] = "此咒甚重，怨念缠身。",
	["$kejiexianxiuzhen2"] = "不信吾法，无福之源。",

	["~kejiexianyuji"] = "道法玄机，竟被参破...",

	["$kejiexianmabida"] = "%from 本次造成的伤害-1！",


	--神华佗
	["kexianhuatuo"] = "仙华佗",
	["&kexianhuatuo"] = "仙华佗",
	["#kexianhuatuo"] = "济世医仙",
	["designer:kexianhuatuo"] = "杀神附体",
	["cv:kexianhuatuo"] = "官方",
	["illustrator:kexianhuatuo"] = "杀神附体",

	["kexianjishi"] = "济世",
	[":kexianjishi"] = "限定技，出牌阶段，你可以弃置四张花色不同的手牌复活一名已阵亡角色，该角色回复所有体力并摸等同于体力上限的牌。",

	["kexianwuqin"] = "五禽",
	["wuqinbasic-ask"] = "请使用一张基本牌，否则其会获得你的一张牌",
	["wuqintrick-ask"] = "请使用一张锦囊牌，否则其会获得你的一张牌",
	["wuqinequip-ask"] = "请使用一张装备牌，否则其会获得你的一张牌",
	[":kexianwuqin"] = "出牌阶段限一次，当你使用牌时，你可以令所有其他角色依次选择一项：使用一张与此牌相同类型的牌，或令你获得其一张手牌。",

	["$bencaorecover"] = "%from 触发了 “<font color='yellow'><b>本草”</b></font> ！",
	["kexianbencao"] = "本草",
	[":kexianbencao"] = "锁定技，当其他角色使用【桃】时，你回复1点体力。",

	["$kexianjishi1"] = "妙手仁心，药到病除。",
	["$kexianjishi2"] = "救死扶伤，悬壶济世。",
	["$kexianwuqin1"] = "病入膏肓，须下猛药。",
	["$kexianwuqin2"] = "病去如抽丝。",

	["~kexianhuatuo"] = "生老病死，命不可违。",

	--fc人形态
	["kexianhumanfc"] = "FC",
	["&kexianhumanfc"] = "FC",
	["#kexianhumanfc"] = "时光流逝",
	["designer:kexianhumanfc"] = "时光流逝FC",
	["cv:kexianhumanfc"] = "-",
	["illustrator:kexianhumanfc"] = "-",

	["kexianemeng"] = "噩梦",
	["fcemeng"] = "噩梦",
	[":kexianemeng"] = "锁定技，摸牌阶段，你改为亮出牌堆顶的X张牌（X为你的“噩梦”数且至少为2），你随机获得其中一种颜色的牌，然后将其余牌置于你的武将牌上，称为“噩梦”。你可以将一张“噩梦”牌当【杀】使用或打出，你以此法使用的【杀】无距离限制。",

	["kexianmengshi"] = "梦噬",
	[":kexianmengshi"] = "锁定技，回合结束时或当你脱离濒死状态时，若你的“噩梦”数大于你的体力值，你移去所有“噩梦”并视为对你使用一张【杀】。",



	--南宫珂
	["kexianxiaokejiang"] = "南宫珂",
	["&kexianxiaokejiang"] = "南宫珂",
	["#kexianxiaokejiang"] = "",
	["designer:kexianxiaokejiang"] = "小珂酱",
	["cv:kexianxiaokejiang"] = "酒井苍",
	["illustrator:kexianxiaokejiang"] = "Internet",

	["kexiancangfeng"] = "藏锋",
	[":kexiancangfeng"] = "锁定技，分发起始手牌时，你的起始手牌数-3，当你接下来三次受到其他角色造成的伤害后，你分别：1.获得伤害来源的一张牌并回复1点体力；2.对伤害来源造成1点伤害；3.失去1点体力上限并回复1点体力，然后获得“启鞘”。",

	["kexianqiqiao"] = "启鞘",
	[":kexianqiqiao"] = "准备阶段开始时，你可以弃置一名其他角色区域内和你区域内的各一张牌，若这两张牌颜色：相同，你与其各摸两张牌或回复1点体力；不同，你本回合拥有“剑闪”。",

	["kexianyidao"] = "弈道",
	[":kexianyidao"] = "出牌阶段限一次，你可以亮出牌堆顶的X张牌（X为游戏轮数且至多为3），你获得其中的非伤害类牌，然后若你拥有“剑闪”，你可以视为对一名角色依次使用X张【杀】（X为亮出的伤害类牌的数量）。",

	["kexianjianshan"] = "剑闪",
	[":kexianjianshan"] = "出牌阶段限一次，当你使用【杀】指定目标时，你可以令任意名曾对你造成过伤害的角色成为此牌的额外目标，然后你摸等量的牌。",

	["$xkjsamecolor"] = "两张牌的颜色相同！",

	["$xkjdifcolor"] = "两张牌的颜色不同！",

	["kexianqiqiao-ask"] = "你可以选择发动“启鞘”的角色",
	["kexianjianshan-ask"] = "剑闪：为此【杀】选择额外目标",
	["kexianyidaoslash-ask"] = "请选择使用【杀】的目标",
	["kexianjianshan-choice"] = "请选择额外目标",

}
return { extension }
