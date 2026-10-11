-- Christmas AI at b6025acc. Source policy is preserved; its removed LuaSkillCard
-- serialization is explicitly repaired through the current RLiwa V2 authority.
local function known(value, key)
    if value == nil then ai_unsupported("Christmas policy fact is unknown", key) end
    return value
end
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("Christmas policy helper is unavailable", method)
    end
    return known(object[method](object, ...), method)
end
sgs.ai_skill_invoke.RLiwa = function(self)
    return not (call(self.player, "isKongcheng") and call(self, "needKongcheng", self.player))
end
sgs.ai_fill_skill.RLiwa = function(self, inclusive, request)
    if call(self.player, "hasUsed", "#RLiwaCard") then return end
    if type(self.getLijianCard) ~= "function" then ai_unsupported("Lijian cost policy is unavailable", "getLijianCard") end
    local cost = self:getLijianCard()
    if cost == nil then
        -- Preserve the known donor concatenation error before Card_Parse.
        -- This is not missing projection and cannot become a fallback pass.
        error("attempt to concatenate a nil value (RLiwa Lijian cost)", 0)
    end
    if type(cost) ~= "number" or cost < 0 or cost % 1 ~= 0 then
        ai_unsupported("RLiwa Lijian cost is not a physical card ID", "RLiwa.cost")
    end
    local receipt = call(self, "bindSkillCard", "RLiwa", {cost}, request)
    call(self, "useKnowledgeEstimate", {status="estimate",value=true,
        basis="donor_error_repair.RLiwa_missing_LuaSkillCard_prototype_to_current_V2",
        viewer=call(self.player,"objectName")}, "christmas.RLiwa.serialization")
    return receipt
end
local function useRLiwa(card, use, self)
    local friends = known(self.friends_noself, "friends_noself")
    if #friends == 0 then return false end
    local sorted = call(self, "sort", friends, "threat")
    for index, friend in ipairs(sorted) do friends[index] = friend end
    local target = friends[1]
    for _, friend in ipairs(friends) do
        -- Source deliberately calls hasSkill with the entire configured string.
        -- Do not replace it with the different multi-skill hasSkills semantics.
        if call(friend, "hasSkill", known(sgs.cardneed_skill, "cardneed_skill")) then target = friend end
    end
    if target then use.card = card end
    if use.to and target then use.to:append(target) end
end
sgs.ai_skill_use_func["#RLiwaCard"] = useRLiwa
sgs.ai_skill_use_func.RLiwa = useRLiwa -- native V2 dispatch identity
sgs.ai_use_value.RLiwaCard = 2.0
sgs.ai_use_priority.RLiwaCard = 5.9
-- Current V2 valuation dispatches on the exact activation skill name.
sgs.ai_use_value.RLiwa = sgs.ai_use_value.RLiwaCard
sgs.ai_use_priority.RLiwa = sgs.ai_use_priority.RLiwaCard
