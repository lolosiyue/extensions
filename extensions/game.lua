-- HUMAN game.lua 的 Lua V2 staging 移植。
-- 小遊戲結果仍由 ui-script/game 的場景寫入工作目錄 txt；真人流程不以亂數代替。

local extension = sgs.Package("game", sgs.Package_GeneralPack)

local function instances(player, name)
    local result = {}
    if not player then return result end
    for _, id in sgs.qlist(player:getValidSkillInstanceIds(name)) do
        table.insert(result, name .. "#" .. id)
    end
    return result
end

local function trigger_instances(player, name)
    local result = instances(player, name)
    return #result > 0 and table.concat(result, "+") or false
end

local function read_game_result(path)
    local file = io.open(path, "r")
    assert(file, "無法打開文件 " .. path)
    local content = file:read("*a")
    file:close()
    return tonumber(content:match("%d+"))
end

local function selected_ids(ctx)
    local ids = sgs.IntList()
    if ctx and ctx.use_card then
        for _, id in sgs.qlist(ctx.use_card:getSubcards()) do ids:append(id) end
    end
    return ids
end

sgs.LoadTranslationTable {
["game"]="小游戏武将",
}

sgs.LoadTranslationTable {
["game_zhengxuan"]="郑玄",
["#game_zhengxuan"]="兼采定道",
["game_zhengjing"]="整经",
[":game_zhengjing"]="出牌阶段限一次，你可以进行一次整经,然后根据得分获得相应的牌,你可将其中的任意张至于一名其他角色,拥有“经”的角色在其回合内跳过判定和摸牌阶段并获得之",
["@game_zhengjing"]="请选择一名角色,将“经”置于其武将牌上,然后其跳过判定,摸牌阶段并获得“经”。",
["jing"]="经",
["#zhengjing-msg"]="%from 发动【整经】，结果是 %arg",
}

sgs.LoadTranslationTable {
["game_sunhanhua"]="孙寒华",
["#game_sunhanhua"]="挣绽的青莲",

["game_chongxu"]="冲虚",
[":game_chongxu"]="出牌阶段限一次，你可以进行一次集灵来获得分数，然后你可以用分数来升级“妙剑”、升级“莲华”或摸牌。",
["$game_chongxu1"]="实难参悟天机",
["$game_chongxu2"]="此间奥妙,似有所得",
["$game_chongxu3"]="大音希声,大象无形",
["#chongxu-msg"]="%from 的得分是 %arg",
["#chongxu-msg-draw"]="%from 选择摸 1 张牌",
["#chongxu-msg-lianhua"]="%from 选择升级【莲华】",
["#chongxu-msg-miaojian"]="%from 选择升级【妙剑】",

["game_lianhua"]="莲华",
[":game_lianhua"]="<b>1级</b>：你成为其他角色使用【<b>杀</b>】的目标时，你摸一张牌。</font>\
<b>2级</b>：你成为其他角色使用【<b>杀</b>】的目标时，你摸一张牌，然后进行一次判定，若判定结果为黑桃，则取消之。</font>\
<b>3级</b>：你成为其他角色使用【<b>杀</b>】的目标时，你摸一张牌，除非该角色弃置一张牌，否则取消之。",
[":game_lianhua2"]="<b>2级</b>：你成为其他角色使用【<b>杀</b>】的目标时，你摸一张牌，然后进行一次判定，若判定结果为黑桃，则取消之。",
[":game_lianhua3"]="<b>3级</b>：你成为其他角色使用【<b>杀</b>】的目标时，你摸一张牌，除非该角色弃置一张牌，否则取消之。",

["game_miaojian"]="妙剑",
[":game_miaojian"]="<b>1级</b>：出牌阶段限一次，你可以将一张【杀】当做【刺杀】使用，或者将一张锦囊牌当做【无中生有】使用。</font>\
<b>2级</b>：出牌阶段限一次，你可以将一张基本牌当做【刺杀】使用，或者将一张非基本牌当做【无中生有】使用。</font>\
<b>3级</b>：出牌阶段限一次，你可以视为使用一张【刺杀】或【无中生有】。",
[":game_miaojian2"]="<b>2级</b>：出牌阶段限一次，你可以将一张基本牌当做【刺杀】使用，或者将一张非基本牌当做【无中生有】使用。",
[":game_miaojian3"]="<b>3级</b>：出牌阶段限一次，你可以视为使用一张【刺杀】或【无中生有】。",

}

