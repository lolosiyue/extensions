module("extensions.dmpkancolle", package.seeall) --游戏包
extension = sgs.Package("dmpkancolle")           --增加拓展包

--势力

do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "kancolle")
	config.color_de = "#9AC0CD"
end

isFire = function(player)
	if player:getMark("@FireCaused") > 0 then
		return true
	else
		return false
	end
end

--吃撑
se_chichengcard = sgs.CreateSkillCard {
	name = "se_chichengcard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("se_chicheng")
		source:addToPile("akagi_lv", self)
		if self:getSubcards():length() > 1 then
			local re = sgs.RecoverStruct()
			re.who = source
			room:recover(source, re, true)
		end
	end
}
se_chicheng = sgs.CreateViewAsSkill {
	name = "se_chicheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = se_chichengcard:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and not player:hasUsed("#se_chichengcard")
	end
}



--制空

se_zhikongcard = sgs.CreateSkillCard {
	name = "se_zhikong",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		-- room:throwCard(self, nil);
		room:throwCard(self,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(),
				""), nil)
	end
}
se_zhikongVS = sgs.CreateOneCardViewAsSkill {
	name = "se_zhikong",
	filter_pattern = ".|.|.|akagi_lv",
	expand_pile = "akagi_lv",
	response_pattern = "@@akagi_lv",
	view_as = function(self, originalCard)
		local snatch = se_zhikongcard:clone()
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}

se_zhikong = sgs.CreateTriggerSkill {
	name = "se_zhikong",
	events = { sgs.EventPhaseChanging, sgs.DamageCaused },
	view_as_skill = se_zhikongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Start then
				local playerdata = sgs.QVariant()
				playerdata:setValue(player)
				room:setTag("se_zhikong", playerdata)
				for _, Akagi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if Akagi:getHp() > 1 and Akagi:getPile("akagi_lv"):length() > 0 and not isFire(Akagi) and room:askForUseCard(Akagi, "@@akagi_lv", "akagi_lv_remove:remove", -1, sgs.Card_MethodNone) then
						room:broadcastSkillInvoke(self:objectName())
						room:doLightbox("se_zhikong$", 800)
						if player:getKingdom() == "kancolle" then
							Akagi:drawCards(1)
						end
						local playerdata = sgs.QVariant()
						playerdata:setValue(player)
						room:setTag("se_zhikongTarget", playerdata)
						room:setPlayerMark(player, "&se_zhikong+to+#" .. Akagi:objectName(), 1)
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:addPlayerMark(p, "Armor_Nullified", 1)
						end
					end
				end
				room:removeTag("se_zhikong")
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") then
				for _, Akagi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("&se_zhikong+to+#" .. Akagi:objectName()) > 0 then
						local id = room:drawCard()
						Akagi:addToPile("akagi_lv", sgs.Sanguosha:getCard(id), false)
						if math.random(1, 100) < 63 then
							damage.damage = damage.damage + 1
							room:broadcastSkillInvoke(self:objectName())
							room:doLightbox("se_zhikong$", 800)
							local log = sgs.LogMessage()
							log.type = "#skill_add_damage_byother1"
							log.from = Akagi
							log.arg = self:objectName()
							room:sendLog(log)
							local log = sgs.LogMessage()
							log.type = "#skill_add_damage_byother2"
							log.from = damage.from
							log.to:append(damage.to)
							log.arg = damage.damage
							room:sendLog(log)
						end
					end
				end
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
--[[
se_zhikong_Clear=sgs.CreateTriggerSkill{
	name = "#se_zhikong_Clear",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasFlag("se_zhikong_on") then
				player:setFlags("-se_zhikong_on")
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("has_been_Armor_Nullified") == 0 then
						room:setPlayerMark(p, "Armor_Nullified", 0)
					else
						room:setPlayerMark(p, "has_been_Armor_Nullified", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}]]
se_zhikong_Clear = sgs.CreateTriggerSkill {
	name = "#se_zhikong_Clear",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("se_zhikongTarget") then
			local target = room:getTag("se_zhikongTarget"):toPlayer()
			room:removeTag("se_zhikongTarget")
			if target and target:isAlive() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if target:getMark("&se_zhikong+to+#" .. p:objectName()) > 0 then
						room:setPlayerMark(target, "&se_zhikong+to+#" .. p:objectName(), 0)
						for _, q in sgs.qlist(room:getOtherPlayers(target)) do
							room:removePlayerMark(q, "Armor_Nullified");
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}

--雷幕
se_leimu = sgs.CreateTriggerSkill {
	name = "se_leimu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local places = move.from_places
			if places:contains(sgs.Player_DrawPile) then
				local num = room:getDrawPile():length()
				if num - move.card_ids:length() < 1 then
					-- local kita = room:findPlayerBySkillName(self:objectName())
					-- if not kita then return end
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"se_leimu-invoke", true, true)
					if not target then return false end
					room:broadcastSkillInvoke(self:objectName())
					room:doLightbox("se_leimu$", 1200)
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = target
					damage.nature = sgs.DamageStruct_Thunder
					room:damage(damage)
				end
			end
		elseif event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"se_leimu-invoke", true, true)
				if not target then return false end
				room:broadcastSkillInvoke(self:objectName())
				room:doLightbox("se_leimu$", 1200)
				local da = sgs.DamageStruct()
				da.from = player
				da.to = target
				da.nature = sgs.DamageStruct_Thunder
				room:damage(da)
			end
		end
	end
}

