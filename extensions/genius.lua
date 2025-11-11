extension_f = sgs.Package("FCGod", sgs.Package_GeneralPack)
newgodsCard = sgs.Package("newgodsCard", sgs.Package_CardPack)
function f_Invoke(player, skill) --发动技能的信息发送
	local room = player:getRoom()
	local log = sgs.LogMessage()
	log.type = "#f_Invoke"
	log.from = player
	log.arg = skill
	room:sendLog(log)
end
local skills = sgs.SkillList()
--==DIY神武将==--
--神司马师
f_shensimashi = sgs.General(extension_f, "f_shensimashi", "god", 5, true, false, false, 4)

f_henjueCard = sgs.CreateSkillCard{
    name = "f_henjueCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
	    return #targets == 0 and to_select:hasEquipArea() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local choices = {}
		for i = 0, 4 do
			if source:hasEquipArea(i) then
				table.insert(choices, i)
			end
		end
		if choices == "" then return false end
		local choice = room:askForChoice(source, "f_henjue", table.concat(choices, "+"))
		local area = tonumber(choice)
		source:throwEquipArea(area)
		local choicess = {}
		for i = 0, 4 do
			if targets[1]:hasEquipArea(i) then
				table.insert(choicess, i)
			end
		end
		if choicess == "" then return false end
		local choicee = room:askForChoice(source, "f_henjue", table.concat(choicess, "+"))
		local area = tonumber(choicee)
		targets[1]:throwEquipArea(area)
		local e = 0
		for i = 0, 4 do
			if not source:hasEquipArea(i) then
				e = e + 1
			end
		end
		room:drawCards(source, e, "f_henjue")
	end,
}
f_henjue = sgs.CreateZeroCardViewAsSkill{
    name = "f_henjue",
	view_as = function()
		return f_henjueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:hasEquipArea() and not player:hasUsed("#f_henjueCard")
	end,
}
f_shensimashi:addSkill(f_henjue)

f_pingpan = sgs.CreateTriggerSkill{
	name = "f_pingpan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:objectName() == player:objectName() then return false end
		local e = 0
		for i = 0, 4 do
			if not damage.to:hasEquipArea(i) then
				e = e + 1
			end
		end
		if e == 0 then return false end
		local log = sgs.LogMessage()
		log.type = "$f_pingpan"
		log.from = player
		log.to:append(damage.to)
		log.arg2 = e
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName())
		damage.damage = damage.damage + e
		data:setValue(damage)
		damage.to:obtainEquipArea()
		local ea = {}
		for i = 0, 4 do
			if not player:hasEquipArea(i) then
				table.insert(ea, i)
			end
		end
		if ea == "" then return false end
		local x = ea[math.random(1, #ea)]
		local area = tonumber(x)
		player:obtainEquipArea(area)
	end,
}
f_shensimashi:addSkill(f_pingpan)



--神刘三刀
f_three = sgs.General(extension_f, "f_three", "god", 4, true)

--“三刀”升级版
f_sandaoEXSlashCard = sgs.CreateSkillCard{
	name = "f_sandaoEXSlashCard",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select, nil, false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:deleteLater()
		slash:setSkillName("f_sandaoEXSlash")
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for _, p in pairs(targets) do
			use.to:append(p)
		end
		room:broadcastSkillInvoke("f_sandaoEXSlash")
		room:broadcastSkillInvoke("f_sandaoEXSlash")
		room:broadcastSkillInvoke("f_sandaoEXSlash")
		room:useCard(use)
	end,
}
f_sandaoEXCard = sgs.CreateSkillCard{
	name = "f_sandaoEXCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@f_sandaoEX")
		room:broadcastSkillInvoke("f_sandao")
		room:doSuperLightbox("WEhaveLSD", "f_sandao")
		local n = 0
		while n < 3 and source:isAlive() do
			if room:askForUseCard(source, "@@f_sandaoEXSlash", "@f_sandaoEXSlash") then
				n = n + 1
			else
				break
			end
		end
	end,
}
f_sandaoEX = sgs.CreateZeroCardViewAsSkill{
	name = "f_sandaoEX&",
	view_as = function()
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return f_sandaoEXCard:clone()
        else
		    return f_sandaoEXSlashCard:clone()
        end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@f_sandaoEX") > 0
	end,
    enabled_at_response = function(self, player, pattern)
		return pattern == "@@f_sandaoEXSlash"
	end,
}
f_sandaoEX_Clear = sgs.CreateTriggerSkill{
	name = "#f_sandaoEX_Clear",
	frequency = sgs.Skill_Limited,
    events = {sgs.Death, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() then
		        local killer
		        if death.damage then
			        killer = death.damage.from
		        else
			        killer = nil
		        end
		        local current = room:getCurrent()
		        if killer and death.damage and death.damage.card and death.damage.card:getSkillName() == "f_sandaoEXSlash" and (current:isAlive() or current:objectName() == death.who:objectName()) then
			        if killer:getMark("f_sandaoEX") == 0 then
						room:addPlayerMark(player, "f_sandaoEX")
					end
					if killer:getMark("@f_sandaoEX") == 0 then
						room:addPlayerMark(player, "@f_sandaoEX")
					end
		        end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:hasUsed("#f_sandaoEXCard") and player:getMark("@f_sandaoEX") == 0 then
				--if player:hasSkill("f_sandaoEX") then
					room:detachSkillFromPlayer(player, "f_sandaoEX", false, false, false)
					if player:getMark("f_sandaoEX") > 0 then
						room:setPlayerMark(player, "f_sandao_using", 0)
                        room:changeTranslation(player, "f_sandao", 1)
					else
                        room:setPlayerMark(player, "f_sandao_using", 0)
                        room:setPlayerMark(player, "f_sandaoFail", 1)
						room:changeTranslation(player, "f_sandao", 2)
						room:setPlayerMark(player, "&f_sandaoUse", 0)
						room:setPlayerMark(player, "&f_sandaoResp", 0)
					end
				--end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
if not sgs.Sanguosha:getSkill("f_sandaoEX&") then skills:append(f_sandaoEX) end
if not sgs.Sanguosha:getSkill("#f_sandaoEX_Clear") then skills:append(f_sandaoEX_Clear) end
extension_f:insertRelatedSkills("f_sandaoEX", "#f_sandaoEX_Clear")

f_sandao_buff = sgs.CreateTargetModSkill{
	name = "#f_sandao_buff",
	residue_func = function(self, player)
		if player:hasSkill("f_sandao") and player:getMark("f_sandao_using") == 0 then
			return 2
		else
			return 0
		end
	end,
}
f_sandaoDraw = sgs.CreateTriggerSkill{
	name = "#f_sandaoDraw",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
			if not card:isKindOf("Slash") then return false end
			room:setPlayerMark(player, "&f_sandaoResp", 0)
			room:addPlayerMark(player, "&f_sandaoUse")
			room:addPlayerMark(player, "f_sandaoUaR")
			if player:getMark("&f_sandaoUse") >= 3 then
				room:sendCompulsoryTriggerLog(player, "f_sandao")
				room:broadcastSkillInvoke("f_sandao")
				room:drawCards(player, 3, "f_sandao")
				room:removePlayerMark(player, "&f_sandaoUse", 3)
			end
		else
			local response = data:toCardResponse()
			card = response.m_card
			if not card:isKindOf("Slash") then return false end
			room:setPlayerMark(player, "&f_sandaoUse", 0)
			room:addPlayerMark(player, "&f_sandaoResp")
			room:addPlayerMark(player, "f_sandaoUaR")
			if player:getMark("&f_sandaoResp") >= 3 then
				room:sendCompulsoryTriggerLog(player, "f_sandao")
				room:broadcastSkillInvoke("f_sandao")
				room:drawCards(player, 3, "f_sandao")
				room:removePlayerMark(player, "&f_sandaoResp", 3)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and (player:hasSkill("f_sandao") and player:getMark("f_sandaoFail") == 0)  and player:getMark("f_sandao_using") == 0
	end,
}
f_sandao = sgs.CreateTriggerSkill{
	name = "f_sandao",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	waked_skills = "f_sandaoEX",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end 
		if player:getMark("f_sandaoUaR") < 3 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("WEhaveLSD", self:objectName())
		room:addPlayerMark(player, self:objectName())
		room:addPlayerMark(player, "f_sandao_using")
		room:addPlayerMark(player, "@waked")
		room:attachSkillToPlayer(player, "f_sandaoEX")
		room:addPlayerMark(player, "@f_sandaoEX")
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName()) and player:isAlive()
	end,
}
f_three:addSkill(f_sandao)
f_three:addSkill(f_sandaoDraw)
f_three:addSkill(f_sandao_buff)
extension_f:insertRelatedSkills("f_sandao", "#f_sandaoDraw")
extension_f:insertRelatedSkills("f_sandao", "#f_sandao_buff")
extension_f:insertRelatedSkills("f_sandao", "#f_sandaoEX_Clear")


--


--

--神刘备-威力加强版
f_shenliubeiEX = sgs.General(extension_f, "f_shenliubeiEX", "god", 8, true, false, false, 6)

f_longnu = sgs.CreateTriggerSkill{
	name = "f_longnu",
	frequency = sgs.Skill_Compulsory,
	change_skill = true,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local n = player:getChangeSkillState(self:objectName())
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				--龙怒·阳
				if n <= 1 then
					room:setChangeSkillState(player, self:objectName(), 2)
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					room:loseMaxHp(player, 1)
					room:drawCards(player, 1, self:objectName())
					room:setPlayerFlag(player, "f_longnu_yang")
					for _,id in sgs.qlist(player:handCards())do
						local c = sgs.Sanguosha:getCard(id)
						if c:isRed() or c:isKindOf("EquipCard") then
							local FireSlash = sgs.Sanguosha:cloneCard("fire_slash", c:getSuit(), c:getNumber())
							FireSlash:setSkillName("f_longnu_yang")
							local card = sgs.Sanguosha:getWrappedCard(c:getId())
							card:takeOver(FireSlash)
							room:notifyUpdateCard(player, id, card)
						end
					end
				--龙怒·阴
				elseif n == 2 then
					room:setChangeSkillState(player, self:objectName(), 1)
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					room:loseMaxHp(player, 1)
					room:drawCards(player, 1, self:objectName())
					room:setPlayerFlag(player, "f_longnu_yin")
					for _,id in sgs.qlist(player:handCards())do
						local c = sgs.Sanguosha:getCard(id)
						if c:isBlack() or c:isKindOf("TrickCard") then
							local ThunderSlash = sgs.Sanguosha:cloneCard("thunder_slash", c:getSuit(), c:getNumber())
							ThunderSlash:setSkillName("f_longnu_yin")
							local card = sgs.Sanguosha:getWrappedCard(c:getId())
							card:takeOver(ThunderSlash)
							room:notifyUpdateCard(player, id, card)
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and player:hasSkill(self:objectName()) and player:getPhase() ~= sgs.Player_NotActive then
				if player:hasFlag("f_longnu_yang") then
					for _,id in sgs.qlist(player:handCards())do
						local c = sgs.Sanguosha:getCard(id)
						if c:isRed() or c:isKindOf("EquipCard") then
							local FireSlash = sgs.Sanguosha:cloneCard("fire_slash", c:getSuit(), c:getNumber())
							FireSlash:setSkillName("f_longnu_yang")
							local card = sgs.Sanguosha:getWrappedCard(c:getId())
							card:takeOver(FireSlash)
							room:notifyUpdateCard(player, id, card)
						end
					end
				end
				if player:hasFlag("f_longnu_yin") then
					for _,id in sgs.qlist(player:handCards())do
						local c = sgs.Sanguosha:getCard(id)
						if c:isBlack() or c:isKindOf("TrickCard") then
							local ThunderSlash = sgs.Sanguosha:cloneCard("thunder_slash", c:getSuit(), c:getNumber())
							ThunderSlash:setSkillName("f_longnu_yin")
							local card = sgs.Sanguosha:getWrappedCard(c:getId())
							card:takeOver(ThunderSlash)
							room:notifyUpdateCard(player, id, card)
						end
					end
				end
			end
		end
	end,
}
----
f_longnu_DRbuff = sgs.CreateTargetModSkill{
    name = "#f_longnu_DRbuff",
	pattern = "Slash",
	distance_limit_func = function(self, from, card, to)
	    if card:getSkillName() == "f_longnu_yang" or card:getSkillName() == "f_longnu_yin" then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, from, card, to)
		if card:getSkillName() == "f_longnu_yang" or card:getSkillName() == "f_longnu_yin"  then
			return 1000
		else
			return 0
		end
	end,
}
f_longnu_buffs = sgs.CreateTriggerSkill{
    name = "#f_longnu_buffs",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.TargetSpecified, sgs.EventPhaseChanging, sgs.QuitDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.from:objectName() ~= player:objectName() or not player:hasSkill("f_longnu") then return false end
			if use.card:isKindOf("FireSlash") and use.card:getSkillName() == "f_longnu_yang" then
				room:broadcastSkillInvoke("f_longnu", 3)
				local c = sgs.Sanguosha:getEngineCard(use.card:getId())
				if c:isRed() and c:isKindOf("EquipCard") then
					room:setCardFlag(use.card, "SlashIgnoreArmor")
				end
			elseif use.card:isKindOf("ThunderSlash") and use.card:getSkillName() == "f_longnu_yin" then
				room:broadcastSkillInvoke("f_longnu", 4)
			end
		elseif event == sgs.TargetSpecified then
			if use.card:getSkillName() == "f_longnu_yin" and use.from:objectName() == player:objectName() and player:hasSkill("f_longnu") then
				local c = sgs.Sanguosha:getEngineCard(use.card:getId())
				if c:isBlack() and c:isKindOf("TrickCard") then
					room:sendCompulsoryTriggerLog(player, "f_longnu_yin")
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list, "_ALL_TARGETS")
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive and player:hasSkill("f_longnu") then
			room:filterCards(player, player:getCards("he"), true)
		elseif event == sgs.QuitDying then
			if not player:isAlive() then return false end
			local current = room:getCurrent()
			if current and current:hasSkill("f_longnu") then
				local choice = room:askForChoice(current, "f_longnu", "1+2")
				if choice == "1" then
					room:sendCompulsoryTriggerLog(current, "f_longnu")
					room:broadcastSkillInvoke("f_longnu", math.random(1,2))
					room:loseHp(current, 1)
					room:drawCards(current, 1, "f_longnu")
				else
					room:sendCompulsoryTriggerLog(current, "f_longnu")
					room:broadcastSkillInvoke("f_longnu", math.random(1,2))
					room:loseMaxHp(current, 1)
					room:drawCards(current, 1, "f_longnu")
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
f_shenliubeiEX:addSkill(f_longnu)
f_shenliubeiEX:addSkill(f_longnu_DRbuff)
f_shenliubeiEX:addSkill(f_longnu_buffs)
extension_f:insertRelatedSkills("f_longnu", "#f_longnu_DRbuff")
extension_f:insertRelatedSkills("f_longnu", "#f_longnu_buffs")
f_shenliubeiEX:addSkill("jieying")



--神董卓
f_shendongzhuo = sgs.General(extension_f, "f_shendongzhuo", "god", 5, true)

f_xiongyan = sgs.CreateTriggerSkill{
	name = "f_xiongyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerFlag(player, "f_shendongzhuo") --AI判断敌友用
			room:broadcastSkillInvoke(self:objectName(), 1)
			local judge = sgs.JudgeStruct()
			judge.good = true
			judge.play_animation = false
			judge.reason = "f_xiongyan"
			judge.who = player
			room:judge(judge)
			local n = judge.card:getNumber()
			room:setPlayerFlag(player, self:objectName()) --点名判断辅助标志
			while n > 0 do
				for _, p in sgs.qlist(room:getAllPlayers()) do --进行一次点名
					if p:hasFlag(self:objectName()) then
						room:setPlayerFlag(p, "-f_xiongyan")
						room:setPlayerFlag(p:getNextAlive(), self:objectName()) --将辅助标志移给此时被点名者（下家），准备结算或下一次点名
						break
					end
				end
				n = n - 1
			end
			if n == 0 then --点名完了，开始结算
				if player:hasFlag(self:objectName()) then --最终点名到自己
					local log = sgs.LogMessage()
				    log.type = "$f_xiongyan_self"
				    log.from = player
				    room:sendLog(log)
					room:broadcastSkillInvoke(self:objectName(), 2)
					local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
					analeptic:setSkillName("f_xiongyann") --防止乱播报语音
					analeptic:deleteLater()
					room:useCard(sgs.CardUseStruct(analeptic, player, player, false))
					if player:isWounded() then room:recover(player, sgs.RecoverStruct(player)) end
				else --最终点名到别人
					room:broadcastSkillInvoke(self:objectName(), 3)
					for _, oc in sgs.qlist(room:getOtherPlayers(player)) do
						if oc:hasFlag(self:objectName()) then
							local log = sgs.LogMessage()
				    		log.type = "$f_xiongyan_others"
				    		log.from = player
							log.to:append(oc)
				    		room:sendLog(log)
							room:setPlayerFlag(oc, "-f_xiongyan")
							local choices = {}
							table.insert(choices, "1")
							if oc:getHandcardNum() + oc:getEquips():length() >= 2 then
			    				table.insert(choices, "2=" .. player:objectName())
							end
							local choice = room:askForChoice(oc, self:objectName(), table.concat(choices, "+"))
							if choice == "1" then
								room:loseHp(oc, 1)
								if not oc:isChained() then room:setPlayerChained(oc) end
							else
								local card = room:askForExchange(oc, self:objectName(), 999, 2, true, "#f_xiongyan:".. player:getGeneralName())
								if card then
									room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), oc:objectName(), self:objectName(), ""), false)
									room:setPlayerFlag(oc, "f_sdzForE") --自己的AI判断敌友用
									if room:askForSkillInvoke(player, "@f_xiongyanDraw", data) then
										local m = card:getSubcards():length()
										room:drawCards(oc, m, self:objectName())
									end
									room:setPlayerFlag(oc, "-f_sdzForE")
								end
							end
						end
					end
				end
			end
			room:setPlayerFlag(player, "-f_shendongzhuo")
		end
	end,
}
f_shendongzhuo:addSkill(f_xiongyan)

f_qianduCard = sgs.CreateSkillCard{
	name = "f_qianduCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
	    room:removePlayerMark(source, "@f_qiandu")
		room:doLightbox("QianduAnimate")
		local ChangAn = targets[1]
		local x = source:distanceTo(ChangAn)*2
		room:swapSeat(source, ChangAn)
		
		local y = 0
		for i = 1, x, 1 do
			if y >= x then break end
			local list = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if source:canDiscard(p, "ej") then
					list:append(p)
				end
			end
			if list:isEmpty() then break end
			local target = room:askForPlayerChosen(source, list, "f_qiandu", "f_qiandu-invoke", true, true)
			if not target then break end
			local draw_num = {}
			local z = 0
			if source:canDiscard(target, "ej") then
				z = target:getCards("ej"):length()
			end
			if z > x then
				z = x
			end
			if y > 0 and (z > (x - y)) then
				z = x - y
			end
			for i = 1, z, 1 do
				table.insert(draw_num, tostring(i))
			end
			local num = tonumber(room:askForChoice(source, "f_qiandu", table.concat(draw_num, "+")))
			y = y + num
			for i = 1, num, 1 do
				local id = room:askForCardChosen(source, target, "ej", "f_qiandu")
				room:throwCard(id, target, source)
				if target:isAllNude() then break end
			end
		end
		room:acquireSkill(source, "f_xibeng")
	end,
}
f_qianduVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_qiandu",
	view_as = function()
		return f_qianduCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	response_pattern = "@@f_qiandu",
}
f_qiandu = sgs.CreateTriggerSkill{
	name = "f_qiandu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_qiandu",
	view_as_skill = f_qianduVS,
	waked_skills = "f_xibeng",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@f_qiandu") > 0 then
			if not room:askForUseCard(player, "@@f_qiandu", "@f_qiandu-card") then
				room:setPlayerFlag(player, "f_qiandu_limited")
			end
		end
	end,
}
f_shendongzhuo:addSkill(f_qiandu)

--“析崩”
f_xibeng = sgs.CreateTriggerSkill{
	name = "f_xibeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpRecover, sgs.CardsMoveOneTime , sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreHpRecover then
			local recover = data:toRecover()
			if recover.who:objectName() == player:objectName() and not player:hasFlag("Global_Dying") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local n = recover.recover + 2
				room:drawCards(player, n, self:objectName())
				return true
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand
			and not move.card_ids:isEmpty() and move.reason.m_skillName == self:objectName() then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					room:setCardFlag(card, "f_xibengCard")
					room:setCardTip(card:getId(), "f_xibeng")
					room:ignoreCards(player, card)
				end
			end
		elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("f_xibengCard") then
                        room:ignoreCards(player, card)
                    end
                end
            end
		end
	end,
}
if not sgs.Sanguosha:getSkill("f_xibeng") then skills:append(f_xibeng) end


--神罗贯中
f_shenluoguanzhong = sgs.General(extension_f, "f_shenluoguanzhong", "god", 4, true)

f_yanyiCard = sgs.CreateSkillCard{
	name = "f_yanyiCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
	    local mhp = player:getMaxHp()
		local hp = player:getHp()
		local allnames = sgs.Sanguosha:getLimitedGeneralNames() 
		for _, p in sgs.qlist(room:getPlayers()) do
			local name = p:getGeneralName()
			allnames[name] = nil
		end
        math.randomseed(tostring(os.time()):reverse():sub(1,7))
		local targetss = {}
		for i = 1, 1, 1 do
			local count = #allnames
			local index = math.random(1, count)
			local selected = allnames[index]
			table.insert(targetss, selected)
			allnames[selected] = nil
		end
		local generals = table.concat(targetss, "+")
		local general = room:askForGeneral(player, generals)
		room:changeHero(player, general, false, false, true, true)
		room:setPlayerProperty(player, "maxhp", sgs.QVariant(mhp))
		room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
	end,
}
f_yanyiVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_yanyi",
	view_as = function()
		return f_yanyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_yanyiCard")
	end,
}
f_yanyi = sgs.CreateTriggerSkill{
	name = "f_yanyi",
	view_as_skill = f_yanyiVS,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.GameStart, sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Judge)
		or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) or event == sgs.GameStart or  event == sgs.TurnStart then
			if event == sgs.GameStart or  event == sgs.TurnStart or room:askForSkillInvoke(player, self:objectName(), data) then
				local mhp = player:getMaxHp()
				local hp = player:getHp()
				room:broadcastSkillInvoke(self:objectName())
				local allnames = sgs.Sanguosha:getLimitedGeneralNames() 
				for _, p in sgs.qlist(room:getPlayers()) do
					local name = p:getGeneralName()
					allnames[name] = nil
				end
				math.randomseed(tostring(os.time()):reverse():sub(1,7))
				local targets = {}
				for i = 1, 1, 1 do
					local count = #allnames
					local index = math.random(1, count)
					local selected = allnames[index]
					table.insert(targets, selected)
					allnames[selected] = nil
				end
				local generals = table.concat(targets, "+")
				local general = room:askForGeneral(player, generals)
				room:changeHero(player, general, false, false, true, true)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(mhp))
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
			end
		end
	end,

}
f_shenluoguanzhong:addSkill(f_yanyi)

--

--神左慈
f_shenzuoci = sgs.General(extension_f, "f_shenzuoci", "god", 3, true)

--==攻击特效==-- --左慈手杀传说动皮“使役鬼神”的出框动画，特别感谢珂酱的技术支持！（设置成仅作为主将可以触发，避免与其他动皮武将双将时的动画冲突）
f_shenzuociAttack = sgs.CreateTriggerSkill{
	name = "#f_shenzuociAttack",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel") or use.card:isKindOf("AOE"))
		and use.from:objectName() == player:objectName() then
			room:broadcastSkillInvoke("f_quanshen")
			room:setEmotion(player, "f_shenzuoci_small")
			room:getThread():delay(1000)
		end
	end,
	can_trigger = function(self, player)
		return player and player:getGeneralName() == "f_shenzuoci" --or player:getGeneral2Name() == "f_shenzuoci"
	end,
}
---
f_shenzuoci:addSkill(f_shenzuociAttack)
f_quanshen = sgs.CreateTriggerSkill{
	name = "f_quanshen",
	priority = -100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerProperty(p, "kingdom", sgs.QVariant("god"))
		end
	end,
}

