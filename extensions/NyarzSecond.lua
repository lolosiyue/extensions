extension = sgs.Package("NyarzSecond", sgs.Package_GeneralPack)

local packages = {}
table.insert(packages, extension)

local function getTypeString(card)
    local cardtype = nil
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,p in ipairs(types) do
        if card:isKindOf(p) then
            cardtype = p
            break
        end
    end
    return cardtype
end

local function CreateDamageLog(damage, changenum, reason, up)
    if up == nil then up = true end
    local log = sgs.LogMessage()
    if damage.from then
        log.type = "$nyarzdamagechange"
        log.from = damage.from
        log.arg5 = damage.to:getGeneralName()
    else
        log.type = "$nyarzdamagechangenofrom"
        log.from = damage.to
    end
    log.arg = reason
    log.arg2 = damage.damage
    if up then
        log.arg3 = "nyarzdamageup"
        log.arg4 = damage.damage + changenum
    else
        log.arg3 = "nyarzdamagedown"
        log.arg4 = damage.damage - changenum
    end
    return log
end

sgs.LoadTranslationTable 
{
    ["$nyarzdamagechange"] = "%from 对 %arg5 造成的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["$nyarzdamagechangenofrom"] = "%from 受到的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["nyarzdamageup"] = "增加",
    ["nyarzdamagedown"] = "减少",
}

local function cardsChosen(room, player, target, reason, flag, num)
    local maxhand = target:getHandcardNum()
    local hand = 0
    local chosen = sgs.IntList()
    local cards = sgs.QList2Table(target:getCards(flag))
    local max = math.min(#cards, num)
    for i = 1, max, 1 do
        if hand >= maxhand then
            local newflag
            if string.find(flag, "e") then
                if string.find(flag, "j") then
                    newflag = "ej"
                else
                    newflag = "e"
                end
            else
                newflag = "j"
            end

            local id = room:askForCardChosen(player, target, newflag, reason, false, sgs.Card_MethodNone, chosen)
            chosen:append(id)
        else
            local id = room:askForCardChosen(player, target, flag, reason, false, sgs.Card_MethodNone, chosen)
            if room:getCardPlace(id) == sgs.Player_PlaceHand then
                hand = hand + 1
            else
                if not chosen:contains(id) then
                    chosen:append(id)
                else
                    if hand < maxhand then
                        hand = hand + 1
                    else
                        local newflag
                        if string.find(flag, "e") then
                            if string.find(flag, "j") then
                                newflag = "ej"
                            else
                                newflag = "e"
                            end
                        else
                            newflag = "j"
                        end
                        for _,card in sgs.qlist(target:getCards(newflag)) do
                            if not chosen:contains(card:getId()) then
                                chosen:append(card:getId())
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if hand > 0 then
        cards = sgs.QList2Table(target:getHandcards())
        for i = 1, hand, 1 do
            chosen:append(cards[i]:getId())
        end
    end
    return chosen
end

jxzhujun = sgs.General(extension, "jxzhujun", "qun", 4, true, false, false)

jxyangjieVS = sgs.CreateZeroCardViewAsSkill
{
    name = "jxyangjie",
    response_pattern = "@@jxyangjie",
    view_as = function(self)
        return jxyangjieCard:clone()
    end,
    enabled_at_play = function()
        return false 
    end
}

jxyangjieCard = sgs.CreateSkillCard
{
    name = "jxyangjie",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        slash:deleteLater()
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return slash and slash:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("_jxyangjie")
        room:setCardFlag(slash, "RemoveFromHistory")
        local tag = {}
        for _,p in sgs.qlist(cardUse.to) do
            table.insert(tag, p:objectName())
        end
        slash:setTag("jxyangjietargets", sgs.QVariant(table.concat(tag, "+")))
        
        return slash
    end,
}

jxyangjie = sgs.CreateTriggerSkill{
    name = "jxyangjie",
    events = {sgs.DamageCaused, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = jxyangjieVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            room:askForUseCard(player, "@@jxyangjie", "@jxyangjie")
        end

        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then return false end
            if not damage.card then return false end
            local tag = damage.card:getTag("jxyangjietargets"):toString():split("+")
            if not tag then return false end
            if table.contains(tag, damage.to:objectName()) then
                local tt = sgs.QVariant()
                tt:setValue(damage.to)
                player:setTag("jxyangjieto", tt)

                local choices = {"damage="..damage.to:getGeneralName()}
                if damage.to:isWounded() then
                    table.insert(choices, "recover="..damage.to:getGeneralName())
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))

                if string.find(choice, "damage") then
                    local log = sgs.LogMessage()
                    log.type = "$jxyangjiedamage"
                    log.from = player
                    log.arg = damage.to:getGeneralName()
                    room:sendLog(log)

                    local log2 = CreateDamageLog(damage, 1, self:objectName(), true)
                    room:sendLog(log2)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                else
                    local log = sgs.LogMessage()
                    log.type = "$jxyangjierecover"
                    log.from = player
                    log.arg = damage.to:getGeneralName()
                    room:sendLog(log)

                    room:recover(damage.to, sgs.RecoverStruct(player, nil, 1))
                    return true
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jxyangjiebuff = sgs.CreateTargetModSkill{
    name = "#jxyangjiebuff",
    residue_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "jxyangjie") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "jxyangjie") then return 1000 end
        return 0
    end,
}

jxjuxiang = sgs.CreateTriggerSkill{
    name = "jxjuxiang",
    events = {sgs.QuitDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not player:isAlive() then return false end
        local targets = room:findPlayersBySkillName(self:objectName())
        for _,p in sgs.qlist(targets) do
            if p:getMark("jxjuxiang_lun") == 0 and p:objectName() ~= player:objectName() then
                room:setPlayerFlag(player, "jxjuxiangtarget")
                local prompt = string.format("dying:%s::%s:", player:getGeneralName(), player:getMaxHp())
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerFlag(player, "-jxjuxiangtarget")
                    room:addPlayerMark(p, "jxjuxiang_lun")
                    room:addPlayerMark(p, "&jxjuxiang+_lun")
                    p:drawCards(player:getMaxHp())
                    room:damage(sgs.DamageStruct(nil, p, player, 1, sgs.DamageStruct_Normal))
                end
                room:setPlayerFlag(player, "-jxjuxiangtarget")
            end
            if not player:isAlive() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

jxhoulu = sgs.CreateTriggerSkill{
    name = "jxhoulu",
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.CardUsed, sgs.CardResponded, sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local _data = sgs.QVariant()
            _data:setValue(player)
            local targets = room:findPlayersBySkillName(self:objectName())
            for _,p in sgs.qlist(targets) do
                if p:getMark("jxhouluused_lun") == 0 and p:isAlive() then
                    if room:askForSkillInvoke(p, self:objectName(), _data) then
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        room:addPlayerMark(p, "jxhouluused_lun")
                        room:addPlayerMark(player, "&jxhoulu-Clear")
                        room:addPlayerMark(player, "jxhoulufrom"..p:objectName().."-Clear")
                        player:drawCards(3)
                    end
                end
                if player:isDead() then return false end
            end
        end

        if event == sgs.Damage then
            if player:getMark("&jxhoulu-Clear") > 0 then
                room:setPlayerMark(player, "jxhouludamage-Clear", 1)
            end
        end

        if event == sgs.Death then
            local target = data:toDeath().who
            if target:objectName() ~= player:objectName() then return false end
            if not player:hasSkill(self:objectName()) then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("&jxhoulu-Clear") > 0 then
                    if p:getMark("jxhoulufrom"..player:objectName().."-Clear") > 0 then
                        room:removePlayerMark(p, "jxhoulufrom"..player:objectName().."-Clear")
                        room:removePlayerMark(p, "&jxhoulu-Clear")
                    end
                end
            end
        end

        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getMark("&jxhoulu-Clear") == 0 then return false end
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                local response = data:toCardResponse()
                card = response.m_card
            end
            if card:isKindOf("SkillCard") then return false end
            if not card then return false end
            room:addPlayerMark(player, "jxhoulunum-Clear")
            if player:getMark("jxhoulunum-Clear") >= 2 then
                room:setPlayerMark(player, "jxhoulunum-Clear", 0)
                local cant = true
                local targets = room:findPlayersBySkillName(self:objectName())
                for _,p in sgs.qlist(targets) do
                    if player:getMark("jxhoulufrom"..p:objectName().."-Clear") > 0 then
                        room:sendCompulsoryTriggerLog(p, self:objectName(), true)
                        if player:getMark("jxhouludamage-Clear") == 0 then
                            room:broadcastSkillInvoke(self:objectName(), 3)
                            room:damage(sgs.DamageStruct(nil, p, player, 1, sgs.DamageStruct_Normal))
                            if p:objectName() == player:objectName() then cant = false end
                        else
                            room:broadcastSkillInvoke(self:objectName(), 2)
                        end
                        if player:isAlive() then
                            player:drawCards(2)
                        end
                    end
                    if player:isDead() then return false end
                end
                if cant and player:isAlive() then
                    room:setPlayerMark(player, "jxhouludamage-Clear", 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

jxzhujun:addSkill(jxyangjie)
jxzhujun:addSkill(jxyangjieVS)
jxzhujun:addSkill(jxyangjiebuff)
jxzhujun:addSkill(jxjuxiang)
jxzhujun:addSkill(jxhoulu)
extension:insertRelatedSkills("jxyangjie", "#jxyangjiebuff")

jjxiahouyuan = sgs.General(extension, "jjxiahouyuan", "wei", 4, true, false, false)

local function jjjjijincanplay(player)
    local patterns = {"nullification", "snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
    for _,p in ipairs(patterns) do
        if player:getMark("jjjijin_juguan_remove_"..p) == 0 then
            local card = sgs.Sanguosha:cloneCard(p, sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("jjjijin")
            if card:isAvailable(player) then
                card:deleteLater()
                return true
            end
            card:deleteLater()
        end
    end
    return false
end

jjjijin = sgs.CreateZeroCardViewAsSkill
{
    name = "jjjijin",
    juguan_type = "nullification,snatch,dismantlement,collateral,ex_nihilo,duel,fire_attack,amazing_grace,savage_assault,archery_attack,god_salvation,iron_chain",
    view_as = function(self, card)
        local card = sgs.Self:getTag("jjjijin"):toCard()
        local pattern = card:objectName()

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern ~= "nullification" then
                return nil
            end
        end

        if pattern then
            local cc = jjjijinCard:clone()
            cc:setUserString(pattern)
            return cc
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        if player:getMark("jjjijinused-Clear") > 0 then return false end
        return jjjjijincanplay(player)
    end,
    --[[enabled_at_nullification = function(self, player)
        if player:getMark("jjjijinused-Clear") > 0 then return false end
        return player:getMark("jjjijin_juguan_remove_nullification") == 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        if player:getMark("jjjijinused-Clear") > 0 then return false end
        return player:getMark("jjjijin_juguan_remove_nullification") == 0 and pattern == "nullification"
    end
}

jjjijinCard = sgs.CreateSkillCard {
	name = "jjjijin",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)		
		local pattern = self:getUserString()	
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("jjjijin")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
        card:deleteLater()
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)		
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)		
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("jjjijin")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local source = card_use.from
		local room = source:getRoom()	
        local pattern = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
		room:addPlayerMark(source, "jjjijin_juguan_remove_"..pattern)
        room:addPlayerMark(source, "jjjijinused-Clear")
        room:addPlayerMark(source, "&jjjijin+used+-Clear")
        room:addPlayerMark(source, "jjjijinusedtimes")
        local names = source:property("SkillDescriptionRecord_jjjijin"):toString():split("+")
        if not table.contains(names, use_card:objectName()) then 
            table.insert(names, use_card:objectName())
            local result = ""
            for i, v in ipairs(names) do
                if i > 1 then
                    result = result .. "+|+"
                end
                result = result .. v
            end
            room:setPlayerProperty(source, "SkillDescriptionRecord_jjjijin", sgs.QVariant(table.concat(names, "+")))
            source:setSkillDescriptionSwap("jjjijin", "%arg1", result)
            room:changeTranslation(source, "jjjijin", 2)
        end

        room:setPlayerCardLimitation(source, "use", use_card:getClassName().."|.|.|hand", false)
        
        use_card:setSkillName("jjjijin")
		return use_card	
	end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local pattern = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
		room:addPlayerMark(source, "jjjijin_juguan_remove_"..pattern)
        room:addPlayerMark(source, "jjjijinused-Clear")
        room:addPlayerMark(source, "&jjjijin+used+-Clear")
        room:addPlayerMark(source, "jjjijinusedtimes")
        local names = source:property("SkillDescriptionRecord_jjjijin"):toString():split("+")

        if not table.contains(names, use_card:objectName()) then 
            table.insert(names, use_card:objectName())
            local result = ""
            for i, v in ipairs(names) do
                if i > 1 then
                    result = result .. "+|+"
                end
                result = result .. v
            end
            room:setPlayerProperty(source, "SkillDescriptionRecord_jjjijin", sgs.QVariant(table.concat(names, "+")))
            source:setSkillDescriptionSwap("jjjijin", "%arg1", result)
            room:changeTranslation(source, "jjjijin", 2)
        end

        room:setPlayerCardLimitation(source, "use", use_card:getClassName().."|.|.|hand", false)

        use_card:setSkillName("jjjijin")
		return use_card	
    end,
}

jjjijindraw = sgs.CreateTriggerSkill{
    name = "#jjjijindraw",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if not use.card:isKindOf("TrickCard") then return false end
        local targets = room:findPlayersBySkillName("jjjijin")
        for _,p in sgs.qlist(targets) do
            if p:getMark("jjjijin_juguan_remove_"..use.card:objectName()) > 0 and p:isAlive() then
                room:sendCompulsoryTriggerLog(p, "jjjijin", true, true)
                room:getThread():delay(300)

                p:drawCards(1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

jjjijinbuff = sgs.CreateTriggerSkill{
    name = "#jjjijinbuff",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not use.card:isKindOf("TrickCard") then return false end
        if use.from:objectName() == player:objectName() then return false end
        if not use.to:contains(player) then return false end
        if player:getMark("jjjijin_juguan_remove_"..use.card:objectName()) == 0 then return false end

        local log = sgs.LogMessage()
		log.type = "#WuyanGooD"
		log.from = player
		log.to:append(use.from)
		log.arg = use.card:objectName()
		log.arg2 = "jjjijin"
		room:sendLog(log)
        --room:broadcastSkillInvoke("jjjijin")
		
		local nullified_list = use.nullified_list
		table.insert(nullified_list, player:objectName())
		use.nullified_list = nullified_list
		data:setValue(use)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("jjjijin")
    end,
}

jjjijingive = sgs.CreateTriggerSkill{
    name = "#jjjijingive",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getHandcardNum() == 0 then return false end
        local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
        local can = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if player:getMark("jjjijin_juguan_remove_"..card:objectName()) > 0 then
                give:addSubcard(card)
                can = true
            end
        end
        if not can then give:deleteLater() return false end
        n = give:subcardsLength()
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "jjjijin", "@jjjijin:"..n, true, true)
        if not target then give:deleteLater() return false end
        room:broadcastSkillInvoke("jjjijin")
        room:obtainCard(target, give, true)
        give:deleteLater()
        player:drawCards(n)
        player:addMark("&jjjijin-Clear", n)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("jjjijin") and target:getPhase() == sgs.Player_Play
    end,
}

jjjijinmax = sgs.CreateMaxCardsSkill{
    name = "#jjjijinmax",
    extra_func = function(self, target)
         return target:getMark("&jjjijin-Clear")
    end,
}

jjxiahouyuan:addSkill(jjjijin)
jjxiahouyuan:addSkill(jjjijindraw)
jjxiahouyuan:addSkill(jjjijinbuff)
jjxiahouyuan:addSkill(jjjijingive)
jjxiahouyuan:addSkill(jjjijinmax)
extension:insertRelatedSkills("jjjijin", "#jjjijindraw")
extension:insertRelatedSkills("jjjijin", "#jjjijinbuff")
extension:insertRelatedSkills("jjjijin", "#jjjijingive")
extension:insertRelatedSkills("jjjijin", "#jjjijinmax")

basimafang = sgs.General(extension, "basimafang", "wei", 4, true, false, false)

basuran = sgs.CreateTriggerSkill{
    name = "basuran",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 6, "@basuran", true, true)
        if targets and targets:length() > 0 then 
            room:broadcastSkillInvoke(self:objectName())
            local lastphases = {"start", "judge", "draw", "play", "discard", "finish"}

            for _,p in sgs.qlist(targets) do
                room:setPlayerFlag(p, "basuran")
                local choices = {}
                for _,phase in ipairs(lastphases) do
                    table.insert(choices, phase.."="..p:getGeneralName())
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                for _,phase in ipairs(lastphases) do
                    if string.find(choice, phase.."="..p:getGeneralName()) then
                        local log = sgs.LogMessage()
                        log.type = "$basuranskip"
                        log.from = p
                        log.arg = self:objectName()
                        log.arg2 = phase
                        room:sendLog(log)

                        room:setPlayerMark(p, "&basuran+:+"..phase.."_lun", 1)
                        table.removeOne(lastphases, phase)
                    end
                end
                room:setPlayerFlag(p, "-basuran")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

basuranskip = sgs.CreateTriggerSkill{
    name = "#basuranskip",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        local phase 
        if change.to == sgs.Player_Start and player:getMark("&basuran+:+start_lun") > 0 then
            phase = "start"
        elseif change.to == sgs.Player_Judge and player:getMark("&basuran+:+judge_lun") > 0 then
            phase = "judge"
        elseif change.to == sgs.Player_Draw and player:getMark("&basuran+:+draw_lun") > 0 then
            phase = "draw"
        elseif change.to == sgs.Player_Play and player:getMark("&basuran+:+play_lun") > 0 then
            phase = "play"
        elseif change.to == sgs.Player_Discard and player:getMark("&basuran+:+discard_lun") > 0 then
            phase = "discard"
        elseif change.to == sgs.Player_Finish and player:getMark("&basuran+:+finish_lun") > 0 then
            phase = "finish"
        else
            return false 
        end
        local log = sgs.LogMessage()
        log.type = "$basuranskip"
        log.from = player
        log.arg = "basuran"
        log.arg2 = phase
        room:sendLog(log)
        room:broadcastSkillInvoke("basuran")
        player:skip(change.to)
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

bajuwei = sgs.CreateTriggerSkill{
    name = "bajuwei",
    events = {sgs.EventPhaseStart, sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("bajuweifrom"..player:objectName()) == 0 then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@bajuwei", true, true)
            if not target then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(target, "&baxiaowei", target:getMark("&baxiaowei")+1)
            room:setPlayerMark(target, "bajuweifrom"..player:objectName(), 1)
            local log = sgs.LogMessage()
            log.type = "$bajuweibegin"
            log.from = target
            room:sendLog(log)
        end
        if event == sgs.Death then
            if data:toDeath().who:objectName() ~= player:objectName() then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("bajuweifrom"..player:objectName()) > 0 then
                    room:setPlayerMark(p, "bajuweifrom"..player:objectName(), 0)
                    room:setPlayerMark(p, "&baxiaowei", p:getMark("&baxiaowei")-1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

bajuweibuff = sgs.CreateTriggerSkill{
    name = "#bajuweibuff",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = data:toDamage().damage
        local targets = room:findPlayersBySkillName("bajuwei")
        for i = 1, n, 1 do
            for _,p in sgs.qlist(targets) do
                if player:getMark("bajuweifrom"..p:objectName()) > 0 and p:isAlive() then
                    room:sendCompulsoryTriggerLog(p, "bajuwei", true, true)
                    room:getThread():delay(300)
                    p:drawCards(1)
                    player:drawCards(1)
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:getMark("&baxiaowei") > 0
    end,
}

bajuweilimit = sgs.CreateProhibitSkill{
    name = "#bajuweilimit",
    is_prohibited = function(self, from, to, card)
        if from:getMark("bajuweifrom"..to:objectName()) > 0 and to:hasSkill("bajuwei") then
            return card:isKindOf("Slash") or card:isKindOf("TrickCard")
        end
        return false
    end,
}

basimafang:addSkill(basuran)
basimafang:addSkill(basuranskip)
basimafang:addSkill(bajuwei)
basimafang:addSkill(bajuweibuff)
basimafang:addSkill(bajuweilimit)
extension:insertRelatedSkills("basuran", "#basuranskip")
extension:insertRelatedSkills("bajuwei", "#bajuweibuff")
extension:insertRelatedSkills("bajuwei", "#bajuweilimit")

diansunquan = sgs.General(extension, "diansunquan", "wei", 4, true, false, false)

dianyingfu = sgs.CreateTriggerSkill{
    name = "dianyingfu",
    events = {sgs.EventPhaseStart, sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_RoundStart then
                room:setPlayerMark(player, "&dianyingfu", 0)
            end

            if player:getPhase() == sgs.Player_Start then
                if player:getHandcardNum() >= 10 then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true, 1)
                local n = 10 - player:getHandcardNum()
                local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                for _,id in sgs.qlist(room:getDrawPile()) do
                    obtain:addSubcard(sgs.Sanguosha:getCard(id))
                    n = n - 1
                    if n <= 0 then break end
                end
                room:obtainCard(player, obtain, false)
                room:ignoreCards(player, obtain:getSubcards())
                for _,id in sgs.qlist(obtain:getSubcards()) do
                    if room:getCardOwner(id):objectName() == player:objectName() then
                        room:setCardTip(id,"dianyingfu")
                    end
                end
                obtain:deleteLater()
            end

            if player:getPhase() == sgs.Player_NotActive then
                for _,card in sgs.qlist(player:getHandcards()) do
                    room:setCardTip(card:getId(),"-dianyingfu")
                end
            end
        end

        if event == sgs.TargetConfirmed then
            if player:getMark("&dianyingfu") > 0 then return false end
            local use = data:toCardUse()
            if use.to:length() ~= 1 then return false end
            local target = nil
            if use.from:objectName() == player:objectName() then
                target = use.to:first()
            else
                target = use.from
                if not use.to:contains(player) then return false end
            end
            if target:getHandcardNum() < player:getHandcardNum() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true, 2)
                local n = 0
                local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:isDamageCard() then
                        give:addSubcard(card)
                        n = n + 1
                    end
                end
                local choices = "give="..target:getGeneralName().."+all="..target:getGeneralName().."="..target:getKingdom()
                
                room:setPlayerMark(player, "dianyingfucards", n)
                local _data = sgs.QVariant()
                _data:setValue(target)

                local choice = room:askForChoice(player, self:objectName(), choices, _data)
                if string.find(choice, "give") then
                    local exchange = room:askForExchange(player, self:objectName(), 1, 1, false, "@dianyingfu:"..target:getGeneralName(), false)
                    room:giveCard(player, target, exchange, self:objectName(), false)
                    room:addPlayerHistory(use.from, use.card:getClassName(), -1)
                end
                if string.find(choice, "all") then
                    if player:getKingdom() ~= target:getKingdom() then
                        local log = sgs.LogMessage()
                        log.type = "#ChangeKingdom2"
                        log.from = player
                        log.arg = player:getKingdom()
                        log.arg2 = target:getKingdom()
                        room:sendLog(log)
                        room:setPlayerProperty(player, "kingdom", sgs.QVariant(target:getKingdom()))
                    end

                    if give:subcardsLength() > 0 then
                        room:giveCard(player, target, give, self:objectName(), true)
                    end
                    room:setPlayerMark(player, "&dianyingfu", 1)
                end
                give:deleteLater()
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dianfengshao = sgs.CreateTriggerSkill{
    name = "dianfengshao",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand)
        and move.to and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "dianfengshao-Clear")
            room:addPlayerMark(player, "&dianfengshao+-Clear")
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == player:getKingdom() then
                    targets:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@dianfengshao:"..player:getKingdom(), false, true)
            local choices 
            if target:getMark("dianfengshaofrom"..player:objectName().."-Clear") > 0 then
                choices = "recover="..target:getGeneralName().."+renew="..target:getGeneralName()
            else
                choices = "damage="..target:getGeneralName().."+turn="..target:getGeneralName()
            end

            local _data = sgs.QVariant()
            _data:setValue(target)

            local choice = room:askForChoice(player, self:objectName(), choices, _data)
            room:addPlayerMark(target, "dianfengshaofrom"..player:objectName().."-Clear")
            if string.find(choice, "recover") then
                if target:isWounded() then
                    room:recover(target, sgs.RecoverStruct(player, nil, 2))
                end
            elseif string.find(choice, "renew") then
                if not target:faceUp() then
                    target:turnOver()
                end
                if target:isChained() then
                    target:setChained(false)
                end
            elseif string.find(choice, "damage") then
                room:damage(sgs.DamageStruct(nil, player, target, 1, sgs.DamageStruct_Fire))
                room:addPlayerMark(target, "&dianfengshao+1_num+to+#"..player:objectName().."-Clear")
            elseif string.find(choice, "turn") then
                target:turnOver()
                target:drawCards(2)
                room:addPlayerMark(target, "&dianfengshao+2_num+to+#"..player:objectName().."-Clear")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("dianfengshao-Clear") < 2
    end,
}

dianchange = sgs.CreateZeroCardViewAsSkill
{
    name = "dianchange&",
    frequency = sgs.Skill_Limited,
    view_as = function(self)
        return dianchangeCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasSkill("dianyingfu") or player:hasSkill("dianfengshao")
    end
}

dianchangeCard = sgs.CreateSkillCard
{
    name = "dianchange",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:getKingdom() ~= "wu" then
            local log = sgs.LogMessage()
            log.type = "#ChangeKingdom2"
            log.from = source
            log.arg = source:getKingdom()
            log.arg2 = "wu"
            room:sendLog(log)
            room:setPlayerProperty(source, "kingdom", sgs.QVariant("wu"))
        end
        if source:hasSkill("dianyingfu") then
            room:detachSkillFromPlayer(source, "dianyingfu")
            room:acquireSkill(source, "dianshiwan", true)
        end
        if source:hasSkill("dianfengshao") then
            room:detachSkillFromPlayer(source, "dianfengshao")
            room:acquireSkill(source, "dianfengshaoori", true)
        end
    end
}

dianshiwan = sgs.CreateTriggerSkill{
    name = "dianshiwan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, "dianyingfu", true, true)
        player:drawCards(10)

        local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isDamageCard() then
                give:addSubcard(card)
            end
        end

        if give:subcardsLength() == 0 then
            local log = sgs.LogMessage()
            log.type = "$dianshiwannotcard"
            log.from = player
            room:sendLog(log)
            give:deleteLater()
            return false 
        end

        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getKingdom() == "wei" then
                targets:append(p)
            end
        end
        if targets:length() == 0 then
            local log = sgs.LogMessage()
            log.type = "$dianshiwannottarget"
            room:sendLog(log)
            give:deleteLater()
            return false 
        end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@dianshiwan:"..give:subcardsLength(), false, true)
        room:getThread():delay(500)
        if target:objectName() ~= player:objectName() then
            room:obtainCard(target, give, true)
        end
        give:deleteLater()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end,
}

dianfengshaoori = sgs.CreateTriggerSkill{
    name = "dianfengshaoori",
    events = {sgs.CardsMoveOneTime, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if player:getMark("diandamage_lun") > 0 and player:getMark("dianrecover_lun") > 0 then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
                room:sendCompulsoryTriggerLog(player, "dianfengshao", true, true)
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() == "wu" then
                        targets:append(p)
                    end
                end
                if targets:length() == 0 then
                    local log = sgs.LogMessage()
                    log.type = "$dianfengshaoorinottarget"
                    room:sendLog(log)
                    return false
                end
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@dianfengshaoori:dianfirst", false, true)
                local choices = {}
                if player:getMark("diandamage_lun") == 0 then
                    table.insert(choices, "damage="..target:getGeneralName())
                end
                if player:getMark("dianrecover_lun") == 0 then
                    table.insert(choices, "recover="..target:getGeneralName())
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if string.find(choice, "damage") then
                    player:addMark("diandamage_lun")
                    room:damage(sgs.DamageStruct(nil, player, target, 1, sgs.DamageStruct_Fire))
                elseif string.find(choice, "recover") then
                    player:addMark("dianrecover_lun")
                    room:recover(target, sgs.RecoverStruct(player, nil, 1))
                end
            end
        end
        if event == sgs.Damaged then
            if player:getMark("dianturn_lun") > 0 and player:getMark("dianback_lun") > 0 then return false end
            room:getThread():delay(500)
            room:sendCompulsoryTriggerLog(player, "dianfengshao", true, true)
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == "wu" then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then
                local log = sgs.LogMessage()
                log.type = "$dianfengshaoorinottarget"
                room:sendLog(log)
                return false
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@dianfengshaoori:diansecond", false, true)
            local choices = {}
            if player:getMark("dianturn_lun") == 0 then
                table.insert(choices, "turn="..target:getGeneralName())
            end
            if player:getMark("dianback_lun") == 0 then
                table.insert(choices, "back="..target:getGeneralName())
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
            if string.find(choice, "turn") then
                player:addMark("dianturn_lun")
                target:turnOver()
            elseif string.find(choice, "back") then
                player:addMark("dianback_lun")
                if not target:faceUp() then
                    target:turnOver()
                end
                if target:isChained() then
                    target:setChained(false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

diansunquan:addSkill(dianyingfu)
diansunquan:addSkill(dianfengshao)
diansunquan:addSkill(dianchange)

mjzhaozhi = sgs.General(extension, "mjzhaozhi", "shu", 3, true, false, false)

mjmengjie = sgs.CreateTriggerSkill{
    name = "mjmengjie",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            for _,skill in sgs.qlist(p:getVisibleSkillList()) do
                if not skill:isAttachedLordSkill() then
                    targets:append(p)
                    break
                end
            end
        end
        if targets:length() < 2 then return false end
        local selected = room:askForPlayersChosen(player, targets, self:objectName(), -1, 2, "@mjmengjie", true)
        if (not selected) or (selected:length() ~= 2) then return false end
        room:broadcastSkillInvoke(self:objectName())
        selected = sgs.QList2Table(selected)
        local swapa, swapb
        local choicesa, choicesb = {}, {}
        for _,skill in sgs.qlist(selected[1]:getVisibleSkillList()) do
            if not skill:isAttachedLordSkill() then
                table.insert(choicesa, skill:objectName())
            end
        end
        for _,skill in sgs.qlist(selected[2]:getVisibleSkillList()) do
            if not skill:isAttachedLordSkill() then
                table.insert(choicesb, skill:objectName())
            end
        end
        swapa = room:askForChoice(player, self:objectName(), table.concat(choicesa, "+"), sgs.QVariant(), nil, "mjmengjielose")
        swapb = room:askForChoice(player, self:objectName(), table.concat(choicesb, "+"), sgs.QVariant(), nil, "mjmengjielose")
        room:detachSkillFromPlayer(selected[1], swapa)
        room:detachSkillFromPlayer(selected[2], swapb)
        room:acquireSkill(selected[1], swapb, true)
        room:acquireSkill(selected[2], swapa, true)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end, 
}

mjtongguanVS = sgs.CreateViewAsSkill
{
    name = "mjtongguan",
    n = 1,
    response_pattern = "@@mjtongguan",
    expand_pile = "#mjtongguan",
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getPile("#mjtongguan"):contains(to_select:getId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = mjtongguanCard:clone()
        card:addSubcard(cards[1])
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

mjtongguanCard = sgs.CreateSkillCard
{
    name = "mjtongguan",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and (not to_select:hasFlag("mjtongguantarget"))
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerFlag(effect.to, "mjtongguandes")
    end
}

mjtongguan = sgs.CreateTriggerSkill{
    name = "mjtongguan",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    change_skill = true,
    view_as_skill = mjtongguanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card 
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or (not card:isKindOf("BasicCard")) then return false end
        local card_ids
        local target
        if player:getChangeSkillState(self:objectName()) <= 1 then
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("view")) then return false end
            room:setChangeSkillState(player, self:objectName(), 2)
            card_ids = room:getNCards(4)
            room:returnToTopDrawPile(card_ids)

            local selflog = sgs.LogMessage()
            selflog.type = "$ViewDrawPile"
            selflog.from = player
            selflog.card_str = table.concat(sgs.QList2Table(card_ids), "+")
            room:sendLog(selflog, player)

            local otherlog = sgs.LogMessage()
            otherlog.type = "#ViewDrawPile"
            otherlog.from = player
            otherlog.arg = "4"
            room:sendLog(otherlog, room:getOtherPlayers(player))
        else
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isKongcheng() then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then return false end
            target = room:askForPlayerChosen(player, targets, self:objectName(), "@mjtongguan", true, true)
            if not target then return false end
            room:setChangeSkillState(player, self:objectName(), 1)

            card_ids = sgs.IntList()
            for _,card in sgs.qlist(target:getHandcards()) do
                card_ids:append(card:getEffectiveId())
            end

            local selflog = sgs.LogMessage()
            selflog.type = "$ViewAllCards"
            selflog.from = player
            selflog.to:append(target)
            selflog.card_str = table.concat(sgs.QList2Table(card_ids), "+")
            room:sendLog(selflog, player)

            local otherlog = sgs.LogMessage()
            otherlog.type = "#ViewAllCards"
            otherlog.from = player
            otherlog.to:append(target)
            room:sendLog(otherlog, room:getOtherPlayers(player))
        end

        if math.random(1,3) > 1 then room:broadcastSkillInvoke(self:objectName()) end

        if target then
            room:setPlayerFlag(target, "mjtongguantarget")
        end

        local tag = sgs.QVariant()
        tag:setValue(card_ids)
        player:setTag("mjtongguancards", tag)

        local place = room:getCardPlace(card_ids:first())
        room:notifyMoveToPile(player, card_ids, "mjtongguan", place, true)
        local use = room:askForUseCard(player, "@@mjtongguan", "mjtongguanmove")
        room:notifyMoveToPile(player, card_ids, "mjtongguan", place, false)

        if target then
            room:setPlayerFlag(target, "-mjtongguantarget")
        end

        if use then
            local move_id = use:getSubcards():first()
            local des 
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("mjtongguandes") then
                    des = p
                    room:setPlayerFlag(p, "-mjtongguandes")
                    break
                end
            end
            local move_card = sgs.Sanguosha:getCard(move_id)
            local choices = {"hand"}
            if move_card:isKindOf("DelayedTrick") then
                local name = move_card:objectName()
                if des:hasJudgeArea() and (not des:containsTrick(name)) then
                    table.insert(choices,"judge")
                end
            elseif move_card:isKindOf("EquipCard") then
                local n = -1
                if move_card:isKindOf("Weapon") then
                    n = 0
                elseif move_card:isKindOf("Armor") then
                    n = 1
                elseif move_card:isKindOf("DefensiveHorse") then
                    n = 2
                elseif move_card:isKindOf("OffensiveHorse") then
                    n = 3
                elseif move_card:isKindOf("Treasure") then
                    n = 4
                end
                if des:hasEquipArea(n) and (not des:getEquip(n)) then
                    table.insert(choices, "equip")
                end
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), nil, "mjtongguanchoice")

            local log = sgs.LogMessage()
            log.type = "$mjtongguanend"
            log.from = player
            log.to:append(des)
            log.arg = self:objectName()..":"..choice
            log.card_str = move_card:toString()
            room:sendLog(log)

            if choice == "hand" then
                room:obtainCard(des, move_card, false)
            elseif choice == "judge" then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                room:moveCardTo(move_card, nil, des, sgs.Player_PlaceDelayedTrick, reason)
            elseif choice == "equip" then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                room:moveCardTo(move_card, nil, des, sgs.Player_PlaceEquip, reason)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

mjzhaozhi:addSkill(mjmengjie)
mjzhaozhi:addSkill(mjtongguan)
mjzhaozhi:addSkill(mjtongguanVS)

gswanglang = sgs.General(extension, "gswanglang", "wei", 3, true, true, false)

gsgushe = sgs.CreateViewAsSkill
{
    name = "gsgushe",
    n = 0,
    view_filter = function(self, selected, to_select)
        return false
    end,
    view_as = function(self, cards)
        return gsgusheCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("gsgushe_failed-PlayClear") == 0 and player:getMark("&gsjici") < 7
    end
}
gsgusheCard = sgs.CreateSkillCard
{
    name = "gsgushe",
    filter = function(self, targets, to_select)
        return #targets < 3 and sgs.Self:canPindian(to_select)
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        --发送拼点信息
        local log = sgs.LogMessage()
        log.type = "#Pindian"
        log.from = source
	    local to_names = {}
	    for i,to in ipairs(targets)do
		    log.to:append(to)
	    end
        room:sendLog(log)
        --获取因技能获得的拼点牌
        local pd = sgs.PindianStruct()
	    local pd_to_card = {}
	    pd.from = source
	    pd.reason = self:objectName()
	    for data,to in ipairs(targets)do
		    pd.to = to
		    pd.to_card = nil
		    data = sgs.QVariant()
            data:setValue(pd)
		    room:getThread():trigger(sgs.AskforPindianCard,room,source,data)
		    pd = data:toPindian()
		    if pd.to_card then
			    pd_to_card[to:objectName()]=pd.to_card
		    end
	    end
        --获取正常获得的拼点牌
	    local pd_to_number = {}
	    for c,to in ipairs(targets)do
		    if not pd_to_card[to:objectName()] and (not pd.from_card) then
	    		c = room:askForPindianRace(source,to,self:objectName())
		    	if c:length()<2 then continue end
		    	pd.from_card = c:at(0)
		    	pd.from_number = c:at(0):getNumber()
		    	pd_to_card[to:objectName()] = c:at(1)
		    	pd_to_number[to:objectName()] = c:at(1):getNumber()
		    elseif not pd.from_card then
			    --pd.from_card = room:askForPindian(source, source, to, self:objectName())
                pd.from_card = room:askForPindian(source, to, self:objectName())
			    pd.from_number = pd.from_card:getNumber()
		    elseif not pd_to_card[to:objectName()] then
			    --pd_to_card[to:objectName()] = room:askForPindian(to, source, to, self:objectName())
                pd_to_card[to:objectName()] = room:askForPindian(to, source, self:objectName())
			    pd_to_number[to:objectName()] = pd_to_card[to:objectName()]:getNumber()
		    end
    	end
        --将拼点牌置于场上
    	local moves = sgs.CardsMoveList()
    	if pd.from_card then
    		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),"",pd.reason,"pindian")
    		moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
    	end
	    for c,to in ipairs(targets)do
	    	c = pd_to_card[to:objectName()]
	    	if not c then continue end
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),to:objectName(),pd.reason,"pindian")
    		moves:append(sgs.CardsMoveStruct(c:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
    	end
    	room:moveCardsAtomic(moves,true)
        --展示拼点牌（消息）
        log.type = "$PindianResult"
        log.from = pd.from
        log.card_str = pd.from_card:getEffectiveId()
        room:sendLog(log)
        for c,to in ipairs(targets)do
            c = pd_to_card[to:objectName()]
            if not c then continue end
            log.type = "$PindianResult"
            log.from = to
            log.card_str = c:getEffectiveId()
            room:sendLog(log)
        end
        --允许技能改变拼点牌大小
        local fn
	    for data,to in ipairs(targets)do
		    pd.to_card = pd_to_card[to:objectName()]
		    if not pd.to_card then continue end
		    pd.to_number = pd_to_number[to:objectName()]
		    pd.to = to
		    data = sgs.QVariant()
            data:setValue(pd)
		    room:getThread():trigger(sgs.PindianVerifying,room,source,data)
		    pd = data:toPindian()
		    fn = fn or pd.from_number
		    pd_to_number[to:objectName()] = pd.to_number
		    pd.from_number = pd.from_card:getNumber()
	    end
	    pd.from_number = fn or pd.from_number
        --比较拼点结果
        local will = true
        for c,to in ipairs(targets)do
            c = pd_to_card[to:objectName()]
            if not c then continue end
            local data = sgs.QVariant()
            pd.to_card = pd_to_card[to:objectName()]
            pd.to_number = pd_to_number[to:objectName()]
            pd.to = to
            if pd.from_number > pd_to_number[to:objectName()] then
                room:setEmotion(source,"success")
                room:setEmotion(to,"no-success")

                local log_1 = sgs.LogMessage()
                log_1.type = "#PindianSuccess"
                log_1.from = source
                log_1.to:append(to)
                room:sendLog(log_1)

                room:setPlayerMark(source, "&gsjici", source:getMark("&gsjici")+1)
                room:setPlayerFlag(source, "gsgushetarget")
                if not room:askForDiscard(to, self:objectName(), 1, 1, true, false, "@gsgushe:"..source:getGeneralName()) then
                    source:drawCards(1)
                end
                room:setPlayerFlag(source, "-gsgushetarget")

                pd.success = true
                will = false
            elseif pd.from_number == pd_to_number[to:objectName()] then
                room:setEmotion(source,"no-success")
                room:setEmotion(to,"no-success")

                local log_1 = sgs.LogMessage()
                log_1.type = "#PindianFailure"
                log_1.from = source
                log_1.to:append(to)
                room:sendLog(log_1)

                room:setPlayerFlag(source, "gsgushetarget")
                if not room:askForDiscard(source, self:objectName(), 1, 1, true, false, "@gsgushe:"..source:getGeneralName()) then
                    source:drawCards(1)
                end
                if not room:askForDiscard(to, self:objectName(), 1, 1, true, false, "@gsgushe:"..source:getGeneralName()) then
                    source:drawCards(1)
                end
                room:setPlayerFlag(source, "-gsgushetarget")

                pd.success = false
            elseif pd.from_number < pd_to_number[to:objectName()] then
                room:setEmotion(source,"no-success")
                room:setEmotion(to,"success")

                local log_1 = sgs.LogMessage()
                log_1.type = "#PindianFailure"
                log_1.from = source
                log_1.to:append(to)
                room:sendLog(log_1)

                room:setPlayerFlag(source, "gsgushetarget")
                if not room:askForDiscard(source, self:objectName(), 1, 1, true, false, "@gsgushe:"..source:getGeneralName()) then
                    source:drawCards(1)
                end
                room:setPlayerFlag(source, "-gsgushetarget")

                pd.success = false
            end
            data:setValue(pd)
            room:getThread():trigger(sgs.Pindian,room,source,data)
            room:getThread():delay(800)
        end
        --将拼点牌置入弃牌堆
        local moves = sgs.CardsMoveList()
	    if pd.from_card and room:getCardPlace(pd.from_card:getEffectiveId())==sgs.Player_PlaceTable then
		    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),"",pd.reason,"pindian")
		    moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	    end
	    for c,to in ipairs(targets)do
		    c = pd_to_card[to:objectName()]
		    if not c or room:getCardPlace(c:getEffectiveId())~=sgs.Player_PlaceTable then continue end
		    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),to:objectName(),pd.reason,"pindian")
		    moves:append(sgs.CardsMoveStruct(c:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	    end
	    room:moveCardsAtomic(moves,true)

        if will then
            local failed_log = sgs.LogMessage()
            failed_log.type = "$gsgushe_allfailed"
            failed_log.from = source
            room:sendLog(failed_log)
            
            if source:isAlive() then
                room:setPlayerMark(source, "gsgushe_failed-PlayClear", 1)
                room:setPlayerMark(source, "&gsgushe", source:getMark("&gsgushe")+1)
                room:loseHp(source, 1, true, source, self:objectName())
            end
        end
    end
}

gsgushe_addnum = sgs.CreateTriggerSkill{
    name = "#gsgushe_addnum",
    events = {sgs.PindianVerifying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local pindian = data:toPindian()
        local can = false
        local n
        if pindian.from:objectName() == player:objectName() and player:getMark("&gsgushe") > 0 and pindian.from_number < 13 then 
            pindian.from_number = pindian.from_number + 2*player:getMark("&gsgushe")
            if pindian.from_number > 13 then pindian.from_number = 13 end
            can = true
            n = pindian.from_number
        elseif pindian.to:objectName() == player:objectName() and player:getMark("&gsgushe") > 0 and pindian.to_number < 13 then 
            pindian.to_number = pindian.to_number + 2*player:getMark("&gsgushe")
            if pindian.to_number > 13 then pindian.to_number = 13 end
            can = true
            n = pindian.to_number
        end
        if can then
            local log = sgs.LogMessage()
            log.type = "$gsgushe_addnum"
            log.from = player
            log.arg = "gsgushe"
            log.arg2 = n
            room:sendLog(log)

            data:setValue(pindian)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("gsgushe")
    end,
}

gsjici = sgs.CreateZeroCardViewAsSkill
{
    name = "gsjici",
    juguan_type = "nullification,snatch,dismantlement,collateral,ex_nihilo,duel,fire_attack,amazing_grace,savage_assault,archery_attack,god_salvation,iron_chain",
    view_as = function(self)
        local card = sgs.Self:getTag("gsjici"):toCard()
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern():split("+")
            card = sgs.Sanguosha:cloneCard(pattern[1], sgs.Card_SuitToBeDecided, -1)
        end
        if card then
            local cc = gsjiciCard:clone()
            cc:setUserString(card:objectName())
            card:deleteLater()
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&gsjici") > player:getMark("&countjici_usedtimes-Clear")
    end,
    --[[enabled_at_nullification = function(self, player)
        return player:getMark("&gsjici") > player:getMark("&countjici_usedtimes-Clear") 
        and player:getMark("gsjici_juguan_remove_nullification") == 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:getMark("&gsjici") > player:getMark("&countjici_usedtimes-Clear") 
        and player:getMark("gsjici_juguan_remove_nullification") == 0
    end
}

gsjiciCard = sgs.CreateSkillCard
{
    name = "gsjici",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local pattern = self:getUserString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("gsjici")

        if card:targetFixed() then return false end

        card:deleteLater()
        return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets, player)
        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("gsjici")
        use_card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if use_card and use_card:canRecast() and #targets == 0 then
			return false
		end

        return use_card and use_card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local pattern = self:getUserString()

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())

        local n = source:getMark("&countjici_usedtimes-Clear") + 1
        room:setPlayerMark(source, "&gsjici", source:getMark("&gsjici")-n)

        local only = sgs.SPlayerList()
        only:append(source)
        room:setPlayerMark(source, "&countjici_usedtimes-Clear", n, only)
        room:setPlayerMark(source, "gsjici_juguan_remove_"..pattern, 1)
        source:removeTag("gsjici")

        local names = source:property("SkillDescriptionRecord_gsjici"):toString():split("+")
        if not table.contains(names, card:objectName()) then 
            table.insert(names, card:objectName())
            local result = ""
            for i, v in ipairs(names) do
                if i > 1 then
                    result = result .. "+|+"
                end
                result = result .. v
            end
            room:setPlayerProperty(source, "SkillDescriptionRecord_gsjici", sgs.QVariant(table.concat(names, "+")))
            source:setSkillDescriptionSwap("gsjici", "%arg1", result)
            room:changeTranslation(source, "gsjici", 2)
        end

        return card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local pattern = self:getUserString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())

        local n = source:getMark("&countjici_usedtimes-Clear") + 1
        room:setPlayerMark(source, "&gsjici", source:getMark("&gsjici")-n)

        local only = sgs.SPlayerList()
        only:append(source)
        room:setPlayerMark(source, "&countjici_usedtimes-Clear", n, only)
        room:setPlayerMark(source, "gsjici_juguan_remove_"..pattern, 1)
        local names = source:property("SkillDescriptionRecord_gsjici"):toString():split("+")
        if not table.contains(names, card:objectName()) then 
            table.insert(names, card:objectName())
            local result = ""
            for i, v in ipairs(names) do
                if i > 1 then
                    result = result .. "+|+"
                end
                result = result .. v
            end
            room:setPlayerProperty(source, "SkillDescriptionRecord_gsjici", sgs.QVariant(table.concat(names, "+")))
            source:setSkillDescriptionSwap("gsjici", "%arg1", result)
            room:changeTranslation(source, "gsjici", 2)
        end

        return card
    end,
}

gsjici_new = sgs.CreateTriggerSkill{
    name = "#gsjici_new",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.from and damage.from:objectName() ~= player:objectName() then else return false end
        room:sendCompulsoryTriggerLog(player, "gsjici", true, true)
        if damage.from and damage.from:canDiscard(damage.from, "he") then
            room:askForDiscard(damage.from, "gsjici", 1, 1, false, true)
        end
        if player:isAlive() then
            for _,name in sgs.list(player:getMarkNames())do
                if player:getMark(name) > 0 and name:startsWith("gsjici_juguan_remove_") then
                    local n = string.len("gsjici_juguan_remove_")+1
                    local pattern = string.sub(name,n)
                    local log = sgs.LogMessage()
                    log.type = "$gsjici_renew"
                    log.from = player
                    log.arg = "gsjici"
                    log.arg2 = pattern
                    room:sendLog(log)
                    room:removePlayerMark(player, name, player:getMark(name))
                end
            end
            room:changeTranslation(player, "gsjici", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

gswanglang:addSkill(gsgushe)
gswanglang:addSkill(gsgushe_addnum)
gswanglang:addSkill(gsjici)
gswanglang:addSkill(gsjici_new)
extension:insertRelatedSkills("gsgushe", "#gsgushe_addnum")
extension:insertRelatedSkills("gsjici", "#gsjici_new")

bndongzhuo = sgs.General(extension, "bndongzhuo$", "qun", 4, true, false, false)

bnbenghuai = sgs.CreateTriggerSkill{
    name = "bnbenghuai$",
    events = {sgs.GameStart,sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:gainMaxHp(player, 4, self:objectName())
            room:recover(player, sgs.RecoverStruct(self:objectName(), player, 4))
        end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then 
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local choices = "hp+max+all"
                local choice = room:askForChoice(player, self:objectName(), choices)
                local log = sgs.LogMessage()
                log.type = "$bnbenghuai_select"
                log.from = player
                log.arg = "bnbenghuai:"..choice
                room:sendLog(log)

                if string.find(choice, "hp") or string.find(choice, "all") then
                    room:loseHp(player, 1, true, player, self:objectName())
                end
                if player:isDead() then return false end
                if string.find(choice, "max") or string.find(choice, "all") then
                    room:loseMaxHp(player, 1)
                end
                if player:isDead() then return false end
                if string.find(choice, "all") then
                    player:drawCards(2, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasLordSkill(self:objectName())
    end,
}

bnbaonve = sgs.CreateTriggerSkill{
    name = "bnbaonve",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then return false end
        if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() then else return false end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        if player:getMark("&bnbaonve_damage") > 0 then
            local n = death.who:getMaxHp()
            local log = sgs.LogMessage()
            log.type = "$bnbaonve_add_damage_log"
            log.from = player
            log.arg = n
            log.arg2 = n + player:getMark("&bnbaonve_damage")
            room:sendLog(log)

            local only = sgs.SPlayerList()
            only:append(player)
            room:addPlayerMark(player, "&bnbaonve_damage", n, only)
            return false
        end
        local used = 0
        local only = sgs.SPlayerList()
        only:append(player)
        room:addPlayerMark(player, "&bnbaonve_damage", death.who:getMaxHp(), only)
        while(true)do
            room:broadcastSkillInvoke(self:objectName())
            used = used + 1
            local others = room:getOtherPlayers(player)
            others = sgs.QList2Table(others)
            local target = others[math.random(1,#others)]

            local log = sgs.LogMessage()
            log.type = "$bnbaonve_damage_log"
            log.from = player
            log.to:append(target)
            log.arg = used
            log.arg2 = player:getMark("&bnbaonve_damage") - 1
            room:sendLog(log)

            room:removePlayerMark(player, "&bnbaonve_damage", 1)
            room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
            room:getThread():delay(1000)
            if player:isDead() then return false end
            if player:getMark("&bnbaonve_damage") <= 0 then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

bnhengzheng = sgs.CreateTriggerSkill{
    name = "bnhengzheng",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getHandcardNum() > player:getHp() then return false end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("get")) then
            room:broadcastSkillInvoke(self:objectName())
            room:loseHp(player, 1, true, player, self:objectName())
            if player:isDead() then return false end
            for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                if (not other:isNude()) and other:isAlive() then
                    local give = room:askForExchange(other, self:objectName(), 1, 1, true, "@bnhengzheng:"..player:getGeneralName(), false)
                    room:obtainCard(player, give, false)
                    if player:isDead() then return false end
                    room:getThread():delay(500)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end, 
}

bnjiuchi = sgs.CreateViewAsSkill
{
    name = "bnjiuchi",
    n = 1,
    view_filter = function(self, selected, to_select)
		return (to_select:getSuit() == sgs.Card_Spade) and #selected < 1
	end,
	view_as = function(self, cards)
		local card = bnjiuchiCard:clone()
        if #cards > 0 then
            card:addSubcard(cards[1])
        end
        return card
	end,
	enabled_at_play = function(self, player)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
        analeptic:setSkillName(self:objectName())
        return analeptic:isAvailable(player) and player:getMark("bnjiuchi-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:getMark("bnjiuchi-Clear") == 0
	end
}

bnjiuchiCard = sgs.CreateSkillCard
{
    name = "bnjiuchi",
    will_throw = false,
    target_fixed = true,
    feasible = function(self, targets, player)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, -1)
        analeptic:setSkillName(self:objectName())
        if self:getSubcards():length() > 0 then
            analeptic:addSubcards(self:getSubcards())
        end
        analeptic:deleteLater()
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return analeptic and analeptic:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, -1)
        analeptic:setSkillName(self:objectName())
        if self:getSubcards():length() > 0 then
            analeptic:addSubcards(self:getSubcards())
        else
            room:setPlayerMark(source, "bnjiuchi-Clear", 1)
            room:setPlayerMark(source, "&bnjiuchi+fail+-Clear", 1)

            local log = sgs.LogMessage()
            log.type = "$bnjiuchi_failed"
            log.from = source
            log.arg = self:objectName()
            room:sendLog(log)
        end
        return analeptic
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, -1)
        analeptic:setSkillName(self:objectName())
        if self:getSubcards():length() > 0 then
            analeptic:addSubcards(self:getSubcards())
        else
            room:setPlayerMark(source, "bnjiuchi-Clear", 1)

            local log = sgs.LogMessage()
            log.type = "$bnjiuchi_failed"
            log.from = source
            log.arg = self:objectName()
            room:sendLog(log)
        end
        return analeptic
    end,
}

bnjiuchi_target = sgs.CreateTargetModSkill{
    name = "#bnjiuchi_target",
    pattern = "Analeptic",
    residue_func = function(self, from, card) 
        if from:hasSkill("bnjiuchi") then return 1000 end
        return 0
    end,
}

bndongzhuo:addSkill(bnbenghuai)
bndongzhuo:addSkill(bnbaonve)
bndongzhuo:addSkill(bnhengzheng)
bndongzhuo:addSkill(bnjiuchi)
bndongzhuo:addSkill(bnjiuchi_target)
extension:insertRelatedSkills("bnjiuchi", "#bnjiuchi_target")

jscaoren = sgs.General(extension, "jscaoren", "wei", 4, true, false, false)

jsjushou = sgs.CreateTriggerSkill{
    name = "jsjushou",
    events = {sgs.CardResponded,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_UNKNOWN then return false end
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            card = response.m_card
        end
        if (not card) or (card:isKindOf("SkillCard")) or (card:isVirtualCard()) then return false end

        local count = 0
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:inMyAttackRange(player) then
                count = count + 1
            end
        end
        count = math.max(1,count)
        local prompt = string.format("draw:%s::%s:",card:objectName(),count)
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke(self:objectName())
            room:moveCardsToEndOfDrawpile(player, card:getSubcards(), self:objectName(), true)

            local log = sgs.LogMessage()
            log.type = "$PutCardEnd2"
            log.from = player
            log.card_str = table.concat(sgs.QList2Table(card:getSubcards()), "+")
            room:sendLog(log)

            player:drawCards(count, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jsjiewei = sgs.CreateTriggerSkill{
    name = "jsjiewei",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isKongcheng() then return false end
        local use = data:toCardUse()
        if (not use.card:isNDTrick()) and (not use.card:isKindOf("Slash")) then return false end
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(use.to) do
            if p:getHandcardNum() < player:getHandcardNum() then
                targets:append(p)
            end
        end
        if targets:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jsjiewei:"..use.card:objectName(), true, true)
        
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, "jsjiewei-Clear", 1)
            room:addPlayerMark(player, "&jsjiewei-Clear", 1)
            local num = math.min(5,player:getHandcardNum() - target:getHandcardNum())
            target:drawCards(num, self:objectName(), false)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("jsjiewei-Clear") < 1
    end,
}

jscaoren:addSkill(jsjushou)
jscaoren:addSkill(jsjiewei)

xscaopi = sgs.General(extension, "xscaopi$", "wei", 3, true, false, false)

xsxingshang = sgs.CreateTriggerSkill{
    name = "xsxingshang",
    events = {sgs.Death,sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("death")) then
                    room:broadcastSkillInvoke(self:objectName())
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
                    end
                    if player:isAlive() then
                        player:drawCards(1, self:objectName())
                    end
                end
            end
        end

        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@xsxingshang", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(target, "xsxingshangfrom"..player:objectName(), 1)
                room:setPlayerMark(target, "&xsxingshang+to+#"..player:objectName(), 1)
                room:loseHp(target, 1, true, player, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

xsxingshangdying = sgs.CreateTriggerSkill{
    name = "#xsxingshangdying",
    events = {sgs.EnterDying,sgs.QuitDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end

        local targets = room:findPlayersBySkillName("xsxingshang")
        for _,target in sgs.qlist(targets) do
            if target:isAlive() then
                if player:getMark("xsxingshangfrom"..target:objectName()) > 0 then

                    if event == sgs.EnterDying and (not player:isNude()) then
                        room:sendCompulsoryTriggerLog(target, "xsxingshang", true, true)
                        local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        for _,card in sgs.qlist(player:getHandcards()) do
                            give:addSubcard(card)
                        end
                        for _,card in sgs.qlist(player:getEquips()) do
                            give:addSubcard(card)
                        end
                        room:setPlayerMark(target, "xsxingshang_"..player:objectName().."-Clear", give:subcardsLength())
                        target:obtainCard(give, false)
                        give:deleteLater()
                    end

                    if event == sgs.QuitDying and (not target:isNude()) and target:getMark("xsxingshang_"..player:objectName().."-Clear") > 0 then
                        room:sendCompulsoryTriggerLog(target, "xsxingshang", true, true)
                        local n = target:getMark("xsxingshang_"..player:objectName().."-Clear")
                        room:setPlayerMark(target, "xsxingshang_"..player:objectName().."-Clear", 0)
                        local get = room:askForExchange(target, "xsxingshang", n, n, true, "xsreturn:"..player:getGeneralName()..":"..n, false)
                        player:obtainCard(get, false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

xsfangzu = sgs.CreateTriggerSkill{
    name = "xsfangzu",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local times = data:toDamage().damage
        for i = 1, times, 1 do
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@xsfangzu", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                local _data = sgs.QVariant()
                _data:setValue(target)

                local n = player:getLostHp()
                local choice = room:askForChoice(player, self:objectName(), "turn="..n.."+discard="..n, _data)
                if string.find(choice, "turn") then
                target:drawCards(n, self:objectName())
                if target:isAlive() then target:turnOver() end
                end
                if string.find(choice, "discard") then
                    room:askForDiscard(target, self:objectName(), n, n, false, true)
                    if target:isAlive() then room:loseHp(target, 1, true, player, self:objectName()) end
                end
            else
                return false
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

xssongwei = sgs.CreateTriggerSkill{
    name = "xssongwei$",
    events = {sgs.FinishJudge},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasLordSkill(self:objectName()) then
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    p:drawCards(1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getKingdom() == "wei"
    end,
}

xscaopi:addSkill(xsxingshang)
xscaopi:addSkill(xsxingshangdying)
xscaopi:addSkill(xsfangzu)
xscaopi:addSkill(xssongwei)
extension:insertRelatedSkills("xsxingshang", "#xsxingshangdying")

tyshendengai = sgs.General(extension, "tyshendengai", "god", 4, true, false, false)

ty_tuoyu = sgs.CreateTriggerSkill{
    name = "ty_tuoyu",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getMark("ty_tuoyu_expand") == 0 then return false end
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then card = response.m_card end
            end
            if (not card) or card:isKindOf("SkillCard") then return false end

            local all = {"ty_tuoyu_fengtian","ty_tuoyu_qingqu","ty_tuoyu_junshan"}
            local choices = {}
            for _,choice in ipairs(all) do
                if player:getMark(choice) > 0 then
                    table.insert(choices, choice)
                end
            end
            local _data = sgs.QVariant()
            _data:setValue(card)
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), _data)
            room:broadcastSkillInvoke(self:objectName())
            
            local log = sgs.LogMessage()
            log.type = "$ty_tuoyu_effect"
            log.from = player
            log.arg = choice
            log.card_str = card:toString()
            room:sendLog(log)

            if choice == "ty_tuoyu_fengtian" then
                room:setCardFlag(card, "ty_tuoyu_fengtian")
                if card:isKindOf("Analeptic") and player:getHp() >= 1 then
                    local ana = player:getMark("drank")
                    ana = ana + 1
                    room:setPlayerMark(player, "drank", ana)
                end
            elseif choice == "ty_tuoyu_qingqu" then
                room:addPlayerHistory(player, card:getClassName(), -1)
            elseif choice == "ty_tuoyu_junshan" then
                if event == sgs.CardUsed then
                    local use = data:toCardUse()
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ty_tuoyu_buff = sgs.CreateTriggerSkill{
    name = "#ty_tuoyu_buff",
    events = {sgs.DamageCaused,sgs.PreHpRecover},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then return false end
            if damage.card and damage.card:hasFlag("ty_tuoyu_fengtian") then
                local log = sgs.LogMessage()
                log.type = "$ty_tuoyu_buff"
                log.from = damage.from
                log.arg = "ty_tuoyu_damage"
                log.arg2 = "ty_tuoyu"
                log.arg3 = damage.damage
                log.arg4 = damage.damage + 1
                room:sendLog(log)

                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end

        if event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("ty_tuoyu_fengtian") then
                local log = sgs.LogMessage()
                log.type = "$ty_tuoyu_buff"
                log.from = recover.from
                log.arg = "ty_tuoyu_recover"
                log.arg2 = "ty_tuoyu"
                log.arg3 = recover.recover
                log.arg4 = recover.recover + 1
                room:sendLog(log)

                recover.recover = recover.recover + 1
                data:setValue(recover)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

ty_tuoyu_distance = sgs.CreateTargetModSkill{
    name = "#ty_tuoyu_distance",
    pattern = ".",
    distance_limit_func = function(self, from, card)
        if from:getMark("ty_tuoyu_expand") >= 3 then return 1000 end
        return 0
    end,
}

ty_xianjin = sgs.CreateTriggerSkill{
    name = "ty_xianjin",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage or event == sgs.Damaged then
            local n = data:toDamage().damage
            room:addPlayerMark(player, "&ty_xianjin", n)
            local first = true
            while(player:getMark("&ty_xianjin") >= 2) do
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                room:removePlayerMark(player, "&ty_xianjin", 2)
                if first then
                    room:broadcastSkillInvoke(self:objectName())
                    if player:getMark("ty_tuoyu_expand") >= 3 then
                        first = false
                    else
                        local all = {"ty_tuoyu_fengtian","ty_tuoyu_qingqu","ty_tuoyu_junshan"}
                        local choices = {}
                        for _,choice in ipairs(all) do
                            if player:getMark(choice) == 0 then
                                table.insert(choices, choice)
                            end
                        end

                        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), sgs.QVariant())
                        room:setPlayerMark(player, choice, 1)
                        room:addPlayerMark(player, "ty_tuoyu_expand", 1)
                        room:addPlayerMark(player, "&" .. choice .."_gain", 1)

                        local log = sgs.LogMessage()
                        log.type = "$ty_tuoyu_expand_choice"
                        log.from = player
                        log.arg = choice
                        room:sendLog(log)
                    end
                end
                player:drawCards(1, self:objectName())
                if player:isDead() then return false end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

tyqijin = sgs.CreateTriggerSkill{
    name = "tyqijin",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Wake,
    waked_skills = "tycuixin",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end

        local target = nil
        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if  p:getMark("tyqijin_wake") == 0 then
                if p:canWake(self:objectName()) or p:getMark("ty_tuoyu_expand") >= 3 then
                    target = p
                    break
                end
            end
        end
        if target then
            room:sendCompulsoryTriggerLog(target, self:objectName(), true, true)
            room:notifySkillInvoked(target, self:objectName())
            room:loseMaxHp(target, 1)
            room:setPlayerMark(target, "tyqijin_wake", 1)
            room:setPlayerMark(target, "tyqijin", 1)
            room:acquireSkill(target, "tycuixin", true)

            local swap = room:askForPlayerChosen(target, room:getOtherPlayers(target), self:objectName(), "@tyqijin", true, true)
            if swap then room:swapSeat(target, swap) end

            local log = sgs.LogMessage()
            log.type = "$tyqijin_wake"
            log.from = target
            log.arg = self:objectName()
            room:sendLog(log)

            target:gainAnExtraTurn()
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

tycuixin = sgs.CreateTriggerSkill{
    name = "tycuixin",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() then return false end
        if (not use.to:contains(player)) and use.to:length() == 1 then
            local _data = sgs.QVariant()
            for _,p in sgs.qlist(use.to) do
                if (not p:isNude()) then
                    _data:setValue(p)
                    if room:askForSkillInvoke(player, self:objectName(), _data) then
                        room:broadcastSkillInvoke(self:objectName())
                        local card = room:askForCardChosen(player, p, "he", self:objectName(), true)
                        room:obtainCard(player, card, false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

tyshendengai:addSkill(ty_tuoyu)
tyshendengai:addSkill(ty_tuoyu_buff)
tyshendengai:addSkill(ty_tuoyu_distance)
tyshendengai:addSkill(ty_xianjin)
tyshendengai:addSkill(tyqijin)
extension:insertRelatedSkills("ty_tuoyu","#ty_tuoyu_buff")
extension:insertRelatedSkills("ty_xianjin","#ty_tuoyu_distance")

jjshendianwei = sgs.General(extension, "jjshendianwei", "god", 4, true, false, false)

jjjuanjia = sgs.CreateFilterSkill{
    name = "jjjuanjia",
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Armor")) and (place == sgs.Player_PlaceHand)
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local _card = sgs.Sanguosha:getWrappedCard(card:getId())
		_card:takeOver(slash)
		return _card
    end,
}

jjjuanjia_start = sgs.CreateTriggerSkill{
    name = "#jjjuanjia_start",
    events = {sgs.GameStart,sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, "jjjuanjia", true, true)
            player:throwEquipArea(1)
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and table.contains(damage.card:getSkillNames(), "jjjuanjia") and (not damage.chain) then
                local log = sgs.LogMessage()
                log.type = "$jjjuanjia_damage"
                log.from = player
                log.arg = "jjjuanjia"
                log.arg2 = damage.damage
                log.arg3 = damage.damage + 1
                room:sendLog(log)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jjjuanjia_buff = sgs.CreateTargetModSkill{
    name = "#jjjuanjia_buff",
    residue_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "jjjuanjia") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "jjjuanjia") then return 1000 end
        return 0
    end,
}

jjqiexie = sgs.CreateTriggerSkill{
    name = "jjqiexie",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        local skills = player:getTag("jjqiexie_skills"):toString():split("+")
        local n = 3
        if #skills > 0 then
            for _,skill in ipairs(skills) do
                if player:hasSkill(skill) then
                    n = n - 1
                end
            end
            if n <= 0 then return false end
        else
            skills = {}
        end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

        local allnames = sgs.Sanguosha:getLimitedGeneralNames()
        local max = 5
        local count = #allnames
        local choices = {}
        while(max > 0)do
            local index = math.random(1,count)
            local selected = allnames[index]
            allnames[selected] = nil
            selected = sgs.Sanguosha:getGeneral(selected)
            local skill = selected:getVisibleSkillList()
            for _,sk in sgs.qlist(skill) do
                if not player:hasSkill(sk:objectName()) then
                    local translation = sgs.Sanguosha:translate(":"..sk:objectName())
                    if string.find(translation,"【杀】") or string.find(translation,"【火杀】") or string.find(translation,"【雷杀】") or string.find(translation,"【冰杀】") then
                    --or string.find(translation,"[杀]") or string.find(translation,"[火杀]") or string.find(translation,"[雷杀]") or string.find(translation,"[冰杀]") then
                        table.insert(choices,sk:objectName())
                        max = max - 1
                    end
                end
                if max <= 0 then break end
            end
        end
        table.insert(choices, "cancel")

        local new_skills = {}
        local can = math.min(n,2)
        for i = 1, can, 1 do
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), table.concat(new_skills, "+"))
            if choice == "cancel" then break end
            table.insert(new_skills, choice)
            table.removeOne(choices, choice)
        end
        if #new_skills > 0 then
            for _,sk in ipairs(new_skills) do
                room:acquireSkill(player, sk, true)
            end
        end
        for _,skill in ipairs(skills) do
            if player:hasSkill(skill) then
                table.insert(new_skills, skill)
            end
        end
        player:setTag("jjqiexie_skills", sgs.QVariant(table.concat(new_skills,"+")))
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jjcuijue = sgs.CreateZeroCardViewAsSkill
{
    name = "jjcuijue",
    view_as = function(self)
        return jjcuijueCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("jjcuijue-Clear") == 0
    end
}

jjcuijueCard = sgs.CreateSkillCard
{
    name = "jjcuijue",
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:inMyAttackRange(to_select) 
        and to_select:getMark("jjcuijue_"..sgs.Self:objectName().."-Clear") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local skills = effect.from:getVisibleSkillList()
        local choices = {}
        for _,skill in sgs.qlist(skills) do
            if not skill:isAttachedLordSkill() then
                table.insert(choices, skill:objectName())
            end
        end
        local choice = room:askForChoice(effect.from, self:objectName(), table.concat(choices, "+"))
        room:detachSkillFromPlayer(effect.from, choice)
        local translation = sgs.Sanguosha:translate(":"..choice)
        if string.find(translation,"【杀】") or string.find(translation,"【火杀】") 
        or string.find(translation,"【雷杀】") or string.find(translation,"【冰杀】") then
            effect.from:drawCards(2, self:objectName())
        else room:setPlayerMark(effect.from, "jjcuijue-Clear", 1) 
            room:setPlayerMark(effect.from, "&jjcuijue+fail+-Clear", 1)
        end

        room:setPlayerMark(effect.to, "jjcuijue_"..effect.from:objectName().."-Clear", 1)
        room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Normal))
    end
}

jjshendianwei:addSkill(jjjuanjia)
jjshendianwei:addSkill(jjjuanjia_start)
jjshendianwei:addSkill(jjjuanjia_buff)
jjshendianwei:addSkill(jjqiexie)
jjshendianwei:addSkill(jjcuijue)
extension:insertRelatedSkills("jjjuanjia","#jjjuanjia_buff")
extension:insertRelatedSkills("jjjuanjia","#jjjuanjia_start")

ny_liuchen_diy = sgs.General(extension, "ny_liuchen_diy", "shu", 4, true, false, false)

ny_zhanjue_diy = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_zhanjue_diy",
    response_pattern = "@@ny_zhanjue_diy",
    view_as = function(self)
        return ny_zhanjue_diyCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_zhanjue_diy"))
    end
}

ny_zhanjue_diyCard = sgs.CreateSkillCard
{
    name = "ny_zhanjue_diy",
    filter = function(self, targets, to_select, player)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("ny_zhanjue_diy")
        duel:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        duel:deleteLater()
        return duel and duel:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, duel, qtargets)
    end,
    feasible = function(self, targets, player)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("ny_zhanjue_diy")
        duel:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return duel and duel:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = source
        log.arg = self:objectName()
        room:sendLog(log)

        source:throwAllHandCards()
        local n = source:getLostHp()
        n = math.max(1, n)
        if source:isAlive() then source:drawCards(n, self:objectName()) end
        

        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("ny_zhanjue_diy")

        return duel
    end,
}

ny_zhanjue_diy_buff = sgs.CreateTriggerSkill{
    name = "ny_zhanjue_diy",
    events = {sgs.Damaged, sgs.PreCardUsed},
    view_as_skill = ny_zhanjue_diy,
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            if player:isAlive() then
                local n = player:getLostHp()
                n = math.max(1, n)
                if room:askForUseCard(player, "@@ny_zhanjue_diy", "@ny_zhanjue_diy:"..n) then
                    room:addPlayerHistory(player, "#ny_zhanjue_diy", -1)
                end
            end
        end
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and table.contains(use.card:getSkillNames(), "ny_zhanjue_diy") then
                local no_offset_list = use.no_offset_list
                table.insert(no_offset_list, "_ALL_TARGETS")
                use.no_offset_list = no_offset_list
                data:setValue(use)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_qingwang_diy = sgs.CreateTriggerSkill{
    name = "ny_qingwang_diy",
    events = {sgs.CardsMoveOneTime, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if player:getMark("ny_qingwang_diy-Clear") > 0 then return false end 
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                local canselected = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if (not p:isNude()) then
                        canselected:append(p)
                    end
                end
                if canselected:isEmpty() then return false end
                local n = move.card_ids:length()
                local targets = room:askForPlayersChosen(player, canselected,
                self:objectName(), 0, n, "@ny_qingwang_diy:"..n, true, true)
                if targets and (not targets:isEmpty()) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(player, "ny_qingwang_diy-Clear", 1)
                    local tag = sgs.QVariant()
                    tag:setValue(player)
                    room:setTag("ny_qingwang_target", tag)


                    for _,target in sgs.qlist(targets) do
                        if (not target:isNude()) then
                            local get = room:askForExchange(target, self:objectName(), 1, 1, true, "ny_qingwang_diy_give:"..player:objectName(), false)
                            if get and (get:subcardsLength() > 0) then
                                player:obtainCard(get, false)
                                for _,id in sgs.qlist(get:getSubcards()) do
                                    if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                                        room:setPlayerMark(player, "ny_qingwang_diy_slash-Clear", 1)
                                        room:setPlayerMark(player, "&ny_qingwang_diy+-Clear", 1)
                                        room:setPlayerMark(target, "ny_qingwang_diy_slashto_"..player:objectName().."-Clear", 1)
                                        local _player = sgs.SPlayerList()
                                        _player:append(player)
                                        room:addPlayerMark(target, "&ny_qingwang_diy_giveslash-Clear", 1, _player)
                                    end
                                end
                            end
                        end
                        if player:isDead() then return false end
                    end
                end
            end
        end
        if event == sgs.Damage then
            if player:getMark("ny_qingwang_diy_slash-Clear") == 0 then return false end
            local first = true
            if player:isWounded() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
                first = false
            end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                if first then room:broadcastSkillInvoke(self:objectName()) end
                for _,target in sgs.qlist(room:getOtherPlayers(player)) do
                    if target:getMark("ny_qingwang_diy_slashto_"..player:objectName().."-Clear") > 0 and target:isAlive() then
                        target:drawCards(1, self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_liuchen_diy:addSkill(ny_zhanjue_diy_buff)
ny_liuchen_diy:addSkill(ny_zhanjue_diy)
ny_liuchen_diy:addSkill(ny_qingwang_diy)

ny_second_yangyi = sgs.General(extension, "ny_second_yangyi", "shu", 3, true, false, false)

ny_second_dingcuo = sgs.CreateTriggerSkill{
    name = "ny_second_dingcuo",
    events = {sgs.Damage, sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
            room:broadcastSkillInvoke(self:objectName())
            local ids = player:drawCardsList(2, self:objectName())
            local first = sgs.Sanguosha:getCard(ids:first())
            local second = sgs.Sanguosha:getCard(ids:last())
            if not first:sameColorWith(second) then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false)
                room:addPlayerMark(player, "&ny_second_dingcuo-Clear", 1)
                if player:getMark("&ny_second_dingcuo-Clear") >= player:getMaxHp() and player:isAlive() then
                    local log = sgs.LogMessage()
                    log.type = "$ny_second_dingcuo_failed"
                    log.from = player
                    log.arg = self:objectName()
                    room:sendLog(log)

                    room:setPlayerMark(player, "ny_second_dingcuo_failed-Clear", 1)
                    room:setPlayerMark(player, "&ny_second_dingcuo-Clear", 0)

                    if player:getHandcardNum() > player:getMaxHp() then
                        local n = player:getHandcardNum() - player:getMaxHp()
                        room:askForDiscard(player, self:objectName(), n, n, false, false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive() and target:getMark("ny_second_dingcuo_failed-Clear") == 0
    end,
}

ny_second_juanxiaVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_second_juanxia",
    response_pattern = "@@ny_second_juanxia",
    view_as = function(self)
        return ny_second_juanxiaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_second_juanxiaCard = sgs.CreateSkillCard
{
    name = "ny_second_juanxia",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local pattern = player:property("ny_second_juanxia_card"):toString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_second_juanxia")

        if card:targetFixed() then return false end

        card:deleteLater()
        return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets, player)
        local user_string = sgs.Self:property("ny_second_juanxia_card"):toString()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName("ny_second_juanxia")
        use_card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if use_card and use_card:canRecast() and #targets == 0 then
			return false
		end

        return use_card and use_card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local pattern = source:property("ny_second_juanxia_card"):toString()

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())

        return card
    end,
}

ny_second_juanxia = sgs.CreateTriggerSkill{
    name = "ny_second_juanxia",
    events = {sgs.Damage, sgs.EventPhaseStart, sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_second_juanxiaVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            room:addPlayerMark(player, "ny_second_juanxia_damage-Clear", 1)
            room:addPlayerMark(player, "&ny_second_juanxia_damage+-Clear", 1)
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if table.contains(use.card:getSkillNames(), "ny_second_juanxia") and use.from:objectName() == player:objectName() then
                for _,target in sgs.qlist(use.to) do
                    if target:objectName() ~= player:objectName() then
                        room:addPlayerMark(target, "&ny_second_juanxia-SelfClear", 1)
                        room:addPlayerMark(target, "ny_second_juanxia"..player:objectName().."-SelfClear", 1)
                    end
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            local n = 1 + player:getMark("ny_second_juanxia_damage-Clear")
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("use:"..n), false) then
                local all = {}
                local used = {}
                for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isNDTrick() and (not table.contains(all, card:objectName())) then
                        table.insert(all, card:objectName())
                    end
                end

                for i = 1, n, 1 do
                    if player:isDead() then return false end
                    local choices = {}
                    local unable = {}
                    for _,name in ipairs(all) do
                        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
                        card:deleteLater()
                        if card:isAvailable(player) then
                            table.insert(choices, name)
                        else
                            table.insert(unable, name)
                        end
                    end
                    for _,name in ipairs(used) do
                        table.insert(unable, name)
                    end
                    table.insert(choices, "cancel")

                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), table.concat(unable, "+"), nil)
                    if choice == "cancel" then return false end
                    table.insert(used, choice)
                    table.removeOne(all, choice)
                    room:setPlayerProperty(player, "ny_second_juanxia_card", sgs.QVariant(choice))
                    if not room:askForUseCard(player, "@@ny_second_juanxia", "@ny_second_juanxia:"..choice) then return false end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_second_juanxia_slash = sgs.CreateTriggerSkill{
    name = "#ny_second_juanxia_slash",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("&ny_second_juanxia-SelfClear") == 0 then return false end
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:getMark("ny_second_juanxia"..p:objectName().."-SelfClear") > 0 then
                local n = player:getMark("ny_second_juanxia"..p:objectName().."-SelfClear")
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                slash:setSkillName("_ny_second_juanxia")
                slash:deleteLater()

                if not player:isProhibited(p, slash) then
                    local prompt = string.format("slash:%s::%s:", p:getGeneralName(), n)
                    room:setPlayerFlag(p, "ny_second_juanxia_target")
                    if room:askForSkillInvoke(player, "ny_second_juanxia", sgs.QVariant(prompt), false) then
                        for i = 1, n, 1 do
                            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                            slash:setSkillName("_ny_second_juanxia")
                            if not player:isProhibited(p, slash) then
                                room:useCard(sgs.CardUseStruct(slash, player, p))
                                room:getThread():delay(500)
                                if player:isDead() or p:isDead() then break end
                            end
                        end
                    end
                    room:setPlayerFlag(p, "-ny_second_juanxia_target")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Finish
    end,
}

ny_second_yangyi:addSkill(ny_second_dingcuo)
ny_second_yangyi:addSkill(ny_second_juanxia)
ny_second_yangyi:addSkill(ny_second_juanxiaVS)
ny_second_yangyi:addSkill(ny_second_juanxia_slash)
extension:insertRelatedSkills("ny_second_juanxia", "#ny_second_juanxia_slash")

nyarz_lidian_plus = sgs.General(extension, "nyarz_lidian_plus", "wei", 3, true, false, false)

nyarz_wangxi = sgs.CreateTriggerSkill{
    name = "nyarz_wangxi",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local target
        local damage = data:toDamage()
        if event == sgs.Damage then
            if damage.to and damage.to:isAlive() then
                target = damage.to
            end
        end
        if event == sgs.Damaged then
            if damage.from and damage.from:isAlive() then
                target = damage.from
            end
        end
        if target and target:objectName() == player:objectName() then target = nil end
        local prompt
        for i = 1, damage.damage, 1 do
            if target and target:isAlive() then
                room:setPlayerFlag(target, "nyarz_wangxi_target")
                prompt = string.format("give:%s:", target:getGeneralName())
            else
                prompt = "draw"
            end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                if target and target:isAlive() then
                    room:setPlayerFlag(target, "-nyarz_wangxi_target")
                end

                player:drawCards(2, self:objectName())
                if target and target:isAlive() and player:isAlive() then
                    local give = room:askForExchange(player, self:objectName(), 1, 1, true, "@@nyarz_wangxi:"..target:getGeneralName(), false)
                    if give then room:giveCard(player, target, give, self:objectName(), false) end
                end
                if player:isDead() then
                    return false
                end
            else
                return false
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_xunxun = sgs.CreateTriggerSkill{
    name = "nyarz_xunxun",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then else return false end
        if move.reason.m_skillName == self:objectName() then return false end
        local n = 0
        if player:getMark("&nyarz_xunxun") <= 1 then
            n = 1
            room:setPlayerMark(player, "&nyarz_xunxun", 2)
        else
            n = 2
            room:setPlayerMark(player, "&nyarz_xunxun", 1)
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..n)) then
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(n, self:objectName())
            local down = room:askForExchange(player, self:objectName(), 1, 1, true, "@@nyarz_xunxun", false)
            if down then
                room:moveCardsToEndOfDrawpile(player, down:getSubcards(), self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_lidian_plus:addSkill(nyarz_wangxi)
nyarz_lidian_plus:addSkill(nyarz_xunxun)

nyarz_jianggan = sgs.General(extension, "nyarz_jianggan", "wei", 3, true, false, false)

nyarz_daoshu = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_daoshu",
    view_as = function(self)
        return nyarz_daoshuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

nyarz_daoshuCard = sgs.CreateSkillCard
{
    name = "nyarz_daoshu",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and (to_select:objectName() ~= sgs.Self:objectName())
        and (not to_select:isNude()) and (to_select:getMark("couldnt_nyarz_daoshu_from"..sgs.Self:objectName()) == 0)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if (not effect.to:isNude()) then
            local names = effect.to:getMarkNames()
            local mark = nil
            for _,name in ipairs(names) do
                if effect.to:getMark(name) > 0 and name:startsWith("&nyarz_daoshu") then
                    mark = name
                    break
                end
            end

            local card = room:askForCardChosen(effect.from, effect.to, "he", self:objectName())

            if effect.from:getState() == "robot" then
                if mark and string.find(mark, sgs.Sanguosha:getCard(card):getSuitString()) then
                    for _,oc in sgs.qlist(effect.to:getCards("he")) do
                        if string.find(mark, oc:getSuitString()) then 
                        else
                            card = oc:getId()
                            break
                        end
                    end
                end
            end

            room:showCard(effect.to, card)
            local givetos = room:getOtherPlayers(effect.to)
            local prompt = string.format("@@nyarz_daoshu:%s::%s:", sgs.Sanguosha:getCard(card):objectName(),effect.to:getGeneralName())
            local giveto = room:askForPlayerChosen(effect.from, givetos, self:objectName(), prompt, false, false)
            room:obtainCard(giveto, card, true)
            if giveto:objectName() ~= effect.from:objectName() and effect.from:isAlive() then
                effect.from:drawCards(1, self:objectName())
            end

            if effect.from:isDead() or effect.to:isDead() then return false end
            local suit = sgs.Sanguosha:getCard(card):getSuitString()

            if not mark then
                mark = "&nyarz_daoshu+:+"..suit.."_char-PlayClear"
                local only_viewers = sgs.SPlayerList()
                only_viewers:append(effect.from)
                room:setPlayerMark(effect.to, mark, 1, only_viewers)
            else
                if string.find(mark, suit) then
                    room:setPlayerMark(effect.to, "couldnt_nyarz_daoshu_from"..effect.from:objectName(), 1)
                    room:damage(sgs.DamageStruct(self:objectName(), effect.to, effect.from, 1, sgs.DamageStruct_Normal))
                else
                    room:setPlayerMark(effect.to, mark, 0)
                    mark = string.sub(mark,1,-11)
                    mark = mark.."+"..suit.."_char-PlayClear"
                    local only_viewers = sgs.SPlayerList()
                    only_viewers:append(effect.from)
                    room:setPlayerMark(effect.to, mark, 1, only_viewers)
                end
            end
        end
    end
}

nyarz_weicheng = sgs.CreateTriggerSkill{
    name = "nyarz_weicheng",
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.TargetConfirmed, sgs.EventPhaseChanging, sgs.KingdomChanged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.KingdomChanged then 
            for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                if other:getMark("nyarz_weicheng") > 0 then
                    room:removePlayerMark(other, "nyarz_weicheng", 1)
                    room:removePlayerMark(player, "HandcardVisible_"..other:objectName(), 1)
                end
                if other:getKingdom() == player:getKingdom() then
                    room:addPlayerMark(player, "HandcardVisible_"..other:objectName(), 1)
                    room:addPlayerMark(other, "nyarz_weicheng", 1)
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_NotActive then
                if player:getMark("nyarz_weicheng_change") > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:setPlayerMark(player, "nyarz_weicheng_change", 0)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getTag("nyarz_weicheng_oldkingdom"):toString()))

                    local log = sgs.LogMessage()
                    log.type = "#ChooseKingdom"
                    log.from = player
                    log.arg = player:getTag("nyarz_weicheng_oldkingdom"):toString()
                    room:sendLog(log)
                end
                for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                    if other:getKingdom() == player:getKingdom() then
                        room:addPlayerMark(player, "HandcardVisible_"..other:objectName().."-Clear", 1)
                        room:addPlayerMark(other, "nyarz_weicheng-Clear", 1)
                    end
                end
            end
        end
        if event == sgs.EventPhaseStart then
            --[[if player:getPhase() == sgs.RoundStart then
                if player:getMark("nyarz_weicheng_change") > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:setPlayerMark(player, "nyarz_weicheng_change", 0)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getTag("nyarz_weicheng_oldkingdom"):toString()))

                    local log = sgs.LogMessage()
                    log.type = "#ChooseKingdom"
                    log.from = player
                    log.arg = player:getTag("nyarz_weicheng_oldkingdom"):toString()
                    room:sendLog(log)
                end
                for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                    if other:getKingdom() == player:getKingdom() then
                        room:addPlayerMark(player, "HandcardVisible_"..other:objectName().."-Clear", 1)
                        room:addPlayerMark(other, "nyarz_weicheng-Clear", 1)
                    end
                end
            end]]--
            if player:getPhase() == sgs.Player_Start then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("change")) then
                    room:broadcastSkillInvoke(self:objectName())
                    local to = room:askForKingdom(player)

                    local log = sgs.LogMessage()
                    log.type = "#ChooseKingdom"
                    log.from = player
                    log.arg = to
                    room:sendLog(log)

                    player:setTag("nyarz_weicheng_oldkingdom", sgs.QVariant(player:getKingdom()))
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant(to))
                    room:setPlayerMark(player, "nyarz_weicheng_change", 1)

                    --[[for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                        if other:getMark("nyarz_weicheng-Clear") > 0 then
                            room:removePlayerMark(other, "nyarz_weicheng-Clear", 1)
                            room:removePlayerMark(player, "HandcardVisible_"..other:objectName().."-Clear", 1)
                        end
                        if other:getKingdom() == player:getKingdom() then
                            room:addPlayerMark(player, "HandcardVisible_"..other:objectName().."-Clear", 1)
                            room:addPlayerMark(other, "nyarz_weicheng-Clear", 1)
                        end
                    end]]
                end
            end
            --[[if player:getPhase() == sgs.Player_NotActive then
                for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                    if other:getMark("nyarz_weicheng-Clear") > 0 then
                        room:removePlayerMark(other, "nyarz_weicheng-Clear", 1)
                        room:removePlayerMark(player, "HandcardVisible_"..other:objectName().."-Clear", 1)
                    end
                end
            end]]
        end
        if event == sgs.Damage then
            if player:getMark("nyarz_weicheng_change") == 0 then return end
            local damage = data:toDamage()
            if damage.to:getKingdom() == player:getKingdom() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "nyarz_weicheng_change", 0)
                room:setPlayerProperty(player, "kingdom", player:getTag("nyarz_weicheng_oldkingdom"))

                local log = sgs.LogMessage()
                log.type = "#ChooseKingdom"
                log.from = player
                log.arg = player:getTag("nyarz_weicheng_oldkingdom"):toString()
                room:sendLog(log)

                if player:getPhase() == sgs.Player_NotActive then return false end
                --[[for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                    if other:getMark("nyarz_weicheng") > 0 then
                        room:removePlayerMark(other, "nyarz_weicheng", 1)
                        room:removePlayerMark(player, "HandcardVisible_"..other:objectName(), 1)
                    end
                    if other:getKingdom() == player:getKingdom() then
                        room:addPlayerMark(player, "HandcardVisible_"..other:objectName(), 1)
                        room:addPlayerMark(other, "nyarz_weicheng", 1)
                    end
                end]]
            end
        end
        if event == sgs.TargetConfirmed then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            local use = data:toCardUse()
            if use.from:getKingdom() == player:getKingdom()
            and use.to:contains(player) and (not use.card:isKindOf("SkillCard")) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_jianggan:addSkill(nyarz_daoshu)
nyarz_jianggan:addSkill(nyarz_weicheng)

nyarz_liuba = sgs.General(extension, "nyarz_liuba", "shu", 3, true, false, false)

local function findMoveTo(room, move_to)
    for _,target in sgs.qlist(room:getAlivePlayers()) do
        if target:objectName() == move_to:objectName() then
            return target
        end
    end
    return nil
end

nyarz_liuzhuan = sgs.CreateTriggerSkill{
    name = "nyarz_liuzhuan",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if player:getMark("nyarz_liuzhuan_used-Clear") > 0 then return false end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() ~= player:objectName()
        and move.to:getPhase() ~= sgs.Player_Draw 
        and move.to_place == sgs.Player_PlaceHand then
            local target = findMoveTo(room, move.to)
            local prompt = string.format("draw:%s:", target:getGeneralName())
            room:setPlayerFlag(target, "nyarz_liuzhuan_target")
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerFlag(target, "-nyarz_liuzhuan_target")
                room:setPlayerMark(player, "nyarz_liuzhuan_used-Clear", 1)
                room:setPlayerMark(target, "&nyarz_liuzhuan-Clear", 1)
                target:drawCards(2, self:objectName())
            else
                room:setPlayerFlag(target, "-nyarz_liuzhuan_target")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_liuzhuan_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_liuzhuan_buff",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    priority = 20,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.to and move.to:getMark("nyarz_liuzhuan_count-Clear") >= 30 then return false end
        if move.reason.m_skillName == "nyarz_liuzhuan" then return false end
        if move.to and move.to_place == sgs.Player_PlaceHand
        and move.to:getMark("&nyarz_liuzhuan-Clear") > 0 then
            room:broadcastSkillInvoke("nyarz_liuzhuan")

            local target = findMoveTo(room, move.to)
            room:addPlayerMark(target, "nyarz_liuzhuan_count-Clear", 1)

            local log = sgs.LogMessage()
            log.type = "$MoveToDiscardPile_nyarz_liuzhuan"
            log.from = target
            log.arg = "nyarz_liuzhuan"
            log.card_str = table.concat(sgs.QList2Table(move.card_ids), "+")
            room:sendLog(log)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, move.to:objectName(), "nyarz_liuzhuan", "")
            local move = sgs.CardsMoveStruct(move.card_ids, nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhubi = sgs.CreateTriggerSkill{
    name = "nyarz_zhubi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        for _,skiller in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if skiller:isAlive() and skiller:hasSkill(self:objectName()) then
                local discard = room:askForExchange(skiller, self:objectName(), 1, 1, true, "@@nyarz_zhubi", true)
                if discard then
                    room:broadcastSkillInvoke(self:objectName())

                    local log = sgs.LogMessage()
                    log.type = "$nyarz_zhubi_recast"
                    log.from = skiller
                    log.arg = self:objectName()
                    log.card_str = table.concat(sgs.QList2Table(discard:getSubcards()), "+")
                    room:sendLog(log)

                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, skiller:objectName(), self:objectName(), "")
                    room:moveCardTo(discard, nil, nil, sgs.Player_DiscardPile, reason)

                    skiller:drawCards(discard:subcardsLength(), "recast")
                    for _,id in sgs.qlist(discard:getSubcards()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isBlack() then
                            skiller:drawCards(1, self:objectName())
                        elseif card:isRed() then
                            if room:askForSkillInvoke(skiller, self:objectName(), sgs.QVariant("put"), false) then
                                room:broadcastSkillInvoke(self:objectName())

                                local find = false
                                local n = 0
                                local ex_nihilo
                                for _,iid in sgs.qlist(room:getDrawPile()) do
                                    local cc = sgs.Sanguosha:getCard(iid)
                                    if cc:objectName() == "ex_nihilo" then
                                        find = true
                                        ex_nihilo = cc
                                        break
                                    end
                                    n = n + 1;
                                end
                                if find then
                                    local tem1 = room:getNCards(n, false)
                                    local tem2 = room:getNCards(1, false)
                                    room:returnToTopDrawPile(tem1)
                                    room:returnToTopDrawPile(tem2)
                                    local llog = sgs.LogMessage()
                                    llog.type = "$nyarz_zhubi_put"
                                    llog.from = skiller
                                    llog.arg = self:objectName()
                                    llog.card_str = ex_nihilo:toString()
                                    room:sendLog(llog)
                                else
                                    for _,iid in sgs.qlist(room:getDiscardPile()) do
                                        local cc = sgs.Sanguosha:getCard(iid)
                                        if cc:objectName() == "ex_nihilo" then
                                            local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, skiller:objectName(), self:objectName(), "")
                                            local move2 = sgs.CardsMoveStruct(iid, nil, sgs.Player_DrawPile, reason2)
                                            room:moveCardsAtomic(move2, true)

                                            local llog = sgs.LogMessage()
                                            llog.type = "$nyarz_zhubi_put"
                                            llog.from = skiller
                                            llog.arg = self:objectName()
                                            llog.card_str = cc:toString()
                                            room:sendLog(llog)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
        
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_liuba:addSkill(nyarz_liuzhuan)
nyarz_liuba:addSkill(nyarz_liuzhuan_buff)
nyarz_liuba:addSkill(nyarz_zhubi)
extension:insertRelatedSkills("nyarz_liuzhuan", "#nyarz_liuzhuan_buff")

nyarz_xusheng = sgs.General(extension, "nyarz_xusheng", "wu", 4, true, false, false)

nyarz_pojunVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_pojun",
    response_pattern = "@@nyarz_pojun",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

nyarz_pojun = sgs.CreateTriggerSkill{
    name = "nyarz_pojun",
    events = {sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_pojunVS,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            room:askForUseCard(player, "@@nyarz_pojun", "@nyarz_pojun", -1, sgs.Card_MethodUse, false, nil, nil, nil)
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then else return false end

            for _,target in sgs.qlist(use.to) do
                if not target:isNude() then
                    room:setPlayerFlag(target, "nyarz_pojun_target")
                    local max = math.min(target:getMaxHp(), target:getCards("he"):length())
                    local prompt = string.format("put:%s::%s:", target:getGeneralName(), max)
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerFlag(target, "-nyarz_pojun_target")
                        
                        --[[local choices = {}
                        for i = 1, max, 1 do
                            table.insert(choices, tostring(i))
                        end
                        local num = tonumber(room:askForChoice(player, self:objectName(), table.concat(choices, "+")))]]
                        local remove = sgs.IntList()

                        for i = 1, max do--进行多次执行
                            local id = room:askForCardChosen(player, target, "he", self:objectName(),
                                false,--选择卡牌时手牌不可见
                                sgs.Card_MethodDiscard,--设置为弃置类型
                                remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
                                i>1)--只有执行过一次选择才可取消
                            if id < 0 then break end--如果卡牌id无效就结束多次执行
                            remove:append(id)--将选择的id添加到虚拟卡的子卡表
                        end

                        local views = sgs.SPlayerList()
                        views:append(target)
                        target:addToPile("nyarz_pojun", remove, false, views)
                    else
                        room:setPlayerFlag(target, "-nyarz_pojun_target")
                    end
                end
            end
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:isDead() then return false end
            if damage.to:getPile("nyarz_pojun") and damage.to:getPile("nyarz_pojun"):length() > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, false)

                local disnum = math.ceil(damage.to:getPile("nyarz_pojun"):length()/2)
                local dis = sgs.IntList()
                for _,id in sgs.qlist(damage.to:getPile("nyarz_pojun")) do
                    dis:append(id)
                    disnum = disnum - 1
                    if disnum <= 0 then break end
                end

                --[[local log = sgs.LogMessage()
                log.type = "$MoveToDiscardPile"
                log.from = player
                log.card_str = table.concat(sgs.QList2Table(dis), "+")
                room:sendLog(log)

                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                local move2 = sgs.CardsMoveStruct(dis, nil, sgs.Player_DiscardPile, reason2)
                room:moveCardsAtomic(move2, true)]]--

                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), "nyarz_pojun", "")
                local move2 = sgs.CardsMoveStruct(dis, player, sgs.Player_PlaceHand, reason2)
                room:moveCardsAtomic(move2, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_pojun_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_pojun_buff",
    residue_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "nyarz_pojun") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "nyarz_pojun") then return 1000 end
        return 0
    end,
}

nyarz_pojun_return = sgs.CreateTriggerSkill{
    name = "#nyarz_pojun_return",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_NotActive then return false end
        for _,target in sgs.qlist(room:getAlivePlayers()) do
            if target:isAlive() and target:getPile("nyarz_pojun") and target:getPile("nyarz_pojun"):length() > 0 then
                --[[local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, target:objectName(), "nyarz_pojun", "")
                local move2 = sgs.CardsMoveStruct(target:getPile("nyarz_pojun"), target, sgs.Player_PlaceHand, reason2)
                room:moveCardsAtomic(move2, true)]]--
                local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                obtain:addSubcards(target:getPile("nyarz_pojun"))
                room:obtainCard(target, obtain, false)
                obtain:deleteLater()
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_xusheng:addSkill(nyarz_pojun)
nyarz_xusheng:addSkill(nyarz_pojunVS)
nyarz_xusheng:addSkill(nyarz_pojun_buff)
nyarz_xusheng:addSkill(nyarz_pojun_return)
extension:insertRelatedSkills("nyarz_pojun", "#nyarz_pojun_buff")
extension:insertRelatedSkills("nyarz_pojun", "#nyarz_pojun_return")

nyarz_liru = sgs.General(extension, "nyarz_liru", "qun", 3, true, false, false)

nyarz_juece = sgs.CreateTriggerSkill{
    name = "nyarz_juece",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if player:getMark("nyarz_juece-Clear") > 0 then return false end
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() ~= player:objectName() 
        and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive
        and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then else return false end
        local empty = false
        if move.from:isKongcheng() then empty = true end
        local target = findMoveTo(room, move.from)
        room:setPlayerFlag(target, "nyarz_juece_target")
        local prompt = "damageto:"..move.from:getGeneralName()
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerFlag(target, "-nyarz_juece_target")
            local damageNum = 1
            if not empty then room:setPlayerMark(player, "nyarz_juece-Clear", 1) room:setPlayerMark(player, "&nyarz_juece+-Clear", 1) end
            if empty then
                local _data = sgs.QVariant()
                _data:setValue(target)
                local choice = room:askForChoice(player, self:objectName(), "damage+draw+cancel", _data)
                if choice == "damage" then damageNum = 2 
                elseif choice == "draw" then player:drawCards(2, self:objectName()) end
            end
            room:damage(sgs.DamageStruct(self:objectName(), player, target, damageNum, sgs.DamageStruct_Normal))
            if player:isAlive() and player:getPhase() == sgs.Player_NotActive then
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            end
        end
        room:setPlayerFlag(target, "-nyarz_juece_target")
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_mieji = sgs.CreateViewAsSkill
{
    name = "nyarz_mieji",
    n = 999,
    view_filter = function(self, selected, to_select)
        return to_select:isNDTrick()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cc = nyarz_miejiCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#nyarz_mieji")
    end
}

nyarz_miejiCard = sgs.CreateSkillCard
{
    name = "nyarz_mieji",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and (not to_select:isNude()) and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showCard(effect.from, self:getSubcards())
        for _,id in sgs.qlist(self:getSubcards()) do
            room:setCardFlag(id, "nyarz_mieji")
            room:setCardTip(id, "nyarz_mieji")
        end
        local dis = cardsChosen(room, effect.from, effect.to, "nyarz_mieji", "he", self:subcardsLength())
        room:setPlayerMark(effect.to, "&nyarz_mieji-PlayClear", 1)
        room:throwCard(dis, self:objectName(), effect.to, effect.from)
    end
}

nyarz_mieji_limit = sgs.CreateProhibitSkill{
    name = "#nyarz_mieji_limit",
    is_prohibited = function(self, from, to, card)
        return card:hasFlag("nyarz_mieji") and from:objectName() ~= to:objectName() and to:getMark("&nyarz_mieji-PlayClear") == 0
    end,
}

nyarz_mieji_throw = sgs.CreateTriggerSkill{
    name = "#nyarz_mieji_throw",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Play then return false end
        local dis = sgs.IntList()
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("nyarz_mieji") then
                dis:append(card:getId())
            end
        end
        if dis:isEmpty() then return false end
        room:sendCompulsoryTriggerLog(player, "nyarz_mieji", true)
        local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), "nyarz_mieji", "")
        local move2 = sgs.CardsMoveStruct(dis, nil, sgs.Player_DiscardPile, reason2)
        room:moveCardsAtomic(move2, true)
        local log = sgs.LogMessage()
        log.type = "$DiscardCard"
        log.from = player
        log.card_str = table.concat(sgs.QList2Table(dis), "+")
        room:sendLog(log)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_fencheng = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_fencheng",
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_fencheng_mark",
    view_as = function(self)
        return nyarz_fenchengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@nyarz_fencheng_mark") > 0
    end
}

nyarz_fenchengCard = sgs.CreateSkillCard
{
    name = "nyarz_fencheng",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:setPlayerMark(source, "@nyarz_fencheng_mark", 0)
        
        room:setPlayerMark(source, "nyarz_fencheng_finish", 1)
        local nextp = source:getNextAlive(1)
        while(nextp:getMark("nyarz_fencheng_finish") == 0) do
            room:setPlayerMark(nextp, "nyarz_fencheng_finish", 1)
            room:damage(sgs.DamageStruct(self:objectName(), source, nextp, 1, sgs.DamageStruct_Fire))
            nextp = nextp:getNextAlive(1)
            room:getThread():delay(300)
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "nyarz_fencheng_finish", 0)
        end

        room:setPlayerMark(source, "nyarz_fencheng_finish", 1)
        local nextp = source:getNextAlive(1)
        while(nextp:getMark("nyarz_fencheng_finish") == 0) do
            room:setPlayerMark(nextp, "nyarz_fencheng_finish", 1)
            
            if not nextp:getEquips():isEmpty() then
                local dis = sgs.IntList()
                for _,equip in sgs.qlist(nextp:getEquipsId()) do
                    dis:append(equip)
                end
                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName(), "nyarz_fencheng", "")
                local move2 = sgs.CardsMoveStruct(dis, nil, sgs.Player_DiscardPile, reason2)
                room:moveCardsAtomic(move2, true)
                local log = sgs.LogMessage()
                log.type = "$DiscardCard"
                log.from = nextp
                log.card_str = table.concat(sgs.QList2Table(dis), "+")
                room:sendLog(log)
                room:getThread():delay(300)
            end
            nextp = nextp:getNextAlive(1)
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "nyarz_fencheng_finish", 0)
        end
    end
}

nyarz_liru:addSkill(nyarz_juece)
nyarz_liru:addSkill(nyarz_mieji)
nyarz_liru:addSkill(nyarz_mieji_limit)
nyarz_liru:addSkill(nyarz_mieji_throw)
nyarz_liru:addSkill(nyarz_fencheng)
extension:insertRelatedSkills("nyarz_mieji","#nyarz_mieji_limit")
extension:insertRelatedSkills("nyarz_mieji","#nyarz_mieji_throw")

nyarz_luxun_wu = sgs.General(extension, "nyarz_luxun_wu", "wu", 3, true, false, false)

nyarz_xiongmu_wu = sgs.CreateTriggerSkill{
    name = "nyarz_xiongmu_wu",
    events = {sgs.DamageInflicted,sgs.StartJudge},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getHandcardNum() > player:getMaxHp() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local count = 0
            if damage.to:objectName() == player:objectName() then
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:getNumber() == 8 then
                        count = count + 1
                        if count == 1 then
                            room:obtainCard(player, card, false)
                            local log = CreateDamageLog(damage, damage.damage, self:objectName(), false)
                            room:sendLog(log)
                        end
                    end
                end
            end
            local log = sgs.LogMessage()
            log.type = "$nyarz_xiongmu_wu_last"
            log.arg = math.max(1,count - 1)
            room:sendLog(log, player)
            if count > 0 then return true end
        end

        if event == sgs.StartJudge then
            local judge = data:toJudge()
            if judge.who:objectName() ~= player:objectName() then return false end
            local needmatch 
            if judge.good then needmatch = true
            else needmatch = false end
            local find = false
            local n = 0
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if needmatch and (sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                    find = true
                    break
                elseif (not needmatch) and (not sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                    find = true
                    break
                end
                n = n + 1;
            end
            if find then
                local tem1 = room:getNCards(n, false)
                local tem2 = room:getNCards(1, false)
                room:returnToTopDrawPile(tem1)
                room:returnToTopDrawPile(tem2)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhangcai_wu = sgs.CreateTriggerSkill{
    name = "nyarz_zhangcai_wu",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.CardFinished,sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.GameStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            if player:isDead() then return false end
            if player:getMark("nyarz_zhangcai_wu-Clear") > 0 then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.from:objectName() == player:objectName()
            and use.card:getNumber() > 0 then
                local num = 0
                local shuffle = sgs.IntList()
                for _,id in sgs.qlist(room:getDiscardPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:getNumber() == use.card:getNumber() then
                        num = num + 1
                        shuffle:append(id)
                    end
                end

                local prompt = string.format("shuffle:%s::%s:", use.card:getNumber(), num)
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(player, "nyarz_zhangcai_wu-Clear", 1)
                    room:setPlayerMark(player, "&nyarz_zhangcai_wu+-Clear", 1)
                    room:addPlayerMark(player, "nyarz_zhangcai_wu_num"..use.card:getNumber(), 1)
                    if num > 0 then
                        local log = sgs.LogMessage()
                        log.type = "$ShuffleCard"
                        log.from = player
                        log.card_str = table.concat(sgs.QList2Table(shuffle), "+")
                        room:sendLog(log)

                        room:shuffleIntoDrawPile(player, shuffle, self:objectName(), true)
                        player:drawCards(num, self:objectName())
                    end
                end
            end
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:isDead() then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card) or card:isKindOf("SkillCard") then return false end
            local draw = player:getMark("&nyarz_ruxian_wu") + player:getMark("nyarz_zhangcai_wu_num"..card:getNumber())
            if draw <= 0 then return false end
            local prompt = string.format("draw:%s:", draw)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(draw, self:objectName())
            end
        end
        if event == sgs.GameStart then
            room:attachSkillToPlayer(player, "nyarz_zhangcai_wu_show")
        end
        if event == sgs.EventAcquireSkill then
            if data:toString() ~= self:objectName() then return false end
            room:attachSkillToPlayer(player, "nyarz_zhangcai_wu_show")
        end
        if event == sgs.EventLoseSkill then
            if data:toString() ~= self:objectName() then return false end
            room:detachSkillFromPlayer(player, "nyarz_zhangcai_wu_show", false, false, false)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_ruxian_wu = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_ruxian_wu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_ruxian_wu_mark",
    view_as = function(self)
        return nyarz_ruxian_wuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@nyarz_ruxian_wu_mark") > 0
    end
}

nyarz_ruxian_wuCard = sgs.CreateSkillCard
{
    name = "nyarz_ruxian_wu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "@nyarz_ruxian_wu_mark", 0)
        room:setPlayerMark(source, "&nyarz_ruxian_wu", 1)
        room:setPlayerMark(source, "nyarz_ruxian_wu_discard-Clear", 1)
    end
}

nyarz_ruxian_wu_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_ruxian_wu_buff",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_NotActive then
                room:setPlayerMark(player, "&nyarz_ruxian_wu", 0)
            end
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("nyarz_ruxian_wu") then
                        room:ignoreCards(player, card)
                    end
                end
            end
        end

        if event == sgs.CardsMoveOneTime then
            if player:getMark("nyarz_ruxian_wu_discard-Clear") == 0
            or player:getPhase() ~= sgs.Player_Discard then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                room:addPlayerMark(player, "nyarz_ruxian_wu_get-Clear", move.card_ids:length())
            end
        end

        if event == sgs.EventPhaseEnd then
            if player:isDead() then return false end
            if player:getPhase() ~= sgs.Player_Discard
            or player:getMark("nyarz_ruxian_wu_discard-Clear") == 0
            or player:getMark("nyarz_ruxian_wu_get-Clear") == 0 then return false end
            local n = player:getMark("nyarz_ruxian_wu_get-Clear")
            room:setPlayerMark(player, "nyarz_ruxian_wu_get-Clear", 0)

            local nums = {}
            for _,card in sgs.qlist(player:getHandcards()) do
                if (not table.contains(nums, card:getNumber())) then
                    table.insert(nums, card:getNumber())
                end
            end

            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if (not table.contains(nums, card:getNumber())) then
                    table.insert(nums, card:getNumber())
                    get:addSubcard(card)
                    n = n - 1
                end
                if n <= 0 then break end
            end
            if get:getSubcards():isEmpty() then
                get:deleteLater()
                return false 
            end
            room:sendCompulsoryTriggerLog(player, "nyarz_ruxian_wu", true, true)
            room:obtainCard(player, get, false)
            for _,id in sgs.qlist(get:getSubcards()) do
                if room:getCardOwner(id):objectName() == player:objectName() then
                    room:setCardFlag(sgs.Sanguosha:getCard(id), "nyarz_ruxian_wu")
                    room:setCardTip(id, "nyarz_ruxian_wu")
                end
            end
            get:deleteLater()
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhangcai_wu_show = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_zhangcai_wu_show&",
    view_as = function(self)
        return nyarz_zhangcai_wu_showCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasSkill("nyarz_zhangcai_wu")
    end
}

nyarz_zhangcai_wu_showCard = sgs.CreateSkillCard
{
    name = "nyarz_zhangcai_wu_show",
    target_fixed = true,
    about_to_use = function(self,room,use)
        local source = use.from
        local choices = {}
        for i = 1, 13, 1 do
            local num = string.format("show=%s=%s",i,source:getMark("nyarz_zhangcai_wu_num"..i))
            table.insert(choices, num)
        end
        local choice = room:askForChoice(source, "nyarz_zhangcai_wu", table.concat(choices, "+"))
    end,
    --[[on_use = function(self, room, source, targets)
        local choices = {}
        for i = 1, 13, 1 do
            local num = string.format("show=%s=%s",i,source:getMark("nyarz_zhangcai_wu_num"..i))
            table.insert(choices, num)
        end
        local choice = room:askForChoice(source, "nyarz_zhangcai_wu", table.concat(choices, "+"))
    end]]
}

nyarz_luxun_wu:addSkill(nyarz_xiongmu_wu)
nyarz_luxun_wu:addSkill(nyarz_zhangcai_wu)
--nyarz_luxun_wu:addSkill(nyarz_zhangcai_wu_show)
nyarz_luxun_wu:addSkill(nyarz_ruxian_wu)
nyarz_luxun_wu:addSkill(nyarz_ruxian_wu_buff)
--extension:insertRelatedSkills("nyarz_zhangcai_wu", "nyarz_zhangcai_wu_show&")
extension:insertRelatedSkills("nyarz_ruxian_wu", "#nyarz_ruxian_wu_buff")

nyarz_lingtong = sgs.General(extension, "nyarz_lingtong", "wu", 4, true, false, false)

local function nyarz_xuanfeng_real(self, event, player, data)
    local room = player:getRoom()
    if player:isDead() then return end
    local targets = sgs.SPlayerList()
    for i = 1, 2, 1 do
        local prompt
        if i == 1 then prompt = "@nyarz_xuanfeng"
        else prompt = "nyarz_xuanfeng_discard" end

        local ctargets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if (not p:isNude()) then
                ctargets:append(p)
            end
        end

        if ctargets:isEmpty() then break end

        local target = room:askForPlayerChosen(player, ctargets, self:objectName(), prompt, true, true)
        if target then
            if i == 1 then room:broadcastSkillInvoke(self:objectName()) end
            if (not targets:contains(target)) then targets:append(target) end

            local card = room:askForCardChosen(player, target, "he", self:objectName())
            room:throwCard(card, target, player)
        else
            break
        end
        if player:isDead() then return end
    end
    if targets:isEmpty() then return end
    if player:isDead() then return end
    if player:getPhase() ~= sgs.Player_NotActive then
        local ntargets = sgs.SPlayerList()
        for _,target in sgs.qlist(targets) do
            if target:isAlive() then ntargets:append(target) end
        end
        if ntargets:isEmpty() then return end
        local target = room:askForPlayerChosen(player, ntargets, "nyarz_xuanfeng_damageto", "nyarz_xuanfeng_damage", true, true)
        if target then 
            room:broadcastSkillInvoke(self:objectName())
            room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal)) 
        end
    end
end

nyarz_xuanfeng = sgs.CreateTriggerSkill{
    name = "nyarz_xuanfeng",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName()
        and ((move.from_places:contains(sgs.Player_PlaceHand)) or (move.from_places:contains(sgs.Player_PlaceEquip))) then
            if move.card_ids:length() >= 2 then nyarz_xuanfeng_real(self, event, player, data) end
            for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					nyarz_xuanfeng_real(self, event, player, data)
				end
			end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_yongjin = sgs.CreateViewAsSkill
{
    name = "nyarz_yongjin",
    n = 99,
    tiansuan_type = "recast,move,all",
    view_filter = function(self, selected,to_select)
        local choice = sgs.Self:getTag("nyarz_yongjin"):toString()
        if string.find(choice, "move") then return false end
        return #selected < 2
    end,
    view_as = function(self, cards)
        local card = nyarz_yongjinCard:clone()
        local choice = sgs.Self:getTag("nyarz_yongjin"):toString()
        card:setUserString(choice)
        if string.find(choice, "move") then
            if #cards == 0 then return card end
        else
            if #cards > 0 then
                for _,cc in ipairs(cards) do
                    card:addSubcard(cc)
                end
                return card
            end
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#nyarz_yongjin"))
    end
}

nyarz_yongjinCard = sgs.CreateSkillCard
{
    name = "nyarz_yongjin",
    target_fixed = true,
    will_throw = false,
    feasible = function(self, targets, player)
        local choice = self:getUserString()
        if string.find(choice, "recast") then return true end
        local room = sgs.Sanguosha:currentRoom()
        return room:canMoveField("ej")
    end,
    on_use = function(self, room, source, targets)
        local choice = self:getUserString()
        if string.find(choice, "recast") or string.find(choice,"all")
        and self:subcardsLength() > 0 then
            local log = sgs.LogMessage()
            log.from = source
            log.type = "$RecastCard"
            log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log)
    
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), "")
            room:moveCardTo(self, nil, nil, sgs.Player_DiscardPile, reason)
            if source:isDead() then return false end
            source:drawCards(self:subcardsLength(), "recast")
        end

        if source:isDead() then return false end
        if room:canMoveField("ej") 
        and (string.find(choice, "move") or string.find(choice,"all")) then
            room:moveField(source, self:objectName(), true, "ej")
        end

        if source:isDead() then return false end
        if string.find(choice,"all") then
            room:loseHp(source, 1, true, source, self:objectName())
            if source:isDead() then return false end
            source:drawCards(1, self:objectName())
        end
    end
}

nyarz_lingtong:addSkill(nyarz_xuanfeng)
nyarz_lingtong:addSkill(nyarz_yongjin)

nyarz_zuoci = sgs.General(extension, "nyarz_zuoci", "qun", 3, true, false, false)

local function nyarz_huashen_get(player,num)
    local room = player:getRoom()
    local allnames = sgs.Sanguosha:getLimitedGeneralNames()
    local allplayers = room:getAlivePlayers()
    for _,p in sgs.qlist(allplayers) do
        local name = p:getGeneralName()
        allnames[name] = nil
    end

    local souls = player:getTag("nyarz_souls"):toString():split("+")
    if (not souls) or (#souls <= 0) then souls = {} end
    if (#souls > 0) then
        for _,soul in ipairs(souls) do
            allnames[soul] = nil
        end
    end

    for i=1, num, 1 do
        local index = math.random(1,#allnames)
        local selected = allnames[index]

        local log = sgs.LogMessage()
        log.type = "$nyarz_huashen_new"
        log.from = player
        log.arg = selected
        room:sendLog(log)

        table.insert(souls, selected)
        allnames[selected] = nil
    end
    room:setPlayerMark(player, "&nyarz_souls", #souls)
    player:setTag("nyarz_souls", sgs.QVariant(table.concat(souls, "+")))
end

nyarz_huashen = sgs.CreateTriggerSkill{
    name = "nyarz_huashen",
    events = {sgs.GameStart,sgs.Damaged,sgs.RoundStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.GameStart then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                nyarz_huashen_get(player,2)
            end
        end

        --[[if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                nyarz_huashen_get(player,2)
            end
        end]]

        if event == sgs.Damaged then
            local damage = data:toDamage()
            for i = 1, damage.damage, 1 do
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    nyarz_huashen_get(player,2)
                end
            end
        end

        if event == sgs.RoundStart then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                nyarz_huashen_get(player,2)
            end
            local souls = player:getTag("nyarz_souls"):toString():split("+")
            if (not souls) or (#souls <= 0) then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("change")) then
                room:broadcastSkillInvoke(self:objectName())
                
                local skill = {}
                local cant = {}
                local get = {}
                local max = math.min(2, #souls)
                for i = 1, max, 1 do
                    local general = room:askForGeneral(player, table.concat(souls, "+"))
                    local hero = sgs.Sanguosha:getGeneral(general)
                    local skills = hero:getVisibleSkillList()
                    for _,p in sgs.qlist(skills) do
                        if (not player:hasSkill(p:objectName())) and (not table.contains(skill, p:objectName())) then
                            table.insert(skill, p:objectName())
                        elseif player:hasSkill(p:objectName()) then
                            table.insert(cant, p:objectName())
                        end
                    end

                    if i == 2 then table.insert(skill, "giveup") end
                    local choice = room:askForChoice(player, self:objectName(), table.concat(skill, "+"), data, table.concat(cant,"+"))
                    if i == 2 and choice == "giveup" then break end

                    local log = sgs.LogMessage()
                    log.type = "$nyarz_huashen_lose"
                    log.from = player
                    log.arg = general
                    room:sendLog(log)

                    room:getThread():trigger(sgs.EventForDiy, room, player, sgs.QVariant("losesouls+"..hero:getKingdom()))
                    room:acquireSkill(player, choice)
                    table.insert(get, choice)
                    table.removeOne(skill, choice)
                    table.removeOne(souls, general)
                end

                room:setPlayerMark(player, "&nyarz_souls", #souls)
                player:setTag("nyarz_souls", sgs.QVariant(table.concat(souls, "+")))
                player:setTag("nyarz_huashen", sgs.QVariant(table.concat(get, "+")))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_huashen_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_huashen_buff",
    events = {sgs.RoundEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local skills = player:getTag("nyarz_huashen"):toString():split("+")
        if (not skills) or (#skills <= 0) then return false end
        player:removeTag("nyarz_huashen")

        room:sendCompulsoryTriggerLog(player, "nyarz_huashen", true)
        for _,skill in ipairs(skills) do
            if player:hasSkill(skill) then
                room:detachSkillFromPlayer(player, skill)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_xinshengVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_xinsheng",
    view_as = function(self)
        return nyarz_xinshengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#nyarz_xinsheng")) and player:getMark("&nyarz_souls") > 0
    end
}

nyarz_xinshengCard = sgs.CreateSkillCard
{
    name = "nyarz_xinsheng",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local souls = source:getTag("nyarz_souls"):toString():split("+")
        local general = room:askForGeneral(source, table.concat(souls, "+"))
        local hero = sgs.Sanguosha:getGeneral(general)
        local num = math.ceil(hero:getMaxHp()/2)
        source:drawCards(num, self:objectName())

        local audio = "audio/death/"..general..".ogg"
        sgs.Sanguosha:playAudioEffect(audio)
        room:getThread():delay(500)

        local log = sgs.LogMessage()
        log.type = "$nyarz_huashen_lose"
        log.from = source
        log.arg = general
        room:sendLog(log)

        room:getThread():trigger(sgs.EventForDiy, room, source, sgs.QVariant("losesouls+"..hero:getKingdom()))
        table.removeOne(souls, general)
        room:setPlayerMark(source, "&nyarz_souls", #souls)
        source:setTag("nyarz_souls", sgs.QVariant(table.concat(souls, "+")))
    end
}

nyarz_xinsheng = sgs.CreateTriggerSkill{
    name = "nyarz_xinsheng",
    events = {sgs.Damage,sgs.EventForDiy},
    view_as_skill = nyarz_xinshengVS,
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:objectName() == player:objectName() then return false end
            local souls = player:getTag("nyarz_souls"):toString():split("+")
            if (not souls) or (#souls <= 0) then souls = {} end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            if table.contains(souls, damage.to:getGeneralName()) then 
                nyarz_huashen_get(player,1)
                return false
            end

            local log = sgs.LogMessage()
            log.type = "$nyarz_huashen_new"
            log.from = player
            log.arg = damage.to:getGeneralName()
            room:sendLog(log)

            table.insert(souls, damage.to:getGeneralName())
            player:setTag("nyarz_souls", sgs.QVariant(table.concat(souls, "+")))
            room:setPlayerMark(player, "&nyarz_souls", #souls)
        end
        if event == sgs.EventForDiy then
            local str = data:toString()
            if not string.find(str, "losesouls") then return false end
            local kingdom = str:split("+")[2]
            local targets = sgs.SPlayerList()
            for _,target in sgs.qlist(room:getAlivePlayers()) do
                if target:getKingdom() == kingdom and target:isWounded() then
                    targets:append(target)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@nyarz_xinsheng:"..kingdom, true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:recover(target, sgs.RecoverStruct(player, nil, 1))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zuoci:addSkill(nyarz_huashen)
nyarz_zuoci:addSkill(nyarz_huashen_buff)
nyarz_zuoci:addSkill(nyarz_xinsheng)
nyarz_zuoci:addSkill(nyarz_xinshengVS)
extension:insertRelatedSkills("nyarz_huashen", "#nyarz_huashen_buff")

nyarz_sunyi = sgs.General(extension, "nyarz_sunyi", "wu", 5, true, false, false)

nyarz_jiqiao = sgs.CreateTriggerSkill{
    name = "nyarz_jiqiao",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or card:isKindOf("SkillCard") then return false end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(2, self:objectName())
            local recast = room:askForExchange(player, self:objectName(), 1, 1, false, "@nyarz_jiqiao", true)
            if recast then
                local log = sgs.LogMessage()
                log.from = player
                log.type = "$RecastCard"
                log.card_str = table.concat(sgs.QList2Table(recast:getSubcards()), "+")
                room:sendLog(log)
    
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                room:moveCardTo(recast, nil, nil, sgs.Player_DiscardPile, reason)
                if player:isDead() then return false end
                player:drawCards(recast:subcardsLength(), "recast")
            end
            if player:isDead() then return false end
            local colors = {}
            for _,cc in sgs.qlist(player:getHandcards()) do
                local color = cc:getColorString()
                if (not table.contains(colors, color)) then
                    table.insert(colors, color)
                end
            end
            if #colors <= 1 and player:isWounded() then
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
            elseif #colors > 1 then
                room:loseHp(player, 1, true, player, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_sunyi:addSkill(nyarz_jiqiao)

nyarz_liubei = sgs.General(extension, "nyarz_liubei$", "shu", 4, true, false, false)

nyarz_rende = sgs.CreateViewAsSkill
{
    name = "nyarz_rende",
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards >= 2 then
            local card = nyarz_rendeCard:clone()
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

nyarz_rendeCard = sgs.CreateSkillCard
{
    name = "nyarz_rende",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
        and to_select:getMark("nyarz_rende_give-PlayClear") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "nyarz_rende_give-PlayClear", 1)
        room:addPlayerMark(effect.from, "nyarz_rende_draw-Clear", 1)
        room:addPlayerMark(effect.from, "&nyarz_rende", 1)
        room:obtainCard(effect.to, self, false)
        room:addPlayerMark(effect.from, "&nyarz_rende+3_num+-Clear", 1)
    end,
}

nyarz_rende_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_rende_buff",
    events = {sgs.EventPhaseStart,sgs.GameStart,sgs.EventAcquireSkill,sgs.EventLoseSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            for _,p in sgs.qlist(room:findPlayersBySkillName("nyarz_rende")) do
                if p:isAlive() and p:getMark("nyarz_rende_draw-Clear") > 0
                and p:getMark("nyarz_rende_used3_lun") < 4 then
                    local prompt = string.format("draw:%s:", p:getMark("nyarz_rende_draw-Clear") + 1)
                    if room:askForSkillInvoke(p, "nyarz_rende", sgs.QVariant(prompt)) then
                        room:broadcastSkillInvoke("nyarz_rende")
                        room:addPlayerMark(p, "nyarz_rende_used3_lun", 1)
                        room:addPlayerMark(p, "nyarz_rende_used4-Clear", 1)
                        p:drawCards(p:getMark("nyarz_rende_draw-Clear") + 1, "nyarz_rende")
                    end
                end
            end
            if player:hasSkill("nyarz_rende") and player:getMark("nyarz_rende_used4-Clear") == 0
            and player:isAlive() then
                room:sendCompulsoryTriggerLog(player, "nyarz_rende", true, true)
                room:addPlayerMark(player, "&nyarz_rende", 1)
            end
        end
        if event == sgs.GameStart then
            if player:hasSkill("nyarz_rende")  then
                if player:getMark("&nyarz_rende") == 0 then
                    room:addPlayerMark(player, "&nyarz_rende", 1)
                end
                if not player:hasSkill("nyarz_rendebasic") then
                    room:attachSkillToPlayer(player, "nyarz_rendebasic")
                end
            end
        end
        if event == sgs.EventAcquireSkill then
            if data:toString() == "nyarz_rende" then
                if not player:hasSkill("nyarz_rendebasic") then
                    room:attachSkillToPlayer(player, "nyarz_rendebasic")
                end
                if player:getMark("&nyarz_rende") == 0 then
                    room:addPlayerMark(player, "&nyarz_rende", 1)
                end
            end
        end
        if event == sgs.EventLoseSkill then
            if data:toString() == "nyarz_rende" then
                room:detachSkillFromPlayer(player, "nyarz_rendebasic")
                room:setPlayerMark(player, "&nyarz_rende", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_rendebasic = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_rendebasic&",
    view_as = function(self)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local card = sgs.Self:getTag("nyarz_rendebasic"):toCard()
			pattern = card:objectName()
		end
        local card = nyarz_rendebasicCard:clone()
        local names = pattern:split("+")
        if #names ~= 1 then pattern = names[1] end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
        card:setUserString(pattern)
        return card
    end,
    enabled_at_play = function(self, player)
        if player:getMark("&nyarz_rende") == 0 then return false end
        if player:getMark("nyarz_rende_used2_lun") >= 4 then return false end
        if not player:hasSkill("nyarz_rende") then return false end
        return true
    end,
    enabled_at_response = function(self,player,pattern)
        if player:getMark("&nyarz_rende") == 0 then return false end
        if player:getMark("nyarz_rende_used2_lun") >= 4 then return false end
        if not player:hasSkill("nyarz_rende") then return false end
        --if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
        local basics = {"slash", "jink", "peach", "analeptic", "Jink", "Slash"}
        for _,basic in ipairs(basics) do
            if string.find(pattern, basic) then
                return true
            end
        end
        return false
    end
}
nyarz_rendebasic:setGuhuoDialog("l")

nyarz_rendebasicCard = sgs.CreateSkillCard
{
    name = "nyarz_rendebasic",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_rende")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_rende")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

        room:addPlayerMark(player, "nyarz_rende_draw-Clear", 1)
        room:addPlayerMark(player, "nyarz_rende_used2_lun", 1)
        room:addPlayerMark(player, "&nyarz_rende+3_num+-Clear", 1)
        room:removePlayerMark(player, "&nyarz_rende", 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_rende")
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

        room:addPlayerMark(player, "nyarz_rende_draw-Clear", 1)
        room:addPlayerMark(player, "nyarz_rende_used2_lun", 1)
        room:addPlayerMark(player, "&nyarz_rende+3_num+-Clear", 1)
        room:removePlayerMark(player, "&nyarz_rende", 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_rende")
		return card
    end
}

nyarz_renwang = sgs.CreateTriggerSkill{
    name = "nyarz_renwang",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            if player:getMark("nyarz_renwang-Clear") > 0 then return false end
            room:setTag("nyarz_renwang", data)
            local damage = data:toDamage()
            local log = sgs.LogMessage()
            log.type = "$nyarz_renwang_damage"
            log.from = player
            log.arg = self:objectName()
            log.arg2 = damage.damage
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, "nyarz_renwang-Clear", 1)
            room:addPlayerMark(player, "&nyarz_renwang+-Clear", 1)

            if not damage.from then return true end

            if damage.from:getKingdom() == "shu" then
                local prompt = string.format("draw:%s:", player:getGeneralName())
                if room:askForSkillInvoke(damage.from, self:objectName(), sgs.QVariant(prompt), false) then
                    player:drawCards(2, self:objectName())
                    return true
                end
            else
                if room:askForSkillInvoke(damage.from, self:objectName(), sgs.QVariant("change"), false) then
                    local log2 = sgs.LogMessage()
                    log2.type = "$nyarz_renwang_change"
                    log2.from = damage.from
                    log2.arg = "shu"
                    room:sendLog(log2)
                    room:setPlayerProperty(damage.from, "kingdom", sgs.QVariant("shu"))
                end
            end
            damage.from:drawCards(1, self:objectName())
            return true
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_liubei_winmusic = sgs.CreateTriggerSkill{
    name = "#nyarz_liubei_winmusic",
    events = {sgs.GameOver},
    frequency = sgs.Skill_NotFrequent,
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toString():split("+")
        for audio,target in sgs.qlist(room:getAlivePlayers()) do
            if (table.contains(winner, target:objectName()) or table.contains(winner, target:getRole())) 
            and target:getGeneralName() == "nyarz_liubei" then
                audio = "audio/system/nyarz_liubei-win.ogg"
                sgs.Sanguosha:playAudioEffect(audio)
                room:getThread():delay(500)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyarz_zhangwu = sgs.CreateTriggerSkill{
    name = "nyarz_zhangwu$",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_zhangwu_mark",
    waked_skills = "nyarz_longnu",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local can = false
            for _,p in sgs.qlist(room:getAllPlayers(true)) do
                if p:getRole() == "loyalist" and p:getKingdom() == "shu" and p:isDead() then
                    can = true
                    break
                end
            end

            if not can then return false end

            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "@nyarz_zhangwu_mark", 0)
                room:detachSkillFromPlayer(player, "nyarz_rende")
                room:gainMaxHp(player, 2, self:objectName())
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 2))
                room:acquireSkill(player, "nyarz_longnu")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasLordSkill(self:objectName())
        and target:getMark("@nyarz_zhangwu_mark") > 0
    end,
}

nyarz_longnu = sgs.CreateViewAsSkill
{
    name = "nyarz_longnu",
    n = 99,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return to_select:isRed() and #selected < 1
        end
        return #selected < 1 and (to_select:isKindOf("TrickCard") or to_select:isRed())
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = nyarz_longnuCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, cards)
        return true
    end,
    enabled_at_response = function(self,player,pattern)
        return string.find(pattern, "slash") or pattern == "Slash"
    end
}

nyarz_longnuCard = sgs.CreateSkillCard
{
    name = "nyarz_longnu",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local rcard = sgs.Sanguosha:getCard(self:getSubcards():at(0))
        if rcard:isBlack() then return false end

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local pattern = "slash"
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())

        if card:targetFixed() then return false end

        card:deleteLater()
        return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets, player)
        local user_string = "slash"
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:addSubcards(self:getSubcards())
        use_card:setSkillName(self:objectName())
        use_card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if #targets == 0 and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local rcard = sgs.Sanguosha:getCard(self:getSubcards():at(0))
            return rcard:isKindOf("TrickCard")
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if not use_card:isAvailable(player) then return false end
        end
        return use_card and use_card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        local player = source

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and cardUse.to:length() == 0 then
            room:broadcastSkillInvoke(self:objectName())
            local skill_log = sgs.LogMessage()
            skill_log.type = "#InvokeSkill"
            skill_log.from = source
            skill_log.arg = self:objectName()
            room:sendLog(skill_log)

            local log = sgs.LogMessage()
            log.from = source
            log.type = "$RecastCard"
            log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), "")
            room:moveCardTo(self, nil, nil, sgs.Player_DiscardPile, reason)

            source:drawCards(self:subcardsLength(), "recast")

            room:addPlayerMark(player, "nyarz_longnu_slash-PlayClear", 1)

            return nil
        end

        local choices = "slash+thunder_slash+fire_slash"
        local pattern = room:askForChoice(player, self:objectName(), choices)

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())

        room:setCardFlag(card, "nyarz_longnu")
        return card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local player = source

        local choices = "slash+thunder_slash+fire_slash"
        local pattern = room:askForChoice(player, self:objectName(), choices)

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())

        room:setCardFlag(card, "nyarz_longnu")
        return card
    end,
}

nyarz_longnu_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_longnu_buff",
    residue_func = function(self, from, card)
        return from:getMark("nyarz_longnu_slash-PlayClear")
    end,
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "nyarz_longnu") then return 1000 end
        return 0
    end,
}

nyarz_longnu_buff2 = sgs.CreateTriggerSkill{
    name = "#nyarz_longnu_buff2",
    events = {sgs.CardUsed,sgs.Death,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:hasFlag("nyarz_longnu") then return false end
            local no_respond_list = use.no_respond_list
            table.insert(no_respond_list, "_ALL_TARGETS")
            use.no_respond_list = no_respond_list
            data:setValue(use)
        end
        if event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from and
            death.damage.from:objectName() == player:objectName()
            and player:hasSkill("nyarz_longnu") then
                room:addPlayerMark(player, "nyarz_longnu_failed-Clear", 1)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            if player:getMark("nyarz_longnu_failed-Clear") > 0 then return false end
            if not player:hasSkill("nyarz_longnu") then return false end
            room:addPlayerMark(player, "&nyarz_longnu", 1)
            room:sendCompulsoryTriggerLog(player, "nyarz_longnu", true, true)
            room:loseHp(player, player:getMark("&nyarz_longnu"), true, player, "nyarz_longnu")
            if player:isAlive() then
                player:drawCards(3*player:getMark("&nyarz_longnu"), "nyarz_longnu")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_liubei:addSkill(nyarz_rende)
nyarz_liubei:addSkill(nyarz_rende_buff)
nyarz_liubei:addSkill(nyarz_renwang)
nyarz_liubei:addSkill(nyarz_liubei_winmusic)
nyarz_liubei:addSkill(nyarz_zhangwu)
extension:insertRelatedSkills("nyarz_rende", "#nyarz_rende_buff")
extension:insertRelatedSkills("nyarz_longnu","#nyarz_longnu_buff")
extension:insertRelatedSkills("nyarz_longnu","#nyarz_longnu_buff2")

nyarz_jushou = sgs.General(extension, "nyarz_jushou", "qun", 3, true, false, false)

nyarz_shibei = sgs.CreateTriggerSkill{
    name = "nyarz_shibei",
    events = {sgs.DamageInflicted,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if event == sgs.Damaged then
            if player:getMark("nyarz_shibei-Clear") == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "nyarz_shibei-Clear", 1)
                room:addPlayerMark(player, "&nyarz_shibei+-Clear", 1)
                if player:isWounded() then
                    local n = math.min(damage.damage, player:getLostHp())
                    room:recover(player, sgs.RecoverStruct(self:objectName(), player, n))
                end
            elseif player:getMark("nyarz_shibei-Clear") == 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "nyarz_shibei-Clear", 1)
                room:addPlayerMark(player, "&nyarz_shibei+-Clear", 1)
                room:loseHp(player, 1, true, player, self:objectName())
            end
        end
        if event == sgs.DamageInflicted then
            if player:getMark("nyarz_shibei-Clear") <= 1 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:loseHp(player, damage.damage, true, player, self:objectName())
            return true
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_jianyingVS = sgs.CreateViewAsSkill
{
    name = "nyarz_jianying",
    n = 99,
    view_filter = function(self, selected, to_select)
        return #selected < 2
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local card = nyarz_jianyingCard:clone()
            card:addSubcard(cards[1])
            card:addSubcard(cards[2])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

nyarz_jianyingCard = sgs.CreateSkillCard
{
    name = "nyarz_jianying",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:isDead() then return false end
        local choice = room:askForChoice(source, self:objectName(), "number+suit")
        if choice == "number" then
            local n = 0
            for _,id in sgs.qlist(self:getSubcards()) do
                n = n + sgs.Sanguosha:getCard(id):getNumber()
            end
            while(n > 13) do
                n = n - 13
            end
            local ids = sgs.IntList()
            for _,id in sgs.qlist(room:getDrawPile()) do
                if sgs.Sanguosha:getCard(id):getNumber() == n then
                    ids:append(id)
                end
                if ids:length() >= 2 then break end
            end
            if ids:length() < 2 then
                for _,id in sgs.qlist(room:getDiscardPile()) do
                    if sgs.Sanguosha:getCard(id):getNumber() == n then
                        ids:append(id)
                    end
                    if ids:length() >= 2 then break end
                end
            end
            if ids:isEmpty() then return false end
            room:fillAG(ids,source)
            local get = room:askForAG(source, ids, false, self:objectName())
            room:clearAG(source)
            room:obtainCard(source, get, false)
        else
            local suits = {}
            for _,id in sgs.qlist(self:getSubcards()) do
                table.insert(suits, sgs.Sanguosha:getCard(id):getSuitString())
            end
            local ids = sgs.IntList()
            for _,suit in ipairs(suits) do
                local find = false
                for _,id in sgs.qlist(room:getDrawPile()) do
                    if (sgs.Sanguosha:getCard(id):getSuitString() == suit) and (not ids:contains(id)) then
                        ids:append(id)
                        find = true
                        break
                    end
                end
                if not find then
                    for _,id in sgs.qlist(room:getDiscardPile()) do
                        if sgs.Sanguosha:getCard(id):getSuitString() == suit and (not ids:contains(id)) then
                            ids:append(id)
                            find = true
                            break
                        end
                    end 
                end
            end
            if ids:isEmpty() then return false end
            room:fillAG(ids,source)
            local get = room:askForAG(source, ids, false, self:objectName())
            room:clearAG(source)
            room:obtainCard(source, get, false)
        end
    end
}

nyarz_jianying = sgs.CreateTriggerSkill{
    name = "nyarz_jianying",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.DrawNCards},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_jianyingVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        --若智红利摸牌
        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= self:objectName() then return false end
            if math.random(1, (player:getMaxHp() + 1)) > player:getHp() then
                local find = false
                local n = 0
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    local mark = string.format("&nyarz_jianying+%s_char",card:getSuitString())
                    if card:getNumber() == player:getMark("nyarz_jianying_number")
                    or player:getMark(mark) > 0 then
                        find = true
                        break
                    end
                    n = n + 1;
                    if n > 3*player:getMaxHp() then break end
                end
                if find then
                    local tem1 = room:getNCards(n, false)
                    local tem2 = room:getNCards(1, false)
                    room:returnToTopDrawPile(tem1)
                    room:returnToTopDrawPile(tem2)
                end
            end
        end

        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            local last
            for _,mark in ipairs(player:getMarkNames()) do
                if player:getMark(mark) > 0 and (string.find(mark, "&nyarz_jianying")) then
                    last = mark
                    break
                end
            end
            if (not card:hasSuit()) or (card:getNumber() <= 0) then
                if last then room:setPlayerMark(player, last, 0) end
                room:setPlayerMark(player, "nyarz_jianying_number", 0)
                return false
            end

            local new = string.format("&nyarz_jianying+%s_char",card:getSuitString())
            if not last then
                room:setPlayerMark(player, "nyarz_jianying_number", card:getNumber())
                room:setPlayerMark(player, new, card:getNumber())
                return false
            end

            room:setPlayerMark(player, "nyarz_jianying_number", card:getNumber())
            if (player:getMark(new) > 0) or (player:getMark(last) == card:getNumber()) then
                room:setPlayerMark(player, last, 0)
                room:setPlayerMark(player, new, card:getNumber())
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(1, self:objectName())
                end
            else
                room:setPlayerMark(player, last, 0)
                room:setPlayerMark(player, new, card:getNumber())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_jianying_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_jianying_buff",
    pattern = ".",
    residue_func = function(self, player, card)
        if not card then return 0 end
        if not player:hasSkill("nyarz_jianying") then return 0 end
        if (not card:hasSuit()) or (card:getNumber() <= 0) then return 0 end

        local new = string.format("&nyarz_jianying+%s_char",card:getSuitString())
        if (player:getMark(new) > 0) then return 1000 end

        local last
        for _,mark in ipairs(player:getMarkNames()) do
            if player:getMark(mark) > 0 and (string.find(mark, "&nyarz_jianying")) then
                last = mark
                break
            end
        end
        if not last then return 0 end
        if player:getMark(last) == card:getNumber() then return 1000 end

        return 0
    end,
    distance_limit_func = function(self, player, card)
        if not card then return 0 end
        if not player:hasSkill("nyarz_jianying") then return 0 end
        if (not card:hasSuit()) or (card:getNumber() <= 0) then return 0 end

        local new = string.format("&nyarz_jianying+%s_char",card:getSuitString())
        if (player:getMark(new) > 0) then return 1000 end

        local last
        for _,mark in ipairs(player:getMarkNames()) do
            if player:getMark(mark) > 0 and (string.find(mark, "&nyarz_jianying")) then
                last = mark
                break
            end
        end
        if not last then return 0 end
        if player:getMark(last) == card:getNumber() then return 1000 end

        return 0
    end,
}

nyarz_jushou:addSkill(nyarz_shibei)
nyarz_jushou:addSkill(nyarz_jianying)
nyarz_jushou:addSkill(nyarz_jianying_buff)
extension:insertRelatedSkills("nyarz_jianying", "#nyarz_jianying_buff")

nyarz_zhouyu_mou = sgs.General(extension, "nyarz_zhouyu_mou", "wu", 4, true, false, false)

nyarz_ronghuo_mou = sgs.CreateTriggerSkill{
    name = "nyarz_ronghuo_mou",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            if player:getMark("nyarz_ronghuo_mou-Clear") > 0 then return false end
            if card:isKindOf("Slash") then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "nyarz_ronghuo_mou-Clear", 1)
                room:addPlayerMark(player, "&nyarz_ronghuo_mou+-Clear", 1)
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:objectName() == "fire_slash" then
                        room:obtainCard(player, card, true)
                        if room:getCardOwner(id):objectName() == player:objectName() then
                            room:setCardFlag(card, "nyarz_ronghuo_mou")
                            room:setCardFlag(card, "RemoveFromHistory")
                            room:setCardTip(id, "nyarz_ronghuo_mou")
                        end
                        return false
                    end
                end
                for _,id in sgs.qlist(room:getDiscardPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:objectName() == "fire_slash" then
                        room:obtainCard(player, card, true)
                        if room:getCardOwner(id):objectName() == player:objectName() then
                            room:setCardFlag(card, "nyarz_ronghuo_mou")
                            room:setCardFlag(card, "RemoveFromHistory")
                            room:setCardTip(id, "nyarz_ronghuo_mou")
                        end
                        return false
                    end
                end
            end
        end

        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire and (not damage.chain) then
                room:broadcastSkillInvoke(self:objectName())
                local kingdoms = {}
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if not table.contains(kingdoms, p:getKingdom()) then
                        table.insert(kingdoms, p:getKingdom())
                    end
                end
                local n = #kingdoms 

                local log = CreateDamageLog(damage, n, self:objectName(), true)
                room:sendLog(log)

                damage.damage = n + damage.damage
                data:setValue(damage)
            end
        end            
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_ronghuo_mou_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_ronghuo_mou_buff",
    residue_func = function(self, from, card)
        if card:hasFlag("nyarz_ronghuo_mou") then return 1000 end
        return 0
    end,
}

nyarz_yingmou_mouVS = sgs.CreateViewAsSkill
{
    name = "nyarz_yingmou_mou",
    n = 99,
    expand_pile = "#nyarz_yingmou_mou",
    response_pattern = "@@nyarz_yingmou_mou",
    view_filter = function(self, selected, to_select)
        if not sgs.Self:hasFlag("nyarz_yingmou_mou") then return false end
        return to_select:isAvailable(sgs.Self) and #selected < 1
        and sgs.Self:getPile("#nyarz_yingmou_mou"):contains(to_select:getId())
    end,
    view_as = function(self, cards)
        if not sgs.Self:hasFlag("nyarz_yingmou_mou") then
            local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("_nyarz_yingmou_mou")
            return card
        end
        if #cards == 1 then
            local card = nyarz_yingmou_mouCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_yingmou_mouCard =sgs.CreateSkillCard
{
    name = "nyarz_yingmou_mou",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card and card:targetFixed() then
			return false
		end

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetFilter(qtargets, to_select, target) and not target:isProhibited(to_select, card, qtargets) then
            return true
        end
        return false 
	end,
    target_fixed = function(self)		
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
        if card and card:targetFixed() then
            return true
        end
        return false
	end,
	feasible = function(self, targets)	
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetsFeasible(qtargets, target) then
            return true
        end
        return false
	end,
    about_to_use = function(self,room,use)
        room:broadcastSkillInvoke(self:objectName())
        local source = use.from
        local tos = {}
        for _,to in sgs.qlist(use.to) do
            table.insert(tos, to:objectName())
        end
        source:setTag("nyarz_yingmou_mou_to", sgs.QVariant(table.concat(tos, "+")))
    end,
}

nyarz_yingmou_mou = sgs.CreateTriggerSkill{
    name = "nyarz_yingmou_mou",
    events = {sgs.CardFinished,sgs.Death,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_yingmou_mouVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            if player:isDead() then return false end
            local death = data:toDeath()
            if death.damage and death.damage.from
            and death.damage.from:objectName() == player:objectName() 
            and player:getMark("nyarz_yingmou_mou_update") == 0 then
                room:setPlayerMark(player, "nyarz_yingmou_mou_update", 1)
                room:setPlayerMark(player, "&nyarz_yingmou_mou", 1)
                room:setPlayerMark(player, "nyarz_yingmou_mou-Clear", 0)
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:getSkillName() == self:objectName() then
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        if event == sgs.CardFinished then
            if player:isDead() then return false end
            if player:getMark("nyarz_yingmou_mou-Clear") > 0 then return false end
            if player:getMark("nyarz_yingmou_mou_draw-Clear") > 0
            and player:getMark("nyarz_yingmou_mou_show-Clear") > 0 then return false end
            local choices = {}
            local cant = {}
            local use = data:toCardUse()

            if player:getMark("nyarz_yingmou_mou_draw-Clear") == 0 then
                local can = false
                for _,p in sgs.qlist(use.to) do
                    if p:isAlive() then 
                        can = true 
                        break
                    end
                end
                if can then table.insert(choices, "draw")
                else table.insert(cant, "draw") end
            else table.insert(cant, "draw") end

            if player:getMark("nyarz_yingmou_mou_show-Clear") == 0 then
                local can = false
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isAlive() and (not p:isKongcheng()) and (not use.to:contains(p)) then 
                        can = true 
                        break
                    end
                end
                if can then table.insert(choices, "show")
                else table.insert(cant, "show") end
            else table.insert(cant, "show") end
            
            if #choices == 0 then return false
            else table.insert(choices, "cancel") end

            if room:askForSkillInvoke(player, self:objectName(), data, false) then else return false end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data, table.concat(cant, "+"))
            if choice == "cancel" then return false end

            --[[local invoke_log = sgs.LogMessage()
            invoke_log.type = "#InvokeSkill"
            invoke_log.from = player
            invoke_log.arg = self:objectName()
            room:sendLog(invoke_log)
            room:broadcastSkillInvoke(self:objectName())]]--

            if choice == "draw" then
                local targets = sgs.SPlayerList()
                for _,target in sgs.qlist(use.to) do
                    if target:isAlive() then targets:append(target) end
                end
                room:setPlayerFlag(player, "nyarz_yingmou_mou_draw")
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "nyarz_yingmou_mou_draw_chosen", true, true)
                room:setPlayerFlag(player, "-nyarz_yingmou_mou_draw")
                if not target then return false end
                local log = sgs.LogMessage()
                log.type = "$nyarz_yingmou_mou_chosen"
                log.from = player
                log.arg = self:objectName()..":draw"
                room:sendLog(log)
                room:broadcastSkillInvoke(self:objectName())

                if player:getMark("nyarz_yingmou_mou_update") == 0 then room:setPlayerMark(player, "nyarz_yingmou_mou-Clear", 1) end
                room:setPlayerMark(player, "nyarz_yingmou_mou_draw-Clear", 1)
                if target:getHandcardNum() > player:getHandcardNum() then
                    player:drawCards(target:getHandcardNum() - player:getHandcardNum(), self:objectName())
                end
                if target:isAlive() then
                    room:askForUseCard(player, "@@nyarz_yingmou_mou", "@nyarz_yingmou_mou:fire_attack:")
                end
            end

            if choice == "show" then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isAlive() and (not p:isKongcheng()) and (not use.to:contains(p)) then 
                        targets:append(p)
                    end
                end
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "nyarz_yingmou_mou_show_chosen", true, true)
                if not target then return false end
                local log = sgs.LogMessage()
                log.type = "$nyarz_yingmou_mou_chosen"
                log.from = player
                log.arg = self:objectName()..":show"
                room:sendLog(log)
                room:broadcastSkillInvoke(self:objectName())

                if player:getMark("nyarz_yingmou_mou_update") == 0 then room:setPlayerMark(player, "nyarz_yingmou_mou-Clear", 1) end
                room:setPlayerMark(player, "nyarz_yingmou_mou_show-Clear", 1)

                local all = sgs.IntList()
                for _,card in sgs.qlist(target:getHandcards()) do
                    if card:isDamageCard() then all:append(card:getId()) end
                end
                local decision
                if not all:isEmpty() then
                    local decisions = string.format("discard=%s+use=%s+cancel",target:getGeneralName(),target:getGeneralName())
                    room:showCard(target, all)

                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    decision = room:askForChoice(player, self:objectName(), decisions, _data)
                else
                    local decisions = string.format("discard=%s+cancel",target:getGeneralName())

                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    decision = room:askForChoice(player, self:objectName(), decisions, _data, "use="..target:getGeneralName())
                end
                if decision == "cancel" then return false end
                if string.find(decision, "discard") and target:getHandcardNum() > player:getHandcardNum() then
                    local n = target:getHandcardNum() - player:getHandcardNum()
                    room:askForDiscard(target, self:objectName(), n, n, false, false)
                end
                if string.find(decision, "use") then
                    while(true) do
                        local card_ids = sgs.QVariant()
                        card_ids:setValue(all)
                        player:setTag("nyarz_yingmou_mou_card_ids", card_ids)
                        
                        room:setPlayerFlag(player, "nyarz_yingmou_mou")
                        room:notifyMoveToPile(player, all, "nyarz_yingmou_mou", sgs.Player_PlaceHand, true)
                        local use_card = room:askForUseCard(player, "@@nyarz_yingmou_mou", "@nyarz_yingmou_mou:nyarz_yingmou_mou_damagecard")
                        room:notifyMoveToPile(player, all, "nyarz_yingmou_mou", sgs.Player_PlaceHand, false)
                        room:setPlayerFlag(player, "-nyarz_yingmou_mou")
                        if not use_card then return false end

                        local real_card = sgs.Sanguosha:getCard(use_card:getSubcards():at(0))
                        local to = sgs.SPlayerList()
                        local tos = player:getTag("nyarz_yingmou_mou_to"):toString():split("+")
                        for _,p in ipairs(tos) do
                            local tt = room:findPlayerByObjectName(p)
                            to:append(tt)
                        end
                        room:useCard(sgs.CardUseStruct(real_card, player, to))

                        if player:isDead() or target:isDead() then return false end
                        local new = sgs.IntList()
                        for _,id in sgs.qlist(all) do
                            if room:getCardOwner(id) and room:getCardOwner(id):objectName() == target:objectName() then
                                new:append(id)
                            end
                        end
                        all = new
                        if all:isEmpty() then return false end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_yingmou_mou_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_yingmou_mou_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from and from:hasFlag("nyarz_yingmou_mou") then return 1000 end
        return 0
    end,
}

nyarz_zhouyu_mou:addSkill(nyarz_ronghuo_mou)
nyarz_zhouyu_mou:addSkill(nyarz_ronghuo_mou_buff)
nyarz_zhouyu_mou:addSkill(nyarz_yingmou_mou)
nyarz_zhouyu_mou:addSkill(nyarz_yingmou_mouVS)
nyarz_zhouyu_mou:addSkill(nyarz_yingmou_mou_buff)
extension:insertRelatedSkills("nyarz_ronghuo_mou","#nyarz_ronghuo_mou_buff")
extension:insertRelatedSkills("nyarz_yingmou_mou","#nyarz_yingmou_mou_buff")

nyarz_lusu_mou = sgs.General(extension, "nyarz_lusu_mou", "wu", 3, true, false, false)

nyarz_mingshi_mouVS = sgs.CreateViewAsSkill
{
    name = "nyarz_mingshi_mou",
    n = 99,
    response_pattern = "@@nyarz_mingshi_mou!",
    view_filter = function(self, selected, to_select)
        return #selected < 3
    end,
    view_as = function(self, cards)
        if #cards == 3 then
            local card = nyarz_mingshi_mouCard:clone()
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_mingshi_mouCard = sgs.CreateSkillCard
{
    name = "nyarz_mingshi_mou",
    will_throw = false,
    mute = true,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showCard(effect.from, self:getSubcards())

        room:fillAG(self:getSubcards(),effect.to)
        local get = room:askForAG(effect.to, self:getSubcards(), false, self:objectName())
        room:clearAG(effect.to)
        room:obtainCard(effect.to, get, false)
    end
}

nyarz_mingshi_mou = sgs.CreateTriggerSkill{
    name = "nyarz_mingshi_mou",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_mingshi_mouVS,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if event == sgs.EventPhaseEnd then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "nyarz_mingshi_mou", 0)
            end
        end
        if event == sgs.CardsMoveOneTime then
            if not player:hasSkill(self:objectName()) then return false end
            local mark = "nyarz_mingshi_mou"
            if player:getMark(mark) > 0 then return false end

            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand then else return false end
            if move.card_ids:length() < 2 then return false end
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, mark, 1)

            player:drawCards(2, self:objectName())

            if player:getCardCount() < 3 then return false end

            room:askForUseCard(player, "@@nyarz_mingshi_mou!", "@nyarz_mingshi_mou")
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_mengmou_mou = sgs.CreateTriggerSkill{
    name = "nyarz_mengmou_mou",
    events = {sgs.CardsMoveOneTime, sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if event == sgs.CardsMoveOneTime then
            if not player:hasSkill(self:objectName()) then return false end
            if player:isDead() then return false end
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_PlaceHand then return false end
            if not (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then return false end
            local target
            if move.from and move.from:objectName() == player:objectName()
            and move.to and move.to:objectName() ~= player:objectName() then 
                target = room:findPlayerByObjectName(move.to:objectName())
            end
            if move.from and move.from:objectName() ~= player:objectName()
            and move.to and move.to:objectName() == player:objectName() then 
                target = room:findPlayerByObjectName(move.from:objectName())
            end
            if (not target) or (target:isDead()) then return false end
    
            local _data = sgs.QVariant()
            _data:setValue(target)
    
            local prompt = string.format("to:%s:", target:getGeneralName())
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
            room:broadcastSkillInvoke(self:objectName())
    
            player:drawCards(2, self:objectName())
            if player:isAlive() and target:isAlive() then
                local choices = string.format("recover=%s+lose=%s", target:getGeneralName(), target:getGeneralName())
                local choice = room:askForChoice(player, self:objectName(), choices, _data)

                if string.find(choice, "recover") then
                    local log = sgs.LogMessage()
                    log.type = "$nyarz_mengmou_mou_chosen"
                    log.from = player
                    log.arg = "nyarz_mengmou_mou_recover_log"
                    room:sendLog(log)

                    local card = room:askForUseCard(target, "Slash", "nyarz_mengmou_mou_recover", -1,
                    sgs.Card_MethodUse, false, player, nil, "nyarz_mengmou_mou_recover")

                else
                    local log = sgs.LogMessage()
                    log.type = "$nyarz_mengmou_mou_chosen"
                    log.from = player
                    log.arg = "nyarz_mengmou_mou_lose_log"
                    room:sendLog(log)

                    local card = room:askForUseCard(target, "Slash", "nyarz_mengmou_mou_lose", -1,
                    sgs.Card_MethodUse, false, player, nil, "nyarz_mengmou_mou_lose")

                    if target:isAlive() and (not card) then
                        room:loseHp(target, 1, true, player, self:objectName())
                    end
                end
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and (damage.card:hasFlag("nyarz_mengmou_mou_lose") 
            or damage.card:hasFlag("nyarz_mengmou_mou_recover")) then
                room:setCardFlag(damage.card, "nyarz_mengmou_mou_damage")
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("nyarz_mengmou_mou_recover") and use.card:hasFlag("nyarz_mengmou_mou_damage")
            and use.from:isAlive() and use.from:isWounded() then
                room:recover(use.from, sgs.RecoverStruct(self:objectName(), use.from, 1))
            end
            if use.card:hasFlag("nyarz_mengmou_mou_lose") and (not use.card:hasFlag("nyarz_mengmou_mou_damage"))
            and use.from:isAlive() then
                room:loseHp(use.from, 1, true, nil, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_lusu_mou:addSkill(nyarz_mingshi_mou)
nyarz_lusu_mou:addSkill(nyarz_mingshi_mouVS)
nyarz_lusu_mou:addSkill(nyarz_mengmou_mou)

nyarz_zhugejin = sgs.General(extension, "nyarz_zhugejin", "wu", 3, true, false, false)

nyarz_mingzhe = sgs.CreateTriggerSkill{
    name = "nyarz_mingzhe",
    events = {sgs.CardsMoveOneTime,sgs.BeforeCardsMove},
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
            local n = 0
            for i = 0, move.card_ids:length() - 1, 1 do
				if move.from_places:at(i) == sgs.Player_PlaceEquip 
                or move.from_places:at(i) == sgs.Player_PlaceHand then
					local id = move.card_ids:at(i)
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isRed() then n = n + 1 end
				end
			end
            if n <= 0 then return false end
            player:drawCards(n, self:objectName())
        end
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
            local show = sgs.IntList()
            for i = 0, move.card_ids:length() - 1, 1 do
				if move.from_places:at(i) == sgs.Player_PlaceEquip 
                or move.from_places:at(i) == sgs.Player_PlaceHand then
					local id = move.card_ids:at(i)
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isRed() then show:append(id) end
				end
			end
            if show:isEmpty() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:showCard(player, show)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and (target:getPhase() ~= sgs.Player_Play) and target:isAlive()
    end,
}

nyarz_huanshi = sgs.CreateTriggerSkill{
    name = "nyarz_huanshi",
    events = {sgs.AskForRetrial},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getCardCount() < 2 then return false end
        local judge = data:toJudge()
        if room:getTag("nyarz_huanshi") then room:removeTag("nyarz_huanshi") end
        room:setTag("nyarz_huanshi", data)

        local prompt = string.format("@nyarz_huanshi:%s::%s:", judge.who:getGeneralName(), judge.reason)
        local show_cards = room:askForExchange(player, self:objectName(), 9999, 2, true, prompt, true)
        if not show_cards then return false end
        local ids = show_cards:getSubcards()
        local invoke_log = sgs.LogMessage()
        invoke_log.type = "#InvokeSkill"
        invoke_log.from = player
        invoke_log.arg = self:objectName()
        room:sendLog(invoke_log)
        room:broadcastSkillInvoke(self:objectName())
        room:notifySkillInvoked(player, self:objectName())

        room:showCard(player, ids)
        room:fillAG(ids, judge.who)
        local change = room:askForAG(judge.who, ids, false, self:objectName(), "nyarz_huanshi_chosen:"..judge.reason)
        room:clearAG(judge.who)
        ids:removeOne(change)

        local card = sgs.Sanguosha:getCard(change)
        room:retrial(card, player, judge, self:objectName(), false)

        local recast = sgs.IntList()
        for _,id in sgs.qlist(ids) do
            if room:getCardOwner(id):objectName() == player:objectName() then
                recast:append(id)
            end
        end
        if recast:isEmpty() then return false end
        local log = sgs.LogMessage()
        log.type = "$RecastCard"
        log.from = player
        log.card_str = table.concat(sgs.QList2Table(recast), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(recast, nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        player:drawCards(recast:length(), "recast")
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_hongyuanVS = sgs.CreateViewAsSkill
{
    name = "nyarz_hongyuan",
    n = 99,
    response_pattern = "@@nyarz_hongyuan",
    view_filter = function(self, selected, to_select)
        return #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = nyarz_hongyuanCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_hongyuanCard = sgs.CreateSkillCard
{
    name = "nyarz_hongyuan",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
        and to_select:getMark("&nyarz_hongyuan_chosen+#"..sgs.Self:objectName()) == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local _player = sgs.SPlayerList()
        _player:append(effect.from)
        room:addPlayerMark(effect.to, "&nyarz_hongyuan_chosen+#"..effect.from:objectName(), 1, _player)
        room:obtainCard(effect.to, self, false)
    end
}

nyarz_hongyuan = sgs.CreateTriggerSkill{
    name = "nyarz_hongyuan",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    priority = 1,
    view_as_skill = nyarz_hongyuanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if event == sgs.EventPhaseEnd then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "nyarz_hongyuan", 0)
            end
        end
        if event == sgs.CardsMoveOneTime then
            if not player:hasSkill(self:objectName()) then return false end
            if player:isDead() then return false end
            local mark = "nyarz_hongyuan"
            if player:getMark(mark) > 0 then return false end

            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand then else return false end
            if move.card_ids:length() < 2 then return false end
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("give:"..move.card_ids:length()), false) then return false end
            
            for i = 1, move.card_ids:length(), 1 do
                local give = room:askForUseCard(player, "@@nyarz_hongyuan", "@nyarz_hongyuan")
                if not give then break end
                room:addPlayerMark(player, "nyarz_hongyuan", 1)
                if player:isDead() then break end
            end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "&nyarz_hongyuan_chosen+#"..player:objectName(), 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_zhugejin:addSkill(nyarz_mingzhe)
nyarz_zhugejin:addSkill(nyarz_huanshi)
nyarz_zhugejin:addSkill(nyarz_hongyuan)
nyarz_zhugejin:addSkill(nyarz_hongyuanVS)

nyarz_guojia = sgs.General(extension, "nyarz_guojia", "wei", 3, true, false, false)

nyarz_tiandu = sgs.CreateTriggerSkill{
    name = "nyarz_tiandu",
    events = {sgs.FinishJudge,sgs.EventPhaseStart,sgs.DrawNCards,sgs.EventLoseSkill},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.FinishJudge then
            if player:isDead() then return false end
            local judge = data:toJudge()
            if judge.who:objectName() ~= player:objectName() then return false end
            local id = judge.card:getId()
            if not room:getCardOwner(id) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:obtainCard(player, judge.card, true)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|heart|."
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            room:getThread():delay()
            if player:isDead() then return false end
            if not judge:isGood() then
                room:damage(sgs.DamageStruct(self:objectName(), nil, player, 1, sgs.DamageStruct_Normal))
            end
            if player:isDead() then return false end
            if player:getMark("&nyarz_tiandu") < 5 then
                room:addPlayerMark(player, "&nyarz_tiandu", 1)
            end
        end
        if event == sgs.DrawNCards then
            if player:getMark("&nyarz_tiandu") > 0 then
                --[[room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                local draw = data:toInt()
                draw = draw + player:getMark("&nyarz_tiandu")
                data:setValue(draw)]]
                local draw = data:toDraw()
                if draw.reason ~= "draw_phase" then return false end
                draw.num = draw.num + player:getMark("&nyarz_tiandu")
                data:setValue(draw)
            end
        end
        if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                room:setPlayerMark(player, "&nyarz_tiandu", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_tiandu_max = sgs.CreateMaxCardsSkill{
    name = "#nyarz_tiandu_max",
    extra_func = function(self, target)
        return target:getMark("&nyarz_tiandu")
    end,
}

nyarz_yijiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_yiji",
    n = 999,
    response_pattern = "@@nyarz_yiji",
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cc = nyarz_yijiCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_yijiCard = sgs.CreateSkillCard
{
    name = "nyarz_yiji",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
    end
}

nyarz_yiji = sgs.CreateTriggerSkill{
    name = "nyarz_yiji",
    events = {sgs.Damaged,sgs.EnterDying,sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill  = nyarz_yijiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            if player:isDead() then return false end
            local damage = data:toDamage()
            for i = 1, damage.damage, 1 do
                if player:isDead() then return false end
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(2, self:objectName())
                    room:setPlayerMark(player, "nyarz_yiji_max", player:getHandcardNum() - player:getMaxCards())
                    while(player:isAlive() and (not player:isNude())) do
                        if (not room:askForUseCard(player, "@@nyarz_yiji", "@nyarz_yiji")) then break end
                        room:addPlayerMark(player, "nyarz_yiji_give", 1)
                    end
                    room:setPlayerMark(player, "nyarz_yiji_give", 0)
                end
            end
        end
        if event == sgs.EnterDying then
            if player:isDead() then return false end
            local dying = data:toDying()
            if dying.who:objectName() ~= player:objectName() then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("trick")) then
                room:broadcastSkillInvoke(self:objectName())
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    local name = card:objectName()
                    if name == "nullification"
                    or name == "dismantlement"
                    or name == "ex_nihilo" then
                        room:obtainCard(player, card, true)
                        break
                    end
                end
            end 
        end
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then return false end
            if player:isAllNude() then return false end
            local targets = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "nyarz_yiji_death", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                give:deleteLater()
                for _,card in sgs.qlist(player:getHandcards()) do
                    give:addSubcard(card)
                end
                for _,equip in sgs.qlist(player:getEquips()) do
                    give:addSubcard(equip)
                end
                for _,delay in sgs.qlist(player:getJudgingArea()) do
                    give:addSubcard(delay)
                end
                room:obtainCard(target, give, false)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_guojia:addSkill(nyarz_tiandu)
nyarz_guojia:addSkill(nyarz_tiandu_max)
nyarz_guojia:addSkill(nyarz_yiji)
nyarz_guojia:addSkill(nyarz_yijiVS)
extension:insertRelatedSkills("nyarz_tiandu", "#nyarz_tiandu_max")

nyarz_zhaoyan = sgs.General(extension, "nyarz_zhaoyan", "wei", 3, true, false, false)

nyarz_funing = sgs.CreateTriggerSkill{
    name = "nyarz_funing",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName() and player:isAlive()
        and use.card and use.card:isKindOf("Slash") and player:getMark("&nyarz_funing-Clear") == 0 then
            local suit = use.card:getSuitString()
            local names = player:getMarkNames()
            local mark = nil
            for _,p in ipairs(names) do
                if (string.find(p,"&nyarz_funing_suit")) and (player:getMark(p) > 0) then
                    mark = p
                    break
                end
            end
            if mark and player:getMark(mark) > 0 then 
                if string.find(mark,suit.."_char") then return false end
                room:setPlayerMark(player, mark, 0)
                mark = string.sub(mark,1,-7)
            else
                mark = "&nyarz_funing_suit"
            end
            mark = mark.."+"..suit.."_char-Clear"
            room:setPlayerMark(player, mark, 1)

            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local recast = sgs.IntList()
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:getSuit() == use.card:getSuit() then
                    recast:append(card:getEffectiveId())
                end
            end
            if recast:isEmpty() then
                room:setPlayerMark(player, "&nyarz_funing-Clear", 1)
                room:loseHp(player, 1, true, player, self:objectName())
                if player:isAlive() then player:drawCards(3, self:objectName()) end
            else
                local log = sgs.LogMessage()
                log.type = "$RecastCard"
                log.from = player
                log.card_str = table.concat(sgs.QList2Table(recast), "+")
                room:sendLog(log)
        
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(recast, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)
        
                if player:isAlive() then player:drawCards(recast:length(), "recast") end
                if player:isAlive() then player:drawCards(1, self:objectName()) end
                if player:isAlive() then room:addPlayerHistory(player, use.card:getClassName(), -1) end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_funing_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_funing_buff",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("nyarz_funing") then return 1000 end
        return 0
    end,
}

nyarz_bingji = sgs.CreateTriggerSkill{
    name = "nyarz_bingji",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if room:getTag("FirstRound"):toBool() then return false end 
            if move.from and move.from:objectName() == player:objectName() and player:isAlive() then

                local n = 0
                local max = player:getHp()
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(0) == sgs.Player_PlaceHand
                    or move.from_places:at(0) == sgs.Player_PlaceEquip then
                        n = n + 1
                    end
                    if n >= max then break end
                end
                if n == 0 then return false end

                local a = 0
                local b = 0
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("nyarz_bingji") then a = a + 1 
                    else b = b + 1 end
                end
                if a > b then return false end

                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local ids = player:drawCardsList(n, self:objectName())
                if player:isDead() then return false end
                for _,id in sgs.qlist(ids) do
                    if room:getCardOwner(id):objectName() == player:objectName() then
                        local card = sgs.Sanguosha:getCard(id)
                        room:setCardFlag(card, "nyarz_bingji")
                        room:setCardTip(id, "nyarz_bingji")
                        room:setPlayerCardLimitation(player, "use", card:toString(), false)
                    end
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("nyarz_bingji") then room:ignoreCards(player, card) end
                end
            end
            if change.to == sgs.Player_NotActive then
                room:clearPlayerCardLimitation(player, false)
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("nyarz_bingji") then
                        local id = card:getId()
                        room:setCardFlag(card, "-nyarz_bingji")
                        room:setCardTip(id, "-nyarz_bingji")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhaoyan:addSkill(nyarz_funing)
nyarz_zhaoyan:addSkill(nyarz_funing_buff)
nyarz_zhaoyan:addSkill(nyarz_bingji)
extension:insertRelatedSkills("nyarz_funing", "#nyarz_funing_buff")

nyarz_longfeng = sgs.General(extension, "nyarz_longfeng", "shu", 4, true, false, false)

nyarz_youlongVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_youlong",
    view_as = function(self)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "@@nyarz_youlong" then
                pattern = sgs.Self:property("nyarz_youlong_card"):toString()
            elseif pattern == "Jink" then
                pattern = "jink"
            end
            if string.find(pattern, "peach") and string.find(pattern, "analeptic") then
                if sgs.Self:getMark("nyarz_youlong_analeptic_lun") == 0 then 
                    pattern = "analeptic"
                elseif sgs.Self:getMark("nyarz_youlong_peach_lun") == 0 then 
                    pattern = "peach" 
                end
            end
            local card = nyarz_youlongCard:clone()
            card:setUserString(pattern)
            return card
        else
            return nyarz_youlong_selectCard:clone()
        end
    end,
    enabled_at_play = function(self, player)
        return player:hasEquipArea()
    end,
    --[[enabled_at_nullification = function(self, player)
        if not player:hasEquipArea() then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        if player:getChangeSkillState(self:objectName()) <= 1 then return false end
        local mark = string.format("nyarz_youlong_%s_lun", "nullification")
        return player:getMark(mark) == 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        if not player:hasEquipArea() then return false end
        if pattern == "@@nyarz_youlong" then return true end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end

        if player:getChangeSkillState(self:objectName()) <= 1 then
            if pattern == "Slash" or string.find(pattern, "slash") then
                local all = {"slash", "fire_slash", "thunder_slash"}
                for _,slash in ipairs(all) do
                    local mark = string.format("nyarz_youlong_%s_lun", slash)
                    if player:getMark(mark) == 0 then
                        return true
                    end
                end
            elseif pattern == "Jink" or pattern == "jink" then
                local mark = string.format("nyarz_youlong_%s_lun", "jink")
                return player:getMark(mark) == 0
            elseif pattern == "Peach" or pattern == "peach" then
                local mark = string.format("nyarz_youlong_%s_lun", "peach")
                return player:getMark(mark) == 0
            elseif pattern == "Analeptic" or pattern == "analeptic" then
                local mark = string.format("nyarz_youlong_%s_lun", "analeptic")
                return player:getMark(mark) == 0
            end
            if string.find(pattern, "peach") and string.find(pattern, "analeptic") then
                return player:getMark("nyarz_youlong_peach_lun") == 0
                or player:getMark("nyarz_youlong_analeptic_lun") == 0
            end
        else
            if pattern == "nullification" then
                local mark = string.format("nyarz_youlong_%s_lun", "nullification")
                return player:getMark(mark) == 0
            end
        end
        return false 
    end,
}

nyarz_youlong_selectCard = sgs.CreateSkillCard
{
    name = "nyarz_youlong_select",
    will_throw = false,
    target_fixed = true,
    about_to_use = function(self,room,use)
        local player = use.from
        local names = {}
        for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
            local card = sgs.Sanguosha:getEngineCard(id)
            if player:getChangeSkillState("nyarz_youlong") <= 1 and card:isKindOf("BasicCard") then 
                local name = card:objectName()
                if not table.contains(names, name) then
                    table.insert(names, name)
                end
            elseif player:getChangeSkillState("nyarz_youlong") == 2 and card:isNDTrick() then 
                local name = card:objectName()
                if not table.contains(names, name) then
                    table.insert(names, name)
                end
            end
        end
        local choices = {}
        local disable = {}
        for _,name in ipairs(names) do
            local card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
            local mark = string.format("nyarz_youlong_%s_lun", name)
            if player:getMark(mark) == 0 and card:isAvailable(player) then
                table.insert(choices, name)
            else
                table.insert(disable, name)
            end
        end
        if #choices <= 0 then
            room:askForChoice(player, "nyarz_youlong", "cancel+nocards")
        else
            table.insert(choices, "cancel")
            local pattern = room:askForChoice(player, "nyarz_youlong", table.concat(choices, "+"), sgs.QVariant(), table.concat(disable, "+"))
            if pattern == "cancel" then return false end
            room:setPlayerProperty(player, "nyarz_youlong_card", sgs.QVariant(pattern))
            room:askForUseCard(player, "@@nyarz_youlong", "@nyarz_youlong:"..pattern)
        end
    end,
}

nyarz_youlongCard = sgs.CreateSkillCard
{
    name = "nyarz_youlong",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_youlong")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_youlong")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg =  self:objectName()
        room:sendLog(log)

        if player:getChangeSkillState(self:objectName()) <= 1 then
            room:setChangeSkillState(player, self:objectName(), 2)
        else
            room:setChangeSkillState(player, self:objectName(), 1)
        end

        local equips = {}
        for i = 0, 4, 1 do
            if player:hasEquipArea(i) then
                table.insert(equips, tostring(i))
            end
        end

        local throw = room:askForChoice(player, self:objectName(), table.concat(equips,"+"), sgs.QVariant(2))
        player:throwEquipArea(tonumber(throw))
        player:drawCards(1, self:objectName())

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local choices = {}
            local all = {"slash", "fire_slash", "thunder_slash"}
            for _,slash in ipairs(all) do
                local mark = string.format("nyarz_youlong_%s_lun", slash)
                if player:getMark(mark) == 0 then
                    table.insert(choices, slash)
                end
            end
            pattern = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), sgs.QVariant(3))
        end

        local mark = string.format("nyarz_youlong_%s_lun", pattern)
        room:setPlayerMark(player, mark, 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_youlong")
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg =  self:objectName()
        room:sendLog(log)

        if player:getChangeSkillState(self:objectName()) <= 1 then
            room:setChangeSkillState(player, self:objectName(), 2)
        else
            room:setChangeSkillState(player, self:objectName(), 1)
        end

        local equips = {}
        for i = 0, 4, 1 do
            if player:hasEquipArea(i) then
                table.insert(equips, tostring(i))
            end
        end

        local throw = room:askForChoice(player, self:objectName(), table.concat(equips,"+"), sgs.QVariant(2))
        player:throwEquipArea(tonumber(throw))
        player:drawCards(1, self:objectName())

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local choices = {}
            local all = {"slash", "fire_slash", "thunder_slash"}
            for _,slash in ipairs(all) do
                local mark = string.format("nyarz_youlong_%s_lun", slash)
                if player:getMark(mark) == 0 then
                    table.insert(choices, slash)
                end
            end
            pattern = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), sgs.QVariant(3))
        end

        local mark = string.format("nyarz_youlong_%s_lun", pattern)
        room:setPlayerMark(player, mark, 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_youlong")
        return card
    end
}

nyarz_youlong = sgs.CreateTriggerSkill{
    name = "nyarz_youlong",
    events = {sgs.GameStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_youlongVS,
    change_skill = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_luanfengVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_luanfeng",
    view_as = function(self)
        return nyarz_luanfengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyarz_luanfeng_used_lun") == 0
    end
}

nyarz_luanfengCard = sgs.CreateSkillCard
{
    name = "nyarz_luanfeng",
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local player = effect.from
        local target = effect.to

        room:setPlayerMark(player, "nyarz_luanfeng_used_lun", 1)
        local first = player:getMark("&nyarz_luanfeng")
        room:setPlayerMark(player, "&nyarz_luanfeng", 1)

        local hp = 3
        if first > 0 then hp = 1 end
        if target:getHp() < hp and target:isWounded() then
            room:recover(target, sgs.RecoverStruct(self:objectName(), player, hp - target:getHp()))
        end
        if target:isDead() then return false end

        local hand = 6
        if first > 0 then hand = 3 end
        if target:getHandcardNum() < hand then
            target:drawCards(hand-target:getHandcardNum(), self:objectName())
        end
        if target:isDead() then return false end
        
        for i = 0, 4, 1 do
            if not target:hasEquipArea(i) then
                target:obtainEquipArea(i)
            end
            if target:isDead() then return false end
        end
    end
}

nyarz_luanfeng = sgs.CreateTriggerSkill{
    name = "nyarz_luanfeng",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_luanfengVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("nyarz_luanfeng_used_lun") > 0 then return false end
        local dying = data:toDying()
        local target = dying.who
        local _data = sgs.QVariant()
        _data:setValue(target)
        if not room:askForSkillInvoke(player, self:objectName(), _data) then return false end
        room:broadcastSkillInvoke(self:objectName())

        room:setPlayerMark(player, "nyarz_luanfeng_used_lun", 1)
        local first = player:getMark("&nyarz_luanfeng")
        room:setPlayerMark(player, "&nyarz_luanfeng", 1)

        local hp = 3
        if first > 0 then hp = 1 end
        if target:getHp() < hp and target:isWounded() then
            room:recover(target, sgs.RecoverStruct(self:objectName(), player, hp - target:getHp()))
        end
        if target:isDead() then return false end

        local hand = 6
        if first > 0 then hand = 3 end
        if target:getHandcardNum() < hand then
            target:drawCards(hand-target:getHandcardNum(), self:objectName())
        end
        if target:isDead() then return false end
        
        for i = 0, 4, 1 do
            if not target:hasEquipArea(i) then
                target:obtainEquipArea(i)
            end
            if target:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_longfeng:addSkill(nyarz_youlong)
nyarz_longfeng:addSkill(nyarz_youlongVS)
nyarz_longfeng:addSkill(nyarz_luanfeng)
nyarz_longfeng:addSkill(nyarz_luanfengVS)

nyarz_lvbu_god = sgs.General(extension, "nyarz_lvbu_god", "god", 5, true, false, false)

nyarz_wumou_god = sgs.CreateTriggerSkill{
    name = "nyarz_wumou_god",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if (not use.card) or (not use.card:isNDTrick()) then return false end
        if player:isDead() then return false end
        local choices = "damaged"
        if player:getMark("&nyarz_baonu_god") > 0 then
            choices = "damaged+dismark"
        end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        local choice = room:askForChoice(player, self:objectName(), choices, data)
        if choice == "dismark" then
            room:broadcastSkillInvoke(self:objectName())
            room:removePlayerMark(player, "&nyarz_baonu_god", 1)
        else
            room:getThread():delay()
            room:damage(sgs.DamageStruct(self:objectName(), nil, player, 1, sgs.DamageStruct_Normal))
            if player:isAlive() then
                local tos = sgs.SPlayerList()
                local slash = sgs.Sanguosha:cloneCard("slash")
                slash:setSkillName("_nyarz_wumou_god")
                for _,to in sgs.qlist(use.to) do
                    if to:objectName() ~= player:objectName()
                    and (not player:isProhibited(to, slash)) then
                        tos:append(to)
                    end
                end
                if not tos:isEmpty() then
                    room:useCard(sgs.CardUseStruct(slash, player, tos))
                else
                    slash:deleteLater()
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_wuqian_god = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_wuqian_god",
    tiansuan_type = "slash,fire_slash,thunder_slash,duel",
    view_as = function(self)
        local pattern = sgs.Self:getTag("nyarz_wuqian_god"):toString()
        local card = nyarz_wuqian_godCard:clone()
        card:setUserString(pattern)
        return card
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#nyarz_wuqian_god") < 2
    end,
}

nyarz_wuqian_godCard = sgs.CreateSkillCard
{
    name = "nyarz_wuqian_god",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wuqian_god")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wuqian_god")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg =  self:objectName()
        room:sendLog(log)

        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 1, sgs.DamageStruct_Normal))

        local pattern = self:getUserString()

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("_nyarz_wuqian_god")
        room:setCardFlag(card, "RemoveFromHistory")
		return card
	end,
}

nyarz_wuqian_god_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_wuqian_god_buff",
    residue_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "nyarz_wuqian_god") then return 1000 end
        return 0
    end,
}

nyarz_shenfen_godVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_shenfen_god",
    response_pattern = "@@nyarz_shenfen_god",
    view_as = function(self)
        return nyarz_shenfen_godCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#nyarz_shenfen_god")) and player:getMark("&nyarz_baonu_god") >= 6
    end,
}

nyarz_shenfen_godCard = sgs.CreateSkillCard
{
    name = "nyarz_shenfen_god",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local player = source
        room:removePlayerMark(player, "&nyarz_baonu_god", 6)

        local flag = "nyarz_shenfen_god_"..player:objectName()
        if player:isDead() then flag = "nyarz_shenfen_god_dead_"..player:objectName() end

        local nextp = player:getNextAlive()
        while(true) do
            if nextp:objectName() == player:objectName() then break end
            if nextp:hasFlag(flag) then break end
            room:setPlayerFlag(nextp, flag)
            room:damage(sgs.DamageStruct(self:objectName(), player, nextp, 1, sgs.DamageStruct_Normal))
            nextp = nextp:getNextAlive()
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerFlag(p, "-"..flag)
        end

        nextp = player:getNextAlive()
        while(true) do
            if nextp:objectName() == player:objectName() then break end
            if nextp:hasFlag(flag) then break end
            room:setPlayerFlag(nextp, flag)
            nextp:throwAllEquips()
            nextp = nextp:getNextAlive()
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerFlag(p, "-"..flag)
        end

        nextp = player:getNextAlive()
        while(true) do
            if nextp:objectName() == player:objectName() then break end
            if nextp:hasFlag(flag) then break end
            room:setPlayerFlag(nextp, flag)
            room:askForDiscard(nextp, self:objectName(), 4, 4, false, false)
            nextp = nextp:getNextAlive()
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerFlag(p, "-"..flag)
        end

        if player:isAlive() then
            player:turnOver()
        end
    end
}

nyarz_shenfen_god = sgs.CreateTriggerSkill{
    name = "nyarz_shenfen_god",
    events = {sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_shenfen_godVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            room:askForUseCard(player, "@@nyarz_shenfen_god", "@nyarz_shenfen_god")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_kuangbao_god = sgs.CreateTriggerSkill{
    name = "nyarz_kuangbao_god",
    events = {sgs.Damage,sgs.Damaged,sgs.MarkChanged},
    frequency = sgs.Skill_Compulsory,
    waked_skills = "nyarz_wushuang_god,nyarz_shenji_god,nyarz_shenwei_god",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage or event == sgs.Damaged then
            if player:isDead() then return false end
            local num = data:toDamage().damage
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "&nyarz_baonu_god", num)
            room:getThread():delay()
        end
        if event == sgs.MarkChanged then
            local has = {}
            local hast = {}
            if player:getMark("&nyarz_baonu_god") < 3 then
                hast = {"nyarz_wushuang_god","nyarz_shenji_god","nyarz_shenwei_god"}
            elseif player:getMark("&nyarz_baonu_god") >= 3 and player:getMark("&nyarz_baonu_god") < 6 then
                has = {"nyarz_wushuang_god"}
                hast = {"nyarz_shenji_god","nyarz_shenwei_god"}
            elseif player:getMark("&nyarz_baonu_god") >= 6 and player:getMark("&nyarz_baonu_god") < 9 then
                has = {"nyarz_wushuang_god","nyarz_shenji_god"}
                hast = {"nyarz_shenwei_god"}
            else
                has = {"nyarz_wushuang_god","nyarz_shenji_god","nyarz_shenwei_god"}
            end
            for _,skill in ipairs(has) do
                if (not player:hasSkill(skill)) then
                    room:acquireSkill(player, skill, true)
                end
            end
            for _,skill in ipairs(hast) do
                if (player:hasSkill(skill)) then
                    room:detachSkillFromPlayer(player, skill)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_wushuang_god = sgs.CreateTriggerSkill{
    name = "nyarz_wushuang_god",
    events = {sgs.DamageCaused,sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("nyarz_wushuang_god_"..damage.to:objectName()) then
                local log = CreateDamageLog(damage, 1, "nyarz_wushuang_god", true)
                room:sendLog(log)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") or use.card:objectName() == "duel" then else return false end
            local choices = string.format("no=%s+up=%s", use.card:objectName(),use.card:objectName())
            if use.from:objectName() == player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:getThread():delay()
                local no_respond_list = use.no_respond_list

                for _,to in sgs.qlist(use.to) do
                    local choice = room:askForChoice(to, self:objectName(), choices, data)
                    if string.find(choice, "no") then
                        table.insert(no_respond_list, to:objectName())
                    else
                        room:setCardFlag(use.card, "nyarz_wushuang_god_"..to:objectName())
                    end
                end

                use.no_respond_list = no_respond_list
                data:setValue(use)
            elseif use.from:objectName() ~= player:objectName() and use.to:contains(player) and use.card:objectName() == "duel" then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:getThread():delay()
                local no_respond_list = use.no_respond_list

                local choice = room:askForChoice(use.from, self:objectName(), choices, data)
                if string.find(choice, "no") then
                    table.insert(no_respond_list, use.from:objectName())
                else
                    room:setCardFlag(use.card, "nyarz_wushuang_god_"..use.from:objectName())
                end

                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_shenji_god = sgs.CreateTargetModSkill{
    name = "nyarz_shenji_god",
    pattern = "Slash,Duel",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("nyarz_shenji_god") then return 1000 end
        return 0
    end,
    extra_target_func = function(self, from, card)
        if from:hasSkill("nyarz_shenji_god") then return 2 end
        return 0
    end,
}

nyarz_shenji_god_audio = sgs.CreateTriggerSkill{
    name = "#nyarz_shenji_god_audio",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") or use.card:objectName() == "duel" then
            if player:hasSkill("nyarz_shenji_god") and use.to:length() > 1 then
                room:broadcastSkillInvoke("nyarz_shenji_god")
                room:getThread():delay()
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_shenwei_god = sgs.CreateTriggerSkill{
    name = "nyarz_shenwei_god",
    events = {sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawNCards then
            if player:hasSkill("nyarz_shenwei_god") then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local draw = data:toDraw()
                if draw.reason ~= "draw_phase" then return false end
                draw.num = draw.num + 2
                data:setValue(draw)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_shenwei_god_max = sgs.CreateMaxCardsSkill{
    name = "#nyarz_shenwei_god_max",
    extra_func = function(self, target)
        if target:hasSkill("nyarz_shenwei_god") then return target:getLostHp() + 2 end
    end,
}

nyarz_lvbu_god:addSkill(nyarz_wumou_god)
nyarz_lvbu_god:addSkill(nyarz_wuqian_god)
nyarz_lvbu_god:addSkill(nyarz_wuqian_god_buff)
nyarz_lvbu_god:addSkill(nyarz_shenfen_god)
nyarz_lvbu_god:addSkill(nyarz_shenfen_godVS)
nyarz_lvbu_god:addSkill(nyarz_kuangbao_god)
extension:insertRelatedSkills("nyarz_wuqian_god", "#nyarz_wuqian_god_buff")
extension:insertRelatedSkills("nyarz_shenji_god", "#nyarz_shenji_god_audio")
extension:insertRelatedSkills("nyarz_shenwei_god", "#nyarz_shenwei_god_max")

nyarz_liuzan = sgs.General(extension, "nyarz_liuzan", "wu", 4, true, false, false)

nyarz_fenyin = sgs.CreateTriggerSkill{
    name = "nyarz_fenyin",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile then return false end
        room:addPlayerMark(player, "&nyarz_fenyin", move.card_ids:length())
        local num = 8
        if player:getPhase() ~= sgs.Player_NotActive then num = 4 end
        while((player:getMark("&nyarz_fenyin") >= num) and player:isAlive()) do
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:removePlayerMark(player, "&nyarz_fenyin", num)
            player:drawCards(1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_lijiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_liji",
    n = 99,
    response_pattern = "@@nyarz_liji",
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark("nyarz_liji")
    end,
    view_as = function(self, cards)
        if #cards == sgs.Self:getMark("nyarz_liji") then
            local cc = nyarz_lijiCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_lijiCard = sgs.CreateSkillCard
{
    name = "nyarz_liji",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isDead() then return false end
        room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Normal))
    end,
}

nyarz_liji = sgs.CreateTriggerSkill{
    name = "nyarz_liji",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_lijiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName()
        and player:isAlive() and move.to_place == sgs.Player_PlaceHand
        and player:getPhase() ~= sgs.Player_Draw then
            room:setPlayerMark(player, "nyarz_liji", move.card_ids:length())
            room:askForUseCard(player, "@@nyarz_liji", "@nyarz_liji:"..move.card_ids:length())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_liuzan:addSkill(nyarz_fenyin)
nyarz_liuzan:addSkill(nyarz_liji)
nyarz_liuzan:addSkill(nyarz_lijiVS)

nyarz_zhanghua = sgs.General(extension, "nyarz_zhanghua", "jin", 3, true, false, false)

nyarz_chuanwu = sgs.CreateTriggerSkill{
    name = "nyarz_chuanwu",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        local skills = {}
        for _,skill in sgs.qlist(player:getVisibleSkillList()) do
            if not skill:isAttachedLordSkill() then
                table.insert(skills, skill:objectName())
            end
        end

        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        local choice = room:askForChoice(player, self:objectName(), table.concat(skills, "+"))
        local all = player:getTag("nyarz_chuanwu"):toString():split("+")
        if (not all) or (#all <= 0) then all = {} end
        table.insert(all, choice)
        player:setTag("nyarz_chuanwu", sgs.QVariant(table.concat(all, "+")))
        room:detachSkillFromPlayer(player, choice)
        if player:isAlive() then player:drawCards(player:getAttackRange(), self:objectName()) end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_chuanwu_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_chuanwu_buff",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_NotActive then return false end
        for _,target in sgs.qlist(room:getAlivePlayers()) do
            local all = target:getTag("nyarz_chuanwu"):toString():split("+")
            if (not all) or (#all <= 0) then 
            else
                room:sendCompulsoryTriggerLog(target, "nyarz_chuanwu", true, true)
                for _,skill in ipairs(all) do
                    room:acquireSkill(target, skill)
                    if target:isDead() then break end
                end
                target:removeTag("nyarz_chuanwu")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_bihun = sgs.CreateTriggerSkill{
    name = "nyarz_bihun",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
        if player:isDead() then return false end
        if use.card:subcardsLength() <= 0 then return false end
        --if room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_PlaceHand then return false end
        local targets = sgs.SPlayerList()
        for _,to in sgs.qlist(use.to) do
            if to:isAlive() and to:objectName() ~= player:objectName() then targets:append(to) end
        end
        if targets:isEmpty() then return false end
        --room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@nyarz_bihun:"..use.card:objectName(), false, true)
        room:broadcastSkillInvoke(self:objectName())
        room:obtainCard(target, use.card, true)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_jianhe = sgs.CreateViewAsSkill
{
    name = "nyarz_jianhe",
    n = 999,
    view_filter = function(self, selected, to_select)
        if #selected > 0 then
            return getTypeString(selected[1]) == getTypeString(to_select)
        else
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards > 1 then
            local cc = nyarz_jianheCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end 
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

nyarz_jianheCard = sgs.CreateSkillCard
{
    name = "nyarz_jianhe",
    will_throw = false,
    filter = function(self, targets, to_select)
        local mark = string.format("&nyarz_jianhe_%s+#%s-PlayClear", "skill", sgs.Self:objectName())
        return #targets < 1 and to_select:getMark(mark) == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local player = effect.from

        local log = sgs.LogMessage()
        log.type = "$RecastCard"
        log.from = effect.from
        log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, effect.from:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        if player:isAlive() then player:drawCards(self:subcardsLength(), "recast") end
        if effect.to:isDead() then return false end
        local ctype = getTypeString(sgs.Sanguosha:getCard(self:getSubcards():at(0)))
        local prompt = string.format("@nyarz_jianhe:%s::%s:", self:subcardsLength(), ctype)

        if ctype == "BasicCard" then
            room:setPlayerMark(effect.to, "nyarz_jianhe_type", 1)
        elseif ctype == "TrickCard" then
            room:setPlayerMark(effect.to, "nyarz_jianhe_type", 2)
        else
            room:setPlayerMark(effect.to, "nyarz_jianhe_type", 3)
        end
        room:setPlayerMark(effect.to, "nyarz_jianhe", self:subcardsLength())

        local recast = room:askForExchange(effect.to, self:objectName(), self:subcardsLength(), self:subcardsLength(), true, prompt, true, ctype)
        if recast then
            local log2 = sgs.LogMessage()
            log2.type = "$RecastCard"
            log2.from = effect.to
            log2.card_str = table.concat(sgs.QList2Table(recast:getSubcards()), "+")
            room:sendLog(log2)

            local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, effect.to:objectName(), self:objectName(), "")
            local move1 = sgs.CardsMoveStruct(recast:getSubcards(), nil, sgs.Player_DiscardPile, reason1)
            room:moveCardsAtomic(move1, true)
            if effect.to:isAlive() then effect.to:drawCards(self:subcardsLength(), "recast") end
        else
            room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
        end
        if effect.to:isAlive() and effect.from:isAlive() then
            local items = {"card", "skill"}
            local choices = {}
            for _,item in ipairs(items) do
                local mark = string.format("&nyarz_jianhe_%s+#%s-PlayClear", item, effect.from:objectName())
                if effect.to:getMark(mark) <= 0 then
                    table.insert(choices, item)
                end
            end
            local data = sgs.QVariant()
            data:setValue(effect.to)
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)

            local log3 = sgs.LogMessage()
            log3.type = "$nyarz_jianhe_chosen"
            log3.from = effect.from
            log3.arg = "nyarz_jianhe:"..choice
            room:sendLog(log3)

            local mark = string.format("&nyarz_jianhe_%s+#%s-PlayClear", choice, effect.from:objectName())
            room:setPlayerMark(effect.to, mark, 1)
        end
    end 
}

nyarz_jianhe_buff = sgs.CreateProhibitSkill{
    name = "#nyarz_jianhe_buff",
    is_prohibited = function(self, from, to, card)
        if from and to and card and (not card:isKindOf("SkillCard")) then
            local mark = string.format("&nyarz_jianhe_%s+#%s-PlayClear", "card", from:objectName())
            return to:getMark(mark) > 0
        end
    end,
}

nyarz_zhanghua:addSkill(nyarz_chuanwu)
nyarz_zhanghua:addSkill(nyarz_chuanwu_buff)
nyarz_zhanghua:addSkill(nyarz_bihun)
nyarz_zhanghua:addSkill(nyarz_jianhe)
nyarz_zhanghua:addSkill(nyarz_jianhe_buff)
extension:insertRelatedSkills("nyarz_chuanwu", "#nyarz_chuanwu_buff")
extension:insertRelatedSkills("nyarz_jianhe", "#nyarz_jianhe_buff")

nyarz_zhaoyun_god = sgs.General(extension, "nyarz_zhaoyun_god", "god", 1, true)

nyarz_jvejin_god = sgs.CreateTriggerSkill{
    name = "nyarz_jvejin_god",
    events = {sgs.CardsMoveOneTime,sgs.HpChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand) and player:getHandcardNum() == 0 then
            else return false end
        end
        if player:getHandcardNum() < (4 + player:getMark("&nyarz_jvejin_god")) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local n = 4 + player:getMark("&nyarz_jvejin_god") - player:getHandcardNum()
            player:drawCards(n, self:objectName())
        elseif player:getMark("&nyarz_jvejin_god") < 3 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "&nyarz_jvejin_god", 1)
            player:setSkillDescriptionSwap("nyarz_jvejin_god", "%arg1", 4 + player:getMark("&nyarz_jvejin_god"))
            room:changeTranslation(player, "nyarz_jvejin_god", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

nyarz_longhun_god = sgs.CreateViewAsSkill
{
    name = "nyarz_longhun_god",
    n = 999,
    tiansuan_type = "fire_slash,jink,peach,nullification",
    view_filter = function(self, selected, to_select)
        for _,card in ipairs(selected) do
            if to_select:getSuit() ~= card:getSuit() then return false end
        end
        return #selected < (sgs.Self:getMark("&nyarz_longhun_god-Clear") + 2)
    end,
    view_as = function(self, cards)
        local pattern = sgs.Self:getTag("nyarz_longhun_god"):toString()
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local rpattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if string.find(rpattern, "Slash") or string.find(rpattern, "slash") then
                pattern = "fire_slash"
            elseif string.find(rpattern, "Jink") or string.find(rpattern, "jink") then
                pattern = "jink"
            elseif string.find(rpattern, "Peach") or string.find(rpattern, "peach") then
                pattern = "peach"
            elseif string.find(rpattern, "Nullification") or string.find(rpattern, "nullification") then
                pattern = "nullification"
            else
                return nil
            end
        end
        if #cards >= (1 + sgs.Self:getMark("&nyarz_longhun_god-Clear")) then
            local cc = nyarz_longhun_godCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            cc:setUserString(pattern)
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end,
    --[[enabled_at_nullification = function(self, player)
        return true
    end,]]
    enabled_at_response = function(self, player, pattern)
        if string.find(pattern, "Slash") or string.find(pattern, "slash") then
            return true
        elseif string.find(pattern, "Jink") or string.find(pattern, "jink") then
            return true
        elseif string.find(pattern, "Peach") or string.find(pattern, "peach") then
            return true
        elseif string.find(pattern, "Nullification") or string.find(pattern, "nullification") then
            return true
        else
            return false
        end
    end,
}

nyarz_longhun_godCard = sgs.CreateSkillCard
{
    name = "nyarz_longhun_god",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_longhun_god")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_longhun_god")
        card:deleteLater()

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if (not card:isAvailable(sgs.Self)) then return false end
        end

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
        local pattern = self:getUserString()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)

        if self:subcardsLength() == (player:getMark("&nyarz_longhun_god-Clear") + 1) then
            local log2 = sgs.LogMessage()
            log2.type = "$DiscardCard"
            log2.from = player
            log2.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log2)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
        else
            local log2 = sgs.LogMessage()
            log2.type = "$RecastCard"
            log2.from = player
            log2.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log2)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
            if player:isAlive() then player:drawCards(self:subcardsLength(), "recast") end
        end

        local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
        local suit = card:getSuitString()
        if pattern == "fire_slash" and suit ~= "diamond" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "jink" and suit ~= "club" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "peach" and suit ~= "heart" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "nullification" and suit ~= "spade" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        end


		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("_nyarz_longhun_god")
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)

        if self:subcardsLength() == (player:getMark("&nyarz_longhun_god-Clear") + 1) then
            local log2 = sgs.LogMessage()
            log2.type = "$DiscardCard"
            log2.from = player
            log2.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log2)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
        else
            local log2 = sgs.LogMessage()
            log2.type = "$RecastCard"
            log2.from = player
            log2.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log2)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
            if player:isAlive() then player:drawCards(self:subcardsLength(), "recast") end
        end

        local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
        local suit = card:getSuitString()
        if pattern == "fire_slash" and suit ~= "diamond" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "jink" and suit ~= "club" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "peach" and suit ~= "heart" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        elseif pattern == "nullification" and suit ~= "spade" then
            room:addPlayerMark(player, "&nyarz_longhun_god-Clear", 1)
        end


		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("_nyarz_longhun_god")
		return card
    end
}

nyarz_zhaoyun_god:addSkill(nyarz_jvejin_god)
nyarz_zhaoyun_god:addSkill(nyarz_longhun_god)

nyarz_luxun = sgs.General(extension, "nyarz_luxun", "wu", 3, true, false, false)

nyarz_lianying = sgs.CreateTriggerSkill{
    name = "nyarz_lianying",
    events = {sgs.CardsMoveOneTime,sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        --[[if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                room:setPlayerMark(player, "&nyarz_lianying", 0)
            end
        end]]
        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand) then
                if player:getHandcardNum() == 0 then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(player, "&nyarz_lianying", 1)
                        player:drawCards(player:getMaxCards(), self:objectName())
                    end
                end
            end
        end
        if event == sgs.Damaged then
            room:addPlayerMark(player, "nyarz_lianying_damage-Clear", 1)
            if player:getMark("nyarz_lianying_damage-Clear") == 2 then 
                room:setPlayerMark(player, "&nyarz_lianying", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

nyarz_lianying_buff = sgs.CreateMaxCardsSkill{
    name = "#nyarz_lianying_buff",
    extra_func = function(self, target)
        return target:getMark("&nyarz_lianying")
    end,
}

nyarz_duoshiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_duoshi",
    n = 99,
    view_filter = function(self, selected, to_select)
        --if sgs.Sanguosha:getCurrentCardUsePattern() == "@@nyarz_duoshi-put" then
            return #selected < 2 and sgs.Self:getHandcards():contains(to_select)
        --[[else
            return #selected < 1 and to_select:isAvailable(sgs.Self)
            and sgs.Self:getPile("nyarz_duoshi"):contains(to_select:getEffectiveId())
        end]]
    end,
    view_as = function(self, cards)
        --if sgs.Sanguosha:getCurrentCardUsePattern() == "@@nyarz_duoshi-put" then
            if #cards > 0 then
                local cc = nyarz_duoshiCard:clone()
                for _,c in ipairs(cards) do
                    cc:addSubcard(c)
                end
                return cc
            end
        --[[else
            if #cards == 1 then
                return cards[1]
            end
        end]]
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@nyarz_duoshi" 
    end

}

nyarz_duoshi_use = sgs.CreateViewAsSkill
{
    name = "nyarz_duoshi_use&",
    n = 99,
    expand_pile = "nyarz_duoshi",
    response_pattern = "@@nyarz_duoshi_use",
    view_filter = function(self, selected, to_select)
        return #selected < 1 and to_select:isAvailable(sgs.Self)
            and sgs.Self:getPile("nyarz_duoshi"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            return cards[1]
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_duoshiCard = sgs.CreateSkillCard
{
    name = "nyarz_duoshi",
    will_throw = false,
    filter = function(self, selected, to_select)
        return #selected < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets, player)
        return #targets <= 1
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if #targets > 0 then
            room:obtainCard(targets[1], self, false)
        else
            source:addToPile("nyarz_duoshi", self:getSubcards())
        end
    end
}

nyarz_duoshi = sgs.CreateTriggerSkill{
    name = "nyarz_duoshi",
    events = {sgs.TargetConfirmed,sgs.EventPhaseStart,sgs.EventAcquireSkill,sgs.GameStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_duoshiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            if (not player:hasSkill(self:objectName())) then return false end
            local use = data:toCardUse()
            if (not use.from) then return false end
            if use.card:isKindOf("SkillCard") then return false end
            if use.to:contains(player) then
                room:setTag("nyarz_duoshi", data)
                room:askForUseCard(player, "@@nyarz_duoshi", "@nyarz_duoshi-put")
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:isAlive() and p:hasSkill(self:objectName())
                and p:getPile("nyarz_duoshi"):length() > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    while(p:isAlive() and (p:getPile("nyarz_duoshi"):length() > 0)) do
                        if (not room:askForUseCard(p, "@@nyarz_duoshi_use", "@nyarz_duoshi-use")) then break end
                    end
                    if p:getPile("nyarz_duoshi"):length() > 0 then
                        local log = sgs.LogMessage()
                        log.type = "$EnterDiscardPile"
                        log.card_str = table.concat(sgs.QList2Table(p:getPile("nyarz_duoshi")), "+")
                        room:sendLog(log)

                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, p:objectName(), self:objectName(), "")
                        local move = sgs.CardsMoveStruct(p:getPile("nyarz_duoshi"), nil, sgs.Player_DiscardPile, reason)
                        room:moveCardsAtomic(move, true)
                    end
                end
            end
        end
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            if (not player:hasSkill("nyarz_duoshi_use")) then
                room:attachSkillToPlayer(player, "nyarz_duoshi_use")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_luxun:addSkill(nyarz_lianying)
nyarz_luxun:addSkill(nyarz_lianying_buff)
nyarz_luxun:addSkill(nyarz_duoshi)
nyarz_luxun:addSkill(nyarz_duoshiVS)
extension:insertRelatedSkills("nyarz_lianying", "#nyarz_lianying_buff")

nyarz_hanfu = sgs.General(extension, "nyarz_hanfu", "qun", 4, true, false, false)

nyarz_jieying = sgs.CreateTriggerSkill{
    name = "nyarz_jieying",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("nyarz_jieying_damage-PlayClear") > 0 then return false end
        room:setPlayerMark(player, "nyarz_jieying_damage-PlayClear", 1)
        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:getMark("nyarz_jieying_lun") == 0 then
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("end:"..player:getGeneralName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(p, "nyarz_jieying_lun", 1)
                    room:setPlayerMark(p, "&nyarz_jieying_lun", 1)
                    room:damage(sgs.DamageStruct(self:objectName(), p, player, 1, sgs.DamageStruct_Normal))
                    if player:isAlive() then
                        player:endPlayPhase()
                        return false
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Play
        and target:isAlive()
    end,
}

nyarz_weipo = sgs.CreateTriggerSkill{
    name = "nyarz_weipo",
    events = {sgs.TargetConfirmed,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            if player:getMark("nyarz_weipo-Clear") > 0 then return false end
            local use = data:toCardUse()
            if (not use.card:isKindOf("SkillCard")) and (use.to:contains(player)) then
                room:setPlayerMark(player, "nyarz_weipo-Clear", 1)
                room:setPlayerMark(player, "&nyarz_weipo-Clear", 1)
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local card = room:askForExchange(player, self:objectName(), 9999, 1, true, "@nyarz_weipo", true)
                    if card and card:getSubcards():length() > 0 then

                        local log = sgs.LogMessage()
                        log.type = "$RecastCard"
                        log.from = player
                        log.card_str = table.concat(sgs.QList2Table(card:getSubcards()), "+")
                        room:sendLog(log)
            
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                        local move = sgs.CardsMoveStruct(card:getSubcards(), nil, sgs.Player_DiscardPile, reason)
                        room:moveCardsAtomic(move, true)
                        if player:isAlive() then player:drawCards(card:subcardsLength(), "recast") end
                    elseif player:getHandcardNum() < player:getMaxHp() then
                        local n = player:getMaxHp() - player:getHandcardNum()
                        player:drawCards(n, self:objectName())
                    end
                end
            end
        end
        if event == sgs.Damaged then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local card = room:askForExchange(player, self:objectName(), 9999, 1, true, "@nyarz_weipo", true)
                if card and card:getSubcards():length() > 0 then

                    local log = sgs.LogMessage()
                    log.type = "$RecastCard"
                    log.from = player
                    log.card_str = table.concat(sgs.QList2Table(card:getSubcards()), "+")
                    room:sendLog(log)
        
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                    local move = sgs.CardsMoveStruct(card:getSubcards(), nil, sgs.Player_DiscardPile, reason)
                    room:moveCardsAtomic(move, true)
                    if player:isAlive() then player:drawCards(card:subcardsLength(), "recast") end
                elseif player:getHandcardNum() < player:getMaxHp() then
                    local n = player:getMaxHp() - player:getHandcardNum()
                    player:drawCards(n, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

nyarz_hanfu:addSkill(nyarz_jieying)
nyarz_hanfu:addSkill(nyarz_weipo)

nyarz_zhangzhi = sgs.General(extension, "nyarz_zhangzhi", "qun", 3, true, false, false)

nyarz_bixin = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_bixin",
    view_as = function(self)
        local pattern
        local cc = nyarz_bixinCard:clone()
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            pattern = sgs.Self:getTag("nyarz_bixin"):toCard():objectName()
            cc:setUserString(pattern)
        else
            pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            cc:setUserString(pattern)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return (not player:isKongcheng())
    end,
    enabled_at_response = function(self, player, pattern)
        if player:isKongcheng() then return false end
        local basics = {"slash", "jink", "peach", "analeptic", "Jink", "Slash"}
        for _,basic in ipairs(basics) do
            if string.find(pattern, basic) then
                return true
            end
        end
        return false
    end
        
}
nyarz_bixin:setGuhuoDialog("l")

nyarz_bixinCard = sgs.CreateSkillCard
{
    name = "nyarz_bixin",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then pattern = "peach" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_bixin")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then pattern = "peach" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_bixin")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)

        local types = {"BasicCard","TrickCard","EquipCard"}
        local used = {}
        local n = 0
        for _,ctype in ipairs(types) do
            if player:getMark("nyarz_bixin_"..ctype.."_lun") == 0 then
                n = n + 1 
            else
                table.insert(used, ctype)
            end
        end

        local choices = {}
        for _,card in sgs.qlist(player:getHandcards()) do
            local ctype = types[card:getTypeId()]
            if ctype and (not table.contains(choices, ctype)) then
                table.insert(choices, ctype)
            end
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), table.concat(used, "+"), "nyarz_bixin_prompt")
        room:setPlayerMark(player, "nyarz_bixin_"..choice.."_lun", 1)
        player:drawCards(n, self:objectName())

        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())

        for _,cc in sgs.qlist(player:getHandcards()) do
            if cc:isKindOf(choice) then
                card:addSubcard(cc)
            end
        end

		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)

        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then 
            pattern = room:askForChoice(player, "nyarz_bixin_slash", "slash+fire_slash+thunder_slash+ice_slash")
        end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then 
            pattern = room:askForChoice(player, "nyarz_bixin_saveself", "peach+analeptic")
        end

        local types = {"BasicCard","TrickCard","EquipCard"}
        local used = {}
        local n = 0
        for _,ctype in ipairs(types) do
            if player:getMark("nyarz_bixin_"..ctype.."_lun") == 0 then
                n = n + 1 
            else
                table.insert(used, ctype)
            end
        end

        local choices = {}
        for _,card in sgs.qlist(player:getHandcards()) do
            local ctype = types[card:getTypeId()]
            if ctype and (not table.contains(choices, ctype)) then
                table.insert(choices, ctype)
            end
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), table.concat(used, "+"), "nyarz_bixin_prompt")
        room:setPlayerMark(player, "nyarz_bixin_"..choice.."_lun", 1)
        player:drawCards(n, self:objectName())

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())

        for _,cc in sgs.qlist(player:getHandcards()) do
            if cc:isKindOf(choice) then
                card:addSubcard(cc)
            end
        end

		return card
    end
}

nyarz_ximo = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_ximo",
    view_as = function(self)
        return nyarz_ximoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyarz_ximo-PlayClear") == 0
    end
}

nyarz_ximoCard = sgs.CreateSkillCard
{
    name = "nyarz_ximo",
    filter = function(self, targets, to_select)
        return (not to_select:isNude()) and #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = room:askForCardChosen(effect.from, effect.to, "he", self:objectName())

        local log = sgs.LogMessage()
        log.from = effect.to
        log.type = "$RecastCard"
        log.card_str = tostring(card)
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, effect.from:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(card, nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        if effect.to:isAlive() then effect.to:drawCards(1, "recast") end
        if not sgs.Sanguosha:getCard(card):isBlack() then
            local prompt = string.format("@nyarz_ximo:%s",sgs.Sanguosha:getCard(card):objectName())
            local target = room:askForPlayerChosen(effect.from, room:getAlivePlayers(), self:objectName(), prompt, false, true)
            room:obtainCard(target, card, true)
            if effect.from:isAlive() then
                room:setPlayerMark(effect.from, "nyarz_ximo-PlayClear", 1)
                room:setPlayerMark(effect.from, "&nyarz_ximo+fail+-PlayClear", 1)
            end
        end
    end
}

nyarz_feibai = sgs.CreateTriggerSkill{
    name = "nyarz_feibai",
    events = {sgs.DamageCaused,sgs.PreHpRecover},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            if (not player:hasSkill(self:objectName())) then return false end
            local damage = data:toDamage()
            if (not damage.card) or (damage.card:isKindOf("SkillCard")) 
            or damage.card:isRed() or damage.card:isBlack() then return false end
            local log = CreateDamageLog(damage, 1, self:objectName(), true)
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
        if event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill(self:objectName())
            and recover.card and ((not recover.card:isBlack()) and (not recover.card:isRed())) then
                local log = sgs.LogMessage()
                log.type = "$nyarz_feibai_recover"
                log.from = recover.who
                log.to:append(player)
                log.arg = self:objectName()
                log.arg2 = recover.recover
                log.arg3 = recover.recover + 1
                room:sendLog(log)
                room:broadcastSkillInvoke(self:objectName())
                recover.recover = recover.recover + 1
                data:setValue(recover)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_zhangzhi:addSkill(nyarz_bixin)
nyarz_zhangzhi:addSkill(nyarz_ximo)
nyarz_zhangzhi:addSkill(nyarz_feibai)

nyarz_guanyu = sgs.General(extension, "nyarz_guanyu", "shu", 4, true, false, false)

nyarz_wushengVS = sgs.CreateViewAsSkill
{
    name = "nyarz_wusheng",
    n = 99,
    view_filter = function(self, selected, to_select)
        return #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = nyarz_wushengCard:clone()
            cc:addSubcard(cards[1])
            cc:setUserString("Slash")
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("nyarz_wusheng") then return false end
        end
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("nyarz_wusheng") then return false end
        end
        return string.find(pattern, "slash") or string.find(pattern, "Slash")
    end
}

nyarz_wushengCard = sgs.CreateSkillCard
{
    name = "nyarz_wusheng",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wusheng")
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wusheng")
        card:addSubcards(self:getSubcards())
        card:deleteLater()

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, self:objectName(), table.concat(all,"+"))
        end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wusheng")
        card:addSubcards(self:getSubcards())
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, self:objectName(), table.concat(all,"+"))
        end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_wusheng")
        card:addSubcards(self:getSubcards())
		return card
    end
}

nyarz_wusheng = sgs.CreateTriggerSkill{
    name = "nyarz_wusheng",
    events = {sgs.EventPhaseStart,sgs.Damage,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_wushengVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf("Slash") then
                        room:obtainCard(player, card, true)
                        if room:getCardOwner(id):objectName() == player:objectName() then
                            room:setCardFlag(card, "nyarz_wusheng")
                            room:setCardFlag(card, "RemoveFromHistory")
                            room:setCardTip(id, "nyarz_wusheng")
                        end
                        break
                    end
                end
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("nyarz_wusheng") then
                room:broadcastSkillInvoke(self:objectName())
            end
        end
        if event == sgs.Damage then
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("nyarz_wusheng") then return false end
            end
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:getHp() ~= 1 
            and damage.to:objectName() ~= player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerProperty(damage.to, "hp", sgs.QVariant(1))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_wusheng_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_wusheng_buff",
    residue_func = function(self, from, card)
        if card:hasFlag("nyarz_wusheng") then return 1000 end
        return 0
    end,
}

nyarz_yijve = sgs.CreateTriggerSkill{
    name = "nyarz_yijve",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        local damage = dying.damage
        if damage and damage.from:objectName() ~= player:objectName()
        and damage.from:hasSkill(self:objectName()) then
            room:removeTag("nyarz_yijve")
            room:setTag("nyarz_yijve", data)
            if player:getMark("&nyarz_yijve+#"..damage.from:objectName()) == 0 then
                if room:askForSkillInvoke(damage.from, self:objectName(), sgs.QVariant("recover:"..player:objectName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    local _player = sgs.SPlayerList()
                    _player:append(damage.from)
                    room:setPlayerMark(player, "&nyarz_yijve+#"..damage.from:objectName(), 1, _player)
                    if player:getHp() >= 1 then return false end
                    room:recover(player, sgs.RecoverStruct(self:objectName(), damage.from, 1 - player:getHp()))
                end
            else
                if room:askForSkillInvoke(damage.from, self:objectName(), sgs.QVariant("death:"..player:objectName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    local judge = sgs.JudgeStruct()
                    judge.who = player
                    judge.reason = self:objectName()
                    judge.good = true
                    judge.pattern = "Peach,GodSalvation"
                    room:judge(judge)
                    if (not judge:isGood()) then
                        room:killPlayer(player, dying.damage)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_guanyu:addSkill(nyarz_wusheng)
nyarz_guanyu:addSkill(nyarz_wushengVS)
nyarz_guanyu:addSkill(nyarz_wusheng_buff)
nyarz_guanyu:addSkill(nyarz_yijve)
extension:insertRelatedSkills("nyarz_wusheng", "#nyarz_wusheng_buff")

nyarz_guanyu_win = sgs.CreateTriggerSkill{
    name = "nyarz_guanyu_win",
    events = {sgs.GameOver},
    frequency = sgs.Skill_NotFrequent,
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toString():split("+")
        for audio,target in sgs.qlist(room:getAlivePlayers()) do
            if (table.contains(winner, target:objectName()) or table.contains(winner, target:getRole())) 
            and target:getGeneralName() == "nyarz_guanyu" then
                room:broadcastSkillInvoke(self:objectName())
                room:getThread():delay(500)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyarz_zhaoyun = sgs.General(extension, "nyarz_zhaoyun", "shu", 4, true, false, false)

nyarz_duwang = sgs.CreateTriggerSkill{
    name = "nyarz_duwang",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card 
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        else
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if (not card) then return false end
        if card:isKindOf("SkillCard") then return false end
        local marks = {"&nyarz_duwang_basic","&nyarz_duwang_nobasic"}
        if card:isKindOf("BasicCard") then
            for _,mark in ipairs(marks) do
                room:setPlayerMark(player, mark, 0)
            end
            room:setPlayerMark(player, "&nyarz_duwang_basic", 1)
        end
        if (not card:isKindOf("BasicCard")) then
            local draw = false
            if player:getMark("&nyarz_duwang_basic") > 0 then
                draw = true 
            end
            for _,mark in ipairs(marks) do
                room:setPlayerMark(player, mark, 0)
            end
            room:setPlayerMark(player, "&nyarz_duwang_nobasic", 1)
            if draw then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_duwang_buff = sgs.CreateTargetModSkill
{
    name = "#nyarz_duwang_buff",
    pattern = "BasicCard",
    residue_func = function(self, from, card)
        if from:hasSkill("nyarz_duwang") and from:getMark("&nyarz_duwang_nobasic") > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill("nyarz_duwang") and from:getMark("&nyarz_duwang_nobasic") > 0 then return 1000 end
        return 0
    end,
}

nyarz_longdanVS = sgs.CreateViewAsSkill
{
    name = "nyarz_longdan",
    n = 99,
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_longdan_mark",
    view_filter = function(self, selected, to_select)
        return #selected < 2
    end,
    view_as = function(self, cards)
        if #cards >= 1 then
            local cc = nyarz_longdanCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
                cc:setUserString("Slash")
            else
                local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
                if string.find(pattern, "Slash") or string.find(pattern, "slash") then
                    cc:setUserString("Slash")
                else
                    cc:setUserString("jink")
                end
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@nyarz_longdan_mark") > 0
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark("@nyarz_longdan_mark") > 0
        and (string.find(pattern, "Slash") or string.find(pattern, "slash")
        or string.find(pattern, "Jink") or string.find(pattern, "jink"))
    end,
}

nyarz_longdanCard = sgs.CreateSkillCard
{
    name = "nyarz_longdan",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()
        room:setPlayerMark(player, "@nyarz_longdan_mark", 0)

        local log1 = sgs.LogMessage()
        log1.type = "#InvokeSkill"
        log1.from = player
        log1.arg = self:objectName()
        room:sendLog(log1)
        room:broadcastSkillInvoke(self:objectName())

        local log = sgs.LogMessage()
        log.from = player
        log.type = "$RecastCard"
        log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        if player:isAlive() then player:drawCards(self:subcardsLength(), "recast") end

        room:getThread():delay(300)

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, self:objectName(), table.concat(all,"+"))
        end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        room:setCardFlag(card, "nyarz_longdan")
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()
        room:setPlayerMark(player, "@nyarz_longdan_mark", 0)

        local log1 = sgs.LogMessage()
        log1.type = "#InvokeSkill"
        log1.from = player
        log1.arg = self:objectName()
        room:sendLog(log1)
        room:broadcastSkillInvoke(self:objectName())

        local log = sgs.LogMessage()
        log.from = player
        log.type = "$RecastCard"
        log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        if player:isAlive() then player:drawCards(self:subcardsLength(), "recast") end

        room:getThread():delay(300)

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, self:objectName(), table.concat(all,"+"))
        end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        room:setCardFlag(card, "nyarz_longdan")
		return card
    end
}

nyarz_longdan = sgs.CreateTriggerSkill{
    name = "nyarz_longdan",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_longdan_mark",
    view_as_skill = nyarz_longdanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or (not card:isKindOf("BasicCard")) then return false end
        if card:hasFlag("nyarz_longdan") then return false end
        if player:getMark("@nyarz_longdan_mark") == 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:setPlayerMark(player, "@nyarz_longdan_mark", 1)
            player:drawCards(1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhaoyun:addSkill(nyarz_duwang)
nyarz_zhaoyun:addSkill(nyarz_duwang_buff)
nyarz_zhaoyun:addSkill(nyarz_longdan)
nyarz_zhaoyun:addSkill(nyarz_longdanVS)
extension:insertRelatedSkills("nyarz_duwang", "#nyarz_duwang_buff")

nyarz_lvfan = sgs.General(extension, "nyarz_lvfan", "wu", 3, true, false, false)

nyarz_diaodu = sgs.CreateTriggerSkill{
    name = "nyarz_diaodu",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card 
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or (not card:isKindOf("EquipCard")) then return false end
            for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() then
                    if room:getTag("nyarz_diaodu") then room:removeTag("nyarz_diaodu") end
                    local tag = sgs.QVariant()
                    tag:setValue(player)
                    room:setTag("nyarz_diaodu", tag)

                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("draw:"..player:getGeneralName())) then
                        room:broadcastSkillInvoke(self:objectName())
                        p:drawCards(1, self:objectName())
                        if player:isAlive() then player:drawCards(1, self:objectName()) end
                    end
                end
                if player:isDead() then break end
            end
        end
        if event == sgs.EventPhaseStart then
            if (not player:hasSkill(self:objectName())) and player:getMark("tem_nyarz_diaodu") == 0 then return false end
            if player:getPhase() == sgs.Player_Start
            or player:getPhase() == sgs.Player_Finish
            or player:getMark("tem_nyarz_diaodu") > 0 then
                room:setPlayerMark(player, "tem_nyarz_diaodu", 0)
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if (not p:isNude()) then targets:append(p) end
                end
                if targets:isEmpty() then return false end
                local target = room:askForPlayerChosen(player, targets, "nyarz_diaodu_get", "@nyarz_diaodu-get", true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    local card = room:askForCardChosen(player, target, "hej", self:objectName())
                    room:obtainCard(player, card, false)
                    if player:isAlive() then
                        local tos = room:getOtherPlayers(target)
                        if tos:isEmpty() then return false end
                        local prompt = string.format("@nyarz_diaodu-give:%s::%s:", sgs.Sanguosha:getCard(card):objectName(), target:getGeneralName())
                        local to = room:askForPlayerChosen(player, tos, "nyarz_diaodu_give", prompt, false, false)
                        if to:objectName() ~= player:objectName() then
                            room:obtainCard(to, card, false)
                        end
                        if to:isAlive() and sgs.Sanguosha:getCard(card):isKindOf("EquipCard") 
                        and room:getCardOwner(card):objectName() == to:objectName() then
                            local prompt2 = string.format("@nyarz_diaodu-use:%s:", sgs.Sanguosha:getCard(card):objectName())
                            room:askForUseCard(to, sgs.Sanguosha:getCard(card):toString(), prompt2)
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

nyarz_diancai = sgs.CreateTriggerSkill{
    name = "nyarz_diancai",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if (not player:hasSkill(self:objectName())) then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                room:setPlayerMark(player, "nyarz_diancai", 1)
            end
        end
        if event == sgs.EventPhaseEnd then
            for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("nyarz_diancai") > 0 and p:isAlive() then
                    room:setPlayerMark(p, "tem_nyarz_diaodu", 1)
                    if p:getHandcardNum() >= p:getMaxHp() and p:getPhase() ~= sgs.Player_NotActive then continue end
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("draw")) then
                        room:broadcastSkillInvoke(self:objectName())
                        if p:getHandcardNum() < p:getMaxHp() then
                            p:drawCards(p:getMaxHp() - p:getHandcardNum(), self:objectName())
                        end
                        if p:isAlive() and p:getPhase() == sgs.Player_NotActive then
                            local skill = sgs.Sanguosha:getTriggerSkill("nyarz_diaodu")
                            skill:trigger(sgs.EventPhaseStart, room, p, data)
                        end
                    end
                end
            end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "tem_nyarz_diaodu", 0)
                room:setPlayerMark(p, "nyarz_diancai", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_lvfan:addSkill(nyarz_diaodu)
nyarz_lvfan:addSkill(nyarz_diancai)

nyarz_xiahoumao = sgs.General(extension, "nyarz_xiahoumao", "wei", 4, true, false, false)

nyarz_cuguo = sgs.CreateTriggerSkill{
    name = "nyarz_cuguo",
    --events = {sgs.SlashMissed,sgs.PostCardEffected,sgs.TrickEffect},
    events = {sgs.CardOffset},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local effect = data:toCardEffect()
        if player:getMark("nyarz_cuguo-Clear") > 0 then 
            if effect.card:hasFlag("nyarz_cuguo"..effect.to:objectName()) then
                room:setCardFlag(effect.card, "-nyarz_cuguo"..effect.to:objectName())
                room:askForDiscard(player, self:objectName(), 1, 1, false, false)
            end
        end
        if player:getMark("nyarz_cuguo-Clear") == 0 then 
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "nyarz_cuguo-Clear", 1)
            room:setCardFlag(effect.card, "nyarz_cuguo"..effect.to:objectName())
            local log = sgs.LogMessage()
            log.type = "$nyarz_cuguo_effect"
            log.to:append(effect.to)
            log.card_str = effect.card:toString()
            room:sendLog(log)
            room:cardEffect(effect.card, player, effect.to)
        end
        --[[if (event == sgs.SlashMissed) and player:hasSkill(self:objectName()) then
            local effect = data:toSlashEffect()
            room:addPlayerMark(player, "nyarz_cuguo-Clear", 1)
            if effect.slash:hasFlag("nyarz_cuguo_"..effect.to:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setCardFlag(effect.slash, "-nyarz_cuguo_"..effect.to:objectName())
                room:askForDiscard(effect.from, self:objectName(), 1, 1, false, true)
            end
            --if player:isNude() then return false end
            if effect.to:isDead() then return false end
            if player:getMark("nyarz_cuguo-Clear") == 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setCardFlag(effect.slash, "nyarz_cuguo_"..effect.to:objectName())
                --room:cardEffect(effect.slash, player, effect.to)
                local log = sgs.LogMessage()
                log.type = "$nyarz_cuguo_effect"
                log.to:append(effect.to)
                log.card_str = effect.slash:toString()
                room:sendLog(log)

                room:slashEffect(effect)
            end
        end
        if (event == sgs.TrickEffect) then
            --若生效，给牌一个flag
            local effect = data:toCardEffect()
            if effect.card:isKindOf("TrickCard") then
                room:setCardFlag(effect.card,"cuguoeffct")
            end
        end
        if (event == sgs.PostCardEffected) then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("TrickCard") and effect.from and effect.from:hasSkill(self:objectName()) then
                if not effect.card:hasFlag("cuguoeffct") then
                    room:addPlayerMark(effect.from, "nyarz_cuguo-Clear", 1)
                    if effect.card:hasFlag("reeffct") then
                        room:sendCompulsoryTriggerLog(effect.from, self:objectName(), true, true)
                        room:setCardFlag(effect.card, "-reeffct")
                        room:askForDiscard(effect.from, self:objectName(), 1, 1, false, true)
                    end
                    if effect.from:isNude() then return false end
                    if effect.to:isDead() then return false end
                    if (effect.from:getMark("nyarz_cuguo-Clear") == 1) then
                        room:sendCompulsoryTriggerLog(effect.from, self:objectName(), true, true)
                        room:setCardFlag(effect.card, "reeffct")
                        
                        local log = sgs.LogMessage()
                        log.type = "$nyarz_cuguo_effect"
                        log.to:append(effect.to)
                        log.card_str = effect.card:toString()
                        room:sendLog(log)

                        room:cardEffect(effect.card, effect.from, effect.to)
                    end
                end
            end
        end]]

    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName())
    end,
}

nyarz_tongwei = sgs.CreateViewAsSkill
{
    name = "nyarz_tongwei",
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local card = nyarz_tongweiCard:clone()
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        --return true
        return not player:hasUsed("#nyarz_tongwei")
    end
}

nyarz_tongweiCard = sgs.CreateSkillCard
{
    name = "nyarz_tongwei",
    will_throw = false,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName()
        and #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local source = effect.from

        local log = sgs.LogMessage()
        log.from = source
        log.type = "$RecastCard"
        log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), "")
        room:moveCardTo(self, nil, nil, sgs.Player_DiscardPile, reason)

        if source:isDead() then return false end

        source:drawCards(self:subcardsLength(), "recast")
        
        if source:isDead() then return false end
        if effect.to:isDead() then return false end

        if effect.to:getMark("nyarz_tongwei+"..source:objectName()) > 0 then
            local max = effect.to:getMark("nyarz_tongwei_max+"..source:objectName())
            local min = effect.to:getMark("nyarz_tongwei_min+"..source:objectName())
            local mark = string.format("&nyarz_tongwei+%s+~+%s+#%s",min,max,source:objectName())
            room:setPlayerMark(effect.to, mark, 0)
            room:removePlayerMark(effect.to, "nyarz_tongwei", 1)
        end

        local max = 1
        local min = 13
        for _,id in sgs.qlist(self:getSubcards()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:getNumber() < min then min = card:getNumber() end
            if card:getNumber() > max then max = card:getNumber() end
        end

        local mark = string.format("&nyarz_tongwei+%s+~+%s+#%s",min,max,source:objectName())
        room:setPlayerMark(effect.to, mark, 1)
        room:setPlayerMark(effect.to, "nyarz_tongwei+"..source:objectName(), 1)
        room:addPlayerMark(effect.to, "nyarz_tongwei", 1)
        room:setPlayerMark(effect.to, "nyarz_tongwei_max+"..source:objectName(), max)
        room:setPlayerMark(effect.to, "nyarz_tongwei_min+"..source:objectName(), min)
    end
}

local function NYtongweiTricks(room, from, to)
    local tricks = {}
    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isNDTrick() and (not table.contains(tricks, card:objectName())) then
            table.insert(tricks, card:objectName())
        end
    end
    local can = {}
    local cant = {}
    for _,trick in ipairs(tricks) do
        local card = sgs.Sanguosha:cloneCard(trick, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("nyarz_tongwei")
        card:deleteLater()
        if card:isAvailable(from) and room:getCardTargets(from, card):contains(to) then
            table.insert(can, trick)
        else 
            table.insert(cant, trick)
        end
    end
    return can, cant
end

nyarz_tongwei_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_tongwei_buff",
    events = {sgs.CardFinished,sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if table.contains(use.card:getSkillNames(), "nyarz_tongwei") then
                local tos = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if use.card:hasFlag("nyarz_tongwei+"..p:objectName()) then
                        tos:append(p)
                    end
                end
                if use.card:objectName() == "collateral" and tos:length() > 0 then
                    local target = tos:at(0)
                    local targets = sgs.SPlayerList()
                    for _,p in sgs.qlist(room:getOtherPlayers(target)) do
                        if target:inMyAttackRange(p) then
                            targets:append(p)
                        end
                    end
                    if (not targets:isEmpty()) then
                        local to = room:askForPlayerChosen(player, targets, self:objectName(), "@nyarz_tongwei-collateral", false, false)
                        --tos:append(to)

                        local tag = sgs.QVariant()
                        --tag:setValue(to)
                        target:setTag("collateralVictim", tag)
                    end
                end
                if (not tos:isEmpty())  then
                    use.to = tos
                    data:setValue(use)
                end
            end
            return false 
        end

        if player:getMark("nyarz_tongwei") <= 0 then return false end

        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        local num = use.card:getNumber()
        room:setPlayerMark(player, "nyarz_tongwei", 0)

        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isAlive() and player:getMark("nyarz_tongwei+"..p:objectName()) > 0 then
                room:setPlayerMark(player, "nyarz_tongwei+"..p:objectName(), 0)
                room:sendCompulsoryTriggerLog(p, "nyarz_tongwei", true)

                local max = player:getMark("nyarz_tongwei_max+"..p:objectName())
                local min = player:getMark("nyarz_tongwei_min+"..p:objectName())
                local mark = string.format("&nyarz_tongwei+%s+~+%s+#%s",min,max,p:objectName())
                room:setPlayerMark(player, mark, 0)

                if num >= min and num <= max then
                    local can, cant = NYtongweiTricks(room, p, player)
                    local types = {}
                    if (not can) or (#can <= 0) then types = "Slash"
                    else types = "Slash+Trick" end
                    local ctype =  room:askForChoice(p, "nyarz_tongwei", types, data)
                    local pattern 
                    if ctype == "Slash" then
                        pattern = room:askForChoice(p, "nyarz_tongwei_slash", "slash+thunder_slash+fire_slash", data)
                    else
                        pattern = room:askForChoice(p, "nyarz_tongwei_trick", table.concat(can, "+"), data, table.concat(cant, "+"))
                    end
                    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
                    card:setSkillName("_nyarz_tongwei")
                    card:deleteLater()
                    room:setCardFlag(card, "nyarz_tongwei+"..player:objectName())
                    room:useCard(sgs.CardUseStruct(card, p, player))
                else
                    room:broadcastSkillInvoke("nyarz_tongwei")
                end
            end
            if player:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_tongwei_dis = sgs.CreateTargetModSkill{
    name = "#nyarz_tongwei_dis",
    pattern = ".",
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "nyarz_tongwei") then return 1000 end
        return 0
    end,
}

nyarz_xiahoumao:addSkill(nyarz_cuguo)
nyarz_xiahoumao:addSkill(nyarz_tongwei)
nyarz_xiahoumao:addSkill(nyarz_tongwei_buff)
nyarz_xiahoumao:addSkill(nyarz_tongwei_dis)
extension:insertRelatedSkills("nyarz_tongwei", "#nyarz_tongwei_buff")
extension:insertRelatedSkills("nyarz_tongwei", "#nyarz_tongwei_dis")

nyarz_duyu = sgs.General(extension, "nyarz_duyu", "jin", 4, true, false, false)

nyarz_zhaotao = sgs.CreateTriggerSkill{
    name = "nyarz_zhaotao",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and (not use.card:isKindOf("SkillCard")) then
                local views = sgs.SPlayerList()
                views:append(player)
                room:addPlayerMark(player, "&nyarz_zhaotao-Clear", 1, views)
            end
        end
        if event == sgs.CardResponded then 
            local response = data:toCardResponse()
            if response.m_isUse and response.m_card and (not response.m_card:isKindOf("SkillCard")) then
                local views = sgs.SPlayerList()
                views:append(player)
                room:addPlayerMark(player, "&nyarz_zhaotao-Clear", 1, views)
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName()
            and (not use.card:isKindOf("SkillCard")) then
                if player:getHandcardNum() < player:getMark("&nyarz_zhaotao-Clear") then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                        room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
                        room:setPlayerMark(player, "&nyarz_zhaotao-Clear", 0)
                        player:drawCards(2, self:objectName())
                    end
                end
                if player:getHandcardNum() == player:getMark("&nyarz_zhaotao-Clear") then
                    local target = room:askForPlayerChosen(player, use.to, self:objectName(), "@nyarz_zhaotao", true, true)
                    if target then
                        room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
                        room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_sanchen = sgs.CreateTriggerSkill{
    name = "nyarz_sanchen",
    events = {sgs.CardFinished,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if (not p:hasSkill(self:objectName())) then continue end

                if p:getPile("nyarz_sanchen"):length() >= 3 then
                    local target = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), "@nyarz_sanchen", true, true)
                    if target then
                        room:broadcastSkillInvoke(self:objectName())
                        local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        obtain:addSubcards(p:getPile("nyarz_sanchen"))
                        room:obtainCard(target, obtain, false)
                        obtain:deleteLater()
                        if p:isAlive() and target:objectName() ~= p:objectName() then 
                            p:drawCards(1, self:objectName()) 
                        end
                    end
                end
            end
            return false
        end

        if (not player:hasSkill(self:objectName())) then return false end

        local use = data:toCardUse()
        if (not use.card) or use.card:isKindOf("SkillCard") then return false end
        if use.card:subcardsLength() <= 0 then return false end

        if use.card:isKindOf("DelayedTrick") then return false end
        if (room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_PlaceHand) then return false end

        if player:getPile("nyarz_sanchen"):length() >= 3 then return false end
        for _,id in sgs.qlist(player:getPile("nyarz_sanchen")) do
            if sgs.Sanguosha:getCard(id):objectName() == use.card:objectName() then return false end
        end

        room:setPlayerMark(player, "nyarz_sanchen_quip", 0)
        if use.card:isKindOf("EquipCard") then room:setPlayerMark(player, "nyarz_sanchen_quip", 1) end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("put:"..use.card:objectName())) then
            room:broadcastSkillInvoke(self:objectName())
            player:addToPile("nyarz_sanchen", use.card:getSubcards())
            if player:isDead() then return false end
            player:drawCards(1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_duyu:addSkill(nyarz_zhaotao)
nyarz_duyu:addSkill(nyarz_sanchen)

nyarz_yuanshu = sgs.General(extension, "nyarz_yuanshu", "qun", 4, true, false, false)

nyarz_canxiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_canxi",
    n = 1,
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, selected, to_select)
        return (not to_select:isKindOf("BasicCard"))
        and (#selected < 1)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = nyarz_canxiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false 
    end,
    --[[enabled_at_nullification = function(self, player)
        if player:getPhase() ~= sgs.Player_NotActive and player:getMark("@nyarz_canxi_"..player:getKingdom()) > 0 then return true end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:getPhase() ~= sgs.Player_NotActive then
                return player:getMark("@nyarz_canxi_"..other:getKingdom()) > 0
            end
        end
        return false 
    end,]]
    enabled_at_response = function(self, player, pattern)
        if pattern ~= "nullification" then return false end
        if player:getPhase() ~= sgs.Player_NotActive and player:getMark("@nyarz_canxi_"..player:getKingdom()) > 0 then return true end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:getPhase() ~= sgs.Player_NotActive then
                return player:getMark("@nyarz_canxi_"..other:getKingdom()) > 0
            end
        end
        return false 
    end
}

nyarz_canxiCard = sgs.CreateSkillCard
{
    name = "nyarz_canxi",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName("nyarz_canxi")
        card:deleteLater()

        if card:targetFixed() then return false end
        return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets, player)
        local card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName("nyarz_canxi")
        card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if card and card:canRecast() and #targets == 0 then
			return false
		end

        return card and card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName("nyarz_canxi")

        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerMark(source, "@nyarz_canxi_"..p:getKingdom(), 0)
                break
            end
        end

        return card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

        local card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName("nyarz_canxi")

        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerMark(source, "@nyarz_canxi_"..p:getKingdom(), 0)
                break
            end
        end

        return card
    end,
}

nyarz_canxi = sgs.CreateTriggerSkill{
    name = "nyarz_canxi",
    events = {sgs.RoundStart,sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = nyarz_canxiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            --room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(player, "@nyarz_canxi_"..p:getKingdom(), 1)
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if not use.from then return false end
            if use.from and use.from:objectName() == player:objectName() then return false end
            if use.from:getMark("nyarz_canxi"..player:objectName().."-Clear") > 0 then return false end
            if (not (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard"))) then return false end
            if (not use.to:contains(player)) then return false end
            if player:getMark("@nyarz_canxi_"..use.from:getKingdom()) == 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            room:setPlayerMark(use.from, "nyarz_canxi"..player:objectName().."-Clear", 1)

            local log = sgs.LogMessage()
            log.type = "$nyarz_canxi_invalid"
            log.from = use.from
            log.to:append(player)
            log.card_str = use.card:toString()
            log.arg = self:objectName()
            room:sendLog(log)

            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end

local function utf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex  = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end

nyarz_pizhi = sgs.CreateTriggerSkill{
    name = "nyarz_pizhi",
    events = {sgs.CardFinished,sgs.CardsMoveOneTime--[[,sgs.EventPhaseStart]]},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local target
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getPhase() == sgs.Player_Play then
                    target = p
                    break
                end
            end
            if (not target) or target:objectName() == player:objectName() then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            local num = 0
            if use.card:isKindOf("Slash") then 
                num = 1
            else
                num = utf8len(sgs.Sanguosha:translate(use.card:objectName()))
            end
            if num >= player:getHp() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                --room:addPlayerMark(player, "&nyarz_pizhi", 1)
                room:setPlayerMark(target, "nyarz_pizhi"..player:objectName().."-Clear", 1)
                target:endPlayPhase()
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (not move.from) then return false end
            local target = room:findPlayerByObjectName(move.from:objectName())
            if target and target:getMark("nyarz_pizhi"..player:objectName().."-Clear") > 0
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
            and target:getPhase() == sgs.Player_Discard then
                local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                for _,id in sgs.qlist(move.card_ids) do
                    if room:getCardPlace(id) == sgs.Player_DiscardPile then
                        obtain:addSubcard(sgs.Sanguosha:getCard(id))
                    end
                end
                if (not obtain:getSubcards():isEmpty()) then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:obtainCard(player, obtain, true)
                end
                obtain:deleteLater()
            end
        end
        --[[if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish and player:getMark("&nyarz_pizhi") > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(player:getMark("&nyarz_pizhi"), self:objectName())
            end
        end]]

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhonggu = sgs.CreateTriggerSkill{
    name = "nyarz_zhonggu",
    events = {sgs.Death,sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseEnd,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            if (not player:hasSkill(self:objectName())) then return false end
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getKingdom() == death.who:getKingdom() then return false end
                end
            end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local old = player:getTag("nyarz_zhonggu"):toString():split("+")
            if old and (#old > 0) then
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    for _,pattern in ipairs(old) do
                        room:removePlayerCardLimitation(p, "use,response", pattern)
                    end
                end
            end
            local new = {}
            local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("EquipCard") then continue end
                local pattern = card:getClassName().."|.|.|."
                if card:isKindOf("Slash") then pattern = "Slash|.|.|." end
                if (not table.contains(new, pattern))  then
                    table.insert(new, pattern)
                    obtain:addSubcard(card)
                end
                if #new >= 3 then break end
            end
            if #new > 0 then
                room:obtainCard(player, obtain, true)
                room:showCard(player, obtain:getSubcards())
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    for _,pattern in ipairs(new) do
                        room:setPlayerCardLimitation(p, "use,response", pattern, false)
                    end
                end
            end
            obtain:deleteLater()
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            room:setPlayerMark(player, "nyarz_zhonggu-PlayClear", 1)
        end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play
            and player:getMark("nyarz_zhonggu-PlayClear") == 0 then
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:isDead() or player:getMark("nyarz_zhonggu-PlayClear") > 0 then return false end
                    room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                    if player:getMark("nyarz_zhonggu+"..p:objectName()) == 0 then
                        room:addPlayerMark(p, "&nyarz_zhonggu_draw", 1)
                        room:addPlayerMark(player, "nyarz_zhonggu+"..p:objectName(), 1)
                    end
                    room:loseHp(player, 1, true, player, self:objectName())
                    room:getThread():delay(300)
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName())
            and player:getMark("&nyarz_zhonggu_draw") > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(player:getMark("&nyarz_zhonggu_draw"), self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_yuanshu:addSkill(nyarz_canxi)
nyarz_yuanshu:addSkill(nyarz_canxiVS)
nyarz_yuanshu:addSkill(nyarz_pizhi)
nyarz_yuanshu:addSkill(nyarz_zhonggu)

nyarz_zhangrang = sgs.General(extension, "nyarz_zhangrang", "qun", 3, true, false, false)

nyarz_luanzheng = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_luanzheng",
    guhuo_type = "lr",
    view_as = function(self)
        local cc = nyarz_luanzhengCard:clone()
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local card = sgs.Self:getTag("nyarz_luanzheng"):toCard()
            cc:setUserString(card:objectName())
            return cc
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" then pattern = "Slash" end
            cc:setUserString(pattern)
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyarz_luanzheng_failed-Clear") == 0
    end,
    --[[enabled_at_nullification = function(self, player)
        if player:getMark("nyarz_luanzheng_failed-Clear") > 0 then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        return player:getMark("nyarz_luanzheng_guhuo_remove_nullification_lun") == 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        if player:getMark("nyarz_luanzheng_failed-Clear") > 0 then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        local patterns = {"peach","analeptic", "jink", "nullification"}
        for _,item in ipairs(patterns) do
            local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", item)
            if string.find(pattern, item) and player:getMark(mark) == 0 then return true end
        end
        if pattern == "slash" or pattern == "Slash" then
            local slashes = {"slash", "thunder_slash", "fire_slash"}
            for _,item in ipairs(slashes) do
                local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", item)
                if string.find(pattern, item) and player:getMark(mark) == 0 then return true end
            end
        end
        if pattern == "Jink" and player:getMark("nyarz_luanzheng_guhuo_remove_jink_lun") == 0 then return true end
        return false
    end
}

nyarz_luanzhengCard = sgs.CreateSkillCard
{
    name = "nyarz_luanzheng",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then pattern = "peach" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_luanzheng")
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then pattern = "peach" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_luanzheng")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", pattern)
        room:setPlayerMark(player, mark, 1)
        if pattern == "slash" then
            room:setPlayerMark(player, "nyarz_luanzheng_guhuo_remove_normal_slash_lun", 1)
        end

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())

        local put = room:askForExchange(player, "nyarz_luanzheng_put", 1, 1, true, "@nyarz_luanzheng-put", true)
        if put then
            local log = sgs.LogMessage()
            log.type = "$nyarz_luanzheng_put"
            log.from = player
            log.arg = self:objectName()
            log.card_str = table.concat(sgs.QList2Table(put:getSubcards()), "+")
            room:sendLog(log)
            --room:broadcastSkillInvoke(self:objectName())

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(put:getSubcards(), nil, sgs.Player_DrawPile, reason)
            room:moveCardsAtomic(move, true)
            --room:getThread():delay()
        else
            room:setCardFlag(card, "nyarz_luanzheng")
        end

		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "normal_slash" then pattern = "slash" end
        if pattern == "Slash" then
            local all = {"slash","fire_slash","thunder_slash"} 
            local items = {}
            for _,item in ipairs(all) do
                local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", item)
                if player:getMark(mark) == 0 then
                    table.insert(items, item)
                end
            end
            pattern = room:askForChoice(player, "nyarz_luanzheng_Slash", table.concat(items, "+"))
        end
        if pattern == "Jink" then pattern = "jink" end
        if pattern == "peach+analeptic" then 
            local all = {"peach","analeptic"} 
            local items = {}
            for _,item in ipairs(all) do
                local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", item)
                if player:getMark(mark) == 0 then
                    table.insert(items, item)
                end
            end
            pattern = room:askForChoice(player, "nyarz_luanzheng_saveself", table.concat(items, "+"))
        end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())

        local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", pattern)
        room:setPlayerMark(player, mark, 1)

        local put = room:askForExchange(player, "nyarz_luanzheng_put", 1, 1, true, "@nyarz_luanzheng-put", true)
        if put then
            local log = sgs.LogMessage()
            log.type = "$nyarz_luanzheng_put"
            log.from = player
            log.arg = self:objectName()
            log.card_str = table.concat(sgs.QList2Table(put:getSubcards()), "+")
            room:sendLog(log)
            --room:broadcastSkillInvoke(self:objectName())

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(put:getSubcards(), nil, sgs.Player_DrawPile, reason)
            room:moveCardsAtomic(move, true)
            --room:getThread():delay()
        else
            room:setCardFlag(card, "nyarz_luanzheng")
        end

        return card
    end
}

nyarz_luanzheng_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_luanzheng_buff",
    events = {sgs.CardFinished, sgs.EventAcquireSkill, sgs.GameStart},
    --view_as_skill = nyarz_luanzhengVS,
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill or event == sgs.GameStart then
            if event == sgs.EventAcquireSkill then
                if data:toString() ~= "nyarz_luanzheng" then return false end
            end
            --local tag = room:getTag("nyarz_luanzheng_cards")
            --if tag then return false end
            local items = {}
            for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("BasicCard") or card:isNDTrick() then
                    if (not table.contains(items, card:objectName())) then
                        table.insert(items, card:objectName())
                    end
                end
            end
            room:setTag("nyarz_luanzheng_cards", sgs.QVariant(table.concat(items, "+")))
            return false
        end

        if player:getMark("nyarz_luanzheng_failed-Clear") > 0 then return false end
        local use = data:toCardUse()
        if use.card and use.card:hasFlag("nyarz_luanzheng") then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "nyarz_luanzheng", "@nyarz_luanzheng", false, true)
            room:setTag("nyarz_luanzheng", data)
            local card = room:askForExchange(target, "nyarz_luanzheng", 1, 1, true, "@nyarz_luanzheng-give:"..player:getGeneralName(), true)
            if card then
                room:obtainCard(player, card, false)
            else
                room:setPlayerMark(player, "nyarz_luanzheng_failed-Clear", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

nyarz_quanqing = sgs.CreateTriggerSkill{
    name = "nyarz_quanqing",
    events = {sgs.CardsMoveOneTime, sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() ~= player:objectName()
            and move.to and move.to:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand)
            or move.from_places:contains(sgs.Player_PlaceEquip))
            and move.to_place == sgs.Player_PlaceHand then
                if move.from:isDead() then return false end
                local target = room:findPlayerByObjectName(move.from:objectName())
                local _player = sgs.SPlayerList()
                _player:append(player)
                room:setPlayerMark(target, "&nyarz_quanqing_can+#"..player:objectName().."-Clear", 1, _player)
            end
            if move.from and move.from:objectName() == player:objectName()
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_USE)
            and (move.from_places:contains(sgs.Player_PlaceHand)
            or move.from_places:contains(sgs.Player_PlaceEquip)) then
                local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, 99, "@nyarz_quanqing", true, true)
                if (not targets:isEmpty()) then
                    room:broadcastSkillInvoke(self:objectName())
                    for _,to in sgs.qlist(targets) do
                        if to:isDead() then continue end
                        to:drawCards(1, self:objectName())
                    end
                    for _,to in sgs.qlist(targets) do
                        if to:isDead() then continue end
                        room:setPlayerMark(to, "&nyarz_quanqing_bad+#"..player:objectName().."-Clear", 1)
                    end
                end
            end
        end
        if event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_isUse then
                if response.m_card and (not response.m_card:isKindOf("SkillCard")) then
                    local can = sgs.SPlayerList()
                    local tos = sgs.SPlayerList()
                    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark("&nyarz_quanqing_can+#"..player:objectName().."-Clear") > 0 then
                            room:setPlayerMark(p, "&nyarz_quanqing_can+#"..player:objectName().."-Clear", 0)
                            can:append(p)
                        else
                            tos:append(p)
                        end
                    end
                    if can:isEmpty() then return false end
                    local log = sgs.LogMessage()
                    log.type = "$nyarz_quanqing_response"
                    log.from = player
                    log.to = tos
                    log.arg = self:objectName()
                    log.card_str = response.m_card:toString()
                    room:sendLog(log)
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (not use.card) or use.card:isKindOf("SkillCard") then return false end
            local can = sgs.SPlayerList()
            local tos = sgs.SPlayerList()
            local use = data:toCardUse()
            local no_respond_list = use.no_respond_list
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("&nyarz_quanqing_can+#"..player:objectName().."-Clear") > 0 then
                    room:setPlayerMark(p, "&nyarz_quanqing_can+#"..player:objectName().."-Clear", 0)
                    can:append(p)
                else
                    table.insert(no_respond_list, p:objectName())
                    tos:append(p)
                end
            end
            if (can:isEmpty() or tos:isEmpty()) then return false end
            local log = sgs.LogMessage()
            log.type = "$nyarz_quanqing_response"
            log.from = player
            log.to = tos
            log.arg = self:objectName()
            log.card_str = use.card:toString()
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())

            use.no_respond_list = no_respond_list
            data:setValue(use)
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_quanqing_buff = sgs.CreateTriggerSkill{
    name = "#nyarz_quanqing_buff",
    --events = {sgs.CardUsed,sgs.CardResponded, sgs.JinkEffect, sgs.NullificationEffect, sgs.CardEffected, sgs.SlashEffected},
    events = {sgs.CardUsed,sgs.CardResponded, sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        --[[if (event == sgs.JinkEffect) then
            if player:hasFlag("nyarz_quanqing") then
                room:setPlayerFlag(player, "-nyarz_quanqing")
                return true
            end
        elseif event == sgs.NullificationEffect then
            if player:hasFlag("nyarz_quanqing") then
                room:setPlayerFlag(player, "-nyarz_quanqing")
                return true
            end
        elseif event == sgs.CardEffected then  
            local effect = data:toCardEffect()
            if effect.card:hasFlag("nyarz_quanqing") then
                return true
            end
        elseif event == sgs.SlashEffected then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("nyarz_quanqing") then
                return true
            end]]
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:hasFlag("nyarz_quanqing") then
                return true
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or card:isKindOf("SkillCard") then return false end
            local invalid = false
            for _,other in sgs.qlist(room:getOtherPlayers(player, true)) do
                if player:getMark("&nyarz_quanqing_bad+#"..other:objectName().."-Clear") > 0 then
                    room:setPlayerMark(player, "&nyarz_quanqing_bad+#"..other:objectName().."-Clear", 0)
                    if card:isKindOf("EquipCard") then continue end
                    invalid = true

                    local log = sgs.LogMessage()
                    log.type = "$nyarz_quanqing_invalid"
                    log.from = other
                    log.to:append(player)
                    log.arg = "nyarz_quanqing"
                    log.card_str = card:toString()
                    room:sendLog(log)
                    if other:isAlive() then other:drawCards(1, "nyarz_quanqing", false) end
                end
            end
            if invalid then
                if (card:isKindOf("Jink") or card:isKindOf("Nullification")) then
                    --room:setPlayerFlag(player, "nyarz_quanqing")
                    if event == sgs.CardUsed then
                        local use = data:toCardUse()
                        local nullified_list = use.nullified_list
                        table.insert(nullified_list, "_ALL_TARGETS")
                        use.nullified_list = nullified_list
                        data:setValue(use)
                    end
                else
                    room:setCardFlag(card, "nyarz_quanqing")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_zhangrang:addSkill(nyarz_luanzheng)
nyarz_zhangrang:addSkill(nyarz_luanzheng_buff)
nyarz_zhangrang:addSkill(nyarz_quanqing)
nyarz_zhangrang:addSkill(nyarz_quanqing_buff)
extension:insertRelatedSkills("nyarz_luanzheng", "#nyarz_luanzheng_buff")
extension:insertRelatedSkills("nyarz_quanqing", "#nyarz_quanqing_buff")

nyarz_xujing = sgs.General(extension, "nyarz_xujing", "shu", 3, true, false, false)

nyarz_caixia = sgs.CreateTriggerSkill{
    name = "nyarz_caixia",
    --events = {sgs.CardUsed,sgs.CardResponded, sgs.JinkEffect, sgs.NullificationEffect, sgs.CardEffected, sgs.SlashEffected},
    events = {sgs.CardUsed,sgs.CardResponded, sgs.CardEffected},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if (event == sgs.CardUsed or event == sgs.CardResponded) and (player:getMark("nyarz_caixia_nolimit") > 0) then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if not ((not card) or card:isKindOf("SkillCard")) then  
                room:setPlayerMark(player, "nyarz_caixia_nolimit", 0)
                room:addPlayerHistory(player, card:getClassName(), -1)
                --room:setCardFlag(card, "RemoveFromHistory")
            end
        end
        if (event == sgs.CardUsed or event == sgs.CardResponded) and player:getMark("&nyarz_caixia") > 0 then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                card = response.m_card
            end
            if not ((not card) or card:isKindOf("SkillCard")) then  
                room:removePlayerMark(player, "&nyarz_caixia", 1)
                return false
            end
        end

        --[[if (event == sgs.JinkEffect) then
            if player:hasFlag("nyarz_caixia") then
                room:setPlayerFlag(player, "-nyarz_caixia")
                return true
            end
        elseif event == sgs.NullificationEffect then
            if player:hasFlag("nyarz_caixia") then
                room:setPlayerFlag(player, "-nyarz_caixia")
                return true
            end
        elseif event == sgs.CardEffected then  
            local effect = data:toCardEffect()
            if effect.card:hasFlag("nyarz_caixia") then
                return true
            end
        elseif event == sgs.SlashEffected then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("nyarz_caixia") then
                return true
            end]]
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:hasFlag("nyarz_caixia") then
                return true
            end
        else
            if (not player:hasSkill(self:objectName())) then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or card:isKindOf("SkillCard") then return false end
            local num = math.max(0, player:getHp())
            local _data = sgs.QVariant()
            _data:setValue(card)
            player:setTag("nyarz_caixia", _data)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..card:objectName().."::"..num)) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, "&nyarz_caixia", num)
                room:addPlayerHistory(player, card:getClassName(), -1)
                room:setPlayerMark(player, "nyarz_caixia_nolimit", 1)
                if num >= 0 then
                    player:drawCards(num, "nyarz_caixia")
                end

                local log = sgs.LogMessage()
                log.type = "$nyarz_caixia_invalid"
                log.from = player
                log.to:append(player)
                log.arg = self:objectName()
                log.card_str = card:toString()
                room:sendLog(log)

                if (card:isKindOf("Jink") or card:isKindOf("Nullification")) then
                    --room:setPlayerFlag(player, "nyarz_caixia")
                    if event == sgs.CardUsed then
                        local use = data:toCardUse()
                        local nullified_list = use.nullified_list
                        table.insert(nullified_list, "_ALL_TARGETS")
                        use.nullified_list = nullified_list
                        data:setValue(use)
                    end
                else
                    room:setCardFlag(card, "nyarz_caixia")
                end
                if card:isKindOf("DelayedTrick") and event == sgs.CardUsed then
                    --[[local use = data:toCardUse()
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, "_ALL_TARGETS")
                    use.nullified_list = nullified_list
                    data:setValue(use)]]
                    if room:getCardPlace(card:getEffectiveId()) ~= sgs.Player_DiscardPile then
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
                        room:moveCardTo(card, nil, nil, sgs.Player_DiscardPile, reason)
                    end
                    return true
                end
                if card:isKindOf("EquipCard") and event == sgs.CardUsed then
                    return true
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_caixia_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_caixia_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:hasSkill("nyarz_caixia") and from:getMark("nyarz_caixia_nolimit") > 0 then return 1000 end
        return 0
    end,
}

nyarz_shangyu = sgs.CreateTriggerSkill{
    name = "nyarz_shangyu",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.reason.m_skillName == self:objectName() then return false end
        if move.to and move.to_place == sgs.Player_PlaceHand then
            local target = room:findPlayerByObjectName(move.to:objectName())
            local _data = sgs.QVariant()
            _data:setValue(target)
            if move.card_ids:length() == 1 then
                local id = move.card_ids:at(0)
                if room:getCardPlace(id) == sgs.Player_PlaceHand
                and room:getCardOwner(id):objectName() == target:objectName() then
                    player:setTag("nyarz_shangyu", _data)
                    local to = room:askForPlayerChosen(player, room:getOtherPlayers(target), self:objectName(), "@nyarz_shangyu:"..target:getGeneralName(), true, true)
                    if to then
                        room:broadcastSkillInvoke(self:objectName())
                        room:giveCard(target, to, sgs.Sanguosha:getCard(id), self:objectName())
                    end
                end
            end
            if move.card_ids:length() >= 2 and target:isAlive() then
                player:setTag("nyarz_shangyu", _data)
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..target:getGeneralName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    target:drawCards(1, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_xujing:addSkill(nyarz_caixia)
nyarz_xujing:addSkill(nyarz_caixia_buff)
nyarz_xujing:addSkill(nyarz_shangyu)
extension:insertRelatedSkills("nyarz_caixia", "#nyarz_caixia_buff")

nyarz_dianwei = sgs.General(extension, "nyarz_dianwei", "wei", 4, true, false, false)

nyarz_qiangxi = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_qiangxi",
    view_as = function(self)
        return nyarz_qiangxiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

nyarz_qiangxiCard = sgs.CreateSkillCard
{
    name = "nyarz_qiangxi",
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:getMark("nyarz_qiangxi_damaged-PlayClear") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Normal))
        if effect.to:isAlive() then
            room:damage(sgs.DamageStruct(self:objectName(), effect.to, effect.from, 1, sgs.DamageStruct_Normal))
        end
    end
}

nyarz_qiangxi_record = sgs.CreateTriggerSkill{
    name = "#nyarz_qiangxi_record",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:setPlayerMark(player, "nyarz_qiangxi_damaged-PlayClear", 1)
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_ninge = sgs.CreateTriggerSkill{
    name = "nyarz_ninge",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:isDead() or player:isDead() then return false end
        local skills = {}
        for _,sk in sgs.list(damage.to:getSkillList())do
            if sk:isAttachedLordSkill() then continue end
            if damage.to:getMark("Qingcheng"..sk:objectName()) == 0 then
                table.insert(skills, sk:objectName())
            end
        end
        if #skills <= 0 then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        local skill = room:askForChoice(player, self:objectName(), table.concat(skills, "+"), data)
        room:addPlayerMark(damage.to, "Qingcheng"..skill, 1)
        room:addPlayerMark(damage.to, "nyarz_ninge_"..skill, 1)

        local log1 = sgs.LogMessage()
        log1.type = "$nyarz_ninge_invalid"
        log1.from = damage.to
        log1.arg = skill
        room:sendLog(log1)


        player:drawCards(2, self:objectName())

        local recast = room:askForExchange(player, self:objectName(), 999, 0, true, "@nyarz_ninge", true)
        if recast and (recast:subcardsLength() > 0) then
            local log = sgs.LogMessage()
            log.from = player
            log.type = "$RecastCard"
            log.card_str = table.concat(sgs.QList2Table(recast:getSubcards()), "+")
            room:sendLog(log)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
            room:moveCardTo(recast, nil, nil, sgs.Player_DiscardPile, reason)
            if player:isDead() then return false end
            player:drawCards(recast:subcardsLength(), "recast")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_ninge_clear = sgs.CreateTriggerSkill{
    name = "#nyarz_ninge_clear",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            for _,sk in sgs.list(p:getSkillList())do
                if sk:isAttachedLordSkill() then continue end
                if p:getMark("nyarz_ninge_"..sk:objectName()) > 0 then
                    room:removePlayerMark(p, "nyarz_ninge_"..sk:objectName(), 1)
                    room:removePlayerMark(p, "Qingcheng"..sk:objectName(), 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_dianwei:addSkill(nyarz_qiangxi)
nyarz_dianwei:addSkill(nyarz_qiangxi_record)
nyarz_dianwei:addSkill(nyarz_ninge)
nyarz_dianwei:addSkill(nyarz_ninge_clear)
extension:insertRelatedSkills("nyarz_qiangxi", "#nyarz_qiangxi_record")
extension:insertRelatedSkills("nyarz_ninge", "#nyarz_ninge_clear")

nyarz_xurong = sgs.General(extension, "nyarz_xurong", "qun", 4, true, false, false)

nyarz_xionghuo = sgs.CreateTriggerSkill{
    name = "nyarz_xionghuo",
    events = {sgs.DamageCaused,sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:objectName() == player:objectName() then return false end

        if event == sgs.DamageCaused then
            if player:getPhase() ~= sgs.Player_Play then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:sendLog(CreateDamageLog(damage, 1, self:objectName(), true))
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end

        if event == sgs.Damage then
            if damage.to:isDead() then return false end
            if damage.damage ~= 1 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:loseHp(damage.to, damage.to:getHp(), true, player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_shajve = sgs.CreateTriggerSkill{
    name = "nyarz_shajve",
    events = {sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_NotActive then return false end
    
        local find = false
        local n = 0
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isDamageCard() then 
                find = true
                break
            end
            n = n + 1;
        end
        if find then
            local draw = data:toDraw()
            if (not draw.top) then return false end
            if draw.reason ~= self:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            end
            draw.num = draw.num + 1
            data:setValue(draw)

            local tem1 = room:getNCards(n, false)
            local tem2 = room:getNCards(1, false)
            room:returnToTopDrawPile(tem1)
            room:returnToTopDrawPile(tem2)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_shajve_other = sgs.CreateTriggerSkill{
    name = "#nyarz_shajve_other",
    events = {sgs.EnterDying,sgs.QuitDying,sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("nyarz_shajve") then
                local log = sgs.LogMessage()
                log.type = "#ChoosePlayerWithSkill"
                log.from = player
                log.arg = "nyarz_shajve"
                log.to = use.to
                room:sendLog(log)
                room:broadcastSkillInvoke("nyarz_shajve")
            end
        end

        if event == sgs.EnterDying then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill("nyarz_shajve") and p:isAlive() then
                    room:sendCompulsoryTriggerLog(p, "nyarz_shajve", true, true)
                    p:drawCards(1, "nyarz_shajve")
                end
            end
        end
        if event == sgs.QuitDying then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:isDead() then break end
                if p:hasSkill("nyarz_shajve") and p:isAlive() then
                    room:setPlayerFlag(p, "nyarz_shajve")
                    room:askForUseSlashTo(p, player, "@nyarz_shajve:"..player:getGeneralName(), false, false, false, p, nil, "nyarz_shajve")
                    room:setPlayerFlag(p, "-nyarz_shajve")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_shajve_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_shajve_buff",
    residue_func = function(self, from, card)
        if from:hasFlag("nyarz_shajve") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasFlag("nyarz_shajve") then return 1000 end
        return 0
    end,
}

nyarz_xurong:addSkill(nyarz_xionghuo)
nyarz_xurong:addSkill(nyarz_shajve)
nyarz_xurong:addSkill(nyarz_shajve_other)
nyarz_xurong:addSkill(nyarz_shajve_buff)
extension:insertRelatedSkills("nyarz_shajve", "#nyarz_shajve_other")
extension:insertRelatedSkills("nyarz_shajve", "#nyarz_shajve_buff")

nyarz_dukui = sgs.General(extension, "nyarz_dukui", "wei", 3, true, true, true)

nyarz_fanyinVS = sgs.CreateViewAsSkill
{
    name = "nyarz_fanyin",
    response_pattern = "@@nyarz_fanyin",
    n = 999,
    expand_pile = "#nyarz_fanyin",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("#nyarz_fanyin"):contains(to_select:getEffectiveId())
        and #selected < 1 and to_select:isAvailable(sgs.Self)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = nyarz_fanyinCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = false,
}

nyarz_fanyinCard = sgs.CreateSkillCard
{
    name = "nyarz_fanyin",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card and card:targetFixed() then
			return false
		end

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetFilter(qtargets, to_select, target) and not target:isProhibited(to_select, card, qtargets) then
            return true
        end
        return false 
	end,
    target_fixed = function(self)		
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
        if card and card:targetFixed() then
            return true
        end
        return false
	end,
	feasible = function(self, targets)	
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetsFeasible(qtargets, target) then
            return true
        end
        return false
	end,
    about_to_use = function(self,room,use)
        room:broadcastSkillInvoke(self:objectName())
        local source = use.from
        local tos = {}
        for _,to in sgs.qlist(use.to) do
            table.insert(tos, to:objectName())
        end
        source:setTag("nyarz_fanyin_to", sgs.QVariant(table.concat(tos, "+")))
    end,
}

nyarz_fanyin = sgs.CreateTriggerSkill{
    name = "nyarz_fanyin",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_fanyinVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        local use = data:toCardUse()
        if (use.card) and (not use.card:isKindOf("SkillCard")) then else return false end
        if use.card:getNumber() <= player:getMark("&nyarz_fanyin-Clear") then return false end
        if use.card:hasFlag("nyarz_fanyin") then return false end
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "&nyarz_fanyin-Clear", use.card:getNumber())

            local all_cards = {}
            local names = {}
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if (not card:isAvailable(player)) then continue end
                if (not table.contains(names, card:objectName())) then
                    if card:isKindOf("EquipCard") and (math.random(1,3) <= 2) then continue end
                    table.insert(names, card:objectName())
                    table.insert(all_cards, id)
                end
            end
            if #all_cards <= 3 then
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if (not card:isAvailable(player)) then continue end
                    if (not table.contains(names, card:objectName())) then
                        if card:isKindOf("EquipCard") and math.random(1,2) == 1 then continue end
                        table.insert(names, card:objectName())
                        table.insert(all_cards, id)
                    end
                end
            end

            if #all_cards <= 0 then return false end
            local card_ids = sgs.IntList()
            if #all_cards <= 3 then
                for _,id in ipairs(all_cards) do
                    card_ids:append(id)
                end
            else
                for i = 1, 3, 1 do
                    local id = all_cards[math.random(1,#all_cards)]
                    table.removeOne(all_cards, id)
                    card_ids:append(id)
                end
            end

            room:setPlayerFlag(player, "nyarz_fanyin")
            room:notifyMoveToPile(player, card_ids, "nyarz_fanyin", sgs.Player_DrawPile, true)
            local use_card = room:askForUseCard(player, "@@nyarz_fanyin", "@nyarz_fanyin-use")
            room:notifyMoveToPile(player, card_ids, "nyarz_fanyin", sgs.Player_DrawPile, false)
            room:setPlayerFlag(player, "-nyarz_fanyin")

            if (not use_card) then return false end
            local real_card = sgs.Sanguosha:getCard(use_card:getSubcards():at(0))
            room:setCardFlag(real_card, "RemoveFromHistory")
            room:setCardFlag(real_card, "nyarz_fanyin")
            local to = sgs.SPlayerList()
            local tos = player:getTag("nyarz_fanyin_to"):toString():split("+")
            for _,p in ipairs(tos) do
                local tt = room:findPlayerByObjectName(p)
                to:append(tt)
            end
            player:removeTag("nyarz_fanyin_to")
            room:useCard(sgs.CardUseStruct(real_card, player, to))
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_fanyin_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_fanyin_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:hasFlag("nyarz_fanyin") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasFlag("nyarz_fanyin") then return 1000 end
        return 0
    end,
}

nyarz_dukui:addSkill(nyarz_fanyin)
nyarz_dukui:addSkill(nyarz_fanyinVS)
nyarz_dukui:addSkill(nyarz_fanyin_buff)
extension:insertRelatedSkills("nyarz_fanyin", "#nyarz_fanyin_buff")

nyarz_qinyilu = sgs.General(extension, "nyarz_qinyilu", "qun", 3, true, false, false)

nyarz_piaopin = sgs.CreateTriggerSkill{
    name = "nyarz_piaopin",
    events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime,sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                if (not player:hasSkill(self:objectName())) then return false end
                if player:isKongcheng() then return false end
                local recast = sgs.IntList()
                for _,card in sgs.qlist(player:getHandcards()) do
                    if (not card:isAvailable(player)) then
                        recast:append(card:getId())
                    end
                end
                if recast:isEmpty() then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local log = sgs.LogMessage()
                log.from = player
                log.type = "$RecastCard"
                log.card_str = table.concat(sgs.QList2Table(recast), "+")
                room:sendLog(log)
        
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(recast, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)
        
                if player:isAlive() then player:drawCards(recast:length(), "recast") end
            end
            if player:getPhase() == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isKongcheng() then continue end
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:hasFlag("nyarz_piaopin") then
                            room:setCardFlag(card, "-nyarz_piaopin")
                            room:setCardTip(card:getEffectiveId(), "-nyarz_piaopin")
                        end
                    end
                end
            end
        end
        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand then
                for _,id in sgs.qlist(move.card_ids) do
                    room:setCardFlag(sgs.Sanguosha:getCard(id), "nyarz_piaopin")
                    room:setCardTip(id, "nyarz_piaopin")
                end
            end
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if (not player:hasSkill(self:objectName())) then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            if (not card:hasFlag("nyarz_piaopin")) then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            player:drawCards(1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyarz_zhuili = sgs.CreateTriggerSkill{
    name = "nyarz_zhuili",
    events = {sgs.CardsMoveOneTime,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local recast = sgs.IntList()
            for _,card in sgs.qlist(player:getCards("hej")) do
                recast:append(card:getId())
            end
            if (not recast:isEmpty()) then
                local log = sgs.LogMessage()
                log.from = player
                log.type = "$RecastCard"
                log.card_str = table.concat(sgs.QList2Table(recast), "+")
                room:sendLog(log)
    
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(recast, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)

                if player:isAlive() then player:drawCards(recast:length(), "recast") end
            end
            if player:isAlive() then player:drawCards(2, self:objectName()) end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceEquip) 
            and player:isWounded() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_qinyilu:addSkill(nyarz_piaopin)
nyarz_qinyilu:addSkill(nyarz_zhuili)

nyarz_xiahouyuan = sgs.General(extension, "nyarz_xiahouyuan", "wei", 4, true, false, false)

nyarz_shensuVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_shensu",
    view_as = function(self)
        return nyarz_shensuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (player:getMark("@nyarz_shensu_limit") == 0)
        or (player:getMark("nyarz_shensu-Clear") == 0)
    end,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        if string.find(pattern, "slash") or pattern == "Slash" then else return false end
        return (player:getMark("@nyarz_shensu_limit") == 0)
        or (player:getMark("nyarz_shensu-Clear") == 0)
    end
}

nyarz_shensuCard = sgs.CreateSkillCard
{
    name = "nyarz_shensu",
    filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()
        room:addPlayerMark(player, "nyarz_shensu-Clear", 1)

        local log1 = sgs.LogMessage()
        log1.type = "#InvokeSkill"
        log1.from = player
        log1.arg = self:objectName()
        room:sendLog(log1)
        room:broadcastSkillInvoke(self:objectName())

        local pattern = self:getUserString()
		if (not pattern) or pattern == "" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, "nyarz_shensu_slash", table.concat(all,"+"))
        end

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        room:setCardFlag(card, "RemoveFromHistory")

        local buffs = {"noresponse", "damage", "limit"}
        local choices = {}
        for _,buff in ipairs(buffs) do
            local mark = string.format("@nyarz_shensu_%s", buff)
            if player:getMark(mark) == 0 then table.insert(choices, buff) end
        end
        if #choices ~= 0 then
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
            room:setPlayerMark(player, string.format("@nyarz_shensu_%s", choice), 1)
            room:setCardFlag(card, string.format("nyarz_shensu_%s", choice))

            local log = sgs.LogMessage()
            log.type = "$nyarz_shensu_choose"
            log.from = player
            log.arg = string.format("nyarz_shensu_%s", choice)
            room:sendLog(log)
        end

        player:drawCards(1, self:objectName())
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()
        room:addPlayerMark(player, "nyarz_shensu-Clear", 1)

        local log1 = sgs.LogMessage()
        log1.type = "#InvokeSkill"
        log1.from = player
        log1.arg = self:objectName()
        room:sendLog(log1)
        room:broadcastSkillInvoke(self:objectName())

        local pattern = self:getUserString()
		if (not pattern) or pattern == "" then 
            local all = {"slash", "fire_slash", "thunder_slash"}
            pattern = room:askForChoice(player, "nyarz_shensu_slash", table.concat(all,"+"))
        end

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        room:setCardFlag(card, "RemoveFromHistory")

        local buffs = {"noresponse", "damage", "limit"}
        local choices = {}
        for _,buff in ipairs(buffs) do
            local mark = string.format("@nyarz_shensu_%s", buff)
            if player:getMark(mark) == 0 then table.insert(choices, buff) end
        end
        if #choices ~= 0 then
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
            room:setPlayerMark(player, string.format("@nyarz_shensu_%s", choice), 1)
            room:setCardFlag(card, string.format("nyarz_shensu_%s", choice))

            local log = sgs.LogMessage()
            log.type = "$nyarz_shensu_choose"
            log.from = player
            log.arg = string.format("nyarz_shensu_%s", choice)
            room:sendLog(log)
        end

        player:drawCards(1, self:objectName())
		return card
    end
}

nyarz_shensu = sgs.CreateTriggerSkill{
    name = "nyarz_shensu",
    events = {sgs.DamageCaused,sgs.CardUsed,sgs.EventLoseSkill},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_shensuVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("nyarz_shensu_damage") then
                room:sendLog(CreateDamageLog(damage, 1, self:objectName(), true))
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("nyarz_shensu_noresponse") then
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                local buffs = {"noresponse", "damage", "limit"}
                for _,buff in ipairs(buffs) do
                    local mark = string.format("@nyarz_shensu_%s", buff)
                    room:setPlayerMark(player, mark, 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_shensu_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_shensu_buff",
    residue_func = function(self, from, card)
        if card:getSkillName() == "nyarz_shensu" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "nyarz_shensu" then return 1000 end
        return 0
    end,
}

nyarz_shebianVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_shebian",
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_shebian_mark",
    view_as = function(self)
        return nyarz_shebianCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getMark("@nyarz_shebian_mark") == 0 then return false end
        for _,skill in sgs.qlist(player:getVisibleSkillList()) do
            if (not skill:isAttachedLordSkill()) and skill:objectName() ~= self:objectName() then return true end
        end
        return false 
    end
}

nyarz_shebianCard = sgs.CreateSkillCard
{
    name = "nyarz_shebian",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local player = source
        room:setPlayerMark(player, "@nyarz_shebian_mark", 0)

        local choices = {}
        for _,skill in sgs.qlist(player:getVisibleSkillList()) do
            if (not skill:isAttachedLordSkill()) and skill:objectName() ~= self:objectName() then 
                table.insert(choices, skill:objectName())
            end
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        room:detachSkillFromPlayer(player, choice)
        
        local tos = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            local name = p:getGeneralName()
            local selected = sgs.Sanguosha:getGeneral(name)
            local skills = selected:getVisibleSkillList()
            for _,skill in sgs.qlist(skills) do
                if (not player:hasSkill(skill:objectName())) then
                    tos:append(p)
                    break
                end
            end
        end

        if tos:isEmpty() then return false end
        local to = room:askForPlayerChosen(player, tos, self:objectName(), "@nyarz_shebian", false, true)
        choices = {}
        local name = to:getGeneralName()
        local selected = sgs.Sanguosha:getGeneral(name)
        for _,skill in sgs.qlist(selected:getVisibleSkillList()) do
            if (not skill:isAttachedLordSkill()) and (not player:hasSkill(skill:objectName())) then 
                table.insert(choices, skill:objectName())
            end
        end
        choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        room:acquireSkill(player, choice)
    end
}

nyarz_shebian = sgs.CreateTriggerSkill{
    name = "nyarz_shebian",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@nyarz_shebian_mark",
    view_as_skill = nyarz_shebianVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who and dying.who:objectName() == player:objectName()
        and player:getMark("@nyarz_shebian_mark") == 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:setPlayerMark(player, "@nyarz_shebian_mark", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_xiahouyuan:addSkill(nyarz_shensu)
nyarz_xiahouyuan:addSkill(nyarz_shensuVS)
nyarz_xiahouyuan:addSkill(nyarz_shensu_buff)
nyarz_xiahouyuan:addSkill(nyarz_shebian)
nyarz_xiahouyuan:addSkill(nyarz_shebianVS)
extension:insertRelatedSkills("nyarz_shensu", "#nyarz_shensu_buff")

nyarz_zhonghui = sgs.General(extension, "nyarz_zhonghui", "wei", 4, true, false, false)

nyarz_quanji = sgs.CreateTriggerSkill{
    name = "nyarz_quanji",
    events = {sgs.Damaged,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        if event == sgs.Damaged then
            local damage = data:toDamage()
            for i = 1, damage.damage, 1 do
                if player:isDead() then break end
                if room:askForSkillInvoke(player, self:objectName()) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(2, self:objectName())
                    if player:isAlive() and (not player:isNude()) then
                        local cards = room:askForExchange(player, "nyarz_quanji_damaged", 9999, 0, true, "@nyarz_quanji-remove", true)
                        if cards and (cards:subcardsLength() > 0) then
                            player:addToPile("nyarz_quanji", cards:getSubcards())
                        end
                    end
                end
            end
        end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(2, self:objectName())
                if player:isAlive() and (not player:isNude()) then
                    local cards = room:askForExchange(player, "nyarz_quanji_end", 9999, 0, true, "@nyarz_quanji-remove", true)
                    if cards and (cards:subcardsLength() > 0) then
                        player:addToPile("nyarz_quanji", cards:getSubcards())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_quanji_max = sgs.CreateMaxCardsSkill{
    name = "#nyarz_quanji_max",
    extra_func = function(self, target)
        if target:hasSkill("nyarz_quanji") then return target:getPile("nyarz_quanji"):length() end
        return 0
    end,
}

nyarz_zili = sgs.CreateTriggerSkill{
    name = "nyarz_zili",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "nyarz_paiyi",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_NotActive then return end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark(self:objectName()) > 0 then continue end
            if p:getPile("nyarz_quanji"):length() >=  p:getMaxHp() 
            or p:canWake(self:objectName()) then
                room:setPlayerMark(p, self:objectName(), 1)
                room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                room:doSuperLightbox(p, "nyarz_zili")
                room:loseMaxHp(p, 1)
                if p:isAlive() then
                    room:acquireSkill(p, "nyarz_paiyi")
                end
                if p:isWounded() then
                    room:recover(p, sgs.RecoverStruct(self:objectName(), p, p:getMaxHp() - p:getHp()))
                end
                if p:isAlive() then
                    p:gainAnExtraTurn()
                    return false
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_paiyi = sgs.CreateViewAsSkill
{
    name = "nyarz_paiyi",
    n = 9999,
    expand_pile = "nyarz_quanji",
    tiansuan_type = "damage,draw",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("nyarz_quanji"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return end
        if #cards >= (sgs.Self:getPile("nyarz_quanji"):length() / 2) then
            local cc
            local choice = sgs.Self:getTag("nyarz_paiyi"):toString()
            cc =  nyarz_paiyiCard:clone()
            cc:setUserString(choice)
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyarz_paiyi_tiansuan_remove_damage-PlayClear") == 0
        or player:getMark("nyarz_paiyi_tiansuan_remove_draw-PlayClear") == 0
    end
}

nyarz_paiyiCard = sgs.CreateSkillCard
{
    name = "nyarz_paiyi",
    target_fixed = function(self)
        return self:getUserString() == "draw"
    end,
    will_throw = true,
    filter = function(self, targets, to_select)
        if self:getUserString() == "draw" then return false end
        return #targets < self:subcardsLength()
    end,
    feasible = function(self, targets)
        return self:getUserString() == "draw" 
        or #targets > 0
    end,
    on_use = function(self, room, source, targets)
        if self:getUserString() == "draw" then
            room:setPlayerMark(source, "nyarz_paiyi_tiansuan_remove_draw-PlayClear", 1)
            --room:broadcastSkillInvoke("nyarz_paiyi")
            source:drawCards(self:subcardsLength() + 2, "nyarz_paiyi")
        else
            for _,p in ipairs(targets) do
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:isAlive() 
        and effect.from:getMark("nyarz_paiyi_tiansuan_remove_damage-PlayClear") == 0 then
            --room:broadcastSkillInvoke("nyarz_paiyi")
            room:setPlayerMark(effect.from, "nyarz_paiyi_tiansuan_remove_damage-PlayClear", 1)
        end
        room:damage(sgs.DamageStruct("nyarz_paiyi", effect.from, effect.to, 1, sgs.DamageStruct_Normal))
    end
}

nyarz_zhonghui:addSkill(nyarz_quanji)
nyarz_zhonghui:addSkill(nyarz_quanji_max)
nyarz_zhonghui:addSkill(nyarz_zili)
extension:insertRelatedSkills("nyarz_quanji", "#nyarz_quanji_max")

local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("dianshiwan") then skills:append(dianshiwan) end
if not sgs.Sanguosha:getSkill("dianfengshaoori") then skills:append(dianfengshaoori) end
if not sgs.Sanguosha:getSkill("tycuixin") then skills:append(tycuixin) end
if not sgs.Sanguosha:getSkill("nyarz_zhangcai_wu_show") then skills:append(nyarz_zhangcai_wu_show) end
if not sgs.Sanguosha:getSkill("nyarz_rendebasic") then skills:append(nyarz_rendebasic) end
if not sgs.Sanguosha:getSkill("nyarz_longnu") then skills:append(nyarz_longnu) end
if not sgs.Sanguosha:getSkill("#nyarz_longnu_buff") then skills:append(nyarz_longnu_buff) end
if not sgs.Sanguosha:getSkill("#nyarz_longnu_buff2") then skills:append(nyarz_longnu_buff2) end
if not sgs.Sanguosha:getSkill("nyarz_wushuang_god") then skills:append(nyarz_wushuang_god) end
if not sgs.Sanguosha:getSkill("nyarz_shenji_god") then skills:append(nyarz_shenji_god) end
if not sgs.Sanguosha:getSkill("#nyarz_shenji_god_audio") then skills:append(nyarz_shenji_god_audio) end
if not sgs.Sanguosha:getSkill("nyarz_shenwei_god") then skills:append(nyarz_shenwei_god) end
if not sgs.Sanguosha:getSkill("#nyarz_shenwei_god_max") then skills:append(nyarz_shenwei_god_max) end
if not sgs.Sanguosha:getSkill("nyarz_duoshi_use") then skills:append(nyarz_duoshi_use) end
if not sgs.Sanguosha:getSkill("nyarz_guanyu_win") then skills:append(nyarz_guanyu_win) end
if not sgs.Sanguosha:getSkill("nyarz_paiyi") then skills:append(nyarz_paiyi) end

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable 
{
    ["NyarzSecond"] = "群阴荟萃·第二幕",

    ["jxzhujun"] = "群阴·朱儁",
    ["&jxzhujun"] = "朱儁",
    ["#jxzhujun"] = "功成师克",
    ["designer:jxzhujun"] = "Nyarz",

    ["jxyangjie"] = "佯解",
    [":jxyangjie"] = "出牌阶段开始时，你可以视为使用一张无距离和次数限制的【火杀】。\
    此牌对目标造成伤害时，你选择一项：①令此牌伤害+1;②防止此伤害并令其回复一点体力。",
    ["jxyangjie:damage"] = "令此牌对%src伤害+1",
    ["jxyangjie:recover"] = "防止此伤害并令%src回复一点体力",
    ["@jxyangjie"] = "你可以视为使用一张无距离和次数限制的【火杀】",
    ["$jxyangjiedamage"] = "%from 选择了 令此牌对 %arg 伤害+1。",
    ["$jxyangjierecover"] = "%from 选择了 防止此伤害并令 %arg 回复一点体力。",
    ["jxjuxiang"] = "拒降",
    [":jxjuxiang"] = "每轮限一次，一名其他角色脱离濒死状态时,你可以摸X张牌并对其造成1点伤害。(X为其体力上限)",
    ["jxjuxiang:dying"] = "你可以发动“拒降”摸 %arg 张牌并对 %src 造成1点伤害",
    ["jxhoulu"] = "厚禄",
    [":jxhoulu"] = "每轮限一次，一名角色的准备阶段，你可以令其摸三张牌。本回合中，以下效果对该角色适用：\
    ①每当其使用或打出两张牌，你对其造成1点伤害，然后令其摸两张牌。\
    ②在其造成伤害后，防止下一次本技能对其造成的伤害。",

    ["$jxyangjie1"] = "佯解",
    ["$jxyangjie2"] = "佯解",
    ["$jxjuxiang1"] = "拒降",
    ["$jxjuxiang2"] = "拒降",
    ["$jxhoulu1"] = "厚禄",
    ["$jxhoulu2"] = "厚禄",
    ["$jxhoulu3"] = "厚禄",
    ["~jxzhujun"] = "群阴·朱儁",

    ["jjxiahouyuan"] = "群阴·急夏侯渊",
    ["&jjxiahouyuan"] = "夏侯渊",
    ["#jjxiahouyuan"] = "耀武宣威",
    ["designer:jjxiahouyuan"] = "Nyarz",

    ["jjjijin"] = "急进",
    [":jjjijin"] = "每回合限一次，你可以视为使用了一张未以此法使用过的普通锦囊牌，然后本局游戏内你不能再从手牌内使用与其相同牌名的牌。\
    出牌阶段结束时，你可以将手牌中因“急进”不可使用的牌交给一名其他角色，然后你摸X张牌，本回合手牌上限+X。（X为你给出的牌数）\
    当你成为其他角色使用锦囊牌的目标时，若你以“急进”使用过相同牌名的牌，令此牌对你无效。\
    一名角色使用锦囊牌时，若你以“急进”使用过相同牌名的牌，你摸1张牌。\
    注释：【无懈可击】的使用有一定问题，须随意点击一种牌名。",
    [":jjjijin2"] = "每回合限一次，你可以视为使用了一张未以此法使用过的普通锦囊牌，然后本局游戏内你不能再从手牌内使用与其相同牌名的牌。\
    出牌阶段结束时，你可以将手牌中因“急进”不可使用的牌交给一名其他角色，然后你摸X张牌，本回合手牌上限+X。（X为你给出的牌数）\
    当你成为其他角色使用锦囊牌的目标时，若你以“急进”使用过相同牌名的牌，令此牌对你无效。\
    一名角色使用锦囊牌时，若你以“急进”使用过相同牌名的牌，你摸1张牌。\
    注释：【无懈可击】的使用有一定问题，须随意点击一种牌名。\
    <font color=\"red\"><b>已使用：%arg1</b></font>",
    ["@jjjijin"] = "你可以将手牌中因“急进”不可使用的牌交给一名其他角色，然后你摸%src张牌，本回合手牌上限+%src。",

    ["$jjjijin1"] = "急进",
    ["$jjjijin2"] = "急进",
    ["~jjxiahouyuan"] = "群阴·急夏侯渊",

    ["basimafang"] = "群阴·蚌司马防",
    ["&basimafang"] = "司马防",
    ["#basimafang"] = "蚌埠住了",
    ["designer:basimafang"] = "Nyarz",

    ["basuran"] = "肃然",
    [":basuran"] = "每轮游戏开始时，你选择至多6名角色，然后为这些角色依次选择一个互不相同的阶段，本轮游戏内其跳过对应阶段。",
    ["@basuran"] = "你可以令至多6名角色于本轮内各跳过一个互不相同的阶段",
    ["$basuranskip"] = "%from 因 %arg 的效果将跳过 %arg2 阶段。",
    ["basuran:start"] = "令%src 跳过准备阶段",
    ["basuran:judge"] = "令%src 跳过判定阶段",
    ["basuran:draw"] = "令%src 跳过摸牌阶段",
    ["basuran:play"] = "令%src 跳过出牌阶段",
    ["basuran:discard"] = "令%src 跳过弃牌阶段",
    ["basuran:finish"] = "令%src 跳过结束阶段",
    ["bajuwei"] = "举尉",
    [":bajuwei"] = "准备阶段，你可以令一名其他角色成为“校尉”。\
    “校尉”使用【杀】和锦囊牌不能指定你为目标，造成1点伤害后与你各摸一张牌。",
    ["@bajuwei"] = "你可以举荐一名其他角色成为“校尉”",
    ["$bajuweibegin"] = "%from 现在是“校尉”了。",
    ["baxiaowei"] = "校尉",
    ["#bajuweilimit"] = "举尉",

    ["$basuran1"] = "肃然",
    ["$basuran2"] = "肃然",
    ["$bajuwei1"] = "举尉",
    ["$bajuwei2"] = "举尉",
    ["~basimafang"] = "群阴·蚌司马防",

    ["diansunquan"] = "群阴·典孙权",
    ["#diansunquan"] = "大魏吴王",
    ["&diansunquan"] = "孙权",
    ["designer:diansunquan"] = "Nyarz",

    ["dianyingfu"] = "影附",
    [":dianyingfu"] = "锁定技，准备阶段，你将手牌摸至10张。以此法获得的牌不计入本回合手牌上限。\
    当你使用牌指定唯一目标后或成为牌的唯一目标后，若对方手牌数小于你，你须执行一项：\
    ①交给其一张手牌，令此牌不计入次数限制。\
    ②将势力调整至与其相同，然后你交给其手牌中的所有伤害类牌，此技能失效直到你的下个回合开始。",
    ["dianyingfu:give"] = "交给%src一张手牌",
    ["dianyingfu:all"] = "调整为%arg势力并交给%src所有伤害类牌",
    ["@dianyingfu"] = "请交给 %src 一张手牌",
    ["dianfengshao"] = "封烧",
    [":dianfengshao"] = "锁定技，每回合限两次，其他角色获得你的手牌后，你须选择一名与你势力相同的角色，然后执行一项：\
    ①对其造成1点火焰伤害。若其本回合内成为过此技能的目标，改为回复2点体力。\
    ②令其翻面并摸两张牌。若其本回合内成为过此技能的目标，改为复原武将牌。",
    ["@dianfengshao"] = "请选择一名 %src 势力角色",
    ["dianfengshao:recover"] = "令%src回复2点体力",
    ["dianfengshao:renew"] = "令%src复原武将牌",
    ["dianfengshao:damage"] = "对%src造成1点火焰伤害",
    ["dianfengshao:turn"] = "令%src翻面并摸两张牌",
    ["dianchange"] = "切换",
    [":dianchange"] = "限定技，你将失去“影附”和“封烧”，获得“原-十万”和“原-封烧”,随后你将势力转换为“吴”。",
    ----彩蛋----
    ["$dianshiwannotcard"] = "%from 手中没有伤害类牌。",
    ["$dianshiwannottarget"] = "场上没有魏势力角色。",
    ["dianshiwan"] = "十万",
    [":dianshiwan"] = "锁定技，准备阶段，你摸10张牌，然后你须将手牌中的伤害类牌交给一名魏势力角色。",
    ["@dianshiwan"] = "你须将手牌中的伤害类牌交给其中一名魏势力角色(共%src张)",
    ["dianfengshaoori"] = "封烧",
    [":dianfengshaoori"] = "锁定技，每轮每项各限一次，当你失去手牌时，你须选择一名吴势力角色，然后：①对其造成1点火焰伤害；②令其回复1点体力。\
    当你受到伤害后，你须选择一名吴势力角色，然后：①令其翻面。；②令其复原武将牌。",
    ["@dianfengshaoori"] = "你选择一名吴势力角色 %src",
    ["dianfirst"] = "对其造成1点火焰伤害或令其回复1点体力",
    ["diansecond"] = "令其翻面或复原武将牌",
    ["$dianfengshaoorinottarget"] = "场上没有吴势力角色",
    ["dianfengshaoori:damage"] = "对%src造成1点火焰伤害",
    ["dianfengshaoori:recover"] = "令%src回复1点体力",
    ["dianfengshaoori:turn"] = "令%src翻面",
    ["dianfengshaoori:back"] = "令%src复原武将牌",
    ----彩蛋----

    ["mjzhaozhi"] = "群阴·赵直",
    ["&mjzhaozhi"] = "赵直",
    ["#mjzhaozhi"] = "捕梦黄粱",
    ["designer:mjzhaozhi"] = "Nyarz",

    ["mjmengjie"] = "梦解",
    [":mjmengjie"] = "在你受到伤害后，你可以选择两名有技能的角色，令其交换一个你选择的技能。",
    ["@mjmengjie"] = "请选择两名要交换技能的角色",
    ["mjmengjielose"] = "要交换的技能",
    ["mjtongguan"] = "统观",
    [":mjtongguan"] = "转换技，在你使用或打出基本牌后，你可以观看：阳：牌堆顶的四张牌；阴：一名其他角色的手牌，然后你可以将其中一张牌移动至一名角色区域内的合理位置。",
    [":mjtongguan1"] = "转换技，在你使用或打出基本牌后，你可以观看：阳：牌堆顶的四张牌；<font color=\"#01A5AF\"><s>阴：一名其他角色的手牌</s></font>，然后你可以将其中一张牌移动至一名角色区域内的合理位置。",
    [":mjtongguan2"] = "转换技，在你使用或打出基本牌后，你可以观看：<font color=\"#01A5AF\"><s>阳：牌堆顶的四张牌</s></font>；阴：一名其他角色的手牌，然后你可以将其中一张牌移动至一名角色区域内的合理位置。",
    ["$mjtongguanend"] = "%from 选择了将 %card 置入 %to 的 %arg 。",
    ["mjtongguanchoice"] = "要移动到的区域",
    ["mjtongguan:hand"] = "手牌区",
    ["mjtongguan:judge"] = "判定区",
    ["mjtongguan:equip"] = "装备区",
    ["mjtongguanmove"] = "你可以将其中一张牌置入一名角色的合理区域内",
    ["@mjtongguan"] = "你可以发动“统观”观看一名其他角色的手牌",
    ["mjtongguan:view"] = "你可以发动“统观”观看牌堆顶的4张牌",
    ["#mjtongguan"] = "统观",

    ["$mjmengjie1"] = "梦解",
    ["$mjmengjie2"] = "梦解",
    ["$mjtongguan1"] = "统观",
    ["$mjtongguan2"] = "统观",
    ["~mjzhaozhi"] = "群阴·赵直",

    ["gswanglang"] = "群阴·王朗",
    ["&gswanglang"] = "王朗",
    ["#gswanglang"] = "骧龙御宇",
    ["designer:gswanglang"] = "Nyarz",

    ["gsgushe"] = "鼓舌",
    [":gsgushe"] = "出牌阶段，若你的“激词”标记数小于七，你可以用一张手牌与至多三名其他角色拼点。\
    若你赢，你获得一枚“激词”标记。\
    没赢的角色须选择一项：①令你摸一张牌；②弃置一张手牌。\
    若你均拼点输，你令此技能于本阶段内失效，然后你失去1点体力，令你此于本局游戏内拼点牌点数+2。",
    ["@gsgushe"] = "请弃置一张手牌，否则%src摸一张牌",
    ["$gsgushe_allfailed"] = "%from 于拼点中大获全败。",
    ["$gsgushe_addnum"] = "%from 的拼点牌点数因 %arg 的效果增加到了 %arg2 点。",
    ["gsjici"] = "激词",
    [":gsjici"] = "你可以弃置X枚“激词”标记，视为你使用了一张未以此法使用过的普通锦囊牌。（X为此技能本回合发动的次数）\
    当你受到其他角色造成的伤害后，伤害来源弃置一张牌，然后重置你使用过的牌名。",
    ["countjici_usedtimes"] = "激词已用",
    ["$gsjici_renew"] = "%from 重置了 %arg 使用过的牌名【%arg2】。",

    ["$gsgushe1"] = "鼓舌",
    ["$gsgushe2"] = "鼓舌",
    ["$gsjici1"] = "激词",
    ["$gsjici2"] = "激词",
    ["~gswanglang"] = "群阴·王朗",

    ["bndongzhuo"] = "群阴·董卓",
    ["&bndongzhuo"] = "董卓",
    ["#bndongzhuo"] = "天魔乱舞",
    ["designer:bndongzhuo"] = "Nyarz",

    ["bnbenghuai"] = "崩坏",
    [":bnbenghuai"] = "主公技，锁定技，游戏开始时，你加4点体力上限并回复4点体力。\
    你的结束阶段，你须选择一项执行：①失去1点体力；②失去1点体力上限；背水：摸2张牌。",
    ["bnbenghuai:hp"] = "失去1点体力",
    ["bnbenghuai:max"] = "失去1点体力上限",
    ["bnbenghuai:all"] = "背水：摸2张牌",
    ["$bnbenghuai_select"] = "%from 选择了 %arg",
    ["bnbaonve"] = "暴虐",
    [":bnbaonve"] = "锁定技，在你杀死一名角色后，你随机对其他角色造成共计X点伤害（X为该角色体力上限）。",
    ["bnbaonve_damage"] = "剩余伤害",
    ["$bnbaonve_add_damage_log"] = "%from 将分配的伤害增加了 %arg 点， 剩余 %arg2 点",
    ["$bnbaonve_damage_log"] = "%from 将第 %arg 点伤害分配给了 %to 剩余 %arg2 点伤害。",
    ["bnhengzheng"] = "横征",
    [":bnhengzheng"] = "准备阶段，若你的手牌数不大于体力值，你可以失去1点体力，令所有其他角色依次交给你一张牌。",
    ["bnhengzheng:get"] = "你可以失去1点体力，令所有其他角色依次交给你一张牌",
    ["@bnhengzheng"] = "请交给 %src 一张牌",
    ["bnjiuchi"] = "酒池",
    [":bnjiuchi"] = "你可以将至多1张♠牌当作【酒】使用。若你没有使用实体牌，此技能于本回合内失效。你使用【酒】无次数限制。",
    ["$bnjiuchi_failed"] = "%from 的 %arg 将在本回合内失效",

    ["$bnbenghuai1"] = "崩坏",
    ["$bnbenghuai2"] = "崩坏",
    ["$bnbaonve1"] = "暴虐",
    ["$bnbaonve2"] = "暴虐",
    ["$bnhengzheng1"] = "横征",
    ["$bnhengzheng2"] = "横征",
    ["$bnjiuchi1"] = "酒池",
    ["$bnjiuchi2"] = "酒池",
    ["~bndongzhuo"] = "群阴·董卓",

    ["jscaoren"] = "群阴·曹仁",
    ["&jscaoren"] = "曹仁",
    ["#jscaoren"] = "固若金汤",
    ["designer:jscaoren"] = "Nyarz",

    ["jsjushou"] = "据守",
    [":jsjushou"] = "当你为响应而使用或打出牌时，你可以将此牌置于牌堆底，然后摸X张牌。（X为攻击范围内含有你的角色数且至少为1）",
    ["jsjushou:draw"] = "你可以将【%src】置于牌堆底并摸 %arg 张牌",
    ["jsjiewei"] = "解围",
    [":jsjiewei"] = "每回合限一次，一名角色使用【杀】或普通锦囊指定目标后，你可以令此牌的其中一名除你以外的目标从牌堆底摸牌直到其手牌数与你相等（至多摸5张）。",
    ["@jsjiewei"] = "你可以令【%src】的其中一名除你以外的目标从牌堆底摸牌直到其手牌数与你相等（至多摸5张）",

    ["$jsjushou1"] = "据守",
    ["$jsjushou2"] = "据守",
    ["$jsjushou3"] = "据守",
    ["$jsjiewei1"] = "解围",
    ["$jsjiewei2"] = "解围",
    ["~jscaoren"] = "群阴·曹仁",

    ["xscaopi"] = "群阴·曹丕",
    ["&xscaopi"] = "曹丕",
    ["#xscaopi"] = "帝王山河",
    ["designer:xscaopi"] = "Nyarz",

    ["xsxingshang"] = "行殇",
    [":xsxingshang"] = "准备阶段，你可以令一名其他角色失去1点体力，该角色于本局游戏内进入濒死状态时，你获得其所有牌，当其脱离濒死状态时，你交给其等量的牌。\
    一名其他角色死亡后，你回复1点体力并摸1张牌。",
    ["xsxingshang:death"] = "你可以回复1点体力并摸1张牌",
    ["@xsxingshang"] = "你可以令一名其他角色失去1点体力",
    ["xsreturn"] = "请选择要交还 %src 的 %arg 张牌",
    ["xsfangzu"] = "放逐",
    [":xsfangzu"] = "在你受到1点伤害后，你可以选择一项令一名其他角色执行：①其摸X张牌并翻面；②其弃置X张牌并失去1点体力。（X为你已损失的体力值）",
    ["@xsfangzu"] = "你可以放逐一名其他角色",
    ["xsfangzu:turn"] = "令其摸%src张牌并翻面",
    ["xsfangzu:discard"] = "令其弃置%src张牌并失去1点体力",
    ["xssongwei"] = "颂威",
    [":xssongwei"] = "主公技，其他魏势力角色的判定牌生效后，你可以摸一张牌。",
    ["xssongwei:draw"] = "你可以摸一张牌",

    ["$xsxingshang1"] = "行殇",
    ["$xsxingshang2"] = "行殇",
    ["$xsfangzu1"] = "放逐",
    ["$xsfangzu2"] = "放逐",
    ["$xssongwei1"] = "颂威",
    ["$xssongwei2"] = "颂威",
    ["~xscaopi"] = "群阴·曹丕",

    ["tyshendengai"] = "群阴·神邓艾",
    ["&tyshendengai"] = "邓艾",
    ["#tyshendengai"] = "神兵天降",
    ["designer:tyshendengai"] = "Nyarz",

    ["ty_tuoyu"] = "拓域",
    [":ty_tuoyu"] = "锁定技，当你使用一张牌时，须选择以下一项已解锁的效果执行（初始均未解锁）：①丰田：伤害值和回复量+1；②清渠：此牌不计入次数限制；③峻山：此牌不可被响应。",
    ["$ty_tuoyu_expand_choice"] = "%from 选择了解锁 %arg",
    ["$ty_tuoyu_effect"] = "%from 为使用的 %card 选择了效果 %arg",
    ["$ty_tuoyu_buff"] = "%from 造成的 %arg 效果因 %arg2 由 %arg3 点增加到了 %arg4 点",
    ["ty_tuoyu_fengtian"] = "丰田：伤害值和回复量+1",
    ["ty_tuoyu_qingqu"] = "清渠：此牌不计入次数限制",
    ["ty_tuoyu_junshan"] = "峻山：此牌不可被响应",
    ["ty_tuoyu_fengtian_gain"] = "丰田",
    ["ty_tuoyu_qingqu_gain"] = "清渠",
    ["ty_tuoyu_junshan_gain"] = "峻山",
    ["ty_tuoyu_recover"] = "治疗",
    ["ty_tuoyu_damage"] = "伤害",
    ["ty_xianjin"] = "险进",
    [":ty_xianjin"] = "每当你造成或受到共计2点伤害时，你解锁一项“拓域”未解锁的效果并摸一张牌。若均已解锁，你使用牌无距离限制。",
    ["tyqijin"] = "奇径",
    [":tyqijin"] = "觉醒技，每个回合结束时，若你已解锁“拓域”的全部效果，你减一点体力上限并获得“摧心”，然后你可以与一名其他角色交换座次，最后你执行一个额外的回合。",
    ["$tyqijin_wake"] = "%from 因 %arg 的效果将执行一个额外的回合",
    ["@tyqijin"] = "你可以与一名其他角色交换座次",
    ["tycuixin"] = "摧心",
    [":tycuixin"] = "在你使用牌仅指定一名其他角色为目标时，你可以观看其手牌并获得该角色一张牌。",

    ["$ty_tuoyu1"] = "拓域",
    ["$ty_tuoyu2"] = "拓域",
    ["$ty_xianjin1"] = "险进",
    ["$ty_xianjin2"] = "险进",
    ["$tyqijin1"] = "奇径",
    ["$tyqijin2"] = "奇径",
    ["$tycuixin1"] = "摧心",
    ["$tycuixin2"] = "摧心",
    ["~tyshendengai"] = "群阴·神邓艾",

    ["jjshendianwei"] = "群阴·神典韦",
    ["&jjshendianwei"] = "典韦",
    ["#jjshendianwei"] = "古之恶来",
    ["designer:jjshendianwei"] = "Nyarz",

    ["jjjuanjia"] = "捐甲",
    [":jjjuanjia"] = "锁定技，游戏开始时，你废除防具栏。你手牌中的防具牌均视为无距离和次数限制且伤害+1的【杀】。",
    ["$jjjuanjia_damage"] = "%from 造成的伤害因 %arg 的效果由 %arg2 点增加到了 %arg3 点",
    ["jjqiexie"] = "挈挾",
    [":jjqiexie"] = "锁定技，准备阶段，你从五个与【杀】有关的技能中选择至多两个获得，你至多同时拥有3个以此法获得的技能。",
    ["jjcuijue"] = "摧决",
    [":jjcuijue"] = "出牌阶段，你可以失去一个技能并指定攻击范围内的一名本回合未以此法选择过的角色，你对其造成1点伤害。若你失去的技能与【杀】无关，此技能直到回合结束失效，否则你摸两张牌。",

    ["$jjjuanjia1"] = "捐甲",
    ["$jjjuanjia2"] = "捐甲",
    ["$jjqiexie1"] = "挈挾",
    ["$jjqiexie2"] = "挈挾",
    ["$jjcuijue1"] = "摧决",
    ["$jjcuijue2"] = "摧决",
    ["~jjshendianwei"] = "群阴·神典韦",
    --刘谌

    ["ny_liuchen_diy"] = "群阴·刘谌",
    ["&ny_liuchen_diy"] = "刘谌",
    ["#ny_liuchen_diy"] = "血荐轩辕",
    ["designer:ny_liuchen_diy"] = "Nyarz",

    ["ny_zhanjue_diy"] = "战绝",
    [":ny_zhanjue_diy"] = "出牌阶段限一次或当你受到伤害后，你可以弃置所有手牌（没有则不弃）并摸X张牌，视为你使用了一张不能被无懈可击的【决斗】。（X为你的已损体力值且至少为1）",
    ["@ny_zhanjue_diy"] = "你可以弃置所有手牌（没有则不弃）并摸 %src 张牌，视为你使用了一张不能被无懈可击的【决斗】",
    ["ny_qingwang_diy"] = "勤王",
    [":ny_qingwang_diy"] = "每回合限一次，当你因弃置而失去牌时，你可以令至多等量名其他角色各交给你一张牌。\
    若你以此法获得了【杀】，你于本回合内造成伤害后恢复1点体力，且可以令本回合内交给你【杀】的角色各摸一张牌。",
    ["@ny_qingwang_diy"] = "你可以发动“勤王”令至多 %src 名其他角色交给你一张牌",
    ["ny_qingwang_diy:draw"] = "你可以发动“勤王”令本回合内交给你【杀】的角色各摸一张牌",
    ["ny_qingwang_diy_give"] = "请交给%src一张牌",
    ["ny_qingwang_diy_giveslash"] = "勤王给杀",

    ["$ny_zhanjue_diy1"] = "既抱必死之心，何存偷生之意！",
    ["$ny_zhanjue_diy2"] = "宁在雨中高歌死，绝不寄人篱下活！",
    ["$ny_qingwang_diy1"] = "关张赵黄马，毅魂归来兮！",
    ["$ny_qingwang_diy2"] = "狼烟起，大汉危，请公发兵来援！",
    ["~ny_liuchen_diy"] = "羞见基业弃与他人。",

    --杨仪

    ["ny_second_yangyi"] = "群阴·杨仪",
    ["&ny_second_yangyi"] = "杨仪",
    ["#ny_second_yangyi"] = "驭雷伏乱",
    ["designer:ny_second_yangyi"] = "Nyarz",

    ["ny_second_dingcuo"] = "定措",
    [":ny_second_dingcuo"] = "在你造成或受到伤害后，你可以摸两张牌。若这两张牌颜色不同，你弃置一张手牌。\
    若你于一回合内因此技能弃置的牌不小于你的体力上限，你将手牌数弃置至体力上限，然后该技能于本回合内失效。",
    ["$ny_second_dingcuo_failed"] = "%from 的技能 %arg 将于本回合内失效",
    ["ny_second_dingcuo:draw"] = "你可以发动“定措”摸两张牌",
    ["ny_second_juanxia"] = "狷狭",
    [":ny_second_juanxia"] = "结束阶段，你可以视为使用了至多X+1张不同牌名的普通锦囊牌（X为你本回合不因此技能造成伤害的次数）。成为这些牌目标的其他角色可以于其下个结束阶段视为对你使用了等量的【杀】。",
    ["ny_second_juanxia:use"] = "你可以发动“狷狭”视为使用了至多%src张不同牌名的普通锦囊牌",
    ["ny_second_juanxia:slash"] = "你可以视为对%src使用了%arg张【杀】",
    ["@ny_second_juanxia"] = "请使用【%src】",

    ["$ny_second_dingcuo1"] = "奋笔墨为锄，茁大汉以壮、慷国士以慨。",
    ["$ny_second_dingcuo2"] = "执金戈为尺，定国之方圆、立人之规矩。",
    ["$ny_second_juanxia1"] = "放之海内，知我者少、同我者无，可谓高处胜寒。",
    ["$ny_second_juanxia2"] = "满堂朱紫，能文者不武，为将者少谋，唯吾兼备。",
    ["~ny_second_yangyi"] = "幼主昏聩，群臣无谋，国将亡。",

    --李典

    ["nyarz_lidian_plus"] = "群阴·李典",
    ["&nyarz_lidian_plus"] = "李典",
    ["#nyarz_lidian_plus"] = "儒雅之士",
    ["designer:nyarz_lidian_plus"] = "Nyarz",

    ["nyarz_wangxi"] = "忘隙",
    [":nyarz_wangxi"] = "当你造成/受到1点伤害后，你可以摸两张牌。然后若受伤角色/伤害来源存在且不为你，你交给其一张牌。",
    ["nyarz_wangxi:draw"] = "你可以发动“忘隙”摸两张牌",
    ["nyarz_wangxi:give"] = "你可以发动“忘隙”摸两张牌并交给 %src 一张牌",
    ["@@nyarz_wangxi"] = "请交给 %src 一张牌",
    ["nyarz_xunxun"] = "恂恂",
    [":nyarz_xunxun"] = "当你不因此技能获得牌时，你可以摸X张牌，然后将一张牌置于牌堆底。（X为1  2的循环）",
    ["nyarz_xunxun:draw"] = "你可以发动“恂恂”摸%src张牌并将一张牌置于牌堆底",
    ["@@nyarz_xunxun"] = "请将一张牌置于牌堆底",

    ["$nyarz_wangxi1"] = "小隙沉舟，同心方可戮力。",
    ["$nyarz_wangxi2"] = "为天下苍生，自当化解私怨。",
    ["$nyarz_xunxun1"] = "吾乃儒雅之士，不须与诸将争功。",
    ["$nyarz_xunxun2"] = "读诗书，尚礼仪，守纲常。",
    ["~nyarz_lidian_plus"] = "恩遇及此，惶恐至极。",

    --蒋干

    ["nyarz_jianggan"] = "群阴·蒋干",
    ["&nyarz_jianggan"] = "蒋干",
    ["#nyarz_jianggan"] = "千帆征战",
    ["designer:nyarz_jianggan"] = "Nyarz",

    ["nyarz_daoshu"] = "盗书",
    [":nyarz_daoshu"] = "出牌阶段，你可以展示一名其他角色的一张牌，然后将其交给除该角色外的一名角色。若获得牌的角色不为你，你摸一张牌。\
    若你以此法于同一阶段内展示了同一角色的两张相同花色的牌，该角色对你造成1点伤害，然后你不能再对其发动“盗书”。",
    ["@@nyarz_daoshu"] = "请将此【%src】交给除 %arg 之外的一名角色",
    ["nyarz_weicheng"] = "伪诚",
    [":nyarz_weicheng"] = "准备阶段，你可以变更你的势力直到你的下个回合开始或你对势力相同的角色造成伤害后。\
    你的回合内，势力与你相同的角色手牌对你可见。你的回合外，势力与你相同的角色使用牌指定你为目标时，你摸一张牌。",
    ["nyarz_weicheng:change"] = "你可以发动“伪诚”变更你的势力",

    ["$nyarz_daoshu1"] = "赤壁之战，我军之患，不足为惧。",
    ["$nyarz_daoshu2"] = "取此机密，简直易如反掌。",
    ["$nyarz_weicheng1"] = "公瑾，吾之诚心，天地可鉴。",
    ["$nyarz_weicheng2"] = "遥闻芳烈，故来叙阔。",
    ["~nyarz_jianggan"] = "蔡张之罪，非我之过呀！",

    --刘巴

    ["nyarz_liuba"] = "群阴·刘巴",
    ["&nyarz_liuba"] = "刘巴",
    ["#nyarz_liuba"] = "清觞月澜",
    ["designer:nyarz_liuba"] = "Nyarz",

    ["nyarz_liuzhuan"] = "流转",
    [":nyarz_liuzhuan"] = "每回合限一次，一名其他角色于其摸牌阶段外获得牌时，你可以令其摸2张牌。然后本回合内当其获得牌时，将获得的牌置入弃牌堆。",
    ["nyarz_liuzhuan:draw"] = "你可以发动“流转”令 %src 摸2张牌",
    ["$MoveToDiscardPile_nyarz_liuzhuan"] = "%from 因 %arg 的效果将 %card 置入了弃牌堆",
    ["nyarz_zhubi"] = "铸币",
    [":nyarz_zhubi"] = "一名角色的准备阶段，你可以重铸一张牌。若为黑色，你摸一张牌；若为红色，你可以从牌堆或弃牌堆中将一张【无中生有】置于牌堆顶。",
    ["@@nyarz_zhubi"] = "你可以发动“铸币”重铸一张牌",
    ["nyarz_zhubi:put"] = "你可以发动“铸币”从牌堆或弃牌堆中将一张【无中生有】置于牌堆顶",
    ["$nyarz_zhubi_recast"] = "%from 发动 %arg 重铸了 %card",
    ["$nyarz_zhubi_put"] = "%from 发动 %arg 将 %card 置于牌堆顶",

    ["$nyarz_liuzhuan1"] = "半生车马，轻舟劳顿，随波逐流不知何处归乡。",
    ["$nyarz_liuzhuan2"] = "一路坎坷，流转八方，幸苍天怜我使风雨不侵。",
    ["$nyarz_zhubi1"] = "安邦定国之谋，下者曰伐，上者曰商。",
    ["$nyarz_zhubi2"] = "币同货值，货通有无，赢一钱可贾万物。",
    ["~nyarz_liuba"] = "吾主知遇之恩，某来世衔环当报。",

    --徐盛

    ["nyarz_xusheng"] = "群阴·徐盛",
    ["&nyarz_xusheng"] = "徐盛",
    ["#nyarz_xusheng"] = "破军杀将",
    ["designer:nyarz_xusheng"] = "Nyarz",

    ["nyarz_pojun"] = "破军",
    [":nyarz_pojun"] = "出牌阶段开始时，你可以视为使用了一张无距离限制且不计次数的【杀】。\
    当你使用【杀】指定目标后，你可以将目标至多X张牌移出游戏直到当前回合结束。（X为其体力上限）\
    在你对一名其他角色造成伤害时，若其武将牌上有因此技能移出游戏的牌，你获得其中一半。（向上取整）",
    ["@nyarz_pojun"] = "你可以视为使用了一张无距离限制且不计次数的【杀】",
    ["nyarz_pojun:put"] = "你可以发动“破军”将 %src 至多 %arg 张牌移出游戏直到当前回合结束",

    ["$nyarz_pojun1"] = "战将临阵，斩关刈城！",
    ["$nyarz_pojun2"] = "区区数百魏军，看我一击灭之。",
    ["~nyarz_xusheng"] = "来世……愿再为我江东之臣！",

    --李儒

    ["nyarz_liru"] = "群阴·李儒",
    ["&nyarz_liru"] = "李儒",
    ["#nyarz_liru"] = "烈火焚城",
    ["designer:nyarz_liru"] = "Nyarz",

    ["nyarz_juece"] = "绝策",
    [":nyarz_juece"] = "每回合限一次，一名其他角色于其回合外失去牌时，你可以对其造成1点伤害，然后若此时不在你的回合内，你弃置一张牌。\
    若其没有手牌，你重置此技能，然后可以选择一项：①令此伤害+1；②摸2张牌。",
    ["nyarz_juece:damageto"] = "你可以对 %src 造成1点伤害",
    ["nyarz_juece:damage"] = "令此伤害+1",
    ["nyarz_juece:draw"] = "摸2张牌",
    ["nyarz_mieji"] = "灭计",
    [":nyarz_mieji"] = "出牌阶段限一次，你可以展示任意张普通锦囊牌，然后弃置一名其他角色等量的牌。\
    本阶段内，你使用这些牌只能指定你与该角色为目标。出牌阶段结束时，弃置你以此法展示过的牌。",
    ["nyarz_fencheng"] = "焚城", 
    [":nyarz_fencheng"] = "限定技，出牌阶段，你可以对所有其他角色依次造成1点火焰伤害，然后这些角色依次弃置装备区的所有牌。", 

    ["$nyarz_juece1"] = "我，最喜欢落井下石。",
    ["$nyarz_juece2"] = "一无所有？那就拿命来填！",
    ["$nyarz_mieji1"] = "我要的是斩草除根。",
    ["$nyarz_mieji2"] = "叫天天不应，叫地地不灵~",
    ["$nyarz_fencheng1"] = "我要这满城的人都来给你陪葬。", 
    ["$nyarz_fencheng2"] = "一把火烧他个精光吧！诶啊哈哈哈哈哈~", 
    ["~nyarz_liru"] = "乱世的好戏才刚刚开始……",

    --陆逊·武

    ["nyarz_luxun_wu"] = "群阴·陆逊·武",
    ["&nyarz_luxun_wu"] = "陆逊",
    ["#nyarz_luxun_wu"] = "释武怀儒",
    ["designer:nyarz_luxun_wu"] = "Nyarz",

    ["nyarz_xiongmu_wu"] = "雄幕",
    [":nyarz_xiongmu_wu"] = "锁定技，当你即将受到伤害时，若你的手牌数不大于体力上限，你从牌堆中获得一张点数为8的牌。若你以此法获得了牌，防止此伤害。",
    ["$nyarz_xiongmu_wu_last"] = "牌堆中剩余点数为8的牌的数量为 %arg ",
    ["nyarz_zhangcai_wu"] = "彰才",
    [":nyarz_zhangcai_wu"] = "每回合限一次，当你使用的牌结算后，你可以将弃牌堆中所有与此牌点数相同的牌洗入牌堆，然后摸等量的牌。\
    若如此做，本局游戏内你使用或打出与此牌点数相同的牌时可以摸X张牌。（X为该点数的牌被此技能洗入牌堆的次数）",
    ["nyarz_zhangcai_wu:shuffle"] = "你可以发动“彰才”将弃牌堆中所有点数为%src的牌洗入牌堆并摸%arg张牌",
    ["nyarz_zhangcai_wu:draw"] = "你可以发动“彰才”摸%src张牌",
    ["nyarz_zhangcai_wu_show"] = "彰才",
    [":nyarz_zhangcai_wu_show"] = "出牌阶段，你可以查看每种点数的牌已发动“彰才”的次数",
    ["nyarz_zhangcai_wu:show"] = "点数为 %src 的牌已发动过 %arg 次“彰才”",
    ["nyarz_ruxian_wu"] = "儒贤",
    [":nyarz_ruxian_wu"] = "限定技，出牌阶段，你可以令“彰才”中X的基础值+1直到你的下个回合开始，然后本回合弃牌阶段结束时，你获得手牌中缺少的点数的牌各一张（总数至多为你的弃牌数），这些牌不计入你的手牌上限。",

    ["$nyarz_xiongmu_wu1"] = "步步为营者，定无后顾之虞。",
    ["$nyarz_xiongmu_wu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
    ["$nyarz_zhangcai_wu1"] = "今提墨笔绘乾坤，湖海添色山永春。",
    ["$nyarz_zhangcai_wu2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
    ["$nyarz_ruxian_wu1"] = "儒道尚仁而有礼，贤者知名而独悟。",
    ["$nyarz_ruxian_wu2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
    ["~nyarz_luxun_wu"] = "此生清白，不为浊泥所染。",

    --凌统

    ["nyarz_lingtong"] = "群阴·凌统",
    ["&nyarz_lingtong"] = "凌统",
    ["#nyarz_lingtong"] = "乘帆破浪",
    ["designer:nyarz_lingtong"] = "Nyarz",

    ["nyarz_xuanfeng"] = "旋风",
    [":nyarz_xuanfeng"] = "当你失去装备区的一张牌后，或一次性失去两张牌后，你可以弃置至多两名其他角色的共计至多两张牌。若此时在你的回合内，你可以对其中一名角色造成1点伤害。",
    ["@nyarz_xuanfeng"] = "你可以发动“旋风”弃置至多两名其他角色的共计至多两张牌",
    ["nyarz_xuanfeng_discard"] = "你可以再弃置一名其他角色的一张牌",
    ["nyarz_xuanfeng_damage"] = "你可以对其中一名目标角色造成1点伤害",
    ["nyarz_xuanfeng_damageto"] = "旋风",
    ["nyarz_yongjin"] = "勇进",
    [":nyarz_yongjin"] = "出牌阶段限一次，你可以选择一项执行：\
    ①重铸至多两张牌；\
    ②移动场上一张牌；\
    背水：失去一点体力并摸一张牌。",
    ["nyarz_yongjin:recast"] = "重铸至多两张牌",
    ["nyarz_yongjin:move"] = "移动场上一张牌",
    ["nyarz_yongjin:all"] = "背水：失去一点体力并摸一张牌",

    ["$nyarz_xuanfeng1"] = "沙场捕虏击旋踵，麾下分炙歌大风。",
    ["$nyarz_xuanfeng2"] = "袭如霹雳摧高阙，进如大浪卷狂风。",
    ["$nyarz_xuanfeng3"] = "风火急袭荡敌寇，剑阙甲裂惊旋风。",
    ["$nyarz_xuanfeng4"] = "龙卷江水浪滔天，且看虎贲击潮头。",
    ["$nyarz_yongjin1"] = "此间狭路相逢，安敢逡巡畏战。",
    ["$nyarz_yongjin2"] = "寇纵有千万，吾亦进而击之。",
    ["~nyarz_lingtong"] = "恨未死沙场，而亡于病榻。",

    --左慈
    
    ["nyarz_zuoci"] = "群阴·左慈",
    ["&nyarz_zuoci"] = "左慈",
    ["#nyarz_zuoci"] = "道法显威",
    ["designer:nyarz_zuoci"] = "Nyarz",

    ["nyarz_huashen"] = "化身",
    [":nyarz_huashen"] = "每轮游戏开始时，你可以移去至多两张“魂”牌，然后从这些“魂”牌的技能中选择至多等量的技能于本轮中获得。\
    游戏开始时，或当你受到1点伤害后，或每轮游戏开始时，你可以获得两张未拥有的武将牌作为“魂”牌。",
    ["nyarz_huashen:draw"] = "你可以获得两张未拥有的武将牌作为“魂”牌",
    ["nyarz_huashen:change"] = "你可以移去至多两张“魂”牌，然后从这些“魂”牌的技能中选择至多等量的技能于本轮中获得",
    ["nyarz_huashen:giveup"] = "放弃获得第二个技能，不失去第二张选择的“魂”牌",
    ["$nyarz_huashen_new"] = "%from 将 %arg 加入了“魂”牌",
    ["$nyarz_huashen_lose"] = "%from 移去了“魂”牌 %arg",
    ["nyarz_xinsheng"] = "新生",
    [":nyarz_xinsheng"] = "出牌阶段限一次，你可以移去一张【魂】牌并摸X张牌。（X为此“魂”牌体力上限的一半向上取整）\
    当你对其他角色造成伤害后，若你没有其武将牌的“魂”牌，获得之，否则你获得一张随机“魂”牌。\
    当你移去“魂”后，可以令一名与“魂”势力相同的角色恢复1点体力。",
    ["nyarz_souls"] = "魂",
    ["@nyarz_xinsheng"] = "你可以令一名 %src 势力角色恢复1点体力",

    ["$nyarz_huashen1"] = "俯观人间百态，化身游雾期间。",
    ["$nyarz_huashen2"] = "贫道身化万方，型满亦得其意。",
    ["$nyarz_xinsheng1"] = "生为死之初，死为生之始。",
    ["$nyarz_xinsheng2"] = "木枯而发枝耳，身死乃见新生。",
    ["~nyarz_zuoci"] = "仙迹难觅，道法难参。",
    ["$nyarz_zuoci"] = "奸臣起乾坤失序，辅忠良重整阴阳。",

    --孙翊

    ["nyarz_sunyi"] = "群阴·孙翊",
    ["&nyarz_sunyi"] = "孙翊",
    ["#nyarz_sunyi"] = "腾龙翻江",
    ["designer:nyarz_sunyi"] = "Nyarz",

    ["nyarz_jiqiao"] = "激峭",
    [":nyarz_jiqiao"] = "当你使用或打出一张牌时，你可以摸两张牌，然后可以重铸一张手牌，最后若你的所有手牌颜色相同，你回复一点体力，否则你失去一点体力。",
    ["nyarz_jiqiao:draw"] = "你可以发动“激峭”摸两张牌",
    ["@nyarz_jiqiao"] = "你可以重铸一张手牌",

    ["$nyarz_jiqiao1"] = "大丈夫行事，理应如火如荼！",
    ["$nyarz_jiqiao2"] = "真男儿性情，当如烈火轰雷！",
    ["~nyarz_sunyi"] = "吾竟死于此等小人之手，恨哉！恨哉！",

    --刘备

    ["nyarz_liubei"] = "群阴·刘备",
    ["&nyarz_liubei"] = "刘备",
    ["#nyarz_liubei"] = "龙御天下",
    ["designer:nyarz_liubei"] = "Nyarz",

    ["nyarz_rende"] = "仁德",
    [":nyarz_rende"] = "这个技能的②③效果一轮各可以发动最多4次。\
    ①出牌阶段，你可以将至少2张牌交给一名本阶段内未以此法获得过牌的角色，然后令②本局可用次数+1。\
    ②每局游戏限1次，你可以视为使用或打出一张任意的基本牌。\
    ③每个回合的结束阶段，若你本回合发动过此技能，你可以摸X+1张牌。（X为此技能本回合发动次数）\
    ④③效果未使用的你的结束阶段，令②本局可用次数+1。",
    ["nyarz_rende:draw"] = "你可以发动“仁德”摸 %src 张牌",
    ["nyarz_rendebasic"] = "仁德",
    [":nyarz_rendebasic"] = "每局游戏限1次，你可以视为使用或打出一张任意的基本牌。",
    ["nyarz_renwang"] = "仁望",
    [":nyarz_renwang"] = "锁定技，每回合限一次，你即将受到伤害时，防止此伤害，然后伤害来源摸一张牌。若伤害来源为蜀势力角色，其可以改为令你摸两张牌，否则其可以将势力改为蜀。",
    ["nyarz_renwang:change"] = "你可以将势力改为“蜀”",
    ["nyarz_renwang:draw"] = "你可以改为令 %src 摸两张牌",
    ["$nyarz_renwang_damage"] = "%from 因 %arg 效果防止了即将受到的 %arg2 点伤害",
    ["$nyarz_renwang_change"] = "%from 将势力改为 %arg",
    ["nyarz_zhangwu"] = "章武",
    [":nyarz_zhangwu"] = "主公技，限定技，准备阶段，若场上存在已死亡的蜀势力忠臣，你可以失去“仁德”，获得“龙怒”，然后加2点体力上限并恢复2点体力。",
    ["nyarz_longnu"] = "龙怒",
    [":nyarz_longnu"] = "①你可以将红色牌当作无距离限制且不可响应的【杀】使用或打出。\
    ②你可以重铸一张锦囊牌并令你本阶段内使用【杀】次数上限+1。\
    ③结束阶段，若你本回合未杀死角色，你失去X点体力并摸3X张牌。（X为此效果触发次数）",

    ["$nyarz_rende1"] = "修德累仁，则汉道克昌！",
    ["$nyarz_rende2"] = "迈仁树德，焘宇内无疆！",
    ["$nyarz_renwang1"] = "以仁待民，民必不使其倾危！",
    ["$nyarz_renwang2"] = "折而不挠，终不为人下！",
    ["$nyarz_zhangwu1"] = "铸剑章武，昭朕肃烈之志！",
    ["$nyarz_zhangwu2"] = "起誓鸣戎，决吾共死之意！",
    ["$nyarz_longnu1"] = "神龙降天怒，雷火震仇雠。",
    ["$nyarz_longnu2"] = "手足之伤，不共戴天。",
    ["~nyarz_liubei"] = "朕躬德薄，望吾儿切勿效之……",

    --沮授

    ["nyarz_jushou"] = "群阴·沮授",
    ["&nyarz_jushou"] = "沮授",
    ["#nyarz_jushou"] = "策胜珠玑",
    ["designer:nyarz_jushou"] = "Nyarz",

    ["nyarz_shibei"] = "矢北",
    [":nyarz_shibei"] = "锁定技，你每回合第一次受到伤害后回复等量体力，第二次受到伤害后失去1点体力，第三次及以后受到的伤害视作失去体力。",
    ["nyarz_jianying"] = "渐营",
    [":nyarz_jianying"] = "你使用或打出牌时，若此牌与你使用或打出的上一张牌的点数或花色相同，则你可以摸一张牌，且使用此牌无次数和距离限制。\
    出牌阶段，你可以弃置两张牌，然后：\
    ①从两张点数与弃置的牌的点数之和对13取余相等的牌中选择一张获得；\
    ②从两张花色与弃置的牌的花色分别对应相同的牌中选择一张获得。",
    ["nyarz_jianying:draw"] = "你可以发动“渐营”摸一张牌",
    ["nyarz_jianying:suit"] = "从两张花色与弃置的牌的花色分别对应相同的牌中选择一张获得",
    ["nyarz_jianying:number"] = "从两张点数与弃置的牌的点数之和对13取余相等的牌中选择一张获得",

    ["$nyarz_shibei1"] = "只有杀身士，绝无降曹夫。",
    ["$nyarz_shibei2"] = "心向袁氏，绝无背离可言。",
    ["$nyarz_jianying1"] = "良谋百出，渐定决战胜势。",
    ["$nyarz_jianying2"] = "佳策数成，破敌垂手可得。",
    ["~nyarz_jushou"] = "授，无愧主公之恩。",

    --周瑜·谋

    ["nyarz_zhouyu_mou"] = "群阴·周瑜·谋",
    ["#nyarz_zhouyu_mou"] = "炽谋英隽",
    ["&nyarz_zhouyu_mou"] = "周瑜",
    ["designer:nyarz_zhouyu_mou"] = "Nyarz",

    ["nyarz_ronghuo_mou"] = "融火",
    [":nyarz_ronghuo_mou"] = "锁定技，你造成的火焰伤害基数+X（X为存活势力数）。你每回合首次使用或打出【杀】时，获得一张不计入次数限制的【火杀】。",
    ["nyarz_yingmou_mou"] = "英谋",
    ["#nyarz_yingmou_mou"] = "英谋",
    [":nyarz_yingmou_mou"] = "每回合限一次，你使用的牌结算后，你可以执行一项：\
    ①将手牌摸至与其中一名目标相同，然后视为使用了一张不能被抵消的【火攻】；\
    ②展示一名不是此牌目标的角色手牌中的所有伤害类牌，然后可以使用之或令其将手牌弃至与你相同。\
    若你杀死过角色，改为每回合各限一次。",
    ["$nyarz_yingmou_mou_chosen"] = "%from 选择了 %arg",
    ["nyarz_yingmou_mou:draw"] = "将手牌摸至与其中一名目标相同，然后视为使用了一张不能被抵消的【火攻】",
    ["nyarz_yingmou_mou:show"] = "展示一名不是此牌目标的角色手牌中的所有伤害类牌，然后可以使用之或令其将手牌弃至与你相同",
    ["nyarz_yingmou_mou:discard"] = "令%src将手牌弃至与你相同",
    ["nyarz_yingmou_mou:use"] = "使用%src手牌中的伤害类牌",
    ["@nyarz_yingmou_mou"] = "请使用 %src",
    ["nyarz_yingmou_mou_damagecard"] = "其中一张伤害类牌",
    ["nyarz_yingmou_mou_draw_chosen"] = "请选择一名目标，将手牌摸至与其相同，然后视为使用了一张不能被抵消的【火攻】",
    ["nyarz_yingmou_mou_show_chosen"] = "请选择一名目标，展示其手牌中的所有伤害类牌，然后可以使用之或令其将手牌弃至与你相同",

    ["$nyarz_ronghuo_mou1"] = "火莲绽江矶，炎映三千弱水。",
    ["$nyarz_ronghuo_mou2"] = "奇志吞樯橹，潮平百万寇贼。",
    ["$nyarz_yingmou_mou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
    ["$nyarz_yingmou_mou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
    ["~nyarz_zhouyu_mou"] = "人生之艰难，犹如不息之长河。",

    --鲁肃·谋

    ["nyarz_lusu_mou"] = "群阴·鲁肃·谋",
    ["&nyarz_lusu_mou"] = "鲁肃",
    ["#nyarz_lusu_mou"] = "鸿谋翼远",
    ["designer:nyarz_lusu_mou"] = "Nyarz",

    ["nyarz_mingshi_mou"] = "明势",
    [":nyarz_mingshi_mou"] = "每阶段限一次，你一次性获得至少两张牌后，可以摸两张牌，然后展示三张牌并令一名其他角色获得其中一张。",
    ["nyarz_mingshi_mou:draw"] = "你可以发动“明势”摸两张牌",
    ["@nyarz_mingshi_mou"] = "请展示三张牌并选择一名其他角色",
    ["nyarz_mengmou_mou"] = "盟谋",
    [":nyarz_mengmou_mou"] = "当你获得其他角色的手牌，或其他角色获得你的手牌后，你可以摸两张牌，然后选择一项令其执行：\
    ①使用一张【杀】，若造成伤害则其回复一点体力；\
    ②使用一张【杀】，若未造成伤害则其失去一点体力。",
    ["nyarz_mengmou_mou:to"] = "你可以发动 “盟谋”摸两张牌并令 %src 使用【杀】",
    ["nyarz_mengmou_mou:recover"] = "令 %src 使用一张【杀】，若造成伤害则其回复一点体力",
    ["nyarz_mengmou_mou:lose"] = "令 %src 使用一张【杀】，若未造成伤害则其失去一点体力",
    ["nyarz_mengmou_mou_recover"] = "请使用【杀】，若造成伤害你将回复一点体力",
    ["nyarz_mengmou_mou_lose"] = "请使用【杀】，若未造成伤害你将失去一点体力",
    ["$nyarz_mengmou_mou_chosen"] = "%from 选择了 %arg",
    ["nyarz_mengmou_mou_recover_log"] = "使用一张【杀】，若造成伤害则其回复一点体力",
    ["nyarz_mengmou_mou_lose_log"] = "使用一张【杀】，若未造成伤害则其失去一点体力",

    ["$nyarz_mingshi_mou1"] = "联刘以抗曹，此可行之大势。",
    ["$nyarz_mingshi_mou2"] = "强敌在北，唯协力可御之。",
    ["$nyarz_mengmou_mou1"] = "合左抑右，定两家之盟。",
    ["$nyarz_mengmou_mou2"] = "求同存异，邀英雄问鼎。",
    ["~nyarz_lusu_mou"] = "虎可为之用，亦可为之伤。",

    --诸葛瑾

    ["nyarz_zhugejin"] = "群阴·诸葛瑾",
    ["&nyarz_zhugejin"] = "诸葛瑾",
    ["#nyarz_zhugejin"] = "风雅神逸",
    ["designer:nyarz_zhugejin"] = "Nyarz",

    ["nyarz_mingzhe"] = "明哲",
    [":nyarz_mingzhe"] = "锁定技，当你于出牌阶段外失去红色牌后，你展示之并摸等量的牌。",
    ["nyarz_huanshi"] = "缓释",
    [":nyarz_huanshi"] = "一名角色的判定牌生效前，你可以展示至少两张牌，令其选择其中一张代替判定牌，然后你重铸剩下的牌。",
    ["@nyarz_huanshi"] = "你可以发动“缓释”，为 %src 的 “%arg” 判定展示至少两张牌",
    ["nyarz_huanshi_chosen"] = "请选择一张牌作为“%src”的判定牌",
    ["nyarz_hongyuan"] = "弘援",
    [":nyarz_hongyuan"] = "每阶段限一次，你一次性获得至少两张牌后，可以交给至多等量名其他角色各一张牌。",
    ["nyarz_hongyuan:give"] = "你可以发动“弘援”交给至多 %src 名其他角色各一张牌",
    ["@nyarz_hongyuan"] = "你可以将一张牌交给本次未以此法获得过牌的其他角色",
    ["nyarz_hongyuan_chosen"] = "已给过牌",

    ["$nyarz_mingzhe1"] = "知势则明志，明志则练达。",
    ["$nyarz_mingzhe2"] = "知之曰明哲，明哲实作则。",
    ["$nyarz_huanshi1"] = "仁者，信者，行天下。",
    ["$nyarz_huanshi2"] = "以君子之道，行兵家之事。",
    ["$nyarz_hongyuan1"] = "后援即刻就到，诸将莫急。",
    ["$nyarz_hongyuan2"] = "只待援军内外夹攻，必胜！",
    ["~nyarz_zhugejin"] = "遇明主，得偿毕生所愿，足矣。",

    --郭嘉

    ["nyarz_guojia"] = "群阴·郭嘉",
    ["&nyarz_guojia"] = "郭嘉",
    ["#nyarz_guojia"] = "一世风华",
    ["designer:nyarz_guojia"] = "Nyarz",

    ["nyarz_tiandu"] = "天妒",
    [":nyarz_tiandu"] = "锁定技，你的判定牌生效后，获得之。准备阶段，你进行判定并令你本局游戏摸牌阶段摸牌数和手牌上限+1(至多+5)，若不为♥，你受到1点无来源的伤害。",
    [":&nyarz_tiandu"] = "你的摸牌数和手牌上限+%src",
    ["nyarz_yiji"] = "遗计",
    [":nyarz_yiji"] = "当你受到1点伤害后，你可以摸2张牌，然后可以将任意张牌分配给任意名其他角色。你进入濒死时，可以从牌堆获得一张智囊牌。你死亡时，可以将区域内的全部牌交给一名其他角色。",
    ["nyarz_yiji_death"] = "你可以将区域内的全部牌交给一名其他角色",
    ["nyarz_yiji:draw"] = "你可以发动“遗计”摸2张牌",
    ["nyarz_yiji:trick"] = "你可以发动“遗计”从牌堆获得一张智囊牌",
    ["@nyarz_yiji"] = "你可以将任意张牌分配给一名其他角色",

    ["$nyarz_tiandu1"] = "如你所愿。",
    ["$nyarz_tiandu2"] = "这种感觉是...",
    ["$nyarz_yiji1"] = "策谋本天成，妙手偶得之。",
    ["$nyarz_yiji2"] = "此有锦囊若干，公可依计行事。",
    ["~nyarz_guojia"] = "死亡并不是结束。",

    --赵俨

    ["nyarz_zhaoyan"] = "群阴·赵俨",
    ["&nyarz_zhaoyan"] = "赵俨",
    ["#nyarz_zhaoyan"] = "酣战方遒",
    ["designer:nyarz_zhaoyan"] = "Nyarz",

    ["nyarz_funing"] = "抚宁",
    [":nyarz_funing"] = "锁定技，你使用【杀】无距离限制。\
    每回合每种花色限一次，在你使用的【杀】结算后，若你的手牌中有与此【杀】相同花色的牌，你重铸这些牌并摸一张牌，令此【杀】不计入次数限制。否则你失去1点体力并摸3张牌，令此技能失效直到回合结束。",
    [":&nyarz_funing"] = "“抚宁”将于本回合内失效",
    ["nyarz_funing_suit"] = "抚宁：",
    ["nyarz_bingji"] = "秉纪",
    [":nyarz_bingji"] = "锁定技，当你失去牌后，若你手牌中因此技能无法使用的牌数不大于其他牌，你摸本次失去牌数量的牌（至多为你的体力值），因此获得的牌不计入手牌上限且无法使用直到你的回合结束。",

    ["$nyarz_funing1"] = "今天下不安，为官一方者当权衡利弊，以安民心。",
    ["$nyarz_funing2"] = "我负朝廷之望，怎可弃重而取轻？",
    ["$nyarz_bingji1"] = "奉丞相敕令，督七军备战，赏罚之令皆出于我。",
    ["$nyarz_bingji2"] = "治一郡如统三军，唯赏罚分明可保其境。",
    ["~nyarz_zhaoyan"] = "四面皆敌，实不知该如何是好。",

    --卧龙凤雏

    ["nyarz_longfeng"] = "群阴·卧龙凤雏",
    ["&nyarz_longfeng"] = "卧龙凤雏",
    ["#nyarz_longfeng"] = "青羽锦绣",
    ["designer:nyarz_longfeng"] = "Nyarz",

    ["nyarz_youlong"] = "游龙",
    [":nyarz_youlong"] = "转换技，若你有未废除的装备栏，你可以废除一个装备栏并摸一张牌，视为使用一张本轮未以此法使用过的：阳：基本牌；阴：普通锦囊牌。",
    [":nyarz_youlong1"] = "转换技，若你有未废除的装备栏，你可以废除一个装备栏并摸一张牌，视为使用一张本轮未以此法使用过的：阳：基本牌；<font color=\"#01A5AF\"><s>阴：普通锦囊牌。</s></font>",
    [":nyarz_youlong2"] = "转换技，若你有未废除的装备栏，你可以废除一个装备栏并摸一张牌，视为使用一张本轮未以此法使用过的：<font color=\"#01A5AF\"><s>阳：基本牌；</s></font>阴：普通锦囊牌。",
    ["@nyarz_youlong"] = "请使用【%src】",
    ["nyarz_youlong:0"] = "武器栏",
    ["nyarz_youlong:1"] = "防具栏",
    ["nyarz_youlong:2"] = "+1坐骑栏",
    ["nyarz_youlong:3"] = "-1坐骑栏",
    ["nyarz_youlong:4"] = "宝物栏",
    ["nyarz_youlong:nocards"] = "没有可以使用的牌",
    ["nyarz_luanfeng"] = "鸾凤",
    [":nyarz_luanfeng"] = "每轮限一次，出牌阶段/一名角色处于濒死状态时，你可以令一名角色/其将体力回复至3点，手牌摸至6张，恢复所有被废除的装备栏。你首次发动“鸾凤”后，令此技能中所有数字减半（向下取整）。",
    [":&nyarz_luanfeng"] = "“鸾凤”改为将体力回复至1点，手牌摸至3张",

    ["$nyarz_youlong1"] = "北伐中原，龙游雍凉，声震千里魏土。",
    ["$nyarz_youlong2"] = " 南安百黎，虬渡泸水，锦铺万洞蛮邦。",
    ["$nyarz_luanfeng1"] = "东庭梧桐，遍着锦绣，引凤凰来栖。",
    ["$nyarz_luanfeng2"] = "西蜀漫道，澄空万里，纵神鸟翱翔。",
    ["~nyarz_longfeng"] = "白簇没凤躯，龙陨五丈原。",

    --神吕布

    ["nyarz_lvbu_god"] = "群阴·神吕布",
    ["&nyarz_lvbu_god"] = "吕布",
    ["#nyarz_lvbu_god"] = "戾火浮屠",
    ["designer:nyarz_lvbu_god"] = "Nyarz",

    ["nyarz_wumou_god"] = "无谋",
    [":nyarz_wumou_god"] = "锁定技，在你使用的普通锦囊牌结算后，你选择一项：①弃置一枚“暴怒”标记；②受到1点无来源的伤害，然后视为对此牌目标包含的所有其他角色使用了一张【杀】。",
    ["nyarz_wumou_god:damaged"] = "受到1点无来源的伤害，然后视为对此牌目标包含的所有其他角色使用了一张【杀】",
    ["nyarz_wumou_god:dismark"] = "弃置一枚“暴怒”标记",
    ["nyarz_wuqian_god"] = "无前",
    [":nyarz_wuqian_god"] = "出牌阶段限两次，你可以受到1点无来源的伤害，视为你使用了一张【杀】或【决斗】。",
    ["nyarz_wuqian_god:slash"] = "杀",
    ["nyarz_wuqian_god:fire_slash"] = "火杀",
    ["nyarz_wuqian_god:thunder_slash"] = "雷杀",
    ["nyarz_wuqian_god:duel"] = "决斗",
    ["nyarz_shenfen_god"] = "神愤",
    [":nyarz_shenfen_god"] = "出牌阶段限一次，你可以弃6枚“暴怒”标记，然后对所有其他角色各造成1点伤害，这些角色先各弃置装备区里的所有牌，再弃置四张手牌，最后你翻面。你死亡时，也可以如此做。",
    ["@nyarz_shenfen_god"] = "你可以发动“神愤”，令所有其他角色与你共渡黄泉",
    ["nyarz_kuangbao_god"] = "狂暴",
    [":nyarz_kuangbao_god"] = "锁定技，你造成或受到伤害后，你获得1枚“暴怒”标记。若“暴怒”标记：不小于3，你视为拥有“无双”；不小于6，你视为拥有“神戟”；不小于9，你视为拥有“神威”。",
    ["nyarz_baonu_god"] = "暴怒",
    ["nyarz_wushuang_god"] = "无双",
    [":nyarz_wushuang_god"] = "锁定技，你使用【杀】或【决斗】指定目标后，或当你成为【决斗】的目标后，令对方选择一项：①无法响应此牌；②此牌对其造成的伤害+1。",
    ["nyarz_wushuang_god:no"] = "不能响应【%src】",
    ["nyarz_wushuang_god:up"] = "【%src】对你造成的伤害+1",
    ["nyarz_shenji_god"] = "神戟",
    [":nyarz_shenji_god"] = "锁定技，你使用【杀】或【决斗】无距离限制且可以额外指定两个目标。",
    ["nyarz_shenwei_god"] = "神威",
    [":nyarz_shenwei_god"] = "锁定技，摸牌阶段，你多摸2张牌。你的手牌上限改为体力上限+2。",

    ["$nyarz_wumou_god1"] = "暗行鬼域，言惑魍魉，非英雄哉。",
    ["$nyarz_wumou_god2"] = "既已以武立身，何须与鼠谋皮！",
    ["$nyarz_wuqian_god1"] = "此身独霸天下，试问天下武夫谁可当之。",
    ["$nyarz_wuqian_god2"] = "横戟征天，凭此间气力、可斩太上神佛。",
    ["$nyarz_shenfen_god1"] = "区区肉胎凡夫，何堪修罗之怒。",
    ["$nyarz_shenfen_god2"] = "神魔之怒，上折不周之柱，下涸九幽之泉。",
    ["$nyarz_kuangbao_god1"] = "我有滔天之怒，可使四海潮立、八荒陆沉！",
    ["$nyarz_kuangbao_god2"] = "吾怒如燎原之火，欲焚九州为炼狱。",
    ["$nyarz_wushuang_god1"] = "赤兔踏幽冥，烈戟扫神魔！",
    ["$nyarz_wushuang_god2"] = "我本纵横天下，何惧万世轮回。",
    ["$nyarz_shenji_god1"] = "断轮回，笑忘川，招旧部，战黄泉！",
    ["$nyarz_shenji_god2"] = "化修罗，修战矛，斩三尸，征九天！",
    ["$nyarz_shenwei_god1"] = "百战轮回锻神躯，我以修罗张天魔！",
    ["$nyarz_shenwei_god2"] = "六道何须论因果，独霸炼狱斩阎罗！",
    ["~nyarz_lvbu_god"] = "此去黄泉，当再斩阎罗。",

    --留赞

    ["nyarz_liuzan"] = "群阴·留赞",
    ["&nyarz_liuzan"] = "留赞",
    ["#nyarz_liuzan"] = "高歌陷陈",
    ["designer:nyarz_liuzan"] = "Nyarz",

    ["nyarz_fenyin"] = "奋音",
    [":nyarz_fenyin"] = "锁定技，每有8张牌进入弃牌堆（你的回合内改为4张），你摸一张牌。",
    [":&nyarz_fenyin"] = "已有 %src 张牌进入弃牌堆",
    ["nyarz_liji"] = "力激",
    [":nyarz_liji"] = "当你于摸牌阶段外获得牌后，你可以弃置等量的牌并对一名其他角色造成1点伤害。",
    ["@nyarz_liji"] = "你可以弃置 %src 张牌并对一名其他角色造成1点伤害",

    ["$nyarz_fenyin1"] = "昂首长歌，振奋作声。",
    ["$nyarz_fenyin2"] = "奋音震天，力荡山河。",
    ["$nyarz_liji1"] = "蓄势待发，全力一搏！",
    ["$nyarz_liji2"] = "以寡敌众，遂相腾击。",
    ["~nyarz_liuzan"] = "战先陷陈，生死无顾！",

    --张华

    ["nyarz_zhanghua"] = "群阴·张华",
    ["&nyarz_zhanghua"] = "张华",
    ["#nyarz_zhanghua"] = "双剑化龙",
    ["designer:nyarz_zhanghua"] = "Nyarz",
 
    ["nyarz_chuanwu"] = "穿屋",
    [":nyarz_chuanwu"] = "锁定技，你造成或受到伤害后，须失去一个技能直到回合结束，然后摸X张牌（X为你的攻击范围）。",
    ["nyarz_bihun"] = "弼昏",
    [":nyarz_bihun"] = "锁定技，你使用的基本牌或普通锦囊牌结算后，令此牌目标包含的一名其他角色获得之。",
    ["@nyarz_bihun"] = "你须令一名目标角色获得此【%src】",
    ["nyarz_jianhe"] = "剑合",
    [":nyarz_jianhe"] = "出牌阶段，你可以选择一名角色并重铸任意至少两张相同类型的牌，除非其重铸等张与你重铸的牌类型相同的牌，否则其受到1点雷电伤害。\
    然后你选择本阶段未为该角色选择的一项：①本阶段不能对其使用牌；②本阶段不能对其发动“剑合”。",
    ["@nyarz_jianhe"] = "请重铸 %src 张 %arg <br/>或取消并受到1点雷电伤害",
    ["nyarz_jianhe:card"] = "本阶段不能对其使用牌",
    ["nyarz_jianhe:skill"] = "本阶段不能对其发动“剑合”",
    ["nyarz_jianhe_card"] = "剑合：牌",
    ["nyarz_jianhe_skill"] = "剑合：技",
    ["$nyarz_jianhe_chosen"] = "%from 选择了 %arg",

    ["$nyarz_chuanwu1"] = "祝融侵库，剑怀远志。",
    ["$nyarz_chuanwu2"] = "斩蛇穿屋，其志绥远。",
    ["$nyarz_bihun1"] = "辅弼天家，以扶朝纲。",
    ["$nyarz_bihun2"] = "为国治政，尽忠匡辅。",
    ["$nyarz_jianhe1"] = "身临朝阙，腰悬太阿。",
    ["$nyarz_jianhe2"] = "位登三事，当配龙泉。",
    ["~nyarz_zhanghua"] = "桑化为柏，此非不祥乎？",

    --赵云·神

    ["nyarz_zhaoyun_god"] = "群阴·赵云·神",
    ["&nyarz_zhaoyun_god"] = "赵云",
    ["#nyarz_zhaoyun_god"] = "天龙乘云",
    ["designer:nyarz_zhaoyun_god"] = "Nyarz",
    
    ["nyarz_jvejin_god"] = "绝境",
    [":nyarz_jvejin_god"] = "锁定技，当你失去最后的手牌后，或当你的体力值变化后，你将手牌摸至【4】张。若你未因此获得牌，令【】中数字+1，至多增加至7。",
    [":nyarz_jvejin_god1"] = "锁定技，当你失去最后的手牌后，或当你的体力值变化后，你将手牌摸至【%arg1】张。若你未因此获得牌，令【】中数字+1，至多增加至7。",
    [":&nyarz_jvejin_god"] = "触发“绝境”时额外摸 %src 张牌",
    ["nyarz_longhun_god"] = "龙魂",
    [":nyarz_longhun_god"] = "你可以弃置【1】张花色相同的牌，或重铸【2】张花色相同的牌，视作你使用或打出了一张【火杀】/【桃】/【闪】/【无懈可击】。\
    若你未按照以下规则选择牌，令【】中数字于本回合内+1：♦️-【火杀】/♥️-【桃】/♣️-【闪】/♠️-【无懈可击】。",
    --["@nyarz_longhun_god"] = "请使用【%src】",
    [":&nyarz_longhun_god"] = "发动“龙魂”须额外选择 %src 张牌",
    ["nyarz_longhun_god:fire_slash"] = "火杀",
    ["nyarz_longhun_god:jink"] = "闪",
    ["nyarz_longhun_god:peach"] = "桃",
    ["nyarz_longhun_god:nullification"] = "无懈可击",

    --陆逊

    ["nyarz_luxun"] = "群阴·陆逊",
    ["&nyarz_luxun"] = "陆逊",
    ["#nyarz_luxun"] = "陈筹画策",
    ["designer:nyarz_luxun"] = "Nyarz",

    ["nyarz_lianying"] = "连营",
    [":nyarz_lianying"] = "当你失去最后的手牌后，你可以令你的手牌上限+1，然后摸牌至手牌上限。当你于一回合内第二次受到伤害后，重置以此法获得的手牌上限。",
    ["nyarz_lianying:draw"] = "你可以令你的手牌上限+1，然后摸牌至手牌上限",
    [":&nyarz_lianying"] = "你的手牌上限增加 %src",
    ["nyarz_duoshi"] = "度势",
    [":nyarz_duoshi"] = "当你成为牌的目标后，你可以：\
    ①交给一名其他角色至多两张手牌。\
    ②将至多两张手牌置于武将牌上，当前回合结束后你可以使用任意张以此法放置的牌，剩余的牌置入弃牌堆。",
    ["@nyarz_duoshi-put"] = "你可以发动“度势”，请选择至多两张手牌",
    ["@nyarz_duoshi-use"] = "你可以发动“度势”使用任意张因此技能放置的牌",
    ["nyarz_duoshi_use"] = "度势",
    [":nyarz_duoshi_use"] = "每个回合结束后，你可以使用任意张“度势”放置的牌并将剩余牌置入弃牌堆。",

    ["$nyarz_lianying1"] = "吾破敌之策，连环相扣，蜀军安能破之？",
    ["$nyarz_lianying2"] = "敌军兵众虽锐，然以疑兵之计怠其心，亦可破之。",
    ["$nyarz_duoshi1"] = "细心筹谋，以虑后计。",
    ["$nyarz_duoshi2"] = "国之大计，当由吾辈共议之。",
    ["~nyarz_luxun"] = "今陛下离散二宫，伤害骨肉，终有追悔莫及之时。",

    --韩馥

    ["nyarz_hanfu"] = "群阴·韩馥",
    ["&nyarz_hanfu"] = "韩馥",
    ["#nyarz_hanfu"] = "怀玺其虞",
    ["designer:nyarz_hanfu"] = "Nyarz",

    ["nyarz_jieying"] = "节应",
    [":nyarz_jieying"] = "每轮限一次，一名角色于其出牌阶段内首次造成伤害后，你可以对其造成1点伤害，然后令其结束此阶段。",
    ["nyarz_jieying:end"] = "你可以对 %src 造成1点伤害，然后令其结束出牌阶段",
    ["nyarz_weipo"] = "危迫",
    [":nyarz_weipo"] = "你每回合首次成为牌的目标后，或当你受到伤害后，你可以将手牌摸至体力上限或重铸任意张牌。",
    ["@nyarz_weipo"] = "你可以重铸任意张牌或点击取消以将手牌摸至体力上限",

    ["$nyarz_jieying1"] = "食君禄当秉臣节，今自举州以应伐董之义。",
    ["$nyarz_jieying2"] = "诸君只须奋力冲杀，馥当为卿等应而援之。",
    ["$nyarz_weipo1"] = "千里冀州已入君手，为何不留我三尺容身？",
    ["$nyarz_weipo2"] = "先取我州郡，再夺我官爵，今欲害我性命乎？",
    ["~nyarz_hanfu"] = "今日若夺我冀州，他日复有人夺汝冀州。",

    --张芝
    
    ["nyarz_zhangzhi"] = "群阴·张芝",
    ["&nyarz_zhangzhi"] = "张芝",
    ["#nyarz_zhangzhi"] = "墨书清流",
    ["designer:nyarz_zhangzhi"] = "Nyarz",

    ["nyarz_bixin"] = "笔心",
    ["nyarz_bixin_prompt"] = "请选择要转化的类型，灰色部分为本轮已转化过的类型",
    [":nyarz_bixin"] = "你可以将手牌中一种类型的全部牌当作任意基本牌使用或打出。若如此做，你先摸X张牌（X为本轮未以此法转换过类型数）。",
    ["nyarz_bixin_slash"] = "笔心",
    ["nyarz_bixin_saveself"] = "笔心",
    ["nyarz_ximo"] = "洗墨",
    [":nyarz_ximo"] = "出牌阶段，你可以重铸一名角色的一张牌。若不为黑色，你将此牌交给任意一名角色，然后此技能于本阶段内失效。",
    ["@nyarz_ximo"] = "请将此【%src】交给一名角色",
    ["nyarz_feibai"] = "飞白",
    [":nyarz_feibai"] = "锁定技，你使用无色牌造成的伤害和回复+1。",
    ["$nyarz_feibai_recover"] = "%from 对 %to 的回复量因 %arg 由 %arg2 点增加到了 %arg3 点",

    ["$nyarz_bixin1"] = "论年鬓已斑，落笔心犹壮！",
    ["$nyarz_bixin2"] = "雄文念当序，举笔心先扬。",
    ["$nyarz_ximo1"] = "池水尽墨,布帛余残。",
    ["$nyarz_ximo2"] = "笔耕不辍，以待功成。",
    ["$nyarz_ximo3"] = "苦练数十寒暑，皆为此时风采。",
    ["$nyarz_feibai1"] = "习前人之法，因而变之，以成今草。",
    ["$nyarz_feibai2"] = "若清涧长源，流而无限。",
    ["~nyarz_zhangzhi"] = "墨有干涸之时，人有寿尽之日。",

    --关羽

    ["nyarz_guanyu"] = "群阴·关羽",
    ["&nyarz_guanyu"] = "关羽",
    ["#nyarz_guanyu"] = "义薄云天",
    ["designer:nyarz_guanyu"] = "Nyarz",

    ["nyarz_wusheng"] = "武圣",
    [":nyarz_wusheng"] = "准备阶段，你获得一张【杀】，使用此【杀】不计入次数限制。若你的手牌中没有以此法获得的【杀】：①你可以将一张牌当作【杀】使用或打出；②你对一名其他角色造成伤害后，令其将体力值调整为1点。",
    ["nyarz_yijve"] = "义绝",
    [":nyarz_yijve"] = "每名角色限一次，一名其他角色因你进入濒死状态时，你可以令其回复至1点体力。此后，该角色因你进入濒死状态时，你可以令其进行一次判定，若不为【桃】或【桃园结义】，该角色死亡。",
    ["nyarz_yijve:recover"] = "你可以令 %src 回复至1点体力",
    ["nyarz_yijve:death"] = "你可以令 %src 进行一次判定",

    ["$nyarz_wusheng1"] = "尔辈奸邪祸国，岂知人神共忿！",
    ["$nyarz_wusheng2"] = "刀斩逆臣贼子，身越地棘天荆！",
    ["$nyarz_wusheng3"] = "佐汉杀贼沥肝胆，赤心换得日月明！",
    ["$nyarz_wusheng4"] = "逆流由吾灭尽，孰谓苍天无眼！",
    ["$nyarz_wusheng5"] = "尽诛恶孽之贼，以还天地之清！",
    ["$nyarz_yijve1"] = "今释君权报厚遇，此一别复无旧恩！",
    ["$nyarz_yijve2"] = "放公归去已全义，再擒尽忠不容情！",
    ["$nyarz_yijve3"] = "今以旧情相释，吾等一并两清！",
    ["~nyarz_guanyu"] = "大丈夫宁奋节显义，无屈降苟生！",

    --赵云

    ["nyarz_zhaoyun"] = "群阴·赵云",
    ["&nyarz_zhaoyun"] = "赵云",
    ["#nyarz_zhaoyun"] = "金甲破阵",
    ["designer:nyarz_zhaoyun"] = "Nyarz",

    ["nyarz_duwang"] = "独往",
    [":nyarz_duwang"] = "锁定技，你使用基本牌/非基本牌时，若你使用的下一张牌为非基本牌/基本牌，你使用下一张牌时摸一张牌/无次数和距离限制。",
    ["nyarz_duwang_nobasic"] = "独往:非基本牌",
    ["nyarz_duwang_basic"] = "独往:基本牌",
    ["nyarz_longdan"] = "龙胆",
    [":nyarz_longdan"] = "限定技，你可以重铸至多两张牌，视为使用或打出一张【杀】或【闪】。你不以此法使用或打出基本牌时，重置此技能并摸一张牌。",

    ["$nyarz_duwang1"] = "斜阳落黄沙，龙腾万里，染就马上黄金甲。",
    ["$nyarz_duwang2"] = "一骑突进驱千里，钢锋破竹靡万军。",
    ["$nyarz_longdan1"] = "将军纵马冲敌阵，斩却王旗耀威风。",
    ["$nyarz_longdan2"] = "清霜冷铁衣，沙场袍泽共分炙，马踏联营。",
    ["~nyarz_zhaoyun"] = "雪漫黄金甲，大浪淘英雄。",

    --吕范

    ["nyarz_lvfan"] = "群阴·吕范",
    ["&nyarz_lvfan"] = "吕范",
    ["#nyarz_lvfan"] = "金石之策",
    ["designer:nyarz_lvfan"] = "Nyarz",

    ["nyarz_diaodu"] = "调度",
    [":nyarz_diaodu"] = "①一名角色使用装备牌时，你可以与其各摸一张牌。\
    ②准备阶段或结束阶段，你可以获得一名角色区域内的一张牌，然后将此牌交给另一名角色。若为装备牌，该角色可以使用之。",
    ["nyarz_diaodu:draw"] = "你可以发动“调度”与 %src 各摸一张牌",
    ["nyarz_diaodu_get"] = "调度",
    ["nyarz_diaodu_give"] = "调度",
    ["@nyarz_diaodu-get"] = "你可以发动“调度”获得一名角色区域内的一张牌",
    ["@nyarz_diaodu-give"] = "请将【%src】交给 %arg 以外的一名角色",
    ["@nyarz_diaodu-use"] = "你可以使用【%src】",
    ["nyarz_diancai"] = "典财",
    [":nyarz_diancai"] = "每名角色的阶段结束时，若你此阶段失去过牌，你可以将手牌摸至体力上限。若此时在你的回合外，你可以发动一次“调度②”。",
    ["nyarz_diancai:draw"] = "你可以发动“典财”将手牌摸至体力上限",

    ["$nyarz_diaodu1"] = "刃利甲坚，乃胜战之因！",
    ["$nyarz_diaodu2"] = "舟车不可不齐整，军器不可不精良！",
    ["$nyarz_diancai1"] = "虽为少主，亦当因规用财！",
    ["$nyarz_diancai2"] = "资财虽为身外物，然不可乱用奢费！",
    ["~nyarz_lvfan"] = "望主公，久踞江东。",

    --夏侯楙

    ["nyarz_xiahoumao"] = "群阴·夏侯楙",
    ["&nyarz_xiahoumao"] = "夏侯楙",
    ["#nyarz_xiahoumao"] = "束甲之鸟",
    ["designer:nyarz_xiahoumao"] = "Nyarz",

    ["nyarz_cuguo"] = "蹙国",
    [":nyarz_cuguo"] = "锁定技，当你每回合第一次使用牌被抵消后，你令此牌对目标角色再结算一次，然后若仍被抵消，你弃置一张牌。",
    ["$nyarz_cuguo_effect"] = "%card 将对 %to 再结算一次",
    ["nyarz_tongwei"] = "统围",
    [":nyarz_tongwei"] = "出牌阶段限一次，你可以选择一名其他角色并重铸任意张牌。当其下一次使用牌结算后，若此牌点数不大于你重铸牌中点数最大的且不小于点数最小的，你视为对其使用一张【杀】或普通锦囊牌。",
    ["@nyarz_tongwei-collateral"] = "请为此【借刀杀人】选择出杀目标",
    ["nyarz_tongwei_slash"] = "统围",
    ["nyarz_tongwei_trick"] = "统围",
    ["nyarz_tongwei:Slash"] = "【杀】",
    ["nyarz_tongwei:Trick"] = "普通锦囊牌",

    ["$nyarz_cuguo1"] = "身担父命，怎可蜷于宫阙。",
    ["$nyarz_cuguo2"] = "体承国运，岂能缩居朝堂。",
    ["$nyarz_tongwei1"] = "集关西诸路大军，必雪当年长坂坡之耻。",
    ["$nyarz_tongwei2"] = "手织天网十万尺，欲擒飞龙落彀中。",
    ["~nyarz_xiahoumao"] = "一将无能，徒累死三军。",

    --杜预

    ["nyarz_duyu"] = "群阴·杜预",
    ["&nyarz_duyu"] = "杜预",
    ["#nyarz_duyu"] = "威兵袭吴",
    ["designer:nyarz_duyu"] = "杜预",

    ["nyarz_zhaotao"] = "诏讨",
    [":nyarz_zhaotao"] = "你使用牌指定目标后，若你的手牌数：小于X，你可以摸两张牌并重置X；等于X，你可以对其中一名目标造成1点伤害。（X为你本回合使用的牌数）",
    ["@nyarz_zhaotao"] = "你可以对其中一名目标造成1点伤害",
    ["nyarz_zhaotao:draw"] = "你可以发动“诏讨”摸两张牌",
    ["nyarz_sanchen"] = "三陈",
    [":nyarz_sanchen"] = "你使用的牌结算后，若你的“三陈”牌少于三张且没有与此牌相同牌名的牌，你可以将此牌置于你的武将牌上并摸一张牌。每名角色的结束阶段，若你拥有至少三张“三陈”牌，你可以将这些牌交给一名角色。若不为你，你摸一张牌。",
    ["@nyarz_sanchen"] = "你可以将“三陈”牌交给一名角色",
    ["nyarz_sanchen:put"] = "你可以发动“三陈”将【%src】置于你的武将牌上",

    ["$nyarz_zhaotao1"] = "闻江南繁花绵千里，今可采之献于阙前。",
    ["$nyarz_zhaotao2"] = "诸将砺兵日久，今诏来，六合终归一统！",
    ["$nyarz_zhaotao3"] = "吞吴之志铸昆吾，剑出可破金石，平江海。",
    ["$nyarz_zhaotao4"] = "奋精锐之师，乘争流之艟，渡弱水之江。",
    ["$nyarz_sanchen1"] = "虎贲秣马，吴鹿待射，邀君览天下一统。",
    ["$nyarz_sanchen2"] = "北卒为毫，南江为墨，丹青绘江南形胜。",
    ["~nyarz_duyu"] = "吾恨长江，犹魏武之于赤壁，昭烈之于夷陵。",

    --袁术

    ["nyarz_yuanshu"] = "群阴·袁术",
    ["&nyarz_yuanshu"] = "袁术",
    ["#nyarz_yuanshu"] = "挥毫九州",
    ["designer:nyarz_yuanshu"] = "Nyarz",

    ["nyarz_canxi"] = "残玺",
    [":nyarz_canxi"] = "锁定技，其他角色每回合对你使用的首张【杀】或锦囊牌无效。你可将一张非基本牌当作【无懈可击】使用，然后本轮“残玺”对该势力角色失效。",
    ["$nyarz_canxi_invalid"] = "%from 对 %to 使用的 %card 因 %arg 的效果对其无效",
    ["nyarz_pizhi"] = "圮秩",
    [":nyarz_pizhi"] = "锁定技，其他角色的出牌阶段内，你使用牌名字数不小于体力值的牌结算后，结束当前出牌阶段。当前回合角色于其弃牌阶段弃置牌后，你获得之。",
    ["nyarz_zhonggu"] = "冢骨",
    [":nyarz_zhonggu"] = "锁定技，①一个势力的最后一名其他角色死亡后，你摸三张不同牌名的非装备牌并展示，令所有其他角色不能使用或打出同名牌直到你下次发动此技能。\
    ②一名角色没有使用过牌的出牌阶段结束时，其失去一点体力。你的结束阶段，摸此效果生效角色数张牌。",
    [":&nyarz_zhonggu_draw"] = "结束阶段，你摸 %src 张牌",
    ["nyarz_zhonggu_draw"] = "冢骨",

    ["$nyarz_canxi1"] = "生不能尊以九五，死何瞑目于九泉。",
    ["$nyarz_canxi2"] = "高祖斩蛇成汉祚，英雄碎玺造山河。",
    ["$nyarz_pizhi1"] = "欲复此间山河者，当出三公之家、当奋四世余烈。",
    ["$nyarz_pizhi2"] = "天命在野，汉既失其鹿，天下人当共逐之。",
    ["$nyarz_zhonggu1"] = "岁月将老，既得此世之荣光，何顾后世之风雨。",
    ["$nyarz_zhonggu2"] = "春秋蹉跎，多少王侯将相，皆成黄土一抔。",
    ["~nyarz_yuanshu"] = "英雄不死则已，死则举大名尔！",

    --张让

    ["nyarz_zhangrang"] = "群阴·张让",
    ["&nyarz_zhangrang"] = "张让",
    ["#nyarz_zhangrang"] = "窃政聚敛",
    ["designer:nyarz_zhangrang"] = "Nyarz",

    ["nyarz_luanzheng"] = "乱政",
    [":nyarz_luanzheng"] = "当你需要使用本轮未以此法使用过的基本牌或普通锦囊牌时，你可以视为使用之。你可以先将一张牌置于牌堆顶，否则此牌结算后，你令一名其他角色选择交给你一张牌或令你此技能失效直到回合结束。",
    ["@nyarz_luanzheng-put"] = "请将一张牌置于牌堆顶<br/>或取消并于此牌结算后令其他角色选择是否交给你牌",
    ["@nyarz_luanzheng-give"] = "请交给 %src 一张牌<br/>或取消并令 %src “乱政”失效直到当前回合结束",
    ["@nyarz_luanzheng"] = "请选择交给你牌的角色",
    ["nyarz_luanzheng_saveself"] = "乱政",
    ["nyarz_luanzheng_Slash"] = "乱政",
    ["$nyarz_luanzheng_put"] = "%from 发动 %arg 将 %card 置于牌堆顶",
    ["nyarz_quanqing"] = "权倾",
    [":nyarz_quanqing"] = "锁定技，当你获得其他角色的牌后，你本回合使用的下一张牌仅能被你和该角色响应。你不因使用而失去牌后，可令任意名其他角色摸一张牌，这些角色本回合使用下一张牌时，若为非装备牌则无效并令你从牌堆底摸一张牌。",
    ["@nyarz_quanqing"] = "你可令任意名其他角色摸一张牌",
    ["$nyarz_quanqing_invalid"] = "%to 使用的 %card 被 %from 的 “%arg” 无效",
    ["$nyarz_quanqing_response"] = "%from 使用的 %card 因 %arg 不能被 %to 响应",
    ["nyarz_quanqing_can"] = "权倾可响应",
    ["nyarz_quanqing_bad"] = "权倾无效",

    ["$nyarz_luanzheng1"] = "此鹿为马，戏殿上朱紫成沐冠之猢。",
    ["$nyarz_luanzheng2"] = "以利障目，乱满朝文武做蛇鼠一窝。",
    ["$nyarz_quanqing1"] = "交通货赂，威形喧赫。",
    ["$nyarz_quanqing2"] = "蒙帝宠幸，无所惮畏。",
    ["~nyarz_zhangrang"] = "故中常侍所为，于吾何干？",

    --许靖

    ["nyarz_xujing"] = "群阴·许靖",
    ["&nyarz_xujing"] = "许靖",
    ["#nyarz_xujing"] = "丹枫盈曈",
    ["designer:nyarz_xujing"] = "Nyarz",

    ["nyarz_caixia"] = "才瑕",
    [":nyarz_caixia"] = "你使用牌时，可令此牌无效，此牌及你使用的下一张牌不计入次数，然后你摸体力值张牌。你不能再发动此技能直到你使用或打出了等量张牌。",
    ["nyarz_caixia:draw"] = "你可以发动“才瑕”令【%src】无效并摸 %arg 张牌",
    [":&nyarz_caixia"] = "还需使用或打出 %src 张牌",
    ["$nyarz_caixia_invalid"] = "%to 使用的 %card 被 %from 的 “%arg” 无效",
    ["nyarz_shangyu"] = "赏誉",
    [":nyarz_shangyu"] = "一名角色不以此法获得牌后，若：①仅有一张，你可以令其将此牌交给你选择的另一名角色；②至少两张，你可以令其摸一张牌。",
    ["nyarz_shangyu:draw"] = "你可以令 %src 摸一张牌",
    ["@nyarz_shangyu"] = "你可以令 %src 将获得的牌交给另一名角色",

    ["$nyarz_caixia1"] = "四时钟灵，金秋独贵，品丹桂而闻雨露秋风。",
    ["$nyarz_caixia2"] = "晚木潇潇，雁归衡阳，一叶落而天下知秋。",
    ["$nyarz_shangyu1"] = "君子撷翠屏，盈锦绣大道，颂万世太平。",
    ["$nyarz_shangyu2"] = "野陌有丹桂，沐金秋银露，梦白鹿青崖。",
    ["~nyarz_xujing"] = "蜀中离客撷银杏，寄君中原一枝秋。",

    --典韦

    ["nyarz_dianwei"] = "群阴·典韦",
    ["&nyarz_dianwei"] = "典韦",
    ["#nyarz_dianwei"] = "蹈锋睥世",
    ["designer:nyarz_dianwei"] = "Nyarz",

    ["nyarz_qiangxi"] = "强袭",
    [":nyarz_qiangxi"] = "出牌阶段，你可以对一名此阶段未受到过伤害的角色造成1点伤害，然后其对你造成1点伤害。",
    ["nyarz_ninge"] = "狞恶",
    [":nyarz_ninge"] = "锁定技，你造成或受到伤害后，令受伤角色的一个技能失效直到当前回合结束，然后你摸两张牌并重铸任意张牌。",
    ["@nyarz_ninge"] = "你可以重铸任意张牌",
    ["$nyarz_ninge_invalid"] = "%from 的 %arg 被无效",

    ["$nyarz_qiangxi1"] = "手持青罡戟，斥啸锟铻兵，竖子安敢放肆。",
    ["$nyarz_qiangxi2"] = "横眉对宵小，俯首卫明公，且来与我一战。",
    ["$nyarz_ninge1"] = "顽敌在野，神兵明箧，跋扈由性，虎目何容人。",
    ["$nyarz_ninge2"] = "怀凶神以慑罗刹，我本桀骜，匹夫以何驯我？",
    ["~nyarz_dianwei"] = "典韦在此，速来决死！",

    --徐荣
    ["nyarz_xurong"] = "群阴·徐荣",
    ["&nyarz_xurong"] = "徐荣",
    ["#nyarz_xurong"] = "怒燎横空",
    ["designer:nyarz_xurong"] = "Nyarz",

    ["nyarz_xionghuo"] = "凶镬",
    [":nyarz_xionghuo"] = "锁定技，你于出牌阶段内对其他角色造成的伤害+1。你对其他角色仅造成1点伤害后，令其失去所有体力。",
    ["nyarz_shajve"] = "杀绝",
    [":nyarz_shajve"] = "锁定技，其他角色进入濒死时，你摸一张牌。其他角色脱离濒死后，你选择是否对其使用一张无距离限制的【杀】。你于回合内从牌堆顶摸牌时，额外摸一张伤害牌。",
    ["@nyarz_shajve"] = "你可以对 %src 使用一张【杀】",

    ["$nyarz_xionghuo1"] = "鼎汇春秋，引江河入镬，升腾万古风流。",
    ["$nyarz_xionghuo2"] = "将者临战，执霜刃摧敌，醉邀袍泽分炙。",
    ["$nyarz_shajve1"] = "围我数重亦如何？今烈刃在手，且试剑苍穹。",
    ["$nyarz_shajve2"] = "我欲雄立天下，弘武烈之士，逐四海之潮。",
    ["~nyarz_xurong"] = "为将死战，可得其所。",

    --杜夔
    ["nyarz_dukui"] = "群阴·杜夔",
    ["&nyarz_dukui"] = "杜夔",
    ["#nyarz_dukui"] = "洪吕涤音",
    ["designer:nyarz_dukui"] = "Nyarz",

    ["nyarz_fanyin"] = "泛音",
    [":nyarz_fanyin"] = "你不以此法使用的牌结算后，若此牌点数大于你本回合上次发动此技能前使用的牌，你可以检视牌堆中三张不同牌名且可以使用的牌，然后可以使用其中一张（不计次数和距离）。",
    ["@nyarz_fanyin-use"] = "你可以使用其中一张牌",
    ["#nyarz_fanyin"] = "泛音",

    --秦宜禄

    ["nyarz_qinyilu"] = "群阴·秦宜禄",
    ["&nyarz_qinyilu"] = "秦宜禄",
    ["#nyarz_qinyilu"] = "尘垢粃糠",
    ["designer:nyarz_qinyilu"] = "Nyarz",

    ["nyarz_piaopin"] = "飘萍",
    [":nyarz_piaopin"] = "锁定技，你使用或打出当前回合获得的牌时，摸一张牌。出牌阶段开始时，重铸你手牌中所有不能使用的牌。",
    ["nyarz_zhuili"] = "惴栗",
    [":nyarz_zhuili"] = "锁定技，你受到伤害后，重铸区域内的所有牌并摸两张牌。你失去装备区内的牌后回复一点体力。",

    ["$nyarz_piaopin1"] = "奔波四处，前途未明。",
    ["$nyarz_piaopin2"] = "辗转各地，功业难寻。",
    ["$nyarz_zhuili1"] = "近况艰难，何不忧愁？",
    ["$nyarz_zhuili2"] = "形势如此，惴惕难当。",
    ["~nyarz_qinyilu"] = "我竟落得如此下场！",

    --夏侯渊

    ["nyarz_xiahouyuan"] = "群阴·夏侯渊",
    ["&nyarz_xiahouyuan"] = "夏侯渊",
    ["#nyarz_xiahouyuan"] = "果敢速战",
    ["designer:nyarz_xiahouyuan"] = "Nyarz",

    ["nyarz_shensu"] = "神速",
    ["nyarz_shensu_slash"] = "神速",
    [":nyarz_shensu"] = "你可以摸一张牌并视为使用一张不计距离和次数的【杀】，同时执行并移除一项：①此【杀】不可被响应；②此【杀】造成的伤害+1；③此技能改为每回合限一次。",
    ["nyarz_shensu:noresponse"] = "此【杀】不可被响应",
    ["nyarz_shensu:damage"] = "此【杀】造成的伤害+1",
    ["nyarz_shensu:limit"] = "此技能改为每回合限一次",
    ["$nyarz_shensu_choose"] = "%from 选择了 %arg",
    ["nyarz_shensu_noresponse"] = "此【杀】不可被响应",
    ["nyarz_shensu_damage"] = "此【杀】造成的伤害+1",
    ["nyarz_shensu_limit"] = "此技能改为每回合限一次",
    ["nyarz_shebian"] = "设变",
    [":nyarz_shebian"] = "限定技，出牌阶段，你可以失去一个其他技能，然后选择一名角色，获得其武将牌上一个你未拥有的技能。你进入濒死状态后重置此技能。",
    ["@nyarz_shebian"] = "请选择一名要获得其武将牌上的技能的角色",

    ["$nyarz_shensu1"] = "已积跬步十万，今必一马当先。",
    ["$nyarz_shensu2"] = "各方群英逐风，我必独占鳌头。",
    ["$nyarz_shebian1"] = "虎贲束甲，与子同袍。",
    ["$nyarz_shebian2"] = "用兵以决，谋变制胜。",
    ["~nyarz_xiahouyuan"] = "居然有人比我快……",

    --钟会·第二版

    ["nyarz_zhonghui"] = "群阴·钟会·第二版",
    ["&nyarz_zhonghui"] = "钟会",
    ["#nyarz_zhonghui"] = "钟桂香蒲",
    ["designer:nyarz_zhonghui"] = "Nyarz",

    ["nyarz_quanji"] = "权计",
    [":nyarz_quanji"] = "在你受到1点伤害或出牌阶段结束时，你可以摸两张牌，然后可以将任意张牌移出游戏。你的手牌上限+X（X为“权计”牌数量）。",
    ["@nyarz_quanji-remove"] = "你可以将任意张牌移出游戏",
    ["nyarz_quanji_end"] = "权计",
    ["nyarz_quanji_damaged"] = "权计",
    ["nyarz_zili"] = "自立",
    [":nyarz_zili"] = "觉醒技，每个回合结束时，若你“权计”牌数量不小于你的体力上限，减一点体力上限并获得“排异”，将体力值回复至上限并于当前回合结束后执行一个额外回合。",
    ["nyarz_paiyi"] = "排异",
    [":nyarz_paiyi"] = "出牌阶段各限一次，你可以移去至少半数的“权计”牌，然后：①对至多等量名角色各造成1点伤害；②摸移去数量+2张牌。",
    ["nyarz_paiyi:draw"] = "摸移去数量+2张牌",
    ["nyarz_paiyi:damage"] = "对至多等量名角色各造成1点伤害",
    ["nyarz_paiyi_damage"] = "排异",
    ["nyarz_paiyi_draw"] = "排异",

    ["$nyarz_quanji1"] = "月缺潜水中，月满照星河。",
    ["$nyarz_quanji2"] = "祸福轮转，暂且退让。",
    ["$nyarz_zili1"] = "独立身，划分界。",
    ["$nyarz_zili2"] = "自立为主，闯荡一番。",
    ["$nyarz_paiyi1"] = "哼，你才不是我的伙伴。",
    ["$nyarz_paiyi2"] = "云泥之别，高下立判。",
    ["~nyarz_zhonghui"] = "不能再与父亲，一起练字了。",
}
return packages