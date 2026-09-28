-- 小程序武將包（Lua V2 staging）

local extension_xcx = sgs.Package("xcx", sgs.Package_GeneralPack)

local xcx_lvmeng = sgs.General(extension_xcx, "xcx_lvmeng", "wu", 4, true)
xcx_lvmeng:setImage("lvmeng")

local xcx_keji = sgs.CreateTriggerSkillV2 {
    name = "xcx_keji",
    events = {sgs.CardUsed, sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.EventPhaseChanging then return false end
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Play then return false end
        local use = data:toCardUse()
        if not use.card or not use.card:isKindOf("BasicCard") then return false end
        return player:hasSkill(skill:objectName()) and skill:objectName() or false
    end,
    on_record = function(skill, event, room, player, ctx)
        if event ~= sgs.EventPhaseChanging or not ctx.original_data then return end
        local change = ctx.original_data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return end
        -- Record visits every extant instance; the event actor is not its owner.
        local owner = ctx.owner
        if not owner then return end
        owner:setSkillInstanceStateValue(skill:objectName(), ctx.instanceID, "count", sgs.QVariant(0))
        local root = sgs.SkillInstanceKey(skill:objectName(), ctx.instanceID)
        for _, child in sgs.list(owner:getChildSkillInstanceKeys(root)) do
            if child.skillName == "#xcx_keji_maxcards" then
                room:setSkillInstanceCorrectState(owner, sgs.SkillInstanceRef(owner:objectName(), child), "count", sgs.QVariant(0))
            end
        end
    end,
    on_cost = function(skill, event, room, player, ctx) return true end,
    on_pay = function(skill, event, room, player, ctx) return true end,
    on_effect = function(skill, event, room, player, ctx)
        if event ~= sgs.CardUsed then return false end
        local id = ctx.instanceID
        local old = player:getSkillInstanceStateValue(skill:objectName(), id, "count"):toInt()
        player:setSkillInstanceStateValue(skill:objectName(), id, "count", sgs.QVariant(old + 1))
        local root = sgs.SkillInstanceKey(skill:objectName(), id)
        for _, child in sgs.list(player:getChildSkillInstanceKeys(root)) do
            if child.skillName == "#xcx_keji_maxcards" then
                room:setSkillInstanceCorrectState(player, sgs.SkillInstanceRef(player:objectName(), child), "count", sgs.QVariant(old + 1))
            end
        end
        room:addPlayerMark(player, "xcx_keji_count-Clear")
        room:sendCompulsoryTriggerLog(player, skill:objectName())
        player:drawCards(skill:getEffectiveAmount(ctx), skill:objectName())
        return false
    end,
}

local xcx_keji_maxcards = sgs.CreateMaxCardsSkillV2 {
    name = "#xcx_keji_maxcards",
    base_amount = 0,
    holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
        local owner = ctx:getPrimary()
        if not owner then return nil end
        return ctx:getStateValue("count", sgs.QVariant(0)):toInt()
    end,
}
xcx_lvmeng:addSkill(xcx_keji)
xcx_lvmeng:addSkill(xcx_keji_maxcards)
extension_xcx:insertRelatedSkills("xcx_keji", "#xcx_keji_maxcards")

local xcx_shenlvmeng = sgs.General(extension_xcx, "xcx_shenlvmeng", "god", 3, true)
xcx_shenlvmeng:setImage("shenlvmeng")
xcx_shenlvmeng:addSkill("shelie")

local xcx_gongxin = sgs.CreateViewAsSkillV2 {
    name = "xcx_gongxin",
    n = 0,
    -- Native card history is cleared on entering/leaving Play, as in the donor.
    limit_scope = sgs.Skill_Limit_Phase,
    phase_name = "Play",
    max_usage_limit = 1,
    target_mode = sgs.ViewAsSkillV2_SelectTargets,
    target_effect_mode = sgs.ViewAsSkillV2_EachTarget,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and player:isAlive()
    end,
    can_select_target = function(skill, request, selected, candidate)
        local player = request:getInitiator()
        return #selected == 0 and candidate and candidate ~= player and not candidate:isKongcheng()
    end,
    targets_feasible = function(skill, request, selected) return #selected == 1 end,
    on_effect = function(skill, ctx)
        local source = ctx.invoker
        local target = ctx.targets:first()
        if not source or not target or target:isKongcheng() then return sgs.ViewAsSkillV2_FinishSkill end
        local ids = sgs.IntList()
        for _, card in sgs.qlist(target:getHandcards()) do
            if card:isRed() then ids:append(card:getEffectiveId()) end
        end
        local room = source:getRoom()
        local card_id = room:doGongxin(source, target, ids, skill:objectName())
        if card_id == -1 then return sgs.ViewAsSkillV2_FinishSkill end
        local result = room:askForChoice(source, skill:objectName(), "obtain+put")
        source:removeTag(skill:objectName())
        local card = sgs.Sanguosha:getCard(card_id)
        if result == "obtain" then
            room:obtainCard(source, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
                source:objectName(), nil, skill:objectName(), nil), false)
        else
            source:setFlags("Global_GongxinOperator")
            room:moveCardTo(card, target, nil, sgs.Player_DrawPile,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), nil, skill:objectName(), nil), true)
            source:setFlags("-Global_GongxinOperator")
        end
        return sgs.ViewAsSkillV2_ContinueEffects
    end,
}
xcx_shenlvmeng:addSkill(xcx_gongxin)

