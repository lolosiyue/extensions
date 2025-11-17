extension = sgs.Package("feiDIY", sgs.Package_GeneralPack)
local skills = sgs.SkillList()
feimore = sgs.CreateTargetModSkill {
    name = "feimore",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("feizuijiao") and to and to:getMark("feizuijiao") > 0 then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("feizuijiao") and to and to:getMark("feizuijiao") > 0 then
            return 1000
        end
    end,
}
feislashmore = sgs.CreateTargetModSkill {
    name = "feislashmore",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("feijiangchi") and from:getHandcardNum() > from:getHp() then
            return 1000
        end
        if from:hasSkill("feisheji") and to and to:hasEquip() then
            return 1000
        end
        if from:hasSkill("feiwusheng") and card:isRed() then
            return 1000
        end
    end,
}
if not sgs.Sanguosha:getSkill("feislashmore") then skills:append(feislashmore) end
if not sgs.Sanguosha:getSkill("feimore") then skills:append(feimore) end
feiluxun = sgs.General(extension, "feiluxun", "wu", "3", true)
feisunjian = sgs.General(extension, "feisunjian$", "wu", 5, true, false, false, 4)
feichengpu = sgs.General(extension, "feichengpu", "wu", "4", true)
feilianyingCard = sgs.CreateSkillCard {
    name = "feilianyingCard",
    filter = function(self, targets, to_select, erzhang)
        return #targets < sgs.Self:getMark("feilianying") and #targets < 5
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local choices = "Chain+draw"
        local choice = room:askForChoice(source, self:objectName(), choices)
        if choice == "draw" then
            for _, p in pairs(targets) do
                p:drawCards(1)
            end
            local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
            fire_attack:deleteLater()
            fire_attack:setSkillName("feilianying")
            local to_choose = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(source)) do
                if not p:isKongcheng() then
                    to_choose:append(p)
                end
            end
            if to_choose:isEmpty() then return false end
            local target = room:askForPlayerChosen(source, to_choose, self:objectName())
            if target then
                local card_use = sgs.CardUseStruct()
                card_use.from = source
                card_use.to:append(target)
                card_use.card = fire_attack
                room:useCard(card_use, false)
                fire_attack:deleteLater()
            end
        elseif choice == "Chain" then
            for _, p in pairs(targets) do
                room:setPlayerChained(p, true)
            end
            source:drawCards(1)
        end
    end
}
feilianyingVS = sgs.CreateZeroCardViewAsSkill {
    name = "feilianying",
    response_pattern = "@@feilianying",
    view_as = function()
        return feilianyingCard:clone()
    end
}
feilianying = sgs.CreateTriggerSkill {
    name = "feilianying",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardsMoveOneTime },
    view_as_skill = feilianyingVS,
    on_trigger = function(self, event, luxun, data)
        local room = luxun:getRoom()
        local move = data:toMoveOneTime()
        if move.from
            and move.from:objectName() == luxun:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand)
            and move.is_last_handcard then
            luxun:setTag("LianyingMoveData", data)
            local count = 0
            for i = 0, move.from_places:length() - 1, 1 do
                if move.from_places:at(i) == sgs.Player_PlaceHand then
                    count = count + 1
                end
            end
            room:setPlayerMark(luxun, "feilianying", math.max(count))
            if room:askForSkillInvoke(luxun, "feilianying", data) then
                room:askForUseCard(luxun, "@@feilianying", "@feilianying")
            end
        end
        return false
    end
}
feiqianxuncard = sgs.CreateSkillCard {
    name = "feiqianxuncard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets < player:getHandcardNum() and #targets < 5
    end,
    feasible = function(self, targets)
        return #targets ~= 0
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        source:throwAllHandCards()
        for _, p in pairs(targets) do
            p:drawCards(2, "feiqianxun")
            room:askForDiscard(p, self:objectName(), 2, 2, false, true)
        end
    end
}
feiqianxunVS = sgs.CreateViewAsSkill {
    name = "feiqianxun",
    n = 0,
    view_as = function()
        return feiqianxuncard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#feiqianxuncard")) and (not player:isKongcheng())
    end,
}
feiqianxun = sgs.CreateTriggerSkill {
    name = "feiqianxun",
    events = { sgs.TrickEffect, sgs.EventPhaseChanging, sgs.TargetConfirmed },
    view_as_skill = feiqianxunVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TrickEffect and player:hasSkill(self:objectName()) then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("DelayedTrick")
                and player:getPhase() == sgs.Player_Judge then
                if not player:isKongcheng() then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        player:addToPile("feiqx", player:handCards(), false)
                    end
                end
            end
        elseif event == sgs.TargetConfirmed and player:hasSkill(self:objectName()) then
            local use = data:toCardUse()
            if use.to:contains(player)
                and use.from
                and use.from:objectName() ~= player:objectName()
                and use.card:isNDTrick() then
                if not player:isKongcheng() then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        player:addToPile("feiqx", player:handCards(), false)
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:hasSkill(self:objectName()) then
                    if p:getPile("feiqx"):length() > 0 then
                        local dummy = dummyCard()
                        dummy:addSubcards(p:getPile("feiqx"))
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(),
                            self:objectName(), "")
                        room:obtainCard(p, dummy, reason, false)
                        dummy:deleteLater()
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
feiluxun:addSkill(feilianying)
feiluxun:addSkill(feiqianxun)
feizhangliao = sgs.General(extension, "feizhangliao", "wei", "4", true)
feituxi = sgs.CreateTriggerSkill {
    name = "feituxi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart, sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(self:objectName()) and p:getMark("&feizhaohu") > 0 then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            p:loseMark("&feizhaohu", 1)
                            room:obtainCard(p, room:askForCardChosen(p, player, "h", self:objectName()))
                            room:askForDiscard(p, self:objectName(), 1, 1, false, true)
                        end
                    end
                end
            elseif player:getPhase() == sgs.Player_Start
                and player:hasSkill(self:objectName()) then
                player:gainMark("&feizhaohu", 2)
            end
        elseif event == sgs.GameStart
            and player:hasSkill(self:objectName()) then
            player:gainMark("&feizhaohu", 2)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
feizhaohu = sgs.CreateTriggerSkill {
    name = "feizhaohu",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from
            and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand)
            and move.is_last_handcard then
            player:setTag("feizhaohuData", data)
            room:setPlayerMark(player, "feizhaohup", 1)
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self:objectName()) then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        local choices = { "get" }
                        if p:getMark("&feizhaohu") > 0 then
                            table.insert(choices, "lose")
                        end
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
                        if choice == "get" then
                            p:gainMark("&feizhaohu", 1)
                        elseif choice == "lose" then
                            local theDamage = sgs.DamageStruct()
                            theDamage.from = p
                            theDamage.to = player
                            theDamage.damage = 1
                            theDamage.nature = sgs.DamageStruct_Normal
                            room:damage(theDamage)
                            p:loseMark("&feizhaohu", 1)
                        end
                    end
                end
            end
            room:setPlayerMark(player, "feizhaohup", 0)
            room:removeTag("feizhaohuData")
        end
        return false
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
feizhangliao:addSkill(feituxi)
feizhangliao:addSkill(feizhaohu)

