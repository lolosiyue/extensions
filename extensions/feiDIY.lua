extension = sgs.Package("feiDIY", sgs.Package_GeneralPack)
local skills = sgs.SkillList()
-- feimore/feislashmore 從未 addSkill 給任何武將，legacy 為全域規則；
-- V2 用 CorrectSkill_System 對應（同 mojiang.lua sy_global_targetMod 慣例）。
feimore = sgs.CreateTargetModSkillV2 {
    name = "feimore",
    pattern = ".",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local modType = ctx:getModType()
        if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then
            return nil
        end
        local from = ctx:getPrimary()
        local to = ctx:getSecondary()
        if from and to and from:hasSkill("feizuijiao") and to:getMark("feizuijiao") > 0 then
            return 1000
        end
        return nil
    end,
}
feislashmore = sgs.CreateTargetModSkillV2 {
    name = "feislashmore",
    pattern = "Slash",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit then
            return nil
        end
        local from = ctx:getPrimary()
        local to = ctx:getSecondary()
        local card = ctx:getCard()
        if not from then return nil end
        if from:hasSkill("feijiangchi") and from:getHandcardNum() > from:getHp() then
            return 1000
        end
        if from:hasSkill("feisheji") and to and to:hasEquip() then
            return 1000
        end
        if from:hasSkill("feiwusheng") and card and card:isRed() then
            return 1000
        end
        return nil
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
        return #targets < erzhang:getMark("feilianying") and #targets < 5
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
			fire_attack:deleteLater()
        elseif choice == "Chain" then
            for _, p in pairs(targets) do
                room:setPlayerChained(p, true)
            end
            source:drawCards(1)
        end
    end
}
feilianyingVS = sgs.CreateViewAsSkillV2 {
    name = "feilianying",
    n = 0,
    can_activate = function(skill, request)
        local reason = request:getReason()
        if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return false
        end
        return request:getPattern() == "@@feilianying"
    end,
    create_card = function(skill, request)
        return feilianyingCard:clone()
    end,
}
feilianying = sgs.CreateTriggerSkillV2 {
    name = "feilianying",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = feilianyingVS,
    events = { sgs.CardsMoveOneTime },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand)
            and move.is_last_handcard then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local move = ctx.original_data:toMoveOneTime()
        player:setTag("LianyingMoveData", ctx.original_data)
        local count = 0
        for i = 0, move.from_places:length() - 1, 1 do
            if move.from_places:at(i) == sgs.Player_PlaceHand then
                count = count + 1
            end
        end
        room:setPlayerMark(player, "feilianying", math.max(count))
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:askForUseCard(player, "@@feilianying", "@feilianying")
        return false
    end,
}
feiqianxuncard = sgs.CreateSkillCard {
    name = "feiqianxuncard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets < player:getHandcardNum() and #targets < 5
    end,
    feasible = function(self, targets, player)
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
feiqianxunVS = sgs.CreateViewAsSkillV2 {
    name = "feiqianxun",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return (not player:hasUsed("#feiqianxuncard")) and (not player:isKongcheng())
    end,
    create_card = function(skill, request)
        return feiqianxuncard:clone()
    end,
}
feiqianxun = sgs.CreateTriggerSkillV2 {
    name = "feiqianxun",
    events = { sgs.TrickEffect, sgs.EventPhaseChanging, sgs.TargetConfirmed },
    view_as_skill = feiqianxunVS,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.TrickEffect then
            if not (player and player:hasSkill(skill:objectName())) then return false end
            local effect = data:toCardEffect()
            if effect.card:isKindOf("DelayedTrick")
                and player:getPhase() == sgs.Player_Judge
                and not player:isKongcheng() then
                return skill:objectName()
            end
        elseif event == sgs.TargetConfirmed then
            if not (player and player:hasSkill(skill:objectName())) then return false end
            local use = data:toCardUse()
            if use.to:contains(player)
                and use.from
                and use.from:objectName() ~= player:objectName()
                and use.card:isNDTrick()
                and not player:isKongcheng() then
                return skill:objectName()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            local names, owners = {}, {}
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:hasSkill(skill:objectName()) and p:getPile("feiqx"):length() > 0 then
                    table.insert(names, skill:objectName())
                    table.insert(owners, p:objectName())
                end
            end
            if #names > 0 then
                return table.concat(names, "|"), table.concat(owners, "|")
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseChanging then return true end
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.TrickEffect or event == sgs.TargetConfirmed then
            player:addToPile("feiqx", player:handCards(), false)
        elseif event == sgs.EventPhaseChanging then
            local dummy = dummyCard()
            dummy:addSubcards(player:getPile("feiqx"))
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(),
                skill:objectName(), "")
            room:obtainCard(player, dummy, reason, false)
            dummy:deleteLater()
        end
        return false
    end,
}
feiluxun:addSkill(feilianying)
feiluxun:addSkill(feiqianxun)
feizhangliao = sgs.General(extension, "feizhangliao", "wei", "4", true)
-- feituxi/feizhaohu 為互為觸發者≠擁有者的一對技能：
-- feituxi 於他人出牌/結束階段反應（owner=feituxi 持有者，invoker=當前回合角色）；
-- feizhaohu 於任一角色失去最後手牌時反應（owner=feizhaohu 持有者，invoker=失牌角色）。
-- 均用格式二 TriggerList（owner 為實際持有該技能者，滿足 V2 實例校驗）。
feituxi = sgs.CreateTriggerSkillV2 {
    name = "feituxi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart, sgs.GameStart },
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play
                or (player:getPhase() == sgs.Player_Finish and not player:isKongcheng()) then
                local names, owners = {}, {}
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(skill:objectName()) and p:getMark("&feizhaohu") > 0 then
                        table.insert(names, skill:objectName())
                        table.insert(owners, p:objectName())
                    end
                end
                if #names > 0 then
                    return table.concat(names, "|"), table.concat(owners, "|")
                end
            elseif player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName()) then
                return skill:objectName()
            end
        elseif event == sgs.GameStart and player:hasSkill(skill:objectName()) then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart and ctx.invoker
            and (ctx.invoker:getPhase() == sgs.Player_Play or ctx.invoker:getPhase() == sgs.Player_Finish) then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart then
            local target = ctx.invoker
            if target:getPhase() == sgs.Player_Play or target:getPhase() == sgs.Player_Finish then
                player:loseMark("&feizhaohu", 1)
                room:obtainCard(player, room:askForCardChosen(player, target, "h", skill:objectName()))
                room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
            elseif target:getPhase() == sgs.Player_Start then
                player:gainMark("&feizhaohu", 2)
            end
        elseif event == sgs.GameStart then
            player:gainMark("&feizhaohu", 2)
        end
        return false
    end,
}
feizhaohu = sgs.CreateTriggerSkillV2 {
    name = "feizhaohu",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime },
    can_trigger = function(skill, event, room, player, data)
        local move = data:toMoveOneTime()
        if not (move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand)
            and move.is_last_handcard) then
            return false
        end
        local names, owners = {}, {}
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasSkill(skill:objectName()) then
                table.insert(names, skill:objectName())
                table.insert(owners, p:objectName())
            end
        end
        if #names > 0 then
            return table.concat(names, "|"), table.concat(owners, "|")
        end
        return false
    end,
    on_record = function(skill, event, room, player, ctx)
        local move = ctx.original_data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName()
            and move.from_places:contains(sgs.Player_PlaceHand)
            and move.is_last_handcard then
            -- 自清舊標記：AI（ai_skill_choice.feizhaohu）靠掃描 feizhaohup 標記找失牌者
            for _, pe in sgs.qlist(room:getAllPlayers()) do
                if pe:getMark("feizhaohup") > 0 and pe:objectName() ~= player:objectName() then
                    room:setPlayerMark(pe, "feizhaohup", 0)
                    pe:removeTag("feizhaohuData")
                end
            end
            player:setTag("feizhaohuData", ctx.original_data)
            room:setPlayerMark(player, "feizhaohup", 1)
        end
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        local target = ctx.invoker
        local choices = { "get" }
        if player:getMark("&feizhaohu") > 0 then
            table.insert(choices, "lose")
        end
        local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"))
        if choice == "get" then
            player:gainMark("&feizhaohu", 1)
        elseif choice == "lose" then
            local theDamage = sgs.DamageStruct()
            theDamage.from = player
            theDamage.to = target
            theDamage.damage = 1
            theDamage.nature = sgs.DamageStruct_Normal
            room:damage(theDamage)
            player:loseMark("&feizhaohu", 1)
        end
        return false
    end,
}
feizhangliao:addSkill(feituxi)
feizhangliao:addSkill(feizhaohu)

