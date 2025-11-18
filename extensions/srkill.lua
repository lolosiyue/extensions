extension = sgs.Package("srkill", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
	["srkill"] = "极略三国SR包",	
}
--技能选择，公共技能
choose = sgs.CreateTriggerSkill{
	name = "#choose",
	priority = 6,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		local choices = {}
		local general1 = player:getGeneral()
		if general1:hasSkill(self:objectName()) then	
			local skills = general1:getVisibleSkillList()
			for _,sk in sgs.qlist(skills) do
				if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() and not sk:isLordSkill() then
					table.insert(choices, "lose"..sk:objectName())
				end
			end
			local choice = room:askForChoice(player,"lose_a_sk",table.concat(choices, "+"),data)			
			local skill = string.sub(choice,5)
			room:handleAcquireDetachSkills(player,"-"..skill)
			for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
				room:handleAcquireDetachSkills(player,"-"..ski:objectName())
			end
		end			
		if player:getGeneral2() then
			local choices = {}
			local general2 = player:getGeneral2()
			if general2:hasSkill(self:objectName()) then	
				local skills = general2:getVisibleSkillList()
				for _,sk in sgs.qlist(skills) do
					if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() and not sk:isLordSkill() then
						table.insert(choices, "lose"..sk:objectName())
					end
				end
			end
			local choice = room:askForChoice(player,self:objectName(),table.concat(choices, "+"),data)
			local skill = string.sub(choice,5)
			room:handleAcquireDetachSkills(player,"-"..skill)
			for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
				room:handleAcquireDetachSkills(player,"-"..ski:objectName())
			end
		end
		return false
	end
}


--【极武】专用
jiwu_extargetCard = sgs.CreateSkillCard{
	name = "jiwu_extarget",
	filter = function(self, targets, to_select)
		return to_select:getMark("jiwu_nil") == 0 and sgs.Self:getSeat() ~= to_select:getSeat() and #targets < 2
	end,
	on_use = function(self, room, source, targets)
		for i = 1, #targets do
		    targets[i]:setMark("jiwu_target", 1)
		end
	end
}

jiwu_extarget = sgs.CreateZeroCardViewAsSkill{
	name = "jiwu_extarget",
	response_pattern = "@@jiwu_extarget",
	view_as = function()
		return jiwu_extargetCard:clone()
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#choose") then skills:append(choose) end
if not sgs.Sanguosha:getSkill("jiwu_extarget") then skills:append(jiwu_extarget) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["#choose"] = "技能选择",
	["lose_a_sk"] = "请选择失去的技能",
	["@jiwu_extraslashtarget"] = "请选择【极武】的额外目标",
	["~jiwu_extarget"] = "选择一名可成为此【杀】的目标的角色→点击确定",
	["jiwu_extarget"] = "极武",
}

--SR刘备
sr_liubei = sgs.General(extension,"sr_liubei$","shu",4)

sr_rende = sgs.CreateTriggerSkill{
	name = "sr_rende",
	events = {sgs.EventPhaseEnd},
	--view_as_skill = sr_rendeVS,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		
		for _, liubei in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local cards = sgs.IntList()
			for _,card in sgs.qlist(liubei:getHandcards()) do
				cards:append(card:getId())
			end
			local list = sgs.SPlayerList()
			list:append(player)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, liubei:objectName(), "", 
				"sr_rende", "")
			if not liubei:askForSkillInvoke(self:objectName(),data)	then return false end	
			room:broadcastSkillInvoke("sr_rende")		
			if player:objectName()~=liubei:objectName() and not liubei:isKongcheng() then
				room:askForYiji(liubei, cards, self:objectName(),false,false,true,-1,list,
					reason,"#sr_rende:"..player:objectName(),true)
			end 
			room:notifySkillInvoked(liubei, "sr_rende")
			local phase = player:getPhase()			
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player,"phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart,room,player) then			
				thread:trigger(sgs.EventPhaseProceeding,room,player)
			end		
			thread:trigger(sgs.EventPhaseEnd,room,player)
			player:setPhase(phase)
			room:broadcastProperty(player,"phase")			
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive() 
	end
}

sr_liubei:addSkill(sr_rende)
	
--仇袭
--仇袭技能
srchouxidummycard = sgs.CreateSkillCard{
	name = "srchouxidummycard",
}
sr_chouxicard = sgs.CreateSkillCard{
	name = "sr_chouxicard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		room:notifySkillInvoked(source, "sr_chouxi")
		local cardIds = sgs.IntList()
		local getcards = {}
		local dummy = srchouxidummycard:clone()
		local card_idxs = room:getNCards(2)
		for _, c in sgs.qlist(card_idxs) do
			cardIds:append(c)
		end
		assert(cardIds:length() == 2)
		local card1 = sgs.Sanguosha:getCard(cardIds:at(0))
		local card2 = sgs.Sanguosha:getCard(cardIds:at(1))
		local type1 = card1:getType()
		local type2 = card2:getType()
--		table.insert(getcards, card1)
--		table.insert(getcards, card2)
		for _,id in sgs.qlist(cardIds) do
			dummy:addSubcard(id)
			table.insert(getcards, id)
		end
		room:setTag("agcards",sgs.QVariant(table.concat( getcards, "+")))
		local move = sgs.CardsMoveStruct()
		move.card_ids = cardIds
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), 
			"", "sr_chouxi", "")
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		local cando = 0
		local players = room:getOtherPlayers(source)
		local target = room:askForPlayerChosen(source, players, "sr_chouxi")
		local types = {"BasicCard", "EquipCard", "TrickCard"}
		for _, id in sgs.qlist(cardIds) do
			local t = sgs.Sanguosha:getCard(id):getType()
			if t == "basic" then table.removeOne(types, "BasicCard") end
			if t == "equip" then table.removeOne(types, "EquipCard") end
			if t == "trick" then table.removeOne(types, "TrickCard") end
		end
		local card
		if #types ~= 0 then
			card = room:askForCard(target, table.concat(types, ","), "@srchouxi-discard", 
				sgs.QVariant(), sgs.CardDiscarded)
		end
		room:removeTag("agcards")
		if not card then cando = 1 end
		if cando == 1 then

			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			room:damage(damage)
			if target:isAlive() then
				if type1 == type2 then
--					for _,c in pairs(getcards) do
						room:obtainCard(target, dummy, true)
--					end
				else
					room:fillAG(cardIds,target)
					local card_id = room:askForAG(target, cardIds, false, "sr_chouxi")
					room:clearAG(target)
					local effective_card = sgs.Sanguosha:getCard(card_id)
					room:obtainCard(target, effective_card, true)
					cardIds:removeOne(card_id)
					room:obtainCard(source, sgs.Sanguosha:getCard(cardIds:at(0)), true)
				end
			else
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, 
					target:objectName(), "sr_chouxi", "")
				if type1 == type2 then
--					for _,c in pairs(getcards) do
						room:throwCard(dummy, reason, nil)
--					end
				else
					room:fillAG(cardIds,source)
					local card_id = room:askForAG(source, cardIds, false, "sr_chouxi")
					source:invoke("clearAG")
					room:obtainCard(source, card_id, true)
					cardIds:removeOne(card_id)
					room:throwCard(sgs.Sanguosha:getCard(cardIds:at(0)), reason, nil)
				end				
			end
		else
--			for _,c in pairs(getcards) do
				room:obtainCard(source, dummy, true)
--			end
		end	
	end
}
sr_chouxi = sgs.CreateViewAsSkill{
	name = "sr_chouxi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_chouxicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#sr_chouxicard")) and (not player:isKongcheng())
	end
}
sr_liubei:addSkill(sr_chouxi)

--拥兵
sr_yongbing = sgs.CreateTriggerSkill{
	name = "sr_yongbing$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data, room)
		
		local damage = data:toDamage()
		local card = damage.card
		local srliubeis = sgs.SPlayerList()
		if card and card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					srliubeis:append(p)
				end
			end
			while not srliubeis:isEmpty() do
				local srliubei = room:askForPlayerChosen(player, srliubeis, self:objectName(), 
					"@sr_yongbing-to", true)
				if srliubei then
					room:notifySkillInvoked(srliubei, "sr_yongbing")
					room:broadcastSkillInvoke("sr_yongbing")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = srliubei
					log.arg = self:objectName()
					room:sendLog(log)
					srliubei:drawCards(1)
					srliubeis:removeOne(srliubei)
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
sr_liubei:addSkill(sr_yongbing)
sr_liubei:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_liubei"] = "SR刘备",
["#sr_liubei"] = "汉昭烈帝",
["&sr_liubei"] = "刘备",
["sr_rende"] = "仁德",
[":sr_rende"] = "任一角色的回合结束阶段结束时，你可以将任意数量的手牌交给该角色 然后该角色进行一个额外"..
"的出牌阶段",
["#sr_rende"] = "请选择任意张手牌交给 %src(也可以不给)",
["sr_chouxi"] = "仇袭",
["sr_chouxicard"] = "仇袭",
["@srchouxi-discard"] = "请你弃置一张与之均不同类别的牌",
[":sr_chouxi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌并展示牌堆顶的"..
"两张牌，然后令一名其他角色选择一项：弃置一张与之均不同类别的牌，然后令你获得这些牌；或者受到你造成的1"..
"点伤害并获得其中一种类别的牌，然后你获得其余的牌",
["sr_yongbing"] = "拥兵",
["@sr_yongbing-to"] = "请选择一名角色使其发动“拥兵”。",
[":sr_yongbing"] = "<font color=\"orange\"><b>主公技，</b></font>当一名其他蜀势力角色使用【杀】造成一次"..
"伤害后，该角色可令你摸一张牌。",
["$sr_rende"] = "以德服人",
["$sr_chouxi1"] = "不灭东吴 誓不归蜀！",
["$sr_chouxi2"] = "害我兄弟之仇，不共戴天！",
["$sr_yongbing"] = "拥兵安民，以固国之根本。",
["~sr_liubei"] = "云长翼德，久等了！",
["losesr_chouxi"] = "失去【仇袭】",
["losesr_rende"] = "失去【仁德】",
["losenone"] = "使用全部技能",
}

--SR黄月英
sr_huangyueying = sgs.General(extension,"sr_huangyueying","shu",3,false)

--授计
sr_shoujicard = sgs.CreateSkillCard{
	name = "sr_shoujicard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local id = self:getSubcards():first()
			local suit = sgs.Sanguosha:getCard(id):getSuit()
			if suit == sgs.Card_Spade then
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				return not targets[1]:isProhibited(to_select, duel)
			elseif suit == sgs.Card_Club then
				if to_select:getWeapon() ~= nil then
					local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
					return not targets[1]:isProhibited(to_select, collateral)
				end
			elseif suit == sgs.Card_Heart then
				if targets[1]:distanceTo(to_select) == 1 then
					if not to_select:isAllNude() then
						local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
						return not targets[1]:isProhibited(to_select, snatch)
					end
				end
			elseif suit == sgs.Card_Diamond then
				if not to_select:isKongcheng() then
					local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
					return not targets[1]:isProhibited(to_select, fire_attack)
				end
			end
		elseif #targets == 2 then
			return false
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, cardUse)
		local huangyueying = cardUse.from

		local l = sgs.LogMessage()
		l.from = huangyueying
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, huangyueying, data)
		room:broadcastSkillInvoke("sr_shouji")
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, huangyueying:objectName(), 
			"", "sr_shouji", "")
		room:moveCardTo(self, huangyueying, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, huangyueying, data)
		thread:trigger(sgs.CardFinished, room, huangyueying, data)
	end,
	on_use = function(self, room, source, targets)		
		local from = targets[1]
		local to = targets[2]			
		room:notifySkillInvoked(source, "sr_shouji")
		local id = self:getSubcards():first()
		local suit = sgs.Sanguosha:getCard(id):getSuit()
		if suit == sgs.Card_Spade then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("sr_shouji")
			local use = sgs.CardUseStruct()
            use.card = duel
            use.from = from
           	use.to:append(to)
            room:useCard(use)
			--source:removeTag("sr_shoujitarget")
		elseif suit == sgs.Card_Club then
			local slashees = sgs.SPlayerList()
			local slashee = nil
			for _,p in sgs.qlist(room:getOtherPlayers(to)) do
				if to:canSlash(p,true) then
					slashees:append(p)
				end
			end
			if not slashees:isEmpty() then
				room:notifySkillInvoked(source, "sr_shouji")
				slashee = room:askForPlayerChosen(from,slashees,"sr_shouji")
			else
				room:obtainCard(source, self, true)					
			end
			if slashee then
				local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
				collateral:setSkillName("sr_shouji")
				local use = sgs.CardUseStruct()
				use.card = collateral
				use.from = from
				use.to:append(to)
				use.to:append(slashee)
				room:useCard(use)					
			end
			--source:removeTag("luashoujitarget")				
		elseif suit == sgs.Card_Heart then
			if not to:isAllNude() then
				local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
				snatch:setSkillName("sr_shouji")
				local use = sgs.CardUseStruct()
				use.card = snatch
				use.from = from
				use.to:append(to)
				room:useCard(use)
				--source:removeTag("sr_shoujitarget")					
			else
				room:obtainCard(source, self, true)					
			end
		elseif suit == sgs.Card_Diamond then				
			local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
			fire_attack:setSkillName("sr_shouji")
			local use = sgs.CardUseStruct()
            use.card = fire_attack
            use.from = from
           	use.to:append(to)
            room:useCard(use)
			--source:removeTag("sr_shoujitarget")				
		end			
	end	
}
			
--视为技
sr_shouji = sgs.CreateViewAsSkill{
	name = "sr_shouji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected==0
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sr_shoujicard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())			
			return card
		end
	end,
	enabled_at_play = function(self, player)		
		return not player:hasUsed("#sr_shoujicard")
	end
}
sr_huangyueying:addSkill(sr_shouji)

--合谋

-- sr_hemou = sgs.CreateTriggerSkill{
-- 	name = "sr_hemou", 
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.Damage,sgs.EventPhaseChanging},  
-- 	on_trigger = function(self, event, player, data, room)
-- 		if event == sgs.EventPhaseChanging then 
-- 			local change = data:toPhaseChange()
-- 			if change.from ~= sgs.Player_Play then return false end
-- 			if player:hasFlag("hemouused") then
-- 				player:getRoom():setPlayerFlag(player,"-hemouused")
-- 			end
-- 		else
-- 			local damage = data:toDamage()
-- 			
-- 			local srhuangyueying = room:findPlayerBySkillName(self:objectName())
-- 			if not srhuangyueying then return false end
-- 			if not srhuangyueying:hasSkill(self:objectName())then return false end
-- 			if player:objectName() == srhuangyueying:objectName() then return false end
-- 			if srhuangyueying:isKongcheng() then return false end
-- 			local current = room:getCurrent()
-- 			if not current or current:getPhase() ~= sgs.Player_Play or current:hasFlag("hemouused") then 
--return false end
-- 			if damage.card and damage.card:isKindOf("Slash") then return false end 				
-- 			local card = room:askForCard(srhuangyueying, ".", "@srhemou-discard", data, sgs.CardDiscarded)
-- 			if card then
-- 				room:setPlayerFlag(current,"hemouused")
-- 				room:notifySkillInvoked(srhuangyueying, "sr_hemou")
-- 				room:broadcastSkillInvoke("sr_hemou")
-- 				local log = sgs.LogMessage()
-- 				log.type = "#TriggerSkill"
-- 				log.from = srhuangyueying
-- 				log.arg = self:objectName()
-- 				room:sendLog(log)
-- 				local targets = sgs.SPlayerList()
-- 				targets:append(srhuangyueying)
-- 				targets:append(player)
-- 				room:sortByActionOrder(targets)
-- 				for _,p in sgs.qlist(targets) do
-- 					p:drawCards(1)
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)		
-- 		return target and target:isAlive()
-- 	end
-- }
sr_hemouvs = sgs.CreateViewAsSkill{
	name = "sr_hemouvs",
	n = 1,
	view_filter = function(self,selected,to_select)		
		local n = sgs.Self:getMark("hemousuit")
		if n<=0 or #selected~=0 then return false end
		if to_select:isEquipped() then return false end
		if n == 1 then
			return to_select:getSuit() == sgs.Card_Spade
		elseif n == 2 then
			return to_select:getSuit() == sgs.Card_Club
		elseif n == 3 then
			return to_select:getSuit() == sgs.Card_Heart
		elseif n == 4 then
			return to_select:getSuit() == sgs.Card_Diamond
		else
			return false
		end
	end,
	view_as = function(self,cards)
		if #cards~=1 then return nil end
		local suit = cards[1]:getSuit()
		local number = cards[1]:getNumber()
		local card = nil
		if suit == sgs.Card_Spade then
			card = sgs.Sanguosha:cloneCard("duel",suit,number)
		elseif suit == sgs.Card_Club then
			card = sgs.Sanguosha:cloneCard("collateral",suit,number)
		elseif suit == sgs.Card_Heart then
			card = sgs.Sanguosha:cloneCard("snatch",suit,number)
		elseif suit == sgs.Card_Diamond then
			card = sgs.Sanguosha:cloneCard("fire_attack",suit,number)
		else
			return nil
		end
		if not card then return nil end
		card:addSubcard(cards[1])
		card:setSkillName("sr_hemouvs")		
		return card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("hemousuit")>0 and not player:isKongcheng()
	end
}

sr_hemou = sgs.CreateTriggerSkill{
	name = "sr_hemou",
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
			    for _, yueying in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if not yueying:isKongcheng() then 
						--if not yueying:askForSkillInvoke(self:objectName(),data) then return false end		
						local card = room:askForCard(yueying,".","@sr_hemou:"..player:objectName(),sgs.QVariant(),
							sgs.Card_MethodNone)
						if not card then return false end
						room:notifySkillInvoked(yueying,"sr_hemou")
						room:broadcastSkillInvoke("sr_hemou")
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,yueying:objectName(),
							player:objectName(),self:objectName(),nil)
						local move = sgs.CardsMoveStruct(card:getEffectiveId(),yueying,player,sgs.Player_PlaceHand,
							sgs.Player_PlaceHand,reason)
						room:moveCardsAtomic(move,true)
						room:setPlayerMark(player,"hemousuit",tonumber(card:getSuit())+1)
						room:handleAcquireDetachSkills(player,"sr_hemouvs")
						room:addPlayerMark(player, "&sr_hemou-Clear")
					end
				end
			else
				if player:getMark("hemousuit")> 0 then
					room:setPlayerMark(player,"hemousuit",0)
				end
				if player:hasSkill("sr_hemouvs") then
					room:handleAcquireDetachSkills(player,"-sr_hemouvs")
				end
			end
		else
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "sr_hemouvs") then
				if use.from and use.from:isAlive() then
					if use.from:getMark("hemousuit")> 0 then
						room:setPlayerMark(use.from,"hemousuit",0)
					end
					if use.from:hasSkill("sr_hemouvs") then
						room:handleAcquireDetachSkills(use.from,"-sr_hemouvs")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and not target:hasSkill(self:objectName())
	end
}
sr_huangyueying:addSkill(sr_hemou)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_hemouvs") then skills:append(sr_hemouvs) end
sgs.Sanguosha:addSkills(skills)
--奇才
-- sr_qicai = sgs.CreateTriggerSkill{
-- 	name = "sr_qicai",  
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.DamageCaused,sgs.DamageInflicted},  
-- 	on_trigger = function(self, event, player, data, room) 
-- 		
-- 		local damage = data:toDamage()
-- 		if event == sgs.DamageCaused then
-- 			local target = damage.to
-- 			if target then
-- 				if target:getEquips():length() > 0 and player:canDiscard(target,"e") then
-- 					if player:askForSkillInvoke(self:objectName(), data) then
-- 						room:notifySkillInvoked(player, "sr_qicai")
-- 						room:broadcastSkillInvoke("sr_qicai")
-- 						local card_id = room:askForCardChosen(player, target, "e", self:objectName())
-- 						room:throwCard(card_id,target, player)
-- 						local msg = sgs.LogMessage()
-- 						msg.type = "#DefendDamage"
-- 						msg.from = player
-- 						msg.to:append(damage.to)
-- 						msg.arg = self:objectName()
-- 						msg.arg2 = "normal_nature"
-- 						room:sendLog(msg)
-- 						return true
-- 					end
-- 				end
-- 			end
-- 		elseif event == sgs.DamageInflicted then
-- 			local source = damage.from
-- 			if source then
-- 				if player:getEquips():length() > 0 and source:canDiscard(player,"e") then
-- 					if player:askForSkillInvoke(self:objectName(), data) then
-- 						room:notifySkillInvoked(player, "sr_qicai")
-- 						room:broadcastSkillInvoke("sr_qicai")
-- 						local card_id = room:askForCardChosen(source, player, "e", self:objectName())
-- 						room:throwCard(card_id,player, source)
-- 						local msg = sgs.LogMessage()
-- 						msg.type = "#AvoidDamage"
-- 						msg.from = player
-- 						msg.to:append(damage.from)
-- 						msg.arg = self:objectName()
-- 						msg.arg2 = "normal_nature"
-- 						room:sendLog(msg)
-- 						return true
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end
-- }
sr_qicai = sgs.CreateTriggerSkill{
	name = "sr_qicai",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if not move.from or not move.from:hasSkill(self:objectName()) or 
			move.from:objectName() ~= player:objectName() then return false end
		if not move.from_places:contains(sgs.Player_PlaceHand) then return false end
		if not player:askForSkillInvoke(self:objectName(),data) then return false end
		room:notifySkillInvoked(player,"sr_qicai")
		room:broadcastSkillInvoke("sr_qicai")
		local judge = sgs.JudgeStruct()
        judge.pattern = ".|red"
		judge.good = true
		judge.negative = false
        judge.play_animation = false
        judge.reason = self:objectName()
        judge.who = player
        room:judge(judge)
		local card = judge.card
		if judge:isGood() then 
		    player:drawCards(1, self:objectName())
		end
		return false
	end
}
sr_huangyueying:addSkill(sr_qicai)
sr_huangyueying:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_huangyueying"] = "SR黄月英",
["#sr_huangyueying"] = "灵智共鸣",
["&sr_huangyueying"] = "黄月英",
["sr_shouji"] = "授计",
[":sr_shouji"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择两名角色，然后"..
"根据你弃置牌的花色，视为其中一名你选择的角色对另一名角色使用一张牌：<font color=\"black\"><b>♠</b></font>"..
"【决斗】，<font color=\"black\"><b>♣</b></font>【借刀杀人】，<font color=\"red\"><b>♥</b></font>【顺手牵羊"..
"】，<font color=\"red\"><b>♦</b></font>【火攻】。<font color=\"red\"><b>（选择第一个角色作为使用来源，选择"..
"第二个角色作为被使用目标）</b></font>",
["sr_hemou"] = "合谋",
--["@srhemou-discard"] = "你可以弃置一张手牌，然后与其各摸一张牌",
--[":sr_hemou"] = "每当一名其他角色造成一次不为【杀】的伤害后，你可以弃置一张手牌，然后与其各摸一张牌"..
--"（一名角色的出牌阶段限一次）",
[":sr_hemou"] = "其他角色的出牌阶段开始时，你可以将一张手牌正面朝上交给该角色，该角色本阶段限一次，可将一张"..
"与之相同花色的手牌按下列规则使用：<font color=\"black\"><b>♠</b></font>【决斗】，<font color=\"black\"><b>♣"..
"</b></font>【借刀杀人】，<font color=\"red\"><b>♥</b></font>【顺手牵羊】，<font color=\"red\"><b>♦</b></fon"..
"t>【火攻】。 ",
["@sr_hemou"] = "你可以发动【合谋】交给 %src 一张手牌",
["sr_hemouvs"] = "合谋",
[":sr_hemouvs"] ="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌按如下方式使用："..
"<font color=\"black\"><b>♠</b></font>当【决斗】，<font color=\"black\"><b>♣</b></font>当【借刀杀人】，"..
"<font color=\"red\"><b>♥</b></font>当【顺手牵羊】，<font color=\"red\"><b>♦</b></font>当【火攻】。",
["sr_qicai"] = "奇才",
-- [":sr_qicai"] = "你可以防止你造成的一次伤害，改为弃置对方装备区的一张牌；你可以防止你受到的一次伤害，"..
--"改为伤害来源弃置你装备区的一张牌。",
[":sr_qicai"] = "每当你失去一次手牌时，你可以进行判定，若结果为红色，你摸一张牌。",
["$sr_shouji"] = "还记得我给你的锦囊吗？",
["$sr_hemou"] = "一起度过这道难关吧！",
["$sr_qicai"] = "尽在我们掌握之中。",
["~sr_huangyueying"] = "孔明大人，请一定要赢~",
["losesr_hemou"] = "失去【合谋】",
["losesr_qicai"] = "失去【奇才】",
["losesr_shouji"] = "失去【授计】",
}

