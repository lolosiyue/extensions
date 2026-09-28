Lolihime = sgs.Package("lolihime")

jdd = sgs.General(Lolihime, "jdd", "real", 3, false)
-- acc = sgs.General(Lolihime, "acc", "science", 3)
--------------------------------------------------------------------------------------
tuhao = sgs.CreateTriggerSkillV2{
	name = "tuhao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from:objectName() == player:objectName() and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Play and not player:getCards("hej"):isEmpty() then
			if use.card:getSuit() == sgs.Card_Heart or use.card:getSuit() == sgs.Card_Diamond
				or use.card:getSuit() == sgs.Card_Club or use.card:getSuit() == sgs.Card_Spade then
				return "tuhao"
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if use.card:getSuit() == sgs.Card_Heart or use.card:getSuit() == sgs.Card_Diamond then
			if not player:hasFlag("tuhao_used") then
				room:broadcastSkillInvoke(skill:objectName())
				player:setFlags("tuhao_used")
			end
			player:drawCards(1)
		end
		if use.card:getSuit() == sgs.Card_Club or use.card:getSuit() == sgs.Card_Spade then
			if not player:hasFlag("tuhao_black_used") then
				room:broadcastSkillInvoke(skill:objectName())
			else
				room:setPlayerFlag(player, "tuhao_black_used")
			end
			local id = room:askForCardChosen(player, player, "hej", "tuhao")
			room:throwCard(id,player, player)
		end
		return false
	end
}

