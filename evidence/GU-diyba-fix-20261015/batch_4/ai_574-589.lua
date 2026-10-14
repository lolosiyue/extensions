-- ===== diyba b05 =====
do
-- diyba b05 ai
sgs.ai_skill_invoke.diyba_yeshen = function(self, data)
    local cur = self.room:getCurrent()
    return cur and self:isFriend(cur) or false
end
sgs.ai_skill_playerchosen.diyba_jungui = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then return p end
    end
    return nil
end
sgs.ai_skill_invoke.diyba_jungui = true
end

