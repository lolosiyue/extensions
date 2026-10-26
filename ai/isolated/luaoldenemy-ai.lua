-- Source: b6025acc ai/luaoldenemy-ai.lua.

local function canDiscard(self, target)
    if type(self.doDisCard) ~= "function" then ai_unsupported("OldEnemy discard helper is unavailable", "doDisCard") end
    -- The donor helper can return nil for an ordinary negative decision.
    local value = self:doDisCard(target, "hej", true)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    return value
end
local function hermitTarget(self)
    local options = self.request and self.request.options
    local fact = options and options.context and options.context.old_enemy_hermit
    if type(fact) ~= "table" or fact.known ~= true or type(fact.target) ~= "string" then
        ai_unsupported("OldEnemyHermit request tag is unknown", "OldEnemyHermit")
    end
    if fact.target == "" then return nil end
    local target = self.room:findPlayerByObjectName(fact.target, true)
    if not target then ai_unsupported("OldEnemyHermit target is outside roster", "OldEnemyHermit") end
    return target
end
ai_skill_invoke.LuaOldEnemyHermit = function(self, options, request)
    local target = hermitTarget(self)
    if self:isFriend(target) then
        if self:getOverflow(target) > 2 then return (true) or false end
        if canDiscard(self, target) then return (true) or false end
    end
    if self:isEnemy(target) then
        if canDiscard(self, target) then return (true) or false end
        return (false) or false
    end
    return (true) or false
end
ai_skill_invoke.LuaPublicEnemy = function(self, options, request) return (true) or false end
sgs.ai_skill_playerchosen.LuaOldEnemyHermit = function(self)
    local friends = self.friends_noself
    if not AIValue.isList(friends) then ai_unsupported("OldEnemy friend order is unknown", "friends_noself") end
    local sorted = self:sort(friends, "chaofeng")
    -- Source sorts the existing friends array in place, before choosing its first member.
    for index, friend in ipairs(sorted) do friends[index] = friend end
    for _, friend in ipairs(friends) do return friend end
end
