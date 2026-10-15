-- ===== diyba b17 =====
do
-- b17 AI hooks
sgs.ai_skill_invoke["diyba_canggu"] = function(self, data)
    local damage = data:toDamage()
    return damage and damage.from and self:isEnemy(damage.from) or false
end
sgs.ai_skill_invoke["diyba_xuanwen"] = true
sgs.ai_skill_choice["diyba_canggu"] = "diyba_canggu_recover"
end

