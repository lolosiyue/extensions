extension = sgs.Package("sgs10th", sgs.Package_GeneralPack)
local packages = {}
table.insert(packages, extension)
--local json = require ("json")

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

local function CreateDamageLog(damage, changenum, reason, up)
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
    if up~=false then
        log.arg3 = "nyarzdamageup"
        log.arg4 = damage.damage + changenum
    else
        log.arg3 = "nyarzdamagedown"
        log.arg4 = damage.damage - changenum
    end
    return log
end

ny_10th_xujing = sgs.General(extension, "ny_10th_xujing", "shu", 3, true, false, false)

ny_10th_caixia = sgs.CreateTriggerSkill{
    name = "ny_10th_caixia",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getMark("&ny_10th_caixia") == 0 then return false end
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            room:removePlayerMark(player, "&ny_10th_caixia", 1)
        end
        if event == sgs.Damage or event == sgs.Damaged then
            if player:isDead() then return false end
            if player:getMark("&ny_10th_caixia") > 0 then return false end
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local all = room:getAllPlayers(true):length()
                all = math.min(5,all)
                local choices = {}
                for i = 1, all, 1 do
                    table.insert(choices, string.format("%d",i))
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                local n = tonumber(choice)
                room:addPlayerMark(player, "&ny_10th_caixia", n)
                player:drawCards(n, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shangyu = sgs.CreateTriggerSkill{
    name = "ny_10th_shangyu",
    events = {sgs.GameStart,sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("Slash") then
                    room:setPlayerMark(player, "ny_10th_shangyu_slash", id)
                    room:obtainCard(player, card, true)
                    room:setCardTip(id, "ny_10th_shangyu")
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@ny_10th_shangyu", false, true)
                    if target:objectName() ~= player:objectName() then
                        room:obtainCard(target, card, true)
                        room:setCardTip(id, "ny_10th_shangyu")
                    end
                    break
                end
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not player:hasSkill(self:objectName()) then return false end
            if player:isDead() then return false end
            if move.to_place == sgs.Player_DiscardPile then
                for _,id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if player:getMark("ny_10th_shangyu_slash") == id then
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        local all = sgs.SPlayerList()
                        for _,p in sgs.qlist(room:getAlivePlayers()) do
                            if p:getMark("ny_10th_shangyu_"..player:objectName().."-Clear") == 0 then
                                all:append(p)
                            end
                        end
                        if all:isEmpty() then return false end
                        local give = room:askForPlayerChosen(player, all, self:objectName(), "@ny_10th_shangyu", false, true)
                        room:setPlayerMark(give, "ny_10th_shangyu_"..player:objectName().."-Clear", 1)
                        room:obtainCard(give, id, true)
                        room:clearCardTip(id)
                        room:setCardTip(id, "ny_10th_shangyu")
                        break
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shangyu_damage = sgs.CreateTriggerSkill{
    name = "#ny_10th_shangyu_damage",
    events = {sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.card then
            for _,p in sgs.qlist(room:findPlayersBySkillName("ny_10th_shangyu")) do
                if p:getMark("ny_10th_shangyu_slash") == damage.card:getId() then
                    room:sendCompulsoryTriggerLog(p, "ny_10th_shangyu", true, true)
                    damage.from:drawCards(1, "ny_10th_shangyu")
                    p:drawCards(1, "ny_10th_shangyu")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_xujing:addSkill(ny_10th_shangyu)
ny_10th_xujing:addSkill(ny_10th_shangyu_damage)
ny_10th_xujing:addSkill(ny_10th_caixia)
extension:insertRelatedSkills("ny_10th_shangyu", "#ny_10th_shangyu_damage")

ny_10th_lezhoufei = sgs.General(extension, "ny_10th_lezhoufei", "wu", 3, false, false, false)

ny_10th_lingkong = sgs.CreateTriggerSkill{
    name = "ny_10th_lingkong",
    events = {sgs.GameStart,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            for _,card in sgs.qlist(player:getHandcards()) do
                room:setCardFlag(card, "ny_10th_konghou")
                room:setCardTip(card:getId(), "ny_10th_konghou")
            end
        end
        if event == sgs.CardsMoveOneTime then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local ids = sgs.QList2Table(move.card_ids)
                local id = ids[math.random(1,#ids)]
                room:setCardFlag(sgs.Sanguosha:getCard(id), "ny_10th_konghou")
                room:setCardTip(id, "ny_10th_konghou")
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_10th_konghou") then
                        room:clearCardTip(card:getId())
                        room:setCardTip(card:getId(), "ny_10th_konghou")
                        room:ignoreCards(player, card)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_xianshu = sgs.CreateViewAsSkill
{
    name = "ny_10th_xianshu",
    n = 99,
    view_filter = function(self, selected, to_select)
        return to_select:hasFlag("ny_10th_konghou") and #selected == 0
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = ny_10th_xianshuCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = true,
}

ny_10th_xianshuCard = sgs.CreateSkillCard
{
    name = "ny_10th_xianshu",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets == 0 and player:objectName() ~= to_select:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local id = self:getSubcards():first()
        room:showCard(effect.from, id)
        room:obtainCard(effect.to, id, true)
        local card = sgs.Sanguosha:getCard(id)
        if card:isRed() and effect.to:getHp() <= effect.from:getHp() then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, 1))
        elseif card:isBlack() and effect.to:getHp() >= effect.from:getHp() then
            room:loseHp(effect.to, 1, true, effect.from, self:objectName())
        end
        if effect.to:isAlive() and effect.from:isAlive() then
            local n = effect.to:getHp() - effect.from:getHp()
            n = math.abs(n)
            n = math.min(n,5)
            effect.from:drawCards(n, self:objectName())
        end
    end
}

ny_10th_lezhoufei:addSkill(ny_10th_lingkong)
ny_10th_lezhoufei:addSkill(ny_10th_xianshu)

ny_10th_donghuan = sgs.General(extension, "ny_10th_donghuan", "qun", 3, false, false, false)

ny_10th_shengdu = sgs.CreateTriggerSkill{
    name = "ny_10th_shengdu",
    events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_RoundStart then return false end
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ny_10th_shengdu", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(target, "&ny_10th_shengdu", 1)
                room:setPlayerMark(target, "ny_10th_shengdu_from_"..player:objectName(), 1)
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:getPhase() == sgs.Player_Draw and move.to_place == sgs.Player_PlaceHand then
                if move.to:getMark("ny_10th_shengdu_from_"..player:objectName()) > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    player:drawCards(move.card_ids:length(), self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shengdu_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_shengdu_clear",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Draw and player:getMark("&ny_10th_shengdu") > 0 then
            room:setPlayerMark(player, "&ny_10th_shengdu", 0)
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(player, "ny_10th_shengdu_from_"..p:objectName(), 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_jieling = sgs.CreateViewAsSkill
{
    name = "ny_10th_jieling",
    n = 99,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return sgs.Self:getHandcards():contains(to_select)
        elseif #selected == 1 then
            return sgs.Self:getHandcards():contains(to_select) and (not to_select:sameColorWith(selected[1]))
        else
            return false
        end
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local cc = ny_10th_jielingCard:clone()
            cc:addSubcard(cards[1])
            cc:addSubcard(cards[2])
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_jieling")
    end,
}

ny_10th_jielingCard = sgs.CreateSkillCard
{
    name = "ny_10th_jieling",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        slash:addSubcards(self:getSubcards())

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        slash:deleteLater()
        return slash:targetFilter(qtargets, to_select, player)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        slash:addSubcards(self:getSubcards())
        slash:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return slash:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        slash:addSubcards(self:getSubcards())
        room:setCardFlag(slash, "RemoveFromHistory")
        room:setCardFlag(slash, "ny_10th_jieling_slash")
        slash:deleteLater()
        return slash
    end,
}

ny_10th_jieling_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_jieling_buff",
    events = {sgs.CardFinished,sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ny_10th_jieling_slash") then
                room:setCardFlag(damage.card, "ny_10th_jieling_success")
                if damage.to:isAlive() then
                    room:sendCompulsoryTriggerLog(player, "ny_10th_jieling", true)
                    room:loseHp(damage.to, 1, true, player, self:objectName())
                end
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            local card = use.card
            if table.contains(use.card:getSkillNames(),"ny_10th_jieling") and (not card:hasFlag("ny_10th_jieling_success")) then
                room:sendCompulsoryTriggerLog(player, "ny_10th_jieling", true)
                local log = sgs.LogMessage()
                log.type = "#ChoosePlayerWithSkill"
                log.from = player
                log.arg = "ny_10th_shengdu"
                log.to = use.to
                room:sendLog(log)
                room:broadcastSkillInvoke("ny_10th_shengdu")

                for _,target in sgs.qlist(use.to) do
                    if target:isAlive() then
                        room:setPlayerMark(target, "&ny_10th_shengdu", 1)
                        room:setPlayerMark(target, "ny_10th_shengdu_from_"..player:objectName(), 1)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jieling_target = sgs.CreateTargetModSkill{
    name = "#ny_10th_jieling_target",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_10th_jieling" then return 1000 end 
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_10th_jieling" then return 1000 end 
        return 0
    end,
}

ny_10th_donghuan:addSkill(ny_10th_shengdu)
ny_10th_donghuan:addSkill(ny_10th_shengdu_clear)
ny_10th_donghuan:addSkill(ny_10th_jieling)
ny_10th_donghuan:addSkill(ny_10th_jieling_buff)
ny_10th_donghuan:addSkill(ny_10th_jieling_target)
extension:insertRelatedSkills("ny_10th_shengdu", "#ny_10th_shengdu_clear")
extension:insertRelatedSkills("ny_10th_jieling", "#ny_10th_jieling_buff")
extension:insertRelatedSkills("ny_10th_jieling", "#ny_10th_jieling_target")

ny_10th_gaoxiang = sgs.General(extension, "ny_10th_gaoxiang", "shu", 4, true, false, false)

ny_10th_chiying = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_chiying",
    view_as = function(self)
        return ny_10th_chiyingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_chiying")
    end
}

ny_10th_chiyingCard = sgs.CreateSkillCard
{
    name = "ny_10th_chiying",
    filter = function(self, targets, to_select,player)
        return to_select:getHp() <= player:getHp() and #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local get = sgs.Sanguosha:cloneCard("jink")
        get:deleteLater()
        local will = false
        if effect.from ~= effect.to then will = true end
        
        for _,other in sgs.qlist(room:getOtherPlayers(effect.to)) do
            if effect.from ~= other and effect.to:inMyAttackRange(other) and (not other:isNude()) then
                local card = room:askForDiscard(other, self:objectName(), 1, 1, false, true)
                if will then
                    if sgs.Sanguosha:getCard(card:getSubcards():first()):isKindOf("BasicCard") then
                        get:addSubcard(card)
                    end
                end
            end
        end

        if effect.to:isAlive() and will and get:subcardsLength() > 0 then
            room:obtainCard(effect.to, get, true)
        end
    end,
}

ny_10th_gaoxiang:addSkill(ny_10th_chiying)

ny_10th_wangrui = sgs.General(extension, "ny_10th_wangrui", "qun", 4, true, false, false)

ny_10th_tongye = sgs.CreateTriggerSkill{
    name = "ny_10th_tongye",
    events = {sgs.GameStart,sgs.Death,sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart or event == sgs.Death then
            if event == sgs.Death then
                local death = data:toDeath()
                if death.who:objectName() == player:objectName() then return false end
            end

            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local kingdoms = {}
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                local kingdom = p:getKingdom()
                if not table.contains(kingdoms,kingdom) then
                    table.insert(kingdoms,kingdom)
                end
            end

            local log = sgs.LogMessage()
            log.type = "$ny_10th_tongye_kingdoms"
            log.arg = #kingdoms
            room:sendLog(log)

            room:setPlayerMark(player, "&ny_10th_tongye", #kingdoms)
        end

        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            if player:getMark("&ny_10th_tongye") == 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local log = sgs.LogMessage()
                log.type = "$ny_10th_tongye_draw"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = 3
                room:sendLog(log)

                draw.num = draw.num + 3
                data:setValue(draw)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_tongye_maxcards = sgs.CreateMaxCardsSkill
{
    name = "#ny_10th_tongye_maxcards",
    extra_func = function(self, target)
        if target:hasSkill("ny_10th_tongye") and target:getMark("&ny_10th_tongye") <= 4 
        and target:getMark("&ny_10th_tongye") > 0 then return 3 end
        return 0
    end,
}

ny_10th_tongye_range = sgs.CreateAttackRangeSkill
{
    name = "#ny_10th_tongye_range",
    extra_func = function(self, target, include_weapon)
        if target:hasSkill("ny_10th_tongye") and target:getMark("&ny_10th_tongye") <= 3 
        and target:getMark("&ny_10th_tongye") > 0 then return 3 end
        return 0
    end,
}

ny_10th_tongye_slash = sgs.CreateTargetModSkill
{
    name = "#ny_10th_tongye_slash",
    residue_func = function(self, target, card)
        if target:hasSkill("ny_10th_tongye") and target:getMark("&ny_10th_tongye") <= 2 
        and target:getMark("&ny_10th_tongye") > 0 then return 3 end
        return 0
    end,
}

ny_10th_changqu = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_changqu",
    view_as = function(self)
        return ny_10th_changquCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_changqu")
    end,
}

ny_10th_changquCard = sgs.CreateSkillCard
{
    name = "ny_10th_changqu",
    filter = function(self, targets, to_select,player)
       return player:isAdjacentTo(to_select) and #targets == 0
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local move = 1
        if source:getNextAlive(1):objectName() ~= targets[1]:objectName() then move = room:getAlivePlayers():length() - 1 end

        if move > 0 then 
            room:setPlayerMark(source, "ny_10th_changqu_right", 1)
        else
            room:setPlayerMark(source, "ny_10th_changqu_right", 0)
        end

        local finish = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "@ny_10th_changqu", false, false)
        local log = sgs.LogMessage()
        log.type = "$ny_10th_changqu_finish"
        log.to:append(finish)
        room:sendLog(log)

        local n = 0
        local now = targets[1]
        while(true) do
            local get_num = math.max(n,1)
            local prompt
            if now:objectName() == finish:objectName() then
                prompt = string.format("ny_10th_changqu_finish:%s::%d:", source:getGeneralName(), get_num)
            else
                prompt = string.format("ny_10th_changqu_move:%s::%d:",source:getGeneralName(), get_num)
            end
            local get = room:askForExchange(now, self:objectName(), get_num, get_num, false, prompt, true)
            if get and get:subcardsLength() > 0 then
                room:obtainCard(source, get, false)
                n = n + 1
                if now:objectName() ~= finish:objectName() then
                    now = now:getNextAlive(move)
                else
                    break
                end
            else
                room:addPlayerMark(now, "&ny_10th_changqu", get_num)
                local log2 = sgs.LogMessage()
                log2.type = "$ny_10th_changqu_willdamgage"
                log2.from = now
                log2.arg = get_num
                room:sendLog(log2)
                room:setPlayerChained(now, true)
                break
            end
        end
    end
}

ny_10th_changqu_damage = sgs.CreateTriggerSkill{
    name = "#ny_10th_changqu",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.nature ~= sgs.DamageStruct_Normal then
            room:broadcastSkillInvoke("ny_10th_changqu")
            local log = sgs.LogMessage()
            log.type = "$ny_10th_changqu_damage"
            log.from = player
            log.arg = "ny_10th_changqu"
            log.arg2 = damage.damage
            log.arg3 = damage.damage + player:getMark("&ny_10th_changqu")
            room:sendLog(log)
            damage.damage= damage.damage + player:getMark("&ny_10th_changqu")
            room:setPlayerMark(player, "&ny_10th_changqu", 0)
            data:setValue(damage)
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&ny_10th_changqu") > 0
    end,
}

ny_10th_wangrui:addSkill(ny_10th_tongye)
ny_10th_wangrui:addSkill(ny_10th_tongye_maxcards)
ny_10th_wangrui:addSkill(ny_10th_tongye_range)
ny_10th_wangrui:addSkill(ny_10th_tongye_slash)
ny_10th_wangrui:addSkill(ny_10th_changqu)
ny_10th_wangrui:addSkill(ny_10th_changqu_damage)
extension:insertRelatedSkills("ny_10th_tongye","#ny_10th_tongye_maxcards")
extension:insertRelatedSkills("ny_10th_tongye","#ny_10th_tongye_range")
extension:insertRelatedSkills("ny_10th_tongye","#ny_10th_tongye_slash")
extension:insertRelatedSkills("ny_10th_changqu","#ny_10th_changqu_damage")

ny_10th_dongxie = sgs.General(extension, "ny_10th_dongxie", "qun", 4, false, false, false)

ny_10th_jiaoxia = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_jiaoxia",
    response_pattern = "@@ny_10th_jiaoxia",
    view_as = function(self)
        local card = sgs.Sanguosha:getCard(sgs.Self:getMark("ny_10th_jiaoxia_card"))
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

ny_10th_jiaoxia_trigger = sgs.CreateTriggerSkill
{
    name = "ny_10th_jiaoxia",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.EventLoseSkill,sgs.Damage,sgs.CardFinished,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_10th_jiaoxia,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("ny_10th_jiaoxia_damage") then
                room:setCardFlag(use.card, "-ny_10th_jiaoxia_damage")
                local card_id = use.card:getId()
                local card = sgs.Sanguosha:getCard(card_id)
                room:setPlayerMark(player, "ny_10th_jiaoxia_card", card_id)
                if card:isAvailable(player) then
                    room:askForUseCard(player, "@@ny_10th_jiaoxia", "@ny_10th_jiaoxia:"..card:objectName())
                    
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("slash")) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "&ny_10th_jiaoxia-PlayClear", 1)
                if not player:hasSkill("ny_10th_jiaoxia_filter") then
                    room:acquireSkill(player, "ny_10th_jiaoxia_filter", false)
                end
                room:filterCards(player, player:getCards("h"), true)
            end
        end
        if event == sgs.EventPhaseEnd or event == sgs.EventLoseSkill then
            if event == sgs.EventPhaseEnd and player:getPhase() ~= sgs.Player_Play then return false end
            room:setPlayerMark(player, "&ny_10th_jiaoxia-PlayClear", 0)
            room:filterCards(player, player:getCards("h"), true)
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and table.contains(damage.card:getSkillNames(),"ny_10th_jiaoxia") then
                room:setCardFlag(damage.card, "ny_10th_jiaoxia_damage")
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _,p in sgs.qlist(use.to) do
                    room:setPlayerMark(p, "ny_10th_jiaoxia_used-PlayClear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jiaoxia_filter = sgs.CreateFilterSkill{
    name = "ny_10th_jiaoxia_filter",
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
        local player = room:getCardOwner(to_select:getEffectiveId())
		return (place == sgs.Player_PlaceHand) and player:getMark("&ny_10th_jiaoxia-PlayClear") > 0
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("ny_10th_jiaoxia")
		local _card = sgs.Sanguosha:getWrappedCard(card:getId())
		_card:takeOver(slash)
		return _card
    end,
}

ny_10th_jiaoxia_buff = sgs.CreateTargetModSkill
{
    name = "#ny_10th_jiaoxia_buff",
    residue_func = function(self, from, card, to)
        if from:hasSkill("ny_10th_jiaoxia") and to and to:getMark("ny_10th_jiaoxia_used-PlayClear") == 0 then return 1000 end
        return 0
    end,
}

ny_10th_humei = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_humei",
    tiansuan_type = "draw,give,recover",
    view_as = function(self)
        local cc = ny_10th_humeiCard:clone()
        cc:setUserString(sgs.Self:getTag("ny_10th_humei"):toString())
        return cc
    end,
    enabled_at_play = function(self, player)
        local choices = {"draw", "give", "recover"}
        for _,p in ipairs(choices) do
            if player:getMark("ny_10th_humei_tiansuan_remove_"..p.."-PlayClear") == 0 then
                return true
            end
        end
    end,
}

ny_10th_humeiCard = sgs.CreateSkillCard
{
    name = "ny_10th_humei",
    filter = function(self, targets, to_select,player)
        local choice = self:getUserString()
        if choice == "give" and to_select:isNude() then return false end
        if choice == "give" and to_select:objectName() == player:objectName() then return false end
        if choice == "recover" and (not to_select:isWounded()) then return false end
        return to_select:getHp() <= player:getMark("&ny_10th_humei-PlayClear") and #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choice = self:getUserString()
        room:setPlayerMark(effect.from, "ny_10th_humei_tiansuan_remove_"..choice.."-PlayClear", 1)
        if choice == "draw" then
            effect.to:drawCards(1, self:objectName())
        end
        if choice == "give" then
            local obtain = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "@ny_10th_humei:"..effect.from:getGeneralName(), false)
            room:obtainCard(effect.from, obtain, false)
        end
        if choice == "recover" then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
        end
    end
}

ny_10th_humei_damage = sgs.CreateTriggerSkill{
    name = "#ny_10th_humei_damage",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:addPlayerMark(player, "&ny_10th_humei-PlayClear", 1)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
        and target:isAlive() and target:getPhase() == sgs.Player_Play
    end,
}

ny_10th_dongxie:addSkill(ny_10th_jiaoxia_trigger)
ny_10th_dongxie:addSkill(ny_10th_jiaoxia)
ny_10th_dongxie:addSkill(ny_10th_jiaoxia_buff)
ny_10th_dongxie:addSkill(ny_10th_humei)
ny_10th_dongxie:addSkill(ny_10th_humei_damage)
extension:insertRelatedSkills("ny_10th_jiaoxia","#ny_10th_jiaoxia_buff")
extension:insertRelatedSkills("ny_10th_humei","#ny_10th_humei_damage")

ny_10th_peiyuanshao = sgs.General(extension, "ny_10th_peiyuanshao", "qun", 4, true, false, false)

ny_10th_moyu = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_moyu",
    view_as = function(self)
        return ny_10th_moyuCard:clone()
    end,
    enabled_at_play = function(self,player)
        return player:getMark("ny_10th_moyu_damage-Clear") == 0
    end
}

ny_10th_moyuCard = sgs.CreateSkillCard
{
    name = "ny_10th_moyu",
    filter = function(self, targets, to_select,player)
        return to_select:objectName() ~= player:objectName() and (not to_select:isAllNude()) 
        and to_select:getMark("ny_10th_moyu_chosen-PlayClear") == 0 and #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = room:askForCardChosen(effect.from, effect.to, "hej", self:objectName())
        room:obtainCard(effect.from, card, false)
        room:addPlayerMark(effect.from, "&ny_10th_moyu-Clear", 1)
        room:addPlayerMark(effect.to,"ny_10th_moyu_chosen-PlayClear", 1)
        local prompt = string.format("@ny_10th_moyu:%s::%s:", effect.from:getGeneralName(), effect.from:getMark("&ny_10th_moyu-Clear"))
        room:askForUseSlashTo(effect.to, effect.from, prompt, false, false, false, effect.from, self, "ny_10th_moyu_slash")
    end
}

ny_10th_moyu_damage = sgs.CreateTriggerSkill{
    name = "#ny_10th_moyu_damage",
    events = {sgs.DamageInflicted, sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ny_10th_moyu_slash") then
                if player:getMark("&ny_10th_moyu-Clear") > 1 then
                    local log = sgs.LogMessage()
                    log.type = "$ny_10th_moyu_damage_add"
                    log.from = player
                    log.arg = "ny_10th_moyu"
                    log.arg2 = damage.damage
                    log.arg3 = damage.damage + player:getMark("&ny_10th_moyu-Clear") - 1
                    room:sendLog(log)

                    damage.damage = damage.damage + player:getMark("&ny_10th_moyu-Clear") - 1
                    data:setValue(damage)
                end
            end
        end
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ny_10th_moyu_slash") then
                if player:isAlive() then
                    room:setPlayerMark(player, "ny_10th_moyu_damage-Clear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_peiyuanshao:addSkill(ny_10th_moyu)
ny_10th_peiyuanshao:addSkill(ny_10th_moyu_damage)
extension:insertRelatedSkills("ny_10th_moyu", "#ny_10th_moyu_damage")

ny_10th_sunlinluan = sgs.General(extension, "ny_10th_sunlinluan", "wu", 3, false, false, false)

ny_10th_lingyue = sgs.CreateTriggerSkill{
    name = "ny_10th_lingyue",
    events = {sgs.Damage, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            room:setTag("ny_10th_lingyue_damage", sgs.QVariant(0))
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            local sum = room:getTag("ny_10th_lingyue_damage"):toInt()
            if (not sum) or sum == 0 then sum = damage.damage 
            else sum = sum + damage.damage end
            room:setTag("ny_10th_lingyue_damage", sgs.QVariant(sum))

            if player:getMark("ny_10th_lingyue_first_lun") == 0 then
                room:setPlayerMark(player, "ny_10th_lingyue_first_lun", 1)
                local draw = 1
                if player:getPhase() == sgs.Player_NotActive then draw = sum end
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:isAlive() then
                        room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                        p:drawCards(draw, self:objectName())
                        room:getThread():delay(500)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_pandi_tenth = sgs.CreateViewAsSkill
{
    name = "ny_pandi_tenth",
    n = 1,
    response_pattern = "@@ny_pandi_tenth",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_pandi_tenth_using") and not to_select:isEquipped() then
            for _,other in sgs.qlist(sgs.Self:getAliveSiblings()) do
                if other:hasFlag("ny_pandi_tenth_target") then
					return to_select:isAvailable(other)
                end
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("ny_pandi_tenth_using") then
            if #cards == 1 then
                local cc = ny_pandi_tenth_useCard:clone()
                cc:addSubcard(cards[1])
                return cc
            end
        else
                return ny_pandi_tenthCard:clone()
            end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("ny_pandi_tenth_notcard-PlayClear") == 0
    end,
}

ny_pandi_tenthCard = sgs.CreateSkillCard
{
    name = "ny_pandi_tenth",
    filter = function(self, targets, to_select,player)
        return #targets == 0 and to_select ~= player
        and to_select:getMark("ny_pandi_tenth_damage-Clear") == 0
    end,
    on_use = function(self, room, source, targets)
        room:setPlayerFlag(source, "ny_pandi_tenth_using")
        room:setPlayerFlag(targets[1], "ny_pandi_tenth_target")
        room:askForUseCard(source, "@@ny_pandi_tenth", "@ny_pandi_tenth:"..targets[1]:getGeneralName())
        room:setPlayerFlag(source, "-ny_pandi_tenth_using")
        room:setPlayerFlag(targets[1], "-ny_pandi_tenth_target")
    end
}

ny_pandi_tenth_useCard = sgs.CreateSkillCard
{
    name = "ny_pandi_tenth_use",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card:targetFixed() then return false end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:hasFlag("ny_pandi_tenth_target") then
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
                return card:targetFilter(qtargets, to_select, other)
            end
        end
        return false 
	end,
    target_fixed = function(self)		
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
        return card:targetFixed()
	end,
	feasible = function(self, targets,player)	
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card:targetFixed() then return true end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:hasFlag("ny_pandi_tenth_target") then
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
                return card:targetsFeasible(qtargets, other)
            end
        end
        return false
	end,
	on_validate = function(self,use)
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		local room = use.from:getRoom()
        for _,other in sgs.qlist(room:getAlivePlayers()) do
            if other:hasFlag("ny_pandi_tenth_target") then
				use.from = other
        end
        end
        return card
    end,
}

ny_pandi_tenth_damage = sgs.CreateTriggerSkill{
    name = "#ny_pandi_tenth_damage",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:setPlayerMark(player, "ny_pandi_tenth_damage-Clear", 1)
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_sunlinluan:addSkill(ny_10th_lingyue)
ny_10th_sunlinluan:addSkill(ny_pandi_tenth)
ny_10th_sunlinluan:addSkill(ny_pandi_tenth_damage)
extension:insertRelatedSkills("ny_pandi_tenth", "#ny_pandi_tenth_damage")

ny_10th_lelin = sgs.General(extension, "ny_10th_lelin", "wei", 4, true, false, false)

ny_tenth_poruiVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_porui",
    n = 1,
    response_pattern = "@@ny_tenth_porui",
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end,
    view_as = function(self, cards)
        if #cards == 1 then 
            local cc = ny_tenth_poruiCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = false,
}

ny_tenth_poruiCard = sgs.CreateSkillCard
{
    name = "ny_tenth_porui",
    will_throw = true,
    filter = function(self, targets, to_select,player)
        return to_select:objectName() ~= player:objectName() and to_select:getMark("&ny_tenth_porui-Clear") > 0
        and to_select:getPhase() == sgs.Player_NotActive
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:addPlayerMark(source, "ny_tenth_porui_used_lun", 1)
        local target = targets[1]
        local n = target:getMark("&ny_tenth_porui-Clear")
        n = math.min(n,5)
        for i = 1, n+1, 1 do
            if source:isDead() or target:isDead() then break end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("_ny_tenth_porui")
            if not source:isProhibited(target, slash) then
                room:useCard(sgs.CardUseStruct(slash, source, target, true))
                room:getThread():delay(500)
            else
                break
            end
			slash:deleteLater()
        end
        if source:isAlive() and target:isAlive() and source:getMark("ny_10th_gonghu_damage") == 0 then
            local prompt = string.format("ny_tenth_porui_give:%s::%s:", target:getGeneralName(), n)
            local give = room:askForExchange(source, self:objectName(), n, n, false, prompt, false)
            if give then
                room:obtainCard(target, give, false)
            end
        end
    end
}


ny_tenth_porui = sgs.CreateTriggerSkill{
    name = "ny_tenth_porui",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_poruiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Finish then return false end
        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:getPhase() ~= sgs.Player_Finish 
            and ((p:getMark("ny_tenth_porui_used_lun") < 1) 
            or (p:getMark("ny_tenth_porui_used_lun") < 2 and p:getMark("ny_10th_gonghu_lose") > 0)) then
                room:askForUseCard(p, "@@ny_tenth_porui", "@ny_tenth_porui")
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_tenth_porui_lose = sgs.CreateTriggerSkill{
    name = "#ny_tenth_porui_lose",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then else return false end
        if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then else return false end
        local num = move.card_ids:length()
        room:addPlayerMark(player, "&ny_tenth_porui-Clear", num, room:findPlayersBySkillName("ny_tenth_porui"))
    end,
    can_trigger = function(self, target)
        local room = target:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        return target:getPhase() == sgs.Player_NotActive
    end,
}

ny_10th_gonghu = sgs.CreateTriggerSkill{
    name = "ny_10th_gonghu",
    events = {sgs.CardsMoveOneTime, sgs.Damage, sgs.Damaged, sgs.CardUsed, sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if player:getMark("ny_10th_gonghu_lose") > 0 then return false end
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then else return false end
            if move.from_places:contains(sgs.Player_PlaceHand) then else return false end
            local n = player:getMark("ny_10th_gonghu_lose_count-Clear")
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                    n = n + 1
                end
                if n >= 2 then break end
            end
            if n >= 2 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "ny_10th_gonghu_lose", 1)
                if player:getMark("ny_10th_gonghu_damage") == 0 then
                    room:changeTranslation(player, "ny_tenth_porui", 1)
                else
                    room:changeTranslation(player, "ny_tenth_porui", 3)
                end
            else
                room:setPlayerMark(player, "ny_10th_gonghu_lose_count-Clear", n)
            end
        end
        if event == sgs.Damage or event == sgs.Damaged then
            if player:getMark("ny_10th_gonghu_damage") > 0 then return false end
            local n = player:getMark("ny_10th_gonghu_damage_count-Clear")
            local damage = data:toDamage()
            n = n + damage.damage
            if n >= 2 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "ny_10th_gonghu_damage", 1)
                if player:getMark("ny_10th_gonghu_lose") == 0 then
                    room:changeTranslation(player, "ny_tenth_porui", 2)
                else
                    room:changeTranslation(player, "ny_tenth_porui", 3)
                end
            else
                room:setPlayerMark(player, "ny_10th_gonghu_damage_count-Clear", n)
            end
        end
        if event == sgs.CardUsed then
            if player:getMark("ny_10th_gonghu_damage") == 0
            or player:getMark("ny_10th_gonghu_lose") == 0 then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("BasicCard") and use.card:isRed() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

                local log = sgs.LogMessage()
                log.type = "$ny_10th_gonghu_noresponse"
                log.from = player
                log.arg = self:objectName()
                log.card_str = use.card:toString()
                room:sendLog(log)

                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        if event == sgs.PreCardUsed then
            if player:getMark("ny_10th_gonghu_damage") == 0
            or player:getMark("ny_10th_gonghu_lose") == 0 then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") and use.card:isRed() and use.card:isNDTrick() then
                local targets = room:getCardTargets(player, use.card, use.to)
                if not targets:isEmpty() then
                    room:setPlayerMark(player, "ny_10th_gonghu_card", use.card:getId())

                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_gonghu:"..use.card:objectName(), true, false)
                    if target then 
                        room:broadcastSkillInvoke(self:objectName())
                        use.to:append(target)
                        data:setValue(use)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ny_10th_lelin:addSkill(ny_tenth_porui)
ny_10th_lelin:addSkill(ny_tenth_poruiVS)
ny_10th_lelin:addSkill(ny_tenth_porui_lose)
ny_10th_lelin:addSkill(ny_10th_gonghu)
extension:insertRelatedSkills("ny_tenth_porui", "#ny_tenth_porui_lose")

ny_10th_duyu = sgs.General(extension, "ny_10th_duyu", "wei", 4, true, false, false)

ny_10th_jianguo = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_jianguo",
    view_as = function(self)
        return ny_10th_jianguoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_jianguo")
    end,
}

ny_10th_jianguoCard = sgs.CreateSkillCard
{
    name = "ny_10th_jianguo",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choices = "draw+dis"
        local _data = sgs.QVariant()
        _data:setValue(effect.to)
        local choice = room:askForChoice(effect.from, self:objectName(), choices, _data)
        if choice == "draw" then
            room:askForDiscard(effect.to, self:objectName(), 1, 1, false, true)
            if effect.to:isAlive() then
                effect.to:drawCards(math.floor(effect.to:getHandcardNum()/2), self:objectName())
            end
        elseif choice == "dis" then
            effect.to:drawCards(1, self:objectName())
            if effect.to:isAlive() then
                room:askForDiscard(effect.to, self:objectName(), math.floor(effect.to:getHandcardNum()/2), math.floor(effect.to:getHandcardNum()/2), false, false)
            end
        end
    end
}

ny_10th_qinshi = sgs.CreateTriggerSkill{
    name = "ny_10th_qinshi",
    events = {sgs.CardUsed, sgs.CardResponded,sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event ~= sgs.TargetConfirmed then
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card and (not card:isKindOf("SkillCard")) then
                room:addPlayerMark(player, "&ny_10th_qinshi-Clear", 1)
            end
        end
        if event == sgs.TargetConfirmed then
            if player:getMark("&ny_10th_qinshi-Clear") ~= player:getHandcardNum() then return false end
            local targets = sgs.SPlayerList()
            local use = data:toCardUse()
            if use.from ~= player then return false end
            if use.card:isKindOf("SkillCard") then return false end
            for _,p in sgs.qlist(use.to) do
                if p:objectName() ~= player:objectName() then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_qinshi", true, true)
            if target then 
                room:broadcastSkillInvoke(self:objectName())
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() ~= sgs.Player_NotActive
    end,
}

ny_10th_duyu:addSkill(ny_10th_jianguo)
ny_10th_duyu:addSkill(ny_10th_qinshi)

ny_10th_sunhanhua = sgs.General(extension, "ny_10th_sunhanhua", "wu", 3, false, false, false)

ny_10th_huiling = sgs.CreateTriggerSkill{
    name = "ny_10th_huiling",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    waked_skills = "ny_10th_taji,ny_10th_qinghuang",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if card and (not card:isKindOf("SkillCard")) then else return false end
        local red = 0
        local black = 0
        for _,id in sgs.qlist(room:getDiscardPile()) do
            if sgs.Sanguosha:getCard(id):isRed() then
                red = red + 1
            elseif sgs.Sanguosha:getCard(id):isBlack() then
                black = black + 1
            end
        end
        if red > black then
            if player:isWounded() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
            if card:isBlack() then
                room:addPlayerMark(player, "&ny_10th_huiling_ling", 1)
            end
        elseif black > red then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isNude() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_huiling", true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    local dis = room:askForCardChosen(player, target, "he", self:objectName())
                    room:throwCard(dis, target, player)
                end
            end
            if card:isRed() then
                room:addPlayerMark(player, "&ny_10th_huiling_ling", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_chongxu = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_chongxu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ny_10th_chongxu_mark",
    view_as = function(self)
        return ny_10th_chongxuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&ny_10th_huiling_ling") >= 4 and player:getMark("@ny_10th_chongxu_mark") > 0
    end,
}

ny_10th_chongxuCard = sgs.CreateSkillCard
{
    name = "ny_10th_chongxu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:setPlayerMark(source, "@ny_10th_chongxu_mark", 0)
        room:detachSkillFromPlayer(source, "ny_10th_huiling")
        room:gainMaxHp(source, source:getMark("&ny_10th_huiling_ling"), self:objectName())
        room:setPlayerMark(source, "&ny_10th_huiling_ling", 0)--清除所有“灵”，防止ai反复使用此技能
        room:acquireSkill(source, "ny_10th_taji", true)
        room:acquireSkill(source, "ny_10th_qinghuang", true)
    end
}

ny_10th_taji = sgs.CreateTriggerSkill{
    name = "ny_10th_taji",
    events = {sgs.CardsMoveOneTime, sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand) then else return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            local all = {"use", "response", "discard", "other"}
            local now = {}

            if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) then
                table.removeOne(all, "use")
                table.insert(now, "use")
            elseif (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_RESPONSE) then
                table.removeOne(all, "response")
                table.insert(now, "response")
            elseif (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
                table.removeOne(all, "discard")
                table.insert(now, "discard")
            else
                table.removeOne(all, "other")
                table.insert(now, "other")
            end

            if player:getMark("&ny_10th_qinghuang-PlayClear") > 0 then
                room:sendCompulsoryTriggerLog(player, "ny_10th_qinghuang", true)
                local add = all[math.random(1,#all)]
                table.insert(now, add)

                local log = sgs.LogMessage()
                log.type = "$ny_10th_qinghuang_add"
                log.from = player
                log.arg = "ny_10th_taji:"..add
                room:sendLog(log)
            end

            for _,p in ipairs(now) do
                if p == "use" then
                    local targets = sgs.SPlayerList()
                    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                        if not p:isNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_taji", true, true)
                        if target then
                            room:broadcastSkillInvoke(self:objectName())
                            local dis = room:askForCardChosen(player, target, "he", self:objectName())
                            room:throwCard(dis, target, player)
                        end
                    end
                end
                if p == "response" then
                    player:drawCards(1, self:objectName())
                end
                if p == "discard" then
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(player, nil, 1))
                    end
                end
                if p == "other" then
                    room:addPlayerMark(player, "&ny_10th_taji", 1)
                end
            end
        end
        if event == sgs.DamageCaused then
            if player:getMark("&ny_10th_taji") == 0 then return false end
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName() then
                local log = sgs.LogMessage()
                log.type = "$ny_10th_taji_damage"
                log.from = player
                log.to:append(damage.to)
                log.arg = self:objectName()
                log.arg2 = damage.damage
                log.arg3 = damage.damage + player:getMark("&ny_10th_taji")
                room:sendLog(log)

                room:broadcastSkillInvoke(self:objectName())
                damage.damage = damage.damage + player:getMark("&ny_10th_taji")
                room:setPlayerMark(player, "&ny_10th_taji", 0)
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_qinghuang = sgs.CreateTriggerSkill{
    name = "ny_10th_qinghuang",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke")) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "&ny_10th_qinghuang-PlayClear", 1)
                room:loseMaxHp(player, 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sunhanhua:addSkill(ny_10th_huiling)
ny_10th_sunhanhua:addSkill(ny_10th_chongxu)

ny_10th_huiling_record = sgs.CreateTriggerSkill{
    name = "#ny_10th_huiling_record",
    events = {sgs.CardsMoveOneTime,sgs.EventLoseSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local marks = {"&ny_10th_huiling_red", "&ny_10th_huiling_black", "&ny_10th_huiling_same"}
        if event == sgs.EventLoseSkill then
            if data:toString() == "ny_10th_huiling" then
                for _,mark in ipairs(marks) do
                    room:setPlayerMark(player, mark, 0)
                end
            end
            return false
        end
        local move = data:toMoveOneTime()
        if move.to_place == sgs.Player_DiscardPile or move.from_places:contains(sgs.Player_DiscardPile) then else return false end
        local red = 0
        local black = 0
        for _,id in sgs.qlist(room:getDiscardPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isRed() then
                red = red + 1
            elseif card:isBlack() then
                black = black + 1
            end
        end
        for _,mark in ipairs(marks) do
            room:setPlayerMark(player, mark, 0)
        end
        if red > black then 
            room:setPlayerMark(player, "&ny_10th_huiling_red", 1)
        elseif red < black then
            room:setPlayerMark(player, "&ny_10th_huiling_black", 1)
        else
            room:setPlayerMark(player, "&ny_10th_huiling_same", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("ny_10th_huiling")
    end,
}

ny_10th_sunhanhua:addSkill(ny_10th_huiling_record)
extension:insertRelatedSkills("ny_10th_huiling", "#ny_10th_huiling_record")

sgs.LoadTranslationTable{
    ["ny_10th_huiling_red"] = "红色较多",
    ["ny_10th_huiling_black"] = "黑色较多",
    ["ny_10th_huiling_same"] = "红黑相等",
}

ny_10th_chentai = sgs.General(extension, "ny_10th_chentai", "wei", 4, true, false, false)

ny_10th_jiuxian = sgs.CreateViewAsSkill
{
    name = "ny_10th_jiuxian",
    n = 999,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getHandcards():contains(to_select)
        and #selected < math.ceil(sgs.Self:getHandcardNum()/2)
    end,
    view_as = function(self, cards)
        if #cards > 0 and #cards == math.ceil(sgs.Self:getHandcardNum()/2) then
            local cc = ny_10th_jiuxianCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_jiuxian")
    end,
}

ny_10th_jiuxianCard = sgs.CreateSkillCard
{
    name = "ny_10th_jiuxian",
    will_throw = false,
    handling_method = sgs.Card_MethodRecast,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("ny_10th_jiuxian")

        duel:deleteLater()
        return duel and duel:targetFilter(qtargets, to_select, player)
    end,
    feasible = function(self, targets, player)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("ny_10th_jiuxian")
        duel:deleteLater()
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return duel:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

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

        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName("_ny_10th_jiuxian")
        duel:deleteLater()
        return duel
    end,
}

ny_10th_jiuxian_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_jiuxian_buff",
    events = {sgs.TargetConfirmed, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Duel") and table.contains(use.card:getSkillNames(),"ny_10th_jiuxian") then
                local names = {}
                for _,p in sgs.qlist(use.to) do
                    room:setCardFlag(use.card, "ny_10th_jiuxian_target_"..p:objectName())
                end
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ny_10th_jiuxian_target_"..damage.to:objectName()) then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
                    if p:isWounded() and damage.to:inMyAttackRange(p) and p:objectName() ~= player:objectName() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, "ny_10th_jiuxian", 
                    "@ny_10th_jiuxian:"..damage.to:getGeneralName(), true, true)
                    if target then
                        room:broadcastSkillInvoke("ny_10th_jiuxian")
                        room:recover(target, sgs.RecoverStruct(player, nil, 1))
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_chenyong = sgs.CreateTriggerSkill{
    name = "ny_10th_chenyong",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event ~= sgs.EventPhaseStart then
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                local respose = data:toCardResponse()
                if respose.m_isUse then
                    card = respose.m_card
                end
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            local types = {"BasicCard", "TrickCard", "EquipCard"}
            for _,cardtype in ipairs(types) do
                if card:isKindOf(cardtype) and player:getMark("ny_10th_chenyong_"..cardtype.."-Clear") == 0 then
                    room:setPlayerMark(player, "ny_10th_chenyong_"..cardtype.."-Clear", 1)
                    room:addPlayerMark(player, "&ny_10th_chenyong-Clear", 1)
                end
            end
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            if player:getMark("&ny_10th_chenyong-Clear") <= 0 then return false end
            local prompt = string.format("draw:%s:", player:getMark("&ny_10th_chenyong-Clear"))
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(player:getMark("&ny_10th_chenyong-Clear"), self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() ~= sgs.Player_NotActive
    end,
}

ny_10th_chentai:addSkill(ny_10th_jiuxian)
ny_10th_chentai:addSkill(ny_10th_jiuxian_buff)
ny_10th_chentai:addSkill(ny_10th_chenyong)
extension:insertRelatedSkills("ny_10th_jiuxian", "#ny_10th_jiuxian_buff")

ny_10th_huanfan = sgs.General(extension, "ny_10th_huanfan", "wei", 3, true, false, false)

ny_10th_fumou = sgs.CreateTriggerSkill{
    name = "ny_10th_fumou",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = player:getLostHp()
        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(),
        self:objectName(), 0, n, "@ny_10th_fumou:"..n, true, true)
        if targets and (not targets:isEmpty()) then
            room:broadcastSkillInvoke(self:objectName())
            for _,target in sgs.qlist(targets) do
                local choices = {"discard"}
                local cant = {}
                if (not target:getEquips():isEmpty()) and target:isWounded() then
                    table.insert(choices, "recover")
                else
                    table.insert(cant, "recover")
                end
                if room:canMoveField("ej") then
                    table.insert(choices, "move")
                else
                    table.insert(cant, "move")
                end
                local choice = room:askForChoice(target, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), table.concat(cant, "+"), nil)
                
                local chosenlog = sgs.LogMessage()
                chosenlog.type = "$ny_10th_fumou_chosen"
                chosenlog.from = target
                chosenlog.arg = "ny_10th_fumou:"..choice
                room:sendLog(chosenlog)
                
                if choice == "discard" then
                    local num = target:getHandcardNum()
                    room:askForDiscard(target, self:objectName(), num, num, false, false)
                    target:drawCards(2, self:objectName())
                end
                if choice == "move" then
                    room:moveField(target, self:objectName(), true, "ej")
                end
                if choice == "recover" then
                    local equips = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    equips:deleteLater()
                    equips:addSubcards(target:getEquipsId())

                    local log = sgs.LogMessage()
                    log.type = "$DiscardCard"
                    log.from = target
                    log.card_str = table.concat(sgs.QList2Table(target:getEquipsId()), "+")
                    room:sendLog(log)

                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, target:objectName(), self:objectName(), "")
                    room:moveCardTo(equips, nil, nil, sgs.Player_DiscardPile, reason)
                    room:recover(target, sgs.RecoverStruct(player, nil, 1))
                end
            end
        end         
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ny_tenth_jianzheng = sgs.CreateViewAsSkill
{
    name = "ny_tenth_jianzheng",
    n = 99,
    response_pattern = "@@ny_tenth_jianzheng",
    expand_pile = "#ny_tenth_jianzheng",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_tenth_jianzheng_using") then
            if not sgs.Self:getPile("#ny_tenth_jianzheng"):contains(to_select:getId()) then return false end
            if #selected >= 1 then return false end
            return to_select:isAvailable(sgs.Self)
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("ny_tenth_jianzheng_using") then
            if #cards == 1 then
                local cc = ny_tenth_jianzheng_useCard:clone()
                cc:addSubcard(cards[1])
                return cc
            end
        else
            if #cards == 0 then
                return ny_tenth_jianzhengCard:clone()
            end
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_tenth_jianzheng")
    end,
}

ny_tenth_jianzhengCard = sgs.CreateSkillCard
{
    name = "ny_tenth_jianzheng",
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName() and (not to_select:isKongcheng())
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()

        local view_cards = sgs.IntList()
        for _,card in sgs.qlist(targets[1]:getHandcards()) do
            view_cards:append(card:getId())
        end

        local view_log_forself = sgs.LogMessage()
        view_log_forself.type = "$ViewAllCards"
        view_log_forself.from = source
        view_log_forself.to:append(targets[1])
        view_log_forself.card_str = table.concat(sgs.QList2Table(view_cards), "+")
        room:sendLog(view_log_forself, source)

        local view_log_forothers = sgs.LogMessage()
        view_log_forothers.type = "#ViewAllCards"
        view_log_forothers.from = source
        view_log_forothers.to:append(targets[1])
        room:sendLog(view_log_forothers, room:getOtherPlayers(source))

        room:setPlayerFlag(source, "ny_tenth_jianzheng_using")
        room:notifyMoveToPile(source, view_cards, "ny_tenth_jianzheng", sgs.Player_PlaceHand, true)
        room:setPlayerFlag(targets[1], "ny_tenth_jianzheng_target")
        local use_card = room:askForUseCard(source, "@@ny_tenth_jianzheng", "@ny_tenth_jianzheng:"..targets[1]:getGeneralName())
        room:setPlayerFlag(targets[1], "-ny_tenth_jianzheng_target")
        room:notifyMoveToPile(source, view_cards, "ny_tenth_jianzheng", sgs.Player_PlaceHand, false)
        room:setPlayerFlag(source, "-ny_tenth_jianzheng_using")

        if use_card then
            local realcard = use_card:getSubcards():first()
            local owner = room:getCardOwner(realcard)
            realcard = sgs.Sanguosha:getCard(realcard)
            if realcard:targetFixed() then
                local usecardlog = sgs.LogMessage()
                usecardlog.type = "$ny_tenth_jianzheng_usecard_targetfixed"
                usecardlog.from = source
                usecardlog.arg = owner and owner:getGeneralName() or ""
                usecardlog.card_str = realcard:toString()
                room:sendLog(usecardlog)

                for _,player in sgs.qlist(room:getAlivePlayers()) do
                    if player:hasFlag("ny_tenth_jianzheng_useto") then
                        room:setPlayerFlag(player, "-ny_tenth_jianzheng_useto")
                    end
                end
                room:obtainCard(source, realcard, true)
                room:setCardFlag(realcard, "ny_tenth_jianzheng_card")
                room:setPlayerFlag(targets[1], "ny_tenth_jianzheng_target")
                room:useCard(sgs.CardUseStruct(realcard, source, sgs.SPlayerList(), false, self, source), true)
                room:setCardFlag(realcard, "-ny_tenth_jianzheng_card")
                room:setPlayerFlag(targets[1], "-ny_tenth_jianzheng_target")
            else
                local useto = sgs.SPlayerList()
                for _,player in sgs.qlist(room:getAlivePlayers()) do
                    if player:hasFlag("ny_tenth_jianzheng_useto") then
                        room:setPlayerFlag(player, "-ny_tenth_jianzheng_useto")
                        useto:append(player)
                    end
                end

                local usecardlog = sgs.LogMessage()
                usecardlog.type = "$ny_tenth_jianzheng_usecard_nottargetfixed"
                usecardlog.from = source
                usecardlog.to = useto
                usecardlog.arg = targets[1]:getGeneralName()
                usecardlog.card_str = realcard:toString()
                room:sendLog(usecardlog)

                room:obtainCard(source, realcard, true)
                room:setCardFlag(realcard, "ny_tenth_jianzheng_card")
                room:setPlayerFlag(targets[1], "ny_tenth_jianzheng_target")
                room:useCard(sgs.CardUseStruct(realcard, source, useto, false, self, source), true)
                room:setCardFlag(realcard, "-ny_tenth_jianzheng_card")
                room:setPlayerFlag(targets[1], "-ny_tenth_jianzheng_target")
            end
        end
    end,
}

ny_tenth_jianzheng_useCard = sgs.CreateSkillCard
{
    name = "ny_tenth_jianzheng_use",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card and card:targetFixed() then
			return false
		end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets) then
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
	feasible = function(self, targets,player)	
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)

		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetsFeasible(qtargets, player) then
            return true
        end
        return false
	end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        for _,player in ipairs(targets) do
            room:setPlayerFlag(player, "ny_tenth_jianzheng_useto")
        end
    end,
}

ny_tenth_jianzheng_buff = sgs.CreateTriggerSkill{
    name = "#ny_tenth_jianzheng",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:hasFlag("ny_tenth_jianzheng_card") then
            for _,p in sgs.qlist(use.to) do
                if p:hasFlag("ny_tenth_jianzheng_target") then
                    room:setPlayerChained(player, true)
                    room:setPlayerChained(p, true)

                    local log = sgs.LogMessage()
                    log.type = "#ViewAllCards"
                    log.from = p
                    log.to:append(player)
                    room:sendLog(log)

                    room:showAllCards(player, p)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_huanfan:addSkill(ny_tenth_jianzheng)
ny_10th_huanfan:addSkill(ny_tenth_jianzheng_buff)
ny_10th_huanfan:addSkill(ny_10th_fumou)
extension:insertRelatedSkills("ny_tenth_jianzheng", "#ny_tenth_jianzheng_buff")

ny_10th_yuecaiwenji = sgs.General(extension, "ny_10th_yuecaiwenji", "qun", 3, false, false, false)

ny_10th_shuangjia = sgs.CreateTriggerSkill{
    name = "ny_10th_shuangjia",
    events = {sgs.GameStart, sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local n = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                room:setCardFlag(card, "ny_10th_hujia")
                room:setCardTip(card:getId(), "ny_10th_hujia")
                n = n + 1
            end
            room:setPlayerMark(player, "&ny_10th_shuangjia", n)
        end
        if event == sgs.CardsMoveOneTime then
            if player:getMark("&ny_10th_shuangjia") == 0 then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then else return false end
            local n = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("ny_10th_hujia") then n = n + 1 end
            end
            room:setPlayerMark(player, "&ny_10th_shuangjia", n)
        end
        if event == sgs.EventPhaseChanging then
            if player:getMark("&ny_10th_shuangjia") == 0 then return false end
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_Discard then return false end
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("ny_10th_hujia") then room:ignoreCards(player, card) end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shuangjia_distance = sgs.CreateDistanceSkill{
    name = "#ny_10th_shuangjia_distance",
    correct_func = function(self, from, to)
        if to:hasSkill("ny_10th_shuangjia") then 
            return math.min(to:getMark("&ny_10th_shuangjia"), 5)
        end
        return 0
    end,
}

ny_10th_beifen = sgs.CreateTriggerSkill
{
    name = "ny_10th_beifen",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    priority = 99,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if player:getMark("&ny_10th_shuangjia") == 0 then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then else return false end
            if move.from_places:contains(sgs.Player_PlaceHand) then else return false end
            local will_invoke = false
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):hasFlag("ny_10th_hujia") then 
                    will_invoke = true
                    break
                end
            end
            if not will_invoke then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local suits = {}
            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            get:deleteLater()
            local n = 0
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("ny_10th_hujia") then
                    n = n + 1
                    if not table.contains(suits, card:getSuitString()) then
                        table.insert(suits, card:getSuitString())
                    end
                end
            end
            room:setPlayerMark(player, "&ny_10th_shuangjia", n)

            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if not table.contains(suits, card:getSuitString()) then
                    table.insert(suits, card:getSuitString())
                    get:addSubcard(card)
                end
            end
            if get:subcardsLength() > 0 then
                room:obtainCard(player, get, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_beifen_buff = sgs.CreateTargetModSkill{
    name = "#ny_10th_beifen_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:hasSkill("ny_10th_beifen") and from:getMark("&ny_10th_shuangjia")*2 < from:getHandcardNum() then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill("ny_10th_beifen") and from:getMark("&ny_10th_shuangjia")*2 < from:getHandcardNum() then return 1000 end
        return 0
    end,
}

ny_10th_yuecaiwenji:addSkill(ny_10th_shuangjia)
ny_10th_yuecaiwenji:addSkill(ny_10th_shuangjia_distance)
ny_10th_yuecaiwenji:addSkill(ny_10th_beifen)
ny_10th_yuecaiwenji:addSkill(ny_10th_beifen_buff)
extension:insertRelatedSkills("ny_10th_shuangjia", "#ny_10th_shuangjia_distance")
extension:insertRelatedSkills("ny_10th_beifen", "#ny_10th_beifen_buff")

ny_10th_yuanji = sgs.General(extension, "ny_10th_yuanji", "wu", 3, false, false, false)

ny_10th_fangdu = sgs.CreateTriggerSkill{
    name = "ny_10th_fangdu",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_NotActive then return false end
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Normal then
            if player:getMark("ny_10th_fangdu_normal-Clear") == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "ny_10th_fangdu_normal-Clear", 1)
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
        else
            if player:getMark("ny_10th_fangdu_unnormal-Clear") == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "ny_10th_fangdu_unnormal-Clear", 1)
                if damage.from:objectName() ~= player:objectName() and ( not damage.from:isKongcheng()) then
                    local cards = sgs.QList2Table(damage.from:getHandcards())
                    room:obtainCard(player, cards[math.random(1, #cards)], false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ny_10th_jiexing = sgs.CreateTriggerSkill{
    name = "ny_10th_jiexing",
    events = {sgs.HpChanged,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.HpChanged then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                local card_ids = player:drawCardsList(1, self:objectName())
                for _,id in sgs.qlist(card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    room:setCardFlag(card, "ny_10th_jiexing")
                    room:setCardTip(id, "ny_10th_jiexing")
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_10th_jiexing") then room:ignoreCards(player, card) end
                end
            end
            if change.from == sgs.Player_NotActive or change.to == sgs.Player_NotActive then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_10th_jiexing") then 
                        room:setCardFlag(card, "-ny_10th_jiexing")
                        room:setCardTip(card:getId(), "-ny_10th_jiexing")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_yuanji:addSkill(ny_10th_fangdu)
ny_10th_yuanji:addSkill(ny_10th_jiexing)

ny_10th_shenzhangjiao = sgs.General(extension, "ny_10th_shenzhangjiao", "god", 3, true, false, false)

ny_10th_yizhao = sgs.CreateTriggerSkill{
    name = "ny_10th_yizhao",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        local n = player:getMark("&ny_10th_huang")
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        end
        if event == sgs.CardResponded then
            local respond = data:toCardResponse()
            card = respond.m_card
        end
        if card:isKindOf("SkillCard") then return false end
        local num = card:getNumber()
        local m = n + num
        room:setPlayerMark(player, "&ny_10th_huang", m)
        if m < 10 then return false end
        local change = math.floor(m/10) - math.floor(n/10)
        if change == 0 then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        for _,id in sgs.qlist(room:getDrawPile()) do
            local get = sgs.Sanguosha:getCard(id)
            local can = math.floor(m/10)
            while(can > 10) do
                can = can - 10
            end
            if get:getNumber() == can then
                room:obtainCard(player, get, false)
                break
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sijun = sgs.CreateTriggerSkill{
    name = "ny_10th_sijun",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        local num = room:getDrawPile():length()
        if player:getMark("&ny_10th_huang") <= num then return false end 
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then return false end
        room:broadcastSkillInvoke(self:objectName())

        local drawpile = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
        for _,id in sgs.qlist(room:getDrawPile()) do
            drawpile:addSubcard(id)
        end

        room:moveCardTo(drawpile, nil, sgs.Player_DiscardPile)
        drawpile:deleteLater()
        room:swapPile()

        room:setPlayerMark(player, "&ny_10th_huang", 0)
        local obtained = sgs.IntList()
        local n = 36
        if math.random(1, 6) == 1 then
            --加入逆天狗运摸牌
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                local num = card:getNumber()
                if num <= n and num <= 3 and card:isAvailable(player) then
                    obtained:append(id)
                    n = n - num
                end
                if n == 0 then break end
            end
            if n > 0 then
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local num = sgs.Sanguosha:getCard(id):getNumber()
                    if num <= n and (not obtained:contains(id)) then
                        obtained:append(id)
                        n = n - num
                    end
                    if n == 0 then break end
                end
            end
        else
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id):getNumber()
                if card <= n then
                    obtained:append(id)
                    n = n - card
                end
                if n == 0 then break end
            end
        end
        local dummy = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
        for _,id in sgs.qlist(obtained) do
            dummy:addSubcard(id)
        end
        player:obtainCard(dummy,false)
        dummy:deleteLater()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sanshou = sgs.CreateTriggerSkill{
    name = "ny_10th_sanshou",
    events = {sgs.DamageForseen},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local can = false

            local types = room:getTag("ny_10th_sanshou_cardtypes"):toString():split("+")
            if (not types) then types = {} end
            local card_ids = room:getNCards(3)
            local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
            local move1 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_PlaceTable, reason1)
            room:moveCardsAtomic(move1, true)

            for _,id in sgs.qlist(card_ids) do
                local find = false
                for _,ctype in ipairs(types) do
                    if sgs.Sanguosha:getCard(id):isKindOf(ctype) then 
                        find = true
                        break
                    end
                end
                if not find then 
                    can = true 
                    break
                end
            end

            if can then
                local damage = data:toDamage().damage
                local log = sgs.LogMessage()
                log.type = "$ny_10th_sanshou_damage"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = damage
                room:sendLog(log)
            end

            local log = sgs.LogMessage()
            log.type = "$MoveToDiscardPile"
            log.from = player
            log.card_str = table.concat(sgs.QList2Table(card_ids), "+")
            room:sendLog(log)

            local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            local move2 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_DiscardPile, reason2)
            room:moveCardsAtomic(move2, true)

            return can
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sanshou_record = sgs.CreateTriggerSkill{
    name = "#ny_10th_sanshou_record",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging},
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
            if (not card) or card:isKindOf("SkillCard") then return false end

            local types = room:getTag("ny_10th_sanshou_cardtypes"):toString():split("+")
            if (not types) then types = {} end
            local alltypes = {"BasicCard", "TrickCard", "EquipCard"}
            for _,ctype in ipairs(alltypes) do
                if card:isKindOf(ctype) then
                    if not table.contains(types, ctype) then
                        table.insert(types, ctype)
                    end
                    break
                end
            end

            room:setTag("ny_10th_sanshou_cardtypes", sgs.QVariant(table.concat(types, "+")))
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:removeTag("ny_10th_sanshou_cardtypes")
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_tianjie = sgs.CreateTriggerSkill{
    name = "ny_10th_tianjie",
    events = {sgs.EventPhaseChanging, sgs.SwappedPile},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            if player:getMark("ny_10th_tianjie_finish-Clear") <= 0 then return false end
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() then
                    local targets = room:askForPlayersChosen(p, room:getOtherPlayers(p),
                    self:objectName(), 0, 3, "@ny_10th_tianjie", true, true)
                    if targets and (not targets:isEmpty()) then
                        room:broadcastSkillInvoke(self:objectName())

                        for _,target in sgs.qlist(targets) do
                            if target:isAlive() then
                                local jink = 0
                                for _,card in sgs.qlist(target:getHandcards()) do
                                    if card:isKindOf("Jink") then jink = jink + 1 end
                                end
                                jink = math.max(1, jink)
                                room:damage(sgs.DamageStruct(self:objectName(), p, target, 1, sgs.DamageStruct_Thunder))
                            end
                        end
                    end
                end
            end
        end
        if event == sgs.SwappedPile then
            for _,p in sgs.qlist(room:getAllPlayers()) do
                room:setPlayerMark(p, "ny_10th_tianjie_finish-Clear", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_shenzhangjiao:addSkill(ny_10th_yizhao)
ny_10th_shenzhangjiao:addSkill(ny_10th_sijun)
ny_10th_shenzhangjiao:addSkill(ny_10th_sanshou)
ny_10th_shenzhangjiao:addSkill(ny_10th_sanshou_record)
ny_10th_shenzhangjiao:addSkill(ny_10th_tianjie)
extension:insertRelatedSkills("ny_10th_sanshou", "#ny_10th_sanshou_record")

ny_10th_zhangfen = sgs.General(extension, "ny_10th_zhangfen", "wu", 4, true, false, false)

ny_tenth_dagongche = sgs.CreateTreasure
{
	name = "_ny_tenth_dagongche",
	class_name = "Dagongche",
    suit = sgs.Card_Spade,
    number = 9,
	target_fixed = true,
    subtype = "ny_tenth_zhangfen_card",
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player, "ny_tenth_dagongche_slashtr", false, false, false)
        room:acquireSkill(player, "ny_tenth_dagongche_slash", false, false, false)
        room:acquireSkill(player, "ny_tenth_dagongche_buff", false, false, false)
        room:acquireSkill(player, "#ny_tenth_dagongche_destory", false, false, false)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "ny_tenth_dagongche_slashtr", true, true, false)
        room:detachSkillFromPlayer(player, "ny_tenth_dagongche_slash", true, true, false)
        room:setPlayerMark(player, "SkillDescriptionArg1_ny_tenth_xianzhu", 0)
        room:setPlayerMark(player, "SkillDescriptionArg2_ny_tenth_xianzhu", 0)
        room:setPlayerMark(player, "ny_tenth_xianzhu_ignore", 0)
		player:setSkillDescriptionSwap("ny_tenth_xianzhu","%arg1",0)
		player:setSkillDescriptionSwap("ny_tenth_xianzhu","%arg2",0)
        if player:hasSkill("ny_tenth_xianzhu") then
            room:changeTranslation(player, "ny_tenth_xianzhu", 1)
        end
        if player:hasSkill("ny_tenth_chaixie") then
            room:sendCompulsoryTriggerLog(player, "ny_tenth_chaixie", true, true)
            player:drawCards(player:getMark("&ny_tenth_xianzhu_update"), "ny_tenth_chaixie")
        end
        room:setPlayerMark(player, "&ny_tenth_xianzhu_update", 0)
	end,
}
ny_tenth_dagongche:setParent(extension)

ny_tenth_dagongche_slash = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_dagongche_slash",
    response_pattern = "@@ny_tenth_dagongche_slash",
    view_as = function(self)
        return ny_tenth_dagongche_slashCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_dagongche_slashCard = sgs.CreateSkillCard
{
    name = "ny_tenth_dagongche_slash",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:setSkillName("ny_tenth_dagongche")

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        slash:deleteLater()
        return slash:targetFilter(qtargets, to_select, player)
    end,
    on_validate = function(self, cardUse)
        local room = cardUse.from:getRoom()
		cardUse.m_addHistory = false

        if cardUse.from:getMark("ny_tenth_xianzhu_ignore") > 0 then
            for _,p in sgs.qlist(cardUse.to) do
                room:addPlayerMark(p, "Armor_Nullified", 1)
                room:setPlayerFlag(p, "ny_tenth_dagongche_target")
            end
        end

        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:setSkillName("ny_tenth_dagongche")
        room:setCardFlag(slash, "RemoveFromHistory")
        room:setCardFlag(slash, "ny_tenth_dagongche_slash")
        slash:deleteLater()
        return slash
    end,
}

--借用一下手杀界破军的fakemove

ny_tenth_dagongche_slashtr = sgs.CreateTriggerSkill{
    name = "ny_tenth_dagongche_slashtr",
    events = {sgs.EventPhaseStart, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_dagongche_slash,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local more = player:getMark("SkillDescriptionArg2_ny_tenth_xianzhu")
            room:askForUseCard(player, "@@ny_tenth_dagongche_slash", "@ny_tenth_dagongche_slash:"..more)
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("ny_tenth_dagongche_target") then
                    room:setPlayerFlag(p, "-ny_tenth_dagongche_target")
                    room:removePlayerMark(p, "Armor_Nullified", 1)
                end
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:isNude() then return false end
            if damage.card and damage.card:hasFlag("ny_tenth_dagongche_slash") then
                local max = math.max(1, player:getMark("SkillDescriptionArg1_ny_tenth_xianzhu"))
                local discards = sgs.IntList()

                local all = damage.to:getCards("he"):length()
                max = math.min(max, all)

                for i = 1, max do--进行多次执行
                    local id = room:askForCardChosen(player, damage.to, "he", "_ny_tenth_dagongche",
                        false,--选择卡牌时手牌不可见
                        sgs.Card_MethodDiscard,--设置为弃置类型
                        discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
                        false)--只有执行过一次选择才可取消
                    if id < 0 then break end--如果卡牌id无效就结束多次执行
                    discards:append(id)--将选择的id添加到虚拟卡的子卡表
                end

                room:throwCard(discards, "_ny_tenth_dagongche", damage.to, player)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasTreasure("_ny_tenth_dagongche")
    end,
}

ny_tenth_dagongche_destory = sgs.CreateCardLimitSkill
{
    name = "#ny_tenth_dagongche_destory",
    limit_list = function(self, player)
        return "discard"
    end,
    limit_pattern = function(self, player, card)
        if card:isKindOf("Dagongche") then 
            for _,p in sgs.qlist(player:getAliveSiblings(true)) do
                if p:hasEquip(card) and p:getMark("&ny_tenth_xianzhu_update")<1 then
                    return card:toString()
            end
        end
        end
		return ""
    end,
}

ny_tenth_dagongche_buff = sgs.CreateTargetModSkill{
    name = "ny_tenth_dagongche_buff",
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_dagongche"
        and from:getMark("ny_tenth_xianzhu_ignore") > 0 then return 1000 end
        return 0
    end,
    extra_target_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_dagongche" then
            return from:getMark("SkillDescriptionArg2_ny_tenth_xianzhu")
        end
        return 0
    end,
}

ny_tenth_wanglu = sgs.CreateTriggerSkill{
    name = "ny_tenth_wanglu",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            if ((not player:getEquip(4)) 
            or (player:getEquip(4) and player:getEquip(4):objectName() ~= "_ny_tenth_dagongche" ))
            and player:hasEquipArea(4) then
                local card = nil
                for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                    if sgs.Sanguosha:getEngineCard(id):isKindOf("Dagongche") then
                        card = sgs.Sanguosha:getEngineCard(id)
                        break
                    end
                end
                if card then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

                    if player:getEquip(4) then
                        room:throwCard(player:getEquip(4), player, player)
                    end

                    local log = sgs.LogMessage()
                    log.type = "$ny_tenth_wanglu_get"
                    log.from = player
                    log.arg = self:objectName()
                    log.card_str = card:toString()
                    room:sendLog(log)

                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                    room:moveCardTo(card, nil, player, sgs.Player_PlaceEquip, reason)
                end
            else
                local log = sgs.LogMessage()
                log.type = "$ny_tenth_wanglu_phase"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = "play"
                room:sendLog(log)

                local thread = room:getThread()
                local old_phase = player:getPhase()
			    player:setPhase(sgs.Player_Play)
			    room:broadcastProperty(player, "phase")
                room:broadcastSkillInvoke(self:objectName())
			    if not thread:trigger(sgs.EventPhaseStart, room, player) then
				    thread:trigger(sgs.EventPhaseProceeding, room, player)
			    end
			    thread:trigger(sgs.EventPhaseEnd, room, player)
                player:setPhase(old_phase)
                room:broadcastProperty(player, "phase")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_xianzhu = sgs.CreateTriggerSkill{
    name = "ny_tenth_xianzhu",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if ((not player:getEquip(4)) 
            or (player:getEquip(4) and player:getEquip(4):objectName() ~= "_ny_tenth_dagongche" )) then return false end
        if player:getMark("&ny_tenth_xianzhu_update") >= 5 then return false end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("update")) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, "&ny_tenth_xianzhu_update", 1)
                local choices = {"discards", "targets", "ignore"}
                local except = {}
                if player:getMark("ny_tenth_xianzhu_ignore") > 0 then
                    table.removeOne(choices, "ignore")
                    table.insert(except, "ignore")
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(),
                table.concat(except, "+"), nil)
                
                if player:getMark("SkillDescriptionArg1_ny_tenth_xianzhu") == 0 then
                    room:addPlayerMark(player, "SkillDescriptionArg1_ny_tenth_xianzhu", 1)
                end

                if choice == "ignore" then
                    room:setPlayerMark(player, "ny_tenth_xianzhu_ignore", 1)
                end
                if choice == "discards" then
                    room:addPlayerMark(player, "SkillDescriptionArg1_ny_tenth_xianzhu", 1)
                end
                if choice == "targets" then
                    room:addPlayerMark(player, "SkillDescriptionArg2_ny_tenth_xianzhu", 1)
                end

                if player:getMark("ny_tenth_xianzhu_ignore") > 0 then
                    room:changeTranslation(player, "ny_tenth_xianzhu", 3)
                else
                    room:changeTranslation(player, "ny_tenth_xianzhu", 2)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_chaixie = sgs.CreateTriggerSkill{
    name = "ny_tenth_chaixie",
    events = {},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhangfen:addSkill(ny_tenth_wanglu)
ny_10th_zhangfen:addSkill(ny_tenth_xianzhu)
ny_10th_zhangfen:addSkill(ny_tenth_chaixie)

ny_10th_jiezhonghui = sgs.General(extension, "ny_10th_jiezhonghui", "wei", 4, true, false, false)

ny_10th_quanji = sgs.CreateTriggerSkill{
    name = "ny_10th_quanji",
    events = {sgs.Damaged, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = 1
        if event == sgs.Damaged then
            n = data:toDamage().damage
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand
            and move.to and move.to:objectName() ~= player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                n = 1
            else
                return false
            end
        end

        for i = 1, n, 1 do
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1)
                local quan = room:askForExchange(player, self:objectName(), 1, 1, false, "@ny_10th_quanji", false)
                if quan and quan:subcardsLength() > 0 then
                    player:addToPile("ny_10th_quan", quan)
                end
            end
            if player:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_10th_quanji_maxcard = sgs.CreateMaxCardsSkill{
    name = "#ny_10th_quanji_maxcard",
    extra_func = function(self, target)
        if target:hasSkill("ny_10th_quanji") then
            return target:getPile("ny_10th_quan"):length()
        end
        return 0
    end,
}

ny_10th_zili = sgs.CreateTriggerSkill{
    name = "ny_10th_zili",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "ny_10th_paiyi",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:setPlayerMark(player, "ny_10th_zili_waked", 1)
        room:recover(player, sgs.RecoverStruct(player, nil, 1))
        player:drawCards(2, self:objectName())
        room:loseMaxHp(player, 1)
        room:acquireSkill(player, "ny_10th_paiyi")
    end,
    can_wake = function(self, event, player, data, room)
        local room = player:getRoom()
        if player:canWake(self:objectName()) then return true end
        return player:getMark("ny_10th_zili_waked") == 0
        and player:getPile("ny_10th_quan"):length() >= 3
        and player:getPhase() == sgs.Player_Start
    end,
}

ny_10th_paiyi = sgs.CreateViewAsSkill
{
    name = "ny_10th_paiyi",
    n = 99,
    expand_pile = "ny_10th_quan",
    tiansuan_type = "draw,damage",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("ny_10th_quan"):contains(to_select:getId())
        and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = ny_10th_paiyiCard:clone()
            cc:addSubcard(cards[1])
            cc:setUserString(sgs.Self:getTag("ny_10th_paiyi"):toString())
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        local choices = {"draw","damage"}
        for _,choice in ipairs(choices) do
            if player:getMark("ny_10th_paiyi_tiansuan_remove_"..choice.."-PlayClear") == 0 then
                return true
            end
        end
    end,
}

ny_10th_paiyiCard = sgs.CreateSkillCard
{
    name = "ny_10th_paiyi",
    will_throw = true,
    filter = function(self, targets, to_select,player)
        local choice = self:getUserString()
        if choice == "draw" then
            return #targets == 0
        else
            return #targets < (player:getPile("ny_10th_quan"):length() - 1)
        end
    end,
    feasible = function(self, targets, player)
        return #targets ~= 0
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local choice = self:getUserString()
        room:setPlayerMark(source, "ny_10th_paiyi_tiansuan_remove_"..choice.."-PlayClear", 1)

        local log = sgs.LogMessage()
        log.type = "$ny_10th_paiyi_chosen"
        log.from = source
        log.arg = "ny_10th_paiyi:"..choice
        room:sendLog(log)

        if choice == "draw" then
            targets[1]:drawCards(source:getPile("ny_10th_quan"):length(), self:objectName())
        else
            for _,target in ipairs(targets) do
                room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, sgs.DamageStruct_Normal))
                room:getThread():delay(500)
            end
        end
    end,
}

ny_10th_jiezhonghui:addSkill(ny_10th_quanji)
ny_10th_jiezhonghui:addSkill(ny_10th_quanji_maxcard)
ny_10th_jiezhonghui:addSkill(ny_10th_zili)
extension:insertRelatedSkills("ny_10th_quanji", "#ny_10th_quanji_maxcard")

ny_10th_jindiancaocao = sgs.General(extension, "ny_10th_jindiancaocao", "wei", 4, true, false, false)

ny_10th_jingdianjianxiong = sgs.CreateTriggerSkill{
    name = "ny_10th_jingdianjianxiong",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = player:getMark("SkillDescriptionArg1_ny_10th_jingdianjianxiong")
        n = math.max(1,n)
        local damage = data:toDamage()
        local card = damage.card
        local prompt
        if card and room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable 
        and (not card:isKindOf("SkillCard")) then
            prompt = string.format("draw:%s::%s:", card:objectName(), n)
        else
            prompt = string.format("draw:%s::%s:", "ny_10th_jingdianjianxiong_nocard", n)
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke(self:objectName())
            if card and room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable 
            and (not card:isKindOf("SkillCard")) then
                room:obtainCard(player, card, true)
            end
            player:drawCards(n, self:objectName())
            if n < 5 then
                n = n + 1
                room:setPlayerMark(player, "SkillDescriptionArg1_ny_10th_jingdianjianxiong", n)
                room:setPlayerMark(player, "&ny_10th_jingdianjianxiong_draw", n)
				player:setSkillDescriptionSwap("ny_10th_jingdianjianxiong","%arg1",n)
                room:changeTranslation(player, "ny_10th_jingdianjianxiong", 1)
            end
        end
    end,
}

ny_10th_jindiancaocao:addSkill(ny_10th_jingdianjianxiong)

ny_10th_jingdiansunquan = sgs.General(extension, "ny_10th_jingdiansunquan", "wu", 4, true, false, false)

ny_10th_jingdianzhiheng = sgs.CreateViewAsSkill
{
    name = "ny_10th_jingdianzhiheng",
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cc = ny_10th_jingdianzhihengCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#ny_10th_jingdianzhiheng") < (1 + player:getMark("&ny_10th_jingdianzhiheng-Clear"))
    end,
}

ny_10th_jingdianzhihengCard = sgs.CreateSkillCard
{
    name = "ny_10th_jingdianzhiheng",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local n = self:subcardsLength()
        if source:getMark("ny_10th_jingdianzhiheng_all") > 0 then
            room:setPlayerMark(source, "ny_10th_jingdianzhiheng_all", 0)
            n = n + 1
        end
        source:drawCards(n, self:objectName())
    end
}

ny_10th_jingdianzhiheng_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_jingdianzhiheng_buff",
    events = {sgs.Damage, sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local card = data:toCardUse().card
            if card:isKindOf("SkillCard") and table.contains(card:getSkillNames(),"ny_10th_jingdianzhiheng") then
                if player:getHandcardNum() == 0 then return end
                local ids = card:getSubcards()
                for _,cc in sgs.qlist(player:getHandcards()) do
                    local id = cc:getId()
                    if not ids:contains(id) then return end
                end
                room:setPlayerMark(player, "ny_10th_jingdianzhiheng_all", 1)
            end
        end
        if event == sgs.Damage then
            if player:getPhase() == sgs.Player_NotActive then return false end
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName()
            and damage.to:getMark("ny_10th_jingdianzhiheng_trigger_"..player:objectName().."-Clear") == 0 then
                room:setPlayerMark(damage.to, "ny_10th_jingdianzhiheng_trigger_"..player:objectName().."-Clear", 1)
                room:addPlayerMark(player, "&ny_10th_jingdianzhiheng-Clear", 1)
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jingdiansunquan:addSkill(ny_10th_jingdianzhiheng)
ny_10th_jingdiansunquan:addSkill(ny_10th_jingdianzhiheng_buff)
extension:insertRelatedSkills("ny_10th_jingdianzhiheng", "#ny_10th_jingdianzhiheng_buff")

ny_10th_jingdianliubei = sgs.General(extension, "ny_10th_jingdianliubei", "shu", 4, true, false, false)

ny_tenth_jingdianrende = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_jingdianrende",
    response_pattern = "@@ny_tenth_jingdianrende",
    view_as = function(self)
        if sgs.Self:hasFlag("ny_tenth_jingdianrende_basic") then
            return ny_tenth_jingdianrende_basicCard:clone()
        end
        return ny_tenth_jingdianrendeCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

ny_tenth_jingdianrendeCard = sgs.CreateSkillCard
{
    name = "ny_tenth_jingdianrende",
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select ~= player
        and to_select:getHandcardNum() > 0
        and to_select:getMark("ny_tenth_jingdianrende_get-PlayClear") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "ny_tenth_jingdianrende_get-PlayClear", 1)

        local obtain = sgs.Sanguosha:cloneCard("jink")
        for i = 1, math.min(effect.to:getHandcardNum(), 2) do
            local id = room:askForCardChosen(effect.from,effect.to,"h","ny_tenth_jingdianrende",false,sgs.Card_MethodNone,obtain:getSubcards())
			obtain:addSubcard(id)
        end
        room:obtainCard(effect.from, obtain, false)
        obtain:deleteLater()

        if effect.from:isAlive() and obtain:subcardsLength()>1 then
            local can = {}
            local cant = {}
            for _,pattern in ipairs(sgs.Sanguosha:getCardNames("BasicCard")) do
                local card = sgs.Sanguosha:cloneCard(pattern)
                if card:isAvailable(effect.from) then
                    table.insert(can, pattern)
                else
                    table.insert(cant, pattern)
                end
				obtain:deleteLater()
            end
            table.insert(can, "cancel")
            local choice = room:askForChoice(effect.from, self:objectName(), table.concat(can, "+"), sgs.QVariant(),
            table.concat(cant, "+"), "ny_tenth_jingdianrende_choice")
            if choice ~= "cancel" then 
                room:setPlayerProperty(effect.from, "ny_tenth_jingdianrende_card", sgs.QVariant(choice))
                room:setPlayerFlag(effect.from, "ny_tenth_jingdianrende_basic")
                room:askForUseCard(effect.from, "@@ny_tenth_jingdianrende", "@ny_tenth_jingdianrende:"..choice)
                room:setPlayerFlag(effect.from, "-ny_tenth_jingdianrende_basic")
            end
        end
    end
}

ny_tenth_jingdianrende_basicCard = sgs.CreateSkillCard
{
    handling_method = sgs.Card_MethodUse,
    mute = true,
    name = "ny_tenth_jingdianrende_basic",
    filter = function(self, targets, to_select, player) 
		local pattern = player:property("ny_tenth_jingdianrende_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_jingdianrende")
        card:deleteLater()
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local pattern = sgs.Self:property("ny_tenth_jingdianrende_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_jingdianrende")
        card:deleteLater()
		return card:targetFixed()
	end,
	feasible = function(self, targets, player)	
		local pattern = player:property("ny_tenth_jingdianrende_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_jingdianrende")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
        card:deleteLater()
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		local pattern = xunyou:property("ny_tenth_jingdianrende_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_jingdianrende")
        card:deleteLater()
		return card	
	end	
}

ny_10th_jingdianliubei:addSkill(ny_tenth_jingdianrende)

ny_10th_quanhuijie = sgs.General(extension, "ny_10th_quanhuijie", "wu", 3, false, false, false)

ny_tenth_huishu = sgs.CreateTriggerSkill{
    name = "ny_tenth_huishu",
    events = {sgs.EventPhaseEnd, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseEnd then
            if player:getPhase() ~= sgs.Player_Draw then return false end
            local draw = player:getMark("SkillDescriptionArg1_ny_tenth_huishu")
            if draw == 0 then
                room:setPlayerMark(player, "SkillDescriptionArg1_ny_tenth_huishu", 3)
                room:setPlayerMark(player, "SkillDescriptionArg2_ny_tenth_huishu", 1)
                room:setPlayerMark(player, "SkillDescriptionArg3_ny_tenth_huishu", 2)
				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg1",3)
				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg2",1)
				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg3",2)
                room:changeTranslation(player, "ny_tenth_huishu", 1)
                draw = 3
            end
            local discard = player:getMark("SkillDescriptionArg2_ny_tenth_huishu")
            local get = player:getMark("SkillDescriptionArg3_ny_tenth_huishu")

            local prompt = string.format("draw:%s::%s:", draw, discard)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "&ny_tenth_huishu_target-Clear", get+1)
                player:drawCards(draw, self:objectName())
                room:askForDiscard(player, self:objectName(), discard, discard, false, false)
            end
        end
        if event == sgs.CardsMoveOneTime then
            if player:getMark("&ny_tenth_huishu_target-Clear") == 0 then return false end
            if player:isDead() then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                room:addPlayerMark(player, "&ny_tenth_huishu_now-Clear", move.card_ids:length())
                if player:getMark("&ny_tenth_huishu_now-Clear") >= player:getMark("&ny_tenth_huishu_target-Clear") then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    local n = player:getMark("&ny_tenth_huishu_target-Clear") - 1
                    room:setPlayerMark(player, "&ny_tenth_huishu_target-Clear", 0)
                    room:setPlayerMark(player, "&ny_tenth_huishu_now-Clear", 0)
                    local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    local all = {}
                    for _,id in sgs.qlist(room:getDiscardPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isKindOf("BasicCard") then else
                            table.insert(all, card)
                        end
                    end
                    if #all > 0 then
                        while((#all > 0) and (n > 0)) do
                            local card = all[math.random(1,#all)]
                            get:addSubcard(card)
                            table.removeOne(all, card)
                            n = n - 1
                        end
                        room:obtainCard(player, get, false)
                    end
                    get:deleteLater()
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_yishu = sgs.CreateTriggerSkill{
    name = "ny_10th_yishu",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local draw = player:getMark("SkillDescriptionArg1_ny_tenth_huishu")
                if draw == 0 then
                    room:setPlayerMark(player, "SkillDescriptionArg1_ny_tenth_huishu", 3)
                    room:setPlayerMark(player, "SkillDescriptionArg2_ny_tenth_huishu", 1)
                    room:setPlayerMark(player, "SkillDescriptionArg3_ny_tenth_huishu", 2)
                    draw = 3
                end
                local discard = player:getMark("SkillDescriptionArg2_ny_tenth_huishu")
                local get = player:getMark("SkillDescriptionArg2_ny_tenth_huishu")

                local max = math.max(draw, discard, get)
                local changemax = {}
                if max == draw then table.insert(changemax, "draw="..max) end
                if max == discard then table.insert(changemax, "discard="..discard) end
                if max == get then table.insert(changemax, "get="..get) end

                local min = math.min(draw, discard, get)
                local changemin = {}
                if min == draw then table.insert(changemin, "draw="..draw) end
                if min == discard then table.insert(changemin, "discard="..discard) end
                if min == get then table.insert(changemin, "get="..get) end
                
                local cmax = room:askForChoice(player, self:objectName(), table.concat(changemax, "+"), sgs.QVariant("max"), nil, "ny_10th_yishu_add")
                local cmin = room:askForChoice(player, self:objectName(), table.concat(changemin, "+"), sgs.QVariant("min"), nil, "ny_10th_yishu_remove")

                if string.find(cmax, "draw") then room:addPlayerMark(player, "SkillDescriptionArg1_ny_tenth_huishu", -1) end
                if string.find(cmax, "discard") then room:addPlayerMark(player, "SkillDescriptionArg2_ny_tenth_huishu", -1) end
                if string.find(cmax, "get") then room:addPlayerMark(player, "SkillDescriptionArg3_ny_tenth_huishu", -1) end

                if string.find(cmin, "draw") then room:addPlayerMark(player, "SkillDescriptionArg1_ny_tenth_huishu", 2) end
                if string.find(cmin, "discard") then room:addPlayerMark(player, "SkillDescriptionArg2_ny_tenth_huishu", 2) end
                if string.find(cmin, "get") then room:addPlayerMark(player, "SkillDescriptionArg3_ny_tenth_huishu", 2) end

				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg1",player:getMark("SkillDescriptionArg1_ny_tenth_huishu"))
				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg2",player:getMark("SkillDescriptionArg2_ny_tenth_huishu"))
				player:setSkillDescriptionSwap("ny_tenth_huishu","%arg3",player:getMark("SkillDescriptionArg2_ny_tenth_huishu"))

                room:changeTranslation(player, "ny_tenth_huishu", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getPhase() ~= sgs.Player_Play and target:hasSkill("ny_tenth_huishu")
    end,
}

ny_10th_ligong = sgs.CreateTriggerSkill{
    name = "ny_10th_ligong",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:setPlayerMark(player, "ny_10th_ligong_waked", 1)
        room:gainMaxHp(player, 1, self:objectName())
        room:recover(player, sgs.RecoverStruct(player, nil, 1))
        room:detachSkillFromPlayer(player, "ny_10th_yishu")
        local names = {}
        local all = sgs.Sanguosha:getLimitedGeneralNames("wu")
        local count = 1000
        local find = 4
        while(find > 0) do
            local name = all[math.random(1, #all)]
            local selected = sgs.Sanguosha:getGeneral(name)
            if selected:isFemale() then
                local skill = selected:getVisibleSkillList()
                local get = false
                for _,p in sgs.qlist(skill) do
                    local na = p:objectName()
                    if not player:hasSkill(na) then
                        get = true
                        table.insert(names, name)
                        break
                    end
                end
                if get then find = find - 1 end
            end
            count = count - 1
            if count <= 0 then break end
        end
        if #names == 0 then 
            player:drawCards(3, self:objectName())
            return false
        end
        for i = 1, 2, 1 do
            local hero = sgs.Sanguosha:getGeneral(room:askForGeneral(player, table.concat(names, "+")))
            local skills = hero:getVisibleSkillList()
            local skillnames = {}
            for _,s in sgs.qlist(skills) do
                local skillname = s:objectName()
                if not player:hasSkill(skillname) then
                    table.insert(skillnames,skillname)
                end
            end
            table.insert(skillnames, "cancel")
            local choices = table.concat(skillnames, "+")
            local skill = room:askForChoice(player, self:objectName(), choices)
            if skill == "cancel" then
                if i == 1 then player:drawCards(3, self:objectName()) end
                return false
            else
                if i == 1 then
                    room:detachSkillFromPlayer(player, "ny_tenth_huishu")
                end
                room:acquireSkill(player, skill)
            end
        end
    end,
    can_wake = function(self, event, player, data, room)
        local room = player:getRoom()
        if player:canWake(self:objectName()) then return true end
        if not player:hasSkill("ny_tenth_huishu") then return false end
        if player:getMark("SkillDescriptionArg1_ny_tenth_huishu") < 5
        and player:getMark("SkillDescriptionArg2_ny_tenth_huishu") < 5
        and player:getMark("SkillDescriptionArg3_ny_tenth_huishu") < 5
        then return false end
        return player:getMark("ny_10th_ligong_waked") == 0
        and player:getPhase() == sgs.Player_Start
    end,
}

ny_10th_quanhuijie:addSkill(ny_tenth_huishu)
ny_10th_quanhuijie:addSkill(ny_10th_yishu)
ny_10th_quanhuijie:addSkill(ny_10th_ligong)

ny_10th_jxqunhuangyueying = sgs.General(extension, "ny_10th_jxqunhuangyueying", "qun", 3, false, false, false)

ny_10th_jiqiao = sgs.CreateTriggerSkill{
    name = "ny_10th_jiqiao",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = room:askForDiscard(player, self:objectName(), 999, 1, true, true, "@ny_10th_jiqiao", ".", self:objectName())
        if card and card:subcardsLength() > 0 then
            --room:broadcastSkillInvoke(self:objectName())
            local n = card:subcardsLength()
            for _,id in sgs.qlist(card:getSubcards()) do
                if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                    n = n + 1
                end
            end
            local card_ids = room:getNCards(n)
            local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
            local move1 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_PlaceTable, reason1)
            room:moveCardsAtomic(move1, true)

            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(card_ids) do
                if not sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                    get:addSubcard(sgs.Sanguosha:getCard(id))
                end
            end
            if get:subcardsLength() > 0 then 
                room:obtainCard(player, get, true) 

                for _,id in sgs.qlist(get:getSubcards()) do
                    card_ids:removeOne(id)
                end
            end
            get:deleteLater()

            if not card_ids:isEmpty() then
                local log = sgs.LogMessage()
                log.type = "$MoveToDiscardPile"
                log.from = player
                log.card_str = table.concat(sgs.QList2Table(card_ids), "+")
                room:sendLog(log)

                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                local move2 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_DiscardPile, reason2)
                room:moveCardsAtomic(move2, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getPhase() == sgs.Player_Play
    end,
}

ny_10th_linglong = sgs.CreateTriggerSkill{
    name = "ny_10th_linglong",
    events = {sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.CardsMoveOneTime,sgs.CardUsed, sgs.InvokeSkill},
    frequency = sgs.Skill_Compulsory,
    waked_skills = "qicai",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() and player:getMark("ny_10th_linglong_qicai") > 0 then
                player:setMark("ny_10th_linglong_qicai", 0)
                room:detachSkillFromPlayer(player, "qicai")
            end
            if data:toString() == "qicai" and player:hasSkill(self) then
                if player:getTreasure() or player:hasSkill("qicai",true) then return false end
                player:setMark("ny_10th_linglong_qicai", 1)
                room:acquireSkill(player, "qicai")
            end
        end
		if not player:hasSkill(self:objectName()) then return false end
        if event == sgs.EventAcquireSkill then
            if player:getTreasure() or player:hasSkill("qicai",true) then return false end
			room:sendCompulsoryTriggerLog(player, self)
			player:setMark("ny_10th_linglong_qicai", 1)
			room:acquireSkill(player, "qicai")
        elseif event == sgs.CardsMoveOneTime then
            if player:getMark("ny_10th_linglong_qicai") == 0 then
                if player:getTreasure() or player:hasSkill("qicai",true) then return false end
                room:sendCompulsoryTriggerLog(player, self)
                player:setMark("ny_10th_linglong_qicai", 1)
                room:acquireSkill(player, "qicai")
            end
            if player:getMark("ny_10th_linglong_qicai") > 0 then
                if not player:getTreasure() then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:setMark("ny_10th_linglong_qicai", 0)
                room:detachSkillFromPlayer(player, "qicai")
            end
        elseif event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card:isKindOf("Slash") or use.card:isNDTrick() then
				if player:getTreasure() or player:getArmor() or player:getDefensiveHorse()
				or player:getOffensiveHorse() then return false end
                    room:broadcastSkillInvoke(self:objectName())

                    local log = sgs.LogMessage()
				log.type = "#ny_10th_linglong_noresponse"
                    log.from = player
                    log.arg = self:objectName()
                    log.card_str = use.card:toString()
                    room:sendLog(log)

                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
        elseif event == sgs.InvokeSkill then
            if data:toString() == "eight_diagram" then
                room:sendCompulsoryTriggerLog(player, self)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_10th_linglong_max = sgs.CreateMaxCardsSkill{
    name = "#ny_10th_linglong_max",
    extra_func = function(self, player)
        if (not player:getDefensiveHorse()) and (not player:getOffensiveHorse()) and player:hasSkill("ny_10th_linglong") then
            return 2
        end
        return 0
    end,
}

ny_10th_linglong_armor = sgs.CreateViewAsEquipSkill{
    name = "#ny_10th_linglong_armor",
	view_as_equip = function(self,target)
		if target:getArmor() == nil and target:hasSkill("ny_10th_linglong") then
	    	return "eight_diagram"
		end
	end 
}

ny_10th_jxqunhuangyueying:addSkill(ny_10th_jiqiao)
ny_10th_jxqunhuangyueying:addSkill(ny_10th_linglong)
ny_10th_jxqunhuangyueying:addSkill(ny_10th_linglong_max)
ny_10th_jxqunhuangyueying:addSkill(ny_10th_linglong_armor)
extension:insertRelatedSkills("ny_10th_linglong", "#ny_10th_linglong_armor")
extension:insertRelatedSkills("ny_10th_linglong", "#ny_10th_linglong_max")

ny_10th_zhangmancheng = sgs.General(extension, "ny_10th_zhangmancheng", "qun", 4, true, false, false)

ny_10th_zhongji = sgs.CreateTriggerSkill{
    name = "ny_10th_zhongji",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if (not card) or (card and card:isKindOf("SkillCard")) then return false end
        if player:getHandcardNum() >= player:getMaxHp() then return false end
        for _,cc in sgs.qlist(player:getHandcards()) do
            if cc:getSuit() == card:getSuit() then return false end
        end

        local draw = player:getMaxHp() - player:getHandcardNum()
        local dis = 1 + player:getMark("&ny_10th_zhongji-Clear")
        local prompt = string.format("draw:%s::%s:", draw, dis)
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, "&ny_10th_zhongji-Clear", 1)
            player:drawCards(draw, self:objectName())
            if player:isAlive() then
                room:askForDiscard(player, self:objectName(), dis, dis, false, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_lvecheng = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_lvecheng",
    view_as = function(self)
        return ny_10th_lvechengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_lvecheng")
    end
}

ny_10th_lvechengCard = sgs.CreateSkillCard
{
    name = "ny_10th_lvecheng",
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        for _,card in sgs.qlist(effect.from:getHandcards()) do
            if card:isKindOf("Slash") then
                room:setCardFlag(card, "ny_10th_lvecheng")
                room:setCardTip(card:getEffectiveId(), "ny_10th_lvecheng")
            end
        end
        room:setPlayerMark(effect.to, "&ny_10th_lvecheng-Clear", 1)
        room:setPlayerMark(effect.to, "ny_10th_lvecheng_from"..effect.from:objectName().."-Clear", 1)
    end
}

ny_10th_lvecheng_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_lvecheng_buff",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            room:setPlayerFlag(player, "ny_10th_lvecheng")
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("ny_10th_lvecheng") then
                    room:setCardFlag(card, "-ny_10th_lvecheng")
                    room:setCardTip(card:getEffectiveId(), "-ny_10th_lvecheng")
                end
            end
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("ny_10th_lvecheng_from"..player:objectName().."-Clear") > 0 
                and p:getHandcardNum() > 0 then
                    room:sendCompulsoryTriggerLog(player, "ny_10th_lvecheng", true, true)
                    room:showAllCards(p)
                    local slashs = {}
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:isKindOf("Slash") then
                            table.insert(slashs, card)
                        end
                    end

                    if #slashs > 0 then
                        local pormpt = string.format("use:%s:", player:getGeneralName())
                        if room:askForSkillInvoke(p, "ny_10th_lvecheng", sgs.QVariant(prompt), false) then
                            for _,slash in ipairs(slashs) do
                                if not p:isProhibited(player, slash) then
                                    room:useCard(sgs.CardUseStruct(slash, p, player))
                                end
                                if player:isDead() then return false end
                            end
                        end
                    end
                end
                if player:isDead() then return false end
            end
            room:setPlayerFlag(player, "-ny_10th_lvecheng")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_lvecheng_target = sgs.CreateTargetModSkill{
    name = "#ny_10th_lvecheng_target",
    residue_func = function(self, from, card, to)
        if card:hasFlag("ny_10th_lvecheng") and to and to:getMark("ny_10th_lvecheng_from"..from:objectName().."-Clear") > 0 then
            return 1000
        end
        return 0
    end,
}


ny_10th_zhangmancheng:addSkill(ny_10th_lvecheng)
ny_10th_zhangmancheng:addSkill(ny_10th_lvecheng_buff)
ny_10th_zhangmancheng:addSkill(ny_10th_lvecheng_target)
extension:insertRelatedSkills("ny_10th_lvecheng", "#ny_10th_lvecheng_buff")
extension:insertRelatedSkills("ny_10th_lvecheng", "#ny_10th_lvecheng_target")
ny_10th_zhangmancheng:addSkill(ny_10th_zhongji)

ny_10th_luyi = sgs.General(extension, "ny_10th_luyi", "qun", 3, false, false, false)

local function yaoyiChangeState(player)
    if not player then return 2 end
    for _,skill in sgs.qlist(player:getVisibleSkillList()) do
        if (not skill:isAttachedLordSkill()) and skill:isChangeSkill() then
            if player:getChangeSkillState(skill:objectName()) <= 1 then
                return 0
            else
                return 1
            end
        end
    end
    return 2
end

ny_10th_yaoyi = sgs.CreateProhibitSkill{
    name = "ny_10th_yaoyi",
    is_prohibited = function(self, from, to, card)
        if from:objectName() == to:objectName() then return false end
        local find = false
        if from:hasSkill("ny_10th_yaoyi") then
            find = true
        else
            for _,player in sgs.qlist(from:getAliveSiblings()) do
                if player:hasSkill("ny_10th_yaoyi") then
                    find = true
                    break
                end
            end
        end
        if not find then return false end
        local st1 = yaoyiChangeState(from)
        local st2 = yaoyiChangeState(to)
        if st1 == 2 or st2 == 2 then return false end
        if card and (not card:isKindOf("SkillCard")) and (st1 == st2) then return true end
        return false
    end,
}

ny_10th_yaoyi_start = sgs.CreateTriggerSkill{
    name = "#ny_10th_yaoyi_start",
    events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:broadcastSkillInvoke("ny_10th_yaoyi")
        for _,target in sgs.qlist(room:getAlivePlayers()) do
            local cfind = true
            for _,skill in sgs.qlist(target:getVisibleSkillList()) do
                if (not skill:isAttachedLordSkill()) and skill:isChangeSkill() then
                    cfind = false
                    break
                end
            end
            if cfind then
                room:acquireSkill(target, "ny_10th_shoutan")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shoutan = sgs.CreateViewAsSkill
{
    name = "ny_10th_shoutan",
    n = 99,
    view_filter = function(self, selected, to_select)
        if not sgs.Self:getHandcards():contains(to_select) then return false end
        if sgs.Self:hasSkill("ny_10th_yaoyi") then return false end
        if sgs.Self:getChangeSkillState(self:objectName()) <= 1 then
            return  #selected < 1 and (not to_select:isBlack())
        elseif sgs.Self:getChangeSkillState(self:objectName()) == 2 then
            return  #selected < 1 and to_select:isBlack()
        end
	end,
    view_as = function(self, cards)
        if #cards == 0 and (not sgs.Self:hasSkill("ny_10th_yaoyi")) then return nil end 
        local cc = ny_10th_shoutanCard:clone()
        if sgs.Self:hasSkill("ny_10th_yaoyi") then return cc end
        for _,card in ipairs(cards) do
            cc:addSubcard(card)
        end
        return cc
    end,
    enabled_at_play = function(self, player)
        if player:hasSkill("ny_10th_yaoyi") then 
            return true
        else
            return not player:hasUsed("#ny_10th_shoutan")
        end
    end,
}

ny_10th_shoutantr = sgs.CreateTriggerSkill{
    name = "ny_10th_shoutan",
    events = {},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_10th_shoutan,
    change_skill = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}


ny_10th_shoutanCard = sgs.CreateSkillCard
{
    name = "ny_10th_shoutan",
    will_throw = true,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:hasSkill("ny_10th_yaoyi") then
            room:broadcastSkillInvoke("ny_10th_yaoyi")
        end
        if source:getChangeSkillState(self:objectName()) <= 1 then
            room:setChangeSkillState(source, self:objectName(), 2)
        elseif source:getChangeSkillState(self:objectName()) == 2 then
            room:setChangeSkillState(source, self:objectName(), 1)
        end
    end
}

ny_tenth_fuxueVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_fuxue",
    n = 99,
    response_pattern = "@@ny_tenth_fuxue",
    expand_pile = "#ny_tenth_fuxue",
    view_filter = function(self, selected, to_select)
        if  (not sgs.Self:getPile("#ny_tenth_fuxue"):contains(to_select:getId())) then return false end
        return #selected < sgs.Self:getHp()
    end,
    view_as = function(self, cards)
        local card = ny_tenth_fuxueCard:clone()
        if #cards == 0 then return nil end
            for _,p in ipairs(cards) do
                card:addSubcard(p)
            end
        return card
    end,
    enabled_at_play = function(self,player)
        return false
    end,
}

ny_tenth_fuxueCard = sgs.CreateSkillCard
{
    name = "ny_tenth_fuxue",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        return false
    end
}

ny_tenth_fuxue = sgs.CreateTriggerSkill{
    name = "ny_tenth_fuxue",
    view_as_skill = ny_tenth_fuxueVS,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) then return false end
            local old_cards = player:getTag("ny_tenth_fuxue_cards"):toIntList()
            if not old_cards then
                old_cards = move.card_ids
            else
                for _,id in sgs.qlist(move.card_ids) do
                    old_cards:append(id)
                end
            end
            local tag = sgs.QVariant()
            tag:setValue(old_cards)
            player:setTag("ny_tenth_fuxue_cards", tag)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                local all = player:getTag("ny_tenth_fuxue_cards"):toIntList()
                if (not all) or (all:isEmpty()) then return false end
                local now = sgs.IntList()
                for _,id in sgs.qlist(room:getDiscardPile()) do
                    if all:contains(id) then
                        now:append(id)
                    end
                end
                if now:isEmpty() then
                    player:removeTag("ny_tenth_fuxue_cards")
                    return false
                end
                local tag = sgs.QVariant()
                tag:setValue(now)
                player:setTag("ny_tenth_fuxue_cards", tag)

                room:notifyMoveToPile(player, now, "ny_tenth_fuxue", sgs.Player_DiscardPile, true)
                local card = room:askForUseCard(player, "@@ny_tenth_fuxue", "@ny_tenth_fuxue:"..player:getHp())
                room:notifyMoveToPile(player, now, "ny_tenth_fuxue", sgs.Player_DiscardPile, false)

                if card then
                    local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    get:addSubcards(card:getSubcards())
                    for _,c in sgs.qlist(card:getSubcards()) do
                        now:removeOne(c)
                    end
                    room:obtainCard(player, get, false)
                    for _,cc in sgs.qlist(player:getHandcards()) do
                        if get:getSubcards():contains(cc:getId()) then
                            room:setCardTip(cc:getEffectiveId(),"ny_tenth_fuxue")
                            room:setCardFlag(cc, "ny_tenth_fuxue")
                        end
                    end
                    get:deleteLater()
                    player:removeTag("ny_tenth_fuxue_cards")
                    local newtag = sgs.QVariant()
                    newtag:setValue(now)
                    player:setTag("ny_tenth_fuxue_cards", newtag)
                end
            end
            if player:getPhase() == sgs.Player_Finish then
                local can = false
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_tenth_fuxue") then 
                        can = true
                        room:setCardTip(card:getEffectiveId(),"-ny_tenth_fuxue")
                        room:setCardFlag(card, "-ny_tenth_fuxue")
                    end
                end
                if can then return false end
                local prompt = string.format("draw:%d:",player:getHp())
                if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(player:getHp(), self:objectName())
            end
            if player:getPhase() == sgs.Player_NotActive then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_tenth_fuxue") then 
                        room:setCardTip(card:getEffectiveId(),"-ny_tenth_fuxue")
                        room:setCardFlag(card, "-ny_tenth_fuxue")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}


ny_10th_luyi:addSkill(ny_tenth_fuxue)
ny_10th_luyi:addSkill(ny_tenth_fuxueVS)
ny_10th_luyi:addSkill(ny_10th_yaoyi)
ny_10th_luyi:addSkill(ny_10th_yaoyi_start)
extension:insertRelatedSkills("ny_10th_yaoyi", "#ny_10th_yaoyi_start")

ny_10th_xingcaoren = sgs.General(extension, "ny_10th_xingcaoren", "wei", 4, true, false, false)

ny_10th_sujun = sgs.CreateTriggerSkill{
    name = "ny_10th_sujun",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if (not card) or (card:isKindOf("SkillCard")) then return false end
        local basic = 0
        local nobasic = 0
        for _,cc in sgs.qlist(player:getHandcards()) do
            if cc:isKindOf("BasicCard") then
                basic = basic + 1
            else
                nobasic = nobasic + 1
            end
        end
        if basic ~= nobasic then return false end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(2, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_lifengvs = sgs.CreateViewAsSkill{
    name = "ny_10th_lifeng",
    n = 1,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getMark(to_select:getColorString().."ny_10th_lifeng-Clear")<1
		and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 1 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern():split("+")
			if #pattern<1 then pattern = {"slash"} end
            local cc = sgs.Sanguosha:cloneCard(pattern[1])
            cc:setSkillName(self:objectName())
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return player:getHandcardNum()>0
    end,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or player:isKongcheng() then return false end
        return pattern == "slash" or pattern == "Slash" or pattern == "nullification"
    end,
}

ny_10th_lifeng = sgs.CreateTriggerSkill{
    name = "ny_10th_lifeng",
    events = {sgs.CardUsed, sgs.CardResponded},
    view_as_skill = ny_10th_lifengvs,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				use.m_addHistory = false
				data:setValue(use)
			end
            card = use.card
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
		if card and card:getTypeId()>0 then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:addPlayerMark(p, card:getColorString().."ny_10th_lifeng-Clear")
            end
		end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_10th_xingcaoren:addSkill(ny_10th_sujun)
ny_10th_xingcaoren:addSkill(ny_10th_lifeng)

ny_10th_jiezhangsong = sgs.General(extension, "ny_10th_jiezhangsong", "shu", 3, true, false, false)

ny_10th_jxxiantu = sgs.CreateTriggerSkill{
    name = "ny_10th_jxxiantu",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self:objectName()) and p:getMark("ny_10th_jxxiantufail-PlayClear") == 0 then
                    local prompt = string.format("draw:%s:",player:getGeneralName())
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerMark(p, "&ny_10th_jxxiantu-PlayClear", 1)
                        p:drawCards(2, self:objectName())
                        local give = room:askForExchange(p, self:objectName(), 2, 2, true, "@ny_10th_jxxiantu:"..player:getGeneralName(), false)
                        if give then
                            player:obtainCard(give, false)
                        end
                    else
                        room:setPlayerMark(p, "ny_10th_jxxiantufail-PlayClear", 1)
                    end
                end
            end
        end
        if event == sgs.Damage then
            room:setPlayerMark(player, "ny_10th_jxxiantuda-PlayClear", 1)
        end
        if event == sgs.EventPhaseEnd then
            if player:getMark("ny_10th_jxxiantuda-PlayClear") > 0 then return false end
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self:objectName()) and p:getMark("&ny_10th_jxxiantu-PlayClear") > 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(p, "&ny_10th_jxxiantu-PlayClear", 0)
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    room:loseHp(p, 1, true, p, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target:getPhase() == sgs.Player_Play
    end,
}

local function getTypeString(card)
    for _,p in ipairs({"BasicCard","TrickCard","EquipCard"}) do
        if card:isKindOf(p) then
            return p
        end
    end
end

ny_10th_jxqiangzhi = sgs.CreateTriggerSkill{
    name = "ny_10th_jxqiangzhi",
    events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            local tas = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() > 0 then
                    tas:append(p)
                end
            end
            local ta = room:askForPlayerChosen(player, tas, self:objectName(), "@ny_10th_jxqiangzhi", true, true)
            if not ta then return false end
            room:broadcastSkillInvoke(self:objectName())
            local show = room:askForCardChosen(player, ta, "h", self:objectName())
            local showc = sgs.Sanguosha:getCard(show)
            local ctype = getTypeString(showc)
            room:setPlayerMark(player, "&ny_10th_jxqiangzhi+"..ctype.."-PlayClear", 1)
            room:showCard(ta, show)
            return false
        end
        local card = nil
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            local res = data:toCardResponse()
            if res.m_isUse then
                card = res.m_card
            end
        end
        if not card or card:getTypeId()<1 then return false end
        local ctype = getTypeString(card)
        if player:getMark("&ny_10th_jxqiangzhi+"..ctype.."-PlayClear") == 0 then return false end
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        room:broadcastSkillInvoke(self:objectName())
        player:drawCards(1, self:objectName())
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Play
    end,
}

ny_10th_jiezhangsong:addSkill(ny_10th_jxxiantu)
ny_10th_jiezhangsong:addSkill(ny_10th_jxqiangzhi)

ny_10th_caochun = sgs.General(extension, "ny_10th_caochun", "wei", 4, true, false, false)

ny_tenth_shanjiaVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_shanjia",
    response_pattern = "@@ny_tenth_shanjia",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

ny_tenth_shanjia = sgs.CreateTriggerSkill{
    name = "ny_tenth_shanjia",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_shanjiaVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:getMark("&ny_tenth_shanjia") >= 3 then return false end
            if move.from and move.from:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
            then else return false end
            if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) then return false end
            local n = player:getMark("&ny_tenth_shanjia")
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                    n = n + 1
                end
            end
            n = math.min(n, 3)
            room:setPlayerMark(player, "&ny_tenth_shanjia", n)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local n = 3 - player:getMark("&ny_tenth_shanjia")
            n = math.max(n,0)
            local prompt = string.format("draw:%s:", n)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(3, self:objectName())
                
                local canslash = true
                room:setPlayerMark(player, "ny_tenth_shanjia_slash-PlayClear", 1)
                room:setPlayerMark(player, "ny_tenth_shanjia_distance-PlayClear", 1)

                local dis
                if n > 0 then
                    dis = room:askForDiscard(player, self:objectName(), n, n, false, true)
                end
                if dis then
                    for _,id in sgs.qlist(dis:getSubcards()) do
                        if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                            room:setPlayerMark(player, "ny_tenth_shanjia_slash-PlayClear", 0)
                            canslash = false
                        end
                        if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
                            room:setPlayerMark(player, "ny_tenth_shanjia_distance-PlayClear", 0)
                            canslash = false
                        end
                    end
                end
                if canslash then
                    room:askForUseCard(player, "@@ny_tenth_shanjia", "@ny_tenth_shanjia", -1,
                    sgs.Card_MethodUse, false, nil, nil, "RemoveFromHistory")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_shanjia_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_shanjia_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:getMark("ny_tenth_shanjia_slash-PlayClear") > 0 
        and card and card:isKindOf("Slash") then return 1 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:getMark("ny_tenth_shanjia_distance-PlayClear") > 0 then return 1000 end
        return 0
    end,
}

ny_10th_caochun:addSkill(ny_tenth_shanjia)
ny_10th_caochun:addSkill(ny_tenth_shanjiaVS)
ny_10th_caochun:addSkill(ny_tenth_shanjia_buff)
extension:insertRelatedSkills("ny_tenth_shanjia", "#ny_tenth_shanjia_buff")

ny_10th_liuye = sgs.General(extension, "ny_10th_liuye", "wei", 3, true, false, false)

ny_tenth_piliche = sgs.CreateTreasure
{
	name = "_ny_tenth_piliche",
	class_name = "Piliche",
    suit = sgs.Card_Diamond,
    number = 9,
	target_fixed = true,
    subtype = "ny_10th_liuye_card",
	on_install = function(self,player)
		local room = player:getRoom()
        room:acquireSkill(player, "ny_tenth_piliche_target", false, false, false)
        room:acquireSkill(player, "ny_tenth_piliche_buff", false, false, false)
        room:acquireSkill(player, "ny_tenth_piliche_destory", false, false, false)
        room:acquireSkill(player, "ny_tenth_piliche_recover", false, false, false)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
        room:detachSkillFromPlayer(player, "ny_tenth_piliche_target", true, true, false)
        room:detachSkillFromPlayer(player, "ny_tenth_piliche_buff", true, true, false)
        room:detachSkillFromPlayer(player, "ny_tenth_piliche_recover", true, true, false)
        --room:detachSkillFromPlayer(player, "ny_tenth_piliche_buff", true, true, false)
	end,
}
ny_tenth_piliche:setParent(extension)

ny_tenth_piliche_target = sgs.CreateTargetModSkill{
    name = "ny_tenth_piliche_target",
    pattern = "BasicCard",
    distance_limit_func = function(self, from, card)
        if from:getEquip(4) and from:getEquip(4):objectName() == "_ny_tenth_piliche" 
        and from:getPhase() ~= sgs.Player_NotActive then return 1000 end
        return 0
    end,
}

ny_tenth_piliche_buff = sgs.CreateTriggerSkill{
    name = "ny_tenth_piliche_buff",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    priority = 10,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                card = data:toCardResponse().m_card
            end
            if (not card) or (not card:isKindOf("BasicCard")) then return false end
            if player:getPhase() == sgs.Player_NotActive then
                room:sendCompulsoryTriggerLog(player, "_ny_tenth_piliche", true)
                player:drawCards(1, self:objectName())
            end
            if player:getPhase() ~= sgs.Player_NotActive then
                if card:isKindOf("Analeptic") and player:getHp() >= 1 then
                    local ana = player:getMark("drank")
                    ana = ana + 1
                    room:setPlayerMark(player, "drank", ana)
                end
                room:setCardFlag(card, "ny_tenth_piliche_buff")
            end
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then return false end
            if player:getPhase() == sgs.Player_NotActive then return false end
            if damage.card and damage.card:isKindOf("BasicCard") then
                local log = sgs.LogMessage()
                log.type = "$ny_tenth_piliche_damage"
                log.from = damage.from
                log.arg = "_ny_tenth_piliche"
                log.arg2 = damage.damage
                log.arg3 = damage.damage + 1
                log.card_str = damage.card:toString()
                room:sendLog(log)

                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getEquip(4) and target:getEquip(4):objectName() == "_ny_tenth_piliche"
    end,
}

ny_tenth_piliche_recover = sgs.CreateTriggerSkill{
    name = "ny_tenth_piliche_recover",
    events = {sgs.PreHpRecover},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("ny_tenth_piliche_buff") then
                local log = sgs.LogMessage()
                log.type = "$ny_tenth_piliche_recover"
                log.from = recover.from
                log.arg = "_ny_tenth_piliche"
                log.arg2 = recover.recover
                log.arg3 = recover.recover + 1
                log.card_str = recover.card:toString()
                room:sendLog(log)

                recover.recover = recover.recover + 1
                data:setValue(recover)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_tenth_piliche_destory = sgs.CreateTriggerSkill{
    name = "ny_tenth_piliche_destory",
    events = {sgs.BeforeCardsMove},
    frequency = sgs.Skill_Compulsory,
    priority = 50,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then else return false end
        local card = nil
        if move.from_places:contains(sgs.Player_PlaceEquip) and move.to_place ~= sgs.Player_PlaceTable then
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):objectName() == "_ny_tenth_piliche" then
                    card = sgs.Sanguosha:getCard(id)
                    move.card_ids:removeOne(id)
                end
            end
        end
        if card then
            room:sendCompulsoryTriggerLog(player, "_ny_tenth_piliche", true, true)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "ny_tenth_piliche","")
            local new_move = sgs.CardsMoveStruct(card:getId(), nil, sgs.Player_PlaceTable, reason)
            room:moveCardsAtomic(new_move, true)
            data:setValue(move)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_poyuan = sgs.CreateTriggerSkill{
    name = "ny_10th_poyuan",
    events = {sgs.GameStart, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    waked_skills = "_ny_tenth_piliche",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_RoundStart then return false end
        end
        if ((not player:getEquip(4)) 
            or (player:getEquip(4) and player:getEquip(4):objectName() ~= "_ny_tenth_piliche" ))
            and player:hasEquipArea(4) then
                local card = nil
                for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                    if sgs.Sanguosha:getEngineCard(id):isKindOf("Piliche") then
                        card = sgs.Sanguosha:getEngineCard(id)
                        break
                    end
                end
                if card then
                    if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("put")) then return false end
                    room:broadcastSkillInvoke(self:objectName())

                    if player:getEquip(4) then
                        room:throwCard(player:getEquip(4), player, player)
                    end

                    local log = sgs.LogMessage()
                    log.type = "$ny_10th_poyuan_get"
                    log.from = player
                    log.arg = self:objectName()
                    log.card_str = card:toString()
                    room:sendLog(log)

                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                    room:moveCardTo(card, nil, player, sgs.Player_PlaceEquip, reason)
                end
        else
                local targets = sgs.SPlayerList()
                for _,target in sgs.qlist(room:getOtherPlayers(player)) do
                    if (not target:isNude()) then
                        targets:append(target)
                    end
                end
                if targets:isEmpty() then return false end
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@@ny_10th_poyuan", true, true)
                if not target then return false end
                room:broadcastSkillInvoke(self:objectName())

                local choices = "1"
                if target:getCards("he"):length() > 1 then
                    choices = "1+2"
                end
                local max = tonumber(room:askForChoice(player, self:objectName(), choices, sgs.QVariant(), nil, "ny_10th_poyuan_dis"))

                --[[local places = {}
                local discards = sgs.IntList()
                room:setPlayerFlag(target, "mobilepojun_InTempMoving")
                for i = 1, max, 1 do
                    if not target:isNude() then
                        --local id = room:askForCardChosen(player, target, "he", "ny_10th_poyuan")
                        local id = room:askForCardChosen(player, target, "he", self:objectName(),
                        false, sgs.Card_MethodDiscard, sgs.IntList(), false)
                        discards:append(id)
                        table.insert(places, room:getCardPlace(id))
                        target:addToPile("#ny_10th_poyuan", id, false)
                    end
                end
                local i = 1
                for _,id in sgs.qlist(discards) do
                    room:moveCardTo(sgs.Sanguosha:getCard(id), target, places[i], false)
                    i = i + 1
                end
                room:setPlayerFlag(target, "-mobilepojun_InTempMoving")]]--

                --local discards = cardsChosen(room, player, target, self:objectName(), "he", max)

                local discards = sgs.IntList()

                for i = 1, 2 do--进行多次执行
                    local id = room:askForCardChosen(player, target, "he", self:objectName(),
                        false,--选择卡牌时手牌不可见
                        sgs.Card_MethodDiscard,--设置为弃置类型
                        discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
                        i>1)--只有执行过一次选择才可取消
                    if id < 0 then break end--如果卡牌id无效就结束多次执行
                    discards:append(id)--将选择的id添加到虚拟卡的子卡表
                end

                room:throwCard(discards, "ny_10th_poyuan", target, player)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_huace = sgs.CreateViewAsSkill{
    name = "ny_10th_huace",
    n = 99,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local c = sgs.Self:getTag("ny_10th_huace"):toCard()
            if c then
                local cc = ny_10th_huaceCard:clone()
                cc:addSubcard(cards[1])
                cc:setUserString(c:objectName())
                return cc
            end
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_huace")
    end
}
ny_10th_huace:setGuhuoDialog("r")

ny_10th_huaceCard = sgs.CreateSkillCard{
	name = "ny_10th_huace",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_huace")

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
        card:deleteLater()
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets, player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_huace")

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
        card:deleteLater()
		return card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_huace")
        card:deleteLater()
		return card
	end,
}

ny_10th_huace_record = sgs.CreateTriggerSkill{
    name = "#ny_10th_huace_record",
    events = {sgs.CardUsed, sgs.CardResponded,sgs.RoundStart,sgs.GameStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card 
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or (not card:isKindOf("TrickCard")) then return false end
            local used = room:getTag("ny_10th_huace_uesd"):toString():split("+")
            if not used then
                used = {}
            end
            if not table.contains(used, card:objectName()) then
                table.insert(used, card:objectName())
            end
            room:setTag("ny_10th_huace_uesd", sgs.QVariant(table.concat(used, "+")))
        end
        if event == sgs.RoundStart then
            local used = room:getTag("ny_10th_huace_uesd"):toString():split("+")
            --[[for _,target in sgs.qlist(room:getAlivePlayers()) do
                for _,mark in sgs.list(target:getMarkNames()) do
                    if string.find(mark, "ny_10th_huace_guhuo_remove_") then 
                        room:setPlayerMark(target, mark, 0)
                    end
                end
            end
            if not used then return false end]]--
            room:removeTag("ny_10th_huace_uesd")
            for _,target in sgs.qlist(room:getAlivePlayers()) do
                for _,name in ipairs(used) do
                    local mark = string.format("ny_10th_huace_guhuo_remove_%s_lun", name)
                    room:setPlayerMark(target, mark, 1)
                    --room:setPlayerMark(target, "ny_10th_huace_guhuo_remove_"..name, 1)
                end
            end
        end
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            if event == sgs.EventAcquireSkill then
                if data:toString() ~= "ny_10th_huace" then return false end
            end
            local tag = room:getTag("ny_10th_huace_cards")
            --if tag then return false end
            local names = {}
            for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                local card = sgs.Sanguosha:getEngineCard(id)
                if card:isNDTrick() then
                    local name = card:objectName()
                    if not table.contains(names, name) then
                        table.insert(names, name)
                    end
                end
            end
            room:setTag("ny_10th_huace_cards", sgs.QVariant(table.concat(names, "+")))
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_liuye:addSkill(ny_10th_poyuan)
ny_10th_liuye:addSkill(ny_10th_huace)
ny_10th_liuye:addSkill(ny_10th_huace_record)
extension:insertRelatedSkills("ny_10th_huace", "#ny_10th_huace_record")

ny_10th_zhangjinyun = sgs.General(extension, "ny_10th_zhangjinyun", "shu", 3, false, false, false)

ny_10th_huizhi = sgs.CreateTriggerSkill{
    name = "ny_10th_huizhi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            if not room:askForSkillInvoke(player, self:objectName()) then return false end
            room:broadcastSkillInvoke(self:objectName())
            room:askForDiscard(player, self:objectName(), 999, 0, false, false, "@ny_10th_huizhi", ".", self:objectName())
            if player:isDead() then return false end
            local max = 0
            for _,target in sgs.qlist(room:getAlivePlayers()) do
                if target:getHandcardNum() > max then
                    max = target:getHandcardNum()
                end
            end
            if max <= player:getHandcardNum() then
                player:drawCards(1, self:objectName())
            else
                local draw = max - player:getHandcardNum()
                draw = math.min(draw, 5)
                player:drawCards(draw, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jijiao = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_jijiao",
    limit_mark = "@ny_10th_jijiao_mark",
    frequency = sgs.Skill_Limited,
    view_as = function(self, player)
        return ny_10th_jijiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@ny_10th_jijiao_mark") > 0
        and player:getMark("ny_10th_jijiao_usedcard") > 0
    end
}

ny_10th_jijiaoCard = sgs.CreateSkillCard
{
    name = "ny_10th_jijiao",
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@ny_10th_jijiao_mark", 1)
        local ids = effect.from:getTag("ny_10th_jijiao_cards"):toIntList()
        local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
        get:deleteLater()
        for _,id in sgs.qlist(room:getDiscardPile()) do
            if ids:contains(id) then
                get:addSubcard(sgs.Sanguosha:getCard(id))
            end
        end
        if get:subcardsLength() == 0 then return false end
        room:obtainCard(effect.to, get, true)
        if effect.to:isDead() then return false end
        for _,id in sgs.qlist(get:getSubcards()) do
            local card = sgs.Sanguosha:getCard(id)
            room:setCardFlag(card, "ny_10th_jijiao")
            room:setCardTip(id, "ny_10th_jijiao")
        end
    end
}

ny_10th_jijiao_record = sgs.CreateTriggerSkill{
    name = "#ny_10th_jijiao_record",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then else return false end
        local ids = player:getTag("ny_10th_jijiao_cards"):toIntList()
        if not ids then ids = sgs.IntList() end

        if (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) then
        elseif (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
        else return false end

        for _,id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(id):isNDTrick() and (not ids:contains(id)) then
                ids:append(id)
                room:setPlayerMark(player, "ny_10th_jijiao_usedcard", 1)
            end
        end

        local tag = sgs.QVariant()
        tag:setValue(ids)
        player:setTag("ny_10th_jijiao_cards", tag)

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jijiao_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_jijiao_buff",
    events = {sgs.EventPhaseChanging, sgs.Death, sgs.CardUsed, sgs.SwappedPile},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death or event == sgs.SwappedPile then
            for _,target in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(target, "ny_10th_jijiao_new-Clear", 1)
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            if player:getMark("ny_10th_jijiao_new-Clear") == 0 then return false end
            for _,skiller in sgs.qlist(room:findPlayersBySkillName("ny_10th_jijiao")) do
                if skiller:getMark("@ny_10th_jijiao_mark") == 0 then
                    room:setPlayerMark(skiller, "@ny_10th_jijiao_mark", 1)
                    room:broadcastSkillInvoke("ny_10th_jijiao")
                    local log = sgs.LogMessage()
                    log.type = "$ny_10th_jijiao_renew"
                    log.from = skiller
                    log.arg = "ny_10th_jijiao"
                    room:sendLog(log)
                end
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("ny_10th_jijiao") then
                local log = sgs.LogMessage()
                log.type = "$ny_10th_jijiao_nooffset"
                log.from = use.from
                log.arg = "ny_10th_jijiao"
                log.card_str = use.card:toString()
                room:sendLog(log)

                local no_offset_list = use.no_offset_list
                table.insert(no_offset_list, "_ALL_TARGETS")
                use.no_offset_list = no_offset_list
                data:setValue(use)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_zhangjinyun:addSkill(ny_10th_huizhi)
ny_10th_zhangjinyun:addSkill(ny_10th_jijiao)
ny_10th_zhangjinyun:addSkill(ny_10th_jijiao_record)
ny_10th_zhangjinyun:addSkill(ny_10th_jijiao_buff)
extension:insertRelatedSkills("ny_10th_jijiao","#ny_10th_jijiao_record")
extension:insertRelatedSkills("ny_10th_jijiao","#ny_10th_jijiao_buff")

ny_10th_chenshi = sgs.General(extension, "ny_10th_chenshi", "shu", 4, true, false, false)


ny_10th_qingbei = sgs.CreateTriggerSkill{
    name = "ny_10th_qingbei",
    --events = {sgs.RoundStart, sgs.CardUsed, sgs.CardResponded, --[[sgs.PreCardResponded, sgs.PreCardUsed]]},
    events = {sgs.RoundStart, sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            local suits = {"heart","diamond","spade","club","cancel"}
            local chosen = {}
            while( #suits > 0) do
                local suit = room:askForChoice(player, self:objectName(), table.concat(suits, "+"), sgs.QVariant(), table.concat(chosen, "+"))
                if suit == "cancel" then break end
				if #chosen<1 then player:skillInvoked(self,-1) end
                    table.insert(chosen, suit)
                    table.removeOne(suits, suit)
                end
            if #chosen == 0 then return false end

			local log = sgs.LogMessage()
			log.type = "$ny_10th_qingbei_chosen"
			log.from = player
            local mark = "&ny_10th_qingbei+:"
            for _,suit in ipairs(chosen) do
                room:setPlayerMark(player, string.format("ny_10th_qingbei_mark_%s_lun", suit), 1)
                mark = mark.."+"..suit.."_char"
				log.arg = suit
				room:sendLog(log)
            end
            room:setPlayerMark(player, mark.."_lun", 1)
            room:setPlayerMark(player, "ny_10th_qingbei_lun", #chosen)
        end

        if event == sgs.CardFinished then
            local use = data:toCardUse()
            local caninvoke = false
            if (not use.card:isKindOf("SkillCard")) and use.m_isHandcard then caninvoke = true end
            if not caninvoke then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            player:drawCards(player:getMark("ny_10th_qingbei_lun"), self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_qingbei_limit = sgs.CreateCardLimitSkill
{
    name = "#ny_10th_qingbei_limit",
    limit_list = function(self, player)
            return "use"
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("ny_10th_qingbei") then 
            local limits = {}
            for _,suit in ipairs({"heart","diamond","spade","club","cancel"}) do
                if player:getMark(string.format("ny_10th_qingbei_mark_%s_lun", suit)) > 0 then
                    table.insert(limits, suit)
                end
            end
			if #limits>0 then
				return ".|"..table.concat(limits,",")
			end
        end
		return ""
    end,
}

ny_10th_chenshi:addSkill(ny_10th_qingbei)
ny_10th_chenshi:addSkill(ny_10th_qingbei_limit)
extension:insertRelatedSkills("ny_10th_qingbei", "#ny_10th_qingbei_limit")

ny_10th_ruanji = sgs.General(extension, "ny_10th_ruanji", "wei", 3, true, false, false)

ny_10th_jiudun = sgs.CreateTriggerSkill{
    name = "ny_10th_jiudun",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if (not use.to:contains(player)) then return false end
            if player:isDead() then return false end
            if use.from ~= player and (not use.card:isKindOf("SkillCard"))
            and use.card:isBlack() then else return false end

            if player:getMark("drank") == 0 then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(1, self:objectName())
                    if player:isDead() then return false end
                    local usec = sgs.CardUseStruct()
                    local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, -1)
                    analeptic:setSkillName("_"..self:objectName())
                        analeptic:deleteLater()
                    if not analeptic:isAvailable(player) then 
                        return false
                    end
                    usec.card = analeptic
                    usec.from = player
                    usec.to:append(player)
                    room:useCard(usec, false)
                end
            else
                local prompt = string.format("@ny_10th_jiudun:%s:", use.card:objectName())
                room:setTag("ny_10th_jiudun_card", data)
                if room:askForDiscard(player, self:objectName(), 1, 1, true, false, prompt, ".", self:objectName()) then
                    local nullified_list = use.nullified_list
		            table.insert(nullified_list, player:objectName())
		            use.nullified_list = nullified_list
		            data:setValue(use)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jiudun_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_jiudun_buff",
    events = {sgs.MarkChange},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,target in sgs.qlist(room:getAlivePlayers()) do
                    if target:hasSkill("ny_10th_jiudun") and target:getMark("drank") > 0 then
                        room:addPlayerMark(target, "ny_10th_jiudun", target:getMark("drank"))
                        room:setPlayerMark(target, "drank", 0)
                    end
                end
            end
            if change.from == sgs.Player_NotActive then
                for _,target in sgs.qlist(room:getAlivePlayers()) do
                    if target:hasSkill("ny_10th_jiudun") and target:getMark("ny_10th_jiudun") > 0 then
                        room:addPlayerMark(target, "drank", target:getMark("ny_10th_jiudun"))
                        room:setPlayerMark(target,"ny_10th_jiudun", 0)
                    end
                end
            end
		else
	    	local mark = data:toMark()
			if mark.name=="drank" and mark.gain<0 and player:hasSkill("ny_10th_jiudun") then
				return room:getCurrent():getPhase()>=sgs.Player_NotActive
			end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_zhaowenVS = sgs.CreateViewAsSkill{
    name = "ny_10th_zhaowen",
    n = 1,
    guhuo_type = "r",
    view_filter = function(self, selected, to_select)
        return to_select:isBlack() and #selected < 1
        and sgs.Self:getHandcards():contains(to_select)
        and to_select:hasFlag("ny_10th_zhaowen")
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local c = sgs.Self:getTag("ny_10th_zhaowen"):toCard()
            if c then
                local cc = ny_10th_zhaowenCard:clone()
                cc:addSubcard(cards[1])
                cc:setUserString(c:objectName())
                return cc
            end
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

ny_10th_zhaowenCard = sgs.CreateSkillCard{
	name = "ny_10th_zhaowen",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhaowen")
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets, player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhaowen")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhaowen")
        card:deleteLater()

        local room = player:getRoom()
        room:setPlayerMark(player, "ny_10th_zhaowen_guhuo_remove_"..self:getUserString().."-Clear", 1)
        room:setPlayerMark(player, "ny_10th_zhaowen_guhuo_remove_"..self:getUserString(), 1)
		return card
	end,
}

ny_10th_zhaowen = sgs.CreateTriggerSkill{
    name = "ny_10th_zhaowen",
    events = {sgs.EventPhaseStart, sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_10th_zhaowenVS,
    guhuo_type = "r",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                for _,mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "ny_10th_zhaowen_guhuo_remove") then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
            if player:getPhase() ~= sgs.Player_Play then return false end
            if player:isKongcheng() then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("show")) then
                room:broadcastSkillInvoke(self:objectName())
                local ids = sgs.IntList()
                for _,card in sgs.qlist(player:getHandcards()) do
                    ids:append(card:getId())
                end
                room:showCard(player, ids)
                for _,card in sgs.qlist(player:getHandcards()) do
                    room:setCardFlag(card, "ny_10th_zhaowen")
                    room:setCardTip(card:getEffectiveId(), "ny_10th_zhaowen")
                end
            end
        end
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
            if (not card) or card:isKindOf("SkillCard") then return false end
            if (not card:isRed()) or (not card:hasFlag("ny_10th_zhaowen")) then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            player:drawCards(1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhaowen_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_zhaowen_clear",
    events = {sgs.EventPhaseChanging,sgs.GameStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,card in sgs.qlist(player:getHandcards()) do
                    room:setCardFlag(card, "-ny_10th_zhaowen")
                    room:setCardTip(card:getEffectiveId(), "-ny_10th_zhaowen")
                end
            end
        end

        --给ai认牌的
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            if event == sgs.EventAcquireSkill then
                if data:toString() ~= "ny_10th_zhaowen" then return false end
            end
            --local tag = room:getTag("ny_10th_zhaowen_cards")
            --if tag then return false end
            local names = {}
            for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
                local card = sgs.Sanguosha:getEngineCard(id)
                if card:isNDTrick() then
                    local name = card:objectName()
                    if not table.contains(names, name) then
                        table.insert(names, name)
                    end
                end
            end
            room:setTag("ny_10th_zhaowen_cards", sgs.QVariant(table.concat(names, "+")))
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_ruanji:addSkill(ny_10th_zhaowen)
ny_10th_ruanji:addSkill(ny_10th_zhaowenVS)
ny_10th_ruanji:addSkill(ny_10th_zhaowen_clear)
ny_10th_ruanji:addSkill(ny_10th_jiudun)
ny_10th_ruanji:addSkill(ny_10th_jiudun_buff)
extension:insertRelatedSkills("ny_10th_jiudun", "#ny_10th_jiudun_buff")
extension:insertRelatedSkills("ny_10th_zhaowen", "#ny_10th_zhaowen_clear")

ny_10th_liuhui = sgs.General(extension, "ny_10th_liuhui", "qun", 4, true, false, false)

local function ny_gusuan_chosen(player, selected, num)
    local room = player:getRoom()
    local targets =  sgs.SPlayerList()
    for _,target in sgs.qlist(room:getAlivePlayers()) do
        if not selected:contains(target) then
            targets:append(target)
        end
    end
    if targets:isEmpty() then return nil end
    local prompt
    if num == 1 then prompt = "ny_10th_gusuan_draw"
    elseif num == 2 then prompt = "ny_10th_gusuan_discard"
    elseif num == 3 then prompt = "ny_10th_gusuan_change" end
    
    room:setPlayerFlag(player, prompt)
    local target = room:askForPlayerChosen(player, targets, "ny_10th_geyuan", prompt, true, true)
    room:broadcastSkillInvoke("ny_10th_gusuan")
    room:setPlayerFlag(player, "-"..prompt)
    return target
end

ny_10th_geyuan = sgs.CreateTriggerSkill{
    name = "ny_10th_geyuan",
    events = {sgs.GameStart,sgs.CardsMoveOneTime,sgs.EventForDiy},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            local allnums = {"A","J","Q","K"}
            for i = 2, 10 do
                table.insert(allnums, i)
            end
            local circle = {}
            while #allnums>0 do
                local num = allnums[math.random(1,#allnums)]
                table.insert(circle, num)
                table.removeOne(allnums, num)
            end
            room:sendCompulsoryTriggerLog(player, self)
            room:setPlayerMark(player, "&"..table.concat(circle, "+").."+#ny_10th_geyuan", 1)
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
			for _,id in sgs.qlist(move.card_ids) do
				local num = sgs.Sanguosha:getCard(id):getNumberString()
				local mt,mr = {},""
				for _,m in sgs.list(player:getMarkNames()) do
					if m:contains("+#ny_10th_geyuan") and player:getMark(m)>0 then
						mr = m
						m = string.gsub(m,"+#ny_10th_geyuan","")
						m = string.gsub(m,"&","")
						mt = m:split("+")
					end
				end
				if num==mt[1] or num==mt[#mt] then
					local circle = player:getTag("geyuan_circle"):toString():split("+")
					if #mt+#circle>12 then
						player:setMark("geyuan_first",id)
					end
					table.removeOne(mt, num)
					room:setPlayerMark(player, mr, 0)
					if #mt<1 then
						local allnums = {"A","J","Q","K"}
						for i = 2, 10 do
							table.insert(allnums, i)
						end
						local fn = sgs.Sanguosha:getCard(player:getMark("geyuan_first")):getNumberString()
						if player:getMark("ny_10th_gusuan")<1 then
							table.insert(circle, fn)
							table.insert(circle, num)
						end
						player:setTag("geyuan_circle",sgs.QVariant(table.concat(circle, "+")))
						for _,n in sgs.list(circle) do
							table.removeOne(allnums, n)
						end
						while #allnums>0 do
							local n = allnums[math.random(1,#allnums)]
							table.insert(mt, n)
							table.removeOne(allnums, n)
						end
						if player:getMark("ny_10th_gusuan")>0 then
							local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,3,"ny_10th_geyuan0",true,false)
							for i,p in sgs.qlist(tos) do
								if i<1 then
									p:drawCards(3,self:objectName())
								elseif i<2 then
									room:askForDiscard(p,self:objectName(),4,4,false,true)
								elseif i<3 then
									local get = room:getNCards(5, false, false)
									room:returnToEndDrawPile(get)
									room:moveCardsToEndOfDrawpile(p, p:handCards(), self:objectName())
									if p:isAlive() then
										local dummy = sgs.Sanguosha:cloneCard("jink")
										dummy:addSubcards(get)
										room:obtainCard(p, dummy, false)
										dummy:deleteLater()
									end
								end
							end
						else
							local get = sgs.Sanguosha:cloneCard("jink")
							for _,id in sgs.qlist(room:getDrawPile()) do
								local n = sgs.Sanguosha:getCard(id):getNumberString()
								if n == num or n == fn then
									get:addSubcard(sgs.Sanguosha:getCard(id))
								end
							end
							for _,pl in sgs.qlist(room:getAlivePlayers()) do
								for _,card in sgs.qlist(pl:getCards("ej")) do
									local n = card:getNumberString()
									if n == num or n == fn then
										get:addSubcard(card)
									end
								end
							end
							if get:subcardsLength() > 0 then
								room:sendCompulsoryTriggerLog(player, self)
								room:obtainCard(player, get, false)
							end
							get:deleteLater()
						end
						if player:isDead() then break end
					end
					if #mt<1 then break end
					room:setPlayerMark(player, "&"..table.concat(mt, "+").."+#ny_10th_geyuan", 1)
				end
			end
		end

        --[[if event == sgs.GameStart then
            local allnums = {}
            for i = 1, 13 do
                table.insert(allnums, i)
            end
            local circle = {}
            while #allnums>0 do
                local num = allnums[math.random(1,#allnums)]
                table.insert(circle, num)
                table.removeOne(allnums, num)
            end
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "&ny_10th_geyuan_last", #circle)
            player:setTag("ny_10th_geyuan_circle", sgs.QVariant(table.concat(circle, "+")))
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasFlag("ny_10th_gusuan") then return false end
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
            if #circle <= 0 then return false end
            if player:getMark("&ny_10th_geyuan_last") == #circle then
                for _,id in sgs.qlist(move.card_ids) do
                    local num = sgs.Sanguosha:getCard(id):getNumber()
                    if table.contains(circle, string.format("%d", num)) then
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        room:setPlayerMark(player, "ny_10th_geyuan_cf", num)
                        local nowcircle = {}
                        local position = -1
                        for i = 1, #circle, 1 do
                            if tonumber(circle[i]) == num then
                                position = i
                            end
                            if (i ~= position) and (position ~= -1) then
                                table.insert(nowcircle, circle[i])
                            end
                        end
                        for i = 1, position - 1, 1 do
                            table.insert(nowcircle, circle[i])
                        end
                        room:setPlayerMark(player, "&ny_10th_geyuan_last", #nowcircle)
                        room:setPlayerMark(player, "&ny_10th_geyuan_head", nowcircle[1])
                        room:setPlayerMark(player, "&ny_10th_geyuan_tail", nowcircle[#nowcircle])
                        player:setTag("ny_10th_geyuan_circle_now", sgs.QVariant(table.concat(nowcircle, "+")))
                        break
                    end
                end
            else
                local nowcircle = player:getTag("ny_10th_geyuan_circle_now"):toString():split("+")
                if #nowcircle <= 0 then return false end
                local finish = -1
                if #nowcircle > 1 then
                    local first = false
                    local last = false
                    for _,id in sgs.qlist(move.card_ids) do
                        local num = sgs.Sanguosha:getCard(id):getNumber()
                        if (not first) and num == tonumber(nowcircle[1]) then
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                            first = true
                            if #nowcircle == 1 then
                                finish = num
                            end
                            table.removeOne(nowcircle, nowcircle[1])
                        end
                        if (not last) and num == tonumber(nowcircle[#nowcircle]) then
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                            last = true
                            if #nowcircle == 1 then
                                finish = num
                            end
                            table.removeOne(nowcircle, nowcircle[#nowcircle])
                        end
                        if first and last then break end
                    end
                    if (first or last) and (#nowcircle > 0) then
                        room:setPlayerMark(player, "&ny_10th_geyuan_last", #nowcircle)
                        room:setPlayerMark(player, "&ny_10th_geyuan_head", nowcircle[1])
                        room:setPlayerMark(player, "&ny_10th_geyuan_tail", nowcircle[#nowcircle])
                        player:setTag("ny_10th_geyuan_circle_now", sgs.QVariant(table.concat(nowcircle, "+")))
                    elseif (#nowcircle == 0) then
                        room:setPlayerMark(player, "&ny_10th_geyuan_last", 0)
                        room:setPlayerMark(player, "&ny_10th_geyuan_head", 0)
                        room:setPlayerMark(player, "&ny_10th_geyuan_tail", 0)
                        player:removeTag("ny_10th_geyuan_circle_now")
                    end
                else
                    local en = false
                    for _,id in sgs.qlist(move.card_ids) do
                        local num = sgs.Sanguosha:getCard(id):getNumber()
                        if num == tonumber(nowcircle[1]) and (not en) then
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                            en = true
                            finish = num
                            table.removeOne(nowcircle, nowcircle[1])
                            break
                        end
                    end
                    if en then
                        room:setPlayerMark(player, "&ny_10th_geyuan_last", 0)
                        room:setPlayerMark(player, "&ny_10th_geyuan_head", 0)
                        room:setPlayerMark(player, "&ny_10th_geyuan_tail", 0)
                        player:removeTag("ny_10th_geyuan_circle_now")
                    end
                end
                if finish > 0 then
                    room:setPlayerMark(player, "ny_10th_geyuan_cn", finish)
                    room:getThread():trigger(sgs.EventForDiy, room, player, sgs.QVariant("ny_10th_geyuan_finish"))
                end
            end
        end
        if event == sgs.EventForDiy then
            local str = data:toString()
            if string.find(str, "ny_10th_geyuan_finish") then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                if player:getMark("ny_10th_gusuan") == 0 then
                    local num1 = player:getMark("ny_10th_geyuan_cn")
                    local num2 = player:getMark("ny_10th_geyuan_cf")
                    local get = sgs.Sanguosha:cloneCard("jink")
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local num = sgs.Sanguosha:getCard(id):getNumber()
                        if num == num1 or num == num2 then
                            get:addSubcard(sgs.Sanguosha:getCard(id))
                        end
                    end
                    for _,pl in sgs.qlist(room:getAlivePlayers()) do
                        for _,card in sgs.qlist(pl:getCards("ej")) do
                            local num = card:getNumber()
                            if num == num1 or num == num2 then
                                get:addSubcard(card)
                            end
                        end
                    end
                    if get:subcardsLength() > 0 then
                        room:obtainCard(player, get, false)
                    end
                    get:deleteLater()
                    local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
                    table.removeOne(circle, string.format("%d", num1))
                    table.removeOne(circle, string.format("%d", num2))
                    room:setPlayerMark(player, "&ny_10th_geyuan_last", #circle)
                    player:setTag("ny_10th_geyuan_circle", sgs.QVariant(table.concat(circle, "+")))
                else
                    room:setPlayerFlag(player, "ny_10th_gusuan")
                    
                    local selected = sgs.SPlayerList()
                    local target1 = ny_gusuan_chosen(player, selected, 1)
                    local target2
                    local target3
                    if target1 then 
                        selected:append(target1)
                        target1:drawCards(3,self:objectName())
                        target2 = ny_gusuan_chosen(player, selected, 2)
                        if target2 then
                            selected:append(target2)
                            room:askForDiscard(target2, self:objectName(), 4, 4, false, true)
                            target3 = ny_gusuan_chosen(player, selected, 3)
                            if target3 and (not target3:isKongcheng()) then
                                local get = room:getNCards(5, false, false)
                                room:returnToEndDrawPile(get)
                                local hand = sgs.IntList()
                                for _,card in sgs.qlist(target3:getHandcards()) do
                                    hand:append(card:getId())
                                end
                                room:moveCardsToEndOfDrawpile(target3, hand, self:objectName())
                                if target3:isAlive() then
                                    local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                                    dummy:addSubcards(get)
                                    room:obtainCard(target3, dummy, false)
                                end
                            end
                        end
                    end

                    room:setPlayerFlag(player, "-ny_10th_gusuan")
                    local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
                    room:setPlayerMark(player, "&ny_10th_geyuan_last", #circle)
                    player:setTag("ny_10th_geyuan_circle", sgs.QVariant(table.concat(circle, "+")))
                end
            end
        end]]
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
		and target:hasSkill(self:objectName())
    end,
}

ny_10th_jieshu = sgs.CreateTriggerSkill{
    name = "ny_10th_jieshu",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_Discard then return false end
			local mt = {}
			for _,m in sgs.list(player:getMarkNames()) do
				if m:contains("+#ny_10th_geyuan") and player:getMark(m)>0 then
					m = string.gsub(m,"+#ny_10th_geyuan","")
					m = string.gsub(m,"&","")
					mt = m:split("+")
				end
			end
			if #mt<13 and player:getHandcardNum()>player:getMaxCards() then
				room:sendCompulsoryTriggerLog(player, self)
			end
			for _,h in sgs.qlist(player:getHandcards()) do
                if h:getNumber()>0 and not table.contains(mt, h:getNumberString()) then
                    room:ignoreCards(player, h)
                end
            end
			--[[local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
            if (not circle) or (#circle <= 0) then return false end
            local circlenum = {}
            for _,num in ipairs(circle) do
                table.insert(circlenum, tonumber(num))
            end
            for _,card in sgs.qlist(player:getHandcards()) do
                if (not table.contains(circlenum, card:getNumber())) then
                    room:ignoreCards(player, card)
                end
            end]]
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
			if card:getTypeId()>0 and card:getNumber()>0 then
				local mt = {}
				for _,m in sgs.list(player:getMarkNames()) do
					if m:contains("+#ny_10th_geyuan") and player:getMark(m)>0 then
						m = string.gsub(m,"+#ny_10th_geyuan","")
						m = string.gsub(m,"&","")
						mt = m:split("+")
					end
				end
				if card:getNumberString()==mt[1] or card:getNumberString()==mt[#mt] then
                    room:sendCompulsoryTriggerLog(player, self)
                    player:drawCards(1, self:objectName())
				end
			end
            --[[if (not card) or (card:isKindOf("SkillCard")) then return false end
            if card:getNumber() <= 0 then return false end
            local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
            if (not circle) or (#circle <= 0) then return false end
            if player:getMark("&ny_10th_geyuan_last") == #circle then
                if  table.contains(circle, tostring(card:getNumber())) then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    player:drawCards(1, self:objectName())
                end
            else
                if card:getNumber() == player:getMark("&ny_10th_geyuan_head")
                or card:getNumber() == player:getMark("&ny_10th_geyuan_tail") then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    player:drawCards(1, self:objectName())
                end
            end]]
            end
    end,
}

ny_10th_gusuan = sgs.CreateTriggerSkill{
    name = "ny_10th_gusuan",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data)
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        local room = player:getRoom()
        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:getMark("ny_10th_gusuan")<1 and p:isAlive() then
				local circle = p:getTag("geyuan_circle"):toString():split("+")
				if #circle == 10 or p:canWake(self:objectName()) then
					room:sendCompulsoryTriggerLog(p, self)
					room:doSuperLightbox(p,self:objectName())
					room:setPlayerMark(p,self:objectName(),1)
					room:changeMaxHpForAwakenSkill(p,-1,self:objectName())
					room:changeTranslation(p,"ny_10th_geyuan",1)
				end
			end
			--[[local circle = player:getTag("ny_10th_geyuan_circle"):toString():split("+")
            if  p:getMark("ny_10th_gusuan") == 0 and p:isAlive()
            and (p:canWake(self:objectName()) or #circle == 3) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "ny_10th_gusuan", 1)
                room:loseMaxHp(p, 1)
            end]]
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_10th_liuhui:addSkill(ny_10th_geyuan)
ny_10th_liuhui:addSkill(ny_10th_jieshu)
ny_10th_liuhui:addSkill(ny_10th_gusuan)

ny_10th_sufei = sgs.General(extension, "ny_10th_sufei", "wu", 4, true, false, false)

ny_tenth_shujian = sgs.CreateViewAsSkill
{
    name = "ny_tenth_shujian",
    response_pattern = "@@ny_tenth_shujian",
    n = 999,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_tenth_shujian") then return false end
        return #selected < 1
    end,
    view_as = function(self,cards)
        if (not sgs.Self:hasFlag("ny_tenth_shujian")) then
            if #cards > 0 then
                local card = ny_tenth_shujianCard:clone()
                card:addSubcard(cards[1])
                return card
            end
            return nil
        else
            local card = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("_ny_tenth_shujian")
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return (player:usedTimes("#ny_tenth_shujian") < 3) and player:getMark("ny_tenth_shujian_failed-PlayClear") == 0
    end,
}

ny_tenth_shujianCard = sgs.CreateSkillCard
{
    name = "ny_tenth_shujian",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        local n = 3 - effect.from:getMark("ny_tenth_shujian-PlayClear")
        room:addPlayerMark(effect.from, "ny_tenth_shujian-PlayClear", 1)
        local choices = {}
        table.insert(choices, string.format("draw=%d=%d", n, n - 1))
        table.insert(choices, string.format("dis=%d", n))
        local choice = ""
        local data = sgs.QVariant()
        data:setValue(effect.from)
        if effect.to:isAlive() then choice = room:askForChoice(effect.to, self:objectName(), table.concat(choices, "+"), data) end
        if effect.from:isAlive() and string.find(choice, "draw") then
            effect.from:drawCards(n, self:objectName())
            room:askForDiscard(effect.from, self:objectName(), n-1, n-1, false, true)
        end
        if effect.to:isAlive() and string.find(choice, "dis") then
            room:addPlayerMark(effect.from, "ny_tenth_shujian_failed-PlayClear", 1)
            room:setPlayerFlag(effect.to, "ny_tenth_shujian")
            for i = 1, n, 1 do
                local prompt = string.format("@ny_tenth_shujian:%s::%s:", i, n)
                if not room:askForUseCard(effect.to, "@@ny_tenth_shujian", prompt) then break end
                if effect.to:isDead() then break end
            end
        end
    end

}

ny_10th_sufei:addSkill(ny_tenth_shujian)

ny_10th_wuban = sgs.General(extension, "ny_10th_wuban", "shu", 4, true, false, false)

ny_10th_youzhan = sgs.CreateTriggerSkill{
    name = "ny_10th_youzhan",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if player:getPhase() == sgs.Player_NotActive then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() ~= player:objectName() then else return false end
            if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then else return false end
            local target = room:findPlayerByObjectName(move.from:objectName())
            if (not target) or target:isDead() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(target, "&ny_10th_youzhan-Clear", 1)
            room:addPlayerMark(target, "ny_10th_youzhan_damageup-Clear", 1)
            local cards = player:drawCardsList(1, self:objectName())
            for _,id in sgs.qlist(cards) do
                local card = sgs.Sanguosha:getCard(id)
                room:setCardFlag(card, "ny_10th_youzhan")
                room:setCardTip(id, "ny_10th_youzhan")
            end
            room:ignoreCards(player, cards)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                for _,card in sgs.qlist(player:getHandcards()) do
                    local id = card:getId()
                    room:setCardFlag(card, "-ny_10th_youzhan")
                    room:setCardTip(id, "-ny_10th_youzhan")
                end
            end
            if player:getPhase() == sgs.Player_Finish then
                local send = true
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark("&ny_10th_youzhan-Clear") > 0 and p:getMark("ny_10th_youzhan_damaged-Clear") == 0 then
                        if send then 
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                            send = false
                        end
                        local n = math.min(p:getMark("&ny_10th_youzhan-Clear"), 3)
                        p:drawCards(n, self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_youzhan_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_youzhan_buff",
    events = {sgs.Damaged,sgs.DamageInflicted},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            room:addPlayerMark(player, "ny_10th_youzhan_damaged-Clear", 1)
        end
        if event == sgs.DamageInflicted then
            if player:getMark("ny_10th_youzhan_damageup-Clear") == 0 then return false end
            local n = player:getMark("ny_10th_youzhan_damageup-Clear")
            room:setPlayerMark(player, "ny_10th_youzhan_damageup-Clear", 0)
            local damage = data:toDamage()

            local log = sgs.LogMessage()
            log.type = "$ny_10th_youzhan_damage"
            log.from = player
            log.arg = "ny_10th_youzhan"
            log.arg2 = damage.damage
            log.arg3 = damage.damage + n
            room:sendLog(log)
            room:broadcastSkillInvoke("ny_10th_youzhan")

            damage.damage = damage.damage + n
            data:setValue(damage)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_wuban:addSkill(ny_10th_youzhan)
ny_10th_wuban:addSkill(ny_10th_youzhan_buff)
extension:insertRelatedSkills("ny_10th_youzhan", "#ny_10th_youzhan_buff")

ny_10th_guannin = sgs.General(extension, "ny_10th_guannin", "shu", 3, true, false, false)

ny_tenth_xiuwen = sgs.CreateTriggerSkill{
    name = "ny_tenth_xiuwen",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
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
        local mark = string.format("ny_tenth_xiuwen_%s", card:objectName())
        if player:getMark(mark) == 0 then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, mark, 1)
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_longsongVS = sgs.CreateViewAsSkill{
    name = "ny_tenth_longsong",
    response_pattern = "@@ny_tenth_longsong",
    n = 99,
    view_filter = function(self, selected, to_select)
        return to_select:isRed() and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_tenth_longsongCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_longsongCard = sgs.CreateSkillCard
{
    name = "ny_tenth_longsong",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.to:obtainCard(self, false)
        local skills = effect.to:getVisibleSkillList()
        local skillnames = {}
        for _,s in sgs.qlist(skills) do
            local skillname = s:objectName()
            if (not s:isAttachedLordSkill()) and (not effect.from:hasSkill(skillname)) then
                local translation = sgs.Sanguosha:translate(":"..skillname)
                if string.find(translation,"出牌阶段") then
                    table.insert(skillnames,skillname)
                    room:acquireSkill(effect.from, skillname)
                end
            end
        end
        if #skillnames > 0 then
            effect.from:setTag("ny_tenth_longsong_skills", sgs.QVariant(table.concat(skillnames,"+")))
        end
    end
}

ny_tenth_longsong = sgs.CreateTriggerSkill{
    name = "ny_tenth_longsong",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.InvokeSkill,sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_longsongVS,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            room:askForUseCard(player, "@@ny_tenth_longsong", "@ny_tenth_longsong")
        end
        if event == sgs.InvokeSkill then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local skillname = data:toString()
            local skills = player:getTag("ny_tenth_longsong_skills"):toString():split("+")
            if (not skills) or (#skills <= 0) then return false end
            for _,skill in ipairs(skills) do
                if string.find(skillname, skill) and player:hasSkill(skill) then
                    local log = sgs.LogMessage()
                    log.type = "#InvokeSkill"
                    log.from = player
                    log.arg = skillname
                    room:sendLog(log)

                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:detachSkillFromPlayer(player, skill)
                    table.removeOne(skills, skill)
                    break
                end
            end
            if #skills <= 0 then player:removeTag("ny_tenth_longsong_skills")
            else player:setTag("ny_tenth_longsong_skills", sgs.QVariant(table.concat(skills,"+"))) end
        end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local skills = player:getTag("ny_tenth_longsong_skills"):toString():split("+")
            if (not skills) or (#skills <= 0) then return false end
            local send = true
            for _,skill in ipairs(skills) do
                if player:hasSkill(skill) then
                    if send then
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        send = false
                    end
                    room:detachSkillFromPlayer(player, skill)
                end
            end
            player:removeTag("ny_tenth_longsong_skills")
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local card 
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card)  then return false end
            local skillname = card:getSkillName()
            local skills = player:getTag("ny_tenth_longsong_skills"):toString():split("+")
            if (not skills) or (#skills <= 0) then return false end
            for _,skill in ipairs(skills) do
                if string.find(skillname, skill) and player:hasSkill(skill) then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:detachSkillFromPlayer(player, skill)
                    table.removeOne(skills, skill)
                    break
                end
            end
            if #skills <= 0 then player:removeTag("ny_tenth_longsong_skills")
            else player:setTag("ny_tenth_longsong_skills", sgs.QVariant(table.concat(skills,"+"))) end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_guannin:addSkill(ny_tenth_xiuwen)
ny_10th_guannin:addSkill(ny_tenth_longsong)
ny_10th_guannin:addSkill(ny_tenth_longsongVS)

ny_10th_sunhuan = sgs.General(extension, "ny_10th_sunhuan", "wu", 4, true, false, false)

ny_tenth_nijiVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_niji",
    response_pattern = "@@ny_tenth_niji",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and to_select:isAvailable(sgs.Self)
        and to_select:hasTip("ny_tenth_niji")
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

ny_tenth_niji = sgs.CreateTriggerSkill{
    name = "ny_tenth_niji",
    events = {sgs.TargetConfirmed,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_nijiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard"))
            and use.to:contains(player) and player:hasSkill(self) then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    room:broadcastSkillInvoke(self:objectName())
                    local cards = player:drawCardsList(1,self:objectName())
                    for _,id in sgs.qlist(cards) do
                        if player:handCards():contains(id) then
							room:setCardTip(id, "ny_tenth_niji-Clear")
                    end
                end
            end
        end
		elseif player:getPhase()==sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				for _,h in sgs.qlist(p:getHandcards()) do
					if h:hasTip("ny_tenth_niji") then
						room:askForUseCard(p, "@@ny_tenth_niji", "@ny_tenth_niji")
            break
        end
    end
				local dc = sgs.Sanguosha:cloneCard("slash")
				for _,h in sgs.qlist(p:getHandcards()) do
					if h:hasTip("ny_tenth_niji") then
						if p:canDiscard(p,h:getId()) then
							dc:addSubcard(h)
            end
        end
    end
				dc:deleteLater()
				room:throwCard(dc,self:objectName(),p)
end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_10th_sunhuan:addSkill(ny_tenth_niji)
ny_10th_sunhuan:addSkill(ny_tenth_nijiVS)

ny_10th_jiachong = sgs.General(extension, "ny_10th_jiachong", "wei", 3, true, false, false)

ny_10th_beini = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_beini",
    view_as = function(self)
        return ny_10th_beiniCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_beini"))
    end
}

ny_10th_beiniCard = sgs.CreateSkillCard
{
    name = "ny_10th_beini",
    filter = function(self, targets, to_select)
        return #targets < 2
    end,
    feasible = function(self, targets, player)
        return #targets == 2
    end,
    about_to_use = function(self,room,use)
        local source = use.from
        local tos = {}
        table.insert(tos, use.to:at(0):objectName())
        table.insert(tos, use.to:at(1):objectName())
        source:setTag("ny_10th_beini", sgs.QVariant(table.concat(tos, "+")))
        self:cardOnUse(room,use)
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:getHandcardNum() > source:getMaxHp() then
            local n = source:getHandcardNum() - source:getMaxHp()
            room:askForDiscard(source, self:objectName(), n, n, false, false)
        elseif source:getMaxHp() > source:getHandcardNum() then
            local n = source:getMaxHp() - source:getHandcardNum()
            source:drawCards(n, self:objectName())
        end
        
        for _,target in ipairs(targets) do
            if target and target:isAlive() then
                room:addPlayerMark(target, "@skill_invalidity")
                room:addPlayerMark(target, "&ny_10th_beini")
            end
        end

        local tos = source:getTag("ny_10th_beini"):toString():split("+")
        local from = room:findPlayerByObjectName(tos[1])
        local to = room:findPlayerByObjectName(tos[2])

        if from and from:isAlive() and to and to:isAlive() 
        and from:canSlash(to, false) then
            local patterns = {"slash", "fire_slash", "thunder_slash"}
            local pattern = room:askForChoice(source, self:objectName(), table.concat(patterns, "+"))
            local slash = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("_ny_10th_beini_slash")
            room:useCard(sgs.CardUseStruct(slash, from, to, false))
			slash:deleteLater()
        end
    end
}

ny_10th_beini_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_beini_clear",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_NotActive then
            for _,pl in sgs.qlist(room:getAlivePlayers()) do
                if pl:getMark("&ny_10th_beini") > 0 then
                    room:removePlayerMark(pl, "@skill_invalidity", pl:getMark("&ny_10th_beini"))
                    room:setPlayerMark(pl, "&ny_10th_beini", 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

--[[ny_10th_beini_invalid = sgs.CreateInvaliditySkill
{
    name = "#ny_10th_beini_invalid",
    skill_valid = function(self, player, skill)
        --return true
        return (player and player:getMark("&ny_10th_beini") == 0)
        or skill:getFrequency() == sgs.Skill_Compulsory
        or (not skill:isVisible())
        or skill:isAttachedLordSkill()
    end,
}]]

--[[local ny_10th_beini_invalid = sgs.LuaInvaliditySkill("#ny_10th_beini_invalid",sgs.Skill_Compulsory)
ny_10th_beini_invalid.skill_valid = function(self, player, skill)
    --return true
    return (player and player:getMark("&ny_10th_beini") == 0)
    or skill:getFrequency() == sgs.Skill_Compulsory
    or (not skill:isVisible())
    or skill:isAttachedLordSkill()
end]]


ny_tenth_shizong = sgs.CreateViewAsSkill{
    name = "ny_tenth_shizong",
    n = 999,
    response_pattern = "@@ny_tenth_shizong!",
    view_filter = function(self, selected, to_select)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern == "@@ny_tenth_shizong!" then
            return #selected < (sgs.Self:getMark("&ny_tenth_shizong-Clear") + 1)
        end
        return false
    end,
    view_as = function(self, cards)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern == "@@ny_tenth_shizong!" then
            if #cards == (sgs.Self:getMark("&ny_tenth_shizong-Clear") + 1) then
                local card = ny_tenth_shizong_giveCard:clone()
                for _,cc in ipairs(cards) do
                    card:addSubcard(cc)
                end
                return card
            end
        else
            if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			    local card = sgs.Self:getTag("ny_tenth_shizong"):toCard()
				if card==nil then return end
			    pattern = card:objectName()
		    end
            local card = ny_tenth_shizongCard:clone()
            local names = pattern:split("+")
            if #names ~= 1 then pattern = names[1] end
            if pattern == "Slash" then pattern = "slash" end
            if pattern == "Jink" then pattern = "jink" end
            card:setUserString(pattern)
            return card
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark("ny_tenth_shizong_disable-Clear") > 0 then return false end
        local num = player:getHandcardNum() + player:getEquips():length()
        return num >= (player:getMark("&ny_tenth_shizong-Clear") + 1)
    end,
    enabled_at_response = function(self,player,pattern)
        if player:getMark("ny_tenth_shizong_disable-Clear") > 0 then return false end
        if pattern == "@@ny_tenth_shizong!" then return true end
        if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        local basics = {"slash", "jink", "peach", "analeptic", "Jink", "Slash"}
        for _,basic in ipairs(basics) do
            if string.find(pattern, basic) then
                local num = player:getHandcardNum() + player:getEquips():length()
                return num >= (player:getMark("&ny_tenth_shizong-Clear") + 1)
            end
        end
        return false
    end
}
ny_tenth_shizong:setGuhuoDialog("l")

ny_tenth_shizongCard = sgs.CreateSkillCard
{
    name = "ny_tenth_shizong",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_shizong")
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets, player)
		local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_shizong")
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

        room:broadcastSkillInvoke(self:objectName())
        local log = sgs.LogMessage()
        log.type = "$ny_tenth_shizong_log"
        log.from = card_use.from
        log.arg = self:objectName()
        log.arg2 = pattern
        room:sendLog(log)

        player:setTag("ny_tenth_shizong_used", sgs.QVariant(pattern))

        local prompt = string.format("ny_tenth_shizong_give:%s:", player:getMark("&ny_tenth_shizong-Clear")+1)
        room:askForUseCard(player, "@@ny_tenth_shizong!", prompt)

        local viewers = sgs.SPlayerList()
        viewers:append(player)
        room:addPlayerMark(player, "&ny_tenth_shizong-Clear", 1, viewers)

        if player:hasFlag("ny_tenth_shizong_success") then
            room:setPlayerFlag(player, "-ny_tenth_shizong_success")
		    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		    card:setSkillName("_ny_tenth_shizong")
			card:deleteLater()
		    return card
        end
        return nil
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end

        room:broadcastSkillInvoke(self:objectName())
        local log = sgs.LogMessage()
        log.type = "$ny_tenth_shizong_log"
        log.from = player
        log.arg = self:objectName()
        log.arg2 = pattern
        room:sendLog(log)

        player:setTag("ny_tenth_shizong_used", sgs.QVariant(pattern))

        local prompt = string.format("ny_tenth_shizong_give:%s:", player:getMark("&ny_tenth_shizong-Clear")+1)
        room:askForUseCard(player, "@@ny_tenth_shizong!", prompt)

        local viewers = sgs.SPlayerList()
        viewers:append(player)
        room:addPlayerMark(player, "&ny_tenth_shizong-Clear", 1, viewers)

        if player:hasFlag("ny_tenth_shizong_success") then
            room:setPlayerFlag(player, "-ny_tenth_shizong_success")
		    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		    card:setSkillName("_ny_tenth_shizong")
			card:deleteLater()
		    return card
        end
        return nil
    end
}

ny_tenth_shizong_giveCard = sgs.CreateSkillCard
{
    name = "ny_tenth_shizong_give",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    about_to_use = function(self,room,use)
        room:obtainCard(use.to:at(0), self, false)

        local data = sgs.QVariant()
        data:setValue(use.from)
        use.to:at(0):setTag("ny_tenth_shizong_from", data)

        if use.to:at(0):getPhase() == sgs.Player_NotActive then
            room:addPlayerMark(use.from, "ny_tenth_shizong_disable-Clear", 1)
        end

        local prompt = string.format("@ny_tenth_shizong:%s::%s:", use.from:getGeneralName(),use.from:getTag("ny_tenth_shizong_used"):toString())
        local down = room:askForExchange(use.to:at(0), "ny_tenth_shizong", 1, 1, true, prompt, true)
        if down then
            room:setPlayerFlag(use.from, "ny_tenth_shizong_success")
            room:moveCardsToEndOfDrawpile(use.to:at(0), down:getSubcards(), "ny_tenth_shizong")
        end
    end,
}

ny_10th_jiachong:addSkill(ny_10th_beini)
ny_10th_jiachong:addSkill(ny_10th_beini_clear)
--ny_10th_jiachong:addSkill(ny_10th_beini_invalid)
ny_10th_jiachong:addSkill(ny_tenth_shizong)
extension:insertRelatedSkills("ny_10th_beini", "#ny_10th_beini_clear")
--extension:insertRelatedSkills("ny_10th_beini", "#ny_10th_beini_invalid")

ny_10th_dongzhao = sgs.General(extension, "ny_10th_dongzhao", "wei", 3, true, false, false)

ny_10th_yijia = sgs.CreateTriggerSkill{
    name = "ny_10th_yijia",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        for _,skiller in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if player:isDead() then return false end
            if skiller:isAlive() and skiller:distanceTo(player) <= 1 then
                local inrange = 0

                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    for _,card in sgs.qlist(p:getEquips()) do
                        local equip_index = card:getRealCard():toEquipCard():location()
                        if player:hasEquipArea(equip_index) then
                            targets:append(p)
                            break
                        end
                    end
                    if p:inMyAttackRange(player) then inrange = inrange + 1 end
                end
                if targets:isEmpty() then return false end

                skiller:removeTag("ny_10th_yijia")
                skiller:setTag("ny_10th_yijia", sgs.QVariant(player:objectName()))
                local target = room:askForPlayerChosen(skiller, targets, self:objectName(), "@ny_10th_yijia:"..player:getGeneralName(), true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    local disable_ids = sgs.IntList()
                    for _,card in sgs.qlist(target:getEquips()) do
                        local equip_index = card:getRealCard():toEquipCard():location()
                        if not player:hasEquipArea(equip_index) then
                            disable_ids:append(card:getId())
                        end
                    end
                    local id = room:askForCardChosen(skiller, target, "e", self:objectName(), false, sgs.Card_MethodNone, disable_ids)

                    local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()

                    local moves = sgs.CardsMoveList()

                    if player:getEquip(equip_index) then
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, skiller:objectName(), self:objectName(), "")
                        local move = sgs.CardsMoveStruct(player:getEquip(equip_index):getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                        moves:append(move)
                    end

                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, skiller:objectName(), self:objectName(), "")
                    local move = sgs.CardsMoveStruct(id, player, sgs.Player_PlaceEquip, reason)
                    moves:append(move)

                    if (not moves:isEmpty()) then
                        room:moveCardsAtomic(moves, true)
                    end

                    if skiller:isAlive() then
                        local inrange2 = 0
                        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                            if p:inMyAttackRange(player) then inrange2 = inrange2 + 1 end
                        end
                        if inrange2 < inrange then skiller:drawCards(1, self:objectName()) end
                    end
                end
            end
        end                      
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_tenth_dingjiVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_dingji",
    n = 99,
    response_pattern = "@@ny_tenth_dingji",
    view_filter = function(self, selected, to_select)
        return (to_select:isKindOf("BasicCard") or to_select:isNDTrick())
        and to_select:isAvailable(sgs.Self) and sgs.Self:getHandcards():contains(to_select)
        and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = sgs.Sanguosha:cloneCard(cards[1]:objectName(), sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("_ny_tenth_dingji")
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_dingji = sgs.CreateTriggerSkill{
    name = "ny_tenth_dingji",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_dingjiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "ny_tenth_dingji_change", true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            if target:getHandcardNum() > 5 then
                local n = target:getHandcardNum() - 5
                room:askForDiscard(target, self:objectName(), n, n, false, false)
            elseif 5 > target:getHandcardNum() then
                local n = 5 - target:getHandcardNum()
                target:drawCards(n, self:objectName())
            end
            if target:isDead() then return false end
            if target:isKongcheng() then return false end
            local show = sgs.IntList()
            local canuse = true
            local names = {}
            for _,card in sgs.qlist(target:getHandcards()) do
                show:append(card:getId())
                local name = card:objectName()
                if card:isKindOf("Slash") then name = "slash" end
                if not table.contains(names, name) then
                    table.insert(names, name)
                else
                    canuse = false
                end
            end
            room:showCard(target, show)
            if canuse then
                room:askForUseCard(target, "@@ny_tenth_dingji", "@ny_tenth_dingji")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_dongzhao:addSkill(ny_10th_yijia)
ny_10th_dongzhao:addSkill(ny_tenth_dingji)
ny_10th_dongzhao:addSkill(ny_tenth_dingjiVS)

ny_10th_malingli = sgs.General(extension, "ny_10th_malingli", "shu", 3, false, false, false)

ny_10th_lima = sgs.CreateDistanceSkill{
    name = "ny_10th_lima",
    correct_func = function(self, from, to)
        if from and from:hasSkill(self:objectName()) then
            local num = 0
            if from:getOffensiveHorse() then num = num - 1 end
            if from:getDefensiveHorse() then num = num - 1 end
            for _,other in sgs.qlist(from:getAliveSiblings()) do
                if other:getOffensiveHorse() then num = num - 1 end
                if other:getDefensiveHorse() then num = num - 1 end
            end
            if num == 0 then num = -1 end
            return num
        end
        return 0
    end,
}

ny_tenth_xiaoyinVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_xiaoyin",
    response_pattern = "@@ny_tenth_xiaoyin",
    expand_pile = "#ny_tenth_xiaoyin",
    n = 99,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_tenth_xiaoyin_add") then
            if #selected == 0 then return true end
            if #selected == 1 then
                local ctypes = {"BasicCard","TrickCard", "EquipCard"}
                for _,ctype in ipairs(ctypes) do
                    if selected[1]:isKindOf(ctype) and (not to_select:isKindOf(ctype)) then return false end
                end
                if sgs.Self:getPile("#ny_tenth_xiaoyin"):contains(selected[1]:getId()) then
                    return not sgs.Self:getPile("#ny_tenth_xiaoyin"):contains(to_select:getId())
                else
                    return sgs.Self:getPile("#ny_tenth_xiaoyin"):contains(to_select:getId())
                end
            end
            return false
        end

        if sgs.Self:hasFlag("ny_tenth_xiaoyin_change") then
            return sgs.Self:getPile("#ny_tenth_xiaoyin"):contains(to_select:getId()) and #selected < 1
        end

        if to_select:hasFlag("ny_tenth_xiaoyin") then return false end
        return to_select:isBlack() and sgs.Self:getPile("#ny_tenth_xiaoyin"):contains(to_select:getId())
        and #selected < 1
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("ny_tenth_xiaoyin_add") then
            if #cards == 2 then
                local card = ny_tenth_xiaoyin_buffCard:clone()
                card:addSubcard(cards[1])
                card:addSubcard(cards[2])
                return card
            end
            return nil
        end

        if sgs.Self:hasFlag("ny_tenth_xiaoyin_change") then
            if #cards == 1 then
                local card = ny_tenth_xiaoyin_buffCard:clone()
                card:addSubcard(cards[1])
                return card
            end
            return nil
        end


        if #cards == 1 then
            local card = ny_tenth_xiaoyinCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

ny_tenth_xiaoyinCard = sgs.CreateSkillCard
{
    name = "ny_tenth_xiaoyin",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        if #targets >= 1 then return false end
        if to_select:hasFlag("ny_tenth_xiaoyin") then return false end
        if to_select:objectName() == player:objectName() then return false end
        local inneed = true
        for _,other in sgs.qlist(to_select:getAliveSiblings()) do
            if other:hasFlag("ny_tenth_xiaoyin") then inneed = false end
        end
        if inneed then return true end
        for _,other in sgs.qlist(to_select:getAliveSiblings()) do
            if other:hasFlag("ny_tenth_xiaoyin") and to_select:isAdjacentTo(other) then return true end
        end
        return false
    end,
    about_to_use = function(self,room,use)
        local player = use.from
        local target = use.to:at(0)
        local _player = sgs.SPlayerList()
        _player:append(player)
        room:setPlayerMark(target, "&ny_tenth_xiaoyin", 1, _player)
        room:setPlayerFlag(target, "ny_tenth_xiaoyin")
        local id = self:getSubcards():at(0)
        local card = sgs.Sanguosha:getCard(id)

        local data_other = sgs.QVariant()
        data_other:setValue(card)
        target:setTag("ny_tenth_xiaoyin_put", data_other)
        room:setCardFlag(card, "ny_tenth_xiaoyin")
    end,
}

ny_tenth_xiaoyin_buffCard = sgs.CreateSkillCard
{
    name = "ny_tenth_xiaoyin_buff",
    target_fixed = true,
    will_throw = false,
    about_to_use = function(self,room,use)
        return false
    end
}

ny_tenth_xiaoyin = sgs.CreateTriggerSkill{
    name = "ny_tenth_xiaoyin",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_xiaoyinVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            if not player:hasSkill(self:objectName()) then return false end
            local n = 1
            for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                if player:distanceTo(other) <= 1 then
                    n = n + 1
                end
            end
            local prompt = string.format("show:%s:", n)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())

                local card_ids = room:getNCards(n)
                local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
                local move1 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_PlaceTable, reason1)
                room:moveCardsAtomic(move1, true)

                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    p:removeTag("ny_tenth_xiaoyin_put")
                end

                local _data = sgs.QVariant()
                _data:setValue(card_ids)
                player:setTag("ny_tenth_xiaoyin_tem", _data)

                room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", sgs.Player_PlaceTable, true)
                while(room:askForUseCard(player, "@@ny_tenth_xiaoyin", "@ny_tenth_xiaoyin")) do end
                room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", sgs.Player_PlaceTable, false)

                local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                local discard = sgs.IntList()

                for _,id in sgs.qlist(card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isRed() then get:addSubcard(card)
                    else discard:append(id) end
                end

                if get:subcardsLength() > 0 then room:obtainCard(player, get, true) end
                get:deleteLater()

                room:setPlayerFlag(player, "ny_tenth_xiaoyin_finish")
                local nextp = player:getNextAlive(1)
                while(not nextp:hasFlag("ny_tenth_xiaoyin_finish")) do
                    if nextp:hasFlag("ny_tenth_xiaoyin") then
                        local card = nextp:getTag("ny_tenth_xiaoyin_put"):toCard()
                        if card then
                            nextp:addToPile("ny_tenth_xiaoyin", card, true)
                            discard:removeOne(card:getId())
                            room:setCardFlag(card, "-ny_tenth_xiaoyin")
                        end
                    end
                    room:setPlayerFlag(nextp, "ny_tenth_xiaoyin_finish")
                    nextp = nextp:getNextAlive(1)
                end

                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerFlag(p, "-ny_tenth_xiaoyin_finish")
                    room:setPlayerFlag(p, "-ny_tenth_xiaoyin")
                    room:setPlayerMark(p, "&ny_tenth_xiaoyin", 0)
                end

                if not discard:isEmpty() then
                    local log = sgs.LogMessage()
                    log.type = "$MoveToDiscardPile"
                    log.from = player
                    log.card_str = table.concat(sgs.QList2Table(discard), "+")
                    room:sendLog(log)

                    local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                    local move2 = sgs.CardsMoveStruct(discard, nil, sgs.Player_DiscardPile, reason2)
                    room:moveCardsAtomic(move2, true)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

local function ny_tenth_xiaoyin_move(room, player, to, card_ids, inc)
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), "ny_tenth_xiaoyin", "")
    local move
    if (inc) then
        move = sgs.CardsMoveStruct(card_ids, to, player, sgs.Player_PlaceSpecial, sgs.Player_PlaceSpecial, reason)
        move.from_pile_name = "ny_tenth_xiaoyin"
        move.to_pile_name = "#ny_tenth_xiaoyin"
        local data = sgs.QVariant()
        data:setValue(card_ids)
        player:setTag("ny_tenth_xiaoyin_tem", data)
    else
        move = sgs.CardsMoveStruct(card_ids, player, to, sgs.Player_PlaceSpecial, sgs.Player_PlaceSpecial, reason)
        move.from_pile_name = "#ny_tenth_xiaoyin"
        move.to_pile_name = "ny_tenth_xiaoyin"
    end

    local moves = sgs.CardsMoveList()
    moves:append(move)
    local _player = sgs.SPlayerList()
    _player:append(player)
    room:notifyMoveCards(true, moves, true, _player)
    room:notifyMoveCards(false, moves, true, _player)
end

ny_tenth_xiaoyin_buff = sgs.CreateTriggerSkill{
    name = "#ny_tenth_xiaoyin_buff",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_xiaoyinVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:getPile("ny_tenth_xiaoyin"):isEmpty() then return false end
            player:setTag("ny_tenth_xiaoyin_buff", data)
            if damage.nature == sgs.DamageStruct_Fire then
                local card_ids = damage.to:getPile("ny_tenth_xiaoyin")
                local prompt = string.format("ny_tenth_xiaoyin_add:%s:", damage.to:getGeneralName())
                local place = room:getCardPlace(card_ids:at(0))

                room:setPlayerFlag(player, "ny_tenth_xiaoyin_add")
                --room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", place, true)
                ny_tenth_xiaoyin_move(room, player, damage.to, card_ids, true)
                local card = room:askForUseCard(player, "@@ny_tenth_xiaoyin", prompt)
                --room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", place, false)
                ny_tenth_xiaoyin_move(room, player, damage.to, card_ids, false)
                room:setPlayerFlag(player, "-ny_tenth_xiaoyin_add")

                if card then
                    room:sendCompulsoryTriggerLog(player, "ny_tenth_xiaoyin", true, true)
                    
                    for _,id in sgs.qlist(card:getSubcards()) do
                        if room:getCardPlace(id) == sgs.Player_PlaceHand
                        or room:getCardPlace(id) == sgs.Player_PlaceEquip then
                            local log = sgs.LogMessage()
                            log.type = "$DiscardCard"
                            log.from = player
                            log.card_str = sgs.Sanguosha:getCard(id):toString()
                            room:sendLog(log)

                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "ny_tenth_xiaoyin", "")
                            local move = sgs.CardsMoveStruct(id, nil, sgs.Player_DiscardPile, reason)
                            room:moveCardsAtomic(move, true)
                        else
                            local log = sgs.LogMessage()
                            log.type = "$MoveToDiscardPile"
                            log.from = player
                            log.card_str = sgs.Sanguosha:getCard(id):toString()
                            room:sendLog(log)
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "ny_tenth_xiaoyin", "")
                            local move = sgs.CardsMoveStruct(id, nil, sgs.Player_DiscardPile, reason)
                            room:moveCardsAtomic(move, true)
                        end
                    end

                    local log = sgs.LogMessage()
                    log.type = "$ny_tenth_xiaoyin_buff_add"
                    log.from = player
                    log.arg = damage.to:getGeneralName()
                    log.arg2 = "ny_tenth_xiaoyin"
                    log.arg3 = damage.damage
                    log.arg4 = damage.damage + 1
                    room:sendLog(log)

                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            else
                local card_ids = damage.to:getPile("ny_tenth_xiaoyin")
                local prompt = string.format("ny_tenth_xiaoyin_change:%s:", damage.to:getGeneralName())

                local place = room:getCardPlace(card_ids:at(0))

                room:setPlayerFlag(player, "ny_tenth_xiaoyin_change")
                --room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", place, true)
                ny_tenth_xiaoyin_move(room, player, damage.to, card_ids, true)
                local card = room:askForUseCard(player, "@@ny_tenth_xiaoyin", prompt)
                --room:notifyMoveToPile(player, card_ids, "ny_tenth_xiaoyin", place, false)
                ny_tenth_xiaoyin_move(room, player, damage.to, card_ids, false)
                room:setPlayerFlag(player, "-ny_tenth_xiaoyin_change")

                if card then
                    room:sendCompulsoryTriggerLog(player, "ny_tenth_xiaoyin", true, true)
                    
                    --room:obtainCard(player, card, true)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), "ny_tenth_xiaoyin", "")
                    local move = sgs.CardsMoveStruct(card:getSubcards(), player, sgs.Player_PlaceHand, reason)
                    room:moveCardsAtomic(move, true)

                    local log = sgs.LogMessage()
                    log.type = "$ny_tenth_xiaoyin_buff_change"
                    log.from = player
                    log.arg = damage.to:getGeneralName()
                    log.arg2 = "ny_tenth_xiaoyin"
                    log.arg3 = "fire_nature"
                    room:sendLog(log)

                    damage.nature = sgs.DamageStruct_Fire
                    data:setValue(damage)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_tenth_huahuo = sgs.CreateViewAsSkill{
    name = "ny_tenth_huahuo",
    n = 99,
    view_filter = function(self, selected, to_select)
        return to_select:isRed() and #selected < 1
        and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_tenth_huahuoCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_tenth_huahuo")
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getPhase() ~= sgs.Player_Play then return false end
        if player:hasUsed("#ny_tenth_huahuo") then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        return pattern == "slash" or pattern == "Slash"
    end,
}

ny_tenth_huahuoCard = sgs.CreateSkillCard
{
    name = "ny_tenth_huahuo",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())

        card:deleteLater()
        return card:targetFilter(qtargets, to_select, player)
    end,
    feasible = function(self, targets, player)
        local use_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        use_card:addSubcards(self:getSubcards())
        use_card:setSkillName(self:objectName())
        use_card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if use_card and use_card:canRecast() and #targets == 0 then
			return false
		end

        return use_card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local player = cardUse.from
        local room = source:getRoom()

        local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        card:deleteLater()

        local choices = "cancel"
        for _,to in sgs.qlist(cardUse.to) do
            if not to:getPile("ny_tenth_xiaoyin"):isEmpty() then 
                choices = "change+cancel" 
                break
            end
        end

        local choice = room:askForChoice(player, self:objectName(), choices)
        if choice == "change" then
            cardUse.to = sgs.SPlayerList()
            for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                if (not other:getPile("ny_tenth_xiaoyin"):isEmpty())
                and (not player:isProhibited(other, card)) then 
                    cardUse.to:append(other)
                end
            end
            room:sortByActionOrder(cardUse.to)
        end

        room:setCardFlag(card, "ny_tenth_huahuo")
        room:setCardFlag(card, "RemoveFromHistory")
        return card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

        local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        card:deleteLater()

        room:setCardFlag(card, "RemoveFromHistory")

        return card
    end,
}

ny_10th_malingli:addSkill(ny_10th_lima)
ny_10th_malingli:addSkill(ny_tenth_xiaoyin)
ny_10th_malingli:addSkill(ny_tenth_xiaoyinVS)
ny_10th_malingli:addSkill(ny_tenth_xiaoyin_buff)
ny_10th_malingli:addSkill(ny_tenth_huahuo)
extension:insertRelatedSkills("ny_tenth_xiaoyin", "#ny_tenth_xiaoyin_buff")

ny_10th_xielingyu = sgs.General(extension, "ny_10th_xielingyu", "wu", 3, false, false, false)

ny_10th_yuandi = sgs.CreateTriggerSkill{
    name = "ny_10th_yuandi",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if player:getMark("ny_10th_yuandi-PlayClear") > 0 then return false end
        room:addPlayerMark(player, "ny_10th_yuandi-PlayClear", 1)
        for _,to in sgs.qlist(use.to) do
            if to:objectName() ~= player:objectName() then return false end
        end

        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:isAlive() and p:objectName() ~= player:objectName() then
                local _data = sgs.QVariant()
                _data:setValue(player)
                if room:askForSkillInvoke(p, self:objectName(), _data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local choices = {"draw="..player:getGeneralName(), "discard="..player:getGeneralName()}
                    local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"), _data)
                    if string.find(choice, "draw") then
                        player:drawCards(1, self:objectName())
                        p:drawCards(1, self:objectName())
                    elseif string.find(choice, "discard") and (not player:isKongcheng()) then
                        local card = room:askForCardChosen(p, player, "h", self:objectName())
                        room:throwCard(card, player, p)
                    end
                end
            end
            if player:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target:getPhase() == sgs.Player_Play and target:isAlive()
    end,
}

ny_10th_xinyou = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_xinyou",
    view_as = function(self)
        return ny_10th_xinyouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_xinyou")
    end
}

ny_10th_xinyouCard = sgs.CreateSkillCard
{
    name = "ny_10th_xinyou",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:isWounded() then
            room:recover(source, sgs.RecoverStruct(self:objectName(), source, source:getLostHp()))
            room:addPlayerMark(source, "ny_10th_xinyou_recover-Clear", 1)
        end
        if source:getHandcardNum() < source:getMaxHp() then
            local n = source:getMaxHp()- source:getHandcardNum()
            source:drawCards(n, self:objectName())
            if n > 2 then
                room:addPlayerMark(source, "ny_10th_xinyou_draw-Clear", 1)
            end
        end
    end
}

ny_10th_xinyou_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_xinyou_buff",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Finish then return false end
        if player:getMark("ny_10th_xinyou_recover-Clear") == 0
        and player:getMark("ny_10th_xinyou_draw-Clear") == 0 then return false end
        room:sendCompulsoryTriggerLog(player, "ny_10th_xinyou", true, true)
        if player:getMark("ny_10th_xinyou_draw-Clear") > 0 then
            room:loseHp(player, 1, true, player, "ny_10th_xinyou")
        end
        if player:getMark("ny_10th_xinyou_recover-Clear") > 0 then
            room:askForDiscard(player, "ny_10th_xinyou", 1, 1, false, true)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_xielingyu:addSkill(ny_10th_yuandi)
ny_10th_xielingyu:addSkill(ny_10th_xinyou)
ny_10th_xielingyu:addSkill(ny_10th_xinyou_buff)
extension:insertRelatedSkills("ny_10th_xinyou","#ny_10th_xinyou_buff")

ny_10th_mouzhouyu = sgs.General(extension, "ny_10th_mouzhouyu", "wu", 4, true, false, false)

ny_10th_ronghuo = sgs.CreateTriggerSkill{
    name = "ny_10th_ronghuo",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and (damage.card:objectName() == "fire_slash" or damage.card:objectName() == "fire_attack")
            and (not damage.chain) then
                room:broadcastSkillInvoke(self:objectName())
                local kingdoms = {}
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if not table.contains(kingdoms, p:getKingdom()) then
                        table.insert(kingdoms, p:getKingdom())
                    end
                end
                local n = #kingdoms - 1 + damage.damage

                local log = sgs.LogMessage()
                log.type = "$ny_10th_ronghuo_damage"
                log.from = player
                --log.to = sgs.SPlayerList()
                log.to:append(damage.to)
                log.arg = self:objectName()
                log.arg2 = damage.damage
                log.arg3 = n
                room:sendLog(log)

                damage.damage = n
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_yingmou = sgs.CreateTriggerSkill{
    name = "ny_10th_yingmou",
    events = {sgs.CardFinished,sgs.GameStart},
    frequency = sgs.Skill_NotFrequent,
    change_skill = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
			if room:askForChoice(player,self:objectName(),"1_num+2_num")=="2_num" then
                room:setChangeSkillState(player, self:objectName(), 2)
			end
		end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from:objectName() ~= player:objectName() then return false end
            if not use.card or use.card:isKindOf("SkillCard") then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(use.to) do
                if (p:objectName() ~= player:objectName()) and p:isAlive() then targets:append(p) end
            end
            if targets:isEmpty() then return false end
            if player:getChangeSkillState(self:objectName()) <= 1 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "ny_10th_yingmou_first", true, true)
                if not target then return false end
                room:broadcastSkillInvoke(self:objectName())
                room:setChangeSkillState(player, self:objectName(), 2)
                room:addPlayerMark(player, "ny_10th_yingmou-Clear", 1)

                if target:getHandcardNum() > player:getHandcardNum() then
                    local n = target:getHandcardNum() - player:getHandcardNum()
                    if n > 5 then n = 5 end
                    player:drawCards(n, self:objectName())
                end
                local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
                fire_attack:setSkillName("_"..self:objectName())
                if player:isAlive() and target:isAlive() and player:canUse(fire_attack, target) then
                    room:useCard(sgs.CardUseStruct(fire_attack, player, target, true))
                end
				fire_attack:deleteLater()
            elseif player:getChangeSkillState(self:objectName()) == 2 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "ny_10th_yingmou_second_first", true, true)
                if not target then return false end
                room:broadcastSkillInvoke(self:objectName())
                room:setChangeSkillState(player, self:objectName(), 1)
                room:addPlayerMark(player, "ny_10th_yingmou-Clear", 1)

                room:setPlayerFlag(player, "ny_10th_yingmou_second_second")
                local max = 0
                local tas = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHandcardNum() > max then max = p:getHandcardNum() end
                end
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHandcardNum() == max then tas:append(p) end
                end
                local from = room:askForPlayerChosen(player, tas, self:objectName(), "ny_10th_yingmou_second_second", false, true)
                room:setPlayerFlag(player, "-ny_10th_yingmou_second_second")

                local discard = true
                room:setPlayerFlag(from, "ny_10th_yingmou")
                for _,card in sgs.qlist(from:getHandcards()) do
                    if from:isDead() then break end
                    if target:isDead() then break end
                    if card:isDamageCard() and from:canUse(card, target) then
                        room:useCard(sgs.CardUseStruct(card, from, target, true))
                        discard = false
                    end
                end
                room:setPlayerFlag(from, "-ny_10th_yingmou")

                if discard and player:isAlive() and from:isAlive() and from:getHandcardNum() > player:getHandcardNum() then
                    local dis = from:getHandcardNum() - player:getHandcardNum()
                    room:askForDiscard(from, self:objectName(), dis, dis, false, false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive() and target:getMark("ny_10th_yingmou-Clear") == 0
    end,
}

ny_10th_yingmou_buff = sgs.CreateTargetModSkill{
    name = "#ny_10th_yingmou_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:hasFlag("ny_10th_yingmou") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasFlag("ny_10th_yingmou") then return 1000 end
        return 0
    end,
}

ny_10th_mouzhouyu:addSkill(ny_10th_ronghuo)
ny_10th_mouzhouyu:addSkill(ny_10th_yingmou)
ny_10th_mouzhouyu:addSkill(ny_10th_yingmou_buff)
extension:insertRelatedSkills("ny_10th_yingmou", "#ny_10th_yingmou_buff")

ny_10th_sunchen = sgs.General(extension, "ny_10th_sunchen", "wu", 4, true, false, false)

ny_10th_zuowei = sgs.CreateTriggerSkill{
    name = "ny_10th_zuowei",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
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
        local n = math.max(player:getEquips():length(), 1)
        if player:getHandcardNum() > n then
            local prompt = string.format("noresponse:%s:",card:objectName())
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                local log = sgs.LogMessage()
                log.type = "$ny_10th_zuowei_noresponse"
                log.from = player
                log.arg = self:objectName()
                log.card_str = card:toString()
                room:sendLog(log)

                if event == sgs.CardUsed then
                    local use = data:toCardUse()
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        elseif player:getHandcardNum() == n then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ny_10th_zuowei", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
            end
        elseif player:getHandcardNum() < n then
            if player:getMark("ny_10th_zuowei-Clear") > 0 then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, "ny_10th_zuowei-Clear", 1)
                player:drawCards(2,self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getPhase() ~= sgs.Player_NotActive
    end,
}

ny_10th_zigu = sgs.CreateViewAsSkill
{
    name = "ny_10th_zigu",
    n = 99,
    view_filter = function(self, selected, to_select)
        return #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_10th_ziguCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_zigu")
    end
}

ny_10th_ziguCard = sgs.CreateSkillCard
{
    name = "ny_10th_zigu",
    handling_method = sgs.Card_MethodDiscard,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        if source:isDead() then return false end
        local tos = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if (not p:getEquips():isEmpty()) then
                tos:append(p)
            end
        end
        if tos:isEmpty() then 
            source:drawCards(1, self:objectName()) 
            return false
        end
        local to = room:askForPlayerChosen(source, tos, "ny_10th_zigu", "@ny_10th_zigu", false, true)
        local card = room:askForCardChosen(source, to, "e", self:objectName())
        room:obtainCard(source, card, true)
        if to:objectName() == source:objectName() and source:isAlive() then source:drawCards(1, self:objectName()) end
    end,
    --[[on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local player = effect.from
        local to = effect.to
        if (not to:getEquips():isEmpty()) then
            local card = room:askForCardChosen(player, to, "e", self:objectName())
            room:obtainCard(player, card, true)
        else
            player:drawCards(1, self:objectName())
        end
        if player:isAlive() and player:objectName() == to:objectName() then
            player:drawCards(1, self:objectName())
        end
    end]]
}

ny_10th_sunchen:addSkill(ny_10th_zigu)
ny_10th_sunchen:addSkill(ny_10th_zuowei)

ny_10th_sunce_shuangbi = sgs.General(extension, "ny_10th_sunce_shuangbi", "wu", 4, true, false, false)

ny_tenth_shuangbi = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_shuangbi",
    response_pattern = "@@ny_tenth_shuangbi",
    view_as = function(self)
        if sgs.Self:hasFlag("ny_tenth_shuangbi") then
            return ny_tenth_shuangbiSlash:clone()
        else
            return ny_tenth_shuangbiCard:clone()
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_tenth_shuangbi")
    end
}

ny_tenth_shuangbiCard = sgs.CreateSkillCard
{
    name = "ny_tenth_shuangbi",
    target_fixed = true,
    mute = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
        local n = room:getAlivePlayers():length()
        local choices = string.format("draw=%s+damage=%s+slash=%s",n,n,n)
        local choice = room:askForChoice(source, self:objectName(), choices, sgs.QVariant(1))
        if string.find(choice, "draw") then
            room:broadcastSkillInvoke(self:objectName(), math.random(1,2)+2)
            source:drawCards(n, self:objectName())
            room:addPlayerMark(source, "&ny_tenth_shuangbi-Clear", n)
        elseif string.find(choice, "damage") then
            room:broadcastSkillInvoke(self:objectName(), math.random(1,2)+4)
            local prompt = string.format("ny_tenth_shuangbi_discard:%s:",n)
            local card = room:askForDiscard(source, self:objectName(), n, 1, true, true, prompt)
            if card then
                for i = 1,card:subcardsLength(),1 do
                    local all = sgs.QList2Table(room:getOtherPlayers(source))
                    local target = all[math.random(1,#all)]
                    room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, sgs.DamageStruct_Fire))
                end
            end
        elseif string.find(choice, "slash") then
            room:broadcastSkillInvoke(self:objectName(), math.random(1,2)+6)
            for i = 1,n,1 do
                local pattern = room:askForChoice(source, self:objectName(), "fire_slash+fire_attack+cancel", sgs.QVariant(2))
                if pattern == "cancel" then break end
                room:setPlayerProperty(source, "ny_tenth_shuangbi_card", sgs.QVariant(pattern))
                room:setPlayerFlag(source, "ny_tenth_shuangbi")
                local use = room:askForUseCard(source, "@@ny_tenth_shuangbi", "@ny_tenth_shuangbi:"..pattern)
                room:setPlayerFlag(source, "-ny_tenth_shuangbi")
                if not use then break end
            end
        end
    end
}

ny_tenth_shuangbiSlash = sgs.CreateSkillCard
{
    handling_method = sgs.Card_MethodUse,
    mute = true,
    name = "ny_tenth_shuangbi_card",
    filter = function(self, targets, to_select, player) 
		local pattern = player:property("ny_tenth_shuangbi_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_shuangbi_mouzhouyu")
		card:deleteLater()
		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local pattern = sgs.Self:property("ny_tenth_shuangbi_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_shuangbi_mouzhouyu")
		card:deleteLater()
		return card:targetFixed()
	end,
	feasible = function(self, targets, player)	
		local pattern = player:property("ny_tenth_shuangbi_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_shuangbi_mouzhouyu")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		card:deleteLater()
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local pattern = player:property("ny_tenth_shuangbi_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("_ny_tenth_shuangbi_mouzhouyu")
        room:setCardFlag(card, "RemoveFromHistory")
		card:deleteLater()
		return card	
	end
}

ny_tenth_shuangbi_max = sgs.CreateMaxCardsSkill{
    name = "#ny_tenth_shuangbi_max",
    extra_func = function(self, target)
        return target:getMark("&ny_tenth_shuangbi-Clear")
    end,
}

ny_tenth_shuangbi_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_shuangbi_buff",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_shuangbi_mouzhouyu" then return 1000 end
        return 0
    end,
}

ny_10th_sunce_shuangbi:addSkill(ny_tenth_shuangbi)
ny_10th_sunce_shuangbi:addSkill(ny_tenth_shuangbi_max)
ny_10th_sunce_shuangbi:addSkill(ny_tenth_shuangbi_buff)
extension:insertRelatedSkills("ny_tenth_shuangbi","#ny_tenth_shuangbi_max")
extension:insertRelatedSkills("ny_tenth_shuangbi","#ny_tenth_shuangbi_buff")

ny_10th_caoyi = sgs.General(extension, "ny_10th_caoyi", "wei", 4, false, false, false)
ny_10th_caoyi_tiger = sgs.General(extension, "ny_10th_caoyi_tiger", "wei", 4, false, true, true)

ny_10th_miyi = sgs.CreateTriggerSkill{
    name = "ny_10th_miyi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if room:askForSkillInvoke(player, self:objectName(), data, false) then
                    local choice = room:askForChoice(player, self:objectName(), "damage+recover+cancel")
                    if choice == "cancel" then return false end
                    room:setPlayerFlag(player, "ny_10th_miyi_"..choice)

                    local targets = room:askForPlayersChosen(player, room:getAlivePlayers(),
                    self:objectName(), 0, 999, "@ny_10th_miyi:"..self:objectName().."_"..choice,
                    false, true)

                    room:setPlayerFlag(player, "-ny_10th_miyi_"..choice)
                    if (not targets) or (targets:isEmpty()) then return false end

                    local log = sgs.LogMessage()
                    log.type = "$ny_10th_miyi_chosen"
                    log.from = player
                    log.arg = self:objectName()
                    log.arg2 = string.format("%s:%s", self:objectName(), choice)
                    log.to = targets
                    room:sendLog(log)
                    room:broadcastSkillInvoke(self:objectName())

                    if choice == "damage" then
                        for _,target in sgs.qlist(targets) do
                            if target:isAlive() then
                                room:addPlayerMark(target, "&ny_10th_miyi-Clear", 1)
                                room:addPlayerMark(target, "ny_10th_miyi_recover-Clear", 1)
                                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
                            end
                        end
                    else
                        for _,target in sgs.qlist(targets) do
                            if target:isAlive() then
                                room:addPlayerMark(target, "&ny_10th_miyi-Clear", 1)
                                room:addPlayerMark(target, "ny_10th_miyi_damage-Clear", 1)
                                if target:isWounded() then
                                    room:recover(target, sgs.RecoverStruct(self:objectName(), player, 1))
                                end
                            end
                        end
                    end
                end
            end
            if player:getPhase() == sgs.Player_Finish then
                local first = true
                for _,target in sgs.qlist(room:getAlivePlayers()) do
                    if target:isAlive() and target:getMark("ny_10th_miyi_recover-Clear") > 0 then
                        if first then 
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true) 
                            first = false
                        end
                        if target:isWounded() then
                            room:recover(target, sgs.RecoverStruct(self:objectName(), player, 1))
                        end
                    end
                    if target:isAlive() and target:getMark("ny_10th_miyi_damage-Clear") > 0 then
                        if first then 
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true) 
                            first = false
                        end
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

ny_10th_yinjun = sgs.CreateTriggerSkill{
    name = "ny_10th_yinjun",
    events = {sgs.CardFinished,sgs.Predamage},
    frequency = sgs.Skill_NotFrequent,
    priority = 1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard")) then else return false end
            if player:getMark("ny_10th_yinjun_finish-Clear") > 0 then return false end
            if not use.m_isHandcard then return false end
            if use.to:length() ~= 1 then return false end
            local target = use.to:at(0)
            if (not target) or (target:objectName() == player:objectName()) then return false end
            if target:isDead() then return false end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("_ny_10th_yinjun")
            room:setCardFlag(slash, "ny_10th_yinjun")
                slash:deleteLater()
            if player:isProhibited(target, slash) then 
                return false
            end

            player:setTag("ny_10th_yinjun", data)
            local prompt = string.format("slash:%s:", target:getGeneralName())
            if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then 
                slash:deleteLater()
                return false
            end

            room:addPlayerMark(player, "&ny_10th_yinjun-Clear", 1)
            if player:getMark("&ny_10th_yinjun-Clear") > player:getHp() then 
                room:addPlayerMark(player, "ny_10th_yinjun_finish-Clear", 1)
            end

            local change = false
            if player:getGeneralName() == "ny_10th_caoyi" then
                change = true
                room:changeHero(player, "ny_10th_caoyi_tiger", false, false)
            end

            room:getThread():delay(200)
            room:useCard(sgs.CardUseStruct(slash, player, target))
            room:getThread():delay(200)

            if change then room:changeHero(player, "ny_10th_caoyi", false, false) end
        end
        if event == sgs.Predamage then
            local damage = data:toDamage()
            if (not damage.from) or (damage.from:objectName() ~= player:objectName()) then return false end
            if damage.card and damage.card:hasFlag("ny_10th_yinjun") then
                damage.from = nil
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_caoyi:addSkill(ny_10th_miyi)
ny_10th_caoyi_tiger:addSkill(ny_10th_miyi)
ny_10th_caoyi:addSkill(ny_10th_yinjun)
ny_10th_caoyi_tiger:addSkill(ny_10th_yinjun)

ny_10th_zhugeruoxue = sgs.General(extension, "ny_10th_zhugeruoxue", "wei", 3, false, false, false)

ny_10th_qiongying = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_qiongying",
    view_as = function(self)
        return ny_10th_qiongyingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_qiongying"))
    end
}

ny_10th_qiongyingCard = sgs.CreateSkillCard
{
    name = "ny_10th_qiongying",
    filter = function(self, targets, to_select)
        if #targets >= 1 then return false end
        return (not to_select:getEquips():isEmpty()) or (not to_select:getJudgingArea():isEmpty())
    end,
    feasible = function(self, targets)
        if #targets <= 0 then return false end
        local target = targets[1]
        local others = target:getAliveSiblings()
        for _,card in sgs.qlist(target:getEquips()) do
            local equip_index = card:getRealCard():toEquipCard():location()
            for _,other in sgs.qlist(others) do
                if other:hasEquipArea(equip_index) and (not other:getEquip(equip_index)) then
                    return true
                end
            end
        end
        for _,card in sgs.qlist(target:getJudgingArea()) do
            for _,other in sgs.qlist(others) do
                if other:hasJudgeArea() and (not other:containsTrick(card:objectName())) then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local player = effect.from
        local target = effect.to
        if target:getCards("ej"):isEmpty() then return false end
        local disable_ids = sgs.IntList()
        local others = room:getOtherPlayers(target)
        
        for _,card in sgs.qlist(target:getEquips()) do
            local equip_index = card:getRealCard():toEquipCard():location()
            local cant = true
            for _,other in sgs.qlist(others) do
                if other:hasEquipArea(equip_index) and (not other:getEquip(equip_index)) then
                    cant = false
                    break
                end
            end
            if cant then disable_ids:append(card:getEffectiveId()) end
        end
        for _,card in sgs.qlist(target:getJudgingArea()) do
            local cant = true
            for _,other in sgs.qlist(others) do
                if other:hasJudgeArea() and (not other:containsTrick(card:objectName())) then
                    cant = false
                    break
                end
            end
            if cant then disable_ids:append(card:getEffectiveId()) end
        end

        local card_id = room:askForCardChosen(player, target, "ej", self:objectName(), false, sgs.Card_MethodNone, disable_ids, false)
        if (not card_id) or (card_id < 0) then return false end
        local card = sgs.Sanguosha:getCard(card_id)

        local tos = sgs.SPlayerList()
        if card:isKindOf("EquipCard") then
            local equip_index = card:getRealCard():toEquipCard():location()
            for _,other in sgs.qlist(others) do
                if other:hasEquipArea(equip_index) and (not other:getEquip(equip_index)) then
                    tos:append(other)
                end
            end
        else
            for _,other in sgs.qlist(others) do
                if other:hasJudgeArea() and (not other:containsTrick(card:objectName())) then
                    tos:append(other)
                end
            end
        end

        local to = room:askForPlayerChosen(player, tos, self:objectName(), "@ny_10th_qiongying:"..card:objectName(), false, false)
        if not to then return false end
        if not card:isKindOf("EquipCard") then
            local log = sgs.LogMessage()
            log.type = "$LightningMove"
            log.from = target
            log.to:append(to)
            log.card_str = card:toString()
            room:sendLog(log)
        end

        local place = sgs.Player_PlaceEquip
        if card:isKindOf("TrickCard") then place = sgs.Player_PlaceJudge end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, target:objectName(), self:objectName(), "")
        room:moveCardTo(card, to, place, reason)

        if player:isDead() or player:isKongcheng() then return false end
        local pattern = string.format(".|%s|.|.", card:getSuitString())
        local dis = room:askForDiscard(player, self:objectName(), 1, 1, false, false, "ny_10th_qiongying_discard:"..card:getSuitString(), pattern)
        if not dis then room:showAllCards(player) end
    end
}

ny_tenth_nuanhuiVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_nuanhui",
    response_pattern = "@@ny_tenth_nuanhui",
    view_as = function(self, cards)
        --return ny_tenth_nuanhuiCard:clone()
        local pattern = sgs.Self:property("ny_tenth_nuanhui_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_nuanhuiCard = sgs.CreateSkillCard
{
    handling_method = sgs.Card_MethodUse,
    mute = true,
    name = "ny_tenth_nuanhui",
    filter = function(self, targets, to_select, player) 
		local pattern = player:property("ny_tenth_nuanhui_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local pattern = sgs.Self:property("ny_tenth_nuanhui_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
        card:deleteLater()
		return card:targetFixed()
	end,
	feasible = function(self, targets, player)	
		local pattern = player:property("ny_tenth_nuanhui_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local pattern = player:property("ny_tenth_nuanhui_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
		card:deleteLater()
        
		return card	
	end
}

ny_tenth_nuanhui = sgs.CreateTriggerSkill{
    name = "ny_tenth_nuanhui",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_nuanhuiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if (not p:getEquips():isEmpty()) then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "ny_tenth_nuanhui_chosen", true, true)
            if not target then return false end
            room:broadcastSkillInvoke(self:objectName())
            local n = target:getEquips():length()
            local u = 0
            local choices = "slash+fire_slash+thunder_slash+peach+analeptic+jink+cancel"
            for i = 1, n, 1 do
                room:setPlayerMark(target, "ny_tenth_nuanhui", i)
                local pattern = room:askForChoice(target, self:objectName(), choices)
                if pattern == "cancel" then break end
                local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
                card:deleteLater()
                if (not card:isAvailable(target)) then break end

                room:setPlayerProperty(target, "ny_tenth_nuanhui_card", sgs.QVariant(pattern))
                local prompt = string.format("@ny_tenth_nuanhui:%s::%s:", pattern, i)
                local use = room:askForUseCard(target, "@@ny_tenth_nuanhui", prompt)
                if use then u = u + 1
                else break end
                if target:isDead() then return false end
            end
            if u > 1 and target:isAlive() and (not target:getEquips():isEmpty()) then
                local card_ids = target:getEquipsId()
                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, target:objectName(), "ny_tenth_nuanhui", "")
                local move2 = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_DiscardPile, reason2)
                room:moveCardsAtomic(move2, true)
            end
        end 
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhugeruoxue:addSkill(ny_10th_qiongying)
ny_10th_zhugeruoxue:addSkill(ny_tenth_nuanhui)

ny_10th_xiahoumao = sgs.General(extension, "ny_10th_xiahoumao", "wei", 4, true, false, false)

ny_10th_tongwei = sgs.CreateViewAsSkill
{
    name = "ny_10th_tongwei",
    n = 2,
    view_filter = function(self, selected, to_select)
        return #selected < 2 
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local card = ny_10th_tongweiCard:clone()
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#ny_10th_tongwei")
    end
}

ny_10th_tongweiCard = sgs.CreateSkillCard
{
    name = "ny_10th_tongwei",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return to_select:objectName() ~= player:objectName()
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

        if effect.to:getMark("ny_10th_tongwei+"..source:objectName()) > 0 then
            local max = effect.to:getMark("ny_10th_tongwei_max+"..source:objectName())
            local min = effect.to:getMark("ny_10th_tongwei_min+"..source:objectName())
            local mark = string.format("&ny_10th_tongwei+%s+~+%s+#%s",min,max,source:objectName())
            room:setPlayerMark(effect.to, mark, 0)
            room:removePlayerMark(effect.to, "ny_10th_tongwei", 1)
        end

        local first = sgs.Sanguosha:getCard(self:getSubcards():at(0)):getNumber()
        local second = sgs.Sanguosha:getCard(self:getSubcards():at(1)):getNumber()
        local max = math.max(first, second)
        local min = math.min(first, second)

        local mark = string.format("&ny_10th_tongwei+%s+~+%s+#%s",min,max,source:objectName())
        room:setPlayerMark(effect.to, mark, 1)
        room:setPlayerMark(effect.to, "ny_10th_tongwei+"..source:objectName(), 1)
        room:addPlayerMark(effect.to, "ny_10th_tongwei", 1)
        room:setPlayerMark(effect.to, "ny_10th_tongwei_max+"..source:objectName(), max)
        room:setPlayerMark(effect.to, "ny_10th_tongwei_min+"..source:objectName(), min)
    end
}

ny_10th_tongwei_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_tongwei_buff",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        local num = use.card:getNumber()
        room:setPlayerMark(player, "ny_10th_tongwei", 0)

        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isAlive() and player:getMark("ny_10th_tongwei+"..p:objectName()) > 0 then
                room:setPlayerMark(player, "ny_10th_tongwei+"..p:objectName(), 0)
                room:sendCompulsoryTriggerLog(p, "ny_10th_tongwei", true)

                local max = player:getMark("ny_10th_tongwei_max+"..p:objectName())
                local min = player:getMark("ny_10th_tongwei_min+"..p:objectName())
                local mark = string.format("&ny_10th_tongwei+%s+~+%s+#%s",min,max,p:objectName())
                room:setPlayerMark(player, mark, 0)

                if num >= min and num <= max then
                    local choices = "slash+dismantlement"
                    local pattern = room:askForChoice(p, "ny_10th_tongwei", choices, data)
                    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
                    card:setSkillName("_ny_10th_tongwei")
                    room:useCard(sgs.CardUseStruct(card, p, player))
					card:deleteLater()
                else
                    room:broadcastSkillInvoke("ny_10th_tongwei")
                end
            end
            if player:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getMark("ny_10th_tongwei") > 0
    end,
}

ny_10th_cuguo = sgs.CreateTriggerSkill{
    name = "ny_10th_cuguo",
    --events = {sgs.SlashMissed,sgs.PostCardEffected,sgs.TrickEffect},
    events = {sgs.CardOffset},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        --[[if (event == sgs.SlashMissed) and player:hasSkill(self:objectName()) then
            local effect = data:toSlashEffect()
            room:addPlayerMark(player, "ny_10th_cuguo-Clear", 1)
            if effect.slash:hasFlag("ny_10th_cuguo_"..effect.to:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setCardFlag(effect.slash, "-ny_10th_cuguo_"..effect.to:objectName())
                room:loseHp(player, 1)
            end
            if player:isNude() then return false end
            if effect.to:isDead() then return false end
            if player:getMark("ny_10th_cuguo-Clear") == 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
                room:setCardFlag(effect.slash, "ny_10th_cuguo_"..effect.to:objectName())
                --room:cardEffect(effect.slash, player, effect.to)
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
                    room:addPlayerMark(effect.from, "ny_10th_cuguo-Clear", 1)
                    if effect.card:hasFlag("reeffct") then
                        room:sendCompulsoryTriggerLog(effect.from, self:objectName(), true, true)
                        room:setCardFlag(effect.card, "-reeffct")
                        room:loseHp(effect.from, 1)
                    end
                    if effect.from:isNude() then return false end
                    if effect.to:isDead() then return false end
                    if (effect.from:getMark("ny_10th_cuguo-Clear") == 1) then
                        room:sendCompulsoryTriggerLog(effect.from, self:objectName(), true, true)
                        room:askForDiscard(effect.from, self:objectName(), 1, 1, false, true)
                        room:setCardFlag(effect.card, "reeffct")
                        room:cardEffect(effect.card, effect.from, effect.to)
                    end
                end
            end
        end]]--

        local effect = data:toCardEffect()
        if effect.card:isKindOf("SkillCard") then return false end
        if (not effect.from:hasSkill(self:objectName())) then return false end 
        room:addPlayerMark(player, "ny_10th_cuguo-Clear", 1)

        if effect.card:hasFlag("ny_10th_cuguo_"..effect.to:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:setCardFlag(effect.card, "-ny_10th_cuguo_"..effect.to:objectName())
            room:loseHp(player, 1, true, player, self:objectName())
        end

        if player:isNude() then return false end
        if effect.to:isDead() then return false end

        if player:getMark("ny_10th_cuguo-Clear") == 1 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:askForDiscard(player, self:objectName(), 1, 1, false, true)

            if effect.to:isDead() then return false end

            room:setCardFlag(effect.card, "ny_10th_cuguo_"..effect.to:objectName())
            room:cardEffect(effect.card, player, effect.to)
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_10th_xiahoumao:addSkill(ny_10th_tongwei)
ny_10th_xiahoumao:addSkill(ny_10th_tongwei_buff)
ny_10th_xiahoumao:addSkill(ny_10th_cuguo)
extension:insertRelatedSkills("ny_10th_tongwei", "#ny_10th_tongwei_buff")

ny_10th_dongguiren_second = sgs.General(extension, "ny_10th_dongguiren_second", "qun", 3, false, false, false)

ny_10th_lingfang = sgs.CreateTriggerSkill{
    name = "ny_10th_lingfang",
    events = {sgs.EventPhaseStart,sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if (not player:hasSkill(self:objectName())) then return false end
            if player:getPhase() ~= sgs.Player_Start then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "&ny_10th_jiao", 1)
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if (not use.card:isBlack()) then return false end
            if use.from:objectName() ~= player:objectName() then return false end
            local cant = true
            for _,to in sgs.qlist(use.to) do
                if to:objectName() ~= player:objectName() then 
                    cant = false
                    break
                end
            end
            if cant then return false end
            if player:hasSkill(self:objectName()) and player:isAlive() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "&ny_10th_jiao", 1)
            end
            for _,to in sgs.qlist(use.to) do
                if to:hasSkill(self:objectName()) and to:objectName() ~= player:objectName() and to:isAlive()  then
                    room:sendCompulsoryTriggerLog(to, self:objectName(), true, true)
                    room:addPlayerMark(to, "&ny_10th_jiao", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_lianzhi = sgs.CreateTriggerSkill{
    name = "ny_10th_lianzhi",
    events = {sgs.GameStart,sgs.EnterDying,sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    waked_skills = "ny_10th_shouze",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ny_10th_lianzhi", false, true)
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(target, "&ny_10th_lianzhi+#"..player:objectName(), 1)
        end
        if event == sgs.EnterDying then
            if player:getMark("ny_10th_lianzhi-Clear") > 0 then return false end
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                local cant = true
                local target 
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("&ny_10th_lianzhi+#"..player:objectName()) > 0 then
                        cant = false
                        target = p
                        break
                    end
                end
                if cant then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "ny_10th_lianzhi-Clear", 1)
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
                if player:isAlive() then player:drawCards(1, self:objectName()) end
                if target and target:isAlive() then target:drawCards(1, self:objectName()) end
            end
        end
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("&ny_10th_lianzhi+#"..player:objectName()) > 0 then
                room:setPlayerFlag(player, "ny_10th_shouze")
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "ny_10th_lianzhi_chosen", true, true)
                room:setPlayerFlag(player, "-ny_10th_shouze")
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:acquireSkill(player, "ny_10th_shouze")
                    room:acquireSkill(target, "ny_10th_shouze")
                    room:addPlayerMark(target, "&ny_10th_jiao", math.max(player:getMark("&ny_10th_jiao"), 1))
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shouze = sgs.CreateTriggerSkill{
    name = "ny_10th_shouze",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            if player:getMark("&ny_10th_jiao") <= 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:removePlayerMark(player, "&ny_10th_jiao", 1)
            local blacks = {}
            for _,id in sgs.qlist(room:getDiscardPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isBlack() then
                    table.insert(blacks, card)
                end
            end
            if #blacks > 0 then
                room:obtainCard(player, blacks[math.random(1,#blacks)])
                if player:isAlive() then room:loseHp(player, 1, true, player, self:objectName()) end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_fengyingVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_fengying",
    n = 99,
    response_pattern = "@@ny_tenth_fengying",
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return sgs.Self:getHandcards():contains(to_select) and #selected < 1
            and to_select:getNumber() <= sgs.Self:getMark("&ny_10th_jiao")
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "@@ny_tenth_fengying" then
                pattern = sgs.Self:property("ny_tenth_fengying_card"):toString()
            elseif pattern == "Jink" then
                pattern = "jink"
            end
            if string.find(pattern, "analeptic") then pattern = "analeptic" end
            if #cards == 1 then
                local card = ny_tenth_fengyingCard:clone()
                card:setUserString(pattern)
                card:addSubcard(cards[1])
                return card
            end
        else
            return ny_tenth_fengyingSelectCard:clone()
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark("&ny_10th_jiao") <= 0 then return false end
        return true
    end,
    --[[enabled_at_nullification = function(self, player)
        if player:getMark("&ny_10th_jiao") <= 0 then return false end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end

        local need = string.format("ny_tenth_fengying_record_%s", "nullification")
        local mark = string.format("ny_tenth_fengying_%s-Clear", "nullification")
        return player:getMark(mark) == 0 and player:getMark(need) > 0
    end,]]
    enabled_at_response = function(self, player, pattern)
        if player:getMark("&ny_10th_jiao") <= 0 then return false end
        if pattern == "@@ny_tenth_fengying" then return true end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
        local real = pattern

        if real == "Slash" then real = "slash" end
        if real == "Jink" then real = "jink" end
        if string.find(real, "analeptic") then real = "analeptic" end

        for _,mark in sgs.list(player:getMarkNames()) do
            if mark:startsWith("ny_tenth_fengying_record") and player:getMark(mark) > 0 then
                if string.find(mark, real) then
                    local thispattern = string.sub(mark, 26)
                    local need = string.format("ny_tenth_fengying_%s-Clear", thispattern)
                    if player:getMark(need) <= 0 then return true end
                end
            end
        end

        return false 
    end,
}

ny_tenth_fengyingSelectCard = sgs.CreateSkillCard
{
    name = "ny_tenth_fengyingSelect",
    mute = true,
    target_fixed = true,
    about_to_use = function(self,room,use)
        local player = use.from
        local names = player:getTag("ny_tenth_fengying"):toString():split("+")
        
        if (not names) or (#names <= 0) then
            room:askForChoice(player, "ny_tenth_fengying", "cancel+nocards")
            return false
        end

        local choices = {}
        local disable = {}
        for _,name in ipairs(names) do
            local card = sgs.Sanguosha:cloneCard(name)
            card:setSkillName("ny_tenth_fengying")
            card:deleteLater()
            local mark = string.format("ny_tenth_fengying_%s-Clear", name)
            if player:getMark(mark) == 0 and card:isAvailable(player) then
                table.insert(choices, name)
            else
                table.insert(disable, name)
            end
        end
        if #choices <= 0 then
            room:askForChoice(player, "ny_tenth_fengying", "cancel+nocards")
        else
            table.insert(choices, "cancel")
            local pattern = room:askForChoice(player, "ny_tenth_fengying", table.concat(choices, "+"), sgs.QVariant(), table.concat(disable, "+"))
            if pattern == "cancel" then return false end
            room:setPlayerProperty(player, "ny_tenth_fengying_card", sgs.QVariant(pattern))
            room:askForUseCard(player, "@@ny_tenth_fengying", "@ny_tenth_fengying:"..pattern)
        end
    end,
}

ny_tenth_fengyingCard = sgs.CreateSkillCard
{
    name = "ny_tenth_fengying",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_fengying")
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_fengying")
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local choices = {}
            local names = player:getTag("ny_tenth_fengying"):toString():split("+")
            for _,name in ipairs(names) do
                if string.find(name, "slash") then
                    local mark = string.format("ny_tenth_fengying_%s-Clear", name)
                    if player:getMark(mark) == 0 then
                        table.insert(choices, name)
                    end
                end
            end
            if #choices <= 0 then choices = {"slash"} end
            pattern = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), sgs.QVariant(3))
        end

        local mark = string.format("ny_tenth_fengying_%s-Clear", pattern)
        room:setPlayerMark(player, mark, 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_fengying")
        card:addSubcards(self:getSubcards())
        room:setCardFlag(card, "RemoveFromHistory")
        card:deleteLater()
		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = self:getUserString()
		if pattern == "Slash" then 
            local choices = {}
            local names = player:getTag("ny_tenth_fengying"):toString():split("+")
            for _,name in ipairs(names) do
                if string.find(name, "slash") then
                    local mark = string.format("ny_tenth_fengying_%s-Clear", name)
                    if player:getMark(mark) == 0 then
                        table.insert(choices, name)
                    end
                end
            end
            if #choices <= 0 then choices = {"slash"} end
            pattern = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), sgs.QVariant(3))
        end

        local mark = string.format("ny_tenth_fengying_%s-Clear", pattern)
        room:setPlayerMark(player, mark, 1)

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_fengying")
        card:addSubcards(self:getSubcards())
        room:setCardFlag(card, "RemoveFromHistory")
        card:deleteLater()
		return card
    end
}

ny_tenth_fengying = sgs.CreateTriggerSkill{
    name = "ny_tenth_fengying",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_fengyingVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.from ~= sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getTag("ny_tenth_fengying") and p:hasSkill(self:objectName()) then 
                local names = p:getTag("ny_tenth_fengying"):toString():split("+")
                for _,name in ipairs(names) do
                    local mark = string.format("ny_tenth_fengying_record_%s", name)
                    room:setPlayerMark(p, mark, 0)
                end
                p:removeTag("ny_tenth_fengying") 
            end
        end
        local names = {}
        for _,id in sgs.qlist(room:getDiscardPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isBlack() and (card:isKindOf("BasicCard") or card:isNDTrick()) and (not table.contains(names, card:objectName())) then
                table.insert(names, card:objectName())
            end
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            p:setTag("ny_tenth_fengying", sgs.QVariant(table.concat(names, "+")))
            for _,name in ipairs(names) do
                local mark = string.format("ny_tenth_fengying_record_%s", name)
                room:setPlayerMark(p, mark, 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_tenth_fengying_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_fengying_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_fengying" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_fengying" then return 1000 end
        return 0
    end,
}

ny_10th_dongguiren_second:addSkill(ny_10th_lianzhi)
ny_10th_dongguiren_second:addSkill(ny_10th_lingfang)
ny_10th_dongguiren_second:addSkill(ny_tenth_fengying)
ny_10th_dongguiren_second:addSkill(ny_tenth_fengyingVS)
ny_10th_dongguiren_second:addSkill(ny_tenth_fengying_buff)
extension:insertRelatedSkills("#ny_tenth_fengying_buff", "ny_tenth_fengying")

ny_10th_pangshanmin = sgs.General(extension, "ny_10th_pangshanmin", "wei", 3, true, false, false)

ny_10th_caisi = sgs.CreateTriggerSkill{
    name = "ny_10th_caisi",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("ny_10th_caisi_failed-Clear") > 0 then return false end
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName()
        and use.card:isKindOf("BasicCard") and player:isAlive() then
            local n = player:getMark("&ny_10th_caisi-Clear") + 1
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("get:"..n)) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, "&ny_10th_caisi-Clear", 1)
                local get = sgs.Sanguosha:cloneCard("jink")
                if player:getPhase() ~= sgs.Player_NotActive then
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if (not card:isKindOf("BasicCard")) then
                            get:addSubcard(card)
                            n = n - 1
                            if n <= 0 then break end
                        end
                    end
                else
                    for i = (room:getDiscardPile():length() - 1), 0, -1 do
                        local id = room:getDiscardPile():at(i)
                        local card = sgs.Sanguosha:getCard(id)
                        if (not card:isKindOf("BasicCard")) then
                            get:addSubcard(card)
                            n = n - 1
                            if n <= 0 then break end
                        end
                    end
                end
                if get:subcardsLength() > 0 then
                    room:obtainCard(player, get, false)
                end
                get:deleteLater()
                if player:getMark("&ny_10th_caisi-Clear") >= player:getMaxHp() then
                    room:setPlayerMark(player, "ny_10th_caisi_failed-Clear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhuoli = sgs.CreateTriggerSkill{
    name = "ny_10th_zhuoli",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
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
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            room:addPlayerMark(player, "ny_10th_zhuoli_use-Clear", 1)
            local value = math.max(player:getMark("ny_10th_zhuoli_use-Clear"), player:getMark("ny_10th_zhuoli_get-Clear"))
            room:setPlayerMark(player, "&ny_10th_zhuoli-Clear", value)
        end

        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and player:isAlive() and move.to_place == sgs.Player_PlaceHand then
                room:addPlayerMark(player, "ny_10th_zhuoli_get-Clear", move.card_ids:length())
                local value = math.max(player:getMark("ny_10th_zhuoli_use-Clear"), player:getMark("ny_10th_zhuoli_get-Clear"))
                room:setPlayerMark(player, "&ny_10th_zhuoli-Clear", value)
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local max = room:getAllPlayers(true):length()
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:isAlive() and p:getMark("&ny_10th_zhuoli-Clear") > p:getHp() then
                        if p:getMaxHp() < max then
                            room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                            room:gainMaxHp(p, 1, self:objectName())
                            if p:isAlive() and p:isWounded() then
                                room:recover(p, sgs.RecoverStruct(self:objectName(), p, 1))
                            end
                        elseif p:isWounded() then
                            room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                            room:recover(p, sgs.RecoverStruct(self:objectName(), p, 1))
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

ny_10th_pangshanmin:addSkill(ny_10th_caisi)
ny_10th_pangshanmin:addSkill(ny_10th_zhuoli)

ny_10th_xizheng = sgs.General(extension, "ny_10th_xizheng", "shu", 3, true, false, false)

ny_10th_danyi = sgs.CreateTriggerSkill{
    name = "ny_10th_danyi",
    events = {sgs.TargetConfirmed,sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.to:isEmpty() then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, "&ny_10th_danyi+#"..player:objectName(), 0)
                end
            end
        end
        if event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_isUse then
                if response.m_card:isKindOf("SkillCard") then return false end
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, "&ny_10th_danyi+#"..player:objectName(), 0)
                end
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.from ~= player then return false end

            local n = 0
            for _,to in sgs.qlist(use.to) do
                if to:getMark("&ny_10th_danyi+#"..player:objectName()) > 0 then
                    n = n + 1
                end
            end
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "&ny_10th_danyi+#"..player:objectName(), 0)
            end

            local _player = sgs.SPlayerList()
            _player:append(player)
            for _,to in sgs.qlist(use.to) do
                room:setPlayerMark(to, "&ny_10th_danyi+#"..player:objectName(), 1, _player)
            end

            if n <= 0 then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..n)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(n, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_wencan = sgs.CreateViewAsSkill
{
    name = "ny_tenth_wencan",
    response_pattern = "@@ny_tenth_wencan",
    n = 99,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            for _,card in ipairs(selected) do
                if card:getSuit() == to_select:getSuit() then return false end
            end
            return #selected < 2
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            if #cards == 2 then
                local cc = ny_tenth_wencanDisCard:clone()
                for _,card in ipairs(cards) do
                    cc:addSubcard(card)
                end
                return cc
            end
            return nil
        else
            return ny_tenth_wencanCard:clone()
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_tenth_wencan"))
    end
}

ny_tenth_wencanCard = sgs.CreateSkillCard
{
    name = "ny_tenth_wencan",
    filter = function(self, targets, to_select)
        for _,p in ipairs(targets) do
            if to_select:getHp() == p:getHp() then return false end
        end
        return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isAlive() then
            if (not room:askForUseCard(effect.to, "@@ny_tenth_wencan", "@ny_tenth_wencan:"..effect.from:getGeneralName())) then
                room:setPlayerMark(effect.to, "&ny_tenth_wencan+#"..effect.from:objectName().."-Clear", 1)
            end
        end
    end,
}

ny_tenth_wencanDisCard = sgs.CreateSkillCard
{
    name = "ny_tenth_wencanDisCard",
    mute = true,
    target_fixed = true,
    will_throw = false,
    about_to_use = function(self,room,use)
        local source = use.from
        local log = sgs.LogMessage()
        log.type = "$DiscardCard"
        log.from = source
        log.card_str = table.concat(sgs.QList2Table(self:getSubcards()),"+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName(), "ny_tenth_wencan", "")
        local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)
    end,
}

ny_tenth_wencan_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_wencan_buff",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from and to and to:getMark("&ny_tenth_wencan+#"..from:objectName().."-Clear") > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from and to and to:getMark("&ny_tenth_wencan+#"..from:objectName().."-Clear") > 0 then return 1000 end
        return 0
    end,
}

ny_10th_xizheng:addSkill(ny_10th_danyi)
ny_10th_xizheng:addSkill(ny_tenth_wencan)
ny_10th_xizheng:addSkill(ny_tenth_wencan_buff)
extension:insertRelatedSkills("ny_tenth_wencan", "#ny_tenth_wencan_buff")

ny_10th_lidian = sgs.General(extension, "ny_10th_lidian", "wei", 3, true, false, false)

ny_10th_wangxi = sgs.CreateTriggerSkill{
    name = "ny_10th_wangxi",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        local target
        local damage = data:toDamage()
        if event == sgs.Damage then 
            target = damage.to
        else
            target = damage.from
        end
        if (not target) or target:objectName() == player:objectName() or target:isDead() then return false end
        for i = 1, damage.damage, 1 do
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..target:getGeneralName())) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(2, self:objectName())
                if player:isAlive() and target:isAlive() and (not player:isNude()) then
                    local card = room:askForExchange(player, self:objectName(), 1, 1, true, "@ny_10th_wangxi:"..target:getGeneralName(), false)
                    if card then
                        room:giveCard(player, target, card, self:objectName(), false)
                    end
                end
            end
            if player:isDead() or target:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_lidian:addSkill("xunxun")
ny_10th_lidian:addSkill(ny_10th_wangxi)

ny_10th_yuezhoufei_second = sgs.General(extension, "ny_10th_yuezhoufei_second", "wu", 3, false, false, false)

ny_10th_lingkong_second = sgs.CreateTriggerSkill{
    name = "ny_10th_lingkong_second",
    events = {sgs.GameStart,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            for _,card in sgs.qlist(player:getHandcards()) do
                room:setCardFlag(card, "ny_10th_konghou_second")
                room:setCardTip(card:getId(), "ny_10th_konghou_second")
            end
        end
        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            if player:getPhase() == sgs.Player_Draw then return false end
            if player:getMark("ny_10th_lingkong_second-Clear") > 0 then return false end
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand and player:isAlive() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "ny_10th_lingkong_second-Clear", 1)
                for _,id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id) == player then
                        room:setCardFlag(sgs.Sanguosha:getCard(id), "ny_10th_konghou_second")
                        room:setCardTip(id, "ny_10th_konghou_second")
                    end
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:hasFlag("ny_10th_konghou_second") then
                        room:clearCardTip(card:getId())
                        room:setCardTip(card:getId(), "ny_10th_konghou_second")
                        room:ignoreCards(player, card)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_xianshu_second = sgs.CreateViewAsSkill
{
    name = "ny_10th_xianshu_second",
    n = 99,
    view_filter = function(self, selected, to_select)
        return to_select:hasFlag("ny_10th_konghou_second") and #selected == 0
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = ny_10th_xianshu_secondCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = true,
}

ny_10th_xianshu_secondCard = sgs.CreateSkillCard
{
    name = "ny_10th_xianshu_second",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets == 0 and player:objectName() ~= to_select:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()

        local id = self:getSubcards():first()
        room:showCard(effect.from, id)
        room:obtainCard(effect.to, id, true)

        if effect.to:isAlive() and effect.from:isAlive() then
            local n = effect.to:getHp() - effect.from:getHp()
            n = math.abs(n)
            n = math.min(n,5)
            effect.from:drawCards(n, self:objectName())
        end

        if effect.to:isDead() then return false end
        local card = sgs.Sanguosha:getCard(id)
        if card:isRed() and effect.to:getHp() <= effect.from:getHp() and effect.to:isWounded() then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, 1))
        elseif card:isBlack() and effect.to:getHp() >= effect.from:getHp() then
            room:loseHp(effect.to, 1, true, effect.from, self:objectName())
        end
    end
}

ny_10th_yuezhoufei_second:addSkill(ny_10th_lingkong_second)
ny_10th_yuezhoufei_second:addSkill(ny_10th_xianshu_second)

ny_10th_caoxian = sgs.General(extension, "ny_10th_caoxian", "wei", 3, false, false, false)

ny_10th_lingxi = sgs.CreateTriggerSkill{
    name = "ny_10th_lingxi",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart or event == sgs.EventPhaseEnd then
            if player:isNude() then return false end
            if player:getPhase() ~= sgs.Player_Play then return false end
            if event == sgs.EventPhaseStart then
                room:setPlayerMark(player, "ny_10th_lingxi_start", 1)
            else
                room:setPlayerMark(player, "ny_10th_lingxi_start", 0)
            end

            local n = player:getMaxHp()
            local put = room:askForExchange(player, self:objectName(), n, 1, true, "@ny_10th_lingxi:"..n, true)
            if not put then return false end

            local log = sgs.LogMessage()
            log.type = "#InvokeSkill"
            log.from = player
            log.arg = self:objectName()
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())

            player:addToPile("ny_10th_yi", put)
        end
        if event == sgs.CardsMoveOneTime then
            if player:isDead() then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceSpecial) then
                local cant = true
                for _,name in ipairs(move.from_pile_names) do
                    if name == "ny_10th_yi" then
                        cant = false
                        break
                    end
                end
                if cant then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local suits = {}
                for _,id in sgs.qlist(player:getPile("ny_10th_yi")) do
                    local suit = sgs.Sanguosha:getCard(id):getSuitString()
                    if not table.contains(suits, suit) then
                        table.insert(suits, suit)
                    end
                end
                local num = (#suits)*2
                if player:getHandcardNum() < num then
                    player:drawCards(num - player:getHandcardNum(), self:objectName())
                elseif player:getHandcardNum() > num then
                    local dis = player:getHandcardNum() - num
                    room:askForDiscard(player, "ny_10th_lingxi_dis", dis, dis, false, false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_zhifouVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_zhifou",
    expand_pile = "ny_10th_yi",
    n = 999,
    response_pattern = "@@ny_tenth_zhifou",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("ny_10th_yi"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        local n = sgs.Self:getMark("ny_tenth_zhifou-Clear") + 1
        if #cards >= n then
            local cc = ny_tenth_zhifouCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,

}

ny_tenth_zhifouCard = sgs.CreateSkillCard
{
    name = "ny_tenth_zhifou",
    will_throw = true,
    filter = function(self, targets, to_select,player)
        if (not player:hasFlag("ny_tenth_zhifou_lose")) and to_select:isNude() then return false end
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()

        local all = {"lose","discard","put"}
        local choice
        for _,item in ipairs(all) do
            local flag = string.format("ny_tenth_zhifou_%s", item)
            local mark = string.format("ny_tenth_zhifou_%s-Clear", item)
            if effect.from:hasFlag(flag) then
                choice = item
                room:setPlayerFlag(effect.from, "-"..flag)
                room:setPlayerMark(effect.from, mark, 1)
                break
            end
        end
        room:addPlayerMark(effect.from, "ny_tenth_zhifou-Clear", 1)
        
        local log = sgs.LogMessage()
        log.type = "$ny_tenth_zhifou_chosen"
        log.from = effect.from
        log.to:append(effect.to)
        log.arg = self:objectName()..":"..choice
        room:sendLog(log)

        if effect.to:isDead() then return false end

        if choice == "lose" then
            room:loseHp(effect.to, 1, true, effect.from, self:objectName())
        elseif choice == "discard" then
            room:askForDiscard(effect.to, self:objectName(), 2, 2, false, true)
        else
            local put = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "ny_tenth_zhifou_put", false)
            if put and effect.from:isAlive() then
                effect.from:addToPile("ny_10th_yi", put)
            end
        end
    end
}

ny_tenth_zhifou = sgs.CreateTriggerSkill{
    name = "ny_tenth_zhifou",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_zhifouVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if player:isDead() then return false end
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        local n = player:getMark("ny_tenth_zhifou-Clear") + 1
        if player:getPile("ny_10th_yi"):length() < n then return false end
        if n > 3 then return false end

        local all = {"lose","discard","put"}
        local choices = {}
        for _,item in ipairs(all) do
            local mark = string.format("ny_tenth_zhifou_%s-Clear", item)
            if player:getMark(mark) <= 0 then
                table.insert(choices,item)
            end
        end
        if #choices <= 0 then return false end
        table.insert(choices, "cancel")

        if not room:askForSkillInvoke(player, self:objectName(), data, false) then return false end

        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        if choice == "cancel" then return false end

        local flag = string.format("ny_tenth_zhifou_%s", choice)
        room:setPlayerFlag(player, flag)
        if not room:askForUseCard(player, "@@ny_tenth_zhifou", "@ny_tenth_zhifou:"..n) then 
            room:setPlayerFlag(player, "-"..flag)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_caoxian:addSkill(ny_10th_lingxi)
ny_10th_caoxian:addSkill(ny_tenth_zhifou)
ny_10th_caoxian:addSkill(ny_tenth_zhifouVS)

ny_10th_dongxie_second = sgs.General(extension, "ny_10th_dongxie_second", "qun", 4, false, false, false)

ny_tenth_jiaoxia_second = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_jiaoxia_second",
    response_pattern = "@@ny_tenth_jiaoxia_second",
    view_as = function(self)
        return ny_tenth_jiaoxia_secondCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

ny_tenth_jiaoxia_secondCard = sgs.CreateSkillCard{
	name = "ny_tenth_jiaoxia_second",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select,player)
		local card = sgs.Sanguosha:getCard(player:getMark("ny_tenth_jiaoxia_second_card"))

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
		local card = sgs.Sanguosha:getCard(player:getMark("ny_tenth_jiaoxia_second_card"))

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local card = sgs.Sanguosha:getCard(player:getMark("ny_tenth_jiaoxia_second_card"))
		return card
	end,
}

ny_tenth_jiaoxia_second_trigger = sgs.CreateTriggerSkill
{
    name = "ny_tenth_jiaoxia_second",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.EventLoseSkill,sgs.Damage,sgs.CardFinished,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_jiaoxia_second,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("ny_tenth_jiaoxia_second_damage") then
                room:setCardFlag(use.card, "-ny_tenth_jiaoxia_second_damage")
                local card_id = use.card:getId()
                local card = sgs.Sanguosha:getCard(card_id)
                room:setPlayerMark(player, "ny_tenth_jiaoxia_second_card", card_id)
                if card:isAvailable(player) then
                    room:askForUseCard(player, "@@ny_tenth_jiaoxia_second", "@ny_tenth_jiaoxia_second:"..card:objectName())
                    
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("slash")) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "&ny_10th_jiaoxia-PlayClear", 1)
                if not player:hasSkill("ny_10th_jiaoxia_filter") then
                    room:acquireSkill(player, "ny_10th_jiaoxia_filter", false)
                end
                room:filterCards(player, player:getCards("h"), true)
            end
        end
        if event == sgs.EventPhaseEnd or event == sgs.EventLoseSkill then
            if event == sgs.EventPhaseEnd and player:getPhase() ~= sgs.Player_Play then return false end
            room:setPlayerMark(player, "&ny_10th_jiaoxia-PlayClear", 0)
            room:filterCards(player, player:getCards("h"), true)
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and table.contains(damage.card:getSkillNames(),"ny_10th_jiaoxia") then
                room:setCardFlag(damage.card, "ny_tenth_jiaoxia_second_damage")
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _,p in sgs.qlist(use.to) do
                    room:setPlayerMark(p, "ny_tenth_jiaoxia_second_used-PlayClear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_jiaoxia_second_buff = sgs.CreateTargetModSkill
{
    name = "#ny_tenth_jiaoxia_second_buff",
    residue_func = function(self, from, card, to)
        if from:hasSkill("ny_tenth_jiaoxia_second") and to and to:getMark("ny_tenth_jiaoxia_second_used-PlayClear") == 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("ny_tenth_jiaoxia_second") and to and to:getMark("ny_tenth_jiaoxia_second_used-PlayClear") == 0 then return 1000 end
        return 0
    end,
}

ny_10th_humei_second = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_humei_second",
    tiansuan_type = "draw,give,recover",
    view_as = function(self)
        local cc = ny_10th_humei_secondCard:clone()
        cc:setUserString(sgs.Self:getTag("ny_10th_humei_second"):toString())
        return cc
    end,
    enabled_at_play = function(self, player)
        local choices = {"draw", "give", "recover"}
        for _,p in ipairs(choices) do
            if player:getMark("ny_10th_humei_second_tiansuan_remove_"..p.."-PlayClear") == 0 then
                return true
            end
        end
    end,
}

ny_10th_humei_secondCard = sgs.CreateSkillCard
{
    name = "ny_10th_humei_second",
    filter = function(self, targets, to_select,player)
        local choice = self:getUserString()
        if choice == "give" and to_select:isNude() then return false end
        if choice == "give" and to_select:objectName() == player:objectName() then return false end
        if choice == "recover" and (not to_select:isWounded()) then return false end
        return to_select:getHp() <= player:getMark("&ny_10th_humei_second-PlayClear") and #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choice = self:getUserString()
        room:setPlayerMark(effect.from, "ny_10th_humei_second_tiansuan_remove_"..choice.."-PlayClear", 1)
        if choice == "draw" then
            effect.to:drawCards(1, self:objectName())
        end
        if choice == "give" then
            local obtain = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "@ny_10th_humei_second:"..effect.from:getGeneralName(), false)
            room:obtainCard(effect.from, obtain, false)
        end
        if choice == "recover" then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
        end
    end
}

ny_10th_humei_second_damage = sgs.CreateTriggerSkill{
    name = "#ny_10th_humei_second_damage",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        room:addPlayerMark(player, "&ny_10th_humei_second-PlayClear", damage.damage)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
        and target:isAlive() and target:getPhase() == sgs.Player_Play
    end,
}

ny_10th_dongxie_second:addSkill(ny_tenth_jiaoxia_second_trigger)
ny_10th_dongxie_second:addSkill(ny_tenth_jiaoxia_second)
ny_10th_dongxie_second:addSkill(ny_tenth_jiaoxia_second_buff)
ny_10th_dongxie_second:addSkill(ny_10th_humei_second)
ny_10th_dongxie_second:addSkill(ny_10th_humei_second_damage)
extension:insertRelatedSkills("ny_10th_jiaoxia","#ny_tenth_jiaoxia_second_buff")
extension:insertRelatedSkills("ny_10th_humei_second","#ny_10th_humei_second_damage")

ny_10th_wuluxun = sgs.General(extension, "ny_10th_wuluxun", "wu", 3, true, false, false)

ny_10th_xiongmu = sgs.CreateTriggerSkill{
    name = "ny_10th_xiongmu",
    events = {sgs.DamageInflicted,sgs.RoundStart,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            if player:getMark("ny_10th_xiongmu-Clear") > 0 then return false end
            room:setPlayerMark(player, "ny_10th_xiongmu-Clear", 1)
            if player:getHandcardNum() > player:getHp() then return false end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("reduce")) then else return false end
            room:broadcastSkillInvoke(self:objectName())

            local damage = data:toDamage()

            local log = sgs.LogMessage()
            log.type = "$ny_10th_xiongmu_reduce"
            log.from = player
            log.arg = damage.damage
            damage.damage = damage.damage - 1
            log.arg2 = damage.damage
            room:sendLog(log)

            data:setValue(damage)
            if damage.damage <= 0 then return true end
        end

        if event == sgs.RoundStart then
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            room:broadcastSkillInvoke(self:objectName())

            if player:getHandcardNum() < player:getMaxHp() then 
                player:drawCards(player:getMaxHp() - player:getHandcardNum(), self:objectName())
            end

            local dc = room:askForExchange(player, self:objectName(), 999, 1, true, "@ny_10th_xiongmu", true)
            if dc==nil then return false end

            room:shuffleIntoDrawPile(player, dc:getSubcards(), self:objectName(), false)
            
            local get = sgs.Sanguosha:cloneCard("jink")
            for _,id in sgs.qlist(room:getDrawPile()) do
                if sgs.Sanguosha:getCard(id):getNumber() == 8 then
                    get:addSubcard(id)
                end
                if get:subcardsLength()>=dc:subcardsLength() then break end
            end
                for _,id in sgs.qlist(room:getDiscardPile()) do
                if get:subcardsLength()>=dc:subcardsLength() then break end
				if sgs.Sanguosha:getCard(id):getNumber() == 8 then
					get:addSubcard(id)
                end
            end
            room:obtainCard(player, get, false)
            for _,id in sgs.qlist(player:handCards()) do
                if get:getSubcards():contains(id) then
                    room:setCardTip(id, self:objectName())
                end
            end
            get:deleteLater()
        end

        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,cc in sgs.qlist(player:getHandcards()) do
                    if cc:hasTip(self:objectName()) then
                        room:ignoreCards(player, cc)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
		and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhangcai = sgs.CreateTriggerSkill{
    name = "ny_10th_zhangcai",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card = nil
        if event == sgs.CardUsed then 
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:isKindOf("SkillCard") then return false end
        if card:getNumber() == 8 or player:getMark("&ny_10th_ruxian") > 0 then else return false end
        local n = 0
        for _,cc in sgs.qlist(player:getHandcards()) do
            if cc:getNumber() == card:getNumber() then
                n = n + 1
            end
        end
        n = math.max(1,n)
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..n)) then
            room:broadcastSkillInvoke(self:objectName())
            if player:getMark("&ny_10th_ruxian") > 0 then
                room:notifySkillInvoked(player, "ny_10th_ruxian")
            end
            player:drawCards(n, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_ruxian = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_ruxian",
    frequency = sgs.Skill_Limited,
    view_as = function(self)
        return ny_10th_ruxianCard:clone()
    end,
    enabled_at_play = function(self,player)
        return player:getMark("ny_10th_ruxian_limit") == 0
    end
}

ny_10th_ruxianCard = sgs.CreateSkillCard
{
    name = "ny_10th_ruxian",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "&ny_10th_ruxian", 1)
        room:setPlayerMark(source, "ny_10th_ruxian_limit", 1)
    end
}

ny_10th_ruxian_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_ruxian_clear",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.from == sgs.Player_NotActive then
            room:setPlayerMark(player, "&ny_10th_ruxian", 0)
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&ny_10th_ruxian") > 0
    end,
}

ny_10th_wuluxun:addSkill(ny_10th_xiongmu)
ny_10th_wuluxun:addSkill(ny_10th_zhangcai)
ny_10th_wuluxun:addSkill(ny_10th_ruxian)
ny_10th_wuluxun:addSkill(ny_10th_ruxian_clear)
extension:insertRelatedSkills("ny_10th_ruxian","#ny_10th_ruxian_clear")

ny_10th_zhaoyun_thefirst = sgs.General(extension, "ny_10th_zhaoyun_thefirst", "god", 1, true, true, false)

ny_10th_jvejin = sgs.CreateTriggerSkill{
    name = "ny_10th_jvejin",
    events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime,sgs.GameStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw and (not player:isSkipped(sgs.Player_Draw)) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:skip(sgs.Player_Draw)
            end
        end
        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            if player:getHandcardNum() == 4 then return false end
            local move = data:toMoveOneTime()
            if (move.from_places:contains(sgs.Player_PlaceHand) and move.from:objectName() == player:objectName())
            or (move.to_place == sgs.Player_PlaceHand and move.to:objectName() == player:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                if player:getHandcardNum() < 4 then
                    player:drawCards(4 - player:getHandcardNum(), self:objectName())
                elseif player:getHandcardNum() > 4 then
                    local n = player:getHandcardNum() - 4
                    room:askForDiscard(player, self:objectName(), n, n, false, false)
                end
            end
        end
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            if player:getHandcardNum() == 4 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            if player:getHandcardNum() < 4 then
                player:drawCards(4 - player:getHandcardNum(), self:objectName())
            elseif player:getHandcardNum() > 4 then
                local n = player:getHandcardNum() - 4
                room:askForDiscard(player, self:objectName(), n, n, false, false)
            end
        end
    end,
}

ny_10th_longhunvs = sgs.CreateViewAsSkill
{
    name = "ny_10th_longhun",
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if (to_select:getSuit() == sgs.Card_Heart) then
				return sgs.Self:isWounded()
			elseif (to_select:getSuit() == sgs.Card_Diamond) then
				return sgs.Slash_IsAvailable(sgs.Self)
				end
			else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
		end
		return false
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card
            if cards[1]:getSuit() == sgs.Card_Spade then
                card = sgs.Sanguosha:cloneCard("nullification")
            elseif cards[1]:getSuit() == sgs.Card_Club then
                card = sgs.Sanguosha:cloneCard("jink")
            elseif cards[1]:getSuit() == sgs.Card_Heart then
                card = sgs.Sanguosha:cloneCard("peach")
            elseif cards[1]:getSuit() == sgs.Card_Diamond then
                card = sgs.Sanguosha:cloneCard("fire_slash")
            end
			if card then
				card:addSubcard(cards[1])
				card:setSkillName("ny_10th_longhun")
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark("&ny_10th_longhun-Clear") >= 20 then return false end
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
        if player:getMark("&ny_10th_longhun-Clear") >= 20 then return false end
		return (pattern == "slash")
			or (pattern == "jink")
			or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
			or (pattern == "nullification")
	end,
	--[[enabled_at_nullification = function(self, player)
        if player:getMark("&ny_10th_longhun-Clear") >= 20 then return false end
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
	end,]]
}

ny_10th_longhun = sgs.CreateTriggerSkill{
	name = "ny_10th_longhun",
    events = {sgs.CardUsed,sgs.CardResponded},
    view_as_skill = ny_10th_longhunvs,
    on_trigger = function(self, event, player, data)
        local card = nil
        if event == sgs.CardUsed then 
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
		end
        if card:isKindOf("SkillCard") then return false end
        local room = player:getRoom()
        if table.contains(card:getSkillNames(),"ny_10th_longhun") then
			room:addPlayerMark(player,"&ny_10th_longhun-Clear");
    end
    end,
}

ny_10th_zhanjiang = sgs.CreateTriggerSkill{
    name = "ny_10th_zhanjiang",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local weapon = p:getWeapon()
            if weapon and weapon:objectName() == "QinggangSword" then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("get")) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:obtainCard(weapon)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhaoyun_thefirst:addSkill(ny_10th_jvejin)
ny_10th_zhaoyun_thefirst:addSkill(ny_10th_longhun)
ny_10th_zhaoyun_thefirst:addSkill(ny_10th_zhanjiang)

ny_10th_yuexiaoqiao = sgs.General(extension, "ny_10th_yuexiaoqiao", "wu", 3, false, false, false)

ny_10th_qiqin = sgs.CreateTriggerSkill{
    name = "ny_10th_qiqin",
    events = {sgs.GameStart,sgs.EventPhaseStart,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            if not player:isKongcheng() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                for _,card in sgs.qlist(player:getHandcards()) do
                    room:setCardTip(card:getId(), "ny_10th_qin")
                    card:setTag("ny_10th_qin", sgs.QVariant(true))
                    room:setPlayerMark(player, "ny_10th_qin_id"..card:getId(), 1)
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            get:deleteLater()
            for _,id in sgs.qlist(room:getDiscardPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getTag("ny_10th_qin"):toBool() then
                    get:addSubcard(card)
                end
            end
            if get:subcardsLength() <= 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:obtainCard(player, get, true)
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:getTag("ny_10th_qin"):toBool() then
                    room:setCardTip(card:getId(), "ny_10th_qin")
                    room:setPlayerMark(player, "ny_10th_qin_id"..card:getId(), 1)
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:getTag("ny_10th_qin"):toBool() then
                        room:ignoreCards(player, card)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_weiwan = sgs.CreateViewAsSkill
{
    name = "ny_10th_weiwan",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and (sgs.Self:getMark("ny_10th_qin_id"..to_select:getId()) > 0)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_10th_weiwanCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_weiwan"))
    end
}

ny_10th_weiwanCard = sgs.CreateSkillCard
{
    name = "ny_10th_weiwan",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
        and (not to_select:isAllNude())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:isDead() or effect.to:isDead() then return false end
        local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
        local suits = {}
        table.insert(suits, card:getSuitString())
        local all = sgs.QList2Table(effect.to:getCards("hej"))
        if #all <= 0 then return false end
        local cards = {}
        while(#all > 0) do
            local rand = all[math.random(1,#all)]
            table.insert(cards, rand)
            table.removeOne(all, rand)
        end
        local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
        get:deleteLater()
        for _,cc in ipairs(cards) do
            local suit = cc:getSuitString()
            if (not table.contains(suits, suit)) then
                table.insert(suits, suit)
                get:addSubcard(cc)
            end
        end
        if get:subcardsLength() <= 0 then return false end
        room:obtainCard(effect.from, get, false)
        if effect.to:isAlive() then
            local n = get:subcardsLength()
            if n == 1 then
                room:loseHp(effect.to, 1, true, effect.from, self:objectName())
            elseif n == 2 then
                local mark = string.format("&ny_10th_weiwan_nolimit+#%s-Clear", effect.from:objectName())
                room:setPlayerMark(effect.to, mark, 1)
            elseif n == 3 then
                local mark = string.format("&ny_10th_weiwan_limit+#%s-Clear", effect.from:objectName())
                room:setPlayerMark(effect.to, mark, 1)
            end
        end
    end
}

ny_10th_weiwan_buff = sgs.CreateTargetModSkill{
    name = "#ny_10th_weiwan_buff",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from and to and to:getMark("&ny_10th_weiwan_nolimit+#"..from:objectName().."-Clear") > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from and to and to:getMark("&ny_10th_weiwan_nolimit+#"..from:objectName().."-Clear") > 0 then return 1000 end
        return 0
    end,
}

ny_10th_weiwan_limit = sgs.CreateProhibitSkill{
    name = "#ny_10th_weiwan_limit",
    is_prohibited = function(self, from, to, card)
        return from and to and (to:getMark("&ny_10th_weiwan_limit+#"..from:objectName().."-Clear") > 0)
    end,
}

ny_10th_yuexiaoqiao:addSkill(ny_10th_qiqin)
ny_10th_yuexiaoqiao:addSkill(ny_10th_weiwan)
ny_10th_yuexiaoqiao:addSkill(ny_10th_weiwan_buff)
ny_10th_yuexiaoqiao:addSkill(ny_10th_weiwan_limit)
extension:insertRelatedSkills("ny_10th_weiwan","#ny_10th_weiwan_buff")
extension:insertRelatedSkills("ny_10th_weiwan","#ny_10th_weiwan_limit")

ny_10th_zhoubuyi = sgs.General(extension, "ny_10th_zhoubuyi", "wei", 3, true, false, false)

ny_tenth_silunVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_silun",
    n = 2,
    response_pattern = "@@ny_tenth_silun!",
    view_filter = function(self, selected, to_select)
        return #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_tenth_silunCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_silunCard = sgs.CreateSkillCard
{
    name = "ny_tenth_silun",
    mute = true,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets >= 1 then return false end
        local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
        if card:isKindOf("EquipCard") then
            local equip_index = card:getRealCard():toEquipCard():location()
            return to_select:hasEquipArea(equip_index) and (not to_select:getEquip(equip_index))
        end
        if card:isKindOf("DelayedTrick") then
            return to_select:hasJudgeArea() and (not to_select:containsTrick(card:objectName()))
        end
        return false
    end,
    feasible = function(self, targets, player)
        return #targets <= 1
    end,
    about_to_use = function(self,room,use)
        local player = use.from
        if use.to:isEmpty() then
            local choice = room:askForChoice(player, self:objectName(), "top+bottom")

            local log = sgs.LogMessage()
            log.type = "$ny_tenth_silun_drawpile"
            log.from = player
            log.arg = self:objectName()..":"..choice
            log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log)

            if choice == "top" then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(self:getSubcards(), nil, sgs.Player_DrawPile, reason)
                room:moveCardsAtomic(move, true)
            else
                room:moveCardsToEndOfDrawpile(player, self:getSubcards(), self:objectName(), true)
            end
        else
            local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
            local target = use.to:at(0)
            local place
            
            local log = sgs.LogMessage()
            log.type = "$ny_tenth_silun_field"
            log.from = player
            log.to:append(target)
            if card:isKindOf("EquipCard") then
                place = sgs.Player_PlaceEquip
                log.arg = "equip_area"
            else
                place = sgs.Player_PlaceDelayedTrick
                log.arg = "judge_area"
            end
            log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(self:getSubcards(), target, place, reason)
            room:moveCardsAtomic(move, true)

            if target:isAlive() and card:isKindOf("EquipCard") then
                if target:isChained() then room:setPlayerChained(target, false) end
                if target:isAlive() and (not target:faceUp()) then target:turnOver() end
            end
        end
        
    end 
}

ny_tenth_silun = sgs.CreateTriggerSkill{
    name = "ny_tenth_silun",
    events = {sgs.EventPhaseStart,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_silunVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_Start then return false end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(4, self:objectName())
            for i = 1, 4, 1 do
                if player:isAlive() and (not player:isNude()) then
                    room:askForUseCard(player, "@@ny_tenth_silun!", "@ny_tenth_silun:"..i)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_shijiVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_shiji",
    response_pattern = "@@ny_tenth_shiji",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local pattern = sgs.Self:property("ny_tenth_shiji_card"):toString()
            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("ny_tenth_shiji")
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_shiji = sgs.CreateTriggerSkill{
    name = "ny_tenth_shiji",
    events = {sgs.EventPhaseStart,sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_shijiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            room:setPlayerMark(player, "ny_tenth_shiji_failed-Clear", 1)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                local _data = sgs.QVariant()
                _data:setValue(player)
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("ny_tenth_shiji_failed-Clear") > 0 then return false end
                    if room:askForSkillInvoke(p, self:objectName(), _data, false) then
                        local all = {}
                        local can = {}
                        local cant = {}
                        for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                            local card = sgs.Sanguosha:getCard(id)
                            if card:isNDTrick() then
                                if (not table.contains(all,card:objectName())) then
                                    table.insert(all,card:objectName())
                                    local mark = string.format("ny_tenth_shiji_%s_lun", card:objectName())
                                    if p:getMark(mark) > 0 then
                                        table.insert(cant, card:objectName())
                                    else
                                        table.insert(can, card:objectName())
                                    end
                                end
                            end
                        end
                        if table.contains(can, "ex_nihilo") then
                            table.removeOne(can, "ex_nihilo")
                            table.insert(cant, "ex_nihilo")
                        end
                        table.insert(can, "cancel")
                        local pattern = room:askForChoice(p, self:objectName(), table.concat(can, "+"), _data, table.concat(cant, "+"))
                        if pattern ~= "cancel" then
                            local mark = string.format("ny_tenth_shiji_%s_lun", pattern)
                            room:setPlayerMark(p, mark, 1)

                            local log = sgs.LogMessage()
                            log.type = "#InvokeSkill"
                            log.from = p
                            log.arg = self:objectName()
                            room:sendLog(log)

                            local log2 = sgs.LogMessage()
                            log2.type = "$ny_tenth_shiji_declare"
                            log2.from = p
                            log2.arg = pattern
                            room:sendLog(log2)

                            room:broadcastSkillInvoke(self:objectName())
                            room:setPlayerProperty(player, "ny_tenth_shiji_card", sgs.QVariant(pattern))
                            room:askForUseCard(player, "@@ny_tenth_shiji", "@ny_tenth_shiji:"..pattern)
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

ny_tenth_shiji_limit = sgs.CreateProhibitSkill{
    name = "#ny_tenth_shiji_limit",
    is_prohibited = function(self, from, to, card)
        return (from and to and from:objectName() == to:objectName()) and (card and card:getSkillName() == "ny_tenth_shiji")
    end,
}


ny_10th_zhoubuyi:addSkill(ny_tenth_shiji)
ny_10th_zhoubuyi:addSkill(ny_tenth_shijiVS)
ny_10th_zhoubuyi:addSkill(ny_tenth_shiji_limit)
ny_10th_zhoubuyi:addSkill(ny_tenth_silun)
ny_10th_zhoubuyi:addSkill(ny_tenth_silunVS)
extension:insertRelatedSkills("ny_tenth_shiji", "#ny_tenth_shiji_limit")

ny_10th_tianshangyi = sgs.General(extension, "ny_10th_tianshangyi", "wei", 3, false, false, false)

local function ny_10th_xiaoren_judge(player, target)
    local room = player:getRoom()
    room:setPlayerFlag(player, "ny_10th_xiaoren_using")
    room:broadcastSkillInvoke("ny_10th_xiaoren")

    local judge = sgs.JudgeStruct()
    judge.pattern = "."
    judge.good = true
    judge.who = player
    judge.reason = "ny_10th_xiaoren"
    room:judge(judge)

    if judge.card:isRed() then
        room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
        room:setPlayerMark(player, "ny_10th_xiaoren_recover", 1)
        local luck = room:askForPlayerChosen(player, room:getAlivePlayers(), "ny_10th_xiaoren", "@ny_10th_xiaoren-recover", true, true)
        room:setPlayerMark(player, "ny_10th_xiaoren_recover", 0)
        if luck then
            if luck:isWounded() then
                room:recover(luck, sgs.RecoverStruct("ny_10th_xiaoren", player, 1))
            end
            if luck:isAlive() and (not luck:isWounded()) then
                luck:drawCards(1,"ny_10th_xiaoren")
            end
        end
    else
        local unlucks = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:isAdjacentTo(target) then
                unlucks:append(p)
            end
        end
        if unlucks:isEmpty() then
            room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
            return false
        end
        local unluck = room:askForPlayerChosen(player, unlucks, "ny_10th_xiaoren", "@ny_10th_xiaoren-damage:"..target:getGeneralName(), true, true)
        if unluck then
            room:damage(sgs.DamageStruct("ny_10th_xiaoren", player, unluck, 1, sgs.DamageStruct_Normal))
            if player:isDead() then 
                room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
                return false 
            end
            if player:hasFlag("ny_10th_xiaoren_dying") then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerFlag(p, "-ny_10th_xiaoren_dying")
                end
                room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
                return false
            end
            if room:askForSkillInvoke(player, "ny_10th_xiaoren") then
                ny_10th_xiaoren_judge(player, unluck)
            else
                room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
                return false
            end
        else
            room:setPlayerFlag(player, "-ny_10th_xiaoren_using")
            return false
        end
    end
end

ny_10th_xiaoren = sgs.CreateTriggerSkill{
    name = "ny_10th_xiaoren",
    events = {sgs.Damage,sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            if player:getMark("ny_10th_xiaoren-Clear") > 0 then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            local damage = data:toDamage()
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:setPlayerMark(player, "ny_10th_xiaoren-Clear", 1)
                ny_10th_xiaoren_judge(player, damage.to)
            end
        end
        if event == sgs.EnterDying then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("ny_10th_xiaoren_using") then
                    for _,pl in sgs.qlist(room:getAlivePlayers()) do
                        room:setPlayerFlag(pl, "ny_10th_xiaoren_dying")
                    end
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

ny_tenth_posuoVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_posuo",
    response_pattern = "@@ny_tenth_posuo",
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_tenth_posuo_using") then return false end
        local mark = string.format("ny_tenth_posuo_%s-PlayClear", to_select:getSuitString())
        return sgs.Self:getMark(mark) == 0 and #selected < 1
        and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("ny_tenth_posuo_using") then
            local pattern = sgs.Self:property("ny_tenth_posuo_card"):toString()
            local cc = ny_tenth_posuoCard:clone()
            cc:setUserString(pattern)
            local card = sgs.Sanguosha:getCard(sgs.Self:getMark("ny_tenth_posuo_id"))
            cc:addSubcard(card)
            return cc
        else
            if #cards == 1 then
                local card = ny_tenth_posuo_selectCard:clone()
                card:addSubcard(cards[1])
                return card
            end
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("ny_tenth_posuo_disable-PlayClear") == 0
    end,
}

ny_tenth_posuo_selectCard = sgs.CreateSkillCard
{
    name = "ny_tenth_posuo_select",
    target_fixed = true,
    will_throw = false,
    about_to_use = function(self,room,use)
        local player = use.from
        local id = self:getSubcards():at(0)
        room:setPlayerMark(player, "ny_tenth_posuo_id", id)

        local card = sgs.Sanguosha:getCard(id)
        local key = string.format("ny_tenth_posuo_%s", card:getSuitString())
        local all = room:getTag(key):toString():split("+")
        if (not all) or (#all <= 0) then
            local suits = {"heart", "diamond", "club", "spade"}
            for _,suit in ipairs(suits) do
                local nkey = string.format("ny_tenth_posuo_%s", suit)
                local patterns = room:getTag(nkey):toString():split("+")
                if (not patterns) or (#patterns <= 0) then
                    patterns = {}
                    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                        local cc = sgs.Sanguosha:getCard(id)
                        if cc:isDamageCard() and cc:getSuitString() == suit then
                            if (not table.contains(patterns, cc:objectName())) then
                                table.insert(patterns, cc:objectName())
                            end
                        end
                    end
                    room:setTag(nkey, sgs.QVariant(table.concat(patterns, "+")))
                end
            end
            all = room:getTag(key):toString():split("+")
        end

        local can = {}
        local cant = {}

        for _,pattern in ipairs(all) do
            local newcard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
            newcard:setSkillName("ny_tenth_posuo")
            newcard:addSubcard(card)
            newcard:deleteLater()
            if newcard:isAvailable(player) then
                table.insert(can, pattern)
            else
                table.insert(cant, pattern)
            end
        end
        if #can <= 0 then
            room:askForChoice(player, "ny_tenth_posuo", "cancel+failed")
            return false
        end
        table.insert(can, "cancel")
        local pattern = room:askForChoice(player, "ny_tenth_posuo", table.concat(can, "+"), sgs.QVariant(), table.concat(cant, "+"))
        if pattern == "cancel" then return false end
        room:setPlayerFlag(player, "ny_tenth_posuo_using")
        room:setPlayerProperty(player, "ny_tenth_posuo_card", sgs.QVariant(pattern))
        room:askForUseCard(player, "@@ny_tenth_posuo", "@ny_tenth_posuo:"..pattern)
        room:setPlayerFlag(player, "-ny_tenth_posuo_using")
    end
}

ny_tenth_posuoCard = sgs.CreateSkillCard
{
    name = "ny_tenth_posuo",
    will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select,player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_tenth_posuo")
		card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_tenth_posuo")
		card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_tenth_posuo")
		card:deleteLater()

        local suit = sgs.Sanguosha:getCard(self:getSubcards():at(0)):getSuitString()
        local mark = string.format("ny_tenth_posuo_%s-PlayClear", suit)
        room:setPlayerMark(player, mark, 1)

        local names = player:getMarkNames()
        mark = nil
        for _,p in ipairs(names) do
            if (string.find(p,"&ny_tenth_posuo")) and (player:getMark(p) > 0) then
                mark = p
                break
            end
        end
        if mark and player:getMark(mark) > 0 then 
            if string.find(mark,suit.."_char") then return false end
            room:setPlayerMark(player, mark, 0)
            mark = string.sub(mark,1,-11)
        else
            mark = "&ny_tenth_posuo"
        end
        mark = mark.."+"..suit.."_char-PlayClear"
        room:setPlayerMark(player, mark, 1)

		return card
	end,
}

ny_tenth_posuo = sgs.CreateTriggerSkill{
    name = "ny_tenth_posuo",
    events = {sgs.Damage,sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_posuoVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local suits = {"heart", "diamond", "club", "spade"}
            for _,suit in ipairs(suits) do
                local key = string.format("ny_tenth_posuo_%s", suit)
                local patterns = room:getTag(key):toString():split("+")
                if (not patterns) or (#patterns <= 0) then
                    patterns = {}
                    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isDamageCard() and card:getSuitString() == suit then
                            if (not table.contains(patterns, card:objectName())) then
                                table.insert(patterns, card:objectName())
                            end
                        end
                    end
                    room:setTag(key, sgs.QVariant(table.concat(patterns, "+")))
                end
            end
        end
        if event == sgs.Damage then
            if player:getPhase() ~= sgs.Player_Play then return false end
            room:setPlayerMark(player, "ny_tenth_posuo_disable-PlayClear", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}


ny_10th_tianshangyi:addSkill(ny_tenth_posuo)
ny_10th_tianshangyi:addSkill(ny_tenth_posuoVS)
ny_10th_tianshangyi:addSkill(ny_10th_xiaoren)

ny_10th_xingyuanshao = sgs.General(extension, "ny_10th_xingyuanshao$", "qun", 4, true, false, false)

ny_10th_xiaoyan = sgs.CreateTriggerSkill{
    name = "ny_10th_xiaoyan",
    events = {sgs.GameStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isAlive() then
                room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Fire))
                room:getThread():delay()
            end
        end
        local _data = sgs.QVariant()
        _data:setValue(player)
        room:setTag("ny_10th_xiaoyan", _data)
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isAlive() and player:isAlive() then
                room:getThread():delay()
                local give = room:askForExchange(p, self:objectName(), 1, 1, true, "@ny_10th_xiaoyan:"..player:getGeneralName(), true)
                if give then
                    room:obtainCard(player, give, false)
                    if p:isAlive() then
                        room:recover(p, sgs.RecoverStruct("ny_10th_xiaoyan", player, 1))
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_zongshi = sgs.CreateViewAsSkill
{
    name = "ny_tenth_zongshi",
    n = 99,
    response_pattern = "@@ny_tenth_zongshi",
    view_filter = function(self, selected, to_select)
        if #selected >= 1 then return false end
        if (not to_select:isKindOf("BasicCard")) and (not to_select:isNDTrick()) then return false end
        if (not to_select:isAvailable(sgs.Self)) then return false end
        for _,card in sgs.qlist(sgs.Self:getHandcards()) do
            if card:getEffectiveId() ~= to_select:getEffectiveId() 
            and card:getSuit() == to_select:getSuit() then
                return true
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_tenth_zongshiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return player:getHandcardNum()>1
    end
}

ny_tenth_zongshiCard = sgs.CreateSkillCard
{
    name = "ny_tenth_zongshi",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    target_fixed = true,
	feasible = function(self, targets,player)
        local show_id = self:getSubcards():at(0)
        local show_card = sgs.Sanguosha:getCard(show_id)

		local card = sgs.Sanguosha:cloneCard(show_card:objectName())
        for _,hand in sgs.qlist(player:getHandcards()) do
            if hand:getSuit() == show_card:getSuit()
            and hand:getEffectiveId() ~= show_id then
                card:addSubcard(hand)
            end
        end
		card:setSkillName("ny_tenth_zongshi")
        card:deleteLater()

        return card:subcardsLength()>0 and card:isAvailable(player)
	end,
    about_to_use = function(self,room,use)
        local show_id = self:getSubcards():at(0)
        local show_card = sgs.Sanguosha:getCard(show_id)

        local player = use.from

        local card = sgs.Sanguosha:cloneCard(show_card:objectName())
        for _,hand in sgs.qlist(player:getHandcards()) do
            if hand:getSuit() == show_card:getSuit()
            and hand:getEffectiveId() ~= show_card:getEffectiveId() then
                card:addSubcard(hand)
            end
        end
		card:setSkillName("_ny_tenth_zongshi")
        local _data = sgs.QVariant()
        _data:setValue(card)
        player:setTag("ny_tenth_zongshi", _data)

        local all_targets = room:getCardTargets(player, card)
        local prompt = string.format("@ny_tenth_zongshi-targets:%s::%s", card:objectName(), card:subcardsLength())
        local targets = room:askForPlayersChosen(player, all_targets,self:objectName(), 0, card:subcardsLength(), prompt)

        if targets:length() > 0 then
            local skill_log = sgs.LogMessage()
            skill_log.type = "#InvokeSkill"
            skill_log.from = player
            skill_log.arg = self:objectName()
            room:sendLog(skill_log)
            room:broadcastSkillInvoke(self:objectName())
    
            room:showCard(player, show_id)
            use.card = card
            use.to = targets
            room:addPlayerHistory(player, card:getClassName(), 1)
            self:cardOnUse(room, use)
        end
        card:deleteLater()
    end
}

ny_tenth_zongshi_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_zongshi_buff",
    pattern = ".",
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_zongshi" then return 1000 end
        return 0
    end,
}

ny_10th_jiaowang = sgs.CreateTriggerSkill{
    name = "ny_10th_jiaowang",
    events = {sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("ny_10th_jiaowang_lun") > 0 then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:loseHp(player, 1, true, player, self:objectName())
        if player:isDead() then return false end
        room:getThread():delay()
        local skill = sgs.Sanguosha:getTriggerSkill("ny_10th_xiaoyan")
        skill:trigger(sgs.GameStart, room, player, data)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jiaowang_count = sgs.CreateTriggerSkill{
    name = "#ny_10th_jiaowang_count",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "ny_10th_jiaowang_lun", 1)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_aoshi = sgs.CreateTriggerSkill{
    name = "ny_10th_aoshi$",
    events = {sgs.GameStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,pl in sgs.qlist(room:getAlivePlayers()) do
            room:attachSkillToPlayer(pl, "ny_10th_aoshi_give")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasLordSkill(self:objectName())
    end,
}

ny_10th_aoshi_give = sgs.CreateViewAsSkill
{
    name = "ny_10th_aoshi_give&",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_10th_aoshi_giveCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        if player:getKingdom() == "qun" then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasLordSkill("ny_10th_aoshi") then
					return not player:hasUsed("#ny_10th_aoshi_give")
    end
			end
		end
    end
}

ny_10th_aoshi_giveCard = sgs.CreateSkillCard
{
    name = "ny_10th_aoshi_give",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
        and to_select:hasLordSkill("ny_10th_aoshi")
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:broadcastSkillInvoke("ny_10th_aoshi")
        local player = effect.to
        room:obtainCard(player, self, false)
        if effect.to:isAlive() then
            room:askForUseCard(player, "@@ny_tenth_zongshi", "@ny_tenth_zongshi")
        end
    end
}

ny_10th_xingyuanshao:addSkill(ny_10th_xiaoyan)
ny_10th_xingyuanshao:addSkill(ny_tenth_zongshi)
--ny_10th_xingyuanshao:addSkill(ny_tenth_zongshi_buff)
ny_10th_xingyuanshao:addSkill(ny_10th_jiaowang)
ny_10th_xingyuanshao:addSkill(ny_10th_jiaowang_count)
ny_10th_xingyuanshao:addSkill(ny_10th_aoshi)
--extension:insertRelatedSkills("ny_tenth_zongshi", "#ny_tenth_zongshi_buff")
extension:insertRelatedSkills("ny_10th_jiaowang", "#ny_10th_jiaowang_count")

ny_10th_bailingyun = sgs.General(extension, "ny_10th_bailingyun", "wei", 3, false, false, false)

ny_tenth_linghuiVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_linghui",
    response_pattern = "@@ny_tenth_linghui",
    expand_pile = "#ny_tenth_linghui",
    n = 1,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("#ny_tenth_linghui"):contains(to_select:getEffectiveId())
        and to_select:isAvailable(sgs.Self)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = ny_tenth_linghuiCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_linghuiCard = sgs.CreateSkillCard
{
    name = "ny_tenth_linghui",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select,player)
        local card = sgs.Sanguosha:getCard(self:getEffectiveId())

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
        local card = sgs.Sanguosha:getCard(self:getEffectiveId())

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 and (not card:isKindOf("EquipCard")) then
			return false
		end
		return card and card:targetsFeasible(qtargets, player)
	end,
    about_to_use = function(self,room,use)
        use.card = sgs.Sanguosha:getCard(self:getEffectiveId())
		self:cardOnUse(room,use)
    end,
}

ny_tenth_linghui = sgs.CreateTriggerSkill{
    name = "ny_tenth_linghui",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_linghuiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		for _,pl in sgs.qlist(room:getAllPlayers()) do
			if pl:isAlive() and pl:hasSkill(self)
			and (player==pl or player:getMark("ny_tenth_linghui_dying-Clear") > 0)
			and pl:askForSkillInvoke(self) then
				pl:peiyin(self)
            local card_ids = room:getNCards(3)
                    room:notifyMoveToPile(pl, card_ids, "ny_tenth_linghui", sgs.Player_DrawPile, true)
                    local card = room:askForUseCard(pl, "@@ny_tenth_linghui", "@ny_tenth_linghui")
                    room:notifyMoveToPile(pl, card_ids, "ny_tenth_linghui", sgs.Player_DrawPile, false)
        
                    if card then
					local useid = card:getEffectiveId()
                        card_ids:removeOne(useid)
                        if pl:isAlive() then
                            local real = {}
                            for _,id in sgs.qlist(card_ids) do
                                if room:getCardPlace(id) == sgs.Player_DrawPile then
                                    table.insert(real, id)
                                end
                            end
                            if #real > 0 then
							useid = real[math.random(1, #real)]
							card_ids:removeOne(useid)
							room:obtainCard(pl, useid, false)
                        end
                    end
                end
				room:returnToTopDrawPile(card_ids)
            end
        end 
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Finish
    end,
}

ny_tenth_linghui_dying = sgs.CreateTriggerSkill{
    name = "#ny_tenth_linghui_dying",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, "ny_tenth_linghui_dying-Clear", 1)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_xiace = sgs.CreateTriggerSkill{
    name = "ny_10th_xiace",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            if player:getMark("ny_10th_xiace_damage-Clear") > 0 then return false end
            if (not player:isWounded()) then return false end--没掉血就不触发了，尽管原版可以
            room:setPlayerMark(player, "ny_10th_xiace_damage-Clear", 1)
            if not room:askForDiscard(player, self:objectName(), 1, 1,
            true, true, "@ny_10th_xiace-discard", ".", "ny_10th_xiace") then
                room:setPlayerMark(player, "ny_10th_xiace_damage-Clear", 0)
                return false
            end
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct("ny_10th_xiace", player, 1))
            end
        end
        if event == sgs.Damaged then
            if player:getMark("ny_10th_xiace_damaged-Clear") > 0 then return false end
            local targets = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_xiace-failure", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "ny_10th_xiace_damaged-Clear", 1)
                if target:getMark("&ny_10th_xiace") > 0 then return false end
                room:addPlayerMark(target, "&ny_10th_xiace", 1)
                for _,sk in sgs.list(target:getSkillList())do
					if sk:isAttachedLordSkill() then continue end
                    if sk:getFrequency() == sgs.Skill_Compulsory then continue end
					room:addPlayerMark(target,"Qingcheng"..sk:objectName())
				end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ny_10th_xiace_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_xiace_clear",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,target in sgs.qlist(room:getAlivePlayers()) do
            if target:getMark("&ny_10th_xiace") > 0 then
                room:removePlayerMark(target, "&ny_10th_xiace", 1)
                for _,sk in sgs.list(target:getSkillList())do
                    if sk:isAttachedLordSkill() then continue end
                    if sk:getFrequency() == sgs.Skill_Compulsory then continue end
                    room:removePlayerMark(target,"Qingcheng"..sk:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_NotActive
    end,
}

ny_10th_yuxin = sgs.CreateTriggerSkill{
    name = "ny_10th_yuxin",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@ny_10th_yuxin_mark",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        for _,pl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if pl:getMark("@ny_10th_yuxin_mark") > 0 then
                local n = 1
                if pl:objectName() ~= player:objectName() then n = pl:getHp() end
                local prompt = string.format("dying:%s::%s:", player:getGeneralName(), n)

                local _data = sgs.QVariant()
                _data:setValue(player)
                room:setTag("ny_10th_yuxin", _data)

                if room:askForSkillInvoke(pl, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(pl, "@ny_10th_yuxin_mark", 0)
                    room:recover(player, sgs.RecoverStruct(self:objectName(), pl, n - player:getHp()))
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_bailingyun:addSkill(ny_tenth_linghui)
ny_10th_bailingyun:addSkill(ny_tenth_linghuiVS)
ny_10th_bailingyun:addSkill(ny_tenth_linghui_dying)
ny_10th_bailingyun:addSkill(ny_10th_xiace)
ny_10th_bailingyun:addSkill(ny_10th_xiace_clear)
ny_10th_bailingyun:addSkill(ny_10th_yuxin)
extension:insertRelatedSkills("ny_tenth_linghui", "#ny_tenth_linghui_dying")
extension:insertRelatedSkills("ny_10th_xiace", "#ny_10th_xiace_clear")

ny_10th_ganfurenmifuren = sgs.General(extension, "ny_10th_ganfurenmifuren", "shu", 3, false, false, false)

ny_tenth_chanjuanVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_chanjuan",
    response_pattern = "@@ny_tenth_chanjuan",
    view_as = function(self)
        return ny_tenth_chanjuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,

}

ny_tenth_chanjuanCard = sgs.CreateSkillCard
{
    name = "ny_tenth_chanjuan",
    handling_method = sgs.Card_MethodUse,
    mute = true,
    filter = function(self, targets, to_select, player) 
		local pattern = player:property("ny_tenth_chanjuan_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_chanjuan")
		card:deleteLater()
		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local pattern = sgs.Self:property("ny_tenth_chanjuan_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_chanjuan")
		card:deleteLater()
		return card:targetFixed()
	end,
	feasible = function(self, targets,player)	
		local pattern = player:property("ny_tenth_chanjuan_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_chanjuan")
		card:deleteLater()
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local pattern = player:property("ny_tenth_chanjuan_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_chanjuan")
		card:deleteLater()

        local target = player:getTag("ny_tenth_chanjuan"):toPlayer()
        if target then
            local data = sgs.QVariant()
            data:setValue(target)
            card:setTag("ny_tenth_chanjuan", data)
        end
        room:setCardFlag(card, "ny_tenth_chanjuan")

        local mark = string.format("ny_tenth_chanjuan_%s",card:objectName())
        if card:isKindOf("Slash") then mark = string.format("ny_tenth_chanjuan_%s","Slash") end
        room:addPlayerMark(player, mark, 1)

        room:setCardFlag(card, "RemoveFromHistory")

		return card	
	end	
}

ny_tenth_chanjuan = sgs.CreateTriggerSkill{
    name = "ny_tenth_chanjuan",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_chanjuanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()

            if use.to:length() == 1 and use.from:objectName() == player:objectName()
            and player:isAlive() and use.m_isHandcard 
            and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
                local mark = string.format("ny_tenth_chanjuan_%s",use.card:objectName())
                if use.card:isKindOf("Slash") then mark = string.format("ny_tenth_chanjuan_%s","Slash") end
                if player:getMark(mark) < 2 then
                    player:removeTag("ny_tenth_chanjuan")
                    local value = sgs.QVariant()
                    value:setValue(use.to:at(0))
                    player:setTag("ny_tenth_chanjuan", value)

                    room:setPlayerProperty(player, "ny_tenth_chanjuan_card", sgs.QVariant(use.card:objectName()))
                    room:askForUseCard(player, "@@ny_tenth_chanjuan", "@ny_tenth_chanjuan:"..use.card:objectName())
                end
            end

            if use.from:objectName() == player:objectName() and player:isAlive()
            and use.card:hasFlag("ny_tenth_chanjuan") then
                local target = use.card:getTag("ny_tenth_chanjuan"):toPlayer()
                use.card:removeTag("ny_tenth_chanjuan")
                if target and use.to:contains(target) and use.to:length() == 1 then
                    player:drawCards(1, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_chanjuan_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_chanjuan_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_chanjuan" then return 1000 end
        return 0
    end,
}

ny_10th_xunbie = sgs.CreateTriggerSkill{
    name = "ny_10th_xunbie",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@ny_10th_xunbie_mark",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("@ny_10th_xunbie_mark") == 0 then return false end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "@ny_10th_xunbie_mark", 0)

            local names = {}
            for _,general in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
                if general:getKingdom() == "shu" then
                    local name = general:objectName()
                    if name == "ny_10th_ganfurenmifuren" then continue end
                    local translation = sgs.Sanguosha:translate(name)
                    if string.find(translation, "甘夫人")
                    or string.find(translation, "糜夫人") then
                        local can = true
                        for _,p in sgs.qlist(room:getAllPlayers(true)) do
                            if p:getGeneralName() == name then 
                                can = false
                                break
                            end
                        end
                        if can then
                            table.insert(names, name)
                        end
                    end
                end
            end
            if #names > 0 then
                local general = room:askForGeneral(player, table.concat(names, "+"))
                room:changeHero(player, general, false)
            end


            room:setPlayerMark(player, "&ny_10th_xunbie-Clear", 1)
            room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1 - player:getHp()))
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_xunbie_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_xunbie_buff",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local log = sgs.LogMessage()
        log.type = "$ny_10th_xunbie_damage"
        log.from = player
        log.arg = "ny_10th_xunbie"
        room:sendLog(log)
        room:broadcastSkillInvoke("ny_10th_xunbie")
        return true
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&ny_10th_xunbie-Clear") > 0
    end,
}

ny_10th_ganfurenmifuren:addSkill(ny_tenth_chanjuan)
ny_10th_ganfurenmifuren:addSkill(ny_tenth_chanjuanVS)
ny_10th_ganfurenmifuren:addSkill(ny_tenth_chanjuan_buff)
ny_10th_ganfurenmifuren:addSkill(ny_10th_xunbie)
ny_10th_ganfurenmifuren:addSkill(ny_10th_xunbie_buff)
extension:insertRelatedSkills("ny_tenth_chanjuan","#ny_tenth_chanjuan_buff")
extension:insertRelatedSkills("ny_10th_xunbie","#ny_10th_xunbie_buff")

ny_10th_shenxuchu = sgs.General(extension, "ny_10th_shenxuchu", "god", 5, true, true, true)

ny_10th_zhuangpoVS = sgs.CreateViewAsSkill
{
    name = "ny_10th_zhuangpo",
    n = 99,
    view_filter = function(self, selected, to_select)
        if #selected >= 1 then return false end
        if to_select:isKindOf("Slash") then return true end
        local to_translate = ":"..to_select:objectName()
        local translation = sgs.Sanguosha:translate(to_translate)
        return string.find(translation, "【杀】")
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = ny_10th_zhuangpoCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

ny_10th_zhuangpoCard = sgs.CreateSkillCard
{
    name = "ny_10th_zhuangpo",
    handling_method = sgs.Card_MethodUse,
    mute = true,
    filter = function(self, targets, to_select, player) 
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhuangpo")
		card:deleteLater()
		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhuangpo")
		card:deleteLater()
		return card:targetFixed()
	end,
	feasible = function(self, targets,player)	
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhuangpo")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		card:deleteLater()
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
		card:setSkillName("ny_10th_zhuangpo")

        room:setCardFlag(card, "ny_10th_zhuangpo")
        room:setCardFlag(card, "ny_10th_zhuangpo_"..player:objectName())
		card:deleteLater()

		return card	
	end	
}

ny_10th_zhuangpo = sgs.CreateTriggerSkill{
    name = "ny_10th_zhuangpo",
    events = {sgs.TargetConfirmed,sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_10th_zhuangpoVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from == player
            and use.card:isKindOf("Duel") and use.card:hasFlag("ny_10th_zhuangpo") then
                for _,to in sgs.qlist(use.to) do
                    if player:getMark("&ny_10th_shenxuchu_qing") > 0 and (not to:isNude()) 
                    and player:isAlive() and to:isAlive() then
                        local _data = sgs.QVariant()
                        _data:setValue(to)
                        player:setTag("ny_10th_zhuangpo", _data)

                        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("remove:"..to:getGeneralName())) then
                            local num = {}
                            local max = math.min(player:getMark("&ny_10th_shenxuchu_qing"), to:getCards("he"):length())
                            for i = 1, max, 1 do
                                table.insert(num, tostring(i))
                            end
                            local discard = room:askForChoice(player, self:objectName(), table.concat(num, "+"))
                            local n = tonumber(discard)
                            room:removePlayerMark(player, "&ny_10th_shenxuchu_qing", n)
                            room:askForDiscard(to, self:objectName(), n, n, false, true)
                        end
                    end
                end
            end
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card:hasFlag("ny_10th_zhuangpo_"..player:objectName())
            and damage.to:getMark("&ny_10th_shenxuchu_qing") > 0 then
                local log = sgs.LogMessage()
                log.type = "$ny_10th_zhuangpo_damage"
                log.from = player
                log.to:append(damage.to)
                log.arg = self:objectName()
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

ny_10th_zhengqing_count = sgs.CreateTriggerSkill{
    name = "#ny_10th_zhengqing_count",
    events = {sgs.Damage,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            room:addPlayerMark(player, "ny_10th_zhengqing_damage_oneturn-Clear", damage.damage)
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("ny_10th_zhengqing_damage_oneturn-Clear") > p:getMark("ny_10th_zhengqing_max_lun") then
                        room:setPlayerMark(p, "ny_10th_zhengqing_max_lun", p:getMark("ny_10th_zhengqing_damage_oneturn-Clear"))
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_zhengqing = sgs.CreateTriggerSkill{
    name = "ny_10th_zhengqing",
    events = {sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local max = 0
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("ny_10th_zhengqing_max_lun") > max then
                max = p:getMark("ny_10th_zhengqing_max_lun")
            end
            room:setPlayerMark(p, "&ny_10th_shenxuchu_qing", 0)
        end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        if player:getMark("ny_10th_zhengqing_max_lun") >= player:getMark("ny_10th_zhengqing_max_history") then
            room:setPlayerMark(player, "ny_10th_zhengqing_max_history", player:getMark("ny_10th_zhengqing_max_lun"))
        end
        if player:getMark("ny_10th_zhengqing_max_lun") == max
        and player:getMark("ny_10th_zhengqing_max_lun") >= player:getMark("ny_10th_zhengqing_max_history") then
            room:addPlayerMark(player, "&ny_10th_shenxuchu_qing", max)
            player:drawCards(math.min(5,max), self:objectName())
        else
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("ny_10th_zhengqing_max_lun") == max then
                    room:addPlayerMark(p, "&ny_10th_shenxuchu_qing", max)
                    player:drawCards(1, self:objectName())
                    p:drawCards(1, self:objectName())
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_shenxuchu:addSkill(ny_10th_zhengqing)
ny_10th_shenxuchu:addSkill(ny_10th_zhengqing_count)
ny_10th_shenxuchu:addSkill(ny_10th_zhuangpo)
ny_10th_shenxuchu:addSkill(ny_10th_zhuangpoVS)
extension:insertRelatedSkills("ny_10th_zhengqing", "#ny_10th_zhengqing_count")

ny_10th_zhoushan = sgs.General(extension, "ny_10th_zhoushan", "wu", 4, true, false, false)

ny_tenth_miyunVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_miyun",
    response_pattern = "@@ny_tenth_miyun!",
    frequency = sgs.Skill_Compulsory,
    n = 99,
    view_filter = function(self, selected, to_select)
        if not sgs.Self:getHandcards():contains(to_select) then return false end
        local find = false
        for _,card in ipairs(selected) do
            if card:hasFlag("ny_tenth_miyun_an") then
                find = true
                break
            end
        end
        if (not find) then 
            return to_select:hasFlag("ny_tenth_miyun_an")
        else
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cc = ny_tenth_miyunCard:clone()
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

ny_tenth_miyunCard = sgs.CreateSkillCard
{
    name = "ny_tenth_miyun",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local player = effect.from
        for _,id in sgs.qlist(self:getSubcards()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:hasFlag("ny_tenth_miyun_an") then
                room:setCardFlag(card, "-ny_tenth_miyun_an")
            end
        end
        room:obtainCard(effect.to, self, true)
        if player:isAlive() and player:getHandcardNum() < player:getMaxHp() then
            player:drawCards(player:getMaxHp() - player:getHandcardNum(), self:objectName())
        end
    end
}

ny_tenth_miyun = sgs.CreateTriggerSkill{
    name = "ny_tenth_miyun",
    events = {sgs.RoundStart,sgs.RoundEnd,sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = ny_tenth_miyunVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if (not p:isNude()) then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_tenth_miyun-get", false, true)
            local card = room:askForCardChosen(player, target, "he", self:objectName())
            room:showCard(target, card)
            room:obtainCard(player, card, true)
            if room:getCardOwner(card) == player
            and player:isAlive() then
                room:setCardFlag(card, "ny_tenth_miyun_an")
                room:setCardTip(card, "ny_tenth_miyun_an")
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand) then
                for _,id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:hasFlag("ny_tenth_miyun_an") then
                        room:setCardFlag(card, "-ny_tenth_miyun_an")
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        room:loseHp(player, 1, true, player, self:objectName())
                    end
                end
            end
        end
        if event == sgs.RoundEnd then
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:hasFlag("ny_tenth_miyun_an") then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:askForUseCard(player, "@@ny_tenth_miyun!", "@ny_tenth_miyun-give")
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_10th_danyin = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_danyin",
    view_as = function(self)
        local pattern
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            pattern = "slash"
        else
            pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if string.find(pattern, "slash") or string.find(pattern, "Slash") then
                pattern = "slash"
            end
            if string.find(pattern, "jink") or string.find(pattern, "Jink") then
                pattern = "jink"
            end
        end
        if pattern ~= "" then
            local card = ny_10th_danyinCard:clone()
            card:setUserString(pattern)
            return card
        end
    end,
    enabled_at_play = function(self, player)
        local find = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("ny_tenth_miyun_an") then
                find = true
                break
            end
        end
        if (not find) then return false end

        if player:getMark("ny_10th_danyin-Clear") > 0 then return false end

        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        local find = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("ny_tenth_miyun_an") then
                find = true
                break
            end
        end
        if (not find) then return false end

        if player:getMark("ny_10th_danyin-Clear") > 0 then return false end

        if string.find(pattern, "slash") or string.find(pattern, "Slash") then
            return true
        end
        if string.find(pattern, "jink") or string.find(pattern, "Jink") then
            return true
        end
    end,
}

ny_10th_danyinCard = sgs.CreateSkillCard
{
    name = "ny_10th_danyin",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local pattern = self:getUserString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
        card:deleteLater()

        if card:targetFixed() then return false end

        return card:targetFilter(qtargets, to_select, player)
    end,
    feasible = function(self, targets, player)
        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(user_string, sgs.Card_SuitToBeDecided, -1)
        use_card:setSkillName(self:objectName())
        use_card:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end

        if use_card:canRecast() and #targets == 0 then
			return false
		end

        return use_card:targetsFeasible(qtargets, player) 
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local player = source
        local room = source:getRoom()

        for _,cc in sgs.qlist(source:getHandcards()) do
            if cc:hasFlag("ny_tenth_miyun_an") then
                room:showCard(player, cc:getEffectiveId())
            end
        end

        local pattern = self:getUserString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())

        room:setPlayerMark(player, "ny_10th_danyin-Clear", 1)
		card:deleteLater()
        return card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local player = source

        for _,cc in sgs.qlist(source:getHandcards()) do
            if cc:hasFlag("ny_tenth_miyun_an") then
                room:showCard(player, cc:getEffectiveId())
            end
        end

        local pattern = self:getUserString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())

        room:setPlayerMark(player, "ny_10th_danyin-Clear", 1)
		card:deleteLater()
        return card
    end,
}

ny_10th_danyin_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_danyin_buff",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if player:getMark("ny_10th_danyin-Clear") ~= 1 then return false end
        if use.to:contains(player) and use.from and use.from:isAlive() then
            room:sendCompulsoryTriggerLog(player, "ny_10th_danyin", true, true)
            room:addPlayerMark(player, "ny_10th_danyin-Clear", 1)
            if (not player:isNude()) then
                local card = room:askForCardChosen(use.from, player, "he", "ny_10th_danyin")
                room:throwCard(card, player, use.from)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_zhoushan:addSkill(ny_tenth_miyun)
ny_10th_zhoushan:addSkill(ny_tenth_miyunVS)
ny_10th_zhoushan:addSkill(ny_10th_danyin)
ny_10th_zhoushan:addSkill(ny_10th_danyin_buff)
extension:insertRelatedSkills("ny_10th_danyin", "#ny_10th_danyin_buff")

ny_10th_liuli = sgs.General(extension, "ny_10th_liuli", "shu", 3, true, false, false)

ny_tenth_dehuaVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_dehua",
    response_pattern = "@@ny_tenth_dehua",
    frequency = sgs.Skill_Compulsory,
    view_as = function(self)
        return ny_tenth_dehuaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_tenth_dehuaCard = sgs.CreateSkillCard
{
    name = "ny_tenth_dehua",
    handling_method = sgs.Card_MethodUse,
    mute = true,
    filter = function(self, targets, to_select, player) 
		local pattern = player:property("ny_tenth_dehua_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_dehua")
		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
    target_fixed = function(self)		
		local pattern = sgs.Self:property("ny_tenth_dehua_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("ny_tenth_dehua")
		return card:targetFixed()
	end,
	feasible = function(self, targets,player)	
		local pattern = player:property("ny_tenth_dehua_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("ny_tenth_dehua")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets, player)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local pattern = player:property("ny_tenth_dehua_card"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("_ny_tenth_dehua")

		return card	
	end
}

ny_tenth_dehua = sgs.CreateTriggerSkill{
    name = "ny_tenth_dehua",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = ny_tenth_dehuaVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            local finds = {"slash"}
            local able = {}
            local unable = player:getTag("ny_tenth_dehua_used"):toString():split("+")
            if (not unable) or (#unable <= 0) then unable = {} end
            if (#unable > 0) and (table.contains(unable, "slash")) then
            else table.insert(able, "slash") end
            local slashs = {}
            for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                local card = sgs.Sanguosha:getCard(id)
                local name = card:objectName()
                if card:isKindOf("Slash") then
                    if (not table.contains(slashs, card:objectName())) then
                        table.insert(slashs, card:objectName())
                    end
                else
                    if (card:isKindOf("BasicCard") or card:isNDTrick())
                    and card:isDamageCard() then
                        if (not table.contains(finds, card:objectName())) then
                            table.insert(finds, card:objectName())
                            if (not table.contains(unable, card:objectName())) then
                                table.insert(able, card:objectName())
                            end
                        end
                    end
                end
            end

            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local choice = room:askForChoice(player, self:objectName(), table.concat(able, "+"), sgs.QVariant(), table.concat(unable, "+"))
            table.insert(unable, choice)
            if choice == "slash" then 
                choice = room:askForChoice(player, "ny_tenth_dehua_slash", table.concat(slashs, "+"))
            end
            room:setPlayerProperty(player, "ny_tenth_dehua_card", sgs.QVariant(choice))
            room:askForUseCard(player, "@@ny_tenth_dehua", "@ny_tenth_dehua:"..choice)

            if player:isAlive() then
                local temp = sgs.Sanguosha:cloneCard(choice, sgs.Card_SuitToBeDecided, -1)
                temp:deleteLater()
                local classname = temp:getClassName()
                if temp:isKindOf("Slash") then classname = "Slash" end
                room:setPlayerCardLimitation(player, "use", classname.."|.|.|hand", false)
                room:addPlayerMark(player, "&ny_tenth_dehua", 1)

                player:setTag("ny_tenth_dehua_used", sgs.QVariant(table.concat(unable, "+")))

                if #able == 1 then
                    room:detachSkillFromPlayer(player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ny_tenth_dehua_lose = sgs.CreateTriggerSkill{
    name = "#ny_tenth_dehua_lose",
    events = {sgs.EventLoseSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventLoseSkill then
            if data:toString() == "ny_tenth_dehua" then
                local unable = player:getTag("ny_tenth_dehua_used"):toString():split("+")
                if (not unable) or (#unable <= 0) then unable = {} end
                player:removeTag("ny_tenth_dehua_used")
                room:setPlayerMark(player, "&ny_tenth_dehua", 0)

                for _,pattern in ipairs(unable) do
                    if pattern == "slash" then
                        room:removePlayerCardLimitation(player, "use", "Slash|.|.|hand")
                    else
                        local temp = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
                        temp:deleteLater()
                        local classname = temp:getClassName()
                        room:removePlayerCardLimitation(player, "use", classname.."|.|.|hand")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() 
    end,
}

ny_tenth_dehua_max = sgs.CreateMaxCardsSkill{
    name = "#ny_tenth_dehua_max",
    extra_func = function(self, target)
         return target:getMark("&ny_tenth_dehua")
    end,
}

ny_10th_fuli = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_fuli",
    view_as = function(self)
        return ny_10th_fuliCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:isKongcheng()) and (not player:hasUsed("#ny_10th_fuli"))
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

ny_10th_fuliCard = sgs.CreateSkillCard
{
    name = "ny_10th_fuli",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local room = player:getRoom()
        local types = {}
        local all = {"BasicCard", "TrickCard", "EquipCard"}
        local show = sgs.IntList()
        for _,card in sgs.qlist(player:getHandcards()) do
            show:append(card:getEffectiveId())
            for _,cardType in ipairs(all) do
                if card:isKindOf(cardType) and (not table.contains(types, cardType)) then
                    table.insert(types, cardType)
                    break
                end
            end
        end
        room:showCard(player, show)

        local choice = room:askForChoice(player, self:objectName(), table.concat(types, "+"))
        local discard = sgs.IntList()
        local draw = 0
        local reduce = false
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isKindOf(choice) then
                discard:append(card:getEffectiveId())
                local name = sgs.Sanguosha:translate(card:objectName())
                local n = utf8len(name)
                if card:isKindOf("Slash") then n = 1 end
                draw = draw + n
                if card:isDamageCard() then reduce = true end
            end
        end

        local log = sgs.LogMessage()
        log.type = "$DiscardCard"
        log.from = player
        log.card_str = table.concat(sgs.QList2Table(discard), "+")
        room:sendLog(log)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(discard, nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)

        if player:isDead() then return false end

        local max = 0
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() > max then max = p:getHandcardNum() end
        end
        draw = math.min(draw, max)
        player:drawCards(draw, self:objectName())
        if reduce and player:isAlive() then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ny_10th_fuli", true, true)
            if target then
                room:addPlayerMark(target, "&ny_10th_fuli", 1)
                room:addPlayerMark(target, "ny_10th_fuli_"..player:objectName(), 1)
            end
        end
    end
}

ny_10th_fuli_range = sgs.CreateAttackRangeSkill
{
    name = "#ny_10th_fuli_range",
    extra_func = function(self, target, include_weapon)
        return (-1)*target:getMark("&ny_10th_fuli")
    end,
}

ny_10th_fuli_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_fuli_clear",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.from == sgs.Player_NotActive then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("ny_10th_fuli_"..player:objectName()) > 0 then
                    local n = p:getMark("ny_10th_fuli_"..player:objectName())
                    room:removePlayerMark(p, "&ny_10th_fuli", n)
                    room:setPlayerMark(p, "ny_10th_fuli_"..player:objectName(), 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}


ny_10th_liuli:addSkill(ny_10th_fuli)
ny_10th_liuli:addSkill(ny_10th_fuli_range)
ny_10th_liuli:addSkill(ny_10th_fuli_clear)
ny_10th_liuli:addSkill(ny_tenth_dehua)
ny_10th_liuli:addSkill(ny_tenth_dehuaVS)
ny_10th_liuli:addSkill(ny_tenth_dehua_max)
ny_10th_liuli:addSkill(ny_tenth_dehua_lose)
extension:insertRelatedSkills("ny_tenth_dehua", "#ny_tenth_dehua_max")
extension:insertRelatedSkills("ny_tenth_dehua", "#ny_tenth_dehua_lose")
extension:insertRelatedSkills("ny_10th_fuli", "#ny_10th_fuli_range")
extension:insertRelatedSkills("ny_10th_fuli", "#ny_10th_fuli_clear")

ny_10th_zhangchangpu = sgs.General(extension, "ny_10th_zhangchangpu", "wei", 3, false, false, false)

local function yanjiaoGetSumOfCards(card_ids)
    local sum = 0
    for _,id in sgs.qlist(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        sum = sum + card:getNumber()
    end
    return sum
end

local function yanjiaoAutoJudgeFinish(plans)
    for _,num in ipairs(plans) do
        if num < 2 then return false end
    end
    return true
end

local function yanjiaoAutoNum(plans)
    local n = 0
    for _,num in ipairs(plans) do
        if num == 0 then n = n + 1 end
    end
    return n
end

local function yanjiaoAutoDivide(card_ids)
    local num = card_ids:length()
    if num <= 1 then return sgs.IntList() , sgs.IntList() end
    local to_divide = sgs.QList2Table(card_ids)

    local plans = {}
    for i = 1, num, 1 do
        plans[i] = 0
    end

    local find = false
    local result1 = sgs.IntList()
    local result2 = sgs.IntList()
    local n = 999

    while(true) do
        if yanjiaoAutoJudgeFinish(plans) then break end
        for i = 1, num, 1 do
            if plans[i] < 2 then
                plans[i] = plans[i] + 1
                break
            else
                plans[i] = 0
            end
        end
        local tem1 = sgs.IntList()
        local tem2 = sgs.IntList()
        for i = 1, num, 1 do
            if plans[i] == 1 then
                tem1:append(to_divide[i])
            elseif plans[i] == 2 then
                tem2:append(to_divide[i])
            end
        end
        local num1 = yanjiaoGetSumOfCards(tem1)
        local num2 = yanjiaoGetSumOfCards(tem2)
        if num1 == num2 then
            if (not find) then
                find = true
                result1 = tem1
                result2 = tem2
                n = yanjiaoAutoNum(plans)
            else
                if yanjiaoAutoNum(plans) < n then
                    result1 = tem1
                    result2 = tem2
                    n = yanjiaoAutoNum(plans)
                end
            end
            if n == 0 then break end
        end
    end
    if find then
        return result1 , result2
    end
    return sgs.IntList() , sgs.IntList()
end


ny_tenth_yanjiao = sgs.CreateViewAsSkill
{
    name = "ny_tenth_yanjiao",
    n = 999,
    expand_pile = "#ny_tenth_yanjiao,#ny_tenth_yanjiao_self,#ny_tenth_yanjiao_target",
    response_pattern = "@@ny_tenth_yanjiao",
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ny_tenth_yanjiao" then
            local piles = {"#ny_tenth_yanjiao", "#ny_tenth_yanjiao_self", "#ny_tenth_yanjiao_target"}
            for _,pile in ipairs(piles) do
                if sgs.Self:getPile(pile):contains(to_select:getEffectiveId()) then
                    return true
                end
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ny_tenth_yanjiao" then
            if #cards > 0 then
                local cc = ny_tenth_yanjiao_usingCard:clone()
                for _,card in ipairs(cards) do
                    cc:addSubcard(card)
                end
                return cc
            end
        else
            return ny_tenth_yanjiaoCard:clone()
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_tenth_yanjiao"))
    end,
}

ny_tenth_yanjiaoCard = sgs.CreateSkillCard
{
    name = "ny_tenth_yanjiao",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, from)
        return #targets < 1 and to_select:objectName() ~= from:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()

        local controler = effect.to
        local other = effect.from

        room:setPlayerMark(controler, "ny_tenth_yanjiao_target", 1)
        room:setPlayerMark(other, "ny_tenth_yanjiao_target", 1)

        local shownum = 4 + effect.from:getMark("&ny_10th_xingshen")
        local all_cards = room:getNCards(shownum)
        room:setPlayerMark(effect.from, "&ny_10th_xingshen", 0)

        local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, effect.from:objectName(), self:objectName(), "")
        local move1 = sgs.CardsMoveStruct(all_cards, nil, sgs.Player_PlaceTable, reason1)
        room:moveCardsAtomic(move1, true)

        local last = sgs.IntList()
        local forself = sgs.IntList()
        local forother = sgs.IntList()

        for _,id in sgs.qlist(all_cards) do
            last:append(id)
        end

        while(true) do
            room:notifyMoveToPile(controler, last, "ny_tenth_yanjiao", sgs.Player_PlaceTable, true)
            room:notifyMoveToPile(controler, forself, "ny_tenth_yanjiao_self", sgs.Player_PlaceTable, true)
            room:notifyMoveToPile(controler, forother, "ny_tenth_yanjiao_target", sgs.Player_PlaceTable, true)
            local try = room:askForUseCard(controler, "@@ny_tenth_yanjiao", "@ny_tenth_yanjiao:"..other:getGeneralName())
            room:notifyMoveToPile(controler, last, "ny_tenth_yanjiao", sgs.Player_PlaceTable, false)
            room:notifyMoveToPile(controler, forself, "ny_tenth_yanjiao_self", sgs.Player_PlaceTable, false)
            room:notifyMoveToPile(controler, forother, "ny_tenth_yanjiao_target", sgs.Player_PlaceTable, false)
            if (not try) then break end --不再操作时结束

            --根据角色标记数量决定操作1释放2留给自己3分给对方
            local choice = controler:getMark("ny_tenth_yanjiao_choice")
            room:setPlayerMark(controler, "ny_tenth_yanjiao_choice", 0)
            if choice == 1 then
                for _,id in sgs.qlist(try:getSubcards()) do
                    if (not last:contains(id)) then last:append(id) end
                    if forself:contains(id) then forself:removeOne(id) end
                    if forother:contains(id) then forother:removeOne(id) end
                end
            elseif choice == 2 then
                for _,id in sgs.qlist(try:getSubcards()) do
                    if (not forself:contains(id)) then forself:append(id) end
                    if last:contains(id) then last:removeOne(id) end
                    if forother:contains(id) then forother:removeOne(id) end
                end
            else
                for _,id in sgs.qlist(try:getSubcards()) do
                    if (not forother:contains(id)) then forother:append(id) end
                    if last:contains(id) then last:removeOne(id) end
                    if forself:contains(id) then forself:removeOne(id) end
                end
            end

            --计算点数之和
            local sumforself = yanjiaoGetSumOfCards(forself)
            room:setPlayerMark(controler, "&ny_tenth_yanjiao", sumforself)
            local sumforother = yanjiaoGetSumOfCards(forother)
            room:setPlayerMark(other, "&ny_tenth_yanjiao", sumforother)
        end

        --停止选中目标
        room:setPlayerMark(controler, "ny_tenth_yanjiao_target", 0)
        room:setPlayerMark(other, "ny_tenth_yanjiao_target", 0)

        --展示点数之和设置为0
        room:setPlayerMark(controler, "&ny_tenth_yanjiao", 0)
        room:setPlayerMark(other, "&ny_tenth_yanjiao", 0)

        local sumforself = yanjiaoGetSumOfCards(forself)
        local sumforother = yanjiaoGetSumOfCards(forother)

        --尝试一次自动分配
        if (sumforself ~= sumforother) or (sumforself == 0) then
            local choice = room:askForChoice(controler, self:objectName(), "yes+no", sgs.QVariant(), "", "ny_tenth_yanjiao_ask")
            if choice == "yes" then
                forself,forother = yanjiaoAutoDivide(all_cards)
                sumforself = yanjiaoGetSumOfCards(forself)
                sumforother = yanjiaoGetSumOfCards(forother)
                last = sgs.IntList()
                for _,id in sgs.qlist(all_cards) do
                    last:append(id)
                end
                for _,id in sgs.qlist(forself) do
                    last:removeOne(id)
                end
                for _,id in sgs.qlist(forother) do
                    last:removeOne(id)
                end
            end
        end

        if sumforself ~= sumforother then
            --点数不等全部置入弃牌堆
            room:addPlayerMark(effect.from, "&ny_tenth_yanjiao_failed-Clear", 1)
            local log = sgs.LogMessage()
            log.type = "$EnterDiscardPile"
            log.card_str = table.concat(sgs.QList2Table(all_cards), "+")
            room:sendLog(log)

            local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:objectName(), "")
            local move2 = sgs.CardsMoveStruct(all_cards, nil, sgs.Player_DiscardPile, reason2)
            room:moveCardsAtomic(move2, true)
        else
            if controler:isAlive() and (not forself:isEmpty()) then
                local card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                card:addSubcards(forself)
                card:deleteLater()
                room:obtainCard(controler, card, true)
            end
            if other:isAlive() and (not forother:isEmpty()) then
                local card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                card:addSubcards(forother)
                card:deleteLater()
                room:obtainCard(other, card, true)
            end
            if effect.from:isAlive() and last:length() > 1 then
                room:addPlayerMark(effect.from, "&ny_tenth_yanjiao_failed-Clear", 1)
            end
            local discard = sgs.IntList()
            for _,id in sgs.qlist(all_cards) do
                if room:getCardPlace(id) == sgs.Player_PlaceTable then
                    discard:append(id)
                end
            end
            if (not discard:isEmpty()) then
                local log = sgs.LogMessage()
                log.type = "$EnterDiscardPile"
                log.card_str = table.concat(sgs.QList2Table(discard), "+")
                room:sendLog(log)
    
                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:objectName(), "")
                local move2 = sgs.CardsMoveStruct(discard, nil, sgs.Player_DiscardPile, reason2)
                room:moveCardsAtomic(move2, true)
            end
        end
    end
}

ny_tenth_yanjiao_usingCard = sgs.CreateSkillCard
{
    name = "ny_tenth_yanjiao_using",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:getMark("ny_tenth_yanjiao_target") > 0
    end,
    feasible = function(self, targets, player)
        return #targets <= 1
    end,
    about_to_use = function(self,room,use)
        local player = use.from
        if use.to:isEmpty() then
            room:setPlayerMark(player, "ny_tenth_yanjiao_choice", 1)
        else
            local to = use.to:at(0)
            if to:objectName() == player:objectName() then
                room:setPlayerMark(player, "ny_tenth_yanjiao_choice", 2)
            else
                room:setPlayerMark(player, "ny_tenth_yanjiao_choice", 3)
            end
        end
    end
}

ny_tenth_yanjiao_max = sgs.CreateMaxCardsSkill{
    name = "#ny_tenth_yanjiao_max",
    extra_func = function(self, target)
        return -target:getMark("&ny_tenth_yanjiao_failed-Clear")
    end,
}

ny_10th_xingshen = sgs.CreateTriggerSkill{
    name = "ny_10th_xingshen",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local n1 = 2
            local n2 = 2
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() < player:getHandcardNum() then
                    n1 = 1
                end
                if p:getHp() < player:getHp() then
                    n2 = 1
                end
            end
            player:drawCards(n1, self:objectName())
            if player:isAlive() then
                room:addPlayerMark(player, "&ny_10th_xingshen", n2)
                if player:getMark("&ny_10th_xingshen") > 4 then
                    room:setPlayerMark(player, "&ny_10th_xingshen", 4)
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_10th_zhangchangpu:addSkill(ny_tenth_yanjiao)
ny_10th_zhangchangpu:addSkill(ny_tenth_yanjiao_max)
ny_10th_zhangchangpu:addSkill(ny_10th_xingshen)
extension:insertRelatedSkills("ny_tenth_yanjiao", "#ny_tenth_yanjiao_max")

ny_10th_mousimayi = sgs.General(extension, "ny_10th_mousimayi", "wei", 3, true, false, false)

ny_tenth_pingliao = sgs.CreateTriggerSkill{
    name = "ny_tenth_pingliao",
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end

            local log = sgs.LogMessage()
            log.type = "#ChoosePlayerWithSkill"
            log.from = player
            log.arg = self:objectName()
            log.to = targets
            room:sendLog(log)

            if player:property("avatarIcon"):toString():endsWith("simayi_yin") then
                room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
            else
                room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
            end
            
            if (not use.card:getSubcards():isEmpty()) then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, player:objectName())
                local move = sgs.CardsMoveStruct(use.card:getSubcards(), nil, sgs.Player_PlaceTable, reason)
                room:moveCardsAtomic(move, true)
            end

            local respon = sgs.SPlayerList()
            for _,target in sgs.qlist(targets) do
                local card = room:askForCard(target, "BasicCard|red|.|.", "@ny_tenth_pingliao:"..player:objectName(), data, sgs.Card_MethodResponse, player)
                if card then
                    respon:append(target)
                end
            end
            for _,p in sgs.qlist(use.to) do
                if (not respon:contains(p)) then
                    room:setPlayerMark(p, "&ny_tenth_pingliao-Clear", 1)
                end
            end
            for _,p in sgs.qlist(respon) do
                if (not use.to:contains(p)) then
                    player:drawCards(2, self:objectName())
                    if player:getPhase() == sgs.Player_Play then
                        room:addPlayerMark(player, "&ny_tenth_pingliao_slash-PlayClear", 1)
                    end
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_pingliao_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_pingliao_buff",
    residue_func = function(self, from, card)
        return from:getMark("&ny_tenth_pingliao_slash-PlayClear")
    end,
}

ny_tenth_pingliao_limit = sgs.CreateCardLimitSkill
{
    name = "#ny_tenth_pingliao_limit",
    limit_list = function(self, player)
            return "use,response"
    end,
    limit_pattern = function(self, player)
        if player:getMark("&ny_tenth_pingliao-Clear") > 0 then 
            return ".|.|.|hand"
        end
    end

}

ny_10th_quanmouVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_quanmou",
    view_as = function(self)
        return ny_10th_quanmouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

ny_10th_quanmouCard = sgs.CreateSkillCard
{
    name = "ny_10th_quanmou",
    mute = true,
    filter = function(self, targets, to_select,player)
        return player:inMyAttackRange(to_select)
		and #targets < 1 and to_select ~= player
        and to_select:getMark("ny_10th_quanmou_selelcted-PlayClear") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "ny_10th_quanmou_selelcted-PlayClear", 1)

		if effect.from:property("avatarIcon"):toString():endsWith("simayi_yin") then
            room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
        else
            room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
        end

        local mark
        if effect.from:getChangeSkillState(self:objectName()) <= 1 then
            mark = string.format("&ny_10th_quanmou_first+#%s-PlayClear", effect.from:objectName())
            room:setChangeSkillState(effect.from, self:objectName(), 2)
            if effect.from:getGeneralName():endsWith("simayi") then
                effect.from:setAvatarIcon("ny_10th_mousimayi_yin")
            end
        else
            mark = string.format("&ny_10th_quanmou_second+#%s-PlayClear", effect.from:objectName())
            room:setChangeSkillState(effect.from, self:objectName(), 1)
            if effect.from:property("avatarIcon"):toString():endsWith("simayi_yin") then
                effect.from:setAvatarIcon("ny_10th_mousimayi")
            end
        end
        room:setPlayerMark(effect.to, mark, 1)
        if (not effect.to:isNude()) then
            local card = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "@ny_10th_quanmou-give:"..effect.from:getGeneralName(), false)
            room:obtainCard(effect.from, card, false)
        end
    end
}

ny_10th_quanmou = sgs.CreateTriggerSkill{
    name = "ny_10th_quanmou",
    events = {sgs.Damage,sgs.DamageCaused,sgs.GameStart},
	change_skill = true,
    view_as_skill = ny_10th_quanmouVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
			if room:askForChoice(player,self:objectName(),"1_num+2_num")=="2_num" then
                room:setChangeSkillState(player, self:objectName(), 2)
			end
            return false
		end
        local damage = data:toDamage()
        if damage.to:getMark("&ny_10th_quanmou_first+#"..player:objectName().."-PlayClear") > 0 
        and event == sgs.DamageCaused then
            room:setPlayerMark(damage.to, "&ny_10th_quanmou_first+#"..player:objectName().."-PlayClear", 0)
            local log = sgs.LogMessage()
            log.type = "$ny_10th_quanmou_prohibit"
            log.from = player
            log.to:append(damage.to)
            log.arg = self:objectName()
            room:sendLog(log)

			if player:property("avatarIcon"):toString():endsWith("simayi_yin") then
                room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
            else
                room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
            end

            return true
        end
        if damage.to:getMark("&ny_10th_quanmou_second+#"..player:objectName().."-PlayClear") > 0
        and event == sgs.Damage then
            room:setPlayerMark(damage.to, "&ny_10th_quanmou_second+#"..player:objectName().."-PlayClear", 0)
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p ~= damage.to then targets:append(p) end
            end
                local damages = room:askForPlayersChosen(player, targets,
                self:objectName(), 0, 3, "@ny_10th_quanmou-damage:"..damage.to:getGeneralName(), true, true)
			if not damages:isEmpty() then
				if player:property("avatarIcon"):toString():endsWith("simayi_yin") then
					room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
                    else
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
                    end

                    for _,to in sgs.qlist(damages) do
                        if to:isAlive() then
                            room:damage(sgs.DamageStruct(self:objectName(), player, to, 1, sgs.DamageStruct_Normal))
                        end
                    end
                end
            end
    end,
}

ny_10th_mousimayi:addSkill(ny_tenth_pingliao)
ny_10th_mousimayi:addSkill(ny_tenth_pingliao_buff)
ny_10th_mousimayi:addSkill(ny_tenth_pingliao_limit)
ny_10th_mousimayi:addSkill(ny_10th_quanmou)
ny_10th_mousimayi:addSkill(ny_10th_quanmouVS)

extension:insertRelatedSkills("ny_tenth_pingliao", "#ny_tenth_pingliao_buff")
extension:insertRelatedSkills("ny_tenth_pingliao", "#ny_tenth_pingliao_limit")

ny_10th_caoshuang = sgs.General(extension, "ny_10th_caoshuang", "wei", 4, true, false, false)

ny_10th_jianzhuan = sgs.CreateTriggerSkill{
    name = "ny_10th_jianzhuan",
    events = {sgs.CardUsed,sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
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
            if (not card) or card:isKindOf("SkillCard") then return false end
            local num = 1 + player:getMark("&ny_10th_jianzhuan-PlayClear")
            local allchoices = player:getTag("ny_10th_jianzhuan"):toString():split("+")
            if (not allchoices) or (#allchoices == 0) then return false end
            local items = {}
            for _,item in ipairs(allchoices) do
                local mark = string.format("ny_10th_jianzhuan_%s-PlayClear", item)
                if player:getMark(mark) == 0 then
                    table.insert(items, string.format("%s=%s", item, num))
                end
            end
            if #items <= 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:addPlayerMark(player, "&ny_10th_jianzhuan-PlayClear", 1)
            local choice = room:askForChoice(player, self:objectName(), table.concat(items, "+"))
            if string.find(choice, "disother") then
                room:setPlayerMark(player, string.format("ny_10th_jianzhuan_%s-PlayClear", "disother"), 1)
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@ny_10th_jianzhuan-disother:"..num, false, true)
                room:askForDiscard(target, self:objectName(), num, num, false, true)
            elseif string.find(choice, "draw") then
                room:setPlayerMark(player, string.format("ny_10th_jianzhuan_%s-PlayClear", "draw"), 1)
                player:drawCards(num, self:objectName())
            elseif string.find(choice, "recast") then
                room:setPlayerMark(player, string.format("ny_10th_jianzhuan_%s-PlayClear", "recast"), 1)
                local re = room:askForExchange(player, self:objectName(), num, num, true, "@ny_10th_jianzhuan-recast:"..num, false)
                if re then 
                    local log = sgs.LogMessage()
                    log.from = player
                    log.type = "$RecastCard"
                    log.card_str = table.concat(sgs.QList2Table(re:getSubcards()), "+")
                    room:sendLog(log)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), "")
                    room:moveCardTo(re, nil, nil, sgs.Player_DiscardPile, reason)
                    if player:isDead() then return false end
                    player:drawCards(re:subcardsLength(), "recast")
                end
            else
                room:setPlayerMark(player, string.format("ny_10th_jianzhuan_%s-PlayClear", "disself"), 1)
                room:askForDiscard(player, self:objectName(), num, num, false, true)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local items = player:getTag("ny_10th_jianzhuan"):toString():split("+")
            if ((not items) or (#items == 0)) and player:getMark("ny_10th_jianzhuan_first") == 0 then
                room:setPlayerMark(player, "ny_10th_jianzhuan_first", 1)
                local allchoices = {"disother", "draw", "recast", "disself"}
                player:setTag("ny_10th_jianzhuan", sgs.QVariant(table.concat(allchoices, "+")))
            end
        end
        if event == sgs.EventPhaseEnd then
            local items = player:getTag("ny_10th_jianzhuan"):toString():split("+")
            if ((not items) or (#items == 0)) then
                return false
            end
            if player:getMark("&ny_10th_jianzhuan-PlayClear") < #items then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local remove = {}
            for i = 1, #items, 1 do
                for j = 1, i + 1, 1 do
                    table.insert(remove, items[i])
                end
            end
            table.removeOne(items, remove[math.random(1,#remove)])
            player:setTag("ny_10th_jianzhuan", sgs.QVariant(table.concat(items, "+")))
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_fanshi = sgs.CreateTriggerSkill{
    name = "ny_10th_fanshi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "ny_10th_fudou",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local item
        local items = player:getTag("ny_10th_jianzhuan"):toString():split("+")
        if ((not items) or (#items == 0)) and player:getMark("ny_10th_jianzhuan_first") == 0 then
            items = {"disother", "draw", "recast", "disself"}
        end
        if items and #items > 0 then
            item = items[math.random(1,#items)]
        end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:setPlayerMark(player, "ny_10th_fanshi", 1)
        if item then
            local num = 1
            local choice = item
            for i = 1, 3, 1 do
                room:broadcastSkillInvoke("ny_10th_jianzhuan")
                room:getThread():delay()
                if string.find(choice, "disother") then
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "ny_10th_jianzhuan", "@ny_10th_jianzhuan-disother:"..num, false, true)
                    room:askForDiscard(target, "ny_10th_jianzhuan", num, num, false, true)
                elseif string.find(choice, "draw") then
                    player:drawCards(num, "ny_10th_jianzhuan")
                elseif string.find(choice, "recast") then
                    local re = room:askForExchange(player, "ny_10th_jianzhuan", num, num, true, "@ny_10th_jianzhuan-recast:"..num, false)
                    if re then 
                        local log = sgs.LogMessage()
                        log.from = player
                        log.type = "$RecastCard"
                        log.card_str = table.concat(sgs.QList2Table(re:getSubcards()), "+")
                        room:sendLog(log)
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), "ny_10th_jianzhuan", "")
                        room:moveCardTo(re, nil, nil, sgs.Player_DiscardPile, reason)
                        if player:isDead() then return false end
                        player:drawCards(re:subcardsLength(), "recast")
                    end
                else
                    room:askForDiscard(player, "ny_10th_jianzhuan", num, num, false, true)
                end
                if player:isDead() then return false end
            end
        end
        --room:detachSkillFromPlayer(player, "ny_10th_jianzhuan")
        if player:isAlive() then
            room:gainMaxHp(player, 2, self:objectName())
        end
        if player:isAlive() and player:isWounded() then
            room:recover(player, sgs.RecoverStruct(self:objectName(), player, 2))
        end
        if player:isAlive() then
            room:detachSkillFromPlayer(player, "ny_10th_jianzhuan")
        end
        if player:isAlive() then
            room:acquireSkill(player, "ny_10th_fudou")
        end
    end,
    can_trigger = function(self, target)
        if (not target) then return false end
        if target:getMark("ny_10th_fanshi") > 0 then return false end
        if target:getPhase() ~= sgs.Player_Finish then return false end
        if target:canWake(self:objectName()) then return true end
        if (not target:hasSkill(self:objectName())) then return false end
        local items = target:getTag("ny_10th_jianzhuan"):toString():split("+")
        if ((items) and (#items <= 1)) and target:getMark("ny_10th_jianzhuan_first") > 0 then
            return true
        end
    end,
}

ny_10th_fudou_record = sgs.CreateTriggerSkill{
    name = "#ny_10th_fudou_record",
    events = {sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to and damage.to:isAlive() then
            room:setPlayerMark(player, "ny_10th_fudou+"..damage.to:objectName(), 1)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_fudou = sgs.CreateTriggerSkill{
    name = "ny_10th_fudou",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.from == player
        and use.to:length() == 1
        and use.to:at(0):objectName() ~= player:objectName()
        and use.to:at(0):isAlive() then
            local target = use.to:at(0)
            player:setTag("ny_10th_fudou", data)
            if target:getMark("ny_10th_fudou+"..player:objectName()) > 0 and use.card:isBlack() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("lose:"..target:getGeneralName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:loseHp(player, 1, true, player, self:objectName())
                    room:loseHp(target, 1, true, player, self:objectName())
                end
            end
            if target:getMark("ny_10th_fudou+"..player:objectName()) == 0 and use.card:isRed() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..target:getGeneralName())) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(1, self:objectName())
                    target:drawCards(1, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_caoshuang:addSkill(ny_10th_jianzhuan)
ny_10th_caoshuang:addSkill(ny_10th_fanshi)
ny_10th_caoshuang:addSkill(ny_10th_fudou_record)
extension:insertRelatedSkills("ny_10th_fanshi", "#ny_10th_fudou_record")

ny_10th_duyu_second = sgs.General(extension, "ny_10th_duyu_second", "wei", 4, true, false, false)

ny_10th_jianguo_second = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_jianguo_second",
    tiansuan_type = "draw,dis",
    view_as = function(self)
        local choice = sgs.Self:getTag(self:objectName()):toString()
        local card = ny_10th_jianguo_secondCard:clone()
        card:setUserString(choice)
        return card
    end,
    enabled_at_play = function(self, player)
        return player:getMark("ny_10th_jianguo_second_tiansuan_remove_draw-PlayClear") == 0
        or player:getMark("ny_10th_jianguo_second_tiansuan_remove_dis-PlayClear") == 0
    end
}

ny_10th_jianguo_secondCard = sgs.CreateSkillCard
{
    name = "ny_10th_jianguo_second",
    filter = function(self, selected, to_select)
        return #selected < 1
        and (self:getUserString() ~= "dis" or (not to_select:isNude()))
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choice = self:getUserString()
        room:setPlayerMark(effect.from, "ny_10th_jianguo_second_tiansuan_remove_"..choice.."-PlayClear", 1)
        if choice == "draw" then
            room:askForDiscard(effect.to, self:objectName(), 1, 1, false, true)
            if effect.to:isAlive() and (not effect.to:isKongcheng()) then
                local num = math.ceil(effect.to:getHandcardNum()/2)
                effect.to:drawCards(num, self:objectName())
            end
        end
        if choice == "dis" then
            effect.to:drawCards(1, self:objectName())
            if effect.to:isAlive() and (not effect.to:isKongcheng()) then
                local num = math.ceil(effect.to:getHandcardNum()/2)
                room:askForDiscard(effect.to, self:objectName(), num, num, false, false)
            end
        end
    end
}

ny_10th_duyu_second:addSkill(ny_10th_jianguo_second)
ny_10th_duyu_second:addSkill("ny_10th_qinshi")

ny_10th_caofang = sgs.General(extension, "ny_10th_caofang$", "wei", 4, true, false, false)

ny_10th_zhimin = sgs.CreateTriggerSkill{
    name = "ny_10th_zhimin",
    events = {sgs.RoundStart, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            if player:getHp() <= 0 then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if (not p:isKongcheng()) then targets:append(p) end
            end
            if targets:isEmpty() then return false end
            local num = player:getHp()
            local tos = room:askForPlayersChosen(player, targets, self:objectName(), 1, num, "@ny_10th_zhimin:"..num, true, true)
            room:broadcastSkillInvoke(self:objectName())
            for _,to in sgs.qlist(tos) do
                if to:isDead() or to:isKongcheng() then continue end
                if player:isDead() then return false end
                local min = 14
                for _,card in sgs.qlist(to:getHandcards()) do
                    if card:getNumber() <= min then min = card:getNumber() end
                end
                for _,card in sgs.qlist(to:getHandcards()) do
                    if card:getNumber() == min then
                        room:obtainCard(player, card, false)
                        break
                    end
                end
            end
        end
        if event == sgs.CardsMoveOneTime then
            if room:getTag("FirstRound"):toBool() then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() 
            and player:getHandcardNum() < player:getMaxHp() then
                for i = 0, move.card_ids:length() - 1, 1 do
                    local card = sgs.Sanguosha:getCard(move.card_ids:at(i))
                    if card:hasFlag("ny_10th_zhimin") and move.from_places:at(i) == sgs.Player_PlaceHand then
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        local num = player:getMaxHp() - player:getHandcardNum()
                        player:drawCards(num, self:objectName())
                        break
                    end
                end
            end
            if move.to and move.to:objectName() == player:objectName() 
            and move.to_place == sgs.Player_PlaceHand and player:getPhase() == sgs.Player_NotActive then
                for _,id in sgs.qlist(move.card_ids) do
                    if player:handCards():contains(id) then
                        room:setCardFlag(id, "ny_10th_zhimin")
                        room:setCardTip(id, "ny_10th_zhimin_min")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
		and target:hasSkill(self:objectName())
    end,
}

ny_10th_jujianVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_jujian$",
    view_as = function(self)
        return ny_10th_jujianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_jujian"))
        and player:hasLordSkill(self:objectName())
    end
}

ny_10th_jujianCard = sgs.CreateSkillCard
{
    name = "ny_10th_jujian",
    filter = function(self, targets, to_select,player)
        return #targets < 1 and to_select:getKingdom() == "wei"
        and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "&ny_10th_jujian+#"..effect.from:objectName().."_lun", 1)
        effect.to:drawCards(1, self:objectName())
    end

}

ny_10th_jujian = sgs.CreateTriggerSkill{
    name = "ny_10th_jujian$",
    events = {sgs.TargetConfirmed},
    view_as_skill = ny_10th_jujianVS,
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isNDTrick() and use.from and use.to:contains(player)
        and use.from:getMark("&ny_10th_jujian+#"..player:objectName().."_lun") > 0 then
            local log = sgs.LogMessage()
            log.type = "$ny_10th_jujian_buff"
            log.from = player
            log.arg = self:objectName()
            log.card_str = use.card:toString()
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())
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

ny_10th_caofang:addSkill(ny_10th_zhimin)
ny_10th_caofang:addSkill(ny_10th_jujian)
ny_10th_caofang:addSkill(ny_10th_jujianVS)

ny_10th_wuguanyu = sgs.General(extension, "ny_10th_wuguanyu", "shu", 5, true, false, false)

ny_tenth_wuyou_other = sgs.CreateViewAsSkill
{
    name = "ny_tenth_wuyou_other&",
    n = 99,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cc = ny_tenth_wuyouCard:clone()
            cc:addSubcard(cards[1])
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_tenth_wuyou"))
    end
}

ny_tenth_wuyouCard = sgs.CreateSkillCard
{
    name = "ny_tenth_wuyou",
    will_throw = false,
    filter = function(self, targets, to_select)
        return to_select:hasSkill("ny_tenth_wuyou") and #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:objectName() ~= effect.from:objectName() then
            room:obtainCard(effect.to, self, false)
        end
        if effect.from:isAlive() and effect.to:isAlive() then
            local give 
            if effect.from:objectName() ~= effect.to:objectName() then
                give = room:askForExchange(effect.to, self:objectName(), 1, 1, false, "@ny_tenth_wuyou:"..effect.from:getGeneralName(), true)
            else
                give = self
            end
            if give then
                local names = {}
                local slash = false
                for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if (not card:isKindOf("EquipCard")) then
                        if card:isKindOf("Slash") then
                            if (not slash) then
                                table.insert(names, card:objectName())
                                slash = true
                                if #names >= 5 then break end
                            end
                        else
                            if (not table.contains(names, card:objectName())) then
                                table.insert(names, card:objectName())
                                if #names >= 5 then break end
                            end
                        end
                    end
                end
                local pattern = room:askForChoice(effect.to, self:objectName(), table.concat(names, "+"))
                if effect.to:objectName() ~= effect.from:objectName() then
                    room:obtainCard(effect.from, give, false)
                end
                local cc = sgs.Sanguosha:getCard(give:getSubcards():at(0))
                if room:getCardOwner(cc:getEffectiveId()) == effect.from
                and effect.from:isAlive() then
                    local new = sgs.Sanguosha:cloneCard(pattern, cc:getSuit(), cc:getNumber())
                    new:setSkillName(self:objectName())
                    local ccc = sgs.Sanguosha:getWrappedCard(cc:getId())
                    ccc:takeOver(new)
                    room:notifyUpdateCard(effect.from, cc:getId(), ccc)
                end
            end
        end
    end
}

ny_tenth_wuyou = sgs.CreateTriggerSkill{
    name = "ny_tenth_wuyou",
    events = {sgs.GameStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill then
            if data:toString() ~= self:objectName() then return false end
        end
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if (not p:hasSkill("ny_tenth_wuyou_other")) then
                room:attachSkillToPlayer(p, "ny_tenth_wuyou_other")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tenth_wuyou_buff = sgs.CreateTargetModSkill{
    name = "#ny_tenth_wuyou_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_wuyou" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_tenth_wuyou" then return 1000 end
        return 0
    end,
}

ny_tenth_yixian = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_tenth_yixian",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ny_tenth_yixian_mark",
    tiansuan_type = "field,discardpile",
    view_as = function(self)
        local card = ny_tenth_yixianCard:clone()
        local choice = sgs.Self:getTag("ny_tenth_yixian"):toString()
        card:setUserString(choice)
        return card
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@ny_tenth_yixian_mark") > 0
    end,
}

ny_tenth_yixianCard = sgs.CreateSkillCard
{
    name = "ny_tenth_yixian",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local room = player:getRoom()
        room:setPlayerMark(player, "@ny_tenth_yixian_mark", 0)
        local choice = self:getUserString()
        if choice == "field" then
            local players = {}
            local num = {}
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:isDead() or player:isDead() then continue end
                local n = p:getEquips():length()
                if n > 0 then
                    table.insert(players, p)
                    num[p:objectName()] = n
                    local all_equips = sgs.IntList()
                    for _,equip in sgs.qlist(p:getEquips()) do
                        all_equips:append(equip:getId())
                    end
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), self:objectName(), "")
                    local move = sgs.CardsMoveStruct(all_equips, p, player, sgs.Player_PlaceEquip, sgs.Player_PlaceHand, reason)
                    room:moveCardsAtomic(move, true)
                    room:getThread():delay(400)
                end
            end
            for _,p in ipairs(players) do
                if p:isDead() or player:isDead() then break end
                local n = num[p:objectName()]
                local data = sgs.QVariant()
                data:setValue(p)
                local can = room:askForChoice(player, self:objectName(), "buff="..p:getGeneralName().."+cancel", data)
                if can ~= "cancel" then
                    p:drawCards(n, self:objectName())
                    if p:isAlive() and p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(self:objectName(), player, 1))
                    end
                end
            end
            
        else
            local all_equips = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(room:getDiscardPile()) do
                if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                    all_equips:addSubcard(sgs.Sanguosha:getCard(id))
                end
            end
            if all_equips:subcardsLength() > 0 then
                room:obtainCard(player, all_equips, true)   
            end     
            all_equips:deleteLater()
        end
    end
}           

ny_tenth_jvewuVS = sgs.CreateViewAsSkill
{
    name = "ny_tenth_jvewu",
    n = 99,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return #selected < 1 and to_select:getNumber() == 2
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return ny_tenth_jvewu_selectCard:clone()
        else
            if #cards == 1 then
                local pattern
                if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ny_tenth_jvewu" then
                    pattern = sgs.Self:property("ny_tenth_jvewu_card"):toString()
                else
                    pattern = "Slash"
                end
                local cc = ny_tenth_jvewuCard:clone()
                cc:addSubcard(cards[1])
                cc:setUserString(pattern)
                return cc
            end
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@ny_tenth_jvewu"
        or ((string.find(pattern, "slash") or string.find(pattern, "Slash"))
        and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
        and player:getMark("ny_tenth_jvewu_Slash-Clear") == 0)
    end,
}

ny_tenth_jvewu_selectCard = sgs.CreateSkillCard
{
    name = "ny_tenth_jvewu_select",
    will_throw = false,
    target_fixed = true,
    about_to_use = function(self,room,use)
        local player = use.from
        local names = {"_ny_tenth_shuiyanqijun"}
        for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
            local card = sgs.Sanguosha:getEngineCard(id)
            if card:isKindOf("BasicCard") or card:isNDTrick() then
                if card:isDamageCard() then
                    if (not table.contains(names, card:objectName())) then
                        table.insert(names, card:objectName())
                    end
                end
            end
        end
        local able = {}
        local enable = {}
        for _,name in ipairs(names) do
            local card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
            local mark = string.format("ny_tenth_jvewu_%s-Clear", card:objectName())
            if card:isKindOf("Slash") then mark = "ny_tenth_jvewu_Slash-Clear" end
            if player:getMark(mark) == 0 and card:isAvailable(player) then
                table.insert(able, name)
            else
                table.insert(enable, name)
            end
        end
        if #able <= 0 then
            room:askForChoice(player, "ny_tenth_jvewu", "disable+cancel")
            return false
        end
        table.insert(able, "cancel")
        local pattern = room:askForChoice(player, "ny_tenth_jvewu", table.concat(able, "+"), sgs.QVariant(), table.concat(enable, "+"))
        if pattern == "cancel" then return false end
        room:setPlayerProperty(player, "ny_tenth_jvewu_card", sgs.QVariant(pattern))
        room:askForUseCard(player, "@@ny_tenth_jvewu", "@ny_tenth_jvewu:"..pattern)
    end
}

ny_tenth_jvewuCard = sgs.CreateSkillCard
{
    name = "ny_tenth_jvewu",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
        if pattern == "Slash" then
            pattern = room:askForChoice(player, "ny_tenth_jvewu_slash", "fire_slash+thunder_slash+slash")
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        local mark = string.format("ny_tenth_jvewu_%s-Clear", card:objectName())
        if card:isKindOf("Slash") then mark = "ny_tenth_jvewu_Slash-Clear" end
        room:setPlayerMark(player, mark, 1)

        if sgs.Sanguosha:getCard(self:getSubcards():at(0)):hasFlag("ny_tenth_jvewu") then
            room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():at(0)), "-ny_tenth_jvewu")
        end
        card:deleteLater()
        return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()
        local pattern = self:getUserString()
        if pattern == "Slash" then
            pattern = room:askForChoice(player, "ny_tenth_jvewu_slash", "fire_slash+thunder_slash+slash")
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        local mark = string.format("ny_tenth_jvewu_%s-Clear", card:objectName())
        if card:isKindOf("Slash") then mark = "ny_tenth_jvewu_Slash-Clear" end
        room:setPlayerMark(player, mark, 1)

        if sgs.Sanguosha:getCard(self:getSubcards():at(0)):hasFlag("ny_tenth_jvewu") then
            room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():at(0)), "-ny_tenth_jvewu")
        end
        card:deleteLater()
        return card
    end
}

ny_tenth_jvewu = sgs.CreateTriggerSkill{
    name = "ny_tenth_jvewu",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_tenth_jvewuVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and (move.from:objectName() ~= player:objectName())
        and (move.from_places:contains(sgs.Player_PlaceHand)
        or move.from_places:contains(sgs.Player_PlaceEquip))
        and move.to and move.to:objectName() == player:objectName()
        and move.to_place == sgs.Player_PlaceHand then
            local cards = sgs.CardList()
            for _,id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getNumber() == 2 then continue end
                cards:append(card)
                room:setCardFlag(card, "ny_tenth_jvewu")
            end
            if (not cards:isEmpty()) then
                room:filterCards(player, cards, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

--这个技能用于给武关羽提供红利期
--摸牌阶段摸牌时，手牌中点数为2的牌越少越容易摸到点数为2的牌
--判定时，血量越少越容易天过

ny_tenth_jvewu_dividend = sgs.CreateTriggerSkill{
    name = "#ny_tenth_jvewu_dividend",
    events = {sgs.DrawNCards,sgs.StartJudge},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.StartJudge then
            local judge = data:toJudge()
            if math.random(1,(player:getMaxHp() + 1)) > (player:getLostHp() + 1) then return false end
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
        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.num > 1 then
                local n = 4
                for _,card in sgs.qlist(player:getHandcards()) do
                    if card:getNumber() == 2 then n = n + 1 end
                end
                if math.random(1,n) <= 2 then
                    local find = false
                    n = 0
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:getNumber() == 2 then
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
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("ny_tenth_jvewu")
        and target:getGeneralName() == "ny_10th_wuguanyu"
    end,
}

ny_tenth_jvewu_change = sgs.CreateFilterSkill{
	name = "#ny_tenth_jvewu_change",
	view_filter = function(self, to_select)
		return to_select:hasFlag("ny_tenth_jvewu")
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setNumber(2)
		new_card:setModified(true)
		return new_card
	end
}

ny_10th_wuguanyu:addSkill(ny_tenth_jvewu)
ny_10th_wuguanyu:addSkill(ny_tenth_jvewuVS)
ny_10th_wuguanyu:addSkill(ny_tenth_jvewu_dividend)
ny_10th_wuguanyu:addSkill(ny_tenth_jvewu_change)
ny_10th_wuguanyu:addSkill(ny_tenth_wuyou)
ny_10th_wuguanyu:addSkill(ny_tenth_wuyou_buff)
ny_10th_wuguanyu:addSkill(ny_tenth_yixian)
extension:insertRelatedSkills("ny_tenth_wuyou", "#ny_tenth_wuyou_buff")
extension:insertRelatedSkills("ny_tenth_jvewu", "#ny_tenth_jvewu_change")

ny_tenth_shuiyanqijun = sgs.CreateTrickCard{
	name = "_ny_tenth_shuiyanqijun",
	class_name = "Drowning",
	subclass = sgs.LuaTrickCard_TypeNormal,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	subtype = "ny_10th_wuguanyu_card",
	damage_card = true,
	can_recast = false,
	filter = function(self,targets,to_select,source)
		if #targets > sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self) + 1 then return false end
		return true
	end,
	--[[feasible = function(self,targets,player)
		if player:isCardLimited(self,sgs.Card_MethodUse) then return false end
		return #targets > 0
	end,]]
    about_to_use = function(self,room,use)
        local tos = {}
        for _,to in sgs.qlist(use.to) do
            table.insert(tos, to:objectName())
        end
        room:setTag("ny_tenth_shuiyanqijun"..self:toString(), sgs.QVariant(table.concat(tos, "+")))
        self:cardOnUse(room,use)
    end,
	on_use = function(self,room,source,targets)
		local tos = room:getTag("ny_tenth_shuiyanqijun"..self:toString()):toString():split("+")
        local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
        local targets_in_order = sgs.SPlayerList()
        for _,p in ipairs(tos) do
            targets_in_order:append(room:findPlayerByObjectName(p))
        end
        for _,p in sgs.list(targets) do
            if (not targets_in_order:contains(p)) then
                targets_in_order:append(p)
            end
        end

		for i,to in sgs.qlist(targets_in_order)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = true
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	
            for i = 1, #tos, 1 do
                if tos[i] == to:objectName() then
                    if (math.floor(i/2) ~= (i/2)) then
                        to:setFlags(self:toString().."throwCard")
                    else
                        to:setFlags(self:toString().."drawCard")
                    end
                end
            end
            
            room:cardEffect(effect)
			to:setFlags("-"..self:toString().."throwCard")
			to:setFlags("-"..self:toString().."drawCard")
			table.insert(tos,to:getHandcardNum())
		end
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
        room:damage(sgs.DamageStruct(self, from, to, 1, sgs.DamageStruct_Thunder))
		if effect.to:hasFlag(self:toString().."throwCard") then
			local tc = room:askForDiscard(to, self:objectName(), 1, 1, false, true)
		end
		if effect.to:hasFlag(self:toString().."drawCard") then
			effect.to:drawCards(1, self:objectName())
		end
		return false
	end,
}

ny_tenth_shuiyanqijun:clone():setParent(extension)

ny_10th_wupu = sgs.General(extension, "ny_10th_wupu", "qun", 4, true, false, false)

ny_10th_duanti = sgs.CreateTriggerSkill{
    name = "ny_10th_duanti",
    events = {sgs.CardUsed,sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or (card:isKindOf("SkillCard")) then return false end
        room:addPlayerMark(player, "&ny_10th_duanti", 1)
        if player:getMark("&ny_10th_duanti") >= 5 then
            room:setPlayerMark(player, "&ny_10th_duanti", 0)
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, 1))
            end
            if player:isAlive() and player:getMark("ny_10th_duanti_max") < 5 then
                room:addPlayerMark(player, "ny_10th_duanti_max", 1)
                room:gainMaxHp(player, 1, self:objectName())
            end
        end


    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

ny_10th_shicao = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_shicao",
    view_as = function(self)
        return ny_10th_shicaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("ny_10th_shicao_disable-Clear") == 0
    end
}

ny_10th_shicaoCard = sgs.CreateSkillCard
{
    name = "ny_10th_shicao",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local room = player:getRoom()
        local place = room:askForChoice(player, "ny_10th_shicao_place", "top+down")
        local kind = room:askForChoice(player, "ny_10th_shicao_type", "BasicCard+TrickCard+EquipCard", sgs.QVariant(place))
        local card_ids
        if place == "top" then
            card_ids = player:drawCardsList(1, self:objectName())
        else
            card_ids = player:drawCardsList(1, self:objectName(), false)
        end
        if player:isDead() then return false end
        local card = sgs.Sanguosha:getCard(card_ids:at(0))
        if (not card:isKindOf(kind)) then
            room:setPlayerMark(player, "ny_10th_shicao_disable-Clear", 1)
            local view
            if place == "top" then
                view = room:getNCards(2, true, false)
                room:returnToEndDrawPile(view)
            else
                view = room:getNCards(2, true, true)
                room:returnToTopDrawPile(view)
            end
            local log = sgs.LogMessage()
            if place == "top" then
                log.type = "$ViewEndDrawPile"
            else
                log.type = "$ViewDrawPile"
            end
            log.from = player
            log.card_str = table.concat(sgs.QList2Table(view), "+")
            room:sendLog(log, player)

            room:fillAG(view, player)
            room:askForAG(player, sgs.IntList(), true, self:objectName(), "@ny_10th_shicao:ny_10th_shicao_"..place)
            room:clearAG(player)
        end
    end
}

ny_10th_wupu:addSkill(ny_10th_duanti)
ny_10th_wupu:addSkill(ny_10th_shicao)

ny_10th_mouguanpin = sgs.General(extension, "ny_10th_mouguanpin", "shu", 4, true, false, false)

ny_10th_wuwei = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_wuwei",
    view_as = function(self)
        return ny_10th_wuweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (player:getMark("&ny_10th_wuwei_can-PlayClear") > 0)
        and (not player:isKongcheng())
    end,
}

ny_10th_wuweiCard = sgs.CreateSkillCard
{
    name = "ny_10th_wuwei",
    handling_method = sgs.Card_MethodUse,
    mute = true,
    filter = function(self, targets, to_select, player) 
		local pattern = "slash"
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
    target_fixed = function(self)		
		local pattern = "slash"
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)	
		local pattern = "slash"
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
    on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
        local use = card_use
        room:removePlayerMark(player, "&ny_10th_wuwei_can-PlayClear", 1)

        local log = sgs.LogMessage()
        log.type = "#ChoosePlayerWithSkill"
        log.from = player
        log.to = card_use.to
        log.arg = self:objectName()
        room:sendLog(log)
        room:broadcastSkillInvoke(self:objectName())

		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("_ny_10th_wuwei")

        local can_choose = ""
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isRed() then 
                can_choose = "red" 
                break
            end
        end
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:isBlack() then
                if can_choose ~= "" then
                    can_choose = can_choose.."+black"
                else
                    can_choose = "black"
                end
                break
            end
        end
        for _,card in sgs.qlist(player:getHandcards()) do
            if (not card:isRed()) and (not card:isBlack()) then 
                if can_choose ~= "" then
                    can_choose = can_choose.."+nocolor"
                else
                    can_choose = "nocolor"
                end
                break
            end
        end

        local color = room:askForChoice(player, self:objectName(), can_choose)
        if color == "red" then
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then 
                    slash:addSubcard(card)
                end
            end
        elseif color == "black" then
            for _,card in sgs.qlist(player:getHandcards()) do
                if card:isBlack() then 
                    slash:addSubcard(card)
                end
            end
        else
            for _,card in sgs.qlist(player:getHandcards()) do
                if (not card:isRed()) and (not card:isBlack()) then 
                    slash:addSubcard(card)
                end
            end 
        end

        local types = {}
        for _,id in sgs.qlist(slash:getSubcards()) do
            local card = sgs.Sanguosha:getCard(id)
            local ctype = card:getTypeId()
            if (not table.contains(types, ctype)) then
                table.insert(types, ctype)
            end
        end

        local targets = {}
        for _,p in sgs.qlist(use.to) do
            table.insert(targets, p:objectName())
        end

        local tag = sgs.QVariant()
        tag:setValue(slash:getSubcards())
        player:setTag("ny_10th_wuwei_card", tag)

        local num = #types
        local chosen = {}
        for i = 1, num, 1 do
            local choice = room:askForChoice(player, self:objectName(), "draw+lockdown+skill", sgs.QVariant(table.concat(targets, "+")))
            if (not table.contains(chosen, choice)) then
                table.insert(chosen, choice)
            end
            if choice == "draw" then
                player:drawCards(1, self:objectName())
            end
            if choice == "lockdown" then
                for _,p in sgs.qlist(use.to) do
                    if p:getMark("ny_10th_wuwei_lock") == 0 then
                        room:setPlayerMark(p, "ny_10th_wuwei_lock", 1)
                        room:addPlayerMark(p, "@skill_invalidity")
                    end
                end
            end
            if choice == "skill" then
                room:addPlayerMark(player, "ny_10th_wuwei_more-Clear", 1)
                room:addPlayerMark(player, "&ny_10th_wuwei_can-PlayClear", 1)
            end
        end

        room:setCardFlag(slash, "RemoveFromHistory")
        if #chosen == 3 then
            room:setCardFlag(slash, "ny_10th_wuwei")
        end
		return slash
	end
}

ny_10th_wuwei_clear = sgs.CreateTriggerSkill{
    name = "#ny_10th_wuwei_clear",
    events = {sgs.DamageCaused, sgs.EventPhaseStart,sgs.EventAcquireSkill},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ny_10th_wuwei") then
                room:sendLog(CreateDamageLog(damage, 1, "ny_10th_wuwei", true))
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                if (not player:hasSkill("ny_10th_wuwei")) then return false end
                room:setPlayerMark(player, "&ny_10th_wuwei_can-PlayClear", (1 + player:getMark("ny_10th_wuwei_more-Clear")))
            end

            if player:getPhase() == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("ny_10th_wuwei_lock") > 0 then
                        room:removePlayerMark(p, "ny_10th_wuwei_lock", 1)
                        room:removePlayerMark(p, "@skill_invalidity", 1)
                    end
                end
            end
        end
        if event == sgs.EventAcquireSkill then
            if data:toString() == "ny_10th_wuwei" and player:getPhase() == sgs.Player_Play then
                room:addPlayerMark(player, "&ny_10th_wuwei_can-PlayClear", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_wuwei_buff = sgs.CreateTargetModSkill{
    name = "#ny_10th_wuwei_buff",
    residue_func = function(self, from, card)
        if card:getSkillName() == "ny_10th_wuwei" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "ny_10th_wuwei" then return 1000 end
        return 0
    end,
}

ny_10th_mouguanpin:addSkill(ny_10th_wuwei)
ny_10th_mouguanpin:addSkill(ny_10th_wuwei_buff)
ny_10th_mouguanpin:addSkill(ny_10th_wuwei_clear)
extension:insertRelatedSkills("ny_10th_wuwei", "#ny_10th_wuwei_clear")
extension:insertRelatedSkills("ny_10th_wuwei", "#ny_10th_wuwei_buff")

ny_10th_sunli = sgs.General(extension, "ny_10th_sunli", "wei", 4, true, false, false)

ny_10th_kangli = sgs.CreateTriggerSkill{
    name = "ny_10th_kangli",
    events = {sgs.Damage,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            local card_ids = player:drawCardsList(2, self:objectName())
            if player:isAlive() then
                for _,id in sgs.qlist(card_ids) do
                    if room:getCardPlace(id) == sgs.Player_PlaceHand
                    and room:getCardOwner(id):objectName() == player:objectName() then
                        room:setCardFlag(id, "ny_10th_kangli")
                        room:setCardTip(id, "ny_10th_kangli")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_kangli_discard = sgs.CreateTriggerSkill{
    name = "#ny_10th_kangli_discard",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local ids = sgs.IntList()
        for _,card in sgs.qlist(player:getHandcards()) do
            if card:hasFlag("ny_10th_kangli") then
                ids:append(card:getId())
            end
        end
        if ids:isEmpty() then return false end

        room:sendCompulsoryTriggerLog(player, "ny_10th_kangli")
        local log = sgs.LogMessage()
        log.type = "$DiscardCard"
        log.from = player
        log.card_str = table.concat(sgs.QList2Table(ids), "+")
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), "ny_10th_kangli", "")
        local move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sunli:addSkill(ny_10th_kangli)
ny_10th_sunli:addSkill(ny_10th_kangli_discard)
extension:insertRelatedSkills("ny_10th_kangli", "#ny_10th_kangli_discard")

ny_10th_mou_hucheer = sgs.General(extension, "ny_10th_mou_hucheer", "qun", 4, true, false, false)

ny_10th_kongwu = sgs.CreateViewAsSkill
{
    name = "ny_10th_kongwu",
    change_skill = true,
    n = 999,
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMaxHp()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cc = ny_10th_kongwuCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_kongwu"))
    end
}

ny_10th_kongwuCard = sgs.CreateSkillCard
{
    name = "ny_10th_kongwu",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets < 1 and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "ny_10th_kongwu_target-PlayClear", 1)
        if effect.from:getChangeSkillState(self:objectName()) <= 1 then
            room:setChangeSkillState(effect.from, self:objectName(), 2)
            if effect.to:isDead() or effect.to:isNude() then return false end
            
            local discards = sgs.IntList()

            local max = math.min(self:subcardsLength(), effect.to:getCards("he"):length())

            for i = 1, max do--进行多次执行
                local id = room:askForCardChosen(effect.from, effect.to, "he", self:objectName(),
                    false,--选择卡牌时手牌不可见
                    sgs.Card_MethodDiscard,--设置为弃置类型
                    discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
                    i>1)--只有执行过一次选择才可取消
                if id < 0 then break end--如果卡牌id无效就结束多次执行
                discards:append(id)--将选择的id添加到虚拟卡的子卡表
            end

            room:throwCard(discards, "ny_10th_kongwu", effect.to, effect.from)

        elseif effect.from:getChangeSkillState(self:objectName()) == 2 then
            room:setChangeSkillState(effect.from, self:objectName(), 1)
            
            for i = 1, self:subcardsLength() do
                if effect.to:isAlive() then
                    local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                    card:setSkillName("_ny_10th_kongwu_slash")
                    room:useCard(sgs.CardUseStruct(card, effect.from, effect.to, true), false)
                end
            end

        end
    end

}

ny_10th_kongwu_buff = sgs.CreateTriggerSkill{
    name = "#ny_10th_kongwu_buff",
    events = {sgs.EventPhaseEnd,sgs.DrawNCards},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then
                for _,pl in sgs.qlist(room:getOtherPlayers(player)) do
                    if pl:getMark("ny_10th_kongwu_target-PlayClear") > 0 then
                        if pl:getHp() <= player:getHp() and pl:getHandcardNum() <= player:getHandcardNum() then
                            room:setPlayerMark(pl, "&ny_10th_kongwu-SelfClear", 1)
                        end
                    end
                end
            end
        end
        if event == sgs.DrawNCards then
            if player:getMark("&ny_10th_kongwu-SelfClear") > 0 then
                local draw = data:toDraw()
                if draw.reason ~= "draw_phase" then return false end
                room:sendCompulsoryTriggerLog(player, "ny_10th_kongwu", true, true)
                draw.num = draw.num - 1
                data:setValue(draw)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_kongwu_limit = sgs.CreateCardLimitSkill
{
    name = "#ny_10th_kongwu_limit",
    limit_list = function(self, player)
        if player:getMark("&ny_10th_kongwu-SelfClear") > 0 and (player:getPhase() ~= sgs.Player_NotActive) then
            return "effect"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("&ny_10th_kongwu-SelfClear") > 0 and (player:getPhase() ~= sgs.Player_NotActive) then 
            return ".|.|.|."
        end
    end
}


ny_10th_mou_hucheer:addSkill(ny_10th_kongwu)
ny_10th_mou_hucheer:addSkill(ny_10th_kongwu_buff)
ny_10th_mou_hucheer:addSkill(ny_10th_kongwu_limit)
extension:insertRelatedSkills("ny_10th_kongwu", "#ny_10th_kongwu_buff")
extension:insertRelatedSkills("ny_10th_kongwu", "#ny_10th_kongwu_limit")

ny_10th_spzhenji = sgs.General(extension, "ny_10th_spzhenji", "qun", 3, false, false, false)

ny_10th_jijie = sgs.CreateTriggerSkill{
    name = "ny_10th_jijie",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        if player:getMark("ny_10th_jijie_card-Clear") > 0 then return false end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() ~= player:objectName() 
        and move.to_place == sgs.Player_PlaceHand then
            local target = room:findPlayerByObjectName(move.to:objectName())
            if target:getPhase() == sgs.Player_NotActive then
                room:addPlayerMark(player, "ny_10th_jijie_card-Clear", 1)
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(move.card_ids:length(), self:objectName())
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_jijie_recover = sgs.CreateTriggerSkill{
    name = "#ny_10th_jijie_recover",
    events = {sgs.HpRecover},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_NotActive then
            local recover = data:toRecover()
            local num = recover.recover
            for _,p in sgs.qlist(room:findPlayersBySkillName("ny_10th_jijie")) do
                if p:getMark("ny_10th_jijie_recover-Clear") == 0 and p:isWounded() 
                and p:objectName() ~= player:objectName() then
                    room:addPlayerMark(p, "ny_10th_jijie_recover-Clear", 1)
                    room:sendCompulsoryTriggerLog(p, "ny_10th_jijie", true, true)
                    room:recover(p, sgs.RecoverStruct("ny_10th_jijie", p, num))
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_huiji = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_huiji",
    view_as = function(self)
        return ny_10th_huijiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_10th_huiji"))
    end
}

local function GetPath()
    local info = debug.getinfo(1, "S") -- 第二个参数 "S" 表示仅返回 source,short_src等字段， 其他还可以 "n", "f", "I", "L"等 返回不同的字段信息
    local path = info.source
    path = string.sub(path, 2, -1)
    path = string.match(path, "^.*\\")
    path = string.gsub(path, "\\", "/")
    return path
end

ny_10th_huijiCard = sgs.CreateSkillCard
{
    name = "ny_10th_huiji",
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local data = sgs.QVariant()
        data:setValue(effect.to)
        local choice = room:askForChoice(effect.from, self:objectName(), "draw+equip", data)
        if choice == "draw" then
            effect.to:drawCards(2, self:objectName())
        else
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("EquipCard") and (card:isAvailable(effect.to)) then
                    room:useCard(sgs.CardUseStruct(card, effect.to, effect.to, false), true)
                    break
                end
            end
        end

        if effect.to:isAlive() and effect.to:getHandcardNum() >= room:getAlivePlayers():length() then
            local card = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("_ny_10th_huiji_mazing_grace")
            --room:useCard(sgs.CardUseStruct(card, effect.to, nil, false), true)

            local data = sgs.QVariant()
            local players = sgs.SPlayerList()
            players:append(effect.from)
            for _,p in sgs.qlist(room:getOtherPlayers(effect.from)) do
                players:append(p)
            end
            local use = sgs.CardUseStruct(card, effect.to, players)
            data:setValue(use)
            room:getThread():trigger(sgs.PreCardUsed, room, effect.to, data)

            local log = sgs.LogMessage()
            log.type = "$ny_10th_huiji_log"
            log.from = effect.to
            log.to = room:getAlivePlayers()
            log.arg = "ny_10th_jijie_ama"
            room:sendLog(log)

			--room:getThread():trigger(sgs.CardUsed, room, effect.to, data)
            for _,p in sgs.qlist(use.to) do
                room:getThread():trigger(sgs.TargetConfirmed, room, p, data)
            end

            if effect.to:isDead() then return false end

            local cards = sgs.IntList()
            for _,hand in sgs.qlist(effect.to:getHandcards()) do
                cards:append(hand:getEffectiveId())
            end

            room:fillAG(cards)

            local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.to:objectName(), self:objectName(),"")
            local move1 = sgs.CardsMoveStruct(cards, effect.to, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, reason1)
            room:moveCardsAtomic(move1,true)

            local list = sgs.QVariant()
            list:setValue(cards)
            room:setTag("AmazingGrace", list)

            for _,p in sgs.qlist(use.to) do
                if p:isAlive() then
                    room:cardEffect(card, effect.to, p)
                end
            end

            local remainder = sgs.IntList()
            for _,id in sgs.qlist(cards) do
                if room:getCardPlace(id) == sgs.Player_PlaceTable then
                    remainder:append(id)
                end
            end

            room:clearAG()

            if (not remainder:isEmpty()) then
                if effect.to:isAlive() then
                    local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, effect.to:objectName(), self:objectName(),"")
                    local move2 = sgs.CardsMoveStruct(remainder, nil, effect.to, sgs.Player_PlaceTable, sgs.Player_PlaceHand, reason2)
                    room:moveCardsAtomic(move2,true)
                else
                    local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName(), self:objectName(),"")
                    local move2 = sgs.CardsMoveStruct(remainder, nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, reason2)
                    room:moveCardsAtomic(move2,true)
                end
            end

            room:getThread():trigger(sgs.CardFinished, room, effect.to, data)
        end
    end
}

ny_10th_spzhenji:addSkill(ny_10th_jijie)
ny_10th_spzhenji:addSkill(ny_10th_jijie_recover)
ny_10th_spzhenji:addSkill(ny_10th_huiji)
extension:insertRelatedSkills("ny_10th_jijie", "#ny_10th_jijie_recover")

ny_10th_panghui_second =  sgs.General(extension, "ny_10th_panghui_second", "wei", 5, true, false, false)

ny_10th_yiyong = sgs.CreateTriggerSkill{
    name = "ny_10th_yiyong",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:objectName() == player:objectName() then return false end
        if not (player:canDiscard(player, "he") and damage.to:canDiscard(damage.to, "he")) then return false end

        local skill_data = sgs.QVariant()
        skill_data:setValue(damage.to)
        if not room:askForSkillInvoke(player, self:objectName(), skill_data) then return false end
        room:broadcastSkillInvoke(self:objectName())

        local self_dis = room:askForExchange(player, self:objectName(), 9999, 1, true, "@ny_10th_yiyong-discard:"..damage.to:getGeneralName(), false)
        local target_dis = room:askForExchange(damage.to, self:objectName(), 9999, 1, true, "@ny_10th_yiyong-discard:"..player:getGeneralName(), false)
        
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "ny_10th_yiyong", "")
        local move = sgs.CardsMoveStruct(self_dis:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)
        local log = sgs.LogMessage()
        log.type = "$DiscardCard"
        log.from = player
        log.card_str = table.concat(sgs.QList2Table(self_dis:getSubcards()), "+")
        room:sendLog(log)

        reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, damage.to:objectName(), "ny_10th_yiyong", "")
        move = sgs.CardsMoveStruct(target_dis:getSubcards(), nil, sgs.Player_DiscardPile, reason)
        room:moveCardsAtomic(move, true)
        log.from = damage.to
        log.card_str = table.concat(sgs.QList2Table(target_dis:getSubcards()), "+")
        room:sendLog(log)

        local self_sum = 0
        for _,id in sgs.qlist(self_dis:getSubcards()) do
            self_sum = self_sum + sgs.Sanguosha:getCard(id):getNumber()
        end
        local target_sum = 0
        for _,id in sgs.qlist(target_dis:getSubcards()) do
            target_sum = target_sum + sgs.Sanguosha:getCard(id):getNumber()
        end

        if self_sum <= target_sum then
            player:drawCards(target_dis:subcardsLength() + 1, self:objectName())
        end

        if self_sum >= target_sum then
            room:sendLog(CreateDamageLog(damage, 1, self:objectName(), true))
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_suchou = sgs.CreateTriggerSkill{
    name = "ny_10th_suchou",
    events = {sgs.EventPhaseStart,sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then 
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local choices = "losehp+losemaxhp+loseskill"
            local choice = room:askForChoice(player, self:objectName(), choices)
            if choice == "losehp" then room:loseHp(player, 1, true, player, self:objectName()) end
            if choice == "losemaxhp" then room:loseMaxHp(player, 1) end
            if choice == "loseskill" then 
                room:detachSkillFromPlayer(player, self:objectName())
                return false
            end
            room:setPlayerMark(player, "&ny_10th_suchou-PlayClear", 1)
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getMark("&ny_10th_suchou-PlayClear") == 0 then return false end
            if use.card:isKindOf("SkillCard") then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            local no_respond_list = use.no_respond_list
            for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                table.insert(no_respond_list, other:objectName())
            end
            use.no_respond_list = no_respond_list
            data:setValue(use)

            --只有需要其他角色响应的牌再放语音，不然太吵了
            if (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
                room:broadcastSkillInvoke(self:objectName())
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getPhase() == sgs.Player_Play
        --只在出牌阶段有效
    end,
}

ny_10th_panghui_second:addSkill(ny_10th_yiyong)
ny_10th_panghui_second:addSkill(ny_10th_suchou)

ny_10th_weizhangliao = sgs.General(extension, "ny_10th_weizhangliao", "qun", 4, true, false, false)

ny_10th_yuxi = sgs.CreateTriggerSkill{
    name = "ny_10th_yuxi",
    events = {sgs.DamageCaused,sgs.DamageInflicted},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            local card_id = player:drawCardsList(1, self:objectName()):at(0)
            if room:getCardOwner(card_id):objectName() == player:objectName() then
                room:setCardFlag(card_id, "ny_10th_yuxi")
                room:setCardFlag(card_id, "RemoveFromHistory")
                room:setCardTip(card_id, "ny_10th_yuxi")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_yuxi_buff = sgs.CreateTargetModSkill{
    name = "#ny_10th_yuxi_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        local extra = 0
        if card:hasFlag("ny_10th_yuxi") then extra = 1000 end
        return extra
    end,
}

ny_10th_porong = sgs.CreateTriggerSkill{
    name = "ny_10th_porong",
    events = {sgs.CardUsed,sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if (not use.card:isDamageCard()) then
                room:setPlayerMark(player, "&ny_10th_porong", 0)
                return false
            end
            if player:getMark("&ny_10th_porong") == 0 then
                room:setPlayerMark(player, "&ny_10th_porong", 1)
                return false
            else
                if (not use.card:isKindOf("Slash")) then return false end
            end

            for _,to in sgs.qlist(use.to) do
                local skill_data = sgs.QVariant()
                skill_data:setValue(to)
                if room:askForSkillInvoke(player, self:objectName(), skill_data) then
                    room:setPlayerMark(player, "&ny_10th_porong", 0)
                    --发动技能就清除标记，不发动这张杀仍然可以计算成连招中的伤害牌

                    room:broadcastSkillInvoke(self:objectName())
                    --杀对其额外结算一次
                    room:setCardFlag(use.card, "ny_10th_porong+"..to:objectName())
                    room:setCardFlag(use.card, "ny_10th_porong")
                    --获得该角色及其相邻角色各一张手牌
                    local targets = {}
                    table.insert(targets, to)
                    for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                        if other:isAdjacentTo(to) and other:objectName() ~= to:objectName() then
                            table.insert(targets, other)
                        end
                    end
                    for _,target in ipairs(targets) do
                        if target:isAlive() and (not target:isKongcheng())
                        and player:isAlive() then
                            local get = room:askForCardChosen(player, target, "h", self:objectName())
                            room:obtainCard(player, get, false)
                        end
                    end
                end
            end
        end

        if event == sgs.CardFinished then
            --处理额外结算
            local use = data:toCardUse()
            if (not use.card:hasFlag("ny_10th_porong")) then return false end
            room:setCardFlag(use.card, "-ny_10th_porong")
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
                local targets = sgs.SPlayerList()
                for _,to in sgs.qlist(use.to) do
                    if use.card:hasFlag("ny_10th_porong+"..to:objectName()) and to:isAlive() then
                        room:setCardFlag(use.card, "-ny_10th_porong+"..to:objectName())
                        targets:append(to)
                    end
                end
                if (not targets:isEmpty()) then
                    local use_again = sgs.CardUseStruct(use.card,player,targets)
				    room:setTag("UseHistory"..use.card:toString(),ToData(use_again))
				    use.card:use(room,player,targets)
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_weizhangliao:addSkill(ny_10th_yuxi)
ny_10th_weizhangliao:addSkill(ny_10th_yuxi_buff)
ny_10th_weizhangliao:addSkill(ny_10th_porong)
extension:insertRelatedSkills("ny_10th_yuxi", "#ny_10th_yuxi_buff")

--用处懂得都懂
global_fuckusetimes = sgs.CreateTriggerSkill{
    name = "global_fuckusetimes",
    global = true,
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:hasFlag("RemoveFromHistory") then
            use.m_addHistory = false
            data:setValue(use)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_shimashi = sgs.General(extension, "ny_10th_shimashi", "wei", 3, true, false, false)

ny_10th_zhenrao = sgs.CreateTriggerSkill{
    name = "ny_10th_zhenrao",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.from == player or use.to:contains(player) then 
            local targets = sgs.SPlayerList()
            if use.from:getHandcardNum() > player:getHandcardNum()
            and use.from:getMark("ny_10th_zhenrao_"..player:objectName().."-Clear") == 0 then
                targets:append(use.from)
            end
            if use.to:contains(use.from) then
                use.to:removeOne(use.from)
            end
            for _,to in sgs.qlist(use.to) do
                if to:getHandcardNum() > player:getHandcardNum()
                and to:getMark("ny_10th_zhenrao_"..player:objectName().."-Clear") == 0 then
                    targets:append(to)
                end
            end
            if (not targets:isEmpty()) then 
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ny_10th_zhenrao-damage", true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(target, "ny_10th_zhenrao_"..player:objectName().."-Clear", 1)
                    local damage = sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal)
                    room:damage(damage)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_sanshi = sgs.CreateTriggerSkill{
    name = "ny_10th_sanshi",
    events = {sgs.GameStart,sgs.CardUsed,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        --标记死士
        if event == sgs.GameStart then
            if (not player:hasSkill(self:objectName())) then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local all_cards = {}
            for i = 1, 13 , 1 do
                table.insert(all_cards, {})
            end
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                local num = card:getNumber()
                table.insert(all_cards[num],card)
            end
            for _,cards in ipairs(all_cards) do
                local num = #cards
                if num > 0 then
                    local sishi = cards[math.random(1,num)]
                    sishi:setTag("ny_10th_sishi", sgs.QVariant(true))
                end
            end
        end

        --令死士不能被响应
        if event == sgs.CardUsed then
            if (not player:hasSkill(self:objectName())) then return false end
            local use = data:toCardUse()
            if (not use.card) or (not use.card:getTag("ny_10th_sishi"):toBool()) then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            local no_respond_list = use.no_respond_list
            table.insert(no_respond_list, "_ALL_TARGETS")
            use.no_respond_list = no_respond_list
            data:setValue(use)
        end

        --为进入手牌的死士添加可见标记
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to_place == sgs.Player_PlaceHand then
                for _,id in sgs.qlist(move.card_ids) do
                    local card  = sgs.Sanguosha:getCard(id)
                    if card:getTag("ny_10th_sishi"):toBool() then
                        room:setCardTip(id, "ny_10th_sishi")
                    end
                end
            end
        end

        --记录进入弃牌堆的死士
        if event == sgs.CardsMoveOneTime then
            if (not player:hasSkill(self:objectName())) then return false end
            local move = data:toMoveOneTime()
            if (move.to_place ~= sgs.Player_DiscardPile) then return false end
            if move.from and move.from:hasSkill(self:objectName()) 
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE) then return false end
            local add = {}
            for _,id in sgs.qlist(move.card_ids) do
                local card  = sgs.Sanguosha:getCard(id)
                if card:getTag("ny_10th_sishi"):toBool() then
                    table.insert(add, id)
                end
            end
            if #add > 0 then
                local list = player:getTag("ny_10th_sanshi"):toIntList()
                if (not list) then list = sgs.IntList() end
                for _,id in ipairs(add) do
                    if (not list:contains(id)) then list:append(id) end
                end
                player:removeTag("ny_10th_sanshi")
                local tag = sgs.QVariant()
                tag:setValue(list)
                player:setTag("ny_10th_sanshi", tag)
            end
        end

        --从弃牌堆获得死士
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local list = p:getTag("ny_10th_sanshi"):toIntList()
                    if list then
                        p:removeTag("ny_10th_sanshi")
                        local obtain = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        for _,id in sgs.qlist(room:getDiscardPile()) do
                            if list:contains(id) then
                                obtain:addSubcard(id)
                            end
                        end
                        if obtain:subcardsLength() > 0 then
                            room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
                            room:obtainCard(p, obtain, true)
                        end
                        obtain:deleteLater()
                    end
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_10th_chenlvevs = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_10th_chenlve",
    view_as = function()
        return ny_10th_chenlveCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@ny_10th_chenlve_mark") > 0
    end,
}

ny_10th_chenlve = sgs.CreateTriggerSkill{
    name = "ny_10th_chenlve",
    events = {sgs.EventPhaseEnd,sgs.Death},
    view_as_skill = ny_10th_chenlvevs,
    frequency = sgs.Skill_Limited,
    limit_mark = "@ny_10th_chenlve_mark",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		if event==sgs.Death then
            local death = data:toDeath()
			if death.who==player and player:getMark("ny_10th_chenlve")>0 then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				local ids = player:getTag("ny_10th_chenlve"):toIntList()
				room:throwCard(ids,self:objectName(),nil)
			end
		elseif player:getPhase()==sgs.Player_Play and player:getMark("ny_10th_chenlve")>0 then
            local ids = player:getTag("ny_10th_chenlve"):toIntList()
			if room:getCardPlace(ids:last())==sgs.Player_PlaceTable then return end
            room:sendCompulsoryTriggerLog(player,self:objectName())
			room:breakCard(ids,player)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_10th_chenlveCard = sgs.CreateSkillCard
{
    name = "ny_10th_chenlve",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local room = player:getRoom()
        room:setPlayerMark(player, "@ny_10th_chenlve_mark", 0)
        room:setPlayerMark(player, "ny_10th_chenlve", 1)
        local list = sgs.IntList()
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card  = sgs.Sanguosha:getCard(id)
            if card:getTag("ny_10th_sishi"):toBool() then
                list:append(id)
            end
        end
        for _,id in sgs.qlist(room:getDiscardPile()) do
            local card  = sgs.Sanguosha:getCard(id)
            if card:getTag("ny_10th_sishi"):toBool() then
                list:append(id)
            end
        end
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            local cards = p:getCards("hej")
            for _,card in sgs.qlist(cards) do
                if card:getTag("ny_10th_sishi"):toBool() then
                    list:append(card:getId())
                end
            end
        end
        if (not list:isEmpty()) then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(list, player, sgs.Player_PlaceHand, reason)
            room:moveCardsAtomic(move, true)
            player:removeTag("ny_10th_chenlve")
            local tag = sgs.QVariant()
            tag:setValue(list)
            player:setTag("ny_10th_chenlve", tag)
            --只移除因此技能摸的死士牌，所以这里要标记一下，不要修改哦
        end
    end
}

ny_10th_shimashi:addSkill(ny_10th_zhenrao)
ny_10th_shimashi:addSkill(ny_10th_sanshi)
ny_10th_shimashi:addSkill(ny_10th_chenlve)









local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("ny_10th_jiaoxia_filter") then skills:append(ny_10th_jiaoxia_filter) end
if not sgs.Sanguosha:getSkill("ny_10th_taji") then skills:append(ny_10th_taji) end
if not sgs.Sanguosha:getSkill("ny_10th_qinghuang") then skills:append(ny_10th_qinghuang) end
if not sgs.Sanguosha:getSkill("ny_tenth_dagongche_slash") then skills:append(ny_tenth_dagongche_slash) end
if not sgs.Sanguosha:getSkill("ny_tenth_dagongche_slashtr") then skills:append(ny_tenth_dagongche_slashtr) end
if not sgs.Sanguosha:getSkill("#ny_tenth_dagongche_destory") then skills:append(ny_tenth_dagongche_destory) end
if not sgs.Sanguosha:getSkill("ny_tenth_dagongche_buff") then skills:append(ny_tenth_dagongche_buff) end
if not sgs.Sanguosha:getSkill("ny_10th_paiyi") then skills:append(ny_10th_paiyi) end
if not sgs.Sanguosha:getSkill("ny_10th_shoutan") then skills:append(ny_10th_shoutantr) end
if not sgs.Sanguosha:getSkill("ny_tenth_piliche_target") then skills:append(ny_tenth_piliche_target) end
if not sgs.Sanguosha:getSkill("ny_tenth_piliche_buff") then skills:append(ny_tenth_piliche_buff) end
if not sgs.Sanguosha:getSkill("ny_tenth_piliche_destory") then skills:append(ny_tenth_piliche_destory) end
if not sgs.Sanguosha:getSkill("ny_tenth_piliche_recover") then skills:append(ny_tenth_piliche_recover) end
if not sgs.Sanguosha:getSkill("ny_10th_shouze") then skills:append(ny_10th_shouze) end
if not sgs.Sanguosha:getSkill("ny_10th_aoshi_give") then skills:append(ny_10th_aoshi_give) end
if not sgs.Sanguosha:getSkill("ny_10th_fudou") then skills:append(ny_10th_fudou) end
if not sgs.Sanguosha:getSkill("ny_tenth_wuyou_other") then skills:append(ny_tenth_wuyou_other) end
--用处懂得都懂
if not sgs.Sanguosha:getSkill("global_fuckusetimes") then skills:append(global_fuckusetimes) end

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
    ["sgs10th"] = "三国杀十周年",

--许靖
    ["ny_10th_xujing"] = "许靖[十周年]", 
	["&ny_10th_xujing"] = "许靖",
    ["#ny_10th_xujing"] = "璞玉有瑕",
    ["designer:ny_10th_xujing"] = "官方",
	["cv:ny_10th_xujing"] = "官方",
	["illustrator:ny_10th_xujing"] = "官方",

    ["ny_10th_caixia"] = "才瑕",
    [":ny_10th_caixia"] = "当你造成或受到伤害后，你可摸至多x张牌（x为游戏人数且最多为5）。若如此做，你无法发动此技能，直到你累计使用了等量的牌。",
    [":&ny_10th_caixia"] = "再使用 %src 张牌才可发动“才瑕”",
    ["ny_10th_shangyu"] = "赏誉",
    [":ny_10th_shangyu"] = "锁定技，游戏开始时你获得一张【杀】并标记之，然后将之交给一名角色。此【杀】造成伤害后你和使用者各摸一张牌；进入弃牌堆后你将之交给一名本回合未以此法指定过的角色。",
    ["@ny_10th_shangyu"] = "请将此【杀】交给一名本回合未以此法指定过的角色",

    ["$ny_10th_caixia1"] = "吾习扫天下之术，不善净一屋之秽。",
	["$ny_10th_caixia2"] = "玉有十色五光，微瑕难掩其瑜。",
	["$ny_10th_shangyu1"] = "君满腹才学，当为国之大器。",
	["$ny_10th_shangyu2"] = "一腔青云之志，正待梦日之时。",
    ["~ny_10th_xujing"] = "时人如江鲫，所逐者功利尔。",

--周妃
    ["ny_10th_lezhoufei"] = "乐周妃[十周年]",
    ["&ny_10th_lezhoufei"] = "周妃",
    ["#ny_10th_lezhoufei"] = "芙蓉泣露",
    ["designer:ny_10th_lezhoufei"] = "官方",
	["cv:ny_10th_lezhoufei"] = "官方",
	["illustrator:ny_10th_lezhoufei"] = "官方",

    ["ny_10th_lingkong"] = "灵箜",
    [":ny_10th_lingkong"] = "锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。你于回合外获得牌后，随机将其中一张标记为“箜篌”牌。",
    ["ny_10th_konghou"] = "箜篌",
    ["ny_10th_xianshu"] = "贤淑",
    [":ny_10th_xianshu"] = "出牌阶段，你可以展示一张“箜篌”牌并交给一名其他角色。\
    若此牌为红色，且该角色体力值小于等于你，该角色回复1点体力；\
    若此牌为黑色，且该角色体力值大于等于你，该角色失去1点体力。\
    然后，你摸X张牌（X为你与该角色体力值之差且至多为5）。",

    ["$ny_10th_lingkong1"] = "箜篌奏晚歌，渔樵有归期。",
	["$ny_10th_lingkong2"] = "吴宫绿荷惊涟漪，飞燕啄新泥。",
	["$ny_10th_xianshu1"] = "居宠而不骄，秉贤淑于内庭。",
	["$ny_10th_xianshu2"] = "心怀玲珑意，宜家国于春秋。",
    ["~ny_10th_lezhoufei"] = "红颜薄命，望君珍重。",

--董绾

    ["ny_10th_donghuan"] = "董绾[十周年]",
    ["&ny_10th_donghuan"] = "董绾",
    ["#ny_10th_donghuan"] = "蜜言如鸩",
    ["designer:ny_10th_donghuan"] = "官方",
	["cv:ny_10th_donghuan"] = "官方",
	["illustrator:ny_10th_donghuan"] = "游漫美绘",

    ["ny_10th_shengdu"] = "生妒",
    [":ny_10th_shengdu"] = "回合开始时，你可以选择一名角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
    ["@ny_10th_shengdu"] = "你可以选择一名角色，该角色下个摸牌阶段摸牌后，你摸等量的牌",
    ["ny_10th_jieling"] = "介绫",
    [":ny_10th_jieling"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。若此【杀】：造成伤害，其失去1点体力；没造成伤害，你对其发动一次“生妒”。",
   
    ["$ny_10th_shengdu1"] = "姐姐有的，妹妹也要有。",
	["$ny_10th_shengdu2"] = "你我同为佳丽，凭甚汝得独宠？",
	["$ny_10th_jieling1"] = "来人，送冯氏上路！",
	["$ny_10th_jieling2"] = "我有一求，请姐姐赴之。",
    ["~ny_10th_donghuan"] = "陛下饶命，妾并无歹意。",
    
--高翔
    ["ny_10th_gaoxiang"] = "高翔[十周年]",
    ["&ny_10th_gaoxiang"] = "高翔",
    ["#ny_10th_gaoxiang"] = "玄乡侯",
    ["designer:ny_10th_gaoxiang"] = "官方",
	["cv:ny_10th_gaoxiang"] = "官方",
	["illustrator:ny_10th_gaoxiang"] = "黯荧岛工作室",

    ["ny_10th_chiying"] = "驰应",
    [":ny_10th_chiying"] = "出牌阶段限一次，你可以选择一名体力值小于等于你的角色，令其攻击范围的其他角色各弃置一张牌。若你选择的是其他角色，其获得其中的基本牌。",
 
    ["$ny_10th_chiying1"] = "今诱老贼来此，必折其父子于上方谷。",
	["$ny_10th_chiying2"] = "列柳城既失，当下唯死守阳平关。",
    ["~ny_10th_gaoxiang"] = "老贼不死，实天意也。",

    --王濬

    ["ny_10th_wangrui"] = "王濬[十周年]",
    ["&ny_10th_wangrui"] = "王濬",
    ["#ny_10th_wangrui"] = "遏浪飞艨",
    ["designer:ny_10th_wangrui"] = "官方",
	["cv:ny_10th_wangrui"] = "官方",
	["illustrator:ny_10th_wangrui"] = "错落宇宙",

    ["ny_10th_tongye"] = "统业",
    [":ny_10th_tongye"] = "锁定技，游戏开始时/有角色死亡后，若场上现存势力数：\
    小于等于4：你手牌上限+3；\
    小于等于3：你攻击范围+3；\
    小于等于2：你出牌阶段出【杀】次数+3；\
    为1：你摸牌阶段摸牌数+3。 ",
    ["$ny_10th_tongye_kingdoms"] = "当前场上现存势力数为 %arg",
    ["$ny_10th_tongye_draw"] = "%from 因 %arg 的效果将多摸 %arg2 张牌",
    ["ny_10th_changqu"] = "长驱",
    [":ny_10th_changqu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，第一个目标角色获得战舰标记。获得战舰标记的角色需要选择一项 ：\
    1.交给你X张手牌，然后将战舰标记移动到下个目标；\
    2.下次受到的属性伤害+X，然后横置自身。\
    （X为选项一被选择的次数且至少为1）",
    ["@ny_10th_changqu"] = "请选择战舰标记的终点",
    ["$ny_10th_changqu_finish"] = "战舰的终点是 %to",
    ["$ny_10th_changqu_willdamgage"] = "%from 下次受到的属性伤害将增加 %arg 点",
    ["$ny_10th_changqu_damage"] = "%from 受到的属性伤害因 %arg 的效果由 %arg2 点增加到 %arg3 点",
    ["ny_10th_changqu_finish"] = "请交给 %src 共计 %arg 张手牌，或横置自身并使下次受到的属性伤害 +%arg",
    ["ny_10th_changqu_move"] = "请交给 %src 共计 %arg 张手牌,然后将战舰标记移动给下一名角色，或横置自身并使下次受到的属性伤害 +%arg",
   
    ["$ny_10th_tongye1"] = "白首全金瓯，著风流于春秋。",
	["$ny_10th_tongye2"] = "长戈斩王气，统大业于四海。",
	["$ny_10th_changqu1"] = "布横江之铁索，徒自缚尔。",
	["$ny_10th_changqu2"] = "艨艟击浪，可下千里江陵。",
    ["~ny_10th_wangrui"] = "未蹈曹刘之辙，险遭士载之厄。",

--董翓   
    ["ny_10th_dongxie"] = "董翓[十周年]",
    ["&ny_10th_dongxie"] = "董翓",
    ["#ny_10th_dongxie"] = "月辉映荼",
    ["designer:ny_10th_dongxie"] = "官方",
	["cv:ny_10th_dongxie"] = "官方",
	["illustrator:ny_10th_dongxie"] = "官方",

    ["ny_10th_jiaoxia"] = "狡黠",
    [":ny_10th_jiaoxia"] = "出牌阶段开始时，你可令你此阶段所有手牌视为【杀】。以此法使用的【杀】若造成伤害，你可于此【杀】结算完毕后使用原卡牌。出牌阶段，你对每名其他角色使用的第一张【杀】无次数限制。\
    注释：视为使用卡牌时须点一下技能才能选择目标[找到了原因，但先不修复]",
    ["ny_10th_jiaoxia:slash"] = "你可令你此阶段所有手牌视为【杀】",
    ["ny_10th_jiaoxia_filter"] = "手牌视为【杀】",
    ["@ny_10th_jiaoxia"] = "你可以视为使用了 【%src】", 
    ["ny_10th_humei"] = "狐魅",
    [":ny_10th_humei"] = "出牌阶段每项限一次，你可令一名体力值至多为x的角色（x为你本阶段造成的伤害次数）：1、摸一张牌；2、交给你一张牌；3、回复1点体力。",
    ["@ny_10th_humei"] = "请交给 %src 一张牌",
    ["ny_10th_humei:draw"] = "摸一张牌",
    ["ny_10th_humei:give"] = "交给你一张牌",
    ["ny_10th_humei:recover"] = "回复1点体力",

    ["$ny_10th_jiaoxia1"] = "暗剑匿踪，现时必捣黄龙。",
	["$ny_10th_jiaoxia2"] = "袖中藏刃，欲取诸君之头。",
	["$ny_10th_humei1"] = "尔为靴下之臣，当行顺我之事。",
	["$ny_10th_humei2"] = "妾身一笑，可倾将军之城否？",
    ["~ny_10th_dongxie"] = "覆巢之下，断无完卵余生。",

--裴元绍      
    ["ny_10th_peiyuanshao"] = "裴元绍[十周年]",
    ["&ny_10th_peiyuanshao"] = "裴元绍",
    ["#ny_10th_peiyuanshao"] = "买椟还珠",
    ["designer:ny_10th_peiyuanshao"] = "官方",
	["cv:ny_10th_peiyuanshao"] = "官方",
	["illustrator:ny_10th_peiyuanshao"] = "官方",

    ["ny_10th_moyu"] = "没欲",
    [":ny_10th_moyu"] = "出牌阶段，你可获得本阶段未以此法指定过的一名其他角色区域内的一张牌，然后该角色可选择是否对你使用一张【杀】，此【杀】伤害值为X（X为此技能本回合发动次数）。若此【杀】对你造成伤害，此技能本回合失效。",
    ["@ny_10th_moyu"] = "你可以对 %src 使用一张伤害为 %arg 的【杀】",
    ["$ny_10th_moyu_damage_add"] = "%from 受到的伤害因 %arg 的效果由 %arg2 点增加到了 %arg3 点",

	["$ny_10th_moyu1"] = "人之所有，我之所欲。",
	["$ny_10th_moyu2"] = "胸有欲壑千丈，自当饥不择食。",
    ["~ny_10th_peiyuanshao"] = "好生厉害的白袍小将。",

--孙翎鸾
    ["ny_10th_sunlinluan"] = "孙翎鸾[十周年]",
    ["&ny_10th_sunlinluan"] = "孙翎鸾",
    ["#ny_10th_sunlinluan"] = "弦凤栖梧",
    ["designer:ny_10th_sunlinluan"] = "官方",
	["cv:ny_10th_sunlinluan"] = "官方",
	["illustrator:ny_10th_sunlinluan"] = "官方",

    ["ny_10th_lingyue"] = "聆乐",
    [":ny_10th_lingyue"] = "锁定技，一名角色在本轮首次造成伤害后，你摸1张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。",
    ["ny_pandi_tenth"] = "盼睇",
    ["ny_pandi_tenth_use"] = "盼睇",
    [":ny_pandi_tenth"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段使用的下一张牌，视为该角色使用。",
    ["@ny_pandi_tenth"] = "你可以为 %src 使用一张手牌",
    ["$ny_pandi_tenth_usecard_targetfixed"] = "%from 令 %to 使用了 %card",
    ["$ny_pandi_tenth_usecard_nottargetfixed"] = "%from 令 %arg 使用了 %card, 目标是 %to",

    ["$ny_10th_lingyue1"] = "宫商催角羽，仙乐自可聆。",
	["$ny_10th_lingyue2"] = "玉琶奏折柳，天地尽箫声。",
	["$ny_pandi_tenth1"] = "待君归时，共泛轻舟于湖海。",
	["$ny_pandi_tenth2"] = "妾有一曲，可壮卿之峥嵘。",
    ["~ny_10th_sunlinluan"] = "良人当归，苦酒何妨。",

--乐綝

    ["ny_10th_lelin"] = "乐綝[十周年]",
    ["&ny_10th_lelin"] = "乐綝",
    ["#ny_10th_lelin"] = "广昌亭侯",
    ["designer:ny_10th_lelin"] = "官方",
	["cv:ny_10th_lelin"] = "官方",
	["illustrator:ny_10th_lelin"] = "官方",

    ["ny_tenth_porui"] = "破锐",
    [":ny_tenth_porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，然后你交给其X张手牌（X为其失去的牌数且最多为5，手牌不足X张则全给）。",
    [":ny_tenth_porui1"] = "每轮限两次，其他角色的结束阶段，你可以弃置一张牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，然后你交给其X张手牌（X为其失去的牌数且最多为5，手牌不足X张则全给）。",
    [":ny_tenth_porui2"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】（X为其失去的牌数且最多为5，手牌不足X张则全给）。",
    [":ny_tenth_porui3"] = "每轮限两次，其他角色的结束阶段，你可以弃置一张牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】（X为其失去的牌数且最多为5，手牌不足X张则全给）。",
    ["@ny_tenth_porui"] = "你可以弃置一张牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】",
    ["ny_tenth_porui_give"] = "请交给 %src 共计 %arg 张手牌",
    ["ny_10th_gonghu"] = "共护",
    [":ny_10th_gonghu"] = "锁定技，你的回合外，当你于一回合内失去超过1张基本牌后，{破锐}改为每轮限2次；当你于一回合内造成或受到超过1点伤害后，你将{破锐}中的“交给”的效果删除。若以上两个效果均已触发，则你本局游戏接下来你使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",
    ["$ny_10th_gonghu_noresponse"] = "%from 使用的 %card 因 %arg 的效果不可被响应",
    ["@ny_10th_gonghu"] = "你可以为【%src】增加一个目标",

    ["$ny_tenth_porui1"] = "承父勇烈，问此间谁堪敌手。",
	["$ny_tenth_porui2"] = "敌锋虽锐，吾亦击之如破卵。",
	["$ny_10th_gonghu1"] = "大都督中伏，吾等当舍命救之。",
	["$ny_10th_gonghu2"] = "袍泽临难，但有共死而无坐视。",
    ["~ny_10th_lelin"] = "天下犹魏，公休何故如此？",

--杜预
    ["ny_10th_duyu"] = "杜预[十周年]",
    ["&ny_10th_duyu"] = "杜预",
    ["#ny_10th_duyu"] = "文成武德",
    ["designer:ny_10th_duyu"] = "官方",
	["cv:ny_10th_duyu"] = "官方",
	["illustrator:ny_10th_duyu"] = "官方",

    ["ny_10th_jianguo"] = "谏国",
    [":ny_10th_jianguo"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向下取整）；令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）。",
    ["ny_10th_jianguo:draw"] = "令其弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）",
    ["ny_10th_jianguo:dis"] = "令其摸一张牌然后弃置一半的手牌（向下取整）",
    ["ny_10th_qinshi"] = "倾势",
    [":ny_10th_qinshi"] = "当你于回合内使用【杀】或锦囊牌指定一名其他角色为目标后，若此牌是你本回合使用的第X张牌，你可对其中一名目标角色造成一点伤害。（X为你的手牌数）",
    ["@ny_10th_qinshi"] = "你可对其中一名目标角色造成一点伤害",

    ["$ny_10th_jianguo1"] = "彭蠡雁惊，此诚平吴之时。",
	["$ny_10th_jianguo2"] = "奏三陈之诏，谏一国之弊。",
	["$ny_10th_qinshi1"] = "潮起万丈之仞，可阻江南春风。",
	["$ny_10th_qinshi2"] = "缮甲兵，耀威武，伐吴指日可待。",
    ["~ny_10th_duyu"] = "六合即归一统，奈何寿数已尽。",

--孙寒华
    ["ny_10th_sunhanhua"] = "孙寒华[十周年]",
    ["&ny_10th_sunhanhua"] = "孙寒华",
    ["#ny_10th_sunhanhua"] = "青丝慧剑",
    ["designer:ny_10th_sunhanhua"] = "官方",
	["cv:ny_10th_sunhanhua"] = "官方",
	["illustrator:ny_10th_sunhanhua"] = "官方",

    ["ny_10th_huiling"] = "汇灵",
    [":ny_10th_huiling"] = "锁定技，弃牌堆中的红色牌数量多于黑色牌时，你使用牌时回复1点体力；弃牌堆中黑色牌数量多于红色牌时，你使用牌时可弃置一名其他角色一张牌；你使用弃牌堆中颜色较少的牌时获得一个“灵”标记。",
    ["@ny_10th_huiling"] = "你可弃置一名其他角色一张牌",
    ["ny_10th_huiling_ling"] = "灵",
    ["ny_10th_chongxu"] = "冲虚",
    [":ny_10th_chongxu"] = "限定技，出牌阶段，若“灵”的数量大于等于4，你可以失去“汇灵”，增加等量的体力上限，并获得“踏寂”和“青荒”。",
    ["ny_10th_taji"] = "踏寂",
    [":ny_10th_taji"] = "你失去手牌时，根据此牌的失去方式执行以下效果：使用，弃置其他角色一张牌；打出，摸一张牌；弃置，回复1点体力；其他,你下次对其他角色造成的伤害+1。",
    ["@ny_10th_taji"] = "你可弃置一名其他角色一张牌",
    ["$ny_10th_qinghuang_add"] = "“青荒”为 %from 增加的额外效果为 %arg",
    ["$ny_10th_taji_damage"] = "%from 对 %to 造成的伤害因 %arg 由 %arg2 点增加到 %arg3 点",
    ["ny_10th_taji:use"] = "弃置其他角色一张牌",
    ["ny_10th_taji:response"] = "摸一张牌",
    ["ny_10th_taji:discard"] = "回复1点体力",
    ["ny_10th_taji:other"] = "你下次对其他角色造成的伤害+1",
    ["ny_10th_qinghuang"] = "青荒",
    [":ny_10th_qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你此阶段失去牌时触发“踏寂”随机额外获得一种效果。",
    ["ny_10th_qinghuang:invoke"] = "你可以减1点体力上限，然后你此阶段失去牌时触发“踏寂”随机额外获得一种效果",

    ["$ny_10th_huiling1"] = "天地有灵，汇于我眸间。",
	["$ny_10th_huiling2"] = "撷四时钟灵，拈芳兰毓秀。",
	["$ny_10th_chongxu1"] = "慕圣道冲虚，有求者皆应。",
	["$ny_10th_chongxu2"] = "养志无为，遗冲虚于物外。",
    ["$ny_10th_taji1"] = "仙途本寂寥，结发叹长生。",
	["$ny_10th_taji2"] = "仙者不言，手执春风。",
    ["$ny_10th_qinghuang1"] = "上士无争，焉生妄心。",
	["$ny_10th_qinghuang2"] = "心有草木，何畏荒芜？",
    ["~ny_10th_sunhanhua"] = "长生不长乐，悔觅仙途。",

    --陈泰

    ["ny_10th_chentai"] = "陈泰[十周年]",
    ["&ny_10th_chentai"] = "陈泰",
    ["#ny_10th_chentai"] = "岳峙渊渟",
    ["designer:ny_10th_chentai"] = "官方",
	["cv:ny_10th_chentai"] = "官方",
	["illustrator:ny_10th_chentai"] = "官方",

    ["ny_10th_jiuxian"] = "救陷",
    [":ny_10th_jiuxian"] = "出牌阶段限一次，你可以重铸一半数量的手牌（向上取整），然后视为使用一张【决斗】。此牌对目标角色造成伤害后，你可令其攻击范围内的一名其他角色回复1点体力。",
    ["@ny_10th_jiuxian"] = "你可以令 %src 攻击范围内的一名其他角色回复一点体力",
    ["ny_10th_chenyong"] = "沉勇",
    [":&ny_10th_chenyong"] = "结束阶段，你可以摸 %src 张牌",
    [":ny_10th_chenyong"] = "结束阶段，你可以摸x张牌。（x为本回合你使用过牌的类型数）",
    ["ny_10th_chenyong:draw"] = "你可以发动“沉勇”摸 %src 张牌",

    ["$ny_10th_jiuxian1"] = "救袍泽于水火，返清明于天下。",
    ["$ny_10th_jiuxian2"] = "与君共扼王旗，焉能见死不救。",
    ["$ny_10th_chenyong1"] = "将者，当泰山崩于前而不改色。",
    ["$ny_10th_chenyong2"] = "救将陷之城，焉求益兵之助。",
    ["~ny_10th_chentai"] = "公非旦，我非勃。",

    --桓范

    ["ny_10th_huanfan"] = "桓范[十周年]",
    ["&ny_10th_huanfan"] = "桓范",
    ["#ny_10th_huanfan"] = "雍国竝世",
    ["designer:ny_10th_huanfan"] = "官方",
	["cv:ny_10th_huanfan"] = "官方",
	["illustrator:ny_10th_huanfan"] = "官方",

    ["ny_10th_fumou"] = "腹谋",
    [":ny_10th_fumou"] = "当你受到伤害后，你可令至多X名角色依次选择一项(X为你已损失的体力值):1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。",
    ["@ny_10th_fumou"] = "你可以对至多 %src 名角色发动 “腹谋”",
    ["$ny_10th_fumou_chosen"] = "%from 选择了 %arg",
    ["ny_10th_fumou:move"] = "移动场上一张牌",
    ["ny_10th_fumou:discard"] = "弃置所有手牌并摸两张牌",
    ["ny_10th_fumou:recover"] = "弃置装备区所有牌并回复1点体力",
    ["ny_tenth_jianzheng"] = "谏诤",
    [":ny_tenth_jianzheng"] = "出牌阶段限一次，你可观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。若此牌指定了该角色为目标，则横置你与其的武将牌，然后其观看你的手牌。",
    ["ny_tenth_jianzheng_use"] = "谏诤",
    ["#ny_tenth_jianzheng"] = "谏诤",
    ["@ny_tenth_jianzheng"] = "你可以获得并使用 %src 的一张手牌",
    ["$ny_tenth_jianzheng_usecard_targetfixed"] = "%from 将获得并使用 %arg 的 %card",
    ["$ny_tenth_jianzheng_usecard_nottargetfixed"] = "%from 将获得并使用 %arg 的 %card , 目标是 %to",

    ["$ny_10th_fumou1"] = "某有良谋，可为将军所用。",
    ["$ny_10th_fumou2"] = "吾负十斗之囊，其盈一石之智。",
    ["$ny_tenth_jianzheng1"] = "将军今出洛阳，恐难再回。",
    ["$ny_tenth_jianzheng2"] = "贼示弱于外，必包藏祸心。",
    ["~ny_10th_huanfan"] = "有良言而不用，君何愚哉。",

    --乐蔡文姬

    ["ny_10th_yuecaiwenji"] = "乐蔡文姬[十周年]",
    ["&ny_10th_yuecaiwenji"] = "蔡文姬",
    ["#ny_10th_yuecaiwenji"] = "胡笳十八拍",
    ["designer:ny_10th_yuecaiwenji"] = "官方",
	["cv:ny_10th_yuecaiwenji"] = "官方",
	["illustrator:ny_10th_yuecaiwenji"] = "官方",

    ["ny_10th_shuangjia"] = "霜笳",
    [":ny_10th_shuangjia"] = "锁定技，游戏开始时，你将初始手牌标记为“胡笳”牌（“胡笳”牌不计入你的手牌上限；其他角色计算与你的距离增加“胡笳”牌数，至多+5）。",
    ["ny_10th_hujia"] = "胡笳",
    ["ny_10th_beifen"] = "悲愤",
    [":ny_10th_beifen"] = "锁定技，当你失去”胡笳“后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",

    ["$ny_10th_shuangjia1"] = "塞外青鸟匿，不闻折柳声。",
    ["$ny_10th_shuangjia2"] = "向晚吹霜笳，雪落白发生。",
    ["$ny_10th_beifen1"] = "此心如置冰壶，无物可暖。",
    ["$ny_10th_beifen2"] = "年少爱登楼，欲说语还休。",
    ["~ny_10th_yuecaiwenji"] = "天何薄我，天何薄我。",

    --袁姬

    ["ny_10th_yuanji"] = "袁姬[十周年]",
    ["&ny_10th_yuanji"] = "袁姬",
    ["#ny_10th_yuanji"] = "袁门贵女",
    ["designer:ny_10th_yuanji"] = "官方",
	["cv:ny_10th_yuanji"] = "官方",
	["illustrator:ny_10th_yuanji"] = "官方",

    ["ny_10th_fangdu"] = "芳妒",
    [":ny_10th_fangdu"] = "锁定技，你的回合外，每回合你第一次受到普通伤害后回复1点体力，你第一次受到属性伤害后随机获得伤害来源一张手牌。",
    ["ny_10th_jiexing"] = "节行",
    [":ny_10th_jiexing"] = "当你的体力值发生变化后，你可以摸一张牌，且此牌不计入本回合的手牌上限。",
    ["ny_10th_jiexing:draw"] = "你可以摸一张牌，且此牌不计入本回合的手牌上限",

    ["$ny_10th_fangdu1"] = "浮萍却红尘，何意染是非？",
    ["$ny_10th_fangdu2"] = "我本无意争春，奈何群芳相妒。",
    ["$ny_10th_jiexing1"] = "女子有节，安能贰其行。",
    ["$ny_10th_jiexing2"] = "坐受雨露，皆为君恩。",
    ["~ny_10th_yuanji"] = "妾本蒲柳，幸荣君恩。",

    --神张角

    ["ny_10th_shenzhangjiao"] = "神张角[十周年]",
    ["&ny_10th_shenzhangjiao"] = "张角",
    ["#ny_10th_shenzhangjiao"] = "末世的起首",
    ["designer:ny_10th_shenzhangjiao"] = "官方",
	["cv:ny_10th_shenzhangjiao"] = "官方",
	["illustrator:ny_10th_shenzhangjiao"] = "官方",
	["information:shenzhangjiao"] = "ᅟᅠ<i>“苍天已死，黄天当立，岁在甲子，天下大吉。”</i>",

    ["ny_10th_yizhao"] = "异兆",
    [":ny_10th_yizhao"] = "锁定技，你使用或打出一张牌后，获得等于此牌点数的“黄”标记。每次“黄”的十位数因此变化时，你获得牌堆中一张与变化后十位数点数相同的牌。",
    ["ny_10th_huang"] = "黄",
    ["ny_10th_sijun"] = "肆军",
    [":ny_10th_sijun"] = "准备阶段，若“黄”标记数量大于牌堆的牌数，你可以移去所有“黄”并洗牌，然后获得随机获得点数之和为36的牌。",
    ["ny_10th_sijun:draw"] = "你可以移去所有“黄”并洗牌，然后获得随机获得点数之和为36的牌",
    ["ny_10th_sanshou"] = "三首",
    [":ny_10th_sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合未使用过的牌的类型，防止此伤害。",
    ["$ny_10th_sanshou_damage"] = "%from 因 %arg 的效果防止了即将受到的 %arg2 点伤害",
    ["ny_10th_tianjie"] = "天劫",
    [":ny_10th_tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量，且至少为1）。",
    ["@ny_10th_tianjie"] = "你可以对至多 3 名其他角色发动 “天劫”",

    ["$ny_10th_yizhao1"] = "苍天已死，此黄天当立之时。",
    ["$ny_10th_yizhao2"] = "甲子尚水，显炎汉将亡之兆。",
    ["$ny_10th_sijun1"] = "联九州黎庶，撼一家之王庭。",
    ["$ny_10th_sijun2"] = "吾以此身为药，欲医天下之疾。",
    ["$ny_10th_sanshou1"] = "三公既现，领大道而立黄天。",
    ["$ny_10th_sanshou2"] = "天地三才，载厚德以驱魍魉。",
    ["$ny_10th_tianjie1"] = "苍天已死，贫道当替天行道。",
    ["$ny_10th_tianjie2"] = "贫道张角，请大汉赴死！",
    ["~ny_10th_shenzhangjiao"] = "诸君唤我为贼，然我所窃何物？",

    --张奋

    ["ny_10th_zhangfen"] = "张奋[十周年]",
    ["&ny_10th_zhangfen"] = "张奋",
    ["#ny_10th_zhangfen"] = "御驰大攻",
    ["designer:ny_10th_zhangfen"] = "官方",
	["cv:ny_10th_zhangfen"] = "官方",
	["illustrator:ny_10th_zhangfen"] = "官方",

    ["_ny_tenth_dagongche"] = "大攻车",
    ["ny_tenth_dagongche"] = "大攻车",
    [":_ny_tenth_dagongche"] = "装备牌·宝物<br /><b>装备效果</b>：出牌阶段开始时，你可以视为使用了一张【杀】（不计入次数限制），若以此法造成伤害，你弃置目标一张牌。\
    若未升级，此牌无法被弃置；\
    此宝物离开装备区时销毁。\
    升级选项：无视距离和防具；目标数+1；弃牌数+1。",
    ["ny_tenth_zhangfen_card"] = "张奋专属",
    ["@ny_tenth_dagongche_slash"] = "你可以视为使用了一张不计入次数限制的【杀】(可以有额外的 %src 个目标)",
    ["ny_tenth_wanglu"] = "望橹",
    [":ny_tenth_wanglu"] = "锁定技，准备阶段，若你的装备区里没有【大攻车】，则将之置入你的装备区，否则你执行一个额外的出牌阶段。",
    ["$ny_tenth_wanglu_get"] = "%from 发动 %arg 将 %card 置入了装备区",
    ["$ny_tenth_wanglu_phase"] = "%from 因 %arg 的效果将执行一个额外的 %arg2 阶段",
    ["ny_tenth_xianzhu"] = "陷筑",
    [":ny_tenth_xianzhu"] = "每当你的【杀】造成伤害后，你可升级【大攻车】（每个【大攻车】 最多升5次）。",
    [":ny_tenth_xianzhu1"] = "每当你的【杀】造成伤害后，你可升级【大攻车】（每个【大攻车】 最多升5次）。",
    [":ny_tenth_xianzhu2"] = "每当你的【杀】造成伤害后，你可升级【大攻车】（每个【大攻车】 最多升5次）。\
    当前升级：可以弃置 %arg1 张牌，可以指定 %arg2 个额外目标",
    [":ny_tenth_xianzhu3"] = "每当你的【杀】造成伤害后，你可升级【大攻车】（每个【大攻车】 最多升5次）。\
    当前升级：可以弃置 %arg1 张牌，可以指定 %arg2 个额外目标 ， 无距离限制且无视目标防具",
    ["ny_tenth_xianzhu:update"] = "你可发动“陷筑”升级【大攻车】",
    ["ny_tenth_xianzhu:discards"] = "额外弃置一张牌",
    ["ny_tenth_xianzhu:targets"] = "额外指定一名目标",
    ["ny_tenth_xianzhu:ignore"] = "无距离限制且无视目标防具",
    ["ny_tenth_xianzhu_update"] = "升级次数",
    ["ny_tenth_chaixie"] = "拆械",
    [":ny_tenth_chaixie"] = "锁定技，当【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",

    ["$ny_tenth_wanglu1"] = "大攻车前，坚城弗当。",
    ["$ny_tenth_wanglu2"] = "大攻既作，天下可望！",
    ["$ny_tenth_xianzhu1"] = "敌垒已陷，当长驱直入！",
    ["$ny_tenth_xianzhu2"] = "舍命陷登，击蛟蟒于狂澜！",
    ["$ny_tenth_chaixie1"] = "利器经久，拆合自用。",
    ["$ny_tenth_chaixie2"] = "损一得十，如鲸落宇。",
    ["~ny_10th_zhangfen"] = "身陨外，愿魂归江东。",

    --界钟会

    ["ny_10th_jiezhonghui"] = "界钟会[十周年]",
    ["&ny_10th_jiezhonghui"] = "钟会",
    ["#ny_10th_jiezhonghui"] = "桀骜野心家",
    ["designer:ny_10th_jiezhonghui"] = "官方",
	["cv:ny_10th_jiezhonghui"] = "官方",
	["illustrator:ny_10th_jiezhonghui"] = "官方",

    ["ny_10th_quanji"] = "权计",
    [":ny_10th_quanji"] = "当你的牌被其他角色获得或你受到1点伤害后，你可以摸一张牌，然后你将一张手牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”的数量）",
    ["ny_10th_quanji:draw"] = "你可以发动“权计”摸一张牌，然后你将一张手牌置于武将牌上",
    ["@ny_10th_quanji"] = "请将一张手牌当作“权”移出游戏",
    ["ny_10th_quan"] = "权",
    ["ny_10th_zili"] = "自立",
    [":ny_10th_zili"] = "觉醒技，准备阶段，若“权”的数量大于等于3，你回复1点体力并摸两张牌，然后减1点体力上限，获得“排异”。",
    ["ny_10th_paiyi"] = "排异",
    [":ny_10th_paiyi"] = "出牌阶段每项限一次，你可以移去一张“权”， 然后选择一项：1.令一名角色摸X张牌；2.对X名角色各造成1点伤害。（X为“权”的数量且至少为1）",
    ["$ny_10th_paiyi_chosen"] = "%from 选择了 %arg",
    ["ny_10th_paiyi:draw"] = "令一名角色摸X张牌",
    ["ny_10th_paiyi:damage"] = "对X名角色各造成1点伤害",

    ["$ny_10th_quanji1"] = "操权弄略，舍小利而谋大局。",
    ["$ny_10th_quanji2"] = "大丈夫行事，岂较一兵一将之得失。",
    ["$ny_10th_zili1"] = "烧去剑阁八百里，蜀中自有一片天。",
    ["$ny_10th_zili2"] = "天下风流出我辈，一遇风云便化龙。",
    ["$ny_10th_paiyi1"] = "蜀川三千里，皆由我一言决之。",
    ["$ny_10th_paiyi2"] = "顺我者封侯拜将，逆我者斧钺加身。",
    ["~ny_10th_jiezhonghui"] = "这就是自食恶果的下场吗？",

    --经典曹操

    ["ny_10th_jindiancaocao"] = "经典·曹操[十周年]",
    ["&ny_10th_jindiancaocao"] = "曹操",
    ["#ny_10th_jindiancaocao"] = "魏武帝",
    ["designer:ny_10th_jindiancaocao"] = "官方",
	["cv:ny_10th_jindiancaocao"] = "官方",
	["illustrator:ny_10th_jindiancaocao"] = "官方",

    ["ny_10th_jingdianjianxiong"] = "奸雄",
    [":ny_10th_jingdianjianxiong"] = "当你受到伤害后，你可以摸1张牌，并获得造成此伤害的牌。每次发动此技能，摸牌数永久+1（至多为5）。",
    [":ny_10th_jingdianjianxiong1"] = "当你受到伤害后，你可以摸 %arg1 张牌，并获得造成此伤害的牌。每次发动此技能，摸牌数永久+1（至多为5）。",
    ["ny_10th_jingdianjianxiong:draw"] = "你可以获得【%src】并摸%arg张牌",
    ["ny_10th_jingdianjianxiong_nocard"] = "没有卡牌",
    ["ny_10th_jingdianjianxiong_draw"] = "奸雄摸牌数",

    ["$ny_10th_jingdianjianxiong1"] = "宁教我负天下人，休教天下人负我！",
    ["$ny_10th_jingdianjianxiong2"] = "吾好梦中杀人！",
    ["~ny_10th_jindiancaocao"] = "霸业未成…未成啊！",

    --经典孙权

    ["ny_10th_jingdiansunquan"] = "经典·孙权[十周年]",
    ["&ny_10th_jingdiansunquan"] = "孙权",
    ["#ny_10th_jingdiansunquan"] = "年轻的贤君",
    ["designer:ny_10th_jingdiansunquan"] = "官方",
	["cv:ny_10th_jingdiansunquan"] = "官方",
	["illustrator:ny_10th_jingdiansunquan"] = "官方",

    ["ny_10th_jingdianzhiheng"] = "制衡",
    [":ny_10th_jingdianzhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，额外摸1张牌。\
    你的回合内每名其他角色每回合限一次，你对其他角色造成伤害后，本回合此技能发动次数+1。",

    ["$ny_10th_jingdianzhiheng1"] = "容我三思！",
    ["$ny_10th_jingdianzhiheng2"] = "且慢！",
    ["~ny_10th_jingdiansunquan"] = "父亲，大哥，仲谋愧矣。",

    --经典刘备

    ["ny_10th_jingdianliubei"] = "经典·刘备[十周年]",
    ["&ny_10th_jingdianliubei"] = "刘备",
    ["#ny_10th_jingdianliubei"] = "乱世的枭雄",
    ["designer:ny_10th_jingdianliubei"] = "官方",
	["cv:ny_10th_jingdianliubei"] = "官方",
	["illustrator:ny_10th_jingdianliubei"] = "官方",

    ["ny_tenth_jingdianrende"] = "仁德",
    [":ny_tenth_jingdianrende"] = "出牌阶段每名其他角色限一次，你可以获得一名其他角色两张手牌，然后视为使用一张基本牌。",
    ["@ny_tenth_jingdianrende"] = "你可以视为使用了【%src】",
    ["ny_tenth_jingdianrende_choice"] = "请选择要使用的基本牌",

    ["$ny_tenth_jingdianrende1"] = "惟贤惟德，能服于人。",
    ["$ny_tenth_jingdianrende2"] = "以德服人。",
    ["~ny_10th_jingdianliubei"] = "这就是，桃园吗？",

    --全惠解

    ["ny_10th_quanhuijie"] = "全惠解[十周年]",
    ["&ny_10th_quanhuijie"] = "全惠解",
    ["#ny_10th_quanhuijie"] = "春早宫深",
    ["designer:ny_10th_quanhuijie"] = "官方",
	["cv:ny_10th_quanhuijie"] = "官方",
	["illustrator:ny_10th_quanhuijie"] = "游漫美绘",

    ["ny_tenth_huishu"] = "慧淑",
    [":ny_tenth_huishu"] = "摸牌阶段结束时，你可以摸3张牌，然后弃置1张手牌。若如此做，当你本回合弃置超过2张牌时，你从弃牌堆中获得等量非基本牌。",
    [":ny_tenth_huishu1"] = "摸牌阶段结束时，你可以摸%arg1张牌，然后弃置%arg2张手牌。若如此做，当你本回合弃置超过%arg3张牌时，你从弃牌堆中获得等量非基本牌。",
    ["ny_tenth_huishu_now"] = "慧淑已弃置",
    ["ny_tenth_huishu_target"] = "慧淑目标",
    ["ny_tenth_huishu:draw"] = "你可以发动“慧淑”摸%src张牌并弃置%arg张手牌",
    ["ny_10th_yishu"] = "易数",
    [":ny_10th_yishu"] = "锁定技，当你于出牌阶段外失去牌后，“慧淑”中最小的一个数字+2且最大的一个数字-1。\
    <font color=\"red\"><b>请注意：没有“慧淑”技能时不会触发这个技能！！！</b></font>",
    ["ny_10th_yishu_add"] = "请选择要减小的数字",
    ["ny_10th_yishu_remove"] = "请选择要增加的数字",
    ["ny_10th_yishu:draw"] = "摸牌数(当前为%src)",
    ["ny_10th_yishu:discard"] = "摸牌后弃牌数(当前为%src)",
    ["ny_10th_yishu:get"] = "获得非基本牌所需弃牌数(当前为%src)",
    ["ny_10th_ligong"] = "离宫",
    [":ny_10th_ligong"] = "觉醒技，准备阶段，若“慧淑”有数字达到5，你加1点体力上限并回复1点体力，失去技能“易数”，然后随机抽取四个吴国女性武将，且可以获得其中两个技能。若你以此法获得了技能，则你失去技能“慧淑”，否则你摸三张牌。\
    <font color=\"red\"><b>不想拿技能可以随便选一名武将然后选取消</b></font>",

    ["$ny_tenth_huishu1"] = "心有慧镜，善解百般人意。",
    ["$ny_tenth_huishu2"] = "袖着静淑，可揾夜阑之泪。",
    ["$ny_10th_yishu1"] = "此命由我，如织之数可易。",
    ["$ny_10th_yishu2"] = "易天定之数，结人定之缘。",
    ["$ny_10th_ligong1"] = "伴君离高墙，日暮江湖远。",
    ["$ny_10th_ligong2"] = "巍巍宫门开，自此不复来。",
    ["~ny_10th_quanhuijie"] = "妾有愧于陛下。",

    --界群黄月英

    ["ny_10th_jxqunhuangyueying"] = "界群黄月英[十周年]",
    ["&ny_10th_jxqunhuangyueying"] = "黄月英",
    ["#ny_10th_jxqunhuangyueying"] = "慧心巧思",
    ["designer:ny_10th_jxqunhuangyueying"] = "官方",
	["cv:ny_10th_jxqunhuangyueying"] = "官方",
	["illustrator:ny_10th_jxqunhuangyueying"] = "匠人绘",

    ["ny_10th_jiqiao"] = "机巧",
    [":ny_10th_jiqiao"] = "出牌阶段开始时，你可以弃置任意张牌，亮出牌堆顶的等量张牌，然后获得其中的非装备牌。你每以此法弃置一张装备牌，本次便多亮出一张牌。",
    ["@ny_10th_jiqiao"] = "你可以发动“机巧”弃置任意张牌",
    ["ny_10th_linglong"] = "玲珑",
    [":ny_10th_linglong"] = "锁定技，若你的装备区里没有：防具牌，你视为装备着【八卦阵】；坐骑牌，你的手牌上限+2；宝物牌，你视为拥有技能“奇才”；均满足，你使用的【杀】或普通锦囊牌不能被响应。",
    ["#ny_10th_linglong_noresponse"] = "%from 使用的 %card 因 %arg 的效果不可被响应",

    ["$ny_10th_jiqiao1"] = "机关将作之术，在乎手巧心灵。",
    ["$ny_10th_jiqiao2"] = "机巧藏于心，亦如君之容。",
    ["$ny_10th_linglong1"] = "我夫所赠之玫，遗香自长存。",
    ["$ny_10th_linglong2"] = "心有玲珑罩，不殇春与秋。",
    ["~ny_10th_jxqunhuangyueying"] = "此心欲留夏，奈何秋风起。",

    --张曼成

    ["ny_10th_zhangmancheng"] = "张曼成[十周年]",
    ["&ny_10th_zhangmancheng"] = "张曼成",
    ["#ny_10th_zhangmancheng"] = "蚁萃宛洛",
    ["designer:ny_10th_zhangmancheng"] = "官方",
	["cv:ny_10th_zhangmancheng"] = "官方",
	["illustrator:ny_10th_zhangmancheng"] = "君桓文化",

    ["ny_10th_zhongji"] = "螽集",
    [":ny_10th_zhongji"] = "当你使用牌时，若你没有与此牌花色相同的手牌且你的手牌数小于体力上限，你可以将手牌摸至体力上限，然后弃置X张牌（X为你本回合发动此技能的次数）。",
    ["ny_10th_zhongji:draw"] = "你可以发动“螽集”摸%src张牌并弃置%arg张牌",
    ["ny_10th_lvecheng"] = "掠城",
    [":ny_10th_lvecheng"] = "出牌阶段限一次，你可以选择一名其他角色，你本回合对其使用当前手牌中的【杀】无次数限制。若如此做，回合结束时，该角色展示手牌：若其中有【杀】，其可选择对你依次使用手牌中所有的【杀】。",
    ["ny_10th_lvecheng:use"] = "你可以对 %src 使用手牌中所有的【杀】",

    ["$ny_10th_zhongji1"] = "羸汉暴政不息，黄巾永世不绝。",
    ["$ny_10th_zhongji2"] = "宛洛膏如秋实，怎可不生螟虫。",
    ["$ny_10th_lvecheng1"] = "我等一无所有，普天又有何惧！",
    ["$ny_10th_lvecheng2"] = "我视百城为饵，皆可食之果腹。",
    ["~ny_10th_zhangmancheng"] = "逡巡不前，坐以待毙。",

    --卢弈

    ["ny_10th_luyi"] = "卢弈[十周年]",
    ["&ny_10th_luyi"] = "卢弈",
    ["#ny_10th_luyi"] = "落子惊鸿",
    ["designer:ny_10th_luyi"] = "官方",
	["cv:ny_10th_luyi"] = "官方",
	["illustrator:ny_10th_luyi"] = "匠人绘",

    ["ny_10th_yaoyi"] = "邀弈",
    [":ny_10th_yaoyi"] = "锁定技，①游戏开始时，你令全场没有转换技的角色获得技能“手谈”（你发动“手谈”无需弃置牌且无次数限制）；\
    ②所有角色不能对除自己外转换技状态与自己相同的角色使用牌。",
    ["ny_10th_shoutan"] = "手谈",
    [":ny_10th_shoutan"] = "转换技，出牌阶段限一次，\
    阳：你可以弃置一张非黑色手牌；\
    阴：你可以弃置一张黑色手牌。",
    [":ny_10th_shoutan1"] = "转换技，出牌阶段限一次，\
    阳：你可以弃置一张非黑色手牌；\
    <font color=\"#01A5AF\"><s>阴：你可以弃置一张黑色手牌。</s></font>",
    [":ny_10th_shoutan2"] = "转换技，出牌阶段限一次，\
    <font color=\"#01A5AF\"><s>阳：你可以弃置一张非黑色手牌；</s></font>\
    阴：你可以弃置一张黑色手牌。",
    ["ny_tenth_fuxue"] = "复学",
    [":ny_tenth_fuxue"] = "准备阶段，你可以选择并获得弃牌堆中的至多X张不因使用而置入的牌;\
    结束阶段，若你的手牌中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",
    ["@ny_tenth_fuxue"] = "你可以从弃牌堆中获得 %src 张不因使用而置入的牌",
    ["ny_tenth_fuxue:draw"] = "你可以发动“复学”摸 %src 张牌",
    ["#ny_tenth_fuxue"] = "复学",

    ["$ny_10th_yaoyi1"] = "对弈未分高下，胜负可问春风。",
    ["$ny_10th_yaoyi2"] = "我掷三十六道，邀君游弈其中。",
    ["$ny_10th_shoutan1"] = "对弈博雅，落子珠玑胜无声。",
    ["$ny_10th_shoutan2"] = "弈者无言，手执黑白谈古今。",
    ["$ny_tenth_fuxue1"] = "普天之大，唯此处可安书桌。",
    ["$ny_tenth_fuxue2"] = "书中自有风月，何故东奔西顾？",
    ["~ny_10th_luyi"] = "此生博弈，落子未有悔。",

    --星曹仁

    ["ny_10th_xingcaoren"] = "星曹仁[十周年]",
    ["&ny_10th_xingcaoren"] = "曹仁",
    ["#ny_10th_xingcaoren"] = "伏波四方",
    ["designer:ny_10th_xingcaoren"] = "官方",
	["cv:ny_10th_xingcaoren"] = "官方",
	["illustrator:ny_10th_xingcaoren"] = "游卡桌游",

    ["ny_10th_sujun"] = "肃军",
    [":ny_10th_sujun"] = "当你使用一张牌时，若你手牌中基本牌与非基本牌的数量相等，你可以摸两张牌。",
    ["ny_10th_sujun:draw"] = "你可以发动“肃军”摸两张牌",
    ["ny_10th_lifeng"] = "砺锋",
    [":ny_10th_lifeng"] = "你可将一张本回合未使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。",

    ["$ny_10th_sujun1"] = "将为军魂，需以身作则。",
    ["$ny_10th_sujun2"] = "整肃三军，可御虎贲。",
    ["$ny_10th_lifeng1"] = "锋出百砺，健卒亦如是。",
    ["$ny_10th_lifeng2"] = "强军者，必校之以三九，炼之三伏。",
    ["~ny_10th_xingcaoren"] = "濡须之败，此生之耻。",

    --界张松

    ["ny_10th_jiezhangsong"] = "界张松[十周年]",
    ["&ny_10th_jiezhangsong"] = "张松",
    ["#ny_10th_jiezhangsong"] = "博学强识",
    ["designer:ny_10th_jiezhangsong"] = "官方",
	["cv:ny_10th_jiezhangsong"] = "官方",
	["illustrator:ny_10th_jiezhangsong"] = "匠人绘",

    ["ny_10th_jxxiantu"] = "献图",
    [":ny_10th_jxxiantu"] = "其他角色的出牌阶段开始时，你可以摸两张牌，然后将两张牌交给该角色，若如此做，此阶段结束时，若其于此阶段内没有造成过伤害，你失去1点体力。",
    ["ny_10th_jxxiantu:draw"] = "你可以发动“献图”摸两张牌并交给 %src 两张牌",
    ["@ny_10th_jxxiantu"] = "请交给 %src 两张牌",
    ["ny_10th_jxqiangzhi"] = "强识",
    [":ny_10th_jxqiangzhi"] = "出牌阶段开始时，你可以展示一名其他角色的一张手牌，若如此做，每当你于此阶段内使用与之类别相同的牌时，你可以摸一张牌。",
    ["@ny_10th_jxqiangzhi"] = "你可以发动“强识”展示一名其他角色的一张手牌",

    ["$ny_10th_jxxiantu1"] = "此图载益州山水，请君纳之。",
    ["$ny_10th_jxxiantu2"] = "我献梧木一株，为引凤而来。",
    ["$ny_10th_jxqiangzhi1"] = "过目难忘，千载在我腹间。",
    ["$ny_10th_jxqiangzhi2"] = "吾目为镜，可照世间文字。",
    ["~ny_10th_jiezhangsong"] = "恨未见使君，入主益州。",

    --曹纯

    ["ny_10th_caochun"] = "曹纯[十周年]",
    ["&ny_10th_caochun"] = "曹纯",
    ["#ny_10th_caochun"] = "虎豹骑首",
    ["designer:ny_10th_caochun"] = "官方",
	["cv:ny_10th_caochun"] = "官方",
	["illustrator:ny_10th_caochun"] = "depp",

    ["ny_tenth_shanjia"] = "缮甲",
    [":ny_tenth_shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置X张牌（X为3减去你于本局游戏内不因使用装备牌而失去过装备牌的数量）。若你以此法弃置的牌中没有：基本牌，你本阶段使用【杀】的次数上限+1；锦囊牌，你本阶段使用牌无距离限制；两项均满足，你可以视为使用一张不计入次数的【杀】。",
    ["ny_tenth_shanjia:draw"] = "你可以发动“缮甲”摸3张牌然后弃置 %src 张牌",
    ["@ny_tenth_shanjia"] = "你可以视为使用了一张【杀】",

    ["$ny_tenth_shanjia1"] = "缮甲厉兵，伺机而行。",
    ["$ny_tenth_shanjia2"] = "战当取精锐之兵而弃驽钝也。",
    ["~ny_10th_caochun"] = "银甲在身，竟败于你手！",

    --刘晔第二版

    ["ny_10th_liuye"] = "刘晔[十周年二版]",
    ["&ny_10th_liuye"] = "刘晔",
    ["#ny_10th_liuye"] = "佐世之才",
    ["designer:ny_10th_liuye"] = "官方",
	["cv:ny_10th_liuye"] = "官方",
	["illustrator:ny_10th_liuye"] = "一意动漫",

    ["ny_10th_poyuan"] = "破垣",
    [":ny_10th_poyuan"] = "游戏开始时或回合开始时，若你的装备区内没有【霹雳车】，你可以将【霹雳车】置于你的装备区；若你的装备区内有【霹雳车】，你可以弃置一名其他角色的至多两张牌。",
    ["ny_10th_poyuan:put"] = "你可以发动“破垣”将【霹雳车】置入装备区",
    ["@@ny_10th_poyuan"] = "你可以发动“破垣”弃置一名其他角色的至多两张牌",
    ["$ny_10th_poyuan_get"] = "%from 发动 %arg 将 %card 置入了装备区",
    ["ny_10th_poyuan_dis"] = "请选择要弃置的牌数",
    ["_ny_tenth_piliche"] = "霹雳车",
    ["ny_tenth_piliche"] = "霹雳车",
    ["ny_10th_liuye_card"] = "刘晔专属",
    [":_ny_tenth_piliche"] = "装备牌·宝物<br /><b>装备效果</b>：你于回合内使用基本牌造成的伤害或回复+1且无距离限制，你于回合外使用或打出基本牌时摸1张牌。\
    此牌离开你的装备区时销毁。",
    ["$ny_tenth_piliche_damage"] = "%from 使用 %card 造成的伤害因 %arg 的效果由 %arg2 点增加到了 %arg3 点",
    ["$ny_tenth_piliche_recover"] = "%from 使用 %card 的治疗量因 %arg 的效果由 %arg2 点增加到了 %arg3 点",
    ["ny_10th_huace"] = "画策",
    [":ny_10th_huace"] = "出牌阶段限一次，你可以将一张手牌当作上一轮没有角色使用过的普通锦囊牌使用。",

    ["$ny_10th_poyuan1"] = "砲石飞空，坚垣难存。",
    ["$ny_10th_poyuan2"] = "声若霹雳，人马俱摧。",
    ["$ny_10th_huace1"] = "筹画所料，无有不中。",
    ["$ny_10th_huace2"] = "献策破敌，所谋皆应。",
    ["~ny_10th_liuye"] = "功名富贵，到头来，不过黄土一抔。",

    --张瑾云第二版

    ["ny_10th_zhangjinyun"] = "张瑾云[十周年二版]",
    ["&ny_10th_zhangjinyun"] = "张瑾云",
    ["#ny_10th_zhangjinyun"] = "暖枫袅袅",
    ["designer:ny_10th_zhangjinyun"] = "官方",
	["cv:ny_10th_zhangjinyun"] = "官方",
	["illustrator:ny_10th_zhangjinyun"] = "阿敦",

    ["ny_10th_huizhi"] = "蕙质",
    [":ny_10th_huizhi"] = "准备阶段，你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同。（最少摸一张，最多摸五张）",
    ["@ny_10th_huizhi"] = "你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同",
    ["ny_10th_jijiao"] = "继椒",
    [":ny_10th_jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中你本局游戏内使用和弃置的全部普通锦囊牌（这些牌不能被【无懈可击】响应）。每个回合结束时，若本回合内牌堆洗切过或有角色死亡，此技能视为未发动过。",
    ["$ny_10th_jijiao_renew"] = "%from 的 %arg 被重置",
    ["$ny_10th_jijiao_nooffset"] = "%from 使用的 %card 因 %arg 的效果无法被【无懈可击】响应",

    ["$ny_10th_huizhi1"] = "妾有一席幽梦，予君三千暗香。",
    ["$ny_10th_huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
    ["$ny_10th_jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
    ["$ny_10th_jijiao2"] = "居椒之殊荣，妾得之惶恐。",
    ["~ny_10th_zhangjinyun"] = "陛下，妾身来陪你了。",

    --陈式

    ["ny_10th_chenshi"] = "陈式[十周年]",
    ["&ny_10th_chenshi"] = "陈式",
    ["#ny_10th_chenshi"] = "裨将可期",
    ["designer:ny_10th_chenshi"] = "官方",
	["cv:ny_10th_chenshi"] = "官方",
	["illustrator:ny_10th_chenshi"] = "游漫美绘",

    ["ny_10th_qingbei"] = "擎北",
    [":ny_10th_qingbei"] = "每轮开始时，你选择任意种花色令你于本轮无法使用，然后本轮你使用一张手牌后，摸本轮“擎北”选择过的花色数的牌。",
    ["$ny_10th_qingbei_chosen"] = "%from 选择了 %arg",

    ["$ny_10th_qingbei1"] = "待追上那司马懿，定教他没好果子吃！",
    ["$ny_10th_qingbei2"] = "身若不周，吾一人可作擎北之柱。",
    ["~ny_10th_chenshi"] = "丞相、丞相！是魏延指使我的！",

    --阮籍

    ["ny_10th_ruanji"] = "阮籍[十周年]",
    ["&ny_10th_ruanji"] = "阮籍",
    ["#ny_10th_ruanji"] = "命世大贤",
    ["designer:ny_10th_ruanji"] = "官方",
	["cv:ny_10th_ruanji"] = "官方",
	["illustrator:ny_10th_ruanji"] = "匠人绘",

    ["ny_10th_jiudun"] = "酒遁",
    [":ny_10th_jiudun"] = "①你使用的【酒】的效果不会因回合结束而消失；\
    ②当你成为其他角色使用黑色牌的目标后，若你不处于【酒】的状态，则你可以摸一张牌并视为使用一张不计入次数限制的【酒】，否则你可以弃置一张手牌令此牌对你无效。",
    ["ny_10th_jiudun:draw"] = "你可以发动“酒遁”摸一张牌并视为使用一张不计入次数限制的【酒】",
    ["@ny_10th_jiudun"] = "你可以发动“酒遁”弃置一张手牌令【%src】对你无效",
    ["ny_10th_zhaowen"] = "昭文",
    [":ny_10th_zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，你本回合：可以将其中的黑色牌当任意一张普通锦囊牌使用（每种牌名每回合限一次）；使用其中的红色牌时摸一张牌。",
    ["ny_10th_zhaowen:show"] = "你可以发动“昭文”展示所有手牌",

    ["$ny_10th_jiudun1"] = "籍不胜酒力，恐失言失仪。",
    ["$ny_10th_jiudun2"] = "秋月春风正好，不如大醉归去。",
    ["$ny_10th_zhaowen1"] = "我辈昭昭，正始之音浩荡。",
    ["$ny_10th_zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
    ["~ny_10th_ruanji"] = "诸君，欲与我同醉否？",

    --刘徽

    ["ny_10th_liuhui"] = "刘徽[十周年]",
    ["&ny_10th_liuhui"] = "刘徽",
    ["#ny_10th_liuhui"] = "周天古率",
    ["designer:ny_10th_liuhui"] = "官方",
	["cv:ny_10th_liuhui"] = "官方",
	["illustrator:ny_10th_liuhui"] = "凡果",

    ["ny_10th_geyuan"] = "割圆",
    [":ny_10th_geyuan"] = "锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环：\
    1.当一张或多张牌置入弃牌堆时，记录其中满足圆环进度的点数；\
    2.当圆环的点数均被记录后，你获得牌堆中与场上所有此圆环最初和最后记录的点数的牌，然后从圆环中移除这两个点数，重新开始圆环点数的记录。",
    [":ny_10th_geyuan1"] = "锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环：\
    1.当一张或多张牌置入弃牌堆时，记录其中满足圆环进度的点数；\
    2.当圆环的点数均被记录后，你依次选择至多三名角色。你选择的第一名角色摸三张牌，第二名角色弃置四张牌，第三名角色用所有手牌替换牌堆底的五张牌。全部结算结束后，重新开始圆环点数的记录。",
    ["ny_10th_geyuan_last"] = "圆环剩余",
    ["ny_10th_geyuan_head"] = "圆环首",
    ["ny_10th_geyuan_tail"] = "圆环尾",
    ["ny_10th_jieshu"] = "解术",
    [":ny_10th_jieshu"] = "锁定技，①圆环中被移除的点数的牌不计入你的手牌上限；\
    ②当你使用或打出一张牌时，若此牌满足圆环进度点数，你摸一张牌。",
    ["ny_10th_gusuan"] = "股算",
    [":ny_10th_gusuan"] = "觉醒技，一名角色的回合结束时，若圆环剩余点数为3个，你减1点体力上限，并将“割圆”的最后部分修改为：\
    •当圆环的点数均被记录后，你依次选择至多三名角色。你选择的第一名角色摸三张牌，第二名角色弃置四张牌，第三名角色用所有手牌替换牌堆底的五张牌。全部结算结束后，重新开始圆环点数的记录。",
    ["ny_10th_gusuan_draw"] = "你可以令一名角色摸三张牌",
    ["ny_10th_gusuan_discard"] = "你可以令一名角色弃置四张牌",
    ["ny_10th_gusuan_change"] = "你可以令一名角色用所有手牌替换牌堆底的五张牌",
    ["ny_10th_geyuan0"] = "割圆：你可以选择3名角色执行效果",

    ["$ny_10th_geyuan1"] = "绘同径之矩，置内圆而割之。",
    ["$ny_10th_geyuan2"] = "矩割弥细，圆失弥少，以至不可割。",
    ["$ny_10th_jieshu1"] = "累乘除以成九数者，可以加减解之。",
    ["$ny_10th_jieshu2"] = "数有其理，见筹一可知沙数。",
    ["$ny_10th_gusuan1"] = "幻中容横，股中容直，可知其玄五。",
    ["$ny_10th_gusuan2"] = "累矩连索，类推衍化，开立而得法。",
    ["~ny_10th_liuhui"] = "算学如海，穷我一生，只得杯水。",

    --苏飞

    ["ny_10th_sufei"] = "苏飞[十周年]",
    ["&ny_10th_sufei"] = "苏飞",
    ["#ny_10th_sufei"] = "义荐恩还",
    ["designer:ny_10th_sufei"] = "官方",
	["cv:ny_10th_sufei"] = "官方",
	["illustrator:ny_10th_sufei"] = "官方",

    ["ny_tenth_shujian"] = "数荐",
    [":ny_tenth_shujian"] = "出牌阶段限三次，你可以交给一名其他角色一张牌，令其选择一项：1.令你摸3张牌并弃置2张牌；2.视为使用3张【过河拆桥】且你本回合不能再发动此技能。选择完成后，本阶段中此技能中的数字-1。",
    ["ny_tenth_shujian:draw"] = "令其摸%src张牌并弃置%arg张牌",
    ["ny_tenth_shujian:dis"] = "视为使用了%src张【过河拆桥】",
    ["@ny_tenth_shujian"] = "你可以视为使用了一张【过河拆桥】（第%src张，共%arg张）",

    ["$ny_tenth_shujian1"] = "我数荐卿而祖不用，其之失也。",
    ["$ny_tenth_shujian2"] = "兴霸乃当世豪杰，何患无爵。",
    ["~ny_10th_sufei"] = "兴霸何在？吾命休矣！",

    --吴班

    ["ny_10th_wuban"] = "吴班[十周年]",
    ["&ny_10th_wuban"] = "吴班",
    ["#ny_10th_wuban"] = "激东奋北",
    ["designer:ny_10th_wuban"] = "官方",
	["cv:ny_10th_wuban"] = "官方",
	["illustrator:ny_10th_wuban"] = "君桓文化",

    ["ny_10th_youzhan"] = "诱战",
    [":ny_10th_youzhan"] = "锁定技，其他角色在你的回合失去牌后，你摸一张牌且此牌本回合不计手牌上限，其本回合下次受到伤害+1。结束阶段，若该角色本回合未受伤，其摸X张牌（X为其本回合失去的牌的次数且最多为3）。",
    ["$ny_10th_youzhan_damage"] = "%from 受到的伤害因 %arg 的效果由 %arg2 点增加到了 %arg3 点",

    ["$ny_10th_youzhan1"] = "本将军在此，贼仲达何在？",
    ["$ny_10th_youzhan2"] = "以身为饵，诱老贼出营。",
    ["~ny_10th_wuban"] = "班有负丞相厚望。",

    --关宁

    ["ny_10th_guannin"] = "关宁[十周年]",
    ["&ny_10th_guannin"] = "关宁",
    ["#ny_10th_guannin"] = "承义秉文",
    ["designer:ny_10th_guannin"] = "官方",
	["cv:ny_10th_guannin"] = "官方",
	["illustrator:ny_10th_guannin"] = "黯荧岛工作室",

    ["ny_tenth_xiuwen"] = "修文",
    [":ny_tenth_xiuwen"] = "当你使用一张牌时，你可以摸一张牌（每种牌名每局游戏限一次）。",
    ["ny_tenth_xiuwen:draw"] = "你可以发动“修文”摸一张牌",
    ["ny_tenth_longsong"] = "龙诵",
    [":ny_tenth_longsong"] = "出牌阶段开始时，你可以交给一名其他角色一张红色牌，然后你本阶段视为拥有该角色的“出牌阶段”的技能直到你发动之。\
    <font color=\"red\"><b>有的时候可能发动后不会失去，属正常bug，不用报给作者，修不了谢谢！！！</b></font>",
    ["@ny_tenth_longsong"] = "你可以交给一名其他角色一张红色牌，然后你本阶段视为拥有该角色的“出牌阶段”的技能直到你发动之。",

    ["$ny_tenth_xiuwen1"] = "书生笔下三尺剑，毫锋可杀人。",
    ["$ny_tenth_xiuwen2"] = "吾以书执剑，可斩世间魍魉。",
    ["$ny_tenth_longsong1"] = "百家诸子，且听九霄龙吟。",
    ["$ny_tenth_longsong2"] = "朗朗书声，岂虚于刀斧铮鸣。",
    ["~ny_10th_guannin"] = "为国捐生，虽死无憾。",

    --孙桓

    ["ny_10th_sunhuan"] = "孙桓[十周年]",
    ["&ny_10th_sunhuan"] = "孙桓",
    ["#ny_10th_sunhuan"] = "扼龙决险",
    ["designer:ny_10th_sunhuan"] = "官方",
	["cv:ny_10th_sunhuan"] = "官方",
	["illustrator:ny_10th_sunhuan"] = "一意动漫",

    ["ny_tenth_niji"] = "逆击",
    [":ny_tenth_niji"] = "当你成为基本牌或锦囊牌的目标后，你可以摸一张牌；\
    一名角色的结束阶段，你弃置本回合以此法摸的所有牌。（你可以先使用其中一张牌）",
    ["ny_tenth_niji:draw"] = "你可以发动“逆击”摸一张牌",
    ["@ny_tenth_niji"] = "你可以使用一张本回合因“逆击”获得的牌",

    ["$ny_tenth_niji1"] = "善战者后动，一击而毙敌。",
    ["$ny_tenth_niji2"] = "我所善者，后发制人尔。",
    ["~ny_10th_sunhuan"] = "此建功立业之时，奈何。",

    --贾充

    ["ny_10th_jiachong"] = "贾充[十周年]",
    ["&ny_10th_jiachong"] = "贾充",
    ["#ny_10th_jiachong"] = "始作俑者",
    ["designer:ny_10th_jiachong"] = "官方",
	["cv:ny_10th_jiachong"] = "官方",
	["illustrator:ny_10th_jiachong"] = "铁杵文化",

    ["ny_10th_beini"] = "悖逆",
    [":ny_10th_beini"] = "出牌阶段限一次，你可以将手牌摸至或弃置至体力上限，选择两名角色，令这两名角色本回合非锁定技失效，然后令一名角色对另一名角色使用一张【杀】。",
    ["ny_10th_beini_slash"] = "悖逆",
    ["ny_tenth_shizong"] = "恃纵",
    [":ny_tenth_shizong"] = "当你需要使用一张基本牌时，你可以交给一名其他角色X张牌（X为此技能本回合发动次数），其可以将一张牌置于牌堆底，然后你视为使用需要的基本牌。若其不为当前回合角色，此技能本回合失效。",
    ["ny_tenth_shizong_give"] = "请将 %src 张牌交给一名其他角色",
    ["@ny_tenth_shizong"] = "你可以将一张牌置于牌堆底，视为 %src 使用了一张 %arg",
    ["$ny_tenth_shizong_log"] = "%from 发动 %arg 声明要使用 【%arg2】",

    ["$ny_10th_beini1"] = "臣等忠心耿耿，陛下何故谋反！",
    ["$ny_10th_beini2"] = "公等养汝，正拟今日，复何疑！",
    ["$ny_tenth_shizong1"] = "成济、王经已死，独我安享富贵。",
    ["$ny_tenth_shizong2"] = "吾乃司马公心腹，顺我者生。",
    ["~ny_10th_jiachong"] = "诸公勿怪，充乃奉命行事。",

    --董昭

    ["ny_10th_dongzhao"] = "董昭[十周年]",
    ["&ny_10th_dongzhao"] = "董昭",
    ["#ny_10th_dongzhao"] = "筹定魏勋",
    ["designer:ny_10th_dongzhao"] = "官方",
	["cv:ny_10th_dongzhao"] = "官方",
	["illustrator:ny_10th_dongzhao"] = "官方",

    ["ny_10th_yijia"] = "移驾",
    [":ny_10th_yijia"] = "当一名距离1以内的角色受到伤害后，你可以将场上的一张装备牌移至其装备区（可替换原装备）。若其因此脱离了一名角色的攻击范围，你摸一张牌。",
    ["@ny_10th_yijia"] = "你可以发动“移驾”将场上一张装备牌移动至 %src 装备区内",
    ["ny_tenth_dingji"] = "定基",
    [":ny_tenth_dingji"] = "准备阶段，你可以令一名角色将手牌调整至五张，然后其展示所有手牌，若牌名均不同，该角色可以视为使用其中的一张基本牌或普通锦囊牌。",
    ["ny_tenth_dingji_change"] = "你可以发动“定基”令一名角色将手牌调整至五张",
    ["@ny_tenth_dingji"] = "你可以视为使用手牌中的一张基本牌或普通锦囊牌",

    ["$ny_10th_yijia1"] = "曹侯忠心可鉴，可暂居其檐下。",
    ["$ny_10th_yijia2"] = "今东都糜败，陛下当移驾许昌。",
    ["$ny_tenth_dingji1"] = "丞相宜进爵国公，以彰殊勋。",
    ["$ny_tenth_dingji2"] = "今公与诸将并侯，岂天下所望哉！",
    ["~ny_10th_dongzhao"] = "凡有天下者，无虚伪不真之人。",

    --马伶俐

    ["ny_10th_malingli"] = "马伶俐[十周年]",
    ["&ny_10th_malingli"] = "马伶俐",
    ["#ny_10th_malingli"] = "火树银花",
    ["designer:ny_10th_malingli"] = "官方",
	["cv:ny_10th_malingli"] = "官方",
	["illustrator:ny_10th_malingli"] = "匠人绘",

    ["ny_10th_lima"] = "骊马",
    [":ny_10th_lima"] = "锁定技，你计算与其他角色的距离-X（X为场上的坐骑牌数，至少为1）。",
    ["ny_tenth_xiaoyin"] = "硝引",
    ["#ny_tenth_xiaoyin"] = "硝引",
    [":ny_tenth_xiaoyin"] = "准备阶段，你可以亮出牌堆顶你距离1以内的角色数张牌，获得其中的红色牌，将其中任意张黑色牌置于等量名连续的其他角色武将牌上（当有“硝引”牌的角色受到伤害时，若此伤害为火焰伤害，则伤害来源可以移去一张“硝引”牌且弃置一张与此牌类别相同的牌并令此伤害+1，否则伤害来源可以获得一张“硝引”牌并将此伤害改为火焰伤害）。\
    <font color=\"red\"><b>有一定bug，但不修！！！</b></font>",
    ["ny_tenth_xiaoyin:show"] = "你可以发动“硝引”亮出牌堆顶的 %src 张牌",
    ["@ny_tenth_xiaoyin"] = "你可以将一张黑色牌置于其他角色武将牌上",
    ["$ny_tenth_xiaoyin_buff_add"] = "%from 对 %arg 造成的伤害因 %arg2 的效果由 %arg3 点增加到 %arg4 点",
    ["$ny_tenth_xiaoyin_buff_change"] = "%from 对 %arg 造成的伤害因 %arg2 的效果被改为 %arg3",
    ["ny_tenth_xiaoyin_add"] = "你可以移去一张“硝引”牌且弃置一张与此牌类别相同的牌并令你对 %src 造成的伤害+1",
    ["ny_tenth_xiaoyin_change"] = "你可以获得一张“硝引”牌并将你对 %src 造成的伤害改为火焰伤害",
    ["ny_tenth_huahuo"] = "花火",
    [":ny_tenth_huahuo"] = "出牌阶段限一次，你可以将一张红色手牌当不计入次数限制的火【杀】使用（若目标角色有“硝引”牌，你可以改为指定所有拥有“硝引”牌的角色为目标）。",
    ["ny_tenth_huahuo:change"] = "将目标改为所有拥有“硝引”牌的角色为目标",

    ["$ny_tenth_xiaoyin1"] = "鹿栖于野，必能奔光而来。",
    ["$ny_tenth_xiaoyin2"] = "磨硝作引，可点心中灵犀。",
    ["$ny_tenth_huahuo1"] = "馏石漆取上清，可为胜爆竹之花火。",
    ["$ny_tenth_huahuo2"] = "莫道繁花好颜色，此火犹胜二月黄。",
    ["~ny_10th_malingli"] = "花无百日好，人无再少年。",

    --谢灵毓

    ["ny_10th_xielingyu"] = "谢灵毓[十周年]",
    ["&ny_10th_xielingyu"] = "谢灵毓",
    ["#ny_10th_xielingyu"] = "淑静才媛",
    ["designer:ny_10th_xielingyu"] = "官方",
	["cv:ny_10th_xielingyu"] = "官方",
	["illustrator:ny_10th_xielingyu"] = "官方",

    ["ny_10th_yuandi"] = "元嫡",
    [":ny_10th_yuandi"] = "当其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.令你与其各摸一张牌。",
    ["ny_10th_yuandi:draw"] = "与 %src 各摸一张牌",
    ["ny_10th_yuandi:discard"] = "弃置 %src 一张手牌",
    ["ny_10th_xinyou"] = "心幽",
    [":ny_10th_xinyou"] = "出牌阶段限一次，你可以回满体力并将手牌摸至体力上限。若你因此摸超过两张牌，结束阶段你失去１点体力；若你因此回复体力，结束阶段你弃置一张牌。",

    ["$ny_10th_yuandi1"] = "此生与君为好，共结连理。",
    ["$ny_10th_yuandi2"] = "结发元嫡，其情唯衷孙郎。",
    ["$ny_10th_xinyou1"] = "我有幽月一斛，可醉十里春风。",
    ["$ny_10th_xinyou2"] = "心在方外，故而不闻市井之声。",
    ["~ny_10th_xielingyu"] = "翠瓦红墙处，最折意中人。",

    --谋周瑜

    ["ny_10th_mouzhouyu"] = "谋周瑜[十周年]",
    ["&ny_10th_mouzhouyu"] = "周瑜",
    ["#ny_10th_mouzhouyu"] = "炽谋英隽",
    ["designer:ny_10th_mouzhouyu"] = "官方",
	["cv:ny_10th_mouzhouyu"] = "官方",
	["illustrator:ny_10th_mouzhouyu"] = "官方",
    ["ny_10th_mouzhouyu2"] = "谋周瑜[十周年]",

    ["ny_10th_ronghuo"] = "融火",
    [":ny_10th_ronghuo"] = "锁定技，你使用火【杀】或【火攻】造成的伤害改为X（X为全场势力数）。",
    ["$ny_10th_ronghuo_damage"] = "%from 对 %to 造成的伤害因 %arg 的效果由 %arg2 点改为 %arg3 点",
    ["ny_10th_yingmou"] = "英谋",
    [":ny_10th_yingmou"] = "转换技，游戏开始时自选①②状态；每回合限一次，当你对其他角色使用牌后，你可以选择其中一名目标角色，\
    ①你将手牌摸至与其相同（至多摸五张），然后视为对其使用一张【火攻】；\
    ②你选择全场手牌数最多的另一名角色，若其手牌中有【杀】或伤害类锦囊牌，则其对该目标角色使用这些牌，否则其将手牌弃置至与你相同。",
    [":ny_10th_yingmou1"] = "转换技，游戏开始时自选①②状态；每回合限一次，当你对其他角色使用牌后，你可以选择其中一名目标角色，\
    ①你将手牌摸至与其相同（至多摸五张），然后视为对其使用一张【火攻】；\
    <font color=\"#01A5AF\"><s>②你选择全场手牌数最多的另一名角色，若其手牌中有【杀】或伤害类锦囊牌，则其对该目标角色使用这些牌，否则其将手牌弃置至与你相同。</s></font>",
    [":ny_10th_yingmou2"] = "转换技，游戏开始时自选①②状态；每回合限一次，当你对其他角色使用牌后，你可以选择其中一名目标角色，\
    <font color=\"#01A5AF\"><s>①你将手牌摸至与其相同（至多摸五张），然后视为对其使用一张【火攻】；</s></font>\
    ②你选择全场手牌数最多的另一名角色，若其手牌中有【杀】或伤害类锦囊牌，则其对该目标角色使用这些牌，否则其将手牌弃置至与你相同。",
    ["ny_10th_yingmou_first"] = "你可以视为对其中一名目标角色使用了【火攻】",
    ["ny_10th_yingmou_second_first"] = "你可以令全场手牌最多的角色对该角色使用手牌中的伤害类牌",
    ["ny_10th_yingmou_second_second"] = "请选择一名手牌最多的角色",
 
    ["$ny_10th_ronghuo1"] = "火莲绽江矶，炎映三千弱水。",
    ["$ny_10th_ronghuo2"] = "奇志吞樯橹，潮平百万寇贼。",
    ["$ny_10th_yingmou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
    ["$ny_10th_yingmou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
    ["~ny_10th_mouzhouyu"] = "人生之艰难，犹如不息之长河。",

    --孙綝

    ["ny_10th_sunchen"] = "孙綝[十周年]",
    ["&ny_10th_sunchen"] = "孙綝",
    ["#ny_10th_sunchen"] = "凶竖盈溢",
    ["designer:ny_10th_sunchen"] = "官方",
	["cv:ny_10th_sunchen"] = "官方",
	["illustrator:ny_10th_sunchen"] = "官方",

    ["ny_10th_zuowei"] = "作威",
    [":ny_10th_zuowei"] = "当你于回合内使用牌时，若你的手牌数：大于X，你可以令此牌不能被响应；等于X，你可以对一名其他角色造成1点伤害；小于X，你可以摸两张牌且本回合不能再发动此项效果（X为你装备区里的牌数，至少为1）。",
    ["ny_10th_zuowei:noresponse"] = "你可以发动“作威”令【%src】不可响应",
    ["ny_10th_zuowei:draw"] = "你可以发动“作威”摸两张牌",
    ["@ny_10th_zuowei"] = "你可以发动“作威”对一名其他角色造成1点伤害",
    ["$ny_10th_zuowei_noresponse"] = "%from 使用的 %card 因 %arg 不可被响应",
    ["ny_10th_zigu"] = "自固",
    [":ny_10th_zigu"] = "出牌阶段限一次，你可以弃置一张牌，获得场上的一张装备牌。若你没有以此法获得其他角色的牌，你摸一张牌。",
    ["@ny_10th_zigu"] = "你请获得场上一张装备牌",

    ["$ny_10th_zuowei1"] = "不顺我意者，当填在野之壑。",
    ["$ny_10th_zuowei2"] = "吾令不从者，当膏霜锋之锷。",
    ["$ny_10th_zigu1"] = "卿有成材良木，可妆吾家江山。",
    ["$ny_10th_zigu2"] = "吾好锦衣玉食，卿家可愿割爱否？",
    ["~ny_10th_sunchen"] = "臣家火起，请离席救之。",

    --双壁·孙策

    ["ny_10th_sunce_shuangbi"] = "双壁·孙策[十周年]",
    ["&ny_10th_sunce_shuangbi"] = "孙策",
    ["#ny_10th_sunce_shuangbi"] = "江东小霸王",
    ["designer:ny_10th_sunce_shuangbi"] = "官方",
	["cv:ny_10th_sunce_shuangbi"] = "官方",
	["illustrator:ny_10th_sunce_shuangbi"] = "官方",

    ["ny_tenth_shuangbi"] = "双壁",
    [":ny_tenth_shuangbi"] = "出牌阶段限一次，你可以选择一名“周瑜”助战：\
    界周瑜：摸X张牌，本回合手牌上限+X；\
    神周瑜：弃置至多X张牌，随机造成等量火焰伤害；\
    谋周瑜：视为使用X张火【杀】或【火攻】。\
    X为存活人数。",
    ["ny_tenth_shuangbi:draw"] = "界周瑜：摸%src张牌，本回合手牌上限+%src",
    ["ny_tenth_shuangbi:damage"] = "神周瑜：弃置至多%src张牌，随机造成等量火焰伤害",
    ["ny_tenth_shuangbi:slash"] = "谋周瑜：视为使用%src张火【杀】或【火攻】",
    ["ny_tenth_shuangbi_discard"] = "你可以弃置至多%src张牌，然后随机造成等量火焰伤害",
    ["@ny_tenth_shuangbi"] = "请使用 【%src】",
    ["ny_tenth_shuangbi_mouzhouyu"] = "双壁·谋周瑜",

    ["$ny_tenth_shuangbi1"] = "有公瑾在，无后顾之忧。",
    ["$ny_tenth_shuangbi2"] = "公瑾良策，解我围困。",
    ["$ny_tenth_shuangbi3"] = "将相本无种，男儿当自强。",
    ["$ny_tenth_shuangbi4"] = "乱世出英杰，江东生异彩。",
    ["$ny_tenth_shuangbi5"] = "红莲业火，焚汝残躯。",
    ["$ny_tenth_shuangbi6"] = "神火天降，樯橹灰飞烟灭。",
    ["$ny_tenth_shuangbi7"] = "火莲绽江矶，炎映三千弱水。",
    ["$ny_tenth_shuangbi8"] = "奇志吞樯橹，潮平百万寇贼。",
    ["~ny_10th_sunce_shuangbi"] = "恕反复无常，岂可信。",

    --曹轶

    ["ny_10th_caoyi"] = "曹轶[十周年]",
    ["&ny_10th_caoyi"] = "曹轶",
    ["#ny_10th_caoyi"] = "飒姿缔燹",
    ["designer:ny_10th_caoyi"] = "官方",
	["cv:ny_10th_caoyi"] = "官方",
	["illustrator:ny_10th_caoyi"] = "官方",
    ["ny_10th_caoyi_tiger"] = "曹轶的小老虎",
    ["&ny_10th_caoyi_tiger"] = "寅君",

    ["ny_10th_miyi"] = "蜜饴",
    [":ny_10th_miyi"] = "准备阶段，你可以选择一项并令任意名角色执行之：1.回复1点体力；2.受到1点你造成的伤害。若如此做，本回合的结束阶段，这些角色执行另一项。",
    ["ny_10th_miyi:recover"] = "回复1点体力",
    ["ny_10th_miyi:damage"] = "受到1点伤害",
    ["$ny_10th_miyi_chosen"] = "%from 发动 %arg 选择了 %arg2, 目标是 %to",
    ["@ny_10th_miyi"] = "你可以令任意名角色 %src",
    ["ny_10th_miyi_recover"] = "回复1点体力",
    ["ny_10th_miyi_damage"] = "受到1点伤害",
    ["$ny_10th_miyi_chosen"] = "%from 发动 %arg 选择了 %arg2, 目标是 %to",
    ["ny_10th_yinjun"] = "寅君",
    [":ny_10th_yinjun"] = "当你对其他角色使用手牌中唯一目标的【杀】或锦囊牌结算后，可以视为对其使用一张【杀】（此杀造成的伤害无来源）。若你此技能本回合发动次数大于你当前体力值，此技能本回合失效。",
    ["ny_10th_yinjun:slash"] = "你可以发动“寅君”令小老虎对 %src 使用一张【杀】",

    ["$ny_10th_miyi1"] = "百战黄沙苦，舒颜红袖甜。",
    ["$ny_10th_miyi2"] = "撷蜜凝饴糖，入喉润心颜。",
    ["$ny_10th_yinjun1"] = "既乘虎豹之威，当弘大魏万年。",
    ["$ny_10th_yinjun2"] = "今日青锋在手，可驯四方虎狼。",
    ["~ny_10th_caoyi"] = "霜落寒鸦浦，天下无故人。",

    --诸葛若雪

    ["ny_10th_zhugeruoxue"] = "诸葛若雪[十周年]",
    ["&ny_10th_zhugeruoxue"] = "诸葛若雪",
    ["#ny_10th_zhugeruoxue"] = "玉榭霑露",
    ["designer:ny_10th_zhugeruoxue"] = "官方",
	["cv:ny_10th_zhugeruoxue"] = "官方",
	["illustrator:ny_10th_zhugeruoxue"] = "官方",

    ["ny_10th_qiongying"] = "琼英",
    [":ny_10th_qiongying"] = "出牌阶段限一次，你可以移动场上的一张牌，然后你弃置一张此花色的手牌，不能弃置则你展示所有手牌。",
    ["@ny_10th_qiongying"] = "请将 【%src】 移动给一名角色",
    ["ny_10th_qiongying_discard"] = "请弃置一张 %src 牌",
    ["ny_tenth_nuanhui"] = "暖惠",
    [":ny_tenth_nuanhui"] = "结束阶段，你可以选择一名角色，该角色可以视为使用X张基本牌（X为其装备区里的牌数）。若其以此法使用的牌数大于1，其弃置装备区里的所有牌。",
    ["ny_tenth_nuanhui_chosen"] = "你可以令一名角色可以视为使用X张基本牌（X为其装备区里的牌数）",
    ["@ny_tenth_nuanhui"] = "请使用 【%src】（当前第 %arg 张）",

    ["$ny_10th_qiongying1"] = "冰心碎玉壶，光转琼英灿。",
    ["$ny_10th_qiongying2"] = "玉心玲珑意，撷英倚西楼。",
    ["$ny_tenth_nuanhui1"] = "暖阳映雪，可照八九之风光。",
    ["$ny_tenth_nuanhui2"] = "晓风和畅，吹融附柳之霜雪。",
    ["~ny_10th_zhugeruoxue"] = "自古佳人叹白头。",

    --夏侯楙

    ["ny_10th_xiahoumao"] = "夏侯楙[十周年]",
    ["&ny_10th_xiahoumao"] = "夏侯楙",
    ["#ny_10th_xiahoumao"] = "束甲之鸟",
    ["designer:ny_10th_xiahoumao"] = "官方",
	["cv:ny_10th_xiahoumao"] = "官方",
	["illustrator:ny_10th_xiahoumao"] = "官方",

    ["ny_10th_tongwei"] = "统围",
    [":ny_10th_tongwei"] = "出牌阶段限一次，你可以选择一名其他角色并重铸两张牌。当其下一次使用牌结算结束后，若此牌点数处于你这两张牌之间，你视为对其使用一张【杀】或【过河拆桥】。",
    ["ny_10th_cuguo"] = "蹙国",
    [":ny_10th_cuguo"] = "锁定技，当你每回合第一次使用牌被抵消后，你弃置一张牌，令此牌对目标角色再结算一次，然后若仍被抵消，你失去1点体力。",

    ["$ny_10th_tongwei1"] = "今统虎贲十万，必困金龙于斯。",
    ["$ny_10th_tongwei2"] = "昔年将军七出长坂，今尚能饭否？",
    ["$ny_10th_cuguo1"] = "本欲开疆拓土，奈何丧师辱国。",
    ["$ny_10th_cuguo2"] = "千里锦绣之地，皆亡逆贼之手。",
    ["~ny_10th_xiahoumao"] = "志大才疏，以致今日之祸。",

    --董贵人·第二版

    ["ny_10th_dongguiren_second"] = "董贵人[十周年二版]",
    ["&ny_10th_dongguiren_second"] = "董贵人",
    ["#ny_10th_dongguiren_second"] = "衣雪宫柳",
    ["designer:ny_10th_dongguiren_second"] = "官方",
	["cv:ny_10th_dongguiren_second"] = "官方",
	["illustrator:ny_10th_dongguiren_second"] = "君桓文化",

    ["ny_10th_lingfang"] = "凌芳",
    [":ny_10th_lingfang"] = "锁定技，准备阶段，或当其他角色对你/你对其他角色使用的黑色牌结算结束后，你获得1个“绞”标记。",
    ["ny_10th_jiao"] = "绞",
    [":&ny_10th_jiao"] = "若你拥有技能“风影”，你可以将点数小于 %src 的牌当作记录的牌使用",
    ["ny_10th_lianzhi"] = "连枝",
    [":ny_10th_lianzhi"] = "游戏开始时，你选择一名其他角色。当你进入濒死状态时，若该角色没有死亡，你回复１点体力且你与其各摸一张牌（每回合限一次）；该角色死亡后，你可以选择一名其他角色，你与其获得“受责”，且其获得与你等量的“绞”标记（至少获得一个）。",
    ["@ny_10th_lianzhi"] = "请选择一名“连枝”角色",
    ["ny_10th_lianzhi_chosen"] = "你可以选择一名其他角色，你与其获得“受责”，且其获得与你等量的“绞”标记（至少获得一个）",
    ["ny_10th_shouze"] = "受责",
    [":ny_10th_shouze"] = "锁定技，结束阶段，你移去1个“绞”标记，随机获得弃牌堆中的一张黑色牌，失去1点体力。",
    ["ny_tenth_fengying"] = "风影",
    [":ny_tenth_fengying"] = "每个回合开始时，记录此时弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。你手牌中点数小于等于“绞”标记数量的一张牌可以当做你记录的牌使用，且此牌没有距离和次数限制。每回合每种牌名限一次。",
    ["@ny_tenth_fengying"] = "你可以将一张符合条件的牌当作【%src】使用",
    ["ny_tenth_fengying:nocards"] = "没有可以使用的牌",

    ["$ny_10th_shouze1"] = "白绫加之我颈，其罪何患无辞？",
    ["$ny_10th_lingfang1"] = "曹贼欲加之罪，何患无据可言。",
    ["$ny_10th_lingfang2"] = "花落水自流，何须怨东风。",
    ["$ny_10th_lianzhi1"] = "刘董同气连枝，一损则俱损。",
    ["$ny_10th_lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
    ["$ny_tenth_fengying1"] = "可怜东篱含蕾树，孤影落秋风",
    ["$ny_tenth_fengying2"] = "西风落，西风落，宫墙不堪破。",
    ["~ny_10th_dongguiren_second"] = "陛下乃大汉皇帝，不可言乞！",

    --庞山民

    ["ny_10th_pangshanmin"] = "庞山民[十周年]",
    ["&ny_10th_pangshanmin"] = "庞山民",
    ["#ny_10th_pangshanmin"] = "抱玉向晚",
    ["designer:ny_10th_pangshanmin"] = "官方",
	["cv:ny_10th_pangshanmin"] = "官方",
	["illustrator:ny_10th_pangshanmin"] = "官方",

    ["ny_10th_caisi"] = "才思",
    [":ny_10th_caisi"] = "当你在回合内/回合外使用基本牌后，你可以从牌堆/弃牌堆获得1张随机的非基本牌。每次发动该技能后，若发动次数：\
    小于体力上限：本回合下次获得牌张数+1；\
    大于等于体力上限：本回合此技能失效。",
    ["ny_10th_caisi:get"] = "你可以发动“才思”获得 %src 张非基本牌",
    [":&ny_10th_caisi"] = "本回合已发动过 %src 次“才思”",
    ["ny_10th_zhuoli"] = "擢吏",
    [":ny_10th_zhuoli"] = "锁定技，每个回合结束时，若你本回合使用牌或获得牌的张数大于体力值，你增加一点体力上限并回复一点体力（体力上限不能超过游戏开始时人数）。",
    [":&ny_10th_zhuoli"] = "本回合使用牌或获得牌的张数为 %src",

    ["$ny_10th_caisi1"] = "扶耒耜、植桑陌，习诗书以传家。",
    ["$ny_10th_caisi2"] = "唯楚有才，于庞门为盛。",
    ["$ny_10th_zhuoli1"] = "良梓千万，当擢才而用。",
    ["$ny_10th_zhuoli2"] = "任人唯才，不妨寒门入上品。",
    ["~ny_10th_pangshanmin"] = "九品中正后，庙堂无寒门。",

    --郤正

    ["ny_10th_xizheng"] = "郤正[十周年]",
    ["&ny_10th_xizheng"] = "郤正",
    ["#ny_10th_xizheng"] = "君子有取",
    ["designer:ny_10th_xizheng"] = "官方",
	["cv:ny_10th_xizheng"] = "官方",
	["illustrator:ny_10th_xizheng"] = "官方",

    ["ny_10th_danyi"] = "耽意",
    [":ny_10th_danyi"] = "当你使用牌指定目标后，若此牌与你使用的上一张牌有相同的目标，你可以摸X张牌（X为相同的目标数）。",
    ["ny_10th_danyi:draw"] = "你可以发动“耽意”摸 %src 张牌",
    [":&ny_10th_danyi"] = "你使用的上一张牌曾指定该角色为目标",
    ["ny_tenth_wencan"] = "文灿",
    [":ny_tenth_wencan"] = "出牌阶段限一次，你可以令至多两名体力值不同的其他角色依次选择一项：1.弃置两张花色不同的牌；2.令你本回合对其使用牌无距离与次数限制。",
    ["@ny_tenth_wencan"] = "请弃置两张花色不同的牌<br/>或取消令 %src 本回合对你使用牌无距离的和次数限制",

    ["$ny_10th_danyi1"] = "满城锦绣，何及笔下春秋？",
    ["$ny_10th_danyi2"] = "一心向学，不闻窗外风雨。",
    ["$ny_tenth_wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
    ["$ny_tenth_wencan2"] = "众星灿于九天，犹雅文耀于万世。",
    ["~ny_10th_xizheng"] = "此生有涯，奈何学海无涯。",

    --李典

    ["ny_10th_lidian"] = "李典[十周年二版]",
    ["&ny_10th_lidian"] = "李典",
    ["#ny_10th_lidian"] = "深明大义",
    ["designer:ny_10th_lidian"] = "官方",
	["cv:ny_10th_lidian"] = "官方",
	["illustrator:ny_10th_lidian"] = "张帅",

    ["ny_10th_wangxi"] = "忘隙",
    [":ny_10th_wangxi"] = "当你对其他角色造成1点伤害后，或受到其他角色造成的1点伤害后，你可以摸两张牌，交给其一张牌。",
    ["ny_10th_wangxi:draw"] = "你可以发动“忘隙”摸2张牌并交给 %src 1张牌",
    ["@ny_10th_wangxi"] = "请交给 %src 1张牌",

    ["$ny_10th_wangxi1"] = "前尘往事，莫再提起。",
    ["$ny_10th_wangxi2"] = "大丈夫，何拘小节？",

    --乐周妃·第二版

    ["ny_10th_yuezhoufei_second"] = "乐周妃[十周年二版]",
    ["&ny_10th_yuezhoufei_second"] = "周妃",
    ["#ny_10th_yuezhoufei_second"] = "芙蓉泣露",
    ["designer:ny_10th_yuezhoufei_second"] = "官方",
	["cv:ny_10th_yuezhoufei_second"] = "官方",
	["illustrator:ny_10th_yuezhoufei_second"] = "官方",

    ["ny_10th_lingkong_second"] = "灵箜",
    [":ny_10th_lingkong_second"] = "锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。当你每回合第一次于摸牌阶段外获得牌后，将这些牌标记为“箜篌”牌。",
    ["ny_10th_konghou_second"] = "箜篌",
    ["ny_10th_xianshu_second"] = "贤淑",
    [":ny_10th_xianshu_second"] = "出牌阶段，你可以展示一张“箜篌”牌并交给一名其他角色，\
    然后摸X张牌（X为你与该角色的体力值之差且至多为5）。\
    若此牌为红色，且该角色体力值小于等于你，该角色回复1点体力；\
    若此牌为黑色，且该角色体力值大于等于你，该角色失去1点体力。",

    ["$ny_10th_lingkong_second1"] = "箜篌奏晚歌，渔樵有归期。",
	["$ny_10th_lingkong_second2"] = "吴宫绿荷惊涟漪，飞燕啄新泥。",
	["$ny_10th_xianshu_second1"] = "居宠而不骄，秉贤淑于内庭。",
	["$ny_10th_xianshu_second2"] = "心怀玲珑意，宜家国于春秋。",
    ["~ny_10th_yuezhoufei_second"] = "红颜薄命，望君珍重。",

    --曹宪

    ["ny_10th_caoxian"] = "曹宪[十周年]",
    ["&ny_10th_caoxian"] = "曹宪",
    ["#ny_10th_caoxian"] = "蝶步韶华",
    ["designer:ny_10th_caoxian"] = "官方",
	["cv:ny_10th_caoxian"] = "官方",
	["illustrator:ny_10th_caoxian"] = "官方",

    ["ny_10th_lingxi"] = "灵犀",
    [":ny_10th_lingxi"] = "出牌阶段开始时或结束时，你可以将至多体力上限张牌置于你的武将牌上，称为“翼”（当有“翼”被移去后，你将手牌调整至“翼”包含的花色数的两倍）。",
    ["@ny_10th_lingxi"] = "你可以将至多 %src 张牌当作“翼”置于武将牌上",
    ["ny_10th_lingxi_dis"] = "灵犀",
    ["ny_10th_yi"] = "翼",
    ["ny_tenth_zhifou"] = "知否",
    [":ny_tenth_zhifou"] = "当你使用牌结算结束后，你可以移去至少X张“翼”（X为你本回合发动此技能的次数），选择一名角色并选择一项（每回合每项限一次），令其执行之：1.将一张牌置入“翼”；2.弃置两张牌；3.失去1点体力。",
    ["@ny_tenth_zhifou"] = "请移去至少 %src 张“翼”并选择一名角色",
    ["ny_tenth_zhifou:lose"] = "失去1点体力",
    ["ny_tenth_zhifou:discard"] = "弃置两张牌",
    ["ny_tenth_zhifou:put"] = "将一张牌置入“翼”",
    ["ny_tenth_zhifou_put"] = "请将一张牌置入“翼”",
    ["$ny_tenth_zhifou_chosen"] = "%from 选择了令 %to 执行 %arg",

    ["$ny_10th_lingxi1"] = "灵犀渡清潭，涟漪扰我心。",
    ["$ny_10th_lingxi2"] = "心有玲珑曲，万籁皆空灵。",
    ["$ny_tenth_zhifou1"] = "满怀相思意，念君君可知？",
    ["$ny_tenth_zhifou2"] = "世有人万万，相知无二三。",
    ["~ny_10th_caoxian"] = "恨生枭雄府，恨嫁君王家。",

    --董翓·第二版

    ["ny_10th_dongxie_second"] = "董翓[十周年二版]",
    ["&ny_10th_dongxie_second"] = "董翓",
    ["#ny_10th_dongxie_second"] = "月辉映荼",
    ["designer:ny_10th_dongxie_second"] = "官方",
	["cv:ny_10th_dongxie_second"] = "官方",
	["illustrator:ny_10th_dongxie_second"] = "官方",

    ["ny_tenth_jiaoxia_second"] = "狡黠",
    [":ny_tenth_jiaoxia_second"] = "出牌阶段开始时，你可令你此阶段所有手牌视为【杀】。以此法使用的【杀】若造成伤害，你可于此【杀】结算完毕后使用原卡牌。出牌阶段，你对每名其他角色使用的第一张【杀】无次数和距离限制。",
    ["ny_tenth_jiaoxia_second:slash"] = "你可令你此阶段所有手牌视为【杀】",
    ["@ny_tenth_jiaoxia_second"] = "你可以视为使用了 【%src】", 
    ["ny_10th_humei_second"] = "狐魅",
    [":ny_10th_humei_second"] = "出牌阶段每项限一次，你可令一名体力值至多为x的角色（x为你本阶段造成的伤害值）：1、摸一张牌；2、交给你一张牌；3、回复1点体力。",
    ["@ny_10th_humei_second"] = "请交给 %src 一张牌",
    ["ny_10th_humei_second:draw"] = "摸一张牌",
    ["ny_10th_humei_second:give"] = "交给你一张牌",
    ["ny_10th_humei_second:recover"] = "回复1点体力",

    ["$ny_tenth_jiaoxia_second1"] = "暗剑匿踪，现时必捣黄龙。",
	["$ny_tenth_jiaoxia_second2"] = "袖中藏刃，欲取诸君之头。",
    ["$ny_10th_humei_second1"] = "尔为靴下之臣，当行顺我之事。",
	["$ny_10th_humei_second2"] = "妾身一笑，可倾将军之城否？",
    ["~ny_10th_dongxie_second"] = "覆巢之下，断无完卵余生。",

    --武陆逊

    ["ny_10th_wuluxun"] = "武陆逊[十周年]",
    ["#ny_10th_wuluxun"] = "释武怀儒",
    ["&ny_10th_wuluxun"] = "陆逊",
    ["designer:ny_10th_wuluxun"] = "官方",
	["cv:ny_10th_wuluxun"] = "官方",
	["illustrator:ny_10th_wuluxun"] = "官方",

    ["ny_10th_xiongmu"] = "雄幕",
    [":ny_10th_xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌洗入牌堆，从牌堆或弃牌堆中获得等量点数为8的牌，这些牌不计入你的手牌上限。\
    你每回合首次受到伤害时，若你的手牌数不大于体力值，此伤害-1。",
    ["@ny_10th_xiongmu"] = "请将任意张牌洗入牌堆并获得等量点数为8的牌",
    ["ny_10th_xiongmu:reduce"] = "你可以发动“雄幕”令此伤害-1",
    ["$ny_10th_xiongmu_reduce"] = "%from 受到的伤害由 %arg 点减少到了 %arg2 点",
    ["ny_10th_zhangcai"] = "彰才",
    [":ny_10th_zhangcai"] = "你使用或打出点数为8的牌时，可以摸X张牌。（X为手牌中与此牌点数相同的牌且至少为1）",
    ["ny_10th_zhangcai:draw"] = "你可以发动“彰才”摸 %src 张牌",
    ["ny_10th_ruxian"] = "儒贤",
    [":ny_10th_ruxian"] = "限定技，出牌阶段，你可以令“彰才”改为所有点数均可触发直到你的下个回合开始。",

    ["$ny_10th_xiongmu1"] = "步步为营者，定无后顾之虞。",
    ["$ny_10th_xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
    ["$ny_10th_zhangcai2"] = "今提墨笔绘乾坤，湖海添色山永春。",
    ["$ny_10th_zhangcai1"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
    ["$ny_10th_ruxian1"] = "儒道尚仁而有礼，贤者知名而独悟。",
    ["$ny_10th_ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
    ["~ny_10th_wuluxun"] = "此生清白，不为浊泥所染。",

    --神赵云·高达一号

    ["ny_10th_zhaoyun_thefirst"] = "神赵云·高达一号[十周年]",
    ["#ny_10th_zhaoyun_thefirst"] = "龙腾虎跃",
    ["&ny_10th_zhaoyun_thefirst"] = "赵云",
    ["designer:ny_10th_zhaoyun_thefirst"] = "官方",
	["cv:ny_10th_zhaoyun_thefirst"] = "官方",
	["illustrator:ny_10th_zhaoyun_thefirst"] = "官方",

    ["ny_10th_jvejin"] = "绝境",
    [":ny_10th_jvejin"] = "锁定技，你跳过摸牌阶段，你的手牌始终为4。",
    ["ny_10th_longhun"] = "龙魂",
    [":ny_10th_longhun"] = "你的牌可以按以下规则使用或打出：红桃当【桃】；方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】。（每回合限20次）",
    [":&ny_10th_longhun"] = "本回合已发动 %src 次“龙魂”",
    ["ny_10th_zhanjiang"] = "斩将",
    [":ny_10th_zhanjiang"] = "准备阶段，如果场上有【青釭剑】，你可以获得之。",
    ["ny_10th_zhanjiang:get"] = "你可以发动“斩将”获得场上的【青釭剑】",

    ["$ny_10th_jvejin1"] = "龙翔九天，曳日月于天地，换旧符于新岁。",
    ["$ny_10th_jvejin2"] = "御风万里，辟邪祟于宇外，映祥瑞于神州。",
    ["$ny_10th_longhun1"] = "龙诞新岁，普天同庆，魂佑宇内，裔泽炎黄。",
    ["$ny_10th_longhun2"] = "龙吐息而万物生，今龙临神州，华夏当兴！",
    ["$ny_10th_zhanjiang1"] = "暂无",
    ["~ny_10th_zhaoyun_thefirst"] = "酒足驱年兽，新岁老一人。",

    --乐小乔

    ["ny_10th_yuexiaoqiao"] = "乐小乔[十周年]",
    ["&ny_10th_yuexiaoqiao"] = "小乔",
    ["#ny_10th_yuexiaoqiao"] = "绿绮嫒媛",
    ["designer:ny_10th_yuexiaoqiao"] = "官方",
	["cv:ny_10th_yuexiaoqiao"] = "官方",
	["illustrator:ny_10th_yuexiaoqiao"] = "官方",

    ["ny_10th_qiqin"] = "绮琴",
    [":ny_10th_qiqin"] = "锁定技，游戏开始时，将初始手牌标记为“琴”牌（“琴”牌不计入你的手牌上限）；准备阶段，你获得弃牌堆中所有的“琴”牌。",
    ["ny_10th_qin"] = "琴",
    ["ny_10th_weiwan"] = "媦婉",
    [":ny_10th_weiwan"] = "出牌阶段限一次，你可以弃置一张“琴”，选择一名其他角色，随机获得其区域内与此“琴”不同花色的牌各一张。若你获得的牌数为：1，其失去1点体力；2，你本回合对其使用牌无距离与次数限制；3，你本回合不能对其使用牌。",
    ["ny_10th_weiwan_nolimit"] = "媦婉无限制",
    ["ny_10th_weiwan_limit"] = "媦婉不能用牌",

    ["$ny_10th_qiqin1"] = "渔歌唱晚落山月，素琴薄暮声。",
    ["$ny_10th_qiqin2"] = "指上琴音浅，欲听还需抚瑶琴。",
    ["$ny_10th_weiwan1"] = "繁花初成，所幸未晚于桑榆。",
    ["$ny_10th_weiwan2"] = "群胥泛舟，共载佳期若瑶梦。",
    ["~ny_10th_yuexiaoqiao"] = "独寄人间白首，曲误周郎难顾。",

    --周不疑

    ["ny_10th_zhoubuyi"] = "周不疑[十周年]",
    ["&ny_10th_zhoubuyi"] = "周不疑",
    ["#ny_10th_zhoubuyi"] = "幼有异才",
    ["designer:ny_10th_zhoubuyi"] = "官方",
	["cv:ny_10th_zhoubuyi"] = "官方",
	["illustrator:ny_10th_zhoubuyi"] = "虫师",

    ["ny_tenth_silun"] = "四论",
    [":ny_tenth_silun"] = "准备阶段，或当你受到伤害后，你可以摸四张牌，将四张牌依次置于场上、牌堆顶或牌堆底（装备区里牌数因此变化的角色复原其武将牌）。",
    ["ny_tenth_silun:draw"] = "你可以发动“四论”摸四张牌",
    ["@ny_tenth_silun"] = "请将一张牌置于场上、牌堆顶或牌堆底（第%src张）",
    ["$ny_tenth_silun_drawpile"] = "%from 选择了将 %card %arg",
    ["ny_tenth_silun:top"] = "置于牌堆顶",
    ["ny_tenth_silun:bottom"] = "置于牌堆底",
    ["$ny_tenth_silun_field"] = "%from 选择了将 %card 置于 %to 的 %arg",
    ["ny_tenth_shiji"] = "十计",
    [":ny_tenth_shiji"] = "一名角色的结束阶段，若其本回合未造成过伤害，你可以声明一种普通锦囊牌的牌名（每种牌名每轮限一次），然后其可以将一张手牌当你声明的牌使用（其不能指定自己为目标）。",
    ["@ny_tenth_shiji"] = "你可以将一张手牌当作【%src】使用（不能指定自己为目标）",
    ["$ny_tenth_shiji_declare"] = "%from 声明了 【%arg】",

    ["$ny_tenth_silun1"] = "习守静之术，行务时之风。",
    ["$ny_tenth_silun2"] = "纵笔瑞白雀，满座尽高朋。",
    ["$ny_tenth_shiji1"] = "区区十丈之城，何须丞相图画。",
    ["$ny_tenth_shiji2"] = "顽垒在前，可依不疑之计施为。",
    ["~ny_10th_zhoubuyi"] = "人心者，叵测也。",

    --田尚衣

    ["ny_10th_tianshangyi"] = "田尚衣[十周年]",
    ["&ny_10th_tianshangyi"] = "田尚衣",
    ["#ny_10th_tianshangyi"] = "婀娜盈珠袖",
    ["designer:ny_10th_tianshangyi"] = "官方",
	["cv:ny_10th_tianshangyi"] = "官方",
	["illustrator:ny_10th_tianshangyi"] = "alien",

    ["ny_10th_xiaoren"] = "绡刃",
    [":ny_10th_xiaoren"] = "每回合限一次，当你造成伤害后，你可以进行一次判定，若结果为：红色，你可以令一名角色回复1点体力，然后若其未受伤，其摸一张牌；黑色，对受伤角色的上家或下家造成1点伤害，然后你可以再次判定并执行对应效果直到有角色进入濒死状态。",
    ["@ny_10th_xiaoren-recover"] = "你可以令一名角色回复1点体力",
    ["@ny_10th_xiaoren-damage"] = "你可以对 %src 的上家或下家造成1点伤害",
    ["ny_tenth_posuo"] = "婆娑",
    [":ny_tenth_posuo"] = "出牌阶段每种花色限一次，若你此阶段仍未造成过伤害，你可以将一张手牌当作此花色有的一张伤害牌使用。",
    ["@ny_tenth_posuo"] = "请使用【%src】",
    ["ny_tenth_posuo:failed"] = "此花色没有可以使用的伤害牌",

    ["$ny_10th_xiaoren1"] = "红绡举腕重，明眸最溺人。",
    ["$ny_10th_xiaoren2"] = "飘然回雪轻，言然游龙惊。",
    ["$ny_tenth_posuo1"] = "绯纱婆娑起，佳人笑靥红。",
    ["$ny_tenth_posuo2"] = "红烛映俏影，一舞影斑斓。",
    ["~ny_10th_tianshangyi"] = "红梅待百花，魏宫无春风。",

    --星袁绍

    ["ny_10th_xingyuanshao"] = "星袁绍[十周年]",
    ["&ny_10th_xingyuanshao"] = "星袁绍",
    ["#ny_10th_xingyuanshao"] = "熏灼群魔",
    ["designer:ny_10th_xingyuanshao"] = "官方",
	["cv:ny_10th_xingyuanshao"] = "官方",
	["illustrator:ny_10th_xingyuanshao"] = "鬼画府",

    ["ny_10th_xiaoyan"] = "硝焰",
    [":ny_10th_xiaoyan"] = "游戏开始时，你对所有其他角色各造成1点火焰伤害，然后这些角色可以交给你一张牌并回复1点体力。",
    ["@ny_10th_xiaoyan"] = "你可以交给 %src 一张牌并回复一点体力",
    ["ny_tenth_zongshi"] = "纵势",
    [":ny_tenth_zongshi"] = "出牌阶段，你可以展示一张基本牌或普通锦囊牌，然后将与此牌花色相同的所有其他手牌当此牌使用（指定目标数改为转化此牌的牌数）。",
    ["@ny_tenth_zongshi"] = "你可以发动一次“纵势”",
    ["@ny_tenth_zongshi-targets"] = "请为 【%src】选择至多 %arg 名目标",
    ["ny_10th_jiaowang"] = "骄妄",
    [":ny_10th_jiaowang"] = "锁定技，每轮结束时，若本轮没有角色死亡，你失去1点体力，发动一次“硝焰”。",
    ["ny_10th_aoshi"] = "傲势",
    [":ny_10th_aoshi"] = "主公技，其他群势力角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以发动一次“纵势”。",
    ["ny_10th_aoshi_give"] = "傲势",
    [":ny_10th_aoshi_give"] = "群势力角色的出牌阶段限一次， 你可以交给一名拥有“傲势”的其他角色一张手牌，然后其可以发动一次“纵势”。",

    ["$ny_10th_xiaoyan1"] = "万军付薪柴，戾火燃苍穹。",
    ["$ny_10th_xiaoyan2"] = "九州硝烟起，烽火灼铁衣。",
    ["$ny_tenth_zongshi1"] = "四世三公之家，当为天下之望。",
    ["$ny_tenth_zongshi2"] = "大势在我，可怀问鼎之心。",
    ["$ny_10th_jiaowang1"] = "剑顾四野，马踏青山，今谁堪敌手？",
    ["$ny_10th_jiaowang2"] = "并土四州，带甲百万，吾可居大否？",
    ["$ny_10th_aoshi1"] = "无傲骨近于鄙夫，有傲心方为君子。",
    ["$ny_10th_aoshi2"] = "得志则喜，临富贵如何不骄？",
    ["~ny_10th_xingyuanshao"] = "骄兵必败，奈何不记前辙。",

    --柏灵筠

    ["ny_10th_bailingyun"] = "柏灵筠[十周年]",
    ["&ny_10th_bailingyun"] = "柏灵筠",
    ["#ny_10th_bailingyun"] = "玲珑心窍",
    ["designer:ny_10th_bailingyun"] = "官方",
	["cv:ny_10th_bailingyun"] = "官方",
	["illustrator:ny_10th_bailingyun"] = "君桓文化",

    ["ny_tenth_linghui"] = "灵慧",
    [":ny_tenth_linghui"] = "每个结束阶段，若本回合有角色进入过濒死状态（你的回合无此条件），你可以观看牌堆顶的三张牌：你可以使用其中一张牌，然后随机获得剩余中的一张。",
    --["ny_tenth_linghui:view"] = "你可以发动“灵慧”观看牌堆顶的三张牌",
    ["#ny_tenth_linghui"] = "灵慧",
    ["@ny_tenth_linghui"] = "你可以使用其中一张牌并随机获得剩余的一张牌",
    ["ny_10th_xiace"] = "黠策",
    [":ny_10th_xiace"] = "每回合每项限一次，当你受到伤害后，你可令一名其他角色所有非锁定技失效直到回合结束；当你造成伤害后，你可以弃置一张牌并回复1点体力。",
    ["@ny_10th_xiace-failure"] = "你可以令一名其他角色所有非锁定技失效直到回合结束",
    ["@ny_10th_xiace-discard"] = "你可以弃置一张牌并恢复1点体力",
    [":&ny_10th_xiace"] = "非锁定技失效直到回合结束",
    ["ny_10th_yuxin"] = "御心",
    [":ny_10th_yuxin"] = "限定技，当一名角色进入濒死状态时，你可以令其将体力值回复至与你相同（若其为你则改为回复至1点）。",
    ["ny_10th_yuxin:dying"] = "你可以发动“御心”令 %src 回复至 %arg 点体力",

    ["$ny_tenth_linghui1"] = "福兮祸所依，祸兮福所伏。",
    ["$ny_tenth_linghui2"] = "枯桑知风，沧海知寒。",
    ["$ny_10th_xiace1"] = "风之积非厚，其负大翼也无力。",
    ["$ny_10th_xiace2"] = "人情同于抔土，岂穷达而异心。",
    ["$ny_10th_yuxin1"] = "得一人知情识趣，何妨同甘共苦。",
    ["$ny_10th_yuxin2"] = "临千军而不改其静，御心无波尔。",
    ["~ny_10th_bailingyun"] = "世人皆惧司马，独我痴情仲达。",

    --甘夫人&糜夫人

    ["ny_10th_ganfurenmifuren"] = "甘夫人&糜夫人[十周年]",
    ["&ny_10th_ganfurenmifuren"] = "甘夫人糜夫人",
    ["#ny_10th_ganfurenmifuren"] = "千里婵娟",
    ["designer:ny_10th_ganfurenmifuren"] = "官方",
	["cv:ny_10th_ganfurenmifuren"] = "官方",
	["illustrator:ny_10th_ganfurenmifuren"] = "七兜豆",

    ["ny_tenth_chanjuan"] = "婵娟",
    [":ny_tenth_chanjuan"] = "每种牌名限两次，当你使用手牌中仅指定唯一目标的基本牌或普通锦囊牌结算结束后，你可以视为使用一张与此牌牌名相同的牌。若此牌的目标与之前相同，你摸一张牌。",
    ["@ny_tenth_chanjuan"] = "你可以发动“婵娟”视为使用了【%src】",
    ["ny_10th_xunbie"] = "殉别",
    [":ny_10th_xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌替换为甘夫人或糜夫人（场上已有的除外），然后你回复1点体力，且本回合防止所有伤害。",
    [":&ny_10th_xunbie"] = "本回合防止所有伤害",
    ["$ny_10th_xunbie_damage"] = "%from 因 %arg 的效果防止了即将受到的伤害",

    ["$ny_tenth_chanjuan1"] = "姐妹一心，共侍玄德无忧。",
    ["$ny_tenth_chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
    ["$ny_10th_xunbie1"] = "既为君之妇，何惧为君之鬼。",
    ["$ny_10th_xunbie2"] = "今临难将罹，唯求不负皇叔。",
    ["~ny_10th_ganfurenmifuren"] = "人生百年，奈何于我十不存一。",

    --神许褚

    ["ny_10th_shenxuchu"] = "神许褚[十周年]",
    ["&ny_10th_shenxuchu"] = "许褚",
    ["#ny_10th_shenxuchu"] = "嗜战的熊罴",
    ["designer:ny_10th_shenxuchu"] = "官方",
	["cv:ny_10th_shenxuchu"] = "官方",
	["illustrator:ny_10th_shenxuchu"] = "小新",

    ["ny_10th_shenxuchu_qing"] = "擎",
    ["ny_10th_zhuangpo"] = "壮魄",
    [":ny_10th_zhuangpo"] = "你可将牌面信息中有【杀】字的牌当【决斗】使用。若你拥有“擎”，则此【决斗】指定目标后，你可以移去任意个“擎”，然后令其弃置等量的牌；若此【决斗】指定了有“擎”的角色为目标，则此牌伤害+1。",
    ["ny_10th_zhuangpo:remove"] = "你可以移去任意个“擎”并令 %src 弃置等量张牌",
    ["$ny_10th_zhuangpo_damage"] = "%from 对 %to 造成的伤害因 %arg 由 %arg2 点增加到了 %arg3 点",
    ["ny_10th_zhengqing"] = "争擎",
    [":ny_10th_zhengqing"] = "锁定技，每轮结束时，移去所有“擎”标记，然后本轮单回合内造成伤害值最多的角色获得X个“擎”标记并与你各摸一张牌（X为其该回合造成的伤害数）。若是你获得“擎”且是获得数量最多的一次，你改为摸X张牌（最多摸5）。",

    ["$ny_10th_zhengqing1"] = "锐士夺志，斩将者虎侯是也。",
    ["$ny_10th_zhengqing2"] = "三军争勇，擎纛者舍我其谁。",
    ["$ny_10th_zhuangpo1"] = "腹吞龙虎，气撼山河。",
    ["$ny_10th_zhuangpo2"] = "神魄凝威，魍魉辟易。",
    ["~ny_10th_shenxuchu"] = "猛虎归林晚，不见往来人。",

    --周善

    ["ny_10th_zhoushan"] = "周善[十周年]",
    ["&ny_10th_zhoushan"] = "周善",
    ["#ny_10th_zhoushan"] = "荆吴刑天",
    ["designer:ny_10th_zhoushan"] = "官方",
	["cv:ny_10th_zhoushan"] = "官方",
	["illustrator:ny_10th_zhoushan"] = "游漫美绘",

    ["ny_tenth_miyun"] = "密运",
    [":ny_tenth_miyun"] = "锁定技，①每轮开始时，你展示并获得一名其他角色的一张牌，称为“安”；\
    ②每轮结束时，你将包含“安”的任意张手牌交给一名其他角色（当你以此法外失去“安”时，你失去1点体力），然后将手牌摸至体力上限。",
    ["@ny_tenth_miyun-get"] = "请展示并获得一名其他角色的一张牌",
    ["@ny_tenth_miyun-give"] = "请将包含“安”的任意张手牌交给一名其他角色",
    ["ny_tenth_miyun_an"] = "安",
    ["ny_10th_danyin"] = "胆迎",
    [":ny_10th_danyin"] = "每回合限一次，当你需要使用或打出【杀】或【闪】时，你可以展示手牌中的“安”，视为使用或打出一张【杀】或【闪】。若如此做，当你本回合下一次成为一名角色使用牌的目标后，该角色弃置你的一张牌。",

    ["$ny_tenth_miyun1"] = "不要大张旗鼓，要神不知鬼不觉。",
    ["$ny_tenth_miyun2"] = "小阿斗，跟本将军走一趟吧。",
    ["$ny_10th_danyin1"] = "早就想会会你常山赵子龙了。",
    ["$ny_10th_danyin2"] = "赵子龙是吧？兜鍪给你打掉。",
    ["~ny_10th_zhoushan"] = "夫人救我！夫人救我！",

    --刘理

    ["ny_10th_liuli"] = "刘理[十周年]",
    ["&ny_10th_liuli"] = "刘理",
    ["#ny_10th_liuli"] = "安平王",
    ["designer:ny_10th_liuli"] = "官方",
	["cv:ny_10th_liuli"] = "官方",
	["illustrator:ny_10th_liuli"] = "黯荧岛工作室",
 
    ["ny_tenth_dehua"] = "德化",
    ["ny_tenth_dehua_slash"] = "德化",
    [":ny_tenth_dehua"] = "锁定技，每轮开始时，你选择一种你可以使用的伤害牌的牌名，视为使用此牌，然后你不能再使用手牌中与之牌名相同的牌（你的手牌上限+X，X为因此不能使用的牌名数），然后若所有伤害牌的牌名均被选择过，你失去此技能。",
    ["@ny_tenth_dehua"] = "请使用【%src】",
    [":&ny_tenth_dehua"] = "你的手牌上限增加 %src ",
    ["ny_10th_fuli"] = "抚黎",
    [":ny_10th_fuli"] = "出牌阶段限一次，你可以展示所有手牌，选择其中有的一种类别全部弃置，然后摸X张牌（X为所有弃置的牌的牌名称字数之合，且不能超过全场手牌数最多角色的手牌数），若你因此弃置了伤害牌，则你可以令一名角色攻击范围-1直到你的下个回合开始。",
    ["@ny_10th_fuli"] = "你可以令一名角色攻击范围-1直到你的下个回合开始",
    [":&ny_10th_fuli"] = "攻击范围减少 %src",
    ["@ny_10th_fuli-discard"] = "请弃置所有的 %src",

    ["$ny_tenth_dehua1"] = "君子怀德，可驱怀土之小人。",
    ["$ny_tenth_dehua2"] = "以德与人，福虽未至，祸已远离。",
    ["$ny_10th_fuli1"] = "民为贵，社稷次之，君为轻。",
    ["$ny_10th_fuli2"] = "民之所欲，天必从之。",
    ["~ny_10th_liuli"] = "覆舟之水，皆百姓之泪。",

    -- 张昌蒲

    ["ny_10th_zhangchangpu"] = "张昌蒲[十周年]",
    ["&ny_10th_zhangchangpu"] = "张昌蒲",
    ["#ny_10th_zhangchangpu"] = "矜严明训",
    ["designer:ny_10th_zhangchangpu"] = "官方",
	["cv:ny_10th_zhangchangpu"] = "官方",
	["illustrator:ny_10th_zhangchangpu"] = "biou09",

    ["ny_tenth_yanjiao"] = "严教",
    [":ny_tenth_yanjiao"] = "出牌阶段限一次，你可以选择一名其他角色并亮出牌堆顶的四张牌，令该角色将这些牌分成点数之和相等的两组并将这两组牌分配给你与其，然后将剩余未分组的牌置入弃牌堆。若未分组的牌数大于1，你本回合的手牌上限-1。",
    ["@ny_tenth_yanjiao"] = "请将牌分配给你与 %src <br/>分配方式：选择任意张展示的牌并选择要分配给的角色，选择牌且不选择角色将取消所有选中牌的分配状态，角色头顶标记为已分配的点数之和，点击取消完成所有分配",
    [":&ny_tenth_yanjiao"] = "“严教”已分配点数和 %src",
    ["#ny_tenth_yanjiao"] = "待分配",
    ["#ny_tenth_yanjiao_self"] = "分给自己",
    ["#ny_tenth_yanjiao_target"] = "分给对方",
    ["ny_tenth_yanjiao_failed"] = "严教减上限",
    ["&ny_tenth_yanjiao_failed"] = "你的手牌上限减少 %src",
    ["ny_tenth_yanjiao_ask"] = "看起来你在卡牌分配方面遇到了一点点小问题，请问你是否需要帮助？",
    ["ny_tenth_yanjiao:yes"] = "是的，我需要帮助。（尝试进行一次自动分配）",
    ["ny_tenth_yanjiao:no"] = "不，我不需要。（就此结束）",
    ["ny_10th_xingshen"] = "省身",
    [":ny_10th_xingshen"] = "当你受到伤害后，你可以摸一张牌，令下一次发动“严教”亮出的牌数+1（至多+4）。\
    若你的手牌数为全场最少，改为摸两张牌。\
    若你的体力值为全场最少，改为+2。",
    [":&ny_10th_xingshen"] = "严教亮出的牌数+ %src",

    ["$ny_tenth_yanjiao1"] = "会虽童稚，勤见规诲。",
    ["$ny_tenth_yanjiao2"] = "性矜严教，明于教训。",
    ["$ny_10th_xingshen1"] = "居上不骄，制节谨度。",
    ["$ny_10th_xingshen2"] = "君子之行，皆积小以致高大。",
    ["~ny_10th_zhangchangpu"] = "我还是小看了，孙氏的伎俩。",

    --谋司马懿

    ["ny_10th_mousimayi"] = "谋司马懿[十周年]",
    ["&ny_10th_mousimayi"] = "司马懿",
    ["#ny_10th_mousimayi"] = "韬谋韫势",
    ["designer:ny_10th_mousimayi"] = "官方",
	["cv:ny_10th_mousimayi"] = "官方",
	["illustrator:ny_10th_mousimayi"] = "米糊PU",
    ["ny_10th_mousimayi_yin"] = "谋司马懿[十周年]",
    ["&ny_10th_mousimayi_yin"] = "司马懿",

    ["ny_tenth_pingliao"] = "平辽",
    [":ny_tenth_pingliao"] = "锁定技，当你使用【杀】指定目标时，不公开指定的目标。你攻击范围内的其它角色同时选择是否打出一张红色基本牌。若此【杀】的目标未打出基本牌，其本回合无法使用或打出手牌。若至少有一名非目标打出基本牌，你摸两张牌且本阶段出【杀】次数+1。",
    ["@ny_tenth_pingliao"] = "%src 发动了 “平辽” ，你可以打出一张红色基本牌",
    [":&ny_tenth_pingliao"] = "本回合不能使用或打出手牌",
    ["ny_tenth_pingliao_slash"] = "额外出杀",
    [":&ny_tenth_pingliao_slash"] = "你可以额外使用 %src 张【杀】",
    ["ny_10th_quanmou"] = "权谋",
    [":ny_10th_quanmou"] = "转换技，游戏开始时自选①②状态；出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，①防止你此阶段对其造成的下次伤害；②你此阶段下次对该角色造成伤害后：可以对该角色以外的至多三名其他角色各造成1点伤害。",
    [":ny_10th_quanmou1"] = "转换技，游戏开始时自选①②状态；出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，①防止你此阶段对其造成的下次伤害；<font color=\"#01A5AF\"><s>②你此阶段下次对该角色造成伤害后，可以对该角色以外的至多三名其他角色各造成1点伤害</s></font>。",
    [":ny_10th_quanmou2"] = "转换技，游戏开始时自选①②状态；出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，<font color=\"#01A5AF\"><s>①防止你此阶段对其造成的下次伤害</s></font>；②你此阶段下次对该角色造成伤害后：可以对该角色以外的至多三名其他角色各造成1点伤害。",
    ["@ny_10th_quanmou-give"] = "请交给 %src 一张牌",
    ["@ny_10th_quanmou-damage"] = "你可以对 %src 以外的至多三名其他角色各造成1点伤害",
    ["$ny_10th_quanmou_prohibit"] = "%from 对 %to 造成的伤害被 %arg 防止",
    ["ny_10th_quanmou_first"] = "权谋防伤",
    [":&ny_10th_quanmou_first"] = "防止你此阶段对其造成的下次伤害",
    ["ny_10th_quanmou_second"] = "权谋伤害",
    [":&ny_10th_quanmou_second"] = "你此阶段下次对该角色造成伤害后，可以对该角色以外的至多三名其他角色各造成1点伤害",

    ["$ny_tenth_pingliao1"] = "烽烟起大荒，戎军远役，问不臣者谁？",
    ["$ny_tenth_pingliao2"] = "挥斥千军之贲，长驱万里之远。",
    ["$ny_tenth_pingliao3"] = "率土之滨皆为王臣，辽土亦居普天之下。",
    ["$ny_tenth_pingliao4"] = "青云远上，寒锋试刃，北雁当寄红翎。",
    ["$ny_10th_quanmou1"] = "洛水为誓，皇天为证，吾意不在刀兵。",
    ["$ny_10th_quanmou2"] = "以谋代战，攻形不以力，攻心不以勇。",
    ["$ny_10th_quanmou3"] = "鸿门之宴虽歇，会稽之胆尚悬，孤岂姬、项之辈。",
    ["$ny_10th_quanmou4"] = "昔藏青锋于沧海，今潮落，可现兵！",
    ["~ny_10th_mousimayi"] = "以权谋而立者，必失大义于千秋。",
    ["~ny_10th_mousimayi_yin"] = "人立中流，非己力可向，实大势所迫。",

    --曹爽

    ["ny_10th_caoshuang"] = "曹爽[十周年]",
    ["&ny_10th_caoshuang"] = "曹爽",
    ["#ny_10th_caoshuang"] = "托孤傲臣",
    ["designer:ny_10th_caoshuang"] = "官方",
	["cv:ny_10th_caoshuang"] = "官方",
	["illustrator:ny_10th_caoshuang"] = "鬼画府",

    ["ny_10th_jianzhuan"] = "渐专",
    [":ny_10th_jianzhuan"] = "锁定技，出牌阶段每项各限一次，当你使用牌时，选择一项（出牌阶段结束时，若你本阶段执行过所有选项，随机删除一个选项）：1.令一名角色弃置X张牌；2.摸X张牌；3.重铸X张牌；4.弃置X张牌（X为此技能本阶段发动次数）。",
    ["ny_10th_jianzhuan:disother"] = "令一名角色弃置 %src 张牌",
    ["ny_10th_jianzhuan:draw"] = "摸 %src 张牌",
    ["ny_10th_jianzhuan:recast"] = "重铸 %src 张牌",
    ["ny_10th_jianzhuan:disself"] = "弃置 %src 张牌",
    ["@ny_10th_jianzhuan-disother"] = "请令一名角色弃置 %src 张牌",
    ["@ny_10th_jianzhuan-recast"] = "请重铸 %src 张牌",
    ["ny_10th_fanshi"] = "反势",
    [":ny_10th_fanshi"] = "觉醒技，结束阶段，若“渐专”的选项数小于2，你执行三次剩余选项且此时X视为1，加2点体力上限并回复2点体力，失去技能“渐专”，获得技能“覆斗”。",
    ["ny_10th_fudou"] = "覆斗",
    [":ny_10th_fudou"] = "你使用黑色牌/红色牌指定其他角色为唯一目标后，若其对你/未对你造成过伤害，你可以与其各失去1点体力/各摸一张牌。",
    ["ny_10th_fudou:lose"] = "你可以与 %src 各失去1点体力",
    ["ny_10th_fudou:draw"] = "你可以与 %src 各摸一张牌",

    ["$ny_10th_jianzhuan1"] = "今做擎天之柱，何怜八方风雨。",
    ["$ny_10th_jianzhuan2"] = "吾寄百里之命，当居万丈危楼。",
    ["$ny_10th_fanshi1"] = "垒巨木为寨，发屯兵自守。",
    ["$ny_10th_fanshi2"] = "吾居伊周之位，怎可以罪见黜。",
    ["$ny_10th_fudou1"] = "既做困禽，何妨铤险以覆车！",
    ["$ny_10th_fudou2"] = "居将覆之巢，必做犹斗之困兽。",
    ["~ny_10th_caoshuang"] = "我度太傅之意，不欲伤我兄弟耳。",

--杜预·第二版

    ["ny_10th_duyu_second"] = "杜预[十周年二版]",
    ["&ny_10th_duyu_second"] = "杜预",
    ["#ny_10th_duyu_second"] = "文成武德",
    ["designer:ny_10th_duyu_second"] = "官方",
	["cv:ny_10th_duyu_second"] = "官方",
	["illustrator:ny_10th_duyu_second"] = "官方",

    ["ny_10th_jianguo_second"] = "谏国",
    [":ny_10th_jianguo_second"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向上取整）；令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向上取整）。",
    ["ny_10th_jianguo_second:draw"] = "令其弃置一张牌然后摸与当前手牌数一半数量的牌（向上取整）",
    ["ny_10th_jianguo_second:dis"] = "令其摸一张牌然后弃置一半的手牌（向上取整）",

    ["$ny_10th_jianguo_second1"] = "彭蠡雁惊，此诚平吴之时。",
	["$ny_10th_jianguo_second2"] = "奏三陈之诏，谏一国之弊。",
    ["~ny_10th_duyu_second"] = "六合即归一统，奈何寿数已尽。",

    --曹芳

    ["ny_10th_caofang"] = "曹芳[十周年]",
    ["&ny_10th_caofang"] = "曹芳",
    ["#ny_10th_caofang"] = "迷瞑终觉",
    ["designer:ny_10th_caofang"] = "官方",
	["cv:ny_10th_caofang"] = "官方",
	["illustrator:ny_10th_caofang"] = "鬼画府",

    ["ny_10th_zhimin"] = "置民",
    [":ny_10th_zhimin"] = "锁定技，每轮开始时，你选择至多X名其他角色（X为你的体力值），然后获得这些角色点数最小的一张手牌。你回合外获得的牌增加“民”标记，你失去“民”后将手牌摸至体力上限。",
    ["@ny_10th_zhimin"] = "请选择至多 %src 名其他角色",
    ["ny_10th_zhimin_min"] = "民",
    ["ny_10th_jujian"] = "拒谏",
    [":ny_10th_jujian"] = "主公技，出牌阶段限一次，你可令一名其他魏势力角色摸一张牌，若如此做，则本轮内其使用普通锦囊牌对你无效。",
    ["$ny_10th_jujian_buff"] = "%from 的 %arg 被触发，%card 对其无效",

    ["$ny_10th_zhimin1"] = "渤海虽阔，亦不及朕胸腹之广。",
    ["$ny_10th_zhimin2"] = "民众渡海而来，当筑梧居相待。",
    ["$ny_10th_jujian1"] = "尔等眼中，只见到朕的昏庸吗？",
    ["$ny_10th_jujian2"] = "我作天子，不得自在邪？",
    ["~ny_10th_caofang"] = "匹夫无罪，怀璧其罪。",

    --武关羽

    ["ny_10th_wuguanyu"] = "武关羽[十周年]",
    ["&ny_10th_wuguanyu"] = "关羽",
    ["#ny_10th_wuguanyu"] = "义武千秋",
    ["designer:ny_10th_wuguanyu"] = "官方",
	["cv:ny_10th_wuguanyu"] = "官方",
	["illustrator:ny_10th_wuguanyu"] = "黯荧岛_小董",

    ["ny_tenth_wuyou"] = "武佑",
    [":ny_tenth_wuyou"] = "每名角色的出牌阶段限一次，其可以交给你一张手牌，然后你可从五个随机的非装备牌的牌名中选择一个牌名并交给其一张手牌（此牌视为你选择的牌名且使用时无距离与次数限制）。",
    ["@ny_tenth_wuyou"] = "你可从五个随机的非装备牌的牌名中选择一个牌名并交给 %src 一张手牌",
    ["ny_tenth_wuyou_other"] = "武佑",
    [":ny_tenth_wuyou_other"] = "出牌阶段限一次，你可以将一张手牌交给“武·关羽”，然后其可能显灵。",
    ["ny_tenth_yixian"] = "义贤",
    [":ny_tenth_yixian"] = "限定技，出牌阶段，你可以选择一项：1.获得场上的所有装备牌；2.获得弃牌堆中的所有装备牌。然后你可以依次令被你获得牌的角色摸X张牌（X为其因此被你获得的牌数）并回复1点体力。",
    ["ny_tenth_yixian:buff"] = "令 %src 摸牌并回复1点体力",
    ["ny_tenth_yixian:field"] = "获得场上的所有装备牌",
    ["ny_tenth_yixian:discardpile"] = "获得弃牌堆中的所有装备牌",
    ["ny_tenth_jvewu"] = "绝武",
    ["ny_tenth_jvewu_slash"] = "绝武",
    ["#ny_tenth_jvewu_change"] = "绝武",
    [":ny_tenth_jvewu"] = "你点数为2的牌可当任意伤害牌使用（每种牌名每回合限一次）。你从其他角色处获得的牌在你的手牌中均视为点数2。",
    ["ny_tenth_jvewu:disable"] = "没有可以使用的伤害牌",
    ["@ny_tenth_jvewu"] = "请将一张点数为2的牌当作 【%src】 使用",
    ["_ny_tenth_shuiyanqijun"] = "水淹七军",
    [":_ny_tenth_shuiyanqijun"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：至多两名角色<br /><b>效果</b>：第一名角色受到1点雷电伤害并弃置一张牌，第二名角色受到1点雷电伤害并摸一张牌",
    ["ny_10th_wuguanyu_card"] = "武关羽专属",

    ["$ny_tenth_wuyou1"] = "人惧则威，人信则义。",
    ["$ny_tenth_wuyou2"] = "尚义之人，天必予惠。",
    ["$ny_tenth_yixian1"] = "春秋一万八千字，其以义为先。",
    ["$ny_tenth_yixian2"] = "义驱千里长路，风起桃园芳菲。",
    ["$ny_tenth_jvewu1"] = "可惜我这青龙偃月刀，竟要斩你这鼠辈。",
    ["$ny_tenth_jvewu2"] = "我自山峰而下，犹未见来人。",
    ["~ny_10th_wuguanyu"] = "寻了兄长三弟一辈子，今日，便等兄弟来寻了。",

    --吴普

    ["ny_10th_wupu"] = "吴普[十周年]",
    ["&ny_10th_wupu"] = "吴普",
    ["#ny_10th_wupu"] = "健体养魄",
    ["designer:ny_10th_wupu"] = "官方",
	["cv:ny_10th_wupu"] = "官方",
	["illustrator:ny_10th_wupu"] = "黯荧岛_小董",

    ["ny_10th_duanti"] = "锻体",
    [":ny_10th_duanti"] = "锁定技，当你每使用或打出五张牌后，你回复1点体力，加1点体力上限（至多加5点）。",
    ["ny_10th_shicao"] = "识草",
    [":ny_10th_shicao"] = "出牌阶段，你可以声明一种类别，从牌堆顶或牌堆底摸一张牌。若此牌与你声明的类别不同，你观看另一端两张牌，然后此技能本回合失效。",
    ["ny_10th_shicao_place:top"] = "从牌堆顶摸一张牌",
    ["ny_10th_shicao_place:down"] = "从牌堆底摸一张牌",
    ["ny_10th_shicao_top"] = "牌堆顶",
    ["ny_10th_shicao_down"] = "牌堆底",
    ["ny_10th_shicao_place"] = "识草",
    ["ny_10th_shicao_type"] = "识草",
    ["@ny_10th_shicao"] = "以上为 %src 的另一端的两张牌",

    ["$ny_10th_duanti1"] = "流水不腐，户枢不蠹。",
    ["$ny_10th_duanti2"] = "五禽锻体，百病不侵。",
    ["$ny_10th_shicao1"] = "药长于草木，然草木非皆可入药。",
    ["$ny_10th_shicao2"] = "掌中非药，乃活人之根本。",
    ["~ny_10th_wupu"] = "医者，不可使人长生。",

    --谋关平

    ["ny_10th_mouguanpin"] = "谋关平[十周年]",
    ["&ny_10th_mouguanpin"] = "关平",
    ["#ny_10th_mouguanpin"] = "百战烈烈",
    ["designer:ny_10th_mouguanpin"] = "官方",
	["cv:ny_10th_mouguanpin"] = "官方",
	["illustrator:ny_10th_mouguanpin"] = "黯荧岛",

    ["ny_10th_wuwei"] = "武威",
    [":ny_10th_wuwei"] = "出牌阶段限一次，你可以将一种颜色的所有手牌当无距离与次数限制的【杀】使用，然后其中每有一种类别的牌，你便可选择一项执行一次：1.摸一张牌；2.令目标角色本回合非锁定技失效；3.此技能本回合可发动次数+1。若你此次执行了所有选项，此【杀】造成的伤害+1。",
    ["ny_10th_wuwei:draw"] = "摸一张牌",
    ["ny_10th_wuwei:lockdown"] = "令目标角色本回合非锁定技失效",
    ["ny_10th_wuwei:skill"] = "本回合可额外发动一次“武威”",
    ["ny_10th_wuwei_color"] = "武威",
    ["ny_10th_wuwei_color:red"] = "红色",
    ["ny_10th_wuwei_color:black"] = "黑色",
    ["ny_10th_wuwei_color:nocolor"] = "无色",
    ["ny_10th_wuwei_used"] = "武威已用",
    ["ny_10th_wuwei_more"] = "武威额外",
    ["ny_10th_wuwei_can"] = "武威可用",

    ["$ny_10th_wuwei1"] = "残阳洗长刀，漫卷天下帜。",
    ["$ny_10th_wuwei2"] = "武效万人敌，复行千里路。",
    ["~ny_10th_mouguanpin"] = "生未屈刀兵，死罢战黄泉。",

    --孙礼

    ["ny_10th_sunli"] = "孙礼[十周年]",
    ["&ny_10th_sunli"] = "孙礼",
    ["#ny_10th_sunli"] = "百炼公才",
    ["designer:ny_10th_sunli"] = "官方",
	["cv:ny_10th_sunli"] = "官方",
	["illustrator:ny_10th_sunli"] = "错落宇宙",

    ["ny_10th_kangli"] = "伉俪",
    [":ny_10th_kangli"] = "当你造成或受到伤害后，你可以摸两张牌，然后你下一次造成伤害时弃置这些牌。",

    ["$ny_10th_kangli1"] = "地界纷争皋陶难断，然图藏天府，坐上可明。",
    ["$ny_10th_kangli2"] = "正至歉岁，难征百姓于役，望陛下明鉴。",
    ["~ny_10th_sunli"] = "国无矩不立，何谓之方圆？",

    --谋胡车儿
    
    ["ny_10th_mou_hucheer"] = "谋胡车儿[十周年]",
    ["&ny_10th_mou_hucheer"] = "胡车儿",
    ["#ny_10th_mou_hucheer"] = "有力逮戟",
    ["designer:ny_10th_mou_hucheer"] = "官方",
	["cv:ny_10th_mou_hucheer"] = "官方",
	["illustrator:ny_10th_mou_hucheer"] = "钟於",

    ["ny_10th_kongwu"] = "孔武",
    ["ny_10th_kongwu_slash"] = "孔武",
    [":ny_10th_kongwu"] = "转换技，出牌阶段限一次，你可以弃置至多体力上限数张牌，并选择一名其他角色，阳：你弃置该角色的至多等量张牌；阴：你视为对其使用等量张【杀】。然后此阶段结束时，若该角色的手牌数与体力值均不大于你，其于其下个回合内：装备区内的牌失效，摸牌阶段少摸一张牌。",
    [":ny_10th_kongwu1"] = "转换技，出牌阶段限一次，你可以弃置至多体力上限数张牌，并选择一名其他角色，阳：你弃置该角色的至多等量张牌；<font color=\"#01A5AF\"><s>阴：你视为对其使用等量张【杀】</s></font>。然后此阶段结束时，若该角色的手牌数与体力值均不大于你，其于其下个回合内：装备区内的牌失效，摸牌阶段少摸一张牌。",
    [":ny_10th_kongwu2"] = "转换技，出牌阶段限一次，你可以弃置至多体力上限数张牌，并选择一名其他角色，<font color=\"#01A5AF\"><s>阳：你弃置该角色的至多等量张牌</s></font>；阴：你视为对其使用等量张【杀】。然后此阶段结束时，若该角色的手牌数与体力值均不大于你，其于其下个回合内：装备区内的牌失效，摸牌阶段少摸一张牌。",
    
    ["$ny_10th_kongwu1"] = "臂有千斤力，何惧万人敌！",
    ["$ny_10th_kongwu2"] = "莫说兵器，取汝首级也易如反掌。",
    ["~ny_10th_mou_hucheer"] = "典，典将军，您还没睡呀？",

    --sp甄姬

    ["ny_10th_spzhenji"] = "sp甄姬[十周年]",
    ["&ny_10th_spzhenji"] = "甄姬",
    ["#ny_10th_spzhenji"] = "善言贤女",
    ["designer:ny_10th_spzhenji"] = "官方",
	["cv:ny_10th_spzhenji"] = "官方",
	["illustrator:ny_10th_spzhenji"] = "匠人绘",

    ["ny_10th_jijie"] = "己诫",
    [":ny_10th_jijie"] = "锁定技，每回合各限一次，当其他角色于其回合外获得牌/回复体力后，你摸等量张牌/回复等量的体力。",
    ["ny_10th_huiji"] = "惠济",
    ["ny_10th_huiji_mazing_grace"] = "惠济",
    [":ny_10th_huiji"] = "出牌阶段限一次，你可以令一名角色摸两张牌或使用牌堆中的一张装备牌。若其手牌数不小于存活角色数，视为其使用一张【五谷丰登】（改为从该角色手牌中挑选）。",
    ["ny_10th_huiji:draw"] = "摸两张牌",
    ["ny_10th_huiji:equip"] = "使用牌堆中的一张装备牌",
    ["$ny_10th_huiji_log"] = "%from 使用了 %arg， 目标是 %to",
    ["ny_10th_jijie_ama"] = "五谷丰登[无色]",

    ["$ny_10th_jijie1"] = "闻古贤女，未有不学前世成败者。",
    ["$ny_10th_jijie2"] = "不知书，何由见之。",
    ["$ny_10th_huiji1"] = "云鬓释远，彩衣婀娜。",
    ["$ny_10th_huiji2"] = "明眸善睐，瑰姿艳逸。",
    ["~ny_10th_spzhenji"] = "自古英雄迟暮，谁见佳人白头？",

    --袁胤

    ["ny_10th_yuanyin"] = "袁胤[十周年]",
    ["&ny_10th_yuanyin"] = "袁胤",
    ["#ny_10th_yuanyin"] = "载路素车",
    ["designer:ny_10th_yuanyin"] = "官方",
	["cv:ny_10th_yuanyin"] = "官方",
	["illustrator:ny_10th_yuanyin"] = "错落宇宙",

    ["ny_10th_moshou"] = "墨守",
    [":ny_10th_moshou"] = "你成为黑色牌的目标后，可以摸体力上限张牌，此后你以此法摸牌数-1。若你以此法摸牌数为1，则重置为体力上限。",
    ["ny_10th_moshou:draw"] = "你可以发动 “墨守” 摸 %src 张牌",
    [":&ny_10th_moshou"] = "发动“墨守”时少摸%src张牌",
    ["ny_tenth_yunjiu"] = "运柩",
    ["#ny_tenth_yunjiu"] = "运柩",
    [":ny_tenth_yunjiu"] = "一名角色死亡时，你可以将该角色死亡时弃置的一张牌交给一名其他角色。若如此做，你加1体力上限并回复1点体力。",
    ["@ny_tenth_yunjiu-give"] = "你可以将 %src 的一张牌交给一名其他角色\
    然后你加1点体力上限并回复1点体力",

    ["$ny_10th_moshou1"] = "好战必亡，此亘古之理。",
    ["$ny_10th_moshou2"] = "天下汹汹之势，恪守方得自保。",
    ["$ny_tenth_yunjiu1"] = "此吾主之柩，请诸君勿扰。",
    ["$ny_tenth_yunjiu2"] = "故者为大，尔等欲欺大者乎？",
    ["~ny_10th_yuanyin"] = "臣不负忠，虽死如是。",

    --庞会·第二版

    ["ny_10th_panghui_second"] = "庞会[十周年二版]",
    ["&ny_10th_panghui_second"] = "庞会",
    ["#ny_10th_panghui_second"] = "临渭亭侯",
    ["designer:ny_10th_panghui_second"] = "官方",
	["cv:ny_10th_panghui_second"] = "官方",
	["illustrator:ny_10th_panghui_second"] = "秋呆呆",

    ["ny_10th_yiyong"] = "异勇",
    [":ny_10th_yiyong"] = "当你对其他角色造成伤害时，你可以与该角色同时弃置任意张牌。若你弃置的牌的点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数+1）；不小于其，此伤害+1。",
    ["@ny_10th_yiyong-discard"] = "请与 %src 同时弃置任意张牌（至少一张）",
    ["ny_10th_suchou"] = "夙仇",
    [":ny_10th_suchou"] = "锁定技，出牌阶段开始时，你选择一项：1.失去1点体力或体力上限，然后你此阶段使用牌无法被其他角色响应；2.失去此技能。",
    [":&ny_10th_suchou"] = "使用牌无法被其他角色响应",
    ["ny_10th_suchou:losehp"] = "失去1点体力",
    ["ny_10th_suchou:losemaxhp"] = "失去1点体力上限",
    ["ny_10th_suchou:loseskill"] = "失去此技能",

    ["$ny_10th_yiyong1"] = "关氏鼠辈，庞令明之子来邪！",
    ["$ny_10th_yiyong2"] = "凭一腔勇力，父仇定可报还。",
    ["$ny_10th_suchou1"] = "关家人我杀定了，谁也保不住！",
    ["$ny_10th_suchou2"] = "身陷仇海，谁知道我是怎么过的！",
    ["~ny_10th_panghui_second"] = "大仇虽报，奈何心有余创。",

    --威张辽

    ["ny_10th_weizhangliao"] = "威张辽[十周年]",
    ["&ny_10th_weizhangliao"] = "张辽",
    ["#ny_10th_weizhangliao"] = "威锐镇西风",
    ["designer:ny_10th_weizhangliao"] = "官方",
	["cv:ny_10th_weizhangliao"] = "官方",
	["illustrator:ny_10th_weizhangliao"] = "鬼画府",

    ["ny_10th_yuxi"] = "驭袭",
    [":ny_10th_yuxi"] = "当你造成或受到伤害时，你可以摸一张牌，以此法获得的牌无次数限制。",
    ["ny_10th_porong"] = "破戎",
    [":&ny_10th_porong"] = "再使用一张【杀】以发动破戎",
    [":ny_10th_porong"] = "连招技（伤害牌+【杀】），你可以获得目标角色以及与其的相邻角色的各一张手牌并令此【杀】额外对其结算一次。",

    ["$ny_10th_yuxi1"] = "任他千军来，我只一枪去！",
    ["$ny_10th_yuxi2"] = "长枪雪恨，斩尽胡马！",
    ["$ny_10th_porong1"] = "胡未灭，家何为！",
    ["$ny_10th_porong2"] = "诸君且听，这雁门虎啸！",
    ["~ny_10th_weizhangliao"] = "血染战袍，虽死犹荣，此心无憾。",

    --司马师

    ["ny_10th_shimashi"] = "司马师[十周年]",
    ["&ny_10th_shimashi"] = "司马师",
    ["#ny_10th_shimashi"] = "唯几成务",
    ["designer:ny_10th_shimashi"] = "官方",
	["cv:ny_10th_shimashi"] = "官方",
	["illustrator:ny_10th_shimashi"] = "鬼画府",

    ["ny_10th_zhenrao"] = "震扰",
    [":ny_10th_zhenrao"] = "每回合每名角色限一次，当你使用牌指定其他角色为目标后，或成为其他角色使用牌的目标后，你可以在目标角色或使用者中选择一名手牌数大于你的角色，对其造成1点伤害。",
    ["@ny_10th_zhenrao-damage"] = "你可以对其中一名角色造成1点伤害",
    ["ny_10th_sanshi"] = "散士",
    [":ny_10th_sanshi"] = "锁定技，游戏开始时，你随机将牌堆中每个点数的一张牌标记为“死士”牌：1.你使用“死士”牌不能被响应；2.一名角色的回合结束时，若本回合有“死士”牌不因你使用或打出而置入弃牌堆，你获得弃牌堆中的这些牌。",
    ["ny_10th_sishi"] = "死士",
    ["ny_10th_chenlve"] = "沉略",
    [":ny_10th_chenlve"] = "限定技，出牌阶段，你可以获得牌堆、弃牌堆、场上或其他角色手牌中所有“死士”牌。若如此做，本阶段结束时，将这些牌移出游戏直到你死亡。",

    ["$ny_10th_zhenrao1"] = "",
    ["$ny_10th_zhenrao2"] = "",
    ["$ny_10th_sanshi1"] = "",
    ["$ny_10th_sanshi2"] = "",
    ["$ny_10th_chenlve1"] = "",
    ["$ny_10th_chenlve2"] = "",
    ["~ny_10th_shimashi"] = "",
}
return packages