local xcx_liucheng = sgs.General(extension_xcx, "xcx_liucheng", "qun", 3, false)
xcx_liucheng:setImage("mobilemou_liucheng")

-- Chui is one public player resource shared by both skills in the donor.
-- Skill instance identity applies to each activation, not to separate mark pools.
local function canUseTriggeredCard(skill, request)
    local player = request:getInitiator()
    local reason = request:getReason()
    return player and player:isAlive()
        and (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
        and request:getPattern() == "@@" .. skill:objectName()
        and request:getActivationInstanceId() > 0
        and request:getActivationInstanceId() == player:property(skill:objectName() .. "_response_instance"):toInt()
end

local function askTriggeredCard(skill, room, player, ctx, prompt, add_history)
    -- Broadcast only the pending instance ID so client and server admit the same entry.
    local key = skill:objectName() .. "_response_instance"
    local previous = player:property(key)
    room:setPlayerProperty(player, key, sgs.QVariant(ctx.instanceID))
    local ok, result = pcall(function()
        return room:askForUseCard(player, "@@" .. skill:objectName(), prompt, -1, sgs.Card_MethodUse, add_history)
    end)
    room:setPlayerProperty(player, key, previous)
    if not ok then error(result) end
end

local function clearTriggeredCard(skill, callback_name, event, room, player, ctx)
    -- Native TurnBroken/StageChange may unwind past the Lua scope.
    if player then room:setPlayerProperty(player, skill:objectName() .. "_response_instance", sgs.QVariant(0)) end
end

local xcx_lveyingVS = sgs.CreateViewAsSkillV2 {
    name = "xcx_lveying",
    n = 0,
    response_or_use = true,
    can_activate = canUseTriggeredCard,
    create_card = function(skill, request)
        local card = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
        if card then card:setSkillName(skill:objectName()) end
        return card
    end,
    on_effect = function(skill, ctx) return sgs.ViewAsSkillV2_ContinueEffects end,
}

local xcx_lveying = sgs.CreateTriggerSkillV2 {
    name = "xcx_lveying",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished, sgs.TargetSpecifying},
    view_as_skill = xcx_lveyingVS,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        local use = data:toCardUse()
        if event == sgs.CardFinished and use.card and use.card:isKindOf("Slash") and player:getMark("&xcx_chui") >= 2 then
            return skill:objectName()
        end
        if event == sgs.TargetSpecifying and use.card and use.card:isKindOf("Slash")
            and use.from and use.from:getPhase() == sgs.Player_Play and use.from:hasSkill(skill:objectName(), true) then
            return skill:objectName(), use.from
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.CardFinished then return true end
        return true
    end,
    on_pay = function(skill, event, room, player, ctx)
        if event == sgs.CardFinished then
            if player:getMark("&xcx_chui") < 2 then return false end
            player:loseMark("&xcx_chui", 2)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.CardFinished then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:drawCards(player, skill:getEffectiveAmount(ctx), skill:objectName())
            askTriggeredCard(skill, room, player, ctx, "@xcx_lveying_ghcc", true)
        elseif event == sgs.TargetSpecifying then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            player:gainMark("&xcx_chui")
        end
        return false
    end,
    on_turn_broken = clearTriggeredCard,
}
xcx_liucheng:addSkill(xcx_lveying)

