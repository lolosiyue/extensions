-- Five effective berserk callbacks, from b6025acc983331337614289d8cac79b078c003af.
-- Preserve the donor's policy domain and short-circuit order. Native inquiry
-- admission remains separate from these pure-value selections.
local function known(value, key)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("berserk policy input is unknown", key) end
    return value
end
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("berserk policy helper is unavailable", method)
    end
    return known(object[method](object, ...), method)
end

sgs.ai_skill_invoke.berserk_jichang = function(self, data)
    local dying = call(data, "toDying")
    local who = known(dying.who, "berserk_jichang.who")
    local peaches = 1 - call(who, "getHp")
    return call(self, "getCardsNum", "Peach") + call(self, "getCardsNum", "Analeptic") < peaches
        and call(who, "getMark", "@guiming") <= 0
end
sgs.ai_canNiepan_skill.berserk_jichang = function(player)
    return call(player, "getMark", "@jichang") > 0
end
sgs.ai_skill_cardask["@jichang"] = function(self)
    local miku = self.room:findPlayerBySkillName("berserk_jichang")
    if AIUnsupported.is(miku) then error(miku,0) end
    -- findPlayerBySkillName may lawfully return nil. isFriend(nil) has its own
    -- donor semantics; do not invent a target or silently change that branch.
    if call(self, "isFriend", miku) then return "." end
end
sgs.ai_skill_invoke.berserk_xinxian = function(self, data)
    local damage = call(data, "toDamage")
    return not call(self, "isFriend", damage.from)
end
sgs.ai_skill_playerchosen["@menghuan-target2"] = function(self)
    local enemies = known(self.enemies, "berserk.enemies")
    if #enemies == 0 then return self.player end
    -- The shared isolated sorter returns a sorted copy; donor sorts self.enemies
    -- in place. Preserve both the array identity and its resulting order.
    local sorted = call(self, "sort", enemies, "defense")
    for index, enemy in ipairs(sorted) do enemies[index] = enemy end
    for _, enemy in ipairs(enemies) do
        if enemy then return enemy end
    end
    return self.enemies[1]
end