---------------------------------------------------------------------------------------
yehuo = sgs.CreateTriggerSkillV2{
	name="yehuo",
	events = {sgs.TurnStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() == sgs.Player_Start and not player:faceUp() and player:hasSkill(skill:objectName()) then
			return "yehuo"
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:turnOver()
		return false
	end
}

-----------------------------------------------
-- vector = sgs.CreateTriggerSkill
-- {
-- 	name = "vector",
-- 	frequency = sgs.Skill_NotFrequent,
--     events = {sgs.CardEffect},
--
-- 	on_trigger = function(self, event, player, data)
--         local room = player:getRoom()
-- 		if player:isKongcheng()then return end
-- 		local effect = data:toCardEffect()
-- 		if effect.to:objectName() ~= player:objectName() then return end
-- 		if player:getCards("he"):length() == 0 then return end
-- 		if room:askForSkillInvoke(player,self:objectName(),data) and room:askForCard(player, ".|.|.", "vector_Discard", sgs.QVariant(), self:objectName()) then
-- 			local list = room:getAlivePlayers()
-- 			for _,q in sgs.qlist(list) do
-- 				if sgs.Sanguosha:isProhibited(player, q, effect.card) then
-- 					list:removeOne(q)
-- 				end
-- 			end
-- 			local dest = room:askForPlayerChosen(player, list, "vector")
-- 			room:broadcastSkillInvoke(self:objectName())
-- 			room:doLightbox("vector$", 800)
-- 			effect.to = dest
-- 			data:setValue(effect)
-- 		end
-- 		return false
-- 	end,
-- }

------------------------------------------------------------------------------------------------
shouji = sgs.CreateViewAsSkillV2{
	name = "shouji",
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	limit_scope = sgs.Skill_Limit_Phase,
	max_usage_limit = 1,
	phase_name = "Play",
	can_activate = function(skill, request)
		return request:getInitiator() ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player ~= nil
			and request:getSelectedCardIds():length() < player:getHp() + 1
			and not player:isJilei(candidate)
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getSelectedCardIds():length() == player:getHp() + 1
	end,
	on_effect = function(skill, ctx)
		local source = ctx.invoker
		local room = source:getRoom()
		room:doLightbox("shouji$", 1000)
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:getCards("h"):isEmpty() then
				local list = p:handCards()
				room:fillAG(list,source)
				local card_id = room:askForAG(source,list,true,skill:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				room:obtainCard(source,card,false)
				room:clearAG(source)
			end
		end
	end
}

--------------------------------------------------------

kuro = sgs.General(Lolihime, "kuro", "magic", 4, false, false, false)


spreadillness = sgs.CreateTriggerSkillV2{
	name = "spreadillness",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() == sgs.Player_Finish
			and (player:getMark("@spreadillness") > 0 or player:hasSkill("spring") or player:getMark("@immune") > 0) then
			local holder = room:findPlayerBySkillName("spreadillness")
			if holder then return "spreadillness", holder:objectName() end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if target:getMark("@spreadillness") > 0 or target:hasSkill("spring") then
			for _,p in sgs.qlist(room:getOtherPlayers(target)) do
				if target:distanceTo(p) == 1 then
					local x = math.random(1,5)
					if p:getMark("@spreadillness") == 0 and p:getMark("@immune") == 0 and x > 1 then
						--room:acquireSkill(p,"spreadillness",true)
						p:gainMark("@spreadillness")
						room:broadcastSkillInvoke("spreadillness")
					end
				end
				if target:distanceTo(p) == 2 then
					local y = math.random(1,2)
					if p:getMark("@spreadillness") == 0 and p:getMark("@immune") == 0 and y == 1 then
						--room:acquireSkill(p,"spreadillness",true)
						p:gainMark("@spreadillness", 1)
						room:broadcastSkillInvoke("spreadillness")
					end
				end
			end
			local z = math.random(1,2)
			if z == 1 then
				--room:detachSkillFromPlayer(target,"spreadillness",true)
				target:loseMark("@spreadillness")
				if not target:hasSkill("spring") then
					target:gainMark("@immune")
				end
			end

			if not target:hasSkill("spring") then
				room:broadcastSkillInvoke("spreadillness", 6)
				room:loseHp(target)
			end
		elseif target:getMark("@immune") > 0 then
			local z = math.random(1,2)
			if z == 1 then
				target:loseMark("@immune")
			end
		end
		return false
	end
}



spring = sgs.CreateTriggerSkillV2{
	name = "spring",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if (damage.from and not damage.from:hasSkill("spring")) and (damage.to and not damage.to:hasSkill("spring")) then return false end
			if damage.from and damage.from:getMark("@spreadillness") == 0 or damage.to:getMark("@immune") > 0 then return false end
			local sp = room:findPlayerBySkillName("spring")
			if not sp then return false end
			return "spring", sp:objectName()
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill("spring") then
				return "spring"
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DamageInflicted then
			return room:askForSkillInvoke(ctx.owner, "spring", ctx.original_data)
		elseif event == sgs.EventPhaseStart then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@spreadillness") > 0 then
					return false
				end
			end
			local card1 = room:askForCard(player, ".|club|.|hand|.", "@spreadDiscard", sgs.QVariant(), skill:objectName())
			return card1 ~= nil
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.DamageInflicted then
			local damage = ctx.original_data:toDamage()
			--room:detachSkillFromPlayer(damage.from,"spreadillness",true)
			if damage.from then
				damage.from:loseMark("@spreadillness")
			end
			--room:acquireSkill(damage.to,spreadillness)
			if damage.to:getMark("@spreadillness") == 0 then
				damage.to:gainMark("@spreadillness")
			end
			damage.damage = 0
			ctx.original_data:setValue(damage)
			room:broadcastSkillInvoke("spring")
			return true
		elseif event == sgs.EventPhaseStart then
			player:gainMark("@spreadillness")
		end
		return false
	end
}
---------------------------
--qb = sgs.General(Lolihime, "qb", "Erciyuan", 3, false, false, false)

youpian = sgs.CreateViewAsSkillV2{
	name = "youpian",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasFlag("youpian_used")
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected == 0 and candidate:getCardCount(true) > 0
			and candidate:objectName() ~= request:getInitiator():objectName()
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
	on_effect_target = function(skill, ctx, target)
		local room = target:getRoom()
		room:setPlayerFlag(ctx.invoker,"youpian_used")
		room:setPlayerMark(target,"youpian_target",1)

		local y = math.random(1,2)
		if y==1 then
			local choice = room:askForChoice(target,"youpianCARD","youpianyes+youpianno")
			if choice == "youpianyes" then
				room:loseHp(target)
				return
			elseif choice == "youpianno" then
				return
			end
		elseif y==2 then
			local choice = room:askForChoice(target,"youpianCARD","youpianno+youpianyes")
			if choice == "youpianyes" then
				room:loseHp(target)
				return
			elseif choice == "youpianno" then
				room:acquireSkill(target,spreadillness)
				return
			end
		end
	end
}

----------------------------------

mianma = sgs.General(Lolihime, "mianma", "real", 1, false, false, false)


lingti = sgs.CreateTriggerSkillV2
{
	name = "lingti",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageDone,sgs.PreHpLost},
	can_trigger = function(skill, event, room, player, data)
		if player:hasSkill(skill:objectName()) then
			return "lingti"
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke("lingti")
		player:drawCards(1)
		return true
	end,
	priority = 8
}


lolihime_xiaoshi = sgs.CreateTriggerSkillV2
{
	name = "lolihime_xiaoshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.GameStart then
			if player:hasSkill(skill:objectName()) then return "lolihime_xiaoshi" end
		elseif event == sgs.EventAcquireSkill then
			if data:toString() == skill:objectName() then return "lolihime_xiaoshi" end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName()) then
				return "lolihime_xiaoshi"
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(0))
			room:broadcastSkillInvoke("lolihime_xiaoshi")
			player:gainMark("@Menma_turn", room:getAlivePlayers():length() + 5)
		elseif event == sgs.EventPhaseStart then
			player:loseMark("@Menma_turn")
			if player:getMark("@Menma_turn") == 0 then
				room:doLightbox("lolihime_xiaoshi$", 3000)
				room:killPlayer(player, killer)
			end
		end
		return false
	end,
	priority = 7
}
------------------------------------
-- cr = sgs.General(Lolihime, "cr", "real", 4, false, false, false)