local xcx_yingwuVS = sgs.CreateViewAsSkillV2 {
    name = "xcx_yingwu",
    n = 0,
    response_or_use = true,
    can_activate = canUseTriggeredCard,
    create_card = function(skill, request)
        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        if card then card:setSkillName(skill:objectName()) end
        return card
    end,
    on_effect = function(skill, ctx) return sgs.ViewAsSkillV2_ContinueEffects end,
}

local xcx_yingwu = sgs.CreateTriggerSkillV2 {
    name = "xcx_yingwu",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished, sgs.TargetSpecifying},
    view_as_skill = xcx_yingwuVS,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        local use = data:toCardUse()
        local card = use.card
        local valid = card and card:isNDTrick() and not card:isDamageCard() and not card:isKindOf("Fqizhengxiangsheng")
        if event == sgs.CardFinished and valid and player:getMark("&xcx_chui") >= 2 then
            return skill:objectName()
        end
        if event == sgs.TargetSpecifying and valid and use.from and use.from:getPhase() == sgs.Player_Play
            and use.from:hasSkill("xcx_lveying", true) then
            return skill:objectName(), use.from
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx) return true end,
    on_pay = function(skill, event, room, player, ctx)
        if event == sgs.CardFinished then
            if player:getMark("&xcx_chui") < 2 then return false end
            player:loseMark("&xcx_chui", 2)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.CardFinished then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:broadcastSkillInvoke(skill:objectName())
            room:drawCards(player, skill:getEffectiveAmount(ctx), skill:objectName())
            -- addHistory is the native no-count contract; a card flag is not consumed.
            askTriggeredCard(skill, room, player, ctx, "@xcx_yingwu_slash", false)
        elseif event == sgs.TargetSpecifying then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:broadcastSkillInvoke(skill:objectName())
            player:gainMark("&xcx_chui")
        end
        return false
    end,
    on_turn_broken = clearTriggeredCard,
}
xcx_liucheng:addSkill(xcx_yingwu)

