module("extensions.lol2015",package.seeall)--【NeonFire LOL 0519】for 0405 by NeonFire
extension = sgs.Package("lol2015")

lol_jiansu = sgs.CreateDistanceSkill{
	name = "#lol_jiansu",
	correct_func = function(self, from, to)
		if from:getPile("lol_jiansu"):length() > 0 and to:getPile("lol_jiansu"):length() == 0 and to:getPile("lol_jiasu"):length() == 0 then return 1 
		elseif from:getPile("lol_jiasu"):length() > 0 and to:getPile("lol_jiansu"):length() == 0 and to:getPile("lol_jiasu"):length() == 0 then return -1 
		elseif to:getPile("lol_jiansu"):length() > 0 and from:getPile("lol_jiansu"):length() == 0 and from:getPile("lol_jiasu"):length() == 0 then return -1
		elseif to:getPile("lol_jiasu"):length() > 0 and from:getPile("lol_jiasu"):length() == 0 and from:getPile("lol_jiansu"):length() == 0 then return 1		
		elseif from:getPile("lol_jiansu"):length() > 0 and to:getPile("lol_jiasu"):length() > 0 then return 2 
		elseif to:getPile("lol_jiansu"):length() > 0 and from:getPile("lol_jiasu"):length() > 0 then return -2
		end
	end,
}
lol_turn = sgs.CreateTriggerSkill{
	name = "#lol_turn",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.CardsMoveOneTime, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "lol_yun_start", 0)
				for _,id in sgs.qlist(player:getPile("lol_yunxuan")) do room:throwCard(id, nil) end				
				for _,id in sgs.qlist(player:getPile("lol_hudun")) do room:throwCard(id, nil) end
			elseif player:getPhase() == sgs.Player_Finish then
			    for _,p in sgs.qlist(room:getAlivePlayers()) do			
					if p:getMark("lol_yun_start") == 0 then 
						for _,id in sgs.qlist(p:getPile("lol_yunxuan")) do room:throwCard(id, nil) end
					end				
                end
				for _,id in sgs.qlist(player:getPile("lol_jiasu")) do room:throwCard(id, nil) end
				for _,id in sgs.qlist(player:getPile("lol_jiansu")) do room:throwCard(id, nil) end
                --if player:getMark("@lol_buff_dczg") > 0 and player:getHandcardNum() < player:getMaxHp() then player:drawCards(1) end					
			end
		elseif event == sgs.DrawNCards then	
		    --if player:getMark("@lol_buff_njzs") > 0 then data:setValue(data:toInt() + 1) end
		elseif event == sgs.CardsMoveOneTime then
            if player:getPile("lol_yunxuan"):length() > 0 then room:setPlayerCardLimitation(player, "use,response", ".|.|.|.", true)		    
			elseif player:getPile("lol_yunxuan"):length() == 0 then room:removePlayerCardLimitation(player, "use,response", ".|.|.|.$1")
			end
			if player:getPile("lol_jiasu"):length() > 0 and player:getPile("lol_jiansu"):length() > 0 then
			    for _,id in sgs.qlist(player:getPile("lol_jiasu")) do room:throwCard(id, nil) end
				for _,id in sgs.qlist(player:getPile("lol_jiansu")) do room:throwCard(id, nil) end
			end
		elseif event == sgs.DamageInflicted and player:getPile("lol_hudun"):length() > 0 then
			local damage = data:toDamage()			
			local upper = math.min(damage.damage, player:getPile("lol_hudun"):length())
			for i = 0, upper - 1, 1 do
				room:fillAG(player:getPile("lol_hudun"), player)
				id = room:askForAG(player, player:getPile("lol_hudun"), false, self:objectName())
				local card = sgs.Sanguosha:getCard(id)
				room:throwCard(card, nil, nil)	
				room:clearAG()					
			end
			damage.damage = damage.damage - upper
			data:setValue(damage)					
		end
	end	
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#lol_jiansu") then skills:append(lol_jiansu) end
if not sgs.Sanguosha:getSkill("#lol_turn") then skills:append(lol_turn) end
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{ 
["lol2015"] = "LOL 2015",
["lol_jiasu"] = "加速",
["lol_jiansu"] = "减速",
["lol_yunxuan"] = "晕眩/束缚/压制",
["lol_hudun"] = "护盾",
}

lol_xlnw_pks = sgs.General(extension, "lol_xlnw_pks", "god", 3, true, true, true)
lol_xlnw_pet = sgs.General(extension, "lol_xlnw_pet", "god", 3, true, true, true)
lol_bjfh_egg = sgs.General(extension, "lol_bjfh_egg", "god", 1, false, true, true)

lol_jwyh = sgs.General(extension, "lol_jwyh", "god", 3, false)
lol_jwyh_t = sgs.CreateTriggerSkill{
	name = "lol_jwyh_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()	
		local move = data:toMoveOneTime()
		if player:getPhase() == sgs.Player_Play and move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
			if player:getMark("@lol_jwyh_t") < 9 then
				room:setPlayerMark(player, "@lol_jwyh_t", player:getMark("@lol_jwyh_t") + 1)
			elseif player:getMark("@lol_jwyh_t") == 9 and player:isWounded() then
				room:broadcastSkillInvoke("lol_jwyh_t")	
				room:notifySkillInvoked(player, self:objectName())				    
				room:setPlayerMark(player, "@lol_jwyh_t", 0)
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end		
		end
	end
}
lol_jwyh_qCard = sgs.CreateSkillCard{
	name = "lol_jwyh_qCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:showCard(effect.from, self:getEffectiveId())
	    room:obtainCard(effect.to, self, true)
		if effect.to:isKongcheng() then return false end
		local card_id = room:askForCardChosen(effect.from, effect.to, "h", self:objectName())
		room:obtainCard(effect.from, card_id)
        room:showCard(effect.from, card_id)
		if self:getSuit() ~= sgs.Sanguosha:getCard(card_id):getSuit() then return false end
		local dest = sgs.QVariant()
		dest:setValue(effect.to)
        if room:askForSkillInvoke(effect.from , "lol_jwyh_q", dest) then
		    room:throwCard(sgs.Sanguosha:getCard(card_id), effect.from)
		    room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1))
		end
	end
}
lol_jwyh_q = sgs.CreateViewAsSkill{
	name = "lol_jwyh_q",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_jwyh_qCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_jwyh_qCard")
	end
}
lol_jwyh_wCard = sgs.CreateSkillCard{
	name = "lol_jwyh_wCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    local room = player:getRoom()
        card1 =  room:askForCard(player, ".", "@lol_jwyh_w_discard", sgs.QVariant(1), sgs.CardDiscarded) 
		if not card1 then		    
			card1 = sgs.Sanguosha:getCard(room:getNCards(1):first())
            room:throwCard(card1, reason, nil)			
		end
		if card1:isRed() then
			room:setPlayerFlag(player, "lol_jwyh_wR")
		else
			room:setPlayerFlag(player, "lol_jwyh_wB")
		end
        card2 =  room:askForCard(player, ".", "@lol_jwyh_w_discard", sgs.QVariant(2), sgs.CardDiscarded) 
		if not card2 then		    
			card2 = sgs.Sanguosha:getCard(room:getNCards(1):first())
            room:throwCard(card2, reason, nil)			
		end
		if card2:isRed() then
			room:setPlayerFlag(player, "lol_jwyh_wR")
		else
			room:setPlayerFlag(player, "lol_jwyh_wB")
		end
        card3 =  room:askForCard(player, ".", "@lol_jwyh_w_discard", sgs.QVariant(3), sgs.CardDiscarded) 
		if not card3 then		    
			card3 = sgs.Sanguosha:getCard(room:getNCards(1):first())
            room:throwCard(card3, reason, nil)			
		end	
		room:setPlayerFlag(player, "-lol_jwyh_wB")
		room:setPlayerFlag(player, "-lol_jwyh_wR")
		room:setPlayerFlag(player, "-lol_jwyh_w_empty")
		if card1:getColor() == card2:getColor() and card2:getColor() == card3:getColor() then 
		    local tos = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			    if player:distanceTo(p) <= 1 and p:objectName() ~= player:objectName() then tos:append(p) end
            end
			if not tos:isEmpty() then
			    local target = room:askForPlayerChosen(player, tos, self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Fire))
			end
		end
	end
}
lol_jwyh_w = sgs.CreateViewAsSkill{
	name = "lol_jwyh_w" ,
	n = 0,
	view_as = function()
		return lol_jwyh_wCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_jwyh_wCard")
	end
}
lol_jwyh_eCard = sgs.CreateSkillCard{
	name = "lol_jwyh_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHandcardNum() >= sgs.Self:getHandcardNum() and to_select:objectName() ~= sgs.Self:objectName()
	end,	
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:showAllCards(effect.to, effect.from)
		effect.to:setFlags("lol_jwyh_e")
		room:setTag("Dongchaer", sgs.QVariant(effect.from:objectName()))		
		room:setTag("Dongchaee", sgs.QVariant(effect.to:objectName()))
	end
}
lol_jwyh_eVS = sgs.CreateViewAsSkill{
	name = "lol_jwyh_e",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_jwyh_eCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_jwyh_eCard")
	end
}
lol_jwyh_e = sgs.CreateTriggerSkill{
	name = "lol_jwyh_e" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	view_as_skill = lol_jwyh_eVS ,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("lol_jwyh_e") then meihuo = p end
		end		
		if event == sgs.CardsMoveOneTime then
		    local move = data:toMoveOneTime()
			if meihuo and move.to and move.to:objectName() == meihuo:objectName() and meihuo:hasFlag("lol_jwyh_e") and move.to_place == sgs.Player_PlaceHand then
			    room:showAllCards(meihuo, player)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish then return false end
			if meihuo and meihuo:hasFlag("lol_jwyh_e") then meihuo:setFlags("-lol_jwyh_e") end		
			room:setTag("Dongchaer", sgs.QVariant())			
			room:setTag("Dongchaee", sgs.QVariant())
		end
	end
}
lol_jwyh_rCard = sgs.CreateSkillCard{
	name = "lol_jwyh_rCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
        room:setPlayerMark(player, "lol_jwyh_r123", player:getMark("lol_jwyh_r123") + 1)	
        if player:getMark("lol_jwyh_r123") == 1 then		
			room:doLightbox("$lol_jwyh_image", 1500)
			room:removePlayerMark(player, "@lol_jwyh_r3")
		end
		player:drawCards(2)	
		if player:getMark("lol_jwyh_r123") ~= 3 then room:askForUseCard(player, "@@lol_jwyh_r", "@lol_jwyh_r") end
	end
}
lol_jwyh_rVS = sgs.CreateViewAsSkill{
	name = "lol_jwyh_r" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_jwyh_rCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_jwyh_r3") >= 1
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lol_jwyh_r"
	end
}
lol_jwyh_r = sgs.CreateTriggerSkill{
	name = "lol_jwyh_r",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_jwyh_r3",
	events = {sgs.TargetConfirming},
	view_as_skill = lol_jwyh_rVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) and player:getMark("@lol_jwyh_r3") >= 1 then
			room:askForUseCard(player, "@@lol_jwyh_r", "@lol_jwyh_r")
		end
	end
}
lol_jwyh:addSkill(lol_jwyh_q)
lol_jwyh:addSkill(lol_jwyh_w)
lol_jwyh:addSkill(lol_jwyh_e)
lol_jwyh:addSkill(lol_jwyh_r)
lol_jwyh:addSkill(lol_jwyh_t)
sgs.LoadTranslationTable{ 
["#lol_jwyh"] = "九尾妖狐",
["lol_jwyh"] = "阿狸",
["~lol_jwyh"] = "啊啊...啊..啊..",
["lol_jwyh_t"] = "被动",
[":lol_jwyh_t"] = "<font color=\"purple\"><b>【摄魂夺魄】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你于出牌阶段内失去手牌时，若你已受伤且“摄魂夺魄”的层数达到9，你失去所有层数，回复1点体力，否则你获得1层“摄魂夺魄”（最多可叠加9层）。",
["$lol_jwyh_t"] = "他们的价值已经被榨干了。",
["lol_jwyh_q"] = "Q",
[":lol_jwyh_q"] = "<font color=\"purple\"><b>【欺诈宝珠】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以展示一张红色手牌并将其交给一名角色，然后你获得该角色一张手牌并展示之，若此牌与你展示的第一张牌颜色相同，你可以弃置此牌，对该角色造成1点伤害。",
["$lol_jwyh_q"] = "你不相信我吗？",
["lol_jwyh_w"] = "W",
[":lol_jwyh_w"] = "<font color=\"purple\"><b>【妖异狐火】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以进行三次选择：1、弃置一张手牌；2、将牌堆顶一张牌置入弃牌堆。然后若以此法置入弃牌堆的三张牌的颜色均相同，你可以对一名距离为1的其他角色造成1点火焰伤害。",
["$lol_jwyh_w"] = "我们去找点真正的乐子吧。",
["@lol_jwyh_w_discard"] = "你可以弃置一张手牌（若点击取消，将牌堆顶一张牌置入弃牌堆）",
["lol_jwyh_e"] = "E",
[":lol_jwyh_e"] = "<font color=\"purple\"><b>【魅惑妖术】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张红色手牌并选择一名手牌数不少于你的其他角色，其手牌对你可见，直到回合结束。",
["$lol_jwyh_e"] = "你渴望什么呀？",
["lol_jwyh_r"] = "R",
[":lol_jwyh_r"] = "<font color=\"purple\"><b>【灵魄突袭】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，或当你成为【杀】的目标时，你可以重复三次此流程：弃置一张黑桃手牌，摸两张牌。",
["$lol_jwyh_image"] = "image=image/animate/lol_jwyh_r.png",
["$lol_jwyh_r"] = "该办正事儿了。",
["@lol_jwyh_r"] = "你可以使用【灵魄突袭】",
["~lol_jwyh_r"] = "选择一张手牌，点击“确定”",
["designer:lol_jwyh"] = "霓炎",
["cv:lol_jwyh"] = " ",
["illustrator:lol_jwyh"] = " ",
}

