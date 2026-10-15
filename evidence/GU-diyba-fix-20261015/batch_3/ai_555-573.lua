-- ===== diyba b04 =====
do
-- diyba b04 AI hooks
sgs.ai_skill_invoke.diyba_langzhi = true
sgs.ai_skill_invoke.diyba_bailei = function(self, data)
    return true
end
sgs.ai_skill_choice.diyba_langzhi = "obtain"
sgs.ai_skill_choice.diyba_bailei = function(self, choices, data)
    if string.find(choices, "kill") then
        for _, p in ipairs(self.enemies or {}) do
            if p:getHp() == 1 then return "kill" end
        end
    end
    if string.find(choices, "damage") then return "damage" end
    return "kill"
end
end