--SR马超
sr_machao = sgs.General(extension, "sr_machao", "shu", 4)

--奔袭
sr_benxi = sgs.CreateTriggerSkill{
	name = "sr_benxi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room) 
		local use = data:toCardUse()
		if use.from and use.from:getSeat() == player:getSeat() and use.card:isKindOf("Slash") then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			local no_respond_list = use.no_respond_list
			for _, t in sgs.qlist(use.to) do
				local discard = room:askForCard(t, "EquipCard", "@srbenxi-discard", data, sgs.CardDiscarded)
				if not discard then
					table.insert(no_respond_list, t:objectName())
				end
			end
			if #no_respond_list > 0 then
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
	end
}

sr_benxitm = sgs.CreateDistanceSkill{
	name = "#sr_benxitm",
	correct_func = function(self, from, to)
		if from:hasSkill("sr_benxi") then
			return -1
		end
	end,
}
sr_machao:addSkill(sr_benxi)
sr_machao:addSkill(sr_benxitm)
extension:insertRelatedSkills("sr_benxi","#sr_benxitm")

--邀战
sr_yaozhancard = sgs.CreateSkillCard{
	name = "sr_yaozhancard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select)
		return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_yaozhan")
		local success = source:pindian(targets[1], "sr_yaozhan", self)
		if success then			
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("sr_yaozhancard")
			slash:deleteLater()
			if source:canSlash(targets[1],slash,false) then
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = source
				card_use.to:append(targets[1])
				room:useCard(card_use, false)
			end
		else
			if targets[1]:canSlash(source,false) then
				room:askForUseSlashTo(targets[1], source, "@slash_can")
			end
		end
	end,
}
sr_yaozhan = sgs.CreateViewAsSkill{
	name = "sr_yaozhan", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_yaozhancard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#sr_yaozhancard")) and (not player:isKongcheng())
	end,
}
sr_machao:addSkill(sr_yaozhan)

sr_machao:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_machao"] = "SR马超",
["#sr_machao"] = "苍穹锦狮",
["&sr_machao"] = "马超",
["sr_benxi"] = "奔袭",
["@srbenxi-discard"] = "请弃置一张装备牌，否则此【杀】不可被【闪】响应",
--[":sr_benxi"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】选择目标后，目标角色须弃"..
--"置一张装备牌，否则此【杀】不可被【闪】响应。",
[":sr_benxi"] = "<font color=\"blue\"><b>锁定技，</b></font>你计算与其他角色的距离时始终-1；<font"..
" color=\"blue\"><b>锁定技，</b></font>你使用【杀】选择目标后，目标角色须弃置一张装备牌，否则此【杀】"..
"不可被【闪】响应。",
["sr_yaozhan"] = "邀战",
["sr_yaozhancard"] = "邀战",
["@slash_can"] = "你可以对拼点没赢的一方使用一张【杀】",
-- [":sr_yaozhan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与你攻击范围内的一名"..
--"其他角色拼点：若你赢，视为对其使用一张【杀】（此【杀】不计入每回合的使用限制）；若你没赢，该角色"..
--"可以对你使用一张【杀】。",
[":sr_yaozhan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点：若你赢，视为对"..
"其使用一张【杀】（此【杀】不计入每回合的使用限制）；若你没赢，该角色可以对你使用一张【杀】。",
["$sr_benxi"] = "全军突击！",
["$sr_yaozhan"] = "堂堂正正的打一场吧！",
["~sr_machao"] = "可恶，绝不轻饶！",
["losesr_benxi"] = "失去【奔袭】",
["losesr_yaozhan"] = "失去【邀战】",
}

--SR关羽
sr_guanyu = sgs.General(extension, "sr_guanyu", "shu", 4)

--温酒
--温酒视为技
sr_wenjiucard = sgs.CreateSkillCard{
	name = "sr_wenjiucard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_wenjiu")
		local ids = self:getSubcards()
		for _,id in sgs.qlist(ids) do
			source:addToPile("@srjiu", id, true)
		end
	end
}
sr_wenjiuVS = sgs.CreateViewAsSkill{
	name = "sr_wenjiu", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if 	not to_select:isEquipped() then
			return to_select:isBlack()
		end
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_wenjiucard:clone()
			card:addSubcard(cards[1]:getId())
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isKongcheng()then
			return not player:hasUsed("#sr_wenjiucard")
		end
		return false
	end
}

sr_wenjiu = sgs.CreateTriggerSkill{
	name = "sr_wenjiu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.ConfirmDamage,sgs.CardOffset,sgs.CardFinished},
	view_as_skill = sr_wenjiuVS,
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.TargetConfirmed then			
			local use = data:toCardUse()
			local source = use.from
			if not source then return false end
			if source:objectName() == player:objectName() then
				local card = use.card
				if card:isKindOf("Slash") then
					if player:getPile("@srjiu"):length() >= 1 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:notifySkillInvoked(player, "sr_wenjiu")
							room:broadcastSkillInvoke("sr_wenjiu")
							local cards = player:getPile("@srjiu")
							local card_id = -1
							if cards:length() == 1 then
								card_id = cards:first()
							else
								room:fillAG(cards, player)
								card_id = room:askForAG(player, cards, true, self:objectName())
								room:clearAG()
							end
							if card_id ~= -1 then
								local cardthrow = sgs.Sanguosha:getCard(card_id)
								room:throwCard(cardthrow, nil,player)
								room:setPlayerMark(player, "wenjiuslash", 1)
							end
						end
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local slash = damage.card
			if player:getMark("wenjiuslash") > 0 then
				if slash and slash:isKindOf("Slash") then
					damage.damage = damage.damage + 1
					room:notifySkillInvoked(player, "sr_wenjiu")
					room:broadcastSkillInvoke("sr_wenjiu")
					local msg = sgs.LogMessage()
					msg.type = "#IncreaseDamage"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = self:objectName()					
					room:sendLog(msg)
					data:setValue(damage)
				end
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			local dest = effect.to
			if effect.card and effect.card:isKindOf("Slash") and player:getMark("wenjiuslash") > 0 then
				room:notifySkillInvoked(player, "sr_wenjiu")
				room:broadcastSkillInvoke("sr_wenjiu")
				player:drawCards(1)
			end
		elseif event == sgs.CardFinished then
			
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") then
				if player:getMark("wenjiuslash") > 0 then
					room:setPlayerMark(player, "wenjiuslash", 0)
				end
			end
		-- elseif event == sgs.EventLoseSkill then
		-- 	if data:toString() == "sr_wenjiu" then
		-- 		player:clearOnePrivatePile("@srjiu")
		-- 	end
		end
		return false
	end	
}
sr_guanyu:addSkill(sr_wenjiu)

--水袭
--水袭技能卡
sr_shuixicard = sgs.CreateSkillCard{
	name = "sr_shuixicard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_shuixi")
		room:showCard(source, self:getEffectiveId())
		room:getThread():delay()
		local target = targets[1]
		local pattern = ""
		local suit = self:getSuit()
		if suit == sgs.Card_Spade then
			pattern = ".S"
		elseif suit == sgs.Card_Heart then
			pattern = ".H"
		elseif suit == sgs.Card_Club then
			pattern = ".C"
		elseif suit == sgs.Card_Diamond then
			pattern = ".D"
		end	
		local suitstring = self:getSuitString()	
		local srthrowcard = room:askForCard(target, pattern, "@srshuixithrow",sgs.QVariant(suitstring), 
			sgs.CardDiscarded)
		if not srthrowcard then
			room:loseHp(target, 1, true, source, "sr_shuixi")
			room:addPlayerMark(source, "&sr_shuixi-Clear")
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end		
	end
}
--水袭视为技
sr_shuixivs = sgs.CreateViewAsSkill{
	name = "sr_shuixi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_shuixicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_shuixi"
	end
}
--水袭触发技
sr_shuixi = sgs.CreateTriggerSkill{
	name = "sr_shuixi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = sr_shuixivs, 
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart then
			
			if not player:isKongcheng() then				
				room:askForUseCard(player, "@@sr_shuixi", "@srshuixicard")
			end
		end
		return false
	end
}
sr_guanyu:addSkill(sr_shuixi)

-- guanyuchoose = sgs.CreateTriggerSkill{
-- 	name = "#guanyuchoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self, event, player, data, room)
-- 		
-- 		local choice = room:askForChoice(player,self:objectName(),"losewenjiu+loseshuixi+losenone",data)
-- 		if choice == "losewenjiu" then
-- 			room:handleAcquireDetachSkills(player,"-sr_wenjiu")
-- 		elseif choice == "loseshuixi" then
-- 			room:handleAcquireDetachSkills(player,"-sr_shuixi")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_guanyu:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_guanyu"] = "SR关羽",
["#sr_guanyu"] = "忠义神武",
["&sr_guanyu"] = "关羽",
["sr_wenjiu"] = "温酒",
["@srjiu"] = "酒",
["#sr_wenjiubuff"] = "温酒",
[":sr_wenjiu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张黑色手牌置于你的武将牌"..
"上，称为“酒”。当你使用【杀】选择目标后，你可以将一张“酒”置入弃牌堆，然后当此【杀】造成伤害时，该伤害+1；"..
"当此【杀】被【闪】响应后，你摸一张牌。",
["#IncreaseDamage"] = "%from的技能【%arg】被触发，其对 %to 造成的伤害 +1",
["sr_shuixi"] = "水袭",
["@srshuixicard"] = "你可以发动“水袭”",
["~sr_shuixi"] = "请选择一张手牌，然后选择一名有手牌的其他角色，最后点击确定",
["@srshuixithrow"] = "请弃置一张与之相同花色的手牌，否则失去1点体力",
[":sr_shuixi"] = "回合开始阶段开始时，你可以展示一张手牌并选择一名有手牌的其他角色，令其选择一项：弃置一"..
"张与之相同花色的手牌，或失去1点体力。若该角色因此法失去体力，则此回合的出牌阶段，你不能使用【杀】。",
["$sr_wenjiu1"] = "关某愿取其首级，献于帐下。",
["$sr_wenjiu2"] = "酒且放下 关某去去就来！",
["$sr_shuixi"] = "听听这江河的咆哮吧！",
["~sr_guanyu"] = "必将尽行大义，以示后人。",
["losesr_wenjiu"] = "失去【温酒】",
["losesr_shuixi"] = "失去【水袭】",
}

--SR诸葛亮
sr_zhugeliang = sgs.General(extension, "sr_zhugeliang", "shu", 3)

--三分
sr_sanfencard = sgs.CreateSkillCard{
	name = "sr_sanfencard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName()		
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, cardUse)
		local zhugeliang = cardUse.from	

		local l = sgs.LogMessage()
		l.from = zhugeliang
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, zhugeliang, data)
		--room:notifySkillInvoked(zhugeliang,"sr_sanfen")
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, zhugeliang:objectName(), "", 
			"sr_sanfen", "")
		room:moveCardTo(self, zhugeliang, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, zhugeliang, data)
		thread:trigger(sgs.CardFinished, room, zhugeliang, data)
	end ,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_sanfen")

		local from = targets[1]
		local to = targets[2]
		local prompt1 = string.format("@srsanfen-slash:%s", to:objectName())
		if not room:askForUseSlashTo(from, to, prompt1, true) then
			if not from:isNude() then
				local chosen = room:askForCardChosen(source, from, "he", self:objectName())
				room:throwCard(chosen, from, source)
			end
		end
		local prompt2 = string.format("@srsanfen-slash:%s", source:objectName())
		if not room:askForUseSlashTo(to, source, prompt2, true) then
			if not to:isNude() then
				local chosen = room:askForCardChosen(source, to, "he", self:objectName())
				room:throwCard(chosen, to, source)
			end
		end
	end
}
sr_sanfen = sgs.CreateViewAsSkill{
	name = "sr_sanfen",
	n = 0, 
	view_as = function(self, cards) 
		return sr_sanfencard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_sanfencard")
	end
}
sr_zhugeliang:addSkill(sr_sanfen)

--观星
sr_guanxing = sgs.CreateTriggerSkill{
	name = "sr_guanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start and player:getPhase() ~= sgs.Player_Finish then 
			return false end
		
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, "sr_guanxing")
			room:broadcastSkillInvoke("sr_guanxing")
			local count = room:alivePlayerCount()
			if count > 3 then
				count = 3
			end
			local cards = room:getNCards(count)
			room:askForGuanxing(player, cards, 0)
		end		
	end
}
sr_zhugeliang:addSkill(sr_guanxing)

--帷幄
sr_weiwo = sgs.CreateTriggerSkill{
	name = "sr_weiwo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data, room) 
		
		local damage = data:toDamage()
		if player:isKongcheng() then			
			if damage.nature == sgs.DamageStruct_Normal then
				room:notifySkillInvoked(player, "sr_weiwo")
				room:broadcastSkillInvoke("sr_weiwo")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = "normal_nature"
				room:sendLog(msg)
				return true
			end
		else			
			if damage.nature ~= sgs.DamageStruct_Normal then
				room:notifySkillInvoked(player, "sr_weiwo")
				room:broadcastSkillInvoke("sr_weiwo")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = damage.nature == sgs.DamageStruct_Fire and "fire_nature" or "thunder_nature"
				room:sendLog(msg)
				return true
			end
		end
		return false
	end
}
sr_zhugeliang:addSkill(sr_weiwo)

-- zhugeliangchoose = sgs.CreateTriggerSkill{
-- 	name = "#zhugeliangchoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self, event, player, data, room)
-- 		
-- 		local choice = room:askForChoice(player,self:objectName(),"losesanfen+loseguanxing+loseweiwo+losenone",data)
-- 		if choice == "losesanfen" then
-- 			room:handleAcquireDetachSkills(player,"-sr_sanfen")
-- 		elseif choice == "loseguanxing" then
-- 			room:handleAcquireDetachSkills(player,"-sr_guanxing")
-- 		elseif choice == "loseweiwo" then
-- 			room:handleAcquireDetachSkills(player,"-sr_weiwo")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_zhugeliang:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_zhugeliang"] = "SR诸葛亮",
["#sr_zhugeliang"] = "三分天下",
["&sr_zhugeliang"] = "诸葛亮",
["sr_sanfen"] = "三分",
["@srsanfen-slash"] = "请对该角色（%src）使用一张【杀】，否则你被弃置一张牌",
[":sr_sanfen"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择两名其他角色，其中一名"..
"你选择的角色须对另外一名角色使用一张【杀】，然后另外一名角色须对你使用一张【杀】，你弃置不如此做者一张"..
"牌。<font color=\"red\"><b>（选择第一个角色为作为第一个【杀】使用者，且此【杀】有距离限制）</b></font>",
["sr_guanxing"] = "观星",
[":sr_guanxing"] = "回合开始/结束阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色的数量，且最多为3），将"..
"其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。",
["sr_weiwo"] = "帷幄",
[":sr_weiwo"] = "<font color=\"blue\"><b>锁定技，</b></font>当你有手牌时，你防止受到的属性伤害；当你没有"..
"手牌时，你防止受到非属性伤害。",
["#AvoidDamage"] = "%from 的技能【%arg】被触发，防止了 %to 对其造成的 %arg2 伤害",
["#DefendDamage"] = "%from 的技能【%arg】被触发，防止了其对 %to 造成的 %arg2 伤害",
["$sr_sanfen"] = "诚如是，则汉室可兴矣。",
["$sr_guanxing"] = "知天易，逆天难。",
["$sr_weiwo"] = "挫敌锐气，静待反击之时！",
["~sr_zhugeliang"] = "悠悠苍天,曷此其极！",
["losesr_sanfen"] = "失去【三分】",
["losesr_guanxing"] = "失去【观星】",
["losesr_weiwo"] = "失去【帷幄】",
}

--SR张飞
sr_zhangfei = sgs.General(extension, "sr_zhangfei", "shu", 4)

--蓄劲
sr_xujindummycard = sgs.CreateSkillCard{
	name = "sr_xujindummycard"
}
sr_xujin = sgs.CreateTriggerSkill{
	name = "sr_xujin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, "sr_xujin")
					room:broadcastSkillInvoke("sr_xujin")
					local ids = room:getNCards(5, false)
					local left = sgs.IntList()
					local getback = sgs.IntList()
					room:fillAG(ids)
					room:getThread():delay()
					local dest = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
					local card_id = room:askForAG(dest, ids, false, self:objectName())
					room:clearAG()
					local card = sgs.Sanguosha:getCard(card_id)
					local suit = card:getSuit()
					for _,id in sgs.qlist(ids) do
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuit() == suit then
							getback:append(id)
						else
							left:append(id)
						end
					end
					if getback:length() > 0 then
						room:setPlayerMark(player, "srxulimark", getback:length())
						room:setPlayerMark(player, "&sr_xujin-Clear", getback:length())
						local dummy = sr_xujindummycard:clone()
						for _,id in sgs.qlist(getback) do
							dummy:addSubcard(id)
						end
						room:obtainCard(dest, dummy, true)
					end
					if left:length() > 0 then
						local dummy = sr_xujindummycard:clone()
						for _,id in sgs.qlist(left) do
							dummy:addSubcard(id)
						end
						room:throwCard(dummy, nil, nil)
					end
					return true
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("srxulimark") > 0 then
					room:setPlayerMark(player, "srxulimark", 0)
				end
			end
		end
		return false	
	end
}
sr_zhangfei:addSkill(sr_xujin)
--蓄劲BUFF
sr_xujintm = sgs.CreateTargetModSkill{
	name = "#sr_xujintm",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self, target)
		if target:hasSkill("sr_xujin") then
			if target:getMark("srxulimark") > 0 then
				local count = target:getMark("srxulimark") - 1
				return count
			end
		end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sr_xujin") then
			if from:getMark("srxulimark") > 0 then
				local count = from:getMark("srxulimark") - 1
				if from:getWeapon() == nil then
					return count
				else
					local distance = from:getWeapon():getRealCard():toWeapon():getRange()
					if count + 1 > distance then
						return count
					end
				end
			end
		end
	end
}
sr_zhangfei:addSkill(sr_xujintm)
extension:insertRelatedSkills("sr_xujin", "#sr_xujintm")

--咆哮
-- sr_paoxiao = sgs.CreateTriggerSkill{
-- 	name = "sr_paoxiao",  
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.TargetConfirmed, sgs.Damage, sgs.CardFinished},  
-- 	on_trigger = function(self, event, player, data, room)
-- 		
-- 		if event == sgs.TargetConfirmed then
-- 			local use = data:toCardUse()
-- 			local source = use.from
-- 			local targets = use.to
-- 			if source and source:hasSkill(self:objectName()) then
-- 				if source:getPhase() == sgs.Player_Play then
-- 					if targets:contains(player) then
-- 						local card = use.card
-- 						if card:isKindOf("Slash") then
-- 							if not player:isNude() then
-- 								if room:askForSkillInvoke(source, self:objectName(), data) then
-- 									room:notifySkillInvoked(source, "sr_paoxiao")
-- 									room:broadcastSkillInvoke("sr_paoxiao")
-- 									local disc = room:askForCardChosen(source, player, "he", self:objectName())
-- 									room:throwCard(disc, player, source)
-- 									room:setPlayerMark(player, "srpaoxiaomark",	player:getMark("srpaoxiaomark") + 1)
-- 									room:setPlayerFlag(source,self:objectName())
-- 								end
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if event == sgs.Damage then
-- 			if player:hasFlag(self:objectName()) then
-- 				local damage = data:toDamage()
-- 				local dest = damage.to
-- 				local card = damage.card
-- 				if not player:isNude() then
-- 					if card and card:isKindOf("Slash") then
-- 						if dest:getMark("srpaoxiaomark") > 0 then
-- 							room:setPlayerFlag(dest,"srpaoxiao")							
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if event == sgs.CardFinished then
-- 			if player:hasFlag(self:objectName()) then
-- 				local use = data:toCardUse()
-- 				if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then					
-- 					local players = room:getAllPlayers()
-- 					for _,p in sgs.qlist(players) do
-- 						if p:getMark("srpaoxiaomark") > 0 and p:hasFlag("srpaoxiao") then
-- 							if player:isNude() then return false end
-- 							room:setPlayerMark(p, "srpaoxiaomark", p:getMark("srpaoxiaomark") - 1)
-- 							room:setPlayerFlag(player,"-"..self:objectName())
-- 							room:setPlayerFlag(p,"-srpaoxiao")							
-- 							local prompt = string.format("srpaoxiaoslash:%s", p:objectName())
-- 							if not room:askForUseCard(player, "slash", prompt) then
-- 								repeat
-- 									if player:isNude() then
-- 										room:setPlayerMark(p,"srpaoxiaomark",0)
-- 										break
-- 									end
-- 									local disc = room:askForCardChosen(p, player, "he", self:objectName())
-- 									room:notifySkillInvoked(player,"sr_paoxiao")
-- 									room:broadcastSkillInvoke("sr_paoxiao")
-- 									room:throwCard(disc, player, p)
-- 									room:setPlayerMark(p, "srpaoxiaomark", p:getMark("srpaoxiaomark") - 1)
-- 								until p:getMark("srpaoxiaomark") <= 0
-- 							else
-- 								room:setPlayerMark(p, "srpaoxiaomark", 0)	
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)
-- 		return target
-- 	end
-- }
sr_paoxiao = sgs.CreateTriggerSkill{
    name = "sr_paoxiao",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
	    
		local damage = data:toDamage()
		local victim = damage.to
		if damage.from:objectName() ~= player:objectName() then return false end
		if victim:objectName() == player:objectName() then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		if damage.chain or damage.transfer or not damage.by_user then return false end
		if not damage.card:isKindOf("Slash") then return false end
		if victim:isDead() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
		    room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)
			room:setPlayerFlag(victim, "paoxiao_tar")
			local paoxiao_slash = room:askForUseCard(player, "slash", "#Paoxiao")
			if not paoxiao_slash then
			    if not player:isNude() then
				    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					    if p:hasFlag("paoxiao_tar") then
						    local disc = room:askForCardChosen(p, player, "he", self:objectName())
							room:throwCard(disc, player, p)
							room:setPlayerFlag(p, "-paoxiao_tar")
						end
					end
				end
			else
			    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("paoxiao_tar") then
						room:setPlayerFlag(p, "-paoxiao_tar")
					end
				end
			end
		end
		return false
	end
}

