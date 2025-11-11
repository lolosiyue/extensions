--==《双城之战》==--
extension = sgs.Package("kearcane", sgs.Package_GeneralPack)
local skills = sgs.SkillList()


--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


--金克斯
kejinx = sgs.General(extension, "kejinx", "god", 3, false )

kejinx_nopay = sgs.CreateTriggerSkill{
	name = "kejinx_nopay",
	waked_skills = "kejinxcrazy",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer then
				for _, jinx in sgs.qlist(room:findPlayersBySkillName("azirshenji")) do
					if jinx:objectName() ~= killer:objectName() then
						jinx:drawCards(2)
						room:broadcastSkillInvoke("kejinx_nopay", math.random(1,8))
					end
				end
				if killer:isAlive() and (killer:hasSkill("kejinx_nopay")) then
					killer:drawCards(3)
					room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
					player:bury()
					room:acquireOneTurnSkills(killer, self:objectName(), "kejinxcrazy")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
 }
kejinx:addSkill(kejinx_nopay)

--击杀语音稳定
kejinxkillbr = sgs.CreateTriggerSkill{
	name = "#kejinxkillbr",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer then
				if killer:isAlive() and (killer:hasSkill("kejinx_nopay")) then
					local room = player:getRoom()
					room:broadcastSkillInvoke("kejinx_nopay", math.random(1,8))
					room:broadcastSkillInvoke("kejinxmark", 19)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
 }
kejinx:addSkill(kejinxkillbr)


kejinx_nopayc = sgs.CreateTriggerSkill{
	name = "#kejinx_nopayc",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer then
				if killer:isAlive() and (killer:hasSkill("kejinx_nopay")) then
					local room = player:getRoom()
					room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
					player:bury()
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	priority = -1,
 }
kejinx:addSkill(kejinx_nopayc)
extension:insertRelatedSkills("kejinx_nopay", "#kejinx_nopayc")