lol_hbss = sgs.General(extension, "lol_hbss", "god", 3, false)
lol_hbss_t = sgs.CreateTriggerSkill{
	name = "lol_hbss_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.ConfirmDamage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		if not me then return false end
        if event == sgs.Damaged then		
            local damage = data:toDamage()
			if damage.from and damage.from:objectName() == me:objectName() or damage.to:objectName() == me:objectName() then
			    room:setPlayerMark(me, "lol_hbss_t_damaged", 1) 
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then				
				if me:getMark("lol_hbss_t_damaged") == 0 and me:getMark("@lol_hbss_t_Mark") < 100 then
                    room:notifySkillInvoked(me, self:objectName())				
				    room:setPlayerMark(me, "@lol_hbss_t_Mark", me:getMark("@lol_hbss_t_Mark") + 20)
				end
				room:setPlayerMark(me, "lol_hbss_t_damaged", 0) 
			end
		elseif event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == me:objectName() and me:getMark("@lol_hbss_t_Mark") == 100 then
			    room:setPlayerMark(me, "@lol_hbss_t_Mark", 0) 
				room:broadcastSkillInvoke("lol_hbss_t")					
			    room:setCardFlag(use.card, "lol_hbss_t_slash")
			end
		elseif event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == me:objectName() and damage.card:hasFlag("lol_hbss_t_slash") then		
				room:notifySkillInvoked(me, "lol_hbss_t")
				damage.damage = damage.damage + 1
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = me
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
				data:setValue(damage)
            end			
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
lol_hbss_qCard = sgs.CreateSkillCard{
	name = "lol_hbss_qCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		player:setFlags("lol_hbss_q")
	end
}
lol_hbss_qVS = sgs.CreateViewAsSkill{
	name = "lol_hbss_q" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then return not to_select:isEquipped() end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = lol_hbss_qCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_hbss_qCard")
	end
}
lol_hbss_q = sgs.CreateTriggerSkill{
	name = "lol_hbss_q" ,
	events = {sgs.TargetConfirmed} ,
	view_as_skill = lol_hbss_qVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() and player:hasFlag("lol_hbss_q") then	
			for _,p in sgs.qlist(use.to) do
				room:acquireSkill(p, "#lol_turn")			
			    room:acquireSkill(p, "lol_jiansu")
                if p:getPile("lol_jiansu"):length() == 0 then p:addToPile("lol_jiansu", room:getNCards(1)) end			
			end			
		end
	end
}
lol_hbss_wVS = sgs.CreateViewAsSkill{
	name = "lol_hbss_w" ,
	n = 2,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		if #cards < 2 then return not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = sgs.Sanguosha:cloneCard("archery_attack", cards[1]:getSuit(), 0)
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:setSkillName("lol_hbss_w")
		return card
	end,
	enabled_at_play = function(self, player)
        return not player:hasFlag("lol_hbss_w")
	end
}
lol_hbss_w = sgs.CreateTriggerSkill{
	name = "lol_hbss_w",
	events = {sgs.CardUsed, sgs.Damage},
	view_as_skill = lol_hbss_wVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then
                room:setPlayerFlag(player, "lol_hbss_w")			
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() then	
				room:acquireSkill(damage.to, "#lol_turn")				
				room:acquireSkill(damage.to, "lol_jiansu")	
                if damage.to:getPile("lol_jiansu"):length() == 0 then damage.to:addToPile("lol_jiansu", room:getNCards(1)) end				
			end		
		end
	end
}
lol_hbss_eCard = sgs.CreateSkillCard{
	name = "lol_hbss_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		return #targets == 0 and not to_select:isKongcheng()
	end,
	on_use = function(self, room, player, targets)
	    local target = targets[1]
	    room:showAllCards(target)
	end
}
lol_hbss_e = sgs.CreateViewAsSkill{
	name = "lol_hbss_e" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then return not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = lol_hbss_eCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
        return not player:hasUsed("#lol_hbss_eCard")
	end
}
lol_hbss_rVS = sgs.CreateViewAsSkill{
	name = "lol_hbss_r" ,
	n = 1,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then return not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
	    if #cards ~= 1 then return nil end
		local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber()) 
		slash:addSubcard(cards[1])
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_hbss_r") >= 1 and sgs.Slash_IsAvailable(player)
	end
}
lol_hbss_r = sgs.CreateTriggerSkill{
	name = "lol_hbss_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_hbss_r",
	events = {sgs.CardUsed, sgs.Damage},
	view_as_skill = lol_hbss_rVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
            local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
                room:doLightbox("$lol_hbss_image", 1500)
		        room:removePlayerMark(player, "@lol_hbss_r")			
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() then					
				for _,p in sgs.qlist(room:getAlivePlayers()) do room:acquireSkill(p, "#lol_turn") end	
                if damage.to:getPile("lol_yunxuan"):length() == 0 then damage.to:addToPile("lol_yunxuan", room:getNCards(1)) end	
				if damage.to:distanceTo(player) >= 2 then room:setPlayerMark(damage.to, "lol_yun_start", 1) end				
			end			
		end
	end
}
lol_hbss_r_dis = sgs.CreateTargetModSkill{
	name = "#lol_hbss_r_dis",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("lol_hbss_r") and table.contains(card:getSkillNames(), "lol_hbss_r") then return 1000 end
	end
}
lol_hbss:addSkill(lol_hbss_q)
lol_hbss:addSkill(lol_hbss_w)
lol_hbss:addSkill(lol_hbss_e)
lol_hbss:addSkill(lol_hbss_r)
lol_hbss:addSkill(lol_hbss_r_dis)
lol_hbss:addSkill(lol_hbss_t)
extension:insertRelatedSkills("lol_hbss_r", "#lol_hbss_r_dis")
sgs.LoadTranslationTable{ 
["#lol_hbss"] = "寒冰射手",
["lol_hbss"] = "艾希",
["~lol_hbss"] = "啊啊...",
["lol_hbss_t"] = "被动",
[":lol_hbss_t"] = "<font color=\"purple\"><b>【全神贯注】</b></font><font color=\"blue\"><b>锁定技，</b></font>一名角色的结束阶段开始时，若你于此回合内没有造成或受到伤害，你获得20层＂全神贯注＂（最多可叠加100层）。<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定一名目标角色后，若＂全神贯注＂的层数达到100，你失去所有层数，此【杀】造成的伤害+1。",
["$lol_hbss_t"] = "我瞄得很稳。",
["lol_hbss_q"] = "Q",
[":lol_hbss_q"] = "<font color=\"purple\"><b>【冰霜射击】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌，若如此做，直到回合结束，每当你使用【杀】指定一名目标角色后，令其减速（直到其结束阶段开始）。",
["$lol_hbss_q"] = "结冰吧。",
["lol_hbss_w"] = "W",
[":lol_hbss_w"] = "<font color=\"purple\"><b>【万箭齐发】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将两张手牌当【万箭齐发】使用，每当你使用此【万箭齐发】对一名角色造成伤害后，令其减速（直到其结束阶段开始）。",
["$lol_hbss_w"] = "你要来几发吗？",
["lol_hbss_e"] = "E",
[":lol_hbss_e"] = "<font color=\"purple\"><b>【鹰击长空】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌，令一名有手牌的角色展示所有手牌。",
["$lol_hbss_e"] = "我们必须向前推进。",
["lol_hbss_r"] = "R",
[":lol_hbss_r"] = "<font color=\"purple\"><b>【魔法水晶箭】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将一张手牌当【杀】使用（无距离限制），当你使用此【杀】对目标角色造成伤害后，令其晕眩（若其与你的距离不大于1，直到结束阶段开始；否则直到其准备阶段开始）。",
["$lol_hbss_image"] = "image=image/animate/lol_hbss_r.png",
["$lol_hbss_r"] = "正对眉心。",
["designer:lol_hbss"] = "霓炎",
["cv:lol_hbss"] = " ",
["illustrator:lol_hbss"] = " ",
}

lol_mzzw = sgs.General(extension, "lol_mzzw", "god", 4, true)
lol_mzzw_t = sgs.CreateTriggerSkill{
	name = "lol_mzzw_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.Damage, sgs.Death, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then	
				for _,p in sgs.qlist(use.to) do
					if player:getMark("@lol_mzzw_t") < 100 then
                        room:notifySkillInvoked(player, self:objectName())						
					    room:setPlayerMark(player, "@lol_mzzw_t", player:getMark("@lol_mzzw_t") + 10) 
					end			
				end			
			end
		elseif event == sgs.Damage then
		    local damage = data:toDamage()
		    if damage.damage >= 2 and player:getMark("@lol_mzzw_t") < 100 then 
				room:notifySkillInvoked(player, self:objectName())				
			    room:setPlayerMark(player, "@lol_mzzw_t", player:getMark("@lol_mzzw_t") + 10) 
			end
		elseif event == sgs.Death then
		    local death = data:toDeath()				
			if death.damage and (death.damage.from and death.damage.from:objectName() == player:objectName()) and player:getMark("@lol_mzzw_t") < 100 then 
			    room:notifySkillInvoked(player, self:objectName())	
				room:setPlayerMark(player, "@lol_mzzw_t", player:getMark("@lol_mzzw_t") + 10) 
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if damage.card and damage.card:isKindOf("Slash") and math.random(250) <= player:getMark("@lol_mzzw_t") then
				room:broadcastSkillInvoke("lol_mzzw_t")
                room:notifySkillInvoked(player, self:objectName())					
				damage.damage = damage.damage + 1
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
				data:setValue(damage)
			end	
        end			
	end,
}
lol_mzzw_qCard = sgs.CreateSkillCard{
	name = "lol_mzzw_qCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    local room = player:getRoom()
	    if player:getMark("@lol_mzzw_t") == 100 then		
		    local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 2
			room:recover(player, recover)
		elseif player:getMark("@lol_mzzw_t") >=50 and player:getMark("@lol_mzzw_t") < 100 then
		    local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
        end
		room:setPlayerMark(player, "@lol_mzzw_t", 0)
	end
}
lol_mzzw_q = sgs.CreateViewAsSkill{
	name = "lol_mzzw_q" ,
	n = 0,
	view_as = function()
		return lol_mzzw_qCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_mzzw_qCard")
	end
}
lol_mzzw_wCard = sgs.CreateSkillCard{
	name = "lol_mzzw_wCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)	
	    local room = effect.from:getRoom()
		local id = room:askForCardChosen(effect.to, effect.to, "h", "lol_mzzw_w")
		card = sgs.Sanguosha:getCard(id) 
        room:showCard(effect.to, card:getEffectiveId())
        if card:isKindOf("Slash") then
		    room:throwCard(card, reason, nil)
		elseif card:isKindOf("Jink") then
		    room:acquireSkill(effect.to, "#lol_turn")			
			room:acquireSkill(effect.to, "lol_jiansu")
			if effect.to:getPile("lol_jiansu"):length() == 0 then effect.to:addToPile("lol_jiansu", room:getNCards(1)) end			
		end
	end
}
lol_mzzw_w = sgs.CreateViewAsSkill{
	name = "lol_mzzw_w" ,
	n = 0,
	view_as = function()
		return lol_mzzw_wCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_mzzw_wCard")
	end
}
lol_mzzw_eVS = sgs.CreateViewAsSkill{
	name = "lol_mzzw_e" ,
	n = 2,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then return (to_select:isKindOf("Jink") or to_select:isKindOf("Slash")) and not to_select:isEquipped() 
		elseif #cards == 1 then 
		    if cards[1]:isKindOf("Slash") then return to_select:isKindOf("Jink") and not to_select:isEquipped()
            elseif cards[1]:isKindOf("Jink") then return to_select:isKindOf("Slash") and not to_select:isEquipped()	
			end			
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), 0)
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:setSkillName("lol_mzzw_e")
		return card
	end,
	enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and not player:hasFlag("lol_mzzw_e")
	end
}
lol_mzzw_e = sgs.CreateTriggerSkill{
	name = "lol_mzzw_e",
	events = {sgs.CardUsed},
	view_as_skill = lol_mzzw_eVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then
			room:setPlayerFlag(player, "lol_mzzw_e")
			if use.to:length() ~= 1 then return false end
			for _,dest in sgs.qlist(use.to) do
                for _,p in sgs.qlist(room:getOtherPlayers(dest)) do
                    if player:distanceTo(p) <= player:distanceTo(dest) and player:canSlash(p, nil, false) then
				        room:setPlayerFlag(p, "lol_mzzw_e_dest")
                    end						
                end				
			end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("lol_mzzw_e_dest") then use.to:append(p) end						
			end
            data:setValue(use)			
		end
	end
}
lol_mzzw_rCard = sgs.CreateSkillCard{
	name = "lol_mzzw_rCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    room:doLightbox("$lol_mzzw_image", 1500)
		room:removePlayerMark(player, "@lol_mzzw_r")
		room:setPlayerMark(player, "lol_mzzw_r_damage", 1)
        if player:getMark("@lol_mzzw_t") < 50 then room:setPlayerMark(player, "@lol_mzzw_t", player:getMark("@lol_mzzw_t") + 50)
        else room:setPlayerMark(player, "@lol_mzzw_t", 100)
		end
	end
}
lol_mzzw_rVS = sgs.CreateViewAsSkill{
	name = "lol_mzzw_r" ,
	n = 0,
	view_as = function()
		return lol_mzzw_rCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_mzzw_r") >= 1
	end
}
lol_mzzw_r = sgs.CreateTriggerSkill{
	name = "lol_mzzw_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_mzzw_r",
	events = {sgs.Dying, sgs.EventPhaseStart},
	view_as_skill = lol_mzzw_rVS ,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if event == sgs.Dying then
			local dying = data:toDying()			    		
			if dying.who:objectName() == player:objectName() and player:getMark("lol_mzzw_r_damage") > 0 then
                room:notifySkillInvoked(player, self:objectName())					
                local log = sgs.LogMessage()
				log.type = "#lol_mzzw_r_log"
				log.from = player
				room:sendLog(log)			
			    room:setPlayerProperty(player, "hp", sgs.QVariant(1))
			end
		elseif event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Start then room:setPlayerMark(player, "lol_mzzw_r_damage", 0) end
		end
	end
}
lol_mzzw:addSkill(lol_mzzw_q)
lol_mzzw:addSkill(lol_mzzw_w)
lol_mzzw:addSkill(lol_mzzw_e)
lol_mzzw:addSkill(lol_mzzw_r)
lol_mzzw:addSkill(lol_mzzw_t)
sgs.LoadTranslationTable{ 
["#lol_mzzw"] = "蛮族之王",
["lol_mzzw"] = "泰达米尔",
["~lol_mzzw"] = "呃...",
["lol_mzzw_t"] = "被动",
[":lol_mzzw_t"] = "<font color=\"purple\"><b>【战斗狂怒】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定一名目标角色后，或造成不少于2点的伤害后，或杀死一名角色后，你获得10点怒气值（怒气上限100点）。<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】对目标角色造成伤害时，你有0.35X%的几率令伤害值+1（X为你的怒气值）。",
["$lol_mzzw_t"] = "我是你最可怕的恶梦。",
["lol_mzzw_q"] = "Q",
[":lol_mzzw_q"] = "<font color=\"purple\"><b>【嗜血杀戮】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以失去所有怒气值，以此法每失去50点怒气值，你回复1点体力。",
["$lol_mzzw_q"] = "我的大刀早已饥渴难耐了。",
["lol_mzzw_w"] = "W",
[":lol_mzzw_w"] = "<font color=\"purple\"><b>【蔑视】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以选择任意名有手牌的其他角色，令这些角色各展示一张手牌，弃置以此法展示的【杀】，并令以此法展示【闪】的角色减速（直到其结束阶段开始时）。",
["$lol_mzzw_w"] = "你是没有机会赢我的。",
["lol_mzzw_e"] = "E",
[":lol_mzzw_e"] = "<font color=\"purple\"><b>【旋风斩】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张【杀】和一张【闪】当【杀】使用，每当你使用此【杀】指定唯一目标时，你距离X以内的其他角色成为此【杀】的额外目标（X为你与目标角色的距离）。",
["$lol_mzzw_e"] = "这将会是场屠杀。",
["lol_mzzw_r"] = "R",
[":lol_mzzw_r"] = "<font color=\"purple\"><b>【无尽怒火】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以获得50点怒气值，且直到你的准备阶段开始，每当你进入濒死状态时，你回复至1点体力。",
["#lol_mzzw_r_log"] = "%from 对死亡免疫，回复至1点体力",
["$lol_mzzw_image"] = "image=image/animate/lol_mzzw_r.png",
["$lol_mzzw_r"] = "现在他们可以死了。",
["designer:lol_mzzw"] = "霓炎",
["cv:lol_mzzw"] = " ",
["illustrator:lol_mzzw"] = " ",
}