feiyinghun = sgs.CreateTriggerSkillV2 {
    name = "feiyinghun",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart, sgs.GameStart },
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                local names, owners = {}, {}
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(skill:objectName()) and p:getMark("&feiyinghun") > 0 then
                        table.insert(names, skill:objectName())
                        table.insert(owners, p:objectName())
                    end
                end
                if #names > 0 then
                    return table.concat(names, "|"), table.concat(owners, "|")
                end
            elseif player:getPhase() == sgs.Player_Start and player:hasSkill(skill:objectName()) then
                return skill:objectName()
            end
        elseif event == sgs.GameStart and player:hasSkill(skill:objectName()) then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart and ctx.invoker and ctx.invoker:getPhase() == sgs.Player_Finish then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart then
            local target = ctx.invoker
            if target:getPhase() == sgs.Player_Finish then
                player:loseMark("&feiyinghun", 1)
                room:loseHp(player, 1, true, player, skill:objectName())
                if player:getHujia() < 5 then player:gainHujia(1) end
                local choice = room:askForChoice(player, skill:objectName(), "draw+throw")
                if choice == "draw" then
                    target:drawCards(player:getMaxHp(), skill:objectName())
                    local n = math.min(target:getCards("he"):length(), player:getHp())
                    room:askForDiscard(target, skill:objectName(), n, n, false, true)
                elseif choice == "throw" then
                    target:drawCards(player:getHp(), skill:objectName())
                    local n = math.min(target:getCards("he"):length(), player:getMaxHp())
                    room:askForDiscard(target, skill:objectName(), n, n, false, true)
                end
            elseif target:getPhase() == sgs.Player_Start then
                player:gainMark("&feiyinghun")
            end
        elseif event == sgs.GameStart then
            player:gainMark("&feiyinghun", 2)
        end
        return false
    end,
}
feizhonglie = sgs.CreateTriggerSkillV2 {
    name = "feizhonglie$",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Death },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasLordSkill(skill:objectName())) then return false end
        local death = data:toDeath()
        if death.who:hasSkill(skill:objectName()) then return false end
        if (death.damage and death.damage.from and death.damage.from:getKingdom() == "wu")
            or death.who:getKingdom() == "wu" then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local theRecover = sgs.RecoverStruct()
        theRecover.recover = 1
        theRecover.who = player
        room:recover(player, theRecover)
        player:gainMark("&feiyinghun")
        return false
    end,
}
feisunjian:addSkill(feiyinghun)
feisunjian:addSkill(feizhonglie)
feicaozhang = sgs.General(extension, "feicaozhang", "wei", "4", true)
feijiangchi = sgs.CreateTriggerSkillV2 {
    name = "feijiangchi",
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        return skill:objectName()
    end,
    on_cost = function(skill, event, room, player, ctx)
        if player:getPhase() == sgs.Player_Start then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        if player:getPhase() == sgs.Player_Start then
            local choice = room:askForChoice(player, skill:objectName(), "draw+play")
            if choice == "draw" then
                room:setPlayerFlag(player, "feijiangchi_draw")
            elseif choice == "play" then
                room:setPlayerFlag(player, "feijiangchi_play")
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
        return false
    end,
}
feicaozhang:addSkill(feijiangchi)
feiyanliang = sgs.General(extension, "feiyanliang", "qun", "4", true)
feihujueCard = sgs.CreateSkillCard {
    name = "feihujueCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return (#targets == 0) and (to_select:objectName() ~= player:objectName())
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
feihujueVS = sgs.CreateViewAsSkillV2 {
    name = "feihujue",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return not player:hasUsed("#feihujueCard")
    end,
    create_card = function(skill, request)
        return feihujueCard:clone()
    end,
}
-- feihujue 的回合結算清理發生在任意角色（受贈臨時武聖者）身上，非 feihujue 持有者本人；
-- 用格式二明確指定合法擁有者（feiyanliang）以滿足 V2 實例校驗，ctx.invoker 為受影響角色。
feihujue = sgs.CreateTriggerSkillV2 {
    name = "feihujue",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging },
    view_as_skill = feihujueVS,
    can_trigger = function(skill, event, room, player, data)
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        if not (player and player:getMark("feihujue_wusheng") > 0) then return false end
        local owner = room:findPlayerBySkillName(skill:objectName())
        if not owner then return false end
        return skill:objectName(), owner:objectName()
    end,
    on_effect = function(skill, event, room, player, ctx)
        local target = ctx.invoker
        if target and target:getMark("feihujue_wusheng") > 0 and target:hasSkill("wusheng") then
            room:setPlayerMark(target, "feihujue_wusheng", 0)
            room:handleAcquireDetachSkills(target, "-wusheng", true)
        end
        return false
    end,
}
feiyanliang:addSkill(feihujue)
feicuxie = sgs.CreateTriggerSkillV2 {
    name = "feicuxie",
    events = { sgs.Damaged, sgs.Damage },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then return false end
        return skill:objectName()
    end,
    on_effect = function(skill, event, room, player, ctx)
        for _, id in sgs.qlist(room:getDrawPile()) do
            if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                room:obtainCard(player, id, false)
                break
            end
        end
        return false
    end,
}
feiyanliang:addSkill(feicuxie)
feiwenchou = sgs.General(extension, "feiwenchou", "qun", "4", true)
feilangduoCard = sgs.CreateSkillCard {
    name = "feilangduoCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= player:objectName())
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
feilangduo = sgs.CreateViewAsSkillV2 {
    name = "feilangduo",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return (not player:hasUsed("#feilangduoCard")) and not player:isKongcheng()
    end,
    create_card = function(skill, request)
        return feilangduoCard:clone()
    end,
}
feiwenchou:addSkill(feilangduo)
feibenzi = sgs.CreateTriggerSkillV2 {
    name = "feibenzi",
    events = { sgs.EventPhaseChanging },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName()) and player:isAlive()) then return false end
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        local change = ctx.original_data:toPhaseChange()
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
        return false
    end,
}
feiwenchou:addSkill(feibenzi)
feilvbu = sgs.General(extension, "feilvbu$", "qun", "4", true)
feifeijiang = sgs.CreateTriggerSkillV2 {
    name = "feifeijiang",
    events = { sgs.TargetSpecified, sgs.DamageCaused },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.DamageCaused then
            return skill:objectName()
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") and not use.card:isKindOf("Duel") then
                return false
            end
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("feifeijiangcard") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then break end
                local dest = sgs.QVariant()
                dest:setValue(p)
                if not p:isKongcheng() and room:askForSkillInvoke(player, skill:objectName(), dest) then
                    local to_show = room:askForCardChosen(player, p, "h", skill:objectName())
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
        return false
    end,
}
feilvbu:addSkill(feifeijiang)
feijiedou = sgs.CreateTriggerSkillV2 {
    name = "feijiedou",
    events = { sgs.TargetConfirmed, sgs.Damage },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from:objectName() ~= player:objectName()
                and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
                return skill:objectName()
            end
            return false
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                return skill:objectName()
            end
            return false
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.TargetConfirmed then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
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
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                player:setFlags("feijiedou")
            end
        end
        return false
    end,
}
feilvbu:addSkill(feijiedou)
feishejiCard = sgs.CreateSkillCard {
    name = "feishejiCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and (player:inMyAttackRange(to_select) or to_select:hasEquip())
    end,
    feasible = function(self, targets, player)
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
feishejiVS = sgs.CreateViewAsSkillV2 {
    name = "feisheji",
    n = 1,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return sgs.Slash_IsAvailable(player)
        elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return request:getPattern() == "slash"
        end
        return false
    end,
    can_select_card = function(skill, request, card)
        return card and card:isKindOf("EquipCard")
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:isEmpty() then return nil end
        local sjcard = feishejiCard:clone()
        sjcard:addSubcard(ids:first())
        sjcard:setSkillName(skill:objectName())
        return sjcard
    end,
}
feisheji = sgs.CreateTriggerSkillV2 {
    name = "feisheji",
    events = { sgs.Damage },
    view_as_skill = feishejiVS,
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("feisheji") then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        player:drawCards(2, skill:objectName())
        return false
    end,
}
feilvbu:addSkill(feisheji)
-- feixiaohu 主公技：實際受詢者為找到的群雄反應角色 p（非 feixiaohu 持有者），
-- 借用 feifeijiang 相同手法──擁有者維持為 damage.from（合法持有者），
-- 以 ctx.extra_data 攜帶被委託詢問的 p，供 on_effect 取回。
feixiaohu = sgs.CreateTriggerSkillV2 {
    name = "feixiaohu$",
    events = { sgs.Damage },
    can_trigger = function(skill, event, room, player, data)
        local damage = data:toDamage()
        if not (damage.from and damage.from:objectName() == player:objectName()
            and damage.from:hasLordSkill(skill:objectName())
            and damage.from:getPhase() == sgs.Player_NotActive) then
            return false
        end
        for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
            if p:getPhase() ~= sgs.Player_NotActive and p:getKingdom() == "qun" then
                return skill:objectName()
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local damage = ctx.original_data:toDamage()
        for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
            if p:getPhase() ~= sgs.Player_NotActive and p:getKingdom() == "qun" then
                if room:askForSkillInvoke(p, skill:objectName(), ctx.original_data) then
                    ctx.extra_data:setValue(p)
                    return true
                end
                break
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local damage = ctx.original_data:toDamage()
        local p = ctx.extra_data:toPlayer()
        damage.from:drawCards(1, skill:objectName())
        if p then p:drawCards(1, skill:objectName()) end
        return false
    end,
}
feilvbu:addSkill(feixiaohu)

feiwanghou = sgs.General(extension, "feiwanghou", "wei", "4", true)
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
feifenhuVS = sgs.CreateViewAsSkillV2 {
    name = "feifenhu",
    n = 0,
    can_activate = function(skill, request)
        local reason = request:getReason()
        if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return false
        end
        return request:getPattern() == "@@feifenhu"
    end,
    create_card = function(skill, request)
        return feifenhuCard:clone()
    end,
}
feifenhu = sgs.CreateTriggerSkillV2 {
    name = "feifenhu",
    events = { sgs.EventPhaseChanging, sgs.TargetConfirming },
    view_as_skill = feifenhuVS,
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName()) and player:isAlive()) then return false end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw then
                return skill:objectName()
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        local change = ctx.original_data:toPhaseChange()
        player:skip(change.to)
        room:askForUseCard(player, "@@feifenhu", "@feifenhu")
        return false
    end,
}
feiwanghou:addSkill(feifenhu)
--DEFER: CreateProhibitSkill 無 V2 對應 API，保留 legacy。
feifenhuex = sgs.CreateProhibitSkill {
    name = "#feifenhuex",
    is_prohibited = function(self, from, to, card)
        return to and card and table.contains(card:getSkillNames(), "feifenhuCard") and (to:getMark("feifenhu") == 0) and
            card:isKindOf("AmazingGrace")
    end
}
feiwanghou:addSkill(feifenhuex)
feidaizui = sgs.CreateTriggerSkillV2 {
    name = "feidaizui",
    events = { sgs.TargetConfirmed, sgs.Damaged },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player)
                and use.from and use.from:objectName() ~= player:objectName()
                and use.card:isKindOf("Slash") then
                return skill:objectName()
            end
            return false
        elseif event == sgs.Damaged then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.TargetConfirmed then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        elseif event == sgs.Damaged then
            return room:askForSkillInvoke(player, skill:objectName() .. "draw", ctx.original_data)
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local otherp = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p ~= use.from then
                    otherp:append(p)
                end
            end
            if otherp:isEmpty() then return false end
            local p = room:askForPlayerChosen(player, otherp, skill:objectName())
            local choice = room:askForChoice(p, skill:objectName(), "give+no", data)
            if choice == "give" then
                local id = room:askForCardChosen(p, p, "he", skill:objectName())
                room:giveCard(p, player, sgs.Sanguosha:getCard(id), skill:objectName())
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
        elseif event == sgs.Damaged then
            local least = 1000
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                least = math.min(p:getHandcardNum(), least)
            end
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getHandcardNum() == least then
                    p:drawCards(player:getLostHp(), skill:objectName())
                end
            end
        end
        return false
    end,
}
feiwanghou:addSkill(feidaizui)

