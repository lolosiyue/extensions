extension = sgs.Package("NyarzFirst", sgs.Package_GeneralPack)

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

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

Dcaocao = sgs.General(extension, "Dcaocao", "wei", 4, true, false, false)

Djianxiong = sgs.CreateTriggerSkill{
    name = "Djianxiong",
    events = {sgs.Damaged, sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    priority = 0,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            local damage = data:toDamage()
            local card = damage.card
            if (not card) or card:isKindOf("SkillCard") then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local names, name = player:property("SkillDescriptionRecord_Djianxiong"):toString():split("+"), card:objectName()
            if card:isKindOf("Slash") then name = "DjianxiongSlash" end
            if not table.contains(names, name) then 
                table.insert(names, name)
            
                local log = sgs.LogMessage()
                log.type = "$Arecord"
                log.arg2 = damage.card:objectName()
                log.arg = player:getGeneralName()
                room:sendLog(log)

		        room:setPlayerProperty(player, "SkillDescriptionRecord_Djianxiong", sgs.QVariant(table.concat(names, "+")))
                player:setSkillDescriptionSwap("Djianxiong", "%arg11", table.concat(names, "+"))
                room:changeTranslation(player, "Djianxiong", 11)
            else
                local choices = {"draw"}
                if player:isWounded() then
                    table.insert(choices, "recover")
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if choice == "draw" then
                    player:drawCards(2)
                elseif choice == "recover" then
                    local recover = sgs.RecoverStruct(player, nil, 1)
                    room:recover(player, recover)
                end
            end    
        end

        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.damage == 1 then return false end
            local card = damage.card
            if (not card) or card:isKindOf("SkillCard") then return false end
            local names, name = player:property("SkillDescriptionRecord_Djianxiong"):toString():split("+"), card:objectName()
            if card:isKindOf("Slash") then name = "DjianxiongSlash" end
            if table.contains(names, name) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local log = sgs.LogMessage()
                log.type = "%djianxiongchangedamage"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = 1
                log.card_str = card:toString()
                room:sendLog(log)

                damage.damage = 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Dzhishi = sgs.CreateTriggerSkill{
    name = "Dzhishi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play  or player:getPhase() == sgs.Player_Finish then
            local names = player:property("SkillDescriptionRecord_Djianxiong"):toString():split("+")
            local num = 0
            for _,p in ipairs(names) do
                num = num + 1
            end
            if num == 0 and player:isWounded() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
            elseif num > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local choice = room:askForChoice(player, self:objectName(), table.concat(names, "+"))
                table.removeOne(names, choice)
                local log = sgs.LogMessage()
                log.type = "$Aremove"
                log.arg2 = choice
                log.arg = player:getGeneralName()
                room:sendLog(log)

                player:drawCards(2)
                room:setPlayerProperty(player, "SkillDescriptionRecord_Djianxiong", sgs.QVariant(table.concat(names, "+")))
                if num == 1 then
                    room:changeTranslation(player, "Djianxiong", 1)
                else 
                    player:setSkillDescriptionSwap("Djianxiong", "%arg11", table.concat(names, "+"))
                    room:changeTranslation(player, "Djianxiong", 11)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Dcaocao:addSkill(Djianxiong)
Dcaocao:addSkill(Dzhishi)

Ghuangzhong = sgs.General(extension, "Ghuangzhong", "god", 4, true, false, false)

Gliegong = sgs.CreateTriggerSkill{
    name = "Gliegong",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "liegongselect", true, true)
        if not target then return false end
        room:broadcastSkillInvoke("liegong")

        local num = target:getMark("liegong"..player:objectName()) + 2
        room:setPlayerMark(target, "liegong"..player:objectName(), target:getMark("liegong"..player:objectName())+1)
        room:addPlayerMark(target, "&Gliegong+to+#"..player:objectName() )

        local decision = math.random(1,100)
        if decision < 2^num + 1 then
            local log = sgs.LogMessage()
            log.type = "$liegongkill"
            log.arg = player:getGeneralName()
            log.arg2 = target:getGeneralName()
            room:sendLog(log)

            local damage = sgs.DamageStruct(nil, player, target, 0, sgs.DamageStruct_Normal)
            room:killPlayer(target,damage)
        else
            local log = sgs.LogMessage()
            log.type = "$liegongfalse"
            log.arg = target:getGeneralName()
            room:sendLog(log)

            player:drawCards(target:getMark("liegong"..player:objectName()))
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Gposhi = sgs.CreateTriggerSkill{
    name = "Gposhi",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not use.card:isKindOf("Slash") then return false end
        if not use.from:hasSkill(self:objectName()) then return false end
        for _,p in sgs.qlist(use.to) do
            local _data = sgs.QVariant()
            _data:setValue(p)
            player:setTag("Gposhi", _data)--ai
            if room:askForSkillInvoke(use.from, self:objectName(), _data) then
                room:broadcastSkillInvoke("liegong")
                room:addPlayerMark(use.from, "&Gposhi+-Clear")
                local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                local can = false
                if p:getHandcardNum() > 0 then
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:objectName() == "jink" then
                            jink:addSubcard(card)
                            can = true
                        end
                    end
                end
                if can then 
                    room:throwCard(jink, p, use.from) 
                else
                    room:setPlayerMark(p, "poshidamage-Clear", 1)
                end
                jink:deleteLater()
                room:setPlayerMark(use.from, "Gposhi-Clear", 1)
                break
            end 
        end         
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and (target:getMark("Gposhi-Clear") == 0)
    end,
}

poshibuff = sgs.CreateTriggerSkill{
    name = "#poshibuff",
    events = {sgs.CardFinished,sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") then return false end
            if not use.from:hasSkill("Gposhi") then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do 
                room:setPlayerMark(p, "poshidamage-Clear", 0)
            end
        end
        if event == sgs.DamageCaused then
            local da = data:toDamage()
            if da.from:hasSkill("Gposhi") and (da.to:getMark("poshidamage-Clear") > 0) and da.card:isKindOf("Slash") then
                room:setPlayerMark(da.to, "poshidamage-Clear", 0)

                local log = sgs.LogMessage()
                log.type = "$poshida"
                log.arg = da.from:getGeneralName()
                log.arg2 = da.to:getGeneralName()
                log.arg3 = string.format("%d",da.damage)
                log.arg4 = string.format("%d",da.damage + 1)
                room:sendLog(log)

                da.damage = da.damage + 1
                data:setValue(da)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Ghuangzhong:addSkill(Gliegong)
Ghuangzhong:addSkill(Gposhi)
Ghuangzhong:addSkill(poshibuff)
extension:insertRelatedSkills("Gposhi", "#poshibuff")

Dliuyan = sgs.General(extension, "Dliuyan", "qun", 3, true, false, false)

Dtushe = sgs.CreateTriggerSkill{
    name = "Dtushe",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() then return false end
        local n = use.to:length()
        local prompt = string.format("draw:%s:",n)
        room:setPlayerMark(player, "dtushe", n)
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
        room:broadcastSkillInvoke(self:objectName())
        if player:getHandcardNum() > 0 then
            for _,p in sgs.qlist(player:getHandcards()) do
                if p:isKindOf("BasicCard") then
                    room:setPlayerMark(player, "tushe-Clear", 1)
                    room:setPlayerMark(player, "&tushe+-Clear", 1)
                    break
                end
            end
        end
        player:drawCards(n)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and (target:getMark("tushe-Clear") == 0)
    end,
}

Dlimu = sgs.CreateViewAsSkill
{
    name = "Dlimu",
    n = 1,
    view_filter = function(self, selected, to_select)
        local player = sgs.Self
        if player:containsTrick("indulgence") and to_select:isRed() then return false end
        if player:containsTrick("supply_shortage") and to_select:isBlack() then return false end
        return #selected < 1
    end,
	view_as = function(self, cards)
        if #cards ~= 1 then return nil end
        local cc = dlimuCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
	end,
    enabled_at_play = function(self, player)
		return (not player:containsTrick("indulgence")) or (not player:containsTrick("supply_shortage"))
	end ,
}

dlimuCard = sgs.CreateSkillCard
{
    name = "Dlimu",
    will_throw = false,
    filter = function(self, targets, to_select)
        return to_select:objectName() == sgs.Self:objectName()
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local pattern = nil
        local card_ids = self:getSubcards()
        for _,id in sgs.qlist(card_ids) do
            local cc = sgs.Sanguosha:getCard(id)
            if cc:isRed() then 
                pattern = "indulgence"
                break
            elseif cc:isBlack() then
                pattern = "supply_shortage"
                break
            end
        end

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        for _,id in sgs.qlist(card_ids) do
            local cc = sgs.Sanguosha:getCard(id)
            card:addSubcard(cc)
        end
        card:setSkillName(self:objectName())
        return card
    end,
}

Dlimubuff = sgs.CreateTargetModSkill{
    name = "#Dlimubuff",
    pattern = "BasicCard,TrickCard",
    residue_func = function(self, from, card)
        if from:hasSkill("Dlimu") then
			if from:getJudgingArea():length() > 0 then
                return 1000
            end
		end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill("Dlimu") then
			if from:getJudgingArea():length() > 0 then
                return 1000
            end
		end
    end,
    extra_target_func = function(self, from, card)
        return 0
    end,
}

Dlimuelse = sgs.CreateTriggerSkill{
    name = "#Dlimuelse",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end
        if use.card:objectName() == "indulgence" and player:isWounded() then
            if not room:askForSkillInvoke(player, "Dlimu", sgs.QVariant("rec")) then return false end
            room:broadcastSkillInvoke("Dlimu")
            local rec = sgs.RecoverStruct(player, nil, 1)
            room:recover(player, rec)
        elseif use.card:objectName() == "supply_shortage" then 
            if not room:askForSkillInvoke(player, "Dlimu", sgs.QVariant("draw")) then return false end
            room:broadcastSkillInvoke("Dlimu")
            player:drawCards(2)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("Dlimu")
    end,
}

Dliuyan:addSkill(Dtushe)
Dliuyan:addSkill(Dlimu)
Dliuyan:addSkill(Dlimubuff)
Dliuyan:addSkill(Dlimuelse)
extension:insertRelatedSkills("Dlimu","#Dlimubuff")
extension:insertRelatedSkills("Dlimu","#Dlimuelse")


--花色标记示例

jn = sgs.CreateTriggerSkill{
    name = "jn",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local names = player:getMarkNames()
        local mark = nil
        for _,p in ipairs(names) do
            if (string.find(p,"&jn")) and (player:getMark(p) > 0) then
                mark = p
                break
            end
        end
        local use = data:toCardUse()
        local suit = use.card:getSuitString()
        if mark and player:getMark(mark) > 0 then 
            if string.find(mark,suit.."_char") then return false end
            room:setPlayerMark(player, mark, 0)
            mark = string.sub(mark,1,-7)
        else
            mark = "&jn"
        end
        mark = mark.."+"..suit.."_char-Clear"
        room:addPlayerMark(player, mark)
        player:drawCards(1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Dwangji = sgs.General(extension, "Dwangji", "wei", 3, true, false, false)

Dqizhi = sgs.CreateTriggerSkill{
    name = "Dqizhi",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or (card:isKindOf("SkillCard")) then return false end

        if (player:getMark("&Dqizhi-Clear") > 0 ) and (player:getPhase() == sgs.Player_NotActive) then return false end
        local targets = sgs.SPlayerList()
        local cant = true
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if (not p:isAllNude()) then
                targets:append(p)
                cant = false
            end
        end
        if cant then return false end
        --if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "Dqizhiask", true, true)
        if not target then return false end
        room:broadcastSkillInvoke("qizhi")
        room:setPlayerMark(player, "&Dqizhi-Clear", player:getMark("&Dqizhi-Clear")+1)
        local card = room:askForCardChosen(player, target, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
        room:throwCard(card, target, player)
        target:drawCards(1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Djinqu = sgs.CreateTriggerSkill{
    name = "Djinqu",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Finish then return false end
        if player:getMark("&Dqizhi-Clear") == 0 then return false end
        local marks = math.min(player:getMark("&Dqizhi-Clear"),5)
        local prompt = string.format("draw:%s:",marks)
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
        room:broadcastSkillInvoke("jinqu")
        player:drawCards(marks)
        local num = player:getHandcardNum() - marks
        if num == 0 then return false end
        room:askForDiscard(player, self:objectName(), num, num, false, false)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Dwangji:addSkill(Dqizhi)
Dwangji:addSkill(Djinqu)

Godganning = sgs.General(extension, "Godganning", "god", 6, false, false, false, 3)

Godjieying = sgs.CreateTriggerSkill{
    name = "Godjieying",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start then
            if player:getMark("&Godying") < 3 then 
                player:gainMark("&Godying",  1) 
                room:broadcastSkillInvoke("Godjieying")
            end
            
        end
        
        if player:getPhase() ~= sgs.Player_Finish then return false end
        if player:getMark("&Godying") == 0 then return false end
        local cant = true
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getMark("&Godying") == 0 then
                cant = false
                targets:append(p)
            end
        end
        if cant then return false end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@Godjieying1", true, true)
        if not target then return false end
        room:broadcastSkillInvoke("Godjieying")
        player:loseMark("&Godying", 1)
        target:gainMark("&Godying", 1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Godjieyingget = sgs.CreateTriggerSkill{
    name = "#Godjieyingget",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("&Godying") == 0 then return false end
        if player:getPhase() ~= sgs.Player_Finish then return false end
        for _, master in sgs.qlist(room:findPlayersBySkillName("Godjieying")) do
            if master:objectName() == player:objectName() then continue end
            local _data = sgs.QVariant()
            _data:setValue(player)
            master:setTag("jieyingtarget",_data) -- ai
            if not room:askForSkillInvoke(master, "Godjieying", _data) then
                master:removeTag("jieyingtarget")
                return false 
            end
            master:removeTag("jieyingtarget")
            player:loseMark("&Godying", 1)
            room:broadcastSkillInvoke("Godjieying")

            local all = sgs.Sanguosha:cloneCard("jink")
            for _,p in sgs.qlist(player:getHandcards()) do
                all:addSubcard(p)
            end
            for _,p in sgs.qlist(player:getEquips()) do
                all:addSubcard(p)
            end

            room:obtainCard(master, all, false)
            all:deleteLater()
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

Godjieyingslash = sgs.CreateTargetModSkill{
    name = "#Godjieyingslash",
    global = true,
    residue_func = function(self, from, card)
        if from:getMark("&Godying") > 0 then
            return from:getMark("&Godying") 
        end
        return 0
    end,
}

Godjieyingdraw = sgs.CreateTriggerSkill{
	name = "#Godjieyingdraw",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
    global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local draw = data:toDraw()
        if draw.reason ~= "draw_phase" then return false end
		draw.num = draw.num + player:getMark("&Godying")
        for _, master in sgs.qlist(room:findPlayersBySkillName("Godjieying")) do
            room:sendCompulsoryTriggerLog(master, "Godjieying", true)
            room:broadcastSkillInvoke("Godjieying")
            data:setValue(draw)
        end
	end,
    can_trigger = function(self, target)
        return (target ~= nil) and target:getMark("&Godying") > 0
    end,
}

Godjieyingmax = sgs.CreateMaxCardsSkill{
    name = "#Godjieyingmax",
    global = true,
    extra_func = function(self, target)
        if target:getMark("&Godying") > 0 then return target:getMark("&Godying")*2 end
        return 0
    end,
}

Godpoxi = sgs.CreateViewAsSkill
{
    name = "Godpoxi",
    n = 99,
    response_pattern = "@@Godpoxi",
    expand_pile = "#Godpoxi",
    view_filter = function(self, selected, to_select)
        if not sgs.Self:hasFlag("godpoxi") then
            return false
        else
            if #selected > 0 then
                for _,card in ipairs(selected) do
			        if card:getSuit() == to_select:getSuit() then return false end
		        end
            end
            if (not sgs.Self:getHandcards():contains(to_select)) and (not sgs.Self:getPile("#Godpoxi"):contains(to_select:getId())) then return false end
        end
		return true
	end,
    view_as = function(self, cards)
        local card = GodpoxiCard:clone()
        if not sgs.Self:hasFlag("godpoxi") then
            return card
        else
            card = GodpoxidisCard:clone()
            if #cards ~= 4 then return nil end
            for _,p in ipairs(cards) do
                card:addSubcard(p)
            end
            return card
        end
	end,
    enabled_at_play = function(self, player)
		return not player:hasUsed("#Godpoxi") 
	end,
}

GodpoxiCard = sgs.CreateSkillCard
{
    name = "Godpoxi",
    filter = function(self, targets, to_select)
        if not sgs.Self:hasFlag("godpoxi") then
		    return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and (not to_select:isKongcheng())
        else 
            return to_select:objectName() == sgs.Self:objectName()
        end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
        local thands = sgs.IntList()
        if not effect.to:isKongcheng() then
            for _,card in sgs.qlist(effect.to:getHandcards()) do
                thands:append(card:getId())
            end
        end

        room:notifyMoveToPile(effect.from, thands, "Godpoxi", sgs.Player_PlaceHand, true)
        room:setPlayerFlag(effect.from, "godpoxi")

        local _data = sgs.QVariant()
        _data:setValue(effect.to)
        effect.from:setTag("godpoxi", _data)--ai

        local card = room:askForUseCard(effect.from, "@@Godpoxi", "@Godpoxi:"..effect.to:objectName())
        room:setPlayerFlag(effect.from, "-godpoxi")
        if not thands:isEmpty() then
            room:notifyMoveToPile(effect.from, thands, "Godpoxi", sgs.Player_PlaceHand, false)
        end

        if not card then return false end
        
        local throwcard = card:getSubcards()
        local from_ids, to_ids = sgs.IntList(), sgs.IntList()
        
        for _,id in sgs.qlist(throwcard) do
            if thands:contains(id) then
                from_ids:append(id)
            else
                to_ids:append(id)
            end
        end
        
        local moves = sgs.CardsMoveList()
        if (not from_ids:isEmpty()) then 
            local move1 = sgs.CardsMoveStruct(from_ids, effect.to, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.to:objectName(), nil, "godpoxi"))
            moves:append(move1)
            
        end
        
        if (not to_ids:isEmpty()) then
            local move2 = sgs.CardsMoveStruct(to_ids, effect.from, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.from:objectName(), nil, "godpoxi"))
            moves:append(move2)
        end
        
        if (not moves:isEmpty()) then
            room:moveCardsAtomic(moves, true)
        end
        
        local n = to_ids:length()

        if n == 0 then room:setPlayerFlag(effect.from,"Global_PlayPhaseTerminated") end

        if n >= 2 and effect.from:isWounded() then
            local re = sgs.RecoverStruct(effect.from, nil, 1)
            room:recover(effect.from, re)
        end

        if n >= 3 then
            local da = sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Normal)
            room:damage(da)
        end

        if n >= 4 then
            effect.from:drawCards(4)
        end
    end
}

GodpoxidisCard = sgs.CreateSkillCard
{
    name = "GodpoxidisCard",
    handling_method = sgs.Card_MethodDiscard,
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        return false
    end
}



Godganning:addSkill(Godjieying)
Godganning:addSkill(Godjieyingget)
Godganning:addSkill(Godjieyingslash)
Godganning:addSkill(Godjieyingdraw)
Godganning:addSkill(Godjieyingmax)
Godganning:addSkill(Godpoxi)
extension:insertRelatedSkills("Godjieying","#Godjieyingget")
extension:insertRelatedSkills("Godjieying","#Godjieyingslash")
extension:insertRelatedSkills("Godjieying","#Godjieyingdraw")
extension:insertRelatedSkills("Godjieying","#Godjieyingmax")

Diyliuzhan = sgs.General(extension, "Diyliuzhan", "wu", 4, true, false, false)

Diyfenyin = sgs.CreateTriggerSkill{
    name = "Diyfenyin",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            local names = player:getMarkNames()
            local mark = nil
            for _,p in ipairs(names) do
                if (string.find(p,"&Diyfenyin")) and (player:getMark(p) > 0) then
                    mark = p
                    break
                end
            end
            for _,id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                local suit = card:getSuitString()
                if ((mark ~= nil) and (not string.find(mark,suit))) or (mark == nil) then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local n = math.random(1,2)
                    room:broadcastSkillInvoke("tenyearfenyin",n)
                    player:drawCards(1)
                    if mark == nil then
                    mark = "&Diyfenyin".."+"..suit.."_char"
                    else
                        room:setPlayerMark(player, mark, 0)
                        mark = mark.."+"..suit.."_char"
                    end
                    room:setPlayerMark(player, mark, 1)
                end
            end
        end

        if event == sgs.EventPhaseStart then
            if not ((player:getPhase() == sgs.Player_Start) or (player:getPhase() == sgs.Player_Finish)) then return false end
            local names = player:getMarkNames()
            local mark = nil
            for _,p in ipairs(names) do
                if (string.find(p,"&Diyfenyin")) and (player:getMark(p) > 0) then
                    mark = p
                    break
                end
            end
            if mark then room:setPlayerMark(player, mark, 0) end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

Diylijisum = sgs.CreateTriggerSkill{
    name = "#Diylijisum",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
        if player:getPhase() == sgs.Player_NotActive then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				local n = player:getMark("&Diylijineed-Clear")
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					n = n + 1
				end
				room:setPlayerMark(player, "&Diylijineed-Clear", n)
                while (player:getMark("&Diylijineed-Clear") >= 4) do
                    room:setPlayerMark(player, "&Diylijineed-Clear", player:getMark("&Diylijineed-Clear")-4)
                    room:setPlayerMark(player, "&Diyliji-Clear", player:getMark("&Diyliji-Clear")+1)     
                end
			end
        end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
}

DiylijiCard = sgs.CreateSkillCard
{   
    name = "DiylijiCard",
    filter = function(self, targets, to_select)
        if (#targets >= 1) or (to_select:objectName() == sgs.Self:objectName()) then return false end
        return true
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:isAlive() and effect.to:isAlive() then
            room:broadcastSkillInvoke("liji")
            local da = sgs.DamageStruct("Diyliji", effect.from, effect.to, 1, sgs.DamageStruct_Normal)
            room:damage(da)
            room:setPlayerMark(effect.from, "&Diyliji-Clear", effect.from:getMark("&Diyliji-Clear")-1)
        end
    end
}

Diyliji = sgs.CreateOneCardViewAsSkill
{
    name = "Diyliji",
    view_filter = function(self, card)
    	return true
	end,
    view_as = function(self, card)
        local c = DiylijiCard:clone()
        c:addSubcard(card)
        c:setSkillName(self:objectName())
        return c
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&Diyliji-Clear") > 0
    end,
}

Diyliuzhan:addSkill(Diyfenyin)
Diyliuzhan:addSkill(Diylijisum)
Diyliuzhan:addSkill(Diyliji)

exzhangliang = sgs.General(extension, "exzhangliang", "qun", 4, true, false, false)

exjijun = sgs.CreateTriggerSkill{
    name = "exjijun",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        local ctype = getTypeString(use.card)
        if ctype == nil then return false end
        if not use.to:contains(player) then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke("jijun")

        local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.who = player
		judge.reason = self:objectName()
	    room:judge(judge)

        player:addToPile("exfang", judge.card, true)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

exfangtongVS = sgs.CreateViewAsSkill
{
    name = "exfangtong",
    expand_pile = "exfang",
    n = 99,
    response_pattern = "@@exfangtong",
    view_filter = function(self, selected, to_select)
		local can = true
        local hand = sgs.Self:getHandcards()
        local equip = sgs.Self:getEquips()
        if #selected > 0 then
            for _,p in ipairs(selected) do
                if hand:contains(p) or equip:contains(p) then
                    can = false
                    break
                end
            end
        end
        local n = 36
        for _,p in ipairs(selected) do
            n = n - p:getNumber()
        end
        if can then 
            return to_select:getNumber() <= n
        else
            return (sgs.Self:getPile("exfang"):contains(to_select:getId())) and (to_select:getNumber() <= n)
        end
	end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local can = false
        local hand = sgs.Self:getHandcards()
        local equip = sgs.Self:getEquips()
        local n = 0
        for _,p in ipairs(cards) do
            if hand:contains(p) or equip:contains(p) then
                can = true
            end
            n = n + p:getNumber()
        end
        if not can then return nil end
        if n ~= 36 then return nil end
		local c = exfangtongCard:clone()
		for _, card in ipairs(cards) do
			c:addSubcard(card)
		end
		return c
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}

exfangtongCard = sgs.CreateSkillCard{
	name = "exfangtongCard",
    will_throw = true,
	filter = function(self, targets, to_select)
        if (#targets >= 1) or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return true
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
        --room:throwCard(self,effect.from)
        room:broadcastSkillInvoke("fangtong")
        effect.from:drawCards(3)
        if effect.from:isWounded() then
            local re = sgs.RecoverStruct(effect.from, nil, 1)
            room:recover(effect.from, re)
        end
		local da = sgs.DamageStruct("exfangtong", effect.from, effect.to, 3, sgs.DamageStruct_Thunder)
        room:damage(da)
	end
}

exfangtong = sgs.CreateTriggerSkill{
    name = "exfangtong",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = exfangtongVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPile("exfang"):length() == 0 then return false end
        room:askForUseCard(player, "@@exfangtong", "@exfangtong",-1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish
    end,
}

exzhangliang:addSkill(exjijun)
exzhangliang:addSkill(exfangtong)
exzhangliang:addSkill(exfangtongVS)

godlvmeng = sgs.General(extension, "godlvmeng", "god", 3, true, false, false)

godshelie = sgs.CreateTriggerSkill{
    name = "godshelie",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Draw then return false end
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke("godshelie")
        room:askForDiscard(player, "godshelie", 2, 2, false, true)
        local suits = {}
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            local suit = card:getSuitString()
            if not table.contains(suits,suit) then
                table.insert(suits,suit)
                dummy:addSubcard(card)
            end
        end
        room:obtainCard(player, dummy, true)
        dummy:deleteLater()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

godshelieextra = sgs.CreateTriggerSkill{
    name = "#godshelieextra",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event ~= sgs.EventPhaseStart then
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card:isKindOf("SkillCard") then return false end
            if not card then return false end
            local names = player:getMarkNames()
            local mark = nil
            for _,p in ipairs(names) do
                if (string.find(p,"&godshelie")) and (player:getMark(p) > 0) then
                    mark = p
                    break
                end
            end
            local suit = card:getSuitString()
            if mark and player:getMark(mark) > 0 then 
                if string.find(mark,suit.."_char") then return false end
                room:setPlayerMark(player, mark, 0)
                mark = string.sub(mark,1,-7)
            else
                mark = "&godshelie"
            end
            mark = mark.."+"..suit.."_char-Clear"
            room:addPlayerMark(player, mark)
            room:setPlayerMark(player, "godshelie-Clear", player:getMark("godshelie-Clear")+1)
        end
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            if player:getMark("godshelie-Clear") < player:getHp() then return false end
            if not room:askForSkillInvoke(player, "godshelie", sgs.QVariant("extra")) then return false end
            room:setPlayerMark(player, "godshelieextra_lun", 1)
            room:setPlayerMark(player, "&godshelie+_lun", 1)
            room:broadcastSkillInvoke("godshelie")
            
            local phase = sgs.PhaseList()
            local choices = {"draw","play"}
            local newphase = nil
            local choice = room:askForChoice(player, "godshelie", table.concat(choices, "+"))
            if choice == "draw" then 
                phase:append(sgs.Player_Draw)
                newphase = "draw"
            else
                phase:append(sgs.Player_Play)
                newphase = "play"
            end

            local log = sgs.LogMessage()
            log.type = "$shelieextra"
            log.arg = player:getGeneralName()
            log.arg2 = newphase
            room:sendLog(log)

            player:play(phase) 
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("godshelie") and target:getMark("godshelieextra_lun") == 0 and target:getPhase() ~= sgs.Player_NotActive
    end,
}


godgongxin = sgs.CreateViewAsSkill
{
    name = "godgongxin",
    n = 99,
    response_pattern = "@@godgongxin",
    expand_pile = "#godgongxin",
    view_filter = function(self, selected, to_select)
        if not sgs.Self:hasFlag("godgongxin") then
            return false
        else
            if #selected > 0 then
                for _,card in ipairs(selected) do
			        if card:isRed() and (not to_select:isRed()) then return false end
                    if card:isBlack() and (not to_select:isBlack()) then return false end
		        end
            end
            if (not sgs.Self:getPile("#godgongxin"):contains(to_select:getId())) then return false end
            if #selected > 1 then return false end
        end
		return true
	end,
    view_as = function(self, cards)
        local card = godgongxinCard:clone()
        if not sgs.Self:hasFlag("godgongxin") then
            return card
        else
            card = godgongxindisCard:clone()
            if #cards > 2 then return nil end
            for _,p in ipairs(cards) do
                card:addSubcard(p)
            end
            return card
        end
	end,
    enabled_at_play = function(self, player)
		return not player:hasUsed("#godgongxin") 
	end,
}

godgongxinCard = sgs.CreateSkillCard
{
    name = "godgongxin",
    filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and (not to_select:isKongcheng())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
        local thands = sgs.IntList()
        if not effect.to:isKongcheng() then
            for _,card in sgs.qlist(effect.to:getHandcards()) do
                thands:append(card:getId())
            end
        end

        room:notifyMoveToPile(effect.from, thands, "godgongxin", sgs.Player_PlaceHand, true)
        room:setPlayerFlag(effect.from, "godgongxin")

        local _data = sgs.QVariant()
        _data:setValue(effect.to)
        effect.from:setTag("godgongxin", _data)--ai

        local card = room:askForUseCard(effect.from, "@@godgongxin", "@godgongxin:"..effect.to:objectName())
        room:setPlayerFlag(effect.from, "-godgongxin")
        if not thands:isEmpty() then
            room:notifyMoveToPile(effect.from, thands, "godgongxin", sgs.Player_PlaceHand, false)
        end

        if not card then return false end
        
        local throwcard = card:getSubcards()
        local from_ids, to_ids = sgs.IntList(), sgs.IntList()
        
        for _,id in sgs.qlist(throwcard) do
            if thands:contains(id) then
                from_ids:append(id)
            else
                to_ids:append(id)
            end
        end
        
        local moves = sgs.CardsMoveList()
        if (not from_ids:isEmpty()) then 
            local move1 = sgs.CardsMoveStruct(from_ids, effect.to, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.to:objectName(), nil, "godgongxin"))
            moves:append(move1)
            
        end
        
        if (not to_ids:isEmpty()) then
            local move2 = sgs.CardsMoveStruct(to_ids, effect.from, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.from:objectName(), nil, "godgongxin"))
            moves:append(move2)
        end
        
        if (not moves:isEmpty()) then
            room:moveCardsAtomic(moves, true)
        end
    end
}

godgongxindisCard = sgs.CreateSkillCard
{
    name = "godgongxindisCard",
    handling_method = sgs.Card_MethodDiscard,
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:broadcastSkillInvoke("godgongxin")
        return false
    end
}

godlvmeng:addSkill(godshelie)
godlvmeng:addSkill(godgongxin)
godlvmeng:addSkill(godshelieextra)
extension:insertRelatedSkills("godshelie","#godshelieextra")

exlitong = sgs.General(extension, "exlitong", "wei", 4, true, false, false)

extuifengbuff = sgs.CreateTriggerSkill{
    name = "#extuifengbuff",
    events = {sgs.Damaged,sgs.Damage, sgs.EventPhaseStart},
    priority = -1,
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            local da = data:toDamage().damage
            room:broadcastSkillInvoke("tuifeng")
            room:sendCompulsoryTriggerLog(player, "extuifeng")
            player:gainMark("&extuifeng", da)
        end
        if event == sgs.Damage then
            if player:getMark("extuifengda-Clear") > 0 then return false end
            room:broadcastSkillInvoke("tuifeng")
            room:sendCompulsoryTriggerLog(player, "extuifeng")
            room:setPlayerMark(player, "extuifengda-Clear", 1)
            player:gainMark("&extuifeng", 1)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            room:broadcastSkillInvoke("tuifeng")
            room:sendCompulsoryTriggerLog(player, "extuifeng")
            player:gainMark("&extuifeng", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("extuifeng")
    end,
}

extuifengVS = sgs.CreateOneCardViewAsSkill
{
    name = "extuifeng",
    view_filter = function(self, card)
    	return true
	end,
    view_as = function(self, card)
        local c = extuifengCard:clone()
        c:addSubcard(card)
        c:setSkillName(self:objectName())
        return c
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&extuifeng") > 0
    end,
}

extuifengCard = sgs.CreateSkillCard
{
    name = "extuifengCard",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:broadcastSkillInvoke("tuifeng")
        source:loseMark("&extuifeng", 1)
        source:drawCards(2)
        room:addSlashCishu(source,1)
    end
}

exlitong:addSkill(extuifengbuff)
exlitong:addSkill(extuifengVS)
extension:insertRelatedSkills("extuifeng","#extuifengbuff")

godzhaoyun = sgs.General(extension, "godzhaoyun", "god", 2, true, false, false)

godjuejin = sgs.CreateTriggerSkill{
    name = "godjuejin",
    events = {sgs.HpChanged,sgs.GameStart,sgs.MaxHpChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart or event == sgs.MaxHpChanged or event == sgs.EventAcquireSkill then
            if player:getMaxHp() == 2 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerProperty(player, "maxhp", sgs.QVariant(2))
        end
        if event == sgs.HpChanged then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local lost = player:getMaxHp() - player:getHp()
            local n = math.max(1,lost)
            player:drawCards(n)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

godjuejinmax = sgs.CreateMaxCardsSkill{
    name = "#godjuejinmax",
    extra_func = function(self, target)
        if target:hasSkill("godjuejin") then return 3 end
        return 0
    end,
}

LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if (#selected >= 1) or to_select:hasFlag("using") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or (pattern == "nullification")
	end ,
	--[[enabled_at_nullification = function(self, player)
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
	end]]
}

godzhaoyun:addSkill(godjuejin)
godzhaoyun:addSkill(godjuejinmax)
godzhaoyun:addSkill(LuaLonghun)
extension:insertRelatedSkills("godjuejin", "#godjuejinmax")

excaochong = sgs.General(extension, "excaochong", "wei", 3, true, false, false)

exchengxiangVS = sgs.CreateViewAsSkill
{
    name = "exchengxiang",
    n = 99,
    response_pattern = "@@exchengxiang",
    expand_pile = "#exchengxiang",
    view_filter = function(self, selected, to_select)
		if #selected ~= 0 then
            local num = #selected
            local sum = 13
            for i = 1, num , 1 do
			    local card = selected[i]
			    sum = sum - card:getNumber() 
            end
            return to_select:getNumber() <= sum and sgs.Self:getPile("#exchengxiang"):contains(to_select:getId())
		end
        if  not sgs.Self:getPile("#exchengxiang"):contains(to_select:getId()) then return false end
		return true
	end,
    view_as = function(self, cards)
        local card = exchengxianggetCard:clone()
        for _,p in ipairs(cards) do
            card:addSubcard(p)
        end
        if #cards > 0 then
            return card
        else
            return nil
        end
	end,
    enabled_at_play = function(self, player)
		return false
	end,

}

exchengxianggetCard = sgs.CreateSkillCard
{
    name = "exchengxiang",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        return false
    end
}

exchengxiang = sgs.CreateTriggerSkill{
    name = "exchengxiang",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    view_as_skill = exchengxiangVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local da = data:toDamage()
        if player:isDead() then return false end
        for i = 1,da.damage,1 do
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            room:broadcastSkillInvoke(self:objectName())
            local card_ids = room:getNCards(4)
		    room:fillAG(card_ids)
            room:returnToTopDrawPile(card_ids)
            
            local cards = sgs.IntList()
            for _,id in sgs.qlist(card_ids) do
                cards:append(id)
            end
            local tag = sgs.QVariant()
            tag:setValue(cards)
            player:setTag("chengxiangcards", tag)

            room:notifyMoveToPile(player, card_ids, "exchengxiang", sgs.Player_DrawPile, true)
            local card = room:askForUseCard(player, "@@exchengxiang", "@exchengxiang")
            room:notifyMoveToPile(player, card_ids, "exchengxiang", sgs.Player_DrawPile, false)
            
            if card then
                local obtainCard = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                for _,id in sgs.qlist(card_ids) do
                    if card:getSubcards():contains(id) then
                        obtainCard:addSubcard(sgs.Sanguosha:getCard(id))
                    end
                end
                for _,id in sgs.qlist(card:getSubcards()) do
                    if card_ids:contains(id) then
                        card_ids:removeOne(id)
                    end
                end
                room:obtainCard(player, obtainCard, true)
                obtainCard:deleteLater()
            end

            local can = true
            if card_ids:length() > 0 then
                if player:getMark("chengxiangex-Clear") == 0 then
                    local ta = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "exchengxianggive", true, true)
                    if ta then
                        can = false
                        room:setPlayerMark(player, "chengxiangex-Clear", 1)
                        local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        for _,id in sgs.qlist(card_ids) do
                            give:addSubcard(sgs.Sanguosha:getCard(id))
                        end
                        room:obtainCard(ta, give, true)
                        give:deleteLater()
                        if ta:isWounded() then
                            local rec = sgs.RecoverStruct(player, nil, 1)
                            room:recover(ta, rec)
                        end
                    end
                end
            end
            room:clearAG()
            if can then
                local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                for _,id in sgs.qlist(card_ids) do
                    give:addSubcard(sgs.Sanguosha:getCard(id))
                end
                room:throwCard(give, nil, player)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

exrenxin = sgs.CreateTriggerSkill{
    name = "exrenxin",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, target, data)
        local room = target:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self:objectName()) then
                local can = false
                if p:getEquips():length() > 0 then can = true end
                if not can then
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:isKindOf("EquipCard") then 
                            can = true
                            break
                        end
                    end
                end
                if p:getMark("exrenxin-Clear") > 0 then can = false end
                if p:hasFlag("Global_exrenxinFailed")  then can = false end
                if can then
                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    p:setTag("renxintarget", _data)
                    if room:askForSkillInvoke(p, self:objectName(), _data) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@exrenxin","EquipCard")
                        local rec = sgs.RecoverStruct(p, nil, 1-target:getHp())
                        room:recover(target, rec)
                        if target:objectName() == p:objectName() then
                            p:drawCards(2)
                            p:turnOver()
                            room:setPlayerMark(p, "exrenxin-Clear", 1)
                            room:setPlayerMark(p, "&exrenxin+-Clear", 1)
                        end
                    else
                        room:setPlayerFlag(p, "Global_exrenxinFailed")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

excaochong:addSkill(exchengxiang)
excaochong:addSkill(exchengxiangVS)
excaochong:addSkill(exrenxin)

exzhonghui = sgs.General(extension, "exzhonghui", "wei", 4, true, false, false)

exquanji = sgs.CreateTriggerSkill{
    name = "exquanji",
    events = {sgs.EventPhaseEnd,sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseEnd then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1)
            local card = room:askForExchange(player, self:objectName(), 1, 1, true, "@quanji", false)
            player:addToPile("exquan", card:getSubcards(), true)
        end
        if event == sgs.Damaged then
            local da = data:toDamage()
            for i = 1,da.damage,1 do
                if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1)
                local card = room:askForExchange(player, self:objectName(), 1, 1, true, "@quanji", false)
                player:addToPile("exquan", card:getSubcards(), true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

exquanjimax = sgs.CreateMaxCardsSkill{
    name = "#exquanjimax",
    extra_func = function(self, target)
         if target:hasSkill("exquanji") then 
            return target:getPile("exquan"):length()
         end
         return 0
    end,
}

ziliex = sgs.CreateTriggerSkill{
    name = "ziliex",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "paiyiex",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(player, "ziliex", 1)
        room:loseMaxHp(player, 1)
        room:acquireSkill(player, "paiyiex", true)
        local choices = {"draw"}
        if player:isWounded() then
            table.insert(choices,"recover")
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
        if choice == "draw" then
            player:drawCards(2)
        else
            local rec = sgs.RecoverStruct(player, nil, 1)
            room:recover(player, rec)
        end
    end,
    can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local x = player:getPile("exquan"):length()

		if x >= 3 and player:isWounded() then return true end
		return false
	end
}

paiyiex = sgs.CreateViewAsSkill
{
    name = "paiyiex",
    expand_pile = "exquan",
    n = 1 ,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getPile("exquan"):contains(to_select:getId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local cc = paiyiexCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#paiyiex")
    end,
}

paiyiexCard = sgs.CreateSkillCard
{
    name = "paiyiex",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets < 1 
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local draw = effect.from:getPile("exquan"):length()
        draw = math.min(draw,7)
        effect.to:drawCards(draw)
        if effect.to:getHandcardNum() > effect.from:getHandcardNum() then
            local damage = sgs.DamageStruct(self, effect.from, effect.to, 1, sgs.DamageStruct_Normal)
            room:damage(damage)
        end
    end,
}

exzhonghui:addSkill(exquanji)
exzhonghui:addSkill(exquanjimax)
exzhonghui:addSkill(ziliex)
extension:insertRelatedSkills("exquanji","#exquanjimax")

spsunquan = sgs.General(extension, "spsunquan", "wu", 4, true, false, false)

spzhiheng = sgs.CreateTriggerSkill{
    name = "spzhiheng",
    events = {sgs.CardsMoveOneTime, sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local can = false

        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            local red = 0
            local black = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then red = red + 1 end
                if card:isBlack() then black = black + 1 end
            end
            if red <= black then return false end
            if use.card:isKindOf("EquipCard") then return false end
            if use.card:isKindOf("DelayedTrick") then return false end
            if use.card:isKindOf("SkillCard") then return false end
            local othertargets = room:getCardTargets(player, use.card, use.to)
            if othertargets:isEmpty() then return false end

            local names = {"peach", "analeptic", "ex_nihilo"}
            if table.contains(names, use.card:objectName()) then
                room:setPlayerMark(player, "spzhihenggood", 1)
            end

            local target = room:askForPlayerChosen(player, othertargets, self:objectName(), "@spzhiheng:"..use.card:objectName(), true, true)
            room:setPlayerMark(player, "spzhihenggood", 0)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                use.to:append(target)
                data:setValue(use)
            end
        end

        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then can = true end
            if move.to and (move.to:objectName() == player:objectName()) and move.to_place == sgs.Player_PlaceHand then can = true end
        end

        if not can then return false end
        can = false
        if player:getHandcardNum() == 0 then 
            can = true
        else
            local red = 0
            local black = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then red = red + 1 end
                if card:isBlack() then black = black + 1 end
            end
            if red == black then can = true end
        end
        if can then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("spzhenghengstart") > 0
    end,
}

spzhihengbuff = sgs.CreateTargetModSkill{
    name = "spzhihengbuff",
    pattern = "BasicCard,TrickCard",
    residue_func = function(self, from, card)
        local player = from
        if not player:hasSkill("spzhiheng") then return 0 end
        local can = false
        local red = 0
        local black = 0
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isRed() then red = red + 1 end
            if card:isBlack() then black = black + 1 end
        end
        if red < black then can = true end
        if can then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        local player = from
        if not player:hasSkill("spzhiheng") then return 0 end
        local can = false
        local red = 0
        local black = 0
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isRed() then red = red + 1 end
            if card:isBlack() then black = black + 1 end
        end
        if red < black then can = true end
        if can then return 1000 end
        return 0
    end,
}

spzhihengstart = sgs.CreateTriggerSkill{
    name = "#spzhihengstart",
    events = {sgs.GameStart, sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill and (data:toString() ~= "spzhiheng" ) then return false end
        room:setPlayerMark(player, "spzhenghengstart", 1)
        if player:getHandcardNum() == 0 then 
            room:sendCompulsoryTriggerLog(player, "spzhiheng", true, true)
            player:drawCards(1, "spzhiheng")
        else
            local red = 0
            local black = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then
                    red = red + 1
                elseif card:isBlack() then
                    black = black + 1
                end
            end
            if red == black then
                room:sendCompulsoryTriggerLog(player, "spzhiheng", true, true)
                player:drawCards(1, "spzhiheng")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("spzhiheng")
    end,
}

shouchang = sgs.CreateTriggerSkill{
    name = "shouchang",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end
        if getTypeString(use.card) == nil then return false end
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:askForDiscard(player, self:objectName(), 1, 1, false, false)
        player:drawCards(1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

spsunquan:addSkill(spzhiheng)
spsunquan:addSkill(spzhihengstart)
spsunquan:addSkill(shouchang)
extension:insertRelatedSkills("spzhiheng", "#spzhihengstart")

exzhangcunhua = sgs.General(extension, "exzhangcunhua", "wei", 3, false, false, false)

exjueqing = sgs.CreateTriggerSkill{
    name = "exjueqing",
    events = {sgs.Predamage,sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        if event == sgs.Predamage then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local damage = data:toDamage()
            room:loseHp(damage.to, damage.damage)
		    return true
        end

        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if not getTypeString(use.card) then return false end
            local n = 0
            local from = use.from
            local to = nil
            for _,p in sgs.qlist(use.to) do
                n = n + 1
                to = p
                if n > 1 then return false end
            end
            if not from or from:objectName() == to:objectName() then return false end
            if (not from:hasSkill(self:objectName())) and (not to:hasSkill(self:objectName())) then return false end
            if to:isNude() or from:isNude() then return false end
            local ta = nil
            if player:objectName() == from:objectName() then
                ta = to
            else
                ta = from
            end
            local _data = sgs.QVariant()
            _data:setValue(ta)

            player:setTag("exjueqingta", _data)

            if not room:askForSkillInvoke(player, self:objectName(), _data) then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            if ta:isNude() then return false end
            local dis = room:askForCardChosen(player, ta, "he", self:objectName())
            room:throwCard(dis, ta, player)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

exshangshi = sgs.CreateTriggerSkill{
    name = "exshangshi",
    events = {sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged,sgs.EventAcquireSkill},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill then
            if data:toString() ~= self:objectName() then return false end
        end
        if not room:askForSkillInvoke(player, self:objectName()) then return false end
        room:broadcastSkillInvoke(self:objectName())
        local lost = player:getLostHp()
        lost = math.max(1,lost)
        local draw = lost - player:getHandcardNum()
        player:drawCards(draw)
    end,
    can_trigger = function(self, player)
        if (not player) or (not player:hasSkill(self:objectName())) then return false end
        local lost = player:getLostHp()
        lost = math.max(1,lost)
        if player:getHandcardNum() < lost then 
            return true
        else
            return false
        end
    end,
}

exzhangcunhua:addSkill(exjueqing)
exzhangcunhua:addSkill(exshangshi)

zhaoe = sgs.General(extension, "zhaoe", "qun", 3, false, false, false)

yanshi = sgs.CreateTriggerSkill{
    name = "yanshi",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    change_skill = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if (not card) or (card:isKindOf("SkillCard")) then return false end

        room:broadcastSkillInvoke(self:objectName())
        if player:getChangeSkillState(self:objectName()) <= 1 then
            room:setChangeSkillState(player, self:objectName(), 2)
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local choices = {}
            if player:canDiscard(player, "he") then
                table.insert(choices,"discard")
            end
            table.insert(choices,"losehp")
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
            if choice == "discard" then
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            elseif choice == "losehp" then
                room:loseHp(player, 1)
            end
        elseif player:getChangeSkillState(self:objectName()) == 2 then
            room:setChangeSkillState(player, self:objectName(), 1)
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local choices = {}
            table.insert(choices,"drawcard")
            if player:isWounded() then
                table.insert(choices,"recoverhp")
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
            if choice == "drawcard" then
                player:drawCards(1)
            elseif choice == "recoverhp" then
                local rec = sgs.RecoverStruct(player, nil, 1)
                room:recover(player, rec)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

renchou = sgs.CreateZeroCardViewAsSkill
{
    name = "renchou",
    view_as = function(self,card)
        return renchouCard:clone()
    end,
    enabled_at_play = function(self,player)
        return true
    end,
}

renchouCard = sgs.CreateSkillCard
{
    name = "renchou",
    filter = function(self, targets, to_select)
        local ta = to_select
        local player = sgs.Self
        if #targets >= 1 then return false end
        if (ta:getHandcardNum() == player:getHandcardNum()) and (ta:getHp() == player:getHp()) then
            return false
        elseif (ta:getHandcardNum() ~= player:getHandcardNum()) and (ta:getHp() ~= player:getHp()) then
            return false
        end
        --return player:inMyAttackRange(to_select)
        return true
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        card:setSkillName(self:objectName())
        --card:deleteLater()
        room:setCardFlag(card, "RemoveFromHistory")
        return card
    end,
}

zhaoe:addSkill(yanshi)
zhaoe:addSkill(renchou)

dliubian = sgs.General(extension, "dliubian", "qun", 3, true, false, false)

xuzun = sgs.CreateTriggerSkill{
    name = "xuzun",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke("xuzun")
        room:setPlayerMark(player, "&xuzun-PlayClear", 1)
        if player:getHandcardNum() > 2*player:getMaxHp() then
            local log = sgs.LogMessage()
            log.type = "$xuzunend"
            log.arg = player:getGeneralName()
            log.arg2 = "xuzun"
            room:sendLog(log)
            room:setPlayerMark(player, "&xuzun-PlayClear", 0)
            room:setPlayerFlag(player,"Global_PlayPhaseTerminated") 
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Play
    end,
}

xuzunbuff = sgs.CreateTriggerSkill{
    name = "#xuzunbuff",
    events = {sgs.CardFinished,sgs.CardsMoveOneTime,sgs.MaxHpChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() then
                room:sendCompulsoryTriggerLog(player, "xuzun")
                room:broadcastSkillInvoke("xuzun")
                player:drawCards(2)
            end
        end
        if event == sgs.CardsMoveOneTime or event == sgs.MaxHpChanged then
            if player:getHandcardNum() > 2*player:getMaxHp() then
                room:broadcastSkillInvoke("xuzun")
                local log = sgs.LogMessage()
                log.type = "$xuzunend"
                log.arg = player:getGeneralName()
                log.arg2 = "xuzun"
                room:sendLog(log)
                room:setPlayerMark(player, "&xuzun-PlayClear", 0)
                room:setPlayerFlag(player,"Global_PlayPhaseTerminated") 
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&xuzun-PlayClear") > 0
    end,
}

dyuyuanVS = sgs.CreateViewAsSkill
{
    name = "dyuyuan",
    n = 2,
    response_pattern = "@@dyuyuan",
	view_filter = function(self, selected, to_select)
		return #selected < 2 and sgs.Self:getHandcards():contains(to_select)
	end,
	view_as = function(self, cards)
        if #cards == 0 then return nil end
        local c = dyuyuanCard:clone()
        for _,id in pairs(cards) do
            c:addSubcard(id)
        end
        return c
    end,
    enabled_at_play = function()
        return false
    end
}

dyuyuanCard = sgs.CreateSkillCard
{
    name = "dyuyuan",
    will_throw = false,
    filter = function(self, targets, to_select)
        if  (#targets >= 1) or (to_select:objectName() == sgs.Self:objectName()) then return false end
		if to_select:getMark("dyuyuan") > 0 then return false end
        return true
    end,
    on_effect = function(self,effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        room:setPlayerMark(effect.to, "dyuyuan", 1)
        room:setPlayerMark(effect.to, "dyuyuan"..effect.from:objectName(), effect.to:getMark("dyuyuan"..effect.from:objectName())+1)
        room:addPlayerMark(effect.to, "&dyuyuan+to+#".. effect.from:objectName())
    end
}

dyuyuan = sgs.CreateTriggerSkill{
    name = "dyuyuan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    priority = 4,
    view_as_skill = dyuyuanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        while(true) do
            if player:getHandcardNum() == 0 then break end
            if not room:askForUseCard(player, "@@dyuyuan", "@dyuyuan", -1) then break end
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "dyuyuan", 0)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and ((target:getPhase() == sgs.Player_Play) or (target:getPhase() == sgs.Player_Discard))
    end,
}

dyuyuandeath = sgs.CreateTriggerSkill{
    name = "#dyuyuandeath",
    events = {sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() then return false end
        local tas = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getMark("dyuyuan"..player:objectName()) > 0 then
                tas:append(p)
            end
        end
        local ta = room:askForPlayerChosen(player, tas, "dyuyuan", "dyuyuandeath", true, true)
        if ta then
            room:broadcastSkillInvoke("dyuyuan",1)
            local num = math.min(ta:getMark("dyuyuan"..player:objectName()),ta:getHp())
            local damage = sgs.DamageStruct(nil, player, ta, num, sgs.DamageStruct_Normal)
            room:damage(damage)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("dyuyuan")
    end,
}

dliubian:addSkill(xuzun)
dliubian:addSkill(xuzunbuff)
dliubian:addSkill(dyuyuan)
dliubian:addSkill(dyuyuanVS)
dliubian:addSkill(dyuyuandeath)
extension:insertRelatedSkills("xuzun","#xuzunbuff")
extension:insertRelatedSkills("dyuyuan","#dyuyuandeath")

dhuaxin = sgs.General(extension, "dhuaxin", "wei", 3, true, false, false)

dxibin = sgs.CreateTriggerSkill{
    name = "dxibin",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        local card = use.card
        if use.card:isKindOf("SkillCard") then return false end
        if use.to:length() ~= 1 then return false end
        if not use.card:isBlack() then return false end
        if not (use.card:isKindOf("Slash") or use.card:isNDTrick()) then return false end
        if use.from:objectName() == player:objectName() then return false end
        if use.from:getPhase() ~= sgs.Player_Play then return false end
        local n = use.from:getHandcardNum()
        local hp = use.from:getHp()
        local prompt = nil
        local dis = 0
        local draw = 0
        if n > hp then
            dis = n - hp
            prompt = string.format("dis:%s::%s:",use.from:getGeneralName(),dis)
        elseif n < math.min(hp,5) then
            draw = math.min(hp,5) - n
            prompt = string.format("draw:%s::%s:",use.from:getGeneralName(),draw)
        else
            prompt = string.format("not:%s:",use.from:getGeneralName())
        end

        local _data = sgs.QVariant()
        _data:setValue(use.from)
        player:setTag("dxibinta", _data) --ai

        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
        room:setPlayerMark(player, "dxibin-Clear", 1)
        room:setPlayerMark(player, "&dxibin+-Clear", 1)
        room:broadcastSkillInvoke(self:objectName())
        if n > hp then
            room:askForDiscard(use.from, self:objectName(), dis, dis, false, false)
        end
        if n < hp then
            use.from:drawCards(draw)
        end
        room:setPlayerCardLimitation(use.from, "use,response", ".|.|.|.", true)
        local log = sgs.LogMessage()
        log.type = "$dxibin"
        log.arg = use.from:getGeneralName()
        room:sendLog(log)

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("dxibin-Clear") == 0
    end,
}

dwanggui = sgs.CreateTriggerSkill{
    name = "dwanggui",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local tas = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("dwanggui"..player:objectName().."-Clear") == 0 then
                    tas:append(p)
                end
            end

            room:setPlayerMark(player, "dwangguida", 1)--ai

            local ta = room:askForPlayerChosen(player, tas, self:objectName(), "dwangguida", true, true)

            room:setPlayerMark(player, "dwangguida", 0)--ai

            if ta then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(ta, "dwanggui"..player:objectName().."-Clear", 1)
                room:setPlayerMark(ta, "&dwanggui+to+#"..player:objectName().."-Clear", 1)
                local da = sgs.DamageStruct(nil, player, ta, 1, sgs.DamageStruct_Normal)
                room:damage(da)
            end
        end
        if event == sgs.Damaged then
            local num = data:toDamage().damage
            if player:isDead() then return false end 
            for i = 1, num, 1 do
                local ta = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "dwangguidraw", true, true)
                if not ta then return false end
                room:broadcastSkillInvoke(self:objectName())
                ta:drawCards(1)
                if ta:objectName() ~= player:objectName() then player:drawCards(1) end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dhuaxin:addSkill(dxibin)
dhuaxin:addSkill(dwanggui)

xushaoex = sgs.General(extension, "xushaoex", "qun", 4, true, false, false)

local function getPingjianSkills(player, used, reason)
    if used == nil then used = {} end
    local allnames = sgs.Sanguosha:getLimitedGeneralNames()
    local targets = {}
    local count = #allnames
    local n = 3
    local i = 0
    while(true) do
        i = i + 1
        local index = math.random(1,count)
        local selected = allnames[index]
        selected = sgs.Sanguosha:getGeneral(selected)
        local skill = selected:getVisibleSkillList()
        for _,p in sgs.qlist(skill) do
            local na = p:objectName()
            if (not player:hasSkill(na)) and (na ~= "pingjianex") and (na ~= "pingjian") and (na ~= "Bqianhuan") 
            and (na ~= "Tqianhuan") and (na ~= "jinhua") then
                local translation = sgs.Sanguosha:translate(":"..na)
                if reason == "play" and (not table.contains(targets,na)) then
                    if string.find(translation,"出牌阶段") then
                        table.insert(targets,na)
                        n = n - 1
                    end
                end
                if reason == "damaged" and (not table.contains(targets,na)) then
                    if string.find(translation,"受到伤害") or string.find(translation,"受到1点伤害") or string.find(translation,"受到一点伤害") then
                        table.insert(targets,na)
                        n = n - 1
                    end
                end
                if reason == "finish" and (not table.contains(targets,na)) then
                    if string.find(translation,"结束阶段") then
                        table.insert(targets,na)
                        n = n - 1
                    end
                end
            end
            if i == 300 or n == 0 then break end
        end
        if i == 300 or n == 0 then break end
    end
    return targets
end

pingjianex = sgs.CreateZeroCardViewAsSkill
{
    name = "pingjianex",
    view_as = function(self)
        return pingjianexCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#pingjianex")
    end
}

pingjianexCard = sgs.CreateSkillCard
{
    name = "pingjianex",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local skill = source:getTag("pingjianexlast"):toString()
        if skill and source:hasSkill(skill) then
            room:detachSkillFromPlayer(source, skill)
        end
        local used = source:getTag("pingjianexused"):toString():split("+")
        local newskills = getPingjianSkills(source, used, "play")

        local get = room:askForChoice(source, self:objectName(), table.concat(newskills,"+"))
        table.insert(used,get)
        room:acquireSkill(source, get, true)
        source:setTag("pingjianexused", sgs.QVariant(table.concat(used,"+")))
        source:setTag("pingjianexlast", sgs.QVariant(get))
    end,
}

pingjianexda = sgs.CreateTriggerSkill{
    name = "#pingjianexda",
    events = {sgs.EventPhaseStart,sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_Finish then return false end
        local reason = nil
        if event == sgs.EventPhaseStart then
            reason = "finish"
        elseif event == sgs.Damaged then
            reason = "damaged"
        end

        if not room:askForSkillInvoke(player, "pingjianex", data) then return false end
        room:broadcastSkillInvoke("pingjianex")

        local skill = player:getTag("pingjianexlast"):toString()
        if skill and player:hasSkill(skill) then
            room:detachSkillFromPlayer(player, skill)
        end
        local used = player:getTag("pingjianexused"):toString():split("+")
        local newskills = getPingjianSkills(player, used, reason)

        local get = room:askForChoice(player, "pingjianex", table.concat(newskills,"+"))
        table.insert(used,get)
        room:acquireSkill(player, get, true)
        player:setTag("pingjianexused", sgs.QVariant(table.concat(used,"+")))
        player:setTag("pingjianexlast", sgs.QVariant(get))
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("pingjianex") and target:isAlive()
    end,
}

xushaoex:addSkill(pingjianex)
xushaoex:addSkill(pingjianexda)
extension:insertRelatedSkills("pingjianex","#pingjianexda")

spzhangliao = sgs.General(extension, "spzhangliao", "god", 4, true, false, false)

spduorui = sgs.CreateTriggerSkill{
    name = "spduorui",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local ta = data:toDamage().to
        if not ta:isAlive() then return false end
        if ta:objectName() == player:objectName() then return false end
        if ta:getMark("spduoruifrom"..player:objectName().."_lun") > 0 then return false end
        local _data = sgs.QVariant()
        _data:setValue(ta)
        player:setTag("duoruita", _data)--ai
        if not room:askForSkillInvoke(player, self:objectName(), _data) then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(ta, "spduoruifrom"..player:objectName().."_lun", 1)
        local choices = {}
        local drskills = ta:getVisibleSkillList()
        for _,skill in sgs.qlist(drskills) do
            table.insert(choices,skill:objectName())
        end
        local lose = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
        room:detachSkillFromPlayer(ta, lose)
        room:setPlayerMark(ta, "&spduorui+:+"..lose.."_lun", 1)
        room:setPlayerMark(ta, "spduorui_lun", 1)
        player:drawCards(1)
        
        ta:setTag("spduoruifrom"..player:objectName(),sgs.QVariant(lose))
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

spduoruireturn = sgs.CreateTriggerSkill{
    name = "#spduoruireturn",
    events = {sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("spduorui_lun") > 0 then
                for _,ot in sgs.qlist(room:getAllPlayers(true)) do
                    if p:getMark("spduoruifrom"..ot:objectName().."_lun") > 0 then
                        room:setPlayerMark(p, "spduoruifrom"..ot:objectName().."_lun", 0)
                        local skill = p:getTag("spduoruifrom"..ot:objectName()):toString()
                        local log = sgs.LogMessage()
                        log.type = "$spduoruireturn"
                        log.arg = p:getGeneralName()
                        log.arg2 = "spduorui"
                        log.arg3 = skill
                        room:sendLog(log)
                        room:acquireSkill(p, skill, true)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

gfengyingVS = sgs.CreateViewAsSkill
{
    name = "gfengying",
    n = 1,
    response_pattern = "@@gfengying",
    view_filter = function(self, selected, to_select)
        return #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local c = gfengyingCard:clone()
        for _,card in ipairs(cards) do
            c:addSubcard(card)
        end
        return c
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

gfengyingCard = sgs.CreateSkillCard
{
    name = "gfengying",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end
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

        room:setPlayerMark(source, "gfengying-Clear", source:getMark("gfengying-Clear")+1)
        room:addPlayerMark(source, "&gfengying+-Clear")
        local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        for _,id in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(sgs.Sanguosha:getCard(id))
        end
        return slash
    end,
}

gfengyingtarget = sgs.CreateTargetModSkill{
    name = "#gfengyingtarget",
    residue_func = function(self, from, card)
        if card:getSkillName() == "gfengying" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "gfengying" then return 1000 end
        return 0
    end,
}

gfengying = sgs.CreateTriggerSkill{
    name = "gfengying",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = gfengyingVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_PlaceHand then return false end
        if (not move.to) or (move.to:objectName() ~= player:objectName()) then return false end
        room:askForUseCard(player, "@@gfengying", "@gfengying")
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("gfengying-Clear") < 4 
        and target:getMark("gamestart") > 0
    end,
}

gfengyingstart = sgs.CreateTriggerSkill{
    name = "#gfengyingstart",
    events = {sgs.GameStart},
    global = true,
    frequency = sgs.Skill_NotFrequent,
    priority = 10,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "gamestart", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

spzhangliao:addSkill(spduorui)
spzhangliao:addSkill(spduoruireturn)
spzhangliao:addSkill(gfengying)
spzhangliao:addSkill(gfengyingVS)
spzhangliao:addSkill(gfengyingtarget)
spzhangliao:addSkill(gfengyingstart)
extension:insertRelatedSkills("spduorui","#spduoruireturn")
extension:insertRelatedSkills("gfengying","#gfengyingtarget")
extension:insertRelatedSkills("gfengying","#gfengyingstart")

exzhangxingcai = sgs.General(extension, "exzhangxingcai", "shu", 3, false, false, false)

shenxianex = sgs.CreateTriggerSkill{
    name = "shenxianex",
    events = {sgs.CardsMoveOneTime,sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local can = false
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place == sgs.Player_DiscardPile then
                if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_USE) then
                    for _, id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if (not card:hasFlag("CardUse")) and card:isKindOf("BasicCard") then
                            can = true
                            break
                        end
                    end
                end
            end
        end
        if event == sgs.CardUsed then
            local card = data:toCardUse().card
            if card and card:isKindOf("BasicCard") then can = true end
        end
        if event == sgs.CardResponded then
            local card = data:toCardResponse().m_card
            if card and card:isKindOf("BasicCard") then can = true end
        end
        if can then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

shenxianjudge = sgs.CreateTriggerSkill{
    name = "#shenxianjudge",
    events = {sgs.PreCardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local card = nil
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse then
			room:setCardFlag(card, "CardUse")
		end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

exqiangwu = sgs.CreateZeroCardViewAsSkill
{
    name = "exqiangwu",
    view_as = function(self, cards)
        return exqiangwuCard:clone()
    end, 
    enabled_at_play = function(self, player)
        return not player :hasUsed("#exqiangwu")
    end, 
}

exqiangwuCard = sgs.CreateSkillCard
{
    name = "exqiangwu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
		local room = source:getRoom()
        source:drawCards(2)
        local card = room:askForDiscard(source, self:objectName(), 1, 1, true, true, "@exqiangwu")
        if card then
            local cc = nil
            for _,id in sgs.qlist(card:getSubcards()) do
                cc = sgs.Sanguosha:getCard(id)
            end
            room:setPlayerMark(source, "&exqiangwu-PlayClear", cc:getNumber())
        end
    end
}

exqiangwuta = sgs.CreateTargetModSkill{
    name = "#exexqiangwuta",
    pattern = "BasicCard,TrickCard",
    residue_func = function(self, from, card)
        if (from:getMark("&exqiangwu-PlayClear") > 0) and (card:getNumber() >= from:getMark("&exqiangwu-PlayClear")) then
            return 1000
        end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if (from:getMark("&exqiangwu-PlayClear") > 0) and (card:getNumber() <= from:getMark("&exqiangwu-PlayClear")) then
            return 1000
        end
        return 0
    end,
}

exzhangxingcai:addSkill(shenxianex)
exzhangxingcai:addSkill(shenxianjudge)
exzhangxingcai:addSkill(exqiangwu)
exzhangxingcai:addSkill(exqiangwuta)
extension:insertRelatedSkills("shenxianex","#shenxianjudge")
extension:insertRelatedSkills("exqiangwu","#exqiangwu")

spcaojinyu = sgs.General(extension, "spcaojinyu", "wei", 3, false, false, false)

spyuqiVS = sgs.CreateViewAsSkill
{
    name = "spyuqi",
    expand_pile = "#spyuqi",
    response_pattern = "@@spyuqi",
    n = 99,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("#spyuqi"):contains(to_select:getId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local cc = spyuqiCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return false 
    end
}

spyuqiCard = sgs.CreateSkillCard
{
    name = "spyuqi",
    will_throw = false,
    target_fixed = true,
    about_to_use = function(self,room,use)
        return
    end,
    on_use = function(self, room, source, targets)
        return false
    end
}

spyuqi = sgs.CreateTriggerSkill
{
    name = "spyuqi",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = spyuqiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self:objectName()) then
                local n = p:getMark("SkillDescriptionArg1_spyuqi")
                if n == 0 then
                    room:setPlayerMark(p, "SkillDescriptionArg1_spyuqi", 1)
                    n = 1
                end
                if p:getMark("spyuqi-Clear") < n then
                    local m = p:getMark("SkillDescriptionArg2_spyuqi")
                    if m == 0 then
                        room:setPlayerMark(p, "SkillDescriptionArg2_spyuqi", 3)
                        m = 3
                    end
                    p:setSkillDescriptionSwap("spyuqi", "%arg1", p:getMark("SkillDescriptionArg1_spyuqi"))
                    p:setSkillDescriptionSwap("spyuqi", "%arg2", p:getMark("SkillDescriptionArg2_spyuqi"))
                    room:changeTranslation(p, "spyuqi", 2)
                    local prompt = string.format("view:%s::%s:",m,player:getGeneralName())
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then

                        local log = sgs.LogMessage()
                        log.type = "$spyuqiview"
                        log.from = p
                        log.arg = m
                        log.arg2 = self:objectName()
                        room:sendLog(log)

                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerMark(p, "spyuqi-Clear", p:getMark("spyuqi-Clear")+1)
                        room:addPlayerMark(p, "&spyuqi+-Clear", 1)
                        local view_cards = room:getNCards(m)
                        room:returnToTopDrawPile(view_cards)

                        local se = sgs.LogMessage()
                        local names = {}
                        for _,id in sgs.qlist(view_cards) do
                            table.insert(names,id)
                        end
                        se.type = "$spyuqiselfview"
                        se.arg = m
                        se.card_str = table.concat(names, "+")
                        room:sendLog(se, p)

                        local tag = sgs.QVariant()
                        tag:setValue(player)
                        p:setTag("spyuqita", tag)--ai
                        local tag2 = sgs.QVariant()
                        tag2:setValue(view_cards)
                        p:setTag("spyuqicc", tag2)--ai

                        room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                        local card = room:askForUseCard(p, "@@spyuqi", "@spyuqi:"..player:getGeneralName())

                        room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, false)
                        
                        if card then
                            local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                            for _,id in sgs.qlist(card:getSubcards()) do
                                give:addSubcard(sgs.Sanguosha:getCard(id))
                                view_cards:removeOne(id)
                            end
                            room:obtainCard(player, give, false)
                            give:deleteLater()
                        end

                        if card and view_cards:length() > 0 then

                            local tag = sgs.QVariant()
                            tag:setValue(p)
                            p:setTag("spyuqita", tag)--ai
                            local tag2 = sgs.QVariant()
                            tag2:setValue(view_cards)
                            p:setTag("spyuqicc", tag2)--ai

                            room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                            local card2 = room:askForUseCard(p, "@@spyuqi", "@spyuqi:"..p:getGeneralName())

                            room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, false)

                            if card2 then
                                local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                                for _,id in sgs.qlist(card2:getSubcards()) do
                                    obtain:addSubcard(sgs.Sanguosha:getCard(id))
                                    view_cards:removeOne(id)
                                end
                                room:obtainCard(p, obtain, false)
                                obtain:deleteLater()
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target:isAlive()
    end,
}

spxianjin = sgs.CreateTriggerSkill{
    name = "spxianjin",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke(self:objectName())
        player:setSkillDescriptionSwap("spyuqi", "%arg1", player:getMark("SkillDescriptionArg1_spyuqi"))
        player:setSkillDescriptionSwap("spyuqi", "%arg2", player:getMark("SkillDescriptionArg2_spyuqi"))
        room:changeTranslation(player, "spyuqi", 2)
        local m = player:getMark("SkillDescriptionArg1_spyuqi")
        local n = player:getMark("SkillDescriptionArg2_spyuqi")
        if m == 0 then 
            room:setPlayerMark(player, "SkillDescriptionArg1_spyuqi", 1)
        end
        if n == 0 then
            room:setPlayerMark(player, "SkillDescriptionArg2_spyuqi", 4)
            player:setSkillDescriptionSwap("spyuqi", "%arg1", player:getMark("SkillDescriptionArg1_spyuqi"))
            player:setSkillDescriptionSwap("spyuqi", "%arg2", player:getMark("SkillDescriptionArg2_spyuqi"))
            room:changeTranslation(player, "spyuqi", 2)
        elseif n < 5 then
            room:setPlayerMark(player, "SkillDescriptionArg2_spyuqi", n + 1)
            room:setPlayerMark(player, "&spxianjin", player:getMark("SkillDescriptionArg2_spyuqi"))
            player:setSkillDescriptionSwap("spyuqi", "%arg1", player:getMark("SkillDescriptionArg1_spyuqi"))
            player:setSkillDescriptionSwap("spyuqi", "%arg2", player:getMark("SkillDescriptionArg2_spyuqi"))
            room:changeTranslation(player, "spyuqi", 2)
        elseif n == 5 then
            local ta = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@spxianjin", true, true)
            if ta then
                room:broadcastSkillInvoke("spyuqi")

                local log = sgs.LogMessage()
                log.type = "$spyuqiview"
                log.from = ta
                log.arg = n
                log.arg2 = "spyuqi"
                room:sendLog(log)

                local view_cards = room:getNCards(n)
                room:returnToTopDrawPile(view_cards)

                local se = sgs.LogMessage()
                local names = {}
                for _,id in sgs.qlist(view_cards) do
                    table.insert(names,id)
                end
                se.type = "$spyuqiselfview"
                se.arg = n
                se.card_str = table.concat(names, "+")
                room:sendLog(se, ta)

                local tag = sgs.QVariant()
                tag:setValue(ta)
                player:setTag("spyuqita", tag)--ai
                local tag2 = sgs.QVariant()
                tag2:setValue(view_cards)
                player:setTag("spyuqicc", tag2)--ai

                room:notifyMoveToPile(player, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                local card = room:askForUseCard(player, "@@spyuqi", "@spyuqi:"..ta:getGeneralName())

                room:notifyMoveToPile(player, view_cards, "spyuqi", sgs.Player_DrawPile, false)
                        
                if card then
                    local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    for _,id in sgs.qlist(card:getSubcards()) do
                        give:addSubcard(sgs.Sanguosha:getCard(id))
                        view_cards:removeOne(id)
                    end
                    room:obtainCard(ta, give, false)
                    give:deleteLater()
                end

                if card and view_cards:length() > 0 then

                    local tag = sgs.QVariant()
                    tag:setValue(player)
                    player:setTag("spyuqita", tag)--ai
                    local tag2 = sgs.QVariant()
                    tag2:setValue(view_cards)
                    player:setTag("spyuqicc", tag2)--ai

                    room:notifyMoveToPile(player, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                    local card2 = room:askForUseCard(player, "@@spyuqi", "@spyuqi:"..player:getGeneralName())

                    room:notifyMoveToPile(player, view_cards, "spyuqi", sgs.Player_DrawPile, false)

                    if card2 then
                        local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        for _,id in sgs.qlist(card2:getSubcards()) do
                            obtain:addSubcard(sgs.Sanguosha:getCard(id))
                            view_cards:removeOne(id)
                        end
                        room:obtainCard(player, obtain, false)
                        obtain:deleteLater()
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
        and target:hasSkill("spyuqi") and target:getPhase() == sgs.Player_Start
    end,
}

spshanshen = sgs.CreateTriggerSkill{
    name = "spshanshen",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self:objectName()) and player:getMark("spshanshen"..p:objectName()) == 0 and p:hasSkill("spyuqi") then
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())

                    if p:isWounded() then
                        local rec = sgs.RecoverStruct(p, nil, 1)
                        room:recover(p, rec)
                    end

                    room:setPlayerMark(player, "spshanshen"..p:objectName(), 1)
                    room:setPlayerMark(player, "&spshanshen+to+#"..p:objectName(), 1)
                    if p:getMark("SkillDescriptionArg2_spyuqi") == 0 then
                        room:setPlayerMark(p, "SkillDescriptionArg1_spyuqi", 3)
                        p:setSkillDescriptionSwap("spyuqi", "%arg1", p:getMark("SkillDescriptionArg1_spyuqi"))
                        p:setSkillDescriptionSwap("spyuqi", "%arg2", p:getMark("SkillDescriptionArg2_spyuqi"))
                        room:changeTranslation(p, "spyuqi", 2)
                    end
                    if p:getMark("SkillDescriptionArg1_spyuqi") == 0 then
                        room:setPlayerMark(p, "SkillDescriptionArg1_spyuqi", 2)
                        p:setSkillDescriptionSwap("spyuqi", "%arg1", p:getMark("SkillDescriptionArg1_spyuqi"))
                        p:setSkillDescriptionSwap("spyuqi", "%arg2", p:getMark("SkillDescriptionArg2_spyuqi"))
                        room:changeTranslation(p, "spyuqi", 2)
                    elseif p:getMark("SkillDescriptionArg1_spyuqi") < 5 then
                        room:setPlayerMark(p, "SkillDescriptionArg1_spyuqi", p:getMark("SkillDescriptionArg1_spyuqi")+1)
                        p:setSkillDescriptionSwap("spyuqi", "%arg1", p:getMark("SkillDescriptionArg1_spyuqi"))
                        p:setSkillDescriptionSwap("spyuqi", "%arg2", p:getMark("SkillDescriptionArg2_spyuqi"))
                        room:changeTranslation(p, "spyuqi", 2)
                        room:setPlayerMark(p, "&spshanshen", p:getMark("SkillDescriptionArg1_spyuqi"))
                    elseif p:getMark("SkillDescriptionArg1_spyuqi") == 5 then
                        local ta = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), "@spshanshen", true, true)
                        if ta then
                            room:broadcastSkillInvoke("spyuqi")


                            local tag = sgs.QVariant()
                            tag:setValue(ta)
                            p:setTag("spyuqita", tag)--ai
                            local tag2 = sgs.QVariant()
                            tag2:setValue(view_cards)
                            player:setTag("spyuqicc", tag2)--ai

                            local view_cards = room:getNCards(p:getMark("SkillDescriptionArg2_spyuqi"))
                            room:returnToTopDrawPile(view_cards)

                            local log = sgs.LogMessage()
                            log.type = "$spyuqiview"
                            log.from = ta
                            log.arg = p:getMark("SkillDescriptionArg2_spyuqi")
                            log.arg2 = "spyuqi"
                            room:sendLog(log)

                            local se = sgs.LogMessage()
                            local names = {}
                            for _,id in sgs.qlist(view_cards) do
                                table.insert(names,id)
                            end
                            se.type = "$spyuqiselfview"
                            se.arg = p:getMark("SkillDescriptionArg2_spyuqi")
                            se.card_str = table.concat(names, "+")
                            room:sendLog(se, p)

                            room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                            local card = room:askForUseCard(p, "@@spyuqi", "@spyuqi:"..ta:getGeneralName())

                            room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, false)
                        
                            if card then
                                local give = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                                for _,id in sgs.qlist(card:getSubcards()) do
                                    give:addSubcard(sgs.Sanguosha:getCard(id))
                                    view_cards:removeOne(id)
                                end
                                room:obtainCard(ta, give, false)
                                give:deleteLater()
                            end

                            if card and view_cards:length() > 0 then

                                local tag = sgs.QVariant()
                                tag:setValue(p)
                                p:setTag("spyuqita", tag)--ai
                                local tag2 = sgs.QVariant()
                                tag2:setValue(view_cards)
                                p:setTag("spyuqicc", tag2)--ai

                                room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, true)

                                local card2 = room:askForUseCard(p, "@@spyuqi", "@spyuqi:"..player:getGeneralName())

                                room:notifyMoveToPile(p, view_cards, "spyuqi", sgs.Player_DrawPile, false)

                                if card2 then
                                    local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                                    for _,id in sgs.qlist(card2:getSubcards()) do
                                        obtain:addSubcard(sgs.Sanguosha:getCard(id))
                                        view_cards:removeOne(id)
                                    end
                                    room:obtainCard(p, obtain, false)
                                    obtain:deleteLater()
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target  ~= nil
    end,
}

spcaojinyu:addSkill(spyuqi)
spcaojinyu:addSkill(spyuqiVS)
spcaojinyu:addSkill(spxianjin)
spcaojinyu:addSkill(spshanshen)

jixiaoqiao = sgs.General(extension, "jixiaoqiao", "wu", 3, false, false, false)

shaoyan = sgs.CreateTriggerSkill{
    name = "shaoyan",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.to:contains(player) and (use.from:getHandcardNum() >= player:getHandcardNum()) then
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jitongxin = sgs.CreateViewAsSkill
{
    name = "jitongxin",
    change_skill = true,
    n = 1,
    response_pattern = "@@jitongxin",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("jitongxinelse") then return false end
        if sgs.Self:getChangeSkillState(self:objectName()) <= 1 then return false end
        return sgs.Self:getHandcards():contains(to_select) and #selected < 1
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("jitongxinelse") then return jitongxinelseCard:clone() end
        local cc = jitongxinCard:clone()
        if #cards == 0 and sgs.Self:getChangeSkillState(self:objectName()) <= 1 then return cc end
        if #cards == 0 and sgs.Self:getChangeSkillState(self:objectName()) == 2 then return nil end
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return player:getMark("jitongxin-PlayClear") == 0
    end
}

jitongxinCard = sgs.CreateSkillCard
{
    name = "jitongxin",
    will_throw = false,
    filter = function(self, targets, to_select)
        if sgs.Self:getChangeSkillState(self:objectName()) <= 1 then 
            return to_select:getHandcardNum() > 0 and #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
        end
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.from, "jitongxin-PlayClear", 1)
        room:setPlayerFlag(effect.from, "jitongxinelse")
        if effect.from:getChangeSkillState(self:objectName()) <= 1 then
            room:setPlayerFlag(effect.to, "jitongxindraw")
            local card = room:askForExchange(effect.to, self:objectName(), 1, 1, false, "jitongxingive:"..effect.from:getGeneralName(), false)
            room:obtainCard(effect.from, card, false)
            room:askForUseCard(effect.from, "@@jitongxin", "jitongxindraw:"..effect.to:getGeneralName())
            room:setPlayerFlag(effect.to, "-jitongxindraw")
        elseif effect.from:getChangeSkillState(self:objectName()) == 2 then
            room:setPlayerFlag(effect.to, "jitongxinda")
            room:obtainCard(effect.to, self, false)
            room:askForUseCard(effect.from, "@@jitongxin", "jitongxinda:"..effect.to:getGeneralName())
            room:setPlayerFlag(effect.to, "-jitongxinda")
        end
        room:setPlayerFlag(effect.from, "-jitongxinelse")
    end,
}

jitongxinelseCard = sgs.CreateSkillCard
{
    name = "jitongxinelse",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasFlag("jitongxindraw") then
                p:drawCards(1)
            elseif p:hasFlag("jitongxinda") then
                local da = sgs.DamageStruct(nil, source, p, 1, sgs.DamageStruct_Normal)
                room:damage(da)
            end
        end
    end
}

jitongxinchange = sgs.CreateTriggerSkill{
    name = "#jitongxinchange",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            local res = data:toCardResponse()
            if res.m_isUse then
                card = res.m_card
            end
        end
        if not card then return false end
        if card:isKindOf("SkillCard") then return false end
        local ctype = getTypeString(card)
        if player:getMark("jitongxin"..ctype.."-Clear") > 0 then return false end
        room:setPlayerMark(player, "jitongxin"..ctype.."-Clear", 1) 
        room:setPlayerMark(player, "&jitongxin+"..ctype.."+-Clear", 1) 
        room:setPlayerMark(player, "jitongxin-PlayClear", 0)
        if player:getChangeSkillState("jitongxin") <= 1 then
            room:setChangeSkillState(player, "jitongxin", 2)
        elseif player:getChangeSkillState("jitongxin") == 2 then
            room:setChangeSkillState(player, "jitongxin", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("jitongxin")
    end,
}

jixiaoqiao:addSkill(shaoyan)
jixiaoqiao:addSkill(jitongxin)
jixiaoqiao:addSkill(jitongxinchange)
extension:insertRelatedSkills("jitongxin","#jitongxinchange")

spsunce = sgs.General(extension, "spsunce", "wu", 4, true, false, false,3)

jiangdraw = sgs.CreateTriggerSkill{
    name = "#jiangdraw",
    events = {sgs.TargetConfirmed,sgs.Damage,sgs.DamageForseen},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local card = data:toCardUse().card
            if (use.from:objectName() ~= player:objectName()) and (not use.to:contains(player)) then return false end
            if (not card:isKindOf("Slash")) and (card:objectName() ~= "duel") then return false end
            if not room:askForSkillInvoke(player, "spjiang", sgs.QVariant("draw")) then return false end
            room:broadcastSkillInvoke("spjiang")
            player:drawCards(1)
        end
        if event == sgs.Damage then
            local card = data:toDamage().card
            if card and card:hasFlag(player:objectName()) then
                room:sendCompulsoryTriggerLog(player, "spjiang")
                room:broadcastSkillInvoke("spjiang")
                player:drawCards(card:subcardsLength())
                if player:getMark("sphunzi") > 0 and player:isWounded() then
                    local rec = sgs.RecoverStruct(player, nil, 1)
                    room:recover(player, rec)
                end
            end
        end 
        if event == sgs.DamageForseen then
            local card = data:toDamage().card
            if not card then return false end
            if card:hasFlag(player:objectName()) and player:getMark("sphunzi") > 0 then
                room:sendCompulsoryTriggerLog(player, "spjiang")
                room:broadcastSkillInvoke("spjiang")
                local log = sgs.LogMessage()
                log.type = "$spjiangfor"
                log.arg = player:getGeneralName()
                room:sendLog(log)
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("spjiang")
    end,
}

spjiang = sgs.CreateViewAsSkill
{
    name = "spjiang",
    n = 999,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local cc = spjiangCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#spjiang")
    end
}

spjiangCard = sgs.CreateSkillCard
{
    name = "spjiang",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("spjiang")
        
        for _,id in sgs.qlist(self:getSubcards()) do
            duel:addSubcard(sgs.Sanguosha:getCard(id))
        end

        duel:deleteLater()
        return duel and duel:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, duel, qtargets)
    end,
    feasible = function(self, targets, player)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("spjiang")
        for _,id in sgs.qlist(self:getSubcards()) do
            duel:addSubcard(sgs.Sanguosha:getCard(id))
        end
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

        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("spjiang")
        for _,id in sgs.qlist(self:getSubcards()) do
            duel:addSubcard(sgs.Sanguosha:getCard(id))
        end
        room:loseHp(source, 1)
        room:setCardFlag(duel, source:objectName())
        return duel
    end,
}

sphunzi = sgs.CreateTriggerSkill{
    name = "sphunzi",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Wake,
    waked_skills = "spjiang2,spyinghun,spyingzi",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:setPlayerMark(player, "sphunzi", 1)
        room:broadcastSkillInvoke(self:objectName())
        local n = 2 - player:getHp()
        if n > 0 then
            local rec = sgs.RecoverStruct(player, nil, n)
            room:recover(player, rec)
        end
        room:loseMaxHp(player, 1)
        room:changeTranslation(player,"spjiang",2)
        room:acquireSkill(player, "spyinghun", true)
        room:acquireSkill(player, "spyingzi", true)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("sphunzi") == 0
    end,
}

spyinghun = sgs.CreateTriggerSkill{
    name = "spyinghun",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local lost = player:getLostHp()
        lost = math.max(1, lost)
        local ta = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@spyinghun:"..lost, true, true)
        if not ta then return false end
        room:broadcastSkillInvoke(self:objectName())
        local choices = {"draw="..lost,"dis="..lost}

        local tag = sgs.QVariant()
        tag:setValue(ta)
        player:setTag("spyinghun", tag)--ai

        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
        if string.find(choice, "draw") then
            ta:drawCards(lost)
            room:askForDiscard(ta, self:objectName(), 1, 1, false, true)
        elseif string.find(choice, "dis") then
            ta:drawCards(1)
            room:askForDiscard(ta, self:objectName(), lost, lost, false, true)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end,
}

spyingzi = sgs.CreateTriggerSkill{
    name = "spyingzi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = 0
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() <= player:getHandcardNum() then
                n = n + 1
            end
        end
        local prompt = string.format("draw:%s:",n)
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(player, "&spyingzi-Clear", n)
        player:drawCards(n)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end,
}

spyingzimax = sgs.CreateMaxCardsSkill{
    name = "#spyingzimax",
    extra_func = function(self, target)
        return target:getMark("&spyingzi-Clear")
    end,
}

spsunce:addSkill(jiangdraw)
spsunce:addSkill(spjiang)
spsunce:addSkill(sphunzi)
extension:insertRelatedSkills("spjiang","#jiangdraw")
extension:insertRelatedSkills("spyingzi","#spyingzimax")

spsimayi = sgs.General(extension, "spsimayi", "god", 4, true, false, false)

sprenjie = sgs.CreateTriggerSkill
{
    name = "sprenjie",
    events = {sgs.CardsMoveOneTime,sgs.Damaged,sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName())
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				local n = move.card_ids:length()
				if n > 0 then
					room:sendCompulsoryTriggerLog(player, "sprenjie")
                    room:broadcastSkillInvoke("sprenjie")
                    room:setPlayerMark(player, "&spren", player:getMark("&spren")+n)
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
            room:sendCompulsoryTriggerLog(player, "sprenjie")
            room:broadcastSkillInvoke("sprenjie")
			room:setPlayerMark(player, "&spren", player:getMark("&spren")+damage.damage)
        elseif event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, "sprenjie")
            room:broadcastSkillInvoke("sprenjie")
            room:setPlayerMark(player, "&spren", player:getMark("&spren")+1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

splianpo = sgs.CreateTriggerSkill{
    name = "splianpo",
    events = {sgs.Death,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("splianpotrigger") > 0 then return false end
            local killer
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
            if killer and killer:hasSkill(self:objectName()) and killer:isAlive() then
                room:setPlayerMark(death.who, "splianpotrigger", 1)
                room:setPlayerMark(killer, "splianpo", 1)
                room:setPlayerMark(killer, "&splianpo-Clear", 1)
                room:sendCompulsoryTriggerLog(killer, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local skills = {}
                local skilllist = death.who:getVisibleSkillList()
                for _,skill in sgs.qlist(skilllist) do
                    if (not skill:isAttachedLordSkill()) and (not player:hasSkill(skill:objectName())) then
                        table.insert(skills,skill:objectName())
                    end
                end
                table.insert(skills,"redr")
                local choice = room:askForChoice(killer, self:objectName(), table.concat(skills,"+"))
                if choice == "redr" then
                    if killer:isWounded() then
                        local rec = sgs.RecoverStruct(killer, nil, 1)
                        room:recover(killer, rec)
                    end
                    killer:drawCards(2)
                else
                    room:acquireSkill(killer, choice, true)
                    room:setPlayerMark(killer, "&splianpo+:+".. choice, 1)
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("splianpo") > 0 then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(p, "splianpo", 0)
                    local log = sgs.LogMessage()
                    log.type = "$splianpoturn"
                    log.arg = p:getGeneralName()
                    log.arg2 = self:objectName()
                    room:sendLog(log)

                    p:drawCards(3)
                    p:gainAnExtraTurn()
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

spbaiyin = sgs.CreateTriggerSkill{
    name = "spbaiyin",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "spjilve",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:setPlayerMark(player, "spbaiyin", 1)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        room:loseMaxHp(player, 1)
        room:setPlayerMark(player, "&spren", player:getMark("&spren")+2)
        room:acquireSkill(player, "spjilve", true)
        if player:getJudgingArea():length() > 0 then
            local card = room:askForCardChosen(player, player, "j", self:objectName())
            room:throwCard(card, nil, player)
        end
    end,
    can_wake = function(self, event, player, data, room)
		if player:getMark("spbaiyin") > 0 then return false end
        if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
            if player:canWake(self:objectName()) then return true end
            return player:getMark("&spren") >= 4 
        end
        return false
	end,
    -- can_trigger = function(self, target)
    --     return target and target:hasSkill(self:objectName()) 
    --     and (target:getPhase() == sgs.Player_Start or target:getPhase() == sgs.Player_Finish) and target:getMark("&spren") >= 4 and target:getMark("spbaiyin") == 0
    -- end,
}

spjilve = sgs.CreateZeroCardViewAsSkill
{
    name = "spjilve",
    view_as = function(self,cards)
        return spjilveCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#spjilve")) and player:getMark("&spren") > 0
    end,
} 

spjilveCard = sgs.CreateSkillCard
{
    name = "spjilve",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local names = {}
        local n = source:getMaxHp()
        local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf("TrickCard") and (not table.contains(names,card:objectName())) then
                get:addSubcard(card)
                table.insert(names,card:objectName())
                n = n - 1
            end
            if n <= 0 then break end
        end
        room:obtainCard(source, get, false)
        get:deleteLater()
        room:setPlayerMark(source, "&spren", source:getMark("&spren")-1)
    end,
}

spjilvere = sgs.CreateTriggerSkill
{
    name = "#spjilvere",
    events = {sgs.AskForRetrial},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.AskForRetrial then
            local judge = data:toJudge()

            local tag = sgs.QVariant()
            tag:setValue(judge)
            player:setTag("spjilvejudge", tag)
            room:setPlayerMark(player, "spjilvejudge", 1)

            if not room:askForSkillInvoke(player, "spjilve", sgs.QVariant("retrial")) then 
                room:setPlayerMark(player, "spjilvejudge", 0)
                return false 
            end
            room:setPlayerMark(player, "spjilvejudge", 0)

            room:broadcastSkillInvoke("spjilve",2)
            room:setPlayerMark(player, "&spren", player:getMark("&spren")-1)
            local suits = "spade+club+diamond+heart"
            local suit = room:askForChoice(player, "spjilve", suits)
            local numbers = {}
            for i = 1, 13, 1 do
                table.insert(numbers,string.format("%d",i))
            end
            local number = room:askForChoice(player, "spjilve", table.concat(numbers,"+"))
            for i = 1, 13, 1 do
                if number == string.format("%d",i) then
                    number = i
                    break
                end
            end

            local new_card = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())
            new_card:setSkillName("spjilve")
            new_card:setNumber(number)
            new_card:setModified(true)
            new_card:deleteLater()
            if suit == "spade" then
                new_card:setSuit(sgs.Card_Spade)
            elseif suit == "club" then
                new_card:setSuit(sgs.Card_Club)
            elseif suit == "diamond" then
                new_card:setSuit(sgs.Card_Diamond)
            elseif suit == "heart" then
                new_card:setSuit(sgs.Card_Heart)
            end
            local log = sgs.LogMessage()
            log.type = "$spjilvere"
            log.arg = player:getGeneralName()
            log.arg2 = "spjilve"
            log.arg3 = new_card:objectName()
            log.arg4 = new_card:getSuitString().."_char"
            log.arg5 = new_card:getNumber()
            room:sendLog(log)
            room:broadcastUpdateCard(room:getAllPlayers(true), judge.card:getEffectiveId(), new_card)
            judge:updateResult()
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("spjilve") and target:getMark("&spren") > 0
    end,
}

spjilveda = sgs.CreateTriggerSkill{
    name = "#spjilveda",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "spjilve", "spjilvedamaged", true, true)
        if not target then return false end
        room:setPlayerMark(player, "&spren", player:getMark("&spren")-1)
        room:broadcastSkillInvoke("spjilve",3)
        player:drawCards(3)
        local give = room:askForExchange(player, "spjilve", 1, 1, false, "spjilvegive:"..target:getGeneralName(), false)
        target:obtainCard(give, false)
        target:turnOver()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("spjilve") and target:getMark("&spren") > 0
    end,
}

spjilvedea = sgs.CreateTriggerSkill{
    name = "#spjilvedea",
    events = {sgs.EnterDying,sgs.AskForPeaches},
    frequency = sgs.Skill_NotFrequent,
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:getMark("jilvedeath-Clear") > 0 then return false end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill("spjilve") and p:getMark("&spren") > 0 then
                    local prompt = string.format("peach:%s:",dying.who:getGeneralName())
                    if room:askForSkillInvoke(p, "spjilve", sgs.QVariant(prompt)) then
                        room:broadcastSkillInvoke("spjilve",4)
                        room:setPlayerMark(p, "&spren", p:getMark("&spren")-1)
                        room:setPlayerMark(dying.who, "jilvedeath-Clear", 1)
                        room:setPlayerMark(dying.who, "&jilve+to+#"..p:objectName().."+-Clear", 1)

                        local log = sgs.LogMessage()
                        log.type = "$spjilvedea"
                        log.arg = dying.who:getGeneralName()
                        room:sendLog(log)

                        break
                    end
                end
            end
        end
        if event == sgs.AskForPeaches then
            local dying = data:toDying()
            if dying.who:getMark("jilvedeath-Clear") > 0 and player:objectName() ~= dying.who:objectName() then
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}

spjilvepr = sgs.CreateProhibitSkill{
    name = "#spjilvepr",
    is_prohibited = function(self, from, to, card)
        return to:getMark("jilvedeath-Clear") > 0 and card:objectName() == "peach" and from:objectName() ~= to:objectName()
    end,
}

spsimayi:addSkill(sprenjie)
spsimayi:addSkill(splianpo)
spsimayi:addSkill(spbaiyin)
extension:insertRelatedSkills("spjilve","#spjilvere")
extension:insertRelatedSkills("spjilve","#spjilveda")
extension:insertRelatedSkills("spjilve","#spjilvedea")
extension:insertRelatedSkills("spjilve","#spjilvepr")

spshenjiangwei = sgs.General(extension, "spshenjiangwei", "god", 4, true, false, false)

sptianren = sgs.CreateTriggerSkill{
    name = "sptianren",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile then return false end
        local names = player:getTag("sptianrencards"):toString():split("+")
        if not names then names = {} end
        local can = false
        for _,id in sgs.qlist(move.card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            if not table.contains(names,card:objectName()) then
                can = true
                table.insert(names,card:objectName())
                local log = sgs.LogMessage()
                log.type = "$spshenjiangweirecord"
                log.arg = player:getGeneralName()
                log.arg2 = self:objectName()
                log.arg3 = card:objectName()
                room:sendLog(log)
            end
        end
        if not can then return false end
        --room:sendCompulsoryTriggerLog(player, self:objectName())
        local n = #names
        room:setPlayerMark(player, "&sptianren", n)
        player:setTag("sptianrencards", sgs.QVariant(table.concat(names,"+")))

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

sptianrenup = sgs.CreateTriggerSkill{
    name = "#sptianrenup",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill("sptianren") then
                local names = p:getTag("sptianrencards"):toString():split("+")
                if #names >= p:getMaxHp() then
                    names = {}
                    room:setPlayerMark(p, "&sptianren", 0)
                    room:sendCompulsoryTriggerLog(p, "sptianren")
                    room:broadcastSkillInvoke("sptianren")
                    room:gainMaxHp(p,1)
                    room:recover(p, sgs.RecoverStruct(p, nil, 1))
                    p:drawCards(2)
                end
                p:setTag("sptianrencards", sgs.QVariant(table.concat(names,"+")))
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}

sppingxiang = sgs.CreateZeroCardViewAsSkill
{
    name = "sppingxiang",
    response_pattern = "@@sppingxiang",
    view_as = function(self,card)
        if sgs.Self:getMark("sppingxiang") == 0 then
            return sppingxiangCard:clone()
        else
            return sppingxiangSlashCard:clone()
        end
    end,
    enabled_at_play = function(self,player)
        if player:getMark("sppingxiang") == 0 then
            return player:getMaxHp() >= 10
        else
            return player:getMaxHp() > 4 and not player:hasUsed("#sppingxiangSlash")
        end
    end,
}

sppingxiangCard = sgs.CreateSkillCard
{
    name = "sppingxiang",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:setPlayerMark(source, "sppingxiang", 1)
        room:setPlayerProperty(source, "maxhp", sgs.QVariant(1))
        room:setPlayerFlag(source, "sppingxiang")
        for i = 1, 9, 1 do
            local card = room:askForUseCard(source, "@@sppingxiang", "@sppingxiang:"..i)
            if not card then break end
        end
        room:setPlayerFlag(source, "-sppingxiang")
        room:setPlayerMark(source, "&sppingxiang", 1)
        room:changeTranslation(source,"sppingxiang",1)
    end,
}

sppingxiangSlashCard = sgs.CreateSkillCard
{
    name = "sppingxiangSlash",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("sppingxiang")

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("sppingxiang")
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

        if not source:hasFlag("sppingxiang") then
            room:setPlayerProperty(source, "maxhp", sgs.QVariant(4))
        end

        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("sppingxiang")
		room:setCardFlag(slash, "RemoveFromHistory")
        return slash
    end,
}

sppingxiangbf = sgs.CreateTargetModSkill{
    name = "#sppingxiangbf",
    residue_func = function(self, from, card)
        if card:getSkillName() == "sppingxiang" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "sppingxiang" then return 1000 end
        return 0
    end,
}

spjiufaVS = sgs.CreateViewAsSkill
{
    name = "spjiufa",
    n = 1,
    expand_pile = "#spjiufa",
    response_pattern = "@@spjiufa",
    view_filter = function(self, selected, to_select)
        if not to_select:isAvailable(sgs.Self) then return false end
        return sgs.Self:getPile("#spjiufa"):contains(to_select:getId()) and #selected < 1
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    view_as = function(self,cards)
        if #cards == 0 then return nil end
        local cc = spjiufaCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
}

spjiufaCard = sgs.CreateSkillCard
{
    name = "spjiufa",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
		local ids = self:getSubcards()
        local card = nil
		for _,id in sgs.qlist(ids) do
            card = sgs.Sanguosha:getCard(id)
        end
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets) then
            return true
        end
        return false 
	end,
    target_fixed = function(self)		
		local ids = self:getSubcards()
        local card = nil
		for _,id in sgs.qlist(ids) do
            card = sgs.Sanguosha:getCard(id)
        end
        if card and card:targetFixed() then
            return true
        end
        return false
	end,
	feasible = function(self, targets)	
		local ids = self:getSubcards()
        local card = nil
		for _,id in sgs.qlist(ids) do
            card = sgs.Sanguosha:getCard(id)
        end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetsFeasible(qtargets, sgs.Self) then
            return true
        end
        return false
	end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local ids = self:getSubcards()
        local card = nil
		for _,id in sgs.qlist(ids) do
            card = sgs.Sanguosha:getCard(id)
        end
        
        local log = sgs.LogMessage()
        log.type = "$spjiufause"
        log.arg = source:getGeneralName()
        log.arg2 = self:objectName()
        log.card_str = card:toString()
        room:sendLog(log)

        room:broadcastSkillInvoke(self:objectName())
        return card
    end,
}

spjiufa = sgs.CreateTriggerSkill{
    name = "spjiufa",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = spjiufaVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:hasFlag("spjiufa") then return false end
            local names = player:getTag("spjiufacards"):toString():split("+")
            if not names then names = {} end
            local can = false
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf("SkillCard") then return false end
            if table.contains(names,card:objectName()) then return false end
            table.insert(names,card:objectName())
            
            room:sendCompulsoryTriggerLog(player, "spjiufa")
            local log = sgs.LogMessage()
            log.type = "$spshenjiangweirecord"
            log.arg = player:getGeneralName()
            log.arg2 = self:objectName()
            log.arg3 = card:objectName()
            room:sendLog(log)


            player:setTag("spjiufacards", sgs.QVariant(table.concat(names,"+")))
            room:setPlayerMark(player, "&spjiufa", #names)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local names = player:getTag("spjiufacards"):toString():split("+")
            if not names then return false end
            if #names < 9 then return false end
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("spjiufa")) then return false end
            names = {}
            room:broadcastSkillInvoke("spjiufa")
            player:setTag("spjiufacards", sgs.QVariant(table.concat(names,"+")))
            room:setPlayerMark(player, "&spjiufa", 0)
            local n = 9
            local card_ids = sgs.IntList()
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if not table.contains(names,card:objectName()) then
                    table.insert(names,card:objectName())
                    card_ids:append(id)
                    n = n - 1
                end
                if n <= 0 then break end
            end
            --room:showCard(player, card_ids)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(),"")
            local move = sgs.CardsMoveStruct(card_ids, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable, reason)
            room:moveCardsAtomic(move,true)

            for _,id in sgs.qlist(card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                room:setCardFlag(card, "spjiufa_card")
            end
            room:setPlayerFlag(player, "spjiufa")
            while(true) do
                local tag = sgs.QVariant()
                tag:setValue(card_ids)
                player:setTag("spjiufalist", tag)


                room:notifyMoveToPile(player, card_ids, "spjiufa", sgs.Player_PlaceTable, true)
                local card = room:askForUseCard(player, "@@spjiufa", "@spjiufa")
                room:notifyMoveToPile(player, card_ids, "spjiufa", sgs.Player_PlaceTable, false)
                for _,id in sgs.qlist(card_ids) do
                    if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                        card_ids:removeOne(id)
                    end
                end
                if card_ids:length() <= 0 then break end
                if not card then break end
                if player:isDead() then break end
            end
            room:setPlayerFlag(player, "-spjiufa")
            if card_ids:length() > 0 then
                local log = sgs.LogMessage()
                log.type = "$spjiufadis"
                log.arg = player:getGeneralName()
                log.arg2 = card_ids:length()
                local cardnames = {}
                for _,id in sgs.qlist(card_ids) do
                    table.insert(cardnames,id)
                end
                log.card_str = table.concat(cardnames, "+")
                room:sendLog(log)

                local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(),"")
                local move1 = sgs.CardsMoveStruct(card_ids, nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, reason1)
                room:moveCardsAtomic(move1,true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

spshenjiangwei:addSkill(sptianren)
spshenjiangwei:addSkill(sptianrenup)
spshenjiangwei:addSkill(sppingxiang)
spshenjiangwei:addSkill(sppingxiangbf)
spshenjiangwei:addSkill(spjiufa)
spshenjiangwei:addSkill(spjiufaVS)
extension:insertRelatedSkills("sptianren","#sptianrenup")
extension:insertRelatedSkills("sppingxiang","#sppingxiangbf")

zhoushand = sgs.General(extension, "zhoushand", "wu", 4, true, false, false)

miyund = sgs.CreateTriggerSkill{
    name = "miyund",
    events = {sgs.RoundStart,sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isNude() then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then return false end

            room:setPlayerFlag(player, "miyunget")
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@miyund", false, true)
            room:setPlayerFlag(player, "-miyunget")

            room:broadcastSkillInvoke(self:objectName())
            local safe = room:askForCardChosen(player, target, "he", self:objectName())
            room:showCard(target, safe)
            room:obtainCard(player, safe, true)
            room:setCardFlag(sgs.Sanguosha:getCard(safe), "miyunsafe")
            room:setCardTip(safe,"miyunsafe")
        end
        if event == sgs.RoundEnd then
            local an = nil
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("miyunsafe") then
                    an = card
                    break
                end
            end
            if not an then return false end

            room:setPlayerFlag(player, "miyungive1")
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "miyund-give", false, true)
            room:setPlayerFlag(player, "-miyungive1")

            room:broadcastSkillInvoke(self:objectName())
            room:obtainCard(target, an, true)
            player:drawCards(player:getMaxHp())
            if player:getHandcardNum() <= player:getMaxHp() then return false end
            local n = player:getHandcardNum() - player:getMaxHp()
            local dis = room:askForExchange(player, self:objectName(), n, n, false, "miyund-dis:"..n, false)
            
            room:setPlayerFlag(player, "miyungive2")
            local ta = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "miyund-obtain:"..n, true, true)
            room:setPlayerFlag(player, "-miyungive2")
           
            if ta then
                room:obtainCard(ta, dis, true)
            else
                room:throwCard(dis, nil, player)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

miyundmax = sgs.CreateMaxCardsSkill
{
    name = "#miyundmax",
    fixed_func = function(self, target)
        local can = false
        for _,card in sgs.qlist(target:getHandcards()) do
            if card:hasFlag("miyunsafe") then
                can = true
                break
            end
        end
        if target:hasSkill("miyund") and can then
            return target:getMaxHp() + 1
        else
            return -1
        end
    end
}

miyundmaxignore = sgs.CreateTriggerSkill{
    name = "#miyundmaxignore",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getHandcardNum() == 0 then return false end
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("miyunsafe") then
                    room:setPlayerCardLimitation(player, "discard", card:toString(), true)
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getHandcardNum() == 0 then return false end
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("miyunsafe") then
                    room:removePlayerCardLimitation(player, "discard", card:toString())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("miyund") and target:getPhase() == sgs.Player_Discard
    end,
}

danyind = sgs.CreateZeroCardViewAsSkill
{
    name = "danyind",
    view_as = function(self, cards)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        local card = sgs.Self:getTag("danyind"):toCard()
        if pattern == "jink" or pattern == "slash" then
            card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
        elseif string.find(pattern, "peach") then
            if string.find(pattern, "analeptic") then
                card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
            else
                card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
            end
        end
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        if player:getMark("danyind-Clear") > 0 then return false end
        if player:getHandcardNum() == 0 then return false end
        local can = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("miyunsafe") then
                can = true
                break
            end
        end
        if not can then return false end
        return (player:isWounded() or sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player)) 
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getMark("danyind-Clear") > 0 then return false end
        if player:getHandcardNum() == 0 then return false end
        local can = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("miyunsafe") then
                can = true
                break
            end
        end
        if not can then return false end
        if pattern == "slash" or pattern == "jink" then return true end
        if pattern == "peach" then return not player:hasFlag("Global_PreventPeach") end
        if string.find(pattern,"analeptic") then return true end
        return false
    end,
}
danyind:setGuhuoDialog("l")

danyindbuff = sgs.CreateTriggerSkill{
    name = "#danyindbuff",
    events = {sgs.Damaged,sgs.PreCardResponded,sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            if player:getMark("danyind-Clear") == 0 then return false end
            if player:getMark("danyind-Clear") == 2 then return false end
            for _,cc in sgs.qlist(player:getHandcards()) do
                if cc:hasFlag("miyunsafe") then
                    room:sendCompulsoryTriggerLog(player, "danyind")
                    room:broadcastSkillInvoke("danyind")
                    room:throwCard(cc, nil, player)
                end
            end
            room:setPlayerMark(player, "danyind-Clear", 2)
        end
        if event == sgs.PreCardUsed or event == sgs.PreCardResponded then
            local card = nil
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf("SkillCard") then return false end
            if card:getSkillName() ~= "danyind" then return false end
            room:setPlayerMark(player, "danyind-Clear", 1)
            room:setPlayerMark(player, "&danyind+-Clear", 1)
            for _,cc in sgs.qlist(player:getHandcards()) do
                if cc:hasFlag("miyunsafe") then
                    room:showCard(player, cc:getEffectiveId())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("danyind") 
    end,
}

zhoushand:addSkill(miyund)
zhoushand:addSkill(miyundmax)
zhoushand:addSkill(miyundmaxignore)
zhoushand:addSkill(danyind)
zhoushand:addSkill(danyindbuff)
extension:insertRelatedSkills("miyund","#miyundmax")
extension:insertRelatedSkills("miyund","#miyundmaxignore")
extension:insertRelatedSkills("danyind","#danyindbuff")

spqinlang = sgs.General(extension, "spqinlang", "wei", 4, true, false, false)

sphaochong = sgs.CreateTriggerSkill{
    name = "sphaochong",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.from:objectName() == player:objectName() then
            local n = 1
            local throw = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            if player:getHandcardNum() > 0  then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if player:getPhase() == sgs.Player_Play then
                        if card:isKindOf("Slash") then
                            local times = player:getMark("JuyingUsedSlashTimes-PlayClear")
                            local limit = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill.Residue, player, card)
                            if times < limit then
                                throw:deleteLater()
                                return false 
                            end
                        elseif card:isAvailable(player) then 
                            throw:deleteLater()
                            return false 
                        end
                    end
                    throw:addSubcard(card)
                    n = n + 1
                end
            else
                throw:deleteLater()
            end
            local prompt = string.format("disdraw:%s:",n)
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then 
                throw:deleteLater()
                return false 
            end
            room:broadcastSkillInvoke(self:objectName())
            if player:getHandcardNum() > 0 then
                room:throwCard(throw, player, nil)
                throw:deleteLater()
            end
            player:drawCards(n)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

spjinjin = sgs.CreateTriggerSkill{
    name = "spjinjin",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getHandcardNum() < player:getMaxCards() then
            local n = player:getMaxCards() - player:getHandcardNum()
            local draw = string.format("draw:%d:",n)
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(draw)) then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "spjinjin-Clear", 1)
            room:setPlayerMark(player, "&spjinjin+-Clear", 1)
            player:drawCards(n)
        elseif player:getHandcardNum() > player:getMaxCards() then
            local n = player:getHandcardNum() - player:getMaxCards()
            local target = nil
            if event == sgs.Damage then
                target = data:toDamage().to
            elseif event == sgs.Damaged then
                target = data:toDamage().from
            end
            local prompt = nil
            if target and target:isAlive() then
                room:setPlayerFlag(target, "spjinjintarget")
                prompt = string.format("dis1:%d::%s:", n, target:getGeneralName())
            else
                prompt = string.format("dis2:%d:", n)
            end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "spjinjin-Clear", 1)
                room:askForDiscard(player, self:objectName(), n, n, false, false)
                local choices = {}
                if player:isWounded() then
                    table.insert(choices, "recover")
                end
                if target and target:isAlive() then
                    table.insert(choices, "damage="..target:getGeneralName())
                end
                if #choices > 0 then
                    local dest = sgs.QVariant()
                    dest:setValue(target)
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), dest)
                    if choice == "recover" then
                        local recover = sgs.RecoverStruct(player, nil, 1)
                        room:recover(player, recover)
                    elseif choice == "damage="..target:getGeneralName() then
                        local damage = sgs.DamageStruct(nil, player, target, 1, sgs.DamageStruct_Normal)
                        room:damage(damage)
                    end
                end
            end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("spjinjintarget") then
                    room:setPlayerFlag(target, "-spjinjintarget")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("spjinjin-Clear") == 0 and target:getHandcardNum() ~= target:getMaxCards()
    end,
}

spqinlang:addSkill(sphaochong)
spqinlang:addSkill(spjinjin)

hfsimayi = sgs.General(extension, "hfsimayi", "jin", 3, true, false, false)

hflanggu = sgs.CreateTriggerSkill{
    name = "hflanggu",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        local card_ids = room:getNCards(2)
        room:returnToTopDrawPile(card_ids)
        room:fillAG(card_ids, player)

        local target = data:toDamage().from
        if target and target:isAlive() then
            room:setPlayerFlag(target, "hflanggutarget")
        end

        local id = room:askForAG(player, card_ids, false, self:objectName())
        room:clearAG(player)
        room:obtainCard(player, id, false)

        if target and target:isAlive() then
            room:setPlayerFlag(target, "-hflanggutarget")
            local log = sgs.LogMessage()
            log.type = "$hflanggusd"
            log.arg = target:getGeneralName()
            log.arg2 = self:objectName()
            log.arg3 = "lightning"
            room:sendLog(log)

            local judge = sgs.JudgeStruct()
			judge.pattern = ".|spade|2~9"
			judge.good = false
			judge.negative = true
			judge.reason = "lightning"
			judge.who = target
			room:judge(judge)
            if judge:isBad() then
				room:damage(sgs.DamageStruct("lightning", nil, target, 3, sgs.DamageStruct_Thunder))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

hfgushi = sgs.CreateZeroCardViewAsSkill
{
    name = "hfgushi",
    view_as = function(self, cards)
        local card = nil
        if sgs.Self:getMark("&hfgushi-PlayClear") == 0 then
            card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
        elseif sgs.Self:getMark("&hfgushi-PlayClear") == 1 then
            card = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_SuitToBeDecided, -1)
        elseif sgs.Self:getMark("&hfgushi-PlayClear") == 2 then
            card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        end
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&hfgushi-PlayClear") < 3
    end,
}

hfgushibuff = sgs.CreateTriggerSkill{
    name = "#hfgushibuff",
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = data:toCardUse().card
        if card:getSkillName() == "hfgushi" then
            room:setPlayerMark(player, "&hfgushi-PlayClear", player:getMark("&hfgushi-PlayClear")+1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("hfgushi")
    end,
}

hfsimayi:addSkill(hflanggu)
hfsimayi:addSkill(hfgushi)
hfsimayi:addSkill(hfgushibuff)
extension:insertRelatedSkills("hfgushi","#hfgushibuff")

dyangbiao = sgs.General(extension, "dyangbiao", "qun", 4, true, false, false, 3)

dzhaohan = sgs.CreateTriggerSkill{
    name = "dzhaohan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isWounded() and room:getTag("SwapPile"):toInt() == 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true, 1)
            local recover = sgs.RecoverStruct(player, nil, 1)
            room:recover(player, recover)
        elseif room:getTag("SwapPile"):toInt() ~= 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true, 2)
            local damage = sgs.DamageStruct(nil, nil, player, 1, sgs.DamageStruct_Normal)
            room:damage(damage)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end,
}

dyizheng = sgs.CreateZeroCardViewAsSkill
{
    name = "dyizheng",
    view_as = function(self, cards)
        return dyizhengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#dyizheng")) and player:getHandcardNum() > 0
    end,
}

dyizhengCard = sgs.CreateSkillCard
{
    name = "dyizheng",
    filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local success = effect.from:pindian(effect.to, "dyizheng", nil)
        if success then
            room:setPlayerMark(effect.to, "&dyizheng", effect.to:getMark("&dyizheng")+1)
        else
            local damage = sgs.DamageStruct(nil, effect.to, effect.from, 1, sgs.DamageStruct_Normal)
            room:damage(damage)
        end
    end,
}

dyizhengskip = sgs.CreateTriggerSkill{
    name = "#dyizhengskip",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
            room:broadcastSkillInvoke("dyizheng")
            local log = sgs.LogMessage()
            log.type = "$dyizhengskip"
            log.arg = player:getGeneralName()
            log.arg2 = "dyizheng"
            log.arg3 = "draw"
            room:sendLog(log)
            room:setPlayerMark(player, "&dyizheng", player:getMark("&dyizheng")-1)
            player:skip(sgs.Player_Draw)
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&dyizheng") > 0
    end,
}

drangjieVS = sgs.CreateViewAsSkill
{
    name = "drangjie",
    expand_pile = "#drangjie",
    response_pattern = "@@drangjie",
    n = 99,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("#drangjie"):contains(to_select:getId()) and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local cc = drangjieCard:clone()
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        return false 
    end
}

drangjieCard = sgs.CreateSkillCard
{
    name = "drangjie",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        return false
    end
}

drangjie = sgs.CreateTriggerSkill{
    name = "drangjie",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = drangjieVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = data:toDamage().damage
        for i = 1, n, 1 do
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1)
                local choices = {}
                if room:canMoveField("ej") then
                    table.insert(choices,"move")
                end
                table.insert(choices, "draw")
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
                if choice == "move" then
                    room:moveField(player, self:objectName(), true, "ej")
                elseif choice == "draw" then
                    local card_ids = sgs.IntList()
                    local n = 9
                    for _,id in sgs.qlist(room:getDiscardPile()) do
                        card_ids:append(id)
                        n = n - 1
                        if n <= 0 then break end
                    end
                    if card_ids:length() == 0 then
                        local log = sgs.LogMessage()
                        log.type = "$drangjienotcard"
                        room:sendLog(log)
                    else
                        local tag = sgs.QVariant()
                        tag:setValue(card_ids)
                        player:setTag("drangjiecards", tag)
                        room:notifyMoveToPile(player, card_ids, "drangjie", sgs.Player_DiscardPile, true)
                        local card = room:askForUseCard(player, "@@drangjie", "@drangjie")
                        room:notifyMoveToPile(player, card_ids, "drangjie", sgs.Player_DiscardPile, false)
                        if card then
                            local movecard = nil
                            for _,id in sgs.qlist(card:getSubcards()) do
                                movecard = sgs.Sanguosha:getCard(id)
                            end
                            local movetops = {"hand"}
                            if movecard:isKindOf("DelayedTrick") then
                                local name = movecard:objectName()
                                for _,p in sgs.qlist(room:getAlivePlayers()) do
                                    if p:hasJudgeArea() and (not p:containsTrick(name)) then
                                        table.insert(movetops,"judge")
                                        break
                                    end
                                end
                            elseif movecard:isKindOf("EquipCard") then
                                local n = -1
                                if movecard:isKindOf("Weapon") then
                                    n = 0
                                elseif movecard:isKindOf("Armor") then
                                    n = 1
                                elseif movecard:isKindOf("DefensiveHorse") then
                                    n = 2
                                elseif movecard:isKindOf("OffensiveHorse") then
                                    n = 3
                                elseif movecard:isKindOf("Treasure") then
                                    n = 4
                                end

                                if n ~= -1 then
                                    for _,p in sgs.qlist(room:getAlivePlayers()) do
                                        if p:hasEquipArea(n) and (not p:getEquip(n)) then
                                            table.insert(movetops,"equip")
                                            break
                                        end
                                    end
                                end
                            end
                            local moveto = room:askForChoice(player, self:objectName(), table.concat(movetops,"+"))
                            if moveto == "hand" then
                                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "drangjiemth:"..movecard:objectName(), false, true)
                                room:obtainCard(target, movecard, true)
                            elseif moveto == "equip" then
                                local targets = sgs.SPlayerList()
                                local n = -1
                                if movecard:isKindOf("Weapon") then
                                    n = 0
                                elseif movecard:isKindOf("Armor") then
                                    n = 1
                                elseif movecard:isKindOf("DefensiveHorse") then
                                    n = 2
                                elseif movecard:isKindOf("OffensiveHorse") then
                                    n = 3
                                elseif movecard:isKindOf("Treasure") then
                                    n = 4
                                end
                                if n ~= -1 then
                                    for _,p in sgs.qlist(room:getAlivePlayers()) do
                                        if p:hasEquipArea(n) and (not p:getEquip(n)) then
                                            targets:append(p)
                                        end
                                    end
                                end

                                local target = room:askForPlayerChosen(player, targets, self:objectName(), "drangjiemte:"..movecard:objectName(), false, true)
                                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), "")
                                room:moveCardTo(movecard, nil, target, sgs.Player_PlaceEquip, reason)

                                local log = sgs.LogMessage()
                                log.type = "$drangjiemovecard"
                                log.arg = player:getGeneralName()
                                log.arg2 = self:objectName()
                                log.arg3 = target:getGeneralName()
                                log.arg4 = "drangjieequiparea"
                                log.card_str = movecard:toString()
                                room:sendLog(log)

                            elseif moveto == "judge" then
                                local targets = sgs.SPlayerList()
                                local name = movecard:objectName()
                                for _,p in sgs.qlist(room:getAlivePlayers()) do
                                    if p:hasJudgeArea() and (not p:containsTrick(name)) then
                                        targets:append(p)
                                    end
                                end

                                room:setPlayerFlag(player,"drangjiejud")

                                local target = room:askForPlayerChosen(player, targets, self:objectName(), "drangjiemtj:"..movecard:objectName(), false, true)
                                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), "")
                                room:moveCardTo(movecard, nil, target, sgs.Player_PlaceDelayedTrick, reason)

                                room:setPlayerFlag(player,"-drangjiejud")

                                local log = sgs.LogMessage()
                                log.type = "$drangjiemovecard"
                                log.arg = player:getGeneralName()
                                log.arg2 = self:objectName()
                                log.arg3 = target:getGeneralName()
                                log.arg4 = "drangjiejudgearea"
                                log.card_str = movecard:toString()
                                room:sendLog(log)
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

dyangbiao:addSkill(dzhaohan)
dyangbiao:addSkill(dyizheng)
dyangbiao:addSkill(dyizhengskip)
dyangbiao:addSkill(drangjie)
dyangbiao:addSkill(drangjieVS)
extension:insertRelatedSkills("dyizheng","#dyizhengskip")

dwzhugeliang = sgs.General(extension, "dwzhugeliang", "shu", 7, true, false, false, 4)

dwzhizhe = sgs.CreateViewAsSkill
{
    name = "dwzhizhe",
    n = 1,
    frequency = sgs.Skill_Limited,
    view_filter = function(self, selected, to_select)
        if sgs.Self:getMark("dwzhizheused") == 0 then 
            if to_select:isKindOf("DelayedTrick") then return false end
            return #selected < 1 and (to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard"))
        else
            return false
        end
    end,
    view_as = function(self, cards)
        if sgs.Self:getMark("dwzhizheused") == 0 then 
            if #cards == 0 then return nil end
            local cc = dwzhizheCard:clone()
            cc:addSubcard(cards[1])
            return cc
        else
            local pattern = sgs.Self:property("dwzhizheshow"):toString()
            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1) 
            card:setSkillName("dwzhizhe")
            return card
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark("dwzhizheused") == 0 then
            return true
        else
            return player:getMark("dwzhizhe-Clear") == 0
        end
    end,
    --[[enabled_at_nullification = function(self, player)
        if player:getMark("dwzhizheused") == 0 then return false end
        local pattern = player:property("dwzhizheshow"):toString()
        if pattern ~= "nullification" then return false end
        return player:getMark("dwzhizhe-Clear") == 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        if player:getMark("dwzhizheused") == 0 then return false end
        local dwzhizhepattern = player:property("dwzhizheshow"):toString()
        if not string.find(dwzhizhepattern, pattern) then return false end
        return player:getMark("dwzhizhe-Clear") == 0
    end,
}

dwzhizheCard = sgs.CreateSkillCard
{
    name = "dwzhizhe",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local name 
        for _,id in sgs.qlist(self:getSubcards()) do
            room:showCard(source, id)
            name = sgs.Sanguosha:getCard(id):objectName()
        end
        room:setPlayerMark(source, "dwzhizheused", 1)
        room:setPlayerMark(source, "&dwzhizhe+:+"..name, 1)
        local names = {}
        table.insert(names,name)
        room:setPlayerProperty(source, "SkillDescriptionRecord_dwzhizhe", sgs.QVariant(table.concat(names, "+")))
        source:setSkillDescriptionSwap("dwzhizhe", "%arg1", table.concat(names, "+"))
        room:changeTranslation(source, "dwzhizhe", 11)
        room:setPlayerProperty(source, "dwzhizheshow", sgs.QVariant(name))
    end,
}

dwzhizhebuff = sgs.CreateTriggerSkill{
    name = "#dwzhizhebuff",
    events = {sgs.PreCardUsed,sgs.PreCardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			local response = data:toCardResponse().m_card
		end
        if (not card) then return false end
        if card:isKindOf("SkillCard") then return false end
        if card:getSkillName() == "dwzhizhe" then
            room:setPlayerMark(player, "dwzhizhe-Clear", 1)
            room:setPlayerMark(player, "&dwzhizhe+-Clear", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("dwzhizhe")
    end,
}

dwqingshiVS = sgs.CreateZeroCardViewAsSkill
{
    name = "dwqingshi",
    response_pattern = "@@dwqingshi",
    view_as = function(self)
        return dwqingshiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

dwqingshiCard = sgs.CreateSkillCard
{
    name = "dwqingshi",
    filter = function(self, targets, to_select)
        if sgs.Self:hasFlag("dwqingshidrawall") then
            return true
        elseif sgs.Self:hasFlag("dwqingshidamage") then
            return to_select:hasFlag("dwqingshiupcan")
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:hasFlag("dwqingshidrawall") then
            effect.to:drawCards(1)
        elseif effect.from:hasFlag("dwqingshidamage") then
            room:setPlayerMark(effect.to, "dwqingshitarget", 1)
        end
    end,
}

dwqingshi = sgs.CreateTriggerSkill{
    name = "dwqingshi",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = dwqingshiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getHandcardNum() == 0 then return false end

        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if not card then return false end
        if card:isKindOf("SkillCard") then return false end

        local can = false
        if card:isKindOf("Slash") then
            if player:getMark("dwqingshiSlash-Clear") > 0 then return false end
            for _,ca in sgs.qlist(player:getHandcards()) do
                if ca:isKindOf("Slash") then
                    can = true
                    break
                end
            end
        else
            if player:getMark("dwqingshi"..card:objectName().."-Clear") > 0 then return false end
            for _,ca in sgs.qlist(player:getHandcards()) do
                if ca:objectName() == card:objectName() then
                    can = true
                    break
                end
            end
        end
        if not can then return false end

        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        local choices = {"drawall"}

        local use
        if event == sgs.CardUsed then
            use = data:toCardUse()
            if use.to:length() > 0 then

                local tag = sgs.QVariant()
                tag:setValue(use)
                player:setTag("dwqingshiuseai", tag)--ai
                room:setPlayerMark(player, "dwqingshiuseai", 1)

                table.insert(choices,"damage="..card:objectName())
            end
        end

        if card:isKindOf("Slash") then
            table.insert(choices,"drawself=dwqingshiSlash")
        else
            table.insert(choices,"drawself="..card:objectName())
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))

        room:setPlayerMark(player, "dwqingshiuseai", 0)--ai

        if choice == "drawall" then
            local log = sgs.LogMessage()
            log.type = "$dwqingshidrawalllog"
            log.arg = player:getGeneralName()
            log.arg2 = "dwqingshi:drawall"
            room:sendLog(log)

            room:setPlayerFlag(player, "dwqingshidrawall")
            room:askForUseCard(player, "@@dwqingshi", "dwqingshidrawall")
            room:setPlayerFlag(player, "-dwqingshidrawall")
        elseif string.find(choice, "damage") then
            local log = sgs.LogMessage()
            log.type = "$dwqingshidamagelog"
            log.arg = player:getGeneralName()
            log.arg2 = "dwqingshidamagemore"
            log.card_str = card:toString()
            room:sendLog(log)

            for _,p in sgs.qlist(use.to) do
                room:setPlayerFlag(p, "dwqingshiupcan")
            end
            room:setPlayerFlag(player, "dwqingshidamage")
            room:askForUseCard(player, "@@dwqingshi", "dwqingshidamage:"..card:objectName())
            room:setPlayerFlag(player, "-dwqingshidamage")

            local names = {}
            for _,p in sgs.qlist(use.to) do
                room:setPlayerFlag(p, "-dwqingshiupcan")
                if p:getMark("dwqingshitarget") > 0 then
                    room:setPlayerMark(p, "dwqingshitarget", 0)
                    table.insert(names, p:objectName())
                end
            end
            if #names > 0 then
                room:setCardFlag(card, "dwqingshidamage")
                card:setTag("dwqingshitarget", sgs.QVariant(table.concat(names,"+")))
            end
        elseif string.find(choice, "drawself") then
            local log = sgs.LogMessage()
            log.type = "$dwqingshidrawselflog"
            log.arg = player:getGeneralName()
            if card:isKindOf("Slash") then
                log.arg2 = "dwqingshiSlash"
            else
                log.arg2 = card:objectName()
            end
            room:sendLog(log)

            room:broadcastSkillInvoke(self:objectName())
            if card:isKindOf("Slash") then
                room:setPlayerMark(player, "dwqingshiSlash-Clear", 1)
            else
                room:setPlayerMark(player, "dwqingshi"..card:objectName().."-Clear", 1)
            end
            player:drawCards(2)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dwqingshibuff = sgs.CreateTriggerSkill{
    name = "#dwqingshibuff",
    events = {sgs.DamageCaused,sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("dwqingshidamage") then
                local names = damage.card:getTag("dwqingshitarget"):toString():split("+")
                if table.contains(names, damage.to:objectName()) then
                    local log = sgs.LogMessage()
                    log.type = "$dwqingshidamageup"
                    log.arg = damage.to:getGeneralName()
                    log.arg2 = "dwqingshi"
                    log.arg3 = damage.damage
                    log.arg4 = damage.damage + 1
                    room:sendLog(log)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end

        if event == sgs.CardFinished then
            local card = data:toCardUse().card
            if card:hasFlag("dwqingshidamage") then
                card:removeTag("dwqingshitarget")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("dwqingshi")
    end,
}

dwjingcui = sgs.CreateTriggerSkill{
    name = "dwjingcui",
    events = {sgs.GameStart,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.GameStart then
            if player:getHandcardNum() < 7 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local n = 7 - player:getHandcardNum()
                player:drawCards(n)
            end
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local n = 0
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getNumber() == 7 then
                    n = n + 1
                end
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            
            local log = sgs.LogMessage()
            log.type = "$dwjingcuicount"
            log.arg = n
            room:sendLog(log)

            n = math.min(n,player:getMaxHp())
            n = math.max(n,1)
            --[[if player:getHp() > n then
                room:loseHp(player, player:getHp()-n)
            elseif player:getHp() < n then
                local recover = sgs.RecoverStruct(player, nil, n-player:getHp())
                room:recover(player, recover)
            end]]
            if player:getHp() ~= n then
                room:setPlayerProperty(player, "hp", sgs.QVariant(n))
            end
            n = math.min(n,7)

            local card_ids = room:getNCards(n)
            room:askForGuanxing(player, card_ids)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dwjingcuidying = sgs.CreateTriggerSkill{
    name = "#dwjingcuidying",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if player:getHandcardNum() == 0 then return false end
        local n = 0
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:getNumber() == 7 then
                n = n + 1
            end
        end
        if n == 0 then return false end

        local dying_data = data:toDying()
		local source = dying_data.who
        local prompt = string.format("dying:%s::%s:",source:getGeneralName(), n)
        if not room:askForSkillInvoke(player, "dwjingcui", sgs.QVariant(prompt)) then return false end
        room:broadcastSkillInvoke("dwjingcui")
        room:setPlayerMark(player, "dwjingcui_lun", 1)
        room:setPlayerMark(player, "&dwjingcui+_lun", 1)
        local log = sgs.LogMessage()


        if source:objectName() ~= player:objectName() then
            local give = room:askForExchange(player, "dwjingcui", 1, 1, false, "@dwjingcui:"..source:getGeneralName(), false)
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getNumber() == 7 then
                    room:obtainCard(source, card, false)
                    break
                end
            end
            room:obtainCard(source, give, false)
        else
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getNumber() == 7 then
                    room:obtainCard(player, card, false)
                    break
                end
            end
        end
        
        local recover = sgs.RecoverStruct(player, nil, 1-source:getHp())
        room:recover(source, recover)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("dwjingcui") and target:getMark("dwjingcui_lun") == 0
    end,
}

dwzhugeliang:addSkill(dwzhizhe)
dwzhugeliang:addSkill(dwzhizhebuff)
dwzhugeliang:addSkill(dwqingshi)
dwzhugeliang:addSkill(dwqingshiVS)
dwzhugeliang:addSkill(dwqingshibuff)
dwzhugeliang:addSkill(dwjingcui)
dwzhugeliang:addSkill(dwjingcuidying)
extension:insertRelatedSkills("dwzhizhe","#dwzhizhebuff")
extension:insertRelatedSkills("dwqingshi","#dwqingshibuff")
extension:insertRelatedSkills("dwjingcui","#dwjingcuidying")

dmzhouxuan = sgs.General(extension, "dmzhouxuan", "wei", 3, true, false, false)

dmwumei = sgs.CreateTriggerSkill{
    name = "dmwumei",
    events = {sgs.TurnStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("dmwumeiused_lun") > 0 then return false end
        local prompt = "dmwumeiextraturn"
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), prompt, true, true)
        if not target then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(player, "dmwumeiused_lun", 1)
        room:setPlayerMark(target, "&dmwumei-SelfClear",1)

        local log = sgs.LogMessage()
        log.type = "$dmwumeigainturn"
        log.arg = target:getGeneralName()
        log.arg2 = self:objectName()
        room:sendLog(log)

        target:gainAnExtraTurn()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dmwumeibuff = sgs.CreateTriggerSkill{
    name = "#dmwumeibuff",
    events = {sgs.TurnStart,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TurnStart then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                local hp = p:getHp()
                room:setPlayerMark(p, "dmwumeihp-Clear", hp)
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    local maxhp = p:getMaxHp()
                    local hp = math.min(p:getMark("dmwumeihp-Clear"), maxhp)

                    if p:getHp() ~= hp then
                        local log = sgs.LogMessage()
                        log.type = "$dmwumeichangehp"
                        log.arg = p:getGeneralName()
                        log.arg2 = "dmwumei"
                        log.arg3 = hp
                        room:sendLog(log)

                        room:setPlayerProperty(p, "hp", sgs.QVariant(hp))
                    end
                end
            end
            if change.to == sgs.Player_Discard then
                local log = sgs.LogMessage()
                log.type = "$dmwumeiskip"
                log.from = player
                log.arg = "dmwumei"
                log.arg2 = "discard"
                room:sendLog(log)

                room:broadcastSkillInvoke("dmwumei")
				player:skip(sgs.Player_Discard)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&dmwumei-SelfClear") > 0
    end,
}

local function JudgeDamageCard(card)
    if card:isKindOf("BasicCard") then
        if card:isKindOf("Slash") then 
            return true
        else
            return false
        end
    elseif card:isKindOf("TrickCard") then
        local damagecards = {"duel", "fire_attack", "savage_assault", "archery_attack"}
        for _,p in ipairs(damagecards) do
            if card:objectName() == p then
                return true
            end
        end
        return false
    elseif card:isKindOf("EquipCard") then
        return false
    end
    return false
end

dmzhanmeng = sgs.CreateTriggerSkill{
    name = "dmzhanmeng",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if card:isKindOf("SkillCard") then return false end

        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        local allchoices = {"recover", "draw", "discard"}
        local choices = {}
        for _,cc in ipairs(allchoices) do
            if player:getMark("dmzhanmeng"..cc.."-Clear") == 0 then
                table.insert(choices, cc)
            end
        end
        table.insert(choices, "cancel")

        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"))
        if choice == "cancel" then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(player, "dmzhanmeng"..choice.."-Clear", 1)
        room:setPlayerMark(player, "dmzhanmeng-Clear", player:getMark("dmzhanmeng-Clear")+1)

        local choicelog = sgs.LogMessage()
        choicelog.type = "$dmzhanmengchoice"
        choicelog.from = player
        choicelog.arg = choice.."dmzhanmeng"
        room:sendLog(choicelog)

        if choice == "recover" then
            room:setPlayerMark(player, "&dmzhanmeng+3_num+-Clear", 1)
            room:setPlayerFlag(player, "dmzhanmenggood")
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@dmzhanmeng:"..choice.."dmzhanmeng", false, true)
            room:setPlayerFlag(player, "-dmzhanmenggood")
            if target:isWounded() then
                local recover = sgs.RecoverStruct(player, nil, 1)
                room:recover(target, recover)
            end
            if target:isChained() then
                local log = sgs.LogMessage()
                log.type = "$dmzhanmengrenew"
                log.from = target
                room:sendLog(log)

                room:setPlayerProperty(target, "chained", sgs.QVariant(false))
            end
            if not target:faceUp() then
                target:turnOver()
            end
        end

        if choice == "draw" then
            room:setPlayerMark(player, "&dmzhanmeng+1_num+-Clear", 1)
            local yes = true
            local no = true
            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(room:getDrawPile()) do
                local cc = sgs.Sanguosha:getCard(id)
                if (JudgeDamageCard(cc) and yes)then
                    get:addSubcard(cc)
                    yes = false
                elseif (not JudgeDamageCard(cc)) and no then
                    get:addSubcard(cc)
                    no = false
                end
                if yes and no then break end
            end
            player:obtainCard(get, false)
            get:deleteLater()
        end

        if choice == "discard" then
            room:setPlayerMark(player, "&dmzhanmeng+2_num+-Clear", 1)
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:canDiscard(p, "he") then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then 
                room:setPlayerMark(player, "dmzhanmeng"..choice.."-Clear", 0)
                room:setPlayerMark(player, "dmzhanmeng-Clear", player:getMark("dmzhanmeng-Clear")-1)
                local log = sgs.LogMessage()
                log.type = "$dmzhanmengnocard"
                room:sendLog(log)
                return false 
            end

            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@dmzhanmeng:"..choice.."dmzhanmeng", false, true)
            local dis = room:askForDiscard(target, self:objectName(), 2, 2, false, true)
            local can = false
            if dis:subcardsLength() == 1 then can = true end
            if dis:subcardsLength() == 2 then
                local first = 100
                for _,id in sgs.qlist(dis:getSubcards()) do
                    local cc = sgs.Sanguosha:getCard(id)
                    local num = cc:getNumber()
                    if first == 100 then first = num
                    elseif first ~= num then can = true end
                end
            end
            if can then
                local damage = sgs.DamageStruct(nil, player, target, 1, sgs.DamageStruct_Fire)
                room:damage(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("dmzhanmeng-Clear") < 3
    end,
}

dmshenyou = sgs.CreateTriggerSkill{
    name = "dmshenyou",
    events = {sgs.AskForPeachesDone, sgs.PreHpLost, sgs.PreHpRecover, sgs.DamageForseen, sgs.HpChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.AskForPeachesDone then
            if player:getHp() > 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local log1 = sgs.LogMessage()
            log1.type = "$dmshenyouhp"
            log1.from = player
            room:sendLog(log1)

            room:setPlayerProperty(player, "hp", sgs.QVariant(1))
            room:setPlayerMark(player, "&dmshenyou", 1)
            room:setPlayerMark(player, "dmshenyoucount", 1)

            local log2 = sgs.LogMessage()
            log2.type = "$dmshenyoustart"
            log2.from = player
            room:sendLog(log2)
        end

        if event == sgs.PreHpLost or event == sgs.PreHpRecover or sgs.DamageForseen then
            if player:getMark("&dmshenyou") == 0 then return false end
            local can = false
            local log = sgs.LogMessage()
            log.type = "$dmshenyoucompulosry"
            log.from = player
            if event == sgs.PreHpLost then
                log.arg = "dmshenyouhplost"
                can = true
            elseif event == sgs.PreHpRecover then
                log.arg = "dmshenyouhprecover"
                can = true
            elseif event == sgs.DamageForseen then
                log.arg = "dmshenyoudamage"
                can = true
            end
            log.arg2 = "dmshenyou"
            if can then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:sendLog(log)
                return true
            end
        end
        if event == sgs.HpChanged then
            if player:getMark("&dmshenyou") == 0 then return false end
            if player:getHp() == 1 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            local log1 = sgs.LogMessage()
            log1.type = "$dmshenyouhp"
            log1.from = player
            room:sendLog(log1)

            room:setPlayerProperty(player, "hp", sgs.QVariant(1))
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

dmshenyouother = sgs.CreateTriggerSkill{
    name = "#dmshenyouother",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("dmshenyoucount") == 1 then
                room:sendCompulsoryTriggerLog(p, "dmshenyou", true, true)
                room:setPlayerMark(p, "dmshenyoucount", 2)
                local log = sgs.LogMessage()
                log.type = "$dmshenyougainturn"
                log.arg = p:getGeneralName()
                log.arg2 = "dmshenyou"
                room:sendLog(log)

                p:gainAnExtraTurn()
            elseif p:getMark("dmshenyoucount") == 2 then
                room:sendCompulsoryTriggerLog(p, "dmshenyou", true, true)
                local log = sgs.LogMessage()
                log.type = "$dmshenyoudie"
                log.from = p
                room:sendLog(log)
                room:killPlayer(p)
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_NotActive
    end,
}

dmzhouxuan:addSkill(dmwumei)
dmzhouxuan:addSkill(dmwumeibuff)
dmzhouxuan:addSkill(dmzhanmeng)
dmzhouxuan:addSkill(dmshenyou)
dmzhouxuan:addSkill(dmshenyouother)
extension:insertRelatedSkills("dmwumei","#dmwumeibuff")
extension:insertRelatedSkills("dmshenyou","#dmshenyouother")

godliubei = sgs.General(extension, "godliubei", "god", 6, true, false, false)

godlongnu = sgs.CreateViewAsSkill
{
    name = "godlongnu",
    n = 1,
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, selected, to_select)
        if #selected >= 1 then return false end
        if not sgs.Self:getHandcards():contains(to_select) then return false end

        local slash = nil
        if to_select:isRed() then 
            slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        elseif to_select:isBlack() then
            slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        end
        slash:addSubcard(to_select)
        slash:setSkillName(self:objectName())
        if not slash:isAvailable(sgs.Self) then slash:deleteLater() return false end
        slash:deleteLater()

        if sgs.Self:getMark("&godlongnuall-PlayClear") > 0 then return to_select:isRed() or to_select:isBlack() end
        if sgs.Self:getMark("&godlongnu+:+fire_slash-PlayClear") > 0 then return to_select:isRed() end
        if sgs.Self:getMark("&godlongnu+:+thunder_slash-PlayClear") > 0 then return to_select:isBlack() end
        return false 
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = nil
        if cards[1]:isRed() then 
            card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        elseif cards[1]:isBlack() then
            card = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        end
        card:addSubcard(cards[1])
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getPhase() ~= sgs.Player_Play then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
		return pattern == "slash"
    end
}

godlongnustart = sgs.CreateTriggerSkill{
    name = "#godlongnustart",
    events = {sgs.EventPhaseStart, sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            room:sendCompulsoryTriggerLog(player, "godlongnu")
            room:broadcastSkillInvoke("godlongnu")
            local choices = {"red", "black", "all"}
            local choice = room:askForChoice(player, "godlongnu", table.concat(choices, "+"))
            
            if choice == "red" or choice == "all" then
                room:loseHp(player, 1)
                player:drawCards(2)
                if choice ~= "all" then
                    room:setPlayerMark(player, "&godlongnu+:+fire_slash-PlayClear", 1)
                end
            end

            if choice == "black" or choice == "all" then
                room:loseMaxHp(player, 1)
                player:drawCards(2)
                if choice ~= "all" then
                    room:setPlayerMark(player, "&godlongnu+:+thunder_slash-PlayClear", 1)
                end
            end

            if choice == "all" then
                room:setPlayerMark(player, "&godlongnuall-PlayClear", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("godlongnu") and target:getPhase() == sgs.Player_Play
    end,
}

godlongnubuff = sgs.CreateTargetModSkill{
    name = "#godlongnubuff",
    residue_func = function(self, from, card)
        if card:objectName() ~= "slash" and from:hasSkill("godlongnu") then
            if not from:hasUsed(card:getClassName()) then return 1000 end
        end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:objectName() ~= "slash" and from:hasSkill("godlongnu") then
            return 1000 
        end
        return 0
    end,
}

godlongnukill = sgs.CreateTriggerSkill{
    name = "#godlongnukill",
    events = {sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("godlongnutrigger") > 0 then return false end
            if death.damage and death.damage.from and death.damage.from:getMark("&godlongnuall-PlayClear") > 0 then
                room:sendCompulsoryTriggerLog(death.damage.from, "godlongnu")
                room:broadcastSkillInvoke("godlongnu")
                room:gainMaxHp(death.damage.from, 2)
                room:recover(death.damage.from, sgs.RecoverStruct(death.damage.from, nil, 1))
            end
            room:setPlayerMark(death.who, "godlongnutrigger", 1)
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

godjieyin = sgs.CreateTriggerSkill{
    name = "godjieyin",
    events = {sgs.GameStart,sgs.EventAcquireSkill, sgs.ChainStateChange, sgs.DamageForseen, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            if player:isChained() then return false end
            if event == sgs.EventAcquireSkill then
                if data:toString() ~= self:objectName() then return false end
            end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:setPlayerChained(player)
        end

        if event == sgs.ChainStateChange then
            if not player:isChained() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            return true
        end

        if event == sgs.DamageForseen then
            local damage = data:toDamage()
            if not damage.chain then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local log = sgs.LogMessage()
            log.type = "$godjieyinforseen"
            log.from = player
            log.arg = self:objectName()
            room:sendLog(log)
            return true
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isChained() then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@godjieyin", false, true)
            room:setPlayerChained(target)
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

godliubei:addSkill(godlongnustart)
godliubei:addSkill(godlongnu)
godliubei:addSkill(godlongnubuff)
godliubei:addSkill(godlongnukill)
godliubei:addSkill(godjieyin)
extension:insertRelatedSkills("godlongnu", "#godlongnubuff")
extension:insertRelatedSkills("godlongnu", "#godlongnukill")
extension:insertRelatedSkills("godlongnu", "#godlongnustart")

xiaolvbu = sgs.General(extension, "xiaolvbu", "qun", 5, true, false, false)

xiaorenfu = sgs.CreateTriggerSkill{
    name = "xiaorenfu",
    events = {sgs.RoundStart, sgs.DamageCaused, sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            local old_yifu = nil
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("xiaoyifufrom"..player:objectName()) > 0 then
                    old_yifu = p
                    break
                end
            end
            local new_yifu = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@xiaorenfu", false, true)
            room:broadcastSkillInvoke(self:objectName(), math.random(1,2))

            if old_yifu and old_yifu:isAlive() then
                room:setPlayerMark(old_yifu, "xiaoyifufrom"..player:objectName(), 0)
                room:setPlayerMark(old_yifu, "&xiaoyifu", old_yifu:getMark("&xiaoyifu")-1)
                if old_yifu:objectName() ~= new_yifu:objectName() then
                    local log = sgs.LogMessage()
                    log.type = "$xiaoyifuchangefrom"
                    log.from = player
                    log.arg = old_yifu:getGeneralName()
                    room:sendLog(log)
                end
            end
            
            room:setPlayerMark(new_yifu, "xiaoyifufrom"..player:objectName(), 1)
            room:setPlayerMark(new_yifu, "&xiaoyifu", new_yifu:getMark("&xiaoyifu")+1)

            if (old_yifu and old_yifu:objectName() ~= new_yifu:objectName()) or (not old_yifu) then
                local log = sgs.LogMessage()
                log.type = "$xiaoyifuchangeto"
                log.from = player
                log.arg = new_yifu:getGeneralName()
                room:sendLog(log)
            end

            if not new_yifu:isNude() then
                local card = room:askForCardChosen(player, new_yifu, "he", self:objectName())
                room:obtainCard(player, card, false)
            end
                
            if old_yifu and old_yifu:isAlive() and old_yifu:objectName() ~= new_yifu:objectName() then
                local prompt = string.format("damage:%s:",old_yifu:getGeneralName())
                room:setPlayerFlag(old_yifu, "old_yifuta")

                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName(), 3)
                    local damage = sgs.DamageStruct(nil, player, old_yifu, 1, sgs.DamageStruct_Normal)
                    room:damage(damage)
                end

                room:setPlayerFlag(old_yifu, "-old_yifuta")
            end
        end

        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.to:getMark("xiaoyifufrom"..player:objectName()) > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 3)
                local log = sgs.LogMessage()
                log.type = "$xiaorenfudamageup"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = damage.to:getGeneralName()
                log.arg3 = damage.damage 
                log.arg4 = damage.damage + 1
                room:sendLog(log)
                
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end

        if event == sgs.Damage then
            local damage = data:toDamage()
            local yifu = nil
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("xiaoyifufrom"..player:objectName()) > 0 then
                    yifu = p
                    break
                end
            end
            if (not yifu) or (yifu:isNude()) or (damage.to:objectName() == yifu:objectName()) then return false end
            if damage.to:objectName() == player:objectName() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true, (math.random(1,2)+3))
            local give = room:askForExchange(yifu, self:objectName(), 1, 1, true, "xiaoyifugive:"..player:getGeneralName(), false)
            room:obtainCard(player, give, false)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

xiaorenfudistance = sgs.CreateDistanceSkill{
    name = "#xiaorenfudistance",
    correct_func = function(self, from, to)
        if from:hasSkill("xiaorenfu") and to:getMark("xiaoyifufrom"..from:objectName()) > 0 then
            return -1000
        end
        return 0
    end,
}

xiaoyifubuff = sgs.CreateTriggerSkill{
    name = "#xiaoyifubuff",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasSkill("xiaorenfu") and player:getMark("xiaoyifufrom"..p:objectName()) > 0 then
                local targets = sgs.SPlayerList()
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                slash:setSkillName("_xiaoyizi")
                --room:setCardFlag(slash, "YUANBEN")
                for _,t in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:canUse(slash, t, true) then
                        targets:append(t)
                    end
                end
                if targets:length() > 0 then

                    room:setPlayerFlag(player, "xiaoyifu")
                    local target = room:askForPlayerChosen(player, targets, "xiaorenfu", "xiaoyifuslash:"..p:getGeneralName(), true, true)
                    room:setPlayerFlag(player, "-xiaoyifu")

                    if target then
                        room:broadcastSkillInvoke("xiaorenfu", (math.random(1,2)+5))
                        room:useCard(sgs.CardUseStruct(slash, p, target, false))
                    else
                        slash:deleteLater()
                    end
                else
                    slash:deleteLater()
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Play and target:getMark("&xiaoyifu") > 0
    end,
}

xiaoyifuslash = sgs.CreateTargetModSkill{
    name = "#xiaoyifuslash",
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "xiaoyizi" then return 1000 end
        return 0
    end,
}

xiaosheji = sgs.CreateTriggerSkill{
    name = "xiaosheji",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if not damage.from then return false end
        if not player:isAlive() then return false end
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasSkill(self:objectName()) and p:getMark("xiaoshejiused-Clear") == 0 and p:objectName() ~= damage.from:objectName() then
                local prompt = string.format("slash:%s::%s:",damage.from:getGeneralName(),damage.to:getGeneralName())
                
                room:setPlayerFlag(damage.from, "shejifrom")
                room:setPlayerFlag(damage.to, "shejito")

                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then
                    room:setPlayerMark(p, "xiaoshejiused-Clear", 1)
                    room:setPlayerMark(p, "&xiaosheji+used-Clear", 1)
                    if not damage.from:isNude() then
                        local dis = room:askForCardChosen(p, damage.from, "he", self:objectName())
                        room:throwCard(dis, damage.from, p)
                    end
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                    slash:setSkillName(self:objectName())
                    room:useCard(sgs.CardUseStruct(slash, p, damage.from))
                    if damage.from:hasFlag("shejisuccess") then
                        room:setPlayerFlag(damage.from, "-shejisuccess")
                        room:setPlayerMark(player, "&xiaosheji+to-Clear", 1)
                        room:setPlayerMark(damage.from, "&xiaosheji-Clear", 1)
                        room:setPlayerMark(player, "xiaoshejifrom"..damage.from:objectName().."-Clear", 1)
                    end
                end

                room:setPlayerFlag(damage.from, "-shejifrom")
                room:setPlayerFlag(damage.to, "-shejito")
            end
        end
        if damage.card and damage.card:getSkillName() == self:objectName() then
            room:setPlayerFlag(player, "shejisuccess")
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

xiaoshejisave = sgs.CreateProhibitSkill{
    name = "#xiaoshejisave",
    is_prohibited = function(self, from, to, card)
        return to:getMark("xiaoshejifrom"..from:objectName().."-Clear") > 0
    end,
}

xiaolvbu:addSkill(xiaorenfu)
xiaolvbu:addSkill(xiaorenfudistance)
xiaolvbu:addSkill(xiaoyifuslash)
xiaolvbu:addSkill(xiaoyifubuff)
xiaolvbu:addSkill(xiaosheji)
xiaolvbu:addSkill(xiaoshejisave)
extension:insertRelatedSkills("xiaorenfu", "#xiaorenfudistance")
extension:insertRelatedSkills("xiaorenfu", "#xiaoyifuslash")
extension:insertRelatedSkills("xiaorenfu", "#xiaoyifubuff")
extension:insertRelatedSkills("xiaosheji", "#xiaoshejisave")

doubleO = sgs.General(extension, "doubleO", "qun", 4, true, false, false)

doubleneifa = sgs.CreateTriggerSkill{
    name = "doubleneifa",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local targets = sgs.SPlayerList()
        local cancancel = true
        local prompt
        if player:hasSkill(self:objectName()) then
            cancancel = false
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if not p:isAllNude() then
                    targets:append(p)
                end
            end
            prompt = "doubleneifamust"
        elseif player:getMark("&doubleneifa") > 0 then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if (not p:isAllNude()) and ((p:getMark("&doubleneifa") > 0) or p:hasSkill(self:objectName())) then
                    targets:append(p)
                end
            end
            prompt = "doubleneifacan"
        end
        if targets:length() == 0 then return false end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, cancancel, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(target, "&doubleneifa", 1)
            local card = room:askForCardChosen(player, target, "hej", self:objectName())
            room:throwCard(card, nil, player)
            player:drawCards(2)
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Start and (target:hasSkill(self:objectName()) or target:getMark("&doubleneifa") > 0)
    end,
}

doubleO:addSkill(doubleneifa)

wwcaocao = sgs.General(extension, "wwcaocao", "god", 7, true, false, false, 3)

wwxionglve = sgs.CreateTriggerSkill{
    name = "wwxionglve",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = player:getMark("wwxionglve")
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        if n >= 5 then 
            room:loseMaxHp(player, 1) 
            return false 
        end
        n = 5 - n
        local allnames = sgs.Sanguosha:getLimitedGeneralNames()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            local name = p:getGeneralName()
            allnames[name] = nil
        end
        local all = #allnames
        local targets = {}
        local a = 1000
        while(n > 0) do
            local selected = allnames[math.random(1,all)]
            local target = sgs.Sanguosha:getGeneral(selected)
            if target:getKingdom() == "wei" and (not table.contains(targets, selected)) then 
                table.insert(targets, selected)
                n = n - 1
            end
            a = a - 1
            if a <= 0 then break end
        end
        local skillnames = {}
        for _,selected in ipairs(targets) do
            local target = sgs.Sanguosha:getGeneral(selected)
            local skills = target:getVisibleSkillList()
            for _,s in sgs.qlist(skills) do
                local skillname = s:objectName()
                if not player:hasSkill(skillname) then
                    table.insert(skillnames,skillname)
                end
            end
        end
        local to_select = {}
        local max = #targets
        for i = 1, max, 1 do
            local ran = math.random(1, #skillnames)
            table.insert(to_select, skillnames[ran])
            table.removeOne(skillnames, skillnames[ran])
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(to_select, "+"))
        room:setPlayerMark(player, "wwxionglve", player:getMark("wwxionglve")+1)
        room:acquireSkill(player, choice)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

wwguixin = sgs.CreateTriggerSkill{
    name = "wwguixin",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.card_ids:length() < 2 then return false end
        if move.to and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
            local owner 
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:objectName() == move.to:objectName() then owner = p break end
            end
            if not owner then return false end
            local card_ids = sgs.IntList()
            for _,id in sgs.qlist(move.card_ids) do
                if id and room:getCardOwner(id) and room:getCardOwner(id):objectName() == owner:objectName() then
                    card_ids:append(id)
                end
            end
            if card_ids:length() < 2 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:fillAG(card_ids, owner)
            local give = room:askForAG(owner, card_ids, false, self:objectName(), "wwguixingive:"..player:getGeneralName())
            room:clearAG(owner)
            room:obtainCard(player, sgs.Sanguosha:getCard(give), false)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

wwcaocao:addSkill(wwxionglve)
wwcaocao:addSkill(wwguixin)

jfwolong = sgs.General(extension, "jfwolong", "god", 3, true, false, false)

jfjifeng = sgs.CreateViewAsSkill
{
    name = "jfjifeng",
    response_pattern = "@@jfjifeng",
    n = 1,
    expand_pile = "#jfjifeng",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("fireattackused") then
            if sgs.Self:getEquips():contains(to_select) then return false end
            local suit = to_select:getSuitString()
            local need = sgs.Self:property("jfjifengsuit"):toString()
            if suit ~= need then return false end
            return #selected < 1 
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("fireattackused") then
            if #cards == 0 then return nil end
            local cc = jfjifengCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
        local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
        fire_attack:setSkillName(self:objectName())
        return fire_attack
    end,
    enabled_at_play = function(self, player)
        local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
        fire_attack:setSkillName(self:objectName())
        if not fire_attack:isAvailable(player) then 
            fire_attack:deleteLater()
            return false 
        end
        fire_attack:deleteLater()
        return player:getMark("jfjifengfailed-PlayClear") == 0
    end,
}

jfjifengCard = sgs.CreateSkillCard
{
    name = "jfjifengdis",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        return false
    end,
}

jfjifengbuff = sgs.CreateTriggerSkill{
    name = "#jfjifengbuff",
    events = {sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardEffected then
			local effect = data:toCardEffect()
            local can_invoke = false
			if effect.card:objectName() == "fire_attack" then		
				if effect.from and effect.from:isAlive() and effect.from:hasSkill("jfjifeng") then
					can_invoke = true
				end
				if (not effect.to) or (not effect.to:isAlive()) or (effect.to:getHandcardNum() == 0) then
                    can_invoke = false
                end
                if effect.nullified then
                    can_invoke = false
                end
			end
			if not can_invoke then return false end
			if effect.card:objectName() == "fire_attack" then	
				if room:isCanceled(effect) then
                    effect.to:setFlags("Global_NonSkillNullify")
                    return true
                end
                local card = room:askForCardShow(effect.to, effect.from, "fire_attack")
                room:showCard(effect.to, card:getEffectiveId())
                room:setPlayerProperty(effect.from, "jfjifengsuit", sgs.QVariant(card:getSuitString()))
                
                local card_ids = room:getNCards(4)
                room:returnToTopDrawPile(card_ids)

                local tag = sgs.QVariant()
                tag:setValue(card_ids)
                effect.from:setTag("jfjifengai", tag)--ai

                room:setPlayerFlag(effect.from, "fireattackused")
                room:notifyMoveToPile(effect.from, card_ids, "jfjifeng", sgs.Player_DrawPile, true)
                local throw = room:askForUseCard(effect.from, "@@jfjifeng", "@jfjifeng:"..card:getSuitString().."::"..effect.to:getGeneralName())
                room:notifyMoveToPile(effect.from, card_ids, "jfjifeng", sgs.Player_DrawPile, false)
                room:setPlayerFlag(effect.from, "-fireattackused")

                if throw then
                    local ids = throw:getSubcards()
                    local place = room:getCardPlace(ids:first())
                    local moves = sgs.CardsMoveList()
                    local move = sgs.CardsMoveStruct(ids, effect.from, nil, place, sgs.Player_DiscardPile,
                                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.from:objectName(), nil, "fire_attack"))
                    moves:append(move)
                    
                    if (not moves:isEmpty()) then
                        room:moveCardsAtomic(moves, true)
                    end

                    local log = sgs.LogMessage()
                    log.type = "$jfjifengdiscard"
                    log.from = effect.from
                    log.card_str = sgs.Sanguosha:getCard(ids:first()):toString()
                    if place == sgs.Player_PlaceHand then
                        log.arg = "jfhand"
                    else
                        log.arg = "jfdrawpile"
                    end
                    room:sendLog(log)

                    if effect.card:getSkillName() ~= "jfjifeng" then
                        room:broadcastSkillInvoke("jfjifeng")
                    end

                    local damage = sgs.DamageStruct(effect.card, effect.from, effect.to, 1, sgs.DamageStruct_Fire)
                    room:damage(damage)
                end
				room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
			end
		end  
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

jfjifengdamage = sgs.CreateTriggerSkill{
    name = "#jfjifengdamage",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire then
            room:broadcastSkillInvoke("jfjifeng")
            local log = sgs.LogMessage()
            log.type = "$jfjifengdamage"
            log.from = player
            log.arg = "jfjifeng"
            log.arg2 = damage.damage
            log.arg3 = damage.damage + player:getMark("&jfjifeng")
            room:sendLog(log)

            damage.damage = damage.damage + player:getMark("&jfjifeng")
            room:setPlayerMark(player, "&jfjifeng", 0)
            data:setValue(damage)
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&jfjifeng") > 0
    end,
}

jfjifengfailed = sgs.CreateTriggerSkill{
    name = "#jfjifengfailed",
    events = {sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == "jfjifeng" then
                room:setCardFlag(damage.card, "jfjifengsuccess")
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.from:objectName() == player:objectName() and use.card:getSkillName() == "jfjifeng" and (not use.card:hasFlag("jfjifengsuccess")) then
                --room:broadcastSkillInvoke("jfjifeng")
                room:setPlayerMark(player, "jfjifengfailed-PlayClear", 1)
                room:setPlayerMark(player, "&jfjifeng+fail+-PlayClear", 1)
                for _,p in sgs.qlist(use.to) do
                    room:setPlayerMark(p, "&jfjifeng", p:getMark("&jfjifeng")+1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("jfjifeng")
    end,
}

jfyueyin = sgs.CreateTriggerSkill{
    name = "jfyueyin",
    events = {sgs.DamageInflicted,sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom() 
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local card = use.card
            if card:isKindOf("SkillCard") then return false end
            local ctype = getTypeString(card)
            if use.to:contains(player) then
                room:setPlayerMark(player, "jfyueyin"..ctype.."-Clear", player:getMark("jfyueyin"..ctype.."-Clear")+1)
                if player:getMark("jfyueyin"..ctype.."-Clear") > 1 and card:isKindOf("TrickCard") then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    player:drawCards(1)
                end
                if player:getMark("jfyueyin"..ctype.."-Clear") > 1 then
                    room:setPlayerMark(player, "&jfyueyin+"..ctype.."+-Clear", 1)
                end
            end
        end 
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local can_invoke = false
            if (not damage.card) or (damage.card and damage.card:isKindOf("SkillCard")) then can_invoke = true end
            if damage.card and (not damage.card:isKindOf("SkillCard")) then
                local ctype = getTypeString(damage.card)
                if player:getMark("jfyueyin"..ctype.."-Clear") > 1 then
                    can_invoke = true
                end
            end
            if can_invoke then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local log = sgs.LogMessage()
                log.type = "$jfyueyinforseen"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = damage.damage
                room:sendLog(log)
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jfqixing = sgs.CreateTriggerSkill{
    name = "jfqixing",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() then return false end
        local targets = {}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            table.insert(targets, p)
        end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        local ta = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@jfqixing", true, true)
        if ta then
            local log = sgs.LogMessage()
            log.type = "$jfqixingelse"
            log.arg = ta:getGeneralName()
            log.arg2 = self:objectName()
            room:sendLog(log)
            table.removeOne(targets, ta)
        end
        if #targets == 0 then return false end
        local n = 200
        local all = #targets
        for i = 1, 7, 1 do
            local now = {}
            for _,p in ipairs(targets) do
                if p:getHp() > 1 then
                    table.insert(now, p)
                end
            end
            if #now == 0 then break end
            local target = now[math.random(1, #now)]
            local log = sgs.LogMessage()
            log.type = "$jfqixingdamage"
            log.from = target
            log.arg = self:objectName()
            log.arg2 =  i
            room:sendLog(log)
            local damage = sgs.DamageStruct(nil, nil, target, 1, sgs.DamageStruct_Thunder)
            room:damage(damage)
            room:getThread():delay(800)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

jfwolong:addSkill(jfjifeng)
jfwolong:addSkill(jfjifengbuff)
jfwolong:addSkill(jfjifengdamage)
jfwolong:addSkill(jfjifengfailed)
jfwolong:addSkill(jfyueyin)
jfwolong:addSkill(jfqixing)
extension:insertRelatedSkills("jfjifeng", "#jfjifengbuff")
extension:insertRelatedSkills("jfjifeng", "#jfjifengdamage")
extension:insertRelatedSkills("jfjifeng", "#jfjifengfailed")

xrcaocun = sgs.General(extension, "xrcaocun", "wei", 4, true, false, false)

xrxiaoruiVS = sgs.CreateViewAsSkill
{
    name = "xrxiaorui",
    n = 1,
    expand_pile = "#xrxiaorui",
    response_pattern = "@@xrxiaorui",
    view_filter = function(self, selected, to_select)
        local target = nil
        for _,p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if p:hasFlag("xrxiaoruitarget") then
                target = p
                break
            end
        end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("xrxiaorui")

        if sgs.Self:isProhibited(target, slash) then
            slash:deleteLater()
            return false
        end
        slash:deleteLater()

        return sgs.Self:getPile("#xrxiaorui"):contains(to_select:getId()) and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = xrxiaoruiCard:clone()
        card:addSubcard(cards[1])
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

xrxiaoruiCard = sgs.CreateSkillCard
{
    name = "xrxiaorui",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        return false
    end
}

xrxiaorui = sgs.CreateTriggerSkill{
    name = "xrxiaorui",
    events = {sgs.Damage, sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = xrxiaoruiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not player:isAlive() then return false end
        local damage = data:toDamage()
        local target = nil
        if event == sgs.Damage then
            if damage.to and damage.to:objectName() ~= player:objectName() then
                target = damage.to
            end
        end
        if event == sgs.Damaged then
            if damage.from and damage.from:objectName() ~= player:objectName() then
                target = damage.from
            end
        end
        if not target then return false end

        if target:getHandcardNum() == 0 then return false end
        room:setPlayerFlag(target, "xrxiaoruitarget")
        local prompt = string.format("view:%s:",target:getGeneralName())
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then 
            room:setPlayerFlag(target, "-xrxiaoruitarget")
            return false 
        end
        room:broadcastSkillInvoke(self:objectName())
        room:setPlayerMark(player, "xrxiaorui-Clear", 1)
        room:setPlayerMark(player, "&xrxiaorui+-Clear", 1)

        local view_cards = sgs.IntList()
        local ids = {}
        for _,card in sgs.qlist(target:getHandcards()) do
            local id = card:getEffectiveId()
            view_cards:append(id)
            table.insert(ids, id)
        end

        local log1 = sgs.LogMessage()
        log1.type = "$XrxiaoruiViewAllCards"
        log1.from = player
        log1.arg = target:getGeneralName()
        room:sendLog(log1)

        local log2 = sgs.LogMessage()
        log2.type = "$XrxiaoruiViewAllCardsself"
        log2.arg = target:getGeneralName()
        log2.card_str = table.concat(ids, "+")
        room:sendLog(log2, player)

        room:notifyMoveToPile(player, view_cards, "xrxiaorui", sgs.Player_PlaceHand, true)
        local card = room:askForUseCard(player, "@@xrxiaorui", "@xrxiaorui:"..target:getGeneralName())
        room:notifyMoveToPile(player, view_cards, "xrxiaorui", sgs.Player_PlaceHand, false)
        room:setPlayerFlag(target, "-xrxiaoruitarget")
        if card then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("_xrxiaorui")

            local id = card:getSubcards():first()
            for _,card in sgs.qlist(target:getHandcards()) do
                if card:getId() == id then
                    slash:addSubcard(card)
                    break
                end
            end
            room:setCardFlag(slash, "RemoveFromHistory")
            local use = sgs.CardUseStruct(slash, player, target)
            room:useCard(use)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("xrxiaorui-Clear") == 0
    end,
}

xrshanjiaVS = sgs.CreateZeroCardViewAsSkill
{
    name = "xrshanjia",
    response_pattern = "@@xrshanjia",
    enabled_at_play = function(self, player)
        return false 
    end,
    view_as = function(self)
        return xrshanjiaCard:clone()
    end,
}

xrshanjiaCard = sgs.CreateSkillCard
{
    name = "xrshanjia",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("xrshanjia")
        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("xrshanjia")
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

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("_xrshanjia")
        slash:deleteLater()
        room:setCardFlag(slash, "RemoveFromHistory")
        return slash
    end,
}

xrshanjia = sgs.CreateTriggerSkill{
    name = "xrshanjia",
    events = {sgs.EventPhaseStart, sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = xrshanjiaVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("use")) then return false end
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1)

            local can = true
            local m = -1
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("EquipCard") then
                    local n = -1
                    if card:isKindOf("Weapon") then
                        n = 0
                    elseif card:isKindOf("Armor") then
                        n = 1
                    elseif card:isKindOf("DefensiveHorse") then
                        n = 2
                    elseif card:isKindOf("OffensiveHorse") then
                        n = 3
                    elseif card:isKindOf("Treasure") then
                        n = 4
                    end
                    if player:canUse(card, player, true) and (not player:getEquip(n)) then
                        can = false
                        local use = sgs.CardUseStruct(card, player, player)
                        room:useCard(use)
                        break
                    end
                end
            end
            if not can then return false end
            local log = sgs.LogMessage()
            log.type = "$xrshanjianot"
            log.from = player
            room:sendLog(log)
            
        end

        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from:objectName() ~= player:objectName() then return false end
            if not use.card:isKindOf("EquipCard") then return false end
            local n = math.max(0,2-player:getEquips():length())
            local prompt = string.format("draw:%s:", n)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(2)
                local can = true
                if n > 0 then
                    local dis = room:askForDiscard(player, self:objectName(), n, n, false, true)
                    for _,id in sgs.qlist(dis:getSubcards()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isKindOf("BasicCard") then
                            can = false
                        end
                    end
                end
                if can then
                    room:askForUseCard(player, "@@xrshanjia", "@xrshanjia")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

xrshanjiabuff = sgs.CreateTargetModSkill{
    name = "#xrshanjiabuff",
    residue_func = function(self, from, card)
        if card:getSkillName() == "xrshanjia" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "xrshanjia" then return 1000 end
        return 0
    end,
}

xrcaocun:addSkill(xrxiaorui)
xrcaocun:addSkill(xrxiaoruiVS)
xrcaocun:addSkill(xrshanjia)
xrcaocun:addSkill(xrshanjiaVS)
xrcaocun:addSkill(xrshanjiabuff)
extension:insertRelatedSkills("xrshanjia", "#xrshanjiabuff")

cqmachao = sgs.General(extension, "cqmachao", "shu", 4, true, false, false)

cqtieji = sgs.CreateTriggerSkill{
    name = "cqtieji",
    events = {sgs.TargetConfirmed, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
                local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		        local index = 1
                for _, p in sgs.qlist(use.to) do
                    local _data = sgs.QVariant()
                    _data:setValue(p)
                    if player:askForSkillInvoke(self:objectName(), _data) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(p, "@skill_invalidity")
                        room:addPlayerMark(p, "cqtieji")
                        jink_table[index] = 0
                        if p:inMyAttackRange(player) and player:inMyAttackRange(p) then
                            local log = sgs.LogMessage()
                            log.type = "$cqmachaospecial"
                            log.arg = self:objectName()
                            log.arg2 = "cqtiejiboji"
                            room:sendLog(log)
                            room:getThread():delay(300)

                            for i = 1, 2, 1 do
                                if (not p:isNude()) and player:isAlive() and p:isAlive() then
                                    local card = room:askForCardChosen(player, p, "he", self:objectName())
                                    room:obtainCard(player, card, false)
                                end
                            end
                        end
                    end
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
		        jink_data:setValue(Table2IntList(jink_table))
		        player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        end

        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName() and damage.to:isAlive() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(damage.to, "&cqtieji+:+"..player:getGeneralName(), damage.to:getMark("&cqtieji+:+"..player:getGeneralName())+1)
                room:setPlayerMark(damage.to, "cqtiejifrom"..player:objectName(), damage.to:getMark("cqtiejifrom"..player:objectName())+1)
            
                local log = sgs.LogMessage()
                log.type = "$cqtiejidistance"
                log.arg = damage.to:getGeneralName()
                log.arg2 = player:getGeneralName()
                log.arg3 = self:objectName()
                log.arg4 = damage.to:getMark("cqtiejifrom"..player:objectName())
                room:sendLog(log)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

cqtiejiclear = sgs.CreateTriggerSkill{
    name = "#cqtiejiclear",
    events = {sgs.TurnStart, sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then return false end
        end

        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("cqtiejifrom"..player:objectName()) > 0 then
                room:setPlayerMark(p, "&cqtieji+:+"..player:getGeneralName(), 0)
                room:setPlayerMark(p, "cqtiejifrom"..player:objectName(), 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("cqtieji", true) 
    end,
}

cqtiejibuff = sgs.CreateDistanceSkill{
    name = "#cqtiejibuff",
    correct_func = function(self, from, to)
        if from:getMark("cqtiejifrom"..to:objectName()) > 0 then
            return from:getMark("cqtiejifrom"..to:objectName())
        end
        return 0
    end,
}

cqtiejiclears = sgs.CreateTriggerSkill{
    name = "#cqtiejiclears",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("cqtieji") > 0 then
                room:setPlayerMark(p, "@skill_invalidity", p:getMark("@skill_invalidity")-p:getMark("cqtieji"))
                room:setPlayerMark(p, "cqtieji", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_NotActive
    end,
}

cqchangqu = sgs.CreateTriggerSkill{
    name = "cqchangqu",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = 2
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if not p:inMyAttackRange(player) then
                n = n + 1
            end
        end
        local youji = false
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "cqchangqu", "@cqchangqu:"..n, true, true)
        if not target then return false end
        room:broadcastSkillInvoke(self:objectName())
        local card_ids = room:getNCards(n)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(),"")
        local move = sgs.CardsMoveStruct(card_ids, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable, reason)
        room:moveCardsAtomic(move,true)

        if player:inMyAttackRange(target) and (not target:inMyAttackRange(player)) then
            local log = sgs.LogMessage()
            log.type = "$cqmachaospecial"
            log.arg = self:objectName()
            log.arg2 = "cqchangquyouji"
            room:sendLog(log)

            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                if (card:isKindOf("BasicCard") and (not card:isKindOf("Slash")))
                or card:isKindOf("TrickCard") then
                    get:addSubcard(card)
                end
            end
            if get:subcardsLength() > 0 then
                room:obtainCard(player, get, true)
                for _,id in sgs.qlist(get:getSubcards()) do
                    card_ids:removeOne(id)
                end
            end
            get:deleteLater()
        end

        local new_cards = sgs.IntList()
        for _,id in sgs.qlist(card_ids) do
            new_cards:append(id)
        end
        
        for _,id in sgs.qlist(card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf("Slash") and (not player:isProhibited(target, card)) and player:isAlive() and target:isAlive() then
                room:getThread():delay(800)
                new_cards:removeOne(id)
                room:useCard(sgs.CardUseStruct(card, player, target))
            end
        end

        if new_cards:length() > 0 then
            local names = sgs.QList2Table(new_cards)
            local log = sgs.LogMessage()
            log.type = "$MoveToDiscardPile"
            log.from = player
            log.card_str = table.concat(names, "+")
            room:sendLog(log)
            local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(),"")
            local move1 = sgs.CardsMoveStruct(new_cards, nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, reason1)
            room:moveCardsAtomic(move1,true)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish
    end,
}

cqmachao:addSkill(cqtieji)
cqmachao:addSkill(cqtiejiclear)
cqmachao:addSkill(cqtiejibuff)
cqmachao:addSkill(cqtiejiclears)
cqmachao:addSkill(cqchangqu)
cqmachao:addSkill("mashu")
extension:insertRelatedSkills("cqtieji", "#cqtiejiclear")
extension:insertRelatedSkills("cqtieji", "#cqtiejibuff")
extension:insertRelatedSkills("cqtieji", "#cqtiejiclears")

yzzhonghui = sgs.General(extension, "yzzhonghui", "wei", 4, true, false, false, 3)

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

yzyuzhi = sgs.CreateTriggerSkill{
    name = "yzyuzhi",
    events = {sgs.RoundStart, sgs.Damage, sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local name_number = 0
            if player:getHandcardNum() > 0 then
                local cards = room:askForExchange(player, self:objectName(), 1, 1, false, "@yzyuzhi", false)
                local card = cards:getSubcards():first()
                card = sgs.Sanguosha:getCard(card)
                room:showCard(player, card:getEffectiveId())
                name_number = utf8len(sgs.Sanguosha:translate(card:objectName()))
                if card:isKindOf("Slash") then name_number = 1 end
            else
                local log = sgs.LogMessage()
                log.type = "$yzyuzhinotcard"
                log.from = player
                room:sendLog(log)
                return false
            end
            
            local log = sgs.LogMessage()
            log.type = "$yzyuzhicard"
            log.from = player
            log.arg = self:objectName()
            log.arg2 = name_number
            room:sendLog(log)

            room:setPlayerMark(player, "&yzyuzhi_lun", name_number)
            room:setPlayerMark(player, "yzyuzhidamage_lun", 0)
            player:drawCards(name_number*2, self:objectName())
        end

        if event == sgs.Damage then
            if player:getMark("yzyuzhidamage_lun") >= player:getMark("&yzyuzhi_lun") then return false end
            local num = data:toDamage().damage + player:getMark("yzyuzhidamage_lun")
            room:setPlayerMark(player, "yzyuzhidamage_lun", num)
            if num < player:getMark("&yzyuzhi_lun") then
                local log = sgs.LogMessage()
                log.type = "$yzyuzhineed"
                log.from = player
                log.arg = player:getMark("&yzyuzhi_lun") - num
                room:sendLog(log)
            else
                local log = sgs.LogMessage()
                log.type = "$yzyuzhicomplete"
                log.from = player
                room:sendLog(log)
            end
        end

        if event == sgs.RoundEnd then
            if player:getMark("yzyuzhidamage_lun") >= player:getMark("&yzyuzhi_lun") then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local num = player:getMark("&yzyuzhi_lun") - player:getMark("yzyuzhidamage_lun")
            
            local log = sgs.LogMessage()
            log.type = "$yzyuzhifailed"
            log.from = player
            log.arg = num
            room:sendLog(log)

            room:loseHp(player, num)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

yzxieshuVS = sgs.CreateViewAsSkill
{
    name = "yzxieshu",
    n = 9999,
    response_pattern = "@@yzxieshu",
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark("yzxieshu")
    end,
    view_as = function(self, cards)
        if #cards < sgs.Self:getMark("yzxieshu") then return nil end
        local card = yzxieshuCard:clone()
        for _,cc in ipairs(cards) do
            card:addSubcard(cc)
        end
        return card
    end,
    enabled_at_play = function(self, player)
        return false 
    end
}

yzxieshuCard = sgs.CreateSkillCard
{
    name = "yzxieshu",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local num = self:subcardsLength()
        room:setPlayerMark(effect.from, "yzxieshu"..num.."-Clear", 1)
        room:setPlayerMark(effect.from, "&yzxieshu+"..num.."_num+-Clear", 1)
        local n = effect.from:getLostHp()
        room:throwCard(self, effect.from, effect.from)
        if effect.from:isAlive() then
            effect.from:drawCards(n)
        end
        if effect.to:isAlive() then
            if effect.to:objectName() == effect.from:objectName() and effect.to:isWounded() then
                room:recover(effect.from, sgs.RecoverStruct(effect.from, nil, 1))
            else
                room:damage(sgs.DamageStruct(self, effect.from, effect.to, 1, sgs.DamageStruct_Normal))
            end
        end
    end
}

yzxieshu = sgs.CreateTriggerSkill{
    name = "yzxieshu",
    events = {sgs.Damage, sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = yzxieshuVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = data:toDamage().card

        if (not card) or card:isKindOf("SkillCard") then return false end

        local name_number = utf8len(sgs.Sanguosha:translate(card:objectName()))
        if card:isKindOf("Slash") then name_number = 1 end

        if player:getMark("yzxieshu"..name_number.."-Clear") > 0 then return false end

        room:setPlayerMark(player, "yzxieshu", name_number)
        room:askForUseCard(player, "@@yzxieshu", "@yzxieshu:"..name_number.."::"..player:getLostHp())
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

yzzhonghui:addSkill(yzyuzhi)
yzzhonghui:addSkill(yzxieshu)
yzzhonghui:addSkill(yzxieshuVS)

lghuangzhong = sgs.General(extension, "lghuangzhong", "shu", 4, true, false, false)

lgliegong = sgs.CreateTriggerSkill{
    name = "lgliegong",
    events = {sgs.TargetConfirmed, sgs.DamageCaused, sgs.CardFinished, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
                local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		        local index = 1
                for _, p in sgs.qlist(use.to) do
                    local _data = sgs.QVariant()
                    _data:setValue(p)
                    if player:askForSkillInvoke(self:objectName(), _data) then
                        room:broadcastSkillInvoke(self:objectName())
                        jink_table[index] = 0
                        if player:inMyAttackRange(p) and (not p:inMyAttackRange(player)) then
                            room:setPlayerMark(p, "&lgliegong-Clear", 1)
                            local log = sgs.LogMessage()
                            log.type = "$lgliegonglimit"
                            log.from = p
                            log.arg = self:objectName()
                            room:sendLog(log)
                        end
                        local tag = use.card:getTag("lgliegongtargets"):toString():split("+")
                        if tag then
                            table.insert(tag, p:objectName())
                            use.card:setTag("lgliegongtargets", sgs.QVariant(table.concat(tag, "+")))
                        else
                            tag = {}
                            table.insert(tag, p:objectName())
                            use.card:setTag("lgliegongtargets", sgs.QVariant(table.concat(tag, "+")))
                        end
                    end
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
		        jink_data:setValue(Table2IntList(jink_table))
		        player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        end

        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then return false end
            if damage.card and damage.card:isKindOf("Slash") then else return false end
            local tag = damage.card:getTag("lgliegongtargets"):toString():split("+")
            if not tag then return false end
            if table.contains(tag, damage.to:objectName()) then
                local n = 0
                if damage.from:getHp() <= damage.to:getHp() then n = n + 1 end
                if damage.from:getHandcardNum() <= damage.to:getHandcardNum() then n = n + 1 end
                if damage.from:getEquips():length() <= damage.to:getEquips():length() then n = n + 1 end
                if n <= 0 then return false end
                local log = sgs.LogMessage()
                log.type = "$lgliegongdamage"
                log.from = player
                log.arg = damage.to:getGeneralName()
                log.arg2 = self:objectName()
                log.arg3 = damage.damage
                log.arg4 = damage.damage + n
                room:sendLog(log)
                damage.damage = damage.damage + n
                data:setValue(damage)
            end
        end

        if event == sgs.CardFinished then
            local use = data:toCardUse()
            local tag = use.card:getTag("lgliegongtargets"):toString():split("+")
            if tag then use.card:removeTag("lgliegongtargets") end
        end

        if event == sgs.EventPhaseStart then 
            if player:getPhase() == sgs.Player_Start then
                local dis = room:askForExchange(player, self:objectName(), 999, 0, true, "@lgliegong", true)
                if dis then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, "lgliegongdis-Clear", dis:getSubcards():length())
                    local log = sgs.LogMessage()
                    log.type = "#InvokeSkill"
                    log.from = player
                    log.arg = self:objectName()
                    room:sendLog(log)
                    room:throwCard(dis, player, player)
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isKindOf("Slash") then
                            player:obtainCard(card, true)
                            break
                        end
                    end
                end
            end
            if player:getPhase() == sgs.Player_Finish then
                if player:getMark("lgliegongdis-Clear") > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    player:drawCards(player:getMark("lgliegongdis-Clear"))
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

lgliegongbuff = sgs.CreateTargetModSkill{
    name = "#lgliegongbuff",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("lgliegong") then return 1000 end
        return 0
    end,
}

lgliegonglimit = sgs.CreateCardLimitSkill
{
    name = "#lgliegonglimit",
    limit_list = function(self, player)
        if player:getMark("&lgliegong-Clear") > 0 then 
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("&lgliegong-Clear") > 0 then 
            return "BasicCard|.|.|."
        else
            return ""
        end
    end,
}

lghuangzhong:addSkill(lgliegong)
lghuangzhong:addSkill(lgliegongbuff)
lghuangzhong:addSkill(lgliegonglimit)
extension:insertRelatedSkills("lgliegong", "#lgliegongbuff")
extension:insertRelatedSkills("lgliegong", "#lgliegonglimit")

local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("jn") then skills:append(jn) end
if not sgs.Sanguosha:getSkill("spzhihengbuff") then skills:append(spzhihengbuff) end
if not sgs.Sanguosha:getSkill("paiyiex") then skills:append(paiyiex) end
if not sgs.Sanguosha:getSkill("spyinghun") then skills:append(spyinghun) end
if not sgs.Sanguosha:getSkill("spyingzi") then skills:append(spyingzi) end
if not sgs.Sanguosha:getSkill("#spyingzimax") then skills:append(spyingzimax) end
if not sgs.Sanguosha:getSkill("spjilve") then skills:append(spjilve) end
if not sgs.Sanguosha:getSkill("#spjilvere") then skills:append(spjilvere) end
if not sgs.Sanguosha:getSkill("#spjilveda") then skills:append(spjilveda) end
if not sgs.Sanguosha:getSkill("#spjilvedea") then skills:append(spjilvedea) end
if not sgs.Sanguosha:getSkill("#spjilvepr") then skills:append(spjilvepr) end

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable 
{
    ["NyarzFirst"] = "群阴荟萃·开端",

    ["Dcaocao"] = "群阴·曹操",
    ["&Dcaocao"] = "曹操",
    ["#Dcaocao"] = "雄吞天下",
    ["designer:Dcaocao"] = "Nyarz",

    ["Djianxiong"] = "奸雄",
    [":Djianxiong"] = "锁定技，在你受到游戏牌造成的伤害后，若未记录此牌名，你记录之，否则你回复1点体力或摸2张牌。当你即将受到游戏牌造成的伤害时，若你已记录此牌名，此伤害改为1。",
    [":Djianxiong1"] = "锁定技，在你受到游戏牌造成的伤害后，若未记录此牌名，你记录之，否则你回复1点体力或摸2张牌。当你即将受到游戏牌造成的伤害时，若你已记录此牌名，此伤害改为1。",
    [":Djianxiong11"] = "锁定技，在你受到游戏牌造成的伤害后，若未记录此牌名，你记录之，否则你回复1点体力或摸2张牌。当你即将受到游戏牌造成的伤害时，若你已记录此牌名，此伤害改为1。\
				<font color=\"red\"><b>已记录：%arg11</b></font>",
    ["Dzhishi"] = "治世",
    [":Dzhishi"] = "锁定技，出牌阶段开始时和结束阶段，你移除一个“奸雄”记录的牌名并摸两张牌。若没有记录的牌名，你回复一点体力。",
    ["$Arecord"] = "%arg 记录了 %arg2",
    ["$Aremove"] = "%arg 移去了 %arg2",
    ["DjianxiongSlash"] = "杀",
    ["%djianxiongchangedamage"] = "%card 对 %from 造成的伤害因 %arg 的效果减少至 %arg2 点。",
    ["Djianxiong:draw"] = "摸两张牌",
    ["Djianxiong:recover"] = "回复一点体力",

    ["$Djianxiong1"] = "奸雄",
    ["$Djianxiong2"] = "奸雄",
    ["$Dzhishi1"] = "治世",
    ["$Dzhishi2"] = "治世",
    ["~Dcaocao"] = "群阴·曹操",

    ["Ghuangzhong"] = "群阴·神黄忠",
    ["&Ghuangzhong"] = "黄忠",
    ["#Ghuangzhong"] = "矢贯坚石",
    ["designer:Ghuangzhong"] = "Nyarz",

    ["Gliegong"] = "烈弓",
    [":Gliegong"] = "准备阶段，你可以尝试击碎一名角色(成功率根据你对其发动此技能的次数决定)，若成功，该角色死亡，否则你摸X张牌（X为你对其发动此技能的次数）。",
    ["liegongselect"] = "你可以尝试击碎一名角色",
    ["$liegongkill"] = "%arg 击碎了 %arg2",
    ["$liegongfalse"] = "%arg 逃过一劫",
    ["Gposhi"] = "破势",
    [":Gposhi"] = "每回合限一次，在你使用【杀】指定目标后，你可以令其弃置手牌中的所有【闪】。若其手牌中没有【闪】，此【杀】对其伤害+1。",
    ["$poshida"] = "由于 %arg2 手牌中没有【闪】，%arg 对 %arg2 使用的【杀】伤害由 %arg3 点增加到 %arg4 点。",

    ["$Gliegong1"] = "烈弓",
    ["$Gliegong2"] = "烈弓",
    ["$Gposhi1"] = "破势",
    ["$Gposhi2"] = "破势",
    ["~Ghuangzhong"] = "群阴·神黄忠",

    ["Dliuyan"] = "群阴·刘焉",
    ["&Dliuyan"] = "刘焉",
    ["#Dliuyan"] = "雄踞一方",
    ["designer:Dliuyan"] = "Nyarz",

    ["Dtushe"] = "图射",
    [":Dtushe"] = "每回合限一次，当你使用牌指定目标后，你可以摸X张牌。若你的手牌中没有基本牌，此技能无次数限制。（X为你指定的目标数）",
    ["Dtushe:draw"] = "你可以发动“图射”摸%src张牌",
    ["Dlimu"] = "立牧",
    [":Dlimu"] = "你可以将红色牌/黑色牌当作【乐不思蜀】/【兵粮寸断】对自己使用，然后回复一点体力/摸两张牌。若你的判定区有牌，你使用牌无次数和距离限制。",
    ["Dlimu:rec"] = "你可以发动“立牧”回复1点体力",
    ["Dlimu:draw"] = "你可以发动“立牧”摸2张牌",

    ["$Dtushe1"] = "图射",
    ["$Dtushe2"] = "图射",
    ["$Dlimu1"] = "立牧",
    ["$Dlimu2"] = "立牧",
    ["~Dliuyan"] = "群阴·刘焉",

    ["Dwangji"] = "群阴·王基",
    ["&Dwangji"] = "王基",
    ["#Dwangji"] = "踏雪寻梅",
    ["designer:Dwangji"] = "Nyarz",

    ["Dqizhi"] = "奇制",
    [":Dqizhi"] = "在你使用或打出一张牌时，你可以弃置一名角色区域内的一张牌，然后该角色摸一张牌。若此时不在你的回合内，此技能失效直到回合结束。",
    ["Dqizhiask"] = "你可以弃置一名角色区域内的一张牌",
    ["Djinqu"] = "进趋",
    [":Djinqu"] = "结束阶段，你可以摸X张牌，然后将手牌弃至X张。(X为你本回合发动“奇制”的次数且至多为5)",
    ["Djinqu:draw"] = "你可以发动“进趋”摸%src张牌，然后将手牌弃至%src张",

    ["$Dqizhi1"] = "奇制",
    ["$Dqizhi2"] = "奇制",
    ["$Djinqu1"] = "进趋",
    ["$Djinqu2"] = "进趋",
    ["~Dwangji"] = "群阴·王基",

--群阴·神甘宁
    ["Godganning"] = "群阴·神甘宁",
    ["&Godganning"] = "甘宁",
    ["#Godganning"] = "锦龙覆江",
    ["designer:Godganning"] = "Nyarz",

    ["Godjieying"] = "劫营",
    [":Godjieying"] = "锁定技，准备阶段，若你的“营”数量小于三，你获得一个“营”（摸牌阶段多摸一张牌；手牌上限+2；出牌阶段可以多使用一张【杀】）；结束阶段，你可以将一个“营”交给一名没有“营”的其他角色；有“营”的其他角色的结束阶段，你可以弃置其“营”并获得其全部牌。",
    ["Godying"] = "营",
    ["@Godjieying1"] = "你可以将一个“营”交给一名没有“营”的其他角色",
    ["Godpoxi"] = "魄袭",
    [":Godpoxi"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后弃置你与该角色共计四张不同花色的手牌。根据你弃置的自己的手牌数，执行以下效果：为0，结束出牌阶段；不小于2，你回复一点体力；不小于3，你对目标造成1点伤害；不小于4，你摸四张牌。",
    ["@Godpoxi"] = "你可以弃置你与【%src】共计四张不同花色的手牌",
    ["godpoxidis"] = "魄袭",
    ["godpoxi"] = "魄袭",
    ["#Godpoxi"] = "魄袭",

    ["$Godjieying1"] = "劫营",
    ["$Godjieying2"] = "劫营",
    ["$Godpoxi1"] = "魄袭",
    ["$Godpoxi2"] = "魄袭",
    ["~Godganning"] = "群阴·神甘宁",

--留赞
    ["Diyliuzhan"] = "群阴·留赞",
    ["&Diyliuzhan"] = "留赞",
    ["#Diyliuzhan"] = "亢天之音",
    ["designer:Diyliuzhan"] = "Nyarz",

    ["Diyfenyin"] = "奋音",
    [":Diyfenyin"] = "锁定技，每种花色限一次，一张牌进入弃牌堆后，你摸一张牌。准备阶段和结束阶段，重置花色记录。",
    ["Diyliji"] = "力激",
    ["diyliji"] = "力激",
    [":Diyliji"] = "出牌阶段限0次，你可以弃置一张牌，然后对一名其他角色造成1点伤害。（本回合中每有4张牌进入弃牌堆，此技能可用次数便+1）",
    ["Diylijineed"] = "已进入弃牌堆",

    ["$Diyfenyin1"] = "奋音",
    ["$Diyfenyin2"] = "奋音",
    ["$Diyliji1"] = "力激",
    ["$Diyliji2"] = "力激",
    ["~Diyliuzhan"] = "群阴·留赞",

--张梁
    ["exzhangliang"] = "群阴·张梁",
    ["&exzhangliang"] = "张梁",
    ["#exzhangliang"] = "人公将军",
    ["designer:exzhangliang"] = "Nyarz",

    ["exjijun"] = "集军",
    [":exjijun"] = "锁定技，当你成为牌的目标时，你进行一次判定，然后将生效后的判定牌置于你的武将牌上，称为“方”。",
    ["exfang"] = "方",
    ["exfangtong"] = "方统",
    [":exfangtong"] = "结束阶段，你可以弃置一张牌并移去任意张“方”，若点数之和为36，你回复一点体力并摸三张牌，然后你对一名其他角色造成3点雷电伤害。",
    ["@exfangtong"] = "你可以弃置一张牌并移去任意张“方”",

    ["$exjijun1"] = "集军",
    ["$exjijun2"] = "集军",
    ["$exfangtong1"] = "方统",
    ["$exfangtong2"] = "方统",
    ["~exzhangliang"] = "群阴·张梁",

--神吕蒙
    ["godlvmeng"] = "群阴·神吕蒙",
    ["&godlvmeng"] = "吕蒙",
    ["#godlvmeng"] = "白衣渡江",
    ["designer:godlvmeng"] = "Nyarz",

    ["godshelie"] = "涉猎",
    [":godshelie"] = "摸牌阶段结束时，你可以弃置两张牌并从牌堆中获得每种花色的牌各一张。\
    每轮限一次，结束阶段，若你本回合使用的花色数不小于体力值，你可以执行一个额外的摸牌或出牌阶段",
    ["godgongxin"] = "攻心",
    [":godgongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以弃置其中至多两张相同颜色的牌。",
    ["@godgongxin"] = "你可以弃置【%src】至多两张颜色相同的手牌",
    ["#godgongxin"] = "攻心",
    ["godgongxindis"] = "攻心",
    ["godshelie:extra"] = "你可以发动“涉猎”执行一个额外的摸牌或出牌阶段",
    ["godshelie:draw"] = "执行一个额外的摸牌阶段",
    ["godshelie:play"] = "执行一个额外的出牌阶段",
    ["$shelieextra"] = "%arg 将执行一个额外的 %arg2 阶段",

    ["$godshelie1"] = "涉猎",
    ["$godshelie2"] = "涉猎",
    ["$godgongxin1"] = "攻心",
    ["$godgongxin2"] = "攻心",
    ["~godlvmeng"] = "群阴·神吕蒙",

--李通
    ["exlitong"] = "群阴·李通",
    ["&exlitong"] = "李通",
    ["#exlitong"] = "万亿吾独往",
    ["designer:exlitong"] = "Nyarz",

    ["extuifeng"] = "推锋",
    [":extuifeng"] = "出牌阶段，你可以弃置一枚“推锋”标记和一张牌，然后你摸两张牌，本阶段可以多使用一张【杀】。\
    准备阶段、你每回合首次造成伤害或在你受到1点伤害后，你获得一枚“推锋”标记。",

    ["$extuifeng1"] = "推锋",
    ["$extuifeng2"] = "推锋",
    ["~exlitong"] = "群阴·李通",

--神赵云
    ["godzhaoyun"] = "群阴·神赵云",
    ["&godzhaoyun"] = "赵云",
    ["#godzhaoyun"] = "龙战于野",
    ["designer:godzhaoyun"] = "Nyarz",

    ["godjuejin"] = "绝境",
    [":godjuejin"] = "锁定技，你的体力上限为2；在你的体力值变化后，你摸等于你已损失体力值的牌（至少为1）;你的手牌上限+3。",
    ["LuaLonghun"] = "龙魂",
    [":LuaLonghun"] = "你可以将一张牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。",

    ["$godjuejin1"] = "绝境",
    ["$godjuejin2"] = "绝境",
    ["$LuaLonghun1"] = "龙魂",
    ["$LuaLonghun2"] = "龙魂",
    ["~godzhaoyun"] = "群阴·神赵云",

--曹冲
    ["excaochong"] = "群阴·曹冲",
    ["&excaochong"] = "曹冲",
    ["#excaochong"] = "仁爱神童",
    ["designer:excaochong"] = "Nyarz",

    ["exchengxiang"] = "称象",
    [":exchengxiang"] = "在你受到1点伤害后，你可以展示牌堆顶的4张牌并获得其中任意张点数之和小于13的牌，其余牌置入弃牌堆。\
    每回合限一次，若你未以此法获得全部展示的牌，你可以将剩余的牌交给一名其他角色并令其回复一点体力。",
    ["@exchengxiang"] = "请选择任意张点数之和不大于13的牌获得",
    ["exchengxianggive"] = "你可以将剩余的牌交给一名其他角色并令其回复一点体力",
    ["#exchengxiang"] = "称象",
    ["exrenxin"] = "仁心",
    [":exrenxin"] = "一名角色进入濒死状态时，你可以弃置一张装备牌并令其将体力值回复至一点。\
    若该角色为你，你翻面并摸两张牌，然后此技能失效直到当前回合结束。",
    ["@exrenxin"] = "请弃置一张装备牌",

    ["$exchengxiang1"] = "称象",
    ["$exchengxiang2"] = "称象",
    ["$exrenxin1"] = "仁心",
    ["$exrenxin2"] = "仁心",
    ["~excaochong"] = "群阴·曹冲",

--钟会
    ["exzhonghui"] = "群阴·钟会",
    ["&exzhonghui"] = "钟会",
    ["#exzhonghui"] = "桀骜的野心家",
    ["designer:exzhonghui"] = "Nyarz",

    ["exquanji"] = "权计",
    [":exquanji"] = "出牌阶段结束时或当你受到1点伤害后，你可以摸一张牌并将一张牌置于你的武将牌上，称为“权”。你的手牌上限+X（X为“权”的数量）",
    ["exquan"] = "权",
    ["@quanji"] = "请将一张牌置于武将牌上",
    ["ziliex"] = "自立",
    [":ziliex"] = "觉醒技，准备阶段，若你已受伤且至少拥有3张“权”，你减一点体力上限并获得“排异”，然后你摸两张牌或回复一点体力。",
    ["ziliex:draw"] = "摸两张牌",
    ["ziliex:recover"] = "回复一点体力",
    ["paiyiex"] = "排异",
    [":paiyiex"] = "出牌阶段限一次，你可以弃置一张“权”，然后令一名角色摸X张牌（X为你“权”的数量且至多为7)。若其手牌数大于你,你对其造成1点伤害。",

    ["$exquanji1"] = "权计",
    ["$exquanji2"] = "权计",
    ["$ziliex1"] = "自立",
    ["$ziliex2"] = "自立",
    ["$paiyiex1"] = "排异",
    ["$paiyiex2"] = "排异",
    ["~exzhonghui"] = "群阴·钟会",

--孙权
    ["spsunquan"] = "群阴·孙权",
    ["&spsunquan"] = "孙权",
    ["#spsunquan"] = "年轻的贤君",
    ["designer:spsunquan"] = "Nyarz",

    ["spzhiheng"] = "权御",
    [":spzhiheng"] = "锁定技，根据你手牌中两种颜色的卡牌数，执行以下效果：\
    相等：摸一张牌；\
    红色多于黑色：使用基本牌和锦囊牌可以多选择一个目标；\
    黑色多于红色：使用基本牌和锦囊牌无次数和距离限制。",
    ["shouchang"] = "守常",
    [":shouchang"] = "当你成为牌的目标后，你可以弃置一张手牌，然后摸一张牌。",
    ["@spzhiheng"] = "你可以为【%src】 选择一个额外的目标",

    ["$spzhiheng1"] = "权御",
    ["$spzhiheng2"] = "权御",
    ["$shouchang1"] = "守常",
    ["$shouchang2"] = "守常",
    ["~spsunquan"] = "群阴·孙权",

-- 张春华
    ["exzhangcunhua"] = "群阴·张春华",
    ["&exzhangcunhua"] = "张春华",
    ["#exzhangcunhua"] = "宣穆皇后",
    ["designer:exzhangcunhua"] = "Nyarz",

    ["exjueqing"] = "绝情",
    [":exjueqing"] = "你即将造成的伤害视为失去体力；当你使用牌指定其他角色为唯一目标/成为其他角色使用牌的唯一目标时，你可以弃置你与其各一张牌。",
    ["exshangshi"] = "伤逝",
    [":exshangshi"] = "当你的手牌数小于X时，你可以将手牌摸至X张（X为你已损失的体力值且最少为1）。",

    ["$exjueqing1"] = "绝情",
    ["$exjueqing2"] = "绝情",
    ["$exshangshi1"] = "伤逝",
    ["$exshangshi2"] = "伤逝",
    ["~exzhangcunhua"] = "群阴·张春华",

--赵娥
    ["zhaoe"] = "群阴·赵娥",
    ["&zhaoe"] = "赵娥",
    ["#zhaoe"] = "怀刃血仇",
    ["designer:zhaoe"] = "Nyarz",

    ["yanshi"] = "言誓",
    [":yanshi"] = "锁定技，转换技，在你使用或打出一张牌后，你：\
    阳：弃一张牌或失去一点体力；\
    阴：摸一张牌或回复一点体力。",
    [":yanshi1"] = "锁定技，转换技，在你使用或打出一张牌后，你：\
    阳：弃一张牌或失去一点体力；\
    <font color=\"#01A5AF\"><s>阴：摸一张牌或回复一点体力。</s></font>",
    [":yanshi2"] = "锁定技，转换技，在你使用或打出一张牌后，你：\
    <font color=\"#01A5AF\"><s>阳：弃一张牌或失去一点体力；</s></font>\
    阴：摸一张牌或回复一点体力。",
    ["yanshi:discard"] = "弃一张牌",
    ["yanshi:losehp"] = "失去一点体力",
    ["yanshi:drawcard"] = "摸一张牌",
    ["yanshi:recoverhp"] = "回复一点体力",
    ["renchou"] = "刃仇",
    [":renchou"] = "出牌阶段，你可以视为对一名体力值与手牌数有且仅有一项与你相同的角色使用了一张不计次数和距离的【杀】。",

    ["$yanshi1"] = "言誓",
    ["$yanshi2"] = "言誓",
    ["$yanshi3"] = "言誓",
    ["$renchou1"] = "刃仇",
    ["$renchou2"] = "刃仇",
    ["~zhaoe"] = "群阴·赵娥",

--刘辩
    ["dliubian"] = "群阴·刘辩",
    ["&dliubian"] = "刘辩",
    ["#dliubian"] = "从龙之仪",
    ["designer:dliubian"] = "Nyarz",

    ["xuzun"] = "虚尊",
    [":xuzun"] = "出牌阶段开始时，你可以于本阶段中获得以下效果：\
    ①在你使用的牌结算后，摸两张牌。\
    ②若你的手牌数大于体力值上限的两倍，结束出牌阶段。",
    ["$xuzunend"] = "%arg 因 %arg2 的效果结束了出牌阶段。",
    ["dyuyuan"] = "余怨",
    [":dyuyuan"] = "出牌阶段和弃牌阶段开始时，你可以交给任意名其他角色各最多2张手牌。\
    你死亡时，你可以对一名以此法获得过牌的角色造成X点伤害（X为其以此法获得牌的次数且至多为其体力值）",
    ["@dyuyuan"] = "你可以发动“余怨”交给1名其他角色最多2张手牌",
    ["dyuyuandeath"] = "你可以对一名因“余怨”获得过牌的角色造成X点伤害（X为其以此法获得牌的次数且至多为其体力值）",

    ["$xuzun1"] = "虚尊",
    ["$xuzun2"] = "虚尊",
    ["$dyuyuan1"] = "余怨",
    ["$dyuyuan2"] = "余怨",
    ["~dliubian"] = "群阴·刘辩",

--华歆
    ["dhuaxin"] = "群阴·华歆",
    ["&dhuaxin"] = "华歆",
    ["#dhuaxin"] = "渊清玉洁",
    ["designer:dhuaxin"] = "Nyarz",

    ["dxibin"] = "息兵",
    [":dxibin"] = "每回合限一次，当其他角色于其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定一名角色为唯一目标后，你可以令该角色将手牌调整至体力值（至多摸至5张），然后其本回合不能再使用或打出牌。",
    ["dxibin:draw"] = "你可以令 %src 摸 %arg 张牌，然后其本回合不能再使用或打出牌",
    ["dxibin:dis"] = "你可以令 %src 弃置 %arg 张手牌，然后其本回合不能再使用或打出牌",
    ["dxibin:not"] = "你可以令 %src 本回合不能再使用或打出牌",
    ["$dxibin"] = " %arg 本回合不能再使用或打出牌。",
    ["dwanggui"] = "望归",
    [":dwanggui"] = "在你受到1点伤害后，你可以令一名角色摸1张牌，若该角色不是你，你也摸1张牌。\
    在你造成伤害后，你可以对一名本回合内未以此法造成过伤害的角色造成1点伤害。",
    ["dwangguida"] = "你可以对一名本回合内未以此法造成过伤害的角色造成1点伤害",
    ["dwangguidraw"] = "你可以令一名角色摸1张牌，若该角色不是你，你也摸1张牌。",

    ["$dxibin1"] = "息兵",
    ["$dxibin2"] = "息兵",
    ["$dwanggui1"] = "望归",
    ["$dwanggui2"] = "望归",
    ["~dhuaxin"] = "群阴·华歆",

--许劭
    ["xushaoex"] = "群阴·许劭",
    ["&xushaoex"] = "许劭",
    ["#xushaoex"] = "月旦雅评",
    ["designer:xushaoex"] = "Nyarz",

    ["pingjianex"] = "评鉴",
    [":pingjianex"] = "你可以于以下时机从三个对应时机可能可以使用的技能中获得一个直到你再次发动“评鉴”：①出牌阶段限一次；②受到伤害后；③结束阶段。每个技能只能获得一次。",

    ["$pingjianex1"] = "评鉴",
    ["$pingjianex2"] = "评鉴",
    ["~xushaoex"] = "群阴·许劭",


--神张辽
    ["spzhangliao"] = "群阴·神张辽",
    ["#spzhangliao"] = "破虏荡寇",
    ["&spzhangliao"] = "张辽",
    ["designer:spzhangliao"] = "Nyarz",

    ["spduorui"] = "夺锐",
    [":spduorui"] = "每轮每名其他角色限一次，在你对一名其他角色造成伤害后，你可以令其失去其武将牌上的一个技能直到本轮结束，然后你摸一张牌。",
    ["$spduoruireturn"] = "%arg 将获得因 %arg2 失去的 %arg3 。",
    ["gfengying"] = "锋影",
    [":gfengying"] = "每回合限四次，当你获得牌时，你可以将一张牌当作无距离和次数限制的【雷杀】使用。",
    ["@gfengying"] = "你可以将一张牌当作无距离和次数限制的【雷杀】使用",

    ["$spduorui1"] = "夺锐",
    ["$spduorui2"] = "夺锐",
    ["$gfengying1"] = "锋影",
    ["$gfengying2"] = "锋影",
    ["~spzhangliao"] = "群阴·神张辽",


--张星彩
    ["exzhangxingcai"] = "群阴·张星彩",
    ["&exzhangxingcai"] = "张星彩",
    ["#exzhangxingcai"] = "临军对阵",
    ["designer:exzhangxingcai"] = "Nyarz",

    ["shenxianex"] = "甚贤",
    [":shenxianex"] = "锁定技，每当有基本牌不因使用进入弃牌堆时，你摸一张牌。你使用或打出基本牌时，摸一张牌。",
    ["exqiangwu"] = "枪舞",
    [":exqiangwu"] = "出牌阶段限一次，你可以摸两张牌，然后你可以弃置一张牌。若你弃置了牌，你此阶段使用不小于/不大于弃置的牌的点数的牌无次数/距离限制。",
    ["@exqiangwu"] = "你可以弃置一张牌",

    ["$shenxianex1"] = "甚贤",
    ["$shenxianex2"] = "甚贤",
    ["$exqiangwu1"] = "枪舞",
    ["$exqiangwu2"] = "枪舞",
    ["~exzhangxingcai"] = "群阴·张星彩",


--草金鱼
    ["spcaojinyu"] = "群阴·草金鱼",
    ["&spcaojinyu"] = "曹金玉",
    ["#spcaojinyu"] = "瓷语青花",
    ["designer:spcaojinyu"] = "Nyarz",

    ["spyuqi"] = "隅泣",
    ["#spyuqi"] = "隅泣",
    [":spyuqi"] = "每回合限1次，一名角色受到伤害时，你可以观看牌堆顶的3张牌，然后你可以交给受伤角色其中任意张，最后你可以获得剩余牌中的任意张。",
    [":spyuqi2"] = "每回合限%arg1次，一名角色受到伤害时，你可以观看牌堆顶的%arg2张牌，然后你可以交给受伤角色其中任意张，最后你可以获得剩余牌中的任意张。",
    ["spyuqi:view"] = "你可以发动“隅泣”观看牌堆顶的 %src 张牌，然后你可以交给 %arg 其中任意张，最后你可以获得剩余牌中的任意张。",
    ["@spyuqi"] = "请选择你要交给 %src 的牌",
    ["spxianjin"] = "娴静",
    [":spxianjin"] = "准备阶段，你可以令“隅泣”的观看数量+1。（至多为5）若已达到上限，你可以对一名角色发动“隅泣”。（不计入回合次数限制）",
    ["@spxianjin"] = "你可以对一名角色发动“隅泣”",
    ["spshanshen"] = "善身",
    [":spshanshen"] = "每名角色限一次，一名角色进入濒死状态时，你可以回复一点体力并令“隅泣”每回合可用次数+1。(至多为5)若已达到上限，你可以对一名角色发动“隅泣”。（不计入回合次数限制）",
    ["@spshanshen"] = "你可以对一名角色发动“隅泣”",
    ["$spyuqiview"] = "%from 发动 %arg2 观看了牌堆顶的 %arg 张牌。",
    ["$spyuqiselfview"] = "牌堆顶的 %arg 张牌为 %card。",

    ["$spyuqi1"] = "隅泣",
    ["$spyuqi2"] = "隅泣",
    ["$spxianjin1"] = "娴静",
    ["$spxianjin2"] = "娴静",
    ["$spshanshen1"] = "善身",
    ["$spshanshen2"] = "善身",
    ["~spcaojinyu"] = "群阴·草金鱼",

    
--小乔·极
    ["jixiaoqiao"] = "群阴·小乔·极",
    ["#jixiaoqiao"] = "琪花瑶草",
    ["&jixiaoqiao"] = "小乔",
    ["designer:jixiaoqiao"] = "Nyarz",

    ["shaoyan"] = "韶颜",
    [":shaoyan"] = "当你成为牌的目标时，若使用者的手牌数不小于你，你可以摸一张牌。",
    ["jitongxin"] = "同心",
    [":jitongxin"] = "韵律技，出牌阶段限一次，你可以：\
    平：令一名其他角色交给你一张手牌，然后你可以令其摸一张牌。\
    仄：交给一名其他角色一张手牌，然后你可以对其造成1点伤害。\
    转韵：在你使用本回合未使用过的类型的牌后。",
    [":jitongxin1"] = "韵律技，出牌阶段限一次，你可以：\
    平：令一名其他角色交给你一张手牌，然后你可以令其摸一张牌。\
    <font color=\"#01A5AF\"><s>仄：交给一名其他角色一张手牌，然后你可以对其造成1点伤害。</s></font>\
    转韵：在你使用本回合未使用过的类型的牌后。",
    [":jitongxin2"] = "韵律技，出牌阶段限一次，你可以：\
    <font color=\"#01A5AF\"><s>平：令一名其他角色交给你一张手牌，然后你可以令其摸一张牌。</s></font>\
    仄：交给一名其他角色一张手牌，然后你可以对其造成1点伤害。\
    转韵：在你使用本回合未使用过的类型的牌后。",
    ["jitongxingive"] = "请将一张手牌交给 %src",
    ["jitongxindraw"] = "你可以令 %src 摸一张牌",
    ["jitongxinda"] = "你可以对 %src 造成1点伤害",
    ["jitongxinelse"] = "同心",

    ["$shaoyan1"] = "韶颜",
    ["$shaoyan2"] = "韶颜",
    ["$jitongxin1"] = "同心",
    ["$jitongxin2"] = "同心",
    ["~jixiaoqiao"] = "群阴·小乔·极",


--孙策
    ["spsunce"] = "群阴·孙策",
    ["&spsunce"] = "孙策",
    ["#spsunce"] = "江东小霸王",
    ["designer:spsunce"] = "Nyarz",

    ["spjiang"] = "激昂",
    [":spjiang"] = "出牌阶段限一次，你可以失去一点体力并将任意张手牌当作【决斗】使用，此牌造成伤害后，你摸X张牌。（X为转化此【决斗】的手牌数）\
    当你使用【杀】或【决斗】指定目标或成为【杀】或【决斗】的目标后，你可以摸一张牌。",
    ["spjiang:draw"] = "你可以发动“激昂”摸一张牌",
    ["spjiang2"] = "激昂",
    [":spjiang2"] = "出牌阶段限一次，你可以失去一点体力并将任意张手牌当作【决斗】使用，此牌造成伤害后，你摸X张牌。（X为转化此【决斗】的手牌数）若你处于受伤状态，你再回复1点体力。防止此【决斗】对你造成的伤害。\
    当你使用【杀】或【决斗】指定目标或成为【杀】或【决斗】的目标后，你可以摸一张牌。",
    ["$spjiangfor"] = "防止了【决斗】对 %arg 造成的伤害。",
    ["sphunzi"] = "魂姿",
    [":sphunzi"] = "觉醒技，当你进入濒死状态时，你将体力值回复至2点，然后你减1点体力上限，修改“激昂”，获得“英姿”和“英魂”。",
    ["spyinghun"] = "英魂",
    [":spyinghun"] = "准备阶段，你可以选择一名角色，令其摸X张牌，然后弃1张牌；或令其摸1张牌，然后弃置X张牌。（X为你的已损体力值且至少为1）",
    ["spyinghun:draw"] = "令其摸%src张牌，然后弃1张牌",
    ["spyinghun:dis"] = "令其摸1张牌，然后弃%src张牌",
    ["@spyinghun"] = "你可以选择一名角色，令其摸%src张牌，然后弃1张牌；或令其摸1张牌，然后弃置%src张牌",
    ["spyingzi"] = "英姿",
    [":spyingzi"] = "准备阶段，你可以摸X张牌并令你本回合手牌上限+X。（X为手牌数不大于你的角色数）",
    ["spyingzi:draw"] = "你可以摸%src张牌并令你本回合手牌上限+%src",

    ["$spjiang1"] = "激昂",
    ["$spjiang2"] = "激昂",
    ["$sphunzi1"] = "魂姿",
    ["$sphunzi2"] = "魂姿",
    ["$spyinghun1"] = "英魂",
    ["$spyinghun2"] = "英魂",
    ["$spyingzi1"] = "英姿",
    ["$spyingzi2"] = "英姿",
    ["~spsunce"] = "群阴·孙策",

    
--神司马懿
    ["spsimayi"] = "群阴·神司马懿",
    ["#spsimayi"] = "三分归晋",
    ["&spsimayi"] = "司马懿",
    ["designer:spsimayi"] = "Nyarz",

    ["sprenjie"] = "忍戒",
    [":sprenjie"] = "锁定技，游戏开始时、你受到1点伤害后、你因弃置失去1张牌后,你获得1枚“忍”。",
    ["spren"] = "忍",
    ["splianpo"] = "连破",
    [":splianpo"] = "锁定技，在你杀死一名角色后，你可以获得其一个技能或回复一点体力并摸2张牌。\
    一名角色的回合结束时，若你于此回合内杀死过角色，你摸3张牌并执行一个额外回合。",
    ["$splianpoturn"] = "%arg 因 %arg2 的效果将获得一个额外的回合。",
    ["splianpo:redr"] = "回复1点体力并摸2张牌",
    ["spbaiyin"] = "拜印",
    [":spbaiyin"] = "觉醒技，准备阶段或结束阶段，若你有至少四枚“忍”，你减1点体力上限并获得“极略”,然后你获得2枚“忍”。若你的判定区有牌，你可以弃置其中一张。",
    ["spjilve"] = "极略",
    [":spjilve"] = "你可以于以下时机弃置1枚“忍”并执行对应效果：\
    ①出牌阶段限一次，从牌堆中获得X张不同的锦囊牌。（X为你的体力上限）\
    ②一张判定牌生效前，将判定结果修改为任意花色和点数。\
    ③受到伤害后，摸3张牌并交给一名其他角色1张手牌，令该角色翻面。\
    ④一名角色进入濒死状态后，令其本回合不能成为其他角色使用【桃】的目标",
    ["spjilve:retrial"] = "你可以发动“极略”修改此次判定结果",
    ["spjilvedamaged"] = "你可以摸3张牌并交给一名其他角色1张手牌，令该角色翻面",
    ["$spjilvere"] = "%arg 发动 %arg2 将判定结果修改为了 %arg3 [%arg4%arg5]。",
    ["spjilvegive"] = "请选择你要交给%src的手牌",
    ["spjilve:peach"] = "你可以弃置一枚“忍”并令%src本回合中不能成为其他角色使用【桃】的目标",
    ["$spjilvedea"] = "%arg 本回合中不能成为其他角色使用【桃】的目标。",

    ["$sprenjie1"] = "忍戒",
    ["$sprenjie2"] = "忍戒",
    ["$splianpo1"] = "连破",
    ["$splianpo2"] = "连破",
    ["$spbaiyin1"] = "拜印",
    ["$spbaiyin2"] = "拜印",
    ["$spjilve1"] = "极略",
    ["$spjilve2"] = "极略",
    ["$spjilve3"] = "极略",
    ["$spjilve4"] = "极略",
    ["~spsimayi"] = "群阴·神司马懿",


--神姜维
    ["spshenjiangwei"] = "群阴·神姜维",
    ["&spshenjiangwei"] = "姜维",
    ["#spshenjiangwei"] = "敕剑伏波",
    ["designer:spshenjiangwei"] = "Nyarz",

    ["sptianren"] = "天任",
    [":sptianren"] = "锁定技，每个回合结束时，若本局游戏进入弃牌堆的牌名数不小于你的体力上限，你加一点体力上限并回复一点体力，然后摸两张牌。最后，清除此技能记录的牌名。",
    ["sppingxiang"] = "平襄",
    [":sppingxiang"] = "限定技，出牌阶段，若你的体力上限不小于10，你可以将体力上限调整至1，然后视为你依次使用了至多9张无距离和次数限制的【火杀】。最后，你修改“平襄”。",
    ["@sppingxiang"] = "请使用第%src张【火杀】",
    [":sppingxiang1"] = "出牌阶段限一次，若你的体力上限大于4，你可以将体力上限调整至4，然后视为你使用了一张无距离和次数限制的【火杀】。",
    ["spjiufa"] = "九伐",
    [":spjiufa"] = "准备阶段，若你使用或打出过至少九种不同牌名的牌，你可以展示牌堆中的九张不同牌名的牌并使用其中任意张可以使用的牌，其余牌置入弃牌堆。此技能结算后，重置牌名记录。",
    ["spjiufa:spjiufa"] = " 你可以发动“九伐”展示牌堆中的九张不同牌名的牌",
    ["#spjiufa"] = "九伐",
    ["@spjiufa"] = "你可以使用其中一张牌",
    ["$spjiufadis"] = "%arg 将 %arg2 张牌置于弃牌堆：%card。",
    ["$spshenjiangweirecord"] = "%arg 发动 %arg2 记录了 %arg3。",
    ["$spjiufause"] = "%arg 发动 %arg2 使用了 %card。",

    ["$sptianren1"] = "天任",
    ["$sptianren2"] = "天任",
    ["$sppingxiang1"] = "平襄",
    ["$sppingxiang2"] = "平襄",
    ["$spjiufa1"] = "九伐",
    ["$spjiufa2"] = "九伐",
    ["~spshenjiangwei"] = "群阴·神姜维",


--周善
    ["zhoushand"] = "群阴·周善",
    ["&zhoushand"] = "周善",
    ["#zhoushand"] = "荆吴刑天",
    ["designer:zhoushand"] = "Nyarz",

    ["miyund"] = "密运",
    [":miyund"] = "锁定技，每轮游戏开始时，你展示并获得一名其他角色的一张牌，称为“安”。\
    若你的手牌中有“安”，你的手牌上限等于体力上限，“安”不计入你的手牌上限。\
    每轮游戏结束时，你将“安”交给一名其他角色，然后你摸X张牌并弃置手牌至X张（X为你的体力上限）。你可以改为将以此法弃置的牌交给一名其他角色。",
    ["miyunsafe"] = "安",
    ["@miyund"] = "请获得一名其他角色的一张牌作为“安”",
    ["miyund-give"] = "你须将“安”交给一名其他角色",
    ["miyund-dis"] = "请弃置%src张手牌",
    ["miyund-obtain"] = "你可以将这 %src 张牌交给一名其他角色",
    ["danyind"] = "胆迎",
    [":danyind"] = "每回合限一次，你可以展示手牌中的“安”，然后视为你使用或打出了一张任意的基本牌。\
    若如此做，本回合中你下次受到伤害时，你弃置“安”。",
    ["@danyind"] = "请为【%src】选择目标",

    ["$miyund1"] = "密运",
    ["$miyund2"] = "密运",
    ["$danyind1"] = "胆迎",
    ["$danyind2"] = "胆迎",
    ["~zhoushand"] = "群阴·周善",


--秦朗
    ["spqinlang"] = "群阴·秦朗",
    ["&spqinlang"] = "秦朗",
    ["#spqinlang"] = "穆乐拾忆",
    ["designer:spqinlang"] = "Nyarz",
    
    ["sphaochong"] = "昊宠",
    [":sphaochong"] = "在你使用的牌结算后，若你的手牌中没有可以使用的牌，你可以弃置所有手牌(没有则不弃)并摸X+1张牌。（X为你弃置的牌数）",
    ["sphaochong:disdraw"] = "你可以发动“昊宠”弃置所有手牌并摸%src张牌",
    ["spjinjin"] = "矜谨",
    [":spjinjin"] = "每回合限一次，当你造成或受到伤害后，你可以将手牌数调整至手牌上限。若你因此失去牌，你回复1点体力或对伤害目标/来源造成1点伤害。",
    ["spjinjin:draw"] = "你可以发动“矜谨”摸%src张牌",
    ["spjinjin:dis1"] = "你可以发动“矜谨”弃%src张牌,然后你回复1点体力或对%arg造成1点伤害",
    ["spjinjin:dis2"] = "你可以发动“矜谨”弃%src张牌,然后你回复1点体力",
    ["spjinjin:recover"] = "回复1点体力",
    ["spjinjin:damage"] = "对%src造成1点伤害",

    ["$sphaochong1"] = "昊宠",
    ["$sphaochong2"] = "昊宠",
    ["$spjinjin1"] = "矜谨",
    ["$spjinjin2"] = "矜谨",
    ["~spqinlang"] = "群阴·秦朗",


--司马懿·晋
    ["hfsimayi"] = "群阴·司马懿·晋",
    ["#hfsimayi"] = "狼顾之相",
    ["&hfsimayi"] = "司马懿",
    ["designer:hfsimayi"] = "Nyarz",

    ["hflanggu"] = "狼顾",
    [":hflanggu"] = "锁定技，当你造成或受到伤害后，你观看牌堆顶的两张牌并获得其中一张牌，然后伤害来源进行一次【闪电】判定。",
    ["$hflanggusd"] = "%arg 因 %arg2 的效果将进行一次 %arg3 判定。",
    ["hfgushi"] = "固势",
    [":hfgushi"] = "出牌阶段限3次，你可以视为使用了以下第X项（X为此阶段你发动“固势”的次数）：①【桃】；②【无中生有】；③【决斗】。",

    ["$hflanggu1"] = "狼顾",
    ["$hflanggu2"] = "狼顾",
    ["$hfgushi1"] = "固势",
    ["$hfgushi2"] = "固势",
    ["~hfsimayi"] = "群阴·司马懿·晋",


--杨彪
    ["dyangbiao"] = "群阴·杨彪",
    ["&dyangbiao"] = "杨彪",
    ["#dyangbiao"] = "德彰海内",
    ["designer:dyangbiao"] = "Nyarz",

    ["dzhaohan"] = "昭汉",
    [":dzhaohan"] = "锁定技，准备阶段，若牌堆未洗切，你回复1点体力，否则你受到1点无来源的伤害。",
    ["dyizheng"] = "义争",
    [":dyizheng"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，该角色跳过下个摸牌阶段，否则其对你造成1点伤害。",
    ["$dyizhengskip"] = "%arg 因 %arg2 的效果将跳过 %arg3 阶段。",
    ["drangjie"] = "让节",
    [":drangjie"] = "在你受到1点伤害后，你可以摸1张牌，然后你选择1项：①移动场上1张牌；②从最近进入弃牌堆的9张牌中将1张牌移动到一名角色区域内的合理位置。",
    ["drangjie:move"] = "移动场上1张牌",
    ["drangjie:draw"] = "从最近进入弃牌堆的9张牌中将1张牌移动到一名角色区域内的合理位置",
    ["$drangjienotcard"] = "<font color=\"red\"><b>弃牌堆中没有任何牌！！!</b></font>",
    ["#drangjie"] = "让节",
    ["@drangjie"] = "请选择你要移动的牌",
    ["drangjiemth"] = "请选择要获得此【%src】的角色",
    ["drangjiemte"] = "请选择要将此【%src】置入装备区的角色",
    ["drangjiemtj"] = "请选择要将此【%src】置入判定区的角色",
    ["drangjie:hand"] = "移动到手牌区",
    ["drangjie:equip"] = "移动到装备区",
    ["drangjie:judge"] = "移动到判定区",
    ["$drangjiemovecard"] = "%arg 发动 %arg2 将 %card 移动到了 %arg3 的 %arg4。",
    ["drangjieequiparea"] = "装备区",
    ["drangjiejudgearea"] = "判定区",

    ["$dzhaohan1"] = "昭汉",
    ["$dzhaohan2"] = "昭汉",   
    ["$dyizheng1"] = "义争",
    ["$dyizheng2"] = "义争",
    ["$drangjie1"] = "让节",
    ["$drangjie2"] = "让节",
    ["~dyangbiao"] = "群阴·杨彪",


--诸葛亮·武
    ["dwzhugeliang"] = "群阴·诸葛亮·武",
    ["&dwzhugeliang"] = "诸葛亮",
    ["#dwzhugeliang"] = "千古一相",
    ["designer:dwzhugeliang"] = "Nyarz",

    ["dwzhizhe"] = "智哲",
    [":dwzhizhe"] = "限定技，出牌阶段，你可以展示一张基本牌或普通锦囊牌，然后你修改“智哲”。\
    修改：每回合限一次，你可以视为使用或打出了一张“智哲”展示过的牌。",
    [":dwzhizhe11"] = "每回合限一次，你可以视为使用或打出了一张【%arg11】。",
    ["dwqingshi"] = "情势",
    [":dwqingshi"] = "当你使用一张牌时，若你的手牌中有牌名相同的牌，你可以选择一项：\
    ①令任意名角色摸1张牌。\
    ②令此牌对任意名目标造成的伤害+1。\
    ③摸两张牌然后本回合不能再为此牌名的牌发动“情势”。",
    ["dwqingshi:drawall"] = "令任意名角色摸1张牌",
    ["dwqingshi:damage"] = "令【%src】对任意名目标造成的伤害+1",
    ["dwqingshi:drawself"] = "摸2张牌，然后本回合使用【%src】时不能再发动“情势”",
    ["dwqingshiSlash"] = "杀",
    ["$dwqingshidrawalllog"] = "%arg 选择了%arg2。",
    ["dwqingshidrawall"] = "你可以令任意名角色摸1张牌",
    ["$dwqingshidamagelog"] = "%arg 选择了令 %card %arg2。",
    ["dwqingshidamagemore"] = "对任意名目标造成的伤害+1",
    ["dwqingshidamage"] = "你可以令【%src】对任意名目标造成的伤害+1",
    ["$dwqingshidrawselflog"] = "%arg 选择了 摸两张牌，然后本回合使用【%arg2】时不能再触发“情势”。",
    ["$dwqingshidamageup"] = "%arg 受到的伤害因 %arg2 由 %arg3 点增加到了 %arg4 点。",
    ["dwjingcui"] = "尽瘁",
    [":dwjingcui"] = "锁定技，游戏开始时，你将手牌摸到7张。\
    准备阶段，你将体力值调整至与牌堆中点数为7的牌相等,然后你观看牌堆顶的X张牌并以任意顺序放回牌堆顶或牌堆底。（X为你的体力值）\
    每轮限一次，一名角色处于濒死状态时,你可以交给其一张手牌和牌堆中一张点数为7的牌，令其将体力值回复到1点。",
    ["$dwjingcuicount"] = "牌堆中点数为7的牌共有 %arg 张。",
    ["dwjingcui:dying"] = "你可以交给%src一张手牌和牌堆中一张点数为7的牌，令其将体力值回复到1点。<br/>牌堆中共有%arg张点数为7的牌。",
    ["@dwjingcui"] = "请将一张手牌交给 %src",

    ["$dwzhizhe1"] = "智哲",
    ["$dwzhizhe2"] = "智哲",
    ["$dwqingshi1"] = "情势",
    ["$dwqingshi2"] = "情势",
    ["$dwjingcui1"] = "尽瘁",
    ["$dwjingcui2"] = "尽瘁",
    ["~dwzhugeliang"] = "群阴·诸葛亮·武",


--大梦仙尊
    ["dmzhouxuan"] = "群阴·大梦仙尊",
    ["#dmzhouxuan"] = "大梦仙尊",
    ["&dmzhouxuan"] = "周宣",
    ["designer:dmzhouxuan"] = "Nyarz",

    ["dmwumei"] = "寤寐",
    [":dmwumei"] = "每轮限一次，你的回合开始前，你可以令一名角色执行一个额外的回合，同时令其跳过此回合内的弃牌阶段。\
    此额外回合结束时，所有存活角色将体力值调整至与回合开始时相同。",
    ["dmwumeiextraturn"] = "你可以发动“寤寐”令一名角色执行一个额外的回合",
    ["$dmwumeigainturn"] = "%arg 因 %arg2 的效果将执行一个额外的回合。",
    ["$dmwumeichangehp"] = "%arg 因 %arg2 的效果将体力值调整至了 %arg3 点。",
    ["$dmwumeiskip"] = "%from 因 %arg 的效果将跳过 %arg2 阶段。",
    ["dmzhanmeng"] = "占梦",
    [":dmzhanmeng"] = "占梦：当你使用或打出牌时，你可以执行一项（每回合每项限一次）：\
    ①获得一张伤害牌和一张非伤害牌。\
    ②令一名其他角色弃置两张牌，若这两张牌点数不同，对其造成一点火焰伤害。\
    ③令一名角色回复一点体力并复原武将牌。",
    ["dmzhanmeng:recover"] = "令一名角色回复一点体力并复原武将牌",
    ["dmzhanmeng:draw"] = "获得一张伤害牌和一张非伤害牌",
    ["dmzhanmeng:discard"] = "令一名其他角色弃置两张牌，若这两张牌点数不同，对其造成一点火焰伤害",
    ["@dmzhanmeng"] = "你可以 %src",
    ["$dmzhanmengchoice"] = "%from 选择了 %arg。",
    ["$dmzhanmengnocard"] = "<font color=\"red\"><b>没有其他角色可以弃置牌！！!</b></font>",
    ["recoverdmzhanmeng"] = "令一名角色回复一点体力并复原武将牌",
    ["drawdmzhanmeng"] = "获得一张伤害牌和一张非伤害牌",
    ["discarddmzhanmeng"] = "令一名其他角色弃置两张牌，若这两张牌点数不同，对其造成一点火焰伤害",
    ["$dmzhanmengrenew"] = "%from 重置了武将牌。",
    ["dmshenyou"] = "神游",
    [":dmshenyou"] = "锁定技，当你进入濒死状态后，若你未被救回，则将你的体力值调整为1，防止此后你的体力值变化效果。当前回合结束时，你执行一个额外回合，此额外回合结束时，你死亡。",
    ["$dmshenyouhp"] = "%from 将体力值调整为了 1 点。",
    ["$dmshenyoustart"] = "%from 的体力值现在起被锁定为 1 点。",
    ["$dmshenyoucompulosry"] = "%from 因 %arg2 的效果防止了 %arg 。",
    ["dmshenyouhplost"] = "体力流失",
    ["dmshenyouhprecover"] = "体力回复",
    ["dmshenyoudamage"] = "受到伤害",
    ["$dmshenyougainturn"] = "%arg 因 %arg2 的效果将执行一个额外的回合。",
    ["$dmshenyoudie"] = "%from 魂归九天。",

    ["$dmwumei1"] = "寤寐",
    ["$dmwumei2"] = "寤寐",
    ["$dmzhanmeng1"] = "占梦",
    ["$dmzhanmeng2"] = "占梦",
    ["$dmshenyou1"] = "神游",
    ["$dmshenyou2"] = "神游",
    ["~dmzhouxuan"] = "群阴·大梦仙尊",


--神刘备
    ["godliubei"] = "群阴·神刘备",
    ["&godliubei"] = "刘备",
    ["#godliubei"] = "至仁至信",
    ["designer:godliubei"] = "Nyarz",

    ["godlongnu"] = "龙怒",
    [":godlongnu"] = "锁定技，出牌阶段开始时，你须选择一项：\
    ①失去1点体力并摸2张牌，本阶段内你可以将红色手牌当作【火杀】使用。\
    ②失去1点体力上限并摸2张牌，本阶段内你可以将黑色手牌当作【雷杀】使用。\
    背水：当你于此阶段内杀死一名角色后，你加2点体力上限并回复1点体力。\
    你于出牌阶段内可以额外使用每种属性的【杀】各一张，且你使用属性【杀】无距离限制。\
    ps:尽管技能按钮是黑色的，但是你可以直接点。",
    ["godlongnuall"] = "龙怒：背水",
    ["godlongnu:red"] = "失去1点体力并摸2张牌，本阶段内你可以将红色手牌当作【火杀】使用",
    ["godlongnu:black"] = "失去1点体力上限并摸2张牌，本阶段内你可以将黑色手牌当作【雷杀】使用",
    ["godlongnu:all"] = "背水：当你于此阶段内杀死一名角色后，你加2点体力上限并回复1点体力。",
    ["godjieyin"] = "结营",
    [":godjieyin"] = "锁定技，你始终处于连环状态。结束阶段，你须横置一名其他角色。防止你受到的铁索连环传导的属性伤害。",
    ["$godjieyinforseen"] = "%from 因 %arg 的效果防止了受到传导伤害。",
    ["@godjieyin"] = "你须横置一名其他角色",

    ["$godlongnu1"] = "龙怒",
    ["$godlongnu2"] = "龙怒",
    ["$godjieyin1"] = "结营",
    ["$godjieyin2"] = "结营",
    ["~godliubei"] = "群阴·神刘备",
    

--孝吕布
    ["xiaolvbu"] = "群阴·孝吕布",
    ["#xiaolvbu"] = "父死子笑",
    ["&xiaolvbu"] = "吕布",
    ["designer:xiaolvbu"] = "Nyarz",

    ["xiaorenfu"] = "认父",
    [":xiaorenfu"] = "锁定技，一轮游戏开始时，你须选择一名其他角色，你令其成为“义父”并获得其一张牌。\
    当“义父”角色改变时，你可以对原先的“义父”造成1点伤害。\
    你对“义父”使用【杀】造成的伤害+1,你与“义父”的距离视为1。\
    “义父”的出牌阶段开始时，其可以令你视为对一名角色使用了一张【杀】。\
    当你对“义父”以外的其他角色造成伤害后，“义父”须交给你一张牌。",
    ["@xiaorenfu"] = "你须选择一名其他角色，令其成为“义父”并获得其一张牌",
    ["xiaoyifu"] = "义父",
    ["xiaorenfu:damage"] = "你可以对旧“义父” %src 造成1点伤害",
    ["$xiaorenfudamageup"] = "%from 对 %arg2 的伤害因 %arg 的效果由 %arg3 点增加到 %arg4 点。",
    ["$xiaoyifuchangefrom"] = "%arg 不再是 %from 的“义父”了。",
    ["$xiaoyifuchangeto"] = "%arg 现在是 %from 的新“义父”了。",
    ["xiaoyifugive"] = "请选择一张要赏赐给 %src 的牌",
    ["xiaoyifuslash"] = "你可以令 %src 视为对你选择的一名角色使用了一张【杀】",
    ["xiaoyizi"] = "义子",
    ["xiaosheji"] = "射戟",
    [":xiaosheji"] = "每回合限一次，一名其他角色受到另一名其他角色的伤害后，你可以弃置伤害来源一张牌并视为对其使用了一张【杀】。若此【杀】造成了伤害，伤害来源于本回合内不能再对该角色使用牌。",
    ["#xiaoshejisave"] = "射戟",
    ["xiaosheji:slash"] = "你可以弃置%src一张牌并视为对其使用了一张【杀】<br/>若此【杀】造成了伤害，%src于本回合内不能再对%arg使用牌",

    ["$xiaorenfu1"] = "认父",
    ["$xiaorenfu2"] = "认父",
    ["$xiaosheji1"] = "射戟",
    ["$xiaosheji2"] = "射戟",
    ["~xiaolvbu"] = "群阴·孝吕布",


--袁谭袁尚
    ["doubleO"] = "群阴·袁谭袁尚",
    ["&doubleO"] = "袁谭袁尚",
    ["#doubleO"] = "兄弟阋墙",
    ["designer:doubleO"] = "Nyarz",

    ["doubleneifa"] = "内伐",
    [":doubleneifa"] = "锁定技，准备阶段，你弃置一名角色区域内的一张牌，然后你摸两张牌。\
    因此失去过区域内的牌的其他角色的准备阶段，该角色可以也如此做（此时目标只能为你或因此失去过区域内的牌的角色）。",
    ["doubleneifamust"] = "请弃置一名角色区域内的一张牌",
    ["doubleneifacan"] = "你可以发动“内伐”弃置一名特定角色区域内的一张牌。",

    ["$doubleneifa1"] = "内伐",
    ["$doubleneifa2"] = "内伐",
    ["~doubleO"] = "群阴·袁谭袁尚",


--魏武大帝
    ["wwcaocao"] = "群阴·魏武大帝",
    ["&wwcaocao"] = "曹操",
    ["#wwcaocao"] = "魏武大帝",
    ["designer:wwcaocao"] = "Nyarz",

    ["wwxionglve"] = "雄略",
    [":wwxionglve"] = "锁定技，每轮游戏开始时，你随机抽取5-X个来自未上场魏势力角色的技能，然后选择一个获得。（X为游戏轮数）若你未因此获得技能，你失去一点体力上限。",
    ["wwguixin"] = "归心",
    [":wwguixin"] = "锁定技，一名其他角色一次性获得至少两张牌时，其须交给你其中一张牌。",
    ["wwguixingive"] = "请选择一张交给%src的牌",

    ["$wwxionglve1"] = "雄略",
    ["$wwxionglve2"] = "雄略",
    ["$wwguixin1"] = "归心",
    ["$wwguixin2"] = "归心",
    ["~wwcaocao"] = "群阴·魏武大帝",


--祭风卧龙
    ["jfwolong"] = "群阴·祭风卧龙",
    ["#jfwolong"] = "祭风卧龙",
    ["&jfwolong"] = "诸葛亮",
    ["designer:jfwolong"] = "Nyarz",

    ["jfjifeng"] = "祭风",
    [":jfjifeng"] = "出牌阶段，你可以视为使用一张【火攻】。若此牌未造成伤害，你令目标下次受到的火焰伤害+1，然后此技能于本阶段内失效。\
    你使用【火攻】时可以从牌堆顶的四张牌中选择牌代替手牌弃置。",
    ["@jfjifeng"] = "你可以弃置一张 %src 牌对 %arg 造成1点火焰伤害",
    ["#jfjifeng"] = "祭风",
    ["$jfjifengdiscard"] = "%from 弃置了 %arg 的 %card 。",
    ["jfhand"] = "手牌中的",
    ["jfdrawpile"] = "牌堆中的",
    ["$jfjifengdamage"] = "%from 受到的火焰伤害因 %arg 的效果由 %arg2 点增加到了 %arg3 点。",
    ["jfyueyin"] = "月隐",
    [":jfyueyin"] = "锁定技，防止非游戏牌对你造成的伤害。当你成为牌的目标时，若这不是你本回合第一次成为该类型的牌的目标，防止此牌对你造成的伤害。若此牌为锦囊牌，你摸一张牌。",
    ["$jfyueyinforseen"] = "%from 因 %arg 的效果防止了即将受到的 %arg2 点伤害。",
    ["jfjifengdis"] = "祭风",
    ["jfqixing"] = "祈星",
    [":jfqixing"] = "锁定技，你死亡时，将7点雷电伤害随机分配给存活的其他角色。你可以令一名角色不成为此伤害的目标，该伤害至多使角色将体力值降至1点。",
    ["@jfqixing"] = "请选择一名不受“祈星”伤害的角色",
    ["$jfqixingelse"] = "%arg 将不会受到 %arg2 的伤害。",
    ["$jfqixingdamage"] = "%from 将受到 %arg 的第 %arg2 点雷电伤害。",

    ["$jfjifeng1"] = "祭风",
    ["$jfjifeng2"] = "祭风",
    ["$jfyueyin1"] = "月隐",
    ["$jfyueyin2"] = "月隐",
    ["$jfqixing1"] = "祈星",
    ["$jfqixing2"] = "祈星",
    ["~jfwolong"] = "群阴·祭风卧龙",


--曹纯
    ["xrcaocun"] = "群阴·曹纯",
    ["&xrcaocun"] = "曹纯",
    ["#xrcaocun"] = "虎啸龙渊",
    ["designer:xrcaocun"] = "Nyarz",

    ["xrxiaorui"] = "骁锐",
    [":xrxiaorui"] = "每回合限一次，当你对一名其他角色造成伤害时，或当你受到其他角色造成的伤害时，你可以观看其手牌，然后可以将其中一张牌当作【杀】对其使用。",
    ["xrxiaorui:view"] = "你可以发动“骁锐”观看%src的手牌",
    ["#xrxiaorui"] = "骁锐",
    ["@xrxiaorui"] = "你可以将%src的一张手牌当作【杀】对其使用",
    ["$XrxiaoruiViewAllCards"] = "%from 观看了 %arg 的手牌。",
    ["$XrxiaoruiViewAllCardsself"] = "%arg 的手牌为 %card 。",
    ["xrshanjia"] = "缮甲",
    [":xrshanjia"] = "出牌阶段开始时，你可以摸一张牌并从牌堆中使用一张你未拥有类别的装备牌。\
    当你使用一张装备牌结算后，你可以摸2张牌，然后弃置2-X张牌。若你没有弃置基本牌，你可以视为使用了一张无距离限制的【杀】。（X为你装备区的牌数）",
    ["xrshanjia:use"] = "你可以发动“缮甲”从牌堆中使用一张你装备区内空置处对应类别的装备牌",
    ["xrshanjia:draw"] = "你可以发动“缮甲”摸2张牌并弃%src张牌",
    ["@xrshanjia"] = "你可以视为使用了一张无距离限制的【杀】",
    ["$xrshanjianot"] = "牌堆中没有 %from 可以使用的装备。",

    ["$xrxiaorui1"] = "骁锐",
    ["$xrxiaorui2"] = "骁锐",
    ["$xrshanjia1"] = "缮甲",
    ["$xrshanjia2"] = "缮甲",
    ["~xrcaocun"] = "群阴·曹纯",


--马超
    ["cqmachao"] = "群阴·马超",
    ["&cqmachao"] = "马超",
    ["#cqmachao"] = "卷土汉中",
    ["designer:cqmachao"] = "Nyarz",

    ["cqtieji"] = "铁骑",
    [":cqtieji"] = "当你使用【杀】指定目标后，你可以令其所有非锁定技失效直到当前回合结束，其不能使用【闪】响应此【杀】。\
    其他角色受到你造成的伤害后，其与你计算距离时+1直到你的下个回合开始。\
    搏击：依次获得其共计两张牌。",
    ["cqchangqu"] = "长驱",
    [":cqchangqu"] = "结束阶段，你可以选择一名角色,然后亮出牌堆顶的X+2张牌（X为攻击范围内不包含你的角色数），对该角色依次使用这些牌中的【杀】。\
    游击：获得剩余的全部基本牌和锦囊牌。",
    ["@cqchangqu"] = "你可以选择一名角色并对其使用牌堆顶的 %src 张牌中的【杀】",
    ["$cqmachaospecial"] = "%arg 的 %arg2 效果被触发。",
    ["cqchangquyouji"] = "游击",
    ["cqtiejiboji"] = "搏击",
    ["$cqtiejidistance"] = "现在 %arg 与 %arg2 计算距离时因 %arg3 的效果须 +%arg4 。",

    ["$cqtieji1"] = "铁骑",
    ["$cqtieji2"] = "铁骑",
    ["$cqchangqu1"] = "长驱",
    ["$cqchangqu2"] = "长驱",
    ["~cqmachao"] = "群阴·马超",

--族钟会
    ["yzzhonghui"] = "群阴·族钟会",
    ["&yzzhonghui"] = "钟会",
    ["#yzzhonghui"] = "纵恣挥军",
    ["designer:yzzhonghui"] = "Nyarz",

    ["yzyuzhi"] = "迂志",
    [":yzyuzhi"] = "锁定技，一轮游戏开始时，你展示一张手牌并摸相当于牌名字数两倍数量的牌。\
    本轮结束时，若你本轮造成的伤害小于所展示的牌名字数，你失去相当于差值的体力。",
    ["$yzyuzhinotcard"] = "%from 胸无大志，决定在本轮游戏中碌碌无为。",
    ["$yzyuzhicard"] = "%from 发动 %arg 确定的志向是于本轮游戏内造成至少 %arg2 点伤害。",
    ["$yzyuzhineed"] = "%from 离完成志向还缺少 %arg 点伤害。",
    ["$yzyuzhicomplete"] = "%from 完成了志向。",
    ["@yzyuzhi"] = "请展示一张手牌以确立“迂志”目标",
    ["$yzyuzhifailed"] = "%from 的志向失败了。（仍需 %arg 点伤害）",
    ["yzxieshu"] = "挟术",
    [":yzxieshu"] = "每回合每种牌名字数限一次，当你造成或受到游戏牌的伤害后，你可以弃置相当于牌名字数的牌并摸相当于你已损失体力值的牌，然后你回复一点体力或对一名其他角色造成1点伤害。",
    ["@yzxieshu"] = "你可以弃置%src张牌并摸%arg张牌，然后你回复一点体力或对一名其他角色造成1点伤害",


    ["$yzyuzhi1"] = "迂志",
    ["$yzyuzhi2"] = "迂志",
    ["$yzxieshu"] = "挟术",
    ["$yzxieshu"] = "挟术",
    ["~yzzhonghui"] = "群阴·族钟会",


--黄忠
    ["lghuangzhong"] = "群阴·黄忠",
    ["&lghuangzhong"] = "黄忠",
    ["#lghuangzhong"] = "没金饮羽",
    ["designer:lghuangzhong"] = "Nyarz",

    ["lgliegong"] = "烈弓",
    [":lgliegong"] = "当你使用【杀】指定目标后，你可以令其不能使用【闪】响应此【杀】。此【杀】对其造成伤害时，你与其依次比较手牌数、体力值和装备区牌数，每有一项不大于该角色，此【杀】伤害便+1。\
    游击：令其本回合不能使用基本牌。\
    准备阶段，你可以弃置任意张牌并从牌堆中获得一张【杀】。结束阶段，你摸等量的牌。\
    你使用【杀】无距离限制。",
    ["$lgliegonglimit"] = "%from 因 %arg 的效果本回合不能再使用基本牌。",
    ["$lgliegongdamage"] = "%from 对 %arg 造成的伤害因 %arg2 的效果由 %arg3 点增加到 %arg4 点。",
    ["@lgliegong"] = "你可以弃置任意张牌并从牌堆中获得一张【杀】,然后于当前回合的结束阶段摸等量的牌。",

    ["$lgliegong1"] = "烈弓",
    ["$lgliegong2"] = "烈弓",
    ["~lghuangzhong"] = "群阴·黄忠",
}

return packages