lol_tqz = sgs.General(extension, "lol_tqz", "god", 3, false)
lol_tqz_t = sgs.CreateTriggerSkill{
	name = "lol_tqz_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
        if damage.to:objectName() ~= player:objectName() and player:getMark("@lol_tqz_r") == 0 then 
		    room:broadcastSkillInvoke("lol_tqz_t")
            room:notifySkillInvoked(player, self:objectName())				
		    room:setPlayerMark(player, "@lol_tqz_r", 1) 
		end
	end,
}
lol_tqz_qVS = sgs.CreateViewAsSkill{
	name = "lol_tqz_q" ,
	n = 1,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then return to_select:isRed() and not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
	    if #cards ~= 1 then return nil end
		local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", cards[1]:getSuit(), cards[1]:getNumber()) 
		fire_attack:addSubcard(cards[1]:getId())
		fire_attack:setSkillName(self:objectName())
		return fire_attack
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("lol_tqz_q")
	end
}
lol_tqz_q = sgs.CreateTriggerSkill{
	name = "lol_tqz_q" ,
	view_as_skill = lol_tqz_qVS,
	events = {sgs.CardUsed, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
            local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
			    room:setPlayerFlag(player, "lol_tqz_q")
				if player:hasFlag("lol_hbss_r") then
				    player:setFlags("-lol_hbss_r")
                    player:setFlags("lol_hbss_rq")					
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() then
                if damage.to and damage.to:isAlive() then		
					if player:hasFlag("lol_hbss_rq") then lol_tqz_q_choice = {"lol_tqz_q_jiansu", "lol_tqz_q_draw", "lol_tqz_q_damage"} 
					else lol_tqz_q_choice = {"lol_tqz_q_jiansu", "lol_tqz_q_draw"} 
					end
					local n = 0		
					while player do            
						local choice = room:askForChoice(player, self:objectName(), table.concat(lol_tqz_q_choice, "+"))
						if choice == "lol_tqz_q_jiansu" then
							player:setFlags("lol_tqz_q_jiansu")
						elseif choice == "lol_tqz_q_damage" then			
							player:setFlags("lol_tqz_q_damage")
						elseif choice == "lol_tqz_q_draw" then
							player:setFlags("lol_tqz_q_draw")
						end
						for i = 1, #lol_tqz_q_choice, 1 do
							if choice == lol_tqz_q_choice[i] then table.remove(lol_tqz_q_choice, i) end
						end				
						n = n + 1			
						if n == 2 and player:hasFlag("lol_hbss_rq") then break
						elseif n == 1 and not player:hasFlag("lol_hbss_rq") then break
						end				
					end			
					if player:hasFlag("lol_tqz_q_jiansu") then
						room:acquireSkill(damage.to, "#lol_turn")				
						room:acquireSkill(damage.to, "lol_jiansu")	
						if damage.to:getPile("lol_jiansu"):length() == 0 then damage.to:addToPile("lol_jiansu", room:getNCards(1)) end	
					end	
					if player:hasFlag("lol_tqz_q_draw") then
						player:drawCards(1)
					end 
					if player:hasFlag("lol_tqz_q_damage") and not damage.to:isKongcheng() then
						local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
						room:useCard(sgs.CardUseStruct(card, player, damage.to))
					end 
                end	
			end			
		end
	end
}
lol_tqz_wCard = sgs.CreateSkillCard{
	name = "lol_tqz_wCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		card_id = room:askForCardChosen(effect.from, effect.to, "h", self:objectName())
		room:showCard(effect.to, card_id)
        if effect.from:hasFlag("lol_hbss_r") then lol_tqz_w_choice = {"lol_tqz_w_shufu", "lol_tqz_w_throw", "lol_tqz_w_hp"} 
		else lol_tqz_w_choice = {"lol_tqz_w_shufu", "lol_tqz_w_throw"} 
		end
		local n = 0		
		while effect.to do            
			local choice = room:askForChoice(effect.to, self:objectName(), table.concat(lol_tqz_w_choice, "+"))
			if choice == "lol_tqz_w_throw" then
                room:throwCard(sgs.Sanguosha:getCard(card_id), effect.to) 
			elseif choice == "lol_tqz_w_shufu" then			
				for _,p in sgs.qlist(room:getAlivePlayers()) do room:acquireSkill(p, "#lol_turn") end	
				if effect.to:getPile("lol_yunxuan"):length() == 0 then effect.to:addToPile("lol_yunxuan", room:getNCards(1)) end			
			elseif choice == "lol_tqz_w_hp" then
		        local recover = sgs.RecoverStruct()
				recover.who = effect.from
				room:recover(effect.from, recover)
			end
			for i = 1, #lol_tqz_w_choice, 1 do
				if choice == lol_tqz_w_choice[i] then table.remove(lol_tqz_w_choice, i) end
			end				
			n = n + 1			
			if n == 2 and effect.from:hasFlag("lol_hbss_r") then break
			elseif n == 1 and not effect.from:hasFlag("lol_hbss_r") then break
			end				
		end
		effect.from:setFlags("-lol_hbss_r")
	end
}
lol_tqz_w = sgs.CreateViewAsSkill{
	name = "lol_tqz_w",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~=1 then return false end
		local card = lol_tqz_wCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:isWounded() and not player:hasUsed("#lol_tqz_wCard")
	end
}
lol_tqz_eCard = sgs.CreateSkillCard{
	name = "lol_tqz_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()	
		if effect.from:hasFlag("lol_hbss_r") then lol_tqz_e_choice = {"lol_tqz_e_hudun", "lol_tqz_e_draw", "lol_tqz_e_both"} 
		else lol_tqz_e_choice = {"lol_tqz_e_hudun", "lol_tqz_e_draw"} 
		end
		local n = 0		
		while effect.from do            
			local choice = room:askForChoice(effect.from, self:objectName(), table.concat(lol_tqz_e_choice, "+"))
			if choice == "lol_tqz_e_hudun" then
				room:acquireSkill(effect.to, "#lol_turn")	
				effect.to:addToPile("lol_hudun", room:getNCards(1, false))
				room:setPlayerFlag(effect.from, "lol_tqz_e_hudun")
			elseif choice == "lol_tqz_e_draw" then			
                effect.to:drawCards(1)
				room:setPlayerFlag(effect.from, "lol_tqz_e_draw")
			elseif choice == "lol_tqz_e_both" then
                room:setPlayerFlag(effect.from, "lol_tqz_e_both")
			end
			for i = 1, #lol_tqz_e_choice, 1 do
				if choice == lol_tqz_e_choice[i] then table.remove(lol_tqz_e_choice, i) end
			end				
			n = n + 1			
			if n == 2 and effect.from:hasFlag("lol_hbss_r") then break
			elseif n == 1 and not effect.from:hasFlag("lol_hbss_r") then break
			end				
		end
		for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
			if effect.to:distanceTo(p) <= 1 and effect.from:hasFlag("lol_tqz_e_both") then
				if effect.from:hasFlag("lol_tqz_e_hudun") then
					room:acquireSkill(p, "#lol_turn")	
					p:addToPile("lol_hudun", room:getNCards(1, false))
				elseif effect.from:hasFlag("lol_tqz_e_draw") then
				    p:drawCards(1)
				end	
			end
		end	
		effect.from:setFlags("-lol_hbss_r")
	end
}
lol_tqz_e = sgs.CreateViewAsSkill{
	name = "lol_tqz_e",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~=1 then return false end
		local card = lol_tqz_eCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_tqz_eCard")
	end
}
lol_tqz_rCard = sgs.CreateSkillCard{
	name = "lol_tqz_rCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    room:doLightbox("$lol_tqz_image", 1500)
		room:removePlayerMark(player, "@lol_tqz_r")	
		player:setFlags("lol_hbss_r")
	end
}
lol_tqz_rVS = sgs.CreateViewAsSkill{
	name = "lol_tqz_r" ,
	n = 0,
	view_as = function()
		return lol_tqz_rCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_tqz_r") >= 1
	end
}
lol_tqz_r = sgs.CreateTriggerSkill{
	name = "lol_tqz_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_tqz_r",
	events = {},
	view_as_skill = lol_tqz_rVS ,
	on_trigger = function()
		return false
	end
}
lol_tqz:addSkill(lol_tqz_q)
lol_tqz:addSkill(lol_tqz_w)
lol_tqz:addSkill(lol_tqz_e)
lol_tqz:addSkill(lol_tqz_r)
lol_tqz:addSkill(lol_tqz_t)
sgs.LoadTranslationTable{ 
["#lol_tqz"] = "天启者",
["lol_tqz"] = "卡尔玛",
["~lol_tqz"] = "就因为这个，打断了我的冥想...",
["lol_tqz_t"] = "被动",
[":lol_tqz_t"] = "<font color=\"purple\"><b>【聚能之炎】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你对其他角色造成伤害后，刷新“梵咒”。",
["$lol_tqz_t"] = "哪里有战斗，哪里就有我。",
["lol_tqz_q"] = "Q",
[":lol_tqz_q"] = "<font color=\"purple\"><b>【心灵烈焰】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张红色手牌当【火攻】使用，每当你使用此【火攻】对目标角色造成伤害后，若其存活，你选择一项：1.令其减速（直到其结束阶段开始）；2.摸一张牌。\
<font color=\"blue\"><b>【梵咒追加选项·灵光闪耀】3.视为对其使用一张【火攻】。</b></font>",
["lol_tqz_q_jiansu"] = "令其减速（直到其结束阶段开始）",
["lol_tqz_q_draw"] = "摸一张牌",
["lol_tqz_q_damage"] = "视为对其使用一张【火攻】",
["$lol_tqz_q"] = "谈判结束了。",
["lol_tqz_w"] = "W",
[":lol_tqz_w"] = "<font color=\"purple\"><b>【坚定不移】</b></font><font color=\"green\"><b>阶段技，</b></font>若你已受伤，你可以弃置一张手牌并选择一名有手牌的其他角色，你展示其一张手牌并令其选择一项：1.被束缚（直到回合结束）；2.弃置该牌。\
<font color=\"blue\"><b>【梵咒追加选项·焕发】3.令你回复1点体力值。</b></font>",
["lol_tqz_w_shufu"] = "被束缚（直到回合结束）",
["lol_tqz_w_throw"] = "弃置该牌",
["lol_tqz_w_hp"] = "令其回复1点体力值",
["$lol_tqz_w"] = "没有妥协的余地。",
["lol_tqz_e"] = "E",
[":lol_tqz_e"] = "<font color=\"purple\"><b>【鼓舞】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张方片手牌并选择一名角色，然后选择一项：1.令其获得护盾（直到其准备阶段开始）；2.令其摸一张牌。\
<font color=\"blue\"><b>【梵咒追加选项·蔑视】3.“鼓舞”同时对其距离1以内的其他角色生效。</b></font>",
["lol_tqz_e_hudun"] = "令其获得护盾（直到其准备阶段开始）",
["lol_tqz_e_draw"] = "令其摸一张牌",
["lol_tqz_e_both"] = "“鼓舞”同时对其距离1以内的其他角色生效",
["$lol_tqz_e"] = "集中你的才智和意志。",
["lol_tqz_r"] = "R",
[":lol_tqz_r"] = "<font color=\"purple\"><b>【梵咒】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令你发动的下一个技能(“心灵烈焰”/“坚定不移”/“鼓舞”)中的“选择一项”改为“选择两项”，并获得<font color=\"blue\"><b>“梵咒追加选项”</b></font>，直到回合结束。",
["lol_tqz_r_slash"] = "R",
["$lol_tqz_image"] = "image=image/animate/lol_tqz_r.png",
["$lol_tqz_r"] = "（梵）lasrianovien",
["designer:lol_tqz"] = "霓炎",
["cv:lol_tqz"] = " ",
["illustrator:lol_tqz"] = " ",
}

lol_xlnw = sgs.General(extension, "lol_xlnw", "god", 3, false)
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do result:append(theTable[i]) end
	return result
end
lol_xlnw_t = sgs.CreateTriggerSkill{
	name = "lol_xlnw_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneral2Name() == "lol_xlnw_pks" or (p:getMark("@lol_xlnw_t")  > 0) then 
			local pks = player:getTag("lol_xlnw_pks"):toString()
			if pks ~= "" then 
				player:setTag("lol_xlnw_pks", sgs.QVariant())
				local mhp = sgs.QVariant(p:getMaxHp())
				local hp = sgs.QVariant(p:getHp())	
				if p:getGeneral2Name() == "lol_xlnw_pks" then
					room:changeHero(p, pks, false, false, true, true) 
					room:setPlayerProperty(p, "maxhp", mhp)	
					room:setPlayerProperty(p, "hp", hp)	
				else
					room:setPlayerMark(p, "@lol_xlnw_t", 0)
				end
			end
		end
		end
        room:broadcastSkillInvoke("lol_xlnw_t")	
        room:notifySkillInvoked(player, self:objectName())			
		local mhp = sgs.QVariant(player:getMaxHp())
		local hp = sgs.QVariant(player:getHp())
		if  player:getGeneralName() == "lol_xlnw" then 
			if player:getGeneral2Name() ~= nil then
				room:setPlayerMark(player, "@lol_xlnw_t", 1)
			else
				room:changeHero(player, "lol_xlnw_pks", true, true, true, true)
				room:setPlayerProperty(player, "maxhp", mhp)
				room:setPlayerProperty(player, "hp", hp)
			end
		else 
		room:setPlayerMark(player, "@lol_xlnw_t", 1)
		end
	end
}
lol_xlnw_qVS = sgs.CreateViewAsSkill{
	name = "lol_xlnw_q" ,
	n = 1,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		return to_select:getSuit() == sgs.Card_Club and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and not player:hasFlag("lol_xlnw_q")
	end
}
lol_xlnw_q = sgs.CreateTriggerSkill{
	name = "lol_xlnw_q",
	events = {sgs.TargetConfirmed, sgs.CardOffset},
	view_as_skill = lol_xlnw_qVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then room:setPlayerFlag(player, "lol_xlnw_q") end
	    elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			local pks
			for _,pet in sgs.qlist(room:getAlivePlayers()) do
				if pet:getGeneral2Name() == "lol_xlnw_pks" or (pet:getMark("@lol_xlnw_t") > 0 ) then pks = pet end
			end			
			if pks then 
			if  effect.card and effect.card:isKindOf("Slash") and effect.card:getSkillName() == self:objectName() then
				if pks:canSlash(effect.to, nil, true) then 
				    room:askForUseSlashTo(pks, effect.to, "@lol_xlnw_q_slash:" .. effect.to:objectName())
					room:notifySkillInvoked(player, self:objectName())	
					end
				end				
			end
		end
	end
}
lol_xlnw_wCard = sgs.CreateSkillCard{
	name = "lol_xlnw_wCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:obtainCard(effect.to, self, false)
		room:acquireSkill(effect.to, "#lol_turn")	
		room:acquireSkill(effect.to, "lol_jiansu")		
		if self:getSuit() == sgs.Card_Heart then
		    if effect.to:getPile("lol_jiasu"):length() == 0 then effect.to:addToPile("lol_jiasu", room:getNCards(1)) end		
		elseif self:getSuit() == sgs.Card_Club then
		    room:setTag("lol_xlnw_w_change", sgs.QVariant(effect.to:getGeneralName()))
			local mhp = sgs.QVariant(effect.to:getMaxHp())
			local hp = sgs.QVariant(effect.to:getHp())
			room:changeHero(effect.to, "lol_xlnw_pet", false, false, false, true)
			room:setPlayerProperty(effect.to, "maxhp", mhp)	
			room:setPlayerProperty(effect.to, "hp", hp)	
			if effect.to:getPile("lol_jiansu"):length() == 0 then effect.to:addToPile("lol_jiansu", room:getNCards(1)) end		
		end						
	end
}
lol_xlnw_wVS = sgs.CreateViewAsSkill{
	name = "lol_xlnw_w",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:getSuit() == sgs.Card_Heart or to_select:getSuit() == sgs.Card_Club) and not to_select:isEquipped() 
	end,
	view_as = function(self, cards)
		if #cards ~=1 then return false end
		local card = lol_xlnw_wCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_xlnw_wCard")
	end
}
lol_xlnw_w = sgs.CreateTriggerSkill{
	name = "lol_xlnw_w" ,
	events = {sgs.EventPhaseStart},
	view_as_skill = lol_xlnw_wVS ,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and room:getTag("lol_xlnw_w_change") then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "lol_xlnw_pet" then
					local mhp = sgs.QVariant(p:getMaxHp())
					local hp = sgs.QVariant(p:getHp())
					room:changeHero(p, room:getTag("lol_xlnw_w_change"):toString(), false, false, false, true)
					room:setPlayerProperty(p, "maxhp", mhp)	
					room:setPlayerProperty(p, "hp", hp)	                    				
				end
			end	
			room:removeTag("lol_xlnw_w_change")
        end			
	end
}
lol_xlnw_eCard = sgs.CreateSkillCard{
	name = "lol_xlnw_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getGeneral2Name() ~= "lol_xlnw_pks" and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneral2Name() == "lol_xlnw_pks" then 
			local pks = effect.from:getTag("lol_xlnw_pks"):toString()
			if pks ~= "" then 
				effect.from:setTag("lol_xlnw_pks", sgs.QVariant())
				local mhp = sgs.QVariant(p:getMaxHp())
				local hp = sgs.QVariant(p:getHp())			
			    room:changeHero(p, pks, false, false, true, false) 
				room:setPlayerProperty(p, "maxhp", mhp)	
		        room:setPlayerProperty(p, "hp", hp)	
			end
			end
		end	
		local mhp = sgs.QVariant(effect.to:getMaxHp())
		local hp = sgs.QVariant(effect.to:getHp())			
		local pks = effect.from:getTag("lol_xlnw_pks"):toString()
		effect.from:setTag("lol_xlnw_pks",sgs.QVariant(effect.to:getGeneral2Name()) )
      --  room:changeHero(effect.to, "lol_xlnw_pks", false, false, true, true)
	  if  effect.to:getGeneral2Name() == nil then  
		room:changeHero(effect.to, "lol_xlnw_pks", true, true, true, true)
		room:setPlayerProperty(effect.to, "maxhp", mhp)
		room:setPlayerProperty(effect.to, "hp", hp)
		else 
		room:setPlayerMark(effect.to, "@lol_xlnw_t", 1)
		end
		effect.from:loseMark("@lol_xlnw_t")
		room:setPlayerProperty(effect.to, "maxhp", mhp)	
		room:setPlayerProperty(effect.to, "hp", hp)			
		if effect.from:getGeneralName() == "lol_xlnw" and effect.from:getGeneral2Name() == "lol_xlnw_pks"  then 
			room:changeHero(effect.from, nil, false, false, true, true)
		else
			room:setPlayerMark(effect.from, "@lol_xlnw_t", 0)
		end
		end
}
lol_xlnw_eVS = sgs.CreateViewAsSkill{
	name = "lol_xlnw_e",
	n = 0,
	view_as = function(self, cards)
		return lol_xlnw_eCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_xlnw_eCard")
	end
}
lol_xlnw_e = sgs.CreateTriggerSkill{
	name = "lol_xlnw_e" ,
	events = {sgs.TargetConfirmed},
	view_as_skill = lol_xlnw_eVS ,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (use.from:getGeneral2Name() == "lol_xlnw_pks" or use.from:getMark("@lol_xlnw_t") > 0) then
			local pks
			for _,pet in sgs.qlist(room:getAlivePlayers()) do
				if (pet:getGeneral2Name() == "lol_xlnw_pks") or  pet:getMark("@lol_xlnw_t") > 0 then pks = pet end
			end			
			for _,p in sgs.qlist(use.to) do	
				if pks and not pks:isKongcheng() then
					local dest = sgs.QVariant()
					dest:setValue(p)
				    if player:askForSkillInvoke(self:objectName(), dest) then
						room:askForDiscard(pks, self:objectName(), 1, 1, false)
						local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
						for i = 0, use.to:length() - 1, 1 do
							if jink_table[i + 1] == 1 then jink_table[i + 1] = 2 end
						end
						local jink_data = sgs.QVariant()
						jink_data:setValue(Table2IntList(jink_table))
						use.from:setTag("Jink_" .. use.card:toString(), jink_data)
                    end						
				end 
            end				
		end			
	end
}
lol_xlnw_rCard = sgs.CreateSkillCard{
	name = "lol_xlnw_rCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHp() == self:getSubcards():length()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
	    room:doLightbox("$lol_xlnw_image", 1500)
		room:removePlayerMark(effect.from, "@lol_xlnw_r")
		local mhp = sgs.QVariant((effect.to:getMaxHp() + 1))
		room:setPlayerProperty(effect.to, "maxhp", mhp)
		local recover = sgs.RecoverStruct()
		recover.who = effect.from
		room:recover(effect.to, recover)
        for _,p in sgs.qlist(room:getAlivePlayers()) do
		    if effect.to:distanceTo(p) == 1 then
				for _,equip in sgs.qlist(p:getEquips()) do p:obtainCard(equip) end
            end				
		end	
	end
}
lol_xlnw_rVS = sgs.CreateViewAsSkill{
	name = "lol_xlnw_r" ,
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local card = lol_xlnw_rCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_xlnw_r") >= 1
	end
}
lol_xlnw_r = sgs.CreateTriggerSkill{
	name = "lol_xlnw_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_xlnw_r",
	events = {},
	view_as_skill = lol_xlnw_rVS ,
    on_trigger = function()
		return false
	end
}
lol_xlnw:addSkill(lol_xlnw_q)
lol_xlnw:addSkill(lol_xlnw_w)
lol_xlnw:addSkill(lol_xlnw_e)
lol_xlnw:addSkill(lol_xlnw_r)
lol_xlnw:addSkill(lol_xlnw_t)
sgs.LoadTranslationTable{ 
["#lol_xlnw"] = "仙灵女巫",
["lol_xlnw"] = "璐璐",
["lol_xlnw_pks"] = "皮克斯",
["lol_xlnw_pet"] = "可爱动物",
["@lol_xlnw_t"] = "皮克斯",
["~lol_xlnw"] = "啊，快晕了...",
["lol_xlnw_t"] = "被动",
[":lol_xlnw_t"] = "<font color=\"purple\"><b>【皮克斯，仙灵伙伴】</b></font><font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你将皮克斯作为副将置于你的武将牌旁。",
["$lol_xlnw_t"] = "气势上压倒！",
["lol_xlnw_q"] = "Q",
[":lol_xlnw_q"] = "<font color=\"purple\"><b>【闪耀长枪】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张梅花手牌当【杀】使用，每当你以此法使用的【杀】被目标角色使用的【闪】抵消时，若目标角色在皮克斯的攻击范围内，皮克斯可以对其使用一张【杀】。",
["@lol_xlnw_q_slash"] = "<font color=\"yellow\"><b>璐璐</b></font> 使用了【闪耀长枪】，你可以对 %src 使用一张【杀】",
["$lol_xlnw_q"] = "弄碎他们！皮克斯！",
["lol_xlnw_w"] = "W",
[":lol_xlnw_w"] = "<font color=\"purple\"><b>【奇思妙想】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张红桃或梅花手牌交给一名角色，然后若此牌为红桃牌，令该角色加速（直到其结束阶段开始），若此牌为梅花牌，令该角色变成可爱的动物（直到回合结束）并令其减速（直到其结束阶段开始）。",
["$lol_xlnw_w"] = "见到你很高兴。",
["lol_xlnw_e"] = "E",
[":lol_xlnw_e"] = "<font color=\"purple\"><b>【帮忙，皮克斯！】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以令一名角色将皮克斯作为副将置于其武将牌旁。每当皮克斯使用【杀】指定一名目标角色后，你可以令皮克斯弃置一张手牌，若如此做，该角色需依次使用两张【闪】才能抵消。",
["$lol_xlnw_e"] = "再去四处走走吧！哈！",
["lol_xlnw_r"] = "R",
[":lol_xlnw_r"] = "<font color=\"purple\"><b>【狂野生长】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置任意张手牌并选择一名体力值为X角色（X为你以此法弃置的手牌数），令其增加1点体力上限并回复1点体力，然后击飞其距离为1的所有角色。",
["#lol_xlnw_r_log"] = "【狂野生长】失效了",
["$lol_xlnw_image"] = "image=image/animate/lol_xlnw_r.png",
["$lol_xlnw_r"] = "巨人出现！",
["designer:lol_xlnw"] = "霓炎",
["cv:lol_xlnw"] = " ",
["illustrator:lol_xlnw"] = " ",
}