mengxian= sgs.CreateTriggerSkillV2
{
	name = "mengxian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.FinishJudge},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and player:hasSkill(skill:objectName()) then
				return "mengxian"
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == skill:objectName() then
				return "mengxian"
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local broadcasted = false
			while player:askForSkillInvoke(skill:objectName()) do
				if not broadcasted then
					room:broadcastSkillInvoke("mengxian", 1)
					room:doLightbox("mengxian$", 500)
					broadcasted = true
				end
				local choice = room:askForChoice(player,skill:objectName(),"jiben12+jinang12+zhuangbei12")
				if choice == "zhuangbei12" then
					local id = room:askForCardChosen(player, player, "h", "mengxian")
					room:throwCard(id,player, player)
					player:gainMark("@force", 1)
				end

				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.negative = false
				judge.play_animation = false
				judge.time_consuming = true
				judge.reason = skill:objectName()
				room:judge(judge)
				if judge.card:isKindOf("BasicCard") and choice == "jiben12" then
					break
				elseif judge.card:isKindOf("TrickCard") and choice == "jinang12" then
					break
				elseif judge.card:isKindOf("EquipCard") and choice == "zhuangbei12" then
					break
				end
				if judge.card:isKindOf("BasicCard") then
					room:broadcastSkillInvoke("mengxian", 2)
				elseif judge.card:isKindOf("TrickCard") then
					room:broadcastSkillInvoke("mengxian", 3)
				else
					room:broadcastSkillInvoke("mengxian", 4)
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			local card = judge.card
			player:obtainCard(card)
			return true
		end
		return false
	end
}

LLJ_force= sgs.CreateTriggerSkillV2
{
	name = "LLJ_force",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.FinishJudge},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName()) then
				return "LLJ_force"
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == skill:objectName() then
				return "LLJ_force"
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			while player:askForSkillInvoke(skill:objectName()) do
				local choice = room:askForChoice(player,skill:objectName(),"jiben12+jinang12+zhuangbei12")
				if choice == "zhuangbei12" then
					local id = room:askForCardChosen(player, player, "h", "mengxian")
					room:throwCard(id,player, player)
				end

				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.negative = false
				judge.play_animation = false
				judge.time_consuming = true
				judge.reason = skill:objectName()
				room:judge(judge)
				room:broadcastSkillInvoke("LuaLuoshen")
				if judge.card:isKindOf("BasicCard") and choice == "jiben12" then
					break
				elseif judge.card:isKindOf("TrickCard") and choice == "jinang12" then
					break
				elseif judge.card:isKindOf("EquipCard") and choice == "zhuangbei12" then
					break
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			local card = judge.card
			player:obtainCard(card)
			return true
		end
		return false
	end
}


------------------------------------------

LLJ_chihun = sgs.CreateTriggerSkillV2{
	name = "LLJ_chihun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from:objectName() == player:objectName() and player:hasSkill(skill:objectName())
			and player:getPhase() == sgs.Player_Play and not player:getCards("hej"):isEmpty()
			and use.card:getSuit() == sgs.Card_NoSuit then
			return "LLJ_chihun"
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(2)
		return false
	end
}

------------------------------------------------------------


LLJ_guilty = sgs.CreateTriggerSkillV2{-----罪
	name = "LLJ_guilty",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	can_trigger=function(skill, event, room, player, data)
		local holder = room:findPlayerBySkillName("LLJ_guilty")
		if holder then
			return "LLJ_guilty", holder:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local da = ctx.original_data:toDamage()
		if da.from == nil then return false end
		if event== sgs.Damaged then
			if da.from:hasSkill(skill:objectName()) then return false end
			if da.from:getMark("@LLJ_guilty") == 0 then
				da.from:gainMark("@LLJ_guilty")
			end
			da.to:loseMark("@LLJ_guilty")
		end
		return false
	end
}

LLJ_DN = sgs.CreateTriggerSkillV2{-----罪
	name = "LLJ_DN",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	can_trigger=function(skill, event, room, player, data)
		local holder = room:findPlayerBySkillName("LLJ_DN")
		if holder then
			return "LLJ_DN", holder:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local da = ctx.original_data:toDamage()
		if da.from == nil then return false end
		if event== sgs.Damaged then
			if da.from:getMark("@LLJ_guilty") > 0 then
			local hp = da.from:getHp()
			room:loseHp(da.from,hp)
			end
		end
		return false
	end
}

