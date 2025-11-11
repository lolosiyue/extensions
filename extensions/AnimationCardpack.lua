module("extensions.AnimationCardpack",package.seeall)
extension = sgs.Package("AnimationCardpack", sgs.Package_CardPack)


function hasRemoved(player)
	if player:containsTrick("shuugakulyukou") then
		return true
	else
		return false
	end
end

function existSomeoneRemove(room)
	local players = room:getAlivePlayers()
	local exist = true
	for _, p in sgs.qlist(players) do
		if hasRemoved(p) then
			exist = true
			break
		end
	end
	return exist
end

    --黑桃--sgs.Card_Spade--♠
	sgs.Sanguosha:cloneCard("slash", sgs.Card_Spade, 2):setParent(extension)
	
	sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Spade, 4):setParent(extension)

	Elucidator = sgs.CreateWeapon{
		name = "Elucidator",
		class_name = "Elucidator",
		suit = sgs.Card_Spade,
		number = 6,
		range = 2,
		on_install = function(self, player) --装备时获得技能
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill then
				if skill:inherits("TriggerSkill") then
					local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
					room:getThread():addTriggerSkill(triggerskill)
				end
			end
			if string.find(player:getGeneralName(), "Kirito") or string.find(player:getGeneral2Name(), "Kirito") then
				room:handleAcquireDetachSkills(player, "-betacheater|htms_rishi")
			end
		end,
		on_uninstall = function(self, player) --卸下时移除技能
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill and skill:inherits("ViewAsSkill") then
				room:detachSkillFromPlayer(player, self:objectName(), true)
			end
			if string.find(player:getGeneralName(), "Kirito") or string.find(player:getGeneral2Name(), "Kirito") then
				room:handleAcquireDetachSkills(player, "-htms_rishi|betacheater")
			end
		end,
	}

	Elucidator_skill = sgs.CreateTriggerSkill{
	name = "Elucidator", --一般的话，技能的objectName()和武器的objectName()用一样的名字
	events = {sgs.Damage},
	can_trigger = function(self, target)
		return target and target:hasWeapon(self:objectName())
	end,
	global = true,
	on_trigger = function(self, event, player, data)
		local room, damage = player:getRoom(), data:toDamage()
		if damage.card and damage.from and damage.to and damage.card:isKindOf("Slash") then
			if room:askForSkillInvoke(player, self:objectName(), data)  then
				damage.to:drawCards(1)
				room:addPlayerMark(player, "Elu_do", 1)
				room:addPlayerMark(player, "&Elucidator-Clear", 1)
			end
		end
		return false
	end
}

	Elucidator_do = sgs.CreateTargetModSkill{
	name = "Elucidator_do",
	pattern = "Slash",
	residue_func = function(self,player)
		local n = player:getMark("Elu_do")
		if  player:getMark("Elu_do") ~= 0 then return n	
		else
			return 0
		end
	end
}

Elucidator_fu = sgs.CreateTriggerSkill{	--阐释者的全局效果
	name = "Elucidator_fu",
	events = {sgs.EventPhaseEnd},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish  then
			 for _, p in sgs.qlist(room:getAlivePlayers()) do
		p:loseAllMarks("Elu_do")
		end 	
		end
	end,
	can_trigger = function(self, target)
		return target 
	end
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
htms_rishi = sgs.CreateTriggerSkill{
	name = "htms_rishi",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
	local use = data:toCardUse()
		if  not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
				_data:setValue(p)
			if player:getHandcardNum() < p:getHandcardNum() and room:askForSkillInvoke(player, self:objectName(), _data) then
				jink_table[index] = 0
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
	end,
		can_trigger = function(self, target)
		return target 
		and target:isAlive() 
		and target:getMark("Equips_Nullified_to_Yourself") <= 0
	end
}
	Elucidator:setParent(extension)
	
	
	mouthgun = sgs.CreateTrickCard{
	name = "mouthgun",
	class_name = "mouthgun",
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 8,
	filter = function(self, targets, to_select, player)
		if player:isProhibited(to_select,self) then return end
	    return to_select:objectName() ~= player:objectName() and not to_select:isKongcheng() and player:distanceTo(to_select) <= math.max(1, player:getHp()) and #targets < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self) and player:canPindian(to_select)
	end,
 --    feasible = function(self, targets)
	-- 	return #targets == 1
	-- end,
	on_effect = function(self, effect)
		effect.from:drawCards(1)
		if effect.to:isKongcheng() or effect.from:isKongcheng() then return false end
		effect.from:pindian(effect.to, "mouthgun", nil)
	end,
}

mouthgun_result = sgs.CreateTriggerSkill{
	name = "mouthgun",
	events = {sgs.Pindian},
	frequency = sgs.Skill_Compulsory,
	global = true,
	on_trigger = function(self, event, player, data)
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local room = player:getRoom()
			local fromNumber = pindian.from_card:getNumber()
			local toNumber = pindian.to_card:getNumber()
			if fromNumber ~= toNumber then
				local winner, loser
				if fromNumber > toNumber then
					winner = pindian.from
					loser = pindian.to
				else
					winner = pindian.to
					loser = pindian.from
				end
				if  loser:isKongcheng() then					
						room:damage(sgs.DamageStruct("mouthgun_fail", winner, loser,1, sgs.DamageStruct_Normal))					
				end
				if not loser:isKongcheng() then	
					local choice = room:askForChoice(loser, self:objectName(), "mouthgun_fail+mouthgun_qp", data)
						if  choice == "mouthgun_fail" then
						room:damage(sgs.DamageStruct("mouthgun_fail", winner, loser,1, sgs.DamageStruct_Normal))
					else
						room:showAllCards(loser)
							end
				end
			end
		end
		return false
	end,
can_trigger = function(self, target)
	return true
end,
}
	mouthgun:setParent(extension)

chopper = sgs.CreateWeapon{
	name = "chopper",
	class_name = "chopper",
	suit = sgs.Card_Spade,
	number = 12,
	range = 3,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			end
		end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then
			room:detachSkillFromPlayer(player, self:objectName(), true)
		end
	end,
}

chopper_skill = sgs.CreateViewAsSkill{
    name = "chopper",
    n = 0,
    view_as = function(self, cards)
	    if #cards > 0 then return nil end
   		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
   		slash:setSkillName(self:objectName())
	   	slash:addSubcards(sgs.Self:getHandcards())
	    return slash
   	end,
    enabled_at_play = function(self, player)
	    return sgs.Slash_IsAvailable(player) and not player:isKongcheng()
    end,
	enabled_at_response = function(self, player, pattern)
	    if player:isKongcheng() then return false end
	return pattern == "slash"
	end,
}

chopper_skill_addtarget = sgs.CreateTargetModSkill{
	name = "#chopper_skill",
	pattern = "Slash", --据说这里要填类别名
	extra_target_func = function(self, poi, card)
		if poi:hasWeapon("chopper") and card:getSkillName() == "chopper" then
			local x = poi:getHandcardNum()
			return x - 1
		else
			return 0
		end
	end
}

chopper:setParent(extension)

together_go_die = sgs.CreateTrickCard{
	name = "together_go_die",
	class_name = "together_go_die",
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 13,
	available = true,
	filter = function(self, targets, to_select, player)
		if player:isProhibited(to_select,self) then return end
		return #targets < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self) 
		and to_select:objectName() ~= player:objectName() 
		and to_select:getHandcardNum() >= player:getHandcardNum() 
	end,
	-- feasible = function(self, targets)
	-- 	return #targets == 1
	-- end,
	on_use = function(self,room,source,targets)
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
	end,
	on_effect = function(self, effect)
		local from, to = effect.from, effect.to
		local room = from:getRoom()
		local n = from:getHandcardNum() + 1
		local prompt_list = {"@tgd-ask", from:objectName(), n}
		local prompt = table.concat(prompt_list, ":")
		local discard = room:askForDiscard(to, self:objectName(), n, n, true, true, prompt)
		if (not discard) then
			room:setPlayerFlag(to, "tgd_target")
			room:addPlayerMark(to, "@skill_invalidity")
			room:addPlayerMark(to, "&together_go_die+to+#"..from:objectName().."-Clear")
			room:setPlayerCardLimitation(to, "use,response", ".|.|.|hand", true)
			room:loseHp(from)
			from:drawCards(2, self:objectName())
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(p, p:getCards("he"), true)
			end
		end
		-- local current, requester, int = effect.to, effect.from, 1
		-- local prompt = string.format("#tgd-diacard:%s:%s", requester:objectName(), int)
		-- local card = room:askForExchange(current, self:objectName(), 999, int, true, prompt, true)
		-- while card --[[and int + card:subcardsLength() <= 5]] do
		-- 	room:throwCard(card, current)
		-- 	int = card:subcardsLength() + 1
		-- 	current, requester = requester, current
		-- 	prompt = string.format("#tgd-diacard:%s:%s", requester:objectName(), int)
		-- 	card = room:askForExchange(current, self:objectName(), 999, int, true, prompt, true)
		-- end
		-- room:damage(sgs.DamageStruct(self, effect.from, current))
	end,
}

tgd_clear = sgs.CreateTriggerSkill
{
	name = "tgd_clear",
	events = {sgs.EventPhaseChanging, sgs.Death},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to ~= sgs.Player_NotActive) then
				return false
			end
		elseif (event == sgs.Death) then
			local death = data:toDeath()
			if (death.who:objectName() ~= player or player:objectName() ~= room:getCurrent():objectName()) then
				return false
			end
		end
		local players = room:getAllPlayers()
		for _, p in sgs.qlist(players) do
			if (not p:hasFlag("tgd_target")) then continue end
			room:setPlayerFlag(p, "-tgd_target")
			for _, t in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(t, t:getCards("he"), true)
			end
			room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$1")
			room:removePlayerMark(p, "@skill_invalidity")
		end
        return false
    end,
	can_trigger = function(self, player)
		return player
	end
}