--回合开始添加标记
kejinxmark = sgs.CreateTriggerSkill{
    name = "kejinxmark",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging,sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Start then
				return false
			end
			local plcs = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do    
				if (p:getMark("@jinxtuya") == 0 )then
					plcs:append(p)  
				end
			end
			local plc = room:askForPlayerChosen(player, plcs, self:objectName(), "jinxmark-ask", true, true)
			if plc then
				plc:gainMark("@jinxtuya")
				room:addPlayerMark(plc, self:objectName()..player:objectName())
				room:broadcastSkillInvoke(self:objectName(),math.random(1,10))
			end	
		end
		if (event == sgs.EventPhaseChanging) and (player:getMark("@jinxtuya") > 0) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_RoundStart then
				return false
			end
			for _, jinx in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark(self:objectName()..jinx:objectName()) > 0 then
					local gl = math.random(1,2)
					if (gl ==1) then
						room:setEmotion(player, "Arcane/jinxmark")
						room:broadcastSkillInvoke("kejinxmark", 18) 
						local log = sgs.LogMessage()
						log.type = "$kejinxbang"
						log.from = jinx
						room:sendLog(log)
						local damage = sgs.DamageStruct()
						damage.from = jinx
						damage.to = player
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Fire
						room:damage(damage)
						room:recover(jinx, sgs.RecoverStruct())
						room:broadcastSkillInvoke("kejinxmark",math.random(11,17))
						room:removePlayerMark(player, self:objectName()..jinx:objectName())
						if (player:getMark("@jinxtuya") > 0) then
							room:removePlayerMark(player, "@jinxtuya")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
kejinx:addSkill(kejinxmark)
extension:insertRelatedSkills("kejinxmark", "#kejinxkillbr")

--加手牌上限
kejinxKeep = sgs.CreateMaxCardsSkill{
	name = "#kejinxKeep",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:hasSkill("kejinxmark") then
			local num = 0
			for _,p in sgs.qlist(target:getAliveSiblings()) do
				if (p:getMark("@jinxtuya") > 0) then
					num = num + 1
				end
			end	
			return num		
		else
			return 0
		end
	end
}
kejinx:addSkill(kejinxKeep)
extension:insertRelatedSkills("kejinxmark", "#kejinxKeep")

jinxchangeCard = sgs.CreateSkillCard{
	name = "jinxchangeCard",
	target_fixed = true,
	on_use = function(self, room, source, target)
		local cg = 0
		if (source:getChangeSkillState("jinxchange") == 1) then
			room:broadcastSkillInvoke("kejinx_nopay",10)  
			room:removePlayerMark(source, "@jinxgun")
			room:addPlayerMark(source, "@jinxcannon")
			local log = sgs.LogMessage()
			log.type = "$jinxchangetocannon"
			log.from = source
			room:sendLog(log)
			cg = 1
			room:setChangeSkillState(source, "jinxchange", 2)
		end
		if (source:getChangeSkillState("jinxchange") == 2) and (cg == 0)then
			room:broadcastSkillInvoke("kejinx_nopay",9)  
			room:removePlayerMark(source, "@jinxcannon")
			room:addPlayerMark(source, "@jinxgun")
			local log = sgs.LogMessage()
			log.type = "$jinxchangetogun"
			log.from = source
			room:sendLog(log)
			room:setChangeSkillState(source, "jinxchange", 1)
		end
	end
}
jinxchangeVS = sgs.CreateZeroCardViewAsSkill{
	name = "jinxchange",
	view_as = function()
		return jinxchangeCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:isAlive()
	end
}
--[[jinxchangeVS = sgs.CreatePhaseChangeSkill{
	name = "jinxchange",
	change_skill = true,
	view_as_skill = jinxchangeVS,
	on_phasechange = function(self, player)
		--if player:getPhase() == sgs.Player_Start
		--return false
	end
}
kejinx:addSkill(jinxchange)]]


--游戏开始时
jinxchange = sgs.CreateTriggerSkill{
	name = "jinxchange",
	change_skill = true,
	view_as_skill = jinxchangeVS,
	events = {sgs.CardUsed,sgs.GameStart,sgs.DamageCaused,sgs.TargetSpecified,sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) and (player:getMark("@jinxgun") > 0) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:isBlack() and player:hasSkill(self:objectName()) then
				if (use.card:getSuit() == sgs.Card_Club )then
					player:drawCards(1)
				end
				if (use.card:getSuit() == sgs.Card_Spade ) and player:hasSkill("kejinxcrazy") then
					player:drawCards(1)
				end
				if use.m_addHistory then
					room:addPlayerHistory(player, use.card:getClassName(),-1)
				end
			end
		end
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and (player:getMark("@jinxcannon") > 0)  then
				room:setCardFlag(use.card, "SlashIgnoreArmor")
				local extra_targets = room:getCardTargets(player, use.card, use.to)
				if extra_targets:isEmpty() then return false end
				local adds = sgs.SPlayerList()
				for _, p in sgs.qlist(extra_targets) do
					if (p:getMark("@jinxtuya") > 0) and not (player:hasFlag("jinxmulti")) then
						use.to:append(p)
						adds:append(p)
					end
				end
				if adds:isEmpty() then return false end
				room:sortByActionOrder(adds)
				room:sortByActionOrder(use.to)
				data:setValue(use)

				local log = sgs.LogMessage()
				log.type = "$kejinxtarget"
				log.from = player
				room:sendLog(log)
				for _, p in sgs.qlist(adds) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(player, "jinxmulti")
			end
		end
		if (event == sgs.TargetSpecified) and (player:hasSkill(self:objectName())) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if (player:getMark("@jinxgun") > 0 )then
					room:broadcastSkillInvoke("kejinx_nopay", 11)
				end
				if (player:getMark("@jinxcannon") > 0 )then
					room:broadcastSkillInvoke("kejinx_nopay", 12)
				end
				local y = math.random(1,5)
				if (y > 2) then
					room:broadcastSkillInvoke("kejinx_nopay", math.random(13,26))
				end
			end
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local vic = damage.to
			if damage.card and damage.card:isKindOf("Slash") and (player:getMark("@jinxcannon") > 0 ) then
				room:broadcastSkillInvoke("kejinxmark", math.random(20,21))
				room:setEmotion(vic, "Arcane/jinxhit")
			end
			if damage.card and damage.card:isKindOf("Slash") and (player:getMark("@jinxgun") > 0 ) then
				--子弹特效
				room:setEmotion(damage.to, "Arcane/ctlhit")
			end
		end
		if (event == sgs.GameStart) and player:hasSkill(self:objectName()) then
			player:throwEquipArea(0)
			room:setPlayerMark(player,"@jinxgun",1)
			local b = math.random(1,3)
			if b == 3 then
				room:broadcastSkillInvoke("kejinx_nopay",math.random(27,29)) 
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejinx:addSkill(jinxchange)


--武器牌视为杀
kejinxguner = sgs.CreateFilterSkill{
	name = "#kejinxguner", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Weapon")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
kejinx:addSkill(kejinxguner)
extension:insertRelatedSkills("jinxchange", "#kejinxguner")

--鱼骨头无限距离
kejinxcannon = sgs.CreateTargetModSkill{
	name = "kejinxcannon",
	distance_limit_func = function(self, from, card)
		if (from:getMark("@jinxcannon") > 0) and card:isKindOf("Slash") then
			return 1000
		else
			return 0
		end
	end,             
}
if not sgs.Sanguosha:getSkill("kejinxcannon") then skills:append(kejinxcannon) end


--额外目标
--[[kejinxtarget = sgs.CreateTriggerSkill{
    name = "#kejinxtarget",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasSkill(kejinxcannon) and (player:getMark("@jinxcannon") > 0)  then
				room:setCardFlag(use.card, "SlashIgnoreArmor")
				local extra_targets = room:getCardTargets(player, use.card, use.to)
				if extra_targets:isEmpty() then return false end
				local adds = sgs.SPlayerList()
				for _, p in sgs.qlist(extra_targets) do
					if (p:getMark("@jinxtuya") > 0) and not (player:hasFlag("jinxmulti")) then
						use.to:append(p)
						adds:append(p)
					end
				end
				if adds:isEmpty() then return false end
				room:sortByActionOrder(adds)
				room:sortByActionOrder(use.to)
				data:setValue(use)

				local log = sgs.LogMessage()
				log.type = "$kejinxtarget"
				log.from = player
				room:sendLog(log)
				for _, p in sgs.qlist(adds) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(player, "jinxmulti")
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
kejinx:addSkill(kejinxtarget)]]

--结束阶段清除
--[[kejinxtargetclear = sgs.CreateTriggerSkill{
	name = "kejinxtargetclear",
	frequency = sgs.Skill_Frequent,
	global = true,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	   local room = player:getRoom()
	   if player:getPhase() == sgs.Player_Finish then
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("jinxmulti") then
			    room:setPlayerFlag(p, "-jinxmulti")
			end
		end
	end
	end,
	can_trigger = function(self, player)
		return player
	end,
 }
 if not sgs.Sanguosha:getSkill("kejinxtargetclear") then skills:append(kejinxtargetclear) end]]


--使用杀语音
--[[kejinxslash = sgs.CreateTriggerSkill{
    name = "#kejinxslash",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if (player:getMark("@jinxgun") > 0 )then
				room:broadcastSkillInvoke("kejinx_nopay", 11)
			end
			if (player:getMark("@jinxcannon") > 0 )then
				room:broadcastSkillInvoke("kejinx_nopay", 12)
			end
			local y = math.random(1,5)
			if (y > 2) then
				room:broadcastSkillInvoke("kejinx_nopay", math.random(13,26))
			end
		end
	end
}
kejinx:addSkill(kejinxslash)]]


--炮弹命中音效
--[[jinxqhit = sgs.CreateTriggerSkill{
	name = "#jinxqhit",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local vic = damage.to
		if damage.card:isKindOf("Slash") and (player:getMark("@jinxcannon") > 0 ) then
			room:broadcastSkillInvoke("kejinxmark", math.random(20,21))
			room:setEmotion(vic, "Arcane/jinxhit")
		end
		if damage.card:isKindOf("Slash") and (player:getMark("@jinxgun") > 0 ) then
			--子弹特效
			room:setEmotion(damage.to, "Arcane/ctlhit")
		end
	end
}
kejinx:addSkill(jinxqhit)]]

--杀死人本回合无限出杀
kejinxcrazy = sgs.CreateTargetModSkill{
	name = "kejinxcrazy",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kejinxcrazy") then skills:append(kejinxcrazy) end




--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--杰斯


kejayce = sgs.General(extension, "kejayce", "god", 4)

kejintuo = sgs.CreateTriggerSkill{
    name = "kejintuo",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			local phase = change.to
			for _, jayce in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (player:getMark("&keflydoor") >= 1) then
					if (phase == sgs.Player_Start) then
						room:setEmotion(player, "Arcane/setflydoor")
						if not (player:hasFlag("selfflydoor") or (player:getMark("@hexstone") >= 3) or (player:hasFlag("nowjaycefail")) ) then
							--不然会双重奏
							if not player:hasFlag("sethexdoor") then
								local yy = math.random(1,2)
								if yy ~= 1 then
									room:broadcastSkillInvoke("kejintuo",math.random(11,12))
								else 
									room:broadcastSkillInvoke("kejintuo",math.random(1,10))
								end
							end
						end
						if (player:hasFlag("selfflydoor")) or (player:getMark("@hexstone") >= 3) then
							room:broadcastSkillInvoke("kejintuo",math.random(11,12))
						end
						local one = math.random(1,5)
						local three = 9
						local two = 9
						--local pre = math.random(1,2)
				--成功后执行2-3项
						if (jayce:getMark("kechuzhism") > 0) then
							two = one
							three = one
						end
				--成功前执行1-2项
						if (jayce:getMark("kechuzhism") == 0) then
							two = one
						end
				--对“二”处理
						while( two == one )
						do
						two = math.random(1,5)
						end		
				--对“三”处理		
						while( (three == one) or (three == two) )
						do
							three = math.random(1,5)
						end	
				--执行效果
						if player:objectName() ~= jayce:objectName() then
							room:doAnimate(1, jayce:objectName(), player:objectName())
						end
						room:getThread():delay(1250)
						if (one == 1) or (two == 1) or (three == 1) then
							local log = sgs.LogMessage()
							log.type = "$keflydoorbuffmp"
							log.from = player
							room:sendLog(log)
							player:drawCards(1)
						end
						if (one == 2) or (two == 2) or (three == 2) then
							local log = sgs.LogMessage()
							log.type = "$keflydoorbuffkeep"
							log.from = player
							room:sendLog(log)
							room:addMaxCards(player, 1, true)
						end
						if (one == 3) or (two == 3) or (three == 3) then
							local log = sgs.LogMessage()
							log.type = "$keflydoorbuffjl"
							log.from = player
							room:sendLog(log)
							room:addDistance(player, -1, true, true)
						end
						if (one == 4) or (two == 4) or (three == 4) then
							local log = sgs.LogMessage()
							log.type = "$keflydoorbuffpd"
							log.from = player
							room:sendLog(log)
							for _, c in sgs.qlist(player:getCards("j")) do 
								room:throwCard(c, player)
							end
						end
						if (one == 5) or (two == 5) or (three == 5) then
							local log = sgs.LogMessage()
							log.type = "$keflydoorbuffhx"
							log.from = player
							room:sendLog(log)
							room:recover(player, sgs.RecoverStruct())
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_RoundStart) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do        
					if (p:getMark("&keflydoor") == 0) and (player:getMark("jaycefail") == 0) then
						players:append(p)
					end
					if (p:getMark("&keflydoor") == 0) and (player:getMark("jaycefail") > 0) and (p:objectName() == player:objectName()) then
						players:append(p)
					end
				end	
				local fri = room:askForPlayerChosen(player, players, self:objectName(), "yanmou-ask", true, true)
				if fri then
					if fri:objectName() == player:objectName() then
						room:setPlayerFlag(player,"selfflydoor")
					end
					if player:getMark("@hexstone") < 3 then
						room:broadcastSkillInvoke("kejintuo",math.random(1,10))
					--else
						--room:broadcastSkillInvoke("kejintuo",math.random(11,12))
					end
					room:addPlayerMark(fri, "&keflydoor")	
					room:setPlayerFlag(player,"sethexdoor")
				end	
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
kejayce:addSkill(kejintuo)

--飞门交换位置

kefanmaoCard = sgs.CreateSkillCard{
	name = "kefanmaoCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets == 0)  and (to_select:getMark("&keflydoor") > 0) --and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		if (target:objectName() ~= player:objectName()) then
			room:setPlayerMark(target,"flydoorfly",1)
			room:setPlayerMark(player,"jayceflied",1)
			room:broadcastSkillInvoke("kejintuo",13)
			room:removePlayerMark(player,"@hexstone",2)
			room:doAnimate(1, player:objectName(), target:objectName())
			room:doAnimate(1, target:objectName(), player:objectName())
			room:setEmotion(player, "Arcane/flydoor")
			room:setEmotion(target, "Arcane/flydoor")
			room:getThread():delay(1500)
			room:swapSeat(target, player)	
			player:drawCards(2)
			target:drawCards(2)
		end

		if (target:objectName() == player:objectName()) then
			room:removePlayerMark(player,"@hexstone",2)
			room:broadcastSkillInvoke("kejintuo",13)
			room:setEmotion(player, "Arcane/flydoor")
			room:getThread():delay(1000)
			player:drawCards(2)
			player:drawCards(2)
		end
	end
}
--主技能
kefanmaoVS = sgs.CreateViewAsSkill{
	name = "kefanmao",
	n = 0,
	view_as = function(self, cards)
		return kefanmaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kefanmaoCard")) and (player:getMark("@hexstone") >= 2)
	end, 
}

kefanmao = sgs.CreateTriggerSkill{
    name = "kefanmao",
	view_as_skill = kefanmaoVS,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) and (player:getMark("jayceflied") > 0) then
				room:setPlayerMark(player,"jayceflied",0)
				--找到飞过的人
				for _, p in sgs.qlist(room:getAllPlayers()) do        
					if p:getMark("flydoorfly") > 0 then
						if room:askForSkillInvoke(player, "flydoorswapback-ask", data) then
							room:broadcastSkillInvoke("kejintuo",13)	
							room:doAnimate(1, player:objectName(), p:objectName())
							room:doAnimate(1, p:objectName(), player:objectName())
							room:setEmotion(player, "Arcane/flydoor")
							room:setEmotion(p, "Arcane/flydoor")
							room:getThread():delay(1500)
							room:swapSeat(p, player)	
							room:getThread():delay(600)
						end
						break
					end
				end	
				--完全清除
				for _, p in sgs.qlist(room:getAllPlayers()) do        
					if p:getMark("flydoorfly") > 0  then
						room:setPlayerMark(p,"flydoorfly",0)
					end
				end	
			end
		end
	end,
	--[[can_trigger = function(self, player)
	    return player:hasSkill(self:objectName())
	end,]]
}
if not sgs.Sanguosha:getSkill("kefanmao") then skills:append(kefanmao) end


--使命
kechuzhism = sgs.CreateTriggerSkill{
	name = "kechuzhism",
	events = {sgs.EventPhaseStart,sgs.Damage,sgs.Damaged,sgs.RoundStart},
	shiming_skill = true,
	waked_skills = "kefanmao,kebengneng",
	-- frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--准备阶段判成功
		--使命成功的标志是标记kechuzhism，失败的标志是标记jaycefail，需要判断，不然会成功后又失败。
		if (event == sgs.RoundStart) and player:hasSkill(self:objectName()) then
			room:addPlayerMark(player,"@hexstone")
		end
		if (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_Start then
				local can_invoke = true
				if player:getMark("@hexstone") < 3 then
					can_invoke = false
				end
				if can_invoke and (player:getMark("kechuzhism") == 0) and (player:getMark("jaycefail") == 0) then
					--room:sendShimingLog(player, self)
					local log = sgs.LogMessage()
					log.type = "$kejaycewakesuc"
					log.from = player
					room:sendLog(log)
					--改技能描述
					-- local translate = sgs.Sanguosha:translate(":kejintuo1")
					room:changeTranslation(player, "kejintuo", 1);
					if room:changeMaxHpForAwakenSkill(player, -1) then
						local tp = math.random(1,2)
						if tp == 1 then
							room:broadcastSkillInvoke("kechuzhism",1)
							room:doLightbox("jayceshimingone")
							room:getThread():delay(500)
						end
						if tp == 2 then
							room:broadcastSkillInvoke("kechuzhism",math.random(2,3))
							room:doLightbox("jayceshimingtwo")
							room:getThread():delay(1500)
						end
						
						room:addPlayerMark(player, "kechuzhism")
						room:setPlayerMark(player,"&chuzhi_damage",0)
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = player:getLostHp()
						room:recover(player, recover)
						room:handleAcquireDetachSkills(player, "kefanmao")
						room:broadcastSkillInvoke("anjiangbgm", 2)
					end
				end
			end
		--回合开始判失败
			if player:getPhase() == sgs.Player_RoundStart then
			    if player:getMark("&chuzhi_damage") > 2 and (player:getMark("kechuzhism") == 0) and (player:getMark("jaycefail") == 0) then
					room:setPlayerMark(player,"jaycefail",1)
					--local nowhp = player:getHp()
					--room:changeHero(player, "kejaycetwo", false, true, false, false, nowhp)
					room:broadcastSkillInvoke("anjiangbgm",1)
					room:broadcastSkillInvoke("kechuzhism",math.random(4,8))
					room:doSuperLightbox("kejaycefail", "kechuzhism")
					local log = sgs.LogMessage()
					log.type = "$kejaycewakefail"
					log.from = player
					room:sendLog(log)
					room:setPlayerFlag(player,"nowjaycefail")
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = 1
					room:recover(player, recover)
					--room:doLightbox("$hexfail", 4000)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("&keflydoor") > 0 then
							room:setPlayerMark(p,"&keflydoor",0)
						end
					end
					room:handleAcquireDetachSkills(player, "kebengneng")
					if player:getMark("jaycefail") > 0 then
						room:setPlayerMark(player,"&chuzhi_damage",0)
					end
				end	
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) and (damage.from:getMark("jaycefail") == 0) then
				if (player:getMark("jaycefail") == 0) and (player:getMark("kechuzhism") == 0) then
					room:addPlayerMark(damage.from,"&chuzhi_damage")
				end
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local jay = damage.to
			if jay:hasSkill(self:objectName()) and (jay:getMark("jaycefail") == 0) then
				if (jay:getMark("jaycefail") == 0) and (jay:getMark("kechuzhism") == 0) then
					room:addPlayerMark(jay,"&chuzhi_damage")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:isAlive() and (target:hasSkill(self:objectName()))
	end,
}
kejayce:addSkill(kechuzhism)

--迸能
kebengneng = sgs.CreateTriggerSkill{
	name = "kebengneng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.DamageCaused,sgs.TargetSpecified,sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
				room:sendCompulsoryTriggerLog(player, "kebengneng")
				--room:broadcastSkillInvoke("kebengneng", math.random(1,9))
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.TargetSpecified) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash")) and (use.card:isBlack()) then
				local log = sgs.LogMessage()
				log.type = "$kebengnengxiangying"
				log.from = player
				room:sendLog(log)
				local no_respond_list = use.no_respond_list
				for _, szm in sgs.qlist(use.to) do
					table.insert(no_respond_list, szm:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local eny = damage.from
			local me = damage.to
			if me:hasSkill(self:objectName()) and me:isAlive() then
				me:drawCards(1)
			end	
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local eny = damage.to
			local me = damage.from
			if (not me:hasSkill(self:objectName())) and me:isAlive() and eny:isAlive() and (eny:objectName() ~= me:objectName()) then
				if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
					room:broadcastSkillInvoke("kebengneng", 16)
					room:doAnimate(1, me:objectName(), eny:objectName())
					room:getThread():delay(300)
					room:setEmotion(damage.to, "Arcane/jaycecannon")
				end
			end
			if me:hasSkill(self:objectName()) and me:isAlive() and eny:isAlive() and (eny:objectName() ~= me:objectName()) then
			    me:drawCards(1)
				local to_data = sgs.QVariant()
				to_data:setValue(eny)
				local will_use = room:askForSkillInvoke(me, self:objectName(), to_data)
			--使用技能情形
				if will_use then
                    if not eny:isKongcheng() then
						local card = eny:getRandomHandCard()
						room:throwCard(card, eny, me)
					end
					if me:getMark("@hexstone") == 0 and (eny:isAlive()) and (eny:hasEquipArea()) then
						if damage.card and not (damage.card:isKindOf("Slash") and damage.card:isRed()) then
							room:broadcastSkillInvoke("kebengneng", 15)
							room:setEmotion(damage.to, "Arcane/jaycehammer")
						end
						if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
							room:broadcastSkillInvoke("kebengneng", 16)
							room:doAnimate(1, me:objectName(), eny:objectName())
							room:getThread():delay(300)
							room:setEmotion(damage.to, "Arcane/jaycecannon")
						end
					end
					if me:getMark("@hexstone") > 0 and (eny:isAlive()) and (eny:hasEquipArea()) then
						room:setPlayerFlag(me,"usebengneng")
						room:removePlayerMark(me,"@hexstone",1)
						local choices = {}
						for i = 0, 4 do
							if eny:hasEquipArea(i) then
								table.insert(choices, i)
							end
						end
						if choices == "" then return false end
						local choice = room:askForChoice(me, "kebengneng-ask", table.concat(choices, "+"))
						local area = tonumber(choice), 0
						if damage.card and not (damage.card:isKindOf("Slash") and damage.card:isRed()) then
							room:broadcastSkillInvoke("kebengneng", math.random(10,13))	
							--if (eny:getHp() <= (eny:getMaxHp())/2) then
								room:broadcastSkillInvoke("kebengneng", 17)	
								local anim = math.random(1,2)
								if anim == 1 then
								    room:doLightbox("$jayceanimatehammer", 2750)
								else
									room:doLightbox("$jayceanimatehammertwo", 2750)
								end
							--end
							room:doAnimate(1, me:objectName(), eny:objectName())
							room:getThread():delay(500)
							room:broadcastSkillInvoke("kebengneng", 15)
							room:setEmotion(damage.to, "Arcane/jaycehammer")
						end
						if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
							room:broadcastSkillInvoke("kebengneng", math.random(10,13))	
							room:broadcastSkillInvoke("kebengneng",18)	
							room:broadcastSkillInvoke("kebengneng",19)	
							room:doLightbox("$jayceanimatecannon", 2250)
							room:doAnimate(1, me:objectName(), eny:objectName())
							room:broadcastSkillInvoke("kebengneng", 16)
							room:getThread():delay(300)
							room:setEmotion(damage.to, "Arcane/jaycecannon")
						end
						eny:throwEquipArea(area)	
					end	
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
}
if not sgs.Sanguosha:getSkill("kebengneng") then skills:append(kebengneng) end


kebengnengextwo = sgs.CreateTargetModSkill{
	name = "kebengnengextwo",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("kebengneng") and card:isKindOf("Slash") and card:isRed() then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("kebengnengextwo") then skills:append(kebengnengextwo) end

--戒严

kejieyanCard = sgs.CreateSkillCard{
	name = "kejieyanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return  (to_select:getMark("&keflydoor") > 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		for _, p in sgs.list(targets) do
			room:setPlayerMark(p,"&keflydoor",0)
		end
	end
}

kejieyan = sgs.CreateViewAsSkill{
	name = "kejieyan&",
	n = 0,
	view_as = function(self, cards)
		return kejieyanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kejieyanCard"))
	end, 
}
if not sgs.Sanguosha:getSkill("kejieyan") then skills:append(kejieyan) end

kejieyanstart = sgs.CreateTriggerSkill{
	name = "#kejieyanstart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,"kejieyan")
	end,
	can_trigger = function(self, player)
	    return player:hasSkill("kejintuo") and (player:getMark("jaycefail") == 0)
	end,
}
kejayce:addSkill(kejieyanstart)
extension:insertRelatedSkills("kejintuo", "#kejieyanstart")


kejayce:addRelateSkill("kejieyan")

--普攻
kejayceaaa = sgs.CreateTriggerSkill{
    name = "#kejayceaaa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:broadcastSkillInvoke("kebengneng", math.random(1,9))
			end
			if use.card:isKindOf("Slash") and not player:hasSkill("kebengneng") then
				room:broadcastSkillInvoke("kebengneng", 14)
				room:setEmotion(use.to:at(0), "Arcane/jaycehammer")
			end
		end
	end
}
kejayce:addSkill(kejayceaaa)

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--凯特琳
kecaitlyn = sgs.General(extension, "kecaitlyn", "god", 3,false)

--彻探
kechetan = sgs.CreateTriggerSkill{
	name = "kechetan",
	events = {sgs.Damaged},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local from = damage.from
			local to = damage.to
			local cats = room:findPlayersBySkillName("kechetan")
			for _, cat in sgs.qlist(cats) do
				if from and  (  (cat:distanceTo(to) <=1) ) and (cat:hasSkill(self:objectName())) and (not from:isKongcheng()) and (from:objectName() ~= cat:objectName()) then
					local to_data = sgs.QVariant()
					to_data:setValue(from)
					local will_use = room:askForSkillInvoke(cat, self:objectName(), to_data)
					if will_use then
						room:broadcastSkillInvoke("kechetan", math.random(1,46))
						if from:getMark("bechetan"..cat:objectName()) == 0 then
							room:addPlayerMark(from,"bechetan"..cat:objectName())
						end
						local ids = sgs.IntList()
						for _, card in sgs.qlist(from:getHandcards()) do
							ids:append(card:getEffectiveId())
						end
						local card_id = room:doGongxin(cat, from, ids)	
						if sgs.Sanguosha:getCard(card_id):isDamageCard() then
							room:addDistance(from, 100, true, true)
							local players = sgs.SPlayerList()
							players:append(from)  
							room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(card_id), cat, players))                                                          
						end
						if (card_id == -1) then return end
						if not (sgs.Sanguosha:getCard(card_id):isDamageCard()) then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, cat:objectName(), nil, "kechetan", nil)
							room:throwCard(sgs.Sanguosha:getCard(card_id), reason, from, cat)
							to:drawCards(1)
						end
					end
				end	
			end	
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
kecaitlyn:addSkill(kechetan)


--精稳
kejingwen = sgs.CreateTriggerSkill{
	name = "kejingwen",
	events = {sgs.CardFinished,sgs.ConfirmDamage,sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory, 
	priority = 3,
	on_trigger = function(self, event, player, data)
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
		    local room = player:getRoom()
			if (use.card:isKindOf("Slash"))  and player:hasSkill(self:objectName()) then
				--room:broadcastSkillInvoke(self:objectName(),22)
				if player:getMark("@kebaotou") > 0 then
					room:removePlayerMark(player,"@kebaotou")
				end
				if player:getMark("&kejingwen") <3 then
				    room:addPlayerMark(player,"&kejingwen")
				end
				if player:getMark("&kejingwen") == 3 then
					room:removePlayerMark(player,"&kejingwen",3)
					if player:getMark("@kebaotou") == 0 then
				        room:addPlayerMark(player,"@kebaotou")
						room:broadcastSkillInvoke("kejingwen", 50)
					end
				end
			end
		end
		if (event == sgs.ConfirmDamage) then
			local room = player:getRoom()
		    local damage = data:toDamage()
			if player:hasSkill(self:objectName()) and (player:getMark("@kebaotou") > 0) and (damage.card:isKindOf("Slash")) and (damage.from:objectName() == player:objectName()) then
				local hurt = damage.damage                   
				damage.damage = hurt + 1
				data:setValue(damage)
				room:getThread():delay(750)
				room:broadcastSkillInvoke("kejingwen", math.random(10,16)) 
				--room:getThread():delay(750)
				local tp = math.random(1,3)
				if tp == 1 then
				    room:doLightbox("catpicone")
				end
				if tp == 2 then
				    room:doLightbox("catpictwo")
				end
				if tp == 3 then
				    room:doLightbox("catpicthree")
				end
				room:getThread():delay(500)
				room:broadcastSkillInvoke("kejingwen", 51)
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
		    local room = player:getRoom()
			if (use.card:isKindOf("Slash")) and (use.card:getSuit() ~= sgs.Card_NoSuit) 
			and (player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				local no_respond_list = use.no_respond_list
				
				local log = sgs.LogMessage()
				log.type = "$kejingwen"
				log.from = player
				for _, p in sgs.qlist(use.to) do 
					local can_baotou = 1
					if not (p:isKongcheng()) then
					    for _, c in sgs.qlist(p:getCards("h")) do 
						    can_baotou = 1
						    if (c:getSuit()) == (use.card:getSuit()) then
							    can_baotou = 0
							    break
						    end
					    end
				    end
					if (can_baotou == 1) or (p:isKongcheng())then
						log.to:append(p)
						table.insert(no_respond_list, p:objectName())
						if player:getMark("@kebaotou") == 0 then
							room:broadcastSkillInvoke("kejingwen", math.random(1,9))
						end
						if player:getMark("@kebaotou") >0  then
							room:broadcastSkillInvoke("kejingwen", math.random(39,43))
						end
						room:setPlayerFlag(player,"catsay")
					end
				end	
				use.no_respond_list = no_respond_list
				data:setValue(use)
				if log.to:length() > 0 then
					room:sendLog(log)
				end
				room:getThread():delay(1000)
			end
		end
	end
}
kecaitlyn:addSkill(kejingwen)

--摸牌buff
kecaitlynmp = sgs.CreateTriggerSkill{
	name = "#kecaitlynmp",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local draw = data:toDraw()
		local n = 0
		local say = 0
		local rec = 1
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
			if p:getMark("bechetan"..player:objectName())>0 then
				room:removePlayerMark(p,"bechetan"..player:objectName())
				rec = 0 
				n = n + 1
				say = 1
			end
		end	
		draw.num = draw.num + n
		room:sendCompulsoryTriggerLog(player, "kechetan")
		data:setValue(draw)
		if say == 1 then
			room:broadcastSkillInvoke("kechetan", math.random(47,56))
		end
		--if rec == 1 then
		--	room:recover(player, sgs.RecoverStruct())
		--	room:broadcastSkillInvoke("kechetan", math.random(47,56))
		--end
		
	end,
}
kecaitlyn:addSkill(kecaitlynmp)

--距离
kekecaitlynjuli = sgs.CreateTargetModSkill{
	name = "#kekecaitlynjuli",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("kejingwen") and card and card:isKindOf("Slash") then
			return 1
		end
	end
}
kecaitlyn:addSkill(kekecaitlynjuli)

extension:insertRelatedSkills("kejingwen", "#kecaitlynmp")
extension:insertRelatedSkills("kejingwen", "#kekecaitlynjuli")

--平a音效
kecaitlynaaa = sgs.CreateTriggerSkill{
    name = "#kecaitlynaaa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	priority = 2,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if player:getMark("@kebaotou") == 0 then
				room:broadcastSkillInvoke("kejingwen", math.random(44,46))
			else
				room:broadcastSkillInvoke("kejingwen", math.random(47,49))
			end
			if not player:hasFlag("catsay") then
				local sj = math.random(1,2)
				if sj == 1 then
					room:broadcastSkillInvoke("kejingwen", math.random(30,38))
				end
				if sj == 2 then
					room:broadcastSkillInvoke("kejingwen", math.random(17,29))
				end
			end
			if player:hasFlag("catsay") then
			    room:setPlayerFlag(player,"-catsay")
			end
		end
	end
}
kecaitlyn:addSkill(kecaitlynaaa)

--命中特效
caitlynqhit = sgs.CreateTriggerSkill{
	name = "#caitlynqhit",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			room:setEmotion(damage.to, "Arcane/ctlhit")
		end
	end
}
kecaitlyn:addSkill(caitlynqhit)

--击杀语音
kecatkill = sgs.CreateTriggerSkill{
	name = "#kecatkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.damage and death.damage.from then
			if death.damage.from:hasSkill(kecatkill) then
				room:broadcastSkillInvoke("kechetan",math.random(57,69))
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kecaitlyn:addSkill(kecatkill)

kecatstart = sgs.CreateTriggerSkill{
	name = "#kecatstart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			room:broadcastSkillInvoke("kechetan",70) 
	end
}
kecaitlyn:addSkill(kecatstart)


--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--蔚
keviolet = sgs.General(extension, "keviolet", "god", 4, false)


--御击
keyujiCard = sgs.CreateSkillCard{
	name = "keyujiCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and ( to_select:objectName() ~= sgs.Self:objectName()) and (not to_select:hasFlag("yujichosen")) and (sgs.Self:inMyAttackRange(to_select))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		if target:getHp() > 1 then
			local yy = math.random(1,5)
			if yy > 2 then
				room:broadcastSkillInvoke("keyuji", math.random(1,20))
			end
			if yy <= 2 then
				room:broadcastSkillInvoke("keyuji",math.random(21,34))
			end
		end
		if target:getHp() <= 1 then
		    room:broadcastSkillInvoke("keyuji",37)
			local ani = math.random(1,2)
			if ani == 1 then
				room:broadcastSkillInvoke("keyuji",math.random(33,34))
		        room:doLightbox("$violetanimate", 3250)
			end
			if ani == 2 then
				room:broadcastSkillInvoke("keyuji",math.random(33,34))
		        room:doLightbox("$violetanimatetwo", 3250)
			end
		end
		if target:getHp() > 1 then
		    room:broadcastSkillInvoke("keyuji",35)
		end
		room:doAnimate(1, player:objectName(), target:objectName())
		room:getThread():delay(500)
		
		room:setEmotion(target, "Arcane/vihit")
		room:setEmotion(target, "Arcane/vismoke")
		if (target:getHp() <= 1) and (target:getMaxHp() > 1 ) then
			room:loseMaxHp(target,1)
		end
		room:damage(sgs.DamageStruct(self:objectName(), player, target))
	--如果是玩家
	    if target:isAlive() then
			local result = room:askForChoice(target,"hitvi","slash+juedou", ToData(player))
			if result == "slash" then	
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("kevioletspace")
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = target
				card_use.to:append(player)
				room:useCard(card_use, false)
				slash:deleteLater() 	
			end
			if result == "juedou" then	
				local juedou = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				juedou:setSkillName("kevioletspace")
				local card_use = sgs.CardUseStruct()
				card_use.card = juedou
				card_use.from = target
				card_use.to:append(player)
				room:useCard(card_use, false)
				juedou:deleteLater() 	
			end
		end    
	end
}
--主技能
keyujiVS = sgs.CreateViewAsSkill{
	name = "keyuji",
	n = 0,
	view_as = function(self, cards)
		return keyujiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasFlag("alreadyyuji"))
	end, 
}

--被反击情形
keyuji = sgs.CreateTriggerSkill{
	name = "keyuji",
	view_as_skill = keyujiVS,
	events = {sgs.Damaged,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			local from = damage.from
			local data = sgs.QVariant()
			data:setValue(damage)
			if damage.card and damage.card:getSkillName() == "kevioletspace" then
				player:drawCards(2)
				if player:getHp() <= from:getHp() then
					player:gainHujia(1)
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("yujichosen") then
						room:setPlayerFlag(p,"-yujichosen")
					end
				end
				room:throwEvent(sgs.TurnBroken)
				room:getThread():delay(500)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			local phase = change.from
			if phase == sgs.Player_Play then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("yujichosen") then
						room:setPlayerFlag(p,"-yujichosen")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
keviolet:addSkill(keyuji)


--用来判断，且不触发语音，顺便清除一下flag
--[[kevioletspace = sgs.CreateTriggerSkill{
	name = "#kevioletspace",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    local change = data:toPhaseChange()
	    local phase = change.from
		if phase == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("yujichosen") then
					room:setPlayerFlag(p,"-yujichosen")
				end
			end
	    end
	end,
	can_trigger = function(self, target)
	   return target
	end,
}
keviolet:addSkill(kevioletspace)]]


kegonghuan = sgs.CreateTriggerSkill{
	name = "kegonghuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForPeaches,sgs.RoundStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.AskForPeaches) and (not player:isKongcheng())
		and player:hasSkill(self:objectName()) 
		and (player:getMark("usedweixu_lun") == 0) then
			local dying_data = data:toDying()
			local friend = dying_data.who
			if friend:objectName() ~= player:objectName() then
				local to_data = sgs.QVariant()
				to_data:setValue(friend)
				local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
				if will_use then
					room:broadcastSkillInvoke(self:objectName())
					local num = player:getHandcardNum()
					room:obtainCard(friend,player:wholeHandCards(),false)
					if num >= 3 then
						room:recover(friend, sgs.RecoverStruct())
					end
					room:setPlayerMark(player,"usedweixu_lun",1)
					--room:setPlayerFlag(player,"usedweixu")
					local lost = player:getLostHp()
					player:drawCards(lost)
				end
			end
		end	
		--[[if (event == sgs.RoundStart) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("usedweixu") then
					room:setPlayerFlag(p,"-usedweixu")
				end
			end
		end]]
	end,
	can_trigger = function(self, target)
		return target
	end
}
keviolet:addSkill(kegonghuan)

--普攻
kevioletaaa = sgs.CreateTriggerSkill{
    name = "#kevioletaaa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash")  then
			room:broadcastSkillInvoke("keyuji", 35)
			local yy = math.random(1,5)
			if yy > 2 then
				room:broadcastSkillInvoke("keyuji", math.random(1,20))
			end
			if yy <= 2 then
				room:broadcastSkillInvoke("keyuji",math.random(21,34))
			end
			room:setEmotion(use.to, "Arcane/vihit")
		end
	end
}
keviolet:addSkill(kevioletaaa)


--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--希尔科
kesilco = sgs.General(extension, "kesilco", "god", 3)

kechupan = sgs.CreateTriggerSkill{
	name = "kechupan",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirming},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirming) then
			local use = data:toCardUse()
			local room = player:getRoom()
			if (event == sgs.TargetConfirming) and use.to:contains(player) and (use.to:length() == 1) 
			and ( not use.from:isKongcheng())
			and player:hasSkill(self:objectName()) then
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and (use.from:objectName() ~= player:objectName()) then 
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName(),math.random(1,7))
						room:setPlayerMark(player,"usedchupan-Clear",1)
						local eny = use.from
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAllPlayers()) do        
							if p:canPindian(eny, true) then
								players:append(p)
							end
						end
						if not players:isEmpty() then 
							local dy = room:askForPlayerChosen(player, players, self:objectName(), "silcochuni-ask", true, true)
					        if dy then
								local success = dy:pindian(eny, "kechupan", nil)
								room:getThread():delay(750)
								if success then
									local log = sgs.LogMessage()
									log.type = "$kechupanyeser"
									log.from = player
									room:sendLog(log)
									for _, mb in sgs.qlist(use.to) do
										use.to:removeOne(mb)
									end
									data:setValue(use)	
									player:drawCards(1)
									dy:drawCards(1)
									if (dy:objectName() ~= player:objectName()) then
										local chupantwo = room:askForChoice(dy,"chupantwo_choice","damage+cancel", data)
										if chupantwo == "damage" then
											room:damage(sgs.DamageStruct(self:objectName(), dy, eny))
										end
									end
								else
									local log = sgs.LogMessage()
									log.type = "$kechupanno"
									log.from = player
									room:sendLog(log)
									local no_respond_list = use.no_respond_list
									table.insert(no_respond_list, player:objectName())
									use.no_respond_list = no_respond_list
									data:setValue(use)	
									room:broadcastSkillInvoke(self:objectName(),math.random(8,11))	
								end
							end
						end
					end
				end
			end
			return false
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName()) and (player:getMark("usedchupan-Clear") == 0)
	end,
}
kesilco:addSkill(kechupan)

kesilang = sgs.CreateTriggerSkill{
	name = "kesilang",
	frequency = sgs.Skill_Frequent,
	--view_as_skill = kesilangVS,
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_Play) then
				player:drawCards(player:getLostHp())
				if (player:getCardCount() > 0) then
					local depai = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kesilang-ask", true, true)
					if depai then
						local card = room:askForExchange(player, self:objectName(), 100, math.min(1,player:getHandcardNum()), false, "silangxuanpai")
						if card and (card:getSubcards():length() > 0) then
							room:obtainCard(depai, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(), self:objectName(), ""), false)
						end
					end
					if player:objectName() ~= depai:objectName() then
						room:doAnimate(1, player:objectName(), depai:objectName())
					end
					room:addPlayerMark(depai,"@besilanged")
					room:broadcastSkillInvoke("keshining")
					if depai:getGender() == sgs.General_Male then
						room:broadcastSkillInvoke("kesilang",math.random(1,9))
					else
						local yy = math.random(1,3)
						if yy == 1 then
							room:broadcastSkillInvoke("kesilang",math.random(1,9))
						else
							room:broadcastSkillInvoke("kesilang",math.random(10,14))
						end
					end
					room:setEmotion(depai, "Arcane/silcoqi")
					room:getThread():delay(1000)
				   --room:askForUseCard(player, "@@kesilang", "newsilang-ask")
				end
			end
		end
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if (player:getMark("@besilanged") > 0) and (not damage.to:hasSkill("kesilang")) then                           
				damage.damage = damage.damage + player:getMark("@besilanged")
				room:broadcastSkillInvoke("kesilang",17)
				data:setValue(damage)
				room:setEmotion(damage.to, "Arcane/silcosilang")
				room:removePlayerMark(player,"@besilanged",player:getMark("@besilanged"))
				room:setPlayerMark(player,"silcoyuyin",1)
				--[[local master = room:findPlayersBySkillName("kesilang")
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				room:getThread():delay(300)]]
				local log = sgs.LogMessage()
				log.type = "$kewolfdalog"
				log.from = player
				room:sendLog(log)
			end	
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
 }