--killer = sgs.General(Lolihime, "killer", "Erciyuan", 3, true, false, false)

---------------------------------------------

rika2 = sgs.General(Lolihime, "rika2", "magic", 3, false, false, false)


LLJ_recycle = sgs.CreateTriggerSkillV2{
	name = "LLJ_recycle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart, sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_Finish then
				if player:getPile("lunhui"):length() > 0 then
					return "LLJ_recycle"
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if not source then return false end
			if source:objectName() ~= player:objectName() then return false end
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			local reason = move.reason.m_reason
			local flag = false
			if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				flag = true
			end
			if reason == 0x01 then
				flag = true
			end
			if flag then return "LLJ_recycle" end
		elseif event == sgs.DrawNCards then
			return "LLJ_recycle"
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local lunhui = player:getPile("lunhui")
			if lunhui:length() > 0 then
				local move2 = sgs.CardsMoveStruct()
				move2.card_ids =lunhui
				move2.to = player
				move2.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move2,false)
				room:broadcastSkillInvoke("LLJ_recycle")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			local ids = sgs.QList2Table(move.card_ids)
			local places = move.from_places
			for i = 1, #ids, 1 do
				local id = ids[i]
				local place = places[i]
				local suit = sgs.Sanguosha:getCard(id):getSuit()
				if suit ~= sgs.Card_NoSuit then
					if place ~= sgs.Player_PlaceSpecial then
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							player:addToPile("lunhui", id)
						end
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local data = ctx.original_data
			if data:toInt() - 1 > 0 then
				data:setValue(data:toInt() - 1)
			else
				data:setValue(0)
			end
		end
		return false
	end,
}