sr_zhangfei:addSkill(sr_paoxiao)

-- zhangfeichoose = sgs.CreateTriggerSkill{
-- 	name = "#zhangfeichoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self, event, player, data, room)
-- 		
-- 		local choice = room:askForChoice(player,self:objectName(),"losexujin+losepaoxiao+losenone",data)
-- 		if choice == "losexujin" then
-- 			room:handleAcquireDetachSkills(player,"-sr_xujin")
-- 			room:handleAcquireDetachSkills(player,"-#sr_xujintm")
-- 		elseif choice == "losepaoxiao" then
-- 			room:handleAcquireDetachSkills(player,"-sr_paoxiao")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_zhangfei:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_zhangfei"] = "SR张飞",
["#sr_zhangfei"] = "豪迈勇者",
["&sr_zhangfei"] = "张飞",
["sr_xujin"] = "蓄劲",
[":sr_xujin"] = "摸牌阶段，你可以放弃摸牌，改为展示牌堆顶的五张牌，并令一名角色获得其中一种花色的所有牌，"..
"再将其余的牌置入弃牌堆。若如此做，你本回合的攻击范围和可以使用的【杀】数量与此法获得的牌的数量相同。",
["sr_paoxiao"] = "咆哮",
["#Paoxiao"] = "你需要使用一张【杀】，否则你被目标角色弃置一张牌",
--[":sr_paoxiao"] = "当你于出牌阶段使用【杀】指定目标后，可以弃置目标角色的一张牌，若如此做，当此【杀】"..
--"造成伤害且结算后，你选择一项：使用一张【杀】，或令该角色弃置你的一张牌。",
[":sr_paoxiao"] = "出牌阶段，当你使用【杀】对目标角色造成一次伤害并结算完毕后，你可以摸一张牌，然后选择一"..
"项：使用一张【杀】，或令该角色弃置你一张牌。",
["$sr_xujin"] = "休想逃，乖乖受死！",
["$sr_paoxiao"] = "都站稳了，吃我一击！",
["~sr_zhangfei"] = "你这家伙，好生厉害！",
["losesr_xujin"] = "失去【蓄劲】",
["losesr_paoxiao"] = "失去【咆哮】",
}

--SR赵云
sr_zhaoyun = sgs.General(extension,"sr_zhaoyun","shu")

function canCauseDamage(card)
	if card:isKindOf("EquipCard") then return false end
	return card:isKindOf("Slash") or card:isKindOf("FireAttack") or card:isKindOf("Duel") or 
	card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("Drowning")
end

-- sr_jiuzhu = sgs.CreateTriggerSkill{
-- 	name = "sr_jiuzhu",
-- 	events = {sgs.CardsMoveOneTime},
-- 	on_trigger = function(self, event, player, data, room)
-- 		local move = data:toMoveOneTime()
-- 		local ids = move.card_ids
-- 		if move.to_place ~= sgs.Player_DiscardPile then return false end
-- 		
-- 		local zhaoyun = room:findPlayerBySkillName(self:objectName())
-- 		if not zhaoyun or zhaoyun:isDead() or not zhaoyun:hasSkill(self:objectName()) then return false end
-- 		for _,id in sgs.qlist(ids) do
-- 			local c = sgs.Sanguosha:getEngineCard(id)
-- 			if c:isKindOf("Jink") then
-- 				local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
-- 				if not room:askForCard(zhaoyun,pattern,"@sr_jiuzhu:"..c:objectName(),data,self:objectName()) then 
				--continue end
-- 				room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
-- 				room:broadcastSkillInvoke("sr_jiuzhu") 
-- 				local move1 = sgs.CardsMoveStruct()
-- 				move1.card_ids:append(id)
-- 				move1.to_place = sgs.Player_PlaceHand
-- 				move1.to = zhaoyun						
-- 				room:moveCardsAtomic(move1, true)
-- 				if zhaoyun:getPhase() == sgs.Player_NotActive then
-- 					local current = room:getCurrent()
-- 					if current and current:isAlive() then
-- 						if room:askForSkillInvoke(zhaoyun,self:objectName(),data) then
-- 							room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
-- 							room:broadcastSkillInvoke("sr_jiuzhu")
-- 							local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
-- 							slash:setSkillName(self:objectName())							
-- 							current:addQinggangTag(slash)							
-- 							room:useCard(sgs.CardUseStruct(slash,zhaoyun,current))
-- 						end
-- 					end
-- 				end				
-- 			end
-- 		end
-- 		return false
-- 	end,	
-- }
sr_jiuzhu = sgs.CreateTriggerSkill{
	name = "sr_jiuzhu",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		local ids = move.card_ids
		if move.to_place ~= sgs.Player_DiscardPile then return false end
		for _,id in sgs.qlist(ids) do
			for _, zhaoyun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local c = sgs.Sanguosha:getEngineCard(id)
				if c:isKindOf("Jink") then
					local acard = room:askForCard(zhaoyun,"^Jink","@sr_jiuzhu:"..c:objectName(), data, self:objectName())
					if acard then
						room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
						room:broadcastSkillInvoke("sr_jiuzhu") 
						local move1 = sgs.CardsMoveStruct()
						move1.card_ids:append(id)
						move1.to_place = sgs.Player_PlaceHand
						move1.to = zhaoyun						
						room:moveCardsAtomic(move1, true)
						if zhaoyun:getPhase() == sgs.Player_NotActive then
							local current = room:getCurrent()
							local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
							slash:deleteLater()
							slash:setSkillName(self:objectName())									
							if zhaoyun:isProhibited(current,slash) then return false end
							if current and current:isAlive() then
								if room:askForSkillInvoke(zhaoyun,self:objectName(),data) then
									room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
									room:broadcastSkillInvoke("sr_jiuzhu")
									current:addQinggangTag(slash)				
									room:useCard(sgs.CardUseStruct(slash,zhaoyun,current))
								end
							end
						end
						break
					end				
				end
			end
		end
		return false
	end,	
}

sr_zhaoyun:addSkill(sr_jiuzhu)


sr_tuwei = sgs.CreateTriggerSkill{
	name = "sr_tuwei",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isVirtualCard() then return false end
		if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("Slash") then
		    room:setPlayerFlag(use.from,"todiscard")
		    for _,p in sgs.qlist(use.to) do
				room:setPlayerFlag(p,"todiscard")
			end
			local tos = {}
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("todiscard") then
					table.insert(tos,p:getGeneralName())
				end
			end
			if use.from:objectName() == player:objectName() then
				for _, t in sgs.qlist(use.to) do
				    if not t:isNude() then
						local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
						if room:askForCard(player,pattern,"@sr_tuwei", sgs.QVariant(table.concat(tos,"+")),self:objectName()) then
						    room:broadcastSkillInvoke(self:objectName())
							room:notifySkillInvoked(player, self:objectName())
						    for i = 1, 2 do
							    local card_id = room:askForCardChosen(player, t, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				                room:throwCard(card_id, t, player)
								if t:isNude() then break end
							end
						end
					end
				end
			else
			    if use.to:contains(player) and not use.from:isNude() then
				    local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
					if room:askForCard(player,pattern,"@sr_tuwei", sgs.QVariant(table.concat(tos,"+")),self:objectName()) then
					    room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(player, self:objectName())
					    for i = 1, 2 do
						    local card_id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				            room:throwCard(card_id, use.from, player)
							if use.from:isNude() then break end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:hasSkill("sr_tuwei")
	end
}

sr_zhaoyun:addSkill(sr_tuwei)

sr_zhaoyun:addSkill("#choose")

sgs.LoadTranslationTable{
	["sr_zhaoyun"] = "SR赵云",
	["#sr_zhaoyun"] = "银龙逆鳞",
	["&sr_zhaoyun"] = "赵云",
	["sr_jiuzhu"] = "救主",
	-- [":sr_jiuzhu"] = "每当一张【闪】进入弃牌堆时，你可以用一张能造成伤害的牌替换之。若此时不在你的回合"..
	--"内，你可以视为对当前回合角色使用一张【杀】，你以此法使用的【杀】无视防具。",
	-- ["@sr_jiuzhu"] = "你可以用一张可以造成伤害的牌替换 【%src】",
	[":sr_jiuzhu"] = "每当一张非转化的【闪】进入弃牌堆时，你可以用一张不为【闪】的牌替换之。若此时不在你"..
	"的回合内，你可以视为对当前回合角色使用一张【杀】，你以此法使用的【杀】无视防具。",
	["@sr_jiuzhu"] = "你可以用一张不为【闪】的牌替换之",
	["$sr_jiuzhu"] = "和我一起，活着离开此地！",
	-- ["sr_tuwei"] = "突围",
	-- [":sr_tuwei"] = "每当一张【杀】进入弃牌堆时，若你是此【杀】的目标或使用者，你可以弃置一张基本牌，然"..
	--"后弃置此牌的目标或使用者的共计两张牌",
	["$sr_tuwei"] = "让我了结此战！",
	-- ["@sr_tuwei"] = "你可以为 【%src】 弃置一张基本牌",
	["sr_tuwei"] = "突围",
	[":sr_tuwei"] = "每当一张非转化的【杀】进入弃牌堆时，若你是此【杀】的目标或使用者，你可以弃置一张可以"..
	"造成伤害的牌，然后弃置此牌的目标或使用者的共计两张牌",
	["@sr_tuwei"] = "你可以弃置一张可以造成伤害的牌",
	["@sr_tuwei-card"] = "你可以发动 【突围】",
	["~sr_tuwei"] = "选择 【杀】 的目标或使用者，弃置其共计两张牌",
	["losesr_jiuzhu"] = "失去【救主】",
	["losesr_tuwei"] = "失去【突围】",
	["~sr_zhaoyun"] = "人外有人，子龙领教了！",
}

--SR孙权
sr_sunquan = sgs.General(extension, "sr_sunquan$", "wu", 4)

--权衡
sr_quanhengCard = sgs.CreateSkillCard{
	name = "sr_quanhengCard",
	target_fixed = true,
	mute = true,
	about_to_use = function(self, room, cardUse)
		local quanheng_items = {}
		if sgs.Slash_IsAvailable(cardUse.from) then table.insert(quanheng_items, "quanheng_vs_slash") end
		table.insert(quanheng_items, "quanheng_vs_exnihilo")
		local choice = room:askForChoice(cardUse.from, "sr_quanheng", table.concat(quanheng_items, "+"))
		if choice == "quanheng_vs_slash" then
			local invoke = room:askForUseCard(cardUse.from, "@@sr_quanheng_slash", "@sr_quanheng_slash")
			if not invoke then room:setPlayerFlag(cardUse.from, "-quanheng_used") end
		elseif choice == "quanheng_vs_exnihilo" then
			local invoke = room:askForUseCard(cardUse.from, "@@sr_quanheng_ex_nihilo", "@sr_quanheng_ex_nihilo")
			if not invoke then room:setPlayerFlag(cardUse.from, "-quanheng_used") end
		end
	end
}

sr_quanhengVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_quanheng",
	view_as = function()
		return sr_quanhengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasFlag("quanheng_used")) and (not player:isKongcheng()) and player:getPhase() ~= sgs.Player_NotActive
	end
}

sr_quanheng = sgs.CreateTriggerSkill{
	name = "sr_quanheng",  
	events = { sgs.CardFinished, sgs.CardOffset, sgs.EventPhaseChanging},
	view_as_skill = sr_quanhengVS,
	on_trigger = function(self, event, player, data, room) 
		if event == sgs.CardFinished then
			local card = data:toCardUse().card
			local from = data:toCardUse().from
			if from then
			    if from:objectName() == player:objectName() then
				    if card:isKindOf("Slash") or card:isKindOf("ExNihilo") then
				        if table.contains(card:getSkillNames(), "sr_quanheng") then									
					        room:setPlayerMark(player, "srquanhengmark", 0)
						end
					end
				end
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			local source = effect.from
			if source and source:hasSkill(self:objectName()) and source:getMark("srquanhengmark") > 0 and effect.card and  table.contains(effect.card:getSkillNames(), "sr_quanheng")then
				room:sendCompulsoryTriggerLog(source, self:objectName())
				room:notifySkillInvoked(source, self:objectName())
				source:drawCards(source:getMark("srquanhengmark"))
				room:setPlayerMark(source, "srquanhengmark", 0)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
				room:setPlayerFlag(player, "-quanheng_used")
				room:setPlayerMark(player, "srquanhengmark", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


--权衡【杀】
sr_quanheng_slashCard = sgs.CreateSkillCard{
	name = "sr_quanheng_slashCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:addSubcards(self:getSubcards())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and 
			not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = false,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("sr_quanheng")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "srquanhengmark", self:subcardsLength())
		room:setPlayerFlag(source, "quanheng_used")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:addSubcards(self:getSubcards())
		slash:setSkillName("sr_quanheng")
		slash:deleteLater()
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for _, p in pairs(targets) do
			use.to:append(p)
		end
		room:useCard(use)
		room:addPlayerHistory(source, use.card:getClassName())
	end
}

sr_quanheng_slash = sgs.CreateViewAsSkill{
	name = "sr_quanheng_slash",
	n = 999,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local skc = sr_quanheng_slashCard:clone()
			for _, c in ipairs(cards) do
				skc:addSubcard(c)
			end
			skc:setSkillName("sr_quanheng")
			return skc
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_quanheng_slash"
	end,
}


--权衡【无中生有】
sr_quanheng_ex_nihiloCard = sgs.CreateSkillCard{
	name = "sr_quanheng_ex_nihiloCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "srquanhengmark", self:subcardsLength())
		room:setPlayerFlag(source, "quanheng_used")
		local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
		ex_nihilo:addSubcards(self:getSubcards())
		ex_nihilo:setSkillName("sr_quanheng")
		ex_nihilo:deleteLater()
		room:useCard(sgs.CardUseStruct(ex_nihilo, source, source, false))
	end
}

sr_quanheng_ex_nihilo = sgs.CreateViewAsSkill{
	name = "sr_quanheng_ex_nihilo",
	n = 999,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local skc = sr_quanheng_ex_nihiloCard:clone()
			for _, c in ipairs(cards) do
				skc:addSubcard(c)
			end
			skc:setSkillName("sr_quanheng")
			return skc
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_quanheng_ex_nihilo"
	end
}


local quanheng = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_quanheng_slash") then quanheng:append(sr_quanheng_slash) end
if not sgs.Sanguosha:getSkill("sr_quanheng_ex_nihilo") then quanheng:append(sr_quanheng_ex_nihilo) end
sgs.Sanguosha:addSkills(quanheng)


sr_sunquan:addSkill(sr_quanheng)


--雄略
sr_xionglvecard = sgs.CreateSkillCard{
	name = "sr_xionglvecard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_xionglve")
		local srlves = source:getPile("@srlve")
		local id
		room:fillAG(srlves, source)
		id = room:askForAG(source, srlves, false, "sr_xionglvecard")
		room:clearAG(source)
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("BasicCard")then
			local choicelist = {}
			local choices = "cancel"
			if source:isWounded() then
				table.insert(choicelist, "srcanpeach")
			end
			if not source:hasUsed("Analeptic") then
				table.insert(choicelist, "srcananaleptic")
			end
			if sgs.Slash_IsAvailable(source) then
				table.insert(choicelist, "srcanslash")
			end
			for _,cando in pairs(choicelist) do
				choices = string.format("%s+%s", cando, choices)
			end
			local choice = room:askForChoice(source, "sr_xionglvebasic", choices)
			if choice == "srcanslash" then
				local players = sgs.SPlayerList()
				local slash = sgs.Sanguosha:cloneCard("Slash", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if source:canSlash(p, slash, true) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(source, players, "sr_xionglveslash", nil, true, false)
					if target then
						slash:setSkillName("sr_xionglvecard")
						slash:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = slash
						use.from = source
						use.to:append(target)
						room:useCard(use)
					end
				end
			elseif choice == "srcananaleptic" then
				local analeptic = sgs.Sanguosha:cloneCard("Analeptic", card:getSuit(), card:getNumber())
				analeptic:setSkillName("sr_xionglvecard")
				analeptic:addSubcard(id)
				local use = sgs.CardUseStruct()
				use.card = analeptic
				use.from = source
				use.to:append(source)
				room:useCard(use)
			elseif choice == "srcanpeach" then
				local peach = sgs.Sanguosha:cloneCard("Peach", card:getSuit(), card:getNumber())
				peach:setSkillName("sr_xionglvecard")
				peach:addSubcard(id)
				local use = sgs.CardUseStruct()
				use.card = peach
				use.from = source
				use.to:append(source)
				room:useCard(use)				
			end
		elseif card:isKindOf("TrickCard")then
			local choicelist = {"srcantiesuo", "srcanwanjian", "srcannanman", "srcantaoyuan", "srcanwugu", 
			"srcanhuogong", "srcanjiedao", "srcanguohe", "srcanshunshou", "srcanwuzhong", "srcanjuedou"}
			local choices = "cancel"
			for _,cando in pairs(choicelist) do
				choices = string.format("%s+%s", cando, choices)
			end
			local choice = room:askForChoice(source, "sr_xionglvetrick", choices)
			local players = sgs.SPlayerList()
			if choice == "srcantiesuo" then
				local chain = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not source:isProhibited(p, chain) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local target1 = room:askForPlayerChosen(source, players, "sr_xionglvetiesuo", 
						nil, true, false)
					if target1 then
						players:removeOne(target1)
						local target2
						if not players:isEmpty() then
							target2 = room:askForPlayerChosen(source, players, "sr_xionglvetiesuo", 
								nil, true, false)
						end
						chain:setSkillName("sr_xionglvecard")
						chain:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = chain
						use.from = source
						use.to:append(target1)
						if target2 then
							use.to:append(target2)
						end
						room:useCard(use)
					end
				end
			elseif choice == "srcanwanjian" then
				local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, archery_attack) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					archery_attack:setSkillName("sr_xionglvecard")
					archery_attack:addSubcard(id)
					local use = sgs.CardUseStruct()
					use.card = archery_attack
					use.from = source
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			elseif choice == "srcannanman" then
				local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, savage_assault) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					savage_assault:setSkillName("sr_xionglvecard")
					savage_assault:addSubcard(id)
					local use = sgs.CardUseStruct()
					use.card = savage_assault
					use.from = source
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			elseif choice == "srcantaoyuan" then
				local god_salvation = sgs.Sanguosha:cloneCard("god_salvation", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not source:isProhibited(p, god_salvation) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					god_salvation:setSkillName("sr_xionglvecard")
					god_salvation:addSubcard(id)
					local use = sgs.CardUseStruct()
					use.card = god_salvation
					use.from = source
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end			
			elseif choice == "srcanwugu" then
				local amazing_grace = sgs.Sanguosha:cloneCard("amazing_grace", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not source:isProhibited(p, amazing_grace) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					amazing_grace:setSkillName("sr_xionglvecard")
					amazing_grace:addSubcard(id)
					local use = sgs.CardUseStruct()
					use.card = amazing_grace
					use.from = source
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end				
			elseif choice == "srcanhuogong" then
				local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not source:isProhibited(p, fire_attack) then
						if not p:isKongcheng() then
							players:append(p)
						end
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(source, players, "sr_xionglvehuogong", nil, true, false)
					if target then
						fire_attack:setSkillName("sr_xionglvecard")
						fire_attack:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = fire_attack
						use.from = source
						use.to:append(target)
						room:useCard(use)
					end
				end				
			elseif choice == "srcanjiedao" then
				local collateral = sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, collateral) then
						if p:getWeapon() ~= nil then
							players:append(p)
						end
					end
				end
				if not players:isEmpty() then
					local target1 = room:askForPlayerChosen(source, players, "sr_xionglvejiedao", nil, true, false)
					if target1 then
						local otherplayers = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(target1)) do
							if target1:canSlash(p) then
								otherplayers:append(p)
							end
						end
						if not otherplayers:isEmpty() then
							local target2 = room:askForPlayerChosen(source, otherplayers, 
								"sr_xionglvejiedao1", nil, true, false)
							if target2 then
								collateral:setSkillName("sr_xionglvecard")
								collateral:addSubcard(id)
								local use = sgs.CardUseStruct()
								use.card = collateral
								use.from = source
								use.to:append(target1)
								use.to:append(target2)
								room:useCard(use)
							end
						end
					end
				end				
			elseif choice == "srcanguohe" then
				local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, dismantlement) then
						if not p:isAllNude() then
							players:append(p)
						end
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(source, players, "sr_xionglveguohe", nil, true, false)
					if target then
						dismantlement:setSkillName("sr_xionglvecard")
						dismantlement:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = dismantlement
						use.from = source
						use.to:append(target)
						room:useCard(use)
					end
				end			
			elseif choice == "srcanshunshou" then
				local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, snatch) then
						if source:distanceTo(p) == 1 then
							if not p:isAllNude() then
								players:append(p)
							end
						end
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(source, players, "sr_xionglveshunshou", 
						nil, true, false)
					if target then
						snatch:setSkillName("sr_xionglvecard")
						snatch:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = snatch
						use.from = source
						use.to:append(target)
						room:useCard(use)
					end
				end					
			elseif choice == "srcanwuzhong" then
				local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", card:getSuit(), card:getNumber())
				ex_nihilo:setSkillName("sr_xionglvecard")
				ex_nihilo:addSubcard(id)
				local use = sgs.CardUseStruct()
				use.card = ex_nihilo
				use.from = source
				use.to:append(source)
				room:useCard(use)			
			elseif choice == "srcanjuedou" then
				local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not source:isProhibited(p, duel) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(source, players, "sr_xionglvejuedou", nil, true, false)
					if target then
						duel:setSkillName("sr_xionglvecard")
						duel:addSubcard(id)
						local use = sgs.CardUseStruct()
						use.card = duel
						use.from = source
						use.to:append(target)
						room:useCard(use)
					end
				end
			end
		elseif card:isKindOf("EquipCard")then
			local players = sgs.SPlayerList()
			if card:isKindOf("Weapon") then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getWeapon() == nil then
						players:append(p)
					end
				end
			elseif card:isKindOf("Armor") then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getArmor() == nil then
						players:append(p)
					end
				end
			elseif card:isKindOf("DefensiveHorse") then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getDefensiveHorse() == nil then
						players:append(p)
					end
				end			
			elseif card:isKindOf("OffensiveHorse") then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getOffensiveHorse() == nil then
						players:append(p)
					end
				end
			elseif card:isKindOf("Treasure") then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getTreasure() == nil then
						players:append(p)
					end
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(source, players, "sr_xionglveequip")
				if target then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), 
						self:objectName(), "")
					room:moveCardTo(card, nil, target, sgs.Player_PlaceEquip, reason)
				end
			end
		end
	end
}
sr_xionglvevs = sgs.CreateViewAsSkill{
	name = "sr_xionglve", 
	n = 0, 
	view_as = function(self, cards)
		return sr_xionglvecard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getPile("@srlve"):length() > 0
	end
}

