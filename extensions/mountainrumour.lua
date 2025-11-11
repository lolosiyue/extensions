module("extensions.mountainrumour",package.seeall)
extension = sgs.Package("mountainrumour")

luadengaizhonghui_fendao = sgs.General(extension, "luadengaizhonghui_fendao", "wei", 8, true)--, true)

luatoudumr = sgs.CreateTriggerSkill
{
	name = "luatoudumr",
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if player:getMark(self:objectName()) == 0 then return false end
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				if not player:isSkipped(change.to) then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:skip(change.to)
						player:turnOver()
						room:setPlayerMark(player, "toudu_dr", 1)
					end
				end
			end
			return false
		end
		if event == sgs.DrawNCards then
			if player:getMark("toudu_dr") == 0 then return false end
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:setPlayerMark(player, "toudu_dr", 0)
			local choice
			if draw.num > 0 then
				choice = room:askForChoice(player, self:objectName(), "toudu_dm+toudu_dl")
			else
				choice = "toudu_dm"
			end
			if choice == "toudu_dm" then
				room:loseHp(player)
				draw.num = draw.num + 1
			else
				draw.num = draw.num - 1
			end
			data:setValue(draw)
			return false
		end
	end
}

luadengaizhonghui_fendao:addSkill(luatoudumr)

luaxianhaicard = sgs.CreateSkillCard
{
	name = "luaxianhaicard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, selected, to_select, player)
		if #selected == 0 then
			return player:inMyAttackRange(to_select) and to_select:getMark("xianhai_from") == 0 and player:objectName() ~= to_select:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local tag = sgs.QVariant()
		tag:setValue(targets[1])
		room:setTag("xianhai_target", tag)
		room:broadcastSkillInvoke("luaxianhai")
	end
}

luaxianhaivs = sgs.CreateViewAsSkill
{
	name = "luaxianhai",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = luaxianhaicard:clone()
			card:addSubcard(cards[1])
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@luaxianhai"
	end
}

luaxianhai = sgs.CreateTriggerSkill
{
	name = "luaxianhai",
	events = sgs.TargetConfirming,
	view_as_skill = luaxianhaivs,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark(self:objectName()) == 0 then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") or use.card:isNDTrick() then
			room:setPlayerMark(use.from, "xianhai_from", 1)
			local xianhai_fromcard = sgs.QVariant()
			xianhai_fromcard:setValue(use.card)
			room:setTag(player:objectName().."xianhai_fromcard", xianhai_fromcard)
			if room:askForUseCard(player, "@@luaxianhai", "@luaxianhai") then
				room:setPlayerMark(use.from, "xianhai_from", 0)
				local target = room:getTag("xianhai_target"):toPlayer()
				local new_to = sgs.SPlayerList()
				for i=1,use.to:length() do
					if use.to:at(i-1):objectName() == player:objectName() then
						new_to:append(target)
					else
						new_to:append(use.to:at(i-1))
					end
				end
				use.to = new_to
				data:setValue(use)
				return true
			end
			room:setPlayerMark(use.from, "xianhai_from", 0)
		end
		return false
	end
}
						
luadengaizhonghui_fendao:addSkill(luaxianhai)

luafendaocard = sgs.CreateSkillCard
{
	name = "luafendaocard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("luafendao")
		room:doLightbox("luafendao$", 3000)
		--room:getThread():delay(3000)
		source:loseMark("@fendao")
		room:setPlayerMark(source, "fendao_used", 1)
		local choice = room:askForChoice(source, self:objectName(), "luatoudumr+luaxianhai")
		room:setTag(source:objectName().."fendao_choice", sgs.QVariant(choice))
		
		local log = sgs.LogMessage()
		log.type = "#luafendao"
		log.from = source
		log.arg = choice
		room:sendLog(log)
		room:addPlayerMark(source, "&"..choice)
				
		
		room:loseMaxHp(source, 4)
	end
}

luafendaovs = sgs.CreateViewAsSkill
{
	name = "luafendao",
	n = 0,
	view_as = function(self, cards)
		return luafendaocard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@fendao") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

luafendao = sgs.CreateTriggerSkill
{
	name = "luafendao",
	events = {sgs.GameStart, sgs.TurnStart},
	frequency = sgs.Skill_Limited,
	view_as_skill = luafendaovs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("@fendao") == 0 then
				player:gainMark("@fendao")
			end
			return false
		end
		if event == sgs.TurnStart then
			if player:getMark("fendao_used") > 0 then
				if player:getMark("fendao_choicemade") == 0 then
					room:setPlayerMark(player, "fendao_choicemade", 1)
					local choice = room:getTag(player:objectName().."fendao_choice"):toString()
					room:setPlayerMark(player, choice, 1)
					room:setPlayerMark(player, "@"..choice.."acquired", 1)
				end
			end
			return false
		end
	end
}

luadengaizhonghui_fendao:addSkill(luafendao)

luazhenggongmr = sgs.CreateTriggerSkill
{
	name = "luazhenggongmr",
	events = sgs.CardUsed,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("fendao_used") > 0 then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.to:length() == 1) then
			local kinds = {"Slash","Jink","Peach","Analeptic","Nullification","Snatch","Dismantlement","Collateral","ExNihilo","Duel","FireAttack","AmazingGrace","SavageAssault","AcheryAttack","GodSalvation","IronChain"}
			local cardtype
			for _,k in ipairs(kinds) do
				if use.card:isKindOf(k) then
					cardtype = k
					break
				end
			end
			
			room:broadcastSkillInvoke(self:objectName())
				
			if not room:askForCard(player, cardtype, "@luazhenggongmr") then				

				local log = sgs.LogMessage()
				log.type = "#luazhenggongmr"
				log.from = player
				log.arg = use.card:objectName()
				room:sendLog(log)
				
				return true
			end
			return false
		end
	end
}

luadengaizhonghui_fendao:addSkill(luazhenggongmr)


luazhanghe_zhuiji = sgs.General(extension, "luazhanghe_zhuiji", "wei", 4, true)--, true)

