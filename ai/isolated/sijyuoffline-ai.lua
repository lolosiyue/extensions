

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["sfofl_shaomou"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to,"hasSkill","sfofl_shaomou") and not damage_call(to,"isNude") and not damage_call(to,"getPile","sfofl_cangchu_liang"):isEmpty() and damage_call(self,"isFriend",to, from) then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["sfofl_shaomou"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_after_legacy" and context.rule == "sfofl_shaomou" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "sfofl_shaomou", {
        {phase="need_hp_after_legacy", order=5, rule="sfofl_shaomou"},
    })
end)()
end