sr_xionglve = sgs.CreateTriggerSkill{
	name = "sr_xionglve",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sr_xionglvevs,
	on_trigger = function(self, event, player, data, room)
				
		if player:getPhase() == sgs.Player_Draw then
			if room:askForSkillInvoke(player, "sr_xionglve", data) then
				room:notifySkillInvoked(player, "sr_xionglve")
				room:broadcastSkillInvoke("sr_xionglve")
				local ids = room:getNCards(2, false)
				room:fillAG(ids)
				local card_id = room:askForAG(player, ids, false, "sr_xionglve")
				room:clearAG()
				local card = sgs.Sanguosha:getCard(card_id)
				for _,id in sgs.qlist(ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getId() == card:getId() then
						room:obtainCard(player, c, true)
					else
						player:addToPile("@srlve", id, true)
					end
				end
				return true
			end
		elseif player:getPhase() == sgs.Player_Discard then
			if player:hasFlag("xionglveused") then
				room:setPlayerFlag(player,"-xionglveused")
			end
		end		
		return false	
	end
}
sr_sunquan:addSkill(sr_xionglve)

--辅政
sr_fuzhengcard = sgs.CreateSkillCard{
	name = "sr_fuzhengcard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		if #targets>=2 then return false end
		return to_select:getKingdom() == "wu" and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self,targets)
		return #targets<=2
	end,
	on_use = function(self,room,source,targets)
		room:notifySkillInvoked(source, "sr_fuzheng")
		if #targets>0 then
			room:setTag("fuzheng_num",sgs.QVariant(#targets))
			for _,p in ipairs(targets) do
				if p:isAlive() then
					p:drawCards(1)
				end
			end			
			local card1
			local card2
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), 
				"sr_fuzheng", nil)			
			if not targets[1]:isKongcheng() then
				card1 = room:askForExchange(targets[1], "sr_fuzheng1", 1, 1, false, "srfuzhengput")
				room:removeTag("fuzheng_num")
			end
			if #targets>1 then				
				if not targets[2]:isKongcheng() then
					card2 = room:askForExchange(targets[2], "sr_fuzheng2", 1, 1, false, "srfuzhengput")
				end
			end
			if card1 then
				room:getThread():delay()
				room:moveCardTo(card1, targets[1], nil, sgs.Player_DrawPile, reason)
			end
			if card2 then
				room:getThread():delay()
				room:moveCardTo(card2, targets[2], nil, sgs.Player_DrawPile, reason)
			end
		end
	end
}

sr_fuzhengvs = sgs.CreateViewAsSkill{
	name = "sr_fuzheng",
	n = 0,
	view_as = function(self,cards)
		return sr_fuzhengcard:clone()
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "@@sr_fuzheng"
	end
}

sr_fuzheng = sgs.CreateTriggerSkill{
	name = "sr_fuzheng$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sr_fuzhengvs,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start then return false end
		if not player:hasLordSkill(self:objectName()) then return false end
		
		local players = sgs.SPlayerList()
		local others = room:getOtherPlayers(player)
		for _,p in sgs.qlist(others) do
			if p:getKingdom() == "wu" then
				players:append(p)
			end
		end
		if players:isEmpty() then return false end
		room:getThread():delay()
		room:askForUseCard(player,"@@sr_fuzheng","@sr_fuzheng")			
		return false
	end
}
sr_sunquan:addSkill(sr_fuzheng)

sr_sunquan:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_sunquan"] = "SR孙权",
["#sr_sunquan"] = "东吴大帝",
["&sr_sunquan"] = "孙权",
["sr_quanheng"] = "权衡",
[":sr_quanheng"] = "出牌阶段限一次，你可以将至少一张手牌当一张【无中生有】或【杀】使用，若你以此法使用的牌被【无懈可击】或【闪】响应时，你摸等量的牌。",
["quanheng_vs_slash"] = "视为使用【杀】",
["quanheng_vs_exnihilo"] = "视为使用【无中生有】",
["sr_quanheng_slash"] = "权衡",
["sr_quanheng_ex_nihilo"] = "权衡",
["@sr_quanheng_ex_nihilo"] = "请选择至少一张手牌当【无中生有】使用",
["@sr_quanheng_slash"] = "请选择至少一张手牌当【杀】使用",
["sr_xionglve"] = "雄略",
["sr_xionglvecard"] = "雄略",
["sr_xionglvebasic"] = "雄略-基本牌",
["sr_xionglveslash"] = "雄略",
["sr_xionglveequip"] = "雄略",
["sr_xionglvetrick"] = "雄略-锦囊牌",
["sr_xionglveguohe"] = "雄略",
["sr_xionglveshunshou"] = "雄略",
["sr_xionglvehuogong"] = "雄略",
["sr_xionglvejiedao"] = "雄略",
["sr_xionglvejiedao1"] = "雄略",
["sr_xionglvetiesuo"] = "雄略",
["sr_xionglvejuedou"] = "雄略",
["@srlve"] = "略",
["srcanslash"] = "当【杀】使用",
["srcananaleptic"] = "当【酒】使用",
["srcanpeach"] = "当【桃】使用",
["srcanjuedou"] = "当【决斗】使用",
["srcanwuzhong"] = "当【无中生有】使用",
["srcanshunshou"] = "当【顺手牵羊】使用",
["srcanguohe"] = "当【过河拆桥】使用",
["srcanjiedao"] = "当【借刀杀人】使用",
["srcanhuogong"] = "当【火攻】使用",
["srcanwugu"] = "当【五谷丰登】使用",
["srcantaoyuan"] = "当【桃园结义】使用",
["srcannanman"] = "当【南蛮入侵】使用",
["srcanwanjian"] = "当【万箭齐发】使用",
["srcantiesuo"] = "当【铁索连环】使用",
[":sr_xionglve"] = "摸牌阶段，你可以放弃摸牌，改为展示牌堆顶的两张牌，你获得其中一张，然后将另一张牌置于"..
"你的武将牌上，称为“略”。出牌阶段，你可以将一张基本牌或锦囊牌的“略”当与之同类别的任意一张牌（延时类锦囊"..
"牌除外）使用，将一张装备牌的“略”置于一名其他角色装备区内的相应位置。",
["sr_fuzheng"] = "辅政",
["srfuzhengput"] = "请选择一张手牌，以便置于牌堆顶",
[":sr_fuzheng"] = "<font color=\"orange\"><b>主公技，</b></font>回合开始阶段开始时，你可以令至多两名其他吴"..
"势力各摸一张牌，然后这些角色依次将一张手牌置于牌堆顶。",
["@sr_fuzheng"] = "你可以发动“辅政”",
["~sr_fuzheng"] = "选择两名其他吴势力角色",
["sr_fuzheng1"] = "辅政",
["sr_fuzheng2"] = "辅政",
["$sr_quanheng"] = "容我三思。",
["$sr_xionglve1"] = "识大体，弃细物，此乃君道。",
["$sr_xionglve2"] = "知己长短方能避短就长。",
["$sr_fuzheng"] = "望诸位各司其职，各出其力。",
["~sr_sunquan"] = "父亲……大哥……仲谋愧矣……",
["losesr_quanheng"] = "失去【权衡】",
["losesr_xionglve"] = "失去【雄略】",
}

--SR陆逊
sr_luxun = sgs.General(extension, "sr_luxun", "wu", 3)

--待劳
sr_dailaocard = sgs.CreateSkillCard{
	name = "sr_dailaocard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_dailao")
		local choice = ""
		if source:isKongcheng() or targets[1]:isKongcheng() then 
			choice = "srdraw"
		else
			room:setPlayerFlag(targets[1],"dailao_target")
			choice = room:askForChoice(source,"sr_dailao","srdraw+srdiscard")
		end
		if choice == "srdraw" then
			if source:isAlive() then source:drawCards(1) end
			if targets[1]:isAlive() then targets[1]:drawCards(1) end
		else
			if not source:isNude() and source:canDiscard(source,"he") then
				room:askForDiscard(source,"sr_dailao",1,1,false,true)
			end
			if not targets[1]:isNude() and targets[1]:canDiscard(targets[1],"he") then
				room:askForDiscard(targets[1],"sr_dailao",1,1,false,true)
			end
		end
		if source:isAlive() then source:turnOver() end
		if targets[1]:isAlive() then targets[1]:turnOver() end		
	end
}
sr_dailao = sgs.CreateViewAsSkill{
	name = "sr_dailao", 
	n = 0, 
	view_as = function(self, cards)
		return sr_dailaocard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_dailaocard")
	end
}
sr_luxun:addSkill(sr_dailao)

--诱敌
sr_youdicard = sgs.CreateSkillCard{
	name = "sr_youdicard", 
	target_fixed = true, 
	will_throw = true, 	
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_youdi")
		local n = self:subcardsLength()
		room:throwCard(self,source)		
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("youdisource") and p:canDiscard(p,"he") then
				if p:getCardCount() <= n then
					p:throwAllHandCardsAndEquips()
				else					
					room:askForDiscard(p,"sr_youdi",n,n,false,true)
				end
			end
		end		
	end
}
sr_youdivs = sgs.CreateViewAsSkill{
	name = "sr_youdi", 
	n = 999, 
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local sr = sr_youdicard:clone()
		for _,c in ipairs(cards) do
			sr:addSubcard(c)
		end
		sr:setSkillName(self:objectName())
		return sr
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "@@sr_youdi"
	end
}

sr_youdi = sgs.CreateTriggerSkill{
	name = "sr_youdi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.CardAsked,sgs.CardResponded, sgs.CardUsed},
	view_as_skill = sr_youdivs,
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.card:isKindOf("Slash") and use.to:contains(player) then			
				room:setPlayerFlag(use.from,"youdisource")								
			end
		elseif event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			if pattern ~= "jink" then return false end
			if player:faceUp() then return false end			
			if not player:askForSkillInvoke(self:objectName(),data) then return false end
			room:notifySkillInvoked(player,"sr_youdi")
			player:turnOver()
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			jink:setSkillName(self:objectName())
			room:provide(jink)
			return true
		elseif event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card
			if player:isKongcheng() then return false end
			if card_star:isKindOf("Jink") and data:toCardResponse().m_isUse and player:canDiscard(player,"h") then
				room:askForUseCard(player,"@@sr_youdi","@sr_youdi")
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("youdisource") then
						room:setPlayerFlag(p,"-youdisource")
					end
				end
			end
		elseif event == sgs.CardUsed then
			local card_star = data:toCardUse().card
			if player:isKongcheng() then return false end
			if card_star:isKindOf("Jink") and player:canDiscard(player,"h") then
				room:askForUseCard(player,"@@sr_youdi","@sr_youdi")
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("youdisource") then
						room:setPlayerFlag(p,"-youdisource")
					end
				end
			end
		end
		return false
	end,	
}
sr_luxun:addSkill(sr_youdi)

--儒雅
sr_ruya = sgs.CreateTriggerSkill{
	name = "sr_ruya",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			if player:askForSkillInvoke(self:objectName(), data) then
			    player:drawCards(player:getMaxHp())
				player:turnOver()
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end
}


sr_luxun:addSkill(sr_ruya)
sr_luxun:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_luxun"] = "SR陆逊",
["#sr_luxun"] = "定计破蜀",
["&sr_luxun"] = "陆逊",
["sr_dailao"] = "待劳",
[":sr_dailao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色与你各摸一张牌"..
"或者各弃一张牌，然后你与其依次将武将牌翻面",
["srdraw"] = "摸一张牌",
["srdiscard"] = "弃一张牌",
["sr_youdi"] = "诱敌",
["@sryoudi-discard"] = "你可以弃置一张牌，然后此【杀】被【闪】响应时，对方弃置所有手牌",
[":sr_youdi"] = "若你的武将牌背面朝上，你可以将其翻面来视为你使用一张闪。每当你使用闪响应一名角色使用的杀"..
"时，你可以额外弃置任意数量的手牌，然后该角色弃置等量的牌",
["@sr_youdi"] = "你可以发动【诱敌】",
["~sr_youdi"] = "选择任意张手牌",
["sr_ruya"] = "儒雅",
[":sr_ruya"] = "当你失去最后的手牌时，你可以将手牌补至你体力上限的张数，然后你的武将牌翻面",
["$sr_dailao1"] = " 广施方略，以观其变。",
["$sr_dailao2"] = "散兵游勇，不攻自破。",
["$sr_youdi"] = "兵者，以诈利，以利动。",
["$sr_ruya"] = "劳谦虚己，则负之者重。",
["~sr_luxun"] = "吾尚不堪大任！",
["losesr_youdi"] = "失去【诱敌】",
["losesr_dailao"] = "失去【待劳】",
["losesr_ruya"] = "失去【儒雅】",
}

--SR周瑜
sr_zhouyu = sgs.General(extension, "sr_zhouyu", "wu", 3)

--英才
sr_yingcai = sgs.CreateTriggerSkill{
	name = "sr_yingcai", 
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw then
			
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sr_yingcai")
				room:broadcastSkillInvoke("sr_yingcai")
				local card_to_get = {}
				local card_to_throw = {}
				local suits = {}
				while true do
					local ids = room:getNCards(1, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, 
						player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					room:getThread():delay()
					local id = ids:at(0)
					local card = sgs.Sanguosha:getCard(id)
					local suit = card:getSuit()
					if table.contains(suits,suit) then
						table.insert(card_to_get, id)
					else
						if #suits < 2 then
							table.insert(suits,suit)
							table.insert(card_to_get, id)
						else
							table.insert(card_to_throw, id)
							break
						end
					end
				end
				if #card_to_throw > 0 then
					for _,card in ipairs(card_to_throw) do
						room:throwCard(card, nil, nil)
					end
				end
				if #card_to_get > 0 then
					for _,card in pairs(card_to_get) do
						room:obtainCard(player, card, true)
					end
				end
				return true
			end
		end
		return false
	end
}
sr_zhouyu:addSkill(sr_yingcai)

--伪报
sr_weibaocard = sgs.CreateSkillCard{
	name = "sr_weibaocard",
	target_fixed = true,
	will_throw = false,
	-- filter = function(self, targets, to_select)
	-- 	if #targets == 0 then
	-- 		return to_select:objectName() ~= sgs.Self:objectName()
	-- 	end
	-- 	return false
	-- end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_weibao")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "sr_weibao", nil)
		room:moveCardTo(self, source,nil, sgs.Player_DrawPile, reason,false)		
		room:getThread():delay()
		local dest = room:askForPlayerChosen(source,room:getOtherPlayers(source),
			"sr_weibao","#sr_weibao",false,true)
		if not dest then return end
		local suit = room:askForSuit(dest, "sr_weibao")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = dest
		log.arg =  sgs.Card_Suit2String(suit)
		room:sendLog(log)
		local ids = room:getNCards(1, false)
		local card = sgs.Sanguosha:getCard(ids:at(0))
		room:obtainCard(dest, card,false)
		room:showCard(dest, ids:at(0))
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = dest
			room:damage(damage)
		end
	end
}
sr_weibao = sgs.CreateViewAsSkill{
	name = "sr_weibao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sr_weibaocard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#sr_weibaocard") 
		end
		return false
	end
}
sr_zhouyu:addSkill(sr_weibao)

--筹略
sr_choulvecard = sgs.CreateSkillCard{
	name = "sr_choulvecard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName() and 
			to_select:objectName() ~= targets[1]:objectName()	
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, cardUse)
		local zhouyu = cardUse.from

		local l = sgs.LogMessage()
		l.from = zhouyu
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, zhouyu, data)
		room:notifySkillInvoked(zhouyu,"sr_choulve")
		
		-- local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, zhouyu:objectName(),
		-- "", "sr_choulve", "")
		-- room:moveCardTo(self, zhouyu, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, zhouyu, data)
		thread:trigger(sgs.CardFinished, room, zhouyu, data)
	end,
	on_use = function(self, room, source, targets)
		--room:notifySkillInvoked(source, "sr_choulve")		
		local first = targets[1]
		local second = targets[2]
		local pointfirst
		local pointsecond
		local card_id1
		local card_id2
		local card1
		local card2
		if source:getHandcardNum() > 0 then
			local prompt1 = string.format("srchoulvegive:%s", first:objectName())
			local cardgive1 = room:askForExchange(source, "sr_choulve1", 1, 1, false, prompt1)
			card_id1 = cardgive1:getSubcards():first()	
			card1 = sgs.Sanguosha:getCard(card_id1)
			room:obtainCard(first, card1,false)
			pointfirst = card1:getNumber()
		else			
			return 
		end
		if source:getHandcardNum() > 0 then
			local prompt2 = string.format("srchoulvegive:%s", second:objectName())
			local cardgive2 = room:askForExchange(source, "sr_choulve2", 1, 1, false, prompt2)
			card_id2 = cardgive2:getSubcards():first()	
			card2 = sgs.Sanguosha:getCard(card_id2)
			room:obtainCard(second, card2,false)
			pointsecond = card2:getNumber()
		else			
			room:obtainCard(source, card1,false)
			return 
		end
		if card_id1 and card_id2 then 
			room:showCard(first, card_id1)
			room:getThread():delay()
			room:showCard(second, card_id2)
			room:getThread():delay()
		end
		if pointfirst and pointsecond then
			if pointfirst ~= pointsecond then
				if pointfirst > pointsecond then
					room:setPlayerFlag(source, "srchoulvebuff")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("sr_choulve")					
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = first
					use.to:append(second)
					room:useCard(use)
					room:setPlayerFlag(source, "-srchoulvebuff")
				else
					room:setPlayerFlag(source, "srchoulvebuff")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("sr_choulve")
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = second
					use.to:append(first)
					room:useCard(use)
					room:setPlayerFlag(source, "-srchoulvebuff")
				end
			end
		end
	end
}
sr_choulvevs = sgs.CreateViewAsSkill{
	name = "sr_choulve",
	n = 0,
	view_as = function(self, cards)
		local card = sr_choulvecard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getHandcardNum() >= 2 then
			return not player:hasUsed("#sr_choulvecard") 
		end
		return false
	end
}