feiyinghun = sgs.CreateTriggerSkill {
    name = "feiyinghun",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart, sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(self:objectName()) and p:getMark("&feiyinghun") > 0 then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            local choices = "draw+throw"
                            p:loseMark("&feiyinghun", 1)
                            room:loseHp(p, 1, true, p, self:objectName())
                            if p:getHujia() < 5 then p:gainHujia(1) end
                            local choice = room:askForChoice(p, self:objectName(), choices)
                            if choice == "draw" then
                                player:drawCards(p:getMaxHp(), self:objectName())
                                local n = math.min(player:getCards("he"):length(), p:getHp())
                                room:askForDiscard(player, self:objectName(), n, n, false, true)
                            elseif choice == "throw" then
                                player:drawCards(p:getHp(), self:objectName())
                                local n = math.min(player:getCards("he"):length(), p:getMaxHp())
                                room:askForDiscard(player, self:objectName(), n, n, false, true)
                            end
                        end
                    end
                end
            elseif player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
                player:gainMark("&feiyinghun")
            end
        elseif event == sgs.GameStart and player:hasSkill(self:objectName()) then
            player:gainMark("&feiyinghun", 2)
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
feisunjian:addSkill(feiyinghun)
feizhonglie = sgs.CreateTriggerSkill {
    name = "feizhonglie$",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Death },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:hasSkill(self:objectName()) then return false end
        if death.damage and death.damage.from and death.damage.from:getKingdom() == "wu" or death.who:getKingdom() == "wu" then
            local theRecover = sgs.RecoverStruct()
            theRecover.recover = 1
            theRecover.who = player
            room:recover(player, theRecover)
            player:gainMark("&feiyinghun")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasLordSkill(self:objectName())
    end,
}
feisunjian:addSkill(feizhonglie)
feicaozhang = sgs.General(extension, "feicaozhang", "wei", "4", true)
feiwanghou = sgs.General(extension, "feiwanghou", "wei", "4", true)
feijiangchi = sgs.CreateTriggerSkill {
    name = "feijiangchi",
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local choice = room:askForChoice(player, self:objectName(), "draw+play")
                if choice == "draw" then
                    room:setPlayerFlag(player, "feijiangchi_draw")
                elseif choice == "play" then
                    room:setPlayerFlag(player, "feijiangchi_play")
                end
            end
        elseif (player:getPhase() == sgs.Player_Play
                or player:getPhase() == sgs.Player_Discard)
            and player:hasFlag("feijiangchi_draw") then
            player:setPhase(sgs.Player_Draw)
            room:broadcastProperty(player, "phase")
        elseif (player:getPhase() == sgs.Player_Judge
                or player:getPhase() == sgs.Player_Draw)
            and player:hasFlag("feijiangchi_play") then
            player:setPhase(sgs.Player_Play)
            room:broadcastProperty(player, "phase")
        end
    end
}
feicaozhang:addSkill(feijiangchi)
feiyanliang = sgs.General(extension, "feiyanliang", "qun", "4", true)
feihujueCard = sgs.CreateSkillCard {
    name = "feihujueCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local tiger = targets[1]
        for _, id in sgs.qlist(room:getDrawPile()) do
            if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                room:obtainCard(source, id, false)
                break
            end
        end
        if not tiger:hasSkill("wusheng") then
            room:setPlayerMark(tiger, "feihujue_wusheng", 1)
            room:handleAcquireDetachSkills(tiger, "wusheng")
        end
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:toTrick():setCancelable(true)
        duel:setSkillName(self:objectName())
        if not source:isCardLimited(duel, sgs.Card_MethodUse)
            and not source:isProhibited(tiger, duel) then
            room:useCard(sgs.CardUseStruct(duel, source, tiger))
        end
        duel:deleteLater()
    end
}
feihujueVS = sgs.CreateZeroCardViewAsSkill {
    name = "feihujue",
    view_as = function(self, cards)
        return feihujueCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#feihujueCard")
    end,
}
feihujue = sgs.CreateTriggerSkill {
    name = "feihujue",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging },
    view_as_skill = feihujueVS,
    on_trigger = function(self, event, player, data)
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        local room = player:getRoom()
        if player:getMark("feihujue_wusheng") > 0 then
            if player:hasSkill("wusheng") then
                room:setPlayerMark(player, "feihujue_wusheng", 0)
                room:handleAcquireDetachSkills(player, "-wusheng", true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
feiyanliang:addSkill(feihujue)
feicuxie = sgs.CreateTriggerSkill {
    name = "feicuxie",
    events = { sgs.Damaged, sgs.Damage },
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = player:getRoom()
        if damage.card and damage.card:isKindOf("Slash") then
            return false
        else
            for _, id in sgs.qlist(room:getDrawPile()) do
                if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                    room:obtainCard(player, id, false)
                    break
                end
            end
        end
    end
}
feiyanliang:addSkill(feicuxie)
feiwenchou = sgs.General(extension, "feiwenchou", "qun", "4", true)
feilangduoCard = sgs.CreateSkillCard {
    name = "feilangduoCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local tiger = targets[1]
        local success = source:pindian(tiger, self:objectName(), nil)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:toTrick():setCancelable(true)
        duel:setSkillName(self:objectName())
        if success then
            if not source:isCardLimited(duel, sgs.Card_MethodUse)
                and not source:isProhibited(tiger, duel) then
                room:useCard(sgs.CardUseStruct(duel, source, tiger))
            end
        else
            if not tiger:isCardLimited(duel, sgs.Card_MethodUse)
                and not tiger:isProhibited(source, duel) then
                room:useCard(sgs.CardUseStruct(duel, tiger, source))
            end
        end
        duel:deleteLater()
    end
}
feilangduo = sgs.CreateZeroCardViewAsSkill {
    name = "feilangduo",
    view_as = function(self, cards)
        return feilangduoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#feilangduoCard")) and not player:isKongcheng()
    end,
}
feiwenchou:addSkill(feilangduo)
feibenzi = sgs.CreateTriggerSkill {
    name = "feibenzi",
    events = { sgs.EventPhaseChanging },
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local n = 0
                for _, id in sgs.qlist(room:getDrawPile()) do
                    if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                        room:obtainCard(player, id, false)
                        n = n + 1
                    end
                    if n > 2 then
                        break
                    end
                end
                player:skip(change.to)
            end
        end
        return false
    end
}
feiwenchou:addSkill(feibenzi)
feilvbu = sgs.General(extension, "feilvbu$", "qun", "4", true)
feifeijiang = sgs.CreateTriggerSkill {
    name = "feifeijiang",
    events = { sgs.TargetSpecified, sgs.DamageCaused },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if (event == sgs.DamageCaused) then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("feifeijiangcard") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        if (event == sgs.TargetSpecified) then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash")
                and not use.card:isKindOf("Duel") then
                return false
            end
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then break end
                local dest = sgs.QVariant()
                dest:setValue(p)
                if not p:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), dest) then
                    local to_show = room:askForCardChosen(player, p, "h", self:objectName())
                    local card = sgs.Sanguosha:getCard(to_show)
                    local to_showlist = sgs.IntList()
                    to_showlist:append(to_show)
                    room:showCard(p, to_showlist)
                    if card:isKindOf("BasicCard") then
                        room:throwCard(to_show, p, player)
                    elseif card:isKindOf("TrickCard") then
                        room:setCardFlag(use.card, "feifeijiangcard")
                    elseif card:isKindOf("EquipCard") then
                        local no_respond_list = use.no_respond_list
                        table.insert(no_respond_list, p:objectName())
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                    end
                end
            end
        end
    end
}
feilvbu:addSkill(feifeijiang)
feijiedou = sgs.CreateTriggerSkill {
    name = "feijiedou",
    events = { sgs.TargetConfirmed, sgs.Damage },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from:objectName() ~= player:objectName()
                and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:setFlags("feijiedou")
                    player:setFlags("-feijiedou")
                    if not room:askForUseSlashTo(player, room:getOtherPlayers(player), "feijiedou1") then return false end
                    if player:isAlive() and player:hasFlag("feijiedou") then
                        player:setFlags("-feijiedou")
                        local nullified_list = use.nullified_list
                        for _, p in sgs.qlist(use.to) do
                            table.insert(nullified_list, p:objectName())
                        end
                        use.nullified_list = nullified_list
                        data:setValue(use)
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                player:setFlags("feijiedou")
            end
        end
    end
}
feilvbu:addSkill(feijiedou)
feishejiCard = sgs.CreateSkillCard {
    name = "feishejiCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and (player:inMyAttackRange(to_select) or to_select:hasEquip())
    end,
    feasible = function(self, targets)
        return #targets ~= 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(),
            effect.to:objectName(), "feisheji", "")
        room:moveCardTo(self, effect.to, sgs.Player_PlaceHand, reason, true)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        room:setCardFlag(slash, "feisheji")
        room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
        slash:deleteLater()
    end
}
feishejiVS = sgs.CreateViewAsSkill {
    name = "feisheji",
    n = 1,
    view_filter = function(self, selected, to_selected)
        return to_selected:isKindOf("EquipCard")
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = cards[1]
            local sjcard = feishejiCard:clone()
            sjcard:addSubcard(card)
            sjcard:setSkillName(self:objectName())
            return sjcard
        end
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) then return false end
        return pattern == "slash"
    end
}
feisheji = sgs.CreateTriggerSkill {
    name = "feisheji",
    events = { sgs.Damage },
    view_as_skill = feishejiVS,
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = player:getRoom()
        if damage.card
            and damage.card:isKindOf("Slash")
            and damage.card:hasFlag("feisheji") then
            player:drawCards(2, self:objectName())
        end
    end
}
feilvbu:addSkill(feisheji)
feixiaohu = sgs.CreateTriggerSkill {
    name = "feixiaohu$",
    events = { sgs.Damage },
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = damage.from:getRoom()
        if damage.from:hasLordSkill(self:objectName())
            and damage.from:getPhase() == sgs.Player_NotActive
            and damage.from then
            for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
                if p:getPhase() ~= sgs.Player_NotActive
                    and p:getKingdom() == "qun" then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        damage.from:drawCards(1, self:objectName())
                        p:drawCards(1, self:objectName())
                    end
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
feilvbu:addSkill(feixiaohu)

feifenhuCard = sgs.CreateSkillCard {
    name = "feifenhuCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return true
    end,
    feasible = function(self, targets, player)
        return #targets > 0
    end,
    on_use = function(self, room, player, targets)
        local players = sgs.SPlayerList()
        for _, target in pairs(targets) do
            players:append(target)
            room:setPlayerMark(target, "feifenhu", 1)
        end
        local wgfd = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
        wgfd:setSkillName(self:objectName())
        local card_use = sgs.CardUseStruct()
        card_use.from = player
        card_use.to = players
        card_use.card = wgfd
        room:useCard(card_use, true)
        wgfd:deleteLater()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            room:setPlayerMark(p, "feifenhu", 0)
        end
    end
}
feifenhuVS = sgs.CreateViewAsSkill {
    name = "feifenhu",
    n = 0,
    view_as = function(self, cards)
        return feifenhuCard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@feifenhu"
    end
}
feifenhu = sgs.CreateTriggerSkill {
    name = "feifenhu",
    events = { sgs.EventPhaseChanging, sgs.TargetConfirming },
    view_as_skill = feifenhuVS,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:skip(change.to)
                    room:askForUseCard(player, "@@feifenhu", "@feifenhu")
                end
            end
        end
    end
}
feiwanghou:addSkill(feifenhu)
feifenhuex = sgs.CreateProhibitSkill {
    name = "#feifenhuex",
    is_prohibited = function(self, from, to, card)
        return to and card and card:getSkillName() == "feifenhuCard" and (to:getMark("feifenhu") == 0) and
            card:isKindOf("AmazingGrace")
    end
}
feiwanghou:addSkill(feifenhuex)
feidaizui = sgs.CreateTriggerSkill {
    name = "feidaizui",
    events = { sgs.TargetConfirmed, sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player)
                and use.from and use.from:objectName() ~= player:objectName()
                and use.card:isKindOf("Slash") then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local otherp = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if (p ~= use.from) then
                            otherp:append(p)
                        end
                    end
                    if otherp:isEmpty() then return false end
                    local p = room:askForPlayerChosen(player, otherp, self:objectName())
                    local choice = room:askForChoice(p, self:objectName(), "give+no", data)
                    if choice == "give" then
                        local id = room:askForCardChosen(p, p, "he", self:objectName())
                        room:giveCard(p, player, sgs.Sanguosha:getCard(id), self:objectName())
                        use.to:removeOne(player)
                        use.to:append(p)
                        room:sortByActionOrder(use.to)
                        data:setValue(use)
                        room:getThread():trigger(sgs.TargetConfirming, room, p, data)
                    elseif choice == "no" then
                        local no_respond_list = use.no_respond_list
                        table.insert(no_respond_list, player:objectName())
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                    end
                end
            end
        elseif event == sgs.Damaged then
            if room:askForSkillInvoke(player, self:objectName() .. "draw", data) then
                local least = 1000
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    least = math.min(p:getHandcardNum(), least)
                end
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getHandcardNum() == least then
                        p:drawCards(player:getLostHp(), self:objectName())
                    end
                end
            end
        end
    end
}
feiwanghou:addSkill(feidaizui)

feitouhuo = sgs.CreateTriggerSkill {
    name = "feitouhuo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.Predamage, sgs.Death },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Predamage and player:hasSkill(self:objectName()) then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Normal then
                damage.nature = sgs.DamageStruct_Fire
            end
            data:setValue(damage)
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from == player then
                local choice = room:askForChoice(player, self:objectName(), "hp+Maxhp", data)
                if choice == "hp" then
                    room:loseHp(player, 1, true, player, self:objectName())
                elseif choice == "Maxhp" then
                    room:loseMaxHp(player)
                end
            end
        end
    end,
    --[[can_trigger = function(self, target)
		return target
	end, ]]
}
feichengpu:addSkill(feitouhuo)
feizuijiaoCard = sgs.CreateSkillCard {
    name = "feizuijiaoCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= player:objectName()
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choice = room:askForChoice(effect.to, self:objectName(), "show+no")
        if choice == "show" then
            room:showAllCards(effect.to)
            local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
            analeptic:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(analeptic, effect.from, effect.from, false))
            analeptic:deleteLater()
        elseif choice == "no" then
            if room:askForSkillInvoke(effect.from, self:objectName()) then
                effect.from:turnOver()
                room:recover(effect.from, sgs.RecoverStruct(effect.from))
                local upper = math.min(5, effect.from:getMaxHp())
                local x = upper - effect.from:getHandcardNum()
                if x > 0 then
                    effect.from:drawCards(x)
                end
                room:setPlayerMark(effect.to, "feizuijiao", 1)
            end
        end
    end
}
feizuijiaoVS = sgs.CreateViewAsSkill {
    name = "feizuijiao",
    n = 0,
    view_as = function(self, cards)
        return feizuijiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#feizuijiaoCard")
    end,
}
feizuijiao = sgs.CreateTriggerSkill {
    name = "feizuijiao",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging },
    view_as_skill = feizuijiaoVS,
    on_trigger = function(self, event, player, data)
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark("feizuijiao") > 0 then
                room:setPlayerMark(p, "feizuijiao", 0)
            end
        end
    end,
}
feichengpu:addSkill(feizuijiao)
feihuchen = sgs.CreateTriggerSkill {
    name = "feihuchen",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place == sgs.Player_PlaceHand
                and not room:getTag("FirstRound"):toBool() then
                if move.to:getPhase() == sgs.Player_Draw
                    and move.card_ids:length() > 2 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        BeMan(room, move.to):drawCards(1)
                    end
                elseif move.to:getPhase() ~= sgs.Player_Draw
                    and move.card_ids:length() > 1 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        BeMan(room, move.to):drawCards(1)
                    end
                end
            end
        end
        return false
    end
}
feichengpu:addSkill(feihuchen)
feiguanyu = sgs.General(extension, "feiguanyu", "shu", "4", true)
feiwushengVS = sgs.CreateOneCardViewAsSkill {
    name = "feiwusheng",
    response_or_use = true,
    view_filter = function(self, card)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:addSubcard(card:getEffectiveId())
            slash:deleteLater()
            return slash:isAvailable(sgs.Self)
        end
        return true
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:addSubcard(card:getId())
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash"
    end
}
feiwusheng = sgs.CreateTriggerSkill {
    name = "feiwusheng",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = feiwushengVS,
    events = { sgs.Predamage },
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = player:getRoom()
        if damage.to:getHujia() > 0 and damage.to:getHp() ~= 1 then
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end,
}
feiguanyu:addSkill(feiwusheng)
feiyanjunCard = sgs.CreateSkillCard {
    name = "feiyanjunCard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select, player)
        return #targets == 0
    end,
    feasible = function(self, targets)
        return #targets ~= 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()

        local judge = sgs.JudgeStruct()
        judge.pattern = "."
        judge.good = true
        judge.play_animation = false
        judge.who = effect.to
        judge.reason = self:objectName()
        room:judge(judge)
        local number = judge.card:getNumber()
        if number == 1 or number == 13 then
            local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
            duel:toTrick():setCancelable(true)
            duel:setSkillName(self:objectName())
            if not effect.to:isCardLimited(duel, sgs.Card_MethodUse)
                and not effect.to:isProhibited(effect.from, duel) then
                room:useCard(sgs.CardUseStruct(duel, effect.from, effect.to))
            end
            duel:deleteLater()
        else
            local choices = {}
            if effect.to:hasEquip() then
                table.insert(choices, "loseEquip")
            end
            table.insert(choices, "damage")
            table.insert(choices, "losehp")
            local choice = room:askForChoice(effect.to, self:objectName(), table.concat(choices, "+"))
            if choice == "loseEquip" then
                effect.to:throwAllEquips()
            elseif choice == "damage" then
                local theDamage = sgs.DamageStruct()
                theDamage.from = effect.from
                theDamage.to = effect.to
                theDamage.damage = 1
                theDamage.nature = sgs.DamageStruct_Thunder
                room:damage(theDamage)
            elseif choice == "losehp" then
                room:loseHp(effect.to, 2, true, effect.from, "feiyanjun")
                effect.to:gainHujia(1)
            end
        end
    end
}
feiyanjun = sgs.CreateViewAsSkill {
    name = "feiyanjun",
    n = 1,
    view_filter = function(self, selected, to_select)
        if not to_select:isKindOf("BasicCard") then
            return true
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = cards[1]
            local vs_card = feiyanjunCard:clone()
            vs_card:addSubcard(card)
            return vs_card
        end
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#feiyanjunCard"))
    end,
}
feiguanyu:addSkill(feiyanjun)
feimayunlu = sgs.General(extension, "feimayunlu", "shu", 4, false)
feifengpoCard = sgs.CreateSkillCard {
    name = "feifengpoCard",
    target_fixed = true,
    will_throw = true,
    filter = function(self, targets, to_select, player)
        return to_select == player
    end,
}
feifengpoVS = sgs.CreateViewAsSkill {
    name = "feifengpo",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isRed()
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local vs_card = feifengpoCard:clone()
            vs_card:addSubcard(cards[1])
            return vs_card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@feifengpo"
    end
}
feifengpo = sgs.CreateTriggerSkill {
    name = "feifengpo",
    events = { sgs.TargetSpecified, sgs.DamageCaused },
    view_as_skill = feifengpoVS,
    on_trigger = function(self, event, player, data)
        if not player:hasSkill(self:objectName()) then return false end
        local room = player:getRoom()
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") and not use.card:isKindOf("Duel") then return false end
            room:setTag("feifengpo", data)
            for _, p in sgs.qlist(use.to) do
                if not room:askForUseCard(p, "@@feifengpo", "@feifengpo") then
                    local dest = sgs.QVariant()
                    dest:setValue(p)
                    if room:askForSkillInvoke(player, self:objectName(), dest) then
                        local judge = sgs.JudgeStruct()
                        judge.pattern = "."
                        judge.good = true
                        judge.play_animation = false
                        judge.who = player
                        judge.reason = self:objectName()
                        room:judge(judge)
                        if judge.card:getNumber() > use.card:getNumber() then
                            player:drawCards(2)
                        else
                            room:setCardFlag(use.card, "feifengpo")
                        end
                    end
                end
            end
            room:removeTag("feifengpo")
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("feifengpo") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}
feimayunlu:addSkill(feifengpo)
feimayunlu:addSkill("mashu")
feipangtong = sgs.General(extension, "feipangtong", "shu", "3", true)
feilianhuanCard = sgs.CreateSkillCard {
    name = "feilianhuanCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return (#targets == 0) and (sgs.Self:canPindian(to_select)) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local tiger = targets[1]
        local success = source:pindian(tiger, "feilianhuan", nil)
        if not success then
            tiger:drawCards(1)
        end
    end
}
feilianhuanVS = sgs.CreateZeroCardViewAsSkill {
    name = "feilianhuan",
    view_as = function(self, cards)
        return feilianhuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}