kesilco:addSkill(kesilang)

kesilcokill = sgs.CreateTriggerSkill{
	name = "#kesilcokill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.BuryVictim) then
			local death = data:toDeath()
			local reason = death.damage
			if reason then
				local killer = reason.from
				if killer then
					if killer:isAlive() and ((killer:hasSkill("kesilang")) or (killer:getMark("silcoyuyin") > 0)) then
						room:broadcastSkillInvoke("kesilang",math.random(15,16))
						room:setPlayerMark(killer,"silcoyuyin",0)
						room:getThread():delay(500)
					end
				end
			end
		end
		if (player:hasSkill(self:objectName())) and (event == sgs.GameStart) then
			room:broadcastSkillInvoke("kechupan",6) 
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
 }
kesilco:addSkill(kesilcokill)

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--范德尔
kevander = sgs.General(extension, "kevander", "god", 5)

--挺护

ketinghuCard = sgs.CreateSkillCard{
	name = "ketinghuCard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select)
		if ((#targets > sgs.Self:getMaxHp() - 1) or (#targets > 3) )then return false end		
		return true 
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		for _, p in sgs.list(targets) do
			room:addPlayerMark(p,"&beketinghu+to+#"..player:objectName())
		end
		room:broadcastSkillInvoke("ketinghu",math.random(1,4))	
	end
}

ketinghuVS = sgs.CreateZeroCardViewAsSkill{
	name = "ketinghu",
	response_pattern = "@@ketinghu",
	view_as = function()
		return ketinghuCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
}

ketinghu = sgs.CreateTriggerSkill{
    name = "ketinghu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	view_as_skill = ketinghuVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Finish then
			return false
		end
		room:askForUseCard(player, "@@ketinghu", "vander-ask")		
	end,
}
kevander:addSkill(ketinghu)

--免伤
ketinghudamage = sgs.CreateTriggerSkill{
	name = "#ketinghudamage",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
		    local room = player:getRoom()
			local be = damage.to
			for _, van in sgs.qlist(room:findPlayersBySkillName("ketinghu")) do
				if (be:getMark("&beketinghu+to+#"..van:objectName())>0) then
					room:sendCompulsoryTriggerLog(van, "ketinghu")
					room:addPlayerMark(van,"&usetinghu")
					room:removePlayerMark(be,"&beketinghu+to+#"..van:objectName())
					room:broadcastSkillInvoke("ketinghu",math.random(5,9))	
					room:doAnimate(1, van:objectName(), be:objectName())
					room:getThread():delay(500)
					damage.prevented = true
					data:setValue(damage)		
					return true 
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
kevander:addSkill(ketinghudamage)

--准备阶段开始时
ketinghu_extra = sgs.CreateTriggerSkill{
    name = "#ketinghu_extra",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Start then
			return false
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do    
			if (p:getMark("&beketinghu+to+#"..player:objectName()) > 0 )then
				room:removePlayerMark(p,"&beketinghu+to+#"..player:objectName())
			end
		end
		if player:getMark("&usetinghu")>0 then
			local num = player:getMark("&usetinghu")
			local result = room:askForChoice(player,"vander_choice","loseanddraw+losemaxhp")
			if result == "loseanddraw" then
				room:loseHp(player,num,true)
				player:drawCards(num + num)

			end
			if result == "losemaxhp" then
				room:loseMaxHp(player, 1)
			end
			room:broadcastSkillInvoke("ketinghu",math.random(10,15))	
			room:removePlayerMark(player,"&usetinghu",player:getMark("&usetinghu"))
		end
	end,
}
kevander:addSkill(ketinghu_extra)
extension:insertRelatedSkills("ketinghu", "#ketinghu_extra")
extension:insertRelatedSkills("ketinghu", "#ketinghudamage")


--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--德莱厄斯



kedarius = sgs.General(extension, "kedarius", "god", 4, true)

keblood = sgs.CreateTriggerSkill{
	name = "keblood",
	waked_skills = "kebloodangry",
	events = {sgs.TargetConfirmed, sgs.TargetSpecified, sgs.Damage,sgs.MarkChanged},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.MarkChanged) then
			local mark = data:toMark()
			if (mark.name == "@shixue") and (mark.gain > 0) then
				if (player:getMark("@shixue") == 5) and not ((player:getMark("@xueyuan") > 0) or (player:hasFlag("beilianflag")) ) then
					room:addPlayerMark(player,"@xueyuan")
					local dariuss = room:findPlayersBySkillName("keblood")
					for _, darius in sgs.qlist(dariuss) do
						if not darius:hasSkill("kebloodangry") then
							room:broadcastSkillInvoke("kebloodangry",math.random(1,16))
							room:doLightbox("newdariuspic")
							room:broadcastSkillInvoke("kebloodangry",17)
							room:acquireOneTurnSkills(darius, "keblood", "kebloodangry")
							darius:drawCards(2)
						end
					end
				end
			end	
		end
		if (event == sgs.TargetSpecified) then 
			local use = data:toCardUse()
			if (use.to:length() == 1) and player:hasSkill(self:objectName()) and (not (use.to:contains(player)))
			and (not ((use.card:isKindOf("SkillCard") or (use.card:isKindOf("Peach")) or (use.card:getSkillName() == "killaround")))) then
				for _, vic in sgs.qlist(use.to) do
					--对每个目标
					if (vic:getMark("@shixue") < 5) and not (vic:hasFlag("alreadyadd")) then--如果已经血怒加上了，就不能重复加
						if player:askForSkillInvoke(self:objectName(), data) then
							--不是杀才有语音，杀有另外的语音
							if ((vic:getMark("@shixue") == 0) or (vic:getMark("@shixue") == 2) or (vic:getMark("@shixue") == 4) ) and not (use.card:isKindOf("Slash")) then
								room:broadcastSkillInvoke(self:objectName(),math.random(1,17))
							end
							vic:gainMark("@shixue")
							room:setEmotion(vic, "Arcane/blooda")
							room:broadcastSkillInvoke("keblood",math.random(31,32))
							room:getThread():delay(250)
						end
					end
					if vic:hasFlag("alreadyadd") then--去掉血怒影响
						room:setPlayerFlag(vic, "-alreadyadd")
					end
				end
			end
		end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.to:contains(player)) and player:hasSkill(self:objectName()) 
			and not ((use.card:isKindOf("SkillCard") or use.card:isKindOf("Peach"))) then
				if ((use.from:getMark("@shixue") < 5) and (use.from:objectName() ~= player:objectName()) 
				and not (use.from:hasFlag("alreadyadd"))) then
					if player:askForSkillInvoke(self:objectName(), data) then
						if ((use.from:getMark("@shixue") == 0) or (use.from:getMark("@shixue") == 2) or (use.from:getMark("@shixue") == 4) ) then
							room:broadcastSkillInvoke(self:objectName(),math.random(18,30))
						end
						use.from:gainMark("@shixue")
						room:setEmotion(use.from, "Arcane/blooda")
						room:broadcastSkillInvoke("keblood",math.random(31,32))
						room:getThread():delay(250)
					end
				end
				if use.from:hasFlag("alreadyadd") then
					room:setPlayerFlag(use.from, "-alreadyadd")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
kedarius:addSkill(keblood)

kedariusKeep = sgs.CreateMaxCardsSkill{
	name = "kedariusKeep",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if (target:getMark("@shixue") == 2) or (target:getMark("@shixue") == 3) then
			return -1
		elseif (target:getMark("@shixue") == 4) then
		    return -2
		elseif (target:getMark("@shixue") >= 5) then
		    return -2
		end
	end
}
if not sgs.Sanguosha:getSkill("kedariusKeep") then skills:append(kedariusKeep) end

--血怒
kebloodangry = sgs.CreateTriggerSkill{
	name = "kebloodangry",
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (event == sgs.TargetSpecified and (use.to:length() == 1)) and not (use.to:contains(player) or (use.card:isKindOf("SkillCard"))) then
			for _, vic in sgs.qlist(use.to) do
				if (vic:getMark("@shixue") < 5) and not (use.card:isKindOf("SkillCard") or (use.card:isKindOf("EquipCard")) or (vic:getMark("@xueyuan")>0) or (use.card:isKindOf("Peach"))) then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName(),math.random(1,16))
						room:broadcastSkillInvoke("kebloodangry",17)
						room:setPlayerFlag(vic, "alreadyadd")
						local num = vic:getMark("@shixue")
						local gain = 5 - num
						if (gain > 1) then
							room:setPlayerFlag(vic, "becausexn")
						end
						vic:gainMark("@shixue",gain)
						room:setEmotion(vic, "Arcane/blooda")
						room:broadcastSkillInvoke("keblood",math.random(31,32))
						room:getThread():delay(250)
					end
				end
			end
		end	
		if (event == sgs.TargetConfirmed) and (use.to:contains(player)) and (use.from:objectName() ~= player:objectName()) then
			if (use.from:getMark("@shixue") < 5) and (use.from:objectName() ~= player:objectName()) and not (use.card:isKindOf("SkillCard") or use.card:isKindOf("Peach") ) then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName(),math.random(1,16))
					room:broadcastSkillInvoke("kebloodangry",17)
					room:setPlayerFlag(use.from, "alreadyadd")
					local num = use.from:getMark("@shixue")
					local gain = 5 - num
					if (gain > 1) then
						room:setPlayerFlag(use.from, "becausexn")
					end
					use.from:gainMark("@shixue",gain)
					room:setEmotion(use.from, "Arcane/blooda")
					room:broadcastSkillInvoke("keblood",math.random(31,32))
					room:getThread():delay(250)
				end
			end
		end
		return false
	end,
	priority = 3,
}
if not sgs.Sanguosha:getSkill("kebloodangry") then skills:append(kebloodangry) end

--大杀四方
--技能卡
killaroundCard = sgs.CreateSkillCard{
	name = "killaroundCard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select)
		if (#targets > sgs.Self:getLostHp() - 1) then return false end		
		return (to_select:objectName() ~= sgs.Self:objectName()) 
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		local ppp = sgs.SPlayerList()
		room:setPlayerFlag(player, "kekilling")
		for _, p in sgs.list(targets) do
			if (p:getMark("@shixue")<5) then
				p:gainMark("@shixue")
				room:setEmotion(p, "Arcane/blooda")
				room:broadcastSkillInvoke("keblood",math.random(31,32))
			end
			ppp:append(p)
		end
		room:broadcastSkillInvoke("killaround",math.random(1,3))
		room:broadcastSkillInvoke("killaround",36)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("killaround")
		--用于不触发语音
		local card_use = sgs.CardUseStruct()
		card_use.from = player
		card_use.to = ppp
		card_use.card = slash
		room:setCardFlag(card_use.card, "SlashIgnoreArmor")
		room:useCard(card_use, false)
		slash:deleteLater() 
	end
}

killaroundVS = sgs.CreateZeroCardViewAsSkill{
	name = "killaround",
	response_pattern = "@@killaround",
	view_as = function()
		return killaroundCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
}

killaround = sgs.CreateTriggerSkill{
	name = "killaround",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	view_as_skill = killaroundVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local from = damage.from
			local room = player:getRoom()
			local data = sgs.QVariant()
			data:setValue(damage)
			if not (player:isKongcheng() or (damage.card and damage.card:getSkillName() == "killaround")) then
				if room:askForSkillInvoke(player, self:objectName(), data) then	
					player:throwAllHandCards()	
					room:setPlayerFlag(player, "kekilling")
					room:askForUseCard(player, "@@killaround", "dssf-ask")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return (player:hasSkill("killaround") )
	end,
}
kedarius:addSkill(killaround)



--诺克萨斯断头台技能卡
keduantouCard = sgs.CreateSkillCard{
	name = "keduantouCard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select)
	if (#targets ~= 0)  then return false end		
	return ( (sgs.Self:distanceTo(to_select) <= 1) and (to_select:objectName() ~= sgs.Self:objectName()))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("keduantou",math.random(1,20))	
		room:removePlayerMark(player, "@duantou")
		--if not player:hasSkill("keduantou_extra") then
		--	room:doSuperLightbox("kedarius", "keduantou")
		--end
		room:addPlayerMark(target, "Armor_Nullified")
		local damage = sgs.DamageStruct() 
		damage.from = player
		damage.to = target
		if (target:getMark("@xueyuan") > 0) then
			if not player:hasSkill("keduantou_extra") then
				room:doSuperLightbox("kedarius", "keduantou")
			end
			room:broadcastSkillInvoke("keduantou",math.random(22,27))
			room:doAnimate(1, player:objectName(), target:objectName())
			room:getThread():delay(750)
			room:broadcastSkillInvoke("keduantou",28)
		    damage.damage = 2
		end
		if (target:getMark("@xueyuan") == 0 ) then
		--if (target:getMark("@shixue") < 5) then
			room:broadcastSkillInvoke("keduantou",math.random(22,27))
			room:doAnimate(1, player:objectName(), target:objectName())
			room:getThread():delay(500)
			room:broadcastSkillInvoke("keduantou",29)
			room:broadcastSkillInvoke("keduantou",29)
			damage.damage = 1
		end
		target:loseAllMarks("@shixue")
		room:setEmotion(target, "Arcane/shining")
		room:damage(damage)
		if target:isDead() then
			if not player:hasSkill("kebloodangry") then
				player:drawCards(2)
				room:acquireOneTurnSkills(player, "keblood", "kebloodangry")
				room:broadcastSkillInvoke("kebloodangry",17)
			--	room:setPlayerFlag(player, "getxuenu")
			end
			room:addPlayerMark(player, "@duantou")
			--room:doLightbox("$dariusduantou")
			if player:hasSkill("keduantou") then
				room:broadcastSkillInvoke("keduantou",math.random(15,21))
				room:handleAcquireDetachSkills(player, "keduantou_extra|-keduantou")
				--连杀语音：
			end
		end
		room:removePlayerMark(target,"@xueyuan")
		room:removePlayerMark(target, "Armor_Nullified")
	end
}


keduantouVS = sgs.CreateViewAsSkill {
	name = "keduantou",
	n = 2,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select) 
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = keduantouCard:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		return card
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@duantou")>0)
	end,
}

--断头台主技能
keduantou = sgs.CreatePhaseChangeSkill{
	name = "keduantou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@duantou",
	view_as_skill = keduantouVS,
	on_phasechange = function()
	end
}
kedarius:addSkill(keduantou)

--杀人后的大招主技能
keduantou_extra = sgs.CreateViewAsSkill{
	name = "keduantou_extra",
	frequency = sgs.Skill_Limited,
	limit_mark = "@duantou",
	n = 0,
	view_as = function(self, cards)
		return keduantouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@duantou") > 0 )
	end, 
}
if not sgs.Sanguosha:getSkill("keduantou_extra") then skills:append(keduantou_extra) end


keduantouget = sgs.CreateTriggerSkill{
	name = "#keduantouget",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if player:getPhase() == sgs.Player_Finish then
			if (player:getMark("@duantou") == 0) then
				room:addPlayerMark(player, "@duantou")
			end
			if player:hasSkill("keduantou_extra") then
				room:handleAcquireDetachSkills(player, "-keduantou_extra|keduantou")
			end
	    end
	end,
	can_trigger = function(self, player)
		return ((player:hasSkill("keduantou")) or (player:hasSkill("keduantou_extra"))  )
	end,
 }
kedarius:addSkill(keduantouget)
extension:insertRelatedSkills("keduantou", "#keduantouget")
extension:insertRelatedSkills("keduantou_extra", "#keduantouget")


--大杀四方回血 需要修改：参照谋杨婉
kekillaroundrecover = sgs.CreateTriggerSkill{
	name = "#kekillaroundrecover",
	events = {sgs.Damage,sgs.CardFinished},
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (event == sgs.Damage) then
			local damage = data:toDamage()                                                                   
			if damage.card and damage.card:isKindOf("Slash") and player:hasFlag("kekilling") and player:hasSkill(self:objectName()) --[[and (damage.card:getSkillName() == "killaround" )]] and player:hasSkill(self:objectName()) then

				    local vic = damage.to
					if player:hasSkill("kebloodangry") then
						local cha = 5 - vic:getMark("@shixue")
						vic:gainMark("@shixue",cha)
						room:broadcastSkillInvoke("keblood",math.random(31,32))
					end
					--(player:getMaxHp() - player:getHp() > 1) then
						local recover = sgs.RecoverStruct()
						recover.who = player
				        recover.recover = 1
					    if not player:hasFlag("dssfbroad") then
						    room:broadcastSkillInvoke("killaround",math.random(4,7))
					    end
					    room:setPlayerFlag(player, "dssfbroad")
					    room:recover(player, recover)
						room:setEmotion(player, "Arcane/recover")
					--end
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") 
			and use.from:objectName() == player:objectName() and use.from:hasFlag("kekilling") and use.from:hasSkill(self:objectName()) then
				--for _, ns in sgs.qlist(room:getAllPlayers()) do
				--	if ns:hasFlag("kekilling") then
				--		room:setPlayerFlag(ns, "-kekilling")
				--	end
				--end
				room:setPlayerFlag(use.from, "-kekilling")
				if player:hasFlag("dssfbroad") then
					room:setPlayerFlag(use.from, "-dssfbroad")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player
	end
}
kedarius:addSkill(kekillaroundrecover)
extension:insertRelatedSkills("killaround", "#kekillaroundrecover")

--悲怜
kebeilianCard = sgs.CreateSkillCard{
	name = "kebeilianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return  (to_select:getMark("@shixue") > 0)
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		for _, p in sgs.list(targets) do
			room:setPlayerFlag(p,"beilianflag")
			if p:getMark("@xueyuan") > 0 then
				room:removePlayerMark(p,"@xueyuan")
			end
			p:loseAllMarks("@shixue")
			room:setPlayerFlag(p,"-beilianflag")
			p:drawCards(1)
		end
	end
}
--悲怜主技能
kebeilian = sgs.CreateViewAsSkill{
	name = "kebeilian&",
	n = 0,
	view_as = function(self, cards)
		return kebeilianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kebeilianCard"))
	end, 
}
if not sgs.Sanguosha:getSkill("kebeilian") then skills:append(kebeilian) end

kebeilianstart = sgs.CreateTriggerSkill{
	name = "#kebeilianstart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--room:handleAcquireDetachSkills(player, "kebeilian")
		room:attachSkillToPlayer(player,"kebeilian")
	end,
	can_trigger = function(self, player)
	    return player:hasSkill("keblood")
	end,
}
--if not sgs.Sanguosha:getSkill("kebeilianstart") then skills:append(kebeilianstart) end
kedarius:addSkill(kebeilianstart)

kedarius:addRelateSkill("kebeilian")


--使用杀音效
dariusslash = sgs.CreateTriggerSkill{
    name = "#dariusslash",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		if (event == sgs.TargetSpecified) then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and not use.card:getSkillName() == "killaround" then
				room:broadcastSkillInvoke("killaround",math.random(8,35))
			end
		end
	end,
}
kedarius:addSkill(dariusslash)

dariusw = sgs.CreateTriggerSkill{
	name = "#dariusw",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and (not damage.card:isKindOf("SkillCard")) then
			if (damage.damage > 1) then
				room:broadcastSkillInvoke("killaround",37)
			end
		end
	end,
}
kedarius:addSkill(dariusw)



--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--盖伦
kegaren = sgs.General(extension, "kegaren", "god", 4)


--正义
kezhengyi = sgs.CreateTriggerSkill{
	name = "kezhengyi",
	events = {sgs.Damage},
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezhengyi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local eny = damage.to
		if (eny:getHp() <= (eny:getMaxHp())/2) and (eny:isAlive()) and (player:getMark("@kezhengyi")>0) and (player:distanceTo(eny) <= 1) and (eny:objectName() ~= player:objectName()) then
			local to_data = sgs.QVariant()
			to_data:setValue(eny)
			local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
			if will_use then
				room:removePlayerMark(player,"@kezhengyi")
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = eny
			--	damage.damage = math.min(eny:getLostHp(),3)  
				damage.damage = eny:getLostHp() 
				damage.nature = sgs.DamageStruct_Thunder
				local yy = math.random(1,12)
				room:broadcastSkillInvoke(self:objectName(), yy)
				if yy == 1 then room:doLightbox("$kezhengyi1") end if yy == 2 then room:doLightbox("$kezhengyi2") end if yy == 3 then room:doLightbox("$kezhengyi3") end
				if yy == 4 then room:doLightbox("$kezhengyi4") end if yy == 5 then room:doLightbox("$kezhengyi5") end if yy == 6 then room:doLightbox("$kezhengyi6") end
				if yy == 7 then room:doLightbox("$kezhengyi7") end if yy == 8 then room:doLightbox("$kezhengyi8") end if yy == 9 then room:doLightbox("$kezhengyi9") end
				if yy == 10 then room:doLightbox("$kezhengyi10") end if yy == 11 then room:doLightbox("$kezhengyi11") end if yy == 12 then room:doLightbox("$kezhengyi12") end
				room:doAnimate(1, player:objectName(), eny:objectName())
				room:getThread():delay(750)	
				room:broadcastSkillInvoke("keshiwei", math.random(28,36))
				room:getThread():delay(250)	
				room:setEmotion(eny, "Arcane/garen_r")
				room:broadcastSkillInvoke("keshiwei", 27)
				room:getThread():delay(500)	
				room:damage(damage)	
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName()) and (target:getMark("@kezhengyi") > 0)
	end,
}
kegaren:addSkill(kezhengyi)