LLJ_recycleClear = sgs.CreateTriggerSkillV2{
	name = "#LLJ_recycle-clear",
	events = {sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not owner or owner:objectName() ~= player:objectName() then return end
		if ctx.original_data:toSkillChange().skillName == "LLJ_recycle" then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:removeFixedDistance(player, p, 1)
			end
		end
	end,
}

-------芽衣子 补充
SE_Xinyuan = sgs.CreateTriggerSkillV2{
        name = "SE_Xinyuan",
        frequency = sgs.Skill_NotFrequent,
        events = {sgs.BeforeCardsMove},
        can_trigger = function(skill, event, room, player, data)
            if not player:hasSkill(skill:objectName()) then return false end
            local move = data:toMoveOneTime()
            local source = move.from
            if source and source:objectName() == player:objectName() and player:getPhase() == sgs.Player_Discard then
                if move.to_place == sgs.Player_DiscardPile then
                    local reason = move.reason
                    local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                    if basic == sgs.CardMoveReason_S_REASON_DISCARD then
                        local i = 0
                        for _,card_id in sgs.qlist(move.card_ids) do
                            if room:getCardOwner(card_id):objectName() == move.from:objectName() then
                                local place = move.from_places:at(i)
                                if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
                                    return "SE_Xinyuan"
                                end
                            end
                            i = i + 1
                        end
                    end
                end
            end
            return false
        end,
        on_cost = function(skill, event, room, player, ctx)
            return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
        end,
        on_effect = function(skill, event, room, player, ctx)
            local move = ctx.original_data:toMoveOneTime()
            local i = 0
            local lirang_card = sgs.IntList()
            for _,card_id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(card_id):objectName() == move.from:objectName() then
                    local place = move.from_places:at(i)
                    if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
                        lirang_card:append(card_id)
                    end
                end
                i = i + 1
            end
            if not lirang_card:isEmpty() then
            	player:setMark("xinyuan_dis", lirang_card:length())
                local dest = room:askForPlayerChosen(player,room:getOtherPlayers(player),skill:objectName())
                room:broadcastSkillInvoke("SE_Xinyuan")
                if dest then dest:drawCards(lirang_card:length()) end
            end
            return false
        end
    }


local function tabcontain(a,b)
	flag=false
	for _, c in ipairs(a) do
		if b==c then
			flag=true
		end
	end
	return flag
end


ku = sgs.General(Lolihime, "ku", "real", 4, false)

dandiao = sgs.CreateTriggerSkillV2{
    name = "dandiao",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
    can_trigger = function(skill, event, room, player, data)
        if player:getPhase() == sgs.Player_Draw and player:hasSkill(skill:objectName()) then
            return "dandiao"
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
				local spade=0
				local heart=0
				local club=0
				local diamond=0
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:getSuit()==sgs.Card_Spade then  spade=spade+1 end
					if card:getSuit()==sgs.Card_Heart then  heart=heart+1 end
					if card:getSuit()==sgs.Card_Club then  club=club+1 end
					if card:getSuit()==sgs.Card_Diamond then  diamond=diamond+1 end
				end
				local onecount=0
				local whichflu="none"
				if spade == 1 then onecount=onecount+1
				whichflu="spade" end
				if heart == 1 then onecount=onecount+1
				whichflu="heart" end
				if club == 1 then onecount=onecount+1
				whichflu="club" end
				if diamond == 1 then onecount=onecount+1
				whichflu="diamond" end
				if onecount~=1 then whichflu="none" end


				--local condition = {}
				--local conditionrank = {}
				----储存弃牌堆的花色
				local spade=0
				local heart=0
				local club=0
				local diamond=0
				for i=0,200 do
					if room:getDiscardPile():at(i)>0 then
						if sgs.Sanguosha:getCard(room:getDiscardPile():at(i)):getSuit()==sgs.Card_Spade then  spade=spade+1 end
						if sgs.Sanguosha:getCard(room:getDiscardPile():at(i)):getSuit()==sgs.Card_Heart then  heart=heart+1 end
						if sgs.Sanguosha:getCard(room:getDiscardPile():at(i)):getSuit()==sgs.Card_Club then  club=club+1 end
						if sgs.Sanguosha:getCard(room:getDiscardPile():at(i)):getSuit()==sgs.Card_Diamond then  diamond=diamond+1 end
					end
				end
				local rank={}
				table.insert(rank,spade)
				table.insert(rank,heart)
				table.insert(rank,club)
				table.insert(rank,diamond)
				table.sort(rank)
				local aimflu=0
				local damagewillbedone=0
				if whichflu=="spade" then aimflu=spade end
				if whichflu=="heart" then aimflu=heart end
				if whichflu=="club" then aimflu=club end
				if whichflu=="diamond" then aimflu=diamond end
				--if whichflu==0 then return end
				for i=1,4 do
					if rank[i]==aimflu then
						damagewillbedone=i
					end
				end


				--[[
				i=1
				while math.max(spade,heart,club,diamond)>0 do
					local Ah = math.max(spade,heart,club,diamond)
					if spade==Ah then
						table.insert(condition,"spade")
						table.insert(conditionrank,i)
						spade=-1
					end
					if heart==Ah then
						table.insert(condition,"heart")
						table.insert(conditionrank,i)
						heart=-1
					end
					if club==Ah then
						table.insert(condition,"club")
						table.insert(conditionrank,i)
						club=-1
					end
					if diamond==Ah then
						table.insert(condition,"diamond")
						table.insert(conditionrank,i)
						diamond=-1
					end
					i=i+1
				end
				]]




				--[[if spade>Ah and tabcontain(condition, "spade") then table.remove(condition,1)end
				if heart>Ah and tabcontain(condition, "heart") then table.remove(condition,1) end
				if club>Ah and tabcontain(condition, "club") then table.remove(condition,1) end
				if diamond>Ah and tabcontain(condition, "diamond") then table.remove(condition,1) end]]

	            local card1 = room:drawCard()
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(card1)
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), skill:objectName(), nil)
				move.to_place = sgs.Player_PlaceTable
				room:moveCardsAtomic(move, true)

				local card2 = sgs.Sanguosha:getCard(card1)
				local suit = card2:getSuitString()

				if whichflu==suit then
					if math.random(1, 2) == 1 then
						room:broadcastSkillInvoke("dandiao", 1)
					else
						room:broadcastSkillInvoke("dandiao", 2)
					end
					room:doLightbox("dandiao$", 3000)
					room:showAllCards(player)
					local to = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "solo", true, true)
					room:damage(sgs.DamageStruct(skill:objectName(), player, to, damagewillbedone, sgs.DamageStruct_Thunder))
					room:loseMaxHp(to, math.floor(damagewillbedone/2))
				else
					if math.random(1, 2) == 1 then
						room:broadcastSkillInvoke("dandiao", 3)
					else
						room:broadcastSkillInvoke("dandiao", 4)
					end
				end

				local move2 = move
	            move2.to_place = sgs.Player_PlaceHand
	            move2.to = player
	            move2.reason.m_reason = sgs.CardMoveReason_S_REASON_DRAW
	            room:moveCardsAtomic(move2, true)
				return true
    end
}
ku:addSkill(dandiao)