sr_choulve = sgs.CreateTriggerSkill{
	name = "sr_choulve", 
	--frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage}, 
	view_as_skill = sr_choulvevs, 
	on_trigger = function(self, event, player, data, room) 
		local damage = data:toDamage()
		
		for _, srzhouyu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if srzhouyu:hasFlag("srchoulvebuff") then 
				if damage.card and damage.card:isKindOf("Slash") then
					room:notifySkillInvoked(srzhouyu,"sr_choulve")
					room:broadcastSkillInvoke("sr_choulve")
					srzhouyu:drawCards(1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		 return target
	end
}
sr_zhouyu:addSkill(sr_choulve)
sr_zhouyu:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_zhouyu"] = "SR周瑜",
["#sr_zhouyu"] = "英隽异才",
["&sr_zhouyu"] = "周瑜",
["sr_yingcai"] = "英才",
[":sr_yingcai"] = "摸牌阶段，你可以放弃摸牌，改为展示牌堆顶的一张牌，你重复此流程直到你展示出第三种花色"..
"的牌时，将这张牌置入弃牌堆，然后获得其余的牌。",
["sr_weibao"] = "伪报",
[":sr_weibao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌置于牌堆顶，然后"..
"令一名其他角色选择一种花色后摸一张牌并展示之，若此牌与所选花色不同，你对其造成1点伤害。",
["#sr_weibao"] = "选择一名其他角色为目标",
["sr_choulve"] = "筹略",
["sr_choulvecard"] = "筹略",
["srchoulvegive"] = "请交给该角色（%src）一张手牌",
[":sr_choulve"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给两名其他角色各一张手牌，"..
"然后依次展示之，若点数不同，视为点数较大的一方对另一方使用一张【杀】，该【杀】造成伤害后，你摸一张牌。",
["$sr_yingcai"] = "汝等看好了。",
["$sr_weibao"] = "一步步走向绝境吧！",
["$sr_choulve"] = "一切如我所料。",
["~sr_zhouyu"] = "谁高一筹，我心中有数！",
["losesr_yingcai"] = "失去【英才】",
["losesr_weibao"] = "失去【伪报】",
["losesr_choulve"] = "失去【筹略】",
}

--SR吕蒙
sr_lvmeng = sgs.General(extension, "sr_lvmeng", "wu", 4)

--誓学
sr_shixue = sgs.CreateTriggerSkill{
	name = "sr_shixue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.CardUsed,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			local from = use.from
			if not from or not card:isKindOf("Slash") or not from:hasSkill(self:objectName()) or
				from:objectName() ~= player:objectName() then
				return false 
			end
			if not room:askForSkillInvoke(from,self:objectName(),data) then return false end
			room:broadcastSkillInvoke("sr_shixue")
			room:setPlayerFlag(from,"shixueused")
			from:drawCards(2)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Jink") then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("shixueused") and not p:isNude() then
						room:broadcastSkillInvoke("sr_shixue")
						room:notifySkillInvoked(p,"sr_shixue")
						if p:getCardCount() <= 2 then
							p:throwAllHandCardsAndEquips()
						else
							room:askForDiscard(p,self:objectName(),2,2,false,true)
						end
						room:setPlayerFlag(p,"-shixueused")
					end 
				end
			end
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then			
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("shixueused") then					
						room:setPlayerFlag(p,"-shixueused")
					end 
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
sr_lvmeng:addSkill(sr_shixue)

--国士
sr_guoshi = sgs.CreateTriggerSkill{
	name = "sr_guoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)	
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:removeTag("srguoshicard")
			end
		else
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				for _, lvmeng in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(lvmeng,"sr_guoshibegin",data) then
						room:notifySkillInvoked(lvmeng,"srguoshi")
						room:broadcastSkillInvoke("sr_guoshi",1)
						local ids = room:getNCards(2)
						room:askForGuanxing(lvmeng,ids,0)
					end
				end
			elseif phase == sgs.Player_Finish then
								
				local DiscardPile = room:getDiscardPile()
				local tag = room:getTag("srguoshicard"):toString():split("+")
				room:removeTag("srguoshicard")
				if #tag == 0 then return false end
				local toGainList = sgs.IntList()				
				for _,is in ipairs(tag) do
					if is~="" and DiscardPile:contains(tonumber(is)) then
						toGainList:append(tonumber(is))
					end
				end			
				if toGainList:isEmpty() then return false end		
					for _, lvmeng in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if room:askForSkillInvoke(lvmeng,"sr_guoshiend",data) then
						room:notifySkillInvoked(lvmeng,"srguoshi")			
						room:broadcastSkillInvoke("sr_guoshi",2)
						room:fillAG(toGainList)
						local card_id = room:askForAG(player, toGainList, false, "sr_guoshi")
						room:clearAG()
						if card_id ~= -1 then
							local gain_card = sgs.Sanguosha:getCard(card_id)					
							player:obtainCard(gain_card)
							toGainList:removeOne(card_id)
						end
						if toGainList:isEmpty() then return false end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

sr_guoshimove = sgs.CreateTriggerSkill{
	name = "#sr_guoshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,},
	on_trigger = function(self, event, player, data, room)
		
		local current = room:getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end		
		local move = data:toMoveOneTime()			
		if (move.to_place == sgs.Player_DiscardPile) 
			and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 
				sgs.CardMoveReason_S_REASON_DISCARD) 
			or (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
			local oldtag = room:getTag("srguoshicard"):toString():split("+")
			local totag = {}
			for _,is in ipairs(oldtag) do
				table.insert(totag,tonumber(is))
			end					
			for _, card_id in sgs.qlist(move.card_ids) do
				table.insert(totag,card_id)
			end	
			room:setTag("srguoshicard",sgs.QVariant(table.concat(totag,"+")))
		end		
	end
}

sr_lvmeng:addSkill(sr_guoshi)
sr_lvmeng:addSkill(sr_guoshimove)
extension:insertRelatedSkills("sr_guoshi","#sr_guoshi")
sr_lvmeng:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_lvmeng"] = "SR吕蒙",
["#sr_lvmeng"] = "国士之风",
["&sr_lvmeng"] = "吕蒙",
["sr_shixue"] = "誓学",
[":sr_shixue"] = "当你使用【杀】指定目标后，你可以摸两张牌，若如此做，则当此【杀】被【闪】响应后，你须弃置两张牌",
["sr_guoshi"] = "国士",
[":sr_guoshi"] = "任一角色的回合开始阶段开始时，你可以观看牌堆顶的两张牌，然后可以将其中任意张牌置于牌堆"..
"底，将其余的牌以任意顺序置于牌堆顶；任一角色的回合结束阶段开始时,你可以令其获得本回合因弃置或者判定进入"..
"弃牌堆的一张牌",
["sr_guoshibegin"] = "国士",
["sr_guoshiend"] = "国士",
["$sr_shixue"] = "不经一事，不长一智。",
["$sr_guoshi1"] = "此事需从长计议。",
["$sr_guoshi2"] = "小不忍，则乱大谋。",
["~sr_lvmeng"] = "大智难尽，吾已无计可施。",
["losesr_guoshi"] = "失去【国士】",
["losesr_shixue"] = "失去【誓学】",
}

--SR甘宁
sr_ganning = sgs.General(extension, "sr_ganning", "wu", 4)

--劫袭
sr_jiexicard = sgs.CreateSkillCard{
	name = "sr_jiexicard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select)
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local success = source:pindian(target, "sr_jiexi", self)
		local data = sgs.QVariant()
		data:setValue(target)
		while success do
			if not source:hasSkill("sr_jiexi") then break end
			if target:isKongcheng() then
				break
			elseif source:isKongcheng() then
				break
			elseif source:askForSkillInvoke("sr_jiexi", data) then
				local room = source:getRoom()
				room:notifySkillInvoked(source,"sr_jiexi")
				room:broadcastSkillInvoke("sr_jiexi")
				success = source:pindian(target, "sr_jiexi")
			else
				break
			end
		end
	end
}
sr_jiexivs = sgs.CreateViewAsSkill{
	name = "sr_jiexi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_jiexicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_jiexicard")
	end
}

sr_jiexi = sgs.CreateTriggerSkill{
	name = "sr_jiexi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Pindian}, 
	view_as_skill = sr_jiexivs, 
	on_trigger = function(self, event, player, data, room) 
		local pindian = data:toPindian()
		if pindian.reason == "sr_jiexi" then
			if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				if pindian.from:objectName() == player:objectName() then
					if not pindian.to:isAllNude() and pindian.from:canDiscard(pindian.to,"hej") then
												
						room:notifySkillInvoked(pindian.from, "sr_jiexi")						
						local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
						dismantlement:setSkillName("sr_jiexi")
						dismantlement:deleteLater()
						local use = sgs.CardUseStruct()
						use.card = dismantlement
						use.from = pindian.from
						use.to:append(pindian.to)
						room:useCard(use)
					end
				end
			end
		end
		return false
	end
}
sr_ganning:addSkill(sr_jiexi)

--游侠
sr_youxiacard = sgs.CreateSkillCard{
	name = "sr_youxiacard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select) 
		if (#targets >= 2) or (to_select:objectName() == sgs.Self:objectName()) then
			return false
		end
		return not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_youxia")
		source:turnOver()
		if not source:isAlive() then return end
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids:append(room:askForCardChosen(source, targets[1], "he", "sr_youxia"))
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		if #targets == 2 then
			local move2 = sgs.CardsMoveStruct()
			move2.card_ids:append(room:askForCardChosen(source, targets[2], "he", "sr_youxia"))
			move2.to = source
			move2.to_place = sgs.Player_PlaceHand
			moves:append(move2)
		end
		room:moveCardsAtomic(moves, false)
	end
}
sr_youxia = sgs.CreateViewAsSkill{
	name = "sr_youxia", 
	n = 0, 
	view_as = function(self, cards) 
		return sr_youxiacard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:faceUp()
	end
}

-- sr_youxia = sgs.CreateTriggerSkill{
-- 	name = "sr_youxia",
-- 	frequency = sgs.Skill_NotFrequent,
-- 	events = {sgs.Damage},
-- 	view_as_skill = sr_youxiavs,
-- 	on_trigger = function(self, event, player, data, room)
-- 		
-- 		local srganning = room:findPlayerBySkillName("sr_youxia")
-- 		if not srganning or srganning:isDead() then return false end		
-- 		if not srganning:hasSkill("sr_youxia") then return false end		
-- 		if player:objectName() == srganning:objectName() then return false end		
-- 		if srganning:faceUp() then return false end		
-- 		local damage = data:toDamage()
-- 		local card = damage.card
-- 		if card then
-- 			if card:isKindOf("Slash") then
-- 				if srganning:getHandcardNum() >= 2 then
-- 					if room:askForSkillInvoke(srganning, "sr_youxia", data) then
-- 						room:notifySkillInvoked(srganning, "sr_youxia")
-- 						room:broadcastSkillInvoke("sr_youxia",2)
-- 						if room:askForDiscard(srganning, "sr_youxia", 2, 2, false, false) then
-- 							srganning:turnOver()
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)
-- 		return target and target:isAlive()
-- 	end
-- }
sr_youxiaPro = sgs.CreateProhibitSkill{
	name = "#sr_youxiaPro",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("sr_youxia") and (card:isKindOf("Slash") or card:isKindOf("Duel")) and not to:faceUp()
	end
}

sr_ganning:addSkill(sr_youxia)
sr_ganning:addSkill(sr_youxiaPro)
extension:insertRelatedSkills("sr_youxia","#sr_youxiaPro")
sr_ganning:addSkill("#choose")
	
sgs.LoadTranslationTable{
["sr_ganning"] = "SR甘宁",
["#sr_ganning"] = "怀铃的乌羽",
["&sr_ganning"] = "甘宁",
["sr_jiexi"] = "劫袭",
[":sr_jiexi"] = "出牌阶段，你可以与一名其他角色拼点，若你赢，视为对其使用一张【过河拆桥】。你可以重复此流"..
"程直到你以此法拼点没赢。<font color=\"green\"><b>每阶段限一次。 </b></font>",
["sr_youxia"] = "游侠",
[":sr_youxia"] = "出牌阶段，若你的武将牌正面朝上，你可以将你的武将牌翻面，然后从一名至两名其他角色处各获"..
"得一张牌；<font color=\"blue\"><b>锁定技，</b></font>若你的武将牌背面朝上，你不是【杀】或【决斗】的合法目标。",
["$sr_jiexi"] = "伙计们，一口气拿下！",
["$sr_youxia1"] = "给我打他个措手不及！",
["$sr_youxia2"] = "这下要再不打，可就晚了！",
["~sr_ganning"] = "坏了，这下跑不了！",
["losesr_jiexi"] = "失去【劫袭】",
["losesr_youxia"] = "失去【游侠】",
}

--SR黄盖
sr_huanggai = sgs.General(extension, "sr_huanggai", "wu", 4)

--舟焰
sr_zhouyancard = sgs.CreateSkillCard{
	name = "sr_zhouyancard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
			return to_select:objectName() ~= sgs.Self:objectName() and 
			not sgs.Self:isProhibited(to_select, fireattack)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		while not source:hasFlag("srzhouyannotdo") do
			local dest = targets[1]
			if not dest:isAlive() then return end			
			room:notifySkillInvoked(source, "sr_zhouyan")
			room:setPlayerFlag(source, "srzhouyannotdo")
			dest:drawCards(1)
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
			fireattack:setSkillName("sr_zhouyan")
			fireattack:deleteLater()
			local use = sgs.CardUseStruct()
			use.card = fireattack
			use.from = source
			use.to:append(dest)
			room:useCard(use)
		end
	end
}
sr_zhouyanvs = sgs.CreateViewAsSkill{
	name = "sr_zhouyan",
	n = 0,
	view_as = function(self, cards)
		return sr_zhouyancard:clone()		
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("srzhouyannotdo")
	end
}

sr_zhouyan = sgs.CreateTriggerSkill{
	name = "sr_zhouyan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	view_as_skill = sr_zhouyanvs,  
	on_trigger = function(self, event, player, data, room) 
		
		local damage = data:toDamage()
		local card = damage.card
		if card:isKindOf("FireAttack") then
			if room:askForSkillInvoke(player,"sr_zhouyan_draw",data) then
				room:notifySkillInvoked(player,"sr_zhouyan")
				room:broadcastSkillInvoke("sr_zhouyan")
				player:drawCards(1)
				room:setPlayerFlag(player, "-srzhouyannotdo")
			end
		end
		return false
	end
}

sr_huanggai:addSkill(sr_zhouyan)

--诈降
-- sr_zhaxiangcard = sgs.CreateSkillCard{
-- 	name = "sr_zhaxiangcard",
-- 	target_fixed = false,
-- 	will_throw = false,
-- 	filter = function(self, targets, to_select)
-- 		if #targets == 0 then
-- 			return to_select:objectName() ~= sgs.Self:objectName() and to_select:canSlash(sgs.Self, nil, false)
-- 		end
-- 		return false
-- 	end,
-- 	on_use = function(self, room, source, targets)
-- 		room:notifySkillInvoked(source, "sr_zhaxiang")
-- 		local dest = targets[1]
-- 		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
-- 		slash:setSkillName("sr_zhaxiang")
-- 		local use = sgs.CardUseStruct()
-- 		use.card = slash
-- 		use.from = dest
-- 		use.to:append(source)
-- 		room:useCard(use)
-- 		if source:isAlive() then
-- 			if source:canSlash(dest, nil, false) then
-- 				local choice = room:askForChoice(source, "sr_zhaxiang", "srzhaxiangslash+cancel")
-- 				if choice == "srzhaxiangslash" then
-- 					source:drawCards(1)
-- 					local useback = sgs.CardUseStruct()
-- 					useback.card = slash
-- 					useback.from = source
-- 					useback.to:append(dest)
-- 					room:useCard(useback, false)
-- 				end
-- 			end
-- 		end
-- 	end
-- }
-- sr_zhaxiang = sgs.CreateViewAsSkill{
-- 	name = "sr_zhaxiang",
-- 	n = 0,
-- 	view_as = function(self, cards)
-- 		return sr_zhaxiangcard:clone()
-- 	end,
-- 	enabled_at_play = function(self, player)
-- 		return not player:hasUsed("#sr_zhaxiangcard") 
-- 	end
-- }
sr_zhaxiangcard = sgs.CreateSkillCard{
	name = "sr_zhaxiangcard",
	target_fixed =true,
	will_throw = false,	
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_zhaxiang")
		local cid = self:getSubcards():first()
		local c = sgs.Sanguosha:getCard(cid)
		room:setTag("zhaxiang",sgs.QVariant(c:objectName()))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(),"sr_zhaxiang", nil)		
		local move = sgs.CardsMoveStruct(self:getSubcards(),source,nil,sgs.Player_PlaceHand,
			sgs.Player_DrawPile,reason)
		room:moveCardsAtomic(move,false)		
		local dest = room:askForPlayerChosen(source,room:getOtherPlayers(source),"sr_zhaxiang")
		room:removeTag("zhaxiang")
		if not dest then 
			source:obtainCard(self)
			return
		end
		local choice = ""
		if dest:isNude() then
			choice = "srshow"
		else
			choice = room:askForChoice(dest,"sr_zhaxiang","srshow+srgive")
		end
		if choice == "srgive" then
			local card = room:askForExchange(dest, "sr_zhaxiang", 1, 1, true, "#srzhaxiang:"..source:objectName())
			if not card then return end
			source:obtainCard(card)
			room:throwCard(self,nil,dest)
			return
		else
			local cardid = self:getSubcards():first()
			local card = sgs.Sanguosha:getCard(cardid)
			room:showCard(dest,cardid)
			dest:obtainCard(self)
			if card:isKindOf("Slash") then
				local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("sr_zhaxiang")
				slash:deleteLater()
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = source
				use.to:append(dest)
				room:useCard(use,false)
			end
		end
	end
}
sr_zhaxiang = sgs.CreateViewAsSkill{
	name = "sr_zhaxiang",
	n = 1, 
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sr_zhaxiangcard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#sr_zhaxiangcard")
	end
}
sr_huanggai:addSkill(sr_zhaxiang)
sr_huanggai:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_huanggai"] = "SR黄盖",
["#sr_huanggai"] = "舍命一搏",
["&sr_huanggai"] = "黄盖",
["sr_zhouyan"] = "舟焰",
["sr_zhouyancard"] = "舟焰",
[":sr_zhouyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色摸一张牌，若"..
"如此做，视为你对其使用一张【火攻】，你可以重复此流程直到你以此法未造成伤害。每当你使用【火攻】造成一次"..
"伤害后，你可以摸一张牌",
["sr_zhouyan_draw"] = "舟焰摸牌",
["sr_zhaxiang"] = "诈降",
["sr_zhaxiangcard"] = "诈降",
["srzhaxiangslash"] = "摸一张牌并视为对其使用一张【杀】",
-- [":sr_zhaxiang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名其他角色，视为该"..
--"角色对你使用一张【杀】，以此法使用的【杀】结算后，你可以摸一张牌，然后视为对其使用一张【杀】。",
[":sr_zhaxiang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌扣置于牌堆顶，然"..
"后令一名其他角色选择一项：交给你一张牌并弃置此牌；或展示并获得此牌，若为【杀】，则视为你对其使用一张火"..
"属性的【杀】（不计入出牌阶段的使用限制）。",
["#srzhaxiang"] = "选择一张交给 %src 的牌",
["srshow"] = "展示此牌",
["srgive"] = "交出一张牌",
["$sr_zhouyan"] = "待老夫来会会你！",
["$sr_zhaxiang"] = "肝脑涂地，无以为报！",
["~sr_huanggai"] = "这条老命，已是风中之烛！",
["losesr_zhouyan"] = "失去【舟焰】",
["losesr_zhaxiang"] = "失去【诈降】",
}

--SR大乔
sr_daqiao = sgs.General(extension,"sr_daqiao","wu",3,false)

--芳馨
sr_fangxincard = sgs.CreateSkillCard{
	name = "sr_fangxincard",
	target_fixed = true,
	will_throw = false,
	mute = true,	
	on_use = function(self,room,source,targets)		
	    local cardid = self:getSubcards():first()
	    local card = sgs.Sanguosha:getCard(cardid)
	    if card:getSuit() == sgs.Card_Diamond then
	    	local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
	    	indulgence:addSubcard(card)
	    	indulgence:setSkillName("sr_fangxin")
	    	room:useCard(sgs.CardUseStruct(indulgence,source,source))
	    elseif card:getSuit() == sgs.Card_Club then
	    	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,card:getNumber())
	    	supply_shortage:addSubcard(card)
	    	supply_shortage:setSkillName("sr_fangxin")
	    	room:useCard(sgs.CardUseStruct(supply_shortage,source,source))
	    end
	    local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit, 0)
	    peach:setSkillName("sr_fangxin")	    
	    room:broadcastSkillInvoke("sk_fangxin")
	    local dest = source
	    local dying = room:getCurrentDyingPlayer()
	    if dying then
	    	dest = dying
	    end
	    if not dest:isWounded() then return end
	    room:useCard(sgs.CardUseStruct(peach,source,dest))	       	
	end	    
}

sr_fangxin = sgs.CreateViewAsSkill{
	name = "sr_fangxin",
	n=1,
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
		if sgs.Self:containsTrick("indulgence") then 
			return to_select:getSuit() == sgs.Card_Club
		elseif sgs.Self:containsTrick("supply_shortage") then
			return to_select:getSuit() == sgs.Card_Diamond 
		else
			return to_select:getSuit() == sgs.Card_Club or to_select:getSuit() == sgs.Card_Diamond
		end
		return false	
	end,	
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end		
		local acard = sr_fangxincard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName("sr_fangxin")		
		return acard
	end,
	enabled_at_play = function(self,player)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
		return player:isWounded() and 
		not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")))
	end,
	enabled_at_response = function(self,player,pattern)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
		return string.find(pattern,"peach") and not (player:getMark("Global_PreventPeach") > 0) and
		not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")))
	end	
}

sr_daqiao:addSkill(sr_fangxin)

--细语
sr_xiyu = sgs.CreateTriggerSkill{
	name = "sr_xiyu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		local targets = sgs.SPlayerList()
		
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if not p:isNude() and player:canDiscard(p,"he") then
				targets:append(p)
			end
		end
		if targets:isEmpty() or not player:askForSkillInvoke(self:objectName(),data) then return false end
		room:broadcastSkillInvoke("sr_xiyu")
		local target = room:askForPlayerChosen(player,targets,self:objectName())
		if not target then return false end
		local to_throw = room:askForCardChosen(player,target,"he",self:objectName())
		local card = sgs.Sanguosha:getCard(to_throw)
		room:throwCard(card, target, player)		
		local log1 = sgs.LogMessage()
		log1.type ="#sr_xiyu"
		log1.from = target
		log1.arg = "play"
		room:sendLog(log1)
		local phase = player:getPhase()--保存阶段
		player:setPhase(sgs.Player_NotActive)--角色设置回合外
		room:broadcastProperty(player,"phase")
		room:setCurrent(target)--设置目标为当前回合
		target:setPhase(sgs.Player_Play)		--设置目标出牌阶段
		room:broadcastProperty(target, "phase")
		local thread = room:getThread()
		if not thread:trigger(sgs.EventPhaseStart,room,target) then			
			thread:trigger(sgs.EventPhaseProceeding,room,target)
		end		
		thread:trigger(sgs.EventPhaseEnd,room,target)		
		target:setPhase(sgs.Player_NotActive)	--设置目标回合外	
		room:broadcastProperty(target,"phase")
		room:setCurrent(player) --设置当前回合为玩家
		player:setPhase(phase) --设置玩家保存的阶段
		room:broadcastProperty(player,"phase")		
		return false
	end
}

sr_daqiao:addSkill(sr_xiyu)