--[[(
ServerPlayer *player, 
const char *reason, 
int discard_num, 
int min_num,
bool include_equip = false, 
const char *prompt = NULL, 
bool optional = false, 
const char *pattern = ".")]]
	together_go_die:setParent(extension)
	--红桃--sgs.Card_Heart--♥
	
rotenburo = sgs.CreateTrickCard{
	name = "rotenburo",
	class_name = "rotenburo",
	subtype = "AOE",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
	target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Heart,
	number = 1,
	available = function(self, player)
	    return true
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		if source:getMark("spa") > 0 then
		    local x = source:getMark("spa")
		    source:drawCards(x)
			room:setPlayerMark(source, "spa", 0)
		end
	end,
	on_effect = function(self, effect)
		local poi, target = effect.from, effect.to
		local room = poi:getRoom()
		local choices = {"draw"}
		if target:isWounded() then
			table.insert(choices, "recover")
		end
		local newdata = sgs.QVariant()
		newdata:setValue(poi)
		local choice = room:askForChoice(target, "rotenburo", table.concat(choices, "+"), newdata)
		
--[[		if target:getAI() and #choices > 1 then
			local lost = target:getLostHp()
			if target:getHp() < (0.8 * lost) then
				choice = "recoverHP"
			--	target:speak(choice)
			else
				choice = choices[math.random(1, choices#)]
			end
		--	target:speak("rtbr_choice:"..choice)
		end]]
		
		if choice == "draw" then
			target:drawCards(1)
		else
			room:recover(target, sgs.RecoverStruct())
			room:addPlayerMark(poi, "spa", 1)
		end
	end,
}
	rotenburo:setParent(extension)
	
	strike_the_death = sgs.CreateTrickCard{
	name = "strike_the_death",
	class_name = "strike_the_death",
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = true,
	suit = sgs.Card_Heart,
	number = 2,
	available = false,
	about_to_use = function(self, room, use)
		if room:getCurrentDyingPlayer() then
			if room:getCurrentDyingPlayer():objectName() == use.from:objectName() and use.from:hasFlag("Global_Dying") and use.from:getHp() < 1 then
				self:cardOnUse(room, use)
			end
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, use.from:objectName(), self:objectName(), "")
			room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason)
			use.from:broadcastSkillInvoke("@recast")
			local log = sgs.LogMessage()
			log.type = "#UseCard_Recast"
			log.from = use.from
			log.card_str = use.card:toString()
			room:sendLog(log)
			use.from:drawCards(1, "recast")
		end
	end,
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local poi = effect.from
		local room = poi:getRoom()
		local current = room:getCurrent()
		local point = 1 - poi:getHp()
		local recover = sgs.RecoverStruct()
		recover.who = poi
		recover.recover = point
		room:recover(poi, recover)
		poi:drawCards(2 * point)
		local playerdata = sgs.QVariant()
		playerdata:setValue(poi)
		room:setTag("strikeInvoke", playerdata)
		room:addPlayerMark(poi, "@std", point)
		current:changePhase(current:getPhase(), sgs.Player_NotActive)
	--	room:setPlayerFlag(current, "Global_PlayPhaseTerminated")
	end,
}

	strike_the_death_effect_skill = sgs.CreateTriggerSkill{
	name = "strike_the_death" ,
	events = {sgs.EventPhaseStart, sgs.Dying, sgs.EventPhaseEnd, sgs.Death--[[, sgs.AskForPeachesDone--]],sgs.DamageCaused},
	priority = 3,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_NotActive then return false end
		    if room:getTag("strikeInvoke") then
			    local target = room:getTag("strikeInvoke"):toPlayer()
		    	
    			if target and target:isAlive() and not target:hasFlag("strike_the_death") then
	    			local phases = sgs.PhaseList()
		    		phases:append(sgs.Player_Play)
			    	local log = sgs.LogMessage()
					log.type = "#get_player-phase"
					log.from = target --:getGeneralName()
					log.arg = self:objectName()
					room:sendLog(log)
					room:setPlayerFlag(target, "strike_the_death")
					target:play(phases)
					room:setPlayerFlag(target, "-strike_the_death")
					room:removeTag("strikeInvoke")
				end
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and player:hasFlag("Global_Dying") and player:getHp() <= 0 then
			--	local card = room:askForUseCard(dying.who, "strike_the_death", "@strike_the_death", 1, sgs.Card_MethodUse)
				local card = room:askForUseCard(dying.who, "strike_the_death", string.format("@strike_the_death:%s", dying.who:objectName()))
			--[[	if not card then
					room:setPlayerFlag(dying.who, "no_need_to_strike")
				end]]--
			end
--[[		elseif event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if dying.who:hasFlag("no_need_to_strike") then
				room:setPlayerFlag(dying.who, "-no_need_to_strike")
			end]]--
		elseif event == sgs.EventPhaseEnd then
			if player:getMark("@std") >= 1 and player:getPhase() == sgs.Player_Play and player:isAlive() then
				local target = room:getTag("strikeInvoke"):toPlayer()
				if room:getTag("strikeInvoke") and target and target:objectName() == player:objectName() then 
					room:removeTag("strikeInvoke")
					local log = sgs.LogMessage()
					log.type = "#strike_the_death_failure"
					log.from = player
					room:sendLog(log)
					local killer = sgs.DamageStruct()
					killer.from = player
					room:killPlayer(player, killer)
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local killer
			if death.damage and death.damage.from then
				killer = death.damage.from
			else
				killer = nil
			end
			if killer and killer:getMark("@std") > 0 then
				room:setPlayerMark(killer, "@std", 0)
			    local log = sgs.LogMessage()
				log.type = "#strike_the_death_success"
				log.from = killer
				room:sendLog(log)
				room:removeTag("strikeInvoke")
			end
			return false
		elseif event == sgs.DamageCaused then
		   	local damage = data:toDamage()
			if damage.from then
			    local count = damage.from:getMark("@std")
			    if count > 0 then
				--	if gaokao_special then
				--		gaokao_Log(room, player, self)
						local msg = sgs.LogMessage()
						msg.type = "#strike_the_death"
						msg.from = damage.from
						msg.to:append(damage.to)
						msg.arg = string.format("%d", damage.damage)
						damage.damage = damage.damage + count
						msg.arg2 = string.format("%d", damage.damage)
						room:sendLog(msg)
						data:setValue(damage)
				--	end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end
}

	strike_the_death:setParent(extension)
	
	sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_Heart, 4):setParent(extension)

	sgs.Sanguosha:cloneCard("peach", sgs.Card_Heart, 6):setParent(extension)

	sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Heart, 9):setParent(extension)

	shuugakulyukou = sgs.CreateTrickCard{
	name = "shuugakulyukou",
	class_name = "shuugakulyukou",
	subtype = "delayed_trick",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Heart,
	number = 10,
	filter = function(self, targets, to_select, source)
		if source:isProhibited(to_select,self) then return end
		return #targets < 1 and not hasRemoved(to_select)
	end,
    feasible = function(self, targets)
	    return #targets == 1
    end,
	available = function(self, player)
	    return true
	end,
	is_cancelable = function(self, effect)
	    return true
	end,
	on_nullified = function(self, target)
	    local room = target:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, target:objectName())
	    room:throwCard(self, reason, nil)
	end,
	on_effect = function(self, effect)
		local poi = effect.to
		local room = poi:getRoom()
		local log = sgs.LogMessage()
		log.from = effect.to
		log.type = "#DelayedTrick"
		log.arg = self:objectName()
		room:sendLog(log)
		local judge = sgs.JudgeStruct()
		judge.who = poi
		judge.play_animation = true
		judge.pattern = ".|diamond|.|.|."
		judge.good = false
		judge.reason = self:objectName()
		room:judge(judge)
		if judge:isGood() then
		--	local other_players = room:getOtherPlayers(player)
		--	for _,p in sgs.qlist(other_players) do
		--		poi:speak(p:getSeat()..p:getGeneralName().."_"..sgs.Sanguosha:correctDistance(poi, p))
		--		poi:speak(p:getGeneralName().."_"..poi:distanceTo(p))
		--	end
			room:moveCardTo(self, poi, sgs.Player_PlaceDelayedTrick, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, poi:objectName(), self:objectName(), ""), true);
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, poi:objectName())
			room:throwCard(self, reason, nil)
		end
	end,
}

	shuugakulyukou:setParent(extension)

	shuugakulyukou_prohibit = sgs.CreateProhibitSkill{
	name = "shuugakulyukou_prohibit",
	is_prohibited = function(self, from, to, card)
		if to and from then
			if not hasRemoved(from) and hasRemoved(to) then
				return card:isKindOf("AOE")
			end
		end
	end,
}
	
	shuugakulyukou_distance = sgs.CreateDistanceSkill{
	name = "shuugakulyukou_distance",
	correct_func = function(self, from, to)
		local a = from:getMark("fake_seat")
		local b = to:getMark("fake_seat")
		if a * b == 0 then --标记真的可以是负数#（吐血）
			return 0
		else
			local ori_right = math.abs(from:getSeat() - to:getSeat())
			local ori_left = from:aliveCount() - ori_right
			local ori_dis = math.min(ori_left, ori_right)
			if a * b > 0 then
				local fake_count
				if hasRemoved(from) then
					fake_count = 0
				else
					fake_count = 1
				end
				for _,p in sgs.qlist(from:getAliveSiblings()) do
					if p:getMark("fake_seat") > 0 then
						fake_count = fake_count + 1
					end
				end
				if a + b < 0 then
					fake_count = from:aliveCount() - fake_count
				end
				local fake_right = math.abs(a - b)
				local fake_left = fake_count - fake_right
				local fake_dis = math.min(fake_right, fake_left)
				return (-ori_dis+fake_dis)
			else --a*b<0
				if gaokao_special then
					return 1
				else
					return 0
				end
			end
		end
	end
}

	shuugakulyukou_setmark = sgs.CreateTriggerSkill{
	name = "shuugakulyukou_setmark",
	events = {sgs.CardsMoveOneTime, sgs.Death},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can = false
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not move.from then return false end
			if move.from:objectName() ~= player:objectName() then return false end
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("shuugakulyukou") then
						if move.from_places:contains(sgs.Player_PlaceDelayedTrick) or move.to_place == sgs.Player_PlaceDelayedTrick then
							can = true
							break
						end
					end
				end
		elseif event == sgs.Death then
			if existSomeoneRemove(room) then
				can = true
			end
		end
		if can == true then
			local real_seat = 0
			local fake_seat = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if hasRemoved(p) then
					fake_seat = fake_seat - 1
					room:setPlayerMark(p, "fake_seat", fake_seat)
			--		p:speak("@fake_seat="..fake_seat)
				else
					real_seat = real_seat + 1
					room:setPlayerMark(p, "fake_seat", real_seat)
			--		p:speak("@fake_seat="..real_seat)
				end
			end
			if fake_seat == 0 then
				for _,t in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(t, "fake_seat", 0)
				end
			end
		end
	end
	}

    sgs.Sanguosha:cloneCard("jink", sgs.Card_Heart, 13):setParent(extension)
	
	--梅花--sgs.Card_Club--♣
	
	sgs.Sanguosha:cloneCard("nullification", sgs.Card_Club, 1):setParent(extension)
	
	Rho_Aias = sgs.CreateArmor{
		name = "Rho_Aias",
		class_name = "Rho_Aias",
		suit = sgs.Card_Club,
		number = 2,
		on_install = function(self, player)
			local room = player:getRoom()
			-- local triggerSkill = sgs.Sanguosha:getTriggerSkill("Rho_Aias")
			-- if (triggerSkill) then
			-- 	room:getThread():addTriggerSkill(triggerSkill)
			-- end
			local viewAsSkill = sgs.Sanguosha:getViewAsSkill("Rho_Aias")
			if (viewAsSkill) then
				room:attachSkillToPlayer(player, self:objectName())
			end
		end,
		on_uninstall = function(self, player)
			local room = player:getRoom()
			for _,card_id in sgs.qlist(player:getPile("ring")) do
					room:throwCard(card_id,player)
				end
			if (player:isAlive() and player:hasArmorEffect(self:objectName()) and not string.find(player:getFlags(), "_InTempMoving")) then
				player:setFlags("RhoAiasDetach")
			end
			local viewAsSkill = sgs.Sanguosha:getViewAsSkill("Rho_Aias")
			if (viewAsSkill) then
				room:detachSkillFromPlayer(player, self:objectName(), true)
			end			
		end
	}

	Rho_Aias_VS = sgs.CreateOneCardViewAsSkill
	{
		name = "Rho_Aias",
		expand_pile = "ring",
		-- filter_pattern = ".|.|.|ring",
		view_filter = function(self, card)
			return sgs.Sanguosha:matchExpPattern(".|.|.|ring", sgs.Self, card)
		end,
		enabled_at_play = function(self, player)
			return false
		end,
		enabled_at_response = function(self, player, pattern)
			return ((pattern == "jink") and (player:hasArmorEffect("Rho_Aias")) and #(player:getTag("Qinggang"):toStringList()) == 0)
		end,
		view_as = function(self, card)
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			jink:setSkillName("Rho_Aias")
			jink:addSubcard(card)
			return jink
		end
	}

	Rho_Aias_skill = sgs.CreateTriggerSkill
	{
		name = "Rho_Aias_trigger",
		events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
		-- view_as_skill = Rho_Aias_VS,
		global = true,
		on_trigger = function(self, event, player, data, room)
			if (event == sgs.CardsMoveOneTime) then
				local move = data:toMoveOneTime()
				if (not move.from or move.from:objectName() ~= player:objectName() or not move.from_places:contains(sgs.Player_PlaceEquip)) then
					return false
				end
				for i = 0, move.card_ids:length() - 1, 1 do
					if (move.from_places:at(i) ~= sgs.Player_PlaceEquip) then
						continue
					end
					local card = sgs.Sanguosha:getEngineCard(move.card_ids:at(i))
					if (card:objectName() == self:objectName()) then
						player:setFlags("-RhoAiasDetach")
						player:clearOnePrivatePile("ring")
						break
					end
				end
			else
				if (player:getPhase() == sgs.Player_Finish and player:hasArmorEffect("Rho_Aias")) then
					local skill = sgs.Sanguosha:getViewAsSkill("Rho_Aias")
					if (skill) then
						--player:speak("1")
						if (player:hasSkill(skill)) then
							--player:speak("2")
						end
					end
					local maxinum = 7 - player:getPile("ring"):length()
					if maxinum > 0 then
						local exchange = room:askForExchange(player, self:objectName(), maxinum, 1, false, "@rho_aias-put:"..maxinum, true)
						if (exchange) then
							local card_ids = exchange:getSubcards()
							player:addToPile("ring", card_ids)
						end
					end
				end
			end
		end,
		can_trigger = function(self, target)
			return target and target:isAlive()
		end
	}

--[[	Rho_Aias_card = sgs.CreateSkillCard{
	name = "Rho_Aias",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_effect = function(self, effect)
	end
}]]


--[[	Rho_Aias_VS = sgs.CreateViewAsSkill{
	name = "Rho_Aias",
	n = 7,
	response_pattern = "@@Rho_Aias",
	expand_pile = "Rho_Aias",
	view_filter = function(self, selected, to_select)
		return sgs.Sanguosha:matchExpPattern(".|.|.|Rho_Aias", sgs.Self, to_select)
	end,
	view_as = function(self, cards)
		if #cards ~= 0 and #cards >= sgs.Self:getMark("reduce") then
			local Rcard = Rho_Aias_card:clone()
			for _, acard in ipairs(cards) do
				Rcard:addSubcard(acard)
			end
			Rcard:setSkillName(self:objectName())
			return Rcard
		end
	end
}]]

--[[    Rho_Aias_skill = sgs.CreateTriggerSkill{
	    name = "Rho_Aias",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.DamageInflicted},
		global = true,
		view_as_skill = Rho_Aias_VS,
		on_trigger = function(self, event, player, data)
			local decrease =  player:getPile("Rho_Aias"):length()
			local m = 2 * (3 ^ 0.5)
			local reduce = math.floor(m - math.log(math.min(7, ((player:getHandcardNum() + player:getHp()) / 2))))
			local room = player:getRoom()
			local damage = data:toDamage()
			if decrease <= damage.damage or decrease <= reduce then
				room:sendCompulsoryTriggerLog(player, "Rho_Aias")
				player:clearOnePrivatePile("Rho_Aias")
				damage.damage = damage.damage - decrease
			else
				room:setPlayerMark(player, "reduce", reduce)
				local prompt_list = {"@Rho_Aias", reduce, damage.damage}
				local prompt = table.concat(prompt_list, ":")
				local card = room:askForUseCard(player, "@@Rho_Aias!", prompt, -1, sgs.Card_MethodResponse)
				if card then
					local lessening = card:subcardsLength()
					damage.damage = damage.damage - lessening

					if gaokao_special then
						gaokao_Log(room, player, self)
					    player:obtainCard(card)
					else
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), self:objectName(), "")
						room:throwCard(card, reason, nil)
					end

				end
			end
			data:setValue(damage)
			if damage.damage <= 0 then return true end
		end,
		can_trigger = function(self,target)
			return target and target:isAlive() and target:hasArmorEffect("Rho_Aias") and target:getPile("Rho_Aias"):length() > 0
		end
	}]]

    Rho_Aias:setParent(extension)

	sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Club, 6):setParent(extension)
	
	local mouthgun1 = mouthgun:clone()
    mouthgun1:setParent(extension)
    mouthgun1:setNumber(10)
    mouthgun1:setSuit(sgs.Card_Club)
	
	
	
	local strike_the_death1 = strike_the_death:clone()
	strike_the_death1:setParent(extension)
	strike_the_death1:setNumber(12)
	strike_the_death1:setSuit(sgs.Card_Club)
	
	
	--方片--3--♦
	local mouthgun2 = mouthgun:clone()
    mouthgun2:setParent(extension)
    mouthgun2:setNumber(1)
    mouthgun2:setSuit(3)
	
    kotatsu = sgs.CreateTreasure{
    name = "kotatsu",
	class_name = "kotatsu",
	suit = 3,
	number = 3,
	on_install = function(self, player) --装备时获得技能
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill then
			if skill:inherits("TriggerSkill") then
				local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
				room:getThread():addTriggerSkill(triggerskill)
			end
		end
	end,
	}

	kotatsu_vs = sgs.CreateOneCardViewAsSkill {
		name = "kotatsu",
		filter_pattern = ".|red|.|hand",
		response_pattern = "@@kotatsu",
		view_as = function(slef, card)
			local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
			peach:addSubcard(card)
			peach:setSkillName("kotatsu")
			return peach
		end,
	}

	kotatsu_skill = sgs.CreateTriggerSkill{
	name = "kotatsu",
	events = {sgs.CardFinished, sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	view_as_skill = kotatsu_vs,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local x = math.max(1, player:getLostHp())
			if player:getPhase() == sgs.Player_Finish then
				if not player:hasTreasure("kotatsu") then return false end
				if player:getMark(self:objectName()) <= x and player:isWounded() and not player:isKongcheng() then
					local peach = room:askForUseCard(player, "@@kotatsu", "@kotatsu-peach")
					if peach and Winter_mode then
						local msg = sgs.LogMessage()
						msg.from = player
						if Winter_Solstice then
							msg.type = "#Winter_Solstice"
							room:drawCards(player, 2, self:objectName())
						else
							msg.type = "#Winter_mode"
							room:drawCards(player, 1, self:objectName())
						end
						room:sendLog(msg)
					end
					room:setPlayerMark(player, self:objectName(), 0)
				end
			elseif player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		else
			local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() or player:getPhase() ~= sgs.Player_Play or use.card:isKindOf("SkillCard") then return false end
			room:addPlayerMark(player, self:objectName(), 1)
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

--	kotatsu:setParent(extension) 2017.12.09-19:14:45

	sgs.Sanguosha:cloneCard("analeptic", 3, 4):setParent(extension)
	
    local shuugakulyukou1 = shuugakulyukou:clone()
	shuugakulyukou1:setParent(extension)
	shuugakulyukou1:setNumber(6)
	shuugakulyukou1:setSuit(3)

    local together_go_die1 = together_go_die:clone()
	together_go_die1:setParent(extension)
	together_go_die1:setNumber(7)
	together_go_die1:setSuit(3)

	sgs.Sanguosha:cloneCard("jink", 3, 10):setParent(extension)
	
function arrangementMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "arrangement", ""))
		move.to_pile_name = "&arrangement"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getPlayers()
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "arrangement", ""))
		move.from_pile_name = "&arrangement"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getPlayers()
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end
	
	
    bunkasai = sgs.CreateTrickCard{
	name = "bunkasai",
	class_name = "bunkasai",
	subtype = "global_effect",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
	target_fixed = true,
	can_recast = false,
	suit = 3,
	number = 13,
	available = function(self, player)
	    return true
	end,
	is_cancelable = function(self, effect)
	    return true
	end,
	on_use = function(self, room, source, targets)
		room:setTag("bunkasai", ToData(self))
	    for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
        local marks = {}
		for _, t in ipairs(targets) do
		    local count = t:getMark("arrange")
			if count == 0 then continue end
		    table.insert(marks, count)
		end
		for _, t in ipairs(targets) do
			if t:getMark("arrange") == math.max(table.unpack(marks)) then
				t:drawCards(1)
			end
			if t:getMark("arrange") == math.min(table.unpack(marks)) then
			    room:damage(sgs.DamageStruct(self, source, t))
			end
			room:setPlayerMark(t, "arrange", 0)
		end
		room:removeTag("bunkasai")
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
        local card = room:askForExchange(effect.to, self:objectName(), 4, 1, false, "bunkasai_arrange", true)
		if card then
		local ids = card:getSubcards()
		local suits = {}
		room:setPlayerMark(effect.to, "arrange", 2)
        for _,id in sgs.qlist(ids) do
            local acard = sgs.Sanguosha:getCard(id)
			if not table.contains(suits, acard:getSuit()) then
				table.insert(suits, id)
				room:addPlayerMark(effect.to, "arrange", 1)
			end
		end
		arrangementMove(ids, false, effect.to)
		else
		    room:setPlayerMark(effect.to, "arrange", 1)
		end
	end
}