f_shenzuoci:addSkill(f_quanshen)
f_yishiCard = sgs.CreateSkillCard{
	name = "f_yishiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local sks = source:getTag("f_yishi"):toString():split("+")
		local n = 0
		for _, s in ipairs(sks) do --先检测玩家有没有记录里的技能，没有则不能选2选项和3选项
			if source:hasSkill(s) then
				n = n + 1
			end
		end
		local hp = source:getHp()
		if hp < 1 then hp = 1 end
	    local choices = {}
		if source:getHandcardNum() >= hp and source:getEquips():length() > 0 and source:canDiscard(source, "he") then
			table.insert(choices, "1=" .. hp)
		end
		if n > 0 then
			table.insert(choices, "2")
			table.insert(choices, "3")
		end
		table.insert(choices, "cancel")
		local choice = room:askForChoice(source, "f_yishi", table.concat(choices, "+"))
		if choice == "cancel" then
			room:addPlayerHistory(source, "#f_yishiCard", -1)
			return
		end
		if choice == "1=" .. hp then
			room:askForDiscard(source, "f_yishi", hp, hp)
			local card_id = room:askForCardChosen(source, source, "e", "f_yishi", false, sgs.Card_MethodDiscard)
			room:throwCard(sgs.Sanguosha:getCard(card_id), source, source)
			local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
			local god_generals = {}
			for _, name in ipairs(all_generals) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general:getKingdom() == "god" then
					table.insert(god_generals, name)
				end
			end
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if table.contains(god_generals, p:getGeneralName()) then
					table.removeOne(god_generals, p:getGeneralName())
				end
			end
			local god_general = {}
			for i = 1, hp do
				local first = god_generals[math.random(1, #god_generals)]
				table.insert(god_general, first)
				table.removeOne(god_generals, first)
			end
			local generals = table.concat(god_general, "+")
			local general = sgs.Sanguosha:getGeneral(room:askForGeneral(source, generals))
			local skill_names = {}
			for _, skill in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(skill_names, skill:objectName())
			end
			if #skill_names > 0 then
				local one = room:askForChoice(source, "f_yishi", table.concat(skill_names, "+"))
				room:broadcastSkillInvoke("f_yishi")
				room:acquireSkill(source, one)
				table.insert(sks, one) --登记为以此法获得的技能
			end
		elseif choice == "2" or choice == "3" then
			local reduce_skilllist = {}
			for _, lsk in ipairs(sks) do
				if source:hasSkill(lsk) then
					table.insert(reduce_skilllist, lsk)
				end
			end
			local off = room:askForChoice(source, "f_yishi", table.concat(reduce_skilllist, "+"))
			room:detachSkillFromPlayer(source, off)
			if choice == "2" then
				local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
				local god_generals = {}
				for _, name in ipairs(all_generals) do
					local general = sgs.Sanguosha:getGeneral(name)
					if general:getKingdom() == "god" then
						table.insert(god_generals, name)
					end
				end
				local god_general = {}
				local first = god_generals[math.random(1, #god_generals)]
				table.insert(god_general, first)
				local generals = table.concat(god_general, "+")
				local general = sgs.Sanguosha:getGeneral(room:askForGeneral(source, generals))
				local skill_names = {}
				for _, skill in sgs.qlist(general:getVisibleSkillList()) do
					table.insert(skill_names, skill:objectName())
				end
				if #skill_names > 0 then
					local one = skill_names[math.random(1, #skill_names)]
					room:broadcastSkillInvoke("f_yishi")
					room:acquireSkill(source, one)
					table.insert(sks, one) --登记为以此法获得的技能
				end
			elseif choice == "3" then
				if source:isWounded() then
					if room:askForChoice(source, "f_yishi", "draw+recover") == "recover" then
						room:broadcastSkillInvoke("f_yishi")
						local recover = sgs.RecoverStruct()
						recover.who = source
						room:recover(source, recover)
					else
						room:broadcastSkillInvoke("f_yishi")
						room:drawCards(source, 2, "f_yishi")
					end
				else
					room:broadcastSkillInvoke("f_yishi")
					room:drawCards(source, 2, "f_yishi")
				end
			end
		end
		source:setTag("f_yishi", sgs.QVariant(table.concat(sks, "+")))
	end,
}
f_yishiVS = sgs.CreateZeroCardViewAsSkill{
    name = "f_yishi",
	view_as = function()
		return f_yishiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_yishiCard")
	end,
}
f_yishi = sgs.CreateTriggerSkill{
	name = "f_yishi",
	priority = 100000, --保证最高优先级，不然某些回合开始时的技能用不了/没效果
	view_as_skill = f_yishiVS,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local n = player:getHp()
		if n - 1 <= 0 then return false end
		local sks = player:getTag("f_yishi"):toString():split("+")
		room:sendCompulsoryTriggerLog(player, "f_yishi")
		room:broadcastSkillInvoke("f_yishi")
		local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
		local god_generals = {}
		for _, name in ipairs(all_generals) do
			local general = sgs.Sanguosha:getGeneral(name)
			if general:getKingdom() == "god" then
				table.insert(god_generals, name)
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if table.contains(god_generals, p:getGeneralName()) then
				table.removeOne(god_generals, p:getGeneralName())
			end
		end
		local god_general = {}
		for i = 1, n+1 do
			local first = god_generals[math.random(1, #god_generals)]
			table.insert(god_general, first)
			table.removeOne(god_generals, first)
		end
		local m = n - 1
		while m > 0 do
			local generals = table.concat(god_general, "+")
			local general = sgs.Sanguosha:getGeneral(room:askForGeneral(player, generals))
			local skill_names = {}
			for _, skill in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(skill_names, skill:objectName())
			end
			if #skill_names > 0 then
				local one = room:askForChoice(player, "f_yishi", table.concat(skill_names, "+"))
				room:acquireSkill(player, one)
				table.insert(sks, one) --登记为以此法获得的技能
				for _, nam in ipairs(god_general) do
					local generall = sgs.Sanguosha:getGeneral(nam)
					if generall:objectName() == general:objectName() then
						table.removeOne(god_general, nam)
					end
				end
				m = m - 1
			end
		end
		player:setTag("f_yishi", sgs.QVariant(table.concat(sks, "+")))
	end,
}

f_shenzuoci:addSkill(f_yishi)

f_mizong = sgs.CreateMasochismSkill{
	name = "f_mizong",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local data = sgs.QVariant()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local loseskill = {}
			for _, skill in sgs.qlist(player:getVisibleSkillList()) do
				table.insert(loseskill, skill:objectName())
			end
			room:broadcastSkillInvoke(self:objectName(), 1)
			local choice = room:askForChoice(player, self:objectName(), table.concat(loseskill, "+"))
			local other = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			room:detachSkillFromPlayer(player, choice)
			room:acquireSkill(other, choice)
			room:broadcastSkillInvoke(self:objectName(), 2)
			if player:hasSkill(self:objectName()) then room:addPlayerMark(player, "&f_mizongRMC")
			room:addMaxCards(player, -1, false)
			end
		end
	end,
}
f_shenzuoci:addSkill(f_mizong)


--神刘禅
f_shenliushan = sgs.General(extension_f, "f_shenliushan$", "god", 4, true)

f_leji = sgs.CreateTriggerSkill{
	name = "f_leji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Indulgence") and not use.to:contains(player) and player:hasSkill(self:objectName()) and not player:containsTrick("indulgence") then
				room:setPlayerFlag(use.to:first(), "f_leji")
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					use.to:removeOne(use.to:first())
					use.to:append(player)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					
				end
				room:setPlayerFlag(use.to:first(), "-f_leji")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard and player:hasSkill(self:objectName()) and not player:containsTrick("indulgence")  then
				local targets = sgs.SPlayerList()
				for _, cjl in sgs.qlist(room:getOtherPlayers(player)) do
					if cjl:containsTrick("indulgence") then 
						targets:append(cjl)
					end
				end

				local IdgCard = room:askForExchange(player, self:objectName(), 1, 1, true, "f_lejiPush", true)
				if IdgCard then
					local Indulgence = sgs.Sanguosha:cloneCard("indulgence", IdgCard:getSuit(), IdgCard:getNumber())
					Indulgence:setSkillName(self:objectName())
					Indulgence:addSubcard(IdgCard)
					Indulgence:deleteLater()
					if not player:isProhibited(player, Indulgence) then
						room:useCard(sgs.CardUseStruct(Indulgence, player, player))
					end
				else
					if targets:length() > 0 then
						local BSS = room:askForPlayerChosen(player, targets, self:objectName(), "f_lejiIndulgenceMove",true, true)
						if BSS then
							local card, place
							for _, c in sgs.qlist(BSS:getJudgingArea()) do
								if c:isKindOf("Indulgence") then
									card = c
									place = room:getCardPlace(c:getEffectiveId())
								end
							end
							if card and place then
								room:moveCardTo(card, BSS, player, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ""))
							end
						end
					end
				end
			end
		end
	end,
}
f_shenliushan:addSkill(f_leji)

f_wuyou = sgs.CreateProhibitSkill{
	name = "f_wuyou",
	frequency = sgs.Skill_Frequent,
	is_prohibited = function(self, from, to, card)
		return to and to:hasSkill(self:objectName()) and ((card:isKindOf("Slash") or card:isKindOf("Duel")) and not card:isVirtualCard()) and to:containsTrick("indulgence")
	end,
}
f_wuyou_Clear = sgs.CreateTriggerSkill{
    name = "#f_wuyou_Clear",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and player:hasSkill("f_wuyou") then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Indulgence") then
						for _, c in sgs.qlist(player:getJudgingArea()) do --是你逼我的
							if c:isKindOf("Indulgence") then
								room:broadcastSkillInvoke("f_wuyou") --当【乐不思蜀】进入神刘禅的判定区时播放，就像诸葛亮的“空城”一样，代表“无忧”开始起作用了
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:hasSkill("f_wuyou") and room:askForSkillInvoke(player, "f_wuyou", data) then
				room:broadcastSkillInvoke("f_wuyou")
				local n, choices = 0, {}
				if player:hasJudgeArea() then
					n = player:getJudgingArea():length()
					table.insert(choices, "1="..n+1)
					table.insert(choices, "2")
				else
					table.insert(choices, "3")
				end
				table.insert(choices, "cancel")
				local choice = room:askForChoice(player, "f_wuyou", table.concat(choices, "+"))
				if string.startsWith(choice, "1") then
					local chengxiang = room:askForPlayerChosen(player, room:getAllPlayers(), "f_wuyou")
					room:drawCards(chengxiang, n+1, "f_wuyou")
					if player:hasSkill("f_leji") then
						room:addPlayerMark(player, "f_wuyouf_leji")
						room:addPlayerMark(player, "Qingchengf_leji")
					end
				elseif choice == "2" then
					if n > 0 then
						local dummy, dummy_id = sgs.Sanguosha:cloneCard("slash"), sgs.IntList()
						--dummy:addSubcards(player:getJudgingAreaID())
						for _, cd in sgs.qlist(player:getJudgingArea()) do
							dummy_id:append(cd:getEffectiveId())
						end
						dummy:addSubcards(dummy_id)
						room:obtainCard(player, dummy)
						dummy:deleteLater()
					end
					if player:isWounded() then
						room:recover(player, sgs.RecoverStruct("f_wuyou"))
					end
					room:addPlayerMark(player, "f_wuyouf_wuyou")
					room:addPlayerMark(player, "Qingchengf_wuyou")
				elseif choice == "3" then
					player:obtainJudgeArea()
				end
				local jsonValue = {
					8
				}
				room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if player:getMark("f_wuyouf_wuyou") > 0 then
				room:setPlayerMark(player, "f_wuyouf_wuyou", 0)
				room:setPlayerMark(player, "Qingchengf_wuyou", 0)
			end
			if player:getMark("f_wuyouf_leji") > 0 then
				room:setPlayerMark(player, "f_wuyouf_leji", 0)
				room:setPlayerMark(player, "Qingchengf_leji", 0)
			end
			local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenliushan:addSkill(f_wuyou)
f_shenliushan:addSkill(f_wuyou_Clear)
extension_f:insertRelatedSkills("f_wuyou", "#f_wuyou_Clear")

f_dansha = sgs.CreateTriggerSkill{
    name = "f_dansha$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local move = data:toMoveOneTime()
		if event == sgs.BeforeCardsMove then
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if player:containsTrick("indulgence") then
					room:addPlayerMark(player, self:objectName()) --“单杀”启动前置条件标记
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if not player:containsTrick("indulgence") and player:getMark(self:objectName()) > 0 then
					local smz = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "f_danshaSiMaZhao", true, true)
					if smz then
						room:broadcastSkillInvoke(self:objectName())
						room:loseHp(smz, 2)
						if not smz:isAlive() then room:detachSkillFromPlayer(player, self:objectName())
						end
					end
				end
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,
}
f_shenliushan:addSkill(f_dansha)




--神曹仁
f_shencaoren = sgs.General(extension_f, "f_shencaoren", "god", 4, true)

f_qizhen = sgs.CreateTriggerSkill{
    name = "f_qizhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard")) and use.from and use.from:objectName() ~= player:objectName()
			and use.to and use.to:contains(player) and use.to:length() == 1 and player:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade" --判定出♠：被破阵，等价于判定失败。
					judge.good = false
					judge.play_animation = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					local jsuit = judge.card:getSuit()
					-- ♠
					if jsuit == sgs.Card_Spade then
						room:broadcastSkillInvoke(self:objectName(), 1)
						local log = sgs.LogMessage()
						log.type = "$f_qizhenSpadePZ"
						log.from = player
						log.to:append(use.from)
						room:sendLog(log)
						if not player:hasFlag("f_qizhen_beipo") then room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false) end
						room:setPlayerFlag(player, "f_qizhen_beipo")
					-- ♣
					elseif jsuit == sgs.Card_Club then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:drawCards(player, 1, self:objectName())
					-- ♦
					elseif jsuit == sgs.Card_Diamond then
						room:broadcastSkillInvoke(self:objectName(), 3)
						--return true
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					-- ♥
					elseif jsuit == sgs.Card_Heart then
						room:broadcastSkillInvoke(self:objectName(), 4)
						local lbj = use.from
						local log = sgs.LogMessage()
						log.type = "$f_qizhenHeartEXchange"
						log.from = player
						log.to:append(lbj)
						log.card_str = use.card:getEffectiveId()
						room:sendLog(log)
						for _, p in sgs.qlist(use.to) do
							use.to:removeOne(p)
						end
						use.from = player
						use.to:append(lbj)
						room:doAnimate(1, player:objectName(), lbj:objectName())
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("f_qizhen_beipo") then
					room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
					room:setPlayerFlag(p, "-f_qizhen_beipo")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shencaoren:addSkill(f_qizhen)

f_lijun = sgs.CreateMasochismSkill{
	name = "f_lijun",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local weijun = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "f_lijun-invoke",true, true)
		if weijun then
			local choicelist = {"1"}
			if weijun:getHandcardNum() - weijun:getHp() > 0 then
				table.insert(choicelist, "2")
			end
			local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(weijun))
			if choice == "1" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:drawCards(weijun, player:getLostHp(), self:objectName())
				if weijun:objectName() ~= player:objectName() and room:askForSkillInvoke(player, "@f_lijunGHJ", ToData(weijun)) then
					room:broadcastSkillInvoke(self:objectName(), 4)
					weijun:gainHujia(1)
				end
			elseif choice == "2" then
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:askForDiscard(weijun, self:objectName(), weijun:getHandcardNum() - weijun:getHp(), weijun:getHandcardNum() - weijun:getHp())
				if weijun:objectName() ~= player:objectName() then
					--资敌（
					if room:askForSkillInvoke(player, "@f_lijunGHJ", ToData(weijun)) then
						room:broadcastSkillInvoke(self:objectName(), 4)
						weijun:gainHujia(1)
					end
				end
			end
		end
	end,
}
f_shencaoren:addSkill(f_lijun)


--神赵云&陈到
f_shenZhaoyunChendao = sgs.General(extension_f, "f_shenZhaoyunChendao", "god", 4, true)

f_junzhen = sgs.CreateMaxCardsSkill{
	name = "f_junzhen",
	extra_func = function(self, player)
		local n = 0
		if player:hasSkill(self:objectName()) then
			n = n + 2
			if player:getArmor() ~= nil then
				n = n + 2
			end
		end
		return n
	end,
}
f_junzhenAudio = sgs.CreateTriggerSkill{
    name = "#f_junzhenAudio",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Discard then return false end
		room:sendCompulsoryTriggerLog(player, "f_junzhen")
		room:notifySkillInvoked(player, "f_junzhen")
		room:broadcastSkillInvoke("f_junzhen")
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill("f_junzhen") and player:getHandcardNum() > player:getHp()
	end,
}
f_shenZhaoyunChendao:addSkill(f_junzhen)
f_shenZhaoyunChendao:addSkill(f_junzhenAudio)
extension_f:insertRelatedSkills("f_junzhen", "#f_junzhenAudio")

f_yonghunSlashCard = sgs.CreateSkillCard{
	name = "f_yonghunSlashCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select, nil, false) --无距离限制
			and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			room:broadcastSkillInvoke("f_yonghun")
			room:setCardFlag(c, "SlashIgnoreArmor")
			--room:useCard(sgs.CardUseStruct(c, effect.from, effect.to), true) --仅无次数限制
			room:useCard(sgs.CardUseStruct(c, effect.from, effect.to), false) --无次数限制且不计次
		end
	end,
}
f_yonghunCard = sgs.CreateSkillCard{
	name = "f_yonghunCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card_ids = room:drawCardsList(source, 2, "f_yonghun", true, true)
		for _, id in sgs.qlist(card_ids) do
			room:setCardFlag(id, "f_yonghun")
		end
		for _, id in sgs.qlist(card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Analeptic") and room:askForSkillInvoke(source, "f_yonghun", ToData(c)) then
				room:broadcastSkillInvoke("f_yonghun")
				room:useCard(sgs.CardUseStruct(c, source, source), false) --不计入使用次数
				room:addPlayerMark(source, "f_yonghun-PlayClear")
			end
		end
		for _, id in sgs.qlist(card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Peach") then
				local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(source)) do
                    if p:isWounded() then
                        targets:append(p)
                    end
                end
                if targets:isEmpty() then 
					local dest = room:askForPlayerChosen(source, targets, self:objectName(), "f_yonghun-invoke", true, true)
					if dest then
						dest:obtainCard(c)
						room:broadcastSkillInvoke("f_yonghun")
						room:useCard(sgs.CardUseStruct(c, dest, dest))
					end
				end
			end
		end
		for _, id in sgs.qlist(card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Jink")  and room:askForSkillInvoke(source, "f_yonghun", ToData(c)) then
				room:throwCard(id,self:objectName(),source,source)
				room:broadcastSkillInvoke("f_yonghun")
				room:drawCards(source, 2, "f_yonghun")
			end
		end
		for _, id in sgs.qlist(card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Slash")  then
				room:askForUseCard(source, "@@f_yonghunSlash", "@f_yonghunSlash")
			end
		end
		for _, id in sgs.qlist(card_ids) do
			room:setCardFlag(id, "-f_yonghun")
		end
	end,
}
f_yonghunVS = sgs.CreateViewAsSkill{
    name = "f_yonghun",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:hasFlag("f_yonghun") and to_select:isKindOf("Slash")
    end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern == "@@f_yonghunSlash" then
			if #cards == 1 then
				local card = f_yonghunSlashCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		end
		return f_yonghunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#f_yonghunCard") < 2
	end,
	enabled_at_response = function(self, player, pattern)
        return pattern == "@@f_yonghunSlash"
	end,
}

f_yonghun = sgs.CreateTriggerSkill{
    name = "f_yonghun",
	events = {sgs.CardUsed, sgs.EventPhaseEnd},
	view_as_skill = f_yonghunVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then return false end --防火防盗防技能卡牌
			if player:getMark("f_yonghun-PlayClear") > 0 then
				room:sendCompulsoryTriggerLog(player, "f_yonghun", true)
				use.m_addHistory = false
				data:setValue(use)
				room:setPlayerMark(player, "f_yonghun-PlayClear", 0)
			end
		end
	end,
}
f_yonghun_buff = sgs.CreateTargetModSkill{
	name = "#f_yonghun_buff",
	pattern = "Card",
	residue_func = function(self, player, card)
		if player:hasSkill("f_yonghun") and player:getMark("f_yonghun-PlayClear") > 0 then
			return 1000
		else
			return 0
		end
	end,
}
f_shenZhaoyunChendao:addSkill(f_yonghun)
f_shenZhaoyunChendao:addSkill(f_yonghun_buff)
extension_f:insertRelatedSkills("f_yonghun", "#f_yonghun_buff")


--神孙尚香
f_shensunshangxiang = sgs.General(extension_f, "f_shensunshangxiang", "god", 4, false)

--丢牌：
f_jianyuanthrowCard = sgs.CreateSkillCard{
	name = "f_jianyuanthrowCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			room:setCardFlag(c, "-f_jianyuan")
		end
	end,
}
--给牌：
f_jianyuangiveCard = sgs.CreateSkillCard{
	name = "f_jianyuangiveCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:hasFlag("f_JYuan") or to_select:objectName() == sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			room:setCardFlag(c, "-f_jianyuan")
		end
		room:broadcastSkillInvoke("f_jianyuan", 2)
		effect.to:obtainCard(self, false)
		if effect.to:objectName() ~= effect.from:objectName() then
			room:setPlayerFlag(effect.to, "f_JYuan_real")
		end
	end,
}
f_jianyuanVS = sgs.CreateOneCardViewAsSkill{
    name = "f_jianyuan",
	mute = true,
	view_filter = function(self, to_select)
		return to_select:hasFlag("f_jianyuan")
	end,
	view_as = function(self, card)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@f_jianyuangive" then
			local jyg = f_jianyuangiveCard:clone()
			jyg:addSubcard(card)
			return jyg
		else
			local jyt = f_jianyuanthrowCard:clone()
			jyt:addSubcard(card)
			return jyt
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@f_jianyuan")
	end,
}
f_jianyuan = sgs.CreateTriggerSkill{
    name = "f_jianyuan",
	view_as_skill = f_jianyuanVS,
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for i = 0, damage.damage - 1, 1 do
			if player:getEquips():length() == 0 then break end
			if room:askForSkillInvoke(player, self:objectName(), data) then
			--寻找【缘】角色：
				--1.装备区里有牌
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isMale() and p:getEquips():length() > 0 then
						room:setPlayerFlag(p, "f_JYuan")
					end
				end
				--2.此次的伤害目标(你造成伤害)/伤害来源(你受到伤害)
				local to
				if event == sgs.Damage and damage.to:isAlive() then
					to = damage.to
				elseif event == sgs.Damaged and damage.from then
					to = damage.from
				end
				if to and to:objectName() ~= player:objectName() and to:isMale() and not to:hasFlag("f_JYuan") then
					room:setPlayerFlag(to, "f_JYuan")
				end
				--3.被记录入《剑缘录》
				local JianYuanLu = player:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isMale() and table.contains(JianYuanLu, p:getGeneralName()) and not p:hasFlag("f_JYuan") then
						room:setPlayerFlag(p, "f_JYuan")
					end
				end
				if not player:isKongcheng() then
					player:throwAllHandCards()
				end
				local x = 4 + player:getMark("&f_jianyuanX")
				if player:getWeapon() ~= nil then x = x + 1 end
				local card_ids = room:getNCards(x)
				for _, id in sgs.qlist(card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					room:setCardFlag(card, self:objectName())
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not card_ids:isEmpty() then
					for _, id in sgs.qlist(card_ids) do
						dummy:addSubcard(id)
					end
					room:obtainCard(player, dummy, false)
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				dummy:clearSubcards()
				local z = 3
				while z > 0 do
					if not room:askForUseCard(player, "@@f_jianyuangive", "@f_jianyuangive-card") then
						room:askForUseCard(player, "@@f_jianyuanthrow!", "@f_jianyuanthrow-card")
					end
					z = z - 1
				end
				local y = 2 + player:getMark("&f_jianyuanY")
				if player:getWeapon() ~= nil then y = y + 1 end
				if player:getHandcardNum() > y then player:turnOver() end
				if player:getHandcardNum() > 4 then room:loseHp(player, 1) end
				--==《剑缘录》==--
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("f_JYuan_real") then
						room:setPlayerFlag(p, "-f_JYuan_real")
						if p:getWeapon() ~= nil or not table.contains(JianYuanLu, p:getGeneralName()) then
							local choice = room:askForChoice(player, self:objectName(), "x+y")
							if choice == "x" then room:addPlayerMark(player, "&f_jianyuanX")
							else room:addPlayerMark(player, "&f_jianyuanY") end
						end
						if not table.contains(JianYuanLu, p:getGeneralName()) and room:askForSkillInvoke(player, self:objectName().."add", ToData("JianYuanLu:"..p:objectName())) then
							room:broadcastSkillInvoke(self:objectName(), 3)
							table.insert(JianYuanLu, p:getGeneralName())
							room:setPlayerProperty(player, "SkillDescriptionRecord_f_jianyuan", sgs.QVariant(table.concat(JianYuanLu, "+")))
							player:setSkillDescriptionSwap("f_jianyuan","%arg11", table.concat(JianYuanLu, "+"))
							room:changeTranslation(player, "f_jianyuan", 11)
						end
					end
				end
				--==============--
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("f_JYuan") then
						room:setPlayerFlag(p, "-f_JYuan")
					end
				end
				for _, c in sgs.qlist(player:getHandcards()) do
					if c:hasFlag(self:objectName()) then
						room:setCardFlag(c, "-f_jianyuan")
					end
				end
			else
				break
			end
		end
	end,
}
f_shensunshangxiang:addSkill(f_jianyuan)

f_gongli = sgs.CreateTriggerSkill{
    name = "f_gongli",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if player:hasSkill(self:objectName()) then
				local JianYuanLu = player:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:distanceTo(p) <= #JianYuanLu + 1 then
						if not player:hasFlag("fGLfrom") then room:setPlayerFlag(player, "fGLfrom") end
						room:setPlayerFlag(p, "fGLPto")
						room:insertAttackRangePair(player, p)
					end
				end
			end
			if not player:isWounded() then return false end
			for _, ss in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local JianYuanLuu = ss:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
				if table.contains(JianYuanLuu, player:getGeneralName()) then
					local choices = {}
					if ss:hasEquipArea() then
						table.insert(choices, "ue")
					end
					table.insert(choices, "dc")
					table.insert(choices, "cancel")
					local choice = room:askForChoice(ss, self:objectName(), table.concat(choices, "+"))
					if choice == "cancel" then return false end
					if choice == "ue" then
						local use_id = -1
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if (card:isKindOf("Weapon") and ss:hasEquipArea(0)) or (card:isKindOf("Armor") and ss:hasEquipArea(1))
							or (card:isKindOf("DefensiveHorse") and ss:hasEquipArea(2)) or (card:isKindOf("OffensiveHorse") and ss:hasEquipArea(3))
							or (card:isKindOf("Treasure") and ss:hasEquipArea(4)) then --这样分类讨论是为了防止没有对应装备栏还使用对应副类别的装备
								use_id = id
								break
							end
						end
						room:doAnimate(1, ss:objectName(), ss:objectName())
						if use_id >= 0 then
							local use_card = sgs.Sanguosha:getCard(use_id)
							if ss:isAlive() and ss:canUse(use_card, ss, true) then
								room:broadcastSkillInvoke(self:objectName())
								room:useCard(sgs.CardUseStruct(use_card, ss, ss))
							end
						end
					elseif choice == "dc" then
						room:broadcastSkillInvoke(self:objectName())
						room:drawCards(ss, 1, self:objectName())
					end
					room:recover(player, sgs.RecoverStruct(ss), true)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:hasFlag("fGLfrom") then room:setPlayerFlag(player, "-fGLfrom") else return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("fGLto") then
					room:setPlayerFlag(p, "-fGLto")
					room:removeAttackRangePair(player, p)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shensunshangxiang:addSkill(f_gongli)



--神于吉
f_shenyuji = sgs.General(extension_f, "f_shenyuji", "god", 2, true)

f_huisheng = sgs.CreateTriggerSkill{
    name = "f_huisheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
			if player:getMark("f_huishengRedBan") > 0 and player:getMark("f_huishengBlackBan") > 0 then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local judge = sgs.JudgeStruct()
				if player:getMark("f_huishengRedBan") > 0 then
					judge.pattern = ".|black"
				elseif player:getMark("f_huishengBlackBan") > 0 then
					judge.pattern = ".|red"
				else
					judge.pattern = "." --不考虑无色了，但无色就算动画打√也过不了，后面会卡着仅限红色或黑色牌
				end
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() and (judge.card:isRed() or judge.card:isBlack()) then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local hs = 2 - player:getHp()
					room:recover(player, sgs.RecoverStruct(player, nil, hs))
					if not player:isAllNude() then
						local throw_all = sgs.IntList()
						for _, c in sgs.qlist(player:getCards("hej")) do
							throw_all:append(c:getEffectiveId())
						end
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not throw_all:isEmpty() then
							for _, id in sgs.qlist(throw_all) do
								dummy:addSubcard(id)
							end
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
							room:throwCard(dummy, reason, player)
							dummy:deleteLater()
						end
					end
					room:drawCards(player, 4, self:objectName())
					local choices = {}
					if player:getMark("f_huishengRedBan") == 0 then
						table.insert(choices, "dr")
					end
					if player:getMark("f_huishengBlackBan") == 0 then
						table.insert(choices, "db")
					end
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice == "dr" then
						local log = sgs.LogMessage()
						log.type = "$f_huishengRedBan"
						log.from = player
						room:sendLog(log)
						room:addPlayerMark(player, "f_huishengRedBan")
					elseif choice == "db" then
						local log = sgs.LogMessage()
						log.type = "$f_huishengBlackBan"
						log.from = player
						room:sendLog(log)
						room:addPlayerMark(player, "f_huishengBlackBan")
					end
				else
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
			end
		end
	end,
}
f_shenyuji:addSkill(f_huisheng)

f_miaodao = sgs.CreateTriggerSkill{
    name = "f_miaodao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local card_id
				if player:getHandcardNum() == 1 then
					card_id = player:handCards():first()
				else
					card_id = room:askForExchange(player, self:objectName(), 2, 1, false, "f_miaodaoPush")
				end
				player:addToPile("f_syjDao", card_id)
				room:broadcastSkillInvoke(self:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial)
			and table.contains(move.from_pile_names, "f_syjDao") and player:getPile("f_syjDao"):length() == 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 2, self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local n = player:getPile("f_syjDao"):length() if n > 4 then n = 4 end
			if n > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, n, self:objectName())
			end
		end
	end,
}
f_shenyuji:addSkill(f_miaodao)

f_yifaCard = sgs.CreateSkillCard{
	name = "f_yifaCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "f_yifaPUT")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), nil, self:objectName(), nil)
		room:moveCardTo(self, source, nil, sgs.Player_DrawPile, reason, false)
		room:setPlayerFlag(source, "-f_yifaPUT")
	end,
}
f_yifaVS = sgs.CreateOneCardViewAsSkill{
	name = "f_yifa",
	filter_pattern = ".|.|.|f_syjDao",
	expand_pile = "f_syjDao",
	view_as = function(self, card)
		local pc = f_yifaCard:clone()
		pc:addSubcard(card)
		return pc
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@f_yifa")
	end,
}
f_yifa = sgs.CreateTriggerSkill{
    name = "f_yifa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding, sgs.RoundStart},
	view_as_skill = f_yifaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			local phase = player:getPhase()
			if phase ~= sgs.Player_Start then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("f_yifa_lun") >= 2 then continue end
				if p:isKongcheng() and p:getPile("f_syjDao"):length() == 0 then continue end
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:addPlayerMark(p, "f_yifa_lun")
					room:broadcastSkillInvoke(self:objectName())
					local optional = not p:getPile("f_syjDao"):isEmpty()
					local card = room:askForExchange(p, "f_yifa", 1,1, false, "@f_yifa:"..p:objectName(), optional)
					if card then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, p:objectName(), nil, self:objectName(), nil)
						room:moveCardTo(card, p, nil, sgs.Player_DrawPile, reason, false)
					else
						room:askForUseCard(p, "@@f_yifa!", "@f_yifa-Dao")
					end
					
					local current = room:getCurrent()
					local choicess = {}
					if room:canMoveField("ej") then
						table.insert(choicess, "move")
					end
					if not current:isAllNude() then
						table.insert(choicess, "get")
					end
					if #choicess > 0 then
						local choicee = room:askForChoice(p, self:objectName(), table.concat(choicess, "+"))
						if choicee == "move" then
							if room:canMoveField("ej") then
								room:moveField(player, self:objectName(), true, "ej")
							end
						elseif choicee == "get" then
							room:doAnimate(1, p:objectName(), current:objectName())
							local card_id = room:askForCardChosen(p, current, "hej", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, p:objectName())
							room:obtainCard(p, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
							room:broadcastSkillInvoke(self:objectName())
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
f_shenyuji:addSkill(f_yifa)

--

--神庞统
f_shenpangtong = sgs.General(extension_f, "f_shenpangtong", "god", 3, true)

f_fengchu = sgs.CreateTriggerSkill{
    name = "f_fengchu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local choices = {"1", "2", "3", "4"}
			local n = 0
			while n < 3 do
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice == "1" then
					room:gainMaxHp(player, 1, self:objectName())
					table.removeOne(choices, "1")
					if player:getState() ~= "online" then table.removeOne(choices, "2") end --为了AI，保证AI必选3和4
				elseif choice == "2" then
					room:recover(player, sgs.RecoverStruct(player))
					table.removeOne(choices, "2")
					if player:getState() ~= "online" then table.removeOne(choices, "1") end --为了AI，保证AI必选3和4
				elseif choice == "3" then
					room:drawCards(player, 2, self:objectName())
					table.removeOne(choices, "3")
				elseif choice == "4" then
					room:setPlayerFlag(player, "no_f_luofeng")
					table.removeOne(choices, "4")
				end
				n = n + 1
			end
			if player:hasFlag("f_fengchuOneTwoChoiced") then room:setPlayerFlag(player, "-f_fengchuOneTwoChoiced") end
		end
	end,
}
f_shenpangtong:addSkill(f_fengchu)

f_shenpanCard = sgs.CreateSkillCard{
	name = "f_shenpanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("f_shenpan-PlayClear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.to, "f_shenpan-PlayClear")
		if effect.to:getMark("f_shenpanOne") > 0 then
			room:askForDiscard(effect.to, "f_shenpan", 2, 2, false, true)
		end
		if effect.to:getMark("f_shenpanTwo") > 0 then
			room:damage(sgs.DamageStruct("f_shenpan", nil, effect.to))
		end
		if effect.to:getMark("f_shenpanThree") > 0 then
			room:loseHp(effect.to, 1)
		end
	end,
}
f_shenpanVS = sgs.CreateOneCardViewAsSkill{
	name = "f_shenpan",
	view_filter = function(self, to_select)
		return true
	end,
	view_as = function(self, card)
		local sp = f_shenpanCard:clone()
		sp:addSubcard(card)
		return sp
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and player:canDiscard(player, "he")
	end,
}
f_shenpan= sgs.CreateTriggerSkill{
    name = "f_shenpan",
	view_as_skill = f_shenpanVS,
	events = {sgs.CardsMoveOneTime, sgs.Damage, sgs.Death, sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local spt = room:findPlayerBySkillName("f_shenpan")
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if ((move.to and move.to:objectName() == player:objectName() and move.from and move.from:objectName() ~= move.to:objectName()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
			or (move.from and move.from:objectName() ~= player:objectName()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD))
			and player:getPhase() ~= sgs.Player_NotActive then
				if spt and player:getMark("&f_shenpanOne") == 0 then
					room:addPlayerMark(player, "&f_shenpanOne") --文字标记只是为了方便神庞统玩家看的，真正起作用的是隐藏标记
				end
				room:addPlayerMark(player, "f_shenpanOne")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive then
				if spt and player:getMark("&f_shenpanTwo") == 0 then
					room:addPlayerMark(player, "&f_shenpanTwo")
				end
				room:addPlayerMark(player, "f_shenpanTwo")
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from and death.who and death.damage.from:objectName() ~= death.who:objectName()
			and death.damage.from:getPhase() ~= sgs.Player_NotActive then
				if spt and death.damage.from:getMark("&f_shenpanThree") == 0 then
					room:addPlayerMark(death.damage.from, "&f_shenpanThree")
				end
				room:addPlayerMark(death.damage.from, "f_shenpanThree")
			end
		elseif event == sgs.TurnStart then
			room:setPlayerMark(player, "&f_shenpanOne", 0)
			room:setPlayerMark(player, "f_shenpanOne", 0)
			room:setPlayerMark(player, "&f_shenpanTwo", 0)
			room:setPlayerMark(player, "f_shenpanTwo", 0)
			room:setPlayerMark(player, "&f_shenpanThree", 0)
			room:setPlayerMark(player, "f_shenpanThree", 0)
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenpangtong:addSkill(f_shenpan)

f_luofeng = sgs.CreateTriggerSkill{
    name = "f_luofeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive or player:hasFlag("no_f_luofeng") then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName(), 1)
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|.|5"
		judge.good = false
		judge.play_animation = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
			room:broadcastSkillInvoke(self:objectName(), 2)
			
			if judge.card:objectName() == "dilu" then --彩蛋：正好判定出了的卢
				room:doLightbox("f_luofengAnimate")
			end
			
			room:loseHp(player, player:getHp())
			if not player:isAlive() then return false end
			if player:hasSkill("f_fengchu") then
				room:detachSkillFromPlayer(player, "f_fengchu")
			end
			if player:hasSkill(self:objectName()) then
				room:detachSkillFromPlayer(player, self:objectName())
			end
		end
	end,
}
f_shenpangtong:addSkill(f_luofeng)



--神蒲元
f_shenpuyuan = sgs.General(extension_f, "f_shenpuyuan", "god", 4, true) --初始；巨匠
f_shenpuyuanx = sgs.General(extension_f, "f_shenpuyuanx", "god", 4, true, true, true) --侠匠

f_tianciStart = sgs.CreateTriggerSkill{ --挑选幸运儿
    name = "#f_tianciStart",
	priority = 5,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local online = {} --登记“神蒲元”玩家
		local robots = {} --登记“神蒲元”AI
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if (p:getGeneralName() == "f_shenpuyuan" or p:getGeneral2Name() == "f_shenpuyuan") and p:hasSkill("f_tianci") then
				if p:getState() == "online" then
					table.insert(online, p)
				elseif p:getState() ~= "online" then
					table.insert(robots, p)
				end
			end
		end
		local xyr = nil
		if #online > 0 then
			xyr = online[math.random(1, #online)]
			room:addPlayerMark(xyr, "f_tianciStart")
		end
		if xyr == nil and #robots > 0 then
			xyr = robots[math.random(1, #robots)]
			room:addPlayerMark(xyr, "f_tianciStart")
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}

f_tianci = sgs.CreateTriggerSkill{
    name = "f_tianci",
	priority = 4,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("f_tianciStart") == 0 then return false end
			room:setPlayerMark(player, "f_tianciStart", 0)
			sgs.Sanguosha:playAudioEffect("audio/skill/f_tianciFate.ogg", false)
			room:doLightbox("$f_tianciFate") --触发命运
			local id = player:getDerivativeCard("_tianleiren", sgs.Player_PlaceHand)
			local choices = {}
			if player:hasEquipArea(0) then
				table.insert(choices, "XJ") --《侠匠之路》
			end
			table.insert(choices, "JJ") --《巨匠之路》
			local choice = room:askForChoice(player, "f_tianciFate", table.concat(choices, "+"))
			if choice == "XJ" then
				for _, tlr in sgs.qlist(player:getCards("he")) do
					if tlr:isKindOf("Tianleiren") then
						room:broadcastSkillInvoke(self:objectName(), 1)
						room:useCard(sgs.CardUseStruct(tlr, player, player)) --装备【天雷刃】
						break
					end
				end
				player:gainMark("&fXiaJiang", 1) --成为“侠匠”
				--更换头像
				local mhp = player:getMaxHp()
				local hp = player:getHp()
				if player:getGeneralName() == "f_shenpuyuan" then
					player:setAvatarIcon("f_shenpuyuanx")
					--room:changeHero(player, "f_shenpuyuanx", false, false, false, false)
				elseif player:getGeneral2Name() == "f_shenpuyuan" then
					player:setAvatarIcon("f_shenpuyuanx", true)
					--room:changeHero(player, "f_shenpuyuanx", false, false, true, false)
				end
				if player:getMaxHp() ~= mhp then room:setPlayerProperty(player, "maxhp", sgs.QVariant(mhp)) end
				if player:getHp() ~= hp then room:setPlayerProperty(player, "hp", sgs.QVariant(hp)) end
			elseif choice == "JJ" then
				for _, tlr in sgs.qlist(player:getCards("he")) do
					if tlr:isKindOf("Tianleiren") then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:throwCard(tlr, nil) --创造销毁的时机
						break
					end
				end
				player:gainMark("&fJuJiang", 1) --成为“巨匠”
				--建立“神兵库”
				local sbk = {"_hunduwanbi", "_shuibojian", "_liecuidao", "_hongduanqiang",
				"wushuangji", "god_blade", "god_sword", "_bintieshuangji", "wutiesuolian", "wuxinghelingshan",
				"shimandai", "baihuapao", "god_pao", "god_diagram", "huxinjing", "heiguangkai",
				"zijinguan", "god_hat", "tianjitu", "taigongyinfu", "_f_sanlve", "_f_zhaogujing"}
				local cds = sgs.IntList()
				for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					local sb = sgs.Sanguosha:getEngineCard(id)
					if table.contains(sbk, sb:objectName()) then
						cds:append(id)
						table.removeOne(sbk, sb:objectName())
					end
				end
				if not cds:isEmpty() then
					player:addToPile("spy_shenbingku", cds)
					local dummi = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					local random_get, n = {}, 2
					for _, ee in sgs.qlist(player:getPile("spy_shenbingku")) do
						local eqp = sgs.Sanguosha:getCard(ee)
						table.insert(random_get, eqp)
					end
					while n > 0 do
						local rgt = random_get[math.random(1, #random_get)]
						dummi:addSubcard(rgt:getEffectiveId())
						table.removeOne(random_get, rgt)
						n = n - 1
					end
					room:obtainCard(player, dummi)
					dummi:deleteLater()
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="BreakCard"
			and move.from:objectName()==player:objectName() then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceEquip
					and sgs.Sanguosha:getCard(id):isKindOf("Tianleiren") then
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						room:breakCard(id,player)
                    end
                end
            end
		end
	end,
}
f_tianciATA = sgs.CreateTriggerSkill{
    name = "#f_tianciATA",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		local can_invoke = true
		for _, c in sgs.qlist(player:getCards("he")) do
			if c:isKindOf("Tianleiren") then
				can_invoke = false
			end
		end
		if can_invoke then --检测到玩家已没有【天雷刃】，重新给予
			local id = player:getDerivativeCard("_tianleiren", sgs.Player_PlaceHand)
			room:sendCompulsoryTriggerLog(player, "f_tianci")
			room:broadcastSkillInvoke("f_tianci")
		end
	end,
	can_trigger = function(self, player)
		return player and player:getMark("&fXiaJiang") > 0
	end,
}
f_shenpuyuan:addSkill(f_tianci)
f_shenpuyuan:addSkill(f_tianciStart)
f_shenpuyuan:addSkill(f_tianciATA)
extension_f:insertRelatedSkills("f_tianci", "#f_tianciStart")
extension_f:insertRelatedSkills("f_tianci", "#f_tianciATA")
f_shenpuyuan:addRelateSkill("spy_shenbingku")

--



--==【“神兵库”】==--
spy_shenbingku = sgs.CreateTriggerSkill{
	name = "spy_shenbingku",
	priority = 22,
	frequency = sgs.Skill_NotFrequent,
	events = {},
	on_trigger = function()
	end,
}
if not sgs.Sanguosha:getSkill("spy_shenbingku") then skills:append(spy_shenbingku) end
--==[[武器]]==--
--1.混毒弯匕(已有)
----
--2.水波剑(已有)
----
--3.烈淬刀(已有)
----
--4.红锻枪(已有)
----
--5.无双方天戟(已有)

--6.鬼龙斩月刀(已有)

--7.赤血青锋(已有)

--8.镔铁双戟(已有)

----------
--==[[防具]]==--
--9.乌铁锁链(已有)
----
--10.五行鹤翎扇(已有)
----
--11.玲珑狮蛮带(已有)

--12.红棉百花袍(已有)

--13.国风玉袍(已有)

--14.奇门八阵(已有)

------
--==[[宝物]]==--
--15.护心镜(已有)
----
--16.黑光铠(已有)
----
--17.束发紫金冠(已有)

--18.虚妄之冕(已有)

--19.天机图(已有)
----
--20.太公阴符(已有)
----
--21.三略
Fsanlves = sgs.CreateTargetModSkill{
	name = "Fsanlve",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:getTreasure() ~= nil and player:getTreasure():isKindOf("Fsanlve") then
		    return 1
		else
		    return 0
		end
	end,
}
Fsanlvex = sgs.CreateMaxCardsSkill{
	name = "Fsanlvex",
	extra_func = function(self, player)
		if player:getTreasure() ~= nil and player:getTreasure():isKindOf("Fsanlve") then
			return 1
		else
			return 0
		end
	end,
}
Fsanlvey = sgs.CreateTargetModSkill{
	name = "Fsanlvey",
	residue_func = function(self, player)
		if player:getTreasure() ~= nil and player:getTreasure():isKindOf("Fsanlve") and player:getPhase() == sgs.Player_Play then
			return 1
		else
			return 0
		end
	end,
}
Fsanlve = sgs.CreateTreasure{
	name = "_f_sanlve",
	class_name = "Fsanlve",
	subtype = "JJ_shenbingku",
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, Fsanlves, false, true, false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "Fsanlve", true, true)
	end,
}
Fsanlve:clone(sgs.Card_Spade, 5):setParent(newgodsCard)
if not sgs.Sanguosha:getSkill("Fsanlve") then skills:append(Fsanlves) end
if not sgs.Sanguosha:getSkill("Fsanlvex") then skills:append(Fsanlvex) end
if not sgs.Sanguosha:getSkill("Fsanlvey") then skills:append(Fsanlvey) end
--22.照骨镜
FzhaogujingsCard = sgs.CreateSkillCard{
	name = "Fzhaogujing",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		for _, id in sgs.list(self:getSubcards()) do
		    room:showCard(source, id)
		end
		local ZGJ_toUse = sgs.Sanguosha:getCard(self:getSubcards():first())
		if ZGJ_toUse:isKindOf("Jink") or ZGJ_toUse:isKindOf("Nullification")
		or ZGJ_toUse:isKindOf("JlWuxiesy") then return false end --这几个硬要使用等的就是闪退
		local pattern = {}
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not sgs.Sanguosha:isProhibited(source, p, ZGJ_toUse) and ZGJ_toUse:isAvailable(source) then
				table.insert(pattern, ZGJ_toUse:getEffectiveId())
			end
		end
		if #pattern > 0 then
			sgs.Sanguosha:playAudioEffect("audio/equip/eight_diagram.ogg", false)
			room:setEmotion(source, "_f_zhaogujing")
			room:askForUseCard(source, table.concat(pattern, ","), "@Fzhaogujing_use:"..ZGJ_toUse:objectName(), -1)
		end
	end,
}
FzhaogujingsVS = sgs.CreateOneCardViewAsSkill{
	name = "Fzhaogujing",
	view_filter = function(self, to_select)
		return (to_select:isKindOf("BasicCard") or to_select:isNDTrick()) and not to_select:isEquipped()
	end,
	view_as = function(self, card)
	    local zgj_card = FzhaogujingsCard:clone()
		zgj_card:addSubcard(card:getId())
		return zgj_card
	end,
	response_pattern = "@@Fzhaogujing",
}
Fzhaogujings = sgs.CreateTriggerSkill{
	name = "Fzhaogujing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	view_as_skill = FzhaogujingsVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "@@Fzhaogujing", "@Fzhaogujing-showcard")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:getTreasure() and player:getTreasure():isKindOf("Fzhaogujing")
	end,
}
Fzhaogujing = sgs.CreateTreasure{
	name = "_f_zhaogujing",
	class_name = "Fzhaogujing",
	subtype = "JJ_shenbingku",
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, Fzhaogujings, false, true, false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "Fzhaogujing", true, true)
	end,
}
Fzhaogujing:clone(sgs.Card_Diamond, 1):setParent(newgodsCard)
if not sgs.Sanguosha:getSkill("Fzhaogujing") then skills:append(Fzhaogujings) end
------
--================--

mini_f_qigongCard = sgs.CreateSkillCard{
	name = "mini_f_qigongCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("f_qigong")
		local n, success, fail = 2, 0, 0 --2*(0+1)=2
		room:getThread():delay(1000)
		while n > 0 do
			local ids = room:getNCards(1)
			room:fillAG(ids)
			room:getThread():delay(1000)
			local id = ids:first()
			local card = sgs.Sanguosha:getCard(id)
			room:setTag("f_qigong", ToData(card))
			if card:isKindOf("EquipCard") then
				success = success + 1
				local to = room:askForPlayerChosen(source, room:getAllPlayers(), "f_qigong", "f_qigongUse:" .. card:objectName())
				local equip_index = card:getRealCard():toEquipCard():location()
				if to:hasEquipArea(equip_index) then
					room:useCard(sgs.CardUseStruct(card, to, to))
				else
					room:obtainCard(to, card)
				end
			else
				fail = fail + 1
				source:addToPile("f_YT", id)
			end
			room:removeTag("f_qigong")
			room:clearAG()
			n = n - 1
		end
		if success > fail then
		else
			room:addPlayerMark(source, "f_qigong-PlayClear")
		end
	end,
}
pro_f_qigongCard = sgs.CreateSkillCard{
	name = "pro_f_qigongCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("f_qigong")
		local m = self:subcardsLength()
		local n, success, fail = 2*(m+1), 0, 0
		room:getThread():delay(1000)
		while n > 0 do
			local ids = room:getNCards(1)
			room:fillAG(ids)
			room:getThread():delay(1000)
			local id = ids:first()
			local card = sgs.Sanguosha:getCard(id)
			room:setTag("f_qigong", ToData(card))
			if card:isKindOf("EquipCard") then
				success = success + 1
				local to = room:askForPlayerChosen(source, room:getAllPlayers(), "f_qigong", "f_qigongUse:" .. card:objectName())
				local equip_index = card:getRealCard():toEquipCard():location()
				if to:hasEquipArea(equip_index) then
					room:useCard(sgs.CardUseStruct(card, to, to))
				else
					room:obtainCard(to, card)
				end
			else
				fail = fail + 1
				source:addToPile("f_YT", id)
			end
			room:removeTag("f_qigong")
			room:clearAG()
			n = n - 1
		end
		if success > fail then
		else
			room:addPlayerMark(source, "f_qigong-PlayClear")
		end
	end,
}
f_qigong = sgs.CreateViewAsSkill{
	name = "f_qigong",
	n = 5,--n = 999,
	view_filter = function(self, selected, to_select)
		if #selected >= 0 then
			return to_select:isEquipped()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return mini_f_qigongCard:clone()
		end
		--
		if #cards >= 1 and #cards <= 5 then
			local qg_card = pro_f_qigongCard:clone()
			for _, card in ipairs(cards) do
				qg_card:addSubcard(card)
			end
			return qg_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("f_qigong-PlayClear") == 0
	end,
}
f_shenpuyuan:addSkill(f_qigong)


f_lingqiVS = sgs.CreateOneCardViewAsSkill{
	name = "f_lingqi",
	mute = true,
	view_filter = function(self, card)
		if not card:isKindOf("EquipCard") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = nil
			if sgs.Self:getMark("&fXiaJiang") > 0 then --侠匠
				local suit = card:getSuit()
				if suit == sgs.Card_Spade then --“毒杀”
					slash = sgs.Sanguosha:cloneCard("slash"--[["poison_slash"]], sgs.Card_SuitToBeDecided, -1)
				elseif suit == sgs.Card_Club then --冰杀
					slash = sgs.Sanguosha:cloneCard("ice_slash", sgs.Card_SuitToBeDecided, -1)
				elseif suit == sgs.Card_Diamond then --雷杀
					slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
				elseif suit == sgs.Card_Heart then --火杀
					slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
				else
					return false --防无花色gank
				end
			elseif sgs.Self:getMark("&fJuJiang") > 0 then --巨匠
				slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			end
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = nil
		if sgs.Self:getMark("&fXiaJiang") > 0 then --侠匠
			local suit = card:getSuit()
			if suit == sgs.Card_Spade then --“毒杀”
				slash = sgs.Sanguosha:cloneCard("slash"--[["poison_slash"]], card:getSuit(), card:getNumber())
				slash:setSkillName("f_lingqix_poison")
			elseif suit == sgs.Card_Club then --冰杀
				slash = sgs.Sanguosha:cloneCard("ice_slash", card:getSuit(), card:getNumber())
				slash:setSkillName("f_lingqix")
			elseif suit == sgs.Card_Diamond then --雷杀
				slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
				slash:setSkillName("f_lingqix")
			elseif suit == sgs.Card_Heart then --火杀
				slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
				slash:setSkillName("f_lingqix")
			else
				return nil --防无花色gank
			end
		elseif sgs.Self:getMark("&fJuJiang") > 0 then --巨匠
			slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:setSkillName("f_lingqij")
		end
		if slash ~= nil then
			slash:addSubcard(card:getId())
			return slash
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and (player:getMark("&fXiaJiang") > 0 or player:getMark("&fJuJiang") > 0)
	end,
}
f_lingqi = sgs.CreateTriggerSkill{
	name = "f_lingqi",
	view_as_skill = f_lingqiVS,
	events = {sgs.PreCardUsed, sgs.CardUsed, sgs.DamageInflicted, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local damage = data:toDamage()
		if event == sgs.PreCardUsed then
			if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
				if use.card:getSkillName() == "f_lingqix" then
					room:broadcastSkillInvoke("f_lingqi", 1)
				elseif use.card:getSkillName() == "f_lingqix_poison" then
					room:broadcastSkillInvoke("f_lingqi", 1)
					room:setEmotion(player, "zhen_analeptic")
					room:setEmotion(player, "poison_slash")
				elseif use.card:getSkillName() == "f_lingqij" then
					room:broadcastSkillInvoke("f_lingqi", 2)
				end
			end
		elseif event == sgs.CardUsed then
			if use.card:isKindOf("Slash") and use.card:getSkillName() == "f_lingqij" then
				room:setCardFlag(use.card, "SlashIgnoreArmor")
			end
		elseif event == sgs.DamageInflicted then --转化为毒属性伤害
			if damage.card and damage.card:objectName() == "slash" and (damage.card:getSkillName() == "f_lingqix_poison" or damage.card:hasFlag("poison_slash")) then
				damage.nature = sgs.DamageStruct_Poison
				data:setValue(damage)
			end
		elseif event == sgs.Damage then --“毒杀”效果
			if damage.card and damage.card:objectName() == "slash" and (damage.card:getSkillName() == "f_lingqix_poison" or damage.card:hasFlag("poison_slash")) then
				local lhp = damage.to:getLostHp()
				local n = lhp*0.2
				if lhp >= 5 or (lhp < 5 and math.random() <= n) then --5*20%=100%
					if damage.to:isMale() then sgs.Sanguosha:playAudioEffect("audio/system/poison_injure1.ogg", false)
					elseif damage.to:isFemale() then sgs.Sanguosha:playAudioEffect("audio/system/poison_injure2.ogg", false)
					end
					room:loseHp(damage.to, 1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_lingqi_buff= sgs.CreateTargetModSkill{
    name = "#f_lingqi_buff",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
	    if card:getSkillName() == "f_lingqix" or card:getSkillName() == "f_lingqix_poison" then
			return 1000
		else
			return 0
		end
	end,
}
f_shenpuyuan:addSkill(f_lingqi)
f_shenpuyuan:addSkill(f_lingqi_buff)
extension_f:insertRelatedSkills("f_lingqi", "#f_lingqi_buff")

f_shenjiangSBKCard = sgs.CreateSkillCard{
    name = "f_shenjiangSBKCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local SB = sgs.Sanguosha:getCard(self:getSubcards():first())
		local sb_id = self:getSubcards():first()
		local log = sgs.LogMessage()
		log.type = "$f_shenjiangSBK"
		log.from = source
		log.card_str = SB:toString()
		room:sendLog(log)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("f_shenjiangTarget") then
				room:obtainCard(p, SB)
				local pattern = {}
				for _, q in sgs.qlist(room:getOtherPlayers(p)) do
					if not sgs.Sanguosha:isProhibited(p, q, SB) and SB:isAvailable(p) then
						table.insert(pattern, sb_id)
					end
				end
				if #pattern > 0 then
					room:askForUseCard(p, table.concat(pattern, ","), "@f_shenjiangSBK_use:"..SB:objectName(), -1)
				end
				break
			end
		end
	end,
}
f_shenjiangCard = sgs.CreateSkillCard{
    name = "f_shenjiangCard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		if effect.from:getMark("&fXiaJiang") > 0 then
			local rcard = room:askForCard(effect.from, ".!", "@f_shenjiangRecast", sgs.QVariant(), sgs.Card_MethodRecast)
			if rcard then
				--room:showcard(effect.from, rcard:getId())
				room:moveCardTo(rcard, effect.from, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, effect.from:objectName(), "f_shenjiang", ""))
				local log = sgs.LogMessage()
				log.type = "#UseCard_Recast"
				log.from = effect.from
				log.card_str = rcard:toString()
				room:sendLog(log)
				effect.from:drawCards(1, "recast")
				local suit = rcard:getSuit()
				if suit == sgs.Card_Spade then --混毒弯匕
					room:addPlayerMark(effect.to, "&f_shenjiang:+_hunduwanbi-SelfClear")
				elseif suit == sgs.Card_Club then --水波剑
					room:addPlayerMark(effect.to, "&f_shenjiang:+_shuibojian-SelfClear")
				elseif suit == sgs.Card_Diamond then --烈淬刀
					room:addPlayerMark(effect.to, "&f_shenjiang:+_liecuidao-SelfClear")
				elseif suit == sgs.Card_Heart then --红锻枪
					room:addPlayerMark(effect.to, "&f_shenjiang:+_hongduanqiang-SelfClear")
				else
					return false
				end
				if not effect.to:hasSkill("f_shenjiangVAE") then
					room:acquireSkill(effect.to, "f_shenjiangVAE", false)
				end
			end
		elseif effect.from:getMark("&fJuJiang") > 0 then
			room:setPlayerFlag(effect.to, "f_shenjiangTarget") --锁定目标
			room:askForUseCard(effect.from, "@@f_shenjiangSBK!", "@f_shenjiangSBK") --从“神兵库”掏出大宝贝
			room:setPlayerFlag(effect.to, "-f_shenjiangTarget")
		end
	end,
}
f_shenjiangVS = sgs.CreateViewAsSkill{
    name = "f_shenjiang",
    n = 4,
	expand_pile = "f_YT,spy_shenbingku",
	view_filter = function(self, selected, to_select)
		if string.startsWith(pattern, "@@f_shenjiangSBK") then
			return sgs.Self:getPile("spy_shenbingku"):contains(to_select:getId())
		end
	    return sgs.Self:getPile("f_YT"):contains(to_select:getId())
	end,
    view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if string.startsWith(pattern, "@@f_shenjiangSBK") then
			if #cards == 1 then
				local sbk_equip = f_shenjiangSBKCard:clone()
				for _, card in ipairs(cards) do
					sbk_equip:addSubcard(card)
				end
				return sbk_equip
			end
		end
	    if #cards == 4 then
			local c = f_shenjiangCard:clone()
			for _, card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end,
	enabled_at_play = function(self, player)
	    return player:getPile("f_YT"):length() >= 4 and ((player:getMark("&fXiaJiang") > 0 and not player:isKongcheng()) --要保证能重铸
		or (player:getMark("&fJuJiang") > 0 and player:getPile("spy_shenbingku"):length() > 0)) --神兵库都没装备了还发动个锤子
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@f_shenjiangSBK")
	end,
}
f_shenjiang = sgs.CreateTriggerSkill{
	name = "f_shenjiang",
	view_as_skill = f_shenjiangVS,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "f_shenjiang" and use.from:objectName() == player:objectName() then
				if player:getMark("&fXiaJiang") > 0 then
					room:broadcastSkillInvoke("f_shenjiang", 1)
				elseif player:getMark("&fJuJiang") > 0 then
					room:broadcastSkillInvoke("f_shenjiang", 2)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenjiangVAE = sgs.CreateViewAsEquipSkill{
	name = "f_shenjiangVAE&",
	view_as_equip = function(self, player)
		if player:getMark("&f_shenjiang:+_hunduwanbi-SelfClear") > 0 then
			return "_hunduwanbi"
		elseif player:getMark("&f_shenjiang:+_shuibojian-SelfClear") > 0 then
			return "_shuibojian"
		elseif player:getMark("&f_shenjiang:+_liecuidao-SelfClear") > 0 then
			return "_liecuidao"
		elseif player:getMark("&f_shenjiang:+_hongduanqiang-SelfClear") > 0 then
			return "_hongduanqiang"
		else
			return ""
		end
	end,
}


f_shenpuyuan:addSkill(f_shenjiang)

if not sgs.Sanguosha:getSkill("f_shenjiangVAE") then skills:append(f_shenjiangVAE) end


--神马钧
f_shenmajun = sgs.General(extension_f, "f_shenmajun", "god", 3, true, false, false, 3, 1)

addhiddenCard = sgs.Package("addhiddenCard", sgs.Package_CardPack)
f_yanfa = sgs.CreateTriggerSkill{ --“研发”被分为两部分：一部分是神马钧的技能，另一部分则是“加入隐藏卡牌”功能的实现
	name = "f_yanfa",
	priority = 15000,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.DrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart or event == sgs.DrawNCards then
			--统计隐藏卡牌（后续还会视情况扩增）
			local hidden_cards = {"_qizhengxiangsheng", "_hunduwanbi", "_shuibojian", "_liecuidao", "_hongduanqiang", "_tianleiren",
			"_piliche", "_secondpiliche", "_tenyearpiliche", "_feilunzhanyu", "_sichengliangyu", "_tiejixuanyu", --"_jinshu", "_qiongshu", "_xishu",
			-- "_ol_sanshou", "_fcmk_ol_sizhaojian", "_maki_yuanjiaojingong", "_fcmk_ol_changandajian_weapon",遠交近攻 三首 長安大艦 "_fcmk_ol_changandajian_armor",
			-- "_fcmk_ol_changandajian_defen", "_fcmk_ol_changandajian_offen", "_fcmk_ol_changandajian_treasure",
			--
			--"_f_shufazijinguan", "_f_xuwangzhimian", "_onl_wuqibingfa",
			"zijinguan","god_hat", "_wuqibingfa",
			"god_ship",
			"_f_sanlve", "_f_zhaogujing", "_wuqibingfa",

			--"_f_goldenchelsea", , "_sd_chao",
			--"_yrjxn", "_xtbgz", "_rwjgd", "_zyszk", "_tybrj", "_tpys_nhlx",
			"_f_chixieren", "_f_morigong",
			"_fcjhq_weapon", "_fcjhq_armor", "_fcjhq_dfhorse", "_fcjhq_ofhorse", "_fcjhq_treasure",
			"ddz_jingubang",
			"_ov_lingbaoxianhu", "_ov_taijifuchen", "_ov_chongyingshenfu", "_ov_tiaojiyanmei", "_ov_binglinchengxia", "_ov_mantianguohai",
			
			-- "_wm_jugongjincui", "_wm_chushibiao", "_wm_bazhentu", "_wm_kongmingdeng", "_wm_huoshou", "_wm_qixingdeng", 
			"_ny_tenth_shuiyanqijun",
			"taipingyaoshu", "_kecheng_tuixinzhifu", "_kecheng_chenhuodajie", "_kecheng_stabs_slash", "_kezhuan_chixueqingfeng", "_kehe_jiejiaguitian",
			-- "_maki_stabs_slash", "_maki_tiaojiyanmei", "_small_joker", "_big_joker",
			"_lxtx_feilongduofeng",
			"_keolsizhaojian",
			"wushuangji", "god_blade", "god_sword", "_bintieshuangji",
			"shimandai", "baihuapao", "god_pao", "god_diagram",
			"zijinguan", "god_hat"
			}
			if event == sgs.GameStart and player:hasSkill(self:objectName()) then
				local hc_data = player:property("SkillDescriptionRecord_f_yanfa"):toString():split("+") --准备好储存隐藏卡牌信息的存档
				local cds = sgs.IntList()
				for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					local hc = sgs.Sanguosha:getEngineCard(id)
					if table.contains(hidden_cards, hc:objectName()) then
						cds:append(id)
						if not table.contains(hc_data, hc:objectName()) then
							table.insert(hc_data, hc:objectName())
						end
					end
				end
				if not cds:isEmpty() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doLightbox("f_yanfaAnimate")
					room:shuffleIntoDrawPile(player, cds, self:objectName(), false) --把这些牛鬼蛇神加入牌堆，群魔乱舞！
					room:setPlayerProperty(player, "SkillDescriptionRecord_f_yanfa", sgs.QVariant(table.concat(hc_data, "+")))
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do --把储存完毕的这份存档发送给全场角色，方便后续的“机神”宝物加成
						room:setPlayerProperty(p, "SkillDescriptionRecord_f_yanfa", sgs.QVariant(table.concat(hc_data, "+")))
					end
				end
			elseif event == sgs.DrawNCards and not table.contains(sgs.Sanguosha:getBanPackages(), "addhiddenCard") then
				local draw = data:toDraw()
				if draw.reason ~= "InitialHandCards" then return false end
				local cds = sgs.IntList()
				for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					local hc = sgs.Sanguosha:getEngineCard(id)
					if table.contains(hidden_cards, hc:objectName()) then
						cds:append(id)
					end
				end
				if not cds:isEmpty() then
					room:shuffleIntoDrawPile(player, cds, self:objectName(), false)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_RoundStart then
				local cds = {}
				local hc_data = player:property("SkillDescriptionRecord_f_yanfa"):toString():split("+")
				for _, c in sgs.qlist(room:getDrawPile()) do
					local cd = sgs.Sanguosha:getCard(c)
					if table.contains(hc_data, cd:objectName()) then
						table.insert(cds, cd)
					end
				end
				if #cds > 0 then
					local ran_cd = cds[math.random(1, #cds)]
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:obtainCard(player, ran_cd)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and (player:hasSkill(self:objectName()) or player:getSeat() == 1)
	end,
}
f_shenmajun:addSkill(f_yanfa)

f_jishenCard = sgs.CreateSkillCard{
	name = "f_jishenCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasEquipArea()
	end,
	on_use = function(self, room, source, targets)
		local jiangjun = targets[1]
		local choices = {}
		for i = 0, 4 do
			table.insert(choices, i)
		end
		local mhp = source:getMaxHp()
		if mhp > 5 then mhp = 5 end
		local n = 5 - mhp
		while n > 0 do
			local buzao = choices[math.random(1, #choices)]
			table.removeOne(choices, buzao)
			n = n - 1
		end
		local choice = room:askForChoice(source, "f_jishen", table.concat(choices, "+"))
		local area = tonumber(choice)
		local use_id = -1
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") and card:getRealCard():toEquipCard():location() == area then
				use_id = id
				break
			end
		end
		--使用装备
		if use_id >= 0 then
			local use_card = sgs.Sanguosha:getCard(use_id)
			if jiangjun:isAlive() and jiangjun:canUse(use_card, jiangjun, true) then
				room:useCard(sgs.CardUseStruct(use_card, jiangjun, jiangjun))
			end
		end
		--附以加成
		if area == 0 then --武器加伤
			room:addPlayerMark(jiangjun, "&f_jishen+jsweapon-SelfClear")
		elseif area == 1 then --防具减伤
			room:addPlayerMark(jiangjun, "&f_jishen+jsarmor-SelfClear")
		elseif area == 2 then -- +1马增回
			room:addPlayerMark(jiangjun, "&f_jishen+jsdefen-SelfClear")
		elseif area == 3 then -- -1马减距
			room:addPlayerMark(jiangjun, "&f_jishen+jsoffen-SelfClear")
		elseif area == 4 then --宝物摸牌
			room:addPlayerMark(jiangjun, "&f_jishen+jstrsr-SelfClear")
		end
	end,
}
f_jishenVS = sgs.CreateZeroCardViewAsSkill{
	name = "f_jishen",
	view_as = function()
		return f_jishenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_jishenCard")
	end,
}
f_jishen = sgs.CreateTriggerSkill{
	name = "f_jishen",
	view_as_skill = f_jishenVS,
	events = {sgs.ConfirmDamage, sgs.DamageInflicted, sgs.PreHpRecover, sgs.TargetSpecified, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage, recover, use = data:toDamage(), data:toRecover(), data:toCardUse()
		local smj = room:findPlayerBySkillName("f_jishen")
		if event == sgs.ConfirmDamage then
			if damage.from:objectName() == player:objectName() and player:getMark("&f_jishen+jsweapon-SelfClear") > 0
			and damage.card and not damage.card:isVirtualCard() then
				if smj then room:sendCompulsoryTriggerLog(smj, "f_jishen") end
				room:broadcastSkillInvoke("f_jishen")
				damage.damage = damage.damage*2
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted then
			if damage.to:objectName() == player:objectName() and player:getMark("&f_jishen+jsarmor-SelfClear") > 0
			and not (damage.card and not damage.card:isVirtualCard()) then
				if smj then room:sendCompulsoryTriggerLog(smj, "f_jishen") end
				room:broadcastSkillInvoke("f_jishen")
				damage.damage = damage.damage/2
				damage.prevented = true
				data:setValue(damage)
				if damage.damage < 1 then return true end
			end
		elseif event == sgs.PreHpRecover then
			if recover.who:objectName() == player:objectName() and player:getMark("&f_jishen+jsdefen-SelfClear") > 0 then
				if smj then room:sendCompulsoryTriggerLog(smj, "f_jishen") end
				room:broadcastSkillInvoke("f_jishen")
				recover.recover = recover.recover*2
				data:setValue(recover)
			end
		elseif event == sgs.TargetSpecified then
			if use.from:objectName() == player:objectName() and player:getMark("&f_jishen+jsoffen-SelfClear") > 0
			and use.card and not use.card:isKindOf("SkillCard") then
				if smj then room:sendCompulsoryTriggerLog(smj, "f_jishen") end
				room:broadcastSkillInvoke("f_jishen")
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(use.to) do
					if player:distanceTo(p) == 1 then
						table.insert(no_respond_list, p:objectName())
					end
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		elseif event == sgs.CardUsed then
			local hc_data = player:property("SkillDescriptionRecord_f_yanfa"):toString():split("+")
			if use.from:objectName() == player:objectName() and player:getMark("&f_jishen+jstrsr-SelfClear") > 0
			and use.card and table.contains(hc_data, use.card:objectName()) then
				if smj then room:sendCompulsoryTriggerLog(smj, "f_jishen") end
				room:broadcastSkillInvoke("f_jishen")
				room:drawCards(player, 1, "f_jishen")
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_jishenOF = sgs.CreateDistanceSkill{
	name = "f_jishenOF",
	correct_func = function(self, from)
		if from:getMark("&f_jishen+jsoffen-SelfClear") > 0 then
			local d = from:getEquips():length()
			if d > 0 then
				return -(d+1)/2
			else
				return 0
			end
		else
			return 0	
		end
	end,
}
f_shenmajun:addSkill(f_jishen)
if not sgs.Sanguosha:getSkill("f_jishenOF") then skills:append(f_jishenOF) end

--

--神司马炎(正式版)
f_shensimayan_f = sgs.General(extension_f, "f_shensimayan_f", "god", 4, true)

f_zhengmie_f = sgs.CreateTriggerSkill{
	name = "f_zhengmie_f",
	--global = true,
	priority = {-3, -3, -3, -3},
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			local phase = player:getPhase()
			if phase ~= sgs.Player_Start then return false end
			for _, smy in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if smy:getMark("&f_zhengmie_f_lun") >= 3 then continue end
				room:setPlayerFlag(player, "f_zhengmie_fTarget")
				local zmto = room:askForPlayerChosen(smy, room:getOtherPlayers(player), self:objectName(), "f_zhengmie_f-invoke:" .. player:objectName(), true, true) --默认不杀自己，总不能讨伐自己吧
				room:setPlayerFlag(player, "-f_zhengmie_fTarget")
				if zmto then
					--播放文字语音
					if math.random() <= 0.5 then room:doLightbox("$f_zhengmie1")
					else room:doLightbox("$f_zhengmie2") end
					--
					room:addPlayerMark(smy, "&f_zhengmie_f_lun")
					room:setPlayerFlag(smy, "f_zhengmie_fSource")
					if not player:hasFlag("f_zhengmie_fTarget") then room:setPlayerFlag(player, "f_zhengmie_fTarget") end
					if player:canSlash(zmto, nil, false) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName(self:objectName())
						room:setPlayerFlag(player, "ZenhuiUser_" .. slash:toString())
						slash:deleteLater()
						room:useCard(sgs.CardUseStruct(slash, player, zmto), false)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and player:hasFlag("f_zhengmie_fTarget") then
				room:setPlayerFlag(player, "-f_zhengmie_fTarget")
				for _, zmf in sgs.qlist(room:getAllPlayers()) do
					if zmf:hasFlag("f_zhengmie_fSource") then
						room:setPlayerFlag(zmf, "-f_zhengmie_fSource")
						if zmf:hasSkill(self:objectName()) then
							room:sendCompulsoryTriggerLog(zmf, self:objectName())
							if math.random() <= 0.5 then room:doLightbox("$f_zhengmie1")
							else room:doLightbox("$f_zhengmie2") end
							room:drawCards(zmf, 1, self:objectName())
							zmf:gainMark("&fZHENGf", 1)
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

f_diyun = sgs.CreateTriggerSkill{
	name = "f_diyun",
	priority = -4,
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseProceeding},
	waked_skills = "dy_shemi,f_shensimayan_sktc",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&fZHENG") < 3 and player:getMark("&fZHENGf") < 3 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if math.random() <= 0.5 then room:doLightbox("$f_diyun1")
		else room:doLightbox("$f_diyun2") end
		room:doSuperLightbox("f_shensimayan", self:objectName())
		room:loseMaxHp(player, 1)
		room:addPlayerMark(player, self:objectName())
		room:addPlayerMark(player, "@waked")
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "rec+drw") == "rec" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2, self:objectName())
			end
		else
			room:drawCards(player, 2, self:objectName())
		end
		if not player:hasSkill("dy_shemi") then
			room:acquireSkill(player, "dy_shemi")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
dy_shemi = sgs.CreateTriggerSkill{
	name = "dy_shemi",
	frequency = sgs.Skill_Frequent,--NotFrequent,
	events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				--if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
				local choices = {"1", "2", "cancel"}
				local n = 2
				while n > 0 do
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice == "cancel" then break end
					if choice == "1" then
						room:setPlayerFlag(player, "dy_shemi_draw")
						table.removeOne(choices, "1")
					elseif choice == "2" then
						room:addSlashMubiao(player, 1, true)
						room:addSlashCishu(player, 1, true)
						table.removeOne(choices, "2")
					end
					room:addMaxCards(player, -1, true)
					n = n - 1
				end
				if math.random() <= 0.5 then room:doLightbox("$dy_shemi1")
				else room:doLightbox("$dy_shemi2") end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("dy_shemi_draw") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				draw.num = draw.num + 2
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Finish then return false end
			if player:isKongcheng() and player:getEquips():length() > 0 and player:canDiscard(player, "e") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				if math.random() <= 0.5 then room:doLightbox("$dy_shemi1")
				else room:doLightbox("$dy_shemi2") end
				local yangche = room:askForCardChosen(player, player, "e", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(yangche, player, player)
			end
		end
	end,
}

f_shensimayan_sktc = sgs.CreateTriggerSkill{
	name = "f_shensimayan_sktc",
	frequency = sgs.Skill_Frequent,
	events = {},
	on_trigger = function(self, event, player, data)
	end,
}
f_shensimayan_f:addSkill(f_zhengmie_f)
f_shensimayan_f:addSkill(f_diyun)
if not sgs.Sanguosha:getSkill("dy_shemi") then skills:append(dy_shemi) end
if not sgs.Sanguosha:getSkill("f_shensimayan_sktc") then skills:append(f_shensimayan_sktc) end
f_shensimayan_f:addRelateSkill("f_shensimayan_sktc")



--神刘协
f_shenliuxie = sgs.General(extension_f, "f_shenliuxie", "god", 3, true)

f_skyssonCard = sgs.CreateSkillCard{
	name = "f_skyssonCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local hxds = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			hxds:append(p)
		end
		local from = room:askForPlayerChosen(source, hxds, "f_skysson_slash", "f_skysson-slashfrom")
		room:setPlayerFlag(from, "f_skysson_sf")
		local to
		for _, p in ipairs(targets) do
			if not p:hasFlag("f_skysson_sf") then
				to = p
			else
				room:setPlayerFlag(p, "-f_skysson_sf")
			end
		end
		local use_slash = room:askForUseSlashTo(from, to, "@f_skysson-slash:" .. to:objectName(), true)
		if not use_slash then
			local log = sgs.LogMessage()
			log.type = "$to_f_shenliuxie_fou"
			log.from = source
			log.to:append(from)
			room:sendLog(log)
			if source:canSlash(from, nil, false) then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("f_skysson")
				slash:deleteLater()
				room:useCard(sgs.CardUseStruct(slash, source, from))
			end
		end
	end,
}
f_skyssonVS = sgs.CreateOneCardViewAsSkill{
	name = "f_skysson",
	view_filter = function(self, to_select)
		return true
	end,
    view_as = function(self, cards)
		local ss_card = f_skyssonCard:clone()
		ss_card:addSubcard(cards)
		return ss_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#f_skyssonCard") and not player:isNude()
	end,
}
f_skysson = sgs.CreateTriggerSkill{
	name = "f_skysson",
	view_as_skill = f_skyssonVS,
	events = {sgs.CardAsked, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			local prompt = data:toStringList()[2]
			if pattern ~= "jink" or string.find(prompt, "@f_skysson-jink")
			or player:getMark(self:objectName().."-Clear") > 0 or not player:hasSkill("f_skysson") then return false end
			if not room:askForSkillInvoke(player, "f_skysson", data) then return false end
			room:broadcastSkillInvoke("f_skysson")
			room:addPlayerMark(player, self:objectName().."-Clear")
			local tohelp = sgs.QVariant()
			tohelp:setValue(player)
			local prompt = string.format("@f_skysson-jink:%s", player:objectName())
			local jw = room:askForPlayerChosen(player, room:getAllPlayers(), "f_skysson", "f_skysson-usejink")
			local jink = room:askForCard(jw, "jink", prompt, tohelp, sgs.Card_MethodResponse, player, false, "", true)
			if jink then
				room:provide(jink)
				return true
			else
				local log = sgs.LogMessage()
				log.type = "$to_f_shenliuxie_fou"
				log.from = player
				log.to:append(jw)
				room:sendLog(log)
				if not jw:isAllNude() then
					local card = room:askForCardChosen(player, jw, "hej", "f_skysson")
					room:obtainCard(player, card, false)
				end
			end
		end
	end,
}
f_shenliuxie:addSkill(f_skysson)

f_guozuo = sgs.CreateTriggerSkill{
	name = "f_guozuo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.MaxHpChange, sgs.Death, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				if player:hasJudgeArea() then
					player:throwJudgeArea()
				end
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			if player:hasSkill(self:objectName()) and not string.find(change.reason, "f_guozuo") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local can_invoke = true
			for _, sl in sgs.qlist(room:getAlivePlayers()) do
				if sl:getKingdom() == death.who:getKingdom() then
					can_invoke = false
				end
			end
			if can_invoke then
				if player:hasSkill(self:objectName()) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:gainMaxHp(player, 1, self:objectName())
					room:recover(player, sgs.RecoverStruct(player))
					room:addPlayerMark(player, "&f_guozuoDraw")
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
			if player:hasSkill(self:objectName()) and player:getMark("&f_guozuoDraw") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local n = player:getMark("&f_guozuoDraw")
				draw.num = draw.num + n
				data:setValue(draw)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenliuxie:addSkill(f_guozuo)

f_kuilei = sgs.CreateTriggerSkill{
	name = "f_kuilei",
	frequency = sgs.Skill_Limited,
	limit_mark = "@f_kuilei",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone, sgs.QuitDying},
	waked_skills = "tianming,mizhao",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if event == sgs.AskForPeaches then
			if dying.who:objectName() == player:objectName() and player:getMark("@f_kuilei") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:removePlayerMark(player, "@f_kuilei")
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("f_shenliuxie_kuilei", self:objectName())
					local bgx = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "f_kuilei_jieguo") --默认不能选自己，总不能自己挟自己吧
					local peach = room:askForCard(bgx, "peach", "@f_kuilei-peach:" .. player:objectName(), data, sgs.Card_MethodNone)
					if peach then
						room:useCard(sgs.CardUseStruct(peach, player, player))
						if not bgx:hasSkill("f_skysson") then
							room:acquireSkill(bgx, "f_skysson")
						end
						bgx:gainMark("&f_Xtz", 1)
						if player:isWounded() then
							local rec = player:getMaxHp() - player:getHp()
							room:recover(player, sgs.RecoverStruct(player, nil, rec))
						end
						if player:hasSkill("f_skysson") then
							room:detachSkillFromPlayer(player, "f_skysson")
						end
						if not player:hasSkill("tianming") then
							room:acquireSkill(player, "tianming")
						end
						if not player:hasSkill("mizhao") then
							room:acquireSkill(player, "mizhao")
						end
					else
						local log = sgs.LogMessage()
						log.type = "$to_f_shenliuxie_fou"
						log.from = player
						log.to:append(bgx)
						room:sendLog(log)
						if not bgx:isNude() then
							bgx:throwAllHandCardsAndEquips()
						end
						room:setPlayerFlag(player, "re_f_kuilei")
					end
				end
			end
		elseif event == sgs.QuitDying then
			if dying.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:hasFlag("re_f_kuilei") then
				room:setPlayerFlag(player, "-re_f_kuilei")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:setPlayerMark(player, "@f_kuilei", 1)
			end
			if player:hasFlag("re_f_kuilei") then room:setPlayerFlag(player, "-re_f_kuilei") end
		end
	end,
}
f_shenliuxie:addSkill(f_kuilei)

f_handi = sgs.CreateTriggerSkill{
	name = "f_handi",
	frequency = sgs.Skill_Wake,
	events = {sgs.Death},
	waked_skills = "luanji,tushe",
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if death.who:getMark("&f_Xtz") == 0 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("f_shenliuxie_handi", self:objectName())
		room:addPlayerMark(player, self:objectName())
		room:addPlayerMark(player, "@waked")
		if not player:hasSkill("f_skysson") then
			room:acquireSkill(player, "f_skysson")
		end
		if not player:hasSkill("luanji") then
			room:acquireSkill(player, "luanji")
		end
		if not player:hasSkill("tushe") then
			room:acquireSkill(player, "tushe")
		end
		if player:hasSkill("tianming") then
			room:detachSkillFromPlayer(player, "tianming")
		end
		if player:hasSkill("mizhao") then
			room:detachSkillFromPlayer(player, "mizhao")
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
f_shenliuxie:addSkill(f_handi)




--新神刘禅
f_shenliushan_new = sgs.General(extension_f, "f_shenliushan_new$", "god", 4, true)

f_shenliushan_new:addSkill("f_leji")
f_shenliushan_new:addSkill("f_wuyou")

f_dansha_new = sgs.CreateTriggerSkill{
    name = "f_dansha_new",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	waked_skills = "olsishu",
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local move = data:toMoveOneTime()
		if event == sgs.BeforeCardsMove then
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if player:containsTrick("indulgence") then
					room:addPlayerMark(player, self:objectName()) --“单杀”启动前置条件标记
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if not player:containsTrick("indulgence") and player:getMark(self:objectName()) > 0 then
					local smz = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "f_danshaSiMaZhao", true, true)
					if smz then
						room:broadcastSkillInvoke(self:objectName())
						local m = 1
						if player:isLord() then
							room:loseHp(smz, m*2)
							room:askForDiscard(smz, self:objectName(), m*2, m*2, false, true)
						else
							room:loseHp(smz, m)
							room:askForDiscard(smz, self:objectName(), m, m, false, true)
						end
						if not smz:isAlive() then
							--此间不乐，思蜀......
							if player:isLord() and not player:hasSkill("olsishu") then
								room:acquireSkill(player, "olsishu")
							end
							room:detachSkillFromPlayer(player, self:objectName())
						end
					end
				end
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,
}

f_shenliushan_new:addSkill(f_dansha_new)



--神-曹丕&甄姬
god_caopi_zhenji = sgs.General(extension_f, "god_caopi_zhenji", "god", 4)
god_caopi_zhenji:setGender(sgs.General_Neuter)
god_caopi_zhenji_m = sgs.General(extension_f, "god_caopi_zhenji_m", "god", 4, true, true, true)
god_caopi_zhenji_f = sgs.General(extension_f, "god_caopi_zhenji_f", "god", 4, false, true, true)
diy_k_luoshangCard = sgs.CreateSkillCard{
    name = "diy_k_luoshang",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    source:loseMark("&"..self:objectName(), 1)
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|black"
		judge.good = true
		judge.reason = self:objectName().."Card"
		judge.who = source
		judge.time_consuming = true
		room:judge(judge)
		room:obtainCard(source, judge.card, false)
		if judge:isBlack() then
			source:gainMark("&"..self:objectName(), 1)
		end
	end,
}
diy_k_luoshangvs = sgs.CreateViewAsSkill{
	name = "diy_k_luoshang",
	n = 0,
	view_as = function(self, cards)
		return diy_k_luoshangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&"..self:objectName()) > 0 and player:usedTimes("#diy_k_luoshang") < player:getMark("&"..self:objectName())
	end,
}
diy_k_luoshang = sgs.CreateTriggerSkill{
	name = "diy_k_luoshang",
	events = {sgs.Death, sgs.EventPhaseStart, sgs.PreCardUsed, sgs.GameStart, sgs.AskForRetrial},
	view_as_skill = diy_k_luoshangvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
			    local n = 0
			    if player:getGeneralName() == "god_caopi_zhenji_m" or player:getGeneral2Name() == "god_caopi_zhenji_m" then
				    n = 2
			    end
			    if player:getGeneralName() == "god_caopi_zhenji_f" or player:getGeneral2Name() == "god_caopi_zhenji_f" then
				    n = 4
			    end
				while room:askForSkillInvoke(player, self:objectName(), data) do
					room:broadcastSkillInvoke(self:objectName(), n)
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
			            return nil
					else
		                room:obtainCard(player, judge.card, false)
			            player:gainMark("&"..self:objectName(), 1)
					end
				end
			end
		elseif event == sgs.GameStart then
			if (player:getGeneralName() == "god_caopi_zhenji" or player:getGeneral2Name() == "god_caopi_zhenji") and player:hasSkill(self:objectName()) then
			    if room:askForChoice(player, "gcz_skinchange", "caopi+zhenji") == "caopi" then
				    if player:getGeneralName() == "god_caopi_zhenji" then
				        room:changeHero(player, "god_caopi_zhenji_m", false, false, false, true)
				    elseif player:getGeneral2Name() == "god_caopi_zhenji" then
				        room:changeHero(player, "god_caopi_zhenji_m", false, false, true, true)
					end
					room:sendCompulsoryTriggerLog(player, self:objectName())
		            room:broadcastSkillInvoke(self:objectName(), 2)
					player:gainMark("&"..self:objectName(), 3)
				else
				    if player:getGeneralName() == "god_caopi_zhenji" then
				        room:changeHero(player, "god_caopi_zhenji_f", false, false, false, true)
				    elseif player:getGeneral2Name() == "god_caopi_zhenji" then
				        room:changeHero(player, "god_caopi_zhenji_f", false, false, true, true)
					end
					room:sendCompulsoryTriggerLog(player, self:objectName())
		            room:broadcastSkillInvoke(self:objectName(), 4)
					player:gainMark("&"..self:objectName(), 3)
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			local n = 2
			if player:getGeneralName() == "god_caopi_zhenji_f" or player:getGeneral2Name() == "god_caopi_zhenji_f" then
				n = n + 2
			end
			if judge.reason == self:objectName() and player:getPhase() ~= sgs.Player_Play and judge.who:objectName() == player:objectName() and judge.card:isRed()
			and player:getMark("&"..self:objectName()) > 0 and player:hasSkill(self:objectName()) and player:askForSkillInvoke(self:objectName().."_judge", data) then
				room:broadcastSkillInvoke(self:objectName(), n)
				player:loseMark("&"..self:objectName(), 1)
				local card_id = room:drawCard()
			    room:getThread():delay()
			    local card = sgs.Sanguosha:getCard(card_id)
			    room:retrial(card, player, judge, self:objectName())
			end
		elseif event == sgs.Death then
		    local death = data:toDeath()
		    if death.who:objectName() == player:objectName() or death.who:isNude() or not player:isAlive() or not player:hasSkill(self:objectName()) then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local n = 2
			if player:getGeneralName() == "god_caopi_zhenji_f" or player:getGeneral2Name() == "god_caopi_zhenji_f" then
				n = n + 2
			end
			room:broadcastSkillInvoke(self:objectName(), n)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local dummi = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			local cards = death.who:getCards("he")
			for _, card in sgs.qlist(cards) do
				dummy:addSubcard(card)
				if card:isBlack() then
				    dummi:addSubcard(card)
				end
			end
			if cards:length() > 0 then
				room:obtainCard(player, dummy, false)
				if dummi:getSubcards():length() > 0 and room:askForChoice(player, "gcz_throwBlack", "yes+no") == "yes" then
					room:throwCard(dummi, player, nil)
					local d = dummi:getSubcards():length()
					player:gainMark("&"..self:objectName(), d)
				end
			end
			dummy:deleteLater()
			dummi:deleteLater()
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			judge.time_consuming = true
			room:judge(judge)
			if judge:isBad() then
			    return nil
			else
		        room:obtainCard(player, judge.card, false)
			    player:gainMark("&"..self:objectName(), 1)
			end
		else
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n = 0
				if use.from:getGeneralName() == "god_caopi_zhenji_m" or use.from:getGeneral2Name() == "god_caopi_zhenji_m" then
				    n = 1
				end
				if use.from:getGeneralName() == "god_caopi_zhenji_f" or use.from:getGeneral2Name() == "god_caopi_zhenji_f" then
				    n = 3
				end
				if skill == self:objectName() and use.from:hasSkill(self:objectName()) then
					room:broadcastSkillInvoke(self:objectName(), n)
					return true
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
god_caopi_zhenji:addSkill(diy_k_luoshang)
god_caopi_zhenji_m:addSkill("diy_k_luoshang")
god_caopi_zhenji_f:addSkill("diy_k_luoshang")


--神袁绍
f_shenyuanshao = sgs.General(extension_f, "f_shenyuanshao", "god", 4, true)

f_mingwang = sgs.CreateTriggerSkill{
	name = "f_mingwang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.DrawNCards, sgs.EventPhaseEnd, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local choices = {}
				table.insert(choices, "1")
				if player:getCards("he"):length() >= 2 and player:canDiscard(player, "he") then
					table.insert(choices, "2")
				end
				local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
				if choice == "1" then
					room:drawCards(p, 2, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					p:gainMark("&f_ysS", 1)
				elseif choice == "2" then
					room:askForDiscard(p, self:objectName(), 2, 2, false, true)
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
			local count = 1
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&f_ysS") > 0 then
					count = count + 1
				end
			end
			draw.num = count
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 2)
			data:setValue(draw)
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and player:getHandcardNum() > player:getHp() then
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
			and damage.to and damage.to:getMark("&f_ysS") == 0 then
				local log = sgs.LogMessage()
				log.type = "$f_mingwangMD"
				log.from = player
				log.to:append(damage.to)
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
}
f_mingwangMaxCards = sgs.CreateMaxCardsSkill{
	name = "#f_mingwangMaxCards",
	extra_func = function(self, player)
		local n = 0
		if player:hasSkill("f_mingwang") then
			if player:getMark("&f_ysS") > 0 then n = n + 1 end
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:getMark("&f_ysS") > 0 then
					n = n + 1
				end
			end
		end
		return n
	end,
}
f_shenyuanshao:addSkill(f_mingwang)
f_shenyuanshao:addSkill(f_mingwangMaxCards)
extension_f:insertRelatedSkills("f_mingwang", "#f_mingwangMaxCards")

f_guamou = sgs.CreateTriggerSkill{
    name = "f_guamou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (not use.card:isKindOf("BasicCard") and not use.card:isNDTrick()) or use.from:objectName() ~= player:objectName() then return false end
		local can_invoke = false
		for _, p in sgs.qlist(use.to) do
			if p:getMark("&f_ysS") == 0 then
				can_invoke = true
			end
		end
		if not can_invoke then return false end
		local extra_targets = room:getCardTargets(player, use.card, use.to)
		if extra_targets:isEmpty() then return false end
		local adds = sgs.SPlayerList()
		for _, p in sgs.qlist(extra_targets) do
			if p:getMark("&f_ysS") > 0 then
				if not use.to:contains(p) then
					use.to:append(p)
				end
				adds:append(p)
			end
		end
		if adds:isEmpty() then return false end
		room:sortByActionOrder(adds)
		room:sortByActionOrder(use.to)
		data:setValue(use)
		local log = sgs.LogMessage()
		log.type = "#QiaoshuiAdd"
		log.from = player
		log.to = adds
		log.card_str = use.card:toString()
		log.arg = self:objectName()
		room:sendLog(log)
		for _, p in sgs.qlist(adds) do
			room:doAnimate(1, player:objectName(), p:objectName())
		end
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
	end,
}
f_shenyuanshao:addSkill(f_guamou)

f_feishi = sgs.CreateTriggerSkill{
    name = "f_feishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName()
			and damage.to and damage.to:isAlive() and damage.to:getMark("&f_ysS") > 0 then
				if room:askForSkillInvoke(damage.to, self:objectName(), ToData("f_feishi-leave:"..player:objectName())) then
					local g = 2
					while not player:isNude() and g > 0 do
						local card = room:askForCardChosen(damage.to, player, "he", self:objectName())
						room:obtainCard(damage.to, card, false)
						g = g - 1
					end
					room:broadcastSkillInvoke(self:objectName())
					damage.to:loseAllMarks("&f_ysS")
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.who:objectName() ~= player:objectName()
			and death.who:getMark("&f_ysS") > 0 and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player, 1)
			end
		end
	end,
}
f_shenyuanshao:addSkill(f_feishi)



--神袁绍-江山如梦
f_shenyuanshao_if = sgs.General(extension_f, "f_shenyuanshao_if", "god", 4, true)

f_yourou = sgs.CreateTriggerSkill{
	name = "f_yourou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") and player:hasSkill(self:objectName()) then
				if math.random() > 0.5 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local list = use.nullified_list
					table.insert(list, "_ALL_TARGETS")
					use.nullified_list = list
					data:setValue(use)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenyuanshao_if:addSkill(f_yourou)

f_guaduan = sgs.CreateTriggerSkill{
	name = "f_guaduan",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") and player:hasSkill(self:objectName()) then
				if math.random() > 0.5 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local list = use.nullified_list
					table.insert(list, "_ALL_TARGETS")
					use.nullified_list = list
					data:setValue(use)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenyuanshao_if:addSkill(f_guaduan)

f_lijian = sgs.CreateTriggerSkill{
	name = "f_lijian",
	priority = 4,
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirming, sgs.CardFinished, sgs.ConfirmDamage, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirming then
			if use.card and not use.card:isKindOf("SkillCard") and use.from:objectName() ~= player:objectName()
			and use.to:contains(player) and use.to:length() == 1 and not player:isKongcheng() and player:hasSkill(self:objectName()) then
				local ljs = room:askForCard(player, "Slash", "@f_lijian-SlashShow", data, sgs.Card_MethodNone, nil, false, self:objectName(), false, nil)
				if ljs then
					f_Invoke(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:showCard(player, ljs:getEffectiveId())
					local choice = room:askForChoice(use.from, self:objectName(), "1+2", ToData(use.from))
					if choice == "1" then
						room:setPlayerMark(use.from, "f_lijian_cantusefrom-Clear", 1)
						room:setPlayerMark(player, "f_lijian_cantuseto-Clear", 1)
						room:acquireOneTurnSkills(use.from, self:objectName(), "f_lijian_limited")
					elseif choice == "2" then
						local log = sgs.LogMessage()
						log.type = "$to_f_lijian_fou"
						log.from = player
						log.to:append(use.from)
						room:sendLog(log)
						room:setCardFlag(use.card, "f_lijian_tsc")
						room:setPlayerFlag(player, "f_lijian_slash_usefrom")
						room:setPlayerFlag(use.from, "f_lijian_slash_useto")
						player:addToPile(self:objectName(), ljs:getEffectiveId())
					end
				end
			end
		elseif event == sgs.CardFinished then
			if use.card and use.card:hasFlag("f_lijian_tsc") and player:hasFlag("f_lijian_slash_useto") then
				room:setCardFlag(use.card, "-f_lijian_tsc")
				room:setPlayerFlag(player, "-f_lijian_slash_useto")
				for _, sys in sgs.qlist(room:getAllPlayers()) do
					if not sys:hasFlag("f_lijian_slash_usefrom") or sys:getPile(self:objectName()):length() == 0 then continue end
					room:setPlayerFlag(sys, "-f_lijian_slash_usefrom")
					if sys:canSlash(player, nil, false) and sys:hasSkill(self:objectName()) then
						if player:hasSkill("f_yourou") then
							room:addPlayerMark(player, "Qingchengf_yourou", 1)
							room:addPlayerMark(player, "f_lijian_f_yourou", 1)
						end
						room:sendCompulsoryTriggerLog(sys, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						for _, lj in sgs.qlist(sys:getPile(self:objectName())) do
							local lj_slash = sgs.Sanguosha:getCard(lj)
							room:setCardFlag(lj_slash, "f_lijian_slash_dmg")
							room:useCard(sgs.CardUseStruct(lj_slash, sys, player), false)
						end
					else
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(sys:getPile(self:objectName()))
						room:throwCard(dummy, nil)
						dummy:deleteLater()
					end
					break
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive then
			if player:getMark("f_lijian_f_yourou") > 0 then
				room:setPlayerMark(player, "Qingchengf_yourou", 0)
				room:setPlayerMark(player, "f_lijian_f_yourou", 0)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("f_lijian_slash_dmg") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_lijian_limited = sgs.CreateProhibitSkill{
	name = "f_lijian_limited&",
	is_prohibited = function(self, from, to, card)
		return from:getMark("f_lijian_cantusefrom-Clear") > 0 and to:getMark("f_lijian_cantuseto-Clear") > 0 and card and not card:isKindOf("SkillCard")
	end,
}
f_shenyuanshao_if:addSkill(f_lijian)
if not sgs.Sanguosha:getSkill("f_lijian_limited") then skills:append(f_lijian_limited) end

f_luanji = sgs.CreateViewAsSkill{
	name = "f_luanji",
	n = 4,
	view_filter = function(self, selected, to_select)
		for _, c in sgs.list(selected) do
			if c:getColor() ~= to_select:getColor() then
			return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards >= 2 and #cards <= 4 then
			local lj_wjqf = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_SuitToBeDecided, -1)
			for _, c in ipairs(cards) do
				lj_wjqf:addSubcard(c)
			end
			lj_wjqf:setSkillName(self:objectName())
			return lj_wjqf
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:getHandcardNum() >= 2 and player:getMark("f_luanji_used-PlayClear") == 0
	end,
}
f_luanjiBuff = sgs.CreateTriggerSkill{
	name = "#f_luanjiBuff",
	priority = 4,
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage, sgs.TargetSpecifying, sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "f_luanji" and damage.card:subcardsLength() >= 3 then
				room:sendCompulsoryTriggerLog(player, "f_luanji")
				--room:broadcastSkillInvoke("f_luanji")
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.TargetSpecifying then
			if use.card and use.card:getSkillName() == "f_luanji" and use.card:subcardsLength() >= 4 then
				if player:hasSkill("f_guaduan") then
					room:addPlayerMark(player, "Qingchengf_guaduan", 1)
                    room:addPlayerMark(player, "f_luanji_f_guaduan", 1)
				end
				room:sendCompulsoryTriggerLog(player, "f_luanji")
				--room:broadcastSkillInvoke("f_luanji")
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					table.insert(no_respond_list, p:objectName())
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		elseif event == sgs.CardUsed then
			if use.card and use.card:getSkillName() == "f_luanji" and use.from:objectName() == player:objectName() then
				if player:getMark("f_luanji_used-PlayClear") == 0 and player:getMark("f_mingmen") == 0 then
					room:addPlayerMark(player, "f_luanji_used-PlayClear")
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive then
			if player:getMark("f_luanji_f_guaduan") > 0 then
				room:setPlayerMark(player, "Qingchengf_guaduan", 0)
				room:setPlayerMark(player, "f_luanji_f_guaduan", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenyuanshao_if:addSkill(f_luanji)
f_shenyuanshao_if:addSkill(f_luanjiBuff)
extension_f:insertRelatedSkills("f_luanji", "#f_luanjiBuff")

lcd_f_huimengCard = sgs.CreateSkillCard{
    name = "lcd_f_huimengCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    room:broadcastSkillInvoke("f_huimeng")
		source:gainMark("&fUnited", 1)
		if self:getSubcards():isEmpty() then
			room:loseHp(source, 1)
		end
	end,
}
f_huimengVS = sgs.CreateViewAsSkill{
	name = "f_huimeng",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local card =  lhp_f_huimengCard:clone()
		if #cards > 0 then
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("f_mingmen") == 0
	end,
}
f_huimeng = sgs.CreateTriggerSkill{
	name = "f_huimeng",
	view_as_skill = f_huimengVS,
	events = {sgs.DrawNCards, sgs.Dying, sgs.AskForPeachesDone, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards and player:hasSkill("f_huimeng") then
			local draw = data:toDraw()
        	if draw.reason ~= "draw_phase" then return false end
			local n = player:getMark("&fUnited")
			if n < 3 then return false end
			if n > 18 then n = 18 end
			local count = data:toInt() + (n/3)
			room:sendCompulsoryTriggerLog(player, "f_huimeng")
			room:broadcastSkillInvoke("f_huimeng")
			draw.num = count
			data:setValue(draw)
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() or player:isNude() then return false end
			for _, sys in sgs.qlist(room:findPlayersBySkillName("f_huimeng")) do
				local n = sys:getMark("&fUnited")
				if sys:hasFlag("f_huimeng_refused") or n < 3 or sys:getMark("f_mingmen") > 0 then continue end
				if room:askForSkillInvoke(sys, "@f_huimeng-crzw", data) then
					room:broadcastSkillInvoke("f_huimeng")
					if n > 18 then n = 18 end
					local m = n / 3
					while m > 0 and not player:isNude() do
						local ruins = room:askForCardChosen(sys, player, "he", "f_huimeng", false, sgs.Card_MethodNone, sgs.IntList(), true)
						if ruins < 0 then --若中途取消获得牌，终止
							break
						else
							room:obtainCard(sys, ruins, false)
							m = m - 1
						end
					end
					sys:loseAllMarks("&fUnited")
				else
					room:setPlayerFlag(sys, "f_huimeng_refused")
				end
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("f_huimeng_refused") then
					room:setPlayerFlag(p, "-f_huimeng_refused")
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and player:hasSkill("f_huimeng") and player:getMark("f_mingmen") == 0 then
				local n = player:getMark("&fUnited")
				if n < 6 then return false end
				if n > 18 then n = 18 end
				if room:askForSkillInvoke(player, "@f_huimeng-myzd", data) then
					room:broadcastSkillInvoke("f_huimeng")
					player:loseMark("&fUnited", n/2)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
f_shenyuanshao_if:addSkill(f_huimeng)

f_mingmen = sgs.CreateTriggerSkill{
	name = "f_mingmen",
	frequency = sgs.Skill_Wake,
	events = {sgs.MarkChanged},
	can_wake = function(self, event, player, data)
		local room = player:getRoom()
		local mark = data:toMark()
		if mark.name ~= "&fUnited" or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&fUnited") < 18 then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("f_shenyuanshao_if", self:objectName())
		local isTCB = false --判断此游戏版本是不是《天才包》
		local tcb = sgs.GetConfig("BanPackages", "")
		if string.find(tcb, "goood") then
			isTCB = true
		else
			for _, szs in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
				if szs == "szs_guanyu" then
					isTCB = true
					break
				end
			end
		end
		if isTCB then
			sgs.Sanguosha:changeBGMEffect("audio/skill/f_shenyuanshao_if.ogg") --切换为神袁绍-江山如梦专属BGM
		end
		room:addPlayerMark(player, "@waked")
		room:addPlayerMark(player, self:objectName())
		if player:hasSkill("f_yourou") then
			room:detachSkillFromPlayer(player, "f_yourou")
		end
		if player:hasSkill("f_guaduan") then
			room:detachSkillFromPlayer(player, "f_guaduan")
		end
		room:setPlayerMark(player, "f_luanji_used-PlayClear", 0)
		room:changeTranslation(player, "f_luanji", 11)
		room:changeTranslation(player, "f_huimeng", 11)
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
f_shenyuanshao_if:addSkill(f_mingmen)

--
--==天才包专属神武将==--
extension_tc = sgs.Package("GeniusPackageGod", sgs.Package_GeneralPack)


--神祝融
tc_shenzhurong = sgs.General(extension_tc, "tc_shenzhurong", "god", 4, false)

tc_juxiang_stsh = sgs.CreateTriggerSkill{
    name = "tc_juxiang_stsh",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove, sgs.CardUsed, sgs.CardEffected, sgs.GameStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1 or not player:hasSkill(self:objectName())) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("SavageAssault")
				and use.from and use.from:objectName() ~= player:objectName() then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
				if use.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				    room:setPlayerFlag(player, self:objectName())
				end
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Finish or player:hasFlag(self:objectName()) then return false end
			if not player:hasSkill(self:objectName()) then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local slash = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, -1)
			slash:deleteLater()
		    slash:setSkillName("_"..self:objectName())
			room:useCard(sgs.CardUseStruct(slash, player, room:getOtherPlayers(player)), false)
		elseif event == sgs.BeforeCardsMove then
		    if player and player:isAlive() and player:hasSkill(self:objectName()) then
			    local move = data:toMoveOneTime()
				if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
				    local card = sgs.Sanguosha:getCard(move.card_ids:first())
				    if card:hasFlag("real_SA") and (player:objectName() ~= move.from:objectName()) then
				        room:sendCompulsoryTriggerLog(player, self:objectName())
				        room:broadcastSkillInvoke(self:objectName(), 1)
					    player:obtainCard(card)
					    move.card_ids = sgs.IntList()
					    data:setValue(move)
					end
				end
			end
		elseif event == sgs.CardEffected then
		    local effect = data:toCardEffect()
		    if effect.card:isKindOf("SavageAssault") and effect.to:hasSkill(self:objectName()) then
				    room:sendCompulsoryTriggerLog(effect.to, self:objectName())
				    room:broadcastSkillInvoke(self:objectName())
			    return true
		    else
			    return false
		    end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
tc_liefeng_spwd = sgs.CreateTriggerSkill{
    name = "tc_liefeng_spwd",
	--global = true,
	events = {sgs.CardUsed, sgs.CardFinished, sgs.Pindian},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    local lieren = true
		    for _, p in sgs.qlist(use.to) do
			    if p:isKongcheng() or p:objectName() == player:objectName() then lieren = false end
			end
			if lieren and use.card:isKindOf("Slash") and use.from:objectName() == player:objectName()
			and player:hasSkill(self:objectName()) and not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local success
				local card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "@tc_liefeng_spwd-invoke", false)
				for _, p in sgs.qlist(use.to) do
			    	success = player:pindian(p, self:objectName(), card_id)
				end
				if success then room:setCardFlag(use.card, "lieren") end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= self:objectName() then return false end
			local winner
			local loser
			if pindian.from_number >= pindian.to_number then
				winner = pindian.from
				loser = pindian.to
			end
			if loser then
				room:setPlayerFlag(loser, "lieren")
			end
		else
		    local use = data:toCardUse()
			if not use.card:hasFlag("lieren") or not player:hasSkill(self:objectName()) then return false end
			local players, targets = room:getOtherPlayers(player), sgs.SPlayerList()
			for _, p in sgs.qlist(players) do
			    if p:hasFlag("lieren") then
				    players:removeOne(p)
					room:setPlayerFlag(p, "-lieren")
				    targets:append(p)
				end
			end
			if not players:isEmpty() then
			    local to = room:askForPlayerChosen(player, players, self:objectName(), "~shuangren", false, true)
				room:broadcastSkillInvoke(self:objectName())
				local dama, n = nil, math.random(1, 4)
				if n == 1 then dama = sgs.DamageStruct_Normal end
				if n == 2 then dama = sgs.DamageStruct_Ice end
				if n == 3 then dama = sgs.DamageStruct_Thunder end
				if n == 4 then dama = sgs.DamageStruct_Fire end
				room:damage(sgs.DamageStruct(self:objectName(), player, to, math.random(1, 3), dama))
				if not targets:isEmpty() then
				    for _, pe in sgs.qlist(targets) do
			            room:loseHp(pe)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())--getGeneralName() == "tc_shenzhurong" or target:getGeneral2Name() == "tc_shenzhurong"
	end,
}
tc_changbiao_sqrhCard = sgs.CreateSkillCard{
	name = "tc_changbiao_sqrh",
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "&".."tc_changbiao_sqrh".."-Clear", self:getSubcards():length())
		if #targets > 0 then
			for _,p in pairs(targets) do
				room:cardEffect(self, source, p)
			end
		end
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		if effect.to then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		    slash:addSubcards(self:getSubcards())
		    slash:setSkillName("tc_changbiao_sqrh")
			room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to, false))
		end
	end,
}
tc_changbiao_sqrhvs = sgs.CreateViewAsSkill{
	name = "tc_changbiao_sqrh",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = tc_changbiao_sqrhCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tc_changbiao_sqrh") and not player:isKongcheng()
	end,
}
tc_changbiao_sqrh = sgs.CreateTriggerSkill{
    name = "tc_changbiao_sqrh",
	events = {sgs.Damage, sgs.CardFinished},
    view_as_skill = tc_changbiao_sqrhvs,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.Damage then
		    local damage = data:toDamage()
		    if damage.card:getSkillName() == "tc_changbiao_sqrh" then
				room:setCardFlag(damage.card, "olchangbiao")
			end
		else
		    local use = data:toCardUse()
			if not use.card:hasFlag("olchangbiao") or player:getMark("&".."tc_changbiao_sqrh".."-Clear") == 0 then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(player:getMark("&".."tc_changbiao_sqrh".."-Clear"))
		end
	end,
}
tc_shenzhurong:addSkill(tc_juxiang_stsh)
tc_shenzhurong:addSkill(tc_liefeng_spwd)
tc_shenzhurong:addSkill(tc_changbiao_sqrh)


--

--神貂蝉
diy_k_shendiaochan = sgs.General(extension_tc, "diy_k_shendiaochan", "god", 3, false)
diy_god_biyue = sgs.CreateTriggerSkill{
	name = "diy_god_biyue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local players = sgs.SPlayerList()
		players:append(player)
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getRole() ~= "lord" then
				-- room:addPlayerMark(p, "&"..p:getRole(), 1, players)
				room:notifyProperty(player, p, "role", p:getRole())
			end
		end
	end,
}
diy_k_meihunCard = sgs.CreateSkillCard{
	name = "diy_k_meihun",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
--	feasible = function(self, targets)
--	    return #targets == 1
--	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local card_id = self:getEffectiveId()
		local card = sgs.Sanguosha:getCard(card_id)
		local nature, n = nil, math.random(1, 3)
		if target:isKongcheng() then
			room:throwCard(self, source, nil)
			for _,skill in sgs.qlist(target:getVisibleSkillList()) do
				if target:getMark("Qingcheng"..skill:objectName()) == 0 then
				    room:addPlayerMark(target, "Qingcheng"..skill:objectName())
				end
			end
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:damage(sgs.DamageStruct(self:objectName(), source, target, n, sgs.DamageStruct_Normal))
			for _,skill in sgs.qlist(target:getVisibleSkillList()) do
				if target:getMark("Qingcheng"..skill:objectName()) > 0 then
				    room:removePlayerMark(target, "Qingcheng"..skill:objectName())
				end
			end
			room:addPlayerHistory(source, "#diy_k_meihun", -1)
		else
		    target:obtainCard(self)
		    room:showAllCards(target)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(target:handCards()) do
				if sgs.Sanguosha:getCard(id):getSuit() == card:getSuit() then
					slash:addSubcard(id)
				end
			end
			if not slash:getSubcards():isEmpty() then
			    room:broadcastSkillInvoke(self:objectName(), 2)
				room:obtainCard(source, slash, false)
			end
		end
	end,
}
diy_k_meihunvs = sgs.CreateViewAsSkill{
	name = "diy_k_meihun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = diy_k_meihunCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:isNude() and player:usedTimes("#diy_k_meihun") < 1
	end,
}
diy_k_meihun = sgs.CreateTriggerSkill{
	name = "diy_k_meihun",
	events = {sgs.PreCardUsed},
	view_as_skill = diy_k_meihunvs,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "diy_k_meihun" then
					room:broadcastSkillInvoke(skill, 1)
					return true
				end
			end
		end
	end,
}
diy_k_huoxin = sgs.CreateTriggerSkill{
	name = "diy_k_huoxin",
	--global = true,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish then return nil end
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:objectName() ~= player:objectName() then
				local card2 = room:askForCard(p, "..", "@diy_k_huoxin", data, sgs.Card_MethodNone, nil, false, self:objectName(), false, nil)
				if card2 ~= nil then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:obtainCard(player, card2, false)
					p:drawCards(1)
					if not player:isNude() then
						local id = room:askForCardChosen(p, player, "he", self:objectName())
						room:obtainCard(p, id)
					end
				else
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(2)
				end
			else
			    room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2)
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player
	end,
}
diy_k_shendiaochan:addSkill(diy_god_biyue)
diy_k_shendiaochan:addSkill(diy_k_meihun)
diy_k_shendiaochan:addSkill(diy_k_huoxin)

--神马超
diy_k_shenmachao = sgs.General(extension_tc, "diy_k_shenmachao", "god", 4, true)
diy_k_shouliCard = sgs.CreateSkillCard{
	name = "diy_k_shouli",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card, user_string = nil, self:getUserString()
            if user_string ~= "" then
                card = sgs.Sanguosha:cloneCard(user_string:split("+")[1])
                card:setSkillName("diy_k_shouli")
            end
            return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
        end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("diy_k_shouli")
        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
	feasible = function(self, targets, player)
        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("diy_k_shouli")
		use_card:deleteLater()
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return use_card and use_card:targetsFeasible(qtargets, player)
    end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
        local source = cardUse.from
        local room = source:getRoom()

		local targets = sgs.SPlayerList()
		local to, card_id
		if source:getMark("diy_k_shouli-noSelf-Clear") == 0 then
			for _,p in sgs.qlist(room:getOtherPlayers(source)) do
				if not p:isNude() then
					targets:append(p)
				end
			end
		end
		if source:getMark("diy_k_shouli-Self-Clear") == 0 and source:canDiscard(source, "he") then
			targets:append(source)
		end
		if not targets:isEmpty() then
			to = room:askForPlayerChosen(source, targets, self:objectName(), "~shuangren", false, false)
		end		
		if to then
			if to == source then
				card_id = room:askForCardChosen(source, to, "he", self:objectName(),true,sgs.Card_MethodDiscard)
				room:addPlayerMark(source, "diy_k_shouli-Self-Clear")
				room:throwCard(card_id, source, source)
			else
				card_id = room:askForCardChosen(source, to, "he", self:objectName(),false,sgs.Card_MethodNone)
				room:addPlayerMark(source, "diy_k_shouli-noSelf-Clear")
				room:obtainCard(source, card_id, false)
			end
		end
		
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("diy_k_shouli")
        room:setCardFlag(slash, "RemoveFromHistory")
        return slash
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

		local targets = sgs.SPlayerList()
		local to, card_id
		if source:getMark("diy_k_shouli-noSelf-Clear") == 0 then
			for _,p in sgs.qlist(room:getOtherPlayers(source)) do
				if not p:isNude() then
					targets:append(p)
				end
			end
		end
		if source:getMark("diy_k_shouli-Self-Clear") == 0 and source:canDiscard(source, "he") then
			targets:append(source)
		end
		if not targets:isEmpty() then
			to = room:askForPlayerChosen(source, targets, self:objectName(), "~shuangren", false, false)
		end		
		if to then
			if to == source then
				card_id = room:askForCardChosen(source, to, "he", self:objectName(),true,sgs.Card_MethodDiscard)
				room:addPlayerMark(source, "diy_k_shouli-Self-Clear")
			else
				card_id = room:askForCardChosen(source, to, "he", self:objectName(),false,sgs.Card_MethodNone)
				room:addPlayerMark(source, "diy_k_shouli-noSelf-Clear")
				room:obtainCard(source, card_id, false)
			end
		end

        local user_string = sgs.Sanguosha:getCurrentCardUsePattern()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("diy_k_shouli")
        return use_card
    end,
}
diy_k_shoulivs = sgs.CreateViewAsSkill{
	name = "diy_k_shouli",
	n = 0,
	view_as = function()
		local card = diy_k_shouliCard:clone()
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            card:setUserString("slash")
            return card
        end
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        card:setUserString(pattern)
        return card
	end,
	enabled_at_play = function(self, player)
		local players, shouli = player:getSiblings(), false
		if player:canDiscard(player, "he") then
			players:append(player)
		end
		for _, sib in sgs.qlist(players) do
			if not sib:isNude() then shouli = true end
		end
		return sgs.Slash_IsAvailable(player) and shouli and (player:getMark("diy_k_shouli-noSelf-Clear") == 0 or player:getMark("diy_k_shouli-Self-Clear") == 0)
	end,
	enabled_at_response = function(self, player, pattern)
        return (pattern == "slash" or pattern == "jink") and (player:getMark("diy_k_shouli-noSelf-Clear") == 0 or player:getMark("diy_k_shouli-Self-Clear") == 0)
    end,
}
diy_k_shouli = sgs.CreateTriggerSkill{
	name = "diy_k_shouli",
	events = {sgs.EventPhaseChanging, sgs.CardFinished, sgs.TargetSpecified},
	view_as_skill = diy_k_shoulivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("&diy_k_shouli-Clear") > 0 then
					room:setPlayerMark(p, "&diy_k_shouli-Clear", 0)
					for _,skill in sgs.qlist(p:getVisibleSkillList()) do
						room:setPlayerMark(p, "Qingcheng"..skill:objectName(), 0)
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "diy_k_shouli" then
				for _,p in sgs.qlist(use.to) do
					room:addPlayerMark(p, "&diy_k_shouli-Clear")
					for _,skill in sgs.qlist(p:getVisibleSkillList()) do
						room:addPlayerMark(p, "Qingcheng"..skill:objectName())
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "diy_k_shouli" then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("&diy_k_shouli-Clear") > 0 then
						room:setPlayerMark(p, "&diy_k_shouli-Clear", 0)
						for _,skill in sgs.qlist(p:getVisibleSkillList()) do
							room:setPlayerMark(p, "Qingcheng"..skill:objectName(), 0)
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

diy_k_shouli_buff = sgs.CreateTargetModSkill {
	name = "#diy_k_shouli_buff",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("diy_k_shouli") and card and card:getSkillName() == "diy_k_shouli" then
			return 999
		else
			return 0
		end
    end,
}



diy_k_hengwu = sgs.CreateTriggerSkill{
    name = "diy_k_hengwu",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        local suit, st = card:getSuitString(), card:getSuit()
        if card:isKindOf("SkillCard") or player:getMark("diy_k_hengwu"..st.."-Clear") > 0 then return false end
        local n = 1
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke(self:objectName())
        local prompt = string.format("@hengwuu:%s::%s:",suit,n)
        local pattern = ".|"..suit.."|.|."
        player:setTag("diy_k_hengwu", sgs.QVariant(suit))--ai
        local dis = room:askForDiscard(player, self:objectName(), 999, 0, true, true, prompt, pattern)
        if dis then player:drawCards(n + dis:subcardsLength())
        else player:drawCards(n) end
		room:setPlayerMark(player, "diy_k_hengwu"..st.."-Clear", 1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}
diy_k_shenmachao:addSkill(diy_k_shouli)
diy_k_shenmachao:addSkill(diy_k_shouli_buff)
extension_tc:insertRelatedSkills("diy_k_shouli", "#diy_k_shouli_buff")
diy_k_shenmachao:addSkill(diy_k_hengwu)



--神裴秀
tc_shenpeixiu = sgs.General(extension_tc, "tc_shenpeixiu", "god", 4, true)

tc_zhitu = sgs.CreateTriggerSkill{
    name = "tc_zhitu",
	priority = {3, 2},
	change_skill = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			local resp = data:toCardResponse()
			card = resp.m_card
		end
		if card == nil or card:isKindOf("SkillCard") then return false end
		local x, n = player:getMark("&".."tc_zhitu"), card:getNumber()
		local cards = {}
		if x > 0 then
			for i=1,n do
				if x*i==n then
					room:broadcastSkillInvoke(self:objectName())
					for _, id in sgs.qlist(room:getDrawPile()) do
						local c = sgs.Sanguosha:getCard(id):getNumber()
						if x % c == 0 then
							table.insert(cards, sgs.Sanguosha:getCard(id))
						end 
					end
					break
				end
			end
			for i=1,x do
				if x/n==i
				then
					room:sendCompulsoryTriggerLog(player,self)
					for _, id in sgs.qlist(room:getDrawPile()) do
						local c = sgs.Sanguosha:getCard(id):getNumber()
						if x % c == 0 then
							table.insert(cards, sgs.Sanguosha:getCard(id))
						end 
					end
					break
				end
			end
			if #cards > 0 then
				local cardd = cards[math.random(1, #cards)]
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:obtainCard(player, cardd)
			end
		end
		room:setPlayerMark(player, "&".."tc_zhitu", n)
		if event ~= sgs.CardUsed then return false end
		local cg = player:getChangeSkillState(self:objectName())
		if cg == 1 then
			room:setChangeSkillState(player, self:objectName(), 2)
		elseif cg == 2 then
			room:setChangeSkillState(player, self:objectName(), 1)
		end
	end,
}
tc_zhitu_buff = sgs.CreateTargetModSkill{
	name = "#tc_zhitu_buff",
	pattern = "^SkillCard",
	distance_limit_func = function(self, player, card)
		local x, n = player:getMark("&".."tc_zhitu"), 0
		if not card then return 0 end
		local num = card:getNumber()
		if player:hasSkill("tc_zhitu") then
			local cg = player:getChangeSkillState("tc_zhitu")
			if cg == 1 then
				if x > 0 then
					for i=1,x do
						if x/num==i
						then
							n = n + 1000
							break
						end
					end
				end
			elseif cg == 2 then
				if x > 0 then
					for i=1,x do
						if x*num==i
						then
							n = n + 1000
							break
						end
					end
				end
			end
		end
		return n
	end,
	residue_func = function(self, player, card)
		if not card then return 0 end
		local x, num, n = player:getMark("&".."tc_zhitu"), card:getNumber(), 0
		if player:hasSkill("tc_zhitu") then
			local cg = player:getChangeSkillState("tc_zhitu")
			if cg == 2 then
				if x > 0 then
					for i=1,x do
						if x/num==i
						then
							n = n + 1000
							break
						end
					end
				end
			elseif cg == 1 then
				if x > 0 then
					for i=1,x do
						if x*num==i
						then
							n = n + 1000
							break
						end
					end
				end
			end
		end
		return n
	end,
}
tc_shenpeixiu:addSkill(tc_zhitu)
tc_shenpeixiu:addSkill(tc_zhitu_buff)
extension_tc:insertRelatedSkills("tc_zhitu", "#tc_zhitu_buff")

tc_liutiCard = sgs.CreateSkillCard{
	name = "tc_liutiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local num, y1, zx = 0, self:subcardsLength() - 1, source:getMark("&".."tc_zhitu")
		for _, id in sgs.qlist(self:getSubcards()) do
			local n = sgs.Sanguosha:getCard(id):getNumber()
			num = num + n
		end
		while num >= zx do
			num = num - zx
		end
		if num == 0 then source:speak("？这什么情况...不对劲...艹，没算明白，余数是0啊！") return false end --恭喜你，成功掉坑
		local tc_liuti_gets, sum = sgs.IntList(), 0
		while y1 > 0 do
			local tc_liuti_y1 = {}
			for _, id in sgs.qlist(room:getDrawPile()) do
				if tc_liuti_gets:contains(id) then continue end
				local cd = sgs.Sanguosha:getCard(id)
				if y1 > 1 or num == 1 then
					table.insert(tc_liuti_y1, cd)
				else
					local numx, numxs = num, sum + cd:getNumber()
					while numxs >= numx do
						numxs = numxs - numx
					end
					if numxs == 0 then
						table.insert(tc_liuti_y1, cd)
					end
				end
			end
			if room:getDiscardPile():length() > 0 then
				for _, id in sgs.qlist(room:getDiscardPile()) do
					if tc_liuti_gets:contains(id) then continue end
					local cd = sgs.Sanguosha:getCard(id)
					if y1 > 1 or num == 1 then
						table.insert(tc_liuti_y1, cd)
					else
						local numx, numxs = num, sum + cd:getNumber()
						while numxs >= numx do
							numxs = numxs - numx
						end
						if numxs == 0 then
							table.insert(tc_liuti_y1, cd)
						end
					end
				end
			end
			if #tc_liuti_y1 > 0 then
				local tly_card = tc_liuti_y1[math.random(1, #tc_liuti_y1)]
				local s = tly_card:getNumber()
				sum = sum + s
				tc_liuti_gets:append(tly_card:getEffectiveId())
			end
			y1 = y1 - 1
		end
		if not tc_liuti_gets:isEmpty() then
			local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(tc_liuti_gets)
			room:obtainCard(source, dummy)
			dummy:deleteLater()
		end
	end,
}
tc_liuti = sgs.CreateViewAsSkill{
	name = "tc_liuti",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards <= 1 then return nil end
		local skillcard = tc_liutiCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getEquips():length() + player:getHandcardNum() >= 2
	end,
}
tc_shenpeixiu:addSkill(tc_liuti)
--



--神吕布
tc_shenlvbu = sgs.General(extension_tc, "tc_shenlvbu", "god", 6, true, false, false, 4)
tc_kuangbao = sgs.CreateTriggerSkill{
	name = "tc_kuangbao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
		    room:broadcastSkillInvoke(self:objectName())
			player:gainMark("&wrath", 6)
			room:notifySkillInvoked(player, self:objectName())
		else
			local damage = data:toDamage()
			room:sendCompulsoryTriggerLog(player, self:objectName())
		    room:broadcastSkillInvoke(self:objectName())
			player:gainMark("&wrath", damage.damage)
			room:notifySkillInvoked(player, self:objectName())
		end
	end,
}
tc_wumou = sgs.CreateFilterSkill{
	name = "tc_wumou",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard") or to_select:isKindOf("Slash")) and place == sgs.Player_PlaceHand
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		slash:setObjectName("wrath_slash")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end,
}
tc_wumou_buff = sgs.CreateTargetModSkill{
	name = "#tc_wumou_buff",
	distance_limit_func = function(self, from, card)
		local n = 0
		if from:hasSkill("tc_wumou") and card:getSkillName() == "tc_wumou" then
			n = 1000
		end
		return n
	end,
	residue_func = function(self, player, card)
		local n = 0
		if player:hasSkill("tc_wumou") and card:getSkillName() == "tc_wumou" then
			n = 1000
		end
		return n
	end,
}
tc_wumou_use = sgs.CreateTriggerSkill{
	name = "tc_wumou_use",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardFinished, sgs.DamageCaused, sgs.CardOffset},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    if use.card:getSkillName() == "tc_wumou" and use.from:objectName() == player:objectName() and use.from:hasSkill("tc_wumou") and (use.from:getMark("&wrath") > 0 or use.from:getMark("@wrath") > 0) and player:askForSkillInvoke("tc_wumou", data) then
			    room:broadcastSkillInvoke("tc_wumou")
				if player:getMark("&wrath") > 0 then
				    player:loseMark("&wrath")
			    end
			    for _, p in sgs.qlist(use.to) do
		            room:addPlayerMark(p, "Armor_Nullified")
			        for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				        room:addPlayerMark(p, "Qingcheng"..skill:objectName())
					end
			    end
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card:objectName()=="wrath_slash"
			and effect.offset_card:isKindOf("Jink")
			and effect.to:getHandcardNum()>0 then
				Skill_msg("yj_stabs_slash",effect.from)
				if room:askForDiscard(effect.to,"yj_stabs_slash",1,1,true,false,"yj_stabs_slash0:")
				then else return true end
			end
		elseif event == sgs.CardFinished then
		    local use = data:toCardUse()
		    if use.card:getSkillName() == "tc_wumou" and use.from:objectName() == player:objectName() and use.from:hasSkill("tc_wumou") then
			    for _, p in sgs.qlist(use.to) do
		            room:removePlayerMark(p, "Armor_Nullified")
			        for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				        room:removePlayerMark(p, "Qingcheng"..skill:objectName())
					end
			    end
			end
		else
		    local damage = data:toDamage()
		    if damage.from:objectName() == player:objectName() and damage.from:hasSkill("tc_wumou") and damage.card:getSkillName() == "tc_wumou" and player:getMark("tc_wumou".."-Clear") > 0 and room:askForSkillInvoke(player, "tc_wumou_damage", data) then
			    room:broadcastSkillInvoke("tc_wumou")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.play_animation = true
				judge.who = player
				judge.reason = "tc_wumou"
				room:judge(judge)
				if judge:isBad() then return false end
				if player:isWounded() then
				    room:recover(player, sgs.RecoverStruct(player, nil, 1))
				else
				    player:drawCards(1)
				end
		    end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}

tc_wuqian = sgs.CreateTriggerSkill{
	name = "tc_wuqian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.CardEffected, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") then
                local wushuang = {}
                if player:hasSkill(self:objectName()) and (player:getMark("@wrath") >= 2 or player:getMark("&wrath") >= 2) then
					if player:getMark("&wrath") > 0 then
						player:loseMark("&wrath", 2)
					end
					if player:getMark("@wrath") > 0 then
						player:loseMark("@wrath", 2)
					end
                    for _, p in sgs.qlist(use.to) do
                        table.insert(wushuang, p:objectName())
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    if p:hasSkill(self:objectName()) and (p:getMark("@wrath") >= 2 or p:getMark("&wrath") >= 2) then
                        table.insert(wushuang, player:objectName())
						if p:getMark("&wrath") > 0 then
							p:loseMark("&wrath", 2)
						end
						if p:getMark("@wrath") > 0 then
							p:loseMark("@wrath", 2)
						end
                    end
                end
                room:setTag("tc_wuqian_"..use.card:toString(), sgs.QVariant(table.concat(wushuang, "+")))
            elseif use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) and (player:getMark("@wrath") >= 2 or player:getMark("&wrath") >= 2) then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
				if player:getMark("&wrath") > 0 then
				    player:loseMark("&wrath", 2)
			    end
			    if player:getMark("@wrath") > 0 then
				    player:loseMark("@wrath", 2)
			    end
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") then
				local wushuang = room:getTag("tc_wuqian_" .. effect.card:toString()):toString()
				if wushuang and wushuang ~= "" then
					if string.find(wushuang, effect.to:objectName()) or string.find(wushuang, effect.from:objectName()) then
						room:setTag("tc_wuqianData", data)
					end
				end
			end
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_toCard and resp.m_toCard:isKindOf("Duel") and not player:hasFlag("tc_wuqianSlash") then
				local wushuang = room:getTag("tc_wuqian_" .. resp.m_toCard:toString()):toString()
				if wushuang and wushuang ~= "" then
					if string.find(wushuang, player:objectName()) then
						room:setPlayerFlag(player,"tc_wuqianSlash")
						if not room:askForCard(player, "slash", "duel-slash:"..resp.m_who:objectName(), room:getTag("tc_wuqianData"), sgs.Card_MethodResponse, resp.m_who, false, "",false,resp.m_toCard) then
							resp.nullified = true
							data:setValue(resp)
						end
						room:setPlayerFlag(player,"-tc_wuqianSlash")
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
tc_shenfenCard = sgs.CreateSkillCard{
	name = "tc_shenfen",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:setFlags("tc_shenfenUsing")
		if source:getMark("&wrath") > 0 then
			source:loseMark("&wrath", 6)
		end
		if source:getMark("@wrath") > 0 then
			source:loseMark("@wrath", 6)
		end
		local players = room:getOtherPlayers(source)
		for _, p in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("tc_shenfen", source, p))
		end
		for _, p in sgs.qlist(players) do
			p:throwAllCards()
		end
		room:addPlayerMark(source, "tc_wumou".."-Clear")
		source:setFlags("-tc_shenfenUsing")
	end,
}
tc_shenfen = sgs.CreateZeroCardViewAsSkill{
	name = "tc_shenfen",
	view_as = function()
		return tc_shenfenCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return (player:getMark("@wrath") >= 6 or player:getMark("&wrath") >= 6) and not player:hasUsed("#tc_shenfen")
	end,
}
tc_shenlvbu:addSkill(tc_kuangbao)
tc_shenlvbu:addSkill(tc_wumou)
tc_shenlvbu:addSkill(tc_wumou_buff)
extension_tc:insertRelatedSkills("tc_wumou", "#tc_wumou_buff")
tc_shenlvbu:addSkill(tc_wuqian)
tc_shenlvbu:addSkill(tc_shenfen)
if not sgs.Sanguosha:getSkill("tc_wumou_use") then skills:append(tc_wumou_use) end



--神左慈
tc_shenzuoci = sgs.General(extension_tc, "tc_shenzuoci", "god", 3)
tc_huashenCard = sgs.CreateSkillCard{
	name = "tc_huashen",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {"wei", "shu", "wu", "qun", "jin", "god"}
		table.removeOne(choices, source:getKingdom())
		local logs = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
		room:setPlayerProperty(source, "kingdom", sgs.QVariant(logs))
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if not string.find(pattern, "@@tc_huashen") then
		    for _,skill in sgs.qlist(source:getVisibleSkillList()) do
			    if source:hasSkill(skill:objectName()) and source:getMark(skill:objectName().."-Clear") < 1 and source:getMark("tc_huashen"..skill:objectName()) > 0 then
				    room:removePlayerMark(source, "tc_huashen"..skill:objectName())
				    room:detachSkillFromPlayer(source, skill:objectName())
				end
			end
		else
            room:addPlayerMark(source, self:objectName().."-Clear")
		end
		local n, x = 1, 1
		while n > 0 do
			local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
			local god_generals = {}
			for _, name in ipairs(all_generals) do
			    local general = sgs.Sanguosha:getGeneral(name)
			    if general:getKingdom() == logs then
				    table.insert(god_generals, name)
			    end
			end
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if table.contains(god_generals, p:getGeneralName()) then
					table.removeOne(god_generals, p:getGeneralName())
				end
			end
			local god_general = {}
			for i = 1, x do
				local first = god_generals[math.random(1, #god_generals)]
				table.insert(god_general, first)
				table.removeOne(god_generals, first)
			end
			local generals = table.concat(god_general, "+")
			local general = sgs.Sanguosha:getGeneral(room:askForGeneral(source, generals))
			local skill_names = {}
			for _, skill in sgs.qlist(general:getVisibleSkillList()) do
				table.insert(skill_names, skill:objectName())
			end
			if #skill_names > 0 then
				local choice = skill_names[math.random(1, #skill_names)]
				room:acquireSkill(source, choice)
				room:addPlayerMark(source, "tc_huashen"..choice)
				room:addPlayerMark(source, choice.."-Clear")
			end
			n = n - 1
		end
	end,
}
tc_huashen = sgs.CreateViewAsSkill{
	name = "tc_huashen",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return tc_huashenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#tc_huashen") < 1 + player:getMark(self:objectName().."-Clear")
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@tc_huashen")
	end,
}
tc_xinsheng = sgs.CreateTriggerSkill{
    name = "tc_xinsheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		local zc, invoke, n = player, nil, 0
		if not zc:isAlive() or zc:objectName() ~= damage.to:objectName() then return false end
		room:sendCompulsoryTriggerLog(zc, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		while n < damage.damage do
			local choices = {}
			if zc:hasSkill(self:objectName()) and zc:hasSkill("tc_huashen") then
				table.insert(choices, "yes")
			end
			table.insert(choices, "no")
			local choice = room:askForChoice(zc, "@tc_huashen", table.concat(choices, "+"))
			if choice == "yes" then
				invoke = room:askForUseCard(zc, "@@tc_huashen", "@tc_huashen")
			end
			local current = room:getCurrent()
			if (not invoke or choice == "no") and zc:objectName() ~= current:objectName() then
				zc:drawCards(1)
			end
			n = n + 1
		end
	end,
}
tc_shenzuoci:addSkill(tc_huashen)
tc_shenzuoci:addSkill(tc_xinsheng)


--神郭嘉
tc_shenguojia = sgs.General(extension_tc, "tc_shenguojia", "god", 3)
tc_huishiCard = sgs.CreateSkillCard{
    name = "tc_huishi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local suits = {}
		while (source:isAlive() and source:getMaxHp() < 10)do		
			local judge = sgs.JudgeStruct()
			judge.who = source
			judge.reason = self:getSkillName()
			judge.pattern = ".|"..table.concat(suits,",")
			judge.throw_card = false
			judge.good = false
			room:judge(judge)
			table.insert(suits,judge.card:getSuitString())
			local id = judge.card:getEffectiveId()
			if room:getCardPlace(id)==sgs.Player_PlaceJudge then
				self:addSubcard(id)
			end
			
			if judge:isGood() and source:isAlive() and source:askForSkillInvoke(self:getSkillName()) then
				
			else
				break
			end
		end
		if source:isAlive() and self:subcardsLength() > 0 then
			room:fillAG(self:getSubcards(),source)
			local to = room:askForPlayerChosen(source,room:getAlivePlayers(),self:getSkillName(),"@huishi-give",true,false)
			room:clearAG(source)
			if to then
				room:doAnimate(1,source:objectName(),to:objectName())
				room:giveCard(source,to,self,self:getSkillName(),true)
				if to:isAlive() and source:isAlive() then
					local hand = to:getHandcardNum()
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getHandcardNum() > hand then return end
					end
					room:loseMaxHp(source,1,self:getSkillName())
					return
				end
			end
		end
		local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "tc_huishizx", "~shuangren", true, true)
		if target then
			room:acquireSkill(target, "tc_zuoxing")
		else
			room:acquireSkill(source, "tc_zuoxing")
		end
	end,
}
tc_huishivs = sgs.CreateZeroCardViewAsSkill{
	name = "tc_huishi",
	view_as = function()
		return tc_huishiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#tc_huishi") < 1
	end,
}
tc_huishi = sgs.CreateTriggerSkill{
	name = "tc_huishi",
	events = {sgs.EventPhaseStart, sgs.PreCardUsed},
	view_as_skill = tc_huishivs,
	waked_skills = "tc_zuoxing",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_RoundStart then
			    for _, p in sgs.qlist(room:getAlivePlayers()) do
				    if not p:hasSkill("tc_zuoxing") then continue end
					room:detachSkillFromPlayer(p, "tc_zuoxing")
				end
			end
		else
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "tc_huishi" then
					room:broadcastSkillInvoke("tc_huishi")
					return true
				end
			end
		end
	end,
}
tc_zuoxingCard = sgs.CreateSkillCard{
	name = "tc_zuoxing",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getTag("tc_zuoxing"):toCard()
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
		local card = sgs.Self:getTag("tc_zuoxing"):toCard()
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
		local player = card_use.from
		local room = player:getRoom()
	    local can_invoke = false
	    for _, p in sgs.qlist(room:getAllPlayers()) do
		    if (p:getGeneralName() == "tc_shenguojia" or p:getGeneral2Name() == "tc_shenguojia") and p:isAlive() then
				can_invoke = true
			    room:cardEffect(self, player, p)
		    	room:getThread():delay()
			    break
		    end
	    end
	    if can_invoke then
		    local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		    use_card:setSkillName(self:objectName())
		    local available = true
		    for _,p in sgs.qlist(card_use.to) do
			    if player:isProhibited(p, use_card)	then
				    available = false
				    break
			    end
		    end
		    available = available and use_card:isAvailable(player)
		    if not available then return nil end
		    return use_card
        end			
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local card_id = room:askForExchange(effect.from, self:objectName(), 1, 1, true, "", false)
		room:obtainCard(effect.to, card_id, false)
	end,
}
tc_zuoxingvs = sgs.CreateViewAsSkill{
	name = "tc_zuoxing",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		local c = sgs.Self:getTag("tc_zuoxing"):toCard()
		if c then
			local card = tc_zuoxingCard:clone()
			card:setUserString(c:objectName())	
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
	    local can_invoke = false
		local players = player:getSiblings()
		players:append(player)
	    for _, p in sgs.qlist(players) do
		    if (p:getGeneralName() == "tc_shenguojia" or p:getGeneral2Name() == "tc_shenguojia") and p:isAlive()  then
				can_invoke = true
		    end
	    end
		return can_invoke and not player:isNude() and not player:hasUsed("#tc_zuoxing")
	end,
}
tc_zuoxing = sgs.CreateTriggerSkill{
	name = "tc_zuoxing",
	events = {sgs.PreCardUsed},
	view_as_skill = tc_zuoxingvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "tc_zuoxing" then
					room:broadcastSkillInvoke("tc_zuoxing")
					return true
				end
			end
		end
	end,
}
tc_zuoxing:setGuhuoDialog("lr")
tc_shenguojia:addSkill(tc_huishi)
if not sgs.Sanguosha:getSkill("tc_zuoxing") then skills:append(tc_zuoxing) end
tc_shenguojia:addSkill("tiandu")
tc_shenguojia:addSkill("tenyearyiji")



--神鲁肃
tc_shenlusu = sgs.General(extension_tc, "tc_shenlusu", "god", 3)
tc_dingzhouCard = sgs.CreateSkillCard{
	name = "tc_dingzhou",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets < 1 and (to_select:getJudgingArea():length() > 0 or not to_select:getEquips():isEmpty())
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local x, list = math.abs(targets[1]:getEquips():length() + targets[1]:getJudgingArea():length()), sgs.IntList()
		for _, card in sgs.qlist(targets[1]:getCards("ej")) do
			list:append(card:getEffectiveId())
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:deleteLater()
		dummy:addSubcards(list)
		room:obtainCard(source, dummy, false)
		local n, dingzhou = math.min(x, source:getEquips():length() + source:getHandcardNum()), false
		local card_id = room:askForExchange(source, self:objectName(), n, n, true, "", false)
		room:obtainCard(targets[1], card_id, false)
	end,
}
tc_dingzhou = sgs.CreateViewAsSkill{
	name = "tc_dingzhou",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return tc_dingzhouCard:clone()
	end,
	enabled_at_play = function(self, player)
		local players = player:getSiblings()
		for _, p in sgs.qlist(players) do
			if (p:getJudgingArea():length() > 0 or not p:getEquips():isEmpty()) then
				return player:usedTimes("#tc_dingzhou") < 1 and not player:isNude()
			end
		end
	end,
}
tc_tamoCard = sgs.CreateSkillCard{
	name = "tc_tamo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source)	
		local players, target, n = sgs.SPlayerList(), nil, 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isLord() then
				players:append(p)
				n = n + 1
			end
		end
		while n > 0 do
			targets = room:askForPlayersChosen(source, players, self:objectName(), 2, 2, "~shuangren", false, false)
		    for _, p in sgs.qlist(targets) do
				players:removeOne(p)
		    end
			room:swapSeat(targets:last(), targets:first())
			n = n - 2
			if n < 2 then n = 0 end
		end
		room:addPlayerMark(source, "tc_tamo", 2)	
	end,
}
tc_tamo = sgs.CreateViewAsSkill{
	name = "tc_tamo",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return tc_tamoCard:clone()
	end,
	enabled_at_play = function(self, player)
		local players = player:getSiblings()
		return player:getMark("tc_tamo") < 1 and players:length() > 1
	end,
}
tc_zhimeng = sgs.CreateTriggerSkill{
	name = "tc_zhimeng",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
			    local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				    if not p:isKongcheng() then
					    players:append(p)
				    end
			    end
		        if not players:isEmpty() then
				    local target = room:askForPlayerChosen(player, players, self:objectName(), "~shuangren", true, true)
			        if target then
					    room:broadcastSkillInvoke(self:objectName())
			            local dummi, dummy = room:askForExchange(player, self:objectName(), player:getHandcardNum(), 1, false, "", false), room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false, "", false)
						room:obtainCard(player, dummy, false)
			            room:obtainCard(target, dummi, false)
			        end
		        end
		    end
		end
		return false
	end,
}
tc_shenlusu:addSkill(tc_dingzhou)
tc_shenlusu:addSkill(tc_tamo)
tc_shenlusu:addSkill(tc_zhimeng)









sgs.LoadTranslationTable {
    ["FCGod"] = "吧友diy神武将",
    ["GeniusPackageGod"] = "天才包专属神武将",
	["newgodsCard"] = "神武将专属卡牌",

	["#f_Invoke"] = "%from 发动了技能 %arg",
    --==吧友diy神武将==--
	--神司马师(自己DIY)
	["f_shensimashi"] = "神司马师",
	["#f_shensimashi"] = "钢铁之心",
	["designer:f_shensimashi"] = "时光流逝FC",
	["cv:f_shensimashi"] = "官方",
	["illustrator:f_shensimashi"] = "?",
	  --狠决
	["f_henjue"] = "狠决",
	[":f_henjue"] = "出牌阶段限一次，你可以废除一个装备栏，废除一名其他角色的一个装备栏。若如此做，你摸X张牌（X为你已废除的装备栏数）。",
	["f_henjue:0"] = "废除武器栏",
	["f_henjue:1"] = "废除防具栏",
	["f_henjue:2"] = "废除+1马栏",
	["f_henjue:3"] = "废除-1马栏",
	["f_henjue:4"] = "废除宝物栏",
	["$f_henjue1"] = "汝大逆不道，当死无赦！",
	["$f_henjue2"] = "斩草除根，灭其退路！",
	  --平叛
	["f_pingpan"] = "平叛",
	[":f_pingpan"] = "锁定技，当你对其他角色造成伤害时，若该角色有被废除的装备栏，你令此伤害+Y，然后该角色恢复所有装备栏，你随机恢复一个装备栏。（Y为该角色已废除的装备栏数）",
	["$f_pingpan"] = "%to 有 %arg2 个装备栏已废除，故 %from 对其造成的伤害 + %arg2",
	["$f_pingpan1"] = "司马当兴，其兴在吾！",
	["$f_pingpan2"] = "撼山易，撼我司马氏难！",
	  --阵亡
	["~f_shensimashi"] = "吾家夙愿，得偿与否，尽看子上......",
	
	--神刘三刀(自己DIY)
	["f_three"] = "神刘三刀",
	["#f_three"] = "三刀神话",
	["designer:f_three"] = "时光流逝FC",
	["cv:f_three"] = "新三国,官方",
	["illustrator:f_three"] = "三国志12",
	  --三刀
	["f_sandao"] = "三刀",
	["f_sandaooo"] = "三刀",
	["f_sandaoDraw"] = "三刀",
	[":f_sandao"] = "<b>原版：</b>锁定技，你于出牌阶段可使用杀的基础次数改为3；你每连续使用/打出三张【杀】，你摸三张牌。\
	<font color='red'><b>升级：</b></font>觉醒技，准备阶段开始时，若你于本局累计使用或打出了至少三张【杀】，你升级“三刀”（限定技，出牌阶段，你可以视为使用至多三张无距离限制且不计次的【杀】。若你以此法造成有角色死亡，此技能视为未发动过）。\
	出牌阶段结束时，若你已发动过升级版“三刀”，你将“三刀”重置为原版，且若你未能通过发动升级版“三刀”杀死有角色，你删除原版“三刀”中的该部分：你每连续使用/打出三张【杀】，你摸三张牌。",
	["f_sandaoUse"] = "使用杀",
	["f_sandaoResp"] = "打出杀",
	["f_sandaoUaR"] = "",
	["WEhaveLSD"] = "我部悍将刘三刀",
	["$f_sandao"] = "我部悍将刘三刀，三刀之内必斩吕布于马下！",
	    --升级版
	  ["f_sandaoEX"] = "三刀",
	  ["f_sandaoex"] = "三刀",
	  ["f_sandaoEXSlash"] = "三刀",
	  ["f_sandaoexslash"] = "三刀",
	  ["f_sandaoEXkill"] = "三刀",
	  [":f_sandaoEX"] = "限定技，出牌阶段，你可以视为使用至多三张无距离限制且不计次的【杀】。若你以此法造成有角色死亡，此技能视为未发动过。",
	  ["@f_sandaoEX"] = "三刀",
	  ["@f_sandaoEXSlash"] = "你可以视为使用一张无距离限制且不计次的【杀】",
	  ["~f_sandaoEXSlash"] = "选择你想斩于马下的角色，点【确定】；若点【取消】视为你中止【杀】的持续使用",
	    --原版（重置）
	  ["f_sandaoC"] = "三刀",
	  [":f_sandao1"] = "锁定技，你于出牌阶段可使用杀的基础次数改为3；你每连续使用/打出三张【杀】，你摸三张牌。",
	    --原版（重置且阉割）
	  ["f_sandaoD"] = "三刀",
	  [":f_sandao2"] = "锁定技，你于出牌阶段可使用杀的基础次数改为3。",
	  --阵亡
	["~f_three"] = "你特么，吹牛逼能不能别带上我...额啊",
	
	--神刘备-威力加强版(吧友DIY)
	["f_shenliubeiEX"] = "神刘备-威力加强版",
	["&f_shenliubeiEX"] = "神刘备",
	["#f_shenliubeiEX"] = "雷火神剑",
	["designer:f_shenliubeiEX"] = "◆流木野◆",
	["cv:f_shenliubeiEX"] = "官方",
	["illustrator:f_shenliubeiEX"] = "鬼画府",
	  --龙怒
	["f_longnu"] = "龙怒",
	["f_longnu_yang"] = "龙怒·阳",
	["f_longnu_yin"] = "龙怒·阴",
	["f_longnu_DRbuff"] = "龙怒",
	["f_longnu_buffs"] = "龙怒",
	[":f_longnu"] = "转换技，锁定技，出牌阶段开始时：\
	[龙怒·阳]你减1点体力上限并摸一张牌，本回合你手牌中的红色牌和装备牌视为火【杀】且无距离和次数限制，若此牌为红色牌且为装备牌，则附加无视防具效果。\
	[龙怒·阴]你减1点体力上限并摸一张牌，本回合你手牌中的黑色牌和锦囊牌视为雷【杀】且无距离和次数限制，若此牌为黑色牌且为锦囊牌，则附加不可被响应效果。\
	锁定技，当有一名角色在你的回合脱离濒死状态后，你选择一项（1.失去1点体力；2.减1点体力上限），然后摸一张牌。",
	[":f_longnu2"] = "转换技，锁定技，出牌阶段开始时：\
	[龙怒·阳]你减1点体力上限并摸一张牌，本回合你手牌中的红色牌和装备牌视为火【杀】且无距离和次数限制，若此牌为红色牌且为装备牌，则附加无视防具效果。\
	<font color=\"#01A5AF\"><s>[龙怒·阴]你减1点体力上限并摸一张牌，本回合你手牌中的黑色牌和锦囊牌视为雷【杀】且无距离和次数限制，若此牌为黑色牌且为锦囊牌，则附加不可被响应效果。</s></font>\
	锁定技，当有一名角色在你的回合脱离濒死状态后，你选择一项（1.失去1点体力；2.减1点体力上限），然后摸一张牌。",
	[":f_longnu1"] = "转换技，锁定技，出牌阶段开始时：\
	<font color=\"#01A5AF\"><s>[龙怒·阳]你减1点体力上限并摸一张牌，本回合你手牌中的红色牌和装备牌视为火【杀】且无距离和次数限制，若此牌为红色牌且为装备牌，则附加无视防具效果。</s></font>\
	[龙怒·阴]你减1点体力上限并摸一张牌，本回合你手牌中的黑色牌和锦囊牌视为雷【杀】且无距离和次数限制，若此牌为黑色牌且为锦囊牌，则附加不可被响应效果。\
	锁定技，当有一名角色在你的回合脱离濒死状态后，你选择一项（1.失去1点体力；2.减1点体力上限），然后摸一张牌。",
	["f_longnu:1"] = "失去1点体力",
	["f_longnu:2"] = "减1点体力上限",
	["$f_longnu1"] = "兄弟疾难，血债血偿！", --摸牌
	["$f_longnu2"] = "损神熬心，誓报此仇！", --摸牌
	["$f_longnu3"] = "真龙之怒，势如燎原！", --火杀
	["$f_longnu4"] = "雷霆一怒，伏尸百万！", --雷杀
	  --结营（同原版）
	  --阵亡
	["~f_shenliubeiEX"] = "云长，翼德，为兄来也......",
	
	--神董卓(吧友DIY)
	["f_shendongzhuo"] = "神董卓",
	["#f_shendongzhuo"] = "权盛位极",
	["designer:f_shendongzhuo"] = "小珂酱",
	["cv:f_shendongzhuo"] = "官方",
	["illustrator:f_shendongzhuo"] = "秋呆呆",
	  --凶宴
	["f_xiongyan"] = "凶宴",
	["f_xiongyann"] = "凶宴",
	[":f_xiongyan"] = "出牌阶段开始时，你可以进行一次判定，根据判定牌的点数，从你的下家开始以逆时针方向依次点名（若场上存活玩家数少于判定牌的点数，将会循环），若点到的角色：\
	<b>·是你</b>，你视为使用一张【酒】并回复1点体力；\
	<b>·不是你</b>，该角色选择一项：1.失去1点体力并横置武将牌；2.交给你至少两张牌，然后你可以令其摸等量的牌。",
	["$f_xiongyan_self"] = "由 %from 发起的“<font color='yellow'><b>凶宴</b></font>”点名结束，发起者 %from 自己被点到",
	["$f_xiongyan_others"] = "由 %from 发起的“<font color='yellow'><b>凶宴</b></font>”点名结束，%to 被点到",
	["f_xiongyan:1"] = "失去1点体力并横置武将牌",
	["f_xiongyan:2"] = "交给“凶宴”发起者%src至少两张牌",
	["#f_xiongyan"] = "请交给 %src 至少两张牌",
	["@f_xiongyanDraw"] = "[凶宴]令其摸等量的牌",
	["$f_xiongyan1"] = "纵酒畅饮，人生妙哉！", --开始判定
	["$f_xiongyan2"] = "风流人生，不枉此生！", --最终点名到自己
	["$f_xiongyan3"] = "饮尽千杯酒，沙场百斩杀！", --最终点名到别人
	  --迁都
	["f_qiandu-invoke"] = "你可以发动“迁都”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["f_qiandu"] = "迁都",
	[":f_qiandu"] = "限定技，准备阶段开始时，你可以与一名其他角色交换座位，然后你可以依次弃置场上的至多2X张牌（X为你与该角色的距离）。然后你获得技能“析崩”。", --依次：从你开始，以逆时针方向一个个弃置（不包括手牌）
	["@f_qiandu"] = "迁都",
	["@f_qiandu-card"] = "你想发动技能“迁都”吗？",
	["~f_qiandu"] = "迁都：与一名其他角色交换座位，然后弃置场上的牌",
	["QianduAnimate"] = "image=image/animate/f_qiandu.png",
	["$f_qiandu1"] = "大汉权责，由我掌控！",
	["$f_qiandu2"] = "我说的，就是王法！",
	    --析崩
	  ["f_xibeng"] = "析崩",
	  ["f_xibengMaxCards"] = "析崩",
	  [":f_xibeng"] = "锁定技，除非你处于濒死状态，当你即将回复体力时，你防止之，改为摸X+2张牌；你以此法获得的牌不计入你的手牌上限。（X为你即将回复的体力值）",
	  ["$f_xibeng1"] = "朝纲王法，与我无效！",
	  ["$f_xibeng2"] = "天下，有我一人就够了！",
	  --阵亡
	["~f_shendongzhuo"] = "竟中了，这王允老贼的奸计......",
	--==作者的设计思路==--
	--[[首先是体力上限，历史上董卓出兵的时候只有5000兵马，所以设定为5。
	凶宴的灵感来自于董卓在宴会上，随机杀人寻乐的事迹。并且可以和李儒的焚城配合。
	迁都则是董卓把都城从洛阳迁到长安，沿途百姓死亡无数，体现为董卓弃置场上的牌。
	析崩则是突出董卓只顾享乐，而不顾及国家大事的感觉。]]
	--==================--
	
	--神罗贯中(自己DIY)
	["f_shenluoguanzhong"] = "神罗贯中",
	["#f_shenluoguanzhong"] = "演义史诗",
	["designer:f_shenluoguanzhong"] = "时光流逝FC",
	["cv:f_shenluoguanzhong"] = "无",
	["illustrator:f_shenluoguanzhong"] = "QQ-AI作画",
	  --演义
	["f_yanyi"] = "演义",
	["f_yanyiStart"] = "演义",
	["f_yanyiStage"] = "演义",
	[":f_yanyi"] = "游戏开始时，你随机抽取一名未登场的武将牌作为自己的副将（体力上限与体力值保持与游戏开始时相同）。\
	<font color=\"#96943D\"><b>判定阶段开始时，</b></font>出牌阶段限一次，<font color='grey'><b>结束阶段结束时，</b></font>你可以以此法变更你的副将；回合开始前，你须以此法变更你的副将。（体力上限与体力值保持与变更前相同）。",
	  --阵亡
	--["~f_shenluoguanzhong"] = "",
	
	--神左慈(自己DIY)
	["f_shenzuoci"] = "神左慈",
	["#f_shenzuoci"] = "众神大战",
	["designer:f_shenzuoci"] = "时光流逝FC,小珂酱(动画制作)",
	["cv:f_shenzuoci"] = "官方",
	["illustrator:f_shenzuoci"] = "凝聚永恒",
	["f_shenzuociAttack"] = "",
	  --全神
	["f_quanshen"] = "全神",
	[":f_quanshen"] = "锁定技，游戏开始后，场上所有武将势力变更为“神”。",
	["$f_quanshen"] = "（摇铃声）",
	  --役使
	["f_yishi"] = "役使",
	["f_yishiGMS"] = "役使",
	[":f_yishi"] = "游戏开始时，你随机抽取X+1张未登场的神武将牌，依次获得其中X-1名武将的各一个技能。出牌阶段限一次，你可以选择一项：\
	1.弃置X张手牌和一张装备区里的牌，随机抽取X张未登场的神武将牌，获得其中一名武将的一个技能；\
	2.移除一个你以此法获得的技能，随机获得一名神武将的一个技能；\
	3.移除一个你以此法获得的技能，摸两张牌或回复1点体力。\
	（<font color='red'><b>注意：技能可能会重复；</b></font>X为你的当前体力值且至少为1）",
	["f_yishi:1"] = "弃置%src张手牌和一张装备区里的牌：我的回合，抽卡！",
	["f_yishi:2"] = "移除一个你以此法获得的技能，随机获得一名神武将的一个技能",
	["f_yishi:3"] = "移除一个你以此法获得的技能，摸两张牌或回复1点体力",
	["f_yishi:draw"] = "摸两张牌",
	["f_yishi:recover"] = "回复1点体力",
	["$f_yishi1"] = "眼之所见，皆为幻象。",
	["$f_yishi2"] = "幻化之术警之，为政者自当为国为民。",
	  --谜踪
	["f_mizong"] = "谜踪",
	["f_mizongReduceMC"] = "谜踪",
	[":f_mizong"] = "你每受到一次伤害，可以将你的一个技能移交给一名其他角色，若你此次移交的技能不为本技能，你本局游戏的手牌上限-1。",
	["f_mizongRMC"] = "手牌上限-",
	["$f_mizong1"] = "死生存亡，命之形也。",
	["$f_mizong2"] = "放下俗念，为道为仙。",
	  --阵亡
	["~f_shenzuoci"] = "凡俗琐事，不再牵扰......",
	
	--神刘禅(吧友DIY)
	["f_shenliushan"] = "神刘禅",
	["#f_shenliushan"] = "单挑王子",
	["designer:f_shenliushan"] = "luzhuoyuty38,时光流逝FC",
	["cv:f_shenliushan"] = "官方",
	["illustrator:f_shenliushan"] = "真三国无双",
	  --乐极
	["f_leji"] = "乐极",
	[":f_leji"] = --"<font color='red'><b>游戏开始时，若你为“神刘禅”，你可以将武将牌替换为“新神刘禅”；</b></font>" ..
	"当其他角色成为【乐不思蜀】的目标时，若你的判定区没有【乐不思蜀】，你可以将目标改为自己。弃牌阶段开始时，你可以选择一项：\
	1.将一张牌视为【乐不思蜀】对自己使用；\
	2.若自己的判定区没有【乐不思蜀】，将场上的一张【乐不思蜀】移至自己的判定区。",
	--["f_leji:TOnewSLS"] = "[乐极]你可以将武将牌替换为“新神刘禅”，是否替换？",
	["invoke"] = "发动",
	["f_leji:1"] = "将一张牌视为【乐不思蜀】对自己使用",
	["f_leji:2"] = "将场上的一张【乐不思蜀】移至自己的判定区",
	["f_lejiPush"] = "请选择一张牌，将此牌视为【乐不思蜀】对你自己使用",
	["f_lejiIndulgenceMove"] = "请选择场上的一名判定区有【乐不思蜀】的角色，将其【乐不思蜀】移至自己的判定区",
	["$f_leji1"] = "相父不在，奏乐起舞！",
	["$f_leji2"] = "纵情享受，不亦乐乎？",
	  --无忧
	["f_wuyou"] = "无忧",
	["f_wuyouo"] = "无忧",
	--[":f_wuyou"] = "当你的判定区有【乐不思蜀】时，你不能被选择为非转化和非虚拟的【杀】或【决斗】的目标。", --最终还是决定动手了，不然除了当主公就是纯fw一个
	[":f_wuyou"] = "当你的判定区有【乐不思蜀】时，你不能被选择为非转化和非虚拟的【杀】或【决斗】的目标。\
	<font color='red'><b>准备阶段开始时，你可以选择一项：\
	1.(若你有判定区)令一名角色摸X张牌（X为你判定区的牌数+1），然后令技能“乐极”失效直到你的下回合开始；\
	2.(若你有判定区)获得判定区内所有判定牌并回复1点体力，然后令本技能失效直到你的下回合开始；\
	3.(若你无判定区)恢复判定区。</b></font>",
	["f_wuyou:1"] = "令一名角色摸%src张牌，直到下回合开始前“乐极”失效",
	["f_wuyou:2"] = "获得判定区内所有判定牌并回复1点体力，直到下回合开始前“无忧”失效",
	["f_lejiLE"] = "乐极失效",
	["f_wuyouLE"] = "无忧失效",
	["$f_wuyou1"] = "此事爱卿可解，朕先退朝！",
	["$f_wuyou2"] = "有众卿家在，朕大可放心！",
	  --丹砂！
	["f_dansha"] = "单杀",
	[":f_dansha"] = "主公技，当【乐不思蜀】离开你的判定区时，你可以令一名角色失去2点体力。若有角色因此技能死亡，你失去此技能。",
	["f_danshaSiMaZhao"] = "请选择一名角色，让ta笑到心脏骤停",
	--["$f_dansha1"] = "",
	--["$f_dansha2"] = "",
	  --阵亡
	["~f_shenliushan"] = "五十四州王霸业，怎甘抛弃属他人......",
	
	--神曹仁(吧友DIY)
	["f_shencaoren"] = "神曹仁",
	["#f_shencaoren"] = "不灭金身",
	["designer:f_shencaoren"] = "钻洞老虎",
	["cv:f_shencaoren"] = "官方",
	["illustrator:f_shencaoren"] = "嗑嗑一休",
	  --奇阵
	["f_qizhen"] = "奇阵",
	[":f_qizhen"] = "当一名其他角色使用【杀】或锦囊牌指定你为唯一目标<font color='red'><b>时</b></font>，你可以进行判定，若结果为：\
	黑桃：你本回合不能使用或打出手牌；\
	梅花：你摸一张牌；\
	方块：此牌对你无效；\
	红桃：此牌的使用者改为你，该角色成为此牌的目标。",
	["$f_qizhenSpadePZ"] = "%from 布置的 <font color='yellow'><b>[</b></font><font color='blue'><b>奇阵</b></font><font color='yellow'><b>]</b></font> 被 %to 破除，%from 本回合不能使用或打出手牌",
	["$f_qizhenHeartEXchange"] = "%from 布置的 <font color='yellow'><b>[</b></font><font color='blue'><b>奇阵</b></font><font color='yellow'><b>]</b></font> 将法则改变，%from 成为 %card 的使用者，目标为 %to",
	["$f_qizhen1"] = "命中如此啊...", --判定失败(♠)，被破阵
	["$f_qizhen2"] = "以不变应万变！", --判定成功(♣)，摸牌
	["$f_qizhen3"] = "坚持住，援兵即刻就到！", --判定大成功(♦)，化解
	["$f_qizhen4"] = "吾自有办法！", --判定出奇迹(♥)，改变法则
	  --励军
	["f_lijun"] = "励军",
	["f_lijun-invoke"] =  "你可以发动“励军”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":f_lijun"] = "当你受到伤害后，你可以选择一项：1.令一名角色摸X张牌（X为你已损失的体力值）；2.令一名角色将手牌弃至其体力值。\
	若你选择了其他角色，你可以令其获得1点护甲。",
	["f_lijun:1"] = "令一名角色摸等同于你损失体力值数的牌",
	["f_lijun:2"] = "令一名角色将手牌弃至其体力值",
	["@f_lijunGHJ"] = "[励军]令其获得1点护甲",
	["$f_lijun1"] = "冲出重围，血拼到底！", --发动
	["$f_lijun2"] = "正是为国杀敌的时刻，冲啊！", --摸牌
	["$f_lijun3"] = "凭你叫嚣，我自坚守不动！", --弃牌
	["$f_lijun4"] = "齐军徐进，步伍严整，方得所向披靡！", --给护甲
	  --阵亡
	["~f_shencaoren"] = "舍身尽忠孝......",
	--==作者的设计思路==--
	--[[一技能来自三国演义中曹仁在新野摆下八门金锁阵的事迹，突出防中有攻的特点，同时也有可能起到负面效果（被徐庶破阵）。
	二技能思路是在周瑜攻打南郡时，曹仁率数十骑解救牛金等人，作为一个辅助队友的技能，也能对声势浩大的敌人造成破坏。至于为什么受伤发动，emmmm，大魏特色！]]
	--==================--
	
	--神赵云&陈到(自己DIY)
	["f_shenZhaoyunChendao"] = "神赵云＆陈到",
	["&f_shenZhaoyunChendao"] = "神赵云陈到",
	["#f_shenZhaoyunChendao"] = "忠勇相往",
	["designer:f_shenZhaoyunChendao"] = "时光流逝FC",
	["cv:f_shenZhaoyunChendao"] = "官方",
	["illustrator:f_shenZhaoyunChendao"] = "绯雪工作室,匠人绘",
	  --军阵
	["f_junzhen"] = "军阵",
	["f_junzhenAudio"] = "军阵",
	[":f_junzhen"] = "锁定技，你的手牌上限+2<font color='red'><b>；若你的装备区有防具牌，你的手牌上限再+2</b></font>。",
	["$f_junzhen1"] = "龙威虎胆，斩敌破阵！/猛将之烈，统帅之所往！",
	["$f_junzhen2"] = "进退自如，游刃有余！/与子龙忠勇相往，猛烈相合！",
	  --勇魂
	["f_yonghun"] = "勇魂",
	["f_yonghunMoveCardBuff"] = "勇魂",
	["f_yonghunAnaleptic"] = "勇魂",
	["f_yonghunanaleptic"] = "勇魂",
	["f_yonghunAN"] = "勇魂",
	["f_yonghunANClear"] = "勇魂",
	["f_yonghunPeach"] = "勇魂",
	["f_yonghunpeach"] = "勇魂",
	["f_yonghunJink"] = "勇魂",
	["f_yonghunjink"] = "勇魂",
	["f_yonghunSlash"] = "勇魂",
	["f_yonghunslash"] = "勇魂",
	[":f_yonghun"] = "出牌阶段限两次，你可以摸两张牌。然后若你手牌中的这两张牌中有：\
	<font color='red'>[<b>杀</b>]</font>可以对一名其他角色使用之，无距离和次数限制<font color='red'><b>且不计次</b></font>、无视其防具；\
	<font color=\"#00FFFF\">[<b>闪</b>]</font>可以弃置之，然后摸两张牌；\
	<font color='pink'>[<b>桃</b>]</font>可以交给一名其他已受伤角色，然后其使用之；\
	<font color='black'>[<b>酒</b>]</font>可以使用之，不计入使用次数且此阶段你使用的下一张牌不受次数限制。\
	<font color='red'><b>（注：效果发动询问顺序：酒->桃->闪->杀）</b></font>",
	["@f_yonghunAnaleptic"] = "你可以使用这张【酒】",
	["~f_yonghunAnaleptic"] = "此【酒】不计入使用次数，且此阶段你使用的下一张牌不受次数限制",
	["@f_yonghunPeach"] = "你可以选择一名其他已受伤角色，将这张【桃】交给其",
	["~f_yonghunPeach"] = "目标角色获得此【桃】，然后使用之",
	["@f_yonghunJink"] = "你可以弃置这张【闪】，然后摸两张牌",
	["~f_yonghunJink"] = "“无中生有！”",
	["@f_yonghunSlash"] = "你可以选择一名其他可被选择的角色，对其使用这张【杀】",
	["~f_yonghunSlash"] = "此【杀】无距离和次数限制、无视目标角色的防具",
	["$f_yonghun1"] = "策马趋前，斩敌当先！/有我在，无人能伤主公分毫！",
	["$f_yonghun2"] = "遍寻天下，但求一败！/主公的安危，由我来守护！",
	  --阵亡
	["~f_shenZhaoyunChendao"] = "你们谁......还敢再上？/我的白毦兵，再也不能为先帝出力了......",
	
	--神孙尚香(自己DIY)
	["f_shensunshangxiang"] = "神孙尚香",
	["#f_shensunshangxiang"] = "剑定情缘",
	["designer:f_shensunshangxiang"] = "时光流逝FC",
	["cv:f_shensunshangxiang"] = "官方",
	["illustrator:f_shensunshangxiang"] = "鬼画府",
	  --剑缘
	["f_jianyuan"] = "剑缘",
	["f_jianyuangive"] = "剑缘",
	["f_jianyuanthrow"] = "剑缘",
	[":f_jianyuan"] = "你每造成或受到1点伤害，若你的装备区里有牌，你可以弃置所有手牌并摸4+X张牌：将其中的总计三张牌依次选择交给一名【缘】角色/自己或弃置。" ..
	"然后若你此时的手牌数：大于2+Y，你翻面；大于4，你失去1点体力。（X与Y初始为0；若你的装备区里有武器牌，此次X与Y值+1）\
	<font color='green'><b>剑缘录：</b></font>上述内容结算完成后，若你此次以此法给牌的【缘】角色：1.装备区里有武器牌或未被记录入<b>《<font color='green'>剑缘录</font>》</b>，" .. 
	"你可以于令“剑缘”的X或Y值+1；2.若其未被记录入<b>《<font color='green'>剑缘录</font>》</b>，你可以记录之。\
	<font color='red'>*注:【缘】角色-->为其他男性角色，且至少满足其中一项：1.装备区里有牌；2.此次的伤害目标(你造成伤害)/伤害来源(你受到伤害)；3.被记录入<b>《<font color='green'>剑缘录</font>》</b>。</font>",
	[":f_jianyuan11"] = "你每造成或受到1点伤害，若你的装备区里有牌，你可以弃置所有手牌并摸4+X张牌：将其中的总计三张牌依次选择交给一名【缘】角色/自己或弃置。" ..
	"然后若你此时的手牌数：大于2+Y，你翻面；大于4，你失去1点体力。（X与Y初始为0；若你的装备区里有武器牌，此次X与Y值+1）\
	<font color='green'><b>剑缘录：</b></font>上述内容结算完成后，若你此次以此法给牌的【缘】角色：1.装备区里有武器牌或未被记录入<b>《<font color='green'>剑缘录</font>》</b>，" .. 
	"你可以于令“剑缘”的X或Y值+1；2.若其未被记录入<b>《<font color='green'>剑缘录</font>》</b>，你可以记录之。\
	<font color='red'>*注:【缘】角色-->为其他男性角色，且至少满足其中一项：1.装备区里有牌；2.此次的伤害目标(你造成伤害)/伤害来源(你受到伤害)；3.被记录入<b>《<font color='green'>剑缘录</font>》</b>。</font>\
	<font color='green'><b>《剑缘录》：%arg11</b></font>",
	["f_jianyuanX"] = "剑缘X+",
	["f_jianyuanY"] = "剑缘Y+",
	["@f_jianyuangive-card"] = "你可以选择一张“剑缘”牌，交给一名【缘】角色（或留给自己）",
	["~f_jianyuangive"] = "若点【取消】，视为你选择弃牌",
	["@f_jianyuanthrow-card"] = "请弃置一张“剑缘”牌",
	["~f_jianyuanthrow"] = "选择一张牌，点【确定】",
	["f_jianyuan:x"] = "令“剑缘”的X值+1",
	["f_jianyuan:y"] = "令“剑缘”的Y值+1",
	["f_jianyuan:JianYuanLu"] = "剑缘：你是否将 <font color='yellow'>%src</font> 记录入<b>《<font color=\"#00FF00\">剑缘录</font>》</b>？",
	["$f_jianyuan1"] = "彩袖双剑鸾凤鸣，良缘牵线醉黛眉。", --摸牌
	["$f_jianyuan2"] = "地生连理枝，水出并头莲。", --给牌
	["$f_jianyuan3"] = "刀剑花舞，将军看看如何？", --记录
	  --弓漓
	["f_gongli"] = "弓漓",
	[":f_gongli"] = "你的回合内，你距离不大于Z的其他角色视为在你的攻击范围内（Z为回合开始时已记录入<b>《<font color='green'>剑缘录</font>》</b>的角色数+1）；" ..
	"一名已受伤且被记录入<b>《<font color='green'>剑缘录</font>》</b>的角色回合开始时，你可以从牌堆随机使用一张装备牌或摸一张牌，令其回复1点体力。",
	["f_gongli:ue"] = "从牌堆随机使用一张装备牌",
	["f_gongli:dc"] = "摸一张牌",
	["$f_gongli1"] = "花间矫捷，快步无影。",
	["$f_gongli2"] = "体态轻盈，出招无形。",
	  --阵亡
	["~f_shensunshangxiang"] = "四水楚歌起，望乡泪满裳......",
	
	--神于吉(吧友DIY)
	["f_shenyuji"] = "神于吉",
	["#f_shenyuji"] = "变幻万千",
	["designer:f_shenyuji"] = "aGbQbEM",
	["cv:f_shenyuji"] = "官方",
	["illustrator:f_shenyuji"] = "猜猜看啊",
	  --回生
	["f_huisheng"] = "回生",
	[":f_huisheng"] = "当你进入濒死状态时，你可以进行一次判定，若结果为红色/黑色，你回复体力至2点，弃置区域内所有牌并摸四张牌，然后删除“回生”中的一种颜色。",
	["f_huisheng:dr"] = "删除“回生”中的红色",
	["f_huisheng:db"] = "删除“回生”中的黑色",
	["f_huishengRedBan"] = "",
	["$f_huishengRedBan"] = "%from 删除了“<font color='yellow'><b>回生</b></font>”中的 <font color='red'><b>红色</b></font>",
	["f_huishengBlackBan"] = "",
	["$f_huishengBlackBan"] = "%from 删除了“<font color='yellow'><b>回生</b></font>”中的 <font color='black'><b>黑色</b></font>",
	["$f_huisheng1"] = "猜猜看啊？", --判定
	["$f_huisheng2"] = "道法玄机，变幻莫测！", --成功
	["$f_huisheng3"] = "道法玄机，竟被参破！", --失败
	  --妙道
	["f_miaodao"] = "妙道",
	[":f_miaodao"] = "出牌阶段结束时，你可以将至多两张手牌置于武将牌上，称为“道”。你失去最后一张“道”时，你摸两张牌。结束阶段，你摸X张牌（X为你的“道”数<font color='blue'><b>且至多为4</b></font>）。",
	["f_syjDao"] = "道",
	["f_miaodaoPush"] = "请将至多两张手牌置于武将牌上，称为“道”",
	["$f_miaodao1"] = "心之所向，势不可挡！",
	["$f_miaodao2"] = "大道之行，为国为民！",
	  --异法
	["f_yifa"] = "异法",
	[":f_yifa"] = "<font color='green'><b>每轮限两次，</b></font>一名角色的准备阶段，你可以将一张手牌或“道”置于牌堆顶，然后选择移动场上的一张牌或获得当前回合角色区域内的一张牌。",
	["f_yifana"] = "",
	["f_yifa:handcard"] = "将一张手牌置于牌堆顶",
	["f_yifa:pilecard"] = "将一张“道”置于牌堆顶",
	["@f_yifa-Dao"] = "请选择一张“道”，将其置于牌堆顶",
	["~f_yifa"] = "如果这是你的最后一张“道”，它应该将会回到你的手心哦",
	["f_yifa:move"] = "移动场上的一张牌",
	["f_yifa:get"] = "获得当前回合角色区域内的一张牌",
	["f_yifa_Move"] = "你可以选择一名场上有牌的角色",
	["@f_yifa_Move-to"] = "请选择移动的目标角色",
	["$f_yifa1"] = "不识天数，在劫难逃！",
	["$f_yifa2"] = "凡人仇怨，皆由心生！",
	  --阵亡
	["~f_shenyuji"] = "治得了病，治不了心啊......",
	
	--神庞统(吧友DIY)
	["f_shenpangtong"] = "神庞统",
	["#f_shenpangtong"] = "断案如神",
	["designer:f_shenpangtong"] = "luzhuoyuty38",
	["cv:f_shenpangtong"] = "官方,老/新三国",
	["illustrator:f_shenpangtong"] = "凝聚永恒",
	  --凤雏
	["f_fengchu"] = "凤雏",
	[":f_fengchu"] = "回合开始时，你选择三项：\
	1.加1点体力上限；\
	2.回复1点体力；\
	3.摸两张牌；\
	4.本回合“落凤”失效。",
	["f_fengchu:1"] = "加1点体力上限",
	["f_fengchu:2"] = "回复1点体力",
	["f_fengchu:3"] = "摸两张牌",
	["f_fengchu:4"] = "本回合“落凤”失效",
	["$f_fengchu1"] = "朱雀之火，永不熄灭！",
	["$f_fengchu2"] = "太阳终将再度升起！",
	  --神判
	["f_shenpan"] = "神判",
	["f_shenpanTarget"] = "神判",
	[":f_shenpan"] = "出牌阶段，你可以弃置一张牌并指定一名本回合未以此法指定过的角色，执行所有对应效果：\
	其的上个回合：\
	1.若其获得过其他角色的牌<font color='red'><b>或有其他角色的牌被弃置</b></font>，其弃置两张牌；\
	2.若其造成过伤害，其受到无来源的1点伤害；\
	3.若其杀死过其他角色，其失去1点体力。",
	["f_shenpanOne"] = "神判:盗案",
	[":&f_shenpanOne"] = "其于上回合获得过其他角色的牌/有其他角色的牌被弃置",
	["f_shenpanTwo"] = "神判:伤案",
	[":&f_shenpanTwo"] = "其于上回合造成过伤害",
	["f_shenpanThree"] = "神判:命案",
	[":&f_shenpanThree"] = "其于上回合杀死过其他角色",
	["f_shenpanTMG"] = "",
	["$f_shenpan1"] = "李六，你知罪吗？", --老三国
	["$f_shenpan2"] = "区区百里小县，有何难人的事？", --新三国
	  --落凤
	["f_luofeng"] = "落凤",
	[":f_luofeng"] = "锁定技，回合结束时，你进行一次判定：若判定点数为5，你失去所有体力值，失去技能“凤雏”、“落凤”。",
	["f_luofengAnimate"] = "image=image/animate/luofengpo_DiLu.png",
	["$f_luofeng1"] = "我道号“凤雏”，此地名“落凤坡”，难道我此行果真不利？", --老三国(判定)
	["$f_luofeng2"] = "看来，这是上天赐我的葬身之地呀！哈哈哈哈哈哈......", --新三国(中奖)
	  --阵亡
	["~f_shenpangtong"] = "白马...白马...主公的白马！再也不能同你伴随主公，驰骋天下了......", --老三国
	--==作者的设计思路==--
	--[[神判来自一日断百日案首次在蜀展示能力；点数5对应的卢]]
	--==================--
	
	--神蒲元(自己DIY)
	["f_shenpuyuan"] = "神蒲元", --巨匠
	["#f_shenpuyuan"] = "万古神兵",
	["f_shenpuyuanx"] = "神蒲元", --侠匠
	["#f_shenpuyuanx"] = "万古神兵",
	["designer:f_shenpuyuan"] = "时光流逝FC",
	["cv:f_shenpuyuan"] = "官方",
	["illustrator:f_shenpuyuan"] = "M云涯",
	  --天赐
	["f_tianci"] = "天赐",
	["f_tianciStart"] = "天赐",
	["f_tianciATA"] = "天赐",
	[":f_tianci"] = "<b>命运技<font color='red'>[神蒲元]</font>，</b>锁定技，游戏开始时，你将获得一件由上天赐予的“神兵”：【天雷刃】。然后你选择一项：\
	<font color='blue'><b>《侠匠之路》</b></font>：你装备之，成为<b>“<font color='blue'>侠匠</font>”</b>并更换头像。之后你的每个回合开始时，" ..
	"若你没有【天雷刃】，（无论你是否有该技能）你重新获得之。\
	<font color='red'><b>《巨匠之路》</b></font>：你销毁之，成为<b>“<font color='red'>巨匠</font>”</b>并建立<font color='red'>//<b>神兵库</b>//</font>，" ..
	"然后从<font color='red'>//<b>神兵库</b>//</font>中随机获得两张装备牌。\
	<font color='orange'><b>(注：出现重复将以及同将模式中，改为只有其中一位“神蒲元”会触发“天赐”，且玩家优先)</b></font>",
	["f_tianciFate"] = "[天赐]请选择你的命运之路",
	["$f_tianciFate"] = "今日，上天赐予了神蒲元一件“神兵”【天雷刃】，\
	属于神蒲元的命运，从此刻开始......",
	["f_tianciFate:XJ"] = "《侠匠之路》",
	["f_tianciFate:JJ"] = "《巨匠之路》",
	["fXiaJiang"] = "侠匠",
	["fJuJiang"] = "巨匠",
	["#DestroyEqiup"] = "%card 被销毁",
	["$f_tianci1"] = "吹毛断发，血不沾锋，当车鼠辈观之尽皆丧胆！", --侠匠（包括后续重得天雷刃）
	["$f_tianci2"] = "切金断玉，削铁如泥，执吾兵者可为万人之敌！", --巨匠
	  --奇工
	["f_qigong"] = "奇工",
	["mini_f_qigong"] = "奇工",
	["pro_f_qigong"] = "奇工",
	[":f_qigong"] = "出牌阶段限一次，你可以弃置X张装备区里的牌（也可以不弃置），进行“<font color='black'><b>工之锻造</b></font>”：你依次亮出牌堆顶的总计2*（X+1）张牌：" ..
	"若为装备牌，你令一名有对应装备栏的角色使用之（若该角色没有对应的装备栏，改为获得之）；否则你将其置于武将牌上，称为“陨铁”。" ..
	"若此次“<font color='black'><b>工之锻造</b></font>”的结果为你(此次)“锻造”出的装备牌数大于你(此次)获得的“陨铁”数，你于此回合可以再次发动“奇工”。",
	["f_YT"] = "陨铁",
	["f_qigongUse"] = "请选择一名角色，其使用这张【<font color='yellow'><b>%src</b></font>】<br />（若其没有对应装备栏，改为获得）",
	["$f_qigong1"] = "匠心独运，自通器具。",
	["$f_qigong2"] = "能工巧匠，百炼成器。",
	  --灵器
	["f_lingqi"] = "灵器",
	["f_lingqix"] = "灵器", --侠匠
	["f_lingqix_poison"] = "灵器[毒杀]",
	["f_lingqij"] = "灵器", --巨匠
	["f_lingqiSlashs"] = "灵器",
	["f_lingqiSlashMD"] = "灵器",
	[":f_lingqi"] = "出牌阶段，你可以将一张装备牌按以下规则使用：\
	1.若你为<b>“<font color='blue'>侠匠</font>”</b>，当作无距离限制的【<font color=\"#99CC00\">毒杀*</b></font>(黑桃)/冰杀(梅花)/雷杀(方块)/火杀(红桃)】使用。\
	2.若你为<b>“<font color='red'>巨匠</font>”</b>，当作无视防具的普通【杀】使用。\
	<font color=\"#99CC00\">*【<b>毒杀</b>】：与属性【杀】不同的是，其性质等同于普通【杀】，但造成的伤害转化为毒素伤害，且造成伤害后根据目标已损失的体力值，" ..
	"有概率令其失去1点体力。（概率公式：目标已损失的体力值数*20%，至多100%）</font>",
	["$f_lingqi1"] = "良禽择木，佳刃择水。", --侠匠
	["$f_lingqi2"] = "融古铸今，通晓百刃。", --巨匠
	  --神匠
	["f_shenjiang"] = "神匠",
	["f_shenjiangVAE"] = "神匠·视为装备",
	["f_shenjiangSBK"] = "神匠",
	["f_shenjiangsbk"] = "神匠",
	["f_shenjiangAC"] = "神匠",
	[":f_shenjiang"] = "出牌阶段，你可以弃置四张“陨铁”并选择一名角色，进行“<font color=\"#FFFF00\"><b>神之锻造</b></font>”：\
	1.若你为<b>“<font color='blue'>侠匠</font>”</b>，你展示一张手牌并重铸，根据你以此法展示的牌的花色，令该角色视为装备【混毒弯匕[黑桃]/水波剑[梅花]/烈淬刀[方块]/红锻枪[红桃]】直到其回合结束。\
	2.若你为<b>“<font color='red'>巨匠</font>”</b>，你<b>打造</b>出<font color='red'>//<b>神兵库</b>//</font>中的一种装备牌，然后该角色获得，并可立即装备之。",
	["@f_shenjiangRecast"] = "请展示并重铸一张手牌，根据此牌花色令目标获得相应效果",
	["f_shenjiang:"] = "神匠:",
	["$f_shenjiangSBK"] = "通过“<font color=\"#FFFF00\"><b>神之锻造</b></font>”，%from 从 <font color='red'>//<b>神兵库</b>//</font> " ..
	"打造出“<font color='yellow'><b>神兵·%card</b></font>”",
	["@f_shenjiangSBK"] = "请选择<font color='red'>//<b>神兵库</b>//</font>中的一件“<font color='yellow'><b>神兵</b></font>”打造",
	["@f_shenjiangSBK_use"] = "你可以装备这张【<font color='yellow'>%src<b></b></font>】",
	["$f_shenjiang1"] = "蜀江爽烈，正合淬刃，唯神匠可尽其用。", --侠匠
	["$f_shenjiang2"] = "熔金造器，得天独厚，非常法可及也。", --巨匠
	--==【“神兵库”】==--（混毒弯匕、水波剑、烈淬刀、红锻枪；乌铁锁链、五行鹤翎扇、护心镜、黑光铠、天机图、太公阴符：游戏主体已有，就不再写了。）\
	["spy_shenbingku"] = "神兵库",
	["JJ_shenbingku"] = "巨匠·“神兵库”",
	[":spy_shenbingku"] = "神蒲元的<font color='red'>//<b>神兵库</b>//</font>内含<b>22</b>种装备牌（带*的为游戏主体已有的），分别为：\
	↑武器牌：【混毒弯匕*】、【水波剑*】、【烈淬刀*】、【红锻枪*】；【无双方天戟】、【鬼龙斩月刀】、【赤血青锋】、【镔铁双戟】、【乌铁锁链*】、【五行鹤翎扇*】\
	☯防具牌：【玲珑狮蛮带】、【红棉百花袍】、【国风玉袍】、【奇门八阵】、【护心镜*】、【黑光铠*】\
	☆宝物牌：【束发紫金冠】、【虚妄之冕】、【天机图*】、【太公阴符*】、【三略】、【照骨镜】",
	--1.混毒弯匕(已有)
	----
	--2.水波剑(已有)
	----
	--3.烈淬刀(已有)
	----
	--4.红锻枪(已有)
	----
	--5.无双方天戟
	["_f_wushuangfangtianji"] = "无双方天戟", --♦Q
	["Fwushuangfangtianji"] = "无双方天戟",
	[":_f_wushuangfangtianji"] = "装备牌·武器<br /><b>攻击范围</b>：４\
	<b>武器技能</b>：当你使用【杀】对目标角色造成伤害后，可以摸一张牌或弃置其一张牌。",
	["Fwushuangfangtianji:1"] = "摸一张牌",
	["Fwushuangfangtianji:2"] = "弃置%src的一张牌",
	--6.鬼龙斩月刀
	["_f_guilongzhanyuedao"] = "鬼龙斩月刀", --♠5
	["Fguilongzhanyuedao"] = "鬼龙斩月刀",
	[":_f_guilongzhanyuedao"] = "装备牌·武器<br /><b>攻击范围</b>：３\
	<b>武器技能</b>：锁定技，你使用的红色【杀】不能被【闪】响应。",
	--7.赤血青锋
	["_f_chixieqingfeng"] = "赤血青锋", --♠6
	["Fchixieqingfeng"] = "赤血青锋",
	[":_f_chixieqingfeng"] = "装备牌·武器<br /><b>攻击范围</b>：２\
	<b>武器技能</b>：锁定技，你使用的【杀】结算结束前，目标角色不能使用或打出手牌，且此【杀】无视其防具。",
	--8.镔铁双戟
	["_f_bingtieshuangji"] = "镔铁双戟", --♦K
	["Fbingtieshuangji"] = "镔铁双戟",
	["Fbingtieshuangjix"] = "镔铁双戟",
	["FbingtieshuangjiClear"] = "镔铁双戟",
	[":_f_bingtieshuangji"] = "装备牌·武器<br /><b>攻击范围</b>：３\
	<b>武器技能</b>：你的【杀】被抵消后，你可以失去1点体力，然后获得此【杀】并摸一张牌，本回合使用【杀】的次数+1。",
	--9.乌铁锁链(已有)
	----
	--10.五行鹤翎扇(已有)
	----
	--11.玲珑狮蛮带
	["_f_linglongshimandai"] = "玲珑狮蛮带", --♠2
	["Flinglongshimandai"] = "玲珑狮蛮带",
	[":_f_linglongshimandai"] = "装备牌·防具<br /><b>防具技能</b>：当其他角色使用牌指定你为唯一目标后，你可以进行一次判定，若判定结果为红桃，则此牌对你无效。", --“笃烈”？
	--12.红棉百花袍
	["_f_hongmianbaihuapao"] = "红棉百花袍", --♣A
	["Fhongmianbaihuapao"] = "红棉百花袍",
	[":_f_hongmianbaihuapao"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，防止你受到的属性伤害。",
	--13.国风玉袍
	["_f_guofengyupao"] = "国风玉袍", --♠9
	["Fguofengyupao"] = "国风玉袍",
	[":_f_guofengyupao"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，你不能成为其他角色使用普通锦囊牌的目标。",
	--14.奇门八阵
	["_f_qimenbazhen"] = "奇门八阵", --♠2
	["Fqimenbazhen"] = "奇门八阵",
	[":_f_qimenbazhen"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，其他角色使用的【杀】对你无效。",
	--15.护心镜(已有)
	----
	--16.黑光铠(已有)
	----
	--17.束发紫金冠
	["_f_shufazijinguan"] = "束发紫金冠", --♦A
	["Fshufazijinguan"] = "束发紫金冠",
	[":_f_shufazijinguan"] = "装备牌·宝物<br /><b>宝物技能</b>：准备阶段，你可以对一名其他角色造成1点伤害。",
	--18.虚妄之冕
	["_f_xuwangzhimian"] = "虚妄之冕", --♣4
	["Fxuwangzhimian"] = "虚妄之冕",
	["Fxuwangzhimianx"] = "虚妄之冕",
	[":_f_xuwangzhimian"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限-1。",
	--19.天机图(已有)
	----
	--20.太公阴符(已有)
	----
	--21.三略
	["_f_sanlve"] = "三略", --♠5
	["Fsanlve"] = "三略",
	["Fsanlvex"] = "三略",
	["Fsanlvey"] = "三略",
	[":_f_sanlve"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，你的攻击<font color='blue'><s>范围</s></font><font color='red'><b>距离</b></font>+1；" ..
	"你的手牌上限+1；你出牌阶段使用【杀】的次数+1。", --四个字：你是个不够帅的营
	--22.照骨镜
	["_f_zhaogujing"] = "照骨镜", --♦A
	["Fzhaogujing"] = "照骨镜",
	["fzhaogujing"] = "照骨镜",
	["@Fzhaogujing-showcard"] = "你可以展示一张基本牌或普通锦囊手牌，然后可以立即使用之",
	["~Fzhaogujing"] = "注意：只能用来响应而不能主动使用的牌将只会展示，不被允许使用",
	["@Fzhaogujing_use"] = "你可以使用这张【<font color='yellow'><b>%src</b></font>】",
	[":_f_zhaogujing"] = "装备牌·宝物<br /><b>宝物技能</b>：出牌阶段结束时，你可以展示一张基本或普通锦囊手牌，" ..
	"<font color='blue'><s>视为</s></font><font color='red'><b>然后</b></font>你<font color='red'><b>可以</b></font>使用之。",
	--================--
	  --阵亡
	["~f_shenpuyuan"] = "[侠匠]:一生铸兵，何日可见铸剑为犁之景？\
	[巨匠]:望有一日，能铸甲销戈。",
	["~f_shenpuyuanx"] = "一生铸兵，何日可见铸剑为犁之景？",
	
	--神马钧(自己DIY)
	["f_shenmajun"] = "神马钧",
	["#f_shenmajun"] = "鬼斧神工",
	["designer:f_shenmajun"] = "时光流逝FC",
	["cv:f_shenmajun"] = "官方",
	["illustrator:f_shenmajun"] = "第七个桔子",
	  --研发
	["f_yanfa"] = "研发",
	[":f_yanfa"] = "锁定技，游戏开始时，你将所有<font color='gray'><b>“隐藏游戏卡牌”</b></font>加入牌堆。" ..
	"回合开始时，你从牌堆随机获得一张<font color='gray'><b>“隐藏游戏卡牌”</b></font>。" ..
	"<font color='red'>（<font color='gray'><b>“隐藏游戏卡牌”</b></font>范围：<font color='black'>游戏主体(不包括三梳)</font>、" ..
	"<font color=\"#FFFF00\">“各服神武将”扩展包(包括“附赠包”;不包括:实质内容为空白的卡牌,一些不适合加入的卡牌)</font>、" ..
	"<font color=\"#CC99FF\">“海外服”扩展包<b>[作者:lua学生]</b></font>、" ..
	"<font color=\"#66FFFF\">“江山如故”扩展包<b>[作者:小珂酱](不包括:“影”,“蓄谋牌”)</b></font>、" ..
	"<font color=\"#0FFADA\">《太阳神三国杀·天才包》专属卡牌<b>[作者:FC,Maki]</b></font>；" ..
	"若你未装有相应补丁，则补丁中的卡牌不会加入游戏）</font>",
	["f_yanfaAnimate"] = "image=image/animate/f_yanfa.png",
	["$f_yanfa1"] = "吾所欲作者，国之精器、军之要用也。",
	["$f_yanfa2"] = "路未尽，铸不止。",
	  --机神
	["f_jishen"] = "机神",
	["f_jishenBUFF"] = "机神的加护",
	["f_jishenOF"] = "机神",
	[":f_jishen"] = "出牌阶段限一次，你可以令一名角色使用牌堆中的一张由你选择的副类别的装备牌（你从随机给出的X个选项中选择一个，X为你的体力上限且至多为5），" ..
	"然后根据你选择的副类别，其获得对应效果直到其回合结束：\
	1.<b>武器牌，</b>其使用非虚拟非转化牌造成的伤害翻倍；\
	2.<b>防具牌，</b>其受到不因非虚拟非转化牌造成的伤害减半（向下取整）；\
	3.<b>+1马牌，</b>其回复量翻倍；\
	4.<b>-1马牌，</b>其与其他角色的距离减去其装备区牌数的一半（向上取整，至少为1），其使用牌不可被其距离为1的目标角色响应；\
	5.<b>宝物牌，</b>其每使用一张“隐藏游戏卡牌”，摸一张牌。",
	["f_jishen:0"] = "武器牌",
	["f_jishen:1"] = "防具牌",
	["f_jishen:2"] = "+1马牌",
	["f_jishen:3"] = "-1马牌",
	["f_jishen:4"] = "宝物牌",
	["jsweapon"] = "武器加伤",
	["jsarmor"] = "防具减伤",
	["jsdefen"] = "+1马增回",
	["jsoffen"] = "-1马减距",
	["jstrsr"] = "宝物摸牌",
	["$f_jishen1"] = "另辟蹊径博君乐，盛世美景百戏中。",
	["$f_jishen2"] = "机关精巧，将军可看在眼里？",
	  --阵亡
	["~f_shenmajun"] = "污泥覆玉，顽石掩璞，痛哉痛哉！.....",
	
	--神司马炎(吧友DIY)
	  --初版
	["f_shensimayan"] = "神司马炎-初版",
	["&f_shensimayan"] = "神司马炎",
	["#f_shensimayan"] = "晋武大帝",
	["designer:f_shensimayan"] = "aGbQbEM", --“卯兔包”落选稿
	["cv:f_shensimayan"] = "(文字播报)", --在尝试一种全新的方式
	["illustrator:f_shensimayan"] = "率土之滨",
	  --征灭
	["f_zhengmie"] = "征灭",
	[":f_zhengmie"] = "<font color='green'><b>每轮限三次，</b></font>每名角色的准备阶段，你可以令其对一名你指定的角色使用一张无距离限制且不计入次数限制的【杀】。" ..
	"若此【杀】造成伤害，你摸一张牌并获得1枚“征”标记。",
	["fZHENG"] = "征",
	["f_zhengmie-invoke"] = "你可以发动技能“征灭”<br /> 提示：选择一名角色，其成为你令%src使用【杀】的目标",
	["@f_zhengmie-slash"] = "你是否响应“征灭”，对%src使用一张【杀】？",
	["$f_zhengmie1"] = "平定秦凉，安抚边境！",
	["$f_zhengmie2"] = "击灭东吴，一统山河！",
	  --帝运
	["f_diyun"] = "帝运",
	[":f_diyun"] = "觉醒技，准备阶段，若你的“征”标记数至少为3枚，你减1点体力上限，回复1点体力或摸两张牌，获得技能“奢靡”。",
	["f_diyun:rec"] = "回复1点体力",
	["f_diyun:drw"] = "摸两张牌",
	["$f_diyun1"] = "三分归一，帝运龙兴！",
	["$f_diyun2"] = "太康盛世，天下繁荣！",
	    --奢靡
	  ["dy_shemi"] = "奢靡",
	  ["dy_shemiSlashBuff"] = "奢靡",
	  ["dy_shemiDeBuff"] = "奢靡",
	  [":dy_shemi"] = "摸牌阶段开始时，你可以选择至多两项：\
	  1.于此阶段多摸两张牌；\
	  2.出牌阶段可以多使用一张【杀】且使用【杀】的目标上限+1。\
	  你每选择一项，本回合的手牌上限-1；结束阶段，若你没有手牌且装备区里有牌，你弃置一张装备区里的牌。",
	  ["dy_shemi:1"] = "此摸牌阶段多摸两张牌",
	  ["dy_shemi:2"] = "出牌阶段可以多使用一张【杀】且使用【杀】的目标上限+1",
	  ["$dy_shemi1"] = "君臣赛富，纵情奢华！",
	  ["$dy_shemi2"] = "尽收佳丽，羊车巡幸！",
	--
	["f_shensimayan_sktc"] = "神司马炎-技能台词",
	[":f_shensimayan_sktc"] = "\
	【征灭】平定秦凉，安抚边境！/击灭东吴，一统山河！\
	【帝运】三分归一，帝运龙兴！/太康盛世，天下繁荣！\
	【奢靡】君臣赛富，纵情奢华！/尽收佳丽，羊车巡幸！",
	  --阵亡
	["~f_shensimayan"] = "宗室同心，朕的江山定会永世长久......",
	
	  --正式版
	["f_shensimayan_f"] = "神司马炎",
	["#f_shensimayan_f"] = "晋武大帝",
	["designer:f_shensimayan_f"] = "aGbQbEM",
	["cv:f_shensimayan_f"] = "(文字播报)",
	["illustrator:f_shensimayan_f"] = "率土之滨",
	  --征灭
	["f_zhengmie_f"] = "征灭",
	[":f_zhengmie_f"] = "<font color='green'><b>每轮限三次，</b></font>每名角色的准备阶段，你可以令其<b>视为</b>对一名你指定的角色使用一张无距离限制且不计入次数限制的【杀】。" ..
	"若此【杀】造成伤害，你摸一张牌并获得1枚“征”标记。",
	["fZHENGf"] = "征",
	["f_zhengmie_f-invoke"] = "你可以发动技能“征灭”<br /> 提示：选择一名角色，其成为你令%src视为使用【杀】的目标",
	["$f_zhengmie_f1"] = "平定秦凉，安抚边境！",
	["$f_zhengmie_f2"] = "击灭东吴，一统山河！",
	  --帝运+奢靡（同初版）
	  --阵亡
	["~f_shensimayan_f"] = "宗室同心，朕的江山定会永世长久......",
	--
	
	--神刘协(吧友DIY)
	["f_shenliuxie"] = "神刘协",
	["#f_shenliuxie"] = "天命所归",
	["designer:f_shenliuxie"] = "通缉令绘制",
	["cv:f_shenliuxie"] = "官方",
	["illustrator:f_shenliuxie"] = "第七个桔子",
	  --天子
	["f_skysson"] = "天子",
	[":f_skysson"] = "出牌阶段限一次，你可以弃置一张牌并选择一名角色，令其选择是否对另一名你选择的角色使用一张【杀】" ..
	"<font color='red'><b>(注:实际发动时要先选两名角色，然后选择是由其中的哪名角色使用【杀】)</b></font>：若其选“否”，视为你对其使用一张【杀】。" ..
	"每个回合限一次，当你需要使用或打出一张【闪】时，你可以选择一名角色，令其选择是否替你使用或打出一张【闪】：若其选“否”，你获得其区域内的一张牌。",
	["f_skysson-slashfrom"] = "请选择使用【杀】的角色",
	["@f_skysson-slash"] = "你是否遵从“天子”的命令，对%src使用一张【杀】？",
	["f_skysson-usejink"] = "请选择一名角色，询问其是否代替你出【闪】",
	["@f_skysson-jink"] = "你是否遵从“天子”的命令，替%src使用一张【闪】？",
	["$to_f_shenliuxie_fou"] = "%to 没有执行 %from 的要求，选择了<font color='red'><b>否</b></font>",
	["$f_skysson1"] = "大汉天命之传承，皆在吾身！",
	["$f_skysson2"] = "朕乃天子，定得天助！",
	  --国祚
	["f_guozuo"] = "国祚",
	[":f_guozuo"] = "锁定技，游戏开始时，你废除判定区；你的体力上限不会因为其他<font color='blue'><s>角色的</s></font>技能的变化而变化" ..
	"；" ..
	"每当场上一种势力的角色全部阵亡时，你加1点体力上限并回复1点体力，本局摸牌阶段的摸牌数+1。",
	["f_guozuoDraw"] = "国祚摸牌",
	["$f_guozuo1"] = "炎汉的国运，请再帮我一把！",
	["$f_guozuo2"] = "这江山，哪能轻易换主！",
	  --傀儡
	["f_kuilei"] = "傀儡",
	[":f_kuilei"] = "限定技，当你处于濒死状态时，你可以选择一名<font color='red'><b>其他</b></font>角色，其选择是否替你使用一张【桃】：\
	1.若其选“是”，则其获得技能“天子”并获得1枚“挟天子”标记，你将体力回复至体力上限，失去技能“天子”，获得技能“天命”、“密诏”；\
	2.若其选“否”，其弃置所有牌，且当你脱离濒死状态后，此技能重置(视为未发动过)。", --emm...要是自己挟自己的话会不会显得很奇怪？所以后续我还是加了限制只能选其他人
	["@f_kuilei"] = "傀儡",
	["f_shenliuxie_kuilei"] = "傀儡·神刘协",
	["f_Xtz"] = "挟天子",
	["f_kuilei_jieguo"] = "哪位将军，救朕于危急？",
	["@f_kuilei-peach"] = "你是否扶持“傀儡”%src，对其使用一张【桃】？",
	["$f_kuilei1"] = "孤，与将军共进退~", --艹，好屑
	["$f_kuilei2"] = "吾乃真龙天子，岂能坐以待毙？",
	  --汉帝
	["f_handi"] = "汉帝",
	[":f_handi"] = "觉醒技，当有“挟天子”标记的角色死亡时，你获得技能“天子”、“乱击”、“图射”，失去技能“天命”、“密诏”。",
	["f_shenliuxie_handi"] = "汉帝·神刘协",
	["$f_handi1"] = "朕祈上帝诸神，佑我汉室不衰！",
	["$f_handi2"] = "朕乃天命所归，逆臣岂敢无礼！",
	  --阵亡
	["~f_shenliuxie"] = "皇权旁落，忠良尽丧，无人...为朕分忧矣......",
	
	--新神刘禅(对吧友DIY的翻新)
	["f_shenliushan_new"] = "新神刘禅",
	["&f_shenliushan_new"] = "神刘禅",
	["#f_shenliushan_new"] = "单挑皇子",
	["designer:f_shenliushan_new"] = "luzhuoyuty38",
	["cv:f_shenliushan_new"] = "官方",
	["illustrator:f_shenliushan_new"] = "真三国无双6",
	  --乐极+无忧（同原版）
	  --丹砂！！
	["f_dansha_new"] = "单杀",
	[":f_dansha_new"] = "当【乐不思蜀】离开你的判定区时，你可以令一名角色[失去X点体力并弃置X张牌]（X为1；主公技，若你的身份为“主公(包括“主将”和“地主”)”，X值翻倍）。" ..
	"若有角色因此技能死亡，你[失去此技能]（主公技，若你的身份为“主公(包括“主将”和“地主”)”，改为：失去此技能并获得技能“思蜀”）。",
	--["$f_dansha_new1"] = "",
	--["$f_dansha_new2"] = "",
	  --阵亡
	["~f_shenliushan_new"] = "五十四州王霸业，怎甘抛弃属他人......",
	
	--神-曹丕&甄姬(吧友DIY)
	["god_caopi_zhenji"] = "神-曹丕＆甄姬",
	["&god_caopi_zhenji"] = "神曹丕甄姬",
	["#god_caopi_zhenji"] = "洛水多殇",
	["designer:god_caopi_zhenji"] = "俺的西木野Maki(包括lua代码编写)",
	["cv:god_caopi_zhenji"] = "官方",
	["illustrator:god_caopi_zhenji"] = "DH",
	  -->曹丕
	["god_caopi_zhenji_m"] = "神·曹丕",
	["&god_caopi_zhenji_m"] = "神曹丕",
	["#god_caopi_zhenji_m"] = "霸业的继承者",
	["designer:god_caopi_zhenji_m"] = "俺的西木野Maki",
	["cv:god_caopi_zhenji_m"] = "官方",
	["illustrator:god_caopi_zhenji_m"] = "DH",
	  -->甄姬
	["god_caopi_zhenji_f"] = "神·甄姬",
	["&god_caopi_zhenji_f"] = "神甄姬",
	["#god_caopi_zhenji_f"] = "薄幸的美人",
	["designer:god_caopi_zhenji_f"] = "俺的西木野Maki",
	["cv:god_caopi_zhenji_f"] = "官方",
	["illustrator:god_caopi_zhenji_f"] = "DH",
	  --洛殇
	["diy_k_luoshang"] = "洛殇",
	["diy_k_luoshangCard"] = "洛殇",
	[":diy_k_luoshang"] = "①游戏开始时，你可以选择将此武将牌变更为“神·曹丕”或“神·甄姬”，然后你获得3枚“洛殇”标记。回合开始时，你可以进行判定：" ..
	"（“洛殇”判定）若结果为黑色，则你获得1枚“洛殇”标记，且于判定牌生效后你获得之，然后你可以再次发动“洛殇”进行判定。\
	②每当一名其他角色死亡时，你可以获得其所有牌，然后你可以弃置其中所有黑色牌并获得等量枚“洛殇”标记，然后你可以发动一次“洛殇”判定。\
	③<font color='green'><b>出牌阶段限X次，</b></font>若X大于0，你可以弃置1枚“洛殇”标记进行一次“洛殇”判定。在你的“洛殇”判定牌生效前，你可以弃置1枚“洛殇”标记，" ..
	"然后从牌堆顶亮出一张牌代替之。（X为你的“洛殇”标记数）",
	["gcz_losehp"] = "失去体力",
	["gcz_losemark"] = "弃置标记",
	["gcz_throwBlack"] = "弃置黑色牌",
	  ["gcz_throwBlack:yes"] = "是（弃置所有黑色牌并获得等量枚“洛殇”标记）",
	  ["gcz_throwBlack:no"] = "否（不弃牌）",
	["gcz_skinchange"] = "选择武将性别", --"变更武将性别",
	  ["gcz_skinchange:caopi"] = "男（神·曹丕）",
	  ["gcz_skinchange:zhenji"] = "女（神·甄姬）",
	["$diy_k_luoshang1"] = "群燕辞归鹄南翔，念君客游思断肠。", --神·曹丕1
	["$diy_k_luoshang2"] = "霜露纷兮交下，木叶落兮凄凄。", --神·曹丕2
	["$diy_k_luoshang3"] = "翩若惊鸿，婉若游龙。", --神·甄姬1
	["$diy_k_luoshang4"] = "神光离合，乍阴乍阳。", --神·甄姬2
	  --阵亡
	["~god_caopi_zhenji"] = "(神·曹丕)建平所言八十，谓昼夜也，吾其决矣……/(神·甄姬)揽騑辔以抗策，怅盘桓而不能去。",
	["~god_caopi_zhenji_m"] = "建平所言八十，谓昼夜也，吾其决矣……", --神·曹丕
	["~god_caopi_zhenji_f"] = "揽騑辔以抗策，怅盘桓而不能去。", --神·甄姬
	
	--神袁绍(吧友DIY)
	["f_shenyuanshao"] = "神袁绍",
	["#f_shenyuanshao"] = "一时之杰",
	["designer:f_shenyuanshao"] = "张一舟2012",
	["cv:f_shenyuanshao"] = "官方",
	["illustrator:f_shenyuanshao"] = "铁杵文化",
	  --名望
	["f_mingwang"] = "名望",
	["f_mingwangMaxCards"] = "名望",
	[":f_mingwang"] = "锁定技，游戏开始时，你令所有其他角色选择一项：1.摸两张牌，获得1枚“势”标记；2.弃置两张牌。\
	锁定技，摸牌阶段，你改为摸X+1张牌；你的手牌上限+X；你对非“势”角色造成的伤害+1。（X为场上的“势”标记数）\
	<font color='red'><b>◆注：有“势”标记的角色称为【“势”角色】；没有“势”标记的角色称为【非“势”角色】</b></font>",
	["f_ysS"] = "势",
	["f_mingwang:1"] = "摸两张牌，成为“势”角色",
	["f_mingwang:2"] = "弃两张牌，仍为非“势”角色",
	["$f_mingwangMD"] = "因为“<font color='yellow'><b>名望</b></font>”的效果，%from 对【<font color='yellow'><b>非“<font color='orange'>势</font>”角色</b></font>】%to " ..
	"造成的伤害+1",
	["$f_mingwang1"] = "诸公，皆吾功成元勋也！", --角色选择获得“势”标记
	["$f_mingwang2"] = "吾袁门之裔，定一统天下！", --额外摸牌、享受手牌上限增益
	["$f_mingwang3"] = "乘敌乱而击之，必大获全胜！", --加伤
	["$f_mingwang4"] = "凶顽之贼，皆以乱箭射之！", --加伤
	  --寡谋
	["f_guamou"] = "寡谋",
	[":f_guamou"] = "锁定技，当你对非“势”角色使用<font color='red'><b>基本牌或普通锦囊牌</b></font>时，额外指定所有“势”角色为目标。",
	["$f_guamou1"] = "弓箭手准备，放！",
	["$f_guamou2"] = "箭如雨下，士众崩溃！",
	  --非势
	["f_feishi"] = "非势",
	[":f_feishi"] = "当你对“势”角色造成伤害后，其可获得你两张牌并移除其所有“势”标记；“势”角色死亡后，你失去1点体力。",
	["f_feishi-leave"] = "你可以拿走盟主%src的两张牌，之后不再是“势”角色",
	["$f_feishi1"] = "这可是与生俱来的血统！",
	["$f_feishi2"] = "这...不可能！",
	  --阵亡
	["~f_shenyuanshao"] = "莫非...最后的赢家是......",
	
	--神袁绍-江山如梦(吧友DIY)
	["f_shenyuanshao_if"] = "神袁绍-江山如梦",
	["&f_shenyuanshao_if"] = "神袁绍IF", --梦袁绍√
	["#f_shenyuanshao_if"] = "一统北方",
	["designer:f_shenyuanshao_if"] = "通缉令绘制",
	["cv:f_shenyuanshao_if"] = "官方",
	["illustrator:f_shenyuanshao_if"] = "枭瞳,墨心绘意",
	  --优柔
	["f_yourou"] = "优柔",
	[":f_yourou"] = "锁定技，你使用基本牌时，有一半的概率取消之。",
	["$f_yourou1"] = "",
	["$f_yourou2"] = "",
	  --寡断
	["f_guaduan"] = "寡断",
	[":f_guaduan"] = "锁定技，你使用锦囊牌时，有一半的概率取消之。",
	["$f_guaduan1"] = "",
	["$f_guaduan2"] = "",
	--//作者注：优柔寡断，凤羽鸡胆。
	  --利剑
	["f_lijian"] = "利剑",
	["f_lijian_limited"] = "钝剑",
	[":f_lijian"] = "当你成为其他角色使用牌(以下称为:太师牌)的唯一目标时，你可以立即展示一张【杀】，该角色选择是否取消对你使用此“太师牌”：\
	若其选“是”，本回合该角色使用牌时无法再选择你为目标；\
	若其选“否”，则你将以此法展示的【杀】置于武将牌上，待该“太师牌”结算完成后，你本回合“优柔”失效并立即对其使用该【杀】，且该【杀】造成的伤害+1。",
	--//作者注：<名场面>：董卓：尔要试试我的宝剑是否锋利吗？袁绍：我剑也未尝不利！
	["@f_lijian-SlashShow"] = "[利剑]你可以展示一张【杀】",
	["f_lijian:1"] = "【是】取消对其使用此“太师牌”",
	["f_lijian:2"] = "【否】正常对其使用此“太师牌”",
	["$to_f_lijian_fou"] = "%to 并没有把 %from 的警告放在眼里，选择了<font color='red'><b>否</b></font>",
	["$f_lijian1"] = "哼！天下之事，在皇帝，在诸位忠臣，你？只不过是一篡逆之辈！",
	["$f_lijian2"] = "我剑也未尝不利！",
	  --乱击
	["f_luanji"] = "乱击",
	["f_luanjiBuff"] = "乱击",
	[":f_luanji"] = "出牌阶段限一次，你可以弃置2~4张颜色相同的牌，视为使用了一张【万箭齐发】，若你以此法弃置了：\
	至少三张牌，伤害+1；\
	至少四张牌：本回合“寡断”失效且其他角色无法响应此牌。",
	["f_luanji11"] = "乱击",
	[":f_luanji11"] = "出牌阶段，你可以弃置2~4张颜色相同的牌，视为使用了一张【万箭齐发】，若你以此法弃置了：\
	至少三张牌，伤害+1；\
	至少四张牌：本回合“寡断”失效且其他角色无法响应此牌。",
	["$f_luanji1"] = "箭阵先行，扫除障碍！",
	["$f_luanji2"] = "箭出如雨，西凉必溃！",
	  --会盟
	["f_huimeng"] = "会盟",
	["lhp_f_huimeng"] = "会盟",
	["lcd_f_huimeng"] = "会盟",
	["f_huimengBuff"] = "会盟",
	[":f_huimeng"] = "出牌阶段，你可以失去1点体力或弃置一张牌，获得1枚“盟”标记；摸牌阶段，你的摸牌数+[X/3](向下取整)。" ..
	"当一名角色进入濒死阶段时，你可以获得其至多X/3张牌(向下取整)，然后你弃置全部“盟”标记。" ..
	"当你受到伤害时，若你的“盟”标记数不少于6枚，你可以弃置X/2枚“盟”标记(向下取整)，防止此次伤害。（X为你的“盟”标记数且至多为18）",
	["f_huimeng11"] = "会盟",
	[":f_huimeng11"] = "摸牌阶段，你的摸牌数+[X/3](向下取整)。（X为你的“盟”标记数且至多为18）",
	["fUnited"] = "盟",
	["@f_huimeng-crzw"] = "[会盟]获得其牌",
	["@f_huimeng-myzd"] = "[会盟]防止伤害",
	["$f_huimeng1"] = "诸侯会盟，合兵伐董！",
	["$f_huimeng2"] = "董贼祸国，忠良之裔当首举义旗！",
	  --名门
	["f_mingmen"] = "名门",
	[":f_mingmen"] = "觉醒技，当你拥有18枚“盟”标记时，你失去“优柔”、“寡断”，【<b>江山如梦：</b>且若你的游戏版本为《天才包》，你切换游戏背景音乐为[神袁绍-江山如梦]的专属BGM】" ..
	"然后将“乱击”的发动条件修改为“出牌阶段”，将“会盟”修改为：摸牌阶段，你的摸牌数+[X/3](向下取整)。（X为你的“盟”标记数且至多为18）",
	["$f_mingmen1"] = "累世公卿立大名，少年意气自纵横！",
	["$f_mingmen2"] = "袁氏公侯之家，匡汉大业义不容辞！",
	  --阵亡
	["~f_shenyuanshao_if"] = "踏遍塞北，秋风猎马；遥望江南，春雨杏花......",
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--==天才包专属神武将==--
	--神祝融(Maki设计)
	["tc_shenzhurong"] = "神祝融[天才包]",
	["&tc_shenzhurong"] = "神祝融",
	["#tc_shenzhurong"] = "巾帼豪迈",
	["designer:tc_shenzhurong"] = "俺的西木野Maki",
	["cv:tc_shenzhurong"] = "官方",
	["illustrator:tc_shenzhurong"] = "第七个桔子/枭瞳",
	  --巨象 势吞山河
	["tc_juxiang_stsh"] = "巨象 势吞山河",
    [":tc_juxiang_stsh"] = "锁定技，【南蛮入侵】对你无效。其他角色使用的【南蛮入侵】在结算完毕后置入弃牌堆时，你获得之。回合结束时，若你于回合内未使用过【南蛮入侵】，" ..
	"你视为使用一张【南蛮入侵】。",
	["$tc_juxiang_stsh1"] = "南蛮巨象，开疆辟土！",
	["$tc_juxiang_stsh2"] = "腾骞征敌，肆意沙场！",
	  --烈锋 势破万敌
	["tc_liefeng_spwd"] = "烈锋 势破万敌",
	[":tc_liefeng_spwd"] = "当你使用【杀】后，你可以与目标角色拼点，若你赢，此【杀】结算结束后，你对另一名其他角色造成随机1~3点随机属性伤害且目标角色失去1点体力。",
	["@tc_liefeng_spwd-invoke"] = "你发动了“烈锋”拼点，请选择一张手牌<br/> <b>操作提示</b>: 选择一张手牌→点击确定<br/>",
	["$tc_liefeng_spwd1"] = "葵花映日熠生辉，烈刃炽火燃赤金！",
	["$tc_liefeng_spwd2"] = "弯刃折衰枝，金葵向日倾！",
	  --长标 势气如虹
	["tc_changbiao_sqrh"] = "长标 势气如虹",
	[":tc_changbiao_sqrh"] = "出牌阶段限一次，你可将任意张手牌当无距离限制的【杀】对任意名其他角色使用。若此【杀】造成过伤害，此【杀】结算结束后你摸等量的牌。",
	["$tc_changbiao_sqrh1"] = "今日就让这群汉人，长长见识！",
	["$tc_changbiao_sqrh2"] = "长矛、飞刀、烈火，都来吧！",
	  --阵亡
	["~tc_shenzhurong"] = "霜露萧瑟，花败枝折......",
	
	--神貂蝉(Maki设计,来自Maki·DIY包)
	["diy_k_shendiaochan"] = "神貂蝉[天才包]",
	["&diy_k_shendiaochan"] = "神貂蝉",
	["#diy_k_shendiaochan"] = "舞惑群心",
	["designer:diy_k_shendiaochan"] = "Maki·DIY包",
	["cv:diy_k_shendiaochan"] = "官方",
	["illustrator:diy_k_shendiaochan"] = "云涯",
	  --闭月
	["diy_god_biyue"] = "闭月",
	[":diy_god_biyue"] = "锁定技，其他非主公角色的身份始终对你可见。",
	["$diy_god_biyue1"] = "英雄轻抚素手，小女既怯且羞。",
	["$diy_god_biyue2"] = "丹唇带笑斟美酒，美目含情送秋波。",
	  --魅魂
	["diy_k_meihun"] = "魅魂",
    [":diy_k_meihun"] = "出牌阶段限一次，你可以选择一张牌，然后选择一名其他角色，若该角色：\
	1.有手牌，其获得此牌后展示其所有手牌，然后你获得其手牌中与此牌花色相同的所有牌；\
	2.没有手牌，你弃置你选择的牌并对其造成随机1~3点伤害（你以此法造成的伤害无视其拥有的技能），然后此技能视为未使用过。",
	["$diy_k_meihun1"] = "嗯哼哼~巧施美色，诱敌两伤。",
	["$diy_k_meihun2"] = "轻撩面纱月色会，娇声低泣蛙声垂。",
	["$diy_k_meihun3"] = "明月常在，容颜易逝。",
	  --惑心
	["diy_k_huoxin"] = "惑心",
	["@diy_k_huoxin"] = "你可以发动“惑心”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	["obtainequip"] = "获得一张装备牌",
	["obtainhand"] = "获得一张手牌",
	[":diy_k_huoxin"] = "每名角色的结束阶段开始时，你可以交给其一张牌，若如此做，则你摸一张牌并获得其一张牌，若未如此做或该角色为你，则你改为摸两张牌。",
	["$diy_k_huoxin1"] = "得君垂怜，妾身足矣。",
	["$diy_k_huoxin2"] = "焚香对月，乞之以心。",
	  --阵亡
	["~diy_k_shendiaochan"] = "一朝春尽红颜老，花落人亡两不知。",
		
	--神马超(Maki设计,来自Maki·DIY包)
	["diy_k_shenmachao"] = "神马超[天才包]",
	["&diy_k_shenmachao"] = "神马超",
	["#diy_k_shenmachao"] = "神威天将军",
	["designer:diy_k_shenmachao"] = "Maki·DIY包",
	["cv:diy_k_shenmachao"] = "官方",
	["illustrator:diy_k_shenmachao"] = "biou09",
	  --狩骊
	["diy_k_shouli"] = "狩骊",
	[":diy_k_shouli"] = "当你需要使用或打出【杀】/【闪】时，你选择一项：1.获得其他角色的一张牌(若你为使用【杀】，则其为【杀】的目标)；2.弃置自己的一张牌。若如此做，你视为使用" ..
	"或打出【杀】（以此法使用的【杀】不计入使用次数、无视距离限制，且令目标技能无效直至此【杀】结算完成时）/打出【闪】。" ..
	"<font color='blue'><b>然后你删除该项直到当前回合结束。</b></font>",
	["$diy_k_shouli1"] = "赤骊骋疆，巡狩八荒！",
	["$diy_k_shouli2"] = "长缨在手，百骥可降！",
	["$diy_k_shouli3"] = "敢缚苍龙擒猛虎，一枪纵横定天山！",
	["$diy_k_shouli4"] = "马踏祁连山河动，兵起玄黄奈何天！",
	  --横骛
	["diy_k_hengwu"] = "横骛",
	[":diy_k_hengwu"] = "<font color='blue'><b>每个回合每种花色各限一次，</b></font>当你使用或打出牌后，你可以弃置任意张与此牌花色相同的牌（可以不弃）" ..
	"并摸等于你弃置的牌数的牌，且你以此法摸牌时额外摸一张牌。",
    ["@hengwuu"] = "你可以弃置任意张 %src 牌并摸等于(弃置数量 + %arg )张牌",
	["$diy_k_hengwu1"] = "横枪立马，独啸秋风！",
	["$diy_k_hengwu2"] = "世皆彳亍，唯我纵横！",
	["$diy_k_hengwu3"] = "雷部显圣，引赤电为翼，铸霹雳成枪！",
	["$diy_k_hengwu4"] = "一骑破霄汉，饮马星河，醉卧广寒！",
	  --阵亡
	["~diy_k_shenmachao"] = "离群之马，虽强亦亡......",
	
	--神裴秀(FC设计)
	["tc_shenpeixiu"] = "神裴秀[天才包]",
	["&tc_shenpeixiu"] = "神裴秀",
	["#tc_shenpeixiu"] = "天才数学家",
	["designer:tc_shenpeixiu"] = "时光流逝FC",
	["cv:tc_shenpeixiu"] = "官方",
	["illustrator:tc_shenpeixiu"] = "网络",
	  --制图
	["tc_zhitu"] = "制图",
	["tc_zhituMAX"] = "制图",
    [":tc_zhitu"] = "锁定技，你使用或打出牌时，若此牌的点数是X的约数/倍数，你从牌堆中随机获得一张点数为X的倍数/约数的牌。\
	转换技，锁定技，①你使用点数为X的约数的牌无距离限制，使用点数为X的倍数的牌无次数限制；②你使用点数为X的倍数的牌无距离限制，使用点数为X的约数的牌无次数限制。\
	（X为你使用或打出的上一张牌的点数<font color='red'><b>；注意：仅使用牌才转换状态</b></font>）",
	[":tc_zhitu1"] = "锁定技，你使用或打出牌时，若此牌的点数是X的约数/倍数，你从牌堆中随机获得一张点数为X的倍数/约数的牌。\
	转换技，锁定技，①你使用点数为X的约数的牌无距离限制，使用点数为X的倍数的牌无次数限制<font color=\"#01A5AF\"><s>；②你使用点数为X的倍数的牌无距离限制，使用点数为X的约数的牌无次数限制</s></font>。\
	（X为你使用或打出的上一张牌的点数<font color='red'><b>；注意：仅使用牌才转换状态</b></font>）",
	[":tc_zhitu2"] = "锁定技，你使用或打出牌时，若此牌的点数是X的约数/倍数，你从牌堆中随机获得一张点数为X的倍数/约数的牌。\
	转换技，锁定技，<font color=\"#01A5AF\"><s>①你使用点数为X的约数的牌无距离限制，使用点数为X的倍数的牌无次数限制；</s></font>②你使用点数为X的倍数的牌无距离限制，使用点数为X的约数的牌无次数限制。\
	（X为你使用或打出的上一张牌的点数<font color='red'><b>；注意：仅使用牌才转换状态</b></font>）",
	["$tc_zhitu"] = "复设五等之制，以解天下土崩之势/表为建爵五等，实则藩卫帝室。",
	  --六体
	["tc_liuti"] = "六体",
	[":tc_liuti"] = "出牌阶段，你可以弃置至少两张牌，然后从{牌堆+弃牌堆}中随机获得Y-1张点数之和为Z的倍数的牌（Y为你以此法弃置的牌数；Z为你弃置的牌的点数之和除以X的余数）。",
	  --挖坑点：如果得出的余数为0，因为0没有倍数，所以结果就会是什么都得不到。
	["$tc_liuti"] = "制图之体有六，缺一不可言精/图设分率，则宇内地域皆可给于一尺。",
	  --阵亡
	["~tc_shenpeixiu"] = "抱歉张梁大人，没能让你使出全力......",
	
	--神-冉·阿让(FC设计)
	["tc_godJeanValjean"] = "神-冉·阿让[天才包]", --取自//在米里哀主教的引导下，冉·阿让得到自我救赎，痛改前非，走上探寻人性光辉之路//的故事情节。
	["&tc_godJeanValjean"] = "神冉阿让",
	["#tc_godJeanValjean"] = "悲惨世界",
	["designer:tc_godJeanValjean"] = "时光流逝FC,维克多·雨果",
	["cv:tc_godJeanValjean"] = "电影(音乐剧)《悲惨世界》",
	["illustrator:tc_godJeanValjean"] = "休·杰克曼",
	  --苦旅
	["tc_kulv"] = "苦旅",
	["tc_kulvv"] = "苦旅",
	[":tc_kulv"] = "锁定技，回合开始时，你失去1点体力；回合结束时，你回复1点体力。锁定技，当你的体力值变化后，你摸一张牌。\
	-----\
	<font color='orange'>[苦旅-光明之旅]锁定技，回合开始时，若你的体力值大于1，你失去1点体力；回合结束时，你选择一名角色，令其回复1点体力。锁定技，当你的体力值变化后，你摸一张牌。</font>\
	-----\
	<font color='purple'>[苦旅-黑暗之旅]锁定技，回合开始时，你受到1点无来源的伤害；回合结束时，你选择对一名角色造成1点伤害。锁定技，当你的体力值变化后，你摸一张牌。</font>",
	--
	[":tc_kulv1"] = "锁定技，回合开始时，若你的体力值大于1，你失去1点体力；回合结束时，你选择一名角色，令其回复1点体力。锁定技，当你的体力值变化后，你摸一张牌。",
	[":tc_kulv2"] = "锁定技，回合开始时，你受到1点无来源的伤害；回合结束时，你选择对一名角色造成1点伤害。锁定技，当你的体力值变化后，你摸一张牌。",
	["tc_kulv-lightREC"] = "[苦旅-光明之旅]请选择一名角色，令其回复1点体力",
	["tc_kulv-darkDMG"] = "[苦旅-黑暗之旅]请选择一名角色，对其造成1点伤害",
	["$tc_kulv1"] = "（背景为已成为市长马德兰的冉·阿让救助被货拉车压在底下的人）————好了，好了。", --苦旅-光明之旅：回复
	["$tc_kulv2"] = "如果人生还有别的选择，20年前我就错失良机，我的人生注定是场打不赢的败仗，他们给我号码的那一刻————冉·阿让就死了，" ..
	"他们用铁链锁住我让我自生自灭，只因我偷了一口面包...", --苦旅-黑暗之旅：伤害
	  --洗礼
	["tc_xili"] = "洗礼",
	[":tc_xili"] = "<b>命运技<font color='red'>[神-冉·阿让]</font>，</b>其他角色的回合开始时，你可以获得当前回合角色的一张牌。然后其可以选择：" ..
	"1.对你使用一张【杀】，然后你获得1枚“罪孽”标记；2.交给你一张牌并令你回复1点体力，然后你获得1枚“洗礼”标记。\
	<font color='orange'><b>《得到救赎，走向光明》</b></font>：回合开始前，若你的“洗礼”标记数至少为2枚且“罪孽”标记数少于2枚，你清除所有“罪孽”和“洗礼”标记" ..
	"并弃X张牌（X为你以此法清除的“罪孽”标记数）、修改“苦旅”(->“苦旅-光明之旅”)，然后失去此技能并获得技能“界仁德”。\
	<font color='purple'><b>《悲惨世界，无尽黑暗》</b></font>：回合开始前，若你的“罪孽”标记数至少为2枚且“洗礼”标记数少于2枚，你清除所有“洗礼”标记" ..
	"并摸Y张牌（Y为你以此法清除的“洗礼”标记数）、修改“苦旅”(->“苦旅-黑暗之旅”)，然后失去此技能并获得技能“奇袭”。",
	["tc_xili:1"] = "【抓捕】对其使用一张【杀】",
	["tc_xili:2"] = "【宽恕】交给其一张牌并令其回复1点体力",
	["@tc_xili-slash"] = "[洗礼-抓捕]请对 %src 使用一张【杀】",
	["#tc_xili-give"] = "[洗礼-宽恕]你将交给 %src 一张牌并令其回复1点体力",
	["tcxl_zuinie"] = "罪孽",
	["tcxl_xili"] = "洗礼",
	["$tc_xiliLightWay"] = "《得到救赎，走向光明》",
	["$tc_xiliDarkFate"] = "《悲惨世界，无尽黑暗》",
	["tc_xiliLight"] = "洗礼-光明",
	["tc_xiliDark"] = "洗礼-黑暗",
	["$tc_xili1"] = "但我的朋友啊，你走得如此匆忙，恐怕忘拿了东西。你忘了，我还给了你这些————怎能落下最好的两件？", --被偷牌后，选择“宽恕”
	["$tc_xili2"] = "我要逃离那个世界，逃离冉·阿让的世界，冉·阿让不复存在了！新的篇章必将展开！————", --得到救赎，走向光明
	  --阵亡
	["~tc_godJeanValjean"] = "现在你们都在，重回我的身边；现在我可以瞑目了，我这一生已经满足......",
	
	--==《各服神武将·神明陨落之日》分界线==--
	
	--神吕布(Maki设计)
	["tc_shenlvbu"] = "神吕布[天才包]",
	["&tc_shenlvbu"] = "神吕布",
	["#tc_shenlvbu"] = "修罗魔道",
	["designer:tc_shenlvbu"] = "俺的西木野Maki",
	["cv:tc_shenlvbu"] = "官方",
	["illustrator:tc_shenlvbu"] = "英雄杀", --蛇年限定吕布
	  --狂暴
	["tc_kuangbao"] = "狂暴",
	[":tc_kuangbao"] = "锁定技，游戏开始时，你获得6枚“暴怒”标记；每当你造成或受到1点伤害后，你获得1枚“暴怒”标记。",
	["$tc_kuangbao1"] = "战神降世，神威再临！",
	["$tc_kuangbao2"] = "战神既出，谁与争锋？",
	  --无谋
	["tc_wumou"] = "无谋",
	["tc_wumou_damage"] = "无谋",
	["wrath_slash"] = "刺杀",
	["@tc_wumou-invoke"] = "你需弃置一张【闪】，否则你无法响应此【刺杀】",
	[":wrath_slash"] = "当你使用【刺杀】时，其需弃置一张牌，否则此【刺杀】无法被响应。",
	[":tc_wumou"] = "锁定技，你所有的锦囊牌、装备牌、【杀】均视为【刺杀】，你使用以此法转化的【刺杀】无距离和次数限制。" ..
	"当你使用以此法转化的【刺杀】时，可以弃置1枚“暴怒”标记，令此【刺杀】无视目标防具且目标技能无效至此【刺杀】结算完成时。",
	["$tc_wumou1"] = "杂鱼们，都去死吧！",
	["$tc_wumou2"] = "竟想赢我？痴人说梦！",
	  --无前
	["tc_wuqian"] = "无前",
	[":tc_wuqian"] = "锁定技，当你使用【杀】指定一名角色为目标后，你须弃置2枚“暴怒”标记，令该角色需连续使用两张【闪】才能抵消；" ..
	"当你使用【决斗】指定目标或成为【决斗】指定的目标时，你须弃置2枚“暴怒”标记，令与你进行“决斗”的角色每次需连续打出两张【杀】。",
	["$tc_wuqian1"] = "萤烛之火，也敢与日月争辉！？",
	["$tc_wuqian2"] = "我不会输给任何人！",
	  --神愤
	["tc_shenfen"] = "神愤",
	[":tc_shenfen"] = "出牌阶段限一次，你可以弃置6枚“暴怒”标记，若如此做，所有其他角色各受到1点伤害、弃置其区域内的所有牌。" ..
	"然后当你通过发动“无谋”于此回合内造成伤害时，你可以防止此伤害并令目标进行一次判定，若判定结果不为黑桃，你回复1点体力（若未受伤则改为摸一张牌）。",
	["$tc_shenfen1"] = "准备受死吧！",
	["$tc_shenfen2"] = "鼠辈，螳臂当车！",
	  --阵亡
	["~tc_shenlvbu"] = "虎牢关...失守了......",
	
	--神左慈(Maki设计)
	["tc_shenzuoci"] = "神左慈[天才包]",
	["&tc_shenzuoci"] = "神左慈",
	["#tc_shenzuoci"] = "迷幻仙道",
	["designer:tc_shenzuoci"] = "俺的西木野Maki",
	["cv:tc_shenzuoci"] = "官方",
	["illustrator:tc_shenzuoci"] = "JanusLausDeo", --皮肤：幻化众生
	  --化身
	["tc_huashen"] = "化身",
	[":tc_huashen"] = "【出牌阶段限一次，】你可以变更为一个与你所属势力不同的<font color='red'><b>(官方)</b></font>势力，【失去以此法获得的所有技能】并随机获得该势力的一个技能。",
	["$tc_huashen1"] = "幻化之术谨之，为政者自当为国为民。",
	["$tc_huashen2"] = "天之政者，不可逆之；逆之，虽胜必衰矣。",
	  --新生
	["tc_xinsheng"] = "新生",
	[":tc_xinsheng"] = "锁定技，当你受到1点伤害后，你选择是否发动“化身”（因此技能发动的“化身”略过“【】”内效果）：若不选择发动且当前回合角色不为你，你摸一张牌。",
	--["@tc_xinsheng-usehuashen"] = "你是否发动“化身”？",
	["@tc_huashen"] = "是否发动“化身”",
	["~tc_huashen"] = "若不选择发动则改为摸牌",
	["$tc_xinsheng1"] = "傍日月，携宇宙，游乎尘垢之外。",
	["$tc_xinsheng2"] = "吾多与天地精神之往来，生即死，死又复生。",
	  --阵亡
	["~tc_shenzuoci"] = "万事，皆有因果......",
	
	--神郭嘉(Maki设计)
	["tc_shenguojia"] = "神郭嘉[天才包]",
	["&tc_shenguojia"] = "神郭嘉",
	["#tc_shenguojia"] = "星月奇才",
	["designer:tc_shenguojia"] = "俺的西木野Maki",
	["cv:tc_shenguojia"] = "官方",
	["illustrator:tc_shenguojia"] = "木美人", --皮肤：谋定天下
	  --慧识
	["tc_huishi"] = "慧识",
	["tc_huishizx"] = "慧识",
	["tc_huishi:continue"] = "你是否继续发动“慧识”进行判定",
	["tc_huishi-give"] = "请将所有判定牌交给一名角色",
	[":tc_huishi"] = "出牌阶段限一次，你可以进行判定：若结果与此阶段内以此法进行判定的结果的花色均不同，你可以重复此流程，将判定牌置于武将牌上，否则你终止判定。所有流程结束后，" ..
	"你可以将所有因“慧识”判定而置于武将牌上的判定牌交给一名角色，然后你令一名其他角色获得“佐幸”直到你的回合开始时，否则你获得“佐幸”直到你的回合开始时。",
	["$tc_huishi1"] = "木秀于林，风必摧之。",
	["$tc_huishi2"] = "虽为神兽，亦须循天道而行。",
	    --佐幸
	  ["tc_zuoxing"] = "佐幸",
	  [":tc_zuoxing"] = "出牌阶段限一次，若<font color=\"#00CCFF\"><b>神郭嘉</b></font>存活，你可以交给其一张牌，若如此做，你可以视为使用一张普通锦囊牌或一张基本牌。",
	  ["$tc_zuoxing1"] = "大道至理，只可意会，不可言传。",
	  ["$tc_zuoxing2"] = "我已，有所顿悟。",
	  --天妒+界遗计
	  --阵亡
	["~tc_shenguojia"] = "天劫降临，我大限将至......",
	
	--神鲁肃(Maki设计)
	["tc_shenlusu"] = "神鲁肃[天才包]",
	["&tc_shenlusu"] = "神鲁肃",
	["#tc_shenlusu"] = "兴业齐才",
	["designer:tc_shenlusu"] = "俺的西木野Maki",
	["cv:tc_shenlusu"] = "官方",
	["illustrator:tc_shenlusu"] = "第七个桔子", --皮肤：周济万民
	  --定州
	["tc_dingzhou"] = "定州",
	--[":tc_dingzhou"] = "出牌阶段限一次，你可以选择一名场上有牌的其他角色并交给其X张牌（X为其场上牌的张数），然后你获得其场上所有牌。",
	[":tc_dingzhou"] = "出牌阶段限一次，你可以选择一名场上有牌的其他角色，然后你获得其场上所有牌并交给其X张牌（X为你以此法获得的牌数）。",
	["$tc_dingzhou1"] = "家有富财，性好施与。",
	["$tc_dingzhou2"] = "内外节俭，不务俗好。",
	  --榻谟
	["tc_tamo"] = "榻谟",
	[":tc_tamo"] = "<font color=\"red\"><b>每局限一次，</b></font>出牌阶段，你可以重新分配除主公外每名角色的座次。",
	["$tc_tamo1"] = "联刘抗曹，是必行之举。",
	["$tc_tamo2"] = "吴蜀缔结联盟，可保时局稳定。",
	  --智盟
	["tc_zhimeng"] = "智盟", --语音：联盟抗魏
	[":tc_zhimeng"] = "回合结束后，你可以选择一名其他角色，然后与其交换至少一张手牌。",
	["$tc_zhimeng1"] = "辅车相依，唇亡齿寒！",
	["$tc_zhimeng2"] = "联盟既起，戮力同心！",
	  --阵亡
	["~tc_shenlusu"] = "内忧外患，何日能消......",
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
}


sgs.Sanguosha:addSkills(skills)

return {extension_f, extension_tc, newgodsCard}


