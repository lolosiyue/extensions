-- ===== diyba b12 =====
do
-- diyba batch b12 AI hooks (minimal)
sgs.ai_skill_invoke.diyba_tuiji = true
sgs.ai_skill_invoke.diyba_yingtan = true
sgs.ai_skill_invoke.diyba_yingtan_get = true
sgs.ai_skill_invoke.diyba_yingtan_show = true
sgs.ai_skill_invoke.diyba_fuding_get = true
sgs.ai_skill_invoke.diyba_xushi_extra = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi_accept = function(self, data) return true end
sgs.ai_skill_invoke.diyba_xuyi2_draw = true
sgs.ai_skill_invoke.diyba_shangyi = function(self, data)
    local damage = data:toDamage()
    if damage and damage.to then return not self:isEnemy(damage.to) or damage.to == self.player end
    return true
end
sgs.ai_skill_choice.diyba_tuiji = "yj_tuixinzhifu"
end