local xcx_xiahouyuan = sgs.General(extension_xcx, "xcx_xiahouyuan", "wei", 4, true)
xcx_xiahouyuan:setImage("mobile_xiahouyuan")
local xcx_shensu = sgs.CreateTriggerSkillV2 {
    name = "xcx_shensu",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            return skill:objectName()
        end
        local card = event == sgs.CardUsed and data:toCardUse().card or nil
        if card and card:getSkillName() == "xcx_shensu_qiangming"
            and card:getActivationSkillName() == skill:objectName() and card:getActivationSkillInstanceId() > 0 then
            return skill:objectName() .. "#" .. card:getActivationSkillInstanceId()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return event ~= sgs.EventPhaseStart or room:askForSkillInvoke(player, skill:objectName())
    end,
    on_pay = function(skill, event, room, player, ctx) return true end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.CardUsed then
            local use = ctx.original_data:toCardUse()
            local list = use.no_respond_list
            for _, p in sgs.qlist(use.to) do if p ~= use.from then table.insert(list, p:objectName()) end end
            use.no_respond_list = list
            ctx.original_data:setValue(use)
            return false
        end
        room:broadcastSkillInvoke(skill:objectName())
        local choices = {"xcx_shensu1", "xcx_shensu2", "xcx_shensu3"}
        local skipped = {judge = 0, draw = 0, play = 0, discard = 0}
        while player:isAlive() and #choices > 0 do
            local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+") .. "+cancel")
            if not table.contains(choices, choice) then break end
            table.removeOne(choices, choice)
            local qiangming = choice ~= "xcx_shensu1"
            if choice == "xcx_shensu1" then player:skip(sgs.Player_Judge); player:skip(sgs.Player_Draw); skipped.judge=skipped.judge+1; skipped.draw=skipped.draw+1
            elseif choice == "xcx_shensu2" then player:skip(sgs.Player_Draw); player:skip(sgs.Player_Play); skipped.draw=skipped.draw+1; skipped.play=skipped.play+1
            else player:skip(sgs.Player_Play); player:skip(sgs.Player_Discard); skipped.play=skipped.play+1; skipped.discard=skipped.discard+1 end
            local slash_choices = {}
            for _, id in sgs.qlist(room:getAvailableCardList(player, "basic", skill:objectName())) do
                local candidate = sgs.Sanguosha:getEngineCard(id)
                if candidate and candidate:isKindOf("Slash") and not table.contains(slash_choices, candidate:objectName()) then
                    table.insert(slash_choices, candidate:objectName())
                end
            end
            if #slash_choices == 0 then table.insert(slash_choices, "slash") end
            local slash_name = #slash_choices == 1 and slash_choices[1]
                or room:askForChoice(player, "xcx_shensu_slashtype", table.concat(slash_choices, "+"))
            local slash = sgs.Sanguosha:cloneCard(slash_name, sgs.Card_NoSuit, 0)
            slash:setSkillName(qiangming and "xcx_shensu_qiangming" or skill:objectName())
            -- Keep the effect label while attributing the card to this exact skill instance.
            slash:setActivationSkill(skill:objectName(), ctx.instanceID)
            slash:setSourceSkill(skill:objectName(), ctx.instanceID)
            local targets = sgs.SPlayerList()
            for _, candidate in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canSlash(candidate, slash, false) then targets:append(candidate) end
            end
            local target
            if not targets:isEmpty() then
                target = room:askForPlayerChosen(player, targets, skill:objectName(), "@xcx_shensu")
            end
            if target then room:useCard(sgs.CardUseStruct(slash, player, target), false) else slash:deleteLater() end
        end
        for _, count in pairs(skipped) do if count >= 2 then player:turnOver(); break end end
        return false
    end,
}
xcx_xiahouyuan:addSkill(xcx_shensu)
xcx_xiahouyuan:addSkill("mobilezhengzi")