luazhuiji = sgs.CreateTriggerSkill
{
	name = "luazhuiji",
	events = {sgs.CardEffected},
	frequency = sgs.Skill_NotFrequent,
	priority = -1,
	can_trigger = function(self, target) return target end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isNDTrick() then
				if effect.from and effect.from:hasSkill(self:objectName()) then
					if effect.from:getMark(self:objectName()) > 0 then
						if effect.to:objectName() ~= effect.from:objectName() then
							if room:askForUseSlashTo(effect.from, effect.to, "@luazhuiji", false) then
								room:broadcastSkillInvoke(self:objectName())
							end
						end
					end
				end
			end
		end
	end
}

luazhanghe_zhuiji:addSkill(luazhuiji)

luashitucard = sgs.CreateSkillCard
{
	name = "luashitucard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "luashitu")
		room:broadcastSkillInvoke("luashitu")
	end
}

luashituvs = sgs.CreateViewAsSkill
{
	name = "luashitu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = luashitucard:clone()
			card:addSubcard(cards[1])
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luashitucard")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

luashitu = sgs.CreateTriggerSkill
{
	name = "luashitu",
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = luashituvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:objectName() == "luashitucard" then
				room:setPlayerMark(player, "shitucard_used", 1)
			end
			return false
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:getMark("shitucard_used") == 1 then
					room:setPlayerMark(player, "luazhuiji", 1)
					room:setPlayerMark(player, "&luazhuiji-Clear", 1)
				end
			end
			return false
		end
	end
}

luashitu_dis = sgs.CreateDistanceSkill
{
	name = "luashitu_dis",
	correct_func = function(self, from, to)
		if from:hasFlag("luashitu") and to:getDefensiveHorse() then
			return -1
		end
		if to:hasFlag("luashitu") and from:getOffensiveHorse() then
			return 1
		end
	end
}


luazhanghe_zhuiji:addSkill(luashitu)

if not sgs.Sanguosha:getSkill("luashitu_dis") then
	local skillList=sgs.SkillList()
	skillList:append(luashitu_dis)
	sgs.Sanguosha:addSkills(skillList)
end







lualiushan_fuyou = sgs.General(extension, "lualiushan_fuyou$", "shu", 3, true)--, true)

luaxianglemr = sgs.CreateTriggerSkill
{
	name = "luaxianglemr",
	events = sgs.CardEffected,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		room = player:getRoom()
		local effect = data:toCardEffect()
		--if effect.to:getPhase() ~= sgs.Player_Play then return false end
		if effect.card and effect.card:isKindOf("Indulgence") then
			effect.card:onEffect(effect)
			player:skip(sgs.Player_Discard)
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
	end
}

lualiushan_fuyou:addSkill(luaxianglemr)


luafuyou = sgs.CreateTriggerSkill
{
	name = "luafuyou",
	events = sgs.Dying,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.pattern = ".|red"
			judge.negative = false	
			judge.play_animation = true
			judge.time_consuming = true		
			judge.good = true			
			judge.reason = self:objectName()			
			room:judge(judge)

			if judge:isGood() then
				room:broadcastSkillInvoke(self:objectName())
				local recov = sgs.RecoverStruct()
				recov.who = player
				recov.recover = 1
				room:recover(player, recov)				
			end
			
		end
	end
}

lualiushan_fuyou:addSkill(luafuyou)

luayudun = sgs.CreateFilterSkill
{
	name = "luayudun",
	view_filter = function(self, to_select)
		return (to_select:getSuit() == sgs.Card_Heart or to_select:getSuit() == sgs.Card_Spade)-- and not to_select:isKindOf("DelayedTrick")
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new = sgs.Sanguosha:getWrappedCard(id)
		new:setSkillName(self:objectName())
		if new:getSuit() == sgs.Card_Heart then
			new:setSuit(sgs.Card_Diamond)
		else
			new:setSuit(sgs.Card_Club)
		end
		new:setModified(true)
		return new
	end
}

lualiushan_fuyou:addSkill(luayudun)

luatuogu = sgs.CreateTriggerSkill
{
	name = "luatuogu$",
	events = sgs.DamageForseen,
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(self, target)
		return target and target:hasLordSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			
			room:broadcastSkillInvoke(self:objectName())
		
			room:setPlayerMark(player, "luatuogu_who", 1)
			
			if damage.from then
				room:setPlayerMark(damage.from, "luatuogu_from", 1)
			end
			
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				if p:getKingdom() == "shu" then
					local choice = room:askForChoice(p, self:objectName(), "tuoguhelper+tuogunonhelper")
					
					local log = sgs.LogMessage()
					log.type = "#luatuogu"
					log.from = p
					log.arg = choice.."log"
					log.to:append(player)
					room:sendLog(log)
					
					if choice == "tuoguhelper" then
						
						damage.to = p
						data:setValue(damage)
						
						room:setPlayerMark(player, "luatuogu_who", 0)
						room:setPlayerMark(damage.from, "luatuogu_from", 0)
						
						return false
					end
				end
			end
		end
		room:setPlayerMark(player, "luatuogu_who", 0)
		if damage.from then
			room:setPlayerMark(damage.from, "luatuogu_from", 0)
		end
		return false
	end
}

lualiushan_fuyou:addSkill(luatuogu)




luajiangwei_qilin = sgs.General(extension, "luajiangwei_qilin", "shu", 4, true)--, true)

luaqilin = sgs.CreateFilterSkill
{
	name = "luaqilin",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local player = room:getCardOwner(to_select:getEffectiveId())
		local current = room:getCurrent()
		if player == nil then return false end
		if current:objectName() ~= player:objectName() then
			return not to_select:isKindOf("Nullification") and to_select:isKindOf("TrickCard")
		end
		return false
	end,
	view_as = function(self, card)
		local room = sgs.Sanguosha:currentRoom()
		local filtered
		if card:isBlack() then
			filtered = sgs.Sanguosha:cloneCard("Slash", card:getSuit(), card:getNumber())
		else
			filtered = sgs.Sanguosha:cloneCard("Jink", card:getSuit(), card:getNumber())
		end
		filtered:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(card:getId()) 
		card:takeOver(filtered)
		return card 
	end
}