--狮威

keshiwei_bysz = sgs.CreateViewAsEquipSkill{
	name = "#keshiwei_bysz",
	view_as_equip = function(self,player)
		if player:getMark("garenbysz")>0 then
		    return "silver_lion"
		end
	end
}
kegaren:addSkill(keshiwei_bysz)

--判断是否造成伤害
--[[kegarenda = sgs.CreateTriggerSkill{
	name = "#kegarenda",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		--判断一下“狮勇”技能有没有造成伤害
		if (player:getPhase() == sgs.Player_Play) then
			if not player:hasFlag("garendamage") then
				room:setPlayerFlag(player, "garendamage")
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName()) 
	end,
}
kegaren:addSkill(kegarenda)]]


keshiwei = sgs.CreateTriggerSkill{
	name = "keshiwei",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			--判断一下“狮勇”技能有没有造成伤害
			if (player:getPhase() == sgs.Player_Play) then
				if not player:hasFlag("garendamage") then
					room:setPlayerFlag(player, "garendamage")
				end
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				room:broadcastSkillInvoke(self:objectName(), 25)
				if player:getMark("&kehaojin") > 0 then
					room:setPlayerMark(player,"&kehaojin",0)
				end
				if not player:hasFlag("garendamage") then
					room:setPlayerMark(player,"garenbysz",0)
					room:setPlayerMark(player,"@kebysz",0)
					if room:askForSkillInvoke(player, self:objectName(), data) then
						if (not player:isWounded()) or (player:getHp() > 2) then
							player:drawCards(1)
						end
						if player:isWounded() and (player:getHp() <= 2) then
							room:recover(player, sgs.RecoverStruct())
						end
						room:broadcastSkillInvoke(self:objectName(),math.random(1,21))
						room:getThread():delay(500)	
					end
				end
				if player:hasFlag("garendamage") then
					player:drawCards(1)
					room:setPlayerMark(player,"garenbysz",1)
					room:setPlayerMark(player,"@kebysz",1)
					room:broadcastSkillInvoke(self:objectName(),math.random(1,21))
					room:getThread():delay(500)	
				end
			end
		end
	end
}
kegaren:addSkill(keshiwei)
extension:insertRelatedSkills("keshiwei", "#keshiwei_bysz")

--豪进
kehaojinCard = sgs.CreateSkillCard{
	name = "kehaojinCard" ,
	target_fixed = true ,
	mute = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("kehaojin",math.random(1,31))
		room:addSlashCishu(source, 1, true)
		room:broadcastSkillInvoke("keshiwei",26)
		room:addPlayerMark(source,"&kehaojin")
	end
}
kehaojinVS = sgs.CreateViewAsSkill{
	name = "kehaojin" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kehaojinCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kehaojinCard")
	end
}

--q距离
kegarenjuli = sgs.CreateTargetModSkill{
	name = "#kegarenjuli",
	distance_limit_func = function(self, from, card)
		if (from:getMark("&kehaojin")>0)  then
			return 1
		end
	end
}
kecaitlyn:addSkill(kegarenjuli)


kehaojin = sgs.CreateTriggerSkill{
	name = "kehaojin",
	events = {sgs.CardFinished,sgs.ConfirmDamage,sgs.TargetSpecified,sgs.EventPhaseChanging},
	view_as_skill = kehaojinVS,
	--priority = 3,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash"))  and player:hasSkill(self:objectName()) then
				room:removePlayerMark(player,"&kehaojin")
			end
		end
		if (event == sgs.ConfirmDamage) and player:hasSkill(self:objectName()) then
		    local damage = data:toDamage()
			if (player:getMark("&kehaojin")>0) 
			and (damage.card:isKindOf("Slash")) 
			and (damage.from:objectName() == player:objectName()) then
				room:setPlayerCardLimitation(damage.to, "use,response", "TrickCard", false)
		        room:setPlayerCardLimitation(damage.to, "use,response", "EquipCard", false)
				room:getThread():delay(250)	
				room:setEmotion(damage.to, "Arcane/garensilence")
				room:setEmotion(damage.to, "Arcane/garen_q")
				room:setPlayerMark(damage.to,"&haojinsilence",1)
			end
		end
		if (event == sgs.TargetSpecified) and (player:hasSkill(self:objectName())) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash")) and (player:getMark("&kehaojin")>0) 
			and (use.from:objectName() == player:objectName()) then
				for _, p in sgs.qlist(use.to) do   
					if (p:getMark("@skill_invalidity") == 0) then   
					    room:addPlayerMark(p, "@skill_invalidity")
					    room:setPlayerMark(p,"haojinskill",1)
					end
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			local phase = change.to
			if (player:getMark("&haojinsilence") >= 1) then
				if phase == sgs.Player_NotActive then
					room:setPlayerMark(player,"&haojinsilence",0)
					room:removePlayerCardLimitation(player, "use,response", "TrickCard")
					room:removePlayerCardLimitation(player, "use,response", "EquipCard")
				end
			end
			if (player:getMark("haojinskill") >= 1) then
				if phase == sgs.Player_NotActive then
					room:removePlayerMark(player,"haojinskill",player:getMark("&haojinsilence"))
					room:setPlayerMark(player,"@skill_invalidity",0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
kegaren:addSkill(kehaojin)
extension:insertRelatedSkills("kehaojin", "#kegarenjuli")

--豪进清除
--[[kehaojinclear = sgs.CreateTriggerSkill{
	name = "#kehaojinclear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	   
	end,
	can_trigger = function(self, target)
	   return target:isAlive()
	end,
}
kegaren:addSkill(kehaojinclear)]]

--普攻
kegarenaaa = sgs.CreateTriggerSkill{
    name = "#kegarenaaa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:getMark("&kehaojin") == 0) then
			room:broadcastSkillInvoke("keshiwei", math.random(22,23))
			for _, p in sgs.qlist(use.to) do
                room:setEmotion(p, "Arcane/garen_a")
			end
			local yy = math.random(1,3)
			if yy == 1 then
				room:broadcastSkillInvoke("keshiwei", math.random(28,36))
			end
			if not (yy == 1) then
				room:broadcastSkillInvoke("kehaojin", math.random(32,61))
			end
		end
		if use.card:isKindOf("Slash") and (player:getMark("&kehaojin") > 0) then
			room:broadcastSkillInvoke("keshiwei", 24)
			for _, p in sgs.qlist(use.to) do
                room:setEmotion(p, "Arcane/garen_a")
			end
			local yy = math.random(1,3)
			if yy == 1 then
				room:broadcastSkillInvoke("keshiwei", math.random(28,36))
			end
			if not (yy == 1) then
				room:broadcastSkillInvoke("kehaojin", math.random(32,61))
			end
		end
	end
}
kegaren:addSkill(kegarenaaa)

--击杀语音
kegarenkill = sgs.CreateTriggerSkill{
	name = "#kegarenkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.damage and death.damage.from then
			if death.damage.from:hasSkill(kegarenkill) then
				room:broadcastSkillInvoke("kehaojin",math.random(62,67))
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kegaren:addSkill(kegarenkill)


--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--拉克丝

kelux = sgs.General(extension, "kelux", "god", 3, false)

keguangfuCard = sgs.CreateSkillCard{
	name = "keguangfuCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName()) and (sgs.Self:canPindian(to_select, true))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("keguangfu", 26)
		local qyy = math.random(1,2)
		if qyy == 1 then
		    room:broadcastSkillInvoke("keguangfu", math.random(35,50))
		end
		player:drawCards(1)
		local success = player:pindian(target, "keguangfu", nil)
		if success then
			room:broadcastSkillInvoke("keguangfu", 27)
			if not player:hasSkill("kelux_r") then
			    room:broadcastSkillInvoke("keguangfu", math.random(1,18))
			end
			room:addPlayerMark(target,"&bluxq")
			--锁手牌--锁技能
			room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", false)
			--距离改变
			for _, p in sgs.qlist(room:getOtherPlayers(target)) do
				room:setFixedDistance(p, target, 1)
			end
			if player:hasSkill("kelux_r") then
				--if room:askForSkillInvoke(player, "luxr-ask", data) then
					--台词语音加动画
					local yy = math.random(1,4)
					room:broadcastSkillInvoke("kelux_r", yy)
					if yy == 1 then
						room:doLightbox("$keluxtext1")
						room:getThread():delay(250)
					end
					if yy == 2 then
						room:doLightbox("$keluxtext2")
						room:getThread():delay(250)
					end
					if yy == 3 then
						room:doLightbox("$keluxtext3")
						room:getThread():delay(250)
					end
					if yy == 4 then
						room:doLightbox("$keluxtext4")
						room:getThread():delay(250)
					end
					--啊语音
					room:doAnimate(1, player:objectName(), target:objectName())
					room:broadcastSkillInvoke("kelux_r", math.random(5,7))
					room:broadcastSkillInvoke("kelux_r", 8)
					room:getThread():delay(1000)
					room:setEmotion(target, "Arcane/luxr")
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = target
					damage.damage = 1
					damage.nature = sgs.DamageStruct_Fire
					room:damage(damage)
				--end
			end
			room:addPlayerMark(target, "Armor_Nullified")
		else
			room:broadcastSkillInvoke("keguangfu", math.random(19,25))
			if not player:hasSkill("kelux_r") then
				if target:canSlash(player, nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					--slash:setSkillName("keguangfu")
					local card_use = sgs.CardUseStruct()
					card_use.from = target
					card_use.to:append(player)
					card_use.card = slash
					room:useCard(card_use, false)     
					slash:deleteLater()                                                         
				end
			end
		end	
	end
}

--光缚主技能
keguangfuVS = sgs.CreateViewAsSkill{
	name = "keguangfu",
	n = 0,
	view_as = function(self, cards)
		return keguangfuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#keguangfuCard")) 
	end, 
}

--距离和防具清除
keguangfu = sgs.CreateTriggerSkill{
    name = "keguangfu",
	view_as_skill = keguangfuVS,
	events = {sgs.EventPhaseStart,sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if p:getMark("&bluxq") > 0 then
						room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
						room:removePlayerMark(p, "&bluxq")
						room:removePlayerMark(p, "Armor_Nullified")
						for _, oth in sgs.qlist(room:getOtherPlayers(p)) do
							room:setFixedDistance(oth, p, -1)
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("&bluxq")>0 then
				room:removePlayerMark(player, "&bluxq")
				room:removePlayerMark(player, "Armor_Nullified")
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setFixedDistance(p, player, -1)
				end
			end
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("&bluxq")>0 then
						--这里不着急失去标记，等到解锁技能再失去
						room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
kelux:addSkill(keguangfu)

--不能用手牌的解锁

--[[keluxq_extra2  = sgs.CreateTriggerSkill{
	name = "keluxq_extra2",
	frequency = sgs.Skill_Frequent,
	global = true,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	   local room = player:getRoom()
	   if player:getPhase() == sgs.Player_Finish then
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("&bluxq")>0 then
				--这里不着急失去标记，等到解锁技能再失去
				room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
			end
		end
	end
	end,
	can_trigger = function(self, player)
		return true
	end,
 }
 if not sgs.Sanguosha:getSkill("keluxq_extra2") then skills:append(keluxq_extra2) end]]

--曲光
kequguang = sgs.CreateTriggerSkill{
    name = "kequguang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Finish then
			return false
		end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local tzs = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "quguang-ask", true, true)
			room:doAnimate(1, player:objectName(), tzs:objectName()) 
			room:getThread():delay(300)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,12))
		    room:broadcastSkillInvoke(self:objectName(), 13)
		--队友血少
			if tzs:getHp() < player:getHp() then
				room:drawCards(player, 1, self:objectName())
				if tzs:getHujia()>=1 then
				    room:drawCards(tzs, 1, self:objectName())
				end
				if tzs:getHujia()<1 then
				    tzs:gainHujia(1)
				end
			end
		--自己血少
			if (tzs:getHp() >= player:getHp())  then
				room:drawCards(tzs, 1, self:objectName())
				if player:getHujia()>=1 then
				    room:drawCards(player, 1, self:objectName())
				end
				if player:getHujia()<1 then
				    player:gainHujia(1)
				end
			end
		end
	end,
}
kelux:addSkill(kequguang)



--光辉觉醒技
keluxr = sgs.CreateTriggerSkill{
	name = "keluxr",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	waked_skills = "kelux_r",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		if not ((player:getHp() == 1) or (player:getHandcardNum() == 0)) then
			can_invoke = false
		end

		if can_invoke or player:canWake(self:objectName()) then
			if room:changeMaxHpForAwakenSkill(player, 0) then
			room:addPlayerMark(player, "keluxr")
			room:broadcastSkillInvoke("keluxr")
			room:doSuperLightbox("kelux", "keluxr")
			room:recover(player, sgs.RecoverStruct())
			player:drawCards(2)
			room:handleAcquireDetachSkills(player, "kelux_r")
			room:broadcastSkillInvoke("anjiangbgm", 2)
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:isAlive()
				and (target:getMark("@luxr") == 0)
				and (target:hasSkill("keluxr"))
	end,
	--priority = 3,
}
kelux:addSkill(keluxr)

--空壳rr（内容直接写在拼点里）
kelux_r  = sgs.CreateTriggerSkill{
	name = "kelux_r",
	frequency = sgs.Skill_Limited,
	limit_mark = "@luxr",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	end,
	can_trigger = function(self, player)
		return player:hasSkill("nonononono")
	end,
 }
 if not sgs.Sanguosha:getSkill("kelux_r") then skills:append(kelux_r) end

 --击杀语音
keluxkill = sgs.CreateTriggerSkill{
	name = "#keluxkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local reason = death.damage
		if death.damage and death.damage.from then
			local killer = reason.from
			if killer:hasSkill(keluxkill) then
				room:broadcastSkillInvoke("keguangfu",math.random(51,52))
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kelux:addSkill(keluxkill)

--平a音效
keluxaaa = sgs.CreateTriggerSkill{
    name = "#keluxaaa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("keguangfu", 28)
			room:broadcastSkillInvoke("keguangfu", math.random(31,50))
		end
	end
}
kelux:addSkill(keluxaaa)

--命中音效
luxahit = sgs.CreateTriggerSkill{
	name = "#luxahit",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local vic = damage.to
		if damage.card and damage.card:isKindOf("Slash") and (vic:getMark("&bluxq") == 0) then
			room:broadcastSkillInvoke("keguangfu", 29)
			room:setEmotion(vic, "Arcane/luxa")
		end
		if damage.card and damage.card:isKindOf("Slash") and (vic:getMark("&bluxq") > 0) then
			room:broadcastSkillInvoke("keguangfu", 30)
			room:setEmotion(vic, "Arcane/luxa")
		end
	end,
}
kelux:addSkill(luxahit)












--阿兹尔
keazir = sgs.General(extension, "keazir", "god", 3, true)

--出牌阶段的复活版本

azirshenjiCard = sgs.CreateSkillCard{
	name = "azirshenjiCard",
	target_fixed = true,
	will_throw = true,
	mute = true,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
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
		--if #choices > 0 then
		--玩家选择一名死亡的角色
			local choice = room:askForChoice(player, "shenji-ask", table.concat(choices, "+"))
		if not (choice == "cancel") then
			for _, pp in sgs.qlist(room:getAllPlayers(true)) do
				--判断死亡的人的名字，跟选择的人是否符合，令其复活
				if pp:isDead() and (pp:getGeneralName() == choice) then
					room:doLightbox("$keshuruima")
					room:removePlayerMark(player,"@azirshenji")
					--player:loseAllMarks("@azirshenji")
			        room:broadcastSkillInvoke("azirshenji")
					room:broadcastSkillInvoke("azirslash",24)
					room:doSuperLightbox("keazir", "azirshenji")
					room:doAnimate(1, player:objectName(), pp:objectName()) 
					room:revivePlayer(pp)
					pp:throwAllMarks()
					room:changeHero(pp, "kesolardisk", true, true, false, true)
					if player:getRole() == "lord" then
						room:setPlayerProperty(pp, "role", sgs.QVariant("loyalist"))
					end
					if player:getRole() == "loyalist" then
						room:setPlayerProperty(pp, "role", sgs.QVariant("loyalist"))
					end
					if player:getRole() == "rebel" then
						room:setPlayerProperty(pp, "role", sgs.QVariant("rebel"))
					end
					if player:getRole() == "renegade" then
						room:setPlayerProperty(pp, "role", sgs.QVariant("renegade"))
					end
					local hp = pp:getMaxHp()
					room:setPlayerProperty(pp, "hp", sgs.QVariant(hp))
				end
			end	
		end
		end
	end
}

azirshenjiVS = sgs.CreateViewAsSkill{
	name = "azirshenji",
	n = 0,
	limit_mark = "@azirshenji",
	view_as = function(self, cards)
		return azirshenjiCard:clone()
	end,
	enabled_at_play = function(self, player)
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isDead() then
				return (player:getMark("@azirshenji") > 0) 
			end
		end
	end, 
}
azirshenji = sgs.CreateTriggerSkill {
	name = "azirshenji",
	frequency = sgs.Skill_Limited,
	view_as_skill = azirshenjiVS,
	limit_mark = "@azirshenji",
	events = {},
	on_trigger = function(self, event, player, data)
	end
}

keazir:addSkill(azirshenji)

--开始获得沙兵
--[[sandsoldierstart = sgs.CreateTriggerSkill{
	name = "sandsoldierstart",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player,"@sandsoldier")
	end,
	can_trigger = function(self, player)
	    return player:hasSkill(d_movesoldier)
	end,
}
if not sgs.Sanguosha:getSkill("sandsoldierstart") then skills:append(sandsoldierstart) end
]]


--出牌阶段移动沙兵

playmovesoldierCard = sgs.CreateSkillCard{
	name = "playmovesoldierCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and  ( to_select:getMark("@sandsoldier") == 0 )
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		local target = targets[1]
		for _, q in sgs.qlist(room:getAllPlayers()) do        
			if  (q:getMark("@sandsoldier") == 1) then
				room:removePlayerMark(q,"@sandsoldier")
				--q:loseAllMarks("@sandsoldier")
			end
		end
		--target:gainMark("@sandsoldier")
		room:addPlayerMark(target,"@sandsoldier")

		if (player:getMark("@sandsoldier") == 1)   then
			local zuidi = true
			local ppp = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:hasSkill("kejiguan") then
					ppp:append(p)
				end
			end
			for _, q in sgs.qlist(ppp) do
				if (player:getHp() > q:getHp()) then
					zuidi = false
				end
			end
			if (zuidi == true) and (player:getHujia() == 0) then
				player:gainHujia(1)
			end
			--if not (zuidi == true)  then
				player:drawCards(1)
			--end
			room:broadcastSkillInvoke("azirslash",23)
			room:broadcastSkillInvoke("azirslash",math.random(14,20))
		end
		--弃牌
		if (player:getMark("@sandsoldier") ~= 1) then
			room:broadcastSkillInvoke("azirslash",21)
			room:broadcastSkillInvoke("azirslash",math.random(8,13))
			if player:canDiscard(target, "he") then
				local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(id, target, player)
			end
		end
	end
}

playmovesoldierVS = sgs.CreateViewAsSkill{
	name = "playmovesoldier",
	n = 0,
	view_as = function(self, cards)
		return playmovesoldierCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#playmovesoldierCard"))
	end, 
}


--受伤移动沙兵
playmovesoldier = sgs.CreateTriggerSkill{
	name = "playmovesoldier",
	view_as_skill = playmovesoldierVS,
	events = {sgs.Damaged,sgs.GameStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:addPlayerMark(player,"@sandsoldier")
		end
		if event == sgs.Damaged then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do        
					if  (p:getMark("@sandsoldier") == 0) then
						players:append(p)
					end
				end
				if not players:isEmpty() then 
					local newone = room:askForPlayerChosen(player, players, self:objectName(), "movesoldier-ask", true, true)
					if not newone then return false end
					for _, q in sgs.qlist(room:getAllPlayers()) do        
						if  (q:getMark("@sandsoldier") == 1) then
							room:removePlayerMark(q,"@sandsoldier")
						end
					end
					room:addPlayerMark(newone,"@sandsoldier")
					player:drawCards(1)
					if (player:getMark("@sandsoldier") == 1)then
						player:drawCards(1)
					end
					if (player:getMark("@sandsoldier") == 1) and (player:getHujia() == 0) then
						local zuidi = true
						local ppp = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if not (p:getGeneralName() == "kesolardisk" or p:getGeneral2Name() == "kesolardisk") then
								ppp:append(p)
							end
						end
						for _, q in sgs.qlist(ppp) do
							if (player:getHp() > q:getHp()) then
								zuidi = false
							end
						end
						if (zuidi == true) and (player:getHujia() == 0) then
							player:gainHujia(1)
						end
						if not (zuidi == true) then
							player:drawCards(1)
						end
						--防御
						room:broadcastSkillInvoke("azirslash",23)
						room:broadcastSkillInvoke("azirslash",math.random(14,20))
					end
					if (player:getMark("@sandsoldier") ~= 1) then
						room:broadcastSkillInvoke("azirslash",21)
						room:broadcastSkillInvoke("azirslash",math.random(8,13))
						if player:canDiscard(newone, "he") then
							local id = room:askForCardChosen(player, newone, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, newone, player)
							--进攻
						end
					end
				end
			end
		end
	end
}
keazir:addSkill(playmovesoldier)


--狂沙猛攻

azirslash = sgs.CreateTriggerSkill{
	name = "azirslash",
	events = {sgs.CardFinished,sgs.EventPhaseStart,sgs.BuryVictim},
	frequency = sgs.Skill_NotFrequent, 
	can_trigger = function(self, target)
		return target 
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.BuryVictim) then
			local death = data:toDeath()
			local nosoldier = 1
			for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
				if (p:getMark("@sandsoldier") > 0) then
					nosoldier = 0
					break
				end
			end
			if nosoldier == 1 then
				for _, azir in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:addPlayerMark(azir,"@sandsoldier")
					local zuidi = true
					local ppp = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(azir)) do
						if not p:hasSkill("kejiguan") then
							ppp:append(p)
						end
					end
					for _, q in sgs.qlist(ppp) do
						if (azir:getHp() > q:getHp()) then
							zuidi = false
						end
					end
					if (zuidi == true) and (azir:getHujia() == 0) then
						azir:gainHujia(1)
					end
					if not (zuidi == true)  then
						azir:drawCards(1)
					end
				end
			end
		end
		if (event == sgs.CardFinished) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if (player:getMark("@sandsoldier") == 0) and (player:getMark("azirslash-Clear") == 0) then
				if (use.card:isKindOf("Slash") or use.card:isNDTrick() ) and (use.to:length() == 1) and not use.to:contains(player) then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName(),22)
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAllPlayers()) do        
							if  (p:getMark("@sandsoldier") > 0) then
								players:append(p)
							end
						end
						room:broadcastSkillInvoke(self:objectName(),math.random(1,7))
						local jnplayers = sgs.SPlayerList()
						for _, ppp in sgs.qlist(players) do    
							jnplayers:append(ppp)   
							room:doAnimate(1, player:objectName(), ppp:objectName()) 
							use.card:use(room, use.from, jnplayers)
						end
						room:addPlayerMark(player, "azirslash-Clear")
					end
				end
			end
		end
	end
}
keazir:addSkill(azirslash)