lol_smss = sgs.General(extension, "lol_smss", "god", 4, true)
lol_smss_t = sgs.CreateTriggerSkill{
	name = "lol_smss_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local damage = data:toDamage()	
		if damage.damage >= 2 and damage.to:objectName() ~= player:objectName() and player:isWounded() then
		    room:broadcastSkillInvoke("lol_smss_t")	
            room:notifySkillInvoked(player, self:objectName())				
		    local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		end
	end
}
lol_smss_qCard = sgs.CreateSkillCard{
	name = "lol_smss_qCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		player:setFlags("lol_smss_q")
	end
}
lol_smss_qVS = sgs.CreateViewAsSkill{
	name = "lol_smss_q" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		return #cards == 0 and not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = lol_smss_qCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_smss_qCard")
	end
}
lol_smss_q = sgs.CreateTriggerSkill{
	name = "lol_smss_q" ,
	events = {sgs.ConfirmDamage, sgs.Death, sgs.CardFinished} ,
	view_as_skill = lol_smss_qVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName() and player:hasFlag("lol_smss_q") then	
				damage.damage = damage.damage + player:getMark("@lol_smss_q")
				data:setValue(damage)			
			end
		elseif event == sgs.Death then
		    local death = data:toDeath()		
			if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() and player:hasFlag("lol_smss_q") then 
				room:setPlayerMark(player, "@lol_smss_q", player:getMark("@lol_smss_q") + 1)
			end
		elseif event == sgs.CardFinished then	
		    local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() and player:hasFlag("lol_smss_q") then
			    player:setFlags("-lol_smss_q")
			end
		end
	end
}
lol_smss_wCard = sgs.CreateSkillCard{
	name = "lol_smss_wCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
        room:acquireSkill(effect.to, "#lol_turn")			
		room:acquireSkill(effect.to, "lol_jiansu")
		if effect.to:getPile("lol_jiansu"):length() == 0 then effect.to:addToPile("lol_jiansu", room:getNCards(1)) end		
	end
}
lol_smss_w = sgs.CreateViewAsSkill{
	name = "lol_smss_w",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~=1 then return false end
		local card = lol_smss_wCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_smss_wCard")
	end
}
lol_smss_eCard = sgs.CreateSkillCard{
	name = "lol_smss_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		n = 3
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		    if effect.to:distanceTo(p) == 1 then n = n - 1 end
        end
        if n > 0 then
			if not room:askForDiscard(effect.to, self:objectName(), n, n, true, true) then 
			    room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Fire))
			end
		end
	end
}
lol_smss_e = sgs.CreateViewAsSkill{
	name = "lol_smss_e",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~=1 then return false end
		local card = lol_smss_eCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_smss_eCard")
	end
}
lol_smss_rCard = sgs.CreateSkillCard{
	name = "lol_smss_rCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHp() == self:getSubcards():length() and to_select:objectName() == sgs.Self:objectName()
	end,
	on_use = function(self, room, player, targets)
	    local room = player:getRoom()
	    room:doLightbox("$lol_smss_image", 1500)
		room:removePlayerMark(player, "@lol_smss_r")
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:distanceTo(p) <= 1 and not p:isKongcheng() then
				local card_id = room:askForCardChosen(player, p, "h", self:objectName())
				room:obtainCard(player, card_id, true)
			end
		end
		local mhp = sgs.QVariant(player:getMaxHp() + 1)
		room:setPlayerProperty(player, "maxhp", mhp)
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover)
	end
}
lol_smss_rVS = sgs.CreateViewAsSkill{
	name = "lol_smss_r" ,
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local card = lol_smss_rCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_smss_r") >= 1
	end
}
lol_smss_r = sgs.CreateTriggerSkill{
	name = "lol_smss_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_smss_r",
	events = {},
	view_as_skill = lol_smss_rVS ,
    on_trigger = function()
		return false
	end
}
lol_smss:addSkill(lol_smss_q)
lol_smss:addSkill(lol_smss_w)
lol_smss:addSkill(lol_smss_e)
lol_smss:addSkill(lol_smss_r)
lol_smss:addSkill(lol_smss_t)
sgs.LoadTranslationTable{ 
["#lol_smss"] = "沙漠死神",
["lol_smss"] = "内瑟斯",
["~lol_smss"] = "咳...",
["lol_smss_t"] = "被动",
[":lol_smss_t"] = "<font color=\"purple\"><b>【吞噬灵魂】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你对其他角色造成不少于2点的伤害后，若你已受伤，你回复1点体力。",
["$lol_smss_t"] = "很快这儿就什么都不会剩下了。",
["lol_smss_q"] = "Q",
[":lol_smss_q"] = "<font color=\"purple\"><b>【汲魂痛击】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌，若如此做，直到回合结束，你使用的下一张【杀】对目标角色造成伤害时，此伤害+X（X为本场游戏中你发动【汲魂痛击】后使用【杀】杀死的角色数）。",
["$lol_smss_q"] = "死亡与我同在。",
["lol_smss_w"] = "W",
[":lol_smss_w"] = "<font color=\"purple\"><b>【枯萎】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张黑桃手牌并选择一名其他角色，令其减速（直到其结束阶段开始）。",
["$lol_smss_w"] = "不要考验我的耐心。",
["lol_smss_e"] = "E",
[":lol_smss_e"] = "<font color=\"purple\"><b>【灵魂烈焰】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张红桃手牌并选择一名其他角色，令其选择一项：1.弃置3-X张牌（X为其距离1的角色数）；2.受到你对其造成的1点火焰伤害。",
["$lol_smss_e"] = "这儿连天使都不敢踏足。",
["lol_smss_r"] = "R",
[":lol_smss_r"] = "<font color=\"purple\"><b>【死神降临】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置X张黑色手牌（X为你的体力值），获得距离1以内所有其他角色的各一张手牌，然后增加1点体力上限并回复1点体力。",
["$lol_smss_image"] = "image=image/animate/lol_smss_r.png",
["$lol_smss_r"] = "他们的死亡就要降临了。",
["designer:lol_smss"] = "霓炎",
["cv:lol_smss"] = " ",
["illustrator:lol_smss"] = " ",
}

