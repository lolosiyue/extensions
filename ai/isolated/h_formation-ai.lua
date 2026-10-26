-- h_formation package value hooks.

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, player, least, query, context)
        if least < 1 and query(self, "hasSkills", "shoucheng", query(self, "getFriends", player)) then least = 1 end
        return least
    end
    local previous_1 = sgs.ai_getLeastHandcardNum_skill["shoucheng"]
    sgs.ai_getLeastHandcardNum_skill["shoucheng"] = function(self, player, least, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "ally_refill" then
                return policy_1(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player, least) end
    end
    sgs.declareValueHookStages("ai_getLeastHandcardNum_skill", "shoucheng", {
        {phase="base", rule="ally_refill", order=200},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_defense_slash["slash_defense.double_jink"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
        local double = call(self.player, "hasSkills", "wushuang|drwushuang")
            or call(self.player, "hasSkill", "roulin") and call(to, "isFemale")
            or call(to, "hasSkill", "roulin") and call(self.player, "isFemale")
            or jiangqin and call(jiangqin, "isAdjacentTo", to) and call(self.player, "isAdjacentTo", to)
                and call(self, "isFriend", jiangqin)
        if double and state.knownJink < 2 and (not call(to, "hasLordSkill", "hujia") or state.hujiaJink < 2) then defense = 0 end
        return defense
    end
    sgs.ai_defense_slash["slash_defense.double_jink"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_2" and context.rule == "slash_defense.double_jink" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "slash_defense.double_jink", {
        {phase="special_2", order=10, rule="slash_defense.double_jink"},
    })
end)()
end
