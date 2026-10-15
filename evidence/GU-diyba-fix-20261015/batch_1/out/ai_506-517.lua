-- ===== diyba b01 =====
do
-- diyba b01: default AI behaviour is sufficient; invoke hooks below.
sgs.ai_skill_invoke.diyba_fujiang = function(self, data) return true end
sgs.ai_skill_invoke.diyba_jiezhong = function(self, data)
    local dying = data:toDying()
    return dying and dying.who and self:isFriend(dying.who)
end
end