lol_ayjm = sgs.General(extension, "lol_ayjm", "god", 4, true)
lol_ayjm_t = sgs.CreateTriggerSkill{
	name = "lol_ayjm_t" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local dying = data:toDying()
		local blood = player:getMark("@lol_ayjm_t")			
		if dying.who:objectName() == player:objectName() and blood > 0 then
			room:broadcastSkillInvoke("lol_ayjm_t")	
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerMark(player, "@lol_ayjm_t", 0)
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = blood
			room:recover(player, recover)
		end
	end
}
lol_ayjm_qVS = sgs.CreateViewAsSkill{
	name = "lol_ayjm_q" ,
	n = 0,
	view_as = function(self, cards)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return player:getHp() > 1 and not player:hasFlag("lol_ayjm_q") and sgs.Slash_IsAvailable(player)
	end
}
lol_ayjm_q = sgs.CreateTriggerSkill{
	name = "lol_ayjm_q",
	events = {sgs.TargetConfirmed},
	view_as_skill = lol_ayjm_qVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then 		    
		    room:setPlayerFlag(player, "lol_ayjm_q")
            room:loseHp(player, 1, true, player, self:objectName())
			room:setPlayerMark(player, "@lol_ayjm_t", player:getMark("@lol_ayjm_t") + 1)
			for _,p in sgs.qlist(use.to) do
				for _,equip in sgs.qlist(p:getEquips()) do p:obtainCard(equip) end				
			end			
		end
	end
}
lol_ayjm_w = sgs.CreateTriggerSkill{
	name = "lol_ayjm_w",
	events = {sgs.GameStart, sgs.TargetConfirmed, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
            room:setPlayerMark(player, "@lol_ayjm_w", 3) 
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then 
			    room:setPlayerMark(player, "@lol_ayjm_w", player:getMark("@lol_ayjm_w") - 1)			
			end
			if player:getMark("@lol_ayjm_w") == 0 then
			    room:setCardFlag(use.card, "lol_ayjm_w")
			    room:setPlayerMark(player, "@lol_ayjm_w", 3)				
			end
		elseif event == sgs.ConfirmDamage then
		    local damage = data:toDamage()
			if player and damage.card and damage.card:hasFlag("lol_ayjm_w") then
				local string = (player:getHp() > 1 and player:isWounded() and "lol_ayjm_w_damage+lol_ayjm_w_hp+cancel") 
				            or (player:getHp() > 1 and not player:isWounded() and "lol_ayjm_w_damage+cancel")
							or (player:getHp() <= 1 and player:isWounded() and "lol_ayjm_w_hp+cancel")
							or (player:getHp() <= 1 and not player:isWounded() and "cancel")
			    local choice = room:askForChoice(player, self:objectName(), string, data)
				room:broadcastSkillInvoke("lol_ayjm_w")	
				room:notifySkillInvoked(player, self:objectName())
				if choice == "lol_ayjm_w_damage" then
					room:loseHp(player, 1, true, player, self:objectName())
					room:setPlayerMark(player, "@lol_ayjm_t", player:getMark("@lol_ayjm_t") + 1)
					damage.damage = damage.damage + 1
					data:setValue(damage)				
				elseif choice == "lol_ayjm_w_hp" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)				
				end
			end
		end
	end
}
lol_ayjm_eVS = sgs.CreateViewAsSkill{
	name = "lol_ayjm_e" ,
	n = 0,
	view_as = function(self, cards)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return player:getHp() > 1 and not player:hasFlag("lol_ayjm_e") and sgs.Slash_IsAvailable(player)
	end
}
lol_ayjm_e = sgs.CreateTriggerSkill{
	name = "lol_ayjm_e",
	events = {sgs.TargetConfirmed, sgs.Damage},
	view_as_skill = lol_ayjm_eVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
		    if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then 	
				room:loseHp(player, 1, true, player, self:objectName())
				room:setPlayerMark(player, "@lol_ayjm_t", player:getMark("@lol_ayjm_t") + 1)
				room:setPlayerFlag(player, "lol_ayjm_e")				
            end				
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() then			    
				room:acquireSkill(damage.to, "#lol_turn")			
				room:acquireSkill(damage.to, "lol_jiansu")
				if damage.to:getPile("lol_jiansu"):length() == 0 then damage.to:addToPile("lol_jiansu", room:getNCards(1)) end			
			end
		end
	end
}
lol_ayjm_rCard = sgs.CreateSkillCard{
	name = "lol_ayjm_rCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    room:doLightbox("$lol_ayjm_image", 1500)
		room:removePlayerMark(player, "@lol_ayjm_r")
		room:setPlayerFlag(player, "lol_ayjm_r_flag")
	end
}
lol_ayjm_rVS = sgs.CreateViewAsSkill{
	name = "lol_ayjm_r" ,
	n = 0,
	view_as = function()
		return lol_ayjm_rCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_ayjm_r") >= 1
	end
}
lol_ayjm_r = sgs.CreateTriggerSkill{
	name = "lol_ayjm_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_ayjm_r",
	events = {},
	view_as_skill = lol_ayjm_rVS,
    on_trigger = function()
		return false
	end
}
lol_ayjm_r_slash = sgs.CreateTargetModSkill{
	name = "#lol_ayjm_r_slash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasFlag("lol_ayjm_r_flag") then return 1 end
	end,
}
lol_ayjm:addSkill(lol_ayjm_q)
lol_ayjm:addSkill(lol_ayjm_w)
lol_ayjm:addSkill(lol_ayjm_e)
lol_ayjm:addSkill(lol_ayjm_r)
lol_ayjm:addSkill(lol_ayjm_r_slash)
lol_ayjm:addSkill(lol_ayjm_t)
extension:insertRelatedSkills("lol_ayjm_r", "#lol_ayjm_r_slash")
sgs.LoadTranslationTable{ 
["#lol_ayjm"] = "暗裔剑魔",
["lol_ayjm"] = "亚托克斯",
["~lol_ayjm"] = "恨呐……",
["lol_ayjm_t"] = "被动",
[":lol_ayjm_t"] = "<font color=\"purple\"><b>【鲜血魔井】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你因“黑暗之跃”/“血之渴望”/“痛苦利刃”失去体力后，你获得1枚“鲜血”标记。<font color=\"blue\"><b>锁定技，</b></font>每当你进入濒死状态时，你弃置所有“鲜血”标记，以此法每失去1枚“鲜血”标记，你回复1点体力。",
["$lol_ayjm_t"] = "我和战争一样永恒。",
["lol_ayjm_q"] = "Q",
[":lol_ayjm_q"] = "<font color=\"purple\"><b>【黑暗之跃】</b></font><font color=\"green\"><b>阶段技，</b></font>若你的体力值大于1，你可以失去1点体力，视为使用一张【杀】，每当你以此法使用【杀】指定一名目标角色后，将其击飞。",
["$lol_ayjm_q"] = "犹豫即是死亡。",
["lol_ayjm_w"] = "W",
[":lol_ayjm_w"] = "<font color=\"purple\"><b>【血之渴望】</b></font>你每使用两张【杀】，当你使用下一张【杀】对目标角色造成伤害时，你选择一项：1.若你的体力值大于1，你失去1点体力，令此伤害值+1；2.若你已受伤，你回复1点体力。",
["$lol_ayjm_w"] = "真正的战士生于鲜血之中。",
["lol_ayjm_w_damage"] = "失去1点体力，令此伤害+1",
["lol_ayjm_w_hp"] = "回复1点体力",
["lol_ayjm_e"] = "E",
[":lol_ayjm_e"] = "<font color=\"purple\"><b>【痛苦利刃】</b></font><font color=\"green\"><b>阶段技，</b></font>若你的体力值大于1，你可以失去1点体力，视为使用一张【杀】，每当你以此法使用【杀】对目标角色造成伤害后，令其减速（直到其结束阶段开始）。",
["$lol_ayjm_e"] = "没有撤退可言。",
["lol_ayjm_r"] = "R",
[":lol_ayjm_r"] = "<font color=\"purple\"><b>【浴血屠戮】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令你能额外使用一张【杀】，直到回合结束。",
["$lol_ayjm_image"] = "image=image/animate/lol_ayjm_r.png",
["$lol_ayjm_r"] = "要么战斗，要么被遗忘。",
["designer:lol_ayjm"] = "霓炎",
["cv:lol_ayjm"] = " ",
["illustrator:lol_ayjm"] = " ",
}