bunkasai:setParent(extension)
 local bunkasai1 = bunkasai:clone()
	bunkasai1:setParent(extension)
	bunkasai1:setNumber(11)
	bunkasai1:setSuit(1)
if gaokao_special then
	heikeji_test = sgs.CreateTreasure{
	name = "heikeji_test",
	class_name = "heikeji_test",
	suit = 4,
	number = 16,
	on_install = function(self, player) --装备时获得技能
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			end
		end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then
			room:detachSkillFromPlayer(player, self:objectName(), true)
		end
	end,
}

	heikeji_test_card = sgs.CreateSkillCard{
		name = "heikeji_test_card",
		will_throw = false,
		handling_method = sgs.Card_MethodNone,
		filter = function(self, targets, to_select)
			local card = sgs.Self:getTag("heikeji_test"):toCard()
			card:addSubcard(self:getSubcards():first())
			card:setSkillName(self:objectName())
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) 
				and not sgs.Self:isProhibited(to_select, card, qtargets)
		end,
		feasible = function(self, targets)
			local card = sgs.Self:getTag("heikeji_test"):toCard()
			card:addSubcard(self:getSubcards():first())
			card:setSkillName(self:objectName())
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			if card and card:canRecast() and #targets == 0 then
				return false
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		end,	
		on_validate = function(self, card_use)
			local xunyou = card_use.from
			local room = xunyou:getRoom()
			local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
			use_card:addSubcard(self:getSubcards():first())
			use_card:setSkillName(self:objectName())
			local available = true
			for _,p in sgs.qlist(card_use.to) do
				if xunyou:isProhibited(p,use_card)	then
					available = false
					break
				end
			end
			available = available and use_card:isAvailable(xunyou)
			if not available then return nil end
			return use_card		
		end,
	}