sgs.LoadTranslationTable{
["ku"] = "竹井久",
["&ku"] = "竹井久",
["@ku"] = "天才麻将少女",
["~ku"] = "那个呢...我平时也是选择更加合理的打法的...",
["#ku"] = "地狱单骑",
["$dandiao1"] = "（まこ）在这里的我们，就是你选择概率低打法的结果呢，部长。",
["$dandiao2"] = "这可不安全哟。点和，立直，一发，宝牌4，12000点。",
["$dandiao3"] = "那么，你打算...把仅此一次的人生，也用理论和计算度过吗？",
["$dandiao4"] = "和看见了又该生气了吧。",
["dandiao"] = "单吊『将』",
["solo"] = "選擇一個角色受到傷害和上限失去！",
[':dandiao'] = "摸牌阶段开始时，你可以放弃摸牌改为从牌堆顶亮出一张牌。若此牌的花色是手牌中唯一的仅一张的花色，则可以展示所有手牌，并选择一名角色，对其造成X点雷电伤害之后失去[X/2]点体力上限，然后获得此牌。 （X为此牌的花色在弃牌堆中花色的从少到多的顺位）。",
["designer:ku"] = "帕秋莉·萝莉姬",
["cv:ku"] = "伊藤静",
["illustrator:ku"] = "",
}

pyuki = sgs.General(Lolihime, "pyuki", "real", 4, false)
eastfast = sgs.CreateTriggerSkillV2{
        name = "eastfast",
        frequency = sgs.Skill_Frequent,
        events = {sgs.EventPhaseStart},
        can_trigger = function(skill, event, room, player, data)
                if player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName()) then
                        return "eastfast"
                end
                return false
        end,
        on_effect = function(skill, event, room, player, ctx)
                if player:getPhase() == sgs.Player_Start then
                        local broadcasted = false
						::label1::
                        if room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
                                local condition=room:getDrawPile():length()-(3*room:getDiscardPile():length())
								local x=2+player:getCards("j"):length()
								if condition>0 then
										if not broadcasted then
											room:doLightbox("eastfast$", 500)
											room:broadcastSkillInvoke("eastfast", 1)
											broadcasted = true
										end
										local card = sgs.IntList()
										card:append(room:getDrawPile():at(0))
										local id = room:getDrawPile():at(0)
										local acard=sgs.Sanguosha:getCard(id)
										room:fillAG(card, player)
										player:setMark("eastfast_card", id)
										local choice = room:askForChoice(player,"eastfast","save+drop")
										if choice =="drop" then
											room:throwCard(acard, nil, nil)
										end
										if choice =="save" then
											if acard:isKindOf("Tacos") then
												room:broadcastSkillInvoke("eastfast", 2)
											end
											player:addToPile("save", acard, false)
										end
										room:clearAG(player)
										if player:getPile("save"):length()<x then
											goto label1
										end
										--goto labels
								end
								if condition<=0 then
										local card = room:askForUseCard(player, 'tacos', "@eastfast-tacos")
										if card then
											if not broadcasted then
												room:broadcastSkillInvoke("eastfast", 2)
												broadcasted = true
											end
											goto label1
										end
										--goto labels
								end
						end
						--::labels::
						local saves=player:getPile("save")
						if saves:length()>0 then
							local move = sgs.CardsMoveStruct()
							move.card_ids=saves
							move.to_place = sgs.Player_DrawPile
							move.reason.m_reason=sgs.CardMoveReason_S_REASON_PUT
							room:moveCardsAtomic(move,false)
							--room:askForGuanxing(player,saves,sgs.Room_GuanxingUpOnly)
						end
						room:clearAG(player)
                end
        end
}

pyuki:addSkill(eastfast)
sgs.LoadTranslationTable{
["pyuki"] = "片岡優希",
["&pyuki"] = "片岡優希",
["@pyuki"] = "天才麻将少女",
["#pyuki"] = "东风王",
["eastfast"] = "速攻『东风』",
["$eastfast1"] = "这样的话，先锋派最强的出战才是常理。就是说我最强！",
["$eastfast2"] = "这场比赛...不会再有东二局！",
["~pyuki"] = "墨西哥饼能量耗尽了...",
["@eastfast-tacos"] = "你可以弃置一张tacos，然后发动「速攻『东风』」",
["drop"] = "弃掉这张牌",
["save"] = "保留这张牌",
[':eastfast'] = '准备阶段开始时，若摸牌堆大于弃牌堆牌数的3倍时，你可以观看牌堆顶的1张牌，然后可以弃置这张牌或者选择将此牌置于保留区，若保留牌数小于于X，则可以继续发动该技能。若摸牌堆不大于弃牌堆牌数的3倍时，你可以使用手牌中的tacos，如此做可以继续发动该技能。技能结束时，将保留区的牌按栈的规则放回牌堆顶。（X为2+你的判定区的牌数。）',
["designer:pyuki"] = "帕秋莉·萝莉姬",
["cv:pyuki"] = "釘宮理恵",
["illustrator:pyuki"] = "",
}