--杀音效
aziruseslash = sgs.CreateTriggerSkill{
    name = "#aziruseslash",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash")  then
			room:broadcastSkillInvoke("azirslash", math.random(25,29))
		end
	end
}
keazir:addSkill(aziruseslash)



--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

--太阳圆盘

kesolardisk = sgs.General(extension, "kesolardisk", "god", 4, true, true)
kesolardisk:setGender(sgs.General_Sexless)

--防止azir对防御塔造成伤害
--[[keazirdiskdamage = sgs.CreateTriggerSkill{
	name = "#keazirdiskdamage",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local azir = damage.from
		local room = player:getRoom()
		if azir:hasSkill("azirshenji") then
	        return true 
		end
	end,
	can_trigger = function(self, player)
		return (player:hasSkill("kesolardiskslash"))
	end
}
kesolardisk:addSkill(keazirdiskdamage)]]

--杀音效
--[[kesolardiskslash = sgs.CreateTriggerSkill{
    name = "#kesolardiskslash",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash")  then
			room:broadcastSkillInvoke("kejiguan")
		end
	end
}
kesolardisk:addSkill(kesolardiskslash)]]

 --掉血,废除装备栏
kejiguan = sgs.CreateTriggerSkill{
	name = "kejiguan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.TargetConfirming,sgs.Dying,sgs.TargetSpecified,sgs.DamageInflicted,sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_Play) 
			and (player:getMark("kejiguanusedsalsh-Clear") == 0)
			and (player:getState() ~= "online") then
				room:askForUseSlashTo(player,room:getOtherPlayers(),"kejiguan-ask",false,false,false,nil,nil)
			end
		end
		if (event == sgs.CardUsed) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player,"kejiguanusedsalsh-Clear",1)
			end
		end
		if (event == sgs.DamageInflicted) and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			local azir = damage.from
			local room = player:getRoom()
			if azir:hasSkill("azirshenji") then
				return true 
			end
		end
	    if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Start and player:hasEquipArea() then
				player:throwEquipArea()		 
			end
			if player:getPhase() == sgs.Player_Finish then
				room:loseHp(player)
			end
		end
		if (event == sgs.TargetConfirming) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash")  then
				room:setCardFlag(use.card, "SlashIgnoreArmor")
			end
		end
		if (event == sgs.Dying) then
			local room = player:getRoom()
			local dying_data = data:toDying()
			local source = dying_data.who
			if source:hasSkill("kejiguan") then
				room:killPlayer(source)
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke("kejiguan")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
 }
 kesolardisk:addSkill(kejiguan)
--濒死不能被救

--距离
kesolardiskTargetMod = sgs.CreateTargetModSkill{
	name = "#kesolardiskTargetMod",
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}
kesolardisk:addSkill(kesolardiskTargetMod)
extension:insertRelatedSkills("kejiguan", "#kesolardiskTargetMod")

