extension = sgs.Package("arknights", sgs.Package_GeneralPack)
local packages = {}
table.insert(packages, extension)

function addNewKingdom(name, color)
    assert(type(name)=="string")
    assert(type(color)=="string")
    require "lua.config"
    if not table.contains(config.kingdoms, name) then
        table.insert(config.kingdoms, name)
        config.kingdom_colors.ling = color
        return true
    else
        return false
    end
end
addNewKingdom("ark", "#17A9C5")

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

local function arkGetSpecialCard(room, target, kind, pile, unhide)
    assert(type(kind) == "string")
    assert(type(pile) == "string")
    if string.find(pile, "draw") then
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf(kind) then
                room:obtainCard(target, card, unhide)
                return card
            end
        end
    end
    if string.find(pile, "discard") then
        for _,id in sgs.qlist(room:getDiscardPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf(kind) then
                room:obtainCard(target, card, unhide)
                return card
            end
        end
    end
    return nil
end

arknight_winmusic = sgs.CreateTriggerSkill{
    name = "arknight_winmusic",
    events = {sgs.GameOver},
    frequency = sgs.Skill_NotFrequent,
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toString():split("+")
        local arknight_heros = {"ark_chongyue", "ark_nearl_RK"}
        for audio,target in sgs.qlist(room:getAlivePlayers()) do
            if (table.contains(winner, target:objectName()) or table.contains(winner, target:getRole())) 
            and table.contains(arknight_heros, target:getGeneralName()) then
                audio = "audio/system/"..target:getGeneralName().."-win.ogg"
                sgs.Sanguosha:playAudioEffect(audio)
                room:getThread():delay(500)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

ark_exusiai = sgs.General(extension, "ark_exusiai", "ark", 3, false, false, false)

ark_guozai = sgs.CreateZeroCardViewAsSkill
{
    name = "ark_guozai",
    view_as = function(self)
        return ark_guozaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getHandcardNum() == player:getHp()
    end,
}

ark_guozaiCard = sgs.CreateSkillCard
{
    name = "ark_guozai",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName(self:objectName())

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
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
        room:setPlayerMark(source, "&ark_guozai-PlayClear", source:getMark("&ark_guozai-PlayClear")+1)

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = source
        log.arg = self:objectName()
        room:sendLog(log)

        if source:getMark("&ark_guozai-PlayClear") > source:getMaxHp() then
            room:loseHp(source, source:getMark("&ark_guozai-PlayClear") - source:getMaxHp(), true, source, self:objectName())
            room:getThread():delay(200)
        end

        source:drawCards(source:getMark("&ark_guozai-PlayClear"), self:objectName())

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("_"..self:objectName())
		room:setCardFlag(slash, "RemoveFromHistory")
        return slash
    end,
}

ark_guozaibuff = sgs.CreateTargetModSkill{
    name = "#ark_guozaibuff",
    residue_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "ark_guozai") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if table.contains(card:getSkillNames(), "ark_guozai") then return 1000 end
        return 0
    end,
}

ark_exusiai:addSkill(ark_guozai)
ark_exusiai:addSkill(ark_guozaibuff)
extension:insertRelatedSkills("ark_guozai", "#ark_guozaibuff")

ark_Isamala = sgs.General(extension, "ark_Isamala", "ark", 3, false)

ark_yongchao = sgs.CreateTriggerSkill{
    name = "ark_yongchao",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            room:setPlayerMark(player, "&ark_yongchao1-PlayClear", 1)
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card 
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if (not card) or card:isKindOf("SkillCard") then return false end
            room:setPlayerMark(player, "&ark_yongchao2-PlayClear", player:getMark("&ark_yongchao2-PlayClear")+1)
            if player:getMark("&ark_yongchao2-PlayClear") >= player:getMark("&ark_yongchao1-PlayClear") then
                room:setPlayerMark(player, "&ark_yongchao1-PlayClear", player:getMark("&ark_yongchao1-PlayClear")+1)
                room:setPlayerMark(player, "&ark_yongchao2-PlayClear", 0)
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(player:getMark("&ark_yongchao1-PlayClear")-1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Play
    end,
}

ark_jingmi = sgs.CreateTriggerSkill{
    name = "ark_jingmi",
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd, sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local targets = room:getOtherPlayers(player)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            room:setPlayerMark(player, "ark_jingmiing-PlayClear", 1)
            for _,p in sgs.qlist(targets) do
                room:addPlayerMark(p, "@skill_invalidity")
            end
            local log = sgs.LogMessage()
            log.type = "$ark_jingmistart"
            room:sendLog(log)
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
            for _,p in sgs.qlist(targets) do
                room:removePlayerMark(p, "@skill_invalidity")
            end
        end
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("ark_jingmiing-PlayClear") > 0 then
                for _,p in sgs.qlist(targets) do
                    room:removePlayerMark(p, "@skill_invalidity")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_Isamala:addSkill(ark_yongchao)
ark_Isamala:addSkill(ark_jingmi)

ark_specterTU = sgs.General(extension, "ark_specterTU", "ark", 3, false, false, false)
ark_specterTU_kuilei = sgs.General(extension, "ark_specterTU_kuilei", "ark", 3, false, true, true)
ark_specterTU_death = sgs.General(extension, "ark_specterTU_death", "ark", 3, false, true, true)

ark_shuangsheng = sgs.CreateTriggerSkill{
    name = "ark_shuangsheng",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:getThread():delay(800)
        room:changeHero(player, "ark_specterTU_kuilei", true, false, false, false)

        local log = sgs.LogMessage()
        log.type = "$ark_specterTU_change"
        log.from = player
        log.arg = "ark_specterTU_second"
        room:sendLog(log)

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_shuangshengonly = sgs.CreateTriggerSkill{
    name = "#ark_shuangshengonly",
    events = {sgs.EventAcquireSkill, sgs.EventLoseSkill},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill then
            local skillname = data:toString()
            if skillname == "ark_shuangsheng" and player:getGeneralName() ~= "ark_specterTU" then
                room:sendCompulsoryTriggerLog(player, "ark_shuangsheng", true, true)
                room:getThread():delay(600)

                room:detachSkillFromPlayer(player, "ark_shuangsheng")
            end
        end
        if event == sgs.EventLoseSkill then
            local skillname = data:toString()
            if skillname == "ark_shuangsheng" and player:getGeneralName() == "ark_specterTU" then
                room:sendCompulsoryTriggerLog(player, "ark_shuangsheng", true, true)
                room:getThread():delay(600)

                room:acquireSkill(player, "ark_shuangsheng")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_shuangsheng_kuilei = sgs.CreateTriggerSkill{
    name = "ark_shuangsheng_kuilei",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:getThread():delay(800)
        room:changeHero(player, "ark_specterTU", true, false, false, false)

        local log = sgs.LogMessage()
        log.type = "$ark_specterTU_change"
        log.from = player
        log.arg = "ark_specterTU_first"
        room:sendLog(log)

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
    end,
}

ark_shuangsheng_kuileionly = sgs.CreateTriggerSkill{
    name = "#ark_shuangsheng_kuileionly",
    events = {sgs.EventAcquireSkill, sgs.EventLoseSkill},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventAcquireSkill then
            local skillname = data:toString()
            if skillname == "ark_shuangsheng_kuilei" and player:getGeneralName() ~= "ark_specterTU_kuilei" then
                room:sendCompulsoryTriggerLog(player, "ark_shuangsheng_kuilei", true, true)
                room:getThread():delay(600)

                room:detachSkillFromPlayer(player, "ark_shuangsheng_kuilei")
            end
        end
        if event == sgs.EventLoseSkill then
            local skillname = data:toString()
            if skillname == "ark_shuangsheng_kuilei" and player:getGeneralName() == "ark_specterTU_kuilei" then
                room:sendCompulsoryTriggerLog(player, "ark_shuangsheng_kuilei", true, true)
                room:getThread():delay(600)

                room:acquireSkill(player, "ark_shuangsheng_kuilei")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_douzheng = sgs.CreateTriggerSkill{
    name = "ark_douzheng",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:objectName() ~= player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            if damage.to:getHp() < player:getHp() then room:loseHp(player, 1, true, player, self:objectName()) end
            local log = CreateDamageLog(damage, 1, self:objectName(), 1)
            room:sendLog(log)
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_specterTU_end = sgs.CreateTriggerSkill{
    name = "#ark_specterTU_end",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local target = data:toDeath().who
        if target:getGeneralName() == "ark_specterTU" or target:getGeneralName() == "ark_specterTU_kuilei" then
            room:changeHero(target, "ark_specterTU_death", false, false, false, false)
            local skills = target:getVisibleSkillList()
            for _,skill in sgs.qlist(skills) do
                if skill:objectName() ~= "ark_specterTU_endlog" then
                    room:detachSkillFromPlayer(target, skill:objectName(), false, false, false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_specterTU_endlog = sgs.CreateTriggerSkill{
    name = "ark_specterTU_endlog",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        return false 
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_yongbao = sgs.CreateTriggerSkill{
    name = "ark_yongbao",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if (not use.card:isKindOf("SkillCard")) and use.card:isDamageCard() and (use.from:objectName() ~= player:objectName()) and use.to:contains(player) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            local log = sgs.LogMessage()
            log.type = "$ark_yongbaolog"
            log.from = use.from
            room:sendLog(log)

            room:setPlayerMark(use.from, "&ark_yongbao-SelfClear", 1)
            room:loseHp(use.from, 1, true, player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_yongbaolimit = sgs.CreateCardLimitSkill
{
    name = "#ark_yongbaolimit",
    limit_list = function(self, player)
        if player:getMark("&ark_yongbao-SelfClear") > 0 then 
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("&ark_yongbao-SelfClear") > 0 then 
            return "Slash,Duel|.|.|."
        else
            return ""
        end
    end,
}

ark_kewang = sgs.CreateTriggerSkill{
    name = "ark_kewang",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.damage == 1 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            player:drawCards(player:getHp())
        elseif damage.damage > 1 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local log = sgs.LogMessage()
            log.type = "$ark_kewangdamage"
            log.from = player
            log.arg = self:objectName()
            log.arg2 = damage.damage
            room:sendLog(log)
            if damage.from then
                room:loseHp(damage.from, 1, true, player, self:objectName())
            end
            return true
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_specterTU:addSkill(ark_shuangsheng)
ark_specterTU:addSkill(ark_shuangshengonly)
ark_specterTU:addSkill(ark_douzheng)
ark_specterTU:addSkill(ark_specterTU_end)
ark_specterTU:addSkill(ark_kewang)
ark_specterTU_kuilei:addSkill(ark_shuangsheng_kuilei)
ark_specterTU_kuilei:addSkill(ark_shuangsheng_kuileionly)
ark_specterTU_kuilei:addSkill(ark_specterTU_end)
ark_specterTU_kuilei:addSkill(ark_yongbao)
ark_specterTU_kuilei:addSkill(ark_yongbaolimit)
ark_specterTU_death:addSkill(ark_specterTU_endlog)
extension:insertRelatedSkills("ark_shuangsheng", "#ark_shuangshengonly")
extension:insertRelatedSkills("ark_shuangsheng_kuilei", "#ark_shuangsheng_kuileionly")
extension:insertRelatedSkills("ark_yongbao", "#ark_yongbaolimit")

ark_dorothy = sgs.General(extension, "ark_dorothy", "ark", 3, false, false, false)

ark_gongzhen = sgs.CreateTriggerSkill{
    name = "ark_gongzhen",
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
        if card:isKindOf("SkillCard") then return false end
        local ctype = getTypeString(card)
        if player:getMark("ark_gongzhen_usedtype"..ctype.."-Clear") > 0 then return false end
        room:setPlayerFlag(player, "ark_gongzhen"..ctype)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ark_gongzhen:"..ctype, true, false)
        room:setPlayerFlag(player, "-ark_gongzhen"..ctype)
        if not target then return false end

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)

        room:broadcastSkillInvoke(self:objectName())
        room:addPlayerMark(player, "ark_gongzhen_usedtype"..ctype.."-Clear")
        local players = sgs.SPlayerList()
        players:append(player)
        room:addPlayerMark(target, "&ark_gongzhen_recordtype+"..ctype, 1, players)
        room:addPlayerMark(target, "ark_gongzhen_from"..ctype..player:objectName())
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_gongzhenbuff = sgs.CreateTriggerSkill{
    name = "#ark_gongzhenbuff",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:isKindOf("SkillCard") then return false end
        local ctype = getTypeString(card)
        if player:getMark("&ark_gongzhen_recordtype+"..ctype) == 0 then return false end
        local players = room:findPlayersBySkillName("ark_gongzhen")
        for _,p in sgs.qlist(players) do
            if player:getMark("ark_gongzhen_from"..ctype..p:objectName()) > 0 then
                room:sendCompulsoryTriggerLog(p, "ark_gongzhen", true, true)
                room:removePlayerMark(player, "ark_gongzhen_from"..ctype..p:objectName())
                room:removePlayerMark(player, "&ark_gongzhen_recordtype+"..ctype)
                p:drawCards(1, "ark_gongzhen")
                room:damage(sgs.DamageStruct(nil, p, player, 1, sgs.DamageStruct_Normal))
                room:getThread():delay(500)
                if player:isAlive() then
                    if card:isKindOf("BasicCard") and player:canDiscard(player, "he") then
                        room:askForDiscard(player, "ark_gongzhen", 2, 2, false, false)
                    elseif card:isKindOf("TrickCard") then
                        room:setPlayerMark(player, "&ark_gongzhen-Clear", 1)

                        local log = sgs.LogMessage()
                        log.type = "$ark_gongzhenlimitc"
                        log.from = player
                        room:sendLog(log)

                    elseif card:isKindOf("EquipCard") then
                        for _,other in sgs.qlist(room:getAlivePlayers()) do
                            if other:getNextAlive():objectName() ~= player:objectName() then
                                if other:getMark("&ark_gongzhen_recordtype+"..ctype) > 0 and other:getMark("ark_gongzhen_from"..ctype..p:objectName()) > 0 then
                                    room:removePlayerMark(other, "ark_gongzhen_from"..ctype..p:objectName())
                                    room:removePlayerMark(other, "&ark_gongzhen_recordtype+"..ctype)
                                    p:drawCards(1, "ark_gongzhen")
                                    room:damage(sgs.DamageStruct(nil, p, other, 1, sgs.DamageStruct_Normal))
                                    room:getThread():delay(500)
                                end
                            end
                        end
                        local nextp = player:getNextAlive()
                        if nextp:getMark("&ark_gongzhen_recordtype+"..ctype) > 0 and nextp:getMark("ark_gongzhen_from"..ctype..p:objectName()) > 0 then
                            room:removePlayerMark(nextp, "ark_gongzhen_from"..ctype..p:objectName())
                            room:removePlayerMark(nextp, "&ark_gongzhen_recordtype+"..ctype)
                            p:drawCards(1, "ark_gongzhen")
                            room:damage(sgs.DamageStruct(nil, p, nextp, 1, sgs.DamageStruct_Normal))
                            room:getThread():delay(500)
                        end
                    end
                end
            end
            if player:isDead() then return false end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

ark_gongzhenlimit = sgs.CreateCardLimitSkill
{
    name = "#ark_gongzhenlimit",
    limit_list = function(self, player)
        if player:getMark("&ark_gongzhen-Clear") > 0 then 
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("&ark_gongzhen-Clear") > 0 then 
            return "."
        end
    end,
}

ark_dorothy:addSkill(ark_gongzhen)
ark_dorothy:addSkill(ark_gongzhenbuff)
ark_dorothy:addSkill(ark_gongzhenlimit)
extension:insertRelatedSkills("ark_gongzhen", "#ark_gongzhenbuff")
extension:insertRelatedSkills("ark_gongzhen", "#ark_gongzhenlimit")

ark_texasTO = sgs.General(extension, "ark_texasTO", "ark", 3, false, false, false)

ark_jianmo = sgs.CreateTriggerSkill{
    name = "ark_jianmo",
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then return false end
            local targets = room:findPlayersBySkillName(self:objectName())
            local can = false
            room:setPlayerFlag(player, "ark_jianmotarget")--ai
            for _,p in sgs.qlist(targets) do
                if p:getMark("ark_jianmo-Clear") == 0 and p:objectName() ~= use.from:objectName() then
                    local prompt = string.format("discard:%s::%s:",use.from:getGeneralName(),use.card:getSkillName())
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerMark(p, "ark_jianmo-Clear", 1)
                        can = true
                        break
                    end
                end
            end
            room:setPlayerFlag(player, "-ark_jianmotarget")--ai
            if not can then return false end

            local uselog = sgs.LogMessage()
            uselog.type = "$ark_jianmochange"
            uselog.from = player
            uselog.arg = use.card:getSkillName()
            room:sendLog(uselog)

            if not use.from:isNude() then
                local card = room:askForCardChosen(use.from, use.from, "he", self:objectName())
                room:throwCard(card, use.from, use.from)
            else
                local log = sgs.LogMessage()
                log.type = "$ark_jianmonocard"
                log.from = player
                log.arg = self:objectName()
                room:sendLog(log)
            end
            room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
            return true
        end

        if event == sgs.TargetConfirmed then
            if not player:hasSkill("ark_jianmo") then return false end
            local use = data:toCardUse()
            if use.card:isDamageCard() and use.from:objectName() == player:objectName() then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(use.to) do
                    if p:getMark("ark_jianmouseto-Clear") == 0 then
                        targets:append(p)
                    end
                end
                if targets:length() == 0 then return false end
                local others = room:askForPlayersChosen(player, targets, self:objectName(), 0, targets:length(), "@ark_jianmo:"..use.card:objectName(), true, true)
                if others and others:length() > 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    for _,p in sgs.qlist(others) do
                        room:setPlayerMark(p, "ark_jianmouseto-Clear", 1)
                        room:addPlayerMark(p, "@skill_invalidity")

                        local log = sgs.LogMessage()
                        log.type = "$ark_jianmoloseskill"
                        log.from = p
                        log.arg = self:objectName()
                        room:sendLog(log)
                    end
                end
            end
        end

        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("ark_jianmouseto-Clear") > 0 then
                        room:setPlayerMark(p, "ark_jianmouseto-Clear", 0)
                        room:removePlayerMark(p, "@skill_invalidity")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

ark_jianyu = sgs.CreateTriggerSkill{
    name = "ark_jianyu",
    events = {sgs.EventPhaseStart, sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName("_ark_jianyu")
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) and (not player:isProhibited(p, slash)) then
                    targets:append(p)
                end
            end
            if targets:length() == 0 then
                slash:deleteLater()
                local log = sgs.LogMessage()
                log.type = "$ark_jianyunotarget"
                log.from = player
                room:sendLog(log)
                return false 
            end
            room:useCard(sgs.CardUseStruct(slash, player, targets, false))
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and use.card:getSkillName() == self:objectName() then
                local targets = room:askForPlayersChosen(player, use.to, self:objectName(), 0, use.to:length(), "@ark_jianyu:"..use.card:objectName(), true, true)
                if targets and targets:length() > 0 then
                    local log = sgs.LogMessage()
                    log.type = "$ark_jianyuremove"
                    log.from = player
                    log.to = targets
                    room:sendLog(log)

                    player:drawCards(targets:length())
                    local nullified_list = use.nullified_list
                    for _,p in sgs.qlist(targets) do
		                table.insert(nullified_list, p:objectName())
                    end
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

ark_chujue = sgs.CreateTriggerSkill{
    name = "ark_chujue",
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            local targets = sgs.SPlayerList()
            local no_respond_list = use.no_respond_list
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    targets:append(p)
                    table.insert(no_respond_list, p:objectName())
                end
            end
            if targets:length() == 0 then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local log = sgs.LogMessage()
            log.type = "$ark_chujue_norespond"
            log.from = player
            log.to = targets
            log.arg = self:objectName()
            log.card_str = use.card:toString()
            room:sendLog(log)

            use.no_respond_list = no_respond_list
            data:setValue(use)
        end

        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:getLostHp() <= 1 then return false end
            if damage.to:objectName() == player:objectName() then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

            local n = damage.to:getLostHp() - 1
            local log = CreateDamageLog(damage, n, self:objectName(), true)
            room:sendLog(log)

            damage.damage = damage.damage + n
            data:setValue(damage)
        end
        
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName()
            and death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "&ark_chujue", player:getMark("&ark_chujue")+1)
                player:drawCards(2)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_chujuerange = sgs.CreateAttackRangeSkill
{
    name = "#ark_chujuerange",
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("ark_chujue") then
            return player:getMark("&ark_chujue")
        end
        return 0
    end
} 

ark_texasTO:addSkill(ark_jianmo)
ark_texasTO:addSkill(ark_jianyu)
ark_texasTO:addSkill(ark_chujue)
ark_texasTO:addSkill(ark_chujuerange)
extension:insertRelatedSkills("ark_chujue", "#ark_chujuerange")

ark_liren_zuiliezhe = sgs.General(extension, "ark_liren_zuiliezhe", "ark", 4, true, false, false)

ark_zhuilie = sgs.CreateZeroCardViewAsSkill
{
    name = "ark_zhuilie",
    view_as = function(self)
        return ark_zhuilieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#ark_zhuilie") < 2
    end,
}

ark_zhuilieCard = sgs.CreateSkillCard
{
    name = "ark_zhuilie",
    filter = function(self, targets, to_select, player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Normal))
        if effect.from:isAlive() and effect.to:isAlive() and effect.to:canSlash(effect.from, true, 0) then
            if not room:askForUseSlashTo(effect.to, effect.from, "@ark_zhuilie:"..effect.from:getGeneralName(), true, false, true) then
                room:addPlayerHistory(effect.from, "#ark_zhuilie", 1)
            end
        else
            room:addPlayerHistory(effect.from, "#ark_zhuilie", 1)
        end
        if effect.from:usedTimes("#ark_zhuilie") < 2 then
            local log = sgs.LogMessage()
            log.type = "$ark_zhuilie_twice"
            log.from = effect.from
            log.arg = self:objectName()
            room:sendLog(log)
        end
    end,
}

ark_guodu = sgs.CreateTriggerSkill{
    name = "ark_guodu",
    events = {sgs.Damaged, sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and damage.from:getMark("&ark_guodu") == 0 then
                room:setPlayerMark(damage.from, "&ark_guodu", 1)
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local log = sgs.LogMessage()
                log.type = "$ark_guodu_start"
                log.from = damage.from
                room:sendLog(log)
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.from:objectName() == player:objectName() then
                local first = true
                for _,to in sgs.qlist(use.to) do
                    if to:getMark("&ark_guodu") > 0 and (not to:isKongcheng()) and player:objectName() ~= to:objectName() then
                        if first then
                            first = false
                            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                        end
                        local n = math.max(1, to:getHandcardNum() - to:getHp())
                        local log = sgs.LogMessage()
                        log.type = "$ark_guodu_effect"
                        log.from = to
                        log.arg = n
                        room:sendLog(log)

                        room:askForDiscard(to, self:objectName(), n, n, false, false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

ark_guodu_count = sgs.CreateTriggerSkill{
    name = "#ark_guodu_count",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
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
        if (not card) or card:isKindOf("SkillCard") then return false end
        if card:isKindOf("Slash") then
            room:setPlayerMark(player, "&ark_guodu_cant", 1)
            room:addPlayerMark(player, "ark_guodu_usecount", 3)
        else
            if player:getMark("ark_guodu_usecount") > 0 then
                room:removePlayerMark(player, "ark_guodu_usecount")
                if player:getMark("ark_guodu_usecount") == 0 then
                    room:setPlayerMark(player, "&ark_guodu_cant", 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&ark_guodu") > 0
    end,
}

ark_guodu_limit = sgs.CreateCardLimitSkill
{
    name = "#ark_guodu_limit",
    limit_list = function(self, player)
        if player:getMark("&ark_guodu_cant") > 0 then 
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("&ark_guodu_cant") > 0 then 
            return "Slash|.|.|."
        end
    end,
}

ark_tanshuo = sgs.CreateTriggerSkill{
    name = "ark_tanshuo",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("&ark_guodu") > 0 then
                    targets:append(p)
                end
            end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            if targets:length() ~= 0 then
                local enemies =  room:askForPlayersChosen(player, targets, self:objectName(), 1, targets:length(), "@ark_tanshuo", false, true)
                local log = sgs.LogMessage()
                log.type = "$ark_tanshuo_death"
                log.from = player
                log.to = enemies
                room:sendLog(log)
                for _,enemy in sgs.qlist(enemies) do
                    if enemy:getMaxHp() > 1 then
                        room:loseMaxHp(enemy, (enemy:getMaxHp() - 1), self:objectName())
                    end
                end
            end
        end 
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_liren_zuiliezhe:addSkill(ark_zhuilie)
ark_liren_zuiliezhe:addSkill(ark_guodu)
ark_liren_zuiliezhe:addSkill(ark_guodu_count)
ark_liren_zuiliezhe:addSkill(ark_guodu_limit)
ark_liren_zuiliezhe:addSkill(ark_tanshuo)
extension:insertRelatedSkills("ark_guodu", "#ark_guodu_count")
extension:insertRelatedSkills("ark_guodu", "#ark_guodu_limit")

ark_chongyue = sgs.General(extension, "ark_chongyue", "ark", 3, true, false, false)

ark_wanxiang = sgs.CreateTriggerSkill{
    name = "ark_wanxiang",
    events = {sgs.CardUsed,sgs.CardResponded, sgs.Damage, sgs.DamageCaused,sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:hasFlag("ark_wanxiang") then
                room:setCardFlag(use.card, "RemoveFromHistory")
            end
        end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf("SkillCard") then return false end
            room:addPlayerMark(player, "&ark_wanxiang", 1)
            if player:getMark("&ark_wanxiang") >= 3 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:setPlayerMark(player, "&ark_wanxiang", 0)
                player:drawCards(1, self:objectName())
                local choices = "ark_chongying+ark_fuchen+ark_wowu"
                local choice = room:askForChoice(player, self:objectName(), choices)
                
                local log = sgs.LogMessage()
                log.type = "$ark_wanxiang_choose"
                log.from = player
                log.arg = "ark_wanxiang:"..choice
                room:sendLog(log)

                if player:isDead() then return false end
                if choice == "ark_wowu" then
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                            room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
                            room:setCardFlag(id, "ark_wanxiang")
                            room:setCardTip(id, "ark_wanxiang")
                            return false
                        end
                    end
                    for _,id in sgs.qlist(room:getDiscardPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                            room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
                            room:setCardFlag(id, "ark_wanxiang")
                            room:setCardTip(id, "ark_wanxiang")
                            return false
                        end
                    end
                else
                    room:addPlayerMark(player, string.format("&%s", choice), 1)
                end
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName() and damage.to:isAlive()
            and player:getMark("&ark_fuchen") > 0 and damage.to:faceUp() then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:removePlayerMark(player, "&ark_fuchen", 1)
                damage.to:turnOver()
            end
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName() and player:getMark("&ark_chongying") > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local n = math.min(player:getMark("&ark_chongying"), 3)
                local log = CreateDamageLog(damage, n, self:objectName(), true)
                room:sendLog(log)
                room:removePlayerMark(player, "&ark_chongying", n)

                damage.damage = damage.damage + n
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_wanxiang_buff = sgs.CreateTargetModSkill{
    name = "#ark_wanxiang_buff",
    residue_func = function(self, from, card)
        if card:hasFlag("ark_wanxiang") then return 1000 end
        return 0
    end,
}

ark_zhige = sgs.CreateTriggerSkill{
    name = "ark_zhige",
    events = {sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and (not damage.card:isKindOf("SkillCard")) then else return false end
            room:setCardFlag(damage.card, "ark_zhige")
            if damage.to:isAlive() and damage.card:getSkillName() == self:objectName() then
                room:setPlayerMark(damage.to, "&ark_zhige-Clear", 1)
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("ark_zhige") and player:isAlive() then
                room:sendCompulsoryTriggerLog(player, "ark_zhige", true, true)
                player:drawCards(1, "ark_zhige")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_zhige_other = sgs.CreateTriggerSkill{
    name = "#ark_zhige_other",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local _data = sgs.QVariant()
        _data:setValue(player)
        for _,skiller in sgs.qlist(room:findPlayersBySkillName("ark_zhige")) do
            if player:isDead() then return false end
            if skiller:objectName() ~= player:objectName() then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
                slash:setSkillName("_ark_zhige")
                if not skiller:isProhibited(player, slash) then
                    if room:askForSkillInvoke(skiller, "ark_zhige", _data) then
                        --room:broadcastSkillInvoke("ark_zhige")
                        room:useCard(sgs.CardUseStruct(slash, skiller, player, true), false)
                        room:askForDiscard(skiller, "ark_zhige", 1, 1, false, true)
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
        return target ~= nil
    end,
}

ark_zhige_limit = sgs.CreateProhibitSkill{
    name = "#ark_zhige_limit",
    is_prohibited = function(self, from, to, card)
        return from:getMark("&ark_zhige-Clear") > 0 and from:objectName() ~= to:objectName()
        and (not card:isKindOf("SkillCard"))
    end,
}

ark_chongyue:addSkill(ark_wanxiang)
ark_chongyue:addSkill(ark_wanxiang_buff)
ark_chongyue:addSkill(ark_zhige)
ark_chongyue:addSkill(ark_zhige_other)
ark_chongyue:addSkill(ark_zhige_limit)
extension:insertRelatedSkills("ark_wanxiang", "#ark_wanxiang_buff")
extension:insertRelatedSkills("ark_zhige", "#ark_zhige_other")
extension:insertRelatedSkills("ark_zhige", "#ark_zhige_other")

ark_nearl_RK = sgs.General(extension, "ark_nearl_RK", "ark", 3, false, false, false)

ark_zhuye = sgs.CreateTriggerSkill{
    name = "ark_zhuye",
    events = {sgs.Dying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@ark_zhuye_mark",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke")) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "@ark_zhuye_mark", 0)
                room:setPlayerMark(player, "&ark_zhuye", 1)
                room:addPlayerMark(player, "&ark_zhuye_damage", 4)
                local n = math.ceil(player:getMaxHp()/2)
                if n ~= player:getMaxHp() then
                    room:loseMaxHp(player, player:getMaxHp() - n, self:objectName())
                end
                room:recover(player, sgs.RecoverStruct(self:objectName(), player, player:getMaxHp() - player:getHp()))
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getMark("@ark_zhuye_mark") > 0
    end,
}

ark_zhuye_buff = sgs.CreateTriggerSkill{
    name = "#ark_zhuye_buff",
    events = {sgs.DamageForseen, sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            room:broadcastSkillInvoke("ark_zhuye")
            local log = CreateDamageLog(damage, 1, "ark_zhuye", true)
            room:sendLog(log)
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
        if event == sgs.DamageForseen then
            if player:getMark("&ark_zhuye_damage") > 0 then
                room:removePlayerMark(player, "&ark_zhuye_damage", 1)
                local damage = data:toDamage()
                room:broadcastSkillInvoke("ark_zhuye")
                local log = CreateDamageLog(damage, damage.damage, "ark_zhuye", false)
                room:sendLog(log)
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target:getMark("&ark_zhuye") > 0
    end,
}

ark_poxiao = sgs.CreateTriggerSkill{
    name = "ark_poxiao",
    events = {sgs.GameStart,sgs.QuitDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),
        self:objectName(), "@ark_poxiao", true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            if target:getMark("ark_poxiao_from"..player:objectName()) > 0 and target:faceUp() then
                target:turnOver()
            end
            room:setPlayerMark(target, "ark_poxiao_from"..player:objectName(), 1)
            local _player = sgs.SPlayerList()
            _player:append(player)
            room:setPlayerMark(target, "&ark_poxiao", 1, _player)
            room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_yaoyang = sgs.CreateTriggerSkill{
    name = "ark_yaoyang",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local n = 1
            if player:getHp() <= 2 then n = 2 end
            for i = 1, n, 1 do
                local card = arkGetSpecialCard(room, player, "Slash", "draw+discard", true)
                if not card then return false end
                room:setCardFlag(card, "ark_yaoyang")
                room:setCardFlag(card, "RemoveFromHistory")
                room:setCardTip(card:getId(), "ark_yaoyang")
            end
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            room:setCardFlag(use.card, "SlashIgnoreArmor")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ark_yaoyang_buff = sgs.CreateTargetModSkill{
    name = "#ark_yaoyang_buff",
    residue_func = function(self, from, card)
        if card:hasFlag("ark_yaoyang") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill("ark_yaoyang") then return 1000 end
        return 0
    end,
}

ark_nearl_RK:addSkill(ark_zhuye)
ark_nearl_RK:addSkill(ark_zhuye_buff)
ark_nearl_RK:addSkill(ark_poxiao)
ark_nearl_RK:addSkill(ark_yaoyang)
ark_nearl_RK:addSkill(ark_yaoyang_buff)
extension:insertRelatedSkills("ark_zhuye", "#ark_zhuye_buff")
extension:insertRelatedSkills("ark_yaoyang", "#ark_yaoyang_buff")

local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("arknight_winmusic") then skills:append(arknight_winmusic) end

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable 
{
    ["arknights"] = "明日方舟",
    ["ark"] = "舟",

    ["ark_exusiai"] = "能天使",
    ["#ark_exusiai"] = "午夜邮差",
    ["ark_guozai"] = "过载",
    [":ark_guozai"] = "出牌阶段，若你的手牌数等于你的体力值，你可以摸X张牌，视为你使用了一张无距离限制且不计入次数限制的【杀】。（X为此技能本阶段发动次数）\
    若你本阶段内此技能发动次数大于你的体力上限，你须先失去相当于两者差值的体力。",

    ["ark_Isamala"] = "伊莎玛拉",
    ["#ark_Isamala"] = "腐化之心",
    ["ark_yongchao"] = "涌潮",
    [":ark_yongchao"] = "锁定技，在你于出牌阶段内使用或打出X张牌后，摸X张牌,然后重置使用计数。（X为你本阶段发动此技能的次数）",
    ["ark_yongchao1"] = "涌潮目标",
    ["ark_yongchao2"] = "涌潮计数",
    ["ark_jingmi"] = "静谧",
    [":ark_jingmi"] = "锁定技，你的出牌阶段内，其他角色的非锁定技失效。",
    ["$ark_jingmistart"] = "<font color=\"red\"><b>潮水涌起，整个世界陷入了静谧之中。</b></font>",

    ["ark_specterTU"] = "归溟幽灵鲨",
    ["#ark_specterTU"] = "生而为一",
    ["&ark_specterTU"] = "幽灵鲨",
    ["ark_specterTU_kuilei"] = "归溟幽灵鲨[傀儡]",
    ["&ark_specterTU_kuilei"] = "幽灵鲨",
    ["ark_specterTU_death"] = "归溟幽灵鲨",
    ["&ark_specterTU_death"] = "幽灵鲨",
    ["ark_shuangsheng"] = "双生",
    [":ark_shuangsheng"] = "锁定技，当你进入濒死状态时，将你的武将替换为“傀儡”，在你的下个准备阶段时换回。更换武将牌时你回复所有体力。",
    ["ark_shuangsheng_kuilei"] = "双生",
    [":ark_shuangsheng_kuilei"] = "锁定技，准备阶段，将你的武将替换为“本体”。更换武将牌时你回复所有体力。",
    ["ark_douzheng"] = "斗争",
    [":ark_douzheng"] = "锁定技，你对其他角色造成伤害时，令此伤害+1。若你的体力值大于该角色，你须先失去1点体力。",
    ["$ark_specterTU_change"] = "%from 切换为了 %arg 。",
    ["ark_specterTU_first"] = "本体",
    ["ark_specterTU_second"] = "傀儡",
    ["ark_specterTU_endlog"] = "安息",
    [":ark_specterTU_endlog"] = "此处埋葬着一位深海猎人。",
    ["ark_yongbao"] = "拥抱",
    [":ark_yongbao"] = "锁定技，当你成为伤害类牌的目标后，伤害来源失去1点体力，直到该角色的下一个回合结束，其不能再使用【杀】或【决斗】。",
    ["$ark_yongbaolog"] = "%from 不能再使用【杀】或【决斗】直到其下个回合结束。",
    ["ark_kewang"] = "渴望",
    [":ark_kewang"] = "锁定技，当你即将受到伤害时，若：伤害值为1，你摸等于当前体力值的牌；伤害值大于1，防止此伤害并令伤害来源失去1点体力。",
    ["$ark_kewangdamage"] = "因 %arg 的效果防止了 %from 即将受到的 %arg2 点伤害。",

    ["ark_dorothy"] = "多萝西",
    ["#ark_dorothy"] = "梦想家",
    ["ark_gongzhen"] = "共振",
    [":ark_gongzhen"] = "每回合每种类型限一次，在你使用或打出一张牌时，你可以标记一名其他角色。\
    当该角色使用或打出同类型的牌时，你摸1张牌并对其造成1点伤害，然后执行以下效果：\
    ①基本牌：该角色弃置两张手牌。\
    ②锦囊牌：本回合其不能再使用牌。\
    ③装备牌：依次触发其上家和下家的装备牌标记（不再执行此效果）。",
    ["ark_gongzhen_recordtype"] = "共振",
    ["@ark_gongzhen"] = "你可以标记一名其他角色（%src）",
    ["$ark_gongzhenlimitc"] = "%from 本回合其不能再使用牌",

    ["ark_texasTO"] = "缄默德克萨斯",
    ["#ark_texasTO"] = "斩棘辟路",
    ["&ark_texasTO"] = "德克萨斯",
    ["ark_jianmo"] = "缄默",
    [":ark_jianmo"] = "当你使用伤害类牌指定目标后，你可以令其中任意名目标的非锁定技失效直到当前回合结束。\
    每回合限一次，其他角色使用技能卡时，那个技能卡的效果变为其弃置自己的一张牌。",
    ["ark_jianmo:discard"] = "你可以令 %src 使用的技能卡【%arg】的效果变为其弃置自己的一张牌",
    ["$ark_jianmonocard"] = "%from 没有可以被 %arg 弃置的牌。",
    ["$ark_jianmochange"] = "%from 使用的技能卡 %arg 的效果被改为 使用者弃置自己的一张牌 。",
    ["@ark_jianmo"] = "你可以令【%src】的任意名目标非锁定技失效直到当前回合结束",
    ["$ark_jianmoloseskill"] = "%from 的非锁定技因 %arg 的效果将失效直到当前回合结束。",
    ["ark_jianyu"] = "剑雨",
    [":ark_jianyu"] = "锁定技，准备阶段，你视为使用了一张指定攻击范围内所有其他角色为目标的【杀】。\
    你可以令此【杀】对任意名目标无效并摸等量的牌。",
    ["$ark_jianyunotarget"] = "攻击范围内没有可以成为 %from 使用【杀】的目标的角色。",
    ["$ark_jianyuremove"] = "%from 令此【杀】对 %to 无效。",
    ["@ark_jianyu"] = "你可以令此【%src】对任意名目标无效并摸等量的牌",
    ["ark_chujue"] = "处决",
    [":ark_chujue"] = "锁定技，已受伤的其他角色无法响应你使用的牌。\
    你对已受伤的其他角色造成的伤害基数改为其已损失体力值。\
    在你杀死一名其他角色后，你摸2张牌并令你的攻击范围+1。",
    ["$ark_chujue_norespond"] = "%from 使用的 %card 因 %arg 的效果不可被 %to 响应。",

    ["ark_liren_zuiliezhe"] = "利刃-追猎者",
    ["#ark_liren_zuiliezhe"] = "皇帝的利刃",
    ["&ark_liren_zuiliezhe"] = "追猎者",
    ["ark_zhuilie"] = "追猎",
    [":ark_zhuilie"] = "出牌阶段限一次，你可以对一名其他角色造成1点伤害，然后该角色可以对你使用一张【杀】并令此技能于本阶段内改为出牌阶段限两次。",
    ["@ark_zhuilie"] = "你可以对%src使用一张【杀】并令“追猎”于本阶段内改为出牌阶段限两次",
    ["$ark_zhuilie_twice"] = "现在 %from 于本阶段中可以使用两次 %arg 。",
    ["ark_guodu"] = "国度",
    [":ark_guodu"] = "锁定技，当你受到其他角色的伤害时，伤害来源于本局游戏内使用的每四张牌中至多只能有一张【杀】。\
    当你使用牌指定受“国度”影响的其他角色时，令其将手牌弃至当前体力值(至少弃置1张)。",
    ["$ark_guodu_start"] = "来自“国度”的恶意开始笼罩 %from 。",
    ["$ark_guodu_effect"] = "源于内心的恐惧驱使着 %from 去弃置 %arg 张手牌。",
    ["ark_guodu_cant"] = "国度:禁止出杀",
    ["ark_tanshuo"] = "坍缩",
    [":ark_tanshuo"] = "锁定技，你死亡时，你须选择至少一名受国度影响的角色，令这些角色依次将体力上限调整为1。",
    ["@ark_tanshuo"] = "你须选择至少一名受国度影响的角色，令这些角色依次将体力上限调整为1",
    ["$ark_tanshuo_death"] = "随着 %from 的逝去，被拘束在其体内的邪魔再不受限制， %to 等角色的体力上限，成为了它重获自由后的第一份大餐。",

    ["ark_chongyue"] = "重岳",
    ["#ark_chongyue"] = "万象伶仃",
    ["designer:ark_chongyue"] = "Nyarz",

    ["ark_wanxiang"] = "万象",
    [":ark_wanxiang"] = "锁定技，在你累计使用或打出3张牌后，你摸1张牌，然后选择1项：\
    <font color='#D38516'><b>冲盈</b></font>:下次对其他角色造成的伤害+1（至多+3）。\
    <font color='#D38516'><b>拂尘</b></font>:下次对其他角色造成伤害后令其翻至背面。\
    <font color='#D38516'><b>我无</b></font>:获得一张不计入次数限制的【杀】。",
    ["ark_chongying"] = "冲盈",
    [":ark_chongying"] = "下次对其他角色造成的伤害+1（至多+3）",
    ["ark_fuchen"] = "拂尘",
    [":ark_fuchen"] = "下次对其他角色造成伤害后令其翻至背面",
    ["ark_wanxiang:ark_chongying"] = "冲盈:下次对其他角色造成的伤害+1（至多+3）",
    ["ark_wanxiang:ark_fuchen"] = "拂尘:下次对其他角色造成伤害后令其翻至背面",
    ["ark_wanxiang:ark_wowu"] = "我无:获得一张不计入次数限制的【杀】",
    ["$ark_wanxiang_choose"] = "%from 选择了 %arg",
    ["ark_zhige"] = "止戈",
    [":ark_zhige"] = "在你使用的牌结算后，若此牌造成过伤害，你摸1张牌。\
    其他角色造成伤害后，你可以视为对其使用了一张【杀】，若此【杀】造成了伤害，其本回合不能对其他角色使用牌。若如此做，你弃置一张牌。",

    ["$ark_wanxiang1"] = "千招百式在一息！",
    ["$ark_wanxiang2"] = "劲发江潮落，气收秋毫平！",
    ["$ark_wanxiang3"] = "日落飞锦绣长河，天地壮我行色。",
    ["$ark_wanxiang4"] = "征蓬未定，甲胄在身。",
    ["$ark_zhige1"] = "你们解决问题，还是只会仰仗干戈吗？",
    ["$ark_zhige2"] = "形不成形，意不在意，再去练练吧。",
    ["~ark_chongyue"] = "胜败乃兵家常事，振作些。",

    ["ark_nearl_RK"] = "耀骑士临光",
    ["&ark_nearl_RK"] = "临光",
    ["#ark_nearl_RK"] = "耀骑士",
    ["designer:ark_nearl_RK"] = "Nyarz",

    ["ark_zhuye"] = "逐夜",
    [":ark_zhuye"] = "限定技，当你处于濒死状态时，你可以令你的体力上限减半并回复所有体力。\
    若如此做，本局游戏内你造成的伤害+1，防止你受到的下4次伤害。",
    ["ark_zhuye_damage"] = "逐夜免伤",
    ["ark_zhuye:invoke"] = "你可以发动“逐夜”令你的体力上限减半并回复所有体力",
    ["ark_poxiao"] = "破晓",
    [":ark_poxiao"] = "游戏开始时或当你脱离濒死状态后，你可以对一名其他角色造成1点伤害。若这不是你第一次对该角色发动此技能，令其翻至背面。",
    ["@ark_poxiao"] = "你可以对一名其他角色造成1点伤害",
    ["ark_yaoyang"] = "耀阳",
    [":ark_yaoyang"] = "锁定技，你使用【杀】无视防具且无距离限制。准备阶段，你获得1张不计入次数限制的【杀】，若你体力值不大于2，再获得1张。",

    ["$ark_zhuye1"] = "这长夜也应结束了。",
    ["$ark_zhuye2"] = "手执威光，便是为了扫尽世间恶行。",
    ["$ark_poxiao1"] = "我将带头冲锋。",
    ["$ark_poxiao2"] = "我将尽除障碍。",
    ["$ark_yaoyang1"] = "太阳啊，请为我颔首吧！",
    ["$ark_yaoyang2"] = "愿光芒浸润你。",
    ["~ark_nearl_RK"] = "还没到放弃的时候，博士，请让我独自断后，重整旗鼓就交给您了。",
}
return packages