rika2:addSkill(LLJ_recycle)
rika2:addSkill(LLJ_recycleClear)
Lolihime:insertRelatedSkills("LLJ_recycle", "#LLJ_recycle-clear")
--killer:addSkill(LLJ_guilty)
--killer:addSkill(LLJ_DN)
-- cr:addSkill(mengxian)
mianma:addSkill(lolihime_xiaoshi)
mianma:addSkill(lingti)
mianma:addSkill(SE_Xinyuan)
--qb:addSkill(youpian)
kuro:addSkill(spring)
kuro:addSkill(spreadillness)
--qb:addSkill(LLJ_chihun)
jdd:addSkill(tuhao)
jdd:addSkill(shouji)
-- acc:addSkill(vector)



sgs.LoadTranslationTable{
["shouji$"] = "image=image/animate/shouji.png",
["lolihime_xiaoshi$"] = "image=image/animate/lolihime_xiaoshi.png",
["eastfast$"] = "image=image/animate/eastfast.png",
["dandiao$"] = "image=image/animate/dandiao.png",


["rika2"] = "古手梨花",
["&rika2"] = "古手梨花",
["@rika2"] = "寒蝉鸣泣之时",
["#rika2"] = "无尽轮回の巫女",
["~rika2"] = "...",
["cv:rika2"] = "田村ゆかり",
["designer:rika2"] = "帕秋莉·萝莉姬",

["lunhui"] = "轮回",
["LLJ_recycle"] = "轮回",
[":LLJ_recycle"] = "锁定技。摸牌阶段，你少摸一张牌（最少为0）。当你使用牌因弃牌、使用结算完毕将要进入弃牌堆时，你可以获得之并置于武将牌上方。回合开始时，回合结束阶段开始时，你获得武将牌上的所有牌。",
["$LLJ_recycle1"] = "这样也好，就算你们不主动涉足，惩罚依旧会来临...因为，绵流祭即将开始...",
["$LLJ_recycle2"] = "我到底该怎么办...该怎么办...",
["~rika2"] = "（背景音：蝉鸣）今天，是举行绵流祭的日子...",

["killer"] = "夜神月",
["LLJ_guilty"] = "罪犯",
["LLJ_DN"] = "DN",
["LLJ_chihun"] = "炽魂",
[":LLJ_chihun"] = "出牌阶段，每当你使用一次指定性技能或使用无色的牌，你摸两张牌。",



["LLJ_force"] = "强制",
[":LLJ_force"] = "出牌阶段，你可以弃置8个标记，并获得场上一张装备牌",
["jiben12"] = "基本牌",
["jinang12"] = "锦囊牌",
["zhuangbei12"] = "装备牌",
["youpian"]="诱骗",
[":youpian"]="你可以指定一名角色，询问其是否愿意成为魔法少女。（如果选择同意，你失去一点体力；选择不同意，有50%几率什么都不发生，50%几率你获得“鼠疫”。）",
["youpianyes"]="你是否愿意成为魔法少女，按照圣经的教训与他同住，在神面前和她结为一体，爱她、安慰她、尊重她、保护他，像你爱自己一样。不论她生病或是健康、富有或贫穷，始终忠於她，直到离开世界?同意选此项",
["youpianno"]="你是否愿意成为魔法少女，按照圣经的教训与他同住，在神面前和她结为一体，爱她、安慰她、尊重她、保护他，像你爱自己一样。不论她生病或是健康、富有或贫穷，始终忠於她，直到离开世界?质疑选此项",

["shouji"]="收集",
["$shouji1"]="折木同学，有什么线索吗？",
["$shouji2"]="折木同学！一起来调查吧！我很好奇！",
[":shouji"]="出牌阶段限一次，你可以弃置X张牌，依次观看场上所有角色的手牌并选择一张获得之。 X为你的体力值+1。",
["tuhao"] = "土豪",
["$tuhao1"] = "（里志）奉太郎没听说过【千反田家族】的名号吗！",
["$tuhao2"] = "（里志）怎么样！够气派吧！（奉太郎）走吧，千反田她们还等着呢。",
[":tuhao"] = "锁定技。出牌阶段，每当你使用一张红色的牌，你摸一张牌；每当你使用一张黑色的牌，你须弃置你的任意区域内的一张牌。",

["yehuo"] = "夜祸",
[":yehuo"] = "锁定技。你的回合开始阶段，如果处于背面朝上，你翻过来行动,并于回合结束阶段翻回背面。回合外，每次被翻回正面，你当收到一点无来源的无属性伤害。",
["spring"] = "源头",
[":spring"] = "游戏开始阶段，你获得“鼠疫”，“鼠疫”对你无效，你无法获得“抗体”。每当你受到“鼠疫”持有角色伤害或对其造成伤害时，可以获得其所拥有的“鼠疫”，或者给予其自己所拥有的“鼠疫”，并防止此次伤害。不能无视抗体",
["spreadillness"] = "鼠疫",
[":spreadillness"] = "回合结束的时候，失去1点体力，与你距离为1的角色将以80%获得“鼠疫”，距离为2的角色将以50%获得“鼠疫”，持有者将以50%的几率失去“鼠疫”获得免疫。获得免疫者以50%失去“抗体”",
["@spreadDiscard"] = "为新的病原体而弃置一张牌。",
["$spreadillness1"] = "那么，比赛开始吧。",
["$spreadillness2"] = "没有哦。",
["$spreadillness3"] = "我的赐名是【黑死斑的魔王】，black parure哦。",
["$spreadillness4"] = "但已经太晚了，我已经让病原菌侵入了一部分参赛者体内。",
["$spring1"] = "很痛哦，不过 原谅你了。",
["$spring2"] = "也就是说，你们的性命就掌握在我手中。",
["lingti"] = "灵体",
[":lingti"] = "锁定技。你防止你的任何体力减少，每防止一次摸一张牌。",
["$lingti1"] = "大~丈~夫~",
["lolihime_xiaoshi"] = "消逝",
[":lolihime_xiaoshi"] = "游戏开始时，你的体力上限变为0，你获得X枚“灵体”标记。回合开始阶段开始时，你失去一个“灵体”标记；若你没有“灵体”标记，你立即死亡。X为游戏人数 + 5",
["$lolihime_xiaoshi1"] = "面麻...对自己已经死了这件事，还是知道的...",
["@Menma_turn"] = "灵体",
["SE_Xinyuan"] = "心愿",
["$SE_Xinyuan1"] = "这样子，真的好怀念，好开心。",
["$SE_Xinyuan2"] = "面麻的愿望...好像已经实现了...",
["$SE_Xinyuan3"] = "仁太，你又哭了吗？",
[":SE_Xinyuan"] = "弃牌阶段，当你的牌因弃置而置入弃牌堆时，你可以令任意其他角色摸等量的牌。",
["lolihime"] = "动漫包-萝莉姬",
["mianma"] = "本间芽衣子",
["#mianma"] = "面码",
["@mianma"] = "花名未闻",
["&mianma"] = "本间芽衣子",
["~mianma"] = "（仁太）一，二，（大家）找到面麻了！ （面麻）被大家找到...了...",
["cv:mianma"] = "茅野爱衣",
["designer:mianma"] = "帕秋莉·萝莉姬 & Sword Elucidator",

["qb"] = "QBキュゥべえ",
["&qb"] = "QB",
["~qb"] = "...",
["#qb"] = "魔法少女诱拐犯",
["cv:qb"] = "加藤英美里",
["designer:qb"] = "帕秋莉·萝莉姬",


["kuro"] = "佩丝特",
["$kuro"] = "佩丝特",
["@kuro"] = "问题儿都来自新世界",
["#kuro"] = "黑死病魔王",
["~kuro"] = "怎么会...我还没...",
["cv:kuro"] = "斋藤千和",
["designer:kuro"] = "帕秋莉·萝莉姬",


["jdd"] = "千反田爱瑠",
["&jdd"] = "千反田爱瑠",
["@jdd"] = "冰菓",
["#jdd"] = "我很好奇",
["~jdd"] = "太好了，让我想起来了...这样就能好好去送舅舅了...",
["designer:jdd"] = "帕秋莉·萝莉姬",
["cv:jdd"] = "佐藤聡美",
["illustrator:jdd"] = "",
}