kejiguaner = sgs.CreateFilterSkill{
	name = "#kejiguaner", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return place == sgs.Player_PlaceHand
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
kesolardisk:addSkill(kejiguaner)
extension:insertRelatedSkills("kejiguan", "#kejiguaner")

--不能杀阿兹尔
kejiguansi = sgs.CreateProhibitSkill{
	name = "#kejiguansi",
	is_prohibited = function(self, from, to, card)
		return to and to:hasSkill(self:objectName()) and (card:isKindOf("Slash")) and from and (from:hasSkill("kejiguan"))
	end
}
keazir:addSkill(kejiguansi)
extension:insertRelatedSkills("kejiguan", "#kejiguansi")

--其他牌不能对防御塔使用
kejiguanliu = sgs.CreateProhibitSkill{
	name = "#kejiguanliu",
	is_prohibited = function(self, from, to, card)
		return to and to:hasSkill(self:objectName()) and not card:isKindOf("Slash")
	end
}
kesolardisk:addSkill(kejiguanliu)
extension:insertRelatedSkills("kejiguan", "#kejiguanliu")

--跳过奖惩
kejiguan_nopay = sgs.CreateTriggerSkill{
	name = "#kejiguan_nopay",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer then
				if killer:isAlive() and (death.who:hasSkill("kejiguan")) then
					local room = player:getRoom()
					room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
					player:bury()
				end
				if killer:hasSkill("kejiguan") then
					local room = player:getRoom()
					for _, azir in sgs.qlist(room:findPlayersBySkillName("azirshenji")) do
						azir:drawCards(3)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
 }
kesolardisk:addSkill(kejiguan_nopay)
extension:insertRelatedSkills("kejiguan", "#kejiguan_nopay")

 kejiguan_nopayClear = sgs.CreateTriggerSkill{
	name = "kejiguan_nopayClear",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer then
				local room = player:getRoom()
				room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target 
	end,
	priority = -1,
 }
 if not sgs.Sanguosha:getSkill("kejiguan_nopayClear") then skills:append(kejiguan_nopayClear) end



sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["kearcane"] = "双城之战",

    --拉克丝
	["kelux"] = "拉克丝", 
	["&kelux"] = "拉克丝",
	["#kelux"] = "绽华溢彩",
	["designer:kelux"] = "小珂酱",
	["cv:kelux"] = "官方",
	["illustrator:kelux"] = "官方",

--曲光
	["kequguang"] = "曲光",
	["quguang-ask"] = "请选择发动“曲光”保护的角色",
	[":kequguang"] = "<font color='#CFB53B'><b>结束阶段开始时</b></font>，你可以选择一名其他角色，若你的体力值大于该角色，其获得1点护甲，你摸一张牌，否则你获得1点护甲，其摸一张牌；\
	◆若已有至少1点护甲，获得护甲改为摸一张牌。",

--光缚
	["keguangfu"] = "光缚",
	["bluxq"] = "光之束缚",
	[":keguangfu"] = "<font color='#CFB53B'><b>出牌阶段限一次</b></font><font color='#CFB53B'><b>,</b></font>你可以摸一张牌并与一名角色拼点：\
	<font color='#CFB53B'>○若你赢，</font>该角色本回合不能使用或打出手牌，且直到其下个回合开始，其防具无效，所有角色与其距离视为1。\
	<font color='#CFB53B'>○若你没赢，</font>视为其对你使用一张【杀】。",
--觉醒大招
	["kelux_r"] = "闪炽",
	[":kelux_r"] = "当你发动“光缚”拼点赢后，你对拼点没赢的角色造成1点火焰伤害；若你发动“光缚”拼点没赢，取消后续的效果。",
	["keluxr"] = "破晓",
	[":keluxr"] = "<font color='#CFB53B'><b>觉醒技</b></font><font color='#CFB53B'><b>，</b></font>准备阶段开始时，若你的体力值为1或没有手牌，你回复1点体力并摸两张牌，然后获得技能“闪炽”。",
	["luxgotr"] = "破晓发动",
	["@luxr"] = "闪炽",
	["$keluxtext1"] = "德玛西亚！",
	["$keluxtext2"] = "德玛西亚之光！",
	["$keluxtext3"] = "毫无保留！",
	["$keluxtext4"] = "以光之名！",
	--["$keluxtext0"] = "终极闪光！",


--台词
	["$kequguang1"] = "光辉闪耀，便是家园。",
	["$kequguang2"] = "你希望长大以后做什么呢？",
	["$kequguang3"] = "世界的阴影已经太多了。",
	["$kequguang4"] = "我会保护你！",
	["$kequguang5"] = "我们尽情闪耀，如同钻石。",
	["$kequguang6"] = "我们可以的！",
	["$kequguang7"] = "我们同心协力！",
	["$kequguang8"] = "喜欢彩虹吗！",
	["$kequguang9"] = "我相信你，并不只是因为我们来自同一个地方。",
	["$kequguang10"] = "永不放弃，是一种更为高超的战术。",
	["$kequguang11"] = "永远不要否定自己。",
	["$kequguang12"] = "与我一同闪耀。",
	["$kequguang13"] = "（曲光屏障）",
	["$keguangfu1"] = "光之束缚！",
	["$keguangfu2"] = "挥动魔杖不需要任何理由。",
	["$keguangfu3"] = "结束战斗吧！",
	["$keguangfu4"] = "没有了光，暗影也就不存在了。",
	["$keguangfu5"] = "太阳正在闪耀，我们也该这样。",
	["$keguangfu6"] = "突破极限。",
	["$keguangfu7"] = "为了正义和所有的光明。",
	["$keguangfu8"] = "我们的家族里，人人都要成为英雄。",
	["$keguangfu9"] = "我要看尽世界。",
	["$keguangfu10"] = "战场上的灯塔！",
	["$keguangfu11"] = "这是我的选择。",
	["$keguangfu12"] = "点亮敌人！",
	["$keguangfu13"] = "黑暗退散！",
	["$keguangfu14"] = "站住！",
	["$keguangfu15"] = "烧尽黑暗！",
	["$keguangfu16"] = "照亮前途！",
	["$keguangfu17"] = "照耀吧！",
	["$keguangfu18"] = "抓到你了。",
	["$keguangfu19"] = "嘿，你说谁是小妞？！",
	["$keguangfu20"] = "你不喜欢我，好吧，我还不如跟石像聊天呢。",
	["$keguangfu21"] = "你好，无缘无故想要杀我的人，很高兴见到你。",
	["$keguangfu22"] = "你所谴责的，就是你所不理解的。",
	["$keguangfu23"] = "如果你厌恶魔法，就和瞎子没有区别。",
	["$keguangfu24"] = "我会告诉盖伦的！",
	["$keguangfu25"] = "我们应该先试着当朋友，不要吗？",
	["$keguangfu26"] = "（光之束缚）",
	["$keguangfu27"] = "（命中）",
	["$keguangfu28"] = "（普通攻击）",
	["$keguangfu29"] = "（普攻命中）",
	["$keguangfu30"] = "（命中光缚角色）",
	["$keguangfu31"] = "保持积极！",
	["$keguangfu32"] = "保持信念",
	["$keguangfu33"] = "光辉追随着我的步伐。",
	["$keguangfu34"] = "光明赐予勇气",
	["$keguangfu35"] = "啊！",
	["$keguangfu36"] = "哒！",
	["$keguangfu37"] = "嗯！",
	["$keguangfu38"] = "哒！",
	["$keguangfu39"] = "嗯！",
	["$keguangfu40"] = "哈！",
	["$keguangfu41"] = "呵！",
	["$keguangfu42"] = "哈！",
	["$keguangfu43"] = "呵！",
	["$keguangfu44"] = "呵！",
	["$keguangfu45"] = "哈！",
	["$keguangfu46"] = "呵！",
	["$keguangfu47"] = "哈！",
	["$keguangfu48"] = "哼！",
	["$keguangfu49"] = "啊！",
	["$keguangfu50"] = "呵！",
	["$keguangfu51"] = "（击杀）光会指引你，即使是此刻。",
	["$keguangfu52"] = "（击杀）如果我道歉，你会好受些吗？",

	["$keluxr1"] = "失败是机会，让我们变得更加闪亮！",
	["$keluxr2"] = "光这种东西，永远不会消逝！",
	["$keluxr3"] = "我没有黑暗沉重的秘密，都是轻松明亮的。",
	["$keluxr4"] = "我已经压抑自己的光芒太久了！",
	["$kelux_r1"] = "德玛西亚！",
	["$kelux_r2"] = "德玛西亚之光！",
	["$kelux_r3"] = "毫无保留！",
	["$kelux_r4"] = "以光之名！",
	["$kelux_r5"] = "呵~啊！",
	["$kelux_r6"] = "啊~啊！",
	["$kelux_r7"] = "呵~哇！",
	["$kelux_r8"] = "（终极闪光）",
	["~kelux"] = "光...灭了...",



--盖伦
	["gailun"] = "盖伦",
	["#gailun"] = "德玛西亚之力",
	["gazhican"] = "致残",
	["luazhican"] = "致残",
	["zhican"] = "致残",
	[":Luazhican"] = "每回合限一次，当你使用【杀】对目标角色造成伤害后，你可以令其直到下个结束阶段不能使用锦囊牌。",
	[":gailunjuli"] = "锁定技,当你体力值不大于2，你使用【杀】无距离限制。",
	[":gailunhujia"] = "准备阶段，你摸一张牌；然后若你至少已损失3点体力值，你获得1点护甲。",
	[":gailunmubiao"] = "锁定技，你使用【杀】可以额外指定一名角色为目标；当你体力值不大于2，你的攻击范围无限。",
	[":gailunxiangying"] = "锁定技，当你使用【杀】指定目标后，若你的手牌数大于你的体力值，你令此【杀】不可被响应。",
 

	["gazhengyi"] = "正义",
	["gailunjuli"] = "冲刺",
	["gailunhujia"] = "勇气",

	["luazhengyi"] = "正义",
	["@zhengyi"] = "正义",
	[":Luazhengyi"] = "限定技，当你对一名角色造成伤害时，若此次伤害值不小于其体力值，你可以对其造成X点雷电伤害（X为其已损失的体力值）。准备阶段或你发动“致残”时，若你至少已损失3点体力值，“正义”视为未发动过。",
	["$Luazhengyi1"] = "正义必胜！",
	["$rhLuazhengyi"] = "接受制裁吧！",
	["~gailun"] = "额啊，德玛西亚。",




--阿兹尔
	["keazir"] = "阿兹尔", 
	["&keazir"] = "阿兹尔",
	["#keazir"] = "沙漠皇帝",
	["designer:keazir"] = "小珂酱",
	["cv:keazir"] = "官方",
	["illustrator:keazir"] = "官方",
--神迹
	["azirshenji"] = "神迹",
	["@azirshenji"] = "神迹",
	["shenji-ask"] = "请选择召唤地点",
	["azirshenjiCard"] = "神迹",
	["canshenji"] = "神迹",
	["playmovesoldierCard"] = "沙卫",
	[":azirshenji"] = "<font color='#CC9966'><b>限定技</b></font><font color='#CC9966'><b>，</b></font>出牌阶段，你可以在一名已阵亡角色处召唤“太阳圆盘”且改为与你相同阵营。",
	["$keshuruima"] = "恕瑞玛即将崛起...",
	

	["playmovesoldier"] = "沙卫",
	[":playmovesoldier"] = "<font color='#CC9966'><b>出牌阶段限一次</b></font><font color='#CC9966'><b>，</b></font>你可以移动“沙兵”；<font color='#CC9966'><b>当你受到伤害时</b></font>，你可以移动“沙兵”，然后摸一张牌。\
	◆你收回“沙兵”时摸一张牌，然后若你体力值为全场最少（不计太阳圆盘），你获得1点护甲（至多1点）。\
	◆当“沙兵”移动到其他角色处时，你弃置该角色一张牌。",
	["#d_movesoldier"] = "沙卫",
	["@sandsoldier"] = "黄沙士兵",

	["azirslash"] = "狂沙",
	["movesoldier-ask"] = "请对黄沙士兵作出指令",
	[":azirslash"] = "<font color='#CC9966'><b>每回合限一次</b></font>，当你对其他角色使用的指定唯一目标使用【杀】或普通锦囊牌结算完毕后，你可以令“沙兵”所在处的其他角色执行一次此牌的结算。",

	["~keazir"] = "恕瑞玛...",

	["$azirshenji1"] = "今天，你们将看见飞升之力！",
	["$azirshenji2"] = "我的帝国存在于每颗沙粒之中。",
	["$azirshenji3"] = "再一次兴起吧！",
	["$azirslash1"] = "把你们自己交给恕瑞玛吧！",
	["$azirslash2"] = "没有恕瑞玛，就没有未来可言。",
	["$azirslash3"] = "命运掌握在我们手中。",
	["$azirslash4"] = "你不需要追随我，但你不能阻拦我！",
	["$azirslash5"] = "你们胆敢反抗我",
	["$azirslash6"] = "荣耀，归于恕瑞玛！",
	["$azirslash7"] = "他们胆敢藐视恕瑞玛？",
	["$azirslash8"] = "见识下恕瑞玛之怒吧！",
	["$azirslash9"] = "埋葬他们！",
	["$azirslash10"] = "命令已下达！",
	["$azirslash11"] = "士兵们，前进！",
	["$azirslash12"] = "我的士兵们前进！",
	["$azirslash13"] = "我意已决！",
	["$azirslash14"] = "你无法推翻恕瑞玛。",
	["$azirslash15"] = "拜见你们的新皇帝吧。",
	["$azirslash16"] = "你们的皇帝，会回来的。",
	["$azirslash17"] = "从沙砾中归来。",
	["$azirslash18"] = "恕瑞玛不会消亡。",
	["$azirslash19"] = "相信我们的将来。",
	["$azirslash20"] = "在这里，我们会决定恕瑞玛的将来。",
	["$azirslash21"] = "（冲锋）",
	["$azirslash22"] = "（突刺）",
	["$azirslash23"] = "（防御）",
	["$azirslash24"] = "（筑塔）",
	["$azirslash25"] = "杀！",
	["$azirslash26"] = "喝！",
	["$azirslash27"] = "哈！",
	["$azirslash28"] = "呵啊！",
	["$azirslash29"] = "呃啊！",


--太阳圆盘
	["kesolardisk"] = "太阳圆盘", 
	["&kesolardisk"] = "太阳圆盘",
	["#kesolardisk"] = "恕瑞玛的遗迹",
	["designer:kesolardisk"] = "小珂酱",
	["cv:kesolardisk"] = "官方",
	["illustrator:kesolardisk"] = "官方",
--神迹
	["kejiguan-ask"] = "你可以使用一张杀",
	["kejiguan"] = "机关",
	["#kejiguanwu"] = "机关",
	["#kesolardiskpeach"] = "圣物",
	["#kejiguaner"] = "机关",
	["#kejiguansan"] = "机关",
	["#kejiguansi"] = "机关",
	["kesolardiskdeath"] = "神迹",
	[":kejiguan"] = "锁定技，\
	◆你废除装备栏；\
	◆你的所有手牌视为【杀】；你使用【杀】无视防具、无距离限制且不能指定阿兹尔为目标；\
	◆你不能成为除【杀】以外的牌的目标。\
	◆结束阶段，你失去1点体力；\
	◆你杀死一名角色后，阿兹尔摸三张牌；\
	◆当你进入濒死状态时，你死亡；",

	["$kejiguan1"] = "（攻击声）",
	["~kesolardisk"] = "（崩塌声）",

--金克斯
	["kejinx"] = "金克丝", 
	["&kejinx"] = "金克丝",
	["#kejinx"] = "黑巷魅影",
	["designer:kejinx"] = "小珂酱",
	["cv:kejinx"] = "官方",
	["illustrator:kejinx"] = "官方",

--快恣
	["kejinx_nopay"] = "快恣",
	["kejinxcrazy"] = "暴走",
	[":kejinxcrazy"] = "锁定技，你使用【杀】无次数限制，你“交响”描述中的“♣”改为黑色。",
	[":kejinx_nopay"] = "<font color='blue'><b><s>锁定技</s></b></font><font color='#FF6EC7'><b><i>(⊙o⊙)这不是我的被动吗？</i></b></font>一名角色被杀死后，若凶手是你，你跳过奖惩结算，摸三张牌且本轮拥有技能“暴走”，否则你摸两张牌。",

--设陷
	["kejinxmark"] = "设陷",
	[":kejinxmark"] = "<font color='green'><b>准备阶段</b></font>，你可以<font color='#FF6EC7'><b><i>标记一个坏蛋！</i></b></font>令一名没有＾▽＾标记的其他角色获得＾▽＾标记。这些角色的回合开始时，有1/2的概率<font color='#FF6EC7'><b><i>“砰！！！啊其实我也不知道炸弹什么时候会爆炸！”</i></b></font>受到1点火焰伤害且你回复1点体力，然后其弃置此标记。\
	◆你的手牌上限+X（X为场上＾▽＾的数量）",
	
	["jinxmark-ask"] = "选择一名坏蛋！",
	["@jinxtuya"] = "＾▽＾",
	["jinxtuya"] = "手牌上限",

--交响
--原始描述
	["jinxchange"] = "交响",
	["#kejinxguner"] = "交响",
	[":jinxchange"] = "转换技，游戏开始时你废除武器栏；你的武器牌视为【杀】<font color='#FF6EC7'><b><i>“哈哈哈我不需要别的伙伴！对吗？鱼骨头。”</i></b></font>；<font color='green'><b>出牌阶段</b></font>，你可以切换武器：\
	①砰砰枪：你使用的黑色【杀】不计入次数，若此【杀】为♣，你摸一张牌；\
	②鱼骨头：你使用【杀】无距离限制且无视防具，你每回合以此武器使用的第一张【杀】指定所有拥有＾▽＾的角色为额外目标。",

--效果一描述
	[":jinxchange1"] = "转换技，游戏开始时你废除武器栏；你的武器牌视为【杀】<font color='#FF6EC7'><b><i>“哈哈哈我不需要别的伙伴！对吗？鱼骨头。”</i></b></font>；<font color='green'><b>出牌阶段</b></font>，你可以切换武器：\
	①砰砰枪：你使用的黑色【杀】不计入次数，若此【杀】为♣，你摸一张牌；\
	<font color='#01A5AF'><s>②鱼骨头：你使用【杀】无距离限制且无视防具，你每回合以此武器使用的第一张【杀】指定所有拥有＾▽＾的角色为额外目标。</s></font>",

--效果二描述
	[":jinxchange2"] = "转换技，游戏开始时你废除武器栏；你的武器牌视为【杀】<font color='#FF6EC7'><b><i>“哈哈哈我不需要别的伙伴！对吗？鱼骨头。”</i></b></font>；<font color='green'><b>出牌阶段</b></font>，你可以切换武器：\
	<font color='#01A5AF'><s>①砰砰枪：你使用的黑色【杀】不计入次数，若此【杀】为♣，你摸一张牌；</s></font>\
	②鱼骨头：你使用【杀】无距离限制且无视防具，你每回合以此武器使用的第一张【杀】指定所有拥有＾▽＾的角色为额外目标。",

	["@jinxgun"] = "砰砰枪",
	["@jinxcannon"] = "鱼骨头",
	["$kejinxtarget"] = "<font color='pink'><b>%from </b></font>触发了“<font color='pink'><b>鱼骨头特性</b></font>”，指定了所有坏蛋为目标！",
	["$kejinxbang"] = "%from 的“<font color='red'><b>炸弹</b></font>”引爆了！这真是太疯狂了！",
	["$jinxchangetocannon"] = "%from 将武器切换为<font color='yellow'><b>鱼骨头</b></font>！",
	["$jinxchangetogun"] = "%from 将武器切换为<font color='yellow'><b>砰砰枪</b></font>！",
	
	["$kejinx_nopay1"] = "干杯！",
	["$kejinx_nopay2"] = "枪不杀人，我是说除非你用它们射击，然后它们会杀掉所有的东西。",
	["$kejinx_nopay3"] = "三把枪的意思是，绝对不说对不起。",
	["$kejinx_nopay4"] = "3，41，9，然后起飞咯！",
	["$kejinx_nopay5"] = "哈哈哈哈哈...",
	["$kejinx_nopay6"] = "我去去就回，没有我就不会有人尖叫到死啦~",
	["$kejinx_nopay7"] = "我现在在哪，哦对，在一场浩劫中。",
	["$kejinx_nopay8"] = "我想都没想过，能有朝一日引爆全场！",
	["$kejinx_nopay9"] = "（砰砰枪）",
	["$kejinx_nopay10"] = "（鱼骨头）",
	["$kejinx_nopay11"] = "砰砰！",
	["$kejinx_nopay12"] = "轰隆！",
	["$kejinx_nopay13"] = "不管怎样，让我们开始开枪吧！",
	["$kejinx_nopay14"] = "加加加加加...",
	["$kejinx_nopay15"] = "他就是个loser，总是要哭的样子，加加加加。",
	["$kejinx_nopay16"] = "快躲开，呵呵，开个玩笑而已，躲闪可没什么用。",
	["$kejinx_nopay17"] = "开平咯！",
	["$kejinx_nopay18"] = "问问我是否有在听你说话吧，剧透一下，我没在听哦~",
	["$kejinx_nopay19"] = "你在，哦不，在笑。",
	["$kejinx_nopay20"] = "人总有一死！",
	["$kejinx_nopay21"] = "我觉得我好像忘了射点什么。",
	["$kejinx_nopay22"] = "我也试着去用心，但是，我做不到啊~",
	["$kejinx_nopay23"] = "笑一下，我们在玩射击游戏呢。",
	["$kejinx_nopay24"] = "哈哈，有谁需要理由？",
	["$kejinx_nopay25"] = "站着别动，我在努力朝你开枪！",
	["$kejinx_nopay26"] = "子弹~",
	["$kejinx_nopay27"] = "来和我不同尺寸的朋友们打个招呼吧！",
	["$kejinx_nopay28"] = "大家都恐慌起来吧！",
	["$kejinx_nopay29"] = "我要带着我的枪去和别人拼刀子，哈哈！",
	["$kejinxmark1"] = "哦，别慌，还能发生什么更糟糕的事情呢？",
	["$kejinxmark2"] = "等等，我在想问题，好了，我想完了。",
	["$kejinxmark3"] = "金克丝的含义，就是金克丝，笨！",
	["$kejinxmark4"] = "没有害怕的必要，也没有活着必要！",
	["$kejinxmark5"] = "你们让我开始觉得无聊了！",
	["$kejinxmark6"] = "哦，所有计划都是我瞎编的！",
	["$kejinxmark7"] = "你是我最喜欢的靶子。",
	["$kejinxmark8"] = "让我们表现得，你被耍了！",
	["$kejinxmark9"] = "我会给你们数到3的时间，3！",
	["$kejinxmark10"] = "有什么遗言吗？哈没有，去死吧！",
	["$kejinxmark11"] = "打住，我想说一些非常酷的话！",
	["$kejinxmark12"] = "说正经的，尖叫可没什么用！",
	["$kejinxmark13"] = "你觉得我很疯狂？你该看看我的姐妹！",
	["$kejinxmark14"] = "我确实需要一把新枪，但不要告诉我的其他枪。",
	["$kejinxmark15"] = "我是个疯子，有医生开的证明。",
	["$kejinxmark16"] = "我意外地做到了。",
	["$kejinxmark17"] = "我有最美好的初衷。",
	["$kejinxmark18"] = "（炸弹爆炸声）",
	["$kejinxmark19"] = "（罪恶快感）",
	["$kejinxmark20"] = "（炮弹）",
	["$kejinxmark21"] = "（炮弹）",

	["~kejinx"] = "他们，干掉我了，呃啊...",




--德莱厄斯
	["kedarius"] = "德莱厄斯", 
	["&kedarius"] = "德莱厄斯",
	["#kedarius"] = "噬君之狼",
	["designer:kedarius"] = "小珂酱",
	["cv:kedarius"] = "官方",
	["illustrator:kedarius"] = "官方",

--失血
	["keblood"] = "迸血",
	["@shixue"] = "失血",
	["@xueyuan"] = "血怒之源",
	[":keblood"] = "<font color='#8E236B'><b>当其他角色对你使用牌时，或你使用牌指定除你外的唯一目标时，</b></font>你可以令其获得1层“失血”（至多5层），每有2层，其手牌上限-1；当一名角色的“失血”达到5层时，你本轮拥有技能“血怒”。",
	["kebloodangry"] = "血怒",
	["kemarkchange"] = "血怒",
	[":kebloodangry"] = "你将“迸血”中对应描述改为“令其获得‘失血’至5层”。\
	◆你获得“血怒”时摸两张牌。",
	["$dariusduantou"] = "狼群就要来了...",
	["newdariuspic"] = "image=image/animate/newdariuspic.png",


	["keduantou"] = "厉决",
	["@duantou"] = "厉决",
	[":keduantou"] = "<font color='#8E236B'><b>出牌阶段限一次</b></font><font color='#8E236B'><b>，</b></font>你可以弃置两张牌对距离为1的一名角色造成1点伤害（若其有5层“失血”，改为2点）然后移除其所有“失血”。\
	◆你发动“厉决”时，目标角色防具无效，若该角色死亡，本回合你拥有技能“血怒”，“厉决”视为未发动过且不再需要弃置牌。",
	["keduantou_extra"] = "厉决",
	[":keduantou_extra"] = "<font color='#8E236B'><b>本回合你已经发动“厉决”击杀了一名角色，“厉决”获得了强化：</b></font>\
	<font color='#8E236B'><b>出牌阶段限一次</b></font><font color='#8E236B'><b>，</b></font>你可以<font color='#01A5AF'><s>弃置两张牌</s></font>对距离为1的一名角色造成1点伤害（若其有5层“失血”，此伤害改为2点）并移除其所有“失血”。\
	◆你发动“厉决”时，目标角色防具无效，若该角色死亡，本回合“厉决”视为未发动过。",


	["killaround"] = "烈斧",
	["killaroundCard"] = "大杀四方",
	[":killaround"] = "<font color='#8E236B'><b>当你受到伤害后，</b></font>你可以弃置所有手牌（至少一张）视为对至多X名角色使用一张无视防具的【杀】（X为你已损失的体力值），且此【杀】每造成一次伤害，你回复1点体力。",
	["kekillaroundrecover"] = "烈斧",
	["dssf-ask"] = "请选择“大杀四方”的角色",
	

	["kebeilian"] = "悲怜",
	[":kebeilian"] = "<font color='#8E236B'><b>出牌阶段限一次</b></font><font color='#8E236B'><b>，</b></font>你可以令任意名角色移除所有“失血”并令其摸一张牌。",

	["$keblood1"] = "旧世界的夜幕正在降临，可你活不到黎明。",
	["$keblood2"] = "狼群的盛宴。",
	["$keblood3"] = "狼群的食物！",
	["$keblood4"] = "没有流血，就无所谓革命。",
	["$keblood5"] = "你躲不掉我的。",
	["$keblood6"] = "你就是猎物！",
	["$keblood7"] = "你能去哪？",
	["$keblood8"] = "你跑不了！",
	["$keblood9"] = "你受伤了。",
	["$keblood10"] = "你只能怪自己没用！",
	["$keblood11"] = "为你的君王流血吧！",
	["$keblood12"] = "我的狼群渴望皇室的鲜血。",
	["$keblood13"] = "我们不能败退，狼群饥渴难平。",
	["$keblood14"] = "血战方得自由。",
	["$keblood15"] = "循环必被打破！",
	["$keblood16"] = "战争，不会饶过任何人！",
	["$keblood17"] = "真正的英雄，以君王的骨血为食。",
	["$keblood18"] = "看你能跑多远。",
	["$keblood19"] = "每个人都有选择，你选择了找死。",
	["$keblood20"] = "狼群已经到你门口了。",
	["$keblood21"] = "你本可以逃掉的！",
	["$keblood22"] = "你太没劲儿了。",
	["$keblood23"] = "你已经作出了选择！",
	["$keblood24"] = "你站错队了。",
	["$keblood25"] = "全身而退？妄想！",
	["$keblood26"] = "我千呼万唤着的战争。",
	["$keblood27"] = "我闻到了血腥！",
	["$keblood28"] = "以血还血！",
	["$keblood29"] = "有点痒痒。",
	["$keblood30"] = "这算什么？",
	["$keblood31"] = "（出血）",
	["$keblood32"] = "（出血）",

	["$killaround1"] = "喝~呀！",
	["$killaround2"] = "嗯~呃！",
	["$killaround3"] = "嗯~呀！",
	["$killaround4"] = "呵呵哈哈哈哈哈。",
	["$killaround5"] = "哈哈哈哈。",
	["$killaround6"] = "呵哈哈哈哈。",
	["$killaround7"] = "哼哈哈哈。",
	["$killaround8"] = "不要背对着狼。",
	["$killaround9"] = "拆光他们藏身的城墙！",
	["$killaround10"] = "待宰的羔羊！",
	["$killaround11"] = "国王之死，经我之手！",
	["$killaround12"] = "看看忠诚把你害成了什么样！",
	["$killaround13"] = "你把脖子伸过来了！",
	["$killaround14"] = "你的脑袋要归我了！",
	["$killaround15"] = "你的头颅会在我手中哭诉着你的失败。",
	["$killaround16"] = "你的众神怎么不管你了？",
	["$killaround17"] = "你想去哪？",
	["$killaround18"] = "跑啊，懦夫！",
	["$killaround19"] = "扔掉你的忠心吧！",
	["$killaround20"] = "全都拆光！",
	["$killaround21"] = "我会将你踏平！",
	["$killaround22"] = "我闻见了你的恐惧！",
	["$killaround23"] = "我许你自由，在你死后！",
	["$killaround24"] = "我能闻到你身上的恐惧，哼哼哼...",
	["$killaround25"] = "要是有必要，我连死亡也要推翻！",
	["$killaround26"] = "我闻到你了！",
	["$killaround27"] = "这是狼群的战斗！",
	["$killaround28"] = "弱肉强食。",
	["$killaround29"] = "喝！",
	["$killaround30"] = "喝啊！",
	["$killaround31"] = "喝啊！",
	["$killaround32"] = "抓住破绽！",
	["$killaround33"] = "咬紧他们！",
	["$killaround34"] = "呵！",
	["$killaround35"] = "咦呀！",
	["$killaround36"] = "（大杀四方）",
	["$killaround37"] = "（致残打击）",

	["$keduantou1"] = "暴君必死！",
	["$keduantou2"] = "帝国的走狗！",
	["$keduantou3"] = "反抗者，死！",
	["$keduantou4"] = "就死在这！",
	["$keduantou5"] = "面对我！",
	["$keduantou6"] = "面对我，暴君！",
	["$keduantou7"] = "你的暴政，死路一条！",
	["$keduantou8"] = "谁敢否定？",
	["$keduantou9"] = "王座我不感兴趣，砍碎它才让我兴奋。",
	["$keduantou10"] = "我不会屈从暴君的命令！",
	["$keduantou11"] = "我对弱者毫不留情！",
	["$keduantou12"] = "我先了结你，再轮到你的主子们。",
	["$keduantou13"] = "先是你，然后是驯养你的人。",
	["$keduantou14"] = "众神的时代已经终结，你也一样。",
	["$keduantou15"] = "还有谁！",
	["$keduantou16"] = "哈，看来死神也无计可施。",
	["$keduantou17"] = "其他人也洗干净脖子吧！",
	["$keduantou18"] = "尸山堆成的王座！",
	["$keduantou19"] = "我就是席卷人间的巨浪！",
	["$keduantou20"] = "我喜欢你死时的样子。",
	["$keduantou21"] = "在此终结！",
	["$keduantou22"] = "呃啊！",
	["$keduantou23"] = "喝啊！",
	["$keduantou24"] = "喝啊，哈哈哈哈...",
	["$keduantou25"] = "喝啊！",
	["$keduantou26"] = "喝啊！",
	["$keduantou27"] = "咦呀！",
	["$keduantou28"] = "（血怒大招）",
	["$keduantou29"] = "（大招）",


	["$kebloodangry1"] = "暴力会重铸一切生命。",
	["$kebloodangry2"] = "德玛西亚将会血流成河。",
	["$kebloodangry3"] = "浩劫降临！",
	["$kebloodangry4"] = "混乱中无人幸免。",
	["$kebloodangry5"] = "见证帝国的末日吧！",
	["$kebloodangry6"] = "旧秩序必被清洗！",
	["$kebloodangry7"] = "冕卫的堂皇借口，一举粉碎吧！",
	["$kebloodangry8"] = "你现在后悔反抗我了吗？",
	["$kebloodangry9"] = "世界会拥抱混乱！",
	["$kebloodangry10"] = "我的力量必将彰显！",
	["$kebloodangry11"] = "现在，什么也救不了你了！",
	["$kebloodangry12"] = "战争，刚刚开始。",
	["$kebloodangry13"] = "这就是你的死地！",
	["$kebloodangry14"] = "挣扎，流血，绝不示弱！",
	["$kebloodangry15"] = "众神和诸王已经让我忍无可忍了。",
	["$kebloodangry16"] = "抓住心中的野兽，然后变成它！",
	["$kebloodangry17"] = "（血怒）",

	["$kebeilian1"] = "暴君想要寻死，我们就让他了了这个心愿。",
	["$kebeilian2"] = "还有更多暴君要杀，更多王座要毁。",
	["$kebeilian3"] = "去战斗吧，去杀戮吧！",
	["$kebeilian4"] = "他们现在知道我们要来了。",
	["$kebeilian5"] = "我不是救星，我是杀神。",
	["$kebeilian6"] = "我觉得你身体里的恶魔得出来透透气。",
	["$kebeilian7"] = "我们必须逃出由和平构筑的监狱。",
	["$kebeilian8"] = "我们都是群狼。",

	["~kedarius"] = "呃啊...",

--凯特琳
	["kecaitlyn"] = "凯特琳", 
	["&kecaitlyn"] = "凯特琳",
	["#kecaitlyn"] = "小蛋糕",
	["designer:kecaitlyn"] = "小珂酱",
	["cv:kecaitlyn"] = "官方",
	["illustrator:kecaitlyn"] = "官方",

--彻探
	["kechetan"] = "彻探",
	["$kejingwen"] = "%from 的<font color='yellow'><b>“精稳”</b></font>效果被触发，此【杀】不能被 %to 响应。",
	[":kechetan"] = "<font color='#333399'><b>当你距离1以内的角色受到伤害后，</b></font>你可以观看伤害来源的手牌并选择其中一张，若你选择了：\
	<font color='#333399'>○伤害类牌</font>，你对其使用之，且该角色与其他角色的距离为无限直到其回合结束；\
	<font color='#333399'>○非伤害类牌</font>，其弃置此牌，受到伤害的角色摸一张牌。\
	◆<font color='#333399'><b>摸牌阶段，</b></font>你多摸X张牌（X为前一轮你发动“彻探”的角色数）。",
	["kejingwen"] = "精稳",
	["kebaotou"] = "爆头",
	[":kejingwen"] = "<font color='#333399'><b>锁定技</b></font><font color='#333399'><b>，</b></font>你使用【杀】的距离限制+1。\
	◆当你使用【杀】指定目标后，</b></font>若目标角色没有与此【杀】花色相同的手牌，其不能响应此牌。\
	◆每当你使用的第三张【杀】结算完毕后，</b></font>你使用的下一张【杀】的伤害基数+1。",

	["catpicone"] = "image=image/animate/catpicone.png",
	["catpictwo"] = "image=image/animate/catpictwo.png",
	["catpicthree"] = "image=image/animate/catpicthree.png",

	["$kechetan1"] = "案情就要取得突破了，我只需要把线索给串起来...",
	["$kechetan2"] = "案情越神秘，我就越喜欢。",
	["$kechetan3"] = "保持镇定从容，是好侦探的必备素养。",
	["$kechetan4"] = "保护皮尔特沃夫公民是我的职责，而我会将它负责到底。",
	["$kechetan5"] = "不能保护公众的法律，一文不值。",
	["$kechetan6"] = "查遍所有蛛丝马迹。",
	["$kechetan7"] = "镀金的外表下，往往掩盖着斑驳的锈渍，但我不会忽略任何细节。",
	["$kechetan8"] = "法网恢恢疏而不漏，更别说我的90口径绳网了。",
	["$kechetan9"] = "犯罪很常见，逻辑却很罕见。",
	["$kechetan10"] = "根本闲不下来。",
	["$kechetan11"] = "公事公办。",
	["$kechetan12"] = "火速出击！",
	["$kechetan13"] = "开始调查之前，首先要做的是检查证据。",
	["$kechetan14"] = "没有你，或许皮城人民可以睡个好觉了，可是蔚嘛...",
	["$kechetan15"] = "没有人能凌驾于法律之上。",
	["$kechetan16"] = "每一轮调查，每一次破案，都让我离正义又前进了一步。",
	["$kechetan17"] = "你所说的一切都将成为呈堂证供。",
	["$kechetan18"] = "你承认自己有罪，还真是慷慨。",
	["$kechetan19"] = "你以为自己凌驾于法律之上，再想想？",
	["$kechetan20"] = "你有权保持沉默，我建议你使用这个权利。",
	["$kechetan21"] = "皮尔特沃夫的良心，是它的人民。",
	["$kechetan22"] = "强权和恐惧代表不了皮尔特沃夫，只有进步才是它的未来。",
	["$kechetan23"] = "谁在呼叫警长？",
	["$kechetan24"] = "似乎我有新的嫌疑人要追查了。",
	["$kechetan25"] = "铁窗生涯就是你最后的结局。",
	["$kechetan26"] = "我必须永远快人三步。",
	["$kechetan27"] = "我才不是皮尔特沃夫当局的走狗，我是为它的人民效力。",
	["$kechetan28"] = "我的目标是赢，而我总是能精确命中目标。",
	["$kechetan29"] = "我超爱追杀的。",
	["$kechetan30"] = "我会把你和你的口供都带回局里。",
	["$kechetan31"] = "我会给TA的罪名再加上一条。",
	["$kechetan32"] = "我绝不会容忍不法行为。",
	["$kechetan33"] = "我可容不得半点失误。",
	["$kechetan34"] = "我来这不是为了服务，而是为了守护。",
	["$kechetan35"] = "我们来彻查此案。",
	["$kechetan36"] = "我们去查案吧。",
	["$kechetan37"] = "我已经掌握了关于你的全套证据。",
	["$kechetan38"] = "我又回来查案了。",
	["$kechetan39"] = "这比坐在办公室里强多了。",
	["$kechetan40"] = "这个案子必须彻查到底。",
	["$kechetan41"] = "争取在下午茶之前把案子给结了。",
	["$kechetan42"] = "知道别人所不知道的事，就是我的工作。",
	["$kechetan43"] = "终身监禁就是对TA最好的回礼，不是吗？",
	["$kechetan44"] = "执勤中。",
	["$kechetan45"] = "专业侦探，必须时刻留意周围的环境。",
	["$kechetan46"] = "最不起眼的线索，也可能是破案的关键。",
	["$kechetan47"] = "不出所料。",
	["$kechetan48"] = "公事公办。",
	["$kechetan49"] = "好戏开始了。",
	["$kechetan50"] = "猫捉老鼠的游戏，该结束了。",
	["$kechetan51"] = "如果罪犯从不睡觉，那我最好再泡上一壶茶。",
	["$kechetan52"] = "我不在的时候老实一点，好吗？",
	["$kechetan53"] = "我的目标，是赢。",
	["$kechetan54"] = "我们来了结这一切吧。",
	["$kechetan55"] = "在我回来之前，不要扰乱犯罪现场哦。",
	["$kechetan56"] = "哦，这下有意思了。",

	["$kechetan57"] = "（击杀）案件已破。",
	["$kechetan58"] = "（击杀）犯人罪名成立！",
	["$kechetan59"] = "（击杀）该办下一个案子了。",
	["$kechetan60"] = "（击杀）干掉一个。",
	["$kechetan61"] = "（击杀）还不准备好投降？",
	["$kechetan62"] = "（击杀）好吧，接下来有的是文件要处理了。",
	["$kechetan63"] = "（击杀）结案了~",
	["$kechetan64"] = "（击杀）手法完美，结果自然精确。",
	["$kechetan65"] = "（击杀）顺利逮捕。",
	["$kechetan66"] = "（击杀）所以，我别无选择。",
	["$kechetan67"] = "（击杀）我本来只想把你关起来的。",
	["$kechetan68"] = "（击杀）真是浪费。",
	["$kechetan69"] = "（击杀）下午茶，结束了。",
	["$kechetan70"] = "（选人）随时准备破案。",

	["$kejingwen1"] = "别想逃跑！",
	["$kejingwen2"] = "逮到你了！",
	["$kejingwen3"] = "弹无虚发。",
	["$kejingwen4"] = "当场抓获。",
	["$kejingwen5"] = "盯住目标了。",
	["$kejingwen6"] = "你躲不过法律的制裁。",
	["$kejingwen7"] = "你想去哪儿呢？",
	["$kejingwen8"] = "我，miss？别指望了。",
	["$kejingwen9"] = "要比比枪法吗？",
	["$kejingwen10"] = "beng！",
	["$kejingwen11"] = "beng！爆头",
	["$kejingwen12"] = "好枪法！",
	["$kejingwen13"] = "精彩！",
	["$kejingwen14"] = "如教科书一般！",
	["$kejingwen15"] = "无可挑剔！",
	["$kejingwen16"] = "指哪打哪！",
	["$kejingwen17"] = "别动！",
	["$kejingwen18"] = "别妨碍执法！",
	["$kejingwen19"] = "放下你的武器！",
	["$kejingwen20"] = "不许动！",
	["$kejingwen21"] = "举手投降吧！",
	["$kejingwen22"] = "举手投降吧！",
	["$kejingwen23"] = "绝不迟疑！",
	["$kejingwen24"] = "目标进入视野。",
	["$kejingwen25"] = "目标已标记。",
	["$kejingwen26"] = "速战速决。",
	["$kejingwen27"] = "已就位",
	["$kejingwen28"] = "他们被我瞄准了。",
	["$kejingwen29"] = "正在与嫌犯交火。",
	["$kejingwen30"] = "呃！",
	["$kejingwen31"] = "呃！",
	["$kejingwen32"] = "嗯！",
	["$kejingwen33"] = "嗯！",
	["$kejingwen34"] = "嗯！",
	["$kejingwen35"] = "嗯啊！",
	["$kejingwen36"] = "嗯！",
	["$kejingwen37"] = "嗯！",
	["$kejingwen38"] = "嗯！",
	["$kejingwen39"] = "呃啊！",
	["$kejingwen40"] = "哈！",
	["$kejingwen41"] = "呵——啊！",
	["$kejingwen42"] = "呵——嗯！",
	["$kejingwen43"] = "嘿——嗯！",
	["$kejingwen44"] = "（开枪）",
	["$kejingwen45"] = "（开枪）",
	["$kejingwen46"] = "（开枪）",
	["$kejingwen47"] = "（爆头开枪）",
	["$kejingwen48"] = "（爆头开枪）",
	["$kejingwen49"] = "（爆头开枪）",
	["$kejingwen50"] = "（获得爆头）",
	["$kejingwen51"] = "（爆头命中）",

	--["$kejingwen"] = "",
	["~kecaitlyn"] = "告诉蔚，其实我...",



--希尔科
	["kesilco"] = "希尔科", 
	["&kesilco"] = "希尔科",
	["#kesilco"] = "铁腕的领袖",
	["designer:kesilco"] = "小珂酱",
	["cv:kesilco"] = "官方",
	["illustrator:kesilco"] = "官方",

--除叛
	["kechupan"] = "除叛",
	[":kechupan"] = "<font color='#CC00FF'><b>每个回合限一次</b></font><font color='#CC00FF'><b>，</b></font>当一名其他角色使用【杀】或普通锦囊牌指定你为唯一目标时，你可以选择一名角色与其拼点，若该角色：\
	<font color='#CC00FF'>○赢</font>：取消此牌的目标且你与其各摸一张牌，若这名角色不是你，其可以对使用者造成1点伤害。\
	<font color='#CC00FF'>○没赢</font>：你不能响应此牌。",
	["kesilang-ask"] = "你可以选择发动“饲狼”的角色",
	["silcochuni-ask"] = "你可以选择发动“饲狼”的角色",
	["kesilang"] = "饲狼",
	["silco_choice"] = "除叛",
	["chupantwo_choice"] = "除叛",
	["chupantwo_choice:damage"] = "对其造成1点伤害",
	["chupantwo_choice:cancel"] = "取消",
	[":kesilang"] = "<font color='#CC00FF'><b>出牌阶段开始时，</b></font>你摸等同于你已损失体力值的牌，然后你可以交给一名其他角色至少一张牌，若如此做，其下一次对除你外的角色造成的伤害+1。",
	["$kechupanyes"] = "%from 除叛成功！目标和使用者交换！",
	["$kechupanyeser"] = "%from 除叛成功！",
	["$kechupanno"] = "%from 除叛失败！",
	["$kewolfdalog"] = "%from 由于<font color='yellow'><b>“饲狼”</b></font>效果，此伤害增加！",
	["#silanggive"] = "请选择给出的牌",
	["kesilangCard"] = "饲狼",
	["silangxuanpai"] = "请选择给出的牌",
	

	["$kechupan1"] = "欢迎，我的人齐了。",
	["$kechupan2"] = "你的胆量我倒是有些意外。",
	["$kechupan3"] = "替我向守卫们问好。",
	["$kechupan4"] = "来找我麻烦吗？",
	["$kechupan5"] = "我的力量，来自你们的忠诚。",
	["$kechupan6"] = "早晚让他们后悔。",
	["$kechupan7"] = "真相，是活下来的人说了算的。",
	["$kechupan8"] = "背叛，不出所料。",
	["$kechupan9"] = "一条走狗，仗势欺人。",
	["$kechupan10"] = "我很失望。",
	["$kechupan11"] = "这个世界变得一天比一天小。",

	["$kesilang1"] = "就让他们化为灰烬！",
	["$kesilang2"] = "让人畏惧，是你本该做到的。",
	["$kesilang3"] = "人人心里都有一只怪物。",
	["$kesilang4"] = "我们也能当一回英雄。",
	["$kesilang5"] = "也该是我干脏活的时候了。",
	["$kesilang6"] = "把怪物放出来吧！",
	["$kesilang7"] = "粉身碎骨，或是百炼成钢。",
	["$kesilang8"] = "很美，对不对。",
	["$kesilang9"] = "活下去，战斗。",
	["$kesilang10"] = "还有什么事，能比女儿更让人头疼呢？",
	["$kesilang11"] = "金克丝，你是完美的。",
	["$kesilang12"] = "你变强了，金克丝。",
	["$kesilang13"] = "你好啊，小姑娘。",
	["$kesilang14"] = "你去哪儿了，金克丝！",
	["$kesilang15"] = "（击杀）他们还没看明白吗？",
	["$kesilang16"] = "（击杀）他们永远都理解不了。",
	["$kesilang17"] = "（饲狼攻击）",

	["~kesilco"] = "我们不该是，这样的结局...",

--范德尔
	["kevander"] = "范德尔", 
	["&kevander"] = "范德尔",
	["#kevander"] = "锈钝的刀锋",
	["designer:kevander"] = "小珂酱",
	["cv:kevander"] = "官方",
	["illustrator:kevander"] = "官方",

	["ketinghu"] = "挺护",
	[":ketinghu"] = "<font color='#CC9966'><b>结束阶段开始时，</b></font>你可以选择至多X名角色（X为你的体力上限且至多为4），直到你下回合开始，每当这些角色下一次受到伤害时，你防止此伤害并获得1点“挺护”。<font color='#CC9966'><b>准备阶段开始时，</b></font>你选择一项：流失Y点体力并摸2Y张牌（Y为“挺护”的数量），或失去一点体力上限。然后你移去所有“挺护”。",
	["beketinghu"] = "挺护保护",
	["usetinghu"] = "挺护",
	["vander_choice:loseanddraw"] = "流失体力并摸牌",
	["vander_choice:losemaxhp"] = "失去1点体力上限",
	["vander_choice"] = "挺护选择",
	["vander-ask"] = "请选择发动“挺护”保护的角色",

	["$ketinghu1"] = "我想保护的是在座的所有人，你们每一个我都在意。",
	["$ketinghu2"] = "但只有我们相互照应才能生存，这没变过。",
	["$ketinghu3"] = "绝对不许踏进上城那地方半步！",
	["$ketinghu4"] = "有关皮尔特沃夫的事情咱不能碰！",
	["$ketinghu5"] = "你动脑子想过你会出什么事吗？",
	["$ketinghu6"] = "我曾经也是，我也愤怒过，就像你一样。",
	["$ketinghu7"] = "有没有人受伤？",
	["$ketinghu8"] = "原来你还是不明白。",
	["$ketinghu9"] = "这事很快就会过去了只是我们要一起扛过去。",
	["$ketinghu15"] = "犯下这事的人，一定会受到惩罚。",
	["$ketinghu16"] = "非逼我再戴上它们可就不好办了。",
	["$ketinghu12"] = "你想让他们付出代价，可你能承受失去谁呢？",
	["$ketinghu13"] = "如果我没有，你们的父母现在还活得好好的。",
	["$ketinghu14"] = "我带着人冲过了这座桥，以为世界能就此改变。",
	["$ketinghu10"] = "看来，你也得练练防守。",
	["$ketinghu11"] = "我也想跟你说都会好的，孩子，但那都是假话。",

	["~kevander"] = "战争中，没有赢家。",

--盖伦
	["kegaren"] = "盖伦", 
	["&kegaren"] = "盖伦",
	["#kegaren"] = "独裁者",
	["designer:kegaren"] = "小珂酱",
	["cv:kegaren"] = "官方",
	["illustrator:kegaren"] = "官方",

	["kehaojin"] = "豪进",
	[":kehaojin"] = "<font color='#6699FF'><b>出牌阶段限一次</b></font><font color='#6699FF'><b>，</b></font>你可以弃置一张牌令你本回合使用【杀】的次数限制+1，若如此做，你使用的下一张【杀】的距离限制+1且你令目标角色的非锁定技失效直到其回合结束，若此【杀】造成了伤害，其不能使用非基本牌直到其回合结束。",
	["haojinsilence"] = "豪进沉默",


	["kezhengyi"] = "正义",
	[":kezhengyi"] = "<font color='#6699FF'><b>限定技</b></font><font color='#6699FF'><b>，</b></font>当你对距离1以内的一名其他角色造成伤害后，若其体力值不大于其体力上限的一半，你可以对其造成等同于其已损失体力值的雷电伤害。",

	["keshiwei"] = "狮威",
	[":keshiwei"] = "<font color='#6699FF'><b>结束阶段开始时，</b></font>若你于本回合出牌阶段没有造成过伤害且你体力值不大于2，你回复1点体力；否则你摸一张牌且你视为装备“白银狮子”直到你下回合结束。",

--配音
	["$kezhengyi1"] = "我是神！",
	["$kezhengyi2"] = "公正的裁决。",
	["$kezhengyi3"] = "跪下！",
	["$kezhengyi4"] = "见识我的正义！",
	["$kezhengyi5"] = "就地正法！",
	["$kezhengyi6"] = "你被驱逐了！",
	["$kezhengyi7"] = "你的末日来临了。",
	["$kezhengyi8"] = "你的判决！",
	["$kezhengyi9"] = "你已定罪。",
	["$kezhengyi10"] = "你已被判死刑。",
	["$kezhengyi11"] = "我们，即是正义！",
	["$kezhengyi12"] = "我就是正义！",
	["$keshiwei1"] = "不要害怕，我永远都不会真正离你远去。",
	["$keshiwei2"] = "不要怀疑你的王，救赎近在咫尺。",
	["$keshiwei3"] = "不要惧怕敌人，我们为了公正的大义而战。",
	["$keshiwei4"] = "不要失去希望，我们的审判如同快刀斩乱麻。",
	["$keshiwei5"] = "忏悔，无法拯救他们。",
	["$keshiwei6"] = "大义，让我焕然一新。",
	["$keshiwei7"] = "没什么能够德玛西亚和生命。",
	["$keshiwei8"] = "你们的神不会抛弃你们。",
	["$keshiwei9"] = "你们的神王，屹立不败。",
	["$keshiwei10"] = "区区野兽，怎可能挡得住神王。",
	["$keshiwei11"] = "神的意志！",
	["$keshiwei12"] = "任何野兽和黑影都无法阻止我。",
	["$keshiwei13"] = "神圣之力！",
	["$keshiwei14"] = "神王不受任何诱惑，绝不动摇，哪怕是现在。",
	["$keshiwei15"] = "神王不死！",
	["$keshiwei16"] = "我，代表德玛西亚！",
	["$keshiwei17"] = "你们的国王威风抖擞！",
	["$keshiwei18"] = "勇气，笃定，信念。",
	["$keshiwei19"] = "这个世界上，只有一个永恒的常量，德玛西亚。",
	["$keshiwei20"] = "这也是属于我的领域。",
	["$keshiwei21"] = "正义的君王，带领正义的人民。",
	["$keshiwei22"] = "（挥砍）",
	["$keshiwei23"] = "（挥砍）",
	["$keshiwei24"] = "（致命打击）",
	["$keshiwei25"] = "（勇气）",
	["$keshiwei26"] = "（豪进）",
	["$keshiwei27"] = "（德玛西亚正义）",
	["$keshiwei28"] = "啊！",
	["$keshiwei29"] = "呜啊！",
	["$keshiwei30"] = "呜啊！",
	["$keshiwei31"] = "咦啊！",
	["$keshiwei32"] = "啊！",
	["$keshiwei33"] = "咦啊！",
	["$keshiwei34"] = "嘎啊！",
	["$keshiwei35"] = "哈！",
	["$keshiwei36"] = "哈！",
	--["$keshiwei"] = "",

	["$kehaojin1"] = "安静！无赖！",
	["$kehaojin2"] = "肮脏的阴影，我要驱逐一切黑暗！",
	["$kehaojin3"] = "摒弃怀疑，终结一切反对我们的人！",
	["$kehaojin4"] = "不惜代价，维护正义。",
	["$kehaojin5"] = "忏悔！",
	["$kehaojin6"] = "德玛西亚，我听到你的声音！",
	["$kehaojin7"] = "敌人脆弱不堪，以我的名义碾碎他们。",
	["$kehaojin8"] = "敌人的阵线已然溃散，我们将取得胜利。",
	["$kehaojin9"] = "见证神力！",
	["$kehaojin10"] = "见证神威！",
	["$kehaojin11"] = "见证我的信仰之力吧！",
	["$kehaojin12"] = "来吧，卑鄙小人，我们会让你永远长眠。",
	["$kehaojin13"] = "没人能挑战神王。",
	["$kehaojin14"] = "没什么能阻挡我。",
	["$kehaojin15"] = "没什么能阻止我的王国的前进步伐。",
	["$kehaojin16"] = "你，敢反抗我？",
	["$kehaojin17"] = "你已被抛弃！",
	["$kehaojin18"] = "碾碎他们！",
	["$kehaojin19"] = "所有威胁德玛西亚的人，都将被灭绝。",
	["$kehaojin20"] = "为了德玛西亚！",
	["$kehaojin21"] = "为了德玛西亚！",
	["$kehaojin22"] = "我必须攘除奸邪。",
	["$kehaojin23"] = "不信神者！",
	["$kehaojin24"] = "丑恶的怪物！",
	["$kehaojin25"] = "德玛西亚长存！",
	["$kehaojin26"] = "渎神者！",
	["$kehaojin27"] = "感受我的怒火吧！",
	["$kehaojin28"] = "你不配！",
	["$kehaojin29"] = "你敢？！",
	["$kehaojin30"] = "谨记我的名字！",
	["$kehaojin31"] = "正义来临！",
	["$kehaojin32"] = "打入黑暗！",
	["$kehaojin33"] = "大地，也要屈服于我的意志。",
	["$kehaojin34"] = "大义凛然！",
	["$kehaojin35"] = "带给全人类的正义。",
	["$kehaojin36"] = "以儆效尤！",
	["$kehaojin37"] = "德玛西亚崛起！",
	["$kehaojin38"] = "很快就将有一天，你这样的生物将从全世界根除。",
	["$kehaojin39"] = "混乱已经打到了家门口，碾碎他的战士，屠杀他的先知。",
	["$kehaojin40"] = "假冒的神使，只有我才掌握着神的力量。",
	["$kehaojin41"] = "奸邪将被清除。",
	["$kehaojin42"] = "净化。",
	["$kehaojin43"] = "净化他们的黑暗，这是神王的命令。",
	["$kehaojin44"] = "恐惧德玛西亚的怒火吧！",
	["$kehaojin45"] = "来受死吧！",
	["$kehaojin46"] = "你的邪恶阴影，将不再笼罩世界。",
	["$kehaojin47"] = "你敢对神说话，你不配。",
	["$kehaojin48"] = "你敢忤逆我？！",
	["$kehaojin49"] = "你将见识我的怒火。",
	["$kehaojin50"] = "你认为你能躲开我的视线吗？",
	["$kehaojin51"] = "叛徒！",
	["$kehaojin52"] = "神，不可能落败！",
	["$kehaojin53"] = "神圣的旨意作证，他们将接收正义的裁决。",
	["$kehaojin54"] = "死吧，恶人！",
	["$kehaojin55"] = "为了伟大的正义。",
	["$kehaojin56"] = "我将所向无敌。",
	["$kehaojin57"] = "我绝不留情！",
	["$kehaojin58"] = "我将战斗至永恒。",
	["$kehaojin59"] = "雄狮的盛宴。",
	["$kehaojin60"] = "雄狮怒吼！",
	["$kehaojin61"] = "一个不留！",
	["$kehaojin62"] = "秩序已被重建。",
	["$kehaojin63"] = "异端已得到报应。",
	["$kehaojin64"] = "又一个恶人在我面前伏法。",
	["$kehaojin65"] = "又一只旧世界的怪物以我的名义被斩杀。",
	["$kehaojin66"] = "在神王的面前，还不跪下！",
	["$kehaojin67"] = "这世界将迎来秩序。",

	["~kegaren"] = "我的王座..犹在...",




--蔚奥莱
	["keviolet"] = "蔚奥莱", 
	["&keviolet"] = "蔚奥莱",
	["#keviolet"] = "拳决恩仇",
	["designer:keviolet"] = "小珂酱",
	["cv:keviolet"] = "官方",
	["illustrator:keviolet"] = "官方",

	["keyuji"] = "透劲",
	["$violetanimate"] = "anim=arcane/animatevi",
	["$violetanimatetwo"] = "anim=arcane/animatevitwo",

	["kevioletspace"] = "透劲反击",
	[":keyuji"] = "<font color='#FF00A0'><b>出牌阶段每名角色限一次，</b></font>你可以对攻击范围内的一名角色造成1点伤害，然后该角色选择视为对你使用一张【杀】或【决斗】，当你因此受到伤害后，你摸两张牌，若你体力值不大于其，你获得1点护甲，然后你结束本回合。\
	◆若你选择的角色体力值不大于1，其失去1点体力上限（至少为1）。",
	["hitvi"] = "我惹你了？",
	["hitvi:slash"] = "视为对其使用一张【杀】",
	["hitvi:juedou"] = "视为对其使用一张【决斗】",
	["kegonghuan"] = "共患",
	[":kegonghuan"] = "<font color='#FF00A0'><b>每轮限一次</b></font><font color='#FF00A0'><b>，</b></font>当一名其他角色进入濒死状态时，你可以将所有手牌交给该角色，若你给出的牌不少于三张，其回复1点体力，然后你摸等同于你已损失体力值的牌。",

	["viskip-ask"] = "你可以跳过本回合",
	
	["$keyuji1"] = "尝尝这个！",
	["$keyuji2"] = "啐，我有五个让你们闭嘴的理由。",
	["$keyuji3"] = "beng！爆头！",
	["$keyuji4"] = "强力一击！",
	["$keyuji5"] = "欢迎参加派对，试试我的铁拳吧！",
	["$keyuji6"] = "计划，我可不需要计划。",
	["$keyuji7"] = "如果碰壁了，就用力把它碰穿！",
	["$keyuji8"] = "谁需要来一记重拳？",
	["$keyuji9"] = "啐，我会用拳头把你们的意见问出来的。",
	["$keyuji10"] = "他们到死的时候都不会知道是谁打的。",
	["$keyuji11"] = "我们，开始行动吧。",
	["$keyuji12"] = "我们开始有趣的部分吧！",
	["$keyuji13"] = "我让双手替我发言。",
	["$keyuji14"] = "我喜欢你的笑容，真是个完美的靶子。",
	["$keyuji15"] = "我在以我的方式处理呢。",
	["$keyuji16"] = "我自己就是后援。",
	["$keyuji17"] = "啐，我只是喜欢痛扁你们而已。",
	["$keyuji18"] = "有趣的东西来了。",
	["$keyuji19"] = "有时，你需要亲手弄出一扇门。",
	["$keyuji20"] = "在他们身上砸个凹痕。",
	["$keyuji21"] = "啊！",
	["$keyuji22"] = "啊~",
	["$keyuji23"] = "啊！",
	["$keyuji24"] = "啊！",
	["$keyuji25"] = "啊！",
	["$keyuji26"] = "哈！",
	["$keyuji27"] = "哈！",
	["$keyuji28"] = "嗯！",
	["$keyuji29"] = "啊！",
	["$keyuji30"] = "呵！",
	["$keyuji31"] = "呵！",
	["$keyuji32"] = "呵啊！",
	["$keyuji33"] = "呃~啊！",
	["$keyuji34"] = "呃~啊！",
	["$keyuji35"] = "（出拳）",
	["$keyuji36"] = "（重击）",
	["$keyuji37"] = "（重击）",
	
	["$kegonghuan1"] = "正是你的与众不同让你强大。",
	["$kegonghuan2"] = "爆爆，牢牢记住这一点，好吗？",


	["~keviolet"] = "呃...呃...",

--杰斯
	["kejayce"] = "杰斯", 
	["&kejayce"] = "杰斯",
	["#kejayce"] = "进步的缔造者",
	["designer:kejayce"] = "小珂酱",
	["cv:kejayce"] = "官方",
	["illustrator:kejayce"] = "官方",

	["kejaycetwo"] = "杰斯", 
	["&kejaycetwo"] = "杰斯",
	["#kejaycetwo"] = "进步的缔造者",
	["designer:kejaycetwo"] = "小珂酱",
	["cv:kejaycetwo"] = "官方",
	["illustrator:kejaycetwo"] = "官方",



	["kejintuoex"] = "进拓",
	[":kejintuo"] = "<font color='#3366FF'><b>回合开始时，</b></font>你可以令一名角色获得“飞门”。拥有“飞门”的角色<font color='#3366FF'><b>准备阶段开始时，</b></font>随机执行两项：\
	○摸一张牌；\
	○本回合手牌上限+1；\
	○弃置判定区的所有牌；\
	○本回合与其他角色距离-1；\
	○回复1点体力。",

	[":kejintuo1"] = "<font color='#3366FF'><b>回合开始时，</b></font>你可以令一名角色获得“飞门”。拥有“飞门”的角色<font color='#3366FF'><b>准备阶段开始时，</b></font>随机执行<font color='red'><b>三项</b></font>：\
	○摸一张牌；\
	○本回合手牌上限+1；\
	○弃置判定区的所有牌；\
	○本回合与其他角色距离-1；\
	○回复1点体力。",

	["keflydoorbuff"] = "海克斯飞门",
	["kejintuo"] = "进拓",

	["kechuzhism"] = "笃志",
	[":kechuzhism"] = "<font color='#3366FF'><b>使命技</b></font><font color='#3366FF'><b>，</b></font><font color='#3366FF'><b>每轮开始时，</b></font>你获得一枚“能石”。\
	[<font color='#3366FF'><b>进步之城</b></font>]<b>成功</b>：准备阶段开始时，若你有至少三枚“能石”，你失去1点体力上限，你回复1点体力并获得技能“繁贸”，然后修改“进拓”（改为随机执行三项）。\
	[<font color='#3366FF'><b>海克斯武器</b></font>]<b>失败</b>：回合开始时，若你使命成功前受到或造成过共计3次伤害，你回复1点体力，移去所有其他角色的“飞门”，且你不能再发动“进拓”选择其他角色，然后获得技能“迸能”。",

	["$hexsuccess"] = "anim=arcane/createhex",
	["$hexfail"] = "anim=arcane/notcreatehex",

	["jayceshimingone"] = "image=image/animate/createhex.png",
	["jayceshimingtwo"] = "image=image/animate/createhextwo.png",


	["kebengneng"] = "迸能",
	[":kebengneng"] = "<font color='#3366FF'><b>当你/一名其他角色对你/一名其他角色造成伤害时，</b></font>你摸一张牌，若伤害来源为你，你可以弃置其一张手牌并移去一枚“能石”，若如此做，你废除其一个装备栏。\
	◆你使用的黑色【杀】不能被响应，红色【杀】无距离限制且伤害基数+1。",
	["chuzhi_damage"] = "笃志伤害",

	["$jayceanimatehammer"] = "anim=arcane/animatejaycehammer",
	["$jayceanimatehammertwo"] = "anim=arcane/animatejaycehammertwo",
	["$jayceanimatecannon"] = "anim=arcane/animatejaycecannon",
	["$jayceanimatecannontwo"] = "anim=arcane/animatejaycecannontwo",

	["kebengneng-ask"] = "请选择废除的装备栏",
	["jaycestone-ask"] = "移去一枚‘能石’摸两张牌",
	["yanmou-ask"] = "你可以在一名角色处设置海克斯飞门",
	["flydoorswapback-ask"] = "将座次交换回来",
	["keflydoor"] = "飞门",

--戒严
	["kejieyan"] = "戒严",
	[":kejieyan"] = "<font color='#3366FF'><b>出牌阶段限一次</b></font><font color='#3366FF'><b>，</b></font>你可以令任意名其他角色移去“飞门”。",
	
	["$keflydoorbuffmp"] = "%from <font color='#CCFFFF'><b>的飞门效果触发，摸一张牌。</b></font>",
	["$keflydoorbuffkeep"] = "%from <font color='#CCFFFF'><b>的飞门效果触发，本回合手牌上限+1。</b></font>",
	["$keflydoorbuffjl"] = "%from <font color='#CCFFFF'><b>的飞门效果触发，本回合与其他角色距离-1。</b></font>",
	["$keflydoorbuffpd"] = "%from <font color='#CCFFFF'><b>的飞门效果触发，弃置判定区的所有牌。</b></font>",
	["$keflydoorbuffhx"] = "%from <font color='#CCFFFF'><b>的飞门效果触发，回复1点体力。</b></font>",
	["$kejaycewakefail"] = "%from 的 <font color='yellow'><b>使命</b></font> 失败！",
	["$kejaycewakesuc"] = "%from 的 <font color='yellow'><b>使命</b></font> 成功！",
	
	["$kebengnengxiangying"] = "%from 的 <font color='yellow'><b>迸能</b></font> 效果触发，此【杀】不能被响应。",

	["kebengneng-ask:0"] = "废除武器栏",
	["kebengneng-ask:1"] = "废除防具栏",
	["kebengneng-ask:2"] = "废除防御马栏",
	["kebengneng-ask:3"] = "废除进攻马栏",
	["kebengneng-ask:4"] = "废除宝物栏",
	

--繁贸

	["kefanmao"] = "繁贸",
	[":kefanmao"] = "<font color='#3366FF'><b>出牌阶段限一次</b></font><font color='#3366FF'><b>，</b></font>你可以移去两枚“能石”与一名拥有“飞门”的角色交换座次并与其各摸两张牌。结束阶段，你可以再次与其交换座次。",
	["fanmaomopai:drawcards"] = "令该角色也摸两张牌",
	["fanmaomopai:cancel"] = "取消",
	["fanmaomopai"] = "繁贸选择",

	["$kejintuo1"] = "请叫我塔利斯议员。",
	["$kejintuo2"] = "我们正在为海克斯科技寻找新的合伙人。",
	["$kejintuo3"] = "我会尽全力不辜负皮尔特沃夫的期望。",
	["$kejintuo4"] = "该轮到我们决定海克斯科技的未来了。",
	["$kejintuo5"] = "可是我们身为科学先驱，一定能将它用在正道上！",
	["$kejintuo6"] = "这里之所以被称为进步之城是因为锲而不舍的精神。",
	["$kejintuo7"] = "我们是这么善于探索，一旦掌握它，还有什么可怕的？",
	["$kejintuo8"] = "这里可是进步之城啊，想想我们能创造多少奇迹。",
	["$kejintuo9"] = "只要您支持塔利斯家族，您将率先与我们共享进步的成果。",
	["$kejintuo10"] = "我亲眼见过魔法有怎样神奇的力量，你根本无法想象它有多美妙。",
	["$kejintuo11"] = "（飞门触发）",
	["$kejintuo12"] = "（飞门触发）",
	["$kejintuo13"] = "（飞门传送）",

	["$kechuzhism1"] = "我和维克托有了突破，海克斯科技的全新篇章。",
	["$kechuzhism2"] = "我们所需要的领导，必须着眼未来而不是固守过去。",
	["$kechuzhism3"] = "海克斯科技本来就是想用魔法造福普通人的生活，而现在，终于可以实现了。",
	["$kechuzhism4"] = "但要治理好这座城市，光说漂亮话是不够的。",
	["$kechuzhism5"] = "人类短短一生不过百岁而已，不能白耗时间坐等进化。",
	["$kechuzhism6"] = "桥上的血到现在都擦不干净，到底还要忍到什么时候？",
	["$kechuzhism7"] = "我们可能没得选。",
	["$kechuzhism8"] = "行动才是关键，不然还会有人丧命。",

	["$kebengneng1"] = "哈！",
	["$kebengneng2"] = "呵啊！",
	["$kebengneng3"] = "哈！",
	["$kebengneng4"] = "呵啊！",
	["$kebengneng5"] = "呵啊！",
	["$kebengneng6"] = "哈！",
	["$kebengneng7"] = "哈！",
	["$kebengneng8"] = "呵！",
	["$kebengneng9"] = "呼！",
	["$kebengneng10"] = "呵~哈！",
	["$kebengneng11"] = "呵~哈！",
	["$kebengneng12"] = "呵~哈！",
	["$kebengneng13"] = "呵~哈！",
	["$kebengneng14"] = "（攻击）",
	["$kebengneng15"] = "（锤形态攻击）",
	["$kebengneng16"] = "（炮形态攻击）",
	["$kebengneng17"] = "（挥舞锤）",
	["$kebengneng18"] = "（发射）",
	["$kebengneng19"] = "（发射）",

	["$kejieyan1"] = "这个问题以后讨论，当务之急是防范新的袭击。",
	["$kejieyan2"] = "这么严重的威胁怎么一直没发现？",

	["~kejayce"] = "这个研究是我的一切...是我的毕生的心血...",
	["~kejaycetwo"] = "这个研究是我的一切...是我的毕生的心血...",



}
return {extension}

