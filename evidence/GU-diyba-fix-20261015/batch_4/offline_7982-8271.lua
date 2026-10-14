-- ===== diyba b05 =====
do
-- diyba b05: 3D14J (李娥 / 张承 / 鲍信)
local function diyba05_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    for _, id in ipairs(ids) do c:addSubcard(id) end
    return c
end

-- ===== 李娥 =====
local diyba_14j_lie = sgs.General(extension, "diyba_14j_lie", "wu", 3, false)

local diyba_yeshen = sgs.CreateTriggerSkillV2 {
    name = "diyba_yeshen",
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Finish then return false end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(skill:objectName()) then return skill:objectName(), p end
        end
        return false
    end,
    on_cost = function(skill, event, room, owner, ctx)
        return owner:askForSkillInvoke(skill:objectName(), ctx.original_data)
    end,
    on_effect = function(skill, event, room, owner, ctx)
        local name = skill:objectName()
        local cur = room:getCurrent()
        local x = owner:getMark("diyba_yeshen_x")
        if x <= 0 then x = 3 end
        local pile = {}
        for _, id in sgs.qlist(room:getDrawPile()) do table.insert(pile, id) end
        local n = math.min(x, #pile)
        if n == 0 then return false end
        local ids = {}
        for i = #pile - n + 1, #pile do table.insert(ids, pile[i]) end
        local il = sgs.IntList()
        for _, id in ipairs(ids) do il:append(id) end
        room:fillAG(il)
        room:getThread():delay(1000)
        room:clearAG()
        local black = sgs.IntList()
        for _, id in ipairs(ids) do
            if sgs.Sanguosha:getCard(id):isBlack() then black:append(id) end
        end
        local used = nil
        local reset = true
        if black:length() > 0 and cur and cur:isAlive() then
            reset = false
            room:fillAG(il, cur)
            local id = room:askForAG(cur, il, false, name)
            room:clearAG(cur)
            local card = sgs.Sanguosha:getCard(id)
            local len = 0
            local tr = sgs.Sanguosha:translate(card:objectName())
            for _ in string.gmatch(tr, "[\228-\233][\128-\191]*") do len = len + 1 end
            if len <= 0 then len = 1 end
            used = id
            local chain = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
            chain:addSubcard(id)
            chain:setSkillName(name)
            local targets = sgs.SPlayerList()
            local cand = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not cur:isProhibited(p, chain) then cand:append(p) end
            end
            local chosen = nil
            if cand:length() > 0 then
                chosen = room:askForPlayersChosen(cur, cand, name, 0, len, "@diyba_yeshen", true)
            end
            if chosen and chosen:length() > 0 then
                room:useCard(sgs.CardUseStruct(chain, cur, chosen), false)
            else
                -- recast: card goes to the discard pile, user draws one card
                local d = diyba05_dummy({ id })
                room:throwCard(d, cur)
                d:deleteLater()
                cur:drawCards(1, name)
            end
            chain:deleteLater()
            x = x - 1
            if x <= 0 then reset = true end
        end
        if not reset then
            owner:setMark("diyba_yeshen_x", x)
            -- remaining revealed cards go back on top of the draw pile
            local rest = {}
            for _, id in ipairs(ids) do
                if id ~= used and room:getCardPlace(id) == sgs.Player_DrawPile then table.insert(rest, id) end
            end
            if #rest > 0 then
                local d = diyba05_dummy(rest)
                room:moveCardTo(d, nil, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), name, ""))
                d:deleteLater()
            end
        else
            owner:setMark("diyba_yeshen_x", 0)
            if owner:isAlive() then
                room:damage(sgs.DamageStruct(name, nil, owner, 1, sgs.DamageStruct_Fire))
            end
        end
        return false
    end,
}
diyba_14j_lie:addSkill(diyba_yeshen)

-- ===== 张承 =====
local diyba_14j_zhangcheng = sgs.General(extension, "diyba_14j_zhangcheng", "wu", 3)

local diyba_jungui_record = sgs.CreateRuleSkillV2 {
    name = "#diyba_jungui_record",
    events = { sgs.CardUsed, sgs.EventPhaseChanging },
    global = true,
    can_trigger = function() return false end,
    on_record = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card and use.card:getSuit() ~= sgs.Card_NoSuit then
                local s = use.from:getTag("diyba_jungui_suits"):toString()
                local suit = use.card:getSuitString()
                if not string.find(s, suit, 1, true) then
                    use.from:setTag("diyba_jungui_suits", sgs.QVariant(s .. suit .. ","))
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_RoundStart and player then
                player:setTag("diyba_jungui_suits", sgs.QVariant(""))
            end
        end
    end,
}