lol_bjfh = sgs.General(extension, "lol_bjfh", "god", 3, false)
lol_bjfh_t = sgs.CreateTriggerSkill{
	name = "lol_bjfh_t" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local dying = data:toDying()	
		if dying.who:objectName() == player:objectName() then
			room:notifySkillInvoked(player, self:objectName())
				if player:getGeneralName() == "lol_bjfh" then
					room:changeHero(player, "lol_bjfh_egg",false, false, false, true)
				elseif player:getGeneral2Name() == "lol_bjfh" then
					room:changeHero(player, "lol_bjfh_egg",false, false, true, true)
				end
		    room:setPlayerProperty(player, "maxhp", sgs.QVariant(1))
		    room:setPlayerProperty(player, "hp", sgs.QVariant(1))	
			room:setPlayerFlag(player, "-Global_Dying")
			local currentdying = room:getTag("CurrentDying"):toStringList()
			table.removeOne(currentdying,player:objectName())
			room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
		end
	end
}
lol_bjfh_egg_t = sgs.CreateTriggerSkill{
	name = "lol_bjfh_egg_t",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:broadcastSkillInvoke("lol_bjfh_t")	
            room:notifySkillInvoked(player, self:objectName())			
			if player:getGeneralName() == "lol_bjfh_egg" then
					room:changeHero(player, "lol_bjfh",false, false, false, true)
				elseif player:getGeneral2Name() == "lol_bjfh_egg" then
					room:changeHero(player, "lol_bjfh",false, false, true, true)
				end
			if player:hasSkill("lol_bjfh_t") then room:detachSkillFromPlayer(player, "lol_bjfh_t") end	
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(3))
		    room:setPlayerProperty(player, "hp", sgs.QVariant(3))		
		end 
	end
}
lol_bjfh_qCard = sgs.CreateSkillCard{
	name = "lol_bjfh_qCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		dest = effect.to
		while dest do
	        local judge = sgs.JudgeStruct()
			judge.who = dest	
			judge.pattern = ".|diamond"
			judge.good = false
			judge.negative = true
			judge.reason = "lol_bjfh_q"
			room:judge(judge)
			if judge:isBad() then
				room:damage(sgs.DamageStruct(self:objectName(), effect.from, dest, 1))			
				room:acquireSkill(dest, "#lol_turn")			
				room:acquireSkill(dest, "lol_jiansu")
				if dest:getPile("lol_jiansu"):length() == 0 then dest:addToPile("lol_jiansu", room:getNCards(1)) end	
				break
			else			    
				if dest and dest:getNextAlive() and dest:getNextAlive():objectName() ~= effect.from:objectName() then dest = dest:getNextAlive()
				else break
				end				    				
			end
		end	
	end
}
lol_bjfh_qVS = sgs.CreateViewAsSkill{
	name = "lol_bjfh_q" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = lol_bjfh_qCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
        return not player:hasUsed("#lol_bjfh_qCard")
	end
}
lol_bjfh_q = sgs.CreateTriggerSkill{
	name = "lol_bjfh_q",
	events = {sgs.AskForRetrial},
	view_as_skill = lol_bjfh_qVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local judge = data:toJudge()
		if judge.reason ~= self:objectName() then return false end
		local prompt_list = {"@lol_bjfh_q-card", judge.who:objectName(), self:objectName(), "lol_bjfh_q", string.format("%d", judge.card:getEffectiveId())}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".|red", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then room:retrial(card, player, judge, self:objectName(), true) end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and not target:isKongcheng()
	end
}
lol_bjfh_wCard = sgs.CreateSkillCard{
	name = "lol_bjfh_wCard", 
	filter = function(self, targets, to_select) 
		if #targets == 0 then 
		    return to_select:objectName() ~= sgs.Self:objectName()
		elseif #targets == 1 then
			local last
			for _,p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				if last and to_select:objectName() == last:objectName() and targets[1]:objectName() == p:objectName() then return true
				elseif last and to_select:objectName() == p:objectName() and targets[1]:objectName() == last:objectName() then return true
				end
				last = p
			end
	    end
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room,source,targets)
	    if targets[1]:objectName() == targets[2]:getNext():objectName() then dest = targets[1]
        elseif targets[2]:objectName() == targets[1]:getNext():objectName() then dest = targets[2]		
	    end
		wp = dest
		room:setPlayerMark(dest, "@lol_bjfh_w", 1)			
		for i = 1, room:getAlivePlayers():length(), 1 do
			room:setPlayerMark(wp, "lol_bjfh_w", i)		
			if i == room:getAlivePlayers():length() then room:setPlayerMark(wp, "@lol_bjfh_w", 1) end
			wp = wp:getNextAlive()
		end				
	end
}
lol_bjfh_wVS = sgs.CreateViewAsSkill{
	name = "lol_bjfh_w",
	n = 1, 
	view_filter = function(self, cards, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = lol_bjfh_wCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_bjfh_wCard")
	end
}
lol_bjfh_w = sgs.CreateTriggerSkill{
	name = "lol_bjfh_w",
    view_as_skill = lol_bjfh_wVS,
	events = {sgs.EventPhaseStart, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				p:loseAllMarks("@lol_bjfh_w")
				p:loseAllMarks("lol_bjfh_w")
			end	
        elseif event == sgs.Death then		
			local death = data:toDeath()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("lol_bjfh_w") > death.who:getMark("lol_bjfh_w") then p:loseMark("lol_bjfh_w") end
			end
			death.who:loseAllMarks("lol_bjfh_w")
			if death.who:getMark("@lol_bjfh_w") == 0 then return false end
			if death.who:getNextAlive():getMark("@lol_bjfh_w") == 0 then
				room:setPlayerMark(death.who:getNextAlive(), "@lol_bjfh_w", 1)				
			else
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getNext():objectName() == death.who:objectName() then room:setPlayerMark(p, "@lol_bjfh_w", 1)	end
				end				    
			end
        end			
	end
}
lol_bjfh_wDistance = sgs.CreateDistanceSkill{
	name = "#lol_bjfh_wDistance",
	correct_func = function(self, from, to)		
		local n = 1
		for _,p in sgs.qlist(from:getSiblings()) do
			if p:isAlive() then n = n + 1 end
		end
		local ncut = math.abs(to:getMark("lol_bjfh_w") - from:getMark("lol_bjfh_w"))
		--return ncut - math.min(ncut, n - ncut)
		return math.max(2 * ncut - n, 0)
	end
}
lol_bjfh_eCard = sgs.CreateSkillCard{
	name = "lol_bjfh_eCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = effect.to		
		judge.pattern = ".|diamond"
		judge.good = false
		judge.negative = true
		judge.reason = self:objectName()
		room:judge(judge)
		if judge:isBad() then room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1)) end
		if effect.to and effect.to:getPile("lol_jiansu"):length() > 0 then
			local judge = sgs.JudgeStruct()
			judge.who = effect.to		
			judge.pattern = ".|diamond"
			judge.good = false
			judge.negative = true
			judge.reason = self:objectName()
			room:judge(judge)		  
            if judge:isBad() then room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1)) end			
		end
	end
}
lol_bjfh_e = sgs.CreateViewAsSkill{
	name = "lol_bjfh_e",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_bjfh_eCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_bjfh_eCard")
	end
}
lol_bjfh_rCard = sgs.CreateSkillCard{
	name = "lol_bjfh_rCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets >= 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerMark(effect.from, "@lol_bjfh_r", 0)
		room:setPlayerMark(effect.to, "@lol_bjfh_r", 1)
	end
}
lol_bjfh_rVS = sgs.CreateViewAsSkill{
	name = "lol_bjfh_r",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_bjfh_rCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_bjfh_r") >= 1
	end
}
lol_bjfh_r = sgs.CreateTriggerSkill{
	name = "lol_bjfh_r" ,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	view_as_skill = lol_bjfh_rVS ,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.GameStart then
		    room:setPlayerMark(player, "@lol_bjfh_r", 1)
		elseif event == sgs.EventPhaseStart then
			if player:getMark("@lol_bjfh_r") == 1 or player:getPhase() ~= sgs.Player_Finish then return false end
			if room:askForCard(player, ".", "lol_bjfh_r_discard", sgs.QVariant(), sgs.CardDiscarded) then
			    room:doLightbox("$lol_bjfh_image", 1500)
				for _,p in sgs.qlist(room:getAlivePlayers()) do
				    if p:getMark("@lol_bjfh_r") == 1 then
						local judge = sgs.JudgeStruct()
						judge.who = p	
						judge.pattern = ".|diamond"
						judge.good = false
						judge.negative = true
						judge.reason = self:objectName()
						room:judge(judge)
						if judge:isBad() then
							room:damage(sgs.DamageStruct(self:objectName(), player, p, 1))			
							room:acquireSkill(p, "#lol_turn")			
							room:acquireSkill(p, "lol_jiansu")
							if p:getPile("lol_jiansu"):length() == 0 then p:addToPile("lol_jiansu", room:getNCards(1)) end	
						end	
					end
                end					
			else			    
				for _,p in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(p, "@lol_bjfh_r", 0) end
				room:setPlayerMark(player, "@lol_bjfh_r", 1)
			end
		end
	end
}
lol_bjfh:addSkill(lol_bjfh_q)
lol_bjfh:addSkill(lol_bjfh_w)
lol_bjfh:addSkill(lol_bjfh_wDistance)
lol_bjfh:addSkill(lol_bjfh_e)
lol_bjfh:addSkill(lol_bjfh_r)
lol_bjfh:addSkill(lol_bjfh_t)
extension:insertRelatedSkills("lol_bjfh_w", "#lol_bjfh_wDistance")
lol_bjfh_egg:addSkill(lol_bjfh_egg_t)
sgs.LoadTranslationTable{ 
["#lol_bjfh"] = "冰晶凤凰",
["lol_bjfh"] = "艾尼维亚",
["~lol_bjfh"] = "啊……",
["lol_bjfh_egg"] = "凤凰蛋",
["lol_bjfh_egg_t"] = "涅槃",
[":lol_bjfh_egg_t"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你变成艾尼维亚，失去【寒霜涅槃】，然后回复至3点体力。",
["lol_bjfh_t"] = "被动",
[":lol_bjfh_t"] = "<font color=\"purple\"><b>【寒霜涅槃】</b></font><font color=\"blue\"><b>锁定技，</b></font>当你进入濒死状态时，你变成凤凰蛋，然后回复至1点体力。\
凤凰蛋为女性角色，体力上限为1，拥有技能“涅槃”（准备阶段开始时，你变成艾尼维亚，失去【寒霜涅槃】，然后回复至3点体力）。",                                                                                                       
["$lol_bjfh_t"] = "展翅翱翔。",
["lol_bjfh_q"] = "Q",
["@lol_bjfh_q-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
[":lol_bjfh_q"] = "<font color=\"purple\"><b>【寒冰闪耀】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张红色手牌并选择一名其他角色，令其进行判定，其判定牌生效前，你可以打出一张红色手牌替换之。若结果为方片，你对其造成1点伤害，并令其减速（直到其结束阶段开始）；若结果不为方片且其下家不为你，你令其下家进行判定并重复此流程。",
["$lol_bjfh_q"] = "保持冷静。",
["lol_bjfh_w"] = "W",
[":lol_bjfh_w"] = "<font color=\"purple\"><b>【寒冰屏障】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌并选择两名位置相邻的其他角色，在这两名角色间制造一道冰墙，直到你的准备阶段开始。<font color=\"blue\"><b>锁定技，</b></font>所有角色不能越过冰墙计算距离。",
["$lol_bjfh_w"] = "很傻很天真。",
["lol_bjfh_e"] = "E",
["lol_bjfh_eCard"] = "E",
[":lol_bjfh_e"] = "<font color=\"purple\"><b>【霜寒刺骨】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌并选择一名其他角色，令其进行判定，若结果为方片，你对其造成1点伤害。若其被减速，令其额外进行一次判定。",
["$lol_bjfh_e"] = "机会转瞬即逝。",
["lol_bjfh_r"] = "R",
[":lol_bjfh_r"] = "<font color=\"purple\"><b>【冰川风暴】</b></font>出牌阶段，若“冰川风暴”处于未发动状态，你可以弃置一张手牌并选择至少一名其他角色，令“冰川风暴”视为处于发动状态。结束阶段开始时，若“冰川风暴”处于发动状态，你选择一项：1.弃置一张手牌，令“冰霜风暴”的目标角色进行判定，若结果为方片，你对其造成1点伤害，并令其减速（直到其结束阶段开始）；2.令“冰川风暴”视为处于未发动状态。",
["$lol_bjfh_image"] = "image=image/animate/lol_bjfh_r.png",
["$lol_bjfh_r"] = "风暴与我同在。",
["lol_bjfh_r_discard"] = "请弃置一张手牌，令“冰霜风暴”的目标角色进行判定",
["designer:lol_bjfh"] = "霓炎",
["cv:lol_bjfh"] = " ",
["illustrator:lol_bjfh"] = " ",
}

lol_sxls = sgs.General(extension, "lol_sxls", "god", 4, true)
lol_sxls_t = sgs.CreateTriggerSkill{
	name = "lol_sxls_t" ,
	events = {sgs.Damage, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if not (damage.to and damage.to:objectName() ~= player:objectName()) then return false end
			room:setPlayerMark(damage.to, "lol_sxls_t", damage.to:getMark("lol_sxls_t") + 1)
			if not (player:isWounded() and damage.to:getMark("lol_sxls_t") >= 2) then return false end
			room:broadcastSkillInvoke("lol_sxls_t")	
			room:notifySkillInvoked(player, self:objectName())
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then	
		    for _,p in sgs.qlist(room:getAlivePlayers()) do 
			    room:setPlayerMark(p, "lol_sxls_t", 0)
			end	
        end		
	end
}
lol_sxls_qVS = sgs.CreateViewAsSkill{
	name = "lol_sxls_q" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		return to_select:getSuit() == sgs.Card_Heart and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	    if #cards ~= 1 then return nil end
		local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber()) 
		slash:addSubcard(cards[1])
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:hasFlag("lol_sxls_q")
	end
}
lol_sxls_q = sgs.CreateTriggerSkill{
	name = "lol_sxls_q" ,
	events = {sgs.TargetConfirmed, sgs.Damage},
	view_as_skill = lol_sxls_qVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then room:setPlayerFlag(player, "lol_sxls_q") end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() then					
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)			
			end			
		end
	end
}
lol_sxls_wCard = sgs.CreateSkillCard{
	name = "lol_sxls_wCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
        room:setPlayerFlag(player, "lol_sxls_w_flag")	
	end
}
lol_sxls_w_slash = sgs.CreateTargetModSkill{
	name = "#lol_sxls_w_slash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasFlag("lol_sxls_w_flag") then return 1 end
	end,
}
lol_sxls_w = sgs.CreateViewAsSkill{
	name = "lol_sxls_w",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_sxls_wCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lol_sxls_wCard")
	end
}
lol_sxls_e_dis = sgs.CreateDistanceSkill{
	name = "#lol_sxls_e_dis",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) and from:getMark("@lol_sxls_e") > 0 and to:isWounded() then return -1 end
	end,
}
lol_sxls_eCard = sgs.CreateSkillCard{
	name = "lol_sxls_eCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
	    if player:getMark("@lol_sxls_e") > 0 then room:setPlayerMark(player, "@lol_sxls_e", 0)
		else room:setPlayerMark(player, "@lol_sxls_e", 1)
		end
	end
}
lol_sxls_e = sgs.CreateViewAsSkill{
	name = "lol_sxls_e",
	n = 0,
	view_as = function(self, cards)
		return lol_sxls_eCard:clone()
	end,
}
lol_sxls_rCard = sgs.CreateSkillCard{
	name = "lol_sxls_rCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
	    room:doLightbox("$lol_sxls_image", 1500)
		room:removePlayerMark(effect.from, "@lol_sxls_r")
		for _,p in sgs.qlist(room:getAlivePlayers()) do room:acquireSkill(p, "#lol_turn") end	
        if effect.to:getPile("lol_yunxuan"):length() == 0 then effect.to:addToPile("lol_yunxuan", room:getNCards(1)) end	
	end
}
lol_sxls_rVS = sgs.CreateViewAsSkill{
	name = "lol_sxls_r" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_sxls_rCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_sxls_r") >= 1
	end
}
lol_sxls_r = sgs.CreateTriggerSkill{
	name = "lol_sxls_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_sxls_r",
	events = {},
	view_as_skill = lol_sxls_rVS ,
    on_trigger = function()
		return false
	end
}
lol_sxls:addSkill(lol_sxls_q)
lol_sxls:addSkill(lol_sxls_w)
lol_sxls:addSkill(lol_sxls_w_slash)
lol_sxls:addSkill(lol_sxls_e)
lol_sxls:addSkill(lol_sxls_e_dis)
lol_sxls:addSkill(lol_sxls_r)
lol_sxls:addSkill(lol_sxls_t)
extension:insertRelatedSkills("lol_sxls_w", "#lol_sxls_w_slash")
extension:insertRelatedSkills("lol_sxls_e", "#lol_sxls_e_dis")
sgs.LoadTranslationTable{ 
["#lol_sxls"] = "嗜血猎手",
["lol_sxls"] = "沃里克",
["~lol_sxls"] = "呃喔……",
["lol_sxls_t"] = "被动",
[":lol_sxls_t"] = "<font color=\"purple\"><b>【血之饥渴】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你于出牌阶段内对其他角色造成伤害后，若此伤害不是你于此阶段内对其造成的首次伤害且你已受伤，你回复1点体力。",
["$lol_sxls_t"] = "我会尽情享受他们的骨头的。",
["lol_sxls_q"] = "Q",
[":lol_sxls_q"] = "<font color=\"purple\"><b>【嗜血攻击】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张红桃手牌当【杀】使用，每当你使用此【杀】对目标角色造成伤害后，若你已受伤，你回复1点体力。",
["$lol_sxls_q"] = "我饿了。",
["lol_sxls_w"] = "W",
[":lol_sxls_w"] = "<font color=\"purple\"><b>【猎手怒吼】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张手牌，令你能额外使用一张【杀】，直到回合结束。",
["$lol_sxls_w"] = "（吼）",
["lol_sxls_e"] = "E",
[":lol_sxls_e"] = "<font color=\"purple\"><b>【血迹追踪】</b></font>激活：你与已受伤的其他角色距离-1。",
["$lol_sxls_e"] = "（嗅）",
["lol_sxls_r"] = "R",
[":lol_sxls_r"] = "<font color=\"purple\"><b>【无尽束缚】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置一张手牌并选择一名其他角色，令其被压制（直到回合结束）。",
["$lol_sxls_image"] = "image=image/animate/lol_sxls_r.png",
["$lol_sxls_r"] = "他们逃跑了我才有乐子。",
["designer:lol_sxls"] = "霓炎",
["cv:lol_sxls"] = " ",
["illustrator:lol_sxls"] = " ",
}