luaqilin_hid = sgs.CreateTriggerSkill{	
	name = "#luaqilin_hid",
	events = sgs.TurnStart,
	can_trigger = function(self, target) return target end,
	on_trigger = function(self, event, player, data)	
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("luaqilin") then
				local cards = p:getHandcards()
				room:filterCards(p, cards, true)
			end
		end				
	end
}

luaqilin_dis = sgs.CreateDistanceSkill
{
	name = "luaqilin_dis",
	correct_func = function(self, from, to)
		if from:hasSkill("luaqilin") then
			return -2
		end
	end
}

luajiangwei_qilin:addSkill(luaqilin_hid)

luajiangwei_qilin:addSkill(luaqilin)

extension:insertRelatedSkills(luaqilin:objectName(), luaqilin_hid:objectName())

if not sgs.Sanguosha:getSkill("luaqilin_dis") then
	local skillList=sgs.SkillList()
	skillList:append(luaqilin_dis)
	sgs.Sanguosha:addSkills(skillList)
end

--require("bit")

luadunjia = sgs.CreateTriggerSkill
{
	name = "luadunjia",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() ~= sgs.Player_Play then return false end
			local move = data:toMoveOneTime()
			--local reason = move.reason.m_reason
			local count = 0
			if move.to_place == sgs.Player_DiscardPile and move.from and move.from:objectName() == player:objectName() then
			--if bit:_and(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then				
				for _,id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("EquipCard") then
						count = count + 1
					end
				end--[[
			elseif move.from_places:contains(sgs.Player_PlaceEquip) then
				for _,p in sgs.qlist(move.from_places) do
					if p == sgs.Player_PlaceEquip then
						count = count + 1
					end
				end]]
			end
			
			for i=1,count do
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local choice
					if player:getLostHp() == 0 then
						choice = "dunjiadraw"
					else 
						choice = room:askForChoice(player, self:objectName(), "dunjiarecover+dunjiadraw")
					end
					if choice == "dunjiadraw" then
						room:broadcastSkillInvoke(self:objectName(), 1)
						player:drawCards(2)
					else
						room:broadcastSkillInvoke(self:objectName(), 2)
						local recov = sgs.RecoverStruct()
						recov.who = player
						recov.recover = 1
						room:recover(player, recov)
					end
					room:setPlayerMark(player, self:objectName(), 1)
				end
			end
			return false
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark(self:objectName()) > 0 then
					room:setPlayerMark(player, self:objectName(), 0)
					player:turnOver()
				end
			end
		end
		return false
	end
}
		
luajiangwei_qilin:addSkill(luadunjia)			



luasunce_bawang = sgs.General(extension, "luasunce_bawang$", "wu", 4, true)--, true)


luabawang = sgs.CreateTriggerSkill
{
	name = "luabawang",
	events = {sgs.Damage, sgs.Pindian},
	frequency = sgs.Skill_NotFrequent,
	priority = -1,
	can_trigger = function(self, target) return target end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if not player:hasSkill(self:objectName()) then return false end
			local damage = data:toDamage()
			if not damage.to:isAlive() then return false end
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					if not room:askForDiscard(damage.to, self:objectName(), 2, 2, true, true, "bawang_dsc") then
						local new_damage = sgs.DamageStruct()
						new_damage.from = player
						new_damage.to = damage.to
						new_damage.damage = 1
						room:damage(new_damage)
					end
				end
			end
			return false
		end
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			local winner
			local loser
			if pindian.from:hasSkill(self:objectName()) and pindian.success then
				winner = pindian.from
				loser = pindian.to
			elseif pindian.to:hasSkill(self:objectName()) and not pindian.success then
				winner = pindian.to
				loser = pindian.from
			end
			if winner then
				if room:askForSkillInvoke(winner, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local damage = sgs.DamageStruct()
					damage.from = winner
					damage.to = loser
					damage.damage = 1
					room:damage(damage)
				end
			end
			return false
		end
	end
}

luasunce_bawang:addSkill(luabawang)

luajiebing = sgs.CreateTriggerSkill
{
	name = "luajiebing$",
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target) 
		return target and target:hasLordSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				local hc_ids = player:handCards()
				for _,id in sgs.qlist(hc_ids) do
					if not move.card_ids:contains(id) then
						return false
					end
				end
				room:setPlayerMark(player, self:objectName(), 1)
				return false
			end
			if event == sgs.CardsMoveOneTime then
				if player:getMark(self:objectName()) > 0 then
					room:broadcastSkillInvoke(self:objectName())
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getKingdom() == "wu" then
							local card = room:askForCard(p, "..", "@luajiebing", data, sgs.Card_MethodNone)
							if card then
								room:obtainCard(player, card, false)
								room:setPlayerMark(player, self:objectName(), 0)
								return false
							end
						end
					end
 				end
				room:setPlayerMark(player, self:objectName(), 0)
				return false
			end
		end
	end
}

luasunce_bawang:addSkill(luajiebing)





luawuguotai_tongtang = sgs.General(extension, "luawuguotai_tongtang", "wu", 3, false)--, true)

luatongtang_mxc = sgs.CreateMaxCardsSkill
{
	name = "luatongtang_mxc",
	extra_func = function(self, player)
		if player:hasSkill("luatongtang") then
			local players = player:getSiblings()
			players:prepend(player)
			local count = 0
			for _,p in sgs.qlist(players) do
				if p:getKingdom() == "wu" then
					count = count + 1
				end
			end
			return 2*count
		end
	end
}

if not sgs.Sanguosha:getSkill("luatongtang_mxc") then
	local skillList=sgs.SkillList()
	skillList:append(luatongtang_mxc)
	sgs.Sanguosha:addSkills(skillList)
end

luatongtang = sgs.CreateTriggerSkill
{
	name = "luatongtang",
	events = sgs.EventPhaseStart,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local card_ids = room:getNCards(3)
				room:fillAG(card_ids, player)
				local id = room:askForAG(player, card_ids, false, self:objectName())
				card_ids:removeOne(id)
				room:clearAG(player)
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getKingdom() == "wu" then
						targets:append(p)
					end
				end				
				local target
				if not targets:isEmpty() then
					target = room:askForPlayerChosen(player, targets, self:objectName())
				end
				if not target then
					target = player
				end
				room:obtainCard(target, id, false)
				local move = sgs.CardsMoveStruct()
				move.to = player
				move.card_ids = card_ids
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, false)
				return true
			end
		end
	end
}