sr_wanrou = sgs.CreateTriggerSkill{
	name = "sr_wanrou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
				
		local move = data:toMoveOneTime()		
		if not move.from or (not move.from:hasSkill(self:objectName())) or move.from:objectName() ~= player:objectName() then return false end
		if move.to_place ~= sgs.Player_DiscardPile then return false end
		for _, id in sgs.qlist(move.card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if not player:askForSkillInvoke(self:objectName(), data) then break end
				local target = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				target:drawCards(1)		
			else
			    if card:getSuit() == sgs.Card_Diamond then
				    if not player:askForSkillInvoke(self:objectName(), data) then break end
					local target = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				    target:drawCards(1)
				end
			end			
		end
		return false
	end
}

sr_daqiao:addSkill(sr_wanrou)
sr_daqiao:addSkill("#choose")

sgs.LoadTranslationTable{
	["sr_daqiao"] = "SR大乔",
	["#sr_daqiao"] = "韶光易逝",
	["&sr_daqiao"] = "大乔",
	["sr_fangxin"] = "芳馨",
	[":sr_fangxin"] = "当你需要使用一张【桃】时，你可以将一张<font color=\"black\"><b> ♣ </b></font>牌"..
	"当【兵粮寸断】或将一张<font color=\"red\"><b> ♦ </b></font>牌当【乐不思蜀】对自己使用，"..
	"若如此做，视为你使用一张【桃】",
	["sr_xiyu"] = "细语",
	[":sr_xiyu"] = "你的回合开始时，你可以弃置一名角色的一张牌，然后该角色进行一个额外的出牌阶段",
	["#sr_xiyu"] = "%from进入了一个额外的%arg阶段",
	["sr_wanrou"] = "婉柔",
	[":sr_wanrou"] = "你的<font color=\"red\"><b>♦</b></font>牌或你判定区的牌进入弃牌堆时，你可以令一名角"..
	"色摸一张牌",
	["$sr_fangxin1"] = "您，累了",
	["$sr_fangxin2"] = "不知您为何事烦恼",
	["$sr_xiyu"] = "让您费心了",
	["$sr_wanrou"] = "我准备好了",
	["~sr_daqiao"] = "青灯常伴，了此余生",
	["losesr_fangxin"] = "失去【芳馨】",
	["losesr_xiyu"] = "失去【细语】",
	["losesr_wanrou"] = "失去【婉柔】",
}

--SR孙尚香
sr_sunshangxiang = sgs.General(extension,"sr_sunshangxiang","wu",3,false)

--姻盟
sr_yinmengcard = sgs.CreateSkillCard{
	name = "sr_yinmengcard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName() and
			to_select:isMale() and not to_select:isKongcheng()
	end,
	on_use = function(self,room,source,targets)
		room:notifySkillInvoked(source,"sr_yinmeng")
		local id = room:askForCardChosen(source, targets[1], "h", "sr_yinmeng")
		local card1 = sgs.Sanguosha:getCard(id) 					
		room:showCard(targets[1], card1:getEffectiveId()) 
		room:setTag("yinmengid",sgs.QVariant(id))
		room:setPlayerFlag(targets[1],"yinmengname")
		local card2 = room:askForCardShow(source, source, "sr_yinmeng")
		room:removeTag("yinmengid")
		room:setPlayerFlag(targets[1],"-yinmengname")
		room:showCard(source, card2:getEffectiveId()) 
		if card1:getTypeId() == card2:getTypeId() then
			if source:isAlive() then source:drawCards(1) end
			if targets[1]:isAlive() then targets[1]:drawCards(1) end
		else
			if source:canDiscard(targets[1],card1:getEffectiveId()) then
				room:throwCard(card1,targets[1],source)
			end
		end
	end
}

sr_yinmeng = sgs.CreateViewAsSkill{
	name = "sr_yinmeng",
	n=0,
	view_as = function(self,cards)
		return sr_yinmengcard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:isKongcheng() and player:usedTimes("#sr_yinmengcard") < math.max(player:getLostHp(),1) 
	end
}

sr_sunshangxiang:addSkill(sr_yinmeng)

--习武
sr_xiwu = sgs.CreateTriggerSkill{
	name = "sr_xiwu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed,sgs.CardResponded,sgs.CardFinished, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or not use.card or not use.card:isKindOf("Slash") or 
				not use.from:hasSkill(self:objectName()) 
				or	use.from:objectName() ~= player:objectName() then return false end
			room:setPlayerFlag(use.from,"srxiwusource")
			for _,p in sgs.qlist(use.to) do
				room:setPlayerFlag(p,"srxiwutarget")
			end			
		elseif event == sgs.CardUsed then
			local card = data:toCardUse().card
			if not card:isKindOf("Jink") then return false end
			if not player:hasFlag("srxiwutarget") then return false end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("srxiwusource") then
					if not p:askForSkillInvoke("sr_xiwu",data) then return false end
					room:notifySkillInvoked(p,"sr_xiwu")
					room:broadcastSkillInvoke("sr_xiwu")
					if p:isAlive() then	p:drawCards(1) end
					if p:canDiscard(player,"h") then
						local id = room:askForCardChosen(p,player,"h","sr_xiwu")
						local c = sgs.Sanguosha:getCard(id)
						room:throwCard(c,player,p)
					end
				end
			end
		else
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			if not use.from or not use.from:hasFlag("srxiwusource") then return false end
			room:setPlayerFlag(use.from,"-srxiwusource")
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("srxiwutarget") then
					room:setPlayerFlag(p,"-srxiwutarget")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

sr_sunshangxiang:addSkill(sr_xiwu)

--决裂
sr_jueliecard = sgs.CreateSkillCard{
	name = "sr_jueliecard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self,targets,to_select)
		return #targets == 0 and to_select:getHandcardNum() ~= sgs.Self:getHandcardNum() and
		to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		local choice = ""
		if source:getHandcardNum() < targets[1]:getHandcardNum() and not targets[1]:canDiscard(targets[1],"h") and
			not source:canSlash(targets[1],nil,false) then 
			room:addPlayerHistory(source,"#sr_jueliecard",-1)
			return 
		end 
		room:notifySkillInvoked(source,"sr_juelie")
		if source:getHandcardNum() < targets[1]:getHandcardNum() and not targets[1]:canDiscard(targets[1],"h") then
			choice = "srslash"
		elseif not source:canSlash(targets[1],nil,false) then
			choice = "srkeepsame"
		else
			choice = room:askForChoice(targets[1],"sr_juelie","srslash+srkeepsame")
		end
		if choice == "srslash" then
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:setSkillName("sr_juelie")
			slash:deleteLater()
			room:useCard(sgs.CardUseStruct(slash,source,targets[1]),false)
		elseif choice == "srkeepsame" then
			local snum = source:getHandcardNum()
			local tnum = targets[1]:getHandcardNum()
			if snum < tnum then
				if targets[1]:canDiscard(targets[1],"h") then
					room:askForDiscard(targets[1],"sr_juelie",tnum - snum,tnum - snum)
				end
			elseif snum>tnum then
				if targets[1]:isAlive() then targets[1]:drawCards(snum-tnum) end
			else
				return
			end
		else
			room:addPlayerHistory(source,"#sr_jueliecard",-1)
			return
		end
	end
}

sr_juelie = sgs.CreateViewAsSkill{
	name = "sr_juelie",
	n = 0,
	view_as = function(self,cards)
		return sr_jueliecard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sr_jueliecard")
	end
}

sr_sunshangxiang:addSkill(sr_juelie)
sr_sunshangxiang:addSkill("#choose")

sgs.LoadTranslationTable{
	["sr_sunshangxiang"] = "SR孙尚香",
	["#sr_sunshangxiang"] = "不让须眉",
	["&sr_sunshangxiang"] = "孙尚香",
	["sr_yinmeng"] = "姻盟",
	[":sr_yinmeng"] = "<font color=\"green\"><b>出牌阶段限X次，</b></font>若你有手牌，你可以展示一名其他男"..
	"性角色的一张手牌，然后展示你的一张手牌，若两张类型相同，你与其各摸一张牌；若不同，你弃置其展示的牌，"..
	"<font color=\"red\"><b>X为你已损失的体力且至少为1</b></font>",
	["$sr_yinmeng"] = "君心知我心，君意共我意。",
	["sr_xiwu"] = "习武",
	[":sr_xiwu"] = "当你使用的【杀】被目标角色的【闪】响应后，你可以摸一张牌，然后弃置其一张手牌",
	["$sr_xiwu"] = "决不允许你这般胡来！", 
	["sr_juelie"] = "决裂",
	[":sr_juelie"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名手牌数与你不同的其他"..
	"角色选择一项：将手牌数调整至与你相等；或视为你对其使用一张杀（不计入出牌阶段的使用限制）",
	["$sr_juelie"] = "休要小看我！",
	["~sr_sunshangxiang"] = "不，我不能输！",
	["srkeepsame"] = "调整手牌",
	["srslash"] = "视为被杀",
	["losesr_yinmeng"] = "失去【姻盟】",
	["losesr_xiwu"] = "失去【习武】",
	["losesr_juelie"] = "失去【决裂】",
}

--SR曹操
sr_caocao = sgs.General(extension,"sr_caocao$","wei",4)

--招降
sr_zhaoxiang = sgs.CreateTriggerSkill{
	name = "sr_zhaoxiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		for _, srcaocao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if use.from and use.from:objectName() ~= srcaocao:objectName() and use.from:objectName() == player:objectName() then
				local source, card, targets, nullified_list = use.from, use.card, use.to, use.nullified_list
				if not card:isKindOf("Slash") then return false end
				for _, t in sgs.qlist(targets) do		
					local cando = false
					if srcaocao:inMyAttackRange(source) or (not srcaocao:inMyAttackRange(source) and srcaocao:getCards("he") > 0) then cando = true end
					if cando then
						-- local _data = sgs.QVariant()
						-- _data:setValue(use.from)
						if srcaocao:askForSkillInvoke(self:objectName(), data) then
							local will_zhaoxiang = 0
							if srcaocao:inMyAttackRange(source) then
								will_zhaoxiang = 1
							else
								if not srcaocao:isNude() then
									if room:askForCard(srcaocao, "..", "srzhaoxiangdiscard", sgs.QVariant(), sgs.Card_MethodDiscard) then
										will_zhaoxiang = 1
									end
								end
							end
							if will_zhaoxiang == 1 then
								room:doAnimate(1, srcaocao:objectName(), source:objectName())
								room:notifySkillInvoked(srcaocao, "sr_zhaoxiang")
								room:broadcastSkillInvoke("sr_zhaoxiang")
								if source:isKongcheng() then
									table.insert(nullified_list, t:objectName())
								else
									local choice = room:askForChoice(source, self:objectName(),
									"srzhaoxianggetcard+srzhaoxiangslashnullified",data)
									if choice == "srzhaoxianggetcard" then
										local card_id = room:askForCardChosen(srcaocao, source, "h", "sr_zhaoxiang")
										room:obtainCard(srcaocao, card_id, false)
									elseif choice == "srzhaoxiangslashnullified" then
										table.insert(nullified_list, t:objectName())
									end
								end
							end
							if source:isDead() or srcaocao:isDead() then break end
						end
					end
				end
				if #nullified_list > 0 then
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
			return false
		end
	end
}
sr_caocao:addSkill(sr_zhaoxiang)


--治世
sr_zhishicard = sgs.CreateSkillCard{
	name = "sr_zhishicard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_zhishi")		
		local card = room:askForCard(targets[1],"BasicCard","#srbasic:" .. source:objectName())
		if not card then
			room:damage(sgs.DamageStruct("sr_zhishi",source,targets[1]))
		end
		if targets[1]:isAlive() and targets[1]:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(targets[1], recover)
		end
	end
}
sr_zhishi = sgs.CreateViewAsSkill{
	name = "sr_zhishi", 
	n = 0, 	
	view_as = function(self, cards) 
		return sr_zhishicard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_zhishicard")
	end
}
sr_caocao:addSkill(sr_zhishi)

--奸雄
sr_jianxiong = sgs.CreateTriggerSkill{
	name = "sr_jianxiong$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data, room)
		
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if not damage.from:hasLordSkill(self:objectName()) then
				local id = card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					local card_data = sgs.QVariant()
					card_data:setValue(card)
					local srcaocaos = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasLordSkill(self:objectName()) then
							srcaocaos:append(p)
						end
					end
					while not srcaocaos:isEmpty() do
						if not player:isKongcheng() then
							local srcaocao = room:askForPlayerChosen(player, srcaocaos, self:objectName(), 
								"@sr_jianxiong-to", true)
							if srcaocao and room:getCardPlace(id) == sgs.Player_PlaceTable then
								room:askForDiscard(player, self:objectName(), 1, 1, false, false)
								room:notifySkillInvoked(srcaocao, "sr_jianxiong")
								room:broadcastSkillInvoke("sr_jianxiong")
								local log = sgs.LogMessage()
								log.type = "#TriggerSkill"
								log.from = srcaocao
								log.arg = self:objectName()
								room:sendLog(log)
								room:obtainCard(srcaocao, card, true)
								srcaocaos:removeOne(srcaocao)
							else
								break
							end
						else
							break
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "wei")
	end
}
sr_caocao:addSkill(sr_jianxiong)
sr_caocao:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_caocao"] = "SR曹操",
["#sr_caocao"] = "乱世奸雄",
["&sr_caocao"] = "曹操",
["sr_zhaoxiang"] = "招降",
["srzhaoxiangdiscard"] = "你可以弃置一张牌，以便发动招降",
["srzhaoxianggetcard"] = "你被取走一张手牌，但你使用的【杀】仍然有效",
["srzhaoxiangslashnullified"] = "你防止被取走一张手牌，但你使用的【杀】失效",
[":sr_zhaoxiang"] = "当一名其他角色使用【杀】指定目标后，若该角色在你的攻击范围内，你令其选择一项：你获得其"..
"一张手牌，或此【杀】无效。若该角色不在你的攻击范围内，你可以弃置一张牌，然后令其作上述选择",
["#zhaoxiang"] = "%from 对 %to 使用的 %arg 无效",
["sr_zhishi"] = "治世",
["#sr_zhishihide"] = "治世",
[":sr_zhishi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色选择一项：弃置一张"..
"基本牌，然后回复一点体力；或受到你造成的一点伤害，然后回复1点体力",
["#srbasic"] = "你可弃置一张基本牌，或是受到%src造成的1点伤害。然后回复1点体力。",
["sr_jianxiong"] = "奸雄",
["@sr_jianxiong-to"] = "请选择一名角色使其发动“奸雄”",
["@srjianxiong-discard"] = "你可以弃置一张手牌，然后令你选择的该角色获得对你造成伤害的牌",
[":sr_jianxiong"] = "<font color=\"orange\"><b>主公技，</b></font>每当一名其他魏势力角色受到不为你造成的伤害"..
"后，该角色可以弃置一张手牌，然后令你获得对其造成伤害的牌。",
["$sr_zhaoxiang"] = "汝可愿降于我，为我所用？",
["$sr_zhishi1"] = " 需得百姓亲附，甲兵强盛。",
["$sr_zhishi2"] = "用人唯才，治世依法！",
["$sr_jianxiong"] = "宁教我负天下人，休教天下人负我！",
["~sr_caocao"] = "孤之霸业，竟有终结之时。",
["losesr_zhaoxiang"] = "失去【招降】",
["losesr_zhishi"] = "失去【治世】",
}

--SR郭嘉
sr_guojia = sgs.General(extension,"sr_guojia","wei",3)

sr_tianshang = sgs.CreateTriggerSkill{
	name = "sr_tianshang", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data, room) 
		
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = room:getOtherPlayers(player)			
			if targets:length() > 0 then				
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					room:notifySkillInvoked(player, "sr_tianshang")
					room:broadcastSkillInvoke("sr_tianshang")
					local skill_list = player:getVisibleSkillList()
					local skills = {}
					for _,skill in sgs.qlist(skill_list) do
						if skill:objectName() ~= "sr_tianshang" then
						    table.insert(skills, skill:objectName())
						end
					end
					local choice = room:askForChoice(target, self:objectName(), table.concat(skills, "+"))					
					room:handleAcquireDetachSkills(target, choice, false)
					room:setPlayerProperty(target,"maxhp",sgs.QVariant(target:getMaxHp()+1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = target
					msg.arg = 1
					room:sendLog(msg)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(target,recover)					
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}
sr_guojia:addSkill(sr_tianshang)

--遗计
sr_yiji = sgs.CreateTriggerSkill{
	name = "sr_yiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		
		local damage = data:toDamage()
		local x = damage.damage
		if player:hasSkill("nosyiji") then return false end
		if player:hasSkill("yiji") then return false end
		for i = 0, x - 1, 1 do
			if not player:isAlive() then return end
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			room:broadcastSkillInvoke("sr_yiji")
			local _guojia = sgs.SPlayerList()
			_guojia:append(player)
			local yiji_cards = room:getNCards(2, false)
			local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), 
								self:objectName(), nil))
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			local origin_yiji = sgs.IntList()
			for _, id in sgs.qlist(yiji_cards) do
				origin_yiji:append(id)
			end
			while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, 
				room:getAlivePlayers()) do
				local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, 
					sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, 
						player:objectName(), self:objectName(), nil))
				for _, id in sgs.qlist(origin_yiji) do
					if room:getCardPlace(id) ~= sgs.Player_DrawPile then
						move.card_ids:append(id)
						yiji_cards:removeOne(id)
					end
				end
				origin_yiji = sgs.IntList()
				for _, id in sgs.qlist(yiji_cards) do
					origin_yiji:append(id)
				end
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				if not player:isAlive() then return end
			end
			if not yiji_cards:isEmpty() then
				local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, 
					sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), 
								self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(yiji_cards) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy, false)
			end
		end
		return false
	end
}
sr_guojia:addSkill(sr_yiji)

--慧觑
sr_huiqu = sgs.CreateTriggerSkill{
	name = "sr_huiqu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if not player:isKongcheng() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						if room:askForDiscard(player, self:objectName(), 1, 1, false, false) then
							room:notifySkillInvoked(player, "sr_huiqu")
							room:broadcastSkillInvoke("sr_huiqu")
							local judge = sgs.JudgeStruct()
							judge.pattern = "."
							judge.good = true
							judge.reason = self:objectName()
							judge.who = player
							judge.time_consuming = true
							room:judge(judge)
						end
					end
				end
			end
		elseif event == sgs.FinishJudge then 
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isRed() then
					local targets = room:getAlivePlayers()
					local players = sgs.SPlayerList()
					for _,p in sgs.qlist(targets) do				
						if p:hasEquip() or p:getJudgingArea():length()>0 then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						local target = room:askForPlayerChosen(player, players, "sr_huiqufirst")
						local q = sgs.QVariant()
						q:setValue(target)
						room:setTag("huiquTarget",q)
						local card_id = room:askForCardChosen(player, target, "ej", self:objectName())
						local card = sgs.Sanguosha:getCard(card_id)
						local place = room:getCardPlace(card_id)
						local playermoves = sgs.SPlayerList()
						if place == sgs.Player_PlaceEquip then
							local equip = card:getRealCard():toEquipCard()
							local index = equip:location()
							for _,p in sgs.qlist(targets) do
								if p:getEquip(index) == nil then
									playermoves:append(p)
								end
							end
						elseif place == sgs.Player_PlaceDelayedTrick then
							for _,p in sgs.qlist(targets) do
								if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
									playermoves:append(p)
								end
							end
						end
						if not playermoves:isEmpty() then
							local playermove = room:askForPlayerChosen(player, playermoves, self:objectName())
							room:removeTag("huiquTarget")
							if playermove then
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,
									player:objectName(), self:objectName(), "")
								room:moveCardTo(card, target, playermove, place, reason)
							end
						end
					end
				elseif card:isBlack() then
					local targets = room:getAlivePlayers()
					local target = room:askForPlayerChosen(player, targets, "sr_huiqudamage")
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = target
					room:damage(damage)
					if target:isAlive() then
						target:drawCards(1)
					end
				end
			end
		end
		return false
	end
}
sr_guojia:addSkill(sr_huiqu)
sr_guojia:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_guojia"] = "SR郭嘉",
["#sr_guojia"] = "天妒英才",
["&sr_guojia"] = "郭嘉",
["sr_yiji"] = "遗计",
[":sr_yiji"] = "每当你受到1点伤害后，你可以观看牌堆顶的两张牌，然后将一张牌交给一名角色，将另一张牌交给一名角色。",
["$sr_yiji"] = "速战速决吧",
["sr_tianshang"] = "天殇",
[":sr_tianshang"] = "你死亡时，可令一名其他角色获得你当前的另一项技能,然后其增加一点体力上限并回复一点体力。",
["sr_huiqu"] = "慧觑",
["sr_huiqudamage"] = "慧觑",
["sr_huiqufirst"] = "慧觑",
[":sr_huiqu"] = "回合开始阶段开始时，你可以弃置一张手牌并进行一次判定，若结果为红色，你将场上的一张牌移动到另一个相"..
"应的位置；若结果为黑色，你对一名角色造成1点伤害，然后该角色摸一张牌。",
["$sr_tianshang"] = "唉，只能等待奇迹。",
["$sr_huiqu"] = "且看你如何化解。",
["~sr_guojia"] = "岂能尽如人意。",
["losesr_tianshang"] = "失去【天殇】",
["losesr_huiqu"] = "失去【慧觑】",
["losesr_yiji"] = "失去【遗计】",
}

--SR许褚
sr_xuchu = sgs.General(extension,"sr_xuchu","wei",4)

--鏖战
sr_aozhanCard = sgs.CreateSkillCard{
	name = "sr_aozhanCard", 
	target_fixed = true,
	will_throw = false,
	mute = true, 
	on_use = function(self, room, source, targets)
		local cards = source:getPile("@srzhan")		
		local dummycard = sgs.Sanguosha:cloneCard("jink")
		dummycard:deleteLater()
		for _,card_id in sgs.qlist(cards) do
			dummycard:addSubcard(card_id)
		end		
		local choice = room:askForChoice(source, "sr_aozhan", "sraozhanget+sraozhandraw")
		room:broadcastSkillInvoke("sr_aozhan", 2)
		if choice == "sraozhanget" then
			room:obtainCard(source, dummycard, true)
		elseif choice == "sraozhandraw" then 
			local count = dummycard:subcardsLength()
			room:throwCard(dummycard, nil,source)
			source:drawCards(count, "sr_aozhan")
		end
	end
}
sr_aozhanVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_aozhan", 
	view_as = function()
		return sr_aozhanCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getPile("@srzhan"):length() > 0 then
			return not player:hasUsed("#sr_aozhanCard")
		end
		return false
	end
}

sr_aozhan = sgs.CreateTriggerSkill{
	name = "sr_aozhan", 
	view_as_skill = sr_aozhanVS,
	events = {sgs.Damage, sgs.Damaged}, 
	on_trigger = function(self, event, player, data, room)		
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") or card:isKindOf("Duel") then
				if player:askForSkillInvoke("sr_aozhan", data) then
					room:notifySkillInvoked(player, "sr_aozhan")
					room:broadcastSkillInvoke("sr_aozhan", 1)
					local x = damage.damage
					for i=1, x, 1 do
						local id = room:drawCard()
						player:addToPile("@srzhan", id, true)
					end
				end
			end
		end		
		return false
	end
}


sr_xuchu:addSkill(sr_aozhan)


--虎啸
sr_huxiao = sgs.CreateTriggerSkill{
	name = "sr_huxiao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},  
	on_trigger = function(self, event, player, data, room) 
		
		local damage = data:toDamage()
		local slash = damage.card
		local victim = damage.to
		if damage.chain then return false end
		if damage.transfer then return false end
		if player:faceUp() then
			if victim and victim:isAlive() then
				if slash and slash:isKindOf("Slash") then
					if player:getPhase() == sgs.Player_Play then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:notifySkillInvoked(player, "sr_huxiao")
							room:broadcastSkillInvoke("sr_huxiao")
							room:setPlayerMark(player, "usedsrhuxiao", 1)
							room:doAnimate(1, player:objectName(), victim:objectName())
							damage.damage = damage.damage + 1
							player:drawCards(1)	
							local msg = sgs.LogMessage()
							msg.type = "#Huxiao"
							msg.from = player
							msg.to:append(damage.to)
							msg.arg = tostring(damage.damage-1)
							msg.arg2 = tostring(damage.damage)
							room:sendLog(msg)						
							data:setValue(damage)							
						end
					end
				end
			end
		end
	end
}			
sr_xuchu:addSkill(sr_huxiao)	
--虎啸造成伤害后死了……
sr_huxiaodamage = sgs.CreateTriggerSkill{
	name = "#sr_huxiaodamage",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardFinished},  
	on_trigger = function(self, event, player, data, room) 
		
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		if not use.from or use.from:objectName() ~= player:objectName() then return false end
		if player:isAlive() then
			if player:getMark("usedsrhuxiao") > 0 then
				player:turnOver()
				player:setAlive(false)
				room:broadcastProperty(player, "alive")
			end
		end
	end,
	priority = -1
}	
sr_xuchu:addSkill(sr_huxiaodamage)	
--活过来了！
sr_huxiaoback = sgs.CreateTriggerSkill{
	name = "#sr_huxiaoback",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data, room)
		
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getPlayers()) do
				if p:getMark("usedsrhuxiao") > 0 and p:getHp() > 0 then
					room:setPlayerMark(p, "usedsrhuxiao", 0)
					p:setAlive(true)
					room:broadcastProperty(p, "alive")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 9
}
sr_xuchu:addSkill(sr_huxiaoback)
extension:insertRelatedSkills("sr_huxiao","#sr_huxiaodamage")
extension:insertRelatedSkills("sr_huxiao","#sr_huxiaoback")	
sr_xuchu:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_xuchu"] = "SR许褚",
["#sr_xuchu"] = "甘效死命",
["&sr_xuchu"] = "许褚",
["sr_aozhan"] = "鏖战",
["@srzhan"] = "战",
["sraozhanget"] = "将所有的“战”收入手牌",
["sraozhandraw"] = "将所有的“战”置入弃牌堆，然后摸等量的牌",
[":sr_aozhan"] = "每当你因【杀】或【决斗】造成或受到1点伤害后，可将牌堆顶的一张牌置于你的武将牌上，称为“战”。"..
"<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一项：将所有的“战”收入手牌，或将所有的“战”置入弃牌"..
"堆，然后摸等量的牌。",
["sr_huxiao"] = "虎啸",
[":sr_huxiao"] = "出牌阶段，当你使用【杀】造成伤害时，若你的武将牌正面朝上，你可以摸一张牌，然后令此伤害+1，若如此"..
"做，则此【杀】结算后，将你的武将牌翻面，并结束当前回合。<font color=\"red\"><b>（不建议双将时用，会有各种不明问"..
"题）</b></font>",
["#Huxiao"] = "%from 发动了技能 “<font color=\"yellow\"><b>虎啸</b></font>”，对 %to 造成伤害由 %arg 点增加到 "..
"%arg2 点",
["$sr_aozhan1"] = "哈哈哈哈哈哈哈！来送死的吧！",
["$sr_aozhan2"] = "这一招如何！",
["$sr_huxiao"] = "纳命来！",
["~sr_xuchu"] = "我还能...接着打。",
["losesr_aozhan"] = "失去【鏖战】",
["losesr_huxiao"] = "失去【虎啸】",
}

--SR司马懿
sr_simayi = sgs.General(extension,"sr_simayi","wei",3)

--鬼才
sr_guicai = sgs.CreateTriggerSkill{
	name = "sr_guicai", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial}, 
	on_trigger = function(self, event, player, data, room)
		
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, "sr_guicai")
			local judge = data:toJudge()
			local choice
			if player:isKongcheng() then
				choice = "srguicailiangchu"
			else
				choice = room:askForChoice(player, self:objectName(), "srguicailiangchu+srguicaidachu",data)
			end
			if choice == "srguicailiangchu" then
				local card_id = room:drawCard()
				room:getThread():delay()
				local card = sgs.Sanguosha:getCard(card_id)
				room:broadcastSkillInvoke("sr_guicai")
				room:retrial(card, player, judge, self:objectName())
			elseif choice == "srguicaidachu" then       			
       			local prompt = "@guicai-card:"..judge.who:objectName()..":"..self:objectName()..
       			":"..judge.reason..":"..judge.card:getEffectiveId()
				local card = room:askForCard(player,  "." , prompt, data, sgs.Card_MethodResponse, judge.who, true)
				room:broadcastSkillInvoke("sr_guicai")
				room:retrial(card, player, judge, self:objectName())
			end
			return false
		end
	end,
}
sr_simayi:addSkill(sr_guicai)

