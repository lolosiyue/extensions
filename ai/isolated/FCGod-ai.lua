-- FCGod package value hooks.

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "getMark", "&f_jishen+jsweapon-SelfClear")>0 and card and not damage_call(card, "isVirtualCard") then
            dmg = dmg * 2
        end
        return dmg, nature
    end
    local function policy_2(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "getMark", "&f_jishen+jsarmor-SelfClear") > 0 and dmg > 1 and card and not damage_call(card, "isVirtualCard") then
            dmg = dmg / 2
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["f_jishen"]
    sgs.ai_ajustdamage_from["f_jishen"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_from" and context.rule == "f_jishen_weapon" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "f_jishen", {
        {phase="before_from", rule="f_jishen_weapon", order=4700},
    })
    local previous_2 = sgs.ai_ajustdamage_to["f_jishen"]
    sgs.ai_ajustdamage_to["f_jishen"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_event" and context.rule == "f_jishen_armor" then
                local damage, next_nature, terminal = policy_2(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "f_jishen", {
        {phase="after_event", rule="f_jishen_armor", order=7400},
    })
end)()