luawuguotai_tongtang:addSkill(luatongtang)	

luazhaoxucard = sgs.CreateSkillCard
{
	name = "luazhaoxucard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, selected, to_select)
		local targets = self:subcardsLength()
		return #selected + 1 < targets and to_select:isMale()
	end,
	feasible = function(self, targets)
		return self:subcardsLength() == #targets + 1 and #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local num = self:subcardsLength() - 1
		local choice = room:askForChoice(source, self:objectName(), "zhaoxulosehp+zhaoxurecoverhp")
		if choice == "zhaoxulosehp" then
			room:broadcastSkillInvoke("luazhaoxu", 1)
			room:loseHp(source, num)
			for _,p in ipairs(targets) do
				room:loseHp(p)
			end
		elseif choice == "zhaoxurecoverhp" then
			room:broadcastSkillInvoke("luazhaoxu", 2)
			local recov = sgs.RecoverStruct()
			recov.who = source
			recov.recover = math.min(num, source:getLostHp())
			room:recover(source, recov)
			for _,p in ipairs(targets) do
				recov.recover = 1
				room:recover(p, recov)
			end
		end
	end
}

luazhaoxu = sgs.CreateViewAsSkill
{
	name = "luazhaoxu",
	n = 998,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 1 then
			local card = luazhaoxucard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luazhaoxucard")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

luawuguotai_tongtang:addSkill(luazhaoxu)	




		
		
		
		

luazuoci_caokong = sgs.General(extension, "luazuoci_caokong", "qun", 3, true)--, true)

luacaokongvs = sgs.CreateViewAsSkill
{
	name = "luacaokong",
	n = 0,
	view_as = function(self, cards)
		local player = sgs.Self
		local pattern = player:property("caokong_pattern"):toString()
		local id = player:getMark("caokong_id")
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
		card:addSubcard(id)
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@luacaokong"
	end
}
	
luacaokong = sgs.CreateTriggerSkill
{
	name = "luacaokong",
	events = sgs.EventPhaseStart,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = luacaokongvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
		
			if player:getMark(self:objectName()) == 0 then return false end
			
			local repeated = false
			local selected = sgs.SPlayerList()
			local card_ids = sgs.IntList()
			local spade_ids = sgs.IntList()
			
			local tag = sgs.QVariant()
			local use = sgs.CardUseStruct()
			tag:setValue(use)
			room:setTag("caokong_tos", tag)
			
			local prompt = "caokong_a"
			
			for i=1,3 do
				local others = room:getOtherPlayers(player)
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(others) do
					if not p:isKongcheng() then
						targets:append(p)
					end
				end
				if targets:isEmpty() or not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
					break
				end
				local target = room:askForPlayerChosen(player, targets, self:objectName())
				if selected:contains(target) then
					repeated = true
				end
				selected:append(target)
				local id = room:askForCardChosen(player, target, "h", self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				card_ids:append(id)
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
					spade_ids:append(id)
				end
				player:addToPile("caokongpile", id)
				
				use.to:append(target)
				tag:setValue(use)
				room:setTag("caokong_tos", tag)
				
				if not repeated then
					prompt = "caokong_b"
				else
					prompt = "caokong_a"
				end
				
			end
						
			if card_ids:isEmpty() then return false end
			
			local move = sgs.CardsMoveStruct()
			move.card_ids = card_ids
			move.to_place = sgs.Player_PlaceTable
			room:moveCardsAtomic(move, true)
			
			room:fillAG(card_ids)
			room:getThread():delay(1000)
			
			while not spade_ids:isEmpty() do
				--local id = room:askForAG(player, spade_ids, false, self:objectName())
				local id = spade_ids:first()
				room:takeAG(player, id)
				card_ids:removeOne(id)
				spade_ids:removeOne(id)
				room:getThread():delay(800)
			end
			
			
			if not card_ids:isEmpty() then
				for _,id in sgs.qlist(card_ids) do
					local card = sgs.Sanguosha:getCard(id)			
						
					local card_to_use = sgs.QVariant()
					card_to_use:setValue(card)					
					room:setTag("caokong_carduse", card_to_use) --给ai准备的，虽然不打算写ai
					
					if card:isKindOf("EquipCard") then
						room:takeAG(player, id)
						if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(card:objectName())) then
							local to = sgs.SPlayerList()
							to:append(player)
							card:use(room, player, to)
						else
						
							local log = sgs.LogMessage()
							log.type = "$EnterDiscardPile"
							log.card_str = card:toString()
							room:sendLog(log)
							
							room:moveCardTo(card, nil, sgs.Player_DiscardPile)
							
						end
					elseif card:isAvailable(player) then
						room:takeAG(player, id)
						room:setPlayerProperty(player, "caokong_pattern", sgs.QVariant(card:objectName()))
						room:setPlayerMark(player, "caokong_id", id)
						
						if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant()) then
							if not room:askForUseCard(player, "@@luacaokong", "@luacaokong") then	
								
								room:removeTag("caokong_carduse")

								local log = sgs.LogMessage()
								log.type = "$EnterDiscardPile"
								log.card_str = card:toString()
								room:sendLog(log)
								
								room:moveCardTo(card, nil, sgs.Player_DiscardPile)
							end
						else		
							
							room:removeTag("caokong_carduse")
						
							local log = sgs.LogMessage()
							log.type = "$EnterDiscardPile"
							log.card_str = card:toString()
							room:sendLog(log)
							
							room:moveCardTo(card, nil, sgs.Player_DiscardPile)
						end
					else
						room:takeAG(nil, id)
					end
					room:getThread():delay(800)
				end
			end
			
			room:clearAG()
						
			player:turnOver()
			if repeated then
				player:skip(sgs.Player_Play)
			end
			
		end
		return false
	end
}

luazuoci_caokong:addSkill(luacaokong)