se_yezhan = sgs.CreateTriggerSkill {
	name = "se_yezhan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.EventPhaseStart },
	priority = -1,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local invoke = false
			if damage.from:hasSkill(self:objectName()) and damage.nature ~= sgs.DamageStruct_Normal and damage.from:getMark("@turn_of_kita") > 0 and math.floor(damage.from:getMark("@turn_of_kita") / 2) * 2 == damage.from:getMark("@turn_of_kita") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				invoke = true
				room:broadcastSkillInvoke(self:objectName())
			end
			if damage.from:hasSkill(self:objectName()) and damage.to:getHp() <= damage.damage then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				room:doLightbox("se_yezhan$", 2000)
				invoke = true
			end
			if invoke then
				local log = sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = self:objectName()
				log.arg2 = damage.damage
				room:sendLog(log)
			end
		elseif event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_RoundStart and player:faceUp() then
				player:gainMark("@turn_of_kita")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

se_mowang = sgs.CreateTriggerSkill {
	name = "se_mowang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:hasSkill(self:objectName()) and source:getMark("@mowang") == 0 then
			if not source:askForSkillInvoke(self:objectName(), data) then return end
			room:loseMaxHp(source, 2)
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("se_mowang$", 3000)
			room:recover(source, sgs.RecoverStruct(source, nil, 1 - source:getHp()))
			source:drawCards(3)
			room:handleAcquireDetachSkills(source, "SE_Lingshang")
			source:gainMark("@mowang")
		end
	end
}

--噩梦
se_emeng = sgs.CreateTriggerSkill {
	name = "se_emeng",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	waked_skills = "poi_yingzi,poi_paoxiao,se_chongzhuang",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("se_suo$", 500)
			room:doLightbox("se_luo$", 500)
			room:doLightbox("se_men$", 1000)
			room:doLightbox("se_wo$", 300)
			room:doLightbox("se_you$", 300)
			room:doLightbox("se_hui$", 300)
			room:doLightbox("se_lai$", 300)
			room:doLightbox("se_le$", 300)
			room:doLightbox("se_a$", 1000)
			room:doLightbox("se_emeng$", 2000)
			if player:getGeneralName() == "Yuudachi" then
				room:changeHero(player, "poi_kai2", false, false, false, false)
			elseif player:getGeneral2Name() == "Yuudachi" then
				room:changeHero(player, "poi_kai2", false, false, true, false)
			else
				room:handleAcquireDetachSkills(player, "poi_yingzi")
				room:handleAcquireDetachSkills(player, "poi_paoxiao")
				room:handleAcquireDetachSkills(player, "se_chongzhuang")
			end
			room:addPlayerMark(player, "se_emeng")
			local list = room:getAlivePlayers()
			for _, p in sgs.qlist(list) do
				room:setFixedDistance(player, p, 1)
				room:setFixedDistance(p, player, 1)
			end
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:getHp() <= 1 then
			return true
		end
		return false
	end,
}
--狂犬
se_kuangquan = sgs.CreateTriggerSkill {
	name = "se_kuangquan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	priority = -3,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.from:hasSkill(self:objectName()) and damage.card and damage.card:isKindOf("Slash") and damage.from:distanceTo(damage.to) <= 1 then
			if not damage.from:askForSkillInvoke(self:objectName(), data) then return end
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("se_kuangquan$", 1000)
			room:loseMaxHp(damage.to, 1)
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--冲撞
se_chongzhuang = sgs.CreateTriggerSkill {
	name = "se_chongzhuang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:hasSkill(self:objectName()) then
			if not source:askForSkillInvoke(self:objectName(), data) then return end
			local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "se_chongzhuang")
			if not target then return end
			while target:objectName() ~= source:getNextAlive():objectName() do
				room:getThread():delay(100)
				room:swapSeat(source, source:getNextAlive())
			end
			room:doLightbox("se_chongzhuang$", 1500)
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(target)
			use.card = card
			room:useCard(use, false)
		end
	end
}

--英姿
poi_yingzi = sgs.CreateTriggerSkill {
	name = "poi_yingzi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "poi_yingzi", data) then
			room:broadcastSkillInvoke("se_emeng")
			local num = math.random(1, 100)
			draw.num = draw.num + 1
			if num > 70 then
				draw.num = draw.num + 1
			elseif num > 92 then
				draw.num = draw.num + 2
			elseif num > 98 then
				draw.num = draw.num + 4
			end
			data:setValue(draw)
		end
	end
}

--咆哮
poi_paoxiao = sgs.CreateTargetModSkill {
	name = "poi_paoxiao",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}


--疾风
se_jifeng = sgs.CreateTriggerSkill {
	name = "se_jifeng",                           --必须
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },          --必须
	on_trigger = function(self, event, player, data) --必须
		local change = data:toPhaseChange()
		local phase = change.to
		if phase == sgs.Player_NotActive then
			local room = player:getRoom()
			--local shima = room:findPlayerBySkillName(self:objectName())
			--if not shima then return end
			local shima = player:getNextAlive():getNextAlive()
			if not shima:askForSkillInvoke(self:objectName(), data) then return end
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("se_jifeng$", 400)
			room:swapSeat(shima, player:getNextAlive())
		end
	end,
	can_trigger = function(self, target)
		return target:getNextAlive():getNextAlive():hasSkill("se_jifeng")
	end
}

--回避
se_huibi = sgs.CreateTriggerSkill {
	name = "se_huibi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardResponded, sgs.CardAsked, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded or event == sgs.CardUsed then
			local card
			if event == sgs.CardResponded then
				card = data:toCardResponse().m_card
			elseif event == sgs.CardUsed then
				card = data:toCardUse().card
			end
			if card and card:isKindOf("Jink") and player:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("se_huibi")
					room:doLightbox("se_jifeng$", 800)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getNextAlive():objectName() == player:objectName() then
							room:swapSeat(p, player)
							break
						end
					end
					player:gainMark("@shimakaze_speed")
				end
			end
		elseif event == sgs.CardAsked then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				if math.random(1, 5) > player:getMark("@shimakaze_speed") then return end
				if not player:hasSkill("se_huibi") then return end
				if not room:askForSkillInvoke(player, "se_huibi_jink", data) then return end
				room:broadcastSkillInvoke(self:objectName())
				local jinkcard = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jinkcard:setSkillName("se_huibi")
				room:provide(jinkcard)
				return true
			end
		end
		return false
	end,
}