lol_bzll = sgs.General(extension, "lol_bzll", "god", 3, false)
lol_bzll_t = sgs.CreateTriggerSkill{
	name = "lol_bzll_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
        local death = data:toDeath()
		for _,p in sgs.qlist(room:getAlivePlayers()) do room:acquireSkill(p, "#lol_turn") end	
        if player:getPile("lol_jiasu"):length() == 0 then player:addToPile("lol_jiasu", room:getNCards(1)) end			
	end
}
lol_bzll_qCard = sgs.CreateSkillCard{
	name = "lol_bzll_qCard",
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets)
		local idlist = sgs.IntList()
		for _,equip in sgs.qlist(source:getEquips()) do
			if equip:isKindOf("Weapon") then idlist:append(equip:getId()) end
		end
		local moveA = sgs.CardsMoveStruct()
		moveA.card_ids = idlist
		moveA.to = source
		moveA.to_place = sgs.Player_PlaceTable
		room:moveCardsAtomic(moveA, false)
		local moveB = sgs.CardsMoveStruct()
		moveB.card_ids = source:getPile("weapon")
		moveB.to = source
		moveB.to_place = sgs.Player_PlaceEquip
		room:moveCardsAtomic(moveB, false)				
		for _,cardid in sgs.qlist(moveA.card_ids) do
			room:setPlayerMark(source, "lol_bzll_q", sgs.Sanguosha:getCard(cardid):getNumber())		
			source:addToPile("weapon", cardid, true)	
		end
		if source:getPile("weapon"):length() == 0 then room:setPlayerMark(source, "lol_bzll_q", 0) end
	end 
}
lol_bzll_qVS = sgs.CreateViewAsSkill{
	name = "lol_bzll_q", 
	n = 0,  
	view_as = function(self, cards) 
		return lol_bzll_qCard:clone()
	end
}
lol_bzll_q = sgs.CreateTriggerSkill{
	name = "lol_bzll_q",
	events = {sgs.GameStart},
	view_as_skill = lol_bzll_qVS,	
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local cardslist = sgs.IntList()
		local j = 0
		for i = 0, 1000 do
			local acard = sgs.Sanguosha:getCard(room:getDrawPile():at(i))
			if j == 2 then break end
			if acard:isKindOf("Weapon") then
				cardslist:append(room:getDrawPile():at(i))
				j = j + 1			
			end
		end
		if cardslist:isEmpty() then return false end
		local x = 1
		for i = 1, x do	
			room:fillAG(cardslist,player)
			local cardid
			cardid = room:askForAG(player, cardslist, false,self:objectName())
			if cardid == -1 then cardid = cardslist:first() end
			cardslist:removeOne(cardid)
			player:addToPile("weapon", cardid, true)
			room:setPlayerMark(player, "lol_bzll_q", sgs.Sanguosha:getCard(cardid):getNumber())
			room:clearAG(player)
			if cardslist:isEmpty() then break end
		end
	end
}
lol_bzll_wVS = sgs.CreateViewAsSkill{
	name = "lol_bzll_w" ,
	n = 1,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		return to_select:getNumber() > sgs.Self:getMark("lol_bzll_q") and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark("lol_bzll_q") > 0 and not player:hasFlag("lol_bzll_w")
	end
}
lol_bzll_w = sgs.CreateTriggerSkill{
	name = "lol_bzll_w",
	events = {sgs.TargetConfirmed, sgs.Damage},
	view_as_skill = lol_bzll_wVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
		    if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then room:setPlayerFlag(player, "lol_bzll_w") end				
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() then			    
				room:acquireSkill(damage.to, "#lol_turn")			
				room:acquireSkill(damage.to, "lol_jiansu")
				if damage.to:getPile("lol_jiansu"):length() == 0 then damage.to:addToPile("lol_jiansu", room:getNCards(1)) end			
			end
		end
	end
}
lol_bzll_eCard = sgs.CreateSkillCard{
	name = "lol_bzll_eCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    source:gainMark("@lol_bzll_e", 3)
	end
}
lol_bzll_eVS = sgs.CreateViewAsSkill{
	name = "lol_bzll_e",
	n = 1,
	view_filter = function(self, selected, to_select)
	    return true
	end,
	view_as = function(self, cards)
		if #cards < 1 then return false end
		local card = lol_bzll_eCard:clone()
		for _,c in pairs(cards) do card:addSubcard(c) end
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_bzll_e") == 0 and not player:hasUsed("#lol_bzll_eCard") 
	end
}
lol_bzll_e = sgs.CreateTriggerSkill{
	name = "lol_bzll_e" ,
	events = {sgs.CardsMoveOneTime},
	view_as_skill = lol_bzll_eVS,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local move = data:toMoveOneTime()			
		if not (player:isAlive() and player:hasSkill(self:objectName())) then return false end
		if not (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then return false end	
		if (move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive)
		or (move.from and move.from:objectName() ~= player:objectName() and player:getPhase() ~= sgs.Player_NotActive) then
			local can_invoke = false
			for _, card_id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(card_id):getNumber() < player:getMark("lol_bzll_q") then can_invoke = true end
			end
			if can_invoke and player:getMark("@lol_bzll_e") > 0 and player:askForSkillInvoke(self:objectName(), data) then
				room:setPlayerMark(player, "@lol_bzll_e", player:getMark("@lol_bzll_e") - 1)
				if move.from:objectName() == player:objectName() then dest = room:getCurrent()
				else dest = room:findPlayer(move.from:getGeneralName())
				end				
				for _,p in sgs.qlist(room:getAlivePlayers()) do room:acquireSkill(p, "#lol_turn") end	
				if dest:getPile("lol_yunxuan"):length() == 0 then dest:addToPile("lol_yunxuan", room:getNCards(1)) end	
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
lol_bzll_rVS = sgs.CreateViewAsSkill{
	name = "lol_bzll_r" ,
	n = 1,
	response_or_use = true,
	view_filter = function(self, cards, to_select)
		return to_select:getNumber() == sgs.Self:getMark("lol_bzll_q") and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark("lol_bzll_q") > 0 and player:getMark("@lol_bzll_r") >= 1
	end
}
lol_bzll_r = sgs.CreateTriggerSkill{
	name = "lol_bzll_r",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_bzll_r",
	events = {sgs.TargetConfirmed, sgs.ConfirmDamage},
	view_as_skill = lol_bzll_rVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
		    if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then 
                room:doLightbox("$lol_bzll_image", 1500)
		        room:removePlayerMark(player, "@lol_bzll_r")	
			end				
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() and damage.to:distanceTo(player) >= 2 then 
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end
}
lol_bzll_r_dis = sgs.CreateTargetModSkill{
	name = "#lol_bzll_r_dis",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("lol_bzll_r") and table.contains(card:getSkillNames(), "lol_bzll_r") then return 1000 end
	end
}
lol_bzll:addSkill(lol_bzll_q)
lol_bzll:addSkill(lol_bzll_w)
lol_bzll:addSkill(lol_bzll_e)
lol_bzll:addSkill(lol_bzll_r)
lol_bzll:addSkill(lol_bzll_r_dis)
lol_bzll:addSkill(lol_bzll_t)
extension:insertRelatedSkills("lol_bzll_r", "#lol_bzll_r_dis")
sgs.LoadTranslationTable{ 
["#lol_bzll"] = "暴走萝莉",
["lol_bzll"] = "金克斯",
["~lol_bzll"] = "我也试着去用心，但是……我做不到啊……",
["lol_bzll_t"] = "被动",
[":lol_bzll_t"] = "<font color=\"purple\"><b>【罪恶快感】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当其他角色死亡时，你获得加速（直到你的回合结束）。",
["$lol_bzll_t"] = "我意外地做到了。",
["lol_bzll_q"] = "Q",
[":lol_bzll_q"] = "<font color=\"purple\"><b>【枪炮交响曲】</b></font><font color=\"blue\"><b>锁定技，</b></font>你拥有一个额外区域，称为“备选武器区”。游戏开始时，你将两张随机武器牌中的一张置于“备选武器区”。出牌阶段，你可以交换装备区和“备选武器区”中的武器牌。",
["$lol_bzll_q"] = "我是个疯子，有医生开的证明。",
["lol_bzll_w"] = "W",
[":lol_bzll_w"] = "<font color=\"purple\"><b>【震荡电磁波】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张点数大于X的手牌当【杀】使用（X为你“备选武器区”中武器牌的点数），每当你使用此【杀】对目标角色造成伤害后，令其减速（直到其回合结束）。",
["$lol_bzll_w"] = "你是我最喜欢的靶子。",
["lol_bzll_e"] = "E",
[":lol_bzll_e"] = "<font color=\"purple\"><b>【嚼火者手雷】</b></font><font color=\"green\"><b>阶段技，</b></font>若没有“嚼火者手雷”，你可以弃置一张牌，获得3枚“嚼火者手雷”。每当你于其他角色回合内失去点数小于X的牌时，或其他角色于你的回合内失去点数小于X的牌时，你可以弃置1枚“嚼火者手雷”，束缚该角色（直到回合结束，X为你“备选武器区”中武器牌的点数）。",
["$lol_bzll_e"] = "我有最美好的初衷。",
["@lol_bzll_e"] = "嚼火者手雷",
["lol_bzll_r"] = "R",
[":lol_bzll_r"] = "<font color=\"purple\"><b>【超究极死神飞弹】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将一张点数为X的手牌当【杀】使用（无距离限制，X为你“备选武器区”中武器牌的点数），当你使用此【杀】对目标角色造成伤害时，若其与你的距离不小于2，你令此伤害+1。",
["$lol_bzll_image"] = "image=image/animate/lol_bzll_r.png",
["$lol_bzll_r"] = "打住，我想说一些非常酷的话。",
["designer:lol_bzll"] = "霓炎",
["cv:lol_bzll"] = " ",
["illustrator:lol_bzll"] = " ",
}



--lol_kpds = sgs.General(extension, "lol_kpds", "god", 3, true)
lol_kpds_t = sgs.CreateTriggerSkill{
	name = "lol_kpds_t",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()				
		if death.damage and death.damage.from:objectName() == player:objectName() then 
			room:broadcastSkillInvoke("lol_kpds_t")	
			room:notifySkillInvoked(player, self:objectName())	
            player:drawCards(math.random(3))
		end		
	end,
}
lol_kpds_qVS = sgs.CreateViewAsSkill{
	name = "lol_kpds_q",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected < 3 then return not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
		if #cards ~= 3 then return false end
		local card = sgs.Sanguosha:cloneCard("archery_attack", cards[1]:getSuit(), 0);
		for _, c in ipairs(cards) do card:addSubcard(c) end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
        return not player:hasFlag("lol_kpds_q")
	end
}
lol_kpds_q = sgs.CreateTriggerSkill{
	name = "lol_kpds_q",
	events = {sgs.TargetConfirmed},
	view_as_skill = lol_kpds_qVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() then room:setPlayerFlag(player, "lol_kpds_q") end
	end
}
lol_kpds_wCard = sgs.CreateSkillCard{
	name = "lol_kpds_wCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, player, targets)
	    local room = player:getRoom()
		if player:getPile("lol_kpds_w_blue"):length() == 1 then 
		    card = sgs.Sanguosha:getCard(player:getPile("lol_kpds_w_blue"):first())
            player:obtainCard(card)						
			player:addToPile("lol_kpds_w_red", card:getEffectiveId())
		elseif player:getPile("lol_kpds_w_red"):length() == 1 then
		    card = sgs.Sanguosha:getCard(player:getPile("lol_kpds_w_red"):first())
            player:obtainCard(card)						
			player:addToPile("lol_kpds_w_gold", card:getEffectiveId())		
		elseif player:getPile("lol_kpds_w_gold"):length() == 1 then
			card = sgs.Sanguosha:getCard(player:getPile("lol_kpds_w_gold"):first())
            player:obtainCard(card)						
			player:addToPile("lol_kpds_w_blue", card:getEffectiveId())
		elseif player:getPile("lol_kpds_w_blue"):length() + player:getPile("lol_kpds_w_red"):length() + player:getPile("lol_kpds_w_gold"):length() == 0 then
			local card = room:askForCard(player, ".", "@lol_kpds_w_ask", sgs.QVariant(), sgs.NonTrigger)
			if card then player:addToPile("lol_kpds_w_blue", card:getEffectiveId()) end
		end
	end
}
lol_kpds_wVS = sgs.CreateViewAsSkill{
	name = "lol_kpds_w",
	n = 0,
	view_as = function(self, cards)
		return lol_kpds_wCard:clone()
	end,
}
lol_kpds_w = sgs.CreateTriggerSkill{
	name = "lol_kpds_w" ,
	events = {sgs.EventPhaseStart},
	view_as_skill = lol_kpds_wVS ,
    on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		local me = room:findPlayerBySkillName(self:objectName())		
		if me and me:isAlive() and player:getMark("lol_kpds_r_dest") > 0 then
			room:doLightbox("$lol_kpds_image", 1500)		    
			room:setPlayerMark(player, "lol_kpds_r_dest", 0)
			while player:getNext():objectName() ~= me:objectName() do room:swapSeat(me, me:getNext()) end	 
		end
	end
}
lol_kpds_e = sgs.CreateTriggerSkill{
	name = "lol_kpds_e",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.TargetConfirmed, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()	
        if event == sgs.GameStart then
            room:setPlayerMark(player, "@lol_kpds_e", 4) 
		elseif event == sgs.TargetConfirmed then		
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				if player:getMark("lol_kpds_e_already") == 0 and math.random(player:getMark("@lol_kpds_e")) == 1 then
					room:setCardFlag(use.card, "lol_kpds_e")
					room:setPlayerMark(player, "lol_kpds_e_already", 1) 
				end
				room:setPlayerMark(player, "@lol_kpds_e", player:getMark("@lol_kpds_e") - 1) 
				if player:getMark("@lol_kpds_e") == 0 then 
				    room:setPlayerMark(player, "lol_kpds_e_already", 0) 
				    room:setPlayerMark(player, "@lol_kpds_e", 4) 
				end
			end
		elseif event == sgs.DamageCaused then	
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if damage.card and damage.card:hasFlag("lol_kpds_e")  then
				room:broadcastSkillInvoke("lol_kpds_e")
                room:notifySkillInvoked(player, self:objectName())					
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end		
		end
	end
}
lol_kpds_e_slash = sgs.CreateTargetModSkill{
	name = "#lol_kpds_e_slash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then return 1 end
	end,
}
lol_kpds_rCard = sgs.CreateSkillCard{
	name = "lol_kpds_rCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
        room:doLightbox("$lol_kpds_image", 1500)		
		room:removePlayerMark(effect.from, "@lol_kpds_r")
		room:setPlayerMark(effect.to, "lol_kpds_r_dest", 1) 
	end
}
lol_kpds_rVS = sgs.CreateViewAsSkill{
	name = "lol_kpds_r" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local card = lol_kpds_rCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_kpds_r") >= 1
	end
}
lol_kpds_r = sgs.CreateTriggerSkill{
	name = "lol_kpds_r" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_kpds_r",
	events = {sgs.EventPhaseStart},
	view_as_skill = lol_kpds_rVS ,
    on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		local me = room:findPlayerBySkillName(self:objectName())		
		if me and me:isAlive() and player:getMark("lol_kpds_r_dest") > 0 then
			room:doLightbox("$lol_kpds_image", 1500)		    
			room:setPlayerMark(player, "lol_kpds_r_dest", 0)
			while player:getNext():objectName() ~= me:objectName() do room:swapSeat(me, me:getNext()) end	 
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
-- lol_kpds:addSkill(lol_kpds_q)
-- lol_kpds:addSkill(lol_kpds_w)
-- lol_kpds:addSkill(lol_kpds_e)
-- lol_kpds:addSkill(lol_kpds_e_slash)
-- lol_kpds:addSkill(lol_kpds_r)
-- lol_kpds:addSkill(lol_kpds_t)
-- extension:insertRelatedSkills("lol_kpds_e", "#lol_kpds_e_slash")
sgs.LoadTranslationTable{ 
["#lol_kpds"] = "卡牌大师",
["lol_kpds"] = "崔斯特",
["~lol_kpds"] = "呃...",
["lol_kpds_t"] = "被动",
[":lol_kpds_t"] = "<font color=\"purple\"><b>【灌铅骰子】</b></font><font color=\"blue\"><b>锁定技，</b></font>每当你杀死一名角色后，你摸X张牌（X为1~3的随机数）。",
["$lol_kpds_t"] = "今天是我的幸运日。",
["lol_kpds_q"] = "Q",
[":lol_kpds_q"] = "<font color=\"purple\"><b>【万能牌】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将三张手牌当【万箭齐发】使用。",
["$lol_kpds_q"] = "出牌吧。",
["lol_kpds_w"] = "W",
[":lol_kpds_w"] = "<font color=\"purple\"><b>【选牌】</b></font><font color=\"green\"><b>阶段技，</b></font>你可以将一张手牌置于你的武将牌上，称为“蓝色牌”。然后你可以多次点击“选牌”，将“蓝色牌”改为“红色牌”、“红色牌”改为“金色牌”、“金色牌”改为“蓝色牌”。你使用【杀】对目标角色造成伤害后，。",
["$lol_kpds_w"] = "洗牌。",
["@lol_kpds_w_ask"] = "你可以将一张手牌置于武将牌上，称为“蓝色牌”",
["lol_kpds_w_blue"] = "蓝色牌",
["lol_kpds_w_red"] = "红色牌",
["lol_kpds_w_gold"] = "金色牌",
["lol_kpds_e"] = "E",
[":lol_kpds_e"] = "<font color=\"purple\"><b>【卡牌骗术】</b></font><font color=\"blue\"><b>锁定技，</b></font>你每使用四张【杀】，其中的随机一张【杀】造成的伤害+1。<font color=\"blue\"><b>锁定技，</b></font>出牌阶段，你能额外使用一张【杀】。",
["$lol_kpds_e"] = "哼哼哼哼哼哼...",
["lol_kpds_r"] = "R",
[":lol_kpds_r"] = "<font color=\"purple\"><b>【命运】</b></font><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置一张黑桃手牌并选择一名其他角色，其准备阶段开始时，你将你的位置移至其下家。",
["$lol_kpds_image"] = "image=image/animate/lol_kpds_r.png",
["$lol_kpds_r"] = "啊，让我算算。",
["designer:lol_kpds"] = "霓炎",
["cv:lol_kpds"] = " ",
["illustrator:lol_kpds"] = " ",
}

return { extension }