heikeji_test_skill = sgs.CreateTriggerSkill{
	name = "heikeji_test_skill",
	events = {sgs.EventPhaseStart, sgs.CardFinished},
	global = true,
	view_as_skill = heikeji_test_vs_skill,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:loseHp(player)
				local standrad = {"god_salvation", "amazing_grace", "savage_assault", "archery_attack", "collateral", "dismantlement", "snatch", "ex_nihilo", "duel", "iron_chain", "fire_attack", "mouthgun", "rotenburo", "bunkasai", "fall_back_in_disorder"}
				local choices = {}
				local trick1 = standrad[math.random(1,#standrad)]
				table.removeOne(standrad, trick1)
				table.insert(choices, trick1)
				local trick2 = standrad[math.random(1,#standrad - 1)]
				table.removeOne(standrad, trick2)
				table.insert(choices, trick2)
				local trick3 = standrad[math.random(1,#standrad - 2)]
				table.removeOne(standrad, trick3)
				table.insert(choices, trick3)
				room:setPlayerProperty(player, "allowed_guhuo_dialog_buttons", sgs.QVariant(table.concat(choices, "+")))
				player:speak(table.concat(choices, "+"))
				room:setPlayerFlag(player, "ban_heikeji")
			else
		--		room:setPlayerFlag(player, "ban_heikeji")
			end
		else
			local use = data:toCardUse()
			if use.card:getSkillName() == "heikeji_test_card" then
				room:setPlayerFlag(player, "-ban_heikeji")
				room:setPlayerProperty(player, "allowed_guhuo_dialog_buttons", sgs.QVariant())
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive() and target:hasTreasure("heikeji_test") and target:getPhase() == sgs.Player_Play
	end
}


heikeji_test_vs_skill = sgs.CreateOneCardViewAsSkill{
	name = "heikeji_test",
	filter_pattern = "TrickCard",
	view_as = function(self, card)
		local c = sgs.Self:getTag("heikeji_test"):toCard()
		if c then
			local acard = heikeji_test_card:clone()
			acard:setUserString(c:objectName())	
			acard:addSubcard(card)
			return acard
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:hasFlag("ban_heikeji")
	end,
}
heikeji_test_vs_skill:setGuhuoDialog("r")

	
	oni = sgs.CreateBasicCard{
	name = "oni",
	class_name = "oni",
	number = 0,
	subtype = "disgusting_card",
	available = true,
	can_recast = false,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			if not source:isProhibited(target, self) then
				room:cardEffect(self, source, target)
			end
		end
	end,
	on_effect = function(self, effect)
		local poi = effect.from
		local room = poi:getRoom()
		local target = effect.to
		target:obtainCard(self)
		if target:isKongcheng() then return false end
		if target:objectName() == poi:objectName() then
		    room:throwCard(self, poi)
		else
			local id = room:askForCardChosen(poi, target, "h", self:objectName())
			room:obtainCard(poi, id)
			target:speak("有毒....")
		end
	end,
}

heikeji_test:setParent(extension)

	oni:setParent(extension)
	oni:setSuit(4)
	
	local oni1 = oni:clone()
    oni1:setParent(extension)
    oni1:setNumber(16)
    oni1:setSuit(5)
end
--村雨

extension_mancard = sgs.Package("AnimationCardpack_card", sgs.Package_CardPack)

Murasame = sgs.CreateWeapon{
	name = "Murasame",
	class_name = "Murasame",
	suit = sgs.Card_Spade,
	number = 13,
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Murasame")
		room:getThread():addTriggerSkill(skill)
	end,
}
MurasameSkill = sgs.CreateTriggerSkill{
	name = "Murasame",
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		local damage = data:toDamage()
		if event == sgs.TargetSpecified then
			if player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then return end
			for _,pl in sgs.qlist(room:getAllPlayers()) do pl:setFlags("-murasamedone") end
			if not player:hasWeapon("Murasame") then return end
			for _,p in sgs.qlist(use.to) do
				local dest = sgs.QVariant()
				dest:setValue(p)
				if room:askForSkillInvoke(player, "Murasame", dest) then	
					if use.card:isRed()  then
						local id = room:askForCard(p, ".|red|.|hand", "@murasamekilla", data, sgs.CardDiscarded)
						if id and use.card:sameColorWith(id) then
							local list = use.nullified_list
							for _,to in sgs.list(use.to)do
								table.insert(list,to:objectName())
							end
							use.nullified_list = list
							data:setValue(use)
						else
							p:setFlags("murasamedone")
						end
					
					elseif use.card:isBlack()  then
						local id = room:askForCard(p, ".|black|.|hand", "@murasamekillb", data, sgs.CardDiscarded)
						if id and use.card:sameColorWith(id) then
							local list = use.nullified_list
							for _,to in sgs.list(use.to)do
								table.insert(list,to:objectName())
							end
							use.nullified_list = list
							data:setValue(use)
						else
							p:setFlags("murasamedone")
						end
					else
						local id = room:askForCard(p, ".|.|.|hand", "@murasamekillc", data, sgs.CardDiscarded)
						if id  then
							local list = use.nullified_list
							for _,to in sgs.list(use.to)do
								table.insert(list,to:objectName())
							end
 							use.nullified_list = list
							data:setValue(use)					
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			if damage.chain or damage.transfer then return false end
			if damage.to:isAlive() and damage.to:hasFlag("murasamedone") then
				damage.to:setFlags("-murasamedone")
				if player:hasWeapon("Murasame") and damage.card and damage.card:isKindOf("Slash") then
					local choice = room:askForChoice(damage.to, "Murasame", "murasamelshp+murasamelsmhp", data)
					if choice == "murasamelshp" then
						room:loseHp(damage.to, damage.to:getHp())
					elseif choice == "murasamelsmhp" then
						room:loseMaxHp(damage.to)
					end
				end
			end
		elseif event == sgs.CardUsed then
			if player:hasWeapon("Murasame") and use.card and use.card:isKindOf("Slash") then
				if not (string.find(player:getGeneralName(), "Akame") or string.find(player:getGeneral2Name(), "Akame")
						or string.find(player:getGeneralName(), "chitong") or string.find(player:getGeneral2Name(), "chitong")) then
					if not room:askForCard(player, ".", "@murasameself", sgs.QVariant(), sgs.CardDiscarded) then
						room:loseHp(player)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


tywz = sgs.CreateWeapon{
	name = "tywz",
	class_name = "tywz",
	suit = sgs.Card_Spade,	--花色点数
	number = 10,
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("tywz")
		room:getThread():addTriggerSkill(skill)
	
	end,
}

tywzSkill = sgs.CreateTriggerSkill{
	name = "tywz", 
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then		
			if room:askForSkillInvoke(player, "tywz", data) then		
					damage.to:gainMark("@hurt")
					room:addPlayerMark(damage.to, "tywz")
				
			end		
		end
	end,
	can_trigger = function(self, target)
		return target 
		and target:isAlive() 
		and target:hasWeapon(self:objectName()) 
		and target:getMark("Equips_Nullified_to_Yourself") <= 0
	end
		
}

hqiangwei = sgs.CreateWeapon{
	name = "hqiangwei",
	class_name = "hqiangwei",
	suit = sgs.Card_Spade,	--花色点数
	number = 11,
	range = 3,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("hqiangwei")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@hurt") > 0 then
				p:loseAllMarks("@hurt")
				room:setPlayerMark(p, "tywz", 0)	--移除桐一文字的隐藏标记
			end
		end
	end,
}
hqiangweiSkill = sgs.CreateTriggerSkill{
	name = "hqiangwei",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.to and damage.to:isAlive() then
		if not player:isKongcheng() then
			local dest = sgs.QVariant()
			dest:setValue(damage.to)
			player:setTag("hqiangwei", dest)
		 if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "hqiangweiSkill") then		 
				damage.to:gainMark("@hurt")	
		end
		player:removeTag("hqiangwei")
		end
		end
	end,
	can_trigger = function(self, target)
		return target 
		and target:isAlive() 
		and target:hasWeapon(self:objectName()) 
		and target:getMark("Equips_Nullified_to_Yourself") <= 0
	end
}

fushang = sgs.CreateTriggerSkill{	--“负伤”标记的全局效果
	name = "fushang",
	events = {sgs.HpChanged, sgs.MaxHpChanged, sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local poi = player:getMark("@hurt")
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local x = player:getMark("tywz")
				if x > 0 then
					room:setPlayerMark(player, "tywz", 0)
					player:loseMark("@hurt", x)	--去除桐一文字的“负伤”
				end
			end
		else
			if player:getLostHp() < poi then
				room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp() - poi))
				if player:getHp() <= 0 then
					room:enterDying(player, nil)	--进入濒死结算，不知道是不是这样写，问下饺神吧
				end 								--t:我记得是setProperty的hp为0然后enterDying
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@hurt") > 0
	end
}


local skills = sgs.SkillList() 

Murasame:setParent(extension_mancard)
tywz:setParent(extension_mancard)
hqiangwei:setParent(extension_mancard)
	--[[0->2->1->3->0
	<<Suit>>
	0-->Blade
	1-->Club
	2-->Heart
	3-->Diomand
	4-->Black
	5-->Red
	others-->NoSuit
	<<number>>
	0-->"-"
	16-->"+"
	--]]
	
sgs.LoadTranslationTable{
	["AnimationCardpack"] = "漫杀の卡牌包",
    ["AnimationCardpack_card"] = "漫杀の卡牌包",
	["Elucidator"] = "阐释者",
    [":Elucidator"] = "装备牌·武器\
	<b>攻击范围</b>：2\
	<b>武器技能</b>：当你使用【杀】对一名角色造成伤害时，你可以令其摸一张牌，然后你此回合使用杀的次数上限+1。<font color=\"blue\"><b>联动技，</b></font>若你为桐人，则：你失去“封弊者”并获得“日蚀”；你失去装备区内的【阐释者】时，你失去“日蚀”，获得“封弊者”。\
（日蚀：你使用【杀】时，目标手牌数大于你手牌数你可弃置一张手牌，则此【杀】无法被闪避。）",

	["shuugakulyukou"] = "修学旅行",
    [":shuugakulyukou"] = "延时锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：一名角色\
    <b>效果</b>：将此牌置于该角色判定区内，判定阶段进行判定：若不为<font color=\"red\"><b>♦</b></font>，将此牌继续置于该角色的判定区内；若为<font color=\"red\"><b>♦</b></font>，将此牌置于弃牌堆。<font color=\"blue\"><b>锁定技，</b></font>判定区内有【修学旅行】的角色：1.不计入其余角色的距离计算；2.不能成为其余角色AOE的目标。\
    ◆其余角色：所有判定区内没有【修学旅行】的角色\
    ◆A不计入B距离计算：A之间计算距离时，视为B不存在；B之间计算距离时，视为A不存在。",

    ["shuugakulyukou_prohibit"] = "修学旅行",
    ["rotenburo"] = "露天温泉",
	[":rotenburo"] = "锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：所有角色\
    <b>效果</b>：所有角色依次选择一项：回复一点体力，或摸一张牌，然后你摸X张牌（X为以此法回复体力的角色数）",
	["rotenburo:recover"] = "回复一点体力",
	["rotenburo:drawncards"] = "摸一张牌",
	
	["chopper"] = "柴刀",
	[":chopper"] = "装备牌·武器\
	<b>攻击范围</b>：3\
	<b>武器技能</b>：你可以将所有手牌当做【杀】使用或打出；<font color=\"blue\"><b>锁定技，</b></font>你以此法使用【杀】可以选择至多X名目标（X为你的手牌数）。",
	
	["bunkasai"] = "文化祭",
	[":bunkasai"] = "锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：所有角色\
    <b>效果</b>：目标角色依次选择展示0~4张手牌，然后展示牌中花色最多的角色摸一张牌，最少的角色受到一点伤害。",
	["arrangement"] = "展示",
	["bunkasai_arrange"] = "请展示0~4张手牌\
	来源：【文化祭】出牌阶段，对所有角色使用，目标角色依次选择展示0~4张手牌，然后展示牌中花色最多的角色摸一张牌，最少的角色受到一点伤害。",
	
	["mouthgun"] = "阵前嘴炮",
	[":mouthgun"] = "锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：距离X的一名有手牌的其他角色（X为你的体力值且至少为1）\
    <b>效果</b>：你摸一张牌，然后你与目标角色拼点，然后拼点输的角色选择一项：受到一点伤害，或展示所有手牌。",
	["mouthgun_fail"] = "受到一点伤害",
	["mouthgun_qp"] = "展示手牌",	
	
	["Rho_Aias"] = "炽天覆七重圆环",
	[":Rho_Aias"] = "装备牌·防具\
	<b>防具技能</b>：结束阶段，你可以将至少一张手牌置于武将牌上（称为“环”，且至多7张）；你可以把一张“环” 当作【闪】使用或打出；当你失去装备区里的【炽天覆七重圆环】时，你将所有“环”置入弃牌堆。",
	["@rho_aias-put"] = "你可以将1~%src张手牌置为“环”\
	来源：炽天覆七重圆环",
	-- ["@Rho_Aias"] = "请至少选择 %src 张牌，令此伤害至少 - %src （共 %dest 点）",
	-- ["~Rho_Aias"] = "每<font color=\"yellow\"><b>多</b></font>选择一张牌，伤害值便-1",
	["ring"] = "环",
	
	["strike_the_death"] = "死亡逃杀",
	[":strike_the_death"] = "锦囊牌\
	<b>时机</b>：你进入濒死状态时\
    <b>目标</b>：你\
    <b>效果</b>：你回复体力至1，摸2X张牌，结束当前回合，暂停结算，然后你进行一个额外的出牌阶段：\
            1.你于此阶段造成伤害+X直到你杀死一名角色；\
            2.若你未于此阶段结束前杀死一名角色，你死亡。（X为你以此法回复的体力）\
    <b>重铸</b>：将此牌置入弃牌堆并摸一张牌。",
	["#get_player-phase"] = "由于【%arg】的效果， %from 将执行一个额外的出牌阶段",
	["#strike_the_death_failure"] = "%from 逃杀失败，自刎而死",
	["#strike_the_death_success"] = "%from 绝地反击，逃过追杀",
	["@strike_the_death"] = "你正处于濒死状态，是否使用【死亡逃杀】？",
	["@std"] = "死亡逃杀",
	["#strike_the_death"] = "由于 %from 正在【<font color=\"yellow\"><b>死亡逃杀</b></font>】，%to 受到的伤害从 %arg 增加至 %arg2",
	
	["kotatsu"] = "被炉",
	[":kotatsu"] = "装备牌·宝物\
	<b>宝物技能</b>：<font color=\"blue\"><b>锁定技，</b></font>结束阶段，若你跳过了出牌阶段或于出牌阶段使用的牌数不超过X，你可以把一张红色手牌当【桃】使用。（X为你已损失的体力值且至少为1）",
	["@kotatsu-peach"] = "【被炉】被触发，是否把一张红色手牌当【桃】使用？",
	["~kotatsu"] = "请选择一张红色手牌",

	["together_go_die"] = "同归于尽",
	[":together_go_die"] = "锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：一名手牌数不小于你的其他角色\
    <b>效果</b>：你令其选择一项：1.弃置X张牌；2.你失去1点体力，摸两张牌，其所有非锁定技无效且不能使用或打出手牌直到本回合结束。（X为你与目标角色的手牌数之差）",
    --["#tgd-diacard"] = "你可以至少弃置%dest张牌并让%src也进行此选择或选择受到伤害（点取消）",
    ["@tgd-ask"] = "%src 对你使用了【同归于尽】，你须弃置 %dest 张牌，否则 %src 失去1点体力并摸两张牌且令你所有非锁定技无效且不能使用或打出手牌直到本回合结束",

    --["rishi"] = "日蚀",
    --[":rishi"] = "你使用【杀】对一名角色造成伤害后，你可以弃置一张牌，然后对与其距离1的一名其他角色造成1点伤害。",
    --["#rishi_dis"] = "你可以弃置一张牌以发动【日蚀】（包括装备）",
    --["#rishi_chosen"] = "请选择一名角色\
    --技能来源：日蚀",
	 ["htms_rishi"] = "日蚀",
    [":htms_rishi"] = "你使用【杀】时，若目标手牌数大于你手牌数，你可令此【杀】无法被闪避。",
	["Murasame"] = "村雨",
	[":Murasame"] = "装备牌·武器\
	<b>攻击范围</b>：２\
	<b>武器技能</b>：①当你使用【杀】指定目标角色后，你可以令其选择是否弃置一张手牌：\
	若其弃置的牌与此【杀】颜色相同，则此【杀】对其无效；\
	若颜色不同或不弃置，则当此【杀】造成伤害时，目标角色选择一项：失去当前所有体力值，或减少一点体力上限。\
	②<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】时，若你不是“赤瞳”，你须弃置一张手牌或失去一点体力。",
	["murasamelshp"] = "失去所有体力",
	["murasamelsmhp"] = "减少体力上限",
	["@murasamekilla"] = "弃置一张红色的手牌令此【杀】对你无效，否则你将可能受到极大创伤",
	["@murasamekillb"] = "弃置一张黑色的手牌令此【杀】对你无效，否则你将可能受到极大创伤",
	["@murasamekillc"] = "弃置一张手牌令此【杀】对你无效，否则你将可能受到极大创伤",
	["@murasameself"] = "你不是“赤瞳”，须弃置一张手牌或失去一点体力",

	["tywz"] = "桐一文字",
	[":tywz"] = "装备牌·武器\
	<b>攻击范围</b>：２\
	<b>武器技能</b>：当你使用【杀】造成伤害时，你可以令目标角色获得一枚“负伤”直到其下回合结束。<br/><br/><b>负伤:锁定技，你的已损失体力至少为X，X为标记数量。<b>",
	["@tywz-ask"] = "你可以弃置一张手牌令 %src 获得一枚“负伤”",

	["hqiangwei"] = "黄蔷薇",
	[":hqiangwei"] = "装备牌·武器\
	<b>攻击范围</b>：３\
	<b>武器技能</b>：当你使用【杀】造成伤害时，你可弃置一张牌令目标角色获得一枚“负伤”；当此装备离开装备区时，清除所有角色的“负伤”。<br/><br/><b>负伤:锁定技，你的已损失体力至少为X，X为标记数量。<b>",
	["hqiangweiSkill"] = "你可以弃置一张手牌发动黄蔷薇，令其获得一枚“负伤”",
	["@hurt"] = "负伤",
}

	if not sgs.Sanguosha:getSkill("Elucidator") then skills:append(Elucidator_skill) end
	if not sgs.Sanguosha:getSkill("Elucidator_do") then skills:append(Elucidator_do) end
	if not sgs.Sanguosha:getSkill("htms_rishi") then skills:append(htms_rishi) end
	if not sgs.Sanguosha:getSkill("chopper") then skills:append(chopper_skill) end
	if not sgs.Sanguosha:getSkill("#chopper_skill") then skills:append(chopper_skill_addtarget) end
	if not sgs.Sanguosha:getSkill("mouthgun") then skills:append(mouthgun_result) end
	if not sgs.Sanguosha:getSkill("Rho_Aias") then skills:append(Rho_Aias_VS) end
	if not sgs.Sanguosha:getSkill("Rho_Aias_trigger") then skills:append(Rho_Aias_skill) end
	if not sgs.Sanguosha:getSkill("strike_the_death") then skills:append(strike_the_death_effect_skill) end
	if not sgs.Sanguosha:getSkill("kotatsu") then skills:append(kotatsu_skill) end
	if not sgs.Sanguosha:getSkill("shuugakulyukou_prohibit") then skills:append(shuugakulyukou_prohibit) end
	if not sgs.Sanguosha:getSkill("shuugakulyukou_distance") then skills:append(shuugakulyukou_distance) end
	if not sgs.Sanguosha:getSkill("shuugakulyukou_setmark") then skills:append(shuugakulyukou_setmark) end
	if not sgs.Sanguosha:getSkill("Murasame") then skills:append(MurasameSkill) end
	if not sgs.Sanguosha:getSkill("tywz") then skills:append(tywzSkill) end
	if not sgs.Sanguosha:getSkill("tgd_clear") then skills:append(tgd_clear) end
	if not sgs.Sanguosha:getSkill("hqiangwei") then skills:append(hqiangweiSkill) end
	if not sgs.Sanguosha:getSkill("fushang") then skills:append(fushang) end
	if not sgs.Sanguosha:getSkill("Elucidator_fu") then skills:append(Elucidator_fu) end

	sgs.Sanguosha:addSkills(skills)

return {extension, extension_mancard} 