--欠雷
se_qianlei = sgs.CreateTriggerSkill {
	name = "se_qianlei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EnterDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local der = dying_data.who
		if not der then return end
		local damage = dying_data.damage
		if not damage then return end
		for _, buki in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			--if not damage.from then return end
			local choicelist = "cancel"
			if not der:isKongcheng() then
				choicelist = string.format("%s+%s", choicelist, "se_qianlei_second=" .. der:objectName())
			end
			if not buki:isNude() then
				choicelist = string.format("%s+%s", choicelist, "se_qianlei_first=" .. der:objectName())
			end
			if choicelist == "cancel" then return end
			local choice = room:askForChoice(buki, self:objectName(), choicelist, data)
			if choice:startsWith("se_qianlei_first") then
				local cardid = room:askForCardChosen(buki, buki, "he", self:objectName())
				if cardid == -1 then return end
				room:broadcastSkillInvoke("se_qianlei", math.random(1, 3))
				room:doLightbox("se_qianlei1$", 1200)
				room:obtainCard(der, cardid)
				local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				card:deleteLater()
				card:setSkillName(self:objectName())
				if damage.from then
					local use = sgs.CardUseStruct()
					use.from = buki
					use.to:append(damage.from)
					use.card = card
					room:useCard(use, false)
				end
			elseif choice:startsWith("se_qianlei_second") then
				if der:getHandcardNum() == 0 then continue end
				room:broadcastSkillInvoke("se_qianlei", math.random(4, 5))
				room:doLightbox("se_qianlei2$", 1200)
				room:showAllCards(der, buki)
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:deleteLater()
				for _, c in sgs.qlist(der:getHandcards()) do
					if c:isRed() then
						dummy:addSubcard(c)
					end
				end
				room:throwCard(dummy, der, buki)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

se_shuacun = sgs.CreateTriggerSkill {
	name = "se_shuacun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from then return end
			if use.from:getPhase() ~= sgs.Player_Play then return end
			for _, p in sgs.qlist(use.to) do
				if p:hasSkill(self:objectName()) and not p:hasFlag("sonzaikan_aru") then
					p:setFlags("sonzaikan_aru")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				for _, buki in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if buki and buki:getPhase() ~= sgs.Player_Play then
						if not buki:hasFlag("sonzaikan_aru") then
							if not buki:isKongcheng() and buki:askForSkillInvoke(self:objectName(), data) then
								room:broadcastSkillInvoke("se_shuacun")
								local num = math.floor(buki:getHandcardNum() / 2)
								local good
								if num ~= 0 then
									good = room:askForDiscard(buki, "se_shuacun", num, num, false, false)
								else
									good = true
								end
								if good then
									buki:drawCards(buki:getHandcardNum())
								end
							end
						else
							buki:setFlags("-sonzaikan_aru")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}




se_hongzha = sgs.CreateViewAsSkill {
	name = "se_hongzha",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = se_hongzhacard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:hasUsed("#se_hongzha") and player:getHp() >= 2 and
			not player:getPile("Kansaiki"):isEmpty() and not isFire(player)
	end,
}

se_hongzhacard = sgs.CreateSkillCard {
	name = "se_hongzha",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select) --必须
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select, card, false) then
			return card:targetFilter(qtargets, to_select, sgs.Self) and
				not sgs.Self:isProhibited(to_select, card, qtargets)
		end
	end,
	on_use = function(self, room, source, targets)
		if #targets > 0 then
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:deleteLater()
			card:setSkillName(self:objectName())
			card:addSubcard(self:getSubcards():first())
			local use = sgs.CardUseStruct()
			use.from = source
			for _, target in ipairs(targets) do
				use.to:append(target)
			end
			use.card = card
			room:useCard(use, true)
		end
	end,
}

se_hongzhaSlash = sgs.CreateTargetModSkill {
	name = "#se_hongzha-slash",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("se_hongzha") and (table.contains(card:getSkillNames(), "se_hongzha")) then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if player:hasSkill("se_hongzha") and (player:getPile("Kansaiki"):length() > 0) and (table.contains(card:getSkillNames(), "se_hongzha")) then
			return player:getPile("Kansaiki"):length() - 1
		else
			return 0
		end
	end,
}


se_weishiCard = sgs.CreateSkillCard {
	name = "se_weishi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (#to_select:getPileNames() > 0 or to_select:objectName() == sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local ids = self:getSubcards()
		local list = target:getPileNames()
		if (target:objectName() == source:objectName()) then
			if not table.contains(list, "Kansaiki") then
				table.insert(list, "Kansaiki")
			end
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(list, "+"))
		target:addToPile(choice, ids:first(), false)
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(target, recover)
	end
}
se_weishiVS = sgs.CreateViewAsSkill {
	name = "se_weishi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = se_weishiCard:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@se_weishi"
	end
}
se_weishi = sgs.CreateTriggerSkill {
	name = "se_weishi",
	events = { sgs.EventPhaseEnd },
	view_as_skill = se_weishiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:isKongcheng() then return false end

		if room:askForUseCard(player, "@@se_weishi", "@se_weishi-card") then
		end
		return false
	end
}

fanqianCard = sgs.CreateSkillCard {
	name = "fanqian",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName())
		if target then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			card:setSkillName("fanqian")
			local dest = sgs.QVariant()
			dest:setValue(target)
			room:setTag("fanqian_target", dest)
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(target)
			use.card = card
			room:useCard(use, true)
		end
	end
}

fanqianVS = sgs.CreateOneCardViewAsSkill {
	name = "fanqian",
	view_filter = function(self, to_select)
		return not to_select:isKindOf("Collateral") and not to_select:isKindOf("Jink") and
			not to_select:isKindOf("Nullification") and not to_select:isKindOf("DelayedTrick")
	end,
	view_as = function(self, originalCard)
		local FanqianCard = fanqianCard:clone()
		FanqianCard:addSubcard(originalCard:getId())
		FanqianCard:setSkillName(self:objectName())
		return FanqianCard
	end,
	enabled_at_play = function(self, player)
		return true
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}