--狼顾
sr_langgu = sgs.CreateTriggerSkill{
	name = "sr_langgu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		
		local damage = data:toDamage()
		local source = damage.from
		local dest = damage.to
		if damage.from and damage.to then
			if damage.from:objectName() == player:objectName() then
				source = player
				dest = damage.to
			else
				source = player
				dest = damage.from
			end
			if not dest:isNude() then				
				if room:askForSkillInvoke(source, self:objectName(), data) then
					room:notifySkillInvoked(source, "sr_langgu")
					room:broadcastSkillInvoke("sr_langgu")
					room:doAnimate(1, source:objectName(), dest:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = source
					room:judge(judge)
					if judge:isGood() then
						local card_id = room:askForCardChosen(source, dest, "he", self:objectName())
						room:obtainCard(source, card_id, false)
					end
				end				
			end
		end
		return false
	end
}
sr_simayi:addSkill(sr_langgu)

--追尊
sr_zhuizun = sgs.CreateTriggerSkill{
	name = "sr_zhuizun",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zhuizun",
	events = {sgs.Dying,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.Dying then
			local dying_data = data:toDying()
			local source = dying_data.who
			if player:getMark("@zhuizun") == 0 then return false end
			if source:objectName() == player:objectName() then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, "sr_zhuizun")
					room:broadcastSkillInvoke("sr_zhuizun")
					player:loseMark("@zhuizun")
					room:setPlayerProperty(player, "hp", sgs.QVariant(1))
					local targets = room:getOtherPlayers(player)
					local prompt = string.format("srzhuizungive:%s", player:objectName())
					for _,p in sgs.qlist(targets) do
						if not p:isKongcheng() then
							local card = room:askForExchange(p, self:objectName(), 1, 1, false, prompt)
							room:obtainCard(player, card, false)
							room:getThread():delay()
						end
					end						
					room:setPlayerMark(player, "srzhuizunudo", 1)
				end
			end			
		else
						
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("srzhuizunudo") > 0 then
					room:setPlayerMark(p, "srzhuizunudo", 0)
					room:notifySkillInvoked(p, "sr_zhuizun")
					room:broadcastSkillInvoke("sr_zhuizun")
					p:gainAnExtraTurn()
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end	
}

-- sr_zhuizunStart = sgs.CreateTriggerSkill{
-- 	name = "#sr_zhuizun",
-- 	frequency = sgs.Skill_Compulsory,
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self, event, player, data, room)
-- 		player:gainMark("@zhuizun")
-- 	end
-- }
sr_simayi:addSkill(sr_zhuizun)
-- sr_simayi:addSkill(sr_zhuizunStart)
-- extension:insertRelatedSkills("sr_zhuizun","#sr_zhuizun")
sr_simayi:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_simayi"] = "SR司马懿",
["#sr_simayi"] = "深冢之虎",
["&sr_simayi"] = "司马懿",
["sr_guicai"] = "鬼才",
["srguicailiangchu"] = "亮出牌堆顶的一张牌代替之",
["srguicaidachu"] = "打出一张手牌代替之",
["srguicaidiscard"] = "请选择一张手牌用作改判",
[":sr_guicai"] = "在一名角色的判定牌生效前，你可以选择一项：亮出牌堆顶的一张牌代替之，或打出一张手牌代替之。",
["sr_langgu"] = "狼顾",
[":sr_langgu"] = "每当你造成或受到一次伤害后，你可以进行一次判定，若结果为黑色，你获得对方的一张牌。",
["@zhuizun"] = "追尊",
["sr_zhuizun"] = "追尊",
["srzhuizungive"] = "请交给该角色(%src)一张手牌",
[":sr_zhuizun"] = "<font color=\"red\"><b>限定技，</b></font>当你进入濒死状态时，你可以回复体力至1点，令所有其他角"..
"色依次交给你一张手牌，然后当前回合结束后，你进行一个额外的回合。",
["$sr_guicai"] = "哼，我已等待多时。",
["$sr_langgu"] = "不自量力。",
["$sr_zhuizun"] = "我才是胜者 哈哈哈哈哈哈哈！",
["~sr_simayi"] = "难道全被识破了吗！",
["losesr_guicai"] = "失去【鬼才】",
["losesr_langgu"] = "失去【狼顾】",
["losesr_zhuizun"] = "失去【追尊】",
}

--SR甄姬
sr_zhenji = sgs.General(extension,"sr_zhenji","wei",3,false)

--流云
sr_liuyuncard = sgs.CreateSkillCard{
	name = "sr_liuyuncard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_liuyun")
		room:setPlayerProperty(source, "chained", sgs.QVariant(true))
		local target = targets[1]
		local gotodo = 0 
		if not target:isWounded() then
			gotodo = 2
		else
			local choice = room:askForChoice(target, "sr_liuyun", "srliuyunrecover+srliuyundrawcard")
			if choice == "srliuyunrecover" then
				gotodo = 1
			elseif choice == "srliuyundrawcard" then
				gotodo = 2
			end
		end
		if gotodo > 0 then
			if gotodo == 1 then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(target, recover)
			elseif gotodo == 2 then
				target:drawCards(2)
			end
		end
	end
}
sr_liuyun = sgs.CreateViewAsSkill{
	name = "sr_liuyun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_liuyuncard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isChained() then
			return not player:hasUsed("#sr_liuyuncard")
		end
		return false
	end
}
sr_zhenji:addSkill(sr_liuyun)

--凌波
sr_lingbo = sgs.CreateTriggerSkill{
	name = "sr_lingbo",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},  
	on_trigger = function(self, event, player, data, room) 
		if player:getPhase() == sgs.Player_Start then
			
			if not room:findPlayerBySkillName(self:objectName()) then return false end
			local srzhenji = room:findPlayerBySkillName(self:objectName())
			if srzhenji then
				if srzhenji:isChained() then
					local players = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:getCards("ej"):length()>0 then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						if room:askForSkillInvoke(srzhenji, self:objectName(), data) then
							room:notifySkillInvoked(srzhenji, "sr_lingbo")
							room:broadcastSkillInvoke("sr_lingbo")
							local target = room:askForPlayerChosen(srzhenji, players, self:objectName())
							local card_id = room:askForCardChosen(srzhenji, target, "ej", "sr_lingbo")
							room:removeTag("lingbocard")
							room:removeTag("lingboperson")
							local card = sgs.Sanguosha:getCard(card_id)
							room:setPlayerProperty(srzhenji, "chained", sgs.QVariant(false))
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
								srzhenji:objectName(), "sr_lingbo", nil)
							room:moveCardTo(card, target, nil, sgs.Player_DrawPile, reason)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
sr_zhenji:addSkill(sr_lingbo)

--倾城
sr_qingchengcard = sgs.CreateSkillCard{
	name = "sr_qingchengcard",
	target_fixed = false,
	will_throw = false,
	player = nil,
	on_use = function(self, room, source)
		player = source	
	end,
	filter = function(self,targets,to_select,player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = nil
		if player:isChained() then
			card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		else
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		end			
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and 
			not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end				
		local pattern = ""
		if not sgs.Self:isChained() then
			pattern = "slash" 
		else
			pattern = "jink"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,
	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = ""
		if not sgs.Self:isChained() then
			pattern = "slash" 
		else
			pattern = "jink"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("sr_qingcheng")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	
	on_validate = function(self, card_use)
		local zhenji = card_use.from
		local room = zhenji:getRoom()		
		if not zhenji:isChained()  then			
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(true))
			local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()			
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(card_use.from, to, use_card)
				if skill then
					local log = sgs.LogMessage()
					log.type = "#SkillAvoid"
					log.from = to
					log.arg = skill:objectName()
					log.arg2 = use_card:objectName()
					room:sendLog(log)					
					room:broadcastSkillInvoke(skill:objectName())
					card_use.to:removeOne(to)
				end
			end
			return use_card					
		else
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(false))
			local use_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()			
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(card_use.from, to, use_card)
				if skill then
					local log = sgs.LogMessage()
					log.type = "#SkillAvoid"
					log.from = to
					log.arg = skill:objectName()
					log.arg2 = use_card:objectName()
					room:sendLog(log)					
					room:broadcastSkillInvoke(skill:objectName())
					card_use.to:removeOne(to)
				end
			end
			return use_card					
		end		
	end,
	on_validate_in_response = function(self, zhenji)
		local room = zhenji:getRoom()			
		if not zhenji:isChained()  then
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(true))
			local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()
			return use_card						
		else
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(false))
			local use_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()
			return use_card				
		end		
	end,	
}

sr_qingcheng = sgs.CreateViewAsSkill{
	name = "sr_qingcheng",
	n = 0,
	view_as = function(self, cards)
		return sr_qingchengcard:clone()
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			return not player:isChained()
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			return not player:isChained()
		elseif pattern == "jink" then
			return player:isChained()
		end
		return false
	end
}

sr_zhenji:addSkill(sr_qingcheng)
sr_zhenji:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_zhenji"] = "SR甄姬",
["#sr_zhenji"] = "月下凌波",
["&sr_zhenji"] = "甄姬",
["sr_liuyun"] = "流云",
["srliuyunrecover"] = "回复1点体力",
["srliuyundrawcard"] = "摸两张牌",
[":sr_liuyun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以横置你的武将牌并弃置一张黑"..
"色牌，然后令一名角色选择一项：回复1点体力，或摸两张牌。",
["sr_lingbo"] = "凌波",
[":sr_lingbo"] = "一名角色的回合开始阶段结束时，你可以重置你的武将牌，然后将场上的一张牌置于牌堆顶。",
["sr_qingcheng"] = "倾城",
[":sr_qingcheng"] = "你可以横置你的武将牌，视为你使用或打出一张【杀】；你可以重置你的武将牌，视为你使用"..
"或打出一张【闪】。",
["$sr_liuyun"] = "仿佛兮若轻云之蔽月。",
["$sr_lingbo"] = "飘摇兮若流风之回雪。",
["$sr_qingcheng"] = "寒辞未吐，气若幽兰。",
["~sr_zhenji"] = "悼良会之永绝兮…哀已逝而异乡……",
["losesr_liuyun"] = "失去【流云】",
["losesr_lingbo"] = "失去【凌波】",
["losesr_qingcheng"] = "失去【倾城】",
}

--SR夏侯惇
sr_xiahoudun = sgs.General(extension,"sr_xiahoudun","wei",4,true)

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local patterns = {"slash", "jink", "peach", "analeptic"}
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end

local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}

sr_xiahoucard = sgs.CreateSkillCard{
	name = "sr_xiahoucard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local xiahou
	    for _, p in sgs.qlist(room:getAlivePlayers()) do
		    if p:hasSkill("sr_zhonghou") then
			    xiahou = p
			    break
		    end
	    end
		if not xiahou or xiahou:isDead() then 
		    room:setPlayerFlag(player, "xiahouused")
		end
		if not (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or 
			sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local choices={}			
			if source:isWounded() then
				table.insert(choices,"peach")
			end
			if sgs.Slash_IsAvailable(source) then
				for _,c in ipairs(patterns) do
					if string.find(c,"slash") then
						table.insert(choices,c)
					end
				end
			end
			local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
			Analeptic:deleteLater()
			if Analeptic:isAvailable(source) then
				table.insert(choices,"analeptic")
			end
			if #choices == 0 then return end
			local choice = room:askForChoice(source,"sr_xiahou",table.concat(choices,"+"))			
			if string.find(choice,"slash") then
				local victims  = sgs.SPlayerList()
				local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				slash:deleteLater()
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if source:canSlash(p,slash,true) then
						victims:append(p)
					end
				end
				if victims:isEmpty() then return end
				local player = room:askForPlayerChosen(source,victims,"sr_xiahou","@sr_xiahou:"..choice,false,true)
				if player then
					local msg = sgs.LogMessage()
					msg.type = "#Guhuo"
					msg.from = source
					msg.to:append(player)
					msg.arg = choice
					msg.arg2 = "sr_xiahou"	
					room:sendLog(msg)				
					local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
					room:setPlayerFlag(source,"xiahouused")
					if c == "srcancel" then return end
					room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
					local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
					slash:deleteLater()
					room:useCard(sgs.CardUseStruct(slash,source,player))
					return
				end
			elseif choice == "peach" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
				local peach = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				peach:deleteLater()
				room:useCard(sgs.CardUseStruct(peach,source,source))
				return
			elseif choice == "analeptic" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
				local analeptic = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				analeptic:deleteLater()
				room:useCard(sgs.CardUseStruct(analeptic,source,source))
				return
			end
		else									
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if  pattern == "slash" then
				local choices={}
				for _,c in ipairs(patterns) do
					if string.find(c,"slash") then
						table.insert(choices,c)
					end
				end
				local choice = room:askForChoice(source,"sr_xiahouresponse",table.concat(choices,"+"))
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
				local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				slash:deleteLater()
				room:provide(slash)
				return
			elseif pattern == "jink" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = pattern
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
				local jink = sgs.Sanguosha:cloneCard(pattern,sgs.Card_NoSuit,0)
				jink:deleteLater()
				room:provide(jink)
				return
			else
				local choices={}				
				if source:getMark("Global_PreventPeach") == 0 then
					table.insert(choices,"peach")
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						if room:getCurrentDyingPlayer():objectName() == room:getCurrent():objectName() then
							table.insert(choices,"analeptic")
						end
					end
					local choice = room:askForChoice(source,"sr_xiahousave",table.concat(choices,"+"))
					local msg = sgs.LogMessage()
					msg.type = "#GuhuoNoTarget"
					msg.from = source				
					msg.arg = choice
					msg.arg2 = "sr_xiahou"	
					room:sendLog(msg)	
					local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
					room:setPlayerFlag(source,"xiahouused")
					if c == "srcancel" then return end
					room:loseHp(xiahou, 1, true, xiahou, "sr_xiahou")
					local peach = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
					peach:deleteLater()
					room:useCard(sgs.CardUseStruct(peach,source,room:getCurrentDyingPlayer()))
					return
				end
			end
		end
		return
	end
}

sr_xiahou = sgs.CreateViewAsSkill{
	name = "sr_xiahou",
	n = 0,
	view_as = function(self,cards)
		return sr_xiahoucard:clone()
	end,
	enabled_at_play = function(self,player)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
		Analeptic:deleteLater()
		if (not sgs.Slash_IsAvailable(player)) and (not Analeptic:isAvailable(player)) and 
			(not player:isWounded()) then return false end
		if player:hasUsed("#sr_xiahoucard") then return false end
		if player:hasFlag("xiahouused") then return false end
		return true
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:hasFlag("xiahouused") then return false end
		if string.find(pattern,"peach") then
			return player:getMark("Global_PreventPeach") == 0
		end
		return pattern == "slash" or pattern == "jink"
	end,
}
sr_zhonghou = sgs.CreateTriggerSkill{
	name = "sr_zhonghou",
	events = {sgs.EventPhaseChanging,sgs.CardUsed,sgs.TargetConfirming,sgs.CardFinished,sgs.Death,
	sgs.EventLoseSkill,sgs.CardAsked},	
	on_trigger = function(self, event, player, data, room)
		
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local xiahou = room:findPlayerBySkillName(self:objectName())
		if not xiahou or xiahou:isDead() then 
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(p,"-sr_xiahou")
				end
			end
			return false 
		end	
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then				
				if player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"-sr_xiahou")
				end
				if player:hasFlag("xiahouused") then
					room:setPlayerFlag(player, "-xiahouused")
				end				
			elseif change.to == sgs.Player_Play then
				if xiahou:inMyAttackRange(player) then
					if not player:hasSkill("sr_xiahou") then
						room:handleAcquireDetachSkills(player,"sr_xiahou")
					end
				end
			end
		elseif event == sgs.TargetConfirming or event == sgs.CardUsed or event == sgs.CardFinished then			
			if player:getPhase() ~= sgs.Player_Play then return false end
			if xiahou:inMyAttackRange(player) then
				if not player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"sr_xiahou")
				end
			else
				if player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"-sr_xiahou")
				end
			end	
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= xiahou:objectName() then return false end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(p,"-sr_xiahou")
				end
			end
		else
			if data:toString() == "sr_zhonghou" then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sr_xiahou") then
						room:handleAcquireDetachSkills(p,"-sr_xiahou")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target 
	end
}

sr_xiahoudun:addSkill(sr_zhonghou)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_xiahou") then skills:append(sr_xiahou) end
sgs.Sanguosha:addSkills(skills)

--刚烈
sr_ganglie = sgs.CreateTriggerSkill{
	name = "sr_ganglie",
	events = {sgs.EventPhaseStart,sgs.DamageCaused,sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					room:broadcastSkillInvoke("sr_ganglie")
					room:loseHp(player, 1, true, player, self:objectName())
					if player:isAlive() then
						room:setPlayerFlag(player,"srganglieinvoked")
					end
				end
			elseif player:getPhase() == sgs.Player_Finish then
				if player:getMark("@sr_ganglie") > 0 then
					room:notifySkillInvoked(player,"sr_ganglie")
					room:broadcastSkillInvoke("sr_ganglie")
					player:drawCards(player:getMark("@sr_ganglie"))
					room:setPlayerMark(player,"@sr_ganglie",0)
				end
			elseif player:getPhase() == sgs.Player_NotActive then
				if player:hasFlag("srganglieinvoked") then
					room:setPlayerFlag(player,"-srganglieinvoked")
				end
				if player:hasFlag("damageincreased") then
					room:setPlayerFlag(player,"-damageincreased")
				end
			end
		else 
			local damage = data:toDamage()
			if not damage.from or damage.from:isDead() or damage.from:objectName() ~= player:objectName() or
				not player:hasFlag("srganglieinvoked") or player:getPhase() == sgs.Player_NotActive then
				return false
			end
			if event == sgs.DamageCaused then
				if not player:hasFlag("damageincreased") and player:hasFlag("srganglieinvoked") then
					room:notifySkillInvoked(player,"sr_ganglie")
					room:setPlayerFlag(player,"damageincreased")
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			elseif event == sgs.Damage then
				if player:hasFlag("srganglieinvoked") then
					room:setPlayerMark(player,"@sr_ganglie",player:getMark("@sr_ganglie") + damage.damage)
				end
			end
		end
		return false
	end
}

sr_xiahoudun:addSkill(sr_ganglie)
sr_xiahoudun:addSkill("#choose")

sgs.LoadTranslationTable{
	["sr_xiahoudun"] = "SR夏侯惇",
	["#sr_xiahoudun"] = "啖睛的苍狼",
	["&sr_xiahoudun"] = "夏侯惇",
	["sr_zhonghou"] = "忠侯",
	[":sr_zhonghou"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>每当你攻击范围内的一名"..
	"角色于其出牌阶段需要使用或打出一张基本牌时，该角色可以声明之，然后你可以失去1点体力，视为该角色使用或打出此牌",
	["sr_xiahou"] = "夏侯",
	["sr_xiahousave"] = "夏侯",
	["sr_xiahouresponse"] = "夏侯",
	["sr_xiahouhelp"] = "夏侯",
	["@sr_xiahou"] = "请选择【%src】的目标",
	[":sr_xiahou"] = "当你于出牌阶段需要使用或打出一张基本牌时，你可以对<font color=\"red\"><b>SR夏侯惇</b></font>"..
	"发动【忠侯】",
	--["@@sr_xiahou"] = "请选择用来发动“忠侯”的目标角色",
	--["~sr_xiahou"] = "选择目标角色（可略过）→点确定",
	["sr_zhonghou"] = "忠侯",
	["sr_zhonghouhelp"] = "忠侯",
	["srlosehp"] = "失去体力",
	["srcancel"] = "取消",
	--["sr_zhonghou_select"] = "忠侯",
	["sr_ganglie"] = "刚烈",
	[":sr_ganglie"] = "出牌阶段开始时，你可以失去1点体力，若如此做，你本回合下一次造成的伤害+1。且本回合你每造成1点"..
	"伤害，回合结束时你便摸一张牌",
	["$sr_ganglie"] = "你能逃得掉吗",
	["@sr_ganglie"] = "刚",
	["~sr_xiahoudun"] = "这仇，早晚要报",
	["losesr_zhonghou"] = "失去【忠侯】",
	["losesr_ganglie"] = "失去【刚烈】",
}

--SR张辽
sr_zhangliao = sgs.General(extension,"sr_zhangliao","wei")

--无畏
-- sr_wuweicard = sgs.CreateSkillCard{
-- 	name = "sr_wuweicard",
-- 	target_fixed = true,
-- 	will_throw = true,
-- 	on_use = function(self,room,source,targets)
-- 		local ids = room:getNCards(3)
-- 		room:fillAG(ids)
-- 		room:getThread():delay()
-- 		room:clearAG()
-- 		--local basic = 0
-- 		local slashs = sgs.IntList()
-- 		local last = sgs.IntList()
-- 		for _,id in sgs.qlist(ids) do
-- 			local card = sgs.Sanguosha:getCard(id)
-- 			if card:isKindOf("BasicCard") then
-- 				slashs:append(id)				
-- 			else
-- 				last:append(id)
-- 			end
-- 		end		
-- 		if not slashs:isEmpty() then
-- 			for i = 1,slashs:length(),1 do
-- 				local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
-- 				slash:setSkillName("sr_wuwei")
-- 				slash:deleteLater()
-- 				local victims = sgs.SPlayerList()
-- 				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
-- 					if source:canSlash(p,slash,false) then
-- 						victims:append(p)
-- 					end
-- 				end
-- 				if victims:isEmpty() then break end
-- 				local target = room:askForPlayerChosen(source,victims,"sr_wuwei","#sr_wuwei",false,true)
-- 				if target then
-- 					room:useCard(sgs.CardUseStruct(slash,source,target),false)
-- 				else
-- 					break
-- 				end
-- 			end
-- 			for _,id in sgs.qlist(slashs) do
-- 				local card = sgs.Sanguosha:getCard(id) 
-- 				room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
	--sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
-- 					source:objectName(), "", "sr_wuwei"), true)
-- 			end
-- 		end		
-- 		if not last:isEmpty() then			
-- 			local n = 0
-- 			while n < 2 and not last:isEmpty() do
-- 				room:fillAG(last)
-- 				local id = room:askForAG(source,last,true,"sr_wuwei")
-- 				if id ~= -1 then
-- 					local card = sgs.Sanguosha:getCard(id)
-- 					source:obtainCard(card)
-- 					last:removeOne(id)
-- 					room:clearAG()
-- 					n = n + 1
-- 				else
-- 					room:clearAG()
-- 					break
-- 				end				
-- 			end
-- 			if not last:isEmpty() then
-- 				for _,id in sgs.qlist(last) do
-- 					local card = sgs.Sanguosha:getCard(id) 
-- 					room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
-- 					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,source:objectName(), "", "sr_wuwei"), true)
-- 				end
-- 			end
-- 		end
-- 	end
-- }