luahuanying = sgs.CreateTriggerSkill
{
	name = "luahuanying",
	events = {sgs.EventPhaseStart, sgs.DamageInflicted},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if player:getPile("huanyingpile"):length() < 4 then
					local card = room:askForCard(player, ".|.|.|hand|.", "@luahuanying", data, sgs.Card_MethodNone)
					if card then
						player:addToPile("huanyingpile", card, false)
					end
				end
			end
			return false
		end
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if not damage.from then return false end
			local card_ids = player:getPile("huanyingpile")
			if not card_ids:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
				
					room:broadcastSkillInvoke(self:objectName())
				
					room:setPlayerMark(player, "luacaokong", 1)
					room:setPlayerMark(player, "&luacaokong", 1)
					
					room:fillAG(card_ids, player)
					local id = room:askForAG(player, card_ids, true, self:objectName())
					room:clearAG(player)
					if id < 0 then return false end
					
					local tag = sgs.QVariant()
					tag:setValue(player)
					room:setTag("huanying_target", tag)
					room:setTag("huanying_data", data)
					
					local choice = room:askForChoice(damage.from, self:objectName(), "question+no_question")
					if choice == "question" then
						room:setEmotion(damage.from, "question")
					else
						room:setEmotion(damage.from, "no-question")
					end
					
					local card = sgs.Sanguosha:getCard(id)
					room:moveCardTo(card, nil, sgs.Player_PlaceTable, true)
					room:getThread():delay(1000)
					
					if choice == "no_question" then
					
						local log = sgs.LogMessage()
						log.type = "$EnterDiscardPile"
						log.card_str = card:toString()
						room:sendLog(log)
						
						room:moveCardTo(card, nil, sgs.Player_DiscardPile)
						
						room:setEmotion(damage.from, ".")	

						room:removeTag("huanying_target")
						room:removeTag("huanying_data")
						
						return true
					else
						if card:getSuit() == sgs.Card_Club then
							room:loseHp(damage.from)
						else
							damage.damage = damage.damage + 1
							data:setValue(damage)
						end
						
						local log = sgs.LogMessage()
						log.type = "$EnterDiscardPile"
						log.card_str = card:toString()
						room:sendLog(log)
						
						room:moveCardTo(card, nil, sgs.Player_DiscardPile)
						
						room:setEmotion(damage.from, ".")
						
						room:removeTag("huanying_target")
						room:removeTag("huanying_data")
						
						return false
						
					end
				end
			end
		end
	end
}

luazuoci_caokong:addSkill(luahuanying)


luaxianti = sgs.CreateTriggerSkill
{
	name = "luaxianti",
	events = {sgs.EventPhaseStart, sgs.FinishJudge, sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Judge then
				if player:getJudgingArea():isEmpty() then
					
					room:broadcastSkillInvoke(self:objectName())
					
					local to_continue = true
					
					while to_continue do
					
						local judge = sgs.JudgeStruct()
						judge.who = player
						judge.pattern = "."
						judge.negative = false	
						judge.play_animation = false
						judge.time_consuming = true		
						judge.good = true			
						judge.reason = self:objectName()			
						room:judge(judge)
						
						if judge.card:getSuit() ~= sgs.Card_Spade then
							to_continue = false
						end
						
					end
				
				end
			end
			return false
		end
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local suit = judge.card:getSuitString()
				
				if suit == "heart" then
					room:setPlayerFlag(player, "xianti_draw")
				elseif suit == "club" then
					room:obtainCard(player, judge.card)
					return true
				elseif suit == "diamond" then
					room:setPlayerFlag(player, "xianti_discard")
				end
			end
			return false
		end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("xianti_draw") then
				draw.num = draw.num + 1
				data:setValue(draw)
			end
			return false
		end
	end
}
luazuoci_caokong:addSkill(luaxianti)

luaxianti_mxc = sgs.CreateMaxCardsSkill
{
	name = "luaxianti_mxc",
	extra_func = function(self, player)
		if player:hasFlag("xianti_discard") then
			return 1
		end
	end
}

if not sgs.Sanguosha:getSkill("luaxianti_mxc") then
	local skillList=sgs.SkillList()
	skillList:append(luaxianti_mxc)
	sgs.Sanguosha:addSkills(skillList)
end





luacaiwenji_shushen = sgs.General(extension, "luacaiwenji_shushen", "qun", 3, false)--, true)

luashushenmrcard = sgs.CreateSkillCard
{
	name = "luashushenmrcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local num = self:subcardsLength()
		room:broadcastSkillInvoke("luashushenmr")
		source:drawCards(2*num)
		source:turnOver()
	end
}

luashushenmrvs = sgs.CreateViewAsSkill
{
	name = "luashushenmr",
	n = 998,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = luashushenmrcard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@luashushenmr"
	end
}

luashushenmr = sgs.CreateTriggerSkill
{
	name = "luashushenmr",
	events = sgs.EventPhaseStart,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = luashushenmrvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if room:askForUseCard(player, "@@luashushenmr", "@luashushenmr") then
			
			end
		end
	end
}

luacaiwenji_shushen:addSkill(luashushenmr)

luahujiamrvs = sgs.CreateViewAsSkill
{
	name = "luahujiamr",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("Slash")
		else
			return to_select:isKindOf("Slash") and to_select:sameColorWith(selected[1])
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, 0)
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, 0)
		return card:isAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

luahujiamr = sgs.CreateTriggerSkill
{
	name = "luahujiamr",
	events = sgs.GameStart,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = luahujiamrvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerCardLimitation(player, "use", "Slash", false)
		--陈宫明策出错！！
	end
}

luacaiwenji_shushen:addSkill(luahujiamr)





luashenyuanshao_mengzhu = sgs.General(extension, "luashenyuanshao_mengzhu", "god", 4, true)--, true)

luamingmen = sgs.CreateMaxCardsSkill
{
	name = "luamingmen",
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getHp()
		end
	end
}

luamingmen_bi = sgs.CreateTriggerSkill
{--专用于播放名门的音效……
	name = "#luamingmen_bi",
	events = sgs.EventPhaseEnd,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHandcardNum() > player:getHp() then
			room:broadcastSkillInvoke("luamingmen")
		end
	end
}