local xcx_yangxiu = sgs.General(extension_xcx, "xcx_yangxiu", "wei", 3, true)
xcx_yangxiu:setImage("yangxiu")
local xcx_danlao = sgs.CreateTriggerSkillV2 {
    name = "xcx_danlao",
    events = {sgs.EventPhaseStart},
    can_trigger = function(skill, event, room, player, data)
        return player and player:isAlive() and player:getPhase() == sgs.Player_Start and skill:objectName()
    end,
    on_cost = function(skill, event, room, player, ctx) return player:askForSkillInvoke(skill:objectName()) end,
    on_pay = function(skill, event, room, player, ctx) return true end,
    on_effect = function(skill, event, room, player, ctx)
        room:broadcastSkillInvoke(skill:objectName())
        local ids = player:drawCardsList(room:alivePlayerCount(), skill:objectName())
        if player:isDead() or ids:isEmpty() then return false end
        local left = {}
        for _, id in sgs.qlist(ids) do
            table.insert(left, id)
        end
        local received = {}
        while player:isAlive() and #left > 0 do
            -- Draw/move observers may already have moved a drawn card out of this hand.
            for i = #left, 1, -1 do
                if room:getCardOwner(left[i]) ~= player or room:getCardPlace(left[i]) ~= sgs.Player_PlaceHand then
                    table.remove(left, i)
                end
            end
            if #left == 0 then break end
            local targets = room:getAlivePlayers()
            local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@xcx_danlao-choose", true, true)
            if not target then break end
            -- Physical card toString() is its ID; the native pattern accepts these exact IDs.
            local card = room:askForExchange(player, skill:objectName(), #left, 1, false,
                "@xcx_danlao-give:" .. target:objectName(), false, table.concat(left, ",") .. "|.|.|hand")
            if not card then break end
            local valid = player:isAlive() and target:isAlive() and card:getSubcards():length() > 0
                and card:getSubcards():length() <= #left
            local seen = {}
            for _, id in sgs.qlist(card:getSubcards()) do
                if seen[id] or not table.contains(left, id) or room:getCardOwner(id) ~= player
                    or room:getCardPlace(id) ~= sgs.Player_PlaceHand then valid = false; break end
                seen[id] = true
            end
            if not valid then card:deleteLater(); break end
            room:obtainCard(target, card, false); received[target:objectName()] = target:objectName()
            for _, id in sgs.qlist(card:getSubcards()) do
                for i, left_id in ipairs(left) do
                    if left_id == id then table.remove(left, i); break end
                end
            end
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if not received[p:objectName()] and p:isAlive() and player:isAlive() and p:canSlash(player, nil, false)
                and p:askForSkillInvoke(skill:objectName(), sgs.QVariant("slash:" .. player:objectName())) then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:setSkillName("_xcx_danlao")
                room:useCard(sgs.CardUseStruct(slash, p, player), false)
            end
        end
        return false
    end,
}
xcx_yangxiu:addSkill(xcx_danlao)
xcx_yangxiu:addSkill("jilei")

