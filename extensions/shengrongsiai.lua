module("extensions.shengrongsiai", package.seeall)
extension = sgs.Package("shengrongsiai")

sgs.LoadTranslationTable{
["shengrongsiai"] = "生荣死哀",

["Rlihui"] = "☆R李恢",
["&Rlihui"] = "李恢",
["#Rlihui"]  = "平乱建功",
["designer:Rlihui"] = "Gent",
["luarshiji"] = "施计",
["luaRshiji"] = "施计",
[":luaRshiji"] = "摸牌阶段，你可以放弃摸牌，视为对攻击范围内的角色使用一张【杀】，若该杀造成了伤害你可以摸3张牌。",
["@luaRshiji"] = "你可以发动“施计”",
["~luaRshiji"] = "选择【杀】的目标→点击确定",
["luaRquanxiang"] = "劝降",
[":luaRquanxiang"] = "限定技，当你杀死一名非主公角色时，在其翻开身份牌之前，你可以使该角色摸3张牌，恢复至1点体力，并将身份牌更换为与你相同的身份。",


["Rsunquan"] = "☆R孙权",
["&Rsunquan"] = "孙权",
["#Rsunquan"]  = "晚年的昏君",
["designer:Rsunquan"] = "文和,Gent",
["luaRduxian"] = "妒贤",
[":luaRduxian"] = "锁定技，若没有角色处于濒死状态，其他角色出牌阶段，每当其使用的牌的总数量大于你的当前体力值时，你须立即对其造成一点伤害。",
["luaRcaiyi"] = "猜疑",
[":luaRcaiyi"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，其须展示任意张手牌并令你选择一项：获得其展示的所有手牌，或获得其未展示的所有手牌。",
["luaRcaiyi-invoke"] = "你可以发动“猜疑”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
["@luaRcaiyi-invoke"] = "请展示若干张牌<br/> <b>操作提示</b>: 选择若干张牌→点击确定<br/>",
["luaRcaiyi1"] = "获得其展示的所有手牌",
["luaRcaiyi2"] = "获得其未展示的所有手牌",
["luaRhuogen"] = "祸根",
[":luaRhuogen"] = "主公技，其他吴势力角色对处于濒死状态的你可以失去1点体力然后使你恢复1点体力。",

["Rdingyuan"] = "☆R丁原",
["&Rdingyuan"] = "丁原",
["#Rdingyuan"]  = "养虎为患",
["designer:Rdingyuan"] = "Gent",
["luaRsihu"] = "饲虎",
["luarsihu"] = "饲虎",
[":luaRsihu"] = "出牌阶段限一次，你可以交给一名其他角色一张装备牌或杀，视为其对你指定的一名其他角色使用一张杀（该杀无视距离）若如此做，此杀的目标可以交给使用者一张装备牌或杀将目标转移给你，你亦可重复此流程，直到此杀确定目标为止。",

["Rcaocao"] = "☆R曹操",
["&Rcaocao"] = "曹操",
["#Rcaocao"]  = "挟天子令天下",
["designer:Rcaocao"] = "Gent",
["luaRjianxiong"] = "奸雄",
["@luaRjianxiong"] = "你可以对 %src 使用一张目标数为1的牌",
[":luaRjianxiong"] = "每当你成为牌的目标并结算完毕后，若该牌目标数为1，你可对牌的来源者使用一张目标数为1的牌，该牌无距离限制，然后摸一张牌。",
["luaRxinhen-slash"] = "你可以对 %src 使用一张【杀】",
["luaRxinhen"] = "心狠",
[":luaRxinhen"] = "一名其他角色濒死状态结算后，你可以对其使用一张【杀】。每回合限一次",
["luaRxietian"] = "挟天",
[":luaRxietian"] = "主公技，锁定技，场上每有一种势力，你的手牌上限便+1。",

["Rhuaxiong"] = "☆R华雄",
["&Rhuaxiong"] = "华雄",
["#Rhuaxiong"]  = "汜水关的死神",
["designer:Rhuaxiong"] = "Gent",
["luaRyaowu"] = "耀武",
[":luaRyaowu"] = "锁定技，每当你使用的杀被目标角色的闪抵消后，你视为对其使用一张决斗",

["Rxunyou"] = "☆R荀攸",
["&Rxunyou"] = "荀攸",
["#Rxunyou"]  = "经达权变",
["designer:Rxunyou"] = "Gent",
["luaRqice"] = "奇策",
[":luaRqice"] = "当场上有任何锦囊结算完毕后，你可以弃掉所有手牌（至少1张）或流失一点体力，使该锦囊再次被使用，每回合限一次。",
["luaRzhiyu"] = "智愚",
[":luaRzhiyu"] = "锁定技，在其他角色对你造成一次伤害后，你须摸至或弃至伤害来源的手牌数",

["Rxuyou"] = "☆R许攸",
["&Rxuyou"] = "许攸",
["#Rxuyou"]  = "贪而无厌",
["designer:Rxuyou"] = "Gent",
["luaRkuangyan"] = "狂言",
[":luaRkuangyan"] = "锁定技，你受到的1点无属性伤害无效。当你一次受到伤害不小于2时，该伤害+1。",
["luaRziao"] = "自傲",
["luarziao"] = "自傲",
[":luaRziao"] = "出牌阶段，你可以与其他角色拼点。",
["luaRshicai"] = "恃才",
[":luaRshicai"] = "锁定技，拼点结束时，与你拼点赢的角色须摸一张牌，与你拼点没赢的角色须弃一张牌。",

["Rdongzhuo"] = "☆R董卓",
["&Rdongzhuo"] = "董卓",
["#Rdongzhuo"]  = "空目一切",
["designer:Rdongzhuo"] = "Gent",
["luaRqiangquan"] = "强权",
[":luaRqiangquan"] = "你的【杀】造成伤害后，你可以选择一名非你和目标的其他角色，令其选择一项1，对被伤害的目标使用一张杀2，失去一点体力。",
["luaRqiangquan-slash"] = "强权：你可以对 %src 使用一张【杀】或失去一点体力",
["luaRqiangquan-invoke"] = "你可以发动“强权”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
["luaRyaoyan"] = "邀宴",
[":luaRyaoyan"] = "每当其他角色造成一次伤害后，其可以进行一次判定，若判定结果为黑桃，你回复1点体力。",
["luaRzhangshi-slash"] = "仗势：你可以对 %src 使用一张【杀】或失去一点体力",
["luarzhangshi"] = "仗势",
["luaRzhangshi"] = "仗势",
["luaRzhangshi:obtain"] = "获得你的一张牌",
["luaRzhangshi:slash"] = "其他所有群势力可以依次选择对你使用一张【杀】（无距离限制）",
[":luaRzhangshi"] = "主公技，出牌阶段限一次，你可以选择一名其他角色选择一项：1，你获得其的一张牌 2，其他所有群势力可以依次选择对其出一张【杀】（无距离限制）。",
}

--李恢↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
Rlihui = sgs.General(extension, "Rlihui", "shu", "3")

luaRshijiCard = sgs.CreateSkillCard{
	name = "luaRshiji" ,
	filter = function(self, targets, to_select, player)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			if player:inMyAttackRange(target) then
				targets_list:append(target)
			end
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luaRshiji")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self) and #targets == 0
	end ,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:inMyAttackRange(target) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
			slash:setSkillName("luaRshiji")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
luaRshijiVS = sgs.CreateViewAsSkill{
	name = "luaRshiji" ,
	n = 0 ,
	view_as = function(self, cards)
		return #cards == 0 and luaRshijiCard:clone() or nil
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@luaRshiji")
	end
}
luaRshiji = sgs.CreateTriggerSkill{
	name = "luaRshiji" ,
	events = {sgs.EventPhaseStart, sgs.Damage, sgs.CardFinished} ,
	view_as_skill = luaRshijiVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw  then
				if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@luaRshiji", "@luaRshiji", 1) then
                    return true
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() then 
				room:setPlayerFlag(player, "luaRshiji_damage")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
				if use.card:isKindOf("Slash") then
					
					if player:hasFlag("luaRshiji_damage") then 
                        player:drawCards(3)
                    end
                    room:setPlayerFlag(player, "-luaRshiji_damage")
                end
            end
		end
		return false
	end
}

luaRquanxiang = sgs.CreateTriggerSkill {
	name = "luaRquanxiang",
	events = { sgs.BeforeGameOverJudge},
    limit_mark = "@luaRquanxiang",
    frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data, room)
		local target = nil
		if event == sgs.BeforeGameOverJudge then
			local death = data:toDeath()
			if death.damage and death.damage.from then
				target = death.damage.from
			end
			if target and not death.who:isLord() and target:hasSkill(self:objectName()) and target:getMark("@luaRquanxiang") > 0 then
				if room:askForSkillInvoke(target, self:objectName(), data) then
                    target:loseMark("@luaRquanxiang")
					room:broadcastProperty(target, "role", target:getRole())
					room:broadcastProperty(death.who, "role", death.who:getRole())
                    death.who:setAlive(true)
                    room:broadcastProperty(death.who, "alive")
                    room:swapSeat(death.who, death.who)
					death.who:drawCards(3)
                    local recover = sgs.RecoverStruct()
                    recover.who = target
                    recover.recover = 1 - death.who:getHp()
                    room:recover(death.who, recover, true)
					if not player:isLord() then
						room:setPlayerProperty(death.who, "role", sgs.QVariant(target:getRole()))
					else
						room:setPlayerProperty(death.who, "role", sgs.QVariant("loyalist"))
					end
					room:broadcastProperty(death.who, "role", death.who:getRole())
                    room:updateStateItem()
                    local right = true
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getRole() == "rebel" or p:getRole() == "renegade" then
                            right = false
                        end
                    end
                    if right then
                        room:gameOver("lord+loyalist")
                    end
                    return true
					--checkgameover
				end
			end
		end
		return false
	end,
    can_trigger = function(self, player)
		return player
	end,
}

Rlihui:addSkill(luaRshiji)
Rlihui:addSkill(luaRquanxiang)





--孙权↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
Rsunquan = sgs.General(extension, "Rsunquan$", "wu", "3")
luaRduxian = sgs.CreateTriggerSkill {
	name = "luaRduxian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
                for _, p in sgs.qlist(player:getAliveSiblings()) do
                    if (p:hasFlag("Global_Dying") or player:hasFlag("Global_Dying")) then
                        return false
                    end
                end
                room:addPlayerMark(player, "luaRduxian-PlayClear")
                room:addPlayerMark(player, "&luaRduxian-PlayClear")
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("luaRduxian-PlayClear") > p:getHp() and player:objectName() ~= p:objectName() then
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                        local damage = sgs.DamageStruct()
                        damage.reason = self:objectName()
                        damage.from = p
                        damage.to = player
                        room:damage(damage)
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
luaRcaiyi = sgs.CreatePhaseChangeSkill{
	name = "luaRcaiyi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "luaRcaiyi-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
                room:obtainCard(target, player:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""), false)
                if not target:isNude() then
                    --local cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false, "@luaRcaiyi")
                    local cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false, "@luaRcaiyi-invoke")
                    local list = target:getCards("h")
                    for _,id in sgs.qlist(cards:getSubcards()) do
                        room:showCard(target, id)
                        list:removeOne(sgs.Sanguosha:getCard(id))
                    end
                    local choices = {"luaRcaiyi1"}
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    dummy:deleteLater()
                    if not list:isEmpty() then
                        table.insert(choices, "luaRcaiyi2")
                        dummy:addSubcards(list)
                    end
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                    ChoiceLog(player, choice)
                    if choice == "luaRcaiyi1" then
                        room:obtainCard(player, cards, true)
                    else
                        room:obtainCard(player, dummy, false)
                    end
                end
            end
        end
        return false
    end
}
luaRhuogen = sgs.CreateTriggerSkill {
	name = "luaRhuogen$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local target = dying.who
		if target:hasLordSkill(self:objectName()) and target:objectName() ~= player:objectName() then
			local dest = sgs.QVariant()
			dest:setValue(target)
			while target:getHp() <= 0 and player:getHp() > 1 do
				if room:askForSkillInvoke(player, self:objectName(), dest) then
					room:loseHp(player, 1, true, player, self:objectName())
					if player:isAlive() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(target, recover)
						if target:getHp() > 0 then
							return true
						end
					end
				else
					return false
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:getKingdom() == "wu"
		end
		return false
	end
}
Rsunquan:addSkill(luaRduxian)
Rsunquan:addSkill(luaRcaiyi)
Rsunquan:addSkill(luaRhuogen)






