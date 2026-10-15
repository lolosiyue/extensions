-- ===== diyba b20 =====
do
-- b20 AI hooks
sgs.ai_skill_invoke.diyba_huahai = function(self, data)
    local card
    local ok, d = pcall(function() return data:toDamage() end)
    if ok and d and d.card then
        return d.from ~= nil and self:isFriend(d.from) and d.to ~= nil and self:isEnemy(d.to)
    end
    local ok2, r = pcall(function() return data:toRecover() end)
    if ok2 and r and r.who then return self:isFriend(r.who) end
    return false
end
sgs.ai_skill_invoke.diyba_ougezhu = function(self, data)
    return self.player:getHp() <= 2
end
end