feitouhuo = sgs.CreateTriggerSkillV2 {
    name = "feitouhuo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.Predamage, sgs.Death },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.Death then
            local death = data:toDeath()
            if not (death.damage and death.damage.from == player) then
                return false
            end
        end
        return skill:objectName()
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Predamage then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Normal then
                damage.nature = sgs.DamageStruct_Fire
            end
            data:setValue(damage)
        elseif event == sgs.Death then
            local choice = room:askForChoice(player, skill:objectName(), "hp+Maxhp", data)
            if choice == "hp" then
                room:loseHp(player, 1, true, player, skill:objectName())
            elseif choice == "Maxhp" then
                room:loseMaxHp(player)
            end
        end
        return false
    end,
}
feichengpu:addSkill(feitouhuo)
feizuijiaoCard = sgs.CreateSkillCard {
    name = "feizuijiaoCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= player:objectName()
    end,
    feasible = function(self, targets, player)
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
feizuijiaoVS = sgs.CreateViewAsSkillV2 {
    name = "feizuijiao",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return not player:hasUsed("#feizuijiaoCard")
    end,
    create_card = function(skill, request)
        return feizuijiaoCard:clone()
    end,
}
feizuijiao = sgs.CreateTriggerSkillV2 {
    name = "feizuijiao",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging },
    view_as_skill = feizuijiaoVS,
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        return skill:objectName()
    end,
    on_effect = function(skill, event, room, player, ctx)
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark("feizuijiao") > 0 then
                room:setPlayerMark(p, "feizuijiao", 0)
            end
        end
        return false
    end,
}
feichengpu:addSkill(feizuijiao)
feihuchen = sgs.CreateTriggerSkillV2 {
    name = "feihuchen",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardsMoveOneTime },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local move = data:toMoveOneTime()
        if move.to_place == sgs.Player_PlaceHand
            and not room:getTag("FirstRound"):toBool() then
            if move.to:getPhase() == sgs.Player_Draw and move.card_ids:length() > 2 then
                return skill:objectName()
            elseif move.to:getPhase() ~= sgs.Player_Draw and move.card_ids:length() > 1 then
                return skill:objectName()
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, player, ctx)
        local move = ctx.original_data:toMoveOneTime()
        BeMan(room, move.to):drawCards(1)
        return false
    end,
}
feichengpu:addSkill(feihuchen)
feiguanyu = sgs.General(extension, "feiguanyu", "shu", "4", true)
feiwushengVS = sgs.CreateViewAsSkillV2 {
    name = "feiwusheng",
    n = 1,
    response_or_use = true,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return sgs.Slash_IsAvailable(player)
        elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return request:getPattern() == "slash"
        end
        return false
    end,
    can_select_card = function(skill, request, card)
        if not card then return false end
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:addSubcard(card:getEffectiveId())
            slash:deleteLater()
            return slash:isAvailable(player)
        end
        return true
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:isEmpty() then return nil end
        local original = sgs.Sanguosha:getCard(ids:first())
        if not original then return nil end
        local slash = sgs.Sanguosha:cloneCard("slash", original:getSuit(), original:getNumber())
        slash:addSubcard(original:getId())
        slash:setSkillName(skill:objectName())
        return slash
    end,
}
feiwusheng = sgs.CreateTriggerSkillV2 {
    name = "feiwusheng",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = feiwushengVS,
    events = { sgs.Predamage },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local damage = data:toDamage()
        if damage.to:getHujia() > 0 and damage.to:getHp() ~= 1 then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local damage = ctx.original_data:toDamage()
        damage.damage = damage.damage + 1
        ctx.original_data:setValue(damage)
        return false
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
    feasible = function(self, targets, player)
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
feiyanjun = sgs.CreateViewAsSkillV2 {
    name = "feiyanjun",
    n = 1,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return not player:hasUsed("#feiyanjunCard")
    end,
    can_select_card = function(skill, request, card)
        return card and not card:isKindOf("BasicCard")
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:isEmpty() then return nil end
        local vs_card = feiyanjunCard:clone()
        vs_card:addSubcard(ids:first())
        return vs_card
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
feifengpoVS = sgs.CreateViewAsSkillV2 {
    name = "feifengpo",
    n = 1,
    can_activate = function(skill, request)
        local reason = request:getReason()
        if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return false
        end
        return request:getPattern() == "@@feifengpo"
    end,
    can_select_card = function(skill, request, card)
        return card and card:isRed()
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:isEmpty() then return nil end
        local vs_card = feifengpoCard:clone()
        vs_card:addSubcard(ids:first())
        return vs_card
    end,
}
feifengpo = sgs.CreateTriggerSkillV2 {
    name = "feifengpo",
    events = { sgs.TargetSpecified, sgs.DamageCaused },
    view_as_skill = feifengpoVS,
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") and not use.card:isKindOf("Duel") then return false end
        end
        return skill:objectName()
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            room:setTag("feifengpo", data)
            for _, p in sgs.qlist(use.to) do
                if not room:askForUseCard(p, "@@feifengpo", "@feifengpo") then
                    local dest = sgs.QVariant()
                    dest:setValue(p)
                    if room:askForSkillInvoke(player, skill:objectName(), dest) then
                        local judge = sgs.JudgeStruct()
                        judge.pattern = "."
                        judge.good = true
                        judge.play_animation = false
                        judge.who = player
                        judge.reason = skill:objectName()
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
        return false
    end,
}
feimayunlu:addSkill(feifengpo)
feimayunlu:addSkill("mashu")
feipangtong = sgs.General(extension, "feipangtong", "shu", "3", true)
feilianhuanCard = sgs.CreateSkillCard {
    name = "feilianhuanCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return (#targets == 0) and (player:canPindian(to_select)) and (to_select:objectName() ~= player:objectName())
    end,
    on_use = function(self, room, source, targets)
        local tiger = targets[1]
        local success = source:pindian(tiger, "feilianhuan", nil)
        if not success then
            tiger:drawCards(1)
        end
    end
}
feilianhuanVS = sgs.CreateViewAsSkillV2 {
    name = "feilianhuan",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return not player:isKongcheng()
    end,
    create_card = function(skill, request)
        return feilianhuanCard:clone()
    end,
}
feilianhuan = sgs.CreateTriggerSkillV2 {
    name = "feilianhuan",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Pindian },
    view_as_skill = feilianhuanVS,
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        local pindian = data:toPindian()
        if pindian.to == player or pindian.from == player then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        local pindian = data:toPindian()
        if pindian.from_card:getSuit() ~= pindian.to_card:getSuit() then
            if room:askForSkillInvoke(player, skill:objectName(), data) then
                room:setPlayerChained(pindian.to, true)
                room:setPlayerChained(pindian.from, true)
            end
        end
        if (pindian.from_card:getSuit() == sgs.Card_Club and pindian.from == player)
            or (pindian.to_card:getSuit() == sgs.Card_Club and pindian.to == player) then
            player:drawCards(1)
        end
        return false
    end,
}
feipangtong:addSkill(feilianhuan)
feiniepan = sgs.CreateTriggerSkillV2 {
    name = "feiniepan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@nirvana",
    events = { sgs.AskForPeaches, sgs.Damaged },
    can_trigger = function(skill, event, room, player, data)
        if not (player and player:hasSkill(skill:objectName())) then return false end
        if event == sgs.AskForPeaches then
            if player:getMark("@nirvana") > 0 then
                local dying_data = data:toDying()
                if dying_data.who:objectName() == player:objectName() then
                    return skill:objectName()
                end
            end
            return false
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if player:isKongcheng() and damage.nature ~= sgs.DamageStruct_Normal then
                return skill:objectName()
            end
            return false
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.AskForPeaches then
            return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.AskForPeaches then
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
            local dying_data = data:toDying()
            if player:isChained() then
                local damage = dying_data.damage
                if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
                    room:setPlayerProperty(player, "chained", sgs.QVariant(false))
                end
            end
            if not player:faceUp() then
                player:turnOver()
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire then
                player:drawCards(2)
            else
                player:drawCards(1)
            end
        end
        return false
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
