-- ===== diyba b07 =====
do
-- diyba b07: default AI behaviour is sufficient; invoke hooks below.
sgs.ai_skill_invoke.diyba_qingxian = true
sgs.ai_skill_invoke.diyba_miaojin = true
sgs.ai_skill_invoke.diyba_chiheng = function(self, data) return true end
end