fanqian = sgs.CreateTriggerSkill {
	name = "fanqian",
	events = { sgs.PreCardUsed },
	view_as_skill = fanqianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PreCardUsed) then
			local use = data:toCardUse()
			if ((use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect")) and table.contains(use.card:getSkillNames(), "fanqian")) then
				use.to:clear()
				use.to:append(room:getTag("fanqian_target"):toPlayer())
				data:setValue(use)
			end
		end
		return false
	end,
}

Buyu = sgs.CreateTriggerSkill {
	name = "Buyu",
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_Play and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				if target then
					target:gainMark("@Buyu")
					room:setPlayerFlag(player, "buyu_used")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@Buyu") > 0 then
					p:loseAllMarks("@Buyu")
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(self:objectName()) and use.card and not (use.card:isKindOf("Slash") and use.card:isBlack()) then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("@Buyu") > 0 then
						if not use.from:hasFlag("Buyu_sdraw_played") then
							room:broadcastSkillInvoke(self:objectName(), 1)
							room:setPlayerFlag(player, "Buyu_sdraw_played")
						end
						use.from:drawCards(1)
						return false
					end
				end
				if use.from:canDiscard(use.from, "he") and use.from:hasFlag("buyu_used") then
					if not use.from:hasFlag("Buyu_sdis_played") then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:setPlayerFlag(player, "Buyu_sdis_played")
					end
					room:askForDiscard(use.from, self:objectName(), 1, 1, false, true)
				end
			end
		end
		return false
	end,
}

eryuCard = sgs.CreateSkillCard {
	name = "eryu",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:isFemale() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("eryu", 1)
		targets[1]:gainMark("@EryuMark")
		source:gainMark("@EryuMark")
	end
}

eryuVS = sgs.CreateZeroCardViewAsSkill {
	name = "eryu",
	view_as = function(self)
		return eryuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#eryu") and player:getMark("@EryuMark") == 0
	end,
}


eryu = sgs.CreateTriggerSkill {
	name = "eryu",
	events = { sgs.CardsMoveOneTime },
	view_as_skill = eryuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			if player:getMark("@EryuMark") == 0 then
				return false
			end
			local linked
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@EryuMark") > 0 then
					linked = p
				end
			end
			if not linked then
				return false
			end
			local move = data:toMoveOneTime()
			if not move.from then return false end
			if (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_USE) or (move.from:objectName() ~= player:objectName() and move.from:objectName() ~= linked:objectName()) then
				return false
			end
			if (not move.to) or (move.to:objectName() ~= move.from:objectName()) then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				if move.from:objectName() == player:objectName() then
					for _, id in sgs.qlist(move.card_ids) do
						if id ~= -1 and not sgs.Sanguosha:getCard(id):isKindOf("Nullification") and (sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or (sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and sgs.Sanguosha:getCard(id):isNDTrick())) then
							dummy:addSubcard(id)
						end
					end
					if dummy:subcardsLength() > 0 then
						room:broadcastSkillInvoke("eryu", 2)
						linked:obtainCard(dummy)
					end
				else
					for _, id in sgs.qlist(move.card_ids) do
						if id ~= -1 and not sgs.Sanguosha:getCard(id):isKindOf("Nullification") and (sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or (sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and sgs.Sanguosha:getCard(id):isNDTrick())) then
							dummy:addSubcard(id)
						end
					end
					if dummy:subcardsLength() > 0 then
						room:broadcastSkillInvoke("eryu", 1)
						player:obtainCard(dummy)
					end
				end
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

eryuClear = sgs.CreateTriggerSkill {
	name = "#eryuClear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill then
			if data:toString() == "eryu" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@EryuMark") > 0 then
						p:loseAllMarks("@EryuMark")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
zheyi = sgs.CreateTriggerSkill {
	name = "zheyi",
	frequency = sgs.Skill_Wake,
	events = { sgs.EnterDying },
	waked_skills = "youdiz",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zuikakus = room:findPlayersBySkillName(self:objectName())
		local dying = data:toDying()
		if dying.who and dying.who:getMark("@EryuMark") > 0 then
			for _, zuikaku in sgs.qlist(zuikakus) do
				if zuikaku and zuikaku:getMark("zheyi") == 0 and zuikaku:getMark("@EryuMark") > 0 then
					room:addPlayerMark(zuikaku, "zheyi")
					if room:changeMaxHpForAwakenSkill(zuikaku, 1, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						room:doLightbox("zheyi$", 3000)
						room:handleAcquireDetachSkills(zuikaku, "youdiz")
						room:handleAcquireDetachSkills(zuikaku, "-eryu")
						local recover = sgs.RecoverStruct()
						recover.who = zuikaku
						room:recover(zuikaku, recover)
					end
				end
			end
		end

		return false
	end,
	can_trigger = function(self, target)
		return target
	end,

}

youdiz = sgs.CreateTriggerSkill {
	name = "youdiz",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnStart, sgs.DamageInflicted, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			if player:hasSkill(self:objectName()) then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:inMyAttackRange(player) then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "youdiz-invoke", true,
						true)
					if target then
						room:broadcastSkillInvoke(self:objectName())
						target:gainMark("@Youdi")
						room:addPlayerMark(target, "&youdiz+to+#" .. player:objectName() .. "+-Clear")
						target:gainAnExtraTurn()
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("@Youdi") > 0 then
				if damage.to and damage.to:hasSkill(self:objectName()) and damage.from:getMark("&youdiz+to+#" .. damage.to:objectName() .. "+-Clear") > 0 then
					local target = room:askForPlayerChosen(damage.to, room:getOtherPlayers(damage.to), self:objectName(),
						"youdi_draw")
					target:drawCards(1)
				else
					local zuikaku
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if damage.from:getMark("&youdiz+to+#" .. p:objectName() .. "+-Clear") > 0 then
							zuikaku = p
							break
						end
					end
					local log = sgs.LogMessage()
					log.type  = "#SkillNullifyDamage"
					log.from  = zuikaku
					log.arg   = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:getMark("@Youdi") > 0 and change.to == sgs.Player_NotActive then
				player:loseAllMarks("@Youdi")
				player:turnOver()
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("&youdiz+to+#" .. p:objectName() .. "+-Clear") > 0 then
						room:setPlayerMark(player, "&youdiz+to+#" .. p:objectName() .. "+-Clear", 0)
					end
				end
			end
		end

		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

nuequ = sgs.CreateViewAsSkill {
	name = "nuequ",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = nuequcard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#nuequ")
	end,
}

nuequcard = sgs.CreateSkillCard {
	name = "nuequ",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select) --必须
		local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
		local min_hp = 999
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			min_hp = math.min(min_hp, p:getHp())
		end
		if to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select, card, false) then
			return card:targetFilter(qtargets, to_select, sgs.Self) and
				not sgs.Self:isProhibited(to_select, card, qtargets) and to_select:getHp() == min_hp
		end
	end,
	on_use = function(self, room, source, targets)
		if #targets > 0 then
			local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
			card:deleteLater()
			card:setSkillName(self:objectName())
			card:addSubcard(self:getSubcards():first())
			local use = sgs.CardUseStruct()
			use.from = source
			for _, target in ipairs(targets) do
				use.to:append(target)
			end
			use.card = card
			room:useCard(use, false)
		end
	end,
}

BurningLove = sgs.CreateTriggerSkill {
	name = "BurningLove",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) and damage.nature == sgs.DamageStruct_Fire and
				damage.to and damage.to:isAlive() and
				damage.card and damage.card:isKindOf("FireSlash") and room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local re = sgs.RecoverStruct()
				re.who = player
				room:recover(damage.to, re, true)
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
		return false
	end,
}

fanghuo = sgs.CreateTriggerSkill {
	name = "fanghuo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.card and damage.card:isKindOf("Slash") then
				if room:askForSkillInvoke(damage.from, self:objectName(), data) then
					room:notifySkillInvoked(damage.from, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					damage.to:gainMark("@FireCaused")
					room:setEmotion(damage.to, "fire_caused")
				end
			end
		end
	end,
}
fanghuoBuff = sgs.CreateTriggerSkill {
	name = "#fanghuoBuff",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			room:setEmotion(player, "fire_caused")
			local damage = sgs.DamageStruct()
			damage.from = player
			damage.to = player
			damage.damage = 1
			damage.nature = sgs.DamageStruct_Fire
			room:damage(damage)
			local log = sgs.LogMessage()
			log.type = "#fanghuo"
			log.from = player
			room:sendLog(log)
			local ran = math.random(1, 100)
			if ran < 26 then
				player:loseMark("@FireCaused")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@FireCaused") > 0 and target:isAlive()
	end
}

jianhun = sgs.CreateOneCardViewAsSkill {
	name = "jianhun",
	response_or_use = true,
	view_filter = function(self, card)
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		local totallost = player:getLostHp()
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if ((p:getGeneralName() == "Mogami") or (p:getGeneral2Name() == "Mogami")) or ((p:getGeneralName() == "Shigure") or (p:getGeneral2Name() == "Shigure")) then
				totallost = totallost + p:getLostHp()
			end
		end
		return ((player:getMark("@FireCaused") > 0) or totallost >= 2)
	end,
	enabled_at_response = function(self, player, pattern)
		local totallost = player:getLostHp()
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if ((p:getGeneralName() == "Mogami") or (p:getGeneral2Name() == "Mogami")) or ((p:getGeneralName() == "Shigure") or (p:getGeneral2Name() == "Shigure")) then
				totallost = totallost + p:getLostHp()
			end
		end
		return pattern == "slash" and ((player:getMark("@FireCaused") > 0) or totallost >= 2)
	end
}

jianhunTargetMod = sgs.CreateTargetModSkill {
	name = "#jianhunTargetMod",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("jianhun") and (table.contains(card:getSkillNames(), "jianhun")) then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("jianhun") and (table.contains(card:getSkillNames(), "jianhun")) then
			return 1000
		end
	end,
}

Akagi = sgs.General(extension, "Akagi", "kancolle", 4, false, false, false)
Kitagami = sgs.General(extension, "Kitagami", "kancolle", 3, false, false, false)
Yuudachi = sgs.General(extension, "Yuudachi", "kancolle", 4, false, false, false)
poi_kai2 = sgs.General(extension, "poi_kai2", "kancolle", 3, false, true, true)
Shimakaze = sgs.General(extension, "Shimakaze", "kancolle", 3, false, false, false)
Fubuki = sgs.General(extension, "Fubuki", "kancolle", 3, false, false, false)
Kaga = sgs.General(extension, "Kaga", "kancolle", 4, false, false, false)
Asashio = sgs.General(extension, "Asashio", "kancolle", 3, false, false, false)
Zuikaku = sgs.General(extension, "Zuikaku", "kancolle", 3, false, false, false)
Kongou = sgs.General(extension, "Kongou", "kancolle", 4, false, false, false)
Mogami = sgs.General(extension, "Mogami", "kancolle", 4, false, false, false)


Akagi:addSkill(se_chicheng)
Akagi:addSkill(se_zhikong)
Akagi:addSkill(se_zhikong_Clear)
extension:insertRelatedSkills("se_zhikong", "#se_zhikong_Clear")
Kitagami:addSkill(se_leimu)
Kitagami:addSkill(se_yezhan)
Kitagami:addSkill(se_mowang)
Kitagami:addRelateSkill("SE_Lingshang")
Yuudachi:addSkill(se_emeng)
Yuudachi:addSkill(se_kuangquan)
poi_kai2:addSkill(poi_yingzi)
poi_kai2:addSkill(poi_paoxiao)
poi_kai2:addSkill(se_chongzhuang)
poi_kai2:addSkill(se_kuangquan)
Shimakaze:addSkill(se_jifeng)
Shimakaze:addSkill(se_huibi)
Fubuki:addSkill(se_qianlei)
Fubuki:addSkill(se_shuacun)
Kaga:addSkill(se_weishi)
Kaga:addSkill(se_hongzha)
Kaga:addSkill(se_hongzhaSlash)
extension:insertRelatedSkills("se_hongzha", "#se_hongzha-slash")
Asashio:addSkill(fanqian)
Asashio:addSkill(Buyu)
Zuikaku:addSkill(eryu)
Zuikaku:addSkill(eryuClear)
extension:insertRelatedSkills("eryu", "#eryuClear")
Zuikaku:addSkill(zheyi)
local s_skillList = sgs.SkillList()
if not sgs.Sanguosha:getSkill("youdiz") then
	s_skillList:append(youdiz)
end
sgs.Sanguosha:addSkills(s_skillList)

Kongou:addSkill(nuequ)
Kongou:addSkill(BurningLove)
Mogami:addSkill(fanghuo)
Mogami:addSkill(fanghuoBuff)
Mogami:addSkill(jianhun)
Mogami:addSkill(jianhunTargetMod)
extension:insertRelatedSkills("fanghuo", "#fanghuoBuff")
extension:insertRelatedSkills("jianhun", "#jianhunTargetMod")



















sgs.LoadTranslationTable {
	["kancolle"] = "舰队大法",
	["dmpkancolle"] = "动漫包-舰队大法",

	["se_chichengcard"] = "吃撑「铝是用来吃的」",
	["se_chicheng"] = "吃撑「铝是用来吃的」",
	["akagi_lv"] = "铝",
	["$se_chicheng1"] = "梅雨的季节呢。还在下雨...这样的日子里到间宫那边小憩也是不错的呢，提督。...提督",
	["$se_chicheng2"] = "那个，提督，吃饭……啊不！作战还没有开始吗！",
	["$se_chicheng3"] = "烈风？不，不知道的孩子呢。",
	["$se_chicheng4"] = "流星？和九七（式）舰攻不一样？",
	[":se_chicheng"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将X张牌置于你的武将牌上，称为“铝”。若X不小于2，你回复一点体力。X为任意正整数。",

	["se_zhikong"] = "制空「铝是用来喷的」",
	["$se_zhikong1"] = "第一次攻击队，请发舰！",
	["$se_zhikong2"] = "舰载机的大家，准备好了吗？",
	[":se_zhikong"] = "若你的血量大于1，任意角色回合开始时，你可以弃置一张“铝”，该角色每在回合内使用【杀】造成的伤害時，将牌堆顶的一张牌置于你的武将牌上，称为“铝”，然后有62%的概率【杀】造成的伤害+1，且在其回合内其他角色的防具失效。若该角色为舰娘，你摸一张牌。",
	["se_zhikong$"] = "image=image/animate/se_zhikong.png",
	["akagi_lv_remove"] = "你可以发动“制空”",

	["se_leimu"] = "雷幕 「开闭幕雷击」",
	["$se_leimu1"] = "单装炮，总感觉它有些寂寞呢。",
	["$se_leimu2"] = "嘛、和大井亲组合的话就最强了呢♪。",
	["$se_leimu3"] = "九三式氧推进鱼雷满载，真是重啊",
	[":se_leimu"] = "游戏开始时，你可以对一名其他角色造成一点雷属性伤害；每当牌堆中牌数为0时，若你的血量大于1，你可以对一名其他角色造成一点雷属性伤害。",
	["se_leimu$"] = "image=image/animate/se_leimu.png",
	["se_leimu-invoke"] = "你可以发动“雷幕”，对一名其他角色造成一点雷属性伤害",

	["se_yezhan"] = "夜斩「夜战斩杀」",
	["$se_yezhan1"] = "给你“通通”的来几下吧！",
	["$se_yezhan2"] = "好——了，要追击了～。跟上我来！",
	["$se_yezhan3"] = "嘛……主炮呢……对……嗯……对啊……",
	[":se_yezhan"] = "<font color=\"blue\"><b>锁定技，</b></font>偶数轮（从你的偶数回合开始时到下个回合开始前），你造成属性伤害时，伤害+1；你的伤害若能造成濒死，伤害+1。",
	["se_yezhan$"] = "image=image/animate/se_yezhan.png",
	["@turn_of_kita"] = "北上的回合数",

	["@mowang"] = "北上大魔王",

	["se_mowang"] = "魔王「我不要裱船了」",
	["$se_mowang1"] = "来生，我还是当个重巡比较好吧……",
	["$se_mowang2"] = "来生的话，果然让我做战舰吧。",
	["$se_mowang3"] = "来生的话，果然让做空母吧…啊，怎么说也，工作舰什么的也，啊哈哈哈…",
	[":se_mowang"] = "当你进入濒死状态时，你可以失去两点体力上限，回复至一点体力，摸3张牌，然后获得技能“岭上”。",
	["se_mowang$"] = "image=image/animate/se_mowang.png",

	["se_emeng"] = "噩梦「所罗门的噩梦poi」",
	["$se_emeng1"] = "所罗门的噩梦，让你们见识一下！",
	["$se_emeng2"] = "那么，让我们举办一场华丽的派对吧！",
	["$se_emeng3"] = "夕立、突击poi。",
	[":se_emeng"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始时，若你的体力值不大于1，你失去一点体力上限并获得技能【英姿】【咆哮】和【冲撞】，你与所有角色计算距离时为1，其他角色与你计算距离时为1。",
	["se_emeng$"] = "image=image/animate/se_emeng.png",

	["se_suo$"] = "所    ",
	["se_luo$"] = "  罗  ",
	["se_men$"] = "    门",
	["se_wo$"] = "\n我          ",
	["se_you$"] = "\n  又        ",
	["se_hui$"] = "\n    回      ",
	["se_lai$"] = "\n      来    ",
	["se_le$"] = "\n        了  ",
	["se_a$"] = "\n          啊",

	["se_kuangquan"] = "狂犬「咬死你poi」",
	["$se_kuangquan1"] = "随便找一个打了poi？",
	["$se_kuangquan2"] = "首先从哪里开始打呢？",
	[":se_kuangquan"] = "你对距离为1的角色使用【杀】造成伤害时，可以令目标失去失去一点体力上限。",
	["se_kuangquan$"] = "image=image/animate/se_kuangquan.png",

	["se_chongzhuang"] = "冲撞「风帆突击」",
	["$se_chongzhuang"] = "即使是把打开船帆，也要继续战斗！",
	[":se_chongzhuang"] = "当你进入濒死时，移动到一名其他角色的左侧并视为对其使用一张【杀】。",
	["se_chongzhuang$"] = "image=image/animate/se_chongzhuang.png",

	["poi_yingzi"] = "英姿「孤舰突击」",
	[":poi_yingzi"] = "摸牌阶段，你可以额外摸一些牌。",
	["poi_paoxiao"] = "咆哮「噩梦般的雷击」",
	[":poi_paoxiao"] = "你在出牌阶段内使用【杀】时无次数限制。",


	["se_jifeng"] = "疾风「疾如岛风」",
	["$se_jifeng1"] = "疾如岛风，de-su！",
	["$se_jifeng2"] = "嘿嘿嘿，你很慢呢！",
	["$se_jifeng3"] = "任何人都追不上我的哦！",
	["$se_jifeng4"] = "太慢了！",
	[":se_jifeng"] = "你左侧第二名存活角色回合结束时，你可以向左移动一个位置。",
	["se_jifeng$"] = "image=image/animate/se_jifeng.png",

	["se_huibi"] = "回避「谁也追不上我哦」",
	["se_huibi_jink"] = "回避「谁也追不上我哦」",
	["$se_huibi1"] = "想赛跑吗？我不会输的哦。",
	["$se_huibi2"] = "越来越快的话也可以吗？",
	["$se_huibi3"] = "这样下去的话有多快我可管不了了哦！",
	[":se_huibi"] = "每当你使用或打出【闪】时，你可以向左移动一个位置，并永久增加20%在你需要使用或打出【闪】时，你可以视为打出一张【闪】。",
	["@shimakaze_speed"] = "回避",

	["se_qianlei"] = "欠雷「逆天改命雷」",
	["se_qianlei_first"] = "将一张牌交给 %src ，然后视为你对来源使用了一张【杀】。",
	["se_qianlei_second"] = "观看 %src 的手牌，并弃置其中所有红色的牌。",
	["$se_qianlei1"] = "要、要由我来守护大家！",
	["$se_qianlei2"] = "拜托了！命中吧！",
	["$se_qianlei3"] = "诶？梦想吗？变得强大，能变得保护大家，和平到来的时候，想一直晒晒太阳呢",
	["$se_qianlei4"] = "就由我来解决掉！",
	["$se_qianlei5"] = "进行追击战。请跟紧我！",
	[":se_qianlei"] = "当一名角色受到伤害进入濒死时，你可以1.将一张牌交给濒死角色，然后视为你对来源使用了一张【杀】。2.观看濒死角色的手牌，并弃置其中所有红色的牌。",
	["se_qianlei1$"] = "image=image/animate/se_qianlei1.png",
	["se_qianlei2$"] = "image=image/animate/se_qianlei2.png",

	["se_shuacun"] = "刷存「怒刷存在感」",
	["$se_shuacun1"] = "您辛苦了，我叫吹雪。是，我会努力！",
	["$se_shuacun2"] = "是！已经准备好了！司令官！",
	[":se_shuacun"] = "其他角色出牌阶段若未指定你为目标，其出牌阶段结束时，你可以弃置一半的手牌（向下取整），然后摸取等同你手牌数目的手牌。",
	["se_shuacun$"] = "image=image/animate/se_qianlei.png",

	["Akagi"] = "赤城",
	["&Akagi"] = "赤城",
	["#Akagi"] = "一航战吃货",
	["~Akagi"] = "一航战的荣耀，不能在这种地方丢掉……！",
	["designer:Akagi"] = "Sword Elucidator",
	["cv:Akagi"] = "藤田咲",
	["illustrator:Akagi"] = "",

	["Kitagami"] = "北上",
	["&Kitagami"] = "北上",
	["#Kitagami"] = "超級北上大人",
	["~Kitagami"] = "嗯……该怎么说呢？这种事也有的嘛……想快点修理去。",
	["designer:Kitagami"] = "Sword Elucidator",
	["cv:Kitagami"] = "大坪由佳",
	["illustrator:Kitagami"] = "custom",

	["Yuudachi"] = "夕立",
	["&Yuudachi"] = "夕立",
	["#Yuudachi"] = "所罗门的噩梦",
	["~Yuudachi"] = "真、真是笨蛋！这样就没法战斗了poi！？",
	["designer:Yuudachi"] = "Sword Elucidator",
	["cv:Yuudachi"] = "谷边由美",
	["illustrator:Yuudachi"] = "リン☆ユウ",

	["poi_kai2"] = "夕立改二",
	["&poi_kai2"] = "夕立改二",
	["#poi_kai2"] = "所罗门的噩梦",
	["~poi_kai2"] = "真、真是笨蛋！这样就没法战斗了poi！？",
	["designer:poi_kai2"] = "Sword Elucidator",
	["cv:poi_kai2"] = "谷边由美",
	["illustrator:poi_kai2"] = "",

	["Shimakaze"] = "島風",
	["&Shimakaze"] = "島風",
	["#Shimakaze"] = "海路最速传说",
	["@Shimakaze"] = "艦隊collection",
	["~Shimakaze"] = "哇啊啊！好痛的啦！",
	["designer:Shimakaze"] = "Sword Elucidator",
	["cv:Shimakaze"] = "佐仓绫音",
	["illustrator:Shimakaze"] = "悠久ポン酢",

	["Fubuki"] = "吹雪",
	["&Fubuki"] = "吹雪",
	["#Fubuki"] = "伪·阿卡林2号机",
	["@Fubuki"] = "艦隊collection",
	["~Fubuki"] = "怎么会这样！不可以啊！",
	["designer:Fubuki"] = "曦行;Sword Elucidator",
	["cv:Fubuki"] = "上坂すみれ",
	["illustrator:Fubuki"] = "",

	["Kongou"] = "金剛",
	["&Kongou"] = "金剛",
	["#Kongou"] = "Burning Love!",
	["@Kongou"] = "艦隊collection",
	["~Kongou"] = "",
	["designer:Kongou"] = "Sword Elucidator",
	["cv:Kongou"] = "東山奈央",
	["illustrator:Kongou"] = "",

	["Naka"] = "那珂",
	["&Naka"] = "那珂",
	["#Naka"] = "舰队偶像",
	["@Naka"] = "艦隊collection",
	["~Naka"] = "",
	["designer:Naka"] = "Sword Elucidator",
	["cv:Naka"] = "佐倉綾音",
	["illustrator:Naka"] = "",

	["Ikazuchi"] = "雷",
	["&Ikazuchi"] = "雷",
	["#Ikazuchi"] = "",
	["@Ikazuchi"] = "艦隊collection",
	["~Ikazuchi"] = "",
	["designer:Ikazuchi"] = "Sword Elucidator",
	["cv:Ikazuchi"] = "洲崎綾",
	["illustrator:Ikazuchi"] = "",

	["Inazuma"] = "電",
	["&Inazuma"] = "電",
	["#Inazuma"] = "",
	["@Inazuma"] = "艦隊collection",
	["~Inazuma"] = "",
	["designer:Inazuma"] = "Sword Elucidator",
	["cv:Inazuma"] = "洲崎綾",
	["illustrator:Inazuma"] = "",


	--inovation	
	["se_weishi"] = "喂食",
	[":se_weishi"] = "出牌阶段结束时，你可以将一张手牌置于一名角色的任意牌堆中，然后该角色回复一点体力。若你指定自己为目标，你可以将该牌视为“舰载机”。",
	["$se_weishi1"] = "啊，赤城桑，诶？做过年的荞麦面？知道了，我来帮忙。",
	["$se_weishi2"] = "喜欢甜食就吃吧。",
	["$se_weishi3"] = "这实在是能让人心情振奋。今天我就来啜饮一杯吧。提督要不要考虑一起来一杯？",
	["@se_weishi-card"] = "你可以发动“喂食”",
	["~se_weishi"] = "选择一名角色→选择一张手牌→点击确定",

	["se_hongzha"] = "轰炸",
	[":se_hongzha"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你的体力值不小于2，你可以将一张牌视为对X名角色使用一张无视距离的【杀】。X至多为你的“舰载机”数量。",
	["$se_hongzha1"] = "小菜一碟。不必担心。",
	["$se_hongzha2"] = "別把我跟五航戰的孩子相提並論。",
	["$se_hongzha3"] = "這裡可不能退讓。",

	["Kansaiki"] = "舰载机",
	["Kaga"] = "加贺",
	["&Kaga"] = "加贺",
	["@Kaga"] = "艦隊collection",
	["#Kaga"] = "一航战的前辈",
	["~Kaga"] = "飞行甲板中弹。这是……不可能",
	["designer:Kaga"] = "Sword Elucidator",
	["cv:Kaga"] = "井口裕香",
	["illustrator:Kaga"] = "LuZi",

	["fanqian"] = "反潜",
	["$fanqian1"] = "司令官！请下令。",
	["$fanqian2"] = "左舷，发现敌舰！",
	["$fanqian3"] = " 是的。随时可以出击。",
	[":fanqian"] = "出牌阶段，你的一张延时锦囊、【闪】、【金色宣言】以外的牌可以指定场上一名存活角色，然后视为你对其使用了这张牌。",
	["Buyu"] = "不渝",
	["@Buyu"] = "不渝",
	["$Buyu1"] = "司令官…是的！那份约定…和司令官重要的约定，我绝对会守护到底的！",
	["$Buyu2"] = "司令官说要等着的话，我朝潮，会有在一直这里等着的觉悟！",
	[":Buyu"] = "出牌阶段开始时，你可指定一名其他角色，若如此，你该阶段每使用一张黑色【杀】以外的牌指定目标时，若该角色为目标之一，你可摸一张牌；否则你需要弃置一张牌。",
	["Asashio"] = "朝潮",
	["&Asashio"] = "朝潮",
	["@Asashio"] = "舰队collection",
	["#Asashio"] = "信守不渝",
	["~Asashio"] = "还没…还没有沉没…那份约定还没有…完成….",
	["designer:Asashio"] = "钉子",
	["cv:Asashio"] = "宫川若菜",
	["illustrator:Asashio"] = "カット＠お仕事募集中",

	["eryu"] = "二羽",
	["$eryu1"] = "翔鹤姐，要上了！舰首迎风，攻击队，开始起飞！",
	["$eryu2"] = "翔鹤姐姐还好吗？",
	["$eryu3"] = "感觉很好呀♪",
	["@EryuMark"] = "二羽",
	[":eryu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你未拥有“羽”标记，你可以与一名女性角色各获得一个“羽”标记。若如此做，你或该角色【金色宣言】以外的通常锦囊牌和基本牌因使用从各自的区域离开时，对方获得之。",
	["zheyi"] = "折翼",
	["$zheyi1"] = "翔鹤姐，没事吗？总觉得，有点担心…",
	[":zheyi"] = "<font color=\"purple\"><b>觉醒技，</b></font>拥有“羽”标记的角色进入濒死状态时，你回复一点体力上限和体力，失去技能“二羽”并获得技能“诱敌”",
	["zheyi$"] = "image=image/animate/zheyi.png",
	["youdiz"] = "诱敌",
	["@Youdi"] = "诱敌",
	["$youdiz1"] = "第一波攻击编队，准备出击！",
	["$youdiz2"] = "第二波攻击编队，全体作战飞机，出击！",
	[":youdiz"] = "回合开始时，你可以令一名攻击范围内有你的其他角色立即进行一个额外的回合，但该回合内其仅能对你造成伤害。你在该回合受到伤害时，令一名其他角色摸一张牌。该回合结束时，将其角色牌翻面。",
	["youdi_draw"] = "诱敌（摸牌）",
	["Zuikaku"] = "瑞鶴",
	["&Zuikaku"] = "瑞鶴",
	["@Zuikaku"] = "艦隊collection",
	["#Zuikaku"] = "最后的正规空母",
	["~Zuikaku"] = "挺，挺能干的嘛…！",
	["designer:Zuikaku"] = "Sword Elucidator",
	["cv:Zuikaku"] = "野水伊織",
	["illustrator:Zuikaku"] = "わだつみ",

	["nuequ"] = "杀驱「傻级只会打驱逐舰吧？」",
	["$nuequ1"] = "射击！Fire～！",
	["$nuequ2"] = "全火炮！开火！",
	[":nuequ"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌视为对场上体力最少的一名角色使用一张火属性的【杀】。该【杀】不计入出牌阶段次数限制。",
	["BurningLove"] = "Burning Love！",
	["$BurningLove1"] = "Burning Love！！",
	["$BurningLove2"] = "Burning Valentine Love！！",
	[":BurningLove"] = "每当你使用火属性的【杀】造成伤害时，你可以令该伤害改为回复一点体力。",
	["BLRecover"] = "令该伤害改为回复一点体力",
	["BLDamage"] = "令该伤害+1",
	["Kongou"] = "金剛",
	["&Kongou"] = "金剛",
	["@Kongou"] = "艦隊collection",
	["#Kongou"] = "大傻",
	["~Kongou"] = "Shit！从提督那里得到的重要装备啊！",
	["designer:Kongou"] = "Sword Elucidator",
	["cv:Kongou"] = "東山奈央",
	["illustrator:Kongou"] = "",

	["fanghuo"] = "放火「烧甲板」",
	["#fanghuo"] = " %from 的【着火】 标记被触发，受到自身造成的一点火焰伤害，",
	["@FireCaused"] = "着火",
	["$fanghuo1"] = "最上，出击了哟。",
	["$fanghuo2"] = "敌舰发现！攻击—！",
	[":fanghuo"] = "你使用的【杀】造成伤害时，你可以令目标附加一个【着火】标记。\n\n着火：\n拥有【着火】标记的角色出牌阶段结束时，受到自身造成的一点火焰伤害，然后有25%的概率失去一个【着火】标记。\n拥有【着火】标记时，舰载机类技能无法使用。",
	["jianhun"] = "舰魂",
	["$jianhun1"] = "好痛痛痛…我要生气了！",
	["$jianhun2"] = "痛…我要生气了哦！",
	["$jianhun3"] = " 要上的话就尽管来吧。",
	[":jianhun"] = "若场上「西村舰队（最上，时雨）」角色失去的总体力值不少于2，或你拥有【着火】标记，你可以将一张牌当做无视使用次数限制和距离的【杀】使用或打出。",
	["Mogami"] = "最上",
	["&Mogami"] = "最上",
	["@Mogami"] = "舰队collection/wows",
	["#Mogami"] = "最爹",
	["~Mogami"] = "唔…这下要是继续战斗的话就困难了。",
	["designer:Mogami"] = "Sword Elucidator",
	["cv:Mogami"] = "洲崎綾",
	["illustrator:Mogami"] = "ケースワベ【K-SUWABE】",



}

return { extension }