--丁原↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

Rdingyuan = sgs.General(extension, "Rdingyuan", "qun", "4")

luaRsihuCard = sgs.CreateSkillCard{
	name = "luaRsihuCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local targets = sgs.SPlayerList()
		if sgs.Slash_IsAvailable(effect.to) then
			for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
				if effect.to:canSlash(p, nil, false) then
					targets:append(p)
				end
			end
		end
		local target
		if (not targets:isEmpty()) and effect.from:isAlive() then
			target = room:askForPlayerChosen(effect.from, targets, "luaRsihu", "@dummy-slash2:" .. effect.to:objectName())
		end
		effect.to:obtainCard(self)
        local temp = target
        local dest = sgs.QVariant()
        dest:setValue(effect.to)
        while true do
            local card = room:askForCard(temp, "EquipCard,Slash|.|.|.|", "@luaRsihu", dest, sgs.Card_MethodNone)
            if card then
                effect.to:obtainCard(card)
                if temp:objectName() == target:objectName() then
                    temp = effect.from
                else
                    temp = target
                end
            else
                break
            end
        end
        if effect.to:canSlash(temp, nil, false) then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
            slash:setSkillName("_luaRsihu")
            room:useCard(sgs.CardUseStruct(slash, effect.to, temp), false)
        end
	end
}
luaRsihu = sgs.CreateViewAsSkill{
	name = "luaRsihu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard") or to_select:isKindOf("Slash")
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local mingcecard = luaRsihuCard:clone()
		mingcecard:addSubcard(cards[1])
		return mingcecard
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luaRsihuCard")
	end
}