sgs.LoadTranslationTable {
["game_nanhualaoxian"]="南华老仙",
["#game_nanhualaoxian"]="南华老仙",
["game_yufeng"]="御风",
[":game_yufeng"]="出牌阶段限一次，你可以进行一次御风飞行。若失败你摸X张牌；若成功，则你可选择至多X名其他角色，"..
"其下一个准备阶段进行一次判定：若结果为黑色，其跳过接下来的出牌和弃牌阶段；"..
"若结果为红色，其跳过接下来的摸牌阶段（若选择角色数不足X则多余的分数改为摸牌）（X为御风飞行得分）",
["game_tianshu"]="天书",
[":game_tianshu"]="出牌阶段开始时，你可以弃置一张牌，并选择1名角色，其将获得【太平要术】并使用之。",
["@tianshu-discard"] = "你可以弃置一张牌发动【天书】",
["@tianshu-choose"] = "请选择一名角色获得并使用【太平要术】",
["#TianshuGive"] = "%from 使用【%arg】令 %to 获得并使用了【太平要术】",
}

local zhengxuan = sgs.General(extension, "game_zhengxuan", "qun", 3, true)
local zhengjing = sgs.CreateViewAsSkillV2 {
    name = "game_zhengjing", n = 0, target_mode = sgs.ViewAsSkillV2_NoTarget,
    max_usage_limit = 1, limit_scope = sgs.Skill_Limit_Turn, phase_name = "Play",
    can_activate = function(skill, request)
        local p = request:getInitiator()
        return p and p:isAlive() and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    on_effect = function(skill, ctx)
        local room, source = ctx.invoker:getRoom(), ctx.invoker
        local thread, number = room:getThread(), nil
        if source:getState() ~= "robot" then
            local targets = sgs.SPlayerList(); targets:append(source)
            room:doAnimate(2, "skill=game/zhengjing/zhengjing:", "game_zhengjing", targets)
            thread:delay(8000)
            number = read_game_result("zhengjing.txt")
        else number = math.random(0, 3) end
        if not number then return sgs.ViewAsSkillV2_FinishSkill end
        local msg = sgs.LogMessage(); msg.type = "#zhengjing-msg"; msg.from = source; msg.arg = number; room:sendLog(msg)
        local cards = room:getNCards(number); if cards:length() == 0 then return sgs.ViewAsSkillV2_FinishSkill end
        local give, keep = sgs.Sanguosha:cloneCard("slash"), sgs.Sanguosha:cloneCard("slash")
        room:fillAG(cards, source)
        while not cards:isEmpty() do
            local id = room:askForAG(source, cards, true, skill:objectName())
            if id == -1 then break end
            cards:removeOne(id); give:addSubcard(id)
        end
        room:clearAG(source)
        for _, id in sgs.qlist(cards) do keep:addSubcard(id) end
        if give:subcardsLength() > 0 then
            local target = room:askForPlayerChosen(source, room:getAlivePlayers(), skill:objectName(), "@game_zhengjing", false, true)
            if target then target:addToPile("jing", give) else for _, id in sgs.qlist(give:getSubcards()) do keep:addSubcard(id) end end
        end
        source:obtainCard(keep); give:deleteLater(); keep:deleteLater()
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local zhengjing_rule = sgs.CreateRuleSkillV2 {
    name = "#game_zhengjing_rule", events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(skill, event, room, player, data)
        -- The recipient need not own Zhengjing: the persistent pile is the source.
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart
            and not player:getPile("jing"):isEmpty() then
            return skill:objectName(), player
        end
        return false
    end,
    on_cost = function() return true end, on_pay = function() return true end,
    on_effect = function(skill, event, room, player, ctx)
        local card = sgs.Sanguosha:cloneCard("slash"); card:addSubcards(player:getPile("jing")); room:obtainCard(player, card, false)
        player:skip(sgs.Player_Judge); player:skip(sgs.Player_Draw); card:deleteLater(); return false
    end,
}
zhengxuan:addSkill(zhengjing)
addToSkills(zhengjing_rule)

local sun = sgs.General(extension, "game_sunhanhua", "wu", 3)
local chongxu = sgs.CreateViewAsSkillV2 {
    name = "game_chongxu", n = 0, target_mode = sgs.ViewAsSkillV2_NoTarget, max_usage_limit = 1, limit_scope = sgs.Skill_Limit_Turn, phase_name = "Play",
    can_activate = function(skill, request) local p=request:getInitiator(); return p and p:isAlive() and request:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    on_effect = function(skill, ctx)
        local room, source, number = ctx.invoker:getRoom(), ctx.invoker, nil
        if source:getState() ~= "robot" then
            local targets=sgs.SPlayerList(); targets:append(source); room:doAnimate(2,"skill=game/chongxu/chongxu:","game_chongxu",targets); room:getThread():delay(13000); number=read_game_result("chongxu.txt")
        else number=math.random(3,5) end
        if not number then return sgs.ViewAsSkillV2_FinishSkill end
        local msg=sgs.LogMessage(); msg.type="#chongxu-msg"; msg.from=source; msg.arg=number; room:sendLog(msg)
        if number < 3 then room:doLightbox("$game_chongxu1",2000) elseif number < 5 then room:doLightbox("$game_chongxu2",2000) else room:doLightbox("$game_chongxu3",2000) end
        local remain=number
        while remain > 1 do
            local choices={"draw"}; if remain>2 and source:getMark("&game_lianhua")<2 then table.insert(choices,"game_lianhua") end; if remain>2 and source:getMark("&game_miaojian")<2 then table.insert(choices,"game_miaojian") end; if source:getState()~="robot" then table.insert(choices,"cancel") end
            local choice=room:askForChoice(source,skill:objectName(),table.concat(choices,"+"),sgs.QVariant(),nil,remain); if choice=="cancel" then break end
            if choice=="draw" then remain=remain-2; msg.type="#chongxu-msg-draw"; room:sendLog(msg); source:drawCards(1)
            elseif choice=="game_lianhua" then remain=remain-3; room:addPlayerMark(source,"&game_lianhua",1); msg.type="#chongxu-msg-lianhua"; room:sendLog(msg); local n=source:getMark("&game_lianhua"); if n==1 then room:changeTranslation(source,"game_lianhua",2) elseif n==2 then room:changeTranslation(source,"game_lianhua",3) end
            elseif choice=="game_miaojian" then remain=remain-3; room:addPlayerMark(source,"&game_miaojian",1); msg.type="#chongxu-msg-miaojian"; room:sendLog(msg); local n=source:getMark("&game_miaojian"); if n==1 then room:changeTranslation(source,"game_miaojian",2) elseif n==2 then room:changeTranslation(source,"game_miaojian",3) end end
        end
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local lianhua = sgs.CreateTriggerSkillV2 {
    name = "game_lianhua", frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirmed},
    can_trigger = function(skill, event, room, player, data)
        local use = data:toCardUse()
        if player and player:isAlive() and use.card and use.card:isKindOf("Slash")
            and use.to:contains(player) and use.from ~= player then
            return trigger_instances(player, skill:objectName())
        end
        return false
    end,
    on_cost = function() return true end,
    on_pay = function() return true end,
    on_effect = function(skill, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        room:sendCompulsoryTriggerLog(player, skill:objectName())
        player:drawCards(skill:getEffectiveAmount(ctx))
        local level, nullify = player:getMark("&game_lianhua"), false
        if level == 1 then
            local judge = sgs.JudgeStruct()
            judge.pattern, judge.good, judge.play_animation = ".", true, true
            judge.who, judge.reason = player, skill:objectName()
            room:judge(judge)
            nullify = judge.card:getSuit() == sgs.Card_Spade
        elseif level == 2 and use.from then
            -- The attacker pays in reaction to the effect, after the draw.
            nullify = not room:askForCard(use.from, ".", "@lianhua-ask",
                sgs.QVariant(), skill:objectName())
        end
        if nullify then
            local names = use.nullified_list
            table.insert(names, "_ALL_TARGETS")
            use.nullified_list = names
            ctx.original_data:setValue(use)
        end
        return false
    end,
}
local miaojian = sgs.CreateViewAsSkillV2 {
    name="game_miaojian", n=0, target_mode=sgs.ViewAsSkillV2_SelectTargets,
    target_effect_mode=sgs.ViewAsSkillV2_EachTarget,
    max_usage_limit=1, limit_scope=sgs.Skill_Limit_Turn, phase_name="Play",
    -- This proxy chooses the resulting card by its target, as in the donor.
    -- Leave material in place until the resulting ordinary card pays it once.
    will_throw_selected_cards=false,
    can_activate=function(skill,request) local p=request:getInitiator(); return p and p:isAlive() and request:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    can_select_card=function(skill,request,candidate) local p=request:getInitiator(); local level=p:getMark("&game_miaojian"); return request:getSelectedCardIds():isEmpty() and not p:isJilei(candidate) and ((level==0 and (candidate:isKindOf("Slash") or candidate:isNDTrick())) or (level==1 and (candidate:isKindOf("Slash") or not candidate:isKindOf("BasicCard")))) end,
    card_selection_feasible=function(skill,request)
        local count = request:getSelectedCardIds():length()
        local level = request:getInitiator():getMark("&game_miaojian")
        return count == 0 or (level < 2 and count == 1)
    end,
    can_select_target=function(skill,request,selected,candidate) local p=request:getInitiator(); if #selected>0 then return false end; local ids=request:getSelectedCardIds(); if ids:isEmpty() then return p:canSlash(candidate) or candidate==p end; local c=sgs.Sanguosha:getCard(ids:first()); return c:isKindOf("Slash") and p:canSlash(candidate) or (not c:isKindOf("Slash") and candidate==p) end,
    targets_feasible=function(skill,request,selected) return #selected==1 end,
    cost=function(skill,room,ctx,request)
        local from, to = ctx.invoker, ctx.targets:first()
        if not from or not from:isAlive() or not to or not to:isAlive() then
            return false
        end
        local activation, source = ctx:getActivationRef(), ctx:getSourceRef()
        if not activation:isValid() or not source:isValid() then return false end
        local ids, card = request:getSelectedCardIds(), nil
        for _, id in sgs.qlist(ids) do
            local place = room:getCardPlace(id)
            if room:getCardOwner(id) ~= from
                or (place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip)
                or from:isJilei(sgs.Sanguosha:getCard(id)) then
                return false
            end
        end
        if ids:isEmpty() then
            card = sgs.Sanguosha:cloneCard(to == from and "ex_nihilo" or "yj_stabs_slash", sgs.Card_NoSuit, 0)
        else
            local old = sgs.Sanguosha:getCard(ids:first())
            card = sgs.Sanguosha:cloneCard(old:isKindOf("Slash") and "yj_stabs_slash" or "ex_nihilo", old:getSuit(), old:getNumber())
            if card then card:addSubcard(old) end
        end
        if not card then return false end
        -- The native cost path replaces the proxy after resolving its identity;
        -- it retains the same use/refs/quota instead of starting a second activation.
        card:setSkillName(skill:objectName())
        card:setActivationSkill(activation.key.skillName, activation.key.instanceID)
        card:setSourceSkill(source.key.skillName, source.key.instanceID)
        card:setFlags("game_miaojian_no_history")
        -- Match ViewAsSkillV2::cost: SkillContext retains updated_card during use.
        card:deleteLater()
        ctx.updated_card = card
        return true
    end,
    pay=function(skill,room,ctx,request)
        local player = ctx.invoker
        if not player or not player:isAlive() then return false end
        local original, ids = selected_ids(ctx), request:getSelectedCardIds()
        if original:length() ~= ids:length() then return false end
        for _, id in sgs.qlist(ids) do
            local card, place = sgs.Sanguosha:getCard(id), room:getCardPlace(id)
            if not original:contains(id) or not card or room:getCardOwner(id) ~= player
                or (place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip)
                or player:isJilei(card) then return false end
        end
        -- Keep material in place; the replacement card consumes it once in onUse.
        return true
    end,
}
local miaojian_history = sgs.CreateRuleSkillV2 {
    name = "#game_miaojian_history", events = {sgs.PreCardUsed},
    on_record = function(skill,event,room,player,ctx)
        if not ctx.original_data then return end
        local use = ctx.original_data:toCardUse()
        local card = use.card
        if card and card:hasFlag("game_miaojian_no_history")
            and card:getActivationSkillName() == "game_miaojian"
            and card:getActivationSkillInstanceId() > 0 then
            -- Preserve donor useCard(..., false); the V2 instance quota is separate.
            use.m_addHistory = false
            ctx.original_data:setValue(use)
        end
    end,
}
sun:addSkill(chongxu); sun:addSkill(lianhua); sun:addSkill(miaojian)
addToSkills(miaojian_history)

local nanhua=sgs.General(extension,"game_nanhualaoxian","qun",3,true)
local yufeng=sgs.CreateViewAsSkillV2 {
    name="game_yufeng", n=0, target_mode=sgs.ViewAsSkillV2_NoTarget, max_usage_limit=1, limit_scope=sgs.Skill_Limit_Turn, phase_name="Play",
    can_activate=function(skill,request) local p=request:getInitiator(); return p and p:isAlive() and request:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    on_effect=function(skill,ctx)
        local room,source=ctx.invoker:getRoom(),ctx.invoker; local number
        if source:getState()~="robot" then local t=sgs.SPlayerList(); t:append(source); room:doAnimate(2,"skill=game/yufeng/yufeng:","game_zhengjing",t); room:getThread():delay(13000); number=read_game_result("yufeng.txt") else number=math.random(0,3) end
        if number and number~=0 then
            local targets=room:askForPlayersChosen(source,room:getAlivePlayers(),skill:objectName(),0,number)
            for _,p in sgs.qlist(targets) do room:addPlayerMark(p,"&game_yufeng",1) end
            if targets:length()<number then source:drawCards(number-targets:length()) end
        end
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local yufeng_rule = sgs.CreateRuleSkillV2 {
    name = "#game_yufeng_rule", frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    can_trigger = function(skill, event, room, player, data)
        -- A pending mark survives loss of the skill and belongs to its recipient.
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart
            and player:getMark("&game_yufeng") > 0 then
            return skill:objectName(), player
        end
        return false
    end,
    on_cost = function() return true end,
    on_effect = function(skill, event, room, player, ctx)
        local judge = sgs.JudgeStruct()
        judge.pattern, judge.good, judge.play_animation = ".", true, true
        judge.who, judge.reason = player, "game_yufeng"
        room:judge(judge)
        if judge.card:isRed() then
            player:skip(sgs.Player_Draw)
        elseif judge.card:isBlack() then
            player:skip(sgs.Player_Play)
            player:skip(sgs.Player_Discard)
        end
        room:removePlayerMark(player, "&game_yufeng")
        return false
    end,
}
local tianshu = sgs.CreateTriggerSkillV2 {
    name = "game_tianshu", events = {sgs.EventPhaseStart},
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(skill:objectName())
            and player:getPhase() == sgs.Player_Play then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local id = player:getDerivativeCard("_taipingyaoshu", sgs.Player_PlaceTable)
        if not id or id <= 0 then return false end
        -- Select without discarding; cancellation/interceptors precede payment.
        local card = room:askForCard(player, ".", "@tianshu-discard", sgs.QVariant(),
            sgs.Card_MethodNone, nil, false, skill:objectName())
        if not card then return false end
        ctx.extra_data = sgs.QVariant(card:getEffectiveId())
        return true
    end,
    on_pay = function(skill, event, room, player, ctx)
        local id = ctx.extra_data:toInt()
        local card = sgs.Sanguosha:getCard(id)
        local place = room:getCardPlace(id)
        if not card or room:getCardOwner(id) ~= player
            or (place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip)
            or player:isJilei(card) then
            return false
        end
        room:throwCard(card, player, player)
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:broadcastSkillInvoke(skill:objectName())
        room:notifySkillInvoked(player, skill:objectName())
        local log = sgs.LogMessage()
        log.type, log.from, log.arg = "#InvokeSkill", player, skill:objectName()
        room:sendLog(log)
        -- In the donor, declining the recipient happens after the discard.
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(),
            skill:objectName(), "@tianshu-choose", true, true)
        if not target or not target:isAlive() then return false end
        log = sgs.LogMessage()
        log.type, log.from, log.arg = "#ChoosePlayerWithSkill", player, skill:objectName()
        log.to:append(target)
        room:sendLog(log)
        local id = player:getDerivativeCard("_taipingyaoshu", sgs.Player_PlaceTable)
        if not id or id <= 0 then return false end
        log = sgs.LogMessage()
        log.type, log.from, log.arg = "#TianshuGive", player, "_taipingyaoshu"
        log.to:append(target)
        room:sendLog(log)
        room:obtainCard(target, id)
        local card = sgs.Sanguosha:getCard(id)
        if card then room:useCard(sgs.CardUseStruct(card, target, target)) end
        return false
    end,
}
nanhua:addSkill(yufeng)
nanhua:addSkill(tianshu)
addToSkills(yufeng_rule)

return extension