luashenyuanshao_mengzhu:addSkill(luamingmen)
luashenyuanshao_mengzhu:addSkill(luamingmen_bi)
extension:insertRelatedSkills(luamingmen:objectName(), luamingmen_bi:objectName())

luamengzhu = sgs.CreateTriggerSkill
{
	name = "luamengzhu",
	events = sgs.EventPhaseStart,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then		
						
			local others = room:getOtherPlayers(player)
			local can_invoke = false
			for _,p in sgs.qlist(others) do
				if not p:isAllNude() then
					can_invoke = true
				end
			end
		
			if can_invoke and room:askForSkillInvoke(player, self:objectName(), data) then	
				
				if others:length() >= 4 then
				
					room:broadcastSkillInvoke(self:objectName())
					local rand = math.random(1, 7)
					if rand > 1 then
						room:doLightbox("luamengzhu1$", 3000)
					else
						room:doLightbox("luamengzhu2$", 3000)
					end
					--room:getThread():delay(3000)
					
				end
				
				for _,p in sgs.qlist(others) do
					if not p:isAllNude() then
						local id = room:askForCardChosen(player, p, "hej", self:objectName())
						room:obtainCard(player, id, false)
						room:getThread():delay(800)
					end
				end
				player:turnOver()
				return true
			end
		end
	end
}

luashenyuanshao_mengzhu:addSkill(luamengzhu)




luashenguojia_shisheng = sgs.General(extension, "luashenguojia_shisheng", "god", 3, true)--, true)

luashenguojia_shisheng_hid = sgs.General(extension, "luashenguojia_shisheng_hid", "god", 3, true, true)






sgs.shisheng_scs = {}
sgs.shisheng_sc_ress = {}
sgs.shisheng_sc_ress_tf = {}
sgs.shisheng_responses = {}
sgs.shisheng_vss = {}


function CreateShishengTSSkillCard(sc_details)
	local ss10 = false
	if sc_details.i == 10 then
		ss10 = true
	end
	local shisheng_response = sgs.CreateSkillCard
	{
		name = "shisheng_response"..sc_details.i,
		target_fixed = true,
		will_throw = false,
		on_use = function(self, room, source, targets)
			local card_ids = self:getSubcards()
			local marks = 0
			for _,id in sgs.qlist(card_ids) do
				marks = 1000*marks+id
			end
			if ss10 then
				room:setPlayerMark(source, "ss10", 1)
			end
			room:setPlayerMark(source, "wins_to_lose", sc_details.markcost)
			room:setPlayerMark(source, "shisheng_id", marks)
		end
	}
	return shisheng_response
end



function CreateShishengResSkillCard(sc_details, tf)
	local name_addition = ""
	if tf then
		name_addition = "tf"
	end
	local ss10 = false
	if sc_details.i == 10 then
		ss10 = true
	end
	local shisheng_sc_res = sgs.CreateSkillCard
	{
		name = "shisheng_sc_re"..name_addition..sc_details.i,
		target_fixed = tf,
		will_throw = false,
		filter = function(self, selected, to_select)
			local pattern = self:getUserString()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			if pattern ~= ""  and pattern ~= "nullification" then
				local patterns = {"slash","fire_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
				for _,p in pairs(patterns) do
					if string.find(pattern, p) then
						pattern = p
						break
					end
				end
				local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
				local targetlist = sgs.PlayerList()
				for _,p in pairs(selected) do
					targetlist:append(p)
				end
				return card:targetFilter(targetlist, to_select, sgs.Self)
			end
			return false
		end,
		on_validate = function(self, use)
			local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
			local pattern = self:getUserString()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local pattern_valid = {}
			if pattern ~= "nullification" then
				table.insert(pattern_valid, "esc")
			end
			local room = use.from:getRoom()
			if pattern ~= "" then				
				for _,p in ipairs(patterns) do
					if string.find(pattern, p) then
						table.insert(pattern_valid, p)
					end
				end
			else
				for _,p in ipairs(patterns) do
					local card = sgs.Sanguosha:cloneCard(p, sgs.Card_NoSuit, 0)
					if card:isAvailable(use.from) then
						table.insert(pattern_valid, p)
					end
				end
			end
			local choice =  room:askForChoice(use.from, self:objectName(), table.concat(pattern_valid, "+"))
			if choice ~= "esc" then
				local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_SuitToBeDecided, 0)
				local card_ids = self:getSubcards()				
				card:setSkillName("shisheng")
				room:setPlayerMark(use.from, "wins_to_lose", sc_details.markcost)
				if ss10 then
					room:setPlayerMark(use.from, "ss10", 1)
				else
					for _,id in sgs.qlist(card_ids) do
						card:addSubcard(id)
					end
				end
				return card
			else
				return nil
			end
		end,--[[
		on_validate_in_response = function(self, user) sgs.Sanguosha:currentRoom():getCurrent():speak("a")
			local pattern = self:getUserString()
			local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
			local card_ids = self:getSubcards()
			for _,id in sgs.qlist(card_ids) do
				card:addSubcard(id)
			end
			card:setSkillName("shisheng")
			room:setPlayerMark(user, "wins_to_lose", sc_details.markcost)
			return card
		end]]
	}
	return shisheng_sc_res
end

function CreateShishengSkillCard(sc_details)
	local ss10 = false
	if sc_details.i == 10 then
		ss10 = true
	end
	local shisheng_sc = sgs.CreateSkillCard
	{
		name = "shisheng_sc"..sc_details.i,
		target_fixed = true,
		will_throw = false,
		on_use = function(self, room, source, targets)
			local card_ids = self:getSubcards()
			local marks = 0
			for _,id in sgs.qlist(card_ids) do
				marks = 1000*marks+id
			end
			room:setPlayerMark(source, "wins_to_lose", sc_details.markcost)
			room:setPlayerMark(source, "shisheng_id", marks)
			if ss10 then
				room:setPlayerMark(source, "ss10", 1)
			end
			room:setPlayerProperty(source, "shisheng_sel", sgs.QVariant())
			if room:askForUseCard(source, "@@shisheng", "@shisheng") then
				
			end
		end
	}
	return shisheng_sc
