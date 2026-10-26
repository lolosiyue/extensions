-- bgm package value hooks.

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function defense_hate_bonus(player, siblings, defense_query)
        for _, sibling in ipairs(siblings) do
            if defense_query(sibling, "getMark", "hate_" .. player:objectName()) > 0 and defense_query(sibling, "getMark", "@hate_to") > 0 then return defense_query(sibling, "getHp") end
        end
        return 0
    end
    local function policy_1(self, player, preferred, query, context)
        if query(player, "getPhase") == sgs.Player_Play and query(player, "hasSkill", "shude") then return true, true end
        return preferred
    end
    local function policy_2(self, player, effect, query, phase, context)
        local manjuan = query(player, "hasSkill", "manjuan")
        if manjuan == nil then return nil, true end
        if manjuan and phase == sgs.Player_NotActive then return true, true end
        return effect
    end
    local function policy_3(self, player, value, defense_query, siblings, context)
        local function hate_bonus() return defense_hate_bonus(player, siblings, defense_query) end
        if defense_query(player, "getMark", "xhate") > 0 and defense_query(player, "hasLordSkill", "shichou") then value = value + hate_bonus() end
        return value
    end
    local function policy_4(self, player, value, defense_query, siblings, context)
        local function hate_bonus() return defense_hate_bonus(player, siblings, defense_query) end
        if defense_query(player, "hasLordSkill", "shichou") and defense_query(player, "getMark", "xhate") > 0 then value = value + hate_bonus() end
        return value
    end
    local previous_1 = sgs.ai_need_kongcheng["shude"]
    sgs.ai_need_kongcheng["shude"] = function(self, player, keep, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_loss" and context.rule == "play_refill" then
                return policy_1(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player, keep) end
    end
    sgs.declareValueHookStages("ai_need_kongcheng", "shude", {
        {phase="after_loss", rule="play_refill", order=1300},
    })
    local previous_2 = sgs.ai_hasManjuanEffect_skill["manjuan"]
    sgs.ai_hasManjuanEffect_skill["manjuan"] = function(self, player, manjuan_only, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "primary" and context.rule == "manjuan" then
                return policy_2(self, player, context.value, context.query, context.extra[1], context)
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(self, player, manjuan_only) end
    end
    sgs.declareValueHookStages("ai_hasManjuanEffect_skill", "manjuan", {
        {phase="primary", rule="manjuan", order=3100},
    })
    local previous_3 = sgs.ai_skill_defense["shichou"]
    sgs.ai_skill_defense["shichou"] = function(self, player, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_health" and context.rule == "shichou_before_health" then
                return policy_3(self, player, context.value, context.query, context.extra[1], context)
            end
            if context.phase == "after_health" and context.rule == "shichou_after_health" then
                return policy_4(self, player, context.value, context.query, context.extra[1], context)
            end
            return context.value
        end
        if type(previous_3) == "function" then return previous_3(self, player) end
        return previous_3
    end
    sgs.declareValueHookStages("ai_skill_defense", "shichou", {
        {phase="before_health", rule="shichou_before_health", order=7800},
        {phase="after_health", rule="shichou_after_health", order=8000},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    -- Keep the mandatory legacy shichou provider distinct, including its absence.
    local previous = sgs.ai_need_damaged["need_hp_before_legacy.shichou"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to,"hasLordSkill","shichou") then
        			local result=sgs.ai_need_damaged.shichou(self,from,to)
                    if AIUnsupported.is(result) then error(result,0) end
                    return result==1, true
        		end
        return value
    end
    sgs.ai_need_damaged["need_hp_before_legacy.shichou"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_legacy" and context.rule == "shichou" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "need_hp_before_legacy.shichou", {
        {phase="need_hp_before_legacy", order=1, rule="shichou"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["good_survival.ganglie_group"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "hasSkills", "neoganglie|xuehen|xueji")
        		and good_query(self, "isWeak", self.friends) then return nil, true end
        return value
    end
    sgs.ai_target_damage["good_survival.ganglie_group"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_survival" and context.rule == "ganglie_group" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "good_survival.ganglie_group", {
        {phase="good_survival", order=4, rule="ganglie_group"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["dahe"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local strategy_known = state.strategy_known
        local same_player = state.same_player
        if call(self.player, "hasSkill", "dahe") and call(to, "hasFlag", "dahe") and state.knownJink < 1 then
            -- Legacy global getKnownNum uses the room current player as observer.
            local current = self.room:getCurrent()
            local substituted_observer = current and not same_player(current, self.player)
            local known = #call(to, "getKnownCards")
            local view = rawget(to, "_view")
            local piles = strategy_known(type(view) == "table" and view.piles or nil, "known hand piles")
            for _, pile in ipairs(piles) do
                if strategy_known(pile.hand_pile, "hand pile status") and strategy_known(pile.open, "hand pile visibility") then
                    known = known + #strategy_known(pile.card_ids, "visible hand pile ids")
                end
            end
            if substituted_observer then
                known = self:useKnowledgeEstimate({value = known, status = "estimate", basis = "observer_substitution_visible_hand_count",
                    viewer = self.player:objectName(), observer = current:objectName()}, "getDefenseSlash:dahe")
            end
            if known == state.hand and not (call(to, "hasLordSkill", "hujia") and state.hujiaJink >= 1) then defense = 0 end
        end
        return defense
    end
    sgs.ai_defense_slash["dahe"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_3" and context.rule == "slash_defense.dahe" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "dahe", {
        {phase="special_3", order=10, rule="slash_defense.dahe"},
    })
end)()
end