sgs.LoadTranslationTable {
    ["xcx"] = "小程序",
    ["xcx_lvmeng"] = "小程序_吕蒙", ["&xcx_lvmeng"] = "吕蒙", ["#xcx_lvmeng"] = "白衣渡江", ["~xcx_lvmeng"] = "被看穿了吗...", ["designer:xcx_lvmeng"] = "小程序", ["cv:xcx_lvmeng"] = "官方", ["illustrator:xcx_lvmeng"] = "小程序",
    ["xcx_keji"] = "克己", [":xcx_keji"] = "出牌阶段，你每使用一张基本牌，你摸一张牌，且本回合手牌上限+1。", ["&xcx_keji"] = "克己",
    ["xcx_shenlvmeng"] = "小程序_神吕蒙", ["&xcx_shenlvmeng"] = "神吕蒙", ["#xcx_shenlvmeng"] = "圣光之国士", ["~xcx_shenlvmeng"] = "看那温暖而盛情的光芒...", ["designer:xcx_shenlvmeng"] = "小程序", ["cv:xcx_shenlvmeng"] = "官方", ["illustrator:xcx_shenlvmeng"] = "小程序",
    ["xcx_gongxin"] = "攻心", [":xcx_gongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以展示其一张红色牌并选择一项：1.获得此牌 2.将此牌置于牌堆顶。", ["xcx_gongxin:obtain"] = "获得此牌", ["xcx_gongxin:put"] = "置于牌堆顶",
    ["xcx_liucheng"] = "小程序_刘赪", ["&xcx_liucheng"] = "刘赪", ["#xcx_liucheng"] = "泣梧的湘女", ["~xcx_liucheng"] = "此番寻药未果，怎医叙儿之疾......", ["designer:xcx_liucheng"] = "小程序", ["cv:xcx_liucheng"] = "官方", ["illustrator:xcx_liucheng"] = "官方",
    ["xcx_lveying"] = "掠影", [":xcx_lveying"] = "当你使用【杀】结算结束后，若你的【椎】标记数不小于2，你移去2枚【椎】标记，摸一张牌，然后可以视为使用一张【过河拆桥】。当你使用【杀】指定其他角色为目标时，你获得1枚【椎】标记。", ["xcx_chui"] = "椎", ["@xcx_lveying_ghcc"] = "你可以视为使用一张【过河拆桥】", ["$xcx_lveying1"] = "避实击虚，吾可不惮尔等蛮力！", ["$xcx_lveying2"] = "疾步如风，谁人可视吾影！",
    ["xcx_yingwu"] = "莺舞", [":xcx_yingwu"] = "当你使用非伤害类普通锦囊牌结算结束后，若你的【椎】标记数不小于2，你移去2枚【椎】标记，摸一张牌，然后可以视为使用一张【杀】（不计次）。当你使用非伤害类普通锦囊牌指定一名角色为目标时，若你有技能【掠影】，你获得1枚【椎】标记。", ["@xcx_yingwu_slash"] = "你可以视为使用一张不计入次数的【杀】", ["$xcx_yingwu1"] = "莺舞曼妙，杀机亦藏其中！", ["$xcx_yingwu2"] = "莺翼之羽，便是诛汝之锋！",
    ["xcx_xiahouyuan"] = "小程序_夏侯渊", ["&xcx_xiahouyuan"] = "夏侯渊", ["#xcx_xiahouyuan"] = "疾行的猎豹", ["~xcx_xiahouyuan"] = "竟然...比我还...快...", ["designer:xcx_xiahouyuan"] = "小程序", ["cv:xcx_xiahouyuan"] = "官方", ["illustrator:xcx_xiahouyuan"] = "小程序",
    ["xcx_shensu"] = "神速", [":xcx_shensu"] = "回合开始时，你可以选择任意项：1.跳过判定和摸牌阶段；2.跳过摸牌和出牌阶段；3.跳过出牌和弃牌阶段。你每选择一项，便视为使用一张无距离限制的【杀】。若你跳过了出牌阶段，对应的【杀】不能响应；若你选择跳过的阶段有重复，你翻面。", ["xcx_shensu_qiangming"] = "神速", ["xcx_shensu1"] = "跳过判定和摸牌阶段", ["xcx_shensu2"] = "跳过摸牌和出牌阶段", ["xcx_shensu3"] = "跳过出牌和弃牌阶段", ["@xcx_shensu"] = "神速：选择一名角色作为【杀】的目标", ["xcx_shensu_slashtype"] = "神速：选择【杀】的类型", ["xcx_shensu:slash"] = "普通杀", ["xcx_shensu:fire_slash"] = "火杀", ["xcx_shensu:thunder_slash"] = "雷杀",
    ["xcx_yangxiu"] = "小程序_杨修", ["&xcx_yangxiu"] = "杨修", ["#xcx_yangxiu"] = "恃才放旷", ["~xcx_yangxiu"] = "哎！吾是聪明反被聪明误啊！", ["designer:xcx_yangxiu"] = "小程序", ["cv:xcx_yangxiu"] = "官方", ["illustrator:xcx_yangxiu"] = "小程序",
    ["xcx_danlao"] = "啖酪", [":xcx_danlao"] = "回合开始时，你可以摸X张牌，然后将任意张牌分配给任意名角色，没有分配到的其他角色可以视为对你使用一张【杀】（X为场上存活角色数）。", ["@xcx_danlao-choose"] = "啖酪：请选择一名角色分配牌（点取消结束分配）", ["@xcx_danlao-give"] = "啖酪：请选择要给 %src 的牌", ["xcx_danlao:slash"] = "你可以视为对 %src 使用一张【杀】", ["$xcx_danlao1"] = "美食美意，岂可辜负？", ["$xcx_danlao2"] = "此，美味也。",
}

return extension_xcx
