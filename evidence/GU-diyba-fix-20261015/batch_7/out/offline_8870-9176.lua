-- ===== diyba b09 =====
do
-- diyba batch b09 (邓方). 司马芝, 张举&张纯, 庞淯 skipped.
local function diyba_trigger(name, events, effect, compulsory)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

diyba_xj_dengfang = sgs.General(extension, "diyba_xj_dengfang", "qun", 2)

------------------------------------------------------------------ 邓方
diyba_guoyi_card = sgs.CreateSkillCard {
    name = "diyba_guoyiCard", will_throw = false,
    filter = function(self, targets, to, from) return #targets == 0 end,
    feasible = function(self, targets) return #targets == 1 end,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        to:drawCards(1, "diyba_guoyi")
        if to:isDead() then return end
        local choice = "diyba_guoyi_discard"
        if to:getCardCount(true) >= 2 then
            choice = room:askForChoice(to, "diyba_guoyi", "diyba_guoyi_give+diyba_guoyi_discard")
        end
        if choice == "diyba_guoyi_give" then
            local ex = room:askForExchange(to, "diyba_guoyi", 2, 2, true, "@diyba_guoyi_give")
            if not ex then return end
            local red, black, none = false, false, false
            for _, id in sgs.qlist(ex:getSubcards()) do
                local c = sgs.Sanguosha:getCard(id)
                if c:isRed() then red = true elseif c:isBlack() then black = true else none = true end
                room:showCard(to, id)
            end
            room:obtainCard(source, ex, true)
            if not red then room:setPlayerCardLimitation(source, "use", ".|red", true) end
            if not black then room:setPlayerCardLimitation(source, "use", ".|black", true) end
            if not none then room:setPlayerCardLimitation(source, "use", ".|.|.|.|colorless", true) end
        else
            source:setTag("diyba_guoyi_target", sgs.QVariant(to:objectName()))
        end
    end,
}
diyba_guoyi = sgs.CreateViewAsSkillV2 {
    name = "diyba_guoyi",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c) return false end,
    card_selection_feasible = function(self, request) return true end,
    create_card = function(self, request)
        local c = diyba_guoyi_card:clone()
        c:setSkillName("diyba_guoyi")
        return c
    end,
}
diyba_guoyi_use = diyba_record("#diyba_guoyi_use", {sgs.CardFinished, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_NotActive then p:removeTag("diyba_guoyi_target") end
        return
    end
    local use = data:toCardUse()
    if use.from ~= p or not p:hasSkill("diyba_guoyi") or use.card:isKindOf("SkillCard") then return end
    local name = p:getTag("diyba_guoyi_target"):toString()
    if name == "" then return end
    local to = room:findPlayer(name)
    if not to or to:isDead() or to:isNude() then return end
    if p:askForSkillInvoke("diyba_guoyi", data) then
        local id = room:askForCardChosen(p, to, "he", "diyba_guoyi", false, sgs.Card_MethodDiscard)
        room:throwCard(id, to, p)
    end
end)
diyba_xj_dengfang:addSkill(diyba_guoyi)
diyba_xj_dengfang:addSkill(diyba_guoyi_use)

sgs.LoadTranslationTable {
    ["diyba_xj_dengfang"] = "邓方", ["#diyba_xj_dengfang"] = "御土如磐", ["designer:diyba_xj_dengfang"] = "yyuaN",
    ["diyba_guoyi"] = "果毅",
    [":diyba_guoyi"] = "出牌阶段限一次，你可以令一名角色摸一张牌并选择一项：1.展示并交给你两张牌，你本回合只能使用这些颜色的牌；2.你本回合使用牌后，可以弃置其一张牌。",
    ["diyba_guoyi_give"] = "展示并交给其两张牌，其本回合只能使用这些颜色的牌",
    ["diyba_guoyi_discard"] = "其本回合使用牌后，可以弃置你一张牌",
    ["@diyba_guoyi_give"] = "果毅：展示并交给其两张牌",
}
end

