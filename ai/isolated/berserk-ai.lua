-- Five effective berserk callbacks, from b6025acc983331337614289d8cac79b078c003af.
-- Preserve the donor's policy domain and short-circuit order. Native inquiry
-- admission remains separate from these pure-value selections.
local function known(value, key)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("berserk policy input is unknown", key) end
    return value
end


sgs.ai_skill_invoke.berserk_jichang = function(self, data)
    local dying = data:toDying()
    local who = known(dying.who, "berserk_jichang.who")
    local peaches = 1 - who:getHp()
    return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
        and who:getMark("@guiming") <= 0
end
sgs.ai_canNiepan_skill.berserk_jichang = function(player)
    return player:getMark("@jichang") > 0
end
sgs.ai_skill_cardask["@jichang"] = function(self)
    local miku = self.room:findPlayerBySkillName("berserk_jichang")
    if AIUnsupported.is(miku) then error(miku,0) end
    -- findPlayerBySkillName may lawfully return nil. isFriend(nil) has its own
    -- donor semantics; do not invent a target or silently change that branch.
    if self:isFriend(miku) then return "." end
end
sgs.ai_skill_invoke.berserk_xinxian = function(self, data)
    local damage = data:toDamage()
    return not self:isFriend(damage.from)
end
sgs.ai_skill_playerchosen["@menghuan-target2"] = function(self)
    local enemies = known(self.enemies, "berserk.enemies")
    if #enemies == 0 then return self.player end
    -- The shared isolated sorter returns a sorted copy; donor sorts self.enemies
    -- in place. Preserve both the array identity and its resulting order.
    local sorted = self:sort(enemies, "defense")
    for index, enemy in ipairs(sorted) do enemies[index] = enemy end
    for _, enemy in ipairs(enemies) do
        if enemy then return enemy end
    end
    return self.enemies[1]
end