end





function CreateShishengVsSkill(skill_details)
	local shisheng_vsskill = sgs.CreateViewAsSkill
	{
		name = "shisheng"..skill_details.i,
		n = skill_details.cn,
		view_filter = skill_details.view_filter,
		view_as = function(self, cards)
			local player = sgs.Self
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if #cards == skill_details.cn then
				local card
				if pattern ~= "" then
					if pattern == "@@shisheng_1_10" then
						card = sgs.shisheng_responses[skill_details.i]:clone()
					end
					local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
					local pattern_fx
					for _,p in ipairs(patterns) do
						if string.find(pattern, p) then
							pattern_fx = p
							break
						end
					end
					if pattern_fx then
						if sgs.Sanguosha:cloneCard(pattern_fx, sgs.Card_NoSuit, 0):targetFixed() then								
							card = sgs.shisheng_sc_ress_tf[skill_details.i]:clone()
						else
							card = sgs.shisheng_sc_ress[skill_details.i]:clone()
						end
					end
					card:setUserString(pattern)
				else
					card = sgs.shisheng_scs[skill_details.i]:clone()
				end
				for _,i in ipairs(cards) do
					card:addSubcard(i)
				end
				return card
			end
			return nil
		end,
		enabled_at_play = function(self, player)
			return player:getMark("@wins") >= skill_details.i
		end,
		enabled_at_response = function(self, player, pattern) --return false end,
			if player:getMark("@wins") < skill_details.i then
				return false
			elseif pattern == "@@shisheng_1_10" then
				return true
			elseif pattern == "slash" then
				return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			elseif pattern == "nullification" or string.find(pattern, "peach") or string.find(pattern, "analeptic") then
				return true
			end
			return false
		end,
		enabled_at_nullification = function(self, player)
			return player:getMark("@wins") >= skill_details.i
		end
	}
	return shisheng_vsskill
end


for i=1,10 do
	local sc_details = {}
	sc_details.i = i
	if i <= 2 then
		sc_details.markcost = 0
	elseif i <= 6 then
		sc_details.markcost = 1
	elseif i <= 9 then
		sc_details.markcost = 2
	else
		sc_details.markcost = 3
	end
	table.insert(sgs.shisheng_scs, CreateShishengSkillCard(sc_details))
	table.insert(sgs.shisheng_sc_ress, CreateShishengResSkillCard(sc_details, false))
	table.insert(sgs.shisheng_sc_ress_tf, CreateShishengResSkillCard(sc_details, true))
	table.insert(sgs.shisheng_responses, CreateShishengTSSkillCard(sc_details))
	
	local skill_details = {}
	skill_details.i = i
	if i <= 2 then
		skill_details.cn = 1
	elseif i <= 5 then
		skill_details.cn = 2
	elseif i == 6 then
		skill_details.cn = 3
	elseif i <= 9 then
		skill_details.cn = 1
	else
		skill_details.cn = 0
	end
	
	skill_details.marks = sc_details.markcost
	if i == 1 then
		skill_details.view_filter = function(self, selected, to_select)
			return to_select:getNumber() == 5
		end
	elseif i == 2 then
		skill_details.view_filter = function(self, selected, to_select)
			return to_select:getNumber() == 10
		end	
	elseif i == 3 then
		skill_details.view_filter = function(self, selected, to_select)
			if #selected == 0 then
				return true
			else
				return to_select:getNumber() == selected[1]:getNumber() and to_select:getSuit() == selected[1]:getSuit()
			end
		end
	elseif i == 4 then
		skill_details.view_filter = function(self, selected, to_select)
			if #selected == 0 then
				return true
			else
				return to_select:getNumber() == selected[1]:getNumber()
			end
		end
	elseif i == 5 then
		skill_details.view_filter = function(self, selected, to_select)
			if #selected == 0 then
				return true
			else
				return to_select:getSuit() == selected[1]:getSuit()
			end
		end
	elseif i == 6 then
		skill_details.view_filter = function(self, selected, to_select)
			return true
		end
	elseif i == 7 then
		skill_details.view_filter = function(self, selected, to_select)
			return to_select:isKindOf("TrickCard")
		end	
	elseif i == 8 then
		skill_details.view_filter = function(self, selected, to_select)
			return to_select:isKindOf("EquipCard")
		end	
	elseif i == 9 then
		skill_details.view_filter = function(self, selected, to_select)
			return to_select:isKindOf("BasicCard")
		end	
	elseif i == 10 then
		skill_details.view_filter = function(self, selected, to_select)
			return true
		end	
	end
	table.insert(sgs.shisheng_vss, CreateShishengVsSkill(skill_details))
	luashenguojia_shisheng_hid:addSkill(sgs.shisheng_vss[i])
	--addSkills的方法不管怎么写都是“重复技能”！虽然不影响游戏但是影响体验！所以就建立了一个完全隐藏的马甲持有这些技能。
	
end



shisheng_card = sgs.CreateSkillCard
{
	name = "shisheng_card",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
		local choices = {"esc"}
		for i=1,#patterns do
			local card = sgs.Sanguosha:cloneCard(patterns[i], sgs.Card_NoSuit, 0)
			if card:isAvailable(source) then
				table.insert(choices, patterns[i])
			end
		end
		if #choices > 1 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			if choice == "esc" then return false end
			room:setPlayerProperty(source, "shisheng_sel", sgs.QVariant(choice))	
			--property真心好用，几乎可以取代flag和mark，虽然有时候确实没那两个方便			
			if room:askForUseCard(source, "@@shisheng", "@shisheng") then
		
			end
			return false
		end
	end
}
shisheng_vs = sgs.CreateViewAsSkill
{
	name = "shisheng",
	n = 0,
	view_as = function(self, cards)
		local player = sgs.Self
		local pattern = player:property("shisheng_sel"):toString()
		if pattern ~= "" then			
			local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
			if player:getMark("ss10") == 0 then
				local marks = player:getMark("shisheng_id")
				local remaining = math.mod(marks, 1000)
				while marks > 1000 do
					card:addSubcard(remaining)
					marks = (marks - remaining)/1000
					remaining = math.mod(marks, 1000)
				end
				card:addSubcard(remaining)
			end
			card:setSkillName(self:objectName())
			return card
		end
		return shisheng_card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@shisheng"
	end
}

