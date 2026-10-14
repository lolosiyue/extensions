-- ===== diyba b10 =====
do
-- b10 AI hooks
sgs.ai_skill_choice.diyba_gengshou = function(self, choices, data)
    local owner = data:toPlayer()
    if not owner then return "cancel" end
    if self:isFriend(owner) then return "draw" end
    if self:isEnemy(owner) and not owner:isNude() then return "discard" end
    return "cancel"
end
sgs.ai_skill_invoke.diyba_gengshou_slash = true
sgs.ai_skill_playerchosen.diyba_gengshou = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return nil
end
end