--江之岛盾子 Junko／SE_Heimu 已由 extensions/dongmanbao.lua 提供，此處不重複定義

ruler = sgs.CreateTriggerSkillV2{
	name = "ruler",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	can_trigger = function(skill, event, room, player, data)
		local junko = room:findPlayerBySkillName("ruler")
		if junko then
			return "ruler", junko:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local junko = ctx.owner or player
		local target = ctx.invoker
		if not target then return false end
		if target:getHp()>junko:getHandcardNum() then
			room:broadcastSkillInvoke(skill:objectName())
			room:setPlayerProperty(target, "hp", sgs.QVariant(junko:getHandcardNum()))
		end
		return false
	end
}
addToSkills(ruler)
sgs.LoadTranslationTable{
["ruler"] = "绝望学园 规定『学级』",
["$ruler1"] = "绝望  是会传染的。",
["$ruler2"] = "是个人都会绝望。",
["$ruler3"] = "嗯，就是这么回事，将作为希望象征的希望峰学园内发生的互相残杀向世界直播这件事....正是人类绝望计划的高潮啊！！",
["$ruler4"] = "我只是单纯的在追求绝望而已，这之中并没有任何其他理由了，正因为没有理由，所以也无法找到对策，而无法应对无法理解的这份蛮横，这正是【超高校级绝望】啦！",
[":ruler"] = "锁定技。场上的所有角色在体力变动后，体力值调整为不多于你的手牌数。",
}

return Lolihime