Rdingyuan:addSkill(luaRsihu)

--曹操↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

Rcaocao = sgs.General(extension, "Rcaocao$", "qun", "3")
luaRjianxiong = sgs.CreateTriggerSkill {
	name = "luaRjianxiong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		if player:isAlive() then
			if event == sgs.CardFinished then
                local use = data:toCardUse()
                local card = use.card
                if not use.from or not use.from:isAlive() then return false end
                if not card:isKindOf("SkillCard") and use.to:length() == 1 then
                    local use_cards = {}
                    local room = player:getRoom()
                    for _, caocao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if use.to:contains(caocao) and caocao:hasSkill(self:objectName()) then
                            for _, c in sgs.qlist(caocao:getHandcards()) do
                                
                                if not c:isAvailable(caocao) then continue end
                                local trannum = room:getCardTargets(caocao,c,sgs.SPlayerList()):length()
                                if c:isKindOf("AOE") or c:isKindOf("GlobalEffect") then 
                                elseif c:targetFixed() then trannum = 1 end
                                if trannum==1 or c:isSingleTargetCard() or c:isKindOf("SingleTargetTrick") then
                                    room:setCardFlag(c, "luaRjianxiong")
                                    if table.contains(use_cards, c:getClassName()) then continue end
                                    table.insert(use_cards,c:getClassName()) 
                                end
                            end
                            if #use_cards > 0 then
                                room:setPlayerFlag(use.from, "luaRjianxiong")
                                room:notifySkillInvoked(caocao, self:objectName())
                                local prompt = string.format("@luaRjianxiong:%s", use.from:objectName())
                                --local card = room:askForUseCard(caocao, table.concat(use_cards, ",").."|.|.|hand", prompt)
                                local dest = sgs.QVariant()
                                dest:setValue(use.from)
                                local card = room:askForCard(caocao, table.concat(use_cards, ",").."|.|.|hand", prompt, dest, sgs.Card_MethodUse)
                                if card then
                                    room:useCard(sgs.CardUseStruct(card, caocao, use.from))
                                    caocao:drawCards(1)
                                end
                                room:setPlayerFlag(use.from, "-luaRjianxiong")
                            end
                            for _, c in sgs.qlist(caocao:getHandcards()) do
                                room:setCardFlag(c, "-luaRjianxiong")
                            end
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
luaRjianxiongTargetMod = sgs.CreateTargetModSkill {
	name = "#luaRjianxiongTargetMod",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("luaRjianxiong") and card and (card:hasFlag("luaRjianxiong")) then
			return 1000
		else
			return 0
		end
	end
}
luaRjianxiongProhibit = sgs.CreateProhibitSkill {
	name = "#luaRjianxiongProhibit",
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("luaRjianxiong") and card and (card:hasFlag("luaRjianxiong")) and not to:hasFlag("luaRjianxiong")
	end
}
luaRxinhen = sgs.CreateTriggerSkill {
	name = "luaRxinhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.QuitDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		for _, mygod in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if mygod:isAlive() and source:isAlive() and mygod:getMark("luaRxinhen-Clear") == 0 and not mygod:hasFlag("luaRxinhen_using") then
                room:setPlayerFlag(mygod, "luaRxinhen_using")
                local prompt = string.format("luaRxinhen-slash:%s", source:objectName())
			    if room:askForUseSlashTo(mygod, source, prompt) then
                    room:addPlayerMark(mygod, "luaRxinhen-Clear")
                    room:addPlayerMark(mygod, "&luaRxinhen-Clear")
                end
                room:setPlayerFlag(mygod, "-luaRxinhen_using")
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
luaRxietian = sgs.CreateMaxCardsSkill{
    name = "luaRxietian$" ,
    extra_func = function(self, target)
        local extra = 0
        local kingdom_set = {}
        table.insert(kingdom_set, target:getKingdom())
        for _, p in sgs.qlist(target:getSiblings()) do
            local flag = true
            for _, k in ipairs(kingdom_set) do
                if p:getKingdom() == k then
                    flag = false
                    break
                end
            end
            if flag then table.insert(kingdom_set, p:getKingdom()) end
        end
        extra = #kingdom_set
        if target:hasLordSkill(self:objectName()) then
            return extra
        else
            return 0
        end
    end
}

Rcaocao:addSkill(luaRjianxiong)
Rcaocao:addSkill(luaRjianxiongTargetMod)
Rcaocao:addSkill(luaRjianxiongProhibit)
extension:insertRelatedSkills("luaRjianxiong", "#luaRjianxiongTargetMod")
extension:insertRelatedSkills("luaRjianxiong", "#luaRjianxiongProhibit")
Rcaocao:addSkill(luaRxinhen)
Rcaocao:addSkill(luaRxietian)



--华雄↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
Rhuaxiong = sgs.General(extension, "Rhuaxiong", "qun", "5")

luaRyaowu = sgs.CreateTriggerSkill{
    name = "luaRyaowu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardOffset},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local effect = data:toCardEffect()
        if not effect.card:isKindOf("Slash") then return end
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:setSkillName(self:objectName())
        duel:deleteLater()
        if effect.to:isAlive() and player:canUse(duel,effect.to)  then
            local use = sgs.CardUseStruct()
            use.card = duel
            use.from = player
            local dest = effect.to
            use.to:append(dest)
            room:useCard(use)
        end
    end
}



Rhuaxiong:addSkill("mashu")
Rhuaxiong:addSkill(luaRyaowu)

--荀攸↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
Rxunyou = sgs.General(extension, "Rxunyou", "wei", "3")

luaRqice = sgs.CreateTriggerSkill {
	name = "luaRqice",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		if player:isAlive() then
			if event == sgs.CardFinished then
                local use = data:toCardUse()
                local card = use.card
                if not use.from or not use.from:isAlive() then return false end
                if card:isKindOf("TrickCard") and use.to:length() > 0 then
                    local room = player:getRoom()
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if p:getMark("luaRqice-Clear") == 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                            room:addPlayerMark(p, "luaRqice-Clear")
                            room:addPlayerMark(p, "&luaRqice-Clear")
                            if p:isKongcheng() then
                                room:loseHp(p, 1, true, p, self:objectName())
                            else
                                p:throwAllHandCards()
                            end
                            use.card:use(room, use.from, use.to)
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
luaRzhiyu = sgs.CreateTriggerSkill {
	name = "luaRzhiyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
            if player:getHandcardNum() ~= damage.from:getHandcardNum() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if player:getHandcardNum() > damage.from:getHandcardNum() then
                    room:askForDiscard(player, self:objectName(), player:getHandcardNum() - damage.from:getHandcardNum(), player:getHandcardNum() - damage.from:getHandcardNum(), false, false)
                else
                    player:drawCards(damage.from:getHandcardNum() - player:getHandcardNum())
                end
            end
		end
	end
}
Rxunyou:addSkill(luaRqice)
Rxunyou:addSkill(luaRzhiyu)

--许攸↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

Rxuyou = sgs.General(extension, "Rxuyou", "wei", "3")

luaRkuangyan = sgs.CreateTriggerSkill{
	name = "luaRkuangyan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		room:notifySkillInvoked(player, "luaRkuangyan")
		if damage.damage == 1 then
			if damage.nature == sgs.DamageStruct_Normal then
				room:broadcastSkillInvoke("luaRkuangyan", 1)
				return true
			end
		elseif damage.damage >= 2 then
			room:broadcastSkillInvoke("luaRkuangyan", 2)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end
}
luaRziaoCard = sgs.CreateSkillCard {
	name = "luaRziao",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and player:canPindian(to_select)
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local success = source:pindian(target, self:objectName(), nil)
	end,
}


luaRziao = sgs.CreateViewAsSkill {
	name = "luaRziao",
	n = 0,
	view_as = function(self, cards)
		return luaRziaoCard:clone()
	end,
}

luaRshicai = sgs.CreateTriggerSkill{
	name = "luaRshicai" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
			if pindian.from_number > pindian.to_number then
				pindian.from:drawCards(1)
                if pindian.to and pindian.to:isAlive() then
                    room:askForDiscard(pindian.to, self:objectName(), 1, 1, false, false)
                end
			elseif pindian.from_number < pindian.to_number then
                if pindian.to and pindian.to:isAlive() then
				    pindian.to:drawCards(1)
                end
                room:askForDiscard(pindian.from, self:objectName(), 1, 1, false, false)
            else
                room:askForDiscard(pindian.from, self:objectName(), 1, 1, false, false)
                if pindian.to and pindian.to:isAlive() then
                    room:askForDiscard(pindian.to, self:objectName(), 1, 1, false, false)
                end
			end
		elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
			if pindian.from_number < pindian.to_number then
				pindian.to:drawCards(1)
                if pindian.from and pindian.from:isAlive() then
                    room:askForDiscard(pindian.from, self:objectName(), 1, 1, false, false)
                end
			elseif pindian.from_number > pindian.to_number then
                if pindian.from and pindian.from:isAlive() then
				    pindian.from:drawCards(1)
                end
                room:askForDiscard(pindian.to, self:objectName(), 1, 1, false, false)
            else
                room:askForDiscard(pindian.to, self:objectName(), 1, 1, false, false)
                if pindian.from and pindian.from:isAlive() then
                    room:askForDiscard(pindian.from, self:objectName(), 1, 1, false, false)
                end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
	
Rxuyou:addSkill(luaRkuangyan)
Rxuyou:addSkill(luaRziao)
Rxuyou:addSkill(luaRshicai)

--董卓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
Rdongzhuo = sgs.General(extension, "Rdongzhuo$", "qun", "4")

luaRqiangquan = sgs.CreateTriggerSkill{
	name = "luaRqiangquan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:objectName() ~= player:objectName() and p:objectName() ~= damage.to:objectName() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local dest = room:askForPlayerChosen(player, targets, "luaRqiangquan", "luaRqiangquan-invoke", true, true)
			    if dest then
                    local prompt = string.format("luaRqiangquan-slash:%s", damage.to:objectName())
                    if not room:askForUseSlashTo(dest, damage.to, prompt) then
                        room:loseHp(dest, 1, true, player, self:objectName())
                    end
                end
            end
		end
		return false
	end
}
luaRyaoyan = sgs.CreateTriggerSkill{
    name = "luaRyaoyan",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.Damage, sgs.DamageDone},
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if event == sgs.DamageDone and damage.from then
            elseif event == sgs.Damage and player:isAlive() then
            local dongzhuos = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self:objectName()) then
                    dongzhuos:append(p)
                end
            end
            while (not dongzhuos:isEmpty()) do
                local dongzhuo = room:askForPlayerChosen(player, dongzhuos, self:objectName(), "@baonue-to", true)
                if dongzhuo then
                    dongzhuos:removeOne(dongzhuo)
                    local log = sgs.LogMessage()
                    log.type = "#InvokeOthersSkill"
                    log.from = player
                    log.to:append(dongzhuo)
                    log.arg = self:objectName()
                    room:sendLog(log)
                    room:notifySkillInvoked(dongzhuo, self:objectName())
                    local judge = sgs.JudgeStruct()
                    judge.pattern = ".|spade"
                    judge.good = true
                    judge.reason = self:objectName()
                    judge.who = player
                    room:judge(judge)
                    if judge:isGood() then
                        room:recover(dongzhuo, sgs.RecoverStruct(player))
                    end
                else
                    break
                end
            end
        end
        return false
    end
}
luaRzhangshicard = sgs.CreateSkillCard {
	name = "luaRzhangshicard",
	target_fixed = false,
	will_throw = true,
    filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return to_select:objectName() ~= player:objectName()
		end
	end,
	on_use = function(self, room, source, targets)
        local target = targets[1]
        local choicelist = "slash"
        if not target:isNude() then
            choicelist = string.format("%s+%s", choicelist, "obtain")
        end
        local choice = room:askForChoice(target, "luaRzhangshi", choicelist)
        if choice == "slash" then
            for _, p in sgs.qlist(room:getLieges("qun", source)) do
                local prompt = string.format("luaRzhangshi-slash:%s", target:objectName())
                room:askForUseSlashTo(p, target, prompt, false) 
            end
        else
            if not target:isNude() then
                local card_id = room:askForCardChosen(source, target, "he", "luaRzhangshi")
                room:obtainCard(source, card_id, true)
            end
        end
	end
}
luaRzhangshi = sgs.CreateViewAsSkill {
	name = "luaRzhangshi$",
	n = 0,
	view_as = function(self, cards)
		local card = luaRzhangshicard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luaRzhangshicard")
	end
}
Rdongzhuo:addSkill(luaRqiangquan)
Rdongzhuo:addSkill(luaRyaoyan)
Rdongzhuo:addSkill(luaRzhangshi)