shisheng = sgs.CreateTriggerSkill
{
	name = "shisheng",
	events = {sgs.Damage, sgs.Damaged, sgs.GameStart, sgs.CardUsed, sgs.CardAsked},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = shisheng_vs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			local marks = player:getMark("@wins")
			if marks < 10 then
				local gains = math.min(damage.damage, 10-marks)
				player:gainMark("@wins", gains)
				for i=3,marks+gains do
					if not player:hasSkill("shisheng"..i) then
						room:acquireSkill(player, "shisheng"..i)
					end
				end
			end
			return false
		end
		if event == sgs.GameStart then
			
			local marks = 0
			
			for i=1,10 do
				if player:hasSkill("shisheng"..i) then
					marks = i
				end
			end
		
			local marks_get = player:getMark("@wins")
			if marks_get < math.max(marks, 2) then
				player:gainMark("@wins", math.max(marks, 2) - marks_get)
			end
			
			if marks == 0 then			
				for i=1,2 do
					room:acquireSkill(player, "shisheng"..i)
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			
			if use.card:getSkillName() ~= self:objectName() then return false end
			
			if player:getMark("wins_to_lose") > 0 then
				local lose = player:getMark("wins_to_lose")
				player:loseMark("@wins", lose)
				room:setPlayerMark(player, "wins_to_lose", 0)
				room:setPlayerMark(player, "ss10", 0)
			end
			return false			
		end
		if event == sgs.CardAsked then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()--data:toStringList():first() 
			--后一种写法无效，first()不能用= =
			
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end 
			local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
			local pattern_valid = {}
			table.insert(pattern_valid, "esc")
			for _,p in ipairs(patterns) do
				if string.find(pattern, p) then
					table.insert(pattern_valid, p)-- player:speak(p)
				end
			end
			if #pattern_valid == 1 then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local card_used = room:askForUseCard(player, "@@shisheng_1_10", "@shisheng_1_10")
			if not card_used then return false end
			local choice =  room:askForChoice(player, self:objectName(), table.concat(pattern_valid, "+"))
			if choice ~= "esc" then
				local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_SuitToBeDecided, 0)
				if player:getMark("ss10") == 0 then
					local marks = player:getMark("shisheng_id")
					local remaining = math.mod(marks, 1000)
					while marks > 1000 do
						card:addSubcard(remaining)
						marks = (marks - remaining)/1000
						remaining = math.mod(marks, 1000)
					end
					card:addSubcard(remaining)
				end
				room:setPlayerMark(player, "ss10", 0)
				card:setSkillName(self:objectName())
				room:provide(card)
				room:setPlayerMark(player, "shisheng_id", 0)
				if player:getMark("wins_to_lose") > 0 then
					player:loseMark("@wins", player:getMark("wins_to_lose"))
					room:setPlayerMark(player, "wins_to_lose", 0)
				end
				return true
			else
				return false
			end
		end
	end
}

luashenguojia_shisheng:addSkill(shisheng)
luashenguojia_shisheng_hid:addSkill("shisheng")

function doCleaningWhileLosingSkill(player, data, skillname, symbolname)
	local name = data:toString()
	if name == skillname then
		if player:getMark(symbolname) > 0 then
			player:loseAllMarks(symbolname)
		end
		if not player:getPile(symbolname):isEmpty() then
			player:removePileByName(symbolname)
		end
	end
end

luaskillalmr = sgs.CreateTriggerSkill --获得、失去技能时，调整移出游戏的牌、其他技能和标记
{
	name = "#luaskillalmr",
	events = {sgs.EventLoseSkill, sgs.EventAcquireSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventAcquireSkill then
			local name = data:toString()
			if name == "shisheng" or name == "luahujiamr" or name == "luafendao" then
				if name == "luafendao" then
					if player:getMark("@fendao") == 0 then
						player:gainMark("@fendao")
					end
				elseif name == "luahujiamr"	then
					room:setPlayerCardLimitation(player, "use", "Slash", false)
				elseif name == "shisheng" then
					local marks = 0
			
					for i=1,10 do
						if player:hasSkill("shisheng"..i) then
							marks = i
						end
					end
					
					local marks_get = player:getMark("@wins")
					if marks_get < math.max(marks, 2) then
		
						player:gainMark("@wins", math.max(marks, 2) - marks_get)
						
					end
			
					if marks == 0 then			
						for i=1,2 do
							room:acquireSkill(player, "shisheng"..i)
						end
					end
				end
			elseif name == "luaqilin" then
				local cards = player:getHandcards()
				room:filterCards(player, cards, true)
			end
			return false
		end
		if event == sgs.EventLoseSkill then
			local skillnames = {"luafendao", "shisheng", "luahuanying"}
			local symbolnames = {"@fendao", "@wins", "huanyingpile"}
			for i=1,#skillnames do
				doCleaningWhileLosingSkill(player, data, skillnames[i], symbolnames[i])
			end
			if data:toString() == "shisheng" then
				for i=1,10 do
					if player:hasSkill("shisheng"..i) then player:speak("aa")
						room:detachSkillFromPlayer(player, "shisheng"..i)
					end
				end
			end
			if data:toString() == "luahujiamr" then player:speak("a")
				room:removePlayerCardLimitation(player, "use", "Slash")
			end
		end
	end
}

luashenguojia_shisheng:addSkill(luaskillalmr)
luashenguojia_shisheng_hid:addSkill(luaskillalmr)
luazuoci_caokong:addSkill(luaskillalmr:objectName())
luadengaizhonghui_fendao:addSkill(luaskillalmr:objectName())
luajiangwei_qilin:addSkill(luaskillalmr:objectName())
luacaiwenji_shushen:addSkill(luaskillalmr:objectName())
local relatedskills = {"luaqilin", "luafendao", "shisheng", "luahuanying", "luahujiamr"}

for _,skill in ipairs(relatedskills) do

	extension:insertRelatedSkills(skill, luaskillalmr:objectName())
	
end








		
		
		
	
	
	