local diyba_jungui = sgs.CreateTriggerSkillV2 {
    name = "diyba_jungui",
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(skill:objectName())
            and player:getPhase() == sgs.Player_Finish then
            return skill:objectName()
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local t = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@diyba_jungui", true, true)
        if not t then return false end
        ctx.targets:append(t)
        return true
    end,
    on_effect_target = function(skill, event, room, player, ctx, target)
        local name = skill:objectName()
        target:drawCards(2, name)
        if target:isAlive() and not target:isKongcheng() then
            room:showAllCards(target)
            -- discard one card of each distinct suit among the hand
            local suits = {}
            local order = {}
            for _, c in sgs.qlist(target:getHandcards()) do
                local s = c:getSuitString()
                if not suits[s] then suits[s] = true table.insert(order, s) end
            end
            for _, s in ipairs(order) do
                if target:isDead() then break end
                local pat = ".|" .. s .. "|.|hand"
                room:askForCard(target, pat, "@diyba_jungui_discard:::" .. s, sgs.QVariant(), sgs.Card_MethodDiscard, nil, false, name)
            end
        end
        if player:isAlive() and target:isAlive() then
            local rec = player:getTag("diyba_jungui_suits"):toString()
            local il = sgs.IntList()
            for _, id in sgs.qlist(room:getDiscardPile()) do
                local c = sgs.Sanguosha:getCard(id)
                if c:getSuit() ~= sgs.Card_NoSuit and string.find(rec, c:getSuitString(), 1, true) then
                    il:append(id)
                end
            end
            if il:length() > 0 and room:askForSkillInvoke(player, name, sgs.QVariant("regain:" .. target:objectName())) then
                local got = {}
                while il:length() > 0 do
                    room:fillAG(il, target)
                    local id = room:askForAG(target, il, true, name)
                    room:clearAG(target)
                    if id < 0 then break end
                    il:removeOne(id)
                    table.insert(got, id)
                end
                if #got > 0 then
                    local d = diyba05_dummy(got)
                    room:obtainCard(target, d, true)
                    d:deleteLater()
                end
            end
        end
        return false
    end,
}
diyba_14j_zhangcheng:addSkill(diyba_jungui)
diyba_14j_zhangcheng:addSkill(diyba_jungui_record)

-- ===== 鲍信 =====
local diyba_14j_baoxin = sgs.General(extension, "diyba_14j_baoxin", "qun", 4)

local diyba05_dmg_kinds = { "Slash", "Duel", "FireAttack", "ArcheryAttack", "SavageAssault", "Lightning" }
local diyba05_phase_pool = { sgs.Player_Judge, sgs.Player_Draw, sgs.Player_Play, sgs.Player_Discard, sgs.Player_Finish }

local diyba_xianjue = sgs.CreateTriggerSkillV2 {
    name = "diyba_xianjue",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
        if player:getTag("diyba_xianjue_extra"):toBool() then return false end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            for _, ph in ipairs(diyba05_phase_pool) do
                if change.to == ph then return skill:objectName() end
            end
            return false
        end
        if player:getPhase() == sgs.Player_Start then return skill:objectName() end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local name = skill:objectName()
        if event == sgs.EventPhaseChanging then
            local change = ctx.original_data:toPhaseChange()
            player:skip(change.to)
            return false
        end
        room:notifySkillInvoked(player, name)
        local ids = room:getNCards(5, false)
        local x = 0
        for _, id in sgs.qlist(ids) do
            local c = sgs.Sanguosha:getCard(id)
            for _, k in ipairs(diyba05_dmg_kinds) do
                if c:isKindOf(k) then x = x + 1 break end
            end
        end
        local avail = sgs.IntList()
        for _, id in sgs.qlist(ids) do avail:append(id) end
        while avail:length() > 0 and player:isAlive() do
            room:fillAG(avail, player)
            local id = room:askForAG(player, avail, true, name)
            room:clearAG(player)
            if id < 0 then break end
            avail:removeOne(id)
            if room:getCardPlace(id) == sgs.Player_DrawPile then
                room:obtainCard(player, id, false)
                local c = sgs.Sanguosha:getCard(id)
                room:askForUseCard(player, tostring(id), "@diyba_xianjue_use:::" .. c:objectName(), -1, sgs.Card_MethodUse, false)
            end
        end
        if x > 0 and player:isAlive() then
            local list = sgs.PhaseList()
            for i = 1, math.min(x, #diyba05_phase_pool) do list:append(diyba05_phase_pool[i]) end
            player:setTag("diyba_xianjue_extra", sgs.QVariant(true))
            player:play(list)
            player:removeTag("diyba_xianjue_extra")
        end
        return false
    end,
}
diyba_14j_baoxin:addSkill(diyba_xianjue)

sgs.LoadTranslationTable {
    ["diyba_14j_lie"] = "李娥",
    ["#diyba_14j_lie"] = "炉焚赤心",
    ["designer:diyba_14j_lie"] = "yyuaN",
    ["diyba_yeshen"] = "冶身",
    [":diyba_yeshen"] = "一名角色的结束阶段，你可以亮出牌堆底三张牌，若其中有黑色牌，其将其中一张当额定目标数为牌名字数的【铁索连环】使用或重铸，令“冶身”亮出牌数-1，然后将其余牌置于牌堆顶；若没有黑色牌或亮出牌数因此减至0，你复原“冶身”并对自己造成1点火焰伤害。",
    ["@diyba_yeshen"] = "冶身：选择【铁索连环】的目标（不选则重铸）",

    ["diyba_14j_zhangcheng"] = "张承",
    ["#diyba_14j_zhangcheng"] = "彰往察来",
    ["designer:diyba_14j_zhangcheng"] = "ZCT20070927",
    ["diyba_jungui"] = "隽轨",
    [":diyba_jungui"] = "结束阶段，你可以令一名角色摸两张牌且展示所有手牌，其再弃置其中花色不同的牌各一张，然后你可令其收回与你此回合内使用过的牌花色相同的任意张牌。",
    ["@diyba_jungui"] = "隽轨：你可以令一名角色摸两张牌且展示所有手牌",
    ["@diyba_jungui_discard"] = "隽轨：请弃置一张 %arg 手牌",

    ["diyba_14j_baoxin"] = "鲍信",
    ["#diyba_14j_baoxin"] = "德昭济北",
    ["designer:diyba_14j_baoxin"] = "突然消失",
    ["diyba_xianjue"] = "先觉",
    [":diyba_xianjue"] = "锁定技，你跳过除准备阶段外的所有额定阶段；准备阶段，你观看牌堆顶的五张牌并使用其中任意张，然后依次执行之后X个额外的阶段（X为这些牌中造成伤害的牌数）。",
    ["@diyba_xianjue_use"] = "先觉：你可以使用【%arg】",
}
end

