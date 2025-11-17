--==《三国 杀神附体——妖》==--
extension = sgs.Package("keyaobao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()



yaochangetupo = sgs.CreateTriggerSkill {
	name = "yaochangetupo",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill("keyaotaiping")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaozhangjiao", false, true, player:getGeneral2Name()=="keyaozhangjiao", false)
			end
		end
		if (player:hasSkill("keyaobuhui")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaozhoutai", false, true, player:getGeneral2Name()=="keyaozhoutai", false)
			end
		end
		if (player:hasSkill("keyaozhabing")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaosimayi", false, true, player:getGeneral2Name()=="keyaosimayi", false)
			end
		end
		if (player:hasSkill("keyaoquwu")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaoxiaoqiao", false, true, player:getGeneral2Name()=="keyaoxiaoqiao", false)
			end
		end
		if (player:hasSkill("keyaoshidu")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaojiping", false, true, player:getGeneral2Name()=="keyaojiping", false)
			end
		end
		if (player:hasSkill("keyaoxieqin")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaochengyu", false, true, player:getGeneral2Name()=="keyaochengyu", false)
			end
		end
	end,
	priority = 5,
}
if not sgs.Sanguosha:getSkill("yaochangetupo") then skills:append(yaochangetupo) end




keyaozhangjiao = sgs.General(extension, "keyaozhangjiao$", "keyao", 3, true)

keyaotaiping = sgs.CreateViewAsSkill {
	name = "keyaotaiping",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		for _, ca in sgs.list(selected) do
			if ca:getSuit() ~= to_select:getSuit() then return false end
		end
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			if suit == sgs.Card_Heart then
				local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Spade then
				local aa = sgs.Sanguosha:cloneCard("savage_assault", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Diamond then
				local aa = sgs.Sanguosha:cloneCard("god_salvation", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Club then
				local aa = sgs.Sanguosha:cloneCard("amazing_grace", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasFlag("useyaotaiping"))
	end
}
keyaozhangjiao:addSkill(keyaotaiping)

keyaotaipingex = sgs.CreateTriggerSkill {
	name = "#keyaotaipingex",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.CardFinished then
			if use.from:hasSkill("keyaotaiping") then
				if use.card:getSkillName() == "keyaotaiping" then
					room:setPlayerFlag(use.from, "useyaotaiping")
				end
			end
		end
	end
}
keyaozhangjiao:addSkill(keyaotaipingex)

keyaotaipingextwo = sgs.CreateTriggerSkill {
	name = "#keyaotaipingextwo",
	events = { sgs.EventPhaseEnd },
	can_trigger = function(self, target)
		return target:hasSkill("keyaotaiping")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_Play then return false end
			if player:hasFlag("useyaotaiping") then
				room:setPlayerFlag(player, "-useyaotaiping")
			end
		end
	end
}
keyaozhangjiao:addSkill(keyaotaipingextwo)
extension:insertRelatedSkills("keyaotaiping", "#keyaotaipingex")
extension:insertRelatedSkills("keyaotaiping", "#keyaotaipingextwo")



keyaojiazi = sgs.CreateTriggerSkill {
	name = "keyaojiazi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local hp = player:getHp()
				if player:getHandcardNum() < hp and room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					local cha = hp - player:getHandcardNum()
					player:drawCards(cha)
				end
			end
		end
	end,
}
keyaozhangjiao:addSkill(keyaojiazi)

keyaotuzhong = sgs.CreatePhaseChangeSkill {
	name = "keyaotuzhong$",
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if player:hasLordSkill(self:objectName()) and player:askForSkillInvoke(self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "yaotuzhong-ask",
					true, true)
				if target then
					local recover = sgs.RecoverStruct()
					recover.who = target
					room:recover(target, recover)
				end
				return true
			end
		end
		return false
	end
}
keyaozhangjiao:addSkill(keyaotuzhong)







keyaosimayi = sgs.General(extension, "keyaosimayi", "keyao", 3, true)

keyaozhabing = sgs.CreateTriggerSkill {
	name = "keyaozhabing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player, "&keyaozhabing", 0)
			end
			if change.to == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(player, 1, true, player, self:objectName())
					room:addPlayerMark(player, "&keyaozhabing")
				end
			end
		end
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to:getMark("&keyaozhabing") > 0 then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
	end,
}
keyaosimayi:addSkill(keyaozhabing)



keyaoguimou = sgs.CreateTriggerSkill {
	name = "keyaoguimou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local los = player:getLostHp()
		if los > 0 and player:askForSkillInvoke(self:objectName()) then
			draw.num = draw.num + los
			room:broadcastSkillInvoke(self:objectName())
		end
		data:setValue(draw)
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
keyaosimayi:addSkill(keyaoguimou)


keyaozhoutai = sgs.General(extension, "keyaozhoutai", "keyao", 4, true)

keyaobuhui = sgs.CreateProhibitSkill {
	name = "keyaobuhui",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash"))
	end
}
keyaozhoutai:addSkill(keyaobuhui)





keyaoxiaoqiao = sgs.General(extension, "keyaoxiaoqiao", "keyao", 3, false)

keyaoquwuCard = sgs.CreateSkillCard {
	name = "keyaoquwuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and
			(sgs.Self:inMyAttackRange(to_select))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&keyaoquwu")
		room:addPlayerMark(player, "useyaoquwu")
	end
}
--主技能
keyaoquwuVS = sgs.CreateViewAsSkill {
	name = "keyaoquwu",
	n = 0,
	view_as = function(self, cards)
		return keyaoquwuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#keyaoquwuCard"))
	end,
}

keyaoquwu = sgs.CreateTriggerSkill {
	name = "keyaoquwu",
	events = { sgs.DrawNCards },
	view_as_skill = keyaoquwuVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.DrawNCards then
			local room = player:getRoom()
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local los = player:getMark("&keyaoquwu")
			for _, xq in sgs.qlist(room:getAllPlayers()) do
				if xq:getMark("useyaoquwu") > 0 then
					local num = xq:getMark("useyaoquwu")
					xq:drawCards(num)
					room:setPlayerMark(xq, "useyaoquwu", 0)
				end
			end
			draw.num = draw.num - los
			data:setValue(draw)
			room:setPlayerMark(player, "&keyaoquwu", 0)
		end
	end,
	can_trigger = function(self, player)
		return player:getMark("&keyaoquwu") > 0
	end,
}
keyaoxiaoqiao:addSkill(keyaoquwu)


keyaotongque = sgs.CreateTriggerSkill {
	name = "keyaotongque",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if event == sgs.TargetConfirming and use.to:contains(player) then
				if (use.card:isKindOf("Analeptic")) or (use.card:isKindOf("IronChain")) then
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill("keyaotongque")
	end,
}
keyaoxiaoqiao:addSkill(keyaotongque)


keyaozhongshang = sgs.CreateTriggerSkill {
	name = "keyaozhongshang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local yxqs = room:findPlayersBySkillName("keyaozhongshang")
		for _, xq in sgs.qlist(yxqs) do
			room:addMaxCards(xq, 1, false)
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
keyaoxiaoqiao:addSkill(keyaozhongshang)





keyaobianshi = sgs.General(extension, "keyaobianshi", "keyao", 3, false)


keyaojiahuo = sgs.CreateOneCardViewAsSkill {
	name = "keyaojiahuo",
	filter_pattern = ".|black",
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("usedyaojiahuo")
	end,
}

keyaobianshi:addSkill(keyaojiahuo)

keyaojiahuoex = sgs.CreateTriggerSkill {
	name = "#keyaojiahuoex",
	events = { sgs.CardFinished, },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.CardFinished then
			if use.from:hasSkill("keyaojiahuo") then
				if use.card:getSkillName() == "keyaojiahuo" then
					room:setPlayerFlag(use.from, "usedyaojiahuo")
				end
			end
		end
	end
}
keyaobianshi:addSkill(keyaojiahuoex)

keyaojiahuoextwo = sgs.CreateTriggerSkill {
	name = "#keyaojiahuoextwo",
	events = { sgs.EventPhaseEnd },
	can_trigger = function(self, target)
		return target:hasSkill("keyaojiahuo")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_Play then return false end
			if player:hasFlag("usedyaojiahuo") then
				room:setPlayerFlag(player, "-usedyaojiahuo")
			end
		end
	end
}
keyaobianshi:addSkill(keyaojiahuoextwo)



keyaoleimu = sgs.CreateTriggerSkill {
	name = "keyaoleimu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		if event == sgs.ConfirmDamage then
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				damage.nature = sgs.DamageStruct_Thunder
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
keyaobianshi:addSkill(keyaoleimu)

keyaoyaohou = sgs.CreateTriggerSkill {
	name = "keyaoyaohou",
	events = { sgs.Damaged },
	--global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local eny = damage.to
			local from = damage.from
			if from and (from:getRole() == "lord") and (from:getGender() == sgs.General_Male) then
				local bss = room:findPlayersBySkillName("keyaoyaohou")
				if not bss:isEmpty() then
					for _, bs in sgs.qlist(bss) do
						local choicelist = "mopai"
						if eny:getCardCount(true) > 0 then
							choicelist = string.format("%s+%s", choicelist, "huode")
						end
						choicelist = string.format("%s+%s", choicelist, "cancel")

						local choice = room:askForChoice(bs, self:objectName(), choicelist, data)
						if choice == "huode" then
							local card_id = room:askForCardChosen(bs, eny, "he", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, bs:objectName())
							room:obtainCard(bs, sgs.Sanguosha:getCard(card_id), reason,
								room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						end
						if choice == "mopai" then
							bs:drawCards(1)
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
keyaobianshi:addSkill(keyaoyaohou)


keyaojiping = sgs.General(extension, "keyaojiping", "keyao", 3)

keyaoshiduCard = sgs.CreateSkillCard {
	name = "keyaoshiduCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) then return false end
		return (to_select:objectName() ~= sgs.Self:objectName()) and
			(to_select:getMark("keyaoshidu" .. sgs.Self:objectName()) == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "keyaoshidu" .. player:objectName())
		room:addPlayerMark(target, "&keyaoshidu")
	end
}

keyaoshiduVS = sgs.CreateViewAsSkill {
	name = "keyaoshidu",
	n = 1,
	view_filter = function(self, cards, to_select)
		--return not sgs.Self:isJilei(to_select)
		return (to_select:getSuit() == sgs.Card_Spade) and
			(to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = keyaoshiduCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

keyaoshidu = sgs.CreatePhaseChangeSkill {
	name = "keyaoshidu",
	view_as_skill = keyaoshiduVS,
	on_phasechange = function()
	end
}
keyaojiping:addSkill(keyaoshidu)

keyaoshidubuff = sgs.CreateTriggerSkill {
	name = "#keyaoshidubuff",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Start then
			return false
		end
		local x = player:getMark("&keyaoshidu")
		for i = 0, x - 1, 1 do
			room:removePlayerMark(player, "&keyaoshidu")
			local target
			local jipings = room:findPlayersBySkillName("keyaoshidu")
			for _, jiping in sgs.qlist(jipings) do
				if player:getMark("keyaoshidu" .. jiping:objectName()) > 0 then
					target = jiping
					room:removePlayerMark(player, "keyaoshidu" .. jiping:objectName())
					break
				end
			end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.good = true
			judge.play_animation = false
			judge.who = player
			judge.reason = self:objectName()
			room:judge(judge)
			if judge:isGood() then
				local log = sgs.LogMessage()
				log.type = "$keyaoshidulog"
				log.from = player

				local damage = sgs.DamageStruct()

				damage.to = player
				damage.damage = 1
				if target then
					log.from = target
					damage.from = target
				end
				room:sendLog(log)
				room:damage(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("&keyaoshidu") > 0
	end,
}
keyaojiping:addSkill(keyaoshidubuff)
extension:insertRelatedSkills("keyaoshidu", "#keyaoshidubuff")


keyaogongdu = sgs.CreateViewAsSkill {
	name = "keyaogongdu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isBlack() and not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		local phase = player:getPhase()
		if phase == sgs.Player_NotActive then
			return string.find(pattern, "peach")
		end
		return false
	end
}
keyaojiping:addSkill(keyaogongdu)

keyaoliandu = sgs.CreateTriggerSkill {
	name = "keyaoliandu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local hurt = damage.damage
		if hurt > 1 then
			damage.damage = 1
			local log = sgs.LogMessage()
			log.type = "$yaojiping_damage"
			log.from = player
			room:sendLog(log)
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, player)
		return (player:hasSkill("keyaoliandu"))
	end
}
keyaojiping:addSkill(keyaoliandu)




keyaolingtong = sgs.General(extension, "keyaolingtong", "wu", 4)

keyaozhongyi = sgs.CreateTriggerSkill {
	name = "keyaozhongyi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local num = player:getHp()
				player:drawCards(num, self:objectName())
			end
		end
		return false
	end
}
keyaolingtong:addSkill(keyaozhongyi)


keyaochengyu = sgs.General(extension, "keyaochengyu", "wei", 3)

keyaoxieqin = sgs.CreateTriggerSkill {
	name = "keyaoxieqin",
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		if event == sgs.Damage then
			local room = player:getRoom()
			local damage = data:toDamage()
			if (damage.from:hasSkill("keyaoxieqin")) and (damage.from:getMark("canuseyaoxieqin_lun") == 0) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
					if damage.from:canDiscard(p, "he") then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local ano = room:askForPlayerChosen(damage.from, players, self:objectName(), "yaoxieqin-ask", true,
						true)
					if ano then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(damage.from, "keyaoxieqin_lun")
						if damage.from:canDiscard(ano, "he") then
							local to_throw = room:askForCardChosen(damage.from, ano, "he", self:objectName())
							local card = sgs.Sanguosha:getCard(to_throw)
							room:throwCard(card, ano, damage.from);
						end
					end
				end
			end
		end
	end,
}
keyaochengyu:addSkill(keyaoxieqin)

keyaoshiwei = sgs.CreateTriggerSkill {
	name = "keyaoshiwei",
	events = { sgs.StartJudge, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.StartJudge then
			local judge = data:toJudge()
			local chengyus = room:findPlayersBySkillName("keyaoshiwei")
			if not chengyus:isEmpty() then
				for _, chengyu in sgs.qlist(chengyus) do
					if room:askForSkillInvoke(chengyu, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local result = room:askForChoice(chengyu, self:objectName(), "black+red")
						if result == "black" then
							local log = sgs.LogMessage()
							log.type = "$keyaoshiweiblacklog"
							log.from = chengyu
							room:sendLog(log)
							room:setPlayerMark(chengyu, "yaoshiweiblack", 1)
						end
						if result == "red" then
							local log = sgs.LogMessage()
							log.type = "$keyaoshiweiredlog"
							log.from = chengyu
							room:sendLog(log)
							room:setPlayerMark(chengyu, "yaoshiweired", 1)
						end
					end
				end
			end
		end
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			local cys = room:findPlayersBySkillName("keyaoshiwei")
			if not cys:isEmpty() then
				for _, cy in sgs.qlist(cys) do
					if (judge.card:isRed()) and (cy:getMark("yaoshiweired") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiredyeslog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(1, self:objectName())
					end
					if (judge.card:isBlack()) and (cy:getMark("yaoshiweiblack") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiblackyeslog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(1, self:objectName())
					end
					if (judge.card:isRed()) and (cy:getMark("yaoshiweiblack") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiblacknolog"
						log.from = cy
						room:sendLog(log)
					end
					if (judge.card:isBlack()) and (cy:getMark("yaoshiweired") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweirednolog"
						log.from = cy
						room:sendLog(log)
					end
					room:setPlayerMark(cy, "yaoshiweired", 0)
					room:setPlayerMark(cy, "yaoshiweiblack", 0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
keyaochengyu:addSkill(keyaoshiwei)




--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



kejieyaozhangjiao = sgs.General(extension, "kejieyaozhangjiao$", "keyao", 3, true)

kejieyaotaiping = sgs.CreateViewAsSkill {
	name = "kejieyaotaiping",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		for _, ca in sgs.list(selected) do
			if ca:getSuit() ~= to_select:getSuit() then return false end
		end
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			if suit == sgs.Card_Heart then
				local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Spade then
				local aa = sgs.Sanguosha:cloneCard("savage_assault", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Diamond then
				local aa = sgs.Sanguosha:cloneCard("god_salvation", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Club then
				local aa = sgs.Sanguosha:cloneCard("amazing_grace", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
kejieyaozhangjiao:addSkill(kejieyaotaiping)


kejieyaojiazi = sgs.CreateTriggerSkill {
	name = "kejieyaojiazi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local hp = player:getMaxHp()
				if player:getHandcardNum() < hp then
					local cha = hp - player:getHandcardNum()
					if cha > 0 then
						room:broadcastSkillInvoke(self:objectName())
					end
					player:drawCards(cha)
				end
			end
		end
	end,
}
kejieyaozhangjiao:addSkill(kejieyaojiazi)


--[[kejieyaotuzhong = sgs.CreateTriggerSkill{
	name = "kejieyaotuzhong$" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.DrawNCards then
			local invoked = false
			if player:isSkipped(sgs.Player_Draw) then return false end
			invoked = player:askForSkillInvoke(self:objectName())
			if invoked then
				player:skip(sgs.Player_Draw)
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "yaotuzhong-ask", true, true)
				if target then
					room:recover(target, sgs.RecoverStruct())
					target:drawCards(1)
				end
			end			
		end
		return false
	end
}]]


kejieyaotuzhong = sgs.CreatePhaseChangeSkill {
	name = "kejieyaotuzhong$",
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local invoked = false
			if player:hasLordSkill(self:objectName()) then
				invoked = player:askForSkillInvoke(self:objectName())
				if invoked then
					local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(),
						"yaotuzhong-ask", true, true)
					if target then
						room:recover(target, sgs.RecoverStruct())
						target:drawCards(1)
					end
					return true
				end
			end
		end
		return false
	end
}
kejieyaozhangjiao:addSkill(kejieyaotuzhong)




kejieyaosimayi = sgs.General(extension, "kejieyaosimayi", "keyao", 3, true)

kejieyaozhabing = sgs.CreateTriggerSkill {
	name = "kejieyaozhabing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging --[[,sgs.DamageInflicted]] },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player, "&keyaozhabing", 0)
			end
			if change.to == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(player, 1, true, player, self:objectName())
					room:addPlayerMark(player, "&keyaozhabing")
				end
			end
		end
	end,
}
kejieyaosimayi:addSkill(kejieyaozhabing)

kejieyaozhabingexjl = sgs.CreateDistanceSkill {
	name = "kejieyaozhabingexjl",
	global = true,
	correct_func = function(self, from, to)
		if (to:hasSkill("kejieyaozhabing")) and (to:getMark("&keyaozhabing") > 0) then
			return to:getLostHp()
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhabingexjl") then skills:append(kejieyaozhabingexjl) end

kejieyaozhabingex = sgs.CreateProhibitSkill {
	name = "kejieyaozhabingex",
	global = true,
	is_prohibited = function(self, from, to, card)
		return (to:getMark("&keyaozhabing") > 0) and (card:isDamageCard())
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhabingex") then skills:append(kejieyaozhabingex) end



kejieyaoguimou = sgs.CreateTriggerSkill {
	name = "kejieyaoguimou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local los = player:getLostHp()
		draw.num = draw.num + los
		if player:isWounded() then
			room:broadcastSkillInvoke(self:objectName())
			for _, id in sgs.qlist(room:getDrawPile()) do
				if (sgs.Sanguosha:getCard(id):isKindOf("TrickCard")) then
					room:obtainCard(player, id, true)
					break
				end
			end
		end
		data:setValue(draw)
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
kejieyaosimayi:addSkill(kejieyaoguimou)

kejieyaozhoutai = sgs.General(extension, "kejieyaozhoutai", "keyao", 5, true)

kejieyaobuhui = sgs.CreateProhibitSkill {
	name = "kejieyaobuhui",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Peach"))
	end
}
kejieyaozhoutai:addSkill(kejieyaobuhui)

kejieyaofenwei = sgs.CreateTriggerSkill {
	name = "kejieyaofenwei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventAcquireSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
				local one = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"kejieyaofenwei-ask", true, true)
				if one then
					room:broadcastSkillInvoke(self:objectName())
					room:handleAcquireDetachSkills(player, "-kejieyaobuhui")
					if not one:hasSkill("kejieyaobuhui") then
						room:handleAcquireDetachSkills(one, "kejieyaobuhui")
						room:addPlayerMark(one, "&kejieyaofenwei", 1)
					end
				end
			end
			if change.to == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
				local tri = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kejieyaofenwei") > 0 then
						tri = 1
					end
				end
				if (tri == 1) and room:askForSkillInvoke(player, "kejieyaofenwei_shouhui", data) then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:getMark("&kejieyaofenwei") > 0 then
							room:removePlayerMark(p, "&kejieyaofenwei", 1)
							if p:hasSkill("kejieyaobuhui") then
								room:handleAcquireDetachSkills(p, "-kejieyaobuhui")
							end
							if not player:hasSkill("kejieyaobuhui") then
								room:handleAcquireDetachSkills(player, "kejieyaobuhui")
							end
						end
					end
				end
			end
		end
		if (event == sgs.EventAcquireSkill) and (data:toString() == "kejieyaobuhui") then
			local yzts = room:findPlayersBySkillName("kejieyaofenwei")
			for _, yzt in sgs.qlist(yzts) do
				local dest = sgs.QVariant()
				dest:setValue(player)
				if room:askForSkillInvoke(yzt, "kejieyaofenwei_mopai", dest) then
					player:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejieyaozhoutai:addSkill(kejieyaofenwei)



--界妖小乔

kejieyaoxiaoqiao = sgs.General(extension, "kejieyaoxiaoqiao", "keyao", 3, false)

kejieyaoquwuCard = sgs.CreateSkillCard {
	name = "kejieyaoquwuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and
			(to_select:getMark("&kejieyaoquwu") == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&kejieyaoquwu")
		room:addPlayerMark(player, "usejieyaoquwu")
		room:removePlayerMark(player, "canusequwucishu", 1)
	end
}
--主技能
kejieyaoquwuVS = sgs.CreateViewAsSkill {
	name = "kejieyaoquwu",
	n = 0,
	view_as = function(self, cards)
		return kejieyaoquwuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("canusequwucishu") > 0)
	end,
}


kejieyaoquwu = sgs.CreateTriggerSkill {
	name = "kejieyaoquwu",
	events = { sgs.DrawNCards },
	view_as_skill = kejieyaoquwuVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.DrawNCards then
			local room = player:getRoom()
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local los = player:getMark("&kejieyaoquwu")
			for _, xq in sgs.qlist(room:getAllPlayers()) do
				if xq:getMark("usejieyaoquwu") > 0 then
					xq:drawCards(1)
					room:removePlayerMark(xq, "usejieyaoquwu", 1)
				end
			end
			draw.num = draw.num - los
			data:setValue(draw)
			room:setPlayerMark(player, "&kejieyaoquwu", 0)
		end
	end,
	can_trigger = function(self, player)
		return player:getMark("&kejieyaoquwu") > 0
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaoquwu)


kejieyaotongque = sgs.CreateTriggerSkill {
	name = "kejieyaotongque",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if event == sgs.TargetConfirming and use.to:contains(player) then
				if use.card:isKindOf("Analeptic") or use.card:isKindOf("IronChain") then
					if use.card:isKindOf("Analeptic") then
						room:addPlayerMark(player, "&jieyaoquwunum", 1)
						if player:getPhase() == sgs.Player_Play then
							room:addPlayerMark(player, "canusequwucishu", 1)
						end
					end
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				local num = player:getMark("&jieyaoquwunum") + 1
				room:setPlayerMark(player, "canusequwucishu", num)
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill("kejieyaotongque")
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaotongque)


kejieyaozhongshang = sgs.CreateTriggerSkill {
	name = "kejieyaozhongshang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local yxqs = room:findPlayersBySkillName("kejieyaozhongshang")
		for _, xq in sgs.qlist(yxqs) do
			room:addMaxCards(xq, 1, false)
			room:recover(xq, sgs.RecoverStruct())
			room:addPlayerMark(xq, "&".. self:objectName())
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaozhongshang)



kejieyaoxiaoqiaotwo = sgs.General(extension, "kejieyaoxiaoqiaotwo", "keyao", 3, false)

kejieyaoquwutwo = sgs.CreateTriggerSkill {
	name = "kejieyaoquwutwo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local room = player:getRoom()
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player, "&quwutlcount", player:getHp())
				room:setPlayerMark(player, "&quwuspcount", player:getHandcardNum())
			end
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "&quwutlcount", 0)
				room:setPlayerMark(player, "&quwuspcount", 0)
			end
		end
		if event == sgs.EventPhaseEnd then
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Play then
				local tl = player:getHp()
				local sp = player:getHandcardNum()
				local mz = 0
				if tl ~= player:getMark("&quwutlcount") then
					mz = mz + 1
				end
				if sp ~= player:getMark("&quwuspcount") then
					mz = mz + 1
				end
				if (mz >= 1) then
					local xqs = room:findPlayersBySkillName(self:objectName())
					if not xqs:isEmpty() then
						for _, xq in sgs.qlist(xqs) do
							if room:askForSkillInvoke(xq, self:objectName(), data) then
								room:broadcastSkillInvoke(self:objectName())
								xq:drawCards(1)
								if mz > 1 then
									if not player:isChained() then
										room:setPlayerChained(player)
									end
								end
							end
						end
					end
				end
				room:setPlayerMark(player, "&quwutlcount", 0)
				room:setPlayerMark(player, "&quwuspcount", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaoquwutwo)

kejieyaotongquetwo = sgs.CreateTriggerSkill {
	name = "kejieyaotongquetwo",
	events = { sgs.DamageInflicted },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank"))
			or (damage.chain) then
			if not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
				local discard = room:askForDiscard(player, self:objectName(), 1, 1, true, false, "kejieyaotongquetwo-dis")
				if discard then
					room:broadcastSkillInvoke("kejieyaoquwutwo")
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					local death = sgs.DeathStruct()
					death.who = player
					death.damage = damage
					local _data = sgs.QVariant()
					_data:setValue(death)
					room:getThread():delay(500)
					room:getThread():trigger(sgs.QuitDying, room, player, _data)
					local hurt = damage.damage
					if hurt == 1 then
						return true
					end
					if hurt > 1 then
						damage.damage = hurt - 1
						data:setValue(damage)
					end
				end
			end
		end
	end
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaotongquetwo)

kejieyaozhongshangtwo = sgs.CreateTriggerSkill {
	name = "kejieyaozhongshangtwo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.QuitDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local yxqs = room:findPlayersBySkillName(self:objectName())
		for _, xq in sgs.qlist(yxqs) do
			local result = room:askForChoice(xq, self:objectName(), "maxhp+handmax")
			if result == "maxhp" then
				room:recover(xq, sgs.RecoverStruct())
			end
			if result == "handmax" then
				room:addPlayerMark(xq, "&kejieyaozhongshangtwo")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaozhongshangtwo)

kejieyaozhongshangtwokeep = sgs.CreateMaxCardsSkill {
	name = "kejieyaozhongshangtwokeep",
	frequency = sgs.Skill_Compulsory,
	global = true,
	extra_func = function(self, target)
		if (target:getMark("&kejieyaozhongshangtwo") > 0) then
			return target:getMark("&kejieyaozhongshangtwo")
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhongshangtwokeep") then skills:append(kejieyaozhongshangtwokeep) end





--界妖吉平

kejieyaojiping = sgs.General(extension, "kejieyaojiping", "keyao", 3)

kejieyaoshiduCard = sgs.CreateSkillCard {
	name = "kejieyaoshiduCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) then return false end
		return (to_select:objectName() ~= sgs.Self:objectName()) and (to_select:getMark("&keyaoshidu") == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&kejieyaoshidu")
		room:addPlayerMark(target, "kejieyaoshidu" .. player:objectName())
	end
}

kejieyaoshiduVS = sgs.CreateViewAsSkill {
	name = "kejieyaoshidu",
	n = 1,
	view_filter = function(self, cards, to_select)
		return (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kejieyaoshiduCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}


kejieyaoshidu = sgs.CreateTriggerSkill {
	name = "kejieyaoshidu",
	view_as_skill = kejieyaoshiduVS,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Start then
			return false
		end
		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, "kejieyaoshidu") and player:getMark(mark) > 0 then
				local target
				room:removePlayerMark(player, mark)
				local jipings = room:findPlayersBySkillName("kejieyaoshidu")
				for _, jiping in sgs.qlist(jipings) do
					if string.find(mark, jiping:objectName()) then
						target = jiping
						break
					end
				end
				if target then
					room:sendCompulsoryTriggerLog(target, self:objectName())
				else
					room:sendCompulsoryTriggerLog(player, self:objectName())
				end

				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				local suit = judge.card:getSuit()
				local damage = sgs.DamageStruct()
				damage.from = nil
				damage.to = player
				if target then
					damage.from = target
				end
				if (suit == sgs.Card_Club) or (suit == sgs.Card_Diamond) then
					damage.damage = 1
				elseif suit == sgs.Card_Spade then
					damage.damage = 2
				end
				local log = sgs.LogMessage()
				log.type = "$keyaoshidulog"
				log.from = target
				room:sendLog(log)
				if suit == sgs.Card_Heart then
					target:drawCards(1)
				else
					room:damage(damage)
				end
			end
		end
		room:setPlayerMark(player, "&kejieyaoshidu", 0)
	end,
	can_trigger = function(self, player)
		return (player:getMark("&kejieyaoshidu") > 0)
	end,
}
kejieyaojiping:addSkill(kejieyaoshidu)

kejieyaogongdu = sgs.CreateViewAsSkill {
	name = "kejieyaogongdu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isBlack()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return true
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach")
	end
}
kejieyaojiping:addSkill(kejieyaogongdu)

kejieyaoliandu = sgs.CreateTriggerSkill {
	name = "kejieyaoliandu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local hurt = damage.damage
		if hurt > 1 then
			damage.damage = 1
			local log = sgs.LogMessage()
			log.type = "$yaojiping_damage"
			log.from = player
			room:sendLog(log)
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, player)
		return (player:hasSkill("kejieyaoliandu"))
	end
}
kejieyaojiping:addSkill(kejieyaoliandu)


--界程昱

kejieyaochengyu = sgs.General(extension, "kejieyaochengyu", "wei", 3)


kejieyaoxieqin = sgs.CreateTriggerSkill {
	name = "kejieyaoxieqin",
	events = { sgs.Damage, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		if event == sgs.Damage then
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:objectName() ~= damage.to:objectName() then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					if room:askForSkillInvoke(damage.from, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local ano = room:askForPlayerChosen(damage.from, players, self:objectName(), "yaoxieqin-ask",
							true, true)
						if ano then
							if damage.from:canDiscard(ano, "he") then
								local to_throw = room:askForCardChosen(damage.from, ano, "he", self:objectName())
								local card = sgs.Sanguosha:getCard(to_throw)
								room:throwCard(card, ano, damage.from);
							end
						end
					end
				end
			end
		end
		if event == sgs.Damaged then
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:objectName() ~= damage.to:objectName() then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					if room:askForSkillInvoke(damage.to, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local ano = room:askForPlayerChosen(damage.to, players, self:objectName(), "yaoxieqin-ask", true,
							true)
						if ano then
							if damage.to:canDiscard(ano, "he") then
								local to_throw = room:askForCardChosen(damage.to, ano, "he", self:objectName())
								local card = sgs.Sanguosha:getCard(to_throw)
								room:throwCard(card, ano, damage.to);
							end
						end
					end
				end
			end
		end
	end,
}
kejieyaochengyu:addSkill(kejieyaoxieqin)

kejieyaoshiwei = sgs.CreateTriggerSkill {
	name = "kejieyaoshiwei",
	events = { sgs.StartJudge, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.StartJudge then
			local judge = data:toJudge()
			local chengyus = room:findPlayersBySkillName("kejieyaoshiwei")
			if not chengyus:isEmpty() then
				for _, chengyu in sgs.qlist(chengyus) do
					if room:askForSkillInvoke(chengyu, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local result = room:askForChoice(chengyu, self:objectName(), "black+red")
						if result == "black" then
							local log = sgs.LogMessage()
							log.type = "$keyaoshiweiblacklog"
							log.from = chengyu
							room:sendLog(log)
							room:setPlayerMark(chengyu, "yaoshiweiblack", 1)
						end
						if result == "red" then
							local log = sgs.LogMessage()
							log.type = "$keyaoshiweiredlog"
							log.from = chengyu
							room:sendLog(log)
							room:setPlayerMark(chengyu, "yaoshiweired", 1)
						end
					end
				end
			end
		end
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			local cys = room:findPlayersBySkillName("kejieyaoshiwei")
			if not cys:isEmpty() then
				for _, cy in sgs.qlist(cys) do
					if (judge.card:isRed()) and (cy:getMark("yaoshiweired") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiredyeslog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(2, self:objectName())
					end
					if (judge.card:isBlack()) and (cy:getMark("yaoshiweiblack") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiblackyeslog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(2, self:objectName())
					end
					if (judge.card:isRed()) and (cy:getMark("yaoshiweiblack") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweiblacknolog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(1, self:objectName())
					end
					if (judge.card:isBlack()) and (cy:getMark("yaoshiweired") > 0) then
						local log = sgs.LogMessage()
						log.type = "$keyaoshiweirednolog"
						log.from = cy
						room:sendLog(log)
						cy:drawCards(1, self:objectName())
					end
					room:setPlayerMark(cy, "yaoshiweired", 0)
					room:setPlayerMark(cy, "yaoshiweiblack", 0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kejieyaochengyu:addSkill(kejieyaoshiwei)







sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["keyaobao"] = "妖包",

	["yaochangetupo"] = "将武将更换为界限突破版本",


	--妖司马懿

	["keyaosimayi"] = "妖司马懿",
	["&keyaosimayi"] = "妖司马懿",
	["#keyaosimayi"] = "冢虎",
	["designer:keyaosimayi"] = "杀神附体",
	["cv:keyaosimayi"] = "官方",
	["illustrator:keyaosimayi"] = "三国无双",

	["keyaozhabing"] = "诈病",
	[":keyaozhabing"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以失去1点体力，若如此做，直到你下回合开始，防止你受到的伤害。",

	["keyaoguimou"] = "鬼谋",
	[":keyaoguimou"] = "<font color='green'><b>摸牌阶段，</b></font>你可以多摸X张牌（X为你已损失的体力值）。",

	["$keyaozhabing1"] = "下次注意点！",
	["$keyaozhabing2"] = "出来混，早晚要还的！",
	["$keyaoguimou1"] = "天命，哈哈哈哈！",
	["$keyaoguimou2"] = "吾乃天命之子！",

	["~keyaosimayi"] = "难道真是，天命难违？",

	--妖张角

	["keyaozhangjiao"] = "妖张角",
	["&keyaozhangjiao"] = "妖张角",
	["#keyaozhangjiao"] = "大贤良师",
	["designer:keyaozhangjiao"] = "杀神附体",
	["cv:keyaozhangjiao"] = "官方",
	["illustrator:keyaozhangjiao"] = "三国无双",

	["keyaotaiping"] = "太平",
	[":keyaotaiping"] = "出牌阶段限一次，你可以将两张：\
	♠牌当【南蛮入侵】使用；\
	♥牌当【万箭齐发】使用；\
	♣牌当【五谷丰登】使用；\
	♦牌当【桃园结义】使用。",

	["keyaojiazi"] = "甲子",
	[":keyaojiazi"] = "<font color='green'><b>回合结束时，</b></font>你可以将手牌摸至体力值。",

	["keyaotuzhong"] = "徒众",
	["yaotuzhong-ask"] = "请选择发动“徒众”的角色",
	[":keyaotuzhong"] = "主公技，你可以跳过你的摸牌阶段，若如此做，你可以令一名角色回复1点体力。",

	["$keyaotaiping1"] = "苍天已死，黄天当立！",
	["$keyaotaiping2"] = "岁在甲子，天下大吉！",
	["$keyaojiazi1"] = "哼哼哼...",
	["$keyaojiazi2"] = "天下大势，为我所控。",

	["~keyaozhangjiao"] = "黄天，也死了...",

	--妖周泰

	["keyaozhoutai"] = "妖周泰",
	["&keyaozhoutai"] = "妖周泰",
	["#keyaozhoutai"] = "肤如刻画",
	["designer:keyaozhoutai"] = "杀神附体",
	["cv:keyaozhoutai"] = "官方",
	["illustrator:keyaozhoutai"] = "三国无双",

	["keyaobuhui"] = "不悔",
	[":keyaobuhui"] = "锁定技，你不能成为【杀】的目标。",

	["~keyaozhoutai"] = "已经，尽力了。",


	--界妖周泰

	["kejieyaozhoutai"] = "界妖周泰",
	["&kejieyaozhoutai"] = "界妖周泰",
	["#kejieyaozhoutai"] = "肤如刻画",
	["designer:kejieyaozhoutai"] = "杀神附体",
	["cv:kejieyaozhoutai"] = "官方",
	["illustrator:kejieyaozhoutai"] = "三国无双",

	["kejieyaobuhui"] = "不悔",
	[":kejieyaobuhui"] = "锁定技，你不能成为【杀】和【桃】的目标。",

	["kejieyaofenwei"] = "奋卫",
	["kejieyaofenwei-mopai:kejieyaobuhui"] = "奋卫：令其摸一张牌",
	["kejieyaofenwei_mopai"] = "奋卫：令其摸一张牌",
	["kejieyaofenwei_shouhui"] = "奋卫：收回“不悔”",
	["kejieyaofenwei-ask"] = "请选择发动“奋卫”的角色",
	[":kejieyaofenwei"] = "回合结束时，若你有技能“不悔”，你可以失去技能“不悔”并选择一名其他角色，该角色获得技能“不悔”，若如此做，你的下一个回合开始时，你可以令其失去技能“不悔”且你获得技能“不悔”。\
	○当一名角色获得技能“不悔”时，你可以令其摸一张牌。",

	["$kejieyaofenwei1"] = "还不够！",
	["$kejieyaofenwei2"] = "我绝不会倒下！",

	["~kejieyaozhoutai"] = "已经，尽力了。",

	--妖小乔

	["keyaoxiaoqiao"] = "妖小乔",
	["&keyaoxiaoqiao"] = "妖小乔",
	["#keyaoxiaoqiao"] = "铜雀春深",
	["designer:keyaoxiaoqiao"] = "杀神附体",
	["cv:keyaoxiaoqiao"] = "官方",
	["illustrator:keyaoxiaoqiao"] = "三国无双",

	["keyaoquwu"] = "曲误",
	[":keyaoquwu"] = "出牌阶段限一次，你可以选择攻击范围内的一名其他角色，你令该角色的下一个摸牌阶段少摸一张牌且你摸一张牌。",

	["keyaotongque"] = "铜雀",
	[":keyaotongque"] = "锁定技，【酒】和【铁索连环】对你无效。",

	["keyaozhongshang"] = "冢殇",
	[":keyaozhongshang"] = "锁定技，每当一名角色死亡后，你的手牌上限+1。",

	["$keyaoquwu1"] = "盈盈一笑，娇花照水。",
	["$keyaoquwu2"] = "玉容花貌，难自弃。",

	["~keyaoxiaoqiao"] = "公瑾，我先走一步。",

	--妖卞氏

	["keyaobianshi"] = "妖卞氏",
	["&keyaobianshi"] = "妖卞氏",
	["#keyaobianshi"] = "黄巾女将",
	["designer:keyaobianshi"] = "杀神附体",
	["cv:keyaobianshi"] = "官方",
	["illustrator:keyaobianshi"] = "三国无双",

	["keyaojiahuo"] = "嫁祸",
	[":keyaojiahuo"] = "出牌阶段限一次，你可以将一张黑色牌当【借刀杀人】使用。",

	["keyaoleimu"] = "电母",
	[":keyaoleimu"] = "锁定技，你造成的非雷电伤害改为雷电伤害。",

	["keyaoyaohou"] = "妖后",
	[":keyaoyaohou"] = "<font color='#CC00FF'><b>皇后技，</b></font>当一名角色受到主公造成伤害后，若主公为男性，你可以选择一项：获得受到伤害的角色的一张牌，或摸一张牌。",

	["keyaoyaohou:huode"] = "获得受伤角色的一张牌",
	["keyaoyaohou:mopai"] = "摸一张牌",
	["keyaoyaohou:cancel"] = "取消",

	--妖吉平

	["keyaojiping"] = "妖吉平",
	["&keyaojiping"] = "妖吉平",
	["#keyaojiping"] = "汉之太医",
	["designer:keyaojiping"] = "杀神附体",
	["cv:keyaojiping"] = "官方",
	["illustrator:keyaojiping"] = "三国无双",

	["keyaoshidu"] = "施毒",
	["keyaoshiduCard"] = "施毒",
	["#keyaoshidubuff"] = "施毒",
	[":keyaoshidu"] = "<font color='green'><b>出牌阶段，</b></font>你可以弃置一张♠基本牌或装备牌并选择一名其他角色，该角色下一个回合开始时进行判定：若结果为黑色，你对其造成1点伤害。",

	["keyaogongdu"] = "攻毒",
	[":keyaogongdu"] = "<font color='green'><b>在你的回合外，</b></font>你可以将一张黑色手牌当【桃】使用。",

	["keyaoliandu"] = "炼毒",
	[":keyaoliandu"] = "锁定技，当你受到大于1点的伤害时，你将伤害值改为1点。",
	["$yaojiping_damage"] = "%from 的<font color='yellow'><b>“炼毒”</b></font>效果触发，伤害改为1点！",


	["$keyaoshidulog"] = "<font color='yellow'><b>施毒</b></font> 效果被触发！",

	["$keyaoshidu1"] = "嚼指为誓，誓杀国贼！",
	["$keyaoshidu2"] = "心怀汉恩，断指相随！",
	["$keyaogongdu1"] = "君有疾在身，不治将恐深。",
	["$keyaogongdu2"] = "汝身患重疾，当以虎狼之药去之。",

	["~keyaojiping"] = "今事不成，唯死而已！",

	--妖凌统

	["keyaolingtong"] = "凌统",
	["&keyaolingtong"] = "凌统",
	["#keyaolingtong"] = "国士之风",
	["designer:keyaolingtong"] = "杀神附体",
	["cv:keyaolingtong"] = "官方",
	["illustrator:keyaolingtong"] = "三国无双",

	["keyaozhongyi"] = "重义",
	[":keyaozhongyi"] = "每当你失去最后的手牌后，你可以摸等同于你体力值的牌。",

	["$keyaozhongyi1"] = "伤敌于千里之外！",
	["$keyaozhongyi2"] = "索命于须臾之间！",

	["~keyaolingtong"] = "大丈夫，不惧死亡！",

	--妖程昱

	["keyaochengyu"] = "程昱",
	["&keyaochengyu"] = "程昱",
	["#keyaochengyu"] = "世之奇士",
	["designer:keyaochengyu"] = "杀神附体",
	["cv:keyaochengyu"] = "官方",
	["illustrator:keyaochengyu"] = "三国无双",

	["keyaoxieqin"] = "挟亲",
	[":keyaoxieqin"] = "每轮限一次，当你对一名角色造成伤害后，你可以弃置另一名角色的一张牌。",
	["yaoxieqin-ask"] = "请选择弃置牌的角色",

	["keyaoshiwei"] = "识伪",
	[":keyaoshiwei"] = "<font color='green'><b>每当判定开始时，</b></font>你可以声明一种颜色，然后若你声明的颜色与本次判定结果相同，你摸一张牌。",

	["$keyaoshiweiblacklog"] = "%from 猜测并声明本次判定结果为“黑色”！",
	["$keyaoshiweiredlog"] = "%from 猜测并声明本次判定结果为“红色”！",
	["$keyaoshiweiredyeslog"] = "%from 猜测正确！本次判定结果为“红色”！",
	["$keyaoshiweiblackyeslog"] = "%from 猜测正确！本次判定结果为“黑色”！",
	["$keyaoshiweiblacknolog"] = "%from 猜测错误！本次判定结果为“红色”！",
	["$keyaoshiweirednolog"] = "%from 猜测错误！本次判定结果为“黑色”！",


	["$keyaoxieqin1"] = "天下大乱，群雄并起，必有命事。",
	["$keyaoxieqin2"] = "曹公智略乃上天所授。",
	["$keyaoshiwei1"] = "圈套已设，埋伏乙烷，只等敌军进来。",
	["$keyaoshiwei2"] = "如此天网，量你插翅也难逃。",

	["~keyaochengyu"] = "此诚报效国家之时，吾却休矣。",





	--界妖张角

	["kejieyaozhangjiao"] = "界妖张角",
	["&kejieyaozhangjiao"] = "界妖张角",
	["#kejieyaozhangjiao"] = "大贤统帅",
	["designer:kejieyaozhangjiao"] = "杀神附体",
	["cv:kejieyaozhangjiao"] = "官方",
	["illustrator:kejieyaozhangjiao"] = "三国无双",

	["kejieyaotaiping"] = "太平",
	[":kejieyaotaiping"] = "<font color='green'><b>出牌阶段，</b></font>你可以将两张：\
	♠牌当【南蛮入侵】使用；\
	♥牌当【万箭齐发】使用；\
	♣牌当【五谷丰登】使用；\
	♦牌当【桃园结义】使用。",

	["kejieyaojiazi"] = "甲子",
	[":kejieyaojiazi"] = "<font color='green'><b>回合结束时，</b></font>你可以将手牌摸至体力上限。",

	["kejieyaotuzhong"] = "徒众",
	[":kejieyaotuzhong"] = "主公技，你可以跳过你的摸牌阶段，若如此做，你可以令一名角色回复1点体力并摸一张牌。",

	["$kejieyaotaiping1"] = "苍天已死，黄天当立！",
	["$kejieyaotaiping2"] = "岁在甲子，天下大吉！",
	["$kejieyaojiazi1"] = "哼哼哼...",
	["$kejieyaojiazi2"] = "天下大势，为我所控。",
	["~kejieyaozhangjiao"] = "黄天，也死了...",

	--界妖司马懿

	["kejieyaosimayi"] = "界妖司马懿",
	["&kejieyaosimayi"] = "界妖司马懿",
	["#kejieyaosimayi"] = "家虎",
	["designer:kejieyaosimayi"] = "杀神附体",
	["cv:kejieyaosimayi"] = "官方",
	["illustrator:kejieyaosimayi"] = "三国无双",

	["kejieyaozhabing"] = "诈病",
	[":kejieyaozhabing"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以失去1点体力，若如此做，直到你下回合开始，你不能成为伤害类牌的目标，且其他角色与你的距离+X（X为你已损失的体力值）。",

	["kejieyaozhabingex"] = "诈病",
	["kejieyaoguimou"] = "鬼谋",
	[":kejieyaoguimou"] = "<font color='green'><b>摸牌阶段，</b></font>若你已受伤，你从牌堆获得一张锦囊牌，且你多摸X张牌。",

	["$kejieyaozhabing1"] = "下次注意点！",
	["$kejieyaozhabing2"] = "出来混，早晚要还的！",
	["$kejieyaoguimou1"] = "天命，哈哈哈哈！",
	["$kejieyaoguimou2"] = "吾乃天命之子！",

	["~kejieyaosimayi"] = "难道真是，天命难违？",

	--界妖小乔

	["kejieyaoxiaoqiao"] = "界妖小乔",
	["&kejieyaoxiaoqiao"] = "界妖小乔",
	["#kejieyaoxiaoqiao"] = "铜雀叶煤",
	["designer:kejieyaoxiaoqiao"] = "杀神附体",
	["cv:kejieyaoxiaoqiao"] = "官方",
	["illustrator:kejieyaoxiaoqiao"] = "三国无双",

	["kejieyaoquwu"] = "曲误",
	["jieyaoquwunum"] = "铜雀酒",
	[":kejieyaoquwu"] = "出牌阶段限一次，你可以选择一名其他角色，你令该角色的下一个摸牌阶段少摸一张牌且你摸一张牌。",

	["kejieyaotongque"] = "铜雀",
	[":kejieyaotongque"] = "锁定技，【酒】和【铁索连环】对你无效，每当你成为【酒】的目标时，你本局游戏出牌阶段发动“曲误”的次数限制+1。",

	["kejieyaozhongshang"] = "冢殇",
	[":kejieyaozhongshang"] = "锁定技，每当一名角色死亡后，你回复1点体力且你的手牌上限+1。",

	["$kejieyaoquwu1"] = "盈盈一笑，娇花照水。",
	["$kejieyaoquwu2"] = "玉容花貌，难自弃。",

	["~kejieyaoxiaoqiao"] = "公瑾，我先走一步。",




	--界妖小乔-第二版

	["kejieyaoxiaoqiaotwo"] = "界妖小乔-第二版",
	["&kejieyaoxiaoqiaotwo"] = "界妖小乔",
	["#kejieyaoxiaoqiaotwo"] = "铜雀春深",
	["designer:kejieyaoxiaoqiaotwo"] = "杀神附体",
	["cv:kejieyaoxiaoqiaotwo"] = "官方",
	["illustrator:kejieyaoxiaoqiaotwo"] = "三国无双",

	["kejieyaoquwutwo"] = "曲误",
	["quwutlcount"] = "曲误：体力值",
	["quwuspcount"] = "曲误：手牌数",
	[":kejieyaoquwutwo"] = "当一名角色的出牌阶段结束时，若该角色的手牌数或体力值与其回合开始时的数值不同，你可以摸一张牌，然后若满足两项，你横置其武将牌。",

	["kejieyaotongquetwo"] = "铜雀",
	["kejieyaotongquetwo-dis"] = "请弃置一张手牌发动“铜雀”",
	[":kejieyaotongquetwo"] = "当你受到【酒】【杀】或因“连环状态”传导的伤害时，你可以弃置一张手牌并重置武将牌，若如此做，视为你脱离了因此伤害进入的濒死状态，然后此伤害-1。",

	["kejieyaozhongshangtwo"] = "抚殇",
	[":kejieyaozhongshangtwo"] = "锁定技，一名角色脱离濒死状态时，你回复1点体力或令手牌上限+1。",

	["kejieyaozhongshangtwo:maxhp"] = "回复1点体力",
	["kejieyaozhongshangtwo:handmax"] = "手牌上限+1",

	["$kejieyaoquwutwo1"] = "盈盈一笑，娇花照水。",
	["$kejieyaoquwutwo2"] = "玉容花貌，难自弃。",

	["~kejieyaoxiaoqiaotwo"] = "公瑾，我先走一步。",


	--界妖吉平

	["kejieyaojiping"] = "界妖吉平",
	["&kejieyaojiping"] = "界妖吉平",
	["#kejieyaojiping"] = "太医令",
	["designer:kejieyaojiping"] = "杀神附体",
	["cv:kejieyaojiping"] = "官方",
	["illustrator:kejieyaojiping"] = "三国无双",

	["kejieyaoshidu"] = "施毒",
	["kejieyaoshiduCard"] = "施毒",
	["#kejieyaoshidubuff"] = "施毒",
	[":kejieyaoshidu"] = "<font color='green'><b>出牌阶段，</b></font>你可以弃置一张基本牌或装备牌并选择一名其他角色，该角色下一个回合开始时进行判定：若结果为♠，你对其造成2点伤害；若结果为♣或♦，你对其造成1点伤害；若结果为♥，你摸一张牌。",

	["kejieyaogongdu"] = "攻毒",
	[":kejieyaogongdu"] = "你可以将一张黑色牌当【桃】使用。",

	["kejieyaoliandu"] = "炼毒",
	[":kejieyaoliandu"] = "锁定技，当你受到大于1点的伤害时，你将伤害值改为1点。",

	["$kejieyaoshidu1"] = "嚼指为誓，誓杀国贼！",
	["$kejieyaoshidu2"] = "心怀汉恩，断指相随！",
	["$kejieyaogongdu1"] = "君有疾在身，不治将恐深。",
	["$kejieyaogongdu2"] = "汝身患重疾，当以虎狼之药去之。",

	["~kejieyaojiping"] = "今事不成，唯死而已！",

	--界妖程昱

	["kejieyaochengyu"] = "界程昱",
	["&kejieyaochengyu"] = "界程昱",
	["#kejieyaochengyu"] = "世之奇士",
	["designer:kejieyaochengyu"] = "杀神附体",
	["cv:kejieyaochengyu"] = "官方",
	["illustrator:kejieyaochengyu"] = "三国无双",

	["kejieyaoxieqin"] = "挟亲",
	[":kejieyaoxieqin"] = "<font color='green'><b>当你受到或造成伤害后，</b></font>你可以弃置不是受伤角色的一名角色的一张牌。",
	["yaoxieqin-ask"] = "请选择弃置牌的角色",

	["kejieyaoshiwei"] = "识伪",
	[":kejieyaoshiwei"] = "<font color='green'><b>每当判定开始时，</b></font>你可以声明一种颜色，然后若你声明的颜色与本次判定结果相同，你摸两张牌，否则你摸一张牌。",

	["$kejieyaoxieqin1"] = "天下大乱，群雄并起，必有命事。",
	["$kejieyaoxieqin2"] = "曹公智略乃上天所授。",
	["$kejieyaoshiwei1"] = "圈套已设，埋伏乙烷，只等敌军进来。",
	["$kejieyaoshiwei2"] = "如此天网，量你插翅也难逃。",

	["~kejieyaochengyu"] = "此诚报效国家之时，吾却休矣。",



}
return { extension }