feilianhuan = sgs.CreateTriggerSkill {
    name = "feilianhuan",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Pindian },
    view_as_skill = feilianhuanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.to == player or pindian.from == player then
                if pindian.from_card:getSuit() ~= pindian.to_card:getSuit() then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:setPlayerChained(pindian.to, true)
                        room:setPlayerChained(pindian.from, true)
                    end
                end
                if (pindian.from_card:getSuit() == sgs.Card_Club and pindian.from == player)
                    or (pindian.to_card:getSuit() == sgs.Card_Club and pindian.to == player) then
                    player:drawCards(1)
                end
            end
        end
    end,
}
feipangtong:addSkill(feilianhuan)
feiniepan = sgs.CreateTriggerSkill {
    name = "feiniepan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@nirvana",
    events = { sgs.AskForPeaches, sgs.Damaged },
    on_trigger = function(self, event, player, data)
        if event == sgs.AskForPeaches and player:getMark("@nirvana") > 0 then
            local room = player:getRoom()
            local dying_data = data:toDying()
            local source = dying_data.who
            if source:objectName() == player:objectName() then
                if player:askForSkillInvoke(self:objectName(), data) then
                    room:removePlayerMark(player, "@nirvana")
                    local hp = player:getMaxHp()
                    room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
                            room:obtainCard(player, id, false)
                            break
                        end
                    end
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
                            room:obtainCard(player, id, false)
                            break
                        end
                    end
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club then
                            room:obtainCard(player, id, false)
                            break
                        end
                    end
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
                            room:obtainCard(player, id, false)
                            break
                        end
                    end
                    if player:isChained() then
                        local damage = dying_data.damage
                        if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
                            room:setPlayerProperty(player, "chained", sgs.QVariant(false))
                        end
                    end
                    if not player:faceUp() then
                        player:turnOver()
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if player:isKongcheng() then
                if damage.nature == sgs.DamageStruct_Normal then return false end
                if damage.nature == sgs.DamageStruct_Fire then
                    player:drawCards(2)
                else
                    player:drawCards(1)
                end
            end
        end
    end,
}
feipangtong:addSkill(feiniepan)

sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
    ["feiDIY"] = "绯DIY",
    ["feiluxun"] = "绯陆逊",
    ["#feiluxun"] = "儒生雄才",
    ["&feiluxun"] = "陆逊",
    ["designer:feiluxun"] = "蒜香绯狱丸",
    ["feilianying"] = "连营",
    ["feilianyingCard"] = "连营",
    ["feilianyingCard:Chain"] = "横置",
    ["@feilianying"] = "请选择连营的目标",
    [":feilianying"] = "每当你失去最后的手牌后，你可以选择至多X名角色，然后令其各摸一张牌，然后视为对其他角色使用一张【火攻】;或横置这些角色并摸一张牌。（X为你失去的手牌数,且至多为5） ",
    ["feiqx"] = "谦逊",
    ["feiqianxun"] = "谦逊",
    ["feiqianxuncard"] = "谦逊",
    [":feiqianxun"] = "每当你的延时锦囊牌生效或你成为其他角色使用的非延时锦囊牌的目标时，你可以将所有手牌扣置于武将牌旁。一名角色的回合结束时，你获得所有“谦逊牌”。出牌阶段限一次，你可以弃置所有手牌令最多等同于你弃置的手牌数的角色(至多5名)摸两张牌并弃置两张牌。",
    ["feizhangliao"] = "绯张辽",
    ["#feizhangliao"] = "前将军",
    ["&feizhangliao"] = "张辽",
    ["designer:feizhangliao"] = "蒜香绯狱丸",
    ["feituxi"] = "突袭",
    [":feituxi"] = "其他角色出牌阶段或结束阶段开始时，若其有手牌，你可以移去一个召虎标记并获得其一张手牌，然后弃置一张牌。你的准备阶段开始或游戏开始时，你获得两个召虎标记。",
    ["feizhaohu"] = "召虎",
    [":feizhaohu"] = "其他角色失去最后的手牌时，你可以选择一项：1.获得一个召虎标记;2.移去一个召虎标记并视为对其造成一点伤害。",
    ["feizhaohu:get"] = "获得标记。",
    ["feizhaohu:lose"] = "失去标记并造成伤害。",
    ["feisunjian"] = "绯孙坚",
    ["#feisunjian"] = "武烈帝",
    ["&feisunjian"] = "孙坚",
    ["designer:feisunjian"] = "蒜香绯狱丸",
    ["feiyinghun"] = "英魂",
    [":feiyinghun"] = "一名其他角色的结束阶段，若你有英魂标记，你可以流失一点体力并移去一个英魂标记,然后获得一点护甲(护甲至多为5)并选择一项1.令其摸X张牌，然后弃置Y张牌，或令其摸Y张牌，然后弃置X张牌。（X为你的体力上限，Y为你的当前体力值）。你的准备阶段开始，你获得一个英魂标记；游戏开始时，你获得两个英魂标记。",
    ["feizhonglie"] = "忠烈",
    [":feizhonglie"] = "主公技，当吴势力角色杀死角色或死亡后，你恢复一点体力并获得一个英魂标记。",
    ["feicaozhang"] = "绯曹彰",
    ["#feicaozhang"] = "黄须儿",
    ["&feicaozhang"] = "曹彰",
    ["designer:feicaozhang"] = "蒜香绯狱丸",
    ["feijiangchi"] = "将驰",
    [":feijiangchi"] = "准备阶段，你可以选择一项1.令你本回合出牌阶段与弃牌阶段改为摸牌阶段；2.令你本回合判定阶段与摸牌阶段改为出牌阶段。你的手牌数大于体力值时，你使用杀无距离限制。",
    ["feiyanliang"] = "绯颜良",
    ["#feiyanliang"] = "何惧华雄",
    ["&feiyanliang"] = "颜良",
    ["designer:feiyanliang"] = "蒜香绯狱丸",
    ["feihujue"] = "虎攫",
    ["feihujueCard"] = "虎攫",
    [":feihujue"] = "出牌阶段限一次，你可以从牌堆中获得一张基本牌，并令一名其他角色直到其回合结束获得“武圣”，然后视为对其使用一张决斗。",
    ["feicuxie"] = "促狭",
    [":feicuxie"] = "你不因【杀】造成或受到伤害后，你随机从牌堆中获得的一张【杀】。",
    ["feiwenchou"] = "绯文丑",
    ["#feiwenchou"] = "有去无回",
    ["&feiwenchou"] = "文丑",
    ["designer:feiwenchou"] = "蒜香绯狱丸",
    ["feilangduo"] = "狼咄",
    ["feilangduoCard"] = "狼咄",
    [":feilangduo"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，视为你对其使用一张决斗；若你没赢，其视为对你使用一张决斗。",
    ["feibenzi"] = "奔辎",
    [":feibenzi"] = "你可以跳过摸牌阶段改为从牌堆中随机获得三张基本牌。",
    ["feilvbu"] = "绯吕布",
    ["#feilvbu"] = "飞将",
    ["&feilvbu"] = "吕布",
    ["designer:feilvbu"] = "蒜香绯狱丸",
    ["feifeijiang"] = "飞将",
    [":feifeijiang"] = "你使用【杀】或【决斗】指定其他角色为目标时，可以展示其一张手牌，若为基本牌，弃置之；若为锦囊牌，该牌伤害+1；若为装备牌，其不能响应该牌。",
    ["feijiedou"] = "解斗",
    ["feijiedou1"] = "你可以使用一张【杀】。",
    [":feijiedou"] = "一名角色成为其他角色使用的【杀】或【决斗】的目标时，你可以对一名角色使用一张【杀】，若该【杀】造成伤害，你令其他角色使用的【杀】或【决斗】无效。",
    ["feisheji"] = "射戟",
    ["feishejiCard"] = "射戟",
    [":feisheji"] = "你可以把一张装备牌交给其他角色，视为你对其使用一张不计入次数限制的【杀】，你以此法造成伤害后，你摸两张牌。其他角色装备区有牌时，视为在你的攻击范围内。",
    ["feixiaohu"] = "虓虎",
    [":feixiaohu"] = "主公技，你在其他群雄角色回合内造成伤害后，当前回合角色可以令你与其各摸一张牌。",
    ["feiwanghou"] = "绯王垕",
    ["#feiwanghou"] = "代罪羔羊",
    ["&feiwanghou"] = "王垕",
    ["designer:feiwanghou"] = "蒜香绯狱丸",
    ["illustrator:feiwanghou"] = "蒜香绯狱丸",
    ["feifenhu"] = "分斛",
    ["#feifenhuex"] = "分斛",
    ["feifenhuCard"] = "分斛",
    [":feifenhu"] = "你可以跳过摸牌阶段，视为对任意名角色使用【五谷丰登】。",
    ["feidaizui"] = "代罪",
    ["feidaizuidraw"] = "代罪",
    [":feidaizui"] = "你成为【杀】的目标时，你可以选择一名其他角色，其可以交给你一张牌并代替你成为【杀】的目标，若其未交给你牌，你不可响应此【杀】。你收到伤害后，你可以令手牌数最少的角色均摸X张牌(X为你已损体力值)",
    ["feichengpu"] = "绯程普",
    ["#feichengpu"] = "三朝虎臣",
    ["&feichengpu"] = "程普",
    ["designer:feichengpu"] = "蒜香绯狱丸",
    ["feitouhuo"] = "投火",
    ["feitouhuo:hp"] = "失去体力。",
    ["feitouhuo:Maxhp"] = "失去体力上限。",
    [":feitouhuo"] = "锁定技，你造成的非属性伤害视为火属性伤害。你杀死其他角色时，你流失一点体力或失去一点体力上限。",
    ["feizuijiao"] = "醉交",
    ["feizuijiaoCard"] = "醉交",
    [":feizuijiao"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.展示所有手牌，并视为你使用一张【酒】；2.你选择是否翻面并回复一点体力，然后将手牌摸至体力上限并本回合对其使用牌无距离和次数限制。",
    ["feihuchen"] = "虎臣",
    [":feihuchen"] = "一名角色一次性获得至少两张牌（若此时是摸牌阶段则改为三张）时，你可以令其摸一张牌。",
    ["feiguanyu"] = "绯关羽",
    ["#feiguanyu"] = "威震华夏",
    ["&feiguanyu"] = "关羽",
    ["designer:feiguanyu"] = "蒜香绯狱丸",
    ["feiwusheng"] = "武圣",
    [":feiwusheng"] = "你可以把一张牌当【杀】使用或打出，你使用红色【杀】无距离限制；你对有护甲且体力不为1的角色造成的伤害+1。",
    ["feiyanjun"] = "淹军",
    ["feiyanjunCard"] = "淹军",
    ["feiyanjuncard:loseEquip"] = "失去所有装备",
    ["feiyanjuncard:losehp"] = "失去2点体力",
    [":feiyanjun"] = "出牌阶段限一次，你可以弃置一张非基本牌，然后令一名其他角色进行判定，若结果为A或K，视为你对其使用一张【决斗】；否则其选择一项：1.失去所有装备;2.受到一点雷电伤害;3.失去两点体力，获得一点护甲。",
    ["feimayunlu"] = "绯马云騄",
    ["#feimayunlu"] = "剑胆琴心",
    ["&feimayunlu"] = "马云騄",
    ["designer:feimayunlu"] = "蒜香绯狱丸",
    ["feifengpo"] = "凤魄",
    ["feifengpoCard"] = "凤魄",
    [":feifengpo"] = "你使用【杀】或【决斗】指定角色后，其可以弃置一张红色牌，否则你可以进行判定；若判定牌的点数大于你使用的牌的点数，你摸两张牌；否则此牌造成的伤害+1。",
    ["@feifengpo"] = "你可以弃置一张红色牌。",
    ["feipangtong"] = "绯庞统",
    ["#feipangtong"] = "凤雏",
    ["&feipangtong"] = "庞统",
    ["designer:feipangtong"] = "蒜香绯狱丸",
    ["feilianhuan"] = "连环",
    ["feilianhuanCard"] = "连环",
    [":feilianhuan"] = "你可以与一名其他角色拼点，若你没赢，其摸一张牌。你拼点时，如果拼点牌花色不同，你可以横置你与拼点的角色。你用♣牌拼点时，摸一张牌。",
    ["feiniepan"] = "涅槃",
    [":feiniepan"] = "限定技，当你处于濒死状态时，你可以复原武将牌，体力回复至体力上限并获得牌堆中每种花色的牌各一张。当你受到属性伤害时，若你没有手牌，你摸一张牌(若是火焰伤害则改为摸两张牌)。",

}
return { extension }