-- sr_wuwei = sgs.CreateViewAsSkill{
-- 	name = "sr_wuwei",
-- 	n = 2,
-- 	view_filter = function(self,selected,to_select)
-- 		return #selected < 2
-- 	end,
-- 	view_as = function(self,cards)
-- 		if #cards ~= 2 then return nil end
-- 		local scard = sr_wuweicard:clone()
-- 		scard:setSkillName("sr_ganglie")
-- 		for _,c in ipairs(cards) do
-- 			scard:addSubcard(c)
-- 		end
-- 		return scard
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		local caninvoke = false
-- 		local players = player:getSiblings()		
-- 		for _, p in sgs.qlist(players) do
-- 			if p:getHp() > player:getHp() then
-- 				caninvoke = true
-- 				break
-- 			end
-- 		end
-- 		if not caninvoke then return false end
-- 		return not player:hasUsed("#sr_wuweicard")
-- 	end
-- }
sr_wuwei = sgs.CreateTriggerSkill{
	name = "sr_wuwei",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		
		if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
		local ids = room:getNCards(3, true)
		room:fillAG(ids)
		room:getThread():delay()
		room:clearAG()
		--local basic = 0
		local slashs = sgs.IntList()
		local last = sgs.IntList()
		for _,id in sgs.qlist(ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("BasicCard") then
				slashs:append(id)				
			else
				last:append(id)
			end
		end		
		if not slashs:isEmpty() then
			for i = 1,slashs:length(),1 do
				local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				slash:setSkillName("sr_wuwei")
				slash:deleteLater()
				local victims = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(p,slash,false) then
						victims:append(p)
					end
				end
				if victims:isEmpty() then break end
				local target = room:askForPlayerChosen(player,victims,"sr_wuwei","#sr_wuwei",true,true)
				if target then
					room:useCard(sgs.CardUseStruct(slash,player,target),false)
				else
					break
				end
			end
			for _,id in sgs.qlist(slashs) do
				local card = sgs.Sanguosha:getCard(id) 
				room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
					player:objectName(), "", "sr_wuwei"), true)
			end
		end				
		if not last:isEmpty() then
			local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			dummycard:deleteLater()			
			for _,id in sgs.qlist(last) do
				local card = sgs.Sanguosha:getCard(id)
 				dummycard:addSubcard(card)
 			end
 			if player:isAlive() then
 				player:obtainCard(dummycard)
 			end			
		end
		return true
	end
}

sr_zhangliao:addSkill(sr_wuwei)

--掩杀
sr_yansha = sgs.CreateTriggerSkill{
	name = "sr_yansha",
	events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return end
			room:setPlayerFlag(player, "yansha_draw")
			if room:askForSkillInvoke(player,self:objectName(),data) then
				room:broadcastSkillInvoke("sr_yansha",1)
				room:setPlayerFlag(player,"sryanshainvoked")
				draw.num = draw.num - 1
				data:setValue(draw)
			end
			room:setPlayerFlag(player, "-yansha_draw")
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:hasFlag("sryanshainvoked") and not player:isKongcheng() then
				local card = room:askForCard(player,".","#sr_yansha",data,sgs.Card_MethodNone)
				if card then
					room:notifySkillInvoked(player,"sr_yansha")
					room:broadcastSkillInvoke("sr_yansha",1)
					player:addToPile("@yan",card,true)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:hasFlag("sryanshainvoked") then
					room:setPlayerFlag(player, "-sryanshainvoked")
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local from = use.from
			local card = use.card
			if not from then return false end
			if from:isKongcheng() then return false end
			if not card or not card:isKindOf("Slash") then return false end
			for _, zhangliao in sgs.qlist(room:findPlayersBySkillName("sr_yansha")) do
				if from:objectName() ~= zhangliao:objectName() and (not zhangliao:getPile("@yan"):isEmpty()) and zhangliao:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke("sr_yansha", 2)
					local fields = zhangliao:getPile("@yan")
					local count = fields:length()
					local id
					if count == 1 then
						id = fields:first()
					elseif count > 1 then
						room:fillAG(fields, zhangliao)
						id = room:askForAG(zhangliao, fields, true, "sr_yansha")
						room:clearAG(zhangliao)
						if id == -1 then
							return false
						end
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", zhangliao:objectName(), self:objectName(), "")
					room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
					local cards = from:getCards("h")
					for i = 0, 1, 1 do
						local n = cards:length()
						local j = math.random(0, n-1)
						local c = cards:at(j)
						cards:removeOne(c)
						dummy:addSubcard(c)
						if cards:isEmpty() then break end
					end
					if dummy:subcardsLength() > 0 then
				        room:obtainCard(zhangliao, dummy, false)
						dummy:deleteLater()
					end
				end
			end
		end
		return false
	end
}


sr_zhangliao:addSkill(sr_yansha)
sr_zhangliao:addSkill("#choose")


sgs.LoadTranslationTable{
	["sr_zhangliao"] = "SR张辽",
	["#sr_zhangliao"] = "古之召虎",
	["&sr_zhangliao"] = "张辽",
	["sr_wuwei"] = "无畏",
	-- [":sr_wuwei"] ="<font color=\"green\"><b>出牌阶段限一次，</b></font>若你的体力值不是全场最多的(或之一)"..
	--"，你可以弃置两张牌，若如此做，你展示牌堆顶的三张牌，其中每有一张基本牌，你便可以视为对一名其他角色使用"..
	--"一张【杀】(以此法使用的【杀】不计入出牌阶段的使用限制)，然后你将这些基本牌置入弃牌堆，并获得其余的一至两张牌",
	[":sr_wuwei"] ="摸牌阶段，你可以放弃摸牌，改为展示牌堆顶的三张牌，其中每有一张基本牌，你便可以视为对一名其"..
	"他角色使用一张【杀】，然后你将这些基本牌置入弃牌堆，并获得其余的牌",
	["#sr_wuwei"] = "选择一名【杀】的目标",
	["sr_yansha"] = "掩杀",
	["#sr_yanshaRob"] = "掩杀",
	[":sr_yansha"] = "摸牌阶段，你可以少摸一张牌，若如此做，则此回合结束阶段开始时，你可以将一张手牌置于你的武"..
	"将牌上，称为“掩”。当一名其他角色使用【杀】选择目标后，你可以将一张“掩”置入弃牌堆，然后获得其两张牌",
	["#sr_yansha"] = "你可以将一张手牌置于武将牌上",
	["@yan"] = "掩",
	["losesr_wuwei"] = "失去【无畏】",
	["losesr_yansha"] = "失去【掩杀】",
	["$sr_yansha1"] = "兵贵神速，随我来",
	["$sr_yansha2"] = "行包围之势，尽数诛之",
	["$sr_wuwei"] = "记住我军的强大吧",
	["~sr_zhangliao"] = "我张文远，竟受此污名",
}

--SR貂蝉
sr_diaochan = sgs.General(extension,"sr_diaochan","qun",3,false)

--离间
sr_lijiancard = sgs.CreateSkillCard{
	name = "sr_lijiancard" ,
	filter = function(self, targets, to_select, Self)
		if not to_select:isMale() then
			return false
		end
		
		local duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0) --克隆一张决斗
		if (#targets == 0) and Self:isProhibited(to_select, duel) then --如果决斗目标不能被决斗，则返回false
			return false
		end
		if (#targets == 1) and to_select:isCardLimited(duel, sgs.Card_MethodUse) then 
			return false
		end
		
		return (#targets < 2) and (to_select:objectName() ~= Self:objectName())
	end ,
	feasible = function(self, targets, Self)
		return #targets == 2 --离间牌可以使用的前提只有目标数为2
	end ,
	about_to_use = function(self, room, cardUse) 
		local diaochan = cardUse.from
		
		local l = sgs.LogMessage()
		l.from = diaochan
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)
		
		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, diaochan, data)
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, 
			diaochan:objectName(), "", "sr_lijian", "")
		room:moveCardTo(self, diaochan, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, diaochan, data)
		thread:trigger(sgs.CardFinished, room, diaochan, data)
	end ,
	on_use = function(self, room, player, targets)
		
		local to = targets[1] --决斗目标
		local from = targets[2] --决斗使用者
		
		local duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0) --真实克隆的决斗，这个才是真正要使用的
		duel:setSkillName("_" .. self:getSkillName()) --设置技能名
		
		if (not from:isCardLimited(duel, sgs.Card_MethodUse)) and (not from:isProhibited(to, duel)) then 
			room:useCard(sgs.CardUseStruct(duel, from, to)) --使用决斗
		end
	end ,
}

sr_lijian = sgs.CreateViewAsSkill{
	name = "sr_lijian",
	n = 1,
	view_filter = function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards~=1 then return nil end
		local card = sr_lijiancard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_lijiancard") 
	end
}
sr_diaochan:addSkill(sr_lijian)

--曼舞
sr_manwucard = sgs.CreateSkillCard{
	name = "sr_manwucard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName() and to_select:isMale()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_manwu")
		local dest = targets[1]
		local id = room:askForCardChosen(source, dest, "h", "sr_manwu")
		local card = sgs.Sanguosha:getCard(id) 					
		room:showCard(dest, card:getEffectiveId()) 
		room:getThread():delay()
		if card:getSuit() == sgs.Card_Diamond then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(),card:getNumber())
			indulgence:deleteLater()	    	
			if not source:isProhibited(dest, indulgence) and not dest:containsTrick("indulgence") then
				indulgence:addSubcard(card)
				indulgence:setSkillName("sr_manwu")
				local use = sgs.CardUseStruct()
				use.card = indulgence
				use.from = dest
				use.to:append(dest)
				room:useCard(use)
			end
		else
			room:obtainCard(source, card, true)
		end
	end
}
sr_manwu = sgs.CreateViewAsSkill{
	name = "sr_manwu",
	n = 0,
	view_as = function(self, cards)
		return sr_manwucard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_manwucard") 
	end
}
sr_diaochan:addSkill(sr_manwu)

--拜月
local srbaiyue_list = {}
sr_baiyue = sgs.CreateTriggerSkill{
	name = "sr_baiyue",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.BeforeCardsMove,sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data, room)
		
		if event == sgs.BeforeCardsMove then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() ~= sgs.Player_NotActive then
					local move = data:toMoveOneTime()
					local source = move.from
					if source and source:objectName() ~= player:objectName() then
						if move.to_place == sgs.Player_DiscardPile then
							for _,card_id in sgs.qlist(move.card_ids) do
								table.insert(srbaiyue_list, card_id)
							end
						end
					end
					if move.from_places:contains(sgs.Player_DiscardPile) then
						for _,card_id in sgs.qlist(move.card_ids) do
							if table.contains(srbaiyue_list, card_id) then
								table.removeOne(srbaiyue_list, card_id)
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if #srbaiyue_list > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, "sr_baiyue")
						room:broadcastSkillInvoke("sr_baiyue")
						local cardIds = sgs.IntList()
						for _,card_id in ipairs(srbaiyue_list) do
							cardIds:append(card_id)
						end
						room:fillAG(cardIds, player)
						local card_id = room:askForAG(player, cardIds, false, self:objectName())
						local card = sgs.Sanguosha:getCard(card_id)
						room:obtainCard(player, card, true)
						room:clearAG()
					end
					srbaiyue_list = {}
				end
			end
		end
	end
}
sr_diaochan:addSkill(sr_baiyue)
sr_diaochan:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_diaochan"] = "SR貂蝉",
["#sr_diaochan"] = "绝代风华",
["&sr_diaochan"] = "貂蝉",
["sr_lijian"] = "离间",
[":sr_lijian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择两名男性角色，令其中"..
"一名男性角色视为对另一名男性角色使用一张【决斗】。",
["$sr_lijian"] = "将军，那人对妾身，好生无礼",
["sr_manwu"] = "曼舞",
["sr_manwucard"] = "曼舞",
[":sr_manwu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示一名男性角色的一张手牌，若此牌"..
"为方片，将之置于该角色的判定区内，视为【乐不思蜀】；若不为方片，你获得之。",
["sr_baiyue"] = "拜月",
[":sr_baiyue"] = "回合结束阶段开始时，你可以获得本回合其他角色进入弃牌堆的一张牌。",
["$sr_manwu"] = "让妾身为您献上一舞！",
["$sr_baiyue"] = "羡慕吧。",
["~sr_diaochan"] = "红颜多薄命，几人能白头！",
["losesr_manwu"] = "失去【曼舞】",
["losesr_baiyue"] = "失去【拜月】",
["losesr_lijian"] = "失去【离间】",
}

--SR华佗
sr_huatuo = sgs.General(extension,"sr_huatuo","qun",3)

--行医
sr_xingyicard = sgs.CreateSkillCard{
	name = "sr_xingyicard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 
			and to_select:isWounded()		
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_xingyi")
		local dest = targets[1]
		local id = dest:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(id)
		room:obtainCard(source, card, false)
		if dest:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(dest, recover)
		end
	end
}
sr_xingyi = sgs.CreateViewAsSkill{
	name = "sr_xingyi",
	n = 0,
	view_as = function(self, cards)
		return sr_xingyicard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_xingyicard") 
	end
}
sr_huatuo:addSkill(sr_xingyi)

--刮骨
srguagudummycard = sgs.CreateSkillCard{
	name = "srguagudummycard",
}
sr_guagu = sgs.CreateTriggerSkill{
	name = "sr_guagu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		
		local dying = data:toDying()
		local target = dying.who
		if not target:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sr_guagu")
				room:broadcastSkillInvoke("sr_guagu")
				local count = target:getHandcardNum()
				local cards = srguagudummycard:clone()
				local list = target:getHandcards()
				for _,cd in sgs.qlist(list) do
					cards:addSubcard(cd)
				end
				room:throwCard(cards, target, player)
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(target, recover)
				if count >= 2 then
					target:drawCards(1)
				end
			end
		end
		return false	
	end
}
sr_huatuo:addSkill(sr_guagu)

--五禽
sr_wuqin = sgs.CreateTriggerSkill{
	name = "sr_wuqin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
				
		if not player:isKongcheng() then
			if player:getPhase() == sgs.Player_Finish then
				if room:askForCard(player, ".Basic", "srwuqindiscard", sgs.QVariant(), sgs.Card_MethodDiscard) then
					room:notifySkillInvoked(player, "sr_wuqin")
					room:broadcastSkillInvoke("sr_wuqin")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					local choice = room:askForChoice(player, self:objectName(), "srwuqindraw+srwuqinplay")
					if choice == "srwuqindraw" then
						player:drawCards(2)
					elseif choice == "srwuqinplay" then
						local phase = player:getPhase()--保存阶段							
						player:setPhase(sgs.Player_Play)		--设置目标出牌阶段
						room:broadcastProperty(player, "phase")
						local thread = room:getThread()
						if not thread:trigger(sgs.EventPhaseStart,room,player) then			
							thread:trigger(sgs.EventPhaseProceeding,room,player)
						end		
						thread:trigger(sgs.EventPhaseEnd,room,player)							
						player:setPhase(phase) --设置玩家保存的阶段
						room:broadcastProperty(player,"phase")		
					end
				end
			end
		end
		return false		
	end
}
sr_huatuo:addSkill(sr_wuqin)
sr_huatuo:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_huatuo"] = "SR华佗",
["#sr_huatuo"] = "圣手仁心",
["&sr_huatuo"] = "华佗",
["sr_xingyi"] = "行医",
[":sr_xingyi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名已受伤的其他角色一张手牌"..
"，然后令其回复1点体力。",
["sr_guagu"] = "刮骨",
[":sr_guagu"] = "当一名角色进入濒死状态时，你可以弃置其所有手牌（至少一张），然后该角色回复1点体力。若你以此"..
"法弃置其两张或者更多的手牌时，该角色摸一张牌。",
["sr_wuqin"] = "五禽",
["srwuqindiscard"] = "你可以弃置一张基本牌以便发动技能“五禽”",
["srwuqindraw"] = "摸两张牌",
["srwuqinplay"] = "进行一个额外的出牌阶段",
[":sr_wuqin"] = "回合结束阶段结束时，你可以弃置一张基本牌，然后选择一项：摸两张牌，或进行一个额外的出牌阶段。",
["$sr_xingyi"] = "病根虽除，仍需调养百日。",
["$sr_guagu"] = "郡侯身体要紧，岂能拖延！",
["$sr_wuqin"] = "流水不腐，户枢不蠹 ",
["~sr_huatuo"] = "人可医，国难医啊！",
["losesr_xingyi"] = "失去【行医】",
["losesr_guagu"] = "失去【刮骨】",
["losesr_wuqin"] = "失去【五禽】",
}

--SR吕布
sr_lvbu = sgs.General(extension,"sr_lvbu","qun",4)

--极武
sr_jiwucard = sgs.CreateSkillCard{
	name = "sr_jiwucard", 
	target_fixed = true, 
	will_throw = false,
	about_to_use = function(self, room, use)
		local source = use.from
		local msg = sgs.LogMessage()
		msg.type = "#InvokeSkill"
		msg.from = use.from
		msg.arg = "sr_jiwu"
		room:sendLog(msg)
		room:broadcastSkillInvoke("sr_jiwu", 1)
		room:notifySkillInvoked(source, "sr_jiwu")
		if source:getHandcardNum() < 1 then
			source:drawCards(1-source:getHandcardNum())
		else
			if source:getHandcardNum() > 1 then
				room:askForDiscard(source, "sr_jiwu", source:getHandcardNum()-1, source:getHandcardNum()-1, false, false)
			end
		end
		room:setPlayerMark(source, "srjiwudistancemark", 1)
		room:setPlayerMark(source, "&sr_jiwu-Clear", 1)
		room:addPlayerMark(source, "jiwu_slashdamage")
	end
}
sr_jiwuvs = sgs.CreateZeroCardViewAsSkill{
	name = "sr_jiwu", 
	view_as = function() 
		return sr_jiwucard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_jiwucard")
	end
}

--极武BUFF
sr_jiwu = sgs.CreateTriggerSkill{
	name = "sr_jiwu",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed,sgs.DamageCaused,sgs.CardFinished,sgs.EventPhaseEnd},
	view_as_skill = sr_jiwuvs,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			room:setTag("jiwudata", data)
			local use = data:toCardUse()
			if not use.from then return false end
			if use.from:objectName() == player:objectName() and use.from:hasSkill("sr_jiwu") then
				if use.card:isKindOf("Slash") and use.from:getCards("e"):length() == 0 then
					for _, p in sgs.qlist(room:getPlayers()) do
						if use.to:contains(p) or sgs.Sanguosha:isProhibited(player, p, use.card) then
							room:addPlayerMark(p, "jiwu_nil")
						end
					end
					local can_jiwuextra = false
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:getMark("jiwu_nil") == 0 then
							can_jiwuextra = true
							break
						end
					end
					if can_jiwuextra then
						if room:askForUseCard(player, "@@jiwu_extarget", "@jiwu_extraslashtarget") then
							room:broadcastSkillInvoke("sr_jiwu", 2)
						end
					end
					for _, p in sgs.qlist(room:getPlayers()) do
						if p:getMark("jiwu_target") > 0 then
							room:setPlayerMark(p, "jiwu_target", 0)
							use.to:append(p)
						end
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
				room:removeTag("jiwudata")
			end
			for _, p in sgs.qlist(room:getPlayers()) do
				room:setPlayerMark(p, "jiwu_nil", 0)
				room:setPlayerMark(p, "jiwu_target", 0)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if player:getMark("jiwu_slashdamage") > 0 then
				if card then
					if card:isKindOf("Slash") then
						room:notifySkillInvoked(player, "sr_jiwu")
						damage.damage = damage.damage + 1
						data:setValue(damage)
					end
				end
			end
		end
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("srjiwudistancemark") > 0 then
					room:setPlayerMark(player, "srjiwudistancemark", 0)
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				for _, pe in sgs.qlist(room:getPlayers()) do
					room:setPlayerMark(pe, "jiwu_target", 0)
					room:setPlayerMark(pe, "jiwu_nil", 0)
					room:setPlayerMark(pe, "jiwu_slashdamage", 0)
				end
			end
		end
		return false
	end
}


sr_jiwutm = sgs.CreateTargetModSkill{
	name = "#sr_jiwutm",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sr_jiwu") then
			if from:getMark("srjiwudistancemark") > 0 then
				return 9999
			end
		end
	end
}

sr_lvbu:addSkill(sr_jiwu)
sr_lvbu:addSkill(sr_jiwutm)
extension:insertRelatedSkills("sr_jiwu", "#sr_jiwutm")

--射戟
sr_sheji = sgs.CreateViewAsSkill{
	name = "sr_sheji", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon then
			if to_select:objectName() == weapon:objectName() then
				if to_select:objectName() == "Crossbow" then
					return sgs.Self:canSlashWithoutCrossbow()
				end
			end
		end
		return to_select:getTypeId() == sgs.Card_TypeEquip
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:isNude()
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:isNude()
	end
}
sr_lvbu:addSkill(sr_sheji)
--攻击范围
sr_shejitm = sgs.CreateTargetModSkill{
	name = "#sr_shejitm",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sr_sheji") then
			if table.contains(card:getSkillNames(), "sr_sheji") then
				return 9999
			end
		end
		return 0
	end
}
sr_lvbu:addSkill(sr_shejitm)
extension:insertRelatedSkills("sr_sheji", "#sr_shejitm")
--获得武器牌时机
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
sr_shejiget = sgs.CreateTriggerSkill{
	name = "#sr_shejiget", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage,sgs.TargetConfirmed},  
	on_trigger = function(self, event, player, data, room)
	if event == sgs.Damage then
		local damage = data:toDamage()
		local source = damage.from
		local target = damage.to
		for _, srlvbu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source and source:objectName() ~= srlvbu:objectName() then
				if source:objectName() ~= target:objectName() then
					if source:getWeapon() ~= nil then
						if not srlvbu:isNude() then
							if room:askForSkillInvoke(srlvbu, "sr_sheji", data) then
								room:notifySkillInvoked(srlvbu, "sr_sheji")
								room:broadcastSkillInvoke("sr_sheji")
								room:askForDiscard(srlvbu, self:objectName(), 1, 1, false, true)
								room:obtainCard(srlvbu, source:getWeapon(), true)
								break
							end
						end
					end
				end
			end
		end
	else
		local use = data:toCardUse()
		local slash1 = use.card				
		if slash1:isKindOf("Slash") and table.contains(slash1:getSkillNames(), "sr_sheji") and 
			(use.from:hasSkill(self:objectName())) then					
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. slash1:toString()):toIntList())
			for i = 0, use.to:length() - 1, 1 do
				if jink_table[i + 1] == 1 then
					jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
				end
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. slash1:toString(), jink_data)
		end
		return false
	end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end				
}
sr_lvbu:addSkill(sr_shejiget)
extension:insertRelatedSkills("sr_sheji", "#sr_shejiget")
sr_lvbu:addSkill("#choose")

sgs.LoadTranslationTable{
["sr_lvbu"] = "SR吕布",
["#sr_lvbu"] = "神驹飞将",
["&sr_lvbu"] = "吕布",
["sr_jiwu"] = "极武",
[":sr_jiwu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将你的手牌调整至一张，若如此做，"..
"本回合你的攻击范围无限，且你下一次使用的【杀】造成的伤害+1。<font color=\"blue\"><b>锁定技"..
"，</b></font>若你的装备区没有牌，你使用的【杀】可以至多额外指定任意两名其他角色为目标。",
["sr_sheji"] = "射戟",
[":sr_sheji"] = "当一名装备区有武器牌的其他角色对另外一名角色造成伤害后，你可以弃置一张牌，然后获得该角色的"..
"武器牌。你可以将装备牌当无距离限制的【杀】使用或打出,你以此法使用的【杀】须连续使用两张【闪】才能抵消。",
["$sr_jiwu2"] = "谁敢挡我！",
["$sr_jiwu1"] = "真是无趣，你们一起上吧！",
["$sr_sheji"] = "够胆的话，就来试试！",
["~sr_lvbu"] = "有意思，呵呵哈哈哈哈！",
["losesr_jiwu"] = "失去【极武】",
["losesr_sheji"] = "失去【射戟】",
}

return {extension}