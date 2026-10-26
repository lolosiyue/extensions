

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["chuanxin"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from, "hasSkill", "chuanxin") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["chuanxin"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_hostile" and context.rule == "chuanxin" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "chuanxin", {
        {phase="can_lose_hostile", order=8, rule="chuanxin"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["chuanxin"]
    local policy = function(self, to, context)
        local value, strategy_call = context.value, context.query
        local from, is_slash, lock, same_player, strategy_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4], context.extra[5]
        if is_slash and strategy_call(from, "hasSkill", "chuanxin") then
                if #strategy_call(to, "getEquips") > 0 and not self:hasZhaxiangEffect(to) and strategy_call(self, "doDisCard", to, "e") then return true, true end
                if strategy_call(to, "getMark", "@chuanxin") < 1 and not strategy_call(to, "hasSkills", strategy_known(sgs.bad_skills, "bad_skills")) then
                    if #strategy_call(to, "getVisibleSkillList") > 1 then return true, true end
                end
            end
        return value
    end
    sgs.ai_target_damage["chuanxin"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "just_damage_after_relation" and context.rule == "chuanxin" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "chuanxin", {
        {phase="just_damage_after_relation", order=5, rule="chuanxin"},
    })
end)()
end
