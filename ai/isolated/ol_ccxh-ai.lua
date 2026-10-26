-- ol_ccxh package value hooks.

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function damage_jiaozi(self, player, damage_call)
        if not damage_call(player, "hasSkill", "jiaozi") then return false end
        for _, sibling in sgs.qlist(damage_call(player,"getAliveSiblings")) do
            if damage_call(sibling, "getHandcardNum") >= damage_call(player, "getHandcardNum") then return false end
        end
        return true
    end
    local function policy_1(self, player, effect, query, phase, context)
        local zishu = query(player, "hasSkill", "zishu")
        if zishu == nil then return nil, true end
        return zishu and phase == sgs.Player_NotActive
    end
    local function policy_2(self, to, value, damage_call, from, helpers, context)
        if damage_call(to,"hasSkill","gongqing") and damage_call(from,"getAttackRange") < 3 then return true, true end
        return value
    end
    local function policy_3(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_jiaozi(self,from,damage_call) then dmg = dmg+1 end
        return dmg, nature
    end
    local function policy_4(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_jiaozi(self,to,damage_call) then dmg = dmg+1 end
        return dmg, nature
    end
    local function policy_5(self, from, to, dmg, card, nature, damage_call, helpers, context)
        local damage_card_flag=helpers.card_flag
        if damage_card_flag(self,card,"hanyong") then dmg=dmg+1 end
        return dmg, nature
    end
    local previous_1 = sgs.ai_hasManjuanEffect_skill["zishu"]
    sgs.ai_hasManjuanEffect_skill["zishu"] = function(self, player, manjuan_only, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "secondary" and context.rule == "zishu" then
                return policy_1(self, player, context.value, context.query, context.extra[1], context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player, manjuan_only) end
    end
    sgs.declareValueHookStages("ai_hasManjuanEffect_skill", "zishu", {
        {phase="secondary", rule="zishu", order=3200},
    })
    local previous_2 = sgs.ai_ajustdamage_to["gongqing"]
    sgs.ai_ajustdamage_to["gongqing"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "cap" and context.rule == "gongqing" then
                return policy_2(self, to, context.value, context.query, from, context.extra[3], context)
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "gongqing", {
        {phase="cap", rule="gongqing", order=3301},
    })
    local previous_3 = sgs.ai_ajustdamage_from["jiaozi"]
    sgs.ai_ajustdamage_from["jiaozi"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_from_head" and context.rule == "jiaozi_from" then
                local damage, next_nature, terminal = policy_3(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            if context.phase == "after_from_head" and context.rule == "jiaozi_to" then
                local damage, next_nature, terminal = policy_4(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_3) == "function" then return previous_3(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "jiaozi", {
        {phase="after_from_head", rule="jiaozi_from", order=5000},
        {phase="after_from_head", rule="jiaozi_to", order=5100},
    })
    local previous_4 = sgs.ai_ajustdamage_from["hanyong"]
    sgs.ai_ajustdamage_from["hanyong"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "aoe_card" and context.rule == "hanyong" then
                local damage, next_nature, terminal = policy_5(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_4) == "function" then return previous_4(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "hanyong", {
        {phase="aoe_card", rule="hanyong", order=5200},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["jiaozi"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from, "hasSkill", "jiaozi")
                and damage_call(from, "getHandcardNum") > damage_call(to, "getHandcardNum") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["jiaozi"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_after_lethal" and context.rule == "jiaozi" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "jiaozi", {
        {phase="can_lose_after_lethal", order=2, rule="jiaozi"},
    })
end)()
end
